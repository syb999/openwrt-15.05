/*
 * =====================================================================================
 *
 *       Filename:  main.c
 *
 *    Description:  call the wireless extension' cmd to make clear how the drivers(mac80211) support
 *                  wext
 *
 *        Version:  1.0
 *        Created:  02/22/2016 03:56:43 PM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  franklin , franklin.wang@siflower.com.cn
 *        Company:  Siflower Communication Tenology Co.,Ltd
 *
 * =====================================================================================
 */
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <sys/socket.h>
#include <linux/wireless.h>
#include <getopt.h>
//#define IFNAME "wlan0"
char ifname[16] = {"wlan0"};

char beacon[192] = {
	0x80, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x16, 0x88, 0x08, 0x07, 0xf9,
	0x00, 0x16, 0x88, 0x08, 0x07, 0xf9, 0x20, 0x5e, 0x5f, 0x20, 0x31, 0x3b, 0x00, 0x00, 0x00, 0x00,
	0x64, 0x00, 0x01, 0x00, 0x00, 0x06, 0x6f, 0x70, 0x65, 0x6e, 0x35, 0x67, 0x01, 0x08, 0x8c, 0x12,
	0x98, 0x24, 0xb0, 0x48, 0x60, 0x6c, 0x03, 0x01, 0x9d, 0x07, 0x06, 0x4e, 0x6f, 0x20, 0x24, 0x0d,
	0x14, 0x05, 0x04, 0x00, 0x01, 0x00, 0x00, 0x2d, 0x1a, 0xec, 0x01, 0x17, 0xff, 0xff, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x3d, 0x16, 0x9d, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbf, 0x0c, 0xa0, 0x01, 0xc0,
	0x31, 0xfa, 0xff, 0x0c, 0x03, 0xfa, 0xff, 0x0c, 0x03, 0xc0, 0x05, 0x00, 0x00, 0x00, 0xf5, 0xff,
	0x7f, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0xdd, 0x18, 0x00, 0x50, 0xf2, 0x02,
	0x01, 0x01, 0x00, 0x00, 0x03, 0xa4, 0x00, 0x00, 0x27, 0xa4, 0x00, 0x00, 0x42, 0x43, 0x5e, 0x00,
	0x62, 0x32, 0x2f, 0x00, 0xdd, 0x07, 0x00, 0x0c, 0x43, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

#define IS_24G 1
#define ETH_P_SFCFG 0x1688
#define SFCFG_MAGIC_NO      0x18181688

/*  command id */
#define SFCFG_CMD_ATE_START				 0x0000
#define SFCFG_CMD_ATE_STOP				 0x0001
#define SFCFG_CMD_ATE_TX_START			 0x0002
#define SFCFG_CMD_ATE_TX_STOP			 0x0003
#define SFCFG_CMD_ATE_RX_START			 0x0004
#define SFCFG_CMD_ATE_RX_STOP			 0x0005
#define SFCFG_CMD_ATE_TX_FRAME_START	 0x0006
#define SFCFG_CMD_ATE_RX_FRAME_START	 0x0007
#define SFCFG_CMD_ATE_MACBYPASS_TX_START 0x0008
#define SFCFG_CMD_ATE_MACBYPASS_TX_STOP  0x0009
#define SFCFG_CMD_ATE_TX_TEST_TONE_START 0x000a
#define SFCFG_CMD_ATE_TX_TEST_TONE_STOP  0x000b
#define SFCFG_CMD_ATE_MACBYPASS_RX_START 0x000c
#define SFCFG_CMD_ATE_MACBYPASS_RX_STOP  0x000d

#define SFCFG_CMD_ATE_SET_BANDWIDTH		0x0100
#define SFCFG_CMD_ATE_SET_CHANNEL		0x0101
#define SFCFG_CMD_ATE_SET_PHY_MODE		0x0102
#define SFCFG_CMD_ATE_SET_RATE			0x0103
#define SFCFG_CMD_ATE_SET_PREAMBLE		0x0104
#define SFCFG_CMD_ATE_SET_GI			0x0105
#define SFCFG_CMD_ATE_SET_TX_POWER		0x0106
#define SFCFG_CMD_ATE_GET_INFO			0x0107
#define SFCFG_CMD_ATE_SAVE_TO_FLASH		0x0108
#define SFCFG_CMD_ATE_SET_CENTER_FREQ1	0x0109

#define SFCFG_CMD_ATE_WHOLE_FRAME			0x1000
#define SFCFG_CMD_ATE_TX_COUNT				0x1001
#define SFCFG_CMD_ATE_PAYLOAD_LENGTH		0x1002
#define SFCFG_CMD_ATE_TX_FC					0x1003
#define SFCFG_CMD_ATE_TX_DUR				0x1004
#define SFCFG_CMD_ATE_TX_BSSID				0x1005
#define SFCFG_CMD_ATE_TX_DA					0x1006
#define SFCFG_CMD_ATE_TX_SA					0x1007
#define SFCFG_CMD_ATE_TX_SEQC				0x1008
#define SFCFG_CMD_ATE_PAYLOAD				0x1009
#define SFCFG_CMD_ATE_TX_FRAME_BW			0x100a
#define SFCFG_CMD_ATE_MACBYPASS_INTERVAL    0x100b

#define SFCFG_CMD_ATE_READ_REG       0x10000
#define SFCFG_CMD_ATE_WRITE_REG      0x10001
#define SFCFG_CMD_ATE_BULK_READ_REG  0x10002
#define SFCFG_CMD_ATE_BULK_WRITE_REG 0x10003

#define SFCFG_PRIV_IOCTL_ATE	  (SIOCIWFIRSTPRIV + 0x08)

#define true  1
#define false 0

typedef unsigned char   bool;
typedef unsigned char   uint8_t;
typedef int    int32_t;
typedef unsigned int   uint32_t;
typedef unsigned short  uint16_t;

enum register_mode {
	MAC_REG,
	PHY_REG,
	RF_REG,
};

bool g_tx_frame_flag = false;
bool g_rx_frame_flag = false;
bool g_stop_tx_frame_flag = false;
bool g_stop_rx_frame_flag = false;
bool g_clock_flag = false;
bool g_start_tx_frame_by_macbypass_flag = false;
bool g_stop_tx_frame_by_macbypass_flag = false;
bool g_start_rx_by_macbypass_flag = false;
bool g_stop_rx_by_macbypass_flag = false;
bool g_tx_test_tone_flag = false;
bool g_stop_tx_test_tone_flag = false;
bool g_agg_tx_frame_flag = false;

unsigned int g_tx_frame_num  = 1;
unsigned int g_tx_chan_freq  = 2412;
unsigned int g_tx_band_width = 0;
unsigned int g_tx_mode       = 0;
unsigned int g_tx_rate_idx   = 0;
unsigned int g_tx_use_sgi    = 0;
unsigned int g_tx_power    = 0;

static int32_t ioctl_socket = -1;
#if 0
static  uint8_t *sa = "16:88:aa:bb:cc:ee";
static  uint8_t *da = "16:88:aa:bb:cc:ee";
static  uint8_t *bssid = "16:88:aa:bb:cc:ee";
#endif
struct tx_frame_param {
	int frame_num;
};

enum ieee80211_band {
	IEEE80211_BAND_2GHZ =0,
	IEEE80211_BAND_5GHZ,
	IEEE80211_BAND_60GHZ,

	/* keep last */
	IEEE80211_NUM_BANDS
};


enum nl80211_chan_width {
	NL80211_CHAN_WIDTH_20_NOHT,
	NL80211_CHAN_WIDTH_20,
	NL80211_CHAN_WIDTH_40,
	NL80211_CHAN_WIDTH_80,
	NL80211_CHAN_WIDTH_80P80,
	NL80211_CHAN_WIDTH_160,
};


enum format_mode {
	NON_HT_MODE = 0,
	NON_HT_DUP_MODE,
	HT_MM_MODE,
	HT_GF_MODE,
	VHT_MODE,
};


struct rwnx_ate_channel_params{
	enum ieee80211_band chan_band;
	unsigned int chan_freq;
	enum nl80211_chan_width chan_width;
};


struct rwnx_ate_rate_params{
	enum format_mode mode;
	unsigned int rate_idx;
	bool use_short_preamble; //only for 2.4G CCK mode rate_idx 1~3
	bool use_short_gi;       //for HT VHT mode but not HT_GF_MODE
};

struct rwnx_ate_packet_params{
	unsigned int frame_num;
	unsigned int frame_len;
	unsigned int tx_power;
};

struct rwnx_ate_address_params{
	unsigned char bssid[6];
	unsigned char da[6];
	unsigned char sa[6];
	unsigned char addr4[6];

};

struct sfcfghdr {
	uint32_t magic_no;
	uint32_t comand_type;
	uint32_t comand_id;
	uint16_t length;
	uint16_t sequence;
	uint32_t status;
	uint8_t  data[2048];
}__attribute__((packed));



//back to user space  /sync to user space parameter
struct rwnx_ioctl_ate_dump_info {
	int bandwidth;
	int frame_bandwidth;
	int band;
	int freq;
	int freq1;
	int rate;
	int mode;
	int gi;
	int pre;
	int power;
	int len;
	int rssi;
	int reg_status;
	uint32_t xof1;
	uint32_t xof2;
	uint32_t count;
	uint32_t tx_cont;
	uint32_t tx_successful;
	uint32_t tx_retry;
	uint32_t rec_rx_count;
	uint32_t fcs_err;
	uint32_t per;
	uint32_t phy_err;
	uint32_t reg_val;
	uint8_t  bssid[12];
	uint8_t  da[12];
	uint8_t  sa[12];
}__attribute__((packed));


/* create the socket fd to wext ioctl*/
static int32_t get_ioctl_socket(void)
{
	/*  Prepare socket */
	if (ioctl_socket == -1)
	{
		ioctl_socket = socket(AF_INET, SOCK_DGRAM, 0);
		fcntl(ioctl_socket, F_SETFD, fcntl(ioctl_socket, F_GETFD) | FD_CLOEXEC);
	}

	return ioctl_socket;
}

/* close the ioctl socket fd*/
void close_ioctl_socket(void)
{
	if (ioctl_socket > -1)
		close(ioctl_socket);
	ioctl_socket = -1;
}


/* do the ioctl*/
int32_t do_ioctl(int32_t cmd, struct iwreq *wrq)
{
	int32_t s = get_ioctl_socket();
	if(!wrq){
		printf("%s error:wrq is NULL\n",__func__);
		return -1;
	}
	strncpy(wrq->ifr_name, ifname, IFNAMSIZ);
	if(s < 0)
		return s;
	return ioctl(s, cmd, wrq);
}


/*
 *Show ATE parameters
 *SFCFG_CMD_ATE_ATESHOW
 *desc:
 *   .header_type    = IW_HEADER_TYPE_ATESHOW,
 *   .flags      = IW_DESCR_FLAG_DUMP,
 * */


int32_t get_ate_info()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info *usdrv;

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
	tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
	tmp.length      = 10;
	tmp.sequence    = 1;

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
		printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
		return -1;
	}
    usdrv = (struct rwnx_ioctl_ate_dump_info *)malloc(sizeof(struct rwnx_ioctl_ate_dump_info));
    if(!usdrv){
        printf("oom!\n");
        return -2;
    }

	memset(usdrv,0,sizeof(struct rwnx_ioctl_ate_dump_info));
	memcpy(usdrv, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));

	printf("bandwidth = %d\n",usdrv->bandwidth);
	printf("frame_bandwidth = %d\n",usdrv->frame_bandwidth);
	printf("band = %d\n",usdrv->band);
	printf("freq = %d\n",usdrv->freq);
	printf("freq = %d\n",usdrv->freq1);
	printf("rate = %d\n",usdrv->rate);
	printf("mode = %d\n",usdrv->mode);
	printf("GI = %d\n",usdrv->gi);
	printf("preamble = %d\n",usdrv->pre);
	printf("power = %d\n",usdrv->power);
	printf("length = %d\n",usdrv->len);
	printf("rssi = %d\n",usdrv->rssi);
	printf("reg_status = %d\n",usdrv->reg_status);
	printf("xof1 = %d\n",usdrv->xof1);
	printf("xof2 = %d\n",usdrv->xof2);
	printf("total count = %d\n",usdrv->count);
	printf("tx_cont = %d\n",usdrv->tx_cont);
	printf("tx_successful = %d\n",usdrv->tx_successful);
	printf("tx_retry = %d\n",usdrv->tx_retry);
	printf("rec_rx_count = %d\n",usdrv->rec_rx_count);
	printf("fcs_err = %d\n",usdrv->fcs_err);
	printf("per = %d\n",usdrv->per);
	printf("phy_err = %d\n",usdrv->phy_err);
	printf("reg_val = %d\n",usdrv->reg_val);
	printf("bssid = 0x%02x : 0x%02x : 0x%02x : 0x%02x : 0x%02x : 0x%02x\n",usdrv->bssid[0],usdrv->bssid[1],usdrv->bssid[2],usdrv->bssid[3],usdrv->bssid[4],usdrv->bssid[5]);
	printf("da = 0x%02x : 0x%02x : 0x%02x : 0x%02x : 0x%02x : 0x%02x\n",usdrv->da[0],usdrv->da[1],usdrv->da[2],usdrv->da[3],usdrv->da[4],usdrv->da[5]);
	printf("sa = 0x%02x : 0x%02x : 0x%02x : 0x%02x : 0x%02x : 0x%02x\n",usdrv->sa[0],usdrv->sa[1],usdrv->sa[2],usdrv->sa[3],usdrv->sa[4],usdrv->sa[5]);
    free(usdrv);
	return 0;
}

