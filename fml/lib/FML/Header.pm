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


1;
