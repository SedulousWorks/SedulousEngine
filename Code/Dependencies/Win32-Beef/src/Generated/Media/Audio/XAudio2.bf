using Win32.Foundation;
using Win32.Media.Audio;
using Win32.System.Com;
using System;

namespace Win32.Media.Audio.XAudio2;

#region Constants
public static
{
	public const uint32 FXEQ_MIN_FRAMERATE = 22000;
	public const uint32 FXEQ_MAX_FRAMERATE = 48000;
	public const float FXEQ_MIN_FREQUENCY_CENTER = 20f;
	public const float FXEQ_MAX_FREQUENCY_CENTER = 20000f;
	public const float FXEQ_DEFAULT_FREQUENCY_CENTER_0 = 100f;
	public const float FXEQ_DEFAULT_FREQUENCY_CENTER_1 = 800f;
	public const float FXEQ_DEFAULT_FREQUENCY_CENTER_2 = 2000f;
	public const float FXEQ_DEFAULT_FREQUENCY_CENTER_3 = 10000f;
	public const float FXEQ_MIN_GAIN = 0.126f;
	public const float FXEQ_MAX_GAIN = 7.94f;
	public const float FXEQ_DEFAULT_GAIN = 1f;
	public const float FXEQ_MIN_BANDWIDTH = 0.1f;
	public const float FXEQ_MAX_BANDWIDTH = 2f;
	public const float FXEQ_DEFAULT_BANDWIDTH = 1f;
	public const uint32 FXMASTERINGLIMITER_MIN_RELEASE = 1;
	public const uint32 FXMASTERINGLIMITER_MAX_RELEASE = 20;
	public const uint32 FXMASTERINGLIMITER_DEFAULT_RELEASE = 6;
	public const uint32 FXMASTERINGLIMITER_MIN_LOUDNESS = 1;
	public const uint32 FXMASTERINGLIMITER_MAX_LOUDNESS = 1800;
	public const uint32 FXMASTERINGLIMITER_DEFAULT_LOUDNESS = 1000;
	public const float FXREVERB_MIN_DIFFUSION = 0f;
	public const float FXREVERB_MAX_DIFFUSION = 1f;
	public const float FXREVERB_DEFAULT_DIFFUSION = 0.9f;
	public const float FXREVERB_MIN_ROOMSIZE = 0.0001f;
	public const float FXREVERB_MAX_ROOMSIZE = 1f;
	public const float FXREVERB_DEFAULT_ROOMSIZE = 0.6f;
	public const uint32 FXLOUDNESS_DEFAULT_MOMENTARY_MS = 400;
	public const uint32 FXLOUDNESS_DEFAULT_SHORTTERM_MS = 3000;
	public const float FXECHO_MIN_WETDRYMIX = 0f;
	public const float FXECHO_MAX_WETDRYMIX = 1f;
	public const float FXECHO_DEFAULT_WETDRYMIX = 0.5f;
	public const float FXECHO_MIN_FEEDBACK = 0f;
	public const float FXECHO_MAX_FEEDBACK = 1f;
	public const float FXECHO_DEFAULT_FEEDBACK = 0.5f;
	public const float FXECHO_MIN_DELAY = 1f;
	public const float FXECHO_MAX_DELAY = 2000f;
	public const float FXECHO_DEFAULT_DELAY = 500f;
	public const String XAUDIO2_DLL_A = "xaudio2_9.dll";
	public const String XAUDIO2_DLL_W = "xaudio2_9.dll";
	public const String XAUDIO2D_DLL_A = "xaudio2_9d.dll";
	public const String XAUDIO2D_DLL_W = "xaudio2_9d.dll";
	public const String XAUDIO2_DLL = "xaudio2_9.dll";
	public const String XAUDIO2D_DLL = "xaudio2_9d.dll";
	public const uint32 XAUDIO2_MAX_BUFFER_BYTES = 2147483648;
	public const uint32 XAUDIO2_MAX_QUEUED_BUFFERS = 64;
	public const uint32 XAUDIO2_MAX_BUFFERS_SYSTEM = 2;
	public const uint32 XAUDIO2_MAX_AUDIO_CHANNELS = 64;
	public const uint32 XAUDIO2_MIN_SAMPLE_RATE = 1000;
	public const uint32 XAUDIO2_MAX_SAMPLE_RATE = 200000;
	public const float XAUDIO2_MAX_VOLUME_LEVEL = 16777216f;
	public const float XAUDIO2_MAX_FREQ_RATIO = 1024f;
	public const float XAUDIO2_DEFAULT_FREQ_RATIO = 2f;
	public const float XAUDIO2_MAX_FILTER_ONEOVERQ = 1.5f;
	public const float XAUDIO2_MAX_FILTER_FREQUENCY = 1f;
	public const uint32 XAUDIO2_MAX_LOOP_COUNT = 254;
	public const uint32 XAUDIO2_MAX_INSTANCES = 8;
	public const uint32 XAUDIO2_MAX_RATIO_TIMES_RATE_XMA_MONO = 600000;
	public const uint32 XAUDIO2_MAX_RATIO_TIMES_RATE_XMA_MULTICHANNEL = 300000;
	public const uint32 XAUDIO2_COMMIT_NOW = 0;
	public const uint32 XAUDIO2_COMMIT_ALL = 0;
	public const uint32 XAUDIO2_NO_LOOP_REGION = 0;
	public const uint32 XAUDIO2_LOOP_INFINITE = 255;
	public const uint32 XAUDIO2_DEFAULT_CHANNELS = 0;
	public const uint32 XAUDIO2_DEFAULT_SAMPLERATE = 0;
	public const uint32 XAUDIO2_DEBUG_ENGINE = 1;
	public const uint32 XAUDIO2_VOICE_NOPITCH = 2;
	public const uint32 XAUDIO2_VOICE_NOSRC = 4;
	public const uint32 XAUDIO2_VOICE_USEFILTER = 8;
	public const uint32 XAUDIO2_PLAY_TAILS = 32;
	public const uint32 XAUDIO2_END_OF_STREAM = 64;
	public const uint32 XAUDIO2_SEND_USEFILTER = 128;
	public const uint32 XAUDIO2_VOICE_NOSAMPLESPLAYED = 256;
	public const uint32 XAUDIO2_STOP_ENGINE_WHEN_IDLE = 8192;
	public const uint32 XAUDIO2_1024_QUANTUM = 32768;
	public const uint32 XAUDIO2_NO_VIRTUAL_AUDIO_CLIENT = 65536;
	public const float XAUDIO2_DEFAULT_FILTER_FREQUENCY = 1f;
	public const float XAUDIO2_DEFAULT_FILTER_ONEOVERQ = 1f;
	public const uint32 XAUDIO2_QUANTUM_NUMERATOR = 1;
	public const uint32 XAUDIO2_QUANTUM_DENOMINATOR = 100;
	public const uint32 FACILITY_XAUDIO2 = 2198;
	public const HRESULT XAUDIO2_E_INVALID_CALL = -2003435519;
	public const HRESULT XAUDIO2_E_XMA_DECODER_ERROR = -2003435518;
	public const HRESULT XAUDIO2_E_XAPO_CREATION_FAILED = -2003435517;
	public const HRESULT XAUDIO2_E_DEVICE_INVALIDATED = -2003435516;
	public const uint32 Processor1 = 1;
	public const uint32 Processor2 = 2;
	public const uint32 Processor3 = 4;
	public const uint32 Processor4 = 8;
	public const uint32 Processor5 = 16;
	public const uint32 Processor6 = 32;
	public const uint32 Processor7 = 64;
	public const uint32 Processor8 = 128;
	public const uint32 Processor9 = 256;
	public const uint32 Processor10 = 512;
	public const uint32 Processor11 = 1024;
	public const uint32 Processor12 = 2048;
	public const uint32 Processor13 = 4096;
	public const uint32 Processor14 = 8192;
	public const uint32 Processor15 = 16384;
	public const uint32 Processor16 = 32768;
	public const uint32 Processor17 = 65536;
	public const uint32 Processor18 = 131072;
	public const uint32 Processor19 = 262144;
	public const uint32 Processor20 = 524288;
	public const uint32 Processor21 = 1048576;
	public const uint32 Processor22 = 2097152;
	public const uint32 Processor23 = 4194304;
	public const uint32 Processor24 = 8388608;
	public const uint32 Processor25 = 16777216;
	public const uint32 Processor26 = 33554432;
	public const uint32 Processor27 = 67108864;
	public const uint32 Processor28 = 134217728;
	public const uint32 Processor29 = 268435456;
	public const uint32 Processor30 = 536870912;
	public const uint32 Processor31 = 1073741824;
	public const uint32 Processor32 = 2147483648;
	public const uint32 XAUDIO2_ANY_PROCESSOR = 4294967295;
	public const uint32 XAUDIO2_USE_DEFAULT_PROCESSOR = 0;
	public const uint32 XAUDIO2_DEFAULT_PROCESSOR = 1;
	public const uint32 XAUDIO2_LOG_ERRORS = 1;
	public const uint32 XAUDIO2_LOG_WARNINGS = 2;
	public const uint32 XAUDIO2_LOG_INFO = 4;
	public const uint32 XAUDIO2_LOG_DETAIL = 8;
	public const uint32 XAUDIO2_LOG_API_CALLS = 16;
	public const uint32 XAUDIO2_LOG_FUNC_CALLS = 32;
	public const uint32 XAUDIO2_LOG_TIMING = 64;
	public const uint32 XAUDIO2_LOG_LOCKS = 128;
	public const uint32 XAUDIO2_LOG_MEMORY = 256;
	public const uint32 XAUDIO2_LOG_STREAMING = 4096;
	public const uint32 XAUDIO2FX_REVERB_MIN_FRAMERATE = 20000;
	public const uint32 XAUDIO2FX_REVERB_MAX_FRAMERATE = 48000;
	public const float XAUDIO2FX_REVERB_MIN_WET_DRY_MIX = 0f;
	public const uint32 XAUDIO2FX_REVERB_MIN_REFLECTIONS_DELAY = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_REVERB_DELAY = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_REAR_DELAY = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_7POINT1_SIDE_DELAY = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_7POINT1_REAR_DELAY = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_POSITION = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_DIFFUSION = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_LOW_EQ_GAIN = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_LOW_EQ_CUTOFF = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_HIGH_EQ_GAIN = 0;
	public const uint32 XAUDIO2FX_REVERB_MIN_HIGH_EQ_CUTOFF = 0;
	public const float XAUDIO2FX_REVERB_MIN_ROOM_FILTER_FREQ = 20f;
	public const float XAUDIO2FX_REVERB_MIN_ROOM_FILTER_MAIN = -100f;
	public const float XAUDIO2FX_REVERB_MIN_ROOM_FILTER_HF = -100f;
	public const float XAUDIO2FX_REVERB_MIN_REFLECTIONS_GAIN = -100f;
	public const float XAUDIO2FX_REVERB_MIN_REVERB_GAIN = -100f;
	public const float XAUDIO2FX_REVERB_MIN_DECAY_TIME = 0.1f;
	public const float XAUDIO2FX_REVERB_MIN_DENSITY = 0f;
	public const float XAUDIO2FX_REVERB_MIN_ROOM_SIZE = 0f;
	public const float XAUDIO2FX_REVERB_MAX_WET_DRY_MIX = 100f;
	public const uint32 XAUDIO2FX_REVERB_MAX_REFLECTIONS_DELAY = 300;
	public const uint32 XAUDIO2FX_REVERB_MAX_REVERB_DELAY = 85;
	public const uint32 XAUDIO2FX_REVERB_MAX_REAR_DELAY = 5;
	public const uint32 XAUDIO2FX_REVERB_MAX_7POINT1_SIDE_DELAY = 5;
	public const uint32 XAUDIO2FX_REVERB_MAX_7POINT1_REAR_DELAY = 20;
	public const uint32 XAUDIO2FX_REVERB_MAX_POSITION = 30;
	public const uint32 XAUDIO2FX_REVERB_MAX_DIFFUSION = 15;
	public const uint32 XAUDIO2FX_REVERB_MAX_LOW_EQ_GAIN = 12;
	public const uint32 XAUDIO2FX_REVERB_MAX_LOW_EQ_CUTOFF = 9;
	public const uint32 XAUDIO2FX_REVERB_MAX_HIGH_EQ_GAIN = 8;
	public const uint32 XAUDIO2FX_REVERB_MAX_HIGH_EQ_CUTOFF = 14;
	public const float XAUDIO2FX_REVERB_MAX_ROOM_FILTER_FREQ = 20000f;
	public const float XAUDIO2FX_REVERB_MAX_ROOM_FILTER_MAIN = 0f;
	public const float XAUDIO2FX_REVERB_MAX_ROOM_FILTER_HF = 0f;
	public const float XAUDIO2FX_REVERB_MAX_REFLECTIONS_GAIN = 20f;
	public const float XAUDIO2FX_REVERB_MAX_REVERB_GAIN = 20f;
	public const float XAUDIO2FX_REVERB_MAX_DENSITY = 100f;
	public const float XAUDIO2FX_REVERB_MAX_ROOM_SIZE = 100f;
	public const float XAUDIO2FX_REVERB_DEFAULT_WET_DRY_MIX = 100f;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_REFLECTIONS_DELAY = 5;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_REVERB_DELAY = 5;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_REAR_DELAY = 5;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_7POINT1_SIDE_DELAY = 5;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_7POINT1_REAR_DELAY = 20;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_POSITION = 6;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_POSITION_MATRIX = 27;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_EARLY_DIFFUSION = 8;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_LATE_DIFFUSION = 8;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_LOW_EQ_GAIN = 8;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_LOW_EQ_CUTOFF = 4;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_HIGH_EQ_GAIN = 8;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_HIGH_EQ_CUTOFF = 4;
	public const float XAUDIO2FX_REVERB_DEFAULT_ROOM_FILTER_FREQ = 5000f;
	public const float XAUDIO2FX_REVERB_DEFAULT_ROOM_FILTER_MAIN = 0f;
	public const float XAUDIO2FX_REVERB_DEFAULT_ROOM_FILTER_HF = 0f;
	public const float XAUDIO2FX_REVERB_DEFAULT_REFLECTIONS_GAIN = 0f;
	public const float XAUDIO2FX_REVERB_DEFAULT_REVERB_GAIN = 0f;
	public const float XAUDIO2FX_REVERB_DEFAULT_DECAY_TIME = 1f;
	public const float XAUDIO2FX_REVERB_DEFAULT_DENSITY = 100f;
	public const float XAUDIO2FX_REVERB_DEFAULT_ROOM_SIZE = 100f;
	public const uint32 XAUDIO2FX_REVERB_DEFAULT_DISABLE_LATE_FIELD = 0;
	public const float HRTF_MAX_GAIN_LIMIT = 12f;
	public const float HRTF_MIN_GAIN_LIMIT = -96f;
	public const float HRTF_MIN_UNITY_GAIN_DISTANCE = 0.05f;
	public const float HRTF_DEFAULT_UNITY_GAIN_DISTANCE = 1f;
	public const uint32 FACILITY_XAPO = 2199;
	public const HRESULT XAPO_E_FORMAT_UNSUPPORTED = -2003369983;
	public const uint32 XAPO_MIN_CHANNELS = 1;
	public const uint32 XAPO_MAX_CHANNELS = 64;
	public const uint32 XAPO_MIN_FRAMERATE = 1000;
	public const uint32 XAPO_MAX_FRAMERATE = 200000;
	public const uint32 XAPO_REGISTRATION_STRING_LENGTH = 256;
	public const uint32 XAPO_FLAG_CHANNELS_MUST_MATCH = 1;
	public const uint32 XAPO_FLAG_FRAMERATE_MUST_MATCH = 2;
	public const uint32 XAPO_FLAG_BITSPERSAMPLE_MUST_MATCH = 4;
	public const uint32 XAPO_FLAG_BUFFERCOUNT_MUST_MATCH = 8;
	public const uint32 XAPO_FLAG_INPLACE_REQUIRED = 32;
	public const uint32 XAPO_FLAG_INPLACE_SUPPORTED = 16;
	public const uint32 SPEAKER_MONO = 4;
	public const uint32 X3DAUDIO_HANDLE_BYTESIZE = 20;
	public const float X3DAUDIO_PI = 3.1415927f;
	public const float X3DAUDIO_2PI = 6.2831855f;
	public const float X3DAUDIO_SPEED_OF_SOUND = 343.5f;
	public const uint32 X3DAUDIO_CALCULATE_MATRIX = 1;
	public const uint32 X3DAUDIO_CALCULATE_DELAY = 2;
	public const uint32 X3DAUDIO_CALCULATE_LPF_DIRECT = 4;
	public const uint32 X3DAUDIO_CALCULATE_LPF_REVERB = 8;
	public const uint32 X3DAUDIO_CALCULATE_REVERB = 16;
	public const uint32 X3DAUDIO_CALCULATE_DOPPLER = 32;
	public const uint32 X3DAUDIO_CALCULATE_EMITTER_ANGLE = 64;
	public const uint32 X3DAUDIO_CALCULATE_ZEROCENTER = 65536;
	public const uint32 X3DAUDIO_CALCULATE_REDIRECT_TO_LFE = 131072;
}
#endregion

