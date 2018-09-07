#-*- perl -*-
#
# Copyright (C) 2004,2005 Ken'ichi Fukamachi
#
# $FML: Subject.pm,v 1.7 2005/08/20 01:25:16 fukachan Exp $
#

package Mail::Message::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

# base class is "Mail::Message::String".
use Mail::Message::String;
@ISA = qw(Mail::Message::String);


=head1 NAME

Mail::Message::Subject - utilities to manipulate subject string.

=head1 SYNOPSIS

    my $subject = new Mail::Message::Subject $header->get('subject');
    $subject->mime_header_decode();
    if ($subject->has_reply_tag()) {
	$subject->delete_dup_reply_tag();
    }
    $subject->mime_header_encode();
    $header->set($subject->as_str());


=head1 DESCRIPTION

=head2 new($subject)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) STR($subject)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $subject) = @_;
    $self->SUPER::new($subject);
}


=head1 Re: TAG HANLING

=cut


# Descriptions: cut off reply keywords like "Re:".
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub delete_dup_reply_tag
{
    my ($self)  = @_;
    my $subject = $self->as_str();

    # XXX-TODO: care for not Japanese string!
    # XXX-TODO: call this module if $subject is Japanese or English.
    # XXX-TODO: but what should we do when the code is not the two above ?
    if (1) {
	use Mail::Message::Language::Japanese::Subject;
	my $sbj  = new Mail::Message::Language::Japanese::Subject;
	$subject = $sbj->cutoff_reply_tag($subject);
	$self->set($subject);
    }
}


# Descriptions: speculate $subject looks a reply message or not?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 (looks reply message) or 0
sub has_reply_tag
{
    my ($self)  = @_;
    my $subject = $self->as_str();
    my $charset = $self->get_mime_charset();

    return 1 if $subject =~ /^\s*Re:/i;

    # XXX anyway, we use this method always :-)
    # XXX-TODO: care for not Japanese string!
    if (1 || $charset =~ /iso-2022-jp/io) {
	use Mail::Message::Language::Japanese::Subject;
	my $sbj  = new Mail::Message::Language::Japanese::Subject;
	if ($sbj->is_reply($subject)) {
	    return 1;
	}
    }

    return 0;
}


=head1 ML TAG HANDLING

=cut


# Descriptions: remove tag-like string.
#    Arguments: OBJ($self) STR($tag)
# Side Effects: none
# Return Value: STR(subject string)
sub delete_tag
{
    my ($self, $tag) = @_;
    my $subject = $self->as_str();

    # XXX $subject SHOULD BE MIME DECODED ALREADY.
    # for example, ml_name = elena
    # if $tag has special regexp such as \U$ml_name\E or \L$ml_name\E
    if (defined $tag) {
        if ($tag =~ /\\E/o && $tag =~ /\\U|\\L/o) {
            eval qq{ \$tag = "$tag";};
            carp($@) if $@;
        }

	my $retag = $self->_regexp_compile($tag);
	$subject  =~ s/$retag//g;
	$subject  =~ s/^\s*//;
	$self->set($subject);
    }

    return $subject;
}


# Descriptions: create regexp for a subject tag, for example
#               "[%s %05d]" => "\[\S+ \d+\]"
#               not OO style.
#    Arguments: OBJ($self) STR($s)
#               $s == a subject tag string
# Side Effects: none
# Return Value: STR(a regexp for the given tag)
sub _regexp_compile
{
    my ($self, $s) = @_;

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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Subject first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

C<Subject_to_unixtime> is imported from fml 4.0-current libmti.pl.

=cut


1;
