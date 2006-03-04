#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newcopml.pm,v 1.1 2006/02/04 08:00:09 fukachan Exp $
#

package FML::Command::Admin::newcopml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::newml;
push(@ISA, qw(FML::Command::Admin::newml));

=head1 NAME

FML::Command::Admin::newcopml - set up a new create-on-post mailing list.

=head1 SYNOPSIS

    use FML::Command::Admin::newcopml;
    $obj = new FML::Command::Admin::newcopml;
    $obj->newcopml($curproc, $command_context);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up a new mailing list.
create mailing list directory,
install config.cf, include, include-ctl et. al.

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


# Descriptions: not need lock in the first time.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: install create-on-post mailing list configuration.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

    # 1. run newml.
    $self->SUPER::process($curproc, $command_context);

    # 2. set up create-on-post configuration.
    use FML::ML::Control;
    my $control = new FML::ML::Control;
    $control->set_mode("create-on-post");
    $control->install_createonpost($curproc, $command_context);
}


# Descriptions: show cgi menu for newcopml command.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: create home directories, update aliases, ...
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';

    # XXX-TODO: $command_context checked ?
    eval q{
        use FML::CGI::ML;
        my $obj = new FML::CGI::ML;
        $obj->cgi_menu($curproc, $command_context);
    };
    if ($r = $@) {
        croak($r);
    }
}


=head1 UTILITIES

=head2 set_force_mode($curproc, $command_context)

set force mode.

=head2 get_force_mode($curproc, $command_context)

return if force mode is enabled or not.

=cut


# Descriptions: set force mode.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $self.
# Return Value: none
sub set_force_mode
{
    my ($self, $curproc, $command_context) = @_;
    $self->{ _force_mode } = 1;
}


# Descriptions: return if force mode is enabled or not.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: none
sub get_force_mode
{
    my ($self, $curproc, $command_context) = @_;
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

FML::Command::Admin::newcopml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
