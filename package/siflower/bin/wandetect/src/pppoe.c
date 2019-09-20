/***author: tianfy , yz_android@163.com**/

#include "discovery.h"

UINT16_t Eth_PPPOE_Discovery = ETHER_TYPE_DISCOVERY;

void rp_fatal(char const *str)
{
	LOG("%s\n", str);
	exit(1);
}

void fatalSys(char const *str)
{
	db_printf(str);
	exit(1);
}

void sysErr(char const *str)
{
	rp_fatal(str);
}

/**********************************************************************
*%FUNCTION: parsePacket
*%ARGUMENTS:
* packet -- the PPPoE discovery packet to parse
* func -- function called for each tag in the packet
* extra -- an opaque data pointer supplied to parsing function
*%RETURNS:
* 0 if everything went well; -1 if there was an error
*%DESCRIPTION:
* Parses a PPPoE discovery packet, calling "func" for each tag in the packet.
* "func" is passed the additional argument "extra".
***********************************************************************/
int parsePacket(PPPoEPacket *packet, ParseFunc *func, void *extra)
{
    UINT16_t len = ntohs(packet->length);
    unsigned char *curTag;
    UINT16_t tagType, tagLen;

    if (PPPOE_VER(packet->vertype) != 1) {
	LOG("Invalid PPPoE version (%d)\n",
		PPPOE_VER(packet->vertype));
	return -1;
    }
    if (PPPOE_TYPE(packet->vertype) != 1) {
	LOG("Invalid PPPoE type (%d)\n",
		PPPOE_TYPE(packet->vertype));
	return -1;
    }

    /* Do some sanity checks on packet */
    if (len > ETH_DATA_LEN - 6) { /* 6-byte overhead for PPPoE header */
	LOG("Invalid PPPoE packet length (%u)\n", len);
	return -1;
    }

    /* Step through the tags */
    curTag = packet->payload;
    while(curTag - packet->payload < len) {
	/* Alignment is not guaranteed, so do this by hand... */
	tagType = (curTag[0] << 8) + curTag[1];
	tagLen = (curTag[2] << 8) + curTag[3];
	if (tagType == TAG_END_OF_LIST) {
	    return 0;
	}
	if ((curTag - packet->payload) + tagLen + TAG_HDR_SIZE > len) {
	    LOG("Invalid PPPoE tag length (%u)\n", tagLen);
	    return -1;
	}
	func(tagType, tagLen, curTag+TAG_HDR_SIZE, extra);
	curTag = curTag + TAG_HDR_SIZE + tagLen;
    }
    return 0;
}

/**********************************************************************
*%FUNCTION: parseForHostUniq
*%ARGUMENTS:
* type -- tag type
* len -- tag length
* data -- tag data.
* extra -- user-supplied pointer.  This is assumed to be a pointer to int.
*%RETURNS:
* Nothing
*%DESCRIPTION:
* If a HostUnique tag is found which matches our PID, sets *extra to 1.
***********************************************************************/
void
parseForHostUniq(UINT16_t type, UINT16_t len, unsigned char *data,
		 void *extra)
{
    int *val = (int *) extra;
    if (type == TAG_HOST_UNIQ && len == sizeof(pid_t)) {
	pid_t tmp;
	memcpy(&tmp, data, len);
	if (tmp == getpid()) {
	    *val = 1;
	}
    }
}

/**********************************************************************
*%FUNCTION: packetIsForMe
*%ARGUMENTS:
* conn -- PPPoE connection info
* packet -- a received PPPoE packet
*%RETURNS:
* 1 if packet is for this PPPoE daemon; 0 otherwise.
*%DESCRIPTION:
* If we are using the Host-Unique tag, verifies that packet contains
* our unique identifier.
***********************************************************************/
int
packetIsForMe(PPPoEConnection *conn, PPPoEPacket *packet)
{
    int forMe = 0;

    /* If packet is not directed to our MAC address, forget it */
    if (memcmp(packet->ethHdr.h_dest, conn->myEth, ETH_ALEN)) return 0;

    /* If we're not using the Host-Unique tag, then accept the packet */
    if (!conn->useHostUniq) return 1;

    parsePacket(packet, parseForHostUniq, &forMe);
    return forMe;
}

