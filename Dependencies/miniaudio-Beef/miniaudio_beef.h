/*
 * miniaudio-Beef - the C surface the Beef binding calls.
 *
 * miniaudio's own API is config-struct heavy: almost every object is created by filling a
 * large nested `*_config` and passing a caller-allocated instance. Mirroring those structs
 * in Beef would mean tracking the exact layout of a dozen of them, and any drift between
 * the two would be silent memory corruption rather than a compile error.
 *
 * So this is a HANDLE SURFACE, the same shape joltc gives Jolt: every object is created and
 * destroyed here, nothing but opaque pointers and scalars crosses the boundary, and the
 * config filling stays in C next to the header that defines it. The set of functions is
 * exactly what the engine needs, and no more.
 *
 * Result codes are miniaudio's own: nought is success.
 */
#ifndef MINIAUDIO_BEEF_H
#define MINIAUDIO_BEEF_H

#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct mab_engine mab_engine;
typedef struct mab_sound mab_sound;
typedef struct mab_sound_group mab_sound_group;
typedef struct mab_decoder mab_decoder;
typedef struct mab_node mab_node;
typedef struct mab_vfs mab_vfs;

/* miniaudio's ma_format, spelled out so the binding does not have to guess. */
#define MAB_FORMAT_UNKNOWN 0
#define MAB_FORMAT_U8      1
#define MAB_FORMAT_S16     2
#define MAB_FORMAT_S24     3
#define MAB_FORMAT_S32     4
#define MAB_FORMAT_F32     5

/* miniaudio's ma_attenuation_model. */
#define MAB_ATTENUATION_NONE        0
#define MAB_ATTENUATION_INVERSE     1
#define MAB_ATTENUATION_LINEAR      2
#define MAB_ATTENUATION_EXPONENTIAL 3

/* miniaudio's ma_seek_origin, as the virtual file system callbacks receive it. */
#define MAB_SEEK_START   0
#define MAB_SEEK_CURRENT 1
#define MAB_SEEK_END     2

/* ma_sound flags the engine passes when creating a voice. */
#define MAB_SOUND_FLAG_STREAM             0x00000001
#define MAB_SOUND_FLAG_DECODE             0x00000002
#define MAB_SOUND_FLAG_ASYNC              0x00000004
#define MAB_SOUND_FLAG_NO_PITCH           0x00000010
#define MAB_SOUND_FLAG_NO_SPATIALIZATION  0x00004000

/* -------------------------------------------------------------------------------------- */
/* The virtual file system bridge.                                                         */
/*                                                                                          */
/* miniaudio pages a streamed voice in on its own job threads, so these are called from     */
/* threads the caller does not own. A handle is whatever the implementer returns from open. */
/* -------------------------------------------------------------------------------------- */
typedef struct mab_vfs_callbacks
{
    void*   (*onOpen) (void* user, const char* path);
    void    (*onClose)(void* user, void* file);
    /* Answers how many bytes were actually read; short means the end. */
    size_t  (*onRead) (void* user, void* file, void* destination, size_t bytes);
    /* Nought on success. */
    int32_t (*onSeek) (void* user, void* file, int64_t offset, int32_t origin);
    /* The cursor, or negative on failure. */
    int64_t (*onTell) (void* user, void* file);
    /* The size in bytes, or negative when it is not known. */
    int64_t (*onSize) (void* user, void* file);
} mab_vfs_callbacks;

mab_vfs* mab_vfs_create(const mab_vfs_callbacks* callbacks, void* user);
void     mab_vfs_destroy(mab_vfs* vfs);

/* -------------------------------------------------------------------------------------- */
/* The engine.                                                                              */
/* -------------------------------------------------------------------------------------- */

/* `noDevice` opens the engine HEADLESS: nothing is played, and the caller pumps it by hand
 * through mab_engine_read_pcm_frames. That is what makes the mixer testable. */
