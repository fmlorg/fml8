#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Message.pm,v 1.5 2001/12/22 09:21:21 fukachan Exp $
#

package Mail::ThreadTrack::Print::Message;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);


=head1 NAME

Mail::ThreadTrack::Print::Message - summarize et.al.

=head1 SYNOPSIS

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 DESCRIPTION

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 METHODS

=head2 message_summary($file)

make message summary for specified $file (article).

=cut


# Descriptions: make message summary for specified $file (article)
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
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


# Descriptions: str looks effective, not quotation et.al. ?
#    Arguments: STR($str)
# Side Effects: none
# Return Value: 1 or 0
sub _valid_buf
{
    my ($str) = @_;
    $str = STR2EUC( $str );

    if ($str =~ /^[\>\#\|\*\:\;\=]/) {
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


# Descriptions: remove subject tag like string in $str e.g. [elena 100]
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub _delete_subject_tag_like_string
{
    my ($str) = @_;

    if (defined $str) {
	use Mail::Message::Utils;
	return Mail::Message::Utils::remove_subject_tag_like_string($str);
    }
    else {
	return undef;
    }
}


# Descriptions: make summary of header $args->{ header }
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub header_summary
{
    my ($self, $args) = @_;
    my $date    = $args->{ header }->get('date');
    my $from    = $args->{ header }->get('from');
    my $subject = $args->{ header }->get('subject');
    my $padding = $args->{ padding } || '   ';

    if (defined $subject) {
	$subject = decode_mime_string($subject, { charset => 'euc-japan' });
	$subject =~ s/\n/ /g;
	$subject = _delete_subject_tag_like_string($subject);
	$subject =~ s/[\s\n]*$//g;
    }

    if (defined $from) {
	$from    = $self->_who_of_address( $from );
	$from    =~ s/\n/ /g;
	$from    =~ s/[\s\n]*$//g;
    }

    # return buffer
    my $r = $padding. $date;
    $r   .= $padding. "$subject, $from\n";
    return STR2EUC( $r );
}


# Descriptions: get gecos field in $address.
#               return $address itself if the extraction failed.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: STR
sub _who_of_address
{
    my ($self, $address) = @_;
    my ($user);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($address);

    for my $addr (@addrs) {
        if (defined( $addr->phrase() )) {
            my $phrase = decode_mime_string( $addr->phrase(), {
		charset => 'euc-japan',
	    });

            if ($phrase) {
                return($phrase);
            }
        }

        $user = $addr->user();
    }

    if ($self->get_mode() eq 'html') {
	return( $user ? "$user\@xxx.xxx.xxx.xxx" : $address );
    }
    else {
	return $address;
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

Mail::ThreadTrack::Print::Message appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
