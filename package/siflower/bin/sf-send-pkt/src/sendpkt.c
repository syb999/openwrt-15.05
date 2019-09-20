#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <regex.h>
#include <unistd.h>
#include <linux/rtnetlink.h>
#include <linux/netlink.h>
#include <linux/genetlink.h>
#include <netinet/in.h>
#include <errno.h>
#include <syslog.h>
#include <libwebsockets.h>
#include <lws_config.h>

typedef struct rtnl_handle
{
    int         fd;
    struct sockaddr_nl  local;
    struct sockaddr_nl  peer;
    __u32           seq;
    __u32           dump;
	__u16	family_id;
} rtnl_handle;

#define MAX_MSG_SIZE			4096

typedef struct msgtemplate {
	struct nlmsghdr n;
	struct genlmsghdr g;
	char data[MAX_MSG_SIZE];
} msgtemplate_t;

struct UserContext{
	uint32_t status;
	uint32_t close;
	struct libwebsocket *wsi;
    struct libwebsocket_context *ct;
};

enum CloudSubClientError{
	WS_CLIENT_OK,
	WS_CLIENT_CONNECT_ESTABLISH,
	WS_CLIENT_CONTEXT_FAIL,
	WS_CLIENT_CONNECT_FAIL,
	WS_CLIENT_HEARTBEAT_TIMEOUT,
	WS_CLIENT_CONNECTION_ERR,
	WS_CLIENT_CONNECTION_CLOSED,
	WS_CLIENT_WS_PATH_FAIL
};

#define GENLMSG_DATA(glh)       ((void *)(NLMSG_DATA(glh) + GENL_HDRLEN))
#define NLA_DATA(na)            ((void *)((char *)(na) + NLA_HDRLEN))
#define NLA_NEXT(na)			((void *)((char *)(na) + NLA_ALIGN(na->nla_len)))
#define TOCHAR(n)				(n>0x9 ? n+0x37 : n+0x30)

#define IP_PKT              0
#define IP_CMD              1
#define SF_TS_PKT_CMD       2

#define ATTR_NEXT(attr) (struct nlattr *)(((char *)attr) + NLA_ALIGN(attr->nla_len))
#define NDA_RTA(r)			((struct rtattr*)(((char*)(r)) + NLMSG_ALIGN(sizeof(struct ndmsg))))
#define LOG(X,...) syslog(LOG_CRIT,X,##__VA_ARGS__)
#define WS_USE_SSL 2

struct UserContext ucontext;
struct rtnl_handle gnrtl;
char SF_WS_HOST[64];
char SF_WS_ADDRESS[64];
int SF_WS_PORT;
char *SF_WS_FAKE_ORIGIN = NULL;
char WSPATH[64] = "/v1/websocketNew";
int8_t g_force_exit_signal = 0;
uint32_t num = 0;

int genl_send_msg(int fd, u_int16_t nlmsg_type, u_int32_t nlmsg_pid, u_int8_t genl_cmd, u_int8_t genl_version, u_int16_t nla_type, void *nla_data, int nla_len);

