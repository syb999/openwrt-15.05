# 在原厂固件里刷入 uboot-mod（CN6619 / ZM-WR2500）

## 文件

| 文件 | 说明 |
|---|---|
| `u-boot_mod__webflash__125952B__db650e60.bin` | U-Boot 镜像，125952 字节，md5 `db650e60562728285904b7f53918dabf` |
| `mtd-rw-3.3.8.ko` | 解锁只读分区的模块，**必须用这份**（vermagic `3.3.8 mod_unload MIPS32_R2 32BIT`，对应原厂 3.3 内核），md5 `f28c1c5e256cec17b3e473be6b3b27b5` |

## 步骤

```sh
# 1) 两个文件都上传到设备（原厂固件里，SSH 登录后）
scp u-boot_mod__webflash__125952B__db650e60.bin mtd-rw-3.3.8.ko root@<设备IP>:/tmp/

# 2) 解锁 u-boot 分区（原厂固件里 mtd0 是只读的）
insmod /tmp/mtd-rw-3.3.8.ko mtdname=u-boot i_want_a_brick=1

# 3) 写入
mtd write /tmp/u-boot_mod__webflash__125952B__db650e60.bin u-boot

# 4) 校验（必须与上面 md5 一致）
dd if=/dev/mtd0 bs=1 count=125952 2>/dev/null | md5sum
# 期望: db650e60562728285904b7f53918dabf

# 5) 重启
reboot
```

> ⚠️ `mtd-rw.ko` 一定要用本目录这份（3.3 内核编的）。用 3.18 内核编的会因 vermagic 不匹配而 `insmod` 失败。

## 刷完后的行为

- **按住 reset ≥3 秒上电** → 自动进网页刷机（`HTTP server is starting for firmware update...`），
  浏览器开 `192.168.1.1`，默认是导航页：刷固件 / 刷 U-Boot / 刷 ART
- 正常上电 → 3 秒 bootdelay（可用 TTL 按键打断进 U-Boot 提示符），随后正常启动系统

## 重编 U-Boot

```sh
make package/voip/cn6619-uboot/clean
make package/voip/cn6619-uboot/compile V=s      # 成品自动拷到 $(TOPDIR)/bin/
```
