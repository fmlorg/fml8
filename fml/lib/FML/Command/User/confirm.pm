#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: confirm.pm,v 1.1 2001/10/11 23:57:37 fukachan Exp $
#

package FML::Command::User::confirm;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::User::confirm - allow action after confirmation

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_keyword };
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
	croak("no such confirmation request");
    }
}


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
	$command_args->{ address }      = $address;
	$command_args->{ command_mode } = 'Admin';
	$obj->$class($curproc, $command_args);
    }
    else {
	croak("no such rule");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::confirm appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
