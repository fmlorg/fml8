#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::ESMTP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use MailingList::SMTP;

require Exporter;
@ISA = qw(MailingList::SMTP Exporter);

sub new
{
    my ($self) = @_;
    $self->SUPER::new(@_);
}


=head1 NAME

MailingList::ESMTP - Extended SMTP class

=head1 SYNOPSIS

   use MailingList::ESMTP;
   $service = new MailingList::ESMTP;
   $service->deliver( ... );

See L<MailingList::SMTP> for more details since this ESMTP class
is an adapter for SMTP (super) class for convenience.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

MailingList::ESMTP appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
