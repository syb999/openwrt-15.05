# Mediatek AES Crypto Engine

This AES Engine is available in the Mediatek MT76x8 SoC.

It enables hardware crypto for AES-ECB and AES-CBC with 128/192/256 keysize.

This should be added to your device DTS or better yet to the mt76x8.dtsi:

	crypto: crypto@10004000 {
		compatible = "mediatek,mtk-aes";
		reg = <0x10004000 0x1000>;

		interrupt-parent = <&intc>;
		interrupts = <13>;

		resets = <&rstctrl 29>;
		reset-names = "cryp";
		clocks = <&clkctrl 29>;
		clock-names = "cryp";
	};

Benchmark: By default crypto-blocks <100 bytes are software only

You have chosen to measure elapsed time instead of user CPU time.

Doing aes-256-cbc for 3s on 16 size blocks: 358615 aes-256-cbc's in 3.00s

Doing aes-256-cbc for 3s on 64 size blocks: 184798 aes-256-cbc's in 3.00s

Doing aes-256-cbc for 3s on 256 size blocks: 152296 aes-256-cbc's in 3.00s

Doing aes-256-cbc for 3s on 1024 size blocks: 120724 aes-256-cbc's in 3.00s

Doing aes-256-cbc for 3s on 8192 size blocks: 36151 aes-256-cbc's in 3.00s

The 'numbers' are in 1000s of bytes per second processed.

type		16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes

aes-256-cbc	1912.61k     3942.36k    12995.93k    41207.13k    98716.33k

OpenSSL integration (OpenSSL 1.1.1)
-----------------------------------

OpenSSL 1.0.2 shipped a cryptodev engine in-tree (-DHAVE_CRYPTODEV) which used
/dev/crypto automatically.  OpenSSL 1.1.1 dropped it, so the /dev/crypto
(devcrypto) engine has to be provided and configured explicitly:

  * kmod-cryptodev (cryptodev-linux) provides /dev/crypto, and dispatches the
    session to the kernel "cbc(aes)" implementation registered by this module.
  * libopenssl-devcrypto provides the engine (loaded on demand via dlopen);
    /etc/init.d/openssl enables it from /etc/config/openssl.
  * Selecting kmod-crypto-hw-mtk-aes pulls in both of the above automatically
    (see the package Makefile).
  * files/devcrypto-mtk.cnf is installed next to the engine's own config and
    is required for acceleration to happen at all: kernel 3.18 has no
    CRYPTO_ALG_KERN_DRIVER_ONLY, so cryptodev reports "cbc-aes-mt7628" as a
    software driver and the engine (USE_SOFTDRIVERS default = 2) would reject
    the cipher.  USE_SOFTDRIVERS = 1 makes it accept and use the driver.

Verify on the device:

  dmesg | grep -i aes                      # Register: cbc(aes) / ecb(aes)
  ls -l /dev/crypto
  openssl engine -t -c -pre DUMP_INFO devcrypto
  openssl speed -evp aes-128-cbc           # compare with the engine disabled

Known-answer test (256 bytes of 'A', AES-128-CBC, zero IV, no padding):

  printf 'A%.0s' $(seq 1 256) | \
    openssl enc -aes-128-cbc -K 000102030405060708090a0b0c0d0e0f \
                -iv 00000000000000000000000000000000 -nopad | md5sum
  # 158d811670a28ea4f866f60d53e8fd3f

Disable hardware acceleration at runtime:

  uci set openssl.devcrypto.enabled='0'; /etc/init.d/openssl reload
