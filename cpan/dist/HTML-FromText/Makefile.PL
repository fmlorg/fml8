use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Convert Plain Text to HTML",
               EXE_FILES     => [ 'bin/text2html' ],
               MAN1PODS      => {
                                 'bin/text2html' => '$(INST_MAN1DIR)/text2html.1',
                                },
               NAME          => 'HTML::FromText',
               PREREQ_PM     => {
                                 'Scalar::Util'          =>  '1.12',
                                 'HTML::Entities'        =>  '1.26',
                                 'Text::Tabs'            => '98.1128',
                                 'Email::Find::addrspec' =>  '0.09',
                                 'Exporter::Lite'        =>  '0.01',
                                 'Test::More'            =>  '0.47',
                                },
               VERSION_FROM  => 'lib/HTML/FromText.pm',
              );
