#-*- perl -*-
#
# $FML$
#
package Test;
use strict;
use Carp;

sub dump_content
{
    my ($obj) = @_;

    if (defined $obj) {
	if (defined $obj->open()) {
	    my $buf = '';

	    while ($buf = $obj->getline()) {
		my $y = $obj->eof ? "y" : "n";
		print "<", $obj->getpos, "(eof=$y)> ";
		print $buf, "\n";
	    }
	    $obj->close;
	}
	else {
	    croak("cannot open()");
	}
    }
    else {
	croak("cannot make object");
    }
}


sub rollback
{
    my ($obj) = @_;
    my $done  = 0;

    if (defined $obj) {
	if (defined $obj->open()) {
	    while ($_ = $obj->getline()) {
		my $y = $obj->eof ? "y" : "n";
		print "<", $obj->getpos, "(eof=$y)> ";
		print $_, "\n";

		unless ($done) {
		    if ($obj->getpos == 4) {
			print STDERR "   skip to 6 \n";
			$obj->setpos(6);
			next;
		    }

		    if ($obj->getpos == 7) {
			print STDERR "   back to 3 \n";
			$obj->setpos(3);
			$done = 1;
		    }
		}
	    }
	    $obj->close;
	}
	else {
	    croak("cannot open()");
	}
    }
    else {
	croak("cannot make object");
    }
}


1;
