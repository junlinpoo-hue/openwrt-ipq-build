#!/bin/bash
# libwrt-6.12-m2.sh - 为 qosmio openwrt-ipq 6.12 (main-nss) 添加 ZN-M2 支持

set -e

echo "========================== libwrt-6.12-m2.sh 开始 =========================="
echo "当前目录: $(pwd)"

# 6.12 路径
IMAGE_MK="target/linux/qualcommax/image/ipq60xx.mk"
BOARD_DIR="target/linux/qualcommax/ipq60xx/base-files/etc/board.d"
UPGRADE_DIR="target/linux/qualcommax/ipq60xx/base-files/lib/upgrade"
DTS_DIR="target/linux/qualcommax/dts"
IPQWIFI_MK="package/firmware/ipq-wifi/Makefile"


echo "========================== 创建 ZN-M2 DTS =========================="
mkdir -p "$DTS_DIR"



echo "========================== 创建 DTS 编译替身（防撞车） =========================="
# 1. 满足你显式指定的正确名称（规范化）
cp "$DTS_DIR/ipq6018-zn-m2.dts" "$DTS_DIR/ipq6000-zn-m2.dts"
# 2. 补齐上游源码里写错/缺失的 m2 文件，彻底解决 cc1: fatal error 报错
cp "$DTS_DIR/ipq6018-zn-m2.dts" "$DTS_DIR/ipq6000-m2.dts"

echo "========================== 修改 ipq60xx.mk =========================="
if [ -f "$IMAGE_MK" ] && ! grep -q "define Device/zn_m2" "$IMAGE_MK" 2>/dev/null; then
    cat >> "$IMAGE_MK" << 'MK_EOF'

define Device/zn_m2
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := ZN
	DEVICE_MODEL := M2
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	SOC := ipq6000
	DEVICE_DTS_CONFIG := config@cp03-c1
	DEVICE_PACKAGES := ipq-wifi-zn_m2
endef
TARGET_DEVICES += zn_m2
MK_EOF
    echo "已添加 zn_m2 到 $IMAGE_MK"
else
    echo "zn_m2 已存在或文件不存在，跳过"
fi

echo "========================== 修改 02_network =========================="
if [ -f "$BOARD_DIR/02_network" ] && ! grep -q "zn,m2" "$BOARD_DIR/02_network"; then
    sed -i '/jdcloud,re-cs-07|\\/i\	zn,m2|\\' "$BOARD_DIR/02_network"
    echo "已添加 zn,m2 到 02_network"
else
    echo "02_network 已存在或文件不存在，跳过"
fi

echo "========================== 修改 01_leds =========================="
if [ -f "$BOARD_DIR/01_leds" ] && ! grep -q "zn,m2)" "$BOARD_DIR/01_leds"; then
    # 在 esac 前插入 zn,m2 配置
    sed -i '/^esac$/i\
zn,m2)\
	ucidef_set_led_netdev "wan" "WAN" "blue:wan" "wan"\
	ucidef_set_led_netdev "lan" "LAN" "blue:lan" "br-lan"\
	;;\
' "$BOARD_DIR/01_leds"
    echo "已添加 zn,m2 到 01_leds"
else
    echo "01_leds 已存在或文件不存在，跳过"
fi

echo "========================== 修改 platform.sh =========================="
if [ -f "$UPGRADE_DIR/platform.sh" ] && ! grep -q "zn,m2" "$UPGRADE_DIR/platform.sh"; then
    sed -i '/netgear,wax214)/i\	zn,m2|\\' "$UPGRADE_DIR/platform.sh"
    echo "已添加 zn,m2 到 platform.sh"
else
    echo "platform.sh 已存在或文件不存在，跳过"
fi

echo "========================== 修改 Makefile  =========================="
# 1. 在 ALLWIFIBOARDS 列表中，zyxel_scr50axe 行后面添加 zn_m2 
sed -i 's/^[[:space:]]*zyxel_scr50axe[[:space:]]*$/    zyxel_scr50axe \\/' "$IPQWIFI_MK"
sed -i '/^[[:space:]]*zyxel_scr50axe \\$/a\    zn_m2' "$IPQWIFI_MK"

# 2. 在 zyxel_scr50axe 的 generate 调用后面添加 zn_m2 的 generate 调用
sed -i '/$(eval $(call generate-ipq-wifi-package,zyxel_scr50axe,Zyxel SCR50AXE))/a\
$(eval $(call generate-ipq-wifi-package,zn_m2,ZN M2))' "$IPQWIFI_MK"

echo "ZN-M2 added to ipq-wifi Makefile"

echo "========================== libwrt-6.12-m2.sh 完成 =========================="
