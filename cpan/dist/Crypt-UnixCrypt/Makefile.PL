use 5.004;  # i.e. not tested under earlier versions
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Crypt::UnixCrypt',
    'VERSION_FROM'  => 'UnixCrypt.pm',
    'dist'          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
