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
     "漢字、カタカナ、ひらがな" =>
     "=?ISO-2022-JP?B?GyRCNEE7eiEiJSslPyUrJUohIiRSJGkkLCRKGyhC?=",
     "foo bar" => 
     "foo bar",
     "漢字、カタカナ、ひらがなの混じったSubject Header." =>
     "=?ISO-2022-JP?B?GyRCNEE7eiEiJSslPyUrJUohIiRSJGkkLCRKJE46LiQ4JEMkPxsoQlN1?=\n =?ISO-2022-JP?B?YmplY3Q=?= Header.",
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
 
    my $decoded_h = jcode($decoded)->h2z->euc;
    my $t_encoded_h = jcode($decoded_h)->mime_encode;

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
	#print $encoded_i, "\n";
    }else{
	$ok = "not ok";
	print <<"EOF";
Di:>$decoded<
Do:>$t_decoded<
EOF
}
    profile(sprintf("MIME decode: %s -> %s %s %d\n", 
		    $decoded, $encoded_i, $ok, ++$n ));

    if ($t_encoded eq $encoded){
	$ok = "ok";
    }else{
	$ok = "not ok";
	print <<"EOF";
Ei>$encoded<
Eo>$t_encoded<
EOF
    }
    profile(sprintf("MIME encode: %s -> %s %s %d\n", 
		    $decoded, $encoded, $ok, ++$n ));

    if ($t_encoded_h eq $encoded){
	$ok = "ok";
    }else{
	$ok = "not ok";
	print <<"EOF";
E>$decoded_h<
E>$t_encoded_h<
EOF
    }
    profile(sprintf("MIME encode: %s -> %s %s %d\n", 
		    $decoded_h, $t_encoded_h, $ok, ++$n ));

}


print 1, "..", $NTESTS, "\n";
for my $TEST (@TESTS){
    print $TEST; 
}





