#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: newml.pm,v 1.4 2001/12/09 12:52:24 fukachan Exp $
#

package FML::Command::Admin::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::Admin::newml - make a new mailing list

=head1 SYNOPSIS

    use FML::Command::Admin::newml;
    $obj = new FML::Command::Admin::newml;
    $obj->newml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config         = $curproc->{ 'config' };
    my $main_cf        = $curproc->{ 'main_cf' };
    my $member_map     = $config->{ 'primary_member_map' };
    my $recipient_map  = $config->{ 'primary_recipient_map' };
    my $ml_name        = $command_args->{ 'ml_name' };
    my $ml_home_prefix = $main_cf->{ 'ml_home_prefix' };
    my $ml_home_dir    = "$ml_home_prefix/$ml_name";
    my $params         = {
	ml_name           => $ml_name,
	ml_domain         => $main_cf->{ 'default_domain' },
	executable_prefix => $main_cf->{ executable_prefix },
	ml_home_prefix    => $ml_home_prefix,
    };

    # fundamental check
    croak("\$ml_name is not specified")    unless $ml_name;

    unless (-d $ml_home_dir) {
	eval q{ 
	    use File::Utils qw(mkdirhier);
	    use File::Spec;
	};
	croak($@) if $@;

	mkdirhier( $ml_home_dir, $config->{ default_dir_mode } || 0755 );

	my $default_config_dir = $main_cf->{ 'default_config_dir' };

	for my $file (qw(config.cf include include-ctl)) {
	    my $src = File::Spec->catfile($default_config_dir, $file);
	    my $dst = File::Spec->catfile($ml_home_dir, $file);

	    print STDERR "installing $dst\n";
	    _install($src, $dst, $params);
	}
    }
    else {
	warn("$ml_name already exists");
    }
}


sub _install
{
    my ($src, $dst, $config) = @_;

    eval q{ 
	use FileHandle;
	use FML::Config::Convert;
    };
    croak($@) if $@;

    my $in  = new FileHandle $src;
    my $out = new FileHandle "> $dst.$$";

    if (defined $in && defined $out) {
	&FML::Config::Convert::convert($in, $out, $config);

	$out->close();
	$in->close();

	rename("$dst.$$", $dst) || croak("fail to rename $dst");
    }
    else {
	croak("fail to open $src") unless defined $in;
	croak("fail to open $dst") unless defined $out;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::Admin::newml appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
