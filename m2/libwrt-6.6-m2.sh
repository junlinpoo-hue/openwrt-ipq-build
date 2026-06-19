#!/bin/bash
# libwrt-6.6-m2.sh - 为 qosmio openwrt-ipq 6.6 (24.10-nss) 添加 ZN-M2 支持

set -e

echo "========================== libwrt-6.6-m2.sh 开始 =========================="
# 使用 GITHUB_WORKSPACE 作为根目录（云编译环境）
OPENWRT_ROOT="${GITHUB_WORKSPACE:-$(dirname $(pwd))}"
OPENWRT_PATH="$OPENWRT_ROOT/openwrt"

echo "项目根目录: $OPENWRT_ROOT"
echo "OpenWrt 源码路径: $OPENWRT_PATH"

# 6.6 路径
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
NETWORK_FILE="$BOARD_DIR/02_network"

if [ -f "$NETWORK_FILE" ]; then
    if grep -q "zn,m2)" "$NETWORK_FILE"; then
        echo "ZN-M2 network config already exists"
    else
        # 在 yuncore,fap650) 前插入
        sed -i '/yuncore,fap650)/i\
\	zn,m2)\
\	\tucidef_set_interfaces_lan_wan "lan1 lan2 lan3" "wan"\
\	\t;;\
' "$NETWORK_FILE"
        echo "ZN-M2 network config added"
    fi
else
    echo "ERROR: $NETWORK_FILE not found"
fi

echo "========================== 修改 01_leds =========================="
LEDS_FILE="$BOARD_DIR/01_leds"

if [ -f "$LEDS_FILE" ]; then
    if grep -q "zn,m2)" "$LEDS_FILE"; then
        echo "ZN-M2 LED config already exists"
    else
        # 在 esac 前插入
        sed -i '/^esac$/i\
\	zn,m2)\
\	\tucidef_set_led_netdev "wan" "WAN" "blue:wan" "wan"\
\	\tucidef_set_led_netdev "wlan2g" "WLAN2G" "blue:wlan2g" "phy1-ap0"\
\	\tucidef_set_led_netdev "wlan5g" "WLAN5G" "blue:wlan5g" "phy0-ap0"\
\	\tucidef_set_led_netdev "lan" "LAN" "blue:lan" "br-lan"\
\	\t;;\
' "$LEDS_FILE"
        echo "ZN-M2 LED config added"
    fi
else
    echo "ERROR: $LEDS_FILE not found"
fi

echo "========================== 修改 platform.sh =========================="
if [ -f "$UPGRADE_DIR/platform.sh" ] && ! grep -q "zn,m2" "$UPGRADE_DIR/platform.sh"; then
    sed -i '/netgear,wax214)/i\	zn,m2|\\' "$UPGRADE_DIR/platform.sh"
    echo "已添加 zn,m2 到 platform.sh"
else
    echo "platform.sh 已存在或文件不存在，跳过"
fi

echo "========================== 修改 Makefile  =========================="
IPQWIFI_MK="package/firmware/ipq-wifi/Makefile"

# 1. 先给最后一项 zyxel_nbg7815 加上反斜杠（用 Tab 缩进）
sed -i 's/^[[:space:]]*zyxel_nbg7815[[:space:]]*$/\tzyxel_nbg7815 \\/' "$IPQWIFI_MK"

# 2. 在 zyxel_nbg7815 行后面添加 zn_m2（用 Tab 缩进）
sed -i '/^[[:space:]]*zyxel_nbg7815 \\$/a\\tzn_m2' "$IPQWIFI_MK"

# 3. 在 generate 调用后面添加 zn_m2 的 generate
sed -i '/$(eval $(call generate-ipq-wifi-package,zyxel_nbg7815,Zyxel NBG7815))/a\
$(eval $(call generate-ipq-wifi-package,zn_m2,ZN M2))' "$IPQWIFI_MK"

echo "ZN-M2 added to ipq-wifi Makefile"

echo "========================== libwrt-6.6-m2.sh 完成 =========================="
