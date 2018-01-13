use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::RandPasswd',
    'VERSION_FROM' => 'lib/Crypt/RandPasswd.pm', # finds $VERSION

    ($mm_ver <= 6.31
        ? ()
        : (LICENSE => 'perl')
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker  =>      'http://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-RandPasswd',
            repository  => {
                type => 'git',
                web  => 'https://github.com/neilbowers/Crypt-RandPasswd',
                url  => 'git://github.com/neilbowers/Crypt-RandPasswd.git',
            },
        },
    })),

);
