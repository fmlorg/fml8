#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: CreateOnPost.pm,v 1.2 2006/07/09 12:11:12 fukachan Exp $
#

package FML::CreateOnPost;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::CreateOnPost - CREATE-ON-POST

=head1 SYNOPSIS

use FML::CreateOnPost;
my $cop = new FML::CreateOnPost $curproc;
$cop->distribute_ml($ml);

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

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


# Descriptions: create ml.
#    Arguments: OBJ($self) STR($ml_addr)
# Side Effects: none
# Return Value: none
sub create_ml
{
    my ($self, $ml_addr) = @_;
    my $curproc = $self->{ _curproc };
    my $myname  = "fml";
    my $hints   = {};

    # prepare parameters;
    my ($ml_name, $ml_domain) = split(/\@/, $ml_addr);
    $hints->{ ARGV }    = [ $ml_addr, "newml" ];
    $hints->{ argv }    = [ $ml_addr, "newml", '-O', 'update-alias=no' ];
    $hints->{ options } = { 'O' => { 'update-alias' => 'no' } };

    eval q{
	$curproc->log("emulate $myname to create $ml_name\@$ml_domain");

	use FML::Process::Switch;
	&FML::Process::Switch::NewProcess($curproc,
					  $myname,
					  $ml_name,
					  $ml_domain,
					  $hints);
    };
    $curproc->logerror($@) if $@;
}


# Descriptions: run distribute process.
#    Arguments: OBJ($self) STR($ml_addr)
# Side Effects: none
# Return Value: none
sub distribute_ml
{
    my ($self, $ml_addr) = @_;
    my $curproc    = $self->{ _curproc };
    my $myname     = "distribute";
    my $maintainer = 'fukachan@home.fml.org';

    # prepare parameters;
    my ($ml_name, $ml_domain) = split(/\@/, $ml_addr);
    my $hints   = {};
    $hints->{ ARGV } = [ $ml_addr ];
    $hints->{ argv } = [ $ml_addr ];
    $hints->{ config_overload } = {
	'article_post_restrictions' => 'permit_anyone',
	'maintainer'                => $maintainer,
    };

    # open STDIO
    my $queue = $curproc->incoming_message_get_current_queue();
    if (defined $queue) {
	my $class = "incoming";

	close(STDIN);
	unless ($queue->open($class, { in_channel => *STDIN{IO} })) {
	    my $qid = $queue->id();
	    $curproc->logerror("cannot open qid=$qid");
	}
    }
    else {
	$curproc->logerror("queue not found");
	return;
    }

    eval q{
	$curproc->log("emulate $myname for $ml_name\@$ml_domain");

	use FML::Process::Switch;
	&FML::Process::Switch::NewProcess($curproc,
					  $myname,
					  $ml_name,
					  $ml_domain,
					  $hints);
    };
    $curproc->logerror($@) if $@;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CreateOnPost appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
