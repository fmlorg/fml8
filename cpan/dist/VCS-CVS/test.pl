#!/usr/gnu/bin/perl -w
#
# Name:
#	test.pl.
#
# Purpose:
#	To test $PERL5LIB/VCS/CVS.pm.
#
# Warning:
#	setenv CVSROOT <somethingHarmless> during this.

use integer;
use strict;

use Cwd;
use File::Basename;
use File::Copy;
use File::Path;
use VCS::CVS;

#------------------------------------------------------------------

sub addDirectory
{
	my($cvs, $projectName, $subDirName, $fileName, $addDirMsg,
		$addFileMsg, $verbose, $permissions) = @_;

	&init("$projectName/$subDirName", $fileName, $verbose, $permissions);

	&heading('addDirectory');
	$cvs -> addDirectory($projectName, $subDirName, $addDirMsg);

	print "\n";

	# We can only add a file if we haven't used a sticky tag.
	if ($projectName !~ /Strip/)
	{
		$fileName = fileparse($fileName, '');

		&heading('addFile');
		$cvs -> addFile("$projectName/$subDirName", $fileName, $addFileMsg);

		print "\n";
	}

}	# End of addDirectory.

#------------------------------------------------------------------

sub checkOut
{
	my($cvs, $readOnly, $dirName, $oldTag) = @_;

	&heading('checkOut');
	$cvs -> checkOut($readOnly, $oldTag, $dirName);

	&printDir($dirName);

	print "\n";

}	# End of checkOut.

#------------------------------------------------------------------

sub createRepository
{
	my($cvs, $projectSource, $vendorTag, $releaseTag, $initialMsg) = @_;

	&heading('createRepository');
	$cvs -> createRepository();

	print "\n";

	&heading('populate');
	$cvs -> populate($projectSource, $vendorTag, $releaseTag, $initialMsg);

	print "\n";

}	# End of creatRepository.

#------------------------------------------------------------------

sub getTags
{
	my($cvs) = @_;

	&heading('getTags');
	my($tagRef) = $cvs -> getTags();

	print "Tags: \n";

	for (sort(@$tagRef) )
	{
		print "$_\n";
	}

}	# End of getTags.

#------------------------------------------------------------------

sub heading
{
	my($heading) = @_;

	print "$heading\n";
	print '-' x (length($heading) ), "\n";

}	# End of heading.

#------------------------------------------------------------------

sub init
{
	my($projectSource, $fileName, $verbose, $permissions) = @_;

	my($destination) = "$ENV{'HOME'}/$projectSource";

	&heading("rmtree+mkpath($destination)");
	rmtree($destination, $verbose);
	mkpath($destination, $verbose, $permissions);

	copy($fileName, $destination);

	&printDir($destination);

	print "\n";

}	# End of init.

#------------------------------------------------------------------

sub printDir
{
	my($dirName) = @_;

	opendir(INX, $dirName) || die("Can't opendir($dirName): $!");
	my(@file) = readdir(INX);
	closedir(INX);

	print "Directory: $dirName. Files: \n";

	for (@file)
	{
		print "$_\n";
	}

}	# End of printDir.

#------------------------------------------------------------------

sub setTag
{
	my($cvs, $newTag) = @_;

	# my($cvs, $dirName, $fileName, $newTag) = @_;
	#
	# Edit file, to cause failure of upToDate call within setTag.
	# chdir($dirName) || die(Can't chdir($dirName): $!");
	# my($line) = &readFile($fileName);
	# splice(@$line, 5, 2);
	# &writeFile($fileName, $line);

	&heading('setTag');
	$cvs -> setTag($newTag);

	print "\n";

	&getTags($cvs);

	print "\n";

}	# End of setTag.

#------------------------------------------------------------------

sub strip
{
	my($cvs, $dirName) = @_;

	&heading('stripCVSDirs');
	$cvs -> stripCVSDirs($dirName);

	print "\n";

}	# End of strip.

#------------------------------------------------------------------

sub upToDate
{
	my($cvs) = @_;

	&heading('status');
	my($status) = $cvs -> status();

	print "Status: \n";
	for (@$status)
	{
		print "$_\n";
	}

	print "\n";

	&heading('upToDate');
	my($upToDate) = $cvs -> upToDate();

	print 'The repository is ', ($upToDate ? '' : 'not '), "up-to-date\n";
	print "\n";

}	# End of upToDate.

#------------------------------------------------------------------

my($addDirMsg)		= 'Add directory';
my($addFileMsg)		= 'Add file';
my($dirName)		= 'project';
my($fileName)		= fileparse($0, '');
my($history)		= 1;
my($initialMsg)		= 'Initial version';
my($myself)			= cwd() . "/$fileName";
my($newTag)			= 'release_0.01';
my($noChange)		= 1;
my($nullTag)		= '';
my($permissions)	= 0775;	# But not '0775'!
my($projectName)	= 'project';
my($projectSource)	= 'projectSource';
my($raw)			= 0;
my($readOnly)		= 0;
my($releaseTag)		= 'release_0.00';
my($removeFileMsg)	= 'Remove file';
my($repository)		= 'repository';
my($roDirName)		= 'projectReadOnly';
my($stripDirName)	= 'projectStrip';
my($subDirName)		= 'subDir';
my($vendorTag)		= 'vendorTag';
my($verbose)		= 1;

$ENV{'HOME'}		= cwd();

$ENV{'CVSROOT'}		= "$ENV{'HOME'}/VCS-CVS-test/$repository";

my($cvs)			= VCS::CVS -> new({
						'project'		=> $projectName,
						'raw'			=> $raw,
						'history'		=> $history,
						'permissions'	=> $permissions,
						'verbose'		=> $verbose});

&init($projectSource, $myself, $verbose, $permissions);

chdir($ENV{'HOME'}) || die("Can't chdir($ENV{'HOME'}): $!");

&createRepository($cvs, $projectSource, $vendorTag, $releaseTag, $initialMsg);

&checkOut($cvs, $readOnly, $projectName, $nullTag);
&checkOut($cvs, $readOnly, $stripDirName, $releaseTag);
&checkOut($cvs, (! $readOnly), $roDirName, $releaseTag);

&addDirectory($cvs, $projectName, $subDirName, $myself, $addDirMsg,
	$addFileMsg, $verbose, $permissions);
&addDirectory($cvs, $stripDirName, $subDirName, $myself, $addDirMsg,
	$addFileMsg, $verbose, $permissions);

#&setTag($cvs, $projectName, $fileName, $newTag);
&setTag($cvs, $newTag);

&upToDate($cvs);

print "Update returned: \n", join("\n", @{$cvs -> update($noChange)}), "\n";
print "\n";
print "History returned: \n", join("\n", @{$cvs -> history({'-e' => ''})}), "\n";

&strip($cvs, $stripDirName);

# Success.
exit(0);
