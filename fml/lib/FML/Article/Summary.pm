#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Summary.pm,v 1.27 2006/05/05 13:24:10 fukachan Exp $
#

package FML::Article::Summary;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Message::Date;


=head1 NAME

FML::Article::Summary - generate article summary.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
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


# Descriptions: append summary to $article_summary_file.
#    Arguments: OBJ($self) HANDLE($wh) NUM($id)
# Side Effects: update $article_summary_file file.
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


# Descriptions: prepare information on article $id for later use.
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
	# XXX we need article object to use $article->filepath() method.
	eval q{ use FML::Article;};
	$article = new FML::Article $curproc;
    }

    my $file = $article->filepath($id);
    if (-f $file) {
	use Mail::Message;
	my $msg      = new Mail::Message->parse( { file => $file } );
	my $header   = $msg->whole_message_header();
	my $address  = $header->get('from')    || '';
	my $date_str = $header->get('date')    || '';
	my $subject  = $header->get('subject') || '';

	# data -> unix time.
	use Mail::Message::Date;
	my $date     = new Mail::Message::Date $date_str;
	my $unixtime = $date->as_unixtime();

	# log the first 15 bytes of user@domain in From: header field.
	if ($address) {
	    use Mail::Message::Address;
	    my $addr = new Mail::Message::Address $address;
	    $addr->cleanup();
	    $address = $addr->substr(0, $addrlen) || '';
	}

	# de-tag, unfold, and charset conversion.
	# XXX as_external_form() returns the "printable" string
	# XXX which encoding is EUC by default but should be changed to UTF-8.
	# XXX The "printable" string is used for output to local files
	# XXX e.g. "summary", "log" NOT mail tranfer.
	if ($subject) {
	    use Mail::Message::Subject;
	    my $sbj = new Mail::Message::Subject $subject;
	    $sbj->mime_header_decode();
	    $sbj->unfold();
	    $sbj->delete_tag($tag);
	    $sbj->unfold();
	    $subject = $sbj->as_external_form();
	}

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

=head2 append($article, $id)

append summary information for article $id into the article summary file.

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
    if (defined $wh) {
	$wh->autoflush(1);

	# speculate boundary if not specified.
	$min ||= 1;
	$max ||= $curproc->article_get_max_id();

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
	my $rh = new FileHandle $article_summary_file;
	if (defined $rh && defined $wh) {
	    my $buf;
	    while ($buf = <$rh>) { print $wh $buf;}
	    $rh->close();
	}
    }
}


# Descriptions: remove content corresponding with expired articles.
#    Arguments: OBJ($self) NUM($first_seq) NUM($last_seq)
# Side Effects: summary rebuilt.
# Return Value: none
sub expire
{
    my ($self, $first_seq, $last_seq)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    my $summary_style = $config->{ article_summary_file_format_style };
    if ($summary_style eq 'fml4_compatible') {
        $self->_expire_fml4_compatible_style_summary($first_seq, $last_seq);
    }
    else {
	my $errmsg = "unknown \$article_summary_file_style: $summary_style";
        $curproc->logerror($errmsg);
    }

}


# Descriptions: remove content corresponding with expired articles.
#    Arguments: OBJ($self) NUM($first_seq) NUM($last_seq)
# Side Effects: summary rebuilt.
# Return Value: none
sub _expire_fml4_compatible_style_summary
{
    my ($self, $first_seq, $last_seq)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    # 06/05/03 16:31:16 [1268:fukachan@home.f] SUMMARY
    my $summary_file = $config->{ article_summary_file };
    my $tmp_file     = $curproc->tmp_file_path();
    if (-f $summary_file) {
	use FileHandle;
	my $rh = new FileHandle $summary_file;
	my $wh = new FileHandle "> $tmp_file";
	if (defined $rh && defined $wh) {
	    my $buf;
	  LINE:
	    while ($buf = <$rh>) {
		if ($buf =~ /\[(\d+):/) {
		    my $seq = $1;
		    next LINE if $seq <= $last_seq;
		}
		print $wh $buf;
	    }
	    $wh->close();
	    $rh->close();
	}
	else {
	    $curproc->logerror("cannot open summary file") unless defined $rh;
	    $curproc->logerror("cannot open tmp file")     unless defined $wh;
	}

	unless (-s $tmp_file) {
	    $curproc->logerror("expire: tmporary file creation fail");
	    return;
	}

	if (rename($tmp_file, $summary_file)) {
	    $curproc->logdebug("expire: summary file rebuilt");
	}
	else {
	    $curproc->logerror("expire: summary file rebuilding fail");
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article::Summary appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
