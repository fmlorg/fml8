use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'File::Spec',
    'VERSION_FROM'  => 'lib/File/Spec.pm',
    'LIBS'          => [''],   # e.g., '-lm' 
    'DEFINE'        => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'           => '',     # e.g., '-I/usr/include/other' 
    'INSTALLDIRS'   => 'perl', # 'perl' makes it replace std modules
    'PL_FILES'      => {},
    'PREREQ_PM'     => {
			'File::Basename' => 0,
			'Cwd' => 0,
			'Test::More' => 0,
			'Test' => 0,
		       },
);
