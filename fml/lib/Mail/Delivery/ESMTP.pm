#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ESMTP.pm,v 1.11 2004/06/29 10:05:29 fukachan Exp $
#

package Mail::Delivery::ESMTP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Delivery::SMTP;

@ISA = qw(Mail::Delivery::SMTP);


# Descriptions: constructor. forward the request to base class (SMTP).
#    Arguments: OBJ($self) VARARGS(@args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, @args) = @_;
    $self->SUPER::new(@args);
}


=head1 NAME

Mail::Delivery::ESMTP - Extended SMTP class.

=head1 SYNOPSIS

    use Mail::Message;

      ... make Mail::Message object ...

    use Mail::Delivery;
    $service = new Mail::Delivery { protocol => 'ESMTP' };
    $service->deliver( ... );

See L<Mail::Delivery::SMTP> for more details since this ESMTP class
is an adapter for SMTP (super) class for convenience.
All requests are forwarded to SMTP super class.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::ESMTP first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
