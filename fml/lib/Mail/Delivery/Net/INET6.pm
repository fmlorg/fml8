#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#  Copyright (C) 2012 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: INET6.pm,v 1.21 2006/07/09 12:11:13 fukachan Exp $
#

package Mail::Delivery::Net::INET6;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $is_module_checked);
use Carp;
use IO::Handle;
use IO::Socket;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(is_ipv6_ready
	     set_ipv6_ready
	     get_ipv6_ready

	     parse_mta6

	     check_ipv6_module_available

	     is_pure_ipv4_syntax
	     is_ipv6_mta_syntax

	     connect6);


# Descriptions: we have Socket6.pm or not ?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub check_ipv6_module_available
{
    my ($self) = @_;

    if ($is_module_checked) {
	return;
    }
    $is_module_checked = 1;

    if (defined \&pack_sockaddr_in6) {
	return;
    }

    eval q{
	use Socket6;
    };
    if ($@ =~ /Can\'t locate Socket6.pm/o) {
	$self->set_ipv6_ready("no");
    }
    else {
	$self->logdebug("IPv6 ready");
	$self->set_ipv6_ready("yes");
    }
}


# Descriptions: This host supports IPv6 ?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM (1 or 0)
sub is_ipv6_ready
{
    my ($self) = @_;

    # probe the IPv6 availability for the first time
    unless ($self->get_ipv6_ready()) {
	$self->check_ipv6_module_available();
    };

    my $status = $self->get_ipv6_ready() || 'no';
    return ($status eq 'yes' ? 1 : 0);
}


# Descriptions: set that this system is ipv6 ready.
#    Arguments: OBJ($self) STR($value)
# Side Effects: update $self.
# Return Value: none
sub set_ipv6_ready
{
    my ($self, $value) = @_;

    if ($value eq 'yes' || $value eq 'no') {
	$self->{_ipv6_ready} = $value;
    }
    else {
	$self->{_ipv6_ready} = undef;
    }
}


# Descriptions: get if this system is ipv6 ready.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_ipv6_ready
{
    my ($self) = @_;
    return( $self->{_ipv6_ready} || undef );
}


# Descriptions: check if $mta is IPv6 syntax ?
#               return (host, port) if $mta is a IPv6 native format.
#    Arguments: OBJ($self) STR($mta)
# Side Effects: none
# Return Value: ARRAY(host, port)
sub is_ipv6_mta_syntax
{
    my ($self, $mta) = @_;

    # check the mta syntax whether it is ipv6 form or not.
    if ($mta =~ /\[([\d:]+)\]:(\d+)/) {
	my ($host, $port) = ($1, $2);
	return ($host, $port);
    }
    else {
	return wantarray ? () : undef;
    }
}


# Descriptions: check if $mta is IPv4 syntax ?
#    Arguments: OBJ($self) STR($mta)
# Side Effects: none
# Return Value: NUM
sub is_pure_ipv4_syntax
{
    my ($self, $mta) = @_;

    # e.g. 127.0.0.1:25
    if ($mta =~ /^\d+\.\d+\.\d+\.\d+:\d+$/) {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: parse host:port style syntax to (host, port).
#    Arguments: OBJ($self) STR($mta)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub parse_mta6
{
    my ($self, $mta) = @_;

    if ($mta =~ /(\S+):(\S+)/) {
	return($1, $2);
    }
    else {
	return(undef, undef);
    }
}


# Descriptions: try connect(2) by IPv6.
#    Arguments: OBJ($self) STR($mta)
# Side Effects: create IPv6 smtp connection
# Return Value: none
sub connect6
{
    my ($self, $mta) = @_;

    # check the mta syntax is $ipv6_addr:$port or not.
    my ($host, $port) = $self->is_ipv6_mta_syntax($mta);

    # if mta is ipv6 raw address syntax,
    # try to parse $mta to $host:$port style.
    unless ($host) {
	($host, $port) = $self->parse_mta6($mta);
    }

    # ASSEART: hmm, invalid MTA
    unless ($host && $port) {
	$self->logerror("connect6: cannot find mta=$mta");
	$self->set_socket(undef);
	return undef;
    }

    my $fh = undef;
    eval q{
	my ($family, $type, $proto, $saddr, $canonname);

	# resolve socket info by getaddrinfo()
	my @res = getaddrinfo($host, $port, AF_UNSPEC, SOCK_STREAM);
	$family = -1;

	# reset.
	if (defined $self->get_socket()) {
	    $self->set_socket(undef);
	}

      ADDR_ENTRY:
	while (scalar(@res) >= 5) {
	    ($family, $type, $proto, $saddr, $canonname, @res) = @res;

	    my ($host, $port) =
		getnameinfo($saddr, NI_NUMERICHOST | NI_NUMERICSERV);

	    # check only IPv6 case here.
	    next ADDR_ENTRY if $family != AF_INET6;

	    # XXX-TODO: timeout customizable
	    $fh = new IO::Socket;
	    socket($fh, $family, $type, $proto) || do {
		# XXX-TODO: need error_clear() some where ???
		$self->logerror("cannot create IPv6 socket");
		$self->set_error("cannot create IPv6 socket");
		next ADDR_ENTRY;
	    };
	    if (connect($fh, $saddr)) {
		$self->logdebug("o.k. connect [$host]:$port");
		last ADDR_ENTRY;
	    }
	    else {
		$self->logerror("cannot connect [$host]:$port via IPv6");
		$self->set_error("cannot connect [$host]:$port via IPv6");
	    }

	    $family = -1;
	}

	# check socket is under connected state.
	# XXX sub $socket->connected { getpeername($self);}
	# XXX IO::Socket of old perl have no such method.
	if (($family != -1) && defined($fh)) {
	    if ($family == AF_INET6) {
		$self->set_socket($fh);
		$self->logdebug("connected to $host:$port by IPv6");
	    }
	    else { # cheap diagnostic
		$self->set_socket(undef);
		$self->logdebug("connected to $host:$port by ? (AF=$family)");
	    }
	} else {
	    $self->set_socket(undef);
	    $self->logerror("cannot connect [$host]:$port by IPv6");
	    $self->set_error("cannot connect [$host]:$port via IPv6");
	}
    };

    $self->logerror("connect6: $@") if $@;
}


=head1 NAME

Mail::Delivery::Net::INET6 - establish tcp connection over IPv6.

=head1 SYNOPSIS

    if ($self->is_ipv6_ready($args)) {
	$self->connect6($args);
    }

=head1 DESCRIPTION

This module tries to create a socket and establish a tcp connection
over IPv6. It is used within L<Mail::Delivery::SMTP> module.

=head1 METHODS

=head2 is_ipv6_ready()

It checks whether your environment has Socket6.pm or not?
If Socket6 module exists, we assume your operating system is IPv6 ready!

=head2 connect6()

try L<connect(2)>.
If it succeeds, returned socket or undef.

Also, save socket via set_socket() access method.

Avaialble arguments follows:

    connect6( { mta => $mta } );

$mta is a hostname or [raw_ipv6_addr]:port form, for example,
[::1]:25.

=head1 SEE ALSO

L<Mail::Delivery::SMTP>,
L<Socket6>,
L<IO::Handle>,
L<IO::Socket>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
Copyright (C) 2012 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Net::INET6 first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
