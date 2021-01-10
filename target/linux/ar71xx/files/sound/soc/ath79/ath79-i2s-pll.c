/*
 * ath79-i2s-pll.c -- ALSA DAI PLL management for QCA AR71xx/AR9xxx designs
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
#include <linux/clk.h>
#include <linux/spinlock.h>
#include <linux/delay.h>
#include <sound/core.h>
#include <sound/soc.h>
#include <sound/pcm_params.h>

#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>

#include "ath79-i2s.h"
#include "ath79-i2s-pll.h"

static DEFINE_SPINLOCK(ath79_pll_lock);

struct ath79_pll_mclk_config {
	unsigned int mclk;	/* MCLK frequency */
	int divint;		/* AUDIO_PLL_MODULATION		06:01 */
	int divfrac;		/* AUDIO_PLL_MODULATION		28:11 */
	int postpllpwd;		/* AUDIO_PLL_CONFIG		09:07 */
	int bypass;		/* AUDIO_PLL_CONFIG		04    */
	int extdiv;		/* AUDIO_PLL_CONFIG		14:12 */
	int refdiv;		/* AUDIO_PLL_CONFIG		03:00 */
	int ki;			/* AUDIO_DPLL2			29:26 */
	int kd;			/* AUDIO_DPLL2			25:19 */
	int shift;		/* AUDIO_DPLL3			29:23 */
};

static const struct ath79_pll_mclk_config pll_mclk_cfg_25MHz[] = {
	/* Freq		divint	divfrac		ppllpwd	bypass	extdiv	refdiv	ki	kd	shift */
	/* 		-----------------------PLL----------------------------	--------DPLL--------- */
	{ 11289600,	0x15,	0x2B442,	0x3,	0,	0x6,	0x1,	0x4,	0x3d,	0x6 },
	{ 12288000,	0x17,	0x24F76,	0x3,	0,	0x6,	0x1,	0x4,	0x3d,	0x6 },
	{ 22579200,	0x15,	0x2B442,	0x2,	0,	0x6,	0x1,	0x4,	0x3d,	0x6 },
	{ 24576000,	0x17,	0x24F76,	0x2,	0,	0x6,	0x1,	0x4,	0x3d,	0x6 },
	{ 33868800,	0x15,	0x2B442,	0x3,	0,	0x2,	0x1,	0x4,	0x3d,	0x6 },
	{ 36864000,	0x17,	0x24F76,	0x3,	0,	0x2,	0x1,	0x4,	0x3d,	0x6 },
	{ 0,		0,	0,		0,	0,	0,	0,	0,	0,	0   },
};

static const struct ath79_pll_mclk_config pll_mclk_cfg_40MHz[] = {
	{ 11289600,	0x1b,	0x6152,		0x3,	0,	0x6,	0x2,    0x4,    0x32,	0x6 },
	{ 12288000,	0x1d,	0x1F6FD,	0x3,	0,	0x6,	0x2,    0x4,    0x32,	0x6 },
	{ 22579200,	0x1b,	0x6152,		0x2,	0,	0x6,	0x2,    0x4,    0x32,	0x6 },
	{ 24576000,	0x1d,	0x1F6FD,	0x2,	0,	0x6,	0x2,    0x4,    0x32,	0x6 },
	{ 33868800,	0x1b,	0x6152,		0x3,	0,	0x2,	0x2,    0x4,    0x32,	0x6 },
	{ 36864000,	0x1d,	0x1F6FD,	0x3,	0,	0x2,	0x2,    0x4,    0x32,	0x6 },
	{ 0,		0,	0,		0,	0,	0,	0,	0,	0,	0   },
};

