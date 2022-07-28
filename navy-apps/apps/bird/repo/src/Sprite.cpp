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

#include "Sprite.h"
#include <search.h>
#include <assert.h>
#include <string.h>

CSprite::CSprite(SDL_Surface *pRenderer, const char *szImageFileName, const char *szTxtFileName)
{
  int ret = hcreate(512);
  assert(ret);
  Load(pRenderer, szImageFileName, szTxtFileName);
}

CSprite::~CSprite()
{
  if (m_pTexture != NULL)
    {
      SDL_FreeSurface(m_pTexture);
    }
  hdestroy();
}

static void myBlit(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect, int hasAlpha) {
  assert(dst && src);

  int sx = (srcrect == NULL ? 0 : srcrect->x);
  int sy = (srcrect == NULL ? 0 : srcrect->y);
  int dx = (dstrect == NULL ? 0 : dstrect->x);
  int dy = (dstrect == NULL ? 0 : dstrect->y);
  int w = (srcrect == NULL ? src->w : srcrect->w);
  int h = (srcrect == NULL ? src->h : srcrect->h);

  if (sx < 0) { w += sx; dx -= sx; sx = 0; }
  if (sy < 0) { h += sy; dy -= sy; sy = 0; }
  if (dx < 0) { w += dx; sx -= dx; dx = 0; }
  if (dy < 0) { h += dy; sy -= dy; dy = 0; }
  if (sx >= src->w) return;
  if (sy >= src->h) return;
  if (dx >= dst->w) return;
  if (dy >= dst->h) return;
  if (src->w - sx < w) { w = src->w - sx; }
  if (src->h - sy < h) { h = src->h - sy; }
  if (dst->w - dx < w) { w = dst->w - dx; }
  if (dst->h - dy < h) { h = dst->h - dy; }
  if (dstrect != NULL) {
    dstrect->w = w;
    dstrect->h = h;
  }

  if (!hasAlpha) {
    for (int j = 0; j < h; j ++) {
      memcpy((uint8_t *)dst->pixels + (dx + (dy + j) * dst->w) * 4,
          (uint8_t *)src->pixels + (sx + (sy + j) * src->w) * 4, w * 4);
    }
    return;
  }

  for (int j = 0; j < h; j ++) {
    uint32_t *pdst = (uint32_t *)dst->pixels + (dy + j) * dst->w + dx;
    uint32_t *psrc = (uint32_t *)src->pixels + (sy + j) * src->w + sx;
#define STEP 16
    int i;
    int first = w - w % STEP;
    for (i = 0; i < first; i += STEP) {
#define macro(k) { \
  int a = ((uint8_t *)(psrc + k))[3]; \
  if (a == 0xff) { \
    *(pdst + k) = *(psrc + k); \
  } else if (a != 0) { \
    uint8_t *pd = (uint8_t *)(pdst + k), *ps = (uint8_t *)(psrc + k); \
    pd[0] += ((ps[0] - pd[0]) * a) >> 8; \
    pd[1] += ((ps[1] - pd[1]) * a) >> 8; \
    pd[2] += ((ps[2] - pd[2]) * a) >> 8; \
  } \
}
      macro(0); macro(1); macro(2); macro(3);
      macro(4); macro(5); macro(6); macro(7);
      macro(8); macro(9); macro(10); macro(11);
      macro(12); macro(13); macro(14); macro(15);
      pdst += STEP;
      psrc += STEP;
    }
    for (; i < w; i ++) {
      macro(0);
      pdst ++;
      psrc ++;
    }
  }
}

void CSprite::Draw(SDL_Surface *pRenderer, const char *szTag, int x, int y)
{
  ENTRY item;
  item.key = (char *)szTag;
  ENTRY *ret = hsearch(item, FIND);

  if (ret)
    {
      SDL_Rect srcrect, dstrect;
      SpritePart_t *it = (SpritePart_t *)ret->data;

      srcrect.x = it->X;
      srcrect.y = it->Y;
      srcrect.w = it->usWidth;
      srcrect.h = it->usHeight;

      dstrect.x = x;
      dstrect.y = y;
      dstrect.w = it->usWidth;
      dstrect.h = it->usHeight;

      myBlit(m_pTexture, &srcrect, pRenderer, &dstrect, it->hasAlpha);
    }
}

void CSprite::DrawEx(SDL_Surface *pRenderer, const char *szTag, int x, int y, int angle)
{
  ENTRY item;
  item.key = (char *)szTag;
  ENTRY *ret = hsearch(item, FIND);

  if (ret)
    {
      SDL_Rect srcrect, dstrect;
      SpritePart_t *it = (SpritePart_t *)ret->data;

      srcrect.x = it->X;
      srcrect.y = it->Y;
      srcrect.w = it->usWidth;
      srcrect.h = it->usHeight;

      dstrect.x = x;
      dstrect.y = y;
      dstrect.w = it->usWidth;
      dstrect.h = it->usHeight;

      myBlit(m_pTexture, &srcrect, pRenderer, &dstrect, it->hasAlpha);
    }
}

void CSprite::Load(SDL_Surface *pRenderer, const char *szImageFileName, const char *szTxtFileName)
{
  SDL_Surface *pSurface = IMG_Load(szImageFileName);

  if (pSurface == NULL)
    {
      fprintf(stderr, "CSprite::Load(): IMG_Load failed: %s\n", IMG_GetError());
      return;
    }

  m_iTextureWidth = pSurface->w;
  m_iTextureHeight = pSurface->h;

  SDL_PixelFormat *fmt = pSurface->format;
  SDL_PixelFormat to = *fmt;
  to.Rloss = fmt->Bloss; to.Rshift = fmt->Bshift; to.Rmask = fmt->Bmask;
  to.Bloss = fmt->Rloss; to.Bshift = fmt->Rshift; to.Bmask = fmt->Rmask;
  m_pTexture = SDL_ConvertSurface(pSurface, &to, 0);
  assert(m_pTexture);
  SDL_FreeSurface(pSurface);

  // Load txt file
  if (!LoadTxt(szTxtFileName))
    {
      SDL_FreeSurface(m_pTexture);
      m_pTexture = NULL;

      fprintf(stderr, "CSprite::Load(): LoadTxte failed\n");
      return;
    }
}

bool CSprite::LoadTxt(const char *szTxtFileName)
{
  FILE *fp = fopen(szTxtFileName, "r");

  if (fp == NULL)
    {
      return false;
    }

  while (!feof(fp))
    {
      char name[256];
      int w, h, x, y;

      if (fscanf(fp, "%s %d %d %d %d", name, &w, &h, &x, &y) != 5)
	{
	  continue;
	}

      SpritePart_t *spritePart = new SpritePart_t;

      spritePart->usWidth = w;
      spritePart->usHeight = h;
      spritePart->X = x;
      spritePart->Y = y;

      spritePart->hasAlpha = 0;
      for (int j = 0; j < h; j ++) {
        for (int i = 0; i < w; i ++) {
          int alpha = ((uint8_t *)m_pTexture->pixels)[((y + j) * m_iTextureWidth + x + i) * 4 + 3];
          if (alpha != 255) {
            spritePart->hasAlpha = 1;
            break;
          }
        }
      }

      ENTRY item;
      item.key = strdup(name);
      item.data = spritePart;
      ENTRY *ret = hsearch(item, ENTER);
      assert(ret != NULL);
    }

  fclose(fp);
  return true;
}
