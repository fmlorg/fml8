#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Command.pm,v 1.12 2001/10/17 10:24:25 fukachan Exp $
#

package FML::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

use FML::Command::Attribute;
@ISA = qw(FML::Command::Attribute);

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


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub DESTROY { ;}


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

    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	my $command = $pkg->new();

	if ($command->can('auth')) {
	    $command->auth($curproc, $command_args);
	}

	if ($command->can('process')) {
	    $curproc->lock() if $self->require_lock($mode, $comname);
	    $command->process($curproc, $command_args);
	    $curproc->unlock() if $self->require_lock($mode, $comname);

	    if ($command->error()) { Log($command->error());}
	}
	else {
	    LogError("${pkg} has no process method");	    
	}
    }
    else {
	LogError("$pkg module is not found");
	LogError($@);
    }
}


=head2 C<require_lock($comname)>

specifield C<command> requires lock (giant lock) ?
return 1 by default (almost all command requires lock).

=cut

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

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
