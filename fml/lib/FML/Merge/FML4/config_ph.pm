#-*- perl -*-
#
#  Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: config_ph.pm,v 1.23 2006/03/20 05:59:01 fukachan Exp $
#

package FML::Merge::FML4::config_ph;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $count $default_config_ph
	    $result %diff_result %config_result %config_default);
use Carp;

my $debug = 0;


=head1 NAME

FML::Merge::FML4::config_ph - handle fml4's config.ph file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: set default_config.ph path.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub set_default_config_ph
{
    my ($self, $file) = @_;

    $default_config_ph = $file;
}


# Descriptions: diff config.ph and return it as HASH_REF.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: ARRAY(HASH_REF, HASH_REF)
sub diff
{
    my ($self, $file) = @_;

    # reset always
    %diff_result   = ();
    %config_result = ();

    $self->_load_default_config_ph();

    my $s = $self->_gen_eval_string($file);
    eval($s);
    print "error: $@\n" if $@;

    # print $result if defined $result;
    return( \%config_result,  \%diff_result );
}


# Descriptions: load default_config.ph into "default" name space.
#    Arguments: none
# Side Effects: default name space filled up by default_config.ph content.
# Return Value: none
sub _load_default_config_ph
{
    package default;
    no strict;

    $DIR               = '$DIR';
    $DOMAINNAME        = '$ml_domain';
    $MAIL_LIST         = '$ml_name@$ml_domain';
    $CONTROL_ADDRESS   = '$ml_name-ctl@$ml_domain';
    $OUTGOING_ADDRESS  = '$ml_name-outgoing@$ml_domain';
    $MAINTAINER        = '$ml_name-admin@$ml_domain';
    $ERRORS_TO         = '$ml_name-admin@$ml_domain';
    $BRACKET           = '$ml_name';
    $ML_FN             = '($ml_name ML)';
    $XMLNAME           = '';
    $GOOD_BYE_PHRASE   = '';
    $WELCOME_STATEMENT = '';

    require $FML::Merge::FML4::config_ph::default_config_ph;

    $DIR              = '$DIR';
    $DOMAINNAME       = '$ml_domain';
    $MAIL_LIST        = '$ml_name@$ml_domain';
    $CONTROL_ADDRESS  = '$ml_name-ctl@$ml_domain';
    $OUTGOING_ADDRESS = '$ml_name-outgoing@$ml_domain';
    $MAINTAINER       = '$ml_name-admin@$ml_domain';
    $ERRORS_TO        = '$ml_name-admin@$ml_domain';
    $BRACKET          = '$ml_name';
    $ML_FN            = '($ml_name ML)';
    $GOOD_BYE_PHRASE  = '--$ml_name@$ml_domain, Be Seeing You!';
    $XMLNAME          = 'X-ML-Name: $ml_name';

    $WELCOME_STATEMENT =~ s/our /our \(\$ml_name ML\)/;

    package main;
}


# Descriptions: generate string to evaluate to load config.ph.
#    Arguments: OBJ($self) STR($f)
# Side Effects: none
# Return Value: STR
sub _gen_eval_string
{
    my ($self, $f) = @_;
    my $package = 'FML::Merge::FML4::config_ph';
    my $s = '';

    $count++;

    $s  = "no strict;\n";
    $s .= sprintf("package config%03d;\n", $count);
    $s .= sprintf("\$DIR = \'\$DIR\';\n");
    $s .= sprintf("\$s = &%s::gen_dummy_macros();\n", $package);
    $s .= sprintf("eval \$s;\n");
    $s .= sprintf("print STDERR \$\@ if \$\@;\n");
    $s .= sprintf("require \"%s\";\n", $f);
    $s .= sprintf("package main;\n");
    $s .= sprintf("*stab = *{\"config%03d::\"};\n", $count);
    $s .= sprintf("&%s::dump_variable('config%03d', \\%%stab);\n", $package, $count);
    $s .= "use strict;\n";

    return $s;
}


