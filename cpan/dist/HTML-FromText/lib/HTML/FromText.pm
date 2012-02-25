package HTML::FromText;

=head1 NAME

HTML::FromText - Convert plain text to HTML.

=head1 SYNOPSIS

    use HTML::FromText;
    text2html( $text, %options );

    # or

    use HTML::FromText ();
    my $t2h  = HTML::FromText->new( \%options );
    my $html = $t2h->parse( $html );

=cut

use strict;
use Scalar::Util          qw[blessed];
use HTML::Entities        qw[encode_entities];
use Text::Tabs            qw[expand];
use Email::Find::addrspec qw[$Addr_spec_re];
use Exporter::Lite;

use vars qw[$VERSION @EXPORT @DECORATORS $PROTOCOLS];

$VERSION    = '2.05';
@EXPORT     = qw[text2html];
@DECORATORS = qw[urls email bold underline];
$PROTOCOLS  = qr/
                 afs      | cid      | ftp      | gopher   |
                 http     | https    | mid      | news     |
                 nntp     | prospero | telnet   | wais
                /x;

=head1 DESCRIPTION

C<HTML::FromText> converts plain text to HTML. There are a handfull of
options that shape the conversion. There is a utility function,
C<text2html>, that's exported by default. This function is simply a short-
cut to the Object Oriented interface described in detail below.

=head2 Methods

The following methods may be used as the public interface.

=head3 new

    my $t2h = HTML::FromText->new({
        paras      => 1,
        blockcode  => 1,
        tables     => 1,
        bullets    => 1,
        numbers    => 1,
        urls       => 1,
        email      => 1,
        bold       => 1,
        underline  => 1,
    });

Constructs a new C<HTML::FromText> object using the given
configuration. The resulting object can parse lots of objects using the
C<parse> method.

Options to C<new> are passed by name, with the value being either true
or false. If true, the option will be turned on. If false, it will be
turned off.  The following outlines all the options.

=head4 Decorators

=over 5

=item metachars

This option is on by default.

All characters that are unsafe for HTML display will be encoded using
C<HTML::Entities::encode_entities()>.

=item urls

This option is off by default.

Replaces URLs with links.

=item email

This option is off by default.

Replaces email addresses with C<mailto:> links.

=item bold

This option is off by default.

Replaces text surrounded by asterisks (C<*>) with the same text
surrounded by C<strong> tags.

=item underline

This option is off by default.

Replaces text surrownded by underscores (C<_>) with the same text
surrounded by C<span> tags with an underline style.

=back

=head4 Output Modes

The following are three output modes and the options associated with
them. They are listed in order of precidence. If none of these modes are
supplied, the basic decorators are applied to the text in whole.

=over 5

=item B<pre>

This option is off by default.

Wraps the entire text in C<pre> tags.

=item B<lines>

This option is off by default.

Preserves line breaks by inserting C<br> tags at the end of each line.

This mode has further options.

=over 5

=item spaces

This option is off by default.

All spaces are HTML encoded.

=back

=item B<paras>

This option is off by default.

Preserves paragraphs by wrapping them in C<p> tags.

This mode has further options.

=over 5

=item bullets

This option is off by default.

Convert bulleted lists into unordered lists (C<ul>). Bullets can be
either an asterisk (C<*>) or a hyphen (C<->). Lists can be nested.

=item numbers

This option is off by default.

Convert numbered lists into ordered lists (C<ol>). Numbered lists are
identified by numerals. Lists may be nested.

=item headings

This option is off by default.

Convert paragraphs identified as headings into HTML headings at
the appropriate level. The heading C<1. Top> would be heading
level one (C<h1>). The heading C<2.5.1. Blah> would be heading
level three (C<h3>).

=item title

This option is off by default.

Convert the first paragraph to a heading level one (C<h1>).

=item tables

This option is off by default.

Convert paragraphs identified as tables to HTML tables. Tables are two
or more rows and two or more columns. Columns should be separated by two
or more spaces.

=back

The following options apply specifically to indented paragraphs. They
are listed in order of precidence.

=over 5

=item blockparas

This option is off by default.

Convert indented paragraphs to block quotes using the C<blockquote> tag.

