#-*- perl -*-
#
#  Copyright (C) 2000-2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package Mail::Delivery;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::Socket;


=head1 NAME

Mail::Delivery - mail delivery system interface

=head1 SYNOPSIS

    use Mail::Delivery;
    my $service = new Mail::Delivery {
	protocol           => 'SMTP',
	default_io_timeout => 10,
    };
    if ($service->error) { Log($service->error); return;}


    $map_params = {
	'mysql:toymodel' => {
	    getline        => "select ... ",
	    get_next_value => "select ... ",
	    add            => "insert ... ",
	    delete         => "delete ... ",
	    replace        => "set address = 'value' where ... ",
	},
    };

    $service->deliver(
                      {
                          smtp_servers    => '[::1]:25 127.0.0.1:25',

                          smtp_sender     => 'rudo@nuinui.net',
                          recipient_maps  => $recipient_maps,
                          recipient_limit => 1000,
			  map_params      => $map_params,

                          header          => $header_object,
                          body            => $body_object,
                      });
    if ($service->error) { Log($service->error); return;}

Actually the real estate of this class is 
almost C<Mail::Delivery::SMTP> class.
Please see it for more details.

=head1 DESCRIPTION

In C<Mail::Delivery> class, 
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
    my $pkg      = 'Mail::Delivery::SMTP';

    # char's of the protocol name is aligned to upper case.
    $protocol =~ tr/a-z/A-Z/;
 
    if ($protocol eq 'SMTP') {
	$pkg = 'Mail::Delivery::SMTP';
    }
    elsif ($protocol eq 'ESMTP') {
	$pkg = 'Mail::Delivery::EMTP';
    }
    elsif ($protocol eq 'LMTP') {
	$pkg = 'Mail::Delivery::LMTP';
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

Mail::Delivery appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
