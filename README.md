# PS-Recover

**Language / Dil / Sprache / Idioma:** [English](README.md) | [Türkçe](README.tr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

**Windows Storage Recovery & Flash Drive Repair Engine**

PS-Recover is a zero-dependency PowerShell file recovery, diagnostics, and storage repair tool for Windows. It is specifically designed to recover data from USB flash drives, SD cards, external hard drives, and internal storage devices, while also diagnosing and repairing write-protected (read-only) flash drives.

The engine can be executed directly in memory via an interactive one-liner (`irm ... | iex`) or installed permanently as a native PowerShell function (`recover`).

---

## Quick Start

### Direct In-Memory Execution
Run directly in Windows PowerShell (5.1 or 7+) without installation:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/recover.ps1 | iex
```

### Persistent Profile Installation
To install the tool permanently into your PowerShell profile:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/install.ps1 | iex
```

Once installed, simply type `recover` in any terminal session.

---

## Multilingual Support

PS-Recover provides full bilingual support (English and Turkish) for all menus, tables, logs, error diagnostics, and report files.

- **CLI Flag:** Specify language on launch:
  ```powershell
  recover -Lang en    # English
  recover -Lang tr    # Turkish
  ```
- **Interactive Switcher:** Press `[L]` in the main menu at any time to toggle between English and Turkish.
- **Preference Persistence:** Your language choice is automatically remembered across sessions in `~/.ps-recover/lang.conf`.
- **System Culture Detection:** When no preference is set, PS-Recover automatically aligns with your Windows display language.

---

## Core Capabilities

### 1. Storage Device & Logical Volume Discovery
- Detects physical disks and logical volumes using the Windows Storage Management API (`Get-Volume`, `Get-Partition`, `Get-Disk`) with CIM/WMI fallback.
- Displays disk model, volume label, bus interface (USB, NVMe, SATA), file system (NTFS, FAT32, exFAT), total capacity, and free space metrics.
- Automatically flags read-only volumes and protects system drives against accidental operations.

### 2. Resilient Data Recovery Engine
- Safely extracts files from damaged or unstable drives into `[Desktop]\recovered\Recovery_<Letter>_<Timestamp>`.
- Preserves full directory hierarchies.
- Incorporates stream-based fallback reading for drives with bad sectors or I/O timeouts, continuing execution without aborting the session.
- Automatically normalizes file permissions and clears restrictive attributes (`ReadOnly`, `Hidden`, `System`) so recovered files are immediately usable.

### 3. Shortcut Virus Remediation & Hidden Data Extraction
- Scans for and unhides real folders and files concealed by common USB shortcut worms (`.lnk`, `.vbs`, `.wsf`).
- Bypasses malicious script shortcuts and salvages the original obscured payload.

### 4. Multi-Criteria File Filtering
- Allows targeted extraction in addition to full drive imaging:
  - **Documents:** PDF, DOCX, XLSX, PPTX, TXT, CSV, RTF, ODT
  - **Photos & Images:** JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD
  - **Videos:** MP4, MKV, AVI, MOV, WMV, FLV, WEBM
  - **Audio:** MP3, WAV, FLAC, AAC, M4A, OGG
  - **Archives:** ZIP, RAR, 7Z, TAR, GZ, ISO
  - **Development:** PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON
  - **Custom Extensions:** User-specified comma-separated extension lists

### 5. Read-Only (Write-Protected) Flash Drive Repair Pipeline
For flash drives locked in read-only mode, PS-Recover executes a safety-first recovery and repair workflow:
1. **Safety Backup:** Before running stress-inducing repair commands, all readable files are backed up to the desktop.
2. **Diskpart Attribute Reset:** Clears `readonly` attributes on both physical disk and logical volume levels.
3. **Storage API Configuration:** Unsets `IsReadOnly` and offline flags at kernel level via `Set-Disk`.
4. **Windows Registry Inspection:** Checks and resets `HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect`.
5. **File System Repair:** Invokes `chkdsk /f` to resolve dirty-bit locks and file allocation table corruption.
6. **Hardware Write Verification & NAND Diagnosis:** Performs a hardware write test. If software locks are cleared but writes fail, PS-Recover accurately diagnoses that the NAND flash controller has entered permanent hardware wear-out ROM mode, protecting user data from false repair assumptions.

### 6. Audit Trail & Detailed TXT Reports
- Generates a UTF-8 encoded report file (`recovery_report.txt` in English, `kurtarma_raporu.txt` in Turkish) in the session folder.
- Records volume metadata, scanned file count, recovered byte totals, elapsed time, and per-file recovery status.

---

## Terminal Interface

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

## Command Parameters

| Parameter | Description |
|---|---|
| `recover` | Launches the interactive terminal menu. |
| `recover -List` | Displays connected storage devices and exit. |
| `recover -Install` | Permanently registers `recover` in your PowerShell profile. |
| `recover -Uninstall` | Uninstalls the tool and cleans up local profile entries. |
| `recover -Lang <en\|tr>` | Overrides interface language (`en` for English, `tr` for Turkish). |
| `recover -Help` | Displays command line usage and parameter documentation. |

---

## Write-Protection Diagnostic Model

Flash memory write-protection originates from two fundamentally different sources:

| Lock Category | Root Mechanism | Resolution Approach |
|---|---|---|
| **Software Lock** | Diskpart flags, Windows Registry policies, file permissions, or unclosed file system `dirty bit` flags caused by unsafe removal. | PS-Recover clears all logical lock layers, resets Registry policies, repairs the file system, and restores write capability. |
| **Hardware Protection (NAND Wear-Out)** | When flash memory cells reach maximum write endurance cycles or critical bad sector thresholds, the hardware controller permanently locks into ROM mode to prevent catastrophic data loss. | Hardware locks cannot be bypassed through software. PS-Recover **rescues all data to your desktop first**, diagnoses the hardware failure, and prevents further corruption. |

---

## Testing & Verification

Run the automated unit and integration test suite:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test-recovery.ps1
```

---

## Uninstallation

To remove PS-Recover completely from your system:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/uninstall.ps1 | iex
```

Or from an existing installation:

```powershell
recover -Uninstall
```

---

## License

This project is licensed under the [MIT License](LICENSE).
