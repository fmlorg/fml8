#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Lite.pm,v 1.29 2001/10/29 15:07:03 fukachan Exp $
#

package Mail::HTML::Lite;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;
my $URL   = "<A HREF=\"http://www.fml.org/software/\">Mail::HTML::Lite</A>";

my $version = q$FML: Lite.pm,v 1.29 2001/10/29 15:07:03 fukachan Exp $;
if ($version =~ /,v\s+([\d\.]+)\s+/) {
    $version = "$URL $1";
}

=head1 NAME

Mail::HTML::Lite - mail to html converter

=head1 SYNOPSIS

  ... lock by something ... 

  use Mail::HTML::Lite;
  my $obj = new Mail::HTML::Lite { 
      charset   => "euc-jp",
      directory => "/var/www/htdocs/ml/elena",
  };

  $obj->htmlfy_rfc822_message({
      id  => 1,
      src => "/var/spool/ml/elena/spool/1",
  });

  ... unlock by something ... 

This module itself provides no lock function.
please use flock() built in perl or CPAN lock modules for it. 

=head1 DESCRIPTION

=head2 Message structure created as HTML

HTML-fied message has following structure.
something() below is method name.

                               for example 
    -------------------------------------------------------------------
    html_begin()               <HTML><HEAD> ... </HEAD><BODY> 
    mhl_preamble()             <!-- comment used by this module -->
    mhl_separator()            <HR>

      message header
           From:    ...
           Subject: ...

    mhl_separator()            <HR>

      message body

    mhl_separator()            <HR>
    mhl_footer()               <!-- comment used by this module -->
    html_end()                 </BODY></HTML> 

=head1 METHODS

=head2 C<new($args)>

    $args = {
	directory => $directory,
    };

C<$directory> is top level directory where html-fied articles are
stored.

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    $me->{ _html_base_directory } = $args->{ directory };
    $me->{ _charset }        = $args->{ charset } || 'us-ascii';
    $me->{ _is_attachment }  = defined($args->{ attachment }) ? 1 : 0;
    $me->{ _db_type }        = $args->{ db_type };
    $me->{ _args }           = $args;
    $me->{ _num_attachment } = 0; # for child process

    return bless $me, $type;
}


=head2 C<htmlfy_rfc822_message($args)>

convert mail to html.

    $args = {
	id   => $id,
	path => $path,
    };

where C<$path> is file path.

=cut


# Descriptions: 
#    Arguments: $self $args
#               $args = { id => $id, path => $path };
#                  $id    identifier (e.g. "1" (article id))
#                  $src_path  file path  (e.g. "/some/where/1");
# Side Effects: 
# Return Value: none
sub htmlfy_rfc822_message
{
    my ($self, $args) = @_;

    # initialize basic information
    my ($id, $src, $dst) = $self->_init_htmlfy_rfc822_message($args);

    # already exists
    if (-f $dst) {
	$self->{ _ignore_list }->{ $id } = 1; # ignore flag
	warn("html file for $id already exists") if $debug;
	return undef;
    }

    use Mail::Message;
    use FileHandle;
    my $rh   = new FileHandle $src;
    my $msg  = Mail::Message->parse( { fd => $rh } );
    my $hdr  = $msg->rfc822_message_header;
    my $body = $msg->rfc822_message_body;

    # save information for index.html and thread.html
    $self->cache_message_info($msg, { id => $id, 
				      src => $src, 
				      dst => $dst,
				  } );

    # prepare output channel
    my $wh = $self->_set_output_channel( { dst => $dst } );
    unless (defined $wh) {
	croak("cannot open output file\n");
    }

    # before main message
    $self->html_begin($wh, { message => $msg });
    $self->mhl_preamble($wh);

    # analyze $msg (message chain)
    my ($m, $type, $attach);
  CHAIN:
    for ($m = $msg; defined($m) ; $m = $m->{ 'next' }) {
	$type = $m->get_data_type;

	last CHAIN if $type eq 'multipart.close-delimiter'; # last of multipart
	next CHAIN if $type =~ /^multipart/;

	unless ($type =~ /^\w+\/[-\w\d\.]+$/) { 
	    warn("invalid type={$type}");
	    next CHAIN;
	}

	# header (Mail::Message object uses this special type)
	if ($type eq 'text/rfc822-headers') {
	    $self->mhl_separator($wh);
	    my $charset = $self->{ _charset };
	    my $header  = $self->_format_safe_header($msg);
	    _print_raw_str($wh, $header, $charset);
	    $self->mhl_separator($wh);
	}
	# message/rfc822 case
	elsif ($type eq 'message/rfc822') {
	    $attach++;

	    my $tmpf = $self->_create_temporary_file_in_raw_mode($m);
	    if (defined $tmpf && -f $tmpf) {
		# write attachement into a separete file
		my $outf = _gen_attachment_filename($dst, $attach, 'html');
		my $args = $self->{ _args };
		$args->{ attachment } = 1; # clarify not top level content.
		my $text = new Mail::HTML::Lite $args;
		$text->htmlfy_rfc822_message({
		    parent_id => $id,
		    src => $tmpf,
		    dst => $outf,
		});

		# show inline href appeared in parent html.
		$self->_print_inline_object_link({
		    fh   => $wh,     # file descriptor
		    type => $type,   # XXX derived from input message
		    num  => $attach, # number
		    file => $outf,   # temporary file name
		});

		unlink $tmpf;
	    }
	}
	# text/plain case.
	elsif ($type eq 'text/plain') {
	    $self->_text_safe_print({ 
		fh   => $wh,
		data => $m->data_in_body_part(),
	    });
	}
	# create a separete file for attachment
	else {
	    $attach++;

	    # write attachement into a separete file
	    my $outf    = _gen_attachment_filename($dst, $attach, $type);
	    my $enc     = $m->get_encoding_mechanism;
	    my $msginfo = { message => $m };

	    # e.g. text/xxx case (e.g. text/html case) 
	    if ($type =~ /^text/) {
		my $tmpf = $self->_create_temporary_filename();
		$msginfo->{ file } = $tmpf;

		# once create temporary file
		_PRINT_DEBUG("attachment: type=$type attach=$attach enc=$enc");
		if ($enc) {
		    $self->_binary_print($msginfo);   # XXX raw mode
		}
		else {
		    $self->_text_raw_print($msginfo); # XXX raw mode
		}

		# disable html tag in file which is saved in raw mode.
		if (-f $tmpf) {
		    $msginfo->{ description } = "(HTML TAGs are disabled)";
		    _disable_html_tag_in_file($tmpf, $outf);
		    unlink $tmpf;
		}
	    }
	    # e.g. image/gif not text/* nor message/*
	    else {
		$msginfo->{ file } = $outf;
		$self->_binary_print($msginfo);
	    }

	    # show inline href appeared in parent html.
	    $self->_print_inline_object_link({
		inline => 1,
		fh     => $wh,
		type   => $type,
		num    => $attach,
		file   => $outf,
		info   => $msginfo,
	    });
	}
    }

    # after message
    $self->mhl_separator($wh);
    $self->mhl_footer($wh);
    $self->html_end($wh);
}


