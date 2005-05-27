#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Size.pm,v 1.10 2004/07/23 12:41:33 fukachan Exp $
#

package FML::Filter::Size;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Filter::ErrorStatus qw(error_set error error_clear);


=head1 NAME

FML::Filter::Size - filter based on mail size.

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::Size> is the collection of filter rules based on mail
size.

=head1 METHODS

=head2 new()

constructor.

=cut


my $debug = 0;


# default rules for convenience.
my (@default_rules) = qw(check_header_size check_body_size);


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };

    # apply default rules
    $me->{ _rules } = \@default_rules;

    # class (direction)
    $me->{ _class } = 'incoming_article';

    return bless $me, $type;
}


=head2 set_rules( $rules )

overwrite rules by specified C<@$rules> ($rules is ARRAY_REF).

=cut


# Descriptions: overwrite rules.
#    Arguments: OBJ($self) ARRAY_REF($rarray)
# Side Effects: overwrite info in object
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


=head2 set_class( $class )

set class e.g. incoming_article, outgoing_article, ...

=cut


# Descriptions: set class.
#    Arguments: OBJ($self) STR($class)
# Side Effects: update $self->{ _class }
# Return Value: STR
sub set_class
{
    my ($self, $class) = @_;
    $self->{ _class } = $class;
}


=head2 size_check($msg)

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::Size;
    my $obj  = new FML::Filter::Size;
    my $msg  = $curproc->{'incoming_message'};

    $obj->Size_check($msg);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


# Descriptions: top level dispatcher.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
sub size_check
{
    my ($self, $msg) = @_;
    my $rules = $self->{ _rules };

  RULE:
    for my $rule (@$rules) {
	if ($rule eq 'permit') {
	    last RULE;
	}

	eval q{
	    $self->$rule($msg);
	};

	if ($@) {
	    $self->error_set($@);
	}
    }
}


=head1 FILTER RULES

=head2 check_header_size($msg)

check the size of mail header.
throw reason via croak() if the size exceeds the limit.

=head2 check_body_size($msg)

check the size of mail body.
throw reason via croak() if the size exceeds the limit.

=cut


# Descriptions: check the size of mail header.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
sub check_header_size
{
    my ($self, $msg) = @_;
    $self->_check_mail_size($msg, "header");
}


# Descriptions: check the size of mail body.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
sub check_body_size
{
    my ($self, $msg) = @_;
    $self->_check_mail_size($msg, "body");
}


# Descriptions: check the size of mail header and body.
#    Arguments: OBJ($self) OBJ($msg) STR($type)
# Side Effects: croak() if matched.
# Return Value: none
sub _check_mail_size
{
    my ($self, $msg, $type) = @_;
    my $curproc    = $self->{ _curproc };
    my $config     = $curproc->config();
    my $hdr_size   = $msg->whole_message_header_size();
    my $body_size  = $msg->whole_message_body_size();
    my $class      = $self->{ _class };
    my $limit      = $config->{ "${class}_${type}_size_limit" } || 10240000;
    my $reason     = '';
    my $errmsg_key = '';

    if ($type eq 'header') {
	if ($hdr_size > $limit) {
	    $reason     = "header size exceeds the limit: $hdr_size > $limit";
	    $errmsg_key = 'error.header_size_limit';
	}
    }
    elsif ($type eq 'body') {
	if ($body_size > $limit) {
	    $reason     = "body size exceeds the limit: $body_size > $limit";
	    $errmsg_key = 'error.body_size_limit';
	}
    }

    if ($reason) {
	$self->error_set($reason);
	croak($reason);
    }
}


=head1 CHECK COMMAND SYNTAX

=head2 check_command_limit($msg, $type)

check the total number of command requests.

=head2 check_line_length_limit($msg, $type)

check the length limit of one command request.

=cut


# Descriptions: check the total number of command requests.
#    Arguments: OBJ($self) OBJ($msg) STR($type)
# Side Effects: croak() if condition matched.
# Return Value: none
sub check_command_limit
{
    my ($self, $msg, $type) = @_;
    my $curproc = $self->{ _curproc };

    use FML::Command::Filter;
    my $_msg   = $curproc->incoming_message_body();
    my $obj    = new FML::Command::Filter $curproc;
    my $reason = $obj->check_command_limit($_msg);

    if ($reason) {
	$self->error_set($reason);
	croak($reason);
    }
}


# Descriptions: check the length limit of one command request.
#    Arguments: OBJ($self) OBJ($msg) STR($type)
# Side Effects: croak() if condition matched.
# Return Value: none
sub check_line_length_limit
{
    my ($self, $msg, $type) = @_;
    my $curproc = $self->{ _curproc };

    use FML::Command::Filter;
    my $_msg   = $curproc->incoming_message_body();
    my $obj    = new FML::Command::Filter $curproc;
    my $reason = $obj->check_line_length_limit($_msg);

    if ($reason) {
	$self->error_set($reason);
	croak($reason);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::Size first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
