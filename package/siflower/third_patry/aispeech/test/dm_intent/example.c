/*	
	example: 语义直接触发对话

	有些情况下，对话不是由用户说话触发的。
	比如车载产品上，当油量不足时，产品应主动触发一次对话，提示用户油量不足。
	这种情况下，可以跳过识别和语义，直接进入指定的意图对话。
	该功能只能在dds为idle状态下使用，避免强制中断上一次对话。
	
	发给dds的事件为：DDS_EV_IN_DM_INTENT，需要配置的参数如下：
	skill	string		技能名称，必选，对应于dui平台上的技能名称
	task	string		任务名称，必选，对应于dui平台上的任务名称
	intent	string		意图名称，必选，对应于dui平台上的意图名称
	slots	json string	语义槽的key-value，可选
						格式为：｛"语义槽1":"语义槽1的值"，语义槽2":"语义槽2的值"｝

	example中对应dui平台上的配置为：
	说法：当前油量为三升（“三”作为语义槽“油量值”）
	对话回复：当前油量不足，仅为#油量值#升，请及时加油！

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

void send_request() {
	struct dds_msg *msg = NULL;

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_DM_INTENT);
	dds_msg_set_string(msg, "skill", "dds的example");
	dds_msg_set_string(msg, "task", "车载");
	dds_msg_set_string(msg, "intent", "油量不足");
	dds_msg_set_string(msg, "slots", "{\"油量值\":\"4\"}");
	dds_send(msg);
	dds_msg_delete(msg);

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

	sleep(2);

	send_request();

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
