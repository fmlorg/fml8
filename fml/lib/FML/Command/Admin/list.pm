#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: list.pm,v 1.3 2002/04/01 23:41:11 fukachan Exp $
#

package FML::Command::Admin::list;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::list - show user list(s)

=head1 SYNOPSIS

See C<FML::Command> for more detailist.

=head1 DESCRIPTION

show user list(s).

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
sub need_lock { 0;}


# Descriptions: show the user list
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config         = $curproc->{ config };
    my $member_maps    = $config->get_as_array_ref( 'member_maps' );
    my $recipient_maps = $config->get_as_array_ref( 'recipient_maps' );
    my $options        = $command_args->{ options };
    my $maplist        = $member_maps;

    for (@$options) {
	if (/^recipient|active/i) {
	    $maplist = $recipient_maps;
	}
	elsif (/^member/i) {
	    $maplist = $member_maps;
	}
	else {
	    LogWarn("list: unknown type $_");
	}
    }

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	maplist => $maplist,
	wh      => \*STDOUT,
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->userlist($curproc, $command_args, $uc_args);
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

FML::Command::Admin::list appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more detailist.

=cut


1;
