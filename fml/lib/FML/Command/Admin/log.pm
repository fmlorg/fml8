#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: log.pm,v 1.1 2002/03/19 11:13:45 fukachan Exp $
#

package FML::Command::Admin::log;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::log - log file operations

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

log a new address.

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


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: log a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config   = $curproc->{ config };
    my $log_file = $config->{ log_file };
    my $options  = $command_args->{ options };
    my $address  = $command_args->{ command_data } || $options->[ 0 ];

    if (-f $log_file) {
	_show_log($log_file, { mode => 'text' });
    }
}


# Descriptions: log a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $config   = $curproc->{ config };
    my $log_file = $config->{ log_file };

    if (-f $log_file) {
	_show_log($log_file, { mode => 'cgi' });
    }
}


sub _show_log
{
    my ($log_file, $args) = @_;
    my $is_cgi       = 1 if $args->{ mode } eq 'cgi';
    my $last_n_lines = 30;
    my $linecount    = 0;
    my $maxline      = 0;

    use FML::Language::ISO2022JP qw(STR2EUC);

    use FileHandle;
    my $fh = new FileHandle $log_file;
    if (defined $fh) {
	while (<$fh>) { $maxline++;}
	$fh->close();

	$fh = new FileHandle $log_file;
	my $s = '';
	$maxline -= $last_n_lines;

      LINE:
	while (<$fh>) {
	    next LINE if $linecount++ < $maxline;

	    $s = STR2EUC($_);

	    if ($is_cgi) {
		$s =~ s/&/&amp;/g;
		$s =~ s/</&lt;/g;
		$s =~ s/>/&gt;/g;
		$s =~ s/\"/&quot;/g;
		print $s;
		print "<BR>\n";
	    }
	    else {
		print $s;
	    }
	}
	$fh->close;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::log appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
