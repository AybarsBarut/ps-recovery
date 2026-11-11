<#
.SYNOPSIS
    PS-Recover - Windows Storage Recovery & Flash Drive Repair Engine
.DESCRIPTION
    Zero-dependency file recovery and diagnostic tool for Windows PowerShell.
    Recovers files from internal/external drives, repairs write-protected USB flash
    drives, unhides shortcut virus victims, and generates audit reports.
.EXAMPLE
    recover
    Opens interactive recovery menu.
.EXAMPLE
    recover -List
    Lists connected drives and statuses.
.EXAMPLE
    recover -Lang en
    Runs the tool in English.
.EXAMPLE
    recover -Lang tr
    Araci Turkce olarak baslatir.
.EXAMPLE
    recover -Install
    Installs 'recover' permanently to PowerShell profile.
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$script:PSRecoverLang = $null

$script:PSRecoverStrings = @{
    en = @{
        BannerTitle             = "Windows Storage Recovery & Flash Drive Repair Engine v1.0"
        AdminModeOn             = "ADMINISTRATOR - All diskpart and unlock privileges active"
        AdminModeOff            = "STANDARD USER (Administrator recommended for read-only hardware repair)"
        SessionMode             = " [i] Session Mode: "
        
        DrivesHeader            = " CONNECTED DISKS AND STORAGE VOLUMES:"
        ColNum                  = "#"
        ColDrive                = "DRIVE"
        ColModel                = "MODEL / LABEL"
        ColType                 = "TYPE"
        ColFS                   = "FS"
        ColTotal                = "TOTAL"
        ColFree                 = "FREE SPACE"
        ColStatus               = "STATUS"
        StatusNormal            = "[NORMAL]"
        StatusReadOnly          = "[READ-ONLY / LOCKED]"
        StatusSystem            = "[SYSTEM DRIVE]"
        NoDrivesFound           = " [!] No accessible disks or drives found on the system."
        Unknown                 = "Unknown"
        Unlabeled               = "(Unlabeled)"
        GenericDisk             = "Storage Device"
        StandardDisk            = "Standard Disk"
        DiskWord                = "Disk"

        TypeUsb                 = "USB Flash / External"
        TypeNvme                = "NVMe SSD (Internal)"
        TypeSata                = "SATA Disk (Internal)"
        TypeRemovable           = "Removable Storage"
        TypeFixed               = "Fixed Disk (Internal)"
        TypeOptical             = "Optical Drive (CD/DVD)"
        TypeNetwork             = "Network Drive"
        TypeLogical             = "Logical Drive"

        RecoveryFolderPrefix    = "Recovery"
        ReportFileName          = "recovery_report.txt"
        SourceDrive             = " [>] Source Drive  : "
        DestFolder              = " [>] Target Folder : "
        ScanMode                = " [>] Scan Mode     : "
        ScanningFiles           = " [*] Scanning files, please wait..."
        ScanError               = " [!] An error occurred while retrieving file list: {0}"
        NoFilesFound            = " [!] No recoverable files found matching selected criteria."
        FilesFoundStarting      = " [+] Found {0} files ({1}). Starting recovery..."
        ProgressActivity        = "Recovering Files (Desktop\recovered)"
        ProgressStatus          = "[{0} / {1}] ({2}%) {3}"
        ProgressDone            = "File Recovery Completed"
        StatusSuccess           = "Success"
        StatusError             = "Error"
        
        ReportTitle             = "                          RECOVERY REPORT SUMMARY                           "
        ReportLabelSource       = " Source Drive           : {0} ({1})"
        ReportLabelDest         = " Target Folder          : {0}"
        ReportLabelTotal        = " Total Scanned Files    : {0}"
        ReportLabelSuccess      = " Successfully Recovered : {0}"
        ReportLabelFailed       = " Unreadable / Errors    : {0}"
        ReportLabelSize         = " Total Recovered Size   : {0}"
        ReportLabelElapsed      = " Elapsed Time           : {0}"
        ReportFilesHeader       = " RECOVERED FILES (Showing first {0} files):"
        ReportMoreFiles         = " ... and {0} more files recovered (Complete list saved in report file)."
        ReportSaved             = " [OK] Detailed report file saved: {0}"
        ReportSaveError         = " [!] Could not write report file: {0}"
        OpenFolderPrompt        = " Open destination folder in File Explorer? [Y/N]"
        
        FileReportHeader        = "                       PS-RECOVER RECOVERY REPORT                          "
        FileReportDate          = " Date                   : {0}"
        FileReportSource        = " Source Disk / Drive    : {0} ({1})"
        FileReportFS            = " File System            : {0}"
        FileReportTarget        = " Target Folder          : {0}"
        FileReportTotal         = " Total Scanned Files    : {0}"
        FileReportSuccess       = " Successfully Recovered : {0}"
        FileReportErrors        = " Errors / Unreadable    : {0}"
        FileReportSize          = " Total Recovered Size   : {0}"
        FileReportElapsed       = " Elapsed Time           : {0}"
        FileReportListHeader    = "FILE LIST:"

        RepairTitle             = "            READ-ONLY (WRITE-PROTECTED) FLASH DRIVE REPAIR                  "
        TargetDriveLabel        = " Target Drive : {0} [{1}] - {2}"
        RepairExplanation1      = " Flash drives typically become read-only due to 2 main reasons:"
        RepairExplanation2      = "  1. Software Locks: Diskpart attributes, corrupted file system, Registry policy, or malware."
        RepairExplanation3      = "  2. Hardware Protection (NAND Wear-Out): The controller permanently locks the drive"
        RepairExplanation4      = "     into read-only mode to prevent catastrophic cell corruption."
        Step1Title              = " [STEP 1 / SAFETY BACKUP]"
        Step1Warn               = " Unlock operations may stress the flash controller. Before repair,"
        Step1Prompt             = " would you like to BACK UP all readable files to Desktop\recovered?"
        Step1Confirm            = " [Recommended] Backup files to desktop now? [Y/N] (Default: Y)"
        Step1Starting           = " [*] Taking full safety backup of flash drive..."
        Step1Skipped            = " [!] Backup step skipped by user."
        Step2Title              = " [STEP 2 / UNLOCKING AND REPAIR OPERATIONS STARTED]"
        Step2AdminWarn1         = " [!] WARNING: ADMINISTRATOR privileges are required to clear write-protection"
        Step2AdminWarn2         = "     via Diskpart and Windows Registry."
        Step2ElevatePrompt      = " Launch a new PowerShell session as Administrator? [Y/N]"
        Step2LimitedMode        = " [!] Without Administrator rights, only limited file attribute clearing will be performed."
        DiskpartRunning         = " [*] Clearing disk and volume read-only flags using Diskpart..."
        DiskpartSuccess         = " [OK] Diskpart commands executed successfully."
        DiskpartError           = " [!] Failed to execute Diskpart: {0}"
        StorageApiRunning       = " [*] Disabling disk read-only flag via Windows Storage API..."
        StorageApiSuccess       = " [OK] Storage API configuration updated."
        RegistryRunning         = " [*] Inspecting Windows Registry StorageDevicePolicies..."
        RegistryCleared         = " [OK] Global 'WriteProtect = 1' flag cleared in Registry (set to 0)!"
        RegistryNoLock          = " [i] No system-wide write protection key found in Registry."
        RegistryError           = " [!] Registry access error: {0}"
        AttribRunning           = " [*] Clearing read-only attributes on all files and directories..."
        AttribSuccess           = " [OK] File system attributes (attrib -r -s -h) cleared."
        ChkdskExplanation       = " A corrupted file system or unclosed 'dirty bit' flag can cause Windows to lock the drive in read-only mode."
        ChkdskPrompt            = " Run file system repair (chkdsk {0} /f)? [Y/N]"
        ChkdskRunning           = " [*] Running Chkdsk, please wait..."
        ChkdskSuccess           = " [OK] Chkdsk completed."
        ChkdskError             = " [!] Chkdsk error: {0}"
        Step3Title              = " [STEP 3 / WRITE VERIFICATION AND DIAGNOSTIC TEST]"
        Step3Running            = " [*] Verifying lock status by writing test data to drive..."
        VerificationSuccess     = "  CONGRATULATIONS! FLASH DRIVE WRITE-LOCK SUCCESSFULLY REMOVED!           "
        VerificationSuccessDesc = " [OK] Drive is no longer read-only. You can now add, delete, and format files."
        VerificationHardwareLock= "  HARDWARE PROTECTION (NAND WEAR-OUT ROM MODE) DIAGNOSED                  "
        HardwareLockDesc1       = " [!] All software locks (Diskpart, Registry, Attrib, Permissions) were cleared,"
        HardwareLockDesc2       = "     but the flash controller (NAND Controller) rejected the write command."
        HardwareLockError       = "     Error: {0}"
        TechnicalDiagnosisHeader= " TECHNICAL DIAGNOSIS AND RECOMMENDATION:"
        HardwareDiagnosis1      = "  When flash memory cells reach end-of-life or critical bad sectors accumulate,"
        HardwareDiagnosis2      = "  the hardware controller permanently locks the drive into 'Hardware ROM' mode"
        HardwareDiagnosis3      = "  to prevent complete catastrophic data loss."
        HardwareGoodNews        = "  GOOD NEWS: All recoverable files were safely rescued to Desktop\recovered in Step 1!"
        HardwareReplacementAdvice= "  This flash drive is no longer reliable; replacement is strongly recommended."

        InstallStarting         = " [*] Installing 'recover' command to your PowerShell profile..."
        InstallSuccess          = " [OK] 'recover' command successfully added to your PowerShell profile!"
        InstallProfilePath      = " [i] Profile file: {0}"
        InstallUsageHint        = " [i] You can now type 'recover' in any PowerShell terminal to launch the tool!"
        InstallAlreadyPresent   = " [i] 'recover' command is already present in your profile."
        UninstallStarting       = " [*] Removing 'recover' command from PowerShell profile..."
        UninstallSuccessProfile = " [OK] Profile entry removed."
        UninstallSuccessFolder  = " [OK] Local installation directory removed ({0})."
        UninstallComplete       = " [OK] PS-Recover has been successfully uninstalled."

        MenuOptionsHeader       = " OPTIONS:"
        MenuOptionDriveSelect   = "  [1-{0}] Select a disk to start recovery/repair operations"
        MenuOptionRescan        = "  [R]   Rescan disks (if you plugged in a new drive)"
        MenuOptionInstall       = "  [P]   Permanently install 'recover' command to PowerShell profile"
        MenuOptionLanguage      = "  [L]   Change Language / Dili Degistir (Current: English)"
        MenuOptionQuit          = "  [Q]   Exit"
        PromptMainSelection     = " Please enter the number of the disk or option you want to process"
        ExitMessage             = " [OK] Exited. Goodbye!"
        RescanningDisks         = " [*] Rescanning disks..."
        PressEnterToContinue    = " Press Enter to continue..."
        InvalidSelection        = " [!] Invalid selection. Please enter a valid number or drive letter from the list."
        SelectedDriveHeader     = "  SELECTED DRIVE: {0} ({1}) - {2}"
        DriveDetails            = "  File System: {0} | Total Size: {1} | Free Space: {2}"
        WarningReadOnly         = "  [!] WARNING: THIS FLASH DRIVE IS IN READ-ONLY (WRITE-PROTECTED) STATE!"
        WarningReadOnlyAdvice   = "      Recommended: [5] Repair Read-Only Flash Drive (Backup -> Unlock)"
        ActionMenuHeader        = " SELECT OPERATION:"
        ActionMenu1             = "  [1] Full Disk Recovery (Backup all files and folders to desktop)"
        ActionMenu2             = "  [2] Shortcut Virus & Hidden Files Recovery (Unhide & recover real data)"
        ActionMenu3             = "  [3] Selective File Type Recovery (Photos, Documents, Videos, etc.)"
        ActionMenu4             = "  [4] Custom Directory / Folder Recovery (Interactive explorer)"
        ActionMenu5             = "  [5] Repair Read-Only / Write-Protected Flash (Backup First -> Unlock)"
        ActionMenu6             = "  [6] View Disk Health and Hardware Details"
        ActionMenu0             = "  [0] Select Another Drive / Back"
        PromptActionChoice      = " Your choice [1-6 or 0]"
        ShortcutScanning        = " [*] Scanning for real files hidden by shortcut viruses (.lnk/.vbs)..."
        SelectFileTypeHeader    = " SELECT FILE TYPE CATEGORY TO RECOVER:"
        FileTypeDocs            = "  [1] Documents (PDF, Word, Excel, PowerPoint, TXT, CSV, RTF...)"
        FileTypePhotos          = "  [2] Photos & Images (JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD...)"
        FileTypeVideos          = "  [3] Videos (MP4, MKV, AVI, MOV, WMV, FLV, WEBM...)"
        FileTypeAudio           = "  [4] Audio (MP3, WAV, FLAC, AAC, M4A, OGG...)"
        FileTypeArchives        = "  [5] Archives (ZIP, RAR, 7Z, TAR, GZ, ISO...)"
        FileTypeCode            = "  [6] Code & Projects (PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON...)"
        FileTypeCustom          = "  [7] Custom File Extensions (e.g., .dwg, .psd)"
        FileTypeCancel          = "  [0] Cancel"
        PromptFileType          = " Your choice [1-7 or 0]"
        PromptCustomExts        = " Enter file extensions separated by commas (e.g., .dwg, .psd, .blend)"
        RootFoldersHeader       = " Directories in drive root:"
        NoDirsFound             = " [!] No directories found in root path."
        PromptDirIndex          = " Enter the number of the directory to recover [1-{0}]"
        InvalidDirIndex         = " [!] Invalid directory number."
        HardwareDetailsHeader   = " HARDWARE AND DRIVE DETAILS:"
        DetailDriveLetter       = " Drive Letter      : {0}"
        DetailDiskModel         = " Disk Model        : {0}"
        DetailDiskNumber        = " Physical Disk No  : {0}"
        DetailBusType           = " Bus / Connection  : {0}"
        DetailFileSystem        = " File System       : {0}"
        DetailTotalCap          = " Total Capacity    : {0}"
        DetailFreeSpace         = " Free Space        : {0}"
        DetailUsedSpace         = " Used Space        : {0}"
        DetailIsReadOnly        = " Is Read-Only?     : {0}"
        DetailHealth            = " Health Status     : {0}"
        DetailOperational       = " Operational Status: {0}"
        PressEnterToReturn      = " Press Enter to return to menu..."
        InvalidMenuOption       = " [!] Please choose one of the available options from the menu."

        LangMenuTitle           = " LANGUAGE SELECTION / DIL SECIMI"
        LangOptionEN            = "  [1] English"
        LangOptionTR            = "  [2] Turkce"
        LangPrompt              = " Choose language / Dil seciniz [1-2]"
        LangSwitchedEN          = " [OK] Language switched to English."
        LangSwitchedTR          = " [OK] Dil Turkce olarak ayarlandi."

        HelpHeader              = " PS-RECOVER COMMAND LINE USAGE"
        HelpSyntax              = " Syntax: recover [-Drive <Letter>] [-List] [-Install] [-Uninstall] [-Lang <en|tr>] [-Help]"
        HelpParamDrive          = "  -Drive <Letter>   Specifies target drive directly."
        HelpParamList           = "  -List             Lists connected drives and exit."
        HelpParamInstall        = "  -Install          Permanently registers 'recover' command in PowerShell profile."
        HelpParamUninstall      = "  -Uninstall        Removes 'recover' command and configuration from system."
        HelpParamLang           = "  -Lang <en|tr>     Sets interface language ('en' for English, 'tr' for Turkish)."
        HelpParamHelp           = "  -Help             Displays this help screen."
    }
    tr = @{
        BannerTitle             = "Windows Disk, USB ve Flash Bellek Kurtarma Araci v1.0"
        AdminModeOn             = "YONETICI (ADMIN) - Tum diskpart ve kilit acma yetkileri aktif"
        AdminModeOff            = "STANDART KULLANICI (Salt okunur donanim duzeltmesi icin Yonetici onerilir)"
        SessionMode             = " [i] Oturum Modu: "

        DrivesHeader            = " TAKILI DISKLER VE DEPOLAMA BIRIMLERI:"
        ColNum                  = "#"
        ColDrive                = "SURUCU"
        ColModel                = "MODEL / ETIKET"
        ColType                 = "TUR"
        ColFS                   = "FS"
        ColTotal                = "TOPLAM"
        ColFree                 = "BOS ALAN"
        ColStatus               = "DURUM"
        StatusNormal            = "[NORMAL]"
        StatusReadOnly          = "[SALT OKUNUR / KILITLI]"
        StatusSystem            = "[SISTEM DISKI]"
        NoDrivesFound           = " [!] Sistemde erisilebilir herhangi bir disk/surucu bulunamadi."
        Unknown                 = "Bilinmiyor"
        Unlabeled               = "(Etiketsiz)"
        GenericDisk             = "Depolama Aygiti"
        StandardDisk            = "Standart Disk"
        DiskWord                = "Disk"

        TypeUsb                 = "USB Flash / Harici"
        TypeNvme                = "NVMe SSD (Dahili)"
        TypeSata                = "SATA Disk (Dahili)"
        TypeRemovable           = "Cikarilabilir Bellek"
        TypeFixed               = "Sabit Disk (Dahili)"
        TypeOptical             = "Optik Surucu (CD/DVD)"
        TypeNetwork             = "Ag Surucusu"
        TypeLogical             = "Mantiksal Surucu"

        RecoveryFolderPrefix    = "Kurtarma"
        ReportFileName          = "kurtarma_raporu.txt"
        SourceDrive             = " [>] Kaynak Surucu  : "
        DestFolder              = " [>] Hedef Klasor   : "
        ScanMode                = " [>] Tarama Modu    : "
        ScanningFiles           = " [*] Dosyalar taraniyor, lutfen bekleyin..."
        ScanError               = " [!] Dosya listesi alinirken bir hata olustu: {0}"
        NoFilesFound            = " [!] Secilen kriterlere uygun kurtarilacak dosya bulunamadi."
        FilesFoundStarting      = " [+] Toplam {0} adet dosya bulundu ({1}). Kurtarma baslatiliyor..."
        ProgressActivity        = "Dosyalar Kurtariliyor (Masaustu\recovered)"
        ProgressStatus          = "[{0} / {1}] ({2}%) {3}"
        ProgressDone            = "Dosyalar Kurtariliyor"
        StatusSuccess           = "Basarili"
        StatusError             = "Hata"

        ReportTitle             = "                          KURTARMA RAPORU OZETI                             "
        ReportLabelSource       = " Kaynak Surucu           : {0} ({1})"
        ReportLabelDest         = " Hedef Klasor            : {0}"
        ReportLabelTotal        = " Toplam Taranan Dosya    : {0}"
        ReportLabelSuccess      = " Basariyla Kurtarilan    : {0}"
        ReportLabelFailed       = " Okunamayan / Hatali     : {0}"
        ReportLabelSize         = " Kurtarilan Toplam Boyut : {0}"
        ReportLabelElapsed      = " Gecen Sure              : {0}"
        ReportFilesHeader       = " KURTARILAN DOSYALAR (Ilk {0} dosya gosteriliyor):"
        ReportMoreFiles         = " ... ve {0} dosya daha kurtarildi (Tam liste rapor dosyasina yazildi)."
        ReportSaved             = " [OK] Detayli rapor dosyasi kaydedildi: {0}"
        ReportSaveError         = " [!] Rapor dosyasi yazilamadi: {0}"
        OpenFolderPrompt        = " Kurtarilan dosyalarin bulundugu klasor dosya gezgininde acilsin mi? [E/H]"

        FileReportHeader        = "                       PS-RECOVER KURTARMA RAPORU                          "
        FileReportDate          = " Tarih                  : {0}"
        FileReportSource        = " Kaynak Disk / Surucu   : {0} ({1})"
        FileReportFS            = " Dosya Sistemi          : {0}"
        FileReportTarget        = " Hedef Klasor           : {0}"
        FileReportTotal         = " Toplam Taranan Dosya   : {0}"
        FileReportSuccess       = " Basariyla Kurtarilan   : {0}"
        FileReportErrors        = " Hatali / Okunamayan    : {0}"
        FileReportSize          = " Toplam Kurtarilan Boyut: {0}"
        FileReportElapsed       = " Gecen Sure             : {0}"
        FileReportListHeader    = "DOSYA LISTESI:"

        RepairTitle             = "            SALT OKUNUR (YAZMA KORUMALI) FLASH BELLEK ONARIMI               "
        TargetDriveLabel        = " Hedef Bellek : {0} [{1}] - {2}"
        RepairExplanation1      = " Flash bellekler genellikle asagidaki 2 sebepten oturu salt okunur kalir:"
        RepairExplanation2      = "  1. Yazilimsal Kilitler: Diskpart ozniteligi, bozuk dosya sistemi, Registry korumasi veya virusler."
        RepairExplanation3      = "  2. Donanimsal Koruma (NAND Wear-Out): Yipranan bellek hucreleri bozulmasin diye kontrolcu"
        RepairExplanation4      = "     cihazi kalici okuma moduna kilitler."
        Step1Title              = " [ADIM 1 / GUVENLIK YEDEKLEMESI]"
        Step1Warn               = " Kilit acma islemleri bellek kontrolcusunu zorlayabilir. Onarima baslamadan once"
        Step1Prompt             = " bellekteki tum dosyalar Masaustu\recovered klasorune YEDEKLENSIN MI?"
        Step1Confirm            = " [Onerilen] Dosyalar simdi masaustune yedeklensin mi? [E/H] (Varsayilan: E)"
        Step1Starting           = " [*] Flash bellegin tam guvenlik yedegi aliniyor..."
        Step1Skipped            = " [!] Yedekleme adimi kullanici tarafindan atlandi."
        Step2Title              = " [ADIM 2 / KILIT ACMA VE ONARIM ISLEMLERI BASLATILIYOR]"
        Step2AdminWarn1         = " [!] UYARI: Diskpart ve Registry uzerinden yazma korumasini kaldirmak icin"
        Step2AdminWarn2         = "     YONETICI (Administrator) yetkileri zorunludur."
        Step2ElevatePrompt      = " Yonetici olarak yeni bir PowerShell penceresi baslatilsin mi? [E/H]"
        Step2LimitedMode        = " [!] Yonetici izni olmadan sadece sinirli dosya oznitelik temizligi yapilabilecek."
        DiskpartRunning         = " [*] Diskpart ile disk ve birim salt okunur bayraklari temizleniyor..."
        DiskpartSuccess         = " [OK] Diskpart komutlari uygulandi."
        DiskpartError           = " [!] Diskpart calistirilamadi: {0}"
        StorageApiRunning       = " [*] Windows Storage API ile disk salt okunurlugu kapatiliyor..."
        StorageApiSuccess       = " [OK] Storage API ayarlari guncellendi."
        RegistryRunning         = " [*] Kayit Defteri (Registry) StorageDevicePolicies kontrol ediliyor..."
        RegistryCleared         = " [OK] Registry'deki global 'WriteProtect = 1' kilidi 0 yapildi!"
        RegistryNoLock          = " [i] Registry'de sistem geneli yazma engeli bulunmuyor."
        RegistryError           = " [!] Registry erisiminde hata: {0}"
        AttribRunning           = " [*] Bellek uzerindeki tum dosya ve klasorlerin salt okunur oznitelikleri kaldiriliyor..."
        AttribSuccess           = " [OK] Dosya sistemi oznitelikleri (attrib -r -s -h) temizlendi."
        ChkdskExplanation       = " Bozuk dosya sistemi veya kapatilmamis 'dirty bit' bayragi Windows'un bellegi korumaya almasina neden olabilir."
        ChkdskPrompt            = " Surucuye dosya sistemi onarimi (chkdsk {0} /f) uygulansin mi? [E/H]"
        ChkdskRunning           = " [*] Chkdsk calistiriliyor, lutfen bekleyin..."
        ChkdskSuccess           = " [OK] Chkdsk tamamlandi."
        ChkdskError             = " [!] Chkdsk hatasi: {0}"
        Step3Title              = " [ADIM 3 / YAZMA DOGRULAMA VE TESHIS TESTI]"
        Step3Running            = " [*] Surucuye test verisi yazilarak kilit durumu kontrol ediliyor..."
        VerificationSuccess     = "  TEBRIKLER! FLASH BELLEK YAZMA KILIDI BASARIYLA KALDIRILDI!               "
        VerificationSuccessDesc = " [OK] Surucu artik salt okunur degil. Dosya ekleyebilir, silebilir ve bicimlendirebilirsiniz."
        VerificationHardwareLock= "  DONANIMSAL KORUMA (HARDWARE WRITE-LOCK) TESHIS EDILDI                     "
        HardwareLockDesc1       = " [!] Yazilimsal tum kilitler (Diskpart, Registry, Attrib, Dosya Izinleri) kaldirildi"
        HardwareLockDesc2       = "     ancak bellek kontrolcusu (NAND Controller) yazma komutunu reddetti."
        HardwareLockError       = "     Hata: {0}"
        TechnicalDiagnosisHeader= " TEKNIK TESHIS VE TAVSIYE:"
        HardwareDiagnosis1      = "  Flash bellegin yongalari (NAND flash) omrunu doldurdugunda veya fiziksel bad sector"
        HardwareDiagnosis2      = "  olustugunda, donanim kontrolcusu verilerinizin tamamen silinmesini veya bozulmasini"
        HardwareDiagnosis3      = "  onlemek amaciyla bellegi 'Kalici Donanimsal Salt Okunur (Hardware ROM)' moduna alir."
        HardwareGoodNews        = "  IYI HABER: Verileriniz ilk adimda Masaustunuzdeki 'recovered' klasorune guvenle kurtarildi!"
        HardwareReplacementAdvice= "  Bu bellek artik guvenilir degildir; yeni bir bellek kullanmaniz siddetle onerilir."

        InstallStarting         = " [*] 'recover' komutu PowerShell profilinize kuruluyor..."
        InstallSuccess          = " [OK] 'recover' komutu basariyla PowerShell profilinize eklendi!"
        InstallProfilePath      = " [i] Profil dosyasi: {0}"
        InstallUsageHint        = " [i] Artik PowerShell'i her actiginizda sadece 'recover' yazmaniz yeterli!"
        InstallAlreadyPresent   = " [i] 'recover' komutu zaten profilinizde mevcut."
        UninstallStarting       = " [*] 'recover' komutu PowerShell profilinden kaldiriliyor..."
        UninstallSuccessProfile = " [OK] Profil kaydi temizlendi."
        UninstallSuccessFolder  = " [OK] Yerel kurulum klasoru temizlendi ({0})."
        UninstallComplete       = " [OK] PS-Recover basariyla kaldirildi."

        MenuOptionsHeader       = " SECENEKLER:"
        MenuOptionDriveSelect   = "  [1-{0}] Bir disk secin ve kurtarma/onarim islemlerine baslayin"
        MenuOptionRescan        = "  [R]   Diskleri yeniden tara (Yeni bir flash bellek taktiysaniz)"
        MenuOptionInstall       = "  [P]   Bu araci 'recover' komutu olarak PowerShell'e kalici yukle"
        MenuOptionLanguage      = "  [L]   Dili Degistir / Change Language (Aktif: Turkce)"
        MenuOptionQuit          = "  [Q]   Cikis"
        PromptMainSelection     = " Lutfen islem yapmak istediginiz diskin numarasini veya secenegi girin"
        ExitMessage             = " [OK] Cikis yapildi. Iyi calismalar!"
        RescanningDisks         = " [*] Diskler yeniden taraniyor..."
        PressEnterToContinue    = " Devam etmek icin Enter'a basin..."
        InvalidSelection        = " [!] Gecersiz secim yaptiniz. Lutfen listedeki bir numara veya surucu harfi girin."
        SelectedDriveHeader     = "  SECILEN SURUCU: {0} ({1}) - {2}"
        DriveDetails            = "  Dosya Sistemi: {0} | Toplam Boyut: {1} | Bos Alan: {2}"
        WarningReadOnly         = "  [!] UYARI: BU FLASH BELLEK SALT OKUNUR (YAZMA KORUMALI) DURUMDADIR!"
        WarningReadOnlyAdvice   = "      Onerilen: [5] Salt Okunur Flashi Yedekle ve Kilidi Kaldir"
        ActionMenuHeader        = " YAPILACAK ISLEMI SECIN:"
        ActionMenu1             = "  [1] Tam Disk Kurtarma (Tum dosya ve klasorleri masaustune yedekle)"
        ActionMenu2             = "  [2] Kisayol Virusu & Gizli Dosyalari Kurtar (Gizli dosyalari aciga cikar ve kurtar)"
        ActionMenu3             = "  [3] Belirli Dosya Turlerini Kurtar (Fotograf, Belge, Video, vb.)"
        ActionMenu4             = "  [4] Ozel Klasor veya Dosya Secerek Kurtar (Interaktif gezgin)"
        ActionMenu5             = "  [5] Salt Okunur / Yazma Korumali Flashi Duzelt (Once Yedekler -> Kilidi Acar)"
        ActionMenu6             = "  [6] Disk Sagligi ve Donanim Ayrintilarini Goruntule"
        ActionMenu0             = "  [0] Farkli Surucu Sec / Geri Don"
        PromptActionChoice      = " Seciminiz [1-6 veya 0]"
        ShortcutScanning        = " [*] Kisayol virusu (Shortcut virus) tarafindan gizlenen gercek dosyalar"
        SelectFileTypeHeader    = " KURTARILACAK DOSYA TURUNU SECIN:"
        FileTypeDocs            = "  [1] Belgeler (PDF, Word, Excel, PowerPoint, TXT, CSV, RTF...)"
        FileTypePhotos          = "  [2] Fotograflar (JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD...)"
        FileTypeVideos          = "  [3] Videolar (MP4, MKV, AVI, MOV, WMV, FLV, WEBM...)"
        FileTypeAudio           = "  [4] Sesler (MP3, WAV, FLAC, AAC, M4A, OGG...)"
        FileTypeArchives        = "  [5] Arsivler (ZIP, RAR, 7Z, TAR, GZ, ISO...)"
        FileTypeCode            = "  [6] Kod ve Projeler (PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON...)"
        FileTypeCustom          = "  [7] Ozel Uzanti Belirt (orn: .dwg, .psd)"
        FileTypeCancel          = "  [0] Iptal"
        PromptFileType          = " Seciminiz [1-7 veya 0]"
        PromptCustomExts        = " Kurtarmak istediginiz uzantilari virgulle ayirarak girin (orn: .dwg, .psd, .blend)"
        RootFoldersHeader       = " Surucu kok dizinindeki klasorler:"
        NoDirsFound             = " [!] Kok dizinde taranabilecek klasor bulunamadi."
        PromptDirIndex          = " Kurtarmak istediginiz klasorun numarasini girin [1-{0}]"
        InvalidDirIndex         = " [!] Gecersiz klasor numarasi."
        HardwareDetailsHeader   = " DONANIM VE SURUCU AYRINTILARI:"
        DetailDriveLetter       = " Surucu Harfi     : {0}"
        DetailDiskModel         = " Disk Modeli      : {0}"
        DetailDiskNumber        = " Fiziksel Disk No : {0}"
        DetailBusType           = " Baglanti Turu    : {0}"
        DetailFileSystem        = " Dosya Sistemi    : {0}"
        DetailTotalCap          = " Toplam Kapasite  : {0}"
        DetailFreeSpace         = " Bos Alan         : {0}"
        DetailUsedSpace         = " Kullanilan Alan  : {0}"
        DetailIsReadOnly        = " Salt Okunur mu?  : {0}"
        DetailHealth            = " Saglik Durumu    : {0}"
        DetailOperational       = " Calisma Durumu   : {0}"
        PressEnterToReturn      = " Menuye donmek icin Enter'a basin..."
        InvalidMenuOption       = " [!] Lutfen menudeki seceneklerden birini girin."

        LangMenuTitle           = " DIL SECIMI / LANGUAGE SELECTION"
        LangOptionEN            = "  [1] English"
        LangOptionTR            = "  [2] Turkce"
        LangPrompt              = " Dil seciniz / Choose language [1-2]"
        LangSwitchedEN          = " [OK] Language switched to English."
        LangSwitchedTR          = " [OK] Dil Turkce olarak ayarlandi."

        HelpHeader              = " PS-RECOVER KOMUT SATIRI KULLANIMI"
        HelpSyntax              = " Sozdizimi: recover [-Drive <Harf>] [-List] [-Install] [-Uninstall] [-Lang <en|tr>] [-Help]"
        HelpParamDrive          = "  -Drive <Harf>     Hedef surucuyu dogrudan belirler."
        HelpParamList           = "  -List             Takili diskleri listeler ve cikar."
        HelpParamInstall        = "  -Install          'recover' komutunu kalici olarak PowerShell profiline ekler."
        HelpParamUninstall      = "  -Uninstall        'recover' komutunu ve yapilandirmayi sistemden kaldirir."
        HelpParamLang           = "  -Lang <en|tr>     Arayuz dilini belirler ('en': Ingilizce, 'tr': Turkce)."
        HelpParamHelp           = "  -Help             Bu yardim ekranini goruntuler."
    }
}

