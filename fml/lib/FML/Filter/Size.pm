#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Size.pm,v 1.2 2002/12/20 03:41:28 fukachan Exp $
#

package FML::Filter::Size;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);


=head1 NAME

FML::Filter::Size - filter based on mail size

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::Size> is the collectoin of filter rules based on mail
size.

=head1 METHODS

=head2 C<new()>

constructor.

=cut


my $debug = 0;


# XXX-TODO: need this default rules here ? (principle of least surprise?)
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



=head2 C<rules( $rules )>

overwrite rules by specified C<@$rules> ($rules is ARRAY_REF).

=cut


# Descriptions: access method to overwrite rule
#    Arguments: OBJ($self) ARRAY_REF($rarray)
# Side Effects: overwrite info in object
# Return Value: ARRAY_REF
sub rules
{
    my ($self, $rarray) = @_;
    $self->{ _rules } = $rarray;
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


=head2 C<size_check($msg, $args)>

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::Size;
    my $obj  = new FML::Filter::Size;
    my $msg  = $curproc->{'incoming_message'};

    $obj->Size_check($msg, $args);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


# Descriptions: top level dispatcher
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub size_check
{
    my ($self, $msg, $args) = @_;
    my $rules = $self->{ _rules };

  RULE:
    for my $rule (@$rules) {
	if ($rule eq 'permit') {
	    last RULE;
	}

	eval q{
	    $self->$rule($msg, $args);
	};

	if ($@) {
	    $self->error_set($@);
	}
    }
}


=head1 FILTER RULES

=head2 check_header_size($msg, $args)

check the size of mail header.
throw reason via croak() if the size exceeds the limit.

=head2 check_body_size($msg, $args)

check the size of mail body.
throw reason via croak() if the size exceeds the limit.

=cut


# Descriptions: check the size of mail header.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub check_header_size
{
    my ($self, $msg, $args) = @_;
    $self->_check_mail_size($msg, "header");
}


# Descriptions: check the size of mail body.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub check_body_size
{
    my ($self, $msg, $args) = @_;
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
    my $limit      = $config->{ "${class}_${type}_size_limit" };
    my $reason     = '';
    my $errmsg_key = '';

    if ($type eq 'header') {
	if ($hdr_size > $limit) {
	    $reason = "header size exceeds the limit: $hdr_size > $limit";
	    $errmsg_key = 'error.header_size_limit';
	}
    }
    elsif ($type eq 'body') {
	if ($body_size > $limit) {
	    $reason = "body size exceeds the limit: $body_size > $limit";
	    $errmsg_key = 'error.body_size_limit';
	}
    }

    $self->error_set($reason) if $reason;
    croak($reason);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::Size first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;