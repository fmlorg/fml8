#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DB.pm,v 1.1.2.4 2003/06/03 13:49:08 fukachan Exp $
#

package Mail::Message::DB;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use lib qw(../../../../fml/lib
	   ../../../../cpan/lib
	   ../../../../img/lib
	   );

my $version = q$FML: DB.pm,v 1.1.2.4 2003/06/03 13:49:08 fukachan Exp $;
if ($version =~ /,v\s+([\d\.]+)\s+/) { $version = $1;}

my $debug = 1;

my $keepalive = 1;

#     map = { key => value } (normal order hash)
# inv_map = { value => key } (inverted hash)
#             or
#           { value => "key key2 key3 ..."  } (inverted hash)
my (@table_list) = qw(
		      from who date subject to cc reply_to

		      message_id
		      inv_message_id

		      ref_key_list
		      next_key
		      prev_key

		      filename
		      filepath
		      subdir

		      month 
		      inv_month

		      hint
		      );



=head1 NAME

Mail::Message::DB - DB interface

=head1 SYNOPSIS

  ... lock by something ...

  ... unlock by something ...

This module itself provides no lock function.
please use flock() built in perl or CPAN lock modules for it.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new($args)>

    my $args = {
	db_module    => 'AnyDBM_File',
	db_base_dir  => '/var/spool/ml/@udb@/thread',
	db_name      => 'elena',  # mailing list identifier
	key          => 100,      # article sequence number
    };

In fml 8 case, C<table> not needs the full mail address such as
C<elena@fml.org> since fml uses different $db_base_dir for each
domain.

For example, this module creates/updates the following databases (e.g.
/$db_base_dir/$db_name/$table.db where $table is 'article', '
message_id', 'sender', et.al.).

   /var/spool/ml/@udb@/thread/elena/articles.db
   /var/spool/ml/@udb@/thread/elena/date.db
   /var/spool/ml/@udb@/thread/elena/message_id.db
   /var/spool/ml/@udb@/thread/elena/sender.db
   /var/spool/ml/@udb@/thread/elena/status.db
   /var/spool/ml/@udb@/thread/elena/thread_id.db

Almost all tables use $key (article sequence number) as primary key
since it is unique in the mailing list articles.

    # key => filepath
    $article = {
	100 => /var/spool/ml/elena/spool/100,
	101 => /var/spool/ml/elena/spool/101,
    };

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # initialize DB module backend
    set_db_module_name($me, $args->{ db_module } || 'AnyDBM_File');

    # db_base_dir = /var/spool/ml/@udb@/elena
    set_db_base_dir($me,
		    $args->{ db_base_dir } || croak("specify db_base_dir"));

    # $db_name/$table uses $key as primary key.
    set_db_name($me, $args->{ db_name }) if defined $args->{ db_name };
    set_key($me,     $args->{ key })     if defined $args->{ key };
		
    return bless $me, $type;
}


# Descriptions: destructor.
#    Arguments: OBJ($self)
# Side Effects: close db
# Return Value: none
sub DESTROY
{
    my ($self) = @_;

    if (defined $self->{ _db }) {
	$self->db_close();
    }
}


=head1 PARSE and ANALYZE

=cut