function global:Set-PSRecoverLanguage {
    param([string]$Language)
    $clean = $Language.Trim().ToLower()
    if ($clean -in @("en", "english", "us", "uk")) {
        $script:PSRecoverLang = "en"
    } elseif ($clean -in @("tr", "turkish", "turkce")) {
        $script:PSRecoverLang = "tr"
    } else {
        $script:PSRecoverLang = "en"
    }
    
    try {
        $confDir = Join-Path $HOME ".ps-recover"
        if (-not (Test-Path $confDir)) {
            New-Item -ItemType Directory -Path $confDir -Force | Out-Null
        }
        Set-Content -Path (Join-Path $confDir "lang.conf") -Value $script:PSRecoverLang -Force -ErrorAction SilentlyContinue
    } catch {}
}

function global:Get-PSRecoverLanguage {
    if (-not [string]::IsNullOrWhiteSpace($script:PSRecoverLang)) {
        return $script:PSRecoverLang
    }
    
    if (-not [string]::IsNullOrWhiteSpace($env:PS_RECOVER_LANG)) {
        $candidate = $env:PS_RECOVER_LANG.Trim().ToLower()
        if ($candidate -in @("en", "tr")) {
            $script:PSRecoverLang = $candidate
            return $script:PSRecoverLang
        }
    }
    
    $confFile = Join-Path (Join-Path $HOME ".ps-recover") "lang.conf"
    if (Test-Path $confFile) {
        try {
            $saved = (Get-Content -Path $confFile -Raw -ErrorAction SilentlyContinue).Trim().ToLower()
            if ($saved -in @("en", "tr")) {
                $script:PSRecoverLang = $saved
                return $script:PSRecoverLang
            }
        } catch {}
    }
    
    try {
        $cultureName = (Get-Culture).TwoLetterISOLanguageName.ToLower()
        if ($cultureName -eq "tr") {
            $script:PSRecoverLang = "tr"
            return $script:PSRecoverLang
        }
    } catch {}
    
    $script:PSRecoverLang = "en"
    return $script:PSRecoverLang
}

