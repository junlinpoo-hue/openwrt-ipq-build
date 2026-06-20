#!/bin/bash
set -e

cd "$OPENWRT_PATH"

echo "========================================="
echo "Fix qca-nss-ecm bonding for kernel 6.6"
echo "========================================="

# 1. 删除所有 bonding patch（之前已有的）
for f in target/linux/qualcommax/patches-6.6/0600-*-bonding*.patch; do
    [ -f "$f" ] && rm -f "$f" && echo "[OK] Removed patch: $f"
done

# 2. 禁用 ECM bonding notifier（新增）
ECM_DIR="feeds/nss_packages/qca-nss-ecm"
find "$ECM_DIR" -name "ecm_bond_notifier.c" -delete 2>/dev/null && echo "[OK] Removed ecm_bond_notifier.c"
find "$ECM_DIR" -type f \( -name "Makefile" -o -name "*.mk" \) \
    -exec sed -i '/ecm_bond_notifier/d' {} + 2>/dev/null && echo "[OK] Removed from Makefiles"

# 3. 禁用配置
echo "CONFIG_QCA_NSS_ECM_BOND_NOTIFIER=n" >> .config

echo "All fixes applied"
