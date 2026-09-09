using System;
using System.Interop;

namespace miniaudio_Beef;

/// The HANDLE SURFACE over miniaudio, as declared in miniaudio_beef.h.
///
/// miniaudio's own API is config struct heavy: nearly every object is created by filling a
/// large nested configuration and handing it a caller allocated instance. Mirroring those
/// layouts here would mean tracking a dozen of them exactly, and any drift between the two
/// would be silent memory corruption rather than a compile error. So the C side owns every
/// allocation and only opaque pointers and scalars cross.
///
/// A result of nought is success, which is miniaudio's own convention.

/// The engine's mixer, its device, and its resource manager.
struct mab_engine;
/// One playing voice.
struct mab_sound;
/// A bus: a sound to miniaudio, and a node like any other.
struct mab_sound_group;
/// A standalone decoder, for probing and for the import transforms.
struct mab_decoder;
/// Anything that can be wired into the graph.
struct mab_node;
/// The bridge that lets a streamed voice page out of the engine's own file system.
struct mab_vfs;

/// The sample format, as miniaudio numbers them.
enum mab_format : uint32
{
	case Unknown = 0;
	case U8 = 1;
	case S16 = 2;
	case S24 = 3;
	case S32 = 4;
	case F32 = 5;
}

/// How a spatialised voice falls off with distance.
enum mab_attenuation : uint32
{
	case None = 0;
	case Inverse = 1;
	case Linear = 2;
	case Exponential = 3;
}

/// What a seek offset is measured from, as the bridge receives it.
enum mab_seek_origin : int32
{
	case Start = 0;
	case Current = 1;
	case End = 2;
}

static
{
	/// A voice DECODES AS IT PLAYS from its source rather than being held decoded.
	public const uint32 MAB_SOUND_FLAG_STREAM = 0x00000001;
	/// Decode the whole thing up front.
	public const uint32 MAB_SOUND_FLAG_DECODE = 0x00000002;
	/// Load on a worker rather than blocking the caller.
	public const uint32 MAB_SOUND_FLAG_ASYNC = 0x00000004;
	/// No resampler at all, which is cheaper for a voice that never changes pitch.
	public const uint32 MAB_SOUND_FLAG_NO_PITCH = 0x00000010;
	/// No spatialisation, for a voice that is always heard flat.
	public const uint32 MAB_SOUND_FLAG_NO_SPATIALIZATION = 0x00004000;
}

/// What the file system bridge answers with.
///
/// These are called from miniaudio's OWN JOB THREADS, which page a streamed voice in, so an
/// implementation must be safe to call from a thread it does not own. A handle is whatever
/// the open answers.
[CRepr]
struct mab_vfs_callbacks
{
	/// Null means the path is not there.
	public function void*(void* user, char8* path) OnOpen;
	public function void(void* user, void* file) OnClose;
	/// How many bytes were actually read; short means the end.
	public function uint(void* user, void* file, void* destination, uint bytes) OnRead;
	/// Nought on success.
	public function int32(void* user, void* file, int64 offset, int32 origin) OnSeek;
	/// The cursor, or negative on failure.
	public function int64(void* user, void* file) OnTell;
	/// The size in bytes, or negative when it is not known.
	public function int64(void* user, void* file) OnSize;

	public this() { this = default; }
}

/// One block of the custom node's processing, on the AUDIO THREAD.
///
/// The frames are interleaved at the engine's own channel count. It must neither allocate
/// nor block: everything else waiting on the mixer is waiting on this.
typealias mab_process_proc = function void(void* user, float* framesIn, float* framesOut,
	uint32 frameCount, uint32 channels);