mab_engine* mab_engine_create(mab_vfs* vfs, uint32_t listenerCount, int32_t noDevice,
                              uint32_t channels, uint32_t sampleRate);
void        mab_engine_destroy(mab_engine* engine);

uint32_t mab_engine_get_channels(mab_engine* engine);
uint32_t mab_engine_get_sample_rate(mab_engine* engine);
uint32_t mab_engine_get_listener_count(mab_engine* engine);
void     mab_engine_set_volume(mab_engine* engine, float volume);
int32_t  mab_engine_read_pcm_frames(mab_engine* engine, void* framesOut, uint64_t frameCount,
                                    uint64_t* framesRead);

/* The graph's endpoint, which is what a bus with no effects attaches to. */
mab_node* mab_engine_get_endpoint(mab_engine* engine);

void mab_engine_listener_set_position(mab_engine* engine, uint32_t index, float x, float y, float z);
void mab_engine_listener_set_direction(mab_engine* engine, uint32_t index, float x, float y, float z);
void mab_engine_listener_set_world_up(mab_engine* engine, uint32_t index, float x, float y, float z);
void mab_engine_listener_set_velocity(mab_engine* engine, uint32_t index, float x, float y, float z);
void mab_engine_listener_set_enabled(mab_engine* engine, uint32_t index, int32_t enabled);

/* The resource manager holds these by REFERENCE, so the bytes must outlive every voice
 * playing them. */
int32_t mab_register_encoded_data(mab_engine* engine, const char* name, const void* data,
                                  size_t sizeInBytes);
int32_t mab_register_decoded_data(mab_engine* engine, const char* name, const void* frames,
                                  uint64_t frameCount, uint32_t format, uint32_t channels,
                                  uint32_t sampleRate);

/* -------------------------------------------------------------------------------------- */
/* Sounds and groups. A group IS a sound to miniaudio, and both are valid nodes.            */
/* -------------------------------------------------------------------------------------- */

mab_sound* mab_sound_create_from_file(mab_engine* engine, const char* name, uint32_t flags,
                                      mab_sound_group* group);
void       mab_sound_destroy(mab_sound* sound);
mab_node*  mab_sound_get_node(mab_sound* sound);

int32_t mab_sound_start(mab_sound* sound);
int32_t mab_sound_stop_with_fade_ms(mab_sound* sound, uint64_t milliseconds);
void    mab_sound_set_fade_in_ms(mab_sound* sound, float from, float to, uint64_t milliseconds);
void    mab_sound_reset_stop_time_and_fade(mab_sound* sound);

int32_t mab_sound_is_playing(mab_sound* sound);
int32_t mab_sound_at_end(mab_sound* sound);
int32_t mab_sound_get_cursor_seconds(mab_sound* sound, float* cursor);

void mab_sound_set_volume(mab_sound* sound, float volume);
void mab_sound_set_pitch(mab_sound* sound, float pitch);
void mab_sound_set_pan(mab_sound* sound, float pan);
void mab_sound_set_looping(mab_sound* sound, int32_t looping);
int32_t mab_sound_set_loop_point_frames(mab_sound* sound, uint64_t beginFrame, uint64_t endFrame);

void mab_sound_set_spatialization_enabled(mab_sound* sound, int32_t enabled);
void mab_sound_set_positioning_absolute(mab_sound* sound);
void mab_sound_set_position(mab_sound* sound, float x, float y, float z);
void mab_sound_set_velocity(mab_sound* sound, float x, float y, float z);
void mab_sound_set_attenuation_model(mab_sound* sound, uint32_t model);
void mab_sound_set_min_distance(mab_sound* sound, float distance);
void mab_sound_set_max_distance(mab_sound* sound, float distance);
void mab_sound_set_rolloff(mab_sound* sound, float rolloff);
void mab_sound_set_doppler_factor(mab_sound* sound, float factor);
void mab_sound_set_cone(mab_sound* sound, float innerRadians, float outerRadians, float outerGain);

