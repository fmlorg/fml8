#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::Net::INET6;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use MailingList::Utils;

require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw(is_ipv6_ready is_ipv6_mta_syntax _connect6);

sub _we_can_use_Socket6
{
    my ($self, $args) = @_;

    eval q{ 
	use Socket; 
	use Socket6;
    };

    if ($@ =~ /Can\'t locate Socket6.pm/) { 
	$self->{_ipv6_ready} = 'no';
    }
    else {
	Log("IPv6 ready");
	$self->{_ipv6_ready} = 'yes';
    }
}


sub is_ipv6_ready
{
    my ($self, $args) = @_;

    # probe the IPv6 availability for the first time
    unless ($self->{_ipv6_ready}) {
	_we_can_use_Socket6($self, $args);
    };

    $self->{_ipv6_ready} eq 'yes' ? 1 : 0;
}


sub is_ipv6_mta_syntax
{
    my ($self, $host) = @_;
    my ($x_host, $x_port);

    # check the mta syntax whether it is ipv6 form or not.
    if ( $host =~ /\[([\d:]+)\]:(\d+)/) {
	($x_host, $x_port) = ($1, $2);
	return ($x_host, $x_port);
    }
    else {
	return wantarray ? () : undef;
    }
}


sub _connect6
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

    # hmm, invalid MTA
    unless ($host && $port) {
	Log("_connect6: cannot find mta=$mta");
	$self->{_socket} = undef;
	return undef;
    }

    $self->{_socket} = undef;
    return undef;

    eval q{
	use IO::Handle;
	use Socket; 
	use Socket6;

	my ($family, $type, $proto, $saddr, $canonname);
	my $fh = new IO::Socket;
	my $inet6_family = &AF_INET6;

	# resolve socket info by getaddrinfo()
	my @res = getaddrinfo($host, $port, AF_UNSPEC, SOCK_STREAM);
	$family = -1;

      LOOP:
	while (scalar(@res) >= 5) {
	    ($family, $type, $proto, $saddr, $canonname, @res) = @res;

	    my ($host, $port) = 
		getnameinfo($saddr, NI_NUMERICHOST | NI_NUMERICSERV);

	    # check only IPv6 case here.
	    next LOOP if $family != $inet6_family;

	    socket($fh, $family, $type, $proto) || do {
		Log("Error: cannot create IPv6 socket");
		next LOOP;
	    };
	    if (connect($fh, $saddr)) {
		Log("(debug6) o.k. connect $host");
		last LOOP;
	    }
	    else {
		Log("Error: cannot connect via IPv6");
	    }

	    $family = -1;
	}

	if ($family != -1) {
	    $self->{_socket} = $fh;
	    Log("connected to $host:$port by IPv6");
	} else {
	    $self->{_socket} = undef;
	    Log("(debug6) fail to connect $host:$port by IPv6");
	}
    };
}


=head1 NAME

FML::__HERE_IS_YOUR_MODULE_NAME__.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__MODULE_NAME__.pm appeared in fml5.

=cut

1;
