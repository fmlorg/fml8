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

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut

use FML::Process::Kernel;
use FML::Log qw(Log);
use FML::Config;

# load standard CGI routines
use CGI qw/:standard/;

@ISA = qw(FML::Process::Kernel Exporter);


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


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
