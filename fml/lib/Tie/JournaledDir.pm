#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: JournaledDir.pm,v 1.21 2003/08/23 04:35:49 fukachan Exp $
#

package Tie::JournaledDir;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Tie::JournaledDir - tie hash to journaled style directory cache

=head1 SYNOPSIS

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', { dir => '/some/where' };
    $db{ 'key' } = 'value';
    untie %db

=head1 DESCRIPTIONS

tie hash by C<Tie::JournaledDir> acceses some directory holding a lot
of files. For example, the directory consists of files with numeric
names.

    /some/where/998520336
    /some/where/998520338
    /some/where/998520340
    /some/where/998520342

C<Tie::JournaledFile> manipulates each file.

C<Tie::JournaledDir> has cache files in a directory.
C<Tie::JournaledDir> wraps C<Tie::JournaledFile> over several files.
It enables easy automatic expiration.


=head1 METHODS

=head2 new($args)

    $args = {
	dir   => directory path,        # mandatory
	unit  => number (seconds),      # optional
	limit => number (days),         # optional
    };

you need specify C<dir> as cache dir at least.

C<unit> is optional, "day" by default.
C<unit> is number (seconds) or keyword "day".

C<limit> is number. It is the range of unit to search.

For example,

    $args = {
	dir   => '/var/spool/ml/elena/var/db/message_id',
	unit  => 'day',
	limit => 90,     # search the last 90 days.
    };

=head2 TIEHASH, FETCH, STORE, FIRSTKEY, NEXTKEY

standard hash functions.

It uses C<Tie::JournaledFile> in background.

=cut


#
# See Tie::Hash
#    sub TIEHASH  { bless {}, $_[0] }
#    sub STORE    { $_[0]->{$_[1]} = $_[2] }
#    sub FETCH    { $_[0]->{$_[1]} }
#    sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
#    sub NEXTKEY  { each %{$_[0]} }
#    sub EXISTS   { exists $_[0]->{$_[1]} }
#    sub DELETE   { delete $_[0]->{$_[1]} }
#    sub CLEAR    { %{$_[0]} = () }
#


use Tie::JournaledFile;

my $debug = 0;


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
#               $args = {
#                    dir => directory path,
#                   unit => number (seconds)
#                  limit => number (days)
#               }
# Side Effects: import _match_style into $self
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    my $dir   = $args->{ 'dir' }   || '';
    my $unit  = $args->{ 'unit' }  || 'day'; # 1 day
    my $limit = $args->{ 'limit' } || 90;

    # sanity.
    unless ($dir) { croak("dir unspecified");}

    # reverse order file list to search
    my @filelist = ();
    for (my $i = 0; $i < $limit; $i++) {
	$filelist[ $i ] = _file_name($unit, $dir, $i);
    }

    # set up object
    $me->{ '_dir' }   = $dir;
    $me->{ '_files' } = \@filelist;
    return bless $me, $type;
}


# Descriptions: generate a cache file name.
#    Arguments: NUM($unit) STR($dir) NUM($i)
# Side Effects: none
# Return Value: STR(file path)
sub _file_name
{
    my ($unit, $dir, $i) = @_;
    my $fn = '';

    if ($unit =~ /^\d+$/o) {
	$fn = $unit * int(time / $unit) - ($i * $unit);
    }
    elsif ($unit eq 'day') {
	use Mail::Message::Date;
	my $date = new Mail::Message::Date time;
	$fn = $date->YYYYMMDD( time - $i * 24 * 3600 );
    }
    else {
	carp("JournaledDir: wrong unit");
    }

    use File::Spec;
    return File::Spec->catfile($dir, $fn);
}


# Descriptions: call new().
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: same as new()
# Return Value: OBJ
sub TIEHASH
{
    my ($self, $args) = @_;
    new($self, $args);
}


# Descriptions: hash{} access to file in the cache directory
#               by Tie::JournaledFile sequentially.
#               XXX file list in the directory is given by new().
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub FETCH
{
    my ($self, $key) = @_;
    my $files = $self->{ '_files' } || [];
    my $x     = '';

  FILE:
    for my $f (@$files) {
	if (-f $f) {
	    # XXX reverse order: firstly, try last match in the latest file.
	    my $obj = new Tie::JournaledFile {
		'match_condition' => 'last',
		'file'            => $f,
	    };

	    if (defined $obj) {
		$x = $obj->FETCH($key);
		last FILE if defined $x;
	    }
	}
    }

    return $x;
}


