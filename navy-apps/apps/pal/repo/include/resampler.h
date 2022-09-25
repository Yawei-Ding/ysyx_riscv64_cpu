#ifndef _RESAMPLER_H_
#define _RESAMPLER_H_

#ifdef __cplusplus
extern "C" {
#endif

void resampler_init(void);

void * resampler_create(void);
void resampler_delete(void *);

enum
{
    RESAMPLER_QUALITY_MIN = 0,
    RESAMPLER_QUALITY_ZOH = 0,
    RESAMPLER_QUALITY_BLEP = 1,
    RESAMPLER_QUALITY_LINEAR = 2,
    RESAMPLER_QUALITY_CUBIC = 3,
    RESAMPLER_QUALITY_SINC = 4,
    RESAMPLER_QUALITY_MAX = 4
};

void resampler_set_quality(void *, int quality);

int resampler_get_free_count(void *);
void resampler_write_sample(void *, short sample);
void resampler_set_rate( void *, unsigned x, unsigned y);
void resampler_clear(void *);
int resampler_get_sample_count(void *);
int resampler_get_sample(void *);
void resampler_remove_sample(void *);

short resampler_get_and_remove_sample(void *_r);

#ifdef __cplusplus
}
#endif

#endif
