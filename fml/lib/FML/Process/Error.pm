#-*- perl -*-
#
# Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Error.pm,v 1.43 2004/04/02 11:56:26 fukachan Exp $
#

package FML::Process::Error;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Error -- error analyzer dispacher.

=head1 SYNOPSIS

   use FML::Process::Error;
   ...

See L<FML::Process::Flow> for details of fml process flow.

=head1 DESCRIPTION

C<FML::Process::Error> is a command wrapper and top level
dispatcher for commands.

=head1 METHODS

=head2 new($args)

make fml process object, which inherits C<FML::Process::Kernel>.

=cut


# Descriptions: standard constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: inherit FML::Process::Kernel
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 prepare($args)

parse argv, load config files and fix @INC.

if $use_error_mail_analyzer_function, parse incoming message.

=cut

# Descriptions: check if $use_error_mail_analyzer_function value is yes.
#               parse incoming message if this process runs.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'error_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    if ($config->yes('use_error_mail_analyzer_function')) {
	$curproc->parse_incoming_message();
    }
    else {
	exit(0);
    }

    $eval = $config->get_hook( 'error_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

dummy.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config     = $curproc->config();
    my $maintainer = $config->{ maintainer };

    my $eval = $config->get_hook( 'error_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # set dummy sender to avoid unexpected error
    $curproc->{'credential'}->set( 'sender', $maintainer );

    $eval = $config->get_hook( 'error_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

dispatcher to run correspondig C<FML::Error::command> for
C<command>. Standard style follows:

    lock
    execute FML::Error::command
    unlock

XXX Each command determines need of lock or not.

=cut


# Descriptions: analyze error mails and remove error addresses.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: update cache and member lists if needed.
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $found  = 0;
    my $pcb    = $curproc->pcb();
    my $msg    = $curproc->incoming_message();

    my $eval = $config->get_hook( 'error_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->_forward_error_message();

    unless ($curproc->is_refused()) {
	eval q{
	    use Mail::Bounce;
	    my $bouncer = new Mail::Bounce;
	    $bouncer->analyze( $msg );

	    use FML::Error;
	    my $error = new FML::Error $curproc;
	    $error->db_open();

	    for my $address ( $bouncer->address_list ) {
		my $status = $bouncer->status( $address );
		my $reason = $bouncer->reason( $address );

		if ($address) {
		    $curproc->log("bounced: address=<$address>");
		    $curproc->log("bounced: status=$status");
		    $curproc->log("bounced: reason=\"$reason\"");

		    $error->add({
			address => $address,
			status  => $status,
			reason  => $reason,
		    });

		    $found++;
		}
	    }

	    $error->db_close();
	};
	$curproc->logerror($@) if $@;

	if ($found) {
	    $pcb->set("error", "found", 1);
	    $curproc->_clean_up_bouncers();
	}
    }

    $eval = $config->get_hook( 'error_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: run analyzer() if long time spent after the last
#               analyze.
#    Arguments: OBJ($curproc)
# Side Effects: remove addresses which causes bounces
# Return Value: none
sub _clean_up_bouncers
{
    my ($curproc) = @_;
    my $channel   = 'erroranalyzer';

    if ($curproc->is_event_timeout($channel)) {
	$curproc->log("(debug) event timeout");

	eval q{
	    use FML::Error;
	    my $error = new FML::Error $curproc;
	    $error->analyze();
	    $error->remove_bouncers();
	};
	$curproc->logerror($@) if $@;

	# XXX-TODO: 3600 customizable.
	$curproc->set_event_timeout($channel, time + 3600);
    }
    else {
	$curproc->log("(debug) event not timeout");
    }
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
print <<"_EOF_";

Usage: $0 \$ml_home_prefix/\$ml_name [options]

   For example, process command of elena ML
   $0 /var/spool/ml/elena

_EOF_
}


=head2 finish($args)

    $curproc->inform_reply_messages();

=cut


# Descriptions: finalize command process.
#               reply messages, command results et. al.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: queue manipulation
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $pcb    = $curproc->pcb();

    my $eval = $config->get_hook( 'error_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # XXX NOT INFORM ANY RESULTS BUT ONLY LOG IT TO AVOID LOOP.
    if ($pcb->get("error", "found")) {
	$curproc->log("error message found");
    }
    else {
	$curproc->log("error message not found");
    }

    $curproc->inform_reply_messages();
    $curproc->queue_flush();

    $eval = $config->get_hook( 'error_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head1 message forwarding

forward the error message.

=cut


# Descriptions: forward the error message.
#    Arguments: OBJ($curproc)
# Side Effects: update reply message queue
# Return Value: none
sub _forward_error_message
{
    my ($curproc)  = @_;
    my $config     = $curproc->config();
    my $fml_owner  = $curproc->fml_owner_address();
    my $maintainer = $config->{ maintainer } || $fml_owner;
    my $maps       = $config->{ maintainer_recipient_maps } || '';
    my $msg        = $curproc->incoming_message();

    if ($maps) {
	my $maps     = $config->get_as_array_ref('maintainer_recipient_maps');
	my $msg_args = {
	    smtp_sender    => $fml_owner,
	    recipient_maps => $maps,
	    header         => {
		sender => $fml_owner,
		from   => $fml_owner,
		to     => $maintainer,
	    },
	};
	$curproc->reply_message($msg, $msg_args);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Error first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
