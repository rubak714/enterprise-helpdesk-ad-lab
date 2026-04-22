#!/bin/bash
echo "=== Local Users with Login Shell ==="
awk -F: '$7 ~ /bash|sh$/ {printf "  %-20s UID:%-6s Home:%s\n", $1, $3, $6}' /etc/passwd

echo ""
echo "=== AD Users (via SSSD) ==="
if command -v getent &> /dev/null; then
    getent passwd | awk -F: '$3 >= 10000 {printf "  %-20s UID:%-6s Home:%s\n", $1, $3, $6}'
else
    echo "  getent not available. SSSD may not be configured."
fi

echo ""
echo "=== Users with Sudo Access ==="
grep -r "^[^#]" /etc/sudoers.d/ 2>/dev/null || echo "  No custom sudoers files."

echo ""
echo "=== Failed SSH Logins (last 24h) ==="
journalctl -u sshd --since "24 hours ago" --no-pager 2>/dev/null | \
    grep "Failed" | tail -10 || echo "  No failed logins found."

echo ""
echo "=== Currently Logged In ==="
who