require 5.008001;

use ExtUtils::MakeMaker;

WriteMakefile
 ( DISTNAME  => 'MailTools'
 , VERSION   => '2.19'
 , AUTHOR    => 'Mark Overmeer <perl@overmeer.net>'
 , ABSTRACT  => 'Various ancient e-mail related modules'
 , LICENSE   => 'perl'

 , PREREQ_PM =>
   { Net::SMTP   => 1.03
   , Net::Domain => 1.05
   , IO::Handle  => 0.00
   , Test::More  => 0.00
   , Date::Format => 0
   , Date::Parse  => 0

   # next deps missing on purpose, to avoid installing a lot which
   # is rarely used.
   # Authen::SASL
   # Net::SMTP::SSL
   }
);

sub MY::postamble {

  return '' unless $] >= 5.00503;

<<'ESQ';

all:: ppd
dist: ppd

# for OODoc's oodist, DIST
RAWDIR		= ../public_html/mailtools/raw
DISTDIR		= ../public_html/mailtools/source
LICENSE		= artistic

# for OODoc's oodist, POD
FIRST_YEAR	= 1995
EMAIL		= perl@overmeer.net
WEBSITE		= http://perl.overmeer.net/

ESQ
}

