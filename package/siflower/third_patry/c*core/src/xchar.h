
#ifndef __XCHAR_H__
#define __XCHAR_H__ 1


#ifndef XCHAR_DEF
#include <stdio.h>
#include <string.h>
#define XCHAR_DEF
#if defined (_WIN32) && !defined (__MINGW32__)
#pragma warning(disable:4996)
#endif

#if defined(_WIN32) && defined(UNICODE)

typedef wchar_t		XCHAR;
#define xstrcpy		wcscpy
#define xstrlen		wcslen
#define xstrcmp		wcscmp
#define xstrcat		wcscat
#define xsprintf	_swprintf
#define xstrstr		wcsstr
#define xstrchr		wcschr
#define xstrrchr	wcsrchr
#define xstrtok		wcstok

#define xstrdup		_wcsdup
#define xstrup		_wcsupr
#define xstrcmpi	_wcsicmp
#define xIsDigit	iswxdigit	
#define xtoupper	towupper
#define xvsnprintf	_vsnwprintf

#define xfsopen		_wfsopen
#define xfopen		_wfopen
#define xfgets		fgetws
#define xstrnicmp	_wcsnicmp
#define xaccess		_waccess
#define xWinMain	wWinMain

#define __X(x)      L ## x

#else /* defined(WIN32) && defined(UNICODE) */

typedef char		XCHAR;
#define xstrcpy		strcpy
#define xstrlen		strlen
#define xstrcmp		strcmp
#define xstrcat		strcat
#define xsprintf	sprintf
#define xstrstr		strstr
#define xstrchr		strchr
#define xstrrchr	strrchr
#define xstrtok		strtok

#define xfgets		fgets
#define xfsopen		_fsopen
#define xfopen		fopen

#define xIsDigit	isxdigit
#define xtoupper	toupper
#define xvsnprintf	vsnprintf

#ifdef WIN32
#define xstrcmpi	_stricmp
#define xstrdup		_strdup
#define xstrup		_strupr
#define xstrnicmp	_strnicmp
#define xWinMain	WinMain
#define xaccess		_access
#else
#define xstrcmpi	strcasecmp
#define xstrdup		strdup
#define xstrup		strupr
#define xstrnicmp	strncasecmp
#endif

#define __X(x)      x

#endif /* defined(WIN32) && defined(UNICODE) */

#define _X(x)		__X(x)

#endif

#endif /* __XCHAR_H__ */
