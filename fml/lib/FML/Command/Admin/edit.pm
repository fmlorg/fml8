#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package FML::Command::Admin::edit;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::edit - edit config.cf (not yet implemented).

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Tool to edit config.cf.

     NOT IMPLEMENTED.

=head1 METHODS

=head2 process($curproc, $command_args)

C<TODO>:
now we can read and write config.cf, but can not change it.

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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: run "vi" or the specified editor to edit config.cf.
#               If environmental variable EDITOR is specified,
#               try to run "$EDITOR config.cf".
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update config.cf
#               change $ENV{ PATH } withiin running editor.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();
    my $config_cf = $curproc->config_cf_filepath($ml_name, $ml_domain);
    my $editor    = $ENV{ 'EDITOR' } || 'vi';
    my $orig_path = $ENV{ 'PATH' };

    if (-f $config_cf) {
	$ENV{'PATH'} = '/bin:/usr/bin:/usr/pkg/bin:/usr/local/bin';
	$curproc->ui_message("$editor $config_cf");
	system $editor, $config_cf;
	$ENV{'PATH'} = $orig_path;
    }
    else {
	my $r = "$config_cf not found";
	$curproc->ui_message("error: $r");
	croak($r);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::edit first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
