#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <uapi/linux/in.h>
#include "sf-ts.h"

#define DRV_NAME "sf-ts"
#define DRV_VERSION "0.0.1"

#define WARN_LIMIT 30*1000*1000

struct sf_ts ts = {
	.ts_enable	= 1,
	.set_pri_enable = 0,
};

static u32 hashv __read_mostly;

static inline u32 sf_mac_hash(const unsigned char *mac)
{
	/* use 1 byte of OUI and 3 bytes of NIC */
	u32 key = get_unaligned((u32 *)(mac + 2));
	return jhash_1word(key, hashv) & TS_HASH_NUM;
}

static int sf_ts_show(struct seq_file *file, void *v){
	struct sf_ts_dev *dev;
	struct sf_counter *rcu_c;
	u64 upload, download;
	u32 start, cpu;
	u16 i;
	u8 *mac;

	seq_printf(file, "mac               upload   download    upspeed   downspeed   maxups    maxdowns   priority flow game video social\n");
	rcu_read_lock();
	for(i =0; i < TS_HASH_SIZE; i++){
		hlist_for_each_entry(dev, &ts.hash_index[i], snode){
			upload = 0;
			download = 0;
			mac = dev->mac;
			rcu_c = rcu_dereference(dev->c);
			for_each_possible_cpu(cpu) {
				struct sf_counter *per_c = per_cpu_ptr(rcu_c, cpu);
				do{
					start = u64_stats_fetch_begin(&per_c->lock);
					upload += per_c->up_c;
					download += per_c->down_c;
				}while(u64_stats_fetch_retry(&per_c->lock, start));
			}
			if(ts.update_enable){
				seq_printf(file, "%02X:%02X:%02X:%02X:%02X:%02X     %llu      %llu     %u  %u   %u  %u  %u %lld %hhu %hhu %hhu\n",
					   	mac[0], mac[1], mac[2], mac[3], mac[4], mac[5], upload, download,
						dev->upload_s, dev->download_s, dev->m_upload_s, dev->m_download_s,
					   	dev->priority, dev->totle.s_flow, dev->flow_type_en & 0x1,
						(dev->flow_type_en & 0x2)>>1, (dev->flow_type_en & 0x4)>>2);
			}else{
				seq_printf(file, "%02X:%02X:%02X:%02X:%02X:%02X     %llu      %llu     %u  %u  %u   %u  %u %lld %hhu %hhu %hhu\n",
					   	mac[0], mac[1], mac[2], mac[3], mac[4], mac[5], upload, download,
						0, 0, dev->m_upload_s, dev->m_download_s, dev->priority, dev->totle.s_flow
						, dev->flow_type_en & 0x1,(dev->flow_type_en & 0x2)>>1, (dev->flow_type_en & 0x4)>>2);
			}
		}
	}
	rcu_read_unlock();
	return 0;
}

static int sf_ts_open(struct inode *inode, struct file *file){
	return single_open(file, sf_ts_show, inode->i_private);
}

struct sf_ts_dev * check_dev_in_hlist(u8 *mac){
	struct sf_ts_dev *dev, *rdev = NULL;
	u32 key;

	key = sf_mac_hash(mac);

	ts_dbg("mac is %2x:%2x:%2x:%2x:%2x:%2x,key is %d\n",mac[0],mac[1],mac[2],mac[3],mac[4],mac[5],key);
	hlist_for_each_entry(dev, &ts.hash_index[key], snode){
		if(ether_addr_equal(mac, dev->mac)){
			rdev = dev;
			break;
		}
	}
	ts_dbg("have is %d\n", rdev != NULL ? 1 : 0);

	return rdev;
}
EXPORT_SYMBOL_GPL(check_dev_in_hlist);

