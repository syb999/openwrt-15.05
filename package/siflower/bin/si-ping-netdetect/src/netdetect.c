/*
 * =====================================================================================
 *
 *       Filename:  netdetect.c
 *
 *    Description:
 *
 *        Version:  1.0
 *        Created:  09/08/2015 07:46:17 PM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  xiaoxi , xiaoxi.lin@siflower.com.cn
 *        Company:  Siflower
 *
 * =====================================================================================
 */
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <uci_config.h>
#include <uci.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <regex.h>

#define PING_NUMBER 5
struct buffer_info{
    long stamp;
    long rxb;
    long txb;
};

static  char *PING_BAIDU_CMD  = "ping -c1 -w2 www.baidu.com";
static  char *PING_QQ_CMD     = "ping -c1 -w2 www.qq.com";
static  char *PING_TAOBAO_CMD = "ping -c1 -w2 www.taobao.com";

int g_if_downloaded = 0;
int g_if_uploaded   = 0;
int g_ping_total    = 0;
int g_ping_success  = 0;
int g_total_delay   = 0;

long PING_NOW;
pthread_mutex_t g_queue_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t g_queue_runcmd = PTHREAD_MUTEX_INITIALIZER;

int run_cmd(char *cmd, char result[])
{
    FILE *pp = popen(cmd, "r");
    int iRet = 0;
    if (!pp){
        return -1;
    }
    while (fgets(result, 256, pp) != NULL)
    {
        if (result[strlen(result) - 1] == '\n') {
            result[strlen(result) - 1] = '\0';
        }
    }
    iRet = pclose(pp);
    if(WIFEXITED(iRet) == 0)
        return -1;
    else
        return WEXITSTATUS(iRet);
}

int get_ping_delay(char *result)
{
    const char *pattern = "[^0-9]+([0-9]+).*";
    char str[10] = "";
    regex_t reg;
    regmatch_t value[2];
    int delay;
    if( regcomp (&reg, pattern, REG_EXTENDED) != 0)
        return -1;
    if( regexec (&reg, result, 2, value, 0) != 0)
        return -1;
    memcpy(str, result + value[1].rm_so, value[1].rm_eo - value[1].rm_so);
    delay  = atoi(str);
    return delay;
}

void *PING(void *args)
{
    int   i;
    char *cmd = (char *)args;
    char result[256] = "";
    for (i = 0; i < PING_NUMBER; i++)
    {
        long ping_next = time(NULL);
        if((ping_next - PING_NOW) > 3)
            break;

        pthread_mutex_lock(&g_queue_runcmd);
        int ret = run_cmd(cmd, result);
        pthread_mutex_unlock(&g_queue_runcmd);
        if(ret != -1){
            pthread_mutex_lock(&g_queue_mutex);
            g_ping_total++;
            pthread_mutex_unlock(&g_queue_mutex);
            if(ret == 0){
                int delay = get_ping_delay(result);
                if(delay != -1){
                    pthread_mutex_lock(&g_queue_mutex);
                    g_total_delay += delay;
                    g_ping_success++;
                    pthread_mutex_unlock(&g_queue_mutex);
                }
            }
        }
    }
    return NULL;
}

void get_wan_ifname(char *ifname){
    struct uci_context *ctx = uci_alloc_context();
    struct uci_package *p = NULL;
    uci_set_confdir(ctx, "/etc/config");
    if(uci_load(ctx, "network", &p) == UCI_OK){
        struct uci_section *wan = uci_lookup_section(ctx, p, "wan");
        if(wan != NULL){
            const char *value = uci_lookup_option_string(ctx, wan, "ifname");
            if(value != NULL)
                sprintf(ifname, "%s", value);
        }

        uci_unload(ctx,p);
    }
    uci_free_context(ctx);
}


