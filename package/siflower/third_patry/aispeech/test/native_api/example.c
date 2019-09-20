/*
	example: native api使用
	
	native api指本地调用，dds服务端查询本地数据, 客户端将本地数据通过dds传回给dui服务端。
	开发者在dui平台定制技能时，在“资源调用“中选择”使用API资源”中的native api方式。

	native api通过DDS_EV_OUT_NATIVE_CALL抛出。
	native　api的结果在回调中通过DDS_EV_IN_NATIVE_RESPONSE，返回给dui服务。

	该example中在dui平台技能配置如下：
	说法：客厅的温度是多少（“客厅”为语义槽“房间”)
	资源调用：
		使用API资源：native://get_temperature
		API配置：参数名称："room"，取值："语义槽：房间"
	对话回复：#房间#的温度是$extra.temperature$
		　　　（客户端传回给dui服务器的参数，统一放在extra字段下，使用$extra.temperature$的方式获取）

	客户端配置：
		在DDS_EV_IN_NATIVE_RESPONSE事件中设置参数："temperature" "35"
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
static int is_get_native_api = 0;

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
		case DDS_EV_OUT_NATIVE_CALL: {
			char *value;
			if (!dds_msg_get_string(msg, "api", &value)) {
				printf("command api: %s\n", value);
				if (!dds_msg_get_string(msg, "param", &value)) {
					printf("command param: %s\n", value);
				}
			}
			is_get_native_api = 1;
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
            	// printf("dui response: %s\n", resp);
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
		if (is_get_native_api) break;
		usleep(10000);
	}

	struct dds_msg *retmsg = dds_msg_new();
	dds_msg_set_type(retmsg, DDS_EV_IN_NATIVE_RESPONSE);
	dds_msg_set_string(retmsg, "temperature", "35");
	dds_send(retmsg);
	dds_msg_delete(retmsg);

	while (1) {
		if (dds_status == DDS_STATUS_IDLE) break;
		usleep(10000);
	}
	
	is_get_native_api = 0;
}

int main(int argc, char **argv) {
	struct dds_msg *msg = NULL;

	pthread_t tid;
	pthread_create(&tid, NULL, _run, NULL);

	while (1) {
		if (dds_status == DDS_STATUS_IDLE) break;
		usleep(10000);
	}

	send_request("example_general/客厅的温度是多少.wav");

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
