#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>

#include <linux/genetlink.h>
#include "netlink_demo.h"


/*
 *  * Generic macros for dealing with netlink sockets. Might be duplicated
 *   * elsewhere. It is recommended that commercial grade applications use
 *    * libnl or libnetlink and use the interfaces provided by the library
 *     */
#define GENLMSG_DATA(glh)	((void *)(NLMSG_DATA(glh) + GENL_HDRLEN))
#define GENLMSG_PAYLOAD(glh)	(NLMSG_PAYLOAD(glh, 0) - GENL_HDRLEN)
#define NLA_DATA(na)		((void *)((char*)(na) + NLA_HDRLEN))
#define NLA_PAYLOAD(len)	(len - NLA_HDRLEN)

#define MAX_MSG_SIZE	512
#define DEBUG			1

#define LOG(fmt, arg...) {			\
	if (DEBUG) {				\
		printf(fmt, ##arg);		\
	}					\
}

struct msgtemplate {
	struct nlmsghdr n;
	struct genlmsghdr g;
	char buf[MAX_MSG_SIZE];
};


/*
 * * Create a raw netlink socket and bind
 *  */
static int demo_create_nl_socket(int protocol)
{
	int fd;
	struct sockaddr_nl local;

	/* create socket */
	fd = socket(AF_NETLINK, SOCK_RAW, protocol);
	if (fd < 0)
	  return -1;

	memset(&local, 0, sizeof(local));
	local.nl_family = AF_NETLINK;
	local.nl_pid = getpid();

	/* bind with pid */
	if (bind(fd, (struct sockaddr *) &local, sizeof(local)) < 0)
	  goto error;

	return fd;

error:
	close(fd);
	LOG("User space %s : create netlink socket fail\n", __func__);
	return -1;
}


static int demo_send_cmd(int sd, __u16 nlmsg_type, __u32 nlmsg_pid,
			__u8 genl_cmd, __u16 nla_type,
			void *nla_data, int nla_len)
{
	struct nlattr *na;
	struct sockaddr_nl nladdr;
	int r, buflen;
	char *buf;

	struct msgtemplate msg;

	/* construct a netlink msg */
	msg.n.nlmsg_len = NLMSG_LENGTH(GENL_HDRLEN);
	msg.n.nlmsg_type = nlmsg_type;
	msg.n.nlmsg_flags = NLM_F_REQUEST;
	msg.n.nlmsg_seq = 0;
	msg.n.nlmsg_pid = nlmsg_pid;
	msg.g.cmd = genl_cmd;
	msg.g.version = SF_GENL_VERSION;
	na = (struct nlattr *) GENLMSG_DATA(&msg);
	na->nla_type = nla_type;
	na->nla_len = nla_len + 1 + NLA_HDRLEN;
	memcpy(NLA_DATA(na), nla_data, nla_len);
	msg.n.nlmsg_len += NLMSG_ALIGN(na->nla_len);

	buf = (char *) &msg;
	buflen = msg.n.nlmsg_len;
	memset(&nladdr, 0, sizeof(nladdr));
	nladdr.nl_family = AF_NETLINK;

	/* send till end */
	while ((r = sendto(sd, buf, buflen, 0, (struct sockaddr *) &nladdr,
						sizeof(nladdr))) < buflen) {
		if (r > 0) {
			LOG("User space %s : send cmd times\n", __func__);
			buf += r;
			buflen -= r;
		} else if (errno != EAGAIN){
			LOG("User space %s : send cmd error %d\n", __func__,errno);
			return -1;
		}
	}

	return 0;
}


/*
 *  * Probe the controller in genetlink to find the family id
 *   * for the SF_GEN_CTRL family
 *    */
static int demo_get_family_id(int sd)
{
	struct msgtemplate ans;

	char name[100];
	int id = 0, ret;
	struct nlattr *na;
	int rep_len;

	/* gen family id by family name */
	strcpy(name, SF_GENL_NAME);
	ret = demo_send_cmd(sd, GENL_ID_CTRL, getpid(), CTRL_CMD_GETFAMILY,
				CTRL_ATTR_FAMILY_NAME, (void *)name, strlen(SF_GENL_NAME)+1);
	if (ret < 0){
		LOG("User space %s : send message error\n", __func__);
		return 0;
	}

	/* receive kernel message */
	rep_len = recv(sd, &ans, sizeof(ans), 0);
	if (ans.n.nlmsg_type == NLMSG_ERROR || (rep_len < 0) || !NLMSG_OK((&ans.n), rep_len)){
		LOG("User space %s : receive message error rep_len %d ans.n.nlmsg_type %d\n", __func__, rep_len, ans.n.nlmsg_type);
		return 0;
	}

	/* parse family id */
	na = (struct nlattr *) GENLMSG_DATA(&ans);
	na = (struct nlattr *) ((char *) na + NLA_ALIGN(na->nla_len));
	if (na->nla_type == CTRL_ATTR_FAMILY_ID) {
		id = *(__u16 *) NLA_DATA(na);
	}

	return id;
}


