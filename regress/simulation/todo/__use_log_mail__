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

sub MailCacheDir
{
    local($id, $p, $pp);

    $LOG_MAIL_DIR = $LOG_MAIL_DIR || "$VAR_DIR/Mail";
    $LOG_MAIL_SEQ = $LOG_MAIL_SEQ || "$LOG_MAIL_DIR/.seq";
    $NUM_LOG_MAIL = $NUM_LOG_MAIL || 100;
    $LOG_MAIL_FILE_SIZE_MAX = $LOG_MAIL_FILE_SIZE_MAX || 2048;

    -d $LOG_MAIL_DIR || &MkDir($LOG_MAIL_DIR);
    -f $LOG_MAIL_SEQ || &Touch($LOG_MAIL_SEQ);

    $id = &GetFirstLineFromFile($LOG_MAIL_SEQ);
    $id = $id % $NUM_LOG_MAIL;
    $id++;

    if (open(F, "> $LOG_MAIL_DIR/$id")) {
	print F $Envelope{'Header'};
	print F "\n";

	for ($p = 0; $p < $LOG_MAIL_FILE_SIZE_MAX; ) {
	    $p = index($Envelope{'Body'}, "\n", $p + 1);
	    if ($p < 0) {
		last;
	    }
	    else {
		print F substr($Envelope{'Body'}, $pp, $p + 1 - $pp);
		$pp = $p + 1;
	    }
	}
	close(F);

	&Write2($id, $LOG_MAIL_SEQ);
    }
    else {
	&Log("cannot open \$LOG_MAIL_DIR/$id");
    }
}


1;
