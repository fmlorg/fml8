#!/usr/bin/env perl
#
# $FML$
#

print "<TABLE BORDER=4>\n";
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
	    printf "\t<TR>\n\t<TD>%s <TD>%s\n", "$var_name ($var_value)", $x;
	}
	else {
	    printf "\t<TR>\n\t<TD>%s <TD>%s\n", $var_name, $x;
	}
    }
}

print "</TABLE>\n";

exit 0;


sub _P
{
    my ($x)= @_;
    $x =~ s/\s*$//;
    $x =~ s/^\s*//;

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
    elsif ($x =~ /\.use/) {
	$x =~ s/\.use/このまま、つかう/;
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
	    use Carp;
	    croak($x);
	}
	else {
	    return $x;
	}
    }
}