/**********************************************************************
*%FUNCTION: parsePADOTags
*%ARGUMENTS:
* type -- tag type
* len -- tag length
* data -- tag data
* extra -- extra user data.  Should point to a PacketCriteria structure
*          which gets filled in according to selected AC name and service
*          name.
*%RETURNS:
* Nothing
*%DESCRIPTION:
* Picks interesting tags out of a PADO packet
***********************************************************************/
void
parsePADOTags(UINT16_t type, UINT16_t len, unsigned char *data,
	      void *extra)
{
    struct PacketCriteria *pc = (struct PacketCriteria *) extra;
    PPPoEConnection *conn = pc->conn;
    int i;

    switch(type) {
    case TAG_AC_NAME:
		pc->seenACName = 1;
		db_printf("Access-Concentrator: %.*s\n", (int) len, data);
		if (conn->acName && len == strlen(conn->acName) &&
			!strncmp((char *) data, conn->acName, len)) {
			pc->acNameOK = 1;
		}
		break;
    case TAG_SERVICE_NAME:
		pc->seenServiceName = 1;
		if (len > 0) {
			db_printf("       Service-Name: %.*s\n", (int) len, data);
		}
		if (conn->serviceName && len == strlen(conn->serviceName) &&
			!strncmp((char *) data, conn->serviceName, len)) {
			pc->serviceNameOK = 1;
		}
		break;
    case TAG_AC_COOKIE:
		db_printf("Got a cookie:");
		/* Print first 20 bytes of cookie */
		for (i=0; i<len && i < 20; i++) {
			db_printf(" %02x", (unsigned) data[i]);
		}
		db_printf("\n");
		conn->cookie.type = htons(type);
		conn->cookie.length = htons(len);
		memcpy(conn->cookie.payload, data, len);
		break;
    case TAG_RELAY_SESSION_ID:
		db_printf("Got a Relay-ID:");
		/* Print first 20 bytes of relay ID */
		for (i=0; i<len && i < 20; i++) {
			db_printf(" %02x", (unsigned) data[i]);
		}
		if (i < len) db_printf("...");
		db_printf("\n");
		conn->relayId.type = htons(type);
		conn->relayId.length = htons(len);
		memcpy(conn->relayId.payload, data, len);
		break;
    case TAG_SERVICE_NAME_ERROR:
		LOG("Got a Service-Name-Error tag: %.*s\n", (int) len, data);
		break;
    case TAG_AC_SYSTEM_ERROR:
		LOG("Got a System-Error tag: %.*s\n", (int) len, data);
		break;
    case TAG_GENERIC_ERROR:
		LOG("Got a Generic-Error tag: %.*s\n", (int) len, data);
		break;
    }
}

/***********************************************************************
*%FUNCTION: sendPacket
*%ARGUMENTS:
* sock -- socket to send to
* pkt -- the packet to transmit
* size -- size of packet (in bytes)
*%RETURNS:
* 0 on success; -1 on failure
*%DESCRIPTION:
* Transmits a packet
***********************************************************************/
int
sendPacket(PPPoEConnection *conn, int sock, PPPoEPacket *pkt, int size)
{
#if defined(HAVE_STRUCT_SOCKADDR_LL)
    if (send(sock, pkt, size, 0) < 0) {
		sysErr("send (sendPacket)");
		return -1;
    }
#else
    struct sockaddr sa;

    if (!conn) {
		rp_fatal("relay and server not supported on Linux 2.0 kernels");
    }
    strcpy(sa.sa_data, conn->ifName);
    if (sendto(sock, pkt, size, 0, &sa, sizeof(sa)) < 0) {
		sysErr("sendto (sendPacket)");
		return -1;
    }
#endif
    return 0;
}