#region Enums

[AllowDuplicates]
public enum XAPO_BUFFER_FLAGS : int32
{
	XAPO_BUFFER_SILENT = 0,
	XAPO_BUFFER_VALID = 1,
}


[AllowDuplicates]
public enum XAUDIO2_FILTER_TYPE : int32
{
	LowPassFilter = 0,
	BandPassFilter = 1,
	HighPassFilter = 2,
	NotchFilter = 3,
	LowPassOnePoleFilter = 4,
	HighPassOnePoleFilter = 5,
}


[AllowDuplicates]
public enum HrtfDirectivityType : int32
{
	OmniDirectional = 0,
	Cardioid = 1,
	Cone = 2,
}


[AllowDuplicates]
public enum HrtfEnvironment : int32
{
	Small = 0,
	Medium = 1,
	Large = 2,
	Outdoors = 3,
}


[AllowDuplicates]
public enum HrtfDistanceDecayType : int32
{
	NaturalDecay = 0,
	CustomDecay = 1,
}

#endregion


#region Structs
[CRepr, Packed(1)]
public struct XAPO_REGISTRATION_PROPERTIES
{
	public Guid clsid;
	public char16[256] FriendlyName;
	public char16[256] CopyrightInfo;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint32 Flags;
	public uint32 MinInputBufferCount;
	public uint32 MaxInputBufferCount;
	public uint32 MinOutputBufferCount;
	public uint32 MaxOutputBufferCount;
}

