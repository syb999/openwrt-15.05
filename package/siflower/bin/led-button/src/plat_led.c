/*
 * SiFlower sf16a18 openwrt gpio-led configuration.
 */
#include <sys/types.h>
#include <dirent.h>
#include "action.h"
#include <sys/types.h>
#include <unistd.h>
#include <sys/file.h>
#include <signal.h>

#define ARRAY_SIZE(arr) (sizeof(arr)/sizeof((arr)[0]))

/* This is the global configuration for all leds and bound with actions. */
struct board_info bd_info = { 0, NULL, { 0, "" } };

int sf_fd = -1;
const char * sf_file_lock = "/tmp/file_lock";

int sfax8_file_lock_set(int fd, int cmd, int type)
{
	struct flock lock;
	/*
	 * lock the whole file
	 * */
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_type = type;
	return fcntl(fd, cmd, &lock);
}

/*
 * Check if the file lock exists
 * */
int sfax8_file_lock_check(const char *file_name)
{
	int fd;
	struct flock lock;
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_type = F_WRLCK; //Must be initialized
	fd = open(file_name, O_RDWR);
	if (fd >= 0) {
		/*
		 * Get the status of a file lock for a file
		 * */
		fcntl(fd, F_GETLK, &lock);
		if (lock.l_type != F_UNLCK){
			debug(LOG_DEBUG, "In %s, sfax8 file was locked!!!\n", __func__);
			close(fd);
			return -1;
		}
		close(fd);
	}
	return 0;
}

int plat_led_init(int *board)
{
	DIR *dir;
	struct dirent *ptr;
	struct board_name *bd;

	bd = plat_get_board();
	if (bd) {
		*board = bd->board;
		bd_info.bn.board = bd->board;
		strcpy(bd_info.bn.name, bd->name);
		bd_info.ledcnt = 0;
	} else {
		debug(LOG_DEBUG, "In %s plat_get_board failed!!!\n", __func__);
		return -ENOENT;
	}

	/* load or reload all /sys/class/leds/ configuration */
	dir = opendir("/sys/class/leds/");
	if (dir) {
		bd_info.bd_leds = malloc(sizeof(char *) * MAX_LED_SUPPORTED);
		bd_info.ledcnt = 0;
		ptr = readdir(dir);
		while (ptr) {
			if (!(strcmp(ptr->d_name, ".") && strcmp(ptr->d_name, ".."))) {
				ptr = readdir(dir);
				continue;
			}
			/* Led name (ptr) must be less than MAX_NAME_LEN */
			bd_info.bd_leds[bd_info.ledcnt] = malloc(sizeof(char) * MAX_NAME_LEN);
			strcpy(bd_info.bd_leds[bd_info.ledcnt], ptr->d_name);
			bd_info.ledcnt++;
			ptr = readdir(dir);
		}
		if (bd_info.ledcnt == 0) {
			free(bd_info.bd_leds);
			bd_info.bd_leds = NULL;
		}
		closedir(dir);
	} else {
		return -ENOENT;
	}

	return 0;
}

int plat_led_deinit(void)
{
	int i;

	for (i = 0; i < bd_info.ledcnt; i++) {
		free(bd_info.bd_leds[i]);
	}
	/* free(NULL) is safe */
	free(bd_info.bd_leds);
	bd_info.ledcnt = 0;
	bd_info.bd_leds = NULL;

	return 0;
}

static int led_config(const char *p, const char *q, int c, char **s)
{
	int i, size;
	FILE *file;
	const char *path = "/sys/class/leds/";
	char filename[128];

	for (i = 0; i < c; i++) {
		strcpy(filename, path);
		strcat(filename, s[i]);
		strcat(filename, "/");
		strcat(filename, p);
		debug(LOG_DEBUG, "file is %s, i is %d, val is %s\n", filename, i, q);
		file = fopen(filename, "w");
		if (file) {
			size = fwrite(q, sizeof(char), strlen(q), file);
			fclose(file);
			if (size != strlen(q))
				return -EBUSY;
		} else {
			return -EINVAL;
		}
	}

	return 0;
}

/* All leds in arg "name" must be available! */
static int led_set_trigger(const char *trig, int cnt, char **name)
{
	return led_config("trigger", trig, cnt, name);
}
static int led_set_delayon(const char *trig, int cnt, char **name)
{
	return led_config("delay_on", trig, cnt, name);
}
static int led_set_delayoff(const char *trig, int cnt, char **name)
{
	return led_config("delay_off", trig, cnt, name);
}
static int led_set_owner(const char *trig, int cnt, char **name)
{
	return led_config("owner", trig, cnt, name);
}

int plat_set_led_on(void)
{
	return led_set_trigger("default-on", bd_info.ledcnt, bd_info.bd_leds);
}

static int __plat_set_led_timer(int c, char **n,
				const char *on, const char *off)
{
	int ret;

	ret = led_set_trigger("timer", c, n);
	if (ret)
		return ret;
	ret = led_set_delayon(on, c, n);
	ret += led_set_delayoff(off, c, n);

	return ret;
}

