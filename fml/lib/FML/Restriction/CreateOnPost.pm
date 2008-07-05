#-*- perl -*-
#
#  Copyright (C) 2006,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: CreateOnPost.pm,v 1.4 2008/06/28 21:05:47 fukachan Exp $
#

package FML::Restriction::CreateOnPost;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Restriction::Post;
push(@ISA, qw(FML::Restriction::Post));

=head1 NAME

FML::Restriction::CreateOnPost - restrictions on craete-on-post.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions:
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_errormail
{
    my ($self, $rule, $sender) = @_;

    if ($sender eq '<>') {
	return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions:
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_fml8_managed_address
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };

    if ($curproc->is_fml8_managed_address($sender)) {
	return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions:
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_createonpost_domain
{
    my ($self, $rule, $sender) = @_;
    my $curproc   = $self->{ _curproc };
    my $ml_domain = $curproc->ml_domain();

    if ($sender =~ /\@$ml_domain$/i) {
	return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions:
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_list_header_field
{
    my ($self, $rule, $sender) = @_;
    my $curproc   = $self->{ _curproc };
    my $header    = $curproc->incoming_message_header();
    my $list_help = $header->get("List-Help") || '';

    if ($list_help) {
	return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions: permit if the sender is contained in $createonpost_newml_maps.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_createonpost_newml_maps
{
    my ($self, $rule, $sender) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $header    = $curproc->incoming_message_header();
    my $cred      = $curproc->credential();
    my $from      = $header->address_cleanup( $header->get('from') );

    my $maps     = 'createonpost_newml_maps';
    my $map_list = $config->get_as_array_ref($maps) || [];

    # check if from: address is contained in either map.
    my $status = 0;
  MAP:
    for my $map (@$map_list) {
        if (defined $map) {
            my $is_valid = $cred->is_valid_map($map, $config);
	    if ($is_valid) {
		$status = $cred->has_address_in_map($map, $config, $from);
		last MAP if $status;
	    }
	    else {
		$curproc->logdebug("invalid map: $map");
	    }
        }
    }

    if ($status) {
	return("matched", "permit");
    }

    return(0, undef);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Restriction::CreateOnPost first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
