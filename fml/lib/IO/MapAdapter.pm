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
    my ($me)   = {};
    my $pkg;

    if (ref($map) eq 'ARRAY') {
	$pkg                    = 'IO::Adapter::Array';
	$me->{_type}            = 'array_reference';
	$me->{_array_reference} = $map;
    }
    else {
	if ($map =~ /file:(\S+)/ || $map =~ m@^(/\S+)@) {
	    $pkg         = 'IO::Adapter::File';
	    $me->{_file} = $1;
	    $me->{_type} = 'file';
	}
	elsif ($map =~ /unix\.group:(\S+)/) {
	    $pkg         = 'IO::Adapter::Array';
	    $me->{_name} = $1;
	    $me->{_type} = 'unix.group';

	    # emulate an array on memory
	    my (@x)       = getgrnam( $me->{_name} );
	    my (@members) = split ' ', $x[3];
	    $me->{_array_reference} = \@members;
	}
	elsif ($map =~ /nis\.group:(\S+)/) {
	    my $key      = $1;
	    $pkg         = 'IO::Adapter::Array';
	    $me->{_name} = $key;
	    $me->{_type} = 'nis.group';

	    # emulate an array on memory
	    my (@x)       = `ypmatch $key group.byname`;
	    my (@members) = split ',', $x[3];
	    $me->{_array_reference} = \@members;
	}
	elsif ($map =~ /(ldap|mysql|postgresql):(\S+)/) {
	    $me->{_type}   = $1;
	    $me->{_schema} = $2;
	    $me->{_type}   =~ tr/A-Z/a-z/; # lowercase the '_type' syntax
	}
	else {
	    my $s = "IO::MapAdapter::new: args='$map' is unknown.";
	    print STDERR $s, "\n";
	    _error_reason($me, $s);
	}
    }

    unshift(@ISA, $pkg);
    eval qq{ require $pkg; $pkg->import();};
    _error_reason($me, $@) if $@;

    return bless $me, $type;
}


=head2 

=item C<open([$flag])>

start IO operation for the map. $flag is passed to SUPER CLASS open()
for "file:" map but ignored in other maps now.

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
	return undef;
    }
    else {
	$self->_error_reason("Error: type=$self->{_type} is unknown type.");
    }
}


=head2

=item C<getline()>

For file map, it is the same as usual getline() for file.
For other maps, same as C<get_next_value()> method.

=item C<get_next_value()>

get the next value. For example, the first column in the next line for
C<file> map. For C<array_reference>, C<unix.group>, C<nis.grouop> maps,
return the next element of the array.

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


# Descriptions: log the error message in the object
#               internal use fucntion.
#    Arguments: $self $mesg
#               $mesg is the error message string.
# Side Effects: $self->{ _error_reason } is set to $mesg.
# Return Value: $mesg
sub _error_reason
{
    my ($self, $mesg) = @_;
    $self->{ _error_reason } = $mesg;
}


# Descriptions: return the error message
#    Arguments: $self
# Side Effects: none
# Return Value: error message
sub error
{
    my ($self) = @_;
    return $self->{ _error_reason };
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

IO::MapAdapter.pm appeared in fml5.

=cut

1;