int32_t read_iw_reg(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info user_reg;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate read reg
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_READ_REG;
	tmp.comand_id   = SFCFG_CMD_ATE_READ_REG;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata,20);
	printf("tmp.data= %s---------\n",tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_READ_REG failed\n");
		return -1;
	}
	//get the results
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
	tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
	tmp.length      = 10;
	tmp.sequence    = 1;
	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
		printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
		return -1;
	}
	memset(&user_reg,0,sizeof(struct rwnx_ioctl_ate_dump_info));
	memcpy(&user_reg, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));
	printf("register value = 0x%x\n",user_reg.reg_val);
	return 0;
}

int32_t write_iw_reg(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info user_reg;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate read reg
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_WRITE_REG;
	tmp.comand_id   = SFCFG_CMD_ATE_WRITE_REG;
	tmp.length      = 21;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata,tmp.length);
	printf("tmp.data= %s---------\n",tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_WRITE_REG failed\n");
		return -1;
	}
	//get the results
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
	tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
	tmp.length      = 10;
	tmp.sequence    = 1;
	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
		printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
		return -1;
	}
	memset(&user_reg,0,sizeof(struct rwnx_ioctl_ate_dump_info));
	memcpy(&user_reg, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));
	if(user_reg.reg_status == 0){
		printf("write register %x done!\n",user_reg.reg_val);
	}
	else{
		printf("write register fail!\n");
	}
	return 0;
}