function global:Get-PSRecoverText {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Key,
        [Parameter(Position=1, ValueFromRemainingArguments=$true)]
        [object[]]$FormatArgs
    )
    $lang = Get-PSRecoverLanguage
    $dict = $script:PSRecoverStrings[$lang]
    if (-not $dict) {
        $dict = $script:PSRecoverStrings["en"]
    }
    
    $val = $dict[$Key]
    if ($null -eq $val) {
        $val = $script:PSRecoverStrings["en"][$Key]
    }
    if ($null -eq $val) {
        return $Key
    }
    
    if ($FormatArgs -and $FormatArgs.Count -gt 0) {
        if ($FormatArgs.Count -eq 1 -and ($FormatArgs[0] -is [System.Collections.IEnumerable]) -and ($FormatArgs[0] -isnot [string])) {
            $FormatArgs = @($FormatArgs[0])
        }
        try {
            return ($val -f $FormatArgs)
        } catch {
            return $val
        }
    }
    return $val
}

function global:T {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Key,
        [Parameter(Position=1, ValueFromRemainingArguments=$true)]
        [object[]]$FormatArgs
    )
    Get-PSRecoverText -Key $Key -FormatArgs $FormatArgs
}

function global:Get-PSRecoverDriveList {
    <#
    .SYNOPSIS
        Detects connected physical and logical storage drives.
    #>
    $driveList = @()
    
    $volumes = @()
    $disks = @()
    $partitions = @()
    
    try {
        $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -ne $null }
    } catch {}
    
    try {
        $disks = Get-Disk -ErrorAction SilentlyContinue
    } catch {}
    
    try {
        $partitions = Get-Partition -ErrorAction SilentlyContinue
    } catch {}

    if ($volumes -and $volumes.Count -gt 0) {
        $index = 1
        foreach ($vol in $volumes) {
            $letter = "$($vol.DriveLetter):"
            $part = $partitions | Where-Object { $_.DriveLetter -eq $vol.DriveLetter } | Select-Object -First 1
            $disk = if ($part) { $disks | Where-Object { $_.Number -eq $part.DiskNumber } | Select-Object -First 1 } else { $null }

            $busType = T 'Unknown'
            $diskModel = T 'StandardDisk'
            $isReadOnly = $false
            $isSystem = ($letter -ieq $env:SystemDrive)

            if ($disk) {
                $busType = $disk.BusType.ToString()
                $diskModel = if ($disk.FriendlyName) { $disk.FriendlyName } else { "$((T 'DiskWord')) $($disk.Number)" }
                $isReadOnly = ($disk.IsReadOnly -eq $true)
            } else {
                $busType = $vol.DriveType.ToString()
            }

            $userFriendlyType = switch -Wildcard ($busType) {
                "*USB*"       { T 'TypeUsb' }
                "*NVMe*"      { T 'TypeNvme' }
                "*SATA*"      { T 'TypeSata' }
                "*Removable*" { T 'TypeRemovable' }
                "*Fixed*"     { T 'TypeFixed' }
                "*CD*"        { T 'TypeOptical' }
                default       { $busType }
            }

            $label = if ([string]::IsNullOrWhiteSpace($vol.FileSystemLabel)) { T 'Unlabeled' } else { $vol.FileSystemLabel }
            $fs = if ([string]::IsNullOrWhiteSpace($vol.FileSystem)) { T 'Unknown' } else { $vol.FileSystem }

            $totalBytes = [int64]$vol.Size
            $freeBytes = [int64]$vol.SizeRemaining
            $usedBytes = $totalBytes - $freeBytes

            $totalGB = [math]::Round($totalBytes / 1GB, 2)
            $freeGB  = [math]::Round($freeBytes / 1GB, 2)
            $usedGB  = [math]::Round($usedBytes / 1GB, 2)

            $driveList += [PSCustomObject]@{
                Index             = $index
                DriveLetter       = $letter
                RootPath          = "$letter\"
                Label             = $label
                DiskModel         = $diskModel
                DiskNumber        = if ($disk) { $disk.Number } else { -1 }
                BusType           = $busType
                DriveTypeDesc     = $userFriendlyType
                FileSystem        = $fs
                TotalBytes        = $totalBytes
                FreeBytes         = $freeBytes
                UsedBytes         = $usedBytes
                TotalGB           = $totalGB
                FreeGB            = $freeGB
                UsedGB            = $usedGB
                IsReadOnly        = $isReadOnly
                IsSystem          = $isSystem
                HealthStatus      = if ($disk) { $disk.HealthStatus.ToString() } else { T 'Unknown' }
                OperationalStatus = if ($disk) { $disk.OperationalStatus.ToString() } else { "OK" }
            }
            $index++
        }
    } else {
        $logicalDisks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue
        $index = 1
        foreach ($ld in $logicalDisks) {
            $letter = $ld.DeviceID
            $isSystem = ($letter -ieq $env:SystemDrive)
            $typeDesc = switch ($ld.DriveType) {
                2 { T 'TypeUsb' }
                3 { T 'TypeFixed' }
                4 { T 'TypeNetwork' }
                5 { T 'TypeOptical' }
                default { T 'TypeLogical' }
            }

            $totalBytes = [int64]$ld.Size
            $freeBytes  = [int64]$ld.FreeSpace
            $usedBytes  = $totalBytes - $freeBytes
            $label = if ([string]::IsNullOrWhiteSpace($ld.VolumeName)) { T 'Unlabeled' } else { $ld.VolumeName }
            $fs = if ([string]::IsNullOrWhiteSpace($ld.FileSystem)) { T 'Unknown' } else { $ld.FileSystem }

            $driveList += [PSCustomObject]@{
                Index             = $index
                DriveLetter       = $letter
                RootPath          = "$letter\"
                Label             = $label
                DiskModel         = T 'GenericDisk'
                DiskNumber        = -1
                BusType           = "Generic"
                DriveTypeDesc     = $typeDesc
                FileSystem        = $fs
                TotalBytes        = $totalBytes
                FreeBytes         = $freeBytes
                UsedBytes         = $usedBytes
                TotalGB           = [math]::Round($totalBytes / 1GB, 2)
                FreeGB            = [math]::Round($freeBytes / 1GB, 2)
                UsedGB            = [math]::Round($usedBytes / 1GB, 2)
                IsReadOnly        = $false
                IsSystem          = $isSystem
                HealthStatus      = T 'Unknown'
                OperationalStatus = "OK"
            }
            $index++
        }
    }

    return ,$driveList
}

