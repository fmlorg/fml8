#!/usr/bin/env perl
#
# $FML: convert.pl,v 1.1 2004/03/14 13:29:25 fukachan Exp $
#

use strict;
use Carp;
use vars qw($count %stab);

load_default();

for my $f (@ARGV) {
    print "# $f\n";
    my $s = gen_eval_string($f);
    eval $s;
    print "error: $@\n" if $@;

    print "\n\n";
}

exit 0;


sub load_default
{
    package default;
    no strict;
    $DIR             = '$DIR';
    $DOMAINNAME      = '$ml_domain';
    $MAIL_LIST       = '$ml_name@$ml_domain';
    $CONTROL_ADDRESS = '$ml_name-ctl@$ml_domain';
    $MAINTAINER      = '$ml_name-admin@$ml_domain';
    $BRACKET         = '$ml_name';
    $ML_FN           = '($ml_name ML)';

    require "/usr/local/fml/default_config.ph";

    $DIR             = '$DIR';
    $DOMAINNAME      = '$ml_domain';
    $MAIL_LIST       = '$ml_name@$ml_domain';
    $CONTROL_ADDRESS = '$ml_name-ctl@$ml_domain';
    $MAINTAINER      = '$ml_name-admin@$ml_domain';
    $BRACKET         = '$ml_name';
    $ML_FN           = '($ml_name ML)';
    $GOOD_BYE_PHRASE = '--$ml_name@$ml_domain, Be Seeing You!';
    $XMLNAME         = 'X-ML-Name: $ml_name';

    $WELCOME_STATEMENT =~ s/our /our \(\$ml_name ML\)/;

    package main;
}


sub gen_eval_string
{
    my ($f) = @_;
    my $s = '';

    $count++;

    $s  = "no strict;\n";
    $s .= sprintf("package config%03d;\n", $count);
    $s .= sprintf("\$DIR = \'\$DIR\';\n");
    $s .= sprintf("\$s = &main::gen_dummy_macros();\n");
    $s .= sprintf("eval \$s;\n");
    $s .= sprintf("print STDERR \$\@ if \$\@;\n");
    $s .= sprintf("require \"%s\";\n", $f);
    $s .= sprintf("package main;\n");
    $s .= sprintf("*stab = *{\"config%03d::\"};\n", $count);
    $s .= "use strict;\n";
    $s .= sprintf("var_dump('config%03d', \\%%stab);\n", $count);

    return $s;
}

sub var_dump
{
    my ($package, $stab) = @_;
    my ($key, $val, $def, $x);

    # resolv
    eval "\$x = \$${package}::MAIL_LIST;\n";
    my ($ml_name, $ml_domain) = split(/\@/, $x);

    while (($key, $val) = each(%$stab)) {
	next if $key =~
	    /^(STRUCT_SOCKADDR|CFVersion|CPU_TYPE_MANUFACTURER_OS|HTML_THREAD_REF_TYPE|FQDN|REJECT_ADDR|SKIP_FIELDS)/;

	eval "\$val = \$${package}::$key;\n";
	eval "\$def = \$default::$key;\n";
	$val =~ s/$ml_name/\$ml_name/g;
	$val =~ s/$ml_domain/\$ml_domain/g;
	print "$key => $val\n" if $val && ($val ne $def);
    }
}


sub gen_old_dummy_macros
{
    my $s = '';

    $s .= "sub GET_HEADER_FIELD_VALUE { 1;}";
    $s .= "sub GET_ORIGINAL_HEADER_FIELD_VALUE { 1;}";
    $s .= "sub SET_HEADER_FIELD_VALUE { 1;}";
    $s .= "sub GET_ENVELOPE_VALUE { 1;}";
    $s .= "sub SET_ENVELOPE_VALUE { 1;}";
    $s .= "sub ENVELOPE_APPEND { 1;}";
    $s .= "sub ENVELOPE_PREPEND { 1;}";
    $s .= "sub GET_BUFFER_FROM_FILE { 1;}";

    $s .= "sub STR2JIS {1;}";
    $s .= "sub STR2EUC {1;}";
    $s .= "sub JSTR    {1;}";

    $s .= "sub DEFINE_SUBJECT_TAG          { 1;}";
    $s .= "sub DEFINE_MODE                 { 1;}";
    $s .= "sub DEFINE_FIELD_FORCED         { 1;}";
    $s .= "sub DEFINE_FIELD_ORIGINAL       { 1;}";
    $s .= "sub DEFINE_FIELD_OF_REPORT_MAIL { 1;}";
    $s .= "sub DEFINE_FIELD_PAT_TO_REJECT  { 1;}";
    $s .= "sub DEFINE_FIELD_LOOP_CHECKED   { 1;}";
    $s .= "sub UNDEF_FIELD_LOOP_CHECKED    { 1;}";

    $s .= "sub ADD_FIELD    { 1;}";
    $s .= "sub DELETE_FIELD { 1;}";
    $s .= "sub COPY_FIELD   { 1;}";
    $s .= "sub MOVE_FIELD   { 1;}";

    $s .= "sub ADD_CONTENT_HANDLER { 1;}";
    $s .= "sub DEFINE_MAILER       { 1;}";

    # procedure manipulation
    $s .= "sub PERMIT_PROCEDURE { 1;}";
    $s .= "sub DENY_PROCEDURE { 1;}";
    $s .= "sub DEFINE_PROCEDURE { 1;}";
    $s .= "sub PERMIT_ADMIN_PROCEDURE { 1;}";
    $s .= "sub DENY_ADMIN_PROCEDURE { 1;}";
    $s .= "sub DEFINE_ADMIN_PROCEDURE { 1;}";
    $s .= "sub DEFINE_MAXNUM_OF_PROCEDURE_IN_ONE_MAIL { 1;}";
    $s .= "sub DEFINE_MAXNUM_OF_ADMIN_PROCEDURE_IN_ONE_MAIL { 1;}";

    # misc
    $s .= "sub SIZE { ;}";

    # for convenience
    $s .= "sub DUMMY { ;}";
    $s .= "sub TRUE  { 1;}";
    $s .= "sub FALSE { \$NULL;}";

    # 1;
    $s .= "'1;\n";

    return $s;
}


