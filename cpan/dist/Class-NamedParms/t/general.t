#!/usr/bin/perl -w

use strict;
use lib ('./blib','../lib','./lib');
use Class::NamedParms;

my @do_tests=(1..3);

my $test_subs = { 
       1 => { -code => \&test1, -desc => 'set   ' },
       2 => { -code => \&test2, -desc => 'get   ' },
       3 => { -code => \&test3, -desc => 'clear ' },
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
# set                                  #
########################################
sub test1 {
	eval {
		my $class = Class::NamedParms->new(-testing);
		$class->set({ -testing => 1 });
	};

	if ($@) {
		return $@;
	}
	'';
}

########################################
# get                                  #
########################################
sub test2 {
	my $class = Class::NamedParms->new(-testing);
	my $test_value = '1.0056';
	$class->set({ -testing => $test_value });
	eval {
		my $value = $class->get(-testing);
		if ($value ne $test_value) {
			return "value returned was not the same as value set\n";
		}
	};

	if ($@) {
		return $@;
	}
	'';
}

########################################
# clear                                #
########################################
sub test3 {
	eval {
		my $class = Class::NamedParms->new(-testing);
		my $test_value = '1.0054';
		$class->set({ -testing => $test_value });
		my $value = $class->get(-testing);
		if ($value ne $test_value) {
			return "value returned was not the same as value set\n";
		}
		$class->clear(-testing);
		my $new_value = $class->get(-testing);
		if (defined $new_value) {
			return "failed to clear value\n";
		}
	};

	if ($@) {
		return $@;
	}
	'';
}
