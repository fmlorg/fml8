   #-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Command.pm,v 1.43 2004/01/22 12:35:35 fukachan Exp $
#

# XXX
# XXX FML::Command should be simple since all program uses this wrapper.
# XXX So, complicated checks are moved to FML::Process::* and each module.
# XXX

package FML::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


my $debug = 0;


=head1 NAME

FML::Command - fml command dispatcher

=head1 SYNOPSIS

    use FML::Command;
    my $obj = new FML::Command;
    $obj->rewrite_prompt($curproc, $command_args, \$orig_command);

=head1 DESCRIPTION

C<FML::Command> is a wrapper and dispathcer for fml commands.
AUTOLOAD() picks up the command request and dispatches
C<FML::Command::User::something> suitable for the request.
Also, it kicks off C<FML::Command::Admin::something> for the admin
command request and makefml commands.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
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


# Descriptions: destructor (dummy).
#    Arguments: none
# Side Effects: none
# Return Value: none
sub DESTROY { ;}


=head2 set_mode($curproc, $command_args)

set the current mode, either of "admin" or "user".

=head2 get_mode($curproc, $command_args)

return the current mode, either of "admin" or "user".

=cut


# Descriptions: set the current mode, either of "admin" or "user".
#               set 'user' mode if invalid mode specified.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR($mode)
# Side Effects: none
# Return Value: STR
sub set_mode
{
    my ($self, $curproc, $command_args, $mode) = @_;

    # always 'user' if invalid mode specified.
    # XXX use capital letter for module name used latter.
    if ($mode =~ /admin/i) {
	$command_args->{'command_mode'} = 'Admin';
    }
    else {
	$command_args->{'command_mode'} = 'User';
    }
}


# Descriptions: return the current mode, either of "admin" or "user".
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: STR
sub get_mode
{
    my ($self, $curproc, $command_args) = @_;

    # XXX use capital letter for module name used latter.
    if ($command_args->{'command_mode'} =~ /admin/i) {
	return 'Admin';
    }
    else {
	return 'User';
    }
}


=head1 METHODS

=head2 rewrite_prompt($curproc, $command_args, $rbuf)

rewrite the specified buffer $rbuf (STR_REF).
$rbuf is rewritten as a result.
For example, this function is used to hide the password in the $rbuf
buffer.

Each module such as C<FML::Command::$MODE::$SOMETING> specifies
how to rewrite by rewrite_prompt() method in it.

=cut


# Descriptions: rewrite prompt buffer
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) STR_REF($rbuf)
# Side Effects: none
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_args, $rbuf) = @_;
    my $command = undef;
    my $comname = $command_args->{ comname };
    my $mode    = $self->get_mode($curproc, $command_args);
    my $pkg     = "FML::Command::${mode}::${comname}";

    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	if ($command->can('rewrite_prompt')) {
	    $command->rewrite_prompt($curproc, $command_args, $rbuf);
	}
	else {
	    $curproc->logerror("$pkg not support rewrite_prompt()") if $debug;
	}
    }
    else {
	if ($debug) {
	    $curproc->logerror("cannot load $pkg");
	    $curproc->logerror($@);
	}
    }
}



=head2 notice_cc_recipient($curproc, $command_args, $rbuf)

return addresses to inform for the command reply.

Each module such as C<FML::Command::$MODE::$SOMETING> specifies
recipients by notice_cc_recipient() method in it.

=cut


# Descriptions: return addresses to inform
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: ARRAY_REF
sub notice_cc_recipient
{
    my ($self, $curproc, $command_args) = @_;
    my $command = undef;
    my $comname = $command_args->{ comname };
    my $mode    = $self->get_mode($curproc, $command_args);
    my $pkg     = "FML::Command::${mode}::${comname}";

    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	if ($command->can('notice_cc_recipient')) {
	    $command->notice_cc_recipient($curproc, $command_args);
	}
    }
}


=head2 AUTOLOAD()

the command dispatcher.
It hooks up the C<$command> request and loads the module in
C<FML::Command::$MODE::$command>.

=cut


# Descriptions: run FML::Command::XXX:YYY()
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: load appropriate module
# Return Value: none
sub AUTOLOAD
{
    my ($self, $curproc, $command_args) = @_;
    my $myname               = $curproc->myname();
    my $default_lock_channel = 'command_serialize';

    # we need to ignore DESTROY()
    return if $AUTOLOAD =~ /DESTROY/;

    # user mode by default
    # XXX IMPORTANT: user mode if the given mode is invalid.
    my $mode = 'User';
    if (defined $command_args->{ command_mode }) {
	$mode = $self->get_mode($curproc, $command_args);
    }

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;
    my $pkg = "FML::Command::${mode}::${comname}";

    $curproc->log("load $pkg") if $myname eq 'loader'; # debug

    my $command = undef;
    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	my $need_lock    = 0; # no lock by default.
	my $lock_channel = $default_lock_channel;

	# we need to authenticate this ?
	if ($command->can('auth')) {
	    $command->auth($curproc, $command_args);
	}

	if ($command->can('check_limit')) {
	    my $n = $command->check_limit($curproc, $command_args);
	    if ($n) { croak("exceed limit");}
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
	    $curproc->logerror("${pkg} has no need_lock method");
	    $curproc->reply_message("Error: invalid command definition\n");
	    $curproc->reply_message("       need_lock() is undefined\n");
	    $curproc->reply_message("       Please contact the maintainer\n");
	}

	if ($command->can('lock_channel')) {
	    $lock_channel = $command->lock_channel() || $default_lock_channel;
	}

	# run the actual process
	if ($command->can('process')) {
	    $curproc->lock($lock_channel)   if $need_lock;
	    $command->process($curproc, $command_args);
	    $curproc->unlock($lock_channel) if $need_lock;
	}
	else {
	    $curproc->logerror("${pkg} has no process method");
	}
    }
    else {
	$curproc->logerror($@) if $@;
	$curproc->logerror("$pkg module is not found");
	croak("$pkg module is not found"); # upcall to FML::Process::Command
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
