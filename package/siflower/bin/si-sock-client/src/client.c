/*
 * =====================================================================================
 *
 *Filename:  client.c
 *
 *Description:  socket IPC example: client

 *
 *Version:  1.0
 *Created:  2015年07月16日 10时55分30秒
 *Revision:  none
 *Compiler:  gcc
 *
 *Author:  Franklin , franklin.wang@siflower.com.cn
 *Company:  Shanghai Siflower Communication Technology Co.,Ltd
 *
 * =====================================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <syslog.h>
#define UNIX_DOMAIN "/tmp/UNIX.domain"

int32_t main(int32_t argc, char *argv[])
{
    int32_t connect_fd;
    struct sockaddr_un un_addr;
    struct sockaddr_in in_addr;
    struct sockaddr* con_addr = NULL;
    int32_t sock_size = 0;
    char snd_buf[2048];
    int32_t ret = 0;
    int32_t tmp_write = 0;
    int32_t fake_message = 0;
    int32_t use_host_port = 0;
    int32_t need_callback = 0;
    

    memset(snd_buf, 0, 2048);
    if(argc > 2){
        int32_t i;
        for(i = 1; i < argc ;i++){
            if(i == 1){
                strcpy(snd_buf, argv[i]);
            }else{
                strcat(snd_buf, " ");
                strcat(snd_buf, argv[i]);
            }
            if(!strcmp(argv[i], "need-callback"))
                need_callback = 1;
        }
    }else if(argc == 2 && !strcmp(argv[1],"uhttpd")){
        use_host_port = 1;
        need_callback = 1;
    }else{
        fake_message = 1;
    }

    //create client socket
    if(use_host_port){
        connect_fd = socket(PF_INET, SOCK_STREAM, 0);
    }else{
        connect_fd = socket(PF_UNIX, SOCK_STREAM, 0);
    }
    if(connect_fd < 0)
    {
        syslog(LOG_CRIT,"[CLIENT]client create socket failed");
        return 1;
    }
    //set server sockaddr_un
    if(use_host_port){
        memset(&in_addr, 0, sizeof(struct sockaddr_in));
        in_addr.sin_family = AF_INET;
        in_addr.sin_port = htons(1688);
        if(inet_pton(AF_INET, "127.0.0.1", &in_addr.sin_addr) <= 0){
            syslog(LOG_CRIT,"[CLIENT] inet_pton error for localhost\n");
            close(connect_fd);
            return 1;
        }
        con_addr = (struct sockaddr *)&in_addr;
        sock_size = sizeof(struct sockaddr_in);
    }else{
        un_addr.sun_family = AF_UNIX;
        strcpy(un_addr.sun_path, UNIX_DOMAIN);
        con_addr = (struct sockaddr *)&un_addr;
        sock_size = sizeof(struct sockaddr_un);
    }

    //connect to server
    ret = connect(connect_fd, con_addr, sock_size);
    if(ret == -1)
    {
        syslog(LOG_CRIT,"[CLIENT]connect to server failed!");
        close(connect_fd);
        return 1;
    }

    //send message to server
    if(fake_message){
        strcpy(snd_buf, "[CLIENT]message from client for test\n");
    }else if(use_host_port){
        strcpy(snd_buf, "GET /cgi-bin/luci HTTP/1.1\r\n");
        strcat(snd_buf, "Host: 192.168.4.1\r\n");
        strcat(snd_buf, "Connection: keep-alive\r\n");
        strcat(snd_buf, "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\n");
        strcat(snd_buf, "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/37.0.2062.120 Chrome/37.0.2062.120 Safari/537.36\r\n");
        strcat(snd_buf, "Referer: http://192.168.4.1/\r\n");
        strcat(snd_buf, "Accept-Encoding: gzip, deflate\r\n");
        strcat(snd_buf, "Accept-Language: en-US,en;q=0.8\r\n");
        strcat(snd_buf, "\r\n");
    }
    syslog(LOG_CRIT, "[CLIENT]end message to server : %s\n", snd_buf);
    while(tmp_write < strlen(snd_buf)){
        tmp_write += write(connect_fd, snd_buf + tmp_write, strlen(snd_buf) - tmp_write);
    }
    //receive message from server
    syslog(LOG_CRIT,"[CLIENT]write over\n");
    if(need_callback){
        char rcv_buf[4096];
        memset(rcv_buf, 0, 4096);
        int32_t rcv_num = read(connect_fd, rcv_buf, 4096);
        syslog(LOG_CRIT,"[CLIENT]receive message from server (%d) :\n%s\n", rcv_num, rcv_buf);
    }

    close(connect_fd);
    syslog(LOG_CRIT,"[CLIENT]communication over\n");
    return 0;
}

