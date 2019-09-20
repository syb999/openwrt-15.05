#include <linux/kthread.h>
#include <linux/sched.h>
#include <linux/kfifo.h>
#include <linux/socket.h>
#include <linux/sched.h>
#include "sf-ts.h"


static struct task_struct *send_pkt = NULL;
static struct task_struct *send_pkt_s = NULL;
DECLARE_KFIFO(pfifo,struct sk_buff *,128);
static spinlock_t plock;
DECLARE_KFIFO(dfifo,struct sk_buff *,128);
static spinlock_t dlock;
static u8 start_send;
static u8 sk_ok = 0;

void print_pkt(struct sk_buff *skb, u8 type){
	int i;
	u8 *data = skb->data;
	u8 *h = skb->head + skb->mac_header;
	printk("type is %s\n", type? "download": "upload");
	for(i=0; i<8; ++i){
		printk("%hhx %hhx %hhx %hhx\n ",data[i*4],data[i*4+1],data[i*4+2],data[i*4+3]);
	}
		printk("--------------------------------------\n");
	for(i=0; i<8; ++i){
		printk("%hhx %hhx %hhx %hhx\n ",h[i*4],h[i*4+1],h[i*4+2],h[i*4+3]);
	}
		printk("++++++++++++++++++++++++++++++++++++++\n");
}

static int send_func(struct sk_buff *pkt, u8 type){

	struct iphdr *iph = ip_hdr(pkt);
	struct buf_p bp[2];
	int ret;
	__be16 sport;
	__be16 dport;
	u8 *mac;
	u8 *head;
	u8 *tail;
	u8 buf[18];

	if(type == 0){
		mac = eth_hdr(pkt)->h_source;
	}else{
		mac = eth_hdr(pkt)->h_dest;
	}

	if(iph->protocol == IPPROTO_TCP){
		struct tcphdr *thdr;
		thdr = tcp_hdr(pkt);
		sport = thdr->source;
		dport = thdr->dest;
	}else if (iph->protocol == IPPROTO_UDP){
		struct udphdr *uhdr;
		uhdr = udp_hdr(pkt);
		sport = uhdr->source;
		dport = uhdr->dest;
	}
	memcpy(buf, mac, 6);
	*((u32 *)(buf+6)) = iph->saddr;
	*((__be16 *)(buf+10)) = sport;
	*((u32 *)(buf+12)) = iph->daddr;
	*((__be16 *)(buf+16)) = dport;
	head = skb_mac_header(pkt) - 18;
	tail = skb_tail_pointer(pkt);
	memcpy(head, buf, 18);
	bp[0].buf = head;
	bp[0].len = tail - head;

//	print_pkt(pkt, type);
	ret = sf_ts_genl_sendmsg(bp, 1, SF_TS_PKT_CMD, IP_PKT, 1);
//	printk("send len is %d\n",ret);
//	if(ret < 0)
	//	pr_err("send_msg error %d\n", ret);

	return ret;
}

static int send_pkt_func(void *data){
	struct sk_buff *sk;
	u32 len;
	u8 is_null, n = 0;
	int ret;

	send_pkt_s = send_pkt;
	while(!kthread_should_stop()){
		is_null = 0;
		len = kfifo_out_locked(&pfifo, &sk, 1, &plock);
		if(likely(len > 0)){
			ret = send_func(sk, 0);
			kfree_skb(sk);
		}else{
			++is_null;
		}
		len = kfifo_out_locked(&dfifo, &sk, 1, &dlock);
		if(likely(len > 0)){
			ret = send_func(sk, 1);
			kfree_skb(sk);
		}else{
			++is_null;
		}

		if(is_null == 2){
			++n;
			if(n >= 5){
				for(;;){
					set_current_state(TASK_UNINTERRUPTIBLE);
					start_send = 0;
					schedule();
					if(start_send != 0 || kthread_should_stop()){
					//	printk("wake up\n");
						__set_current_state(TASK_RUNNING);
						break;
					}
				}
				n = 0;
			}
		}else{
			n = 0;
		}

	}

	while(kfifo_out_locked(&pfifo, &sk, 1, &plock)){
		kfree_skb(sk);
	}
	while(kfifo_out_locked(&dfifo, &sk, 1, &plock)){
		kfree_skb(sk);
	}

	return 0;
}

static void inline wake_pkt(void){
	start_send = 1;
	smp_rmb();
	if(send_pkt_s){
		wake_up_process(send_pkt);
	}
}

void pkt_enqueue(struct sk_buff *skb, u8 type){
	struct sk_buff *sk;
	int ret;

	if(sk_ok != 1){
		if(start_send == 0){
			wake_pkt();
		}
		return;
	}

	sk = skb_copy_expand(skb, 32, 16,GFP_ATOMIC);
	if(!sk)
		return;

	if(type == 0){
		ret = kfifo_in_locked(&pfifo, &sk, 1, &plock);
	}else{
		ret = kfifo_in_locked(&dfifo, &sk, 1, &dlock);
	}
	if(ret < 0){
		pr_err("packet enqueue error, type is %d\n",type);
		kfree_skb(sk);
	}else{
		if(start_send == 0){
			wake_pkt();
		}
	}
}
EXPORT_SYMBOL_GPL(pkt_enqueue);

int send_pkt_init(void){
	if(sk_ok == 0){
		return 0;
	}
	start_send = 1;
	INIT_KFIFO(pfifo);
	INIT_KFIFO(dfifo);
	spin_lock_init(&plock);
	spin_lock_init(&dlock);
	send_pkt = kthread_run(send_pkt_func, NULL, "send_pkt");
	if(IS_ERR(send_pkt)){
		printk("init send pkt thread error\n");
		send_pkt = NULL;
		return -1;
	}else{
		pr_debug("send packet to server by userspace init ok\n");
		return 0;
	}
}
EXPORT_SYMBOL_GPL(send_pkt_init);

void send_pkt_exit(void){
	sk_ok = 0;
	if(send_pkt_s){
		start_send = 1;
		smp_rmb();
		kthread_stop(send_pkt);
		send_pkt_s = NULL;
	}
	send_pkt = NULL;
}
EXPORT_SYMBOL_GPL(send_pkt_exit);

void send_pkt_run(u8 run){
	if(run != 0){
		if(!send_pkt_s)
			send_pkt_init();
	}else{
		send_pkt_exit();
	}
}
EXPORT_SYMBOL_GPL(send_pkt_run);

void send_pkt_sock_ok(u8 ok){
	sk_ok = ok;
	if(ok == 1){
		send_pkt_init();
	}else{
		send_pkt_exit();
	}
	return;
}
EXPORT_SYMBOL_GPL(send_pkt_sock_ok);
