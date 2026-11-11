# PS-Recover Uninstallation Script
# Remote execution:
# irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/uninstall.ps1 | iex

param(
    [Alias("Language")]
    [string]$Lang = ""
)

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$targetLang = "en"
if (-not [string]::IsNullOrWhiteSpace($Lang)) {
    $clean = $Lang.Trim().ToLower()
    if ($clean -in @("tr", "turkish", "turkce")) { $targetLang = "tr" }
} elseif (-not [string]::IsNullOrWhiteSpace($env:PS_RECOVER_LANG)) {
    $clean = $env:PS_RECOVER_LANG.Trim().ToLower()
    if ($clean -in @("tr", "turkish", "turkce")) { $targetLang = "tr" }
} else {
    try {
        if ((Get-Culture).TwoLetterISOLanguageName.ToLower() -eq "tr") {
            $targetLang = "tr"
        }
    } catch {}
}

Write-Host ""
Write-Host " ===========================================================================" -ForegroundColor Yellow
if ($targetLang -eq "tr") {
    Write-Host "   PS-Recover - Kaldirma Islemi                                             " -ForegroundColor Yellow
} else {
    Write-Host "   PS-Recover - Uninstallation Process                                      " -ForegroundColor Yellow
}
Write-Host " ===========================================================================" -ForegroundColor Yellow

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
    if ($targetLang -eq "tr") {
        Write-Host " [OK] PowerShell profilinden 'recover' komutu kaldirildi." -ForegroundColor Green
    } else {
        Write-Host " [OK] 'recover' command removed from PowerShell profile." -ForegroundColor Green
    }
}

$installFolder = Join-Path $HOME ".ps-recover"
if (Test-Path $installFolder) {
    Remove-Item -Path $installFolder -Recurse -Force -ErrorAction SilentlyContinue
    if ($targetLang -eq "tr") {
        Write-Host " [OK] Yerel dosyalar silindi ($installFolder)." -ForegroundColor Green
    } else {
        Write-Host " [OK] Local files deleted ($installFolder)." -ForegroundColor Green
    }
}

Write-Host ""
if ($targetLang -eq "tr") {
    Write-Host " [OK] PS-Recover sisteminizden basariyla kaldirildi." -ForegroundColor Green
} else {
    Write-Host " [OK] PS-Recover has been successfully removed from your system." -ForegroundColor Green
}
Write-Host ""
