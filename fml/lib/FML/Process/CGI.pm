#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Process::CGI;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::CGI - CGI basic functions

=head1 SYNOPSIS

   use FML::Process::CGI;
   my $obj = new FML::Process::CGI;
   $obj->prepare($args);
      ... snip ...

=head1 DESCRIPTION

the base class of CGI programs

=head1 METHODS

=head2 C<new()>

constructor which is usual in FML::Process classes.

=cut

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

# load standard CGI routines
use CGI qw/:standard/;

@ISA = qw(FML::Process::Kernel Exporter);


sub new
{
    my ($self, $args) = @_;
    my $type = ref($self) || $self;

    # we should get $ml_name from HTTP.
    my $ml_home_prefix = $args->{ ml_home_prefix };
    my $ml_name        = param('ml_name');
    my $ml_home_dir    = $ml_home_prefix .'/'. $ml_name;

    # fix $args { cf_list, ml_home_dir };
    my $cf = $args->{ cf_list };
    push(@$cf, $ml_home_dir.'/config.cf');
    $args->{ ml_home_dir } =  $ml_home_dir;

    # o.k. load configurations
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 C<prepare()>

print HTTP header.

=cut

# XXX FML::Process::Kernel::prepare() parses incoming_message
# XXX CGI do not parse incoming_message;
sub prepare
{
    my ($curproc) = @_;
    my $config    = $curproc->{ config };
    my $charset   = $config->{ cgi_charset } || 'euc-jp';

    print header(-type => "text/html; charset=$charset");
}


# dummy methods
sub verify_request { 1;}
sub finish { 1;}


# See CGI.pm for more details
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $title  = $config->{ ticket_cgi_title }   || 'ticket system interface';
    my $color  = $config->{ ticket_cgi_bgcolor } || '#E6E6FA';

    use FileHandle;
    my ($rfd, $wfd) = FileHandle::pipe;
    $args->{ fd }   = $wfd;

    # ticket object
    my $ticket = $curproc->_load_ticket_model_module($args);
    $ticket->mode({ mode => 'html' });

    # o.k start html
    print start_html(-title=>$title,-BGCOLOR=>$color), "\n";

    # menu at the top of scrren
    $ticket->cgi_top_menu($curproc, $args);

    # get ticket id list
    my $tid = $ticket->get_id_list($curproc, $args);
    $ticket->sort($curproc, $args, $tid);
    for (@$tid) { $ticket->html_show($curproc, $args, $_);}

    # show summary
    $ticket->mode({ mode => 'html' });
    $ticket->show_summary($curproc, $args, {rfd => $rfd, wfd => $wfd});

    # o.k. end of html
    print end_html;
    print "\n";
}



=head2 C<_load_ticket_model_module($args)>

load model dependent module.

=cut

sub _load_ticket_model_module
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $model  = $config->{ ticket_model };
    my $pkg    = "FML::Ticket::Model::$model";

    # fake use() to do "use FML::Ticket::$model;"
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	return $pkg->new($curproc, $args);
    }
    else {
	Log($@);
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::CGI appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
