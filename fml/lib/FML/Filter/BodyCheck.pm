#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Filter::Core;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::Core - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

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


sub body_check
{
    my ($self, $curproc, $args) = @_;
    my $message = $curproc->{ incoming_message }->{ body };

    # 0. preparation 
    # local scope after here
    local($*) = 0;

    # 1. XXX run-hooks
    # 2. XXX %REJECT_HDR_FIELD_REGEXP
    # 3. check only the first plain/text block
    my $m = $message->get_first_plaintext_message();

    # 4 check only the last paragraph
    my $num_paragraph = $m->num_paragraph();
    my $is_one_line   = $m->is_one_line_message();

}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Filter::Core appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
