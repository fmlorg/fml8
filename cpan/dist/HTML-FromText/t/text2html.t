# HTML::FromText test suite (-*- cperl -*-)

use strict;
use HTML::FromText;
$^W = 1;

# Each test is represented by three data chunks, separated by a line
# containing only a form-feed character (0x0c).  The first chunk is
# the options to pass to text2html(), the second is the input, and the 
# third the expected output.

$/ = "\n\f\n";
my @tests = ();
while (<DATA>) {
  chomp;
  push @tests, $_;
}
my $n = @tests / 3;
print "1..$n\n";
foreach my $i (1..$n) {
  my $j = 3 * ($i - 1);
  my $input = $tests[$j + 1];
  my $expected = $tests[$j + 2];
  my @options = eval $tests[$j];
  my $output = text2html($input, @options);
  unless ($output eq $expected) {
    print STDERR
      "\n",'--expected','-'x60,
      "\n",$expected,
      "\n",'--but-found','-'x59,
      "\n",$output,
      "\n",'-'x70,
      "\n";
    print "not ";
  }
  print "ok $i\n";
}

__DATA__

()

<B>&lt;&amp;&gt;</B>

&lt;B&gt;&amp;lt;&amp;amp;&amp;gt;&lt;/B&gt;


(metachars => 0)

<B>&lt;&amp;&gt;</B>

<B>&lt;&amp;&gt;</B>


(email => 1)

real@email.address, real2@email.addresss.
fake@:email.address, another@[fake].address
mailto:me@foo.bar.com
<tricky@subdomain.domain>
#$%=strange!?@characters.=+=in=+=_.address

<TT><A HREF="mailto:real@email.address">real@email.address</A></TT>, <TT><A HREF="mailto:real2@email.addresss">real2@email.addresss</A></TT>.
fake@:email.address, another@[fake].address
<TT><A HREF="mailto:me@foo.bar.com">mailto:me@foo.bar.com</A></TT>
&lt;<TT><A HREF="mailto:tricky@subdomain.domain">tricky@subdomain.domain</A></TT>&gt;
<TT><A HREF="mailto:#$%=strange!?@characters.=+=in=+=_.address">#$%=strange!?@characters.=+=in=+=_.address</A></TT>


(metachars => 1, email => 1)

An email address with an & in it: fred&barney@stonehenge.com.

An email address with an &amp; in it: <TT><A HREF="mailto:fred&amp;barney@stonehenge.com">fred&amp;barney@stonehenge.com</A></TT>.


(metachars => 0, email => 1)

An email address with an & in it: fred&barney@stonehenge.com.  Generates
non-legal HTML, but that was what was asked for!

An email address with an & in it: <TT><A HREF="mailto:fred&barney@stonehenge.com">fred&barney@stonehenge.com</A></TT>.  Generates
non-legal HTML, but that was what was asked for!


(urls => 1)

See http://foo.bar.com.
What about http://foo.com/bar/baz?
http://foo.com/bar/baz?quux.
ftp://spong.gov/a/b/c/d.e/f.g/h/ should have trailing /
...gopher://x.y.z/foo...
mailto:mail@address.com is translated
but mail@address.com on its own is not

See <TT><A HREF="http://foo.bar.com">http://foo.bar.com</A></TT>.
What about <TT><A HREF="http://foo.com/bar/baz">http://foo.com/bar/baz</A></TT>?
<TT><A HREF="http://foo.com/bar/baz?quux">http://foo.com/bar/baz?quux</A></TT>.
<TT><A HREF="ftp://spong.gov/a/b/c/d.e/f.g/h/">ftp://spong.gov/a/b/c/d.e/f.g/h/</A></TT> should have trailing /
...<TT><A HREF="gopher://x.y.z/foo">gopher://x.y.z/foo</A></TT>...
<TT><A HREF="mailto:mail@address.com">mailto:mail@address.com</A></TT> is translated
but mail@address.com on its own is not


(bold => 1, underline => 1)