static int32_t
callback_sf_websocket(struct libwebsocket_context *this,
			struct libwebsocket *wsi,
			enum libwebsocket_callback_reasons reason,
					       void *user, void *in, size_t len)
{
    struct UserContext *userContext = NULL;
    void *userData = NULL;
	int ret;
	int8_t cmd;
	switch (reason) {
    case LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER:
        break;

	case LWS_CALLBACK_CLIENT_ESTABLISHED:
		LOG("callback_sf_websocket: LWS_CALLBACK_CLIENT_ESTABLISHED\n");
        userData = libwebsockets_get_protocol(wsi)->user;
        if(userData != NULL) userContext = (struct UserContext*)userData;
        if(userContext != NULL){
            userContext->status = WS_CLIENT_CONNECT_ESTABLISH;
			userContext->wsi = wsi;
			userContext->close = 0;
        }
		cmd = 1;
		ret = genl_send_msg(gnrtl.fd, gnrtl.family_id, 0, SF_TS_PKT_CMD, 1, IP_CMD, (void *)&cmd, 1);
		if(ret < 0){
			LOG("sf-ts send cmd to kernel fail");
		}
		break;

	case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
		LOG("LWS_CALLBACK_CLIENT_CONNECTION_ERROR\n");
        userData = libwebsockets_get_protocol(wsi)->user;
        if(userData != NULL) userContext = (struct UserContext*)userData;
        if(userContext != NULL) {
			userContext->status = WS_CLIENT_CONNECTION_ERR;
			userContext->close = 1;
		}
		cmd = 0;
		ret = genl_send_msg(gnrtl.fd, gnrtl.family_id, 0, SF_TS_PKT_CMD, 1, IP_CMD, (void *)&cmd, 1);
        break;

	case LWS_CALLBACK_CLOSED:
        LOG("LWS_CALLBACK_CLOSED\n");
        userData = libwebsockets_get_protocol(wsi)->user;
        if(userData != NULL) userContext = (struct UserContext*)userData;
        if(userContext != NULL){
		   	userContext->status = WS_CLIENT_CONNECTION_CLOSED;
			userContext->close = 1;
		}
		cmd = 0;
		ret = genl_send_msg(gnrtl.fd, gnrtl.family_id, 0, SF_TS_PKT_CMD, 1, IP_CMD, (void *)&cmd, 1);
		break;

	case LWS_CALLBACK_CLIENT_RECEIVE:
//		cmd = 1;
//		 genl_send_msg(gnrtl.fd, gnrtl.family_id, 0, SF_TS_PKT_CMD, 1, IP_CMD, (void *)&cmd, 1);
		break;

	case LWS_CALLBACK_CLIENT_CONFIRM_EXTENSION_SUPPORTED:
		break;

	default:
		break;
	}

	return 0;
}

static struct libwebsocket_protocols protocols[] = {
	{
        "http-only",
		callback_sf_websocket,
		32772,
		32772, //max buffer size per packet
        2,
	},
	{ NULL, NULL, 0, 0 } /* end */
};

void sighandler(int32_t  sig)
{
	g_force_exit_signal = 1;
}


int32_t runWsSubClient(struct UserContext *uct)
{
    int32_t ret = 0;
    struct lws_context_creation_info info;
    struct libwebsocket *wsi_client;
    struct libwebsocket_context *context;

    uct->status = WS_CLIENT_OK;

    //init context create information
    memset(&info, 0, sizeof(info));
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols;
    //access it use libwebsockets_get_protocol(wsi)->user
    info.protocols[0].user = (void *)(uct);
    info.extensions = libwebsocket_get_internal_extensions();
    info.gid = -1;
    info.uid = -1;

    /* create a client websocket using cloud websocket protocl */
    context = libwebsocket_create_context(&info);
    if (context == NULL) {
        LOG("creating libwebsocket context failed\n");
        ret = WS_CLIENT_CONTEXT_FAIL;
        goto bail;
    }
	uct->ct = context;
    wsi_client = libwebsocket_client_connect(context,
            SF_WS_ADDRESS,//address
            SF_WS_PORT,//port
            WS_USE_SSL,//ifuse ssl
            WSPATH,//location path
            SF_WS_HOST,  //host
            SF_WS_FAKE_ORIGIN, //origin fake
            protocols[0].name,  //protocols
            -1                  //user latest
            );


	if (wsi_client == NULL) {
		LOG("libwebsocket connect failed\n");
		ret = WS_CLIENT_CONNECT_FAIL;
        goto bail;
	}
	int count_j = 0;
	while(1){
		if (uct->status == WS_CLIENT_OK){
			count_j++;
			libwebsocket_service(context, 3);
			if (count_j > 20)
				goto bail;
			usleep(250000);
		}else{
			break;
		}
	}

	/*
	int32_t n = 0;
    //half time of CLOUD_HEARTBEART_TIME_S,almose 20s check interval if no data happen
    int32_t checkIntervalN = (CLOUD_HEARTBEART_TIME_S * 1000 / WEBSOCKET_SERVICE_INTERVAL_MS) / 2;
    int i = 0;
	while (n >= 0 && !g_force_exit_signal) {
        if(uct->status != WS_CLIENT_CONNECT_ESTABLISH){
            ret = uct->status;
            break;
        }
        i++;
        //check heartbeat
        if(uct->status == WS_CLIENT_CONNECT_ESTABLISH){
            if((i + checkIntervalN) % checkIntervalN == 0){
                int32_t timeNow = getUptime();
                LOG("check time now--%d \n",timeNow);
                if(timeNow - uct->heartbeatUpdateTime > (CLOUD_HEARTBEART_TIME_S + 10)){
                    ret = WS_CLIENT_HEARTBEAT_TIMEOUT;
                    break;
                }
            };
        }
        n = libwebsocket_service(context, WEBSOCKET_SERVICE_INTERVAL_MS);
        if (n < 0) continue;
    }
	*/
	return 0;
bail:
	//wsi_client will be freed in this function
    libwebsocket_context_destroy(context);
    return ret;

}

