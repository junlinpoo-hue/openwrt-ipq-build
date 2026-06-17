#!/bin/bash
# libwrt.sh - 通用 DIY 脚本

cd "$OPENWRT_PATH" || exit 1

# 1. 删除冲突的 hostapd 补丁
echo "========================== 修复 hostapd 版本冲突 =========================="
PATCH_FILE="package/network/services/hostapd/patches/900-hostapd-update-muedca-params.patch"
if [ -f "$PATCH_FILE" ]; then
    rm -f "$PATCH_FILE"
    echo "已删除冲突补丁: $PATCH_FILE"
else
    find package/network/services/hostapd/ -name "*muedca*.patch" -exec rm -f {} \;
    echo "已清理所有 muedca 相关补丁"
fi
