#include <stdlib.h>
#include <string.h>
#define _USE_MATH_DEFINES
#include <math.h>

#define ALIGNED     __attribute__((aligned(16)))

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#include "resampler.h"

enum { RESAMPLER_SHIFT = 10 };
enum { RESAMPLER_RESOLUTION = 1 << RESAMPLER_SHIFT };
enum { SINC_WIDTH = 16 };

enum { resampler_buffer_size = SINC_WIDTH * 4 };

typedef struct resampler
{
	int write_pos, write_filled;
	int read_pos, read_filled;
	unsigned int phase;
	unsigned int phase_inc;
	unsigned int inv_phase;
	unsigned int inv_phase_inc;
	unsigned char quality;
	signed char delay_added;
	signed char delay_removed;
	int buffer_in[resampler_buffer_size * 2];
	int buffer_out[resampler_buffer_size + SINC_WIDTH * 2 - 1];
} resampler;

static int resampler_run_zoh(resampler * r, int ** out_, int * out_end)
{
	int in_size = r->write_filled;
	int const* in_ = r->buffer_in + resampler_buffer_size + r->write_pos - r->write_filled;
	int used = 0;
	in_size -= 1;
	if (in_size > 0)
	{
		int* out = *out_;
		int const* in = in_;
		int const* const in_end = in + in_size;
		int phase = r->phase;
		int phase_inc = r->phase_inc;

		do
		{
			int sample;

			if (out >= out_end)
				break;

			sample = *in;
			*out++ = sample;

			phase += phase_inc;

			in += phase >> RESAMPLER_SHIFT;

			phase &= RESAMPLER_RESOLUTION - 1;
		} while (in < in_end);

		r->phase = (unsigned short)phase;
		*out_ = out;

		used = (int)(in - in_);

		r->write_filled -= used;
	}

	return used;
}

void resampler_init(void) {
}

void * resampler_create(void)
{
    resampler * r = ( resampler * ) malloc( sizeof(resampler) );
    if ( !r ) return 0;

    r->write_pos = SINC_WIDTH - 1;
    r->write_filled = 0;
    r->read_pos = 0;
    r->read_filled = 0;
    r->phase = 0;
    r->phase_inc = 0;
    r->inv_phase = 0;
    r->inv_phase_inc = 0;
    r->quality = RESAMPLER_QUALITY_MAX;
    r->delay_added = -1;
    r->delay_removed = -1;
    memset( r->buffer_in, 0, sizeof(r->buffer_in) );
    memset( r->buffer_out, 0, sizeof(r->buffer_out) );

    return r;
}

void resampler_delete(void * _r)
{
    free( _r );
}

void resampler_set_quality(void *_r, int quality)
{
    resampler * r = ( resampler * ) _r;
    quality = RESAMPLER_QUALITY_MIN;
    if ( r->quality != quality )
    {
        r->delay_added = -1;
        r->delay_removed = -1;
    }
    r->quality = (unsigned char)quality;
}

int resampler_get_free_count(void *_r)
{
    resampler * r = ( resampler * ) _r;
    return resampler_buffer_size - r->write_filled;
}

static int resampler_min_filled(resampler *r) {
  return 1;
}

static int resampler_input_delay(resampler *r) {
  return 0;
}

static int resampler_output_delay(resampler *r) {
  return 0;
}

void resampler_clear(void *_r)
{
    resampler * r = ( resampler * ) _r;
    r->write_pos = SINC_WIDTH - 1;
    r->write_filled = 0;
    r->read_pos = 0;
    r->read_filled = 0;
    r->phase = 0;
    r->delay_added = -1;
    r->delay_removed = -1;
    memset(r->buffer_in, 0, (SINC_WIDTH - 1) * sizeof(r->buffer_in[0]));
    memset(r->buffer_in + resampler_buffer_size, 0, (SINC_WIDTH - 1) * sizeof(r->buffer_in[0]));
}

void resampler_set_rate(void *_r, unsigned x, unsigned y)
{
    // new_factor = x / y;
    resampler * r = ( resampler * ) _r;
    r->phase_inc = (int)( x * RESAMPLER_RESOLUTION / y);
    r->inv_phase_inc = (int)( y * RESAMPLER_RESOLUTION / x);
}

void resampler_write_sample(void *_r, short s)
{
    resampler * r = ( resampler * ) _r;

    if ( r->delay_added < 0 )
    {
        r->delay_added = 0;
        r->write_filled = resampler_input_delay( r );
    }
    
    if ( r->write_filled < resampler_buffer_size )
    {
        int s32 = s * 256;

        r->buffer_in[ r->write_pos ] = s32;
        r->buffer_in[ r->write_pos + resampler_buffer_size ] = s32;

        ++r->write_filled;

        r->write_pos = ( r->write_pos + 1 ) % resampler_buffer_size;
    }
}

static void resampler_fill(resampler * r)
{
    int min_filled = resampler_min_filled(r);
    while ( r->write_filled > min_filled &&
            r->read_filled < resampler_buffer_size )
    {
        int write_pos = ( r->read_pos + r->read_filled ) % resampler_buffer_size;
        int write_size = resampler_buffer_size - write_pos;
        int * out = r->buffer_out + write_pos;
        if ( write_size > ( resampler_buffer_size - r->read_filled ) )
            write_size = resampler_buffer_size - r->read_filled;
        resampler_run_zoh( r, &out, out + write_size );
        r->read_filled += out - r->buffer_out - write_pos;
    }
}

static void resampler_fill_and_remove_delay(resampler * r)
{
    resampler_fill( r );
    if ( r->delay_removed < 0 )
    {
        int delay = resampler_output_delay( r );
        r->delay_removed = 0;
        while ( delay-- )
            resampler_remove_sample( r );
    }
}

int resampler_get_sample_count(void *_r)
{
    resampler * r = ( resampler * ) _r;
    if ( r->read_filled < 1)
        resampler_fill_and_remove_delay( r );
    return r->read_filled;
}

int resampler_get_sample(void *_r)
{
    resampler * r = ( resampler * ) _r;
    if ( r->read_filled < 1 && r->phase_inc)
        resampler_fill_and_remove_delay( r );
    if ( r->read_filled < 1 )
        return 0;
    return (int)r->buffer_out[ r->read_pos ];
}

void resampler_remove_sample(void *_r)
{
    resampler * r = ( resampler * ) _r;
    if ( r->read_filled > 0 )
    {
        --r->read_filled;
        r->read_pos = ( r->read_pos + 1 ) % resampler_buffer_size;
    }
}
