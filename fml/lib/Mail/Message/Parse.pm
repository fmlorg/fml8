#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: __template.pm,v 1.5 2001/04/03 09:45:39 fukachan Exp $
#


package Mail::Message::Parse;

use strict;
use vars qw(@ISA);
use Carp;

use Mail::Message;
@ISA = qw(Mail::Message);

sub new
{
    my ($self, $args) = @_;
    return Mail::Message->parse($args);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::Message::Parse appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
