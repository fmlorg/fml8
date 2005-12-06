#!/usr/bin/env perl
#
# $FML: list_up_command_lock.pl,v 1.1 2003/05/31 04:42:31 fukachan Exp $
#

for my $x (<AdminCommand/*pm UserCommand/*pm>) {
    _check($x);
}

exit 0;


sub _check
{
    my ($file) = @_;
    my $need_lock = 0;
    my $channel   = '';
    my $isa = '';

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
	while (<$fh>) { 
	    chomp;

	    if (/\@ISA\s*=\s*qw\(([A-Za-z:]+)/) {
		$isa = $1;
		$isa =~ s/FML::Command:://;
	    }

	    if (/sub need_lock.*1/) {
		$need_lock = 1;
	    }

	    if (/sub lock_channel.*return\s*[\'\"](\S+)[\'\"]/) {
		$channel = $1;
	    }

	}

	$fh->close();
    }

    if ($isa) {
	printf "%-30s  %3s   %s\n", $file, "==>", $isa;
    }
    else {
	printf 
	    "%-30s  %3s   %s\n", 
	    $file, 
	    ($need_lock ? "yes" : "no"), 
	    $channel;
    }
}
