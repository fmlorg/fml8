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


# XXX now we re-evaluate $ml_home_dir and @cf again.
# XXX but we need the mechanism to re-evaluate $args passed from
# XXX libexec/loader.
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


=head2 C<verify_request()>

a dummy method

=head2 C<finish()>

dummy method

=cut

sub verify_request { 1;}
sub finish { 1;}


# See CGI.pm for more details
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    # model specific ticket object
    my $module = 'FML::Ticket::Model::'.$config->{ ticket_model };
    my $ticket = $curproc->load_module($args, $module);
    $ticket->mode({ mode => 'html' });
    $ticket->run_cgi($curproc, $args);
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
