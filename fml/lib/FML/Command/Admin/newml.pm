#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newml.pm,v 1.79 2004/03/16 12:53:40 fukachan Exp $
#

package FML::Command::Admin::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::newml - set up a new mailing list.

=head1 SYNOPSIS

    use FML::Command::Admin::newml;
    $obj = new FML::Command::Admin::newml;
    $obj->newml($curproc, $command_args);

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


# Descriptions: set up a new mailing list.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options        = $curproc->command_line_options();
    my $config         = $curproc->config();

    # XXX-TODO: can we here use $curproc->ml_*() ?
    my $ml_name        = $config->{ ml_name };
    my $ml_domain      = $config->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $owner          = $config->{ newml_command_ml_admin_default_address }||
			 $curproc->fml_owner();
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

    # mkdir $ml_home_prefix if could.
    unless (-d $ml_home_prefix) {
	$curproc->mkdir($ml_home_prefix, "mode=public");
    }

    # fundamental check
    croak("\$ml_name is not specified")     unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;
    croak("\$ml_home_prefix not exists")    unless -d $ml_home_prefix;

    # check if $ml_home_prefix is writable
    croak("\$ml_home_prefix is not writable") unless -w $ml_home_prefix;

    # update $ml_home_prefix and $ml_home_dir to expand variables again.
    $config->set( 'ml_home_prefix', $ml_home_prefix );
    $config->set( 'ml_home_dir',    $ml_home_dir );

    use FML::ML::Control;
    my $control = new FML::ML::Control;

    # define _ml_name_xxx variables in $parms for virtual domain
    $control->adjust_params_for_virtual_domain($curproc,
					       $command_args,
					       $params);

    # "makefml --force newml elena" creates elena ML even if elena
    # already exists.
    unless ($self->get_force_mode($curproc, $command_args)) {
	if (-d $ml_home_dir) {
	    # XXX-TODO: $curproc->logwarn() ?
	    warn("$ml_name ml_home_dir($ml_home_dir) already exists");
	    return ;
	}
    }

    # check the duplication of alias keys in MTA aliases
    # Example: search among all entries in postfix $alias_maps and /etc/passwd
    # XXX we assume /etc/passwd exists for backword compatibility
    # XXX on all unix plathomes.
    if ($control->is_mta_alias_maps_has_ml_entry($curproc,$params,$ml_name)) {
	unless ($self->get_force_mode($curproc, $command_args)) {
	    # XXX-TODO: $curproc->logwarn() ?
	    warn("$ml_name already exists (somewhere in MTA aliases)");
	    return ;
	}
    }

    # 0. creat $ml_home_dir
    # 1. install $ml_home_dir/{config.cf,include,include-ctl}
    # 2. set up aliases
    # 3. prepare mail archive at ~fml/public_html/$domain/$ml/ ?
    # 4. prepare cgi interface at ?
    #      ~fml/public_html/cgi-bin/fml/$domain/admin/
    #    prepare thread cgi interface at ?
    #      ~fml/public_html/cgi-bin/fml/$domain/threadview.cgi ?
    # 5. prepare listinfo url
    $control->init_ml_home_dir($curproc, $command_args, $params);
    $control->install_template_files($curproc, $command_args, $params);
    $control->update_aliases($curproc, $command_args, $params);
    $control->setup_mail_archive_dir($curproc, $command_args, $params);
    $control->setup_cgi_interface($curproc, $command_args, $params);
    $control->setup_listinfo($curproc, $command_args, $params);
}


# Descriptions: show cgi menu for newml command.
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

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::newml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
