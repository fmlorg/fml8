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
use vars qw(@ISA @ORIG_ISA $FirstTime);
use strict;
use Carp;
use ErrorMessages::Status qw(error_set error error_clear);

BEGIN {}
END   {}

=head1 NAME

IO::MapAdapter - adapter for several IO interfaces

=head1 SYNOPSIS

    use IO::MapAdapter;
    $obj = new IO::MapAdapter ($map, $map_params);
    $obj->open || croak("cannot open $map");
    while ($x = $obj->getline) { ... }
    $obj->close;

where C<$map_params> is map specific parametes used for C<RDBMS>.
For example, C<$map_params> is:

    $map_params = {
	'mysql:toymodel' => {
	    getline        => "select ... ",
	    get_next_value => "select ... ",
	    add            => "insert ... ",
	    delete         => "delete ... ",
	    replace        => "set address = 'value' where ... ",
	},
    };


=head1 DESCRIPTION

This is "Adapter" (or "Wrapper") C<design pattern>.
This is a wrapper of IO for
e.g. file, 
unix group, 
NIS (Network Information System), 
RDBMS (Relational DataBase Management System)
et. al.
Once you create and open a C<map>, 
you can use the same methods as usual file IO.

=head2 MAP

C<map> specifies the type of the database we read/write.  

For example, C<file> map imples we hold our data in a file.
The format is one line for one entry in a lot of cases.

   key1
   key2 value

To get one entry is to read one line or a part of one line.

This wrapper provides IO like a usual file for the specified C<$map>. 

=head2 MAP TYPES

   map name        descriptions or examples        
   ---------------------------------------------------
   file            file:$file_name
                   For example, file:/var/spool/ml/elena/recipients

   unix.group      unix.group:$group_name
                   For example, unix.group:fml

   nis.group       nis.group:$group_name
                   the NIS "Netork Information System" (YP) map "group.byname"
                   For example, nis.group:fml

   mysql           mysql:$schema_name
                   *** not yet implemented ***

   postgresql      postgresql:$schema_name
                   *** not yet implemented ***

   ldap            ldap:$schema_name
                   *** not yet implemented ***

=head1 METHODS

=item C<new()>

the constructor. The first argument is a map decribed above.

=cut


# Descriptions: a constructor, which prepare IO operations for the
#               given $map
#    Arguments: $self $map $args
# Side Effects: @ISA is modified
#               load and import sub-class
# Return Value: object
sub new
{
    my ($self, $map, $args) = @_;
    my ($type) = ref($self) || $self;
    my ($me)   = { _map => $map };
    my $pkg;

    if (ref($map) eq 'ARRAY') {
	$pkg                    = 'IO::Adapter::Array';
	$me->{_type}            = 'array_reference';
	$me->{_array_reference} = $map;
    }
    else {
	if ($map =~ /file:(\S+)/ || $map =~ m@^(/\S+)@) {
	    $me->{_file} = $1;
	    $me->{_type} = 'file';
	    $pkg         = 'IO::Adapter::File';
	}
	elsif ($map =~ /unix\.group:(\S+)/) {
	    $me->{_name} = $1;
	    $me->{_type} = 'unix.group';
	    $pkg         = 'IO::Adapter::UnixGroup';
	}
	elsif ($map =~ /nis\.group:(\S+)/) {
	    $me->{_name} = $1;
	    $me->{_type} = 'nis.group';
	    $pkg         = 'IO::Adapter::NIS';
	}
	elsif ($map =~ /(mysql|postgresql):(\S+)/i) {
	    $me->{_type}   = $1;
	    $me->{_schema} = $2;
	    $me->{_params} = $args;
	    $me->{_type}   =~ tr/A-Z/a-z/; # lowercase the '_type' syntax
	    $pkg           = 'IO::Adapter::MySQL';
	}
	elsif ($map =~ /(ldap):(\S+)/i) {
	    $me->{_type}   = $1;
	    $me->{_schema} = $2;
	    $me->{_params} = $args;
	    $me->{_type}   =~ tr/A-Z/a-z/; # lowercase the '_type' syntax
	    $pkg           = 'IO::Adapter::LDAP';
	}
	else {
	    my $s = "IO::MapAdapter::new: map='$map' is unknown.";
	    error_set($me, $s);
	}
    }

    # save @ISA for further use, re-evaluate @ISA
    @ORIG_ISA = @ISA unless $FirstTime++;
    @ISA      = ($pkg, @ORIG_ISA);

    eval qq{ require $pkg; $pkg->import();};
    $pkg->configure($me, $args) if $pkg->can('configure');
    error_set($me, $@) if $@;

    return bless $me, $type;
}


