#!/usr/local/bin/perl
#
# Copyright (C) 1993-1998 Ken'ichi Fukamachi
#          All rights reserved. 
#               1993-1996 fukachan@phys.titech.ac.jp
#               1996-1998 fukachan@sapporo.iij.ad.jp
# 
# FML is free software; you can redistribute it and/or modify
# it under the terms of GNU General Public License.
# See the file COPYING for more details.
#
# q$Id$;
$Rcsid   = 'msend 4.0';

# For the insecure command actions
$ENV{'PATH'}  = '/bin:/usr/ucb:/usr/bin';	# or whatever you need
$ENV{'SHELL'} = '/bin/sh' if $ENV{'SHELL'} ne '';
$ENV{'IFS'}   = '' if $ENV{'IFS'} ne '';

# "Directory of Mailing List(where is config.ph)" and "Library-Paths"
# format: fml.pl [-options] DIR(for config.ph) [PERLLIB's -options]
# Now for the exist-check (DIR, LIBDIR), "free order is available"
foreach (@ARGV) { 
    /^\-/   && &Opt($_) || push(@INC, $_);
    $LIBDIR || ($DIR  && -d $_ && ($LIBDIR = $_));
    $DIR    || (-d $_ && ($DIR = $_));
    -d $_   && push(@LIBDIR, $_);
}
$DIR    = $DIR    || '/home/beth/fukachan/w/fml';
$LIBDIR	= $LIBDIR || $DIR;
$0 =~ m#^(.*)/(.*)# && do { unshift(@INC, $1); unshift(@LIBDIR, $1);};
unshift(@INC, $DIR); #IMPORTANT @INC ORDER; $DIR, $1(above), $LIBDIR ...;


#################### MAIN ####################
# a little configuration before the action
# this code is required since msend has newsyslog(8) actions;
if ($MSEND_UMASK || $UMASK) {
    $MSEND_UMASK ? umask($MSEND_UMASK) : umask($UMASK);
}
elsif ($USE_FML_WITH_FMLSERV) {
    umask(007); # rw-rw----
}
else {
    umask(077); # rw-------
}

chdir $DIR || die "Can't chdir to $DIR\n";

########## PROCESS GO! ##########
require 'libkern.pl';		        # not using :include:..;

if ($0 eq __FILE__) {
    # defaults header;
    $Envelope{'h:From:'} = $From_address = "msend";
    $SLEEPTIME           = 5;
    $MSEND_SUBJECT_TEMPLATE = "Digest _ARTICLE_RANGE_ _PART_ _ML_FN_";

    &InitConfig;		# initialize date etc..

    &SlowStart if $Opt{"opt:s"};# sleep a little 
				# to be shifed from cron kick off

    require 'libfop.pl';	# file operations

    &MSendInit(*Envelope);	# IF $MSEND_RC is NOT SET, exit

    $Quiet = 1 if $Opt{"opt:q"}; # quiet mode;

    if (! $Quiet) {
	print STDERR "MatomeOkuri Control Program for $ML_FN\n";
	print STDERR "   $Rcsid\n   \$MSEND_RC = $MSEND_RC\n";
    }

    # Daemon or Self Running;
    if ($Opt{"opt:b"} eq 'd' || $Opt{"opt:b"} eq 'sr') {
	local($t);
	while (1) {
	    $t = time;
	    &ExecMSend; # timeout within
	    $t = time - $t; # used time 
	    &Log("MSend Daemon: sleep(3600 - $t)") if $debug;
	    $0 = "$FML: MSend Daemon $ML_FN <$LOCKFILE>";

	    sleep(3600 - $t); # adjust the sleeptime;
	}
    }
    else {
	&ExecMSend;
    }

    exit 0;				# the main ends.
}
else {
    &MSendInit(*Envelope);		# IF $MSEND_RC is NOT SET, exit

    print STDERR "Loading MSend.pl as a library\n" if $debug;
    for $proc (GetTime, InitConfig, GetID , Debug, MSending, 
	 MSendMasterControl, MSendRCConfig, Log, 
	 Logging, Warn, eval, Opt, Flock, Funlock) {
	undef &$proc;
    }
}

