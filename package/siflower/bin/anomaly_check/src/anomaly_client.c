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

int main(void)
{
	int connect_fd;
	int ret;
	char snd_buf[1024];
	static struct sockaddr_un srv_addr;
	//create unix socket
	connect_fd = socket(PF_UNIX, SOCK_STREAM, 0);
	if(connect_fd < 0) {
		printf("cannot create communication socket");
		return 1;
	}
	srv_addr.sun_family = AF_UNIX;
	strcpy(srv_addr.sun_path,ANOMALY_DOMAIN);
	//connect server
	ret = connect(connect_fd, (struct sockaddr*)&srv_addr, sizeof(srv_addr));
	if(ret == -1) {
		printf("cannot connect to the server");	
		close(connect_fd);
		return 1;
	}
	memset(snd_buf, 0, 1024);
	snd_buf[0] = 0x01;
	//send command
	write(connect_fd, snd_buf, sizeof(snd_buf));
	//send info server
	memset(snd_buf, 0, 1024);
	strcpy(snd_buf, "find anomaly !");
	write(connect_fd, snd_buf, sizeof(snd_buf));
	close(connect_fd);
	return 0;
}
