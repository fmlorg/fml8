use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Log::ErrLogger',
    'VERSION_FROM' => 'ErrLogger.pm', # finds $VERSION
    'PREREQ_PM'	=> { Mail::Mailer => 0 },
);
