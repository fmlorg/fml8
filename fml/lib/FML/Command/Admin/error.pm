#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: error.pm,v 1.8 2003/08/23 04:35:31 fukachan Exp $
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

show error status.

=head1 METHODS

=head2 process($curproc, $command_args)

call error status list generator.

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


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return undef;}


# Descriptions: list up status of error messages
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    # XXX-TODO: fml $ml error --algorithm $algorithm ?
    $self->_fmlerror($curproc);
}


# Descriptions: show error messages
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fmlerror
{
    my ($self, $curproc) = @_;
    my $config = $curproc->config();
    my $list   = $config->get_as_array_ref('error_analyzer_function_list');

    use FML::Error;
    my $error = new FML::Error $curproc;

    for my $fp (@$list) {
	print "# analyzer function = $fp\n";
	$error->set_analyzer_function($fp);
	$error->analyze();
	$error->print();
	print "\n";
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
