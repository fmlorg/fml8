#-*- perl -*-
#
# Copyright (C) 2002,2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Spool.pm,v 1.13 2003/01/02 15:51:49 fukachan Exp $
#

package FML::Process::Spool;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

my $debug = 0;


=head1 NAME

FML::Process::Spool -- small maintenance jobs on the spool directory

=head1 SYNOPSIS

=head1 DESCRIPTION

This class provides utilitiy functions for the spool directory.

=head1 METHODS

=head2 C<new($args)>

create a C<FML::Process::Kernel> object and return it.

=head2 C<prepare($args)>

ajdust ml_* variables, load config files and fix @INC.

=head2 C<verify_request($args)>

show help.

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

    $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

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
    my $argv   = $curproc->command_line_argv();
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlspool_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    if (length(@$argv) == 0 || (not $argv->[0])) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlspool_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

move ml spool to other location.
convert ml spool from plane to subdir if specified.

=cut

#
# XXX-TODO: clean up run() more.
#


# Descriptions: move ml spool to other location.
#               convert ml spool from plane to subdir if specified.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load modules, create HTML files and directories
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };
    my $dst_dir = $config->{ spool_dir };
    my $options = $curproc->command_line_options();
    my $argv    = $curproc->command_line_argv();
    my $numargs = $#$argv;
    my $command = $argv->[ 0 ] || '';

    my $eval = $config->get_hook( 'fmlspool_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # article object to handle subdir
    use FML::Article;
    my $article = new FML::Article $curproc;

    # XXX-TODO: options and argv(s) are appropriate ?
    # use $dst_dir as $src_dir if --srcdir=DIR not specified.
    my $src_dir = $options->{srcdir} || $dst_dir;
    my $optargs = {
	article => $article,
	src_dir => $src_dir,
	dst_dir => $dst_dir,
    };

    # XXX-TODO: you can specify the spool type by --style=subdir
    # XXX-TODO: but only "subdir" is supported now :)
    if ($numargs > 0) {
	if ($command eq 'convert') {
	    print "convert spool of $ml_name ML.\n\n";
	    $curproc->_convert($args, $optargs);
	    $curproc->_check($args, $optargs);
	}
	elsif ($command eq 'check') {
	    $curproc->_check($args, $optargs);
	}
	else {
	    croak("command=$command unknown");
	}
    }
    else {
	# show status by default for "Principle of Least Surprise".
	$curproc->_check($args, $optargs);
    }

    $eval = $config->get_hook( 'fmlspool_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: convert files from src_dir/ to dst_dir/
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_RER($optargs)
# Side Effects: none
# Return Value: none
sub _convert
{
    my ($curproc, $args, $optargs) = @_;
    my $src_dir  = $optargs->{ src_dir };
    my $dst_dir  = $optargs->{ dst_dir };
    my $article  = $optargs->{ article };
    my $use_link = 0;

    if ($src_dir eq $dst_dir) {
	$src_dir .= ".old";
	rename($dst_dir, $src_dir);
	$curproc->mkdir($dst_dir, "mode=private");
	$use_link = 1;
    }

    print STDERR "converting $dst_dir from $src_dir\n";

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	my $source = '';

	while (defined($_ = $dh->read)) {
	    next if /^\./o;

	    $source = File::Spec->catfile($src_dir, $_);

	    if (-d $source) {
		print STDERR "   $source is a subdir.\n";
	    }
	    elsif (-f $source) {
		my $subdirpath = $article->subdirpath($_);
		my $filepath   = $article->filepath($_);

		next if -f $filepath;

		# may conflict $subdirpath (directory) name with
		# $source file name.
		if (-f $subdirpath) {
		    croak("$subdirpath file/dir conflict");
		}
		else {
		    unless (-d $subdirpath) {
			$curproc->mkdir($subdirpath, "mode=private");
		    }

		    if (-d $subdirpath) {
			if ($use_link) {
			    link($source, $filepath);
			}
			else {
			    use File::Utils qw(copy);
			    copy($source, $filepath);
			}
		    }
		    else {
			croak("cannot mkdir $filepath\n");
		    }
		}

		if (-f $filepath) {
		    print STDERR "   $source -> $filepath\n";
		}
		else {
		    print STDERR "   Error: fail $source -> $filepath\n";
		}
	    }
	}
    }

    print STDERR "done.\n\n";
}


# Descriptions: show file information
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_RER($optargs)
# Side Effects: none
# Return Value: none
sub _check
{
    my ($curproc, $args, $optargs) = @_;
    my $dst_dir  = $optargs->{ dst_dir };
    my $suffix   = '';

    my ($num_file, $num_dir) = _scan_dir( $dst_dir );

    print STDERR "spool directory = $dst_dir\n";

    $suffix = $num_file > 1 ? 's' : '';
    printf STDERR "%20d %s\n", $num_file, "file$suffix";

    $suffix = $num_dir > 1 ? 's' : '';
    printf STDERR "%20d %s\n", $num_dir, "subdir$suffix";
}


# Descriptions: return directory information
#    Arguments: STR($dir)
# Side Effects: none
# Return Value: ARRAY(NUM, NUM)
sub _scan_dir
{
    my ($dir) = @_;
    my $num_dir  = 0;
    my $num_file = 0;
    my $f = '';

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	while (defined($_ = $dh->read)) {
	    next if /^\./;

	    $f = File::Spec->catfile($dir, $_);
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

Usage: $name [--style=STR] [--srcdir=DIR] [-I DIR] COMMAND ML

commands:

convert     convert the spool dir at the same directory path.
check       check the current spool status.

options:

--style=    convertd to subdir style if 'subdir' specified.

-I DIR      prepend dir into include path

ML          ml_name. Example: elena, rudo\@nuinui.net

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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Spool first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
