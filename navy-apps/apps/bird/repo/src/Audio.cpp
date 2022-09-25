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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <SDL.h>

static int audio_len = 0;
static unsigned char *audio_pos = NULL;
static int audio_len2 = 0;
static unsigned char *audio_pos2 = NULL;
static SDL_mutex *mtx = NULL;
static SDL_AudioSpec audio_spec;
bool g_fAudioOpened = false;

// The audio function callback takes the following parameters:
// stream:  A pointer to the audio buffer to be filled
// len:     The length (in bytes) of the audio buffer
static void SOUND_FillAudio(void *, unsigned char *stream, int len)
{
  memset(stream, 0, len);

  int len2 = len;
  unsigned char *mix_stream1 = NULL, *mix_stream2 = NULL;
  int mix_len1 = 0, mix_len2 = 0;

  SDL_mutexP(mtx);

  // Mix as much data as possible
  if (audio_len > 0)
    {
      len = (len > audio_len) ? audio_len : len;
      mix_stream1 = audio_pos;
      mix_len1 = len;
      audio_pos += len;
      audio_len -= len;
    }

  if (audio_len2 > 0)
    {
      len = (len2 > audio_len2) ? audio_len2 : len2;
      mix_stream2 = audio_pos2;
      mix_len2 = len;
      audio_pos2 += len;
      audio_len2 -= len;
    }

  SDL_mutexV(mtx);

  if (mix_stream1 != NULL)
    {
      SDL_MixAudio(stream, mix_stream1, mix_len1, SDL_MIX_MAXVOLUME);
    }

  if (mix_stream2 != NULL)
    {
      SDL_MixAudio(stream, mix_stream2, mix_len2, SDL_MIX_MAXVOLUME);
    }
}

int SOUND_OpenAudio(int freq, int channels, int samples)
{
  if (g_fAudioOpened) 
    {
      return 0;
    }

  mtx = SDL_CreateMutex();

  // Set the audio format
  audio_spec.freq = freq;
  audio_spec.format = AUDIO_S16;
  audio_spec.channels = channels; // 1 = mono, 2 = stereo
  audio_spec.samples = samples;
  audio_spec.callback = SOUND_FillAudio;
  audio_spec.userdata = NULL;

  // Open the audio device, forcing the desired format
  if (SDL_OpenAudio(&audio_spec, NULL) < 0)
    {
      fprintf(stderr, "WARNING: Couldn't open audio: %s\n", SDL_GetError());
      return -1;
    }
  else
    {
      g_fAudioOpened = true;
      return 0;
    }
}

void SOUND_CloseAudio()
{
  if (g_fAudioOpened)
    {
      SDL_CloseAudio();
      g_fAudioOpened = false;
    }

  SDL_DestroyMutex(mtx);
  mtx = NULL;
}

#ifndef __NAVY__
void *SOUND_LoadWAV(const char *filename)
{
  SDL_AudioCVT *wavecvt;
  SDL_AudioSpec wavespec, *loaded;
  unsigned char *buf;
  unsigned int len;

  if (!g_fAudioOpened) {
    return NULL;
  }

  wavecvt = (SDL_AudioCVT *)malloc(sizeof(SDL_AudioCVT));
  if (wavecvt == NULL)
    {
      return NULL;
    }

  loaded = SDL_LoadWAV(filename, &wavespec, &buf, &len);
  if (loaded == NULL) 
    {
      free(wavecvt);
      return NULL;
    }

  // Build the audio converter and create conversion buffers
  if (SDL_BuildAudioCVT(wavecvt, wavespec.format, wavespec.channels, wavespec.freq,
			audio_spec.format, audio_spec.channels, audio_spec.freq) < 0)
    {
      SDL_FreeWAV(buf);
      free(wavecvt);
      return NULL;
    }
  int samplesize = ((wavespec.format & 0xFF) / 8) * wavespec.channels;
  wavecvt->len = len & ~(samplesize - 1);
  wavecvt->buf = (unsigned char *)malloc(wavecvt->len * wavecvt->len_mult);
  if (wavecvt->buf == NULL)
    {
      SDL_FreeWAV(buf);
      free(wavecvt);
      return NULL;
    }
  memcpy(wavecvt->buf, buf, len);
  SDL_FreeWAV(buf);

  // Run the audio converter
  if (SDL_ConvertAudio(wavecvt) < 0)
    {
      free(wavecvt->buf);
      free(wavecvt);
      return NULL;
    }

  return wavecvt;
}
#else
typedef struct {
  uint8_t *buf;
  int len;
  int len_mult;
} SDL_AudioCVT;

void *SOUND_LoadWAV(const char *filename)
{
  SDL_AudioSpec wavespec, *loaded;
  uint8_t *buf;
  uint32_t len;
  SDL_AudioSpec *ret = SDL_LoadWAV(filename, &wavespec, &buf, &len);
  if (ret == NULL) return NULL;
  SDL_AudioCVT *audio = new SDL_AudioCVT;
  audio->buf = buf;
  audio->len = len;
  audio->len_mult = 1;
  return audio;
}
#endif

void SOUND_FreeWAV(void *audio)
{
  if (audio == NULL)
    {
      return;
    }
#ifdef __NAVY__
  SDL_FreeWAV(((SDL_AudioCVT *)audio)->buf);
#else
  free(((SDL_AudioCVT *)audio)->buf);
#endif
  free(audio);
}

void SOUND_PlayWAV(int channel, void *audio)
{
  if (audio == NULL)
    {
      return;
    }

  SDL_mutexP(mtx);
  if (channel == 0)
    {
      audio_pos = ((SDL_AudioCVT *)audio)->buf;
      audio_len = ((SDL_AudioCVT *)audio)->len * ((SDL_AudioCVT *)audio)->len_mult;
    }
  else
    {
      audio_pos2 = ((SDL_AudioCVT *)audio)->buf;
      audio_len2 = ((SDL_AudioCVT *)audio)->len * ((SDL_AudioCVT *)audio)->len_mult;
    }
  SDL_mutexV(mtx);

  SDL_PauseAudio(0);
}
