#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Subject.pm,v 1.3 2001/11/24 08:47:46 fukachan Exp $
#


###                                                   ###
### CAUTION: THE CHARSET OF THIS FILE IS "EUC-JAPAN". ###
###                                                   ###


package FML::Language::Japanese::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

use Mail::Message::Language::Japanese::Subject;
@ISA = qw(Mail::Message::Language::Japanese::Subject);

=head1 NAME

FML::Language::Japanese::Subject - Japanese specific handling of a subject

=head1 SYNOPSIS

    use FML::Language::Japanese::Subject;
    $is_reply = FML::Language::Japanese::Subject::is_reply($subject);

=head1 DESCRIPTION

Mail::Message::Language::Japanese::Subject has actual codes.
See L<Mail::Message::Language::Japanese::Subject> for more details.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Language::Japanese::Subject appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
