#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Parse.pm,v 1.9 2004/01/02 14:42:48 fukachan Exp $
#


package Mail::Message::Parse;

use strict;
use vars qw(@ISA);
use Carp;

use Mail::Message;
@ISA = qw(Mail::Message);


# Descriptions: fake constructor.
#               run Mail::Message->parse($args) in fact.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    return Mail::Message->parse($args);
}


=head1 NAME

Mail::Message::Parse - parse a mail message.

=head1 SYNOPSIS

    use Mail::Message::Parse;
    my $fh = new Mail::Message::Parse $args;

where C<$args> is same as one of C<Mail::Message>'s C<parse()>.

=head1 DESCRIPTION

just a wrapper for C<Mail::Message> parser function.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Parse first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