int plat_set_led_timer(void)
{
	return __plat_set_led_timer(bd_info.ledcnt, bd_info.bd_leds, "100", "100");
}

int plat_set_led_off(void)
{
	return led_set_trigger("none", bd_info.ledcnt, bd_info.bd_leds);
}

/*
 * Check if strings in a is included in b.
 * Returns 0 for found, -1 for not found.
 */
static int plat_led_check(char **a, char **b, int a_cnt, int b_cnt)
{
	int i, j;

	for (i = 0; i < a_cnt; i++) {
		for (j = 0; j < b_cnt; j++) {
			if (strcmp(a[i], b[j]) == 0)
				break;
		}
		if (j == b_cnt)
			return -1;
	}

	return 0;
}

/*
 * Repeater led action definition:
 *	1. power: default-on
 *	2. repeater-signal: default-on / timer:800:800
 *	3. wifi-status: default-on / timer:100:100
 */

int plat_repeater_check(char **ledx, int cnt)
{
	if (bd_info.bn.board == BOARD_3) {
		if (plat_led_check(ledx, bd_info.bd_leds, cnt, bd_info.ledcnt) == 0)
			return 0;
	}

	return -EINVAL;
}

int plat_set_led_rep_1(void)
{
	int ret;
	char *led[2] = {"repeater-red", "repeater-green"};

	ret = plat_repeater_check(led, 2);
	if (!ret) {
		ret = led_set_trigger("default-on", 1, &led[0]);
		ret += led_set_trigger("none", 1, &led[1]);
	}
	return ret;
}

int plat_set_led_rep_2(void)
{
	int ret;
	char *led[2] = {"repeater-red", "repeater-green"};

	ret = plat_repeater_check(led, 2);
	if (!ret) {
		ret = led_set_trigger("none", 1, &led[0]);
		ret += led_set_trigger("default-on", 1, &led[1]);
	}
	return ret;
}

int plat_set_led_rep_3(void)
{
	int ret;
	char *led_1 = "wifi-status";

	ret = plat_repeater_check(&led_1, 1);
	if (!ret)
		ret = __plat_set_led_timer(1, &led_1, "800", "800");
	return ret;
}

int plat_set_led_rep_4(void)
{
	int ret;
	char *led_1 = "wifi-status";

	ret = plat_repeater_check(&led_1, 1);
	if (!ret)
		ret = led_set_trigger("default-on", 1, &led_1);
	return ret;
}

int plat_set_led_rep_5(void)
{
	int ret;
	char *led[2] = {"repeater-red", "wifi-status"};

	ret = plat_repeater_check(led, 2);
	if (!ret) {
		ret = plat_set_led_off();
		ret += __plat_set_led_timer(2, led, "300", "300");
	}
	return ret;
}

/*
 * 86V led action definition
 *
 * */

int plat_86v_check(char **ledx, int cnt)
{
	if (bd_info.bn.board == BOARD_1 || bd_info.bn.board == BOARD_7) {
		if (plat_led_check(ledx, bd_info.bd_leds, cnt, bd_info.ledcnt) == 0)
			return 0;
	}

	return -EINVAL;
}

static int __plat_set_led_86v_delay(const char* delayon, const char *delayoff)
{
	int ret;
	char *led_1 = "led1";

	ret = plat_86v_check(&led_1, 1);
	if (!ret)
		ret = __plat_set_led_timer(1, &led_1, delayon, delayoff);
	return ret;
}

int plat_set_led_86v_delay(const char* delayon, const char *delayoff)
{
	if (sfax8_file_lock_check(sf_file_lock)) {
		debug(LOG_DEBUG, "In %s, sfax8 file lock check failed!!!\n", __func__);
		return -1;
	}
	return __plat_set_led_86v_delay(delayon, delayoff);
}

void sigalrm_fn_86v(int sig)
{
	if (sf_fd < 0) {
		debug(LOG_DEBUG, "In %s file was closed !!!\n", __func__);
		return;
	}
	if (sfax8_file_lock_set(sf_fd, F_SETLK, F_UNLCK)) {
		debug(LOG_DEBUG, "In %s, sfax8 file unlock failed !!!\n", __func__);
		goto done;
	}
	plat_set_led_on();
done:
	/*
	 * When the normal program exits, the file
	 * descriptor will be automatically closed.
	 * */
	close(sf_fd);
	sf_fd = -1;
	exit(0);
}

int plat_set_led_86v_flicker(int sec)
{
	int ret;
	if (sf_fd < 0) {
		sf_fd = open(sf_file_lock, O_RDWR | O_CREAT, 0666);
		if (sf_fd < 0) {
			debug(LOG_DEBUG, "In %s open failed !!!\n", __func__);
		} else {
			if (sfax8_file_lock_set(sf_fd, F_SETLK, F_WRLCK)) {
				/*
				 * Even if the file lock setting fails,
				 * it will not be worse if you continue to run.
				 * */
				debug(LOG_DEBUG, "In %s, sfax8 file lock failed !!!\n", __func__);
			}
		}
	}
	ret = __plat_set_led_86v_delay("500","500");

	signal(SIGALRM, sigalrm_fn_86v);
	alarm(sec);
	for (;;);
	return ret;
}

