#!/usr/bin/perl

use strict;
use warnings;

use Config::General;
use Date::Format;
use LWP::UserAgent;
use Mail::Mailer;
use XML::LibXML;
use XML::LibXML::XPathContext;

my $ipFile = $ENV{'HOME'} . "/.getip.lastip";
my $configFile = $ENV{'HOME'} . "/.getip.conf";

# writes a ip to the ip file
sub readIp {
	return "" if (! -r $ipFile);

	open my $file, "<", $ipFile or die "Couldn't open file:\n" . $!;
	my $ip = <$file>;
	close $file or die "Couldn't close file:\n" . $!;
	chomp $ip;
	return $ip;
}

# reads the ip from the ip file
sub writeIp {
	my $ip = shift || die "A ip to write must be given.";
	open my $file, ">", $ipFile or die "Couldn't open file:\n" . $!;
	print $file $ip;
	close $file or die "Couldn't close file:\n" . $!;
}

my $conf = new Config::General($configFile);
my %config = $conf->getall;

my $ua = LWP::UserAgent->new;
$ua->credentials($config{'ip'} . ":" . $config{'port'}, $config{'realm'}, $config{'user'}, $config{'pwd'});
my $res = $ua->get("http://" . $config{'ip'} . "/setup.cgi?next_file=Status.htm");
$res->is_success or die $res->status_line . "\n";

my $xpath = "/html/body/form/div/table/tr/td/table/tr/td[text() = 'IP-Adresse:']/following-sibling::td";
my $doc = XML::LibXML->new->parse_html_string($res->content);
my $ip = XML::LibXML::XPathContext->new->findvalue($xpath, $doc);

my $lastip = readIp;

# print ip to stdout
if ($config{'print'} && !($config{'onlychanged'} && $ip eq $lastip)) {
	print time2str("%Y%m%d-%T", time), " " if ($config{'date'});
	print $ip, "\n";
}

# send ip per mail
if ($config{'mailto'} && !($config{'onlychanged'} && $ip eq $lastip)) {
	my $mail = Mail::Mailer->new('sendmail');
	$mail->open({To => $config{'mailto'}, From => $config{'mailfrom'}, Subject => "IP"});
	print $mail $ip;
	$mail->close;
}

writeIp($ip);

__END__

=head1 getip - get the ip address of the router

=head2 Description

This script logins into a given router, determines it's external ip. According
to the configuration it prints the ip to stdout or sends it per mail.

=head2 Configuration

This script is configured with a property file at F<~/.getip.conf>. The
properties are written as C<name=value>. Available options are:

=over

=item ip

The internal ip address of the router

=item port

the port of the routers web interface

=item realm

The real in which to login

=item user

The username to use

=item pwd

The user's password

=item onlychanged

Do the actions (pringing, mailing, ...) only, if the ip has changed

=item print

Print the ip to C<STDOUT>

=item date

Set to C<1> if the date should be printed out

=item mailto

If specified the program will try to send a mail to this email address with C<sendmail>

=item mailfrom

The sender for the mail sent

=back
