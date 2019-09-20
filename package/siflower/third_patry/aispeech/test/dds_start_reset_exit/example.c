/* 
	example: dds start, reset, exit

	start: 调用dds_start()，该接口会一直阻塞，需要在一个单独的线程里面调用执行
		   dds启动完成后，会从回调抛出状态DDS_STATUS_IDLE
		　　　dds的消息通过回调抛出
		　　　需要发送给dds的消息，通过dds_send()发送到dds内部

	reset: 如果在操作dds时，“发送部分音频后，不想要继续这次操作”等情况，
		   发送DDS_EV_IN_RESET，dds回调初始状态

	exit: 发送DDS_EV_IN_EXIT，退出dds
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include "dds.h"
#include "example_general/example_general.c"
enum _status dds_status;

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
	dds_msg_set_string(msg, "deviceProfile", deviceProfile);

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

	sleep(1);

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_RESET);
	dds_send(msg);
	dds_msg_delete(msg);

	sleep(1);

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