mab_sound_group* mab_sound_group_create(mab_engine* engine, uint32_t flags, mab_node* parent);
void             mab_sound_group_destroy(mab_sound_group* group);
mab_node*        mab_sound_group_get_node(mab_sound_group* group);
void             mab_sound_group_set_volume(mab_sound_group* group, float volume);
int32_t          mab_sound_group_start(mab_sound_group* group);
int32_t          mab_sound_group_stop(mab_sound_group* group);
/* A group is a sound: the same fade-then-stop declick applies, and halting the group node
   freezes every voice routed through it in place. */
int32_t          mab_sound_group_stop_with_fade_ms(mab_sound_group* group, uint64_t milliseconds);
void             mab_sound_group_set_fade_in_ms(mab_sound_group* group, float from, float to,
                                                uint64_t milliseconds);
void             mab_sound_group_reset_stop_time_and_fade(mab_sound_group* group);

/* -------------------------------------------------------------------------------------- */
/* The node graph.                                                                          */
/* -------------------------------------------------------------------------------------- */

int32_t mab_node_attach_output_bus(mab_node* node, uint32_t outputBus, mab_node* other,
                                   uint32_t otherInputBus);
int32_t mab_node_set_output_bus_volume(mab_node* node, uint32_t outputBus, float volume);

/* The built in effect nodes. Each is created against the engine, so it inherits the mixer's
 * channel count and rate. */
mab_node* mab_lpf_node_create(mab_engine* engine, double cutoff, uint32_t order);
int32_t   mab_lpf_node_set_cutoff(mab_node* node, mab_engine* engine, double cutoff,
                                  uint32_t order);
void      mab_lpf_node_destroy(mab_node* node);

mab_node* mab_hpf_node_create(mab_engine* engine, double cutoff, uint32_t order);
void      mab_hpf_node_destroy(mab_node* node);

mab_node* mab_delay_node_create(mab_engine* engine, uint32_t delayFrames, float decay);
void      mab_delay_node_destroy(mab_node* node);

mab_node* mab_splitter_node_create(mab_engine* engine);
void      mab_splitter_node_destroy(mab_node* node);

/* -------------------------------------------------------------------------------------- */
/* A custom processing node, which is what carries a reverb whose maths lives outside C.    */
/*                                                                                          */
/* The callback runs on the AUDIO THREAD, on interleaved frames of the engine's channel     */
/* count, and must neither allocate nor block. It processes CONTINUOUSLY, so a tail keeps   */
/* ringing after its input stops.                                                           */
/* -------------------------------------------------------------------------------------- */
typedef void (*mab_process_proc)(void* user, const float* framesIn, float* framesOut,
                                 uint32_t frameCount, uint32_t channels);

mab_node* mab_custom_node_create(mab_engine* engine, mab_process_proc process, void* user);
void      mab_custom_node_destroy(mab_node* node);

/* -------------------------------------------------------------------------------------- */
/* Decoding, for probing a clip and for the import transforms.                              */
/* -------------------------------------------------------------------------------------- */

/* `channels` and `sampleRate` of nought keep the source's own. */
mab_decoder* mab_decoder_create_memory(const void* data, size_t sizeInBytes, uint32_t format,
                                       uint32_t channels, uint32_t sampleRate);
void         mab_decoder_destroy(mab_decoder* decoder);
uint32_t     mab_decoder_get_channels(mab_decoder* decoder);
uint32_t     mab_decoder_get_sample_rate(mab_decoder* decoder);
int32_t      mab_decoder_get_length_frames(mab_decoder* decoder, uint64_t* frameCount);
int32_t      mab_decoder_read_pcm_frames(mab_decoder* decoder, void* framesOut, uint64_t frameCount,
                                         uint64_t* framesRead);

/* miniaudio's own version, so a binding mismatch is visible rather than mysterious. */
void mab_version(uint32_t* major, uint32_t* minor, uint32_t* revision);

#if defined(__cplusplus)
}
#endif

#endif /* MINIAUDIO_BEEF_H */
