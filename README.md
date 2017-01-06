# FHEM-SMA-Speedwire
Repository for FHEM-support of devices that use the "SMA Speedwire" protocol.

* 77_SMAEM.pm: Support for SMA Energymeter, a bidirectional energy meter/counter
* ~~77_SMASTP.pm: Support for SMA Sunny Tripower Inverter~~ -> **Deprecated. Please use 76_SMAInverter.pm**


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

**The module 77_SMASTP is deprecated.**

**It will be removed from the official FHEM soon.**

**Don't use it anymore!**

**Please use 76_SMAInverter.pm instead.**

**You'll find 76_SMAInverter.pm in the official FHEM SVN.**

**Development resource of 76_SMAInverter.pm can be found here: https://github.com/Rincewind76/SMAInverter**



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