/***********************************************************************
*%FUNCTION: receivePacket
*%ARGUMENTS:
* sock -- socket to read from
* pkt -- place to store the received packet
* size -- set to size of packet in bytes
*%RETURNS:
* >= 0 if all OK; < 0 if error
*%DESCRIPTION:
* Receives a packet
***********************************************************************/
int
receivePacket(int sock, PPPoEPacket *pkt, int *size)
{
    if ((*size = recv(sock, pkt, sizeof(PPPoEPacket), 0)) < 0) {
		sysErr("recv (receivePacket)");
		return -1;
    }
    return 0;
}

/***********************************************************************
*%FUNCTION: sendPADI
*%ARGUMENTS:
* conn -- PPPoEConnection structure
*%RETURNS:
* Nothing
*%DESCRIPTION:
* Sends a PADI packet
***********************************************************************/
void
sendPADI(PPPoEConnection *conn)
{
    PPPoEPacket packet;
    unsigned char *cursor = packet.payload;
    PPPoETag *svc = (PPPoETag *) (&packet.payload);
    UINT16_t namelen = 0;
    UINT16_t plen;

    if (conn->serviceName) {
		namelen = (UINT16_t) strlen(conn->serviceName);
    }
    plen = TAG_HDR_SIZE + namelen;
    CHECK_ROOM(cursor, packet.payload, plen);

    /* Set destination to Ethernet broadcast address */
    memset(packet.ethHdr.h_dest, 0xFF, ETH_ALEN);
    memcpy(packet.ethHdr.h_source, conn->myEth, ETH_ALEN);

    packet.ethHdr.h_proto = htons(Eth_PPPOE_Discovery);
    packet.vertype = PPPOE_VER_TYPE(1, 1);
    packet.code = CODE_PADI;
    packet.session = 0;

    svc->type = TAG_SERVICE_NAME;
    svc->length = htons(namelen);
    CHECK_ROOM(cursor, packet.payload, namelen+TAG_HDR_SIZE);

    if (conn->serviceName) {
	memcpy(svc->payload, conn->serviceName, strlen(conn->serviceName));
    }
    cursor += namelen + TAG_HDR_SIZE;

    /* If we're using Host-Uniq, copy it over */
    if (conn->useHostUniq) {
		PPPoETag hostUniq;
		pid_t pid = getpid();
		hostUniq.type = htons(TAG_HOST_UNIQ);
		hostUniq.length = htons(sizeof(pid));
		memcpy(hostUniq.payload, &pid, sizeof(pid));
		CHECK_ROOM(cursor, packet.payload, sizeof(pid) + TAG_HDR_SIZE);
		memcpy(cursor, &hostUniq, sizeof(pid) + TAG_HDR_SIZE);
		cursor += sizeof(pid) + TAG_HDR_SIZE;
		plen += sizeof(pid) + TAG_HDR_SIZE;
    }

    packet.length = htons(plen);

    sendPacket(conn, conn->discoverySocket, &packet, (int) (plen + HDR_SIZE));
}

