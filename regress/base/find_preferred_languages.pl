#!/usr/bin/env perl
#
# $FML$
#

use FML::Process::Kernel;
use FML::Process::Debug;
my $curproc = new FML::Process::Debug;

$FML::Process::Kernel::debug = 1;

$pref_order = [ 'ja', 'en' ];
TOP();

$pref_order = [ 'en', 'ja' ];
TOP();

$pref_order = [ 'en' ];
TOP();

exit 0;


sub TOP
{
    for $mime_lang ('ja', 'en', '') {

	$acpt_lang_list = [ ];
	JUDGE();

	next;

	$acpt_lang_list = [ 'ja', 'en' ];
	JUDGE();

	$acpt_lang_list = [ 'en', 'ja' ];
	JUDGE();
    }
}


sub JUDGE
{
    &FML::Process::Kernel::__find_preferred_languages($curproc,
						      $pref_order,
						      $acpt_lang_list, 
						      $mime_lang);
}
