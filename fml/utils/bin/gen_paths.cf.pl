#!/usr/bin/env perl
#
# $FML$
#

print "#\n";
print "# \$FML\$\n";
print "#\n";
print "\n";

while (<>) {
    if (/dnl path_check/ .. /dnl path_check_end/) {
	if (/AC_PATH_PROG\(([\w\d]+),\s*([\w\d]+)\)/) {
	    printf "path_%-20s = \@%s\@\n\n", $2, $1;
	}
    }
}

exit 0;
