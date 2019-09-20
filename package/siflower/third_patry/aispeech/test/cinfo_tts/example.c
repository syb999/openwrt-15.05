#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include "dds.h"
#include "example_general/example_general.c"
enum _status dds_status;

/* 	
	example：cinfo设置

	每台设备(对应唯一的一个profile授权文件)在dui服务器上会有对应这台设备的一些配置。
	目前支持的配置包括：
	1.对话时返回的合成音的参数：
		音色："voiceId":"zhilingf"　	可选值：zhilingf,
        语速："speed":1.0,			可选范围: 0.7~2, 1表示正常语速，数值越小语速越慢；默认是正常语速
        音量："volume":80,			可选范围: 10~100, 取值越大音量越大
        采样率："sampleRate":8000,	可选值：16000(TODO 8000是否支持)，默认16000
        合成音格式："audioType":"mp3"	可选值：mp3，wav，默认mp3

        音色支持：
        发音人取值	说明
		anonyf		小妮，青年女声，普通话中文，英文混读
		qianranf	小倩，女童声，普通话中文
		hyanif		小燕；纯中文；青年女声
		lzyinf		小颖；纯中文；青年女声
		dlaf		多拉爱梦;中英文；青年女声
		zhilingf	林志玲，青年女声，普通话中文，英文混读
		anonyg		小珍，女童声，普通话中文
		xijunm		小军，青年男声，普通话中文，英文混读
		geyou		葛优，青年男声，普通话中文
		gdgm		郭德纲；纯中文；青年男声
		swkm		孙悟空；纯中文；青年男声
		hbrinf		快乐智慧；纯中文 童声女声
		zxcm		周星驰；纯中文；青年男声
		gqlanf		纯中文；青年女声
		lucyf		lucy ; 青年女声; 普通话中文,英文混读
		zzxiangm	赵忠祥 纯中文 中年男声

	2.默认的城市：
		城市: "city":"苏州市"
	比如问"今天天气怎么样"，此时不带城市信息，如果此前调用这个接口设置过城市(如苏州），则会返苏州的天气。
	否则dui服务器会根据客户端ip，去获取一个地理位置，但这种方式获取到的地理位置可能由于代理等原因不准确。
	这些配置可以通过cinfo set/get去设置/获取。
	
	speakUrl可以使用wget下载，并保存为音频文件，使用aplay/ffmpeg播放音频文件
	（在测试dds功能时可以使用命令行下载和播放音频，集成到应用中建议开发下载和播放功能）

*/
static int is_get_asr_result = 0;
static int is_get_tts_url = 0;

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

		case DDS_EV_OUT_ERROR: {
			char *value;
			if (!dds_msg_get_string(msg, "error", &value)) {
				printf("DDS_EV_OUT_ERROR: %s\n", value);
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
	dds_msg_set_type(msg, DDS_EV_IN_SPEECH);
	dds_msg_set_string(msg, "action", "start");
	dds_send(msg);
	dds_msg_delete(msg);
	msg = NULL;

	FILE *f = fopen("example_general/你叫什么名字.wav", "rb");
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
		if (is_get_tts_url) break;
		usleep(10000);
	}

	is_get_tts_url = 0;
	is_get_asr_result = 0;

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

	//获取cinfo服务器上的配置
	//获取的结果会通过回调中DDS_EV_OUT_CINFO_RESULT事件抛出
	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_CINFO_OPERATE);
	dds_msg_set_string(msg, "operation", "get");
	dds_msg_set_string(msg, "cinfo", "tts");
	dds_send(msg);
	dds_msg_delete(msg);

	//设置cinfo前
	send_request();

	//设置cinfo服务器上合成音的配置
	//设置是否成功会通过回调中DDS_EV_OUT_CINFO_RESULT事件抛出
	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_CINFO_OPERATE);
	dds_msg_set_string(msg, "operation", "set");
	dds_msg_set_string(msg, "tts", "{\"voiceId\":\"gdgm\",\"speed\":1,\"volume\":80,\"sampleRate\":16000,\"audioType\":\"mp3\"}");
	dds_send(msg);
	dds_msg_delete(msg);

	sleep(1);

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_RESET);
	dds_send(msg);
	dds_msg_delete(msg);

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_CINFO_OPERATE);
	dds_msg_set_string(msg, "operation", "get");
	dds_msg_set_string(msg, "cinfo", "tts");
	dds_send(msg);
	dds_msg_delete(msg);
	//设置cinfo后
	send_request();

	msg = dds_msg_new();
	dds_msg_set_type(msg, DDS_EV_IN_EXIT);
	dds_send(msg);
	dds_msg_delete(msg);


	pthread_join(tid, NULL);

	return 0;
}
