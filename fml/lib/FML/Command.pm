#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Command.pm,v 1.4 2001/04/03 09:45:40 fukachan Exp $
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

C<FML::Commands> is a wrapper and dispathcer for fml commands.
AUTOLOAD() picks up the command request and dispatches
C<FML::Command::somoting> for the request.

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
    my ($self, $curproc, $args) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my $command = $AUTOLOAD;
    $command =~ s/.*:://;

    my $pkg = "FML::Command::${command}";

    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	if ($pkg->can($command)) {
	    $curproc->lock() if $self->require_lock($command);
	    $pkg->$command($curproc, $args);
	    $curproc->unlock() if $self->require_lock($command);
	}
	else {
	    Log("$pkg module has no $command method");	    
	}
    }
    else {
	Log("$pkg module is not found");
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
