#-*- perl -*-
#
#  Copyright (C) 2000 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::String;

use Carp;

require Exporter;
@ISA       = qw(Exporter); 
@EXPORT_OK = qw(STR2JIS STR2EUC);

use strict;

sub AUTOLOAD
{
    print STDERR "bad AUTOLOAD()\n";
}

sub STR2EUC
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'euc');
}


sub STR2JIS
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'jis');
}


sub STR2SJIS
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'sjis');
}


=head1 NAME

FML::String -- utilties to manipulate strings

=head1 SYNOPSIS

=head1 METHOD

=item STR2JIS(string)

convert CHARSET of the given string to JIS.

=item STR2EUC(string)

convert CHARSET of the given string to EUC.

=item STR2SJIS(string)

convert CHARSET of the given string to SJIS.


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::String.pm appeared in fml5.

=cut

1;