[CRepr, Packed(1)]
public struct XAPO_LOCKFORPROCESS_PARAMETERS
{
	public WAVEFORMATEX* pFormat;
	public uint32 MaxFrameCount;
}

[CRepr, Packed(1)]
public struct XAPO_PROCESS_BUFFER_PARAMETERS
{
	public void* pBuffer;
	public XAPO_BUFFER_FLAGS BufferFlags;
	public uint32 ValidFrameCount;
}

[CRepr, Packed(1)]
public struct FXEQ_PARAMETERS
{
	public float FrequencyCenter0;
	public float Gain0;
	public float Bandwidth0;
	public float FrequencyCenter1;
	public float Gain1;
	public float Bandwidth1;
	public float FrequencyCenter2;
	public float Gain2;
	public float Bandwidth2;
	public float FrequencyCenter3;
	public float Gain3;
	public float Bandwidth3;
}

[CRepr, Packed(1)]
public struct FXMASTERINGLIMITER_PARAMETERS
{
	public uint32 Release;
	public uint32 Loudness;
}

[CRepr, Packed(1)]
public struct FXREVERB_PARAMETERS
{
	public float Diffusion;
	public float RoomSize;
}

[CRepr, Packed(1)]
public struct FXECHO_INITDATA
{
	public float MaxDelay;
}

