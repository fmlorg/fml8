#!/usr/bin/env perl
#
# $FML: check.pl,v 1.1 2001/09/23 09:17:18 fukachan Exp $
#

use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);
use FileHandle;
use Mail::Message;

for my $f (@ARGV) {
    my $fh      = new FileHandle $f;
    my $message = Mail::Message->parse( { fd => $fh } );

    if (defined $message) {
	use File::Basename;
	my $fn = basename($f);

	printf STDERR "%-20s header = ", $fn;

	use FML::Filter::HeaderCheck;
	my $obj = new FML::Filter::HeaderCheck;

	$obj->header_check($message);
	if ($obj->error()) {
	    my $x = $obj->error();
	    $x =~ s/\s*at .*$//;
	    print STDERR "error: $x";
	}
	else {
	    print STDERR "ok\n";
	}


	printf STDERR "%-20s   body = ", $fn;

	use FML::Filter::BodyCheck;
	my $obj = new FML::Filter::BodyCheck;

	$obj->body_check($message);
	if ($obj->error()) {
	    my $x = $obj->error();
	    $x =~ s/\s*at .*$//;
	    print STDERR "error: $x";
	}
	else {
	    print STDERR "ok\n";
	}

	print STDERR "\n";
    }
}

exit 0;


sub _print
{
    my (@args) = @_;
    printf STDERR "%30s %s %s %s\n", @args;
}
