#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: List.pm,v 1.3 2003/09/27 04:06:53 fukachan Exp $
#

package FML::CGI::List;
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
    my $target      = $curproc->cgi_var_frame_target();
    my $action      = $curproc->cgi_var_action();
    my $map_default = $curproc->cgi_var_address_map();
    my $map_list    = $curproc->cgi_var_address_map_list();
    my $ml_name     = $command_args->{ ml_name };

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('ml_name', $ml_name)) {
	croak("invalid ml_name");
    }

    # check $map_default included in $map_list.
    unless ($config->has_attribute("cgi_menu_map_list", $map_default)) {
	croak("invalid map: $map_default");
    }

    print start_form(-action=>$action, -target=>$target);
    print hidden(-name => 'command', -default => 'list');
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
    print reset(-name  => 'reset');
    print end_form;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::List first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
