#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ToHTML.pm,v 1.82 2006/04/15 06:33:01 fukachan Exp $
#

package Mail::Message::ToHTML;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $hints);
use Carp;

my $is_strict_warn = 0;
my $debug = 0;
my $URL   =
    "<A HREF=\"http://www.fml.org/software/\">Mail::Message::ToHTML</A>";

my $version = q$FML: ToHTML.pm,v 1.82 2006/04/15 06:33:01 fukachan Exp $;
my $versionid = 0;
if ($version =~ /,v\s+([\d\.]+)\s+/) {
    $versionid = "$1";
    $version = "$URL $versionid";
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

  $obj->htmlify_rfc822_message({
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
    html_start()               <HTML><HEAD> ... </HEAD><BODY>
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

=head2 new($args)

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

    $me->{ _charset }             = $args->{ charset } || 'us-ascii';
    $me->{ _html_base_directory } = $args->{ output_dir };
    $me->{ _db_type }             = $args->{ db_type };
    $me->{ _db_name }             = $args->{ db_name };
    $me->{ _db_base_dir }         = $args->{ db_base_dir };
    $me->{ _is_attachment }       = defined($args->{ attachment }) ? 1 : 0;
    $me->{ _args }                = $args;
    $me->{ _num_attachments }     = 0; # for child process
    $me->{ _use_subdir }          = 'yes';
    $me->{ _subdir_style }        = 'yyyymm';
    $me->{ _html_id_order }       = $args->{ index_order }  || 'normal';
    $me->{ _use_address_mask }    = $args->{ use_address_mask }  || 'yes';
    $me->{ _address_mask_type }   = $args->{ address_mask_type } || 'all';

    # global hints
    $hints                        = $args->{ hints } || {};

    use Mail::Message::Thread;
    my $t = new Mail::Message::Thread $args;
    $me->{ _thread_object } = $t;

    return bless $me, $type;
}


# Descriptions: destructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub DESTROY
{
    my ($self) = @_;

    _PRINT_DEBUG("ToHTML::DESTROY");
    1;
}


=head2 htmlify_rfc822_message($args)

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
sub htmlify_rfc822_message
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
    my ($id, $src, $dst) = $self->_init_htmlify_rfc822_message($args);
    $self->{ _debug_id } = $id;

    # target html exists already.
    if (-f $dst) {
	$self->{ _ignore_list }->{ $id } = 1; # ignore flag
	warn("html file for $id already exists") if $debug;
	return undef;
    }

    # save information for index.html and thread.html
    $self->cache_message_info($msg, { id  => $id,
				      src => $src,
				      dst => $dst,
				  } );

    # prepare output channel
    my $wh = $self->_set_output_channel( { dst => $dst } );
    unless (defined $wh) {
	croak("cannot open output file $dst\n");
    }

    # before main message
    $self->html_start($wh, { message => $msg });
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
		$text->htmlify_rfc822_message({
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
	    if ($self->{ _use_address_mask } eq 'yes') {
		$self->_text_plain_part_safe_print($wh, $m);
	    }
	    else {   # original
		$self->_text_safe_print({
		    fh       => $wh,                    # parent html
		    data     => $m->message_text(),
		    charset  => $m->charset(),
		    encoding => $m->encoding_mechanism(),
		});
	    }
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
    my $mask = umask();

    umask(022);

    use FileHandle;
    my $rh = new FileHandle $inf;
    my $wh = new FileHandle "> $outf";
    if (defined $rh) {
	my $buf = '';

	my $b;
	while ($b = <$rh>) { $buf .= $b;}

	_print_safe_buf($wh, $buf);
	$wh->close;
	$rh->close;
    }

    umask($mask);
}


# Descriptions: return HTML filename
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR or UNDEF
sub html_filename
{
    my ($self, $id) = @_;
    my $use_subdir = $self->{ _use_subdir };

    # relative path under html_base_dir
    if (defined($id) && ($id > 0)) {
	if ($use_subdir eq 'yes') {
	    return $self->_html_file_subdir_name($id);
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
    my $ndb           = $self->ndb();
    my $subdir        = '';
    my $html_base_dir = $self->{ _html_base_directory };
    my $subdir_style  = $self->{ _subdir_style };
    my $dir_mode      = $self->{ _dir_mode } || 0755;

    if ($subdir_style eq 'yyyymm') {
	my $hdr = $self->{ _current_hdr  };
	use Mail::Message::Utils;
	$subdir = Mail::Message::Utils::get_time_from_header($hdr, 'yyyymm');

	use File::Spec;
	my $xsubdir = File::Spec->catfile($html_base_dir, $subdir);
	unless (-d $xsubdir) {
	    my $mask = umask();
	    umask(022);
	    mkdir($xsubdir, $dir_mode);
	    umask($mask);
	}
    }
    else {
	croak("unknown \$subdir_style");
    }

    if ($subdir) {
	use File::Spec;
	return File::Spec->catfile($subdir, "msg$id.html");
    }
    else {
	warn("not create msg$id.html");
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
sub _init_htmlify_rfc822_message
{
    my ($self, $args) = @_;
    my ($id, $src, $dst);

    if (defined $args->{ src }) {
	$src = $args->{ src };
    }
    else {
	croak("htmlify_rfc822_message: \$src is mandatory\n");
    }

    if (defined $args->{ id }) {
	my $html_base_dir = $self->{ _html_base_directory };
	$id  = $args->{ id };
	$dst = $self->html_filepath($id);
    }
    # this object is an attachment if parent_id is specified.
    elsif (defined $args->{ parent_id }) {
	$self->{ _num_attachments }++;
	$id  = $args->{ parent_id } .'.'. $self->{ _num_attachments };
	$dst = $args->{ dst };
    }
    # last resort: give unique identifier
    elsif (defined $args->{ dst }) {
	$id  = sprintf("%s.%s", time, $$);
	$dst = $args->{ dst };
    }
    # oops ;) wrong call of this function
    else {
	croak("htmlify_rfc822_message: specify \$id or \$dst\n");
    }

    return ($id, $src, $dst);
}


# Descriptions: show html header + file title in <BODY>
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($self, $wh, $args) = @_;
    my ($msg, $hdr, $title);

    if (defined $args->{ title }) {
	$title = $args->{ title };
    }
    elsif (defined $args->{ message }) {
	$msg   = $args->{ message };
	$hdr   = $msg->whole_message_header;
	$title = $self->_decode_mime_string( $hdr->get('article_subject') ||
					$hdr->get('subject') );
    }

    print $wh "<!-- X-FML 8 ToHTML $versionid -->\n";
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
    my $wh  = undef;

    my $mask = umask();
    umask(022);

    if (defined $dst) {
	use FileHandle;
	$wh = new FileHandle "> $dst";
    }
    else {
	$wh = \*STDOUT;
    }

    umask($mask);

    return $wh;
}


# Descriptions: return temporary file path.
#               XXX temporary file is created under $db_dir not public space
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub _create_temporary_filename
{
    my ($self) = @_;
    my $html_base_dir = $self->{ _html_base_directory };

    use File::Spec;
    return File::Spec->catfile($html_base_dir, "tmp.$$");
}


# Descriptions: create a temporary file with the content $msg
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: create $tmpf file
# Return Value: STR
sub _create_temporary_file_in_raw_mode
{
    my ($self, $msg) = @_;
    my $tmpf = $self->_create_temporary_filename();
    my $mask = umask();
    umask(022);

    use FileHandle;
    my $wh = new FileHandle "> $tmpf";
    if (defined $wh) {
	$wh->autoflush(1);

	my $buf = $msg->message_text();
	$wh->print($buf);
	$wh->close;

	umask($mask);
	return ($tmpf);
    }

    umask($mask);
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
	print $wh "<BR><IMG SRC=\"../$file\">$desc\n";
    }
    else {
	my $t = $file;
	print $wh "<BR><A HREF=\"../$file\" TARGET=\"$t\"> $type $num </A>";
	print $wh "$desc<BR>\n";
    }
}


# Descriptions: return attachment filename
#    Arguments: STR($dst) STR($attach) STR($suffix)
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
my @header_field = qw(From To Cc Subject Date Message-Id X-Sequence);


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

    my $mimeopt = $main::opt_mimedecodequoted;
    $main::opt_mimedecodequoted = 1;

    # header
    $buf .= "<SPAN CLASS=mailheaders>\n";
    for my $field (@$header_field) {
	if (defined($hdr->get($field))) {
	    $buf .= "<SPAN CLASS=${field}>\n";
	    $buf .= "${field}: ";
	    $buf .= "</SPAN>\n";

	    my $xbuf = $hdr->get($field);

	    # mask the raw address against address collector (e.g. spammer).
	    if ($self->{ _use_address_mask } eq 'yes') {
		if ($self->_is_mask_address($field)) {
		    $xbuf = $self->_address_to_gecos($xbuf);
		}
	    }

	    $xbuf = $self->_decode_mime_string($xbuf) if $xbuf =~ /=\?/i;
	    $buf .= "<SPAN CLASS=${field}-value>\n";
	    $buf   .= _sprintf_safe_str($xbuf);
	    $buf .= "</SPAN>\n";
	    $buf .= "<BR>\n";
	}
    }
    $buf .= "</SPAN>\n";

    $main::opt_mimedecodequoted = $mimeopt;
    return($buf);
}


my @indexs = qw(all thread month month_thread top);

# Descriptions: show link to indexes as navigation
#    Arguments: HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _format_index_navigator
{
    my ($args) = @_;
    my $use_subdir = defined $args->{use_subdir} ? $args->{use_subdir} : 0;
    my $prefix = $use_subdir ? '../' : '';
    my $str;
    my $indexs = \@indexs;

    for my $index (@$indexs) {
	$str .= qq{<A HREF=\"${prefix}index_all.html\">[ID Index]</A>\n} if ($index eq "all");
	$str .= qq{<A HREF=\"${prefix}thread.html\">[Thread Index]</A>\n} if ($index eq "thread");
	$str .= qq{<A HREF=\"${prefix}monthly_index.html\">[Monthly ID Index]</A>\n} if ($index eq "month");
	$str .= qq{<A HREF=\"${prefix}monthly_thread.html\">[Monthly Thread Index]</A>\n} if ($index eq "month_thread");
	$str .= qq{<A HREF=\"${prefix}index.html\">[Top Index]</A>\n} if ($index eq "top");
    };

return $str;
}


# Descriptions: print text/plain part by printing each paragraph.
#               mask raw mail addresses in the signature if could.
#    Arguments: OBJ($self) HANDLE($wh) OBJ($m)
# Side Effects: none
# Return Value: STR
sub _text_plain_part_safe_print
{
    my ($self, $wh, $m) = @_;
    my $total = $m->paragraph_total();

    # print each paragraph.
    for (my $i = 1; $i <= $total ; $i++) {
	my $buf = $m->nth_paragraph($i);

	# try to hide domain since the last paragraph must be signature.
	if ($self->{ _use_address_mask } eq 'yes') {
	    if ($i == $total) {
		$buf =~ s/(\w+\@[\w\.]+)/$self->_address_to_gecos($1)/ge;
	    }
	}

	$self->_text_safe_print({
	    fh       => $wh,                    # parent html
	    data     => $buf,
	    charset  => $m->charset(),
	    encoding => $m->encoding_mechanism(),
	});
    }
}


# Descriptions: print out text data with escaping by _print_safe_buf()
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub _text_safe_print
{
    my ($self, $args) = @_;
    my $buf      = $args->{ data };
    my $fh       = $args->{ fh } || \*STDOUT;
    my $in_code  = $args->{ charset }  || undef;
    my $encoding = $args->{ encoding } || '7bit';

    if ($encoding eq 'base64') {
	use Mail::Message::Encode;
	my $encode = new Mail::Message::Encode;
	$buf = $encode->decode_base64_string($buf);
    }
    elsif ($encoding eq 'quoted-printable') {
	use Mail::Message::Encode;
	my $encode = new Mail::Message::Encode;
	$buf = $encode->decode_qp_string($buf);
    }

    # XXX-TODO: euc-jp is hard-coded.
    if (defined $buf && $buf) {
	$buf = $self->_convert($buf, 'euc');
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
	my $mask = umask();
	umask(022);

	my $outf = $args->{ file };
	use FileHandle;
	my $fh = new FileHandle "> $outf";

	# XXX-TODO: euc-jp is hard-coded.
	if (defined $buf && $buf) {
	    $buf = $self->_convert($buf, 'euc');
	}
	print $fh $buf, "\n";
	$fh->close();

	umask($mask);
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
    my $enc  = $msg->encoding_mechanism || '';
    my $mask = umask();

    umask(022);

    if (defined( $args->{ file } )) {
	my $outf = $args->{ file };
	use FileHandle;
	my $fh = new FileHandle "> $outf";

	if (defined $fh) {
	    $fh->autoflush(1);
	    binmode($fh);

	    use Mail::Message::Encode;
	    my $encode = new Mail::Message::Encode;
	    if ($enc eq 'base64') {
		print $fh $encode->raw_decode_base64( $msg->message_text() );
	    }
	    elsif ($enc eq 'quoted-printable') {
		print $fh $encode->raw_decode_qp( $msg->message_text() );
	    }
	    elsif ($enc eq '7bit') {
		_print_safe_str($fh, $msg->message_text());
	    }
	    else {
		my $r = "*** unknown MIME encoding enc='$enc' ***\n";
		_print_safe_str($fh, $r);
		_print_safe_str($fh, $msg->message_text());
	    }

	    $fh->close();
	}
    }

    umask($mask);
}


=head2 is_ignore($id)

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

=head2 cache_message_info($msg, $args)

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
    my $ndb = $self->ndb();
    my $id  = $args->{ id };
    my $src = $args->{ src };
    my $dst = $args->{ dst };

    $ndb->set_key($id);

    $ndb->set('html_filename', $id, $self->html_filename($id));
    $ndb->set('html_filepath', $id, $dst);

    unless ($ndb->get('message_id', $id)) {
	# analyze $msg only if not yet analyzed.
	print STDERR "debug: analyze $id.\n" if $debug;
	$ndb->add($msg);
    }
    else {
	print STDERR "debug: already analyzed!\n" if $debug;
    }
}


# Descriptions: return Mail::Message::DB object.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub ndb
{
    my ($self) = @_;
    my $t = $self->{ _thread_object };

    return $t->db();
}


=head2 update_msg_html_links($id)

update link relation around C<$id>.

=cut


# Descriptions: top level dispatcher to update database.
#               _msg_file_rewrite_links() has real function for updating.
#    Arguments: OBJ($self) STR($id)
# Side Effects: update databse
# Return Value: none
sub update_msg_html_links
{
    my ($self, $id) = @_;
    my $info = $self->evaluate_links_relation($id);
    my $list = $self->{ _affected_idlist } = [];

    if ($self->is_ignore($id)) {
	warn("not update relation around $id") if $debug;
	return undef;
    }

    # sanity
    return unless defined $id;
    return unless $id;

    # update target itself, of course
    $self->_msg_file_rewrite_links($id);
    push(@$list, $id);

    # no rewriting for myself
    my %uniq = ( $id => 1 );

  KEY:
    for my $_link (qw(prev_id next_id prev_thread_id next_thread_id)) {
	if (defined $info->{ $_link }) {
	    my $_id = $info->{ $_link };

	    next KEY if $uniq{ $_id };
	    $uniq{ $_id } = 1;

	    _PRINT_DEBUG("try: rewrite $_link links in msg $_id");

	    if (defined $_id && $_id) {
		$self->_msg_file_rewrite_links($_id);
		push(@$list, $_id);
	    }
	}
	else {
	    _PRINT_DEBUG("error: fail to rewrite msg $_link");
	}
    }

    # hint cached on memory, provided by _print_thread().
    if (defined $self->{ _hint_ref_key_list }->{ $id }) {
	my $thread_list = $self->{ _hint_ref_key_list }->{ $id } || [];

	# update link relation for all articles in this thread.
      KEY:
	for my $id (@$thread_list) {
	    next KEY if $uniq{ $id};
	    $uniq{ $id } = 1;

	    $self->_msg_file_rewrite_links( $id );
	    push(@$list, $id);
	}
    }
}


# Descriptions: update link at preamble and footer of HTML-ified message.
#    Arguments: OBJ($self) STR($id)
# Side Effects: rewrite index file
# Return Value: none
sub _msg_file_rewrite_links
{
    my ($self, $id) = @_;
    my $info     = $self->evaluate_links_relation($id);
    my $preamble = $self->evaluate_safe_preamble($info);
    my $footer   = $self->evaluate_safe_footer($info);
    my $code     = _charset_to_code($self->{ _charset });

    my $pat_preamble_begin = quotemeta($preamble_begin);
    my $pat_preamble_end   = quotemeta($preamble_end);
    my $pat_footer_begin   = quotemeta($footer_begin);
    my $pat_footer_end     = quotemeta($footer_end);

    my $mask = umask();

    umask(022);

    _PRINT_DEBUG("try _msg_file_rewrite_links($id)");

    use FileHandle;
    my $file = $info->{ filepath };
    if (defined $file && $file && -f $file) {
	my ($old, $new) = ($file, "$file.new.$$");
	my $rh = new FileHandle $old;
	my $wh = new FileHandle "> $new";

	if (defined $rh && defined $wh) {
	    my $buf;

	    _PRINT_DEBUG("rewrite: open msg $id");

	  LINE:
	    while ($buf = <$rh>) {
		if ($buf =~ /^$pat_preamble_begin/
		      ..
		    $buf =~ /^$pat_preamble_end/) {
		    if ($buf =~ /^$pat_preamble_end/) {
			_print_raw_str($wh, $preamble, $code);
		    }
		    next LINE;
		}

		if ($buf =~ /^$pat_footer_begin/
		     ..
		    $buf =~ /^$pat_footer_end/) {
		    if ($buf =~ /^$pat_footer_end/) {
			_print_raw_str($wh, $footer, $code);
		    }
		    next LINE;
		}

		# just copy (rewrite only $preamble and $footer not message)
		_print_raw_str($wh, $buf, $code);
	    }
	    $rh->close;
	    $wh->close;

	    unless (rename($new, $old)) {
		croak("rename($new, $old) fail (id=$id)\n");
	    }
	    else {
		_PRINT_DEBUG("done: rewritten links in msg $id");
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

    umask($mask);
}


# Descriptions: return thread link relation info et.al. for $id
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: HASH_REF
sub evaluate_links_relation
{
    my ($self, $id) = @_;
    my $ndb = $self->ndb();

    return $ndb->get_tohtml_thread_summary($id);
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

    my $mask = umask();

    umask(022);

    # for debug
    $preamble .= "<!-- rewritten for id=$self->{ _debug_id } -->\n";

    if (defined($link_prev_id) && $link_prev_id) {
	$preamble .= "<A HREF=\"${prefix}$link_prev_id\">[Prev by ID]</A>\n";
    }
    else {
	$preamble .= "[No Prev ID]\n";
    }

    if (defined($link_next_id) && $link_next_id) {
	$preamble .= "<A HREF=\"${prefix}$link_next_id\">[Next by ID]</A>\n";
    }
    else {
	$preamble .= "[No Next ID]\n";
    }

    if (defined $link_prev_thread_id && $link_prev_thread_id) {
	$preamble .=
	    "<A HREF=\"${prefix}$link_prev_thread_id\">[Prev by Thread]</A>\n";
    }
    else {
	if (defined $link_prev_id && $link_prev_id) {
	    $preamble .=
		"<A HREF=\"${prefix}$link_prev_id\">[Prev by Thread]</A>\n";
	}
	else {
	    $preamble .= "[No Prev Thread]\n";
	}
    }

    if (defined $link_next_thread_id && $link_next_thread_id) {
	$preamble .=
	    "<A HREF=\"${prefix}$link_next_thread_id\">[Next by Thread]</A>\n";
    }
    else {
	if (defined $link_next_id && $link_next_id) {
	    $preamble .=
		"<A HREF=\"${prefix}$link_next_id\">[Next by Thread]</A>\n";
	}
	else {
	    $preamble .= "[No Next Thread]\n";
	}
    }

    $preamble .= _format_index_navigator( { use_subdir => $use_subdir } );
    $preamble .= $preamble_end. "\n";;

    umask($mask);

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

    if (defined($link_prev_id) && $link_prev_id) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"${prefix}$link_prev_id\">Prev by ID: ";
	if (defined $subject->{ prev_id } ) {
	    $footer .= _sprintf_safe_str( $subject->{ prev_id } );
	}
	$footer .= "</A>\n";
    }

    if (defined($link_next_id) && $link_next_id) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"${prefix}$link_next_id\">Next by ID: ";
	if (defined $subject->{ next_id } ) {
	    $footer .= _sprintf_safe_str( $subject->{ next_id } );
	}
	$footer .= "</A>\n";
    }

    if (defined $link_prev_thread_id && $link_prev_thread_id) {
	$footer .= "<BR>\n";
	$footer .=
	    "<A HREF=\"${prefix}$link_prev_thread_id\">Prev by Thread: ";
	if (defined $subject->{ prev_thread_id }) {
	    $footer .= _sprintf_safe_str($subject->{ prev_thread_id });
	}
	$footer .= "</A>\n";
    }
    elsif (defined($link_prev_id) && $link_prev_id) {
	$footer .= "<BR>\n";
	$footer .=
	    "<A HREF=\"${prefix}$link_prev_id\">Prev by Thread: ";
	if (defined $subject->{ prev_id }) {
	    $footer .= _sprintf_safe_str($subject->{ prev_id });
	}
	$footer .= "</A>\n";
    }

    if (defined $link_next_thread_id && $link_next_thread_id) {
	$footer .= "<BR>\n";
	$footer .=
	    "<A HREF=\"${prefix}$link_next_thread_id\">Next by Thread: ";
	if (defined $subject->{ next_thread_id }) {
	    $footer .= _sprintf_safe_str($subject->{ next_thread_id });
	}
	$footer .= "</A>\n";
    }
    elsif (defined($link_next_id) && $link_next_id) {
	$footer .= "<BR>\n";
	$footer .=
	    "<A HREF=\"${prefix}$link_next_id\">Next by Thread: ";
	if (defined $subject->{ next_id }) {
	    $footer .= _sprintf_safe_str($subject->{ next_id });
	}
	$footer .= "</A>\n";
    }

    $footer .= qq{<BR>\n};
    $footer .= _format_index_navigator( { use_subdir => $use_subdir } );
    $footer .= $footer_end. "\n";;

    return $footer;
}


=head2 update_id_index($args)

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

    my $mask = umask();

    umask(022);

    use FileHandle;
    my $wh = new FileHandle "> $new";
    $args->{ wh } = $wh;

    $self->html_start($wh, { title => $title });

    _print_raw_str($wh, _format_index_navigator(), $code);
    $self->mhl_separator($wh);

    umask($mask);
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

# Descriptions: create Top index.html if no index.html
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create Top index.html
# Return Value: none
sub create_top_index
{
    my ($self, $args) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $order         = $self->{ _html_id_order } || 'normal';
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "Top Index",
	old   => "$html_base_dir/index.html",
	new   => "$html_base_dir/index.html.new.$$",
	code  => $code,
    };

    return if ( -f $htmlinfo-> { old } );

    $self->_print_index_begin( $htmlinfo );
    my $wh = $htmlinfo->{ wh };

    $self->_print_index_end( $htmlinfo );
}


# Descriptions: update index_all.html
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite index_all.html
# Return Value: none
sub update_id_index
{
    my ($self, $args) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $order         = $self->{ _html_id_order } || 'normal';
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "ID Index",
	old   => "$html_base_dir/index_all.html",
	new   => "$html_base_dir/index_all.html.new.$$",
	code  => $code,
    };

    if ($self->is_ignore($args->{id})) {
	warn("not update index_all.html around $args->{id}") if $debug;
	return undef;
    }

    $self->_print_index_begin( $htmlinfo );
    my $wh     = $htmlinfo->{ wh };
    my $db     = $self->ndb();
    my $max_id = $db->get('hint', 'max_id');

    $self->_print_ul($wh, $db, $code);
    if ($order eq 'reverse') {
	for my $id (reverse (1 .. $max_id)) {
	    $self->_print_li_filename($wh, $db, $id, $code);
	}
    }
    else {
	for my $id (1 .. $max_id) {
	    $self->_print_li_filename($wh, $db, $id, $code);
	}
    }
    $self->_print_end_of_ul($wh, $db, $code);

    $self->_print_index_end( $htmlinfo );
}


=head2 update_monthly_id_index($args)

=cut


# Descriptions: update monthly index
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite monthly index
# Return Value: none
sub update_monthly_id_index
{
    my ($self, $args) = @_;
    my $affected_list = $self->{ _affected_idlist };

    if ($self->is_ignore($args->{id})) {
	warn("not update index.html around $args->{id}") if $debug;
	return undef;
    }

    # open databaes
    my $db = $self->ndb();
    my %month_update = ();

  IDLIST:
    for my $id (@$affected_list) {
	next IDLIST unless $id =~ /^\d+$/o;
	next IDLIST     if $id =~ /^\s*$/o;

	my $month = $db->get('month', $id);
	if (defined $month && $month !~ /^\s*$/o) {
	    $month_update{ $month } = 1;
	}
    }

    # todo list
    for my $month (sort keys %month_update) {
	my $this_month = $month;                     # yyyy/mm
	my $suffix     = $month; $suffix =~ s@/@@go; # yyyymm

	$self->_update_monthly_id_index($args, {
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

    use File::Spec;
    my $old = File::Spec->catfile($html_base_dir, "monthly_index.html");
    my $new = File::Spec->catfile($html_base_dir, "monthly_index.html.new.$$");
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "ID Index",
	old   => $old,
	new   => $new,
	code  => $code,
    };

    $self->_print_index_begin( $htmlinfo );
    my $wh      = $htmlinfo->{ wh };
    my $db      = $self->ndb();
    my $mlist   = $db->get_table_as_hash_ref('inv_month'); # month => (id ...)
    my (@list)  = sort __sort_yyyymm keys %$mlist;
    my ($years) = _yyyy_range(\@list);

    _print_raw_str($wh, "<table border='1'>", $code);

    for my $year (sort {$b <=> $a} @$years) {
	_print_raw_str($wh, "<tr>", $code);
	_print_raw_str($wh, "<th> $year </th>", $code);

	for my $month (1 .. 12) {
	    my $xx = sprintf("%04d%02d",  $year, $month); # YYYYMM
	    my $fn = "month.$xx.html";

	    use File::Spec;
	    my $file = File::Spec->catfile($html_base_dir, $fn);
	    if (-f $file) {
		_print_raw_str($wh, "<td><a href=\"$fn\"> $month </a>", $code);
	    }
	    else {
		_print_raw_str($wh, "<td>", $code);
	    }
	    _print_raw_str($wh, "</td>", $code);
	}
	_print_raw_str($wh, "</tr>", $code);
    }
    _print_raw_str($wh, "</table>", $code);

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

    for my $y (@$list) {
	if ($y =~ /^(\d{4})\/(\d{2})/o) {
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
sub _update_monthly_id_index
{
    my ($self, $args, $monthlyinfo) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $this_month    = $monthlyinfo->{ this_month }; # yyyy/mm
    my $suffix        = $monthlyinfo->{ suffix };     # yyyymm
    my $order         = $self->{ _html_id_order } || 'normal';
    my $htmlinfo = {
	title => "ID Monthly Index $this_month",
	old   => "$html_base_dir/month.${suffix}.html",
	new   => "$html_base_dir/month.${suffix}.html.new.$$",
	code  => $code,
    };

    $self->_print_index_begin( $htmlinfo );
    my $wh     = $htmlinfo->{ wh };
    my $db     = $self->ndb();
    my $max_id = $db->get('hint', 'max_id');
    my $list   = $db->get_as_array_ref('inv_month', $this_month);

    # debug information (it is useful not to remove this ?)
    _print_raw_str($wh, "<!-- this month ids=(@$list) -->\n", $code);

    $self->_print_ul($wh, $db, $code);
    if ($order eq 'reverse') {
      ID:
	for my $id (reverse sort {$a <=> $b} @$list) {
	    next ID unless $id =~ /^\d+$/o;
	    $self->_print_li_filename($wh, $db, $id, $code);
	}
    }
    else {
      ID:
	for my $id (sort {$a <=> $b} @$list) {
	    next ID unless $id =~ /^\d+$/o;
	    $self->_print_li_filename($wh, $db, $id, $code);
	}
    }
    $self->_print_end_of_ul($wh, $db, $code);

    $self->_print_index_end( $htmlinfo );
}


=head2 update_thread_index($args)

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
    my $order         = $self->{ _html_id_order } || 'normal';
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
    my $wh     = $htmlinfo->{ wh };
    my $db     = $self->ndb();
    my $max_id = $db->get('hint', 'max_id');

    # initialize negagtive cache to ensure uniquness
    delete $self->{ _uniq };

    $self->_print_ul($wh, $db, $code);
    for my $id ( 1 .. $max_id ) {
	# head of the thread (not referenced yet)
	unless (defined $self->{ _uniq }->{ $id }) {
	    $self->_print_thread($wh, $db, $id, $code);
	}
    }
    $self->_print_end_of_ul($wh, $db, $code);

    $self->_print_index_end( $htmlinfo );
}


# Descriptions: check whether $id has next or previous link.
#    Arguments: OBJ($self) HASH_REF($db) NUM($id)
# Side Effects: none
# Return Value: 1 or 0
sub _has_link
{
    my ($self, $db, $id) = @_;

    if ($db->get('next_key', $id) || $db->get('prev_key', $id)) {
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
    my $uniq              = $self->{ _uniq };

    # get id list: @idlist = ( $head_id id2 id3 ... )
    my $ndb = $self->ndb();
    my $buf = $ndb->get('ref_key_list', $head_id);

    # debug information (it is useful not to remove this ?)
    _print_raw_str($wh, "<!-- thread head=$head_id ($buf) -->\n", $code);

    my $idlist = $ndb->get_as_array_ref('ref_key_list', $head_id);
    if (@$idlist) {
      IDLIST:
	for my $id (@$idlist) {
	    # save $head_id => "id1 id2 id3 ..." on memory for further use.
	    # "> 1" implies idlist contains others than myself.
	    if ($#$idlist > 1) {
		my $ra = $ndb->get_as_array_ref('ref_key_list', $head_id);
		$self->{ _hint_ref_key_list }->{ $id } = $ra;
	    }

	    # @$idlist = (number's)
	    _print_raw_str($wh, "<!-- thread (@$idlist) -->\n", $code);

	    next IDLIST if $uniq->{ $id };
	    $uniq->{ $id } = 1;

	    $self->_print_ul($wh, $db, $code);

	    # oops, we should ignore head of the thread ( myself ;-)
	    if (($id != $head_id) && $self->_has_link($db, $id)) {
		_print_raw_str($wh, "<!-- thread $id has link -->\n", $code);
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

=head2 update_monthly_thread_index($args)

=cut

# Descriptions: update monthly thread index
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite monthly thread index
# Return Value: none
sub update_monthly_thread_index
{
    my ($self, $args) = @_;
    my $affected_list = $self->{ _affected_idlist };

    if ($self->is_ignore($args->{id})) {
	warn("not update monthly_thread.html around $args->{id}") if $debug;
	return undef;
    }

    # open databaes
    my $db = $self->ndb();
    my %month_update = ();

  IDLIST:
    for my $id (@$affected_list) {
	next IDLIST unless $id =~ /^\d+$/o;
	next IDLIST     if $id =~ /^\s*$/o;

	my $month = $db->get('month', $id);
	if (defined $month && $month !~ /^\s*$/o) {
	    $month_update{ $month } = 1;
	}
    }

    # todo list
    for my $month (sort keys %month_update) {
	my $this_month = $month;                     # yyyy/mm
	my $suffix     = $month; $suffix =~ s@/@@go; # yyyymm

	$self->_update_monthly_thread_index($args, {
	    this_month => $this_month,
	    suffix     => $suffix,
	});
    }

    # update monthly_index.html
    $self->_update_montly_thread_index_master($args);
}


# Descriptions: update monthly thread index master
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: rewrite monthly_thread.html
# Return Value: none
sub _update_montly_thread_index_master
{
    my ($self, $args) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });

    use File::Spec;
    my $old = File::Spec->catfile($html_base_dir, "monthly_thread.html");
    my $new = File::Spec->catfile($html_base_dir, "monthly_thread.html.new.$$");
    my $htmlinfo = {
	title => defined($args->{ title }) ? $args->{ title } : "Thread Index",
	old   => $old,
	new   => $new,
	code  => $code,
    };

    $self->_print_index_begin( $htmlinfo );
    my $wh      = $htmlinfo->{ wh };
    my $db      = $self->ndb();
    my $mlist   = $db->get_table_as_hash_ref('inv_month'); # month => (id ...)
    my (@list)  = sort __sort_yyyymm keys %$mlist;
    my ($years) = _yyyy_range(\@list);

    _print_raw_str($wh, "<TABLE>", $code);

    for my $year (sort {$b <=> $a} @$years) {
	_print_raw_str($wh, "<TR>", $code);

	for my $month (1 .. 12) {
	    _print_raw_str($wh, "<TR>", $code) if $month == 7;

	    my $id = sprintf("%04d/%02d", $year, $month); # YYYY/MM
	    my $xx = sprintf("%04d%02d",  $year, $month); # YYYYMM
	    my $fn = "thread.$xx.html";

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

    $self->_print_index_end( $htmlinfo );
}


# Descriptions: update thread.YYYYMM.html
#    Arguments: OBJ($self) HASH_REF($args) HASH_REF($monthlyinfo)
# Side Effects: update thread.YYYYMM.html
# Return Value: none
sub _update_monthly_thread_index
{
    my ($self, $args, $monthlyinfo) = @_;
    my $html_base_dir = $self->{ _html_base_directory };
    my $code          = _charset_to_code($self->{ _charset });
    my $this_month    = $monthlyinfo->{ this_month }; # yyyy/mm
    my $suffix        = $monthlyinfo->{ suffix };     # yyyymm
    my $order         = $self->{ _html_id_order } || 'normal';
    my $htmlinfo = {
	title => "Monthly Thread Index $this_month",
	old   => "$html_base_dir/thread.${suffix}.html",
	new   => "$html_base_dir/thread.${suffix}.html.new.$$",
	code  => $code,
    };

    $self->_print_index_begin( $htmlinfo );
    my $wh     = $htmlinfo->{ wh };
    my $db     = $self->ndb();
    my $max_id = $db->get('hint', 'max_id');
    my $list   = $db->get_as_array_ref('inv_month', $this_month);

    # initialize negagtive cache to ensure uniquness
    delete $self->{ _uniq };

    # debug information (it is useful not to remove this ?)
    _print_raw_str($wh, "<!-- this month ids=(@$list) -->\n", $code);

    $self->_print_ul($wh, $db, $code);
    for my $id (sort {$a <=> $b} @$list) {
	# head of the thread (not referenced yet)
	unless (defined $self->{ _uniq }->{ $id }) {
	    $self->_print_thread($wh, $db, $id, $code);
	}
    }
    $self->_print_end_of_ul($wh, $db, $code);

    $self->_print_index_end( $htmlinfo );
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

    # XXX-TODO: euc-jp is hard-coded.
    if (defined($str) && $str) {
	$str = __nc_convert($str, $code || 'euc');
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
#               $str language code is modified by Mail::Message::Encode.
#    Arguments: NUM($attr_pre) HANDLE($wh) STR($str) STR($code)
# Side Effects: none
# Return Value: STR or UNDEF
sub __sprintf_safe_str
{
    my ($attr_pre, $wh, $str, $code) = @_;
    my $regexp = $hints->{ subject_tag_regexp } || '';
    my $rbuf   = '';

    # XXX-TODO: euc-jp is hard-coded.
    if (defined($str) && $str) {
	$str = __nc_convert($str, $code || 'euc');
    }

    if (defined $str) {
	# $url$trailor => $url $trailor for text2html() incomplete regexp
	$str =~ s#(http://[^\s\<\>\'\"]+[\w\d/])#_separete_url($1)#ge;

	use HTML::FromText;
	# NOT CONVERT subject tag (see fml-devel:726).
	if ($str =~ /^\s*($regexp)(.*)/) {
	    my ($tag, $post) = ($1, $2);
	    my $tag_s  = text2html($tag,  urls => 0, pre => $attr_pre);
	    my $post_s = text2html($post, urls => 1, pre => $attr_pre);
	    return sprintf("%s%s", $tag_s, $post_s);
	}
	else {
	    return text2html($str, urls => 1, pre => $attr_pre);
	}
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
#    Arguments: OBJ($self) HANDLE($wh) HASH_REF($db) NUM($id) STR($code)
# Side Effects: none
# Return Value: none
sub _print_li_filename
{
    my ($self, $wh, $db, $id, $code) = @_;
    my $filename = $db->get('html_filename', $id);
    my $subject  = $db->get('article_subject', $id) ||
			$db->get('subject', $id) || "no subject";
    my $who      = $db->get('who', $id) || "no sender";
    if ($self->{ _use_address_mask } ne 'yes' &&
	$db->get('from', $id) ne '') {
	$who	 = "" if ($who =~ /\@xxx/);
	$who	.= " " . $db->get('from', $id);
    }

    my $mimeopt = $main::opt_mimedecodequoted;
    $main::opt_mimedecodequoted = 1;
    $subject = $self->_decode_mime_string($subject) if $subject =~ /=\?/i;
    $who = $self->_decode_mime_string($who) if $who =~ /=\?/i;
    $main::opt_mimedecodequoted = $mimeopt;

    _PRINT_DEBUG("-- print_li_filename id=$id file=$filename");

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


# Descriptions: extrace gecos field in $address
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: STR
sub _address_to_gecos
{
    my ($self, $address) = @_;

    use Mail::Message::Utils;
    return Mail::Message::Utils::from_address_to_name($address);
}


# Descriptions: mask the detail of address
#    Arguments: OBJ($self) STR($field)
# Side Effects: none
# Return Value: NUM
sub _is_mask_address
{
    my ($self, $field) = @_;
    my $type = $self->{ _address_mask_type } || 'all';

    if ($type eq 'all') {
	if ($field =~ /^(From|To|Cc)$/i) {
	    return 1;
	}
	else {
	    return 0;
	}
    }
    else {
	return 0;
    }
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

    if (defined($str) && $str) {
	use Mail::Message::Encode;
	my $encode = new Mail::Message::Encode;
	return $encode->decode_mime_string($str, $code);
    }

    return $str;
}


# Descriptions: convert $str to $out_code code
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub _convert
{
    my ($self, $str, $out_code, $in_code) = @_;

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    return $encode->convert($str, $out_code, $in_code);
}

# Descriptions: convert $str to $out_code code (non method version)
#               XXX you should remove this function.
#    Arguments: STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub __nc_convert
{
    my ($str, $out_code, $in_code) = @_;

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    return $encode->convert($str, $out_code, $in_code);
}


=head1 useful functions as entrance

=head2 htmlify_file($file, $args)

try to convert rfc822 message C<$file> to HTML.

    $args = {
	directory => "destination directory",
    };

=head2 htmlify_dir($dir, $args)

try to convert all rfc822 messages to HTML in C<$dir> directory.

    $args = {
	directory => "destination directory",
    };

=cut


# Descriptions: convert $file to HTML
#    Arguments: OBJ($self) STR($file) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub htmlify_file
{
    my ($self, $file, $args) = @_;
    my $dst_dir = $args->{ output_dir };
    my $indexs = \@indexs;

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
    my $html = new Mail::Message::ToHTML $args;

    if ($debug) {
	printf STDERR "htmlify_file( id=%-6s src=%s )\n", $id, $file;
    }

    _PRINT_DEBUG("htmlify_rfc822_message begin");
    $html->htmlify_rfc822_message({
	id  => $id,
	src => $file,
    });
    _PRINT_DEBUG("htmlify_rfc822_message end");

    if ($debug) {
	printf STDERR "htmlify_file( id=%-6s ) update relation\n", $id;
    }

    _PRINT_DEBUG("-- msg_html_links");
    $html->update_msg_html_links( $id );

    for my $index (@$indexs) {
	if ($index eq "month") {
	    _PRINT_DEBUG("-- monthly id index");
	    $html->update_monthly_id_index({ id => $id });
	}

	if ($index eq "all") {
	    _PRINT_DEBUG("-- id index");
	    $html->update_id_index({ id => $id });
	}

	if ($index eq "thread") {
	    _PRINT_DEBUG("-- thread index");
	    $html->update_thread_index({ id => $id });
	}

	if ($index eq "month_thread") {
	    _PRINT_DEBUG("-- month thread index");
	    $html->update_monthly_thread_index({ id => $id });
	}

	if ($index eq "top") {
	    _PRINT_DEBUG("-- top index");
	    $html->create_top_index();
	}
    }

    # no more action for old files
    if ($html->is_ignore($id)) {
	warn("not process $id (already exists)") if $debug;
    }
    else {
	if ($debug) {
	    printf STDERR "   converted( id=%-6s src=%s )\n", $id, $file;
	}
    }
}


# Descriptions: convert all articles in specified directory
#    Arguments: OBJ($self) STR($src_dir) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub htmlify_dir
{
    my ($self, $src_dir, $args) = @_;
    my $dst_dir  = $args->{ output_dir };
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
    $max      = $args->{ max }      if defined $args->{ max };

    print STDERR "   scan ( $min .. $max ) for $src_dir\n" if $debug;
    for my $id ( $min .. $max ) {
	use File::Spec;
	my $file = File::Spec->catfile($src_dir, $id);

	unless ( $has_fork ) {
	    $self->htmlify_file($file, $args);
	}
	else {
	    my $pid = fork();
	    if ($pid < 0) {
		croak("cannot fork");
	    }
	    elsif ($pid == 0) {
		$self->htmlify_file($file, $args);
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
    my $charset  = 'euc-jp';
    my $opts     = {
	output_dir  => "/tmp/htdocs",
	db_base_dir => "/tmp/",
	db_name     => "elena",
    };

    eval q{
	my ($t, $time_b, $time_e);
	for my $x (@ARGV) {
	    $time_b = time;
	    print STDERR "debug.main processing $x ...";

	    if (-f $x) {
		eval q{
		    my $obj = new Mail::Message::ToHTML $opts;
		    $obj->htmlify_file($x, {
			output_dir  => "/tmp/htdocs",
			directory   => $dir,
			charset     => $charset,
			db_base_dir => "/tmp/",
			db_name     => "elena",
		    });
		};
		print STDERR $@ if $@;
	    }
	    elsif (-d $x) {
		my $obj = new Mail::Message::ToHTML $opts;
		$obj->htmlify_dir($x, {
		    output_dir  => "/tmp/htdocs",
		    directory => $dir,
		    has_fork  => $has_fork,
		    max       => $max,
		    charset   => $charset,
		    db_base_dir => "/tmp/",
		    db_name     => "elena",
		});
	    }

	    $t = time - $time_b;
	    print STDERR "\t$t sec.\n";
	}
	print STDERR "done.\n";
    };

    if ($@) { croak($@);}
}


=head1 TODO

   expiration

   sub directory?

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::ToHTML first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
