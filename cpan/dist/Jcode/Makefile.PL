#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.77 2002/01/14 11:06:55 dankogai Exp $
#

use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME         => 'Jcode',
     VERSION_FROM => 'Jcode.pm',
     PREREQ_PM    => {
	 'MIME::Base64'     => "2.1",
     },
     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Jcode.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Kogai <dankogai@dan.co.jp>') : ()
      ),
     );	       

