#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Obsolete.pm,v 1.5 2004/01/02 16:08:39 fukachan Exp $
#

package FML::Process::Obsolete;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::Obsolete - show obsolete message (for obsolete module).

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

constructor. run help as soon as possible.

=head2 help($args)

show "this module is obsolete.".

=cut


# Descriptions: constructor.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub new
{
    my ($curproc, $args) = @_;

    $curproc->help();
}


# Descriptions: show message "this command is obsolete".
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub help
{
    my ($curproc, $args) = @_;

    # XXX $curproc->myname() is not used since $curproc is not initialized.
    use File::Basename;
    my $myname = basename($0);

    # XXX valid use of STDERR
    print STDERR "\nWARNING: $myname command is obsolete.\n\n";

    exit(0);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Obsolete appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
