#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Bounce.pm,v 1.2 2001/04/10 14:37:49 fukachan Exp $
#

package Mail::Bounce;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

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

    for my $pkg (
		 'DSN', 
		 'Postfix19991231', 
		 'Qmail', 
		 'Exim',
		 'SimpleMatch', 
		 ) {
	my $module = "Mail::Bounce::$pkg";
	eval qq { 
	    require $module; $module->import();
	    $module->analyze( \$msg , \$result );
	};
	croak($@) if $@;
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