int rtnl_open(struct rtnl_handle *rth, unsigned subscriptions, int type)
{
    int addr_len;

    memset(rth, 0, sizeof(rtnl_handle));

    rth->fd = socket(PF_NETLINK, SOCK_RAW, type);
    if (rth->fd < 0) {
        perror("Cannot open netlink socket");
        return -1;
    }

    memset(&rth->local, 0, sizeof(rth->local));
    rth->local.nl_family = AF_NETLINK;
    rth->local.nl_groups = subscriptions;

    if (bind(rth->fd, (struct sockaddr*)&rth->local, sizeof(rth->local)) < 0) {
        perror("Cannot bind netlink socket");
        return -1;
    }
    addr_len = sizeof(rth->local);
    if (getsockname(rth->fd, (struct sockaddr*)&rth->local,
                (socklen_t *) &addr_len) < 0) {
        perror("Cannot getsockname");
        return -1;
    }
    if (addr_len != sizeof(rth->local)) {
        fprintf(stderr, "Wrong address length %d\n", addr_len);
        return -1;
    }
    if (rth->local.nl_family != AF_NETLINK) {
        fprintf(stderr, "Wrong address family %d\n", rth->local.nl_family);
        return -1;
    }
    rth->seq = time(NULL);
    return 0;
}

void rtnl_close(struct rtnl_handle *rth)
{
    close(rth->fd);
}

int genl_send_msg(int fd, u_int16_t nlmsg_type, u_int32_t nlmsg_pid, u_int8_t genl_cmd, u_int8_t genl_version, u_int16_t nla_type, void *nla_data, int nla_len){
    struct nlattr *na;
	struct sockaddr_nl nladdr;
	int r, buflen;
	char *buf;
	msgtemplate_t msg;

	msg.n.nlmsg_len = NLMSG_LENGTH(GENL_HDRLEN);
	msg.n.nlmsg_type = nlmsg_type;
	msg.n.nlmsg_flags = NLM_F_REQUEST;
	msg.n.nlmsg_seq = 0;

	msg.n.nlmsg_pid = nlmsg_pid;
	msg.g.cmd = genl_cmd;
	msg.g.version = genl_version;
	na = (struct nlattr *) GENLMSG_DATA(&msg);
	na->nla_type = nla_type;
	na->nla_len = nla_len + 1 + NLA_HDRLEN;
	memcpy(NLA_DATA(na), nla_data, nla_len);
	msg.n.nlmsg_len += NLMSG_ALIGN(na->nla_len);

	buf = (char *) &msg;
	buflen = msg.n.nlmsg_len;
	memset(&nladdr, 0, sizeof(nladdr));
	nladdr.nl_family = AF_NETLINK;

	while ((r = sendto(fd, buf, buflen, 0, (struct sockaddr *) &nladdr, sizeof(nladdr))) < buflen) {
		if (r > 0) {
			buf += r;
			buflen -= r;
		}else if(errno != EAGAIN){
			return -1;
		}
	}
	LOG("Send genl message ok!\n");
	return 0;
}

int find_group(struct nlattr *nlattr, char *group){
	struct nlattr *gattr = (struct nlattr *)(((char *)nlattr) + NLA_HDRLEN);
	int nl_len = nlattr->nla_len - NLA_HDRLEN;
	while(1){
		if(strncmp(((char *)gattr)+3*NLA_HDRLEN+4, group, strlen(group))== 0){
			return *((int *)((char *)gattr + 2*NLA_HDRLEN));
		}
		nl_len -= NLA_ALIGN(gattr->nla_len);
		if( nl_len > 0){
			gattr = ATTR_NEXT(gattr);
		}else{
			LOG("find group fail\n");
			return -1;
		}
	}
}