static ssize_t sf_ts_write(struct file *file, const char __user *input,
				size_t size, loff_t *ofs)
{
	struct sf_counter *per_c, *rcu_c, *new_c, *old_c;
	struct sf_ts_dev *dev, *newdev;
	int ret;
	u64 download, upload, u_data = 0;
	u32 cmd, cpu, key, start, u_pri = 0;
	u16 i;
	u8 buffer[BUF_SIZE + 1], func;
	u8 mac[ETH_ALEN];
	char buf[MAXBUF];

	if(size > BUF_SIZE){
		return -EIO;
	}
	if(copy_from_user(buffer, input, size)){
		return -EFAULT;
	}
	buffer[size] = 0;

	ret = sscanf(buffer,"%u %2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx %llu", &cmd,
		   &mac[0], &mac[1], &mac[2], &mac[3], &mac[4], &mac[5], &u_data);
	if(ret < 1){
		ts_dbg("CMD param error\n");
		goto done;
	}
	ts_dbg("cmd is %d, data is %lld\n", cmd, u_data);
	u_pri = (u32)u_data;
	switch(cmd){
		case CMD_ADD_MAC:
			if(ret < 8){
				ts_dbg("Add: param error\n");
				break;
			}
			dev = check_dev_in_hlist(mac);
			if(!dev){
				key = sf_mac_hash(mac);
				newdev = kmalloc(sizeof(struct sf_ts_dev), GFP_KERNEL);
				if(!newdev)
					break;

				memset(newdev, 0, sizeof(struct sf_ts_dev));
				newdev->c = sf_alloc_percpu_stats(struct sf_counter);
				if(!newdev->c){
					kfree(newdev);
					break;
				}
				memcpy(newdev->mac, mac, ETH_ALEN);
				newdev->priority = u_pri;
				newdev->ret = NF_ACCEPT;
				newdev->warn = WARN_LIMIT;

				hlist_add_head_rcu(&newdev->snode, &ts.hash_index[key]);
			}
			break;

		case CMD_DEL_MAC:
			if(ret < 7){
				ts_dbg("Del: param error\n");
				break;
			}
			dev = check_dev_in_hlist(mac);
			if(dev){
				hlist_del_rcu(&dev->snode);
				synchronize_rcu();
				free_percpu(dev->c);
				kfree(dev);
			}else{
				ts_dbg("Delete: not found\n");
			}
			break;

		case CMD_RESET_TXRX:
			if(ret < 7){
				ts_dbg("Reset: param error\n");
				break;
			}
			dev = check_dev_in_hlist(mac);
			if(dev){
				new_c = sf_alloc_percpu_stats(struct sf_counter);
				if(!new_c){
					break;
				}
				old_c = dev->c;
				rcu_assign_pointer(dev->c, new_c);
				synchronize_rcu();
				free_percpu(old_c);

				if(ts.update_enable){
					/*wait clear each cpu traffic, then clear totle traffic*/
					dev->clear = 1;
				}
			}else{
				ts_dbg("Reset txrx: not found\n");
			}
			break;

		case CMD_GET_TXRX:
			break;

		case CMD_RESET_ALL_TXRX:
			for(i =0; i < TS_HASH_SIZE; i++){
				hlist_for_each_entry(dev, &ts.hash_index[i], snode){
					new_c = sf_alloc_percpu_stats(struct sf_counter);
					if(!new_c){
						continue;
					}
					old_c = dev->c;
					rcu_assign_pointer(dev->c, new_c);
					synchronize_rcu();
					free_percpu(old_c);

					if(ts.update_enable){
						dev->clear = 1;
					}
				}
			}
			break;

		case CMD_GET_ALL_TXRX:
			break;

		case CMD_SET_PRI:
			if(ret < 8){
				ts_dbg("Priority: param error\n");
				break;
			}
			dev = check_dev_in_hlist(mac);
			if(dev){
				dev->priority = u_pri;
			}else{
				ts_dbg("Set priority: not found\n");
			}
			break;

		case CMD_UPDATE_START:
			if(ts.update_enable){
				break;
			}
			rcu_read_lock();
			for(i=0; i < TS_HASH_SIZE; i++){
				hlist_for_each_entry_rcu(dev, &ts.hash_index[i], snode){
						upload = 0;
						download = 0;
						rcu_c = rcu_dereference(dev->c);
						for_each_possible_cpu(cpu) {
							per_c = per_cpu_ptr(rcu_c, cpu);
							do{
								start = u64_stats_fetch_begin(&per_c->lock);
								upload += per_c->up_c;
								download += per_c->down_c;
							}while(u64_stats_fetch_retry(&per_c->lock, start));
						}
						/*update totle traffic*/
						u64_stats_update_begin(&dev->totle.lock);
						dev->totle.up_c = upload;
						dev->totle.down_c = download;
						u64_stats_update_end(&dev->totle.lock);

						/*init device status*/
						dev->upload_s = 0;
						dev->download_s = 0;
						dev->alive = 0;
				}
			}
			rcu_read_unlock();
			add_timer(&ts.ts_timer);
			ts.update_enable = 1;
			break;

		case CMD_UPDATE_STOP:
			if(!ts.update_enable){
				break;
			}
			ts.update_enable = 0;
			del_timer(&ts.ts_timer);
			break;
		case CMD_PRI_EN:
			ts.set_pri_enable = 1;
			break;
		case CMD_PRI_DIS:
			ts.set_pri_enable = 0;
			break;
		case CMD_FLOW_EN:
			dev = check_dev_in_hlist(mac);
			if(dev){
				dev->l_flow_en = 1;
				u64_stats_update_begin(&dev->totle.lock);
				dev->totle.s_flow = u_data*1000*1000;
				u64_stats_update_end(&dev->totle.lock);
				dev->ret = NF_ACCEPT;
			}else{
				pr_err("Not find device\n");
			}
			break;
		case CMD_FLOW_DIS:
			dev = check_dev_in_hlist(mac);
			if(dev){
				dev->l_flow_en = 0;
				dev->totle.s_flow = 0;
			}else{
				pr_err("Not find device\n");
			}
			break;
		case CMD_TYPE_FLOW:
			func = (u8)u_data;
			dev = check_dev_in_hlist(mac);
			if(dev){
				dev->t_flow_en = (func & 0x8) >> 3;
				dev->flow_type_en = (func & 0x7);
			}else{
				pr_err("Not find device\n");
			}
			break;
		case CMD_TYPE_FLOW_SHOW:
			ret = type_flow_show(buf);
			if(ret < 0){
				pr_err("Get ip information error, maybe too much\n");
			}else{
				printk("%s",buf);
			}
			break;
		default:
			break;
	}
done:
	return size;
}