sub gen_dummy_macros
{
    my $s = '';

    $s .= "sub GET_HEADER_FIELD_VALUE {
	\$PROC__GET_HEADER_FIELD_VALUE .= join(\" \", \@_ );
    }\n";
    $s .= "sub GET_ORIGINAL_HEADER_FIELD_VALUE {
	\$PROC__GET_ORIGINAL_HEADER_FIELD_VALUE .= join(\" \", \@_ );
    }\n";
    $s .= "sub SET_HEADER_FIELD_VALUE {
	\$PROC__SET_HEADER_FIELD_VALUE .= join(\" \", \@_ );
    }\n";
    $s .= "sub GET_ENVELOPE_VALUE {
	\$PROC__GET_ENVELOPE_VALUE .= join(\" \", \@_ );
    }\n";
    $s .= "sub SET_ENVELOPE_VALUE {
	\$PROC__SET_ENVELOPE_VALUE .= join(\" \", \@_ );
    }\n";
    $s .= "sub ENVELOPE_APPEND {
	\$PROC__ENVELOPE_APPEND .= join(\" \", \@_ );
    }\n";
    $s .= "sub ENVELOPE_PREPEND {
	\$PROC__ENVELOPE_PREPEND .= join(\" \", \@_ );
    }\n";
    $s .= "sub GET_BUFFER_FROM_FILE {
	\$PROC__GET_BUFFER_FROM_FILE .= join(\" \", \@_ );
    }\n";
    $s .= "sub STR2JIS {
	\$PROC__STR2JIS .= join(\" \", \@_ );
    }\n";
    $s .= "sub STR2EUC {
	\$PROC__STR2EUC .= join(\" \", \@_ );
    }\n";
    $s .= "sub JSTR {
	\$PROC__JSTR .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_SUBJECT_TAG {
	\$PROC__DEFINE_SUBJECT_TAG .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_MODE {
	\$PROC__DEFINE_MODE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_FIELD_FORCED {
	\$PROC__DEFINE_FIELD_FORCED .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_FIELD_ORIGINAL {
	\$PROC__DEFINE_FIELD_ORIGINAL .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_FIELD_OF_REPORT_MAIL {
	\$PROC__DEFINE_FIELD_OF_REPORT_MAIL .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_FIELD_PAT_TO_REJECT {
	\$PROC__DEFINE_FIELD_PAT_TO_REJECT .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_FIELD_LOOP_CHECKED {
	\$PROC__DEFINE_FIELD_LOOP_CHECKED .= join(\" \", \@_ );
    }\n";
    $s .= "sub UNDEF_FIELD_LOOP_CHECKED {
	\$PROC__UNDEF_FIELD_LOOP_CHECKED .= join(\" \", \@_ );
    }\n";
    $s .= "sub ADD_FIELD {
	\$PROC__ADD_FIELD .= join(\" \", \@_ );
    }\n";
    $s .= "sub DELETE_FIELD {
	\$PROC__DELETE_FIELD .= join(\" \", \@_ );
    }\n";
    $s .= "sub COPY_FIELD {
	\$PROC__COPY_FIELD .= join(\" \", \@_ );
    }\n";
    $s .= "sub MOVE_FIELD {
	\$PROC__MOVE_FIELD .= join(\" \", \@_ );
    }\n";
    $s .= "sub ADD_CONTENT_HANDLER {
	\$PROC__ADD_CONTENT_HANDLER .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_MAILER {
	\$PROC__DEFINE_MAILER .= join(\" \", \@_ );
    }\n";
    $s .= "sub PERMIT_PROCEDURE {
	\$PROC__PERMIT_PROCEDURE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DENY_PROCEDURE {
	\$PROC__DENY_PROCEDURE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_PROCEDURE {
	\$PROC__DEFINE_PROCEDURE .= join(\" \", \@_ );
    }\n";
    $s .= "sub PERMIT_ADMIN_PROCEDURE {
	\$PROC__PERMIT_ADMIN_PROCEDURE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DENY_ADMIN_PROCEDURE {
	\$PROC__DENY_ADMIN_PROCEDURE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_ADMIN_PROCEDURE {
	\$PROC__DEFINE_ADMIN_PROCEDURE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_MAXNUM_OF_PROCEDURE_IN_ONE_MAIL {
	\$PROC__DEFINE_MAXNUM_OF_PROCEDURE_IN_ONE_MAIL .= join(\" \", \@_ );
    }\n";
    $s .= "sub DEFINE_MAXNUM_OF_ADMIN_PROCEDURE_IN_ONE_MAIL {
	\$PROC__DEFINE_MAXNUM_OF_ADMIN_PROCEDURE_IN_ONE_MAIL .= join(\" \", \@_ );
    }\n";
    $s .= "sub SIZE {
	\$PROC__SIZE .= join(\" \", \@_ );
    }\n";
    $s .= "sub DUMMY {
	\$PROC__DUMMY .= join(\" \", \@_ );
    }\n";
    $s .= "sub TRUE {
	\$PROC__TRUE .= join(\" \", \@_ );
    }\n";
    $s .= "sub FALSE {
	\$PROC__FALSE .= join(\" \", \@_ );
    }\n";

    return $s;
}
