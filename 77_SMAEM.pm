################################################################
#
#  Copyright notice
#
#  (c) 2016 Copyright: Volker Kettenbach
#  e-mail: volker at kettenbach minus it dot de
#
#  Description:
#  This is an FHEM-Module for the SMA Energy Meter, 
#  a bidirectional energy meter/counter used in photovoltaics
#
#  Requirements:
#  This module requires:
#  - Perl Module: IO::Socket::Multicast
#  On a Debian (based) system, these requirements can be fullfilled by:
#  - apt-get install install libio-socket-multicast-perl
#
#  Origin:
#  https://github.com/kettenbach-it/FHEM-SMAEM
#
################################################################

package main;

use strict;
use warnings;
use bignum;

use IO::Socket::Multicast;

#####################################
sub
SMAEM_Initialize($)
{
  my ($hash) = @_;
  
  $hash->{ReadFn}  = "SMAEM_Read";
  $hash->{DefFn}   = "SMAEM_Define";
  $hash->{UndefFn} = "SMAEM_Undef";
  #$hash->{WriteFn} = "SMAEM_Write";
  #$hash->{ReadyFn} = "SMAEM_Ready";
  #$hash->{GetFn}   = "SMAEM_Get";
  #$hash->{SetFn}   = "SMAEM_Set";
  #$hash->{AttrFn}  = "SMAEM_Attr";
  $hash->{AttrList}= "$readingFnAttributes";
}

#####################################
sub
SMAEM_Define($$)
{
  my ($hash, $def) = @_;
  my $name= $hash->{NAME};
  
  my @a = split(/\s+/, $def);
  my $interval = 60;
  $interval = $a[2] if($a[2]);
  $hash->{INTERVAL}=$interval;
  $hash->{LASTUPDATE}=0;

  Log3 $hash, 3, "$name: Opening multicast socket...";
  my $socket = IO::Socket::Multicast->new(
    Proto     => 'udp',
    LocalPort => '9522',
  ) or return "Can't bind : $@";
  
  $socket->mcast_add('239.12.255.254');

  $hash->{TCPDev}= $socket;
  $hash->{FD} = $socket->fileno();
  delete($readyfnlist{"$name"});
  $selectlist{"$name"} = $hash;

  return undef;
}


#####################################
sub
SMAEM_Undef($$)
{
  my ($hash, $arg) = @_;
  my $name= $hash->{NAME};
  my $socket= $hash->{TCPDev};
  Log3 $hash, 3, "$name: Closing multicast socket...";
  $socket->mcast_drop('239.12.255.254');
  $socket->close;

  return undef;
}

