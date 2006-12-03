#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newdomain.pm,v 1.10 2006/03/05 08:08:36 fukachan Exp $
#

package FML::Command::Admin::newdomain;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::newdomain - declare a new domain we use.

=head1 SYNOPSIS

See C<FML::Command> for more detail of newdomain operation.

=head1 DESCRIPTION

declare a new domain we use.

=head2 new()

constructor.

=head2 need_lock()

not need lock in the first time.

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


=head2 process($curproc, $command_context)

declare a new domain we use.
It adds domain to ml_home_prefix configuration file.

=cut


# Descriptions: declare a new domain we use.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $canon_argv = $command_context->get_canon_argv();
    my $domain     = $canon_argv->{ ml_name }        || '';
    my $prefix     = $canon_argv->{ options }->[ 0 ] || '';
    my $error      = '';

    if ($domain && $prefix) {
	use FML::ML::HomePrefix;
	my $ml_home_prefix = new FML::ML::HomePrefix $curproc;
	$ml_home_prefix->add($domain, $prefix);
    }
    elsif ($domain && (! $prefix)) {
	$error = "ml_home_prefix unspecified";
    }
    elsif ((! $domain) && $prefix) {
	$error = "domain unspecified";
    }
    else {
	$error = "no argument";
    }

    if ($error) {
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

FML::Command::Admin::newdomain first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more detainewdomain.

=cut


1;
