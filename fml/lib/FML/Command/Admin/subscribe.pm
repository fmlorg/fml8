#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: subscribe.pm,v 1.18 2002/09/22 14:56:46 fukachan Exp $
#

package FML::Command::Admin::subscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::subscribe - subscribe a new member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

subscribe a new address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

subscribe a new user.

=cut


# Descriptions: constructor.
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


# Descriptions: subscribe a new user.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $command_args->{ options };
    my $address       = $command_args->{ command_data } || $options->[ 0 ];

    # fundamental check
    croak("address is not defined")           unless defined $address;
    croak("address is not specified")         unless $address;
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	address => $address,
	maplist => [ $recipient_map, $member_map ],
    };
    my $r = '';

    # XXX-TODO: we expect useradd() validates $address.
    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->useradd($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu for subscribe
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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::subscribe first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
