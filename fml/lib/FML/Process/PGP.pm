#-*- perl -*-
#
# Copyright (C) 2005,2006 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: PGP.pm,v 1.5 2005/08/10 15:03:27 fukachan Exp $
#

package FML::Process::PGP;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::PGP -- wrap pgp/gpg commands.

=head1 SYNOPSIS

    use FML::Process::PGP;
    $curproc = new FML::Process::PGP;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::PGP wraps a pgp/gpg command processing.

See C<FML::Process::Flow> for the flow detail.

=head1 METHODS

=head2 new($args)

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 prepare($args)

load config files and fix @INC.

=head2 verify_request($args)

dummy.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: load config files and fix @INC.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlpgp_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->ml_variables_resolve();
    $curproc->config_cf_files_load();
    $curproc->env_fix_perl_include_path();

    $eval = $config->get_hook( 'fmlpgp_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: check @ARGV, call help() if needed.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv   = $curproc->command_line_argv();
    my $len    = $#$argv + 1;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlpgp_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    if ($#$argv < 1) {
	print STDERR "Error: missing argument(s)\n";
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlpgp_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<fmlpgp>.

It kicks off C<_fmlpgp_dispatch()> for fmlpgp.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _fmlpgp_dispatch().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $myname = $curproc->myname();
    my $argv   = $curproc->command_line_argv();

    $curproc->_fmlpgp_dispatch();
}


=head2 finish

dummy.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlpgp_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'fmlpgp_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 help()

show help.

=cut


# Descriptions: show help.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    my $name = $0;
    eval {
	use File::Basename;
	$name = basename($0);
    };

print <<"_EOF_";

Usage: $name \$ml_name [options] PGP/GPG parameters ...

[options]
    --article-post-auth
    --command-mail-auth
    --admin-command-mail-auth
    --article-post-encrypt

_EOF_
}


=head2 _fmlpgp_dispatch()

set up environment variables e.g. PGPPATH and dispatch the
corresponding command.

=cut


# Descriptions: dispatcher with environment variable setting.
#    Arguments: OBJ($curproc)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _fmlpgp_dispatch
{
    my ($curproc)  = @_;
    my $config     = $curproc->config();
    my $argv       = $curproc->command_line_raw_argv();
    my @fixed_argv = ();

    my $eval = $config->get_hook( 'fmlpgp_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # XXX-TODO: mode hard-coded.
    # mode definitions.
    my $key   = 'article-post|command-mail|admin-command-mail';
    my $c_key = 'pgp_command_wrapper_default_mode';
    my $mode  = $config->{ $c_key } || 'admin_command_mail_auth';

    # parse raw arguments by myself.
    for my $arg (@$argv) {
	my $_arg = $arg;
	$_arg =~ s/_/-/g;
	if ($_arg =~ /^--($key)-(auth|encrypt)/) {
	    $mode = sprintf("%s_%s", $1, $2);
	    $mode =~ s/-/_/g;
	}
	else {
	    push(@fixed_argv, $arg);
	}
    }
    shift @fixed_argv;

    # program.
    my $name    = basename($0); $name =~ s/^fml//;
    my $program = $config->{ "path_$name" } || '';

    # execute ...
    if ($program && -x $program) {
	$curproc->_setup_pgp_environment($mode);
	print STDERR "PGPPATH   $ENV{PGPPATH}\n"   if $program =~ /pgp/;
	print STDERR "GNUPGHOME $ENV{GNUPGHOME}\n" if $program =~ /gpg/;
	print STDERR "EXECUTE   $program @fixed_argv\n";
	system $program, @fixed_argv;
	$curproc->_reset_pgp_environment();
    }
    else {
	print STDERR "error: program $name not found\n";
    }

    $eval = $config->get_hook( 'fmlpgp_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: modify PGP related environment variables.
#               create keyring directory if not exists.
#    Arguments: OBJ($curproc) STR($mode)
# Side Effects: PGP related environment variables modified.
#               create keyring directory if not exists.
# Return Value: none
sub _setup_pgp_environment
{
    my ($curproc, $mode) = @_;
    my $config = $curproc->config();

    # PGP2/PGP5/PGP6
    my $pgp_config_dir = $config->{ "${mode}_pgp_config_dir" };
    $ENV{'PGPPATH'}    = $pgp_config_dir;

    # GPG
    my $gpg_config_dir = $config->{ "${mode}_gpg_config_dir" };
    $ENV{'GNUPGHOME'}  = $gpg_config_dir;

    unless (-d $pgp_config_dir) {
	$curproc->mkdir($pgp_config_dir, "mode=private");
    }

    unless (-d $gpg_config_dir) {
	$curproc->mkdir($gpg_config_dir, "mode=private");
    }

    #
    # CONVENSIONAL NAME.
    #
    $curproc->_symlink_admin_dir("pgp");
    $curproc->_symlink_admin_dir("gpg");
}


# Descriptions: symlink to conventional naming dir if needed.
#    Arguments: OBJ($curproc) STR($pgp)
# Side Effects: create symlink(2) if needed.
# Return Value: none
sub _symlink_admin_dir
{
    my ($curproc, $pgp) = @_;
    my $config = $curproc->config();
    my $dir    = $config->{"admin_command_mail_auth_${pgp}_config_dir"};
    my $alias  = $config->{"admin_command_mail_auth_${pgp}_config_dir_alias"};

    my $cur_dir = `pwd`;
    chomp $cur_dir;

    if (-d $dir && ! -l $alias) {
	use File::Basename;
	if (dirname($dir) eq dirname($alias)) {
	    chdir dirname($dir);
	    my $_dir   = basename($dir);
	    my $_alias = basename($alias);
	    symlink($_dir, $_alias);
	}
	else {
	    symlink($dir, $alias);
	}
    }

    chdir $cur_dir;
}


# Descriptions: remove PGP related environment variables.
#    Arguments: OBJ($curproc)
# Side Effects: PGP related environment variables modified.
# Return Value: none
sub _reset_pgp_environment
{
    my ($curproc) = @_;
    delete $ENV{'PGPPATH'};
    delete $ENV{'GNUPGHOME'};
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::PGP first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
