#-*- perl -*-
#
# Copyright (C) 2004,2005 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Emulate.pm,v 1.8 2005/08/10 11:28:44 fukachan Exp $
#

package FML::Process::Emulate;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Emulate -- fml version 4's fml.pl emulator.

=head1 SYNOPSIS

   use FML::Process::Emulate;
   ...

See L<FML::Process::Flow> for details of the fml flow.

=head1 DESCRIPTION

C<FML::Process::Flow::ProcessStart($obj, $args)> drives the fml flow
where C<$obj> is the object C<FML::Process::$module::new()> returns.

=head1 METHOD

=head2 new($args)

create C<FML::Process::Emulate> object.
C<$curproc> is the object C<FML::Process::Kernel> returns but
we bless it as C<FML::Process::Emulate> object again.

=cut


# Descriptions: standard constructor.
#               sub class of FML::Process::Kernel
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(FML::Process::Emulate)
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 prepare($args)

forward the request to the base class.
adjust ml_* and load configuration files.

=cut


# Descriptions: prepare miscellaneous work before the main routine starts.
#               adjust ml_* and load configuration files.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config           = $curproc->config();
    my $resolver_args    = {
	fallback => "config_cf_generate_from_config_ph",
    };

    # load only default configuration.
    my $default_config_cf = $curproc->default_config_cf_filepath();
    $config->load_file($default_config_cf);

    # go !
    $curproc->ml_variables_resolve($resolver_args);
    $curproc->config_cf_files_load();
    $curproc->env_fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();
    $curproc->_fml4_emulate();
}


# Descriptions: emulate fml4 (fml.pl in fact) process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fml4_emulate
{
    my ($curproc) = @_;
    my $option    = $curproc->command_line_options || {};
    my $myname    = $curproc->myname();

    if ($myname eq 'mead.pl') {
	$curproc->_fml4_emulate_error_process();
    }
    elsif ($myname eq 'msend.pl') {
	$curproc->_fml4_emulate_digest_process();
    }
    elsif (defined $option->{ ctladdr } && $option->{ ctladdr }) {
	$curproc->_fml4_emulate_command_mail_process();
    }
    else {
	$curproc->_fml4_emulate_post_article_process();
    }
}


# Descriptions: emulate fml4 (fml.pl in fact) process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fml4_emulate_post_article_process
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    $curproc->log("start as article_post mode");

    eval q{
	use FML::Process::Distribute;
	unshift(@ISA, "FML::Process::Distribute");
    };
    if ($@) {
	$curproc->logerror($@);
	croak("failed to initialize article_post process.");
    }

    if ($config->yes('use_article_post_function')) {
	$curproc->incoming_message_parse();
    }
    else {
	$curproc->logerror("use of distribute program prohibited");
	exit(0);
    }
}


# Descriptions: emulate fml4 (fml.pl in fact) process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fml4_emulate_command_mail_process
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    $curproc->log("start as command_mail mode");

    eval q{
	use FML::Process::Command;
	unshift(@ISA, "FML::Process::Command");
    };
    if ($@) {
	$curproc->logerror($@);
	croak("failed to initialize command_mail process.");
    }

    if ($config->yes('use_command_mail_function')) {
	$curproc->incoming_message_parse();
    }
    else {
	$curproc->logerror("use of command_mail program prohibited");
	exit(0);
    }
}


# Descriptions: emulate error (mead.pl in fact) process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fml4_emulate_error_process
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    # |/usr/local/fml/libexec/mead.pl \
    #  -E /usr/local/fml -S /var/spool/ml -D /var/spool/ml/elena

    # XXX-TODO: disabled for test ?
    $curproc->log("start as error mail analyzer mode");

    exit(0);

    eval q{
	use FML::Process::Error;
	unshift(@ISA, "FML::Process::Error");
    };
    if ($@) {
	$curproc->logerror($@);
	croak("failed to initialize error_mail process.");
    }

    if ($config->yes('use_error_mail_analyzer_function')) {
	$curproc->incoming_message_parse();
    }
    else {
	$curproc->logerror("use of error_mail program prohibited");
	exit(0);
    }
}


# Descriptions: emulate digest (msend.pl in fact) process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fml4_emulate_digest_process
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    # /usr/local/fml/msend.pl /var/spool/ml/elena
    $curproc->log("start as article digest mode");

    # XXX-TODO: disabled for test ?
    exit(0);

    eval q{
	use FML::Process::Digest;
	unshift(@ISA, "FML::Process::Digest");
    };
    if ($@) {
	$curproc->logerror($@);
	croak("failed to initialize digest_mail process.");
    }

    if ($config->yes('use_article_digest_function')) {
	;
    }
    else {
	$curproc->logerror("use of article digest program prohibited");
	exit(0);
    }
}


=head1 FALLBACK FOR ERROR RECOVORY

=head2 config_cf_generate_from_config_ph($fallback_args)

When fml.pl runs, it generates config.cf if config.cf does not exist.
This code is a subset of "fml $ml mergeml" command.

=cut


# Descriptions: generate config.cf if it does not exist.
#    Arguments: OBJ($curproc) HASH_REF($fallback_args)
# Side Effects: none
# Return Value: none
sub config_cf_generate_from_config_ph
{
    my ($curproc, $fallback_args) = @_;
    my $ml_home_dir    = '';
    my $config_cf_path = $fallback_args->{ config_cf_path };
    my $config_ph_path = $fallback_args->{ config_cf_path };
    $config_ph_path    =~ s/config.cf/config.ph/;

    use File::stat;
    my $stat_ph = stat($config_ph_path);
    my $stat_cf = stat($config_cf_path);
    if (! -f $config_ph_path && -f $config_cf_path) {
	# fml8 normal case.
	# OK, DO NOTHING.
    }
    elsif (($stat_ph->mtime > $stat_cf->mtime) ||
	   (-f $config_ph_path && ! -f $config_cf_path)) {
	# fml4 -> fml8 case (config.ph -> config.cf).
	$curproc->log("generate config.cf from config.ph");
	use File::Basename;
	my $ml_home_dir = dirname($config_cf_path);
	my $params = {
	    ml_home_dir   => $ml_home_dir,
	    src_dir       => $ml_home_dir,
	    target_system => "fml4",
	};
	$curproc->_fml4_merge($params);
    }
    elsif (-f $config_ph_path && -f $config_cf_path) {
	# OK, DO NOTHING.
    }
    else {
	# ? abnormal ???
    }
}


# Descriptions: merge ML configurations.
#    Arguments: OBJ($curproc) HASH_REF($params)
# Side Effects: none
# Return Value: none
sub _fml4_merge
{
    my ($curproc, $params) = @_;
    my $src_dir = $params->{ src_dir }       || undef;
    my $system  = $params->{ target_system } || undef;

    use FML::Merge;
    my $merge = new FML::Merge $curproc, $params;
    $merge->set_target_system($system);

    # 1. back up .
    $merge->backup_old_config_files();

    # XXX mergeml do this, but emulator not need this.
    #   2. fix include*.
    #   3. run newml --force.
    use FML::ML::Control;
    my $control = new FML::ML::Control;
    $control->install_config_cf($curproc, {}, $params);

    # 4. convert files if needed.
    $merge->convert_list_files();

    # XXX mergeml do this, but emulator not need this.
    #   5. analyze fml4 configuration and build diff only.
    #   6. translate diff into fml8 cf.
    $merge->merge_into_config_cf();

    # XXX mergeml do this, but emulator not need this.
    # 7. warning.
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
reEmulate it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Emulate first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
