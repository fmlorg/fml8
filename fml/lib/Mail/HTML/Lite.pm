#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Lite.pm,v 1.14 2001/10/21 05:53:58 fukachan Exp $
#

package Mail::HTML::Lite;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;
my $URL   = "<A HREF=\"http://www.fml.org/software/\">Mail::HTML::Lite</A>";

my $version = q$FML: Lite.pm,v 1.14 2001/10/21 05:53:58 fukachan Exp $;
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

    $me->{ _charset } = $args->{ charset } || 'us-ascii';
    $me->{ _html_base_directory } = $args->{ directory };
    $me->{ _is_attachment } = defined($args->{ attachment }) ? 1 : 0;
    $me->{ _db_type } = $args->{ db_type };
    $me->{ _args } = $args;

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

	# header
	if ($type eq 'text/rfc822-headers') {
	    $self->mhl_separator($wh);
	    my $header = $self->_format_header($msg);
	    $self->_text_print({ 
		fh   => $wh,
		data => $header,
	    });
	    $self->mhl_separator($wh);
	}
	# text/plain case.
	elsif ($type eq 'text/plain') {
	    $self->_text_print({ 
		fh   => $wh,
		data => $m->data,
	    });
	}
	# message/rfc822 case
	elsif ($type eq 'message/rfc822') {
	    $attach++;

	    my $tmpf = $self->_create_temporary_file($m);
	    if (defined $tmpf && -f $tmpf) {
		# write attachement into a separete file
		my $outf = _gen_attachment_filename($dst, $attach, 'html');
		my $args = $self->{ _args };
		$args->{ attachment } = 1; # clarify not top level content.
		my $text = new Mail::HTML::Lite $args;
		$text->htmlfy_rfc822_message({
		    src => $tmpf,
		    dst => $outf,
		});

		# show inline href appeared in parent html.
		$self->_print_inline_object({
		    fh   => $wh,
		    type => $type,
		    num  => $attach,
		    file => $outf,
		});

		unlink $tmpf;
	    }
	}
	# e.g. image/gif case
	else {
	    $attach++;

	    # write attachement into a separete file
	    my $outf = _gen_attachment_filename($dst, $attach, $type);
	    my $enc  = $msg->get_encoding_mechanism;

	    # e.g. text/html case 
	    if ($type =~ /^text/ && (not $enc)) {
		$self->_text_print_by_raw_mode({ 
		    message => $m,
		    file    => $outf,
		});
	    }
	    # e.g. image/gif, but this case includes encoded "text/html".
	    else {
		$self->_binary_print({ 
		    message => $m,
		    file    => $outf,
		});
	    }

	    # show inline href appeared in parent html.
	    $self->_print_inline_object({
		inline => 1,
		fh   => $wh,
		type => $type,
		num  => $attach,
		file => $outf,
	    });
	}
    }

    # after message
    $self->mhl_separator($wh);
    $self->mhl_footer($wh);
    $self->html_end($wh);
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
	print $wh "<title>$title</title>\n";
    }

    print $wh "</HEAD>\n";
    print $wh "<BODY>\n";
    print $wh "<CENTER>$title</CENTER>\n";
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
sub _create_temporary_file
{
    my ($self, $msg) = @_;
    my $db_dir  = $self->{ _html_base_directory };
    my $tmpf    = "$db_dir/tmp$$";
    
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
sub _print_inline_object
{
    my ($self, $args) = @_;
    my $wh   = $args->{ fh };
    my $type = $args->{ type };
    my $num  = $args->{ num };
    my $file = $self->_relative_path($args->{ file });
    my $inline = defined( $args->{ inline } ) ? 1 : 0;

    if ($inline && $type =~ /image/) {
	print $wh "<BR><IMG SRC=\"$file\">\n";
    }
    else {
	my $t = $file;
	print $wh "<BR><A HREF=\"$file\" TARGET=\"$t\"> $type $num </A><BR>\n";
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
my @header_field = qw(From To Cc Subject Date);


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _format_header
{
    my ($self, $msg) = @_;
    my ($buf);
    my $hdr = $msg->rfc822_message_header;
    my $header_field = \@header_field;

    # header
    for my $field (@$header_field) {
	if (defined($hdr->get($field))) {
	    $buf .= "${field}: ";
	    my $xbuf = $hdr->get($field); 
	    $buf .= $xbuf =~ /=\?iso/i ? $self->_decode_mime_string($xbuf) : $xbuf;
	}
    }

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
sub _text_print
{
    my ($self, $args) = @_;
    my $buf = $args->{ data };
    my $fh  = $args->{ fh } || \*STDOUT;

    use Jcode;
    &Jcode::convert(\$buf, 'euc');

    use HTML::FromText;
    print $fh text2html($buf, urls => 1, pre => 1);
    print $fh "\n";
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _text_print_by_raw_mode
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

	use Jcode;
	&Jcode::convert(\$buf, 'euc');
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

	    use MIME::Base64;
	    binmode($fh);
	    print $fh decode_base64( $msg->data_in_body_part() );
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
	    $db->{_info }->{id_max } = $id;
	}
	print STDERR "   parent\n" if $debug;
	print STDERR "   update id_max = $db->{_info }->{id_max }\n" if $debug;
    }
    else {
	print STDERR "   child\n" if $debug;
    }

    print STDERR "   cache_message_info( id=$id ) running\n" if $debug;

    $db->{ _filename }->{ $id } = $self->message_filename($id);
    $db->{ _filepath }->{ $id } = $dst;

    print STDERR "   date\n" if $debug > 3;
    $db->{ _date }->{ $id } = $hdr->get('date');

    use Time::ParseDate;
    my $unixtime = parsedate( $hdr->get('date') );
    $db->{ _unixtime }->{ $id } = $unixtime;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime( $unixtime );
    my $month  = sprintf("%04d/%02d", 1900 + $year, $mon + 1);

    # id => YYYY/MM
    $db->{ _month }->{ $id } = $month;

    # YYYY/MM => (id1 id2 id3 ..)
    $db->{ _monthly_idlist }->{ $month } .= " $id";


    print STDERR "   subject\n" if $debug > 3;
    $db->{ _subject }->{ $id } = 
	$self->_decode_mime_string( $hdr->get('subject') );
	
    print STDERR "   from\n" if $debug > 3;
    my $ra = _address_clean_up( $hdr->get('from') );
    $db->{ _from }->{ $id } = $ra->[0];
    $db->{ _who }->{ $id } = $self->_who_of_address( $hdr->get('from') );

    print STDERR "   message-id\n" if $debug > 3;
    $ra  = _address_clean_up( $hdr->get('message-id') );
    my $mid = $ra->[0];
    if ($mid) {
	print STDERR "   message-id = <$mid>\n" if $debug > 3;
	$db->{ _message_id }->{ $id } = $mid;
	$db->{ _msgidref }->{ $mid }  = $id;
	$db->{ _idref }->{ $id }      = $id;
    }

    print STDERR "   in-reply-to\n" if $debug > 3;
    $ra = _address_clean_up( $hdr->get('in-reply-to') );
    my $in_reply_to = $ra->[0];
    for my $mid (@$ra) {
	$db->{ _msgidref }->{ $mid } .= " ".$id;

	# message-id => id
	my $idp = _list_head($db->{ _msgidref }->{ $mid });
	$db->{ _idref }->{ $idp } .= " ".$id if defined $idp;
    }

    print STDERR "   referances\n" if $debug > 3;
    $ra = _address_clean_up( $hdr->get('references') );
    for my $mid (@$ra) {
	$db->{ _msgidref }->{ $mid } .= " ".$id;

	# message-id => id
	my $idp = _list_head($db->{ _msgidref }->{ $mid });
	$db->{ _idref }->{ $idp } .= " ".$id if defined $idp;
    }

    # thread information for convenience
    #   prev_id = { id => prev_id } (by in-reply-to:)
    #   next_id = { id => next_id } (? in-reply-to of the future message ?)

    #  $ids = (id1 id2 id3 ...)
    my $ids = $db->{ _msgidref }->{ $in_reply_to };
    if (defined $ids) {
	my $prev_id = _list_head($ids);
	$db->{ _prev_id }->{ $id } = $prev_id;

	# XXX we should not overwrite " id => next_id " hash.
	# XXX we preserve the first " id => next_id " value.
	unless (defined $db->{ _next_id }->{ $prev_id }) {
	    $db->{ _next_id }->{ $prev_id } = $id;
	}
    }
    else {
	warn("no prev/next thread link (id=$id)\n") if $debug;
    }

    $self->_db_close();
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
    for my $id (qw(prev_id next_id prev_thread_id next_thread_id)) {
	if (defined $args->{ $id }) {
	    $self->_update_relation( $args->{ $id });
	    push(@$list, $args->{ $id });
	}
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
    my $preamble = $self->evaluate_preamble($args);
    my $footer   = $self->evaluate_footer($args);
    my $code     = _charset_to_code($self->{ _charset });

    my $pat_preamble_begin = quotemeta($preamble_begin);
    my $pat_preamble_end   = quotemeta($preamble_end);
    my $pat_footer_begin   = quotemeta($footer_begin);
    my $pat_footer_end     = quotemeta($footer_end);

    use FileHandle;
    my $file        = $args->{ file };
    my ($old, $new) = ($file, "$file.new.$$");
    my $rh = new FileHandle $old;
    my $wh = new FileHandle "> $new";
    if (defined $rh && defined $wh) {
	while (<$rh>) {
	    if (/^$pat_preamble_begin/ .. /^$pat_preamble_end/) {
		_print($wh, $preamble, $code) if /^$pat_preamble_end/;
		next;
	    }
	    if (/^$pat_footer_begin/ .. /^$pat_footer_end/) {
		_print($wh, $footer, $code) if /^$pat_footer_end/;
		next;
	    }

	    _print($wh, $_, $code);
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

    my $next_file        = $self->message_filepath( $id + 1 );
    my $prev_id          = $id > 1 ? $id - 1 : undef;
    my $next_id          = $id + 1 if -f $next_file;
    my $prev_thread_id   = $db->{ _prev_id }->{ $id };
    my $next_thread_id   = $db->{ _next_id }->{ $id };

    # diagnostic
    undef $prev_thread_id if $prev_thread_id == $id;
    undef $next_thread_id if $next_thread_id == $id;

    my $link_prev_id     = $self->message_filename($prev_id);
    my $link_next_id     = $self->message_filename($next_id);
    my $link_prev_thread = $self->message_filename($prev_thread_id);
    my $link_next_thread = $self->message_filename($next_thread_id);
    my $subject = {
	prev_id     => $db->{ _subject }->{ $prev_id },
	next_id     => $db->{ _subject }->{ $next_id },
	prev_thread => $db->{ _subject }->{ $prev_thread_id },
	next_thread => $db->{ _subject }->{ $next_thread_id },
    };

    if ($debug) {
	print STDERR "subject($prev_id -> $id -> $next_id)\n";
	print STDERR "       ($prev_thread_id -> $id -> $next_thread_id)\n";
    }

    my $args = {
	id               => $id,
	file             => $file,
	prev_id          => $prev_id,
	next_id          => $next_id,
	prev_thread      => $prev_thread_id,
	next_thread      => $next_thread_id,
	link_prev_id     => $link_prev_id,
	link_next_id     => $link_next_id,
	link_prev_thread => $link_prev_thread,
	link_next_thread => $link_next_thread,
	subject          => $subject, 
    };

    $self->_db_close();

    return $args;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub evaluate_preamble
{
    my ($self, $args) = @_;
    my $link_prev_id     = $args->{ link_prev_id };
    my $link_next_id     = $args->{ link_next_id };
    my $link_prev_thread = $args->{ link_prev_thread };
    my $link_next_thread = $args->{ link_next_thread };

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

    if (defined $link_prev_thread) {
	$preamble .= "<A HREF=\"$link_prev_thread\">[Prev by Thread]</A>\n";
    }
    else {
	$preamble .= "[No Prev Thread]\n";
    }
    
    if (defined $link_next_thread) {
	$preamble .= "<A HREF=\"$link_next_thread\">[Next by Thread]</A>\n";
    }
    else {
	$preamble .= "[No Next Thread]\n";
    }

    $preamble .= _format_index_navigator();
    $preamble .= $preamble_end. "\n";;

    return $preamble;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub evaluate_footer
{
    my ($self, $args) = @_;
    my $link_prev_id     = $args->{ link_prev_id };
    my $link_next_id     = $args->{ link_next_id };
    my $link_prev_thread = $args->{ link_prev_thread };
    my $link_next_thread = $args->{ link_next_thread };
    my $subject     = $args->{ subject };

    my $footer = $footer_begin. "\n";;

    if (defined($link_prev_id)) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_prev_id\">Prev by ID: ";
	$footer .= "$subject->{ prev_id }</A>\n";
    }

    if (defined($link_next_id)) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_next_id\">Next by ID: ";
	$footer .= "$subject->{ next_id }</A>\n";
    }

    if (defined $link_prev_thread) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_prev_thread\">Prev by Thread: ";
	$footer .= "$subject->{ prev_thread }</A>\n";
    }

    if (defined $link_next_thread) {
	$footer .= "<BR>\n";
	$footer .= "<A HREF=\"$link_next_thread\">Next by Thread: ";
	$footer .= "$subject->{ next_thread }</A>\n";
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

    print STDERR "_db_open( type = $db_type )\n" if $debug;

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
 	for my $db (@kind_of_databases) {
	    my $file = "$db_dir/.ht_mhl_${db}";
	    my $str = qq{
		my \%$db = ();
		tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, 0644;
		\$self->{ _db }->{ _$db } = \\\%$db;
	    };
	    print STDERR $str if $debug > 10;
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

    print STDERR "_db_close()\n" if $debug;

    for my $db (@kind_of_databases) {
	my $str = qq{ 
	    my \$${db} = \$self->{ _db }->{ _$db };
	    untie \%\$${db};
	};
	print STDERR $str if $debug > 10;
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

    _print($wh, _format_index_navigator(), $code);
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
    _print($wh, _format_index_navigator(), $code);

    # append version information
    _print($wh, "<BR>Genereated by $version\n", $code);

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

    _print($wh, "<TABLE>", $code);

    for my $year (@$years) {
	# $self->_print_ul($wh, $db, $code);

	_print($wh, "<TR>", $code);

	for my $month (1 .. 12) {
	    _print($wh, "<TR>", $code) if $month == 7;

	    my $id = sprintf("%04d/%02d", $year, $month); # YYYY/MM
	    my $xx = sprintf("%04d%02d", $year, $month); # YYYYMM
	    my $fn = "month.$xx.html";

	    use File::Spec;
	    my $file = File::Spec->catfile($html_base_dir, $fn);
	    if (-f $file) {
		_print($wh, "<TD><A HREF=\"$fn\"> $id </A>", $code);
	    }
	    else {
		_print($wh, "<TD>", $code);
	    }
	}

	# $self->_print_end_of_ul($wh, $db, $code);
    }
    _print($wh, "</TABLE>", $code);
    
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
    _print($wh, "<!-- thread head=$head_id -->\n", $code);

    # get id list: @idlist = ( $head_id id2 id3 ... )
    my $buf = $db->{ _idref }->{ $head_id };
    $buf =~ s/^\s*//;
    $buf =~ s/\s*$//;
    my (@idlist) = split(/\s+/, $buf);

  IDLIST:
    for my $id (@idlist) {
	_print($wh, "<!-- thread (@idlist) -->\n", $code);

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
sub _print
{
    my ($wh, $str, $code) = @_;
    $code = defined($code) ? $code : 'euc'; # euc-jp by default

    use Jcode;
    &Jcode::convert( \$str, $code);

    print $wh $str;
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
    _print($wh, "${padding}<UL>\n", $code);
}


sub _print_end_of_ul
{
    my ($self, $wh, $db, $code) = @_;

    return unless $self->{ _stack } > 0;

    my $padding = "   " x $self->{ _stack };
    _print($wh, "${padding}</UL>\n", $code);

    $self->{ _stack }--;
}


sub _print_li_filename
{
    my ($self, $wh, $db, $id, $code) = @_;
    my $filename = $db->{ _filename }->{ $id };
    my $subject  = $db->{ _subject }->{ $id };
    my $who      = $db->{ _who }->{ $id };

    _print($wh, "<!-- LI id=$id -->\n", $code);

    _print($wh, "<LI>\n", $code);
    _print($wh, "<A HREF=\"$filename\">\n", $code);
    # _print($wh, "[ $id ] ", $code);
    _print($wh, $subject, $code);
    _print($wh, ",\n", $code);
    _print($wh, "$who\n", $code);
    _print($wh, "</A>\n", $code);
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
    if (($str =~ /=\?ISO\-2022\-JP\?[BQ]\?/i) &&
	($code eq 'euc' || $code eq 'jis')) {
        use MIME::Base64;
        if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
        }

        use MIME::QuotedPrint;
        if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
        }

	use Jcode;
	my $icode = &Jcode::getcode(\$str);
	&Jcode::convert(\$str, $code, $icode);
    }

    return $str;
}


#
# debug
#

sub _debug
{
    my ($file) = @_;

    use File::Basename;
    my $f = basename($file);
    my $html = new Mail::HTML::Lite {
	charset   => "euc-jp",
	directory => "/tmp/htdocs",
    };

    printf STDERR "_debug( id=%-6s src=%s )\n", $f, $file;

    $html->htmlfy_rfc822_message({
	id  => $f,
	src => $file,
    });
    $html->update_relation( $f );

    $html->update_id_monthly_index({ 
	title => "monthly index",
	id    => $f,
    });

    # update index.html
    $html->update_id_index({ 
	title => "index",
	id    => $f,
    });

    # update thread.html
    my $start_time = time;
    $html->update_thread_index({
	title => "thread",
	id    => $f,
    });

    # no more action for old files
    if ($html->is_ignore($f)) {
	warn("not process $f (already exists)");
    }
}


if ($0 eq __FILE__) {
    eval q{
	for my $x (@ARGV) {
	    if (-f $x) {
		_debug($x);
	    }
	    elsif (-d $x) {
		my $max = 0;
		use DirHandle;
		my $dh = new DirHandle $x;
		if (defined $dh) {
		    for my $file ( $dh->read() ) {
			next unless $file =~ /^\d+$/;
			$max = $max < $file ? $file : $max;
		    }
		}

		for my $f ( 1 .. $max ) {
		    use File::Spec;
		    my $file = File::Spec->catfile($x, $f);
		    _debug( $file );
		}
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