sub _disable_html_tag_in_file
{
    my ($inf, $outf) = @_;

    use FileHandle;
    my $rh = new FileHandle $inf;
    my $wh = new FileHandle "> $outf";
    if (defined $rh) {
	my $buf = '';
	while (<$rh>) { $buf .= $_;}
	_print_safe_buf($wh, $buf);
	$wh->close;
	$rh->close;
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub message_filename
{
    my ($self, $id) = @_;

    if (defined($id) && ($id > 0)) {
	return "msg${id}.html";
    }
    else {
	return undef;
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub message_filepath
{
    my ($self, $id) = @_;
    my $html_base_dir = $self->{ _html_base_directory };

    if (defined($id) && ($id > 0)) {
	return "$html_base_dir/msg$id.html";
    }
    else {
	return undef;
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _init_htmlfy_rfc822_message
{
    my ($self, $args) = @_;
    my ($id, $src, $dst);

    if (defined $args->{ src }) {
	$src = $args->{ src };
    }
    else {
	croak("htmlfy_rfc822_message: \$src is mandatory\n");
    }

    if (defined $args->{ id }) {
	my $html_base_dir = $self->{ _html_base_directory };
	$id  = $args->{ id };
	$dst = $self->message_filepath($id);
    }
    elsif (defined $args->{ parent_id }) {
	$self->{ _num_attachment }++;
	$id  = $args->{ parent_id } .'.'. $self->{ _num_attachment };
	$dst = $args->{ dst };
    }
    elsif (defined $args->{ dst }) {
	$id  = time.".".$$;
	$dst = $args->{ dst };
    }
    else {
	croak("htmlfy_rfc822_message: specify \$id or \$dst\n");
    }

    $self->{ _id } = $id;

    return ($id, $src, $dst);
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub html_begin
{
    my ($self, $wh, $args) = @_;
    my ($msg, $hdr, $title);

    if (defined $args->{ title }) {
	$title = $args->{ title };
    }
    elsif (defined $args->{ message }) {
	$msg   = $args->{ message };
	$hdr   = $msg->rfc822_message_header;
	$title = $self->_decode_mime_string( $hdr->get('subject') );
    }

    print $wh 
	q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">};
    print $wh "\n";
    print $wh "<HTML>\n";
    print $wh "<HEAD>\n";

    if (defined $self->{ _charset }) {
	my $charset = $self->{ _charset };
	print $wh "<META http-equiv=\"Content-Type\"\n";
	print $wh "   content=\"text/html; charset=${charset}\">\n";
    }

    if (defined $self->{ _stylsheet }) {
	my $css = $self->{ _stylsheet };
	print $wh "<LINK rel=\"stylesheet\"\n";
	print $wh "   type=\"text/css\" href=\"fml.css\">\n";
    }

    if (defined $title) {
	print $wh "<title>";
	_print_safe_str($wh, $title);
	print $wh "</title>\n";
    }

    print $wh "</HEAD>\n";
    print $wh "<BODY>\n";
    print $wh "<CENTER>";
    _print_safe_str($wh, $title);
    print $wh "</CENTER>\n";
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub html_end
{
    my ($self, $wh) = @_;
    print $wh "</BODY>";
    print $wh "</HTML>\n";
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub mhl_separator
{
    my ($self, $wh) = @_;
    print $wh "<HR>\n";
}


my $preamble_begin = "<!-- __PREAMBLE_BEGIN__ by Mail::HTML::Lite -->";
my $preamble_end   = "<!-- __PREAMBLE_END__   by Mail::HTML::Lite -->";
my $footer_begin   = "<!-- __FOOTER_BEGIN__ by Mail::HTML::Lite -->";
my $footer_end     = "<!-- __FOOTER_END__   by Mail::HTML::Lite -->";


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub mhl_preamble
{
    my ($self, $wh) = @_;
    print $wh $preamble_begin, "\n";
    print $wh $preamble_end, "\n";
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub mhl_footer
{
    my ($self, $wh) = @_;
    print $wh $footer_begin, "\n";
    print $wh $footer_end, "\n";
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _set_output_channel
{
    my ($self, $args) = @_;
    my $dst = $args->{ dst };
    my $wh;

    if (defined $dst) {
	$wh = new FileHandle "> $dst";
    }
    else {
	$wh = \*STDOUT;
    }

    return $wh;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _create_temporary_filename
{
    my ($self, $msg) = @_;
    my $db_dir  = $self->{ _html_base_directory };

    return "$db_dir/tmp$$";
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _create_temporary_file_in_raw_mode
{
    my ($self, $msg) = @_;
    my $tmpf = $self->_create_temporary_filename();
    
    use FileHandle;
    my $wh = new FileHandle "> $tmpf";
    if (defined $wh) {
	$wh->autoflush(1);

	my $buf = $msg->data_in_body_part();
	$wh->print($buf);
	$wh->close;

	return ($tmpf);
    }

    return undef;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _relative_path
{
    my ($self, $file) = @_;
    my $html_base_dir  = $self->{ _html_base_directory };
    $file =~ s/$html_base_dir//;
    $file =~ s@^/@@;
    return $file;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _print_inline_object_link
{
    my ($self, $args) = @_;
    my $wh   = $args->{ fh };
    my $type = $args->{ type };
    my $num  = $args->{ num };
    my $file = $self->_relative_path($args->{ file });
    my $desc = '';
    my $inline = defined( $args->{ inline } ) ? 1 : 0;

    if (defined $args->{ info }->{ description }) {
	$desc = $args->{ info }->{ description };
    }

    if ($inline && $type =~ /image/) {
	print $wh "<BR><IMG SRC=\"$file\">$desc\n";
    }
    else {
	my $t = $file;
	print $wh "<BR><A HREF=\"$file\" TARGET=\"$t\"> $type $num </A>";
	print $wh "$desc<BR>\n";
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _gen_attachment_filename
{
    my ($dst, $attach, $suffix) = @_;
    my $outf = $dst;
    if ($suffix =~ m@/@) { $suffix =~ s@.*/@@;}

    $outf =~s/\.html$//;
    $outf = "$outf.$attach.$suffix";
    return $outf;
}


# default header to show
my @header_field = qw(From To Cc Subject Date 
		      X-ML-Name X-Mail-Count X-Sequence);


# Descriptions: 
#    Arguments: $self $args
# Side Effects: none
#               XXX print return value (str) in raw mode later.
# Return Value: none
sub _format_safe_header
{
    my ($self, $msg) = @_;
    my ($buf);
    my $hdr = $msg->rfc822_message_header;
    my $header_field = \@header_field;

    # header
    $buf .= "<SPAN CLASS=mailheaders>\n";
    for my $field (@$header_field) {
	if (defined($hdr->get($field))) {
	    $buf .= "<SPAN CLASS=${field}>\n";
	    $buf .= "${field}: ";
	    $buf .= "</SPAN>\n";

	    my $xbuf = $hdr->get($field); 
	    $xbuf = $self->_decode_mime_string($xbuf) if $xbuf =~ /=\?iso/i;
	    $buf .= "<SPAN CLASS=${field}-value>\n";
	    $buf   .= _sprintf_safe_str($xbuf);
	    $buf .= "</SPAN>\n";
	    $buf .= "<BR>\n";
	}
    }
    $buf .= "</SPAN>\n";

    return($buf);
}


sub _format_index_navigator
{
    my $str = qq{
<A HREF=\"index.html\">[ID Index]</A>
<A HREF=\"thread.html\">[Thread Index]</A>
<A HREF=\"monthly_index.html\">[Monthly ID Index]</A>
};

return $str;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _text_safe_print
{
    my ($self, $args) = @_;
    my $buf = $args->{ data };
    my $fh  = $args->{ fh } || \*STDOUT;

    if (defined $buf) {
	use Jcode;
	&Jcode::convert(\$buf, 'euc');
    }

    _print_safe_buf($fh, $buf);
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _text_raw_print
{
    my ($self, $args) = @_;
    my $msg  = $args->{ message }; # Mail::Message object
    my $type = $msg->get_data_type;
    my $enc  = $msg->get_encoding_mechanism;
    my $buf  = $msg->data_in_body_part();

    if (defined( $args->{ file } )) {
	my $outf = $args->{ file };
	use FileHandle;
	my $fh = new FileHandle "> $outf";

	if (defined $buf) {
	    use Jcode;
	    &Jcode::convert(\$buf, 'euc');
	}
	print $fh $buf, "\n";
	$fh->close();
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _binary_print
{
    my ($self, $args) = @_;
    my $msg  = $args->{ message }; # Mail::Message object
    my $type = $msg->get_data_type;
    my $enc  = $msg->get_encoding_mechanism;

    if (defined( $args->{ file } )) {
	my $outf = $args->{ file };
	use FileHandle;
	my $fh = new FileHandle "> $outf";

	if (defined $fh) {
	    $fh->autoflush(1);
	    binmode($fh);

	    if ($enc eq 'base64') {
		use MIME::Base64;
		print $fh decode_base64( $msg->data_in_body_part() );
	    }
	    elsif ($enc eq 'quoted-printable') {
		use MIME::QuotedPrint;
		print $fh decode_qp( $msg->data_in_body_part() );
	    }
	    elsif ($enc eq '7bit') {
		_print_safe_str($fh, $msg->data_in_body_part());
	    }
	    else {
		croak("unknown MIME encoding enc=$enc");
	    }

	    $fh->close();
	}
    }
}


=head2 C<is_ignore($id)>

we should not process this C<$id>

=cut


sub is_ignore
{
    my ($self, $id) = @_;

    return defined($self->{ _ignore_list }->{ $id }) ? 1 : 0;
}



=head1 METHODS for index and thread

=head2 C<cache_message_info($msg, $args)>

save information into DB.
See section C<Internal Data Presentation> for more detail.

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub cache_message_info
{
    my ($self, $msg, $args) = @_;
    my $hdr = $msg->rfc822_message_header;
    my $id  = $args-> { id };
    my $dst = $args-> { dst };

    $self->_db_open();
    my $db = $self->{ _db };

    # XXX update max id only under the top level operation
    unless ($self->{ _is_attachment }) {
	if (defined $db->{ _info }->{ id_max }) {
	    $db->{_info}->{id_max} = 
		$db->{_info}->{id_max} < $id ? $id : $db->{_info}->{id_max};
	}
	else {
	    $db->{_info}->{id_max} = $id;
	}
	_PRINT_DEBUG("   parent");
	_PRINT_DEBUG("   update id_max = $db->{_info }->{id_max}");
    }
    else {
	_PRINT_DEBUG("   child");
    }

    _PRINT_DEBUG("   cache_message_info( id=$id ) running");

    $db->{ _filename }->{ $id } = $self->message_filename($id);
    $db->{ _filepath }->{ $id } = $dst;

    # Date:
    $db->{ _date }->{ $id } = $hdr->get('date');

    use Time::ParseDate;
    my $unixtime = parsedate( $hdr->get('date') );
    $db->{ _unixtime }->{ $id } = $unixtime;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime( $unixtime );
    my $month  = sprintf("%04d/%02d", 1900 + $year, $mon + 1);

    # { id => YYYY/MM }
    $db->{ _month }->{ $id } = $month;

    # { YYYY/MM => (id1 id2 id3 ..) }
    __add_value_to_array($db, '_monthly_idlist', $month, $id);

    # Subject:
    $db->{ _subject }->{ $id } = 
	$self->_decode_mime_string( $hdr->get('subject') );
	
    # From:
    my $ra = _address_clean_up( $hdr->get('from') );
    $db->{ _from }->{ $id } = $ra->[0];
    $db->{ _who }->{ $id } = $self->_who_of_address( $hdr->get('from') );

    # Message-Id:
    $ra  = _address_clean_up( $hdr->get('message-id') );
    my $mid = $ra->[0];
    if ($mid) {
	$db->{ _message_id }->{ $id } = $mid;
	$db->{ _msgidref }->{ $mid }  = $id;
	$db->{ _idref }->{ $id }      = $id;
    }

    # Thread Information by In-Reply-To: and References
    {
	my $irt_ra = _address_clean_up( $hdr->get('in-reply-to') );
	my $in_reply_to = $irt_ra->[0];

	_PRINT_DEBUG("In-Reply-To: $in_reply_to") if defined $in_reply_to;

	for my $mid (@$irt_ra) {
	    # { message-id => (id1 id2 id3 ...)
	    __add_value_to_array($db, '_msgidref', $mid, $id);

	    # idp (pointer to id) by { message-id => id }
	    my $idp = _list_head($db->{ _msgidref }->{ $mid });

	    # { idp => (id1 id2 id3 ...) }
	    __add_value_to_array($db, '_idref', $idp, $id) if defined $idp;
	}

	# apply the same logic as above for all message-id's in References:
	my $ref_ra = _address_clean_up( $hdr->get('references') );
	my %uniq = ();
      MSGID_SEARCH:
	for my $mid (@$ref_ra) {
	    next MSGID_SEARCH unless defined $mid;
	    next MSGID_SEARCH if $uniq{$mid};
	    $uniq{$mid} = 1; # ensure uniqueness

	    _PRINT_DEBUG("References: $mid");
	    __add_value_to_array($db, '_msgidref', $mid, $id);
	    my $idp = _list_head($db->{ _msgidref }->{ $mid });
	    __add_value_to_array($db, '_idref', $idp, $id) if defined $idp;
	}

	# 0. ok. go to speculate prev/next links
	# 1. If In-Reply-To: is found, use it as "pointer to previous id"
	my $idp = 0;
	if (defined $in_reply_to) {
	    # XXX idp (id pointer) = id1 by _list_head( (id1 id2 id3 ...)
	    $idp = _list_head( $db->{ _msgidref }->{ $in_reply_to } ); 
	}
	# 2. if not found, try to use References: "in reverse order"
	elsif (@$ref_ra) {
	    my (@rra) = reverse(@$ref_ra);
	    $idp = $rra[0];
	}
	# 3. no prev/next link
	else {
	    $idp = 0;
	}

	if (defined($idp) && $idp && $idp =~ /^\d+$/) {
	    if ($idp != $id) {
		$db->{ _prev_id }->{ $id } = $idp;
		_PRINT_DEBUG("\$db->{ _prev_id }->{ $id } = $idp");
	    }
	    else {
		_PRINT_DEBUG("no \$db->{ _prev_id }");
	    }

	    # XXX we should not overwrite already " id => next_id " exists
	    # XXX we preserve the first " id => next_id " value.
	    # XXX but we overwride it if "id => id (itself)", wrong link.
	    unless ((defined $db->{ _next_id }->{ $idp }) &&
		    ($db->{ _next_id }->{ $idp } != $idp)) {
		$db->{ _next_id }->{ $idp } = $id;
		_PRINT_DEBUG("override \$db->{ _next_id }->{ $idp } = $id");
	    }
	    else {
		my $thread_head_id  = _thread_head( $db, $id );
		_PRINT_DEBUG("no \$db->{ _next_id }->{ $idp } override");
		_PRINT_DEBUG("   = $db->{ _next_id }->{ $idp }");
	    }
	}
	else {
	    _PRINT_DEBUG("no prev/next thread link (id=$id)");
	    warn("no prev/next thread link (id=$id)\n") if $debug;
	}
    }

    $self->_db_close();
}


sub __str2array
{
    my ($str) = @_;

    return undef unless defined $str;

    $str =~ s/^\s*//; 
    $str =~ s/\s*$//; 
    my (@a) = split(/\s+/, $str);
    return \@a;
}


sub __add_value_to_array
{
    my ($db, $dbname, $key, $value) = @_;
    my $found = 0;
    my $ra = __str2array($db->{ $dbname }->{ $key });

    for (@$ra) { 
	$found = 1 if ($value =~ /^\d+$/) && ($_ == $value);
	$found = 1 if ($value !~ /^\d+$/) && ($_ eq $value);
    }

    unless ($found) {
	$db->{ $dbname }->{ $key } .= " $value";
    }
}


sub _thread_head
{
    my ($db, $id) = @_;
    my $max     = 128;
    my $head_id = 0;

    # search the thread head
    while ($max-- > 0) {
	my $prev_id = $db->{ _prev_id }->{ $id };
	last unless $prev_id;
	$head_id = $prev_id;
    }

    return $head_id;
}


sub _search_default_next_thread_id
{
    my ($db, $id) = @_;
    my $list = __str2array( $db->{ _thread_list }->{ $id } );
    my (@ra, @c0, @c1) = ();
    @ra = reverse @$list if defined $list;

    for (1 .. 10) { push(@c0, $id + $_);}
    for my $xid ($id, @ra, @c0) {
	my $default = __search_default_next_thread_id($db, $xid);
	return $default if defined $default;
    }
}


sub __search_default_next_thread_id
{
    my ($db, $id) = @_;
    my $list = __str2array( $db->{ _thread_list }->{ $id } );
    my $prev = 0;

    return undef unless $#$list > 1;

  SEARCH:
    for my $xid (reverse @$list) {
	last SEARCH if $xid == $id;
	$prev = $xid;
    }

    # found ( XXX we use $prev in reverse order, so this $prev means "next")
    if ($prev > 0) {
	_PRINT_DEBUG("default thread: $id => $prev (@$list)");
	return $prev;
    }
    else {
	_PRINT_DEBUG("default thread: $id => none (@$list)");
	return undef;
    }
}


=head2 C<update_relation($id)>

update link relation around C<$id>.

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub update_relation
{
    my ($self, $id) = @_;
    my $args = $self->evaluate_relation($id);
    my $list = $self->{ _affected_idlist } = [];

    if ($self->is_ignore($id)) {
	warn("not update relation around $id") if $debug;
	return undef;
    }

    # update target itself, of course
    $self->_update_relation($id);
    push(@$list, $id);

    # rewrite links of files for 
    #      prev/next id (article id) and
    #      prev/next by thread
    my $db = $self->{ _db };
    my $thread_list = __str2array( $db->{ _thread_list }->{ $id } );
    my %uniq = ( $id => 1 );

  UPDATE:
    for my $id (qw(prev_id next_id prev_thread_id next_thread_id)) {
	if (defined $args->{ $id }) {
	    next UPDATE if $uniq{ $args->{$id} }; $uniq{ $args->{$id} } = 1;

	    $self->_update_relation( $args->{ $id });
	    push(@$list, $args->{ $id });
	}
    }

    # update all articles in this thread.
    for my $id (@$thread_list) {
	next UPDATE if $uniq{ $id}; $uniq{ $id } = 1;
	$self->_update_relation( $id );
	push(@$list, $id);
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _update_relation
{
    my ($self, $id) = @_;
    my $args     = $self->evaluate_relation($id);
    my $preamble = $self->evaluate_safe_preamble($args);
    my $footer   = $self->evaluate_safe_footer($args);
    my $code     = _charset_to_code($self->{ _charset });

    my $pat_preamble_begin = quotemeta($preamble_begin);
    my $pat_preamble_end   = quotemeta($preamble_end);
    my $pat_footer_begin   = quotemeta($footer_begin);
    my $pat_footer_end     = quotemeta($footer_end);

    _PRINT_DEBUG("_update_relation $id");

    use FileHandle;
    my $file        = $args->{ file };
    my ($old, $new) = ($file, "$file.new.$$");
    my $rh = new FileHandle $old;
    my $wh = new FileHandle "> $new";
    if (defined $rh && defined $wh) {
	while (<$rh>) {
	    if (/^$pat_preamble_begin/ .. /^$pat_preamble_end/) {
		_print_raw_str($wh, $preamble, $code) if /^$pat_preamble_end/;
		next;
	    }
	    if (/^$pat_footer_begin/ .. /^$pat_footer_end/) {
		_print_raw_str($wh, $footer, $code) if /^$pat_footer_end/;
		next;
	    }

	    # just copy (rewrite only $preamble and $footer not message)
	    _print_raw_str($wh, $_, $code);
	}
	$rh->close;
	$wh->close;

	unless (rename($new, $old)) {
	    croak("rename($new, $old) fail (id=$id)\n");
	}
    }
    else {
	warn("cannot open $file (id=$id)\n");
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub evaluate_relation
{
    my ($self, $id) = @_;

    $self->_db_open();
    my $db   = $self->{ _db };
    my $file = $db->{ _filepath }->{ $id };

    my $next_file      = $self->message_filepath( $id + 1 );
    my $prev_id        = $id > 1 ? $id - 1 : undef;
    my $next_id        = $id + 1 if -f $next_file;
    my $prev_thread_id = $db->{ _prev_id }->{ $id } || undef;
    my $next_thread_id = $db->{ _next_id }->{ $id } || undef;

    # diagnostic
    if ($prev_thread_id) {
	undef $prev_thread_id if $prev_thread_id == $id;
    }
    if ($next_thread_id) {
	undef $next_thread_id if $next_thread_id == $id;
    }
    else {
	my $xid = _search_default_next_thread_id($db, $id);
	if ($xid && ($xid != $id)) {
	    $next_thread_id = $xid;
	    _PRINT_DEBUG("override next_thread_id = $next_thread_id");
	}
    }

    my $link_prev_id        = $self->message_filename($prev_id);
    my $link_next_id        = $self->message_filename($next_id);
    my $link_prev_thread_id = $self->message_filename($prev_thread_id);
    my $link_next_thread_id = $self->message_filename($next_thread_id);

    my $subject = {};
    if (defined $prev_id) {
	$subject->{ prev_id } = $db->{ _subject }->{ $prev_id };
    }
    if (defined $next_id) {
	$subject->{ next_id } = $db->{ _subject }->{ $next_id };
    }
    if (defined $prev_thread_id) {
	$subject->{ prev_thread_id } = $db->{ _subject }->{ $prev_thread_id };
    }
    if (defined $next_thread_id) {
	$subject->{ next_thread_id } = $db->{ _subject }->{ $next_thread_id };
    }

    my $args = {
	id                  => $id,
	file                => $file,
	prev_id             => $prev_id,
	next_id             => $next_id,
	prev_thread_id      => $prev_thread_id,
	next_thread_id      => $next_thread_id,
	link_prev_id        => $link_prev_id,
	link_next_id        => $link_next_id,
	link_prev_thread_id => $link_prev_thread_id,
	link_next_thread_id => $link_next_thread_id,
	subject             => $subject, 
    };
    _PRINT_DEBUG_DUMP_HASH( $args );

    $self->_db_close();

    return $args;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub evaluate_safe_preamble
{
    my ($self, $args) = @_;
    my $link_prev_id        = $args->{ link_prev_id };
    my $link_next_id        = $args->{ link_next_id };
    my $link_prev_thread_id = $args->{ link_prev_thread_id };
    my $link_next_thread_id = $args->{ link_next_thread_id };

    my $preamble = $preamble_begin. "\n";

    if (defined($link_prev_id)) {
	$preamble .= "<A HREF=\"$link_prev_id\">[Prev by ID]</A>\n";
    }
    else {
	$preamble .= "[No Prev ID]\n";
    }

    if (defined($link_next_id)) {
	$preamble .= "<A HREF=\"$link_next_id\">[Next by ID]</A>\n";
    }
    else {
	$preamble .= "[No Next ID]\n";
    }

    if (defined $link_prev_thread_id) {
	$preamble .= "<A HREF=\"$link_prev_thread_id\">[Prev by Thread]</A>\n";
    }
    else {
	if (defined $link_prev_id) {
	    $preamble .= "<A HREF=\"$link_prev_id\">[Prev by Thread]</A>\n";
	}
	else {
	    $preamble .= "[No Prev Thread]\n";
	}
    }
    
    if (defined $link_next_thread_id) {
	$preamble .= "<A HREF=\"$link_next_thread_id\">[Next by Thread]</A>\n";
    }
    else {
	if (defined $link_next_id) {
	    $preamble .= "<A HREF=\"$link_next_id\">[Next by Thread]</A>\n";
	}
	else {
	    $preamble .= "[No Next Thread]\n";
	}
    }

    $preamble .= _format_index_navigator();
    $preamble .= $preamble_end. "\n";;

    return $preamble;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub evaluate_safe_footer
{
    my ($self, $args) = @_;
    my $link_prev_id        = $args->{ link_prev_id };
    my $link_next_id        = $args->{ link_next_id };
    my $link_prev_thread_id = $args->{ link_prev_thread_id };
    my $link_next_thread_id = $args->{ link_next_thread_id };
    my $subject     = $args->{ subject };

    my $footer = $footer_begin. "\n";;

    if (defined($link_prev_id)) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_prev_id\">Prev by ID: ";
	$footer .= _sprintf_safe_str( $subject->{ prev_id } );
	$footer .= "</A>\n";
    }

    if (defined($link_next_id)) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_next_id\">Next by ID: ";
	$footer .= _sprintf_safe_str( $subject->{ next_id } );
	$footer .= "</A>\n";
    }

    if (defined $link_prev_thread_id) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_prev_thread_id\">Prev by Thread: ";
	$footer .= _sprintf_safe_str($subject->{ prev_thread_id });
	$footer .= "</A>\n";
    }

    if (defined $link_next_thread_id) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_next_thread_id\">Next by Thread: ";
	$footer .= _sprintf_safe_str($subject->{ next_thread_id });
	$footer .= "</A>\n";
    }

    $footer .= qq{<BR>\n};
    $footer .= _format_index_navigator();
    $footer .= $footer_end. "\n";;

    return $footer;
}


=head1 Internal Data Presentation

=head2 Hashes for Database

   name          hash content
   ----------------------------
   from          id => From: header field
   date          id => Date: header field
   subject       id => Subject: header field
   message_id    id => Message-Id: header field
   references    id => References: header field
   filepath      id => file location ( /some/where/YYYY/MM/DD/xxx.html )
   idref         id => id(myself) refered-by-id1 refered-by-id2 ...
   msgidref      message-id => id(myself) refered-by-id1 refered-by-id2 ...

We need several information to speculate thread relation rapidly.
At least we need two relations:

1. to speculate [Next by Thread]

   message-id => ( id1 id2 id3 ... )   

where C<id1> is the message itself.

2. to speculate [Prev by Thread]

   id         => message-id of replied message (e.g. In-Reply-To:)

hashes. 

BTW, the end message of the thread has no next message, 
and the top of the thread has no previous message. 
We arrange apporopviate link to another thread.
Also we need this relation for C<thread.html>.

To resolve this problem, we need ID or Date ordered thread (top id of
th thread) list ?

   thread   followup relation in the thread
   -----------------------------
     id1    id1 - id2 - id4
     id3    id3 - id5 - id6
                   |
                    - id7 - id10
     id8    id8 - id9 - id11
     id12   id12   ...

=head2 Usage

For example, you can set { $key => $value } for C<from> data in this way:

    $self->{ _db }->{ _from }->{ $key } = $value;

=cut

my @kind_of_databases = qw(from date subject message_id references
			   msgidref idref next_id prev_id
			   filename filepath
			   unixtime month monthly_idlist
			   thread_list
			   who info);


# 1. Hmm, what database is needed for 
#    {Prev,Next} by Article ID
#    {Prev,Next} by Thread
#
# 2. each message needs ?
#
#      Subject:
#      From:
#
sub _db_open
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type } || $self->{ _db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    _PRINT_DEBUG("_db_open( type = $db_type )");

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
 	for my $db (@kind_of_databases) {
	    my $file = "$db_dir/.ht_mhl_${db}";
	    my $str = qq{
		my \%$db = ();
		tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, 0644;
		\$self->{ _db }->{ _$db } = \\\%$db;
	    };
	    eval $str;
	    croak($@) if $@;
	}
    }
    else {
	croak("cannot use $db_type");
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _db_close
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type } || $self->{ _db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    _PRINT_DEBUG("_db_close()");

    for my $db (@kind_of_databases) {
	my $str = qq{ 
	    my \$${db} = \$self->{ _db }->{ _$db };
	    untie \%\$${db};
	};
	eval $str;
	croak($@) if $@;
    }
}


=head2 C<update_id_index($args)>

update index.html.

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _print_index_begin
{
    my ($self, $args) = @_;
    my $old   = $args->{ old };
    my $new   = $args->{ new };
    my $title = $args->{ title };
    my $code  = _charset_to_code($self->{ _charset });

    use FileHandle;
    my $wh = new FileHandle "> $new";
    $args->{ wh } = $wh;

    $self->html_begin($wh, { title => $title });

    _print_raw_str($wh, _format_index_navigator(), $code);
    $self->mhl_separator($wh);
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _print_index_end
{
    my ($self, $args) = @_;
    my $wh    = $args->{ wh };
    my $old   = $args->{ old };
    my $new   = $args->{ new };
    my $title = $args->{ title };
    my $code  = $args->{ code };

    $self->mhl_separator($wh);
    _print_raw_str($wh, _format_index_navigator(), $code);

    # append version information
    _print_raw_str($wh, "<BR>Genereated by $version\n", $code);

    $self->html_end($wh);

    unless (rename($new, $old)) {
	croak("rename($new, $old) fail\n");
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub update_id_index
{
    my ($self, $args) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "ID Index",
	old   => "$html_base_dir/index.html",
	new   => "$html_base_dir/index.html.new.$$",
	code  => $code,
    };

    if ($self->is_ignore($args->{id})) {
	warn("not update index.html around $args->{id}") if $debug;
	return undef;
    }

    $self->_print_index_begin( $htmlinfo );
    my $wh = $htmlinfo->{ wh };

    $self->_db_open();
    my $db = $self->{ _db };
    my $id_max = $db->{ _info }->{ id_max };

    $self->_print_ul($wh, $db, $code);
    for my $id ( 1 .. $id_max ) {
	$self->_print_li_filename($wh, $db, $id, $code);
    }
    $self->_print_end_of_ul($wh, $db, $code);
    
    $self->_db_close();
    $self->_print_index_end( $htmlinfo );
}


=head2 C<update_id_monthly_index($args)>

=cut


sub update_id_monthly_index
{
    my ($self, $args) = @_;
    my $affected_list = $self->{ _affected_idlist };

    if ($self->is_ignore($args->{id})) {
	warn("not update index.html around $args->{id}") if $debug;
	return undef;
    }

    # open databaes
    $self->_db_open();
    my $db = $self->{ _db };

    my %month_update = ();

  IDLIST:
    for my $id (@$affected_list) {
	next IDLIST unless $id =~ /^\d+$/;
	my $month = $db->{ _month }->{ $id };
	$month_update{ $month } = 1;
    }

    # todo list
    for my $month (sort keys %month_update) {
	my $this_month = $month;                    # yyyy/mm
	my $suffix     = $month; $suffix =~ s@/@@g; # yyyymm

	$self->_update_id_monthly_index($args, {
	    this_month => $this_month,
	    suffix     => $suffix,
	});
    }

    # update monthly_index.html
    $self->_update_id_montly_index_master($args);
}

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _update_id_montly_index_master
{
    my ($self, $args) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "ID Index",
	old   => "$html_base_dir/monthly_index.html",
	new   => "$html_base_dir/monthly_index.html.new.$$",
	code  => $code,
    };

    $self->_print_index_begin( $htmlinfo );
    my $wh = $htmlinfo->{ wh };

    $self->_db_open();
    my $db = $self->{ _db };
    my $mlist   = $db->{ _monthly_idlist };
    my (@list)  = sort __sort_yyyymm keys %$mlist;
    my ($years) = _yyyy_range(\@list);

    _print_raw_str($wh, "<TABLE>", $code);

    for my $year (@$years) {
	_print_raw_str($wh, "<TR>", $code);

	for my $month (1 .. 12) {
	    _print_raw_str($wh, "<TR>", $code) if $month == 7;

	    my $id = sprintf("%04d/%02d", $year, $month); # YYYY/MM
	    my $xx = sprintf("%04d%02d", $year, $month); # YYYYMM
	    my $fn = "month.$xx.html";

	    use File::Spec;
	    my $file = File::Spec->catfile($html_base_dir, $fn);
	    if (-f $file) {
		_print_raw_str($wh, "<TD><A HREF=\"$fn\"> $id </A>", $code);
	    }
	    else {
		_print_raw_str($wh, "<TD>", $code);
	    }
	}
    }
    _print_raw_str($wh, "</TABLE>", $code);
    
    $self->_db_close();
    $self->_print_index_end( $htmlinfo );
}


sub _yyyy_range
{
    my ($list) = @_;
    my ($yyyy);

    for (@$list) {
	if (/^(\d{4})\/(\d{2})/) {
	    $yyyy->{ $1 } = $1;
	}
    }

    my (@yyyy) = keys %$yyyy;
    return( \@yyyy );
}


sub __sort_yyyymm
{
    my ($xa, $xb) = ($a, $b);
    $xa =~ s@/@@;
    $xb =~ s@/@@;
    $xa <=> $xb;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _update_id_monthly_index
{
    my ($self, $args, $monthlyinfo) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $this_month    = $monthlyinfo->{ this_month }; # yyyy/mm
    my $suffix        = $monthlyinfo->{ suffix };     # yyyymm
    my $htmlinfo = {
	title => "ID Monthly Index $this_month",
	old   => "$html_base_dir/month.${suffix}.html",
	new   => "$html_base_dir/month.${suffix}.html.new.$$",
	code  => $code,
    };

    $self->_print_index_begin( $htmlinfo );
    my $wh = $htmlinfo->{ wh };

    $self->_db_open();
    my $db = $self->{ _db };
    my $id_max = $db->{ _info }->{ id_max };

    # oops, this list may be " a b c d e " string, nuke \s* to avoid warning.
    $db->{ _monthly_idlist }->{ $this_month } =~ s/^\s*//;
    $db->{ _monthly_idlist }->{ $this_month } =~ s/\s*$//;
    my (@list) = split(/\s+/, $db->{ _monthly_idlist }->{ $this_month });

    $self->_print_ul($wh, $db, $code);
    for my $id (sort {$a <=> $b} @list) {
	next unless $id =~ /^\d+$/;
	$self->_print_li_filename($wh, $db, $id, $code);
    }
    $self->_print_end_of_ul($wh, $db, $code);
    
    $self->_db_close();
    $self->_print_index_end( $htmlinfo );
}


=head2 C<update_thread_index($args)>

update thread.html.

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub update_thread_index
{
    my ($self, $args) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "Thread Index",
	old   => "$html_base_dir/thread.html",
	new   => "$html_base_dir/thread.html.new.$$",
	code  => $code,
    };

    if ($self->is_ignore($args->{id})) {
	warn("not update thread.html around $args->{id}") if $debug;
	return undef;
    }

    $self->_print_index_begin( $htmlinfo );
    my $wh = $htmlinfo->{ wh };

    $self->_db_open();
    my $db = $self->{ _db };
    my $id_max = $db->{ _info }->{ id_max };

    # initialize negagtive cache to ensure uniquness
    delete $self->{ _uniq };

    $self->_print_ul($wh, $db, $code);
    for my $id ( 1 .. $id_max ) {
	# head of the thread (not referenced yet)
	unless (defined $self->{ _uniq }->{ $id }) {
	    $self->_print_thread($wh, $db, $id, $code);
	}
    }
    $self->_print_end_of_ul($wh, $db, $code);

    $self->_db_close();
    $self->_print_index_end( $htmlinfo );
}


sub _has_link
{
    my ($self, $db, $id) = @_;

    if (defined( $db->{ _next_id }->{ $id } ) ||
	defined( $db->{ _prev_id }->{ $id } )) {
	return 1;
    }
    else {
	return 0;
    }
}


#  print thread array of (head_id id2 id3 ...)
#
sub _print_thread
{
    my ($self, $wh, $db, $head_id, $code) = @_;
    my $saved_stack_level = $self->{ _stack };
    my $uniq = $self->{ _uniq };

    # debug information (it is useful not to remove this ?)
    _print_raw_str($wh, "<!-- thread head=$head_id -->\n", $code);

    # get id list: @idlist = ( $head_id id2 id3 ... )
    my $buf = $db->{ _idref }->{ $head_id };

    if (defined $buf) {
	my $ra       = __str2array($buf);
	my (@idlist) = @$ra;

      IDLIST:
	for my $id (@idlist) {
	    # save $id => " @idlist " for further use
	    # XXX override occurs but select latest information (no reason;)
	    if ($#idlist > 1) {
		$db->{ _thread_list }->{ $id } = $buf;
		_PRINT_DEBUG("\$db->{ _thread_list }->{ $id } = $buf");
	    }

	    # @idlist = (number's)
	    _print_raw_str($wh, "<!-- thread (@idlist) -->\n", $code);

	    next IDLIST if $uniq->{ $id };
	    $uniq->{ $id } = 1;

	    $self->_print_ul($wh, $db, $code);

	    # oops, we should ignore head of the thread ( myself ;-)
	    if (($id != $head_id) && $self->_has_link($db, $id)) {
		$self->_print_li_filename($wh, $db, $id, $code);
		$self->_print_thread($wh, $db, $id, $code);
	    }
	    else {
		$self->_print_li_filename($wh, $db, $id, $code);
	    }
	}
    }

    while ($self->{ _stack } > $saved_stack_level) {
	$self->_print_end_of_ul($wh, $db, $code);
    }
}


=head2 internal utility functions for IO

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _charset_to_code
{
    my ($charset) = @_;

    if (defined $charset) {
	$charset =~ tr/A-Z/a-z/;
	if ($charset eq 'euc-jp') {
	    return 'euc';
	}
	elsif ($charset eq 'iso-2022-jp') {
	    return 'jis';
	}
	else {
	    return $charset; # may be wrong, but I hope it works well:-)
	}
    }
    else {
	return 'euc'; # euc-jp by default
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _print_raw_str
{
    my ($wh, $str, $code) = @_;
    $code = defined($code) ? $code : 'euc'; # euc-jp by default

    if (defined $str) {
	use Jcode;
	&Jcode::convert( \$str, $code);
    }

    print $wh $str;
}


sub _print_safe_str
{
    my ($wh, $str, $code) = @_;
    __print_safe_str(0, $wh, $str, $code);
}


sub _print_safe_buf
{
    my ($wh, $str, $code) = @_;
    __print_safe_str(1, $wh, $str, $code);
}


sub __print_safe_str
{
    my ($attr_pre, $wh, $str, $code) = @_;
    my $p = __sprintf_safe_str($attr_pre, $wh, $str, $code);
    print $wh $p if defined $p;
    print $wh "\n";
}


sub _sprintf_safe_str
{
    my ($str, $code) = @_;
    return __sprintf_safe_str(0, undef, $str, $code);
}


sub __sprintf_safe_str
{
    my ($attr_pre, $wh, $str, $code) = @_;
    my $rbuf = '';

    if (defined($str) && defined($code)) {
	use Jcode;
	&Jcode::convert(\$str, $code);
    }

    if (defined $str) {
	# $url$trailor => $url $trailor for text2html() incomplete regexp
	$str =~ s#(http://\S+[\w\d/])#_separete_url($1)#ge;

	use HTML::FromText;
	return text2html($str, urls => 1, pre => $attr_pre);
    }
    else {
	return undef;
    }
}


# $url$trailor => $url $trailor for text2html() incomplete regexp 
# based on fml 4.0-current (2001/10/28)
sub _separete_url
{
    my ($url) = @_;
    my ($re_euc_c) = '[\241-\376][\241-\376]';
    my ($re_euc_s)  = "($re_euc_c)+";
    my $trailor = '';

    # remove prepended/appended EUC strings
    if ($url =~ /($re_euc_s)+$/) {
        $trailor = $1;
        $url     =~ s/$trailor//;
    }

    # incomplete but may be effective ?
    # RFC2068 says these special char's are not used.
    # we should not include these char's in URL.
    # reserved       = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+"
    # unsafe         = CTL | SP | <"> | "#" | "%" | "<" | ">"
    if ($url =~ /(\&\w{2}\;|\;|\?|\:|\@|\&|\=|\+|\#|\%|\<|\>|\")+$/) {
        my $pat  = $1;
        $trailor = $pat . $trailor;
        $url     =~ s/${pat}$//; 
    }

    return "$url $trailor";
}


sub _PRINT_DEBUG
{
    my ($str) = @_;
    print STDERR "(debug) $str\n" if $debug;
}


sub _PRINT_DEBUG_DUMP_HASH
{
    my ($hash) = @_;
    my ($k,$v);

    if ($debug) {
	while (($k, $v) = each %$hash) {
	    printf STDERR "%-30s => %s\n", $k, $v;
	}
    }
}


=head2 internal utility functions for HTML TAGS

C<_print_something()> internal function provides wrapper to print HTML
tags et.al.

=cut


sub _print_ul
{
    my ($self, $wh, $db, $code) = @_;

    $self->{ _stack }++;

    my $padding = "   " x $self->{ _stack };
    _print_raw_str($wh, "${padding}<UL>\n", $code);
}


sub _print_end_of_ul
{
    my ($self, $wh, $db, $code) = @_;

    return unless $self->{ _stack } > 0;

    my $padding = "   " x $self->{ _stack };
    _print_raw_str($wh, "${padding}</UL>\n", $code);

    $self->{ _stack }--;
}


sub _print_li_filename
{
    my ($self, $wh, $db, $id, $code) = @_;
    my $filename = $db->{ _filename }->{ $id };
    my $subject  = $db->{ _subject }->{ $id };
    my $who      = $db->{ _who }->{ $id };

    _print_raw_str($wh, "<!-- LI id=$id -->\n", $code);

    _print_raw_str($wh, "<LI>\n", $code);
    _print_raw_str($wh, "<A HREF=\"$filename\">\n", $code);
    _print_safe_str($wh, $subject, $code);
    _print_raw_str($wh, ",\n", $code);
    _print_safe_str($wh, "$who\n", $code);
    _print_raw_str($wh, "</A>\n", $code);
}


=head2 misc

=cut


sub _address_clean_up
{
    my ($addr) = @_;
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


sub _who_of_address
{
    my ($self, $address, $options) = @_;
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


sub _list_head
{
    my ($buf) = @_;
    $buf =~ s/^\s*//;
    $buf =~ s/\s*$//;
    return (split(/\s+/, $buf))[0];
}


sub _decode_mime_string
{
    my ($self, $str, $options) = @_;
    my $charset = $options->{ 'charset' } || $self->{ _charset };
    my $code    = _charset_to_code($charset);

    # If looks Japanese and $code is specified as Japanese, decode !
    if (defined($str) &&
	($str =~ /=\?ISO\-2022\-JP\?[BQ]\?/i) &&
	($code eq 'euc' || $code eq 'jis')) {
        use MIME::Base64;
        if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
        }

        use MIME::QuotedPrint;
        if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
        }

	if (defined $str) {
	    use Jcode;
	    my $icode = &Jcode::getcode(\$str);
	    &Jcode::convert(\$str, $code, $icode);
	}
    }

    return $str;
}


=head1 useful functions as entrance

=head2 C<htmlify_file($file, $args)>

try to convert rfc822 message C<$file> to HTML. 

    $args = {
	directory => "destination directory",
    };

=head2 C<htmlify_dir($dir, $args)>

try to convert all rfc822 messages to HTML in C<$dir> directory.

    $args = {
	directory => "destination directory",
    };

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub htmlify_file
{
    my ($file, $args) = @_;
    my $dst_dir = $args->{ directory };

    use File::Basename;
    my $id = basename($file);
    my $html = new Mail::HTML::Lite {
	charset   => "euc-jp",
	directory => $dst_dir, 
    };

    if (defined $ENV{'debug'}) {
	printf STDERR "htmlify_file( id=%-6s src=%s )\n", $id, $file;
    }

    $html->htmlfy_rfc822_message({
	id  => $id,
	src => $file,
    });

    $html->update_relation( $id );
    $html->update_id_monthly_index({ id => $id });
    $html->update_id_index({ id => $id });
    $html->update_thread_index({ id => $id });

    # no more action for old files
    if ($html->is_ignore($id)) {
	warn("not process $id (already exists)") if defined $ENV{'debug'};
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub htmlify_dir
{
    my ($src_dir, $args) = @_;
    my $dst_dir = $args->{ directory };
    my $max     = 0;

    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
      FILE:
	for my $file ( $dh->read() ) {
	    next FILE unless $file =~ /^\d+$/;
	    $max = $max < $file ? $file : $max;
	}
    }

    for my $id ( 1 .. $max ) {
	use File::Spec;
	my $file = File::Spec->catfile($src_dir, $id);
	htmlify_file($file, { directory => $dst_dir });
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $dir = "/tmp/htdocs";

    eval q{
	for my $x (@ARGV) {
	    if (-f $x) {
		htmlify_file($x, { directory => $dir });
	    }
	    elsif (-d $x) {
		htmlify_dir($x, { directory => $dir });
	    }
	}
    };
    croak($@) if $@;
}


=head1 TODO

   expiration

   sub directory? 

=head1 AUTHOR

Ken'ichi Fukamachi 

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi 

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::HTML::Lite appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