[CRepr, Packed(1)]
public struct FXECHO_PARAMETERS
{
	public float WetDryMix;
	public float Feedback;
	public float Delay;
}

[CRepr, Packed(1)]
public struct XAUDIO2_VOICE_DETAILS
{
	public uint32 CreationFlags;
	public uint32 ActiveFlags;
	public uint32 InputChannels;
	public uint32 InputSampleRate;
}

[CRepr, Packed(1)]
public struct XAUDIO2_SEND_DESCRIPTOR
{
	public uint32 Flags;
	public IXAudio2Voice* pOutputVoice;
}

[CRepr, Packed(1)]
public struct XAUDIO2_VOICE_SENDS
{
	public uint32 SendCount;
	public XAUDIO2_SEND_DESCRIPTOR* pSends;
}

[CRepr, Packed(1)]
public struct XAUDIO2_EFFECT_DESCRIPTOR
{
	public IUnknown* pEffect;
	public BOOL InitialState;
	public uint32 OutputChannels;
}

[CRepr, Packed(1)]
public struct XAUDIO2_EFFECT_CHAIN
{
	public uint32 EffectCount;
	public XAUDIO2_EFFECT_DESCRIPTOR* pEffectDescriptors;
}

[CRepr, Packed(1)]
public struct XAUDIO2_FILTER_PARAMETERS
{
	public XAUDIO2_FILTER_TYPE Type;
	public float Frequency;
	public float OneOverQ;
}

[CRepr, Packed(1)]
public struct XAUDIO2_BUFFER
{
	public uint32 Flags;
	public uint32 AudioBytes;
	public uint8* pAudioData;
	public uint32 PlayBegin;
	public uint32 PlayLength;
	public uint32 LoopBegin;
	public uint32 LoopLength;
	public uint32 LoopCount;
	public void* pContext;
}

[CRepr, Packed(1)]
public struct XAUDIO2_BUFFER_WMA
{
	public uint32* pDecodedPacketCumulativeBytes;
	public uint32 PacketCount;
}

[CRepr, Packed(1)]
public struct XAUDIO2_VOICE_STATE
{
	public void* pCurrentBufferContext;
	public uint32 BuffersQueued;
	public uint64 SamplesPlayed;
}

[CRepr, Packed(1)]
public struct XAUDIO2_PERFORMANCE_DATA
{
	public uint64 AudioCyclesSinceLastQuery;
	public uint64 TotalCyclesSinceLastQuery;
	public uint32 MinimumCyclesPerQuantum;
	public uint32 MaximumCyclesPerQuantum;
	public uint32 MemoryUsageInBytes;
	public uint32 CurrentLatencyInSamples;
	public uint32 GlitchesSinceEngineStarted;
	public uint32 ActiveSourceVoiceCount;
	public uint32 TotalSourceVoiceCount;
	public uint32 ActiveSubmixVoiceCount;
	public uint32 ActiveResamplerCount;
	public uint32 ActiveMatrixMixCount;
	public uint32 ActiveXmaSourceVoices;
	public uint32 ActiveXmaStreams;
}

[CRepr, Packed(1)]
public struct XAUDIO2_DEBUG_CONFIGURATION
{
	public uint32 TraceMask;
	public uint32 BreakMask;
	public BOOL LogThreadID;
	public BOOL LogFileline;
	public BOOL LogFunctionName;
	public BOOL LogTiming;
}

[CRepr, Packed(1)]
public struct XAUDIO2FX_VOLUMEMETER_LEVELS
{
	public float* pPeakLevels;
	public float* pRMSLevels;
	public uint32 ChannelCount;
}

[CRepr, Packed(1)]
public struct XAUDIO2FX_REVERB_PARAMETERS
{
	public float WetDryMix;
	public uint32 ReflectionsDelay;
	public uint8 ReverbDelay;
	public uint8 RearDelay;
	public uint8 SideDelay;
	public uint8 PositionLeft;
	public uint8 PositionRight;
	public uint8 PositionMatrixLeft;
	public uint8 PositionMatrixRight;
	public uint8 EarlyDiffusion;
	public uint8 LateDiffusion;
	public uint8 LowEQGain;
	public uint8 LowEQCutoff;
	public uint8 HighEQGain;
	public uint8 HighEQCutoff;
	public float RoomFilterFreq;
	public float RoomFilterMain;
	public float RoomFilterHF;
	public float ReflectionsGain;
	public float ReverbGain;
	public float DecayTime;
	public float Density;
	public float RoomSize;
	public BOOL DisableLateField;
}

