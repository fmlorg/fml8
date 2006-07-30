#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: error.pm,v 1.18 2006/03/04 13:48:28 fukachan Exp $
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

show error (bounce mail) status.

=head1 METHODS

=head2 new()

constructor.

=head2 need_lock()

need lock or not.

=head2 lock_channel()

return lock channel name.

=head2 verify_syntax($curproc, $command_context)

provide command specific syntax checker.

=head2 process($curproc, $command_context)

main command specific routine.

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
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

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
    my $option = $curproc->command_line_cui_specific_options() || {};
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

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::error first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
