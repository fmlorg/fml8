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
use Dialect::Japanese::Utils qw(is_iso2022jp_string);

require Exporter;
@ISA       = qw(Dialect::Japanese::Utils Exporter);
@EXPORT_OK = @Dialect::Japanese::Utils::EXPORT_OK;

=head1 NAME

Dialect::ISO2022JP.pm - adapter for Dialect::Japanese

=head1 SYNOPSIS

    use Dialect::ISO2022JP qw(is_iso2022jp_string);
    if ( is_iso2022jp_string($string) ) { do_something_if_Japanese;}

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
