#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: List.pm,v 1.5 2002/09/22 14:56:42 fukachan Exp $
#

package FML::CGI::Admin::List;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines


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


# Descriptions: show address list
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($args)
#               HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $action       = $curproc->myname();
    my $target       = '_top';
    my $ml_name      = $command_args->{ ml_name };
    my $map_list     = [ 'member', 'recipient', 'admin_member' ];
    my $map_default  = $curproc->safe_param_map() || 'member';

    # XXX-TODO: we can validate $action ?
    # create <FORM ... > ... by (start_form() ... end_form())
    print start_form(-action=>$action, -target=>$target);

    print hidden(-name => 'command', -default => 'list');

    # XXX-TODO: we should validate $ml_name by safe regexp ?
    # XXX-TODO: check $map_default included in $map_list.
    print table( { -border => undef },
		Tr( undef,
		   td([
		       "ML:",
		       textfield(-name    => 'ml_name',
				 -default => $ml_name),
		       ])
		   ),
		Tr( undef,
		   td([
		       "map",
		       scrolling_list(-name    => 'map',
				      -values  => $map_list,
				      -default => $map_default,
				      -size    => $#$map_list + 1)
		       ]),
		   )
		);


    print submit(-name => 'show');
    print end_form;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Admin::List first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
