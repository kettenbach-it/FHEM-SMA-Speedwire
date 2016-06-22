#!/usr/bin/perl

################################################################
##
##  Copyright notice
##
##  (c) 2016 Copyright: Volker Kettenbach
##  e-mail: volker at kettenbach minus it dot de
##
##  Description:
##  This is a test program for the SMA Energy Meter,
##  a bidirectional energy meter/counter used in photovoltaics.
##  Use this code before you use 77_SMAEM.pm in FHEM to try, 
##  if your SMAEM multicast is by received by your host
##  and if the received values make sense.
##
##  It's very extensive code, to show, how the SMAEM works
##
##  Requirements:
##  This module requires:
##  - Perl Module: IO::Socket::Multicast
##  On a Debian (based) system, these requirements can be fullfilled by:
##  - apt-get install libio-socket-multicast-perl
##
##  Origin:
##  https://github.com/kettenbach-it/FHEM-SMA-Speedwire
##
#################################################################

use strict;
use warnings;
use bignum;

use IO::Socket::Multicast;

my $socket = IO::Socket::Multicast->new(
	Proto     => 'udp',
	LocalPort => '9522',
) or die "Can't bind : $@\n";

$socket->mcast_add('239.12.255.254');

while (1) {
	# Format of the udp packets of the SMAEM:
	# http://www.sma.de/fileadmin/content/global/Partner/Documents/SMA_Labs/EMETER-Protokoll-TI-de-10.pdf
	# http://www.eb-systeme.de/?page_id=1240

	# Conversion like in this python code:
	# http://www.unifox.at/sma_energy_meter/
	# https://github.com/datenschuft/SMA-EM
	
	my $data;
	$socket->recv($data, 600);	# Each SMAEM packet is 600 bytes of packed payload

	# unpack big-endian to 2-digit hex (bin2hex)
	my $hex=unpack('H*', $data);	

	# Extract datasets from hex:
	# Generic:
	my $susyid=hex(substr($hex,36,4));
	my $smaserial=hex(substr($hex,40,8));
	my $milliseconds=hex(substr($hex,48,8));

	# Counter Divisor: [Hex-Value]=Ws => Ws/1000*3600=kWh => divide by 3600000
	
	# Sum L1-3
	my $bezug_wirk=hex(substr($hex,64,8))/10;
	my $bezug_wirk_count=hex(substr($hex,80,16))/3600000;
	my $einspeisung_wirk=hex(substr($hex,104,8))/10;
	my $einspeisung_wirk_count=hex(substr($hex,120,16))/3600000;

	my $bezug_blind=hex(substr($hex,144,8))/10;
	my $bezug_blind_count=hex(substr($hex,160,16))/3600000;
	my $einspeisung_blind=hex(substr($hex,184,8))/10;
	my $einspeisung_blind_count=hex(substr($hex,200,16))/3600000;

	my $bezug_schein=hex(substr($hex,224,8))/10;
	my $bezug_schein_count=hex(substr($hex,240,16))/3600000;
	my $einspeisung_schein=hex(substr($hex,264,8))/10;
	my $einspeisung_schein_count=hex(substr($hex,280,16))/3600000;

	my $cosphi=hex(substr($hex,304,8))/1000;

	# L1
	my $l1_bezug_wirk=hex(substr($hex,320,8))/10;
	my $l1_bezug_wirk_count=hex(substr($hex,336,16))/3600000;
	my $l1_einspeisung_wirk=hex(substr($hex,360,8))/10;
	my $l1_einspeisung_wirk_count=hex(substr($hex,376,16))/3600000;

	my $l1_bezug_blind=hex(substr($hex,400,8))/10;	
	my $l1_bezug_blind_count=hex(substr($hex,416,16))/3600000;
	my $l1_einspeisung_blind=hex(substr($hex,440,8))/10;	
	my $l1_einspeisung_blind_count=hex(substr($hex,456,16))/3600000;

	my $l1_bezug_schein=hex(substr($hex,480,8))/10;	
	my $l1_bezug_schein_count=hex(substr($hex,496,16))/3600000;
	my $l1_einspeisung_schein=hex(substr($hex,520,8))/10;	
	my $l1_einspeisung_schein_count=hex(substr($hex,536,16))/3600000;

	my $l1_thd=hex(substr($hex,560,8))/1000;
	my $l1_v=hex(substr($hex,576,8))/1000;
	my $l1_cosphi=hex(substr($hex,592,8))/1000;

	# L2
	my $l2_bezug_wirk=hex(substr($hex,608,8))/10;
	my $l2_bezug_wirk_count=hex(substr($hex,624,16))/3600000;
	my $l2_einspeisung_wirk=hex(substr($hex,648,8))/10;	
	my $l2_einspeisung_wirk_count=hex(substr($hex,664,16))/3600000;	

	my $l2_bezug_blind=hex(substr($hex,688,8))/10;	
	my $l2_bezug_blind_count=hex(substr($hex,704,16))/3600000;
	my $l2_einspeisung_blind=hex(substr($hex,728,8))/10;	
	my $l2_einspeisung_blind_count=hex(substr($hex,744,16))/3600000;

	my $l2_bezug_schein=hex(substr($hex,768,8))/10;	
	my $l2_bezug_schein_count=hex(substr($hex,784,16))/3600000;
	my $l2_einspeisung_schein=hex(substr($hex,808,8))/10;	
	my $l2_einspeisung_schein_count=hex(substr($hex,824,16))/3600000;

	my $l2_thd=hex(substr($hex,848,8))/1000;
	my $l2_v=hex(substr($hex,864,8))/1000;
	my $l2_cosphi=hex(substr($hex,880,8))/1000;

	# L3
	my $l3_bezug_wirk=hex(substr($hex,896,8))/10;
	my $l3_bezug_wirk_count=hex(substr($hex,912,16))/3600000;
	my $l3_einspeisung_wirk=hex(substr($hex,936,8))/10;	
	my $l3_einspeisung_wirk_count=hex(substr($hex,952,16))/3600000;	

	my $l3_bezug_blind=hex(substr($hex,976,8))/10;	
	my $l3_bezug_blind_count=hex(substr($hex,992,16))/3600000;
	my $l3_einspeisung_blind=hex(substr($hex,1016,8))/10;	
	my $l3_einspeisung_blind_count=hex(substr($hex,1032,16))/3600000;

	my $l3_bezug_schein=hex(substr($hex,1056,8))/10;
	my $l3_bezug_schein_count=hex(substr($hex,1072,16))/3600000;
	my $l3_einspeisung_schein=hex(substr($hex,1096,8))/10;	
	my $l3_einspeisung_schein_count=hex(substr($hex,1112,16))/3600000;

	my $l3_thd=hex(substr($hex,1136,8))/1000;
	my $l3_v=hex(substr($hex,1152,8))/1000;
	my $l3_cosphi=hex(substr($hex,1168,8))/1000;


	# Prepare as text
	my $bezug_wirk_s=sprintf("%.1f", $bezug_wirk);
	my $bezug_wirk_count_s=sprintf("%.1f", $bezug_wirk_count);
	my $einspeisung_wirk_s=sprintf("%.1f", $einspeisung_wirk);
	my $einspeisung_wirk_count_s=sprintf("%.1f", $einspeisung_wirk_count);
	my $bezug_blind_s=sprintf("%.1f", $bezug_blind);
	my $bezug_blind_count_s=sprintf("%.1f", $bezug_blind_count);
	my $einspeisung_blind_s=sprintf("%.1f", $einspeisung_blind);
	my $einspeisung_blind_count_s=sprintf("%.1f", $einspeisung_blind_count);
	my $bezug_schein_s=sprintf("%.1f", $bezug_schein);
	my $bezug_schein_count_s=sprintf("%.1f", $bezug_schein_count);
	my $einspeisung_schein_s=sprintf("%.1f", $einspeisung_schein);
	my $einspeisung_schein_count_s=sprintf("%.1f", $einspeisung_schein_count);
	my $cosphi_s=sprintf("%.3f", $cosphi);

	my $l1_bezug_wirk_s=sprintf("%.1f", $l1_bezug_wirk);
	my $l1_bezug_wirk_count_s=sprintf("%.1f", $l1_bezug_wirk_count);
	my $l1_einspeisung_wirk_s=sprintf("%.1f", $l1_einspeisung_wirk);
	my $l1_einspeisung_wirk_count_s=sprintf("%.1f", $l1_einspeisung_wirk_count);
	my $l1_bezug_blind_s=sprintf("%.1f", $l1_bezug_blind);
	my $l1_bezug_blind_count_s=sprintf("%.1f", $l1_bezug_blind_count);
	my $l1_einspeisung_blind_s=sprintf("%.1f", $l1_einspeisung_blind);
	my $l1_einspeisung_blind_count_s=sprintf("%.1f", $l1_einspeisung_blind_count);
	my $l1_bezug_schein_s=sprintf("%.1f", $l1_bezug_schein);
	my $l1_bezug_schein_count_s=sprintf("%.1f", $l1_bezug_schein_count);
	my $l1_einspeisung_schein_s=sprintf("%.1f", $l1_einspeisung_schein);
	my $l1_einspeisung_schein_count_s=sprintf("%.1f", $l1_einspeisung_schein_count);
	my $l1_cosphi_s=sprintf("%.3f", $l1_cosphi);
	my $l1_thd_s=sprintf("%.2f", $l1_thd);
	my $l1_v_s=sprintf("%.1f", $l1_v);

	my $l2_bezug_wirk_s=sprintf("%.1f", $l2_bezug_wirk);
	my $l2_bezug_wirk_count_s=sprintf("%.1f", $l2_bezug_wirk_count);
	my $l2_einspeisung_wirk_s=sprintf("%.1f", $l2_einspeisung_wirk);
	my $l2_einspeisung_wirk_count_s=sprintf("%.1f", $l2_einspeisung_wirk_count);
	my $l2_bezug_blind_s=sprintf("%.1f", $l2_bezug_blind);
	my $l2_bezug_blind_count_s=sprintf("%.1f", $l2_bezug_blind_count);
	my $l2_einspeisung_blind_s=sprintf("%.1f", $l2_einspeisung_blind);
	my $l2_einspeisung_blind_count_s=sprintf("%.1f", $l2_einspeisung_blind_count);
	my $l2_bezug_schein_s=sprintf("%.1f", $l2_bezug_schein);
	my $l2_bezug_schein_count_s=sprintf("%.1f", $l2_bezug_schein_count);
	my $l2_einspeisung_schein_s=sprintf("%.1f", $l2_einspeisung_schein);
	my $l2_einspeisung_schein_count_s=sprintf("%.1f", $l2_einspeisung_schein_count);
	my $l2_cosphi_s=sprintf("%.3f", $l2_cosphi);
	my $l2_thd_s=sprintf("%.2f", $l2_thd);
	my $l2_v_s=sprintf("%.1f", $l2_v);

	my $l3_bezug_wirk_s=sprintf("%.1f", $l3_bezug_wirk);
	my $l3_bezug_wirk_count_s=sprintf("%.1f", $l3_bezug_wirk_count);
	my $l3_einspeisung_wirk_s=sprintf("%.1f", $l3_einspeisung_wirk);
	my $l3_einspeisung_wirk_count_s=sprintf("%.1f", $l3_einspeisung_wirk_count);
	my $l3_bezug_blind_s=sprintf("%.1f", $l3_bezug_blind);
	my $l3_bezug_blind_count_s=sprintf("%.1f", $l3_bezug_blind_count);
	my $l3_einspeisung_blind_s=sprintf("%.1f", $l3_einspeisung_blind);
	my $l3_einspeisung_blind_count_s=sprintf("%.1f", $l3_einspeisung_blind_count);
	my $l3_bezug_schein_s=sprintf("%.1f", $l3_bezug_schein);
	my $l3_bezug_schein_count_s=sprintf("%.1f", $l3_bezug_schein_count);
	my $l3_einspeisung_schein_s=sprintf("%.1f", $l3_einspeisung_schein);
	my $l3_einspeisung_schein_count_s=sprintf("%.1f", $l3_einspeisung_schein_count);
	my $l3_cosphi_s=sprintf("%.3f", $l3_cosphi);
	my $l3_thd_s=sprintf("%.2f", $l3_thd);
	my $l3_v_s=sprintf("%.1f", $l3_v);


	# Output to console
	print "Seriennummer: $smaserial \n";
	print "Update: $milliseconds \n";

	print "L1:\n";
	print "\tBezug Wirkleistung (W): $l1_bezug_wirk_s \n";
	print "\tBezug Wirkleistung Zähler (kWh): $l1_bezug_wirk_count_s \n";
	print "\tEinspeisung Wirkleistung (W): $l1_einspeisung_wirk_s \n";
	print "\tEinspeisung Wirkleistung Zähler (kWh): $l1_einspeisung_wirk_count_s \n";
	print "\n";
	print "\tBezug Blindleistung (var): $l1_bezug_blind_s \n";
	print "\tBezug Blindleistung Zähler (kvarh): $l1_bezug_blind_count_s \n";
	print "\tEinspeisung Blindleistung (var): $l1_einspeisung_blind_s \n";
	print "\tEinspeisung Blindleistung Zähler (kvarh): $l1_einspeisung_blind_count_s \n";
	print "\n";
	print "\tBezug Scheinleistung (VA): $l1_bezug_schein_s \n";
	print "\tBezug Scheinleistung Zähler (kVAh): $l1_bezug_schein_count_s \n";
	print "\tEinspeisung Scheinleistung (VA): $l1_einspeisung_schein_s \n";
	print "\tEinspeisung Scheinleistung Zähler (kVAh): $l1_einspeisung_schein_count_s \n";
	print "\n";
	print "\tCosPhi: $l1_cosphi_s\n";
	print "\tTHD: $l1_thd_s\n";
	print "\tSpannung (V): $l1_v_s";
	print "\n";

	print "L2:\n";
	print "\tBezug Wirkleistung (W): $l2_bezug_wirk_s \n";
	print "\tBezug Wirkleistung Zähler (kWh): $l2_bezug_wirk_count_s \n";
	print "\tEinspeisung Wirkleistung (W): $l2_einspeisung_wirk_s \n";
	print "\tEinspeisung Wirkleistung Zähler (kWh): $l2_einspeisung_wirk_count_s \n";
	print "\n";
	print "\tBezug Blindleistung (var): $l2_bezug_blind_s \n";
	print "\tBezug Blindleistung Zähler (kvarh): $l2_bezug_blind_count_s \n";
	print "\tEinspeisung Blindleistung (var): $l2_einspeisung_blind_s \n";
	print "\tEinspeisung Blindleistung Zähler (kvarh): $l2_einspeisung_blind_count_s \n";
	print "\n";
	print "\tBezug Scheinleistung (VA): $l2_bezug_schein_s \n";
	print "\tBezug Scheinleistung Zähler (kVAh): $l2_bezug_schein_count_s \n";
	print "\tEinspeisung Scheinleistung (VA): $l2_einspeisung_schein_s \n";
	print "\tEinspeisung Scheinleistung Zähler (kVAh): $l2_einspeisung_schein_count_s \n";
	print "\n";
	print "\tCosPhi: $l2_cosphi_s\n";
	print "\tTHD: $l2_thd_s\n";
	print "\tSpannung (V): $l2_v_s";
	print "\n";

	print "L3:\n";
	print "\tBezug Wirkleistung (W): $l3_bezug_wirk_s \n";
	print "\tBezug Wirkleistung Zähler (kWh): $l3_bezug_wirk_count_s \n";
	print "\tEinspeisung Wirkleistung (W): $l3_einspeisung_wirk_s \n";
	print "\tEinspeisung Wirkleistung Zähler (kWh): $l3_einspeisung_wirk_count_s \n";
	print "\n";
	print "\tBezug Blindleistung (var): $l3_bezug_blind_s \n";
	print "\tBezug Blindleistung Zähler (kvarh): $l3_bezug_blind_count_s \n";
	print "\tEinspeisung Blindleistung (var): $l3_einspeisung_blind_s \n";
	print "\tEinspeisung Blindleistung Zähler (kvarh): $l3_einspeisung_blind_count_s \n";
	print "\n";
	print "\tBezug Scheinleistung (VA): $l3_bezug_schein_s \n";
	print "\tBezug Scheinleistung Zähler (kVAh): $l3_bezug_schein_count_s \n";
	print "\tEinspeisung Scheinleistung (VA): $l3_einspeisung_schein_s \n";
	print "\tEinspeisung Scheinleistung Zähler (kVAh): $l3_einspeisung_schein_count_s \n";
	print "\n";
	print "\tCosPhi: $l3_cosphi_s\n";
	print "\tTHD: $l3_thd_s\n";
	print "\tSpannung (V): $l3_v_s";
	print "\n";
	print "\n";
	
	print "Alle Phasen: \n";
	print "\tBezug Wirkleistung (W): $bezug_wirk_s \n";
	print "\tBezug Wirkleistung Zähler (kWh): $bezug_wirk_count_s \n";
	print "\tEinspeisung Wirkleistung (W): $einspeisung_wirk_s \n";
	print "\tEinspeisung Wirkleistung Zähler (kWh): $einspeisung_wirk_count_s \n";
	print "\n";
	print "\tBezug Blindleistung (var): $bezug_blind_s \n";
	print "\tBezug Blindleistung Zähler (kvarh): $bezug_blind_count_s \n";
	print "\tEinspeisung Blindleistung (var): $einspeisung_blind_s \n";
	print "\tEinspeisung Blindleistung Zähler (kvarh): $einspeisung_blind_count_s \n";
	print "\n";
	print "\tBezug Scheinleistung (VA): $bezug_schein_s \n";
	print "\tBezug Scheinleistung Zähler (kVA): $bezug_schein_count_s \n";
	print "\tEinspeisung Scheinleistung (VA): $einspeisung_schein_s \n";
	print "\tEinspeisung Scheinleistung Zähler (kVA): $einspeisung_schein_count_s \n";
	print "\n";
	print "\tCosPhi: $cosphi_s";
	print "\n";

	print "\n";

	# Check for plausibity - in my case, this does not work out every time.... don't know why
	print "Plausichecks:\n";
	my $sum = $l1_bezug_wirk + $l2_bezug_wirk + $l3_bezug_wirk;
	print "\tBezug Wirkleistung: $l1_bezug_wirk_s + $l2_bezug_wirk_s + $l3_bezug_wirk_s = $sum ? == $bezug_wirk_s\n";
	$sum = $l1_bezug_wirk_count + $l2_bezug_wirk_count + $l3_bezug_wirk_count;
	print "\tBezug Wirkleistung Zähler: $l1_bezug_wirk_count_s + $l2_bezug_wirk_count_s + $l3_bezug_wirk_count_s = $sum ?== $bezug_wirk_count_s\n";
	print "\n";
	$sum = $l1_einspeisung_wirk + $l2_einspeisung_wirk + $l3_einspeisung_wirk;
	print "\tEinspeisung Wirkleistung: $l1_einspeisung_wirk_s + $l2_einspeisung_wirk_s + $l3_einspeisung_wirk_s = $sum ? == $einspeisung_wirk_s\n";
	$sum = $l1_einspeisung_wirk_count + $l2_einspeisung_wirk_count + $l3_einspeisung_wirk_count;
	print "\tBezug Wirkleistung Zähler: $l1_einspeisung_wirk_count_s + $l2_einspeisung_wirk_count_s + $l3_einspeisung_wirk_count_s = $sum ?== $einspeisung_wirk_count_s\n";
	print "\n";
	$sum = $einspeisung_wirk + $einspeisung_blind;
	print "\tEinspeisung Leistung $einspeisung_wirk_s + $einspeisung_blind_s = $sum ?== $einspeisung_schein_s\n"; 
	$sum = $bezug_wirk + $bezug_blind;
	print "\tBezug Leistung $bezug_wirk_s + $bezug_blind_s = $sum ?== $bezug_schein_s\n"; 
	print "\n";


}

