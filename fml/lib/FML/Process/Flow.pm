#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Process::Flow;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::Flow - describe process flow 

=head1 SYNOPSIS

   use FML::Process::Flow;
   FML::Process::Flow::ProcessStart($pkg, $args);

where C<$pkg> is the package name.
C<$args> is HASH REFERENCE.

=head1 DESCRIPTION

This module describes the current fml program flow. 
Each function is implemented in each module of FML::Process classes.

    # create a new process object
    my $process = $pkg->new($args);

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

=cut

# Descriptions: drives basic flow 
#               1. initialize processes and load configurations from *.cf
#                  switch to each process according with $0 and @ARGV.
#               2. parse the incoming message(mail)
#               3. start the main transaction
#                  lock, execute main routine, unlock
#               4. inform error messages, clean up and more ...
#    Arguments: $self $args
# Side Effects: 
#               ProcessSwtich() is exported to main:: Name Space.
# Return Value: none
sub ProcessStart
{
    my ($pkg, $args) = @_;

    # create a new process object
    my $process = $pkg->new($args);

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
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Flow appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
