#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.5 2002/01/18 15:37:38 fukachan Exp $
#

package FML::ErrorAnalyze;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::ErrorAnalyze - manipulate error/bounce infomation

=head1 SYNOPSIS

	use FML::ErrorAnalyze;
	my $error = new FML::ErrorAnalyze $curproc;
	$error->cache_on( $bounce_info );

where C<$bounce_info) follows:

    $bounce_info = [ { address => 'rudo@nuinui.net',
		       status  => '5.x.y',
		       reason  => '... reason ... ',
		   }
    ];
    
=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


# Descriptions: 
#    Arguments: OBJ($self) HASH_REF($curproc)
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: save bounce info into cache.
#    Arguments: OBJ($self) ARRAY_REF($info)
# Side Effects: update cache
# Return Value: none
sub cache_on
{
    my ($self, $info) = @_;
    my $io = $self->_open_cache();

    if (defined $io) {
	my ($address, $reason, $status);
	my $time = time;

	for my $hint (@$info) {
	    $address = $hint->{ address }; 
	    $reason  = $hint->{ reason }; 
	    $status  = $hint->{ status }; 

	    $io->set($address, "$time status=$status");
	}

	$self->_close_cache();
    }
}


# Descriptions: check cache and determine bounced or not
#               apply deluser() for addressed looked as bounced
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: delete addresses
# Return Value: none
sub is_bounced
{
    my ($self) = @_;

    my $io = $self->_open_cache();

    if (defined $io) {
	$self->_close_cache();
    }

    return 0;
}


# Descriptions: open the cache dir for File::CacheDir
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub _open_cache
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };
    my $type    = $config->{ error_analyzer_cache_type };
    my $dir     = $config->{ error_analyzer_cache_dir  };
    my $mode    = $config->{ error_analyzer_cache_mode } || 'temporal';
    my $days    = $config->{ error_analyzer_cache_size } || 14;

    if ($type eq 'File::CacheDir') {
	if ($dir) {
	    use File::CacheDir;
	    my $obj = new File::CacheDir {
		directory  => $dir,
		cache_type => $mode,
		expires_in => $days,
	    };
	    return $obj;
	}
    }

    return undef;
}


# Descriptions: dummy
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _close_cache
{
    ;
}


# Descriptions: delete the specified address
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: none
sub deluser
{
    my ($self, $address) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name }; 

    use FML::Restriction::Base;
    my $safe    = new FML::Restriction::Base;
    my $regexp  = $safe->basic_variable();
    my $addrreg = $regexp->{ address };

    # check if $address is a safe string.
    if ($address =~ /^($addrreg)$/) {
	Log("deluser: ok <$address>");
    }
    else {
	Log("deluser: invalid address");
	return;
    }

    # arguments to pass off to each method
    my $method       = 'unsubscribe';
    my $command_args = {
        command_mode => 'admin',
        comname      => $method,
        command      => "$method $address",
        ml_name      => $ml_name,
        options      => [ $address ],
        argv         => undef,
        args         => undef,
    };

    # here we go
    require FML::Command;
    my $obj = new FML::Command;

    if (defined $obj) {
        # execute command ($comname method) under eval().
        eval q{
            $obj->$method($curproc, $command_args);
        };
        unless ($@) {
            ; # not show anything
        }
        else {
            my $r = $@;
            LogError("command $method fail");
            LogError($r);
            if ($r =~ /^(.*)\s+at\s+/) {
                my $reason = $1;
                Log($reason); # pick up reason
                croak($reason);
            }
        }
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::ErrorAnalyze appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
