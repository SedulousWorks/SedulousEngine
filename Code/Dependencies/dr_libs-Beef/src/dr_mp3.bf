using System;
using System.Interop;
namespace dr_libs_Beef;

/*
MP3 audio decoder. Choice of public domain or MIT-0. See license statements at the end of this file.
dr_mp3 - v0.7.3 - TBD

David Reid - mackron@gmail.com

GitHub: https://github.com/mackron/dr_libs

Based on minimp3 (https://github.com/lieff/minimp3) which is where the real work was done. See the bottom of this file for differences between minimp3 and dr_mp3.
*/

/*
Introduction
=============
dr_mp3 is a single file library. To use it, do something like the following in one .c file.

	```c
	#define DR_MP3_IMPLEMENTATION
	#include "dr_mp3.h"
	```

You can then #include this file in other parts of the program as you would with any other header file. To decode audio data, do something like the following:

	```c
	drmp3 mp3;
	if (!drmp3_init_file(&mp3, "MySong.mp3", NULL)) {
		// Failed to open file
	}

	...

	drmp3_uint64 framesRead = drmp3_read_pcm_frames_f32(pMP3, framesToRead, pFrames);
	```

The drmp3 object is transparent so you can get access to the channel count and sample rate like so:

	```
	drmp3_uint32 channels = mp3.channels;
	drmp3_uint32 sampleRate = mp3.sampleRate;
	```

The example above initializes a decoder from a file, but you can also initialize it from a block of memory and read and seek callbacks with
`drmp3_init_memory()` and `drmp3_init()` respectively.

You do not need to do any annoying memory management when reading PCM frames - this is all managed internally. You can request any number of PCM frames in each
call to `drmp3_read_pcm_frames_f32()` and it will return as many PCM frames as it can, up to the requested amount.

You can also decode an entire file in one go with `drmp3_open_and_read_pcm_frames_f32()`, `drmp3_open_memory_and_read_pcm_frames_f32()` and
`drmp3_open_file_and_read_pcm_frames_f32()`.


Build Options
=============
#define these options before including this file.

#define DR_MP3_NO_STDIO
  Disable drmp3_init_file(), etc.

#define DR_MP3_NO_SIMD
  Disable SIMD optimizations.
*/


/* Sized Types */
typealias drmp3_int8 =  int8          ;
typealias drmp3_uint8 = uint8          ;
typealias drmp3_int16 =   int16          ;
typealias drmp3_uint16 =  uint16          ;
typealias drmp3_int32 =   int32            ;
typealias drmp3_uint32 = uint32            ;
typealias   drmp3_int64 = int64    ;
typealias drmp3_uint64 = uint64    ;
typealias drmp3_uintptr = uint        ;
typealias drmp3_bool8 = drmp3_uint8             ;
typealias drmp3_bool32 = drmp3_uint32            ;
static
{
	public const uint32 DRMP3_TRUE       =       1;
	public const uint32 DRMP3_FALSE      =       0;

	/* Weird shifting syntax is for VC6 compatibility. */
	public const uint64 DRMP3_UINT64_MAX   =     (((drmp3_uint64)0xFFFFFFFF << 32) | (drmp3_uint64)0xFFFFFFFF);
	/* End Sized Types */
}

	/* Result Codes */
