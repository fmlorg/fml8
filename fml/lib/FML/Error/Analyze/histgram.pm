#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: histgram.pm,v 1.12 2004/12/05 16:19:08 fukachan Exp $
#

package FML::Error::Analyze::histgram;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 1;


=head1 NAME

FML::Error::Analyze::histgram - cost evaluator.

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


# Descriptions: top level dipatcher to run cost evaluator.
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


# Descriptions: error continuity based cost counting.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($data)
# Side Effects: none
# Return Value: ARRAY_REF
sub _histgram
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count, $i, $time, $status, $reason);
    my @removelist = ();
    my $summary    = {};
    my $config     = $curproc->config();
    my $limit      = $config->{ error_mail_analyzer_simple_count_limit } || 14;
    my $daylimit   = $config->{ error_mail_analyzer_day_limit } || 14;
    my $now        = time;                 # unix time (seconds).
    my $half_day   = 12   * 3600 ;         # 12 hours  (seconds).
    my $one_day    = 24   * 3600 ;         # 24 hours  (seconds).
    my $threshold  = $one_day * $daylimit; # how old   (seconds).

    # $data format = {
    #             key1 => [ value1, value2, ... ],
    #             key2 => [ value1, value2, ... ],
    #          }
    while (($addr, $bufarray) = each %$data) {
	$count = 0;

	if (defined $bufarray) {
	  BUF:
	    for my $buf (@$bufarray) {
		($time, $status, $reason) = split(/\s+/, $buf);

		# ignore too old data.
		next BUF if (($now - $time) > $threshold);

		if ($buf =~ /status=5/i) {
		    unless (defined $summary->{ $addr }) {
			$summary->{ $addr } = [ 0 ];
		    }

		    # center of distribution function
		    $i = int( ($now - $time ) / $one_day );
		    $summary->{ $addr }->[ $i ] += 2;

		    # +delta
		    $i = int( ($now - $time + $half_day) / $one_day );
		    $summary->{ $addr }->[ $i ] += 1;

		    # -delta
		    $i = int( ($now - $time - $half_day) / $one_day );
		    $summary->{ $addr }->[ $i ] += 1 if $i >= 0;
		}
		elsif ($buf =~ /status=4/i) {
		    unless (defined $summary->{ $addr }) {
			$summary->{ $addr } = [ 0 ];
		    }

		    # center of distribution function
		    $i = int( ($now - $time ) / $one_day );
		    $summary->{ $addr }->[ $i ] += 0.25;

		    # +delta
		    $i = int( ($now - $time + $half_day) / $one_day );
		    $summary->{ $addr }->[ $i ] += 0.25;

		    # -delta
		    $i = int( ($now - $time - $half_day) / $one_day );
		    $summary->{ $addr }->[ $i ] += 0.25 if $i >= 0;
		}
	    }
	}
    }

    # debug info
    {
	my $addr = '';
	my $ra   = ();
	my $sum  = 0;
	while (($addr, $ra) = each %$summary) {
	    $sum = 0;
	    for my $v (@$ra) {
		# count if the top of the mountain is over 2.
		if (defined $v) {
		    $sum += 1 if $v >= 2;
		}
	    }

	    my $array = _ra_to_str($ra);
	    $curproc->logdebug("summary: $addr sum=$sum ($array)");
	    push(@removelist, $addr) if $sum >= $limit;
	}
    }

    # save info
    $self->{ _summary } = $summary;

    # save address for removal candidates
    $self->{ _address_to_be_removed } = \@removelist;
}


# Descriptions: return array list with 0 padding (debug).
#    Arguments: ARRAY_REF($ra)
# Side Effects: none
# Return Value: STR
sub _ra_to_str
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
sub get_summary
{
    my ($self) = @_;

    return( $self->{ _summary } || {} );
}


# Descriptions: return addresses to be removed.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_address_to_be_removed
{
    my ($self) = @_;

    return( $self->{ _address_to_be_removed } || [] );
}


# Descriptions: print summary for the specified address.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self, $addr) = @_;
    my $wh       = \*STDOUT;
    my $summary  = $self->get_summary();
    my $bufarray = $summary->{ $addr } || [];
    my $result   = _ra_to_str($bufarray);

    printf $wh "%25s => (%s)\n", $addr, $result;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error::Analyze::simple_count appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
