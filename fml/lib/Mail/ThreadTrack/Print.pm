#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Print.pm,v 1.12 2001/11/09 12:08:45 fukachan Exp $
#

package Mail::ThreadTrack::Print;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);

my $is_show_cost_indicate = 0;

=head1 NAME

Mail::ThreadTrack::Print - print out thread relation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 review()

=head2 C<summary(>)

top level entrance for routines to show the thread summary. 

See L<simple_print()> for more detail.
Either of 
C<simple_print()> 
or
C<_summary_print()>
is used for purposes.

Each row that C<show_summary()> returns has a set of 
C<date>, C<age>, C<status>, C<thread-id> and 
C<articles>, which is a list of articles with the thread-id.

=head2 C<simple_print()>

show entries by the thread_id order. For example,

       date    age status  thread id             articles
 ------------------------------------------------------------
 2001/02/07    3.6  going  elena_#00000450       807 808 809 
 2001/02/07    3.1   open  elena_#00000451       810 
 2001/02/07    3.0   open  elena_#00000452       812 
 2001/02/07    3.0   open  elena_#00000453       813 
 2001/02/07    3.0  going  elena_#00000454       814 815 
 2001/02/10    0.1   open  elena_#00000456       821 

=head2 C<_summary_print()> 

show entries in the C<cost> larger order.
The cost is evaluated by $status and $age.
The cost is larger as $age is larger.
It is also larger if $status is C<open>.

=cut


sub summary
{
    my ($self, @opts) = @_;

    $self->_load_library();
    $self->db_open();
    $self->_do_summary(@opts);
    $self->db_close();
}


sub review
{
    my ($self, @opts) = @_;

    $self->_load_library();
    $self->db_open();
    $self->_do_review(@opts);
    $self->db_close();
}



sub _load_library
{
    my ($self) = @_;
    my $mode = $self->get_mode || 'text';

    require Mail::ThreadTrack::Print::Message;
    require Mail::ThreadTrack::Print::Sort;
    my @list = 
	qw(Mail::ThreadTrack::Print::Message Mail::ThreadTrack::Print::Sort);

    if ($mode eq 'text') { 
	require Mail::ThreadTrack::Print::Text;
	push(@list, 'Mail::ThreadTrack::Print::Text');
    }
    elsif ($mode eq 'html') { 
	require Mail::ThreadTrack::Print::HTML;
	push(@list, 'Mail::ThreadTrack::Print::HTML');
    }

    unshift(@ISA, @list);
}


sub _do_summary
{
    my ($self) = @_;
    my ($tid, $status, $thread_id);
    my $mode = $self->get_mode || 'text';
    my $fd   = $self->{ _fd } || \*STDOUT;

    # rh: thread id list, which is ARRAY REFERENCE tied to db_dir/*db's
    $thread_id = $self->list_up_thread_id();

    if (@$thread_id) {
	# sort the thread output order by cost and
	# print the thread summary in that order.
	$self->sort_thread_id($thread_id);
	$self->_print_thread_summary($thread_id);

	# show short summary for each message
	unless ($mode eq 'html') {
	    $self->_print_message_summary($thread_id);
	}
    }
}



