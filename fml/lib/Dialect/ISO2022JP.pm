#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package Dialect::ISO2022JP;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

Dialect::ISO2022JP - adapter for Dialect::Japanese

=head1 SYNOPSIS

    use Dialect::ISO2022JP qw(is_iso2022jp_string);
    if ( is_iso2022jp_string($string) ) { do_something_if_Japanese;}

    use Dialect::ISO2022JP qw(STR2EUC);
    $euc_string = STR2EUC( $string );

=cut


use Dialect::Japanese::Utils qw(is_iso2022jp_string);
use Dialect::Japanese::String qw(STR2JIS STR2EUC STR2SJIS);

require Exporter;
@ISA = qw(Dialect::Japanese::Utils Dialect::Japanese::String Exporter);
push(@EXPORT_OK, @Dialect::Japanese::Utils::EXPORT_OK);
push(@EXPORT_OK, @Dialect::Japanese::String::EXPORT_OK);


=head1 METHODS

=head2 C<is_iso2022jp_string>

See L<Dialect::Japanese::Utils>

=head2 C<STR2JIS> C<STR2EUC> C<STR2SJIS>

See L<Dialect::Japanese::String>

=head1 SEE ALSO

L<Dialect::Japanese::Utils>,
L<Dialect::Japanese::String>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Dialect::ISO2022JP appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
