use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'           => 'Class::ParmList',
    'VERSION_FROM'   => 'lib/Class/ParmList.pm',
    'PREREQ_PM'      => {},
    'linkext'        => { LINKTYPE=>'' },    # no link needed
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
    'ZIP'            => '/usr/bin/zip','ZIPFLAGS'=>'-rl'}
);
