#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Bounce.pm,v 1.6 2001/04/12 12:06:11 fukachan Exp $
#

package Mail::Bounce;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;

=head1 NAME

Mail::Bounce - analye error messages

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub analyze
{
    my ($self, $msg) = @_;
    my $result = {};

    if ($debug) {
	my $h = $msg->get_data_type_list;
	print "   ----- dump msg -----\n";
	for (@$h) { print "   ", $_, "\n";}
	print "   ----- dump msg end -----\n";
    }

    for my $pkg (
		 'DSN', 
		 'Postfix19991231', 
		 'Qmail', 
		 'Exim',
		 'GOO',
		 'SimpleMatch', 
		 ) {
	my $module = "Mail::Bounce::$pkg";
	print "\n   --- module: $module\n" if $debug;
	eval qq { 
	    require $module; $module->import();
	    $module->analyze( \$msg , \$result );
	};
	croak($@) if $@;

	if (keys %$result) { 
	    print "\n   match $module\n" if $debug;
	    last;
	}
    }

    $self->{ _result } = $result;
}


sub address_list
{
    my ($self) = @_;
    my $result = $self->{ _result };
    return keys %$result;
}


sub status
{
    my ($self, $addr) = @_;
    my $status = $self->{ _result }->{ $addr }->{ 'Status' };
    $status =~ s/\s+/ /g;
    $status =~ s/\s*$//;
    $status;
}


sub reason
{
    my ($self, $addr) = @_;
    my $reason = $self->{ _result }->{ $addr }->{ 'Diagnostic-Code' };
    $reason =~ s/\s+/ /g;
    $reason =~ s/\s*$//; 
    $reason;
}


my $RE_SJIS_C = '[\201-\237\340-\374][\100-\176\200-\374]';
my $RE_SJIS_S = "($RE_SJIS_C)+";
my $RE_EUC_C  = '[\241-\376][\241-\376]';
my $RE_EUC_S  = "($RE_EUC_C)+";
my $RE_JIN    = '\033\$[\@B]';
my $RE_JOUT   = '\033\([BJ]';

my @REGEXP = (
	      $RE_SJIS_C,
	      $RE_SJIS_S,
	      $RE_EUC_C,
	      $RE_EUC_S,
	      $RE_JIN,
	      $RE_JOUT,
	      );

sub look_japanese
{
    my ($self, $buf) = @_;

    for my $regexp (@REGEXP) {
	return 1 if $buf =~ /$regexp/;
    }

    0;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::Bounce appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
