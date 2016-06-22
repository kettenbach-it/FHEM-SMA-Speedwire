#!/usr/bin/perl

################################################################
##
##  Copyright notice
##
##  (c) 2016 Copyright: Volker Kettenbach
##  e-mail: volker at kettenbach minus it dot de
##
##  Credits:
##  - based on an Idea by SpenZerX and HDO
##  - Waldmensch for various improvements
##  - sbfspot (https://sbfspot.codeplex.com/)
##
##  Description:
##  This is a test program for the SMA Sunny Tripower Inverter 
##  with Speedwire (Ethernet) interface (-TL20 or -TL10 with Webconnect piggyback)
##  Tested on Sunny Tripower 6000TL-20, 10000-TL20 and 10000TL-10 with
##  Speedwire/Webconnect Piggyback
##
##  Use this code before you use 77_SMASTP.pm in FHEM to try,
##  if your Sunny Tripower can be quried and if the received values make sense.
##
##  Origin:
##  https://github.com/kettenbach-it/FHEM-SMA-Speedwire
##
#################################################################

use strict;
use warnings;
use IO::Socket::INET;

if (@ARGV < 2) {
	print "Usage $0 <inverterip> <inverteruserpass>\n";
	exit;
}
my $Host = $ARGV[0];
my $port = 9522;
my $Pass = $ARGV[1];

# Global vars
my $cmd_login                   = "534d4100000402a000000001003a001060650ea0ffffffffffff00017800C8E8033800010000000004800c04fdff07000000840300004c20cb5100000000encpw00000000";
my $cmd_logout                  = "534d4100000402a00000000100220010606508a0ffffffffffff00037800C8E80338000300000000d7840e01fdffffffffff00000000";
my $cmd_query_total_today       = "534d4100000402a00000000100260010606509e0ffffffffffff00007800C8E80338000000000000f1b10002005400002600ffff260000000000";
my $cmd_query_spot_ac_power     = "534d4100000402a00000000100260010606509e0ffffffffffff00007800C8E8033800000000000081f00002005100002600ffff260000000000";
my $cmd_query_spot_dc_power     = "534d4100000402a00000000100260010606509e0ffffffffffff00007800C8E8033800000000000081f00002805300002500ffff260000000000";

my $code_login                  = "0d04fdff";   #0xfffd040d;
my $code_total_today            = "01020054";   #0x54000201;
my $code_spot_ac_power          = "01020051";   #0x51000201;
my $code_spot_dc_power          = "01028053";   #0x53800201;

use constant MAXBYTES => scalar 200; #1024 #80

my $encpw = "888888888888888888888888"; # unencoded pw
for my $index (0..length $Pass )        # encode password
{
	substr($encpw,($index*2),2) = substr(sprintf ("%lX", (hex(substr($encpw,($index*2),2)) + ord(substr($Pass,$index,1)))),0,2);
}
$cmd_login =~ s/encpw/$encpw/g;         #replace the placeholder with password

my $socket = new IO::Socket::INET (PeerHost => $Host, PeerPort => $port, Proto => 'udp', Timeout => 2);
if (!$socket) {
	# in case of error
	die "ERROR. Can't open socket to inverter: $!\n";
};

my $end=0;
my $size=0;
my $error=0;
my $SpotPower=0;
my $TodayTotal=0;
my $AlltimeTotal=0;
my $PDC1=0;
my $PDC2=0;
my $code=0;

print "Sending to inverter $Host:9522\n";
print "send: Login, ";
my $data = pack "H*",$cmd_login;
$size = $socket->send($data);
print "$size bytes sent - ";

do
{
	$socket->recv($data, MAXBYTES) or die "recv: $!";
	$size = length($data);
	my $received = unpack("H*", $data);
	print "Received $size bytes: ($received) \n";

	# unpack command
	my $code = unpack("H*", substr $data, 42, 4);
	print "Got code: $code ";

	# answer to command login
	if  ($code_login eq $code)
	{
		print "send: Query total today, ";
		$data = pack "H*",$cmd_query_total_today;
		$size = $socket->send($data);
		print "$size bytes sent - ";
	}

	# answer to command total today
	if  ($code_total_today eq $code)
	{
		$TodayTotal  = unpack("V*", substr $data, 78, 4);
		$AlltimeTotal  = unpack("V*", substr $data, 62, 4);
		print "send: Query spot AC power, ";
		$data = pack "H*",$cmd_query_spot_ac_power;
		$size = $socket->send($data);
		print "$size bytes sent - ";
	}

	# answer to command AC power
	if  ($code_spot_ac_power eq $code)
	{
		$SpotPower  = unpack("V*", substr $data, 62, 4);
		# special case at night ? Inverter off?
		if ($SpotPower eq 0x80000000) {$SpotPower = 0};
		print "send: Query spot DC power, ";
		$data = pack "H*",$cmd_query_spot_dc_power;
		$size = $socket->send($data);
		print "$size bytes sent - ";
	}

	# answer to command DC Power
	if  ($code_spot_dc_power eq $code)
	{
		$PDC1 = unpack("V*", substr $data, 62, 4);
		if ($PDC1 eq 0x80000000) {$PDC1 = 0};
		$PDC2 = unpack("V*", substr $data, 90, 4);
		if ($PDC2 eq 0x80000000) {$PDC2 = 0};
		# send: cmd_logout
		print "send: Logout, ";
		$data = pack "H*",$cmd_logout;
		$size = $socket->send($data);
		print "$size bytes sent.";
		$end=1;
		$socket->close();
	}
} while (($code_spot_dc_power ne $code )); 

print "Results: \n";
print "Today Total: ". $TodayTotal . "\n";
print "All Time Total: " . $AlltimeTotal . "\n";
print "SpotPower: " . $SpotPower . "\n";
print "PDC1: " . $PDC1 . "\n";
print "PDC2: " . $PDC2 . "\n";
