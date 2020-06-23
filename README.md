# Buddy-Speicherverwaltung
Dieses Projekt setzt die Aufgabenstellung für das Modul BSRN SS2020, die Implementierung einer Buddy-Speicherverwaltung als Bash Skript, um.

## Umsetzung
Aufruf im Linux Terminal:
```bash
./bash.sh <optional: Größe des Gesamtspeichers als Integer>
```
### Funktionen
* Allokation von Speicher
* Deallokation von belegten Blöcken anhand der Startadresse und Merge von Buddies (falls vorhanden)
* Auflisten der aktuell belegten Blöcke durch ausgabe der Startadresse
* Sample zum Kleinschrittigen durchspielen eines statischen Beispiels
* Ausgabe: 
	* Tabelle freier Blöcke in den verschiedenen Speichergrößen + Linke List (entspricht Anzahl gleich großer Blöcke, "-1" Speichergröße nicht vorhanden oder Ende Linked List)
	* Balkendiagramm zur schematischen Darstellung
* Reset aller getätigter Eingaben



## Referenzen

* Buchquellen innerhalb der Dokumentation
* [https://github.com/lyrahgames/buddy-system](https://github.com/lyrahgames/buddy-system)
