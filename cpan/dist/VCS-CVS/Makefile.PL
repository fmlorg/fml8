use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (rpsavage@ozemail.com.au)',
		'ABSTRACT' => "Interface to GNU's CVS",
    ) : (),
'clean'				=>
	{
	'FILES'			=> 'blib/* Makefile VCS-CVS-*'
	},
'dist'				=>
	{
	'COMPRESS'		=> 'gzip',
	'SUFFIX'		=> 'gz'
	},
'DISTNAME'			=> 'VCS-CVS',
'NAME'				=> 'VCS::CVS',
'PM'				=>
	{
	'CVS.pm' 		=> '$(INST_LIBDIR)/CVS.pm',
	},
'PREREQ_PM'			=> {},
'VERSION_FROM'		=> 'CVS.pm'
);
