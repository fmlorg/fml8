#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: HeaderCheck.pm,v 1.4 2001/08/05 14:07:08 fukachan Exp $
#

package FML::Filter::HeaderCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter::HeaderCheck - filter based on mail header content

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::HeaderCheck> is a collectoin of filter rules based on
mail header content.

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



=head2 C<header_check($msg, $args)>

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::HeaderCheck;
    my $obj  = new FML::Filter::HeaderCheck;
    my $msg  = $curproc->{'incoming_message'};

    $obj->header_check($msg, $args);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


sub header_check
{
    my ($self, $msg, $args) = @_;
    my $h = $msg->rfc822_message_header();

    eval q{
	$self->is_valid_message_id($h, $args);
    };

    if ($@) {
	$self->error_set($@);
    }
}


sub is_valid_message_id
{
    my ($self, $msg, $args) = @_;
    my $mid = $msg->get('message-id');

    if ($mid !~ /\@/) { 
	croak "invalid Message-Id";
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Filter::HeaderCheck appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