int32_t read_iw_bulk_reg(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info user_reg;
	int num = 0;
	int type = 0;
	int space = 0;
	int i = 0;
	char addrs[1000] = {0};
	char tmp_addr[9] = {0};
	if(tmpdata[0]=='0'){
		type = MAC_REG;
		space = 8;}
	else if(tmpdata[0]=='1'){
		type = PHY_REG;
		space = 8;}
	else{type = 2;
		space = 4;
	}
	num = atoi(tmpdata+2);
	memcpy(addrs,tmpdata+4,sizeof(addrs));
	while(i<num){
		memcpy(tmp_addr,tmpdata+4+i*(space+1),space);
		memset(&wrq, 0, sizeof(struct iwreq));
		memset(&tmp, 0, sizeof(struct sfcfghdr));

		// cmd ate read reg
		tmp.magic_no = SFCFG_MAGIC_NO;
		tmp.comand_type = SFCFG_CMD_ATE_READ_REG;
		tmp.comand_id   = SFCFG_CMD_ATE_READ_REG;
		tmp.length      = 8;
		tmp.sequence    = 1;

		memcpy(tmp.data,tmp_addr,tmp.length);

		wrq.u.data.pointer = (caddr_t)&tmp;
		wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
		if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
			printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_READ_BULK_REG failed\n");
			return -1;
		}
		//get the results
		memset(&wrq, 0, sizeof(struct iwreq));
		memset(&tmp, 0, sizeof(struct sfcfghdr));

		tmp.magic_no = SFCFG_MAGIC_NO;
		tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
		tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
		tmp.length      = 10;
		tmp.sequence    = 1;
		wrq.u.data.pointer = (caddr_t)&tmp;
		wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
		if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
			printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
			return -1;
		}
		memset(&user_reg,0,sizeof(struct rwnx_ioctl_ate_dump_info));
		memcpy(&user_reg, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));
		printf("register:0x%s value = 0x%x\n",tmp_addr,user_reg.reg_val);
		i++;
	}
	return 0;
}


int32_t write_iw_bulk_reg(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info user_reg;
	int num = 0;
	int type = 0;
	int space = 0;
	int i = 0;
	char addrs[1000] = {0};
	char tmp_addr_val[18] = {0};
	char tmp_addr[9] = {0};
	if(tmpdata[0]=='0'){
		type = MAC_REG;
		space = 17;}
	else if(tmpdata[0]=='1'){
		type = PHY_REG;
		space = 17;}
	else{type = RF_REG;
		space = 9;
	}
	num = atoi(tmpdata+2);
	memcpy(addrs,tmpdata+4,sizeof(addrs));
	while(i<num){
		memcpy(tmp_addr_val,tmpdata+4+i*(space+1),space);
		memcpy(tmp_addr,tmp_addr_val,(space-1)/2);
		memset(&wrq, 0, sizeof(struct iwreq));
		memset(&tmp, 0, sizeof(struct sfcfghdr));

		// cmd ate write reg
		tmp.magic_no = SFCFG_MAGIC_NO;
		tmp.comand_type = SFCFG_CMD_ATE_WRITE_REG;
		tmp.comand_id   = SFCFG_CMD_ATE_WRITE_REG;
		tmp.length      = space;
		tmp.sequence    = 1;

		memcpy(tmp.data,tmp_addr_val,tmp.length);

		wrq.u.data.pointer = (caddr_t)&tmp;
		wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
		if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
			printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_WRITE_BULK_REG failed\n");
			return -1;
		}
		//get the results
		memset(&wrq, 0, sizeof(struct iwreq));
		memset(&tmp, 0, sizeof(struct sfcfghdr));

		tmp.magic_no = SFCFG_MAGIC_NO;
		tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
		tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
		tmp.length      = 10;
		tmp.sequence    = 1;
		wrq.u.data.pointer = (caddr_t)&tmp;
		wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
		if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
			printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
			return -1;
		}
		memset(&user_reg,0,sizeof(struct rwnx_ioctl_ate_dump_info));
		memcpy(&user_reg, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));
		if(user_reg.reg_status == 0){
			printf("write register:0x%s done!\n",tmp_addr);
		}
		else{
			printf("write register:0x%s fail!\n",tmp_addr);
		}
		i++;
	}
	return 0;
}


