#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Text.pm,v 1.13 2003/01/11 15:14:26 fukachan Exp $
#

package Mail::ThreadTrack::Print::Text;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);

#
# XXX-TODO: insert more examples on format in each function.
#

=head1 NAME

Mail::ThreadTrack::Print::Text - printing suitable for text

=head1 SYNOPSIS

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 DESCRIPTION

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 METHODS

=head2 show_articles_in_thread(thread_id)

show articles as text in this thread.

=cut

# XXX-TODO: $is_show_cost_indicate hard-coded.
my $is_show_cost_indicate = 0;

# XXX-TODO: $format hard-coded.
my $format = "%-20s %10s %5s %8s %s\n";


# Descriptions: show articles as text in this thread
#    Arguments: OBJ($self) STR($thread_id)
# Side Effects: none
# Return Value: none
sub show_articles_in_thread
{
    my ($self, $thread_id) = @_;
    my $mode      = $self->get_mode || 'text';
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };
    my $articles  = $self->{ _hash_table }->{ _articles }->{ $thread_id };
    my $wh        = $self->{ _fd } || \*STDOUT;

    use FileHandle;
    if (defined($articles) && defined($spool_dir) && -d $spool_dir) {
	my $s = '';
	# $articles = "1 2 3 4 5";
	for my $id (split(/\s+/, $articles)) {
	    my $file = $self->filepath({
		base_dir => $spool_dir,
		id       => $id,
	    });

	    my $fh = new FileHandle $file;
	    if (defined $fh) {
	      LINE:
		while (defined($_ = $fh->getline())) {
		    next LINE if 1 .. /^$/;

		    # XXX-TODO: we suppose Japanese only here.
		    $s = STR2EUC($_);
		    print $wh $s;
		}
		$fh->close;
	    }
	}
    }
}


# Descriptions: show guide line
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub __start_thread_summary
{
    my ($self, $args) = @_;
    my $fd = $self->{ _fd } || \*STDOUT;

    # XXX-TODO: guide line is hard-coded. o.k.?
    printf($fd $format, 'id', 'date', 'age', 'status', 'articles');
    print $fd "-" x60;
    print $fd "\n";
}


# Descriptions: print formatted brief summary
#    Arguments: OBJ($self) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub __print_thread_summary
{
    my ($self, $optargs) = @_;
    my $fd        = $self->{ _fd } || \*STDOUT;
    my $date      = $optargs->{ date };
    my $age       = $optargs->{ age };
    my $status    = $optargs->{ status };
    my $thread_id = $optargs->{ thread_id };
    my $articles  = $optargs->{ articles };
    my $aid       = (split(/\s+/, $articles))[0]; # the head of this thread

    printf($fd $format, $thread_id, $date, $age, $status,
	   _format_list(25, $articles));
}


# Descriptions: print closing string, empty now (dummy).
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub __end_thread_summary
{
    my ($self, $args) = @_;
    my $fd = $self->{ _fd } || \*STDOUT;
}


# Descriptions: create a string of "a b c .." style up to $num bytes
#    Arguments: NUM($max) STR($str)
# Side Effects: none
# Return Value: STR
sub _format_list
{
    my ($max, $str) = @_;
    my (@idlist) = split(/\s+/, $str);
    my $r = '';

  ID:
    for (@idlist) {
	$r .= $_ . " ";
	if (length($r) > $max) {
	    $r .= "...";
	    last ID;
	}
    }

    return $r;
}


# Descriptions: print message summary
#    Arguments: OBJ($self) STR($thread_id)
# Side Effects: none
# Return Value: none
sub __print_message_summary
{
    my ($self, $thread_id) = @_;
    my $config = $self->{ _config };
    my $age  = $self->{ _age }  || {};
    my $cost = $self->{ _cost } || {};
    my $fd   = $self->{ _fd }   || \*STDOUT;
    my $rh   = $self->{ _hash_table };

    if (defined $config->{ spool_dir }) {
	my ($aid, @aid, $file);
	my $spool_dir = $config->{ spool_dir };

      THREAD_ID_LIST:
	for my $thread_id (@$thread_id) {
	    if ($is_show_cost_indicate) {
		my $how_bad = _cost_to_indicator( $cost->{ $thread_id } );
		printf $fd "\n%6s  %-10s  %s\n", $how_bad, $thread_id;
	    }
	    else {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $thread_id;
	    }

	    # show only the first article of this thread $thread_id
	    if (defined $rh->{ _articles }->{ $thread_id }) {
		(@aid) = split(/\s+/, $rh->{ _articles }->{ $thread_id });
		$aid  = $aid[0];
		$file = $self->filepath({
		    base_dir => $spool_dir,
		    id       => $aid,
		});
		if (-f $file) {
		    $self->print(  $self->message_summary($file) );
		}
	    }
	}
    }
}


# Descriptions: for example, cost -> '!!!'
#               broken now ;-)
#    Arguments: STR($cost)
# Side Effects: none
# Return Value: STR
sub _cost_to_indicator
{
    my ($cost) = @_;
    my $how_bad = 0;

    # XXX-TODO: cost indicator is broken ?
    if ($cost =~ /(\w+)\-(\d+)/) {
	$how_bad += $2;
	$how_bad += 2 if $1 =~ /open/;
	$how_bad  = "!" x ($how_bad > 6 ? 6 : $how_bad);
    }

    $how_bad;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::ThreadTrack::Print::Text first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
