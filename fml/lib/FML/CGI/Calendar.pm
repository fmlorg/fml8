#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Calender.pm,v 1.7 2002/12/18 04:47:34 fukachan Exp $
#

package FML::CGI::Calender;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines
use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::Calender - CGI module to show calender as HTML TABLE (DEMO)

=head1 SYNOPSIS

    $obj = new FML::CGI::Calender;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Calender> is a subclass of C<FML::Process::CGI>.

Almost all methods inherit C<FML::Process::CGI> base class.

=head1 METHODS

=cut


# Descriptions: print out HTML header + body former part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $user    = $curproc->safe_param_user;
    my $myname  = $curproc->myname();
    my $title   = "$user schedule";
    my $color   = '#E6E6FA';
    my $charset = $config->{ cgi_charset } || 'euc-jp';

    # o.k start html
    print start_html(-title   => $title,
		     -lang    => $charset,
		     -BGCOLOR => $color);
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

    for my $n ('this', 'next', 'last') {
	print "<A HREF=\"\#$n\">[$n month]</A>\n";
    }
}


# Descriptions: main routine for calender as HTML TABLE format
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc, $args) = @_;
    my $user = $curproc->safe_param_user;

    use Calender::Lite;
    my $schedule = new Calender::Lite { user => $user };

    for my $n ('this', 'next', 'last') {
	$schedule->print_specific_month(\*STDOUT, $n);
    }
}


# Descriptions: show menu (table based menu)
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc, $args) = @_;
    ;
}


# Descriptions: show menu (table based menu)
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_options
{
    my ($curproc, $args) = @_;
    ;
}


=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and
L<FML::Process::Flow>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Calender first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
