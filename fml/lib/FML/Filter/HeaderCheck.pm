#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HeaderCheck.pm,v 1.12 2002/02/01 12:03:56 fukachan Exp $
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


my $debug = 0;


my (@default_rules) = qw(is_valid_message_id);


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # apply default rules
    $me->{ _rules } = \@default_rules;

    return bless $me, $type;
}



=head2 C<rules( $rules )>

overwrite rules by specified C<@$rules> ($rules is HASH ARRAY).

=cut


# Descriptions: access method to overwrite rule
#    Arguments: OBJ($self) ARRAY_REF($rarray)
# Side Effects: overwrite info in object
# Return Value: none
sub rules
{
    my ($self, $rarray) = @_;
    $self->{ _rules } = $rarray;
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


# Descriptions: top level dispatcher
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub header_check
{
    my ($self, $msg, $args) = @_;
    my $h = $msg->whole_message_header();
    my $rules = $self->{ _rules };

    for my $rule (@$rules) {
	eval q{
	    $self->$rule($h, $args);
	};

	if ($@) {
	    $self->error_set($@);
	}
    }
}


# Descriptions: check whether message-id has @
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: croak()
# Return Value: none
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

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::HeaderCheck appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
