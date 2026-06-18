#!/bin/bash
set -e

# 确保进入 OpenWrt 源码目录
cd "$OPENWRT_PATH" || exit 1

echo "========================== 修复 hostapd/NSS 冲突 =========================="

PATCH_DIR="target/linux/qualcommax/patches-6.6"

# 定义需要删除的冲突补丁列表
PATCH_FILES=(
    "0600-3-qca-nss-ecm-support-net-bonding.patch"
    "0600-4-qca-nss-ecm-support-net-bonding-over-LAG-interface.patch"
)

# 循环检查并删除
for file in "${PATCH_FILES[@]}"; do
    FULL_PATH="$PATCH_DIR/$file"
    if [ -f "$FULL_PATH" ]; then
        rm -f "$FULL_PATH"
        echo "[成功] 已删除冲突补丁: $file"
    else
        echo "[跳过] 补丁不存在或已被清理: $file"
    fi
done

echo "========================= 冲突补丁清理完毕 ========================="
