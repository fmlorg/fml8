use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::Template',
    'VERSION_FROM' => 'Template.pm', # finds $VERSION
    'PREREQ_PM' => {Carp => 0, 'File::Spec' => 0.82},
);
