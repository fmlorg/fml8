#-*- perl -*-
#
# Copyright (C) 2005 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: FetchFML.pm,v 1.2 2005/06/04 08:49:10 fukachan Exp $
#

package FML::Process::FetchFML;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::FetchFML -- fetch and run fml8 process.

=head1 SYNOPSIS

    use FML::Process::FetchFML;
    $curproc = new FML::Process::FetchFML;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::FetchFML provides the main function for C<libexec/fetchfml>.

See C<FML::Process::Flow> for the flow detail.

=head1 METHODS

=head2 new($args)

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 prepare($args)

load default config files,
set up domain we need to fake,
and
fix @INC if needed.

lastly, parse incoming message input from \*STDIN channel.

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


# Descriptions: preparation.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fetchfml_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->ml_variables_resolve();
    $curproc->config_cf_files_load();
    $curproc->env_fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();
    $curproc->_fetchfml_prepare();

    $eval = $config->get_hook( 'fetchfml_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

dummy.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fetchfml_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'fetchfml_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<fetchfml>.

=cut


# Descriptions: just a switch, call _fetchfml_main().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fetchfml_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    unless ($curproc->is_refused()) {
	my $myname    = $curproc->_get_myname();
	my $ml_name   = $config->{ ml_name };
	my $ml_domain = $config->{ ml_domain };
	eval q{
	    $curproc->log("emulate $myname for $ml_name\@$ml_domain ML");

	    use FML::Process::Switch;
	    &FML::Process::Switch::NewProcess($curproc,
					      $args,
					      $myname,
					      $ml_name,
					      $ml_domain);
	};
	$curproc->logerror($@) if $@;
    }
    else {
	$curproc->log("request ignored.");
    }

    $eval = $config->get_hook( 'fetchfml_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 finish($args)

dummy.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fetchfml_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'fetchfml_finish_end_hook' );
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

print <<"_EOF_";

Usage: $name [options]

[BUGS]

_EOF_
}


=head1 INTERNAL FUNCTIONS

Internal function fakes mail retrieve and forward mechanism.

It fetches a message via POP3 or IMAP4 protocol and forward it into
fml8 process.

=cut


# Descriptions: retrieve a message and forward it into fml8 to parse
#               incoming message.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fetchfml_prepare
{
    my ($curproc)     = @_;
    my $current_class = $curproc->_get_current_class();

    $curproc->logdebug("class: $current_class");

    # 2. retierive a message via POP3 or IMAP4 protocol.
    $curproc->_fetchfml_retrieve({
	class => $current_class,
    });

    unless ($curproc->is_refused()) {
	# 3. fake IO.
	$curproc->_fetchfml_fake_stdio({
	    class => $current_class,
	});
    }
}


# Descriptions: retrieve a message.
#    Arguments: OBJ($curproc) HASH_REF($ff_args)
# Side Effects: none
# Return Value: none
sub _fetchfml_retrieve
{
    my ($curproc, $ff_args) = @_;
    my $config   = $curproc->config();
    my $class    = $ff_args->{ class } || "article_post";
    my $username = $config->{ "fetchfml_${class}_user" };
    my $password = $config->{ "fetchfml_${class}_password" };
    my $server   = $config->{ fetchfml_pop_server };

    use FML::MUA::POP3;
    my $mua = new FML::MUA::POP3 $curproc;
    if (defined $mua) {
	$mua->login({
	    server   => $server,
	    username => $username,
	    password => $password,
	});

	if ($mua->error()) {
	    $curproc->logerror($mua->error());
	    $curproc->stop_this_process();
	    return;
	}

	$mua->retrieve( { class => $class } );
	if ($mua->error()) {
	    $curproc->logerror($mua->error());
	    $curproc->stop_this_process();
	    return;
	}

	$mua->quit();
	if ($mua->error()) {
	    $curproc->logerror($mua->error());
	}
    }
    else {
	$curproc->logerror("object undefined.");
    }
}


# Descriptions: pick up one message and fake STDIN for it.
#    Arguments: OBJ($curproc) HASH_REF($ff_args)
# Side Effects: none
# Return Value: none
sub _fetchfml_fake_stdio
{
    my ($curproc, $ff_args) = @_;
    my $class = $ff_args->{ class } || "article_post";

    use FML::MUA::POP3;
    my $mua = new FML::MUA::POP3 $curproc;
    if (defined $mua) {
	my $queue = $mua->pick_up_queue( { class => $class } );

	# 1. queue to do found.
	if (defined $queue) {
	    # XXX we need to remove this queue with synchronizing later
	    # XXX incoming queue in.
	    $curproc->incoming_message_stack_queue_for_removal($queue);

	    close(STDIN);
	    unless ($queue->open($class, { in_channel => *STDIN{IO} })) {
		my $qid = $queue->id();
		$curproc->logerror("cannot open qid=$qid");
	    }
	}
	# 2. queue not found.
	else {
	    $curproc->logdebug("nothing to do");
	    exit(0);
	}
    }
    else {
	$curproc->logerror("object undefined.");
    }
}


=head1 UTILITY

=cut


# Descriptions: speculate the current class we process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub _get_current_class
{
    my ($curproc)     = @_;
    my $option        = $curproc->command_line_options();
    my $current_class = "article_post";

    # 1. determine emulataion of distribute or command.
    # command_mail_function
    if ($option->{ 'command-mail' }) {
	$current_class = "command_mail";
    }
    # error_mail_analyzer_function
    elsif ($option->{ 'error' } || $option->{'error-mail-analyzer'}) {
	$current_class = "error_mail_analyzer";
    }
    # article_post_function
    elsif ($option->{ 'article-post' }) {
	$current_class = "article_post";
    }
    else {
	$current_class = "article_post";
    }

    return $current_class;
}


# Descriptions: speculate myname we process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub _get_myname
{
    my ($curproc)     = @_;
    my $current_class = $curproc->_get_current_class();
    my $class_to_name = {
	"article_post"        => "distribute",
	"command_mail"        => "command",
	"error_mail_analyzer" => "error",
    };

    return $class_to_name->{ $current_class };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::FetchFML first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
