#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package File::LogStructuredData;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

File::LogStructuredData - hash emulation for a log structered file

=head1 SYNOPSIS

   use File::LogStructuredData;
   $db = new File::LogStructuredData { file => 'cache.txt' };

   # add value for the key 'rudo'
   $db->append('rudo', 'is pretty');

   # get all entries with the key = 'rudo'
   $values = $db->find( 'rudo' );

where $values->[0] is "is pretty'.

If you want to use C<tie()> style, you can use it like this:

   use File::LogStructuredData;
   tie %db, 'File::LogStructuredData', { file => 'cache.txt' };
   print $db{ rudo }, "\n";

where the format of "cache.txt" is "key value" for each line.
For example

     rudo   teddy bear
     kenken north fox
     .....

By default, FETCH() returns the first value with the key.

   use File::LogStructuredData;
   tie %db, 'File::LogStructuredData', { first_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

If you print out the latest value (so at the later line somewhere in
the file) for the specified C<$key>

   use File::LogStructuredData;
   tie %db, 'File::LogStructuredData', { last_match => 1, file => 'cache.txt' };
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

    $me->{ _file } = $args->{ file };

    if ($args->{ first_match }) {
	$me->{ _match_style } = 'first';
    }
    elsif ($args->{ last_match }) {
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


=head2 C<find(key)>

return the line with the C<key>. 
The line is either first or last mached line.
It is determined by C<last_match> or C<first_match> parameter at
C<new()> method. 
C<first_match> by default.

=cut

sub find
{
    my ($self, $key) = @_;
    return $self->_fetch($key, 'array');
}



=head2 C<get_value(key)>

get the latest value for the C<key>.

=cut


sub get_value
{
    my ($self, $key) = @_;
    my $ra = $self->_fetch($key, 'array');
    my $x;
    for (@$ra) { $x = $_;}
    return $x;
}


# Descriptions: real function to search $key.
#               This routine is used at find() and FETCH() methods.
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


=head2 C<append($key, $value)>

append C<$key> and C<$value> to the database.

=cut


sub append
{
    my ($self, $key, $value) = @_;

    use IO::File;
    my $fh = new IO::File;
    $fh->open( $self->{ _file }, "a");
    $fh->autoflush(1);
    print $fh $key, " ", $value, "\n";
    $fh->close;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::LogStructuredData appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
