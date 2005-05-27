#-*- perl -*-
#
#  Copyright (C) 2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Ring.pm,v 1.4 2004/07/23 15:59:02 fukachan Exp $
#

package FML::Cache::Ring;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::File;
use File::Spec;


=head1 NAME

FML::Cache::Ring - IO operations to ring buffer which consists of files.

=head1 SYNOPSIS

   ... lock e.g. by flock(2) ...

   use FML::Cache::Ring;
   $obj = new FML::Cache::Ring {
       directory          => '/some/where' # mandatory
       sequence_file_name => '.seq',       # optional
       modulus            => 128,          # optional
   };
   $fh = $obj->open;
   print $fh "some message";
   $fh->close;

   ... unlock ...

The buffer directory has files with the name C<0>, C<1>, ...
You can specify C<file_name> parameter.

   $obj = new FML::Cache::Ring {
       directory => '/some/where',
       file_name => '_smtplog',
   };

If so, the file names become _smtplog.0, _smtplog.1, ...

The cache data is limited by the number of files, so approximately
size by default. Instead of number fo files, you can limit
FML::Cache::Ring based on time. It is time based expiretion. If you
so, use new() like this:

   $obj = new FML::Cache::Ring {
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

$args hash can take the following arguments:

	variable		default value
	--------------------------------
	directory 		.
	file_name 		""
	sequence_file_name 	.seq
	modulus 		128
	cache_type 		cyclic
	dir_mode 		0755

=cut


@ISA = qw(IO::File);

BEGIN {}
END   {}


# Descriptions: constructor.
#               forward new() request to superclass (IO::File)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ (blessed as a file handle).
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _take_file_name($me, $args);

    return bless $me, $type;
}


# Descriptions: determine the file name to write into.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: increment $sequence_file_name
#               set the file name at ${*$self}{ _file }
# Return Value: none
sub _take_file_name
{
    my ($self, $args)      = @_;
    my $sequence_file_name = $args->{ sequence_file_name } || '.seq';
    my $directory          = $args->{ directory }  || '.';
    my $filename_prefix    = $args->{ file_name }  || '';
    my $modulus            = $args->{ modulus }    || 128;
    my $cache_type         = $args->{ cache_type } || 'cyclic';
    my $dir_mode           = $args->{ dir_mode }   || 0755;
    my $file;

    unless (-d $directory) {
	use File::Path;
	mkpath( [ $directory ], 0, $dir_mode);
    }

    if ($cache_type eq 'temporal') {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time);
	my $filename = sprintf("%04d%02d%02d", 1900+$year, $mon+1, $mday);
	$file = File::Spec->catfile($directory, $filename);
    }
    elsif ($cache_type eq 'cyclic') {
	my $seq_file = File::Spec->catfile($directory, $sequence_file_name);

	use IO::Adapter;
	my $io = new IO::Adapter $seq_file;
	my $id = $io->sequence_increment();

	# updated.
	my $saved_id = $id;

	# check if $id is rolled over or not.
	$id = $id % $modulus;
	if ($saved_id != $id) {
	    $io->sequence_replace($id);
	}

	# file.
	$file = File::Spec->catfile($directory,
				    sprintf("%s%s", $filename_prefix, $id));
    }

    $self->{ _cache_type } = $cache_type || 'cyclic';
    $self->{ _cache_data } = {};
    $self->{ _directory }  = $directory  || '';
    $self->{ _file }       = $file       || '';
}


# Descriptions: return the path of file to be written.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub cache_file_path
{
    my ($self) = @_;

    return( $self->{ _opened_file } || '');
}


=head2 open(file, mode)

open file in the buffer.
The target file is already determined when constructor runs.

=cut


# Descriptions: open() cache file in the buffer.
#    Arguments: OBJ($self) STR($file) STR($mode)
#               XXX $self is blessed file handle.
# Side Effects: create ${ *$self } hash to save status information
# Return Value: HANDLE(write file handle for $file.new.$$)
sub open
{
    my ($self, $file, $mode) = @_;
    $file = defined $file ? $file : $self->{ _file };
    $mode = defined $mode ? $mode :
	($self->{ _cache_type } eq 'temporal' ? "a+" : "w+");

    # error
    return undef unless $file;

    # If the cache is limited by "time", we only add values to the file.
    # If limited by space, we ovewrite the file, so open it by the mode "w".
    my $fh = new IO::File;

    # real open with $mode
    if (defined $fh) {
	$self->{ _opened_file } = $file;
	$fh->open($file, $mode);
	$fh->autoflush(1);
	$self->{ _fh } = $fh;
	return $fh;
    }
    else {
	return undef;
    }
}


