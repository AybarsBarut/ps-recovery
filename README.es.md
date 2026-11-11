# PS-Recover

**Language / Dil / Sprache / Idioma:** [English](README.md) | [Türkçe](README.tr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

**Motor de Recuperacion de Almacenamiento y Reparacion de Unidades Flash para Windows**

PS-Recover es una herramienta de PowerShell sin dependencias externas (zero-dependency) para la recuperacion de archivos, diagnostico y reparacion de unidades de almacenamiento en Windows. Esta disenada para memorias USB, tarjetas SD, discos duros externos y discos internos, incluyendo el diagnostico y desbloqueo de unidades flash protegidas contra escritura (solo lectura).

El motor se puede ejecutar directamente en memoria mediante una sola linea interactiva (`irm ... | iex`) o instalarse de forma permanente como un comando de PowerShell (`recover`).

---

## Inicio Rapido

### Ejecucion Directa en Memoria
Ejecucion directa en Windows PowerShell (5.1 o 7+) sin necesidad de instalacion previa:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/recover.ps1 | iex
```

### Instalacion Permanente en el Perfil
Para registrar permanentemente el comando en su perfil de PowerShell:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/install.ps1 | iex
```

Una vez instalado, ejecute simplemente `recover` en cualquier ventana de PowerShell.

---

## Soporte Multilingue

PS-Recover incluye soporte bilingue completo (ingles y turco) para todos los menus, tablas, registros, diagnosticos de error y archivos de reporte.

- **Parametro CLI:** Especifique el idioma al iniciar:
  ```powershell
  recover -Lang en    # Ingles
  recover -Lang tr    # Turco
  ```
- **Cambio Interactivo:** Pulse `[L]` en el menu principal en cualquier momento para alternar el idioma.
- **Persistencia de Preferencia:** Su eleccion de idioma se almacena automaticamente en `~/.ps-recover/lang.conf`.
- **Deteccion Automatica:** Si no se define una configuracion manual, PS-Recover se ajusta al idioma de interfaz de Windows.

---

## Capacidades Principales

### 1. Deteccion de Dispositivos y Volumenes Logicos
- Detecta unidades fisicas y particiones mediante la API de administracion de almacenamiento de Windows (`Get-Volume`, `Get-Partition`, `Get-Disk`) con respaldo CIM/WMI.
- Muestra modelo de disco, etiqueta de volumen, tipo de interfaz (USB, NVMe, SATA), sistema de archivos (NTFS, FAT32, exFAT), capacidad total y espacio libre.
- Clasifica unidades en modo de solo lectura y resguarda los discos de sistema frente a acciones accidentales.

### 2. Motor Resiliente de Recuperacion de Archivos
- Extrae archivos conservando la estructura de carpetas original en `[Desktop]\recovered\Recovery_<Letra>_<MarcaDeTiempo>`.
- Integra lectura por flujo (streams) para sectores danados o con errores de E/S, continuando el proceso sin abortar la sesion.
- Normaliza permisos y limpia atributos restrictivos (`ReadOnly`, `Hidden`, `System`) estableciendolos en `Normal`.

### 3. Eliminacion de Virus de Acceso Directo y Rescate de Datos Ocultos
- Detecta y aisla gusanos de acceso directo (`.lnk`, `.vbs`, `.wsf`) en memorias USB.
- Recupera de forma segura los archivos y carpetas reales ocultados por el malware.

### 4. Filtrado Multicriterio de Archivos
- Permite la extraccion selectiva por categorias de archivo:
  - **Documentos:** PDF, DOCX, XLSX, PPTX, TXT, CSV, RTF, ODT
  - **Fotos e Imagenes:** JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD
  - **Videos:** MP4, MKV, AVI, MOV, WMV, FLV, WEBM
  - **Audio:** MP3, WAV, FLAC, AAC, M4A, OGG
  - **Archivos Comprimidos:** ZIP, RAR, 7Z, TAR, GZ, ISO
  - **Desarrollo:** PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON
  - **Extensiones Personalizadas:** Lista de extensiones definida por el usuario

### 5. Linea de Reparacion para Memorias Flash Protegidas contra Escritura
Para memorias USB bloqueadas en modo de solo lectura, PS-Recover aplica un protocolo de recuperacion prioritario:
1. **Copia de Seguridad Previa:** Respalda todos los archivos legibles en el escritorio antes de ejecutar procesos de reparacion.
2. **Reinicio de Atributos Diskpart:** Limpia indicadores de solo lectura a nivel de disco fisico y volumen logico.
3. **Configuracion Storage API:** Restablece indicadores de solo lectura y desconexion a nivel de kernel mediante `Set-Disk`.
4. **Inspeccion del Registro de Windows:** Comprueba y restablece `StorageDevicePolicies\WriteProtect`.
5. **Reparacion del Sistema de Archivos:** Ejecuta `chkdsk /f` para corregir inconsistencias y flags dirty-bit.
6. **Verificacion de Escritura y Diagnostico NAND:** Realiza pruebas de escritura en el hardware. Si los bloqueos por software se eliminaron pero la escritura sigue rechazada, PS-Recover diagnostica el modo de proteccion por desgaste del controlador (NAND Wear-Out ROM Mode).

### 6. Pista de Auditoria y Reportes TXT Detallados
- Genera un reporte en texto plano UTF-8 (`recovery_report.txt` o `kurtarma_raporu.txt`) en la carpeta de sesion, detallando volumen, archivos procesados, bytes recuperados y estado individual de cada elemento.

---

## Interfaz de Terminal

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

## Parametros de Linea de Comandos

| Parametro | Descripcion |
|---|---|
| `recover` | Inicia el menu interactivo de terminal. |
| `recover -List` | Muestra dispositivos conectados en formato de tabla y finaliza. |
| `recover -Install` | Registra `recover` de forma permanente en el perfil de PowerShell. |
| `recover -Uninstall` | Elimina el registro del perfil y los archivos de instalacion local. |
| `recover -Lang <en\|tr>` | Define el idioma de la interfaz (`en`: ingles, `tr`: turco). |
| `recover -Help` | Muestra la documentacion y ayuda de parametros. |

---

## Modelo de Diagnostico de Proteccion contra Escritura

| Tipo de Bloqueo | Causa Raiz | Enfoque de Solucion |
|---|---|---|
| **Bloqueo por Software** | Atributos de Diskpart, directivas del Registro de Windows, permisos de archivo o indicador `dirty bit` por extraccion insegura. | PS-Recover remueve todas las restricciones logicas, restablece el Registro, repara el sistema de archivos y devuelve la capacidad de escritura. |
| **Proteccion de Hardware (NAND Wear-Out)** | Al agotarse los ciclos de escritura de las celdas o incrementarse sectores defectuosos, el controlador bloquea la memoria en modo ROM permanente para evitar la perdida de datos. | Los bloqueos de hardware no pueden eliminarse por software. PS-Recover **salva primero todos los datos en el escritorio**, identifica la falla del controlador y previene la corrupcion de la informacion. |

---

## Pruebas y Verificacion

Ejecute la suite de pruebas unitarias y de integracion:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test-recovery.ps1
```

---

## Desinstalacion

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/uninstall.ps1 | iex
```

O desde una instalacion activa:

```powershell
recover -Uninstall
```

---

## Licencia

Este proyecto esta licenciado bajo la [Licencia MIT](LICENSE).
