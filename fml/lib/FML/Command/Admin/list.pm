#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: list.pm,v 1.2 2002/04/01 14:20:20 fukachan Exp $
#

package FML::Command::Admin::list;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


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


# Descriptions: dir
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $command_args->{ options };
    my $maplist       = [ $member_map ];

    for (@$options) {
	if (/^recipient|active/i) {
	    $maplist = [ $recipient_map ];
	}
	elsif (/^member/i) {
	    $maplist = [ $member_map ];
	}
	else {
	    $maplist = [ $member_map ];
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

=head1 NAME

FML::Command::Admin::list - list a new member

=head1 SYNOPSIS

See C<FML::Command> for more detailist.

=head1 DESCRIPTION

same as C<dir>.

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
