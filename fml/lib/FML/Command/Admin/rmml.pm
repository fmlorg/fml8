#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: rmml.pm,v 1.16 2003/08/29 15:33:59 fukachan Exp $
#

package FML::Command::Admin::rmml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::rmml - remove the specified mailing list

=head1 SYNOPSIS

    use FML::Command::Admin::rmml;
    $obj = new FML::Command::Admin::rmml;
    $obj->rmml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

remove the mailing list directory (precisely speaking,
we just rename ml -> @ml)
and the corresponding alias entries.

=head1 METHODS

=head2 process($curproc, $command_args)

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


# Descriptions: not need lock in the first time
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: set up a new mailing list
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options        = $curproc->command_line_options();
    my $config         = $curproc->config();
    my $ml_name        = $config->{ ml_name };
    my $ml_domain      = $config->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $params         = {
	fml_owner         => $curproc->fml_owner(),
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,
    };

    # fundamental check
    croak("\$ml_name is not specified")     unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;

    # update $ml_home_prefix and expand variables again.
    $config->set( 'ml_home_prefix' , $ml_home_prefix );

    # check if $ml_name already exists.
    unless (-d $ml_home_dir) {
	warn("no such ml ($ml_home_dir)");
	return;
    }

    # o.k. here we go!
    $self->_remove_ml_home_dir($curproc, $command_args, $params);
    $self->_remove_aliases($curproc, $command_args, $params);
}


# Descriptions: remove $ml_home_dir and update aliases if needed
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: remove ml_home_dir, update aliases entry
# Return Value: none
sub _remove_ml_home_dir
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $ml_name        = $params->{ ml_name };
    my $ml_domain      = $params->{ ml_domain };
    my $ml_home_prefix = $params->{ ml_home_prefix };
    my $ml_home_dir    = $params->{ ml_home_dir };

    print STDERR "removing ml_home_dir for $ml_name\n";

    # /var/spool/ml/elena -> /var/spool/ml/@elena
    use File::Spec;
    my $removed_dir = File::Spec->catfile($ml_home_prefix, '@'.$ml_name);
    rename($ml_home_dir, $removed_dir);

    if (-d $removed_dir && (! -d $ml_home_dir)) {
	print STDERR "\tremoved.\n";
    }
    else {
	print STDERR "\tfailed.\n";
    }
}


# Descriptions: remove aliases entry
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: update aliases entry
# Return Value: none
sub _remove_aliases
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config  = $curproc->config();
    my $ml_name = $params->{ ml_name };
    my $list    = $config->get_as_array_ref('newml_command_mta_config_list');

    eval q{
	use FML::MTAControl;

	for my $mta (@$list) {
	    my $optargs = { mta_type => $mta };
	    my $obj = new FML::MTAControl;
	    $obj->remove_alias($curproc, $params, $optargs);
	    $obj->update_alias($curproc, $params, $optargs);
	    $obj->remove_virtual_map($curproc, $params, $optargs);
	    $obj->update_virtual_map($curproc, $params, $optargs);
	}
    };
    croak($@) if $@;
}


# Descriptions: show cgi menu for rmml
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: create home directories, update aliases, ...
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
        use FML::CGI::Admin::ML;
        my $obj = new FML::CGI::Admin::ML;
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

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::rmml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
