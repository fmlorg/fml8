#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: DocViewer.pm,v 1.19 2002/08/14 03:31:56 fukachan Exp $
#

package FML::Process::DocViewer;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::DocViewer -- perldoc wrapper to show a fml module

=head1 SYNOPSIS

    use FML::Process::DocViewer;
    $curproc = new FML::Process::DocViewer;
      ...
    $curproc->run();
      ...

=head1 DESCRIPTION

FML::Process::DocViewer is the main routine of C<fmldoc> program.
It wraps C<perldoc>.

See C<FML::Process::Flow> for the program flow.

=head1 METHODS

=head2 C<new($args)>

standard constructor.
It inherits C<FML::Process::Kernel>.

=head2 C<prepare($args)>

load default configuration files.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: FML::Process::DocViewer object
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: load default configurations
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmldoc_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmldoc_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: check @ARGV and show help if needed
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: may exit.
#               longjmp() to help() if appropriate.
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv   = $curproc->command_line_argv();
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmldoc_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    if (length(@$argv) == 0) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmldoc_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

the main top level dispatcher.
It kicks off internal function C<_fmlconf($args)> for
C<fmlconf($args)>.

=cut


# Descriptions: just a switch, call _fmldoc()
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $curproc->myname();
    my $argv   = $curproc->command_line_argv();

    $curproc->_fmldoc($args);
}


# Descriptions: fmldoc wrapper / top level dispacher
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _fmldoc
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $curproc->myname();
    my $argv   = $curproc->command_line_argv();

    my $eval = $config->get_hook( 'fmldoc_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    my (@opts);
    push(@opts, '-v') if $args->{ options }->{ v };
    push(@opts, '-t') if $args->{ options }->{ t };
    push(@opts, '-u') if $args->{ options }->{ u };
    push(@opts, '-m') if $args->{ options }->{ m };
    push(@opts, '-l') if $args->{ options }->{ l };

    # add path for perl executatbles e.g. /usr/local/bin
    eval q{
	use Config;
	$ENV{'PATH'} .= ":". $Config{ scriptdir };
	exec 'perldoc', @opts, @$argv;
    };
    croak($@);

    $eval = $config->get_hook( 'fmldoc_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
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

Usage: $name MODULE

   For example,
   $name FML::Process::Kernel

_EOF_
}


=head2 finish()

finalize.

=cut


# Descriptions: clean up in the end of the curreen process.
#               return error messages et. al.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: queue flush
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmldoc_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmldoc_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::DocViewer first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
