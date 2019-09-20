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

#define ANOMALY_DOMAIN "/tmp/dnsblock.domain"
#define LEASE_CMD		"lease"
#define PCTL_CMD		"pctl"
#define ADD				"add"
#define DEL				"del"
#define SET 			"set"
#define BUF_CMD			0
#define BUF_SUBCMD		1
#define BUF_LEASE_MAC	2
#define BUF_PCTL_PARAM	8
#define CMD_LEASE_NUM	0
#define CMD_PCTL_NUM	1
#define SUBCMD_ADD		0
#define SUBCMD_DEL		1
#define SUBCMD_SET		2

int add_mac_to_buf(char *buf, char *mac){
	int ret = 0;
	if(strlen(mac) ==17){
		ret = sscanf(mac,"%2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx",buf,buf+1,buf+2,buf+3,buf+4,buf+5);
	}else{
		printf("Error mac format\n");
	}
	return ret < 6 ? -1 : 0;
}

int main(int argc, char **argv)
{
	int connect_fd;
	int ret;
	char buf[128];
	static struct sockaddr_un srv_addr;
	char *cmd = *++argv;

	if(cmd != NULL){
		memset(buf, 0, sizeof(buf));
		if(strncmp(cmd, LEASE_CMD,sizeof(LEASE_CMD)) == 0){
			buf[BUF_CMD] = CMD_LEASE_NUM;
			char *subcmd = *(argv+1);
			char *mac = *(argv+2);
			printf("subcmd %s,mac %s\n",subcmd, mac);
			if(strncmp(subcmd, ADD,sizeof(ADD)) == 0){
				buf[BUF_SUBCMD] = SUBCMD_ADD;
				ret = add_mac_to_buf(buf+BUF_LEASE_MAC, mac);
				if(ret < 0){
					printf("Error mac format\n");
					return 0;
				}
			} else if(strncmp(subcmd, DEL,sizeof(DEL)) == 0) {
				buf[BUF_SUBCMD] = SUBCMD_DEL;
				ret = add_mac_to_buf(buf+BUF_LEASE_MAC, mac);
				if(ret < 0){
					printf("Error mac format\n");
					return 0;
				}
			}else{
				printf("Lease: not support subcmd\n");
				return 0;
			}

		}else if(strncmp(cmd, PCTL_CMD,sizeof(PCTL_CMD)) == 0){
			buf[BUF_CMD] = CMD_PCTL_NUM;
			char *subcmd = *(argv+1);
			char *mac = *(argv+2);
			printf("subcmd %s,mac %s\n",subcmd, mac);
			if(strncmp(subcmd, SET,sizeof(SET)) == 0){
				char *param = *(argv+3);
				buf[BUF_SUBCMD] = SUBCMD_SET;
				ret = add_mac_to_buf(buf+BUF_LEASE_MAC, mac);
				if(ret < 0){
					printf("Error mac format\n");
					return 0;
				}
				ret = sscanf(param, "%hhd",buf+BUF_PCTL_PARAM);
				if(ret < 1){
					printf("Error param for setting type\n");
					return 0;
				}
			} else if(strncmp(subcmd, DEL,sizeof(DEL)) == 0) {
				buf[BUF_SUBCMD] = SUBCMD_DEL;
				ret = add_mac_to_buf(buf+BUF_LEASE_MAC, mac);
				if(ret < 0){
					printf("Error mac format\n");
					return 0;
				}
			}else{
				printf("Lease: not support subcmd\n");
				return 0;
			}

		}else{
			printf("Not support cmd\n");
			return 0;
		}
	}
	//create unix socket
	//printf("create connect ot server\n");
	connect_fd = socket(PF_UNIX, SOCK_STREAM, 0);
	if(connect_fd < 0) {
		printf("cannot create communication socket");
		return 1;
	}
	srv_addr.sun_family = AF_UNIX;
	strcpy(srv_addr.sun_path,ANOMALY_DOMAIN);
	//connect server
	//printf("connect ot server\n");
	ret = connect(connect_fd, (struct sockaddr*)&srv_addr, sizeof(srv_addr));
	if(ret == -1) {
	   	printf("cannot connect to the server");
		close(connect_fd);
		return 1;
	}
	//send command
	//printf("write message to server\n");
	write(connect_fd, buf, sizeof(buf));
	printf("finish write message to server\n");
	//send info server
	close(connect_fd);
	return 0;
}
