#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: simple_count.pm,v 1.10 2004/07/23 13:16:37 fukachan Exp $
#

package FML::Error::Analyze::simple_count;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 1;


=head1 NAME

FML::Error::Analyze::simple_count - simple cost evaluator.

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


=head2 process($curproc, $data)

count up the number of error messsages if the status is [45]XX.
The cost to sum up varies according to the status code.

=cut


# Descriptions: main dispatcher.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($data)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $data) = @_;
    $self->_simple_count($curproc, $data);
}


# Descriptions: simply count up the number of errors.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($data)
# Side Effects: none
# Return Value: ARRAY_REF
sub _simple_count
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count);
    my ($time, $status, $reason);
    my @removelist = ();
    my $summary    = {};
    my $config     = $curproc->config();
    my $limit      = $config->{ error_mail_analyzer_simple_count_limit } || 5;
    my $daylimit   = $config->{ error_mail_analyzer_day_limit } || 14;
    my $now        = time;
    my $day        = 24*3600;
    my $threshold  = $day * $daylimit;

    # $data format = {
    #             key1 => [ value1, value2, ... ],
    #             key2 => [ value1, value2, ... ],
    #          }
    while (($addr, $bufarray) = each %$data) {
	$count = 0;

	# count up the number of error messsages if the status is [45]XX.
	if (defined $bufarray) {
	  ELEMENT:
	    for my $buf (@$bufarray) {
		($time, $status, $reason) = split(/\s+/, $buf);

		# ignore too old data.
		next ELEMENT if (($now - $time) > $threshold);

		# XXX-TODO: cost should be customizable.
		if ($buf =~ /status=5/i) {
		    $count += 1.0;
		}
		elsif ($buf =~ /status=4/i) {
		    $count += 0.25;
		}
		else {
		    $count += 0.1;
		}

		$summary->{ $addr } = $count;
	    }
	}

	# add address to the removal list if the count is over $limit.
	if ($count > $limit) {
	    push(@removelist, $addr);
	}
    }

    # save info
    $self->{ _summary } = $summary;

    # save address for removal candidates
    $self->{ _address_to_be_removed } = \@removelist;
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


# Descriptions: print address and the summary.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self, $addr) = @_;
    my $wh      = \*STDOUT;
    my $summary = $self->get_summary();

    printf $wh "%25s => %s\n", $addr, $summary->{ $addr };
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
