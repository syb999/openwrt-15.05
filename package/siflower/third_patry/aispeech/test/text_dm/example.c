/*
	example:　传文本到dui服务器做对话

	从dui服务端获取到对话结果后，会依次抛出：
	DDS_EV_OUT_ASR_RESULT 	识别结果
	DDS_EV_OUT_DUI_RESPONSE	dui服务器返回的对话结果（json格式）
	DDS_EV_OUT_TTS　			对话回复对应的合成音链接，从这个链接下载音频

	初始化后，dds状态为idle
	发送DDS_EV_IN_SPEECH "start"后，dds状态转换为listening，此时将音频送入dds.
	发送DDS_EV_IN_SPEECH "end"后，dds状态转换为understanging，等待dui服务器返回结果。
	获取到dui服务器结果后，如果是单轮对话，dds状态转换为idle，否则为listening。
	进入下一次对话，重复上述操作

	测试说法：
	苏州今天的天气怎么样	天气技能，单轮对话
	你叫什么名字			闲聊技能，多轮对话
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
                printf("dui resp len %d, msg len\n");
                write_dui_response(resp);
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
    FILE *f = NULL;
    char data[2048];

    memset(data, 0, 2048);

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_NLU_TEXT);
	f = fopen("/tmp/text_dm.txt", "rb");
    if (f) {
        fread(data, 1, sizeof(data), f);
	    dds_msg_set_string(msg, "text", data);
        fclose(f);
    } else {
	    dds_msg_set_string(msg, "text", "我要听歌");
    }
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

	sleep(2);

	send_request();

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
