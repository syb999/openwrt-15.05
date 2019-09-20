/*
	example: 设置wakeupword

	假设唤醒词为："你好小驰"
	则说：你好小驰今天天气怎么样
	服务端在做语义解析时，发现"你好小驰"是唤醒词，则会去掉唤醒词，解析后面半句，这样语义解析更准确。

	唤醒词和cinfo服务不同：
		cinfo会将配置保存在云端，
		唤醒词设置的有效时间为下一次唤醒之前，重新调用dds_start会重置唤醒词为空。
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include "dds.h"
#include "example_general/example_general.c"

static int is_get_asr_result = 0;
static int is_get_tts_url = 0;
static int is_dui_response = 0;

static int dds_ev_ccb(void *userdata, struct dds_msg *msg) {
	int type;
	if (!dds_msg_get_type(msg, &type)) {
		switch (type) {
		case DDS_EV_OUT_STATUS: {
			char *value;
			if (!dds_msg_get_string(msg, "status", &value)) {
				printf("dds cur status: %s\n", value);
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
		case DDS_EV_OUT_CINFO_RESULT: {
			char *value;
			if (!dds_msg_get_string(msg, "result", &value)) {
				printf("result: %s\n", value);
			}
			if (!dds_msg_get_string(msg, "cinfo", &value)) {
				printf("cinfo: %s\n", value);
			}
			break;
		}
		case DDS_EV_OUT_ASR_RESULT: {
			char *value;
			if (!dds_msg_get_string(msg, "var", &value)) {
				printf("var: %s\n", value);
			}
			if (!dds_msg_get_string(msg, "text", &value)) {
				printf("text: %s\n", value);
				is_get_asr_result = 1;
			}
			break;
		}
		case DDS_EV_OUT_TTS: {
			char *value;
			if (!dds_msg_get_string(msg, "speakUrl", &value)) {
				printf("speakUrl: %s\n", value);
				is_get_tts_url = 1;
			}
			break;
		}
		case DDS_EV_OUT_DUI_RESPONSE: {
            char *resp = NULL;
            if(!dds_msg_get_string(msg, "response", &resp)) {
            	printf("dui response: %s\n", resp);
            }
            is_dui_response = 1;
            break;
        }
		case DDS_EV_OUT_ERROR: {
			char *value;
			if (!dds_msg_get_string(msg, "error", &value)) {
				printf("DDS_EV_OUT_ERROR: %s\n", value);
			}
			is_dui_response = 1;
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

void send_request(char *wav_name) {
	struct dds_msg *msg = NULL;

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_SPEECH);
	dds_msg_set_string(msg, "action", "start");
	dds_send(msg);
	dds_msg_delete(msg);
	msg = NULL;

	FILE *f = fopen(wav_name, "rb");
	fseek(f, 44, SEEK_SET);
	char data[3200];
	int len;
	struct dds_msg *m;
	while (1) {
		len = fread(data, 1, sizeof(data), f);
		if (len <= 0) break;
		m = dds_msg_new();
		dds_msg_set_type(m, DDS_EV_IN_AUDIO_STREAM);
		dds_msg_set_bin(m, "audio", data, len);
		dds_send(m);
		dds_msg_delete(m);
		usleep(100000);
	}
	fclose(f);

	/*告知DDS结束语音*/
	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_SPEECH);
	dds_msg_set_string(msg, "action", "end");
	dds_send(msg);
	dds_msg_delete(msg);
	msg = NULL;

	while (1) {
		if (is_dui_response) break;
		usleep(10000);
	}

	is_dui_response = 0;

}

int main(int argc, char **argv) {
	struct dds_msg *msg = NULL;

	pthread_t tid;
	pthread_create(&tid, NULL, _run, NULL);

	while (1) {
		if (dds_status == DDS_STATUS_IDLE) break;
		usleep(10000);
	}

	/*设置wakeupword*/
	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_WAKEUP_WORD);
	dds_msg_set_string(msg, "wakeupWord", "你好小驰");
	dds_send(msg);
	dds_msg_delete(msg);
	msg = NULL;

	send_request("example_general/你好小驰苏州今天的天气怎么样.wav");
	send_request("example_general/你好小乐苏州今天的天气怎么样.wav");

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
