#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: list.pm,v 1.12 2003/01/26 03:14:17 fukachan Exp $
#

package FML::Command::Admin::list;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::list - show user list(s)

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


# Descriptions: show the address list.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options = [ 'member' ];

    # import makefml options
    if (defined $command_args->{ options } &&
	ref($command_args->{ options }) eq 'ARRAY') {
	my $xopt = $command_args->{ options };
	if (@$xopt) { $options = $xopt;}
    }

    $command_args->{ is_cgi } = 0;
    $self->_show_list($curproc, $command_args, $options);
}


# Descriptions: show the address list.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
#               HASH_ARRAY($options)
# Side Effects: none
# Return Value: none
sub _show_list
{
    my ($self, $curproc, $command_args, $options) = @_;
    my $config  = $curproc->{ config };
    my $maplist = undef;

    for my $option (@$options) {
	if ($option =~ /^recipient|active/i) {
	    $maplist = $config->get_as_array_ref( 'recipient_maps' );
	}
	elsif ($option =~ /^member/i) {
	    $maplist = $config->get_as_array_ref( 'member_maps' );
	}
	elsif ($option =~ /^adminmember|^admin_member/i) {
	    $maplist = $config->get_as_array_ref( 'admin_member_maps' );
	}
	else {
	    LogWarn("list: unknown type $option");
	}
    }

    # cheap sanity
    unless (defined $maplist) { croak("list: map undefined");}
    unless ($maplist)         { croak("list: map unspecified");}

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	maplist => $maplist,
	wh      => \*STDOUT,
	is_cgi  => $command_args->{ is_cgi },
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->userlist($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $map_default = $curproc->safe_param_map() || 'member';
    my $options     = [ $map_default ];
    my $ml_name     = $curproc->cgi_try_get_ml_name($args);
    my $r           = '';

    # declare CGI mode now.
    $command_args->{ is_cgi } = 1;

    # navigation bar
      eval q{
	use FML::CGI::Admin::List;
	my $obj = new FML::CGI::Admin::List;
	$obj->cgi_menu($curproc, $args, $command_args);
    };
    if ($r = $@) {
	print $r;
	croak($r);
    }

    print "<hr>\n";

    eval q{
	$self->_show_list($curproc, $command_args, $options);
    };
    if ($r = $@) {
	croak($r);
    }
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

FML::Command::Admin::list first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more detailist.

=cut


1;