int get_genl_group(struct rtnl_handle *rth, char *family, char *group){
	msgtemplate_t genlmsg;
	int ret;
	struct nlattr *nlattr;
	int rc_len;
	int nl_len;

	ret = genl_send_msg(rth->fd, GENL_ID_CTRL, 0, CTRL_CMD_GETFAMILY, 1, CTRL_ATTR_FAMILY_NAME,
		   	family, strlen(family)+1);
	if(ret){
		LOG("Send genl fail\n");
		goto fail;
	}
	rc_len = recv(rth->fd, &genlmsg, sizeof(genlmsg), 0);

	if(rc_len < 0){
		LOG("Receive error!\n");
		goto fail;
	}

	if(genlmsg.n.nlmsg_type == NLMSG_ERROR || !NLMSG_OK((&genlmsg.n), rc_len)){
		LOG("Genlmsg type is %d, rc_len is %d, msg len is %d\n", genlmsg.n.nlmsg_type, rc_len, genlmsg.n.nlmsg_len);
		goto fail;
	}

	if(genlmsg.n.nlmsg_type == GENL_ID_CTRL){
		LOG("nl type ok\n");
		if(genlmsg.g.cmd == CTRL_CMD_NEWFAMILY){
			nlattr = (struct nlattr *)GENLMSG_DATA(&genlmsg);
			nl_len = genlmsg.n.nlmsg_len - NLMSG_HDRLEN - NLA_HDRLEN;
			if(nlattr->nla_type == CTRL_ATTR_FAMILY_NAME){
				if(strncmp(((char *)nlattr)+NLA_HDRLEN, family, strlen(family)) == 0){
					nlattr = ATTR_NEXT(nlattr);
					rth->family_id = *((__u16 *)(NLA_DATA(nlattr)));
					LOG("return family is %d\n", rth->family_id);
				    while(1){
						nl_len -= NLA_ALIGN(nlattr->nla_len);
						if( nl_len <=0){
							LOG("Not find attr\n");
							goto fail;
						}
						nlattr = ATTR_NEXT(nlattr);
						if( nlattr->nla_type == CTRL_ATTR_MCAST_GROUPS){
							return find_group(nlattr, group);
						}else{
							continue;
						}
					}
				}
			}
		}
	}
fail:
	return -1;

}

static int sf_ts_genl(struct rtnl_handle *rth)
{

	int ret;
	int group;
	__u16 id;

	if(rtnl_open(rth, 0, NETLINK_GENERIC) < 0)
	{
		perror("Can't initialize rtnetlink socket");
		return -1;
	}
	group = get_genl_group(rth, "SF_TS_NL", "sf-ts-pkt");
	LOG("group number is %d\n", group);
	if (group < 0){
		goto err1;
	}

	rtnl_close(rth);
	id = rth->family_id;
	if (rtnl_open(rth, 1 << (group-1), NETLINK_GENERIC) < 0){
		perror("Can't initialize generic netlink\n");
		goto err1;
	}
	rth->family_id = id;
	return 0;
err1:
	rtnl_close(rth);

	return -1;
}
void reconnect(){
	int cmd = 0;

	if(ucontext.close == 1){
		libwebsocket_context_destroy(ucontext.ct);
	}
	runWsSubClient(&ucontext);
}

int32_t postMessageToUserbyws(char *buf,int32_t len)
{
	int ret = 0;
	int32_t  n = -1;
	int32_t data_len = len + LWS_SEND_BUFFER_POST_PADDING;
	int8_t cmd = 0;
	void *data;

	if(ucontext.status == WS_CLIENT_CONNECT_ESTABLISH){
		data = malloc(LWS_SEND_BUFFER_PRE_PADDING + data_len);
		memset(data,'\1',LWS_SEND_BUFFER_PRE_PADDING);
		memset(data+LWS_SEND_BUFFER_PRE_PADDING+data_len-LWS_SEND_BUFFER_POST_PADDING,'\1',LWS_SEND_BUFFER_POST_PADDING);
		memcpy(data+LWS_SEND_BUFFER_PRE_PADDING,buf,len);

		n = libwebsocket_write(ucontext.wsi, data + LWS_SEND_BUFFER_PRE_PADDING, data_len, LWS_WRITE_BINARY);
		if(n <= 0){
			LOG("ws post message fail\n");
			libwebsocket_service(ucontext.ct, 1);
			ret = -1;
		}
		free(data);
	}else{
	//	reconnect();
	}

	return ret;
}

