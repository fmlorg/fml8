#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: confirm.pm,v 1.7 2002/02/17 13:29:59 fukachan Exp $
#

package FML::Command::User::confirm;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::User::confirm - allow action after confirmation

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

real process after confirmation succeeds.

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


# Descriptions: real process after confirmation succeeds.
#               run _switch_command() for real process.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $expire_limit  = $config->{ confirm_expire_limit } || 14*24*3600;
    my $command       = $command_args->{ command };

    my ($class, $id);

    # get class and id from buffer, for example,
    # "confirm subscribe 813f42fa2aa84bbba500ed3d2781dea6"
    if ($command =~ /$keyword\s+(\w+)\s+([\w\d]+)/) {
	($class, $id) = ($1, $2);
    }

    use FML::Confirm;
    my $confirm = new FML::Confirm {
	keyword   => $keyword,
	cache_dir => $cache_dir,
	class     => $class,
	buffer    => $command,
    };

    my $found = '';
    if ($found = $confirm->find($id)) { # if request is found
	unless ($confirm->is_expired($found, $expire_limit)) {
	    my $address = $confirm->get_address($id);
	    $self->_switch_command($class, $address, $curproc, $command_args);
	}
	else { # if req is expired
	    croak("request is expired");
	}
    }
    else {
	croak("no such confirmation request id=$id");
    }
}


# Descriptions: load module for real process and
#               switched to it.
#               We support only {subscribe,unsubscribe,chaddr} now.
#    Arguments: OBJ($self) STR($class) STR($address)
#               OBJ($curproc) HASH_REF($command_args)
# Side Effects: module loaded
# Return Value: none
sub _switch_command
{
    my ($self, $class, $address, $curproc, $command_args) = @_;

    # lower case
    $class =~ tr/A-Z/a-z/;

    use FML::Command;
    my $obj = new FML::Command;

    if ($class eq 'subscribe'   ||
	$class eq 'unsubscribe' ||
	$class eq 'chaddr') {
	$command_args->{ command_data } = $address;
	$command_args->{ command_mode } = 'Admin';
	$command_args->{ override_need_no_lock } = 1; # already locked
	$obj->$class($curproc, $command_args);
    }
    else {
	croak("no such rule");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::confirm appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
