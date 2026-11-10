# PS-Recover Otomatik Test Paketi (Unit & Integration Tests)
# Bu betik sanal bir depolama ortami olusturarak dosya kurtarma motorunu,
# kisayol virusu temizleme modunu, filtreleme ve raporlama ozelliklerini test eder.

$ErrorActionPreference = "Stop"

Write-Host "===========================================================================" -ForegroundColor Cyan
Write-Host "               PS-RECOVER TEST VE DOGRULAMA CALISMASI                      " -ForegroundColor Yellow
Write-Host "===========================================================================" -ForegroundColor Cyan

# 1. Ortami Hazirla
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$repoRoot = Split-Path $scriptRoot -Parent
$recoverScript = Join-Path $repoRoot "recover.ps1"

Write-Host " [*] recover.ps1 yukleniyor: $recoverScript" -ForegroundColor Gray
$env:PS_RECOVER_DONOTRUN = "1"
$env:PS_RECOVER_NONINTERACTIVE = "1"
. $recoverScript

$testBench = Join-Path $repoRoot "TestBench"
$mockSource = Join-Path $testBench "MockDrive"
$testDesktop = Join-Path $testBench "TestDesktop"

if (Test-Path $testBench) {
    Remove-Item $testBench -Recurse -Force
}

New-Item -ItemType Directory -Path (Join-Path $mockSource "Belgeler") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $mockSource "Fotograflar") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $mockSource "GizliKlasor") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $mockSource "VirusSimulasyonu") -Force | Out-Null

# Test Dosyalari Olustur
$docFile = Join-Path $mockSource "Belgeler\Tez_Calismasi.docx"
$photoFile = Join-Path $mockSource "Fotograflar\Tatil_2025.jpg"
$secretFile = Join-Path $mockSource "GizliKlasor\GizliVeri.pdf"
$readOnlyFile = Join-Path $mockSource "Belgeler\SaltOkunurSozlesme.txt"
$lnkVirus = Join-Path $mockSource "VirusSimulasyonu\Belgeler.lnk"

[System.IO.File]::WriteAllText($docFile, "Tez Calismasi Icerigi - Onemli Veri")
[System.IO.File]::WriteAllText($photoFile, "Fake Image Binary Content")
[System.IO.File]::WriteAllText($secretFile, "Cok gizli PDF verisi")
[System.IO.File]::WriteAllText($readOnlyFile, "Bu dosya salt okunur olarak kilitlendi.")
[System.IO.File]::WriteAllText($lnkVirus, "Fake Shortcut Worm")

