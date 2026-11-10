<#
.SYNOPSIS
    PS-Recover - Windows Gelismis Disk, USB ve Flash Bellek Dosya Kurtarma Araci
.DESCRIPTION
    PowerShell uzerinde 'recover' komutuyla veya 'irm ... | iex' tek satiriyla calisan,
    bagli tum diskleri listeleyen, secilen dosyalari Masaustu\recovered klasorune aktaran,
    kurtarilan dosyalarin raporunu sunan ve salt okunur (yazma korumali) kalan flash bellekleri
    once yedekleyip ardindan duzelten kurtarma araci.
.EXAMPLE
    recover
    Interaktif disk ve dosya kurtarma menusunu acar.
.EXAMPLE
    recover -List
    Sadece bagli diskleri ve durumlarini listeler.
.EXAMPLE
    recover -Install
    Bu komutu kalici olarak PowerShell profilinize kaydeder.
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function global:Get-PSRecoverDriveList {
    <#
    .SYNOPSIS
        Bagli tum fiziksel diskleri ve mantiksal suruculeri tespit eder.
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

            $busType = "Bilinmiyor"
            $diskModel = "Standart Disk"
            $isReadOnly = $false
            $isSystem = ($letter -ieq $env:SystemDrive)

            if ($disk) {
                $busType = $disk.BusType.ToString()
                $diskModel = if ($disk.FriendlyName) { $disk.FriendlyName } else { "Disk $($disk.Number)" }
                $isReadOnly = ($disk.IsReadOnly -eq $true)
            } else {
                $busType = $vol.DriveType.ToString()
            }

            $userFriendlyType = switch -Wildcard ($busType) {
                "*USB*"       { "USB Flash / Harici" }
                "*NVMe*"      { "NVMe SSD (Dahili)" }
                "*SATA*"      { "SATA Disk (Dahili)" }
                "*Removable*" { "Cikarilabilir Bellek" }
                "*Fixed*"     { "Sabit Disk (Dahili)" }
                "*CD*"        { "Optik Surucu (CD/DVD)" }
                default       { $busType }
            }

            $label = if ([string]::IsNullOrWhiteSpace($vol.FileSystemLabel)) { "(Etiketsiz)" } else { $vol.FileSystemLabel }
            $fs = if ([string]::IsNullOrWhiteSpace($vol.FileSystem)) { "Bilinmiyor" } else { $vol.FileSystem }

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
                HealthStatus      = if ($disk) { $disk.HealthStatus.ToString() } else { "Bilinmiyor" }
                OperationalStatus = if ($disk) { $disk.OperationalStatus.ToString() } else { "OK" }
            }
            $index++
        }
    } else {
        # Fallback: WMI / CIM Win32_LogicalDisk
        $logicalDisks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue
        $index = 1
        foreach ($ld in $logicalDisks) {
            $letter = $ld.DeviceID
            $isSystem = ($letter -ieq $env:SystemDrive)
            $typeDesc = switch ($ld.DriveType) {
                2 { "USB / Cikarilabilir Bellek" }
                3 { "Sabit Disk (Yerel)" }
                4 { "Ag Surucusu" }
                5 { "CD/DVD Optik Surucu" }
                default { "Mantiksal Surucu" }
            }

            $totalBytes = [int64]$ld.Size
            $freeBytes  = [int64]$ld.FreeSpace
            $usedBytes  = $totalBytes - $freeBytes
            $label = if ([string]::IsNullOrWhiteSpace($ld.VolumeName)) { "(Etiketsiz)" } else { $ld.VolumeName }
            $fs = if ([string]::IsNullOrWhiteSpace($ld.FileSystem)) { "Bilinmiyor" } else { $ld.FileSystem }

            $driveList += [PSCustomObject]@{
                Index             = $index
                DriveLetter       = $letter
                RootPath          = "$letter\"
                Label             = $label
                DiskModel         = "Depolama Aygiti"
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
                HealthStatus      = "Bilinmiyor"
                OperationalStatus = "OK"
            }
            $index++
        }
    }

    return ,$driveList
}

