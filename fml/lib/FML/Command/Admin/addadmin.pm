#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: addadmin.pm,v 1.3 2002/04/03 11:32:58 fukachan Exp $
#

package FML::Command::Admin::addadmin;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::addadmin - add a new administrator

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

add a new administrator address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: addadmin a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config     = $curproc->{ config };
    my $member_map = $config->{ primary_admin_member_map };
    my $options    = $command_args->{ options };
    my $address    = $command_args->{ command_data } || $options->[ 0 ];

    # fundamental check
    croak("address is not undefined")    unless defined $address;
    croak("member_map is not undefined") unless defined $member_map;
    croak("address is not specified")    unless $address;
    croak("member_map is not specified") unless $member_map;

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	address => $address,
	maplist => [ $member_map ],
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->useradd($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: cgi menu to add a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
	use FML::CGI::Admin::User;
	my $obj = new FML::CGI::Admin::User;
	$obj->cgi_menu($curproc, $args, $command_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::addadmin appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
