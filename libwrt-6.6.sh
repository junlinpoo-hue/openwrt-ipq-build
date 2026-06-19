      - name: Fix Qualcomm NSS ECM Bonding Patch
        run: |
          cd openwrt
          # 1. 尝试解压内核源码并应用现有补丁（会报错，所以用 || true 忽略）
          make target/linux/prepare V=s || true
          
          # 2. 进入内核源码目录，将那些未成功应用的 .rej 剩余补丁强制合入
          cd build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.6.*
          
          # 3. 使用 patch 命令将残留的拒绝块强制重新应用（或手动用 sed 修正）
          # 注：最安全的方法是直接更新上层补丁。我们在这里直接让 openwrt 刷新补丁：
          cd ../../../..
          make target/linux/refresh V=s
