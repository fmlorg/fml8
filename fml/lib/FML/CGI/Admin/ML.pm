#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ML.pm,v 1.3 2002/06/24 11:06:11 fukachan Exp $
#

package FML::CGI::Admin::ML;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

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


# Descriptions: show menu for subscribe/unsubscribe commands
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($args)
#               HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $config       = $curproc->{ config };
    my $action       = $curproc->myname();
    my $ml_domain    = $curproc->ml_domain();
    my $ml_list      = $curproc->get_ml_list($args, $ml_domain);
    my $address      = $curproc->safe_param_address() || '';
    my $target       = '_top';
    my $comname      = $command_args->{ comname };
    my $command_list = [ 'newml', 'rmml' ];

    print start_form(-action=>$action, -target=>$target);

    if ($comname eq 'newml') {
	print table( { -border => undef },
		    Tr( undef,
		       td([
			   "ML:",
			   textfield(-name      => 'ml_name_specified',
				     -default   => '',
				     -override  => 1,
				     -size      => 32,
				     -maxlength => 64,
				     )
			   ])
		       ),
		    Tr( undef,
		       td([
			   "command: ",
			   textfield(-name    => 'command',
				     -default => $comname,
				     -size    => 32)
			   ])
		       ),
		    );

    }
    elsif ($comname eq 'rmml') {
	print table( { -border => undef },
		    Tr( undef,
		       td([
			   "ML: ",
			   scrolling_list(-name   => 'ml_name',
					  -values => $ml_list,
					  -size   => 5)
			   ])
		       ),
		    Tr( undef,
		       td([
			   "",
			   textfield(-name      => 'ml_name_specified',
				     -default   => '',
				     -override  => 1,
				     -size      => 32,
				     -maxlength => 64,
				     )
			   ])
		       ),
		    Tr( undef,
		       td([
			   "command: ",
			   textfield(-name    => 'command',
				     -default => $comname,
				     -size    => 32)
			   ])
		       ),
		    );
    }
    else {
	croak("Admin::ML::cgi_menu: unknown command");
    }

    print submit(-name => 'submit');
    print reset(-name  => 'reset');
    print end_form;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Admin::ML appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
