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

    return bless $me, $type;
}


sub DESTROY {}


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
    
    # if the header carries "Subject: Re: ..." with ticket-id, 
    # we do not rewrite the subject but save the extracted $ticket_id.
    if ($is_reply && $has_ticket_id) {
	Log("reply message with ticket_id=$has_ticket_id");
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

    # entries to check
    my $subject = $header->get('subject');
    my $content = $body->get_first_plaintext_message();

    if ($content =~ /^\s*close/ || $subject =~ /^\s*close/) {
	$self->{ _status } = "close";
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

    # save $ticke_id et.al. in db_dir/
    $self->_update_db($curproc, $args);
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
    my $config    = $curproc->{ config };
    my $pcb       = $curproc->{ pcb };

    $self->_open_db($curproc, $args);

    # prepare hash table tied to db_dir/*db's
    my $rh = $self->{ _hash_table };

    # prepare article_id and ticket_id
    my $article_id = $pcb->get('article', 'id');
    my $ticket_id  = $self->{ _ticket_id };
    Log("article_id=$article_id ticket_id=$ticket_id");

    $rh->{ _ticket_id }->{ $article_id }  = $ticket_id;
    $rh->{ _date      }->{ $article_id }  = time;
    $rh->{ _articles  }->{ $ticket_id  } .= $article_id . " ";

    # record the sender information
    my $header = $curproc->{ incoming_message }->{ header };
    $rh->{ _sender }->{ $article_id } = $header->get('from');

    # in the first ticket assignment, set the default status value.
    unless (defined $rh->{ _status }->{ $ticket_id }) {
	$self->_set_status($ticket_id, 'open');
    }

    # update status
    if (defined $self->{ _status }) {
	$self->_set_status($ticket_id, $self->{ _status });
    }

    $self->_close_db($curproc, $args);
}


sub _set_status
{
    my ($self, $ticket_id, $value) = @_;
    $self->{ _hash_table }->{ _status }->{ $ticket_id } = $value;
}


sub list_up
{
    my ($self, $curproc, $args) = @_;

    # self->{ _hash_table } is tied to DB's.
    $self->_open_db($curproc, $args);

    # XXX $dh: date object handle
    use FML::Date;
    my $dh = new FML::Date;

    # XXX $rh = Reference to Hash table, which is tied to db_dir/*db's
    my $rh             = $self->{ _hash_table };
    my $rh_status      = $rh->{ _status };
    my ($tid, $status) = ();
    my $mode           = $args->{ mode } || 'open_only';

  TICEKT_LIST:
    while (($tid, $status) = each %$rh_status) {
	if ($mode eq 'open_only') {
	    next TICEKT_LIST unless $status eq 'open';
	}

	# we get the date by the form 1999/09/13 
	# for the oldest article assigned to this ticket ($tid)
	my ($aid) = split(/\s+/, $rh->{ _articles }->{ $tid });
	my $date  = $dh->YYYYxMMxDD( $rh->{ _date }->{ $aid } , '/');

	printf("%10s  %5s  %-20s  %s\n", 
	       $date,
	       $status,
	       $tid,
	       $rh->{ _articles }->{ $tid }
	       );
    }

    # self->{ _hash_table } is untied from DB's.
    $self->_close_db($curproc, $args);
}


sub _open_db
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $pcb       = $curproc->{ pcb };
    my $db_type   = $curproc->{ ticket_db_type } || 'AnyDBM_File';
    my $db_dir    = $self->{ _db_dir };

    my (%ticket_id, %date, %status, %articles, %sender);
    my $ticket_id_file = $db_dir.'/ticket_id';
    my $date_file      = $db_dir.'/date';
    my $status_file    = $db_dir.'/status';
    my $sender_file    = $db_dir.'/sender';
    my $articles_file  = $db_dir.'/articles';

    eval qq{ use $db_type;};
    unless ($@) {
	eval q{
	    use Fcntl;
	    tie %ticket_id, $db_type, $ticket_id_file, O_RDWR|O_CREAT, 0644;
	    tie %date,      $db_type, $date_file,      O_RDWR|O_CREAT, 0644;
	    tie %status,    $db_type, $status_file,    O_RDWR|O_CREAT, 0644;
	    tie %sender,    $db_type, $sender_file,    O_RDWR|O_CREAT, 0644;
	    tie %articles,  $db_type, $articles_file,  O_RDWR|O_CREAT, 0644;
	};
	unless ($@) {
	    $self->{ _hash_table }->{ _ticket_id } = \%ticket_id;
	    $self->{ _hash_table }->{ _date }      = \%date;
	    $self->{ _hash_table }->{ _status }    = \%status;
	    $self->{ _hash_table }->{ _sender }    = \%sender;
 	    $self->{ _hash_table }->{ _articles }  = \%articles;
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


sub _close_db
{
    my ($self, $curproc, $args) = @_;
    my $ticket_id = $self->{ _hash_table }->{ _ticket_id };
    my $date      = $self->{ _hash_table }->{ _date };
    my $status    = $self->{ _hash_table }->{ _status };
    my $sender    = $self->{ _hash_table }->{ _sender };
    my $articles  = $self->{ _hash_table }->{ _articles };

    untie %$ticket_id;
    untie %$date;
    untie %$status;
    untie %$sender;
    untie %$articles;
}


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

=head2 new

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
