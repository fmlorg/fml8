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
use strict;
use Carp;

=head1 NAME

FML::String -- utilities to manipulate strings

=head1 SYNOPSIS

    use FML::String qw(STR2JIS);
    $euc_str = STR2JIS($str);

=head1 METHOD

=head2 C<STR2JIS(string)>

convert CHARSET of the given string to JIS.

=head2 C<STR2EUC(string)>

convert CHARSET of the given string to EUC.

=head2 C<STR2SJIS(string)>

convert CHARSET of the given string to SJIS.

=cut


require Exporter;
@ISA       = qw(Exporter); 
@EXPORT_OK = qw(STR2JIS STR2EUC STR2SJIS);

use Jcode;


sub STR2EUC
{
    my ($str) = @_;
    &Jcode::convert(\$str, 'euc');
    $str;
}


sub STR2JIS
{
    my ($str) = @_;
    &Jcode::convert(\$str, 'jis');
    $str;
}


sub STR2SJIS
{
    my ($str) = @_;
    &Jcode::convert(\$str, 'sjis');
    $str;
}


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
