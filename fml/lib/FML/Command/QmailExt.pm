#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.10 2006/01/07 13:16:41 fukachan Exp $
#

package FML::Command::QmailExt;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::QmailExt - qmail-ext style command emulator.

=head1 SYNOPSIS

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


=head2 match($extension)

Environment variable EXT holds extention information.
for example, a mail to ML-subscribe@VIRTUAL.DOMAIN is recognized as
extension with "VIRTUAL.DOMAIN-ML-subscribe" in EXT variable.

=cut


# Descriptions: check if $extension string look a qmail extension command.
#    Arguments: OBJ($self) STR($extension)
# Side Effects: none
# Return Value: NUM
sub match
{
    my ($self, $extension) = @_;
    my $curproc = $self->{ _curproc };

    # ASSERT
    unless (defined $extension) { return 0;}
    unless ($extension)         { return 0;}

    # 1. parse command normally.
    my ($found, $command) = $self->_parse_extension($extension);
    $curproc->logdebug("qmail-ext: @$command");

    # 2. admin command special handling.
    # XXX VERPs and admin command looks same.
    # need more care for admin command, which is an exception.
    my ($main_command, $sub_command) = @$command;
    if ($main_command eq 'admin') {
	if ($sub_command =~ /^[a-z0-9]+$/i) {
	    $curproc->logdebug("qmail-ext: looks admin command");
	}
	else {
	    $curproc->logdebug("qmail-ext: not looks admin command");
	    $found = 0;
	}
    }

    return $found;
}


# Descriptions: parse extension string.
#               return status and command list as ARRAY_REF.
#    Arguments: OBJ($self) STR($extension)
# Side Effects: none
# Return Value: ARRAY(NUM, ARRAY_REF)
sub _parse_extension
{
    my ($self, $extension) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();
    my $anonymous_command_list =
	$config->get_as_array_ref('anonymous_command_mail_allowed_commands');
    my $user_command_list =
	$config->get_as_array_ref('user_command_mail_allowed_commands');

    # extension is VIRTUAL.DOMAIN-ML-COMMAND-ARGUMENTS format.
    my (@command) = ();
    my $found     = 0;
  COMMAND:
    for my $command (@$anonymous_command_list, @$user_command_list) {
	my $pattern = sprintf("%s-%s-%s", $ml_domain, $ml_name, $command);
	if ($extension =~  /^($pattern)$|^($pattern)\-/i) {
	    my $argv = $self->_parse_argv($extension, $pattern);
	    (@command) = ($command, @$argv);
	    $found = 1;
	    last COMMAND;
	}
    }		     

    if ($found) {
	return($found, \@command);
    }
    else {
	return(0, []);
    }
}


# Descriptions: parse arguments and return it as ARRAY_REF.
#    Arguments: OBJ($self) STR($extension) STR($pattern)
# Side Effects: none
# Return Value: ARRAY_REF
sub _parse_argv
{
    my ($self, $extension, $pattern) = @_;

    my $argv = $extension;
    $argv =~ s/^$pattern//;
    $argv =~ s/^\-//;
    $argv =~ s/\-\-/\@/g; # XXX @ is unavaialble string. useful for swapping.
    $argv =~ s/\-/ /g;
    $argv =~ s/\@/-/g;
    $argv =~ s/=/\@/g;

    if ($argv) {
	my (@argv) = split(/\s+/, $argv);
	return \@argv;
    }
    else {
	return [];
    }
}


=head2 execute($extension)

emulate command process.

=cut


# Descriptions: emulate command process.
#    Arguments: OBJ($self) STR($extension)
# Side Effects: bootstrap FML::Process::Command emulation.
# Return Value: none
sub execute
{
    my ($self, $extension) = @_;
    my $curproc = $self->{ _curproc };

    # ASSERT
    unless (defined $extension) { return 0;}
    unless ($extension)         { return 0;}

    # 1. parse extension to extract a command (ARRAY_REF).
    my ($found, $command) = $self->_parse_extension($extension);
    $curproc->log("qmail-ext: emulate command: @$command");

    # 2. fake a command request message.
    # 2.1 message header is same as the current message.
    # 2.2 message body is $command.
    my $msg_file = $self->_construct_request_mail($command);
    unless (defined $msg_file) {
	$curproc->logerror("command execution stop");
	return;
    }

    # 3. close STDIO. re-open STDIO for our faked message.
    my $status = $self->_reopen_stdio_channel($msg_file);
    unless ($status) {
	$curproc->logerror("cannot re-open STDIO.");
	$curproc->logerror("command execution stop");
	return;
    }

    # 4. run a new process context by NewProcess() call.
    $self->_execute_new_process();
}


# Descriptions: create a temporary request message.
#    Arguments: OBJ($self) ARRAY_REF($command)
# Side Effects: none
# Return Value: STR
sub _construct_request_mail
{
    my ($self, $command) = @_;
    my $curproc = $self->{ _curproc };
    my $header  = $curproc->incoming_message_header();

    # create a new faked message file.
    use FileHandle;
    my $message_file = $curproc->tmp_file_path();
    my $wh = new FileHandle "> $message_file";
    if (defined $wh) {
	$wh->autoflush(1);
	$header->print($wh);
	print $wh "\n";
	print $wh join(" ", @$command), "\n";
	$wh->close();
    }
    else {
	$curproc->logerror("cannot open tmp file: $message_file");
	return undef;
    }

    return $message_file;
}


# Descriptions: close and re-open STDIN
#    Arguments: OBJ($self) STR($message_file)
# Side Effects: close and re-open STDIN
# Return Value: NUM
sub _reopen_stdio_channel
{
    my ($self, $message_file) = @_;

    close(STDIN);
    my $status = open(STDIN, $message_file);
    return( $status ? 1 : 0 ); 
}


# Descriptions: emulate execution of command mail process.
#    Arguments: OBJ($self)
# Side Effects: execute a new process.
# Return Value: none
sub _execute_new_process
{
    my ($self)    = @_;
    my $curproc   = $self->{ _curproc };
    my $myname    = "command";
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();

    $curproc->logdebug("emulate $myname for $ml_name\@$ml_domain ML");

    my $hints = {
	config_overload => {
	    'use_incoming_mail_header_loop_check' => 'no',
	},
    };

    eval q{
	use FML::Process::Switch;
	&FML::Process::Switch::NewProcess($curproc,
					  $myname,
					  $ml_name,
					  $ml_domain,
					  $hints);
    };
    if ($@) {
	$curproc->logerror($@);
    }

    $curproc->logdebug("emulation done");
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

FML::Command::QmailExt appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