[CRepr, Packed(1)]
public struct XAUDIO2FX_REVERB_I3DL2_PARAMETERS
{
	public float WetDryMix;
	public int32 Room;
	public int32 RoomHF;
	public float RoomRolloffFactor;
	public float DecayTime;
	public float DecayHFRatio;
	public int32 Reflections;
	public float ReflectionsDelay;
	public int32 Reverb;
	public float ReverbDelay;
	public float Diffusion;
	public float Density;
	public float HFReference;
}

[CRepr]
public struct HrtfPosition
{
	public float x;
	public float y;
	public float z;
}

[CRepr]
public struct HrtfOrientation
{
	public float[9] element;
}

[CRepr]
public struct HrtfDirectivity
{
	public HrtfDirectivityType type;
	public float scaling;
}

[CRepr]
public struct HrtfDirectivityCardioid
{
	public HrtfDirectivity directivity;
	public float order;
}

[CRepr]
public struct HrtfDirectivityCone
{
	public HrtfDirectivity directivity;
	public float innerAngle;
	public float outerAngle;
}

[CRepr]
public struct HrtfDistanceDecay
{
	public HrtfDistanceDecayType type;
	public float maxGain;
	public float minGain;
	public float unityGainDistance;
	public float cutoffDistance;
}

[CRepr]
public struct HrtfApoInit
{
	public HrtfDistanceDecay* distanceDecay;
	public HrtfDirectivity* directivity;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_FXEQ = .(0xf5e01117, 0xd6c4, 0x485a, 0xa3, 0xf5, 0x69, 0x51, 0x96, 0xf3, 0xdb, 0xfa);


	public const Guid CLSID_FXMasteringLimiter = .(0xc4137916, 0x2be1, 0x46fd, 0x85, 0x99, 0x44, 0x15, 0x36, 0xf4, 0x98, 0x56);


	public const Guid CLSID_FXReverb = .(0x7d9aca56, 0xcb68, 0x4807, 0xb6, 0x32, 0xb1, 0x37, 0x35, 0x2e, 0x85, 0x96);


	public const Guid CLSID_FXEcho = .(0x5039d740, 0xf736, 0x449a, 0x84, 0xd3, 0xa5, 0x62, 0x02, 0x55, 0x7b, 0x87);


	public const Guid CLSID_AudioVolumeMeter = .(0x4fc3b166, 0x972a, 0x40cf, 0xbc, 0x37, 0x7d, 0xb0, 0x3d, 0xb2, 0xfb, 0xa3);


	public const Guid CLSID_AudioReverb = .(0xc2633b16, 0x471b, 0x4498, 0xb8, 0xc5, 0x4f, 0x09, 0x59, 0xe2, 0xec, 0x09);


}
#endregion

#region COM Types
[CRepr]struct IXAPO : IUnknown
{
	public new const Guid IID = .(0xa410b984, 0x9839, 0x4819, 0xa0, 0xbe, 0x28, 0x56, 0xae, 0x6b, 0x3a, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XAPO_REGISTRATION_PROPERTIES** ppRegistrationProperties) GetRegistrationProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pOutputFormat, WAVEFORMATEX* pRequestedInputFormat, WAVEFORMATEX** ppSupportedInputFormat) IsInputFormatSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pInputFormat, WAVEFORMATEX* pRequestedOutputFormat, WAVEFORMATEX** ppSupportedOutputFormat) IsOutputFormatSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pData, uint32 DataByteSize) Initialize;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 InputLockedParameterCount, XAPO_LOCKFORPROCESS_PARAMETERS* pInputLockedParameters, uint32 OutputLockedParameterCount, XAPO_LOCKFORPROCESS_PARAMETERS* pOutputLockedParameters) LockForProcess;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) UnlockForProcess;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 InputProcessParameterCount, XAPO_PROCESS_BUFFER_PARAMETERS* pInputProcessParameters, uint32 OutputProcessParameterCount, XAPO_PROCESS_BUFFER_PARAMETERS* pOutputProcessParameters, BOOL IsEnabled) Process;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 OutputFrameCount) CalcInputFrames;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 InputFrameCount) CalcOutputFrames;
	}


	public HRESULT GetRegistrationProperties(XAPO_REGISTRATION_PROPERTIES** ppRegistrationProperties) mut => VT.[Friend]GetRegistrationProperties(&this, ppRegistrationProperties);

	public HRESULT IsInputFormatSupported(WAVEFORMATEX* pOutputFormat, WAVEFORMATEX* pRequestedInputFormat, WAVEFORMATEX** ppSupportedInputFormat) mut => VT.[Friend]IsInputFormatSupported(&this, pOutputFormat, pRequestedInputFormat, ppSupportedInputFormat);

	public HRESULT IsOutputFormatSupported(WAVEFORMATEX* pInputFormat, WAVEFORMATEX* pRequestedOutputFormat, WAVEFORMATEX** ppSupportedOutputFormat) mut => VT.[Friend]IsOutputFormatSupported(&this, pInputFormat, pRequestedOutputFormat, ppSupportedOutputFormat);

	public HRESULT Initialize(void* pData, uint32 DataByteSize) mut => VT.[Friend]Initialize(&this, pData, DataByteSize);

	public void Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT LockForProcess(uint32 InputLockedParameterCount, XAPO_LOCKFORPROCESS_PARAMETERS* pInputLockedParameters, uint32 OutputLockedParameterCount, XAPO_LOCKFORPROCESS_PARAMETERS* pOutputLockedParameters) mut => VT.[Friend]LockForProcess(&this, InputLockedParameterCount, pInputLockedParameters, OutputLockedParameterCount, pOutputLockedParameters);

	public void UnlockForProcess() mut => VT.[Friend]UnlockForProcess(&this);

	public void Process(uint32 InputProcessParameterCount, XAPO_PROCESS_BUFFER_PARAMETERS* pInputProcessParameters, uint32 OutputProcessParameterCount, XAPO_PROCESS_BUFFER_PARAMETERS* pOutputProcessParameters, BOOL IsEnabled) mut => VT.[Friend]Process(&this, InputProcessParameterCount, pInputProcessParameters, OutputProcessParameterCount, pOutputProcessParameters, IsEnabled);

	public uint32 CalcInputFrames(uint32 OutputFrameCount) mut => VT.[Friend]CalcInputFrames(&this, OutputFrameCount);

	public uint32 CalcOutputFrames(uint32 InputFrameCount) mut => VT.[Friend]CalcOutputFrames(&this, InputFrameCount);
}

