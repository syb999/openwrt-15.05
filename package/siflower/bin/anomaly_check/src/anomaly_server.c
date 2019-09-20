#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netdb.h>
#include <poll.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

#define ANOMALY_DOMAIN "/tmp/anomaly_check.domain"
#define READ_FROM_CLIENT 0X01
#define WRITE_TO_CLIENT 0x02

int main(void)
{
	socklen_t clt_addr_len;
	int listen_fd;
	int com_fd;
	int ret;
	//int i;
	static char data_buf[1024];
	int len;
	struct sockaddr_un clt_addr;
	struct sockaddr_un srv_addr;
	listen_fd = socket(PF_UNIX, SOCK_STREAM, 0);
	if(listen_fd < 0) {
		perror("cannot create communication socket");
		return 1;
	}
	//set server addr_param
	srv_addr.sun_family = AF_UNIX;
	strcpy(srv_addr.sun_path,ANOMALY_DOMAIN);
	unlink(ANOMALY_DOMAIN);
	//bind sockfd & addr
	ret = bind(listen_fd, (struct sockaddr*)&srv_addr, sizeof(srv_addr));
	if(ret == -1) {
		perror("cannot bind server socket");
		close(listen_fd);
		unlink(ANOMALY_DOMAIN);
		return 1;
	}
	//listen sockfd
	ret = listen(listen_fd,1);
	if(ret == -1) {
		perror("cannot listen the client connect request");
		close(listen_fd);
		unlink(ANOMALY_DOMAIN);
		return 1;
	}
	while(1) {
		//have connect request use accept
		len = sizeof(clt_addr);
		com_fd = accept(listen_fd,(struct sockaddr*)&clt_addr,&len);
		if(com_fd < 0) {
			perror("cannot accept client connect request");
			close(listen_fd);
			unlink(ANOMALY_DOMAIN);
			return 1;
		}
		//read and printf sent client info
		printf("\nReceive from client:\n");	
		memset(data_buf, 0, 1024);
		read(com_fd, data_buf, sizeof(data_buf));
		printf(" Request is %d\n", data_buf[0]);
		//Read from client
		if(data_buf[0] == READ_FROM_CLIENT) {
			memset(data_buf, 0, 1024);
			read(com_fd, data_buf, sizeof(data_buf));
			printf("The data read from client is : %s\n",data_buf);
			printf("close the led!\n");
			system("led.sh clear led1");
			system("echo anomaly > /tmp/anomaly_check");
		}
		//Send to client
		if(data_buf[0] == WRITE_TO_CLIENT) {
			memset(data_buf, 0, 1024);
			strcpy(data_buf, "message from server!!");
			write(com_fd, data_buf, sizeof(data_buf));
			printf("The data send to client is %s\n:",data_buf);
		}
		memset(data_buf, 0, 1024);
		close(com_fd);
	}
	
	//close(listen_fd);
	//unlink(ANOMALY_DOMAIN);
	//return 0;
}
