#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#
# $FML: Date.pm,v 1.10 2001/11/03 08:19:49 fukachan Exp $
#

package FML::Date;

use Mail::Message::Date;
@ISA = qw(Mail::Message::Date);

package FML::Date;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Date - date

=head1 SYNOPSIS

See C<Mail::Message::Date>.

=head1 DESCRIPTION

All requests are forwarded to C<Mail::Message::Date>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Date appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
