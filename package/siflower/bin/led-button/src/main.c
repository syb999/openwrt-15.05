/*
 * Led and button centralized dispatcher.
 * Author: nevermore.wang@siflower.com.cn
 */
#include <unistd.h>
#include <signal.h>
#include "action.h"

static int usage(void)
{
	debug(LOG_ERR, "*****led-button usage****\n");
	debug(LOG_ERR, "/$PATH/led-button [ -b arg0 ] [ -l arg1 ]\n");
	debug(LOG_ERR, "-b $pathname : setup gpio_key button, wait event from");
	debug(LOG_ERR,		      "event device from $pathname.\n");
	debug(LOG_ERR, "-l $ACTION : setup led configuration with the action");
	debug(LOG_ERR,		    "defined in action.h.\n\n");

	return 0;
}

int main(int argc, char **argv)
{
	int ch, ret = 0;
	int action;

	while ((ch = getopt(argc, argv, "l:b:h:")) != -1) {
		switch (ch) {
		case 'h':
			usage();
			break;
		case 'b':
			debug(LOG_DEBUG, "input device %s!\n", optarg);
			ret = set_btn(optarg);
			break;
		case 'l':
			action = atoi(optarg);
			debug(LOG_DEBUG, "led %d!\n", action);
			if (action >= LED_ACTION_NONE && action < LED_ACTION_MAX)
				ret = set_led(action);
			break;
		default:
			usage();
			break;
		}
	}

	debug(LOG_DEBUG, "%s ret is %d\n", __func__, ret);
	return ret;
}
