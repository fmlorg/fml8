#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HeaderRewrite.pm,v 1.13 2002/12/22 03:21:33 fukachan Exp $
#

package Mail::ThreadTrack::HeaderRewrite;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::ThreadTrack::HeaderRewrite - header manipulation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 rewrite_header($msg)

C<$msg> is Mail::Message object.

=cut


# Descriptions: add thread track info into $msg where
#               $msg is Mail::Message object.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: modify $msg header
# Return Value: none
sub rewrite_header
{
    my ($self, $msg) = @_;
    my $config  = $self->{ _config };
    my $loctype = $config->{ thread_subject_tag_location } || 'appended';
    my $header  = $msg->whole_message_header();
    my $tag     = $self->{ _thread_subject_tag } || '';

    # append the thread tag to the subject
    if (defined $header->get('subject')) {
	my $subject = $header->get('subject');

	if ($loctype eq 'appended' && $tag) {
	    $header->replace('subject', $subject ." ". $tag);
	}
	elsif ($loctype eq 'prepended' && $tag) {
	    $header->replace('subject', $tag ." ". $subject);
	}
	else {
	    $self->log("unknown thread_subject_tag_location type");
	}

	if (defined $self->{ _status_info }) {
	    $header->add('X-Thread-Status', $self->{ _status_info });
	}

	if (defined $self->{ _thread_id }) {
	    $header->add('X-Thread-ID', $self->{ _thread_id });
	}

	if (defined $self->{ _status_history }) {
	    $header->add('X-Thread-History', $self->{ _status_history });
	}
    }
}


# Descriptions: prepare history infomation for further header rewriting.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: update $self->{ _status_history }
# Return Value: none
sub prepare_history_info
{
    my ($self, $msg) = @_;
    my $thread_id = $self->get_thread_id();

    # prepare hash table tied to db_dir/*db's
    my $rh = $self->{ _hash_table };

    if (defined $rh->{ _articles  }->{ $thread_id }) {
	my $buf    = '';
	my (@aid)  = split(/\s+/, $rh->{ _articles  }->{ $thread_id });
	my $sender = $rh->{ _sender }->{ $aid[0] };
	my $when   = $rh->{ _date }->{ $aid[0] };

	# clean up
	$sender =~ s/[\s\n]*$//;
	$when   =~ s/[\s\n]*$//;

	use Mail::Message::Date;
	$when = Mail::Message::Date->new($when)->mail_header_style();

	# XXX-TODO: validate $aid[0], $sender, $when, @aid.
	$buf .= "\t\n";
	$buf .= "\tthis thread is opended at article $aid[0]\n";
	$buf .= "\tby $sender\n";
	$buf .= "\ton $when\n";
	$buf .= "\tarticle references: @aid\n";
	$self->{ _status_history } = $buf;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::ThreadTrack::HeaderRewrite first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
