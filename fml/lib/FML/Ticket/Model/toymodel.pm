#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Ticket::Model::toymodel;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log);
use FML::Ticket::System;

require Exporter;
@ISA = qw(FML::Ticket::System Exporter);

=head1 NAME

FML::Ticket::Model::toymodel - a toymodel of ticket systems

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASS HIERARCHY

        FML::Ticket::System
                |
                A 
       -------------------
       |        |        |
    toymodel  model2    ....

=head1 METHOD

=head2 C<new($curproc, $args)>

constructor. 

=cut


sub new
{
    my ($self, $curproc, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    bless $me, $type;

    # initialize directory for DB files for further work
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };
    $me->{ _db_dir } = $config->{ ticket_db_dir } ."/". $ml_name;
    $me->_init_ticket_db_dir($curproc, $args) || do { return undef;};

    # index for cross reference over mailing lists.
    $me->{ _index_db } = $config->{ ticket_db_dir } ."/\@index";

    # pragma for operations hints
    $me->{ _pragma } = '';

    return bless $me, $type;
}


sub DESTROY {}


=head2 C<assign($curproc, $args)>

assign a new ticket or extract the existing ticket-id from the subject.

=cut


# Descriptions: assign a new ticket or 
#               extract the existing ticket-id from the subject
#    Arguments: $self $curproc $args
# Side Effects: a new ticket_id may be assigned
#               article header is rewritten
# Return Value: none
sub assign
{
    my ($self, $curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $header  = $curproc->{ incoming_message }->{ header };
    my $subject = $header->get('subject');

    use FML::Header::Subject;
    my $is_reply      = FML::Header::Subject->is_reply( $subject );
    my $has_ticket_id = $self->_extract_ticket_id($header, $config);
    my $pragma        = $header->get('x-ticket-pragma') || '';

    # If the header has a "X-Ticket-Pragma: ignore" field, 
    # we ignore this mail.
    if ($pragma =~ /ignore/i) {
	$self->{ _pragma } = 'ignore';
	return undef;
    }
    
    # if the header carries "Subject: Re: ..." with ticket-id, 
    # we do not rewrite the subject but save the extracted $ticket_id.
    if ($is_reply && $has_ticket_id) {
	Log("reply message with ticket_id=$has_ticket_id");
	$self->{ _status    } = 'going';
	$self->{ _ticket_id } = $has_ticket_id;
    }
    elsif ($has_ticket_id) {
	Log("usual message with ticket_id=$has_ticket_id");
	$self->{ _ticket_id } = $has_ticket_id;
    }
    else {
	# assign a new ticket number for a new message
	# call SUPER class's FML::Ticket::System::increment_id()
	my $id = $self->increment_id( $config->{ ticket_sequence_file } );

	# O.K. rewrite Subject: of the article to distribute
	unless ($self->error) {
	    my $header = $curproc->{ article }->{ header };

	    $self->_pcb_set_id($curproc, $id); # save $id info in PCB
	    $self->_rewrite_subject($header, $config, $id);
	}
	else {
	    Log( $self->error );
	}
    }
}


sub update_status
{
    my ($self, $curproc, $args) = @_;
    my $header  = $curproc->{ incoming_message }->{ header };
    my $body    = $curproc->{ incoming_message }->{ body };

    return if $self->{ _pragma } eq 'ignore';

    # entries to check
    my $subject = $header->get('subject');
    my $content = $body->get_first_plaintext_message();
    my $pragma  = $header->get('x-ticket-pragma') || '';

    if ($content =~ /^\s*close/ || 
	$subject =~ /^\s*close/ || 
	$pragma  =~ /close/      ) {
	$self->{ _status } = "closed";
	Log("ticket is closed");
    }
    else {
	Log("ticket status not changed");
    }
}


sub update_db
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name };

    return if $self->{ _pragma } eq 'ignore';

    $self->open_db($curproc, $args);

    # save $ticke_id et.al. in db_dir/$ml_name
    $self->_update_db($curproc, $args);

    # save cross reference pointers among $ml_name
    $self->_update_index_db($curproc, $args);

    $self->close_db($curproc, $args);
}


sub _gen_ticket_id
{
    my ($self, $header, $config, $id) = @_;
    my $ml_name   = $config->{ ml_name };

    # ticket_id in subject
    my $tag       = $config->{ ticket_subject_tag };
    my $ticket_id = sprintf($tag, $id);
    $self->{ _ticket_subject_tag } = $ticket_id;

    $tag       = $config->{ ticket_id_syntax };
    $ticket_id = sprintf($tag, $id);
    $self->{ _ticket_id } = $ticket_id;

    return $ticket_id;
}


