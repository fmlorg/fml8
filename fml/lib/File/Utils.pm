#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#

package File::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $ErrorString);
use Carp;


require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(mkdirhier touch search_program copy);

=head1 NAME

File::Utils - utilities to handle files or directories

=head1 SYNOPSIS

   use File::Utils qw(mkdiehier);
   mkdirhier($dir, $mode);

=head1 DESCRIPTION

this module provides utility functions to handle files, 
for example, 
C<mkdirhier>,
C<touch>,
C<search_program>
and
C<copy>.

=head1 METHODS

=cut

# Descriptions: return the error
#    Arguments: none
# Side Effects: none
# Return Value: error message
sub error       { return $ErrorString;}

# Descriptions: remove the error message buffer
#    Arguments: none
# Side Effects: undef $ErrorString buffer
# Return Value: none
sub error_clear { undef $ErrorString;}


=head2 C<mkdiehier($dir, $mode)>

make a directory C<$dir> by the mode C<$mode> recursively.

=cut


# Descriptions: "mkdir -p" or "mkdirhier"
#    Arguments: directory [file_mode]
# Side Effects: set $ErrorString
# Return Value: succeeded to create directory or not
sub mkdirhier
{
    my ($dir, $mode) = @_;

    error_clear();

    # XXX $mode (e.g. 0755) should be a numeric not a string
    eval qq{ 
	use File::Path;
	mkpath(\$dir, 0, $mode);
    };
    $ErrorString = $@;
    return ($@ ? undef : 1);
}


=head2 C<touch($file, $mode)>

create a file (which size is 0) if the file not exists.

=cut

# Descriptions: touch: create file if file not exists
#    Arguments: file file_mode
# Side Effects: none
# Return Value: 1 if succeed, 0 if not
sub touch
{
    my ($file, $mode) = @_;
    my ($ok) = 0;

    error_clear();

    if ( -f $file) {
	return 1;
    }
    else {
	my $fh = new IO::File $file, "a";

	if (defined $fh) {
	    $fh->autoflush(1);
	    close($fh);
	}

	$ok++        if -f $file;
	return 0 unless -f $file;
    };

    if (defined $mode) {
	chmod $mode, $file && $ok++;
    }

    return $ok;
}


=head2 C<search_program($file [, $path_list ])>

search C<$file>. 
C<$path_list> is the hash array.
It searches it among C<$path_list> if specified.

The default search path list is 

  ('/usr/bin', '/bin', '/sbin', ' /usr/local/bin', 
   '/usr/gnu/bin', '/usr/pkg/bin')

=cut

# Descriptions: file $file executable
#    Arguments: file [path_list]
#               The "path_list" is an ARRAY_REFERENCE. 
#               For example, 
#               search_program('md5'); 
#               search_program('md5', [ '/bin', '/sbin' ]); 
# Side Effects: none
# Return Value: pathname if found, undef if not
sub search_program
{
    my ($file, $path_list) = @_;

    my $default_path_list = [
			     '/usr/bin', 
			     '/bin', 
			     '/sbin', 
			     '/usr/local/bin', 
			     '/usr/gnu/bin', 
			     '/usr/pkg/bin'
			     ];

    $path_list ||= $default_path_list;

    use File::Spec;
    my $path;
    for $path (@$path_list) {
	my $prog = File::Spec->catfile($path, $file);
	if (-x $prog) {
	    return $prog;
	}
    }

    return wantarray ? () : undef;
}


=head2 C<copy($src, $dst)>

copy C<$src> to C<$dst> in atomic way.
This routine uses C<IO::File::Atomic> module.

=cut

# wrappers for delegation :-)
sub copy
{
    my ($src, $dst) = @_;
    my $pkg = 'IO::File::Atomic';

    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	$pkg->new->copy($src, $dst);
    }
    else {
	undef;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::Utils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
