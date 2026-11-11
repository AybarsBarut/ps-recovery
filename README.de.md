# PS-Recover

**Language / Dil / Sprache / Idioma:** [English](README.md) | [Türkçe](README.tr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

**Windows Speicherwiederherstellung & Flash-Laufwerk-Reparatur-Engine**

PS-Recover ist ein abhaengigkeitsfreies (Zero-Dependency) PowerShell-Werkzeug zur Dateiwiederherstellung, Diagnose und Speicherreparatur fuer Windows. Es wurde speziell fuer USB-Sticks, SD-Karten, externe Festplatten und interne Laufwerke entwickelt, inklusive Diagnose und Entsperrung schreibgeschuetzter (Read-Only) Flash-Laufwerke.

Die Engine kann direkt im Arbeitsspeicher ueber einen interaktiven Einzeiler (`irm ... | iex`) ausgefuehrt oder als permanenter PowerShell-Befehl (`recover`) installiert werden.

---

## Schnellstart

### Direkte Ausfuehrung im Arbeitsspeicher
Ausfuehrung in Windows PowerShell (5.1 oder 7+) ohne vorherige Installation:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/recover.ps1 | iex
```

### Permanente Profil-Installation
Zur dauerhaften Registrierung des Befehls in Ihrem PowerShell-Profil:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/install.ps1 | iex
```

Nach der Installation kann das Werkzeug jederzeit ueber den Befehl `recover` in jedem Terminal aufgerufen werden.

---

## Mehrsprachigkeit

PS-Recover verfuegt ueber vollstaendige zweisprachige Unterstuetzung (Englisch und Tuerkisch) fuer Menues, Tabellen, Protokolle, Fehlerdiagnosen und Berichtdateien.

- **CLI-Parameter:** Sprache beim Start waehlen:
  ```powershell
  recover -Lang en    # Englisch
  recover -Lang tr    # Tuerkisch
  ```
- **Interaktiver Sprachwechsel:** Druecken Sie im Hauptmenue jederzeit `[L]`, um die Sprache umzuschalten.
- **Dauerhafte Speicherung:** Ihre Spracheinstellung wird automatisch in `~/.ps-recover/lang.conf` gespeichert.
- **Automatische Erkennung:** Ohne manuelle Angabe passt sich PS-Recover automatisch an Ihre Windows-Anzeigesprache an.

---

## Kernfunktionen

### 1. Speichergeraete- und Volume-Erkennung
- Erkennt physische Laufwerke und logische Volumes ueber die Windows Storage Management API (`Get-Volume`, `Get-Partition`, `Get-Disk`) mit CIM/WMI-Fallback.
- Zeigt Festplattenmodell, Volume-Bezeichnung, Bus-Schnittstelle (USB, NVMe, SATA), Dateisystem (NTFS, FAT32, exFAT), Gesamtkapazitaet und freien Speicherplatz an.
- Erkennt schreibgeschuetzte Datentraeger und schuetzt Systemlaufwerke vor versehentlichen Operationen.

### 2. Robuste Wiederherstellungs-Engine
- Sichert Dateien unter Beibehaltung der Verzeichnisstruktur in `[Desktop]\recovered\Recovery_<Buchstabe>_<Zeitstempel>`.
- Nutzt Stream-basiertes Lesen fuer Datentraeger mit fehlerhaften Sektoren (Bad Sectors), ohne den Wiederherstellungsvorgang abzubrechen.
- Bereinigt Dateibeschraenkungen und setzt Dateiattribute (`ReadOnly`, `Hidden`, `System`) automatisch auf `Normal`.

### 3. Beseitigung von Shortcut-Viren & Wiederherstellung versteckter Daten
- Erkennt und isoliert Verknuepfungswuermer (`.lnk`, `.vbs`, `.wsf`) auf USB-Sticks.
- Stellt durch Viren versteckte Originaldateien und Ordner zuverlaessig wieder her.

### 4. Mehrkriterielle Dateifilterung
- Ermoeglicht gezielte Wiederherstellung nach Dateikategorien:
  - **Dokumente:** PDF, DOCX, XLSX, PPTX, TXT, CSV, RTF, ODT
  - **Fotos & Bilder:** JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD
  - **Videos:** MP4, MKV, AVI, MOV, WMV, FLV, WEBM
  - **Audio:** MP3, WAV, FLAC, AAC, M4A, OGG
  - **Archive:** ZIP, RAR, 7Z, TAR, GZ, ISO
  - **Entwicklung:** PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON
  - **Benutzerdefinierte Formate:** Kommagetrennte Liste eigener Erweiterungen

### 5. Reparatur-Pipeline fuer schreibgeschuetzte Flash-Laufwerke
Fuer USB-Sticks mit Schreibschutz fuehrt PS-Recover einen sicherheitsorientierten Reparaturprozess aus:
1. **Sicherheits-Backup:** Vor belastenden Eingriffen werden alle lesbaren Daten auf den Desktop gesichert.
2. **Diskpart-Attribute bereinigen:** Loescht Schreibschutz-Flags auf Datentraeger- und Volume-Ebene.
3. **Storage-API-Konfiguration:** Hebt ueber `Set-Disk` Kernel-Schreibschutzflags auf.
4. **Registry-Pruefung:** Kontrolliert und korrigiert `StorageDevicePolicies\WriteProtect`.
5. **Dateisystem-Reparatur:** Fuehrt `chkdsk /f` zur Behebung von Dateisystemfehlern aus.
6. **Hardware-Schreibtest & NAND-Diagnose:** Verifiziert den Schreibzugriff. Scheitert dieser trotz Entsperrung aller Softwaresperren, diagnostiziert PS-Recover den hardwareseitigen Verschleissschutzmodus (NAND Wear-Out ROM Mode) des Controllers.

### 6. Pruefpfad & Detaillierte Berichte
- Erstellt eine UTF-8-kodierte Berichtdatei (`recovery_report.txt` bzw. `kurtarma_raporu.txt`) im Sitzungsordner mit ausfuehrlichen Statusinformationen fuer jede verarbeitete Datei.

---

## Terminal-Benutzeroberflaeche

```text
 ===========================================================================
   ____  ____        ____                                          
  |  _ \/ ___|      |  _ \ ___  ___ _____   _____ _ __ _   _       
  | |_) \___ \ _____| |_) / _ \/ __/ _ \ \ / / _ \ '__| | | |      
  |  __/ ___) |_____|  _ <  __/ (_| (_) \ V /  __/ |  | |_| |      
  |_|   |____/      |_| \_\___|\___\___/ \_/ \___|_|   \__, |      
                                                        |___/       
       Windows Storage Recovery & Flash Drive Repair Engine v1.0         
 ===========================================================================
 [i] Session Mode: ADMINISTRATOR - All diskpart and unlock privileges active

 CONNECTED DISKS AND STORAGE VOLUMES:
 ---------------------------------------------------------------------------------------------
 #    DRIVE  MODEL / LABEL            TYPE               FS          TOTAL FREE SPACE  STATUS
 ---------------------------------------------------------------------------------------------
 [1]  C:     CT1000P3PSSD8            NVMe SSD (Internal) NTFS    930.26 GB  191.81 GB  [SYSTEM DRIVE]
 [2]  E:     BACKUP (Kingston DT 3.0) USB Flash / External FAT32   29.80 GB   14.20 GB  [READ-ONLY / LOCKED]
 ---------------------------------------------------------------------------------------------

 OPTIONS:
  [1-2] Select a disk to start recovery/repair operations
  [R]   Rescan disks (if you plugged in a new drive)
  [P]   Permanently install 'recover' command to PowerShell profile
  [L]   Change Language / Dili Degistir (Current: English)
  [Q]   Exit
```

---

## Befehlsparameter

| Parameter | Beschreibung |
|---|---|
| `recover` | Startet das interaktive Terminal-Menue. |
| `recover -List` | Listet angeschlossene Laufwerke tabellarisch auf und beendet das Programm. |
| `recover -Install` | Registriert `recover` dauerhaft im PowerShell-Profil. |
| `recover -Uninstall` | Entfernt die Profilregistrierung und lokale Dateien vollstaendig. |
| `recover -Lang <en\|tr>` | Legt die Oberflaechensprache fest (`en`: Englisch, `tr`: Tuerkisch). |
| `recover -Help` | Zeigt Syntax und Hilfeinformationen an. |

---

## Diagnosemodell fuer Schreibschutz

| Sperrtyp | Mechanismus | Loesungsansatz |
|---|---|---|
| **Software-Sperre** | Diskpart-Flags, Windows-Registry-Richtlinien, Dateiberechtigungen oder unvollstaendig geschlossene `dirty bit`-Flags nach unsicherem Entfernen. | PS-Recover bereinigt logische Sperren, setzt Registry-Schluessel zurueck, repariert das Dateisystem und stellt Schreibzugriff wieder her. |
| **Hardware-Schutz (NAND Wear-Out)** | Wenn Speicherzellen ihre maximale Schreibzyklen erreichen oder defekte Sektoren zunehmen, sperrt der Controller das Geraet dauerhaft im Hardware-ROM-Modus. | Hardware-Sperren koennen nicht softwareseitig behoben werden. PS-Recover **sichert zuerst alle Daten auf den Desktop**, diagnostiziert den Zustand und verhindert Datenverlust. |

---

## Tests & Validierung

Automatisierte Unit- und Integrationstests ausfuehren:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test-recovery.ps1
```

---

## Deinstallation

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/uninstall.ps1 | iex
```

Oder ueber eine bestehende Installation:

```powershell
recover -Uninstall
```

---

## Lizenz

Dieses Projekt ist unter der [MIT-Lizenz](LICENSE) lizenziert.
