#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Config.pm,v 1.5 2004/07/23 13:16:41 fukachan Exp $
#

package FML::Merge::FML4::Config;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Merge::FML4::Config - what files we need to merge.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($config)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $config) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# target files to back up.
my $ml_home_dir_backup_target_files = {

    #
    # main configuration files
    #
    'cf' => {
	'backup_mode' => 'move',
    },

    'config.ph' => {
	'backup_mode' => 'copy',
    },


    #
    # system
    #
    'aliases' => {
	'backup_mode' => 'move',
    },

    'crontab' => {
	'backup_mode' => 'move',
    },

    'fmlwrapper.c' => {
	'backup_mode' => 'move',
    },

    'fmlwrapper.h' => {
	'backup_mode' => 'move',
    },


    #
    # message files
    #
    'confirm' => {
	'backup_mode' => 'move',
    },

    'deny' => {
	'backup_mode' => 'move',
    },

    'guide' => {
	'backup_mode' => 'copy',
    },

    'help' => {
	'backup_mode' => 'move',
    },

    'help-admin' => {
	'backup_mode' => 'move',
    },

    'objective' => {
	'backup_mode' => 'move',
    },

    'welcome' => {
	'backup_mode' => 'move',
    },


    #
    # include*
    #
    'include' => {
	'backup_mode' => 'copy',
	'type'        => 'include',
    },

    'include-ctl' => {
	'backup_mode' => 'copy',
	'type'        => 'include',
    },

    'include-mead' => {
	'backup_mode' => 'copy',
	'type'        => 'include',
    },


    #
    # list files
    #

    # member list files
    'actives' => {
	'backup_mode' => 'move',
	'type'        => 'list',
    },

    'members' => {
	'backup_mode' => 'copy',
	'type'        => 'list',
    },

    # admin member list files
    'members-admin' => {
	'backup_mode' => 'copy',
	'type'        => 'list',
    },

    # moderators
    'moderators' => {
	'backup_mode' => 'copy',
	'type'        => 'list',
    },


    #
    # password files
    #
    'etc/passwd' => {
	'backup_mode' => 'move',
	'type'        => 'list',
    },


    #
    # log et.al.
    #
    'summary' => {
	'backup_mode' => 'copy',
	'continue'    => 'yes',
    },

    'seq' => {
	'backup_mode' => 'copy',
	'continue'    => 'yes',
    },

    'log' => {
	'backup_mode' => 'copy',
	'continue'    => 'yes',
    },


    #
    # misc
    #
    'Makefile' => {
	'backup_mode' => 'move',
    },
};


# Descriptions: return list of files to back up.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_old_config_files
{
    my ($self)  = @_;

    my (@files) = keys %$ml_home_dir_backup_target_files;
    return \@files
}


# Descriptions: return list of include* files.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_old_include_files
{
    my ($self)  = @_;
    my (@files) = ();

    for my $f (keys %$ml_home_dir_backup_target_files) {
	my $type = $ml_home_dir_backup_target_files->{ $f }->{ type } || '';
	if ($type eq 'include') {
	    push(@files, $f);
	}
    }

    return \@files
}


# Descriptions: return list of list* files.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_old_list_files
{
    my ($self)  = @_;
    my (@files) = ();

    for my $f (keys %$ml_home_dir_backup_target_files) {
	my $type = $ml_home_dir_backup_target_files->{ $f }->{ type } || '';
	if ($type eq 'list') {
	    push(@files, $f);
	}
    }

    return \@files
}


# Descriptions: return list of files we use continuously.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_continuous_use_files
{
    my ($self)  = @_;
    my (@files) = ();

    for my $f (keys %$ml_home_dir_backup_target_files) {
	my $cnt = $ml_home_dir_backup_target_files->{ $f }->{ continue } || '';
	if ($cnt eq 'yes') {
	    push(@files, $f);
	}
    }

    return \@files
}


# Descriptions: check if we should backup this $file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub backup_mode
{
    my ($self, $file) = @_;

    if (defined $ml_home_dir_backup_target_files->{$file}->{backup_mode}) {
	my $mode = $ml_home_dir_backup_target_files->{$file}->{backup_mode};
	return $mode;
    }
    else {
	return 'unknown';
    }
}


#
# debug
#
if ($0 eq __FILE__) {
   for my $f (keys %$ml_home_dir_backup_target_files) {
	print $f, "\n";
   }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Merge::FML4::Config appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