#####################################
# called from the global loop, when the select for hash->{FD} reports data
sub SMAEM_Read($) 
{
  my ($hash) = @_;
  my $name= $hash->{NAME};
  my $socket= $hash->{TCPDev};

  my $data;
  return unless $socket->recv($data, 600); # Each SMAEM packet is 600 bytes of packed payload
  Log3 $hash, 5, "$name: Received " . length($data) . " bytes.";

  if ($hash->{LASTUPDATE}==0 | time() >= $hash->{LASTUPDATE}+$hash->{INTERVAL}){
    readingsBeginUpdate($hash);
    # Format of the udp packets of the SMAEM:
    # http://www.sma.de/fileadmin/content/global/Partner/Documents/SMA_Labs/EMETER-Protokoll-TI-de-10.pdf
    # http://www.eb-systeme.de/?page_id=1240

    # Conversion like in this python code:
    # http://www.unifox.at/sma_energy_meter/
    # https://github.com/datenschuft/SMA-EM

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
    readingsBulkUpdate($hash, "state", sprintf("%.1f", $einspeisung_wirk-$bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Saldo_Wirkleistung", sprintf("%.1f",$einspeisung_wirk-$bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Saldo_Wirkleistung_Zaehler", sprintf("%.1f",$einspeisung_wirk_count-$bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Bezug_Wirkleistung", sprintf("%.1f",$bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Bezug_Wirkleistung_Zaehler", sprintf("%.1f",$bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Einspeisung_Wirkleistung", sprintf("%.1f",$einspeisung_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Einspeisung_Wirkleistung_Zaehler", sprintf("%.1f",$einspeisung_wirk_count));
  
    my $bezug_blind=hex(substr($hex,144,8))/10;
    my $bezug_blind_count=hex(substr($hex,160,16))/3600000;
    my $einspeisung_blind=hex(substr($hex,184,8))/10;
    my $einspeisung_blind_count=hex(substr($hex,200,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Bezug_Blindleistung", sprintf("%.1f",$bezug_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Bezug_Blindleistung_Zaehler", sprintf("%.1f",$bezug_blind_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Einspeisung_Blindleistung", sprintf("%.1f",$einspeisung_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Einspeisung_Blindleistung_Zaehler", sprintf("%.1f",$einspeisung_blind_count));

    my $bezug_schein=hex(substr($hex,224,8))/10;
    my $bezug_schein_count=hex(substr($hex,240,16))/3600000;
    my $einspeisung_schein=hex(substr($hex,264,8))/10;
    my $einspeisung_schein_count=hex(substr($hex,280,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Bezug_Scheinleistung", sprintf("%.1f",$bezug_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Bezug_Scheinleistung_Zaehler", sprintf("%.1f",$bezug_schein_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Einspeisung_Scheinleistung", sprintf("%.1f",$einspeisung_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_Einspeisung_Scheinleistung_Zaehler", sprintf("%.1f",$einspeisung_schein_count));

    my $cosphi=hex(substr($hex,304,8))/1000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_CosPhi", sprintf("%.3f",$cosphi));

    # L1
    my $l1_bezug_wirk=hex(substr($hex,320,8))/10;
    my $l1_bezug_wirk_count=hex(substr($hex,336,16))/3600000;
    my $l1_einspeisung_wirk=hex(substr($hex,360,8))/10;
    my $l1_einspeisung_wirk_count=hex(substr($hex,376,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Saldo_Wirkleistung", sprintf("%.1f",$l1_einspeisung_wirk-$l1_bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Saldo_Wirkleistung_Zaehler", sprintf("%.1f",$l1_einspeisung_wirk_count-$l1_bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Bezug_Wirkleistung", sprintf("%.1f",$l1_bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Bezug_Wirkleistung_Zaehler", sprintf("%.1f",$l1_bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Einspeisung_Wirkleistung", sprintf("%.1f",$l1_einspeisung_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Einspeisung_Wirkleistung_Zaehler", sprintf("%.1f",$l1_einspeisung_wirk_count));
 
    my $l1_bezug_blind=hex(substr($hex,400,8))/10;
    my $l1_bezug_blind_count=hex(substr($hex,416,16))/3600000;
    my $l1_einspeisung_blind=hex(substr($hex,440,8))/10;
    my $l1_einspeisung_blind_count=hex(substr($hex,456,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Bezug_Blindleistung", sprintf("%.1f",$l1_bezug_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Bezug_Blindleistung_Zaehler", sprintf("%.1f",$l1_bezug_blind_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Einspeisung_Blindleistung", sprintf("%.1f",$l1_einspeisung_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Einspeisung_Blindleistung_Zaehler", sprintf("%.1f",$l1_einspeisung_blind_count));

    my $l1_bezug_schein=hex(substr($hex,480,8))/10;
    my $l1_bezug_schein_count=hex(substr($hex,496,16))/3600000;
    my $l1_einspeisung_schein=hex(substr($hex,520,8))/10;
    my $l1_einspeisung_schein_count=hex(substr($hex,536,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Bezug_Scheinleistung", sprintf("%.1f",$l1_bezug_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Bezug_Scheinleistung_Zaehler", sprintf("%.1f",$l1_bezug_schein_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Einspeisung_Scheinleistung", sprintf("%.1f",$l1_einspeisung_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Einspeisung_Scheinleistung_Zaehler", sprintf("%.1f",$l1_einspeisung_schein_count));

    my $l1_thd=hex(substr($hex,560,8))/1000;
    my $l1_v=hex(substr($hex,576,8))/1000;
    my $l1_cosphi=hex(substr($hex,592,8))/1000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_THD", sprintf("%.2f",$l1_thd));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_Spannung", sprintf("%.1f",$l1_v));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L1_CosPhi", sprintf("%.3f",$l1_cosphi));


    # L2
    my $l2_bezug_wirk=hex(substr($hex,608,8))/10;
    my $l2_bezug_wirk_count=hex(substr($hex,624,16))/3600000;
    my $l2_einspeisung_wirk=hex(substr($hex,648,8))/10;
    my $l2_einspeisung_wirk_count=hex(substr($hex,664,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Saldo_Wirkleistung", sprintf("%.1f",$l2_einspeisung_wirk-$l1_bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Saldo_Wirkleistung_Zaehler", sprintf("%.1f",$l2_einspeisung_wirk_count-$l1_bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Bezug_Wirkleistung", sprintf("%.1f",$l2_bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Bezug_Wirkleistung_Zaehler", sprintf("%.1f",$l2_bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Einspeisung_Wirkleistung", sprintf("%.1f",$l2_einspeisung_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Einspeisung_Wirkleistung_Zaehler", sprintf("%.1f",$l2_einspeisung_wirk_count));
 
    my $l2_bezug_blind=hex(substr($hex,688,8))/10;
    my $l2_bezug_blind_count=hex(substr($hex,704,16))/3600000;
    my $l2_einspeisung_blind=hex(substr($hex,728,8))/10;
    my $l2_einspeisung_blind_count=hex(substr($hex,744,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Bezug_Blindleistung", sprintf("%.1f",$l2_bezug_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Bezug_Blindleistung_Zaehler", sprintf("%.1f",$l2_bezug_blind_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Einspeisung_Blindleistung", sprintf("%.1f",$l2_einspeisung_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Einspeisung_Blindleistung_Zaehler", sprintf("%.1f",$l2_einspeisung_blind_count));

    my $l2_bezug_schein=hex(substr($hex,768,8))/10;
    my $l2_bezug_schein_count=hex(substr($hex,784,16))/3600000;
    my $l2_einspeisung_schein=hex(substr($hex,808,8))/10;
    my $l2_einspeisung_schein_count=hex(substr($hex,824,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Bezug_Scheinleistung", sprintf("%.1f",$l2_bezug_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Bezug_Scheinleistung_Zaehler", sprintf("%.1f",$l2_bezug_schein_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Einspeisung_Scheinleistung", sprintf("%.1f",$l2_einspeisung_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Einspeisung_Scheinleistung_Zaehler", sprintf("%.1f",$l2_einspeisung_schein_count));

    my $l2_thd=hex(substr($hex,848,8))/1000;
    my $l2_v=hex(substr($hex,864,8))/1000;
    my $l2_cosphi=hex(substr($hex,880,8))/1000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_THD", sprintf("%.2f",$l2_thd));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_Spannung", sprintf("%.1f",$l2_v));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L2_CosPhi", sprintf("%.3f",$l2_cosphi));

    # L3
    my $l3_bezug_wirk=hex(substr($hex,896,8))/10;
    my $l3_bezug_wirk_count=hex(substr($hex,912,16))/3600000;
    my $l3_einspeisung_wirk=hex(substr($hex,936,8))/10;
    my $l3_einspeisung_wirk_count=hex(substr($hex,952,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Saldo_Wirkleistung", sprintf("%.1f",$l3_einspeisung_wirk-$l1_bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Saldo_Wirkleistung_Zaehler", sprintf("%.1f",$l3_einspeisung_wirk_count-$l1_bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Bezug_Wirkleistung", sprintf("%.1f",$l3_bezug_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Bezug_Wirkleistung_Zaehler", sprintf("%.1f",$l3_bezug_wirk_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Einspeisung_Wirkleistung", sprintf("%.1f",$l3_einspeisung_wirk));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Einspeisung_Wirkleistung_Zaehler", sprintf("%.1f",$l3_einspeisung_wirk_count));

    my $l3_bezug_blind=hex(substr($hex,976,8))/10;
    my $l3_bezug_blind_count=hex(substr($hex,992,16))/3600000;
    my $l3_einspeisung_blind=hex(substr($hex,1016,8))/10;
    my $l3_einspeisung_blind_count=hex(substr($hex,1032,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Bezug_Blindleistung", sprintf("%.1f",$l3_bezug_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Bezug_Blindleistung_Zaehler", sprintf("%.1f",$l3_bezug_blind_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Einspeisung_Blindleistung", sprintf("%.1f",$l3_einspeisung_blind));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Einspeisung_Blindleistung_Zaehler", sprintf("%.1f",$l3_einspeisung_blind_count));

    my $l3_bezug_schein=hex(substr($hex,1056,8))/10;
    my $l3_bezug_schein_count=hex(substr($hex,1072,16))/3600000;
    my $l3_einspeisung_schein=hex(substr($hex,1096,8))/10;
    my $l3_einspeisung_schein_count=hex(substr($hex,1112,16))/3600000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Bezug_Scheinleistung", sprintf("%.1f",$l3_bezug_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Bezug_Scheinleistung_Zaehler", sprintf("%.1f",$l3_bezug_schein_count));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Einspeisung_Scheinleistung", sprintf("%.1f",$l3_einspeisung_schein));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Einspeisung_Scheinleistung_Zaehler", sprintf("%.1f",$l3_einspeisung_schein_count));

    my $l3_thd=hex(substr($hex,1136,8))/1000;
    my $l3_v=hex(substr($hex,1152,8))/1000;
    my $l3_cosphi=hex(substr($hex,1168,8))/1000;
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_THD", sprintf("%.2f",$l3_thd));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_Spannung", sprintf("%.1f",$l3_v));
    readingsBulkUpdate($hash, "SMAEM".$smaserial."_L3_CosPhi", sprintf("%.3f",$l3_cosphi));

    readingsEndUpdate($hash, 1);
    $hash->{LASTUPDATE}=time();
  }
}


#############################
1;
#############################


=pod
=begin html

<a name="SMAEM"></a>
<h3>SMAEM</h3>
<ul>
  <br>

  <a name="SMAEM"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SMAEM [&lt;interval&gt];</code><br>
    <br>
    Defines a SMA Energy Meter (SMAEM), a bidirectional energy meter/counter used in photovoltaics. 
    <br><br>
    You need at least one SMAEM on your local subnet or behind a multicast enabled network of routers to receive multicast messages from the SMAEM over the
    multicast group 239.12.255.254 on udp/9522. Multicast messages are sent by SMAEM once a second (firmware 1.02.04.R, March 2016).
    <br><br>
    [&lt;interval&gt] defines the update interval. If not set, it defaults to 60s. Since the SMAEM sends updates once a second, you can
    update the readings once a second by lowering the interval to 1 (Not recommended, since it puts FHEM under heavy load).
    <br><br>
    You need the perl module IO::Socket::Multicast. Under Debian (based) systems it can be installed with <code>apt-get install libio-socket-multicast-perl</code>.
  </ul>  

</ul>


=end html
