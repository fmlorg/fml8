#-*- perl -*-
#
# Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Configure.pm,v 1.65 2004/04/23 04:10:36 fukachan Exp $
#

package FML::Process::Configure;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Configure -- makefml main functions.

=head1 SYNOPSIS

    use FML::Process::Configure;
    $curproc = new FML::Process::Configure;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Configure provides the main function for C<makefml>.

See C<FML::Process::Flow> for the flow detail.

=head1 METHODS

=head2 new($args)

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 prepare($args)

fix @INC, adjust ml_* and load configuration files.

=head2 verify_request($args)

show help if needed.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: adjust ml_* and load configuration files.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'makefml_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();
    $curproc->log_message_init();

    $eval = $config->get_hook( 'makefml_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: check @ARGV, call help() if needed.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP if arguments are invalid.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv   = $curproc->command_line_argv();
    my $len    = $#$argv + 1;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'makefml_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    if ($len <= 1) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'makefml_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<makefml>.

It kicks off internal function
C<_makefml($args)> for makefml.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _makefml().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $myname = $curproc->myname();
    my $argv   = $curproc->command_line_argv();

    $curproc->_makefml($args);
}


# Descriptions: send if --allow-send-message or --allow-reply-message
#               option specified.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'makefml_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # --allow-send-message or --allow-reply-message option specified.
    if ($curproc->allow_reply_message()) {
	$curproc->inform_reply_messages();
	$curproc->queue_flush();
    }

    $eval = $config->get_hook( 'makefml_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 help()

show help.

=cut


# Descriptions: show help.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    my $name = $0;
    eval {
	use File::Basename;
	$name = basename($0);
    };

    # XXX-TODO: show all available commands at the last of help message.
    if ($name eq 'fml') {
	_fml_help($name);
    }
    else {
	_makefml_help($name);
    }
}


# Descriptions: show FYI help.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub _fyi_help
{
print <<"_EOF_";

FYI:

\"makefml\" and \"fml\" are same program except for the argument order.
So, available commands are same as makefml.

Usage:
   fml     \$ml_name \$command [command_options]
   makefml \$command \$ml_name [command_options]

 * newdomain and rmdomain commands are irregular.
   fml     \$ml_domain \$command
   makefml \$command \$ml_domain

_EOF_
}


# Descriptions: show help usage.
#    Arguments: STR($name)
# Side Effects: none
# Return Value: none
sub _fml_help
{
    my ($name) = @_;

print <<"_EOF_";
Usage: $name \$ml_name \$command [command_options]

_EOF_

    _fyi_help();
}


# Descriptions: show help usage.
#    Arguments: STR($name)
# Side Effects: none
# Return Value: none
sub _makefml_help
{
    my ($name) = @_;

print <<"_EOF_";

Usage: $name \$command \$ml_name [options]

$name help         \$ml_name                   show this help

$name subscribe    \$ml_name ADDRESS
$name unsubscribe  \$ml_name ADDRESS
...
_EOF_

    _fyi_help();
}


=head2 _makefml($args)

switch of C<makefml> command.
It kicks off <FML::Command::$command> corresponding with
C<@$argv> ( $argv = $args->{ ARGV } ).

C<Caution:>
C<$args> is passed from parrent libexec/loader.
We construct a new struct C<$command_args> here to pass parameters
to child objects.
C<FML::Command::$command> object takes them as arguments not pure
C<$args>. It is a little mess. Pay attention.

See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: makefml top level dispacher.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _makefml
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->config();
    my $ml_name = $config->{ ml_name };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();
    my ($method, $argv_ml_name, @options);

    # XXX hmm, HARD-CODED but no idea.
    if ($myname eq 'makefml') {
	($method, $argv_ml_name, @options) =  @$argv;
    }
    elsif ($myname eq 'fml') {
	($argv_ml_name, $method, @options) =  @$argv;
    }

    # build arguments to pass off to each method.
    # XXX-TODO: command = [ $method, @options ]; ? (no, used only for message?)
    my $option       = $curproc->command_line_options();
    my $command_mode = $curproc->__get_command_mode($option);
    my $command_args = {
	command_mode => $command_mode,
	comname      => $method,
	command      => "$method @options",
	ml_name      => $ml_name,
	options      => \@options,
	argv         => $argv,

	# save raw argv for {new,rm}domain commands, which need to
	# interpret $ml_name as ml_domain.
	canon_argv   => {
	    ml_name  => $argv_ml_name,
	    method   => $method,
	    options  => \@options,
	},
    };

    my $eval = $config->get_hook( 'makefml_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # here we go
    require FML::Command;
    my $obj = new FML::Command;

    if (defined $obj) {
	# execute command ($comname method) under eval().
	eval q{
	    $obj->$method($curproc, $command_args);
	};
	unless ($@) {
	    ; # not show anything
	}
	else {
	    my $r = $@;
	    $curproc->logerror("command $method fail");
	    $curproc->logerror($r);
	    if ($r =~ /^(.*)\s+at\s+/) {
		my $reason = $1;
		$curproc->log($reason); # pick up reason
		croak($reason);
	    }
	}
    }

    $eval = $config->get_hook( 'makefml_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: determine command mode.
#    Arguments: OBJ($curproc) HASH_REF($option)
# Side Effects: none
# Return Value: STR
sub __get_command_mode
{
    my ($curproc, $option) = @_;

    if (defined $option->{ mode } && $option->{ mode } =~ /^user$/i) {
	return 'user';
    }
    else {
	return 'admin';
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

FML::Process::Configure first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
