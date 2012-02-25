use Test::More;

my $script = 'blib/script/text2html';

plan skip_all => "$script doesn't exist"
  unless -e $script;

plan 'no_plan';

open T2H, "perl -Iblib/lib $script --paras t/files/paras.txt |" or die $!;
undef $/;
my $html = <T2H>;
close T2H;

cmp_ok( $html, 'eq', <<__HTML__, 'output from text2html correct' );
<p class="hft-paras">Hello</p>

<p class="hft-paras">Test</p>
__HTML__

use_ok 'HTML::FromText';

$html = text2html( <<__TEXT__, paras => 1, blockcode => 1 );
  Foo Bar
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockcode should preserve spaces' );
<blockquote class="hft-blockcode"><pre>Foo Bar</pre></blockquote>
__HTML__

