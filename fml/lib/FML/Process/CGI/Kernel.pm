#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Kernel.pm,v 1.1.1.1 2001/11/08 15:35:32 fukachan Exp $
#

package FML::Process::CGI::Kernel;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::CGI::Kernel - CGI basic functions

=head1 SYNOPSIS

   use FML::Process::CGI::Kernel;
   my $obj = new FML::Process::CGI::Kernel;
   $obj->prepare($args);
      ... snip ...

This new() creates CGI object which wraps C<FML::Process::Kernel>.

=head1 DESCRIPTION

the base class of CGI programs.
It provides basic functions and flow.

=head1 METHODS

=head2 C<new()>

ordinary constructor which is used widely in FML::Process classes.

=cut

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

# load standard CGI routines
use CGI qw/:standard/;

@ISA = qw(FML::Process::Kernel);


# XXX now we re-evaluate $ml_home_dir and @cf again.
# XXX but we need the mechanism to re-evaluate $args passed from
# XXX libexec/loader.
sub new
{
    my ($self, $args) = @_;
    my $type = ref($self) || $self;

    # we should get $ml_name from HTTP.
    my $ml_home_prefix = $args->{ ml_home_prefix };
    my $ml_name        = safe_param_ml_name($self) || do {
	croak("not get ml_name from HTTP") if $args->{ need_ml_name };
    };

    use File::Spec;
    my $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);
    my $config_cf   = File::Spec->catfile($ml_home_dir, 'config.cf');

    # fix $args { cf_list, ml_home_dir };
    my $cflist = $args->{ cf_list };
    push(@$cflist, $config_cf);
    $args->{ ml_home_dir } =  $ml_home_dir;

    # o.k. load configurations
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 C<prepare()>

print HTTP header.
The charset is C<euc-jp> by default.

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

dummy method now.

=head2 C<finish()>

dummy method now.

=cut

sub verify_request { 1;}

sub finish { 1;}


=head2 C<run()>

dispatch *.cgi programs.

=cut

# See CGI.pm for more details
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $config->{ program_name };

    # model specific ticket object
    if ($myname eq 'makefml.cgi') {
	$curproc->_makefml($args);
    }
    else {
	croak("Who am I ($myname)? I don't know $myname\n");
    }
}


sub _makefml
{
    my ($curproc, $args) = @_;
    my $method  = $curproc->safe_param_method;
    my $ml_name = $curproc->safe_param_ml_name;
    my $address = $curproc->safe_param_address || '';
    my $argv    = $curproc->command_line_argv();
    my @options = ();

    # arguments to pass off to each method
    my $optargs = {
	command => $method,
	ml_name => $ml_name,
	address => $address,
	options => \@options,
	argv    => $argv,
	args    => $args,
    };

    Log("makefml.cgi ml_name=$ml_name command=$method address=$address");

    # here we go
    require FML::Command;
    my $obj = new FML::Command;
    $obj->$method($curproc, $optargs);
}


=head2 safe_param_xxx()

get and filter param('xxx') via AUTOLOAD().

=cut


sub AUTOLOAD
{
    my ($curproc) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;

    if ($comname =~ /^safe_param_(\S+)/) {
        my $varname = $1;
        return $curproc->safe_param($varname);
    }
    else {
        croak("unknown method $comname");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::CGI::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
