/*
 * =====================================================================================
 *
 *       Filename:  netdiscover.c
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  2015年09月02日 20时12分00秒
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  kevin.feng , kevin.feng@siflower.com.cn
 *        Company:  Siflower
 *
 * =====================================================================================
 */
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>
#include <malloc.h>

#include "netdiscover.h"

#include <syslog.h>


//#define DEBUG

int scan_timeout = 100;
int scan_count = 1;

pthread_mutex_t g_scan_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t g_scan_cond = PTHREAD_COND_INITIALIZER;


/* Forge Arp Packet, using libnet */
static void *scan_process(void *args)
{
    struct timespec to;
    devinfo *device = (devinfo *)args;
    char *dest_ip = NULL;
    char *iface = device->interface;    
    int i = 0;
    char lnet_error[100];
    struct libnet_ether_addr *src_mac = NULL;
    u_char sip[IP_ALEN];
    u_char dip[IP_ALEN];
    u_int32_t otherip, myip;

    libnet_ptag_t arp=0, eth=0;
    libnet_t *libnet = NULL;
    
    u_char dmac[ETH_ALEN] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
    u_int8_t smac[ETH_ALEN];


    pthread_mutex_lock(&g_scan_mutex);
    to.tv_sec = time(NULL)+3;
    pthread_cond_timedwait(&g_scan_cond, &g_scan_mutex, &to);
    pthread_mutex_unlock(&g_scan_mutex);
#ifdef DEBUG
    syslog(LOG_CRIT,"<-----------------currect time stamp, function is %s", __func__);
#endif    


    int k = 0;
    for(k = 0; k < scan_count; k++)
    {
        for(i = 0; i < device->ipnum; i++)
        {
            libnet = libnet_init(LIBNET_LINK, iface, lnet_error);
            if(!libnet)
            {      
                printf("init error lnet_error = %s", lnet_error);
                return NULL;        
            }

            src_mac = libnet_get_hwaddr(libnet);

            memcpy(smac, src_mac->ether_addr_octet, ETH_ALEN);

            
                         
            myip = libnet_name2addr4(libnet, "192.168.4.67", LIBNET_RESOLVE);
            memcpy(sip, (char*)&myip, IP_ALEN);
            /* get src & dst ip address */

        
            dest_ip = device->iplist[i].ipaddr;
            otherip = libnet_name2addr4(libnet, dest_ip, LIBNET_RESOLVE);
            memcpy(dip, (char*)&otherip, IP_ALEN);
            eth = 0;


            /* forge arp data */
            libnet_build_arp(
              ARPHRD_ETHER,
              ETHERTYPE_IP,
              ETH_ALEN, IP_ALEN,
              ARPOP_REQUEST,
              smac, sip,
              dmac, dip,
              NULL, 0,
              libnet,
              arp);
         
            /* forge ethernet header */
            eth = libnet_build_ethernet(
              dmac, smac,
              ETHERTYPE_ARP,
            NULL, 0,
            libnet,
            eth);
       

            /* Inject the packet */
            libnet_write(libnet);
            libnet_destroy(libnet);
        }
    }
   
}


void *loopbreak_process(void *args)
{
    int timeout = SNIFF_TIMEOUT;
    usleep(timeout);
    pcap_breakloop((pcap_t *)args);
    pcap_close((pcap_t *)args);
}



static void arp_sniff(devinfo *device)    
{
    char *interface = NULL;
    interface = device->interface;
    pcap_t *descr;
    struct bpf_program fp;  
    char errbuf[100];
    
#ifdef DEBUG
    syslog(LOG_CRIT,"<-----------------currect time stamp1, function is %s", __func__);
#endif    
    /* Open interface */
    descr = pcap_open_live(interface, BUFSIZ, 1, scan_timeout, errbuf);
    if(descr == NULL)
    {   
        printf("pcap_open_live(): %s\n", errbuf);
        exit(1);
    }   

    /* Set pcap filter for arp only */
    pcap_compile(descr, &fp, "arp", 0, 0); 
    pcap_setfilter(descr, &fp);
#ifdef DEBUG
    syslog(LOG_CRIT,"<-----------------currect time stamp2, function is %s", __func__);
#endif    
    
    usleep(100);
    pthread_mutex_lock(&g_scan_mutex);
    pthread_cond_signal(&g_scan_cond);
    pthread_mutex_unlock(&g_scan_mutex);


    /* Start loop for packet capture */
    pcap_dispatch(descr, -1, (pcap_handler)proccess_packet, (u_char *)device);
    pcap_close(descr);

}

void *sniff_process(void *args)
{
    devinfo *device = (devinfo *)args;
    arp_sniff(device);
}


