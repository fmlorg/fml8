#-*- perl -*-
#
# Copyright (C) 2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML$
#

package FML::Process::Emulate;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Emulate -- fml version 4's fml.pl emulator.

=head1 SYNOPSIS

   use FML::Process::Emulate;
   ...

See L<FML::Process::Flow> for details of the fml flow.

=head1 DESCRIPTION

C<FML::Process::Flow::ProcessStart($obj, $args)> drives the fml flow
where C<$obj> is the object C<FML::Process::$module::new()> returns.

=head1 METHOD

=head2 new($args)

create C<FML::Process::Emulate> object.
C<$curproc> is the object C<FML::Process::Kernel> returns but
we bless it as C<FML::Process::Emulate> object again.

=cut


# Descriptions: standard constructor.
#               sub class of FML::Process::Kernel
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(FML::Process::Emulate)
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 prepare($args)

forward the request to the base class.
adjust ml_* and load configuration files.

=cut


# Descriptions: prepare miscellaneous work before the main routine starts.
#               adjust ml_* and load configuration files.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    my $a = $curproc->command_line_options || {};
    if (defined $a->{ ctladdr } && $a->{ ctladdr }) {
	$curproc->log("start as command_mail mode");

 	eval q{
	    use FML::Process::Command;
	    unshift(@ISA, "FML::Process::Command");
	};
	$curproc->logerror($@) if $@;
	croak("failed to initialize command_mail process.") if $@;

	if ($config->yes('use_command_mail_function')) {
	    $curproc->parse_incoming_message();
	}
	else {
	    $curproc->logerror("use of command_mail program prohibited");
	    exit(0);
	}
    }
    else {
	$curproc->log("start as article_post mode");

	eval q{
	    use FML::Process::Distribute;
	    unshift(@ISA, "FML::Process::Distribute");
	};
	$curproc->logerror($@) if $@;
	croak("failed to initialize article_post process.") if $@;

	if ($config->yes('use_article_post_function')) {
	    $curproc->parse_incoming_message();
	}
	else {
	    $curproc->logerror("use of distribute program prohibited");
	    exit(0);
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
reEmulate it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Emulate first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