static const struct file_operations sf_ts_ops = {
	.owner	 = THIS_MODULE,
	.open	 = sf_ts_open,
	.read	 = seq_read,
	.write	 = sf_ts_write,
	.llseek	 = seq_lseek,
	.release = single_release,
};


static void sf_do_update(unsigned long arg){
	struct sf_ts *pri = (struct sf_ts *)arg;
	struct sf_ts_dev *dev;
	struct sf_counter *rcu_c;
	struct buf_p bp;
	u64 download, upload;
	u32 i, start, use, j=0;
	u32 cpu;
	u8 databuf[512];

	rcu_read_lock();
	for(i=0; i < TS_HASH_SIZE; i++){
		hlist_for_each_entry_rcu(dev, &pri->hash_index[i], snode){
			if (dev->alive){
				upload = 0;
				download = 0;
				rcu_c = rcu_dereference(dev->c);
				for_each_possible_cpu(cpu) {
					struct sf_counter *per_c = per_cpu_ptr(rcu_c, cpu);
					do{
						start = u64_stats_fetch_begin(&per_c->lock);
						upload += per_c->up_c;
						download += per_c->down_c;
					}while(u64_stats_fetch_retry(&per_c->lock, start));
				}
				/*if set clear, clear totle traffic*/
				if(unlikely(dev->clear)){
					u64_stats_update_begin(&dev->totle.lock);
					dev->totle.up_c = 0;
					dev->totle.down_c = 0;
					u64_stats_update_end(&dev->totle.lock);
					dev->clear = 0;
				}
				/*speed*/
				dev->upload_s = upload - dev->totle.up_c;
				dev->download_s = download - dev->totle.down_c;

				if(unlikely(dev->upload_s > dev->m_upload_s)){
					dev->m_upload_s = dev->upload_s;
				}
				if(unlikely(dev->download_s > dev->m_download_s)){
					dev->m_download_s = dev->download_s;
				}

				/*update totle traffic*/
				u64_stats_update_begin(&dev->totle.lock);
				dev->totle.up_c = upload;
				dev->totle.down_c = download;
				u64_stats_update_end(&dev->totle.lock);

				if(dev->l_flow_en){
					s64 flow;
					use =dev->upload_s + dev->download_s;
					u64_stats_update_begin(&dev->totle.lock);
					dev->totle.s_flow -= use;
					flow = dev->totle.s_flow;
					u64_stats_update_end(&dev->totle.lock);
					if(flow <= 0){
						dev->ret = NF_DROP;
					}
					dev->warn -= use;
					if(dev->warn < 0){
						dev->warn = dev->warn % WARN_LIMIT + WARN_LIMIT;
						strncpy(databuf+j, dev->mac, ETH_ALEN);
						*((u64 *)(databuf+j+ETH_ALEN)) = flow;
						j += ETH_ALEN + sizeof(flow);
					}
				}
				/*reset device status*/
				dev->alive = 0;

//				ts_dbg("update upload speed %u, download speed %u\n", dev->upload_s, dev->download_s);
//				ts_dbg("mac is %2x:%2x:%2x:%2x:%2x:%2x\n",dev->mac[0],dev->mac[1],dev->mac[2],dev->mac[3],dev->mac[4],dev->mac[5]);
			}
		}
	}
	if(pri->update_enable){
		pri->ts_timer.expires = jiffies + HZ;
		add_timer(&pri->ts_timer);
	}
	rcu_read_unlock();
	if( j > 0){
		bp.buf = &databuf[0];
		bp.len = j;
		sf_ts_genl_sendmsg(&bp, 1, SF_TS_CMD, FLOW_DATA, 0);
	}
	return;
}


