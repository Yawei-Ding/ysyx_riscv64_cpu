/* -*- mode: c; tab-width: 4; c-basic-offset: 4; c-file-style: "linux" -*- */
//
// Copyright (c) 2009-2011, Wei Mingzhi <whistler_wmz@users.sf.net>.
// Copyright (c) 2011-2020, SDLPAL development team.
// All rights reserved.
//
// This file is part of SDLPAL.
//
// SDLPAL is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#ifndef _COMMON_H
#define _COMMON_H

#define ENABLE_REVISIED_BATTLE
#ifndef ENABLE_REVISIED_BATTLE
# define PAL_CLASSIC        1
#endif

// #define ENABLE_GBK

#include <wchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdarg.h>
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>

#include <SDL.h>
#include "myFLOAT.h"

#define __WIDETEXT(quote) L##quote
#define WIDETEXT(quote) __WIDETEXT(quote)

static inline int max(int a, int b) { return (a > b ? a : b); }
static inline int min(int a, int b) { return (a < b ? a : b); }

#define SDL_TICKS_PASSED(A, B)  ((Sint32)((B) - (A)) <= 0)

#define PAL_FORCE_INLINE __attribute__((always_inline)) static __inline__

# ifndef FALSE
#  define FALSE               0
# endif
# ifndef TRUE
#  define TRUE                1
# endif
# define VOID                void
typedef char                CHAR;
typedef wchar_t             WCHAR;
typedef short               SHORT;
typedef long                LONG;

typedef unsigned long       ULONG, *PULONG;
typedef unsigned short      USHORT, *PUSHORT;
typedef unsigned char       UCHAR, *PUCHAR;

typedef unsigned short      WORD, *LPWORD;
typedef unsigned int        DWORD, *LPDWORD;
typedef int                 INT, *LPINT;
typedef int                 BOOL, *LPBOOL;
typedef unsigned int        UINT, *PUINT, UINT32, *PUINT32;
typedef unsigned char       BYTE, *LPBYTE;
typedef const BYTE         *LPCBYTE;
typedef void               *LPVOID;
typedef const void         *LPCVOID;
typedef CHAR               *LPSTR;
typedef const CHAR         *LPCSTR;
typedef WCHAR              *LPWSTR;
typedef const WCHAR        *LPCWSTR;

# define PAL_MAX_PATH  PATH_MAX


#ifdef __cplusplus
# define PAL_C_LINKAGE       extern "C"
# define PAL_C_LINKAGE_BEGIN PAL_C_LINKAGE {
# define PAL_C_LINKAGE_END   }
#else
# define PAL_C_LINKAGE
# define PAL_C_LINKAGE_BEGIN
# define PAL_C_LINKAGE_END
#endif

#define SDL_strncasecmp strncasecmp
#define SDL_strcasecmp strcasecmp
#define SDL_setenv(a,b,c) 

#define PAL_SDL_INIT_FLAGS    (SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_NOPARACHUTE | SDL_INIT_JOYSTICK)
#define PAL_VIDEO_INIT_FLAGS  (SDL_HWSURFACE | SDL_RESIZABLE | (gConfig.fFullScreen ? SDL_FULLSCREEN : 0))

#ifdef __NAVY__
#define SDL_SwapLE32(x) (x)
#define SDL_SwapLE16(x) (x)
#define SDL_MUSTLOCK(screen) 0

#define PAL_FATAL_OUTPUT(s)   printf("FATAL ERROR: %s\n", (s))
#define PAL_PREFIX            "/share/games/pal/"
#else
#define PAL_FATAL_OUTPUT(s)   system(PAL_va(0, "beep; xmessage -center \"FATAL ERROR: %s\"", (s)))
#define PAL_PREFIX            "./data"
#endif

#define PAL_SAVE_PREFIX       PAL_PREFIX

#define PAL_DEFAULT_WINDOW_WIDTH   640
#define PAL_DEFAULT_WINDOW_HEIGHT  400
#define PAL_DEFAULT_FULLSCREEN_HEIGHT 480

#define PAL_PLATFORM         NULL
#define PAL_CREDIT           NULL
#define PAL_PORTYEAR         NULL

#ifndef PAL_DEFAULT_TEXTURE_WIDTH
# define PAL_DEFAULT_TEXTURE_WIDTH     PAL_DEFAULT_WINDOW_WIDTH
#endif

#ifndef PAL_DEFAULT_TEXTURE_HEIGHT
# define PAL_DEFAULT_TEXTURE_HEIGHT    PAL_DEFAULT_WINDOW_HEIGHT
#endif

/* Default for 1024 samples */
#define PAL_AUDIO_DEFAULT_BUFFER_SIZE   1024

#define PAL_CONFIG_PREFIX PAL_PREFIX

#ifndef PAL_LARGE
# define PAL_LARGE
#endif

#ifndef PAL_SCALE_SCREEN
# define PAL_SCALE_SCREEN   TRUE
#endif

#define PAL_fread(buf, elem, num, fp) if (fread((buf), (elem), (num), (fp)) < (num)) return -1

typedef enum tagLOGLEVEL
{
	LOGLEVEL_MIN,
	LOGLEVEL_VERBOSE = LOGLEVEL_MIN,
	LOGLEVEL_DEBUG,
	LOGLEVEL_INFO,
	LOGLEVEL_WARNING,
	LOGLEVEL_ERROR,
	LOGLEVEL_FATAL,
	LOGLEVEL_MAX = LOGLEVEL_FATAL,
} LOGLEVEL;

#define PAL_LOG_MAX_OUTPUTS   (LOGLEVEL_MAX + 1)

#if defined(DEBUG) || defined(_DEBUG)
# define PAL_DEFAULT_LOGLEVEL  LOGLEVEL_MIN
#else
# define PAL_DEFAULT_LOGLEVEL  LOGLEVEL_MAX
#endif


#define PAL_MAX_GLOBAL_BUFFERS 4
#define PAL_GLOBAL_BUFFER_SIZE 1024

//
// PAL_PATH_SEPARATORS contains all vaild path separators under a specific OS
// If you define this constant, please put the default separator at first.
//
#ifndef PAL_PATH_SEPARATORS
# define PAL_PATH_SEPARATORS "/"
#endif

#ifndef PAL_IS_PATH_SEPARATOR
# define PAL_IS_PATH_SEPARATOR(x) ((x) == '/')
#endif

#include "opltypes.h"

#endif