=head2 

=item C<open([$flag])>

open IO operation for the map. 
C<$flag> is passed to SUPER CLASS open()
when "file:" map is specified. 
C<open()> is a dummy function in other maps now.

=cut

# Descriptions: open IO, each request is forwraded to each sub-class
#    Arguments: $self $flag
#               $flag is the same as open()'s flag for file: map but
#               "r" only for other maps.
# Side Effects: none
# Return Value: file handle
sub open
{
    my ($self, $flag) = @_;

    # default flag is "r" == "read open"
    $flag ||= 'r';

    if ($self->{'_type'} eq 'file') {
	$self->SUPER::open( { file => $self->{_file}, flag => $flag } );
    }
    elsif ($self->{'_type'} eq 'unix.group' ||
	   $self->{'_type'} eq 'array_reference') {
	$self->SUPER::open( { flag => $flag } );
    }
    elsif ($self->{'_type'} =~ /^(ldap|mysql|postgresql)$/o) {
	$self->SUPER::open( { flag => $flag } );
    }
    else {
	$self->error_set("Error: type=$self->{_type} is unknown type.");
    }
}


=head2

=item C<getline()>

In C<file> map case, it is the same as usual getline() for a file.
In other maps, it is the same as C<get_next_value()> method below.

=item C<get_next_value()>

get the next value from the specified database (map). 
For example, this function returns the first column in the next line
for C<file> map. 
It return the next element of the array,
in C<array_reference>, C<unix.group>, C<nis.grouop> maps.

=item C<get_member()>

an alias of C<get_next_value()> now.

=item C<get_active()>

an alias of C<get_next_value()> now.

=item C<get_recipient()>

an alias of C<get_next_value()> now.

=cut

# Descriptions: aliases for convenience
#               request is forwarded to get_next_value() method.
#    Arguments: $self
# Side Effects: none
# Return Value: none
sub get_member    { my ($self) = @_; $self->get_next_value;}
sub get_active    { my ($self) = @_; $self->get_next_value;}
sub get_recipient { my ($self) = @_; $self->get_next_value;}


=head2 C<add( $address )>

add $address to the specified map.

=head2 C<delete( $regexp )>

delete lines which matches $regexp from this map.

=head2 C<regexp( $regexp, $value )>

replace lines which matches $regexp with $value.

=cut


# Descriptions: 
#    Arguments: $self $address
# Side Effects: 
# Return Value: none
sub add
{
    my ($self, $address) = @_;

    if ($self->can('add')) {
	$self->SUPER::add($address);
    }
    else {
	$self->error_set("Error: add() method is not supported.");
	undef;
    }
}


# Descriptions: 
#    Arguments: $self $address
# Side Effects: 
# Return Value: none
sub delete
{
    my ($self, $regexp) = @_;

    if ($self->can('delete')) {
	$self->SUPER::delete($regexp);
    }
    else {
	$self->error_set("Error: delete() method is not supported.");
	undef;
    }
}


# Descriptions: 
#    Arguments: $self $regexp $value
# Side Effects: 
# Return Value: none
sub replace
{
    my ($self, $regexp, $value) = @_;

    if ($self->can('replace')) {
	$self->SUPER::replace($regexp, $value);
    }
    else {
	$self->error_set("Error: replace() method is not supported.");
	undef;
    }
}


# Descriptions: destructor
#               request is forwarded to close() method.
#    Arguments: $self $args
# Side Effects: object is undef'ed.
# Return Value: none
sub DESTROY
{
    my ($self) = @_;
    $self->close;
    undef $self;
}


=head2

=item C<error()>

return the most recent error message if exists.

=head1 AUTHOR

Ken'ichi Fukamchi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamchi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::MapAdapter appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
