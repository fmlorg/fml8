#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Convert.pm,v 1.18 2004/01/21 03:51:17 fukachan Exp $
#


package FML::Config::Convert;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Config::Convert -- tiny non object-style variable expansion tool.

=head1 SYNOPSIS

    my $in  = new FileHandle $src;
    my $out = new FileHandle "> $dst.$$";

    if (defined $in && defined $out) {
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
Specify HASH_REF $config as source of { key => value }.

=head2 convert_file($src, $dst, $config)

convert() wrapper for files.

=cut


# Descriptions: conversion filter for file handles
#               with configuration replacement.
#    Arguments: HANDLE($in) HANDLE($out) HASH_REF($config)
# Side Effects: print out to handle $out
# Return Value: none
sub convert
{
   my ($in, $out, $config) = @_;

   if (defined $in && defined $out && defined $config) {
       my $buf;
       while ($buf = <$in>) {
	   $buf = _replace($buf, $config) if $buf =~ /__/o;
	   print $out $buf;
       }
   }
   else {
       croak("convert: invalid in/out channel");
   }
}


# Descriptions: conversion filter for files.
#    Arguments: STR($src) STR($dst) HASH_REF($config)
# Side Effects: print out to file $out
# Return Value: none
sub convert_file
{
   my ($src, $dst, $config) = @_;
   my $dst_tmp = $dst .".". $$;

   use FileHandle;
   my $in  = new FileHandle $src;
   my $out = new FileHandle "> " . $dst_tmp;

    if (defined $in && defined $out) {
	use File::stat;
	my $stat = stat($src);
	my $mode = $stat->mode;

	eval q{ convert($in, $out, $config);};
	croak($@) if $@;

	$out->close();
	$in->close();

	chmod $mode, $dst_tmp;
	rename($dst_tmp, $dst) || croak("fail to rename $dst");
    }
    else {
	croak("fail to open $src") unless defined $in;
	croak("fail to open $dst") unless defined $out;
    }
}


# Descriptions: replace __variable__ with real value in $config.
#    Arguments: STR($buf) HASH_REF($config)
# Side Effects: buffer replacement
# Return Value: STR($buf) HASH_REF($config)
sub _replace
{
    my ($buf, $config) = @_;

    # XXX special condition: replace one line if hints is given
    if (defined $config->{ __hints_for_fml_process__ }) {
	if ($buf =~ /__hints_for_fml_process__/) {
	    $buf = $config->{ __hints_for_fml_process__ };
	    return $buf;
	}
    }

    if (defined $config->{ fml_owner }) {
	$buf =~ s/__fml_owner__/$config->{ fml_owner }/g;
    }

    if (defined $config->{ ml_name }) {
	$buf =~ s/__ml_name__/$config->{ ml_name }/g;
    }

    if (defined $config->{ _ml_name_admin }) {
	$buf =~ s/__ml_name_admin__/$config->{ _ml_name_admin }/g;
    }

    if (defined $config->{ _ml_name_ctl }) {
	$buf =~ s/__ml_name_ctl__/$config->{ _ml_name_ctl }/g;
    }

    if (defined $config->{ _ml_name_error }) {
	$buf =~ s/__ml_name_error__/$config->{ _ml_name_error }/g;
    }

    if (defined $config->{ _ml_name_post }) {
	$buf =~ s/__ml_name_post__/$config->{ _ml_name_post }/g;
    }

    if (defined $config->{ _ml_name_request }) {
	$buf =~ s/__ml_name_request__/$config->{ _ml_name_request }/g;
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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Config::Convert first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
