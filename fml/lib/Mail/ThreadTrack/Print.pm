#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Print.pm,v 1.8 2001/11/07 09:28:28 fukachan Exp $
#

package Mail::ThreadTrack::Print;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $is_show_cost_indicate = 0;

=head1 NAME

Mail::ThreadTrack::Print - print out thread relation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

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


sub review
{
    my ($self, $str, $min, $max) = @_;
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };
    my $fd        = $self->{ _fd } || \*STDOUT;
    my %uniq      = ();

    # modify Print parameters 
    $self->{ _article_summary_lines } = 5;

    $self->db_open();
    my $rh = $self->{ _hash_table };

    use Mail::Message::MH;
    my $ra = Mail::Message::MH->expand($str, $min, $max);
    my $first = 0;

    if (defined $config->{ reverse_order }) { @$ra = reverse @$ra;}

    for my $id (@$ra) {
	if ($id =~ /^\d+$/) { 
	    my $tid = $self->_create_thread_id_strings($id);
	    # check thread id $tid exists really ?
	    if (defined $rh->{ _articles }->{ $tid }) {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $tid;

		# change treatment for the fisrt article in this thread
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
			print $fd $self->__article_summary($file);
			print $fd "\n";
		    }
		}
	    }
	}
    }

    $self->db_close();
}


sub summary
{
    my ($self) = @_;
    my ($tid, $status, $thread_id);
    my $mode = $self->get_mode || 'text';

    # rh: thread id list, which is ARRAY REFERENCE tied to db_dir/*db's
    $thread_id = $self->list_up_thread_id();

    # self->{ _hash_table } is tied to DB's.
    $self->db_open();

    if (@$thread_id) {
	# sort the thread output order it out by cost
	# and print the thread summary in that order.
	$self->sort($thread_id);

	if ($mode eq 'html') {
	    print "<TABLE BORDER=4>\n" if $mode eq 'html';
	    $self->_print_thread_summary($thread_id);
	    print "</TABLE>\n" if $mode eq 'html';
	}
	else {
	    $self->_print_thread_summary($thread_id);

	    # show short summary for each article
	    $self->_print_article_summary($thread_id);
	}
    }

    # self->{ _hash_table } is untied from DB's.
    $self->db_close();
}