/* Handle packets recived from pcap_loop */
static void proccess_packet(u_char *args, struct pcap_pkthdr *pkthdr,const u_char *packet)
{
    int i = 0;
    devinfo *device = (devinfo *)args;
    char sip[20];
    char smacaddr[20];
    sprintf(smacaddr, "%02x:%02x:%02x:%02x:%02x:%02x", packet[6],packet[7],packet[8],packet[9],packet[10],packet[11]);
#ifdef DEBUG    
    syslog(LOG_CRIT, "smacaddr === %s", smacaddr);
    syslog(LOG_CRIT, "device->macaddr === %s\n", device->macaddr);

    printf("packet length = %d\n", sizeof(packet));

    for(i=0;i<42;i++)
    {
        if(i%16 == 0)
        {
            printf("\n");
        }
        printf(" %02x",packet[i]);
    }

    printf("\n");
/*    printf("pkthdr length = %d\n", sizeof(pkthdr));

    for(i=0;i<42;i++)
    {
        if(i%16 == 0)
        {
            printf("\n");
        }
        printf("%02x",pkthdr[i]);
    }
    printf("\n");
*/
#endif        
    


    if(packet[21] == 2 && packet[20] == 0)
    {      
        sprintf(sip, "%d.%d.%d.%d", packet[28],packet[29],packet[30],packet[31]);        
#ifdef DEBUG    
        syslog(LOG_CRIT, "sip === %s", sip);
#endif                
        for(i = 0; i < device->ipnum; i++)
        {
#ifdef DEBUG    
            syslog(LOG_CRIT, "device->iplist[%d].ipaddr === %s function:%s", i, device->iplist[i].ipaddr, __func__);
#endif        
            if(strcmp(device->iplist[i].ipaddr, sip) == 0)
            {
               device->iplist[i].ipavailable = 1;
               printf(" %s %s\n", sip, smacaddr);
               break;
            }
        }
    }
}


void usage(char *progname)
{
    printf("ndscan(net device scan)\n");
    printf("Written by: Kevin.feng <kevin.feng@siflower.com.cn>\n");
    printf("Usage: %s <-i interface> <-d ipaddr> [-t timeout] [-c count]\n", progname);
    printf("   -i interface: your network interface\n");
    printf("   -d ipaddr: the ip address you want to scan\n");
    printf("   -t timeout: arp sniff time (unit: ms)  the default value is 100\n");
    printf("   -c count: arp scan times,  the default value is 1\n");
}

int main(int argc, char *argv[])
{

    devinfo *device = NULL;
    device = (devinfo *)calloc(1, sizeof(devinfo));
   
    char c = 0;

    char *ip_tmp = NULL; 
    int i = 0;

    while ((c = getopt(argc, argv, "m:d:i:c:t:h")) != EOF)
    {
        switch (c)
        {
            case 'i':
                sprintf(device->interface, "%s", optarg);
                break;
            case 'd':
                ip_tmp = strtok(optarg, ";");
                strcpy(device->iplist[i].ipaddr, ip_tmp);
                while(ip_tmp = strtok(NULL, ";"))
                {
                    strcpy(device->iplist[i].ipaddr, ip_tmp);
                    i++;
                }
                device->ipnum = i+1;

            case  'c':
                scan_count = atoi(optarg);
                break;
    
            case 't':
                scan_timeout = atoi(optarg);
                break;
    
            case 'h':
                usage(argv[0]);
                exit(1);
                break;

            default:
                break;
        }
    }


#ifdef DEBUG
    for(i=0;i<device->ipnum;i++)
    {
        syslog(LOG_CRIT, "\ndevice->ipnum = %d  device->iplist[%d].ipaddr = %s  ipavailable = %d dhcp = %d\n" , device->ipnum, i, device->iplist[i].ipaddr, device->iplist[i].ipavailable, device->iplist[i].dhcp);
    }
#endif
	char pcap_error[100];

    pthread_t scan_thread;
    pthread_create(&scan_thread, NULL, &scan_process, (void *)device);

    if(scan_thread <= 0){
        syslog(LOG_CRIT, "scan_thread create failed!\n");
        free(device);
        return;
    }

    pthread_t sniff_thread;
    pthread_create(&sniff_thread, NULL, &sniff_process, (void *)device);
    if(sniff_thread > 0)
    {
        syslog(LOG_CRIT, "create sniff_thread!\n");
    }
    else{
        syslog(LOG_CRIT, "sniff_thread create failed!\n");
        free(device);
        return;
    }

    pthread_join(scan_thread, NULL);
    pthread_join(sniff_thread, NULL);
#ifdef DEBUG
    for(i=0;i<device->ipnum;i++)
    {
        syslog(LOG_CRIT, "\ndevice->ipnum = %d  device->iplist[%d].ipaddr = %s  ipavailable = %d dhcp = %d\n" , device->ipnum, i, device->iplist[i].ipaddr, device->iplist[i].ipavailable, device->iplist[i].dhcp);
    }
#endif
    
    free(device);
}



