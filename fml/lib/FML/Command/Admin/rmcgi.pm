#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newml.pm,v 1.85 2008/09/12 11:05:24 fukachan Exp $
#

package FML::Command::Admin::rmcgi;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::rmcgi - set up cgi scripts for the specified domain.

=head1 SYNOPSIS

    use FML::Command::Admin::rmcgi;
    $command = new FML::Command::Admin::rmcgi;
    $command->process($curproc, $command_context);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up cgi scripts for the specified domain.

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


# Descriptions: set up a new mailing list.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $options        = $curproc->command_line_options();
    my $config         = $curproc->config();
    my $ml_domain      = $command_context->get_ml_domain();
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $owner          = $config->{ newml_command_ml_admin_default_address }||
			 $curproc->fml_owner();

    # 1. resolve $ml_home_prefix and assert it.
    $config->set( 'ml_home_prefix', $ml_home_prefix );
    unless (-d $ml_home_prefix) {
	$curproc->mkdir($ml_home_prefix, "mode=public");
    }
    croak("\$ml_home_prefix not exists")      unless -d $ml_home_prefix;
    croak("\$ml_home_prefix is not writable") unless -w $ml_home_prefix;

    # 2. apply cgi creation for all ml ($ml_name@$ml_domain).
    my $ml_list = $curproc->ml_name_list();
    for my $ml_name (@$ml_list) {
	my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
	my $params         = {
	    fml_owner         => $owner,
	    executable_prefix => $curproc->executable_prefix(),
	    ml_name           => $ml_name,
	    ml_domain         => $ml_domain,
	    ml_home_prefix    => $ml_home_prefix,
	    ml_home_dir       => $ml_home_dir,

	    # non conversion ml_name, which is preserved for further use
	    _ml_name          => $ml_name,
	};

	# 2.1 assert: fundamental check
	croak("\$ml_name is not specified")     unless $ml_name;
	croak("\$ml_home_dir is not specified") unless $ml_home_dir;

	# 2.2 update $ml_name and $ml_home_dir to expand variables again.
	$config->set('ml_name',     $ml_name);
	$config->set('ml_home_dir', $ml_home_dir);

	# 2.3 XXX [main] delete CGI scripts for $ml_name@$ml_domain ML.
	use FML::ML::Control;
	my $mlctl = new FML::ML::Control;
	$mlctl->adjust_params_for_virtual_domain($curproc,
						 $command_context,
						 $params);
	$mlctl->set_force_mode();
	$mlctl->delete_cgi_interface($curproc, $command_context, $params);
    }
}


# Descriptions: show cgi menu for newml command.
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
# Return Value: NUM
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


# Descriptions: check if we should update alias files.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM
sub is_update_alias
{
    my ($self, $curproc, $command_context) = @_;
    my $option = $curproc->command_line_cui_specific_options() || {};

    if (defined $option->{ 'update-alias' }) {
	return( $option->{ 'update-alias' } eq 'no' ? 0 : 1 );
    }
    else {
	return 1;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::rmcgi first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
