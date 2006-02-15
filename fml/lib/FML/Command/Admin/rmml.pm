#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: rmml.pm,v 1.28 2006/02/04 08:10:08 fukachan Exp $
#

package FML::Command::Admin::rmml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::rmml - remove the specified mailing list.

=head1 SYNOPSIS

    use FML::Command::Admin::rmml;
    $obj = new FML::Command::Admin::rmml;
    $obj->rmml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

remove the mailing list directory (precisely speaking,
we just rename ml -> @ml.$date)
and the corresponding alias entries.

=head1 METHODS

=head2 process($curproc, $command_args)

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


# Descriptions: not need lock in the first time.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: remove the specified mailing list.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: remove mailing list directory and the corresponding
#               alias entries.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options        = $curproc->command_line_options();
    my $config         = $curproc->config();
    my $ml_name        = $command_args->{ ml_name };
    my $ml_domain      = $command_args->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $params         = {
	fml_owner         => $curproc->fml_owner(),
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,
    };

    # fundamental sanity check
    croak("\$ml_name is not specified")     unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;

    # XXX-TODO: WHY? (update $ml_home_prefix and expand variables again.)
    # update $ml_home_prefix and expand variables again.
    $config->set( 'ml_home_prefix' , $ml_home_prefix );

    # check if $ml_name exists.
    unless (-d $ml_home_dir) {
	my $s = "no such ml_home_dir ($ml_home_dir) for $ml_name\@$ml_domain";
	$curproc->ui_message($s);
	$curproc->logwarn($s);
	return;
    }

    # o.k. here we go!
    use FML::ML::Control;
    my $ml = new FML::ML::Control;
    $ml->delete_ml_home_dir($curproc, $command_args, $params);
    $ml->delete_aliases($curproc, $command_args, $params);
}


# Descriptions: show cgi menu for rmml command.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create home directories, update aliases, ...
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_args) = @_;
    my $r = '';

    # XXX-TODO: $commnad_args checked ?
    eval q{
        use FML::CGI::ML;
        my $obj = new FML::CGI::ML;
        $obj->cgi_menu($curproc, $command_args);
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

Copyright (C) 2001,2002,2003,2004,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::rmml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
