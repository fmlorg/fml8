#!/usr/local/bin/perl
#use Jcode::Constants 

my $n = 0; my $str = "";
for my $c2 (0340..0374){
    for my $c1 (0200..0374){
	if ($n++ % 32 == 31){ # LF for every 32 zenkaku chars
	    print $str, "\n"; $str = "";
	}else{
	    $str .= chr($c2) . chr($c1);
	}

    }
}
warn $n;
