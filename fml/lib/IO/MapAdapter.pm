#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package IO::MapAdapter;
use vars qw(@ISA);
use strict;
use Carp;

require Exporter;
@ISA = qw(Exporter);

BEGIN {}
END   {}

=head1 NAME

IO::MapAdapter - adapter for several IO interfaces

=head1 SYNOPSIS

This is just an adapter for 
e.g. file, unix group, NIS, RDMS et. al.
So, after you create and open the map, 
operation method is the same as usual file IO.
For examle

    use IO::MapAdapter;
    $obj = new IO::MapAdapter $map;
    $obj->open || croak("cannot open $map");
    while ($x = $obj->getline) { ... }
    $obj->close;

=head1 DESCRIPTION

This is "Adapter" (or "Wrapper") design pattern.

=head1 MAP

"map" is what database we read/write. 
The basic format of the database is a file. 
In a lot of cases, the file format is one line for one entry.
For example,

   key1
   key2 value

So, to get one entry is to read one line or a part of one line.

This wrapper maps IO for some object to usual file IO.


   map name        descriptions or examples        
   ---------------------------------------------------
   file            file:$file_name
                   For example, file:/var/spool/ml/elena/recipients

   unix.group      unix.group:$group_name
                   For example, unix.group:fml

   nis             NIS "Netork Information System" (YP)
                   *** not yet implemented ***

   mysql           mysql:$schema_name
                   *** not yet implemented ***

   postgresql      postgresql:$schema_name
                   *** not yet implemented ***

   ldap            ldap:$schema_name
                   *** not yet implemented ***

=head1 METHODS

=item C<new()>

the constructor. $args is a map.

=cut

sub new
{
    my ($self, $map, $args) = @_;
    my ($type) = ref($self) || $self;
    my ($me)   = {};

    if (ref($map) eq 'ARRAY') {
	$me->{_type}            = 'array_reference';
	$me->{_array_reference} = $map;

	my $pkg = 'IO::Adapter::Array';
	unshift(@ISA, $pkg);
	eval qq{ require $pkg; $pkg->import();};
	_error_reason($me, $@) if $@;
    }
    else {
	if ($map =~ /file:(\S+)/ || $map =~ m@^(/\S+)@) {
	    $me->{_file} = $1;
	    $me->{_type} = 'file';
	}
	elsif ($map =~ /unix\.group:(\S+)/) {
	    $me->{_name} = $1;
	    $me->{_type} = 'unix.group';

	    my $pkg = 'IO::Adapter::Array';
	    unshift(@ISA, $pkg);
	    eval qq{ require $pkg; $pkg->import();};
	    _error_reason($me, $@) if $@;
	}
	elsif ($map =~ /(ldap|mysql|postgresql):(\S+)/) {
	    $me->{_type}   = $1;
	    $me->{_schema} = $2;

	    # lowercase the '_type' syntax
	    $me->{_type}   =~ tr/A-Z/a-z/;
	}
	else {
	    my $s = "IO::MapAdapter::new: args='$map' is unknown.";
	    print STDERR $s, "\n";
	    _error_reason($me, $s);
	}
    }

    return bless $me, $type;
}


sub _error_reason
{
    my ($self, $mesg) = @_;
    $self->{ _error_reason } = $mesg;
}


sub error
{
    my ($self) = @_;
    return $self->{ _error_reason };
}


sub dump_variables
{
    my ($self, $args) = @_;
    my ($k, $v);
    while (($k, $v) = each %$self) {
	print STDERR "IO::Map.debug: $k => $v\n";
    }
}


