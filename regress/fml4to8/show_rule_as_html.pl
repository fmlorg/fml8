#!/usr/bin/env perl
#
# $FML: show_rule_as_html.pl,v 1.2 2004/12/09 11:35:12 fukachan Exp $
#

my $raw_mode = $ENV{ 'RAW_MODE' } ? 1 : 0;

print "<TABLE BORDER=4>\n" unless $raw_mode;
while (<>) {
    chomp;

    s/\s*$//;

    if (/^\.if\s*([A-Z]\S+)\s*.=\s*(.*)/) {
	$var_name  = $1;
	$var_value = $2;
	$var_value = /\!=/o ? "!= $var_value" : $var_value;

	$saved_var_name  = $var_name;
	$saved_var_value = $var_value;
    }
    elsif (/^\.if\s*([A-Z]\S+)/) {
	undef $condition;
	$var_name  = $1;
	$var_value = undef;

	$saved_var_name  = $var_name;
	$saved_var_value = $var_value;
    }

    if (/^\t\.if\s*([A-Z]\S+)\s*==\s*(.*)/) {
	$var_name  = "$saved_var_name && $1";
	$var_value = "$saved_var_value && $2";
    }
    elsif (/^\t(.*)/) {
	my $x = _P($1);
	if (defined $var_value) {
	    if ($raw_mode) {
		printf "%-40s  %s\n", "$var_name ($var_value)", $x;
	    }
	    else {
		printf "\t<TR>\n\t<TD>%s <TD>%s\n", 
		"$var_name ($var_value)", $x;
	    }
	}
	else {
	    if ($raw_mode) {
		printf "%-40s  %s\n", $var_name, $x;
	    }
	    else {
		printf "\t<TR>\n\t<TD>%s <TD>%s\n", $var_name, $x;
	    }
	}
    }
}

print "</TABLE>\n" unless $raw_mode;

exit 0;


sub _P
{
    my ($x) = @_;
    $x =~ s/\s*$//;
    $x =~ s/^\s*//;

    if ($raw_mode) { return $x;}

    #       .fml8_default           fml8 のデフォルトと同じ、気にするな
    #       .not_yet_implemented    まだ、実装されてない
    #       .unavailable            対応するものがない、実装予定もない
    #       .ignore                 実装方式が違うので、無意味
    if ($x eq '.fml8_default') {
	return 'OK。fml8 のデフォルトと同じ';
    }
    elsif ($x =~ /\.auto/) {
	$x =~ s/\.auto/fml8 でよろしく頑張る(自動設定)/;
	return $x;
    }
    elsif ($x =~ /\.convert/) {
	$x =~ s/\.convert/fml8 の形式に変換して使う/;
	return $x;
    }
    elsif ($x =~ /\.use_fml4_value/) {
	$x =~ s/\.use_fml4_value/このまま fml4  の値を使う/;
	return $x;
    }
    elsif ($x =~ /\.use_fml8_value/) {
	$x =~ s/\.use_fml8_value/対応する fml8 の値を使う/;
	return $x;
    }
    elsif ($x eq '.ignore') {
	return '対応するものがない';
    }
    elsif ($x eq '.unavailable') {
	return '実装予定なし';
    }
    elsif ($x eq '.not_yet_configurable') {
	return 'まだ設定変更できない';
    }
    elsif ($x eq '.not_yet_implemented') {
	return '未実装';
    }
    else {
	if ($x =~ /^\s*\./) {
		print STDERR "INPUT{$x}\n";
	    use Carp;
	    croak($x);
	}
	else {
	    return $x;
	}
    }
}
