use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'AsciiDB::TagFile',
    VERSION_FROM => 'TagFile.pm',
    'dist' => {
	TARFLAGS => 'cvf', 
	COMPRESS => 'gzip', 
	SUFFIX => 'gz',
    },
);