[CRepr]struct IXAPOParameters : IUnknown
{
	public new const Guid IID = .(0x26d95c66, 0x80f2, 0x499a, 0xad, 0x54, 0x5a, 0xe7, 0xf0, 0x1c, 0x6d, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pParameters, uint32 ParameterByteSize) SetParameters;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pParameters, uint32 ParameterByteSize) GetParameters;
	}


	public void SetParameters(void* pParameters, uint32 ParameterByteSize) mut => VT.[Friend]SetParameters(&this, pParameters, ParameterByteSize);

	public void GetParameters(void* pParameters, uint32 ParameterByteSize) mut => VT.[Friend]GetParameters(&this, pParameters, ParameterByteSize);
}

[CRepr]struct IXAudio2 : IUnknown
{
	public new const Guid IID = .(0x2b02e3cf, 0x2e0b, 0x4ec3, 0xbe, 0x45, 0x1b, 0x2a, 0x3f, 0xe7, 0x21, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXAudio2EngineCallback* pCallback) RegisterForCallbacks;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IXAudio2EngineCallback* pCallback) UnregisterForCallbacks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXAudio2SourceVoice** ppSourceVoice, WAVEFORMATEX* pSourceFormat, uint32 Flags, float MaxFrequencyRatio, IXAudio2VoiceCallback* pCallback, XAUDIO2_VOICE_SENDS* pSendList, XAUDIO2_EFFECT_CHAIN* pEffectChain) CreateSourceVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXAudio2SubmixVoice** ppSubmixVoice, uint32 InputChannels, uint32 InputSampleRate, uint32 Flags, uint32 ProcessingStage, XAUDIO2_VOICE_SENDS* pSendList, XAUDIO2_EFFECT_CHAIN* pEffectChain) CreateSubmixVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXAudio2MasteringVoice** ppMasteringVoice, uint32 InputChannels, uint32 InputSampleRate, uint32 Flags, PWSTR szDeviceId, XAUDIO2_EFFECT_CHAIN* pEffectChain, AUDIO_STREAM_CATEGORY StreamCategory) CreateMasteringVoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartEngine;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) StopEngine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 OperationSet) CommitChanges;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, XAUDIO2_PERFORMANCE_DATA* pPerfData) GetPerformanceData;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, XAUDIO2_DEBUG_CONFIGURATION* pDebugConfiguration, void* pReserved) SetDebugConfiguration;
	}


	public HRESULT RegisterForCallbacks(IXAudio2EngineCallback* pCallback) mut => VT.[Friend]RegisterForCallbacks(&this, pCallback);

	public void UnregisterForCallbacks(IXAudio2EngineCallback* pCallback) mut => VT.[Friend]UnregisterForCallbacks(&this, pCallback);

	public HRESULT CreateSourceVoice(IXAudio2SourceVoice** ppSourceVoice, WAVEFORMATEX* pSourceFormat, uint32 Flags, float MaxFrequencyRatio, IXAudio2VoiceCallback* pCallback, XAUDIO2_VOICE_SENDS* pSendList, XAUDIO2_EFFECT_CHAIN* pEffectChain) mut => VT.[Friend]CreateSourceVoice(&this, ppSourceVoice, pSourceFormat, Flags, MaxFrequencyRatio, pCallback, pSendList, pEffectChain);

	public HRESULT CreateSubmixVoice(IXAudio2SubmixVoice** ppSubmixVoice, uint32 InputChannels, uint32 InputSampleRate, uint32 Flags, uint32 ProcessingStage, XAUDIO2_VOICE_SENDS* pSendList, XAUDIO2_EFFECT_CHAIN* pEffectChain) mut => VT.[Friend]CreateSubmixVoice(&this, ppSubmixVoice, InputChannels, InputSampleRate, Flags, ProcessingStage, pSendList, pEffectChain);

	public HRESULT CreateMasteringVoice(IXAudio2MasteringVoice** ppMasteringVoice, uint32 InputChannels, uint32 InputSampleRate, uint32 Flags, PWSTR szDeviceId, XAUDIO2_EFFECT_CHAIN* pEffectChain, AUDIO_STREAM_CATEGORY StreamCategory) mut => VT.[Friend]CreateMasteringVoice(&this, ppMasteringVoice, InputChannels, InputSampleRate, Flags, szDeviceId, pEffectChain, StreamCategory);

	public HRESULT StartEngine() mut => VT.[Friend]StartEngine(&this);

	public void StopEngine() mut => VT.[Friend]StopEngine(&this);

	public HRESULT CommitChanges(uint32 OperationSet) mut => VT.[Friend]CommitChanges(&this, OperationSet);

	public void GetPerformanceData(XAUDIO2_PERFORMANCE_DATA* pPerfData) mut => VT.[Friend]GetPerformanceData(&this, pPerfData);

	public void SetDebugConfiguration(XAUDIO2_DEBUG_CONFIGURATION* pDebugConfiguration, void* pReserved) mut => VT.[Friend]SetDebugConfiguration(&this, pDebugConfiguration, pReserved);
}

