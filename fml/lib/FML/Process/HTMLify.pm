#-*- perl -*-
#
# Copyright (C) 2000-2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: HTMLify.pm,v 1.10 2002/02/17 03:07:56 fukachan Exp $
#

package FML::Process::HTMLify;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

my $debug = 0;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::HTMLify -- htmlify articles

=head1 SYNOPSIS

See C<Mail::HTML::Lite> module.

=head1 DESCRIPTION

This class drives thread tracking system in the top level.

=head1 METHODS

=head2 C<new($args)>

create a C<FML::Process::Kernel> object and return it.

=head2 C<prepare()>

dummy :)

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: inherit FML::Process::Kernel
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config }; 

    my $eval = $config->get_hook( 'fmlhtmlify_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlhtmlify_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config }; 

    my $eval = $config->get_hook( 'fmlhtmlify_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlhtmlify_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

call the actual thread tracking system.

=cut

# Descriptions: convert text format article to HTML by Mail::HTML::Lite
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load modules, create HTML files and directories
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config }; 
    my $argv    = $curproc->command_line_argv();
    my $options = $curproc->command_line_options();
    my $src_dir = $argv->[0];
    my $dst_dir = $argv->[1];

    print STDERR "htmlify\t$src_dir =>\n\t\t$dst_dir\n" if $debug;

    my $eval = $config->get_hook( 'fmlhtmlify_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # prepend $opt_I as @INC
    if (defined $options->{ I }) {
	print STDERR "\t\tprepend $options->{ I } (\@INC)\n" if $debug;
	unshift(@INC, $options->{ I });
    }

    unless (-d $src_dir) {
	croak("no such source directory");
    }

    if (defined $dst_dir) {
        unless (-d $dst_dir) {
            use File::Utils qw(mkdirhier);
            mkdirhier($dst_dir, 0755);
        }

	eval q{
	    use Mail::HTML::Lite;
	    &Mail::HTML::Lite::htmlify_dir($src_dir, {
		directory => $dst_dir,
	    });
	};
	croak($@) if $@;
    }
    else {
        croak("no destination directory\n");
    }

    $eval = $config->get_hook( 'fmlhtmlify_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: show help
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    use File::Basename;
    my $name = basename($0);

print <<"_EOF_";

Usage: $name [-I dir] src_dir dst_dir

options:

-I dir      prepend dir into include path

_EOF_
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config }; 

    my $eval = $config->get_hook( 'fmlhtmlify_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlhtmlify_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub DESTROY {}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
