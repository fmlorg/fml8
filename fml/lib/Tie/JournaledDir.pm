#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: JournaledDir.pm,v 1.2 2001/08/21 08:39:03 fukachan Exp $
#

package Tie::JournaledDir;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Tie::JournaledDir - tie hash to journaled style directory cache by Tie::JournaledFile

=head1 SYNOPSIS

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', { dir => '/some/where' };
    $db{ 'key' } = 'value';
    untie %db

=head1 DESCRIPTIONS

tie hash by C<Tie::JournaledDir> acceses some directory with a lot of
files. For example the directory consists of files with numeric names.

    /some/where/998520336
    /some/where/998520338
    /some/where/998520340
    /some/where/998520342

C<Tie::JournaledFile> manipulates each file.

C<Tie::JournaledDir> has a cache by a directory.
C<Tie::JournaledDir> wraps C<Tie::JournaledFile> over several files.
It enables easy automatic expiration.


=head1 METHODS

=head2 TIEHASH, FETCH, STORE, FIRSTKEY, NEXTKEY

standard hash functions.

It uses C<Tie::JournaledFile> in background.

=cut


use Tie::JournaledFile;

my $debug = $ENV{'debug'} ? 1 :0;


# Descriptions: constructor
#    Arguments: $self $args
#               $args = {
#                    dir => directory path,
#                   unit => number (seconds)
#                  limit => number (days)
#               }
# Side Effects: import _match_style into $self
# Return Value: object
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    my $dir   = $args->{ 'dir' };
    my $unit  = $args->{ 'unit' }  || 24*3600; # 1 day 
    my $limit = $args->{ 'limit' } || 90;

    # reverse order file list to search
    my @filelist = ();
    for (my $i = 0; $i < $limit; $i++) {
	$filelist[ $i ] = _file_name($unit, $dir, $i);
    }

    # set up object
    $me->{ 'dir' }   = $dir;
    $me->{ 'files' } = \@filelist;
    return bless $me, $type;
}


# Descriptions: generate a cache file
#    Arguments: (number, directory path, number)
# Side Effects: none
# Return Value: file path
sub _file_name
{
    my ($unit, $dir, $i) = @_;
    my $fn = $unit * int(time / $unit) - ($i * $unit);

    use File::Spec;
    File::Spec->catfile($dir, $fn);
}


# Descriptions: call new()
#    Arguments: $self $args
# Side Effects: same as new()
# Return Value: object returned by new()
sub TIEHASH
{
    my ($self, $args) = @_;
    new($self, $args);
}


# Descriptions: hash{} access to file in the cache directory
#               by Tie::JournaledFile sequentially.
#               XXX file list in the directory is given by new().
#    Arguments: $self $key
# Side Effects: none
# Return Value: key string
sub FETCH
{
    my ($self, $key) = @_;
    my $files = $self->{ 'files' } || [];
    my $x     = '';

  FILES_LOOP:
    for my $f (@$files) { 
	if (-f $f) {
	    my $obj = new Tie::JournaledFile { 
		'last_match' => 1, 
		'file'       => $f, 
	    };

	    if (defined $obj) {
		$x = $obj->FETCH($key);
		last FILES_LOOP if defined $x;
	    }
	}
    }

    return $x;
}


# Descriptions: add { $key => $value } to the latest file
#               by Tie::JournaledFile.  
#    Arguments: $self $key $value
# Side Effects: none
# Return Value: Tie::JournaledFile->STORE() operation return value
sub STORE
{
    my ($self, $key, $value) = @_;
    my $f = $self->{ 'files' }->[ 0 ]; # XXX [0] is the latest file.

    my $obj = new Tie::JournaledFile { 
	'last_match' => 1, 
	'file'       => $f, 
    };

    return $obj->STORE($key, $value);
}


# Descriptions: find key in file
#    Arguments: $self
# Side Effects: update object and negative cache in $self
#               where the cache is file list already searched
# Return Value: key string
sub __find_key
{
    my ($self) = @_;
    my $files = $self->{ 'files' };

    # we open some file now, search in the file.
    if (defined $self->{ '_key_files_obj' }) {
	my $obj = $self->{ '_key_files_obj' };
	my $x   = $obj->NEXTKEY();

	if (defined $x) {
	    print STDERR "NEXTKEY: $x\n" if $debug; 
	    return $x;
	}
	else {
	    delete $self->{ '_key_files_obj' };
	}
    }

    # 1. for the first time 
    # 2. no more valid keys in the file ( _key_files_obj object )
    # so try to read the first/next file
  FILES:
    for my $f (@$files) {
	# skip the file already done
	next FILES if defined $self->{ '_key_files_done' }->{ $f };

	# try to open the next file
	if (-f $f) {
	    print STDERR "open $f\n" if $debug; 
	    my $obj = new Tie::JournaledFile { 
		'last_match' => 1, 
		'file'       => $f, 
	    };

	    if (defined $obj) {
		# negative cache: mark which file is opened.
		$self->{ '_key_files_done' }->{ $f } = 1;

		# XXX for the first time
		my $x = $obj->FIRSTKEY();

		# save object if this file has valid value(s).
		if (defined $x) {
		    print STDERR "FIRSTKEY: $x\n" if $debug; 
		    $self->{ '_key_files_obj' } = $obj;
		    return $x;
		}
		# skip this file if this file has no valid value. 
		else {
		    print STDERR "FIRSTKEY: not found\n" if $debug; 
		    next FILES;
		}
	    }
	    else {
		delete $self->{ '_key_files_obj' };
	    }
	}
    }

    undef;
}


# Descriptions: object for cache file is alive
#    Arguments: $self
# Side Effects: none
# Return Value: 1 or 0
sub __in_valid_search
{
    my ($self) = @_;
    return $self->{ '_key_files_obj' } ? 1 : 0;
}


# Descriptions: return the first key in the latest file
#    Arguments: $self
# Side Effects: initialize _key_files{done,obj}
# Return Value: key string
sub FIRSTKEY
{
    my ($self) = @_;
    my $files = $self->{ 'files' };

    # initialize cache area which holds done lists
    delete $self->{ '_key_files_done' };
    delete $self->{ '_key_files_obj' };

    my $x = $self->__find_key();

    if (defined $x) {
	$self->{ '_key_cache' }->{ $x } = 1;
	return $x;
    }
    else {
	return undef;
    }
}


# Descriptions: fetch the next key in the cache
#               file to search changes automatically by Tie::JournaledFile.
#    Arguments: $self
# Side Effects: none
# Return Value: key string
sub NEXTKEY
{
    my ($self) = @_;

    # XXX we need the duplication check.
    # XXX This class opens plural files and
    # XXX is responsible to check return values.

    while ($self->__in_valid_search()) { # 1/0 is returned.
	my $x = $self->__find_key();

	if (defined $x) {
	    unless (defined $self->{ '_key_cache' }->{ $x }) {
		$self->{ '_key_cache' }->{ $x } = 1;
		return $x;
	    }
	    else {
		return undef;
	    }
	}
    }

    undef;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Tie::JournaledDir appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
