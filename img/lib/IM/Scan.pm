# -*-Perl-*-
################################################################
###
###			       Scan.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Mar 22, 2003
###

my $PM_VERSION = "IM::Scan.pm version 20030322(IM144)";

package IM::Scan;
require 5.003;
require Exporter;

use IM::Config qw(allowcrlf scansbr_file scan_header_pick mail_path address
		  addresses_regex addrbook_file petname_file);
use IM::Util;
use IM::EncDec qw(mime_decode_string);
use IM::Address qw(extract_addr fetch_addr);
use IM::Japanese;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(set_scan_form get_header store_header parse_body parse_header
	     disp_msg read_petnames);

use vars qw($WIDTH $JIS_SAFE $HEADLINELIMIT $BODYLINELIMIT
	    $MSTR2NUM @MSTR @WSTR %symbol_table
	    %multipart_mark @NEEDSAFE %NEEDSAFE_HASH
	    @STRUCTURED %STRUCTURED_HASH
	    @HANDLE
	    %REF_SYMBOL %message_id %message_id_and_subject
	    %petnames %ADDRESS_HASH
	    $SI $SO $SS2 $SS3
	    $ALLOW_CRLF);

############################################
##
## Environments
##

BEGIN {
    $WIDTH = 80;
    $JIS_SAFE = 0;

    $HEADLINELIMIT = 100;
    $BODYLINELIMIT = 30;

    $MSTR2NUM = {
	Jan => "01", Feb => "02", Mar => "03", Apr => "04",
	May => "05", Jun => "06", Jul => "07", Aug => "08",
	Sep => "09", Oct => "10", Nov => "11", Dec => "12",
    };

    @MSTR = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
	     'Sep', 'Oct', 'Nov', 'Dec');

    @WSTR = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

    # used in 'set_scan_form' to convert scan_form() to $EVAL_SCAN_FORM
    %symbol_table = (
		     'n' => 'number:',
		     'd' => 'date:',
		     'f' => 'from:',
		     't' => 'to:',
		     'g' => 'newsgroups',
		     'a' => 'address:',
		     'P' => 'pureaddr:',
		     'A' => 'Address:',
		     's' => 'subject:',
		     'i' => 'indent:',
		     'b' => 'body:',
		     'm' => 'multipart:',
		     'S' => 'indent-subject:',
		     'F' => 'folder:',
		     'M' => 'mark:',
		     'p' => 'private:',
		     'D' => 'duplicate:',
#		     'B' => 'bytes:',
		     'K' => 'kbytes:',

		     'y' => 'year:',
		     'c' => 'month:',
		     'C' => 'monthstr:',
		     'e' => 'mday:',
		     'h' => 'hour:',
		     'E' => 'min:',
		     'G' => 'sec:',
		     );

    %multipart_mark = (
		       'enc' => 'E',
		       'sig' => 'S',
		       );

    @NEEDSAFE = qw(from: to: cc: address: Address:
		   subject: indent-subject: body:);

    %NEEDSAFE_HASH = ();

    foreach (@NEEDSAFE) {
	$NEEDSAFE_HASH{$_} = 1;
    }
}

############################################
##
## If user specifies a scan format, convert that to 'eval-form'.
##

sub set_scan_form($$$) {
    my($scan_form, $width, $jis_safe) = @_;

    $ALLOW_CRLF = allowcrlf();

    $WIDTH = $width;
    $JIS_SAFE= $jis_safe;

    my $scan_hook = scansbr_file();
    if ($scan_hook =~ /^(\S+)$/) {
	if ($main::INSECURE) {
	    im_warn("Sorry, ScanSbr is ignored for SUID root script.\n");
	} else {
	    $scan_hook = $1;	# to pass through taint check
	    if (-f $scan_hook) {
		require $scan_hook;
	    } else {
		im_err("scan subroutine file $scan_hook not found.\n");
	    }
	}
    }

    convert_scan_form($scan_form);
}

############################################
##
##   get_header
##