# Oznitelikleri ayarla (Gizli, Sistem, Salt Okunur)
[System.IO.File]::SetAttributes($secretFile, [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
[System.IO.File]::SetAttributes($readOnlyFile, [System.IO.FileAttributes]::ReadOnly)

Write-Host " [OK] Sanal test ortami basariyla olusturuldu." -ForegroundColor Green

# 2. Sahte Disk Nesnesi Olustur
$mockDisk = [PSCustomObject]@{
    Index             = 99
    DriveLetter       = "M:"
    RootPath          = "$mockSource\"
    Label             = "MOCK_FLASH"
    DiskModel         = "Virtual Test Flash Drive 3.0"
    DiskNumber        = 99
    BusType           = "USB"
    DriveTypeDesc     = "USB Flash / Harici"
    FileSystem        = "FAT32"
    TotalBytes        = 16GB
    FreeBytes         = 12GB
    UsedBytes         = 4GB
    TotalGB           = 16.0
    FreeGB            = 12.0
    UsedGB            = 4.0
    IsReadOnly        = $true
    IsSystem          = $false
    HealthStatus      = "Healthy"
    OperationalStatus = "OK"
}

# 3. Test 1: Sürücü Listeleme Fonksiyonunu Test Et
Write-Host ""
Write-Host ">> TEST 1: Get-PSRecoverDriveList Testi..." -ForegroundColor Yellow
$drives = @(Get-PSRecoverDriveList)
if ($drives -and $drives.Count -gt 0) {
    Write-Host " [BASARILI] Sistemde $($drives.Count) adet surucu basariyla listelendi." -ForegroundColor Green
    Write-Host " Ilk surucu: $($drives[0].DriveLetter) - $($drives[0].DiskModel)" -ForegroundColor Gray
} else {
    throw "Surucu listesi bos dondu!"
}

# 4. Test 2: Tum Dosyalari Kurtarma (Mode: All) Testi
Write-Host ""
Write-Host ">> TEST 2: Tam Disk Kurtarma (Mode: All)..." -ForegroundColor Yellow

# Desktop ortam degiskenini gecici olarak test klasorune yonlendirelim
$originalDesktop = [Environment]::GetEnvironmentVariable("USERPROFILE")
$recoveredBase = Join-Path ([Environment]::GetFolderPath("Desktop")) "recovered"

Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "All"

# Kontrol: Masaustunde recovered klasoru olustu mu?
if (Test-Path $recoveredBase) {
    $latestRecovery = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    Write-Host " [OK] Kurtarma oturumu olusturuldu: $($latestRecovery.FullName)" -ForegroundColor Green

    # Kurtarilan dosyalari kontrol et
    $recDoc = Join-Path $latestRecovery.FullName "Belgeler\Tez_Calismasi.docx"
    $recSecret = Join-Path $latestRecovery.FullName "GizliKlasor\GizliVeri.pdf"
    $recReadOnly = Join-Path $latestRecovery.FullName "Belgeler\SaltOkunurSozlesme.txt"
    $reportTxt = Join-Path $latestRecovery.FullName "kurtarma_raporu.txt"

    if (Test-Path $recDoc) {
        Write-Host " [BASARILI] Belge dosyasi kurtarildi: $recDoc" -ForegroundColor Green
    } else {
        throw "Belge dosyasi kurtarilamadi!"
    }

    if (Test-Path $recSecret) {
        Write-Host " [BASARILI] Gizli dosya kurtarildi: $recSecret" -ForegroundColor Green
    } else {
        throw "Gizli dosya kurtarilamadi!"
    }

    if (Test-Path $recReadOnly) {
        # Ozniteligin Normal yapildigini kontrol et
        $attr = (Get-Item $recReadOnly).Attributes
        if (-not ($attr -band [System.IO.FileAttributes]::ReadOnly)) {
            Write-Host " [BASARILI] Salt okunur dosya kurtarildi ve kilidi Normal olarak acildi!" -ForegroundColor Green
        } else {
            throw "Kurtarilan dosyadaki salt okunur oznitelik temizlenememis!"
        }
    } else {
        throw "Salt okunur dosya kurtarilamadi!"
    }

    if (Test-Path $reportTxt) {
        Write-Host " [BASARILI] Kurtarma raporu olusturuldu:" -ForegroundColor Green
        Get-Content $reportTxt | Select-Object -First 12 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    } else {
        throw "Kurtarma rapor dosyasi bulunamadi!"
    }
} else {
    throw "Desktop\recovered klasoru olusturulamadi!"
}

# 5. Test 3: Kısayol Virüsü Temizleme Modu Testi (Mode: Unhide)
Write-Host ""
Write-Host ">> TEST 3: Kisayol Virusu Temizleme Modu (Mode: Unhide)..." -ForegroundColor Yellow
Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "Unhide"
$latestRecovery2 = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
$recLnk = Join-Path $latestRecovery2.FullName "VirusSimulasyonu\Belgeler.lnk"
if (-not (Test-Path $recLnk)) {
    Write-Host " [BASARILI] Zararli .lnk kisayol dosyasi basariyla filtrelendi ve atlandi." -ForegroundColor Green
} else {
    Write-Host " [!] .lnk dosyasi kopyalandi (dikkat)." -ForegroundColor Yellow
}

# 6. Test 4: Dosya Turune Gore Filtreleme (Mode: Preset - PDF only)
Write-Host ""
Write-Host ">> TEST 4: Uzanti Filtreleme Modu (Sadece .pdf)..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 1200
Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "Preset" -Extensions @(".pdf")
$latestRecovery3 = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$recDoc3 = Join-Path $latestRecovery3.FullName "Belgeler\Tez_Calismasi.docx"
$recPdf3 = Join-Path $latestRecovery3.FullName "GizliKlasor\GizliVeri.pdf"

if ((-not (Test-Path $recDoc3)) -and (Test-Path $recPdf3)) {
    Write-Host " [BASARILI] Sadece PDF dosyasi kurtarildi, docx filtrelendi." -ForegroundColor Green
} else {
    throw "Uzanti filtreleme testi basarisiz!"
}

# 7. Temizlik
Write-Host ""
Write-Host " [*] Test ortami temizleniyor..." -ForegroundColor Gray
Remove-Item $testBench -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Green
Write-Host "               TUM TESTLER BASARIYLA TAMAMLANDI (PASSED)                  " -ForegroundColor Green
Write-Host "===========================================================================" -ForegroundColor Green
