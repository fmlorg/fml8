#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: digeston.pm,v 1.1 2002/11/24 02:52:43 fukachan Exp $
#

package FML::Command::Admin::digeston;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);


=head1 NAME

FML::Command::Admin::digest - digest mode on

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

enable digest mode for the specified address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: digest mode off/on for the specified user.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map,$digest_recipient_maps
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options = $command_args->{ options } || [];
    my $address = $command_args->{ command_data } || $options->[ 0 ] || undef;

    # mode on
    $options->[ 1 ] = "on";

    use FML::Command::Admin::digest;
    my $digest = new FML::Command::Admin::digest;
    $digest->process($curproc, $command_args);
}


# Descriptions: show cgi menu for digeston
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
	use FML::CGI::Admin::User;
	my $obj = new FML::CGI::Admin::User;
	$obj->cgi_menu($curproc, $args, $command_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::on first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
