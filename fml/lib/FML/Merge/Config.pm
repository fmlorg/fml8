#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Config.pm,v 1.1 2004/03/20 02:43:03 fukachan Exp $
#

package FML::Merge::Config;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;


=head1 NAME

FML::Merge::Config - handle configurations.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($params)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $params) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # import variables: ml_* ...
    for my $x (keys %$params) {
	$me->{ "_$x" } = $params->{ $x } if defined $params->{ $x };
    };

    return bless $me, $type;
}


# Descriptions: set { $key => $value }.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: update $self
# Return Value: none
sub set
{
    my ($self, $key, $value) = @_;

    if (defined $key && defined $value) {
	$self->{ "_$key" } = $value;
    }
    else {
	return '';
    }
}


# Descriptions: return value for the key $key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: update $self
# Return Value: none
sub get
{
    my ($self, $key) = @_;

    if (defined $self->{ "_$key" }) {
	return $self->{ "_$key" };
    }
    else {
	return '';
    }
}


=head1 UTILITIES

=cut


# Descriptions: return file path at the source dir.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub old_file_path
{
    my ($self, $file) = @_;
    my $old_home_dir  = $self->get('src_dir');

    return File::Spec->catfile($old_home_dir, $file);
}


# Descriptions: return file path at $ml_home_dir.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub new_file_path
{
    my ($self, $file) = @_;
    my $ml_home_dir   = $self->get('ml_home_dir');

    return File::Spec->catfile($ml_home_dir, $file);
}


# Descriptions: return file path at backup-ed dir e.g. $ml_home_dir/.fml4rc.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub backup_file_path
{
    my ($self, $file) = @_;
    my $back_up_dir   = $self->get('backup_dir');

    return File::Spec->catfile($back_up_dir, $file);
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

FML::Merge::Config appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