/**********************************************************************
*%FUNCTION: waitForPADO
*%ARGUMENTS:
* conn -- PPPoEConnection structure
* timeout -- how long to wait (in seconds)
*%RETURNS:
* Nothing
*%DESCRIPTION:
* Waits for a PADO packet and copies useful information
***********************************************************************/
void
waitForPADO(PPPoEConnection *conn, int timeout)
{
    fd_set readable;
    int r;
    struct timeval tv;
    PPPoEPacket packet;
    int len;

    struct PacketCriteria pc;
    pc.conn          = conn;
    pc.acNameOK      = (conn->acName)      ? 0 : 1;
    pc.serviceNameOK = (conn->serviceName) ? 0 : 1;
    pc.seenACName    = 0;
    pc.seenServiceName = 0;
    conn->error = 0;

    do {
	if (BPF_BUFFER_IS_EMPTY) {
	    tv.tv_sec = timeout;
	    tv.tv_usec = 0;

	    FD_ZERO(&readable);
	    FD_SET(conn->discoverySocket, &readable);

	    while(1) {
			r = select(conn->discoverySocket+1, &readable, NULL, NULL, &tv);
			if (r >= 0 || errno != EINTR) break;
		}
		if (r < 0) {
			LOG("select (waitForPADO)");
			return;
	    }
	    if (r == 0){
			LOG("get PADO time out\n");
			return;        /* Timed out */
		}
	}

	/* Get the packet */
	receivePacket(conn->discoverySocket, &packet, &len);

	/* Check length */
	if (ntohs(packet.length) + HDR_SIZE > len) {
	    LOG("Bogus PPPoE length field (%u)\n",
		   (unsigned int) ntohs(packet.length));
	    continue;
	}

	/* If it's not for us, loop again */
	if (!packetIsForMe(conn, &packet)) {
		LOG("packet is no for me\n");
		continue;
	}

	if (packet.code == CODE_PADO) {
	    if (BROADCAST(packet.ethHdr.h_source)) {
			LOG("Ignoring PADO packet from broadcast MAC address\n");
			continue;
	    }
	    parsePacket(&packet, parsePADOTags, &pc);
	    if (conn->error)
			return;
	    if (!pc.seenACName) {
			LOG("Ignoring PADO packet with no AC-Name tag\n");
			continue;
	    }
	    if (!pc.seenServiceName) {
			LOG("Ignoring PADO packet with no Service-Name tag\n");
			continue;
	    }
	    conn->numPADOs++;
	    db_printf("---------------------------recv PADO-----------------------\n");
	    if (pc.acNameOK && pc.serviceNameOK) {
			memcpy(conn->peerEth, packet.ethHdr.h_source, ETH_ALEN);
			if (conn->printACNames) {
				db_printf("AC-Ethernet-Address: %02x:%02x:%02x:%02x:%02x:%02x\n",
				   (unsigned) conn->peerEth[0],
				   (unsigned) conn->peerEth[1],
				   (unsigned) conn->peerEth[2],
				   (unsigned) conn->peerEth[3],
				   (unsigned) conn->peerEth[4],
				   (unsigned) conn->peerEth[5]);
			}
			conn->discoveryState = STATE_RECEIVED_PADO;
			break;
	    }
	}
    } while (conn->discoveryState != STATE_RECEIVED_PADO);
}


int get_ifindex(char *device_name) {
	int sock=socket(AF_PACKET,SOCK_RAW,htons(ETHER_TYPE_DISCOVERY));
	struct ifreq ifr;
	memset(&ifr,0,sizeof(ifr));
	strncpy (ifr.ifr_name,device_name, sizeof(ifr.ifr_name) - 1);
	ifr.ifr_name[sizeof(ifr.ifr_name)-1]='\0';
	if(ioctl(sock,SIOCGIFINDEX,&ifr) == -1) {
		db_printf("%s\n",strerror(errno));
		exit(1);
	}
	close(sock);
	return ifr.ifr_ifindex;
}

