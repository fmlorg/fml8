require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'MIME::Base64::Perl',
    VERSION_FROM => 'lib/MIME/Base64/Perl.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
