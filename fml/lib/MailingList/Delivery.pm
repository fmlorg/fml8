#-*- perl -*-
#
#  Copyright (C) 2000-2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::Delivery;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::Socket;
use MailingList::SMTP;

require Exporter;
@ISA = qw(MailingList::SMTP Exporter);


sub new
{
    my ($self, $args) = @_;
    $self->SUPER::new($args);
}

1;
