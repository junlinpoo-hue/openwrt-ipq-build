 
#!/bin/bash
set -e

echo "========================================="
echo "Remove incompatible bonding patch"
echo "========================================="

PATCH_FILE="target/linux/qualcommax/patches-6.6/0600-4-qca-nss-ecm-support-net-bonding-over-LAG-interface.patch"

if [ -f "$PATCH_FILE" ]; then
    rm -f "$PATCH_FILE"
    echo "[OK] Removed:"
    echo "     $PATCH_FILE"
else
    echo "[SKIP] Patch not found"
fi
echo "Checking NSS patches..."
ls -l target/linux/qualcommax/patches-6.6/ | grep bonding || true
