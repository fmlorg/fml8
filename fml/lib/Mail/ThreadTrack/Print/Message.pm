#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Utils.pm,v 1.1 2001/11/09 10:37:06 fukachan Exp $
#

package Mail::ThreadTrack::Print::Message;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);

sub message_summary
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
	    my $header_info = $self->header_summary({
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
    use Mail::Message::Utils;
    return Mail::Message::Utils::remove_subject_tag_like_string($str);
}


sub header_summary
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


1;
