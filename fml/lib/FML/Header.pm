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

    $header = use FML::Header $r_header;
    $header->rewrite;

(... not yet mature  ...)
    

=head1 DESCRIPTION

=head1 METHOD

=item rewrite

=item check


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Header.pm appeared in fml5.

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
    $self->SUPER::new($args);
}

sub DESTROY {}

sub AUTOLOAD
{
    my ($self, $args) = @_;
    Log("Error: $AUTOLOAD is not defined");
}


sub rewrite
{
    my ($self) = @_;
}


sub check
{
    my ($self) = @_;

    print "From: ",       $self->get('from');
    print "Message-Id: ", $self->get('message-id');
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

    $header->add('X-ML-Server',   "fml 5.0 prototype 0");
    $header->add('List-Software', "fml 5.0 prototype 0");
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


1;
