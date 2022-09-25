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

#include "main.h"
#include <math.h>

volatile PALINPUTSTATE   g_InputState;

# define SDLK_KP_1     SDLK_KP1
# define SDLK_KP_2     SDLK_KP2
# define SDLK_KP_3     SDLK_KP3
# define SDLK_KP_4     SDLK_KP4
# define SDLK_KP_5     SDLK_KP5
# define SDLK_KP_6     SDLK_KP6
# define SDLK_KP_7     SDLK_KP7
# define SDLK_KP_8     SDLK_KP8
# define SDLK_KP_9     SDLK_KP9
# define SDLK_KP_0     SDLK_KP0

# define SDL_JoystickNameForIndex    SDL_JoystickName
# define SDL_GetKeyboardState        SDL_GetKeyState
# define SDL_GetScancodeFromKey(x)   (x)

static int _default_input_event_filter(const SDL_Event *event, volatile PALINPUTSTATE *state) { return 0; }

static int (*input_event_filter)(const SDL_Event *, volatile PALINPUTSTATE *) = _default_input_event_filter;

static const int g_KeyMap[][2] = {
   { SDLK_UP,        kKeyUp },
   { SDLK_DOWN,      kKeyDown },
   { SDLK_LEFT,      kKeyLeft },
   { SDLK_RIGHT,     kKeyRight },
   { SDLK_ESCAPE,    kKeyMenu },
   { SDLK_INSERT,    kKeyMenu },
   { SDLK_LALT,      kKeyMenu },
   { SDLK_RALT,      kKeyMenu },
   { SDLK_RETURN,    kKeySearch },
   { SDLK_SPACE,     kKeySearch },
   { SDLK_LCTRL,     kKeySearch },
   { SDLK_PAGEUP,    kKeyPgUp },
   { SDLK_PAGEDOWN,  kKeyPgDn },
   { SDLK_HOME,      kKeyHome },
   { SDLK_END,       kKeyEnd },
   { SDLK_r,         kKeyRepeat },
   { SDLK_a,         kKeyAuto },
   { SDLK_d,         kKeyDefend },
   { SDLK_e,         kKeyUseItem },
   { SDLK_w,         kKeyThrowItem },
   { SDLK_q,         kKeyFlee },
   { SDLK_f,         kKeyForce },
   { SDLK_s,         kKeyStatus }
};

static VOID
PAL_KeyDown(
   INT         key,
   BOOL        fRepeat
)
/*++
  Purpose:

    Called when user pressed a key.

  Parameters:

    [IN]  key - keycode of the pressed key.

  Return value:

    None.

--*/
{
   switch (key)
   {
   case kKeyUp:
      if (g_InputState.dir != kDirNorth && !fRepeat)
      {
         g_InputState.prevdir = (gpGlobals->fInBattle ? kDirUnknown : g_InputState.dir);
         g_InputState.dir = kDirNorth;
      }
      g_InputState.dwKeyPress |= kKeyUp;
      break;

   case kKeyDown:
      if (g_InputState.dir != kDirSouth && !fRepeat)
      {
         g_InputState.prevdir = (gpGlobals->fInBattle ? kDirUnknown : g_InputState.dir);
         g_InputState.dir = kDirSouth;
      }
      g_InputState.dwKeyPress |= kKeyDown;
      break;

   case kKeyLeft:
      if (g_InputState.dir != kDirWest && !fRepeat)
      {
         g_InputState.prevdir = (gpGlobals->fInBattle ? kDirUnknown : g_InputState.dir);
         g_InputState.dir = kDirWest;
      }
      g_InputState.dwKeyPress |= kKeyLeft;
      break;

   case kKeyRight:
      if (g_InputState.dir != kDirEast && !fRepeat)
      {
         g_InputState.prevdir = (gpGlobals->fInBattle ? kDirUnknown : g_InputState.dir);
         g_InputState.dir = kDirEast;
      }
      g_InputState.dwKeyPress |= kKeyRight;
      break;

   default:
      g_InputState.dwKeyPress |= key;
      break;
   }
}

