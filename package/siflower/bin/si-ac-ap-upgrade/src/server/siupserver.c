/*
 * =====================================================================================
 *
 *      Filename:  socket_server.c
 *
 *   Description:  local socket server, listen for autotest
 *       Version:  1.0
 *       Created:  01/09/2018
 *      Compiler:  gcc
 *
 *        Author:  Qin.Xia , qin.xia@siflower.com.cn
 *       Company:  Siflower Communication Tenology Co.,Ltd
 *       TODO:
 *       1)
 *
 *
 * ======================================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <sys/time.h>
#include <fcntl.h>
#include <signal.h>


#define AP_DOWNLOAD_PORT                1125
#define MAX_CLIENT                      128
#define MSG_BUFFER                      1024
#define BLOCK_SIZE                      14600//14*1024

static volatile int g_force_exit_signal = 0;
char * gc_file_content = NULL;
unsigned gi_file_content_len = NULL;
int  listenfd = 0;
int connfd[MAX_CLIENT] = {0};
void sighandler(int sig) {
	unsigned int i = 0;
	printf("handle signal here\n");
	g_force_exit_signal = 1;
	if(gc_file_content)
	  free(gc_file_content);
	if(listenfd)
	  close(listenfd);
	for(;i < MAX_CLIENT; i++){
		if(connfd[i])
		  close(connfd[i]);
	}
	return ;
}

void *download_handler(void *fd)
{
	int *psockfd = (int *)fd;
	int next_len = BLOCK_SIZE;
	char * pbuf = NULL;
	// unsigned int len = 0;
	// char buf[MSG_BUFFER] = {'\0'};

	// len = recv(psockfd, (void *)buf, MSG_BUFFER, MSG_WAITALL);
	// if (len < 0){
	// 	printf("[server] %s, receive message error!\n", __func__);
	// 	return fd;
	// }
	// printf("[server] %s, receive message: %s, %d bytes\n", __func__, buf, len);
	// TODO: may download other things or start auto test
	printf("[server] %s, start send file  %d bytes\n", __func__, gi_file_content_len);
	if(next_len > gi_file_content_len){
		printf("[server] %s, file size is less than a block %d bytes\n", __func__, gi_file_content_len);
		next_len = gi_file_content_len;
	}
	pbuf = gc_file_content;
	while (next_len > 0){
		if (send(*psockfd, pbuf, next_len, MSG_NOSIGNAL) < 0) {
			printf("[server] %s, send message error! errno=%s\n", __func__, strerror(errno));
			break;
		}
		// printf("[server] %s, send file size %d!\n", __func__, next_len);
		pbuf += next_len;
		if ((gc_file_content + gi_file_content_len - pbuf) < BLOCK_SIZE){
			next_len = gc_file_content + gi_file_content_len - pbuf;
		}
		else
		  next_len = BLOCK_SIZE;
	}

	printf("[server] %s, send file done !\n", __func__);
	close(*psockfd);
	*psockfd = 0;
	return NULL;
}

void *download_server(void *param)
{
	struct timeval timeout = {3, 0};
	struct sockaddr_in srv_addr, clt_addr;
	socklen_t sock_len;
	pthread_t tid;
	pthread_attr_t a;
	pthread_attr_init(&a);
	//set thread detach so when it's down, would free resource by system
	pthread_attr_setdetachstate(&a, PTHREAD_CREATE_DETACHED);
	int  val = 1, i = 0;
	int  ret;
	int count = 0;
	bzero(&srv_addr, sizeof(srv_addr));
	srv_addr.sin_family = AF_INET;
	srv_addr.sin_addr.s_addr = htons(INADDR_ANY);
	srv_addr.sin_port = htons(AP_DOWNLOAD_PORT);

	listenfd = socket(AF_INET, SOCK_STREAM, 0);
	if (listenfd < 0)
	{
		printf("[server] %s, create socket fail!\n", __func__);
		return NULL;
	}

	if (setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &val, sizeof(val))) {
		printf("[server] %s, setsockopt error!\n", __func__);
		goto SOCKET_ERR;
	}

	if (bind(listenfd, (struct sockaddr*)&srv_addr, sizeof(srv_addr)) < 0)
	{
		printf("[server] %s, bind socket error!\n", __func__);
		goto SOCKET_ERR;
	}

	sock_len = sizeof(srv_addr);
	if (listen(listenfd, MAX_CLIENT) < 0)
	{
		printf("[server] %s, listen error!\n", __func__);
		goto SOCKET_ERR;
	}
	printf("[server] %s, listen OK!\n", __func__);

	sock_len = sizeof(clt_addr);

	while (1){
		/* socket will blocking here to wait for connect requet */
		connfd[i] = accept(listenfd, (struct sockaddr *)&clt_addr, &sock_len);
		if (connfd[i] < 0)
		{
			printf("[server] %s, accept error! erroo=%s\n", __func__, strerror(errno));
			continue;
		}
		printf("[server] %s, received a connection IP:%s port:%d!\n", __func__, inet_ntoa(clt_addr.sin_addr), ntohs(clt_addr.sin_port));

		/* set timeout for receive data */
		setsockopt(connfd[i], SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(struct timeval));

		/* create thread to handle receive message */
		ret = pthread_create(&tid, &a, download_handler, &connfd[i]);
		if ( ret != 0){
			printf("[server] autotest download pthread create error! - %s count %d\n", strerror(ret), count);
			break;
		}
		count++;
		i += 1;
		i %= MAX_CLIENT;
	}

SOCKET_ERR:
	close(listenfd);
	listenfd = 0;
	printf("set signal here\n");
	g_force_exit_signal = 1;
	return NULL;
}

int load_file(char* file_name){

	FILE *fp = NULL;
	unsigned int file_size = 0;
	unsigned int read_count = 0;
	// open file to read, it will touch this file when not exist.
	fp = fopen(file_name, "r");
	if (fp == NULL){
		printf("[server] %s, open file error!\n", __func__);
		return -1;
	}
	fseek(fp, 0, SEEK_END);
	file_size = ftell(fp);
	rewind(fp);
	gc_file_content = malloc(file_size);
	read_count = fread(gc_file_content, 1, file_size, fp);
	if(read_count == 0 ||  read_count != file_size){
		printf("[server] %s, read file error!\n", __func__);
		fclose(fp);
		if(gc_file_content)
		  free(gc_file_content);
		return -1;
	}
	fclose(fp);
	gi_file_content_len = file_size;
	return 0;
}

int main(int argc, char *argv[])
{
	unsigned int i = 0;
	signal(SIGINT, sighandler);
	if(argc < 2){
		return -1;
	}
	int ret = 0;
	char * dir_name = argv[1];
	printf("firmware dir is %s \n",dir_name);

	if(load_file(dir_name) < 0){
		printf("load file fail \n");
		return -1;
	}
	pthread_t download_server_thread;
	ret = pthread_create(&download_server_thread, NULL, &download_server, NULL);
	if(ret != 0) {
		printf("can not create autotest download thread! %s\n", strerror(ret));
		return -1;
	}

	while(!g_force_exit_signal) {
		if(g_force_exit_signal){
			printf("Receive force exit signal, exit!\n");
			if(gc_file_content)
			  free(gc_file_content);
			if(listenfd)
			  close(listenfd);

			for(;i < MAX_CLIENT; i++){
				if(connfd[i])
				  close(connfd[i]);
			}
			return 1;
		}
		sleep(5);
	}

	return 0;
}