sub get_header($) {
    my $path = shift;
    my %Head = ();
    my $folder;

    $Head{'path'} = $path;
    if ($path =~ /(.*)\/([0-9]+)$/) {
	# xxx how about news?
	$Head{'number:'} = $2;
	$folder = substr($1, length(mail_path()) + 1);
	$folder = conv_iso2022jp($folder) if ($folder =~ /[\200-\377]/);
	$Head{'folder:'} = '+' . $folder;
    }

    im_open(\*MSG, "<$path") || return;

    ##
    ## Collect file attributes
    ##
#    $Head{'bytes:'} = -s MSG;
    $Head{'kbytes:'} = int(((-s MSG) + 1023) / 1024);

    ##
    ## Header parse
    ##
    my $header;
    if ($ALLOW_CRLF) {
	$header = <MSG>;
	if ($header =~ /\r/) {
	    $/ = "\r\n\r\n";
	} else {
	    $/ = "\n\n";
	}
	$header .= <MSG>;
	$header =~ s/\r//g;
    } else {
	$/ = "\n\n";
	$header = <MSG>;
    }
    store_header(\%Head, $header);

    ##
    ## Body parse
    ##
    $/ = "\n";
    $Head{'body:'} = parse_body(*MSG, 0);

    close(MSG);

    parse_header(\%Head);

    return(%Head);
}

@STRUCTURED = qw (
	sender from reply-to return-path
	resent-sender resent-from resent-reply-to
	errors-to return-receipt-to
	to cc bcc dcc apparently-to
	resent-to resent-cc resent-bcc
);

%STRUCTURED_HASH = ();

foreach (@STRUCTURED) {
    $STRUCTURED_HASH{$_} = 1;
}

sub store_header($$) {
    my($href, $header) = @_;
    local $_;
    my $lines = 0;

    chomp($header);
    $header =~ s/\n[ \t]+/ /g;
    foreach (split("\n", $header)) {
	chomp;
	last if (++$lines > $HEADLINELIMIT);
	next unless (/^([^:]*):\s*(.*)$/);
	my $label = lc($1);
	next if ($label eq 'received');
	if (defined($href->{$label})) {
	    if ($STRUCTURED_HASH{$label}) {
		$href->{$label} .= ", ";
	    } else {
		$href->{$label} .= "\n\t";
	    }
	    $href->{$label} .= $2;
	} else {
	    $href->{$label} = $2;
	}
    }
}

