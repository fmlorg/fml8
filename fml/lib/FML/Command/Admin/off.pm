#-*- perl -*-
#
#  Copyright (C) 2002 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: off.pm,v 1.2 2002/09/11 23:18:08 fukachan Exp $
#

package FML::Command::Admin::off;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::off - change off mode specified member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change off mode specified member

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


# Descriptions: change off mode specified member
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my @recipient_map = split(/\s+/, $config->{ recipient_maps });
    my $options       = $command_args->{ options };
    my $address       = $command_args->{ command_data } || $options->[ 0 ];

    # fundamental check
    croak("address is not specified")         unless defined $address;
    croak("\@recipient_map is not specified") unless @recipient_map;

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	address => $address,
	maplist => [ @recipient_map ],
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->userdel($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu for off
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
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

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2002 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::off first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
