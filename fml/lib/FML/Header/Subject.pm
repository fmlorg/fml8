#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Subject.pm,v 1.40 2003/08/23 04:35:36 fukachan Exp $
#

package FML::Header::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Header::Subject - manipule the mail header subject

=head1 SYNOPSIS

    use FML::Header::Subject;
    FML::Header::Subject->rewrite_article_subject_tag($header, $config, $args);

=head1 DESCRIPTION

collection of functions to manipulate the header subject.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 rewrite_article_subject_tag($header, $config, $args)

add or rewrite the subject tag for C<$header>.
This mothod cuts off Re: (reply identifier) in subject: and
replace the subject with the newer content e.g. including the ML tag.

=cut


# Descriptions: add or rewrite the subject tag
#    Arguments: OBJ($self) OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: the header subject is rewritten
# Return Value: none
sub rewrite_article_subject_tag
{
    my ($self, $header, $config, $rw_args) = @_;
    my ($in_code, $out_code);

    # XXX-TODO: need $article_subject_tag expaned already e.g. "\Lmlname\E"
    # XXX-TODO: we should include this exapansion method within this module?
    my $tag     = $config->{ article_subject_tag };
    my $subject = $header->get('subject');

    # decode MIME encoded string and get charset info if could.
    ($subject, $tag, $in_code, $out_code) = $self->decode($subject, $tag);

    # cut off Re: Re: Re: ...
    $self->_cut_off_reply(\$subject);

    # XXX-TODO: method-ify _delete_subject_tag() ?
    # de-tag
    $subject = _delete_subject_tag( $subject, $tag );

    # cut off Re: Re: Re: ...
    $self->_cut_off_reply(\$subject);

    use Mail::Message::Encode;
    my $obj = new Mail::Message::Encode;

    # add(prepend) the rewrited tag with mime encoding.
    $tag = sprintf($tag, $rw_args->{ id });
    my $new_subject = $tag." ".$subject;
    $new_subject = $obj->encode_mime_string($new_subject, 'base64', $in_code);
    $header->replace('Subject', $new_subject);
}


# Descriptions: delete subject tag
#    Arguments: OBJ($self) STR($subject) STR($tag)
# Side Effects: none
# Return Value: STR
sub clean_up
{
    my ($self, $subject, $tag) = @_;
    my ($s, $in_code, $out_code) = $self->decode($subject, $tag);
    return $self->delete_subject_tag($s, $tag);
}


# Descriptions: exapnd special regexp(s) and mime-decode subject.
#    Arguments: OBJ($self) STR($subject) STR($tag)
# Side Effects: none
# Return Value: ARRAY(STR, STR, STR, STR)
sub decode
{
    my ($self, $subject, $tag) = @_;
    my ($in_code, $out_code) = ();

    # for example, ml_name = elena
    # if $tag has special regexp such as \U$ml_name\E or \L$ml_name\E
    if (defined $tag) {
	if ($tag =~ /\\E/o && $tag =~ /\\U|\\L/o) {
	    eval qq{ \$tag = "$tag";};
	    Log($@) if $@;
	}
    }

    # XXX-TODO: care for not Japanese !
    if ($subject =~ /=\?iso-2022-jp\?/i) {
	$in_code  = 'jis-jp';
	$out_code = 'euc-jp';
    }
    else {
	$in_code = $out_code = '';
    }

    # decode mime
    use Mail::Message::Encode;
    my $obj = new Mail::Message::Encode;
    $subject = $obj->decode_mime_string($subject , $out_code);

    return ($subject, $tag, $in_code, $out_code);
}


# Descriptions: delete subject tag
#    Arguments: OBJ($self) STR($subject) STR($tag)
# Side Effects: none
# Return Value: STR
sub delete_subject_tag
{
    my ($self, $subject, $tag) = @_;
    return _delete_subject_tag($subject, $tag);
}


# Descriptions: remove tag-like string
#    Arguments: STR($subject) STR($tag)
#               XXX non OO type function
# Side Effects: none
# Return Value: STR(subject string)
sub _delete_subject_tag
{
    my ($subject, $tag) = @_;
    my $retag = _regexp_compile($tag);

    $subject =~ s/$retag//g;
    $subject =~ s/^\s*//;

    return $subject;
}


=head2 regexp_compile($string)

build a regular expression to trap C<$string>.

=cut


# Descriptions: wrapper for _regexp_compile
#    Arguments: OBJ($self) STR($string)
# Side Effects: none
# Return Value: STR(regular expression)
sub regexp_compile
{
    my ($self, $string) = @_;
    _regexp_compile($string);
}


# Descriptions: create regexp for a subject tag, for example
#               "[%s %05d]" => "\[\S+ \d+\]"
#               not OO style.
#    Arguments: STR($s)
#               $s == a subject tag string
# Side Effects: none
# Return Value: STR(a regexp for the given tag)
sub _regexp_compile
{
    my ($s) = @_;

    if (defined $s) {
	$s = quotemeta( $s );
	$s =~ s@\\\%@\%@g;
	$s =~ s@\%s@\\S+@g;
	$s =~ s@\%d@\\d+@g;
	$s =~ s@\%0\d+d@\\d+@g;
	$s =~ s@\%\d+d@\\d+@g;
	$s =~ s@\%\-\d+d@\\d+@g;

	# quote for regexp substitute: [ something ] -> \[ something \]
	# $s =~ s/^(.)/quotemeta($1)/e;
	# $s =~ s/(.)$/quotemeta($1)/e;

	return $s;
    }
    else {
	return '';
    }
}


=head2 is_reply($subject_string)

speculate C<$subject_string> looks a reply message or not?
It depends on each language specific representations.
Now we can trap Japanese specific keywords.

=cut


# Descriptions: speculate $subject looks a reply message or not?
#    Arguments: OBJ($self) STR($subject)
# Side Effects: none
# Return Value: 1 (looks reply message) or 0
sub is_reply
{
    my ($self, $subject) = @_;

    return 1 if $subject =~ /^\s*Re:/i;

    # XXX-TODO: care for not Japanese string!
    my $pkg = 'Mail::Message::Language::Japanese::Subject';
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	return 1 if &Mail::Message::Language::Japanese::Subject::is_reply($subject);
    };

    return 0;
}


# Descriptions: cut off reply keywords like "Re:".
#    Arguments: OBJ($self) STR_REF($r_subject)
#               $r_subject is SCALAR REREFENCE to the subject string
# Side Effects: $r_subject is rewritten
# Return Value: none
sub _cut_off_reply
{
    my ($self, $r_subject) = @_;

    # XXX-TODO: care for not Japanese string!
    my $pkg = 'Mail::Message::Language::Japanese::Subject';
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	my $obj = new Mail::Message::Language::Japanese::Subject;
	$$r_subject = $obj->cut_off_reply_tag($$r_subject);
    }
    else  {
	Log($@);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Header::Subject first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
