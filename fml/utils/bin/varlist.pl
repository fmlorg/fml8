#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: varlist.pl,v 1.2 2002/04/01 23:41:24 fukachan Exp $
#

use strict;
use Carp;
use Getopt::Long;
use lib qw(../../../../fml/lib ../../../../cpan/lib);

my %option  = ();
my %list    = ('__table_head__' => {
    varname => 'variable name',
    desc    => 'descrition',
    value   => 'default value(s)',
});
my $desc    = '';
my $varname = '';
my $value   = '';

GetOptions(\%option, qw(debug! d! sgml! html!));

&read_config_cf;
&print_varlist;

exit 0;


sub read_config_cf
{
    while (<>) {
	# reset if we encounters blank line
	if (/^\s*$/) {
	    _alloc_entry($varname, $desc, $value);
	    undef $desc;
	    undef $varname;
	    undef $value;
	}

	if (/^\#\s*Descriptions:(.*)/) {
	    $desc = $1;
	}

	if (/^([\w\d+_]+)\s*=\s*(.*)/) {
	    $varname = $1;
	    $value   = $2 . "\n";
	    $value   =~ s/^\s*//;
	}

	if ($varname && /^\s+(.*)/) {
	    $value  .= $1 . "\n";
	}
    }
}


sub _alloc_entry
{
    my ($varname, $desc, $value) = @_;

    if ($varname && $desc && $value) {
	$value =~ s/\n/\n   /g;
	$list{ $varname }->{ varname } = $varname;
	$list{ $varname }->{ desc    } = $desc;
	$list{ $varname }->{ value   } = $value;
    }
}


my ($table_begin, $table_end)             = ();
my $table_title                           = '';
my ($table_entry_begin, $table_entry_end) = ();
my ($table_thead_begin, $table_thead_end) = ();
my ($table_tbody_begin, $table_tbody_end) = ();
my ($table_block_begin, $table_block_end) = ();


sub _customize_tag
{
    if (defined $option{ html }) {
	$table_begin       = "<TABLE BORDER=4>\n";
	$table_end         = "</TABLE>\n";

	$table_entry_begin = "<TD>\n";
	$table_entry_end   = "</TD>\n";

	$table_block_begin = "<TR>\n";
	$table_block_end   = "</TR>\n";
    }
    elsif (defined $option{ sgml }) {
	$table_begin       = "<para>\n<table>\n";
	$table_end         = "</tgroup>\n</table>\n</para>\n";

	$table_title       =
	    "<title> table description </title>\n<tgroup cols=3>";

	$table_entry_begin = "<entry>\n";
	$table_entry_end   = "</entry>\n";

	$table_block_begin = "<row>\n";
	$table_block_end   = "</row>\n";

	$table_thead_begin = "<thead>\n";
	$table_thead_end   = "</thead>\n";

	$table_tbody_begin = "<tbody>\n";
	$table_tbody_end   = "</tbody>\n";
    }
}


sub print_varlist
{
    _customize_tag();

    print $table_begin;
    print $table_title;

    print $table_thead_begin;
    _print_row('__table_head__');
    print $table_thead_end;

    print $table_tbody_begin;
    for my $varname (sort keys %list) {
	next if $varname eq '__table_head__';
	_print_row($varname);
    }
    print $table_tbody_end;

    print $table_end;
}


sub _print_row
{
    my ($varname) = @_;

    print $table_block_begin;

    print $table_entry_begin;
    print $list{ $varname }->{ varname };
    print $table_entry_end;

    print $table_entry_begin;
    print $list{ $varname }->{ desc };
    print $table_entry_end;

    my $x = $list{ $varname }->{ value };

    print $table_entry_begin;
    use HTML::FromText;
    print text2html($x);
    print $table_entry_end;

    print $table_block_end;

}

1;