sub _print_thread_summary
{
    my ($self, $thread_id_list) = @_;
    my $mode   = $self->get_mode || 'text';
    my $rh_age = $self->{ _age } || {};
    my $fd     = $self->{ _fd } || \*STDOUT;
    my $rh     = $self->{ _hash_table };
    my $format = "%10s  %5s %8s  %-20s  %s\n";

    if ($mode eq 'text') {
	printf($fd $format, 'date', 'age', 'status', 'thread id', 'articles');
	print $fd "-" x60;
	print $fd "\n";
    }
    else {
	print $fd "<TABLE BORDER=4>\n";
	print "<TD>action\n";
	print "<TD>date\n"."<TD>age\n"."<TD>status\n"."<TD>thread id\n";
	print "<TD>article summary\n";
    }

    my ($tid, @article_id, $article_id, $date, $age, $status) = ();
    my $dh = new Mail::Message::Date;
    for $tid (@$thread_id_list) {
	next unless defined $rh->{ _articles }->{ $tid };

	# get the first $article_id from the article_id list
	(@article_id) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$article_id   = $article_id[0];

	# determine $date for the $article_id
	# $age and $status for $thread_id
	$date   = $dh->YYYYxMMxDD( $rh->{ _date }->{ $article_id } , '/');
	$age    = $rh_age->{ $tid };
	$status = $rh->{ _status }->{ $tid };

	if ($mode eq 'html') {
	    eval q{
		use Mail::ThreadTrack::Print::HTML;
		push(@ISA, qw(Mail::ThreadTrack::Print::HTML));
	    };
	}
	else {
	    printf($fd $format, 
		   $date, $age, $status, $tid, $rh->{ _articles }->{ $tid });
	}
    }

    if ($mode eq 'html') {
	print $fd "</TABLE>\n";
    }
}


sub _cost_to_indicator
{
    my ($cost) = @_;
    my $how_bad = 0;

    if ($cost =~ /(\w+)\-(\d+)/) { 
	$how_bad += $2;
	$how_bad += 2 if $1 =~ /open/;
	$how_bad  = "!" x ($how_bad > 6 ? 6 : $how_bad);
    }
}


sub _print_message_summary
{
    my ($self, $thread_id) = @_;
    my $config = $self->{ _config };
    my $age  = $self->{ _age }  || {};
    my $cost = $self->{ _cost } || {};
    my $fd   = $self->{ _fd }   || \*STDOUT;
    my $rh   = $self->{ _hash_table };

    if (defined $config->{ spool_dir }) {
	my ($aid, @aid, $file);
	my $spool_dir  = $config->{ spool_dir };

      THREAD_ID_LIST:
	for my $tid (@$thread_id) {
	    if ($is_show_cost_indicate) {
		my $how_bad = _cost_to_indicator( $cost->{ $tid } );
		printf $fd "\n%6s  %-10s  %s\n", $how_bad, $tid;
	    }
	    else {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $tid;
	    }

	    # show only the first article of this thread $tid
	    if (defined $rh->{ _articles }->{ $tid }) {
		(@aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
		$aid  = $aid[0];
		$file = File::Spec->catfile($spool_dir, $aid);
		if (-f $file) {
		    print $fd $self->message_summary($file);
		}
	    }
	}
    }
}


sub _do_review
{
    my ($self, $str, $min, $max) = @_;
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };
    my $fd        = $self->{ _fd } || \*STDOUT;
    my $rh        = $self->{ _hash_table };
    my %uniq      = ();

    # modify Print parameters 
    $self->{ _article_summary_lines } = 5;

    use Mail::Message::MH;
    my $ra = Mail::Message::MH->expand($str, $min, $max);
    my $first = 0;

    if (defined $config->{ reverse_order }) { @$ra = reverse @$ra;}

  ID_LIST:
    for my $id (@$ra) {
	next ID_LIST unless defined $id;

	if ($id =~ /^\d+$/) {
	    # create thread identifier string: e.g. 100 -> elena/100
	    my $tid = $self->_create_thread_id_strings($id);

	    # check thread id $tid exists really ?
	    if (defined $rh->{ _articles }->{ $tid }) {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $tid;

		# different treatment for the fisrt article in this thread
		$first = 1;

		# show all articles in this thread
	      ARTICLE:
		for my $aid (split(/\s+/, $rh->{ _articles }->{ $tid })) {
		    # ensure uniquness
		    next ARTICLE if $uniq{ $aid };
		    $uniq{ $aid } = 1;

		    if ($first) {
			undef $self->{ _no_header_summary };
			$first = 0;
		    }
		    else {
			$self->{ _no_header_summary } = 1;
		    }

		    my $file = File::Spec->catfile($spool_dir, $aid);
		    if (-f $file) {
			print $fd $self->message_summary($file);
			print $fd "\n";
		    }
		}
	    }
	}
    }
}


1;
