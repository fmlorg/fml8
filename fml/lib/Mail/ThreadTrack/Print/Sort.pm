#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Sort.pm,v 1.2 2001/11/09 12:08:46 fukachan Exp $
#

package Mail::ThreadTrack::Print::Sort;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head2 sort_thread_id($thread_id_list)

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub sort_thread_id
{
    my ($self, $thread_id_list) = @_;

    # get age HASH TABLE
    my ($age, $cost) = $self->_calculate_age($thread_id_list);
    $self->{ _age }  = $age;
    $self->{ _cost } = $cost;

    @$thread_id_list = sort { 
	(defined($cost->{$b}) ? $cost->{$b} : '') 
	    cmp 
		(defined($cost->{$a}) ? $cost->{$a} : '')
    } @$thread_id_list;

    return $thread_id_list;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _calculate_age
{
    my ($self, $thread_id_list) = @_;
    my (%age, %cost) = ();
    my $now   = time; # save the current UTC for convenience
    my $rh    = $self->{ _hash_table } || {};
    my $day   = 24*3600;

    # $age hash referehence = { $thread_id => $age };
    my (@aid, $last, $age, $date, $status, $tid) = ();
    for $tid (sort @$thread_id_list) {
	next unless defined $rh->{ _articles }->{ $tid };

	# $last: get the latest one of article_id's
	(@aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$last  = $aid[ $#aid ] || 0;

	# how long this thread is not concerned ?
	$age = sprintf("%2.1f%s", ($now - $rh->{ _date }->{ $last })/$day);
	$age{ $tid } = $age;

	# evaluate cost hash table which is { $thread_id => $cost }
	$cost{ $tid } = $rh->{ _status }->{ $tid }.'-'. $age;
    }

    return (\%age, \%cost);
}


1;
