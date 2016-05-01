#!/usr/bin/python
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
from twisted.application.internet import MulticastServer

spwMCastAdr='239.12.255.255'
spwMCastAdr2='239.12.255.254'
spwMCastAdr3='239.12.255.253'
spwPort = 9522

discoveryRequest = '534d4100000402a0ffffffff0000002000000000'
discoveryResponse ='534d4100000402a000000001000200000001'

class MulticastClientUDP(DatagramProtocol):
    def startProtocol (self):
        print "Joining speedwire multicast group."
#        self.transport.joinGroup(spwMCastAdr)
        self.transport.joinGroup(spwMCastAdr2)
#        self.transport.joinGroup(spwMCastAdr3)

        print "Sending discovery request."
        data = discoveryRequest.decode ('hex' )
#        self.transport.write(data, (spwMCastAdr, spwPort))
        self.transport.write(data, (spwMCastAdr2, spwPort))

    def datagramReceived (self , datagram, (srcAddress , port)):
        data = datagram.encode('hex')
        if (data.startswith(discoveryResponse)):
            print "Found device: " + srcAddress

def stopReactor():
    print "Discovery finished ."
    reactor.stop()

reactor.listenMulticast(spwPort , MulticastClientUDP(), listenMultiple=True)
reactor.callLater(10, stopReactor )
reactor.run()
