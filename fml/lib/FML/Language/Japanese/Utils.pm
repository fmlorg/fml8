#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.9 2002/05/11 09:45:48 fukachan Exp $
#

package FML::Language::Japanese::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;

=head1 NAME

FML::Language::Japanese::Utils - functions to handle Japanese srings

=head1 SYNOPSIS

   use FML::Language::Japanese::Utils qw(is_iso2022jp_string);
   if ( is_iso2022jp_string($string) ) { do_something_if_Japanese;}

=head1 DESCRIPTION

Utilities for Japanse string

=head1 METHODS

=head2 <is_iso2022jp_string($string)>

check whether $string looks Japanese.
return 1 if it looks so.

=cut

require Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(is_iso2022jp_string);


# Descriptions: $buf looks like Japanese or not ?
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_iso2022jp_string
{
    my ($buf) = @_;
    return (not _look_not_iso2022jp_string($buf));
}


# Descriptions: $buf looks like Japanese or not ?
#               based on fml-support: 07020, 07029
#                  Koji Sudo <koji@cherry.or.jp>
#                  Takahiro Kambe <taca@sky.yamashina.kyoto.jp>
#               check the given buffer has unusual Japanese (not ISO-2022-JP)
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _look_not_iso2022jp_string
{
    my ($buf) = @_;

    # trivial check;
    return 0 unless defined $buf;
    return 0 unless $buf;

    # check 8 bit on
    if ($buf =~ /[\x80-\xFF]/){
        return 1;
    }

    # check SI/SO
    if ($buf =~ /[\016\017]/) {
        return 1;
    }

    # HANKAKU KANA
    if ($buf =~ /\033\(I/) {
        return 1;
    }

    # MSB flag or other control sequences
    if ($buf =~ /[\001-\007\013\015\020-\032\034-\037\177-\377]/) {
        return 1;
    }

    0; # O.K.
}


=head2 C<compare_euc_string($buf, $pat)>

search $pat in EUC string $buf.
return 1 if found or 0 if not.

=cut


# Descriptions: compare Japanese EUC strings
#    Arguments: OBJ($self) STR($a) STR($pat)
# Side Effects: none
#      History: fml 4.0: EUCCompare($buf, $pat)
#               where $pat should be $& (matched pattern)
# Return Value: NUM(1 or 0)
sub compare_euc_string
{
    my ($self, $a, $pat) = @_;

    # XXX validate $a and $pat ???
    #     e.g. defined($a) ?

    # (Refeence: jcode 2.12)
    # $re_euc_c    = '[\241-\376][\241-\376]';
    # $re_euc_kana = '\216[\241-\337]';
    # $re_euc_0212 = '\217[\241-\376][\241-\376]';
    my ($re_euc_c, $re_euc_kana, $re_euc_0212);
    $re_euc_c    = '[\241-\376][\241-\376]';
    $re_euc_kana = '\216[\241-\337]';
    $re_euc_0212 = '\217[\241-\376][\241-\376]';

    # always true if given buffer is not EUC.
    if ($a !~ /($re_euc_c|$re_euc_kana|$re_euc_0212)/) {
	&Log("EUCCompare: do nothing for non EUC strings");# if $debug;
	return 1;
    }

    # extract EUC code (e.g. .*EUC_PATTERN.*)
    # but how to do for "EUC ASCII EUC" case ???
    my ($pa, $loc, $i);
    do {
	if ($a =~ /(($re_euc_c|$re_euc_kana|$re_euc_0212)+)/) {
	    $pa  = $1;
	    $loc = index($pa, $pat);
	}

	print STDERR "buf = <$a> pa=<$pa> pat=<$pat> loc=$loc\n" if $debug;

	return 1 if ($loc % 2) == 0;

	$a = substr($a, index($a, $pa) + length($pa) );
    } while ($i++ < 16);

    0;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Language::Japanese::Utils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
