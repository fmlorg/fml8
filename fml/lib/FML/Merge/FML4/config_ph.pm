#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: config_ph.pm,v 1.13 2004/12/30 04:39:59 fukachan Exp $
#

package FML::Merge::FML4::config_ph;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $count $default_config_ph
	    $result %result);
use Carp;

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
# Return Value: HASH_REF
sub diff
{
    my ($self, $file) = @_;

    # reset always
    %result = ();

    $self->_load_default_config_ph();

    my $s = $self->_gen_eval_string($file);
    eval($s);
    print "error: $@\n" if $@;

    # print $result if defined $result;
    return \%result;
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
    $s .= sprintf("&%s::var_dump('config%03d', \\%%stab);\n", $package, $count);
    $s .= "use strict;\n";

    return $s;
}


# Descriptions: generate diff config.ph against defualt_config.ph and
#               save it at %result (global variable).
#    Arguments: STR($package) HASH_REF($stab)
# Side Effects: none
# Return Value: none
sub var_dump
{
    my ($package, $stab) = @_;
    my ($key, $val, $def, $x, $rbuf);

    # resolv
    eval "\$x = \$${package}::MAIL_LIST;\n";
    my ($ml_name, $ml_domain) = split(/\@/, $x);

    while (($key, $val) = each(%$stab)) {
	next if $key =~
	    /^(STRUCT_SOCKADDR|CFVersion|CPU_TYPE_MANUFACTURER_OS|HTML_THREAD_REF_TYPE|FQDN|REJECT_ADDR|SKIP_FIELDS)/;

	eval "\$val = \$${package}::$key;\n";
	eval "\$def = \$default::$key;\n";
	$def ||= 0;
	$val ||= 0;

	if (defined $val) {
	    $val =~ s/$ml_name/\$ml_name/g;
	    $val =~ s/$ml_domain/\$ml_domain/g;
	    if ($val && ($val ne $def)) {
		$rbuf .= "# $key => $val\n";
		$result{ $key } = $val;
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

=head2 translate($key, $value)

translate fml4 config {$key => $value } to fml8 one if could.

=cut


# Descriptions: translate fml4 config {$key => $value } to fml8 one if could.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate
{
    my ($self, $diff, $key, $value) = @_;
    my $dispatch = {
	rule_convert           => \&translate_xxx,
	rule_ignore            => \&translate_ignore,
	rule_prefer_fml4_value => \&translate_xxx,
	rule_prefer_fml8_value => \&translate_use_fml8_value,
    };

    use FML::Merge::FML4::Rules;
    my $s = FML::Merge::FML4::Rules::translate($self, $dispatch, $diff, $key, $value);
    return $s;
}


# Descriptions: translate fml4 config {$key => $value } to fml8 one if could.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_xxx
{
    my ($self, $diff, $key, $value) = @_;

    if ($key eq 'SUBJECT_TAG_TYPE'         ||
	$key eq 'BRACKET'                  ||
	$key eq 'BRACKET_SEPARATOR'        ||
	$key eq 'SUBJECT_FREE_FORM'        ||
	$key eq 'SUBJECT_FREE_FORM_REGEXP' ||
	$key eq 'SUBJECT_FORM_LONG_ID'     ||
	$key eq 'SUBJECT_HML_FORM'         ||
	$key eq 'HML_FORM_LONG_ID') {
	return $self->_fix_subject_tag($diff, $key, $value);
    }
    elsif ($key eq 'MAINTAINER') {
	return "maintainer = $value";
    }
    elsif ($key eq 'MAIL_LIST') {
	return "article_post_address = $value";
    }
    elsif ($key eq 'CONTROL_ADDRESS') {
	return "command_mail_address = $value";
    }
    elsif ($key eq 'OUTGOING_ADDRESS') {
	return "";
	return "# WARNING outgoing_address = $value";
    }
    elsif ($key eq 'SMTP_SENDER') {
	return "smtp_sender = $value";
    }
    elsif ($key eq 'REJECT_ADDR') {
	return "system_special_accounts = $value";
    }
    elsif ($key eq 'HOST' || $key eq 'PORT') {
	my $host = $diff->{ 'HOST' } || '127.0.0.1';
	my $port = $diff->{ 'PORT' } || 25;
	return "smtp_servers = $host:$port";
    }
    elsif ($key eq 'SPOOL_DIR') {
	my $v = $self->_fix_dir($diff, $key, $value, "spool");
	if ($v) {
	    return "spool_dir = $v";
	}
	else {
	    return "";
	}
    }
    elsif ($key eq 'TMP_DIR') {
	my $v = $self->_fix_dir($diff, $key, $value, "tmp");
	if ($v) {
	    return "tmp_dir = $v";
	}
	else {
	    return "";
	}
    }
    elsif ($key eq 'ADMIN_MEMBER_LIST') {
	$value = $self->_fix_map($diff, $key, $value);
	return "primary_admin_member_map = $value";
    }
    elsif ($key eq 'MEMBER_LIST') {
	$value = $self->_fix_map($diff, $key, $value);
	return "primary_member_map = $value";
    }
    elsif ($key eq 'ACTIVE_LIST') {
	$value = $self->_fix_map($diff, $key, $value);
	return "primary_recipient_map = $value";
    }
    elsif ($key eq 'PASSWD_FILE') {
	$value = $self->_fix_map($diff, $key, $value);
	return "primary_admin_member_password_map = $value";
    }
    elsif ($key eq 'LOGFILE') {
	return "log_file = $value";
    }
    elsif ($key eq 'GUIDE_FILE') {
	return "guide_file = $value";
    }
    elsif ($key eq 'OBJECTIVE_FILE') {
	return "objective_file = $value";
    }
    elsif ($key eq 'SEQUENCE_FILE') {
	return "article_sequence_file = $value";
    }
    elsif ($key eq 'SUMMARY_FILE') {
	return "summary_file = $value";
    }
    elsif ($key eq 'SKIP_FIELDS') {
	return $self->_fix_skip_fields($diff, $key, $value);
    }
    elsif ($key eq 'FILE_TO_REGIST') {
	$value = $self->_fix_map($diff, $key, $value);
	my $s = '';
	$s .= "primary_member_map      = $value\n";
	$s .= "primary_recipient_map   = $value\n";
	return $s;
    }
    elsif ($key eq 'NUM_LOG_MAIL') {
	return "incoming_mail_cache_size = $value\n";
    }
    elsif ($key eq 'ML_MEMBER_CHECK') {
	return $self->_fix_acl_policy($diff, $key, $value);
    }
    elsif ($key eq 'LOAD_LIBRARY') {
	return $self->_fix_module_definition($diff, $key, $value);
    }
    elsif ($key eq 'TZone') {
	return $self->_fix_time_zone($diff, $key, $value);
    }

    return '# ***ERROR*** UNKNOWN TRANSLATION RULE';
}


# Descriptions: handle map info.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_map
{
    my ($self, $diff, $key, $value) = @_;

    $value =~ s@\$DIR/@\$ml_home_dir/@g;
    return $value;
}


# Descriptions: handle directory info.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value) STR($match)
# Side Effects: none
# Return Value: STR
sub _fix_dir
{
    my ($self, $diff, $key, $value, $match) = @_;
    my $x = $value;

    $x =~ s@\$DIR/@@;
    $x =~ s@^/@@;
    $x =~ s@^/@@;
    $x =~ s@^/@@;

    print "// CHECK key=<$key> value=<$value> x=<$x>\n";
    if ($key eq $x) {
	return "";
    }
    else {
	$value =~ s@\$DIR/@\$ml_home_dir/@;
	return $value;
    }
}


# Descriptions: acl policy.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_acl_policy
{
    my ($self, $diff, $key, $value) = @_;

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
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_module_definition
{
    my ($self, $diff, $key, $value) = @_;

    if ($key eq 'LOAD_LIBRARY') {
	if ($value eq 'libfml.pl') {
	    return '# same as fml8 default';
	}
    }

    return '# ***ERROR*** UNKNOWN TRANSLATION POLICY';
}


# Descriptions: fix time zone.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_time_zone
{
    my ($self, $diff, $key, $value) = @_;

    if ($value eq ' JST') {
	return "system_timezone = +0900";
    }

    return "# ***ERROR*** UNKNOWN TIME ZONE";
}


# Descriptions: handle subject tag related conversion.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_skip_fields
{
    my ($self, $diff, $key, $value) = @_;
    my (@fields) = split(/\|/, $value);

    return "unsafe_header_fields = @fields";
}


# Descriptions: handle subject tag related conversion.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub _fix_subject_tag
{
    my ($self, $diff, $key, $value) = @_;
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


# Descriptions: ignore translation since this variable uses fml8 value.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_use_fml8_value
{
    my ($self, $diff, $key, $value) = @_;

   return "# IGNORED since \$$key uses fml8 value";
}


# Descriptions: ignore translation since this variable uses fml8 value.
#    Arguments: OBJ($self) HASH_REF($diff) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub translate_ignore
{
    my ($self, $diff, $key, $value) = @_;

   return "# IGNORED since \$$key is of no means";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Merge::FML4::config_ph appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