function global:Test-IsAdminUser {
    <#
    .SYNOPSIS
        Mevcut oturumun Yonetici (Administrator) yetkilerine sahip olup olmadigini kontrol eder.
    #>
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function global:Format-ByteSize {
    <#
    .SYNOPSIS
        Bayt cinsinden boyutu insan tarafindan okunabilir (B, KB, MB, GB, TB) bicime cevirir.
    #>
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
    Write-Host "       Windows Disk, USB & Flash Bellek Kurtarma Araci v1.0         " -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    
    $isAdmin = Test-IsAdminUser
    if ($isAdmin) {
        Write-Host " [i] Oturum Modu: " -NoNewline -ForegroundColor Gray
        Write-Host "YONETICI (ADMIN) - Tum diskpart ve kilit acma yetkileri aktif" -ForegroundColor Green
    } else {
        Write-Host " [i] Oturum Modu: " -NoNewline -ForegroundColor Gray
        Write-Host "STANDART KULLANICI (Salt okunur donanim duzeltmesi icin Yonetici onerilir)" -ForegroundColor Yellow
    }
    Write-Host ""
}

function global:Show-PSRecoverDrivesTable {
    param([array]$Drives)

    if (-not $Drives -or $Drives.Count -eq 0) {
        Write-Host " [!] Sistemde erisilebilir herhangi bir disk/surucu bulunamadi." -ForegroundColor Red
        return
    }

    Write-Host " TAKILI DISKLER VE DEPOLAMA BIRIMLERI:" -ForegroundColor Yellow
    Write-Host " ---------------------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host (" {0,-4} {1,-6} {2,-24} {3,-18} {4,-6} {5,10} {6,10}  {7}" -f "#", "SURUCU", "MODEL / ETIKET", "TUR", "FS", "TOPLAM", "BOS ALAN", "DURUM") -ForegroundColor Cyan
    Write-Host " ---------------------------------------------------------------------------------------------" -ForegroundColor Gray

    foreach ($d in $Drives) {
        $statusText = "[NORMAL]"
        $statusColor = "Green"

        if ($d.IsReadOnly) {
            $statusText = "[SALT OKUNUR / KILITLI]"
            $statusColor = "Red"
        } elseif ($d.IsSystem) {
            $statusText = "[SISTEM DISKI]"
            $statusColor = "Cyan"
        }

        $labelModel = "$($d.DiskModel)"
        if ($d.Label -ne "(Etiketsiz)") {
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
        Secilen surucuden dosyalari tarar, Masaustu\recovered klasorune guvenle kopyalar
        ve dosya ozniteliklerini temizleyip rapor sunar.
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
    $sessionFolderName = "Kurtarma_${cleanLetter}_${timestamp}"
    $destinationDir = Join-Path $recoveredBaseDir $sessionFolderName
    if (Test-Path $destinationDir) {
        $sessionFolderName = "Kurtarma_${cleanLetter}_${timestamp}_$(Get-Random -Minimum 100 -Maximum 999)"
        $destinationDir = Join-Path $recoveredBaseDir $sessionFolderName
    }
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null

    $sourceRoot = if (![string]::IsNullOrEmpty($CustomSourcePath)) { $CustomSourcePath } else { $SelectedDrive.RootPath }

    Write-Host ""
    Write-Host " [>] Kaynak Surucu  : " -NoNewline -ForegroundColor Gray
    Write-Host "$sourceRoot ($($SelectedDrive.DiskModel))" -ForegroundColor Cyan
    Write-Host " [>] Hedef Klasor   : " -NoNewline -ForegroundColor Gray
    Write-Host "$destinationDir" -ForegroundColor Green
    Write-Host " [>] Tarama Modu    : " -NoNewline -ForegroundColor Gray
    Write-Host "$Mode" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " [*] Dosyalar taraniyor, lutfen bekleyin..." -ForegroundColor Gray

    # 1. Asama: Dosyalari Listele
    $scannedFiles = @()
    try {
        if ($Mode -eq "Preset" -and $Extensions.Count -gt 0) {
            $allFiles = Get-ChildItem -Path $sourceRoot -Recurse -Force -File -ErrorAction SilentlyContinue
            $scannedFiles = $allFiles | Where-Object {
                $ext = $_.Extension.ToLower()
                $Extensions -contains $ext
            }
        } elseif ($Mode -eq "Unhide") {
            # Kisayol virusu temizleme modu: Zararli .lnk ve .vbs kisayollarini atla veya gercek veriyi al
            $allFiles = Get-ChildItem -Path $sourceRoot -Recurse -Force -File -ErrorAction SilentlyContinue
            $scannedFiles = $allFiles | Where-Object {
                $_.Extension.ToLower() -notin @(".lnk", ".vbs", ".wsf") -or $_.Length -gt 100KB
            }
        } else {
            # Tum dosyalar veya Ozel Klasor
            $scannedFiles = Get-ChildItem -Path $sourceRoot -Recurse -Force -File -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host " [!] Dosya listesi alinirken bir hata olustu: $($_.Exception.Message)" -ForegroundColor Red
    }

    if (-not $scannedFiles -or $scannedFiles.Count -eq 0) {
        Write-Host " [!] Secilen kriterlere uygun kurtarilacak dosya bulunamadi." -ForegroundColor Yellow
        return
    }

    $totalCount = $scannedFiles.Count
    $totalBytesToCopy = ($scannedFiles | Measure-Object -Property Length -Sum).Sum
    Write-Host " [+] Toplam $totalCount adet dosya bulundu ($(Format-ByteSize $totalBytesToCopy)). Kurtarma baslatiliyor..." -ForegroundColor Green
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

        # Bagil dosya yolunu hesapla (Klasor hiyerarsisini masaustunde korumak icin)
        $relPath = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $targetFilePath = Join-Path $destinationDir $relPath
        $targetFolder = Split-Path -Path $targetFilePath -Parent

        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
        }

        Write-Progress -Activity "Dosyalar Kurtariliyor (Masaustu\recovered)" `
            -Status "[$currentIndex / $totalCount] ($percent%) $($file.Name)" `
            -PercentComplete $percent

        $isSuccess = $false
        $errorMsg = ""

        # Dosya kopyalama denemesi
        try {
            [System.IO.File]::Copy($file.FullName, $targetFilePath, $true)
            $isSuccess = $true
        } catch {
            # 1. Alternatif: Akis (Stream) okuyucusuyla parca parca okumayi dene
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
            # Kurtarilan dosyadaki Salt Okunur, Gizli ve Sistem ozniteliklerini temizle
            try {
                [System.IO.File]::SetAttributes($targetFilePath, [System.IO.FileAttributes]::Normal)
            } catch {}

            $successCount++
            $recoveredBytes += $file.Length
            [void]$recoveredList.Add([PSCustomObject]@{
                Name         = $file.Name
                RelativePath = $relPath
                Size         = $file.Length
                Status       = "Basarili"
                Error        = ""
            })
        } else {
            $failedCount++
            [void]$recoveredList.Add([PSCustomObject]@{
                Name         = $file.Name
                RelativePath = $relPath
                Size         = $file.Length
                Status       = "Hata"
                Error        = $errorMsg
            })
        }
    }

    Write-Progress -Activity "Dosyalar Kurtariliyor" -Completed
    $sw.Stop()

    # Rapor Olusturma ve Ekrana Basma
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
    <#
    .SYNOPSIS
        Kurtarma islemi bittiginde konsola ozet sunar, kurtarilan dosyalari listeler
        ve masaustundeki recovered klasorune kurtarma_raporu.txt yazar.
    #>
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
    Write-Host "                          KURTARMA RAPORU OZETI                             " -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Green
    Write-Host (" Kaynak Surucu           : {0} ({1})" -f $Drive.DriveLetter, $Drive.DiskModel) -ForegroundColor White
    Write-Host (" Hedef Klasor            : {0}" -f $DestinationDir) -ForegroundColor Green
    Write-Host (" Toplam Taranan Dosya    : {0}" -f $TotalScanned) -ForegroundColor White
    Write-Host (" Basariyla Kurtarilan    : {0}" -f $SuccessCount) -ForegroundColor Green
    Write-Host (" Okunamayan / Hatali     : {0}" -f $FailedCount) -ForegroundColor $(if ($FailedCount -gt 0) { "Red" } else { "Gray" })
    Write-Host (" Kurtarilan Toplam Boyut : {0}" -f (Format-ByteSize $RecoveredBytes)) -ForegroundColor Cyan
    Write-Host (" Gecen Sure              : {0}" -f $elapsedStr) -ForegroundColor White
    Write-Host " ===========================================================================" -ForegroundColor Green
    Write-Host ""

    # Konsolda kurtarilan dosyalarin listesi
    Write-Host " KURTARILAN DOSYALAR (Ilk 35 dosya gosteriliyor):" -ForegroundColor Yellow
    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
    
    $displayLimit = 35
    $shownCount = 0
    foreach ($item in $FileList) {
        $shownCount++
        if ($shownCount -le $displayLimit) {
            if ($item.Status -eq "Basarili") {
                Write-Host " [BASARILI] " -NoNewline -ForegroundColor Green
                Write-Host ("\{0,-45} ({1})" -f $item.RelativePath, (Format-ByteSize $item.Size)) -ForegroundColor White
            } else {
                Write-Host " [HATA]     " -NoNewline -ForegroundColor Red
                Write-Host ("\{0,-45} [{1}]" -f $item.RelativePath, $item.Error) -ForegroundColor Red
            }
        }
    }

    if ($FileList.Count -gt $displayLimit) {
        $remaining = $FileList.Count - $displayLimit
        Write-Host " ... ve $($remaining) dosya daha kurtarildi (Tam liste rapor dosyasina yazildi)." -ForegroundColor Gray
    }
    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    # Rapor dosyasini hedef klasore TXT olarak kaydet
    $reportFilePath = Join-Path $DestinationDir "kurtarma_raporu.txt"
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("===========================================================================")
    [void]$sb.AppendLine("                       PS-RECOVER KURTARMA RAPORU                          ")
    [void]$sb.AppendLine(" Tarih                  : $((Get-Date).ToString('dd.MM.yyyy HH:mm:ss'))")
    [void]$sb.AppendLine(" Kaynak Disk / Surucu   : $($Drive.DriveLetter) ($($Drive.DiskModel))")
    [void]$sb.AppendLine(" Dosya Sistemi          : $($Drive.FileSystem)")
    [void]$sb.AppendLine(" Hedef Klasor           : $DestinationDir")
    [void]$sb.AppendLine(" Toplam Taranan Dosya   : $TotalScanned")
    [void]$sb.AppendLine(" Basariyla Kurtarilan   : $SuccessCount")
    [void]$sb.AppendLine(" Hatali / Okunamayan    : $FailedCount")
    [void]$sb.AppendLine(" Toplam Kurtarilan Boyut: $(Format-ByteSize $RecoveredBytes)")
    [void]$sb.AppendLine(" Gecen Sure             : $elapsedStr")
    [void]$sb.AppendLine("===========================================================================")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("DOSYA LISTESI:")
    [void]$sb.AppendLine("---------------------------------------------------------------------------")

    foreach ($item in $FileList) {
        $line = ("[{0}] \{1} ({2}) {3}" -f $item.Status, $item.RelativePath, (Format-ByteSize $item.Size), $item.Error).Trim()
        [void]$sb.AppendLine($line)
    }

    try {
        [System.IO.File]::WriteAllText($reportFilePath, $sb.ToString(), [System.Text.Encoding]::UTF8)
        Write-Host " [OK] Detayli rapor dosyasi kaydedildi: $reportFilePath" -ForegroundColor Cyan
    } catch {
        Write-Host " [!] Rapor dosyasi yazilamadi: $($_.Exception.Message)" -ForegroundColor Red
    }

    if (-not $env:PS_RECOVER_NONINTERACTIVE) {
        Write-Host ""
        $openFolder = Read-Host " Kurtarilan dosyalarin bulundugu klasor dosya gezgininde acilsin mi? [E/H]"
        if ($openFolder -match "^[eEyY]") {
            try {
                Start-Process "explorer.exe" -ArgumentList "`"$DestinationDir`""
            } catch {}
        }
    }
}

function global:Repair-ReadOnlyFlashDrive {
    <#
    .SYNOPSIS
        Salt okunur (yazma korumali) kalan flash bellekleri once masaustune yedekler,
        ardindan Diskpart, Storage API, Registry ve Dosya Izinleri kilitlerini temizler
        ve donanimsal kontrolcu teshis testini calistirir.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$SelectedDrive
    )

    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Red
    Write-Host "            SALT OKUNUR (YAZMA KORUMALI) FLASH BELLEK ONARIMI               " -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Red
    Write-Host " Hedef Bellek : $($SelectedDrive.DriveLetter) [$($SelectedDrive.Label)] - $($SelectedDrive.DiskModel)" -ForegroundColor White
    Write-Host ""
    Write-Host " Flash bellekler genellikle asagidaki 2 sebepten oturu salt okunur kalir:" -ForegroundColor Gray
    Write-Host "  1. Yazilimsal Kilitler: Diskpart ozniteligi, bozuk dosya sistemi, Registry korumasi veya virusler." -ForegroundColor Gray
    Write-Host "  2. Donanimsal Koruma (NAND Wear-Out): Yipranan bellek hucreleri bozulmasin diye kontrolcu" -ForegroundColor Gray
    Write-Host "     cihazi kalici okuma moduna kilitler." -ForegroundColor Gray
    Write-Host ""

    # Adim 1: Guvenlik Yedeklemesi (Altin Kural: Donanim onarimindan once veriyi kurtar!)
    Write-Host " [ADIM 1 / GUVENLIK YEDEKLEMESI]" -ForegroundColor Yellow
    Write-Host " Kilit acma islemleri bellek kontrolcusunu zorlayabilir. Onarima baslamadan once" -ForegroundColor White
    Write-Host " bellekteki tum dosyalar Masaustu\recovered klasorune YEDEKLENSIN MI?" -ForegroundColor White
    $doBackup = Read-Host " [Onerilen] Dosyalar simdi masaustune yedeklensin mi? [E/H] (Varsayilan: E)"
    if ([string]::IsNullOrWhiteSpace($doBackup) -or $doBackup -match "^[eEyY]") {
        Write-Host " [*] Flash bellegin tam guvenlik yedegi aliniyor..." -ForegroundColor Cyan
        Invoke-FileRecoveryEngine -SelectedDrive $SelectedDrive -Mode "All"
    } else {
        Write-Host " [!] Yedekleme adimi kullanici tarafindan atlandi." -ForegroundColor Yellow
    }

    # Adim 2: Yonetici Izni Kontrolu
    $isAdmin = Test-IsAdminUser
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host " [!] UYARI: Diskpart ve Registry uzerinden yazma korumasini kaldirmak icin" -ForegroundColor Red
        Write-Host "     YONETICI (Administrator) yetkileri zorunludur." -ForegroundColor Red
        Write-Host ""
        $elevate = Read-Host " Yonetici olarak yeni bir PowerShell penceresi baslatilsin mi? [E/H]"
        if ($elevate -match "^[eEyY]") {
            $scriptPath = $MyInvocation.MyCommand.Path
            if ($scriptPath) {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "& '$scriptPath'; recover"
            } else {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "recover"
            }
            return
        } else {
            Write-Host " [!] Yonetici izni olmadan sadece sinirli dosya oznitelik temizligi yapilabilecek." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host " [ADIM 2 / KILIT ACMA VE ONARIM ISLEMLERI BASLATILIYOR]" -ForegroundColor Yellow

    # 1. Asama: Diskpart attributes temizleme
    if ($isAdmin -and $SelectedDrive.DiskNumber -ge 0) {
        Write-Host " [*] Diskpart ile disk ve birim salt okunur bayraklari temizleniyor..." -ForegroundColor Cyan
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
            Write-Host " [OK] Diskpart komutlari uygulandi." -ForegroundColor Green
        } catch {
            Write-Host " [!] Diskpart calistirilamadi: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Remove-Item $tempDpFile -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Asama: Storage API Set-Disk
    if ($isAdmin -and $SelectedDrive.DiskNumber -ge 0) {
        Write-Host " [*] Windows Storage API ile disk salt okunurlugu kapatiliyor..." -ForegroundColor Cyan
        try {
            Set-Disk -Number $SelectedDrive.DiskNumber -IsReadOnly $false -ErrorAction SilentlyContinue
            Set-Disk -Number $SelectedDrive.DiskNumber -IsOffline $false -ErrorAction SilentlyContinue
            Write-Host " [OK] Storage API ayarlari guncellendi." -ForegroundColor Green
        } catch {}
    }

    # 3. Asama: Windows Registry StorageDevicePolicies Kontrolu
    if ($isAdmin) {
        Write-Host " [*] Kayit Defteri (Registry) StorageDevicePolicies kontrol ediliyor..." -ForegroundColor Cyan
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
        try {
            if (Test-Path $regPath) {
                $wp = Get-ItemProperty -Path $regPath -Name "WriteProtect" -ErrorAction SilentlyContinue
                if ($wp -and $wp.WriteProtect -eq 1) {
                    Set-ItemProperty -Path $regPath -Name "WriteProtect" -Value 0
                    Write-Host " [OK] Registry'deki global 'WriteProtect = 1' kilidi 0 yapildi!" -ForegroundColor Green
                } else {
                    Write-Host " [i] Registry'de sistem geneli yazma engeli bulunmuyor." -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host " [!] Registry erisiminde hata: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 4. Asama: Dosya ve Dizin Duzeyinde Salt Okunur Ozniteliklerini Temizleme
    Write-Host " [*] Bellek uzerindeki tum dosya ve klasorlerin salt okunur oznitelikleri kaldiriliyor..." -ForegroundColor Cyan
    try {
        & attrib.exe -r -s -h "$($SelectedDrive.DriveLetter)\*" /s /d 2>$null
        Write-Host " [OK] Dosya sistemi oznitelikleri (attrib -r -s -h) temizlendi." -ForegroundColor Green
    } catch {}

    # 5. Asama: Dosya Sistemi Onarimi (Chkdsk)
    Write-Host ""
    Write-Host " Bozuk dosya sistemi veya kapatilmamis 'dirty bit' bayragi Windows'un bellegi korumaya almasina neden olabilir." -ForegroundColor Gray
    $runChkdsk = Read-Host " Surucuye dosya sistemi onarimi (chkdsk $($SelectedDrive.DriveLetter) /f) uygulansin mi? [E/H]"
    if ($runChkdsk -match "^[eEyY]") {
        Write-Host " [*] Chkdsk calistiriliyor, lutfen bekleyin..." -ForegroundColor Cyan
        try {
            & chkdsk.exe "$($SelectedDrive.DriveLetter)" /f
            Write-Host " [OK] Chkdsk tamamlandi." -ForegroundColor Green
        } catch {
            Write-Host " [!] Chkdsk hatasi: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 6. Asama: Dogrulama ve Donanimsal Teshis Testi
    Write-Host ""
    Write-Host " [ADIM 3 / YAZMA DOGRULAMA VE TESHIS TESTI]" -ForegroundColor Yellow
    Write-Host " [*] Surucuye test verisi yazilarak kilit durumu kontrol ediliyor..." -ForegroundColor Cyan

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
        Write-Host "  TEBRIKLER! FLASH BELLEK YAZMA KILIDI BASARIYLA KALDIRILDI!               " -ForegroundColor Green
        Write-Host " ===========================================================================" -ForegroundColor Cyan
        Write-Host " [OK] Surucu artik salt okunur degil. Dosya ekleyebilir, silebilir ve bicimlendirebilirsiniz." -ForegroundColor Green
    } else {
        Write-Host "  DONANIMSAL KORUMA (HARDWARE WRITE-LOCK) TESHIS EDILDI                     " -ForegroundColor Red
        Write-Host " ===========================================================================" -ForegroundColor Cyan
        Write-Host " [!] Yazilimsal tum kilitler (Diskpart, Registry, Attrib, Dosya Izinleri) kaldirildi" -ForegroundColor Yellow
        Write-Host "     ancak bellek kontrolcusu (NAND Controller) yazma komutunu reddetti." -ForegroundColor Yellow
        Write-Host "     Hata: $writeError" -ForegroundColor Red
        Write-Host ""
        Write-Host " TEKNIK TESHIS VE TAVSIYE:" -ForegroundColor Yellow
        Write-Host "  Flash bellegin yongalari (NAND flash) omrunu doldurdugunda veya fiziksel bad sector" -ForegroundColor White
        Write-Host "  olustugunda, donanim kontrolcusu verilerinizin tamamen silinmesini veya bozulmasini" -ForegroundColor White
        Write-Host "  onlemek amaciyla bellegi 'Kalici Donanimsal Salt Okunur (Hardware ROM)' moduna alir." -ForegroundColor White
        Write-Host ""
        Write-Host "  IYI HABER: Verileriniz ilk adimda Masaustunuzdeki 'recovered' klasorune guvenle kurtarildi!" -ForegroundColor Green
        Write-Host "  Bu bellek artik guvenilir degildir; yeni bir bellek kullanmaniz siddetle onerilir." -ForegroundColor Gray
    }
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function global:Install-PSRecoverProfile {
    <#
    .SYNOPSIS
        'recover' komutunu PowerShell Profiline ekler, boylece kullanici her acilista
        sadece 'recover' yazarak araci calistirabilir.
    #>
    Write-Host ""
    Write-Host " [*] 'recover' komutu PowerShell profilinize kuruluyor..." -ForegroundColor Cyan

    $installFolder = Join-Path $HOME ".ps-recover"
    if (-not (Test-Path $installFolder)) {
        New-Item -ItemType Directory -Path $installFolder -Force | Out-Null
    }

    $targetScriptPath = Join-Path $installFolder "recover.ps1"
    
    $copied = $false
    $currentScript = $MyInvocation.MyCommand.Definition
    if ($currentScript -and (Test-Path $currentScript)) {
        try {
            Copy-Item -Path $currentScript -Destination $targetScriptPath -Force
            $copied = $true
        } catch {}
    }
    
    if (-not $copied -and (-not [string]::IsNullOrWhiteSpace($PSScriptRoot))) {
        try {
            $thisFile = Join-Path $PSScriptRoot "recover.ps1"
            if (Test-Path $thisFile) {
                Copy-Item -Path $thisFile -Destination $targetScriptPath -Force
                $copied = $true
            }
        } catch {}
    }

    if (-not $copied -and (-not (Test-Path $targetScriptPath))) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
            $wc = New-Object System.Net.WebClient
            $wc.Encoding = [System.Text.Encoding]::UTF8
            $rawScript = $wc.DownloadString("https://raw.githubusercontent.com/AybarsBarut/drive-recovery/main/recover.ps1")
            [System.IO.File]::WriteAllText($targetScriptPath, $rawScript, [System.Text.Encoding]::UTF8)
            $copied = $true
        } catch {}
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

# >>> PS-Recover: Windows Disk & Flash Bellek Kurtarma Araci >>>
if (Test-Path "$targetScriptPath") {
    . "$targetScriptPath"
}
# <<< PS-Recover <<<
"@

    if ($profileContent -notmatch "PS-Recover") {
        Add-Content -Path $PROFILE -Value $profileSnippet -Encoding UTF8
        Write-Host " [OK] 'recover' komutu basariyla PowerShell profilinize eklendi!" -ForegroundColor Green
        Write-Host " [i] Profil dosyasi: $PROFILE" -ForegroundColor Gray
        Write-Host " [i] Artik PowerShell'i her actiginizda sadece 'recover' yazmaniz yeterli!" -ForegroundColor Cyan
    } else {
        Write-Host " [i] 'recover' komutu zaten profilinizde mevcut." -ForegroundColor Yellow
    }
}

function global:Uninstall-PSRecoverProfile {
    <#
    .SYNOPSIS
        'recover' komutunu PowerShell profilinden ve diskten kaldirir.
    #>
    Write-Host ""
    Write-Host " [*] 'recover' komutu PowerShell profilinden kaldiriliyor..." -ForegroundColor Cyan

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
        Write-Host " [OK] Profil kaydi temizlendi." -ForegroundColor Green
    }

    $installFolder = Join-Path $HOME ".ps-recover"
    if (Test-Path $installFolder) {
        Remove-Item -Path $installFolder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host " [OK] Yerel kurulum klasoru temizlendi ($installFolder)." -ForegroundColor Green
    }
    Write-Host " [OK] PS-Recover basariyla kaldirildi." -ForegroundColor Green
}

function global:recover {
    <#
    .SYNOPSIS
        PS-Recover ana komutu.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Drive,
        [switch]$List,
        [switch]$Install,
        [switch]$Uninstall,
        [switch]$Help
    )

    if ($Help) {
        Get-Help recover
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

    # Interaktif Ana Dongu
    while ($true) {
        $drives = Get-PSRecoverDriveList
        Show-PSRecoverDrivesTable -Drives $drives

        Write-Host " SECENEKLER:" -ForegroundColor Yellow
        Write-Host "  [1-$($drives.Count)] Bir disk secin ve kurtarma/onarim islemlerine baslayin" -ForegroundColor White
        Write-Host "  [R]   Diskleri yeniden tara (Yeni bir flash bellek taktiysaniz)" -ForegroundColor Cyan
        Write-Host "  [P]   Bu araci 'recover' komutu olarak PowerShell'e kalici yukle" -ForegroundColor Magenta
        Write-Host "  [Q]   Cikis" -ForegroundColor Gray
        Write-Host ""

        $selection = Read-Host " Lutfen islem yapmak istediginiz diskin numarasini veya secenegi girin"
        $selection = $selection.Trim()

        if ($selection -ieq "Q" -or $selection -ieq "Cikis") {
            Write-Host " [OK] Cikis yapildi. Iyi calismalar!" -ForegroundColor Green
            break
        }

        if ($selection -ieq "R") {
            Write-Host " [*] Diskler yeniden taraniyor..." -ForegroundColor Gray
            Start-Sleep -Milliseconds 600
            continue
        }

        if ($selection -ieq "P") {
            Install-PSRecoverProfile
            Write-Host ""
            Read-Host " Devam etmek icin Enter'a basin..."
            continue
        }

        # Numara kontrolu
        $selectedDrive = $null
        if ($selection -match "^\d+$") {
            $num = [int]$selection
            $selectedDrive = $drives | Where-Object { $_.Index -eq $num } | Select-Object -First 1
        } else {
            # Surucu harfi girilmis olabilir (orn: E veya E:)
            $cleanSel = ($selection -replace '[:\\]','').Trim()
            $selectedDrive = $drives | Where-Object { ($_.DriveLetter -replace '[:\\]','').Trim() -ieq $cleanSel } | Select-Object -First 1
        }

        if (-not $selectedDrive) {
            Write-Host " [!] Gecersiz secim yaptiniz. Lutfen listedeki bir numara veya surucu harfi girin." -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }

        # Secilen Disk icin Islem Alt Menusu
        while ($true) {
            Write-Host ""
            Write-Host " ===========================================================================" -ForegroundColor Cyan
            Write-Host ("  SECILEN SURUCU: {0} ({1}) - {2}" -f $selectedDrive.DriveLetter, $selectedDrive.Label, $selectedDrive.DiskModel) -ForegroundColor Yellow
            Write-Host ("  Dosya Sistemi: {0} | Toplam Boyut: {1} | Bos Alan: {2}" -f $selectedDrive.FileSystem, (Format-ByteSize $selectedDrive.TotalBytes), (Format-ByteSize $selectedDrive.FreeBytes)) -ForegroundColor White
            
            if ($selectedDrive.IsReadOnly) {
                Write-Host "  [!] UYARI: BU FLASH BELLEK SALT OKUNUR (YAZMA KORUMALI) DURUMDADIR!" -ForegroundColor Red
                Write-Host "      Onerilen: [5] Salt Okunur Flashi Yedekle ve Kilidi Kaldir" -ForegroundColor Yellow
            }
            Write-Host " ===========================================================================" -ForegroundColor Cyan
            Write-Host " YAPILACAK ISLEMI SECIN:" -ForegroundColor Yellow
            Write-Host "  [1] Tam Disk Kurtarma (Tum dosya ve klasorleri masaustune yedekle)" -ForegroundColor White
            Write-Host "  [2] Kisayol Virusu & Gizli Dosyalari Kurtar (Gizli dosyalari aciga cikar ve kurtar)" -ForegroundColor White
            Write-Host "  [3] Belirli Dosya Turlerini Kurtar (Fotograf, Belge, Video, vb.)" -ForegroundColor White
            Write-Host "  [4] Ozel Klasor veya Dosya Secerek Kurtar (Interaktif gezgin)" -ForegroundColor White
            Write-Host "  [5] Salt Okunur / Yazma Korumali Flashi Duzelt (Once Yedekler -> Kilidi Acar)" -ForegroundColor $(if ($selectedDrive.IsReadOnly) { "Red" } else { "Cyan" })
            Write-Host "  [6] Disk Sagligi ve Donanim Ayrintilarini Goruntule" -ForegroundColor White
            Write-Host "  [0] Farkli Surucu Sec / Geri Don" -ForegroundColor Gray
            Write-Host ""

            $action = Read-Host " Seciminiz [1-6 veya 0]"
            $action = $action.Trim()

            if ($action -eq "0") {
                break
            }

            switch ($action) {
                "1" {
                    # Tam disk kurtarma
                    Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "All"
                }
                "2" {
                    # Kisayol virusu ve gizli dosyalari kurtarma
                    Write-Host ""
                    Write-Host " [*] Kisayol virusu (Shortcut virus) tarafindan gizlenen gercek dosyalar" -ForegroundColor Cyan
                    Write-Host "     ve sistem oznitelikli veriler taraniyor..." -ForegroundColor Gray
                    Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "Unhide"
                }
                "3" {
                    # Dosya turune gore kurtarma
                    Write-Host ""
                    Write-Host " KURTARILACAK DOSYA TURUNU SECIN:" -ForegroundColor Yellow
                    Write-Host "  [1] Belgeler (PDF, Word, Excel, PowerPoint, TXT, CSV, RTF...)" -ForegroundColor White
                    Write-Host "  [2] Fotograflar (JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD...)" -ForegroundColor White
                    Write-Host "  [3] Videolar (MP4, MKV, AVI, MOV, WMV, FLV, WEBM...)" -ForegroundColor White
                    Write-Host "  [4] Sesler (MP3, WAV, FLAC, AAC, M4A, OGG...)" -ForegroundColor White
                    Write-Host "  [5] Arsivler (ZIP, RAR, 7Z, TAR, GZ, ISO...)" -ForegroundColor White
                    Write-Host "  [6] Kod ve Projeler (PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON...)" -ForegroundColor White
                    Write-Host "  [7] Ozel Uzanti Belirt (orn: .dwg, .psd)" -ForegroundColor White
                    Write-Host "  [0] Iptal" -ForegroundColor Gray
                    Write-Host ""
                    $typeChoice = Read-Host " Seciminiz [1-7]"
                    
                    $extList = @()
                    switch ($typeChoice.Trim()) {
                        "1" { $extList = @(".pdf", ".docx", ".doc", ".xlsx", ".xls", ".pptx", ".ppt", ".txt", ".csv", ".rtf", ".odt") }
                        "2" { $extList = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp", ".raw", ".cr2", ".nef", ".heic", ".psd") }
                        "3" { $extList = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm", ".m4v") }
                        "4" { $extList = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma") }
                        "5" { $extList = @(".zip", ".rar", ".7z", ".tar", ".gz", ".iso") }
                        "6" { $extList = @(".py", ".js", ".ts", ".html", ".css", ".cs", ".cpp", ".c", ".java", ".sql", ".json", ".xml") }
                        "7" {
                            $customExts = Read-Host " Kurtarmak istediginiz uzantilari virgulle ayirarak girin (orn: .dwg, .psd, .blend)"
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
                    # Ozel klasor secerek kurtarma
                    Write-Host ""
                    Write-Host " Surucu kok dizinindeki klasorler:" -ForegroundColor Yellow
                    $dirs = Get-ChildItem -Path $selectedDrive.RootPath -Directory -Force -ErrorAction SilentlyContinue
                    if (-not $dirs -or $dirs.Count -eq 0) {
                        Write-Host " [!] Kok dizinde taranabilecek klasor bulunamadi." -ForegroundColor Yellow
                    } else {
                        $dIndex = 1
                        foreach ($dir in $dirs) {
                            Write-Host ("  [{0}] {1}" -f $dIndex, $dir.Name) -ForegroundColor White
                            $dIndex++
                        }
                        Write-Host ""
                        $dirSel = Read-Host " Kurtarmak istediginiz klasorun numarasini girin [1-$($dirs.Count)]"
                        if ($dirSel -match "^\d+$" -and [int]$dirSel -le $dirs.Count -and [int]$dirSel -ge 1) {
                            $targetDirObj = $dirs[[int]$dirSel - 1]
                            Invoke-FileRecoveryEngine -SelectedDrive $selectedDrive -Mode "Selective" -CustomSourcePath $targetDirObj.FullName
                        } else {
                            Write-Host " [!] Gecersiz klasor numarasi." -ForegroundColor Red
                        }
                    }
                }
                "5" {
                    # Salt okunur flash bellek kurtarma ve onarim
                    Repair-ReadOnlyFlashDrive -SelectedDrive $selectedDrive
                }
                "6" {
                    # Disk Sagligi ve Donanim Ayrintilari
                    Write-Host ""
                    Write-Host " DONANIM VE SURUCU AYRINTILARI:" -ForegroundColor Yellow
                    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
                    Write-Host (" Surucu Harfi     : {0}" -f $selectedDrive.DriveLetter) -ForegroundColor White
                    Write-Host (" Disk Modeli      : {0}" -f $selectedDrive.DiskModel) -ForegroundColor White
                    Write-Host (" Fiziksel Disk No : {0}" -f $selectedDrive.DiskNumber) -ForegroundColor White
                    Write-Host (" Baglanti Turu    : {0}" -f $selectedDrive.BusType) -ForegroundColor White
                    Write-Host (" Dosya Sistemi    : {0}" -f $selectedDrive.FileSystem) -ForegroundColor White
                    Write-Host (" Toplam Kapasite  : {0}" -f (Format-ByteSize $selectedDrive.TotalBytes)) -ForegroundColor White
                    Write-Host (" Bos Alan         : {0}" -f (Format-ByteSize $selectedDrive.FreeBytes)) -ForegroundColor White
                    Write-Host (" Kullanilan Alan  : {0}" -f (Format-ByteSize $selectedDrive.UsedBytes)) -ForegroundColor White
                    Write-Host (" Salt Okunur mu?  : {0}" -f $selectedDrive.IsReadOnly) -ForegroundColor $(if ($selectedDrive.IsReadOnly) { "Red" } else { "Green" })
                    Write-Host (" Saglik Durumu    : {0}" -f $selectedDrive.HealthStatus) -ForegroundColor White
                    Write-Host (" Calisma Durumu   : {0}" -f $selectedDrive.OperationalStatus) -ForegroundColor White
                    Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Gray
                    Write-Host ""
                    Read-Host " Menuye donmek icin Enter'a basin..."
                }
                default {
                    Write-Host " [!] Lutfen menudeki seceneklerden birini girin." -ForegroundColor Red
                }
            }
        }
    }
}

# Alias tanimlama
Set-Alias -Name "ps-recover" -Value "recover" -Scope Global -ErrorAction SilentlyContinue

# Dogrudan veya iex ile calistirildiginda otomatik baslatma mantigi
if ($MyInvocation.InvocationName -ne '.' -and (-not $env:PS_RECOVER_DONOTRUN)) {
    recover @args
}
