#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: ISO2022JP.pm,v 1.1.1.1 2001/06/10 04:11:39 fukachan Exp $
#

package FML::NL::ISO2022JP;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::NL::ISO2022JP - adapter for FML::NL::Japanese

=head1 SYNOPSIS

    use FML::NL::ISO2022JP qw(is_iso2022jp_string);
    if ( is_iso2022jp_string($string) ) { do_something_if_Japanese;}

    use FML::NL::ISO2022JP qw(STR2EUC);
    $euc_string = STR2EUC( $string );

=cut


use FML::NL::Japanese::Utils qw(is_iso2022jp_string);
use FML::NL::Japanese::String qw(STR2JIS STR2EUC STR2SJIS);

require Exporter;
@ISA = qw(FML::NL::Japanese::Utils FML::NL::Japanese::String Exporter);
push(@EXPORT_OK, @FML::NL::Japanese::Utils::EXPORT_OK);
push(@EXPORT_OK, @FML::NL::Japanese::String::EXPORT_OK);


=head1 METHODS

=head2 C<is_iso2022jp_string>

See L<FML::NL::Japanese::Utils>

=head2 C<STR2JIS> C<STR2EUC> C<STR2SJIS>

See L<FML::NL::Japanese::String>

=head1 SEE ALSO

L<FML::NL::Japanese::Utils>,
L<FML::NL::Japanese::String>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::NL::ISO2022JP appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