#################### MAIN ENDS ####################

##### SubRoutines #####
sub ExecMSend
{
    &GetTime;
    
    $Hour || die "Not Set \$Hour Variable\n";

    # additional before action
    $MSEND_START_HOOK && &eval($MSEND_START_HOOK, 'Start hook'); 

    # NOTIFICATION of NO TRAFFIC
    $MSEND_NOTIFICATION && &MSendNotifyP && &MSendNotify(*Envelope);

    # set timeout for the whole process (against the lock of IPC)
    local($evid);
    $evid = &SetEvent($TimeOut{'flock'} || 3600, 'TimeOut') if $HAS_ALARM;

    &MSend4You;			        # MAIN

    if ($Opt{"opt:n"}|| $debug && ($ID % 3 == 0)) {     # debug mode
	local($sep) =  "-" x 65;

	if (! $Quiet) {
	    print STDERR 
		"\n$sep\nDEBUG MODE try turn over \@NEWSYSLOG_FILES\n";
	}

	require 'libnewsyslog.pl'; 
	&NewSyslog(@NEWSYSLOG_FILES);
	print STDERR "$sep\n\n";
    }

    #&MSendRunHooks;			        # run hooks after unlocking

    &Notify if $Envelope{'message'};    # Reply some report if-needed.
	                                # should be here for e.g. mget..

    &ClearEvent($evid) if $evid;
}


sub MSend4You
{
    &Lock;
    &ReloadMySelf;

    &GetID;				# set $ID
    &GetDistributeList;

    &Unlock;			        # unlock against slow distributing

    &MSendMasterControl;

    &Lock;			        # lock to reconfig MSendRC

    &MSendRCConfig;			# When new comers exist. 

    &eval($_PCB{'Destr'}, 'Destructer:');# Destructer;

    &Unlock;			        # Unlock and ENDS
}


# Check the Matome Okuri Kankaku
# if 2 hours, 0, 2, 4, 6, 8 ...(implies modulus is 2)
sub MSendP
{
    local($who, $str) = @_;

    if ((! $str) && (!$Quiet)) {
	printf STDERR 
	    "%-30s [(%-2d %% %-2d == 0) && (%-5d - %-5d)>=0] mode=%s\n",
	    $who, $Hour, $When{$who}, $ID, $Request{$who}, $mode{$who};
	    # &DocModeLookup("#".$mode{$who});
    }

    return if (! defined($When{$who}));

    # CHECK: Modulus 
    if (($ID - $Request{$who}) >= 0) {
	return 1 if (0 == ($Hour % $When{$who}));
	return 1 if ($When{$who} > 12 && ($Hour + 24 == $When{$who}));
    }

    return 0;
}


# Get ID 
sub GetID
{
    if (open(IDINC, $SEQUENCE_FILE)) {
	$ID = <IDINC>; 
	chop $ID;
	close(IDINC);
	$ID;
    }
    else {
	0;
    }
}