sub _print_thread_summary
{
    my ($self, $thread_id) = @_;
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
	print "<TD>action\n";
	print "<TD>date\n"."<TD>age\n"."<TD>status\n"."<TD>thread id\n";
	print "<TD>article summary\n";
    }

    my ($tid, @article_id, $article_id, $date, $age, $status) = ();
    my $dh = new Mail::Message::Date;
    for $tid (@$thread_id) {
	# get the first $article_id from the article_id list
	(@article_id) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$article_id   = $article_id[0];

	# determine $date for the $article_id
	# $age and $status for $thread_id
	$date   = $dh->YYYYxMMxDD( $rh->{ _date }->{ $article_id } , '/');
	$age    = $rh_age->{ $tid };
	$status = $rh->{ _status }->{ $tid };

	if ($mode eq 'html') {
	    $self->_show_thread_by_html_table( {
		format   => $format,
		date     => $date, 
		age      => $age, 
		status   => $status, 
		tid      => $tid, 
		articles => $rh->{ _articles }->{ $tid },
	    });
	}
	else {
	    printf($fd $format, 
		   $date, $age, $status, $tid, $rh->{ _articles }->{ $tid });
	}
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


sub _print_article_summary
{
    my ($self, $thread_id) = @_;
    my $config = $self->{ _config };
    my $age  = $self->{ _age }  || {};
    my $cost = $self->{ _cost } || {};
    my $fd   = $self->{ _fd }   || \*STDOUT;
    my $rh   = $self->{ _hash_table };

    if (defined $config->{ spool_dir }) {
	my ($aid, @aid, $file);

	if ($is_show_cost_indicate) {
	    print $fd "\n\"!\" mark: stalled? please check and reply it.\n";
	}

	my $spool_dir  = $config->{ spool_dir };
	for my $tid (@$thread_id) {
	    if ($is_show_cost_indicate) {
		my $how_bad = _cost_to_indicator( $cost->{ $tid } );
		printf $fd "\n%6s  %-10s  %s\n", $how_bad, $tid;
	    }
	    else {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $tid;
	    }

	    # show only the first article of this thread $tid
	    (@aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
	    $aid  = $aid[0];
	    $file = File::Spec->catfile($spool_dir, $aid);
	    print $fd $self->__article_summary($file);
	}
    }
}


sub __article_summary
{
    my ($self, $file) = @_;
    my (@header) = ();
    my $buf      = '';
    my $line     = $self->{ _article_summary_lines } || 3;
    my $mode     = $self->get_mode || 'text';
    my $padding  = $mode eq 'text' ? '   ' : '';

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
      LINE:
	while (<$fh>) {
	    # nuke useless lines
	    next LINE if /^\>/;
	    next LINE if /^\-/;

	    # header
	    if (1 ../^$/) {
		push(@header, $_);
	    }
	    # body part
	    else {
		next LINE if /^\s*$/;

		# ignore mail header like patterns
		next LINE if /^X-[-A-Za-z0-9]+:/i;
		next LINE if /^Return-[-A-Za-z0-9]+:/i;
		next LINE if /^Mime-[-A-Za-z0-9]+:/i;
		next LINE if /^Content-[-A-Za-z0-9]+:/i;
		next LINE if /^(To|From|Subject|Reply-To|Received):/i;
		next LINE if /^(Message-ID|Date):/i;

		# pick up effetive the first $line lines
		if (_valid_buf($_)) {
		    $line--;
		    $buf .= $padding. $_;
		}
		last LINE if $line < 0;
	    }
	}
	close($fh);

	if (defined $self->{ _no_header_summary }) {
	    return STR2EUC( $buf );
	}
	else {
	    use Mail::Header;
	    my $h = new Mail::Header \@header;
	    my $header_info = $self->_header_summary({
		header  => $h,
		padding => $padding,
	    });
	    return STR2EUC( $header_info ."\n". $buf );
	}
    }
    else {
	return undef;
    }
}


sub _valid_buf
{
    my ($str) = @_;
    $str = STR2EUC( $str );

    if ($str =~ /^[\>\#\|\*\:\;]/) {
	return 0;
    }
    elsif ($str =~ /^in /) { # quotation ?
	return 0;
    }
    elsif ($str =~ /\w+\@\w+/) { # mail address ?
	return 0;
    }
    elsif ($str =~ /^\S+\>/) { # quotation ?
	return 0;
    }

    return 1;
}


sub _delete_subject_tag_like_string
{
    my ($str) = @_;
    $str =~ s/^\s*\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;
    $str;
}


sub _header_summary
{
    my ($self, $args) = @_;
    my $from    = $args->{ header }->get('from');
    my $subject = $args->{ header }->get('subject');
    my $padding = $args->{ padding };

    $subject = decode_mime_string($subject, { charset => 'euc-japan' });
    $subject =~ s/\n/ /g;
    $subject = _delete_subject_tag_like_string($subject);

    $from    = decode_mime_string($from, { charset => 'euc-japan' });
    $from    =~ s/\n/ /g;

    my $br = $self->get_mode eq 'html' ? '<BR>' : '';

    # return buffer
    my $r = '';
    $r .= STR2EUC( $padding. "   From: ". $from ."$br\n" );
    $r .= STR2EUC( $padding. "Subject: ". $subject ."$br\n" );

    return $r;
}


=head2 C<decode_mime_string(string, [$options])>

decode a base64/quoted-printable encoded string to a plain message.
The encoding method is automatically detected.

C<$options> is a HASH REFERENCE.
You can specify the charset of the string to return 
by $options->{ charset }. 

=cut

sub decode_mime_string
{
    my ($str, $options) = @_;
    my $charset = $options->{ 'charset' } || 'euc-japan';

    if ($charset eq 'euc-japan') {
        use MIME::Base64;
        if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
        }

        use MIME::QuotedPrint;
        if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
        }
    }

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    $str;
}


sub STR2EUC
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    return $str;
}


1;
