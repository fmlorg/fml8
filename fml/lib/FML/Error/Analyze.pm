#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Analyze.pm,v 1.2 2002/08/07 15:06:58 fukachan Exp $
#

package FML::Error::Analyze;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


my $debug = 1;


=head1 NAME

FML::Error::Analyze - analyzer routine for error cache

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self) HASH_REF($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# *** model specific analyzer ***
# $data = {
#    address => [ 
#           error_string_1,
#           error_string_2, ... 
#    ]
# };
#
sub simple_count
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count);
    my @removelist = ();
    my $summary    = {};
    my $config     = $curproc->config();
    my $limit      = $config->{ error_analyzer_simple_count_limit } || 5;

    while (($addr, $bufarray) = each %$data) {
	$count = 0;
	if (defined $bufarray) {
	    for my $buf (@$bufarray) {
		if ($buf =~ /status=5/i) {
		    $count++;
		    $summary->{ $addr } = $count;
		}
	    }
	}

	if ($count > $limit) {
	    push(@removelist, $addr);
	}
    }

    # debug info
    if ($debug) {
	Log("analyze summary");
	my ($k, $v);
	while (($k, $v) = each %$summary) {
	    Log("summary: $k = $v points");
	}
    }

    return \@removelist;
}


sub simple_count_by_day
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count);
    my ($time, $status, $reason);
    my @removelist = ();
    my $summary    = {};
    my $config     = $curproc->config();
    my $limit      = $config->{ error_analyzer_simple_count_limit } || 5;

    while (($addr, $bufarray) = each %$data) {
	$count = 0;
	if (defined $bufarray) {
	    for my $buf (@$bufarray) {
		($time, $status, $reason) = split(/\s+/, $buf);

		if ($buf =~ /status=5/i) {
		    my $i = int( (time - $time ) / (24*3600) );

		    unless (defined $summary->{ $addr }) {
			$summary->{ $addr } = [ ];
		    }

		    if ($i <= $limit) {
			$summary->{ $addr }->[ $i ] = 1;
		    }
		}
	    }
	}
    }

    # debug info
    {
	my ($addr, $ra);
	while (($addr, $ra) = each %$summary) {
	    Log("summary: $addr = (@$ra) points");
	}
    }

    return \@removelist;
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

FML::Error::Analyze appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
