#-*- perl -*-
#
# Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Addr.pm,v 1.17 2004/01/31 04:06:31 fukachan Exp $
#

package FML::Process::Addr;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Addr -- fmladdr, which show all aliases (accounts + aliases).

=head1 SYNOPSIS

    use FML::Process::Addr;
    $curproc = new FML::Process::Addr;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Addr provides the main function for C<fmladdr>.

C<fmladdr> command shows all aliases (accounts + aliases) but
C<fmlalias> command shows only aliases without accounts.

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


# Descriptions: ordinary constructor
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

    my $eval = $config->get_hook( 'fmladdr_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmladdr_prepare_end_hook' );
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

    my $eval = $config->get_hook( 'fmladdr_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    if (0) {
	print STDERR "Error: missing argument(s)\n";
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmladdr_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<fmladdr>.

It kicks off C<_fmladdr()> for fmladdr.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _fmladdr().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $myname = $curproc->myname();
    my $argv   = $curproc->command_line_argv();

    $curproc->_fmladdr();
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

    my $eval = $config->get_hook( 'fmladdr_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'fmladdr_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 help()

show help.

=cut


# Descriptions: show help
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

Usage: $name [options]

-n   show fml specific aliases.

[BUGS]
	support only fml8 + postfix case.
	also, we assume /etc/passwd exists.

_EOF_
}


=head2 _fmladdr()

show all aliases (accounts + aliases).
show only accounts if -n option specified.

=cut


# Descriptions: show all aliases (accounts + aliases).
#               show only accounts if -n option specified.
#    Arguments: OBJ($curproc)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _fmladdr
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    my $eval = $config->get_hook( 'fmladdr_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # show only accounts if -n option specified.
    my $options = $curproc->command_line_options();
    my $mode    = $options->{ n } ? 'fmlonly' : 'all';

    use FML::MTA::Control;
    my $mta     = new FML::MTA::Control;
    my $aliases = $mta->get_aliases_as_hash_ref($curproc, {}, {
        mta_type => 'postfix',
	mode     => $mode,
    });

    use FML::Sys::User;
    my $sys  = new FML::Sys::User $curproc;
    my $list = $sys->get_user_list();

    for my $user (keys %$list) {
	# which definition survives ? alias > user ?
	unless (defined $aliases->{ $user }) {
	    $aliases->{ $user } = "$user (LOCAL USER)";
	}
    }

    for my $k (sort keys %$aliases) {
        printf "%-25s => %s\n", $k, $aliases->{ $k };
    }

    $eval = $config->get_hook( 'fmladdr_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
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

FML::Process::Addr first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
