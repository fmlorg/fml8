#-*- perl -*-
#
# Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#
# $FML: Spool.pm,v 1.12 2004/01/24 09:04:00 fukachan Exp $
#

package Mail::Message::Spool;

use strict;
use Carp;

=head1 NAME

Mail::Message::Spool - utilities to handle directory such as article spool.

=head1 SYNOPSIS

   use Mail::Message::Spool;
   my $spool = new Mail::Message::Spool;
   my $file  = $spool->filepath($args);

=head1 DESCRIPTION

C<Mail::Message::Spool> class provides utility functions to handle a
directory such as article spool.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 filepath($args)

return article file path.  If you use hierarchical subdirectories,
this filepath() conversion is useful.

   $args = {
	base_dir    => $base_dir,
	id          => $id,
	use_subdir  => 0,    # 1 or 0
	subdir_unit => 1000,
   };

where C<base_dir> and C<id> are mandatory.

=cut


# Descriptions: return article file path.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: croak() if failed.
# Return Value: STR(file path)
sub filepath
{
    my ($self, $args) = @_;

    # XXX-TODO: $is_hash is used for what ?
    if (defined $args->{ base_dir } && defined $args->{ id }) {
	my $base_dir = $args->{ base_dir };
	my $id       = $args->{ id };
	my $is_hash  = 0;
	my $file     = '';
	my $unit     = $args->{ subdir_unit } || 1000;
	my $subdir   = int($id/$unit);

	if (defined $args->{ use_subdir } && $args->{ use_subdir }) {
	    $is_hash = 1;
	    use File::Spec;
	    $file = File::Spec->catfile($base_dir, $subdir, $id);
	}
	else {
	    use File::Spec;
	    $file = File::Spec->catfile($base_dir, $id);
	}

	return $file;
    }
    else {
	croak("filepath: invalid input");
    }
}


# Descriptions: return article dirpath with subdir if needed.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: croak() if failed.
# Return Value: STR(dir path)
sub dirpath
{
    my ($self, $args) = @_;

    # XXX-TODO: $is_hash is used for what ?
    if (defined $args->{ base_dir } && defined $args->{ id }) {
	my $base_dir = $args->{ base_dir };
	my $id       = $args->{ id };
	my $is_hash  = 0;
	my $dir      = '';
	my $unit     = 1000;
	my $subdir   = int($id/$unit);

	if (defined $args->{ use_subdir } && $args->{ use_subdir }) {
	    $is_hash = 1;
	    use File::Spec;
	    $dir = File::Spec->catfile($base_dir, $subdir);
	}
	else {
	    $dir = $base_dir;
	}

	return $dir;
    }
    else {
	croak("filepath: invalid input");
    }
}


#
# test
#
if ($0 eq __FILE__) {
    my $obj = new Mail::Message::Spool;

    for my $is_hash (0, 1) {
	print "\nhashed ? ", ($is_hash ? "yes" : "no"), "\n\n";

	for my $id (qw(0 1 2 99 100 101
		       999 1000 1001 1999 2000 2001
		       9999 10000 10001
		       )) {
	    print "$id\t=>\t";
	    print $obj->filepath({
		base_dir   => '/var/spool/ml/elena/spool',
		id         => $id,
		use_subdir => $is_hash,
	    }), "\n";
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Spool first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