typealias drmp3_result = drmp3_int32;
static
{
	public const drmp3_result DRMP3_SUCCESS                       = 0;
	public const drmp3_result DRMP3_ERROR                         = -1; /* A generic error. */
	public const drmp3_result DRMP3_INVALID_ARGS                   = -2;
	public const drmp3_result DRMP3_INVALID_OPERATION              = -3;
	public const drmp3_result DRMP3_OUT_OF_MEMORY                  = -4;
	public const drmp3_result DRMP3_OUT_OF_RANGE                   = -5;
	public const drmp3_result DRMP3_ACCESS_DENIED                  = -6;
	public const drmp3_result DRMP3_DOES_NOT_EXIST                 = -7;
	public const drmp3_result DRMP3_ALREADY_EXISTS                 = -8;
	public const drmp3_result DRMP3_TOO_MANY_OPEN_FILES            = -9;
	public const drmp3_result DRMP3_INVALID_FILE                   = -10;
	public const drmp3_result DRMP3_TOO_BIG                        = -11;
	public const drmp3_result DRMP3_PATH_TOO_LONG                  = -12;
	public const drmp3_result DRMP3_NAME_TOO_LONG                  = -13;
	public const drmp3_result DRMP3_NOT_DIRECTORY                  = -14;
	public const drmp3_result DRMP3_IS_DIRECTORY                   = -15;
	public const drmp3_result DRMP3_DIRECTORY_NOT_EMPTY            = -16;
	public const drmp3_result DRMP3_END_OF_FILE                    = -17;
	public const drmp3_result DRMP3_NO_SPACE                       = -18;
	public const drmp3_result DRMP3_BUSY                           = -19;
	public const drmp3_result DRMP3_IO_ERROR                       = -20;
	public const drmp3_result DRMP3_INTERRUPT                      = -21;
	public const drmp3_result DRMP3_UNAVAILABLE                    = -22;
	public const drmp3_result DRMP3_ALREADY_IN_USE                 = -23;
	public const drmp3_result DRMP3_BAD_ADDRESS                    = -24;
	public const drmp3_result DRMP3_BAD_SEEK                       = -25;
	public const drmp3_result DRMP3_BAD_PIPE                       = -26;
	public const drmp3_result DRMP3_DEADLOCK                       = -27;
	public const drmp3_result DRMP3_TOO_MANY_LINKS                 = -28;
	public const drmp3_result DRMP3_NOT_IMPLEMENTED                = -29;
	public const drmp3_result DRMP3_NO_MESSAGE                     = -30;
	public const drmp3_result DRMP3_BAD_MESSAGE                    = -31;
	public const drmp3_result DRMP3_NO_DATA_AVAILABLE              = -32;
	public const drmp3_result DRMP3_INVALID_DATA                   = -33;
	public const drmp3_result DRMP3_TIMEOUT                        = -34;
	public const drmp3_result DRMP3_NO_NETWORK                     = -35;
	public const drmp3_result DRMP3_NOT_UNIQUE                     = -36;
	public const drmp3_result DRMP3_NOT_SOCKET                     = -37;
	public const drmp3_result DRMP3_NO_ADDRESS                     = -38;
	public const drmp3_result DRMP3_BAD_PROTOCOL                   = -39;
	public const drmp3_result DRMP3_PROTOCOL_UNAVAILABLE           = -40;
	public const drmp3_result DRMP3_PROTOCOL_NOT_SUPPORTED         = -41;
	public const drmp3_result DRMP3_PROTOCOL_FAMILY_NOT_SUPPORTED  = -42;
	public const drmp3_result DRMP3_ADDRESS_FAMILY_NOT_SUPPORTED   = -43;
	public const drmp3_result DRMP3_SOCKET_NOT_SUPPORTED           = -44;
	public const drmp3_result DRMP3_CONNECTION_RESET               = -45;
	public const drmp3_result DRMP3_ALREADY_CONNECTED              = -46;
	public const drmp3_result DRMP3_NOT_CONNECTED                  = -47;
	public const drmp3_result DRMP3_CONNECTION_REFUSED             = -48;
	public const drmp3_result DRMP3_NO_HOST                        = -49;
	public const drmp3_result DRMP3_IN_PROGRESS                    = -50;
	public const drmp3_result DRMP3_CANCELLED                      = -51;
	public const drmp3_result DRMP3_MEMORY_ALREADY_MAPPED          = -52;
	public const drmp3_result DRMP3_AT_END                         = -53;
	/* End Result Codes */

	public const uint32 DRMP3_MAX_PCM_FRAMES_PER_MP3_FRAME =   1152;
	public const uint32 DRMP3_MAX_SAMPLES_PER_FRAME     =    (DRMP3_MAX_PCM_FRAMES_PER_MP3_FRAME * 2);

}


static
{
	[CLink] public static extern void drmp3_version(drmp3_uint32* pMajor, drmp3_uint32* pMinor, drmp3_uint32* pRevision);
	[CLink] public static extern char8* drmp3_version_string(void);
}


	/* Allocation Callbacks */
[CRepr] struct drmp3_allocation_callbacks
{
	void* pUserData;
	function void*(uint sz, void* pUserData) onMalloc;
	function void*(void* p, uint sz, void* pUserData) onRealloc;
	function void  (void* p, void* pUserData) onFree;
}
/* End Allocation Callbacks */


/*
Low Level Push API
==================
*/
static
{
	public const uint32 DRMP3_MAX_BITRESERVOIR_BYTES      = 511;
	public const uint32 DRMP3_MAX_FREE_FORMAT_FRAME_SIZE  = 2304; /* more than ISO spec's */
	public const uint32 DRMP3_MAX_L3_FRAME_PAYLOAD_BYTES  = DRMP3_MAX_FREE_FORMAT_FRAME_SIZE; /* MUST be >= 320000/8/32000*1152 = 1440 */
}

[CRepr] struct drmp3dec_frame_info
{
	int32 frame_bytes;
	int32 channels;
	int32 sample_rate;
	int32 layer;
	int32 bitrate_kbps;
}

[CRepr] struct drmp3_bs
{
	drmp3_uint8* buf;
	int32 pos, limit;
}

[CRepr] struct drmp3_L3_gr_info
{
	drmp3_uint8* sfbtab;
	drmp3_uint16 part_23_length, big_values, scalefac_compress;
	drmp3_uint8 global_gain, block_type, mixed_block_flag, n_long_sfb, n_short_sfb;
	drmp3_uint8[3] table_select;
	drmp3_uint8[3] region_count;
	drmp3_uint8[3] subblock_gain;
	drmp3_uint8 preflag, scalefac_scale, count1_table, scfsi;
}