# Descriptions: generate diff config.ph against defualt_config.ph and
#               save it at %diff_result (global variable).
#    Arguments: STR($package) HASH_REF($stab)
# Side Effects: none
# Return Value: none
sub dump_variable
{
    my ($package, $stab) = @_;
    my ($key, $val, $def, $x, $rbuf);

    # resolv
    eval "\$x = \$${package}::MAIL_LIST;\n";
    my ($ml_name, $ml_domain) = split(/\@/, $x);

    while (($key, $val) = each(%$stab)) {
	next if $key =~
	    /^(STRUCT_SOCKADDR|CFVersion|CPU_TYPE_MANUFACTURER_OS|HTML_THREAD_REF_TYPE|FQDN)/;

	eval "\$val = \$${package}::$key;\n";
	eval "\$def = \$default::$key;\n";
	$def ||= 0;
	$val ||= 0;

	if (defined $val) {
	    $val =~ s/$ml_name/\$ml_name/g;
	    $val =~ s/$ml_domain/\$ml_domain/g;
	    if ($val ne $def) {
		$rbuf .= "# $key => $val\n";
		$diff_result{ $key } = $val || "___nil___";
	    }

	    # save all values.
	    $config_default{ $key } = $def;
	    $config_result{ $key }  = $val;

	    if ($debug) {
		print "CONFIG: $key => $val\n";
		if ($diff_result{ $key }) {
		    print "  DIFF: $diff_result{$key}\n";
		}
	    }
	}
    }

    $result = $rbuf;
}


