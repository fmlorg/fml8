#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#

package FML::Process::QueueManager;

use strict;
use Carp;

=head1 NAME

FML::Process::QueueManager - provide queue manipulation functions

=head1 SYNOPSIS

    use FML::Process::QueueManager;

=head1 DESCRIPTION

=cut

use FML::Log qw(Log LogWarn LogError);

sub send
{
    my ($self, $queuefile) = @_;

    use Mail::Message;
    my $msg = Mail::Message->parse( { file => $queuefile } );

    use FML::Mailer;
    my $obj = new FML::Mailer;
    my ($sender, $rcpt);
    $obj->send( {
	sender    => $sender,
	recipient => $rcpt,
	message   => $msg,
    });
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::QueueManager appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
