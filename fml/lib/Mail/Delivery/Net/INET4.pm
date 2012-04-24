#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004,2005,2006 Ken'ichi Fukamachi
#  Copyright (C) 2012 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: INET4.pm,v 1.14 2006/07/09 12:11:13 fukachan Exp $
#

package Mail::Delivery::Net::INET4;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(connect4);


# Descriptions: try connect(2) by IPv4.
#    Arguments: OBJ($self) STR($mta)
# Side Effects: create ipv4 smtp connection
# Return Value: HANDLE
sub connect4
{
    my ($self, $mta) = @_;
    my $socket = undef;

    # ASSERT
    unless (defined $mta) {
	$self->logerror("connect4: mta undefined");
	return undef;
    }
    unless ($mta) {
	$self->logerror("connect4: mta undefined");
	return undef;
    }

    # XXX we should avoid croak() in IO::Socket module;
    # XXX-TODO: timeout must be customizable.
    eval {
	local($SIG{ALRM}) = sub {
	    $self->logerror("timeout to connect $mta");
	};
	use IO::Socket;
	$socket = new IO::Socket::INET(PeerAddr => $mta,
				       Timeout  => 120,
				       );
    };
    if ($@) {
	$self->logerror("cannot create socket for $mta");
	$self->set_error("cannot create socket: $@");
	return undef;
    }

    if (defined $socket) {
	$self->logdebug("o.k. connected to $mta");
	$self->set_socket($socket);
	$socket->autoflush(1);
	return $socket;
    }
    else {
	$self->logdebug("cannot open socket ($!) mta=$mta");
	$self->set_error("cannot open socket: $!");
	return undef;
    }
}


=head1 NAME

Mail::Delivery::Net::INET4 - establish tcp connection over IPv4.

=head1 SYNOPSIS

   use Mail::Delivery::Net::INET4;

   $mta = '127.0.0.1:25';
   $self->connect4( { mta => $mta });

=head1 DESCRIPTION

This module tries to create a socket and establish tcp connection over
IPv4. This is a typical socket program.

=head1 METHODS

=head2 connect4()

try L<connect(2)>.
If it succeeds, return a file handle.
return undef if failes.

Also, save the socket handle via set_socket() access method.

Avaialble arguments follows:

    connect4( { mta => $mta } );

$mta is a hostname or [raw_ipv4_addr]:port form, for example,
127.0.0.1:25.

=head1 SEE ALSO

L<Mail::Delivery::SMTP>,
L<IO::Socket>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004,2005,2006 Ken'ichi Fukamachi
Copyright (C) 2012 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Net::INET4 first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