sub _extract_ticket_id
{
    my ($self, $header, $config) = @_;
    my $tag     = $config->{ ticket_subject_tag };
    my $subject = $header->get('subject');

    use FML::Header::Subject;
    my $regexp = FML::Header::Subject::_regexp_compile($tag);

    if ($subject =~ /($regexp)\s*$/) {
	my $id = $1;
	$id =~ s/^(\[|\(|\{)//;
	$id =~ s/(\]|\)|\})$//;
	return $id;
    }
}


sub _rewrite_subject
{
    my ($self, $header, $config, $id) = @_;

    # create ticket syntax in the subject
    $self->_gen_ticket_id($header, $config, $id);

    # append the ticket tag to the subject
    my $subject = $header->get('subject') || '';
    $header->replace('Subject', 
		     $subject." " . $self->{ _ticket_subject_tag });

    # X-* information
    $header->add('X-Ticket-ID', $self->{ _ticket_id });
}


sub _update_db
{
    my ($self, $curproc, $args) = @_;
    my $config     = $curproc->{ config };
    my $pcb        = $curproc->{ pcb };
    my $article_id = $pcb->get('article', 'id');
    my $ticket_id  = $self->{ _ticket_id };

    # 0. logging
    Log("article_id=$article_id ticket_id=$ticket_id");

    # prepare hash table tied to db_dir/*db's
    my $rh = $self->{ _hash_table };

    # 1. 
    $rh->{ _ticket_id }->{ $article_id }  = $ticket_id;
    $rh->{ _date      }->{ $article_id }  = time;
    $rh->{ _articles  }->{ $ticket_id  } .= $article_id . " ";

    # 2. record the sender information
    my $header = $curproc->{ incoming_message }->{ header };
    $rh->{ _sender }->{ $article_id } = $header->get('from');

    # 3. update status information
    if (defined $self->{ _status }) {
	$self->_set_status($ticket_id, $self->{ _status });
    }
    else {
	# set the default status value for the first time.
	unless (defined $rh->{ _status }->{ $ticket_id }) {
	    $self->_set_status($ticket_id, 'open');
	}
    }
}



# register myself to index_db for further reference among mailing lists
sub _update_index_db
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $ticket_id = $self->{ _ticket_id };
    my $rh        = $self->{ _hash_table };
    my $ml_name   = $config->{ ml_name };

    my $ref = $rh->{ _index }->{ $ticket_id } || '';
    if ($ref !~ /^$ml_name|\s$ml_name\s|$ml_name$/) {
	$rh->{ _index }->{ $ticket_id } .= $ml_name." ";
    }
}


=head1 METHOD on DB IO

methods to manipulate data in DB.

=head2 C<open_db($curproc, $args)>

open DB's which tie() hashes to DB as a file. 
Our toymodel uses several DB's for
C<%ticket_id>,
C<%date>,
C<%status>,
C<%sender>,
C<%articles>,
C<%index>.

=head2 C<close_db($curproc, $args)>

untie() hashes opended by C<open_db()>.

=cut


sub open_db
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $pcb       = $curproc->{ pcb };
    my $db_type   = $curproc->{ ticket_db_type } || 'AnyDBM_File';
    my $db_dir    = $self->{ _db_dir };

    my (%ticket_id, %date, %status, %articles, %sender, %index);
    my $ticket_id_file = $db_dir.'/ticket_id';
    my $date_file      = $db_dir.'/date';
    my $status_file    = $db_dir.'/status';
    my $sender_file    = $db_dir.'/sender';
    my $articles_file  = $db_dir.'/articles';
    my $index_file     = $self->{ _index_db };

    eval qq{ use $db_type;};
    unless ($@) {
	eval q{
	    use Fcntl;
	    tie %ticket_id, $db_type, $ticket_id_file, O_RDWR|O_CREAT, 0644;
	    tie %date,      $db_type, $date_file,      O_RDWR|O_CREAT, 0644;
	    tie %status,    $db_type, $status_file,    O_RDWR|O_CREAT, 0644;
	    tie %sender,    $db_type, $sender_file,    O_RDWR|O_CREAT, 0644;
	    tie %articles,  $db_type, $articles_file,  O_RDWR|O_CREAT, 0644;
	    tie %index,     $db_type, $index_file,     O_RDWR|O_CREAT, 0644;
	};
	unless ($@) {
	    $self->{ _hash_table }->{ _ticket_id } = \%ticket_id;
	    $self->{ _hash_table }->{ _date }      = \%date;
	    $self->{ _hash_table }->{ _status }    = \%status;
	    $self->{ _hash_table }->{ _sender }    = \%sender;
 	    $self->{ _hash_table }->{ _articles }  = \%articles;
 	    $self->{ _hash_table }->{ _index }     = \%index;
	}
	else {
	    Log("Error: tail to tie() under $db_type");
	    return undef;
	}
    }
    else {
	Log("Error: fail to use $db_type");
	return undef;
    }

    1;
}


