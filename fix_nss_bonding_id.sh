#!/bin/bash
set -e

PATCH_FILE="target/linux/qualcommax/patches-6.6/0600-3-qca-nss-ecm-support-net-bonding.patch"

if [ ! -f "$PATCH_FILE" ]; then
    echo "❌ 找不到 patch 文件: $PATCH_FILE"
    exit 1
fi

echo "=============================="
echo " NSS ECM bonding ID 修复脚本"
echo "=============================="

echo "[1/3] 备份原 patch..."
cp "$PATCH_FILE" "${PATCH_FILE}.bak"

echo "[2/3] 修改 bonding ID 分配方式..."

# ----------------------------
# 方案1：ifindex（推荐默认）
# ----------------------------

# 删除 bond_id_mask 定义
sed -i '/bond_id_mask/d' "$PATCH_FILE"

# 删除 set_bit / clear_bit / ffz 相关逻辑
sed -i '/ffz(bond_id_mask)/d' "$PATCH_FILE"
sed -i '/set_bit.*bond_id_mask/d' "$PATCH_FILE"
sed -i '/clear_bit.*bond_id_mask/d' "$PATCH_FILE"

# 替换 bond_create 中 ID 分配逻辑
sed -i '/bond->id = ~0U/,+10c\
\t/* NSS ECM bonding ID fix: use ifindex (6.6 safe) */\
\tbond->id = bond->dev->ifindex;\
' "$PATCH_FILE"

echo "[3/3] 清理完成"

echo "=============================="
echo " 修复完成（ifindex 模式）"
echo "=============================="

echo "建议检查："
echo "  grep -n bond->id $PATCH_FILE"
