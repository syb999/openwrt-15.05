/*
 * ath-pcm.c -- ALSA PCM interface for the QCA Wasp based audio interface
 *
 * Copyright (c) 2012 Qualcomm Atheros, Inc.
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

#include <linux/module.h>
#include <linux/slab.h>
#include <sound/soc.h>
#include <sound/pcm.h>

#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>

#define DRV_NAME		"ath79-internal-codec"

struct ath79_priv {
	u8	lvol;
	u8	rvol;
	u8	lenabled;
	u8	renabled;
};

static struct snd_soc_dai_driver ath79_codec_dai = {
	.name = "ath79-hifi",
	.playback = {
		.stream_name = "Playback",
		.channels_min = 2,
		.channels_max = 2,
		.rates = SNDRV_PCM_RATE_22050 |
				SNDRV_PCM_RATE_32000 |
				SNDRV_PCM_RATE_44100 |
				SNDRV_PCM_RATE_48000 |
				SNDRV_PCM_RATE_88200 |
				SNDRV_PCM_RATE_96000,
		.formats = SNDRV_PCM_FMTBIT_S8 |
				SNDRV_PCM_FMTBIT_S16 |
				SNDRV_PCM_FMTBIT_S24 |
				SNDRV_PCM_FMTBIT_S32,
		},
};

static int ath79_volume_ctrl_info(struct snd_kcontrol *kcontrol,
					struct snd_ctl_elem_info *uinfo)
{
	uinfo->type = SNDRV_CTL_ELEM_TYPE_INTEGER;
	uinfo->count = 2;
	uinfo->value.integer.min = 0;
	uinfo->value.integer.max = 15;
	return 0;
}

/* If value in reg has bit4 set, it's a negative. See Datasheet for details */
#define reg_to_int(t) (t >= 0x10 ? 15 - (t & 0xf) : t + 15)
#define int_to_reg(t) (t >= 15 ? (t - 15) : (15 - t) | 0x10)

static int ath79_volume_ctrl_get(struct snd_kcontrol *kcontrol,
					struct snd_ctl_elem_value *ucontrol)
{
	struct ath79_priv *priv;
	
	priv = (struct ath79_priv *)kcontrol->private_value;

	ucontrol->value.integer.value[0] = priv->lvol;
	ucontrol->value.integer.value[1] = priv->rvol;

	return 0;
}

static int ath79_volume_ctrl_put(struct snd_kcontrol *kcontrol,
					struct snd_ctl_elem_value *ucontrol)
{
	u32 t;
	struct ath79_priv *priv;
	
	priv = (struct ath79_priv *)kcontrol->private_value;

	if ((ucontrol->value.integer.value[0] == priv->lvol) &&
	    (ucontrol->value.integer.value[1] == priv->rvol)) {
		return 0;
	}
	
	priv->lvol = ucontrol->value.integer.value[0];
	priv->rvol = ucontrol->value.integer.value[1];
	t = ath79_stereo_rr(AR934X_STEREO_REG_VOLUME);

	if (priv->lenabled) {
		t &= ~(AR934X_STEREO_VOLUME_MASK << AR934X_STEREO_VOLUME_CH0);
		t |= int_to_reg(priv->lvol) << AR934X_STEREO_VOLUME_CH0;
	}
	if (priv->renabled) {
		t &= ~(AR934X_STEREO_VOLUME_MASK << AR934X_STEREO_VOLUME_CH1);
		t |= int_to_reg(priv->rvol) << AR934X_STEREO_VOLUME_CH1;
	}
	ath79_stereo_wr(AR934X_STEREO_REG_VOLUME, t);

	return 1;
}

#define ath79_mute_ctrl_info snd_ctl_boolean_stereo_info

static int ath79_mute_ctrl_get(struct snd_kcontrol *kcontrol,
					struct snd_ctl_elem_value *ucontrol)
{
	struct ath79_priv *priv;

	priv = (struct ath79_priv *)kcontrol->private_value;

	ucontrol->value.integer.value[0] = priv->lenabled;
	ucontrol->value.integer.value[1] = priv->renabled;

	return 0;
}

static int ath79_mute_ctrl_put(struct snd_kcontrol *kcontrol,
					struct snd_ctl_elem_value *ucontrol)
{
	struct ath79_priv *priv;
	int changed;
	u32 t, vol;