# VARIABLE LIST
# %Request	: send mails from $Request{$rcpt} to  $ID
# %When		: the time to send
# %mode		: mode of sending
# %MRcpt		: recipient (if relay, aleady expanded relay-address)
#
# one pass to cut out the header and the body
sub GetDistributeList
{
    local($who) = @_;		# use when "# matome 0"
    local($rehash);

    # configuration of MSEND_RC
    if (-z $MSEND_RC) {		# if filesize is 0,
	print STDERR "WARNING: $MSEND_RC filesize=0 O.K.?\n" unless $Quiet;
    }

    if (! open(MSEND_RC, $MSEND_RC)) {
	print STDERR "not found $MSEND_RC\n" unless -f $MSEND_RC;
	&Log("$MSEND_RC not found") unless -f $MSEND_RC;
	print STDERR "cannot open $MSEND_RC:$!\n";
	&Log("cannot open $MSEND_RC:$!");
	return;
    };

    open(BACKUP, ">> $MSEND_RC.bak") || do {
	print STDERR "cannot open $MSEND_RC.bak:$!\n";
	&Log("cannot open $MSEND_RC.bak:$!");
	return;
    };
    print BACKUP "-----Backup on $Now-----\n";

    {
	local($rcpt, $rc);

	# make a table of "when" a matomeokuri is sent to "who".
      line: while (<MSEND_RC>) {
	  print BACKUP $_;
	  next line if /^\#/o;	# skip comment and off member
	  next line if /^\s*$/o;# skip null line;

	  chop;

	  tr/A-Z/a-z/;		# E-mail form(RFC822)

	  ($rcpt, $rc)    = split(/\s+/, $_);
	  $MRcpt{$rcpt}   = $rcpt;
	  $Request{$rcpt} = $rc;

	  $rehash = $rc if $who && &AddressMatch($who, $rcpt);
      }

	close MSEND_RC; 
	close BACKUP;
    }

    # REHASH when "# matome 0", usually $who == nil;
    return $rehash if $who;

    if ($debug) {
	foreach (keys %MRcpt) {
	    printf STDERR "Mrcpt:\t%-30s seq=%s\n", $MRcpt{$_}, $Request{$_}; 
	}
	print STDERR "\n";
    }

    ### O.K. open ACTIVE LIST and check matomeokuri or not 
    &AdjustActiveAndMemberLists; # tricky

    # plural active_list available (97/03/26)
    {
	local(@a) = (@ACTIVE_LIST, $ACTIVE_LIST);
	&Uniq(*a);
	for (@a) { &MSendReadActiveList($_);}
    }

    # debug 
    if ($debug) {
	foreach (keys %MRcpt) {
	    printf STDERR "%-30s modulus=%d mode=%s\n", 
	    $MRcpt{$_}, $When{$_}, $mode{$_};
	    #$MRcpt{$_}, $When{$_}, &DocModeLookup("#".$mode{$_});
	}
	print STDERR "\n";
    }
}


sub MSendReadActiveList
{
    local($active) = @_;
    
    &Log("ReadActiveRecipients:$active") if $debug_active;

    if (! open(ACTIVE_LIST, $active)) {
	print STDERR "cannot open $ACTIVE_LIST:$!\n";
	return;
    };

    # generate recipients table
    local($rcpt, $opt, $w, $relay, $who, $mxhost, $d, $m);

  line: while (<ACTIVE_LIST>) {	# RMS <-> Relay, Matome, Skip
      chop;

      next line if /^\#/o;	 # skip comment and off member
      next line if /^\s*$/o; # skip null line
      next line if /^$MAIL_LIST/i; # no loop back
      next line if $CONTROL_ADDRESS && /^$CONTROL_ADDRESS/i;

      tr/A-Z/a-z/;		# E-mail form(RFC822)
      s/(\S+)\s\#.*$/$1/;	# strip comment, not \S+ for mx;

      # Backward Compatibility.	tricky "^\s".Code above need no /^\#/o;
      s/\smatome\s+(\S+)/ m=$1 /i;
      s/\sskip\s*/ s=skip /i;
      ($rcpt, $opt) = split(/\s+/, $_, 2);
      $opt = ($opt && !($opt =~ /^\S=/)) ? " r=$opt " : " $opt ";

      # in this stage; possible addr form is "addr [rms]=\S+ [rms]=\S+ ... "
      # we permit and use only "addr m= r= " and "addr m= ".
      next line if /\ss=/io; # options [sm]= are not exclusive each other --;;
      next line unless /\sm=/io; # for MatomeOkuri ver.2;

      printf STDERR "msend::rcpt:\t%-30s %s\n", $rcpt, $opt if $debug;

      # set candidates of delivery
      $MRcpt{$rcpt} = $rcpt;

      # Matomeokuri Mode Settings
      if ($opt =~ /\sm=(\d+)\s/i) {
	  $When{$rcpt}  = $DefaultWhen || $1;
	  ($d, $m) = &ModeLookup($1.$2);
	  # $mode{$rcpt}  = $m; # = 'gz'; 
	  $mode{$rcpt} = $MSEND_MODE_DEFAULT || $m;
      }
      elsif ($opt =~ /\sm=(\d+)([A-Za-z]+)\s/i) {
	  $When{$rcpt}  = $DefaultWhen || $1;
	  ($d, $m) = &ModeLookup($1.$2);
	  $mode{$rcpt}  = $m;
      }
      else {
	  $mode{$rcpt} = $MSEND_MODE_DEFAULT || 'gz';
	  print STDERR "ERROR: NO MATCH OPTION[$opt], so => $mode{$rcpt} mode\n";
      }

      # Relay
      if ($opt =~ /\sr=(\S+)/i) {
	  $relay = $1;
	  $MRcpt{$rcpt} = "\@$relay:$rcpt";
      }	# % relay is not refered in RFC, but effective in Sendmail's.

      $When{$rcpt} = 1 if $Opt{'opt:a'}; # opttion -a always(for Ver.5);

  }# end of while;

    close(ACTIVE_LIST);
}


