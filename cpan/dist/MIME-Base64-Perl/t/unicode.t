BEGIN {
	unless ($] >= 5.006) {
		print "1..0\n";
		exit(0);
	}
}

print "1..2\n";

require MIME::Base64::Perl;

eval {
    my $tmp = MIME::Base64::Perl::encode_base64(v300);
    print "# enc: $tmp\n";
};
print "# $@" if $@;
print "not " unless $@;
print "ok 1\n";

require MIME::QuotedPrint::Perl;

eval {
    my $tmp = MIME::QuotedPrint::Perl::encode_qp(v300);
    print "# enc: $tmp\n";
};
print "# $@" if $@;
print "not " unless $@;
print "ok 2\n";
