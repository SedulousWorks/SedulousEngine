/*
 * miniaudio-Beef - the handle surface's implementation. See miniaudio_beef.h for why this
 * exists at all rather than the binding calling miniaudio directly.
 */
#include "miniaudio/miniaudio.h"
#include "miniaudio_beef.h"

#include <stdlib.h>
#include <string.h>

/* ---------------------------------------------------------------------------------------- */
/* The virtual file system bridge.                                                            */
/* ---------------------------------------------------------------------------------------- */

/* miniaudio treats the first member as the callback table, so this IS an ma_vfs. */
struct mab_vfs
{
    ma_vfs_callbacks  callbacks;
    mab_vfs_callbacks user_callbacks;
    void*             user;
};

static ma_result mab_vfs_on_open(ma_vfs* vfs, const char* path, ma_uint32 openMode,
                                 ma_vfs_file* file)
{
    struct mab_vfs* self = (struct mab_vfs*)vfs;
    void* handle;

    /* Read only: the engine never writes through the bridge. */
    if ((openMode & MA_OPEN_MODE_WRITE) != 0) {
        return MA_INVALID_OPERATION;
    }
    if (self == NULL || self->user_callbacks.onOpen == NULL) {
        return MA_INVALID_ARGS;
    }

    handle = self->user_callbacks.onOpen(self->user, path);
    if (handle == NULL) {
        return MA_DOES_NOT_EXIST;
    }
    *file = (ma_vfs_file)handle;
    return MA_SUCCESS;
}

static ma_result mab_vfs_on_open_w(ma_vfs* vfs, const wchar_t* path, ma_uint32 openMode,
                                   ma_vfs_file* file)
{
    (void)vfs; (void)path; (void)openMode; (void)file;
    /* The engine names everything in UTF-8, so the wide path is never taken. */
    return MA_INVALID_OPERATION;
}

static ma_result mab_vfs_on_close(ma_vfs* vfs, ma_vfs_file file)
{
    struct mab_vfs* self = (struct mab_vfs*)vfs;
    if (self == NULL || self->user_callbacks.onClose == NULL) {
        return MA_INVALID_ARGS;
    }
    self->user_callbacks.onClose(self->user, (void*)file);
    return MA_SUCCESS;
}

static ma_result mab_vfs_on_read(ma_vfs* vfs, ma_vfs_file file, void* destination,
                                 size_t sizeInBytes, size_t* bytesRead)
{
    struct mab_vfs* self = (struct mab_vfs*)vfs;
    size_t read;

    if (self == NULL || self->user_callbacks.onRead == NULL) {
        return MA_INVALID_ARGS;
    }
    read = self->user_callbacks.onRead(self->user, (void*)file, destination, sizeInBytes);
    if (bytesRead != NULL) {
        *bytesRead = read;
    }
    /* A short read is the end of the stream, which miniaudio wants told apart from success. */
    return (read < sizeInBytes) ? MA_AT_END : MA_SUCCESS;
}

static ma_result mab_vfs_on_write(ma_vfs* vfs, ma_vfs_file file, const void* source,
                                  size_t sizeInBytes, size_t* bytesWritten)
{
    (void)vfs; (void)file; (void)source; (void)sizeInBytes; (void)bytesWritten;
    return MA_INVALID_OPERATION;
}

static ma_result mab_vfs_on_seek(ma_vfs* vfs, ma_vfs_file file, ma_int64 offset,
                                 ma_seek_origin origin)
{
    struct mab_vfs* self = (struct mab_vfs*)vfs;
    if (self == NULL || self->user_callbacks.onSeek == NULL) {
        return MA_INVALID_ARGS;
    }
    return self->user_callbacks.onSeek(self->user, (void*)file, offset, (int32_t)origin) == 0
               ? MA_SUCCESS
               : MA_ERROR;
}

static ma_result mab_vfs_on_tell(ma_vfs* vfs, ma_vfs_file file, ma_int64* cursor)
{
    struct mab_vfs* self = (struct mab_vfs*)vfs;
    int64_t position;

    if (self == NULL || self->user_callbacks.onTell == NULL || cursor == NULL) {
        return MA_INVALID_ARGS;
    }
    position = self->user_callbacks.onTell(self->user, (void*)file);
    if (position < 0) {
        return MA_ERROR;
    }
    *cursor = (ma_int64)position;
    return MA_SUCCESS;
}

