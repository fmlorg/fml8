$map = 'file:/etc/mail/sendmail.cf';

while (1) { &p;}

sub p
{
    use FML::IO::Map;
    my $obj = new FML::IO::Map $map;

    if (defined $obj) {
	$obj->open;

	if ($pos) { $obj->setpos($pos);} 

	$i = 0;
	# XXX $obj->getline returns a mail address.
	while (defined ($_ = $obj->get_rawline)) {
	    print $_;
	    last if $i++ > 3;
	}

	# save the current position in the file handle
	$pos = $obj->getpos;

	if ($obj->eof) { exit 0;}

	$obj->close;
    }
}

