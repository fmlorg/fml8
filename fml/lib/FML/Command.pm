#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Command.pm,v 1.25 2002/04/07 05:35:08 fukachan Exp $
#

package FML::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command - fml command dispatcher

=head1 SYNOPSIS

    use FML::Command;
    my $obj = new FML::Command;
    $obj->rewrite_prompt($curproc, $command_args, \$orig_command);

=head1 DESCRIPTION

C<FML::Command> is a wrapper and dispathcer for fml commands.
AUTOLOAD() picks up the command request and dispatches
C<FML::Command::User::somoting> suitable for the request.
Also, C<FML::Command::Admin::somoting> for the admin command request
and makefml commands.

=head1 METHODS

=head2 C<new()>

ordinary constructor.

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


=head2 C<rewrite_prompt($curproc, $command_args, $rbuf)>

rewrite the specified buffer $rbuf (STR_REF).
$rbuf is rewritten as a result.
For example, this function is used to hide the password in the $rbuf
buffer.

=cut


# Descriptions: rewrite prompt buffer
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR_REF($rbuf)
# Side Effects: none
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_args, $rbuf) = @_;
    my $command = undef;
    my $comname = $command_args->{ comname };
    my $mode    = 
	$command_args->{'command_mode'} =~ /admin/i ? 'Admin' : 'User';
    my $pkg     = "FML::Command::${mode}::${comname}";

    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	if ($command->can('rewrite_prompt')) {
	    $command->rewrite_prompt($curproc, $command_args, $rbuf);
	}
    }
}


=head2 C<AUTOLOAD()>

the command dispatcher.
It hooks up the C<command> request and loads the module in
C<FML::Command::command>.

=cut


# Descriptions: run FML::Command::XXX:YYY()
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: load appropriate module
# Return Value: none
sub AUTOLOAD
{
    my ($self, $curproc, $command_args) = @_;

    # we need to ignore DESTROY()
    return if $AUTOLOAD =~ /DESTROY/;

    # user mode by default
    # XXX IMPORTANT: user mode if the given mode is invalid.
    my $mode = 'User';
    if (defined $command_args->{ command_mode }) {
	$mode =
	    $command_args->{ command_mode } =~ /admin/i ? 'Admin' : 'User';
    }

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;
    my $pkg = "FML::Command::${mode}::${comname}";

    Log("load $pkg") if $0 =~ /loader/; # debug

    my $command = undef;
    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	my $need_lock = 1; # default.

	# we need to authenticate this ?
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
	else {
	    LogError("${pkg} has no need_lock method");
	    $curproc->reply_message("Error: invalid command definition\n");
	    $curproc->reply_message("       need_lock() is undefined\n");
	    $curproc->reply_message("       Please contact the maintainer\n");
	}

	# run the actual process
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
	LogError($@) if $@;
	LogError("$pkg module is not found");
	croak("$pkg module is not found"); # upcall to FML::Process::Command
    }
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