# Descriptions: update database on message header, thread relation
#               et. al.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: update database
# Return Value: none
sub analyze
{
    my ($self, $msg) = @_;
    my $hdr      = $msg->whole_message_header;
    my $date     = $hdr->get('date');     $date    =~ s/\s*$//;
    my $to       = $hdr->get('to');       $to      =~ s/\s*$//;
    my $cc       = $hdr->get('cc');       $cc      =~ s/\s*$//;
    my $replyto  = $hdr->get('reply-to'); $replyto =~ s/\s*$//;
    my $subject  = $hdr->get('subject');  $subject =~ s/\s*$//;
    my $id       = $self->get_key();
    my $month    = $self->msg_time($hdr, 'yyyy/mm');
    my $subdir   = $self->msg_time($hdr, 'yyyymm');
    my $_subject = $self->_decode_mime_string($subject);
    my $who      = $self->_who_of_address( $hdr->get('from') );
    my $ra_from  = $self->_address_clean_up( $hdr->get('from') );
    my $ra_mid   = $self->_address_clean_up( $hdr->get('message-id') );
    my $from     = $ra_from->[0] || 'unknown';
    my $mid      = $ra_mid->[0]  || '';

    my $db = $self->db_open();

    $self->_update_max_id($db, $id);

    $self->_db_set($db, 'date',     $id, $date);     # Sun Jun 1 13:46:15 ...
    $self->_db_set($db, 'from',     $id, $from);     # rudo@nuinui.net
    $self->_db_set($db, 'reply_to', $id, $replyto);  # a@b
    $self->_db_set($db, 'who',      $id, $who);      # Rudolf Shumidt
    $self->_db_set($db, 'subject',  $id, $_subject); # subject string ...
    $self->_db_set($db, 'to',       $id, $to);       # a@b
    $self->_db_set($db, 'cc',       $id, $cc);       # a@b
    $self->_db_set($db, 'month',    $id, $month);    # 2003/06
    $self->_db_set($db, 'subdir',   $id, $subdir);   # 200306
    $self->_db_set($db, 'id',       $id, $id);       # 100

    if ($mid) {
	$self->_db_set($db, 'message_id',     $id, $mid); # 20030601rudo@nui
	$self->_db_set($db, 'inv_message_id', $mid, $id); # REVERSE_MAP
    }

    # HASH { YYYY/MM => (id1 id2 id3 ..) }
    $self->_db_array_add($db, 'inv_month', $month, $id);

    $self->_analyze_thread($db, $msg, $hdr);

    unless ($keepalive) {
	$self->db_close();
    }
}


# Descriptions: update $max_id in hint.
#    Arguments: OBJ($self) HASH_REF($db) NUM($id)
# Side Effects: update hint in $db
# Return Value: none
sub _update_max_id
{
    my ($self, $db, $id) = @_;

    # we should not update max_id when our target is an attachment.
    # update max_id only under the top level operation
    unless ($self->{ _is_attachment }) {
	_PRINT_DEBUG("mode = parent");

	my $max_id = $self->_db_get($db, 'hint', 'max_id') || 0;
	if (defined $max_id && $max_id) {
	    my $value = $max_id < $id ? $id : $max_id;
	    $self->_db_set($db, 'hint', 'max_id', $value);
	}
	else {
	    $self->_db_set($db, 'hint', 'max_id', $id);
	}
    }
    else {
	_PRINT_DEBUG("mode = child");
    }
}


