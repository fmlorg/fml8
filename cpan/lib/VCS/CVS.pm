package VCS::CVS;

# Name:
#	VCS::CVS.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.
#
# Tabs:
#	4 spaces || die.
#
# --------------------------------------------------------------------------

use strict;
no strict 'refs';

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Carp;
use Cwd;
use File::Find;
use File::Path;

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT		= qw();

@EXPORT_OK	= qw();

$VERSION	= '2.00';

# Preloaded methods go here.
# --------------------------------------------------------------------------
# Add an existing directory to the project.
# $dir can be a full path, or relative to the CWD.

sub addDirectory
{
	my($self, $dir, $subDir, $message) = @_;

	# Preserve the caller's current working directory.
	my($cwd) = cwd();
	chdir($dir) || croak("Can't chdir($dir): \nFailure: $!");

	# CVS options:
	#	-Q				Really quiet.
	#	-m message		Use this log message.
	#	$subDir			Add this directory.

	# Warning: Do not try to combine these lines under any circumstances...
	# Perl can't handle null list elements in a call to system.
	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'add');

	if ($message)
	{
		$message = '"' . $message . '"' if ($message !~ /^".*"$/);
		push(@args, '-m', $message);
	}

	push(@args, $subDir);

	$self -> runOrCroak(@args);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

}	# End of addDirectory.

# --------------------------------------------------------------------------
# Add an existing file to the project.
# $dir can be a full path, or relative to the CWD.

sub addFile
{
	my($self, $dir, $file, $message) = @_;

	# Preserve the caller's current working directory.
	my($cwd) = cwd();
	chdir($dir) || croak("Can't chdir($dir): \nFailure: $!");

	# CVS options:
	#	-Q				Really quiet.
	#	-m message		Use this log message.
	#	$file			Add this file.

	# Warning: Do not try to combine these lines under any circumstances...
	# Perl can't handle null list elements in a call to system.
	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'add');

	if ($message)
	{
		$message = '"' . $message . '"' if ($message !~ /^".*"$/);
		push(@args, '-m', $message);
	}

	push(@args, $file);

	$self -> runOrCroak(@args);

	$self -> commit($message);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

}	# End of addFile.

# --------------------------------------------------------------------------
# Prepare & perform 'cvs checkout'.
# You call checkOut, and it calls _checkOutDontCallMe.
# $readOnly	Interpretation
#	0		Check out files as read-write
#	1		Check out files as read-only
# $tag		Interpretation
#	Null	Do not call upToDate; ie check out repository as is
#	! Null	Call upToDate; Croak if repository is not up-to-date
# If you called new with $raw == 1, your tag is passed as is to CVS.
# If you called new with $raw == 0, your tag is assumed to be of the
#	form release_1.23, and is converted to CVS's form release_1_23.
# $dir can be a full path, or relative to the CWD.

sub checkOut
{
	my($self, $readOnly, $tag, $dir) = @_;

	$tag =~ s/([-a-zA-Z]+_\d\d?)\.(\d\d)/$1_$2/ if (! $self -> {'raw'});

	$self -> _validateObject($self -> {'project'}, 'modules', 0);
	$self -> _validateObject($tag, 'val-tags', 0);

	croak("Failure: Move directory $dir out of the way") if (-d $dir);

	# Ensure the repository is up-to-date.
	croak("Failure: The repository is not up-to-date. Run 'cvs commit' or 'cvs update'")
		if ($tag && (! $self -> upToDate() ) );

	# Zap previous copy of work directory.
	rmtree($dir, $self -> {'verbose'});

	# Checkout a current copy of the project.
	$self -> _checkOutDontCallMe($readOnly, $tag, $dir);

}	# End of checkOut.

# --------------------------------------------------------------------------
# Commit changes.
# Called as appropriate by addFile, removeFile and removeDirectory,
# so you don't need to call it.

sub commit
{
	my($self, $message) = @_;

	# CVS options:
	#	-Q				Really quiet.
	#	-m message		Use this log message.

	# Warning: Do not try to combine these lines under any circumstances...
	# Perl can't handle null list elements in a call to system.
	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'commit');

	if ($message)
	{
		$message = '"' . $message . '"' if ($message !~ /^".*"$/);
		push(@args, '-m', $message);
	}

	$self -> runOrCroak(@args);

}	# End of commit.

# --------------------------------------------------------------------------
# Create a repository, using the current $CVSROOT.

