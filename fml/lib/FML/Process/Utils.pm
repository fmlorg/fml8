#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Utils.pm,v 1.1 2001/11/04 03:46:50 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Process::Utils - small utilities

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 TODO

=head1 METHODS

=cut


sub fml_version
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_version };
}


sub myname
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ myname };
}


sub command_line_raw_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ argv };
}


sub command_line_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ ARGV };
}


sub command_line_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ options };
}


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

    return( $id =~ /^\d+$/ ? $id : 0 );
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
