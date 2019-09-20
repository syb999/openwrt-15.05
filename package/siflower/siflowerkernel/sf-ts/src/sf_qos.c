#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <uapi/linux/in.h>
#include "sf-ts.h"


static int sf_qos_show(struct seq_file *file, void *v){
	struct sf_ts_dev *dev;
	u8 *mac;
	int i;

	seq_printf(file, "mac               qos game video social\n");
	rcu_read_lock();
	for(i =0; i < TS_HASH_SIZE; i++){
		hlist_for_each_entry(dev, &ts.hash_index[i], snode){
			mac = dev->mac;
			seq_printf(file, "%02X:%02X:%02X:%02X:%02X:%02X     %hhu %hhu %hhu %hhu\n",
					mac[0], mac[1], mac[2], mac[3], mac[4], mac[5],
					dev->t_qos, dev->qos[0] >> 2, dev->qos[1] >> 2, dev->qos[2] >> 2);
		}
	}
	rcu_read_unlock();
	return 0;
}

static int sf_qos_open(struct inode *inode, struct file *file){
	return single_open(file, sf_qos_show, inode->i_private);
}

static ssize_t sf_qos_write(struct file *file, const char __user *input,
				size_t size, loff_t *ofs)
{
	struct sf_ts_dev *dev;
	int ret;
	u32 cmd;
	u8 buffer[BUF_SIZE + 1];
	s8 qos, game, video, social;
	u8 mac[ETH_ALEN];

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
	ts_dbg("cmd is %d\n", cmd);
	switch(cmd){
		case CMD_SET_QOS:
			ret = sscanf(buffer+2,"%2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx %hhd %hhd %hhd %hhd",
				&mac[0], &mac[1], &mac[2], &mac[3], &mac[4], &mac[5], &qos, &game, &video, &social);
			if(ret < 10){
				ts_dbg("sf qos set param error\n");
				break;
			}
			dev = check_dev_in_hlist(mac);
			if(dev){
				if(qos >= 0){
					dev->t_qos = qos;
				}
				if(game >= 0){
					dev->qos[0] = game << 2;
				}
				if(video >= 0){
					dev->qos[1] = video << 2;
				}
				if(social >= 0){
					dev->qos[2] = social << 2;
				}
			}else{
				pr_err("can not find device\n");
			}
			break;

		default:
			break;
	}
done:
	return size;
}

static const struct file_operations sf_qos_ops = {
	.owner	 = THIS_MODULE,
	.open	 = sf_qos_open,
	.read	 = seq_read,
	.write	 = sf_qos_write,
	.llseek	 = seq_lseek,
	.release = single_release,
};

void type_flow_qos(struct sk_buff *skb, struct sf_ts_dev *dev, u8 upload){
	struct hlist_head (*hash_ip_rcu)[FLOW_TYPE][FLOW_HASH_NUM];
	struct hlist_node *hnode;
	struct sf_ip *inode;
	u32 i, j, key;
	__be32 addr;
	struct iphdr *iph = ip_hdr(skb);

	/*if it is upload packet, use destination address, otherwise use source address*/
	if(upload == 1){
		key = sf_ip_hash(&iph->daddr);
		addr = iph->daddr;
	}else{
		key = sf_ip_hash(&iph->saddr);
		addr = iph->saddr;
	}
	rcu_read_lock();
	hash_ip_rcu = rcu_dereference(hash_ip);
	for(i=0; i<FLOW_TYPE; i++){
		hnode = (*hash_ip_rcu)[i][key].first;
		while(hnode){
			inode = (struct sf_ip *)hnode;
			j = 0;
			while(j < inode->use){
				if(addr == inode->ip[j]){
					rcu_read_unlock();
					if(iph->tos == 0){
						ipv4_change_dsfield(iph,0, dev->qos[i]);
					}
					//printk("qos type %d, qos is %x\n", i, iph->tos);
					return;
				}
				++j;
			}
			hnode = inode->hnode.next;
		}
	}
	rcu_read_unlock();
	return;
}
EXPORT_SYMBOL_GPL(type_flow_qos);

int __init sf_qos_init(void){
	struct proc_dir_entry *file;

	file = proc_create("sf_qos", 0644, NULL, &sf_qos_ops);
	if (!file){
		return -1;
	}
	return 0;
}
EXPORT_SYMBOL_GPL(sf_qos_init);

void __exit sf_qos_exit(void){
	remove_proc_entry("sf_qos",NULL);
}
EXPORT_SYMBOL_GPL(sf_qos_exit);