=item blockquotes

Convert indented paragraphs as C<blockparas> would, but also preserving
line breaks.

=item blockcode

Convert indented paragraphs as C<blockquotes> would, but also preserving
spaces using C<pre> tags.

=back

=back

=cut

sub new {
    my ($class, $options) = @_;
    $options ||= {};
    $class->_croak("Options must be a hash reference")
      if ref($options) ne 'HASH';

    my %options = (
                   metachars    => 1,
                   urls         => 0,
                   email        => 0,
                   bold         => 0,
                   underline    => 0,

                   pre          => 0,

                   lines        => 0,
                   spaces       => 0,

                   paras        => 0,
                   bullets      => 0,
                   numbers      => 0,
                   headings     => 0,
                   title        => 0,
                   blockparas   => 0,
                   blockquotes  => 0,
                   blockcode    => 0,
                   tables       => 0,

                   %{ $options },
                  );

    my %self    = (
                   options => \%options,
                   text    => '',
                   html    => '',
                  );

    return bless \%self, blessed($class) || $class;
}

=head3 parse

  my $html = $t2h->parse( $text );

Parses text supplied as a single scalar string and returns the HTML as a
single scalar string.  All the tabs in your text will be expanded using
C<Text::Tabs::expand()>.

=cut

sub parse {
    my ($self, $text) = @_;

    $text = join "\n", expand( split /\n/, $text );

    $self->{text}  = $text;
    $self->{html}  = $text;
    $self->{paras} = undef;

    my $options = $self->{options};

    $self->metachars if $options->{metachars};

       if ( $options->{pre}   ) { $self->pre   }
    elsif ( $options->{lines} ) { $self->lines }
    elsif ( $options->{paras} ) { $self->paras }

    $options->{$_} and $self->$_ foreach @DECORATORS;

    return $self->{html};
}

=head2 Functions

=head3 text2html

    my $html = text2html(
                         $text,
                         urls  => 1,
                         email => 1,
                        );

Functional interface that just wraps the OO interface. This function is
exported by default. If you don't want it you can C<require> the module
or C<use> it with an empty list.

    require HTML::FromText;
    # or ...
    use HTML::FromText ();

=cut

sub text2html {
    my ($text, %options) = @_;
    HTML::FromText->new(\%options)->parse($text);
}

=head2 Subclassing

B<Note:> At the time of this release, the internals of C<HTML::FromText>
are in a state of development and cannot be expected to stay the same
from release to release. I expect that release version B<3.00> will be
analogous to a C<1.00> release of other software. This is because the
current maintainer has rewritten this distribution from the ground up
for the C<2.x> series.  You have been warned.

The following methods may be used for subclassing C<HTML::FromText>
to create your own text to HTML conversions. Each of these methods
is passed just one argument, the object (C<$self>), unless
otherwise stated.

The structure of C<$self> is as follows for this release.

    {
     options => {
                 option_name => $value,
                 ...
                },
     text    => $text, # as passed to parse(), with tabs expanded
     html    => $html, # the HTML that will be returned from parse()
    }

=head3 pre

Used when C<pre> mode is specified.

Should set C<< $self->{html} >>.

Return value is ignored.

=cut

sub pre {
    my ($self) = @_;
    $self->{html} = join $self->{html}, '<pre class="hft-pre">', '</pre>';
}

=head3 lines

Used when C<lines> mode is specified.

Implements the C<spaces> option internally when the option is set to a
true value.

Should set C<< $self->{html} >>.

Return value is ignored.

=cut

sub lines {
    my ($self) = @_;
    $self->{html} =~ s[ ][&nbsp;]g if $self->{options}->{spaces};
    $self->{html} =~ s[$][<br />]gm;
    $self->{html} =~ s[^][<div class="hft-lines">];
    $self->{html} =~ s[$][</div>];
}

=head3 paras

Used when the C<paras> mode is specified.

Splits C<< $self->{text} >> into paragraphs internally and sets up
C<< $self->{paras} >> as follows.

    paras => {
              0 => {
                    text => $text, # paragraph text
                    html => $html, # paragraph html
                   },
              ... # and so on for all paragraphs
             },

Implements the C<title> option internally when the option is turned on.

