#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chaddr.pm,v 1.14 2003/03/17 13:22:24 fukachan Exp $
#

package FML::Command::Admin::chaddr;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::chaddr - change the subscribed address

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change address from old one to new one.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

change address from old one to new one.

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


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: change address from old one to new one
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config         = $curproc->{ config };
    my $member_maps    = $config->get_as_array_ref( 'member_maps' );
    my $recipient_maps = $config->get_as_array_ref( 'recipient_maps' );
    my $options        = $command_args->{ options };
    my $old_address    = '';
    my $new_address    = '';

    if (defined $command_args->{ command_data }) {
	my $x = $command_args->{ command_data };
	($old_address, $new_address) = split(/\s+/, $x);
    }
    else {
	$old_address = $options->[ 0 ];
	$new_address = $options->[ 1 ];
    }

    Log("chaddr: $old_address -> $new_address");

    # sanity check
    unless ($old_address && $new_address) {
	croak("chaddr: invalid arguments");
    }
    croak("\$member_maps is not specified")    unless $member_maps;
    croak("\$recipient_maps is not specified") unless $recipient_maps;

    # change all maps including this $address.
    my (@maps) = ();
    push(@maps, @$member_maps);
    push(@maps, @$recipient_maps);

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	old_address => $old_address,
	new_address => $new_address,
	maplist     => \@maps,
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->user_chaddr($curproc, $command_args, $uc_args);
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

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::chaddr first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
