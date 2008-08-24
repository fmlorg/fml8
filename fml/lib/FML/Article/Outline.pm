#-*- perl -*-
#
#  Copyright (C) 2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Outline.pm,v 1.3 2005/09/17 01:33:47 fukachan Exp $
#

package FML::Article::Outline;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

=head1 NAME

FML::Article::Outline - article thread outline.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new(curproc)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ(FML::Article)
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head1 ARTICLE THREAD OUTLINE

=head2 add_outline($thread_db_args)

add thread outline information to article object.

=cut


# Descriptions: add thread outline information to article object.
#    Arguments: OBJ($self) HASH_REF($tdb_args)
# Side Effects: update article.
# Return Value: none
sub add_outline
{
    my ($self, $tdb_args) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $id      = $tdb_args->{ id } || -1;
    my $charset = $curproc->langinfo_get_charset("reply_message");

    # e.g. "iso-2022-jp" => "ja",
    use Mail::Message::Charset;
    my $cobj = new Mail::Message::Charset;
    my $lang = $cobj->message_charset_to_language($charset);

    if ($config->yes('use_article_thread_outline')) {
	# 1. get thread outline containing article $id within it.
	# 2. fix charset as could as possible.
	use FML::Article::Thread;
	my $article_thread = new FML::Article::Thread $curproc, $tdb_args;
	my $_outline       = $article_thread->get_outline($id, $tdb_args);
	my $outline        = $self->_fix_charset($_outline, $charset);

	# 3 .apply rules.
	my $rules = $config->get_as_array_ref('article_thread_outline_rules');
	for my $rule (@$rules) {
	    my $fp = sprintf("_fp_$rule", $outline, $charset, $lang);
	    if ($self->can($fp)) {
		$self->$fp($outline, $charset, $lang);
	    }
	    else {
		$curproc->logerror("outline: no such rule: $rule");
	    }
	}
    }
}


# Descriptions: fix charset.
#    Arguments: OBJ($self) STR($s) STR($charset)
# Side Effects: none
# Return Value: STR
sub _fix_charset
{
    my ($self, $s, $charset) = @_;

    use Mail::Message::String;
    my $str = new Mail::Message::String $s;
    $str->charcode_convert($charset);
    return $str->as_str();
}


# Descriptions: add thread outline to article header.
#    Arguments: OBJ($self) STR($outline) STR($charset) STR($lang)
# Side Effects: update article header.
# Return Value: none
sub _fp_add_outline_to_header
{
    my ($self, $outline, $charset, $lang) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->config();
    my $_hdr     = "X-Article-Thread-Outline";
    my $hdr_name = $config->{ article_thread_outline_header_field } || $_hdr;

    # clean up.
    my $_outline = $outline;
    $_outline =~ s/^\s*//;
    $_outline =~ s/\s*$//;

    # add.
    my $header = $curproc->article_message_header();
    $header->add($hdr_name, $_outline);
}


# Descriptions: prepend thread outline to article body.
#    Arguments: OBJ($self) STR($outline) STR($charset) STR($lang)
# Side Effects: update article body.
# Return Value: none
sub _fp_prepend_outline_to_body
{
    my ($self, $outline, $charset, $lang) = @_;
    $self->_fp_body("prepend", $outline, $charset, $lang);
}


# Descriptions: append thread outline to article body.
#    Arguments: OBJ($self) STR($outline) STR($charset) STR($lang)
# Side Effects: update article body.
# Return Value: none
sub _fp_append_outline_to_body
{
    my ($self, $outline, $charset, $lang) = @_;
    $self->_fp_body("append", $outline, $charset, $lang);
}


# Descriptions: add thread outline to article body.
#    Arguments: OBJ($self) STR($fp) STR($outline) STR($charset) STR($lang)
# Side Effects: update article body.
# Return Value: none
sub _fp_body
{
    my ($self, $fp, $outline, $charset, $lang) = @_;
    my $curproc    = $self->{ _curproc };
    my $config     = $curproc->config();
    my $sp         = "=" x 60;
    my $separator  = $config->{ article_thread_outline_body_separator } || $sp;
    my $title_key  = sprintf("article_thread_outline_greeting_%s" ,$lang);
    my $_title     = $config->{ $title_key } || '';
    my $title      = $self->_fix_charset($_title, $charset);

    # prepare buffer.
    my $_outline = sprintf("%s\n%s\n%s\n%s",
			   $separator,
			   $title,
			   $outline,
			   $separator);

    # append.
    if ($fp eq 'prepend' || $fp eq 'append') {
	my $body = $curproc->article_message_body();
	$body->$fp({
	    type    => "text/plain",
	    charset => $charset,
	    data    => $_outline,
	});
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
