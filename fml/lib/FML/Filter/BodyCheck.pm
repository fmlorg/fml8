#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: BodyCheck.pm,v 1.5 2001/09/23 09:30:28 fukachan Exp $
#

package FML::Filter::BodyCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter::BodyCheck - filter by mail body content

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::BodyCheck> is a collectoin of filter rules based on
mail body content.

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


my $debug = $ENV{'debug'} ? 1 : 0;


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}



=head2 C<body_check($msg, $args)>

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::BodyCheck;
    my $obj     = new FML::Filter::BodyCheck;
    my $msg = $curproc->{ incoming_message }->{ body };

    $obj->body_check($msg, $args);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


sub body_check
{
    my ($self, $msg, $args) = @_;

    ## 0. preparation 
    # local scope after here
    local($*) = 0;

    ## 1. XXX run-hooks
    ## 2. XXX %REJECT_HDR_FIELD_REGEXP
    ## 3. check only the first plain/text block

    # get the message object for the first plain/text message.
    # If the incoming message is a mime multipart format,
    # get_first_plaintext_message() return the first mime part block
    # with the "plain/text" type.
    my $m = $msg->get_first_plaintext_message();

    ## 4. check only the last paragraph
    #     XXX if message size > 1024 or not, we change the buffer to check.
    #     XXX fml 4.0 extracts the last and first paragraph (libenvf.pl)
    #     XXX for small enough buffer. The information comes from @pmap, but
    #     XXX we should implement methods for them within $m message object.
    # get useful information for the message object.
    my $num_paragraph       = $m->num_paragraph();
    my $need_one_line_check = $self->need_one_line_check($m);

    ## 5. preparation for main rules.
    ## $self->_clean_up_buffer($m);

    ## 6. main fules
    for my $rule (qw(reject_not_iso2022jp_japanese_string
		     reject_null_mail_body
		     reject_virus_message
		     reject_one_line_message
		     reject_old_fml_command_syntax
		     reject_invalid_fml_command_syntax
		     reject_japanese_command_syntax
		     )) {
	if ($self->can($rule)) {
	    eval q{
		$self->$rule($msg, $args, $m);
	    };
	    if ($@) {
		$self->error_set($@);
		return $@;
	    }
	}
	else {
	    carp("no such rule $rule");
	}
    }
}


sub reject_not_iso2022jp_japanese_string
{
    my ($self, $msg, $args, $first_msg) = @_;
    my $buf = $first_msg->nth_paragraph(1);

    use FML::Language::ISO2022JP qw(is_iso2022jp_string);
    unless (is_iso2022jp_string($buf)) {
	croak "Japanese but not ISO-2022-JP";
    }
}


sub reject_null_mail_body
{
    my ($self, $msg, $args, $first_msg) = @_;
    my $buf = $first_msg->nth_paragraph(1);

    if ($first_msg->is_empty) {
	my $size = $first_msg->size();
	croak "empty (size = $size)";
    }
}


# Descriptions: virus check against some types of M$ products
#               Even if Multipart, evaluate all blocks agasint virus checks.
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub reject_virus_message
{
    my ($self, $msg, $args, $first_msg) = @_;

    # &use('viruschk');
    # my ($xr);
    # $xr = &VirusCheck(*e);
}


# Descriptions: e.g. "unsubscribe", "help", ("subscribe" in some case)
#               XXX DO NOT INCLUDE ".", "?" (I think so ...)! 
#               XXX but we need "." for mail address syntax 
#               XXX e.g. "chaddr a@d1 b@d2".
#               If we include them, 
#               we cannot identify a command or an English phrase ;D
# Arguments: $self $args
# Side Effects: 
# Return Value: none
sub reject_one_line_message
{
    my ($self, $msg, $args, $first_msg) = @_;
    my $buf = $first_msg->nth_paragraph(1);

    if ( $self->need_one_line_check($first_msg) ) {
	if ($buf =~ /^[\s\n]*[\s\w\d:,\@\-]+[\n\s]*$/) {
	    croak "one line mail body";
	}
    }
}


