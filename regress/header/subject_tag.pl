#!/usr/local/bin/perl -w
#
# $Id$
#

use lib qw(../../fml/lib);
use FML::Header::Subject;

my $format      = "%8s %s\n";
my $subject_tag = '[%s %05d]';
my $x           = sprintf($subject_tag, 'elena', 100). " uja";

{
    printf $format,  "tag:", $subject_tag;
    $re = FML::Header::Subject::_regexp_compile( $subject_tag );
    printf $format,  "regexp:", $re;

    printf $format,  "in:", $x;
    $x = FML::Header::Subject::_delete_subject_tag( $x , $subject_tag );
    printf $format,  "out:", $x;
}

exit 0;
