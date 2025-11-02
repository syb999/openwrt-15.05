/*
 * ASoC Machine Driver for ATH79 + WM8904
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/i2c.h>
#include <sound/core.h>
#include <sound/soc.h>
#include <sound/soc-dapm.h>
#include <sound/pcm_params.h>

static int ath79_wm8904_hw_params(struct snd_pcm_substream *substream,
				  struct snd_pcm_hw_params *params)
{
	struct snd_soc_pcm_runtime *rtd = substream->private_data;
	struct snd_soc_dai *codec_dai = rtd->codec_dai;
	struct snd_soc_dai *cpu_dai = rtd->cpu_dai;
	unsigned int mclk_rate;
	int ret;

	switch (params_rate(params)) {
	case 8000:
	case 16000:
	case 32000:
	case 48000:
	case 96000:
		mclk_rate = 12288000;
		break;
	case 11025:
	case 22050:
	case 44100:
		mclk_rate = 11289600;
		break;
	case 88200:
		mclk_rate = 11289600;
		break;
	default:
		mclk_rate = 12288000;
		return -EINVAL;
	}

	ret = snd_soc_dai_set_sysclk(cpu_dai, 0, mclk_rate, SND_SOC_CLOCK_OUT);
	if (ret < 0) {
		dev_err(rtd->dev, "Failed to set CPU DAI sysclk: %d\n", ret);
		return ret;
	}

	ret = snd_soc_dai_set_sysclk(codec_dai, 1, mclk_rate, SND_SOC_CLOCK_IN);
	if (ret < 0) {
		dev_err(rtd->dev, "Failed to set WM8904 clock source: %d\n", ret);
		return ret;
	}

	dev_info(rtd->dev, "CPU MCLK set to %u Hz for sample rate %u\n",
		 mclk_rate, params_rate(params));
	return 0;
}

static int ath79_wm8904_init(struct snd_soc_pcm_runtime *rtd)
{
	struct snd_soc_dai *codec_dai = rtd->codec_dai;
	int ret;

	ret = snd_soc_dai_set_fmt(codec_dai, SND_SOC_DAIFMT_I2S |
				  SND_SOC_DAIFMT_NB_NF |
				  SND_SOC_DAIFMT_CBS_CFS);
	if (ret < 0) {
		dev_err(rtd->dev, "Failed to set WM8904 DAI format: %d\n", ret);
		return ret;
	}

	dev_info(rtd->dev, "WM8904 initialized in slave mode\n");

	return 0;
}

static struct snd_soc_ops ath79_wm8904_ops = {
	.hw_params = ath79_wm8904_hw_params,
};

static struct snd_soc_dai_link ath79_wm8904_dai = {
	.name = "WM8904",
	.stream_name = "WM8904 HiFi",
	.codec_dai_name = "wm8904-hifi",
	.cpu_dai_name = "ath79-i2s",
	.platform_name = "ath79-pcm-audio",
	.codec_name = "wm8904.0-001a",
	.init = ath79_wm8904_init,
	.ops = &ath79_wm8904_ops,
};

static struct snd_soc_card ath79_wm8904_card = {
	.name = "ath79-wm8904",
	.owner = THIS_MODULE,
	.dai_link = &ath79_wm8904_dai,
	.num_links = 1,
};

static int ath79_wm8904_probe(struct platform_device *pdev)
{
	struct snd_soc_card *card = &ath79_wm8904_card;
	int ret;

	card->dev = &pdev->dev;

	ret = snd_soc_register_card(card);
	if (ret) {
		dev_err(&pdev->dev, "snd_soc_register_card failed: %d\n", ret);
		return ret;
	}

	return 0;
}

static int ath79_wm8904_remove(struct platform_device *pdev)
{
	struct snd_soc_card *card = platform_get_drvdata(pdev);

	snd_soc_unregister_card(card);
	return 0;
}

static struct platform_driver ath79_wm8904_driver = {
	.driver = {
		.name = "ath79-wm8904",
		.owner = THIS_MODULE,
	},
	.probe = ath79_wm8904_probe,
	.remove = ath79_wm8904_remove,
};

module_platform_driver(ath79_wm8904_driver);

MODULE_DESCRIPTION("ALSA SoC ATH79 WM8904");
MODULE_LICENSE("GPL");
MODULE_ALIAS("platform:ath79-wm8904");