void handle_netlink(struct rtnl_handle *rth){
	struct sockaddr_nl sanl;
	struct nlattr *nlattr;
	msgtemplate_t *genlmsg;
	socklen_t sanllen = sizeof(struct sockaddr_nl);
	int amt, ret, i=0, nl_len;
	char buf[2048], *buff;


	amt = recvfrom(rth->fd, buf, sizeof(buf), MSG_DONTWAIT, (struct sockaddr*)&sanl, &sanllen);
	if(amt < 0)
	{
		if(errno != EINTR && errno != EAGAIN)
		{
			fprintf(stderr, "%s: error reading netlink: %s.\n",
					__PRETTY_FUNCTION__, strerror(errno));
		}
		return;
	}

	if(amt == 0)
	{
		fprintf(stderr, "%s: EOF on netlink??\n", __PRETTY_FUNCTION__);
		return;
	}
	genlmsg = (msgtemplate_t *)buf;
	if(genlmsg->n.nlmsg_type == NLMSG_ERROR || !NLMSG_OK((&genlmsg->n), amt)){
		LOG("Genlmsg type is %d, amt is %d, msg len is %d\n", genlmsg->n.nlmsg_type, amt, genlmsg->n.nlmsg_len);
		return;
	}
	if(genlmsg->g.cmd == SF_TS_PKT_CMD){
		if(num % 100 == 0){
			LOG("cmd SF_TS_PKT_CMD\n");
		}
		num++;
		nlattr = (struct nlattr *)GENLMSG_DATA(genlmsg);
		nl_len = genlmsg->n.nlmsg_len - NLMSG_HDRLEN - GENL_HDRLEN - NLA_HDRLEN;
		buff = (char *)NLA_DATA(nlattr);
		if(nlattr->nla_type == IP_PKT){
			ret = postMessageToUserbyws(buff,nl_len);
		}
	}
			/*
	for(i=0;i < 8;i++){
		printf("%2hhx %2hhx %2hhx %2hhx\n",buff[i*4+0],buff[i*4+1],buff[i*4+2],buff[i*4+3]);
	}
	LOG( "ts send packet netlink event has finished!");
	*/
}

int main(int argc, char *argv[])
{
    int ret = 0, n = 0;
	fd_set        rfds;
	u_int32_t len = 0;
	int8_t cmd = 1;
	pid_t pid;
	struct timeval tv;

	while (n >= 0) {
		n = getopt_long(argc, argv, "i:p:", NULL, NULL);
		if (n < 0)
			continue;
		switch (n) {
            case 'i':
                LOG("ip:%s\n",optarg);
				sprintf(SF_WS_ADDRESS,"%s",optarg);
                break;
            case 'p':
                LOG("port:%s\n",optarg);
				SF_WS_PORT = atoi(optarg);
                break;
        }
    }

	sprintf(SF_WS_HOST,"%s:%d", SF_WS_ADDRESS, SF_WS_PORT);
	LOG("data addr is %s\n",SF_WS_HOST);

    signal(SIGINT, sighandler);

	pid = getpid();
	ret = setpriority(PRIO_PROCESS, pid, -20);
	if(ret != 0 ){
		LOG("set priority fail %d",ret);
		goto err;
	}

	ret = sf_ts_genl(&gnrtl);
	if(ret < 0){
		LOG("sf-ts init netlink fail");
		goto err;
	}
	ucontext.close = 1;
	ret = runWsSubClient(&ucontext);
	if(ret < 0){
		LOG("sf-ts init websocket fail");
		goto err;
	}

	//char buff[32] = "abcdefg";
	//ret = postMessageToUserbyws(buff,8);
	tv.tv_sec = 1;
	tv.tv_usec = 0;
	while(!g_force_exit_signal){
		if (ucontext.status != WS_CLIENT_CONNECT_ESTABLISH){
			libwebsocket_service(ucontext.ct, 5);
			continue;
		}
        FD_ZERO(&rfds);
        FD_SET(gnrtl.fd, &rfds);
        ret = select(gnrtl.fd + 1, &rfds, NULL, NULL, &tv);

        if(ret < 0)
        {
            if(errno == EAGAIN || errno == EINTR)
                continue;
            fprintf(stderr, "Unhandled signal - exiting...\n");
            break;
        }

        if(ret == 0)
        {
            continue;
        }

        if(FD_ISSET(gnrtl.fd, &rfds))
            handle_netlink(&gnrtl);

		if (ucontext.close == 1){
			reconnect();
		}
	}
	cmd = 0;
	ret = genl_send_msg(gnrtl.fd, gnrtl.family_id, 0, SF_TS_PKT_CMD, 1, IP_CMD, (void *)&cmd, 1);
	rtnl_close(&gnrtl);

err:
    return ret;
}