sub MSending
{
    local($left, $right, $packp, @to) = @_;
    local($to) = join(" ", @to);
    local(@filelist, $total);

    $0 = "$FML: MSending to $to $ML_FN <$LOCKFILE>";

    # check the given condistion is correct or not?
    print STDERR "TRY $left -> $right for $to \n" if $debug;
    if (!defined($left)) { 
	&Log("MSend: Cannot find left  for $to"); return;
    }
    if (!defined($right)) { 
	&Log("MSend: Cannot find right for $to"); return;
    }

    # get a file list to send
    for($left .. $right) { push(@filelist, "$SPOOL_DIR/$_");}

    # Sending
    &Log("MSend: $left -> $right ($to)");
    print STDERR "MSend: $left -> $right ($to)\n" unless $Quiet;
     
    $0 = "$FML: MSending to $to $ML_FN ends <$LOCKFILE>";

    # matome.gz -> matome.ish in LhaAndEncode2Ish().
    local($total, $tmp, $mode, $name, $s, $a, $msend_subject, $field);

    $tmp   = "$FP_TMP_DIR/MSend$$"; # relative
    $mode  = $mode{$to[0]};
    $total = &DraftGenerate($tmp, $mode, 
			    &GetProtoByMode('matome', $mode),
			    @filelist);

    ### MSEND header Generation ###
    # Make a subject here since mode::constructor in DraftGenerate. 
    {
	$rfc1153 = $_PCB{'subject', $mode};
	$name    = &DocModeLookup("#3$mode");
	$a       = $left < $right ? "Articles $left-$right" : "Article $left";

	local(%template_cf) = ("_RFC1153_INFO_",  $rfc1153,
			       "_DOC_MODE_",      "[$name]",
			       "_ARTICLE_RANGE_", $a,
			       );
	
	$msend_subject = 
	    &SubstituteTemplate($MSEND_SUBJECT_TEMPLATE, *template_cf);

	($field, $name) = split(/[\s:]+/, $XMLNAME);
	if (! grep(/^($field)$/, @HdrFieldsOrder)) {# against duplicatation
	    &ADD_FIELD($field);
	    &DEFINE_FIELD_OF_REPORT_MAIL($field, $name);
	}

	# Please define "$msend_subject = ....;" in MSEND_HEADER_HOOK;
	if ($MSEND_HEADER_HOOK) {
	    &eval($MSEND_HEADER_HOOK, 'MSend Header Hook'); 
	}

	$msend_subject = $msend_subject || $s; # $s is backward ?
    }

    local(@rcpt);

    $Envelope{'GH:Precedence:'} = $PRECEDENCE || 'list';

    if ($total) {
	# rewriting each $addr => rcpt to: address; (for relay)
	undef @rcpt;
	for (@to) { push(@rcpt, $MRcpt{$_});}

	&Log("MSend: total =[$total], sendx to @rcpt") if $debug_msend;

	&SendingBackInOrder($tmp, $total, $msend_subject, ($SLEEPTIME || 3), @rcpt);
	$0 = "$FML: MSending to $to $ML_FN ends <$LOCKFILE>";

	# may duplicate but cache out agasint errors
	# though removed in &MSendRCConfig
	for (@rcpt) {
	    $_ = "$_\t". ($ID + 1). "\n";
	    &Append2($_, $MSEND_RC);
	}
    }
    else {
	&Log("MSend: total =[$total], so not send to @to") if $debug_msend;
    }
}


