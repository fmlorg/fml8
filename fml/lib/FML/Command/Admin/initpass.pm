#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package FML::Command::Admin::initpass;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::changepassword;
@ISA = qw(FML::Command::Admin::changepassword);


# Descriptions: initialize admin password of a new user.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to password module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options = $command_args->{ options };

    if ($options->[ 2 ]) {
	croak("wrong arguments");
    }
    elsif ($options->[ 1 ] && $options->[ 0 ]) {
	# [0] = username
	# [1] = password(plaintext)
	$self->SUPER::process($curproc, $command_args);
    }
    else {
	croak("wrong arguments");
    }
}


=head1 NAME

FML::Command::Admin::initpass - initialize admin password (fml4 compatible)

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::changepassword>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::initpass
first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
