#!/usr/bin/perl -w

use strict;
use lib ('./blib','../blib','../lib','./lib');
use Class::ParmList qw(simple_parms);

# General info for writing test modules:
#
# When running as 'make test' the default
# working directory is the one _above_ the
# 't/' directory.

my @do_tests=(1..5);

my $test_subs = {
       1 => { -code => \&test1, -desc => ' malformed parameter list              ' },
       2 => { -code => \&test2, -desc => ' correctly formed parameter list       ' },
       3 => { -code => \&test3, -desc => ' missing parameters                    ' },
       4 => { -code => \&test4, -desc => ' extra parameters                      ' },
       5 => { -code => \&test5, -desc => ' bad context                           ' },
};
print $do_tests[0],'..',$do_tests[$#do_tests],"\n";
print STDERR "\n";
my $n_failures = 0;
foreach my $test (@do_tests) {
	my $sub  = $test_subs->{$test}->{-code};
	my $desc = $test_subs->{$test}->{-desc};
	my $failure = '';
	eval { $failure = &$sub; };
	if ($@) {
		$failure = $@;
	}
	if ($failure ne '') {
		chomp $failure;
		print "not ok $test\n";
		print STDERR "    $desc - $failure\n";
		$n_failures++;
	} else {
		print "ok $test\n";
		print STDERR "    $desc - ok\n";

	}
}
print "END\n";
exit;

########################################
# malformed parameter lists            #
########################################
sub test1 {
	eval { my ($parm1,$parm2) = simple_parms('parm1','parm2','key1','value1'); };
	if (not $@) { return 'Failed to detect simple malformed parameter list (no prototype list)' }
	eval { my ($parm1,$parm2) = simple_parms(['parm1','parm2'],'key1'); };
	if (not $@) { return 'Failed to detect hashed malformed parameter list (odd number of parms)' }
	eval { my ($parm1,$parm2) = simple_parms(['parm1','parm2'],'key1','value2','key2'); };
	if (not $@) { return 'Failed to detect hashed malformed parameter list (odd number of parms)' }
    return '';
}

########################################
# correctly formed parameter lists     #
########################################
sub test2 {
    my ($parm1,$parm2,$parm3,$parm4);
    eval { ($parm1,$parm2) = simple_parms(['parm1','parm2'],'parm1','value1','parm2','value2'); };
	if ($@) {
        return "Failed to parse simple list parameters correctly: $@";
    }
    if (($parm1 ne 'value1') || ($parm2 ne 'value2')) {
        return 'Failed to parse simple list parameters correctly - returned values were incorrect';
    }
	eval {
        ($parm1,$parm2,$parm3,$parm4) = simple_parms(['parm1','parm2','earm3','arm4'],
                                                        { 'parm1' => 'value1',
                                                          'parm2' => 'value2',
                                                          'earm3' => 'value3',
                                                           'arm4' => 'value4' });
    };
	if ($@) {
        return "Failed to parse anon hash parameter correctly: $@";
    }
    if (($parm1 ne 'value1') || ($parm2 ne 'value2') || ($parm3 ne 'value3') || ($parm4 ne 'value4')) {
        return 'Failed to parse anon hash parameters correctly - returned values were incorrect';
    }

    # Check for ordering dependancies
	eval {
        ($parm3,$parm1,$parm2,$parm4) = simple_parms(['earm3','parm1','parm2','arm4'],
                                                        { 'parm1' => 'value1',
                                                          'parm2' => 'value2',
                                                          'earm3' => 'value3',
                                                           'arm4' => 'value4' });
    };
	if ($@) {
        return "Failed to parse anon hash parameter correctly: $@";
    }
    if (($parm1 ne 'value1') || ($parm2 ne 'value2') || ($parm3 ne 'value3') || ($parm4 ne 'value4')) {
        return 'Failed to parse anon hash parameters correctly - returned values were incorrect when permuted';
    }
    return '';
}

########################################
# Missing parameters                   #
########################################
sub test3 {
	eval { my ($parm1,$parm2) = simple_parms(['parm1','parm2'],'parm1','value1'); };
	if (not $@) {
        return "Failed to detect missing parameters in a simple list";
    }

	eval { my ($parm1,$parm2) = simple_parms(['parm1','parm2'],{ 'parm1' => 'value1'} ); };
	if (not $@) {
        return "Failed to detect missing parameters in hash list";
    }
    return '';
}

########################################
# Extra parameters                     #
########################################
sub test4 {
	eval { my ($parm1,$parm2) = simple_parms(['parm1','parm2'],'parm1','value1','parm2','value2','parm3','value3'); };
	if (not $@) {
        return "Failed to detect extra parameters in a simple list";
    }

	eval { my ($parm1,$parm2) = simple_parms(['parm1','parm2'],{ 'parm1' => 'value1', 'parm2' => 'value2', 'parm3' => 'value3'} ); };
	if (not $@) {
        return "Failed to detect extra parameters in hash list";
    }
    return '';
}

########################################
# Bad context                          #
########################################
sub test5 {
	eval { my $parm1 = simple_parms(['parm1','parm2'],'parm1','value1','parm2','value2'); };
	if (not $@) {
        return "Failed to detect a bad context for returned results with a simple list";
    }

	eval { my $parm1 = simple_parms(['parm1','parm2'],{ 'parm1' => 'value1', 'parm2' => 'value2'} ); };
	if (not $@) {
        return "Failed to detect a bad context for returned results for a hash list";
    }

    return '';
}