*Words* in *bold* _underline_ and *bold* again, but 5*4, 3_1 unaffected;
_underline_ *more* *bold*
_more_ _underline_
Now *several words in bold* and _several in underline_ but
equations like 5*x + 5*y or zeta_i + phi_i are not marked up.
Here's a *phrase in bold
crossing a newline* and an _underlined phrase
crossing a newline_
Single letter words: *a* _b_ *c* _d_

<B>Words</B> in <B>bold</B> <U>underline</U> and <B>bold</B> again, but 5*4, 3_1 unaffected;
<U>underline</U> <B>more</B> <B>bold</B>
<U>more</U> <U>underline</U>
Now <B>several words in bold</B> and <U>several in underline</U> but
equations like 5*x + 5*y or zeta_i + phi_i are not marked up.
Here's a <B>phrase in bold
crossing a newline</B> and an <U>underlined phrase
crossing a newline</U>
Single letter words: <B>a</B> <U>b</U> <B>c</B> <U>d</U>


(paras => 1, bold => 1, underline => 1)

*Bold* works OK in a paragraph context
and so does _underline_

_Underline works OK_ in a paragraph context
and *so does bold*

<P><B>Bold</B> works OK in a paragraph context
and so does <U>underline</U></P>
<P><U>Underline works OK</U> in a paragraph context
and <B>so does bold</B></P>


(lines => 1)

line 1
line 2
line 3
line 4

line 1<BR>
line 2<BR>
line 3<BR>
line 4


(lines => 1, spaces => 1)

line 1
 line  2
  line   3
   line    4
	tab	1
		tab  	2

line&nbsp;1<BR>
&nbsp;line&nbsp;&nbsp;2<BR>
&nbsp;&nbsp;line&nbsp;&nbsp;&nbsp;3<BR>
&nbsp;&nbsp;&nbsp;line&nbsp;&nbsp;&nbsp;&nbsp;4<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tab&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tab&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2


(paras => 1)

paragraph
one
   
paragraph
two

a
long
paragraph
three

<P>paragraph
one</P>
<P>paragraph
two</P>
<P>a
long
paragraph
three</P>


(paras => 1, title => 1)

this
is the
title

and this
the text

<H1>this
is the
title</H1>
<P>and this
the text</P>


(paras => 1, headings => 1)

1. Chapter one

2. Chapter two

2.1 Section two point one

2.1.1 Subsection two point one point one

2.1.1.3 Subsubsection two point one point one point three

2.1.1.3.7 Heading level 5

2.1.1.3.7.1 Heading level 6 (a long heading across
two lines)

paragraph text

2.1.1.3.7.1.2 There are no more than 6 heading levels.

paragraph text

3. Chapter three

<H1>1. Chapter one</H1>
<H1>2. Chapter two</H1>
<H2>2.1 Section two point one</H2>
<H3>2.1.1 Subsection two point one point one</H3>
<H4>2.1.1.3 Subsubsection two point one point one point three</H4>
<H5>2.1.1.3.7 Heading level 5</H5>
<H6>2.1.1.3.7.1 Heading level 6 (a long heading across
two lines)</H6>
<P>paragraph text</P>
<H6>2.1.1.3.7.1.2 There are no more than 6 heading levels.</H6>
<P>paragraph text</P>
<H1>3. Chapter three</H1>


(paras => 1, bullets => 1)

Ordinary text

  * bulleted paragraph

  * another bulleted paragarph
    with two lines

ordinary text

* bullet flush left

	 * bullet with tabs

	 - bullet with hyphen

<P>Ordinary text</P>
<UL><LI><P>bulleted paragraph</P>
<LI><P>another bulleted paragarph
    with two lines</P>
</UL><P>ordinary text</P>
<UL><LI><P>bullet flush left</P>
<LI><P>bullet with tabs</P>
<LI><P>bullet with hyphen</P>
</UL>


(paras => 1, headings => 1, numbers => 1)

1. This is a heading, not a numbered paragraph

  1. number one

  2. number two

  31. number thirty-one

