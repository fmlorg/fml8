#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: rmml.pm,v 1.25 2002/04/21 13:52:02 fukachan Exp $
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

remove mailing list directory (precisely speaking, we just rename ml -
> @ml) and the corresponding alias entries.

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
    my $config         = $curproc->{ 'config' };
    my ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir) =
	$self->_get_domain_info($curproc, $command_args);
    my $params         = {
	fml_owner         => $curproc->fml_owner(),
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,
    };

    # fundamental check
    croak("\$ml_name is not specified") unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;

    # update $ml_home_prefix and expand variables again.
    $config->set( 'ml_home_prefix' , $ml_home_prefix );

    # "makefml --force rmml elena" makes elena ML even if elena
    # already exists.
    my $found = 0;
    unless (defined $options->{ force } ) {
	if (-d $ml_home_dir) {
	    $found = 1;
	}
    }

    unless ($found) {
	warn("no such ml");
	return;
    }

    # /var/spool/ml/elena -> /var/spool/ml/@elena
    use File::Spec;
    my $removed_dir = File::Spec->catfile($ml_home_prefix, '@'.$ml_name);
    rename($ml_home_dir, $removed_dir);

    if (-d $removed_dir && (! -d $ml_home_dir)) {
	print STDERR "$ml_name home_dir removed.\n";
    }

    $self->_update_aliases($curproc, $command_args, $params);
}


# Descriptions: check argument and prepare virtual domain information
#               if needed.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: ARRAY
sub _get_domain_info
{
    my ($self, $curproc, $command_args) = @_;
    my $ml_name        = $command_args->{ 'ml_name' };
    my $ml_domain      = $curproc->default_domain();
    my $ml_home_prefix = '';
    my $ml_home_dir    = '';

    # virtual domain support e.g. "makefml newml elena@nuinui.net"
    if ($ml_name =~ /\@/o) {
	# overwrite $ml_name
	($ml_name, $ml_domain) = split(/\@/, $ml_name);
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }
    # default domain: e.g. "makefml newml elena"
    else {
	$ml_home_prefix = $curproc->ml_home_prefix();
    }

    eval q{ use File::Spec;};
    $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);

    # save for convenience
    $self->{ _ml_name   } = $ml_name;
    $self->{ _ml_domain } = $ml_domain;

    return ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir);
}


# Descriptions: remove aliases entry
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: update aliases entry
# Return Value: none
sub _update_aliases
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config  = $curproc->{ config };
    my $ml_name = $self->{ _ml_name };
    my $alias   = $config->{ mail_aliases_file };

    # append
    if ($self->_alias_has_ml_entry($alias, $ml_name)) {
	$self->_remove_alias_entry($alias, $ml_name);

	my $prog = $config->{ path_postalias };
	system "$prog $alias";
    }
    else {
	warn("no such ml in aliases");
    }
}


# Descriptions: $alias file has an $ml_name entry or not
#    Arguments: OBJ($self) STR($alias) STR($ml_name)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub _alias_has_ml_entry
{
    my ($self, $alias, $ml_name) = @_;

    use FileHandle;
    my $fh = new FileHandle $alias;
    if (defined $fh) {
	while (<$fh>) {
	    if (/ALIASES $ml_name\@/) {
		return 1;
	    }
	}
	$fh->close;
    }

    return 0;
}


# Descriptions: $alias file has an $ml_name entry or not
#    Arguments: OBJ($self) STR($alias) STR($ml_name)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub _remove_alias_entry
{
    my ($self, $alias, $ml_name) = @_;
    my $alias_new = $alias."new.$$";
    my $removed   = 0;

    use FileHandle;
    my $rh = new FileHandle $alias;
    my $wh = new FileHandle "> $alias_new";
    if (defined $rh && defined $wh) {
      LINE:
	while (<$rh>) {
	    if (/\<ALIASES\s+$ml_name\@/ .. /\<\/ALIASES\s+$ml_name\@/) {
		$removed++;
		next LINE;
	    }

	    print $wh $_;
	}
	$wh->close;
	$rh->close;

	if ($removed > 3) {
	    if (rename($alias_new, $alias)) {
		print STDERR "$ml_name aliases removed.\n";
	    }
	    else {
		print STDERR "warning: fail to rename alias files.\n";
	    }
	}
    }
    else {
	warn("cannot open $alias")     unless defined $rh;
	warn("cannot open $alias_new") unless defined $wh;
    }
}


# Descriptions: show cgi menu for rmml
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
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


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::rmml appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
