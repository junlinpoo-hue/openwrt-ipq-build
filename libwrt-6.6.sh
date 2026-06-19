#!/bin/bash
# fix_nss_ecm_6_6.sh
# Fix QCA NSS ECM bonding incompatibility on Linux 6.6

set -e

echo "=========================================="
echo " Fix NSS ECM bonding issue for Linux 6.6 "
echo "=========================================="

ECM_PATH=$(find . -type d -path "*qca-nss-ecm*" | head -n 1)

if [ -z "$ECM_PATH" ]; then
    echo "[ERROR] qca-nss-ecm path not found"
    exit 1
fi

echo "[INFO] ECM path: $ECM_PATH"

cd "$ECM_PATH"

echo "------------------------------------------"
echo "1. Disable bond notifier source file"
echo "------------------------------------------"

if [ -f "frontends/cmn/ecm_bond_notifier.c" ]; then
    echo "[PATCH] Neutralizing ecm_bond_notifier.c"

    cat > frontends/cmn/ecm_bond_notifier.c << 'EOF'
/*
 * Disabled for Linux 6.6 compatibility
 * bond_cb API removed from kernel
 */

#include <linux/module.h>

static int ecm_bond_notifier_init(void)
{
    return 0;
}

static void ecm_bond_notifier_exit(void)
{
}

module_init(ecm_bond_notifier_init);
module_exit(ecm_bond_notifier_exit);

MODULE_LICENSE("GPL");
EOF
fi

echo "------------------------------------------"
echo "2. Patch Makefile to prevent compilation"
echo "------------------------------------------"

MAKEFILE_PATH=$(find . -type f -name "Makefile" | grep frontends/cmn | head -n 1)

if [ -n "$MAKEFILE_PATH" ]; then
    echo "[PATCH] Fix Makefile: $MAKEFILE_PATH"

    sed -i 's/ecm_bond_notifier.o/# ecm_bond_notifier.o (disabled for 6.6)/g' "$MAKEFILE_PATH"
fi

echo "------------------------------------------"
echo "3. Safety clean"
echo "------------------------------------------"

find . -name "*.o" -delete 2>/dev/null || true

echo "------------------------------------------"
echo "DONE"
echo "------------------------------------------"
echo "Now rebuild OpenWrt:"
echo "  make -j$(nproc)"
echo "=========================================="
