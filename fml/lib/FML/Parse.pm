#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Parse.pm,v 1.24 2002/04/26 00:25:25 fukachan Exp $
#

package FML::Parse;

use strict;
use Carp;
use FML::Header;
use Mail::Message;
use FML::Config;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Parse - parse the incoming message

=head1 SYNOPSIS

    $msg = new FML::Parse $curproc, \*STDIN;

=head1 DESCRIPTION

FML::Parse parses the incoming message. C<new()> analyses the data
injected from STDIN channel, by default, and split it to a set of mail
header and body.  C<new()> returns a C<Mail::Message> object.

=head1 METHODS

=item new( fd )

C<fd> is the file handle.
Normally C<fd> is the handle for STDIN channel.

=cut


# Descriptions: parse message read from file handle $fd
#    Arguments: OBJ($self) OBJ($curproc) HANDLE($fd)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $fd) = @_;
    my $me = {};
    bless $me, $self;

    return $me->_parse($curproc, $fd);
}


# Descriptions: parse message read from file handle $fd
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub _parse
{
    my ($self, $curproc, $fd) = @_;

    use Mail::Message;
    my $msg = Mail::Message->parse( {
	fd           => $fd,
	header_class => 'FML::Header',
    });

    # log information
    my $header_size = $msg->whole_message_header_size();
    my $body_size   = $msg->whole_message_body_size();
    Log("read header=$header_size body=$body_size");

    if (defined $msg->envelope_sender()) {
	my $pcb = $curproc->{ pcb };
	$pcb->set('credential', 'unix-from', $msg->envelope_sender());
    }

    return $msg;
}


=head1 SEE ALSO

L<Mail::Message>,
L<Mail::Header>,
L<FML::Header>,
L<FML::Config>,
L<FML::Log>


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Parse appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
