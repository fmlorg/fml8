#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.7 2003/01/01 02:06:22 fukachan Exp $
#

package FML::Data::Deadline;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Data::Deadline - maintain data with expiration.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

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


=head2 add($key, $value)

=cut


# Descriptions: add { $key => $value }.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub add
{
    my ($self, $key, $value) = @_;
    my $class = $self->{ _class };
    my $addr  = $self->{ _address };

    # update database.
    my $db    = $self->_open_db();
    $db->{ $key } = sprintf("%s submitted_time=%s", $value, time);
    $self->_close_db();
}


=head2 find($key)

find value for $key not expired yet.

=cut


# Descriptions: find value for $key
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub find
{
    my ($self, $key) = @_;

    if ($self->is_expired($key)) {
	return '';
    }
    else {
	# search
	my $db    = $self->_open_db();
	my $found = $db->{ $key } || '';
	$self->_close_db();

	($found)  = split(/\s+/, $found);
	return( $found || '' );
    }
}


=head2 is_expired($key)

check if $key is is_expired.

=cut


# Descriptions: check if $key is is_expired
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_expired
{
    my ($self, $key) = @_;
    my $now = time;

    # get value
    my $db    = $self->_open_db();
    my $found = $db->{ $key } || '';
    $self->_close_db();

    my ($xkey, $time)  = split(/\s+/, $found);
    if ($time > $now) {
	return 1;
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
    my $db    = $self->{ _journal_db };
    my $dir   = $self->{ _cache_dir };
    my $class = $self->{ _class };
    my $_db   = $db->open($dir, $class);

    $self->{ _db } = $_db;
    return $_db;
}


# Descriptions: close database interface.
#    Arguments: OBJ($self)
# Side Effects: close db
# Return Value: none
sub _close_db
{
    my ($self) = @_;
    my $db = $self->{ _journal_db };
    $db->close();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Data::Deadline appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
