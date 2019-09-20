#include "sf-ts.h"

u32 ip_rnd __read_mostly;
struct hlist_head (*hash_ip)[FLOW_TYPE][FLOW_HASH_NUM];

int type_flow_check(struct sk_buff *skb, struct sf_ts_dev *dev){
	struct hlist_head (*hash_ip_rcu)[FLOW_TYPE][FLOW_HASH_NUM];
	struct hlist_node *hnode;
	struct sf_ip *inode;
	u32 i, j, key;
	struct iphdr *iph = ip_hdr(skb);

	key = sf_ip_hash(&iph->daddr);
	rcu_read_lock();
	hash_ip_rcu = rcu_dereference(hash_ip);
	for(i=0; i<FLOW_TYPE; i++){
		if((dev->flow_type_en >> i) & 0x1){
				hnode = (*hash_ip_rcu)[i][key].first;
				while(hnode){
					inode = (struct sf_ip *)hnode;
					j = 0;
					while(j < inode->use){
						if(iph->daddr == inode->ip[j]){
							rcu_read_unlock();
							//printk("drop type %d, ip is %x\n", i, iph->daddr);
							return SF_DROP;
						}
						++j;
					}
					hnode = inode->hnode.next;
				}
		}
	}
	rcu_read_unlock();
	return SF_ACCEPT;
}
EXPORT_SYMBOL_GPL(type_flow_check);

#define TYPE_GAME_KEY		htonl(0x7f000100)
#define TYPE_VIDEO_KEY		htonl(0x7f000200)
#define TYPE_SOCIAL_KEY		htonl(0x7f000300)
#define TYPE_GAME		0
#define TYPE_VIDEO		1
#define TYPE_SOCIAL		2
#define IP_BUFLEN		4

int type_flow_show(char *buf){
	struct hlist_head (* hash_ip_rcu)[FLOW_TYPE][FLOW_HASH_NUM];
	struct hlist_node *hnode;
	struct sf_ip *inode;
	int i, j, k, len = 0;
	u8 *ip;

	rcu_read_lock();
	hash_ip_rcu = rcu_dereference(hash_ip);

	for(i=0; i<FLOW_TYPE; i++){
		len += sprintf(buf + len,"tpye %d:\n", i);
		if(len < 0 || len > MAXBUF){
			return -1;
		}
		for(j=0; j<FLOW_HASH_NUM; j++){
			hnode = (*hash_ip_rcu)[i][j].first;
			while(hnode){
				k = 0;
				inode = (struct sf_ip *)hnode;
				printk("%d\n", inode->use);
				while(k < inode->use){
					ip = (u8 *)&inode->ip[k];
					len += sprintf(buf + len,"%hhx.%hhx.%hhx.%hhx\n", ip[0], ip[1], ip[2], ip[3]);
					if(len < 0 || len > MAXBUF){
						return -1;
					}
					k++;
				}
				hnode = hnode->next;
			}
		}
	}
	rcu_read_unlock();
	return 0;
}
EXPORT_SYMBOL_GPL(type_flow_show);

int deal_ses(u32 *sbuf, u32 end, struct hlist_head hasht[FLOW_HASH_NUM], u32 len){
	struct sf_ip *inode, *onode;
	int num = 0, ouse;
	u32 key, nip;

	while(sbuf[num] != end){
		nip = sbuf[num];
		key = sf_ip_hash(&nip);
//		printk("%x %u\n",sbuf[num], key);

		if(hasht[key].first == NULL){ //if first is null, alloc new struct
			inode = kmalloc(sizeof(*inode) + IP_BUFLEN*4, GFP_KERNEL);
			if(!inode){
				goto fail;
			}
			inode->ip[0] = nip;
			inode->len = IP_BUFLEN;
			inode->use = 1;
			hlist_add_head(&inode->hnode, &hasht[key]);
		}else{
			onode = (struct sf_ip *)hasht[key].first;
			if(onode->use < onode->len){
				ouse = onode->use;
				onode->ip[ouse] = nip;
				ouse += 1;
				onode->use = ouse;
			}else{ //if len is full, alloc new struct, new len is old len + IP_BUFLEN
				inode = kmalloc(sizeof(*inode) + onode->len*4 + IP_BUFLEN*4, GFP_KERNEL);
				if(!inode){
					goto fail;
				}
				memcpy(inode, onode, sizeof(*onode)+onode->len*4);
				ouse = onode->use;
				inode->ip[ouse] = nip;
				ouse += 1;
				inode->len = onode->len + IP_BUFLEN;
				inode->use = ouse;
				hasht[key].first = NULL;
				hlist_add_head(&inode->hnode, &hasht[key]);
				kfree(onode);
			}
		}
		++num;
		if(num >= len){
			pr_err("Config error, ip number is bigger than number from user pass\n");
			goto fail;
		}
	}
	return num+1;
fail:
	return -1;
}