# Descriptions: add { $key => $value } to the latest file
#               by Tie::JournaledFile.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: STR(Tie::JournaledFile->STORE() operation return value)
sub STORE
{
    my ($self, $key, $value) = @_;
    my $f = $self->{ '_files' }->[ 0 ]; # XXX [0] is the latest file.

    my $obj = new Tie::JournaledFile {
	'match_condition' => 'last',
	'file'            => $f,
    };

    return $obj->STORE($key, $value);
}


# Descriptions: generate and return HASH_REF on memory over all data.
#    Arguments: OBJ($self)
# Side Effects: generate hash on memory
# Return Value: HASH_REF
sub __gen_hash
{
    my ($self) = @_;
    my $files  = $self->{ '_files' } || [];
    my $hash   = {};
    my %db     = ();
    my ($k, $v);

    use FileHandle;
  FILE:
    for my $f (reverse @$files) {
	next FILE unless -f $f;

	tie %db, 'Tie::JournaledFile', {
	    'match_condition' => 'last',
	    'file'            => $f,
	};

	# XXX overwrite { key => value } for normal time order.
	# XXX so, the value is the latest one.
	while (($k, $v) = each %db) {
	    $hash->{ $k } = $v;
	}

	untie %db;
    }

    return $hash;
}


# Descriptions: return the first key in hash on memory.
#    Arguments: OBJ($self)
# Side Effects: __gen_hash() creates hash on momery.
# Return Value: ARRAY(STR, STR)
sub FIRSTKEY
{
    my ($self) = @_;
    my $hash   = $self->__gen_hash();

    if (defined $hash) {
	$self->{ _hash } = $hash;
	return each %$hash;
    }
    else {
	return undef;
    }
}


# Descriptions: fetch the next key in the cache.
#               file to search changes automatically by Tie::JournaledFile.
#    Arguments: OBJ($self) STR($lastkey)
# Side Effects: seek $self->{ _hash } by each().
# Return Value: ARRAY(STR, STR)
sub NEXTKEY
{
    my ($self, $lastkey) = @_;
    my $hash = $self->{ _hash };

    if (defined $hash) {
	return each %$hash;
    }
    else {
	return undef;
    }
}


# Descriptions: check whether $key exists ($key has value or not).
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub EXISTS
{
    my ($self, $key) = @_;
    my $v = $self->FETCH($key);

    return $v ? 1 : 0;
}


# Descriptions: delete $key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: update cache.
# Return Value: none
sub DELETE
{
    my ($self, $key) = @_;

    $self->STORE($key, '');
}


# Descriptions: dummy.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub CLEAR
{
    ;
}



=head1 NOT tie() BASED METHODS

=head2 get_all_values_as_hash_ref()

return { key => values } for all keys.
The returned value is HASH REFERECE for the KEY as follows:

   KEY => [
	   VALUE1,
	   VALUE2,
	   vlaue3,
	   ];

not

   KEY => VALUE

which is by default.

=cut


# Descriptions: get all values for the key as ARRAY_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_all_values_as_hash_ref
{
    my ($self) = @_;
    my $files  = $self->{ '_files' } || [];
    my $result = {};

    # read files in reverse order to overwrite values by the latest one
    # from old to new.
    use FileHandle;
    for my $f (reverse @$files) {
	my $obj  = new Tie::JournaledFile {
	    'match_condition' => 'last',
	    'file'            => $f,
	};
	my $hash = $obj->get_all_values_as_hash_ref();

	# copy
	my ($a, $k, $v);
	while (($k, $v) = each %$hash) {
	    if (defined $result->{ $k }) {
		$a = $result->{ $k };
	    }
	    else {
		$a = [];
	    }

	    push(@$a, @$v);
	    $result->{ $k } = $a;
	}
    }

    # return all values assigned to the key.
    #        { key => [ value1, value2, ... ] }.
    return $result;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Tie::JournaledDir first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
