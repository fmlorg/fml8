#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#
# $FML: MH.pm,v 1.6 2002/07/02 12:54:44 fukachan Exp $
#

package Mail::Message::MH;
use strict;

=head1 NAME

Mail::Message::MH - utilities to handle MH style format

=head1 SYNOPSIS

   use Mail::Message::MH;
   my $mh = new Mail::Message::MH;

=head1 DESCRIPTION

=head1 METHODS

=head2 expand($str, [$min, $max])

return ARRAY_REF of numbers specified by the following format:

    100
    100-110
    first-110
    100-last
    first
    first:100
    last
    last:100

=cut


# Descriptions: usual constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: expand MH style expression to list of numbers
#    Arguments: OBJ($self) STR($str) NUM($min) NUM($max)
# Side Effects: none
# Return Value: ARRAY_REF
sub expand
{
    my ($self, $str, $min, $max) = @_;
    my $ra = [];

    unless (defined $min) { $min = 1;}

    if ($str =~ /,/o) {
	for my $s (split(/,/, $str)) {
	    my $ra0 = $self->expand($s, $min, $max);
	    for my $element (@$ra0) { push(@$ra, $element);}
	}
	return $ra;
    }

    if ($str eq 'all') {
	unless (defined $max) { return undef;}
	return _expand_range($min, $max);
    }
    elsif ($str =~ /^\d+$/) {
        return [ $str ];
    }
    elsif ($str =~ /^(\d+)\-(\d+)$/) {
        my ($first, $last) = ($1, $2);
        return _expand_range($first, $last);
    }
    elsif ($str =~ /^(first)\-(\d+)$/) {
        my ($first, $last) = ($1, $2);
        return _expand_range($min, $last);
    }
    elsif ($str =~ /^(\d+)\-(last)$/) {
	unless (defined $max) { return undef;}
        my ($first, $last) = ($1, $2);
        return _expand_range($first, $max);
    }
    elsif ($str eq 'first') {
        return [ $min ];
    }
    elsif ($str eq 'last' || $str eq 'cur') {
	unless (defined $max) { return undef;}
        return [ $max ];
    }
    elsif ($str =~ /^first:(\d+)$/) {
	return _expand_range($min, $min + $1 - 1);
    }
    elsif ($str =~ /^last:(\d+)$/) {
	unless (defined $max) { return undef;}
	return _expand_range($max - $1 + 1, $max);
    }

    return [];
}


# Descriptions: make an array from $fist to $last number
#    Arguments: NUM($first_number) NUM($last_number)
# Side Effects: none
# Return Value: ARRAY_REF (as [ $first .. $last ])
sub _expand_range
{
    my ($first, $last) = @_;
    my (@fn) = ();

    for ($first .. $last) { push(@fn, $_);}

    return \@fn;
}


if ($0 eq __FILE__) {
    my $mh = new Mail::Message::MH;
    for (qw(1,2,3
	    1,10,last:20
	    100
	    100-110
	    first-110
	    190-last
	    first first:10
	    last  last:10
	    )) {
	print "\n[$_] => ";
	my $a = $mh->expand($_, 1, 200);
	print "@$a\n";
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::MH appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
