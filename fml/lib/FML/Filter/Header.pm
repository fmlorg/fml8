#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Header.pm,v 1.11 2005/05/27 01:47:04 fukachan Exp $
#

package FML::Filter::Header;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Filter::ErrorStatus qw(error_set error error_clear);


=head1 NAME

FML::Filter::Header - filter based on mail header content.

=head1 SYNOPSIS

use FML::Filter::Header;
my $filter = new FML::Filter::Header;
if (defined $filter) {
    my $rules = $config->get_as_array_ref('article_header_filter_rules');
    if (defined $rules) {
	$filter->set_rules( $rules );
    }
    $filter->header_check($mesg);
    if ($filter->error()) {
        ... error handling ...
    }
}

=head1 DESCRIPTION

C<FML::Filter::Header> is the collection of filter rules based on mail
header content.

=head1 METHODS

=head2 new()

constructor.

=cut


my $debug = 0;


# default rules for convenience.
my (@default_rules) = qw(check_message_id);


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



=head2 set_rules( $rules )

overwrite rules by specified C<@$rules> ($rules is ARRAY_REF).

=cut


# Descriptions: access method to overwrite filter rules.
#    Arguments: OBJ($self) ARRAY_REF($rarray)
# Side Effects: overwrite information in object.
# Return Value: ARRAY_REF
sub set_rules
{
    my ($self, $rarray) = @_;

    if (ref($rarray) eq 'ARRAY') {
	$self->{ _rules } = $rarray;
    }
    else {
	carp("rules: invalid input");
    }
}


=head2 header_check($msg);

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::Header;
    my $filter = new FML::Filter::Header;
    my $msg    = $curproc->incoming_message();

    $filter->header_check($msg);
    if ($filter->error()) {
       # do something for wrong formated message ...
    }

=cut


# Descriptions: top level dispatcher.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
sub header_check
{
    my ($self, $msg) = @_;
    my $hdr   = $msg->whole_message_header();
    my $rules = $self->{ _rules };

    # apply $rule check for the header object $hdr
  RULE:
    for my $rule (@$rules) {
	if ($rule eq 'permit') {
	    last RULE;
	}

	eval q{
	    $self->$rule($hdr);
	};

	if ($@) {
	    $self->error_set($@);
	}
    }
}


=head1 FILTER RULES

=head2 check_message_id($msg)

validate the message-id in the given message $msg.
This routine checks whether the message-id has @.

=head2 check_date($msg)

validate the date in the given message $msg.
This routine checks if the header has no date field or not.

=cut


# Descriptions: validate the message-id in the given message $msg.
#               This routine checks whether the message-id has @.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: croak()
# Return Value: none
sub check_message_id
{
    my ($self, $msg) = @_;
    my $mid = $msg->get('message-id') || '';

    if ($mid !~ /\@/) {
	croak( "invalid Message-Id" );
    }
}


# Descriptions: validate the date in the given message $msg.
#               This routine checks if the header has no date field or not.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: croak()
# Return Value: none
sub check_date
{
    my ($self, $msg) = @_;
    my $date = $msg->get('date') || '';

    unless ($date) {
	croak( "Missing Date: field" );
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::Header first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
