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

=head1 NAME

FML::Header - header manipulators

=head1 SYNOPSIS

    $header = use FML::Header \@header;
    $header->add('X-ML-Info', "mailing list name");
    
=head1 DESCRIPTION

FML::Header is an adapter for Mail::Address class.
That is, Mail::Address is the base class. 

=head1 METHOD

=cut

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Header;
use FML::Log qw(Log);

require Exporter;
@ISA = qw(Exporter Mail::Header);


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


sub add_fml_ml_name
{
    my ($header, $config, $args) = @_;

    $header->add('X-ML-Name', $config->{ address_for_post });
}


sub add_fml_article_id
{
    my ($header, $config, $args) = @_;

    $header->add('X-Mail-Count', $args->{ id });
}


sub add_software_info
{
    my ($header, $config, $args) = @_;
    my $fml_version = $config->{ fml_version };

    if ($fml_version) {
	$header->add('X-ML-Server',   $fml_version);
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

    # RFC2369
    $header->add('List-Post',  "<mailto:${post}>")       if $post;
    $header->add('List-Owner', "<mailto:${maintainer}>") if $maintainer;
}


sub add_x_sequence
{
    my ($header, $config, $args) = @_;

    $header->add('X-Sequence',  "$args->{ name } $args->{ id }");
}


sub rewrite_subject
{
    my ($header, $config, $args) = @_;

    my $pkg = "FML::Header::Subject";
    require $pkg; $pkg->import();

    # subject tag 
    if ($config->has_attribute( header_rewrite_rules , add_subject_tag )) {
	$pkg->rewrite_subject_tag($header, $config, $args);
    }
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

FML::Header.pm appeared in fml5.

=cut

1;
