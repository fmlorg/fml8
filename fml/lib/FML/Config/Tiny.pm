#-*- perl -*-
#
#  Copyright (C) 2003,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Tiny.pm,v 1.3 2005/05/26 10:20:05 fukachan Exp $
#

package FML::Config::Tiny;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Config::Tiny - just read and return without variable expansion.

=head1 SYNOPSIS

use FML::Config::Tiny;
my $tinyconfig = new FML::Config::Tiny;
$new_main_cf = $tinyconfig->read($default_main_cf);

=head1 DESCRIPTION

This class provides simplest function of configuration file parser.
It reads and returns config hash without variable expansion.

=head1 METHODS

=head2 new()

constructor.

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


=head2 read($file)

read $file, parse it and return content as HASH_REF.

=cut


# Descriptions: read $file, parse it and return content as HASH_REF.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: HASH_REF
sub read
{
    my ($self, $file) = @_;
    my $config = {};

    my $fh = new IO::File $file, "r";
    if (defined $fh) {
        my $curkey = '';
	my $buf;

      LINE:
        while ($buf = <$fh>) {
            next LINE if $buf =~ /^\#/o;
            chomp $buf;

            if ($buf =~ /^([A-Za-z]\w+)\s+=\s*(.*)/) {
                my ($key, $value) = ($1, $2);
                $curkey           = $key;
                $config->{$key}   = $value;
            }
            if ($buf =~ /^\s+(.*)/) {
                $config->{ $curkey } .= " $1";
            }
        }
        $fh->close;
    }
    else {
        croak("cannot open $file");
    }

    return $config;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Config::Tiny appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
