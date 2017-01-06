# FHEM-SMA-Speedwire

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
This inactivity is therefore called "nightmode". During nightmode, the inverter is not queried over the network.
By default nightmode is between 9pm and 5am. This can be changed by "starttime" (start of inverter 
operation, end of nightmode) and "endtime" (end of inverter operation, start of nightmode).
Further there is the inactivitymode: in inactivitymode, the inverter is queried but readings are not updated (since all of them are zero).

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


