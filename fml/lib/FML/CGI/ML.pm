#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ML.pm,v 1.7 2004/01/02 14:50:29 fukachan Exp $
#

package FML::CGI::ML;
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


# Descriptions: show menu for subscribe/unsubscribe commands
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_args) = @_;
    my $target       = $curproc->cgi_var_frame_target();
    my $action       = $curproc->cgi_var_action();
    my $ml_domain    = $curproc->cgi_var_ml_domain();
    my $ml_list      = $curproc->cgi_var_ml_name_list();
    my $address      = $curproc->safe_param_address() || '';
    my $comname      = $command_args->{ comname };
    my $command_list = [ 'newml', 'rmml' ];

    # XXX-TODO: who verified comname ?

    unless ($curproc->cgi_var_cgi_mode() eq "admin") {
	# XXX-TODO: nl ?
	croak("Admin::ML::cgi_menu: prohibited in this mode");
    }

    print start_form(-action=>$action, -target=>$target);
    print $curproc->cgi_hidden_info_language();

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
	# XXX-TODO: nl ?
	croak("Admin::ML::cgi_menu: unknown command");
    }

    print submit(-name => 'submit');
    print reset(-name  => 'reset');
    print end_form;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::ML first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