[CRepr]struct IXAudio2Extension : IUnknown
{
	public new const Guid IID = .(0x84ac29bb, 0xd619, 0x44d2, 0xb1, 0x97, 0xe4, 0xac, 0xf7, 0xdf, 0x3e, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32* quantumNumerator, uint32* quantumDenominator) GetProcessingQuantum;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32* processor) GetProcessor;
	}


	public void GetProcessingQuantum(uint32* quantumNumerator, uint32* quantumDenominator) mut => VT.[Friend]GetProcessingQuantum(&this, quantumNumerator, quantumDenominator);

	public void GetProcessor(uint32* processor) mut => VT.[Friend]GetProcessor(&this, processor);
}

[CRepr]struct IXAudio2Voice
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, XAUDIO2_VOICE_DETAILS* pVoiceDetails) GetVoiceDetails;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XAUDIO2_VOICE_SENDS* pSendList) SetOutputVoices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XAUDIO2_EFFECT_CHAIN* pEffectChain) SetEffectChain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EffectIndex, uint32 OperationSet) EnableEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EffectIndex, uint32 OperationSet) DisableEffect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 EffectIndex, BOOL* pEnabled) GetEffectState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EffectIndex, void* pParameters, uint32 ParametersByteSize, uint32 OperationSet) SetEffectParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EffectIndex, void* pParameters, uint32 ParametersByteSize) GetEffectParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XAUDIO2_FILTER_PARAMETERS* pParameters, uint32 OperationSet) SetFilterParameters;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, XAUDIO2_FILTER_PARAMETERS* pParameters) GetFilterParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXAudio2Voice* pDestinationVoice, XAUDIO2_FILTER_PARAMETERS* pParameters, uint32 OperationSet) SetOutputFilterParameters;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IXAudio2Voice* pDestinationVoice, XAUDIO2_FILTER_PARAMETERS* pParameters) GetOutputFilterParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Volume, uint32 OperationSet) SetVolume;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, float* pVolume) GetVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Channels, float* pVolumes, uint32 OperationSet) SetChannelVolumes;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 Channels, float* pVolumes) GetChannelVolumes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXAudio2Voice* pDestinationVoice, uint32 SourceChannels, uint32 DestinationChannels, float* pLevelMatrix, uint32 OperationSet) SetOutputMatrix;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IXAudio2Voice* pDestinationVoice, uint32 SourceChannels, uint32 DestinationChannels, float* pLevelMatrix) GetOutputMatrix;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) DestroyVoice;
	}


	public void GetVoiceDetails(XAUDIO2_VOICE_DETAILS* pVoiceDetails) mut => VT.[Friend]GetVoiceDetails(&this, pVoiceDetails);

	public HRESULT SetOutputVoices(XAUDIO2_VOICE_SENDS* pSendList) mut => VT.[Friend]SetOutputVoices(&this, pSendList);

	public HRESULT SetEffectChain(XAUDIO2_EFFECT_CHAIN* pEffectChain) mut => VT.[Friend]SetEffectChain(&this, pEffectChain);

	public HRESULT EnableEffect(uint32 EffectIndex, uint32 OperationSet) mut => VT.[Friend]EnableEffect(&this, EffectIndex, OperationSet);

	public HRESULT DisableEffect(uint32 EffectIndex, uint32 OperationSet) mut => VT.[Friend]DisableEffect(&this, EffectIndex, OperationSet);

	public void GetEffectState(uint32 EffectIndex, BOOL* pEnabled) mut => VT.[Friend]GetEffectState(&this, EffectIndex, pEnabled);

	public HRESULT SetEffectParameters(uint32 EffectIndex, void* pParameters, uint32 ParametersByteSize, uint32 OperationSet) mut => VT.[Friend]SetEffectParameters(&this, EffectIndex, pParameters, ParametersByteSize, OperationSet);

	public HRESULT GetEffectParameters(uint32 EffectIndex, void* pParameters, uint32 ParametersByteSize) mut => VT.[Friend]GetEffectParameters(&this, EffectIndex, pParameters, ParametersByteSize);

	public HRESULT SetFilterParameters(XAUDIO2_FILTER_PARAMETERS* pParameters, uint32 OperationSet) mut => VT.[Friend]SetFilterParameters(&this, pParameters, OperationSet);

	public void GetFilterParameters(XAUDIO2_FILTER_PARAMETERS* pParameters) mut => VT.[Friend]GetFilterParameters(&this, pParameters);

	public HRESULT SetOutputFilterParameters(IXAudio2Voice* pDestinationVoice, XAUDIO2_FILTER_PARAMETERS* pParameters, uint32 OperationSet) mut => VT.[Friend]SetOutputFilterParameters(&this, pDestinationVoice, pParameters, OperationSet);

	public void GetOutputFilterParameters(IXAudio2Voice* pDestinationVoice, XAUDIO2_FILTER_PARAMETERS* pParameters) mut => VT.[Friend]GetOutputFilterParameters(&this, pDestinationVoice, pParameters);

	public HRESULT SetVolume(float Volume, uint32 OperationSet) mut => VT.[Friend]SetVolume(&this, Volume, OperationSet);

	public void GetVolume(float* pVolume) mut => VT.[Friend]GetVolume(&this, pVolume);

	public HRESULT SetChannelVolumes(uint32 Channels, float* pVolumes, uint32 OperationSet) mut => VT.[Friend]SetChannelVolumes(&this, Channels, pVolumes, OperationSet);

	public void GetChannelVolumes(uint32 Channels, float* pVolumes) mut => VT.[Friend]GetChannelVolumes(&this, Channels, pVolumes);

	public HRESULT SetOutputMatrix(IXAudio2Voice* pDestinationVoice, uint32 SourceChannels, uint32 DestinationChannels, float* pLevelMatrix, uint32 OperationSet) mut => VT.[Friend]SetOutputMatrix(&this, pDestinationVoice, SourceChannels, DestinationChannels, pLevelMatrix, OperationSet);

	public void GetOutputMatrix(IXAudio2Voice* pDestinationVoice, uint32 SourceChannels, uint32 DestinationChannels, float* pLevelMatrix) mut => VT.[Friend]GetOutputMatrix(&this, pDestinationVoice, SourceChannels, DestinationChannels, pLevelMatrix);

	public void DestroyVoice() mut => VT.[Friend]DestroyVoice(&this);
}

