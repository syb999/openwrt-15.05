
#ifndef __BASE_TYPE_DEF_H__
#define __BASE_TYPE_DEF_H__ 1

#ifdef _WIN32

#ifdef WINCE
#define WINVER _WIN32_WCE
#else
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif
#endif

//#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#ifndef HDEV_DEF
typedef HANDLE	HDEV;
#endif

#else /* linux */

typedef int		HDEV;
typedef void*	HANDLE;
typedef char   *LPSTR;
typedef signed char BOOL;
typedef int DWORD;

#define _GNU_SOURCE
#define __USE_GNU

#endif

typedef unsigned char	u8;
typedef unsigned short	u16;
typedef unsigned long	u32;

#include "xchar.h"

#endif /* __BASE_TYPE_DEF_H__ */
