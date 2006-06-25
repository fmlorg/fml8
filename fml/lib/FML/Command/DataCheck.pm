#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DataCheck.pm,v 1.18 2005/08/19 12:17:07 fukachan Exp $
#

package FML::Command::DataCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


#
# XXX-TODO: rename DataCheck -> Parse ?
#


=head1 NAME

FML::Command::DataCheck - parse, clean up et.al. command buffer.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: return command name ( ^\S+ in $command ) and the sub name.
#               remove the prepending strings such as \s, #, ...
#    Arguments: OBJ($self) STR($command)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub parse_command_buffer
{
    my ($self, $command) = @_;

    $command = $self->cleanup($command);
    my ($comname, $comsubname) = split(/\s+/, $command);
    return ($comname, $comsubname);
}


# Descriptions: return arguments after command name $comname in $command.
#    Arguments: OBJ($self) STR($command) STR($comname)
# Side Effects: none
# Return Value: ARRAY_REF
sub parse_command_arguments
{
    my ($self, $command, $comname) = @_;
    my $found     = 0;
    my (@options) = ();

    # XXX-TODO: $comname matches exactly.
    # XXX-TODO: so, you need lower/uppercase before this routine.

    # pick up arguments into @options after $comname.
    # Example:
    #    $comname = "subscribe";
    #    $command = "subscribe rudo von schmit";
    #    @options = [ 'rudo', 'von', 'shmit' ];
    for my $buf (split(/\s+/, $command)) {
	push(@options, $buf) if $found;
	$found = 1 if $buf eq $comname;
    }

    return \@options;
}


#
# XXX-TODO: find_special_keyword() NOT USED ? YES. REMOVE IT.
#


# Descriptions: check the message of the current process to find
#               whether it contains some special keyword e.g. "confirm".
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($ra_data)
# Side Effects: none
# Return Value: HASH_REF
sub find_special_keyword
{
    my ($self, $curproc, $ra_data) = @_;
    my $config         = $curproc->config();
    my $confirm_prefix = $config->{ confirm_command_prefix };
    my $admin_prefix   = $config->{ privileged_command_prefix };
    my $confirm_found  = '';
    my $admin_found    = '';

    # clean up
    $confirm_prefix = $self->cleanup($confirm_prefix);
    $admin_prefix   = $self->cleanup($admin_prefix);

    # XXX $ra_data is not whole body but already parsed and prepared buffer.
    # XXX See below and FML::Process::Command module, for example.
    # XXX not use /^$regexp/ due to the case such as "> confirm ...".
    for my $buf (@$ra_data) {
	if ($buf =~ /$confirm_prefix\s+\w+\s+([\w\d]+)/) {
	    $confirm_found = $1;
	}

	if ($buf =~ /$admin_prefix\s+\w+\s+([\w\d]+)/) {
	    $admin_found = $1;
	}
    }

    return {
	confirm_keyword => $confirm_found,
	admin_keyword   => $admin_found,
    };
}


#
# XXX-TODO: find_anonymous_command_mail_allowed_commands() NOT USED? YES. RM!
#


# Descriptions: check the message of the current process to find
#               whether it contais special keyword e.g. "confirm".
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: NUM( 1 or )
sub find_anonymous_command_mail_allowed_commands
{
    my ($self, $curproc) = @_;
    my $config   = $curproc->config();
    my $commands = $config->get_as_array_ref('anonymous_command_mail_allowed_commands');
    my $body     = $curproc->incoming_message_body();
    my $msg      = $body->find_first_plaintext_message();

    # assert
    unless (defined $msg) {
	return 0;
    }

    # XXX-TODO: use message_text_as_array_ref().
    my (@body)   = split(/\n/, $msg->message_text );
    my $comname  = '';

  LINE:
    for my $buf (@body) {
	($comname) = $self->parse_command_buffer( $buf );
	next LINE unless defined($comname) && $comname;

	# $comname matches one of $anonymous_command_mail_allowed_commands ?
	# XXX-TODO: we need to care for lowercase/uppercase mismtach ?
	# XXX-TODO: need to define macro EQUAL_CASE_INSENSITIVE(a,b) ?
      COMMAND:
	for my $proc (@$commands) {
	    next COMMAND unless defined($proc) && $proc;

	    return 1 if $comname eq $proc;
	}
    };

    my $data = $self->find_special_keyword($curproc, \@body);
    return 1 if $data->{ confirm_keyword };

    return 0;
}


# Descriptions: clean up the given string and return a cleaned one.
#               For example, "# ls uja " -> "ls uja"
#    Arguments: OBJ($self) STR($s)
# Side Effects: none
# Return Value: STR
sub cleanup
{
    my ($self, $s) = @_;

    $s =~ s/^[\#\s]*//;
    $s =~ s/\s*$//;

    return $s;
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

FML::Command::DataCheck first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
