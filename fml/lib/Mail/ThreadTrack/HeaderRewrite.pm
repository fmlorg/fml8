#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: HeaderRewrite.pm,v 1.2 2001/11/03 00:18:01 fukachan Exp $
#

package Mail::ThreadTrack::HeaderRewrite;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::ThreadTrack::HeaderRewrite - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 C<rewrite_header($msg)>

C<$msg> is Mail::Message object.

=cut


sub rewrite_header
{
    my ($self, $msg) = @_;
    my $header = $msg->rfc822_message_header;

    if (defined $self->{ _status_info }) {
	$header->add('X-Thread-Status', $self->{ _status_info });
    }

    if (defined $self->{ _thread_id }) {
	$header->add('X-Thread-ID', $self->{ _thread_id });
    }

    if (defined $self->{ _status_history }) {
	$header->add('X-Thread-History', $self->{ _status_history });
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::ThreadTrack::HeaderRewrite appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