static ma_result mab_vfs_on_info(ma_vfs* vfs, ma_vfs_file file, ma_file_info* info)
{
    struct mab_vfs* self = (struct mab_vfs*)vfs;
    int64_t size;

    if (self == NULL || self->user_callbacks.onSize == NULL || info == NULL) {
        return MA_INVALID_ARGS;
    }
    size = self->user_callbacks.onSize(self->user, (void*)file);
    if (size < 0) {
        return MA_ERROR;
    }
    info->sizeInBytes = (ma_uint64)size;
    return MA_SUCCESS;
}

mab_vfs* mab_vfs_create(const mab_vfs_callbacks* callbacks, void* user)
{
    struct mab_vfs* self;

    if (callbacks == NULL) {
        return NULL;
    }
    self = (struct mab_vfs*)calloc(1, sizeof(struct mab_vfs));
    if (self == NULL) {
        return NULL;
    }

    self->user_callbacks = *callbacks;
    self->user = user;
    self->callbacks.onOpen  = mab_vfs_on_open;
    self->callbacks.onOpenW = mab_vfs_on_open_w;
    self->callbacks.onClose = mab_vfs_on_close;
    self->callbacks.onRead  = mab_vfs_on_read;
    self->callbacks.onWrite = mab_vfs_on_write;
    self->callbacks.onSeek  = mab_vfs_on_seek;
    self->callbacks.onTell  = mab_vfs_on_tell;
    self->callbacks.onInfo  = mab_vfs_on_info;
    return self;
}

void mab_vfs_destroy(mab_vfs* vfs)
{
    free(vfs);
}

/* ---------------------------------------------------------------------------------------- */
/* The engine.                                                                                */
/* ---------------------------------------------------------------------------------------- */

mab_engine* mab_engine_create(mab_vfs* vfs, uint32_t listenerCount, int32_t noDevice,
                              uint32_t channels, uint32_t sampleRate)
{
    ma_engine* engine;
    ma_engine_config config = ma_engine_config_init();

    config.pResourceManagerVFS = (ma_vfs*)vfs;
    if (listenerCount > 0) {
        config.listenerCount = listenerCount;
    }
    if (noDevice != 0) {
        config.noDevice   = MA_TRUE;
        config.channels   = (channels   != 0) ? channels   : 2;
        config.sampleRate = (sampleRate != 0) ? sampleRate : 48000;
    }

    engine = (ma_engine*)calloc(1, sizeof(ma_engine));
    if (engine == NULL) {
        return NULL;
    }
    if (ma_engine_init(&config, engine) != MA_SUCCESS) {
        free(engine);
        return NULL;
    }
    return (mab_engine*)engine;
}

void mab_engine_destroy(mab_engine* engine)
{
    if (engine == NULL) {
        return;
    }
    ma_engine_uninit((ma_engine*)engine);
    free(engine);
}

uint32_t mab_engine_get_channels(mab_engine* engine)
{
    return (engine != NULL) ? ma_engine_get_channels((ma_engine*)engine) : 0;
}

uint32_t mab_engine_get_sample_rate(mab_engine* engine)
{
    return (engine != NULL) ? ma_engine_get_sample_rate((ma_engine*)engine) : 0;
}

uint32_t mab_engine_get_listener_count(mab_engine* engine)
{
    return (engine != NULL) ? ma_engine_get_listener_count((ma_engine*)engine) : 0;
}

void mab_engine_set_volume(mab_engine* engine, float volume)
{
    if (engine != NULL) {
        ma_engine_set_volume((ma_engine*)engine, volume);
    }
}

int32_t mab_engine_read_pcm_frames(mab_engine* engine, void* framesOut, uint64_t frameCount,
                                   uint64_t* framesRead)
{
    if (engine == NULL) {
        return MA_INVALID_ARGS;
    }
    return (int32_t)ma_engine_read_pcm_frames((ma_engine*)engine, framesOut, frameCount,
                                              (ma_uint64*)framesRead);
}

mab_node* mab_engine_get_endpoint(mab_engine* engine)
{
    if (engine == NULL) {
        return NULL;
    }
    return (mab_node*)ma_node_graph_get_endpoint(ma_engine_get_node_graph((ma_engine*)engine));
}

void mab_engine_listener_set_position(mab_engine* engine, uint32_t index, float x, float y, float z)
{
    ma_engine_listener_set_position((ma_engine*)engine, index, x, y, z);
}

