#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Control.pm,v 1.5 2003/11/26 11:02:05 fukachan Exp $
#

package FML::User::Control;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;
use FML::Credential;
use FML::Restriction::Base;
use FML::Log qw(Log LogWarn LogError);
use IO::Adapter;


# XXX_LOCK_CHANNEL: recipient_map_modify
my $lock_channel = "recipient_map_modify";


#
# XXX-TODO: we use this module to add/del user anywhere.
#

my $debug = 0;


=head1 NAME

FML::User::Control - utility functions to control user list.

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
    my $reason   = '';

    # XXX check if $address is safe (persistent ?).
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	croak("unsafe address");
    }

    # pass info into reply_message()
    my $msg_args = $command_args->{ msg_args };
    $msg_args->{ _arg_address } = $address;

    my $ml_home_dir = $config->{ ml_home_dir };

    $curproc->lock($lock_channel);

  MAP:
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
		$curproc->log("add $address to map=$_map");
		$curproc->reply_message_nl('command.add_ok',
					   "$address added.",
					   $msg_args);
	    }
	    else {
		$curproc->reply_message_nl('command.add_fail',
					   "failed to add $address",
					   $msg_args);
		$reason = "fail to add $address to map=$_map";
		last MAP;
	    }
	}
	else {
	    $reason = "$address is already member (map=$_map)";
	    last MAP;
	}
    }

    $curproc->unlock($lock_channel);

    # upcall error
    if ($reason) {
	$curproc->logerror($reason);
	croak($reason);
    }

    unless ($trycount) {
	$curproc->logerror("fail to add $address");
	croak("fail to add $address");
    }

    # update user database.
    if ($curproc->is_under_mta_process()) {
	my $info_args = {
	    address => $address,
	};

	eval q{
	    use FML::User::Info;
	    my $info = new FML::User::Info $curproc;
	    $info->import_from_mail_header($curproc, $info_args);
	};
	$curproc->logerror($@) if $@;	
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
    my $reason   = '';

    # XXX check if $address is safe (persistent ?).
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	croak("unsafe address");
    }

    # pass info to reply_message()
    my $msg_args = $command_args->{ msg_args };
    $msg_args->{ _arg_address } = $address;

    my $ml_home_dir = $config->{ ml_home_dir };

    $curproc->lock($lock_channel);

  MAP:
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
		$curproc->log("remove $address from map=$_map");
		$curproc->reply_message_nl('command.del_ok',
					   "$address removed.",
					   $msg_args);
	    }
	    else {
		$curproc->reply_message_nl('command.del_fail',
					   "failed to remove $address",
					   $msg_args);
		$reason = "fail to remove $address from map=$_map";
		last MAP;
	    }
	}
	else {
	    $curproc->logwarn("no such user in map=$_map") if $debug;
	}
    }

    $curproc->unlock($lock_channel);

    # upcall error
    if ($reason) {
	$curproc->logerror($reason);
	croak($reason);
    }

    unless ($trycount) {
	$curproc->logerror("no such user $address");
	croak("no such user $address");
    }

    # update user database.
    # NOTHING TO DO.
}


# Descriptions: dispatch chaddr operation
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: none
# Return Value: none
sub user_chaddr
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $cred    = new FML::Credential $curproc;
    my $level   = $cred->get_compare_level();
    my $maplist = $uc_args->{ maplist };

    # save excursion: exatct match as could as possible.
    $cred->set_compare_level( 100 );

    $curproc->lock($lock_channel);

    for my $map (@$maplist) {
	$self->_try_chaddr_in_map($curproc, $command_args, $uc_args,
				   $cred, $map);
    }

    $curproc->unlock($lock_channel);

    # reset enironment.
    $cred->set_compare_level( $level );
}


# Descriptions: chaaddr
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
#               OBJ($cred) STR($map)
# Side Effects: update member list
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
	$curproc->logerror("$new_address is already member (map=$map)");
	return 0;
    }

    # 3. both conditions are o.k., here we go!
    # XXX-TODO: this condition is correct ?
    # XXX-TODO: we should remove old one when both old and new ones exist.
    # XXX WHICH STEP IS IT BETTER TO UPDATE LIST ?
    #  [I] 1. remove the old address only if $new_address not included.
    #      2. add the newadderss
    # [II] 1. add the newadderss
    #      2. remove the old address only if $new_address not included.
    #
    # Plan [II] is better for authentication without reader lock.
    # Consider the case the process executing chaddr is preempted, and
    # another distributing process starts to run.
    #
    if ($is_old_address_ok && $is_new_address_ok) {
	{
	    my $obj = new IO::Adapter $map, $config;
	    $obj->open();
	    $obj->add( $new_address );
	    unless ($obj->error()) {
		$curproc->log("add $new_address to map=$map");
	    }
	    else {
		$curproc->logerror("fail to add $new_address to map=$map");
	    }
	    $obj->close();
	}

	# restart map to add the new address.
	# XXX we need to restart or rewrind map.
	{
	    my $obj = new IO::Adapter $map, $config;
	    $obj->touch();

	    $obj->open();
	    $obj->delete( $old_address_in_map );
	    unless ($obj->error()) {
		$curproc->log("delete $old_address from map=$map");
	    }
	    else {
		$curproc->logerror("fail to delete $old_address to map=$map");
	    }
	    $obj->close();
	}
    }

    # update user database.
}


# Descriptions: show list
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: none
# Return Value: none
sub print_userlist
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $config  = $curproc->config();
    my $maplist = $uc_args->{ maplist };
    my $wh      = $uc_args->{ wh };
    my $style   = $curproc->get_print_style();

    $curproc->lock($lock_channel);

    for my $map (@$maplist) {
	my $obj = new IO::Adapter $map, $config;

	if (defined $obj) {
	    my $x = '';
	    my $buf;
	    $obj->open;

	  LINE:
	    while ($x = $obj->get_key_values_as_array_ref()) {
		$buf = join(" ", @$x) if ref($x) eq 'ARRAY';
		next LINE unless defined $buf;
		next LINE unless $buf;

		if ($style eq 'html') {
		    # XXX-TODO: html-ify address ?
		    print $wh $buf, "<br>\n";
		}
		# we assume text mode by default.
		else {
		    print $wh $buf, "\n";
		}
	    }
	    $obj->close;
	}
	else {
	    $curproc->logwarn("canot open $map");
	}
    }

    $curproc->unlock($lock_channel);
}


# Descriptions: return address list as ARRAY_REF
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_user_list
{
    my ($self, $curproc, $list) = @_;
    my $config = $curproc->config();
    my $r = [];

    $curproc->lock($lock_channel);

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

    $curproc->unlock($lock_channel);

    return $r;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

2003/11:23:
FML::User::Control is renamed from FML::Command::UserControl.

FML::User::Control first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
