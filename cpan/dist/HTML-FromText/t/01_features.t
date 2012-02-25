BEGIN {
    use Test::More qw[no_plan];
    use_ok 'HTML::FromText';
}

use strict;
use warnings;

my $t2h = HTML::FromText->new;
isa_ok( $t2h, 'HTML::FromText', 'default' );
my $html = $t2h->parse( '<>' );
cmp_ok( $html, 'eq', '&lt;&gt;', 'metachars encoded <> correctly' );


$t2h = HTML::FromText->new({underline => 1});
$html = $t2h->parse( '_underline_' );
cmp_ok( $html, 'eq', '<span class="hft-underline" style="text-decoration: underline">underline</span>', 'underline did' );

$t2h = HTML::FromText->new({underline => 1});
$html = $t2h->parse( "_should\nnot_" );
cmp_ok( $html, 'eq', "_should\nnot_", 'underline should not across lines' );


$t2h = HTML::FromText->new({bold => 1});
$html = $t2h->parse( '*bold*' );
cmp_ok( $html, 'eq', '<strong class="hft-bold">bold</strong>', 'bold did' );


$t2h = HTML::FromText->new({urls => 1});
$html = $t2h->parse( 'http://example.com' );
cmp_ok( $html, 'eq', '<a href="http://example.com" class="hft-urls">http://example.com</a>', 'urls did' );


$t2h = HTML::FromText->new({urls => 1});
$html = $t2h->parse( 'http://example.com/?foo=bar&baz=quux' );
cmp_ok( $html, 'eq', '<a href="http://example.com/?foo=bar&amp;baz=quux" class="hft-urls">http://example.com/?foo=bar&amp;baz=quux</a>', 'urls and metachars did' );


$t2h = HTML::FromText->new({email => 1});
$html = $t2h->parse( 'casey@geeknest.com' );
cmp_ok( $html, 'eq', '<a href="mailto:casey@geeknest.com" class="hft-email">casey@geeknest.com</a>', 'email did' );


$t2h = HTML::FromText->new({pre => 1});
$html = $t2h->parse( 'pre' );
cmp_ok( $html, 'eq', '<pre class="hft-pre">pre</pre>', 'pre did' );


$t2h = HTML::FromText->new({lines => 1});
$html = $t2h->parse( "one\ntwo" );
cmp_ok( $html, 'eq', qq[<div class="hft-lines">one<br />\ntwo<br /></div>], 'lines did' );


$t2h = HTML::FromText->new({lines => 1,spaces => 1});
$html = $t2h->parse( "one\n two" );
cmp_ok( $html, 'eq', qq[<div class="hft-lines">one<br />\n&nbsp;two<br /></div>], 'lines and spaces did' );

$t2h = HTML::FromText->new({paras => 1});
$html = $t2h->parse( <<__TEXT__ );
One
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'one paragraph' );
<p class="hft-paras">One</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1});
$html = $t2h->parse( <<__TEXT__ );
One

Two
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'two paragraphs' );
<p class="hft-paras">One</p>

<p class="hft-paras">Two</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1, bullets => 1});
$html = $t2h->parse( <<__TEXT__ );
  * One
  * Two
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'single bullet list' );
  <ul class="hft-bullets">
  <li> One</li>
  <li> Two</li>
</ul>
__HTML__

$t2h = HTML::FromText->new({paras => 1, bullets => 1});
$html = $t2h->parse( <<__TEXT__ );
- One
  - Half
- Two
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'nested bullet list' );
<ul class="hft-bullets">
<li> One</li>
  <ul class="hft-bullets">
  <li> Half</li>
  </ul>
<li> Two</li>
</ul>
__HTML__

$t2h = HTML::FromText->new({paras => 1, bullets => 1, bold => 1});
$html = $t2h->parse( <<__TEXT__ );
* One
  * Half
  * Whole
    * Shabang
      Dude
* Two

*Normal* Text
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'nested bullets and normal paragraph' );
<ul class="hft-bullets">
<li> One</li>
  <ul class="hft-bullets">
  <li> Half</li>
  <li> Whole</li>
    <ul class="hft-bullets">
    <li> Shabang
      Dude</li>
    </ul>
  </ul>
<li> Two</li>
</ul>

<p class="hft-paras"><strong class="hft-bold">Normal</strong> Text</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1, numbers => 1});
$html = $t2h->parse( <<__TEXT__ );
1 One
  1 Half
  2 Whole
    1 Shabang
      Dude
2 Two

