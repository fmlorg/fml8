#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: error.pm,v 1.14 2004/06/26 11:47:56 fukachan Exp $
#

package FML::Command::Admin::error;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::error - show statics/status of error mails.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show error status.

=head1 METHODS

=head2 process($curproc, $command_args)

call error status generator.

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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: return lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return undef;}


# Descriptions: list up status of error messages.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->_fmlerror($curproc);
}


# Descriptions: show analyzed result of error messages in all
#               available analyzer cases.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _fmlerror
{
    my ($self, $curproc) = @_;
    my $config      = $curproc->config();
    my $select_list =
	$config->get_as_array_ref('error_mail_analyzer_function_select_list');

    use FML::Error;
    my $error = new FML::Error $curproc;

    # XXX fml $ml error -O algorithm=ALGORITHM
    my $option = $curproc->cui_command_specific_options() || {};
    if (defined $option->{ algorithm } && $option->{ algorithm }) {
	my $fp = $option->{ algorithm };
	if ($config->has_attribute('error_mail_analyzer_function_select_list',
				   $fp)) {
	    $self->_run_analyzer($curproc, $error, $fp);
	}
	else {
	    $curproc->ui_message("error: unknown algorithm: $fp");
	    $curproc->logerror("unknown algorithm: $fp");
	}
    }
    else {
	# show all cases.
	for my $fp (@$select_list) {
	    $self->_run_analyzer($curproc, $error, $fp);
	}
    }
}


# Descriptions: show result by the specified analyzer.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($error) STR($fp)
# Side Effects: none
# Return Value: none
sub _run_analyzer
{
    my ($self, $curproc, $error, $fp) = @_;

    print "# analyzer function = $fp\n";
    $error->set_analyzer_function($fp);
    $error->analyze();
    $error->print();
    print "\n";
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

FML::Command::Admin::error first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
