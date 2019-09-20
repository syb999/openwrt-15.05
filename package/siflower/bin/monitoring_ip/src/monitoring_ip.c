#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/if.h>
#include <stdio.h>
#include <netinet/in.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <arpa/inet.h>
#include <signal.h>

int running = 1;

void parseBinaryNetlinkMessage(struct nlmsghdr *nh) {
    int len = nh->nlmsg_len - sizeof(*nh);
    struct ifinfomsg *ifi;

    if (sizeof(*ifi) > (size_t) len) {
        printf("Got a short RTM_NEWLINK message\n");
        return;
    }

    ifi = (struct ifinfomsg *)NLMSG_DATA(nh);
    if ((ifi->ifi_flags & IFF_LOOPBACK) != 0) {
        return;
    }

    struct rtattr *rta = (struct rtattr *)
      ((char *) ifi + NLMSG_ALIGN(sizeof(*ifi)));
    len = NLMSG_PAYLOAD(nh, sizeof(*ifi));

    while(RTA_OK(rta, len)) {
        switch(rta->rta_type) {
          case IFLA_IFNAME:
          {
            char ifname[IFNAMSIZ];
	        char *action;
            snprintf(ifname, sizeof(ifname), "%s",(char *) RTA_DATA(rta));
            action = (ifi->ifi_flags & IFF_RUNNING) ? "up" : "down";
            printf("%s link %s \n",ifname,action);
          }
        }
        rta = RTA_NEXT(rta, len);
    }
}

void parseNetlinkAddrMsg(struct nlmsghdr *nlh, int new)
{
	struct ifaddrmsg *ifa = (struct ifaddrmsg *) NLMSG_DATA(nlh);
	struct rtattr *rth = IFA_RTA(ifa);
	int rtl = IFA_PAYLOAD(nlh);
	char cmd[50];
	char ip[18];

	while (rtl && RTA_OK(rth, rtl)) {
	    if (rth->rta_type == IFA_LOCAL) {
		uint32_t ipaddr = htonl(*((uint32_t *)RTA_DATA(rth)));
		char name[IFNAMSIZ];
		if_indextoname(ifa->ifa_index, name);
        	if (new && (strncmp("br-lan",name, 6) == 0)){
				sprintf(ip,"%d.%d.%d.%d",(ipaddr >> 24) & 0xff,(ipaddr >> 16) & 0xff,(ipaddr >> 8) & 0xff,ipaddr & 0xff);
				if (strncmp("192.168.4.251",ip,13) != 0){
				sprintf(cmd,"/bin/sh /bin/dhcp.sh");
				system(cmd);
				}
	    	}
	   }
	    rth = RTA_NEXT(rth, rtl);
	}
}

int main(int argc, char* argv[])
{
    struct sockaddr_nl addr;
    int sock, len;
    char buffer[4096];
    struct nlmsghdr *nlh;
    if ((sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_ROUTE)) == -1) {
        perror("couldn't open NETLINK_ROUTE socket");
        return 1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_groups = RTMGRP_LINK | RTMGRP_IPV4_IFADDR;

    if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
        perror("couldn't bind");
        return 1;
    }

    while (running && (len = recv(sock, buffer, 4096, 0)) > 0) {
        nlh = (struct nlmsghdr *)buffer;
        while ((NLMSG_OK(nlh, len)) && (nlh->nlmsg_type != NLMSG_DONE)) {
            if (nlh->nlmsg_type == RTM_NEWADDR) {
				parseNetlinkAddrMsg(nlh, 1);
            }else if(nlh->nlmsg_type == RTM_DELADDR){
				parseNetlinkAddrMsg(nlh, 0);
            }else if (nlh->nlmsg_type == RTM_NEWLINK){
				parseBinaryNetlinkMessage(nlh);
			}
            nlh = NLMSG_NEXT(nlh, len);
        }
    }
	close(sock);
    return 0;
}
