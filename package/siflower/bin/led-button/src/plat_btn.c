#include "action.h"
#include <linux/input.h>
#include <sys/types.h>
#include <sys/wait.h>

int plat_btn_handler(int action, struct board_name *bn, int btn)
{
	int ret = -1;
	char cmd[100];
	sprintf(cmd, "sh /bin/check_btn_cfg %x  %d\n", btn, action);
	debug(LOG_DEBUG, "cmd = %s\n", cmd);
	ret = system(cmd);
	if (-1 == ret) {
		debug(LOG_DEBUG, "%s: %d >> system error!\n", __func__, __LINE__);
	} else {
		if (WIFEXITED(ret)) {
			ret = WEXITSTATUS(ret);
			debug(LOG_DEBUG, "%s: %d >> system ret = %d\n", __func__, __LINE__, ret);
		} else {
			debug(LOG_DEBUG, "%s: %d >> system error ret = %d\n", __func__, __LINE__, ret);
		}
	}
	return ret;
}
