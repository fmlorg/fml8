#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.8 2004/01/01 07:29:27 fukachan Exp $
#

package FML::Process::State;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::State - interface to handle states within this process

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=haed1 BASIC RESTRICTION STATES

=cut



=haed1 COMMAND PROCESSOER STATES

=cut


# Descriptions: parse $orig_command and set up HASH_REF as
#               base information for command processing.
#    Arguments: OBJ($curproc) STR($orig_command)
# Side Effects: none
# Return Value: HASH_REF
sub command_context_init
{
    my ($curproc, $orig_command) = @_;

    # Example: if orig_command = "# help", comname = "help"
    my $cleanstr = _command_string_clean_up($orig_command);
    my $context  = $curproc->_build_command_context_template($cleanstr);

    # save original string, set the command mode be "user" by default.
    $context->{ command_mode }     = "User";
    $context->{ original_command } = $orig_command;

    return $context;
}


# Descriptions: parse command buffer to prepare several info
#               after use. return info as HASH_REF.
#    Arguments: OBJ($curproc) STR($fixed_command)
# Side Effects: none
# Return Value: HASH_REF
sub _build_command_context_template
{
    my ($curproc, $fixed_command) = @_;
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();
    my $argv      = $curproc->command_line_argv();

    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    my ($comname, $comsubname) = $check->parse_command_buffer($fixed_command);
    my $options = $check->parse_command_arguments($fixed_command, $comname);
    my $cominfo = {
	command    => $fixed_command,
	comname    => $comname,
	comsubname => $comsubname,
	options    => $options,

	ml_name    => $ml_name,
	ml_domain  => $ml_domain,
	argv       => $argv,

	msg_args   => {},
    };

    return $cominfo;
}


# Descriptions: remove the superflous string before the actual command.
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub _command_string_clean_up
{
    my ($buf) = @_;
    $buf =~ s/^\W+//o;
    return $buf;
}


# Descriptions: declare no more further command processing needed.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_stop_process
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "stop_now", 1);
}


# Descriptions: we stop here or not ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_stop_process
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "stop_now") || 0 );
}


# Descriptions: set "we need to send back confirmation".
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_need_confirm
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "need_confirm", 1);
}


# Descriptions: check if we need to send back confirmation ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_need_confirm
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "need_confirm") || 0 );
}


# Descriptions: remote administrator is authenticated.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_admin_auth
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "admin_auth", 1);
}


# Descriptions: check if remote administrator is authenticated.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_admin_auth
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "admin_auth") || 0 );
}


# Descriptions: store password on memory for later use.
#    Arguments: OBJ($curproc) STR($password)
# Side Effects: update pcb.
# Return Value: STR
sub command_context_set_admin_password
{
    my ($curproc, $password) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "admin_password", $password);
}


# Descriptions: retrive stored password on memory.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub command_context_get_admin_password
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "admin_password") || '' );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::State appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
