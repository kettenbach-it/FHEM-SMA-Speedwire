Wechselricher von Bluetooth auf Speedwire (=LAN) umstellen

Die folgende Anleitung ist gültig für SMA Sunny Tripower (STP) Wechselrichter, 
deren Produktbezeichnung mit -TL20 aufhört.
Die Modelle mit -TL10 haben ab Werk kein Ethernet an Bord, können aber aufgerüstet 
werden (SMA SPEEDWIRE/WEBCONNECT Piggy-Back).

Der WR STP-xxxxx-TL20 kann per Bluetooth oder LAN (Speedwire) mit einem Sunny Home Manager
kommunizieren.  Soll der WR seine Daten über das LAN senden, so muss seine
Bluetooth Funktion abgeschaltet werden.

Vorgehen:
1. BLUETOOTH Kommunikation der Wechselrichter deaktivieren 
Wenn ein Wechselrichter gleichzeitig über Speedwire/WLAN und über BLUETOOTH mit
dem Sunny Home Manager kommuniziert, kommt es zu Fehlern bei der
Datenerfassung.  Bei Wechselrichtern mit BLUETOOTH Schnittstelle die NetID 0
einstellen (siehe Dokumentation des Wechselrichters oder des BLUETOOTH
Piggy-Back). Dadurch ist die BLUETOOTH Kommunikation deaktiviert.

2. Speedwire-Geräte an den Router/Switch anschließen (siehe Dokumentation des
Speedwire- Geräts). Dabei beachten, dass die Entfernung zum Montageort des
Sunny Home Managers nicht zu groß ist, da der Sunny Home Manager später an den
gleichen Router/Switch angeschlossen werden muss.

Wechselrichter NetId 0:

Werkseitig ist die NetID bei allen SMA Wechselrichtern und SMA
Kommunikationsprodukten mit Bluetooth auf 1 eingestellt. Wenn Ihre Anlage aus
einem Wechselrichter und maximal einem weiteren Bluetooth Gerät (z. B. Computer
mit Bluetooth oder SMA Kommunikationsprodukt) besteht, können Sie die NetID auf
1 eingestellt lassen.

In folgenden Fällen müssen Sie die NetID ändern:
- Wenn Ihre Anlage aus einem Wechselrichter und 2 weiteren Bluetooth Geräten
  (z. B.  Computer mit Bluetooth Schnittstelle und SMA Kommunikationsprodukt)
  oder aus mehreren Wechselrichtern mit Bluetooth besteht, müssen Sie die NetID
  Ihrer Anlage ändern. Dadurch ermöglichen Sie die Kommunikation mit mehreren
  Bluetooth Geräten.
- Wenn sich im Umkreis von 500 m um Ihre Anlage eine andere Anlage mit
  Bluetooth befindet, müssen Sie die NetID Ihrer Anlage ändern. Dadurch grenzen
  Sie die beiden Anlagen voneinander ab.
- Wenn Sie nicht über Bluetooth kommunizieren möchten, deaktivieren Sie die
  Kommunikation über Bluetooth an Ihrem Wechselrichter. Dadurch schützen Sie
  die Anlage vor unberechtigtem Zugriff.  Alle Bluetooth Geräte einer Anlage
  müssen die gleiche NetID haben. Sie können eine neue NetID mit dem Drehschalter
  C im Wechselrichter vor der Inbetriebnahme einstellen. Die Einstellung wird
  nach der Inbetriebnahme übernommen. Dieser Vorgang kann bis zu 5 Minuten
  dauern.

Schalterstellungen des Drehschalters C:
0 Kommunikation über Bluetooth ist deaktiviert.
1 Kommunikation über Bluetooth mit einem weiteren Bluetooth Gerät 
2...F NetID für Kommunikation über Bluetooth mit mehreren Bluetooth Geräten

-> Wechselrichter vom Strom und den Panels trennen
-> Gehäuse aufschrauben

Um eine neue NetID einzustellen, den Drehschalter C mit einem Schlitz-
Schraubendreher (Klingenbreite: 2,5 mm) auf die ermittelte NetID stellen.

Um die Kommunikation über Bluetooth zu deaktivieren, den Drehschalter C mit
einem Schlitz-Schraubendreher (Klingenbreite: 2,5 mm) auf die Position 0
stellen. Dadurch schützen Sie die Anlage vor unberechtigtem Zugriff.

Der Wechselrichter übernimmt die Einstellung nach der Inbetriebnahme. Dieser
Vorgang kann bis zu 5 Minuten dauern.
