use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MIME::Lite::HTML',
    'VERSION_FROM'	=> 'HTML.pm', # finds $VERSION
    'PREREQ_PM'		=> {MIME::Lite=>1.0}, # e.g., Module::Name => 1.1
);
