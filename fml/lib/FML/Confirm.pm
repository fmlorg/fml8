#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Confirm.pm,v 1.16 2004/01/18 14:03:55 fukachan Exp $
#

package FML::Confirm;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Confirm - manipulate confirmation database.

=head1 SYNOPSIS

    use FML::Confirm;
    my $confirm = new FML::Confirm $curproc, {
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

This module provides several utilitiy functions for confirmation:
    assign id
    store  id
    expire id
    database manipulation utility

=head1 METHODS

=head2 new($cargs)

constructor. The argument follows:

    $cargs = {
	keyword   => "confirm",
	class     => "subscribe",
	address   => "mail@address",
	buffer    => $buffer,
	cache_dir => "/some/where",
    };

This class uses FML::Cache::Journal as database internally.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($cargs)
# Side Effects: create object
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $cargs) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };

    for my $id ('keyword', 'class', 'address', 'buffer', 'cache_dir') {
	if (defined $cargs->{ $id }) {
	    $me->{ "_$id" } = $cargs->{ $id };
	}
    }

    use FML::Cache::Journal;
    $me->{ _journal_db } = new FML::Cache::Journal $curproc;

    return bless $me, $type;
}


=head2 assign_id()

assign new id for current object.

=cut


# Descriptions: assign new id for current object.
#    Arguments: OBJ($self)
# Side Effects: update databse.
# Return Value: STR
sub assign_id
{
    my ($self)  = @_;
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

    # XXX-TODO: o.k.? $id is returned but not saved within object ?
    # 1. build id
    my $id = "$keyword $class $md5sum";

    # 2. save the time map: { MD5 => ASSIGNED_UNIX_TIME }
    $self->store_id( $md5sum );

    return $id;
}


=head2 store_id($id, $comment)

save id into databse with comment if specified.

=cut


# Descriptions: save id into database.
#    Arguments: OBJ($self) STR($id) STR($comment)
# Side Effects: update database
# Return Value: none
sub store_id
{
    my ($self, $id, $comment) = @_;
    my $class  = $self->{ _class };
    my $addr   = $self->{ _address };
    my $id_str = sprintf("%s%s", time, defined $comment ? " $comment" : '');

    my $db = $self->_open_db();

    $db->{ $id }           = $id_str;
    $db->{ "request-$id" } = "$class $addr";
    $db->{ "address-$id" } = $addr;

    $self->_close_db();
}


=head2 find($id)

find database value for $id.

=cut


# Descriptions: find value for $id.
#    Arguments: OBJ($self) STR($id)
# Side Effects: update $self->{ _found }.
# Return Value: STR
sub find
{
    my ($self, $id) = @_;
    my $found = '';

    my $db = $self->_open_db();
    if (defined $db) {
	$found = $db->{ $id } || '';
	$self->_close_db();
    }

    $self->{ _found } = $found || '';

    return $found;
}


=head2 get_request($id)

get request info for id $id.

=cut


# Descriptions: get request for id.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub get_request
{
    my ($self, $id) = @_;
    my $found = '';

    my $db = $self->_open_db();
    if (defined $db) {
	$found = $db->{ "request-$id" } || '';
	$self->_close_db();
    }

    return $found;
}


=head2 get_address($id)

get address for $id.

=cut


# Descriptions: get address for $id.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub get_address
{
    my ($self, $id) = @_;
    my $found = '';

    my $db = $self->_open_db();
    if (defined $db) {
	$found = $db->{ "address-$id" } || '';
	$self->_close_db();
    }

    return $found;
}


=head2 is_expired($id, $howold)

check if request for $id is expired or not.

=cut


# Descriptions: check if request for $id is expired or not.
#    Arguments: OBJ($self) STR($id) NUM($howold)
# Side Effects: none
# Return Value: 1 or 0
sub is_expired
{
    my ($self, $id, $howold) = @_;
    my $found = $self->find($id);
    my ($time, $comment) = split(/\s+/, $found);

    # XXX-TODO: expiration limit should be configurable.
    # expired in 2 weeks by default.
    $howold ||= 14*24*3600;

    if ((time - $time) > $howold) {
	return 1; # expired
    }
    else {
	return 0;
    }
}


=head1 Cache database

This cache uses C<FML::Cache::Journal> based on C<Tie::JournaledDir>.

=head2 _open_db()

=head2 _close_db()

=cut


# Descriptions: open cache database.
#    Arguments: OBJ($self)
# Side Effects: close db
# Return Value: HASH_REF
sub _open_db
{
    my ($self) = @_;
    my $db = $self->{ _journal_db };

    if (defined $db) {
	my $dir   = $self->{ _cache_dir };
	my $class = $self->{ _class };
	my $_db   = $db->open($dir, $class) || undef;
	$self->{ _db } = $_db;
	return $_db;
    }
    else {
	return undef;
    }
}


# Descriptions: close database interface.
#    Arguments: OBJ($self)
# Side Effects: close db
# Return Value: none
sub _close_db
{
    my ($self) = @_;
    my $db = $self->{ _journal_db };

    if (defined $db) {
	$db->close();
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Confirm first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
