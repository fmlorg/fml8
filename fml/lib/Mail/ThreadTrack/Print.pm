#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Print.pm,v 1.25 2002/09/11 23:18:29 fukachan Exp $
#

package Mail::ThreadTrack::Print;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);

=head1 NAME

Mail::ThreadTrack::Print - dispatcher to print out thread

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 list()

show todo list without article summary.

=cut


# Descriptions: show todo list without article summary.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub list
{
    my ($self, @opts) = @_;

    $self->_load_library();
    $self->db_open();
    $self->_do_list(@opts);
    $self->db_close();
}


=head2 summary()

show the thread summary, which is todo list C<with> article summary.

Each row that C<show_summary()> returns has a set of
C<date>, C<age>, C<status>, C<thread-id> and
C<articles>, which is a list of articles with the thread-id.

summary show entries by the thread_id order. For example,

       date    age status  thread id             articles
 ------------------------------------------------------------
 2001/02/07    3.6  going  elena_#00000450       807 808 809
 2001/02/07    3.1   open  elena_#00000451       810
 2001/02/07    3.0   open  elena_#00000452       812
 2001/02/07    3.0   open  elena_#00000453       813
 2001/02/07    3.0  going  elena_#00000454       814 815
 2001/02/10    0.1   open  elena_#00000456       821

=cut


# Descriptions: show todo list with article summary.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub summary
{
    my ($self, @opts) = @_;

    $self->_load_library();
    $self->db_open();
    $self->_do_summary(@opts);
    $self->db_close();
}


=head2 review()

show a chain of article summary in each thread.
This summary is a collection of short summary of articles in one thread.

=cut


# Descriptions: show summary for each thread
#    Arguments: OBJ($self) VARARGS
# Side Effects: none
# Return Value: none
sub review
{
    my ($self, @opts) = @_;

    $self->_load_library();
    $self->db_open();
    $self->_do_review(@opts);
    $self->db_close();
}



# Descriptions: load subclasses, change @INC
#    Arguments: OBJ($self)
# Side Effects: @INC modified
# Return Value: none
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


#
# SUMMARY MODE
#


# Descriptions: dispatcher to show todo list with article summary.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _do_summary
{
    my ($self) = @_;
    $self->__do_summary( { mode => 'summary' });
}


# Descriptions: dispatcher to show todo list without article summary.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _do_list
{
    my ($self) = @_;
    $self->__do_summary( { mode => 'list' });
}


# Descriptions: get thread id list with status != 'close' and
#               show summary for the list
#    Arguments: OBJ($self) HASH_REF($option)
# Side Effects: none
# Return Value: none
sub __do_summary
{
    my ($thread, $option) = @_;
    my $mode   = $thread->get_mode || 'text';
    my $config = $thread->{ _config };

    # rh: thread id list picked from status.db
    my $thread_id_list = $thread->list_up_thread_id();

    # 1. sort the thread output order by cost
    # 2. print the thread brief summary in that order.
    # 3. show short summary for each message if needed (mode dependent)
    if (@$thread_id_list) {
	$thread->sort_thread_id($thread_id_list);

	# reverse order (first thread is the latest one) if reverse mode
	if ($config->{ reverse_order }) {
	    @$thread_id_list = reverse @$thread_id_list;
	}

	$thread->_print_thread_summary($thread_id_list);

	if ($option->{ mode } eq 'summary') {
	    $thread->_print_message_summary($thread_id_list);
	}
    }
}