sub MSendMasterControl
{
    local(%mconf, $id, $mode);

    $0 = "$FML: MSendMasterControl $ML_FN <$LOCKFILE>";

    # gathering same condition requests;
    # %MRcpt: addr =hash=> <rcpt to:'s address> (may addr != rcpt to:);
    foreach (keys %MRcpt) {
	if (! $When{$_}) {
	    print STDERR "Remove $MRcpt{$_}\n" unless $Quiet;
	    delete $MRcpt{$_};
	    next;
	}

	# patched by Shigeki Morimoto <mori@isc.mew.co.jp>
	# fml-support:00338 on Tue, 18 Apr 1995 10:52:24 +0900
        # if now the time to send
	if (1 == &MSendP($_)) {
	    # determine the first $ID
	    $id   = ($Request{$_} || $ID);
	    $mode = $mode{$_};

	    # Make a list ($id $mode)
	    # ($id $mode) is required for the last "change command"
	    # THIS LIST is required to lighten the sendmail work by 
	    # setting a list to deliver		

	    # original: $mconf{"$id:$mode"} .= $MRcpt{$_}." ";
	    $mconf{"$id:$mode"} .= "$_ "; # addr (!= rcpt (e.g. relay))
	    print STDERR "\$mconf{\"$id:$mode\"} = $mconf{\"$id:$mode\"}\n"
		unless $Quiet;
	}
    }

    # O.K. sending for each same condition group
    local(@to, $id, $mode, $addr);
    for (keys %mconf) {
	($id, $mode) = split(/:/, $_);
	@to = split(/\s+/, $mconf{$_}); # addr list

	if ($debug) {
	    &Debug("\n---mconf:\nid=$id\nmode=$mode");
	    &Debug("rcpt=@to");
	}

	# MSending($left, $right, $mode, @to);
	if (! $Quiet) {
	    print STDERR "&MSending($id, $ID, $mode, \@to);\n";
	    print STDERR "\@to => @to\n";
	}

	# passed addr entries (not rcpt to: list)
	&MSending($id, $ID, $mode, @to);
    }
}