static VOID
PAL_KeyUp(
   INT         key
)
/*++
  Purpose:

    Called when user released a key.

  Parameters:

    [IN]  key - keycode of the released key.

  Return value:

    None.

--*/
{
   switch (key)
   {
   case kKeyUp:
      if (g_InputState.dir == kDirNorth)
      {
         g_InputState.dir = g_InputState.prevdir;
      }
      g_InputState.prevdir = kDirUnknown;
      break;

   case kKeyDown:
      if (g_InputState.dir == kDirSouth)
      {
         g_InputState.dir = g_InputState.prevdir;
      }
      g_InputState.prevdir = kDirUnknown;
      break;

   case kKeyLeft:
      if (g_InputState.dir == kDirWest)
      {
         g_InputState.dir = g_InputState.prevdir;
      }
      g_InputState.prevdir = kDirUnknown;
      break;

   case kKeyRight:
      if (g_InputState.dir == kDirEast)
      {
         g_InputState.dir = g_InputState.prevdir;
      }
      g_InputState.prevdir = kDirUnknown;
      break;

   default:
      break;
   }
}

static VOID
PAL_UpdateKeyboardState(
   VOID
)
/*++
  Purpose:

    Poll & update keyboard state.

  Parameters:

    None.

  Return value:

    None.

--*/
{
   static DWORD   rgdwKeyLastTime[sizeof(g_KeyMap) / sizeof(g_KeyMap[0])] = {0};
   LPCBYTE        keyState = (LPCBYTE)SDL_GetKeyboardState(NULL);
   int            i;
   DWORD          dwCurrentTime = SDL_GetTicks();

   for (i = 0; i < sizeof(g_KeyMap) / sizeof(g_KeyMap[0]); i++)
   {
      if (keyState[SDL_GetScancodeFromKey(g_KeyMap[i][0])])
      {
         if (dwCurrentTime > rgdwKeyLastTime[i])
         {
            PAL_KeyDown(g_KeyMap[i][1], (rgdwKeyLastTime[i] != 0));
            if (gConfig.fEnableKeyRepeat)
            {
               rgdwKeyLastTime[i] = dwCurrentTime + (rgdwKeyLastTime[i] == 0 ? 200 : 75);
            }
            else
            {
               rgdwKeyLastTime[i] = 0xFFFFFFFF;
            }
         }
      }
      else
      {
         if (rgdwKeyLastTime[i] != 0)
         {
            PAL_KeyUp(g_KeyMap[i][1]);
            rgdwKeyLastTime[i] = 0;
         }
      }
   }
}

static int SDLCALL
PAL_EventFilter(
   const SDL_Event       *lpEvent
)

/*++
  Purpose:

    SDL event filter function. A filter to process all events.

  Parameters:

    [IN]  lpEvent - pointer to the event.

  Return value:

    1 = the event will be added to the internal queue.
    0 = the event will be dropped from the queue.

--*/
{
#ifndef __NAVY__
   switch (lpEvent->type)
   {
   case SDL_VIDEORESIZE:
      //
      // resized the window
      //
      VIDEO_Resize(lpEvent->resize.w, lpEvent->resize.h);
      break;

   case SDL_QUIT:
      //
      // clicked on the close button of the window. Quit immediately.
      //
      PAL_Shutdown(0);
   }
#endif

   //
   // All events are handled here; don't put anything to the internal queue
   //
   return 0;
}

VOID
PAL_ClearKeyState(
   VOID
)
/*++
  Purpose:

    Clear the record of pressed keys.

  Parameters:

    None.

  Return value:

    None.

--*/
{
   g_InputState.dwKeyPress = 0;
}

VOID
PAL_InitInput(
   VOID
)
/*++
  Purpose:

    Initialize the input subsystem.

  Parameters:

    None.

  Return value:

    None.

--*/
{
   memset((void *)&g_InputState, 0, sizeof(g_InputState));
   g_InputState.dir = kDirUnknown;
   g_InputState.prevdir = kDirUnknown;
}

VOID
PAL_ShutdownInput(
   VOID
)
/*++
  Purpose:

    Shutdown the input subsystem.

  Parameters:

    None.

  Return value:

    None.

--*/
{
}

static int
PAL_PollEvent(
   SDL_Event *event
)
/*++
  Purpose:

    Poll and process one event.

  Parameters:

    [OUT] event - Events polled from SDL.

  Return value:

    Return value of PAL_PollEvent.

--*/
{
   SDL_Event evt;

   int ret = SDL_PollEvent(&evt);
   if (ret != 0 && !input_event_filter(&evt, &g_InputState))
   {
      PAL_EventFilter(&evt);
   }

   if (event != NULL)
   {
      *event = evt;
   }

   return ret;
}

VOID
PAL_ProcessEvent(
   VOID
)
/*++
  Purpose:

    Process all events.

  Parameters:

    None.

  Return value:

    None.
 
--*/
{
   while (PAL_PollEvent(NULL));

   PAL_UpdateKeyboardState();
}