function global:Test-IsAdminUser {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function global:Format-ByteSize {
    param([int64]$Bytes)
    
    if ($Bytes -ge 1TB) { return "$([math]::Round($Bytes / 1TB, 2)) TB" }
    if ($Bytes -ge 1GB) { return "$([math]::Round($Bytes / 1GB, 2)) GB" }
    if ($Bytes -ge 1MB) { return "$([math]::Round($Bytes / 1MB, 2)) MB" }
    if ($Bytes -ge 1KB) { return "$([math]::Round($Bytes / 1KB, 2)) KB" }
    return "$Bytes B"
}

function global:Show-PSRecoverBanner {
    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host "   ____  ____        ____                                          " -ForegroundColor Cyan
    Write-Host "  |  _ \/ ___|      |  _ \ ___  ___ _____   _____ _ __ _   _       " -ForegroundColor Cyan
    Write-Host "  | |_) \___ \ _____| |_) / _ \/ __/ _ \ \ / / _ \ '__| | | |      " -ForegroundColor White
    Write-Host "  |  __/ ___) |_____|  _ <  __/ (_| (_) \ V /  __/ |  | |_| |      " -ForegroundColor White
    Write-Host "  |_|   |____/      |_| \_\___|\___\___/ \_/ \___|_|   \__, |      " -ForegroundColor Cyan
    Write-Host "                                                        |___/       " -ForegroundColor Cyan
    Write-Host ("       {0}         " -f (T 'BannerTitle')) -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    
    $isAdmin = Test-IsAdminUser
    if ($isAdmin) {
        Write-Host (T 'SessionMode') -NoNewline -ForegroundColor Gray
        Write-Host (T 'AdminModeOn') -ForegroundColor Green
    } else {
        Write-Host (T 'SessionMode') -NoNewline -ForegroundColor Gray
        Write-Host (T 'AdminModeOff') -ForegroundColor Yellow
    }
    Write-Host ""
}

function global:Show-PSRecoverDrivesTable {
    param([array]$Drives)

    if (-not $Drives -or $Drives.Count -eq 0) {
        Write-Host (T 'NoDrivesFound') -ForegroundColor Red
        return
    }

    Write-Host (T 'DrivesHeader') -ForegroundColor Yellow
    Write-Host " ---------------------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host (" {0,-4} {1,-6} {2,-24} {3,-18} {4,-6} {5,10} {6,10}  {7}" -f `
        (T 'ColNum'), (T 'ColDrive'), (T 'ColModel'), (T 'ColType'), (T 'ColFS'), (T 'ColTotal'), (T 'ColFree'), (T 'ColStatus')) -ForegroundColor Cyan
    Write-Host " ---------------------------------------------------------------------------------------------" -ForegroundColor Gray

    foreach ($d in $Drives) {
        $statusText = T 'StatusNormal'
        $statusColor = "Green"

        if ($d.IsReadOnly) {
            $statusText = T 'StatusReadOnly'
            $statusColor = "Red"
        } elseif ($d.IsSystem) {
            $statusText = T 'StatusSystem'
            $statusColor = "Cyan"
        }

        $labelModel = "$($d.DiskModel)"
        if ($d.Label -ne (T 'Unlabeled')) {
            $labelModel = "$($d.Label) ($($d.DiskModel))"
        }
        if ($labelModel.Length -gt 23) {
            $labelModel = $labelModel.Substring(0, 20) + "..."
        }

        $line = (" [{0}]  {1,-6} {2,-24} {3,-18} {4,-6} {5,10} {6,10}  " -f `
            $d.Index, `
            $d.DriveLetter, `
            $labelModel, `
            $d.DriveTypeDesc, `
            $d.FileSystem, `
            "$(Format-ByteSize $d.TotalBytes)", `
            "$(Format-ByteSize $d.FreeBytes)")

        Write-Host $line -NoNewline -ForegroundColor White
        Write-Host $statusText -ForegroundColor $statusColor
    }
    Write-Host " ---------------------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
}

function global:Invoke-FileRecoveryEngine {
    <#
    .SYNOPSIS
        Scans files from selected drive, safely copies to Desktop\recovered,
        normalizes attributes and outputs a report.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$SelectedDrive,
        [Parameter(Mandatory=$true)]
        [string]$Mode, # "All", "Unhide", "Preset", "Selective"
        [string[]]$Extensions = @(),
        [string]$CustomSourcePath = ""
    )

    $desktop = [Environment]::GetFolderPath("Desktop")
    $recoveredBaseDir = Join-Path $desktop "recovered"
    
    if (-not (Test-Path $recoveredBaseDir)) {
        New-Item -ItemType Directory -Path $recoveredBaseDir -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $cleanLetter = ($SelectedDrive.DriveLetter -replace '[:\\]','').Trim()
    $folderPrefix = T 'RecoveryFolderPrefix'
    $sessionFolderName = "${folderPrefix}_${cleanLetter}_${timestamp}"
    $destinationDir = Join-Path $recoveredBaseDir $sessionFolderName
    if (Test-Path $destinationDir) {
        $sessionFolderName = "${folderPrefix}_${cleanLetter}_${timestamp}_$(Get-Random -Minimum 100 -Maximum 999)"
        $destinationDir = Join-Path $recoveredBaseDir $sessionFolderName
    }
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null

    $sourceRoot = if (![string]::IsNullOrEmpty($CustomSourcePath)) { $CustomSourcePath } else { $SelectedDrive.RootPath }

    Write-Host ""
    Write-Host (T 'SourceDrive') -NoNewline -ForegroundColor Gray
    Write-Host "$sourceRoot ($($SelectedDrive.DiskModel))" -ForegroundColor Cyan
    Write-Host (T 'DestFolder') -NoNewline -ForegroundColor Gray
    Write-Host "$destinationDir" -ForegroundColor Green
    Write-Host (T 'ScanMode') -NoNewline -ForegroundColor Gray
    Write-Host "$Mode" -ForegroundColor Yellow
    Write-Host ""
    Write-Host (T 'ScanningFiles') -ForegroundColor Gray

    $scannedFiles = @()
    try {
        if ($Mode -eq "Preset" -and $Extensions.Count -gt 0) {
            $allFiles = Get-ChildItem -Path $sourceRoot -Recurse -Force -File -ErrorAction SilentlyContinue
            $scannedFiles = $allFiles | Where-Object {
                $ext = $_.Extension.ToLower()
                $Extensions -contains $ext
            }
        } elseif ($Mode -eq "Unhide") {
            $allFiles = Get-ChildItem -Path $sourceRoot -Recurse -Force -File -ErrorAction SilentlyContinue
            $scannedFiles = $allFiles | Where-Object {
                $_.Extension.ToLower() -notin @(".lnk", ".vbs", ".wsf") -or $_.Length -gt 100KB
            }
        } else {
            $scannedFiles = Get-ChildItem -Path $sourceRoot -Recurse -Force -File -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host (T 'ScanError' @($_.Exception.Message)) -ForegroundColor Red
    }

    if (-not $scannedFiles -or $scannedFiles.Count -eq 0) {
        Write-Host (T 'NoFilesFound') -ForegroundColor Yellow
        return
    }

    $totalCount = $scannedFiles.Count
    $totalBytesToCopy = ($scannedFiles | Measure-Object -Property Length -Sum).Sum
    Write-Host (T 'FilesFoundStarting' @($totalCount, (Format-ByteSize $totalBytesToCopy))) -ForegroundColor Green
    Write-Host ""

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $recoveredList = New-Object System.Collections.ArrayList
    $successCount = 0
    $failedCount = 0
    $recoveredBytes = 0

    $currentIndex = 0
    foreach ($file in $scannedFiles) {
        $currentIndex++
        $percent = [math]::Round(($currentIndex / $totalCount) * 100)

        $relPath = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $targetFilePath = Join-Path $destinationDir $relPath
        $targetFolder = Split-Path -Path $targetFilePath -Parent

        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
        }

        Write-Progress -Activity (T 'ProgressActivity') `
            -Status (T 'ProgressStatus' @($currentIndex, $totalCount, $percent, $file.Name)) `
            -PercentComplete $percent

        $isSuccess = $false
        $errorMsg = ""

        try {
            [System.IO.File]::Copy($file.FullName, $targetFilePath, $true)
            $isSuccess = $true
        } catch {
            try {
                $inStream = New-Object System.IO.FileStream($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $outStream = New-Object System.IO.FileStream($targetFilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                $buffer = New-Object byte[] 65536
                while (($bytesRead = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $outStream.Write($buffer, 0, $bytesRead)
                }
                $outStream.Close()
                $inStream.Close()
                $isSuccess = $true
            } catch {
                $errorMsg = $_.Exception.Message
                $isSuccess = $false
            }
        }

        if ($isSuccess) {
            try {
                [System.IO.File]::SetAttributes($targetFilePath, [System.IO.FileAttributes]::Normal)
            } catch {}

            $successCount++
            $recoveredBytes += $file.Length
            [void]$recoveredList.Add([PSCustomObject]@{
                Name         = $file.Name
                RelativePath = $relPath
                Size         = $file.Length
                Status       = T 'StatusSuccess'
                Error        = ""
            })
        } else {
            $failedCount++
            [void]$recoveredList.Add([PSCustomObject]@{
                Name         = $file.Name
                RelativePath = $relPath
                Size         = $file.Length
                Status       = T 'StatusError'
                Error        = $errorMsg
            })
        }
    }

    Write-Progress -Activity (T 'ProgressDone') -Completed
    $sw.Stop()

    Show-RecoveryReportSummary -Drive $SelectedDrive `
                               -DestinationDir $destinationDir `
                               -TotalScanned $totalCount `
                               -SuccessCount $successCount `
                               -FailedCount $failedCount `
                               -RecoveredBytes $recoveredBytes `
                               -ElapsedTime $sw.Elapsed `
                               -FileList $recoveredList
}

function global:Show-RecoveryReportSummary {
    param(
        [PSCustomObject]$Drive,
        [string]$DestinationDir,
        [int]$TotalScanned,
        [int]$SuccessCount,
        [int]$FailedCount,
        [int64]$RecoveredBytes,
        [timespan]$ElapsedTime,
        $FileList
    )

    $elapsedStr = ("{0:D2}:{1:D2}:{2:D2}" -f $ElapsedTime.Hours, $ElapsedTime.Minutes, $ElapsedTime.Seconds)

    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Green
    Write-Host (T 'ReportTitle') -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Green
    Write-Host (T 'ReportLabelSource' @($Drive.DriveLetter, $Drive.DiskModel)) -ForegroundColor White
    Write-Host (T 'ReportLabelDest' @($DestinationDir)) -ForegroundColor Green
    Write-Host (T 'ReportLabelTotal' @($TotalScanned)) -ForegroundColor White
    Write-Host (T 'ReportLabelSuccess' @($SuccessCount)) -ForegroundColor Green
    Write-Host (T 'ReportLabelFailed' @($FailedCount)) -ForegroundColor $(if ($FailedCount -gt 0) { "Red" } else { "Gray" })
    Write-Host (T 'ReportLabelSize' @((Format-ByteSize $RecoveredBytes))) -ForegroundColor Cyan
    Write-Host (T 'ReportLabelElapsed' @($elapsedStr)) -ForegroundColor White
    Write-Host " ===========================================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host (T 'ReportFilesHeader' @(35)) -ForegroundColor Yellow
    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
    
    $displayLimit = 35
    $shownCount = 0
    foreach ($item in $FileList) {
        $shownCount++
        if ($shownCount -le $displayLimit) {
            if ($item.Status -eq (T 'StatusSuccess') -or $item.Status -eq "Success" -or $item.Status -eq "Basarili") {
                Write-Host " [OK]       " -NoNewline -ForegroundColor Green
                Write-Host ("\{0,-45} ({1})" -f $item.RelativePath, (Format-ByteSize $item.Size)) -ForegroundColor White
            } else {
                Write-Host " [FAIL]     " -NoNewline -ForegroundColor Red
                Write-Host ("\{0,-45} [{1}]" -f $item.RelativePath, $item.Error) -ForegroundColor Red
            }
        }
    }

    if ($FileList.Count -gt $displayLimit) {
        $remaining = $FileList.Count - $displayLimit
        Write-Host (T 'ReportMoreFiles' @($remaining)) -ForegroundColor Gray
    }
    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    $reportFileName = T 'ReportFileName'
    $reportFilePath = Join-Path $DestinationDir $reportFileName
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("===========================================================================")
    [void]$sb.AppendLine((T 'FileReportHeader'))
    [void]$sb.AppendLine((T 'FileReportDate' @((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))))
    [void]$sb.AppendLine((T 'FileReportSource' @($Drive.DriveLetter, $Drive.DiskModel)))
    [void]$sb.AppendLine((T 'FileReportFS' @($Drive.FileSystem)))
    [void]$sb.AppendLine((T 'FileReportTarget' @($DestinationDir)))
    [void]$sb.AppendLine((T 'FileReportTotal' @($TotalScanned)))
    [void]$sb.AppendLine((T 'FileReportSuccess' @($SuccessCount)))
    [void]$sb.AppendLine((T 'FileReportErrors' @($FailedCount)))
    [void]$sb.AppendLine((T 'FileReportSize' @((Format-ByteSize $RecoveredBytes))))
    [void]$sb.AppendLine((T 'FileReportElapsed' @($elapsedStr)))
    [void]$sb.AppendLine("===========================================================================")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((T 'FileReportListHeader'))
    [void]$sb.AppendLine("---------------------------------------------------------------------------")

    foreach ($item in $FileList) {
        $line = ("[{0}] \{1} ({2}) {3}" -f $item.Status, $item.RelativePath, (Format-ByteSize $item.Size), $item.Error).Trim()
        [void]$sb.AppendLine($line)
    }

    try {
        [System.IO.File]::WriteAllText($reportFilePath, $sb.ToString(), [System.Text.Encoding]::UTF8)
        Write-Host (T 'ReportSaved' @($reportFilePath)) -ForegroundColor Cyan
    } catch {
        Write-Host (T 'ReportSaveError' @($_.Exception.Message)) -ForegroundColor Red
    }

    if (-not $env:PS_RECOVER_NONINTERACTIVE) {
        Write-Host ""
        $openFolder = Read-Host (T 'OpenFolderPrompt')
        if ($openFolder -match "^[yYeE]") {
            try {
                Start-Process "explorer.exe" -ArgumentList "`"$DestinationDir`""
            } catch {}
        }
    }
}

function global:Repair-ReadOnlyFlashDrive {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$SelectedDrive
    )

    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Red
    Write-Host (T 'RepairTitle') -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Red
    Write-Host (T 'TargetDriveLabel' @($SelectedDrive.DriveLetter, $SelectedDrive.Label, $SelectedDrive.DiskModel)) -ForegroundColor White
    Write-Host ""
    Write-Host (T 'RepairExplanation1') -ForegroundColor Gray
    Write-Host (T 'RepairExplanation2') -ForegroundColor Gray
    Write-Host (T 'RepairExplanation3') -ForegroundColor Gray
    Write-Host (T 'RepairExplanation4') -ForegroundColor Gray
    Write-Host ""

    Write-Host (T 'Step1Title') -ForegroundColor Yellow
    Write-Host (T 'Step1Warn') -ForegroundColor White
    Write-Host (T 'Step1Prompt') -ForegroundColor White
    $doBackup = Read-Host (T 'Step1Confirm')
    if ([string]::IsNullOrWhiteSpace($doBackup) -or $doBackup -match "^[yYeE]") {
        Write-Host (T 'Step1Starting') -ForegroundColor Cyan
        Invoke-FileRecoveryEngine -SelectedDrive $SelectedDrive -Mode "All"
    } else {
        Write-Host (T 'Step1Skipped') -ForegroundColor Yellow
    }

    $isAdmin = Test-IsAdminUser
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host (T 'Step2AdminWarn1') -ForegroundColor Red
        Write-Host (T 'Step2AdminWarn2') -ForegroundColor Red
        Write-Host ""
        $elevate = Read-Host (T 'Step2ElevatePrompt')
        if ($elevate -match "^[yYeE]") {
            $scriptPath = $MyInvocation.MyCommand.Path
            $currentLang = Get-PSRecoverLanguage
            if ($scriptPath) {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "& '$scriptPath' -Lang $currentLang; recover -Lang $currentLang"
            } else {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "recover -Lang $currentLang"
            }
            return
        } else {
            Write-Host (T 'Step2LimitedMode') -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host (T 'Step2Title') -ForegroundColor Yellow

    if ($isAdmin -and $SelectedDrive.DiskNumber -ge 0) {
        Write-Host (T 'DiskpartRunning') -ForegroundColor Cyan
        $diskPartScript = @"
select disk $($SelectedDrive.DiskNumber)
attributes disk clear readonly
online disk
select volume $($SelectedDrive.DriveLetter.Substring(0,1))
attributes volume clear readonly
exit
"@
        $tempDpFile = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($tempDpFile, $diskPartScript)
        try {
            $dpOutput = & diskpart.exe /s $tempDpFile
            Write-Host (T 'DiskpartSuccess') -ForegroundColor Green
        } catch {
            Write-Host (T 'DiskpartError' @($_.Exception.Message)) -ForegroundColor Red
        } finally {
            Remove-Item $tempDpFile -Force -ErrorAction SilentlyContinue
        }
    }

    if ($isAdmin -and $SelectedDrive.DiskNumber -ge 0) {
        Write-Host (T 'StorageApiRunning') -ForegroundColor Cyan
        try {
            Set-Disk -Number $SelectedDrive.DiskNumber -IsReadOnly $false -ErrorAction SilentlyContinue
            Set-Disk -Number $SelectedDrive.DiskNumber -IsOffline $false -ErrorAction SilentlyContinue
            Write-Host (T 'StorageApiSuccess') -ForegroundColor Green
        } catch {}
    }

    if ($isAdmin) {
        Write-Host (T 'RegistryRunning') -ForegroundColor Cyan
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
        try {
            if (Test-Path $regPath) {
                $wp = Get-ItemProperty -Path $regPath -Name "WriteProtect" -ErrorAction SilentlyContinue
                if ($wp -and $wp.WriteProtect -eq 1) {
                    Set-ItemProperty -Path $regPath -Name "WriteProtect" -Value 0
                    Write-Host (T 'RegistryCleared') -ForegroundColor Green
                } else {
                    Write-Host (T 'RegistryNoLock') -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host (T 'RegistryError' @($_.Exception.Message)) -ForegroundColor Red
        }
    }

    Write-Host (T 'AttribRunning') -ForegroundColor Cyan
    try {
        & attrib.exe -r -s -h "$($SelectedDrive.DriveLetter)\*" /s /d 2>$null
        Write-Host (T 'AttribSuccess') -ForegroundColor Green
    } catch {}

    Write-Host ""
    Write-Host (T 'ChkdskExplanation') -ForegroundColor Gray
    $runChkdsk = Read-Host (T 'ChkdskPrompt' @($SelectedDrive.DriveLetter))
    if ($runChkdsk -match "^[yYeE]") {
        Write-Host (T 'ChkdskRunning') -ForegroundColor Cyan
        try {
            & chkdsk.exe "$($SelectedDrive.DriveLetter)" /f
            Write-Host (T 'ChkdskSuccess') -ForegroundColor Green
        } catch {
            Write-Host (T 'ChkdskError' @($_.Exception.Message)) -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host (T 'Step3Title') -ForegroundColor Yellow
    Write-Host (T 'Step3Running') -ForegroundColor Cyan

    $testFileName = ".psrecover_test_$([System.IO.Path]::GetRandomFileName()).tmp"
    $testFilePath = Join-Path $SelectedDrive.RootPath $testFileName
    $writeSuccess = $false
    $writeError = ""

    try {
        [System.IO.File]::WriteAllText($testFilePath, "PS-Recover Write Verification Test - $(Get-Date)")
        $writeSuccess = $true
        [System.IO.File]::Delete($testFilePath)
    } catch {
        $writeSuccess = $false
        $writeError = $_.Exception.Message
    }

    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    if ($writeSuccess) {
        Write-Host (T 'VerificationSuccess') -ForegroundColor Green
        Write-Host " ===========================================================================" -ForegroundColor Cyan
        Write-Host (T 'VerificationSuccessDesc') -ForegroundColor Green
    } else {
        Write-Host (T 'VerificationHardwareLock') -ForegroundColor Red
        Write-Host " ===========================================================================" -ForegroundColor Cyan
        Write-Host (T 'HardwareLockDesc1') -ForegroundColor Yellow
        Write-Host (T 'HardwareLockDesc2') -ForegroundColor Yellow
        Write-Host (T 'HardwareLockError' @($writeError)) -ForegroundColor Red
        Write-Host ""
        Write-Host (T 'TechnicalDiagnosisHeader') -ForegroundColor Yellow
        Write-Host (T 'HardwareDiagnosis1') -ForegroundColor White
        Write-Host (T 'HardwareDiagnosis2') -ForegroundColor White
        Write-Host (T 'HardwareDiagnosis3') -ForegroundColor White
        Write-Host ""
        Write-Host (T 'HardwareGoodNews') -ForegroundColor Green
        Write-Host (T 'HardwareReplacementAdvice') -ForegroundColor Gray
    }
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function global:Install-PSRecoverProfile {
    Write-Host ""
    Write-Host (T 'InstallStarting') -ForegroundColor Cyan

    $installFolder = Join-Path $HOME ".ps-recover"
    if (-not (Test-Path $installFolder)) {
        New-Item -ItemType Directory -Path $installFolder -Force | Out-Null
    }

    $targetScriptPath = Join-Path $installFolder "recover.ps1"
    
    $alreadyInstalled = $false
    if (Test-Path $targetScriptPath) {
        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            try {
                $curDir = (Resolve-Path $PSScriptRoot).Path
                $tgtDir = (Resolve-Path $installFolder).Path
                if ($curDir -ieq $tgtDir) {
                    $alreadyInstalled = $true
                }
            } catch {}
        }
    }

    if (-not $alreadyInstalled) {
        $copied = $false
        $currentScript = $MyInvocation.MyCommand.Definition
        if ($currentScript -and (Test-Path $currentScript)) {
            try {
                $srcPath = (Resolve-Path $currentScript).Path
                $dstPath = if (Test-Path $targetScriptPath) { (Resolve-Path $targetScriptPath).Path } else { "" }
                if ($srcPath -ine $dstPath) {
                    Copy-Item -Path $currentScript -Destination $targetScriptPath -Force
                    $copied = $true
                }
            } catch {}
        }
        
        if (-not $copied -and (-not [string]::IsNullOrWhiteSpace($PSScriptRoot))) {
            try {
                $thisFile = Join-Path $PSScriptRoot "recover.ps1"
                if (Test-Path $thisFile) {
                    $srcPath = (Resolve-Path $thisFile).Path
                    $dstPath = if (Test-Path $targetScriptPath) { (Resolve-Path $targetScriptPath).Path } else { "" }
                    if ($srcPath -ine $dstPath) {
                        Copy-Item -Path $thisFile -Destination $targetScriptPath -Force
                        $copied = $true
                    }
                }
            } catch {}
        }

        if (-not $copied -and (-not (Test-Path $targetScriptPath))) {
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
                $wc = New-Object System.Net.WebClient
                $wc.Encoding = [System.Text.Encoding]::UTF8
                $rawScript = $wc.DownloadString("https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/recover.ps1")
                [System.IO.File]::WriteAllText($targetScriptPath, $rawScript, [System.Text.Encoding]::UTF8)
                $copied = $true
            } catch {}
        }
    }

    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent) { $profileContent = "" }

    $profileSnippet = @"

# >>> PS-Recover: Windows Disk & Flash Recovery Engine >>>
if (Test-Path "$targetScriptPath") {
    . "$targetScriptPath"
}
# <<< PS-Recover <<<
"@

    if ($profileContent -notmatch "PS-Recover") {
        Add-Content -Path $PROFILE -Value $profileSnippet -Encoding UTF8
        Write-Host (T 'InstallSuccess') -ForegroundColor Green
        Write-Host (T 'InstallProfilePath' @($PROFILE)) -ForegroundColor Gray
        Write-Host (T 'InstallUsageHint') -ForegroundColor Cyan
    } else {
        Write-Host (T 'InstallAlreadyPresent') -ForegroundColor Yellow
    }
}

function global:Uninstall-PSRecoverProfile {
    Write-Host ""
    Write-Host (T 'UninstallStarting') -ForegroundColor Cyan

    if (Test-Path $PROFILE) {
        $lines = Get-Content -Path $PROFILE
        $newLines = @()
        $skip = $false
        foreach ($line in $lines) {
            if ($line -match "# >>> PS-Recover") { $skip = $true; continue }
            if ($line -match "# <<< PS-Recover") { $skip = $false; continue }
            if (-not $skip) { $newLines += $line }
        }
        $newLines | Set-Content -Path $PROFILE -Encoding UTF8
        Write-Host (T 'UninstallSuccessProfile') -ForegroundColor Green
    }

    $installFolder = Join-Path $HOME ".ps-recover"
    if (Test-Path $installFolder) {
        Remove-Item -Path $installFolder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host (T 'UninstallSuccessFolder' @($installFolder)) -ForegroundColor Green
    }
    Write-Host (T 'UninstallComplete') -ForegroundColor Green
}

function global:Show-PSRecoverHelp {
    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host (T 'HelpHeader') -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host (T 'HelpSyntax') -ForegroundColor White
    Write-Host ""
    Write-Host (T 'HelpParamDrive') -ForegroundColor Gray
    Write-Host (T 'HelpParamList') -ForegroundColor Gray
    Write-Host (T 'HelpParamInstall') -ForegroundColor Gray
    Write-Host (T 'HelpParamUninstall') -ForegroundColor Gray
    Write-Host (T 'HelpParamLang') -ForegroundColor Gray
    Write-Host (T 'HelpParamHelp') -ForegroundColor Gray
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function global:Show-PSRecoverLanguageMenu {
    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host (T 'LangMenuTitle') -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host (T 'LangOptionEN') -ForegroundColor White
    Write-Host (T 'LangOptionTR') -ForegroundColor White
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    $choice = Read-Host (T 'LangPrompt')
    $choice = $choice.Trim()

    if ($choice -eq "1" -or $choice -ieq "en") {
        Set-PSRecoverLanguage "en"
        Write-Host (T 'LangSwitchedEN') -ForegroundColor Green
    } elseif ($choice -eq "2" -or $choice -ieq "tr") {
        Set-PSRecoverLanguage "tr"
        Write-Host (T 'LangSwitchedTR') -ForegroundColor Green
    }
    Start-Sleep -Milliseconds 600
}

function global:recover {
    <#
    .SYNOPSIS
        PS-Recover main entry point.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Drive,
        [switch]$List,
        [switch]$Install,
        [switch]$Uninstall,
        [switch]$Help,
        [Alias("Language")]
        [string]$Lang
    )

    if ($Lang) {
        Set-PSRecoverLanguage $Lang
    }

    if ($Help) {
        Show-PSRecoverHelp
        return
    }

    if ($Install) {
        Install-PSRecoverProfile
        return
    }

    if ($Uninstall) {
        Uninstall-PSRecoverProfile
        return
    }

    Show-PSRecoverBanner

    $drives = Get-PSRecoverDriveList

    if ($List) {
        Show-PSRecoverDrivesTable -Drives $drives
        return
    }

    while ($true) {
        $drives = Get-PSRecoverDriveList
        Show-PSRecoverDrivesTable -Drives $drives

        Write-Host (T 'MenuOptionsHeader') -ForegroundColor Yellow
        Write-Host (T 'MenuOptionDriveSelect' @($drives.Count)) -ForegroundColor White
        Write-Host (T 'MenuOptionRescan') -ForegroundColor Cyan
        Write-Host (T 'MenuOptionInstall') -ForegroundColor Magenta
        Write-Host (T 'MenuOptionLanguage') -ForegroundColor Yellow
        Write-Host (T 'MenuOptionQuit') -ForegroundColor Gray
        Write-Host ""

        $selection = Read-Host (T 'PromptMainSelection')
        $selection = $selection.Trim()

        if ($selection -ieq "Q" -or $selection -ieq "Cikis" -or $selection -ieq "Exit") {
            Write-Host (T 'ExitMessage') -ForegroundColor Green
            break
        }

        if ($selection -ieq "R") {
            Write-Host (T 'RescanningDisks') -ForegroundColor Gray
            Start-Sleep -Milliseconds 600
            continue
        }

        if ($selection -ieq "P") {
            Install-PSRecoverProfile
            Write-Host ""
            Read-Host (T 'PressEnterToContinue')
            continue
        }

        if ($selection -ieq "L") {
            Show-PSRecoverLanguageMenu
            continue
        }

        $selectedDrive = $null
        if ($selection -match "^\d+$") {
            $num = [int]$selection
            $selectedDrive = $drives | Where-Object { $_.Index -eq $num } | Select-Object -First 1
        } else {
            $cleanSel = ($selection -replace '[:\\]','').Trim()
            $selectedDrive = $drives | Where-Object { ($_.DriveLetter -replace '[:\\]','').Trim() -ieq $cleanSel } | Select-Object -First 1
        }

        if (-not $selectedDrive) {
            Write-Host (T 'InvalidSelection') -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }

        while ($true) {
            Write-Host ""
            Write-Host " ===========================================================================" -ForegroundColor Cyan
            Write-Host (T 'SelectedDriveHeader' @($selectedDrive.DriveLetter, $selectedDrive.Label, $selectedDrive.DiskModel)) -ForegroundColor Yellow
            Write-Host (T 'DriveDetails' @($selectedDrive.FileSystem, (Format-ByteSize $selectedDrive.TotalBytes), (Format-ByteSize $selectedDrive.FreeBytes))) -ForegroundColor White
            
            if ($selectedDrive.IsReadOnly) {
                Write-Host (T 'WarningReadOnly') -ForegroundColor Red
                Write-Host (T 'WarningReadOnlyAdvice') -ForegroundColor Yellow
            }
            Write-Host " ===========================================================================" -ForegroundColor Cyan
            Write-Host (T 'ActionMenuHeader') -ForegroundColor Yellow
            Write-Host (T 'ActionMenu1') -ForegroundColor White
            Write-Host (T 'ActionMenu2') -ForegroundColor White
            Write-Host (T 'ActionMenu3') -ForegroundColor White
            Write-Host (T 'ActionMenu4') -ForegroundColor White
            Write-Host (T 'ActionMenu5') -ForegroundColor $(if ($selectedDrive.IsReadOnly) { "Red" } else { "Cyan" })
            Write-Host (T 'ActionMenu6') -ForegroundColor White
            Write-Host (T 'ActionMenu0') -ForegroundColor Gray
            Write-Host ""

            $action = Read-Host (T 'PromptActionChoice')
            $action = $action.Trim()

            if ($action -eq "0") {
                break
            }

            switch ($action) {
                "1" {
                    Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "All"
                }
                "2" {
                    Write-Host ""
                    Write-Host (T 'ShortcutScanning') -ForegroundColor Cyan
                    Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "Unhide"
                }
                "3" {
                    Write-Host ""
                    Write-Host (T 'SelectFileTypeHeader') -ForegroundColor Yellow
                    Write-Host (T 'FileTypeDocs') -ForegroundColor White
                    Write-Host (T 'FileTypePhotos') -ForegroundColor White
                    Write-Host (T 'FileTypeVideos') -ForegroundColor White
                    Write-Host (T 'FileTypeAudio') -ForegroundColor White
                    Write-Host (T 'FileTypeArchives') -ForegroundColor White
                    Write-Host (T 'FileTypeCode') -ForegroundColor White
                    Write-Host (T 'FileTypeCustom') -ForegroundColor White
                    Write-Host (T 'FileTypeCancel') -ForegroundColor Gray
                    Write-Host ""
                    $typeChoice = Read-Host (T 'PromptFileType')
                    
                    $extList = @()
                    switch ($typeChoice.Trim()) {
                        "1" { $extList = @(".pdf", ".docx", ".doc", ".xlsx", ".xls", ".pptx", ".ppt", ".txt", ".csv", ".rtf", ".odt") }
                        "2" { $extList = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp", ".raw", ".cr2", ".nef", ".heic", ".psd") }
                        "3" { $extList = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm", ".m4v") }
                        "4" { $extList = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma") }
                        "5" { $extList = @(".zip", ".rar", ".7z", ".tar", ".gz", ".iso") }
                        "6" { $extList = @(".py", ".js", ".ts", ".html", ".css", ".cs", ".cpp", ".c", ".java", ".sql", ".json", ".xml") }
                        "7" {
                            $customExts = Read-Host (T 'PromptCustomExts')
                            $extList = ($customExts -split ',') | ForEach-Object {
                                $clean = $_.Trim().ToLower()
                                if (-not $clean.StartsWith(".")) { $clean = ".$clean" }
                                $clean
                            }
                        }
                    }

                    if ($extList.Count -gt 0) {
                        Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "Preset" -Extensions $extList
                    }
                }
                "4" {
                    Write-Host ""
                    Write-Host (T 'RootFoldersHeader') -ForegroundColor Yellow
                    $dirs = Get-ChildItem -Path $selectedDrive.RootPath -Directory -Force -ErrorAction SilentlyContinue
                    if (-not $dirs -or $dirs.Count -eq 0) {
                        Write-Host (T 'NoDirsFound') -ForegroundColor Yellow
                    } else {
                        $dIndex = 1
                        foreach ($dir in $dirs) {
                            Write-Host ("  [{0}] {1}" -f $dIndex, $dir.Name) -ForegroundColor White
                            $dIndex++
                        }
                        Write-Host ""
                        $dirSel = Read-Host (T 'PromptDirIndex' @($dirs.Count))
                        if ($dirSel -match "^\d+$" -and [int]$dirSel -le $dirs.Count -and [int]$dirSel -ge 1) {
                            $targetDirObj = $dirs[[int]$dirSel - 1]
                            Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "Selective" -CustomSourcePath $targetDirObj.FullName
                        } else {
                            Write-Host (T 'InvalidDirIndex') -ForegroundColor Red
                        }
                    }
                }
                "5" {
                    Repair-ReadOnlyFlashDrive -SelectedDrive $selectedDrive
                }
                "6" {
                    Write-Host ""
                    Write-Host (T 'HardwareDetailsHeader') -ForegroundColor Yellow
                    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
                    Write-Host (T 'DetailDriveLetter' @($selectedDrive.DriveLetter)) -ForegroundColor White
                    Write-Host (T 'DetailDiskModel' @($selectedDrive.DiskModel)) -ForegroundColor White
                    Write-Host (T 'DetailDiskNumber' @($selectedDrive.DiskNumber)) -ForegroundColor White
                    Write-Host (T 'DetailBusType' @($selectedDrive.BusType)) -ForegroundColor White
                    Write-Host (T 'DetailFileSystem' @($selectedDrive.FileSystem)) -ForegroundColor White
                    Write-Host (T 'DetailTotalCap' @((Format-ByteSize $selectedDrive.TotalBytes))) -ForegroundColor White
                    Write-Host (T 'DetailFreeSpace' @((Format-ByteSize $selectedDrive.FreeBytes))) -ForegroundColor White
                    Write-Host (T 'DetailUsedSpace' @((Format-ByteSize $selectedDrive.UsedBytes))) -ForegroundColor White
                    Write-Host (T 'DetailIsReadOnly' @($selectedDrive.IsReadOnly)) -ForegroundColor $(if ($selectedDrive.IsReadOnly) { "Red" } else { "Green" })
                    Write-Host (T 'DetailHealth' @($selectedDrive.HealthStatus)) -ForegroundColor White
                    Write-Host (T 'DetailOperational' @($selectedDrive.OperationalStatus)) -ForegroundColor White
                    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
                    Write-Host ""
                    Read-Host (T 'PressEnterToReturn')
                }
                default {
                    Write-Host (T 'InvalidMenuOption') -ForegroundColor Red
                }
            }
        }
    }
}

Set-Alias -Name "ps-recover" -Value "recover" -Scope Global -ErrorAction SilentlyContinue

if ($MyInvocation.InvocationName -ne '.' -and (-not $env:PS_RECOVER_DONOTRUN)) {
    recover @args
}