int get_buffer_info(struct buffer_info *info)
{
    char result[256] = "";
    char cmd[20] = "luci-bwc -i ";
    char ifname[10] = "";
    get_wan_ifname(ifname);
    strcat(cmd, ifname);
    const char *pattern = "[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+[0-9]+[^0-9]+([0-9]+).*";
    regex_t reg;
    regmatch_t value[4];
    long tmp_num[3];
    int i;
    run_cmd(cmd, result);
    if( regcomp (&reg, pattern, REG_EXTENDED) != 0)
        return -1;
    if( regexec (&reg, result, 4, value, 0) != 0)
        return -1;
    for(i = 1; i < 4; i ++){
        char tmp_str[15] = "";
        memcpy(tmp_str, result + value[i].rm_so, value[i].rm_eo - value[i].rm_so);
        tmp_num[i-1] = atoi(tmp_str);
    }
    info->stamp = tmp_num[0];
    info->rxb   = tmp_num[1];
    info->txb   = tmp_num[2];
    regfree(&reg);
    return 0;
}


long get_wan_speed(char *speed_type)
{
    long speed = 0;
    char *upspeed = "upspeed";
    char *downspeed = "downspeed";
    struct buffer_info *now_info, *next_info;
    now_info = (struct buffer_info*)malloc(sizeof(struct buffer_info));
    next_info = (struct buffer_info*)malloc(sizeof(struct buffer_info));
    get_buffer_info(now_info);
    sleep(1);
    get_buffer_info(next_info);
	while(now_info->stamp == next_info->stamp){
        get_buffer_info(next_info);
    }
    if(strcmp(speed_type, upspeed) == 0)
        speed = (next_info->txb - now_info->txb)/(next_info->stamp - now_info->stamp);
    if(strcmp(speed_type, downspeed) == 0)
        speed = (next_info->rxb - now_info->rxb)/(next_info->stamp - now_info->stamp);
    free(now_info);
    free(next_info);
    return speed;
}


void *get_downbandwidth(void *args)
{
    char *speed_type = "downspeed";
    long max_speed = 0;
    long bandwidth = 0;
    long speed = 0;
	int count = 0;
    while(g_if_downloaded != 1){
        speed=get_wan_speed(speed_type);
		max_speed += speed;
		count++;
    }
	// remove last count because may download stop in the second
	max_speed -= speed;
	count--;
    bandwidth = max_speed/count/1000;
    printf("downbandwidth=%ld\n",bandwidth);
    return NULL;
}


void *get_upbandwidth(void *args)
{
    char *speed_type = "upspeed";
    long max_speed = 0;
    long bandwidth = 0;
    long speed = 0;
    while(g_if_uploaded != 1){
        speed=get_wan_speed(speed_type);
        if(max_speed < speed)
            max_speed = speed;
    }
    bandwidth = max_speed*8/1000;
    printf("upbandwidth=%ld",bandwidth);
    return NULL;
}


void *do_download(void *args)
{
    char dustbin[256] = "";
    int value = (int)args;
	if(value == 1)
	  run_cmd("curl -4 -s -m 8 -o /dev/null http://downapp.baidu.com/appsearch/AndroidPhone/1.0.73.221/1/1012271b/20180927115602/appsearch_AndroidPhone_1-0-73-221_1012271b.apk",dustbin);
	else if (value == 2)
	  run_cmd("curl -4 -s -m 8 -o /dev/null http://downapp.baidu.com/appsearch/AndroidPhone/1.0.73.221/1/1012271b/20180927115602/appsearch_AndroidPhone_1-0-73-221_1012271b.apk",dustbin);
	else
	  run_cmd("curl -4 -s -m 8 -o /dev/null  http://downapp.baidu.com/appsearch/AndroidPhone/1.0.73.221/1/1012271b/20180927115602/appsearch_AndroidPhone_1-0-73-221_1012271b.apk",dustbin);

    g_if_downloaded = 1;

    return NULL;
}

