#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Calendar.pm,v 1.6 2004/01/01 08:41:33 fukachan Exp $
#

package FML::CGI::Calendar;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines
use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::Calendar - CGI module to show calendar as HTML TABLE (DEMO)

=head1 SYNOPSIS

    $obj = new FML::CGI::Calendar;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Calendar> is a subclass of C<FML::Process::CGI>.

Almost all methods inherit C<FML::Process::CGI> base class.

=head1 METHODS

=head2 html_start()

print out HTML header + body former part and navigator.

=head2 html_end()

print out the navigator and closing of html.

=cut


# Descriptions: print out HTML header + body former part and navigator.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->config();
    my $user    = $curproc->safe_param_user;
    my $myname  = $curproc->myname();
    my $title   = "$user schedule";
    my $color   = '#E6E6FA';
    my $charset = $curproc->get_charset("cgi");

    # o.k start html
    print start_html(-title   => $title,
		     -lang    => $charset,
		     -BGCOLOR => $color);
    print "\n";

    $curproc->_show_guide($args);

    print "<HR>\n";
}


# Descriptions: print out the navigator and closing of html.
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


=head2 run_cgi_main()

main routine to print calendar as HTML TABLE format.

=head2 run_cgi_navigator()

dummy.

=head2 run_cgi_options()

dummy.

=cut


# Descriptions: main routine to print calendar as HTML TABLE format.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc, $args) = @_;
    my $user = $curproc->safe_param_user;

    use Calendar::Lite;
    my $schedule = new Calendar::Lite { user => $user };

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

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Calendar first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
