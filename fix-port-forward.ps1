#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Updates the WSL2 SSH port forward after WSL IP changes.
.DESCRIPTION
    Run this after WSL reboot if SSH stops working.
    Add to Windows Task Scheduler for automatic execution on login.
#>

$wslIP = (wsl hostname -I).Trim()

if ([string]::IsNullOrWhiteSpace($wslIP) -or $wslIP -notmatch '^\d+\.\d+\.\d+\.\d+') {
    Write-Host "ERROR: Could not detect WSL IP. Is WSL running?" -ForegroundColor Red
    exit 1
}

# Remove old rule
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>$null

# Add updated rule
netsh interface portproxy add v4tov4 `
    listenport=2222 `
    listenaddress=0.0.0.0 `
    connectport=22 `
    connectaddress=$wslIP

Write-Host "Port forward updated: 2222 -> WSL($wslIP):22" -ForegroundColor Green
