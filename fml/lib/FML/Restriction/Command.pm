#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Command.pm,v 1.16 2004/12/05 16:19:13 fukachan Exp $
#

package FML::Restriction::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Restriction::Post;
push(@ISA, qw(FML::Restriction::Post));


=head1 NAME

FML::Restriction::Command - command mail restrictions.

=head1 SYNOPSIS

collection of utility functions used in command routines.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: permit if $sender is an ML member.
#    Arguments: OBJ($self) STR($rule) STR($sender) HASH_REF($v_args)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_user_command
{
    my ($self, $rule, $sender, $v_args) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->config();
    my $context  = $v_args || {};
    my $comname  = $context->{ comname } || '';

    # 1) sender check
    my ($match, $reason) = $self->SUPER::permit_member_maps($rule, $sender);

    # 2) command match anonymous one ?
    # XXX-TODO: deny reason is first match ? last match ?
    if ($match) {
	if ($reason eq 'reject') {
	    my $_rule = "permit_member_maps";
	    $curproc->restriction_state_set_deny_reason($_rule);
	    return(0, undef);
	}
	else {
	    if ($config->has_attribute('user_command_mail_allowed_commands',
				       $comname)) {
		$curproc->logdebug("match: rule=$rule comname=$comname");
		return("matched", "permit");
	    }
	    else {
		$curproc->restriction_state_set_deny_reason($rule);
		return(0, undef);
	    }
	}
    }
    else {
	my $_rule = "permit_member_maps";
	$curproc->restriction_state_set_deny_reason($_rule);
	return(0, undef);
    }
}


# Descriptions: permit specific anonymous command 
#               even if $sender is a stranger.
#    Arguments: OBJ($self) STR($rule) STR($sender) HASH_REF($v_args)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_anonymous_command
{
    my ($self, $rule, $sender, $v_args) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->config();
    my $context  = $v_args || {};
    my $comname  = $context->{ comname } || '';

    # 1) sender: no check.
    # 2) command match anonymous one ?
    if ($config->has_attribute('anonymous_command_mail_allowed_commands',
			       $comname)) {
	$curproc->logdebug("match: rule=$rule comname=$comname");
	return("matched", "permit");
    }
    # XXX-TODO: not need deny reason logging ?

    return(0, undef);
}


=head1 ADMIN COMMAND SPECIFIC RULES

=head2 permit_admin_member_maps($rule, $sender)

permit if admin_member_maps includes the sender in it.

=cut


# Descriptions: permit if admin_member_maps includes the sender in it.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_admin_member_maps
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->{ credential };
    my $match   = $cred->is_privileged_member($sender);

    if ($match) {
	$curproc->logdebug("found in admin_member_maps");
	return("matched", "permit");
    }
    # XXX-TODO: not need deny reason logging ?

    return(0, undef);
}


# Descriptions: check if admin member passwrod is valid.
#    Arguments: OBJ($self) STR($rule) STR($sender) HASH_REF($context)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub check_admin_member_password
{
    my ($self, $rule, $sender, $context) = @_;
    my $curproc  = $self->{ _curproc };
    my $opt_args = $context->{ admin_option } || {};
    my $password = $opt_args->{ password }    || '';

    use FML::Command::Auth;
    my $auth   = new FML::Command::Auth;
    my $status = $auth->check_admin_member_password($curproc, $opt_args);
    if ($status) {
	$curproc->log("admin password: auth ok");
	return("matched", "permit");
    }
    else {
	# XXX-TODO: not need deny reason logging ?
	$curproc->logerror("admin password: auth fail");
	return(0, undef);
    }
}


=head1 UTILITIES

=cut

# Descriptions: check if the input string looks secure as a command ?
#    Arguments: OBJ($self) STR($s)
# Side Effects: none
#      History: fml 4.0's SecureP()
# Return Value: NUM(1 or 0)
sub _is_secure_command_string
{
   my ($self, $s) = @_;

   # 0. clean up
   $s =~ s/^\s*\#\s*//o; # remove ^#

   # 1. trivial case
   # 1.1. empty
   if ($s =~ /^\s*$/o) {
       return 1;
   }

   # 2. allow
   #           command = [-\d\w]+
   #      mail address = [-_\w]+@[\w\-\.]+
   #   command options = last:30
   #
   # XXX sync w/ mailaddress regexp in FML::Restriction::Base ?
   # XXX hmm, it is difficult.
   #
   if ($s =~/^[-\d\w]+\s*$/o) {
       return 1;
   }
   elsif ($s =~/^[-\d\w]+\s+[\s\w\_\-\.\,\@\:]+$/o) {
       return 1;
   }

   return 0;
}


# Descriptions: incremental regexp match for the given data.
#    Arguments: OBJ($self) VAR_ARGS($data)
# Side Effects: none
# Return Value: NUM(>0 or 0)
sub command_regexp_match
{
    my ($self, $data) = @_;
    my $r = 0;

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;

    if (ref($data)) {
	if (ref($data) eq 'ARRAY') {
	  DATA:
	    for my $x (@$data) {
		next DATA unless $x;

		unless ($safe->regexp_match('command_mail_substr', $x)) {
		    $r = 0;
		    last DATA;
		}
		else {
		    $r++;
		}
	    }
	}
	else {
	    my $curproc = $self->{ _curproc };
	    $curproc->logerror("FML::Restriction::Command: wrong data");
	    $r = 0;
	}
    }
    else {
	$r = $safe->regexp_match('command', $data);
    }

    return $r;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Restriction::Command first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
