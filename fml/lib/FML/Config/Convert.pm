#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Convert.pm,v 1.1.1.1 2001/12/09 12:48:15 fukachan Exp $
#


package FML::Config::Convert;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Config::Convert -- 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


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


sub _replace
{
    my ($buf, $config) = @_;

    if (defined $config->{ ml_name }) {
	$buf =~ s/__ml_name__/$config->{ ml_name }/g;
    }
	
    if (defined $config->{ ml_domain }) {
	$buf =~ s/__ml_domain__/$config->{ ml_domain }/g;
    }

    if (defined $config->{ libexec_dir }) {
	$buf =~ s/__libexec_dir__/$config->{ libexec_dir }/g;
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