int demo_msg_check(struct msgtemplate msg, int rep_len)
{
	if (msg.n.nlmsg_type == NLMSG_ERROR || !NLMSG_OK((&msg.n), rep_len)) {
		struct nlmsgerr *err = NLMSG_DATA(&msg);
		fprintf(stderr, "fatal reply error,  errno %d\n", err->error);
		LOG("User space : received error message len %d,nlmsg type %d,flags %d,pid %d\n", (err->msg).nlmsg_len,(err->msg).nlmsg_type,(err->msg).nlmsg_flags,(err->msg).nlmsg_pid);
		return -1;
	}

	return 0;
}

static int kthread_msg = 0;

void demo_msg_recv_analysis(int sd, int num)
{
	int rep_len;
	int len;
	struct nlattr *na;
	struct msgtemplate msg;
	char *string;
	int *p;

	while (num--) {

		/* receive echo message */
		rep_len = recv(sd, &msg, sizeof(msg), 0);
		if (rep_len < 0 || demo_msg_check(msg, rep_len) < 0) {
			fprintf(stderr, "nonfatal reply error: errno %d\n", errno);
			continue;
		}

		rep_len = GENLMSG_PAYLOAD(&msg.n);
		na = (struct nlattr *) GENLMSG_DATA(&msg);
		len = 0;

		/* one msg may include many attrs，so that read in a circle */
		while (len < rep_len) {
			len += NLA_ALIGN(na->nla_len);
			switch (na->nla_type) {
				case SF_CMD_ATTR_ECHO:
					/* receive echo string message */
					string = (char *) NLA_DATA(na);
					printf("User space : get echo reply:%s\n", string);
					break;
				case SF_CMD_ATTR_KTHREAD_RUN:
					/* receive echo string message */
					p = (int *) NLA_DATA(na);
					printf("User space : get echo reply:0x%2x\n", *p);
					kthread_msg = *p;

					break;
				default:
					fprintf(stderr, "Unknown nla_type %d\n", na->nla_type);
			}
			na = (struct nlattr *) (GENLMSG_DATA(&msg) + len);
		}
	}
}


int main(int argc, char* argv[])
{
	int nl_fd;
	int nl_family_id;
	int my_pid;
	int ret;

	int data;
	char *str;
	int i = 0;
	char string[256] = {0};

	if (argc < 3) {
		printf("invalid input! usage: demo <char str> <int data>\n");
		return 0;
	}

	/* create netlink socket */
	nl_fd = demo_create_nl_socket(NETLINK_GENERIC);
	if (nl_fd < 0) {
		fprintf(stderr, "failed to create netlink socket\n");
		return 0;
	}

	/* get family id */
	nl_family_id = demo_get_family_id(nl_fd);
	if (!nl_family_id) {
		fprintf(stderr, "Error getting family id, errno %d\n", errno);
		goto out;
	}
	//LOG("User space : get family name %s, id %d\n",SF_GENL_NAME, nl_family_id);

	my_pid = getpid();
	str = argv[1];
	data = atoi(argv[2]);

	if (!memcmp(str, "kthread_create", 14)){
		LOG("User space : send message for create kthread\n");
		sprintf(string, "%d", data);
		ret = demo_send_cmd(nl_fd, nl_family_id, my_pid, SF_CMD_GENERIC,
					SF_CMD_ATTR_KTHREAD_RUN, (void *)string, strlen(string) + 1);
		if (ret < 0) {
			fprintf(stderr, "failed to send kthread create message\n");
			goto out;
		}
		demo_msg_recv_analysis(nl_fd, 1);

		sleep(60);
		LOG("User space : send message for stop kthread after 60s\n");
		ret = demo_send_cmd(nl_fd, nl_family_id, my_pid, SF_CMD_GENERIC,
					SF_CMD_ATTR_KTHREAD_STOP, (void *)&kthread_msg, sizeof(int));
		if (ret < 0) {
			fprintf(stderr, "failed to send kthread stop message\n");
			goto out;
		}
		goto out;
	}

	for (i = 0; i < 100; i ++){
		sprintf(string, "message %d ", i);
		strcat(string, str);
		/* send test string message */
		//LOG("User space : send test string message, %s\n", string);
		ret = demo_send_cmd(nl_fd, nl_family_id, my_pid, SF_CMD_GENERIC,
					SF_CMD_ATTR_ECHO, (void *)string, strlen(string) + 1);
		if (ret < 0) {
			fprintf(stderr, "failed to send echo cmd\n");
			goto out;
		}
	}
	demo_msg_recv_analysis(nl_fd, 100);

out:
	close(nl_fd);
	return 0;
}