int32_t set_phy_bandwidth(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate bandwidth
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_BANDWIDTH;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_BANDWIDTH;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata,10);
	//printf("tmp.data= %s---------\n",tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_BANDWIDTH failed\n");
		return -1;
	}

	return 0;
}


int32_t set_phy_chan_freq(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_CHANNEL;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_CHANNEL;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data,tmpdata,10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_CHANNEL failed\n");
		return -1;
	}
	return 0;

}


int32_t set_phy_center_freq1(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_CENTER_FREQ1;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_CENTER_FREQ1;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data,tmpdata,10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_CENTER_FREQ1 failed\n");
		return -1;
	}
	return 0;

}

int32_t set_phy_mode(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_PHY_MODE;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_PHY_MODE;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_PHY_MODE failed\n");
		return -1;
	}

	return 0;

}


int32_t set_phy_rate_idx(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_RATE;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_RATE;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_RATE failed\n");
		return -1;
	}
	return 0;

}


int32_t set_phy_use_sgi(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_GI;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_GI;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_GI failed\n");
		return -1;
	}
	return 0;

}


int32_t set_phy_preamble(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_PREAMBLE;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_PREAMBLE;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_PREAMBLE failed\n");
		return -1;
	}
	return 0;

}


int32_t set_phy_power(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SET_TX_POWER;
	tmp.comand_id   = SFCFG_CMD_ATE_SET_TX_POWER;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_TX_POWER failed\n");
		return -1;
	}
	return 0;

}


int32_t set_pkg_bandwidth(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate bandwidth
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_FRAME_BW;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_FRAME_BW;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata,10);
	//printf("tmp.data= %s---------\n",tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_FRAME_BW failed\n");
		return -1;
	}
	return 0;
}


int32_t set_pkg_frame_length(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_PAYLOAD_LENGTH;
	tmp.comand_id   = SFCFG_CMD_ATE_PAYLOAD_LENGTH;
	tmp.length      = 10;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_PAYLOAD_LENGTH failed\n");
		return -1;
	}
	return 0;

}

int32_t set_pkg_frame_num(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate num
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_COUNT;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_COUNT;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data,tmpdata,10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_TX_COUNT failed\n");
		return -1;
	}
	return 0;

}

int32_t set_pkg_macbypass_interval(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate num
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_MACBYPASS_INTERVAL;
	tmp.comand_id   = SFCFG_CMD_ATE_MACBYPASS_INTERVAL;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data,tmpdata,10);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_MACBYPASS_INTERVAL failed\n");
		return -1;
	}
	return 0;
}

int32_t set_pkg_fc(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_FC;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_FC;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 20);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_TX_FC failed\n");
		return -1;
	}
	return 0;

}


int32_t set_pkg_dur(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_DUR;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_DUR;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 20);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_TX_DUR failed\n");
		return -1;
	}
	return 0;

}


int32_t set_pkg_bssid(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_BSSID;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_BSSID;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 20);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_BSSID failed\n");
		return -1;
	}
	return 0;

}


int32_t set_pkg_da(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_DA;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_DA;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 20);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_DA failed\n");
		return -1;
	}
	return 0;

}


int32_t set_pkg_sa(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_SA;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_SA;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 20);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_SA failed\n");
		return -1;
	}
	return 0;

}


int32_t set_pkg_seqc(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_SEQC;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_SEQC;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, 20);
	//printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_PHY_MODE failed\n");
		return -1;
	}
	return 0;
}


int32_t set_pkg_whole_frame(char beacon[], int length_array)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	int i = 0;
	//fill beacon mac header
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	//cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_WHOLE_FRAME;
	tmp.comand_id   = SFCFG_CMD_ATE_WHOLE_FRAME;
	tmp.length      = length_array;
	tmp.sequence    = 1;

	printf("%s: length_array = %d\n",__func__,length_array);
	memcpy(tmp.data, beacon, length_array);

	for(i = 0; i <= length_array; i++)
	{
		printf("%s: tmp.data[%d] = 0x%02x\n",__func__,i,tmp.data[i]);
	}

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_PHY_MODE failed\n");
		return -1;
	}
	return 0;
}


int32_t set_pkg_payload(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	int i = 0;
	printf("~~~set_pkg_payload,%lu\n",sizeof(tmpdata));
	//fill the frame payload
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	//cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_PAYLOAD;
	tmp.comand_id   = SFCFG_CMD_ATE_PAYLOAD;
	tmp.length      = sizeof(tmpdata);
	tmp.sequence    = 1;

	memcpy(tmp.data, tmpdata, sizeof(tmpdata));
	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SET_PAYLOAD failed\n");
		return -1;
	}
	return 0;
}

int32_t send_tx_test_tone_start()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_TEST_TONE_START;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_TEST_TONE_START;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data, "true", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_TEST_TONE_START failed\n");
		return -1;
	}
	return 0;
}

int32_t send_tx_test_tone_stop()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	//first call SFCFG_CMD_ATE_START
	tmp.comand_type = SFCFG_CMD_ATE_TX_TEST_TONE_STOP;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_TEST_TONE_STOP;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data, "true", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_TEST_TONE_STOP failed\n");
		return -1;
	}
	return 0;
}

int32_t send_ate_start()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	//struct tx_frame_param *tx_frame_param = NULL;
	// struct rwnx_ate_config_params *ate_config_params = NULL;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	//first call SFCFG_CMD_ATE_START
	tmp.comand_type = SFCFG_CMD_ATE_START;
	tmp.comand_id   = SFCFG_CMD_ATE_START;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data, "true", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_START failed\n");
		return -1;
	}
	return 0;
}

int32_t send_ate_stop()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	//struct tx_frame_param *tx_frame_param = NULL;
	// struct rwnx_ate_config_params *ate_config_params = NULL;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	//first call SFCFG_CMD_ATE_START
	tmp.comand_type = SFCFG_CMD_ATE_STOP;
	tmp.comand_id   = SFCFG_CMD_ATE_STOP;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data, "true", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_STOP failed\n");
		return -1;
	}
	return 0;
}


