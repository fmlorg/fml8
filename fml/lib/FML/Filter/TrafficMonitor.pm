#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: TrafficMonitor.pm,v 1.3 2002/01/16 13:33:59 fukachan Exp $
#

package FML::Filter::TrafficMonitor;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::TrafficMonitor - Mail Traffic Information

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut

use File::CacheDir;
@ISA = qw(File::CacheDir);


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# open cache and return C<File::CacheDir> object.
sub _open_cache
{
    my ($self, $db, $args) = @_;
    my $dir  = $args->{ 'directory' };
    my $mode = 'temporal';
    my $days = 14;

    if ($dir) {
        my $obj = new File::CacheDir {
            directory  => $dir,
            cache_type => $mode,
            expires_in => $days,
        };

        $self->{ _obj } = $obj;
        return $obj;
    }

    undef;
}


sub _get_addrinfo
{
    my ($self, $curproc) = @_;
    my $msg  = $curproc->{'incoming_message'}->{ message };
    my $hdr  = $msg->whole_message_header;
    my $info = {};

    use Mail::Message::Date;
    $info->{'time'}     = time;
    $info->{'date'}     = Mail::Message::Date::date_to_unixtime($hdr->get('date'));
    $info->{'from'}     = $hdr->address_clean_up($hdr->get('from'));
    $info->{'sender'}   = $hdr->address_clean_up($hdr->get('sender'));
    $info->{'x-sender'} = $hdr->address_clean_up($hdr->get('x-sender'));
    $info->{'return-path'} = $hdr->address_clean_up($hdr->get('return-path'));

    return $info;
}


sub _get_hostinfo
{
    my ($self, $curproc) = @_;
    my $msg  = $curproc->{'incoming_message'}->{ message };
    my $hdr  = $msg->whole_message_header;
    my $info = {};

    # Analizeing Received:
    # XXX $status = &MTI::GetHostInfo(*hostinfo));

    return $info;
}


sub _save_addrinfo
{
    my ($self, $addrinfo, $db) = @_;

    # cache on address with the current time; also,
    # expire the address cache automatically by File::CacheDir
    my %uniq = ();
    for my $field (qw(from return-path sender x-sender)) {
  	next unless $info->{ $field };
	next if $uniq{$field}; $uniq{$field} = 1; # ensure uniqueness

	next if $MTI{$_} =~ /$time:/; # unique;

	$MTI{$_} .= " $time:$date";
    }
}


sub _save_hostinfo
{

    ## UNDER CURRENT IMPLEMENTATION, HOST INFO IS JUST ADDITONAL FYI.
    ## cache host info with Date: or Received:
    if (%hostinfo) {
	local($host, $rdate);
	while (($host, $rdate) = each %hostinfo) {
	    &MTICleanUp(*HI, $host, $rdate);
	    $HI{$host} .= " ${date}:$rdate";
	}
    }
}


sub analyze
{
    my ($self, $curproc) = _@;
    my ($db, $args, $addrinfo, $hostinfo);
    my $config = $curproc->{ config };

    # 0.
    $args = {
	directory => "/tmp",
    };

    # 1. get {addr,host}info and save it into cache.
    $self->_open_cache($db, $args);

    $addrinfo = $self->_get_addrinfo($curproc);
    $hostinfo = $self->_get_hostinfo($curproc);
    $self->_save_addrinfo($addrinfo, $db);
    $self->_save_hostinfo($addrinfo, $db);

    $self->_close_cache();

    # 2. reopen and analyze traffic information
    $self->_open_cache($db, $args);

    # CHECK ROUTINES to average traffic
    # if (($mode eq 'distribute' && $MTI_DISTRIBUTE_TRAFFIC_MAX) ||
    # ($mode eq 'command' && $MTI_COMMAND_TRAFFIC_MAX)) {
    # for (keys %addrinfo) {
    # &MTIProbe(*MTI, $_, "${mode}:max_traffic");	# open, close;
    # }}

    $self->_close_cache();

    # 3. reopen and analyze traffic information
    $self->_open_cache($db, $args);

    # local($fp) = $MTI_COST_EVAL_FUNCTION || 'MTISimpleBomberP';
    # &$fp(*e, *MTI, *HI, *addrinfo, *hostinfo);
    # EVAL HOOKS
    # if ($MTI_COST_EVAL_HOOK) { eval($MTI_COST_EVAL_HOOK); &Log($@) if $@;}

    $self->_close_cache();
}



