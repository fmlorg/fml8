#!/usr/bin/env perl
#
# $FML: configtest.pl,v 1.1 2004/12/09 11:35:58 fukachan Exp $
#

use strict;
use Carp;
use lib qw(fml/lib cpan/lib gnu/lib img/lib);
use vars qw(@failed_queue %failed_queue $base_dir);

my $base_dir = shift || '/var/spool/ml';

for my $f (<$base_dir/*/config.ph>) {
    if (-f $f) {
	print STDERR "// check $f\n";
	check($f);
    }
}

for my $f (<$base_dir/*/.fml4rc/config.ph>) {
    if (-f $f) {
	print STDERR "// check $f\n";
	check($f);
    }
}

if (@failed_queue) {
    print "\n\n--- failure summary ---\n\n";
    for my $q (@failed_queue) {
	$failed_queue{ $q } = $q;
    }

    for my $q (sort keys %failed_queue) {
	print $q;
    }
    print "\n";
}
else {
    print "Congraturations! ALL OK\n";
}

exit 0;


# Descriptions: check translation results.
#    Arguments: STR($old_config_ph)
# Side Effects: update @failed_queue.
# Return Value: none
sub check
{
    my ($old_config_ph) = @_;

    use FML::Merge::FML4::config_ph;
    my $config_ph = new FML::Merge::FML4::config_ph;

    my $default_config_ph = "./fml/etc/compat/fml4/default_config.ph";
    $config_ph->set_default_config_ph($default_config_ph);

    my $diff = $config_ph->diff($old_config_ph);

    # print out;
    my ($k, $v, $x, $y);
    for my $k (sort _sort_order keys %$diff) {
        $v = $diff->{ $k };
        $y = $v;
        $y =~ s/\n/\n# /gm;

	print "\n";
        print "# Q: $k => $y\n";
	my $query = "# Q: $k => $y\n";

        if ($x = $config_ph->translate($diff, $k, $v)) {
	    print "# A: OK TRANSLATION FOUND\n";
            print $x ,"\n";
        }
	else {
	    if ($k =~ /_HOOK$/) {
		print "# A: OK (IGNORED SINCE HOOK CAN NOT TRANSLATED)\n";
	    }
	    else {
		print "# A: FAILED (NOT TRANSLATED)\n";
	    }
	    push(@failed_queue, $query);
	}
    }
}


# Descriptions: tune sort order: postpone PROC__* and *_HOOK variables.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub _sort_order
{
    my $x = $a;
    my $y = $b;

    $x = "zz_$x"  if $x =~ /^PROC__/o;
    $y = "zz_$y"  if $y =~ /^PROC__/o;
    $x = "zzz_$x" if $x =~ /HOOK/o;
    $y = "zzz_$y" if $y =~ /HOOK/o;

    $x cmp $y;
}