static void ath79_pll_set_target_div(u32 div_int, u32 div_frac)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_MOD_REG);
	t &= ~(AR934X_PLL_AUDIO_MOD_TGT_DIV_INT_MASK
		<< AR934X_PLL_AUDIO_MOD_TGT_DIV_INT_SHIFT);
	t &= ~(AR934X_PLL_AUDIO_MOD_TGT_DIV_FRAC_MASK
		<< AR934X_PLL_AUDIO_MOD_TGT_DIV_FRAC_SHIFT);
	t |= (div_int & AR934X_PLL_AUDIO_MOD_TGT_DIV_INT_MASK)
		<< AR934X_PLL_AUDIO_MOD_TGT_DIV_INT_SHIFT;
	t |= (div_frac & AR934X_PLL_AUDIO_MOD_TGT_DIV_FRAC_MASK)
		<< AR934X_PLL_AUDIO_MOD_TGT_DIV_FRAC_SHIFT;
	ath79_pll_wr(AR934X_PLL_AUDIO_MOD_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_pll_set_refdiv(u32 refdiv)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG);
	t &= ~(AR934X_PLL_AUDIO_CONFIG_REFDIV_MASK
		<< AR934X_PLL_AUDIO_CONFIG_REFDIV_SHIFT);
	t |= (refdiv & AR934X_PLL_AUDIO_CONFIG_REFDIV_MASK)
		<< AR934X_PLL_AUDIO_CONFIG_REFDIV_SHIFT;
	ath79_pll_wr(AR934X_PLL_AUDIO_CONFIG_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_pll_set_ext_div(u32 ext_div)
{	
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG);
	t &= ~(AR934X_PLL_AUDIO_CONFIG_EXT_DIV_MASK
		<< AR934X_PLL_AUDIO_CONFIG_EXT_DIV_SHIFT);
	t |= (ext_div & AR934X_PLL_AUDIO_CONFIG_EXT_DIV_MASK)
		<< AR934X_PLL_AUDIO_CONFIG_EXT_DIV_SHIFT;
	ath79_pll_wr(AR934X_PLL_AUDIO_CONFIG_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_pll_set_postpllpwd(u32 postpllpwd)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG);
	t &= ~(AR934X_PLL_AUDIO_CONFIG_POSTPLLPWD_MASK
		<< AR934X_PLL_AUDIO_CONFIG_POSTPLLPWD_SHIFT);
	t |= (postpllpwd & AR934X_PLL_AUDIO_CONFIG_POSTPLLPWD_MASK)
		<< AR934X_PLL_AUDIO_CONFIG_POSTPLLPWD_SHIFT;
	ath79_pll_wr(AR934X_PLL_AUDIO_CONFIG_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_pll_bypass(bool val)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG);
	if(val)
		t |= AR934X_PLL_AUDIO_CONFIG_BYPASS;
	else
		t &= ~(AR934X_PLL_AUDIO_CONFIG_BYPASS);
	ath79_pll_wr(AR934X_PLL_AUDIO_CONFIG_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static bool ath79_pll_ispowered(void)
{
	u32 status;

	status = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG)
			& AR934X_PLL_AUDIO_CONFIG_PLLPWD;
	return ( !status ? true : false);
}

static void ath79_audiodpll_set_gains(u32 kd, u32 ki)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	if(ath79_pll_ispowered())
		BUG();

	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_2);
	t &= ~(AR934X_DPLL_2_KD_MASK << AR934X_DPLL_2_KD_SHIFT);
	t &= ~(AR934X_DPLL_2_KI_MASK << AR934X_DPLL_2_KI_SHIFT);
	t |= (kd & AR934X_DPLL_2_KD_MASK) << AR934X_DPLL_2_KD_SHIFT;
	t |= (ki & AR934X_DPLL_2_KI_MASK) << AR934X_DPLL_2_KI_SHIFT;
	ath79_audio_dpll_wr(AR934X_DPLL_REG_2, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_audiodpll_phase_shift_set(u32 phase)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	if(ath79_pll_ispowered())
		BUG();

	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_3);
	t &= ~(AR934X_DPLL_3_PHASESH_MASK << AR934X_DPLL_3_PHASESH_SHIFT);
	t |= (phase & AR934X_DPLL_3_PHASESH_MASK)
		<< AR934X_DPLL_3_PHASESH_SHIFT;
	ath79_audio_dpll_wr(AR934X_DPLL_REG_3, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_audiodpll_range_set(void)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_2);
	t &= ~(AR934X_DPLL_2_RANGE);
	ath79_audio_dpll_wr(AR934X_DPLL_REG_2, t);
	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_2);
	t |= AR934X_DPLL_2_RANGE;
	ath79_audio_dpll_wr(AR934X_DPLL_REG_2, t);

	spin_unlock(&ath79_pll_lock);
}

static u32 ath79_audiodpll_sqsum_dvc_get(void)
{
	u32 t;

	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_3) >> AR934X_DPLL_3_SQSUM_DVC_SHIFT;
	t &= AR934X_DPLL_3_SQSUM_DVC_MASK;
	return t;
}

static void ath79_stereo_set_posedge(u32 posedge)
{
	u32 t;

	spin_lock(&ath79_stereo_lock);

	t = ath79_stereo_rr(AR934X_STEREO_REG_CONFIG);
	t &= ~(AR934X_STEREO_CONFIG_POSEDGE_MASK
		<< AR934X_STEREO_CONFIG_POSEDGE_SHIFT);
	t |= (posedge & AR934X_STEREO_CONFIG_POSEDGE_MASK)
		<< AR934X_STEREO_CONFIG_POSEDGE_SHIFT;
	ath79_stereo_wr(AR934X_STEREO_REG_CONFIG, t);

	spin_unlock(&ath79_stereo_lock);
}

