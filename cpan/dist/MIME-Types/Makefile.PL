use ExtUtils::MakeMaker;

require 5.006;

my $version  = '2.14';   # scanned by bin/collect_types !

WriteMakefile
  ( NAME      => 'MIME::Types'
  , VERSION   => $version
  , PREREQ_PM =>
    { Test::More     => 0.47
    , File::Spec     => 0
    , File::Basename => 0
    , List::Util     => 0
    }
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Definition of MIME types'
  , LICENSE   => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mimetypes/raw
DISTDIR         = ../public_html/mimetypes/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 1999,2001
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/mimetypes/

# for HTML
HTML_OUTPUT     = ../public_html/mimetypes/html
HTML_DOCROOT    = /mimetypes/html
HTML_PACKAGE    = ../public_html/mimetypes/htmlpkg

__POSTAMBLE
