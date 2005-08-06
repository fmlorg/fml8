#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DB.pm,v 1.20 2004/06/11 10:37:41 tmu Exp $
#

package Mail::Message::DB;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $NULL_VALUE
	    @table_list
	    @orig_header_fields @header_fields @article_header_fields
	    %old_db_to_udb_map
	    %udb_to_old_db_map
	    %header_field_type
	    $mime_decode_filter
	    );
use Carp;
use File::Spec;

my $version = q$FML: DB.pm,v 1.20 2004/06/11 10:37:41 tmu Exp $;
if ($version =~ /,v\s+([\d\.]+)\s+/) { $version = $1;}

# special value
$NULL_VALUE = '___NULL___';

# operation mode definitions.
my $debug             = 0;
my $is_keepalive      = 1;
my $is_demand_copying = 1;


#     map = { key => value } (normal order hash)
# inv_map = { value => key } (inverted hash)
#             or
#           { value => "key key2 key3 ..."  } (inverted hash)


%header_field_type = (
		      from        => 'ADDR',
		      date        => 'STR',
		      subject     => 'STR,MIME_DECODE',
		      to          => 'ADDR_LIST',
		      cc          => 'ADDR_LIST',
		      reply_to    => 'ADDR_LIST',
		      message_id  => 'ADDR,INVERSE_MAP',
		      references  => 'ADDR_LIST',

		      # article_*
		      article_subject => 'STR,MIME_DECODE',

		      # save info for filter system.
		      return_path => 'ADDR',
		      posted      => 'STR',
		      x_posted    => 'STR',
		      sender      => 'ADDR',
		      x_sender    => 'ADDR',
		      received    => 'STR',
		      x_received  => 'STR',
		  );

@table_list    = qw(who

		    inv_message_id

		    ref_key_list
		    next_key
		    prev_key

		    html_filename
		    html_filepath
		    subdir

		    month
		    inv_month

		    hint

		    thread_status
		    article_status
		    article_summary
		    );


# db name is same unless specified.
#                        OLD                   NEW
# OLD .htdb_${db_name}
# NEW       ${db_name}
%old_db_to_udb_map = qw(
			msgidref            inv_message_id
			idref               ref_key_list
			next_id             next_key
			prev_id             prev_key
			filename            html_filename
			filepath            html_filepath
			monthly_idlist      inv_month
			thread_list         undef
			subdir              subdir
			info                hint
			);

{
    my ($k, $v);

    # set up reverse map
    while (($k, $v) = each %old_db_to_udb_map) {
	$udb_to_old_db_map{ $v } = $k;
    }

    # set up filter
    while (($k, $v) = each %header_field_type) {
	if ($v =~ /MIME_DECODE/) {
	    $mime_decode_filter .= $mime_decode_filter ? "|$k" : $k;
	}
    }
}


=head1 NAME

Mail::Message::DB - DB interface

=head1 SYNOPSIS

  ... lock by something ...

  ... unlock by something ...

This module itself provides no lock function.
please use flock() built in perl or CPAN lock modules for it.

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

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
    set_db_module_class($me, $args->{ db_module } || 'AnyDBM_File');

    # db_base_dir = /var/spool/ml/@udb@/elena
    my $_db_base_dir = $args->{ db_base_dir } || croak("specify db_base_dir");
    set_db_base_dir($me, $_db_base_dir);

    # XXX in old ToHTML module (before UDB), db_base_dir == html_base_dir.
    if (defined $args->{ old_db_base_dir }) {
	$me->{ _old_db_base_dir } = $args->{ old_db_base_dir };
    }

    # XXX-TOOD: if db_name and key is not specified ? we should call croak()?
    # $db_name/$table uses $key as primary key.
    set_db_name($me, $args->{ db_name }) if defined $args->{ db_name };
    set_key($me,     $args->{ key })     if defined $args->{ key };

    # genearete @orig_header_fields based on @header_fields
    @header_fields = sort keys %header_field_type;
    for my $hdr (@header_fields) {
	push(@orig_header_fields,    "orig_$hdr");
	push(@article_header_fields, "article_$hdr");
    }

    return bless $me, $type;
}


