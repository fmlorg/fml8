#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Body.pm,v 1.5 2006/07/09 12:11:11 fukachan Exp $
#

package FML::Body;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Body - operations for mail body.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: checksum of mail body part.
#               return 1 if the same checksum is found in the database.
#    Arguments: OBJ($self) OBJ($config)
# Side Effects: update database.
# Return Value: NUM
sub check_body_checksum
{
    my ($self, $config) = @_;
    my $curproc   = $self->{ _curproc };
    my $body_file = $curproc->incoming_message_print_body_as_file();

    # calculate checksum of $body_file.
    use Mail::Message::Checksum;
    my $cksum = new Mail::Message::Checksum;
    my $md5   = $cksum->md5_file($body_file);

    # compare md5 value with the checksum database.
    my $retval = 0;
    my $db_dir = $config->{ incoming_mail_body_checksum_cache_dir };
    my $db     = $self->db_open( { directory => $db_dir } );
    if (defined $db) {
	if ($db->{ $md5 }) {
	    $retval = 1;
	}
	else {
	    $db->{ $md5 } = time;
	    $retval = 0;
	}
	$self->db_close();
    }
    return $retval;
}


=head1 DATABASE

=head2 db_open($db_args)

open database (journalized db).

=head2 db_close($db_args)

dummy.

=cut


# Descriptions: open database.
#    Arguments: OBJ($self) HASH_REF($db_args)
# Side Effects: open database.
# Return Value: HASH_ERF
sub db_open
{
    my ($self, $db_args) = @_;
    my $dir  = $db_args->{ 'directory' } || '';
    my $mode = 'temporal';
    my $days = 14;

    if ($dir) {
	unless (-d $dir) {
	    # XXX-TODO: dir_mode is hard-coded ?
	    my $dir_mode = $self->{ _dir_mode } || 0700;

	    use File::Path;
	    mkpath( [ $dir ], 0, $dir_mode );
	}

	my %db = ();
	use Tie::JournaledDir;
	tie %db, 'Tie::JournaledDir', { dir => $dir };

	$self->{ _db } = \%db;
	return \%db;
    }
    else {
	my $curproc = $self->{ _curproc };
	$curproc->logerror("FML::Body: db_open: directory unspecified");
    }

    return undef;
}


# Descriptions: dummy.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub db_close
{
    ;
}


=head1 ACCESS METHODS

=head2 set_checksum_type($type)

set checksum method type.

=head2 get_checksum_type()

get checksum method type.
return 'md5' by default.

=cut


my $global_default_checksum_type = 'md5';


# Descriptions: set checksum method type.
#    Arguments: OBJ($self) STR($type)
# Side Effects: update $self
# Return Value: none
sub set_checksum_type
{
    my ($self, $type) = @_;

    if ($type eq 'md5') {
	$self->{ _type } = $type;
    }
    else {
	my $curproc = $self->{ _curproc };
	$curproc->logerror("FML::Body: unsupported checksum: $type");
    }
}


# Descriptions: return checksum method type.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_checksum_type
{
    my ($self) = @_;

    return( $self->{ _type } || $global_default_checksum_type );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Body appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
