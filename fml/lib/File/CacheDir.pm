#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: CacheDir.pm,v 1.10 2002/01/13 05:46:25 fukachan Exp $
#

package File::CacheDir;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::File;

=head1 NAME

File::CacheDir - IO operations to ring buffer which consists of files

=head1 SYNOPSIS

   ... lock e.g. by flock(2) ...

   use File::CacheDir;
   $obj = new File::CacheDir {
       directory => '/some/where'
   };
   $fh = $obj->open;
   print $fh "some message";
   $fh->close;

   ... unlock ...

The buffer directory has files with the name C<0>, C<1>, ...
You can specify C<file_name> parameter.

   $obj = new File::CacheDir {
       directory => '/some/where',
       file_name => '_smtplog',
   };

If so, the file names become _smtplog.0, _smtplog.1, ...

The C<File::CacheDir> described above is limited by size.

You can use File::CacheDir based on time not size.
It is time based expiretion. 
If you so, use new() like this:

   $obj = new File::CacheDir {
       directory  => '/some/where',
       cache_type => 'temporal',
       expires_in => 90,             # 90 days
   };

where C<cache_type> is C<cyclic> by default.


=head1 DESCRIPTION

To log messages up to some limit, 
it may be useful to use filenames in cyclic way.
The file to write is chosen among a set of files allocated as a buffer.

Consider several files under a directory C<ring/> as a ring buffer
where the unit of the ring is 5 here.
C<ring/> may have 5 files in it.

   0 1 2 3 4

To log a message is to write it to one of them.
At the first time the message is logged to the file C<0>,
and next time to C<1> and so on.
If all 5 files are used, 
this module reuses and overwrites the oldest one C<0>.
So we use a file in cyclic way as follows:

   0 -> 1 -> 2 -> 3 -> 4 -> 0 -> 1 -> ...

We expire the old data.
A file name is a number for simplicity.
The latest number is holded in C<ring/.seq> file (C<.seq> in that
direcotry by default) and truncated to 0 by the modulo C<5>.

=head1 METHODS

=head2 new(args)

=cut


@ISA = qw(IO::File);

BEGIN {}
END   {}


# Descriptions: constructor
#               forward new() request to superclass (IO::File)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
#               XXX $self is blessed file handle.
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _take_file_name($me, $args);

    return bless $me, $type;
}


# Descriptions: determine the file name to write into
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: increment $sequence_file_name
#               set the file name at ${*$self}{ _file }
# Return Value: none
sub _take_file_name
{
    my ($self, $args) = @_;
    my $directory          = $args->{ directory } || '.';
    my $file_name          = $args->{ file_name } || '';
    my $sequence_file_name = $args->{ sequence_file_name } || '.seq';
    my $modulus            = $args->{ modulus } || 128;
    my $cache_type         = $args->{ cache_type } || 'cyclic';

    my $file;
    eval q{ use File::Spec;};

    unless (-d $directory) {
	my $mode = $args->{ directory_mode } || 0755;
	eval q{ use File::Utils qw(mkdirhier);};
	mkdirhier($directory, $mode);
    }

    if ($cache_type eq 'temporal') {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time);
	my $file_name = sprintf("%04d%02d%02d", 1900+$year, $mon+1, $mday);
	$file = File::Spec->catfile($directory, $file_name);
    }
    elsif ($cache_type eq 'cyclic') {
	my $seq_file = File::Spec->catfile($directory, $sequence_file_name);

	eval q{ use File::Sequence;};
	my $sfh = new File::Sequence {
	    sequence_file => $seq_file,
	    modulus       => $modulus,
	};
	my $id = $sfh->increment_id;
	$file  = File::Spec->catfile($directory, $file_name.$id);
    }

    $self->{ _cache_type } = $cache_type || 'cyclic';
    $self->{ _cache_data } = {};
    $self->{ _directory }  = $directory || '';
    $self->{ _file }       = $file || '';
}


=head2 C<open(file, mode)>

no argument.

=cut


# Descriptions: open() a file in the buffer
#    Arguments: OBJ($self) STR($file) STR($mode)
#               XXX $self is blessed file handle.
# Side Effects: create ${ *$self } hash to save status information
# Return Value: HANDLE(write file handle for $file.new.$$)
sub open
{
    my ($self, $file, $mode) = @_;
    $file = $file || $self->{ _file };
    $mode = defined $mode ? $mode :
	($self->{ _cache_type } eq 'temporal' ? "a+" : "w+");

    # error
    return undef unless $file;

    # If the cache is limited by "time", we only add values to the file.
    # If limited by space, we ovewrite the file, so open it by the mode "w".
    my $fh = new IO::File;

    # real open with $mode
    if (defined $fh) {
	$fh->open($file, $mode);
	$fh->autoflush(1);
	$self->{ _fh } = $fh;
	return $fh;
    }
    else {
	return undef;
    }
}


=head2 C<close()>

no argument.

=cut


# Descriptions: forward close() to SUPER class
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as SUPER::close() or UNDEF
sub close
{
    my ($self) = @_;
    my $fh = $self->{ _fh };
    defined $fh ? $fh->close() : undef;
}


=head2 get(key)

get value (latest value in the ring buffer) for key.

=cut


# Descriptions: get value (latest value in the ring buffer) for key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub get
{
    my ($self, $key) = @_;
    $self->get_latest_value($key);
}


# Descriptions: get value (latest value in the ring buffer) for key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub get_latest_value
{
    my ($self, $key) = @_;
    my $file = $self->{ _file };
    my $buf  = $self->_search($file, $key);

    # return cache
    return $buf if $buf;

    my $dir = $self->{ _directory };
    return '' unless $dir;

    my $dh = new IO::Handle;
    opendir($dh, $dir);

    my @dh = ();
    for (readdir($dh)) { push(@dh, $_) if /^\d+/;}
    @dh = sort { $b <=> $a } @dh;

    eval q{ use File::Spec;};

    for (@dh) {
	next if $_ =~ /^\./;
	next if $_ !~ /^\d/;
	next if $_ =~ /^\d{1,2}$/;

	$file = File::Spec->catfile($dir, $_);
	$buf  = $self->_search($file, $key);
	last if $buf;
    }
    closedir($dh) if defined $dh;

    return $buf;
}


# Descriptions: search value for $key in the $file
#    Arguments: OBJ($self) STR($file) STR($key)
# Side Effects: none
# Return Value: STR
sub _search
{
    my ($self, $file, $key) = @_;
    my $hash = $self->{ _cache_data };
    my $pkey = quotemeta( substr($key, 0, 1) );
    my $buf;

    # negative cache
    return '' unless $file;
    return '' if defined $hash->{ $file };
    $hash->{ $file } = 1;

    my $fh = $self->open($file, "r");
    while ($_ = $fh->getline) {
	next unless /^$pkey/;

	if (/^$key\s+/ || /^$key$/) {
	    chop $_;
	    my ($k, $v) = split(/\s+/, $_, 2);
	    $buf = $v;
	}
    }
    $self->close;

    $buf;
}


=head2 find(key)

get value (latest value in the ring buffer) for key.
same as get() now.

=cut


# Descriptions: get value (latest value in the ring buffer) for key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub find
{
    my ($self, $key) = @_;
    $self->get($key);
}


=head2 set(key, value) 

set value for key.

=cut


# Descriptions: set value for key.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: same as close()
sub set
{
    my ($self, $key, $value) = @_;
    my $fh = $self->open;
    print $fh $key, "\t", $value, "\n";
    $self->close;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

File::CacheDir appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