static void ath79_pll_powerup(void)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG);
	t &= ~AR934X_PLL_AUDIO_CONFIG_PLLPWD;
	ath79_pll_wr(AR934X_PLL_AUDIO_CONFIG_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_pll_powerdown(void)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_pll_rr(AR934X_PLL_AUDIO_CONFIG_REG);
	t |= AR934X_PLL_AUDIO_CONFIG_PLLPWD;
	ath79_pll_wr(AR934X_PLL_AUDIO_CONFIG_REG, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_audiodpll_do_meas_set(void)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_3);
	t |= AR934X_DPLL_3_DO_MEAS;
	ath79_audio_dpll_wr(AR934X_DPLL_REG_3, t);

	spin_unlock(&ath79_pll_lock);
}

static void ath79_audiodpll_do_meas_clear(void)
{
	u32 t;

	spin_lock(&ath79_pll_lock);

	t = ath79_audio_dpll_rr(AR934X_DPLL_REG_3);
	t &= ~(AR934X_DPLL_3_DO_MEAS);
	ath79_audio_dpll_wr(AR934X_DPLL_REG_3, t);

	spin_unlock(&ath79_pll_lock);
}

static bool ath79_audiodpll_meas_done_is_set(void)
{
	u32 status;

	status = ath79_audio_dpll_rr(AR934X_DPLL_REG_4) & AR934X_DPLL_4_MEAS_DONE;
	return ( status ? true : false);
}

static void ath79_load_pll_regs(const struct ath79_pll_mclk_config *cfg)
{
	/* Set PLL regs */
	ath79_pll_set_postpllpwd(cfg->postpllpwd);
	ath79_pll_bypass(cfg->bypass);
	ath79_pll_set_ext_div(cfg->extdiv);
	ath79_pll_set_refdiv(cfg->refdiv);
	ath79_pll_set_target_div(cfg->divint, cfg->divfrac);
	/* Set DPLL regs */
	ath79_audiodpll_range_set();
	ath79_audiodpll_phase_shift_set(cfg->shift);
	ath79_audiodpll_set_gains(cfg->kd, cfg->ki);
	return;
}

static const struct ath79_pll_mclk_config *ath79_select_pll_table (void)
{
	struct clk *clk = clk_get(NULL, "ref");
	const struct ath79_pll_mclk_config *mclk_cfg = NULL;

	/* PLL settings can have 2 different values depending
	 * on the clock rate */
	switch(clk_get_rate(clk)) {
	case 25*1000*1000:
		mclk_cfg = &pll_mclk_cfg_25MHz[0];
		break;
	case 40*1000*1000:
		mclk_cfg = &pll_mclk_cfg_40MHz[0];
		break;
	default:
		printk(KERN_ERR "%s: Clk speed %lu.%03lu not supported\n", __FUNCTION__,
		       clk_get_rate(clk)/1000000,(clk_get_rate(clk)/1000) % 1000);
	}

	return mclk_cfg;
}

int ath79_find_mclk_in_pll_table (unsigned int mclk)
{
	int i = 0;
	int entry = -1;
	const struct ath79_pll_mclk_config *table;

	table = ath79_select_pll_table();

	while (table[i].mclk != 0 && entry == -1) {
		if (table[i].mclk == mclk) {
			entry = i;
		}
		i++;
	}

	return entry;
}

int ath79_audio_set_rate(unsigned int mclk, int fs)
{
	int posedge;

	/* Calculated based on specs */
	posedge = mclk/(fs * 128);

	pr_debug("Setting posedge to %d\n", posedge);
	/* Set Stereo regs */
	ath79_stereo_set_posedge(posedge);

	return 0;
}

int ath79_audio_set_clocks(unsigned int mclk)
{
	const struct ath79_pll_mclk_config *mclk_table;
	int i;

	mclk_table = ath79_select_pll_table();
	if (mclk_table == NULL) {
		return -EIO;
	}

	i = ath79_find_mclk_in_pll_table(mclk);
	if (i < 0) {
		printk(KERN_ERR "%s: MLKC freq %ud not supported\n",
			__FUNCTION__, mclk);
		return -ENOTSUPP;
	}

	pr_debug("Setting PLL registers to:\n");
	pr_debug("divint\tdivfrac\tppll\tbypass\textdiv\trefdiv\tki\tkd\tshift\n");
	pr_debug("%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", mclk_table[i].divint, 
		 mclk_table[i].divfrac, mclk_table[i].postpllpwd, mclk_table[i].bypass, mclk_table[i].extdiv, 
		 mclk_table[i].refdiv, mclk_table[i].ki, mclk_table[i].kd, mclk_table[i].shift);
	/* Loop until we converged to an acceptable value */
	do {
		ath79_audiodpll_do_meas_clear();
		ath79_pll_powerdown();
		udelay(100);

		ath79_load_pll_regs(&mclk_table[i]);

		ath79_pll_powerup();
		ath79_audiodpll_do_meas_clear();
		ath79_audiodpll_do_meas_set();

		while ( ! ath79_audiodpll_meas_done_is_set()) {
			udelay(10);
		}

	} while (ath79_audiodpll_sqsum_dvc_get() >= 0x40000);

	return 0;
}