void mab_engine_listener_set_direction(mab_engine* engine, uint32_t index, float x, float y, float z)
{
    ma_engine_listener_set_direction((ma_engine*)engine, index, x, y, z);
}

void mab_engine_listener_set_world_up(mab_engine* engine, uint32_t index, float x, float y, float z)
{
    ma_engine_listener_set_world_up((ma_engine*)engine, index, x, y, z);
}

void mab_engine_listener_set_velocity(mab_engine* engine, uint32_t index, float x, float y, float z)
{
    ma_engine_listener_set_velocity((ma_engine*)engine, index, x, y, z);
}

void mab_engine_listener_set_enabled(mab_engine* engine, uint32_t index, int32_t enabled)
{
    ma_engine_listener_set_enabled((ma_engine*)engine, index, enabled ? MA_TRUE : MA_FALSE);
}

int32_t mab_register_encoded_data(mab_engine* engine, const char* name, const void* data,
                                  size_t sizeInBytes)
{
    if (engine == NULL) {
        return MA_INVALID_ARGS;
    }
    return (int32_t)ma_resource_manager_register_encoded_data(
        ma_engine_get_resource_manager((ma_engine*)engine), name, data, sizeInBytes);
}

int32_t mab_register_decoded_data(mab_engine* engine, const char* name, const void* frames,
                                  uint64_t frameCount, uint32_t format, uint32_t channels,
                                  uint32_t sampleRate)
{
    if (engine == NULL) {
        return MA_INVALID_ARGS;
    }
    return (int32_t)ma_resource_manager_register_decoded_data(
        ma_engine_get_resource_manager((ma_engine*)engine), name, frames, frameCount,
        (ma_format)format, channels, sampleRate);
}

/* ---------------------------------------------------------------------------------------- */
/* Sounds and groups.                                                                         */
/* ---------------------------------------------------------------------------------------- */

mab_sound* mab_sound_create_from_file(mab_engine* engine, const char* name, uint32_t flags,
                                      mab_sound_group* group)
{
    ma_sound* sound;

    if (engine == NULL) {
        return NULL;
    }
    sound = (ma_sound*)calloc(1, sizeof(ma_sound));
    if (sound == NULL) {
        return NULL;
    }
    if (ma_sound_init_from_file((ma_engine*)engine, name, flags, (ma_sound_group*)group, NULL,
                                sound) != MA_SUCCESS) {
        free(sound);
        return NULL;
    }
    return (mab_sound*)sound;
}

void mab_sound_destroy(mab_sound* sound)
{
    if (sound == NULL) {
        return;
    }
    ma_sound_uninit((ma_sound*)sound);
    free(sound);
}

mab_node* mab_sound_get_node(mab_sound* sound)
{
    return (mab_node*)sound;
}

int32_t mab_sound_start(mab_sound* sound)
{
    return (int32_t)ma_sound_start((ma_sound*)sound);
}

int32_t mab_sound_stop_with_fade_ms(mab_sound* sound, uint64_t milliseconds)
{
    return (int32_t)ma_sound_stop_with_fade_in_milliseconds((ma_sound*)sound, milliseconds);
}

void mab_sound_set_fade_in_ms(mab_sound* sound, float from, float to, uint64_t milliseconds)
{
    ma_sound_set_fade_in_milliseconds((ma_sound*)sound, from, to, milliseconds);
}

void mab_sound_reset_stop_time_and_fade(mab_sound* sound)
{
    ma_sound_reset_stop_time_and_fade((ma_sound*)sound);
}

int32_t mab_sound_is_playing(mab_sound* sound)
{
    return (sound != NULL && ma_sound_is_playing((ma_sound*)sound) == MA_TRUE) ? 1 : 0;
}

int32_t mab_sound_at_end(mab_sound* sound)
{
    return (sound != NULL && ma_sound_at_end((ma_sound*)sound) == MA_TRUE) ? 1 : 0;
}

int32_t mab_sound_get_cursor_seconds(mab_sound* sound, float* cursor)
{
    return (int32_t)ma_sound_get_cursor_in_seconds((ma_sound*)sound, cursor);
}

void mab_sound_set_volume(mab_sound* sound, float volume)
{
    ma_sound_set_volume((ma_sound*)sound, volume);
}

void mab_sound_set_pitch(mab_sound* sound, float pitch)
{
    ma_sound_set_pitch((ma_sound*)sound, pitch);
}

