#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.1 2001/08/07 12:23:48 fukachan Exp $
#

package Mail::HTML::Lite;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::HTML::Lite - mail to html converter

=head1 SYNOPSIS

=head1 DESCRIPTION

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

    return bless $me, $type;
}


=head2 C<htmlfy_rfc822_message($args)>

convert mail to html.

    $args = {
	id   => $id,
	path => $path,
    };

C<$path> is file path.

=cut


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
	$dst = "$html_base_dir/msg$id.html";
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

    use Mail::Message;
    use FileHandle;
    my $rh   = new FileHandle $src;
    my $msg  = Mail::Message->parse( { fd => $rh } );
    my $hdr  = $msg->rfc822_message_header;
    my $body = $msg->rfc822_message_body;

    # save information for index.html and thread.html
    $self->cache_message_info($msg, { src => $src } );

    # prepare output channel
    my $wh = $self->_set_output_channel( { dst => $dst } );
    unless (defined $wh) {
	croak("cannot open output file\n");
    }

    # before main message
    $self->html_begin($wh);
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
		my $text = new Mail::HTML::Lite;
		$text->htmlfy_rfc822_message({
		    src => $tmpf,
		    dst => $outf,
		});

		# show inline href appeared in parent html.
		$self->_print_attachment({
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
		$self->_raw_text_print({ 
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
	    $self->_print_attachment({
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


=head1 Message structure created as HTML

HTML-fied message has following structure.
something() below is method name.

                                       for example 
    -----------------------------------------------------------------------
    html_begin()                      <HTML><HEAD> ... </HEAD><BODY> 
    mhl_preamble()                    <!-- comment used by this module -->
    mhl_separator()                   <HR>

      ... message header  ...
           From:    ...
           Subject: ...

    mhl_separator()                   <HR>

     ... message body ...

    mhl_separator()                   <HR>
    mhl_footer()                      <!-- comment used by this module -->
    html_end()                        </BODY></HTML> 

=cut


sub html_begin
{
    my ($self, $wh) = @_;
    print $wh "<HTML>";
    print $wh "<HEAD>\n";
    print $wh "\n";
    print $wh "</HEAD>\n";
    print $wh "<BODY>\n";
}


sub html_end
{
    my ($self, $wh) = @_;
    print $wh "</BODY>";
    print $wh "</HTML>\n";
}


sub mhl_separator
{
    my ($self, $wh) = @_;
    print $wh "<HR>\n";
}


sub mhl_preamble
{
    my ($self, $wh) = @_;
    print $wh "<!-- __PREAMBLE_BEGIN__ by Mail::HTML::Lite -->\n";
    print $wh "<!-- __PREAMBLE_END__   by Mail::HTML::Lite -->\n";
}


sub mhl_footer
{
    my ($self, $wh) = @_;
    print $wh "<!-- __FOOTER_BEGIN__ by Mail::HTML::Lite -->\n";
    print $wh "<!-- __FOOTER_END__   by Mail::HTML::Lite -->\n";
}


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


sub _relative_path
{
    my ($self, $file) = @_;
    my $html_base_dir  = $self->{ _html_base_directory };
    $file =~ s/$html_base_dir//;
    $file =~ s@^/@@;
    return $file;
}


sub _print_attachment
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


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _format_header
{
    my ($self, $msg) = @_;
    my $hdr = $msg->rfc822_message_header;
    my $buf = '';

    # header
    for my $field (qw(From To Cc Subject Date)) {
	if (defined($hdr->get($field))) {
	    $buf .= "${field}: ";
	    $buf .= $hdr->get($field);
	}
    }

    return($buf);
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
sub _raw_text_print
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


=head1 Create INDEX

=head2 C<cache_message_info($msg, $args)>

=cut


sub cache_message_info
{
    my ($self, $msg, $args) = @_;
    my $hdr = $msg->rfc822_message_header;
    my $src = $args->{ src };

    $self->_db_open();

    $self->{ _db }->{ _from }->{ $src } = $hdr->get('from');
    $self->{ _db }->{ _date }->{ $src } = $hdr->get('date');
    $self->{ _db }->{ _message_id }->{ $src } = $hdr->get('message-id');

    $self->_db_close();
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
   fileloc       id => file location ( /some/where/YYYY/MM/DD/xxx.html )
   msgidref      message-id => id(myself) refered-by-id1 refered-by-id2 ...

=head2 Usage

For example, you can set { $key => $value } for C<from> data in this way:

    $self->{ _db }->{ _from }->{ $key } = $value;

=cut

my @kind_of_databases = qw(from date subject message_id references
			   fileloc msgidref);


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
    my $db_type = $args->{ db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
 	for my $db (@kind_of_databases) {
	    my $file = "$db_dir/.ht_mhl_${db}";
	    eval qq{
		my \%$db;
		tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, 0644;
		\$self->{ _db }->{ _$db } = \\\%$db;
	    };
	    croak($@) if $@;
	}
    }
}


sub _db_close
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    unless ($@) {
 	for my $db (@kind_of_databases) {
	    eval qq{ untie \$self->{ _db }->{ _$db };};
	    croak($@) if $@;
	}
    }
}


=head2 C<make_index($args)>

sub make_index
{
    my ($self, $args) = @_;
}

=cut


if ($0 eq __FILE__) {
    eval q{
	my $html = new Mail::HTML::Lite { directory => "/tmp/htdocs" };

	for (@ARGV) {
	    use File::Basename;
	    my $f = basename($_);
	    $html->htmlfy_rfc822_message({
		id  => $f,
		src => $_,
	    });
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
