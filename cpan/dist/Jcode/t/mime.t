#!/usr/bin/perl -w

use strict;
use diagnostics;
$| = 1; # autoflush
use vars qw(@ARGV $ARGV);
use lib ".";
use Jcode;

eval { require MIME::Base64 };
if ($@){
    print "1..0\n";
    exit 0;
}

my ($NTESTS, @TESTS) ;

sub profile {
    no strict 'vars';
    my $profile = shift;
    print $profile if $ARGV[0];
    $profile =~ m/(not ok|ok) (\d+)$/o;
    $profile = "$1 $2\n";
    $NTESTS = $2;
    push @TESTS, $profile;
}


my $n = 0;
my $file;

my %mime = 
    (
     "¥Æ¥¹¥Ètest¤Ç¤¹" =>
     "=?ISO-2022-JP?B?GyRCJUYlOSVIGyhCdGVzdBskQiRHJDkbKEI=?=",
     "foo bar" => 
     "foo bar",
     "£°£±£²£³£´£µ£¶£·£¸£¹£°£±£²£³£´£µ£¶£·£¸£¹£°£±£²£³£´£µ£¶£·£¸£¹£°£±£²£³£´£µ£¶£·£¸£¹£°£±£²£³£´£µ£¶£·£¸£¹" =>
     "=?ISO-2022-JP?B?GyRCIzAjMSMyIzMjNCM1IzYjNyM4IzkjMCMxIzIjMyM0IzUjNiM3GyhC?=\n =?ISO-2022-JP?B?GyRCIzgjOSMwIzEjMiMzIzQjNSM2IzcjOCM5IzAjMSMyIzMjNCM1GyhC?=\n =?ISO-2022-JP?B?GyRCIzYjNyM4IzkjMCMxIzIjMyM0IzUjNiM3IzgjORsoQg==?=",
     );

for my $k (keys %mime){
    $mime{"$k\n"} = $mime{$k} . "\n";
}

for my $decoded (sort keys %mime){
    my ($ok, $out);
    my $encoded = $mime{$decoded};
    my $encoded_i = $encoded; $encoded_i =~ s/^(=\?ISO-2022-JP\?B\?)/lc($1)/eo;
    my $t_encoded = jcode($decoded)->mime_encode;
    my $t_decoded = jcode($encoded)->mime_decode;
    my $t_decoded_i = jcode($encoded_i)->mime_decode;
 
   if ($t_decoded eq $decoded){
	$ok = "ok";
    }else{
	$ok = "not ok";
	print <<"EOF";
D:>$decoded<
D:>$t_decoded<
EOF
}

    profile(sprintf("MIME decode: %s -> %s %s %d\n", 
		    $decoded, $encoded, $ok, ++$n ));

    if ($t_decoded_i eq $decoded){
	$ok = "ok";
	print $encoded_i, "\n";
    }else{
	$ok = "not ok";
	print <<"EOF";
D:>$decoded<
D:>$t_decoded<
EOF
}
    profile(sprintf("MIME decode: %s -> %s %s %d\n", 
		    $decoded, $encoded_i, $ok, ++$n ));

    if ($t_encoded eq $encoded){
	$ok = "ok";
    }else{
	$ok = "not ok";
	print <<"EOF";
E>$encoded<
E>$t_encoded<
EOF
    }
    profile(sprintf("MIME encode: %s -> %s %s %d\n", 
		    $decoded, $encoded, $ok, ++$n ));
}


print 1, "..", $NTESTS, "\n";
for my $TEST (@TESTS){
    print $TEST; 
}





