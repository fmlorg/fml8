
use ExtUtils::MakeMaker;

WriteMakefile( 
	VERSION_FROM =>	'lib/Time/ParseDate.pm',
	NAME =>		'Time-modules',
	($] >= 5.005 
		?	
			(
				ABSTRACT	=> 'Parse and format time values',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/Time-modules',
					},
				},
			) 
		: ()
	),
	dist => { 	COMPRESS=>"gzip", SUFFIX=>"gz" },
);