static unsigned int sf_ts_ip_forward_fn(const struct nf_hook_ops *ops,
						struct sk_buff *skb,
						const struct net_device *in,
						const struct net_device *out,
						int (*okfn)(struct sk_buff *))
{
	struct sf_ts_dev *dev;
	struct sf_counter *per_c;
	u32 key;
	u8 *mac;

	if(strncmp(in->name,"br-",3) == 0){
		mac = eth_hdr(skb)->h_source;
		key = sf_mac_hash(mac);
		rcu_read_lock();
		hlist_for_each_entry_rcu(dev, &ts.hash_index[key], snode){
			if(ether_addr_equal(mac, dev->mac)){
				if(dev->l_flow_en == 1 && dev->ret == NF_DROP){
						goto drop;
				}
				if(dev->t_flow_en == 1){
					struct nf_conn *ct;
					enum ip_conntrack_info ctinfo;
					ct = nf_ct_get(skb, &ctinfo);
					if(ctinfo == IP_CT_NEW){
						if(type_flow_check(skb, dev) == SF_DROP){
							goto drop;
						}
					}
				}
				if(dev->t_qos == 1){
					type_flow_qos(skb, dev, 1);
				}

				per_c = this_cpu_ptr(rcu_dereference(dev->c));
				u64_stats_update_begin(&per_c->lock);
				per_c->up_c += skb->len;
				u64_stats_update_end(&per_c->lock);

				/*function: set device priority*/
				if(ts.set_pri_enable){
					skb->mark |= dev->priority;
				}

				/*set device alive*/
				if(!dev->alive)
					dev->alive = 1;

				/*
				ts_dbg("up data len is %d\n",skb->len);
				*/
				break;
			}
		}
		rcu_read_unlock();
	}else if(strncmp(in->name,"eth", 3) == 0){
		skb->mark |= DMARK;
	}

	return NF_ACCEPT;
drop:
	rcu_read_unlock();
	return NF_DROP;

}

static unsigned int sf_ts_br_out_fn(const struct nf_hook_ops *ops,
						struct sk_buff *skb,
						const struct net_device *in,
						const struct net_device *out,
						int (*okfn)(struct sk_buff *))
{
	struct sf_ts_dev *dev;
	struct sf_counter *per_c;
	u32 key;
	u8 *mac;

	if(skb->mark & DMARK){
		mac = eth_hdr(skb)->h_dest;
		key = sf_mac_hash(mac);
		rcu_read_lock();
		hlist_for_each_entry_rcu(dev, &ts.hash_index[key], snode){
			if(ether_addr_equal(mac, dev->mac)){
				if(dev->l_flow_en && dev->ret == NF_DROP){
					goto drop;
				}
				if(dev->t_qos == 1){
					type_flow_qos(skb, dev, 0);
				}
				per_c = this_cpu_ptr(rcu_dereference(dev->c));
				u64_stats_update_begin(&per_c->lock);
				per_c->down_c += skb->len;
				u64_stats_update_end(&per_c->lock);

				/*function: set device priority*/
				if(ts.set_pri_enable){
					skb->mark |= dev->priority;
				}

				/*set device alive*/
				if(!dev->alive)
					dev->alive = 1;

				/*
				ts_dbg("down data len is %d\n",skb->len);
				*/
				break;
			}
		}
		rcu_read_unlock();
	}

	return NF_ACCEPT;
drop:
	rcu_read_unlock();
	return NF_DROP;
}

/*hijack code*/
struct ip_hajick hi;

static inline u32 sf_hi_ip_hash(const u32 *ip)
{
	u32 key = get_unaligned(ip);
	return jhash_1word(key, hashv) % HI_HASH_NUM;
}

static inline void print_param(struct seq_file *f, struct hlist_head *hh){
	struct param_node *pn;
	u8 *sip, *dip, *mac;

	hlist_for_each_entry_rcu(pn, hh, snode){
		sip =(u8 *)(&pn->src_ip);
		dip = (u8 *)(&pn->dst_ip);
		mac = pn->mac;
		seq_printf(f, "%u %02X:%02X:%02X:%02X:%02X:%02X     %hhu.%hhu.%hhu.%hhu   %hhu.%hhu.%hhu.%hhu   %hu  %hu  %hhu %hhu %hhu\n",
				 pn->num, mac[0], mac[1], mac[2], mac[3], mac[4], mac[5],
				 sip[0], sip[1], sip[2], sip[3],
				 dip[0], dip[1], dip[2], dip[3],
				 ntohs(pn->src_port), ntohs(pn->dst_port), pn->action,
				 pn->qos_en, pn->qos >> 2);
	}
}

