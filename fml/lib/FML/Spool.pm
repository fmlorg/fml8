#-*- perl -*-
#
# Copyright (C) 2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Spool.pm,v 1.16 2003/02/01 08:51:41 fukachan Exp $
#

package FML::Spool;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

my $debug = 0;


=head1 NAME

FML::Spool -- utilities for small maintenance jobs on the spool directory

=head1 SYNOPSIS

=head1 DESCRIPTION

This class provides utilitiy functions for the spool directory.

=head1 METHODS

=head2 C<new($curproc)>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;

    # we use methods provided by article object.
    use FML::Article;
    my $article = new FML::Article $curproc;

    my $me = { 
	_curproc => $curproc,
	_article => $article,
    };

    return bless $me, $type;
}


# Descriptions: convert files from src_dir/ to dst_dir/
#    Arguments: OBJ($self) OBJ($curproc) HASH_RER($command_args)
# Side Effects: none
# Return Value: none
sub convert
{
    my ($self, $curproc, $command_args) = @_;
    my $wh       = $command_args->{ _output_channel } || \*STDOUT;
    my $article  = $self->{ _article };
    my $src_dir  = $command_args->{ _src_dir };
    my $dst_dir  = $command_args->{ _dst_dir };
    my $ml_name  = $command_args->{ ml_name };
    my $use_link = 0;

    print $wh "convert spool of $ml_name ML.\n\n";

    if ($src_dir eq $dst_dir) {
	$src_dir .= ".old";
	rename($dst_dir, $src_dir);
	$curproc->mkdir($dst_dir, "mode=private");
	$use_link = 1;
    }

    print $wh "converting $dst_dir from $src_dir\n";

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	my $source = '';
	my $dir;

	while (defined($dir = $dh->read)) {
	    next if $dir =~ /^\./o;

	    $source = File::Spec->catfile($src_dir, $dir);

	    if (-d $source) {
		print $wh "   $source is a subdir.\n";
	    }
	    elsif (-f $source) {
		my $subdirpath = $article->subdirpath($dir);
		my $filepath   = $article->filepath($dir);

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
		    print $wh "   $source -> $filepath\n";
		}
		else {
		    print $wh "   Error: fail $source -> $filepath\n";
		}
	    }
	}
    }

    print $wh "done.\n\n";
}


# Descriptions: show information on spool and articles.
#    Arguments: OBJ($self) OBJ($curproc) HASH_RER($command_args)
# Side Effects: none
# Return Value: none
sub status
{
    my ($self, $curproc, $command_args) = @_;
    my $wh      = $command_args->{ _output_channel } || \*STDOUT;
    my $dst_dir = $command_args->{ _dst_dir };
    my $suffix  = '';

    my ($num_file, $num_dir) = $self->_scan_dir( $dst_dir );

    print $wh "spool directory = $dst_dir\n";

    $suffix = $num_file > 1 ? 's' : '';
    printf $wh "%20d %s\n", $num_file, "file$suffix";

    $suffix = $num_dir > 1 ? 's' : '';
    printf $wh "%20d %s\n", $num_dir, "subdir$suffix";
}


# Descriptions: return directory information
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: ARRAY(NUM, NUM)
sub _scan_dir
{
    my ($self, $dir) = @_;
    my $num_dir  = 0;
    my $num_file = 0;

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my ($file, $entry);
	while (defined($entry = $dh->read)) {
	    next if $entry =~ /^\./o;

	    $file = File::Spec->catfile($dir, $entry);
	    if (-f $file) {
		$num_file++;
	    }
	    elsif (-d $file) {
		$num_dir++;
		my ($x_num_file, $x_num_dir) = $self->_scan_dir( $file );
		$num_file += $x_num_file;
		$num_dir  += $x_num_dir;
	    }
	}
    }

    return ($num_file, $num_dir);
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

Core functions of FML::Process::Spool is moved to FML::Spool at
2003/03.

FML::Spool first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
