use File::RingBuffer;

my $obj = new File::RingBuffer {
    directory => "/tmp"
};

my $fh = $obj->open;

chop($_ = `date`);
print $fh $_;
close($fh);

$obj->close;