static int sf_ts_hijack_show(struct seq_file *file, void *v){
	struct hlist_head *_hh;
	u32 i;

	seq_printf(file, "num mac               sip   dip    sport   dport   action qos_en qos\n");
	rcu_read_lock();
	for(i=0; i< HI_NUM; i++){
		_hh = &hi.hash_index[i];
		print_param(file, _hh);
	}
	rcu_read_unlock();
	return 0;
}

static int sf_ts_hijack_open(struct inode *inode, struct file *file){
	return single_open(file, sf_ts_hijack_show, inode->i_private);
}

static ssize_t sf_ts_hijack_write(struct file *file, const char __user *input,
				size_t size, loff_t *ofs)
{
	struct param_node *pn = NULL, *del_pn = NULL, *edit_pn = NULL;
	int ret;
	u32 cmd, num, key, i;
	u16 sport, dport;
	u8 buffer[BUF_SIZE + 1];
	u8 mac[ETH_ALEN], sip[4], dip[4], action;
	s8 qos_en, qos;

	if(size > BUF_SIZE){
		return -EIO;
	}
	if(copy_from_user(buffer, input, size)){
		return -EFAULT;
	}
	buffer[size] = 0;
	ret = sscanf(buffer,"%u", &cmd);
	if(ret < 1){
		ts_dbg("CMD param error\n");
		goto done;
	}
	switch(cmd){
		case CMD_ADD:
			ret = sscanf(buffer+2,"%2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx %hhu.%hhu.%hhu.%hhu %hhu.%hhu.%hhu.%hhu %hu %hu %hhu %hhd %hhd",
				   &mac[0], &mac[1], &mac[2], &mac[3], &mac[4], &mac[5],
				   &sip[0], &sip[1], &sip[2], &sip[3],
				   &dip[0], &dip[1], &dip[2], &dip[3],
				   &sport, &dport, &action, &qos_en, &qos);

			ts_dbg("cmd is %d\n", cmd);
			if(ret < 17){
				ts_dbg("Add: param error\n");
				break;
			}
			pn = kmalloc(sizeof(struct param_node), GFP_KERNEL);
			if(!pn)
				break;

			memcpy(pn->mac, mac, ETH_ALEN);
			pn->src_ip = *((u32 *)sip);
			pn->dst_ip = *((u32 *)dip);
			pn->src_port = htons(sport);
			pn->dst_port = htons(dport);
			pn->action = action;
			pn->num = hi.num;
			pn->qos_en = qos_en;
			pn->qos = qos << 2;
			hi.num++;
			if(pn->dst_ip == 0){
				hlist_add_head_rcu(&pn->snode, &hi.hash_index[HI_HASH_NUM]);
			}else{
				key = sf_hi_ip_hash(&pn->dst_ip);
				hlist_add_head_rcu(&pn->snode, &hi.hash_index[key]);
			}
			break;

		case CMD_DEL:
			ret = sscanf(buffer+2,"%u", &num);

			ts_dbg("cmd is %d\n", cmd);
			if(ret < 1){
				ts_dbg("CMD param error\n");
				goto done;
			}

			for(i=0; i< HI_NUM; i++){
				hlist_for_each_entry(pn, &hi.hash_index[i], snode){
					if(pn->num == num){
						del_pn = pn;
						i = HI_NUM;
						break;
					}
				}
			}

			if(del_pn){
				hlist_del_rcu(&del_pn->snode);
				synchronize_rcu();
				kfree(del_pn);
			}else{
				ts_dbg("Delete: not found\n");
			}
			break;

		case CMD_EDIT:
			ret = sscanf(buffer+2,"%u %2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx %hhu.%hhu.%hhu.%hhu %hhu.%hhu.%hhu.%hhu %hu %hu %hhu",
				   &num, &mac[0], &mac[1], &mac[2], &mac[3], &mac[4], &mac[5],
				   &sip[0], &sip[1], &sip[2], &sip[3],
				   &dip[0], &dip[1], &dip[2], &dip[3],
				   &sport, &dport, &action);

			ts_dbg("cmd is %d\n", cmd);
			if(ret < 18){
				ts_dbg("edit: param error\n");
				break;
			}

			for(i=0; i< HI_NUM; i++){
				hlist_for_each_entry(edit_pn, &hi.hash_index[i], snode){
					if(edit_pn->num == num){
						del_pn = edit_pn;
						i = HI_NUM;
						break;
					}
				}
			}
			if(del_pn){
				pn = kmalloc(sizeof(struct param_node), GFP_KERNEL);
				if(!pn)
					break;

				memcpy(pn->mac, mac, ETH_ALEN);
				pn->src_ip = *((u32 *)sip);
				pn->dst_ip = *((u32 *)dip);
				pn->src_port = htons(sport);
				pn->dst_port = htons(dport);
				pn->action = action;
				pn->num = num;
				pn->qos_en = del_pn->qos_en;
				pn->qos = del_pn->qos;
				hlist_del_rcu(&del_pn->snode);
				synchronize_rcu();
				kfree(del_pn);
				if(pn->dst_ip == 0){
					hlist_add_head_rcu(&pn->snode, &hi.hash_index[HI_HASH_NUM]);
				}else{
					key = sf_hi_ip_hash(&pn->dst_ip);
					hlist_add_head_rcu(&pn->snode, &hi.hash_index[key]);
				}
			}else{
				printk("edit: can not find param node\n");
			}

			break;
#ifdef CONFIG_SF_PKT_SEND_BY_KERNEL
		case CMD_SET_SERVER:
			ret = sscanf(buffer+2,"%hhu.%hhu.%hhu.%hhu %hu",
				   &sip[0], &sip[1], &sip[2], &sip[3], &sport);

			ts_dbg("cmd is %d\n", cmd);
			if(ret < 5){
				ts_dbg("set server and port: param error\n");
				break;
			}
			update_ip_port(ntohl(*((u32 *)sip)), sport);
			break;
#endif
		case CMD_RUN:
			ret = sscanf(buffer+2,"%hhu", &action);

			ts_dbg("cmd is %d\n", cmd);
			if(ret < 1){
				ts_dbg("set server and port: param error\n");
				break;
			}
			send_pkt_run(action);
			break;
		case CMD_QOS:
			ret = sscanf(buffer+2,"%u %hhd %hhd", &num, &qos_en, &qos);
			ts_dbg("cmd is %d\n", cmd);
			if(ret < 2){
				ts_dbg("flow qos: param error\n");
				break;
			}

			for(i=0; i< HI_NUM; i++){
				hlist_for_each_entry(edit_pn, &hi.hash_index[i], snode){
					if(edit_pn->num == num){
						pn = edit_pn;
						i = HI_NUM;
						break;
					}
				}
			}
			if(pn){
				if(qos_en >= 0){
					pn->qos_en = qos_en;
				}
				if(qos >= 0){
					pn->qos = qos << 2;
				}
			}
			break;
		default:
			break;
	}
done:
	return size;
}

