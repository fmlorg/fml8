package Utils;

@ISA = qw(Exporter);
@EXPORT = qw(slurp spew cmp);

sub slurp { 
    my $path = shift;
    open IN, "<$path"; my $data = join('',<IN>); close IN; $data;
}

sub spew  { 
    my ($path, $data) = @_;
    open OUT, ">$path"; print OUT $data; close OUT;
}

sub cmp {
    my ($a, $b) = @_;
    $a =~ s/\r//g;
    $b =~ s/\r//g;
    return ($a eq $b);
}

1;
