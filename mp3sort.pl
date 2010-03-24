#!/usr/bin/perl

use common::sense;

use Carp;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec::Functions qw(catfile splitdir rel2abs);
use Getopt::Std;
use MP3::Info;

our %options;
my $mp3FilePattern = qr/.+\.mp3$/;
my $yearPattern = qr/(\d{4})/;
my $trackNumPattern = qr/(\d+)/;
my $invalidFilenamePattern = qr/[^A-Za-z0-9 .,_-]/;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
getopts("mn", \%options);

my $outputDirectory = shift @ARGV;
my @sourceDirectories = @ARGV;

# no output directory defined
if (!$outputDirectory) {
	HELP_MESSAGE();
	exit 1;
}

# no source directories defined
if (!@sourceDirectories) {
	HELP_MESSAGE();
	exit 2;
}

# make absolute filenames
$outputDirectory = rel2abs($outputDirectory);
@sourceDirectories = map {rel2abs($_)} @sourceDirectories;

sub HELP_MESSAGE {
	my $progName = fileparse($0);
	print <<EOF
usage: $progName [-m] [-n] <destination directory> <source directory...>
	-m move files instead of copying them
	-n do nothing, just print the computed filenames

There must be at leas one destination directory and one or more source
directories be defined.
EOF
}

sub VERSION_MESSAGE {
	print fileparse($0) . " "
		. "version 0.1 "
		. "by Richard Pöttler "
		. "(richard dot poettler at gmail dot com)\n";
}

sub makeValidFilepart {
	my $string = shift;
	$string =~ s/$invalidFilenamePattern//g;
	return $string;
}

sub analyzeFile {
	if ( -r $File::Find::name
			&& -f _ && $File::Find::name =~ $mp3FilePattern) {
		my $tags = get_mp3tag($File::Find::name);

		# compute the new filename
		my $destFilename = catfile($outputDirectory,
				makeValidFilepart($tags->{"ARTIST"}),
				makeValidFilepart($tags->{"ALBUM"}),
				makeValidFilepart(sprintf("%.2d %s.mp3",
						$tags->{"TRACKNUM"},
						$tags->{"TITLE"})));
		my (undef, $destDir) = fileparse($destFilename);
		print $destFilename, "\n";

		# return, if we only have to print the filename
		return if ($options{"n"});

		# create the directory and copy/move the file
		if (! -d $destDir) {
			mkpath($destDir)
				or croak "Can't create dir: " . $destDir;
		}
		if ($options{"m"}) {
			move($File::Find::name, $destFilename)
				or croak "Move failed: $!";
		} else {
			copy($File::Find::name, $destFilename)
				or croak "Copy failed: $!";
		}

		# set the corrected mp3 tags
		set_mp3tag($destFilename, $tags);
	}
}

find(\&analyzeFile, @sourceDirectories);