static const struct file_operations sf_ts_hijack_ops = {
	.owner	 = THIS_MODULE,
	.open	 = sf_ts_hijack_open,
	.read	 = seq_read,
	.write	 = sf_ts_hijack_write,
	.llseek	 = seq_lseek,
	.release = single_release,
};


static unsigned int sf_ts_forward_hijack_fn(const struct nf_hook_ops *ops,
						struct sk_buff *skb,
						const struct net_device *in,
						const struct net_device *out,
						int (*okfn)(struct sk_buff *))
{
	struct param_node *pn;
	struct hlist_head *hh;
	u8 get_one = 0;
	u32 key;

	if(strncmp(in->name,"br-",3) == 0){
		struct iphdr *iph = ip_hdr(skb);
		__be16 sport;
		__be16 dport;
		u16 hlen;
		u8 mac0[6] = {0};
		u8 *mac = eth_hdr(skb)->h_source;
		u32 skb_daddr = iph->daddr;
		u32 skb_saddr = iph->saddr;

		if(iph->protocol == IPPROTO_TCP){
			struct tcphdr *thdr;
			thdr = tcp_hdr(skb);
			sport = thdr->source;
			dport = thdr->dest;
			hlen = thdr->doff*4;
		}else if (iph->protocol == IPPROTO_UDP){
			struct udphdr *uhdr;
			uhdr = udp_hdr(skb);
			sport = uhdr->source;
			dport = uhdr->dest;
			hlen = sizeof(*uhdr);
		}else{
			goto accept;
		}
		rcu_read_lock();
		key = sf_hi_ip_hash(&skb_daddr);
		hh = &hi.hash_index[key];
try_again:
		hlist_for_each_entry_rcu(pn, hh, snode){
			if(!(ether_addr_equal(mac, pn->mac) == true || ether_addr_equal(mac0, pn->mac) == true)){
				continue;
			}
			if(!(skb_daddr == pn->dst_ip || pn->dst_ip == 0)){
				continue;
			}
			if(!(skb_saddr == pn->src_ip || pn->src_ip == 0)){
				continue;
			}
			if(!(dport == pn->dst_port || pn->dst_port == 0)){
				continue;
			}
			if(!(sport == pn->src_port || pn->src_port == 0)){
				continue;
			}
			get_one = 1;
			break;
		}
		if(get_one != 1 && hh != &hi.hash_index[HI_HASH_NUM]){
			hh = &hi.hash_index[HI_HASH_NUM];
			goto try_again;
		}
		rcu_read_unlock();
		if(get_one){
			/*
			char *acc = "accept";
			char *drp = "drop";
			u8 *d, *s, *dt;
			int i = 0;
			d = (u8 *)(&skb_daddr);
			s = (u8 *)(&skb_saddr);
			dt = (u8 *)iph + hlen + iph->ihl*4;
			printk("upload: src: %hhu.%hhu.%hhu.%hhu dst %hhu.%hhu.%hhu.%hhu\n", s[0],s[1],s[2],s[3],d[0],d[1],d[2],d[3]);
			printk("data:\n");
			for(i=0;i<4;i++){
				printk("%02x %02x %02x %02x %02x %02x %02x %02x\n",
						dt[i+0],dt[i+1],dt[i+2],dt[i+3],dt[i+4],dt[i+5],dt[i+6],dt[i+7]);
			}
			printk("upload to server\n");
			printk("action: %s\n", pn->action ? acc : drp);
			printk("get upload\n");
			*/

			/*qos function*/
			if(pn->qos_en && iph->tos == 0){
				ipv4_change_dsfield(iph, 0, pn->qos);
			}

			pkt_enqueue(skb, 0);
			if(pn->action){
				goto accept;
			}else{
				goto drop;
			}
		}
	}else if(strncmp(in->name,"eth",3) == 0){
		skb->mark |= DMARK;
	}
accept:
	return NF_ACCEPT;
drop:
	return NF_DROP;

}
static unsigned int sf_ts_br_out_hajiack_fn(const struct nf_hook_ops *ops,
						struct sk_buff *skb,
						const struct net_device *in,
						const struct net_device *out,
						int (*okfn)(struct sk_buff *))

