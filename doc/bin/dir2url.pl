#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

use strict;
use Carp;
use vars qw($WarningMessage);
use File::Basename;

my $Module;
my $ModulePrefix;
my $TableMode = 1;
my $Prefix    = dirname($0);

Init();
HEADER();
Show();
FOOTER();

if ($WarningMessage) {
    print "*** warning ***\n";
    print $WarningMessage;
}

exit 0;


sub Init
{
    my $pwd = `pwd`;
    chop($pwd);
    $pwd =~ s@^.*fml/lib@@;
    $pwd =~ s@^.*cpan/dist@@;
    $pwd =~ s@^.*cpan/lib@@;
    $pwd =~ s@^/@@;
    $ModulePrefix = $pwd;
    $ModulePrefix =~ s@/@::@g;
    $Module       = $pwd . "::*";
}


sub update_cvs_ignore
{
    if ( -f ".cvsignore" ) {
	use FileHandle;
	my $fh = new FileHandle "> .cvsignore";
	print $fh '@@doc', "\n";
	close($fh);
    } 
}


sub generate_manual
{
    my ($pathname) = @_;
    my ($doc, $manual);

    if (-f $pathname) {
	-d '@@doc' || mkdir('@@doc', 0755);
	$manual = '@@doc/'.$pathname;
	$manual =~ s/pm$/txt/;

	print STDERR "\tpod2text $pathname > $manual\n";
	system "pod2text $pathname > $manual";

	$manual =  $pathname;
	$manual =~ s/pm$/ja.txt/;
	$doc    =  '@@doc/'.$pathname;
	$doc    =~  s/pm$/ja.html/;

	if (-f $manual) {
	    system "$Prefix/text2html.pl $manual > $doc";
	}
    }
}


sub Show
{
    my ($pathname, $manual);

    print "<CENTER><EM>$ModulePrefix class modules</EM></CENTER>\n<HR>\n";
    print ($TableMode ? "<TABLE>\n" : "<UL>\n");

    update_cvs_ignore();

    foreach $pathname (<*>) {
	next if $pathname =~ /^\__template/;
	next if $pathname =~ /^\@/;
	next if $pathname =~ /\~$/;
	next if $pathname =~ /pod$/;
	next if $pathname eq 'CVS';
	next if $pathname eq 't'; # test directory
	next if $pathname =~ /^index/;
	next if $pathname eq 'Makefile';

	my $module = $pathname;
	if ($module =~ /\.pm$/) { generate_manual($pathname);}

	$manual = '@@doc/'.$pathname;
	$manual =~ s/pm$/txt/;

	if (-d $pathname) {
	    print ($TableMode ? "<TR>\n" : "<LI>\n");
	    print "<TD>\n" if $TableMode;
	    
	    if (-f "$pathname/index.ja.html") {
		print " <A HREF=$pathname/index.ja.html>";

		if ($ModulePrefix) {
		    print "${ModulePrefix}::${module}::* class</A>\n";
		}
		else {
		    print "${module}::*</A>\n";
		}
	    }
	    else {
		if (-f "$pathname/README") {
		    print " <A HREF=$pathname/README>README</A>\n";
		}

		if ( -f "$pathname/INSTALL") {
		    print " <A HREF=$pathname/INSTALL>INSTALL</A>\n";
		}

		_warn("Error: *** fail to convert $pathname ***");
		print "${pathname}/\n";
	    }
	}
	elsif ($pathname =~ /\.pm$/) {
	    print ($TableMode ? "<TR>\n" : "<LI>\n");
	    print "<TD>\n" if $TableMode;
	    print " $module ";

	    print "<TD>\n" if $TableMode;
	    print "<A HREF=\"$pathname\">[source]</A>\n";

	    print "<TD>\n" if $TableMode;
	    print "<A HREF=\"$manual\">[manual]</A>\n" if -f $manual;

	    my $doc = $manual;
	    $doc    =~ s/txt/ja.html/;
	    print "<TD>\n" if $TableMode;
	    print "<A HREF=\"$doc\">[Japanese MEMO]</A>\n" if -f $doc;
	}
	elsif ($pathname =~ /\.ja\.txt$/) {
	    ; # see above
	}
	else {
	    _warn("unknown file type $pathname");
	}
    }

    print ($TableMode ? "</TABLE>\n" : "</UL>\n");
}


sub HEADER 
{

print <<"_EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<TITLE>
$Module classes
</TITLE>
<META http-equiv="Content-Type"
	content="text/html; charset=EUC-JP">
</HEAD>

<BODY BGCOLOR="#E6E6FA">
_EOF

}


sub FOOTER
{

print <<'_EOF';
</BODY>
</HTML>
_EOF

}


sub _warn
{
    my ($mesg) = @_;
    $WarningMessage .= $mesg . "\n";
}


1;
