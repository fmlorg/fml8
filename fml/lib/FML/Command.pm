#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Command.pm,v 1.19 2002/02/17 03:13:47 fukachan Exp $
#

package FML::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command - dispacher of fml commands

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Command> is a wrapper and dispathcer for fml commands.
AUTOLOAD() picks up the command request and dispatches
C<FML::Command::User::somoting> for the request.
Also, C<FML::Command::Admin::somoting> for the admin command request.

=head1 METHODS

=head2 C<new()>

ordinary constructor.

=head2 C<AUTOLOAD()>

dispatcher.
It hooks up the C<command> request and loads the module
C<FML::Command::command>.

=cut


# Descriptions: ordinary constructor
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


# Descriptions: ordinary destructor
#    Arguments: none
# Side Effects: none
# Return Value: none
sub DESTROY { ;}


# Descriptions: run FML::Command::XXX:YYY()
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: load appropriate module
# Return Value: none
sub AUTOLOAD
{
    my ($self, $curproc, $command_args) = @_;
    my $mode = 'User';

    return if $AUTOLOAD =~ /DESTROY/;

    if (defined $command_args->{ 'command_mode' }) {
	$mode = $command_args->{'command_mode'} =~ /admin/i ? 'Admin' : 'User';
    }

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;
    my $pkg = "FML::Command::${mode}::${comname}";

    Log("load $pkg") if $0 =~ /loader/; # debug

    my $command = undef;
    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	my $need_lock = 1; # default.

	if ($command->can('auth')) {
	    $command->auth($curproc, $command_args);
	}

	# this command needs lock (currently giant lock) ?
	if ($command->can('need_lock')) {
	    $need_lock = $command->need_lock($mode);

	    # override lock()
	    if (defined $command_args->{ override_need_no_lock }) {
		$need_lock = 0 if $command_args->{ override_need_no_lock };
	    }
	}

	if ($command->can('process')) {
	    $curproc->lock()   if $need_lock;
	    $command->process($curproc, $command_args);
	    $curproc->unlock() if $need_lock;
	}
	else {
	    LogError("${pkg} has no process method");
	}
    }
    else {
	LogError("$pkg module is not found");
	LogError($@) if $@;
	croak("$pkg module is not found"); # upcall to FML::Process::Command
    }
}


=head2 C<require_lock($comname)>

specifield C<command> requires lock (giant lock) ?
return 1 by default (almost all command requires lock).

=cut


# Descriptions: we need lock or not
#    Arguments: OBJ($self) STR($mode) STR($comname)
# Side Effects: none
# Return Value: 1 / 0 / undef
sub require_lock
{
    my ($self, $mode, $comname) = @_;

    my $r = $self->get_attribute($mode, $comname, 'require_lock');

    if ($0 =~ /loader/) {
	Log("get_attribute($mode, $comname, 'require_lock') = $r");
    }

    return $r;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
