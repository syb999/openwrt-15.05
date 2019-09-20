#include <sys/ioctl.h>
#include <net/if.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <linux/sockios.h>
#include <string.h>
#include <linux/if_ether.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <syslog.h>

/*
#define DEBUG 1
*/
#ifdef DEBUG
#define db_printf(format,...) printf(format,##__VA_ARGS__)
#else
#define db_printf(format,...) do{}while(0)
#endif

#define LOG(X,...) syslog(LOG_CRIT,X,##__VA_ARGS__)
extern char dt_iface[];
typedef unsigned short UINT16_t;

#define BPF_BUFFER_IS_EMPTY 1

/* PPPoE codes */
#define CODE_PADI           0x09
#define CODE_PADO           0x07
#define CODE_PADR           0x19
#define CODE_PADS           0x65
#define CODE_PADT           0xA7

/* PPPoE Tags */
#define TAG_END_OF_LIST        0x0000
#define TAG_SERVICE_NAME       0x0101
#define TAG_AC_NAME            0x0102
#define TAG_HOST_UNIQ          0x0103
#define TAG_AC_COOKIE          0x0104
#define TAG_VENDOR_SPECIFIC    0x0105
#define TAG_RELAY_SESSION_ID   0x0110
#define TAG_SERVICE_NAME_ERROR 0x0201
#define TAG_AC_SYSTEM_ERROR    0x0202
#define TAG_GENERIC_ERROR      0x0203

/* Discovery phase states */
#define STATE_SENT_PADI     0
#define STATE_RECEIVED_PADO 1
#define STATE_SENT_PADR     2
#define STATE_SESSION       3
#define STATE_TERMINATED    4

#define PPPOE_OVERHEAD 6  /* type, code, session, length */
#define HDR_SIZE (sizeof(struct ethhdr) + PPPOE_OVERHEAD)
#define MAX_PPPOE_PAYLOAD (ETH_DATA_LEN - PPPOE_OVERHEAD)

/* How many PADI/PADS attempts? */
#define MAX_PADI_ATTEMPTS 3

/* Initial timeout for PADO/PADS */
#define PADI_TIMEOUT 2

#define HAVE_STRUCT_SOCKADDR_LL 1

#define MAC_LEN 6 //the length of a mac address
#define MTU 1500
#define ETHER_TYPE_DISCOVERY 0x8863
#define ETHER_TYPE_PPP_SESSION 0x8864
#define ETH_HEARER_LEN_WITHOUT_CRC 14
#define PPPOE_HEADER_LEN 6

#define Service_Name 0x0101
#define Host_Uniq 0x0103
#define TIME_OUT_DISCOVERY 5
#define TIME_OUT_SESSION 5


struct pppoe_packet {
	char eth_dst_mac[MAC_LEN];
	char eth_src_mac[MAC_LEN];
	unsigned short int eth_type;
	char pppoe_type:4;
	char pppoe_ver:4;
	char pppoe_code;
	unsigned short int pppoe_session_id;  //network order
	unsigned short int pppoe_length; //the length of pppoe payload
	char payload[MTU-PPPOE_HEADER_LEN];
};

/* PPPoE Tag */

typedef struct PPPoETagStruct {
    unsigned int type:16;	/* tag type */
    unsigned int length:16;	/* Length of payload */
    unsigned char payload[ETH_DATA_LEN]; /* A LOT of room to spare */
} PPPoETag;

/* Keep track of the state of a connection -- collect everything in
   one spot */
typedef struct PPPoEConnectionStruct {
    int discoveryState;		/* Where we are in discovery */
    int discoverySocket;	/* Raw socket for discovery frames */
    int sessionSocket;		/* Raw socket for session frames */
    unsigned char myEth[ETH_ALEN]; /* My MAC address */
    unsigned char peerEth[ETH_ALEN]; /* Peer's MAC address */
    unsigned char req_peer_mac[ETH_ALEN]; /* required peer MAC address */
    unsigned char req_peer;	/* require mac addr to match req_peer_mac */
    UINT16_t session;		/* Session ID */
    char *ifName;		/* Interface name */
    char *serviceName;		/* Desired service name, if any */
    char *acName;		/* Desired AC name, if any */
    int synchronous;		/* Use synchronous PPP */
    int useHostUniq;		/* Use Host-Uniq tag */
    int printACNames;		/* Just print AC names */
    FILE *debugFile;		/* Debug file for dumping packets */
    int numPADOs;		/* Number of PADO packets received */
    PPPoETag cookie;		/* We have to send this if we get it */
    PPPoETag relayId;		/* Ditto */
    int error;			/* Error packet received */
    int debug;			/* Set to log packets sent and received */
    int discoveryTimeout;       /* Timeout for discovery packets */
}PPPoEConnection;

/* A PPPoE Packet, including Ethernet headers */
typedef struct PPPoEPacketStruct {
    struct ethhdr ethHdr;	/* Ethernet header */
    unsigned int vertype:8;	/* PPPoE Version and Type (must both be 1) */
    unsigned int code:8;	/* PPPoE code */
    unsigned int session:16;	/* PPPoE session */
    unsigned int length:16;	/* Payload length */
    unsigned char payload[ETH_DATA_LEN]; /* A bit of room to spare */
} PPPoEPacket;

/* Header size of a PPPoE tag */
#define TAG_HDR_SIZE 4

#define CHECK_ROOM(cursor, start, len) \
do {\
    if (((cursor)-(start))+(len) > MAX_PPPOE_PAYLOAD) { \
	db_printf("Would create too-long packet");	\
        return; \
    } \
} while(0)

#define PPPOE_VER(vt)		((vt) >> 4)
#define PPPOE_TYPE(vt)		((vt) & 0xf)
#define PPPOE_VER_TYPE(v, t)	(((v) << 4) | (t))

/* Structure used to determine acceptable PADO or PADS packet */
struct PacketCriteria {
    PPPoEConnection *conn;
    int acNameOK;
    int serviceNameOK;
    int seenACName;
    int seenServiceName;
};

/* True if Ethernet address is broadcast or multicast */
#define NOT_UNICAST(e) ((e[0] & 0x01) != 0)
#define BROADCAST(e) ((e[0] & e[1] & e[2] & e[3] & e[4] & e[5]) == 0xFF)
#define NOT_BROADCAST(e) ((e[0] & e[1] & e[2] & e[3] & e[4] & e[5]) != 0xFF)

/* Function passed to parsePacket */
typedef void ParseFunc(UINT16_t type,
		       UINT16_t len,
		       unsigned char *data,
		       void *extra);

extern int detect_pppoe(void);
