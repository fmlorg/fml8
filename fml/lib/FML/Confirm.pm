#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.1 2001/08/07 12:23:48 fukachan Exp $
#

package FML::Confirm;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Confirm - assign id for e.g. confirmation 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new($args)>

usual constructor.

    $args = {
	cache_dir => "/some/where",
	class     => "subscribe",
	address   => "mail@address",
	buffer    => $buffer,
    };

=cut

sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    for my $id ('keyword', 'class', 'address', 'buffer', 'cache_dir') {
	if (defined $args->{ $id }) {
	    $me->{ "_$id" } = $args->{ $id };
	}
    }

    return bless $me, $type;
}


sub assign_id
{
    my ($self) = @_;
    my $class   = $self->{ _class };
    my $addr    = $self->{ _address };
    my $buffer  = $self->{ _buffer };
    my $keyword = $self->{ _keyword };
    my $time    = time;
    my $pid     = $$;
    my $string  = "$time $pid $addr $buffer";

    use FML::Checksum;
    my $cksum  = new FML::Checksum;
    my $md5sum = $cksum->md5( \$string );

    # o.k. assign id
    my $id = "$keyword $class $md5sum";
    $self->store_id( $md5sum );

    return $id;
}


sub _open_db
{
    my ($self, $id, $comment) = @_;
    my (%db) = ();

    use File::Spec;
    my $cache_dir = $self->{ _cache_dir };
    my $class     = $self->{ _class };
    my $dir       = File::Spec->catfile($cache_dir, $class);

    unless (-d $dir) {
	use File::Utils qw(mkdirhier);
	mkdirhier($dir, 0700);
    }

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', { dir => $dir };

    $self->{ _db } = \%db;

    return \%db;
}


sub _close_db
{
    my ($self) = @_;
    my $db = $self->{ _db };
    untie %$db;
}


sub store_id
{    
    my ($self, $id, $comment) = @_;
    my $class = $self->{ _class };
    my $addr  = $self->{ _address };
    my $db    = $self->_open_db();

    $db->{ $id } = time .(defined $comment ? " $comment" : '');
    $db->{ "request-$id" } = "$class $addr";
    $db->{ "address-$id" } = $addr;

    $self->_close_db();
}


sub find
{
    my ($self, $id) = @_;    
    my $db = $self->_open_db();

    my $found = $db->{ $id };
    $self->_close_db();

    $self->{ _found } = $found;

    return $found;
}


sub get_request
{
    my ($self, $id) = @_;    
    my $db = $self->_open_db();

    my $found = $db->{ "request-$id" } || undef;
    $self->_close_db();

    return $found;
}


sub get_address
{
    my ($self, $id) = @_;    
    my $db = $self->_open_db();

    my $found = $db->{ "address-$id" } || undef;
    $self->_close_db();

    return $found;
}


sub is_expired
{
    my ($self, $found, $howold) = @_;
    my ($time, $commont) = split(/\s+/, $found);

    if ((time - $time) > $howold) {
	return 1; # expired
    }
    else {
	return 0;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Confirm appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
