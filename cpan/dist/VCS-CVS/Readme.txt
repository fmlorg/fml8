.rn '' }`
''' $RCSfile$$Revision$$Date$
'''
''' $Log$
'''
.de Sh
.br
.if t .Sp
.ne 5
.PP
\fB\\$1\fR
.PP
..
.de Sp
.if t .sp .5v
.if n .sp
..
.de Ip
.br
.ie \\n(.$>=3 .ne \\$3
.el .ne 3
.IP "\\$1" \\$2
..
.de Vb
.ft CW
.nf
.ne \\$1
..
.de Ve
.ft R

.fi
..
'''
'''
'''     Set up \*(-- to give an unbreakable dash;
'''     string Tr holds user defined translation string.
'''     Bell System Logo is used as a dummy character.
'''
.tr \(*W-|\(bv\*(Tr
.ie n \{\
.ds -- \(*W-
.ds PI pi
.if (\n(.H=4u)&(1m=24u) .ds -- \(*W\h'-12u'\(*W\h'-12u'-\" diablo 10 pitch
.if (\n(.H=4u)&(1m=20u) .ds -- \(*W\h'-12u'\(*W\h'-8u'-\" diablo 12 pitch
.ds L" ""
.ds R" ""
'''   \*(M", \*(S", \*(N" and \*(T" are the equivalent of
'''   \*(L" and \*(R", except that they are used on ".xx" lines,
'''   such as .IP and .SH, which do another additional levels of
'''   double-quote interpretation
.ds M" """
.ds S" """
.ds N" """""
.ds T" """""
.ds L' '
.ds R' '
.ds M' '
.ds S' '
.ds N' '
.ds T' '
'br\}
.el\{\
.ds -- \(em\|
.tr \*(Tr
.ds L" ``
.ds R" ''
.ds M" ``
.ds S" ''
.ds N" ``
.ds T" ''
.ds L' `
.ds R' '
.ds M' `
.ds S' '
.ds N' `
.ds T' '
.ds PI \(*p
'br\}
.\"	If the F register is turned on, we'll generate
.\"	index entries out stderr for the following things:
.\"		TH	Title 
.\"		SH	Header
.\"		Sh	Subsection 
.\"		Ip	Item
.\"		X<>	Xref  (embedded
.\"	Of course, you have to process the output yourself
.\"	in some meaninful fashion.
.if \nF \{
.de IX
.tm Index:\\$1\t\\n%\t"\\$2"
..
.nr % 0
.rr F
.\}
.TH CVS 3 "perl 5.005, patch 02" "17/Jun/99" "User Contributed Perl Documentation"
.UC
.if n .hy 0
.if n .na
.ds C+ C\v'-.1v'\h'-1p'\s-2+\h'-1p'+\s0\v'.1v'\h'-1p'
.de CQ          \" put $1 in typewriter font
.ft CW
'if n "\c
'if t \\&\\$1\c
'if n \\&\\$1\c
'if n \&"
\\&\\$2 \\$3 \\$4 \\$5 \\$6 \\$7
'.ft R
..
.\" @(#)ms.acc 1.5 88/02/08 SMI; from UCB 4.2
.	\" AM - accent mark definitions
.bd B 3
.	\" fudge factors for nroff and troff
.if n \{\
.	ds #H 0
.	ds #V .8m
.	ds #F .3m
.	ds #[ \f1
.	ds #] \fP
.\}
.if t \{\
.	ds #H ((1u-(\\\\n(.fu%2u))*.13m)
.	ds #V .6m
.	ds #F 0
.	ds #[ \&
.	ds #] \&
.\}
.	\" simple accents for nroff and troff
.if n \{\
.	ds ' \&
.	ds ` \&
.	ds ^ \&
.	ds , \&
.	ds ~ ~
.	ds ? ?
.	ds ! !
.	ds /
.	ds q
.\}
.if t \{\
.	ds ' \\k:\h'-(\\n(.wu*8/10-\*(#H)'\'\h"|\\n:u"
.	ds ` \\k:\h'-(\\n(.wu*8/10-\*(#H)'\`\h'|\\n:u'
.	ds ^ \\k:\h'-(\\n(.wu*10/11-\*(#H)'^\h'|\\n:u'
.	ds , \\k:\h'-(\\n(.wu*8/10)',\h'|\\n:u'
.	ds ~ \\k:\h'-(\\n(.wu-\*(#H-.1m)'~\h'|\\n:u'
.	ds ? \s-2c\h'-\w'c'u*7/10'\u\h'\*(#H'\zi\d\s+2\h'\w'c'u*8/10'
.	ds ! \s-2\(or\s+2\h'-\w'\(or'u'\v'-.8m'.\v'.8m'
.	ds / \\k:\h'-(\\n(.wu*8/10-\*(#H)'\z\(sl\h'|\\n:u'
.	ds q o\h'-\w'o'u*8/10'\s-4\v'.4m'\z\(*i\v'-.4m'\s+4\h'\w'o'u*8/10'
.\}
.	\" troff and (daisy-wheel) nroff accents
.ds : \\k:\h'-(\\n(.wu*8/10-\*(#H+.1m+\*(#F)'\v'-\*(#V'\z.\h'.2m+\*(#F'.\h'|\\n:u'\v'\*(#V'
.ds 8 \h'\*(#H'\(*b\h'-\*(#H'
.ds v \\k:\h'-(\\n(.wu*9/10-\*(#H)'\v'-\*(#V'\*(#[\s-4v\s0\v'\*(#V'\h'|\\n:u'\*(#]
.ds _ \\k:\h'-(\\n(.wu*9/10-\*(#H+(\*(#F*2/3))'\v'-.4m'\z\(hy\v'.4m'\h'|\\n:u'
.ds . \\k:\h'-(\\n(.wu*8/10)'\v'\*(#V*4/10'\z.\v'-\*(#V*4/10'\h'|\\n:u'
.ds 3 \*(#[\v'.2m'\s-2\&3\s0\v'-.2m'\*(#]
.ds o \\k:\h'-(\\n(.wu+\w'\(de'u-\*(#H)/2u'\v'-.3n'\*(#[\z\(de\v'.3n'\h'|\\n:u'\*(#]
.ds d- \h'\*(#H'\(pd\h'-\w'~'u'\v'-.25m'\f2\(hy\fP\v'.25m'\h'-\*(#H'
.ds D- D\\k:\h'-\w'D'u'\v'-.11m'\z\(hy\v'.11m'\h'|\\n:u'
.ds th \*(#[\v'.3m'\s+1I\s-1\v'-.3m'\h'-(\w'I'u*2/3)'\s-1o\s+1\*(#]
.ds Th \*(#[\s+2I\s-2\h'-\w'I'u*3/5'\v'-.3m'o\v'.3m'\*(#]
.ds ae a\h'-(\w'a'u*4/10)'e
.ds Ae A\h'-(\w'A'u*4/10)'E
.ds oe o\h'-(\w'o'u*4/10)'e
.ds Oe O\h'-(\w'O'u*4/10)'E
.	\" corrections for vroff
.if v .ds ~ \\k:\h'-(\\n(.wu*9/10-\*(#H)'\s-2\u~\d\s+2\h'|\\n:u'
.if v .ds ^ \\k:\h'-(\\n(.wu*10/11-\*(#H)'\v'-.4m'^\v'.4m'\h'|\\n:u'
.	\" for low resolution devices (crt and lpr)
.if \n(.H>23 .if \n(.V>19 \
\{\
.	ds : e
.	ds 8 ss
.	ds v \h'-1'\o'\(aa\(ga'
.	ds _ \h'-1'^
.	ds . \h'-1'.
.	ds 3 3
.	ds o a
.	ds d- d\h'-1'\(ga
.	ds D- D\h'-1'\(hy
.	ds th \o'bp'
.	ds Th \o'LP'
.	ds ae ae
.	ds Ae AE
.	ds oe oe
.	ds Oe OE
.\}
.rm #[ #] #H #V #F C
.SH "NAME"
\f(CWVCS::CVS\fR \- Provide a simple interface to CVS (the Concurrent Versions System).
.PP
You need to be clear in your mind about the 4 directories involved:
.Ip "\(bu" 4
The directory where your source code resides before you import it into \s-1CVS\s0.
It is used only once \- during the import phase. Call this \f(CW$projectSource\fR.
.Ip "\(bu" 4
The directory into which you check out a read-write copy of the repository,
in order to edit that copy. Call this \f(CW$project\fR. You will spend up to 100% of
your time working within this directory structure.
.Ip "\(bu" 4
The directory in which the repository resides. This is \f(CW$CVSROOT\fR. Thus
\f(CW$projectSource\fR will be imported into \f(CW$CVSROOT\fR/$project.
.Ip "\(bu" 4
The directory into which you get a read-only copy of the repository, in order to,
say, make and ship that copy. Call this \f(CW$someDir\fR. It must not be \f(CW$project\fR.
.PP
Note: You cannot have a directory called \s-1CVS\s0 in your home directory. That's
just asking for trouble.
.SH "SYNOPSIS"
.PP
.Vb 1
\&        #!/usr/gnu/bin/perl -w
.Ve
.Vb 2
\&        use integer;
\&        use strict;
.Ve
.Vb 1
\&        use VCS::CVS;
.Ve
.Vb 12
\&        my($history)        = 1;
\&        my($initialMsg)     = 'Initial version';
\&        my($noChange)       = 1;
\&        my($nullTag)        = '';
\&        my($permissions)    = 0775;     # But not '0775'!
\&        my($project)        = 'project';
\&        my($projectSource)  = 'projectSource';
\&        my($raw)            = 0;
\&        my($readOnly)       = 0;
\&        my($releaseTag)     = 'release_0.00';
\&        my($vendorTag)      = 'vendorTag';
\&        my($verbose)        = 1;
.Ve
.Vb 1
\&        # Note the anonymous hash in the next line, new as of V 1.10.
.Ve
.Vb 6
\&        my($cvs)            = VCS::CVS -> new({
\&                                'project' => $project,
\&                                'raw' => $raw,
\&                                'verbose' => $verbose,
\&                                'permissions' => $permissions,
\&                                'history' => $history});
.Ve
.Vb 3
\&        $cvs -> createRepository();
\&        $cvs -> populate($projectSource, $vendorTag, $releaseTag, $initialMsg);
\&        $cvs -> checkOut($readOnly, $nullTag, $project);
.Ve
.Vb 3
\&        print join("\en", @{$cvs -> update($noChange)});
\&        print "\en";
\&        print join("\en", @{$cvs -> history()});
.Ve
.Vb 1
\&        exit(0);
.Ve
.SH "DESCRIPTION"
The \f(CWVCS::CVS\fR module provides an OO interface to CVS.
.PP
VCS \- Version Control System \- is the prefix given to each Perl module which
deals with some sort of source code control system.
.PP
I have seen CVS corrupt binary files, even when run with CVS's binary option \-kb.
So, since CVS doesn't support binary files, neither does VCS::CVS.
.PP
Stop press: CVS V 1.10 (with RCS 5.7) supports binary files.
.PP
Subroutines whose names start with a \*(L'_\*(R' are not normally called by you.
.PP
There is a test program included, but I have not yet worked out exactly how to
set it up for make test. Stay tuned.
.SH "INSTALLATION"
You install \f(CWVCS::CVS\fR, as you would install any perl module library,
by running these commands:
.PP
.Vb 4
\&        perl Makefile.PL
\&        make
\&        make test
\&        make install
.Ve
If you want to install a private copy of \f(CWVCS::CVS\fR in your home
directory, then you should try to produce the initial Makefile with
something like this command:
.PP
.Vb 3
\&        perl Makefile.PL LIB=~/perl
\&                or
\&        perl Makefile.PL LIB=C:/Perl/Site/Lib
.Ve
If, like me, you don't have permission to write man pages into unix system
directories, use:
.PP
.Vb 1
\&        make pure_install
.Ve
instead of make install. This option is secreted in the middle of p 414 of the
second edition of the dromedary book.
.SH "WARNING re CVS bugs"
The following are my ideas as to what constitutes a bug in CVS:
.Ip "\(bu" 4
The initial revision tag, supplied when populating the repository with
\&'cvs import\*(R', is not saved into \f(CW$CVSROOT\fR/\s-1CVSROOT/\s0val-tags.
.Ip "\(bu" 4
The \*(L'cvs tag\*(R' command does not always put the tag into \*(L'val-tags\*(R'.
.Ip "\(bu" 4
\&\f(CW'cvs checkout -dNameOfDir'\fR fails if NameOfDir =~ /\e/$/.
.Ip "\(bu" 4
\&\f(CW'cvs checkout -d NameOfDir'\fR inserts a leading space into the name of
the directory it creates.
.SH "WARNING re test environment"
This code has only been tested under Unix. Sorry.
.SH "WARNING re project names \*(M'v\*(S' directory names"
I assume your copy of the repository was checked out into a directory with
the same name as the project, since I do a \*(L'cd \f(CW$HOME\fR/$project\*(R' before running
\&'cvs status\*(R', to see if your copy is up-to-date. This is because some activity is
forbibben unless your copy is up-to-date. Typical cases of this include:
.Ip "\(bu" 4
\f(CWcheckOut\fR
.Ip "\(bu" 4
\f(CWremoveDirectory\fR
.Ip "\(bu" 4
\f(CWsetTag\fR
.SH "WARNING re shell intervention"
Some commands cause the shell to become involved, which, under Unix, will read your
\&.cshrc or whatever, which in turn may set CVSROOT to something other than what you
set it to before running your script. If this happens, panic...
.PP
Actually, I think I've eliminated such cases. You hope so.
.SH "WARNING re Perl bug"
As always, be aware that these 2 lines mean the same thing, sometimes:
.Ip "\(bu" 4
$self \-> {'thing'}
.Ip "\(bu" 4
$self->{'thing'}
.PP
The problem is the spaces around the \->. Inside double quotes, \*(L"...\*(R", the
first space stops the dereference taking place. Outside double quotes the
scanner correctly associates the \f(CW$self\fR token with the {'thing'} token.
.PP
I regard this as a bug.
.SH "\fIaddDirectory\fR\|($dir, \f(CW$subDir\fR, \f(CW$message\fR)"
Add an existing directory to the project.
.PP
$dir can be a full path, or relative to the CWD.
.SH "\fIaddFile\fR\|($dir, \f(CW$file\fR, \f(CW$message\fR)"
Add an existing file to the project.
.PP
$dir can be a full path, or relative to the CWD.
.SH "\fIcheckOut\fR\|($readOnly, \f(CW$tag\fR, \f(CW$dir\fR)"
Prepare & perform \*(L'cvs checkout\*(R'.
.PP
You call checkOut, and it calls _checkOutDontCallMe.
.Ip "\(bu" 4
$readOnly == 0 \-> Check out files as read-write.
.Ip "\(bu" 4
$readOnly == 1 \-> Check out files as read-only.
.Ip "\(bu" 4
$tag is Null \-> Do not call upToDate; ie check out repository as is.
.Ip "\(bu" 4
$tag is not Null \-> Call upToDate; Croak if repository is not up-to-date.
.PP
The value of \f(CW$raw\fR used in the call to new influences the handling of \f(CW$tag:\fR
.Ip "\(bu" 4
$raw == 1 \-> Your tag is passed as is to \s-1CVS\s0.
.Ip "\(bu" 4
$raw == 0 \-> Your tag is assumed to be of the form release_1.23, and is
converted to \s-1CVS\s0's form release_1_23.
.PP
$dir can be a full path, or relative to the \s-1CWD\s0.
.SH "\fIcommit\fR\|($message)"
Commit changes.
.PP
Called as appropriate by addFile, removeFile and removeDirectory,
so you don't need to call it.
.SH "\fIcreateRepository()\fR"
Create a repository, using the current \f(CW$CVSROOT\fR.
.PP
This involves creating these files:
.Ip "\(bu" 4
$\s-1ENV\s0{'\s-1CVSROOT\s0'}/\s-1CVSROOT/\s0modules
.Ip "\(bu" 4
$\s-1ENV\s0{'\s-1CVSROOT\s0'}/\s-1CVSROOT/\s0val-tags
.Ip "\(bu" 4
$\s-1ENV\s0{'\s-1CVSROOT\s0'}/\s-1CVSROOT/\s0history
.PP
Notes:
.Ip "\(bu" 4
The \*(L'modules\*(R' file contains these lines:
.Sp
.Vb 3
\&        CVSROOT  CVSROOT
\&        modules  CVSROOT  modules
\&        $self -> {'project'}  $self -> {'project'}
.Ve
where \f(CW$self\fR \-> {'project'} comes from the \*(L'project\*(R' parameter to \fInew()\fR
.Ip "\(bu" 4
The \*(L'val-tags\*(R' file is initially empty
.Ip "\(bu" 4
The \*(L'history\*(R' file is only created if the \*(L'history\*(R' parameter to \fInew()\fR is set.
The file is initially empty
.SH "\fIgetTags()\fR"
Return a reference to a list of tags.
.PP
See also: the \f(CW$raw\fR option to \fInew()\fR.
.PP
\f(CWgetTags\fR does not take a project name because tags belong to the repository
as a whole, not to a project.
.SH "\fIhistory\fR\|({})"
Report details from the history log, \f(CW$CVSROOT\fR/CVSROOT/history.
.PP
You must have used \fInew\fR\|({'history\*(R' => 1}), or some other mechanism, to create
the history file, before CVS starts logging changes into the history file.
.PP
The anonymous hash takes any parameters \*(L'cvs history\*(R' takes, and joins them
with a single space. Eg:
.PP
.Vb 1
\&        $cvs -> history();
.Ve
.Vb 1
\&        $cvs -> history({'-e' => ''});
.Ve
.Vb 1
\&        $cvs -> history({'-xARM' => ''});
.Ve
.Vb 1
\&        $cvs -> history({'-u' => $ENV{'LOGNAME'}, '-x' => 'A'});
.Ve
but not
.PP
.Vb 1
\&        $cvs -> history({'-xA' => 'M'});
.Ve
because it doesn't work.
.SH "\fInew\fR\|({})"
Create a new object. See the synopsis.
.PP
The anonymous hash takes these parameters, of which \*(L'project\*(R' is the
only required one.
.Ip "\(bu" 4
\&'project\*(R' => \*(L'killerApp\*(R'. The required name of the project. No default
.Ip "\(bu" 4
\&'permissions\*(R' => 0775. Unix-specific stuff. Default. Do not use \*(L'0775\*(R'.
.Ip "\(bu" 4
\&'history\*(R' => 0. Do not create \f(CW$CVSROOT\fR/\s-1CVSROOT/\s0history when \fIcreateRepository()\fR is called. Default
.Ip "\(bu" 4
\&'history\*(R' => 1. Create \f(CW$CVSROOT\fR/\s-1CVSROOT/\s0history, which initiates \*(L'cvs history\*(R' stuff
.Ip "\(bu" 4
\&'raw\*(R' => 0. Convert tags from \s-1CVS\s0 format to real format. Eg: release_1.23. Default.
.Ip "\(bu" 4
\&'raw\*(R' => 1. Return tags in raw \s-1CVS\s0 format. Eg: release_1_23.
.Ip "\(bu" 4
\&'verbose\*(R' => 0. Do not report on the progress of mkpath/rmtree
.Ip "\(bu" 4
\&'verbose\*(R' => 1. Report on the progress of mkpath/rmtree. Default
.SH "\fIpopulate\fR\|($sourceDir, \f(CW$vendorTag\fR, \f(CW$releaseTag\fR, \f(CW$message\fR)"
Import an existing directory structure. But, (sub) import is a reserved word.
.PP
Use this to populate a repository for the first time.
.PP
The value used for \f(CW$vendorTag\fR is not important; CVS discards it.
.PP
The value used to \f(CW$releaseTag\fR is important; CVS discards it (why?) but I
force it to be the first tag in \f(CW$CVSROOT\fR/CVSROOT/val-tags. Thus you
should supply a meaningful value. Thus \*(L'release_0_00\*(R' is strongly, repeat
strongly, recommended.
.PP
The value of \f(CW$raw\fR used in the call to new influences the handling of \f(CW$tag:\fR
.Ip "\(bu" 4
$raw == 1 \-> Your tag is passed as is to \s-1CVS\s0.
.Ip "\(bu" 4
$raw == 0 \-> Your tag is assumed to be of the form release_1.23, and is
converted to \s-1CVS\s0's form release_1_23.
.SH "\fIremoveDirectory\fR\|($dir)"
Remove a directory from the project.
.PP
This deletes the directory (and all its files) from your working copy
of the repository, as well as deleting them from the repository.
.PP
Warning: \f(CW$dir\fR will have \f(CW$CVSROOT\fR and \f(CW$HOME\fR prepended by this code.
Ie: \f(CW$dir\fR starts from \- but excludes \- your home directory
(assuming, of course, you've checked out into your home directory...).
.PP
You can't remove the current directory, or a parent.
.SH "\fIremoveFile\fR\|($dir, \f(CW$file\fR, \f(CW$message\fR)"
Remove a file from the project.
.PP
This deletes the file from your working copy of the repository,
as well as deleting it from the repository.
.PP
$dir can be a full path, or relative to the CWD.
\f(CW$file\fR is relative to \f(CW$dir\fR.
.SH "\fIrunOrCroak()\fR"
The standard way to run a system command and report on the result.
.SH "\fIsetTag\fR\|($tag)"
Tag the repository.
.PP
You call setTag, and it calls _setTag.
.PP
The value of \f(CW$raw\fR used in the call to new influences the handling of \f(CW$tag:\fR
.Ip "\(bu" 4
$raw == 1 \-> Your tag is passed as is to \s-1CVS\s0.
.Ip "\(bu" 4
$raw == 0 \-> Your tag is assumed to be of the form release_1.23, and is
converted to \s-1CVS\s0's form release_1_23.
.SH "\fIstripCVSDirs\fR\|($dir)"
Delete all CVS directories and files from a copy of the repository.
.PP
Each user directory contains a CVS sub-directory, which holds 3 files:
.Ip "\(bu" 4
Entries
.Ip "\(bu" 4
Repository
.Ip "\(bu" 4
Root
.PP
Zap \*(L'em.
.SH "\fIstatus()\fR"
Run cvs status.
.PP
Return a reference to a list of lines.
.PP
Only called by \fIupToDate()\fR, but you may call it.
.SH "\fIupdate\fR\|($noChange)"
Run \*(L'cvs \f(CW-q\fR [\f(CW-n\fR] update\*(R', returning a reference to a list of lines.
Each line will start with one of [UARMC?], as per the CVS docs.
.PP
$cvs \-> \fIupdate\fR\|(1) is a good way to get a list of uncommited changes, etc.
.Ip "\(bu" 4
$noChange == 0 \-> Do not add \f(CW-n\fR to the cvs command. Ie update your working copy
.Ip "\(bu" 4
$noChange == 1 \-> Add \f(CW-n\fR to the cvs command. Do not change any files
.SH "\fIupToDate()\fR"
.Ip "\(bu" 4
return == 0 \-> Repository not up-to-date.
.Ip "\(bu" 4
return == 1 \-> Up-to-date.
.SH "\fI_checkOutDontCallMe\fR\|($readOnly, \f(CW$tag\fR, \f(CW$dir\fR)"
Checkout a current copy of the project.
.PP
You call checkOut, and it calls this.
.Ip "\(bu" 4
$readOnly == 0 \-> Check out files as read-write.
.Ip "\(bu" 4
$readOnly == 1 \-> Check out files as read-only.
.SH "\fI_fixTag\fR\|($tag)"
Fix a tag which CVS failed to add.
.PP
Warning: \f(CW$tag\fR must be in CVS format: release_1_23, not release_1.23.
.SH "\fI_mkpathOrCroak\fR\|($self, \f(CW$dir\fR)"
There is no need for you to call this.
.SH "\fI_readFile\fR\|($file)"
Return a reference to a list of lines.
.PP
There is no need for you to call this.
.SH "\fI_setTag\fR\|($tag)"
Tag the current version of the project.
.PP
Warning: \f(CW$tag\fR must be in CVS format: release_1_23, not release_1.23.
.PP
You call setTag and it calls this.
.SH "\fI_validateObject\fR\|($tag, \f(CW$file\fR, \f(CW$mustBeAbsent\fR)"
Validate an entry in one of the CVS files \*(L'module\*(R' or \*(L'val-tags\*(R'.
.PP
Warning: \f(CW$tag\fR must be in CVS format: release_1_23, not release_1.23.
.SH "AUTHOR"
\f(CWVCS::CVS\fR was written by Ron Savage \fI<rpsavage@ozemail.com.au>\fR in 1998.
.SH "LICENCE"
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

.rn }` ''
.IX Title "CVS 3"
.IX Name "C<VCS::CVS> - Provide a simple interface to CVS (the Concurrent Versions System)."

.IX Header "NAME"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "SYNOPSIS"

.IX Header "DESCRIPTION"

.IX Header "INSTALLATION"

.IX Header "WARNING re CVS bugs"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "WARNING re test environment"

.IX Header "WARNING re project names \*(M'v\*(S' directory names"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "WARNING re shell intervention"

.IX Header "WARNING re Perl bug"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIaddDirectory\fR\|($dir, \f(CW$subDir\fR, \f(CW$message\fR)"

.IX Header "\fIaddFile\fR\|($dir, \f(CW$file\fR, \f(CW$message\fR)"

.IX Header "\fIcheckOut\fR\|($readOnly, \f(CW$tag\fR, \f(CW$dir\fR)"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIcommit\fR\|($message)"

.IX Header "\fIcreateRepository()\fR"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIgetTags()\fR"

.IX Header "\fIhistory\fR\|({})"

.IX Header "\fInew\fR\|({})"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIpopulate\fR\|($sourceDir, \f(CW$vendorTag\fR, \f(CW$releaseTag\fR, \f(CW$message\fR)"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIremoveDirectory\fR\|($dir)"

.IX Header "\fIremoveFile\fR\|($dir, \f(CW$file\fR, \f(CW$message\fR)"

.IX Header "\fIrunOrCroak()\fR"

.IX Header "\fIsetTag\fR\|($tag)"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIstripCVSDirs\fR\|($dir)"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIstatus()\fR"

.IX Header "\fIupdate\fR\|($noChange)"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fIupToDate()\fR"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fI_checkOutDontCallMe\fR\|($readOnly, \f(CW$tag\fR, \f(CW$dir\fR)"

.IX Item "\(bu"

.IX Item "\(bu"

.IX Header "\fI_fixTag\fR\|($tag)"

.IX Header "\fI_mkpathOrCroak\fR\|($self, \f(CW$dir\fR)"

.IX Header "\fI_readFile\fR\|($file)"

.IX Header "\fI_setTag\fR\|($tag)"

.IX Header "\fI_validateObject\fR\|($tag, \f(CW$file\fR, \f(CW$mustBeAbsent\fR)"

.IX Header "AUTHOR"

.IX Header "LICENCE"

