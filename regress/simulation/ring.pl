use File::RingBuffer;

my $obj = new File::RingBuffer {
    directory => "/tmp/b"
};


&uja($obj);

my $obj = new File::RingBuffer {
    directory => "/tmp/b",
    file_name => "_smtplog.",
};

&uja($obj);


sub uja
{
	my ($obj) = @_;

	my $fh = $obj->open;
	$_ = `date`;
	print $fh $_;
	close($fh);

	$obj->close;
}
