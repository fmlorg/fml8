#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package FML::Command::DataCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::DataCheck - check data as command(s)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

=cut


# Descriptions: ordinary constructor
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


# Descriptions: return command name ( ^\S+ in $command ).
#               remove the prepending strings such as \s, #, ...
#    Arguments: OBJ($self) STR($command)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub parse_command_buffer
{
    my ($self, $command) = @_;

    $command = $self->clean_up($command);
    my ($comname, $comsubname) = split(/\s+/, $command);
    return ($comname, $comsubname);
}


# Descriptions: parse command buffer to make
#               argument vector after command name
#    Arguments: OBJ($STR) STR($command) STR($comname)
# Side Effects: none
# Return Value: ARRAY_REF
sub parse_command_arguments
{
    my ($command, $comname) = @_;
    my $found = 0;
    my (@options) = ();

    for my $buf (split(/\s+/, $command)) {
	push(@options, $buf) if $found;
	$found = 1 if $buf eq $comname;
    }

    return \@options;
}


# Descriptions: check message of the current process
#               whether it contais keyword e.g. "confirm".
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($ra_data)
# Side Effects: none
# Return Value: HASH_REF
sub find_special_keyword
{
    my ($self, $curproc, $ra_data) = @_;
    my $config         = $curproc->{ config };
    my $confirm_prefix = $config->{ confirm_command_prefix };
    my $admin_prefix   = $config->{ privileged_command_prefix };
    my $confirm_found  = '';
    my $admin_found    = '';

    # clean up
    $confirm_prefix = $self->clean_up($confirm_prefix);
    $admin_prefix   = $self->clean_up($admin_prefix);

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


# Descriptions: clean up the given string and return a cleaned one.
#               For example, "# ls uja " -> "ls uja"
#    Arguments: OBJ($self) STR($s)
# Side Effects: none
# Return Value: STR
sub clean_up
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

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::DataCheck appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
