use Test::More qw[no_plan];

use_ok 'HTML::FromText';

my $html = text2html( <<'__TEXT__', paras => 1, blockcode => 1 );
  my $who = "World";

  print "Hello, $who!\n";
__TEXT__
cmp_ok( $html, 'eq', <<'__HTML__', 'blockcode consolidated' );
<blockquote class="hft-blockcode"><pre>my $who = &quot;World&quot;;

print &quot;Hello, $who!\n&quot;;</pre></blockquote>
__HTML__

$html = text2html( <<'__TEXT__', paras => 1, blockparas => 1 );
  Hello

  World
__TEXT__
cmp_ok( $html, 'eq', <<'__HTML__', 'blockparas consolidated' );
<blockquote class="hft-blockparas"><p>Hello</p>

<p>World</p></blockquote>
__HTML__
