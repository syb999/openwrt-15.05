# CN6619 / ZM-WR2500 刷 U-Boot（u-boot_mod）

## 镜像（只有一个，三种刷法通用）

| 文件 | 大小 | md5 |
|---|---|---|
| `u-boot_mod__zmtel_zm-wr2500__131072B.bin` | 131072 字节（= u-boot 分区大小） | `ab22e73682ac8410e1091699e57d54e2` |

这是带网页恢复功能的 u-boot_mod，**已经补齐到 128 KB**（尾部 0xFF），所以：

* 编程器整片/分区写 → 能启动
* 原厂固件 `mtd write` → 能启动
* u-boot_mod 网页「刷 U-Boot」→ 能启动

> 为什么必须补 0xFF：u-boot_mod 原始产物是 125952 字节，比分区少 5120 字节，那一段
> 是 u-boot 的**环境变量区**。用 `mtd write` 时 mtd 会先擦整个分区（尾部自然变 0xFF），
> 所以 125952 也能用；但用**编程器**只写 125952 字节时，尾部残留旧 u-boot，
> u-boot 读到坏环境就起不来 —— 统一用 131072 的版本就不会有这个问题。

## 方法 A：原厂固件里用 SSH 刷

```sh
# 1) 上传 镜像 + 3.3 内核的 mtd-rw 模块
scp u-boot_mod__zmtel_zm-wr2500__131072B.bin mtd-rw-3.3.8.ko root@<设备IP>:/tmp/

# 2) 解锁只读的 u-boot 分区
insmod /tmp/mtd-rw-3.3.8.ko mtdname=u-boot i_want_a_brick=1

# 3) 写入（131072 = 分区大小，长度正好）
mtd write /tmp/u-boot_mod__zmtel_zm-wr2500__131072B.bin u-boot

# 4) 回读校验
dd if=/dev/mtd0 2>/dev/null | md5sum      # 期望 ab22e73682ac8410e1091699e57d54e2

reboot
```

OpenWrt 侧（本包编进固件的脚本）：
```sh
/usr/sbin/flash-uboot.sh /root/uboot_cn6619.bin   # 自动补齐大小 + 备份 + 回读校验
/usr/sbin/flash-uboot.sh --restore --yes          # 校验失败时写回备份(救砖)
```

## 方法 B：编程器（CH341A）

只替换 u-boot 区（保留 kernel/rootfs/art）：
```sh
cd /home/oem/888/flashrom
sudo ./flashrom -p ch341a_spi -c "W25Q128.V" \
     -l uboot.layout -i uboot -w u-boot_mod__zmtel_zm-wr2500__131072B.bin
```
`uboot.layout` 内容：`00000000:0001ffff uboot`

用 GUI（flashrom-ch341a-gui）的「写 u-boot 区」按钮更省事：它会自动
读整片 → 校验读全 → 只改前 128 KB → 写回，并把原始整片 dump 永久保存到
`~/.cache/flashrom-gui/pristine_<时间>.bin`（写失败时用它救回来）。

> 整片刷（新片/救砖）必须写**完整 16 MB 镜像**，不能只写“0xFF + u-boot”。

## 方法 C：u-boot_mod 网页里刷

1. **按住 reset ≥3 秒再上电** → 串口打印 `HTTP server is starting for firmware update...`，
   浏览器打开 `192.168.1.1`；
2. 首页有 **刷固件 / 刷 U-Boot / 刷 ART** 三个选项；
3. 选 **刷 U-Boot**，上传 `u-boot_mod__zmtel_zm-wr2500__131072B.bin`；
4. 页面显示写入进度，完成后设备自动重启。

## 刷完后

* 正常上电：3 秒 bootdelay（TTL 按键可打断进控制台），随后启动系统；
* 按住 reset ≥3 秒上电：进入网页恢复模式（192.168.1.1）。

## 重编

```sh
make package/voip/cn6619-uboot/clean
make package/voip/cn6619-uboot/compile V=s      # 成品拷到 $(TOPDIR)/bin/
```
若产物小于 131072 字节，先补 0xFF 到 131072 再用于编程器刷写：
```sh
cp new.bin out.bin && dd if=/dev/zero bs=1 count=$((131072-$(wc -c < new.bin))) 2>/dev/null \
   | tr '\000' '\377' >> out.bin
```
