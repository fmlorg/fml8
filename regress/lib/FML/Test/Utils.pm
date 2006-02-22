#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package FML::Test::Utils;
use strict;
use Carp;

my $debug = $ENV{ debug } ? 1 : 0;


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub set_content
{
    my ($self, $file, $str) = @_;
    my $buf = '';

    use FileHandle;
    my $fh = new FileHandle "> $file";
    if (defined $fh) {
	print $fh $str, "\n";
	$fh->close();
    }
}


sub get_content
{
    my ($self, $file) = @_;
    my $buf = '';

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
	my $_buf;
	while ($_buf = <$fh>) { $buf .= $_buf;}
	$fh->close();
    }

    return $buf;
}


sub copy
{
    my ($self, $src, $dst) = @_;

    use IO::Adapter::AtomicFile;
    my $io = new IO::Adapter::AtomicFile;
    $io->copy($src, $dst) || croak("fail to copy $src $dst");
}


sub diff
{
    my ($self, $buf0, $buf1) = @_;
    my $title = $self->get_title();

    if ($debug) {
	print "? <$buf0> eq <$buf1>\n";
    }

    if ($buf0 eq $buf1) {
	printf("%-40s ... %s\n", $title, "ok");
    }
    else {
	printf("%-40s ... %s\n", $title, "fail");
    }
}


sub set_title
{
    my ($self, $title) = @_;
    $self->{ _cur_title } = $title || '';
}


sub get_title
{
    my ($self, $title) = @_;
    return( $self->{ _cur_title } || '' );
}


sub error
{
    my ($self, $msg) = @_;
    $self->print_error($msg);
    exit(1);
}


sub print_error
{
    my ($self, $msg) = @_;
    my $title = $self->get_title();

    if ($msg) {
	printf("%-40s ... fail (%s)\n", $title, $msg);
    }
    else {
	printf("%-40s ... fail\n", $title);
    }
}


sub print_ok
{
    my ($self, $msg) = @_;
    my $title = $self->get_title();

    if (defined $msg && $msg) {
	printf("%-40s ... %s (%s)\n", $title, "ok", $msg);
    }
    else {
	printf("%-40s ... %s\n", $title, "ok");
    }
}

1;
