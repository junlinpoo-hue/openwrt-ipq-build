
#!/bin/bash
# libwrt-6.6-ap8220.sh - 为 qosmio openwrt-ipq 6.6 (24.10-nss) 添加 aliyun-ap8220 支持

set -e

echo "========================== libwrt-6.6-ap8220.sh 开始 =========================="
echo "当前目录: $(pwd)"

# 6.12 路径
IMAGE_MK="target/linux/qualcommax/image/ipq807x.mk"
BOARD_DIR="target/linux/qualcommax/ipq807x/base-files/etc/board.d"
UPGRADE_DIR="target/linux/qualcommax/ipq807x/base-files/lib/upgrade"
DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
IPQWIFI_MK="package/firmware/ipq-wifi/Makefile"


echo "========================== 创建 aliyun_ap8220 DTS =========================="
mkdir -p "$DTS_DIR"

cat > "$DTS_DIR/ipq8071-ap8220.dts" << 'DTS_EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;

#include "ipq8074.dtsi"
#include "ipq8074-ac-cpu.dtsi"
#include "ipq8074-ess.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
	model = "Aliyun AP8220";
	compatible = "aliyun,ap8220", "qcom,ipq8074";

	aliases {
		serial0 = &blsp1_uart5;
		led-boot = &led_power;
		led-failsafe = &led_power;
		led-running = &led_power;
		led-upgrade = &led_power;
	};

	chosen {
		stdout-path = "serial0:115200n8";
		bootargs-append = " root=/dev/ubiblock0_1";
	};

	keys {
		compatible = "gpio-keys";
		pinctrl-0 = <&button_pins>;
		pinctrl-names = "default";

		reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&tlmm 66 GPIO_ACTIVE_LOW>;
		};
	};

	leds {
		compatible = "gpio-leds";

		led_power: power {
			color = <LED_COLOR_ID_GREEN>;
			function = LED_FUNCTION_POWER;
			gpios = <&tlmm 46 GPIO_ACTIVE_HIGH>;
		};

		wlan2g {
			color = <LED_COLOR_ID_GREEN>;
			function = LED_FUNCTION_WLAN_2GHZ;
			gpios = <&tlmm 47 GPIO_ACTIVE_HIGH>;
			linux,default-trigger = "phy1radio";
		};

		wlan5g {
			color = <LED_COLOR_ID_GREEN>;
			function = LED_FUNCTION_WLAN_5GHZ;
			gpios = <&tlmm 48 GPIO_ACTIVE_HIGH>;
			linux,default-trigger = "phy0radio";
		};

		bluetooth {
			color = <LED_COLOR_ID_GREEN>;
			function = LED_FUNCTION_BLUETOOTH;
			gpios = <&tlmm 50 GPIO_ACTIVE_HIGH>;
		};
	};

	gpio-export {
		compatible = "gpio-export";

		ble-power {
			gpio-export,name = "ble_power";
			gpio-export,output = <1>;
			gpios = <&tlmm 54 GPIO_ACTIVE_HIGH>;
		};
	};
};

&tlmm {
	mdio_pins: mdio-pins {
		mdc {
			pins = "gpio68";
			function = "mdc";
			drive-strength = <8>;
			bias-pull-up;
		};

		mdio {
			pins = "gpio69";
			function = "mdio";
			drive-strength = <8>;
			bias-pull-up;
		};
	};

	button_pins: button-pins {
		mux {
			pins = "gpio66";
			function = "gpio";
			drive-strength = <8>;
			bias-pull-up;
		};
	};
};

&blsp1_spi1 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <50000000>;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "0:sbl1";
				reg = <0x0 0x50000>;
				read-only;
			};

			partition@50000 {
				label = "0:mibib";
				reg = <0x50000 0x10000>;
				read-only;
			};

			partition@60000 {
				label = "0:qsee";
				reg = <0x60000 0x180000>;
				read-only;
			};

			partition@1e0000 {
				label = "0:devcfg";
				reg = <0x1e0000 0x10000>;
				read-only;
			};

			partition@1f0000 {
				label = "0:apdp";
				reg = <0x1f0000 0x10000>;
				read-only;
			};

			partition@200000 {
				label = "0:rpm";
				reg = <0x200000 0x40000>;
				read-only;
			};

			partition@240000 {
				label = "0:cdt";
				reg = <0x240000 0x10000>;
				read-only;
			};

			partition@250000 {
				label = "0:appsblenv";
				reg = <0x250000 0x10000>;
			};

			partition@260000 {
				label = "0:appsbl";
				reg = <0x260000 0xa0000>;
				read-only;
			};

			partition@300000 {
				label = "0:art";
				reg = <0x300000 0x40000>;
				read-only;
			};

			partition@340000 {
				label = "0:ethphyfw";
				reg = <0x340000 0x80000>;
				read-only;
			};

			partition@3c0000 {
				label = "product_info";
				reg = <0x3c0000 0x10000>;
				read-only;
			};

			partition@3d0000 {
				label = "mtdoops";
				reg = <0x3d0000 0x20000>;
			};

			partition@3f0000 {
				label = "priv_data1";
				reg = <0x3f0000 0x10000>;
				read-only;
			};
		};
	};
};

&blsp1_uart5 {
	status = "okay";
};

&cryptobam {
	status = "okay";
};

&crypto {
	status = "okay";
};

&prng {
	status = "okay";
};

&qpic_bam {
	status = "okay";
};

&qusb_phy_0 {
	status = "okay";
};

&ssphy_0 {
	status = "okay";
};