int32_t send_tx_start(char *bufs)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	//struct tx_frame_param *tx_frame_param = NULL;
	// struct rwnx_ate_config_params *ate_config_params = NULL;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	//first call SFCFG_CMD_ATE_START
	tmp.comand_type = SFCFG_CMD_ATE_TX_START;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_START;
	tmp.length      = 10;
	tmp.sequence    = 1;

	if(bufs != NULL)
		memcpy(tmp.data, bufs, sizeof(bufs));
	else
		strncpy(tmp.data, "true", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_START failed\n");
		return -1;
	}
	return 0;
}


int32_t send_tx_start_by_macbypass()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	//first call SFCFG_CMD_ATE_START
	tmp.comand_type = SFCFG_CMD_ATE_MACBYPASS_TX_START;
	tmp.comand_id   = SFCFG_CMD_ATE_MACBYPASS_TX_START;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data, "true", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_MACBYPASS_TX_START failed\n");
		return -1;
	}
	return 0;
}


int32_t send_rx_start()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info user;
	uint32_t tmp1 = 0;
	uint32_t tmp2 = 0;
	uint32_t tmp3 = 0;
	uint32_t per = 0;
	uint32_t tmp_f = 0;
	uint32_t tmp_p = 0;
	uint32_t tmp_r = 0;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	//first call SFCFG_CMD_ATE_START
	tmp.comand_type = SFCFG_CMD_ATE_RX_START;
	tmp.comand_id   = SFCFG_CMD_ATE_RX_START;
	tmp.length      = 10;
	tmp.sequence    = 1;

	strncpy(tmp.data, "true", 10);
	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_RX_START failed\n");
		return -1;
	}

	//read results from driver
	printf("show PER, RSSI!\n");
	g_clock_flag = 1;
#if 1
	while(g_clock_flag){
		sleep(3);
		memset(&wrq, 0, sizeof(struct iwreq));
		memset(&tmp, 0, sizeof(struct sfcfghdr));

		tmp.magic_no = SFCFG_MAGIC_NO;
		tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
		tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
		tmp.length      = 10;
		tmp.sequence    = 1;

		wrq.u.data.pointer = (caddr_t)&tmp;
		wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
		if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
			printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
			return -1;
		}
		memset(&user, 0, sizeof(struct rwnx_ioctl_ate_dump_info));
		memcpy(&user, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));

		tmp_f = user.fcs_err - tmp1;
		tmp_p = user.phy_err - tmp2;
		tmp_r = user.rec_rx_count - tmp3;
		if(tmp_r)
			per = ((tmp_f+tmp_p)*100/tmp_r);
		else
			per = 100;
		tmp1 = user.fcs_err;
		tmp2 = user.phy_err;
		tmp3 = user.rec_rx_count;
		printf("receive data = %d,rssi = %d,fcs error = %d,phy error = %d,per(every 3 seconds) = %d, per(from the beginning) = %d\n",
				user.rec_rx_count, user.rssi, user.fcs_err, user.phy_err, per, user.per);
	}
#endif
	return 0;
}

int32_t send_rx_start_by_macbypass()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	struct rwnx_ioctl_ate_dump_info user;
	uint32_t tmp1 = 0;
	uint32_t tmp2 = 0;
	uint32_t tmp3 = 0;
	uint32_t per = 0;
	uint32_t tmp_f = 0;
	uint32_t tmp_p = 0;
	uint32_t tmp_r = 0;

	printf("%s>>\n", __func__);

	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_MACBYPASS_RX_START;
	tmp.comand_id   = SFCFG_CMD_ATE_MACBYPASS_RX_START;
	tmp.length      = 20;
	tmp.sequence    = 1;

	strncpy(tmp.data, "rx start macby", tmp.length);

	wrq.u.data.pointer = (caddr_t)&tmp;

	//12 is the sizeof sfcfghdr except data field, 10 is the actual data
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_MACBYPASS_RX_START failed\n");
		return -1;
	}
	//read results from driver
	printf("show PER, RSSI!\n");
	g_clock_flag = 1;
	while(g_clock_flag){
		sleep(3);
		memset(&wrq, 0, sizeof(struct iwreq));
		memset(&tmp, 0, sizeof(struct sfcfghdr));

		tmp.magic_no = SFCFG_MAGIC_NO;
		tmp.comand_type = SFCFG_CMD_ATE_GET_INFO;
		tmp.comand_id   = SFCFG_CMD_ATE_GET_INFO;
		tmp.length      = 10;
		tmp.sequence    = 1;

		wrq.u.data.pointer = (caddr_t)&tmp;
		wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;
		if(do_ioctl(SFCFG_PRIV_IOCTL_ATE,&wrq) < 0){
			printf("SFCFG_CMD_ATE_GET_INFO ioctl failed\n");
			return -1;
		}
		memset(&user, 0, sizeof(struct rwnx_ioctl_ate_dump_info));
		memcpy(&user, wrq.u.data.pointer, sizeof(struct rwnx_ioctl_ate_dump_info));

		tmp_f = user.fcs_err - tmp1;
		tmp_p = user.phy_err - tmp2;
		tmp_r = user.rec_rx_count - tmp3;
		if(tmp_r)
			per = ((tmp_f+tmp_p)*100/tmp_r);
		else
			per = 100;
		tmp1 = user.fcs_err;
		tmp2 = user.phy_err;
		tmp3 = user.rec_rx_count;
		printf("receive data = %d,fcs error = %d,phy error = %d,per(every 3 seconds) = %d, per(from the beginning) = %d\n",
				user.rec_rx_count, user.fcs_err, user.phy_err, per, user.per);
	}
	return 0;
}


int32_t send_tx_stop()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no    = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_TX_STOP;
	tmp.comand_id   = SFCFG_CMD_ATE_TX_STOP;
	tmp.length      = 10;
	tmp.sequence    = 1;
	strncpy(tmp.data, "false", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = tmp.length + 16;//12 is the sizeof sfcfghdr except data field, 10 is the actual data

	//call SFCFG_CMD_ATE_TX_STOP
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_TX_STOP failed\n");
		return -1;
	}
	return 0;
}

int32_t send_tx_stop_by_macbypass()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no    = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_MACBYPASS_TX_STOP;
	tmp.comand_id   = SFCFG_CMD_ATE_MACBYPASS_TX_STOP;
	tmp.length      = 10;
	tmp.sequence    = 1;
	strncpy(tmp.data, "false", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = tmp.length + 16;//12 is the sizeof sfcfghdr except data field, 10 is the actual data

	//call SFCFG_CMD_ATE_TX_STOP
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_MACBYPASS_TX_STOP failed\n");
		return -1;
	}
	return 0;
}

