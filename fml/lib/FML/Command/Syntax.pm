#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.8 2004/01/01 07:29:27 fukachan Exp $
#

package FML::Command::Syntax;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::Syntax - shared command syntax checker

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 check_syntax_address_handler($curproc, $command_args)

verify the syntax command string.
return 0 if it looks insecure.

=cut


# Descriptions: verify the syntax command string.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub check_syntax_address_handler
{
    my ($self, $curproc, $command_args) = @_;
    my $comname    = $command_args->{ comname }    || '';
    my $comsubname = $command_args->{ comsubname } || '';
    my $options    = $command_args->{ options }    || [];
    my @test       = ($comname);
    my $ok         = 0;

    # XXX Let original_command be "admin subscribe ADDRESS".
    # XXX options = [ 'subscribe', ADDRESS ] (not shifted yet here).
    my $command = $options->[ 0 ] || '';
    my $address = $options->[ 1 ] || '';
    push(@test, $command);

    # 1. check address syntax
    if ($address) {
	use FML::Restriction::Base;
	my $dispatch = new FML::Restriction::Base;
	if ($dispatch->regexp_match('address', $address)) {
	    $ok++;
	}
	else {
	    $curproc->logerror("insecure address: <$address>");
	}
    }

    # 2. check other comonents
    use FML::Command;
    my $dispatch = new FML::Command;
    if ($dispatch->safe_regexp_match($curproc, $command_args, \@test)) {
	$ok++;
    }
    else {
	$curproc->logerror("insecure syntax");
    }

    return( $ok == 2 ? 1 : 0 );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Syntax appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
