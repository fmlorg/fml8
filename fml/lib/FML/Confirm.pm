#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Confirm.pm,v 1.9 2002/12/22 04:43:05 fukachan Exp $
#

package FML::Confirm;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Confirm - manipulate confirmation database

=head1 SYNOPSIS

    use FML::Confirm;
    my $confirm = new FML::Confirm {
            keyword   => $keyword,
            cache_dir => $cache_dir,
            class     => 'subscribe',
            address   => $address,
            buffer    => $command,
        };
    my $id = $confirm->assign_id;
    $curproc->reply_message_nl('command.confirm');
    $curproc->reply_message("\n$id\n");

=head1 DESCRIPTION

This module provides several utilitiy functions for confirmation.
    assign id
    store id
    expire id
    database manipulation

=head1 METHODS

=head2 new($args)

usual constructor.

    $args = {
	keyword   => "confirm",
	cache_dir => "/some/where",
	class     => "subscribe",
	address   => "mail@address",
	buffer    => $buffer,
    };

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create object
# Return Value: OBJ
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


=head2 assign_id()

assign new id for current object.

=cut


# Descriptions: assign new id for current object
#    Arguments: OBJ($self)
# Side Effects: update databse
# Return Value: STR
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

    use Mail::Message::Checksum;
    my $cksum  = new Mail::Message::Checksum;
    my $md5sum = $cksum->md5( \$string );

    # o.k. assign id
    my $id = "$keyword $class $md5sum";
    $self->store_id( $md5sum );

    return $id;
}


# Descriptions: open database by Tie::JournaledDir.
#    Arguments: OBJ($self) STR($id) STR($comment)
# Side Effects: open database, mkdir if needed
# Return Value: HASH_REF to dabase
sub _open_db
{
    my ($self, $id, $comment) = @_;
    my (%db) = ();

    # XXX-TODO: dir_mode hard-coded.
    my $mode = $self->{ _dir_mode } || 0700;

    use File::Spec;
    my $cache_dir = $self->{ _cache_dir };
    my $class     = $self->{ _class };
    my $dir       = File::Spec->catfile($cache_dir, $class);

    unless (-d $dir) {
	use File::Path;
	mkpath( [ $dir ], 0, $mode );
    }

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', { dir => $dir };

    $self->{ _db } = \%db;

    return \%db;
}


# Descriptions: close database.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _close_db
{
    my ($self) = @_;
    my $db = $self->{ _db };
    untie %$db;
}


=head2 store_id($id, $comment)

save id into databse with comment if specified.

=cut


# Descriptions: save id into databse
#    Arguments: OBJ($self) STR($id) STR($comment)
# Side Effects: update database
# Return Value: none
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


=head2 find($id)

find database value for $id

=cut


# Descriptions: find value for $id
#    Arguments: OBJ($self) STR($id)
# Side Effects: update $self->{ _found };
# Return Value: STR
sub find
{
    my ($self, $id) = @_;
    my $db = $self->_open_db();

    my $found = $db->{ $id };
    $self->_close_db();

    $self->{ _found } = $found;

    return $found;
}


=head2 get_request($id)

get value for request id $id.

=cut


# Descriptions: get request id
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub get_request
{
    my ($self, $id) = @_;
    my $db = $self->_open_db();

    my $found = $db->{ "request-$id" } || undef;
    $self->_close_db();

    return $found;
}


=head2 get_address($id)

get address for $id.

=cut


# Descriptions: get address for $id
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub get_address
{
    my ($self, $id) = @_;
    my $db = $self->_open_db();

    my $found = $db->{ "address-$id" } || undef;
    $self->_close_db();

    return $found;
}


=head2 is_expired($found, $howold)

request for $id is expired or not.
specify $found (database value) for $id as argument.

=cut


# Descriptions: request for $id is expired or not
#    Arguments: OBJ($self) STR($found) NUM($howold)
# Side Effects: none
# Return Value: 1 or 0
sub is_expired
{
    # XXX-TODO: strange argument ? should be is_expired($id) ?
    my ($self, $found, $howold) = @_;
    my ($time, $commont) = split(/\s+/, $found);

    if ((time - $time) > $howold) {
	return 1; # expired
    }
    else {
	return 0;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Confirm first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
