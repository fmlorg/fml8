#!/usr/bin/env perl
#-*- perl -*-
#
# $FML$
#

use strict;
use Carp;

for my $f (@ARGV) {
    edit(parse($f));
}

exit 0;

sub parse
{
    my ($f) = @_;

    use File::Spec;
    my $ja = File::Spec->catfile("ja", $f);
    my $en = File::Spec->catfile("en", $f);
    return(($ja, $en));
}

sub edit
{
    my (@f) = @_;
    my $editor = $ENV{'FML_EMUL_EDITOR'} || $ENV{'EDITOR'} || "vi";
    chdir "../../fml/doc" || exit 1;
    print STDERR join(" ", $editor, @f), "\n";

    for my $f (@f) {
	if (! -f $f || -z $f) {
	    use FileHandle;
	    my $wh = new FileHandle "> $f";
	    if (defined $wh) {
		_print_template($wh);
		$wh->close();
	    }
	}
    }

    system $editor, @f;
}

sub _print_template
{
    my ($wh) = @_;

    print $wh <<_EOF_;
<!--
 \$FML\$
-->

<qandaset>


<qandaentry>

<question>
<para>

</para>
</question>

<answer>
<para>

<screen>

</screen>

</para>
</answer>

</qandaentry>


</qandaset>

_EOF_
}