[CRepr]struct IXAudio2SourceVoice : IXAudio2Voice
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXAudio2Voice.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags, uint32 OperationSet) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags, uint32 OperationSet) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XAUDIO2_BUFFER* pBuffer, XAUDIO2_BUFFER_WMA* pBufferWMA) SubmitSourceBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlushSourceBuffers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Discontinuity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 OperationSet) ExitLoop;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, XAUDIO2_VOICE_STATE* pVoiceState, uint32 Flags) GetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Ratio, uint32 OperationSet) SetFrequencyRatio;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, float* pRatio) GetFrequencyRatio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NewSourceSampleRate) SetSourceSampleRate;
	}


	public HRESULT Start(uint32 Flags, uint32 OperationSet) mut => VT.[Friend]Start(&this, Flags, OperationSet);

	public HRESULT Stop(uint32 Flags, uint32 OperationSet) mut => VT.[Friend]Stop(&this, Flags, OperationSet);

	public HRESULT SubmitSourceBuffer(XAUDIO2_BUFFER* pBuffer, XAUDIO2_BUFFER_WMA* pBufferWMA) mut => VT.[Friend]SubmitSourceBuffer(&this, pBuffer, pBufferWMA);

	public HRESULT FlushSourceBuffers() mut => VT.[Friend]FlushSourceBuffers(&this);

	public HRESULT Discontinuity() mut => VT.[Friend]Discontinuity(&this);

	public HRESULT ExitLoop(uint32 OperationSet) mut => VT.[Friend]ExitLoop(&this, OperationSet);

	public void GetState(XAUDIO2_VOICE_STATE* pVoiceState, uint32 Flags) mut => VT.[Friend]GetState(&this, pVoiceState, Flags);

	public HRESULT SetFrequencyRatio(float Ratio, uint32 OperationSet) mut => VT.[Friend]SetFrequencyRatio(&this, Ratio, OperationSet);

	public void GetFrequencyRatio(float* pRatio) mut => VT.[Friend]GetFrequencyRatio(&this, pRatio);

	public HRESULT SetSourceSampleRate(uint32 NewSourceSampleRate) mut => VT.[Friend]SetSourceSampleRate(&this, NewSourceSampleRate);
}

[CRepr]struct IXAudio2SubmixVoice : IXAudio2Voice
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXAudio2Voice.VTable
	{
	}

}

[CRepr]struct IXAudio2MasteringVoice : IXAudio2Voice
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXAudio2Voice.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pChannelmask) GetChannelMask;
	}


	public HRESULT GetChannelMask(uint32* pChannelmask) mut => VT.[Friend]GetChannelMask(&this, pChannelmask);
}

[CRepr]struct IXAudio2EngineCallback
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnProcessingPassStart;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnProcessingPassEnd;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, HRESULT Error) OnCriticalError;
	}


	public void OnProcessingPassStart() mut => VT.[Friend]OnProcessingPassStart(&this);

	public void OnProcessingPassEnd() mut => VT.[Friend]OnProcessingPassEnd(&this);

	public void OnCriticalError(HRESULT Error) mut => VT.[Friend]OnCriticalError(&this, Error);
}

[CRepr]struct IXAudio2VoiceCallback
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 BytesRequired) OnVoiceProcessingPassStart;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnVoiceProcessingPassEnd;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnStreamEnd;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pBufferContext) OnBufferStart;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pBufferContext) OnBufferEnd;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pBufferContext) OnLoopEnd;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pBufferContext, HRESULT Error) OnVoiceError;
	}


	public void OnVoiceProcessingPassStart(uint32 BytesRequired) mut => VT.[Friend]OnVoiceProcessingPassStart(&this, BytesRequired);

	public void OnVoiceProcessingPassEnd() mut => VT.[Friend]OnVoiceProcessingPassEnd(&this);

	public void OnStreamEnd() mut => VT.[Friend]OnStreamEnd(&this);

	public void OnBufferStart(void* pBufferContext) mut => VT.[Friend]OnBufferStart(&this, pBufferContext);

	public void OnBufferEnd(void* pBufferContext) mut => VT.[Friend]OnBufferEnd(&this, pBufferContext);

	public void OnLoopEnd(void* pBufferContext) mut => VT.[Friend]OnLoopEnd(&this, pBufferContext);

	public void OnVoiceError(void* pBufferContext, HRESULT Error) mut => VT.[Friend]OnVoiceError(&this, pBufferContext, Error);
}

[CRepr]struct IXAPOHrtfParameters : IUnknown
{
	public new const Guid IID = .(0x15b3cd66, 0xe9de, 0x4464, 0xb6, 0xe6, 0x2b, 0xc3, 0xcf, 0x63, 0xd4, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HrtfPosition* position) SetSourcePosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HrtfOrientation* orientation) SetSourceOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float gain) SetSourceGain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HrtfEnvironment environment) SetEnvironment;
	}


	public HRESULT SetSourcePosition(HrtfPosition* position) mut => VT.[Friend]SetSourcePosition(&this, position);

	public HRESULT SetSourceOrientation(HrtfOrientation* orientation) mut => VT.[Friend]SetSourceOrientation(&this, orientation);

	public HRESULT SetSourceGain(float gain) mut => VT.[Friend]SetSourceGain(&this, gain);

	public HRESULT SetEnvironment(HrtfEnvironment environment) mut => VT.[Friend]SetEnvironment(&this, environment);
}

#endregion

#region Functions
public static
{
	[Import("XAudio2_8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateFX(in Guid clsid, IUnknown** pEffect, void* pInitDat, uint32 InitDataByteSize);

	[Import("XAudio2_8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT XAudio2CreateWithVersionInfo(IXAudio2** ppXAudio2, uint32 Flags, uint32 XAudio2Processor, uint32 ntddiVersion);

	[Import("XAudio2_8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateAudioVolumeMeter(IUnknown** ppApo);

	[Import("XAudio2_8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateAudioReverb(IUnknown** ppApo);

	[Import("HrtfApo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateHrtfApo(HrtfApoInit* init, IXAPO** xApo);

}
#endregion
