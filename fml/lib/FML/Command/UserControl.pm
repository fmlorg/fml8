#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: UserControl.pm,v 1.27 2003/02/15 02:25:40 fukachan Exp $
#

package FML::Command::UserControl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;
use FML::Credential;
use FML::Restriction::Base;
use FML::Log qw(Log LogWarn LogError);
use IO::Adapter;

#
# XXX-TODO: we use this module to add/del user anywhere.
#

my $debug = 0;


=head1 NAME

FML::Command::UserControl - utility functions to control user list.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

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


# Descriptions: add user
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: update maps
# Return Value: none
sub useradd
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $config   = $curproc->config();
    my $address  = $uc_args->{ address };
    my $maplist  = $uc_args->{ maplist };
    my $trycount = 0;

    # XXX check if $address is safe (persistent ?).
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	croak("unsafe address");
    }

    # pass info into reply_message()
    my $msg_args = $command_args->{ msg_args };
    $msg_args->{ _arg_address } = $address;

    my $ml_home_dir = $config->{ ml_home_dir };
    for my $map (@$maplist) {
	my $_map = $map;
	$_map =~ s@$ml_home_dir@\$ml_home_dir@;
	$_map =~ s/file://;

	my $cred = new FML::Credential $curproc;

	# exatct match as could as possible.
	$cred->set_compare_level( 100 );

	unless ($cred->has_address_in_map($map, $config, $address)) {
	    $msg_args->{ _arg_map } = $curproc->which_map_nl($map);

	    $trycount++;

	    my $obj = new IO::Adapter $map, $config;
	    $obj->touch(); # create a new map entry (e.g. file) if needed.
	    $obj->add( $address );
	    unless ($obj->error()) {
		Log("add $address to map=$_map");
		$curproc->reply_message_nl('command.add_ok',
					   "$address added.",
					   $msg_args);
	    }
	    else {
		$curproc->reply_message_nl('command.add_fail',
					   "failed to add $address",
					   $msg_args);
		croak("fail to add $address to map=$_map");
	    }
	}
	else {
	    croak( "$address is already member (map=$_map)" );
	    return undef;
	}
    }

    unless ($trycount) {
	LogError("no trail to add $address");
    }
}


# Descriptions: remove user
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: update maps
# Return Value: none
sub userdel
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $config   = $curproc->config();
    my $address  = $uc_args->{ address };
    my $maplist  = $uc_args->{ maplist };
    my $trycount = 0;

    # XXX check if $address is safe (persistent ?).
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	croak("unsafe address");
    }

    # pass info to reply_message()
    my $msg_args = $command_args->{ msg_args };
    $msg_args->{ _arg_address } = $address;

    my $ml_home_dir = $config->{ ml_home_dir };
    for my $map (@$maplist) {
	my $_map = $map;
	$_map =~ s@$ml_home_dir@\$ml_home_dir@;
	$_map =~ s/file://;

	my $cred = new FML::Credential $curproc;

	# exatct match as could as possible.
	$cred->set_compare_level( 100 );

	if ($cred->has_address_in_map($map, $config, $address)) {
	    # $address may differ matched address in case.
	    # we need to use $address_in_map which is the matched string.
	    my $address_in_map = $cred->matched_address();

	    $msg_args->{ _arg_map } = $curproc->which_map_nl($map);

	    $trycount++;

	    my $obj = new IO::Adapter $map, $config;
	    $obj->delete( $address_in_map );
	    unless ($obj->error()) {
		Log("remove $address from map=$_map");
		$curproc->reply_message_nl('command.del_ok',
					   "$address removed.",
					   $msg_args);
	    }
	    else {
		$curproc->reply_message_nl('command.del_fail',
					   "failed to remove $address",
					   $msg_args);
		croak("fail to remove $address from map=$_map");
	    }
	}
	else {
	    LogWarn("no such user in map=$_map") if $debug;
	}
    }

    unless ($trycount) {
	LogError("no trail to remove $address");
    }
}


