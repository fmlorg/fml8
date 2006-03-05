#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: digestoff.pm,v 1.13 2006/03/04 13:48:28 fukachan Exp $
#

package FML::Command::Admin::digestoff;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);


=head1 NAME

FML::Command::Admin::digest - digest mode off (from digest to real time).

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

disable digest mode for the specified address.
It means delivery to this address from digest to real delivery mode.

=head1 METHODS

=head2 process($curproc, $command_context)

=cut


# Descriptions: constructor.
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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: verify the syntax command string.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub verify_syntax
{
    my ($self, $curproc, $command_context) = @_;

    use FML::Command::Syntax;
    push(@ISA, qw(FML::Command::Syntax));
    $self->check_syntax_address_handler($curproc, $command_context);
}


# Descriptions: disable digest mode for the specified user.
#               changed from digest to real delivery mode.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map,$digest_recipient_maps
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $options = $command_context->get_options() || [];
    my $address = $command_context->get_data() || $options->[ 0 ] || undef;

    # mode off
    $options->[ 1 ] = "off";

    use FML::Command::Admin::digest;
    my $digest = new FML::Command::Admin::digest;
    $digest->process($curproc, $command_context);
}


# Descriptions: show cgi menu for digestoff.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';

    eval q{
	use FML::CGI::User;
	my $obj = new FML::CGI::User;
	$obj->cgi_menu($curproc, $command_context);
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

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::on first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