sub MSendRCConfig
{
    $0 = "$FML: MSendRCConfig $ML_FN <$LOCKFILE>";
    local($warn, $who);

    ### Update RC temporary file ###
    open(MSEND_RC, "> $MSEND_RC.new") || do {
	print STDERR "cannot open $MSEND_RC. Cannot reset:$!\n";
	&Log("cannot open $MSEND_RC. Cannot reset:$!");
	return;
    };
    select(MSEND_RC); $| = 1; select(STDOUT);

    print STDERR "\n" if $debug;

    foreach $who (keys %MRcpt) { 
	print STDERR "Reconfigure MSendrc\t[$who]\n" if $debug;
	next unless $MRcpt{$who}; # if matome 0, remove the member

	# if sent, reset the values
	if (1 == &MSendP($who, "NO_OUTPUT_HERE")) {
	    print MSEND_RC $who, "\t", $ID + 1, "\n";
	}
	else {			# not sent, old values
	    print MSEND_RC $who, "\t", 
	    $Request{$who} ? $Request{$who} : $ID, "\n"; 
	    # if no counter, add the present one
	}
    }

    close(MSEND_RC);

    ### Update RC file ###
    if ((! -z $MSEND_RC) && -z "$MSEND_RC.new") {
	print STDERR "WARNING:\n";
	print STDERR "\tReConfigured MSendrc must be filesize=0.\nO.K.?\n";
#	&Log("msend: $MSEND_RC must be filesize=0");
#	&Warn("msend Inconsistency", 
#	      "$MSEND_RC must be filesize=0\nO.K.?\n");
	# return;# if only one matome -> synchronous delivery case?
    }


    if (! rename("$MSEND_RC.new", $MSEND_RC)) {
	print STDERR "ERROR:\n\tFILE UPDATE FAILS for $MSEND_RC.new\n";
	&Log("msend: FILE UPDATE ERROR: $MSEND_RC.new");
	&Warn("msend Inconsistency", 
	      "msend: FILE UPDATE ERROR: $MSEND_RC.new");
    }

    # remove the backup "MSendrc.bak" at moring 6 on Sunday
    if ((! $MSEND_NOT_USE_NEWSYSLOG) && 
	('Sun' eq $WDay[$wday]) && (6 == $Hour)) {
	if (! $Quiet) {
	    print STDERR ('*' x 70)."\n\n";
	    print STDERR "Newsyslog at Sun 6 a.m\n\n";
	    print STDERR ('*' x 70)."\n\n"; 
	}

	require 'libnewsyslog.pl';
	&NewSyslog(@NEWSYSLOG_FILES);
    }

    &Warn("msend Inconsistency", $warn) if $warn;
}