# Descriptions: 
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: 
# Return Value: none
sub user_chaddr
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $cred    = new FML::Credential $curproc;
    my $level   = $cred->get_compare_level();
    my $maplist = $uc_args->{ maplist };

    # save excursion: exatct match as could as possible.
    $cred->set_compare_level( 100 );

    for my $map (@$maplist) {
	$self->_try_chaddr_in_map($curproc, $command_args, $uc_args, 
				   $cred, $map);
    }

    # reset enironment.
    $cred->set_compare_level( $level );
}


# Descriptions: 
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: 
# Return Value: none
sub _try_chaddr_in_map
{
    my ($self, $curproc, $command_args, $uc_args, $cred, $map) = @_;
    my $config      = $curproc->config();
    my $old_address = $uc_args->{ old_address };
    my $new_address = $uc_args->{ new_address };

    # 
    my $is_old_address_ok  = 0;
    my $is_new_address_ok  = 0;
    my $old_address_in_map = '';

    # 1. old address exists
    #   XXX the case of $old_address may differ in this map, so
    #   XXX we need to hold the matched address(e.g. x@a.b vs x@A.B).
    if ($cred->has_address_in_map($map, $config, $old_address)) {
	$is_old_address_ok  = 1;
	$old_address_in_map = $cred->matched_address();
    }

    # 2. new address NOT EXISTS
    unless ($cred->has_address_in_map($map, $config, $new_address)) { 
	$is_new_address_ok = 1;
    }
    else {
	LogError("$new_address is already member (map=$map)");
	return 0;
    }

    # 3. both conditions are o.k., here we go!
    # XXX-TODO: this condition is correct ?
    # XXX-TODO: we should remove old one when both old and new ones exist.
    if ($is_old_address_ok && $is_new_address_ok) {
	# remove the old address only if $new_address not included.
	{
	    my $obj = new IO::Adapter $map, $config;
	    $obj->touch();

	    $obj->open();
	    $obj->delete( $old_address_in_map );
	    unless ($obj->error()) {
		Log("delete $old_address from map=$map");
	    }
	    else {
		croak("fail to delete $old_address to map=$map");
	    }
	    $obj->close();	
	}

	# restart map to add the new address.
	# XXX we need to restart or rewrind map.
	{
	    my $obj = new IO::Adapter $map, $config;
	    $obj->open();
	    $obj->add( $new_address );
	    unless ($obj->error()) {
		Log("add $new_address to map=$map");
	    }
	    else {
		croak("fail to add $new_address to map=$map");
	    }
	    $obj->close();
	}
    }
}


# Descriptions: show list
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: none
# Return Value: none
sub userlist
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $config  = $curproc->config();
    my $maplist = $uc_args->{ maplist };
    my $wh      = $uc_args->{ wh };
    my $style   = $curproc->get_print_style();

    for my $map (@$maplist) {
	my $obj = new IO::Adapter $map, $config;

	if (defined $obj) {
	    my $x = '';
	    $obj->open;
	    while ($x = $obj->get_next_key()) {
		if ($style eq 'html') {
		    # XXX-TODO: html-ify address ?
		    print $wh $x, "<br>\n";
		}
		# we assume text mode by default.
		else {
		    print $wh $x, "\n";
		}
	    }
	    $obj->close;
	}
	else {
	    LogWarn("canot open $map");
	}
    }
}


# Descriptions: return address list as ARRAY_REF
#    Arguments: OBJ($self) ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_user_list
{
    my ($self, $curproc, $list) = @_;
    my $config = $curproc->config();
    my $r = [];

    for my $map (@$list) {
	my $io  = new IO::Adapter $map, $config;
	my $key = '';
	if (defined $io) {
	    $io->open();
	    while (defined($key = $io->get_next_key())) {
		push(@$r, $key);
	    }
	    $io->close();
	}
    }

    return $r;
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

FML::Command::UserControl first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