##### BODY parse #####
#
# parse_body(HANDLER, mode)
#        HANDER: Filer Hander or Array
#        mode: 1 if HANDLER is File Handler, otherwise HANDLER is Array
#        return value: substring from body
#
sub parse_body(*$) {
    local *HANDLE = shift;
    my $mode = shift;
    my($content, $lines) = ('', 0);

    while (1) {
	if ($mode == 0) {
	    $_ = <HANDLE>;
	} else {
	    $_ = shift(@HANDLE);
	}
	last unless defined($_);

	next if /^\s*\n/;
	next if /^--/;
	next if /^- --/;
	next if /^=2D/;
	next if /^\s+[\w*-]+=/;		# eg. "boundary="; * = RFC2231
	next if /^\s*[\w-]+: /;		# Headers and header style citation
	next if /^\s*[>:|\/_}]/;	# other citation
	next if /^  /;
	next if /^\s*\w+([\'._-]+\w+)*>/;
	next if /^\s*(On|At) .*[^.!\s\n]\s*$/;
        next if /(:|;|\/)\s*\n$/;
        next if /(wrote|writes?|said|says?)[^.!\n]?\s*\n$/;
	next if /^This is a multi-part message in MIME format/i;

	if (/^\s*In (message|article|<|\")/i) {
	    if ($mode == 0) {
		$_ = <HANDLE>;
	    } else {
		$_ = shift(@HANDLE);
	    }
	    last unless defined($_);
	    next;
	}

	chomp;
	s/^\s+//g;
	s/\s+/ /g;
	if ($content eq '') {
	    $content = $_;
	} else {
	    $content .= ' ';
	    $content .= $_;
	}

	last if (length($content) > $WIDTH);
	$lines++;
	last if ($lines > $BODYLINELIMIT);
    }

    return substr_safe($content, $WIDTH);
}

sub parse_header($) {
    my $href = shift;
    
    ##
    ## Thread related
    ##
    if (($href->{'in-reply-to'})
	&& ($href->{'in-reply-to'} =~ /.*(<[^<]*>)\s*/))  {
	$href->{'references:'} = $1;
    } elsif ($href->{'references'}) {
	if ($href->{'references'} =~ /.*(<[^<]*>)/) {
	    $href->{'references:'} = $1;
	} else {
	    $href->{'references:'} = $href->{'references'};
	}
    }

    ##
    ## Date
    ##
    my $tz;
    if ($href->{'date'}) {
	$href->{'date:'} = $href->{'date'};
    } else {
	my($sec, $min, $hour, $mday, $mon, $year,
	   $wday, $yday, $isdst) = localtime((stat($href->{'path'}))[9]);
	my($gsec, $gmin, $ghour, $gmday, $gmon, $gyear,
	   $gwday, $gyday, $gisdst) = gmtime((stat($href->{'path'}))[9]);

	my $off = ($hour - $ghour) * 60 + $min - $gmin;
	if ($year < $gyear) {
	    $off -= 24 * 60;
	} elsif ($year > $gyear) {
	    $off += 24 * 60;
	} elsif ($yday < $gyday) {
	    $off -= 24 * 60;
	} elsif ($yday > $gyday) {
	    $off += 24 * 60;
	}
	if ($off == 0) {
	    $tz = "GMT";
	} elsif ($off > 0) {
	    $tz = sprintf("+%02d%02d", $off/60, $off%60);
	} else {
	    $off = -$off;
	    $tz = sprintf("-%02d%02d", $off/60, $off%60);
	}

	$href->{'date:'} = sprintf "%s, %d %s %d %02d:%02d:%02d %s",
			$WSTR[$wday], $mday, $MSTR[$mon], $year + 1900,
			$hour, $min, $sec, $tz;
    }

    $href->{'date:'} =~ /(\d\d?)\s+([A-Za-z]+)\s+(\d+)\s/;
    my($mday, $monthstr, $year) = ($1, "\u\L$2", $3);
    my $mon = $MSTR2NUM->{$monthstr};

    $href->{'date:'} =~ /\s(\d\d?):(\d\d?)/;
    my($hour, $min, $sec) = ($1, $2, 0);
    if ($href->{'date:'} =~ /\s\d\d?:\d\d?:(\d\d?)\s/) {
	$sec = $1;
    }

    if ($year < 50) {
	$year += 2000;
    } elsif ($year < 1000) {
	$year += 1900;
    }
    $href->{'year:'} = $year;
    $href->{'month:'} = $mon;
    $href->{'monthstr:'} = $monthstr;
    $href->{'mday:'} = $mday;
    $href->{'hour:'} = $hour;
    $href->{'min:'} = $min;
    $href->{'sec:'} = $sec;
    $href->{'date:'} = sprintf "%02d/%02d", $href->{'month:'}, $href->{'mday:'};

    ##
    ## MIME decoding
    ##
    $href->{'subject:'} = &mime_decode_string($href->{'subject'});
    $href->{'from:'} = &mime_decode_string($href->{'from'})
	if $REF_SYMBOL{'from:'};
    $href->{'to:'} = &mime_decode_string($href->{'to'})
	if $REF_SYMBOL{'to:'};
    $href->{'cc:'} = &mime_decode_string($href->{'cc'})
	if $REF_SYMBOL{'cc:'};

    ##
    ## Mark
    ##
    $href->{'multipart:'} = ' ';
    if (defined($href->{'mime-version'}) &&
	defined($href->{'content-type'})) {
	if ($href->{'content-type'} =~ /Multipart\/(...)/i) {
	    $href->{'multipart:'} = $multipart_mark{lc($1)} || 'M';
	} elsif ($href->{'content-type'} =~ /Message\/Partial/i) {
	    $href->{'multipart:'} = 'P';
	}
    }

    ##
    ## Address related
    ##
    if ($REF_SYMBOL{'address:'}) {
	$href->{'address:'} = friendly_addr($href->{'from'}, 0)
	    unless ($href->{'address:'});
    }
    if ($REF_SYMBOL{'Address:'}) {
	if (my_addr($href->{'from'})) {
	    if ($href->{'to'}) {
	        my $to = &friendly_addr($href->{'to'}, 0);
		if ($to) {
		    $href->{'Address:'} = 'To:' . $to;
		}
	    } elsif ($href->{'newsgroups'}) {
		$href->{'Address:'} = 'Ng:' .  $href->{'newsgroups'};
	    }
	}
	$href->{'Address:'} = friendly_addr($href->{'from'}, 0)
	      unless ($href->{'Address:'});
    }
    if ($REF_SYMBOL{'pureaddr:'}) {
	if (my_addr($href->{'from'})) {
	    if ($href->{'to'}) {
		my($to, $rest) = &fetch_addr($href->{'to'}, 1);
		if ($to) {
		    $href->{'pureaddr:'} = 'To:' . $to;
		}
	    } elsif ($href->{'newsgroups'}) {
		$href->{'pureaddr:'} = 'Ng:' .  $href->{'newsgroups'};
	    }
	}
	$href->{'pureaddr:'} = &extract_addr($href->{'from'})
	    unless ($href->{'pureaddr:'});
    }
    if (($REF_SYMBOL{'mark:'} || $REF_SYMBOL{'private:'}) 
	&& my_addr($href->{'to'}, $href->{'cc'}, $href->{'apparently-to'})) {
	$href->{'mark:'} = $href->{'private:'} = '*';
    } else {
	$href->{'mark:'} = $href->{'private:'} = ' ';
    }

    if ($::opt_dupchecktarget eq "" or $::opt_dupchecktarget eq "message-id") {
	if ($href->{'multipart:'} ne 'P'
	    && $href->{'message-id'} && $message_id{$href->{'message-id'}}++) {
	    $href->{'mark:'} = $href->{'duplicate:'} = 'D';
	} else {
	    $href->{'duplicate:'} = ' ';
	}
    }
    elsif ($::opt_dupchecktarget eq "message-id+subject") {
	my $t = join(";", $href->{'message-id'}, $href->{'subject'});
	if ($t ne ";" and $message_id_and_subject{$t}++) {
	    $href->{'mark:'} = $href->{'duplicate:'} = 'D';
	}
	else {
	    $href->{'duplicate:'} = ' ';
	}
    }

    ##
    ## Call user defined function
    ##
    &scan_sub($href) if (defined(&scan_sub));
}

sub disp_msg($;$) {
    my($href, $vscan) = @_;

    $href->{'indent:'} = '' unless defined($href->{'indent:'});
    $href->{'subject:'} = '' unless defined($href->{'subject:'});
    $href->{'indent-subject:'} = $href->{'indent:'} . $href->{'subject:'};

    binmode(STDOUT);

    if (defined &my_get_msg) {
	print &my_get_msg($href), "\n";
	flush('STDOUT') unless $main::opt_buffer;
	return;
    } elsif (defined(&scan_form)) {
	my $content = &scan_form($href);
	$content =~ s/\t/ /g;
	if ($vscan) {
	    print &substr_safe($content, $WIDTH - 1),
	    "\r $href->{'folder:'} $href->{'pnum'}\n";
	} else {
	    print &substr_safe($content, $WIDTH - 1), "\n";
	}
	flush('STDOUT') unless $main::opt_buffer;
	return;
    } else {
	im_err("no scan_form specified.\n");
    }
}

############################################
##
## Convert into Friendly Address
##

sub friendly_addr($$) {
    my($addr, $need_addr) = @_;
    return '' unless $addr;
    my $friendly = '';
    my($a, $f, $p);
    while (($a, $addr, $f) = &fetch_addr($addr, 1), $a ne '') {
	$a =~ s/\/[^@]*//;
	if (defined(%petnames) && $petnames{lc($a)}) {
	    $p = $petnames{lc($a)};
	} elsif (!$need_addr && $f) {
	    $p = &mime_decode_string($f);
	} else {
	    $p = $a;
	}
	if ($friendly eq '') {
	    $friendly = $p;
	} else {
	    $friendly .= ', ' . $p;
	}
    }
    return $friendly;
}

############################################
##
## Read petnames entry
##

%ADDRESS_HASH = ();

sub my_addr(@) {
    my @addrs = @_;
    my $addr;

    unless (defined($ADDRESS_HASH{'init'})) {
	$ADDRESS_HASH{'addr'} = addresses_regex();
	unless ($ADDRESS_HASH{'addr'}) {
	    $ADDRESS_HASH{'addr'} = '^' . quotemeta(address()) . '$';  #'
            $ADDRESS_HASH{'addr'} =~ s/(\\\s)*\\,(\\\s)*/\$|\^/g;
	}
	    $ADDRESS_HASH{'init'} = 1;
    }
    return 0 if ($ADDRESS_HASH{'addr'} eq "");
    foreach $addr (@addrs) {
	my $a;
	while (($a, $addr) = fetch_addr($addr, 1), $a ne "") {
	    return 1 if ($a =~ /$ADDRESS_HASH{'addr'}/io);
	}
    }
    return 0;
}

############################################
##
## Convert scan_form() to 'eval-form'
##

sub convert_scan_form($) {
    my $SCANFORM = shift;

    if (!$main::INSECURE && $SCANFORM && $SCANFORM !~ /%/) {
	do $SCANFORM; # -- require $SCAN_FORM; (sub scan_form)
	return if defined(&scan_form);
    }

    my @symbols = ();
    my($format, $jis_safe, $plus, $hyphen, $size, $type, $arg);

    if (scan_header_pick()) {
	my $elem;
	foreach $elem (split /,/, scan_header_pick()) {
	    if ($elem =~ /^([a-zA-Z]+):(.*)$/) {
		$symbol_table{$1} = "$2";
	    }
	}
    }

    while ($SCANFORM ne '') {
	if ($SCANFORM =~ /^%(!?)(\+?)(-?)(\d*)([a-zA-Z]|{\w+})(.*)/) {
	    $plus = $2;
	    $hyphen = $3;
	    $size = $4;
	    $type = $5;
	    $SCANFORM = $6;

	    $type =~ s/{(.*)}/$1/;
	    if ($type eq 'n') {
		if ($SCANFORM =~ /^ / ||
		    $SCANFORM =~ /^%D/ || $SCANFORM =~ /^%p/ ||
		    $SCANFORM =~ /^%M/) {
		    # OK
		} else {
		im_err("Characters in Scan form after %n should be a space or %D or %p or %M\n");
	        }
	    }

	    $jis_safe = ($size ne '' && $size > 0
			 && ($1 ne '' || $NEEDSAFE_HASH{$symbol_table{$type}}))
		? $JIS_SAFE : 0;

	    $arg = '$href->{\'' . $symbol_table{$type} . '\'}';
	    $arg = "&substr_safe(sprintf('%${hyphen}${size}s', $arg), $size)"
		if ($jis_safe && !$plus);

	    push(@symbols, $arg);
	    $REF_SYMBOL{$symbol_table{$type}} = 1;

	    if ($size =~ /^0/) { # numerical context
		$format .= "%${hyphen}${size}d";
	    } else {
		if ($jis_safe || $plus || $size eq '') {
		    $format .= "%${hyphen}${size}s";
		} else {
		    $format .= "%${hyphen}${size}.${size}s";
		}
	    }
	} elsif ($SCANFORM =~ /^([^%]+)(.*)/) {
	    $format .= $1;
	    $SCANFORM = $2;
	    next;
	} else {
	    im_warn("invalid scan format: $SCANFORM\n");
	    return;
	}
    }

    $arg  = join(',', @symbols);
    my $EVAL_SCAN_FORM = "sprintf('$format', $arg)";
    eval "sub scan_form { my(\$href) = shift; $EVAL_SCAN_FORM }";
    if ($@) {
	im_die("Form seems to be wrong.\nPerl error message is: $@");
    }
}

############################################
##
## Substring in Safe Manner
## fill up spaces to specified '$len' when length doesn't reach that.
##

BEGIN {
     $SI = "\x0f";		# Shift In Sequence
     $SO = "\x0e";		# Shift Out Sequence
     # for ISO-2022-CN
     $SS2 = "\x1b\x4e";		# <ISO 2022 Single_shift two>
     $SS3 = "\x1b\x4f";		# <ISO 2022 Single_shift three>
}

sub substr_safe($$) {
    ($_, my $len) = @_;

    # This hack makes the code a few percent faster but it's kinda ugly.
    # Do you want leave it?
    if (1) {
	unless (/[^\s!-~]/) {
	    return pack("A$len", $_);
	}
    }

    my $i = 0;			# Current Index of this string
    my $count = 0;		# Readable Characters
    my $charset = 'ascii';	# Current Character Set
    my @res = ();		# Output Result
    my $fill_char = ' ';	# Fill Spaces up to specified length
    my $last_char = '';		# Extra Characters in double-byte-segment
    my $shift_in = '';		# Return code to shift in
    my $G0 = 'ascii';		# Buffer G0
    my $G1 = '';		# Buffer G1
    my $G2 = '';		# Buffer G2
    my $G3 = '';		# Buffer G3

    while (length($_) && $count < $len) {

	   if (s/(^$SI)//o)	{ $charset = $G0; }
	elsif (s/(^$SO)//o)	{ $charset = $G1; $shift_in = $SI; }
	elsif (s/(^$SS2)//o)	{ $charset = $G2; $shift_in = $SI; }
	# This is verbose if SS3 appears only in ISO-2022-CN-EXT
	elsif (s/(^$SS3)//o)	{ $charset = $G3; $shift_in = $SI; }

	elsif (m/(^[^\e$SI$SO]+)/o) {
	    my $room = $len - $count;
	    my $matched_len = length($1);
	    my $avail;

	    # XXX: Should be parameterized.
	    if ($charset =~ /(^cns11643-plane-2)/) {
		$avail = int(length($1) / 3) * 2;
	    } else {
		$avail = length($1);
	    }

	    if ($avail >= $room) {
		my $i;

		if ($room % 2 and $charset =~
		    /^(jisx0208|jisx0212|jisx0213|ksc5601|cns11643-plane-2|big5-1|big5-2)/) {
		    $room--;
		    $last_char = ' ';
		}
		if ($charset =~ /^cns11643-plane-2/) {
		    $i = $room * 3 / 2;
		} else {
		    $i = $room;
		}
		$count = $len;
		push(@res, substr($_, 0, $i));
		last;
	    }
	    $count += $avail;
	    push(@res, substr($_, 0, $matched_len));
	    substr($_, 0, $matched_len) = '';
	    next;
	}

	# for Japanese Character in rfc1554
	elsif (s/(^\e\(B)//)	{ $G0 = $charset = 'ascii'; }
	elsif (s/(^\e\$\@)//)	{ $G0 = $charset = 'jisx0208-1978'; }
	elsif (s/(^\e\$\(?B)//)	{ $G0 = $charset = 'jisx0208-1983'; }
	elsif (s/(^\e\(J)//)	{ $G0 = $charset = 'jisx0201-roman'; }
	elsif (s/(^\e\$\(?A)//)	{ $G0 = $charset = 'gb2312-1980'; }
	elsif (s/(^\e\$\(D)//)	{ $G0 = $charset = 'jisx0212-1990'; }
	elsif (s/(^\e\$\(C)//)	{ $G1 = $charset = 'ksc5601-1987';
				  $G0 = 'ascii'; }

	elsif (s/(^\e\$\(O)//)	{ $G0 = $charset = 'jisx0213-1'; }
	elsif (s/(^\e\$\(P)//)	{ $G0 = $charset = 'jisx0213-2'; }

	elsif (s/(^\e-A)//)	{ $G1 = $charset = 'iso8859-1'; }
	elsif (s/(^\e-B)//)	{ $G1 = $charset = 'iso8859-2'; }
	elsif (s/(^\e-C)//)	{ $G1 = $charset = 'iso8859-3'; }
	elsif (s/(^\e-D)//)	{ $G1 = $charset = 'iso8859-4'; }
	elsif (s/(^\e-L)//)	{ $G1 = $charset = 'iso8859-5'; }
	elsif (s/(^\e-G)//)	{ $G1 = $charset = 'iso8859-6'; }
	elsif (s/(^\e-F)//)	{ $G1 = $charset = 'iso8859-7'; }
	elsif (s/(^\e-H)//)	{ $G1 = $charset = 'iso8859-8'; }
	elsif (s/(^\e-M)//)	{ $G1 = $charset = 'iso8859-9'; }
	   
	elsif (s/(^\e\.A)//)	{ $G2 = $charset = 'iso8859-1'; }
	elsif (s/(^\e\.F)//)	{ $G2 = $charset = 'iso8859-7'; }

	# for Korean Character in rfc1557
	elsif (s/(^\e\$\)C)//)	{ $G1 = $charset = 'ksc5601';
				  $G0 = 'ascii'; }

	# for Chinese Character in rfc1922
	elsif (s/(^\e\$\)A)//)	{ $G1 = $charset = 'gb2312';
				  $G0 = 'ascii'; }
	elsif (s/(^\e\$\)G)//)	{ $G1 = $charset = 'cns11643-plane-1';
				  $G0 = 'ascii'; }
	elsif (s/(^\e\$\*H)//)	{ $G2 = $charset = 'cns11643-plane-2';
				  $G0 = 'ascii';}

	elsif (s/(^\e\$\(0)//)	{ $G0 = $charset = 'big5-1';}
	elsif (s/(^\e\$\(1)//)	{ $G0 = $charset = 'big5-2';}

	elsif (s/(^\e)//) {
	    ;
	}
	else {
	    die "panic";
	}
	push(@res, $1);
    }

    join ('',
	@res,
	($G0 ne 'ascii') ? "\e(B" : '',
	$shift_in,
	$last_char,
	$fill_char x ($len - $count),
    );
}

############################################
##
## Read petnames entry
##

sub w2n($) {
    my $line = shift;
    $line =~ tr/\x20/\x0/;

    return $line;
}

sub read_petnames() {
    if (addrbook_file() && open(ADDRBOOK, addrbook_file())) {
	my $key; my $addr; my $petname; my $a; my @addrs;
	my $code;

	while (<ADDRBOOK>) {
	    my $line = '';
	    do {
		chomp;
		next if (/^[\#;]/);
		$code = code_check($_, 0);
		if ($code eq 'sjis') {
		    $_ = conv_euc_from_sjis($_);
		} elsif ($code eq 'jis') {
		    $_ = conv_euc_from_jis($_);
		}
		s/#.*$//g;
		$line =~ s/\\$//;
		$line .= $_;
	    } while (/[,\\]$/ && defined($_ = <ADDRBOOK>));
	    $_ = $line;
	    s/"([^"]+)"/w2n($1)/geo;  #"
	    s/,\s+/,/g;
	    if (s/^(\S+)\s+(\S+)\s+(\S+)//) {
		$key = $1;
		$addr = $2;
		$petname = $3;
		next if ($key =~ /:$/);
	        next if $petname eq '*';
	    } else {
		next;
	    }
	    $petname =~ tr/\x0/\x20/;
            $petname = conv_iso2022jp($petname, 'EUC');

	    @addrs = split(/,\s*/, $addr);
	    while ($addr = shift(@addrs)) {
	        $petnames{lc($addr)} = $petname;
	    }
	}
	close(ADDRBOOK);
	return;
    }
    my $file = petname_file();
    return unless $file;
    unless (open(PETNAMES, $file)) { ## don't use im_open().
	im_warn("can't open petname file $file\n");
	return;
    } 
    while (<PETNAMES>) {
	next if (/^$/);
	next if (/^#/);
	chomp;
	my($name, $petname);
	if (/(\S+)\s+(.*)/) {
	    $name = $1;
	    $petname = $2;
	}
	$petname =~ s/^"(.*)"$/$1/;
	$petnames{lc($name)} = $petname;
    }
    close(PETNAMES);
}

1;

__END__

=head1 NAME

IM::Scan - scan listing from mail/news message

=head1 SYNOPSIS

 use IM::Scan;

 &set_scan_form($scan_form, $width, $use_jis);
 &read_petnames();
 %Head = &get_header($mail_file);
 &disp_msg(\%Head);

=head1 DESCRIPTION

The I<IM::Scan> module handles scan format and petnames format
for mail/news message.

This modules is provided by IM (Internet Message).

=head1 FILES

 $HOME/.im/Config	the user profile

=head1 PROFILE COMPONENTS

 Component     Explanation                     Example

 MailDir:      your mail directory             Mail
 Width:        one line width                  80
 JisSafe:      safely substr for ISO-2022-JP   on
 Form:         scan format                     %+5n %m%d %8f %-30S %b
 PetnameFile:  nickname file			~/.im/Petname
 Address:      your mail addresses             kazu@mew.org, kazu@wide.ad.jp
 AddrRegex:    regexp of your addresses        ^kazu@.*$
               if necessary

=head1 SCAN FORMAT

'%{width}{header-type}' format is available. You can define any
header-type as you want. Default valid header-types are

    %n    message number
    %d    raw Date: field
    %f    MIME decoded From: field
    %t    MIME decoded To: filed
    %g    raw Newsgroups: field
    %a    friendly From: field
    %A    If this message is originated by yourself, friendly To: 
          or raw Newsgroups: is displayed in 'To:xxx' or 'Ng:xxx' 
          format, respectively. Otherwise, friendly From: field is 
          displayed.
    %P    Similar to %A, but diplay raw address of mail sender
          instead of friendly From: field, just like mh-e.            
    %i    indent to display thread
    %s    MIME decoded Subject: field
    %S    indented MIME decoded Subject (same as %i+%s)
    %b    a part of body extracted with heuristic
    %m    Multipart type
              'S'igned, 'E'ncrypt, 'M'ultipart, 'P'artial or none
    %p    mark '*' if the message is destined to you
    %D    mark 'D' if the message is duplicated
    %M    %p+%D
    %F    folder path
    %K    file block size (1024 bytes/block)

    %y    year
    %c    month (digit)
    %C    month (string)
    %e    mday
    %h    hour
    %E    min
    %G    sec

{width} is a integer with/without '-' sign. if a '-' sign exists, content
of a header-type will be displaied with left adjustment. If the integer
have leading '0', the field will be padded with leading '0's.

To improve processing speed, needless process on JIS character should be
avoided. Even if 'JisSafe' is on, only %f, %t, %A, %s, %S and %b are
processed with 'substr' routine for JIS characters by default. If you want
to process other header-types with JIS version of 'substr', specify '!'
just after '%' like: %!-8S.

ScanForm "%+5n %m%d %-14A %-18S %b" works as same as IM default scaning.

=head1 PETNAMES FORMAT

Following format is valid in petnames file.
A line beginning with '#' is ignored.

    # This is comments
    Kazu@Mew.org      "Mr.Kazu"
    nom@Mew.org       "Nomsun"

=head1 COPYRIGHT

IM (Internet Message) is copyrighted by IM developing team.
You can redistribute it and/or modify it under the modified BSD
license.  See the copyright file for more details.

=cut

### Copyright (C) 1997, 1998, 1999 IM developing team
### All rights reserved.
### 
### Redistribution and use in source and binary forms, with or without
### modification, are permitted provided that the following conditions
### are met:
### 
### 1. Redistributions of source code must retain the above copyright
###    notice, this list of conditions and the following disclaimer.
### 2. Redistributions in binary form must reproduce the above copyright
###    notice, this list of conditions and the following disclaimer in the
###    documentation and/or other materials provided with the distribution.
### 3. Neither the name of the team nor the names of its contributors
###    may be used to endorse or promote products derived from this software
###    without specific prior written permission.
### 
### THIS SOFTWARE IS PROVIDED BY THE TEAM AND CONTRIBUTORS ``AS IS'' AND
### ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
### IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
### PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE TEAM OR CONTRIBUTORS BE
### LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
### CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
### SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
### BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
### WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
### OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
### IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
