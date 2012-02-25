use Test::More qw[no_plan];

use_ok( 'HTML::FromText' );

my $html = text2html( <<__TEXT__, paras => 1, bullets => 1, bold => 1 );
* An article on *how* to do test...
---

*With C/C++*
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'mixing bullets should not work' );
<ul class="hft-bullets">
<li> An article on <strong class="hft-bold">how</strong> to do test...
---</li>
</ul>

<p class="hft-paras"><strong class="hft-bold">With C/C++</strong></p>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, urls => 1 );
http://example.com/i-ndex.html#test
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'url with hash' );
<p class="hft-paras"><a href="http://example.com/i-ndex.html#test" class="hft-urls">http://example.com/i-ndex.html#test</a></p>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, underline => 1 );
mod_perl/mod_ssl

_foo_

_foo_.
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'complex underlines' );
<p class="hft-paras">mod_perl/mod_ssl</p>

<p class="hft-paras"><span class="hft-underline" style="text-decoration: underline">foo</span></p>

<p class="hft-paras"><span class="hft-underline" style="text-decoration: underline">foo</span>.</p>
__HTML__

$html = text2html( <<__TEXT__, paras => 1, bold => 1 );
foo*foo*foo

*foo*

*foo*.
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'complex bolds' );
<p class="hft-paras">foo*foo*foo</p>

<p class="hft-paras"><strong class="hft-bold">foo</strong></p>

<p class="hft-paras"><strong class="hft-bold">foo</strong>.</p>
__HTML__


$html = text2html( <<__TEXT__, paras => 1, bullets => 1 );
* Fast, powerful and extensible template processing system. 
 *         Powerful presentation language supports all standard templating directives, e.g. variable substitution, includes, conditionals,
          loops. 
   *       Many additional features such as output filtering, exception handling, macro definition, support for plugin objects, definition
          of template metadata, embedded Perl code (only enabled by EVAL_PERL option), definition of template blocks, a 'switch'
          statement, and more. 
   *       Full support for complex Perl data types such as hashes, lists, objects and sub-routine references. 
  *        Clear separation of concerns between user interface (templates), application code (Perl objects/sub-routines) and data
          (Perl data). 
   *       Programmer-centric back end, allowing application logic and data structures to be built in Perl. 
   *       Designer-centric front end, hiding underlying complexity behind simple variable access. 
   *       Templates are compiled to Perl code for maximum runtime efficiency and performance. Compiled templates are cached
          and can be written to disk in "compiled form" (e.g. Perl code) to achieve cache persistance. 
    *      Well suited to online dynamic web content generation (e.g. Apache/mod_perl). 
    *      Also has excellent support for offline batch processing for generating static pages (e.g. HTML, POD, LaTeX, PostScript,
          plain text) from source templates. 
     *     Comprehensive documentation including tutorial and reference manuals. 
     *     Fully Open Source and Free 
__TEXT__
cmp_ok( $html, 'eq', <<__HTML__, 'complex bullets' );
<ul class="hft-bullets">
<li> Fast, powerful and extensible template processing system. </li>
 <ul class="hft-bullets">
 <li>         Powerful presentation language supports all standard templating directives, e.g. variable substitution, includes, conditionals,
          loops. </li>
   <ul class="hft-bullets">
   <li>       Many additional features such as output filtering, exception handling, macro definition, support for plugin objects, definition
          of template metadata, embedded Perl code (only enabled by EVAL_PERL option), definition of template blocks, a 'switch'
          statement, and more. </li>
   <li>       Full support for complex Perl data types such as hashes, lists, objects and sub-routine references. </li>
   </ul>
  <li>        Clear separation of concerns between user interface (templates), application code (Perl objects/sub-routines) and data
          (Perl data). </li>
   <ul class="hft-bullets">
   <li>       Programmer-centric back end, allowing application logic and data structures to be built in Perl. </li>
   <li>       Designer-centric front end, hiding underlying complexity behind simple variable access. </li>
   <li>       Templates are compiled to Perl code for maximum runtime efficiency and performance. Compiled templates are cached
          and can be written to disk in &quot;compiled form&quot; (e.g. Perl code) to achieve cache persistance. </li>
    <ul class="hft-bullets">
    <li>      Well suited to online dynamic web content generation (e.g. Apache/mod_perl). </li>
    <li>      Also has excellent support for offline batch processing for generating static pages (e.g. HTML, POD, LaTeX, PostScript,
          plain text) from source templates. </li>
     <ul class="hft-bullets">
     <li>     Comprehensive documentation including tutorial and reference manuals. </li>
     <li>     Fully Open Source and Free </li>
</ul>
</ul>
</ul>
</ul>
</ul>
__HTML__