[CRepr] struct drmp3dec_scratch
{
	drmp3_bs bs;
	drmp3_uint8[DRMP3_MAX_BITRESERVOIR_BYTES + DRMP3_MAX_L3_FRAME_PAYLOAD_BYTES] maindata;
	drmp3_L3_gr_info[4] gr_info;
	float[2][576] grbuf;
	float[40] scf;
	float[18 + 15][2 * 32] syn;
	drmp3_uint8[2][39] ist_pos;
}

[CRepr] struct drmp3dec
{
	float[2][9 * 32] mdct_overlap;
	float[15 * 2 * 32] qmf_state;
	int32 reserv, free_format_bytes;
	drmp3_uint8[4] header;
	drmp3_uint8[511] reserv_buf;
	drmp3dec_scratch scratch;
}
static
{
/* Initializes a low level decoder. */
	[CLink] public static extern void drmp3dec_init(drmp3dec* dec);

/* Reads a frame from a low level decoder. */
	[CLink] public static extern int32 drmp3dec_decode_frame(drmp3dec* dec, drmp3_uint8* mp3, int32 mp3_bytes, void* pcm, drmp3dec_frame_info* info);

/* Helper for converting between f32 and s16. */
	[CLink] public static extern void drmp3dec_f32_to_s16(float* @in, drmp3_int16* @out, uint num_samples);
}


/*
Main API (Pull API)
===================
*/
enum drmp3_seek_origin : int32
{
	DRMP3_SEEK_SET,
	DRMP3_SEEK_CUR,
	DRMP3_SEEK_END
}

[CRepr] struct drmp3_seek_point
{
	drmp3_uint64 seekPosInBytes; /* Points to the first byte of an MP3 frame. */
	drmp3_uint64 pcmFrameIndex; /* The index of the PCM frame this seek point targets. */
	drmp3_uint16 mp3FramesToDiscard; /* The number of whole MP3 frames to be discarded before pcmFramesToDiscard. */
	drmp3_uint16 pcmFramesToDiscard; /* The number of leading samples to read and discard. These are discarded after mp3FramesToDiscard. */
}

enum drmp3_metadata_type : int32
{
	DRMP3_METADATA_TYPE_ID3V1,
	DRMP3_METADATA_TYPE_ID3V2,
	DRMP3_METADATA_TYPE_APE,
	DRMP3_METADATA_TYPE_XING,
	DRMP3_METADATA_TYPE_VBRI
}

[CRepr] struct drmp3_metadata
{
	drmp3_metadata_type type;
	void* pRawData; /* A pointer to the raw data. */
	uint rawDataSize;
}


/*
Callback for when data is read. Return value is the number of bytes actually read.

pUserData   [in]  The user data that was passed to drmp3_init(), and family.
pBufferOut  [out] The output buffer.
bytesToRead [in]  The number of bytes to read.

Returns the number of bytes actually read.

A return value of less than bytesToRead indicates the end of the stream. Do _not_ return from this callback until
either the entire bytesToRead is filled or you have reached the end of the stream.
*/
typealias drmp3_read_proc = function uint(void* pUserData, void* pBufferOut, uint bytesToRead);

/*
Callback for when data needs to be seeked.

pUserData [in] The user data that was passed to drmp3_init(), and family.
offset    [in] The number of bytes to move, relative to the origin. Can be negative.
origin    [in] The origin of the seek.

Returns whether or not the seek was successful.
*/
typealias drmp3_seek_proc = function drmp3_bool32(void* pUserData, int32 offset, drmp3_seek_origin origin);

/*
Callback for retrieving the current cursor position.

pUserData [in]  The user data that was passed to drmp3_init(), and family.
pCursor   [out] The cursor position in bytes from the start of the stream.

Returns whether or not the cursor position was successfully retrieved.
*/
typealias drmp3_tell_proc = function drmp3_bool32(void* pUserData, drmp3_int64* pCursor);


/*
Callback for when metadata is read.

Only the raw data is provided. The client is responsible for parsing the contents of the data themsevles.
*/
typealias drmp3_meta_proc = function void(void* pUserData, drmp3_metadata* pMetadata);


[CRepr] struct drmp3_config
{
	public drmp3_uint32 channels;
	public drmp3_uint32 sampleRate;
}

