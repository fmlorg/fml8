
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 100.010301,
	'NAME' => 'Time-modules',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Parse and format time values',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);