sub createRepository
{
	my($self) = @_;

	croak("Failure: Move directory $ENV{'CVSROOT'} out of the way") if (-d $ENV{'CVSROOT'});

	# Create the repository and its files.
	$self -> _mkpathOrCroak($ENV{'CVSROOT'});
	$self -> _mkpathOrCroak("$ENV{'CVSROOT'}/CVSROOT");

	# Create the modules file.
	my(@args) = ();
	push(@args, "CVSROOT\t\tCVSROOT");
	push(@args, "modules\t\tCVSROOT\tmodules");
	push(@args, "$self->{'project'}\t\t$self->{'project'}");

	my($file) = "$ENV{'CVSROOT'}/CVSROOT/modules";
	open(OUT, "> $file") || croak("Can't open($file): \nFailure: $!");
	print OUT join("\n", @args), "\n";
	close(OUT);

	$file = "$ENV{'CVSROOT'}/CVSROOT/val-tags";
	open(OUT, "> $file") || croak("Can't open($file): \nFailure: $!");
	# Write nothing.
	close(OUT);

	if ($self -> {'history'})
	{
		$file = "$ENV{'CVSROOT'}/CVSROOT/history";
		open(OUT, "> $file") || croak("Can't open($file): \nFailure: $!");
		# Write nothing.
		close(OUT);
	}

}	# End of createRepository.

# --------------------------------------------------------------------------
# Return a reference to a list of tags.
# See also: the $raw option to new().

sub getTags
{
	my($self) = @_;

	my($line) = [];

	if (-e "$ENV{'CVSROOT'}/CVSROOT/val-tags")
	{
		$line = $self -> _readFile("$ENV{'CVSROOT'}/CVSROOT/val-tags");

		for (@$line)
		{
			$_ = (split)[0];

			# Convert tag_1_23 into tag_1.23, if requested.
			s/([-a-zA-Z]+_\d\d?)_(\d\d)/$1\.$2/ if (! $self -> {'raw'});
		}

	}

	$line;

}	# End of getTags.

# --------------------------------------------------------------------------
# Run cvs history [-options].
# Return a reference to a list of lines.
#
# The default option is -c.

sub history
{
	my($self, $optionRef) = @_;

	# Preserve the caller's current working directory.
	# cvs status only works on the whole repository when run from your project dir
	# (assuming, of course, you've checked out into your home directory...).
	my($cwd) = cwd();
	chdir("$ENV{'HOME'}/$self->{'project'}") ||
		croak("Can't chdir($ENV{'HOME'}/$self->{'project'}): $!");

	# CVS history options:
	#	-c		Report commits, ie -xARM.

	if (ref($optionRef) ne 'HASH')
	{
		$optionRef = {'-c' => ''};
	}

	my(@args) = ('cvs');
	push(@args, 'history');
	push(@args, join(' ', %$optionRef) );
	@args = `@args`;
	chomp(@args);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

	\@args;

}	# End of history.

# --------------------------------------------------------------------------
# These are the options in the anonymous hash of parameters you pass in to 'new'.
#
# 'project'
#	'killerApp'	The name of the project. No default
#
# 'history'
#	0			Do not create $CVSROOT/CVSROOT/history when createRepository() is called. Default
#	1			Create $CVSROOT/CVSROOT/history, which initiates 'cvs history' stuff
#
# 'permissions'
#	0775		Unix-specific. Default. Do not use '0775'
#
# 'raw'
#	0			Convert tags from CVS format to real format. Eg: release_1.23. Default
#	1			Set/Get tags in raw CVS format. Eg: release_1_23
#
# 'verbose'
#	0			Run quietly
#	1			Report progress. Default

sub new
{
	my($class, $optionRef)	= @_;
	$class					= ref($class) || $class;
	my($self)				= (ref($optionRef) eq 'HASH') ? $optionRef : {};

	my(%default) =
	(
		'history'		=> 0,
		'permissions'	=> 0775,	# But not '0775'!
		'project'		=> '',
		'raw'			=> 0,
		'verbose'		=> 1,
	);

	my($option);

	for $option (keys(%default) )
	{
		$self -> {$option} = $default{$option} if (! defined($self -> {$option}) );
	}

	$ENV{'HOME'}	= '' if (! defined($ENV{'HOME'}) );
	$ENV{'CVSROOT'}	= '' if (! defined($ENV{'CVSROOT'}) );

	croak("Failure: No project name specified")	if (! $self -> {'project'});
	croak("Failure: Env. var HOME not set")		if (! $ENV{'HOME'});
	croak("Failure: Env. var CVSROOT not set")	if (! $ENV{'CVSROOT'});

	return bless $self, $class;

}	# End of new.

