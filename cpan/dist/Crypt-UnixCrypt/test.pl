BEGIN { 
  $| = 1;
  print "1..22\n"; # Adjust to the number of tests implemented
  $Crypt::UnixCrypt::OVERRIDE_BUILTIN = 1; # do use our own crypt()
}
END {print "not ok 1\n" unless $loaded;}
use Crypt::UnixCrypt;
$loaded = 1;
print "ok 1\n";

# Thanks to Tom Phoenix, rootbeer@redcat.com, for these test cases
my %passwords = qw{
    baVNbYZEf7LDE       fred
    fr7q2GbYzYnUY       fred
    frDRU8pKCvhno       barney
    bavBxSScsQx4c       barney
    frnyAy5uqxI72       Fred
    frOnUcrBFxA0.       FRED
    loS9ozwAlfL0.       thisstringistoolong
    on0GQrELiWzlk       onlythefirst8charsareused
    puTVTxaAZz6sw       I've%got_punc!tu~a$tion*marks?
    moaj75vMGk/4s       !@$%^&*()~
};

my $start = 2;
for (sort keys %passwords) {
    my $pass = $passwords{$_};
    my $crypted = crypt $pass, $_;
    print "# Expected $_ got $crypted ($pass)\nnot "
        if $_ ne $crypted;
    print "ok ", $start++, "\n";
    # Try a false salt
    my $original = $_;
    s/^(..)(.*)$/ $1 . reverse $2 /e;
    $crypted = crypt $pass, $_;
    print "# crypt is returning the salt!\nnot "
        if $_ eq $crypted;
    print "ok ", $start++, "\n";
}

print "not " unless
    crypt("fr","someverylongstring") eq
    crypt("fr","somevery");
print "ok ", $start++, "\n";