# Descriptions: analyze thread information based on In-Reply-To: 
#               and References. It updates HASH_REF(ref_key_list).
#
#               For example, "article 101" is a reply to "article 100"
#               and references: shows 101 refers 90 and 91.
#               "article 102" is a reply to 101 but without references.
#               "article 91" is a reply to 90.
#                       ref_key_list = {
#                                101 => "102"
#                                100 => "101",
#                                 90 => "91 101",
#                                 91 => "101",
#                       };
#
#    Arguments: OBJ($self) HASH_REF($db) OBJ($msg) OBJ($hdr)
# Side Effects: update db
# Return Value: none
sub _analyze_thread
{
    my ($self, $db, $msg, $hdr) = @_;
    my $current_key  = $self->get_key();
    my $ra_ref       = $self->_address_clean_up($hdr->get('references'));
    my $ra_inreplyto = $self->_address_clean_up($hdr->get('in-reply-to'));
    my $in_reply_to  = $ra_inreplyto->[0] || '';
    my %uniq         = ();
    my $count        = 0;

    # search order is artibrary (see comments above).
  MSGID_SEARCH:
    for my $mid (@$ra_inreplyto, @$ra_ref) {
	next MSGID_SEARCH unless defined $mid;

	# ensure uniqueness
	next MSGID_SEARCH if $uniq{$mid};
	$uniq{$mid} = 1;

	$count++;

	my $head_id = $self->_db_get($db, 'inv_message_id', $mid) || 0;
	if ($head_id && $head_id != $current_key) {
	    $self->_db_array_add($db, 'ref_key_list', $head_id, $current_key);
	    _PRINT_DEBUG("THREAD SEARCH: $head_id => $current_key");
	}
	else {
	    _PRINT_DEBUG("THREAD SEARCH: NOT FOUND");
	}
    }

    unless ($count) {
	_PRINT_DEBUG("THREAD SEARCH: NOT TRY");
    }

    # II. ok. go to speculate prev/next links
    #   1. If In-Reply-To: is found, use it as "pointer to previous id"
    my $idp = 0;
    if (defined $in_reply_to) {
	# XXX idp (id pointer) = id1 by _head_of_list_str( (id1 id2 id3 ...)
	$idp = $self->_db_get($db, 'inv_message_id', $in_reply_to);
    }
    # 2. if not found, try to use References: "in reverse order"
    elsif (@$ra_ref) {
	my (@rra) = reverse(@$ra_ref);
	$idp = $rra[0] || 0;
    }
    # 3. no link to previous one found
    else {
	$idp = 0;
    }

    # 4. if $idp (link to previous message) found, 
    if (defined($idp) && $idp && $idp =~ /^\d+$/) {
	if ($idp != $current_key) {
	    $self->_db_set($db, 'prev_key', $current_key, $idp);
	}

	# We should not overwrite "id => next_key" assinged already.
	# We should preserve the first "id => next_key" value.
	# but we may overwride it if "id => id (itself)", wrong link.
	my $nid = $self->_db_get($db, 'next_key', $idp) || 0;
	unless ($nid && $nid != $idp && $current_key != $idp) {
	    $self->_db_set($db, 'next_key', $idp, $current_key);
	}
    }
    else {
	_PRINT_DEBUG("no prev thread link (key=$current_key)");
    }
}


=head1 SUMMARY

retrieve summary on thread et.al.

=head2 thread_summary($id).

return the following thread summary around the primary key $id.

    my $summary = {
	prev_id        => $prev_id,
	next_id        => $next_id,
	prev_thread_id => $prev_thread_id,
	next_thread_id => $next_thread_id,
    };

For example, supporse $id 5 and the thread link is (3 5 6):

    my $summary = {
	prev_id        => 4,
	next_id        => 6,
	prev_thread_id => 3,
	next_thread_id => 6,
    };

=cut


# Descriptions: return thread summary around key $id.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: HASH_REF
sub thread_summary
{
    my ($self, $id)    = @_;
    my $db             = $self->db_open();
    my $prev_id        = $id > 1 ? $id - 1 : undef;
    my $next_id        = $id + 1;
    my $prev_thread_id = $self->_db_get($db, 'prev_key', $id);
    my $next_thread_id = $self->_db_get($db, 'next_key', $id);

    # diagnostic
    if ($prev_thread_id) {
	undef $prev_thread_id if $prev_thread_id == $id;
    }
    if ($next_thread_id) {
	undef $next_thread_id if $next_thread_id == $id;
    }

    # XXX this routine returns information expected straight forwardly, so
    # XXX $summary may be invalid since $next*id not yet exists.
    # XXX we expect the program calling this method validates this info.
    # XXX For examle, check the existence of msg${next_id}.html before use.
    my $summary = {
	prev_id        => $prev_id,
	next_id        => $next_id,
	prev_thread_id => $prev_thread_id,
	next_thread_id => $next_thread_id,
    };

    return $summary;
}


=head1 UTILITY FUNCTIONS

All methods are module internal.

=cut


# Descriptions: convert space-separeted string to array
#    Arguments: STR($str)
# Side Effects: none
# Return Value: ARRAY_REF
sub _str_to_array_ref
{
    my ($str) = @_;

    return undef unless defined $str;

    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    my (@a) = split(/\s+/, $str);
    return \@a;
}