# Distribute mail to members
sub MSendNotify
{
    $0 = "$FML: Distributing <$LOCKFILE>";
    local($mail_file, $status, $num_rcpt, $s, @Rcpt);
    local(*e) = @_;

    ###### $Envelope{"h::"} #####
    $e{"h:Return-Path:"}	= $MAINTAINER;
    $e{"h:Date:"}	= $MailDate;
    $e{"h:From:"}	= $MAINTAINER;
    $e{"h:To:"}		= $MAIL_LIST;
    $e{"h:Errors-To:"}	= $MAINTAINER if $AGAINST_NIFTY;
    $e{"h:Precedence:"}	= 'list';

    # Please set $MSEND_NOTIFICATION_SUBJEC Tin config.ph
    $e{"h:Subject:"}	= 
	$MSEND_NOTIFICATION_SUBJECT || "Notification $ML_FN";

    # Original is for 5.67+1.6W, but R8 requires no MX tuning tricks.
    # So version 0 must be forever(maybe) :-)
    # RMS = Relay, Matome, Skip; C = Crosspost;
    $Rcsid =~ s/^(.*)(\#\d+:\s+.*)/$1.($USE_CROSSPOST?"(rmsc)":"(rms)").$2/e;
    $Rcsid =~ s/\)\(/,/g;

    ##### ML Preliminary Session Phase 03: get @Rcpt
    {
	local(@a) = (@ACTIVE_LIST, $ACTIVE_LIST);
	&Uniq(*a);
	for (@a) { &MSendNotifyReadActiveList($_);}
    }

    ##### ML Distribute Phase 01: Fixing and Adjusting *Header
    # Added INFOMATION
    if (! $MSEND_NOT_USE_X_ML_INFO) {
	$e{'h:X-ML-INFO:'} = 
	    "If you have a question, send $e{'trap:ctk'} help|Mail ".&CtlAddr;
    }

    # set Reply-To:, use "ORIGINAL Reply-To:" if exists ??? (96/2/18, -> Reply)
    $e{'h:Reply-To:'} = 
	$e{'fh:reply-to:'} || $e{'h:Reply-To:'} || $MAIL_LIST;


    # STAR TREK SUPPORT:-);
    if ($APPEND_STARDATE) { &use('stardate'); $e{'h:X-Stardate:'} = &Stardate;}

    # Server info to add
    $e{'h:X-MLServer:'}  = $Rcsid if $Rcsid;
    $e{'h:X-MLServer:'} .= "\n\t($rcsid)" if $debug && $rcsid;
    $e{"h:$XMLCOUNT:"}   = $id || sprintf("%05d", $ID); # 00010;
    $e{"h:X-ML-Info:"}   = &GenXMLInfo;

    ##### ML Distribute Phase 02: Generating Hdr
    # This is the order recommended in RFC822, p.20. But not clear about X-*
    local(%dup);
    for (@HdrFieldsOrder) {
	# print STDERR "\$e{'h:$_:'}\t". $e{"h:$_:"} ."\n";
	$lcf = $_; $lcf =~ tr/A-Z/a-z/; # lower case field name
	next if $dup{$_}; $dup{$_} = 1; # duplicate check;

	if ($e{"fh:$lcf:"}) {	# force some value to a field
	    $e{'Hdr'} .= "$_: ". $e{"fh:$lcf:"} ."\n";
	}
	elsif ($e{"oh:$lcf:"}) { # original fields
	    $e{'Hdr'} .= "$_: ". $e{"h:$lcf:"} ."\n" if $e{"h:$lcf:"};
	}
	elsif (/^:body:$/o && $body) {
	    $e{'Hdr'} .= $body;
	}
	elsif (/^:any:$/ && $e{'Hdr2add'}) {
	    $e{'Hdr'} .= $e{'Hdr2add'};
	}
	# ALREADY EXIST?
	elsif (/^Message\-Id/i && ($body =~ /Message\-Id:/i)) { 
	    ;
	}
	elsif (/^:XMLNAME:$/o) {
	    $e{'Hdr'} .= "$XMLNAME\n";
	}
	elsif (/^:XMLCOUNT:$/o) {
	    $e{'Hdr'} .= "$XMLCOUNT: $e{\"h:$XMLCOUNT:\"}\n";
	}
	elsif ($e{"h:$_:"}) {
	    $e{'Hdr'} .= "$_: ".($e{"fh:$lcf:"} || $e{"h:$_:"})."\n";
	}
    }

    ##### ML Distribute Phase 03: SMTP
    # IPC. when debug mode or no recipient, no distributing 
    if ($num_rcpt && (!$debug)) {
	$status = &Smtp(*e, *Rcpt);
	&Log("Sendmail:$status") if $status;
	&MSendNotifyTouch;
    }
}


sub MSendNotifyReadActiveList
{
    local($active) = @_;

    if (! open(ACTIVE_LIST, $active)) { return 0;}

    # Get a member list to deliver
    # After 1.3.2, inline-code is modified for further extentions.
    {
	local($rcpt, $opt, $w, $relay, $who, $mxhost);

      line: while (<ACTIVE_LIST>) {
	  chop;

	  next line if /^\#/o;	 # skip comment and off member
	  next line if /^\s*$/o; # skip null line
	  next line if /^$MAIL_LIST/i; # no loop back
	  next line if $CONTROL_ADDRESS && /^$CONTROL_ADDRESS/i;

	  tr/A-Z/a-z/;		# E-mail form(RFC822)
	  s/(\S+)\s\#.*$/$1/;	# strip comment, not \S+ for mx;

	  # Backward Compatibility; tricky "^\s".Code above need no /^\#/o;
	  s/\smatome\s+(\S+)/ m=$1 /i;
	  s/\sskip\s*/ s=skip /i;

	  ($rcpt, $opt) = split(/\s+/, $_, 2);
	  $opt = ($opt && !($opt =~ /^\S=/)) ? " r=$opt " : " $opt ";

	  printf STDERR "%-30s %s\n", $rcpt, $opt if $debug;

	  # Crosspost Extension. if matched to other ML's, no deliber
	  if ($USE_CROSSPOST && $e{'crosspost'}) {
	      $w = $rcpt;
	      ($w)=($w =~ /(\S+)@\S+\.(\S+\.\S+\.\S+\.\S+)/ && $1.'@'.$2||$w);
	      print STDERR "   ".($NoRcpt{$w} && "not ")."deliver\n" if $debug;
	      next line if $NoRcpt{$w}; # no add to @Rcpt
	  }

	  ## exception ## next line if $opt =~ /\s[ms]=/i;# tricky "^\s";
	  next line if $SKIP{$rcpt};
	  next line if $skip{$rcpt}; # backward compat;_;

	  # Relay server
	  # % relay hack is not refered in RFC, but effective in Sendmail's;
	  if ($opt =~ /\sr=(\S+)/i || $DEFAULT_RELAY_SERVER) {
	      $relay = $1 || $DEFAULT_RELAY_SERVER;
	      $rcpt = "\@$relay:$rcpt";
	  }
	  
	  print STDERR "RCPT:<$rcpt>\n\n" if $debug;
	  push(@Rcpt, $rcpt);
      }

	close(ACTIVE_LIST);
    }
}


sub MSendNotifyP 
{ 
    ($Hour == 24 || $Hour == 1 || $Hour == 2 || $Hour == 3) &&
	(time - (stat($SEQUENCE_FILE))[9]) > (24 * 3600);
}


sub MSendInit
{
    local(*e) = @_;

    if ($USE_DATABASE) {
        &use('databases');

        # dump recipients
	my (%mib, %result, %misc, $error);
	&DataBaseMIBPrepare(\%mib, 'dump_active_list');
	&DataBaseCtl(\%Envelope, \%mib, \%result, \%misc);
	&Log("fail to dump active list") if $mib{'error'};
	exit 1 if $mib{'error'};
    }

    # defaults header;
    $Envelope{'h:From:'} = $From_address = "msend";
    $SLEEPTIME           = 5;
    $DefaultWhen   = 0;		# Default synchronous mode for 1153
    $Hour = (localtime(time))[2];	# Only this differ from &GetTime in fml.pl
    $Hour = (0 == $Hour) ? 24 : $Hour;

    $MSendTouchFile = "$TMP_DIR/msend_last_touch"; # what for ?

    ### SET DEFAULT MODE 
    # Default setting should be HERE 96/02/13 kishiba@ipc.hiroshima-u.ac.jp
    # DEFAULT ACTION is not 'mget'. 
    $MSEND_OPT_HOOK .= q%$MSendOpt{''} = 'gz';%;

    # To: $MAIL_LIST (delivery list is suppressed)
    $e{"GH:To:"} = $e{"GH:To:"} || "$MAIL_LIST (Delivery list is suppressed)";

    # for reply for matomeokuri
    $e{'GH:Reply-To:'} = $e{'GH:Reply-To:'} || $MAIL_LIST; 

    ### RFC1153 digest;
    if ($MSEND_MODE_DEFAULT eq "rfc1153") {
	# the standard for 1153-counter, but required?
	# anyway comment out below 95/6/27
	#    $DefaultWhen    = $DefaultWhen || 3;
	$MSEND_OPT_HOOK .= q%$MSendOpt{''} = 'rfc1153';%;
    }
    ### RFC934 
    elsif ($MSEND_MODE_DEFAULT eq "rfc934") {
	$MSEND_OPT_HOOK .= q%$MSendOpt{''} = 'rfc934';%;
    }

    # CHECK MSEND_RC DEFINED OR NOT? for fml 1.x (96/02/13)
    # Using the default value is dangerous. 
    # This variable should be not automatic-fixed
    # for the continuous use of msend.pl 
    # even in 1.x -> 2.x installing process ...
    if (! $MSEND_RC) {
	&Log("\$MSEND_RC IS NOT DEFINED", 
	     "Please Define \$MSEND_RC in config.ph");
	die "\$MSEND_RC IS NOT DEFINED, SO EXIT!\nPlease define \$MSEND_RC.\n";
    }
}



### :include: -> libkern.pl
# Getopt
sub Opt { push(@SetOpts, @_);}


### Section: utils
sub SlowStart
{
    # required before lock();
    &SRand;
    $sleep = int(rand($MSEND_SLOW_START_DELAY || 180));
    print STDERR "    sleep($sleep);\n" if $debug;
    sleep($sleep);
}


1;
