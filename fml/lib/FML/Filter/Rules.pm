sub reject_null_mail_body
{
    $buf =~ /^[\s\n]*$/;
}


sub reject_not_iso2022jp_japanese_string
{
    use Language::ISO2022JP;
    not is_iso2022jp_string();
}


sub reject_one_line_message
{

    # e.g. "unsubscribe", "help", ("subscribe" in some case)
    # XXX DO NOT INCLUDE ".", "?" (I think so ...)! 
    # XXX but we need "." for mail address syntax e.g. "chaddr a@d1 b@d2".
    # If we include them, 
    # we cannot identify a command or an English phrase ;D
    if ($fparbuf =~ /^[\s\n]*[\s\w\d:,\@\-]+[\n\s]*$/) {
	$r = "one line mail body";
    }
}


# XXX fml 4.0: fml.pl (distribute) should not accpet commands 
# XXX: "# command" is internal represention
# XXX: but to reject the old compatible syntaxes.
sub reject_command_syntax
{
    if ($mode eq 'distribute' && $FILTER_ATTR_REJECT_COMMAND &&
	$fparbuf =~ /^[\s\n]*(\#\s*[\w\d\:\-\s]+)[\n\s]*$/) {
	$r = $1; $r =~ s/\n//g;
	$r = "avoid to distribute commands [$r]";
    }
}


sub reject_invalid_command_syntax
{

    elsif ($fparbuf =~ /^[\s\n]*\%\s*echo.*/i && 
	   $FILTER_ATTR_REJECT_INVALID_COMMAND) {
	$r = "invalid command in the mail body";
}

# Japanese command
# JIS: 2 byte A-Z => \043[\101-\132]
# JIS: 2 byte a-z => \043[\141-\172]
# EUC 2-bytes "A-Z" (243[301-332])+
# EUC 2-bytes "a-z" (243[341-372])+
# e.g. reject "SUBSCRIBE" : octal code follows:
# 243 323 243 325 243 302 243 323 243 303 243 322 243 311 243 302
# 243 305
sub reject_japanese_command_syntax
{
    elsif ($FILTER_ATTR_REJECT_2BYTES_COMMAND && 
	   $fparbuf =~ /\033\044\102(\043[\101-\132\141-\172])/) {
	# /JIS"2byte"[A-Za-z]+/
	
	$s = &STR2EUC($fparbuf);

	my ($n_pat, $sp_pat);
	$n_pat  = '\243[\301-\332\341-\372]';
	$sp_pat = '\241\241'; # 2-byte space

	$s = (split(/\n/, $s))[0]; # check the first line only
	if ($s =~ /^\s*(($n_pat){2,})\s+.*$|^\s*(($n_pat){2,})($sp_pat)+.*$|^\s*(($n_pat){2,})$/) {
	    &Log("2 byte <". &STR2JIS($s) . ">");
	    $r = '2 byte command';
	}
    }
}


sub reject_invalid_message_id
{


}



# [VIRUS CHECK against a class of M$ products]
# Even if Multipart, evaluate all blocks agasint virus checks.
sub reject_virus_message
{

	&use('viruschk');
	my ($xr);
	$xr = &VirusCheck(*e);

}


1;
