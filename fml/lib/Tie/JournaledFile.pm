#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: JournaledFile.pm,v 1.24 2002/12/22 03:37:15 fukachan Exp $
#

package Tie::JournaledFile;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Tie::JournaledFile - hash operation for a jurnaled style log file

=head1 SYNOPSIS

   use Tie::JournaledFile;
   $db = new Tie::JournaledFile { file => 'cache.txt' };

   # get all entries with the key = 'rudo'
   @values = $db->find( 'rudo' );

or access in hash style

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { file => 'cache.txt' };
   print $db{ rudo }, "\n";

where the format of "cache.txt" is

   key value

for each line. For example

     rudo   teddy bear
     kenken north fox
     .....

By default, FETCH() returns the first value with the key.
It meas first match.

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { first_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

If you print out the latest value for C<$key>, specify C<last_match>.

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { last_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

It is the value at the latest line with the key in the file.

=head2 KNOWN BUG

YOU CANNOT USE SPACE (\s+) IN THE KEY.


=head1 METHODS

=head2 TIEHASH, FETCH, STORE, FIRSTKEY, NEXTKEY

standard hash functions.

=cut


my $debug = 0;


# Descriptions: constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: import _match_style into $self
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    $me->{ _file } = $args->{ file };

    # define search strategy: first or last match
    if (defined $args->{ 'first_match' } && defined $args->{ 'last_match' }) {
	croak "both first_match and last_match specified\n";
    }
    elsif (defined $args->{ 'first_match' }) {
	$me->{ '_match_style' } = 'first';
    }
    elsif (defined $args->{ 'last_match' }) {
	$me->{ '_match_style' } = 'last';
    }
    else {
	# XXX-TODO: why first match by default?
	# first match by default.
	$me->{ '_match_style' } = 'first';
    }

    return bless $me, $type;
}


# Descriptions: tie() operation stars
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: initialize object
# Return Value: OBJ
sub TIEHASH
{
    my ($self, $args) = @_;
    $args->{ 'last_match' } = 1;

    new($self, $args);
}


# Descriptions: tie() fetch op
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub FETCH
{
    my ($self, $key) = @_;

    $self->_fetch($key, 'scalar');
}


# Descriptions: tie() store op
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub STORE
{
    my ($self, $key, $value) = @_;

    $self->_store($key, $value);
}


# Descriptions: op for keys() and each()
#    Arguments: OBJ($self)
# Side Effects: initialize $self->{ _hash }.
# Return Value: ARRAY(STR, STR)
sub FIRSTKEY
{
    my ($self) = @_;
    my $file = $self->{ '_file' };
    my $hash = {};

    use IO::File;
    my $fh = new IO::File $file;
    if (defined $fh) {
	my ($k, $v);
	while (<$fh>) {
	    # XXX overwritten. it means last match.
	    # XXX-TODO: hmm, what imply first match ?
	    ($k, $v) = split(/\s+/, $_, 2);
	    $hash->{ $k } = $v if $k;
	}
	$fh->close();
    }
    else {
	return undef; # error: cannot open file
    }

    $self->{ _hash } = $hash;
    return each %$hash;
}


# Descriptions: tie() keys op (next op)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub NEXTKEY
{
    my ($self) = @_;
    my $hash = $self->{ _hash };

    if (defined $hash) {
	return each %$hash;
    }
    # error: file handle is not defined.
    else {
	return undef;
    }
}


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


# Descriptions: return all key and the values as HASH_REF
#               { key => [ values ] }
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_all_values_as_hash_ref
{
    my ($self) = @_;
    my $file   = $self->{ '_file' };
    my $hash   = {};

    use IO::File;
    my $fh = new IO::File;

    if (-f $file && defined $fh) {
	$fh->open($file, "r");

	if (defined $fh) {
	    $self->{ _fh } = $fh;

	    my ($a, $k, $v);
	    while (<$fh>) {
		chomp;

		($k, $v) = split(/\s+/, $_, 2);

		if (defined $hash->{ $k }) {
		    $a = $hash->{ $k };
		}
		else {
		    $a = [];
		}

		push(@$a, $v);
		$hash->{ $k } = $a;
	    }
	    $fh->close();
	}
	else {
	    $self->{ _fh } = undef;
	}

	return $hash;
    }
    else {
	return undef;
    }
}


=head2 find(key, [ $mode ])

return the array of line(s) with the specified C<key>.

The line is either first or last mached line.
The maching strategy is determined by C<last_match> or C<first_match>
parameter at C<new()> method. C<first_match> by default.

=cut


# Descriptions: return the array of line(s) with the specified key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: ARRAY_REF
sub find
{
    my ($self, $key, $mode) = @_;
    return $self->_fetch($key, $mode || 'array');
}


# Descriptions: real function to search $key.
#               This routine is used at find() and FETCH() methods.
#               return the value with the $key
#               $self->{ '_match_style' } conrolls the matching algorithm
#               is either of the fist or last match.
#    Arguments: OBJ($self) STR($key) STR($mode)
#               $key is the string to search.
#               $mode selects the return value style, scalar or array.
# Side Effects: none
# Return Value: SCALAR or ARRAY_REF
sub _fetch
{
    my ($self, $key, $mode) = @_;
    my $prekey  = $key;
    my $keytrap = quotemeta($key);

    # the first 1 byte of the key
    if ($key =~ /^(.)/) { $prekey = quotemeta($1);}

    use IO::File;
    my $fh = new IO::File;
    $fh->open($self->{ '_file' }, "r");

    # error (we fail to open cache file).
    unless (defined $fh) { return undef;}

    # o.k. we open cache file, here we go for searching
    my ($xkey, $xvalue, $value, @values) = ();

  SEARCH:
    while (<$fh>) {
	next SEARCH if /^\#*$/;
	next SEARCH if /^\s*$/;
	next SEARCH unless /^$prekey/i;
	next SEARCH unless /^$keytrap/i;

	chomp;

	($xkey, $xvalue) = split(/\s+/, $_, 2);
	if ($xkey eq $key) {
	    $value = $xvalue; # save the value for $key

	    if ($mode eq 'array' || $mode eq 'array_ref') {
		push(@values, $value);
	    }
	    if ($mode eq 'scalar') {
		# firstmatch: exit loop ASAP if the $key is found.
		if ($self->{ '_match_style' } eq 'first') {
		    last SEARCH;
		}
	    }
	}
    }
    close($fh);

    if ($mode eq 'scalar') {
	return( $value || undef );
    }
    elsif ($mode eq 'array') {
	return @values;
    }
    elsif ($mode eq 'array_ref') {
	return \@values;
    }
    else {
	croak("JournaledFile: invalid mode");
    }
}


# Descriptions: wrapper to put "key => value" pair to cache file.
#               It emulates hash value upates.
#    Arguments: OBJ($self) STR($key) STR($value)
#               that is, $key => $value
# Side Effects: update cache file by _puts()
# Return Value: same as _puts()
sub _store
{
    my ($self, $key, $value) = @_;
    $self->_puts(sprintf("%-20s   %s", $key, $value));
}


# Descriptions: append given string to cache file
#    Arguments: OBJ($self) STR($string)
# Side Effects: update cache file
# Return Value: 1 or throw exception by croak()
sub _puts
{
    my ($self, $string) = @_;
    my $file = $self->{ '_file' };

    use IO::File;
    my $fh = new IO::File;
    if (defined $fh) {
	$fh->open($file, "a");

	if (defined $string) {
	    $fh->print($string);
	    $fh->print("\n") unless $string =~ /\n$/;
	}

	$fh->close;
    }
    else {
	croak "cannot open cache file $file\n";
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Tie::JournaledFile first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
