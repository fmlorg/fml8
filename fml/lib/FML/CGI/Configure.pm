#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Configure.pm,v 1.8 2001/12/23 09:20:41 fukachan Exp $
#

package FML::CGI::Configure;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::Configure - provides functions for makefml CGI interface

=head1 SYNOPSIS

    $obj = new FML::CGI::Configure;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Configure> is a subclass of C<FML::Process::CGI>.

             FML::Process::Kernel
                       |
                       A
             FML::Process::CGI
                       |
                       A
            -----------------------
           |                       |
           A                       A
 FML::CGI::Configure

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

This module has routines needed for CGI.

=cut


# Descriptions: print out HTML header + body former part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc, $args) = @_;
    my $myname  = $curproc->myname();
    my $ml_name = $curproc->safe_param_ml_name();
    my $title   = "$ml_name configuration interface";
    my $color   = '#E6E6FA';
    my $charset = 'euc-jp';

    # o.k start html
    print start_html(-title=>$title,
		     -lang => $charset,
		     -BGCOLOR=>$color);
    print "\n";

    $curproc->_show_guide($args);

    print "<HR>\n";
}


# Descriptions: print out body latter part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_end
{
    my ($curproc, $args) = @_;

    print "<HR>\n";

    $curproc->_show_guide($args);

    # o.k. end of html
    print end_html;
    print "\n";
}


# Descriptions: print out navigation bar
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _show_guide
{
    my ($curproc, $args) = @_;

    ;
}


# Descriptions: main routine for makefml.cgi.
#               kick off suitable FML::Command finally via _execulte_command().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $config->{ program_name };
    my $command = $curproc->safe_param_command() || '';
    my $address = $curproc->safe_param_address() || '';

    print "command = $command\n<BR>\n";
    print "address = $address\n<BR>\n";

    print hr;
    $curproc->_show_menu($args);

    my $command_args = {
	command_mode => 'admin',
	comname      => $command,
	command      => $command,
	options      => [ $address ],
	argv         => undef,
	args         => undef,
    };
    $curproc->_execute_command($args, $command_args);
}


# Descriptions: execute FML::Command
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: load module
# Return Value: none
sub _execute_command
{
    my ($curproc, $args, $command_args) = @_;

    use FML::Command;
    my $obj = new FML::Command;
    if (defined $obj) {
	my $comname = $command_args->{ comname };
	eval q{
	    $obj->$comname($curproc, $command_args);
	};
	unless ($@) {
	    print "OK\n";
	}
	else {
	    print "$comname fails\n<BR>\n";
	    if ($@ =~ /^(.*)\s+at\s+/) {
		print $@;
		print "<BR>\n";
		print $1;
		print "<BR>\n";
	    }
	}
    }
}


# Descriptions: show menu
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _show_menu
{
    my ($curproc, $args) = @_;
    my $action  = $curproc->myname();
    my $target  = '_top';
    my $ml_list = $curproc->get_ml_list($args);
    my $address = $curproc->safe_param_address() || '';
    my $command_list = [
			'subscribe',
			'unsubscribe',
			];

    print start_form(-action=>$action, -target=>$target);

    print "ML: ";
    print popup_menu(-name => 'ml_name', -values => $ml_list);

    print "command: ";
    print popup_menu(-name => 'command', -values => $command_list);

    print "\n<BR>\n";

    print "address: ";
    print textfield(-name      => 'address',
		    -default   => $address,
		    -override  => 1,
		    -size      => 32,
		    -maxlength => 64,
		    );

    print "\n<BR>\n";

    print submit(-name => 'submit');
    print reset(-name  => 'reset');
    print end_form;
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

FML::CGI::Configure appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
