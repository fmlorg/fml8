#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: list.pm,v 1.19 2003/11/26 09:19:10 fukachan Exp $
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
    my $options = [];

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
    my $config  = $curproc->config();
    my $maplist = $config->get_as_array_ref( 'list_command_default_maps');

    # XXX first match is ok ?
  ARGV:
    for my $option (@$options) {
	my $list = $self->_gen_key_list($option);

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
    unless ($maplist)         { croak("list: map unspecified");}

    # FML::User::Control specific parameters
    my $uc_args = {
	maplist => $maplist,
	wh      => \*STDOUT,
	is_cgi  => $command_args->{ is_cgi },
    };
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->print_userlist($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: generate keyword list
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: ARRAY_REF
sub _gen_key_list
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
    my $ml_name     = $curproc->cgi_var_ml_name($args);
    my $r           = '';

    # declare CGI mode now.
    $command_args->{ is_cgi } = 1;

    # navigation bar
      eval q{
	use FML::CGI::List;
	my $obj = new FML::CGI::List;
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