[CRepr] struct drmp3
{
	drmp3dec decoder;
	drmp3_uint32 channels;
	drmp3_uint32 sampleRate;
	drmp3_read_proc onRead;
	drmp3_seek_proc onSeek;
	drmp3_meta_proc onMeta;
	void* pUserData;
	void* pUserDataMeta;
	drmp3_allocation_callbacks allocationCallbacks;
	drmp3_uint32 mp3FrameChannels; /* The number of channels in the currently loaded MP3 frame. Internal use only. */
	drmp3_uint32 mp3FrameSampleRate; /* The sample rate of the currently loaded MP3 frame. Internal use only. */
	drmp3_uint32 pcmFramesConsumedInMP3Frame;
	drmp3_uint32 pcmFramesRemainingInMP3Frame;
	drmp3_uint8[sizeof(float) * DRMP3_MAX_SAMPLES_PER_FRAME] pcmFrames; /* <-- Multipled by sizeof(float) to ensure there's enough room for DR_MP3_FLOAT_OUTPUT. */
	drmp3_uint64 currentPCMFrame; /* The current PCM frame, globally. */
	drmp3_uint64 streamCursor; /* The current byte the decoder is sitting on in the raw stream. */
	drmp3_uint64 streamLength; /* The length of the stream in bytes. dr_mp3 will not read beyond this. If a ID3v1 or APE tag is present, this will be set to the first byte of the tag. */
	drmp3_uint64 streamStartOffset; /* The offset of the start of the MP3 data. This is used for skipping ID3v2 and VBR tags. */
	drmp3_seek_point* pSeekPoints; /* NULL by default. Set with drmp3_bind_seek_table(). Memory is owned by the client. dr_mp3 will never attempt to free this pointer. */
	drmp3_uint32 seekPointCount; /* The number of items in pSeekPoints. When set to 0 assumes to no seek table. Defaults to zero. */
	drmp3_uint32 delayInPCMFrames;
	drmp3_uint32 paddingInPCMFrames;
	drmp3_uint64 totalPCMFrameCount; /* Set to DRMP3_UINT64_MAX if the length is unknown. Includes delay and padding. */
	drmp3_bool32 isVBR;
	drmp3_bool32 isCBR;
	uint dataSize;
	uint dataCapacity;
	uint dataConsumed;
	drmp3_uint8* pData;
	drmp3_bool32 atEnd;
	[CRepr] struct
	{
		drmp3_uint8* pData;
		uint dataSize;
		uint currentReadPos;
	} memory; /* Only used for decoders that were opened against a block of memory. */
}
static
{
/*
Initializes an MP3 decoder.

onRead    [in]           The function to call when data needs to be read from the client.
onSeek    [in]           The function to call when the read position of the client data needs to move.
onTell    [in]           The function to call when the read position of the client data needs to be retrieved.
pUserData [in, optional] A pointer to application defined data that will be passed to onRead and onSeek.

Returns true if successful; false otherwise.

Close the loader with drmp3_uninit().

See also: drmp3_init_file(), drmp3_init_memory(), drmp3_uninit()
*/
	[CLink] public static extern drmp3_bool32 drmp3_init(drmp3* pMP3, drmp3_read_proc onRead, drmp3_seek_proc onSeek, drmp3_tell_proc onTell, drmp3_meta_proc onMeta, void* pUserData, drmp3_allocation_callbacks* pAllocationCallbacks);

/*
Initializes an MP3 decoder from a block of memory.

This does not create a copy of the data. It is up to the application to ensure the buffer remains valid for
the lifetime of the drmp3 object.

The buffer should contain the contents of the entire MP3 file.
*/
	[CLink] public static extern drmp3_bool32 drmp3_init_memory_with_metadata(drmp3* pMP3, void* pData, uint dataSize, drmp3_meta_proc onMeta, void* pUserDataMeta,  drmp3_allocation_callbacks* pAllocationCallbacks);
	[CLink] public static extern drmp3_bool32 drmp3_init_memory(drmp3* pMP3, void* pData, uint dataSize,  drmp3_allocation_callbacks* pAllocationCallbacks);

//#ifndef DR_MP3_NO_STDIO
/*
Initializes an MP3 decoder from a file.

This holds the internal FILE object until drmp3_uninit() is called. Keep this in mind if you're caching drmp3
objects because the operating system may restrict the number of file handles an application can have open at
any given time.
*/
	[CLink] public static extern drmp3_bool32 drmp3_init_file_with_metadata(drmp3* pMP3, char8* pFilePath, drmp3_meta_proc onMeta, void* pUserDataMeta,  drmp3_allocation_callbacks* pAllocationCallbacks);
	[CLink] public static extern drmp3_bool32 drmp3_init_file_with_metadata_w(drmp3* pMP3,  c_wchar* pFilePath, drmp3_meta_proc onMeta, void* pUserDataMeta,  drmp3_allocation_callbacks* pAllocationCallbacks);

	[CLink] public static extern drmp3_bool32 drmp3_init_file(drmp3* pMP3, char8* pFilePath,  drmp3_allocation_callbacks* pAllocationCallbacks);
	[CLink] public static extern drmp3_bool32 drmp3_init_file_w(drmp3* pMP3,  c_wchar* pFilePath,  drmp3_allocation_callbacks* pAllocationCallbacks);
//#endif

/*
Uninitializes an MP3 decoder.
*/
	[CLink] public static extern void drmp3_uninit(drmp3* pMP3);

/*
Reads PCM frames as interleaved 32-bit IEEE floating point PCM.

Note that framesToRead specifies the number of PCM frames to read, _not_ the number of MP3 frames.
*/
	[CLink] public static extern drmp3_uint64 drmp3_read_pcm_frames_f32(drmp3* pMP3, drmp3_uint64 framesToRead, float* pBufferOut);

/*
Reads PCM frames as interleaved signed 16-bit integer PCM.

Note that framesToRead specifies the number of PCM frames to read, _not_ the number of MP3 frames.
*/
	[CLink] public static extern drmp3_uint64 drmp3_read_pcm_frames_s16(drmp3* pMP3, drmp3_uint64 framesToRead, drmp3_int16* pBufferOut);

/*
Seeks to a specific frame.

Note that this is _not_ an MP3 frame, but rather a PCM frame.
*/
	[CLink] public static extern drmp3_bool32 drmp3_seek_to_pcm_frame(drmp3* pMP3, drmp3_uint64 frameIndex);

/*
Calculates the total number of PCM frames in the MP3 stream. Cannot be used for infinite streams such as internet
radio. Runs in linear time. Returns 0 on error.
*/
	[CLink] public static extern drmp3_uint64 drmp3_get_pcm_frame_count(drmp3* pMP3);

/*
Calculates the total number of MP3 frames in the MP3 stream. Cannot be used for infinite streams such as internet
radio. Runs in linear time. Returns 0 on error.
*/
	[CLink] public static extern drmp3_uint64 drmp3_get_mp3_frame_count(drmp3* pMP3);

/*
Calculates the total number of MP3 and PCM frames in the MP3 stream. Cannot be used for infinite streams such as internet
radio. Runs in linear time. Returns 0 on error.

This is equivalent to calling drmp3_get_mp3_frame_count() and drmp3_get_pcm_frame_count() except that it's more efficient.
*/
	[CLink] public static extern drmp3_bool32 drmp3_get_mp3_and_pcm_frame_count(drmp3* pMP3, drmp3_uint64* pMP3FrameCount, drmp3_uint64* pPCMFrameCount);

/*
Calculates the seekpoints based on PCM frames. This is slow.

pSeekpoint count is a pointer to a uint32 containing the seekpoint count. On input it contains the desired count.
On output it contains the actual count. The reason for this design is that the client may request too many
seekpoints, in which case dr_mp3 will return a corrected count.

Note that seektable seeking is not quite sample exact when the MP3 stream contains inconsistent sample rates.
*/
	[CLink] public static extern drmp3_bool32 drmp3_calculate_seek_points(drmp3* pMP3, drmp3_uint32* pSeekPointCount, drmp3_seek_point* pSeekPoints);

/*
Binds a seek table to the decoder.

This does _not_ make a copy of pSeekPoints - it only references it. It is up to the application to ensure this
remains valid while it is bound to the decoder.

Use drmp3_calculate_seek_points() to calculate the seek points.
*/
	[CLink] public static extern drmp3_bool32 drmp3_bind_seek_table(drmp3* pMP3, drmp3_uint32 seekPointCount, drmp3_seek_point* pSeekPoints);


/*
Opens an decodes an entire MP3 stream as a single operation.

On output pConfig will receive the channel count and sample rate of the stream.

Free the returned pointer with drmp3_free().
*/
	[CLink] public static extern float* drmp3_open_and_read_pcm_frames_f32(drmp3_read_proc onRead, drmp3_seek_proc onSeek, drmp3_tell_proc onTell, void* pUserData, drmp3_config* pConfig, drmp3_uint64* pTotalFrameCount, drmp3_allocation_callbacks* pAllocationCallbacks);
	[CLink] public static extern drmp3_int16* drmp3_open_and_read_pcm_frames_s16(drmp3_read_proc onRead, drmp3_seek_proc onSeek, drmp3_tell_proc onTell, void* pUserData, drmp3_config* pConfig, drmp3_uint64* pTotalFrameCount, drmp3_allocation_callbacks* pAllocationCallbacks);

	[CLink] public static extern float* drmp3_open_memory_and_read_pcm_frames_f32(void* pData, uint dataSize, drmp3_config* pConfig, drmp3_uint64* pTotalFrameCount,  drmp3_allocation_callbacks* pAllocationCallbacks);
	[CLink] public static extern drmp3_int16* drmp3_open_memory_and_read_pcm_frames_s16(void* pData, uint dataSize, drmp3_config* pConfig, drmp3_uint64* pTotalFrameCount,  drmp3_allocation_callbacks* pAllocationCallbacks);

//#ifndef DR_MP3_NO_STDIO
	[CLink] public static extern float* drmp3_open_file_and_read_pcm_frames_f32(char8* filePath, drmp3_config* pConfig, drmp3_uint64* pTotalFrameCount,  drmp3_allocation_callbacks* pAllocationCallbacks);
	[CLink] public static extern drmp3_int16* drmp3_open_file_and_read_pcm_frames_s16(char8* filePath, drmp3_config* pConfig, drmp3_uint64* pTotalFrameCount,  drmp3_allocation_callbacks* pAllocationCallbacks);
//#endif

/*
Allocates a block of memory on the heap.
*/
	[CLink] public static extern void* drmp3_malloc(uint sz, drmp3_allocation_callbacks* pAllocationCallbacks);

/*
Frees any memory that was allocated by a public drmp3 API.
*/
	[CLink] public static extern void drmp3_free(void* p,  drmp3_allocation_callbacks* pAllocationCallbacks);
}
 /* dr_mp3_h */


