#!/bin/bash
# libwrt-6.6-ap8220.sh - 为 qosmio openwrt-ipq 6.6 (24.10-nss) 添加 aliyun-ap8220 支持

set -e

echo "========================== libwrt-6.6-ap8220.sh 开始 =========================="
echo "当前目录: $(pwd)"

# 路径定义
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
			function = LED_FUNCTION_WLAN_5GH
