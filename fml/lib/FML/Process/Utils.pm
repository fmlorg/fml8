#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.6 2001/12/23 11:37:08 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Process::Utils - small utilities for FML::Process::

=head1 SYNOPSIS

See FML::Process::Kernel.

=head1 DESCRIPTION

=head1 METHODS

=head2 fml_version()

return fml version.

=head2 myname()

return current process name.

=head2 command_line_raw_argv()

@ARGV before getopts() analyze.

=head2 command_line_argv()

@ARGV after getopts() analyze.

=head2 command_line_argv_find(pat)

search pattern in @ARGV and return it if found.

=head2 command_line_options()

return options, result of getopts() analyze.

=cut


# Descriptions: return fml version
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_version
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_version };
}


# Descriptions: return current process name
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub myname
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ myname };
}


# Descriptions: return raw @ARGV of current process,
#               where @ARGV is before getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub command_line_raw_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ argv };
}


# Descriptions: return @ARGV of current process,
#               where @ARGV is after getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub command_line_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ ARGV };
}


# Descriptions: search string matched with specified pattern and
#               return it.
#    Arguments: OBJ($curproc) STR($pat)
# Side Effects: none
# Return Value: STR or UNDEF
sub command_line_argv_find
{
    my ($curproc, $pat) = @_;
    my $argv = $curproc->command_line_argv();

    if (defined $pat) {
	for my $x (@$argv) {
	    if ($x =~ /^$pat/) {
		return $1;
	    }
	}
    }

    return undef;
}


# Descriptions: options, which is the result by getopts() analyze
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub command_line_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ options };
}


=head2 get_virtual_maps()

return virtual maps.

=cut


# Descriptions: options, which is the result by getopts() analyze
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub get_virtual_maps
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args }->{ main_cf };

    if (defined $args->{ virtual_maps } && $args->{ virtual_maps }) {
	my (@r) = ();   
	my (@maps) = split(/\s+/, $args->{ virtual_maps });
	for (@maps) {
	    if (-f $_) { push(@r, $_);}
	}
	return \@r;
    }
    else {
	return undef;
    }
}


=head2 article_id_max()

return the current article number (sequence number).

=cut


# Descriptions: return the current article number (sequence number)
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub article_id_max
{
    my ($curproc) = @_;
    my $config   = $curproc->{ config };
    my $seq_file = $config->{ sequence_file };
    my $id       = undef;

    use FileHandle;
    my $fh = new FileHandle $seq_file;
    if (defined $fh) {
	$id = $fh->getline();
	$id =~ s/^\s*//; $id =~ s/[\n\s]*$//;
	$fh->close();
    }

    if (defined $id) {
	return( $id =~ /^\d+$/ ? $id : 0 );
    }
    else {
	return 0;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Utils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
