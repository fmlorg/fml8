#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#


package Standalone;

use strict;
use Carp;

=head1 NAME

Standalone - minimal parser for libexec/* programs

=head1 SYNOPSIS

   use Standalone;
   my $main_cf = Standalone::load_cf($main_cf_file, $params);

where $param is optional and the format of it is

  $params = "key1=value1 key2=value2";

=head1 DESCRIPTION

C<load_cf()> reads the C<key = value> style configuration file and
return the hash. The file format is like this:

   key1 = value1

   key2 = value2
          value3

key2 is equivalent to 

   key2 = value2 value3

A set of space separeted elements is an array of values.


=head1 METHODS

=head2 C<load_cf()>

load "key = value" style configuration file and build a hash.
return the reference to the hash.

=cut


# Descriptions: load "key = value" style configuration.
#               It is available to use the following style.
#                    key = value1 value2
#                          value3
#               XXX This file is non-Object Oriented style but 
#               XXX this is minimum module used in standalone program.
#    Arguments: $file $params
#               $params is 'key1=value1 key2=value2' syntax.
# Side Effects: $config (hash reference) is allocated on memory here.
# Return Value: hash reference to configuration parameters
sub load_cf
{
    my ($file, $params) = @_;
    my $config = $params ? _parse_params($params) : {};

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my $curkey;
	while (<$fh>) {
	    next if /^\#/;
	    chop;

	    if (/^([A-Za-z]\w+)\s+=\s*(.*)/) {
		my ($key, $value) = ($1, $2);
		$curkey           = $key;
		$config->{$key}   = $value;
	    }
	    if (/^\s+(.*)/) {
		$config->{ $curkey }  .= " ". $1;
	    }
	}
	$fh->close;
    }
    else {
	croak("Error: cannot open $file");
    }

    _expand_variables( $config );
    return $config;
}


# Descriptions: expand $var to the value of $var.
#    Arguments: $ref_to_config
# Side Effects: rewrite the given $config 
# Return Value: none
sub _expand_variables
{
    my ($config) = @_;
    my @order  = keys %$config;

    # check whether the variable definition is recursive.
    # For example, definition "var_a = $var_a/b/c" causes a loop.
    for my $x ( @order ) {
	if ($config->{ $x } =~ /\$$x/) {
	    croak("loop1: definition of $x is recursive\n");
	}
    }

    # main expansion loop
    my $org = '';
    my $max = 0;
  KEY:
    for my $x ( @order ) {
	next KEY if $config->{ $x } !~ /\$/o;

	# we need a loop to expand nested variables, for example, 
	# a = $x/y and b = $a/c/0
	# 
	$max = 0;
      EXPANSION_LOOP:
	while ($max++ < 16) {
	    $org = $config->{ $x };

	    $config->{ $x } =~ s/\$([a-z_]+)/$config->{$1}/g;

	    last EXPANSION_LOOP if $config->{ $x } !~ /\$/o;
	    last EXPANSION_LOOP if $org eq $config->{ $x };

	    if ($config->{ $x } =~ /\$$x/) {
		croak("loop2: definition of $x is recursive\n");
	    }
        }

	if ($max >= 16) {
	    croak("variable expansion of $x causes infinite loop\n");
	} 
    }
}


sub _parse_params
{
    my ($params) = @_;
    my %config = ();

    for my $x (split(/\s+/, $params)) {
	my ($key, $value) = split(/=/, $x);
	$config{ $key } = $value;
    }

    \%config;
}




=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Standalone appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
