#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::INET4;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use MailingList::Utils;

require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw(_connect4);

sub _connect4
{
    my ($self, $args) = @_;
    my $mta = $args->{ _mta };
    my $socket = '';

    # avoid croak() in IO::Socket module;
    eval {
	local($SIG{ALRM}) = sub { Log("Error: timeout to connect $mta");};
	use IO::Socket;
	$socket = new IO::Socket::INET($mta);
    };
    if ($@) {
	Log("Error: cannot make socket for $mta");
	$self->_error_reason("Error: cannot make socket: $@");
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
	$self->_error_reason("Error: cannot open socket: $!");
	return undef;
    }
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
