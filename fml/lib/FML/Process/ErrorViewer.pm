#-*- perl -*-
#
# Copyright (C) 2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: ErrorViewer.pm,v 1.1 2003/01/05 02:22:17 fukachan Exp $
#

package FML::Process::ErrorViewer;
use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use FML::Log qw(Log LogWarn LogError);
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::ErrorViewer -- show bounce messages status

=head1 SYNOPSIS

    use FML::Process::ErrorViewer;
    $curproc = new FML::Process::ErrorViewer;
       ...
    $curproc->run();
       ...

=head1 DESCRIPTION

FML::Process::ErrorViewer provides the main function for C<fmlerror>.

=head1 METHODS

=head2 new($args)

ordinary constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 prepare($args)

fix @INC, adjust ml_* and load configuration files.

=head2 verify_request($args)

show help unless @ARGV.

=cut


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: FML::Process::ErrorViewer object
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
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlerror_prepare_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmlerror_prepare_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
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
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlerror_verify_request_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    if (length(@$argv) == 0 || (not $argv->[0])) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlerror_verify_request_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


=head2 C<run($args)>

the top level dispatcher for C<fmlconf>.

It kicks off internal function C<_fmlconf($args)> for C<fmlconf>.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _fmlconf()
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $curproc->myname();
    my $argv   = $curproc->command_line_argv();

    my $eval = $config->get_hook( 'fmlerror_run_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    $curproc->_fmlerror($args);

    $eval = $config->get_hook( 'fmlerror_run_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


=head2 help()

show help.

=cut


# Descriptions: show help
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub help
{
    my ($curproc, $args) = @_;
    my $name = $curproc->myname();

print <<"_EOF_";

Usage: $name \$ml_name

_EOF_
}


# Descriptions: dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlerror_finish_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    $eval = $config->get_hook( 'fmlerror_finish_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


=head2 C<_fmlconf($args)> (INTERNAL USE)

run dump_variables of C<FML::Config>.

=cut


# Descriptions: show error messages
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _fmlerror
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    use FML::Error;
    my $obj  = new FML::Error $curproc;
    my $data = $obj->analyze();
    my $info = $obj->get_data_detail();

    my ($k, $v);
    while (($k, $v) = each %$info) {
	if (ref($v) eq 'ARRAY') {
	    print "$k => (@$v)\n";
	}
	else {
	    print "$k => $v\n";
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::ErrorViewer first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
