#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Cache.pm,v 1.11 2003/05/28 13:24:12 fukachan Exp $
#

package FML::Error::Cache;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Error::Cache - manipulate error/bounce information database.

=head1 SYNOPSIS

	use FML::Error::Cache;
	my $db = new FML::Error::Cache $curproc;
	$db->add( $bounce_info );

where C<$bounce_info) follows:

    $bounce_info = [
            {
		address => 'rudo@nuinui.net',
		status  => '5.x.y',
		reason  => '... reason ... ',
	    },
                  ...
    ];

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self) HASH_REF($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    my $config = $curproc->config();
    my $db_dir = $config->{ error_analyzer_cache_dir };

    unless (-d $db_dir) {
	$curproc->mkdir($db_dir, "mode=private");
    }

    return bless $me, $type;
}


=head2 open()

dummy.

=head2 close()

dummy.

=head2 touch()

dummy.

=cut


# Descriptions: none
#    Arguments: none
# Side Effects: none
# Return Value: none
sub open  { 1;}

# Descriptions: none
#    Arguments: none
# Side Effects: none
# Return Value: none
sub close { 1;}

# Descriptions: none
#    Arguments: none
# Side Effects: none
# Return Value: none
sub touch { 1;}


=head2 add($address, $argv) 

add data given as hash reference $argv.

    $argv = {
	address => STR,
	reason  => STR,
	status  => STR,
    };

C<Tie::JournaledDir> is a simple hash, so $argv is converted to the
following a set of key ($address) and value.

     $address => "$unixtime status=$status reason=$reason"

=cut


# Descriptions: add bounce info into cache.
#    Arguments: OBJ($self) STR($address) HASH_REF($argv)
# Side Effects: update cache
# Return Value: none
sub add
{
    my ($self, $address, $argv) = @_;

    $self->_open_cache();

    my $db = $self->{ _db };
    if (defined $db) {
	my ($reason, $status);
	my $unixtime = time;

	if (ref($argv) eq 'HASH') {
	    $reason = $argv->{ reason } || 'unknown';
	    $status = $argv->{ status } || 'unknown';
	    $status =~ s/\s+/_/g;
	    $reason =~ s/\s+/_/g;
	}
	else {
	    LogError("FML::Error::Cache: add: not implemented \$argv type");
	    return undef;
	}

	if ($address) {
	    $db->{ $address } = "$unixtime status=$status reason=$reason";
	}
	else {
	    LogWarn("FML::Error::Cache: add: invalid data");
	}

	$self->_close_cache();
    }
    else {
	croak("FML::Error::Cache: add: unknown data input type");
    }
}


=head2 delete($address)

delete entry for $address.

=cut


# Descriptions: delete entry for $address.
#    Arguments: OBJ($self) STR($address)
# Side Effects: update cache
# Return Value: none
sub delete
{
    my ($self, $address) = @_;

    $self->_open_cache();

    my $db = $self->{ _db };
    if (defined $db) {
	if ($address) {
	    delete $db->{ $address };
	}
	else {
	    LogWarn("FML::Error::Cache: delete: invalid data");
	}

	$self->_close_cache();
    }
    else {
	croak("FML::Error::Cache: delete: unknown data input type");
    }
}


=head1 CACHE IO MANIPULATION

You need to use primitive methods this class provides for IO into/from
error data cache.

C<Tie::JournaledDir> is a simple hash, so $argv is converted to the
following a set of key ($address) and value.

     $address => "$unixtime status=$status reason=$reason"

=cut


# Descriptions: open the cache database for File::CacheDir.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub _open_cache
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };
    my $type    = $config->{ error_analyzer_cache_type };
    my $dir     = $config->{ error_analyzer_cache_dir  };
    my $mode    = $config->{ error_analyzer_cache_mode } || 'temporal';
    my $days    = $config->{ error_analyzer_cache_size } || 14;

    use Tie::JournaledDir;

    # tie style
    my %db = ();
    tie %db, 'Tie::JournaledDir', { dir => $dir };
    $self->{ _db } = \%db;
}


# Descriptions: destruct tied hash.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _close_cache
{
    my ($self) = @_;
    my $db = $self->{ _db };

    if (defined $db) {
	untie %$db;
    }
}


=head1 UTILITY FUNCTIONS

=head2 get_primary_keys()

return primary keys in cache as ARRAY_REF.

=cut


# Descriptions: return (primary) key list in cache database.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_primary_keys
{
    my ($self) = @_;

    $self->_open_cache();

    my $db   = $self->{ _db };
    my @addr = keys %$db;

    $self->_close_cache();

    return \@addr;
}


# Descriptions: get all values as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_all_values_as_hash_ref
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $dir     = $config->{ error_analyzer_cache_dir  };

    use Tie::JournaledDir;
    my $obj = new Tie::JournaledDir { dir => $dir };
    return $obj->get_all_values_as_hash_ref();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error::Cache first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
