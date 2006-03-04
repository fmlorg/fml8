#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: changepassword.pm,v 1.17 2005/11/30 23:30:38 fukachan Exp $
#

package FML::Command::Admin::changepassword;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::changepassword - change remote administrator password.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

set password for a new address or change password.

=head1 METHODS

=head2 process($curproc, $command_context)

change remote administrator password.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: verify the syntax command string.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub verify_syntax
{
    my ($self, $curproc, $command_context) = @_;
    my $comname    = $command_context->get_cooked_command()    || '';
    my $comsubname = $command_context->get_cooked_subcommand() || '';
    my $options    = $command_context->get_options()    || [];
    my @test       = ($comname);
    my $command    = $options->[ 0 ] || '';
    my $address    = $options->[ 1 ] || '';
    my $passwd     = $options->[ 2 ] || '';
    push(@test, $command);

    # 1. check address syntax
    if ($address) {
        use FML::Restriction::Base;
        my $dispatch = new FML::Restriction::Base;
        unless ($dispatch->regexp_match('address', $address)) {
            $curproc->logerror("insecure address: <$address>");
            return 0;
        }
    }

    # 2. check syntax of (only) command name.
    use FML::Command;
    my $dispatch = new FML::Command;
    return $dispatch->safe_regexp_match($curproc, $command_context, \@test);
}


# Descriptions: change the admin password.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: NUM
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $myname  = $curproc->myname();
    my $options = $command_context->get_options();

    # XXX The arguments differ for the cases.
    # 1. command mail: admin changepassword [$USER] $PASSWORD
    # 2. command line: makefml changepassword $ML $ADDR $PASSWORD
    #                  fml $ML changepassword     $ADDR $PASSWORD
    if ($myname eq 'makefml' || $myname eq 'fml' ||
	$myname eq 'loader' ||
	$myname eq 'command' || $myname eq 'fml.pl') {
	my ($address, $password);

	if ($options->[2]) {
	    croak("wrong arguments");
	}
	elsif ($options->[0] && $options->[1]) {
	    $address  = $options->[ 0 ];
	    $password = $options->[ 1 ];
	}
	elsif ($options->[0]) {
	    # XXX-TODO really ???
	    # XXX special treatment only for command mails.
	    if ($myname eq 'command' || $myname eq 'fml.pl') {
		my $cred  = $curproc->credential();
		$address  = $cred->sender(); # From: in the header
		$password = $options->[ 0 ];
	    }
	    else {
		croak("wrong arguments");
	    }
	}
	else {
	    croak("wrong arguments");
	}

	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;
	if ($safe->regexp_match('address', $address)) {
	    $self->_change_password($curproc,
				    $command_context,
				    $address,
				    $password);
	}
	else {
	    croak("unsafe address");
	    $curproc->logerror("unsafe address: $address");
	}
    }
    else {
	croak("this program not support this function");
	$curproc->logerror("myname=$myname not support this function");
    }
}


# Descriptions: change the remote admin password.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
#               STR($address) STR($password)
# Side Effects: update *admin_member_password_maps
# Return Value: NUM
sub _change_password
{
    my ($self, $curproc, $command_context, $address, $password) = @_;
    my $config = $curproc->config();
    my $cred   = $curproc->credential();

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps.
    my $pri_map = $config->{ primary_admin_member_password_map };
    my $up_args = {
	map      => $pri_map,
	address  => $address,
	password => $password,
    };
    my $r = '';

    my $member_map = $config->{ primary_admin_member_map };
    unless ($cred->has_address_in_map($member_map, $config, $address)) {
	my $r  = "no such admin member";
	my $r0 = "firstly, please add the address as admin member.";
	$curproc->reply_message_nl('error.no_such_admin_member', $r);
	$curproc->reply_message_nl('command.please_add_admin_member',
				   $r0);
	$curproc->logerror($r);
	croak($r);
    }

    eval q{
	use FML::Command::Auth;
	my $passwd = new FML::Command::Auth;
	$passwd->change_password($curproc, $command_context, $up_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: rewrite buffer to hide the password phrase in $rbuf.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context) STR_REF($rbuf)
# Side Effects: none
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_context, $rbuf) = @_;

    if (defined $rbuf) {
	$$rbuf =~ s/^(.*(password|pass)\s+\S+).*/$1 ********/;
	unless ($$rbuf =~ /\*\*\*\*\*\*\*\*/o) {
	    $$rbuf =~ s/^(.*(password|pass)\s+).*/$1 ********/;
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::changepassword
first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