&usb_0 {
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
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "rootfs1";
				reg = <0x0000000 0x3000000>;
			};

			partition@3000000 {
				label = "rootfs2";
				reg = <0x3000000 0x3000000>;
			};

			partition@6000000 {
				label = "usrdata";
				reg = <0x6000000 0x2000000>;
			};
		};
	};
};

&mdio {
	status = "okay";

	pinctrl-0 = <&mdio_pins>;
	pinctrl-names = "default";

	qca8081_24: ethernet-phy@24 {
		compatible = "ethernet-phy-id004d.d101";
		reg = <24>;
		reset-deassert-us = <10000>;
		reset-gpios = <&tlmm 33 GPIO_ACTIVE_LOW>;
	};

	qca8081_28: ethernet-phy@28 {
		compatible = "ethernet-phy-id004d.d101";
		reg = <28>;
		reset-deassert-us = <10000>;
		reset-gpios = <&tlmm 44 GPIO_ACTIVE_LOW>;
	};
};

&switch {
	status = "okay";

	switch_lan_bmp = <ESS_PORT5>;
	switch_wan_bmp = <ESS_PORT6>;
	switch_mac_mode1 = <MAC_MODE_SGMII_PLUS>;
	switch_mac_mode2 = <MAC_MODE_SGMII_PLUS>;

	qcom,port_phyinfo {
		port@5 {
			port_id = <5>;
			phy_address = <24>;
			port_mac_sel = "QGMAC_PORT";
		};
		port@6 {
			port_id = <6>;
			phy_address = <28>;
			port_mac_sel = "QGMAC_PORT";
		};
	};
};

&edma {
	status = "okay";
};

&dp5 {
	status = "okay";
	phy-mode = "sgmii";
	phy-handle = <&qca8081_24>;
	label = "wan";
};

&dp6 {
	status = "okay";
	phy-handle = <&qca8081_28>;
	label = "lan";
};

&wifi {
	status = "okay";

	qcom,ath11k-calibration-variant = "Aliyun-AP8220";
};
DTS_EOF


echo "========================== 修改 ipq807x.mk =========================="
if [ -f "$IMAGE_MK" ] && ! grep -q "define Device/aliyun_ap8220" "$IMAGE_MK" 2>/dev/null; then
    cat >> "$IMAGE_MK" << 'MK_EOF'

define Device/aliyun_ap8220
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := Aliyun
	DEVICE_MODEL := AP8220
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	DEVICE_DTS_CONFIG := config@ac02
	SOC := ipq8071
	DEVICE_PACKAGES := ipq-wifi-aliyun_ap8220
endef
TARGET_DEVICES += aliyun_ap8220
MK_EOF
    echo "已添加 aliyun_ap8220 到 $IMAGE_MK"
else
    echo "aliyun_ap8220 已存在或文件不存在，跳过"
fi

echo "========================== 修改 02_network =========================="
if [ -f "$BOARD_DIR/02_network" ] && ! grep -q "aliyun,ap8220" "$BOARD_DIR/02_network"; then
    sed -i '/yuncore,ax880|\\/i\	aliyun,ap8220|\\' "$BOARD_DIR/02_network"
    echo "已添加 aliyun,ap8220 到 02_network"
else
    echo "02_network 已存在或文件不存在，跳过"
fi

echo "========================== 修改 01_leds =========================="
LEDS_FILE="$BOARD_DIR/01_leds"

if [ -f "$LEDS_FILE" ]; then
    if grep -q "zn,m2)" "$LEDS_FILE"; then
        echo "ZN-M2 LED config already exists"
    else
        # 在 esac 前插入
        sed -i '/^esac$/i\
\	aliyun,ap8220)\
\	\ucidef_set_led_netdev "wlan2g" "WLAN2G" "2g:status" "phy1-ap0"\
\	\ucidef_set_led_netdev "wlan5g" "WLAN5G" "5g:status" "phy0-ap0"\
\	\t;;\
' "$LEDS_FILE"
        echo "ZN-M2 LED config added"
    fi
else
    echo "ERROR: $LEDS_FILE not found"
fi

echo "========================== 修改 platform.sh =========================="
if [ -f "$UPGRADE_DIR/platform.sh" ] && ! grep -q "aliyun,ap8220" "$UPGRADE_DIR/platform.sh"; then
    sed -i '/arcadyan,aw1000|\\/i\
	  aliyun,ap8220)\
		  CI_UBIPART="rootfs"\
		  nand_do_upgrade "$1"\
		  ;;' "$UPGRADE_DIR/platform.sh"
    echo "已添加 zn,m2 到 platform.sh"
else
    echo "platform.sh 已存在或文件不存在，跳过"
fi

echo "========================== 修改 Makefile  =========================="

# 1. 先给最后一项 zyxel_nbg7815 加上反斜杠（用 Tab 缩进）
sed -i 's/^[[:space:]]*zyxel_nbg7815[[:space:]]*$/\tzyxel_nbg7815 \\/' "$IPQWIFI_MK"

# 2. 在 zyxel_nbg7815 行后面添加 aliyun_ap8220（用 Tab 缩进）
sed -i '/^[[:space:]]*zyxel_nbg7815 \\$/a\\taliyun_ap8220' "$IPQWIFI_MK"

# 3. 在 generate 调用后面添加 aliyun_ap8220 的 generate
sed -i '/$(eval $(call generate-ipq-wifi-package,zyxel_nbg7815,Zyxel NBG7815))/a\
$(eval $(eval $(call generate-ipq-wifi-package,aliyun_ap8220,Aliyun AP8220))' "$IPQWIFI_MK"

echo " aliyun_ap8220 added to ipq-wifi Makefile"

echo "========================== libwrt-6.12.sh 完成 =========================="
