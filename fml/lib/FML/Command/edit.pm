#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: edit.pm,v 1.2 2001/07/15 08:14:45 fukachan Exp $
#

package FML::Command::edit;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::edit - edit a new member

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 C<edit( $address )>

=cut


sub edit
{
    my ($self, $curproc, $args) = @_;
    my $config        = $curproc->{ config };
    my $options       = $args->{ options };
    my $address       = $args->{ address } || $options->[ 0 ];
    my $myname        = $args->{ args }->{ myname };

    # ML's home directory
    my $ml_home_dir   = $args->{ 'args' }->{ 'ml_home_dir' };
    my $config_cf     = $ml_home_dir."/config.cf";

    use FML::Config;
    my $c = new FML::Config;

    $c->read( $config_cf );

    # replace/ovewrite $config_cf
    # old $config_cf is backup'ed to $config_cf.bak
    $c->write( $config_cf );
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::edit appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
