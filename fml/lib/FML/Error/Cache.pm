#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Cache.pm,v 1.22 2004/05/22 06:19:52 fukachan Exp $
#

package FML::Error::Cache;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

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

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    my $config = $curproc->config();
    my $db_dir = $config->{ error_mail_analyzer_cache_dir };

    unless (-d $db_dir) {
	$curproc->mkdir($db_dir, "mode=private");
    }

    use Tie::JournaledDir;
    my $obj = new Tie::JournaledDir { dir => $db_dir };
    $obj->expire();

    return bless $me, $type;
}


=head2 open()

dummy.

=head2 close()

dummy.

=head2 touch()

dummy.

=cut


# Descriptions: dummy.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub open  { 1;}

# Descriptions: dummy.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub close { 1;}

# Descriptions: dummy.
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
    my $curproc = $self->{ _curproc };

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
	    my $s = "FML::Error::Cache: unknown type: \$argv";
	    $curproc->logerror($s);
	    return undef;
	}

	if ($address) {
	    if ($self->_is_valid_address($address)) {
		$db->{ $address } = "$unixtime status=$status reason=$reason";
	    }
	    else {
		$curproc->logwarn("FML::Error::Cache: add: invalid address");
	    }
	}
	else {
	    $curproc->logwarn("FML::Error::Cache: add: invalid data");
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
    my $curproc = $self->{ _curproc };

    $self->_open_cache();

    my $db = $self->{ _db };
    if (defined $db) {
	if ($address) {
	    if ($self->_is_valid_address($address)) {
		delete $db->{ $address };
	    }
	    else {
		croak("FML::Error::Cache: delete: invalid address");
	    }
	}
	else {
	    $curproc->logwarn("FML::Error::Cache: delete: invalid data");
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


# Descriptions: open the cache database for Tie::Journaled*.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub _open_cache
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $dir     = $config->{ error_mail_analyzer_cache_dir  };

    # parameters.
    my %db   = ();
    my $type = $config->{ error_mail_analyzer_cache_type };
    my $mode = $config->{ error_mail_analyzer_cache_mode } || 'temporal';
    my $days = $config->{ error_mail_analyzer_cache_size } || 14;
    my $args = {
	dir   => $dir,
	unit  => 'day',
	limit => $days,
    };

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', $args;
    $self->{ _db } = \%db;
}


# Descriptions: destruct tied hash.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _close_cache
{
    my ($self) = @_;
    my $db     = $self->{ _db };

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
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $dir     = $config->{ error_mail_analyzer_cache_dir };

    use Tie::JournaledDir;
    my $obj = new Tie::JournaledDir { dir => $dir };
    return $obj->get_all_values_as_hash_ref();
}


# Descriptions: check if the address is valid string?
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM
sub _is_valid_address
{
    my ($self, $address) = @_;

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    if ($safe->regexp_match('address', $address)) {
	return 1;
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

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error::Cache first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
