#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: List.pm,v 1.8 2003/02/16 08:52:44 fukachan Exp $
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
    my $action      = $curproc->safe_cgi_action_name();
    my $target      = '_top';
    my $ml_name     = $command_args->{ ml_name };
    my $config      = $curproc->config();
    my $map_list    = $config->get_as_array_ref('cgi_menu_map_list');
    my $_defaultmap = $config->{ cgi_menu_default_map };
    my $map_default = $curproc->safe_param_map() || $_defaultmap;

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

FML::CGI::Admin::List first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
