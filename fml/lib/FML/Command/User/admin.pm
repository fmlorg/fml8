#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: admin.pm,v 1.3.2.1 2004/03/04 04:02:56 fukachan Exp $
#

package FML::Command::User::admin;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::User::admin - entrance for priviledged command world.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

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


# Descriptions: rewrite command prompt.
#               Always we need to rewrite command prompt to hide password.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR_REF($rbuf)
# Side Effects: rewrite buffer to hide the password phrase in $rbuf.
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_args, $rbuf) = @_;

    # XXX-TODO: good style? FML::Command::Admin::password->rewrite_prompt() ?
    use FML::Command::Admin::password;
    my $obj = new FML::Command::Admin::password;
    $obj->rewrite_prompt($curproc, $command_args, $rbuf);
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


=head2 verify_syntax($curproc, $command_args)

verify the syntax command string.
return 0 if it looks insecure.

=cut


# Descriptions: verify the syntax command string.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub verify_syntax
{
    my ($self, $curproc, $command_args) = @_;
    my $command = undef;
    my $comname = $command_args->{ comsubname };
    my $pkg     = "FML::Command::Admin::${comname}";

    eval qq{ use $pkg; \$command = new $pkg;};
    unless ($@) {
	if ($command->can('verify_syntax')) {
	    return $command->verify_syntax($curproc, $command_args);
	}
    }

    use FML::Command;
    my $dispatch = new FML::Command;
    return $dispatch->simple_syntax_check($curproc, $command_args);
}


# Descriptions: interface for priviledged command world.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update authentication state if needed.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $command = $command_args->{ original_command };

    # 1. check already authenticated. if not, try auth.
    #    authentication rules are defined as $admin_command_restrictions.
    #    XXX _try_admin_auth() needs to handle several types:
    #              1. password auth (one line).
    #              2. pgp auth      (one file).
    unless ($curproc->command_context_get_admin_auth()) {
	my $status = $self->_try_admin_auth($curproc, $command_args);
	if ($status) {
	    $curproc->reply_message_nl("command.admin_auth_ok",
				       "authenticated.");
	    $curproc->command_context_set_admin_auth();
	}
    }

    # 2. run admin command if already authenticated. 
    #    if not, fatal error.
    if ($curproc->command_context_get_admin_auth()) {
	my $class = $command_args->{ comsubname } || '';
	$self->_execute_admin_command($curproc, $command_args, $class);
    }
    else {
	$curproc->logerror("admin: not auth, cannot run \"$command\"");
	$curproc->reply_message_nl("command.admin_auth_fail",
				   "not authenticated.");
	$curproc->command_context_set_stop_process();
	croak("admin authentication failed.");
    }
}


# Descriptions: authenticate the currrent process sender as an admin.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _try_admin_auth
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $rules   = $config->get_as_array_ref('admin_command_restrictions');
    my $cred    = $curproc->{ credential };
    my $sender  = $cred->sender();
    my $optargs = { address => $sender };
    my $class   = $command_args->{ comsubname } || '';
    my $is_auth = 0;

    # XXX-TODO: configurable.
    # prepare() for later use.
    if ($class eq 'pass' || $class eq 'password') {
	$self->_execute_admin_command($curproc, $command_args, $class);
	my $p = $curproc->command_context_get_admin_password();
	$optargs->{ password } = $p || '';
    }

    use FML::Command::Auth;
    my $auth = new FML::Command::Auth;
    for my $rule (@$rules) {
	$is_auth = $auth->$rule($curproc, $optargs);

	# reject as soon as possible
	if ($is_auth eq '__LAST__') {
	    $curproc->log("admin: rejected by $rule");
	    return 0;
	}
	elsif ($is_auth) {
	    $curproc->log("admin: auth by $rule");
	    return $is_auth;
	}
	else {
	    $curproc->log("admin: not match rule=$rule");
	}
    }

    # deny transition to admin mode by default
    return 0;
}


# Descriptions: execute admin command.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR($class)
# Side Effects: none
# Return Value: none
sub _execute_admin_command
{
    my ($self, $curproc, $command_args, $class) = @_;
    my $args = $self->_prepare_command_args($curproc, $command_args);

    use FML::Command;
    my $dispatch = new FML::Command;
    $dispatch->$class($curproc, $args);
}


# Descriptions: adjust $command_args for admin mode.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub _prepare_command_args
{
    my ($self, $curproc, $command_args) = @_;

    # duplicate $command_args HASH_REF.
    my $args = {};
    for my $k (keys %$command_args) {
	$args->{ $k } = $command_args->{ $k };
    }
    $args->{ command_mode } = 'Admin';

    # we need to shift "options" by one column in admin command.
    # e.g. for "admin add some thing", 
    # options = [ add, some, thing ] => [ some, thing ]
    my @options = @{ $command_args->{ options } };
    shift @options;
    $args->{ options } = \@options;

    return $args;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::add first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
