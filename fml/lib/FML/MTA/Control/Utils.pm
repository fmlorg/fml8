#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.3 2004/01/23 09:17:37 fukachan Exp $
#

package FML::MTA::Control::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTA::Control::Utils - utility functions.

=head1 SYNOPSIS

=head1 DESCRIPTION

utility functions for MTA control library.

=head1 METHODS

=head2 is_user_entry_exist_in_passwd($user)

check if $user is found in /etc/passwd ?
return 1 if found, and 0 if not.

=cut


# Descriptions: check if $user is found in /etc/passwd ?
#    Arguments: OBJ($self) STR($user)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_user_entry_exist_in_passwd
{
    my ($self, $user) = @_;
    my $found = 0;

    if (-f "/etc/passwd") {
	use FileHandle;
	my $fh = new FileHandle "/etc/passwd";
	if (defined $fh) {
	    my ($x_user, $buf);
	    while ($buf = <$fh>) {
		($x_user) = split(/:/, $buf);
		if ($user eq $x_user) {
		    $found = 1;
		}
	    }
	    $fh->close();
	}
    }

    return $found;
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

FML::MTA::Control::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
