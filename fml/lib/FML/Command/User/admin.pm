#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: admin.pm,v 1.2 2003/02/09 12:31:42 fukachan Exp $
#

package FML::Command::User::admin;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


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


# Descriptions: rewrite command prompt.
#               Always we need to rewrite command prompt to hide password.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR_REF($rbuf)
# Side Effects: rewrite buffer to hide the password phrase in $rbuf.
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_args, $rbuf) = @_;

    # XXX-TODO: good style? FML::Command::Admin::password->rewrite_prompt() ?
    use FML::Command::Admin::password;
    my $obj = new FML::Command::Admin::password;
    $obj->rewrite_prompt($curproc, $command_args, $rbuf);
}


# XXX-TODO: process() is not implementd. correct ?


=head1 NAME

FML::Command::User::admin - dummy.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

In fact, this module is dummy but provide utility for the case auth
fail. It rewrites buffer to hide the password phrase in command
prompt.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::add first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
