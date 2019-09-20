#include "action.h"

int set_led(int action)
{
	int ret, board = -1;

	ret = plat_led_init(&board);
	if (ret < 0)
		return ret;

	switch (action << 16 | board) {
	case mACTION(LED, 1, 1):
	case mACTION(LED, 1, 4):
	case mACTION(LED, 1, 7):
		ret = plat_set_led_on();
		break;
	case mACTION(LED, 2, 4):
		ret = plat_set_led_timer();
		break;
	case mACTION(LED, 3, 1):
	case mACTION(LED, 3, 4):
	case mACTION(LED, 3, 7):
		ret = plat_set_led_off();
		break;
	case mACTION(LED, 9, 0):
		ret = plat_set_led_p10m();
		break;
	case mACTION(LED, 17, 3):
		ret = plat_set_led_rep_1();
		break;
	case mACTION(LED, 18, 3):
		ret = plat_set_led_rep_2();
		break;
	case mACTION(LED, 19, 3):
		ret = plat_set_led_rep_3();
		break;
	case mACTION(LED, 20, 3):
		ret = plat_set_led_rep_4();
		break;
	case mACTION(LED, 21, 3):
		ret = plat_set_led_rep_5();
		break;
	case mACTION(LED, 25, 1):
	case mACTION(LED, 25, 7):
		ret = plat_set_led_86v_flicker(4);
		break;
	case mACTION(LED, 26, 1):
	case mACTION(LED, 26, 7):
		ret = plat_set_led_86v_flicker(6);
		break;
	case mACTION(LED, 27, 1):
	case mACTION(LED, 27, 7):
		ret = plat_set_led_86v_delay("1000", "1000");
		break;
	case mACTION(LED, 28, 1):
	case mACTION(LED, 28, 7):
		ret = plat_set_led_86v_delay("2000", "2000");
		break;
	case mACTION(LED, 33, 5):
		ret = plat_set_led_p10h();
		break;
	case mACTION(LED, 41, 4):
		ret = plat_set_led_evb();
		break;
	case mACTION(LED, 49, 8):
		ret = plat_set_led_rep_nopa_1();
		break;
	case mACTION(LED, 50, 8):
		ret = plat_set_led_rep_nopa_2();
		break;
	case mACTION(LED, 51, 8):
		ret = plat_set_led_rep_nopa_3();
		break;
	case mACTION(LED, 52, 8):
		ret = plat_set_led_rep_nopa_4();
		break;
	case mACTION(LED, 53, 8):
		ret = plat_set_led_rep_nopa_5();
		break;
	default:
		ret = -EINVAL;
		break;
	}

	plat_led_deinit();

	return ret;
}
