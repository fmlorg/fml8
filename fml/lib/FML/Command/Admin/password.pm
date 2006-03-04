#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: password.pm,v 1.15 2004/07/23 13:16:35 fukachan Exp $
#

package FML::Command::Admin::password;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::password - authenticate the remote admin password.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 process($curproc, $command_context)

authenticate the remote admin password.

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


# Descriptions: rewrite buffer to hide the password phrase in $rbuf.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context) STR_REF($rbuf)
# Side Effects: none
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_context, $rbuf) = @_;

    if (defined $rbuf) {
	$$rbuf =~ s/^(.*(password|pass)\s+).*/$1 ********/;
    }
}


=head2 verify_syntax($curproc, $command_context)

verify the syntax command string.
return 0 if it looks insecure.

=cut


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

    # XXX Let original_command be "admin password PASSWORD".
    # XXX options = [ 'password', PASSWORD ] (not shifted yet here).
    my $i = 0;
  DATA:
    for my $x (@$options) {
	if ($i++ == 1) {
	    push(@test, "PASSWORD");
	}
	else {
	    push(@test, $x);
	}
    }

    use FML::Command;
    my $dispatch = new FML::Command;
    return $dispatch->safe_regexp_match($curproc, $command_context, \@test);
}


# Descriptions: dummy in the case of command mail.
#
#               [Case 1: command mail]
#               This password module is a dummy. In fact,
#               FML::Command::Auth::check::check_admin_member_password()
#               verified the password already before this module is called.
#
#               [Case 2: makefml/fml command on promt]
#
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $option = $command_context->get_options() || [];

    # XXX Let original_command be "admin password PASSWORD".
    # XXX $option is shifted before this method called, so [ PASSWORD ] now.
    my $p = $option->[ 0 ];
    $curproc->command_context_set_admin_password($p);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::password first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