Converts any normal paragraphs to HTML paragraphs (surrounded by C<p>
tags) internally.

Should set C<< $self->{html} >>.

Return value is ignored.

=cut

sub paras {
    my ($self) = @_;

    my $options = $self->{options};
    my @paras   = split /\n{2,}/, $self->{html};
    my %paras   = map { $_, { text => $paras[$_], html => undef } } 0 .. $#paras;
    $self->{paras} = \%paras;

    $self->{paras}->{0}->{html} = join(
                                       $self->{paras}->{0}->{text},
                                       q[<h1 class="hft-title">], "</h1>\n"
                                      ) if $options->{title};

    $self->headings if $options->{headings};
    $self->bullets  if $options->{bullets};
    $self->numbers  if $options->{numbers};

    $self->tables   if $options->{tables};

       if ( $options->{blockparas}  ) { $self->blockparas  }
    elsif ( $options->{blockquotes} ) { $self->blockquotes }
    elsif ( $options->{blockcode}   ) { $self->blockcode   }

    $self->_manipulate_paras(sub { qq[<p class="hft-paras">$_[0]</p>\n] });

    $self->{html} = join "\n", map $paras{$_}->{html},
      sort { $a <=> $b } keys %paras;
}

=head3 headings

Used to format headings when the C<headings> option is turned on.

Return value is ignored.

=cut

sub headings {
    my ($self) = @_;
    my $heading = qr/\d+\./;

    $self->_manipulate_paras(sub{
        my ($text) = @_;
        return unless $text =~ m[^((?:$heading)+)\s+];

        my $depth; $depth++ for split /\./, $1;

        qq[<h$depth class="hft-headings">$text</h$depth>\n];
    });
}

=head3 bullets

Format bulleted lists when the C<bullets> option is turned on.

Return value is ignored.

=cut

sub bullets {
    my ($self) = @_;
    $self->_format_list( qr/[*]/, 'ul', 'hft-bullets' );
    $self->_format_list( qr/[-]/, 'ul', 'hft-bullets' );
}

=head3 numbers

Format numbered lists when the C<numbers> option is turned on.

Return value is ignored.

=cut

sub numbers {
    my ($self) = @_;
    $self->_format_list( qr/[0-9]/, 'ol', 'hft-numbers');
}

=head3 tables

Format tables when the C<tables> option is turned on.

Return value is ignored.

=cut