// // download would delete downloadn test now
// void *do_upload(void *args)
// {
//     char dustbin[256] = "";
//     run_cmd("curl -4 -s -m 20 -T /tmp/bandwidthtest www.baidu.com",dustbin);
//     sleep(3);
//     g_if_uploaded = 1;
//     run_cmd("rm /tmp/bandwidthtest",NULL);
//     return NULL;
// }


int count_pkglost()
{
    int i = 0;
    PING_NOW = time(NULL);
    pthread_t ping_poll[10];
	int ret_v[10];

    ret_v[0]= pthread_create(&ping_poll[0],  NULL, PING, (void *)PING_BAIDU_CMD);
    ret_v[1]= pthread_create(&ping_poll[1],  NULL, PING, (void *)PING_BAIDU_CMD);
    ret_v[2]= pthread_create(&ping_poll[2],  NULL, PING, (void *)PING_QQ_CMD);
    ret_v[3]= pthread_create(&ping_poll[3],  NULL, PING, (void *)PING_QQ_CMD);
    ret_v[4]= pthread_create(&ping_poll[4],  NULL, PING, (void *)PING_QQ_CMD);
    ret_v[5]= pthread_create(&ping_poll[5],  NULL, PING, (void *)PING_TAOBAO_CMD);
    ret_v[6]= pthread_create(&ping_poll[6],  NULL, PING, (void *)PING_TAOBAO_CMD);
    ret_v[7]= pthread_create(&ping_poll[7],  NULL, PING, (void *)PING_TAOBAO_CMD);
    ret_v[8]= pthread_create(&ping_poll[8],  NULL, PING, (void *)PING_BAIDU_CMD);
    ret_v[9]= pthread_create(&ping_poll[9],  NULL, PING, (void *)PING_BAIDU_CMD);
	for (i = 0; i < 10; ++i) {
		pthread_join(ping_poll[i],NULL);
	}
	for (i = 0; i < 10; ++i) {
		if(ret_v[i] != 0)
		  return -1;
	}
    printf("ping_total=%d,ping_success=%d,delay=%d",g_ping_total, g_ping_success, g_ping_success == 0 ? -1 : g_total_delay/g_ping_success);
    return 0;
}


int count_downbandwidth()
{
    int ret = 0;
    pthread_t downbandwidth, download1, download2, download3;
    int ret1, ret2, ret3, ret4;
    ret1 = pthread_create(&download1,        NULL, do_download,  (void*) 1);
    ret2 = pthread_create(&download2,        NULL, do_download,  (void*) 2);
    ret3 = pthread_create(&download3,        NULL, do_download,  (void*) 3);
    sleep(2);
    ret4 = pthread_create(&downbandwidth,   NULL, get_downbandwidth, NULL);
    if((ret1!=0) || (ret2!=0)){
        ret = -1;
    }
    pthread_join(download1,NULL);
    pthread_join(download2,NULL);
    pthread_join(download3,NULL);
    pthread_join(downbandwidth,NULL);

    return ret;
}


// int count_upbandwidth()
// {
//     int ret = 0;
//     pthread_t upbandwidth, upload;
//     int ret1, ret2;
//     ret1 = pthread_create(&upload,        NULL, do_upload,       NULL);
//     ret2 = pthread_create(&upbandwidth,   NULL, get_upbandwidth, NULL);
//     if((ret1 != 0) || (ret2 != 0)){
//         ret = -1;
//     }
//     pthread_join(upload,NULL);
//     pthread_join(upbandwidth,NULL);
//     return ret;
// }


int main(int argc, char *argv[])
{
    int n = 0;
    int ret = 0;
    while ((n = getopt(argc, argv, "pdu")) != EOF){
        switch (n) {
            case 'p':
                ret = count_pkglost();
                break;
            case 'd':
                ret = count_downbandwidth();
                break;
            // case 'u':
            //     ret = count_upbandwidth();
            //     break;
            default :
                ret = -1;
                break;
        }
    }
    if (ret == -1){
        printf("excute error !");
    }
    return ret;
}
