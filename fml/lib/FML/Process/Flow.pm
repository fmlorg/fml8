#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Flow.pm,v 1.34 2008/08/24 08:18:33 fukachan Exp $
#

package FML::Process::Flow;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::Flow - the process flow.

=head1 SYNOPSIS

   use FML::Process::Flow;
   FML::Process::Flow::ProcessStart($obj, $args);

where C<$obj> is an FML::Process::C<something> object and
C<$args> is HASH REFERENCE prepared by C<FML::Process::Switch>.

=head1 DESCRIPTION

This module describes the fml program flow. All methods, even if
dummy, should be implemented in each FML::Process::CLASS.
This flow is same among fml processes such as
programs kicked by MTA, command line interfaces and CGI's.

    # create a new process object
    my $process = $pkg->new($args);

    # XXX private method to show help ASAP.
    # XXX we need to trap here since $process object is clarified after
    # XXX $pkg->new() above.
    $process->sysflow_trap_help($args);

    # e.g. parse the incoming message (e.g. STDIN)
    $process->prepare($args);

    # validate the request, for example,
    #    permit post from the sender,
    #    check the mail loop or not ...
    $process->verify_request($args);

    # start main transaction
    $process->run($args);

    # closing the process
    $process->finish($args);

    # clean up tmporary files
    $process->tmp_file_cleanup();

=cut


# Descriptions: drive top level process flow
#               1. initialize processes and load configurations from *.cf,
#                  switch to each process according with $0 and @ARGV.
#               2. parse the incoming message(mail).
#               3. start the main transaction.
#                  lock, execute main routine, unlock, ...
#               4. inform error messages, clean up and more ...
#    Arguments: OBJ($pkg) HASH_REF($args)
# Side Effects: ProcessSwtich() is exported to main:: Name Space.
# Return Value: none
sub ProcessStart
{
    my ($pkg, $args) = @_;

    # create a new process object
    my $process = $pkg->new($args);

    # curproc back pointer, used in emergency.
    $args->{ curproc } = $process;

    # XXX private method to show help ASAP
    # XXX we need to trap here since $process object is clarified after
    # XXX $pkg->new() above.
    $process->sysflow_trap_help($args);

    # e.g. parse the incoming message (e.g. STDIN)
    $process->prepare($args);

    # close and reopen STDERR to record log messages written into STDERR.
    $process->sysflow_reopen_stderr_channel();

    # validate the request, for example,
    #    permit post from the sender,
    #    check the mail loop or not ...
    $process->verify_request($args);

    # start main transaction
    $process->run($args);

    # start closing of this process
    $process->finish($args);

    # flush stderr channel log.
    $process->sysflow_finalize_stderr_channel($args);

    # log file rotation et.al.
    $process->log_file_cleanup();

    # clean up temporary files.
    $process->tmp_file_cleanup();
    $process->isolated_message_cleanup_queue();
    $process->incoming_message_cleanup_queue();

    # debug
    $process->finalize();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Flow first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