sub MTIDBMOpen
{
    local($mode) = @_;
    local($error);

    ### OPEN HASH TABLES (SWITCH)
    if ($mode eq 'distribute') {
	$MTI_DB    = $MTI_DIST_DB    || "$FP_VARDB_DIR/mti.dist";
	$MTI_HI_DB = $MTI_HI_DIST_DB || "$FP_VARDB_DIR/mti.hi.dist";
    }
    elsif ($mode eq 'command') {
	$MTI_DB    = $MTI_COMMAND_DB    || "$FP_VARDB_DIR/mti.command";
	$MTI_HI_DB = $MTI_HI_COMMAND_DB || "$FP_VARDB_DIR/mti.hi.command";
    }
    else {
	&Log("MTI[$$] ERROR: MTICache called under an unknown mode");
	return $NULL;
    }

    # force the permission
    if ($USE_FML_WITH_FMLSERV) {
	chmod 0660, $MTI_DB, $MTI_HI_DB;
    }
    else {
	chmod 0600, $MTI_DB, $MTI_HI_DB;
    }

    ### DBM OPEN ###
    # perl 5 tie
    if ($MTI_TIE_TYPE) {
	eval "use $MTI_TIE_TYPE;";
	&Log($@) if $@;

	local($_) =  q#;
	tie(%MTI, $MTI_TIE_TYPE, $MTI_DB) ||
	    ($error++, &Log("MTI[$$]: cannot tie \%MTI as $MTI_TIE_TYPE"));
	tie(%HI, $MTI_TIE_TYPE, $MTI_HI_DB) ||
	    ($error++, &Log("MTI[$$]: cannot tie \%HI as $MTI_TIE_TYPE"));
	#;

	eval($_);
	&Log($@) if $@;
    }
    # perl 4 (default)
    else {
	if ($USE_FML_WITH_FMLSERV) {
	    dbmopen(%MTI, $MTI_DB, 0660) ||
		($error++, &Log("MTI[$$]: cannot bind \%MTI"));
	    dbmopen(%HI,  $MTI_HI_DB, 0660) ||
		($error++, &Log("MTI[$$]: cannot bind \%HI"));
	}
	else {
	    dbmopen(%MTI, $MTI_DB, 0600) ||
		($error++, &Log("MTI[$$]: cannot bind \%MTI"));
	    dbmopen(%HI,  $MTI_HI_DB, 0600) ||
		($error++, &Log("MTI[$$]: cannot bind \%HI"));
	}
    }

    $error ? 0 : 1;
}


sub MTIDBMClose
{
    dbmclose(%MTI);
    dbmclose(%HI);
}


sub MTIProbe
{
    local(*MTI, $addr, $mode) = @_;
    local(@c, $c, $s, $ss);

    &MTIDBMOpen($mode =~ /^(\w+):/ && $1) || return $NULL;

    if ($mode eq "distribute:max_traffic") {
	# count irrespective of contents
	@c = split(/\s+/, $MTI{$addr});
	$c = $#c + 1;

	if ($c > $MTI_DISTRIBUTE_TRAFFIC_MAX) {
	    $s  = "Distribute traffic ($c mails/$MTI_EXPIRE_UNIT s) ";
	    $s .= "exceeds \$MTI_DISTRIBUTE_TRAFFIC_MAX.";
	    $ss = "Reject post from $From_address for a while.";
	    &Log("MTI[$$]: $s");
	    &Log("MTI[$$]: $ss");
	    &MTIHintOut(*e, $addr) if $MTI_APPEND_TO_REJECT_ADDR_LIST;
	}
    }
    elsif ($mode eq "command:max_traffic") {
	# count irrespective of contents
	@c = split(/\s+/, $MTI{$addr});
	$c = $#c + 1;

	if ($c > $MTI_COMMAND_TRAFFIC_MAX) {
	    $s  = "Command traffic ($c mails/$MTI_EXPIRE_UNIT s) ";
	    $s .= "exceeds \$MTI_COMMAND_TRAFFIC_MAX.";
	    $ss = "Reject command from $From_address for a while.";
	    &Log("MTI[$$]: $s");
	    &Log("MTI[$$]: $ss");
	    &MTIHintOut(*e, $addr) if $MTI_APPEND_TO_REJECT_ADDR_LIST;
	}
    }

    &MTIDBMClose;

    $s ? ($MTIErrorString = "$s\n$ss") : $NULL; # return;
}

