/*
 * Copyright (c) 2014, Wei Mingzhi <whistler_wmz@users.sf.net>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author and contributors may not be used to endorse
 *    or promote products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL WASABI SYSTEMS, INC
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <SDL.h>
#include <SDL_image.h>

#include "BirdGame.h"
#include "Sprite.h"
#include "Video.h"
#include "Audio.h"

#include <stdlib.h>
#include <time.h>
#include <assert.h>

#define SCALE SCREEN_HEIGHT / 511
#define BIRD_DROP_HEIGHT 40
#define PIPE_DRAW_Y_DISTANCE (311 + PIPE_Y_DISTANCE)

static CSprite *gpSprite = NULL;

typedef enum tagGameState
  {
    GAMESTATE_INITIAL = 0,
    GAMESTATE_GAMESTART,
    GAMESTATE_GAME,
    GAMESTATE_GAMEOVER,
  } GameState;

static GameState g_GameState = GAMESTATE_INITIAL;
static bool g_bMouseDown = false;
static bool g_bNight = false;
static int g_iBirdPic = 0;
static int g_iMouseX = 0;
static int g_iMouseY = 0;
static int g_iScore = 0;
static int g_iHighScore = 0;
static int g_flBirdVelocity100 = 0;
static int g_flBirdHeight100 = 0;
static int g_flBirdAngle100 = 0;
static int g_iPipePosX[3] = { 0, 0, 0 };
static int g_iPipePosY[3] = { 0, 0, 0 };

static void *g_pSfxDie = NULL;
static void *g_pSfxHit = NULL;
static void *g_pSfxPoint = NULL;
static void *g_pSfxSwooshing = NULL;
static void *g_pSfxWing = NULL;

#define GRAVITY100   32
#define WINGPOWER100 520
#define ROTATION100  270
#define PIPEDISTANCE 150
#define PIPEWIDTH    50
#define BIRDWIDTH    48
#define BIRDMARGIN   12

#ifdef __NAVY__
#include <fixedptc.h>
#else
#include <math.h>
#endif

static inline int min(int a, int b) { return a < b ? a : b; }
static inline int mycos(int ticks, int multipler) {
  ticks = ticks / 2 % 360;
#ifdef __NAVY__
  return fixedpt_toint(fixedpt_muli(
        fixedpt_cos(fixedpt_divi(fixedpt_muli(FIXEDPT_PI, ticks), 180)),
        multipler));
#else
  return cos(ticks * 3.14 / 180) * multipler;
#endif
}

static void LoadWav()
{
  g_pSfxDie = SOUND_LoadWAV(FILE_PATH("sfx_die.wav"));
  g_pSfxHit = SOUND_LoadWAV(FILE_PATH("sfx_hit.wav"));
  g_pSfxPoint = SOUND_LoadWAV(FILE_PATH("sfx_point.wav"));
  g_pSfxSwooshing = SOUND_LoadWAV(FILE_PATH("sfx_swooshing.wav"));
  g_pSfxWing = SOUND_LoadWAV(FILE_PATH("sfx_wing.wav"));
}

static void FreeWav()
{
  SDL_PauseAudio(1);

  if (g_pSfxDie != NULL)
    {
      SOUND_FreeWAV(g_pSfxDie);
      g_pSfxDie = NULL;
    }
  if (g_pSfxHit != NULL)
    {
      SOUND_FreeWAV(g_pSfxHit);
      g_pSfxHit = NULL;
    }
  if (g_pSfxPoint != NULL)
    {
      SOUND_FreeWAV(g_pSfxPoint);
      g_pSfxPoint = NULL;
    }
  if (g_pSfxSwooshing != NULL)
    {
      SOUND_FreeWAV(g_pSfxSwooshing);
      g_pSfxSwooshing = NULL;
    }
  if (g_pSfxWing != NULL)
    {
      SOUND_FreeWAV(g_pSfxWing);
      g_pSfxWing = NULL;
    }
}

static void UpdateEvents()
{
  SDL_Event evt;

  while (SDL_PollEvent(&evt))
    {
      switch (evt.type)
	{
#ifndef __NAVY__
	case SDL_QUIT:
	  exit(0);
	  break;

	case SDL_MOUSEBUTTONDOWN:
	  g_bMouseDown = true;
	  g_iMouseX = evt.button.x;
	  g_iMouseY = evt.button.y;
	  break;

	case SDL_MOUSEBUTTONUP:
	  g_bMouseDown = false;
	  break;
#endif

	case SDL_KEYDOWN:
	  g_bMouseDown = true;
	  break;

	case SDL_KEYUP:
	  g_bMouseDown = false;
	  break;
	}
    }
}

static void ShowTitle()
{
  SDL_Surface *pSurfaceTitle = IMG_Load(FILE_PATH("splash.png"));
  if (pSurfaceTitle == NULL)
    {
      fprintf(stderr, "cannot load splash.png\n");
      return;
    }

  SDL_PixelFormat *fmt = pSurfaceTitle->format;
  SDL_PixelFormat to = *fmt;
  to.Rloss = fmt->Bloss; to.Rshift = fmt->Bshift; to.Rmask = fmt->Bmask;
  to.Bloss = fmt->Rloss; to.Bshift = fmt->Rshift; to.Bmask = fmt->Rmask;
  SDL_Surface *s = SDL_ConvertSurface(pSurfaceTitle, &to, 0);
  assert(s);
  SDL_FreeSurface(pSurfaceTitle);
  pSurfaceTitle = s;

  unsigned int uiStartTime = SDL_GetTicks();

  SDL_Rect rect;
  rect.x = (pSurfaceTitle->w - SCREEN_WIDTH) / 2;
  rect.y = (pSurfaceTitle->h - SCREEN_HEIGHT) / 2;
  rect.w = SCREEN_WIDTH;
  rect.h = SCREEN_HEIGHT;
  while (SDL_GetTicks() - uiStartTime < 1000)
    {
      SDL_BlitSurface(pSurfaceTitle, &rect, gpRenderer, NULL);
      SDL_UpdateRect(gpRenderer, 0, 0, 0, 0);

      UpdateEvents();
      SDL_Delay(100);
    }

  SDL_FreeSurface(pSurfaceTitle);
}

static void DrawBackground()
{
  gpSprite->Draw(gpRenderer, g_bNight ? "bg_night" : "bg_day", 0, 0);
}

static void DrawLand(bool bStatic)
{
  static unsigned int time = 0;
  if (!bStatic)
    {
      time++;
    }

  gpSprite->Draw(gpRenderer, "land", -(int)((time * 2) % SCREEN_WIDTH), SCREEN_HEIGHT - LAND_HEIGHT);
  gpSprite->Draw(gpRenderer, "land", 287 - ((time * 2) % SCREEN_WIDTH), SCREEN_HEIGHT - LAND_HEIGHT);
}

static void DrawScore(int score)
{
  int iScoreLen = 0;
  int iBeginX = SCREEN_WIDTH / 2;
  int iReverseScore = 0;

  do
    {
      if (score % 10 == 1)
	{
	  iBeginX -= 16 / 2 + 1;
	}
      else
	{
	  iBeginX -= 24 / 2 + 1;
	}

      iReverseScore *= 10;
      iReverseScore += score % 10;

      score /= 10;
      iScoreLen++;
    } while (score > 0);

  do
    {
      char buf[256];
      sprintf(buf, "font_%.3d", 48 + (iReverseScore % 10));

      gpSprite->Draw(gpRenderer, buf, iBeginX, 60 * SCALE);
      if (iReverseScore % 10 == 1)
	{
	  iBeginX += 16 + 2;
	}
      else
	{
	  iBeginX += 24 + 2;
	}
      
      iReverseScore /= 10;
      iScoreLen--;
    } while (iScoreLen > 0);
}

static void DrawScoreOnBoard(int score, int x, int y)
{
  int iScoreLen = 0;
  int iBeginX = x;
  int iReverseScore = 0;

  do
    {
      iBeginX -= 16;
      iReverseScore *= 10;
      iReverseScore += score % 10;

      score /= 10;
      iScoreLen++;
    } while (score > 0);

  do
    {
      char buf[256];
      sprintf(buf, "number_score_%.2d", iReverseScore % 10);

      gpSprite->Draw(gpRenderer, buf, iBeginX, y);
      iBeginX += 16;

      iReverseScore /= 10;
      iScoreLen--;
    } while (iScoreLen > 0);
}

static void GameThink_Initial()
{
  static unsigned int fading_start_time = 0;
  static GameState enNextGameState;

  if (fading_start_time > 0)
    {
      unsigned int elapsed = SDL_GetTicks() - fading_start_time;

      if (elapsed > 500)
	{
	  g_GameState = enNextGameState;
	  gpSprite->SetColorMod(255, 255, 255);
	  fading_start_time = 0;
	  g_bNight = ((rand() % 2) == 1);
	  g_iBirdPic = rand() % 3;
	  for (int i = 0; i < 3; i++)
	    {
	      g_iPipePosX[i] = SCREEN_WIDTH + 200 + i * PIPEDISTANCE;
	      g_iPipePosY[i] = rand() % 200;
	    }
	  return;
	}

      elapsed *= 255;
      elapsed /= 500;

      elapsed = 255 - elapsed;

      gpSprite->SetColorMod(elapsed, elapsed, elapsed);
    }

  DrawBackground();
  DrawLand(false);

  gpSprite->Draw(gpRenderer, "title", 55, 110 * SCALE);

  char buf[256];
  sprintf(buf, "bird0_%d", (SDL_GetTicks() / 200) % 3);
  gpSprite->Draw(gpRenderer, buf, 118, 180 * SCALE + mycos(SDL_GetTicks(), 5));

  gpSprite->Draw(gpRenderer, "button_play", 85, 340 * SCALE);

  gpSprite->Draw(gpRenderer, "brand_copyright", 80, 450 * SCALE);

  if (g_bMouseDown)
    {
	  // user clicked "play" button
	  fading_start_time = SDL_GetTicks();
	  enNextGameState = GAMESTATE_GAMESTART;
    }
}

static void BirdFly()
{
  g_flBirdVelocity100 = WINGPOWER100;
  g_flBirdAngle100 = -45 * 100;
  SOUND_PlayWAV(1, g_pSfxWing);
}

static void GameThink_GameStart()
{
  static unsigned int fading_start_time = 0;

  if (fading_start_time == 0)
    {
      fading_start_time = SDL_GetTicks();
    }

  unsigned int elapsed = SDL_GetTicks() - fading_start_time;

  if (elapsed < 500)
    {
      elapsed *= 255;
      elapsed /= 500;

      gpSprite->SetColorMod(elapsed, elapsed, elapsed);
    }
  else
    {
      gpSprite->SetColorMod(255, 255, 255);
    }

  DrawBackground();
  DrawLand(false);

  char buf[256];
  sprintf(buf, "bird%d_%d", g_iBirdPic, (SDL_GetTicks() / 200) % 3);
  g_flBirdHeight100 = 230 * SCALE * 100 + mycos(SDL_GetTicks(), 5 * 100);
  gpSprite->Draw(gpRenderer, buf, 60, g_flBirdHeight100 / 100);

  // draw score
  DrawScore(0);

  // draw "get ready" notice
  gpSprite->Draw(gpRenderer, "text_ready", 50, 130 * SCALE);

  // draw hint picture
  gpSprite->Draw(gpRenderer, "tutorial", 90, 220 * SCALE);

  if (g_bMouseDown)
    {
      g_GameState = GAMESTATE_GAME;
      gpSprite->SetColorMod(255, 255, 255);
      fading_start_time = 0;
      g_iScore = 0;
      BirdFly();
    }
}

static void GameThink_Game()
{
  static bool bPrevMouseDown = false;
  bool bGameOver = false;
	
  static bool bPrevInRange = false;

  int i;

  g_flBirdHeight100 -= g_flBirdVelocity100;
  g_flBirdVelocity100 -= GRAVITY100;

  g_flBirdAngle100 += ROTATION100;
  if (g_flBirdAngle100 > 85 * 100)
    {
      g_flBirdAngle100 = 85 * 100;
    }

  if (g_flBirdHeight100 < -50 * 100)
    {
      // bird is above the sky
      g_flBirdHeight100 = -50 * 100;
    }
  else if (g_flBirdHeight100 > (SCREEN_HEIGHT - LAND_HEIGHT - BIRD_DROP_HEIGHT) * 100)
    {
      // bird has hit the ground
      g_flBirdHeight100 = (SCREEN_HEIGHT - LAND_HEIGHT - BIRD_DROP_HEIGHT) * 100;
      bGameOver = true;
    }

  DrawBackground();

  // move pipes
  for (i = 0; i < 3; i++)
    {
      g_iPipePosX[i] -= 2;
    }

  if (g_iPipePosX[0] < -PIPEWIDTH)
    {
      g_iPipePosX[0] = g_iPipePosX[1];
      g_iPipePosX[1] = g_iPipePosX[2];
      g_iPipePosX[2] = g_iPipePosX[1] + PIPEDISTANCE;

      g_iPipePosY[0] = g_iPipePosY[1];
      g_iPipePosY[1] = g_iPipePosY[2];
      g_iPipePosY[2] = rand() % 200;
    }

  // draw pipes
  for (i = 0; i < 3; i++)
    {
      int upPosY = SCREEN_HEIGHT - LAND_HEIGHT - 250 + g_iPipePosY[i];
      int downPosY = upPosY - PIPE_DRAW_Y_DISTANCE;
      gpSprite->Draw(gpRenderer, "pipe_down", g_iPipePosX[i], downPosY);
      gpSprite->Draw(gpRenderer, "pipe_up", g_iPipePosX[i], upPosY);
    }

  DrawScore(g_iScore);
  DrawLand(false);

  // draw bird
  char buf[256];
  sprintf(buf, "bird%d_%d", g_iBirdPic, (SDL_GetTicks() / 200) % 3);
  gpSprite->DrawEx(gpRenderer, buf, 60, g_flBirdHeight100 / 100, g_flBirdAngle100 / 100);

  // check if bird is in the range of a pipe
  if (g_iPipePosX[0] < 60 + BIRDWIDTH - BIRDMARGIN && g_iPipePosX[0] + PIPEWIDTH > 60 + BIRDMARGIN)
    {
      if (!bPrevInRange && g_iPipePosX[0] + PIPEWIDTH / 2 < 60 + BIRDMARGIN)
	{
	  g_iScore++;
	  SOUND_PlayWAV(0, g_pSfxPoint);
	  bPrevInRange = true;
	}

      // check if the bird hits the pipe
      int upPosY = SCREEN_HEIGHT - LAND_HEIGHT - 250 + g_iPipePosY[0];
      int downPosY = upPosY - PIPE_DRAW_Y_DISTANCE + 320;
      if (g_flBirdHeight100 / 100 + BIRDMARGIN < downPosY ||
	  g_flBirdHeight100 / 100 + BIRDWIDTH - BIRDMARGIN > upPosY)
	{
	  bGameOver = true;
	}
    }
  else
    {
      bPrevInRange = false;
    }

  if (bGameOver)
    {
      bPrevMouseDown = false;
      bPrevInRange = false;
      g_GameState = GAMESTATE_GAMEOVER;
      return;
    }

  if (g_bMouseDown && !bPrevMouseDown)
    {
      BirdFly();
    }

  bPrevMouseDown = g_bMouseDown;
}

static void GameThink_GameOver()
{
  static enum { FLASH, DROP, SHOWTITLE, SHOWSCORE } gameoverState = FLASH;
  static int time = 0;
  static bool bIsHighscore = false;
  static int fading_start_time = 0;

  if (gameoverState == FLASH)
    {
      SDL_FillRect(gpRenderer, NULL, 0xFFFFFFFF);
      if (time == 0)
	{
	  SOUND_PlayWAV(0, g_pSfxHit);
	}
      else if (time > 2)
	{
	  gameoverState = DROP;
	  time = 0;
	  return;
	}
      time++;
    }
  else if (gameoverState == DROP)
    {
      if (g_flBirdHeight100 / 100 < SCREEN_HEIGHT - LAND_HEIGHT - BIRD_DROP_HEIGHT || !time)
	{
	  if (time == 15)
	    {
	      SOUND_PlayWAV(1, g_pSfxDie);
	    }
	  g_flBirdAngle100 = 85 * 100;
	  g_flBirdHeight100 += 8 * 100;

	  if (g_flBirdHeight100 > (SCREEN_HEIGHT - LAND_HEIGHT - BIRD_DROP_HEIGHT) * 100)
	    {
	      g_flBirdHeight100 = (SCREEN_HEIGHT - LAND_HEIGHT - BIRD_DROP_HEIGHT) * 100;
	    }

	  DrawBackground();

	  // draw pipes
	  for (int i = 0; i < 3; i++)
	    {
      int upPosY = SCREEN_HEIGHT - LAND_HEIGHT - 250 + g_iPipePosY[i];
      int downPosY = upPosY - PIPE_DRAW_Y_DISTANCE;
	      gpSprite->Draw(gpRenderer, "pipe_down", g_iPipePosX[i], downPosY);
	      gpSprite->Draw(gpRenderer, "pipe_up", g_iPipePosX[i], upPosY);
	    }

	  DrawLand(true);

	  // draw bird
	  char buf[256];
	  sprintf(buf, "bird%d_%d", g_iBirdPic, (SDL_GetTicks() / 200) % 3);
	  gpSprite->DrawEx(gpRenderer, buf, 60, g_flBirdHeight100 / 100, g_flBirdAngle100 / 100);

	  DrawScore(g_iScore);
	  time++;
	}
      else
	{
	  gameoverState = SHOWTITLE;
	  time = 0;
	}
    }
  else if (gameoverState == SHOWTITLE)
    {
      DrawBackground();

      // draw pipes
      for (int i = 0; i < 3; i++)
	{
      int upPosY = SCREEN_HEIGHT - LAND_HEIGHT - 250 + g_iPipePosY[i];
      int downPosY = upPosY - PIPE_DRAW_Y_DISTANCE;
	  gpSprite->Draw(gpRenderer, "pipe_down", g_iPipePosX[i], downPosY);
	  gpSprite->Draw(gpRenderer, "pipe_up", g_iPipePosX[i], upPosY);
	}

      DrawLand(true);

      // draw bird
      char buf[256];
      sprintf(buf, "bird%d_0", g_iBirdPic);
      gpSprite->DrawEx(gpRenderer, buf, 60, g_flBirdHeight100 / 100, g_flBirdAngle100 / 100);

      if (time > 30)
	{
	  if (time < 30 + 5)
	    {
	      if (time == 30 + 1)
		{
		  SOUND_PlayWAV(0, g_pSfxSwooshing);
		}
	      gpSprite->Draw(gpRenderer, "text_game_over", 45, 110 * SCALE - (time - 30) * 6);
	      time++;
	    }
	  else if (time < 30 + 15)
	    {
	      gpSprite->Draw(gpRenderer, "text_game_over", 45, 80 * SCALE + (time - 30) * 3);
	      time++;
	    }
	  else if (time < 30 + 25)
	    {
	      gpSprite->Draw(gpRenderer, "text_game_over", 45, 80 * SCALE + 15 * 3);
	      time++;
	    }
	  else
	    {
	      gpSprite->Draw(gpRenderer, "text_game_over", 45, 80 * SCALE + 15 * 3);
	      gameoverState = SHOWSCORE;
	      time = 0;

	      if (g_iScore > g_iHighScore)
		{
		  g_iHighScore = g_iScore;
		  bIsHighscore = true;
		}
	    }
	}
      else
	{
	  DrawScore(g_iScore);
	  time++;
	}
    }
  else if (gameoverState == SHOWSCORE)
    {
      if (fading_start_time > 0)
	{
	  unsigned int elapsed = SDL_GetTicks() - fading_start_time;

	  if (elapsed > 500)
	    {
	      g_GameState = GAMESTATE_GAMESTART;
	      gpSprite->SetColorMod(255, 255, 255);
	      fading_start_time = 0;
	      gameoverState = FLASH;
	      time = 0;
	      bIsHighscore = false;
	      g_bNight = ((rand() % 2) == 1);
	      g_iBirdPic = rand() % 3;
	      for (int i = 0; i < 3; i++)
		{
		  g_iPipePosX[i] = SCREEN_WIDTH + 200 + i * PIPEDISTANCE;
		  g_iPipePosY[i] = rand() % 200;
		}
	      return;
	    }

	  elapsed *= 255;
	  elapsed /= 500;

	  elapsed = 255 - elapsed;

	  gpSprite->SetColorMod(elapsed, elapsed, elapsed);
	}

      DrawBackground();

      // draw pipes
      for (int i = 0; i < 3; i++)
	{
      int upPosY = SCREEN_HEIGHT - LAND_HEIGHT - 250 + g_iPipePosY[i];
      int downPosY = upPosY - PIPE_DRAW_Y_DISTANCE;
	  gpSprite->Draw(gpRenderer, "pipe_down", g_iPipePosX[i], downPosY);
	  gpSprite->Draw(gpRenderer, "pipe_up", g_iPipePosX[i], upPosY);
	}

      DrawLand(true);

      // draw bird
      char buf[256];
      sprintf(buf, "bird%d_0", g_iBirdPic);
      gpSprite->DrawEx(gpRenderer, buf, 60, g_flBirdHeight100 / 100, g_flBirdAngle100 / 100);

      gpSprite->Draw(gpRenderer, "text_game_over", 45, 80 * SCALE + 15 * 3);

      if (time < 15)
	{
	  if (time == 0)
	    {
	      SOUND_PlayWAV(0, g_pSfxSwooshing);
	    }
	  gpSprite->Draw(gpRenderer, "score_panel", 31, 190 * SCALE + (15 - time) * 20);
	}
      else
	{
    int panelY = 190 * SCALE;
	  gpSprite->Draw(gpRenderer, "score_panel", 31, panelY);
	  DrawScoreOnBoard(min(g_iScore, (time - 15) / 2), 240, panelY + 35);
	  DrawScoreOnBoard(g_iHighScore, 240, panelY + 75);

	  if (bIsHighscore)
	    {
	      gpSprite->Draw(gpRenderer, "new", 170, panelY + 60);
	    }

    int medalY = panelY + 45;
	  if (g_iScore >= 40)
	    {
	      gpSprite->Draw(gpRenderer, "medals_0", 62, medalY);
	    }
	  else if (g_iScore >= 30)
	    {
	      gpSprite->Draw(gpRenderer, "medals_1", 62, medalY);
	    }
	  else if (g_iScore >= 20)
	    {
	      gpSprite->Draw(gpRenderer, "medals_2", 62, medalY);
	    }
	  else if (g_iScore >= 10)
	    {
	      gpSprite->Draw(gpRenderer, "medals_3", 62, medalY);
	    }
		  
	  gpSprite->Draw(gpRenderer, "button_play", 85, 340 * SCALE);

	  if (fading_start_time == 0 && g_bMouseDown)
	    {
		  // user clicked to play
		  fading_start_time = SDL_GetTicks();
	    }

	}

      time++;
    }
}

int GameMain()
{
  srand((unsigned int)time(NULL));

  gpSprite = new CSprite(gpRenderer, FILE_PATH("atlas.png"), FILE_PATH("atlas.txt"));

  atexit([](void) { delete gpSprite; });

  LoadWav();

  atexit(FreeWav);
  atexit(SOUND_CloseAudio);

  ShowTitle();

  g_GameState = GAMESTATE_INITIAL;

  unsigned int uiNextFrameTime = SDL_GetTicks();
  unsigned int uiCurrentTime = SDL_GetTicks();

  while (1)
    {
      // 60fps
      do
	{
	  uiCurrentTime = SDL_GetTicks();
	  UpdateEvents();
	  SDL_Delay(1);
	} while (uiCurrentTime < uiNextFrameTime);

      if ((int)(uiCurrentTime - uiNextFrameTime) > 1000)
	{
	  uiNextFrameTime = uiCurrentTime + 1000 / 60;
	}
      else
	{
	  uiNextFrameTime += 1000 / 60;
	}

      switch (g_GameState)
	{
	case GAMESTATE_INITIAL:
	  GameThink_Initial();
	  break;

	case GAMESTATE_GAMESTART:
	  GameThink_GameStart();
	  break;

	case GAMESTATE_GAME:
	  GameThink_Game();
	  break;

	case GAMESTATE_GAMEOVER:
	  GameThink_GameOver();
	  break;

	default:
	  fprintf(stderr, "invalid game state: %d\n", (int)g_GameState);
	  exit(255);
	}

      SDL_UpdateRect(gpRenderer, 0, 0, 0, 0);
    }

  return 255; // shouldn't really reach here
}
