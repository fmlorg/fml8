#-*- perl -*-
#
#  Copyright (C) 2000 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Parse;

use vars qw($InComingMessage);
use strict;
use Carp;
use FML::Header;
use MailingList::Messages;
use FML::Config;
use FML::Log qw(Log);


=head1 NAME

FML::Parse - parse the incoming message/mail to the header and body.

=head1 SYNOPSIS

    ($r_header, $r_body) = new FML::Parse \*STDIN;

=head1 DESCRIPTION

FML::Parse parses the incoming mail. The target to parse is given the
argument os new() constructor.

$r_header is the reference to the header object, which is returned by
Mail::Header class. $r_body is reference to the scalar mail body
variable, which is alloced in FML::Parse name space.

=head1 METHODS

=item new( fd )

C<fd> is the file handle. 
Normally C<fd> is the handle for STDIN channel.

=cut

sub new
{
    my ($self, $curproc, $fd) = @_;
    my $me = {};
    bless $me, $self;

    # return ( $ref_to_mail_header, $ref_to_mail_body, $error_code);
    return $me->_parse($curproc, $fd);
}


# return ( $ref_to_mail_header, $ref_to_mail_body, $error_code);
sub _parse
{
    my ($self, $curproc, $fd) = @_;
    my ($header, $header_size);
    my $body_size;
    my $total_buffer_size;
    my ($p, $buf);

    # extract header and put it to $header
    while ($p = sysread($fd, $_, 1024)) {
	$total_buffer_size += $p;
	$buf .= $_; 
	if (($p = index($buf, "\n\n", 0)) > 0) {
	    $header      = substr($buf, 0, $p + 1);
	    $header_size = $p + 1;
	    $InComingMessage = substr($buf, $p + 2);
	    last;
	}
    }

    # extract mail body and put it to $FML::Parse::InComingMessage
    while ($p = sysread($fd, $_, 1024)) {
	$total_buffer_size += $p;
	$InComingMessage     .= $_;
    }

    # read the message (mail body) from the incoming mail
    $body_size = length($InComingMessage);

    Log("read total=$total_buffer_size header=$header_size body=$body_size");

    my @h = split(/\n/, $header);
    my $x;
    for $x (@h) { $x .= "\n";}

    # save unix-from (mail-from) in PCB and remove it in the header
    if ($h[0] =~ /^From\s/o) {
	my $pcb = $curproc->{ pcb };
	$pcb->set('credential', 'unix-from', $h[0]);
	shift @h;
    }

    # extract each field from the header array
    my $r_header = new FML::Header \@h, Modify => 0;
    my $r_body   = new MailingList::Messages {
	boundary     => $r_header->mime_boundary(),
	content_type => $r_header->content_type(),
	content      => \$InComingMessage,
    };

    # return ( $ref_to_mail_header, $ref_to_mail_body, $error_code);
    return ($r_header, $r_body, 0);
}


=head1 SEE ALSO

L<Mail::Header>,
L<FML::Header>,
L<MailingList::Messages>,
L<FML::Config>,
L<FML::Log>


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Parse appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
