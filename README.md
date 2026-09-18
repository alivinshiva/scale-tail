# Remote Access to WSL via SSH

Access your WSL2 terminal from any other machine using SSH — same LAN or different network.

---

## Two Access Methods

### Method 1: Same LAN (Port Forwarding)

```
[Other Machine] --SSH--> [Windows Host:2222] --Port Forward--> [WSL:22]
```

Works only when both machines are on the same office/home network. Requires Windows port forwarding.

### Method 2: Any Network (Tailscale) — Recommended

```
[Other Machine] --Tailscale mesh VPN--> [WSL:22]
```

Each machine gets a stable `100.x.x.x` IP. Works from home, café, mobile data — anywhere. No port forwarding, survives WSL reboots.

**Our Tailscale IP:** `100.107.255.4`

```bash
ssh shivam@100.107.255.4
```

---

## VS Code Remote Access (Any Network)

### 1. Install Extension
Install **Remote - SSH** (by Microsoft) on the client machine.

### 2. Add host to SSH config
`F1` → **Remote-SSH: Open SSH Configuration File** → add:

```
Host wsl-office
    HostName 100.107.255.4
    User shivam
    IdentityFile ~/.ssh/id_ed25519
```

### 3. Connect
`F1` → **Remote-SSH: Connect to Host** → select `wsl-office`

Gives you full VS Code experience — terminal, file explorer, extensions, debugging, port forwarding.

---

## LAN-Only Setup (Port Forwarding Details Below)

## How It Works

```
[Other Machine] --SSH--> [Windows Host:2222] --Port Forward--> [WSL:22]
```

WSL2 runs behind NAT. Windows acts as the gateway. We forward a Windows port into WSL.

---

## Prerequisites

- Windows machine with WSL2 + Ubuntu
- OpenSSH server installed in WSL
- Admin access to Windows PowerShell

---

## Step 1: Verify SSH Server in WSL

SSH server is already installed and active. Verify it:

```bash
# Check status
sudo systemctl status ssh

# If not running, start it
sudo systemctl start ssh
sudo systemctl enable ssh
```

---

## Step 2: Set Up Port Forwarding on Windows

Open **PowerShell as Administrator** on the Windows host and run:

```powershell
# Get WSL IP
$wslIP = (wsl hostname -I).Trim()
Write-Host "WSL IP: $wslIP"

# Forward Windows port 2222 -> WSL port 22
netsh interface portproxy add v4tov4 `
    listenport=2222 `
    listenaddress=0.0.0.0 `
    connectport=22 `
    connectaddress=$wslIP

# Allow port 2222 through Windows Firewall
netsh advfirewall firewall add rule `
    name="WSL SSH" `
    dir=in `
    action=allow `
    protocol=TCP `
    localport=2222
```

---

## Step 3: SSH From Another Machine

From any machine on the same network:

```bash
ssh shivam@<WINDOWS_IP> -p 2222
```

Replace `<WINDOWS_IP>` with your Windows machine's LAN IP (e.g., `10.122.4.109`).

Find your Windows IP by running on Windows:
```powershell
ipconfig
```

---

## Step 4: (Recommended) SSH Key Setup

Avoid typing your password every time by setting up key-based auth.

**On the client machine** (the one you SSH from):

```bash
# Generate a key pair (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy the public key to WSL
ssh-copy-id -p 2222 shivam@<WINDOWS_IP>
```

After this, you can connect without a password:
```bash
ssh shivam@<WINDOWS_IP> -p 2222
```

---

## WSL IP Changes on Reboot

WSL2 may assign a new IP after reboot. The Windows port forward uses the old IP and breaks.

### Solution: Auto-Update Port Forward on WSL Startup

Run this once on Windows (PowerShell Admin) to create a startup script:

```powershell
# Create the auto-fix script
$script = @'
# Fix-WSLPortForward.ps1
$wslIP = (wsl hostname -I).Trim()

# Remove old rule
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>$null

# Add new rule
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=$wslIP

Write-Host "Port forward updated: 2222 -> WSL($wslIP):22"
'@

$script | Out-File -FilePath "C:\Users\$env:USERNAME\Fix-WSLPortForward.ps1" -Encoding UTF8

# Add to Windows Startup (Task Scheduler)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\Users\$env:USERNAME\Fix-WSLPortForward.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName "WSL Port Forward" -Action $action -Trigger $trigger -Description "Auto-update WSL SSH port forward" -RunLevel Highest

Write-Host "Created startup task. It will auto-fix on next login."
```

Or run the script directly from `access/fix-port-forward.ps1` after copying it to Windows.

---

## Quick Reference

| Item | Value |
|---|---|
| WSL SSH Port | 22 |
| Windows Forward Port | 2222 |
| Windows LAN IP | (check with `ipconfig`) |
| Username | shivam |
| SSH Command | `ssh shivam@<WINDOWS_IP> -p 2222` |

---

## Troubleshooting

### Connection Refused

1. Make sure SSH server is running in WSL:
   ```bash
   sudo systemctl status ssh
   ```

2. Verify the port forward exists:
   ```powershell
   netsh interface portproxy show all
   ```

3. Check Windows Firewall allows port 2222.

### Permission Denied

Make sure your user has a password set:
```bash
passwd shivam
```

Or use key-based auth (see Step 4).

### WSL Not Reachable

WSL2 might have a new IP. Re-run the port forward command or restart the startup task.

---

## Files in This Directory

| File | Description |
|---|---|
| `README.md` | This documentation |
| `setup.ps1` | Windows PowerShell setup script (run as Admin) |
| `fix-port-forward.ps1` | Auto-fix script for WSL IP changes |
| `verify.sh` | WSL-side verification script |
