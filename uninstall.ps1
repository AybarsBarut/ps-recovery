# PS-Recover Kaldirma Betigi
# irm https://raw.githubusercontent.com/4rchura/drive-recovery/main/uninstall.ps1 | iex

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host " ===========================================================================" -ForegroundColor Yellow
Write-Host "   PS-Recover - Kaldirma Islemi                                             " -ForegroundColor Yellow
Write-Host " ===========================================================================" -ForegroundColor Yellow

# Profil kaydini temizle
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
    Write-Host " [OK] PowerShell profilinden 'recover' komutu kaldirildi." -ForegroundColor Green
}

# Kurulum klasorunu temizle
$installFolder = Join-Path $HOME ".ps-recover"
if (Test-Path $installFolder) {
    Remove-Item -Path $installFolder -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " [OK] Yerel dosyalar silindi ($installFolder)." -ForegroundColor Green
}

Write-Host ""
Write-Host " [OK] PS-Recover sisteminizden basariyla kaldirildi." -ForegroundColor Green
Write-Host ""
