#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newdomain.pm,v 1.1 2003/11/15 03:09:44 fukachan Exp $
#

package FML::Command::Admin::newdomain;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::newdomain - declare a new domain we use

=head1 SYNOPSIS

See C<FML::Command> for more detainewdomain.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::dir>.

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: not need lock in the first time
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: declare a new domain we use
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options = $command_args->{ options };
    my $domain  = $options->[ 0 ];
    my $prefix  = $options->[ 1 ];

    use FML::HomeDir::Prefix;
    my $ml_home_prefix = new FML::HomeDir::Prefix $curproc;
    $ml_home_prefix->add($domain, $prefix);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::newdomain first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more detainewdomain.

=cut


1;
