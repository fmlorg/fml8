#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.8 2004/01/01 07:29:27 fukachan Exp $
#

package FML::Command::Admin::merge;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::Admin::merge - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

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


# Descriptions: merge other mailing list driver system into fml8.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $options = $command_args->{ options } || [];
    my $src_dir = $options->[ 0 ] || '';

    # XXX-TODO: can we here use $curproc->ml_*() ?
    my $ml_name        = $config->{ ml_name };
    my $ml_domain      = $config->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $owner          = $config->{ newml_command_ml_admin_default_address }||
			 $curproc->fml_owner();
    my $params         = {
	ml_name     => $ml_name,
	ml_domain   => $ml_domain,
	ml_home_dir => $ml_home_dir,

	# old ml_home_dir path (e.g. /var/spool/ml/elena).
	src_dir     => $src_dir,
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

    # get and check argument.
    croak("specify old \$ml_home_dir")       unless $src_dir;
    croak("specify directory as a argument") unless -d $src_dir;

    # update $ml_home_prefix and $ml_home_dir to expand variables again.
    $config->set( 'ml_home_prefix', $ml_home_prefix );
    $config->set( 'ml_home_dir',    $ml_home_dir );

    # HERE WE GO!
    my $ml_list = "$ml_name\@$ml_domain";
    print STDERR "merge configurations at @$options into $ml_list\n";

    use FML::Merge;
    my $merge = new FML::Merge $curproc, $params;
    $merge->set_target_system("fml4");

    # 1. back up .
    $merge->backup_old_config_files();

    # 2. fix include*.
    $merge->disable_include_files();

    # 3. run newml --force.
    use FML::Command::Admin::newml;
    my $ml = new FML::Command::Admin::newml;
    $ml->set_force_mode($curproc, $command_args);
    $ml->process($curproc, $command_args);

    # 4. convert files if needed.
    $merge->convert_list_files();

    return;

    # 5. analyze fml4 configuration and build diff only.
    # 6. translate diff into fml8 cf.
    $merge->merge_into_config_cf();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::merge appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
