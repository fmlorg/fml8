#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: list.pm,v 1.26 2004/06/26 11:42:22 fukachan Exp $
#

package FML::Command::Admin::list;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::list - show the content of specified map(s).

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show user list(s).

=cut


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


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: show the specified map(s).
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $options   = [];
    my $x_options = $command_context->get_options() || [];

    # import makefml options
    if (defined $x_options && ref($x_options) eq 'ARRAY') {
	if (@$x_options) { $options = $x_options;}
    }

    $self->_show_list($curproc, $command_context, $options);
}


# Descriptions: show content of the specified map(s).
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
#               HASH_ARRAY($options)
# Side Effects: none
# Return Value: none
sub _show_list
{
    my ($self, $curproc, $command_context, $options) = @_;
    my $config  = $curproc->config();
    my $maplist = $config->get_as_array_ref('list_command_default_maps');

    # XXX first match is ok ?
  ARGV:
    for my $option (@$options) {
	my $list = $self->_get_map_candidates_as_array_ref($option);

      KEY:
	for my $key (@$list) {
	    if (defined $config->{ $key } && $config->{ $key }) {
		$maplist = $config->get_as_array_ref( $key );
		last ARGV;
	    }
	}
    }

    # cheap sanity
    unless (defined $maplist) { croak("list: map undefined");}
    unless (@$maplist)        { croak("list: map unspecified");}

    # $uc_args  = FML::User::Control specific parameters
    my $uc_args = {
	maplist => $maplist,
	wh      => \*STDOUT,
    };
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->print_userlist($curproc, $command_context, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: generate map name list with $key word.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_map_candidates_as_array_ref
{
    my ($self, $key) = @_;
    my (@list) = (sprintf("%s_maps", $key),
		  sprintf("primary_%s_map", $key),
		  sprintf("fml_%s_maps", $key));

    if ($key =~ /maps$/ || $key =~ /^primary_\S+_map$/) {
	unshift(@list, $key);
    }

    return \@list;
}


# Descriptions: show cgi menu for list command.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';

    # navigation bar
    eval q{
	use FML::CGI::List;
	my $obj = new FML::CGI::List;
	$obj->cgi_menu($curproc, $command_context);
    };
    if ($r = $@) {
	print $r;
	croak($r);
    }

    print "<hr>\n";

    # the default map is defined in _show_list().
    # so, we set null string by default.
    my $map_default = $curproc->safe_param_map() || '';
    my $options     = [ $map_default ];
    eval q{
	$self->_show_list($curproc, $command_context, $options);
    };
    if ($r = $@) {
	print $r;
	croak($r);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::list first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more detailist.

=cut


1;