sub tables {
    my ($self) = @_;

    $self->_manipulate_paras(sub{
        my ($text) =  $self->_remove_indent( $_[0] );

        my @lines   = split /\n/, $text;
        my $columns = $self->_table_find_columns(
                        $self->_table_initial_spaces( split //, $lines[0] ),
                        [ @lines[1 .. $#lines] ],
                      );

        return unless $columns;
        $self->_table_create( $columns, \@lines );
    });
}

=head3 blockparas

Used when the C<blockparas> option is turned on.

Return value is ignored.

=cut

sub blockparas {
    my ($self) = @_;
    my $paras = $self->{paras};

    $self->_manipulate_paras(sub{
        my ($text) = $self->_remove_indent( $_[0], 1 );
        my ($pnum, $paras) = @_[1,2];
        return unless $text;

        $self->_consolidate_blocks(
                                   ( exists $paras->{$pnum - 1} ? $paras->{$pnum -1} : undef ),
                                   'blockparas', 1,
                                   qq[<blockquote class="hft-blockparas"><p>$text</p></blockquote>\n],
                                  );
    });
}

=head3 blockquotes

Used when the C<blockquotes> option is turned on.

Return value is ignored.

=cut

sub blockquotes {
    my ($self) = @_;
    my $paras = $self->{paras};

    $self->_manipulate_paras(sub {
        my ($text) = $self->_remove_indent( $_[0], 1 );
        return unless $text;

        $text =~ s[\n|$][<br />\n]g;

        qq[<blockquote class="hft-blockquotes"><div>$text</div></blockquote>\n];
    });
}

=head3 blockcode

Used when the C<blockcode> option is turned on.

Return value is ignored.

=cut

sub blockcode {
    my ($self) = @_;
    my $paras = $self->{paras};

    $self->_manipulate_paras(sub {
        my ($text) = $self->_remove_indent( $_[0], 1 );
        my ($pnum, $paras) = @_[1,2];
        return unless $text;

        $text =~ s[^][<pre>];
        $text =~ s[$][</pre>];
        $self->_consolidate_blocks(
                                   ( exists $paras->{$pnum - 1} ? $paras->{$pnum -1} : undef ),
                                   'blockcode', 0,
                                   qq[<blockquote class="hft-blockcode">$text</blockquote>\n],
                                  );
    });
}

=head3 urls

Turn urls into links when C<urls> option is turned on.

Should operate on C<< $self->{html} >>.

Return value is ignored.

=cut

sub urls {
    my ($self) = @_;
    $self->{html} =~ s[\b((?:$PROTOCOLS):[^\s<]+[\w/])]
                      [<a href="$1" class="hft-urls">$1</a>]og;
}

=head3 email

Turn email addresses into C<mailto:> links when C<email> option is
turned on.

Should operate on C<< $self->{html} >>.

Return value is ignored.

=cut

sub email {
    my ($self) = @_;
    $self->{html} =~ s[($Addr_spec_re)]
                      [<a href="mailto:$1" class="hft-email">$1</a>]og;
}

=head3 underline

Underline things between _underscores_ when C<underline> option is
turned on.

Should operate on C<< $self->{html} >>.

Return value is ignored.

=cut

sub underline {
    my ($self) = @_;
    $self->{html} =~ s[(?:^|(?<=\W))((_)([^\\_\n]*(?:\\.[^\\_\n]*)*)(_))(?:(?=\W)|$)]
                      [<span class="hft-underline" style="text-decoration: underline">$3</span>]g;
}

=head3 bold

Bold things between *asterisks* when C<bold> option is turned on.

Should operate on C<< $self->{html} >>.

Return value is ignored.

=cut

sub bold {
    my ($self) = @_;
    $self->{html} =~ s[(?:^|(?<=\W))((\*)([^\\\*\n]*(?:\\.[^\\\*\n]*)*)(\*))(?:(?=\W)|$)]
                      [<strong class="hft-bold">$3</strong>]g;
}

=head3 metachars

Encode meta characters when C<metachars> option is turned on.

Should operate on C<< $self->{html} >>.

Return value is ignored.

=cut

sub metachars {
    my ($self) = @_;
    $self->{html} = encode_entities( $self->{html} );
}

# private

sub _croak {
    my ($class, @error) = @_;
    require Carp;
    Carp::croak(@error);
}

sub _carp {
    my ($class, @error) = @_;
    require Carp;
    Carp::carp(@error);
}

sub _format_list {
    my ($self, $identifier, $parent, $class) = @_;

    $self->_manipulate_paras(sub {
        my ($text) = @_;
        return unless $text =~ m[^\s*($identifier)\s+];

        my ($pos, $html, @open) = (-1, '');
        foreach my $line ( split /\n(?=\s*$identifier)/, $text ) {
            $line =~ s[(\s*)$identifier][];
            my $line_pos = length $1;
            if ($line_pos > $pos) {
                $html .= (' ' x $line_pos) . qq[<$parent class="$class">\n];
                push @open, $line_pos;
            } elsif ($line_pos < $pos) {
                until ( $open[-1] <= $line_pos ) {
                    $html .= (' ' x pop @open) . "</$parent>\n";
                }
            }
            $html .= (' ' x ($pos = $line_pos)) . "<li>$line</li>\n";
        }
        $html .= "</$parent>\n"x@open;
    });
}

sub _manipulate_paras {
    my ($self, $action) = @_;

    my  $paras = $self->{paras};

    foreach my $pnum ( sort { $a <=> $b } keys %{$paras}) {
        my $para = $paras->{$pnum};
        $para->{html} = $action->($para->{text}, $pnum,  $paras)
          unless $para->{html};
    }
}

sub _table_initial_spaces {
    my ($self, @chars) = @_;

    my %spaces;
    foreach ( 0 .. $#chars ) {
        my ($open_space) = grep { !defined( $_->{end} ) } values %spaces;
        if ( $chars[$_] eq ' ' ) {
            $spaces{$_} = {start => $_, end => undef} unless $open_space;
        } else {
            if ( $open_space && $_ - $open_space->{start} > 1 ) {
                $open_space->{end} = $_ - 1;
            } else {
                delete $spaces{$open_space->{start}} if $open_space;
            }
        }
    }
    return \%spaces;
}

sub _table_find_columns {
    my ($self, $spaces, $lines) = @_;
    return unless keys %{$spaces};
    my %spots;
    foreach my $line ( @{$lines} ) {
        foreach my $pos ( sort { $a <=> $b } keys %{$spaces} ) {
            my $key;
               $key = $spaces->{$pos}->{start}
                 if substr( $line, $spaces->{$pos}->{start}, 1 ) eq ' ';
               $key = $spaces->{$pos}->{end}
                 if substr( $line, $spaces->{$pos}->{end}, 1 )   eq ' ' && ! $key;
            if ( $key ) {
                $spots{$key}++;
                $spots{$spaces->{$pos}->{start}}++
                  if $spots{$spaces->{$pos}->{start}} && $key ne $spaces->{$pos}->{start};
                $spots{$spaces->{$pos}->{end}}++
                  if $key ne $spaces->{$pos}->{end};
            } else {
                delete $spaces->{$pos};
            }
        }
        foreach my $spot (sort {$b <=> $a} keys %spots) {
            if ( substr( $line, $spot, 1 ) ne ' ' ) {
                delete $spots{$spot};
            }
            if ( exists $spaces->{$spot}) {
                my $space = $spaces->{$spot};
                if ( exists $spots{$space->{start}} && $spots{$space->{end}}) {
                    delete $spots{$spot};
                }
            }
        }
    }


    my @spots = grep { $spots{$_} == @{$lines} } sort { $a <=> $b } keys %spots;
    return @spots ? join( '', (
                      map {
                          my $ret = 'A' . ( $spots[$_] - ( $_ == 0 ? 0 : $spots[$_ - 1] ) );
                          $ret eq 'A0' ? () : $ret;
                      } 0 .. $#spots
                    ), 'A*' ) : undef;
}

sub _table_create {
    my ($self, $columns, $lines) = @_;

    my $table = qq[<table class="hft-tables">\n];
    foreach my $line ( @{$lines} ) {
        $table .= join( '',
                        '  <tr><td>',
                        join(
                             '</td><td>',
                             map { s/^\s+//; s/\s$//; $_ } unpack $columns, $line
                            ),
                        "</td></tr>\n",
                      );
    }
    $table .= "</table>\n";
}

sub _remove_indent {
    my ($self, $text, $strict) = @_;
    return if $text !~ m[^(\s+).+(?:\n\1.+)*$] && $strict;
    $text =~ s[^$1][]mg if $1;
    return $text;
}

sub _consolidate_blocks {
    my ($self, $prev_para, $class, $keep_inner, $html) = @_;
    if ( $prev_para && $prev_para->{html} =~ m[<blockquote class="hft-$class"><(\w+)>] ) {
        my $inner_tag = $keep_inner ? '' : qr[</?$1>];
        $prev_para->{html} =~ s[$inner_tag</blockquote>][];
        $html =~ s[<blockquote class="hft-$class">$inner_tag][];
    }
    return $html;
}

1;

__END__

=head2 Output

The output from C<HTML::FromText> has been updated to pass XHTML 1.1
validation. Every HTML tag that should have a CSS class name does. They
are prefixed with C<hft-> and correspond to the names of the options to
C<new()> (or C<text2html()>). For example C<hft-lines>, C<hft-paras>,
and C<hft-urls>.

One important note is the output for C<underline>. Because the <u> tag
is deprecated in this specification a C<span> is used with a style
attribute of C<text-decoration: underline>. The class is C<hft-
underline>. If you want to override the C<text-decoration> style in the
CSS class you'll need to do so like this.

    text-decoration: none !important;

=head1 SEE ALSO

L<text2html(1)>.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>.

=head1 AUTHOR EMERITUS

Gareth Rees <F<garethr@cre.canon.co.uk>>.

=head1 COPYRIGHT

  Copyright (c) 2003 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
