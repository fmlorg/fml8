#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: JournaledDir.pm,v 1.1 2001/08/21 03:46:39 fukachan Exp $
#

package Tie::JournaledDir;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Tie::JournaledDir - wrap Tie::JournaledFile

=head1 SYNOPSIS

    use Tie::JournaledDir;
    $db = new Tie::JournaledDir { 
        dir => '/some/where',
    };

    # get all entries with the key = 'rudo'
    @values = $db->grep( 'rudo' );

OR

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', { dir => '/some/where' };
    $db{ 1 } = 1;
    untie %db


=head1 METHODS

=head2 TIEHASH, FETCH, STORE, FIRSTKEY, NEXTKEY

standard hash functions.

=cut


use Tie::JournaledFile;

my $debug = $ENV{'debug'} ? 1 :0;


# Descriptions: constructor
#    Arguments: $self $args
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


sub _file_name
{
    my ($unit, $dir, $i) = @_;
    my $fn = $unit * int(time / $unit) - ($i * $unit);

    use File::Spec;
    File::Spec->catfile($dir, $fn);
}


sub TIEHASH
{
    my ($self, $args) = @_;
    new($self, $args);
}


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


sub __in_valid_search
{
    my ($self) = @_;
    return $self->{ '_key_files_obj' } ? 1 : 0;
}


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
