#!/usr/bin/perl

use strict;
use warnings;

use Config::General;
use Date::Format;
use LWP::UserAgent;
use XML::LibXML::XPathContext;
use XML::LibXML;

my $conf = new Config::General($ENV{'HOME'} . "/.getip.conf");
my %config = $conf->getall;

my $ua = LWP::UserAgent->new;
$ua->credentials($config{'ip'} . ":" . $config{'port'}, $config{'realm'}, $config{'user'}, $config{'pwd'});
my $res = $ua->get("http://" . $config{'ip'} . "/s_status.htm");
$res->is_success or die $res->status_line . "\n";

my $xpath = "/html/body/form/table/tr/td/b[text() = 'IP-Adresse']/../following-sibling::*[text() != '" . $config{'ip'} . "']/text()";
my $doc = XML::LibXML->new->parse_html_string($res->content);
my $ip = XML::LibXML::XPathContext->new->findvalue($xpath, $doc);
print time2str("%Y%m%d-%T", time) . " " if ($config{'date'});
print $ip . "\n";

__END__

=head1 getip - get the ip address of the router

=head2 Description

This script logins into a given router, determines it's external ip address and prints it out.

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

=item date

Set to C<1> if the date should be printed out

=back
