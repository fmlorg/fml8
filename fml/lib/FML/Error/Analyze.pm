#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Analyze.pm,v 1.3 2002/08/17 02:38:37 fukachan Exp $
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


sub error_continuity
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count, $i);
    my ($time, $status, $reason);
    my @removelist = ();
    my $summary    = {};
    my $config     = $curproc->config();
    my $limit      = $config->{ error_analyzer_simple_count_limit } || 14;

    while (($addr, $bufarray) = each %$data) {
	$count = 0;
	if (defined $bufarray) {
	    for my $buf (@$bufarray) {
		($time, $status, $reason) = split(/\s+/, $buf);

		if ($buf =~ /status=5/i) {
		    unless (defined $summary->{ $addr }) {
			$summary->{ $addr } = [ 0 ];
		    }

		    # count up the folloging distribution function.
		    #     *
		    #    ***

		    # center of distribution function
		    $i = int( (time - $time ) / (24*3600) );
		    $summary->{ $addr }->[ $i ] += 2;

		    # +delta
		    $i = int( (time - $time + 12*3600) / (24*3600) );
		    $summary->{ $addr }->[ $i ] += 1;

		    # -delta
		    $i = int( (time - $time - 12*3600) / (24*3600) );
		    $summary->{ $addr }->[ $i ] += 1 if $i >= 0;
		}
	    }
	}
    }

    # debug info
    {
	my ($addr, $ra, $sum);
	while (($addr, $ra) = each %$summary) {
	    $sum = 0;
	    for my $v (@$ra) {
		$sum += 1 if $v >= 2;
	    }

	    Log("summary: $addr sum=$sum (@$ra)");

	    push(@removelist, $addr) if $sum >= $limit;
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
