#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: histgram.pm,v 1.4 2003/08/23 07:24:45 fukachan Exp $
#

package FML::Error::Analyze::histgram;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

my $debug = 1;


=head1 NAME

FML::Error::Analyze::histgram - cost evaluator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new($curproc)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: cost evaluator.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($data)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $data) = @_;
    $self->_histgram($curproc, $data);
}


=head2 histgram()

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
sub _histgram
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count, $i);
    my ($time, $status, $reason);
    my @removelist = ();
    my $summary    = {};
    my $config     = $curproc->config();
    my $limit      = $config->{ error_analyzer_simple_count_limit } || 14;
    my $daylimit   = $config->{ error_analyzer_day_limit } || 14;
    my $now        = time;
    my $day        = 24*3600;
    my $threshold  = $day * $daylimit;

    while (($addr, $bufarray) = each %$data) {
	$count = 0;
	if (defined $bufarray) {
	    for my $buf (@$bufarray) {
		($time, $status, $reason) = split(/\s+/, $buf);
		next if ((time - $time) > $threshold);

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
		elsif ($buf =~ /status=4/i) {
		    unless (defined $summary->{ $addr }) {
			$summary->{ $addr } = [ 0 ];
		    }

		    # center of distribution function
		    $i = int( (time - $time ) / (24*3600) );
		    $summary->{ $addr }->[ $i ] += 0.25;

		    # +delta
		    $i = int( (time - $time + 12*3600) / (24*3600) );
		    $summary->{ $addr }->[ $i ] += 0.25;

		    # -delta
		    $i = int( (time - $time - 12*3600) / (24*3600) );
		    $summary->{ $addr }->[ $i ] += 0.25 if $i >= 0;
		}
	    }
	}
    }

    # debug info
    {
	my $addr = '';
	my $sum  = 0;
	my $ra   = ();
	while (($addr, $ra) = each %$summary) {
	    $sum = 0;
	    for my $v (@$ra) {
		# count if the top of the mountain is over 2.
		if (defined $v) {
		    $sum += 1 if $v >= 2;
		}
	    }

	    my $array = __debug_printable_array($ra);
	    $curproc->log("summary: $addr sum=$sum ($array)");
	    push(@removelist, $addr) if $sum >= $limit;
	}
    }

    # save info
    $self->{ _summary } = $summary;

    # save address for removal candidates
    $self->{ _removal_address } = \@removelist;
}


# Descriptions: return array list with 0 padding (debug)
#    Arguments: ARRAY_REF($ra)
# Side Effects: none
# Return Value: STR
sub __debug_printable_array
{
    my ($ra) = @_;
    my $s    = '';

    for my $x (@$ra) {
	$s .= defined $x ? $x : 0;
	$s .= " ";
    }

    return $s;
}


# Descriptions: return summary as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub summary
{
    my ($self) = @_;

    return( $self->{ _summary } || {} );
}


# Descriptions: return addresses to be removed.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub removal_address
{
    my ($self) = @_;

    return( $self->{ _removal_address } || [] );
}


# Descriptions: print address and the summary
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self, $addr) = @_;
    my $wh       = \*STDOUT;
    my $summary  = $self->summary();
    my $bufarray = $summary->{ $addr } || [];
    my $x        = '';
    my $y        = '';

    for my $y (@$bufarray) {
	$x .= defined $y ? $y : 0;
	$x .= " ";
    }

    $x =~ s/^\s*//;
    $x =~ s/\s*$//;
    printf $wh "%25s => (%s)\n", $addr, $x;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error::Analyze::simple_count appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