/*
 * p10h led action definition
 *
 * */
int plat_p10h_check(char **ledx, int cnt)
{
	if (bd_info.bn.board == BOARD_5) {
		if (plat_led_check(ledx, bd_info.bd_leds, cnt, bd_info.ledcnt) == 0)
			return 0;
	}

	return -EINVAL;
}

int plat_set_led_p10h_eth(char *trigger)
{
	int ret;
	char *led[2] = {"eth_led0", "eth_led1"};
	ret = plat_p10h_check(led, 2);
	if (!ret) {
		ret = led_set_trigger(trigger, 2, led);
		ret += led_set_owner("gpio", 2, led);
	}
	return ret;
}
void sigalrm_fn_p10h(int sig)
{
	plat_set_led_p10h_eth("default-on");
	exit(0);
}

int plat_set_led_p10h(void)
{
	int ret;
	ret = plat_set_led_p10h_eth("timer");
	signal(SIGALRM, sigalrm_fn_p10h);
	alarm(7);
	for (;;);
	return ret;
}

/*
 * p10m led action definition
 *
 * */
int plat_p10m_check(char **ledx, int cnt)
{
	if (bd_info.bn.board == BOARD_0) {
		if (plat_led_check(ledx, bd_info.bd_leds, cnt, bd_info.ledcnt) == 0)
			return 0;
	}

	return -EINVAL;
}

int plat_set_led_p10m_eth(char *trigger)
{
	int ret;
	char *led[4] = {"eth_led0", "eth_led1", "eth_led2", "eth_led3"};
	ret = plat_p10m_check(led, 4);
	if (!ret) {
		ret = led_set_trigger(trigger, 4, led);
		ret += led_set_owner("gpio", 4, led);

	}
	return ret;
}

void sigalrm_fn_p10m(int sig)
{
	plat_set_led_p10m_eth("default-on");
	exit(0);
}

int plat_set_led_p10m(void)
{
	int ret;
	ret = plat_set_led_p10m_eth("timer");
	signal(SIGALRM, sigalrm_fn_p10m);
	alarm(7);
	for (;;);
	return ret;
}

/*
 * evb led action definition
 *
 * */
int plat_evb_check(char **ledx, int cnt)
{
	if (bd_info.bn.board == BOARD_4) {
		if (plat_led_check(ledx, bd_info.bd_leds, cnt, bd_info.ledcnt) == 0)
			return 0;
	}

	return -EINVAL;
}

int plat_set_led_evb_eth(char *trigger)
{
	int ret;
	char *led[2] = {"eth_led0", "eth_led1"};
	ret = plat_evb_check(led, 2);
	if (!ret) {
		ret = led_set_trigger(trigger, 2, led);
		ret += led_set_owner("gpio", 2, led);

	}
	return ret;
}

void sigalrm_fn_evb(int sig)
{
	plat_set_led_evb_eth("default-on");
	exit(0);
}

int plat_set_led_evb(void)
{
	int ret;
	ret = plat_set_led_evb_eth("timer");
	signal(SIGALRM, sigalrm_fn_evb);
	alarm(7);
	for (;;);
	return ret;
}

/*
 * Repeater nopa led action definition:
 *	1. power: default-on
 *	2. repeater-signal: default-on / timer:800:800
 *	3. wifi-status: default-on / timer:100:100
 */

int plat_repeater_nopa_check(char **ledx, int cnt)
{
	if (bd_info.bn.board == BOARD_8) {
		if (plat_led_check(ledx, bd_info.bd_leds, cnt, bd_info.ledcnt) == 0)
			return 0;
	}

	return -EINVAL;
}

int plat_set_led_rep_nopa_1(void)
{
	int ret;
	char *led_1 = "wifi-status";

	ret = plat_repeater_nopa_check(&led_1, 1);
	if (ret)
		return ret;
	else
		return __plat_set_led_timer(1, &led_1, "100", "100");
}

int plat_set_led_rep_nopa_2(void)
{
	int ret;
	char *led_1 = "wifi-status";

	ret = plat_repeater_nopa_check(&led_1, 1);
	if (ret)
		return ret;
	else
		return led_set_trigger("default-on", 1, &led_1);
}

int plat_set_led_rep_nopa_3(void)
{
	int ret;
	char *led_1 = "repeater-signal";

	ret = plat_repeater_nopa_check(&led_1, 1);
	if (ret)
		return ret;
	else
		return __plat_set_led_timer(1, &led_1, "800", "800");
}

int plat_set_led_rep_nopa_4(void)
{
	int ret;
	char *led_1 = "repeater-signal";

	ret = plat_repeater_nopa_check(&led_1, 1);
	if (ret)
		return ret;
	else
		return led_set_trigger("default-on", 1, &led_1);
}

int plat_set_led_rep_nopa_5(void)
{
	int ret;
	char *led[3] = {"power", "wifi-status", "repeater-signal"};

	ret = plat_repeater_nopa_check(led, 3);
	if (!ret) {
		ret = plat_set_led_off();
		ret += __plat_set_led_timer(3, led, "300", "300");
	}
	return ret;
}
