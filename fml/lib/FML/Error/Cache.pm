#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Cache.pm,v 1.7 2002/12/18 04:23:41 fukachan Exp $
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

=head2 C<new()>

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


# Descriptions: add bounce info into cache.
#    Arguments: OBJ($self) HASH_REF($info)
# Side Effects: update cache
# Return Value: none
sub add
{
    my ($self, $info) = @_;

    $self->_open_cache();

    my $db = $self->{ _db };
    if (defined $db) {
	my ($address, $reason, $status);
	my $unixtime = time;

	$address = $info->{ address };
	$reason  = $info->{ reason } || 'unknown';
	$status  = $info->{ status } || 'unknown';

	if ($address) {
	    $status =~ s/\s+/_/g;
	    $reason =~ s/\s+/_/g;
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


# Descriptions: return key list in db.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_addr_list
{
    my ($self) = @_;

    $self->_open_cache();

    my $db   = $self->{ _db };
    my @addr = keys %$db;

    $self->_close_cache();

    return \@addr;
}


# Descriptions: return new Tie::JournaledDir object.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub _new
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };
    my $type    = $config->{ error_analyzer_cache_type };
    my $dir     = $config->{ error_analyzer_cache_dir  };
    my $mode    = $config->{ error_analyzer_cache_mode } || 'temporal';
    my $days    = $config->{ error_analyzer_cache_size } || 14;

    #
    # XXX-TODO: this _new() method is required ?
    #
    use Tie::JournaledDir;
    return new Tie::JournaledDir { dir => $dir };
}


# Descriptions: get all values as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_all_values_as_hash_ref
{
    my ($self) = @_;
    my $obj = $self->_new();

    $obj->get_all_values_as_hash_ref();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error::Cache first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