sub MTIGabageCollect
{
    local(*MTI, $time) = @_;
    local($k, $v);
    while (($k, $v) = each %MTI) {
	&MTICleanUp(*MTI, $k, $time);
	undef $MTI{$k} unless $MTI{$k};
    }
}

# expire history logs beyond $MTI_EXPIRE_UNIT
sub MTICleanUp
{
    local(*MTI, $addr, $time) = @_;
    local($mti, $t);

    $MTI_EXPIRE_UNIT = $MTI_EXPIRE_UNIT || 3600;

    for (split(/\s+/, $MTI{$addr})) {
	next unless $_;
	($t) = (split(/:/, $_))[0];
	next if ($time - $t) > $MTI_EXPIRE_UNIT;
	$mti .= $mti ? " $_" : $_;
    }

    $MTI{$addr} = $mti;
}

sub MTIError
{
    local(*e) = @_;

    if ($MTIErrorString) {
	&MTIWarn(*e, $MTIErrorString);
	1;
    }
    else {
	0;
    }
}

sub MTIWarn
{
    local(*e, $s) = @_;
    local($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	  $atime,$mtime,$ctime,$blksize,$blocks);
    local($cont, $s);

    $MTI_WARN_LASTLOG  = $MTI_WARN_LASTLOG  || "$FP_VARLOG_DIR/mti.lastwarn";
    $MTI_WARN_INTERVAL = $MTI_WARN_INTERVAL || 3600;

    # already exists (some errors occured in the past)
    if (-f $MTI_WARN_LASTLOG) {
	($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	 $atime,$mtime,$ctime,$blksize,$blocks)
	    = stat($MTI_WARN_LASTLOG);

	# ignore until the next waning time.
	if ((time - $mtime) < $MTI_WARN_INTERVAL) {
	    return 0;
	}
	elsif ((time - $mtime) < 2*$MTI_WARN_INTERVAL) {
	    $cont = 1;
	    &Append2(time, $MTI_WARN_LASTLOG);
	}
    }
    # the first time
    else {
	&Append2(time, $MTI_WARN_LASTLOG);
    }

    $s = "FML Mail Traffic Monitor System:\n\n".
	"I detect a burst traffic (mail bomb?) occurs now.\n";
    if ($cont) {
	$s .= "Fml MTI rejects submission of articles continuously.\n";
    }
    else {
	$s .= "Fml MTI rejects submission of articles hereafter.\n";
    }
    $s .= "The current rejected article:\n\n$MTIErrorString\n";

    &WarnE("FML Mail Traffic Monitor System Report $ML_FN", $s);
}


sub MTILog
{
    local(*e, $s) = @_;
    local($buf, $x, $h);

    $buf .= "We reject the following mail:\n\n";
    for ('return-path', 'date', 'from', 'sender', 'x-sender') {
	$h = $_;
	$h =~ s/^(\w)/ $x = $1, $x =~ tr%a-z%A-Z%, $x/e; # capitlalize
	$h =~ s/(\-\w)/$x = $1, $x =~ tr%a-z%A-Z%, $x/eg; # capitlalize
	$buf .= sprintf("%15s %s\n", "$h:", $e{"h:$_:"}) if $e{"h:$_:"};
    }
    $buf .= "\nsince\n$s\n";

    # IN TEST PHASE, please set $USE_MTI_TEST to reject mails automatically.
    # removed $USE_MTI_TEST in the future;
    $MTIErrorString .= $buf if $USE_MTI_TEST && $s;
}


sub MTIHintOut
{
    local(*e, $addr) = @_;
    local($rp, $hint);

    $hint = $MTI_MAIL_FROM_HINT_LIST || "$DIR/mti_mailfrom.hints";
    &Touch($hint) if ! -f $hint;

    # logs Erturn-Path: (hints for MTA e.g. sendmail)
    if ( $hdr->get('return-path:'}) {
	$rp = $hdr->address_clean_up( $hdr->get('return-path:'});

	if (! &Lookup($rp, $hint)) {
	    &Append2($hdr->address_clean_up( $hdr->get('return-path:'}, *e), $hint);
	}
    }

    # logs $addr to $DIR/spamlist (FML level)
    if ($addr && $MTI_APPEND_TO_REJECT_ADDR_LIST) {
	&Append2($addr, $REJECT_ADDR_LIST);
    }
}


######################################################################
package MTI;

sub Log { &main::Log(@_);}
sub ABS { $_[0] < 0 ? - $_[0] : $_[0];}