sub close_db
{
    my ($self, $curproc, $args) = @_;

    my $ticket_id = $self->{ _hash_table }->{ _ticket_id };
    my $date      = $self->{ _hash_table }->{ _date };
    my $status    = $self->{ _hash_table }->{ _status };
    my $sender    = $self->{ _hash_table }->{ _sender };
    my $articles  = $self->{ _hash_table }->{ _articles };
    my $index     = $self->{ _hash_table }->{ _index };

    untie %$ticket_id;
    untie %$date;
    untie %$status;
    untie %$sender;
    untie %$articles;
    untie %$index;
}


=head2 C<set_status($args)>

set $status for $ticket_id. It rewrites DB (file).
C<$args>, HASH reference, must have two keys.

    $args = {
	ticket_id => $ticket_id,
	status    => $status,
    }

C<set_status()> calls open_db() an close_db() automatically within it.

=cut


# Descriptions: 
#    Arguments: $self $curproc $args
# Side Effects: 
# Return Value: none
sub set_status
{
    my ($self, $curproc, $args) = @_;
    my $ticket_id = $args->{ ticket_id };
    my $status    = $args->{ status };

    $self->open_db($curproc, $args);
    $self->_set_status($ticket_id, $status);
    $self->close_db($curproc, $args);
}


sub _set_status
{
    my ($self, $ticket_id, $value) = @_;
    $self->{ _hash_table }->{ _status }->{ $ticket_id } = $value;
}



=head1 OUTPUT ROUTINES

=head2 C<show_summary($curproc, $args>)

show the ticket summary. 
See L<_simple_print()> for more detail.

Intenally
C<_simple_print()> 
or
C<_summary_print()>
is used for each purpose.

Each row has a set of 
C<date>, C<age>, C<status>, C<ticket-id> and 
C<articles>, which is a list of articles with the ticket-id.

=head2 C<_simple_print()>

show entries by the ticket_id order. 

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
    my ($self, $curproc, $args) = @_;
    my ($tid, $status, @ticket_id);

    # self->{ _hash_table } is tied to DB's.
    $self->open_db($curproc, $args);

    # rh: Reference to Hash table, which is tied to db_dir/*db's
    my $rh_status      = $self->{ _hash_table }->{ _status };
    my $mode           = $args->{ mode } || 'default';

    # @ticket_id ARRAY
  TICEKT_LIST:
    while (($tid, $status) = each %$rh_status) {
	if ($mode eq 'default') {
	    next TICEKT_LIST if $status =~ /close/o;
	}

	push(@ticket_id, $tid);
    }

    if (@ticket_id) {
	# age HASH TABLE
	my ($rh_age, $rh_cost) = 
	    $self->_calculate_age($curproc, $args, \@ticket_id);

	# sort the ticket output order and print it out
	$self->_sort_ticket_id($curproc, \@ticket_id, $rh_cost);
	$self->_print_ticket_summary($curproc, $args, \@ticket_id, $rh_age);

	# show short summary for each article
	$self->_print_article_summary($curproc, $args, \@ticket_id, 
				      $rh_age, $rh_cost);
    }

    # self->{ _hash_table } is untied from DB's.
    $self->close_db($curproc, $args);
}


sub _sort_ticket_id
{
    my ($self, $curproc, $ticket_id, $cost) = @_;

    @$ticket_id = sort { 
	$cost->{$b} cmp $cost->{$a};
    } @$ticket_id;
}