int32_t send_rx_stop()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;

	g_clock_flag = false;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no    = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_RX_STOP;
	tmp.comand_id   = SFCFG_CMD_ATE_RX_STOP;
	tmp.length      = 10;
	tmp.sequence    = 1;
	strncpy(tmp.data, "false", 10);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = tmp.length + 16;//12 is the sizeof sfcfghdr except data field, 10 is the actual data

	//call SFCFG_CMD_ATE_RX_STOP
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_RX_FRAME_START failed\n");
		return -1;
	}
	return 0;
}

int32_t send_rx_stop_by_macbypass()
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	g_clock_flag = false;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));

	tmp.magic_no    = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_MACBYPASS_RX_STOP;
	tmp.comand_id   = SFCFG_CMD_ATE_MACBYPASS_RX_STOP;
	tmp.length      = 20;
	tmp.sequence    = 1;
	strncpy(tmp.data, "rx stop macbypass", tmp.length);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = tmp.length + 16;//12 is the sizeof sfcfghdr except data field, 10 is the actual data

	//call SFCFG_CMD_ATE_TX_STOP
	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_MACBYPASS_RX_STOP failed\n");
		return -1;
	}
	return 0;
}

int32_t save_XO_config_to_flash(char *tmpdata)
{
	struct iwreq wrq;
	struct sfcfghdr tmp;
	memset(&wrq, 0, sizeof(struct iwreq));
	memset(&tmp, 0, sizeof(struct sfcfghdr));
	// cmd ate band
	tmp.magic_no = SFCFG_MAGIC_NO;
	tmp.comand_type = SFCFG_CMD_ATE_SAVE_TO_FLASH;
	tmp.comand_id   = SFCFG_CMD_ATE_SAVE_TO_FLASH;
	tmp.length      = 20;
	tmp.sequence    = 1;

	memcpy(tmp.data,tmpdata, tmp.length);
	printf("tmp.data= %s---------\n", tmp.data);

	wrq.u.data.pointer = (caddr_t)&tmp;
	wrq.u.data.length = sizeof(struct sfcfghdr) - sizeof(((struct sfcfghdr *)0)->data) + tmp.length;

	if(do_ioctl(SFCFG_PRIV_IOCTL_ATE, &wrq) < 0){
		printf("SFCFG_PRIV_IOCTL_ATE ioctl SFCFG_CMD_ATE_SAVE_TO_FLASH failed\n");
		return -1;
	}
	return 0;
}

static void usage()
{
	printf("Usage:\n"
			"  ate_cmd wlan0/1 set/read/write "
			"ATEXXX = XXX \\\n"
			"\n"
		  );
	printf(" ate_cmd wlan0 set ATE = ATESTART, ATE start\n");
	printf(" ate_cmd wlan0 set ATE = ATETXSTART, Tx frame start (-t)\n");
	printf(" ate_cmd wlan0 set ATE = ATETXSTOP, Stop current TX action (-s)\n");
	printf(" ate_cmd wlan0 set ATE = ATERXSTART, RX frame start (-r)\n");
	printf(" ate_cmd wlan0 set ATE = ATERXSTOP, Stop current RX action (-k)\n");
	printf(" ate_cmd wlan0 set ATE = ATESHOW, Show Setting info\n");
	printf(" ate_cmd wlan0 set ATEPHYBW = X,(0~3) Set ATE PHY Bandwidth (-w)\n");
	printf(" ate_cmd wlan0 set ATETXBW = X,(0~3) Set ATE Tx Frame Bandwidth (-u)\n");
	printf(" ate_cmd wlan0 set ATECHAN = X, Set ATE Channel(primmary freq), decimal(-f)\n");
	printf(" ate_cmd wlan0 set ATECENTERFREQ1 = X, Set ATE center freq1, decimal(-c)\n");
	printf(" ate_cmd wlan0 set ATETXNUM = X, Set ATE Tx Frame Number(-n)\n");
	printf(" ate_cmd wlan0 set ATELEN = X, Set ATE Frame Length(-l)\n");
	printf(" ate_cmd wlan0 set ATETXMODE = X,(0~4) Set ATE Tx Mode(-m)\n");
	printf(" ate_cmd wlan0 set ATETXMCS = X, Set ATE Tx MCS type(-i)\n");
	printf(" ate_cmd wlan0 set ATETXGI = X,(0~1) Set ATE Tx Guard Interval(-g)\n");
	printf(" ate_cmd wlan0 set ATETXPOW = XX,(0~31) Set ATE Tx power(-p)\n");
	printf(" ate_cmd wlan0 set ATETXPREAM = X,(0~1) Set ATE Tx pream\n");
	printf(" ate_cmd wlan0 set ATETXDA = XX:XX:XX:XX:XX:XX, Set da\n");
	printf(" ate_cmd wlan0 set ATETXSA = XX:XX:XX:XX:XX:XX, Set sa\n");
	printf(" ate_cmd wlan0 set ATETXBSSID = XX:XX:XX:XX:XX:XX, Set bssid\n");
	printf(" ate_cmd wlan0 read ATEREG = X, Read the Value of One Register, X must be 0xYYYYYYYY or 0xYYYY\n");
	printf(" ate_cmd wlan0 write ATEREG = X(addr)_X(val), Write the Value of One Rergister\n");
	//printf(" ate_cmd wlan0 read ATEBULKREG = type_num_X1_X1_..., Read Many Registers\n");
	//printf(" ate_cmd wlan0 write ATEBULKREG = type_num_addr1_val1_X2_X2..., Write Many Registers\n");
	printf(" ate_cmd wlan0 set ATE = ATEMACHDR -f 0x0008 -t 0x0000 -b 00:aa:bb:cc:dd:ee -d 16:88:aa:bb:cc:dd -s 16:88:aa:bb:cc:dd -q 0x5e20, Set the frame mac header\n");
	printf(" ate_cmd wlan1 fastconfig -n 10 -l 1024 -f 5500 -c 5530 -w 3 -u 3 -m 4 -i 9 -g 0 -p 28 -t, Transmit frames by fast setting on HB\n");
	printf(" ate_cmd wlan1 fastconfig -l 4000 -f 5500 -c 5500 -w 3 -u 3 -m 4 -i 9 -g 0 -p 28 -b 4096 -y, Transmit frames by macbypass on HB\n");
	printf(" ate_cmd wlan1 fastconfig -q, stop tx by macbypass on HB!!\n");
	printf(" ate_cmd wlan1 fastconfig -f 5180 -c 5180 -w 0 -u 0 -h,Receive frames by macbypass on HB\n");
	printf(" ate_cmd wlan1 fastconfig -j, stop rx by macbypass on HB!!\n");
	printf(" ate_cmd wlan1 fastconfig -f 5500 -c 5500 -w 3 -u 3 -p 28 -o, Transmit test tone on HB\n");
	printf(" ate_cmd wlan1 fastconfig -x, Stop test tone on HB\n");
	printf(" ate_cmd wlan1 fastconfig -n 100 -l 1024 -f 5500 -c 5500 -w 1 -u 1 -m 2 -i 7 -g 1 -p 28 -a 16, Transmit aggregated frames by fast setting on HB, 16 is the max agg buffer size\n");
	printf(" ate_cmd wlan1 save 0x1a1b, Save XO cali caonfig  0x1a1b into falsh\n");
	printf(" if you use (ate_init lb/hb) to active ate tool, only use wlan0\n");
	printf(" if you use (ate_init) to active ate tool, use wlan0 for 2.4G test and wlan1 for 5G test\n");
}

