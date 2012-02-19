#
# $Id$
#

package Jcode::_Classic;
use 5.004;
use Carp;
use strict;
use vars qw($RCSID $VERSION $DEBUG);

$RCSID = q$Id$;
$VERSION = do { my @r = (q$Revision$ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

$DEBUG = $Jcode::DEBUG;
use vars qw($USE_CACHE $NOXS);

$USE_CACHE = 1;
$NOXS = 0;

print $RCSID, "\n" if $DEBUG;

use Jcode::Constants qw(:all);

sub new {
    my $class = shift;
    my ($thingy, $icode) = @_;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;
    convert($r_str, 'euc', $icode);
    my $self = [
	$r_str,
	$icode,
	$nmatch,
    ];
    carp "Object of class $class created" if $DEBUG >= 2;
    bless $self, $class;
}

sub r_str  { $_[0]->[0] }
sub icode  { $_[0]->[1] }
sub nmatch { $_[0]->[2] }

sub set {
    my $self = shift;
    my ($thingy, $icode) = @_;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;
    convert($r_str, 'euc', $icode);
    $self->[0] = $r_str;
    $self->[1] = $icode;
    $self->[2] = $nmatch;
    $self->[3] = "Classic";
    return $self;
}

sub append {
    my $self = shift;
    my ($thingy, $icode) = @_;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;
    convert($r_str, 'euc', $icode);
    ${$self->[0]} .= $$r_str;
    $self->[1] = $icode;
    $self->[2] = $nmatch;
    return $self;
}

sub jcode { return Jcode->new(@_) }
sub euc   { return ${$_[0]->[0]} }
sub jis   { return  &euc_jis(${$_[0]->[0]})}
sub sjis  { return &euc_sjis(${$_[0]->[0]})}
sub iso_2022_jp{return $_[0]->h2z->jis}

sub jfold{
    my $self = shift;
    my ($bpl, $nl) = @_;
    $bpl ||= 72;
    $nl  ||= "\n";
    my $r_str = $self->[0];
    my @lines = (); my $len = 0; my $i = 0;
    while ($$r_str =~
	   m/($RE{EUC_0212}|$RE{EUC_KANA}|$RE{EUC_C}|[\x00-\xff])/sgo)
    {
	if ($len + length($1) > $bpl){ # fold!
	    $i++; 
	    $len = 0;
	}
	$lines[$i] .= $1;
	$len += length($1);
    }
    defined($lines[$i]) or pop @lines;
    $$r_str = join($nl, @lines);
    return wantarray ? @lines : $self;
}

sub jlength {
    my $self = shift;
    my $r_str = $self->[0];
    return scalar (my @char = $$r_str =~ m/($RE{EUC_0212}|$RE{EUC_KANA}|$RE{EUC_C}|[\x00-\xff])/sgo);
}

sub mime_encode{
    my $self = shift;
    my $r_str = $self->[0];
    my $lf  = shift || "\n";
    my $bpl = shift || 76;

    my ($trailing_crlf) = ($$r_str =~ /(\n|\r|\x0d\x0a)$/o);
    my $str  = _mime_unstructured_header($$r_str, $lf, $bpl);
    not $trailing_crlf and $str =~ s/(\n|\r|\x0d\x0a)$//o;
    $str;
}

#
# shamelessly stolen from
# http://www.din.or.jp/~ohzaki/perl.htm#JP_Base64
#

sub _add_encoded_word {
    require MIME::Base64;
    my($str, $line, $bpl) = @_;
    my $result = '';
    while (length($str)) {
	my $target = $str;
	$str = '';
	if (length($line) + 22 +
	    ($target =~ /^(?:$RE{EUC_0212}|$RE{EUC_C})/o) * 8 > $bpl) {
	    $line =~ s/[ \t\n\r]*$/\n/;
	    $result .= $line;
	    $line = ' ';
	}
	while (1) {
	    my $iso_2022_jp = jcode($target, 'euc')->iso_2022_jp;
	    if (my $count = ($iso_2022_jp =~ tr/\x80-\xff//d)){
		$DEBUG and warn $count;
		$target = jcode($iso_2022_jp, 'iso_2022_jp')->euc;
	    }
	    my $encoded = '=?ISO-2022-JP?B?' .
	      MIME::Base64::encode_base64($iso_2022_jp, '')
		  . '?=';
	    if (length($encoded) + length($line) > $bpl) {
		$target =~ 
		    s/($RE{EUC_0212}|$RE{EUC_KANA}|$RE{EUC_C}|$RE{ASCII})$//o;
		$str = $1 . $str;
	    } else {
		$line .= $encoded;
		last;
	    }
	}
    }
    return $result . $line;
}

sub _mime_unstructured_header {
    my ($oldheader, $lf, $bpl) = @_;
    my(@words, @wordstmp, $i);
    my $header = '';
    $oldheader =~ s/\s+$//;
    @wordstmp = split /\s+/, $oldheader;
    for ($i = 0; $i < $#wordstmp; $i++) {
	if ($wordstmp[$i] !~ /^[\x21-\x7E]+$/ and
	    $wordstmp[$i + 1] !~ /^[\x21-\x7E]+$/) {
	    $wordstmp[$i + 1] = "$wordstmp[$i] $wordstmp[$i + 1]";
	} else {
	    push(@words, $wordstmp[$i]);
	}
    }
    push(@words, $wordstmp[-1]);
    for my $word (@words) {
	if ($word =~ /^[\x21-\x7E]+$/) {
	    $header =~ /(?:.*\n)*(.*)/;
	    if (length($1) + length($word) > $bpl) {
		$header .= "$lf $word";
	    } else {
		$header .= $word;
	    }
	} else {
	    $header = _add_encoded_word($word, $header, $bpl);
	}
	$header =~ /(?:.*\n)*(.*)/;
	if (length($1) == $bpl) {
	    $header .= "$lf ";
	} else {
	    $header .= ' ';
	}
    }
    $header =~ s/\n? $/\n/;
    $header;
}

# see http://www.din.or.jp/~ohzaki/perl.htm#JP_Base64
#$lws = '(?:(?:\x0d\x0a)?[ \t])+'; 
#$ew_regex = '=\?ISO-2022-JP\?B\?([A-Za-z0-9+/]+=*)\?='; 
#$str =~ s/($ew_regex)$lws(?=$ew_regex)/$1/gio; 
#$str =~ s/$lws/ /go; $str =~ s/$ew_regex/decode_base64($1)/egio; 

sub mime_decode{
    require MIME::Base64; # not use
    my $self = shift;
    my $r_str = $self->[0];
    my $re_lws = '(?:(?:\r|\n|\x0d\x0a)?[ \t])+';
    my $re_ew = '=\?[Ii][Ss][Oo]-2022-[Jj][Pp]\?[Bb]\?([A-Za-z0-9+/]+=*)\?=';
    $$r_str =~ s/($re_ew)$re_lws(?=$re_ew)/$1/sgo;
    $$r_str =~ s/$re_lws/ /go;
    $self->[2] = 
	($$r_str =~
	 s/$re_ew/jis_euc(MIME::Base64::decode_base64($1))/ego
	 );
    $self;
}

sub tr{
    require Jcode::Tr; # not use
    my $self = shift;
    $self->[2] = Jcode::Tr::tr($self->[0], @_);
    return $self;
}

#
# load needed module depending on the configuration just once!
#

use vars qw(%PKG_LOADED);

sub load_module{
    my $pkg = shift;
    return $pkg if $PKG_LOADED{$pkg}++;
    unless ($NOXS){
	eval qq( require $pkg; );
	unless ($@){
	    carp "$pkg loaded." if $DEBUG;
	    return $pkg;
	}
    }
    $pkg .= "::NoXS";
    eval qq( require $pkg; );
    unless ($@){
	carp "$pkg loaded" if $DEBUG;
    }else{
	croak "Loading $pkg failed!";
    }
    $pkg;
}

sub ucs2{
    load_module("Jcode::Unicode");
    euc_ucs2(${$_[0]->[0]});
}

sub utf8{
    load_module("Jcode::Unicode");
    euc_utf8(${$_[0]->[0]});
}

sub getcode {
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;

    my ($code, $nmatch, $sjis, $euc, $utf8) = ("", 0, 0, 0, 0);
    if ($$r_str =~ /$RE{BIN}/o) {	# 'binary'
	my $ucs2;
	$ucs2 += length($1)
	    while $$r_str =~ /(\x00$RE{ASCII})+/go;
	if ($ucs2){      # smells like raw unicode 
	    ($code, $nmatch) = ('ucs2', $ucs2);
	}else{
	    ($code, $nmatch) = ('binary', 0);
	 }
    }
    elsif ($$r_str !~ /[\e\x80-\xff]/o) {	# not Japanese
	($code, $nmatch) = ('ascii', 1);
    }				# 'jis'
    elsif ($$r_str =~ 
	   m[
	     $RE{JIS_0208}|$RE{JIS_0212}|$RE{JIS_ASC}|$RE{JIS_KANA}
	   ]ox)
    {
	($code, $nmatch) = ('jis', 1);
    } 
    else { # should be euc|sjis|utf8
	# use of (?:) by Hiroki Ohzaki <ohzaki@iod.ricoh.co.jp>
	$sjis += length($1) 
	    while $$r_str =~ /((?:$RE{SJIS_C})+)/go;
	$euc  += length($1) 
	    while $$r_str =~ /((?:$RE{EUC_C}|$RE{EUC_KANA}|$RE{EUC_0212})+)/go;
	$utf8 += length($1) 
	    while $$r_str =~ /((?:$RE{UTF8})+)/go;
	# $utf8 *= 1.5; # M. Takahashi's suggestion
	$nmatch = _max($utf8, $sjis, $euc);
	carp ">DEBUG:sjis = $sjis, euc = $euc, utf8 = $utf8" if $DEBUG >= 3;
	$code = 
	    ($euc > $sjis and $euc > $utf8) ? 'euc' :
		($sjis > $euc and $sjis > $utf8) ? 'sjis' :
		    ($utf8 > $euc and $utf8 > $sjis) ? 'utf8' : undef;
    }
    return wantarray ? ($code, $nmatch) : $code;
}

sub convert{
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    my ($ocode, $icode, $opt) = @_;

    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;

    return $$r_str if $icode eq $ocode and !defined $opt; # do nothin'

    no strict qw(refs);
    my $method;

    # convert to EUC

    load_module("Jcode::Unicode") if $icode =~ /ucs2|utf8/o;
    if ($icode and defined &{$method = "$icode" . "_euc"}){
	carp "Dispatching \&$method" if $DEBUG >= 2;
	&{$method}($r_str) ;
    }

    # h2z or z2h

    if ($opt){
	my $cmd = ($opt =~ /^z/o) ? "h2z" : ($opt =~ /^h/o) ? "z2h" : undef;
	if ($cmd){
	    require Jcode::H2Z;
	    &{'Jcode::H2Z::' . $cmd}($r_str);
	}
    }

    # convert to $ocode

    load_module("Jcode::Unicode") if $ocode =~ /ucs2|utf8/o;
    if ($ocode and defined &{$method =  "euc_" . $ocode}){
	carp "Dispatching \&$method" if $DEBUG >= 2;
	&{$method}($r_str) ;
    }
    $$r_str;
}

sub h2z {
    require Jcode::H2Z; # not use
    my $self = shift;
    $self->[2] = Jcode::H2Z::h2z($self->[0], @_);
    return $self;
}


sub z2h {
    require Jcode::H2Z; # not use
    my $self = shift;
    $self->[2] =  &Jcode::H2Z::z2h($self->[0], @_);
    return $self;
}

# JIS<->EUC

sub jis_euc {
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    $$r_str =~ s(
		 ($RE{JIS_0212}|$RE{JIS_0208}|$RE{JIS_ASC}|$RE{JIS_KANA})
		 ([^\e]*)
		 )
    {
	my ($esc, $str) = ($1, $2);
	if ($esc !~ /$RE{JIS_ASC}/o) {
	    $str =~ tr/\x21-\x7e/\xa1-\xfe/;
	    if ($esc =~ /$RE{JIS_KANA}/o) {
		$str =~ s/([\xa1-\xdf])/\x8e$1/og;
	    }
	    elsif ($esc =~ /$RE{JIS_0212}/o) {
		$str =~ s/([\xa1-\xfe][\xa1-\xfe])/\x8f$1/og;
	    }
	}
	$str;
    }geox;
    $$r_str;
}

#
# euc_jis
#
# Based upon the contribution of
# Kazuto Ichimura <ichimura@shimada.nuee.nagoya-u.ac.jp>
# optimized by <ohzaki@iod.ricoh.co.jp>

sub euc_jis{
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    $$r_str =~ s{
	((?:$RE{EUC_C})+|(?:$RE{EUC_KANA})+|(?:$RE{EUC_0212})+)
	}{
	    my $str = $1;
	    my $esc = 
		( $str =~ tr/\x8E//d ) ? $ESC{KANA} :
		    ( $str =~ tr/\x8F//d ) ? $ESC{JIS_0212} :
			$ESC{JIS_0208};
	    $str =~ tr/\xA1-\xFE/\x21-\x7E/;
	    $esc . $str . $ESC{ASC};
	}geox;
    $$r_str =~
	s/\Q$ESC{ASC}\E
	    (\Q$ESC{KANA}\E|\Q$ESC{JIS_0212}\E|\Q$ESC{JIS_0208}\E)/$1/gox;
    $$r_str;
}

# EUC<->SJIS

my %_S2E = ();
my %_E2S = ();

sub sjis_euc {
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    $$r_str =~ s(
		 ($RE{SJIS_C}|$RE{SJIS_KANA})
	     )
    {
	my $str = $1;
	unless ($_S2E{$1}){
	    my ($c1, $c2) = unpack('CC', $str);
	    if (0xa1 <= $c1 && $c1 <= 0xdf) {
		$c2 = $c1;
		$c1 = 0x8e;
	    } elsif (0x9f <= $c2) {
		$c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe0 : 0x60);
		$c2 += 2;
	    } else {
		$c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe1 : 0x61);
		$c2 += 0x60 + ($c2 < 0x7f);
	    }
	    $_S2E{$str} = pack('CC', $c1, $c2);
	}
	$_S2E{$str};
    }geox;
    $$r_str;
}

#

sub euc_sjis {
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    $$r_str =~ s(
		 ($RE{EUC_C}|$RE{EUC_KANA}|$RE{EUC_0212})
		 )
    {
	my $str = $1;
	unless ($_E2S{$str}){
	    my ($c1, $c2) = unpack('CC', $str);
	    if ($c1 == 0x8e) {          # SS2
		$_E2S{$str} = chr($c2);
	    } elsif ($c1 == 0x8f) {     # SS3
		$_E2S{$str} = $CHARCODE{UNDEF_SJIS};
	    }else { #SS1 or X0208
		if ($c1 % 2) {
		    $c1 = ($c1>>1) + ($c1 < 0xdf ? 0x31 : 0x71);
		    $c2 -= 0x60 + ($c2 < 0xe0);
		} else {
		    $c1 = ($c1>>1) + ($c1 < 0xdf ? 0x30 : 0x70);
		    $c2 -= 2;
		}
		$_E2S{$str} = pack('CC', $c1, $c2);
	    }
	}
	$_E2S{$str};
    }geox;
    $$r_str;
}

#
# Util. Functions
#

sub _max {
    my $result = shift;
    for my $n (@_){
	$result = $n if $n > $result;
    }
    return $result;
}
1;
