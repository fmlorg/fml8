#!/usr/bin/env perl
#
# $FML: bodycheck.pl,v 1.1.1.1 2001/08/19 14:51:46 fukachan Exp $
#

use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);
use FileHandle;
use Mail::Message;
use FML::Filter::BodyCheck;

for my $f (@ARGV) {
    my $checker = new FML::Filter::BodyCheck;
    my $fh      = new FileHandle $f;
    my $message = Mail::Message->parse( { fd => $fh } );

    if (defined $message) {
	my $m = $message->get_first_plaintext_message();

	_print(" - analyze $f");

	_print("num of paragraph(s) =", $m->num_paragraph);

	_print("need_one_line_check =",
	       ($checker->need_one_line_check($m) ? "yes" : "no"));

	_print("first part =",
	       ($m->is_empty($m) ? "empty" : $m->size." bytes"));
		
	print STDERR "\n";
    }
}

exit 0;


sub _print
{
    my (@args) = @_;
    printf STDERR "%30s %s %s %s\n", @args;
}
