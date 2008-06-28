#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2007,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HomePrefix.pm,v 1.10 2007/01/16 11:39:32 fukachan Exp $
#

package FML::ML::HomePrefix;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $debug);
use Carp;
use File::Spec;
use FML::Credential;
use FML::Restriction::Base;
use IO::Adapter;

# disable debug by default.
$debug = 0;


=head1 NAME

FML::ML::HomePrefix - create, rename and delete ml_home_prefix dir.

=head1 SYNOPSIS

use FML::ML::HomePrefix;
my $ml_home_prefix = new FML::ML::HomePrefix $curproc;
$ml_home_prefix->add($domain);
$ml_home_prefix->delete($domain);

=head1 DESCRIPTION

This class provides functions to create, rename and delete
ml_home_prefix directory information.
Mainly it is used to edit ml_home_prefix configuration file.

=head1 METHODS

=head2 new($curproc)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 primary_map()

return the primary ml_home_prefix_map.

=cut


# Descriptions: return the primary ml_home_prefix_map.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub primary_map
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $debug > 100 ? $curproc->{ config } : $curproc->config();

    return $config->{ fml_primary_ml_home_prefix_map } || '';
}


# Descriptions: cheap sanity check.
#    Arguments: OBJ($self)
# Side Effects: long jump by croak() if needed.
# Return Value: none
sub _sanity_check
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $map     = $self->primary_map();
    my $error   = '';

    if ($map) {
	unless (-f $map) {
	    use IO::Adapter;
	    my $obj = new IO::Adapter $map;
	    $obj->touch();
	}

	unless (-w $map) {
	    $error = "\$primary_ml_home_prefix_map not writable";
	}
    }
    else {
	$error = "\$primary_ml_home_prefix_map undefined";
    }

    if ($error) {
	$curproc->logerror($error);
	croak($error);
    }
}


=head2 add($domain, $dir)

add domain into $fml_primary_ml_home_prefix_map.

=cut


# Descriptions: add { $domian => $dir } map to $fml_primary_ml_home_prefix_map.
#    Arguments: OBJ($self) STR($domain) STR($dir)
# Side Effects: update $fml_primary_ml_home_prefix_map map.
# Return Value: none
sub add
{
    my ($self, $domain, $dir) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->credential();
    my $pri_map = $self->primary_map();

    $self->_sanity_check();

    # 1. add domain into ml_home_prefix map.
    use IO::Adapter;
    my $obj = new IO::Adapter $pri_map;
    $obj->touch();

    my $_domain   = quotemeta($domain);
    my ($domlist) = $obj->find($_domain, { all => 1 });
    if (@$domlist) {
	my $found = 0;
	for my $_dom (@$domlist) {
	    my ($_domain) = split(/\s+/, $_dom);
	    $found = 1 if $cred->is_same_domain($_domain, $domain);
	}

	if ($found) {
	    my $error = "already defined domain: $domain";
	    $curproc->logerror($error);
	    croak($error);
	}
	else {
	    $obj->add($domain, [ $dir ]);
	}
    }
    else {
	$obj->add($domain, [ $dir ]);
    }

    $obj->close();

    # change onwer and group of the created directory.
    if ($< == 0) {  # we can do this only when running as user "root".
	my $owner = $curproc->fml_owner();
	my $group = $curproc->fml_group();
	$curproc->chown($owner, $group, $pri_map);
    }

    # 2. reuse or create the domain prefix directory.
    # 2.1 check the directory.
    if (-d $dir) {
	$curproc->logwarn("$dir already exist. reuse it.");
    }
    else {
	# XXX proper mode ?
	$curproc->mkdir($dir);

	if (-d $dir) {
	    $curproc->log("$dir created");

	    # change onwer and group of the created directory.
	    if ($< == 0) {  # we can do this only when running as user "root".
		my $owner = $curproc->fml_owner();
		my $group = $curproc->fml_group();
		$curproc->chown($owner, $group, $dir);
	    }
	}
	else {
	    $curproc->logerror("fail to mkdir $dir");
	    croak("fail to mkdir $dir");
	}
    }
}


=head2 delete($domain)

delete the specified domain from $fml_primary_ml_home_prefix_map.

=cut


# Descriptions: delete { $domian => $dir } map
#               from $fml_primary_ml_home_prefix_map.
#    Arguments: OBJ($self) STR($domain)
# Side Effects: update $fml_primary_ml_home_prefix_map
# Return Value: none
sub delete
{
    my ($self, $domain) = @_;
    my $curproc = $self->{ _curproc };
    my $pri_map = $self->primary_map();

    $self->_sanity_check();

    # directory info
    my $dir = $curproc->ml_home_prefix($domain);
    if ($dir) {
	if (-d $dir) {
	    $curproc->log("$dir left as itself");
	}
	else {
	    $curproc->log("$dir no longer exist");
	}
    }
    else {
	$curproc->logerror("ml_home_prefix not found");
	$curproc->logerror("no such domain: $domain");
    }

    # remove hash entry.
    my $obj = new IO::Adapter $pri_map;
    $obj->open();
    $obj->delete($domain);
    $obj->close();

    # change onwer and group of the created directory.
    if ($< == 0) {  # we can do this only when running as user "root".
	my $owner = $curproc->fml_owner();
	my $group = $curproc->fml_group();
	$curproc->chown($owner, $group, $pri_map);
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $domain  = "nuinui.net";
    my $prefix  = "/tmp/nuinui.net";
    my $map     = "/etc/fml/ml_home_prefix";

    use FML::Process::Debug;
    my $curproc = new FML::Process::Debug;
    $curproc->{ config } = { fml_primary_ml_home_prefix_map => $map };

    # special debug flag on
    $debug = 101;
    $|     = 1;

    my $ml_home_prefix = new FML::ML::HomePrefix $curproc;

    print "\n# add { $domain => $prefix }\n";
    $ml_home_prefix->add($domain, $prefix);
    system "cat $map";

    print "\n# delete { $domain => $prefix }\n";
    $ml_home_prefix->delete($domain);
    system "cat $map";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2007,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::ML::HomePrefix first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
