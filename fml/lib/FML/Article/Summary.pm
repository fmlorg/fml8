#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Summary.pm,v 1.15 2003/10/18 05:07:41 fukachan Exp $
#

package FML::Article::Summary;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);
use Mail::Message::Date;

=head1 NAME

FML::Article::Summary - generate article summary

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

standard constructor.

=cut


# Descriptions: standard constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: $self->{ _curproc } = $curproc;
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    $me->{ _curproc } = $curproc;

    return bless $me, $type;
}


# Descriptions: append summary to $article_summary_file
#    Arguments: OBJ($self) HANDLE($wh) NUM($id)
# Side Effects: append summary to $article_summary_file
# Return Value: none
sub print
{
    my ($self, $wh, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    # XXX last resort == STDOUT.
    $wh ||= \*STDOUT;

    if (defined $wh) {
	my $info = $self->_prepare_info($id);
	if (defined $info) {
	    $self->print_one_line_summary($wh, $info);
	}
    }
}


# Descriptions: prepare infomation on article $id for later use
#               such as $id, $address, $subject et.al.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: HASH_REF
sub _prepare_info
{
    my ($self, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $tag     = $config->{ article_subject_tag };
    my $addrlen = $config->{ article_summary_file_format_address_length };
    my $article = undef;

    if (defined $self->{ _article }) {
	$article = $self->{ _article };
    }
    else {
	# XXX-TODO: why we run "new FML::Article" here?
	# XXX-TODO: how do we know if this $article is proper (e.g. latest)?
	# XXX-TODO: we should use e.g. $curproc->last_article() ?
	use FML::Article;
	$article = new FML::Article $curproc;
    }

    my $file = $article->filepath($id);
    if (-f $file) {
	use Mail::Message;
	my $msg      = new Mail::Message->parse( { file => $file } );
	my $header   = $msg->whole_message_header();
	my $address  = $header->get( 'from' ) || '';
	my $date     = $header->get( 'date' ) || '';

	# XXX-TODO: not object-flavor,
	# XXX-TODO: $date = new Mail::Message::Date; 
	# XXX-TODO: $date->set("Tue Dec 30 17:06:34 JST 2003");
	# XXX-TODO: $date->to_unixtime();
	my $obj      = new Mail::Message::Date;
	my $unixtime = $obj->date_to_unixtime( $date );

	# log the first 15 bytes of user@domain in From: header field.
	if (defined $address) {
	    # XXX-TODO: implement FML::Address class
	    # XXX-TODO: $addr = FML::Address $from; $addr->cleanup().
	    use FML::Header;
	    my $hdr  = new FML::Header;
	    my $addr = $hdr->address_clean_up($address);
	    $address = defined $addr ? substr($addr, 0, $addrlen) : '';
	}

	# XXX-TODO $subject->clean_up() ? (object flavour?)
	# XXX-TODO $subject = new FML::Header::Subject $subject_string; 
	# XXX-TODO $subject->clean_up();
	use FML::Header::Subject;
	my $subjobj = new FML::Header::Subject;
	my $subject = $subjobj->clean_up($header->get('subject'), $tag);
	$subject =~ s/\s*\n/ /g; # fold "\n".
	$subject =~ s/\s+/ /g;

	# XXX-TODO "jis-jp" and "euc-jp" is hard-coded.
	# XXX-TODO: $in_code = subject->code(); $out_code = $config->{ ? }
	use Mail::Message::Encode;
	my $enc  = new Mail::Message::Encode;
	$subject = $enc->convert($subject, "jis-jp", "euc-jp");

	# XXX-TODO: $address->str() ? $subject->str() ?
	my $info = {
	    id       => $id,
	    address  => $address,
	    subject  => $subject,
	    unixtime => $unixtime,
	};

	return $info;
    }
    else {
	return undef;
    }
}


# Descriptions: one line version of print().
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($info)
# Side Effects: none
# Return Value: none
sub print_one_line_summary
{
    my ($self, $wh, $info) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $style   = $config->{ 'article_summary_file_format_style' };

    if ($style eq 'fml4_compatible') {
	$self->_fml4_compatible_style_one_line_summary($wh, $info);
    }
    else {
	$curproc->logerror("unknown \$article_summary_file_style: $style");
    }
}


# Descriptions: write out formatted string into $article_summary_file.
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($info)
# Side Effects: update $article_summary_file.
# Return Value: none
sub _fml4_compatible_style_one_line_summary
{
    my ($self, $wh, $info) = @_;
    my $curproc = $self->{ _curproc };
    my $time    = $info->{ unixtime } || undef;
    my $rdate   = undef;

    if ($time) {
	use Mail::Message::Date;
	$rdate = new Mail::Message::Date $time;
    }
    else {
	$curproc->logerror("unix time undefined");
    }

    if (defined $rdate) {
	my $date   = $rdate->{ 'log_file_style' };
	my $format = "%s [%d:%s] %s\n";
	my $id     = $info->{ id };
	my $addr   = $info->{ address };
	my $subj   = $info->{ subject };

	printf $wh $format, $date, $id, $addr, $subj;
    }
    else {
	$curproc->logerror("date object undefined.");
    }
}


=head1 UTILITIES

=cut


# Descriptions: append summary information for article $id.
#    Arguments: OBJ($self) OBJ($article) NUM($id)
# Side Effects: update summary
# Return Value: none
sub append
{
    my ($self, $article, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $config->{ 'article_summary_file' };

    if (defined $article) {
	$self->{ _article } = $article;
    }

    use FileHandle;
    my $wh = new FileHandle ">> $file";
    if (defined $wh) {
	$wh->autoflush(1);
	$self->print($wh, $id);
	$wh->close();
    }
}


# Descriptions: re-genearete summary from $min to $max.
#    Arguments: OBJ($self) NUM($min) NUM($max)
# Side Effects: re-create $summary file.
# Return Value: none
sub rebuild
{
    my ($self, $min, $max) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $config->{ 'article_summary_file' };
    my $tmp     = "$file.new.$$";

    use FileHandle;
    my $wh = new FileHandle ">> $tmp";

    # XXX-TODO: $min, $max is mandatory
    if (defined $wh) {
	$wh->autoflush(1);

	for my $id ($min .. $max) {
	    $self->print($wh, $id);
	}
	$wh->close();
    }

    if (-s $tmp) {
	rename($tmp, $file);
    }
    else {
	$curproc->logerror("fail to write $tmp");
    }
}


# Descriptions: print all lines in summary file into file handle $wh.
#    Arguments: OBJ($self) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub dump
{
    my ($self, $wh) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->config();
    my $article_summary_file = $config->{ "article_summary_file" };

    if (-f $article_summary_file) {
	my $fh = new FileHandle $article_summary_file;
	if (defined $fh && defined $wh) {
	    my $buf;
	    while ($buf = <$fh>) { print $wh $buf;}
	    $fh->close();
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article::Summary appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