# should we try ?
#    if ($buf =~ /\@localhost.*by\s+(\S+).*;(.*)/) {
#    elsif ($buf =~ /from\s+(\S+).*;(.*)/) {
#    elsif ($buf =~ /^\s*by\s+(\S+).*;(.*)/) {
sub GetHostInfo
{
    local(*hostinfo, *e) = @_;
    local($host, $rdate, $p_rdate, @chain, $threshold);
    local($buf) = "\n $hdr->get('received:'}\n";
    local($host_pat) = '[A-Za-z0-9\-]+\.[A-Za-z0-9\-\.]+';

    # We trace Received: chain to detect network error (may be UUCP?)
    # where the threshold is 15 min.
    # NOT USED NOW
    $threshold = $main::MTI_CACHE_HI_THRESHOLD || 15*60; # 15 min.

    for (split(/\n\w+:/, $buf)) {
	undef $host; undef $rdate;

	s/\n/ /g;
	s/\(/ \(/g;
	s/by\s+($host_pat).*(\;.*)/$host = $1, $rdate = $2/e;

	if ($rdate) {
	    $rdate = &main::Date2UnixTime($rdate);
	    $rdate || next;	# skip if invalid Date:
	    $hostinfo{$host} = $rdate;

	    push(@chain, &ABS($rdate - $p_rdate)) if $p_rdate;
	    $p_rdate = $rdate;
	}
    }

    for (@chain) {
	if ($_ > $threshold) {
	    return "network is jammed? @chain";
	}
    }

    $NULL;
}


sub main::MTISimpleBomberP
{
    local(*e, *MTI, *HI, *addrinfo, *hostinfo) = @_;
    local($soft_limit, $hard_limit, $es, $addr);
    local($cr, $scr);

    # BOMBER OR NOT: the limit is
    # "traffic over sequential 5 mails with 1 mail for each 5s".
    $soft_limit = $main::MTI_BURST_SOFT_LIMIT || (5/5);
    $hard_limit = $main::MTI_BURST_HARD_LIMIT || (2*5/5);

    # GLOBAL in this Name Space; against divergence
    $Threshold = $main::MTI_BURST_MINIMUM || 3;

    # addresses
    for $addr (keys %addrinfo) {
	($cr, $scr)  = &SumUp($MTI{$addr});	# CorRelation

	if (($cr > 0) && $main::debug_mti) {
	    &Log("MTI[$$]: SumUp ".
		 sprintf("src_cr=%2.4f dst_cr=%2.4f", $scr, $cr));
	}

	# soft limit: scr > cr : busrt in src host not dst host
	# hard limit: cf > hard_limit or scr > hard_limit
	if ((&MTI_GE($scr, $cr) && ($scr > $soft_limit)) ||
	    ($scr > $hard_limit) ||
	    ($cr  > $hard_limit)) {
	    &Log("MTI[$$]: <$addr> must be a bomber;");
	    &Log("MTI[$$]:".
		 sprintf("src_cr=%2.4f >= dst_cr=%2.4f", $scr, $cr));
	    $es .= "   MTI[$$]: <$addr> must be a bomber,\n";
	    $es .= "   since the evaled costs are ".
		sprintf("src_cr=%2.4f >= dst_cr=%2.4f\n", $scr, $cr);
	    &main::MTIHintOut(*e);
	}
    }

    &main::MTILog(*e, $es) if $es;
}


sub MTI_GE
{
    if ($_[0] >= $_[1]) {
	return 1;
    }
    # within 3 %
    elsif (&ABS($_[0] - $_[1]) < $MTI_BURST_SOFT_LIMIT * 0.03) {
	return 1;
    }

    0;
}

sub COST
{
    &ABS($_[0]) < $Threshold ? $Threshold : &ABS($_[0]);
}


sub SumUp
{
    local($buf) = @_;
    local($cr, $d_cr, $time, $date, $p_time, $p_date);

    # reset
    $cr = $d_cr = 0;

    for (split(/\s+/, $buf)) {
	next unless $_;
	($time, $date) = split(/:/, $_);

	if ($p_time) { # $p_date may be invalid, so not check it.
	    $cr   += 1 / &COST($time - $p_time);
	    $d_cr += 1 / &COST($date - $p_date);
	}

	# cache on previous values
	($p_time, $p_date) = ($time, $date);
    }

    ($cr, $d_cr);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::TrafficMonitor appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