void flow_ip_init(u32 *buf, u32 buflen){
	struct hlist_head (* new_hash)[FLOW_TYPE][FLOW_HASH_NUM];
	struct hlist_head (* free_hash)[FLOW_TYPE][FLOW_HASH_NUM];
	struct hlist_node *hnode, *nhnode;
	u32 i, j, len = 0, ip_num;
	free_hash = hash_ip;
	new_hash =(struct hlist_head (*)[FLOW_TYPE][FLOW_HASH_NUM])kmalloc(sizeof(*new_hash),GFP_KERNEL);

	if(!new_hash){
		pr_err("alloc new_hash mem fail\n");
		return;
	}

	for(i=0; i<FLOW_TYPE; i++ ){
		hash_init((*new_hash)[i]);
	}

	for(i=0; i<FLOW_TYPE; i++ ){
		printk("%x\n",buf[len]);
		switch(buf[len]){
			case TYPE_GAME_KEY:
				len += 1;
				ip_num = deal_ses(buf+len, TYPE_GAME_KEY, (*new_hash)[TYPE_GAME], buflen - len);
				//pr_debug("Game ok\n");
				break;
			case TYPE_VIDEO_KEY:
				len += 1;
				ip_num = deal_ses(buf+len, TYPE_VIDEO_KEY, (*new_hash)[TYPE_VIDEO], buflen - len);
				//pr_debug("Video ok\n");
				break;
			case TYPE_SOCIAL_KEY:
				len += 1;
				ip_num = deal_ses(buf+len, TYPE_SOCIAL_KEY, (*new_hash)[TYPE_SOCIAL], buflen - len);
				//pr_debug("Social ok\n");
				break;
			default:
				pr_err("tpye flow config error\n");
				free_hash = new_hash;
				goto fail;
				break;
		}
		if(ip_num < 0){
			free_hash = new_hash;
			goto fail;
		}
		len += ip_num;
		if(len > buflen){
			free_hash = new_hash;
			pr_err("flow init error, len is %d\n", len);
			goto fail;
		}else if(len == buflen){
			break;
		}
	}
	rcu_assign_pointer(hash_ip, new_hash);
	synchronize_rcu();
fail:
	for(i=0; i<FLOW_TYPE; i++){
		for(j=0; j<FLOW_HASH_NUM; j++){
			hnode = (*free_hash)[i][j].first;
			while(hnode){
				nhnode = hnode->next;
				kfree((struct sf_ip *)hnode);
				hnode = nhnode;
			}
		}
	}
	kfree(free_hash);
	return;
}
EXPORT_SYMBOL_GPL(flow_ip_init);

int flow_init(void){

	u32 rand;
	int i;

	do{
		get_random_bytes(&rand, sizeof(rand));
	}while(!rand);

	cmpxchg(&ip_rnd, 0, rand);

	hash_ip =(struct hlist_head (*)[FLOW_TYPE][FLOW_HASH_NUM])kmalloc(sizeof(*hash_ip),GFP_KERNEL);
	if(!hash_ip){
		pr_err("alloc hash_ip mem fail\n");
		return -1;
	}

	for(i=0; i<FLOW_TYPE; i++ ){
		hash_init((*hash_ip)[i]);
	}

	return 0;
}
EXPORT_SYMBOL_GPL(flow_init);

void flow_exit(void){
	struct hlist_node *hnode, *nhnode;
	u32 i, j;

	for(i=0; i<FLOW_TYPE; i++){
		for(j=0; j<FLOW_HASH_NUM; j++){
			hnode = (*hash_ip)[i][j].first;
			while(hnode){
				nhnode = hnode->next;
				kfree((struct sf_ip *)hnode);
				hnode = nhnode;
			}
		}
	}
	kfree(hash_ip);
}
EXPORT_SYMBOL_GPL(flow_exit);
