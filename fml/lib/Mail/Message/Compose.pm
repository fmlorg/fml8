#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Compose.pm,v 1.2 2001/05/30 14:35:11 fukachan Exp $
#


package Mail::Message::Compose;

use strict;
use vars qw(@ISA);
use Carp;

use MIME::Lite;
@ISA = qw(MIME::Lite);

=head1 NAME

Mail::Message::Compose - message composer

=head1 SYNOPSIS

See C<Mail::Message>.

=head1 DESCRIPTION

This class is the adapter for C<MIME::Lite>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Compose appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
