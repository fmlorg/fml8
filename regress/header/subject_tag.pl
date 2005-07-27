#!/usr/bin/env perl -w
#
# $FML: subject_tag.pl,v 1.3 2001/06/17 09:00:31 fukachan Exp $
#

use lib qw(../../fml/lib);
use FML::Header::Subject;

my $format      = "%8s %s\n";

$tags = {
    '[ ]' => [  '[', ' ', ']' ],
    '[:]' => [  '[', ':', ']' ],
    '[,]' => [  '[', ',', ']' ],
    '[]'  => [  '[', '' , ']' ],
    '[I]' => [  '[', 'I', ']' ],

    '( )' => [  '(', ' ', ')' ],
    '(:)' => [  '(', ':', ')' ],
    '(,)' => [  '(', ',', ')' ],
    '()'  => [  '(', '',  ')' ],
    '(I)' => [  '(', 'I', ')' ],
};

my $i = 0;
while ( ($k, $v) = each %$tags) {
    $i++;
    print "${i}. ${k}\n";
    my ($left, $sep, $right) = @$v;

    if ($sep) {
	if ($sep eq 'I') {
	    $subject_tag = $left. '%05d'. $right;
	    $x           = sprintf($subject_tag, 100). " uja";
	}
	else {
	    $subject_tag = $left. '%s'. $sep .'%05d'. $right;
	    $x           = sprintf($subject_tag, 'elena', 100). " uja";
	}
    }
    else {
	$subject_tag = $left. '%s'. $right;
	$x           = sprintf($subject_tag, 'elena', 100). " uja";
    }


    {
	printf $format,  "tag:", $subject_tag;
	$re = FML::Header::Subject::_regexp_compile( $subject_tag );
	printf $format,  "regexp:", $re;

	printf $format,  "in:", $x;
	$x = FML::Header::Subject::_delete_subject_tag( $x , $subject_tag );
	printf $format,  "out:", $x;
    }
    print "\n";
}

exit 0;
