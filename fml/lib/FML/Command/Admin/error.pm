#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: error.pm,v 1.2 2003/03/14 06:53:22 fukachan Exp $
#

package FML::Command::Admin::error;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::error - show error status

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change delivery mode from real time to digest.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: constructor.
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


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: change delivery mode from real time to digest.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->_fmlerror($curproc);
}


# Descriptions: show error messages
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fmlerror
{
    my ($self, $curproc) = @_;
    my $config = $curproc->config();

    use FML::Error;
    my $obj  = new FML::Error $curproc;
    my $data = $obj->analyze();
    my $info = $obj->get_data_detail();

    my ($k, $v);
    while (($k, $v) = each %$info) {
	if (defined($v) && ref($v) eq 'ARRAY') {
	    my $x = '';
	    for my $y (@$v) {
		$x .= $y if defined $y;
		$x .= " ";
	    }
	    print "$k => ( $x)\n";
	}
	else {
	    print "$k => $v\n";
	}
    }
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

FML::Command::Admin::error first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
