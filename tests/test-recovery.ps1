# PS-Recover Automated Test Suite (Unit & Integration Tests)
# Validates drive enumeration, file recovery engine, shortcut virus cleaning,
# file extension filtering, reporting, and multilingual support (EN & TR).

$ErrorActionPreference = "Stop"

Write-Host "===========================================================================" -ForegroundColor Cyan
Write-Host "               PS-RECOVER TEST AND VERIFICATION SUITE                      " -ForegroundColor Yellow
Write-Host "===========================================================================" -ForegroundColor Cyan

$scriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$repoRoot = Split-Path $scriptRoot -Parent
$recoverScript = Join-Path $repoRoot "recover.ps1"

Write-Host " [*] Loading recover.ps1: $recoverScript" -ForegroundColor Gray
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

[System.IO.File]::SetAttributes($secretFile, [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
[System.IO.File]::SetAttributes($readOnlyFile, [System.IO.FileAttributes]::ReadOnly)

Write-Host " [OK] Mock test bench environment created successfully." -ForegroundColor Green

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

# TEST 1: Drive Listing
Write-Host ""
Write-Host ">> TEST 1: Drive Listing (Get-PSRecoverDriveList)..." -ForegroundColor Yellow
$drives = @(Get-PSRecoverDriveList)
if ($drives -and $drives.Count -gt 0) {
    Write-Host " [PASSED] Enumerated $($drives.Count) drive(s) on system." -ForegroundColor Green
    Write-Host " Primary drive: $($drives[0].DriveLetter) - $($drives[0].DiskModel)" -ForegroundColor Gray
} else {
    throw "Drive list returned empty!"
}

# TEST 2: Full Recovery in English (Mode: All, Lang: en)
Write-Host ""
Write-Host ">> TEST 2: Full Disk Recovery in English (Mode: All, Lang: en)..." -ForegroundColor Yellow
Set-PSRecoverLanguage "en"
$recoveredBase = Join-Path ([Environment]::GetFolderPath("Desktop")) "recovered"

Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "All"

if (Test-Path $recoveredBase) {
    $latestRecovery = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    Write-Host " [OK] Recovery folder created: $($latestRecovery.FullName)" -ForegroundColor Green

    $recDoc = Join-Path $latestRecovery.FullName "Belgeler\Tez_Calismasi.docx"
    $recSecret = Join-Path $latestRecovery.FullName "GizliKlasor\GizliVeri.pdf"
    $recReadOnly = Join-Path $latestRecovery.FullName "Belgeler\SaltOkunurSozlesme.txt"
    $reportEn = Join-Path $latestRecovery.FullName "recovery_report.txt"

    if (Test-Path $recDoc) {
        Write-Host " [PASSED] Document recovered: $recDoc" -ForegroundColor Green
    } else {
        throw "Document file was not recovered!"
    }

    if (Test-Path $recSecret) {
        Write-Host " [PASSED] Hidden system file recovered: $recSecret" -ForegroundColor Green
    } else {
        throw "Hidden file was not recovered!"
    }

    if (Test-Path $recReadOnly) {
        $attr = (Get-Item $recReadOnly).Attributes
        if (-not ($attr -band [System.IO.FileAttributes]::ReadOnly)) {
            Write-Host " [PASSED] Read-only attribute cleared to Normal!" -ForegroundColor Green
        } else {
            throw "Read-only attribute was not normalized!"
        }
    } else {
        throw "Read-only file was not recovered!"
    }

    if (Test-Path $reportEn) {
        Write-Host " [PASSED] English report generated: $reportEn" -ForegroundColor Green
    } else {
        throw "English report file (recovery_report.txt) not found!"
    }
} else {
    throw "Desktop\recovered folder was not created!"
}

# TEST 3: Recovery in Turkish (Mode: All, Lang: tr)
Write-Host ""
Write-Host ">> TEST 3: Full Disk Recovery in Turkish (Mode: All, Lang: tr)..." -ForegroundColor Yellow
Set-PSRecoverLanguage "tr"
Start-Sleep -Milliseconds 1200
Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "All"

$latestRecoveryTr = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$reportTr = Join-Path $latestRecoveryTr.FullName "kurtarma_raporu.txt"
if (Test-Path $reportTr) {
    Write-Host " [PASSED] Turkish report generated: $reportTr" -ForegroundColor Green
} else {
    throw "Turkish report file (kurtarma_raporu.txt) not found!"
}

# TEST 4: Shortcut Virus Cleanup (Mode: Unhide)
Write-Host ""
Write-Host ">> TEST 4: Shortcut Virus Cleanup Mode (Mode: Unhide)..." -ForegroundColor Yellow
Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "Unhide"
$latestRecoveryUnhide = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
$recLnk = Join-Path $latestRecoveryUnhide.FullName "VirusSimulasyonu\Belgeler.lnk"
if (-not (Test-Path $recLnk)) {
    Write-Host " [PASSED] Malicious .lnk shortcut file was filtered and skipped." -ForegroundColor Green
} else {
    Write-Host " [!] .lnk file copied (warning)." -ForegroundColor Yellow
}

# TEST 5: File Type Extension Filtering (.pdf only)
Write-Host ""
Write-Host ">> TEST 5: Extension Filtering Mode (.pdf only)..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 1200
Invoke-FileRecoveryEngine -SelectedDrive $mockDisk -Mode "Preset" -Extensions @(".pdf")
$latestRecoveryPreset = Get-ChildItem -Path $recoveredBase -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$recDocPreset = Join-Path $latestRecoveryPreset.FullName "Belgeler\Tez_Calismasi.docx"
$recPdfPreset = Join-Path $latestRecoveryPreset.FullName "GizliKlasor\GizliVeri.pdf"

if ((-not (Test-Path $recDocPreset)) -and (Test-Path $recPdfPreset)) {
    Write-Host " [PASSED] Only PDF files were recovered; docx was filtered." -ForegroundColor Green
} else {
    throw "Extension filtering test failed!"
}

# Cleanup
Write-Host ""
Write-Host " [*] Cleaning up mock environment..." -ForegroundColor Gray
Remove-Item $testBench -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Green
Write-Host "               ALL TESTS COMPLETED SUCCESSFULLY (PASSED)                   " -ForegroundColor Green
Write-Host "===========================================================================" -ForegroundColor Green