=head2 close()

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


=head2 import_data_from($args)

import data from file.
Actually, link(2) $src to cache file.

    KEY        VALUE
    ---------------------------
    file       STR
    try_link   STR ( yes | no )

=cut


# Descriptions: import data from file.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $dst file (linked).
# Return Value: NUM(1(success) or 0(fail))
sub import_data_from
{
    my ($self, $args) = @_;
    my $link = $args->{ try_link }      || 1;
    my $src  = $args->{ file }          || '';
    my $dst  = $self->cache_file_path() || '';

    unless ($src) { return 0;}
    unless ($dst) {
	$self->open();
	$dst = $self->cache_file_path() || '';
    }

    if ($dst && $src) {
	return 0 unless -f $src;
	unlink $dst  if -f $dst;
	if (link($src, $dst)) {
	    return 1;
	}
	else {
	    return 0;
	}
    }

    return 0;
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


# Descriptions: get value (latest value in the ring buffer) for the
#               specified key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub get_latest_value
{
    my ($self, $key) = @_;

    # cheap sanity.
    return '' unless defined $key;

    # 1. return matched value if found in the latest cache.
    my $file = $self->{ _file };
    my $buf  = $self->_search($file, $key);
    return $buf if $buf;

    # 2. if not found in the latest cache, search cacheses in the
    #    cache directory in reverse temporal order.
    my $dir = $self->{ _directory };
    return '' unless $dir;

    my $dh = new IO::Handle;
    opendir($dh, $dir);

    my @dh = ();
    for my $entry (readdir($dh)) { push(@dh, $entry) if $entry =~ /^\d+/o;}
    @dh = sort { $b <=> $a } @dh;

  DIR_ENTRY:
    for my $_dirent (@dh) {
	next DIR_ENTRY if $_dirent =~ /^\./o;
	next DIR_ENTRY if $_dirent !~ /^\d/o;

	# XXX-TODO: rule ignoring /^\d{1,2}$/ is correct ?
	next DIR_ENTRY if $_dirent =~ /^\d{1,2}$/;

	$file = File::Spec->catfile($dir, $_dirent);
	$buf  = $self->_search($file, $key);

	last DIR_ENTRY if $buf;
    }
    closedir($dh) if defined $dh;

    return $buf;
}


# Descriptions: search value for $key in the $file.
#    Arguments: OBJ($self) STR($file) STR($key)
# Side Effects: none
# Return Value: STR
sub _search
{
    my ($self, $file, $key) = @_;
    my $hash = $self->{ _cache_data };
    my $pkey = quotemeta( substr($key, 0, 1) );
    my $buf  = '';

    # simple check
    return '' unless defined $file;
    return '' unless $file;

    # XXX-TODO: negative cache is needed ?
    # XXX-TODO: when negative cache is expired ? this code is correct ?
    return '' if defined $hash->{ $file };
    $hash->{ $file } = 1;

    my $fh = $self->open($file, "r");

    if (defined $fh) {
	my $x;

      ENTRY:
	while ($x = $fh->getline) {
	    next ENTRY unless $x =~ /^$pkey/;

	    if ($x =~ /^$key\s+/ || $x =~ /^$key$/) {
		chomp $x;
		my ($k, $v) = split(/\s+/, $x, 2);
		$buf = $v;
	    }
	}
	$self->close;
    }

    return $buf;
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

    if (defined $fh) {
	printf $fh "%s\t%s\n", $key, $value;
	$self->close;
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $tmp_dir = "/tmp/cachedir";

    unless (-d $tmp_dir) {
	eval q{
	    use File::Path;
	    mkpath( [ $tmp_dir ], 0, 0755);
	};
    }
    my $cache = new FML::Cache::Ring { directory => $tmp_dir };
    $cache->set(time, time);

    print STDERR "see $tmp_dir\n";
}


=head1 TODO

Export core parts of this module to another putlic class e.g.
File::SOMETHING outside FML::* classes, again.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Cache::Ring first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

FML::Cache::Ring is renamed from File::CacheDir in 2004.

=cut


1;
