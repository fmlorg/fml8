use ExtUtils::MakeMaker;
WriteMakefile( NAME	     => 'HTML::FromText',
	       VERSION_FROM => 'FromText.pm',
	       dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	     );
