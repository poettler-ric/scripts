#!/usr/bin/perl

use strict;
use warnings;

use Config::General;
use Date::Format;
use LWP::UserAgent;
use Mail::Mailer;
use XML::LibXML;
use XML::LibXML::XPathContext;

my $conf = new Config::General($ENV{'HOME'} . "/.getip.conf");
my %config = $conf->getall;

my $ua = LWP::UserAgent->new;
$ua->credentials($config{'ip'} . ":" . $config{'port'}, $config{'realm'}, $config{'user'}, $config{'pwd'});
my $res = $ua->get("http://" . $config{'ip'} . "/setup.cgi?next_file=Status.htm");
$res->is_success or die $res->status_line . "\n";

my $xpath = "/html/body/form/div/table/tr/td/table/tr/td[text() = 'IP-Adresse:']/following-sibling::td";
my $doc = XML::LibXML->new->parse_html_string($res->content);
my $ip = XML::LibXML::XPathContext->new->findvalue($xpath, $doc);

# print ip to stdout
if ($config{'print'}) {
	print time2str("%Y%m%d-%T", time), " " if ($config{'date'});
	print $ip, "\n";
}

# send ip per mail
if ($config{'mailto'}) {
	my $mail = Mail::Mailer->new('sendmail');
	$mail->open({To => $config{'mailto'}, From => $config{'mailfrom'}, Subject => "IP"});
	print $mail $ip;
	$mail->close;
}

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

=item print

Print the ip to C<STDOUT>

=item date

Set to C<1> if the date should be printed out

=item mailto

If specified the program will try to send a mail to this email address with C<sendmail>

=item mailfrom

The sender for the mail sent

=back
