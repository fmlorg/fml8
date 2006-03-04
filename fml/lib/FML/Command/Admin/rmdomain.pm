#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: rmdomain.pm,v 1.7 2004/07/26 01:10:54 fukachan Exp $
#

package FML::Command::Admin::rmdomain;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::rmdomain - declare discarding this domain.

=head1 SYNOPSIS

See C<FML::Command> for more detairmdomain.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::dir>.

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


# Descriptions: not need lock in the first time.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: declare discarding this domain.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $canon_argv = $command_context->{ canon_argv };
    my $domain     = $canon_argv->{ ml_name };

    if ($domain) {
	use FML::ML::HomePrefix;
	my $ml_home_prefix = new FML::ML::HomePrefix $curproc;
	$ml_home_prefix->delete($domain);
    }
    else {
	my $error = 'no argument';
	$curproc->logerror($error);
	croak($error);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::rmdomain first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more detairmdomain.

=cut


1;
