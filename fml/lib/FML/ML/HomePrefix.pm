#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HomePrefix.pm,v 1.4 2004/04/23 04:10:34 fukachan Exp $
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

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: standard constructor.
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


# Descriptions: add { $domian => $dir } map to $fml_primary_ml_home_prefix_map.
#    Arguments: OBJ($self) STR($domain) STR($dir)
# Side Effects: update $fml_primary_ml_home_prefix_map
# Return Value: none
sub add
{
    my ($self, $domain, $dir) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->{ credential };
    my $pri_map = $self->primary_map();

    $self->_sanity_check();

    # ml_home_prefix map
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

    # check the directory.
    if (-d $dir) {
	$curproc->logwarn("$dir already exist. reuse it.");
    }
    else {
	$curproc->mkdir($dir);

	if (-d $dir) {
	    $curproc->log("$dir created");
	}
	else {
	    $curproc->logerror("fail to mkdir $dir");
	    croak("fail to mkdir $dir");
	}
    }
}


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

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::ML::HomePrefix first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
