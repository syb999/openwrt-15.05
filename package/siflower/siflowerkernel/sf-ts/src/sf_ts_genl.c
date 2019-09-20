#include <asm/types.h>
#include <net/sock.h>
#include <linux/socket.h>
#include <linux/netlink.h>
#include <linux/skbuff.h>
#include <linux/net.h>
#include <linux/version.h>
#include <net/genetlink.h>
#include "sf-ts.h"

static struct genl_family sf_ts_genl_family = {
		.id			= GENL_ID_GENERATE,
		.hdrsize	= 0,
		.name		= "SF_TS_NL",
		.version	= 1,
		.maxattr	= SF_TS_MAXATTR,
		.netnsok	= true,
};

int sf_ts_genl_rec(struct sk_buff *skb, struct genl_info *info){
	u32 *buf, len;
	struct nlattr *n = (struct nlattr *)info->userhdr;

	printk("Get msg from user len is %u  type is %u!\n", n->nla_len, n->nla_type);

	buf = (u32 *)nla_data(n);
	len = n->nla_len / 4;
	flow_ip_init(buf, len);
	return 0;
}

static int sf_ts_dump(struct sk_buff *skb, struct netlink_callback *cb){
	printk("call dump function\n");
	return 0;
}

static struct nla_policy sf_ts_genl_policy[SF_TS_MAXATTR + 1] = {
		//[IP_INFO]		= {.type = NLA_NESTED},
		[IP_INFO]		= {.type = NLA_BINARY, .len = 4096},
		[FLOW_DATA]		= {.type = NLA_BINARY, .len = 4096},
		[IP_TEST]		= {.type = NLA_U8}, /*NLA_U8 should not use in higher linux version*/
};

#ifndef CONFIG_SF_PKT_SEND_BY_KERNEL
int sf_ts_pkt_genl_rec(struct sk_buff *skb, struct genl_info *info){
	u32 *buf, len;
	struct nlattr *n = (struct nlattr *)info->userhdr;

	buf = (u32 *)nla_data(n);
	len = n->nla_len;
	send_pkt_sock_ok((u8)*buf);
	printk("Get pkt msg from user len is %u  type is %u buf is %d!\n", n->nla_len, n->nla_type, *((u8 *)buf));
	return 0;
}

static struct nla_policy sf_ts_pkt_genl_policy[SF_TS_MAXATTR + 1] = {
		[IP_PKT]		= {.type = NLA_BINARY, .len = 4096},
		[IP_CMD]		= {.type = NLA_U8}, /*NLA_U8 should not use in higher linux version*/
};
#endif

static const struct genl_ops sf_ts_genl_ops[] = {
	{
		.cmd		= SF_TS_CMD,
		.policy		= sf_ts_genl_policy,
		.doit		= sf_ts_genl_rec,
		.dumpit		= sf_ts_dump,
	},
#ifndef CONFIG_SF_PKT_SEND_BY_KERNEL
	{
		.cmd		= SF_TS_PKT_CMD,
		.policy		= sf_ts_pkt_genl_policy,
		.doit		= sf_ts_pkt_genl_rec,
		.dumpit		= sf_ts_dump,
	},
#endif
};

static struct genl_multicast_group sf_ts_genl_group[] = {
	{
		.name = "sf-ts",
	},
#ifndef CONFIG_SF_PKT_SEND_BY_KERNEL
	{
		.name = "sf-ts-pkt",
	},
#endif
};

int sf_ts_genl_sendmsg(struct buf_p *bufp, u8 c, u8 cmd, int type, u32 group){
	struct sk_buff *skb;
	int ret = 0, i, len = 0;
	void *msg_head;

	skb = genlmsg_new(NLMSG_GOODSIZE, GFP_KERNEL);
	if (skb == NULL){
		printk("skb error!\n");
		ret = -ENOMEM;
		goto fail;
	}
	msg_head = genlmsg_put(skb, 0, 0, &sf_ts_genl_family, 0, cmd);
	if (msg_head == NULL){
		printk("msghead error!\n");
		ret = -ENOMEM;
		goto fail1;
	}
	for(i=0;i<c;i++){
		ret = nla_put(skb, type, bufp[i].len, (void *)bufp[i].buf);
		if (ret != 0){
			printk("nla_put error!\n");
			ret = -EMSGSIZE;
			goto fail1;
		}
		len += bufp[i].len;
	}
	genlmsg_end(skb, msg_head);

	ret = genlmsg_multicast(&sf_ts_genl_family, skb, 0, group, GFP_KERNEL);
//	printk("multicast return %d\n", ret);
	return ret;
fail1:
	kfree_skb(skb);
fail:
	return ret;

}
EXPORT_SYMBOL_GPL(sf_ts_genl_sendmsg);

int sf_ts_genl_init(void){
	int ret;

	ret = genl_register_family_with_ops_groups(&sf_ts_genl_family, sf_ts_genl_ops, sf_ts_genl_group);
	if (ret != 0){
		printk("register family error return %d!\n", ret);
		goto fail;
	}
	printk("offset is %d!\n", sf_ts_genl_family.mcgrp_offset);
	return 0;
fail:
	printk("init fail!\n");
	return -1;
}
EXPORT_SYMBOL_GPL(sf_ts_genl_init);

int sf_ts_genl_exit(void){
	int ret;

	ret = genl_unregister_family(&sf_ts_genl_family);
	if (ret){
		printk("unregister family error!\n");
	}
	return ret;
}
EXPORT_SYMBOL_GPL(sf_ts_genl_exit);
