#include <linux/err.h>
#include <linux/init.h>
#include <linux/string.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/skbuff.h>
#include <linux/netfilter.h>
#include <linux/netfilter_bridge.h>
#include <linux/if_ether.h>
#include <linux/netdevice.h>
#include <linux/timer.h>
#include <linux/hashtable.h>
#include <linux/jhash.h>
#include <linux/random.h>
#include <linux/rcupdate.h>
#include <linux/rculist.h>
#include <asm/unaligned.h>
#include <linux/udp.h>
#include <linux/tcp.h>
#include <linux/ip.h>
#include <linux/net.h>
#include <linux/spinlock.h>
#include <net/netfilter/nf_conntrack.h>


#define NF_IP_PRI_SF_TS			-500
#define NF_BR_PRI_SF_TS			-500
#define NF_IP_HIJACK_PRI_SF_TS			-490
#define NF_BR_HIJACK_PRI_SF_TS			-490

#define DMARK					0x800
#define TS_HASH_SIZE			128
#define TS_HASH_NUM				(TS_HASH_SIZE - 1)
#define BUF_SIZE				127

#define TS_DEBUG 1

#ifdef TS_DEBUG
#define	ts_dbg(fmt,...) printk(fmt,##__VA_ARGS__)
#else
#define	ts_dbg(fmt,...) do{}while(0)
#endif

#define SF_DROP					0
#define SF_ACCEPT				1

/*netlink*/
#define	SF_TS_MAXATTR		3
#define SF_TS_CMD			1
#define SF_TS_PKT_CMD		2
#define IP_INFO				0
#define FLOW_DATA			1
#define	IP_TEST				2
#define IP_PKT				0
#define IP_CMD				1

/*
 * add a mac entry
 * delete a mac entry
 * reset a mac tx/rx
 * get a mac tx/rx
 * get all mac tx/rx
 * reset all mac tx/rx
 * set a mac priority
 * enable update function
 * disable update function
 * enable mark priority
 * disable mark priority
 * limit flow enable
 * limit flow disable
 * type flow set
 * show type flow ip information
 */
enum ts_cmd{
	CMD_ADD_MAC = 0,
	CMD_DEL_MAC,
	CMD_RESET_TXRX,
	CMD_GET_TXRX,
	CMD_RESET_ALL_TXRX,

	CMD_GET_ALL_TXRX,
	CMD_SET_PRI,
	CMD_UPDATE_START,
	CMD_UPDATE_STOP,
	CMD_PRI_EN,

	CMD_PRI_DIS,
	CMD_FLOW_EN,
	CMD_FLOW_DIS,
	CMD_TYPE_FLOW,
	CMD_TYPE_FLOW_SHOW,
};

/*
 * configure packet hijack params
 */

enum hi_cmd{
	CMD_ADD = 0,
	CMD_DEL,
	CMD_EDIT,
	CMD_SET_SERVER,
	CMD_RUN,
	CMD_QOS,
};

enum qos_cmd{
	CMD_SET_QOS = 0,
};

struct sf_counter{
	u64 up_c;
	u64 down_c;
	s64 s_flow;
	struct u64_stats_sync lock;
};

/*
 * snode: hash list node
 * mac: device mac address
 * totle: all cpu totle traffic
 * c: traffic statistic for each cpu
 * warn: notice user space to save flow number when over this param
 * upload_s: upload speed
 * download_s: download speed
 * m_upload_s: max upload speed
 * m_download_s: max download speed
 * priority: device priority for tc
 * ret: return action status, accept or drop
 * l_flow_en: limit flow enable or disable
 * alive: mark device which has traffic pass in 1s when update function is running
 * clear: use this param to reset totle traffic when update function is running
 * t_flow_en: tpye flow enable or disable
 * t_qos: qos enable or disable
 * flow_type_en: game(0 bit), video(1 bit), social(2 bit) enable status
 * qos: qos[0] game, qos[1] video, qos[2] social
 */

