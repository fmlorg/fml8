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


=head1 NAME

MailingList::Delivery - mail delivery system interface

=head1 SYNOPSIS

    use MailingList::Delivery;
    my $service = new MailingList::Delivery {
	protocol           => 'SMTP',
	default_io_timeout => 10,
    };
    if ($service->error) { Log($service->error); return;}

    $service->deliver(
                      {
                          smtp_servers    => '[::1]:25 127.0.0.1:25',

                          smtp_sender     => 'rudo@nuinui.net',
                          recipient_maps  => $recipient_maps,
                          recipient_limit => 1000,

                          header          => $header_object,
                          body            => $body_object,
                      });
    if ($service->error) { Log($service->error); return;}

Actually the real estate of this class is 
almost C<MailingList::SMTP> class.
Please see it for more details.

=head1 DESCRIPTION

In C<MailingList> class, 
C<Delivery> is an adapter to
C<SMTP>
C<ESMTP>
C<LMTP> classes. 
For example, we use 
C<Delivery>
as an entrance into 
actual delivery routines in 
C<SMTP>
C<ESMTP>
C<LMTP> classes. 

                     SMTP
                      |
                      A
                  ----------
                 |          |
  Delivery --> ESMTP       LMTP


=head1 METHODS

=item C<new($args)>

constructor. The request is forwarded to SUPER class.

=cut


sub new
{
    my ($self, $args) = @_;
    my $protocol =  $args->{ protocol } || 'SMTP';
    my $pkg      = 'MailingList::SMTP';

    # char's of the protocol name is aligned to upper case.
    $protocol =~ tr/a-z/A-Z/;
 
    if ($protocol eq 'SMTP') {
	$pkg = 'MailingList::SMTP';
    }
    elsif ($protocol eq 'ESMTP') {
	$pkg = 'MailingList::EMTP';
    }
    elsif ($protocol eq 'LMTP') {
	$pkg = 'MailingList::LMTP';
    }
    else {
	croak("unknown protocol=$protocol");
	return undef;
    }

    unshift(@ISA, $pkg);
    eval qq{require $pkg; $pkg->import();};
    unless ($@) {
	$self->SUPER::new($args);
    }
    else {
	croak("fail to load $pkg");
	return undef;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

MailingList::Delivery appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
