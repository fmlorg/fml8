#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Parse.pm,v 1.1 2001/05/06 08:21:05 fukachan Exp $
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


=head1 NAME

Mail::Message::Parse - parse a mail message

=head1 SYNOPSIS

    use Mail::Message::Parse;
    my $fh = new Mail::Message::Parse $args;

where C<$args> is same as one of C<Mail::Message>'s C<parse()>.

=head1 DESCRIPTION

just a wrapper for C<Mail::Message> parser function.

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
