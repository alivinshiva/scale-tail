#!/bin/bash
# verify.sh - Check that WSL SSH setup is working correctly
# Run this inside WSL

echo "=== WSL SSH Verification ==="
echo ""

# Check SSH server status
echo "[1] SSH Server Status:"
if systemctl is-active --quiet ssh; then
    echo "    OK: sshd is running"
else
    echo "    FAIL: sshd is not running. Fix: sudo systemctl start ssh"
fi

# Check SSH port
echo ""
echo "[2] Listening on port 22:"
if ss -tlnp | grep -q ":22 "; then
    ss -tlnp | grep ":22 " | awk '{print "    OK: "$4}'
else
    echo "    FAIL: Nothing listening on port 22"
fi

# Show WSL IP
echo ""
echo "[3] WSL IP Address:"
wslIP=$(hostname -I | awk '{print $1}')
echo "    $wslIP"

# Check host keys
echo ""
echo "[4] SSH Host Keys:"
if ls /etc/ssh/ssh_host_*_key &>/dev/null; then
    ls /etc/ssh/ssh_host_*_key.pub | while read key; do
        echo "    OK: $(basename $key)"
    done
else
    echo "    FAIL: No host keys. Fix: sudo ssh-keygen -A"
fi

# Check user password
echo ""
echo "[5] User Account:"
echo "    User: $(whoami)"
if passwd --status "$(whoami)" 2>/dev/null | grep -q "P"; then
    echo "    OK: Password is set"
else
    echo "    WARN: No password set. Run: passwd"
fi

# Show port forward instructions
echo ""
echo "=== Connection Info ==="
echo "From another machine, run:"
echo "  ssh shivam@<WINDOWS_IP> -p 2222"
echo ""
echo "Find Windows IP (run on Windows): ipconfig"
