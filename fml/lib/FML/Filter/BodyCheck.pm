#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: BodyCheck.pm,v 1.1.1.1 2001/03/28 15:13:31 fukachan Exp $
#

package FML::Filter::BodyCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

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


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}



=head2 C<body_check($curproc, $args)>

entrance to the body check routines.
C<fml process> to need this function kicks off fileter rules 
through C<body_check()>.

Filter rules are applied to the incoming message from STDIN, 

   $curproc->{ incoming_message }->{ body }.

=cut


sub body_check
{
    my ($self, $curproc, $args) = @_;
    my $message = $curproc->{ incoming_message }->{ body };

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
    my $m = $message->get_first_plaintext_message();

    ## 4. check only the last paragraph
    #     XXX if message size > 1024 or not, we change the buffer to check.
    #     XXX fml 4.0 extracts the last and first paragraph (libenvf.pl)
    #     XXX for small enough buffer. The information comes from @pmap, but
    #     XXX we should implement methods for them within $m message object.
    # get useful information for the message object.
    my $num_paragraph = $m->num_paragraph();
    my $is_one_line   = $self->is_one_line_message($m);

    ## 5. preparation for main rules.
    $self->clean_up_buffer($m);

    ## 6. main fules
    my $rules = '';
    for $rules (
		'reject_not_iso2022jp_japanese_string',
		'reject_null_mail_body',
		) {
	if ($self->can($method)) {
	    $self->$method($curproc, $args, $m);
	}
	else {
	    LogWarn("no such method $method");
	}
    }
}


sub clean_up_buffer
{
    ;
}


# XXX fml 4.0: If it has @ or ://, it must be a paragraph 
sub is_one_line_message
{
    ;
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
