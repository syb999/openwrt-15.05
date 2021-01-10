/*
 * qca-ap123-tb388.c -- ALSA machine code for AP123 board ref design
 * (and relatives) using TB388
 *
 * Based on qca-db120.c by Qualcomm
 *
 * Copyright (c) 2013 Qualcomm Atheros, Inc.
 * Copyright (c) 2013 Fon Technology S.L.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <asm/delay.h>
#include <linux/types.h>
#include <sound/core.h>
#include <sound/soc.h>
#include <linux/module.h>

/* Driver include */
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>
#include "ath79-i2s.h"
#include "ath79-pcm.h"

static struct platform_device *ap123_tb388_snd_device;

static int ap123_tb388_hw_params(struct snd_pcm_substream *substream,
	struct snd_pcm_hw_params *params)
{
	struct snd_soc_pcm_runtime *rtd = substream->private_data;
	struct snd_soc_dai *cpu_dai = rtd->cpu_dai;
	unsigned int mclk = 0;
	int ret = 0;
	int fs = params_rate(params);

	switch (fs) {
	case 44100:
	case 48000:
		mclk = 256*fs;
		break;
	case 88200:
	case 96000:
		mclk = 128*fs;
		break;
	default:
		printk(KERN_ERR "Sample rate not supported %d\n", params_rate(params));
	}

	/* set the I2S master clock */
	ret = snd_soc_dai_set_pll(cpu_dai, 0, 0, 0, mclk);

	return ret;
}

static struct snd_soc_ops ap123_tb388_ops = {
	.hw_params = ap123_tb388_hw_params,
};


static struct snd_soc_dai_link ap123_tb388_dai = {
	.name = "AP123 TB388 audio",
	.stream_name = "AP123 TB388 audio",
	.cpu_dai_name = "ath79-i2s",
	.codec_dai_name = "ath79-hifi",
	.platform_name = "ath79-pcm-audio",
	.codec_name = "ath79-internal-codec",
	.ops = &ap123_tb388_ops,
};

static struct snd_soc_card snd_soc_ap123_tb388 = {
	.name = "QCA AP123 TB388",
	.long_name = "QCA AP123 - ath79-pcm/ath79-i2s/ath79-int-codec",
	.dai_link = &ap123_tb388_dai,
	.num_links = 1,
};

static int __init ap123_tb388_init(void)
{
	int ret;

	ap123_tb388_snd_device = platform_device_alloc("soc-audio", -1);
	if(!ap123_tb388_snd_device)
		return -ENOMEM;

	platform_set_drvdata(ap123_tb388_snd_device, &snd_soc_ap123_tb388);
	ret = platform_device_add(ap123_tb388_snd_device);

	if (ret) {
		platform_device_put(ap123_tb388_snd_device);
	}

	return ret;
}

static void __exit ap123_tb388_exit(void)
{
	platform_device_unregister(ap123_tb388_snd_device);
}

module_init(ap123_tb388_init);
module_exit(ap123_tb388_exit);

MODULE_AUTHOR("Fon Technology S.L.");
MODULE_AUTHOR("Alejandro Enrique <alejandro.enrique@fon.com>");
MODULE_DESCRIPTION("QCA Audio Machine module");
MODULE_LICENSE("GPL");
