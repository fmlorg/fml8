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

    #       .fml8_default           fml8 �Υǥե���Ȥ�Ʊ�������ˤ����
    #       .not_yet_implemented    �ޤ�����������Ƥʤ�
    #       .unavailable            �б������Τ��ʤ�������ͽ���ʤ�
    #       .ignore                 �����������㤦�Τǡ�̵��̣
    if ($x eq '.fml8_default') {
	return 'OK��fml8 �Υǥե���Ȥ�Ʊ��';
    }
    elsif ($x =~ /\.auto/) {
	$x =~ s/\.auto/fml8 �Ǥ������ĥ��(��ư����)/;
	return $x;
    }
    elsif ($x =~ /\.convert/) {
	$x =~ s/\.convert/fml8 �η������Ѵ����ƻȤ�/;
	return $x;
    }
    elsif ($x =~ /\.use/) {
	$x =~ s/\.use/���Τޤޡ��Ĥ���/;
	return $x;
    }
    elsif ($x eq '.ignore') {
	return '�б������Τ��ʤ�';
    }
    elsif ($x eq '.unavailable') {
	return '����ͽ��ʤ�';
    }
    elsif ($x eq '.not_yet_configurable') {
	return '�ޤ������ѹ��Ǥ��ʤ�';
    }
    elsif ($x eq '.not_yet_implemented') {
	return '̤����';
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