/*
DIFFERENCES BETWEEN minimp3 AND dr_mp3
======================================
- First, keep in mind that minimp3 (https://github.com/lieff/minimp3) is where all the real work was done. All of the
  code relating to the actual decoding remains mostly unmodified, apart from some namespacing changes.
- dr_mp3 adds a pulling style API which allows you to deliver raw data via callbacks. So, rather than pushing data
  to the decoder, the decoder _pulls_ data from your callbacks.
- In addition to callbacks, a decoder can be initialized from a block of memory and a file.
- The dr_mp3 pull API reads PCM frames rather than whole MP3 frames.
- dr_mp3 adds convenience APIs for opening and decoding entire files in one go.
- dr_mp3 is fully namespaced, including the implementation section, which is more suitable when compiling projects
  as a single translation unit (aka unity builds). At the time of writing this, a unity build is not possible when
  using minimp3 in conjunction with stb_vorbis. dr_mp3 addresses this.
*/

/*
REVISION HISTORY
================
v0.7.3 - TBD
  - Fix an error in drmp3_open_and_read_pcm_frames_s16() and family when memory allocation fails.
  - Fix some compilation warnings.

v0.7.2 - 2025-12-02
  - Reduce stack space to improve robustness on embedded systems.
  - Fix a compilation error with MSVC Clang toolset relating to cpuid.
  - Fix an error with APE tag parsing.

v0.7.1 - 2025-09-10
  - Silence a warning with GCC.
  - Fix an error with the NXDK build.
  - Fix a decoding inconsistency when seeking. Prior to this change, reading to the end of the stream immediately after initializing will result in a different number of samples read than if the stream is seeked to the start and read to the end.

v0.7.0 - 2025-07-23
  - The old `DRMP3_IMPLEMENTATION` has been removed. Use `DR_MP3_IMPLEMENTATION` instead. The reason for this change is that in the future everything will eventually be using the underscored naming convention in the future, so `drmp3` will become `dr_mp3`.
  - API CHANGE: Seek origins have been renamed to match the naming convention used by dr_wav and my other libraries.
	- drmp3_seek_origin_start   -> DRMP3_SEEK_SET
	- drmp3_seek_origin_current -> DRMP3_SEEK_CUR
	- DRMP3_SEEK_END (new)
  - API CHANGE: Add DRMP3_SEEK_END as a seek origin for the seek callback. This is required for detection of ID3v1 and APE tags.
  - API CHANGE: Add onTell callback to `drmp3_init()`. This is needed in order to track the location of ID3v1 and APE tags.
  - API CHANGE: Add onMeta callback to `drmp3_init()`. This is used for reporting tag data back to the caller. Currently this only reports the raw tag data which means applications need to parse the data themselves.
  - API CHANGE: Rename `drmp3dec_frame_info.hz` to `drmp3dec_frame_info.sample_rate`.
  - Add detection of ID3v2, ID3v1, APE and Xing/VBRI tags. This should fix errors with some files where the decoder was reading tags as audio data.
  - Delay and padding samples from LAME tags are now handled.
  - Fix compilation for AIX OS.

v0.6.40 - 2024-12-17
  - Improve detection of ARM64EC

v0.6.39 - 2024-02-27
  - Fix a Wdouble-promotion warning.

v0.6.38 - 2023-11-02
  - Fix build for ARMv6-M.

v0.6.37 - 2023-07-07
  - Silence a static analysis warning.

v0.6.36 - 2023-06-17
  - Fix an incorrect date in revision history. No functional change.

v0.6.35 - 2023-05-22
  - Minor code restructure. No functional change.

v0.6.34 - 2022-09-17
  - Fix compilation with DJGPP.
  - Fix compilation when compiling with x86 with no SSE2.
  - Remove an unnecessary variable from the drmp3 structure.

v0.6.33 - 2022-04-10
  - Fix compilation error with the MSVC ARM64 build.
  - Fix compilation error on older versions of GCC.
  - Remove some unused functions.

v0.6.32 - 2021-12-11
  - Fix a warning with Clang.

v0.6.31 - 2021-08-22
  - Fix a bug when loading from memory.

v0.6.30 - 2021-08-16
  - Silence some warnings.
  - Replace memory operations with DRMP3_* macros.

v0.6.29 - 2021-08-08
  - Bring up to date with minimp3.

v0.6.28 - 2021-07-31
  - Fix platform detection for ARM64.
  - Fix a compilation error with C89.

v0.6.27 - 2021-02-21
  - Fix a warning due to referencing _MSC_VER when it is undefined.

v0.6.26 - 2021-01-31
  - Bring up to date with minimp3.

v0.6.25 - 2020-12-26
  - Remove DRMP3_DEFAULT_CHANNELS and DRMP3_DEFAULT_SAMPLE_RATE which are leftovers from some removed APIs.

v0.6.24 - 2020-12-07
  - Fix a typo in version date for 0.6.23.

v0.6.23 - 2020-12-03
  - Fix an error where a file can be closed twice when initialization of the decoder fails.

v0.6.22 - 2020-12-02
  - Fix an error where it's possible for a file handle to be left open when initialization of the decoder fails.

v0.6.21 - 2020-11-28
  - Bring up to date with minimp3.

v0.6.20 - 2020-11-21
  - Fix compilation with OpenWatcom.

v0.6.19 - 2020-11-13
  - Minor code clean up.

v0.6.18 - 2020-11-01
  - Improve compiler support for older versions of GCC.

v0.6.17 - 2020-09-28
  - Bring up to date with minimp3.

v0.6.16 - 2020-08-02
  - Simplify sized types.

v0.6.15 - 2020-07-25
  - Fix a compilation warning.

v0.6.14 - 2020-07-23
  - Fix undefined behaviour with memmove().

v0.6.13 - 2020-07-06
  - Fix a bug when converting from s16 to f32 in drmp3_read_pcm_frames_f32().

v0.6.12 - 2020-06-23
  - Add include guard for the implementation section.

v0.6.11 - 2020-05-26
  - Fix use of uninitialized variable error.

v0.6.10 - 2020-05-16
  - Add compile-time and run-time version querying.
	- DRMP3_VERSION_MINOR
	- DRMP3_VERSION_MAJOR
	- DRMP3_VERSION_REVISION
	- DRMP3_VERSION_STRING
	- drmp3_version()
	- drmp3_version_string()

v0.6.9 - 2020-04-30
  - Change the `pcm` parameter of drmp3dec_decode_frame() to a `const drmp3_uint8*` for consistency with internal APIs.

v0.6.8 - 2020-04-26
  - Optimizations to decoding when initializing from memory.

v0.6.7 - 2020-04-25
  - Fix a compilation error with DR_MP3_NO_STDIO
  - Optimization to decoding by reducing some data movement.

v0.6.6 - 2020-04-23
  - Fix a minor bug with the running PCM frame counter.

v0.6.5 - 2020-04-19
  - Fix compilation error on ARM builds.

v0.6.4 - 2020-04-19
  - Bring up to date with changes to minimp3.

v0.6.3 - 2020-04-13
  - Fix some pedantic warnings.

v0.6.2 - 2020-04-10
  - Fix a crash in drmp3_open_*_and_read_pcm_frames_*() if the output config object is NULL.

v0.6.1 - 2020-04-05
  - Fix warnings.

v0.6.0 - 2020-04-04
  - API CHANGE: Remove the pConfig parameter from the following APIs:
	- drmp3_init()
	- drmp3_init_memory()
	- drmp3_init_file()
  - Add drmp3_init_file_w() for opening a file from a wchar_t encoded path.

v0.5.6 - 2020-02-12
  - Bring up to date with minimp3.

v0.5.5 - 2020-01-29
  - Fix a memory allocation bug in high level s16 decoding APIs.

v0.5.4 - 2019-12-02
  - Fix a possible null pointer dereference when using custom memory allocators for realloc().

v0.5.3 - 2019-11-14
  - Fix typos in documentation.

v0.5.2 - 2019-11-02
  - Bring up to date with minimp3.

v0.5.1 - 2019-10-08
  - Fix a warning with GCC.

v0.5.0 - 2019-10-07
  - API CHANGE: Add support for user defined memory allocation routines. This system allows the program to specify their own memory allocation
	routines with a user data pointer for client-specific contextual data. This adds an extra parameter to the end of the following APIs:
	- drmp3_init()
	- drmp3_init_file()
	- drmp3_init_memory()
	- drmp3_open_and_read_pcm_frames_f32()
	- drmp3_open_and_read_pcm_frames_s16()
	- drmp3_open_memory_and_read_pcm_frames_f32()
	- drmp3_open_memory_and_read_pcm_frames_s16()
	- drmp3_open_file_and_read_pcm_frames_f32()
	- drmp3_open_file_and_read_pcm_frames_s16()
  - API CHANGE: Renamed the following APIs:
	- drmp3_open_and_read_f32()        -> drmp3_open_and_read_pcm_frames_f32()
	- drmp3_open_and_read_s16()        -> drmp3_open_and_read_pcm_frames_s16()
	- drmp3_open_memory_and_read_f32() -> drmp3_open_memory_and_read_pcm_frames_f32()
	- drmp3_open_memory_and_read_s16() -> drmp3_open_memory_and_read_pcm_frames_s16()
	- drmp3_open_file_and_read_f32()   -> drmp3_open_file_and_read_pcm_frames_f32()
	- drmp3_open_file_and_read_s16()   -> drmp3_open_file_and_read_pcm_frames_s16()

v0.4.7 - 2019-07-28
  - Fix a compiler error.

v0.4.6 - 2019-06-14
  - Fix a compiler error.

v0.4.5 - 2019-06-06
  - Bring up to date with minimp3.

v0.4.4 - 2019-05-06
  - Fixes to the VC6 build.

v0.4.3 - 2019-05-05
  - Use the channel count and/or sample rate of the first MP3 frame instead of DRMP3_DEFAULT_CHANNELS and
	DRMP3_DEFAULT_SAMPLE_RATE when they are set to 0. To use the old behaviour, just set the relevant property to
	DRMP3_DEFAULT_CHANNELS or DRMP3_DEFAULT_SAMPLE_RATE.
  - Add s16 reading APIs
	- drmp3_read_pcm_frames_s16
	- drmp3_open_memory_and_read_pcm_frames_s16
	- drmp3_open_and_read_pcm_frames_s16
	- drmp3_open_file_and_read_pcm_frames_s16
  - Add drmp3_get_mp3_and_pcm_frame_count() to the public header section.
  - Add support for C89.
  - Change license to choice of public domain or MIT-0.

v0.4.2 - 2019-02-21
  - Fix a warning.

v0.4.1 - 2018-12-30
  - Fix a warning.

v0.4.0 - 2018-12-16
  - API CHANGE: Rename some APIs:
	- drmp3_read_f32 -> to drmp3_read_pcm_frames_f32
	- drmp3_seek_to_frame -> drmp3_seek_to_pcm_frame
	- drmp3_open_and_decode_f32 -> drmp3_open_and_read_pcm_frames_f32
	- drmp3_open_and_decode_memory_f32 -> drmp3_open_memory_and_read_pcm_frames_f32
	- drmp3_open_and_decode_file_f32 -> drmp3_open_file_and_read_pcm_frames_f32
  - Add drmp3_get_pcm_frame_count().
  - Add drmp3_get_mp3_frame_count().
  - Improve seeking performance.

v0.3.2 - 2018-09-11
  - Fix a couple of memory leaks.
  - Bring up to date with minimp3.

v0.3.1 - 2018-08-25
  - Fix C++ build.

v0.3.0 - 2018-08-25
  - Bring up to date with minimp3. This has a minor API change: the "pcm" parameter of drmp3dec_decode_frame() has
	been changed from short* to void* because it can now output both s16 and f32 samples, depending on whether or
	not the DR_MP3_FLOAT_OUTPUT option is set.

v0.2.11 - 2018-08-08
  - Fix a bug where the last part of a file is not read.

v0.2.10 - 2018-08-07
  - Improve 64-bit detection.

v0.2.9 - 2018-08-05
  - Fix C++ build on older versions of GCC.
  - Bring up to date with minimp3.

v0.2.8 - 2018-08-02
  - Fix compilation errors with older versions of GCC.

v0.2.7 - 2018-07-13
  - Bring up to date with minimp3.

v0.2.6 - 2018-07-12
  - Bring up to date with minimp3.

v0.2.5 - 2018-06-22
  - Bring up to date with minimp3.

v0.2.4 - 2018-05-12
  - Bring up to date with minimp3.

v0.2.3 - 2018-04-29
  - Fix TCC build.

v0.2.2 - 2018-04-28
  - Fix bug when opening a decoder from memory.

v0.2.1 - 2018-04-27
  - Efficiency improvements when the decoder reaches the end of the stream.

v0.2 - 2018-04-21
  - Bring up to date with minimp3.
  - Start using major.minor.revision versioning.

v0.1d - 2018-03-30
  - Bring up to date with minimp3.

v0.1c - 2018-03-11
  - Fix C++ build error.

v0.1b - 2018-03-07
  - Bring up to date with minimp3.

v0.1a - 2018-02-28
  - Fix compilation error on GCC/Clang.
  - Fix some warnings.

v0.1 - 2018-02-xx
  - Initial versioned release.
*/

/*
This software is available as a choice of the following licenses. Choose
whichever you prefer.

===============================================================================
ALTERNATIVE 1 - Public Domain (www.unlicense.org)
===============================================================================
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>

===============================================================================
ALTERNATIVE 2 - MIT No Attribution
===============================================================================
Copyright 2023 David Reid

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
	https://github.com/lieff/minimp3
	To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide.
	This software is distributed without any warranty.
	See <http://creativecommons.org/publicdomain/zero/1.0/>.
*/
