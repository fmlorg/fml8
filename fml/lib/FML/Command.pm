#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Command.pm,v 1.8 2001/10/08 15:51:56 fukachan Exp $
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
    my ($self, $curproc, $optargs) = @_;
    my $mode = $optargs->{ 'command_mode' } =~ /admin/i ? 'Admin' : 'User';

    return if $AUTOLOAD =~ /DESTROY/;

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;
    my $pkg = "FML::Command::${mode}::${comname}";

    Log("AUTOLOAD->load $pkg") if $0 =~ /loader/; # debug

    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	my $command = $pkg->new();

	if ($command->can('auth')) {
	    $command->auth($curproc, $optargs);
	}

	if ($command->can('process')) {
	    $curproc->lock() if $self->require_lock($comname);
	    $command->process($curproc, $optargs);
	    $curproc->unlock() if $self->require_lock($comname);

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


=head2 C<require_lock(command)>

specifield C<command> requires lock (giant lock) ?
return 1 by default (almost all command requires lock).

=cut

sub require_lock
{
    my ($self, $command) = @_;
    $command eq 'newml' ? 0 : 1;
}


=head2 C<error_nl()>

=cut

sub error_nl
{
    my ($self) = @_;
    return undef;
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
