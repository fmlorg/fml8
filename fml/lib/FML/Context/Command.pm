#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.10 2006/01/07 13:16:41 fukachan Exp $
#

package FML::Context::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Context::Command - command mail context information

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: none
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };

    # save original string, set the command mode be "user" by default.
    $me->{ command_mode }     = "User";

    return bless $me, $type;
}


# Descriptions: save original command string.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update $self.
# Return Value: none
sub set_command
{
    my ($self, $command) = @_;
    $self->{ original_command } = $command || undef;
    $self->_build_object();
}


# Descriptions: return original command string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_command
{
    my ($self) = @_;
    return( $self->{ original_command } || undef );
}


# Descriptions: save cooked (cleaned) command string.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update $self.
# Return Value: none
sub set_cooked_command
{
    my ($self, $command) = @_;
    $self->{ comname } = $command || undef;
}


# Descriptions: return cooked (cleaned) command string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_cooked_command
{
    my ($self) = @_;
    return( $self->{ comname } || undef );
}


# Descriptions: save cooked (cleaned) sub command string.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update $self.
# Return Value: none
sub set_cooked_subcommand
{
    my ($self, $command) = @_;
    $self->{ comsubname } = $command || undef;
}


# Descriptions: return cooked (cleaned) sub command string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_cooked_subcommand
{
    my ($self) = @_;
    return( $self->{ comsubname } || undef );
}


# Descriptions: build object.
#    Arguments: OBJ($self)
# Side Effects: set up several $self parameters.
# Return Value: none
sub _build_object
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $command = $self->{ original_command };

    if (defined $command && $command) {
	my $clean_command = $self->_cleanup($command);
	$self->_build_command_context_template($clean_command);
    }
    else {
	$curproc->logerror("command context: invalid configuration");
    }
}


# Descriptions: parse command buffer to prepare several info
#               after use. return info as HASH_REF.
#    Arguments: OBJ($self) STR($clean_command)
# Side Effects: none
# Return Value: none
sub _build_command_context_template
{
    my ($self, $clean_command) = @_;
    my $curproc   = $self->{ _curproc };
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();
    my $argv      = $curproc->command_line_argv();

    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    my ($comname, $comsubname) = $check->parse_command_buffer($clean_command);
    my $options = $check->parse_command_arguments($clean_command, $comname);

    $self->{ command    } = $clean_command;
    $self->set_cooked_command($comname);
    $self->set_cooked_subcommand($comsubname);
    $self->set_options($options);
    $self->{ ml_name    } = $ml_name;
    $self->{ ml_domain  } = $ml_domain;
    $self->{ argv	} = $argv;
    $self->set_msg_args( {} );
}


# Descriptions: remove the superflous string before the actual command.
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: STR
sub _cleanup
{
    my ($self, $buf)   = @_;
    my $curproc        = $self->{ _curproc };
    my $config         = $curproc->config();
    my $confirm_prefix = $config->{ confirm_command_prefix };

    $buf =~ s/^\W+$confirm_prefix/$confirm_prefix/;
    return $buf;
}


# Descriptions: save message system parameters (HASH_REF).
#    Arguments: OBJ($self) HASH_REF($value)
# Side Effects: update $self.
# Return Value: none
sub set_msg_args
{
    my ($self, $value) = @_;
    $self->{ msg_args } = $value || {};
}


# Descriptions: return message system parameters as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_msg_args
{
    my ($self) = @_;
    return( $self->{ msg_args } || {} );
}


# Descriptions: save options.
#    Arguments: OBJ($self) ARRAY_REF($value)
# Side Effects: update $self.
# Return Value: none
sub set_options
{
    my ($self, $value) = @_;
    $self->{ options } = $value || [];
}


# Descriptions: return options as ARRAY_REF
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_options
{
    my ($self) = @_;
    return( $self->{ options } || [] );
}


# Descriptions: save admin options.
#    Arguments: OBJ($self) HASH_REF($value)
# Side Effects: update $self.
# Return Value: none
sub set_admin_options
{
    my ($self, $value) = @_;
    $self->{ admin_options } = $value || {};
}


# Descriptions: retrun admin options.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_admin_options
{
    my ($self) = @_;
    return( $self->{ admin_options } || {} );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Context::Command appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
