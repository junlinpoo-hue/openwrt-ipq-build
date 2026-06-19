#!/bin/bash
# libwrt-6.12-m2.sh - 为 qosmio openwrt-ipq 6.12 (main-nss) 添加 ZN-M2 支持

set -e

echo "========================== libwrt-6.12-m2.sh 开始 =========================="
# 使用 GITHUB_WORKSPACE 作为根目录（云编译环境）
OPENWRT_ROOT="${GITHUB_WORKSPACE:-$(dirname $(pwd))}"
OPENWRT_PATH="$OPENWRT_ROOT/openwrt"

echo "项目根目录: $OPENWRT_ROOT"
echo "OpenWrt 源码路径: $OPENWRT_PATH"

# 6.12 路径
IMAGE_MK="$OPENWRT_PATH/target/linux/qualcommax/image/ipq60xx.mk"
BOARD_DIR="$OPENWRT_PATH/target/linux/qualcommax/ipq60xx/base-files/etc/board.d"
UPGRADE_DIR="$OPENWRT_PATH/target/linux/qualcommax/ipq60xx/base-files/lib/upgrade"
IPQWIFI_MK="$OPENWRT_PATH/package/firmware/ipq-wifi/Makefile"

echo "========================== 拷贝 DTS 文件 =========================="

# 1. 拷贝 ipq6018-common.dtsi
SRC_FILE1="$OPENWRT_ROOT/m2/ipq6018-common.dtsi"
DEST_DIR1="$OPENWRT_PATH/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DEST_FILE1="$DEST_DIR1/ipq6018-common.dtsi"

if [ -f "$SRC_FILE1" ]; then
    echo "[1/3] 拷贝 ipq6018-common.dtsi..."
    mkdir -p "$DEST_DIR1"
    cp -v "$SRC_FILE1" "$DEST_FILE1"
    echo "  完成: $DEST_FILE1"
else
    echo "[1/3] 警告: 源文件不存在: $SRC_FILE1"
fi

# 2. 拷贝 ipq6000-m2.dts
SRC_FILE2="$OPENWRT_ROOT/m2/ipq6000-m2.dts"
DEST_DIR2="$OPENWRT_PATH/target/linux/qualcommax/dts"
DEST_FILE2="$DEST_DIR2/ipq6000-m2.dts"

if [ -f "$SRC_FILE2" ]; then
    echo "[2/3] 拷贝 ipq6000-m2.dts..."
    mkdir -p "$DEST_DIR2"
    cp -v "$SRC_FILE2" "$DEST_FILE2"
    echo "  完成: $DEST_FILE2"
else
    echo "[2/3] 警告: 源文件不存在: $SRC_FILE2"
fi

# 3. 拷贝 ipq6000-cmiot.dtsi
SRC_FILE3="$OPENWRT_ROOT/m2/ipq6000-cmiot.dtsi"
DEST_FILE3="$DEST_DIR2/ipq6000-cmiot.dtsi"

if [ -f "$SRC_FILE3" ]; then
    echo "[3/3] 拷贝 ipq6000-cmiot.dtsi..."
    cp -v "$SRC_FILE3" "$DEST_FILE3"
    echo "  完成: $DEST_FILE3"
else
    echo "[3/3] 警告: 源文件不存在: $SRC_FILE3"
fi

echo ""
echo "验证目标文件:"
for f in "$DEST_FILE1" "$DEST_FILE2" "$DEST_FILE3"; do
    if [ -f "$f" ]; then
        echo "  ✓ $(basename $f)"
    else
        echo "  ✗ $(basename $f) - 不存在"
    fi
done
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

# 检查 zyxel_scr50axe 行是否已有反斜杠
if grep -q "zyxel_scr50axe \\\\$" "$IPQWIFI_MK"; then
    # 已有反斜杠，直接添加 zn_m2
    if ! grep -q "zn_m2" "$IPQWIFI_MK"; then
        sed -i '/^[[:space:]]*zyxel_scr50axe \\$/a\    zn_m2' "$IPQWIFI_MK"
        echo "已添加 zn_m2 到 ALLWIFIBOARDS"
    fi
else
    # 没有反斜杠，先添加再插入
    sed -i 's/^[[:space:]]*zyxel_scr50axe[[:space:]]*$/    zyxel_scr50axe \\/' "$IPQWIFI_MK"
    sed -i '/^[[:space:]]*zyxel_scr50axe \\$/a\    zn_m2' "$IPQWIFI_MK"
    echo "已添加 zn_m2 到 ALLWIFIBOARDS"
fi

# 添加 generate 调用（如果不存在）
if ! grep -q "generate-ipq-wifi-package,zn_m2" "$IPQWIFI_MK"; then
    sed -i '/$(eval $(call generate-ipq-wifi-package,zyxel_scr50axe,Zyxel SCR50AXE))/a\
$(eval $(call generate-ipq-wifi-package,zn_m2,ZN M2))' "$IPQWIFI_MK"
    echo "已添加 generate-ipq-wifi-package for zn_m2"
else
    echo "generate-ipq-wifi-package for zn_m2 已存在"
fi

echo "========================== libwrt-6.12-m2.sh 完成 =========================="
