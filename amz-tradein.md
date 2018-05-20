# amz-tradein.pl

## Autom. Amazon-Trade-In-Preisliste für Goodreads-Bücher

![Maintenance](https://img.shields.io/maintenance/yes/2015.svg)

```
$ ./gr-tradein.pl 18418712 books-for-sale
EUR 8,50   Schneekreuzer. Alle drei Teile in einem Band
EUR 3,37   Exit Wounds
EUR 2,45   Software Factories: Assembling Applications with Patterns, Models, Frameworks and Tools
EUR 0,15   Death March
EUR 0,15   Bellum Gallicum. Text
EUR 0,10   Wien wartet auf Dich. Der Faktor Mensch im DV Management
EUR 0,10   Produkt ist Kommunikation - Integration von Branding und Usability
EUR 0,10   Politik als Beruf
```

## Amazon kauft gebrauchte Bücher zurück
- kein Warten auf Käufer, kein Werben nötig = schneller Verkauf alter Bücher
- finanz. immer Verlust, aber Buchfehlkäufe verstauben sonst bzw. ärgern mit ihrer Gegenwart
- Fachbücher erlösten manchmal 10-25 EUR (50% vom Einkaufspreis)
- Erlöse z.B. für den Kauf anderer Gebrauchtbücher
- _zeitaufwendig_ (a) immer wieder und (b) genug höherpreisige Bücher per Hand zu finden
  - vertane Zeit, wenn sich nichts findet; Preise ändern sich regelm.
  - lohnende Bücher übersehen, falsch beurteilt
- Gr-tradein.pl ermittelt _automatisch_ alle Angebote für ein gesamtes Goodreads-Regal
- Goodreads.com: weltgrößte Lesegemeinde + Tools zur Bücherverwaltung


## Installation unter GNU/Linux
1. Keine Installation nötig! Amazon kauft nichts mehr ([seit 31.08.15](https://www.amazon.de/gp/browse/ref=trdrt_conf_exodus?ie=UTF8&node=4455884031))
2. Perl ist oft vorinstalliert
3. amz-tradein.pl ausführbar machen (chmod +x) und starten, Hilfe erscheint
4. bei Startfehler evtl. das Perl-Modul WWW::Curl::Easy z.B. über [cpan](http://perl.about.com/od/packagesmodules/qt/perlcpan.htm) installieren


## Nutzungslizenz
Creative Commons BY-SA


