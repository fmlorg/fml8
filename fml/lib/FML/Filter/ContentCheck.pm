#-*- perl -*-
#
#  Copyright (C) 2002 Takuya MURASHITA
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ContentCheck.pm,v 1.4 2002/04/23 23:52:50 tmu Exp $
#

package FML::Filter::ContentCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter::ContentCheck - filter based on mail MIME content

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::ContentCheck> is a MIME content filter

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


my $debug = 0;

my (@default_rules) = qw(only_plaintext);

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


=head2 C<content_check($msg, $args)>

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::ContentCheck;
    my $obj  = new FML::Filter::ContentCheck;
    my $msg  = $curproc->{'incoming_message'};

    $obj->content_check($msg, $args);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


# Descriptions: top level dispatcher
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub content_check
{
    my ($self, $msg, $args) = @_;
    my $rules = $self->{ _rules };

    for my $rule (@$rules) {
	eval q{
	    $self->$rule($msg, $args);
	};

	if ($@) {
	    $self->error_set($@);
	}
    }
}


# Descriptions: plaintext only
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: croak()
# Return Value: none
sub only_plaintext
{
    my ($self, $msg, $args) = @_;
    my $mp   = $msg;
    my ($data_type,$prevmp,$nextmp);

   for ( ; $mp; $mp = $mp->{ next }) {
	$data_type = $mp->data_type();
	next if($data_type eq "text/rfc822-headers");
	next if($data_type eq "text/plain");
	next if($data_type =~ "multipart\.");

	$prevmp = $mp->{ prev };
	if($prevmp) {
	    my $prev_type = $prevmp->data_type();
	    if ($prev_type eq "multipart.delimiter") {
		$prevmp->delete_message_part_link();
	    }
	}
	$mp->delete_message_part_link();
    }
    return 0;
}

=head1 AUTHOR

Takuya MURASHITA

=head1 COPYRIGHT

Copyright (C) 2002 Takuya MURASHITA

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::ContentCheck appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