{
	struct param_node *pn;
	struct hlist_head *hh;
	u32 key;
	u8 get_one = 0;

	if(skb->mark & DMARK){
		struct iphdr *iph = ip_hdr(skb);
		__be16 sport;
		__be16 dport;
		u16 hlen;
		u8 mac0[6] = {0};
		u32 skb_daddr = iph->daddr;
		u32 skb_saddr = iph->saddr;
		u8 *mac = eth_hdr(skb)->h_dest;

		if(iph->protocol == IPPROTO_TCP){
			struct tcphdr *thdr;
			thdr = tcp_hdr(skb);
			sport = thdr->source;
			dport = thdr->dest;
			hlen = thdr->doff*4;
		}else if (iph->protocol == IPPROTO_UDP){
			struct udphdr *uhdr;
			uhdr = udp_hdr(skb);
			sport = uhdr->source;
			dport = uhdr->dest;
			hlen = sizeof(*uhdr);
		}else{
			goto accept;
		}

		rcu_read_lock();
		key = sf_hi_ip_hash(&skb_saddr);
		hh = &hi.hash_index[key];
try_again:
		hlist_for_each_entry_rcu(pn, hh, snode){
			if(!(ether_addr_equal(mac, pn->mac) == true || ether_addr_equal(mac0, pn->mac) == true)){
				continue;
			}
			if(!(skb_saddr == pn->dst_ip || pn->dst_ip == 0)){
				continue;
			}
			if(!(skb_daddr == pn->src_ip || pn->src_ip == 0)){
				continue;
			}
			if(!(sport == pn->dst_port || pn->dst_port == 0)){
				continue;
			}
			if(!(dport == pn->src_port || pn->src_port == 0)){
				continue;
			}
			get_one = 1;
			break;
		}
		if(get_one != 1 && hh != &hi.hash_index[HI_HASH_NUM]){
			hh = &hi.hash_index[HI_HASH_NUM];
			goto try_again;
		}
		rcu_read_unlock();
		if(get_one){
			/*
			char *acc = "accept";
			char *drp = "drop";
			u8 *d, *s, *dt;
			int i = 0;
			d = (u8 *)(&skb_daddr);
			s = (u8 *)(&skb_saddr);
			dt =(u8 *)iph + hlen + iph->ihl*4;
			printk("download: src: %hhu.%hhu.%hhu.%hhu dst %hhu.%hhu.%hhu.%hhu\n", s[0],s[1],s[2],s[3],d[0],d[1],d[2],d[3]);
			printk("data:\n");
			for(i=0;i<4;i++){
				printk(" %02x %02x %02x %02x %02x %02x %02x %02x\n",
						dt[i+0],dt[i+1],dt[i+2],dt[i+3],dt[i+4],dt[i+5],dt[i+6],dt[i+7]);
			}
			printk("upload to server\n");
			printk("action: %s\n", pn->action ? acc : drp);
			printk("get download\n");
			*/

			/*qos function*/
			if(pn->qos_en && iph->tos == 0){
				ipv4_change_dsfield(iph, 0, pn->qos);
			}

			pkt_enqueue(skb, 1);
			if(pn->action){
				goto accept;
			}else{
				goto drop;
			}
		}
	}
accept:
	return NF_ACCEPT;
drop:
	return NF_DROP;

}

