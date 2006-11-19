#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MessageID.pm,v 1.26 2006/04/18 11:14:06 fukachan Exp $
#

package FML::Header::MessageID;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $global_counter);
use Carp;

=head1 NAME

FML::Header::MessageID - manipulate message-id.

=head1 SYNOPSIS

        use FML::Header::MessageID;
        my $xargs = { directory => $dir };
        my $db    = FML::Header::MessageID->new->db_open($xargs);

        if (defined $db) {
            # we can tind the $mid in the past message-id cache ?
            $dup = $db->{ $mid };
            Log( "message-id duplicated" ) if $dup;

            # save the current id
            $db->{ $mid } = 1;
        }

=head1 DESCRIPTION

manipulate Message-Id database.

=head1 METHODS

=head2 new($args)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 db_open($db_args)

open message-id database and return HASH_REF for the db access.

=head2 db_close()

close message-id database (dummy).

=cut


# Descriptions: open message-id database.
#    Arguments: OBJ($self) HASH_REF($db_args)
# Side Effects: open database.
# Return Value: HASH_REF
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

    return undef;
}


# Descriptions: close message-id database (dummy).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub db_close
{
}


=head2 get($key)

get value for the key $key in message-id database.
return '' if not found nor defined.

=head2 set($key, $value)

set value for the key $key in message-id database.

=cut


# Descriptions: get value for $key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub get
{
    my ($self, $key) = @_;
    my $db = $self->{ _db };

    if (defined $db) {
	return( $db->{ $key } || '' );
    }
    else {
	return '';
    }
}


# Descriptions: set value for $key.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub set
{
    my ($self, $key, $value) = @_;
    my $db = $self->{ _db };

    if (defined $db) {
	$db->{ $key } = $value || '';
	return $value;
    }

    return undef;
}


=head2 gen_id($config)

generate a new message-id and return it.

=cut


# Descriptions: generate a new message-id used in reply message.
#    Arguments: OBJ($self) OBJ($config)
# Side Effects: counter increment
# Return Value: STR
sub gen_id
{
    my ($self, $config) = @_;
    my $post_addr  = $config->{ article_post_address };
    my $maintainer = $config->{ maintainer };
    my $addr       = $post_addr || $maintainer;

    $global_counter++;
    return sprintf("<%d.%d.%s.%s>", time, $$, $global_counter, $addr);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Header::MessageID first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
