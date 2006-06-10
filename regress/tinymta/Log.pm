#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package TinyMTA::Log;
use strict;
use Carp;

# Descriptions: send log message by syslog(3).
#    Arguments: STR($msg)
# Side Effects: none
# Return Value: OBJ
sub log
{
    my ($msg) = @_;

    use File::Basename;
    my $myname   = basename($0);
    my $ident    = "tinymta/$myname";
    my $logopt   = "pid";
    my $facility = "local0";
    my $priority = "info";

    use Sys::Syslog;
    openlog($ident, $logopt, $facility);
    syslog($priority, $msg);
    closelog();
}


1;
