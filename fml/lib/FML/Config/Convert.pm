#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Convert.pm,v 1.4 2001/12/22 14:23:40 fukachan Exp $
#


package FML::Config::Convert;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Config::Convert -- variable expansion for __variable__

=head1 SYNOPSIS

    my $in  = new FileHandle $src;
    my $out = new FileHandle "> $dst.$$";

    if (defined $in && defined $out) {
        chmod 0644, "$dst.$$";

        &FML::Config::Convert::convert($in, $out, $config);

        $out->close();
        $in->close();

        rename("$dst.$$", $dst) || croak("fail to rename $dst");
    }
    else {
        croak("fail to open $src") unless defined $in;
        croak("fail to open $dst") unless defined $out;
    }

=head1 DESCRIPTION

Installer needs variable expansion. This module provides variable
expansion for __variable__ style string.

=head1 METHODS

=head2 convert($in, $out, $config)

conversion filter. The source is given by file handle $in,
output is specified as file handle $out.
Specify HASH_REF $config as real value.

=cut


# Descriptions: conversion filter.
#    Arguments: HANDLE($in) HANDLE($out) HASH_REF($config)
# Side Effects: print out to handle $out
# Return Value: none
sub convert
{
   my ($in, $out, $config) = @_;

   if (defined $in && defined $out && defined $config) {
       while (<$in>) {
	   $_ = _replace($_, $config) if /__/;
	   print $out $_;
       }
   }
   else {
       croak("convert: invalid in/out channel");
   }
}


# Descriptions: replace __variable__ with real value in $config
#    Arguments: STR($buf) HASH_REF($config)
# Side Effects: buffer replacement
# Return Value: STR($buf)
sub _replace
{
    my ($buf, $config) = @_;

    if (defined $config->{ fml_owner }) {
	$buf =~ s/__fml_owner__/$config->{ fml_owner }/g;
    }

    if (defined $config->{ ml_name }) {
	$buf =~ s/__ml_name__/$config->{ ml_name }/g;
    }

    if (defined $config->{ ml_domain }) {
	$buf =~ s/__ml_domain__/$config->{ ml_domain }/g;
    }

    if (defined $config->{ libexec_dir }) {
	$buf =~ s/__libexec_dir__/$config->{ libexec_dir }/g;
    }

    if (defined $config->{ ml_home_dir }) {
	$buf =~ s/__ml_home_dir__/$config->{ ml_home_dir }/g;
    }

    if (defined $config->{ ml_home_prefix }) {
	$buf =~ s/__ml_home_prefix__/$config->{ ml_home_prefix }/g;
    }

    if (defined $config->{ executable_prefix }) {
	$buf =~ s/__executable_prefix__/$config->{ executable_prefix }/g;
    }

    return $buf;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Config::Convert appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
