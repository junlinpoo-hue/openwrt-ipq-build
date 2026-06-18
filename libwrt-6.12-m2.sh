#!/bin/bash
# libwrt-6.12.sh - 为 qosmio openwrt-ipq 6.12 (main-nss) 添加 ZN-M2 支持

set -e

echo "========================== libwrt-6.12.sh 开始 =========================="
echo "当前目录: $(pwd)"

# 6.12 路径
IMAGE_MK="target/linux/qualcommax/image/ipq60xx.mk"
BOARD_DIR="target/linux/qualcommax/ipq60xx/base-files/etc/board.d"
UPGRADE_DIR="target/linux/qualcommax/ipq60xx/base-files/lib/upgrade"
DTS_DIR="target/linux/qualcommax/dts"
IPQWIFI_MK="package/firmware/ipq-wifi/Makefile"


echo "========================== 创建 ZN-M2 DTS =========================="
mkdir -p "$DTS_DIR"

cat > "$DTS_DIR/ipq6018-zn-m2.dts" << 'DTS_EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;

#include "ipq6018-512m.dtsi"
#include "ipq6018-ess.dtsi"
#include "ipq6018-nss.dtsi"
#include "ipq6018-cp-cpu.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
	model = "ZN M2";
	compatible = "zn,m2", "qcom,ipq6018";

	aliases {
		serial0 = &blsp1_uart3;
		led-boot = &led_power;
		led-failsafe = &led_power;
		led-running = &led_power;
		led-upgrade = &led_power;

		ethernet0 = &dp1;
		ethernet1 = &dp2;
		ethernet3 = &dp4;
		ethernet4 = &dp5;
	};

	chosen {
		stdout-path = "serial0:115200n8";
		bootargs-append = " root=/dev/ubiblock0_1";
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&tlmm 60 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};

		wps {
			label = "wps";
			gpios = <&tlmm 9 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_WPS_BUTTON>;
		};
	};

	leds {
		compatible = "gpio-leds";

		led_power: power {
			label = "blue:power";
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_POWER;
			gpios = <&tlmm 58 GPIO_ACTIVE_HIGH>;
		};

		mesh {
			label = "blue:mesh";
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_WLAN;
			gpios = <&tlmm 73 GPIO_ACTIVE_HIGH>;
		};

		lan {
			label = "blue:lan";
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_LAN;
			gpios = <&tlmm 74 GPIO_ACTIVE_HIGH>;
		};

		wan {
			label = "blue:wan";
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_WAN;
			gpios = <&tlmm 37 GPIO_ACTIVE_HIGH>;
		};
	};
};

&tlmm {
	mdio_pins: mdio-pins {
		mdc {
			pins = "gpio64";
			function = "mdc";
			drive-strength = <8>;
			bias-pull-up;
		};

		mdio {
			pins = "gpio65";
			function = "mdio";
			drive-strength = <8>;
			bias-pull-up;
		};
	};
};

&blsp1_uart3 {
	pinctrl-0 = <&serial_3_pins>;
	pinctrl-names = "default";
	status = "okay";
};

&qpic_bam {
	status = "okay";
};

&qpic_nand {
	status = "okay";

	nand@0 {
		reg = <0>;
		nand-ecc-strength = <4>;
		nand-ecc-step-size = <512>;
		nand-bus-width = <8>;

		partitions {
			compatible = "qcom,smem-part";
		};
	};
};

&qusb_phy_0 {
	status = "disabled";
};

&ssphy_0 {
	status = "disabled";
};

&usb3 {
	status = "disabled";
};

&mdio {
	status = "okay";

	pinctrl-0 = <&mdio_pins>;
	pinctrl-names = "default";
	reset-gpios = <&tlmm 75 GPIO_ACTIVE_LOW>;

	ethernet-phy-package@0 {
		compatible = "qcom,qca8075-package";
		#address-cells = <1>;
		#size-cells = <0>;
		reg = <0>;

		qca8075_0: ethernet-phy@0 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <0>;
		};

		qca8075_1: ethernet-phy@1 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <1>;
		};

		qca8075_3: ethernet-phy@3 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <3>;
		};

		qca8075_4: ethernet-phy@4 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <4>;
		};
	};
};

&switch {
	status = "okay";

	switch_lan_bmp = <(ESS_PORT1 | ESS_PORT2 | ESS_PORT4)>;
	switch_wan_bmp = <ESS_PORT5>;
	switch_mac_mode = <MAC_MODE_PSGMII>;

	qcom,port_phyinfo {
		port@1 {
			port_id = <1>;
			phy_address = <0>;
		};

		port@2 {
			port_id = <2>;
			phy_address = <1>;
		};

		port@4 {
			port_id = <4>;
			phy_address = <3>;
		};

		port@5 {
			port_id = <5>;
			phy_address = <4>;
		};
	};
};

&edma {
	status = "okay";
};

&dp1 {
	status = "okay";
	phy-handle = <&qca8075_0>;
	label = "lan3";
};

&dp2 {
	status = "okay";
	phy-handle = <&qca8075_1>;
	label = "lan2";
};

&dp4 {
	status = "okay";
	phy-handle = <&qca8075_3>;
	label = "lan1";
};

&dp5 {
	status = "okay";
	phy-handle = <&qca8075_4>;
	label = "wan";
};
DTS_EOF

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
	DEVICE_DTS := ipq6018-zn-m2
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

echo "========================== 复制 BDF 文件 =========================="
mkdir -p package/firmware/ipq-wifi/src

# 尝试多个可能的路径（适应不同执行环境）
BDF_COPIED=false
for bdf_path in \
    "board-zn_m2.ipq6018" \
    "../board-zn_m2.ipq6018" \
    "../../board-zn_m2.ipq6018" \
    "/mnt/agents/upload/board-zn_m2.ipq6018"
do
    if [ -f "$bdf_path" ]; then
        cp "$bdf_path" package/firmware/ipq-wifi/src/
        BDF_COPIED=true
        echo "已从 $bdf_path 复制 BDF"
        break
    fi
done

if [ "$BDF_COPIED" = false ]; then
    echo "错误: 找不到 board-zn_m2.ipq6018 文件"
    echo "请在脚本执行前将 BDF 文件放在以下位置之一:"
    echo "  - $(pwd)/board-zn_m2.ipq6018"
    echo "  - $(pwd)/../board-zn_m2.ipq6018"
    exit 1
fi

echo "BDF prepared:"
ls -la package/firmware/ipq-wifi/src/board-zn_m2.ipq6018

echo "========================== libwrt-6.12.sh 完成 =========================="
