#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newml.pm,v 1.15 2002/02/18 14:24:12 fukachan Exp $
#

package FML::Command::Admin::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::newml - set up a new mailing list

=head1 SYNOPSIS

    use FML::Command::Admin::newml;
    $obj = new FML::Command::Admin::newml;
    $obj->newml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up a new mailing list
create mailing list directory,
install config.cf, include, include-ctl et. al.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


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


# Descriptions: not need lock in the first time
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: set up a new mailing list
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config         = $curproc->{ 'config' };
    my ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir) =
	$self->_get_domain_info($curproc, $command_args);
    my $params         = {
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,
    };

    # fundamental check
    croak("\$ml_name is not specified") unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;

    unless (-d $ml_home_dir) {
	eval q{
	    use File::Utils qw(mkdirhier);
	    use File::Spec;
	};
	croak($@) if $@;

	mkdirhier( $ml_home_dir, $config->{ default_dir_mode } || 0755 );

	my $template_dir = $curproc->template_files_dir_for_newml();
	for my $file (qw(config.cf include include-ctl)) {
	    my $src = File::Spec->catfile($template_dir, $file);
	    my $dst = File::Spec->catfile($ml_home_dir, $file);

	    print STDERR "installing $dst\n";
	    _install($src, $dst, $params);
	}
    }
    else {
	warn("$ml_name already exists");
    }
}


# Descriptions: check argument and prepare virtual domain information
#               if needed.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: ARRAY
sub _get_domain_info
{
    my ($self, $curproc, $command_args) = @_;
    my $ml_name        = $command_args->{ 'ml_name' };
    my $ml_domain      = $curproc->default_domain();
    my $ml_home_prefix = '';
    my $ml_home_dir    = '';

    # virtual domain support e.g. "makefml newml elena@nuinui.net"
    if ($ml_name =~ /\@/o) {
	# overwrite $ml_name
	($ml_name, $ml_domain) = split(/\@/, $ml_name);
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }
    # default domain: e.g. "makefml newml elena"
    else {
	$ml_home_prefix = $curproc->ml_home_prefix();
    }

    eval q{ use File::Spec;};
    $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);

    return ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir);
}


# Descriptions: install $dst with variable expansion of $src
#    Arguments: STR($src) STR($dst) HASH_REF($config)
# Side Effects: create $dst
# Return Value: none
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
	chmod 0644, "$dst.$$";

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

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::newml appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