void mab_sound_set_pan(mab_sound* sound, float pan)
{
    ma_sound_set_pan((ma_sound*)sound, pan);
}

void mab_sound_set_looping(mab_sound* sound, int32_t looping)
{
    ma_sound_set_looping((ma_sound*)sound, looping ? MA_TRUE : MA_FALSE);
}

int32_t mab_sound_set_loop_point_frames(mab_sound* sound, uint64_t beginFrame, uint64_t endFrame)
{
    ma_data_source* source = ma_sound_get_data_source((ma_sound*)sound);
    if (source == NULL) {
        return MA_INVALID_ARGS;
    }
    return (int32_t)ma_data_source_set_loop_point_in_pcm_frames(source, beginFrame, endFrame);
}

void mab_sound_set_spatialization_enabled(mab_sound* sound, int32_t enabled)
{
    ma_sound_set_spatialization_enabled((ma_sound*)sound, enabled ? MA_TRUE : MA_FALSE);
}

void mab_sound_set_positioning_absolute(mab_sound* sound)
{
    ma_sound_set_positioning((ma_sound*)sound, ma_positioning_absolute);
}

void mab_sound_set_position(mab_sound* sound, float x, float y, float z)
{
    ma_sound_set_position((ma_sound*)sound, x, y, z);
}

void mab_sound_set_velocity(mab_sound* sound, float x, float y, float z)
{
    ma_sound_set_velocity((ma_sound*)sound, x, y, z);
}

void mab_sound_set_attenuation_model(mab_sound* sound, uint32_t model)
{
    ma_sound_set_attenuation_model((ma_sound*)sound, (ma_attenuation_model)model);
}

void mab_sound_set_min_distance(mab_sound* sound, float distance)
{
    ma_sound_set_min_distance((ma_sound*)sound, distance);
}

void mab_sound_set_max_distance(mab_sound* sound, float distance)
{
    ma_sound_set_max_distance((ma_sound*)sound, distance);
}

void mab_sound_set_rolloff(mab_sound* sound, float rolloff)
{
    ma_sound_set_rolloff((ma_sound*)sound, rolloff);
}

void mab_sound_set_doppler_factor(mab_sound* sound, float factor)
{
    ma_sound_set_doppler_factor((ma_sound*)sound, factor);
}

void mab_sound_set_cone(mab_sound* sound, float innerRadians, float outerRadians, float outerGain)
{
    ma_sound_set_cone((ma_sound*)sound, innerRadians, outerRadians, outerGain);
}

mab_sound_group* mab_sound_group_create(mab_engine* engine, uint32_t flags, mab_node* parent)
{
    ma_sound_group* group;

    if (engine == NULL) {
        return NULL;
    }
    group = (ma_sound_group*)calloc(1, sizeof(ma_sound_group));
    if (group == NULL) {
        return NULL;
    }
    if (ma_sound_group_init((ma_engine*)engine, flags, (ma_sound_group*)parent, group)
        != MA_SUCCESS) {
        free(group);
        return NULL;
    }
    return (mab_sound_group*)group;
}

void mab_sound_group_destroy(mab_sound_group* group)
{
    if (group == NULL) {
        return;
    }
    ma_sound_group_uninit((ma_sound_group*)group);
    free(group);
}

mab_node* mab_sound_group_get_node(mab_sound_group* group)
{
    return (mab_node*)group;
}

void mab_sound_group_set_volume(mab_sound_group* group, float volume)
{
    ma_sound_group_set_volume((ma_sound_group*)group, volume);
}

int32_t mab_sound_group_start(mab_sound_group* group)
{
    return (int32_t)ma_sound_group_start((ma_sound_group*)group);
}

int32_t mab_sound_group_stop(mab_sound_group* group)
{
    return (int32_t)ma_sound_group_stop((ma_sound_group*)group);
}

/* ---------------------------------------------------------------------------------------- */
/* The node graph.                                                                            */
/* ---------------------------------------------------------------------------------------- */

int32_t mab_node_attach_output_bus(mab_node* node, uint32_t outputBus, mab_node* other,
                                   uint32_t otherInputBus)
{
    return (int32_t)ma_node_attach_output_bus((ma_node*)node, outputBus, (ma_node*)other,
                                              otherInputBus);
}

