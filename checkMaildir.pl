#!/usr/bin/perl -s
# author: 	Richard Pöttler (richard dot poettler at gmail dot com)
# date:		2006 dec 14
# description:	checks how many new mails are in a maildir mailbox
# $Id: checkMaildir.pl,v 1.8 2007/09/06 07:56:42 richi Exp $

use strict;
use warnings;

use File::Find;

our ($s, $h, $l);

my @dirs = @ARGV || ($ENV{"HOME"} . "/Mail");
my %newMails = ();
my $newDirPat = qr/^.*\/new$/;
my $folderPat;

sub printHelp() {
	print << "EOF"
usage: $0 [-h|-s|-l] [directories...]

	checks [directories...] for new mails

	-s prints only the number of new mails
	-l prints the number of new messages an folders contining them on one line
	-h prints this help message
EOF
}

sub searchNew {
	if ($File::Find::dir =~ /$newDirPat/) {
		$File::Find::dir =~ /$folderPat/;
		$newMails{$1}++;
	}
}

if ($h) {
	printHelp();
	exit;
}

foreach my $dir (@dirs) {
	$folderPat = qr/^$dir\/(.*)\/new$/;
	find(\&searchNew, $dir);
}

if ($s) { # choosed short format
	my $n = 0;
	$n += $_ foreach (values %newMails);
	print $n . "\n";
} else {
	if ($l) {
		while ((my $key, my $value) = each %newMails) {
			print $key . ": " . $value . "  ";
		}
	} else {
		while ((my $key, my $value) = each %newMails) {
			print $value . "\t " . $key . "\n";
		}
	}
}
