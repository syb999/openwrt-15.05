#include "action.h"

#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <linux/input.h>

int fd = -1;
struct input_event last[MAX_BTNS] = { 0 };

static int get_last_event(int btn)
{
	int i;

	for (i = 0; i < MAX_BTNS; i++) {
		if (last[i].code == btn)
			return i;
		if (last[i].code == 0) {
			last[i].code = KEY_MAX;
			return i; /* 1st */
		}
	}
	return -1; /* too much btns */
}

static int event_handled(int index)
{
	memset(&last[index], 0, sizeof(struct input_event));
	return 0;
}

void evdev_handler(int signum)
{
	struct input_event evt;
	int count, sec[2], usec[2], action = 0;
	struct board_name *bd;
	int ret, i = 0;

	debug(LOG_DEBUG, "%s: signum is %d vs SIGIO is %d\n",
						__func__, signum, SIGIO);
	if (fd < 0) {
		debug(LOG_ERR, "Input device not found! fd = %d\n", fd);
		return;
	}

	count = read(fd, &evt, sizeof(evt));
	bd = plat_get_board();
	if (!bd) {
		debug(LOG_ERR, "In %s : plat_get_board fail !!!\n", __func__);
		return;
	}
	while (count > 0) {
		/*
		 * normal gpio-input generates:
		 * 1st event: EV_KEY
		 * 2nd event: EV_SYNC
		 */
		if (evt.type == EV_SYN) {
			debug(LOG_DEBUG, "EV_SYN recieved!\n");
			goto set_done;
		}
		if (evt.type == EV_KEY) {
			/*
			 * Debounce is set in drivers/input/keyboard/gpio_keys.c,
			 * default 20ms set in dts.
			 *
			 * There are 2 kinds of buttons:
			 * LOW/HIGH/EDGE vs xxx press
			 *
			 * no old.value ---> LOW/HIGH/EDGE
			 * new.value == old.value ---> debounce, don't care
			 * new.value != old.value ---> press :
			 *	new.sec - old.sec < 4s ---> short press
			 *	new.sec - old.sec < 12s ---> long press
			 *	new.sec - old.sec >= 12s ---> extra long press
			 */
			sec[0] = evt.time.tv_sec;
			usec[0] = evt.time.tv_usec;
			i = get_last_event(evt.code);
			if (last[i].code == KEY_MAX) {
				debug(LOG_DEBUG, "first press!\n");
				ret = plat_btn_handler(BTN_ACTION_EDGE, bd, evt.code);
				if (ret == 0) {
					event_handled(i);
					goto set_done;
				}
				if (evt.value)
					ret = plat_btn_handler(BTN_ACTION_HIGH, bd, evt.code);
				else
					ret = plat_btn_handler(BTN_ACTION_LOW, bd, evt.code);
				if (ret == 0)
					event_handled(i);
				else
					memcpy(&last[i], &evt, sizeof(evt));
				goto set_done;
			} else if (i < 0) {
				debug(LOG_ERR, "too much btns!!!!\n");
				return;
			}
			sec[1] = last[i].time.tv_sec;
			usec[1] = last[i].time.tv_usec;
			if (last[i].value == evt.value)
				goto set_done; /* maybe a debounce? */
			debug(LOG_DEBUG, "time is %d, %d vs %d, %d\n",
					sec[0], usec[0], sec[1], usec[1]);
			debug(LOG_DEBUG, "type is %d, code is %d, value is %d\n",
						evt.type, evt.code, evt.value);
			if (sec[0] - sec[1] < 4) {
				action = BTN_ACTION_SPRESS;
			} else if (sec[0] - sec[1] < 12) {
				action = BTN_ACTION_LPRESS;
			} else {
				action = BTN_ACTION_ELPRESS;
			}
			ret = plat_btn_handler(action, bd, evt.code);
			event_handled(i);
			if (ret != 0)
				debug(LOG_ERR, "There is no handler for btn %d\n", evt.code);
		}
set_done:
		count = read(fd, &evt, sizeof(evt));
	}
	debug(LOG_DEBUG, "handler exit!\n");
}

int set_btn(const char *pathname)
{
	int Oflags;

	signal(SIGIO, evdev_handler);

	fd = open(pathname, O_RDONLY);
	if (fd < 0) {
		debug(LOG_ERR, "%s not found, try default path\n", pathname);
		fd = open("/dev/input/event0", O_RDONLY);
		if (fd < 0) {
			debug(LOG_ERR, "Input device not found! fd = %d\n", fd);
			return -1;
		}
	}

	fcntl(fd, F_SETOWN, getpid());
	Oflags = fcntl(fd, F_GETFL);
	fcntl(fd, F_SETFL, Oflags | FASYNC);

	/* TODO: wait here */
	while (1)
		sleep(60);

	return 0;
}
