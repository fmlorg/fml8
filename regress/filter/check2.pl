#!/usr/bin/env perl
#
# $FML: check.pl,v 1.3 2001/10/14 22:22:40 fukachan Exp $
#

use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);
use FileHandle;
use Mail::Message;

for my $f (@ARGV) {
    my $fh      = new FileHandle $f;
    my $message = Mail::Message->parse( { fd => $fh } );

    if (defined $message) {
	my $curproc = {};

	use File::Basename;
	my $fn = basename($f);

	use FML::Filter;
	my $filter = new FML::Filter;
	$curproc->{ 'incoming_message' } = $message;

	use FML::Config;
	my $config = new FML::Config;
	$curproc->{ 'config' } = $config;
	$config->{ use_header_filter } = 'yes';
	$config->{ use_body_filter }   = 'yes';

	$filter->check( $curproc );
	my $error = $filter->error();
	_print($fn, ($error ? "error" : "ok"), $error);
    }
}

exit 0;


sub _print
{
    my (@args) = @_;
    printf STDERR "%-25s %-5s   %s\n", @args;
}


1;