struct sf_ts_dev{
	struct hlist_node snode;
	u8 mac[6];
	struct sf_counter totle;
	struct sf_counter __percpu *c;
	int warn;
	u32 upload_s;
	u32 download_s;
	u32 m_upload_s;
	u32 m_download_s;
	u32 priority;
	u8 ret;
	u8 l_flow_en:1;
	u8 alive:1;
	u8 clear:1;
	u8 t_flow_en:1;
	u8 t_qos:1;
	u8 qos[3];
	u8 flow_type_en;
};

/*
 * hash_index: hash list
 * ts_timer: timer for update function
 * ts_enable: enable traffic statistic
 * set_pri_enable: enable set priority for tc
 * update_enable: enable run update function for get device speed and max speed
 */
struct sf_ts{
	struct hlist_head hash_index[TS_HASH_SIZE];
	struct timer_list ts_timer;
	u8 ts_enable;
	u8 set_pri_enable;
	u8 update_enable;
};

#define HI_NUM	256
#define HI_HASH_NUM		(HI_NUM - 1)
#define FLOW_HASH_NUM	256
#define FLOW_TYPE		3
#define MAXBUF 4096

/*
 *len : array length
 *use : array length of used
 *ip : array for saving ip address
 * */
struct sf_ip{
	struct hlist_node hnode;
	u16 len;
	u16 use;
	u32 ip[0];
};

/*num: number of param node*/
struct ip_hajick{
	struct hlist_head hash_index[HI_NUM];
	u8 hi_enable;
	u32 num;
};

/*packet hijack param struct*/
struct param_node{
	struct hlist_node snode;
	__be32 src_ip;
	__be32 dst_ip;
	__be16 src_port;
	__be16 dst_port;
	u8 mac[6];
	u8 action;
	u8 qos_en;
	u8 qos;
	u32 num;
};

struct buf_p{
	u8 *buf;
	u32 len;
};

#define sf_alloc_percpu_stats(type)               \
({                              \
	typeof(type) __percpu *pcpu_stats = alloc_percpu(type); \
	if (pcpu_stats) {                   \
		int i;                      \
		for_each_possible_cpu(i) {          \
			typeof(type) *per_c;         \
			per_c = per_cpu_ptr(pcpu_stats, i);  \
			per_c->up_c = 0; \
			per_c->down_c = 0; \
			u64_stats_init(&per_c->lock);       \
		}                       \
	}                           \
	pcpu_stats;                     \
})

extern u32 ip_rnd;
extern struct hlist_head (*hash_ip)[FLOW_TYPE][FLOW_HASH_NUM];
extern struct sf_ts ts;

static inline u32 sf_ip_hash(const u32 *ip)
{
	u32 key = get_unaligned(ip);
	return jhash_1word(key, ip_rnd) % FLOW_HASH_NUM;
}

static inline void ipv4_change_dsfield(struct iphdr *iph,__u8 mask,
		__u8 value)
{
	__u32 check = ntohs((__force __be16)iph->check);
	__u8 dsfield;

	dsfield = (iph->tos & mask) | value;
	check += iph->tos;
	if ((check+1) >> 16) check = (check+1) & 0xffff;
	check -= dsfield;
	check += check >> 16; /* adjust carry */
	iph->check = (__force __sum16)htons(check);
	iph->tos = dsfield;
}


int type_flow_check(struct sk_buff *skb, struct sf_ts_dev *dev);
int sf_ts_genl_init(void);
int sf_ts_genl_exit(void);
void flow_ip_init(u32 *buf, u32 buflen);
int flow_init(void);
void flow_exit(void);
int type_flow_show(char *buf);
int sf_ts_genl_sendmsg(struct buf_p *bufp, u8 c, u8 cmd, int type, u32 group);
int send_pkt_init(void);
void send_pkt_exit(void);
void pkt_enqueue(struct sk_buff *sk, u8 type);
#ifdef CONFIG_SF_PKT_SEND_BY_KERNEL
void update_ip_port(u32 ip, u16 port);
#else
void send_pkt_sock_ok(u8 ok);
#endif
void send_pkt_run(u8 run);
struct sf_ts_dev * check_dev_in_hlist(u8 *mac);
void type_flow_qos(struct sk_buff *skb, struct sf_ts_dev *dev, u8 upload);
int sf_qos_init(void);
void sf_qos_exit(void);
