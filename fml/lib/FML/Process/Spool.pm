#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Spool.pm,v 1.15 2002/04/15 04:01:47 fukachan Exp $
#

package FML::Process::Spool;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

my $debug = 0;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Spool -- spool handling

=head1 SYNOPSIS

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

    my $eval = $config->get_hook( 'fmlspool_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlspool_prepare_end_hook' );
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

    my $eval = $config->get_hook( 'fmlspool_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlspool_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

call the actual thread tracking system.

=cut

# Descriptions: convert text format article to HTML by Mail::Message::ToHTML
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load modules, create HTML files and directories
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $src_dir = $config->{ spool_dir };
    my $options = $curproc->command_line_options();

    my $eval = $config->get_hook( 'fmlspool_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # article object to handle subdir
    use FML::Article;
    my $article = new FML::Article $curproc;

    # use $src_dir if --dstdir=DIR not specified.
    my $dst_dir = defined $options->{dstdir} ? $options->{dstdir} : $src_dir;
    my $optargs = {
	article => $article,
	src_dir => $src_dir, 
	dst_dir => $dst_dir, 
    };

    # XXX you can specify the spool type by --style=subdir but only
    # XXX "subdir" is supported now :)
    if (defined $options->{ convert }) {
	$curproc->_convert($args, $optargs);
	$curproc->_check($args, $optargs);
    }
    else {
	# show status by default for "Principle of Least Surprise".
	$curproc->_check($args, $optargs);
    } 

    $eval = $config->get_hook( 'fmlspool_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


sub _convert
{
    my ($curproc, $args, $optargs) = @_;
    my $src_dir = $optargs->{ src_dir };
    my $dst_dir = $optargs->{ dst_dir };
    my $article = $optargs->{ article };

    print STDERR "converting $src_dir to subdir style...\n";

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	my $target = '';
	my $tmpnew = '';

	while (defined($_ = $dh->read)) { 
	    next if /^\./;
	    $target = File::Spec->catfile($src_dir, $_);
	    $tmpnew = File::Spec->catfile($src_dir, $_ . ".new.$$");

	    if (-d $target) {
		print STDERR "   $target is a subdir.\n";
	    }
	    elsif (-f $target) {
		my $filepath   = $article->filepath($_);
		my $subdirpath = $article->subdirpath($_);
		rename($target, $tmpnew);
		mkdir($subdirpath, 0700);
		rename($tmpnew, $filepath);

		if (-f $filepath) {
		    print STDERR "   mv $target $filepath\n";
		}
		else {
		    print STDERR "   Error: fail to mv $target $filepath\n";
		}
	    }
	}
    }

    print STDERR "done.\n\n";
}


sub _check
{
    my ($curproc, $args, $optargs) = @_;
    my $src_dir  = $optargs->{ src_dir };
    my $suffix   = '';

    my ($num_file, $num_dir) = _scan_dir( $src_dir );

    print STDERR "spool directory = $src_dir\n";

    $suffix = $num_file > 1 ? 's' : '';
    printf STDERR "%20d %s\n", $num_file, "file$suffix";

    $suffix = $num_dir > 1 ? 's' : '';
    printf STDERR "%20d %s\n", $num_dir, "subdir$suffix";
}


sub _scan_dir
{
    my ($src_dir) = @_;
    my $num_dir  = 0;
    my $num_file = 0;
    my $f = '';

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	while (defined($_ = $dh->read)) { 
	    next if /^\./;

	    $f = File::Spec->catfile($src_dir, $_);
	    if (-f $f) {
		$num_file++;
	    }
	    elsif (-d $f) {
		$num_dir++; 
		my ($x_num_file, $x_num_dir) = _scan_dir( $f );
		$num_file += $x_num_file;
		$num_dir  += $x_num_dir;
	    }
	}
    }

    return ($num_file, $num_dir);
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

Usage: $name [--convert] [--style=STR] [-I DIR] DIR

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

    my $eval = $config->get_hook( 'fmlspool_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlspool_finish_end_hook' );
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

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Spool appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