int32_t main(int32_t argc, char *argv[])
{
    int i = 0;
	uint8_t j = 1;
	char *bufs;
    printf(" enter into ate cmd main-------------\n");
    for(i = 0; i< argc; i++){
        printf("input argv[%d] : %s\n", i, argv[i]);
    }

    if(argc < 2){
        usage();
        return -1;
    }

	send_ate_start();

	if(strcmp(argv[1],"save") == 0){
		char value[] = "0";
		strcpy(value, argv[2]);
		if(save_XO_config_to_flash(value))
			return -3;
		goto DONE;
	}
	if(strcmp(argv[1],"fastconfig") != 0)
	{
		strcpy(ifname, argv[1]);
		j=2;
	}
	if(strcmp(argv[j],"fastconfig") == 0)
	{
		int opt;
		char options[] = "trskyqoxhja:n:l:f:c:w:u:m:i:g:p:v:z:e:db:";

#if 0
		set_pkg_da(da);
		set_pkg_sa(sa);
		set_pkg_bssid(bssid);
#endif
		// parse parameters
		//./ate_cmd fastconfig -t -n 10 -l 1024 -f 5520 -w 0 -m 0 -i 0 -g 0
		while ((opt = getopt (argc, argv, options)) != -1)
		{
			switch (opt)
			{
				case 't':
					g_tx_frame_flag = true;
					printf("%s -t param g_tx_frame_flag=%d\n", __func__, g_tx_frame_flag);
					break;
				case 'r':
					g_rx_frame_flag = true;
					printf("%s -r param g_rx_frame_flag=%d\n", __func__, g_rx_frame_flag);
					break;
				case 's':
					g_stop_tx_frame_flag = true;
					printf("%s -s param g_stop_tx_frame_flag=%d\n", __func__, g_stop_tx_frame_flag);
					break;
				case 'k':
					g_stop_rx_frame_flag = true;
					printf("%s -k param g_stop_rx_frame_flag=%d\n", __func__, g_stop_rx_frame_flag);
					break;
				case 'y':
					g_start_tx_frame_by_macbypass_flag = true;
					printf("%s -y param g_start_tx_frame_by_macbypass_flag=%d\n", __func__, g_start_tx_frame_by_macbypass_flag);
					break;
				case 'q':
					g_stop_tx_frame_by_macbypass_flag = true;
					printf("%s -y param g_stop_tx_frame_by_macbypass_flag=%d\n", __func__, g_stop_tx_frame_by_macbypass_flag);
					break;
				case 'o':
					g_tx_test_tone_flag = true;
					printf("%s -o param g_tx_test_tone_flag=%d\n", __func__, g_tx_test_tone_flag);
					break;
				case 'x':
					g_stop_tx_test_tone_flag = true;
					printf("%s -x param g_stop_tx_test_tone_flag=%d\n", __func__, g_stop_tx_test_tone_flag);
					break;
				case 'h':
					g_start_rx_by_macbypass_flag = true;
					printf("%s -h param g_start_rx_by_macbypass_flag=%d\n", __func__, g_start_rx_by_macbypass_flag);
					break;
				case 'j':
					g_stop_rx_by_macbypass_flag = true;
					printf("%s -j param g_stop_rx_by_macbypass_flag=%d\n", __func__, g_stop_rx_by_macbypass_flag);
					break;
				case 'a':
					g_agg_tx_frame_flag = true;
					bufs = optarg;
					printf("%s -a param g_agg_tx_frame_flag=%d\n", __func__, g_agg_tx_frame_flag);
					break;
				case 'n':
					if(set_pkg_frame_num(optarg))
						return -1;
					break;
				case 'b':
					if(set_pkg_macbypass_interval(optarg))
						return -1;
					break;
				case 'l':
					if(set_pkg_frame_length(optarg))
						return -1;
					break;
				case 'f':
					if(set_phy_chan_freq(optarg))
						return -1;
					break;
				case 'c':
					if(set_phy_center_freq1(optarg))
						return -1;
					break;
				case 'w':
					if(set_phy_bandwidth(optarg))
						return -1;
					break;
				case 'u':
					if(set_pkg_bandwidth(optarg))
						return -1;
					break;
				case 'm':
					if(set_phy_mode(optarg))
						return -1;
					break;
				case 'i':
					if(set_phy_rate_idx(optarg))
						return -1;
					break;
				case 'g':
					if(set_phy_use_sgi(optarg))
						return -1;
					break;
				case 'p':
					if(set_phy_power(optarg))
						return -1;
					break;
				case 'v':
					if(read_iw_reg(optarg))
						return -1;
					break;
				case 'z':
					if(write_iw_reg(optarg))
						return -1;
					break;
				case 'e':
					if(read_iw_bulk_reg(optarg))
						return -1;
					break;
				case 'd':
					if(write_iw_bulk_reg(optarg))
						return -1;
					break;
				case '?':
				case ':':
					usage();
					break;
			}
		}

		if (g_tx_frame_flag) {
			if(send_tx_start(NULL))
				return -1;
			goto DONE;
		}

		if (g_rx_frame_flag) {
			if(send_rx_start())
				return -1;
			goto DONE;
		}

		if (g_stop_tx_frame_flag) {
			if(send_tx_stop())
				return -1;
			goto DONE;
		}

		if (g_stop_rx_frame_flag) {
			if(send_rx_stop())
				return -1;
			goto DONE;
		}

		if (g_start_tx_frame_by_macbypass_flag) {
			if(send_tx_start_by_macbypass())
				return -1;
			goto DONE;
		}

		if (g_stop_tx_frame_by_macbypass_flag) {
			if(send_tx_stop_by_macbypass())
				return -1;
			goto DONE;
		}

		if (g_start_rx_by_macbypass_flag) {
			if(send_rx_start_by_macbypass())
				return -1;
			goto DONE;
		}

		if (g_stop_rx_by_macbypass_flag) {
			if(send_rx_stop_by_macbypass())
				return -1;
			goto DONE;
		}

		if (g_tx_test_tone_flag) {
			if(send_tx_test_tone_start())
				return -1;
			g_tx_test_tone_flag = false;
			goto DONE;
		}

		if (g_stop_tx_test_tone_flag) {
			if(send_tx_test_tone_stop())
				return -1;
			g_stop_tx_test_tone_flag = false;
			goto DONE;
		}

		if (g_agg_tx_frame_flag) {
			if(send_tx_start(bufs))
				return -1;
			g_agg_tx_frame_flag = false;
			goto DONE;
		}
		goto DONE;
	}

	// ./ate_cmd wlan0 set XXX = XXX
	if(argc > 5 && strcmp(argv[0],"ate_cmd") == 0 && strcmp(argv[4],"=") == 0)
	{
		char *tmpdata;
	    int length_array = sizeof(beacon);
		// ./ate_cmd wlanx set XXX = XXX
		tmpdata=(char *)malloc(200);

		tmpdata = argv[5];

		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATESTART") == 0){
			if(send_ate_start())
				return -1;
		}
		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATESTOP") == 0){
			if(send_ate_stop())
				return -1;
		}
		//command id SFCFG_CMD_ATE_START 0x0000

		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATETXSTART") == 0){
			if(send_tx_start(NULL))
				return -1;
		}
		//command id SFCFG_CMD_ATE_TX_START 0x0002

		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATETXSTOP") == 0){
			if(send_tx_stop())
				return -1;
		}
		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATERXSTART") == 0){
			if(send_rx_start())
				return -1;
		}
		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATERXSTOP") == 0){
			if(send_rx_stop())
				return -1;
		}

		if(strcmp(argv[3],"ATE") == 0 && strcmp(argv[5],"ATESHOW") == 0){
			if(get_ate_info())
				return -1;
		}
		//config the frame mac head content
		//./ate_cmd wlan0 set ATE = ATEMACHDR -f 0x0080 -t 0x0000 -b 16:88:aa:bb:cc:dd -d 16:88:aa:bb:cc:dd -s 16:88:aa:bb:cc:dd -q 0x5e20
		if( strcmp(argv[5],"ATEMACHDR") == 0)
		{
			int opt;
			char options[] ="f:t:b:d:s:q:";
			while ((opt = getopt (argc, argv, options)) != -1)
			{
				switch (opt)
				{
					case 'f':
						set_pkg_fc(optarg);
						break;
					case 't':
						set_pkg_dur(optarg);
						break;
					case 'b':
						set_pkg_bssid(optarg);
						break;
					case 'd':
						set_pkg_da(optarg);
						break;
					case 's':
						set_pkg_sa(optarg);
						break;
					case 'q':
						set_pkg_seqc(optarg);
						break;
					case ':':
						usage();
						break;
				}
			}
		}

		//./ate_cmd wlan0 set ATETXFC = 0x0080
		if(strcmp(argv[3],"ATETXFC") == 0){
			if(set_pkg_fc(tmpdata))
				return -1;
		}
		//./ate_cmd wlan0 set ATETXDUR = 0x0000
		if(strcmp(argv[3],"ATETXDUR") == 0){
			if(set_pkg_dur(tmpdata))
				return -1;
		}
		//./ate_cmd wlan0 set ATETXDA = 00:16:88:08:07:f9
		if(strcmp(argv[3],"ATETXDA") == 0){
			if(set_pkg_da(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXSA") == 0){
			if(set_pkg_sa(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXBSSID") == 0){
			if(set_pkg_bssid(tmpdata))
				return -1;
		}
		//./ate_cmd wlan0 set ATETXSEQC = 0x5e20
		if(strcmp(argv[3],"ATETXSEQC") == 0){
			if(set_pkg_seqc(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATEPHYBW") == 0){
			if(set_phy_bandwidth(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXBW") == 0){
			if(set_pkg_bandwidth(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXNUM") == 0){
			if(set_pkg_frame_num(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATECHAN") == 0){
			if(set_phy_chan_freq(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATECENTERFREQ1") == 0){
			if(set_phy_center_freq1(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXMODE") == 0){
			if(set_phy_mode(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXMCS") == 0){
			if(set_phy_rate_idx(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXGI") == 0){
			if(set_phy_use_sgi(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXPREAM") == 0){
			if(set_phy_preamble(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATETXPOW") == 0){
			if(set_phy_power(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATELEN") == 0){
			if(set_pkg_frame_length(tmpdata))
				return -1;
		}
		// ./ate_cmd wlan0 set ATE = ATEWHOLEFRAME
		if(strcmp(argv[5],"ATEWHOLEFRAME") == 0){
			if(set_pkg_whole_frame(beacon,length_array))
				return -1;
		}
		if(strcmp(argv[3],"ATEPAYLOAD") == 0){
			if(set_pkg_payload(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATEREG") == 0 && strcmp(argv[2],"read") ==0){
			if(read_iw_reg(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATEREG") == 0 && strcmp(argv[2],"write") == 0){
			if(write_iw_reg(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATEBULKREG") == 0 && strcmp(argv[2],"read") ==0){
			if(read_iw_bulk_reg(tmpdata))
				return -1;
		}
		if(strcmp(argv[3],"ATEBULKREG") == 0 && strcmp(argv[2],"write") == 0){
			if(write_iw_bulk_reg(tmpdata))
				return -1;
		}
	}else{
		usage();
    }

DONE:
	close_ioctl_socket();
	return 0;
}