/**********************************************************************
*%FUNCTION: openInterface
*%ARGUMENTS:
* ifname -- name of interface
* type -- Ethernet frame type
* hwaddr -- if non-NULL, set to the hardware address
*%RETURNS:
* A raw socket for talking to the Ethernet card.  Exits on error.
*%DESCRIPTION:
* Opens a raw Ethernet socket
***********************************************************************/
int
openInterface(char const *ifname, UINT16_t type, unsigned char *hwaddr)
{
    int optval=1;
    int fd;
    struct ifreq ifr;
    int domain, stype;

#ifdef HAVE_STRUCT_SOCKADDR_LL
    struct sockaddr_ll sa;
#else
    struct sockaddr sa;
#endif

    memset(&sa, 0, sizeof(sa));

#ifdef HAVE_STRUCT_SOCKADDR_LL
    domain = PF_PACKET;
    stype = SOCK_RAW;
#else
    domain = PF_INET;
    stype = SOCK_PACKET;
#endif

    if ((fd = socket(domain, stype, htons(type))) < 0) {
		/* Give a more helpful message for the common error case */
		if (errno == EPERM) {
			rp_fatal("Cannot create raw socket -- pppoe must be run as root.");
		}
		fatalSys("socket");
    }

    if (setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &optval, sizeof(optval)) < 0) {
		fatalSys("setsockopt");
    }

    /* Fill in hardware address */
    if (hwaddr) {
		strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
		if (ioctl(fd, SIOCGIFHWADDR, &ifr) < 0) {
			fatalSys("ioctl(SIOCGIFHWADDR)");
		}
		memcpy(hwaddr, ifr.ifr_hwaddr.sa_data, ETH_ALEN);
#ifdef ARPHRD_ETHER
		if (ifr.ifr_hwaddr.sa_family != ARPHRD_ETHER) {
			char buffer[256];
			sprintf(buffer, "Interface %.16s is not Ethernet", ifname);
			rp_fatal(buffer);
		}
#endif
		if (NOT_UNICAST(hwaddr)) {
			char buffer[256];
			sprintf(buffer,
				"Interface %.16s has broadcast/multicast MAC address??",
				ifname);
			rp_fatal(buffer);
		}
    }

    /* Sanity check on MTU */
    strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    if (ioctl(fd, SIOCGIFMTU, &ifr) < 0) {
		fatalSys("ioctl(SIOCGIFMTU)");
    }
    if (ifr.ifr_mtu < ETH_DATA_LEN) {
		db_printf("Interface %.16s has MTU of %d -- should be %d.\n",
	      ifname, ifr.ifr_mtu, ETH_DATA_LEN);
		LOG("You may have serious connection problems.\n");
    }

#ifdef HAVE_STRUCT_SOCKADDR_LL
    /* Get interface index */
    sa.sll_family = AF_PACKET;
    sa.sll_protocol = htons(type);

    strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    if (ioctl(fd, SIOCGIFINDEX, &ifr) < 0) {
		fatalSys("ioctl(SIOCFIGINDEX): Could not get interface index");
    }
    sa.sll_ifindex = ifr.ifr_ifindex;

#else
    strcpy(sa.sa_data, ifname);
#endif

    /* We're only interested in packets on specified interface */
    if (bind(fd, (struct sockaddr *) &sa, sizeof(sa)) < 0) {
	fatalSys("bind");
    }

    return fd;
}

int detect_pppoe(void){
	PPPoEConnection *conn;

    conn = malloc(sizeof(PPPoEConnection));
	conn->ifName = strdup(dt_iface);
	conn->discoverySocket = -1;
	conn->sessionSocket = -1;
	conn->printACNames = 1;

	int padiAttempts = 0;
	int timeout = PADI_TIMEOUT;

	int ret = 0;

	conn->discoverySocket = openInterface(conn->ifName, Eth_PPPOE_Discovery, conn->myEth);
	do {
		padiAttempts++;
		if (padiAttempts > MAX_PADI_ATTEMPTS) {
			LOG("Timeout waiting for PADO packets\n");
			close(conn->discoverySocket);
			conn->discoverySocket = -1;
			free(conn);
			return ret;
		}
		sendPADI(conn);
		conn->discoveryState = STATE_SENT_PADI;
		waitForPADO(conn, timeout);
	} while (!conn->numPADOs);
	LOG("##___conn->discoveryState = %d   \n",conn->discoveryState);
	ret = 1;
	free(conn);
	return ret;
}
