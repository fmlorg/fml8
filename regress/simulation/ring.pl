use File::RingBuffer;

my $obj = new File::RingBuffer {
    directory => "/tmp/b"
};

my $fh = $obj->open;
$_ = `date`;
print $fh $_;
close($fh);

$obj->close;
