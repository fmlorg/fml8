#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Summary.pm,v 1.4 2002/11/26 14:13:00 fukachan Exp $
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

=head2 C<new()>

=cut


# Descriptions: usual constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    $me->{ _curproc } = $curproc;

    return bless $me, $type;
}


# Descriptions: append summary to $summary_file
#    Arguments: OBJ($self) HANDLE($wh) NUM($id)
# Side Effects: append summary to $summary_file
# Return Value: none
sub print
{
    my ($self, $wh, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $config->{ 'summary_file' };

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

    use FML::Article;
    my $article = new FML::Article $curproc;
    my $file    = $article->filepath($id);

    if (-f $file) {
	use Mail::Message;
	my $msg      = new Mail::Message->parse( { file => $file } );
	my $header   = $msg->whole_message_header();
	my $address  = $header->get( 'from' );
	my $date     = $header->get( 'date' );
	my $unixtime = Mail::Message::Date::date_to_unixtime( $date );

	# extract the first 15 bytes of user@domain part 
	# from From: header field.
	use FML::Header;
	my $hdrobj = new FML::Header;
	$address = substr($hdrobj->address_clean_up( $address ), 0, 15);

	# fold "\n"
	use FML::Header::Subject;
	my $obj     = new FML::Header::Subject;
	my $subject = $obj->clean_up($header->get('subject'), $tag);
	$subject =~ s/\s*\n/ /g;   
	$subject =~ s/\s+/ /g;

	use Mail::Message::Encode;
	my $enc  = new Mail::Message::Encode;
	$subject = $enc->convert($subject, "jis-jp", "euc-jp");

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
    my $style   = $config->{ 'summary_format_style' };

    if ($style eq 'fml4_compatible') {
	$self->_fml4_compatible_style_one_line_summary($wh, $info);
    }
    else {
	LogError("unknown \$summary_file_style: $style");
    }
}


# Descriptions: write out formatted string into $summary_file.
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($info)
# Side Effects: update $summary_file.
# Return Value: none
sub _fml4_compatible_style_one_line_summary
{
    my ($self, $wh, $info) = @_;
    my $time  = $info->{ unixtime } || undef;
    my $rdate = undef;

    if ($time) {
	use Mail::Message::Date;
	$rdate = new Mail::Message::Date $time;
    }
    else {
	LogError("unix time undefined");
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
	LogError("date object undefined.");
    }
}


=head1 UTILITIES

=cut


# Descriptions: append summary information for article $id.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: update summary
# Return Value: none
sub append
{
    my ($self, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $config->{ 'summary_file' };

    use FileHandle;
    my $wh = new FileHandle ">> $file";
    if (defined $wh) {
	$wh->autoflush(1);
	$self->print($wh, $id);
	$wh->close();
    }
}


# Descriptions: re-genearete summary from $min to $max.
#    Arguments: OBJ($self) NUM(min) NUM($max)
# Side Effects: re-create $summary file.
# Return Value: none
sub rebuild
{
    my ($self, $min, $max) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $config->{ 'summary_file' };
    my $tmp     = "$file.new.$$";

    use FileHandle;
    my $wh = new FileHandle ">> $tmp";

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
	LogError("fail to write $tmp");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article::Summary appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
