#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::CGI::TicketSystem;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use CGI qw/:standard/; # load standard CGI routines
use FML::Process::CGI;

@ISA = qw(FML::Process::CGI Exporter);


=head1 NAME

FML::CGI::TicketSystem - CGI details to control ticket system

=head1 SYNOPSIS

    $ticket = new FML::CGI::TicketSystem;
    $ticket->new();
    $ticket->run();

See L<FML::Process::Flow> for flow methods details.

=head1 DESCRIPTION

C<NOT YET IMPLEMENTED>.

=head2 CLASS HIERARCHY

C<FML::CGI::TicketSystem> is a subclass of C<FML::Process::CGI>.

             FML::Process::Kernel
                       |
                       A
             FML::Process::CGI
                       |
                       A
            -----------------------
           |           |           |
           A           A           A
     FML::CGI::TicketSystem


=head1 METHODS

Almost methods are forwarded to C<FML::Process::CGI> base class.

=head2 C<run()>

main method.

=cut

# See CGI.pm for more details
sub run
{
    my ($curproc, $args) = @_;

    use FileHandle;
    my ($rfd, $wfd) = FileHandle::pipe;
    $args->{ fd }   = $wfd;
    my $ticket = $curproc->_load_ticket_model_module($args);

    print start_html('ticket system interface'), "\n";

    print "<PRE>\n";


    my $argv     = $args->{ ARGV };
    $argv->[ 0 ] = 'list';

    # my $tid = $ticket->get_id_list($curproc, $args);
    # for (@$tid) { print "|| $_\n";}

    $ticket->show_summary($curproc, $args);
    close($wfd);
    while (<$rfd>) { print STDOUT " | $_";}


    print "</PRE>\n";

    print "\n";
    print end_html;
    print "\n";
}


sub _load_ticket_model_module
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $model  = $config->{ ticket_model };
    my $pkg    = "FML::Ticket::Model::";

    if ($model eq 'toymodel') {
	$pkg .= $model;
    }
    else {
	Log("ticket: unknown model");
	return;
    }

    # fake use() to do "use FML::Ticket::$model;"
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	return $pkg->new($curproc, $args);
    }
    else {
	Log($@);
    }
}


=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and 
L<FML::Process::Flow>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::CGI::TicketSystem appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
