#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML: Header.pm,v 1.27 2001/04/03 03:34:00 fukachan Exp $
#

package FML::Header;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Header;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Header - header manipulators

=head1 SYNOPSIS

    $header = use FML::Header \@header;
    $header->add('X-ML-Info', "mailing list name");
    $header->delete('Return-Receipt-To');
    $header->replace(field, value);

=head1 DESCRIPTION

C<FML::Header> is an adapter for C<Mail::Header> class.
C<Mail::Header> is the base class. 

=head1 METHODS

Methods defined in C<Mail::Header> are available.
For example,
C<modify()>, C<mail_from()>, C<fold()>, C<extract()>, C<read()>,
C<empty()>, C<header()>, C<header_hashref()>, C<add()>, C<replace()>,
C<combine()>, C<get()>, C<delete()>, C<count()>, C<print()>,
C<as_string()>, C<fold_length()>, C<tags()>, C<dup()>, C<cleanup()>,
C<unfold()>.

=cut

require Exporter;
@ISA = qw(Mail::Header Exporter);


# Descriptions: forward new() request to the base class
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub new
{
    my ($self, $args) = @_;

    # an adapter for Mail::Header::new()
    $self->SUPER::new($args);
}


sub DESTROY {}


sub AUTOLOAD
{
    my ($self, $args) = @_;
    Log("Error: $AUTOLOAD is not defined");
}


=head2 C<data_type()>

return the C<type> defind in the header's Content-Type field.

=head2 C<mime_boundary()>

return the C<boundary> defind in the header's Content-Type field.

=cut

# Descriptions: return the type defind in the header's Content-Type field.
#    Arguments: $self
# Side Effects: extra spaces in the type to return is removed.
# Return Value: none
sub data_type
{
    my ($header) = @_;
    my ($type) = split(/;/, $header->get('content-type'));
    if (defined $type) {
	$type =~ s/\s*//g;
	return $type;
    }
    undef;
}


# Descriptions: return boundary defined in Content-Type
#    Arguments: $self $args
# Side Effects: none.
# Return Value: none
sub mime_boundary
{
    my ($header) = @_;
    my $m = $header->get('content-type');

    if ($m =~ /boundary=\"(.*)\"/) {
	return $1;
    }
    else {
	undef;
    }
}


###
### FML specific functions
###

=head1 FML SPECIFIC METHODS

=head2 C<add_fml_ml_name($config, $args)>

add X-ML-Name:

=head2 C<add_fml_traditional_article_id($config, $args)>

add X-Mail-Count:

=head2 C<add_fml_article_id($config, $args)>

add X-ML-Count:

=cut


sub add_fml_ml_name
{
    my ($header, $config, $args) = @_;
    $header->add('X-ML-Name', $config->{ x_ml_name });
}


sub add_fml_traditional_article_id
{
    my ($header, $config, $args) = @_;
    $header->add('X-Mail-Count', $args->{ id });
}


sub add_fml_article_id
{
    my ($header, $config, $args) = @_;
    $header->add('X-ML-Count', $args->{ id });
}


=head2 C<add_software_info($config, $args)>

add X-MLServer: and List-Software:

=head2 C<add_rfc2369($config, $args)>

add List-* sereies defined in RFC2369.

=head2 C<add_x_sequence($config, $args)>

add X-Sequence.

=cut


sub add_software_info
{
    my ($header, $config, $args) = @_;
    my $fml_version = $config->{ fml_version };

    if ($fml_version) {
	$header->add('X-MLServer',   $fml_version);
	$header->add('List-Software', $fml_version);
    }
}


sub add_rfc2369
{
    my ($header, $config, $args) = @_;

    # addresses
    my $post       = $config->{ address_for_post };
    my $command    = $config->{ address_for_command };
    my $maintainer = $config->{ maintainer };

    # See RFC2369 for more details
    $header->add('List-Post',  "<mailto:${post}>")       if $post;
    $header->add('List-Owner', "<mailto:${maintainer}>") if $maintainer;

    if ($command) {
	$header->add('List-Help',      "<mailto:${command}?body=help>");
	$header->add('List-Subscribe', "<mailto:${command}?body=subscribe>");
	$header->add('List-UnSubscribe', 
		     "<mailto:${command}?body=unsubscribe>");
    }
}


sub add_x_sequence
{
    my ($header, $config, $args) = @_;

    $header->add('X-Sequence',  "$config->{ x_ml_name } $args->{ id }");
}


=head2 C<rewrite_subject_tag($config, $args)>

add subject tag e.g. [elena:00010]. 
The real function exists in C<FML::Header::Subject>.

=head2 C<rewrite_reply_to>

add or replace C<Reply-To:>.

=cut


sub rewrite_subject_tag
{
    my ($header, $config, $args) = @_;

    my $pkg = "FML::Header::Subject";
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	$pkg->rewrite_subject_tag($header, $config, $args);
    }
    else {
	Log("Error: cannot load $pkg");
    }
}


sub rewrite_reply_to
{
    my ($header, $config, $args) = @_;
    my $reply_to = $header->get('reply-to');
    unless (defined $reply_to) {
	$header->add('reply-to', $config->{ address_for_post });
    }
}


=head2 C<delete_unsafe_header_fields($config, $args)>

remove header fields defiend in C<$unsafe_header_fields>.

=cut

sub delete_unsafe_header_fields
{
    my ($header, $config, $args) = @_;
    my (@fields) = split(/\s+/, $config->{ unsafe_header_fields });
    for (@fields) { $header->delete($_);}
}


=head1 MISCELLANEOUS UTILITIES

=head2 C<remove_subject_tag_like_string($string)>

remove subject tag like string in C<$string>.

=cut


sub remove_subject_tag_like_string
{
    my ($str) = @_;
    $str =~ s/\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;
    $str;
}


=head2 C<verify_list_post_uniqueness()>

=cut


sub verify_message_id_uniqueness
{
    my ($header, $config, $args) = @_;    
    Log("run verify_message_id_uniqueness");
}

sub verify_x_ml_info_uniqueness
{
    my ($header, $config, $args) = @_;    
    Log("run verify_x_ml_info_uniqueness");
}

sub verify_list_post_uniqueness
{
    my ($header, $config, $args) = @_;    
    Log("run verify_list_post_uniqueness");
}


=head1 SEE ALSO

L<Mail::Header>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Header appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
