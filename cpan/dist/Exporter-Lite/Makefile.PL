#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME            => 'Exporter::Lite',
    VERSION_FROM    => "lib/Exporter/Lite.pm",
    PREREQ_PM       => {
        'strict'   => 0,
        'warnings' => 0,
        'Carp'     => 0,
    },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test::More' => '0.34',
          })
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Exporter-Lite',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilb/Exporter-Lite',
                    url  => 'https://github.com/neilb/Exporter-Lite.git',
                },
            },
          })
    ),

);