# Descriptions: destructor.
#    Arguments: OBJ($self)
# Side Effects: close db
# Return Value: none
sub DESTROY
{
    my ($self) = @_;

    _PRINT_DEBUG("DB::DESTROY");
    if (defined $self->{ _db }) {
	$self->db_close();
    }
}


=head1 PARSE and ANALYZE

=head2 analyze()

update database on message header, thread relation information.

XXX-TODO: This routine should be moved to Mail::Message::Thread ?

=cut


# Descriptions: update database on message header, thread relation
#               et. al.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: update database
# Return Value: none
sub analyze
{
    my ($self, $msg) = @_;
    my $hdr    = $msg->whole_message_header;
    my $id     = $self->get_key();
    my $month  = $self->_get_time_from_header($hdr, 'yyyy/mm');
    my $subdir = $self->_get_time_from_header($hdr, 'yyyymm');

    #
    # XXX-TODO: analyze() must not be here ?
    #

    _PRINT_DEBUG("analyze start");

    my $db = $self->db_open();

    $self->_update_max_id($db, $id);
    $self->_save_header_info($db, $id, $hdr);

    $self->_db_set($db, 'id',     $id, $id);       # 100 => 100
    $self->_db_set($db, 'month',  $id, $month);    # 100 => 2003/06
    $self->_db_set($db, 'subdir', $id, $subdir);   # 100 => 200306

    # HASH { YYYY/MM => (id1 id2 id3 ..) }
    $self->_db_array_add($db, 'inv_month', $month, $id);

    $self->_analyze_thread($db, $id, $msg, $hdr);

    unless ($is_keepalive) {
	$self->db_close();
    }

    _PRINT_DEBUG("analyze end");
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


# Descriptions: extract and format if needed header information
#               and save them into db.
#    Arguments: OBJ($self) HASH_REF($db) NUM($id) OBJ($hdr)
# Side Effects: update hint in $db
# Return Value: none
sub _save_header_info
{
    my ($self, $db, $id, $hdr) = @_;
    my ($fld, $val, @val);

    # @header_fields may be overwritten. For example,
    #   key = message_id
    #   fld = message-id
    #   val = xxx@yyy.domain
    for my $key (@header_fields) {
	$fld =  $key;
	$fld =~ s/_/-/g;
	$fld =~ tr/A-Z/a-z/;
	@val =  $hdr->get($fld);
	$val =  join("", @val);
	$val =~ s/\s*$//;

	$self->_db_set($db, "orig_$key", $id, $val);

	# ADDR type: save the first element of address list.
	if ($header_field_type{ $key } =~ /ADDR/o) { # ADDR or ADDR_LIST
	    my $ra_val = $self->_address_clean_up( $val );
	    $val = $ra_val->[0] || '';
	    $self->_db_set($db, $key, $id, $val);
	}
	elsif ($header_field_type{ $key } =~ /MIME_DECODE/o) {
	    $val = $self->_decode_mime_string($val);
	    $self->_db_set($db, $key, $id, $val);
	}
	else {
	    $self->_db_set($db, $key, $id, $val);
	}

	# reverse map { $key => $id }
	if ($header_field_type{ $key } =~ /INVERSE_MAP/o) {
	    $self->_db_set($db, "inv_$key", $val, $id);
	}
    }

    # what is called, "Gecos field"
    my $who = $self->_who_of_address( $hdr->get('from') );
    $self->_db_set($db, 'who',      $id, $who);      # Rudolf Shumidt
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
#    Arguments: OBJ($self) HASH_REF($db) NUM($id) OBJ($msg) OBJ($hdr)
# Side Effects: update db
# Return Value: none
sub _analyze_thread
{
    my ($self, $db, $id, $msg, $hdr) = @_;
    my $current_key  = $self->get_key();
    my $ra_ref       = $self->_address_clean_up($hdr->get('references'));
    my $ra_inreplyto = $self->_address_clean_up($hdr->get('in-reply-to'));
    my $in_reply_to  = $ra_inreplyto->[0] || '';
    my %uniq         = ();
    my $count        = 0;

    # ref_key_list = ( id(myself), id(in-reply-to), id's(references) );
    $self->_db_array_add($db, 'ref_key_list', $id, $id);

    # I. update ref_key_list database.
    # search order is artibrary (see comments above).
  MSGID:
    for my $mid (@$ra_inreplyto, @$ra_ref) {
	next MSGID unless defined $mid;

	# ensure uniqueness
	next MSGID if $uniq{$mid};
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

    # I. (2)
    # XXX-TODO: update ref_key_list based on subject.

    # II. ok. go to speculate prev/next links
    #   1. if In-Reply-To: is found, use it as "pointer to previous id".
    my $idp = 0;
    if (defined $in_reply_to && $in_reply_to ne '') {
	# XXX this "idp" is previous message candidate.
	# XXX idp (id pointer) = id1 by _head_of_list_str( (id1 id2 id3 ...)
	$idp = $self->_db_get($db, 'inv_message_id', $in_reply_to);
    }
    # 2. if not found, try to use References: "in reverse order". So
    #    the last referenced message_id is the previous message candidate.
    elsif (@$ra_ref) {
	my (@rra) = reverse(@$ra_ref);
	$idp = $rra[0] || 0;
    }
    # 3. no link to the previous message is found.
    else {
	$idp = 0;
    }

    # III. if $idp (link to the previous message) found,
    #      update prev_key (itself to preious) and 
    #      next_key (previous to itself) database.
    if (defined($idp) && $idp && $idp =~ /^\d+$/o) {
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

=head2 get_thread_summary($id).

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
sub get_thread_summary
{
    my ($self, $id)    = @_;
    my ($fn_prev_id, $fn_next_id, $fn_prev_thread_id,
	$fn_next_thread_id, $fp_prev_id, $fp_next_id,
	$fp_prev_thread_id, $fp_next_thread_id);
    my $db             = $self->db_open();
    my $prev_id        = $id > 1 ? $id - 1 : undef;
    my $next_id        = $id + 1;
    my $prev_thread_id = $self->_db_get($db, 'prev_key', $id) || $prev_id;
    my $next_thread_id = $self->_db_get($db, 'next_key', $id) || $next_id;

    # diagnostic
    if (defined $prev_thread_id && $prev_thread_id) {
	undef $prev_thread_id if $prev_thread_id == $id;
    }
    if (defined $next_thread_id && $next_thread_id) {
	undef $next_thread_id if $next_thread_id == $id;
    }

    # file name (fn_*) and file path (fp_*)
    if (defined $prev_id) {
	$fn_prev_id = $self->_db_get($db, 'html_filename', $prev_id);
	$fp_prev_id = $self->_db_get($db, 'html_filepath', $prev_id);
    }

    if (defined $next_id) {
	$fn_next_id = $self->_db_get($db, 'html_filename', $next_id);
	$fp_next_id = $self->_db_get($db, 'html_filepath', $next_id);

	unless (-f $fp_next_id) {
	    undef $next_id;
	    $fp_next_id = '';
	    $fn_next_id = '';
	}
    }

    if (defined $prev_thread_id) {
	$fn_prev_thread_id =
	    $self->_db_get($db, 'html_filename', $prev_thread_id);
	$fp_prev_thread_id =
	    $self->_db_get($db, 'html_filepath', $prev_thread_id);
    }

    if (defined $next_thread_id) {
	$fn_next_thread_id =
	    $self->_db_get($db, 'html_filename', $next_thread_id);
	$fp_next_thread_id =
	    $self->_db_get($db, 'html_filepath', $next_thread_id);

	unless(-f $fp_next_thread_id) {
	    undef $next_thread_id;
	    $fn_next_thread_id = '';
	    $fp_next_thread_id = '';
	}
    }

    # XXX this routine returns information expected straight forwardly, so
    # XXX $summary may be invalid since $next*id not yet exists.
    # XXX we expect the program calling this method validates this info.
    # XXX For examle, check the existence of msg${next_id}.html before use.
    my $summary = {
	id                           => $id,

	prev_id                      => $prev_id,
	next_id                      => $next_id,
	prev_thread_id               => $prev_thread_id,
	next_thread_id               => $next_thread_id,

	# file relative path info
	html_filename_prev_id        => $fn_prev_id,
	html_filename_next_id        => $fn_next_id,
	html_filename_prev_thread_id => $fn_prev_thread_id,
	html_filename_next_thread_id => $fn_next_thread_id,

	# file (full)path info
	html_filepath_prev_id        => $fp_prev_id,
	html_filepath_next_id        => $fp_next_id,
	html_filepath_prev_thread_id => $fp_prev_thread_id,
	html_filepath_next_thread_id => $fp_next_thread_id,
    };

    return $summary;
}


# Descriptions: return thread summary around key $id.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: HASH_REF
sub get_tohtml_thread_summary
{
    my ($self, $id)    = @_;
    my $db             = $self->db_open();
    my $summary        = $self->get_thread_summary($id);
    my $prev_id        = $summary->{ prev_id };
    my $next_id        = $summary->{ next_id };
    my $prev_thread_id = $summary->{ prev_thread_id };
    my $next_thread_id = $summary->{ next_thread_id };

    #
    # XXX-TODO: we should get back this method to Mail::Message::ToHTML ?
    # XXX-TODO: or Mail::Message::Thread ? but looks difficult ...
    #

    unless (defined $next_thread_id || $next_thread_id) {
	my $xid = $self->_search_default_next_thread_id($db, $id);
	if ($xid && ($xid != $id)) {
	    $next_thread_id = $xid;
	    _PRINT_DEBUG("override next_thread_id = $next_thread_id");
	}
    }

    my $subject = {};
    if (defined $prev_id && $prev_id) {
	$subject->{ prev_id } = $self->_db_get($db, 'subject', $prev_id);
    }
    if (defined $next_id && $next_id) {
	$subject->{ next_id } = $self->_db_get($db, 'subject', $next_id);
    }
    if (defined $prev_thread_id && $prev_thread_id) {
	$subject->{ prev_thread_id } =
	    $self->_db_get($db, 'subject', $prev_thread_id);
    }
    if (defined $next_thread_id && $next_thread_id) {
	$subject->{ next_thread_id } =
	    $self->_db_get($db, 'subject', $next_thread_id);
    }

    # filename (relative file path)
    my $fn_prev_id        = $summary->{ html_filename_prev_id };
    my $fn_next_id        = $summary->{ html_filename_next_id };
    my $fn_prev_thread_id = $summary->{ html_filename_prev_thread_id };
    my $fn_next_thread_id = $summary->{ html_filename_next_thread_id };
    my $path              = $self->_db_get($db, 'html_filepath', $id);
    my $tohtml_thread_summary = {
	# myself
	id                    => $id,
	filepath              => $path,

	# other links
	prev_id               => $prev_id,
	next_id               => $next_id,
	prev_thread_id        => $prev_thread_id,
	next_thread_id        => $next_thread_id,

	link_prev_id          => $fn_prev_id,
	link_next_id          => $fn_next_id,
	link_prev_thread_id   => $fn_prev_thread_id,
	link_next_thread_id   => $fn_next_thread_id,

	subject               => $subject,
    };

    _PRINT_DEBUG("$id link relation");
    _PRINT_DEBUG_DUMP_HASH( $tohtml_thread_summary );
    return $tohtml_thread_summary;
}


# Descriptions: speculate head of the next thread list.
#    Arguments: OBJ($self) HASH_REF($db) STR($id)
# Side Effects: none
# Return Value: STR
sub _search_default_next_thread_id
{
    my ($self, $db, $id) = @_;
    my $list      = $self->get_as_array_ref('ref_key_list', $id);
    my (@ra, @c0) = ();

    # 1. @ra (id list for $id thread relations)
    @ra = reverse @$list if defined $list;

    # 2. @c0 (gamble :-)
    for my $_id (1 .. 10) { push(@c0, $id + $_id);}

    # prepare thread list to search
    # 1. thread includes $id
    # 2. thread(s) begining at each id in thread 1.
    # 3. last resort: thread includes ($id+1),
    #                 thread includes ($id+2), ...
    for my $xid ($id, @ra, @c0) {
	my $default = $self->__search_default_next_id_in_thread($db, $xid);
	return $default if defined $default;
    }

    return 0;
}


# Descriptions: speculate the next id of $id.
#    Arguments: OBJ($self) HASH_REF($db) STR($id)
# Side Effects: none
# Return Value: STR
sub __search_default_next_id_in_thread
{
    my ($self, $db, $id) = @_;
    my $list = [];
    my $prev = 0;

    _PRINT_DEBUG("__search_default_next_id_in_thread($id)");

    # thread_list HASH { $id => $id1 $id2 $id3 ... }
    $list = $self->get_as_array_ref('ref_key_list', $id);
    if (@$list) {
	return undef unless $#$list > 1;

	# thread_list HASH { $id => $id1 $id2 $id3 ... $id $prev ... }
	#                           <---- search ---
      ID:
	for my $xid (reverse @$list) {
	    last ID if $xid == $id;
	    $prev = $xid;
	}
    }

    # found
    # XXX we use $prev in reverse order, so this $prev means "next"
    if ($prev > 0) {
	_PRINT_DEBUG("default thread: $id => $prev (@$list)");
	return $prev;
    }
    else {
	_PRINT_DEBUG("default thread: $id => none (@$list)");
	return undef;
    }

    return undef;
}


=head2 get_thread_data($thread_args)

return thread data around the specified key.  The data is a hash of
array recursively explorered in the thread link relation.

    hash = {
	id => [ id1 id2 id2a id2b id3 ... ],
    };

=cut


# Descriptions: return thread data around the specified key.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: HASH_REF
sub get_thread_data
{
    my ($self, $thread_args) = @_;
    my ($n, $next_key, $list, $id, $found);
    my $result = {};
    my $cache  = {};

    # range
    use Mail::Message::MH;
    my $mh      = new Mail::Message::MH;
    my $range   = $thread_args->{ range } || 'last:10';
    my $head_id = $thread_args->{ last_id };
    my $id_list = $mh->expand($range, 1, $head_id);

  KEY:
    for my $id (@$id_list) {
	next KEY if defined $cache->{ $id } && $cache->{ $id };

	# get id array for the thread with the head_id = $id.
	$list = [];
	$self->_get_keys_in_this_thread($id, $list, $cache);
	$result->{ $id } = $list || [];
    }

    return $result;
}

my $recursive = 0;

# Descriptions: return id list for thread with the $head_id at the top.
#    Arguments: OBJ($self) NUM($head_id) ARRAY_REF($list) HASH_REF($uniq)
# Side Effects: none
# Return Value: ARRAY(NUM, NUM, ARRAY_REF)
sub _get_keys_in_this_thread
{
    my ($self, $head_id, $list, $uniq) = @_;

    $recursive++;

    my $idlist = $self->get_as_array_ref('ref_key_list', $head_id);
    if (@$idlist) {
	print STDERR "($recursive) head=$head_id => @$idlist\n" if $debug;

      ID:
        for my $id (@$idlist) {
            next ID if $uniq->{ $id };
            $uniq->{ $id } = 1;

	    print STDERR "($recursive) check id=$id\n" if $debug;

            # oops, we should ignore head of the thread ( myself ;-)
	    if (($id != $head_id) && $self->_has_link($id)) {
		print STDERR "call again (call from id=$id)\n" if $debug;
                push(@$list, $id);
		$self->_get_keys_in_this_thread($id, $list, $uniq);
            }
            else {
                print STDERR "push(@$list, $id);\n" if $debug;
                push(@$list, $id);
            }
        }
    }
    else {
	print STDERR "($recursive) head=$head_id => no list\n" if $debug;
	$uniq->{ $head_id } = 1;
	push(@$list, $head_id);
    }

    $recursive--;
}


# Descriptions: check whether $id has next or previous link.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: 1 or 0
sub _has_link
{
    my ($self, $id) = @_;

    if ($self->get('next_key', $id) || $self->get('prev_key', $id)) {
        return 1;
    }
    else {
        return 0;
    }
}


=head1 UTILITY FUNCTIONS

All methods are module internal.

=cut


# Descriptions: convert space-separeted string to array.
#    Arguments: STR($str)
# Side Effects: none
# Return Value: ARRAY_REF
sub _str_to_array_ref
{
    my ($str) = @_;

    return [] unless defined $str;

    $str =~ s/^\s*//o;
    $str =~ s/\s*$//o;
    my (@a) = split(/\s+/, $str);
    return \@a;
}


# Descriptions: add { key => value } into $table with converting
#               where value is "x y z ..." form, space separated string.
#    Arguments: OBJ($self) HASH_REF($db) STR($table) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub _db_array_add
{
    my ($self, $db, $table, $key, $value) = @_;
    my $found = 0;
    my $ra    = $self->get_as_array_ref($table, $key) || [];

    _PRINT_DEBUG("ARRAY: table=$table key=$key, add '$value' into (@$ra)");

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
    else {
	_PRINT_DEBUG("ARRAY: fail to add");
    }
}


# Descriptions: head of array (space separeted string).
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub _head_of_list_str
{
    my ($buf) = @_;
    $buf =~ s/^\s*//o;
    $buf =~ s/\s*$//o;

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


# Descriptions: clean up email address by Mail::Address.
#               return clean-up'ed address list.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: ARRAY_REF
sub _address_clean_up
{
    my ($self, $addr) = @_;
    my (@r);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($addr);

    my $i = 0;
  ADDR:
    for my $addr (@addrs) {
	my $xaddr = $addr->address();
	next ADDR unless $xaddr =~ /\@/o;
	push(@r, $xaddr);
    }

    return \@r;
}


# Descriptions: extrace gecos field in $address.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: STR
sub _who_of_address
{
    my ($self, $address) = @_;

    use Mail::Message::Utils;
    return Mail::Message::Utils::from_to_name($address);
}


# Descriptions: return formated time of message Date:
#    Arguments: OBJ($self) OBJ($hdr) STR($type)
# Side Effects: none
# Return Value: STR
sub _get_time_from_header
{
    my ($self, $hdr, $type) = @_;

    use Mail::Message::Utils;
    return Mail::Message::Utils::get_time_from_header($hdr, $type);
}


=head1 DATABASE PARAMETERS MANIPULATION

=cut


# Descriptions: open database.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: tied with $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub db_open
{
    my ($self, $args) = @_;
    my (@table)       = ();

    if (defined $args->{ table }) {
	my $table = $args->{ table };

	if ($self->{ _db_opened }->{ "_$table" }) {
	    return;
	}
	else {
	    @table = ($table);
	}
    }
    else {
	return $self->{ _db } if defined $self->{ _db };

	# @table = (@orig_header_fields,
	#           @header_fields,
	#           @article_header_fields,
	#           @table_list);
	@table = (@table_list);
    }
    _PRINT_DEBUG("db_open(on demand): @table");

    my $db_type   = $self->get_db_module_class();
    my $db_dir    = $self->get_db_base_dir();
    my $file_mode = $self->{ _file_mode } || 0644;

    _PRINT_DEBUG("db_open( type = $db_type )");

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
	my ($file, $str);
 	for my $db (@table) {
	    $file = File::Spec->catfile($db_dir, $db);
	    $str  = qq{
		my \%$db = ();
		tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, $file_mode;
		\$self->{ _db }->{ '_$db' } = \\\%$db;
		\$self->{ _db_opened }->{ '_$db' } = 1;
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


# Descriptions: close database.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: untie $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub db_close
{
    my ($self, $args) = @_;
    my (@table)       = ();

    if (defined $args->{ table }) {
	@table = ($args->{ table });
    }
    else {
	@table = (@orig_header_fields, @header_fields, @article_header_fields,
		  @table_list);
    }
    _PRINT_DEBUG("db_close(on demand): @table");

    my $db_type = $args->{ db_type } || $self->{ _db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    _PRINT_DEBUG("db_close()");

    for my $db (@table) {
	my $str = qq{
	    my \$${db} = \$self->{ _db }->{ '_$db' };
	    untie \%\$${db};
	    \$self->{ _db_opened }->{ '_$db' } = 0;
	};
	eval $str;
	croak($@) if $@;
    }

    delete $self->{ _db } if defined $self->{ _db };
}


# Descriptions: set $key = $value of $table.
#    Arguments: OBJ($self) STR($table) STR($key) STR($value)
# Side Effects: one
# Return Value: STR
sub set
{
    my ($self, $table, $key, $value) = @_;
    my $db = $self->db_open();

    _PRINT_DEBUG("_db_set: table=$table { $key => $value }");

    $self->_db_set($db, $table, $key, $value);
}


# Descriptions: get $key of $table.
#    Arguments: OBJ($self) STR($table) STR($key)
# Side Effects: one
# Return Value: STR
sub get
{
    my ($self, $table, $key) = @_;
    my $db = $self->db_open();

    return $self->_db_get($db, $table, $key);
}


# Descriptions: get $key (list) of $table as array (ARRAY_REF).
#    Arguments: OBJ($self) STR($table) STR($key)
# Side Effects: one
# Return Value: ARRAY_REF
sub get_as_array_ref
{
    my ($self, $table, $key) = @_;

    _PRINT_DEBUG("get_as_array_ref($table, $key)");

    my $db  = $self->db_open();
    my $val = $self->_db_get($db, $table, $key);
    $val =~ s/^\s*//o;
    $val =~ s/\s*$//o;

    _PRINT_DEBUG("get_as_array_ref($table, $key, '$val')");

    my (@x) = split(/\s+/, $val);

    _PRINT_DEBUG("return(@x)");
    return( \@x );
}


# Descriptions: set $key = $value of $table.
#    Arguments: OBJ($self) HASH_REF($db) STR($table) STR($key) STR($value)
# Side Effects: one
# Return Value: STR
sub _db_set
{
    my ($self, $db, $table, $key, $value) = @_;

    if (defined $value && $value && defined $key && $key) {
	unless ($self->{ _db_opened }->{ "_$table" }) {
	    $self->db_open( { table => $table } );
	}

	if ($table =~ /^($mime_decode_filter)$/) {
	    if ($value =~ /ISO.*\?[BQ]/io) {
		$value = $self->_decode_mime_string($value);
	    }
	}

	_PRINT_DEBUG("_db_set: table=$table { $key => $value }");
	$db->{ "_$table" }->{ $key } = $value;
    }
}


# Descriptions: get $key of $table.
#    Arguments: OBJ($self) HASH_REF($db) STR($table) STR($key)
# Side Effects: one
# Return Value: STR
sub _db_get
{
    my ($self, $db, $table, $key) = @_;
    my $v = $db->{ "_$table" }->{ $key } || '';

    if ($v eq $NULL_VALUE) {
	return '';
    }

    unless ($v) {
	if ($self->{ _db_opened }->{ "_$table" }) {
	    $self->db_open( { table => $table } );
	}

	if ($is_demand_copying) {
	    _PRINT_DEBUG("_old_db_copyin(\$db, $table, $key)");
	    $self->_old_db_copyin($db, $table, $key);
	}
	$v = $db->{ "_$table" }->{ $key } || '';

	unless ($v) {
	    $db->{ "_$table" }->{ $key } = $NULL_VALUE;
	}
    }

    if ($v eq $NULL_VALUE) {
	return '';
    }

    return $v;
}


# Descriptions: set module class.
#    Arguments: OBJ($self) STR($module)
# Side Effects: none
# Return Value: none
sub set_db_module_class
{
    my ($self, $module) = @_;

    $self->{ _db_module } = $module if defined $module;
}


# Descriptions: get module name.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_db_module_class
{
    my ($self) = @_;

    return( $self->{ _db_module } || undef );
}


# Descriptions: set db_base_dir.
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: none
sub set_db_base_dir
{
    my ($self, $dir) = @_;

    $self->{ _db_base_dir } = $dir if defined $dir;
}


# Descriptions: get db_base_dir.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_db_base_dir
{
    my ($self) = @_;

    return( $self->{ _db_base_dir } || undef );
}


# Descriptions: set db_name.
#    Arguments: OBJ($self) STR($name)
# Side Effects: none
# Return Value: none
sub set_db_name
{
    my ($self, $name) = @_;

    $self->{ _db_name } = $name if defined $name;
}


# Descriptions: get db_name.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_db_name
{
    my ($self) = @_;

    return( $self->{ _db_name } || undef );
}


# Descriptions: set the curent key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: none
sub set_key
{
    my ($self, $key) = @_;

    $self->{ _key } = $key if defined $key;
}


# Descriptions: get the curent key.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_key
{
    my ($self) = @_;

    return( $self->{ _key } || undef );
}


=head1 HANDLE TABLE

=cut


# Descriptions: get table as hash ref to handle it as HASH_REF.
#    Arguments: OBJ($self) STR($table)
# Side Effects: none
# Return Value: HASH_REF
sub get_table_as_hash_ref
{
    my ($self, $table) = @_;
    my $db = $self->db_open();

    return( $db->{ "_$table" } || {} );
}


=head1 HANDLE OLD DB by DEMAND COPYING

=cut


# Descriptions: copy a part of $table from old db.
#    Arguments: OBJ($self) HASH_REF($db) STR($table) STR($key)
# Side Effects: one
# Return Value: STR
sub _old_db_copyin
{
    my ($self, $db, $table, $key) = @_;
    my (%old_db);
    my $db_type    = $self->get_db_module_class();
    my $db_dir     = $self->get_db_base_dir();
    my $file_mode  = $self->{ _file_mode } || 0644;
    my $old_db_dir = $self->{ _old_db_base_dir };
    my $_table     = $udb_to_old_db_map{ $table } || $table;
    my $file       = File::Spec->catfile($old_db_dir, ".htdb_${_table}");
    my $file_db    = File::Spec->catfile($old_db_dir, ".htdb_${_table}.db");
    my $file_pag   = File::Spec->catfile($old_db_dir, ".htdb_${_table}.pag");
    my $cur_key    = $self->get_key() || 0;

    if (-f $file_db || -f $file_pag) {
	eval qq{ use $db_type; use Fcntl;};
	unless ($@) {
	    eval q{
		tie %old_db, $db_type, $file, O_RDWR|O_CREAT, $file_mode;
	    };
	    croak($@) if $@;
	}
	else {
	    croak("cannot use $db_type");
	}

	if ($key =~ /^\d+$/o) {
	    my $value = $old_db{ $key } || $NULL_VALUE;
	    $self->_db_set($db, $table, $key, $value);

	    my $start = $key - 25 > 0 ? $key - 25 : 1;
	    my $end   = $key + 25;
	    _PRINT_DEBUG("copy ($start .. $end) into $table from $file");

	  COPYIN:
	    for my $i ($start .. $end) {
		last COPYIN if $cur_key == $i || $cur_key < $i;

		# we should not overwrite myself in coping.
		if ($cur_key && $cur_key != $i) {
		    $self->_db_set($db, $table, $i, $old_db{$i}||$NULL_VALUE);
		}
	    }
	}
	# we may need to copy all contents
	else {
	    my $value = $old_db{ $key } || $NULL_VALUE;
	    $self->_db_set($db, $table, $key, $value);

	    _PRINT_DEBUG("all copy into $table from $file");

	    my ($k, $v);
	    while (($k, $v) = each %old_db) {
		$self->_db_set($db, $table, $k, $v || $NULL_VALUE);
	    }
	}

	eval q{ untie %old_db; };
    }
    else {
	_PRINT_DEBUG("$file not found");
    }
}


=head1 DEBUG

=cut

# Descriptions: print if debug mode.
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

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::DB first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