sub _calculate_age
{
    my ($self, $curproc, $args, $ticket_id) = @_;
    my (%age, %cost) = ();
    my $now   = time; # save the current UTC for convenience
    my $rh    = $self->{ _hash_table };
    my $day   = 24*3600;

    # $age hash referehence = { $ticket_id => $age };
    my (@aid, $last, $age, $date, $status);
    for my $tid (sort @$ticket_id) {
	# $last: get the latest one of article_id's
	(@aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$last  = $aid[ $#aid ];

	# how long this ticket is not concerned ?
	$age = sprintf("%2.1f%s", ($now - $rh->{ _date }->{ $last })/$day);
	$age{ $tid } = $age;

	# evaluate cost hash table which is { $ticket_id => $cost }
	$cost{ $tid } = $rh->{ _status }->{ $tid }.'-'. $age;
    }

    return (\%age, \%cost);
}


sub _print_ticket_summary
{
    my ($self, $curproc, $args, $ticket_id, $rh_age) = @_;
    my $fd     = $self->{ _fd } || \*STDOUT;
    my $rh     = $self->{ _hash_table };
    my $format = "%10s  %5s %6s  %-20s  %s\n";

    printf($fd $format, 'date', 'age', 'status', 'ticket id', 'articles');
    print $fd "-" x60;
    print $fd "\n";

    my ($tid, @article_id, $article_id, $date, $age, $status) = ();
    my $dh = new FML::Date;
    for $tid (@$ticket_id) {
	# get the first $article_id from the article_id list
	(@article_id) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$article_id   = $article_id[0];

	# determine $date for the $article_id
	# $age and $status for $ticket_id
	$date   = $dh->YYYYxMMxDD( $rh->{ _date }->{ $article_id } , '/');
	$age    = $rh_age->{ $tid };
	$status = $rh->{ _status }->{ $tid };

	printf($fd $format, 
	       $date, $age, $status, $tid, $rh->{ _articles }->{ $tid });
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
    my ($self, $curproc, $args, $ticket_id, $age, $cost) = @_;
    my $fd     = $self->{ _fd } || \*STDOUT;
    my $rh     = $self->{ _hash_table };
    my $wd     = $self->{ _wd } || \*STDOUT;

    # 
    my ($aid, @aid);
    my $spool_dir  = $curproc->{ config }->{ spool_dir };

    print $wd "\n\"!\" mark: stalled? please check and reply it.\n";

    for my $tid (@$ticket_id) {
	my $how_bad = _cost_to_indicator( $cost->{ $tid } );
	printf $wd "\n%6s  %-10s  %s\n", $how_bad, $tid;

	(@aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
	$aid   = $aid[0];
	print $wd $self->_article_summary( $spool_dir ."/". $aid );
    }
}


sub _article_summary
{
    my ($self, $file) = @_;
    my (@header) = ();
    my $buf      = '';
    my $line     = 5;
    my $padding  = '      > ';

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
      ARTICLE:
	while (<$fh>) {
	    # nuke useless lines
	    next ARTICLE if /^\>/;
	    next ARTICLE if /^\-/;

	    if (1 ../^$/) {
		push(@header, $_);
	    }
	    else {
		next ARTICLE if /^\s*$/;

		# pick up effetive the first $line lines
		if ($line--> 0) {
		    $buf .= $padding. $_;
		}
		else {
		    last ARTICLE;
		}
	    }
	}
	close($fh);
    }

    use FML::Header;
    my $h = new FML::Header \@header;
    my $header_info = _header_summary({
	header  => $h,
	padding => $padding,
    }); 

    return $header_info	. $buf;
}


sub _header_summary
{
    my ($args) = @_;
    my $from    = $args->{ header }->get('from');
    my $subject = $args->{ header }->get('subject');
    my $padding = $args->{ padding };

    use Jcode;

    if ($subject =~ /=\?ISO\-2022\-JP\S+B\?(\S+)=\?=/) { 
	my $y = decode_base64($1);
	$subject = Jcode::convert(\$y, 'euc')."\n";
    }
    if ($from =~ /=\?ISO\-2022\-JP\S+B\?(\S+)=\?=/) { 
	my $y = decode_base64($1);
	$from = Jcode::convert(\$y, 'euc')."\n";
    }

    $from    =~ s/\n/ /g;
    $subject =~ s/\n/ /g;
    $subject = FML::Header::remove_subject_tag_like_string($subject);

    return 
	$padding. "   From: ". $from ."\n". 
	$padding. "Subject: ". $subject ."\n";
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Ticket::Model::toymodel.pm appeared in fml5.

=cut

1;
