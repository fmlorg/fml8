#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: INET6.pm,v 1.14 2004/01/24 09:03:58 fukachan Exp $
#

package Mail::Delivery::Net::INET6;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Mail::Delivery::Utils;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(is_ipv6_ready is_ipv6_mta_syntax connect6);


# Descriptions: we have Socket6.pm or not ?
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _we_can_use_Socket6
{
    my ($self, $args) = @_;

    eval q{
	use Socket;
	use Socket6;
    };

    if ($@ =~ /Can\'t locate Socket6.pm/o) {
	$self->{_ipv6_ready} = 'no';
    }
    else {
	Log("IPv6 ready");
	$self->{_ipv6_ready} = 'yes';
    }
}


# Descriptions: This host supports IPv6 ?
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub is_ipv6_ready
{
    my ($self, $args) = @_;

    # probe the IPv6 availability for the first time
    unless ($self->{_ipv6_ready}) {
	_we_can_use_Socket6($self, $args);
    };

    return ($self->{_ipv6_ready} eq 'yes' ? 1 : 0);
}


# Descriptions: $host is IPv6 syntax ?
#               return (host, port) if IPv6 native format
#    Arguments: OBJ($self) STR($host)
# Side Effects: none
# Return Value: ARRAY(host, port)
sub is_ipv6_mta_syntax
{
    my ($self, $host) = @_;
    my ($x_host, $x_port);

    # check the mta syntax whether it is ipv6 form or not.
    if ($host =~ /\[([\d:]+)\]:(\d+)/) {
	($x_host, $x_port) = ($1, $2);
	return ($x_host, $x_port);
    }
    else {
	return wantarray ? () : undef;
    }
}


# Descriptions: try connect(2) by IPv6.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create IPv6 smtp connection
# Return Value: none
sub connect6
{
    my ($self, $args) = @_;
    my $mta = $args->{ _mta };

    # check the mta syntax is $ipv6_addr:$port or not.
    my ($host, $port) = $self->is_ipv6_mta_syntax( $args->{ _mta } );

    # if mta is ipv6 raw address syntax,
    # try to parse $mta to $host:$port style.
    unless ($host) {
	if ($mta =~ /(\S+):(\S+)/) {
	    ($host, $port) = ($1, $2);
	}
    }

    # Error: hmm, invalid MTA
    unless ($host && $port) {
	Log("connect6: cannot find mta=$mta");
	$self->{_socket} = undef;
	return undef;
    }

    my $fh = undef;
    eval q{
	use IO::Handle;
	use Socket;
	use Socket6;

	my ($family, $type, $proto, $saddr, $canonname);

	# resolve socket info by getaddrinfo()
	my @res = getaddrinfo($host, $port, AF_UNSPEC, SOCK_STREAM);
	$family = -1;

	# reset.
	delete $self->{_socket} if defined $self->{_socket};

      ADDR_ENTRY:
	while (scalar(@res) >= 5) {
	    ($family, $type, $proto, $saddr, $canonname, @res) = @res;

	    my ($host, $port) =
		getnameinfo($saddr, NI_NUMERICHOST | NI_NUMERICSERV);

	    # check only IPv6 case here.
	    next ADDR_ENTRY if $family != AF_INET6;

	    $fh = new IO::Socket;
	    socket($fh, $family, $type, $proto) || do {
		# XXX-TODO: need error_clear() some where ???
		Log("Error: cannot create IPv6 socket");
		$self->error_set("cannot create IPv6 socket");
		next ADDR_ENTRY;
	    };
	    if (connect($fh, $saddr)) {
		Log("(debug6) o.k. connect [$host]:$port");
		last ADDR_ENTRY;
	    }
	    else {
		Log("Error: cannot connect [$host]:$port via IPv6");
		$self->error_set("cannot [$host]:$port via IPv6");
	    }

	    $family = -1;
	}

	# check socket is under connected state.
	# XXX sub $socket->connected { getpeername($self);}
	# XXX IO::Socket of old perl have no such method.
	if (($family != -1) && defined($fh)) {
	    if ($family == AF_INET6) {
		$self->{_socket} = $fh;
		Log("connected to $host:$port by IPv6");
	    }
	    else { # cheap diagnostic
		delete $self->{_socket};
		Log("connected to $host:$port by ? (AF=$family)");
	    }
	} else {
	    delete $self->{_socket};
	    Log("(debug6) fail to connect [$host]:$port by IPv6");
	    $self->error_set("cannot [$host]:$port via IPv6");
	}
    };

    Log($@) if $@;
}


=head1 NAME

Mail::Delivery::Net::INET6 - establish tcp connection over IPv6.

=head1 SYNOPSIS

    if ($self->is_ipv6_ready($args)) {
	$self->connect6($args);
    }

=head1 DESCRIPTION

This module tries to create a socket and establish a tcp connection
over IPv6. It is used within C<Mail::Delivery::SMTP> module.

=head1 METHODS

=item C<is_ipv6_ready()>

It checks whether your environment has Socket6.pm or not?
If Socket6 module exists, we assume your operating system is IPv6 ready!

=item C<connect6()>

try L<connect(2)>.
If it succeeds, returned socket and set the value at $self->{ _socket }.
If failed, $self->{ _socket } is undef.

Avaialble arguments follows:

    connect6( { _mta => $mta } );

$mta is a hostname or [raw_ipv6_addr]:port form, for example,
[::1]:25.

=head1 SEE ALSO

L<Mail::Delivery::SMTP>,
L<Socket6>,
L<Socket>,
L<IO::Handle>,
L<IO::Socket>,
L<Mail::Delivery::Utils>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Net::INET6 first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
