# FHEM-SMA-Speedwire
Repository for FHEM-support of devices that use the "SMA Speedwire" protocol.

* 77_SMAEM.pm: Support for SMA Energymeter, a bidirectional energy meter/counter
* 77_SMASTP.pm: Support for SMA Sunny Tripower Inverter


## FHEM-SMAEM
FHEM-Module for the SMA Energy Meter, a bidirectional energy meter/counter 
used in photovoltaics.

### Installation & Dependencies

This module requires:
- Perl Module: IO::Socket::Multicast

On a Debian (based) system, these requirements can be fullfilled by:
- apt-get install libio-socket-multicast-perl

Before you start using 77_SMAEM.pm, you should try the test
programm smaem_test.pl. It will read data sent by the SMA-EM
over multicast and will print it to the terminal.

Concerning multicast: as long as your FHEM-host is on the same layer2/3 subnet (LAN)
as your SMA-EM, multicast will pretty much behave like broadcast and
you have nothing to worry about.
If the receiving host is behind on or more routers, you have to make sure,
that those routers have multicast forwarding enabled and configured.

Beware: some cheap soho-switches in the 50 euro class pretend to work with 
multicast but inexplicably block random multicast groups. 
You either have to switch to a better switch or use a super simple one (10 Euro),
which doesn't understand multicast at all and will just treat it as broadcast.

Once you get proper readings with smaem_test.pl, you can install 77_SMAEM.pm
just by copying it to your FHEM-installation.

### Setup

Once copied to four FHEM-installation folder ("/FHEM"), load the module with

	reload 77_SMAEM

### Usage

Then you can define your SMA-EM like this: 

	define <name> SMAEM;

"The attibut interval" defines the update interval. If not set, it defaults to 60s. 
Since the SMAEM sends updates once a second (firmware 1.02.04.R, March 2016), 
you can update the readings once a second by lowering the interval to 1, which 
is not recommended, since it puts FHEM under heavy load. 

Example:

	define DP11_SMAEM SMAEM
	attr DP11_SMAEM alias SMA Energy Meter
	attr DP11_SMAEM group Photovoltaik Anlage
	attr DP11_SMAEM room Zähler
	attr DP11_SMAEM interval 120
	attr DP11_SMAEM powerCost 0.28
	attr DP11_SMAEM feedinPrice 0.124
	attr DP11_SMAEM icon measure_power
	attr DP11_SMAEM stateFormat {sprintf("%.1f",ReadingsVal($name,"state",0))." W"}

	define DP11_SMAEM_LOG FileLog ./log/DP11_SMAEM_LOG-%Y.log DP11_SMAEM|DP11_SMAEM:.*


### Limitations
77_SMAEM.pm is in principle capable of supporting several SMA-EMs but it has not been tested.
In case you have more than one SMA-EM, please contact me.
Each reading of each SMA-EM will be uniquely named containg the serial of the SMA-EM it came from,
so you can distinguish between different SMA-EM inside FHEM.


## FHEM-SMASTP

### Installation & Dependencies

This module requires:
- Perl Module: IO::Socket::INET
- Perl Module: Datime

Before you start using 77_SMASTP.pm, you should try the test
programm smaestp_test.pl. It will connect to the SMA STP, read some data
and will print it to the terminal.

If you get proper readings with smastp_test.pl, you can install 77_SMASTP.pm
just by copying it to your FHEM-installation.

### Setup

Once copied to four FHEM-installation folder ("/FHEM"), load the module with

	reload 77_SMASTP

### Usage

Then you can define your SMA-EM like this: 

	define <name> SMASTP <pin> <hostname/ip> [port]

* pin: User-Password of the SMA STP Inverter. Default is 0000. Can be changed by "Sunny Explorer" Windows Software
* hostname/ip: Hostname or IP-Adress of the inverter (or it's speedwire piggyback module)
* port: Port of the inverter. 9522 by default.

The module automatically detects the inactvity of the inverter due to a lack of light (night). 
This inactivity is therefore called "nightmode". During nightmode, the inverter is not queried over the nwtwork.
By default nightmode is between 9pm and 5am. This can be changed by "starttime" (start of inverter 
operation, ende of nightmode) and "endtime" (end of inverter operation, start of nightmode).
Further there is the inactivitymode: in inactivitymode, the inverter is queried but readings are not updated.

Parameter:

* interval: Queryintreval in seconds
* suppress-night-mode: The nightmode is deactivated
* suppress-inactivity-mode: The inactivitymode is deactivated
* starttime: Starttime of inverter operation (default 5am)
* endtime: Endtime of inverter operation (default 9pm)
* force-sleepmode: The nightmode is activated on inactivity, even the endtime is not reached
* enable-modulstate: Turns the reading "modulstate" (normal / inactive / sleeping) on
* alarm1-value, alarm2-value, alarm3-value: Set an alarm on the reading SpotP in watt.<br>
The readings Alarm1..Alarm3 are set accordingly: -1 for SpotP < alarmX-value and 1 for SpotP >= alarmX-value

Example:

	define DP11_SMASTP SMASTP 0000 mysmastp.mydomain.com
	attr DP11_SMASTP alias DP11 SMA Wechselrichter STP 10000-TL20
	attr DP11_SMASTP group Photovoltaik Anlage
	attr DP11_SMASTP icon measure_power
	attr DP11_SMASTP interval 120
	attr DP11_SMASTP room Zähler

	define DP11_SMASTP_LOG FileLog ./log/DP11_SMASTP_LOG-%Y-%m.log  DP11_SMASTP
	attr DP11_SMASTP_LOG room Logs

Readings:

        SpotP: spotpower - Current power in watt delivered by the inverter
        AvP01: average power 1 minute: average power in watt of the last minute
        AvP05: average power 5 minutes: average power in watt of the five minutes
        AvP15: average power 15 minutes: average power in watt of the fifteen minutes
        SpotPDC1: current d.c. voltage delivered by string 1
        SpotPDC2: current d.c. voltage delivered by string 2
        TotalTodayP: generated power in Wh of the current day
        AlltimeTotalP: all time generated power in Wh
        Alarm1..3: alrm trigger 1..3. Set by parameter alarmN-value


## Support

### Forum
#### SMA-EM
A forum for users of the SMA-EM module can be found at:
https://forum.fhem.de/index.php/topic,51569.0.html

#### SMA-STP
A forum for users of the SMA-STP module can be found at:
https://forum.fhem.de/index.php/topic,42688.0.html

### Issues
Please submit issues to github:
https://github.com/kettenbach-it/FHEM-SMA-Speedwire/issues

### Patches
In case you fix something, please submit a patch to
https://github.com/kettenbach-it/FHEM-SMA-Speedwire/issues

## Copyright
Volker Kettenbach, volker (at) kettenbach (minus) it (dot) de