# --------------------------------------------------------------------------
# Import an existing directory structure. But, (sub) import is a reserved word.
# Use this to populate a repository for the first time.
# The value used for $vendorTag is not important; CVS discards it.
# The value used to $releaseTag is important; CVS discards it (why?) but I
# force it to be the first tag in $CVSROOT/CVSROOT/val-tags. Thus you
# should supply a meaningful value. Thus 'release_0_00' is strongly, repeat
# strongly, recommended.
# If you called new with $raw == 1, $releaseTag is passed as is to CVS.
# If you called new with $raw == 0, $releaseTag is assumed to be of the
#	form release_1.23, and is converted to CVS's form release_1_23.

# $sourceDir can be a full path, or relative to the CWD.

sub populate
{
	my($self, $sourceDir, $vendorTag, $releaseTag, $message) = @_;

	$vendorTag	= 'vendorTag'		if ( ($#_ < 2) || (length($_[2]) == 0) );
	$releaseTag	= 'release_0_00'	if ( ($#_ < 3) || (length($_[3]) == 0) );
	$message	= 'Initial version'	if ($#_ < 4);

	$releaseTag	=~ s/([-a-zA-Z]+_\d\d?)\.(\d\d)/$1_$2/ if (! $self -> {'raw'});

	# Preserve the caller's current working directory.
	my($cwd) = cwd();
	chdir($sourceDir) || croak("Can't chdir($sourceDir): \nFailure: $!");

	# CVS options:
	#	-Q				Really quiet.
	#	-m message		Use this log message.

	# Warning: Do not try to combine these lines under any circumstances...
	# Perl can't handle null list elements in a call to system.
	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'import');

	if ($message)
	{
		$message	= '"' . $message . '"' if ($message !~ /^".*"$/);
		push(@args, '-m', $message);
	}

	push(@args, $self -> {'project'}, $vendorTag, $releaseTag);

	$self -> runOrCroak(@args);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

	# Compensate for yet another CVS bug.
	$self -> _fixTag($releaseTag);

}	# End of populate.

# --------------------------------------------------------------------------
# Remove a directory from the project.
# This deletes the directory (and all its files) from your working copy
# of the repository, as well as deleting them from the repository.
# Warning: $dir will have $CVSROOT and $HOME prepended by this code.
# Ie: $dir starts from - but excludes - your home directory
# (assuming, of course, you've checked out into your home directory...).
# You can't remove the current directory, or a parent thereof.

sub removeDirectory
{
	my($self, $dir) = @_;

	my($cvsDir)		= "$ENV{'CVSROOT'}/$dir/";
	my($workDir)	= "$ENV{'HOME'}/$dir/";

	# Preserve the caller's current working directory.
	my($cwd) = cwd();

	# Move into the work directory.
	chdir($workDir) || croak("Can't chdir($workDir): \nFailure: $!");
	my($thisCwd) = cwd();

	# Sanity check.
	croak("Failure: You can't remove the current directory, or a parent") if ($cwd =~ /^$thisCwd/);

	# Ensure the repository is up-to-date.
	croak("Failure: The repository is not up-to-date. Run 'cvs commit' or 'cvs update'")
		if (! $self -> upToDate() );

	# Read the CVS entries.
	my($cvsEntries)	= 'CVS/Entries';
	my($entry)		= $self -> _readFile($cvsEntries);

	# Remove each file, using CVS.
	for (@$entry)
	{
		next if (/^D/);

		my($file);

		$file = $1 if (/^\/(.+?)\//);

		$self -> removeFile($workDir, $file, 'Whole directory removed');
	}

	$self -> commit('Whole directory removed');

	# Move up, and remove the directory.
	chdir('..') || croak("Can't chdir('..'): \nFailure: $!");
	my($directory)	= $workDir;
	my($index)		= rindex($directory, '/', (length($directory) - 2) );
	substr($directory, 0, ($index + 1) ) = '';
	rmtree($directory, $self -> {'verbose'});

	# Edit the CVS entries file to remove the dir.
	if (-f $cvsEntries)
	{
		$entry	= $self -> _readFile($cvsEntries);
		@$entry	= grep(! /^D\/$directory\//, @$entry);
		open(OUT, "> $cvsEntries") || croak("Can't open $cvsEntries: \nFailure: $!");
		print OUT join("\n", @$entry), "\n";
		close(OUT);
	}

	# Remove the directory from CVS.
	rmtree($cvsDir, $self -> {'verbose'});

	# Remove the directory from the modules list.
	if ($dir !~ /\//)
	{
		$cvsEntries	= "$ENV{'CVSROOT'}/CVSROOT/modules";
		$entry		= $self -> _readFile($cvsEntries);

		my($i);

		for ($i = 0; $i <= $#{$entry}; $i++)
		{
			my(@field) = split(/\s+/, $$entry[$i]);
			splice(@$entry, $i, 1) if ($field[1] =~ /^$dir$/);
		}

		open(OUT, "> $cvsEntries") || croak("Can't open $cvsEntries: \nFailure: $!");
		print OUT join("\n", @$entry), "\n";
		close(OUT);
	}

	chdir($cwd) || croak("Can't chdir($cwd): $!");

}	# End of removeDirectory.

# --------------------------------------------------------------------------
# Remove a file from the project.
# This deletes the file from your working copy of the repository,
# as well as deleting it from the repository.
# $dir can be a full path, or relative to the CWD.
# $file is relative to $dir.

sub removeFile
{
	my($self, $dir, $file, $message) = @_;

	# Preserve the caller's current working directory.
	my($cwd) = cwd();
	chdir($dir) || croak("Can't chdir($dir): \nFailure: $!");

	unlink($file) || croak("Can't unlink($file): $!");

	# CVS options:
	#	-Q				Really quiet.
	#	-f				Remove the file first.
	#	-l				Do not recurse.
	#	$file			Checkout this module.

	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'remove', '-f', '-l', $file);

	$self -> runOrCroak(@args);

	$self -> commit($message);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

}	# End of removeFile.

# --------------------------------------------------------------------------
# The standard way to run a system command and report on the result.

sub runOrCroak
{
	my($self, @args) = @_;

	my($result) = 0xffff & system(@args);

	print "Command: @args\n";

	if ($result == 0)
	{
		print 'Success. ';
	}
	elsif ($result == 0xff00)
	{
		print "Failure: $!. ";
	}
	elsif ($result > 0x80)
	{
		$result >>= 8;
		print "Exit status: $result. ";
	}
	else
	{
		if ($result & 0x80)
		{
			$result &= ~0x80;
			print 'Coredump from ';
		}

		print "Signal $result. ";
	}

	printf("Result: %#04x\n", $result);

	croak("Failure: Can't run '@args'") if ($result);

}	# End of runOrCroak.

# --------------------------------------------------------------------------
# Tag the repository.
# You call setTag, and it calls _setTag.
# If you called new with $raw == 1, your tag is passed as is to CVS.
# If you called new with $raw == 0, your tag is assumed to be of the
#	form release_1.23, and is converted to CVS's form release_1_23.

sub setTag
{
	my($self, $tag) = @_;

	$tag =~ s/([-a-zA-Z]+_\d\d?)\.(\d\d)/$1_$2/ if (! $self -> {'raw'});

	$self -> _validateObject($self -> {'project'}, 'modules', 0);
	$self -> _validateObject($tag, 'val-tags', 1);

	croak("Failure: The repository is not up-to-date. Run 'cvs commit' or 'cvs update'")
		if ($self -> upToDate() == 0);

	$self -> _setTag($tag);

}	# End of setTag.

# --------------------------------------------------------------------------
# Run cvs status.
# Return a reference to a list of lines.
# Only called by upToDate(), but you may call it.

sub status
{
	my($self) = @_;

	# Preserve the caller's current working directory.
	# cvs status only works on the whole repository when run from your project dir
	# (assuming, of course, you've checked out into your home directory...).
	my($cwd) = cwd();
	chdir("$ENV{'HOME'}/$self->{'project'}") ||
		croak("Can't chdir($ENV{'HOME'}/$self->{'project'}): $!");

	# CVS options:
	#	-Q				Really quiet.

	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'status');
	@args = `@args`;
	chomp(@args);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

	\@args;

}	# End of status.

# --------------------------------------------------------------------------
# Delete all CVS directories and files from a copy of the repository.

sub stripCVSDirs
{
	my($self, $dir) = @_;

	# Preserve the caller's current working directory.
	my($cwd) = cwd();
	chdir($dir) || croak("Can't chdir($dir): $!");

	my(%dirStack);

	find
	(
		sub
		{
			$dirStack{$File::Find::dir} = 1 if ($File::Find::dir =~ /\/CVS$/);
		},
		cwd()
	);

	for (keys(%dirStack) )
	{
		rmtree($_, $self -> {'verbose'});
	}

	chdir($cwd) || croak("Can't chdir($cwd): $!");

}	# End of stripCVSDirs.

# --------------------------------------------------------------------------
# Run cvs -q [-n] update.
# Return a reference to a list of lines.
# Each line will start with one of [UARMC?], as per the CVS docs.
#
# Parameters	Interpretation
#	$n			0 -> Do not add -n to the cvs update command
#				1 -> Add -n to the command

sub update
{
	my($self, $n) = @_;

	$n = 0 if (! defined($n) );

	# Preserve the caller's current working directory.
	# cvs status only works on the whole repository when run from your project dir
	# (assuming, of course, you've checked out into your home directory...).
	my($cwd) = cwd();
	chdir("$ENV{'HOME'}/$self->{'project'}") ||
		croak("Can't chdir($ENV{'HOME'}/$self->{'project'}): $!");

	# CVS options:
	#	-q				Quiet
	#	-n				Do not change any files

	my(@args) = ('cvs');
	push(@args, '-q')	if (! $self -> {'verbose'});
	push(@args, '-n')	if ($n);
	push(@args, 'update');
	@args = `@args`;
	chomp(@args);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

	\@args;

}	# End of update.

# --------------------------------------------------------------------------
# Return	Interpretation
#	0		Repository not up-to-date.
#	1		Up-to-date.

sub upToDate
{
	my($self) = @_;

	# Get the status of the repository.
	my($status)	= $self -> status();
	@$status	= grep(/Status/ && ! /Up-to-date/, @$status);
	my($result)	= 1;						# Up-to-date.
	$result		= 0 if ($#{$status} >= 0);	# Not, because log contains something.

	$result;

}	# End of upToDate.

# --------------------------------------------------------------------------
# Checkout a current copy of the project.
# You call checkOut, and it calls this.

sub _checkOutDontCallMe
{
	my($self, $readOnly, $tag, $dir) = @_;

	# CVS options:
	#	-Q				Really quiet.
	#	-r				Read-only. Make the new working files read-only.
	#	-d$dir		Use $dir, not $project, as the directory name.
	#	-r <tag>		Check out files tagged with <tag>. Optional.
	#
	#	$project		Checkout this module.

	# CVS bug. Remove trailing '/', if any.
	$dir = $1 if ($dir =~ /^(.+)\/$/);

	# Warning: Do not try to combine these lines under any circumstances...
	# Perl can't handle null list elements in a call to system.
	my(@args) = ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, '-r') if ($readOnly);
	push(@args, 'checkout', '-A', '-P', "-d$dir");
	push(@args, '-r', $tag) if ($tag);
	push(@args, $self -> {'project'});

	$self -> runOrCroak(@args);

}	# End of _checkOutDontCallMe.

# --------------------------------------------------------------------------
# Fix a tag CVS failed to add.
# Warning: $tag must be in CVS format. Eg: release_1_23, not release_1.23.

sub _fixTag
{
	my($self, $tag) = @_;

	my($file) = "$ENV{'CVSROOT'}/CVSROOT/val-tags";

	open(INX, $file) || croak("Can't open($file): \nFailure: $!");

	my($found) = 0;

	while (<INX>)
	{
		$found = 1 if (/^$tag/);
	}

	close(INX);

	if (! $found)
	{
		print "Warning: CVS bug. Tag $tag not in file $file\n" if ($self -> {'verbose'});
		print "Fixing... " if ($self -> {'verbose'});

		open(OUT, ">> $file") || croak("Can't open(>>$file): \nFailure: $!");
		print OUT "$tag y\n";
		close(OUT);

		print "Success\n" if ($self -> {'verbose'});
	}

}	# End of _fixTag.

# --------------------------------------------------------------------------

sub _mkpathOrCroak
{
	my($self, $dir) = @_;

	my($result) = mkpath($dir, $self -> {'verbose'}, $self -> {'permissions'});

	croak("Can't mkpath($dir, $self->{'verbose'}, $self->{'permissions'}): \nFailure: $!")
		if ( (! $result) && ($! !~ /No such file/) );

}	# End of _mkpathOrCroak.

# --------------------------------------------------------------------------
# Return a reference to a list of lines.

sub _readFile
{
	my($self, $file) = @_;

	open(INX, $file) || croak("Can't open($file): $!");
	my(@line) = <INX>;
	close(INX);
	chomp(@line);

	\@line;

}	 # end of _readFile.

# --------------------------------------------------------------------------
# Tag the current version of the project.
# Warning: $tag must be in CVS format. Eg: release_1_23, not release_1.23.
# You call setTag and it calls this.

sub _setTag
{
	my($self, $tag) = @_;

	# Preserve the caller's current working directory.
	# cvs tag only works on the whole repository when run from your project dir
	# (assuming, of course, you've checked out into your home directory...).
	my($cwd) = cwd();
	chdir($ENV{'HOME'}) || croak("Can't chdir($ENV{'HOME'}): $!");

	# CVS options:
	#	-Q				Really quiet.
	#	-r <tag>		Tag files with <tag>.
	#	$project		Tag this module.

	# Warning: Do not try to combine these lines under any circumstances...
	# Perl can't handle null list elements in a call to system.
	my(@args)	= ('cvs');
	push(@args, '-Q') if (! $self -> {'verbose'});
	push(@args, 'tag', $tag, $self -> {'project'});

	$self -> runOrCroak(@args);

	chdir($cwd) || croak("Can't chdir($cwd): $!");

	# Compensate for yet another CVS bug.
	$self -> _fixTag($tag);

}	# End of _setTag.

# --------------------------------------------------------------------------
# Validate an entry in one of the CVS files 'module' or 'val-tags'.
# Warning: $tag must be in CVS format. Eg: release_1_23, not release_1.23.

sub _validateObject
{
	my($self, $tag, $file, $mustBeAbsent) = @_;

	$file = "$ENV{'CVSROOT'}/CVSROOT/$file";

	open(INX, $file) || croak("Can't open($file): \nFailure: $!");

	my($found) = 0;

	while (<INX>)
	{
		$found = 1 if (/^$tag/);
	}

	close(INX);

	croak("Failure: Tag not found: $tag in file $file")
		if ( (! $found) && (! $mustBeAbsent) );

	croak("Failure: Tag already present: $tag in file $file")
		if ($found && $mustBeAbsent);

}	# End of _validateObject.

# --------------------------------------------------------------------------

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

C<VCS::CVS> - Provide a simple interface to CVS (the Concurrent Versions System).

You need to be clear in your mind about the 4 directories involved:

=over 4

=item *

The directory where your source code resides before you import it into CVS.
It is used only once - during the import phase. Call this $projectSource.

=item *

The directory into which you check out a read-write copy of the repository,
in order to edit that copy. Call this $project. You will spend up to 100% of
your time working within this directory structure.

=item *

The directory in which the repository resides. This is $CVSROOT. Thus
$projectSource will be imported into $CVSROOT/$project.

=item *

The directory into which you get a read-only copy of the repository, in order to,
say, make and ship that copy. Call this $someDir. It must not be $project.

=back

Note: You cannot have a directory called CVS in your home directory. That's
just asking for trouble.

=head1 SYNOPSIS

	#!/usr/gnu/bin/perl -w

	use integer;
	use strict;

	use VCS::CVS;

	my($history)        = 1;
	my($initialMsg)     = 'Initial version';
	my($noChange)       = 1;
	my($nullTag)        = '';
	my($permissions)    = 0775;	# But not '0775'!
	my($project)        = 'project';
	my($projectSource)  = 'projectSource';
	my($raw)            = 0;
	my($readOnly)       = 0;
	my($releaseTag)     = 'release_0.00';
	my($vendorTag)      = 'vendorTag';
	my($verbose)        = 1;

	# Note the anonymous hash in the next line, new as of V 1.10.

	my($cvs)            = VCS::CVS -> new({
				'project' => $project,
				'raw' => $raw,
				'verbose' => $verbose,
				'permissions' => $permissions,
				'history' => $history});

	$cvs -> createRepository();
	$cvs -> populate($projectSource, $vendorTag, $releaseTag, $initialMsg);
	$cvs -> checkOut($readOnly, $nullTag, $project);

	print join("\n", @{$cvs -> update($noChange)});
	print "\n";
	print join("\n", @{$cvs -> history()});

	exit(0);

=head1 DESCRIPTION

The C<VCS::CVS> module provides an OO interface to CVS.

VCS - Version Control System - is the prefix given to each Perl module which
deals with some sort of source code control system.

I have seen CVS corrupt binary files, even when run with CVS's binary option -kb.
So, since CVS doesn't support binary files, neither does VCS::CVS.

Stop press: CVS V 1.10 (with RCS 5.7) supports binary files.

Subroutines whose names start with a '_' are not normally called by you.

There is a test program included, but I have not yet worked out exactly how to
set it up for make test. Stay tuned.

=head1 INSTALLATION

You install C<VCS::CVS>, as you would install any perl module library,
by running these commands:

	perl Makefile.PL
	make
	make test
	make install

If you want to install a private copy of C<VCS::CVS> in your home
directory, then you should try to produce the initial Makefile with
something like this command:

	perl Makefile.PL LIB=~/perl
		or
	perl Makefile.PL LIB=C:/Perl/Site/Lib

If, like me, you don't have permission to write man pages into unix system
directories, use:

	make pure_install

instead of make install. This option is secreted in the middle of p 414 of the
second edition of the dromedary book.

=head1 WARNING re CVS bugs

The following are my ideas as to what constitutes a bug in CVS:

=over 4

=item *

The initial revision tag, supplied when populating the repository with
'cvs import', is not saved into $CVSROOT/CVSROOT/val-tags.

=item *

The 'cvs tag' command does not always put the tag into 'val-tags'.

=item *

C<'cvs checkout -dNameOfDir'> fails if NameOfDir =~ /\/$/.

=item *

C<'cvs checkout -d NameOfDir'> inserts a leading space into the name of
the directory it creates.

=back

=head1 WARNING re test environment

This code has only been tested under Unix. Sorry.

=head1 WARNING re project names 'v' directory names

I assume your copy of the repository was checked out into a directory with
the same name as the project, since I do a 'cd $HOME/$project' before running
'cvs status', to see if your copy is up-to-date. This is because some activity is
forbibben unless your copy is up-to-date. Typical cases of this include:

=over 4

=item *

C<checkOut>

=item *

C<removeDirectory>

=item *

C<setTag>

=back

=head1 WARNING re shell intervention

Some commands cause the shell to become involved, which, under Unix, will read your
.cshrc or whatever, which in turn may set CVSROOT to something other than what you
set it to before running your script. If this happens, panic...

Actually, I think I've eliminated such cases. You hope so.

=head1 WARNING re Perl bug

As always, be aware that these 2 lines mean the same thing, sometimes:

=over 4

=item *

$self -> {'thing'}

=item *

$self->{'thing'}

=back

The problem is the spaces around the ->. Inside double quotes, "...", the
first space stops the dereference taking place. Outside double quotes the
scanner correctly associates the $self token with the {'thing'} token.

I regard this as a bug.

=head1 addDirectory($dir, $subDir, $message)

Add an existing directory to the project.

$dir can be a full path, or relative to the CWD.

=head1 addFile($dir, $file, $message)

Add an existing file to the project.

$dir can be a full path, or relative to the CWD.

=head1 checkOut($readOnly, $tag, $dir)

Prepare & perform 'cvs checkout'.

You call checkOut, and it calls _checkOutDontCallMe.

=over 4

=item *

$readOnly == 0 -> Check out files as read-write.

=item *

$readOnly == 1 -> Check out files as read-only.

=back

=over 4

=item *

$tag is Null -> Do not call upToDate; ie check out repository as is.

=item *

$tag is not Null -> Call upToDate; Croak if repository is not up-to-date.

=back

The value of $raw used in the call to new influences the handling of $tag:

=over 4

=item *

$raw == 1 -> Your tag is passed as is to CVS.

=item *

$raw == 0 -> Your tag is assumed to be of the form release_1.23, and is
converted to CVS's form release_1_23.

=back

$dir can be a full path, or relative to the CWD.

=head1 commit($message)

Commit changes.

Called as appropriate by addFile, removeFile and removeDirectory,
so you don't need to call it.

=head1 createRepository()

Create a repository, using the current $CVSROOT.

This involves creating these files:

=over 4

=item *

$ENV{'CVSROOT'}/CVSROOT/modules

=item *

$ENV{'CVSROOT'}/CVSROOT/val-tags

=item *

$ENV{'CVSROOT'}/CVSROOT/history

=back

Notes:

=over 4

=item *

The 'modules' file contains these lines:

	CVSROOT  CVSROOT
	modules  CVSROOT  modules
	$self -> {'project'}  $self -> {'project'}

where $self -> {'project'} comes from the 'project' parameter to new()

=item *

The 'val-tags' file is initially empty

=item *

The 'history' file is only created if the 'history' parameter to new() is set.
The file is initially empty

=back

=head1 getTags()

Return a reference to a list of tags.

See also: the $raw option to new().

C<getTags> does not take a project name because tags belong to the repository
as a whole, not to a project.

=head1 history({})

Report details from the history log, $CVSROOT/CVSROOT/history.

You must have used new({'history' => 1}), or some other mechanism, to create
the history file, before CVS starts logging changes into the history file.

The anonymous hash takes any parameters 'cvs history' takes, and joins them
with a single space. Eg:

	$cvs -> history();

	$cvs -> history({'-e' => ''});

	$cvs -> history({'-xARM' => ''});

	$cvs -> history({'-u' => $ENV{'LOGNAME'}, '-x' => 'A'});

but not

	$cvs -> history({'-xA' => 'M'});

because it doesn't work.

=head1 new({})

Create a new object. See the synopsis.

The anonymous hash takes these parameters, of which 'project' is the
only required one.

=over 4

=item *

'project' => 'killerApp'. The required name of the project. No default

=back

=over 4

=item *

'permissions' => 0775. Unix-specific stuff. Default. Do not use '0775'.

=back

=over 4

=item *

'history' => 0. Do not create $CVSROOT/CVSROOT/history when createRepository() is called. Default

=item *

'history' => 1. Create $CVSROOT/CVSROOT/history, which initiates 'cvs history' stuff

=back

=over 4

=item *

'raw' => 0. Convert tags from CVS format to real format. Eg: release_1.23. Default.

=item *

'raw' => 1. Return tags in raw CVS format. Eg: release_1_23.

=back

=over 4

=item *

'verbose' => 0. Do not report on the progress of mkpath/rmtree

=item *

'verbose' => 1. Report on the progress of mkpath/rmtree. Default

=back

=head1 populate($sourceDir, $vendorTag, $releaseTag, $message)

Import an existing directory structure. But, (sub) import is a reserved word.

Use this to populate a repository for the first time.

The value used for $vendorTag is not important; CVS discards it.

The value used to $releaseTag is important; CVS discards it (why?) but I
force it to be the first tag in $CVSROOT/CVSROOT/val-tags. Thus you
should supply a meaningful value. Thus 'release_0_00' is strongly, repeat
strongly, recommended.

The value of $raw used in the call to new influences the handling of $tag:

=over 4

=item *

$raw == 1 -> Your tag is passed as is to CVS.

=item *

$raw == 0 -> Your tag is assumed to be of the form release_1.23, and is
converted to CVS's form release_1_23.

=back

=head1 removeDirectory($dir)

Remove a directory from the project.

This deletes the directory (and all its files) from your working copy
of the repository, as well as deleting them from the repository.

Warning: $dir will have $CVSROOT and $HOME prepended by this code.
Ie: $dir starts from - but excludes - your home directory
(assuming, of course, you've checked out into your home directory...).

You can't remove the current directory, or a parent.

=head1 removeFile($dir, $file, $message)

Remove a file from the project.

This deletes the file from your working copy of the repository,
as well as deleting it from the repository.

$dir can be a full path, or relative to the CWD.
$file is relative to $dir.

=head1 runOrCroak()

The standard way to run a system command and report on the result.

=head1 setTag($tag)

Tag the repository.

You call setTag, and it calls _setTag.

The value of $raw used in the call to new influences the handling of $tag:

=over 4

=item *

$raw == 1 -> Your tag is passed as is to CVS.

=item *

$raw == 0 -> Your tag is assumed to be of the form release_1.23, and is
converted to CVS's form release_1_23.

=back

=head1 stripCVSDirs($dir)

Delete all CVS directories and files from a copy of the repository.

Each user directory contains a CVS sub-directory, which holds 3 files:

=over 4

=item *

Entries

=item *

Repository

=item *

Root

=back

Zap 'em.

=head1 status()

Run cvs status.

Return a reference to a list of lines.

Only called by upToDate(), but you may call it.

=head1 update($noChange)

Run 'cvs C<-q> [C<-n>] update', returning a reference to a list of lines.
Each line will start with one of [UARMC?], as per the CVS docs.

$cvs -> update(1) is a good way to get a list of uncommited changes, etc.

=over 4

=item *

$noChange == 0 -> Do not add C<-n> to the cvs command. Ie update your working copy

=item *

$noChange == 1 -> Add C<-n> to the cvs command. Do not change any files

=back

=head1 upToDate()

=over 4

=item *

return == 0 -> Repository not up-to-date.

=item *

return == 1 -> Up-to-date.

=back

=head1 _checkOutDontCallMe($readOnly, $tag, $dir)

Checkout a current copy of the project.

You call checkOut, and it calls this.

=over 4

=item *

$readOnly == 0 -> Check out files as read-write.

=item *

$readOnly == 1 -> Check out files as read-only.

=back

=head1 _fixTag($tag)

Fix a tag which CVS failed to add.

Warning: $tag must be in CVS format: release_1_23, not release_1.23.

=head1 _mkpathOrCroak($self, $dir)

There is no need for you to call this.

=head1 _readFile($file)

Return a reference to a list of lines.

There is no need for you to call this.

=head1 _setTag($tag)

Tag the current version of the project.

Warning: $tag must be in CVS format: release_1_23, not release_1.23.

You call setTag and it calls this.

=head1 _validateObject($tag, $file, $mustBeAbsent)

Validate an entry in one of the CVS files 'module' or 'val-tags'.

Warning: $tag must be in CVS format: release_1_23, not release_1.23.

=head1 AUTHOR

C<VCS::CVS> was written by Ron Savage I<E<lt>rpsavage@ozemail.com.auE<gt>> in 1998.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
