package Exporter::Lite;

require 5.006;
use warnings;
use strict;

our $VERSION = '0.08';
our @EXPORT = qw(import);


sub import {
    my($exporter, @imports)  = @_;
    my($caller, $file, $line) = caller;

    no strict 'refs';

    unless( @imports ) {        # Default import.
        @imports = @{$exporter.'::EXPORT'};
    }
    else {
        # Because @EXPORT_OK = () would indicate that nothing is
        # to be exported, we cannot simply check the length of @EXPORT_OK.
        # We must to oddness to see if the variable exists at all as
        # well as avoid autovivification.
        # XXX idea stolen from base.pm, this might be all unnecessary
        my $eokglob;
        if( $eokglob = ${$exporter.'::'}{EXPORT_OK} and *$eokglob{ARRAY} ) {
            if( @{$exporter.'::EXPORT_OK'} ) {
                # This can also be cached.
                my %ok = map { s/^&//; $_ => 1 } @{$exporter.'::EXPORT_OK'},
                                                 @{$exporter.'::EXPORT'};

                my($denied) = grep {s/^&//; !$ok{$_}} @imports;
                _not_exported($denied, $exporter, $file, $line) if $denied;
            }
            else {      # We don't export anything.
                _not_exported($imports[0], $exporter, $file, $line);
            }
        }
    }

    _export($caller, $exporter, @imports);
}



sub _export {
    my($caller, $exporter, @imports) = @_;

    no strict 'refs';

    # Stole this from Exporter::Heavy.  I'm sure it can be written better
    # but I'm lazy at the moment.
    foreach my $sym (@imports) {
        # shortcut for the common case of no type character
        (*{$caller.'::'.$sym} = \&{$exporter.'::'.$sym}, next)
            unless $sym =~ s/^(\W)//;

        my $type = $1;
        my $caller_sym = $caller.'::'.$sym;
        my $export_sym = $exporter.'::'.$sym;
        *{$caller_sym} =
            $type eq '&' ? \&{$export_sym} :
            $type eq '$' ? \${$export_sym} :
            $type eq '@' ? \@{$export_sym} :
            $type eq '%' ? \%{$export_sym} :
            $type eq '*' ?  *{$export_sym} :
            do { require Carp; Carp::croak("Can't export symbol: $type$sym") };
    }
}


#"#
sub _not_exported {
    my($thing, $exporter, $file, $line) = @_;
    die sprintf qq|"%s" is not exported by the %s module at %s line %d\n|,
        $thing, $exporter, $file, $line;
}

1;

__END__

=head1 NAME

Exporter::Lite - lightweight exporting of functions and variables

=head1 SYNOPSIS

  package Foo;
  use Exporter::Lite;

  our @EXPORT    = qw($This That);      # default exports
  our @EXPORT_OK = qw(@Left %Right);    # optional exports

Then in code using the module:

  use Foo;
  # $This and &That are imported here

You have to explicitly ask for optional exports:

 use Foo qw/ @Left %Right /;

=head1 DESCRIPTION

Exporter::Lite is an alternative to L<Exporter>,
intended to provide a lightweight subset
of the most commonly-used functionality.
It supports C<import()>, C<@EXPORT> and
C<@EXPORT_OK> and not a whole lot else.

Unlike Exporter, it is not necessary to inherit from Exporter::Lite;
Ie you don't need to write:

 @ISA = qw(Exporter::Lite);

Exporter::Lite simply exports its import() function into your namespace.
This might be called a "mix-in" or a "role".

Setting up a module to export its variables and functions is simple:

    package My::Module;
    use Exporter::Lite;

    our @EXPORT = qw($Foo bar);

Functions and variables listed in the C<@EXPORT> package variable
are automatically exported if you use the module and don't explicitly
list any imports.
Now, when you C<use My::Module>, C<$Foo> and C<bar()> will show up.

Optional exports are listed in the C<@EXPORT_OK> package variable:

    package My::Module;
    use Exporter::Lite;

    our @EXPORT_OK = qw($Foo bar);

When My::Module is used, C<$Foo> and C<bar()> will I<not> show up,
unless you explicitly ask for them:

    use My::Module qw($Foo bar);

Note that when you specify one or more functions or variables to import,
then you must also explicitly list any of the default symbols you want to use.
So if you have an exporting module:

    package Games;
    our @EXPORT    = qw/ pacman defender  /;
    our @EXPORT_OK = qw/ galaga centipede /;

Then if you want to use both C<pacman> and C<galaga>, then you'd write:

    use Games qw/ pacman galaga /;

=head1 Methods

Export::Lite has one public method, import(), which is called
automatically when your modules is use()'d.  

In normal usage you don't have to worry about this at all.

=over 4

=item B<import>

  Some::Module->import;
  Some::Module->import(@symbols);

Works just like C<Exporter::import()> excepting it only honors
@Some::Module::EXPORT and @Some::Module::EXPORT_OK.

The given @symbols are exported to the current package provided they
are in @Some::Module::EXPORT or @Some::Module::EXPORT_OK.  Otherwise
an exception is thrown (ie. the program dies).

If @symbols is not given, everything in @Some::Module::EXPORT is
exported.

=back

=head1 DIAGNOSTICS

=over 4

=item '"%s" is not exported by the %s module'

Attempted to import a symbol which is not in @EXPORT or @EXPORT_OK.

=item 'Can\'t export symbol: %s'

Attempted to import a symbol of an unknown type (ie. the leading $@% salad
wasn't recognized).

=back


=head1 SEE ALSO

L<Exporter> is the grandaddy of all Exporter modules, and bundled with Perl
itself, unlike the rest of the modules listed here.

L<Attribute::Exporter> defines attributes which you use to mark
which subs and variables you want to export, and how.

L<Exporter::Simple> also uses attributes to control the export of
functions and variables from your module.

L<Const::Exporter> makes it easy to create a module that exports constants.

L<Constant::Exporter> is another module that makes it easy to create
modules that define and export constants.

L<Sub::Exporter> is a "sophisticated exporter for custom-built routines";
it lets you provide generators that can be used to customise what
gets imported when someone uses your module.

L<Exporter::Tiny> provides the same features as L<Sub::Exporter>,
but relying only on core dependencies.

L<Exporter::Shiny> is a shortcut for L<Exporter::Tiny> that
provides a more concise notation for providing optional exports.

L<Exporter::Declare> provides syntactic sugar to make the export
status of your functions part of their declaration. Kind of.

L<AppConfig::Exporter> lets you export part of an L<AppConfig>-based
configuration.

L<Exporter::Lexical> lets you export lexical subs from your module.

L<Constant::Export::Lazy> lets you write a module that exports
function-style constants, which are instantiated lazily.

L<Exporter::Auto> will export everything from your module that
it thinks is a public function (name doesn't start with an underscore).

L<Class::Exporter> lets you export class methods as regular subroutines.

L<Xporter> is like Exporter, but with persistent defaults and auto-ISA.


=head1 REPOSITORY

L<https://github.com/neilb/Exporter-Lite>

=head1 AUTHORS

Michael G Schwern <schwern@pobox.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
