#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: ConfViewer.pm,v 1.30 2004/04/23 04:10:36 fukachan Exp $
#

package FML::Process::ConfViewer;
use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::ConfViewer -- show configuration variables.

=head1 SYNOPSIS

    use FML::Process::ConfViewer;
    $curproc = new FML::Process::ConfViewer;
       ...
    $curproc->run();
       ...

=head1 DESCRIPTION

FML::Process::ConfViewer provides the main function for C<fmlconf>.

=head1 METHODS

=head2 new($args)

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 prepare($args)

fix @INC, adjust ml_* and load configuration files.

=head2 verify_request($args)

show help unless @ARGV.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: FML::Process::ConfViewer object
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: adjust ml_* and load configuration files.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlconf_prepare_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmlconf_prepare_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }
}


# Descriptions: check @ARGV, call help() if needed
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv   = $curproc->command_line_argv();
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlconf_verify_request_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }

    if (length(@$argv) == 0 || (not $argv->[0])) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlconf_verify_request_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }
}


=head2 run($args)

the top level dispatcher for C<fmlconf>.

=cut


# Descriptions: just a switch, call _fmlconf().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlconf_run_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }

    $curproc->_fmlconf();

    $eval = $config->get_hook( 'fmlconf_run_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }
}


=head2 help()

show help.

=cut


# Descriptions: show help.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub help
{
    my ($curproc, $args) = @_;
    my $name = $curproc->myname();

print <<"_EOF_";

Usage: $name [-n] \$ml_name

          show all configuration variables

-n        show only difference from default

_EOF_
}


# Descriptions: dummy.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'fmlconf_finish_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }

    $eval = $config->get_hook( 'fmlconf_finish_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	$curproc->logwarn($@) if $@;
    }
}


# Descriptions: show configurations variables in the sytle "key = value".
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fmlconf
{
    my ($curproc) = @_;
    my $config  = $curproc->config();
    my $options = $curproc->command_line_options();
    my $mode    = $options->{ n } ? 'difference_only' : 'all';
    my $argv    = $curproc->command_line_argv();

    # if variable name is given, show the value.
    if (defined $argv->[1]) {
	my $k = $argv->[1];
	print "$k = ", $config->{ $k }, "\n";
    }
    else {
	$config->dump_variables({ mode => $mode });
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::ConfViewer first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
