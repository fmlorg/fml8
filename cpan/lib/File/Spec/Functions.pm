package File::Spec::Functions;

use File::Spec;
use strict;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	canonpath
	catdir
	catfile
	curdir
	rootdir
	updir
	no_upwards
	file_name_is_absolute
	path
	nativename
);

sub canonpath { File::Spec->canonpath(@_); }
sub catdir { File::Spec->catdir(@_); }
sub catfile { File::Spec->catfile(@_); }
sub curdir { File::Spec->curdir(@_); }
sub rootdir { File::Spec->rootdir(@_); }
sub updir { File::Spec->updir(@_); }
sub no_upwards { File::Spec->no_upwards(@_); }
sub file_name_is_absolute { File::Spec->file_name_is_absolute(@_); }
sub path { File::Spec->path(@_); }
sub nativename { File::Spec->nativename(@_); }

1;

