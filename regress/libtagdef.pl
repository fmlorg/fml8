# Copyright (C) 1993-1998 Ken'ichi Fukamachi
#          All rights reserved. 
#               1993-1996 fukachan@phys.titech.ac.jp
#               1996-1998 fukachan@sapporo.iij.ad.jp
# 
# FML is free software; you can redistribute it and/or modify
# it under the terms of GNU General Public License.
# See the file COPYING for more details.
#
# $Id$;

# if $SUBJECT_HML_FORM = 1;
#   [Elena:100]
# 
# other candidates as follows:
sub SubjectTagDef
{
    local($mode) = @_;

    $mode =~ s/\"//g;
    $mode =~ s/\'//g;

    # (Elena 100) 
    if ($mode eq '( )') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '(';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = ' ';
	$END_BRACKET       = ')';
	$SUBJECT_FREE_FORM_REGEXP = "\\($BRACKET\\s+\\d+\\)";
    }
    # [Elena 100];
    elsif ($mode eq '[ ]') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '[';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = ' ';
	$END_BRACKET       = ']';
	$SUBJECT_FREE_FORM_REGEXP = "\\[$BRACKET\\s+\\d+\\]";
    }
    # (Elena:100) 
    elsif ($mode eq '(:)') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '(';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = ':';
	$END_BRACKET       = ')';
	$SUBJECT_FREE_FORM_REGEXP = "\\($BRACKET:\\d+\\)";
    }
    # [Elena:100];
    elsif ($mode eq '[:]') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '[';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = ':';
	$END_BRACKET       = ']';
	$SUBJECT_FREE_FORM_REGEXP = "\\[$BRACKET:\\d+\\]";
    }
    elsif ($mode eq '[,]') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '[';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = ',';
	$END_BRACKET       = ']';
	$SUBJECT_FREE_FORM_REGEXP = "\\[$BRACKET,\\d+\\]";
    }
    elsif ($mode eq '(,)') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '(';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = ',';
	$END_BRACKET       = ')';
	$SUBJECT_FREE_FORM_REGEXP = "\\($BRACKET,\\d+\\)";
    }
    ###
    ### without numbers
    ###
    elsif ($mode eq '()') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '(';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = '';
	$END_BRACKET       = ')';
	$SUBJECT_FREE_FORM_REGEXP = "\\($BRACKET\\)";
    }
    # [Elena 100];
    elsif ($mode eq '[]') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '[';
	$BRACKET           = $BRACKET || 'Elena';
	$BRACKET_SEPARATOR = '';
	$END_BRACKET       = ']';
	$SUBJECT_FREE_FORM_REGEXP = "\\[$BRACKET\\]";
    }
    ###
    ### NUMBER AND BRACKET
    ###
    elsif ($mode eq '(ID)') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '(';
	$BRACKET           = '';
	$BRACKET_SEPARATOR = '';
	$END_BRACKET       = ')';
	$SUBJECT_FREE_FORM_REGEXP = "\\(\\d+\\)";
    }
    elsif ($mode eq '[ID]') {
	$SUBJECT_FREE_FORM = 1;
	$BEGIN_BRACKET     = '[';
	$BRACKET           = '';
	$BRACKET_SEPARATOR = '';
	$END_BRACKET       = ']';
	$SUBJECT_FREE_FORM_REGEXP = "\\[\\d+\\]";
    }

}

1;
