<#
secure-install-choco.ps1
A small hardened wrapper for downloading and verifying Chocolatey package before executing its install script.

Usage:
  powershell.exe -ExecutionPolicy Bypass -File .\secure-install-choco.ps1 -ChocolateyDownloadUrl <url> -ExpectedSha256 <hex>

Notes:
  - This script is conservative: if no signature is present it aborts by default. You can change behavior to allow unsigned when hash matches.
  - Run as Administrator when ready to install.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ChocolateyDownloadUrl = 'https://community.chocolatey.org/api/v2/package/chocolatey',

    [Parameter(Mandatory=$false)]
    [string]$ExpectedSha256 = ''
)

function Fail([string]$msg) {
    Write-Error $msg
    exit 1
}

try {
    # Force TLS1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
} catch {
    Write-Warning "Unable to set TLS1.2, proceeding anyway: $_"
}

$dest = Join-Path $env:TEMP 'chocolatey_secure.nupkg'
Write-Host "Downloading $ChocolateyDownloadUrl to $dest"
try {
    (New-Object System.Net.WebClient).DownloadFile($ChocolateyDownloadUrl, $dest)
} catch {
    Fail "Unable to download package: $_"
}

if ($ExpectedSha256) {
    try {
        $actual = (Get-FileHash -Path $dest -Algorithm SHA256).Hash
    } catch {
        Fail "Failed to compute file hash: $_"
    }

    if ($actual -ne $ExpectedSha256) {
        Fail "SHA256 mismatch. Expected: $ExpectedSha256, Actual: $actual"
    } else {
        Write-Host "SHA256 OK."
    }
} else {
    Write-Warning "No expected SHA256 provided; skipping hash verification. Consider providing ExpectedSha256 for security."
}

$extractDir = Join-Path $env:TEMP 'choco_secure_extract'
Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $extractDir | Out-Null

try {
    Expand-Archive -Path $dest -DestinationPath $extractDir -Force
} catch {
    Fail "Failed to extract package: $_"
}

$installScript = Join-Path $extractDir 'tools\chocolateyInstall.ps1'
if (-not (Test-Path $installScript)) {
    Fail "Install script not found in package at $installScript"
}

# Check Authenticode signature
$sig = Get-AuthenticodeSignature -FilePath $installScript
if ($sig -and $sig.SignerCertificate) {
    if ($sig.Status -eq 'Valid') {
        Write-Host "Authenticode signature is valid."
    } else {
        Fail "Authenticode signature status: $($sig.Status). Aborting."
    }
} else {
    # Conservative default: abort when no signature
    Fail "No Authenticode signature found on $installScript. Aborting by default."
}

# Confirm with user
Write-Host "Ready to execute $installScript. This will run with current PowerShell privileges."
$confirm = Read-Host "Type 'Y' to continue and execute the install script"
if ($confirm -ne 'Y') { Write-Host "Aborted by user."; Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue; exit 0 }

# Execute
try {
    & $installScript
} catch {
    Fail "Execution of install script failed: $_"
}

# Cleanup
Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
Write-Host "Secure install completed."
