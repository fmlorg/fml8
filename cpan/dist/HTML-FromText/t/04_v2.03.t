use Test::More 'no_plan';

use_ok 'HTML::FromText';

$html = text2html( <<__TEXT__, paras => 1, blockcode => 1 );
  Foo Bar
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockcode should use pre' );
<blockquote class="hft-blockcode"><pre>Foo Bar</pre></blockquote>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, blockparas => 1 );
  Foo Bar
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockparas should use p' );
<blockquote class="hft-blockparas"><p>Foo Bar</p></blockquote>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, blockquotes => 1 );
  Foo Bar
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'blockquotes should use div' );
<blockquote class="hft-blockquotes"><div>Foo Bar<br />
</div></blockquote>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, tables => 1 );
Perl Command Line                                 Casey West
Introduction to CPAN Testing                      Adam J. Foxson
Parsing JavaScript                                David Hand
Test Better with Test::More                       Casey West
Creating a Template Toolkit Plugin                Chris Winters
GD::SIRDS                                         David Hand
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'table should work' );
<table class="hft-tables">
  <tr><td>Perl Command Line</td><td>Casey West</td></tr>
  <tr><td>Introduction to CPAN Testing</td><td>Adam J. Foxson</td></tr>
  <tr><td>Parsing JavaScript</td><td>David Hand</td></tr>
  <tr><td>Test Better with Test::More</td><td>Casey West</td></tr>
  <tr><td>Creating a Template Toolkit Plugin</td><td>Chris Winters</td></tr>
  <tr><td>GD::SIRDS</td><td>David Hand</td></tr>
</table>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, tables => 1 );
*01.08.2003*  19:00  Robot Club          http://pgh.pm.org/m/200301.html
*02.12.2003*  19:00  Lightning Talks     http://pgh.pm.org/m/200302.html
*03.12.2003*  19:00  Social Gathering    http://pgh.pm.org/m/200303.html
*04.09.2003*  19:00  Technical Meeting   http://pgh.pm.org/m/200304.html
*05.14.2003*  19:00  Social Gathering    http://pgh.pm.org/m/200305.html
*06.14.2003*  11:00  /burgh?/ Meetup     http://pgh.pm.org/m/200306.html
*07.09.2003*  19:00  Social Meeting      http://pgh.pm.org/m/200307.html
*08.13.2003*  19:00  Technical Meeting   http://pgh.pm.org/m/200308.html
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'table should work' );
<table class="hft-tables">
  <tr><td>*01.08.2003*</td><td>19:00</td><td>Robot Club</td><td>http://pgh.pm.org/m/200301.html</td></tr>
  <tr><td>*02.12.2003*</td><td>19:00</td><td>Lightning Talks</td><td>http://pgh.pm.org/m/200302.html</td></tr>
  <tr><td>*03.12.2003*</td><td>19:00</td><td>Social Gathering</td><td>http://pgh.pm.org/m/200303.html</td></tr>
  <tr><td>*04.09.2003*</td><td>19:00</td><td>Technical Meeting</td><td>http://pgh.pm.org/m/200304.html</td></tr>
  <tr><td>*05.14.2003*</td><td>19:00</td><td>Social Gathering</td><td>http://pgh.pm.org/m/200305.html</td></tr>
  <tr><td>*06.14.2003*</td><td>11:00</td><td>/burgh?/ Meetup</td><td>http://pgh.pm.org/m/200306.html</td></tr>
  <tr><td>*07.09.2003*</td><td>19:00</td><td>Social Meeting</td><td>http://pgh.pm.org/m/200307.html</td></tr>
  <tr><td>*08.13.2003*</td><td>19:00</td><td>Technical Meeting</td><td>http://pgh.pm.org/m/200308.html</td></tr>
</table>
__HTML__

