#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ToHTML.pm,v 1.19 2002/04/27 05:25:03 fukachan Exp $
#

package Mail::Message::ToHTML;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $is_strict_warn = 0;
my $debug = 0;
my $URL   =
    "<A HREF=\"http://www.fml.org/software/\">Mail::Message::ToHTML</A>";

my $version = q$FML: ToHTML.pm,v 1.19 2002/04/27 05:25:03 fukachan Exp $;
if ($version =~ /,v\s+([\d\.]+)\s+/) {
    $version = "$URL $1";
}

=head1 NAME

Mail::Message::ToHTML - convert text format mail to HTML format

=head1 SYNOPSIS

  ... lock by something ...

  use Mail::Message::ToHTML;
  my $obj = new Mail::Message::ToHTML {
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


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
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
    $me->{ _use_subdir }     = 'yes';
    $me->{ _subdir_style }   = 'yyyymm';

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


# Descriptions: top level entrance to convert mail to html
#    Arguments: OBJ($self) HASH_REF($args)
#               $args = { id => $id, path => $path };
#                  $id    identifier (e.g. "1" (article id))
#                  $path  file path  (e.g. "/some/where/1");
# Side Effects: none
# Return Value: none
sub htmlfy_rfc822_message
{
    my ($self, $args) = @_;

    # prepare source
    use Mail::Message;
    use FileHandle;
    my $rh   = new FileHandle $args->{ src };
    my $msg  = Mail::Message->parse( { fd => $rh } );
    my $hdr  = $msg->whole_message_header;
    my $body = $msg->whole_message_body;
    $self->{ _current_msg  } = $msg;
    $self->{ _current_hdr  } = $hdr;
    $self->{ _current_body } = $body;

    # initialize basic information
    #    $id  = article id
    #   $src  = source file
    #   $dst  = destination file (target html)
    my ($id, $src, $dst)   = $self->_init_htmlfy_rfc822_message($args);
    $self->{ _current_id } = $id;

    # target html exists already.
    if (-f $dst) {
	$self->{ _ignore_list }->{ $id } = 1; # ignore flag
	warn("html file for $id already exists") if $debug;
	return undef;
    }

    # hints
    $self->{ _hints }->{ src }->{ filepath } = $src;

    # save information for index.html and thread.html
    $self->cache_message_info($msg, { id => $id,
				      src => $src,
				      dst => $dst,
				  } );

    # prepare output channel
    my $wh = $self->_set_output_channel( { dst => $dst } );
    unless (defined $wh) {
	croak("cannot open output file $dst\n");
    }

    # before main message
    $self->html_begin($wh, { message => $msg });
    $self->mhl_preamble($wh);

    # analyze $msg, chain of Mail::Message objects.
    # See Mail::Message class for more detail.
    # XXX we use $m->{ next } here, but we should avoid this style and
    # XXX prepare access method for it in Mail::Message class.
    my ($m, $type, $attach);
  CHAIN:
    for ($m = $msg; defined($m) ; $m = $m->{ 'next' }) {
	$type = $m->data_type;

	last CHAIN if $type eq 'multipart.close-delimiter'; # last of multipart
	next CHAIN if $type =~ /^multipart/; # multipart type is special.

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
	# message/rfc822 case (attached rfc822 message)
	elsif ($type eq 'message/rfc822') {
	    $attach++;

	    my $tmpf = $self->_create_temporary_file_in_raw_mode($m);
	    if (defined $tmpf && -f $tmpf) {
		# write attachement into a separete file
		my $outf = _gen_attachment_filename($dst, $attach, 'html');
		my $args = $self->{ _args };
		$args->{ attachment } = 1; # clarify not top level content.
		my $text = new Mail::Message::ToHTML $args;
		$text->htmlfy_rfc822_message({
		    parent_id => $id,
		    src => $tmpf,
		    dst => $outf,
		});

		# show inline <HREF> link,
		# which appears in parent html ( == $wh channel ).
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
	# XXX inline expansion.
	elsif ($type eq 'text/plain') {
	    $self->_text_safe_print({
		fh   => $wh,                    # parent html
		data => $m->message_text(),
	    });
	}
	# create a separete file for attachment
	else {
	    $attach++;

	    # write attachement into a separete file
	    my $outf    = _gen_attachment_filename($dst, $attach, $type);
	    my $enc     = $m->encoding_mechanism;
	    my $msginfo = { message => $m };

	    # e.g. text/xxx case (e.g. text/html case)
	    if ($type =~ /^text/) {
		# 1. firstly saved to temporary file $tmpf in "raw" mode
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

		# 2. secondary convert $tmpf to real target $outf with
		#    some modification e.g. metachars escaping, ...
		# disable html tag in file saved in raw mode.
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

	    # show inline <HREF> link appeared in parent html.
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

    # show navigation bar et.al. after message itself
    $self->mhl_separator($wh);
    $self->mhl_footer($wh);
    $self->html_end($wh);
}


# Descriptions: copy $inf file to $outf file with disabling HTML tag
#               by _print_safe_buf().
#    Arguments: STR($inf) STR($outf)
# Side Effects: create $outf file
# Return Value: none
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


# Descriptions: return HTML filename
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR or UNDEF
sub html_filename
{
    my ($self, $id) = @_;
    my $use_subdir = $self->{ _use_subdir };

    if (defined($id) && ($id > 0)) {
	if ($use_subdir eq 'yes') {
	    my $r = $self->_html_file_subdir_name($id);
	    # print STDERR "xdebug: $id => $r\n";
	    return $r;
	}
	else {
	    return "msg${id}.html";
	}
    }
    else {
	return undef;
    }
}


# Descriptions: return HTML sub directory string
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR
sub _html_file_subdir_name
{
    my ($self, $id) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $subdir        = '';
    my $subdir_style  = $self->{ _subdir_style };
    my $month_db      = $self->{ _db }->{ _month };
    my $subdir_db     = $self->{ _db }->{ _subdir };
    my $curid         = $self->{ _current_id };

    if ($subdir_style eq 'yyyymm') {
	if (defined $subdir_db->{ $id } && $subdir_db->{ $id }) {
	    $subdir = $subdir_db->{ $id };
	}
	else {
	    $subdir = $self->_msg_time('yyyymm');

	    # XXX why we need validate $curid here ? (sholed be true always ?)
	    if (defined($curid) && $curid == $id) {
		$subdir_db->{ $id } = $subdir; # cache subdir info into DB.
		# print STDERR "xdebug: \$subdir_db->{ $id } = $subdir\n";
	    }

	    use File::Spec;
	    my $xsubdir = File::Spec->catfile($html_base_dir, $subdir);
	    unless (-d $xsubdir) {
		mkdir($xsubdir, 0755);
	    }
	}
    }

    if ($subdir) {
	use File::Spec;
	return File::Spec->catfile($subdir, "msg$id.html");
    }
    else {
	return undef;
    }
}


# Descriptions: return HTML file path
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR
sub html_filepath
{
    my ($self, $id) = @_;
    my $html_base_dir = $self->{ _html_base_directory };

    if (defined($id) && ($id > 0)) {
	my $filename = $self->html_filename($id);

	use File::Spec;
	return File::Spec->catfile($html_base_dir, $filename);
    }
    else {
	return undef;
    }
}


# Descriptions: parse $args and return file id, name, path.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY(NUM, STR, STR)
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
	$dst = $self->html_filepath($id);
    }
    # this object is an attachment if parent_id is specified.
    elsif (defined $args->{ parent_id }) {
	$self->{ _num_attachment }++;
	$id  = $args->{ parent_id } .'.'. $self->{ _num_attachment };
	$dst = $args->{ dst };
    }
    # last resort: give unique identifier
    elsif (defined $args->{ dst }) {
	$id  = time.".".$$;
	$dst = $args->{ dst };
    }
    # oops ;) wrong call of this function
    else {
	croak("htmlfy_rfc822_message: specify \$id or \$dst\n");
    }

    $self->{ _id } = $id;

    return ($id, $src, $dst);
}


# Descriptions: show html header + file title in <BODY>
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($args)
# Side Effects: none
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
	$hdr   = $msg->whole_message_header;
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


# Descriptions: show html closing
#    Arguments: OBJ($self) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub html_end
{
    my ($self, $wh) = @_;
    print $wh "</BODY>";
    print $wh "</HTML>\n";
}


# Descriptions: show html separetor, we use <HR> now.
#    Arguments: OBJ($self) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub mhl_separator
{
    my ($self, $wh) = @_;
    print $wh "<HR>\n";
}


my $preamble_begin = "<!-- __PREAMBLE_BEGIN__ by Mail::Message::ToHTML -->";
my $preamble_end   = "<!-- __PREAMBLE_END__   by Mail::Message::ToHTML -->";
my $footer_begin   = "<!-- __FOOTER_BEGIN__ by Mail::Message::ToHTML -->";
my $footer_end     = "<!-- __FOOTER_END__   by Mail::Message::ToHTML -->";


# Descriptions: prepare information area before main message appears.
#               Later, this area is replaced with useful information
#               e.g. thread link.
#    Arguments: OBJ($self) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub mhl_preamble
{
    my ($self, $wh) = @_;
    print $wh $preamble_begin, "\n";
    print $wh $preamble_end, "\n";
}


# Descriptions: prepare information area after main message appears.
#               Later, this area is replaced with useful information
#               e.g. thread link.
#    Arguments: OBJ($self) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub mhl_footer
{
    my ($self, $wh) = @_;
    print $wh $footer_begin, "\n";
    print $wh $footer_end, "\n";
}


# Descriptions: prepare write handle
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $args->{ dst } file if needed
# Return Value: HANDLE
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


# Descriptions: return temporary file path.
#               XXX temporary file is created under $db_dir not public space
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub _create_temporary_filename
{
    my ($self, $msg) = @_;
    my $db_dir  = $self->{ _html_base_directory };

    return "$db_dir/tmp$$";
}


# Descriptions: create a temporary file with the content $msg
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $tmpf file
# Return Value: STR
sub _create_temporary_file_in_raw_mode
{
    my ($self, $msg) = @_;
    my $tmpf = $self->_create_temporary_filename();

    use FileHandle;
    my $wh = new FileHandle "> $tmpf";
    if (defined $wh) {
	$wh->autoflush(1);

	my $buf = $msg->message_text();
	$wh->print($buf);
	$wh->close;

	return ($tmpf);
    }

    return undef;
}


# Descriptions: convert $file filepath to relative path
#               XXX UNIX specific ???
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
#         Todo: UNIX specific
# Return Value: STR
sub _relative_path
{
    my ($self, $file) = @_;
    my $html_base_dir  = $self->{ _html_base_directory };
    $file =~ s/$html_base_dir//;
    $file =~ s@^/@@;
    return $file;
}


# Descriptions: print inline link as html for attachments e.g.
#               images, files et. al.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
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


# Descriptions: return attachment filename
#    Arguments: OBJ($self) STR($attach) STR($suffix)
# Side Effects: none
#         Todo: UNIX specific
# Return Value: STR
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


# Descriptions: format header of $msg with escaping HTML metachars
#               and disabling special HTML tags.
#               See _sprintf_safe_str() for how to escape.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
#               XXX $buf is printed out later in raw mode.
# Return Value: STR
sub _format_safe_header
{
    my ($self, $msg) = @_;
    my ($buf);
    my $hdr = $msg->whole_message_header;
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


# Descriptions: show link to indexes as navigation
#    Arguments: none
# Side Effects: none
# Return Value: none
sub _format_index_navigator
{
    my ($args) = @_;
    my $use_subdir = defined $args->{use_subdir} ? $args->{use_subdir} : 0;
    my $prefix = $use_subdir ? '../' : '';

    my $str = qq{
<A HREF=\"${prefix}index.html\">[ID Index]</A>
<A HREF=\"${prefix}thread.html\">[Thread Index]</A>
<A HREF=\"${prefix}monthly_index.html\">[Monthly ID Index]</A>
};

return $str;
}


# Descriptions: print out text data with escaping by _print_safe_buf()
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub _text_safe_print
{
    my ($self, $args) = @_;
    my $buf = $args->{ data };
    my $fh  = $args->{ fh } || \*STDOUT;

    if (defined $buf && $buf) {
	use Jcode;
	&Jcode::convert(\$buf, 'euc');
    }

    _print_safe_buf($fh, $buf);
}


# Descriptions: print out message without escaping
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $outf
# Return Value: none
sub _text_raw_print
{
    my ($self, $args) = @_;
    my $msg  = $args->{ message }; # Mail::Message object
    my $type = $msg->data_type;
    my $enc  = $msg->encoding_mechanism;
    my $buf  = $msg->message_text();

    if (defined( $args->{ file } )) {
	my $outf = $args->{ file };
	use FileHandle;
	my $fh = new FileHandle "> $outf";

	if (defined $buf && $buf) {
	    use Jcode;
	    &Jcode::convert(\$buf, 'euc');
	}
	print $fh $buf, "\n";
	$fh->close();
    }
}


# Descriptions: print out binary with MIME encoding or
#               text with escaping
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $outf file
# Return Value: none
sub _binary_print
{
    my ($self, $args) = @_;
    my $msg  = $args->{ message }; # Mail::Message object
    my $type = $msg->data_type;
    my $enc  = $msg->encoding_mechanism;

    if (defined( $args->{ file } )) {
	my $outf = $args->{ file };
	use FileHandle;
	my $fh = new FileHandle "> $outf";

	if (defined $fh) {
	    $fh->autoflush(1);
	    binmode($fh);

	    if ($enc eq 'base64') {
		eval q{
		    use MIME::Base64;
		    print $fh decode_base64( $msg->message_text() );
		};
	    }
	    elsif ($enc eq 'quoted-printable') {
		eval q{
		    use MIME::QuotedPrint;
		    print $fh decode_qp( $msg->message_text() );
		};
	    }
	    elsif ($enc eq '7bit') {
		_print_safe_str($fh, $msg->message_text());
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


# Descriptions: check whether article $id is ignored
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: 1 or 0
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


# Descriptions: update database on message header, thread relation
#               et. al.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: update database
# Return Value: none
sub cache_message_info
{
    my ($self, $msg, $args) = @_;
    my $hdr = $msg->whole_message_header;
    my $id  = $args-> { id };
    my $dst = $args-> { dst };

    $self->_db_open();
    my $db = $self->{ _db };

    # XXX we should not update max_id when our target is an attachment.
    # XXX update max_id only under the top level operation
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

    # HASH { $id => Date: }
    $db->{ _date }->{ $id } = $hdr->get('date');

    # HASH { $id => YYYY/MM }
    my $month = $self->_msg_time('yyyy/mm');
    $db->{ _month }->{ $id } = $month;

    # HASH { YYYY/MM => (id1 id2 id3 ..) }
    __add_value_to_array($db, '_monthly_idlist', $month, $id);

    # need month database to determine subdir for the html file
    $db->{ _filename }->{ $id } = $self->html_filename($id);
    $db->{ _filepath }->{ $id } = $dst;

    # HASH { $id => Subject: }
    $db->{ _subject }->{ $id } =
	$self->_decode_mime_string( $hdr->get('subject') );

    # HASH { $id => From: }
    my $ra = _address_clean_up( $hdr->get('from') );
    $db->{ _from }->{ $id } = $ra->[0];
    $db->{ _who }->{ $id } = $self->_who_of_address( $hdr->get('from') );

    # HASH { $id => Message-Id: }
    # HASH { Message-Id: => $id }
    # HASH { $id => list of $id ... }
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

	# save message-id(s) within In-Reply-To: field into database
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

	    # XXX we should not overwrite " id => next_id " assinged already.
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


# Descriptions: return
#    Arguments: OBJ($self) STR($type)
# Side Effects: none
# Return Value: STR
sub _msg_time
{
    my ($self, $type) = @_;
    my $hdr  = $self->{ _current_hdr  };

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
	my $id = $self->{ _current_id };
	warn("cannot pick up Date: field id=$id");
	return '';
    }
}


# Descriptions: convert space-separeted string to array
#    Arguments: STR($str)
# Side Effects: none
# Return Value: ARRAY_REF
sub __str2array
{
    my ($str) = @_;

    return undef unless defined $str;

    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    my (@a) = split(/\s+/, $str);
    return \@a;
}


# Descriptions: add { key => value } of database $dbname.
#               value is "x y z ..." form, space separated string.
#    Arguments: HASH_REF($db) STR($dbname) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub __add_value_to_array
{
    my ($db, $dbname, $key, $value) = @_;
    my $found = 0;
    my $ra = __str2array($db->{ $dbname }->{ $key });

    # ensure uniqueness
    for (@$ra) {
	$found = 1 if ($value =~ /^\d+$/) && ($_ == $value);
	$found = 1 if ($value !~ /^\d+$/) && ($_ eq $value);
    }

    # add if the value is a new comer.
    unless ($found) {
	$db->{ $dbname }->{ $key } .= " $value";
    }
}


# Descriptions: speculate head of thread list,
#               traced back from $id.
#    Arguments: HASH_REF($db) STR($id)
# Side Effects: none
# Return Value: NUM
sub _thread_head
{
    my ($db, $id) = @_;
    my $max     = 128;
    my $head_id = $id;

    # track back id list to search the thread head
    while ($max-- > 0) {
	my $prev_id = $db->{ _prev_id }->{ $head_id };
	last unless $prev_id;
	$head_id = $prev_id;
    }

    return $head_id;
}


# Descriptions: speculate head of the next thread list.
#    Arguments: HASH_REF($db) STR($id)
# Side Effects: none
# Return Value: STR
sub _search_default_next_thread_id
{
    my ($db, $id) = @_;
    my $list = __str2array( $db->{ _thread_list }->{ $id } );
    my (@ra, @c0, @c1) = ();
    @ra = reverse @$list if defined $list;

    for (1 .. 10) { push(@c0, $id + $_);}

    # prepare thread list to search
    # 1. thread includes $id
    # 2. thread(s) begining at each id in thread 1.
    # 3. last resort: thread includes ($id+1),
    #                 thread includes ($id+2), ...
    for my $xid ($id, @ra, @c0) {
	my $default = __search_default_next_id_in_thread($db, $xid);
	return $default if defined $default;
    }
}


# Descriptions: speculate the next id of $id.
#    Arguments: HASH_REF($db) STR($id)
# Side Effects: none
# Return Value: STR
sub __search_default_next_id_in_thread
{
    my ($db, $id) = @_;
    my $list = [];
    my $prev = 0;

    # thread_list HASH { $id => $id1 $id2 $id3 ... }
    if (defined $db->{ _thread_list }->{ $id }) {
	$list = __str2array( $db->{ _thread_list }->{ $id } );
	return undef unless $#$list > 1;

	# thread_list HASH { $id => $id1 $id2 $id3 ... $id $prev ... }
	#                           <---- search ---
      SEARCH:
	for my $xid (reverse @$list) {
	    last SEARCH if $xid == $id;
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
}


=head2 C<update_relation($id)>

update link relation around C<$id>.

=cut


# Descriptions: top level dispatcher to update database.
#               _update_relation() has real function for updating.
#    Arguments: OBJ($self) STR($id)
# Side Effects: update databse
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
    my %uniq = ( $id => 1 );

  UPDATE:
    for my $id (qw(prev_id next_id prev_thread_id next_thread_id)) {
	if (defined $args->{ $id }) {
	    next UPDATE if $uniq{ $args->{$id} }; $uniq{ $args->{$id} } = 1;

	    $self->_update_relation( $args->{ $id });
	    push(@$list, $args->{ $id });
	}
    }

    if (defined $db->{ _thread_list }->{ $id } ) {
	my $thread_list = __str2array( $db->{ _thread_list }->{ $id } );

	# update link relation for all articles in this thread.
	for my $id (@$thread_list) {
	    next UPDATE if $uniq{ $id}; $uniq{ $id } = 1;
	    $self->_update_relation( $id );
	    push(@$list, $id);
	}
    }
}


# Descriptions: update link at preamble and footer of HTML-ified message.
#    Arguments: OBJ($self) STR($id)
# Side Effects: rewrite index file
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
    my $file = $args->{ file };
    if (defined $file && $file && -f $file) {
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
	    unless (defined $file) {
		$new = $old = '(null string)';
	    }
	    warn("cannot open   $old (id=$id)\n") unless defined $rh;
	    warn("cannot create $new (id=$id)\n") unless defined $wh;
	}
    }
    else {
	warn("undefined file for $id\n") if $is_strict_warn;
    }
}


# Descriptions: return thread link relation info et.al. for $id
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: HASH_REF
sub evaluate_relation
{
    my ($self, $id) = @_;

    $self->_db_open();
    my $db   = $self->{ _db };
    my $file = $db->{ _filepath }->{ $id };

    my $next_file      = $self->html_filepath( $id + 1 );
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

    my $link_prev_id        = $self->html_filename($prev_id);
    my $link_next_id        = $self->html_filename($next_id);
    my $link_prev_thread_id = $self->html_filename($prev_thread_id);
    my $link_next_thread_id = $self->html_filename($next_thread_id);

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


# Descriptions: return preamble without metachars
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub evaluate_safe_preamble
{
    my ($self, $args) = @_;
    my $link_prev_id        = $args->{ link_prev_id };
    my $link_next_id        = $args->{ link_next_id };
    my $link_prev_thread_id = $args->{ link_prev_thread_id };
    my $link_next_thread_id = $args->{ link_next_thread_id };

    my $use_subdir = $self->{ _use_subdir } eq 'yes' ? 1 : 0;
    my $prefix     = $use_subdir ? '../' : '';
    my $preamble   = $preamble_begin. "\n";

    if (defined($link_prev_id)) {
	$preamble .= "<A HREF=\"${prefix}$link_prev_id\">[Prev by ID]</A>\n";
    }
    else {
	$preamble .= "[No Prev ID]\n";
    }

    if (defined($link_next_id)) {
	$preamble .= "<A HREF=\"${prefix}$link_next_id\">[Next by ID]</A>\n";
    }
    else {
	$preamble .= "[No Next ID]\n";
    }

    if (defined $link_prev_thread_id) {
	$preamble .=
	    "<A HREF=\"${prefix}$link_prev_thread_id\">[Prev by Thread]</A>\n";
    }
    else {
	if (defined $link_prev_id) {
	    $preamble .=
		"<A HREF=\"${prefix}$link_prev_id\">[Prev by Thread]</A>\n";
	}
	else {
	    $preamble .= "[No Prev Thread]\n";
	}
    }

    if (defined $link_next_thread_id) {
	$preamble .=
	    "<A HREF=\"${prefix}$link_next_thread_id\">[Next by Thread]</A>\n";
    }
    else {
	if (defined $link_next_id) {
	    $preamble .=
		"<A HREF=\"${prefix}$link_next_id\">[Next by Thread]</A>\n";
	}
	else {
	    $preamble .= "[No Next Thread]\n";
	}
    }

    $preamble .= _format_index_navigator( { use_subdir => $use_subdir } );
    $preamble .= $preamble_end. "\n";;

    return $preamble;
}


# Descriptions: return footer without metachars
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub evaluate_safe_footer
{
    my ($self, $args) = @_;
    my $link_prev_id        = $args->{ link_prev_id };
    my $link_next_id        = $args->{ link_next_id };
    my $link_prev_thread_id = $args->{ link_prev_thread_id };
    my $link_next_thread_id = $args->{ link_next_thread_id };
    my $subject     = $args->{ subject };

    my $use_subdir = $self->{ _use_subdir } eq 'yes' ? 1 : 0;
    my $prefix     = $use_subdir ? '../' : '';
    my $footer     = $footer_begin. "\n";;

    if (defined($link_prev_id)) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"${prefix}$link_prev_id\">Prev by ID: ";
	if (defined $subject->{ prev_id } ) {
	    $footer .= _sprintf_safe_str( $subject->{ prev_id } );
	}
	$footer .= "</A>\n";
    }

    if (defined($link_next_id)) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"${prefix}$link_next_id\">Next by ID: ";
	if (defined $subject->{ next_id } ) {
	    $footer .= _sprintf_safe_str( $subject->{ next_id } );
	}
	$footer .= "</A>\n";
    }

    if (defined $link_prev_thread_id) {
	$footer .= "<BR>\n";
	$footer .=
	    "<A HREF=\"${prefix}$link_prev_thread_id\">Prev by Thread: ";
	if (defined $subject->{ prev_thread_id }) {
	    $footer .= _sprintf_safe_str($subject->{ prev_thread_id });
	}
	$footer .= "</A>\n";
    }

    if (defined $link_next_thread_id) {
	$footer .= "<BR>\n";
	$footer .=
	    "<A HREF=\"${prefix}$link_next_thread_id\">Next by Thread: ";
	if (defined $subject->{ next_thread_id }) {
	    $footer .= _sprintf_safe_str($subject->{ next_thread_id });
	}
	$footer .= "</A>\n";
    }

    $footer .= qq{<BR>\n};
    $footer .= _format_index_navigator( { use_subdir => $use_subdir } );
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
			   subdir
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


# Descriptions: open database
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: tied with $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub _db_open
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type } || $self->{ _db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    _PRINT_DEBUG("_db_open( type = $db_type )");

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
 	for my $db (@kind_of_databases) {
	    my $file = "$db_dir/.htdb_${db}";
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


# Descriptions: close database
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: untie $self->{ _db }
#         Todo: we should use IO::Adapter ?
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


# Descriptions: print navigation bar et.al. at upper half of indexes
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $new html
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


# Descriptions: print navigation bar et.al. at the end of indexes.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create $new html
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


# Descriptions: update index.html
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite index.html
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


# Descriptions: update monthly index
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite monthly index
# Return Value: none
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
	if (defined $month) {
	    $month_update{ $month } = 1;
	}
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


# Descriptions: update monthly index master
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite monthly_index.html
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

    for my $year (sort {$b <=> $a} @$years) {
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


# Descriptions: return list of YYYY/MM format
#    Arguments: ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub _yyyy_range
{
    my ($list) = @_;
    my ($yyyy) = {};

    for (@$list) {
	if (/^(\d{4})\/(\d{2})/) {
	    $yyyy->{ $1 } = $1;
	}
    }

    my (@yyyy) = keys %$yyyy;
    return( \@yyyy );
}


# Descriptions: sort YYYY/MM formt strings
#    Arguments: none
# Side Effects: none
# Return Value: NUM
sub __sort_yyyymm
{
    my ($xa, $xb) = ($a, $b);
    $xa =~ s@/@@;
    $xb =~ s@/@@;
    if ($xa eq '') { $xa = 0;}
    if ($xb eq '') { $xb = 0;}

    $xa <=> $xb;
}


# Descriptions: update month.YYYYMM.html
#    Arguments: OBJ($self) HASH_REF($args) HASH_REF($monthlyinfo)
# Side Effects: update month.YYYYMM.html
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


# Descriptions: update thread.html
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite thread.html
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


# Descriptions: check whether $id has next or previous link.
#    Arguments: OBJ($self) HASH_REF($db) NUM($id)
# Side Effects: none
# Return Value: 1 or 0
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


# Descriptions: print thread array of (head_id id2 id3 ...)
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($db) STR($head_id) STR($code)
# Side Effects: none
# Return Value: none
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


# Descriptions: cnvert charset to code e.g. iso-2022-jp => jis
#    Arguments: STR($charset)
# Side Effects: none
# Return Value: STR
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


# Descriptions: print raw $str to $wh channel
#    Arguments: HANDLE($wh) STR($str) STR($code)
# Side Effects: none
# Return Value: none
sub _print_raw_str
{
    my ($wh, $str, $code) = @_;
    $code = defined($code) ? $code : 'euc'; # euc-jp by default

    if (defined($str) && $str) {
	use Jcode;
	warn("code not specified") unless defined $code;
	&Jcode::convert( \$str, $code || 'euc');
    }

    print $wh $str;
}


# Descriptions: print safe $str to $wh channel
#               XXX text2html($str, urls => 1, pre => 0)
#    Arguments: HANDLE($wh) STR($str) STR($code)
# Side Effects: none
# Return Value: none
sub _print_safe_str
{
    my ($wh, $str, $code) = @_;
    __print_safe_str(0, $wh, $str, $code);
}


# Descriptions: print safe $str to $wh channel
#               XXX text2html($str, urls => 1, pre => 1)
#    Arguments: HANDLE($wh) STR($str) STR($code)
# Side Effects: none
# Return Value: none
sub _print_safe_buf
{
    my ($wh, $str, $code) = @_;
    __print_safe_str(1, $wh, $str, $code);
}


# Descriptions: print safe $str to $wh channel
#    Arguments: NUM($attr_pre) HANDLE($wh) STR($str) STR($code)
# Side Effects: none
# Return Value: none
sub __print_safe_str
{
    my ($attr_pre, $wh, $str, $code) = @_;
    my $p = __sprintf_safe_str($attr_pre, $wh, $str, $code);
    print $wh $p if defined $p;
    print $wh "\n";
}


# Descriptions: return safe $str
#    Arguments: STR($str) STR($code)
# Side Effects: none
# Return Value: STR
sub _sprintf_safe_str
{
    my ($str, $code) = @_;
    return __sprintf_safe_str(0, undef, $str, $code);
}


# Descriptions: return safe $str modified by text2html().
#               $str language code is modified by Jcode if needed.
#    Arguments: NUM($attr_pre) HANDLE($wh) STR($str) STR($code)
# Side Effects: none
# Return Value: STR or UNDEF
sub __sprintf_safe_str
{
    my ($attr_pre, $wh, $str, $code) = @_;
    my $rbuf = '';

    if (defined($str) && $str) {
	use Jcode;
	&Jcode::convert(\$str, defined($code) ? $code : 'euc' );
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


# Descriptions: extract URL syntax in $url string.
#               $url$trailor => $url $trailor for text2html()
#               XXX incomplete regexp, we should correct it.
#    Arguments: STR($url)
# Side Effects: none
#      History: based on fml 4.0-current (2001/10/28)
# Return Value: STR
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
	    printf STDERR "%-30s => %s\n", $k, $v;
	}
    }
}


=head2 internal utility functions for HTML TAGS

C<_print_something()> internal function provides wrapper to print HTML
tags et.al.

=cut


# Descriptions: print <UL> with proper indentation
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($db) STR($code)
# Side Effects: none
# Return Value: none
sub _print_ul
{
    my ($self, $wh, $db, $code) = @_;

    $self->{ _stack }++;

    my $padding = "   " x $self->{ _stack };
    _print_raw_str($wh, "${padding}<UL>\n", $code);
}


# Descriptions: print </UL> with proper indentation
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($db) STR($code)
# Side Effects: none
# Return Value: none
sub _print_end_of_ul
{
    my ($self, $wh, $db, $code) = @_;

    return unless $self->{ _stack } > 0;

    my $padding = "   " x $self->{ _stack };
    _print_raw_str($wh, "${padding}</UL>\n", $code);

    $self->{ _stack }--;
}


# Descriptions: print <LI> filename ... with proper indentation
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($db) STR($code)
# Side Effects: none
# Return Value: none
sub _print_li_filename
{
    my ($self, $wh, $db, $id, $code) = @_;
    my $filename = $db->{ _filename }->{ $id };
    my $subject  = $db->{ _subject }->{ $id };
    my $who      = $db->{ _who }->{ $id };

    if (defined $filename && $filename) {
	_print_raw_str($wh, "<!-- LI id=$id -->\n", $code);

	_print_raw_str($wh, "<LI>\n", $code);
	_print_raw_str($wh, "<A HREF=\"$filename\">\n", $code);
	_print_safe_str($wh, $subject, $code);
	_print_raw_str($wh, ",\n", $code);
	_print_safe_str($wh, "$who\n", $code);
	_print_raw_str($wh, "</A>\n", $code);
    }
}


=head2 misc

=cut


# Descriptions: clean up email address by Mail::Address.
#               return clean-up'ed address list.
#    Arguments: STR($addr)
# Side Effects: none
# Return Value: ARRAY_REF
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


# Descriptions: head of array (space separeted string)
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub _list_head
{
    my ($buf) = @_;
    $buf =~ s/^\s*//;
    $buf =~ s/\s*$//;
    return (split(/\s+/, $buf))[0];
}


# Descriptions: decode MIME-encoded $str
#    Arguments: OBJ($self) STR($str) HASH_REF($options)
# Side Effects: none
# Return Value: STR
sub _decode_mime_string
{
    my ($self, $str, $options) = @_;
    my $charset = $options->{ 'charset' } || $self->{ _charset };
    my $code    = _charset_to_code($charset) || 'euc';

    # If looks Japanese and $code is specified as Japanese, decode !
    if (defined($str) &&
	($str =~ /=\?ISO\-2022\-JP\?[BQ]\?/i) &&
	($code eq 'euc' || $code eq 'jis')) {
        if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) {
	    eval q{ use MIME::Base64; };
            $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
        }

        if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) {
	    eval q{ use MIME::QuotedPrint;};
            $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
        }

	if (defined($str) && $str) {
	    eval q{ use Jcode;};
	    my $icode = &Jcode::getcode(\$str);
	    warn("code not specified") unless defined $code;
	    warn("icode not specified") unless defined $icode;
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


# Descriptions: convert $file to HTML
#    Arguments: STR($file) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub htmlify_file
{
    my ($file, $args) = @_;
    my $dst_dir = $args->{ directory };

    unless (-f $file) {
	print STDERR "no such file: $file\n" if $debug;
	return;
    }

    unless (-s $file) {
	print STDERR "empty file: $file\n" if $debug;
	return;
    }

    use File::Basename;
    my $id   = basename($file);
    my $html = new Mail::Message::ToHTML {
	charset   => "euc-jp",
	directory => $dst_dir,
    };

    if ($debug) {
	printf STDERR "htmlify_file( id=%-6s src=%s )\n", $id, $file;
    }

    $html->htmlfy_rfc822_message({
	id  => $id,
	src => $file,
    });

    if ($debug) {
	printf STDERR "htmlify_file( id=%-6s ) update relation\n", $id;
    }
    $html->update_relation( $id );
    $html->update_id_monthly_index({ id => $id });
    $html->update_id_index({ id => $id });
    $html->update_thread_index({ id => $id });

    # no more action for old files
    if ($html->is_ignore($id)) {
	warn("not process $id (already exists)") if $debug;
    }
    else {
	printf STDERR "   converted( id=%-6s src=%s )\n", $id, $file;
    }
}


# Descriptions: convert all articles in specified directory
#    Arguments: STR($src_dir) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub htmlify_dir
{
    my ($src_dir, $args) = @_;
    my $dst_dir  = $args->{ directory };
    my $min      = 0;
    my $max      = 0;
    my $has_fork = 1; # ok on unix and perl>5.6 on wine32.

    print STDERR "src = $src_dir\ndst = $dst_dir\n" if $debug;

    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
      FILE:
	for my $file ( $dh->read() ) {
	    next FILE unless $file =~ /^\d+$/;

	    # initialize $min
	    unless ($min) { $min = $file;}

	    $max = $max < $file ? $file : $max;
	    $min = $min > $file ? $file : $min;
	}
    }

    # overwride
    $has_fork = $args->{ has_fork } if defined $args->{ has_fork };
    $max      = $args->{ max } if defined $args->{ max };

    print STDERR "   scan ( $min .. $max ) for $src_dir\n";
    for my $id ( $min .. $max ) {
	use File::Spec;
	my $file = File::Spec->catfile($src_dir, $id);

	unless ( $has_fork ) {
	    htmlify_file($file, { directory => $dst_dir });
	}
	else {
	    my $pid = fork();
	    if ($pid < 0) {
		croak("cannot fork");
	    }
	    elsif ($pid == 0) {
		htmlify_file($file, { directory => $dst_dir });
		exit 0;
	    }

	    # parent
	    my $dying;
	    while (($dying = wait()) != -1 && ($dying != $pid) ){
		;
	    }
	}
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $dir      = "/tmp/htdocs";
    my $has_fork = defined $ENV{'HAS_FORK'} ? 1 : 0;
    my $max      = defined $ENV{'MAX'} ? $ENV{'MAX'} : 1000;

    eval q{
	for my $x (@ARGV) {
	    if (-f $x) {
		htmlify_file($x, { directory => $dir });
	    }
	    elsif (-d $x) {
		htmlify_dir($x, {
		    directory => $dir,
		    has_fork  => $has_fork,
		    max       => $max,
		});
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

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::ToHTML appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
