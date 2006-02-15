#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: rmcopml.pm,v 1.1 2006/02/04 08:00:09 fukachan Exp $
#

package FML::Command::Admin::rmcopml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::rmml;
push(@ISA, qw(FML::Command::Admin::rmml));

=head1 NAME

FML::Command::Admin::rmcopml - disable a new create-on-post mailing list.

=head1 SYNOPSIS

    use FML::Command::Admin::rmcopml;
    $obj = new FML::Command::Admin::rmcopml;
    $obj->rmcopml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up a new mailing list.
create mailing list directory,
install config.cf, include, include-ctl et. al.

=head1 METHODS

=head2 process($curproc, $command_args)

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


# Descriptions: not need lock in the first time.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: disable create-on-post mailing list configuration.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->SUPER::process($curproc, $command_args);

    use FML::ML::Control;
    my $control = new FML::ML::Control;
    $control->set_mode("create-on-post");
    $control->delete_createonpost($curproc, $command_args);
}


# Descriptions: show cgi menu for rmcopml command.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create home directories, update aliases, ...
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_args) = @_;
    my $r = '';

    # XXX-TODO: $command_args checked ?
    eval q{
        use FML::CGI::ML;
        my $obj = new FML::CGI::ML;
        $obj->cgi_menu($curproc, $command_args);
    };
    if ($r = $@) {
        croak($r);
    }
}


=head1 UTILITIES

=head2 set_force_mode($curproc, $command_args)

set force mode.

=head2 get_force_mode($curproc, $command_args)

return if force mode is enabled or not.

=cut


# Descriptions: set force mode.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $self.
# Return Value: none
sub set_force_mode
{
    my ($self, $curproc, $command_args) = @_;
    $self->{ _force_mode } = 1;
}


# Descriptions: return if force mode is enabled or not.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub get_force_mode
{
    my ($self, $curproc, $command_args) = @_;
    my $options = $curproc->command_line_options();

    if (defined $self->{ _force_mode }) {
	return( $self->{ _force_mode } ? 1 : 0 );
    }
    else {
	return( (defined $options->{ force }) ? 1 : 0 );
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::rmcopml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