# Descriptions: show thread summary
#    Arguments: OBJ($self) ARRAY_REF($thread_id_list)
# Side Effects: none
# Return Value: none
sub _print_thread_summary
{
    my ($self, $thread_id_list) = @_;
    my $mode = $self->get_mode || 'text';
    my $db   = $self->{ _hash_table };

    # guide of presentation
    $self->__start_thread_summary(); # XXX dynamic binding

    # show brief summary along thread_id list
    my ($thread_id, @article_id, $article_id, $date, $age, $status) = ();
    my $date_h = new Mail::Message::Date;
    for $thread_id (@$thread_id_list) {
	next unless defined $db->{ _articles }->{ $thread_id };

	# get the first $article_id from the article_id list
	(@article_id) = split(/\s+/, $db->{ _articles }->{ $thread_id });
	$article_id   = $article_id[0];

	# format $date for the $article_id
	$date   = $date_h->YYYYxMMxDD( $db->{ _date }->{ $article_id } , '/');
	$age    = $self->{ _age }->{ $thread_id };
	$status = $db->{ _status }->{ $thread_id };

	$self->__print_thread_summary( {
	    date      => $date,
	    age       => $age,
	    status    => $status,
	    thread_id => $thread_id,
	    articles  => $db->{ _articles }->{ $thread_id },
	}); # XXX dynamic binding
    }

    $self->__end_thread_summary(); # XXX dynamic binding
}


# Descriptions: show the first few lines of the first message in the thread
#    Arguments: OBJ($self) STR($thread_id)
# Side Effects: none
# Return Value: none
sub _print_message_summary
{
    my ($self, $thread_id) = @_;
    $self->__print_message_summary($thread_id);
}


#
# REVIEW MODE
#

# Descriptions: show brief summary chain of messages in the thread
#    Arguments: OBJ($self) STR($str) NUM($min) NUM($max)
# Side Effects: none
# Return Value: none
sub _do_review
{
    my ($self, $str, $min, $max) = @_;
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };
    my $fd        = $self->{ _fd } || \*STDOUT;
    my $db        = $self->{ _hash_table };
    my %uniq      = ();
    my $is_first  = 0;

    # translate the given parameter (MH style)
    # get ARRAY_REF of specified range
    use Mail::Message::MH;
    my $range = Mail::Message::MH->expand($str, $min, $max);

    # reverse order (first thread is the latest one) if reverse mode
    if ($config->{ reverse_order }) { @$range = reverse @$range;}

  ID_LIST:
    for my $id (@$range) {
	next ID_LIST unless defined $id;

	if ($id =~ /^\d+$/) {
	    # create thread identifier string: e.g. 100 -> elena/100
	    my $tid = $self->_create_thread_id_strings($id);

	    # check thread id $tid exists really ?
	    if (defined $db->{ _articles }->{ $tid }) {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $tid;

		# different treatment for the fisrt article in this thread
		$is_first = 1;

		# show all articles in this thread
	      ARTICLE:
		for my $aid (split(/\s+/, $db->{ _articles }->{ $tid })) {
		    # ensure uniquness
		    next ARTICLE if $uniq{ $aid };
		    $uniq{ $aid } = 1;

		    # show header only for the first message in this thread
		    if ($is_first) {
			undef $self->{ _no_header_summary };
			$is_first = 0;
		    }
		    else {
			$self->{ _no_header_summary } = 1;
		    }

		    my $file = $self->filepath({
			base_dir => $spool_dir,
			id       => $aid,
		    });
		    if (-f $file) {
			$self->print(  $self->message_summary($file) );
			print $fd "\n";
		    }
		}
	    }
	}
    }
}


=head2 show($tid)

show all articles in specified thread.

=cut


# Descriptions: show all articles in specified thread.
#    Arguments: OBJ($self) STR($tid)
# Side Effects: none
# Return Value: none
sub show
{
    my ($self, $tid) = @_;

    $self->_load_library();
    $self->db_open();
    $self->show_articles_in_thread($tid);
    $self->db_close();
}


=head2 print(str)

print str with special effect e.g. quoting if needed.
The function depends the mode, 'text' or 'html'.

=cut


# Descriptions: wrapper of print()
#    Arguments: OBJ($self) STR($str)
# Side Effects: quote if needed
# Return Value: none
sub print
{
    my ($self, $str) = @_;
    my $mode = $self->get_mode || 'text';
    my $fd   = $self->{ _fd } || \*STDOUT;

    if ($mode eq 'text') {
	print $fd $str;
    }
    elsif ($mode eq 'html') {
	$str = &_quote($str);
	$str =~ s/\n/<BR>\n/g;
	print $fd $str;
    }
}


# Descriptions: quote for html metachars
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub _quote
{
    my ($str) = @_;

    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/\"/&quot;/g;

    return $str;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::ThreadTrack::Print first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
