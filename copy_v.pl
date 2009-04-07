#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;
use File::Path;
use File::Spec::Functions;

my @sourceDirectories = (catdir(qw/t: pcssw teiln pcs-por prog/),
	catdir(qw/v: pcssw base prog/),
	catdir(qw/v: pcssw pati prog/));
my $destinationDirectory = catdir(qw/v: teiln pcs-por prog/);
my $compileFileName = catfile(qw/t: pcssw teiln pcs-por richi compile.txt/);

my $compileLinePattern = qr/\s*compile\s+(\S+)\s+/i;

print "destination directory: ", $destinationDirectory, "\n";
if (! -d $destinationDirectory) {
	mkpath($destinationDirectory)
		or die "couldn't create directory " . $destinationDirectory . ": " . $!;
}

open my $compileFile, "<", $compileFileName
	or die "couldn't open " . $compileFileName . ": " . $!;
for my $line (<$compileFile>) {
	if ($line =~ $compileLinePattern) {
		for my $sourceDirectory (@sourceDirectories) {
			my $sourceFile = catfile($sourceDirectory, $1);
			if (-r $sourceFile) {
				print "copying ", $sourceFile, "\n";
				copy($sourceFile, $destinationDirectory);
				last;
			}
		}
	}
}
close $compileFile
	or die "couldn't close " . $compileFileName . ": " . $!;
