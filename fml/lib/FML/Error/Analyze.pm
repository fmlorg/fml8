#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Analyze.pm,v 1.9 2002/12/12 04:57:53 fukachan Exp $
#

package FML::Error::Analyze;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


my $debug = 1;


=head1 NAME

FML::Error::Analyze - provide model specific analyzer routines.

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


=head2 $data STRUCTURE

C<$data> is passed to the error analyer function.

	 $data = {
	    address => [
	           error_info_1,
	           error_info_2, ...
	    ]
	 };

where the error_info_* has error reasons.

=head1 METHODS

=head2 simple_count()

=cut


# Descriptions: count up the number of errors.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($data)
# Side Effects: none
# Return Value: ARRAY_REF
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

	# count up the number of error messsages if the status is 5XX.
	if (defined $bufarray) {
	    for my $buf (@$bufarray) {
		if ($buf =~ /status=5/i) {
		    $count++;
		    $summary->{ $addr } = $count;
		}
	    }
	}

	# add address to the removal list if the count is over $limit.
	if ($count > $limit) {
	    push(@removelist, $addr);
	}
    }

    # debug info
    if ($debug) {
	Log("error: simple_count analyzer summary");
	my ($k, $v);
	while (($k, $v) = each %$summary) {
	    Log("summary: $k = $v points");
	}
    }

    return \@removelist;
}


=head2 error_continuity()

    examine the continuity of error messages (*).
    --------------------> time
         *           ok
        *********    bad
        * * *** *    ambiguous

but sum up count as the delta.

         *
        ***

=cut


# Descriptions: error continuity based cost counting
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($data)
# Side Effects: none
# Return Value: ARRAY_REF
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
		# count if the top of the mountain is over 2.
		if (defined $v) {
		    $sum += 1 if $v >= 2;
		}
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

FML::Error::Analyze first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
