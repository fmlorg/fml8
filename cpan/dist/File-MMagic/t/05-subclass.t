use strict;
use warnings;
use Test::More tests => 3;

my $mm = Example::Module->new();
isa_ok( $mm, 'Example::Module', 'subclassed object' );
isa_ok( $mm, 'File::MMagic', 'subclassed object' );
is( $mm->checktype_filename(), 'foo/bar', 'override method' );

package Example::Module;
use base qw( File::MMagic );

sub checktype_filename { 'foo/bar' }
