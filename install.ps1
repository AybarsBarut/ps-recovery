# PS-Recover Installation Script (Windows PowerShell / PowerShell Core)
# Remote execution:
# irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/install.ps1 | iex

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

if ($targetLang -eq "tr") {
    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host "   PS-Recover - Windows Disk & Flash Kurtarma Araci Kurulumu               " -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host "   PS-Recover - Windows Storage Recovery & Repair Engine Installer         " -ForegroundColor Yellow
    Write-Host " ===========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

$installFolder = Join-Path $HOME ".ps-recover"
if (-not (Test-Path $installFolder)) {
    New-Item -ItemType Directory -Path $installFolder -Force | Out-Null
}

try {
    Set-Content -Path (Join-Path $installFolder "lang.conf") -Value $targetLang -Force -ErrorAction SilentlyContinue
} catch {}

$targetScript = Join-Path $installFolder "recover.ps1"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {}

$repo = "AybarsBarut/ps-recovery"
$branch = "main"
$isLocal = $false

if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    try {
        $localCandidate = Join-Path $PSScriptRoot "recover.ps1"
        if (Test-Path $localCandidate) {
            $srcPath = (Resolve-Path $localCandidate).Path
            $dstPath = if (Test-Path $targetScript) { (Resolve-Path $targetScript).Path } else { "" }
            if ($srcPath -ine $dstPath) {
                Copy-Item -Path $localCandidate -Destination $targetScript -Force
                if ($targetLang -eq "tr") {
                    Write-Host " [OK] Yerel recover.ps1 kopyalandi: $targetScript" -ForegroundColor Green
                } else {
                    Write-Host " [OK] Local recover.ps1 copied: $targetScript" -ForegroundColor Green
                }
            }
            $isLocal = $true
        }
    } catch {}
}

if (-not $isLocal) {
    if ($targetLang -eq "tr") {
        Write-Host " [*] PS-Recover ana betigi GitHub reposundan ($repo) indiriliyor..." -ForegroundColor Cyan
    } else {
        Write-Host " [*] Downloading PS-Recover main script from GitHub repository ($repo)..." -ForegroundColor Cyan
    }
    $repoUrl = "https://raw.githubusercontent.com/$repo/$branch/recover.ps1"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        $scriptContent = $webClient.DownloadString($repoUrl)
        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            throw "Downloaded script content is empty!"
        }
        [System.IO.File]::WriteAllText($targetScript, $scriptContent, [System.Text.Encoding]::UTF8)
        if ($targetLang -eq "tr") {
            Write-Host " [OK] En guncel betik basariyla indirildi: $targetScript" -ForegroundColor Green
        } else {
            Write-Host " [OK] Latest script successfully downloaded: $targetScript" -ForegroundColor Green
        }
    } catch {
        if ($targetLang -eq "tr") {
            Write-Host " [!] Betik indirilirken hata olustu: $($_.Exception.Message)" -ForegroundColor Red
        } else {
            Write-Host " [!] Error downloading script: $($_.Exception.Message)" -ForegroundColor Red
        }
        return
    }
}

if (-not (Test-Path $targetScript)) {
    if ($targetLang -eq "tr") {
        Write-Host " [!] Kritik Hata: recover.ps1 dosyasina erisilemiyor ($targetScript)." -ForegroundColor Red
    } else {
        Write-Host " [!] Critical Error: Cannot access recover.ps1 at $targetScript." -ForegroundColor Red
    }
    return
}

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

# >>> PS-Recover: Windows Disk & Flash Recovery Engine >>>
if (Test-Path "$targetScript") {
    . "$targetScript"
}
# <<< PS-Recover <<<
"@

if ($profileText -notmatch "PS-Recover") {
    Add-Content -Path $PROFILE -Value $loaderBlock -Encoding UTF8
    if ($targetLang -eq "tr") {
        Write-Host " [OK] 'recover' komutu PowerShell profilinize kaydedildi ($PROFILE)." -ForegroundColor Green
    } else {
        Write-Host " [OK] 'recover' command registered in your PowerShell profile ($PROFILE)." -ForegroundColor Green
    }
} else {
    if ($targetLang -eq "tr") {
        Write-Host " [i] 'recover' komutu zaten PowerShell profilinizde kayitli." -ForegroundColor Yellow
    } else {
        Write-Host " [i] 'recover' command is already registered in your PowerShell profile." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Cyan
if ($targetLang -eq "tr") {
    Write-Host "  KURULUM TAMAMLANDI!" -ForegroundColor Green
    Write-Host "  Artik herhangi bir PowerShell penceresine sadece 'recover' yazarak" -ForegroundColor White
    Write-Host "  bagli diskleri listeleyebilir, dosya kurtarabilir ve salt okunur flashlari" -ForegroundColor White
    Write-Host "  duzeltebilirsiniz." -ForegroundColor White
} else {
    Write-Host "  INSTALLATION COMPLETED!" -ForegroundColor Green
    Write-Host "  You can now type 'recover' in any PowerShell terminal to list drives," -ForegroundColor White
    Write-Host "  recover files, and repair write-protected flash drives." -ForegroundColor White
}
Write-Host " ---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

if ($targetLang -eq "tr") {
    Write-Host " [*] PS-Recover simdi baslatiliyor..." -ForegroundColor Yellow
} else {
    Write-Host " [*] Starting PS-Recover now..." -ForegroundColor Yellow
}
Start-Sleep -Milliseconds 500
. "$targetScript"
recover -Lang $targetLang
