
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Please run this script as Administrator" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

function Install-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        refreshenv
    }
}

function Install-WireguardTools {
    if (!(Get-Command wireguard -ErrorAction SilentlyContinue)) {
        Write-Host "Installing WireGuard..." -ForegroundColor Yellow
        choco install wireguard -y --force
    }
    if (!(Get-Command wgcf -ErrorAction SilentlyContinue)) {
        Write-Host "Downloading and installing WGCF..." -ForegroundColor Yellow
        $wgcfPath = "C:\ProgramData\wgcf\wgcf.exe"
        New-Item -ItemType Directory -Path "C:\ProgramData\wgcf" -Force | Out-Null
        Invoke-WebRequest -Uri "https://github.com/ViRb3/wgcf/releases/download/v2.2.23/wgcf_2.2.23_windows_amd64.exe" -OutFile $wgcfPath
        $env:Path += ";C:\ProgramData\wgcf"
        [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
    }
}

function Configure-WGCF {
    Write-Host "Registering WGCF and accepting Terms of Service..." -ForegroundColor Yellow
    Start-Process -FilePath "wgcf" -ArgumentList "register", "--accept-tos" -Wait -NoNewWindow
    Start-Process -FilePath "wgcf" -ArgumentList "generate" -Wait -NoNewWindow
}

function Connect-WireGuard {
    ls
    Write-Host "Connecting WireGuard..." -ForegroundColor Yellow
    $currentDirectory = Get-Location
    Write-Host "Current Directory: $currentDirectory" -ForegroundColor Magenta
    $wireguardPath = "C:\Program Files\WireGuard\wireguard.exe"
    & "$wireguardPath" /installtunnelservice "wgcf-profile.conf"
    Write-Host "Checking new IP address..." -ForegroundColor Green
    $newIP = (Invoke-RestMethod -Uri "http://ifconfig.me/ip").Trim()
    Write-Host "New IP Address: $newIP" -ForegroundColor Cyan
    return $newIP
}

try {
    Install-Chocolatey
    Install-WireguardTools
    Configure-WGCF
    Connect-WireGuard
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