sub open
{
    my ($self, $flag) = @_;

    # default flag is "r" == "read open"
    $flag ||= 'r';

    if ($self->{'_type'} eq 'file') {
	my $file = $self->{_file};
	my $fh;
	use FileHandle;
	$fh = new FileHandle $file, $flag;
	if (defined $fh) {
	    $self->{_fh} = $fh;
	    return $fh;
	}
	else {
	    $self->_error_reason("Error: cannot open $file $flag");
	    return undef;
	}
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	my (@x)       = getgrnam( $self->{_name} );
	my (@members) = split ' ', $x[3];
	$self->{_array_reference} = \@members;
	$self->SUPER::open( { flag => $flag } );
    }
    elsif ($self->{'_type'} eq 'array_reference') {
	$self->SUPER::open( { flag => $flag } );
    }
    elsif ($self->{'_type'} eq 'ldap' ||
	   $self->{'_type'} eq 'mysql' ||
	   $self->{'_type'} eq 'postgresql'
	   ) {
	return undef;
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


my $c = 0;
my $ec = 0;
sub line_count { my ($self) = @_; return "${ec}/${c}";}


# aliases for convenience
sub get_member    { my ($self) = @_; $self->_get_address;}
sub get_active    { my ($self) = @_; $self->_get_address;}
sub get_recipient { my ($self) = @_; $self->_get_address;}
sub _get_address
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my ($buf) = '';
	my $fh = $self->{_fh};

	if (defined $fh) {
	  INPUT:
	    while ($buf = <$fh>) {
		$c++; # for benchmark (debug)
		next INPUT if not defined $buf;
		next INPUT if $buf =~ /^\s*$/o;
		next INPUT if $buf =~ /^\#/o;
		next INPUT if $buf =~ /\sm=/o;
		next INPUT if $buf =~ /\sr=/o;
		next INPUT if $buf =~ /\ss=/o;
		last INPUT;
	    }

	    if (defined $buf) {
		my @buf = split(/\s+/, $buf);
		$buf    = $buf[0];
		$buf    =~ s/[\r\n]*$//o;
		$ec++;
	    }
	    return $buf;
	}
	return undef;
    }
    elsif ($self->{'_type'} eq 'unix.group' ||
	   $self->{'_type'} eq 'array_reference') {
	$self->SUPER::get_next_value();
    }
    elsif ($self->{'_type'} eq 'ldap' ||
	   $self->{'_type'} eq 'mysql' ||
	   $self->{'_type'} eq 'postgresql'
	   ) {
	$self->_error_reason("Error: not yet implemented");
	return undef;
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


# raw line reading
sub getline
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	$fh->getline;
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	my $i  = $self->{_counter}++;
	my $ra = $self->{_members};
	defined $$ra[ $i ] ? $$ra[ $i ] : undef;
    }
    elsif ($self->{'_type'} eq 'ldap' ||
	   $self->{'_type'} eq 'mysql' ||
	   $self->{'_type'} eq 'postgresql'
	   ) {
	$self->_error_reason("Error: not yet implemented");
	return undef;
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
	return undef;
    }
}


sub getpos
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	defined $fh ? tell($fh) : undef;
    }
    elsif ($self->{'_type'} eq 'unix.group' ||
	   $self->{'_type'} eq 'array_reference') {
	$self->SUPER::getpos();
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


sub setpos
{
    my ($self, $pos) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	seek($fh, $pos, 0);
    }
    elsif ($self->{'_type'} eq 'unix.group' ||
	   $self->{'_type'} eq 'array_reference') {
	$self->SUPER::getpos($pos);
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


sub eof
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	$fh->eof if defined $fh;
    }
    elsif ($self->{'_type'} eq 'unix.group' ||
	   $self->{'_type'} eq 'array_reference') {
	$self->SUPER::eof();
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


sub close
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	$self->{_fh}->close if defined $self->{_fh};
    }
    elsif ($self->{'_type'} eq 'unix.group' ||
	   $self->{'_type'} eq 'array_reference') {
	;
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


sub DESTROY
{
    my ($self) = @_;
    $self->close;
    undef $self;
}


=head1 AUTHOR

Ken'ichi Fukamchi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamchi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::MapAdapter.pm appeared in fml5.

=cut

1;
