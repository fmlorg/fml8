#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.1 2001/08/07 12:23:48 fukachan Exp $
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

=head2 C<show_summary(>)

top level entrance for routines to show the ticket summary. 

See L<simple_print()> for more detail.
Either of 
C<simple_print()> 
or
C<_summary_print()>
is used for purposes.

Each row that C<show_summary()> returns has a set of 
C<date>, C<age>, C<status>, C<ticket-id> and 
C<articles>, which is a list of articles with the ticket-id.

=head2 C<simple_print()>

show entries by the ticket_id order. For example,

       date    age status  ticket id             articles
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


sub show_summary
{
    my ($self) = @_;
    my ($tid, $status, $ticket_id);
    my $mode = $self->get_mode || 'text';

    # rh: ticket id list, which is ARRAY REFERENCE tied to db_dir/*db's
    $ticket_id = $self->list_up_ticket_id();

    # self->{ _hash_table } is tied to DB's.
    $self->db_open();

    if (@$ticket_id) {
	# sort the ticket output order it out by cost
	# and print the ticket summary in that order.
	$self->sort($ticket_id);

	if ($mode eq 'html') {
	    print "<TABLE BORDER=4>\n" if $mode eq 'html';
	    $self->_print_ticket_summary($ticket_id);
	    print "</TABLE>\n" if $mode eq 'html';
	}
	else {
	    $self->_print_ticket_summary($ticket_id);

	    # show short summary for each article
	    $self->_print_article_summary($ticket_id);
	}
    }

    # self->{ _hash_table } is untied from DB's.
    $self->db_close();
}



sub _print_ticket_summary
{
    my ($self, $ticket_id) = @_;
    my $mode   = $self->get_mode || 'text';
    my $rh_age = $self->{ _age } || {};
    my $fd     = $self->{ _fd } || \*STDOUT;
    my $rh     = $self->{ _hash_table };
    my $format = "%10s  %5s %6s  %-20s  %s\n";

    if ($mode eq 'text') {
	printf($fd $format, 'date', 'age', 'status', 'ticket id', 'articles');
	print $fd "-" x60;
	print $fd "\n";
    }
    else {
	print "<TD>action\n";
	print "<TD>date\n"."<TD>age\n"."<TD>status\n"."<TD>ticket id\n";
	print "<TD>article summary\n";
    }

    my ($tid, @article_id, $article_id, $date, $age, $status) = ();
    my $dh = new Mail::Message::Date;
    for $tid (@$ticket_id) {
	# get the first $article_id from the article_id list
	(@article_id) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$article_id   = $article_id[0];

	# determine $date for the $article_id
	# $age and $status for $ticket_id
	$date   = $dh->YYYYxMMxDD( $rh->{ _date }->{ $article_id } , '/');
	$age    = $rh_age->{ $tid };
	$status = $rh->{ _status }->{ $tid };

	if ($mode eq 'html') {
	    $self->_show_ticket_by_html_table( {
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
    my ($self, $ticket_id) = @_;
    my $config = $self->{ _config };
    my $age  = $self->{ _age }  || {};
    my $cost = $self->{ _cost } || {};
    my $fd   = $self->{ _fd }   || \*STDOUT;
    my $rh   = $self->{ _hash_table };

    if (defined $config->{ spool_dir }) {
	my ($aid, @aid);

	if ($is_show_cost_indicate) {
	    print $fd "\n\"!\" mark: stalled? please check and reply it.\n";
	}

	my $spool_dir  = $config->{ spool_dir };
	for my $tid (@$ticket_id) {
	    if ($is_show_cost_indicate) {
		my $how_bad = _cost_to_indicator( $cost->{ $tid } );
		printf $fd "\n%6s  %-10s  %s\n", $how_bad, $tid;
	    }
	    else {
		printf $fd "\n>Thread-Id: %-10s  %s\n", $tid;
	    }

	    (@aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
	    $aid   = $aid[0];
	    my $file = File::Spec->catfile($spool_dir, $aid);
	    print $fd $self->__article_summary($file);
	}
    }
}


sub __article_summary
{
    my ($self, $file) = @_;
    my (@header) = ();
    my $buf      = '';
    my $line     = 3;
    my $mode    = $self->get_mode || 'text';
    my $padding  = $mode eq 'text' ? '   ' : '';

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
      LINE:
	while (<$fh>) {
	    # nuke useless lines
	    next LINE if /^\>/;
	    next LINE if /^\-/;

	    if (1 ../^$/) {
		push(@header, $_);
	    }
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
		if ($line-- > 0) {
		    $buf .= $padding. $_;
		}
		else {
		    last LINE;
		}
	    }
	}
	close($fh);
    }

    use Mail::Header;
    my $h = new Mail::Header \@header;
    my $header_info = $self->_header_summary({
	header  => $h,
	padding => $padding,
    }); 

    return $header_info	. $buf;
}


sub _delete_subject_tag_like_string
{
    my ($str) = @_;
    $str =~ s/\W[-\w]+.\s*\d+\W//g;
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

    use FML::MIME qw(decode_mime_string);
    $subject = decode_mime_string($subject, { charset => 'euc-japan' });
    $subject =~ s/\n/ /g;
    $subject = _delete_subject_tag_like_string($subject);

    $from    = decode_mime_string($from, { charset => 'euc-japan' });
    $from    =~ s/\n/ /g;

    my $br = $self->get_mode eq 'html' ? '<BR>' : '';
    return 
	$padding. "   From: ". $from ."$br\n". 
	$padding. "Subject: ". $subject ."$br\n";
}


1;
