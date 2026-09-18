#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sets up SSH access to WSL2 from other machines on the network.
.DESCRIPTION
    Forwards Windows port 2222 to WSL port 22 via netsh portproxy.
    Adds a Windows Firewall rule to allow inbound connections on port 2222.
.NOTES
    Run this script in PowerShell as Administrator.
    After reboot, WSL IP may change. Run fix-port-forward.ps1 to update.
#>

Write-Host "=== WSL2 SSH Access Setup ===" -ForegroundColor Cyan

# Get current WSL IP
Write-Host "`n[1/4] Detecting WSL IP..." -ForegroundColor Yellow
$wslIP = (wsl hostname -I).Trim()
Write-Host "  WSL IP: $wslIP"

if ([string]::IsNullOrWhiteSpace($wslIP) -or $wslIP -notmatch '^\d+\.\d+\.\d+\.\d+') {
    Write-Host "  ERROR: Could not detect a valid WSL IP. Is WSL running?" -ForegroundColor Red
    Write-Host "  Try: wsl -- bash -c 'hostname -I'" -ForegroundColor Gray
    exit 1
}

# Remove existing port forward rule if any
Write-Host "`n[2/4] Cleaning up old port forward..." -ForegroundColor Yellow
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>$null
Write-Host "  Done."

# Add new port forward
Write-Host "`n[3/4] Setting up port forward (0.0.0.0:2222 -> WSL:22)..." -ForegroundColor Yellow
netsh interface portproxy add v4tov4 `
    listenport=2222 `
    listenaddress=0.0.0.0 `
    connectport=22 `
    connectaddress=$wslIP
Write-Host "  Done."

# Verify
$rule = netsh interface portproxy show all | Select-String "2222"
Write-Host "  Active rule: $rule"

# Add firewall rule
Write-Host "`n[4/4] Adding Windows Firewall rule..." -ForegroundColor Yellow
$existingRule = Get-NetFirewallRule -DisplayName "WSL SSH" -ErrorAction SilentlyContinue
if ($existingRule) {
    Remove-NetFirewallRule -DisplayName "WSL SSH"
}
New-NetFirewallRule `
    -DisplayName "WSL SSH" `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 2222 `
    -Description "Allow SSH access to WSL2 via port 2222" | Out-Null
Write-Host "  Done."

# Summary
Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
$windowsIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -ne "127.0.0.1" } | Select-Object -First 1).IPAddress
Write-Host "  Windows IP : $windowsIP" -ForegroundColor Cyan
Write-Host "  WSL IP     : $wslIP" -ForegroundColor Cyan
Write-Host "  SSH Command : ssh shivam@${windowsIP} -p 2222" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: WSL IP may change after reboot." -ForegroundColor Yellow
Write-Host "Run fix-port-forward.ps1 as Administrator to update the rule." -ForegroundColor Yellow
