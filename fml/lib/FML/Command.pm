#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Command - dispacher of fml commands

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


sub DESTROY { ;}


sub AUTOLOAD
{
    my ($self, $curproc, $args) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my $command = $AUTOLOAD;
    $command =~ s/.*:://;

    my $pkg = "FML::Command::${command}";

    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	if ($pkg->can($command)) {
	    $pkg->$command($curproc, $args);
	}
	else {
	    Log("$pkg module has no $command method");	    
	}
    }
    else {
	Log("$pkg module is not found");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
