#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Info.pm,v 1.4 2005/05/27 03:03:40 fukachan Exp $
#

package FML::User::Info;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $debug $default_expire_period);
use Carp;


=head1 NAME

FML::User::Info - maintain user information.

=head1 SYNOPSIS

    use FML::User::Info;
    my $data = new FML::User::Info $curproc;
    $data->import_from_mail_header($curproc, $info);

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constuctor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($infoargs)
# Side Effects: create object
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $infoargs) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };

    use FML::User::DB;
    $me->{ _db } = new FML::User::DB $curproc;

    return bless $me, $type;
}


=head2 add($info)

top level entrance to update user database based on header
information.

=cut


# Descriptions: update user database based on header information.
#    Arguments: OBJ($self) HASH_REF($info)
# Side Effects: update db.
# Return Value: none
sub add
{
    my ($self, $info) = @_;
    my $curproc = $self->{ _curproc };
    my $address = $info->{ address };
    my $header  = $curproc->incoming_message_header();
    my $from    = $header->get('from');

    # For example, we record the following user information if could.
    # See passwd(5).
    #   class     User's login class.
    #   change    Password change time.
    #   expire    Account expiration time.
    #   gecos     General information about the user.

    # XXX-TODO: correct logic if multiple matched ?
    use Mail::Address;
    my (@addrlist) = Mail::Address->parse($from);
    for my $a (@addrlist) {
	my $gecos = $a->comment();
	if ($gecos) { $self->set_gecos($address, $gecos);}
    }

    $self->set_subscribe_date($address, time);
}


=head1 GECOS INFO MANIPULATION

=head2 set_gecos($address, $gecos)

update gecos database.

=head2 get_gecos($address)

get information from gecos database.

=cut


# Descriptions: update gecos database.
#    Arguments: OBJ($self) STR($address) STR($gecos)
# Side Effects: update gecos database
# Return Value: none
sub set_gecos
{
    my ($self, $address, $gecos) = @_;
    my $db = $self->{ _db };
    $db->add("gecos", $address, $gecos);
}


# Descriptions: get gecos info from database.
#    Arguments: OBJ($self) STR($address)
# Side Effects: update gecos database
# Return Value: none
sub get_gecos
{
    my ($self, $address) = @_;
    my $db = $self->{ _db };
    $db->get("gecos", $address);
}


=head1 "WHEN SUBSCRIBED" INFO MANIPULATION

=head2 set_subscribe_date($address, $subscribe_date)

update subscribe_date database.

=head2 get_subscribe_date($address)

get information from subscribe_date database.

=cut


# Descriptions: update subscribe_date database.
#    Arguments: OBJ($self) STR($address) STR($subscribe_date)
# Side Effects: update subscribe_date database
# Return Value: none
sub set_subscribe_date
{
    my ($self, $address, $subscribe_date) = @_;
    my $db = $self->{ _db };
    $db->add("subscribe_date", $address, $subscribe_date);
}


# Descriptions: get info from subscribe_date database.
#    Arguments: OBJ($self) STR($address)
# Side Effects: update subscribe_date database
# Return Value: none
sub get_subscribe_date
{
    my ($self, $address) = @_;
    my $db = $self->{ _db };
    $db->get("subscribe_date", $address);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::User::Info appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