# Descriptions: add { key => value } into $table with converting
#               where value is "x y z ..." form, space separated string.
#    Arguments: HASH_REF($db) STR($dbname) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub _db_array_add
{
    my ($self, $db, $table, $key, $value) = @_;
    my $found = 0;
    my $ra    = _str_to_array_ref($db->{ $table }->{ $key }) || [];

    if (defined($key) && $key && defined($value) && $value) {
	# check duplication to ensure uniqueness within this array.
	for my $v (@$ra) {
	    $found = 1 if ($value =~ /^\d+$/o) && ($v == $value);
	    $found = 1 if ($value !~ /^\d+$/o) && ($v eq $value);
	}
	
	# add if the value is a new comer.
	unless ($found) {
	    my $v = $self->_db_get($db, $table, $key) || '';
	    $v .= $v ? " $value" : $value;
	    $self->_db_set($db, $table, $key, $v);
	}
    }
}


# Descriptions: head of array (space separeted string)
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub _head_of_list_str
{
    my ($buf) = @_;
    $buf =~ s/^\s*//;
    $buf =~ s/\s*$//;

    return (split(/\s+/, $buf))[0];
}


# Descriptions: decode mime string.
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub _decode_mime_string
{
    my ($self, $str, $out_code, $in_code) = @_;

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    return $encode->decode_mime_string($str, $out_code, $in_code);
}


# Descriptions: return formated time of message Date:
#    Arguments: OBJ($self) STR($type)
# Side Effects: none
# Return Value: STR
sub msg_time
{
    my ($self, $hdr, $type) = @_;

    if (defined($hdr) && $hdr->get('date')) {
	use Time::ParseDate;
	my $unixtime = parsedate( $hdr->get('date') );
	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime( $unixtime );

	if ($type eq 'yyyymm') {
	    return sprintf("%04d%02d", 1900 + $year, $mon + 1);
	}
	elsif ($type eq 'yyyy/mm') {
	    return sprintf("%04d/%02d", 1900 + $year, $mon + 1);
	}
    }
    else {
	warn("cannot pick up Date: field");
	return '';
    }
}


# Descriptions: clean up email address by Mail::Address.
#               return clean-up'ed address list.
#    Arguments: STR($addr)
# Side Effects: none
# Return Value: ARRAY_REF
sub _address_clean_up
{
    my ($self, $addr) = @_;
    my (@r);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($addr);

    my $i = 0;
  LIST:
    for my $addr (@addrs) {
	my $xaddr = $addr->address();
	next LIST unless $xaddr =~ /\@/;
	push(@r, $xaddr);
    }

    return \@r;
}


# Descriptions: extrace gecos field in $address
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: STR
sub _who_of_address
{
    my ($self, $address) = @_;
    my ($user);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($address);

    for my $addr (@addrs) {
	if (defined( $addr->phrase() )) {
	    my $phrase = $self->_decode_mime_string( $addr->phrase() );

	    if ($phrase) {
		return($phrase);
	    }
	}

	$user = $addr->user();
    }

    return( $user ? "$user\@xxx.xxx.xxx.xxx" : $address );
}


=head1 DATABASE PARAMETERS MANIPULATION

=cut


# Descriptions: open database
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: tied with $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub db_open
{
    my ($self, $args) = @_;

    return $self->{ _db } if defined $self->{ _db };

    my $db_type   = $self->get_db_module_name();
    my $db_dir    = $self->get_db_base_dir();
    my $file_mode = $self->{ _file_mode } || 0644;

    _PRINT_DEBUG("db_open( type = $db_type )");

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
 	for my $db (@table_list) {
	    my $file = "$db_dir/${db}";
	    my $str = qq{
		my \%$db = ();
		tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, $file_mode;
		\$self->{ _db }->{ '_$db' } = \\\%$db;
	    };
	    eval $str;
	    croak($@) if $@;
	}
    }
    else {
	croak("cannot use $db_type");
    }

    $self->{ _db } || undef;
}


# Descriptions: close database
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: untie $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub db_close
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type } || $self->{ _db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    _PRINT_DEBUG("db_close()");

    for my $db (@table_list) {
	my $str = qq{
	    my \$${db} = \$self->{ _db }->{ '_$db' };
	    untie \%\$${db};
	};
	eval $str;
	croak($@) if $@;
    }

    delete $self->{ _db } if defined $self->{ _db };
}