ordinary text

  1. another number one

  * bulleted paragraph not recognised

  3. number three

<H1>1. This is a heading, not a numbered paragraph</H1>
<OL><LI VALUE="1"><P>number one</P>
<LI VALUE="2"><P>number two</P>
<LI VALUE="31"><P>number thirty-one</P>
</OL><P>ordinary text</P>
<OL><LI VALUE="1"><P>another number one</P>
</OL><P>  * bulleted paragraph not recognised</P>
<OL><LI VALUE="3"><P>number three</P>
</OL>


(paras => 1, numbers => 1, bullets => 1)

   1. a numbered item

   2. and another

      * switching to bullets starts a new list

  3. as does switching back

<OL><LI VALUE="1"><P>a numbered item</P>
<LI VALUE="2"><P>and another</P>
</OL><UL><LI><P>switching to bullets starts a new list</P>
</UL><OL><LI VALUE="3"><P>as does switching back</P>
</OL>


(paras => 1, numbers => 1, bullets => 1)

* a bulleted list
* with all the bullets next to each other
* blah
* blah

<UL><LI><P>a bulleted list</P>
<LI><P>with all the bullets next to each other</P>
<LI><P>blah</P>
<LI><P>blah</P>
</UL>


(paras => 1, numbers => 1, bullets => 1)

1. a numbered list
2. with all the numbers next to each other
3. blah
4. blah

<OL><LI VALUE="1"><P>a numbered list</P>
<LI VALUE="2"><P>with all the numbers next to each other</P>
<LI VALUE="3"><P>blah</P>
<LI VALUE="4"><P>blah</P>
</OL>


(paras => 1, numbers => 1, bullets => 1)

* switching between
111 numbers
* and
222 bullets

<UL><LI><P>switching between</P>
</UL><OL><LI VALUE="111"><P>numbers</P>
</OL><UL><LI><P>and</P>
</UL><OL><LI VALUE="222"><P>bullets</P>
</OL>


(paras => 1, numbers => 1, bullets => 1)

Ordinary paragraphs
* mixed up with
numbers
789 and
bullets

<P>Ordinary paragraphs</P>
<UL><LI><P>mixed up with
numbers</P>
</UL><OL><LI VALUE="789"><P>and
bullets</P>
</OL>


(paras => 1, numbers => 1, bullets => 1)

000 different
002. kinds
003) of
004] numbered
001 list

<OL><LI VALUE="000"><P>different</P>
<LI VALUE="002"><P>kinds</P>
<LI VALUE="003"><P>of</P>
<LI VALUE="004"><P>numbered</P>
<LI VALUE="001"><P>list</P>
</OL>


(paras => 1, blockquotes => 1)

Here's a block quote:

   line 1
   line 2
   line 3
   line 4

end of block quote

<P>Here's a block quote:</P>
<BLOCKQUOTE>line 1<BR>
line 2<BR>
line 3<BR>
line 4</BLOCKQUOTE>
<P>end of block quote</P>


(paras => 1, blockquotes => 1)

A block quote with variable spacing:

  line 1
    line 2
      line 3

end of block quote

<P>A block quote with variable spacing:</P>
<BLOCKQUOTE>line 1<BR>
  line 2<BR>
    line 3</BLOCKQUOTE>
<P>end of block quote</P>


(paras => 1, blockquotes => 1)

Ditto, spacing goes the other way:

      line 1
    line 2
  line 3

end of block quote

<P>Ditto, spacing goes the other way:</P>
<BLOCKQUOTE>    line 1<BR>
  line 2<BR>
line 3</BLOCKQUOTE>
<P>end of block quote</P>


(paras => 1, blockquotes => 1)

This shouldn't be recognized as blockquote:

   despite the spaces on this line,
   and this one,
this is just an ordinary paragraph?

<P>This shouldn't be recognized as blockquote:</P>
<P>   despite the spaces on this line,
   and this one,
this is just an ordinary paragraph?</P>


