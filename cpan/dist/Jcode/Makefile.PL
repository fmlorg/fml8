#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.70 2001/05/15 19:35:59 dankogai Exp $
#

use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME         => 'Jcode',
     VERSION_FROM => 'Jcode.pm',
     PREREQ_PM    => {
	 'MIME::Base64'     => "2.1",
     }
     );	       