# Descriptions: generate macro definitions used in fml4 config.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub gen_dummy_macros
{
    my $s = '';

    $s .= "sub GET_HEADER_FIELD_VALUE {
	\$PROC__GET_HEADER_FIELD_VALUE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub GET_ORIGINAL_HEADER_FIELD_VALUE {
	\$PROC__GET_ORIGINAL_HEADER_FIELD_VALUE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub SET_HEADER_FIELD_VALUE {
	\$PROC__SET_HEADER_FIELD_VALUE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub GET_ENVELOPE_VALUE {
	\$PROC__GET_ENVELOPE_VALUE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub SET_ENVELOPE_VALUE {
	\$PROC__SET_ENVELOPE_VALUE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub ENVELOPE_APPEND {
	\$PROC__ENVELOPE_APPEND .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub ENVELOPE_PREPEND {
	\$PROC__ENVELOPE_PREPEND .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub GET_BUFFER_FROM_FILE {
	\$PROC__GET_BUFFER_FROM_FILE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub STR2JIS {
	\$PROC__STR2JIS .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub STR2EUC {
	\$PROC__STR2EUC .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub JSTR {
	\$PROC__JSTR .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_SUBJECT_TAG {
	\$PROC__DEFINE_SUBJECT_TAG .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_MODE {
	\$PROC__DEFINE_MODE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_FIELD_FORCED {
	\$PROC__DEFINE_FIELD_FORCED .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_FIELD_ORIGINAL {
	\$PROC__DEFINE_FIELD_ORIGINAL .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_FIELD_OF_REPORT_MAIL {
	\$PROC__DEFINE_FIELD_OF_REPORT_MAIL .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_FIELD_PAT_TO_REJECT {
	\$PROC__DEFINE_FIELD_PAT_TO_REJECT .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_FIELD_LOOP_CHECKED {
	\$PROC__DEFINE_FIELD_LOOP_CHECKED .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub UNDEF_FIELD_LOOP_CHECKED {
	\$PROC__UNDEF_FIELD_LOOP_CHECKED .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub ADD_FIELD {
	\$PROC__ADD_FIELD .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DELETE_FIELD {
	\$PROC__DELETE_FIELD .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub COPY_FIELD {
	\$PROC__COPY_FIELD .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub MOVE_FIELD {
	\$PROC__MOVE_FIELD .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub ADD_CONTENT_HANDLER {
	\$PROC__ADD_CONTENT_HANDLER .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_MAILER {
	\$PROC__DEFINE_MAILER .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub PERMIT_PROCEDURE {
	\$PROC__PERMIT_PROCEDURE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DENY_PROCEDURE {
	\$PROC__DENY_PROCEDURE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_PROCEDURE {
	\$PROC__DEFINE_PROCEDURE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub PERMIT_ADMIN_PROCEDURE {
	\$PROC__PERMIT_ADMIN_PROCEDURE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DENY_ADMIN_PROCEDURE {
	\$PROC__DENY_ADMIN_PROCEDURE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_ADMIN_PROCEDURE {
	\$PROC__DEFINE_ADMIN_PROCEDURE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_MAXNUM_OF_PROCEDURE_IN_ONE_MAIL {
	\$PROC__DEFINE_MAXNUM_OF_PROCEDURE_IN_ONE_MAIL .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DEFINE_MAXNUM_OF_ADMIN_PROCEDURE_IN_ONE_MAIL {
	\$PROC__DEFINE_MAXNUM_OF_ADMIN_PROCEDURE_IN_ONE_MAIL .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub SIZE {
	\$PROC__SIZE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub DUMMY {
	\$PROC__DUMMY .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub TRUE {
	\$PROC__TRUE .= join(\" \", \@_ ). \" \";
    }\n";
    $s .= "sub FALSE {
	\$PROC__FALSE .= join(\" \", \@_ ). \" \";
    }\n";

    return $s;
}


=head1 TRANSLATION FROM 4 TO 8

=head2 translate($config, $diff, $key, $value)

translate fml4 config {$key => $value } to fml8 one if could.

=cut


# Descriptions: translate fml4 config {$key => $value } to fml8 one if could.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate
{
    my ($self, $config, $diff, $key, $value) = @_;
    my $dispatch = {
	rule_convert             => \&translate_xxx,
	rule_ignore              => \&translate_ignore,
	rule_not_yet_implemented => \&translate_not_yet_implemented,
	rule_prefer_fml4_value   => \&translate_xxx,
	rule_prefer_fml8_value   => \&translate_use_fml8_value,
    };

    use FML::Merge::FML4::Rules;
    my $s = FML::Merge::FML4::Rules::translate($self,
					       $dispatch,
					       $config,
					       $diff,
					       $key,
					       $value);
    return $s;
}


# Descriptions: translate fml4 config {$key => $value } to fml8 one if could.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_xxx
{
    my ($self, $config, $diff, $key, $value) = @_;

    if ($key eq 'SUBJECT_TAG_TYPE'         ||
	$key eq 'BRACKET'                  ||
	$key eq 'BRACKET_SEPARATOR'        ||
	$key eq 'SUBJECT_FREE_FORM'        ||
	$key eq 'SUBJECT_FREE_FORM_REGEXP' ||
	$key eq 'SUBJECT_FORM_LONG_ID'     ||
	$key eq 'SUBJECT_HML_FORM'         ||
	$key eq 'HML_FORM_LONG_ID') {
	return $self->_fix_subject_tag($config, $diff, $key, $value);
    }
    elsif ($key eq 'PERMIT_POST_FROM'      ||
	   $key eq 'REJECT_POST_HANDLER'   ||
	   $key eq 'PERMIT_COMMAND_FROM'   ||
	   $key eq 'REJECT_COMMAND_HANDLER') {
	return $self->_fix_restrictions($config, $diff, $key, $value);
    }
    elsif ($key eq 'MAINTAINER') {
	my $value = $self->_fix_address($config, $diff, $key, $value);
	return "maintainer = $value";
    }
    elsif ($key eq 'MAIL_LIST') {
	my $value = $self->_fix_address($config, $diff, $key, $value);
	return "article_post_address = $value";
    }
    elsif ($key eq 'CONTROL_ADDRESS') {
	my $value = $self->_fix_address($config, $diff, $key, $value);
	return "command_mail_address = $value";
    }
    elsif ($key eq 'OUTGOING_ADDRESS') {
	my $value = $self->_fix_address($config, $diff, $key, $value);
	return "";
	return "# WARNING outgoing_address = $value";
    }
    elsif ($key eq 'SMTP_SENDER') {
	my $value = $self->_fix_address($config, $diff, $key, $value);
	return "smtp_sender = $value";
    }
    elsif ($key eq 'ERRORS_TO') {
	my $value = $self->_fix_address($config, $diff, $key, $value);
	return "mail_header_default_errors_to = $value";
    }
    elsif ($key eq 'LIST_POST'        ||
	   $key eq 'LIST_OWNER'       ||
	   $key eq 'LIST_HELP'        ||
	   $key eq 'LIST_SUBSCRIBE'   ||
	   $key eq 'LIST_UNSUBSCRIBE' ||
	   $key eq 'LIST_ID'          ) {
	my $value    = $self->_fix_address($config, $diff, $key, $value);
	my $var_name = sprintf("mail_header_default_%s", lc($key));
	return "$var_name = $value";
    }
    elsif ($key eq 'REJECT_ADDR') {
	my ($list) = join(" ", split(/\|/, $value));
	return "system_special_accounts = $list";
    }
    elsif ($key eq 'HOST' || $key eq 'PORT') {
	my $host = $diff->{ 'HOST' } || '127.0.0.1';
	my $port = $diff->{ 'PORT' } || 25;
	$host = $host eq '___nil___' ? '127.00.1' : $host;
	$port = $port eq '___nil___' ? 25 : $port; 
	return "smtp_servers = $host:$port";
    }
    elsif ($key eq 'SPOOL_DIR' || $key eq 'TMP_DIR') {
	my $v = $self->_fix_path($config, $diff, $key, $value);
	if ($v) {
	    $key =~ tr/A-Z/a-z/;
	    return "$key = $v";
	}
	else {
	    return "";
	}
    }
    elsif ($key eq 'ADMIN_MEMBER_LIST') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "primary_admin_member_map = $value";
    }
    elsif ($key eq 'MEMBER_LIST') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "primary_member_map = $value";
    }
    elsif ($key eq 'ACTIVE_LIST') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "primary_recipient_map = $value";
    }
    elsif ($key eq 'MODERATOR_MEMBER_LIST') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	my $r1 = "primary_moderator_member_map = $value";
	my $r2 = "primary_moderator_recipient_map = $value";
	return "$r1\n\n$r2";
    }
    elsif ($key eq 'PASSWD_FILE') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "primary_admin_member_password_map = $value";
    }
    elsif ($key eq 'LOGFILE') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "log_file = $value";
    }
    elsif ($key eq 'GUIDE_FILE') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "guide_file = $value";
    }
    elsif ($key eq 'OBJECTIVE_FILE') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "objective_file = $value";
    }
    elsif ($key eq 'SEQUENCE_FILE') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "article_sequence_file = $value";
    }
    elsif ($key eq 'SUMMARY_FILE') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	return "summary_file = $value";
    }
    elsif ($key eq 'SKIP_FIELDS') {
	return $self->_fix_skip_fields($config, $diff, $key, $value);
    }
    elsif ($key eq 'FILE_TO_REGIST') {
	$value = $self->_fix_path($config, $diff, $key, $value);
	my $s = '';
	$s .= "primary_member_map      = $value\n";
	$s .= "primary_recipient_map   = $value\n";
	return $s;
    }
    elsif ($key eq 'ML_MEMBER_CHECK') {
	return $self->_fix_acl_policy($config, $diff, $key, $value);
    }
    elsif ($key eq 'LOAD_LIBRARY') {
	return $self->_fix_module_definition($config, $diff, $key, $value);
    }
    elsif ($key eq 'TZone') {
	return $self->_fix_time_zone($config, $diff, $key, $value);
    }
    elsif ($key eq 'INCOMING_MAIL_SIZE_LIMIT') {
	my ($s, $v);

	$v = $self->_fix_atoi($config, $diff, $key, $value);

	$s .= sprintf("incoming_article_body_size_limit = %d\n\n", $v);
	$s .= sprintf("incoming_command_mail_body_size_limit = %d\n\n", $v);
	return $s;
    }
    elsif ($key eq 'LOGFILE_NEWSYSLOG_LIMIT') {
	my ($s, $v);

	$v = $self->_fix_atoi($config, $diff, $key, $value);

	$s .= sprintf("use_log_rotate = yes\n\n");
	$s .= sprintf("log_rotate_size_limit = %d\n\n", $v);
	return $s;
    }
    elsif ($key eq 'XMLNAME') {
	my ($s, $v);

	$v = $value;
	$v =~ s/X-ML-Name:\s+//g;

	$s .= sprintf("outgoing_mail_header_x_ml_name = %s\n\n", $v);
	return $s;	
    }

    return '# ***ERROR*** UNKNOWN TRANSLATION RULE';
}


# Descriptions: restrictions
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_restrictions
{
    my ($self, $config, $diff, $key, $value) = @_;
    my $p_result = '';
    my $c_result = '';

    unless ( $self->{ _cache }->{ restrictions } ) {
	my $permit_post_from       = $config->{ PERMIT_POST_FROM }       || '';
	my $reject_post_handler    = $config->{ REJECT_POST_HANDLER }    || '';
	my $permit_command_from    = $config->{ PERMIT_COMMAND_FROM }    || '';
	my $reject_command_handler = $config->{ REJECT_COMMAND_HANDLER } || '';

 	# flags
	my $mode      = 'manual';
	my $symmetric = 1;

	#
	# permit_*_from based
	#
	if ($permit_post_from eq 'anyone') {
	    $p_result .= "article_post_restrictions = ";
	    $p_result .= "reject_system_special_accounts ";
	    $p_result .= "permit_anyone ";
	    $p_result .= "reject\n";
	}
	elsif ($permit_post_from eq 'members_only') { # fml8 default
	    ;
	}
	elsif ($permit_post_from eq 'moderator') {
	    $p_result .= "article_post_restrictions = ";
	    $p_result .= "reject_system_special_accounts ";
	    $p_result .= "permit_forward_to_moderator ";
	    $p_result .= "reject\n";
	}

	#
	# handler based
	#
	if ($reject_post_handler =~ /auto_regist|autoregist|auto_subscribe/) {
	    $mode     = "automatic";
	    $symmetric = 1;
	}
	elsif ($reject_post_handler =~ /auto_asymmetric_regist/) {
	    $mode     = "automatic";
	    $symmetric = 0;
	}
	elsif ($reject_post_handler eq 'ignore') {
	    if ($p_result =~ /article_post_restrictions/) {
		$p_result =~ s/\s+reject\s*$/ ignore/g;
	    }
	    else {
		$c_result .= "\n";
		$p_result .= "article_post_restrictions = ";
		$p_result .= "reject_system_special_accounts ";
		$p_result .= "permit_member_maps ";
		$p_result .= "ignore\n";
	    }
	}
	elsif ($reject_post_handler eq 'reject') {

	}

	if ($reject_command_handler eq 'ignore') {
	    if ($c_result =~ /command_mail_restrictions/) {
		$c_result =~ s/\s+reject\s*$/ ignore/g;
	    }
	    else {
		$c_result .= "\n";
		$c_result .= "command_mail_restrictions = ";
		$c_result .= "reject_system_special_accounts ";
		$c_result .= "permit_anonymous_command ";
		$c_result .= "permit_user_command ";
		$c_result .= "ignore\n";
	    }
	}
	elsif ($reject_command_handler =~
	    /auto_regist|autoregist|auto_subscribe/) {
	    $mode     = "automatic";
	    $symmetric = 1;
	}
	elsif ($reject_command_handler =~ /auto_asymmetric_regist/) {
	    $mode     = "automatic";
	    $symmetric = 0;
	}
	elsif ($reject_command_handler eq "reject") {
	    ;
	}

	unless ($symmetric) {
	    ; # ?
	}

	if ($mode eq 'manual') {
	    $c_result .= "\nsubscribe_command_operation_mode = manual\n";
	}
	elsif ($mode eq 'automatic') {
	    $c_result .= "\nsubscribe_command_operation_mode = automatic\n";
	}
	else {
	    $c_result .= "\n# unknown operation mode = $mode\n";
	}

	$self->{ _cache }->{ restrictions } = 1;

	return "$p_result\n$c_result\n";
    }
    else {
	return "# OK (already translated)\n";
    }
}


# Descriptions: convert address related parameters.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_address
{
    my ($self, $config, $diff, $key, $value) = @_;
    my $address = $value;
    my $fqdn = `hostname`;
    $fqdn =~ s/\s*$//;

    $address =~ s/\$DOMAINNAME/\$ml_domain/g;
    $address =~ s/\$FQDN/$fqdn/g;

    return $address;
}


# Descriptions: handle map info.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_path
{
    my ($self, $config, $diff, $key, $value) = @_;

    # 1. $value is either of ^$DIR or ^./ directory.
    if ($self->_is_relative_to_fml4_home_dir($value)) {
	my $relative_path = $self->_cutoff_fml4_home_dir_prefix($value);
	return $self->_fml8_absolete_path($relative_path);
    }
    # 2. $value is absolute path.
    elsif ($self->_is_absolute_path($value)) {
	return $value;
    }
    # 3. $value is a file name only (must be relative to $DIR or ./ directory).
    else {
	return $self->_fml8_absolete_path($value);
    }
}


# Descriptions: check if $path is relative to fml4 $DIR.
#    Arguments: OBJ($self) STR($path)
# Side Effects: none
# Return Value: NUM
sub _is_relative_to_fml4_home_dir
{
    my ($self, $path) = @_;

    if ($path =~ /^\$DIR/ || $path =~ /^\.\//) {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: check if $path is absolute.
#    Arguments: OBJ($self) STR($path)
# Side Effects: none
# Return Value: NUM
sub _is_absolute_path
{
    my ($self, $path) = @_;

    use File::Spec;
    return File::Spec->file_name_is_absolute($path);
}


# Descriptions: check if $path is relative to fml4 $DIR.
#    Arguments: OBJ($self) STR($path)
# Side Effects: none
# Return Value: NUM
sub _cutoff_fml4_home_dir_prefix
{
    my ($self, $path) = @_;

    $path =~ s/^\$DIR//;
    $path =~ s/^\.//;
    $path =~ s/^\///;
    return $path;
}


# Descriptions: relative path-ify.
#    Arguments: OBJ($self) STR($path)
# Side Effects: none
# Return Value: STR
sub _split_path
{
    my ($self, $path) = @_;

    use File::Spec;
    my ($volume, $directories, $file) = File::Spec->splitpath( $path );
    return $file;
}


# Descriptions: be absolete path.
#    Arguments: OBJ($self) STR($x)
# Side Effects: none
# Return Value: STR
sub _fml8_absolete_path
{
    my ($self, $x) = @_;

    use File::Spec;
    return File::Spec->catfile('$ml_home_dir', $x);
}


# Descriptions: acl policy.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_acl_policy
{
    my ($self, $config, $diff, $key, $value) = @_;

    if ($key eq 'ML_MEMBER_CHECK') {
	if ($value) {
	    return '# same as fml8 default';
	}
	else {
	    # post = auto_regist, command = auto_regist
	    return '# same as fml8 default';
	}
    }

    return '# ***ERROR*** UNKNOWN TRANSLATION POLICY';
}


# Descriptions: acl policy.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_module_definition
{
    my ($self, $config, $diff, $key, $value) = @_;

    if ($key eq 'LOAD_LIBRARY') {
	if ($value eq 'libfml.pl') {
	    return '# same as fml8 default';
	}
    }

    return '# ***ERROR*** UNKNOWN TRANSLATION POLICY';
}


# Descriptions: fix time zone.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_time_zone
{
    my ($self, $config, $diff, $key, $value) = @_;

    if ($value eq ' JST') {
	return "system_timezone = +0900";
    }

    return "# ***ERROR*** UNKNOWN TIME ZONE";
}


# Descriptions: handle subject tag related conversion.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_skip_fields
{
    my ($self, $config, $diff, $key, $value) = @_;
    my (@fields) = split(/\|/, $value);

    return "unsafe_header_fields = @fields";
}


# Descriptions: handle subject tag related conversion.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_subject_tag
{
    my ($self, $config, $diff, $key, $value) = @_;
    my $s = "article_header_rewrite_rules += rewrite_article_subject_tag\n\n";

    # ensure uniqueness
    return '#    ALREADY TRANSLATED' if $self->{ _subject_tag_fixed };
    $self->{ _subject_tag_fixed } = 1;

    # variables
    my $type             = $diff->{ 'SUBJECT_TAG_TYPE' }         || '';
    my $bracket          = $diff->{ 'BRACKET' }                  || '';
    my $bracket_sep      = $diff->{ 'BRACKET_SEPARATOR' }        || '';
    my $free_form        = $diff->{ 'SUBJECT_FREE_FORM' }        || '';
    my $free_form_regexp = $diff->{ 'SUBJECT_FREE_FORM_REGEXP' } || '';
    my $free_long_id     = $diff->{ 'SUBJECT_FORM_LONG_ID' }     || 5;

    # fml2 compatible
    if ($diff->{ 'SUBJECT_HML_FORM' }) {
	$type = '[:]';
    }
    if ($diff->{ 'HML_FORM_LONG_ID' }) {
	$free_long_id = $diff->{ 'HML_FORM_LONG_ID' };
    }

    if ($type eq '[:]') {
	$s .= "article_subject_tag = [\$ml_name:\%05d]\n";
    }
    elsif ($type eq '[,]') {
	$s .= "article_subject_tag = [\$ml_name,\%05d]\n";
    }
    elsif ($type eq '[ ]') {
	$s .= "article_subject_tag = [\$ml_name \%05d]\n";
    }
    elsif ($type eq '(:)') {
	$s .= "article_subject_tag = (\$ml_name:\%05d)\n";
    }
    elsif ($type eq '(,)') {
	$s .= "article_subject_tag = (\$ml_name,\%05d)\n";
    }
    elsif ($type eq '( )') {
	$s .= "article_subject_tag = (\$ml_name \%05d)\n";
    }
    elsif ($type eq '()') {
	$s .= "article_subject_tag = (\$ml_name)\n";
    }
    elsif ($type eq '[]') {
	$s .= "article_subject_tag = [\$ml_name]\n";
    }
    elsif ($type eq '(ID)') {
	$s .= "article_subject_tag = (\%05d)\n";
    }
    elsif ($type eq '[ID]') {
	$s .= "article_subject_tag = [\%05d]\n";
    }

    if ($free_long_id != 5) {
	my $r = sprintf("%%0%dd", $free_long_id);
	$s =~ s/\%05d/$r/g;
    }

    return $s;
}


# Descriptions: convert from ascii to number.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_atoi
{
    my ($self, $config, $diff, $key, $value) = @_;
    my $x = $value;

    if ($x =~ /^(\d+)$/) {
	;
    }
    elsif ($x =~ /^(\d+)K$/i) {
	$x *= 1024;
    }
    elsif ($x =~ /^(\d+)M$/i) {
	$x *= 1024*1024;
    }

    return $x;
}


# Descriptions: ignore translation since this variable uses fml8 value.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_use_fml8_value
{
    my ($self, $config, $diff, $key, $value) = @_;

   return "# IGNORED since \$$key prefers fml8 value.";
}


# Descriptions: ignore translation since this variable uses fml8 value.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_ignore
{
    my ($self, $config, $diff, $key, $value) = @_;

   return "# IGNORED since \$$key is of no means.";
}


# Descriptions: show this variable is not yet implemented.
#    Arguments: OBJ($self)
#               HASH_REF($config) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_not_yet_implemented
{
    my ($self, $config, $diff, $key, $value) = @_;

   return "# ERROR. SORRY \$$key IS NOT YET IMPLEMENTED.";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Merge::FML4::config_ph appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