(paras => 1, bullets => 1, numbers => 1, blockquotes => 1)

  
This is not a blockquote, despite initial and final blank lines.
  

<P>This is not a blockquote, despite initial and final blank lines.</P>


(pre => 1)

preformatted
text

<PRE>preformatted
text</PRE>


(paras => 1, blockparas => 1)

Turing wrote,

    I propose to consider the question, "Can machines think?"
    This should begin with definitions of the meaning of the
    terms "machine" and "think".

<P>Turing wrote,</P>
<BLOCKQUOTE><P>I propose to consider the question, &quot;Can machines think?&quot;
This should begin with definitions of the meaning of the
terms &quot;machine&quot; and &quot;think&quot;.</P></BLOCKQUOTE>


(paras => 1, blockquotes => 1)

From "The Waste Land":

    Phlebas the Phoenecian, a fortnight dead,
    Forgot the cry of gulls, and the deep sea swell

<P>From &quot;The Waste Land&quot;:</P>
<BLOCKQUOTE>Phlebas the Phoenecian, a fortnight dead,<BR>
Forgot the cry of gulls, and the deep sea swell</BLOCKQUOTE>


(paras => 1, blockcode => 1)

Here's how to output numbers with commas (from perlfaq4):

    sub commify {
      local $_ = shift;
      1 while s/^(-?\d+)(\d{3})/$1,$2/;
      $_;
    }

<P>Here's how to output numbers with commas (from perlfaq4):</P>
<BLOCKQUOTE><TT>sub&nbsp;commify&nbsp;{<BR>
&nbsp;&nbsp;local&nbsp;$_&nbsp;=&nbsp;shift;<BR>
&nbsp;&nbsp;1&nbsp;while&nbsp;s/^(-?\d+)(\d{3})/$1,$2/;<BR>
&nbsp;&nbsp;$_;<BR>
}</TT></BLOCKQUOTE>


()

Line mixing tabs and metachars:
	&&&	<>	

Line mixing tabs and metachars:
        &amp;&amp;&amp;     &lt;&gt;      


(paras => 1, tables => 1)

	1, 1	1, 2	1, 3
	2, 1	2, 2	2, 3
	3, 1	3, 2	3, 3

<BLOCKQUOTE><TABLE>
<TR><TD>1, 1</TD><TD>1, 2</TD><TD>1, 3</TD></TR>
<TR><TD>2, 1</TD><TD>2, 2</TD><TD>2, 3</TD></TR>
<TR><TD>3, 1</TD><TD>3, 2</TD><TD>3, 3</TD></TR>
</TABLE></BLOCKQUOTE>


(paras => 1, tables => 1)

Tables can be left-aligned:

1, 1	1, 2	1, 3	
2, 1	2, 2	2, 3	
3, 1	3, 2	3, 3	

<P>Tables can be left-aligned:</P>
<P><TABLE>
<TR><TD>1, 1</TD><TD>1, 2</TD><TD>1, 3</TD></TR>
<TR><TD>2, 1</TD><TD>2, 2</TD><TD>2, 3</TD></TR>
<TR><TD>3, 1</TD><TD>3, 2</TD><TD>3, 3</TD></TR>
</TABLE></P>


(paras => 1, tables => 1)

   despite its    appearance
   this    table  has
   only    two    columns

<BLOCKQUOTE><TABLE>
<TR><TD>despite its</TD><TD>appearance</TD></TR>
<TR><TD>this    table</TD><TD>has</TD></TR>
<TR><TD>only    two</TD><TD>columns</TD></TR>
</TABLE></BLOCKQUOTE>


(paras => 1, tables => 1)

  tables
  must
  have
  two
  columns

<P>  tables
  must
  have
  two
  columns</P>


(paras => 1, tables => 1)

 tables  can
 have    only
 one     space
 at the  left