int32_t mab_node_set_output_bus_volume(mab_node* node, uint32_t outputBus, float volume)
{
    return (int32_t)ma_node_set_output_bus_volume((ma_node*)node, outputBus, volume);
}

mab_node* mab_lpf_node_create(mab_engine* engine, double cutoff, uint32_t order)
{
    ma_lpf_node* node;
    ma_lpf_node_config config;

    if (engine == NULL) {
        return NULL;
    }
    config = ma_lpf_node_config_init(ma_engine_get_channels((ma_engine*)engine),
                                     ma_engine_get_sample_rate((ma_engine*)engine), cutoff, order);
    node = (ma_lpf_node*)calloc(1, sizeof(ma_lpf_node));
    if (node == NULL) {
        return NULL;
    }
    if (ma_lpf_node_init(ma_engine_get_node_graph((ma_engine*)engine), &config, NULL, node)
        != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return (mab_node*)node;
}

int32_t mab_lpf_node_set_cutoff(mab_node* node, mab_engine* engine, double cutoff, uint32_t order)
{
    ma_lpf_config config;

    if (node == NULL || engine == NULL) {
        return MA_INVALID_ARGS;
    }
    config = ma_lpf_config_init(ma_format_f32, ma_engine_get_channels((ma_engine*)engine),
                                ma_engine_get_sample_rate((ma_engine*)engine), cutoff, order);
    return (int32_t)ma_lpf_node_reinit(&config, (ma_lpf_node*)node);
}

void mab_lpf_node_destroy(mab_node* node)
{
    if (node == NULL) {
        return;
    }
    ma_lpf_node_uninit((ma_lpf_node*)node, NULL);
    free(node);
}

mab_node* mab_hpf_node_create(mab_engine* engine, double cutoff, uint32_t order)
{
    ma_hpf_node* node;
    ma_hpf_node_config config;

    if (engine == NULL) {
        return NULL;
    }
    config = ma_hpf_node_config_init(ma_engine_get_channels((ma_engine*)engine),
                                     ma_engine_get_sample_rate((ma_engine*)engine), cutoff, order);
    node = (ma_hpf_node*)calloc(1, sizeof(ma_hpf_node));
    if (node == NULL) {
        return NULL;
    }
    if (ma_hpf_node_init(ma_engine_get_node_graph((ma_engine*)engine), &config, NULL, node)
        != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return (mab_node*)node;
}

void mab_hpf_node_destroy(mab_node* node)
{
    if (node == NULL) {
        return;
    }
    ma_hpf_node_uninit((ma_hpf_node*)node, NULL);
    free(node);
}

mab_node* mab_delay_node_create(mab_engine* engine, uint32_t delayFrames, float decay)
{
    ma_delay_node* node;
    ma_delay_node_config config;

    if (engine == NULL) {
        return NULL;
    }
    config = ma_delay_node_config_init(ma_engine_get_channels((ma_engine*)engine),
                                       ma_engine_get_sample_rate((ma_engine*)engine), delayFrames,
                                       decay);
    node = (ma_delay_node*)calloc(1, sizeof(ma_delay_node));
    if (node == NULL) {
        return NULL;
    }
    if (ma_delay_node_init(ma_engine_get_node_graph((ma_engine*)engine), &config, NULL, node)
        != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return (mab_node*)node;
}

void mab_delay_node_destroy(mab_node* node)
{
    if (node == NULL) {
        return;
    }
    ma_delay_node_uninit((ma_delay_node*)node, NULL);
    free(node);
}

mab_node* mab_splitter_node_create(mab_engine* engine)
{
    ma_splitter_node* node;
    ma_splitter_node_config config;

    if (engine == NULL) {
        return NULL;
    }
    config = ma_splitter_node_config_init(ma_engine_get_channels((ma_engine*)engine));
    node = (ma_splitter_node*)calloc(1, sizeof(ma_splitter_node));
    if (node == NULL) {
        return NULL;
    }
    if (ma_splitter_node_init(ma_engine_get_node_graph((ma_engine*)engine), &config, NULL, node)
        != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return (mab_node*)node;
}

void mab_splitter_node_destroy(mab_node* node)
{
    if (node == NULL) {
        return;
    }
    ma_splitter_node_uninit((ma_splitter_node*)node, NULL);
    free(node);
}

/* ---------------------------------------------------------------------------------------- */
/* The custom processing node.                                                                */
/* ---------------------------------------------------------------------------------------- */

typedef struct mab_custom_node
{
    ma_node_base     base; /* FIRST, so a mab_custom_node* is a valid ma_node*. */
    mab_process_proc process;
    void*            user;
    ma_uint32        channels;
} mab_custom_node;

static void mab_custom_node_process(ma_node* node, const float** framesIn, ma_uint32* frameCountIn,
                                    float** framesOut, ma_uint32* frameCountOut)
{
    mab_custom_node* self = (mab_custom_node*)node;
    ma_uint32 frames = (*frameCountOut < *frameCountIn) ? *frameCountOut : *frameCountIn;

    if (self->process != NULL) {
        self->process(self->user, framesIn[0], framesOut[0], frames, self->channels);
    } else {
        memcpy(framesOut[0], framesIn[0], (size_t)frames * self->channels * sizeof(float));
    }

    *frameCountIn  = frames;
    *frameCountOut = frames;
}

/* CONTINUOUS processing, so a tail keeps ringing after its input stops. */
static ma_node_vtable mab_custom_node_vtable = {
    mab_custom_node_process, NULL, 1, 1, MA_NODE_FLAG_CONTINUOUS_PROCESSING
};

mab_node* mab_custom_node_create(mab_engine* engine, mab_process_proc process, void* user)
{
    mab_custom_node* node;
    ma_node_config config;
    ma_uint32 channels[1];

    if (engine == NULL) {
        return NULL;
    }
    node = (mab_custom_node*)calloc(1, sizeof(mab_custom_node));
    if (node == NULL) {
        return NULL;
    }

    node->process  = process;
    node->user     = user;
    node->channels = ma_engine_get_channels((ma_engine*)engine);
    channels[0]    = node->channels;

    config = ma_node_config_init();
    config.vtable          = &mab_custom_node_vtable;
    config.pInputChannels  = channels;
    config.pOutputChannels = channels;

    if (ma_node_init(ma_engine_get_node_graph((ma_engine*)engine), &config, NULL, &node->base)
        != MA_SUCCESS) {
        free(node);
        return NULL;
    }
    return (mab_node*)node;
}

void mab_custom_node_destroy(mab_node* node)
{
    if (node == NULL) {
        return;
    }
    ma_node_uninit(&((mab_custom_node*)node)->base, NULL);
    free(node);
}

/* ---------------------------------------------------------------------------------------- */
/* Decoding.                                                                                  */
/* ---------------------------------------------------------------------------------------- */

mab_decoder* mab_decoder_create_memory(const void* data, size_t sizeInBytes, uint32_t format,
                                       uint32_t channels, uint32_t sampleRate)
{
    ma_decoder* decoder;
    ma_decoder_config config = ma_decoder_config_init((ma_format)format, channels, sampleRate);

    decoder = (ma_decoder*)calloc(1, sizeof(ma_decoder));
    if (decoder == NULL) {
        return NULL;
    }
    if (ma_decoder_init_memory(data, sizeInBytes, &config, decoder) != MA_SUCCESS) {
        free(decoder);
        return NULL;
    }
    return (mab_decoder*)decoder;
}

void mab_decoder_destroy(mab_decoder* decoder)
{
    if (decoder == NULL) {
        return;
    }
    ma_decoder_uninit((ma_decoder*)decoder);
    free(decoder);
}

uint32_t mab_decoder_get_channels(mab_decoder* decoder)
{
    return (decoder != NULL) ? ((ma_decoder*)decoder)->outputChannels : 0;
}

uint32_t mab_decoder_get_sample_rate(mab_decoder* decoder)
{
    return (decoder != NULL) ? ((ma_decoder*)decoder)->outputSampleRate : 0;
}

int32_t mab_decoder_get_length_frames(mab_decoder* decoder, uint64_t* frameCount)
{
    return (int32_t)ma_decoder_get_length_in_pcm_frames((ma_decoder*)decoder,
                                                        (ma_uint64*)frameCount);
}

int32_t mab_decoder_read_pcm_frames(mab_decoder* decoder, void* framesOut, uint64_t frameCount,
                                    uint64_t* framesRead)
{
    return (int32_t)ma_decoder_read_pcm_frames((ma_decoder*)decoder, framesOut, frameCount,
                                               (ma_uint64*)framesRead);
}

void mab_version(uint32_t* major, uint32_t* minor, uint32_t* revision)
{
    ma_version(major, minor, revision);
}
