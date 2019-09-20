#ifndef __ACTION_H_
#define __ACTION_H_

#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include "plat.h"

#define DEBUG LOG_DEBUG

#define debug(level, fmt, ...) do { \
	if (level <= LOG_ERR) { \
		printf(fmt, ## __VA_ARGS__); \
	} else if (level <= DEBUG) {	\
		syslog(level, "led-button " fmt, ## __VA_ARGS__); \
	} } while (0)

/*
* @LED_ACTION_NONE:not used
* @LED_ACTION_1:   set all leds default on
* @LED_ACTION_2:   set all leds timer:delay_on:delay_off,each  interval is 500ms
* @LED_ACTION_3:   set all leds none
* @LED_ACTION_4:   Reserved
* @LED_ACTION_5:   Reserved
* @LED_ACTION_6:   Reserved
* @LED_ACTION_7:   Reserved
* @LED_ACTION_8:   Reserved
*
* @LED_ACTION_9:   p10m >> set p10h eth led flashes once 500ms
* @LED_ACTION_10:  p10m >> Reserved
* @LED_ACTION_11:  p10m >> Reserved
* @LED_ACTION_12:  p10m >> Reserved
* @LED_ACTION_13:  p10m >> Reserved
* @LED_ACTION_14:  p10m >> Reserved
* @LED_ACTION_15:  p10m >> Reserved
* @LED_ACTION_16:  p10m >> Reserved
*
* @LED_ACTION_17:  repeater >> set repeater-red on && repeater-green off
* @LED_ACTION_18:  repeater >> set repeater-red off && repeater-green on
* @LED_ACTION_19:  repeater >> set wifi-status to timer:800:800
* @LED_ACTION_20:  repeater >> set wifi-status to default-on
* @LED_ACTION_21:  repeater >> set repeater leds(wifi-status, repeater-red) flashes once 300ms
* @LED_ACTION_22:  repeater >> Reserved
* @LED_ACTION_23:  repeater >> Reserved
* @LED_ACTION_24:  repeater >> Reserved
*
* @LED_ACTION_25:  86v >> Flashes four times after the startup is completed, each interval is 500ms
* @LED_ACTION_26:  86v >> set 86v led light flashes once every 500ms
* @LED_ACTION_27:  86v >> led light flashes once every 1s
* @LED_ACTION_28:  86v >> set 86v led light flashes once every 2s
* @LED_ACTION_29:  86v >> Reserved
* @LED_ACTION_30:  86v >> Reserved
* @LED_ACTION_31:  86v >> Reserved
* @LED_ACTION_32:  86v >> Reserved
*
* @LED_ACTION_33:  p10h >> set p10h eth led flashes once 500ms
* @LED_ACTION_34:  p10h >> Reserved
* @LED_ACTION_35:  p10h >> Reserved
* @LED_ACTION_36:  p10h >> Reserved
* @LED_ACTION_37:  p10h >> Reserved
* @LED_ACTION_38:  p10h >> Reserved
* @LED_ACTION_39:  p10h >> Reserved
* @LED_ACTION_40:  p10h >> Reserved
*
* @LED_ACTION_41:  evb_v5 >> set evb_v5 eth led flashes once 500ms
* @LED_ACTION_42:  evb_v5 >> Reserved
* @LED_ACTION_43:  evb_v5 >> Reserved
* @LED_ACTION_44:  evb_v5 >> Reserved
* @LED_ACTION_45:  evb_v5 >> Reserved
* @LED_ACTION_46:  evb_v5 >> Reserved
* @LED_ACTION_47:  evb_v5 >> Reserved
* @LED_ACTION_48:  evb_v5 >> Reserved
*
* @LED_ACTION_49:  repeater >> set repeater wifi-status to timer:100:100
* @LED_ACTION_50:  repeater >> set repeater wifi-status to default-on
* @LED_ACTION_51:  repeater >> set repeater repeater-signal to timer:800:800
* @LED_ACTION_52:  repeater >> set repeater repeater-signal to default-on
* @LED_ACTION_53:  repeater >> set repeater leds(repeater-siignal, wifi-status, power) flashes once 300ms
* @LED_ACTION_54:  repeater >> Reserved
* @LED_ACTION_55:  repeater >> Reserved
* @LED_ACTION_56:  repeater >> Reserved
* @LED_ACTION_MAX: not used
* */
enum {
	LED_ACTION_NONE,
	LED_ACTION_1,  LED_ACTION_2,  LED_ACTION_3,  LED_ACTION_4,
	LED_ACTION_5,  LED_ACTION_6,  LED_ACTION_7,  LED_ACTION_8,
	LED_ACTION_9,  LED_ACTION_10, LED_ACTION_11, LED_ACTION_12,
	LED_ACTION_13, LED_ACTION_14, LED_ACTION_15, LED_ACTION_16,
	LED_ACTION_17, LED_ACTION_18, LED_ACTION_19, LED_ACTION_20,
	LED_ACTION_21, LED_ACTION_22, LED_ACTION_23, LED_ACTION_24,
	LED_ACTION_25, LED_ACTION_26, LED_ACTION_27, LED_ACTION_28,
	LED_ACTION_29, LED_ACTION_30, LED_ACTION_31, LED_ACTION_32,
	LED_ACTION_33, LED_ACTION_34, LED_ACTION_35, LED_ACTION_36,
	LED_ACTION_37, LED_ACTION_38, LED_ACTION_39, LED_ACTION_40,
	LED_ACTION_41, LED_ACTION_42, LED_ACTION_43, LED_ACTION_44,
	LED_ACTION_45, LED_ACTION_46, LED_ACTION_47, LED_ACTION_48,
	LED_ACTION_49, LED_ACTION_50, LED_ACTION_51, LED_ACTION_52,
	LED_ACTION_53, LED_ACTION_54, LED_ACTION_55, LED_ACTION_56,
	LED_ACTION_MAX,
};

enum {
	BTN_ACTION_NONE,
	BTN_ACTION_LPRESS,
	BTN_ACTION_SPRESS,
	BTN_ACTION_ELPRESS,
	BTN_ACTION_HIGH,
	BTN_ACTION_LOW,
	BTN_ACTION_EDGE,
	BTN_ACTION_MAX,
};

#define mACTION(x, y, z) (x##_ACTION_##y << 16 | BOARD_##z)

extern int set_led(int);
extern int set_btn(const char *pathname);

#endif /* __ACTION_H_ */