static struct nf_hook_ops nf_sf_ts_ops[] __read_mostly = {
	{
		.hook		= sf_ts_ip_forward_fn,
		.owner		= THIS_MODULE,
		.pf			= NFPROTO_IPV4,
		.hooknum	= NF_INET_FORWARD,
		.priority	= NF_IP_PRI_SF_TS,
	},
	{
		.hook		= sf_ts_br_out_fn,
		.owner		= THIS_MODULE,
		.pf			= NFPROTO_BRIDGE,
		.hooknum	= NF_BR_LOCAL_OUT,
		.priority	= NF_BR_PRI_SF_TS,
	},
	{
		.hook		= sf_ts_forward_hijack_fn,
		.owner		= THIS_MODULE,
		.pf			= NFPROTO_IPV4,
		.hooknum	= NF_INET_FORWARD,
		.priority	= NF_IP_HIJACK_PRI_SF_TS,
	},
	{
		.hook		= sf_ts_br_out_hajiack_fn,
		.owner		= THIS_MODULE,
		.pf			= NFPROTO_BRIDGE,
		.hooknum	= NF_BR_LOCAL_OUT,
		.priority	= NF_BR_HIJACK_PRI_SF_TS,
	},
};

static int __init sf_ts_init(void)
{
	struct proc_dir_entry *file;
	int ret;

	hash_init(ts.hash_index);
	hi.num = 1;
	hash_init(hi.hash_index);

	get_random_bytes(&hashv, sizeof(hashv));

	send_pkt_init();

	ret = flow_init();
	if(ret < 0){
		goto err0;
	}

	ret = nf_register_hooks(nf_sf_ts_ops, ARRAY_SIZE(nf_sf_ts_ops));
	if(ret < 0)
		 goto err1;

	ts.update_enable = 1;
	init_timer(&ts.ts_timer);
	ts.ts_timer.function = &sf_do_update;
	ts.ts_timer.data =(unsigned long)&ts;
	ts.ts_timer.expires = jiffies + HZ;
	add_timer(&ts.ts_timer);


	file = proc_create("ts", 0644, NULL, &sf_ts_ops);
	if (!file){
		ret = -ENOMEM;
		goto err2;
	}

	ret = sf_ts_genl_init();
	if(ret < 0){
		goto err3;
	}

	file = proc_create("hi", 0644, NULL, &sf_ts_hijack_ops);
	if (!file){
		ret = -ENOMEM;
		goto err4;
	}

	ret = sf_qos_init();
	if(ret < 0){
		ret = -ENOMEM;
		goto err5;
	}

	printk("TS init success\n");

	return 0;
err5:
	remove_proc_entry("hi",NULL);
err4:
	sf_ts_genl_exit();
err3:
	remove_proc_entry("ts",NULL);
err2:
	del_timer(&ts.ts_timer);
	nf_unregister_hooks(nf_sf_ts_ops, ARRAY_SIZE(nf_sf_ts_ops));
err1:
	flow_exit();
err0:
	return ret;
}

static void __exit sf_ts_exit(void){
	struct sf_ts_dev *dev;
	struct param_node *pn;
	u16 i;

	nf_unregister_hooks(nf_sf_ts_ops, ARRAY_SIZE(nf_sf_ts_ops));
	printk("unregister hooks\n");
	remove_proc_entry("ts", NULL);
	remove_proc_entry("hi", NULL);
	sf_qos_exit();
	printk("rm procfs ts hi\n");
	sf_ts_genl_exit();
	printk("genl exit ok\n");
	send_pkt_exit();
	printk("send pkt thread exit\n");
	flow_exit();
	printk("flow exit\n");
	if(ts.update_enable){
		del_timer(&ts.ts_timer);
	}
	for(i=0; i < TS_HASH_SIZE; i++){
		hlist_for_each_entry(dev, &ts.hash_index[i], snode){
			free_percpu(dev->c);
			kfree(dev);
		}
	}
	for(i=0; i < HI_NUM; i++){
		hlist_for_each_entry(pn, &hi.hash_index[i], snode){
			kfree(pn);
		}
	}
}

module_init(sf_ts_init);
module_exit(sf_ts_exit);

MODULE_DESCRIPTION(DRV_NAME);
MODULE_VERSION(DRV_VERSION);
MODULE_AUTHOR("Xijun Guo <xijun.guo@siflower.org>");
MODULE_LICENSE("GPL");
