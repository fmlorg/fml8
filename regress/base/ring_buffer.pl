#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

-d "/tmp/b" || mkdir("/tmp/b", 0755);


use File::RingBuffer;

my $obj = new File::RingBuffer {
    directory => "/tmp/b"
};


&simple_write_to_ring_buffer($obj);

my $obj = new File::RingBuffer {
    directory => "/tmp/b",
    file_name => "_smtplog.",
};

&simple_write_to_ring_buffer($obj);


sub simple_write_to_ring_buffer
{
	my ($obj) = @_;

	my $fh = $obj->open;
	$_ = `date`;
	print $fh $_;
	close($fh);

	$obj->close;
}
