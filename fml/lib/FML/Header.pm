#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Header;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Header;
use FML::Log qw(Log);


=head1 NAME

FML::Header - header manipulators

=head1 SYNOPSIS

    $header = use FML::Header \@header;
    $header->add('X-ML-Info', "mailing list name");
    
=head1 DESCRIPTION

FML::Header is an adapter for Mail::Address class.
That is, Mail::Address is the base class. 

=head1 METHODS

=cut

require Exporter;
@ISA = qw(Mail::Header Exporter);


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


sub content_type
{
    my ($header) = @_;
    my ($type) = split(/;/, $header->get('content-type'));
    if (defined $type) {
	$type =~ s/\s*//g;
	return $type;
    }
}


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


sub remove_subject_tag_like_string
{
    my ($str) = @_;
    $str =~ s/\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;
    $str;
}


sub delete_unsafe_header_fields
{
    my ($header, $config, $args) = @_;
    my (@fields) = split(/\s+/, $config->{ unsafe_header_fields });
    for (@fields) { $header->delete($_);}
}


=head1 SEE ALSO

L<Mail::Address>

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
