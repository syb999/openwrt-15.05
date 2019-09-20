/*
	example:　授权方式

	1.deviceProfile：从dui平台下载的该产品的授权文件里面的内容
	2.savedProfile：从dui平台下载的该产品的授权文件的路径
	3.productKey和productSecret: 
		dui平台每个产品对应一个productKey和productSecret。
		每一台设备需要有一个deviceName，用于标识每一台设备。
		（所有设备的deviceName需要告知dui平台，进行预登记）
		这种方式授权dds会在运行时向服务端请求profile文件，保存到savedProfile设置的路径中。
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include "dds.h"
#include "example_general/example_general.c"

#define USE_AUTH_DEVICE_PROFILE
#define USE_AUTH_SAVE_PROFILE
#define USE_AUTH_PRODUCT_KEY

static int dds_ev_ccb(void *userdata, struct dds_msg *msg) {
	int type;
	if (!dds_msg_get_type(msg, &type)) {
		switch (type) {
		case DDS_EV_OUT_STATUS: {
			char *value;
			if (!dds_msg_get_string(msg, "status", &value)) {
				if (!strcmp(value, "idle")) {
					dds_status = DDS_STATUS_IDLE;
				} else if (!strcmp(value, "listening")) {
					dds_status = DDS_STATUS_LISTENING;
				} else if (!strcmp(value, "understanding")) {
					dds_status = DDS_STATUS_UNDERSTANDING;
				}
			}
			break;
		}
		case DDS_EV_OUT_ERROR: {
			char *value;
			if (!dds_msg_get_string(msg, "error", &value)) {
				printf("DDS_EV_OUT_ERROR: %s\n", value);
			}
			break;
		}
		default:
			break;
		}
	}
	return 0;
}


void *_run(void *arg) {
	struct dds_msg *msg = dds_msg_new();
	dds_msg_set_string(msg, "productId", productId);
	dds_msg_set_string(msg, "aliasKey", aliasKey);
#ifdef USE_DEVICE_PROFILE
	dds_msg_set_string(msg, "deviceProfile", deviceProfile);
#elif defined USE_AUTH_SAVE_PROFILE
	dds_msg_set_string(msg, "savedProfile", savedProfile);
#elif defined USE_PRODUCT_KEY
	dds_msg_set_string(msg, "productKey", productKey);
	dds_msg_set_string(msg, "productSecret", productSecret);
#endif
	struct dds_opt opt;
	opt._handler = dds_ev_ccb;
	opt.userdata = arg;
	dds_start(msg, &opt);
	dds_msg_delete(msg);

	return NULL;
}

int main(int argc, char **argv) {
	struct dds_msg *msg = NULL;

	pthread_t tid;
	pthread_create(&tid, NULL, _run, NULL);

	while (1) {
		if (dds_status == DDS_STATUS_IDLE) break;
		usleep(10000);
	}

	sleep(2);

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