Normal Text
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'nested numbers and normal paragraph' );
<ol class="hft-numbers">
<li> One</li>
  <ol class="hft-numbers">
  <li> Half</li>
  <li> Whole</li>
    <ol class="hft-numbers">
    <li> Shabang
      Dude</li>
    </ol>
  </ol>
<li> Two</li>
</ol>

<p class="hft-paras">Normal Text</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1, headings => 1});
$html = $t2h->parse( <<__TEXT__ );
1. One

Normal Text

1.1. Sub section

2. Second Top

__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'headings' );
<h1 class="hft-headings">1. One</h1>

<p class="hft-paras">Normal Text</p>

<h2 class="hft-headings">1.1. Sub section</h2>

<h1 class="hft-headings">2. Second Top</h1>
__HTML__

$t2h = HTML::FromText->new({paras => 1, title => 1});
$html = $t2h->parse( <<__TEXT__ );
Title

Normal Text
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'title' );
<h1 class="hft-title">Title</h1>

<p class="hft-paras">Normal Text</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1, blockparas => 1});
$html = $t2h->parse( <<__TEXT__ );
  Test
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockparas' );
<blockquote class="hft-blockparas"><p>Test</p></blockquote>
__HTML__

$t2h = HTML::FromText->new({paras => 1, blockquotes => 1});
$html = $t2h->parse( <<__TEXT__ );
  Test
  This
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockquotes' );
<blockquote class="hft-blockquotes"><div>Test<br />
This<br />
</div></blockquote>
__HTML__

$t2h = HTML::FromText->new({paras => 1, blockcode => 1});
$html = $t2h->parse( <<__TEXT__ );
  Test
  This Please

__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockcode' );
<blockquote class="hft-blockcode"><pre>Test
This Please</pre></blockquote>
__HTML__

$t2h = HTML::FromText->new({paras => 1, tables => 1});
$html = $t2h->parse( <<__TEXT__ );
Casey West     Daddy
Chastity West  Mommy
Evelina West   Baby
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'tables' );
<table class="hft-tables">
  <tr><td>Casey West</td><td>Daddy</td></tr>
  <tr><td>Chastity West</td><td>Mommy</td></tr>
  <tr><td>Evelina West</td><td>Baby</td></tr>
</table>
__HTML__

$t2h = HTML::FromText->new({paras => 1, tables => 1});
$html = $t2h->parse( <<__TEXT__ );
    Chastity West  Mommy
    Casey West     Daddy
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'indented tables' );
<table class="hft-tables">
  <tr><td>Chastity West</td><td>Mommy</td></tr>
  <tr><td>Casey West</td><td>Daddy</td></tr>
</table>
__HTML__

$t2h = HTML::FromText->new({paras => 1, tables => 1});
$html = $t2h->parse( <<__TEXT__ );
    Chastity West Mommy
    Casey West    Daddy
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'should not be table' );
<p class="hft-paras">    Chastity West Mommy
    Casey West    Daddy</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1, tables => 1});
$html = $t2h->parse( <<__TEXT__ );
    Casey West     Daddy    Tall
    Chastity West  Mommy   Short

Normal Text.
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'indented tables with normal para' );
<table class="hft-tables">
  <tr><td>Casey West</td><td>Daddy</td><td>Tall</td></tr>
  <tr><td>Chastity West</td><td>Mommy</td><td>Short</td></tr>
</table>

<p class="hft-paras">Normal Text.</p>
__HTML__

$t2h = HTML::FromText->new({paras => 1, tables => 1});
$html = $t2h->parse( <<__TEXT__ );
http://www.pm.org           Perl Mongers
http://perl.com             O'Reilly Perl Center
http://lists.perl.org       List of Mailing Lists
http://use.perl.org         Perl News and Community Journals
http://perl.apache.org      mod_perl
http://theperlreview.com    The Perl Review
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'indented tables with normal para' );
<table class="hft-tables">
  <tr><td>http://www.pm.org</td><td>Perl Mongers</td></tr>
  <tr><td>http://perl.com</td><td>O'Reilly Perl Center</td></tr>
  <tr><td>http://lists.perl.org</td><td>List of Mailing Lists</td></tr>
  <tr><td>http://use.perl.org</td><td>Perl News and Community Journals</td></tr>
  <tr><td>http://perl.apache.org</td><td>mod_perl</td></tr>
  <tr><td>http://theperlreview.com</td><td>The Perl Review</td></tr>
</table>
__HTML__

