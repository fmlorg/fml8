#-*- perl -*-
#
# Copyright (C) 2002 Ken'ichi Fukamachi
#
# $FML: Spool.pm,v 1.1 2002/03/30 15:29:43 fukachan Exp $
#

package Mail::Message::Spool;

use strict;
use Carp;

=head1 NAME

Mail::Message::Spool - utilities for Spool style format

=head1 SYNOPSIS

   use Mail::Message::Spool;
   my $Spool = new Mail::Message::Spool;

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut


# Descriptions: usual constructor
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

return article file path.

   $args = {
	base_dir   => $base_dir, 
	id         => $id,
	use_subdir => 0,    # 1 or 0
   };

=cut


# Descriptions: return article file path.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR(file path)
sub filepath
{
    my ($self, $args) = @_;

    if (defined $args->{ base_dir } && defined $args->{ id }) {
	my $base_dir = $args->{ base_dir };
	my $id       = $args->{ id };
	my $is_hash  = 0;
	my $file     = '';
	my $unit     = 1000;
	my $subdir   = int($id/$unit);

	if (defined $args->{ use_subdir }) {
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


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Spool appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