# Descriptions: 
#              XXX fml 4.0: fml.pl (distribute) should not accpet commands 
#              XXX: "# command" is internal represention
#              XXX: but to reject the old compatible syntaxes.
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub reject_old_fml_command_syntax
{
    my ($self, $msg, $args, $first_msg) = @_;
    my $buf = $first_msg->data;

    if ($buf =~ /^[\s\n]*(\#\s*[\w\d\:\-\s]+)[\n\s]*$/) {
	my $r = $1; 
	$r =~ s/\n//g;
	$r = "avoid to distribute commands [$r]";
	croak $r;
    }
}


sub reject_invalid_fml_command_syntax
{
    my ($self, $msg, $args, $first_msg) = @_;
    my $buf = $first_msg->data;

    if ($buf =~ /^[\s\n]*\%\s*echo.*/i) {
	croak "invalid command in the mail body";
    }
}


# Descriptions: reject Japanese command syntax
#                JIS: 2 byte A-Z => \043[\101-\132]
#                JIS: 2 byte a-z => \043[\141-\172]
#                EUC 2-bytes "A-Z" (243[301-332])+
#                EUC 2-bytes "a-z" (243[341-372])+
#                e.g. reject "SUBSCRIBE" : octal code follows:
#                243 323 243 325 243 302 243 323 243 303 
#                243 322 243 311 243 302 243 305
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub reject_japanese_command_syntax
{
    my ($self, $msg, $args, $first_msg) = @_;
    my $buf = $first_msg->data;

    if ($buf =~ /\033\044\102(\043[\101-\132\141-\172])/) {
	# trap /JIS"2byte"[A-Za-z]+/

	# EUC-fy for further investigation
	my $s = &STR2EUC($buf);
	$s    = (split(/\n/, $s))[0]; # check the first line only

	my ($n_pat, $sp_pat);
	$n_pat  = '\243[\301-\332\341-\372]';
	$sp_pat = '\241\241'; # 2-byte spaces

	if ($s =~ /^\s*(($n_pat){2,})\s+.*$|^\s*(($n_pat){2,})($sp_pat)+.*$|^\s*(($n_pat){2,})$/) {
	    croak '2 byte command';
	}
    }
}


sub need_one_line_check
{
    my ($self, $m) = @_;
    my $np = $m->num_paragraph;

    if ($np == 1) {
	return 1;
    }
    elsif ($np == 2) {
	# if the seconda paragraph looks signature, 
	# this message has only one effective message (paragraph).
	if ($self->is_signature($m->nth_paragraph(2))) {
	    return 1;
	}
    }
    elsif ($np == 3) {
	# case 1: data + citation + signature
	# case 2: citation + data + signature
	if ($self->is_signature($m->nth_paragraph(3))) {
	    if ($self->is_citation($m->nth_paragraph(1)) ||
		$self->is_citation($m->nth_paragraph(2))) {
		return 1;
	    }
	}
    }

    return 0;
}


sub is_citation
{
    my ($self, $data) = @_;
    my $trap_pat = ''; # keyword to trap citation at the head of the line

    if ($data =~ /(\n.)/) { $trap_pat = quotemeta($1);}

    # > a i u e o ...
    # > ka ki ku ke ko ...
    if ($data =~ /\n>/) { return 1;}
    if ($trap_pat) { if ($data =~ /$trap_pat.*$trap_pat/) { return 1;}}

    return 0;
}


# XXX fml 4.0 assumes: 
# XXX If the paragraph has @ or ://, it must be signature.
# trap special keyword like tel:011-123-456789 ...
sub is_signature
{
    my ($self, $data) = @_;

    if ($data =~ /\@/ || 
	$data =~ /TEL:/i ||
	$data =~ /FAX:/i ||
	$data =~ /:\/\// ) {
	return 1;
    }

    # -- fukachan ( usenet style signature ? )
    # // fukachan ( signature derived from what ? )
    if ($data =~ /^--/ || $data =~ /^\/\//) {
	return 1;
    }

    use FML::Language::ISO2022JP qw(STR2EUC);
    $data = STR2EUC( $data );

    # "2-byte @"domain where "@" is a 2-byte "@" character.
    if ($data =~ /[-A-Za-z0-9]\241\367[-A-Za-z0-9]/) {
	return 1;
    }

    return 0;
}


=head2 C<clean_up_buffer($args)>

remove some special syntax pattern for further check.
For example, the pattern is a mail address.
We remove it and check the remained buffer whether it is safe or not.

=cut

sub clean_up_buffer
{
    my ($self, $xbuf) = @_;

    # 1. cut off Email addresses (exceptional).
    $xbuf =~ s/\S+@[-\.0-9A-Za-z]+/account\@domain/g;

    # 2. remove invalid syntax seen in help file with the bug? ;D
    $xbuf =~ s/^_CTK_//g;
    $xbuf =~ s/\n_CTK_//g;

    $xbuf;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Filter::BodyCheck appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
