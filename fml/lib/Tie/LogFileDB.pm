#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package Tie::LogFileDB;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Tie::LogFileDB - hash emulation for a log structered file

=head1 SYNOPSIS

   use Tie::LogFileDB;
   $db = new Tie::LogFileDB { file => 'cache.txt' };

   # all entries with the key = 'rudo'
   @values = $db->grep( rudo );

or

   use Tie::LogFileDB;
   tie %db, 'Tie::LogFileDB', { file => 'cache.txt' };
   print $db{ rudo }, "\n";

where cache file "cache.txt" format is "key value" for each line.
For example

     rudo   teddy bear
     kenken north fox
     .....

By default, FETCH() returns the first value with the key.

   use Tie::LogFileDB;
   tie %db, 'Tie::LogFileDB', { first_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

if you find the latest value (so at the later line somewhere in the
file) for the $key

   use Tie::LogFileDB;
   tie %db, 'Tie::LogFileDB', { last_match => 1, file => 'cache.txt' };
   print $db{ rudo }, "\n";

=cut


require Exporter;
@ISA = qw(Exporter);

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


sub grep
{
    my ($self, $key) = @_;
    my $rarray = $self->_fetch($key, 'array');
    return @$rarray;
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


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Tie::LogFileDB appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
