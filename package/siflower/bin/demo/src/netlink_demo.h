#ifndef _NETLINK_SF_H
#define _NETLINK_SF_H


#define	SF_GENL_NAME		"COMMON_NL"
#define	SF_GENL_VERSION		0x1



enum {
	SF_CMD_UNSPEC = 0,	/* Reserved */
	SF_CMD_GENERIC,
	__SF_CMD_MAX,
};
#define SF_CMD_MAX (__SF_CMD_MAX - 1)


enum {
	SF_CMD_ATTR_UNSPEC = 0,
	SF_CMD_ATTR_DPS,             /* use for detect port status change */
	SF_CMD_ATTR_ECHO,            /* use for echo message */
	SF_CMD_ATTR_KTHREAD_RUN,     /* use for create kthread */
	SF_CMD_ATTR_KTHREAD_STOP,    /* use for stop kthread */
	SF_CMD_ATTR_WIFI,            /* reserve for wifi */
	SF_CMD_ATTR_APP,             /* reserve for app */
	__SF_CMD_ATTR_MAX,
};
#define SF_CMD_ATTR_MAX (__SF_CMD_ATTR_MAX - 1)





#endif /* _NETLINK_SF_H */
