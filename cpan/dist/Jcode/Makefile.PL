#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.61 2000/11/15 05:45:25 dankogai Exp $
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

