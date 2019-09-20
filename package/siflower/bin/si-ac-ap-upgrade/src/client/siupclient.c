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


#define DOWNLOAD_PORT                   1125
#define MSG_BUFFER                      1024
#define BLOCK_SIZE                      14600//14*1024

const char * hello = "Hello";

int download_firmware(char* server_ip)
{
	int32_t fd;
	struct sockaddr_in srv_addr;
	FILE *fp = NULL;
	char buf[BLOCK_SIZE] = {0};
	int32_t recvlen = 0, writelen = 0, val = 1;
	struct timeval timeout = {3, 0};

	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd < 0)
	{
		printf("[client] %s, create socket fail!\n", __func__);
		return -1;
	}

	if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &val, sizeof(val))) {
		printf("[client] %s, setsockopt error!\n", __func__);
		goto SOCKET_ERR;
	}

	setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(struct timeval));
	bzero(&srv_addr, sizeof(srv_addr));
	srv_addr.sin_family = AF_INET;
	srv_addr.sin_port = htons(DOWNLOAD_PORT);
	srv_addr.sin_addr.s_addr = inet_addr(server_ip);
	printf("[client] %s, download server addr: [%s:%d]\n", __func__, server_ip, DOWNLOAD_PORT);

	if (connect(fd, (struct sockaddr*)&srv_addr, sizeof(srv_addr)) < 0)
	{
		printf("[client] %s, connect to server error!\n", __func__);
		goto SOCKET_ERR;
	}

	printf("[client] %s, connect to server done!\n", __func__);
	// download filename to autotest server
	// if (send(fd, hello, strlen(hello), 0) < 0){
	// 	printf("[client] %s, send message to server error! errno=%s\n", __func__,  strerror(errno));
	// 	goto SOCKET_ERR;
	// }

	// printf("[client] %s, send hello done!\n", __func__);
	// open file to write, it will touch this file when not exist.
	fp = fopen("/tmp/firmware.img", "w");
	if (fp == NULL){
		printf("[server] %s, open file error!\n", __func__);
		goto SOCKET_ERR;
	}

	while(1)
	{
		recvlen = recv(fd, buf, sizeof(buf), MSG_WAITALL);
		// recvlen = recv(fd, buf, sizeof(buf), 0);
		if (recvlen < 0) {
			printf("[client] %s, receive data error!, errno=%s\n", __func__, strerror(errno));
			goto FILE_ERR;
		}
		else if(recvlen == 0){
			printf("[client] %s, receive data 0!, errno=%s\n", __func__, strerror(errno));
			break;
		}

		writelen = fwrite(buf, sizeof(char), recvlen, fp);
		if (writelen < recvlen){
			printf("[server] %s, write data error!\n", __func__);
			goto FILE_ERR;
		}

		// printf("[client] %s, receive data %d!\n", __func__, recvlen);
		if(recvlen < BLOCK_SIZE){
			printf("[client] %s, receive last part %d!\n", __func__, recvlen);
			break;
		}
		memset(buf, 0, sizeof(buf));
	}

	printf("[client] %s, receive data done!\n", __func__ );
	fclose(fp);
	close(fd);
	return 0;

FILE_ERR:
	fclose(fp);

SOCKET_ERR:
	close(fd);

	return -1;
}

int main(int argc, char *argv[])
{
	if(argc < 2){
		return -1;
	}
	char * download_ip = argv[1];
	printf("download ip is %s\n",download_ip);

	if(download_firmware(download_ip) < 0)
	  return -1;
	return 0;
}
