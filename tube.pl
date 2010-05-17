#!/usr/bin/perl

use common::sense;

use Config::General;
use File::HomeDir;
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile rel2abs);
use HTML::TreeBuilder;
use LWP::UserAgent;
use Parallel::ForkManager;
use String::Util qw(trim);

use File::Copy;

my $ua = LWP::UserAgent->new(
	'agent' =>
	'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.8) Gecko/20071023 Firefox/2.0.0.8'); 

my $videoPattern = qr/var videourl="([^"]+)"/;
my $titlePattern = qr/<title>([^-]+).*<\/title>/;

my $configFile = catfile(File::HomeDir->my_home, ".tube");
my $configFile = catfile(File::HomeDir->my_home, "_tube");

# TODO: make linkfile configurable
my $linkFile = "todo.txt";
die "linkfile (", $linkFile, ") not readable" if (!-r $linkFile);
die "linkfile (", $linkFile, ") not writeable" if (!-w _);

my $config = new Config::General($configFile);
my %conf = $config->getall;

my $pm = new Parallel::ForkManager($conf{'MAX_PROCESSES'} or 3);

my $outputDir = eval($conf{'OUTPUT_DIR'});

# links holding all links for pages to parse
my @links;


sub doPage {
	my $url = shift or warn "no url given";

	say "starting: ", $url;

	my $response = $ua->get($url);
	die "error while getting page: " . $response->message
		unless $response->is_success;

	# TODO: handle case, when output file already exists
	$response->content =~ $videoPattern;
	my $videoUrl = $1;
	$response->content =~ $titlePattern;
	my $outputFile = trim($1);

	say "doing: ", $outputFile;

	$outputFile =~ s/ /_/g;
	$outputFile .= ".flv";
	$outputFile = catfile($outputDir, $outputFile);

	make_path($outputDir);

	$response = $ua->get($videoUrl, ':content_file' => $outputFile);
	die "error while getting video: " . $response->message
		unless $response->is_success;
}

$pm->run_on_finish(
	sub {
		my ($pid, $exit_code, $link) = @_;

		say "finished ", $link;

		# save only outstanding links
		@links = grep {!/$link/} @links;
		open my $file, ">", $linkFile or die "can't open linkfile for writing";
		print $file join("\n", @links);
		close $file or die "can't close linkfile";
	}
);

copy("_todo.txt", "todo.txt");
# slurp file and save links into a list
open my $file, "<", $linkFile or die "can't open linkfile for reading";
@links = map {trim($_)} <$file>;
close $file or die "can't close linkfile";

# iterate over the links (we don't use foreach, because it holds an unalterable
# copy of the array, so the changes to the array don't have any effect)
while (my $line = shift @links) {
	my $pid = $pm->start($line) and next;
	doPage(trim($line));
	$pm->finish;
}
$pm->wait_all_children;
