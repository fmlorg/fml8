#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: JournaledFile.pm,v 1.12 2001/12/26 14:23:31 fukachan Exp $
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

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { first_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

If you print out the latest value for C<$key>

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
    my ($type) = ref($self) || $self;
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


# Descriptions: tie() keys op
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub FIRSTKEY
{
    my ($self) = @_;

    use IO::File;
    my $fh = new IO::File;
    if ($fh->open( $self->{ '_file' }, "r")) {
	$self->{ _fh } = $fh;

	my $r   = <$fh>;
	my $key = (split(/\s+/, $r))[0];

	# negative cache
	$self->{ '_key_negative_cache' }->{ $key } = 1;

	print STDERR "   File.FIRSTKEY: $key (return)\n" if $debug;
	return $key;
    }
    else {
	return undef; # error: cannot open file
    }
}


# Descriptions: tie() keys op (next op)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub NEXTKEY
{
    my ($self) = @_;
    my $fh = $self->{ _fh };

    if (defined $fh) {
	my ($r, $key);

      LOOP:
	while (defined ($r = <$fh>)) {
	    $key = (split(/\s+/, $r))[0];

	    # duplicated (already returned key)
	    if (defined $self->{ '_key_negative_cache' }->{ $key }) {
		print STDERR "   File.NEXTKEY: $key (dup, ignored)\n" if $debug;
		next LOOP;
	    }
	    else {
		print STDERR "   File.NEXTKEY: $key (found)\n" if $debug;
	    }

	    # negative cache
	    $self->{ '_key_negative_cache' }->{ $key }++;
	    last LOOP;
	}

	# duplicated key ( > 1 ) is found. ignore it.
	# XXX "> 1" is important to clarify duplication or not.
	if ((defined $self->{ '_key_negative_cache' }->{ $key }) &&
	    ($self->{ '_key_negative_cache' }->{ $key } > 1)) {
	    print STDERR "   File.NEXTKEY: $key (ignored*)\n" if $debug;
	    return undef;
	}
	# $key is found
	else {
	    print STDERR "   File.NEXTKEY: $key found\n" if $debug;
	    return $key;
	}
    }
    # error: file handle is not defined.
    else {
	print STDERR "   File.NEXTKEY: file handle exhauseted" if $debug;
	return undef;
    }
}


=head2 C<find(key)>

return the array of line(s) with the specified C<key>.

The line is either first or last mached line.
The maching strategy is determined by C<last_match> or C<first_match>
parameter at C<new()> method. C<first_match> by default.

=cut


# Descriptions: return the array of line(s) with the specified key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: ARRAY
sub find
{
    my ($self, $key) = @_;
    my $rarray = $self->_fetch($key, 'array');
    return @$rarray;
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
# Return Value: SCALAR or ARRAY
sub _fetch
{
    my ($self, $key, $mode) = @_;
    my $prekey  = $key;
    my $keytrap = quotemeta($key);

    # the first 1 byte of the key
    if ($key =~ /^(.)/) { $prekey = quotemeta($1);}

    use IO::File;
    my $fh = new IO::File;
    $fh->open( $self->{ '_file' }, "r");

    # error (we fail to open cache file).
    unless (defined $fh) { return undef;}

    # o.k. we open cache file, here we go for searching
    my ($xkey, $xvalue, $value) = ();
    my (@values)        = ();
  SEARCH:
    while (<$fh>) {
	next SEARCH if /^\#*$/;
	next SEARCH if /^\s*$/;
	next SEARCH unless /^$prekey/i;
	next SEARCH unless /^$keytrap/i;

	chop;

	($xkey, $xvalue) = split(/\s+/, $_, 2);
	if ($xkey eq $key) {
	    $value = $xvalue; # save the value for $key

	    if ($mode eq 'array') {
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
	return \@values;
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
    $fh->open($file, "a");

    if (defined $fh) {
	use Time::localtime;
	my $date = ctime(time);
	if (defined $string) {
	    $fh->print($string);
	    $fh->print("\n") unless $string =~ /\n$/;
	}
	$fh->close;
	return 1;
    }
    else {
	use Carp;
	croak "cannot open cache file $file\n";
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Tie::JournaledFile appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
