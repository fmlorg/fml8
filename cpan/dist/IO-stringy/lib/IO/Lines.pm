package IO::Lines;


=head1 NAME

IO::Lines - IO:: interface for reading/writing an array of lines


=head1 SYNOPSIS

    use IO::Lines;

    # See IO::ScalarArray for details 


=head1 DESCRIPTION

This class implements objects which behave just like FileHandle
(or IO::Handle) objects, except that you may use them to write to
(or read from) an array of lines.  They can be tiehandle'd as well.  

This is a subclass of L<IO::ScalarArray|IO::ScalarArray> 
in which the underlying
array has its data stored in a line-oriented-format: that is,
every element ends in a C<"\n">, with the possible exception of the
final element.  This makes C<getline()> I<much> more efficient;
if you plan to do line-oriented reading/printing, you want this class.

The C<print()> method will enforce this rule, so you can print
arbitrary data to the line-array: it will break the data at
newlines appropriately.

See L<IO::ScalarArray> for full usage.

=cut

use Carp;
use strict;
use IO::ScalarArray;
use vars qw($VERSION @ISA);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.111 $, 10;

# Inheritance:
@ISA = qw(IO::ScalarArray);     # also gets us new_tie  :-)


#------------------------------
# getline
#------------------------------
# Instance method, override.
# Return the next line, or undef on end of data.
# Can safely be called in an array context.
# Currently, lines are delimited by "\n".
#
sub getline {
    my $self = shift;
    if (!defined $/) {
	return join( '' => $self->getlines );
    }
    ($/ eq "\n")
	or croak '$/ must be "\n" or undef, not ', "'$/'.";

    if (!$self->{Pos}) {      # full line...
	return $self->{AR}[$self->{Str}++];
    }
    else {                    # partial line...
	my $partial = substr($self->{AR}[$self->{Str}++], $self->{Pos});
	$self->{Pos} = 0;
	return $partial;
    }
}

#------------------------------
# getlines
#------------------------------
# Instance method, override.
# Return an array comprised of the remaining lines, or () on end of data.
# Must be called in an array context.
# Currently, lines are delimited by "\n".
#
sub getlines {
    my $self = shift;
    wantarray or croak("Can't call getlines in scalar context!");

    my ($rArray, $Str, $Pos) = @$self{ qw( AR Str Pos ) };
    my @partial = ();

    if ($Pos) {					# partial line...
	@partial = (substr( $rArray->[ $Str++ ], $Pos ));
	$self->{Pos} = 0;
    }
    $self->{Str} = scalar @$rArray;		# about to exhaust @$rArray
    return (@partial,
	    @$rArray[ $Str .. $#$rArray ]);	# remaining full lines...
}

#------------------------------
# print ARGS...
#------------------------------
# Instance method, override.
# Print ARGS to the underlying line array.  
#
sub print {
    my $self = shift;
    ### print STDERR "\n[[ARRAY WAS...\n", @{$self->{AR}}, "<<EOF>>\n";
    my @lines = split /^/, join('', @_); @lines or return 1;

    # Did the previous print not end with a newline?  If so, append first line:
    if (@{$self->{AR}} and ($self->{AR}[-1] !~ /\n\Z/)) {
	$self->{AR}[-1] .= shift @lines;
    }
    push @{$self->{AR}}, @lines;       # add the remainder
    ### print STDERR "\n[[ARRAY IS NOW...\n", @{$self->{AR}}, "<<EOF>>\n";
    1;
}

#------------------------------
1;

__END__


=head1 VERSION

$Id: Lines.pm,v 1.111 2001/04/04 05:37:51 eryq Exp $


=head1 AUTHORS


=head2 Principal author

Eryq (F<eryq@zeegee.com>).
President, ZeeGee Software Inc (F<http://www.zeegee.com>).


=head2 Other contributors 

Thanks to the following individuals for their invaluable contributions
(if I've forgotten or misspelled your name, please email me!):

I<Morris M. Siegel,>
for his $/ patch and the new C<getlines()>.

=cut

