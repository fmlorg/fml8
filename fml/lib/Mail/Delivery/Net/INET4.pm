#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: INET4.pm,v 1.10 2004/06/29 10:05:29 fukachan Exp $
#

package Mail::Delivery::Net::INET4;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Mail::Delivery::Utils;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(connect4);


# Descriptions: try connect(2) by IPv4.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create ipv4 smtp connection
# Return Value: HANDLE
sub connect4
{
    my ($self, $args) = @_;
    my $mta    = $args->{ _mta };
    my $socket = undef;

    # XXX we should avoid croak() in IO::Socket module;
    # XXX-TODO: timeout must be customizable.
    eval {
	local($SIG{ALRM}) = sub { Log("Error: timeout to connect $mta");};
	use IO::Socket;
	$socket = new IO::Socket::INET(PeerAddr => $mta,
				       Timeout  => 120,
				       );
    };
    if ($@) {
	Log("Error: cannot create socket for $mta");
	$self->error_set("cannot create socket: $@");
	return undef;
    }

    if (defined $socket) {
	Log("(debug) o.k. connected to $mta");
	$self->{'_socket'} = $socket;
	$socket->autoflush(1);
	return $socket;
    }
    else {
	Log("(debug) error. fail to connect $mta");
	$self->error_set("cannot open socket: $!");
	return undef;
    }
}


=head1 NAME

Mail::Delivery::Net::INET4 - establish tcp connection over IPv4.

=head1 SYNOPSIS

   use Mail::Delivery::Net::INET4;

   $mta = '127.0.0.1:25';
   $self->connect4( { _mta => $mta });

=head1 DESCRIPTION

This module tries to create a socket and establish tcp connection over
IPv4. This is a typical socket program.

=head1 METHODS

=item C<connect4()>

try L<connect(2)>.
If it succeeds, returned file handle and set the value at $self->{ _socket }.
If failed, $self->{ _socket } is undef.

Avaialble arguments follows:

    connect4( { _mta => $mta } );

$mta is a hostname or [raw_ipv4_addr]:port form, for example,
127.0.0.1:25.

=head1 SEE ALSO

L<Mail::Delivery::SMTP>,
L<Socket>,
L<IO::Socket>,
L<Mail::Delivery::Utils>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Net::INET4 first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
