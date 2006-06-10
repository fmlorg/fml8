#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package TinyMTA::Config;
use strict;
use Carp;

# Descriptions: load configuration from $config_cf_file.
#    Arguments: STR($config_cf_file) OBJ($main_cf)
# Side Effects: none
# Return Value: OBJ
sub load_file
{
    my ($config_cf_file, $main_cf) = @_;

    my $opts = {};
    for my $k (keys %$main_cf) {
	my $key = sprintf("fml_%s", $k); 
	$opts->{ $key } = $main_cf->{ $k };
    }

    use FML::Config;
    my $config = new FML::Config $opts;
    $config->load_file($config_cf_file);
    return $config;
}


1;
