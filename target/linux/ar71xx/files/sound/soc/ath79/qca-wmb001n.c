/*
 * sutured and not tested!!!          
 * qca-wmb001n.c -- ALSA machine code for WMB001N board ref design (and relatives)
 *
 * Copyright (c) 2013 Qualcomm Atheros, Inc.
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
#include "../codecs/wm8904.h"

static struct platform_device *wmb001n_snd_device;

static int wmb001n_hw_params(struct snd_pcm_substream *ss,
	struct snd_pcm_hw_params *params)
{
	struct snd_soc_pcm_runtime *rtd = ss->private_data;
	struct snd_soc_dai *codec_dai = rtd->codec_dai;
	int ret;

	ret = snd_soc_dai_set_pll(codec_dai, WM8904_FLL_MCLK, WM8904_FLL_MCLK,
		32768, params_rate(params) * 256);
	if (ret < 0) {
		pr_err("%s - failed to set wm8904 codec PLL.", __func__);
		return ret;
	}

	/*
	 * As here wm8904 use FLL output as its system clock
	 * so calling set_sysclk won't care freq parameter
	 * then we pass 0
	 */
	ret = snd_soc_dai_set_sysclk(codec_dai, WM8904_CLK_FLL,
			0, SND_SOC_CLOCK_IN);
	if (ret < 0) {
		pr_err("%s -failed to set wm8904 SYSCLK\n", __func__);
		return ret;
	}

	return 0;
}

static struct snd_soc_ops wmb001n_dai_ops = {
	.hw_params = wmb001n_hw_params,
};

static struct snd_soc_dai_link wmb001n_dai = {
	.name = "WM8904",
	.stream_name = "WM8904 PCM",
	.cpu_dai_name = "ath79-i2s",
	.codec_dai_name = "wm8904-hifi",
	.platform_name = "ath79-pcm-audio",
	.codec_name = "spi0.1",
	/* use ops to check startup state */
	.ops = &wmb001n_dai_ops,
};

static struct snd_soc_card snd_soc_wmb001n = {
	.name = "QCA WMB001N",
	.long_name = "WMB001N - ath79-pcm/ath79-i2s/wm8904",
	.dai_link = &wmb001n_dai,
	.num_links = 1,
};

static int __init wmb001n_init(void)
{
	int ret;

	wmb001n_snd_device = platform_device_alloc("soc-audio", -1);
	if(!wmb001n_snd_device)
		return -ENOMEM;

	platform_set_drvdata(wmb001n_snd_device, &snd_soc_wmb001n);
	ret = platform_device_add(wmb001n_snd_device);

	if (ret) {
		platform_device_put(wmb001n_snd_device);
	}

	return ret;
}

static void __exit wmb001n_exit(void)
{
	platform_device_unregister(wmb001n_snd_device);
}

module_init(wmb001n_init);
module_exit(wmb001n_exit);

MODULE_AUTHOR("Qualcomm-Atheros Inc.");
MODULE_AUTHOR("Mathieu Olivari <mathieu@qca.qualcomm.com>");
MODULE_DESCRIPTION("QCA Audio Machine module");
MODULE_LICENSE("Dual BSD/GPL");
