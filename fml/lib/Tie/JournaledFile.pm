#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: JournaledFile.pm,v 1.5 2001/06/17 08:57:11 fukachan Exp $
#

package Tie::JournaledFile;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Tie::JournaledFile - hash emulation for a log structered file

=head1 SYNOPSIS

   use Tie::JournaledFile;
   $db = new Tie::JournaledFile { file => 'cache.txt' };

   # get all entries with the key = 'rudo'
   @values = $db->grep( 'rudo' );

or

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { file => 'cache.txt' };
   print $db{ rudo }, "\n";

where the format of "cache.txt" is "key value" for each line.
For example

     rudo   teddy bear
     kenken north fox
     .....

By default, FETCH() returns the first value with the key.

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { first_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

If you print out the latest value (so at the later line somewhere in
the file) for the specified C<$key>

   use Tie::JournaledFile;
   tie %db, 'Tie::JournaledFile', { last_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

=head1 METHODS

=head2 TIEHASH, FETCH, STORE, FIRSTKEY, NEXTKEY

standard hash functions.

=cut


# Descriptions: constructor
#    Arguments: $self $args
# Side Effects: import _match_style into $self
# Return Value: object
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # make a cache file if not exists
    $me->{ _file } = $args->{ file };
    unless (-f $me->{ _file }) {
	use Time::localtime;
	my $date = ctime(time);
	_puts($me, "# format: ^key\\s+value\$");
	_puts($me, "#              key: should not have spaces in it.");
	_puts($me, "#            value: may have spaces in it.");
	_puts($me, "#");
	_puts($me, "# created at $date");
    }
    
    # define search strategy: first or last match
    if (defined $args->{ first_match }) {
	$me->{ _match_style } = 'first';
    }
    elsif (defined $args->{ last_match }) {
	$me->{ _match_style } = 'last';
    }
    else {
	$me->{ _match_style } = 'first';
    }

    return bless $me, $type;
}


sub TIEHASH
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    new($self, $args);
}


sub FETCH
{
    my ($self, $key) = @_;
    $self->_fetch($key, 'scalar');
}


sub STORE
{
    my ($self, $key, $value) = @_;
    $self->_store($key, $value);
}


sub FIRSTKEY
{
    my ($self) = @_;

    use IO::File;
    my $fh = new IO::File;
    $fh->open( $self->{ _file }, "r");
    $self->{ _fh } = $fh;

    my $r = <$fh>;
    my @r = split(/\s+/, $r);
    return $r[0];
}


sub NEXTKEY
{
    my ($self) = @_;
    my $fh = $self->{ _fh };
    my $r  = <$fh>;
    my @r  = split(/\s+/, $r);
    return $r[0];
}


=head2 C<grep(key)>

return the line with the C<key>. 
The line is either first or last mached line.
It is determined by C<last_match> or C<first_match> parameter at
C<new()> method. 
C<first_match> by default.

=cut

sub grep
{
    my ($self, $key) = @_;
    my $rarray = $self->_fetch($key, 'array');
    return @$rarray;
}


# Descriptions: real function to search $key.
#               This routine is used at grep() and FETCH() methods.
#               return the value with the $key
#               $self->{ _match_style } conrolls the matching algorithm
#               is either of the fist or last match.
#    Arguments: $self $key $mode
#               $key is the string to search.
#               $mode selects the return value style, scalar or array.
# Side Effects: none
# Return Value: SCALAR or ARRAY with the key
sub _fetch
{
    my ($self, $key, $mode) = @_;
    my $prekey = $key;

    # the first 1 byte of the key
    if ($key =~ /^(.)/) { $prekey = $1;}

    use IO::File;
    my $fh = new IO::File;
    $fh->open( $self->{ _file }, "r");

    # error (we fail to open cache file).
    unless (defined $fh) { return undef;}

    # o.k. we open cache file, here we go for searching
    my ($xkey, $xvalue) = ();
    my (@values)        = ();
  SEARCH:
    while (<$fh>) {
	next SEARCH if /^\#*$/;
	next SEARCH if /^\s*$/;
	next SEARCH unless /^$prekey/i; 
	next SEARCH unless /^$key/i;

	chop;

	($xkey, $xvalue) = split(/\s+/, $_, 2);
	if ($xkey eq $key) {
	    if ($mode eq 'array') {
		push(@values, $xvalue);  
	    }
	    if ($mode eq 'scalar') {
		# firstmatch: exit loop ASAP if the $key is found.
		if ($self->{ _match_style } eq 'first') {
		    last SEARCH;
		}
	    }
	}
    }	
    close($fh);

    if ($mode eq 'scalar') {
	return( $xvalue || undef );
    }
    if ($mode eq 'array') {
	return \@values;
    }    
}


# Descriptions: wrapper to put "key => value" pair to cache file.
#               It emulates hash value upates.
#    Arguments: $self $key $value
#               that is, $key => $value
# Side Effects: update cache file by _puts()
# Return Value: return value from _puts()
sub _store
{
    my ($self, $key, $value) = @_;
    $self->_puts(sprintf("%-20s   %s", $key, $value));
}



# Descriptions: append given string to cache file
#    Arguments: $self $string
# Side Effects: update cache file
# Return Value: 1 or throw exception by croak()
sub _puts
{
    my ($self, $string) = @_;
    my $file = $self->{ _file };

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
