#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Parse.pm,v 1.31 2003/08/29 15:33:54 fukachan Exp $
#

package FML::Parse;

use strict;
use Carp;
use FML::Header;
use Mail::Message;
use FML::Config;


=head1 NAME

FML::Parse - parse the incoming message

=head1 SYNOPSIS

    $msg = new FML::Parse $curproc, \*STDIN;

=head1 DESCRIPTION

FML::Parse parses the incoming message. C<new()> analyses the data
injected from STDIN channel, by default, and split it to a set of mail
header and body.  C<new()> returns a C<Mail::Message> object.

=head1 METHODS

=item new( $curproc, [$fd] )

C<$fd> is the file handle.
Normally C<$fd> is the handle for STDIN channel.

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
#    Arguments: OBJ($self) OBJ($curproc) HANDLE($fd)
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
    $curproc->log("read header=$header_size body=$body_size");

    if (defined $msg->envelope_sender()) {
	my $pcb = $curproc->pcb();
	if (defined $pcb) {
	    $pcb->set('credential', 'unix-from', $msg->envelope_sender());
	}
	else {
	    $curproc->logerror("parse: pcb not defined");
	}
    }

    return $msg;
}


=head1 SEE ALSO

L<Mail::Message>,
L<Mail::Header>,
L<FML::Header>,
L<FML::Config>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Parse first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
