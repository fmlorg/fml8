#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Sort.pm,v 1.9 2002/12/22 03:21:33 fukachan Exp $
#

package Mail::ThreadTrack::Print::Sort;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

Mail::ThreadTrack::Print::Sort - sort function for printing

=head1 SYNOPSIS

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 DESCRIPTION

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 METHODS

=head2 sort_thread_id($thread_id_list)

=cut


# Descriptions: sort ARRAY REFERENCE $thread_id_list
#    Arguments: OBJ($self) ARRAY_REF($thread_id_list)
# Side Effects: initialize $self->{ _age } and $self->{ _cost }
# Return Value: ARRAY_REF
sub sort_thread_id
{
    my ($self, $thread_id_list) = @_;

    # get age HASH TABLE
    my ($age, $cost) = $self->_calculate_age($thread_id_list);
    $self->{ _age }  = $age;
    $self->{ _cost } = $cost;

    @$thread_id_list = sort {
	$cost->{$b} <=> $cost->{$a}
    } @$thread_id_list;

    return $thread_id_list;
}


my $status_cost = {
    open     => ( 1 << 10 ),
    analyzed => ( 1 <<  9 ),
};


# Descriptions: evaluate how old and status each thread is
#    Arguments: OBJ($self) ARRAY_REF($thread_id_list)
# Side Effects: none
# Return Value: ARRAY( HASH_REF, HASH_REF )
sub _calculate_age
{
    my ($self, $thread_id_list) = @_;
    my (%age, %cost) = ();
    my $now = time; # save the current UTC for convenience
    my $rh  = $self->{ _hash_table } || {};
    my $day = 24*3600;

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
	my $status = $rh->{ _status }->{ $tid };
	$cost{ $tid } = $status_cost->{ $status } + $age;
    }

    return (\%age, \%cost);
}



=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::ThreadTrack::Print::Sort first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
