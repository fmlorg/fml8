if ($0 eq __FILE__) {
    use FML::Lock;
    my $lockobj = new FML::Lock;

    my $r = $lockobj->lock( { file => '/tmp/a' });
    if ($r) { 
	print STDERR "lock ($$) ... ok\n";
    }
    else {
	print STDERR $lockobj->error, "\n";
    }

    sleep 1;

    $r = $lockobj->unlock( { file => '/tmp/a' });
    if ($r) { 
	print STDERR "unlock ... ok\n";
    }
    else {
	print STDERR $lockobj->error, "\n";
    }
}
