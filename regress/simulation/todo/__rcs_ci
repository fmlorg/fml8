# Copyright (C) 1993-1998 Ken'ichi Fukamachi
#          All rights reserved. 
#               1993-1996 fukachan@phys.titech.ac.jp
#               1996-1998 fukachan@sapporo.iij.ad.jp
# 
# FML is free software; you can redistribute it and/or modify
# it under the terms of GNU General Public License.
# See the file COPYING for more details.
#
# $Id$
#

sub RCSBackUp
{
    local($f) = @_;
    local($mode);

    &RCSInit;

    if (! $CI) {
	&Log("RCSBackUp: ERROR: cannot find 'ci'");
	return $NULL;
    }

    &Log("RCSBackUp: $CI -l -q $f 2>&1|") if $debug;

    if (!-f $f) {
	&Log("RCSBackUp: ERROR: cannot find $f");
	return;
    }

    # preserve mode
    $mode = (stat($f))[2];

    open(CI, "$CI -l -q $f 2>&1|") || 
	&Log("RCSBackUp ERROR: cannot exec $CI -q $f");
    while (<CI>) {
	chop;
	&Debug("RCSBackUp> $_") if $debug;
	&Log("RCSBackUp: $_") if /error/i;
    }
    close($f);

    # preserve mode
    chmod $mode, $f;
}


sub RCSInit
{
    -d "$DIR/RCS" || &MkDir("$DIR/RCS");

    # no check
    return if $RCS && $CI;

    local(@path) = ('/usr/bin', '/usr/ucb', '/usr/lib',
		    '/usr/local/bin', '/usr/contrib/bin', '/usr/pkg/bin');

    $RCS = $RCS || &SearchPath('rcs', @path);
    $CI  = $CI  || &SearchPath('ci', @path);

    &DiagPrograms('RCS', 'CI');
}


1;
