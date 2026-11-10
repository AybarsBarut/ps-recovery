# PS-Recover Kurulum Betigi (Windows PowerShell / PowerShell Core)
# Tek satirda kurulum:
# irm https://raw.githubusercontent.com/AybarsBarut/drive-recovery/main/install.ps1 | iex

param(
    [string]$Repo = "AybarsBarut/drive-recovery",
    [string]$Branch = "main"
)

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host " ===========================================================================" -ForegroundColor Cyan
Write-Host "   PS-Recover - Windows Disk & Flash Kurtarma Araci Kurulumu               " -ForegroundColor Yellow
Write-Host " ===========================================================================" -ForegroundColor Cyan
Write-Host ""

$installFolder = Join-Path $HOME ".ps-recover"
if (-not (Test-Path $installFolder)) {
    New-Item -ItemType Directory -Path $installFolder -Force | Out-Null
}

$targetScript = Join-Path $installFolder "recover.ps1"

# Eger yerel depodan calisiyorsa yerel recover.ps1'i kopyala, degilse GitHub'dan indir
$localRecover = Join-Path $PSScriptRoot "recover.ps1"
if (Test-Path $localRecover) {
    Copy-Item -Path $localRecover -Destination $targetScript -Force
    Write-Host " [OK] Yerel recover.ps1 kopyalandi: $targetScript" -ForegroundColor Green
} else {
    Write-Host " [*] PS-Recover ana betigi GitHub reposundan ($Repo) indiriliyor..." -ForegroundColor Cyan
    $repoUrl = "https://raw.githubusercontent.com/$Repo/$Branch/recover.ps1"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        $scriptContent = $webClient.DownloadString($repoUrl)
        [System.IO.File]::WriteAllText($targetScript, $scriptContent, [System.Text.Encoding]::UTF8)
        Write-Host " [OK] En guncel betik basariyla indirildi: $targetScript" -ForegroundColor Green
    } catch {
        Write-Host " [!] Betik indirilirken hata olustu: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# PowerShell Profiline ekleme
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$profileText = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $profileText) { $profileText = "" }

$loaderBlock = @"

# >>> PS-Recover: Windows Disk & Flash Bellek Kurtarma Araci >>>
if (Test-Path "$targetScript") {
    . "$targetScript"
}
# <<< PS-Recover <<<
"@

if ($profileText -notmatch "PS-Recover") {
    Add-Content -Path $PROFILE -Value $loaderBlock -Encoding UTF8
    Write-Host " [OK] 'recover' komutu PowerShell profilinize kaydedildi ($PROFILE)." -ForegroundColor Green
} else {
    Write-Host " [i] 'recover' komutu zaten PowerShell profilinizde kayitli." -ForegroundColor Yellow
}

Write-Host ""
Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  KURULUM TAMAMLANDI!" -ForegroundColor Green
Write-Host "  Artik herhangi bir PowerShell penceresine sadece 'recover' yazarak" -ForegroundColor White
Write-Host "  bagli diskleri listeleyebilir, dosya kurtarabilir ve salt okunur flashlari" -ForegroundColor White
Write-Host "  duzeltebilirsiniz." -ForegroundColor White
Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Hemen calistir
Write-Host " [*] PS-Recover simdi baslatiliyor..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 800
. "$targetScript"
recover