# Descriptions: set $key = $value of $table
#    Arguments: OBJ($self) STR($table) STR($key) STR($value)
# Side Effects: one
# Return Value: STR
sub set
{
    my ($self, $table, $key, $value) = @_;
    my $db = $self->db_open();

    $self->_db_set($db, $table, $key, $value);
}


# Descriptions: get $key of $table
#    Arguments: OBJ($self) STR($table) STR($key)
# Side Effects: one
# Return Value: STR
sub get
{
    my ($self, $table, $key) = @_;
    my $db = $self->db_open();

    return $self->_db_get($db, $table, $key);
}


# Descriptions: set $key = $value of $table
#    Arguments: OBJ($self) HASH_REF($db) STR($table) STR($key) STR($value)
# Side Effects: one
# Return Value: STR
sub _db_set
{
    my ($self, $db, $table, $key, $value) = @_;

    if (defined $value && $value) {
	_PRINT_DEBUG("db: table=$table { $key => $value }");
	$db->{ "_$table" }->{ $key } = $value;
    }
}


# Descriptions: get $key of $table
#    Arguments: OBJ($self) HASH_REF($db) STR($table) STR($key)
# Side Effects: one
# Return Value: STR
sub _db_get
{
    my ($self, $db, $table, $key) = @_;

    return( $db->{ "_$table" }->{ $key } || '' );
}


# Descriptions: set module name
#    Arguments: OBJ($self) STR($module)
# Side Effects: none
# Return Value: none
sub set_db_module_name
{
    my ($self, $module) = @_;

    $self->{ _db_module } = $module if defined $module;
}


# Descriptions: get module name
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_db_module_name
{
    my ($self) = @_;

    return( $self->{ _db_module } || undef );
}


# Descriptions: set db_base_dir
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: none
sub set_db_base_dir
{
    my ($self, $dir) = @_;

    $self->{ _db_base_dir } = $dir if defined $dir;
}


# Descriptions: get db_base_dir
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: none
sub get_db_base_dir
{
    my ($self) = @_;

    return( $self->{ _db_base_dir } || undef );
}


# Descriptions: set db_name
#    Arguments: OBJ($self) STR($name)
# Side Effects: none
# Return Value: none
sub set_db_name
{
    my ($self, $name) = @_;

    $self->{ _db_name } = $name if defined $name;
}


# Descriptions: get db_name
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_db_name
{
    my ($self) = @_;

    return( $self->{ _db_name } || undef );
}


# Descriptions: set the curent key
#    Arguments: OBJ($self) STR($name)
# Side Effects: none
# Return Value: none
sub set_key
{
    my ($self, $key) = @_;

    $self->{ _key } = $key if defined $key;
}


# Descriptions: get the curent key
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_key
{
    my ($self) = @_;

    return( $self->{ _key } || undef );
}



=head1 DEBUG

=cut

# Descriptions: debug
#    Arguments: STR($str)
# Side Effects: none
# Return Value: none
sub _PRINT_DEBUG
{
    my ($str) = @_;
    print STDERR "(debug) $str\n" if $debug;
}


# Descriptions: debug, print out hash
#    Arguments: HASH_REF($hash)
# Side Effects: none
# Return Value: none
sub _PRINT_DEBUG_DUMP_HASH
{
    my ($hash) = @_;
    my ($k,$v);

    if ($debug) {
	while (($k, $v) = each %$hash) {
	    printf STDERR "(debug) %-30s => %s\n", $k, $v;
	}
    }
}


#
# DEBUG
#
if ($0 eq __FILE__) {
    my $args = {
	db_module    => 'AnyDBM_File',
	db_base_dir  => '/tmp',
	db_name      => 'elena',  # mailing list identifier
	key          => 100,      # article sequence number
    };

    my $obj = new Mail::Message::DB $args;

    for my $file (@ARGV) {
	use File::Basename;
	my $id = basename($file);

	use Mail::Message;
	my $msg = Mail::Message->parse( { file => $file } );
	$obj->set_key($id);
	$obj->analyze($msg);
    }
}


=head1 TODO

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::DB first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
