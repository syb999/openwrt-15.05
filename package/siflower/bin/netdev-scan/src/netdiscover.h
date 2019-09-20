/*
 * =====================================================================================
 *
 *       Filename:  netdiscover.h
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  2015年09月04日 11时43分44秒
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  kevin.feng (), kevin.feng@siflower.com.cn
 *        Company:  Siflower
 *
 * =====================================================================================
 */

#ifndef  __NETDISCOVER_H__
#define __NETDISCOVER_H__


#include <libnet.h>
#include <pcap.h>

#define ETH_ALEN 6
#define IP_ALEN 4
#define SNIFF_TIMEOUT 6000000

typedef struct{
    char ipaddr[16];
    char ipavailable;
    char dhcp;
} ipdetail;

typedef struct{
    char macaddr[20];
    ipdetail iplist[12];
    char interface[12];
    char curipnum;
    int ipnum;
    char online[2];
    char hostname[50];
    int newdevice;
} devinfo;


static void arp_sniff(devinfo *device);
static void proccess_packet(u_char *args, struct pcap_pkthdr *pkthdr,const u_char *packet);
extern int netdiscover(devinfo *device);

#endif
