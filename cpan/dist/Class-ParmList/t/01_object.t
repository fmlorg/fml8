#!/usr/bin/perl -w

use strict;
use lib ('./blib','../lib','./lib');
use Class::ParmList;

my @do_tests=(1..5);

my $test_subs = {
       1 => { -code => \&test1, -desc => 'legal                ' },
       2 => { -code => \&test2, -desc => 'required             ' },
       3 => { -code => \&test3, -desc => 'defaults             ' },
       4 => { -code => \&test4, -desc => 'stacked parms (hash) ' },
       5 => { -code => \&test5, -desc => 'stacked parms (list) ' },
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
        print STDERR "     $desc                  - $failure\n";
        $n_failures++;
    } else {
        print "ok $test\n";
        print STDERR "     $desc                  - ok\n";

    }
}
print "END\n";
exit;

########################################
# legal                                #
########################################
sub test1 {
    my $parms = { -test => 'hello' };
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                           -legal => [qw(-test)],
                                         });
		if (not defined $class) {
			 die "failed to create new object and parse data";
		}
		my ($test) = $class->get(-test);
    };

    if ($@) {
        return $@;
    }
    eval {
		my $class;
        $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                           -legal => [-burp],
                                         });
		if (defined $class) {
			 die "failed to flag undeclared parameter";
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# required                             #
########################################
sub test2 {
    my $parms = { -test => 'hello' };
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [qw(-burp)],
                                           -legal => [qw(-test)],
                                         });
		if (defined $class) {
			 die "failed to flag missing required parameter";
		}
    };
    if ($@) {
        return $@;
    }
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [qw(-test)],
                                           -legal => [qw(-burp)],
                                         });
		if (not defined $class) {
			 die "failed to accept required parameter";
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# defaults                             #
########################################
sub test3 {
    my $parms = { -test => 'hello' };
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {-heathen => 'yes', -test=> 'goodbye' },
                                        -required => [],
                                           -legal => [qw(-test -heathen)],
                                         });
		if (not defined $class) {
			 die "failed to flag missing required parameter";
		}
		my ($test,$heathen) = $class->get(-test,-heathen);
		if ($test ne 'hello') {
			return "failed to overwrite default";
		}
		if ($heathen ne 'yes') {
			return 'failed to set default';
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# stacked parms hash                   #
########################################
sub test4 {
    my $parms = [{ '-test' => 'hello' }];
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {-heathen => 'yes', -test=> 'goodbye' },
                                        -required => [],
                                           -legal => [qw(-test -heathen)],
                                         });
		if (not defined $class) {
			 die "failed to flag missing required parameter";
		}
		my ($test,$heathen) = $class->get(-test,-heathen);
		if ($test ne 'hello') {
			return "failed to overwrite default";
		}
		if ($heathen ne 'yes') {
			return 'failed to set default';
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# stacked parms list                   #
########################################
sub test5 {
    my $parms = [ '-test' => 'hello' ];
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {-heathen => 'yes', -test=> 'goodbye' },
                                        -required => [],
                                           -legal => [qw(-test -heathen)],
                                         });
		if (not defined $class) {
			 die "failed to flag missing required parameter";
		}
		my ($test,$heathen) = $class->get(-test,-heathen);
		if ($test ne 'hello') {
			return "failed to overwrite default";
		}
		if ($heathen ne 'yes') {
			return 'failed to set default';
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