<BLOCKQUOTE><TABLE>
<TR><TD>tables</TD><TD>can</TD></TR>
<TR><TD>have</TD><TD>only</TD></TR>
<TR><TD>one</TD><TD>space</TD></TR>
<TR><TD>at the</TD><TD>left</TD></TR>
</TABLE></BLOCKQUOTE>


(paras => 1, tables => 1)

  tables  must  have  two  rows

<P>  tables  must  have  two  rows</P>


(paras => 1, tables => 1)

  this  table  has  varying  lengths  of  column
  at    the    right

<BLOCKQUOTE><TABLE>
<TR><TD>this</TD><TD>table</TD><TD>has  varying  lengths  of  column</TD></TR>
<TR><TD>at</TD><TD>the</TD><TD>right</TD></TR>
</TABLE></BLOCKQUOTE>


(paras => 1, tables => 1)

This table contains right-aligned cells:

     p   p^2   p^3    p^4
     2     4     8     16
     3     9    27     81
     5    25   125    625
     7    49   343   2401

<P>This table contains right-aligned cells:</P>
<BLOCKQUOTE><TABLE>
<TR><TD>p</TD><TD ALIGN="RIGHT">p^2</TD><TD ALIGN="RIGHT">p^3</TD><TD ALIGN="RIGHT">p^4</TD></TR>
<TR><TD>2</TD><TD ALIGN="RIGHT">4</TD><TD ALIGN="RIGHT">8</TD><TD ALIGN="RIGHT">16</TD></TR>
<TR><TD>3</TD><TD ALIGN="RIGHT">9</TD><TD ALIGN="RIGHT">27</TD><TD ALIGN="RIGHT">81</TD></TR>
<TR><TD>5</TD><TD ALIGN="RIGHT">25</TD><TD ALIGN="RIGHT">125</TD><TD ALIGN="RIGHT">625</TD></TR>
<TR><TD>7</TD><TD ALIGN="RIGHT">49</TD><TD ALIGN="RIGHT">343</TD><TD ALIGN="RIGHT">2401</TD></TR>
</TABLE></BLOCKQUOTE>


(paras => 1, tables => 1)

This table contains metacharacters:

   &   &amp;
   <   &lt;
   >   &gt;

<P>This table contains metacharacters:</P>
<BLOCKQUOTE><TABLE>
<TR><TD>&amp;</TD><TD>&amp;amp;</TD></TR>
<TR><TD>&lt;</TD><TD>&amp;lt;</TD></TR>
<TR><TD>&gt;</TD><TD>&amp;gt;</TD></TR>
</TABLE></BLOCKQUOTE>


(paras => 1, tables => 1)

Here's a table with centre-aligned columns:

1            1
2           1 1
3          1 2 1
4         1 3 3 1
5        1 4 6 4 1

<P>Here's a table with centre-aligned columns:</P>
<P><TABLE>
<TR><TD>1</TD><TD ALIGN="CENTER">1</TD></TR>
<TR><TD>2</TD><TD ALIGN="CENTER">1 1</TD></TR>
<TR><TD>3</TD><TD ALIGN="CENTER">1 2 1</TD></TR>
<TR><TD>4</TD><TD ALIGN="CENTER">1 3 3 1</TD></TR>
<TR><TD>5</TD><TD ALIGN="CENTER">1 4 6 4 1</TD></TR>
</TABLE></P>


(paras => 1, blockparas => 1, tables => 1)

  This  should  get  recognised
  as  a  blockquote  despite
  the  unorthodox  spacing.

  But  this   is  a  table
  XXX  XXXX   XX  X  XXXXX

<BLOCKQUOTE><P>This  should  get  recognised
as  a  blockquote  despite
the  unorthodox  spacing.</P></BLOCKQUOTE>
<BLOCKQUOTE><TABLE>
<TR><TD>But</TD><TD>this</TD><TD>is</TD><TD>a</TD><TD>table</TD></TR>
<TR><TD>XXX</TD><TD>XXXX</TD><TD>XX</TD><TD>X</TD><TD>XXXXX</TD></TR>
</TABLE></BLOCKQUOTE>