static
{
	// ---- the file system bridge ----

	[CLink] public static extern mab_vfs* mab_vfs_create(mab_vfs_callbacks* callbacks, void* user);
	[CLink] public static extern void mab_vfs_destroy(mab_vfs* vfs);

	// ---- the engine ----

	/// A NO DEVICE engine plays nothing and is pumped by hand through the read below, which
	/// is what makes the mixer testable without an audio device at all.
	[CLink] public static extern mab_engine* mab_engine_create(mab_vfs* vfs, uint32 listenerCount,
		int32 noDevice, uint32 channels, uint32 sampleRate);
	[CLink] public static extern void mab_engine_destroy(mab_engine* engine);

	[CLink] public static extern uint32 mab_engine_get_channels(mab_engine* engine);
	[CLink] public static extern uint32 mab_engine_get_sample_rate(mab_engine* engine);
	[CLink] public static extern uint32 mab_engine_get_listener_count(mab_engine* engine);
	[CLink] public static extern void mab_engine_set_volume(mab_engine* engine, float volume);
	[CLink] public static extern int32 mab_engine_read_pcm_frames(mab_engine* engine,
		void* framesOut, uint64 frameCount, uint64* framesRead);

	/// The graph's endpoint, which is what a bus with no effects attaches to.
	[CLink] public static extern mab_node* mab_engine_get_endpoint(mab_engine* engine);

	[CLink] public static extern void mab_engine_listener_set_position(mab_engine* engine,
		uint32 index, float x, float y, float z);
	[CLink] public static extern void mab_engine_listener_set_direction(mab_engine* engine,
		uint32 index, float x, float y, float z);
	[CLink] public static extern void mab_engine_listener_set_world_up(mab_engine* engine,
		uint32 index, float x, float y, float z);
	[CLink] public static extern void mab_engine_listener_set_velocity(mab_engine* engine,
		uint32 index, float x, float y, float z);
	[CLink] public static extern void mab_engine_listener_set_enabled(mab_engine* engine,
		uint32 index, int32 enabled);

	/// The resource manager holds these BY REFERENCE, so the bytes must outlive every voice
	/// playing them.
	[CLink] public static extern int32 mab_register_encoded_data(mab_engine* engine, char8* name,
		void* data, uint sizeInBytes);
	[CLink] public static extern int32 mab_register_decoded_data(mab_engine* engine, char8* name,
		void* frames, uint64 frameCount, uint32 format, uint32 channels, uint32 sampleRate);

	// ---- sounds and groups ----

	[CLink] public static extern mab_sound* mab_sound_create_from_file(mab_engine* engine,
		char8* name, uint32 flags, mab_sound_group* group);
	[CLink] public static extern void mab_sound_destroy(mab_sound* sound);
	[CLink] public static extern mab_node* mab_sound_get_node(mab_sound* sound);

	[CLink] public static extern int32 mab_sound_start(mab_sound* sound);
	[CLink] public static extern int32 mab_sound_stop_with_fade_ms(mab_sound* sound,
		uint64 milliseconds);
	[CLink] public static extern void mab_sound_set_fade_in_ms(mab_sound* sound, float from,
		float to, uint64 milliseconds);
	[CLink] public static extern void mab_sound_reset_stop_time_and_fade(mab_sound* sound);

	[CLink] public static extern int32 mab_sound_is_playing(mab_sound* sound);
	[CLink] public static extern int32 mab_sound_at_end(mab_sound* sound);
	[CLink] public static extern int32 mab_sound_get_cursor_seconds(mab_sound* sound,
		float* cursor);

	[CLink] public static extern void mab_sound_set_volume(mab_sound* sound, float volume);
	[CLink] public static extern void mab_sound_set_pitch(mab_sound* sound, float pitch);
	[CLink] public static extern void mab_sound_set_pan(mab_sound* sound, float pan);
	[CLink] public static extern void mab_sound_set_looping(mab_sound* sound, int32 looping);
	[CLink] public static extern int32 mab_sound_set_loop_point_frames(mab_sound* sound,
		uint64 beginFrame, uint64 endFrame);

	[CLink] public static extern void mab_sound_set_spatialization_enabled(mab_sound* sound,
		int32 enabled);
	[CLink] public static extern void mab_sound_set_positioning_absolute(mab_sound* sound);
	[CLink] public static extern void mab_sound_set_position(mab_sound* sound, float x, float y,
		float z);
	[CLink] public static extern void mab_sound_set_velocity(mab_sound* sound, float x, float y,
		float z);
	[CLink] public static extern void mab_sound_set_attenuation_model(mab_sound* sound,
		uint32 model);
	[CLink] public static extern void mab_sound_set_min_distance(mab_sound* sound, float distance);
	[CLink] public static extern void mab_sound_set_max_distance(mab_sound* sound, float distance);
	[CLink] public static extern void mab_sound_set_rolloff(mab_sound* sound, float rolloff);
	[CLink] public static extern void mab_sound_set_doppler_factor(mab_sound* sound, float factor);
	[CLink] public static extern void mab_sound_set_cone(mab_sound* sound, float innerRadians,
		float outerRadians, float outerGain);

	[CLink] public static extern mab_sound_group* mab_sound_group_create(mab_engine* engine,
		uint32 flags, mab_node* parent);
	[CLink] public static extern void mab_sound_group_destroy(mab_sound_group* group);
	[CLink] public static extern mab_node* mab_sound_group_get_node(mab_sound_group* group);
	[CLink] public static extern void mab_sound_group_set_volume(mab_sound_group* group,
		float volume);
	[CLink] public static extern int32 mab_sound_group_start(mab_sound_group* group);
	[CLink] public static extern int32 mab_sound_group_stop(mab_sound_group* group);

	// ---- the node graph ----

	[CLink] public static extern int32 mab_node_attach_output_bus(mab_node* node, uint32 outputBus,
		mab_node* other, uint32 otherInputBus);
	[CLink] public static extern int32 mab_node_set_output_bus_volume(mab_node* node,
		uint32 outputBus, float volume);

	[CLink] public static extern mab_node* mab_lpf_node_create(mab_engine* engine, double cutoff,
		uint32 order);
	[CLink] public static extern int32 mab_lpf_node_set_cutoff(mab_node* node, mab_engine* engine,
		double cutoff, uint32 order);
	[CLink] public static extern void mab_lpf_node_destroy(mab_node* node);

	[CLink] public static extern mab_node* mab_hpf_node_create(mab_engine* engine, double cutoff,
		uint32 order);
	[CLink] public static extern void mab_hpf_node_destroy(mab_node* node);

	[CLink] public static extern mab_node* mab_delay_node_create(mab_engine* engine,
		uint32 delayFrames, float decay);
	[CLink] public static extern void mab_delay_node_destroy(mab_node* node);

	[CLink] public static extern mab_node* mab_splitter_node_create(mab_engine* engine);
	[CLink] public static extern void mab_splitter_node_destroy(mab_node* node);

	/// A node whose processing lives outside C, which is what carries a reverb written here.
	/// It processes CONTINUOUSLY, so a tail keeps ringing after its input stops.
	[CLink] public static extern mab_node* mab_custom_node_create(mab_engine* engine,
		mab_process_proc process, void* user);
	[CLink] public static extern void mab_custom_node_destroy(mab_node* node);

	// ---- decoding ----

	/// Channels and a rate of nought keep the source's own.
	[CLink] public static extern mab_decoder* mab_decoder_create_memory(void* data,
		uint sizeInBytes, uint32 format, uint32 channels, uint32 sampleRate);
	[CLink] public static extern void mab_decoder_destroy(mab_decoder* decoder);
	[CLink] public static extern uint32 mab_decoder_get_channels(mab_decoder* decoder);
	[CLink] public static extern uint32 mab_decoder_get_sample_rate(mab_decoder* decoder);
	[CLink] public static extern int32 mab_decoder_get_length_frames(mab_decoder* decoder,
		uint64* frameCount);
	[CLink] public static extern int32 mab_decoder_read_pcm_frames(mab_decoder* decoder,
		void* framesOut, uint64 frameCount, uint64* framesRead);

	/// miniaudio's own version, so a mismatch between this binding and the library it was
	/// generated against is visible rather than mysterious.
	[CLink] public static extern void mab_version(uint32* major, uint32* minor, uint32* revision);
}