	priv = (struct ath79_priv *)kcontrol->private_value;
	changed = 0;
	
	t = ath79_stereo_rr(AR934X_STEREO_REG_VOLUME);

	if (ucontrol->value.integer.value[0] != priv->lenabled) {
		priv->lenabled = ucontrol->value.integer.value[0];
		vol = int_to_reg((priv->lenabled ? 
				  priv->lvol : 0));
		t &= ~(AR934X_STEREO_VOLUME_MASK << AR934X_STEREO_VOLUME_CH0);
		t |= vol << AR934X_STEREO_VOLUME_CH0;
		changed = 1;
	}
	if (ucontrol->value.integer.value[1] != priv->renabled) {
		priv->renabled = ucontrol->value.integer.value[1];
		vol = int_to_reg((priv->renabled ?
				  priv->rvol : 0));
		t &= ~(AR934X_STEREO_VOLUME_MASK << AR934X_STEREO_VOLUME_CH1);
		t |= vol << AR934X_STEREO_VOLUME_CH1;
		changed = 1;
	}

	if (changed)
		ath79_stereo_wr(AR934X_STEREO_REG_VOLUME, t);
	
	return changed;
}

static const struct snd_kcontrol_new ath79_controls[] = {
	{ 
		.iface = SNDRV_CTL_ELEM_IFACE_MIXER,
		.name = "Master Playback Volume",
		.access = SNDRV_CTL_ELEM_ACCESS_TLV_READ |
		SNDRV_CTL_ELEM_ACCESS_READWRITE,
		.info = ath79_volume_ctrl_info,
		.get = ath79_volume_ctrl_get,
		.put = ath79_volume_ctrl_put,
	},
	{
		.iface = SNDRV_CTL_ELEM_IFACE_MIXER,
		.name = "Master Playback Switch",
		.info = ath79_mute_ctrl_info,
		.get = ath79_mute_ctrl_get,
		.put = ath79_mute_ctrl_put,
	}
};

static int ath79_codec_driver_probe (struct snd_soc_codec *codec)
{
	struct ath79_priv *priv;
	struct snd_kcontrol_new *control;
	int i;

	priv = kzalloc(sizeof(struct ath79_priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	priv->lvol = 15;
	priv->rvol = 15;
	priv->lenabled=1;
	priv->renabled=1;
	
	for (i=0; i<codec->driver->num_controls; i++) {
		control = &codec->driver->controls[i];
		control->private_value = (unsigned long) priv;
	}

	return 0;
}

static int ath79_codec_driver_remove (struct snd_soc_codec *codec)
{
	/* only free first instance as the rest should contain the same
	   address */
	if (codec->driver->num_controls > 0) 
		kfree((void *)codec->driver->controls[0].private_value);

	return 0;
}

static const struct snd_soc_codec_driver soc_codec_ath79 = {
	.probe = ath79_codec_driver_probe,
	.remove = ath79_codec_driver_remove,
	.controls = ath79_controls,
	.num_controls = 2,
};

static int ath79_codec_probe(struct platform_device *pdev)
{
	return snd_soc_register_codec(&pdev->dev, &soc_codec_ath79,
			&ath79_codec_dai, 1);
}

static int ath79_codec_remove(struct platform_device *pdev)
{
	snd_soc_unregister_codec(&pdev->dev);
	return 0;
}

static struct platform_driver ath79_codec_driver = {
	.probe		= ath79_codec_probe,
	.remove		= ath79_codec_remove,
	.driver		= {
		.name	= DRV_NAME,
		.owner	= THIS_MODULE,
	},
};

module_platform_driver(ath79_codec_driver);

MODULE_AUTHOR("Qualcomm-Atheros Inc.");
MODULE_AUTHOR("Mathieu Olivari <mathieu@qca.qualcomm.com>");
MODULE_AUTHOR("Fon Technology S.L.");
MODULE_AUTHOR("Alejandro Enrique <alejandro.enrique@fon.com>");
MODULE_DESCRIPTION("ATH79 integrated codec driver");
MODULE_LICENSE("Dual BSD/GPL");
MODULE_ALIAS("platform:" DRV_NAME);
