using Win32.Foundation;
using Win32.Media.Audio;
using Win32.Graphics.Direct3D;
using Win32.System.Com;
using System;

namespace Win32.Media.Audio.DirectSound;

#region Constants
public static
{
	public const uint32 DIRECTSOUND_VERSION = 1792;
	public const uint32 _FACDS = 2168;
	public const Guid CLSID_DirectSound = .(0x47d4d946, 0x62e8, 0x11cf, 0x93, 0xbc, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid CLSID_DirectSound8 = .(0x3901cc3f, 0x84b5, 0x4fa4, 0xba, 0x35, 0xaa, 0x81, 0x72, 0xb8, 0xa0, 0x9b);
	public const Guid CLSID_DirectSoundCapture = .(0xb0210780, 0x89cd, 0x11d0, 0xaf, 0x08, 0x00, 0xa0, 0xc9, 0x25, 0xcd, 0x16);
	public const Guid CLSID_DirectSoundCapture8 = .(0xe4bcac13, 0x7f99, 0x4908, 0x9a, 0x8e, 0x74, 0xe3, 0xbf, 0x24, 0xb6, 0xe1);
	public const Guid CLSID_DirectSoundFullDuplex = .(0xfea4300c, 0x7959, 0x4147, 0xb2, 0x6a, 0x23, 0x77, 0xb9, 0xe7, 0xa9, 0x1d);
	public const Guid DSDEVID_DefaultPlayback = .(0xdef00000, 0x9c6d, 0x47ed, 0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03);
	public const Guid DSDEVID_DefaultCapture = .(0xdef00001, 0x9c6d, 0x47ed, 0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03);
	public const Guid DSDEVID_DefaultVoicePlayback = .(0xdef00002, 0x9c6d, 0x47ed, 0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03);
	public const Guid DSDEVID_DefaultVoiceCapture = .(0xdef00003, 0x9c6d, 0x47ed, 0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03);
	public const uint32 DSFX_LOCHARDWARE = 1;
	public const uint32 DSFX_LOCSOFTWARE = 2;
	public const uint32 DSCFX_LOCHARDWARE = 1;
	public const uint32 DSCFX_LOCSOFTWARE = 2;
	public const uint32 DSCFXR_LOCHARDWARE = 16;
	public const uint32 DSCFXR_LOCSOFTWARE = 32;
	public const Guid GUID_All_Objects = .(0xaa114de5, 0xc262, 0x4169, 0xa1, 0xc8, 0x23, 0xd6, 0x98, 0xcc, 0x73, 0xb5);
	public const uint32 KSPROPERTY_SUPPORT_GET = 1;
	public const uint32 KSPROPERTY_SUPPORT_SET = 2;
	public const uint32 DSFXGARGLE_WAVE_TRIANGLE = 0;
	public const uint32 DSFXGARGLE_WAVE_SQUARE = 1;
	public const uint32 DSFXGARGLE_RATEHZ_MIN = 1;
	public const uint32 DSFXGARGLE_RATEHZ_MAX = 1000;
	public const uint32 DSFXCHORUS_WAVE_TRIANGLE = 0;
	public const uint32 DSFXCHORUS_WAVE_SIN = 1;
	public const float DSFXCHORUS_WETDRYMIX_MIN = 0f;
	public const float DSFXCHORUS_WETDRYMIX_MAX = 100f;
	public const float DSFXCHORUS_DEPTH_MIN = 0f;
	public const float DSFXCHORUS_DEPTH_MAX = 100f;
	public const float DSFXCHORUS_FEEDBACK_MIN = -99f;
	public const float DSFXCHORUS_FEEDBACK_MAX = 99f;
	public const float DSFXCHORUS_FREQUENCY_MIN = 0f;
	public const float DSFXCHORUS_FREQUENCY_MAX = 10f;
	public const float DSFXCHORUS_DELAY_MIN = 0f;
	public const float DSFXCHORUS_DELAY_MAX = 20f;
	public const uint32 DSFXCHORUS_PHASE_MIN = 0;
	public const uint32 DSFXCHORUS_PHASE_MAX = 4;
	public const uint32 DSFXCHORUS_PHASE_NEG_180 = 0;
	public const uint32 DSFXCHORUS_PHASE_NEG_90 = 1;
	public const uint32 DSFXCHORUS_PHASE_ZERO = 2;
	public const uint32 DSFXCHORUS_PHASE_90 = 3;
	public const uint32 DSFXCHORUS_PHASE_180 = 4;
	public const uint32 DSFXFLANGER_WAVE_TRIANGLE = 0;
	public const uint32 DSFXFLANGER_WAVE_SIN = 1;
	public const float DSFXFLANGER_WETDRYMIX_MIN = 0f;
	public const float DSFXFLANGER_WETDRYMIX_MAX = 100f;
	public const float DSFXFLANGER_FREQUENCY_MIN = 0f;
	public const float DSFXFLANGER_FREQUENCY_MAX = 10f;
	public const float DSFXFLANGER_DEPTH_MIN = 0f;
	public const float DSFXFLANGER_DEPTH_MAX = 100f;
	public const uint32 DSFXFLANGER_PHASE_MIN = 0;
	public const uint32 DSFXFLANGER_PHASE_MAX = 4;
	public const float DSFXFLANGER_FEEDBACK_MIN = -99f;
	public const float DSFXFLANGER_FEEDBACK_MAX = 99f;
	public const float DSFXFLANGER_DELAY_MIN = 0f;
	public const float DSFXFLANGER_DELAY_MAX = 4f;
	public const uint32 DSFXFLANGER_PHASE_NEG_180 = 0;
	public const uint32 DSFXFLANGER_PHASE_NEG_90 = 1;
	public const uint32 DSFXFLANGER_PHASE_ZERO = 2;
	public const uint32 DSFXFLANGER_PHASE_90 = 3;
	public const uint32 DSFXFLANGER_PHASE_180 = 4;
	public const float DSFXECHO_WETDRYMIX_MIN = 0f;
	public const float DSFXECHO_WETDRYMIX_MAX = 100f;
	public const float DSFXECHO_FEEDBACK_MIN = 0f;
	public const float DSFXECHO_FEEDBACK_MAX = 100f;
	public const float DSFXECHO_LEFTDELAY_MIN = 1f;
	public const float DSFXECHO_LEFTDELAY_MAX = 2000f;
	public const float DSFXECHO_RIGHTDELAY_MIN = 1f;
	public const float DSFXECHO_RIGHTDELAY_MAX = 2000f;
	public const uint32 DSFXECHO_PANDELAY_MIN = 0;
	public const uint32 DSFXECHO_PANDELAY_MAX = 1;
	public const float DSFXDISTORTION_GAIN_MIN = -60f;
	public const float DSFXDISTORTION_GAIN_MAX = 0f;
	public const float DSFXDISTORTION_EDGE_MIN = 0f;
	public const float DSFXDISTORTION_EDGE_MAX = 100f;
	public const float DSFXDISTORTION_POSTEQCENTERFREQUENCY_MIN = 100f;
	public const float DSFXDISTORTION_POSTEQCENTERFREQUENCY_MAX = 8000f;
	public const float DSFXDISTORTION_POSTEQBANDWIDTH_MIN = 100f;
	public const float DSFXDISTORTION_POSTEQBANDWIDTH_MAX = 8000f;
	public const float DSFXDISTORTION_PRELOWPASSCUTOFF_MIN = 100f;
	public const float DSFXDISTORTION_PRELOWPASSCUTOFF_MAX = 8000f;
	public const float DSFXCOMPRESSOR_GAIN_MIN = -60f;
	public const float DSFXCOMPRESSOR_GAIN_MAX = 60f;
	public const float DSFXCOMPRESSOR_ATTACK_MIN = 0.01f;
	public const float DSFXCOMPRESSOR_ATTACK_MAX = 500f;
	public const float DSFXCOMPRESSOR_RELEASE_MIN = 50f;
	public const float DSFXCOMPRESSOR_RELEASE_MAX = 3000f;
	public const float DSFXCOMPRESSOR_THRESHOLD_MIN = -60f;
	public const float DSFXCOMPRESSOR_THRESHOLD_MAX = 0f;
	public const float DSFXCOMPRESSOR_RATIO_MIN = 1f;
	public const float DSFXCOMPRESSOR_RATIO_MAX = 100f;
	public const float DSFXCOMPRESSOR_PREDELAY_MIN = 0f;
	public const float DSFXCOMPRESSOR_PREDELAY_MAX = 4f;
	public const float DSFXPARAMEQ_CENTER_MIN = 80f;
	public const float DSFXPARAMEQ_CENTER_MAX = 16000f;
	public const float DSFXPARAMEQ_BANDWIDTH_MIN = 1f;
	public const float DSFXPARAMEQ_BANDWIDTH_MAX = 36f;
	public const float DSFXPARAMEQ_GAIN_MIN = -15f;
	public const float DSFXPARAMEQ_GAIN_MAX = 15f;
	public const int32 DSFX_I3DL2REVERB_ROOM_MIN = -10000;
	public const uint32 DSFX_I3DL2REVERB_ROOM_MAX = 0;
	public const int32 DSFX_I3DL2REVERB_ROOM_DEFAULT = -1000;
	public const int32 DSFX_I3DL2REVERB_ROOMHF_MIN = -10000;
	public const uint32 DSFX_I3DL2REVERB_ROOMHF_MAX = 0;
	public const int32 DSFX_I3DL2REVERB_ROOMHF_DEFAULT = -100;
	public const float DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_MIN = 0f;
	public const float DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_MAX = 10f;
	public const float DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_DEFAULT = 0f;
	public const float DSFX_I3DL2REVERB_DECAYTIME_MIN = 0.1f;
	public const float DSFX_I3DL2REVERB_DECAYTIME_MAX = 20f;
	public const float DSFX_I3DL2REVERB_DECAYTIME_DEFAULT = 1.49f;
	public const float DSFX_I3DL2REVERB_DECAYHFRATIO_MIN = 0.1f;
	public const float DSFX_I3DL2REVERB_DECAYHFRATIO_MAX = 2f;
	public const float DSFX_I3DL2REVERB_DECAYHFRATIO_DEFAULT = 0.83f;
	public const int32 DSFX_I3DL2REVERB_REFLECTIONS_MIN = -10000;
	public const uint32 DSFX_I3DL2REVERB_REFLECTIONS_MAX = 1000;
	public const int32 DSFX_I3DL2REVERB_REFLECTIONS_DEFAULT = -2602;
	public const float DSFX_I3DL2REVERB_REFLECTIONSDELAY_MIN = 0f;
	public const float DSFX_I3DL2REVERB_REFLECTIONSDELAY_MAX = 0.3f;
	public const float DSFX_I3DL2REVERB_REFLECTIONSDELAY_DEFAULT = 0.007f;
	public const int32 DSFX_I3DL2REVERB_REVERB_MIN = -10000;
	public const uint32 DSFX_I3DL2REVERB_REVERB_MAX = 2000;
	public const uint32 DSFX_I3DL2REVERB_REVERB_DEFAULT = 200;
	public const float DSFX_I3DL2REVERB_REVERBDELAY_MIN = 0f;
	public const float DSFX_I3DL2REVERB_REVERBDELAY_MAX = 0.1f;
	public const float DSFX_I3DL2REVERB_REVERBDELAY_DEFAULT = 0.011f;
	public const float DSFX_I3DL2REVERB_DIFFUSION_MIN = 0f;
	public const float DSFX_I3DL2REVERB_DIFFUSION_MAX = 100f;
	public const float DSFX_I3DL2REVERB_DIFFUSION_DEFAULT = 100f;
	public const float DSFX_I3DL2REVERB_DENSITY_MIN = 0f;
	public const float DSFX_I3DL2REVERB_DENSITY_MAX = 100f;
	public const float DSFX_I3DL2REVERB_DENSITY_DEFAULT = 100f;
	public const float DSFX_I3DL2REVERB_HFREFERENCE_MIN = 20f;
	public const float DSFX_I3DL2REVERB_HFREFERENCE_MAX = 20000f;
	public const float DSFX_I3DL2REVERB_HFREFERENCE_DEFAULT = 5000f;
	public const uint32 DSFX_I3DL2REVERB_QUALITY_MIN = 0;
	public const uint32 DSFX_I3DL2REVERB_QUALITY_MAX = 3;
	public const uint32 DSFX_I3DL2REVERB_QUALITY_DEFAULT = 2;
	public const float DSFX_WAVESREVERB_INGAIN_MIN = -96f;
	public const float DSFX_WAVESREVERB_INGAIN_MAX = 0f;
	public const float DSFX_WAVESREVERB_INGAIN_DEFAULT = 0f;
	public const float DSFX_WAVESREVERB_REVERBMIX_MIN = -96f;
	public const float DSFX_WAVESREVERB_REVERBMIX_MAX = 0f;
	public const float DSFX_WAVESREVERB_REVERBMIX_DEFAULT = 0f;
	public const float DSFX_WAVESREVERB_REVERBTIME_MIN = 0.001f;
	public const float DSFX_WAVESREVERB_REVERBTIME_MAX = 3000f;
	public const float DSFX_WAVESREVERB_REVERBTIME_DEFAULT = 1000f;
	public const float DSFX_WAVESREVERB_HIGHFREQRTRATIO_MIN = 0.001f;
	public const float DSFX_WAVESREVERB_HIGHFREQRTRATIO_MAX = 0.999f;
	public const float DSFX_WAVESREVERB_HIGHFREQRTRATIO_DEFAULT = 0.001f;
	public const uint32 DSCFX_AEC_MODE_PASS_THROUGH = 0;
	public const uint32 DSCFX_AEC_MODE_HALF_DUPLEX = 1;
	public const uint32 DSCFX_AEC_MODE_FULL_DUPLEX = 2;
	public const uint32 DSCFX_AEC_STATUS_HISTORY_UNINITIALIZED = 0;
	public const uint32 DSCFX_AEC_STATUS_HISTORY_CONTINUOUSLY_CONVERGED = 1;
	public const uint32 DSCFX_AEC_STATUS_HISTORY_PREVIOUSLY_DIVERGED = 2;
	public const uint32 DSCFX_AEC_STATUS_CURRENTLY_CONVERGED = 8;
	public const HRESULT DS_NO_VIRTUALIZATION = 142082058;
	public const uint32 DSCAPS_PRIMARYMONO = 1;
	public const uint32 DSCAPS_PRIMARYSTEREO = 2;
	public const uint32 DSCAPS_PRIMARY8BIT = 4;
	public const uint32 DSCAPS_PRIMARY16BIT = 8;
	public const uint32 DSCAPS_CONTINUOUSRATE = 16;
	public const uint32 DSCAPS_EMULDRIVER = 32;
	public const uint32 DSCAPS_CERTIFIED = 64;
	public const uint32 DSCAPS_SECONDARYMONO = 256;
	public const uint32 DSCAPS_SECONDARYSTEREO = 512;
	public const uint32 DSCAPS_SECONDARY8BIT = 1024;
	public const uint32 DSCAPS_SECONDARY16BIT = 2048;
	public const uint32 DSSCL_NORMAL = 1;
	public const uint32 DSSCL_PRIORITY = 2;
	public const uint32 DSSCL_EXCLUSIVE = 3;
	public const uint32 DSSCL_WRITEPRIMARY = 4;
	public const uint32 DSSPEAKER_DIRECTOUT = 0;
	public const uint32 DSSPEAKER_HEADPHONE = 1;
	public const uint32 DSSPEAKER_MONO = 2;
	public const uint32 DSSPEAKER_QUAD = 3;
	public const uint32 DSSPEAKER_STEREO = 4;
	public const uint32 DSSPEAKER_SURROUND = 5;
	public const uint32 DSSPEAKER_5POINT1 = 6;
	public const uint32 DSSPEAKER_7POINT1 = 7;
	public const uint32 DSSPEAKER_7POINT1_SURROUND = 8;
	public const uint32 DSSPEAKER_5POINT1_SURROUND = 9;
	public const uint32 DSSPEAKER_7POINT1_WIDE = 7;
	public const uint32 DSSPEAKER_5POINT1_BACK = 6;
	public const uint32 DSSPEAKER_GEOMETRY_MIN = 5;
	public const uint32 DSSPEAKER_GEOMETRY_NARROW = 10;
	public const uint32 DSSPEAKER_GEOMETRY_WIDE = 20;
	public const uint32 DSSPEAKER_GEOMETRY_MAX = 180;
	public const uint32 DSBCAPS_PRIMARYBUFFER = 1;
	public const uint32 DSBCAPS_STATIC = 2;
	public const uint32 DSBCAPS_LOCHARDWARE = 4;
	public const uint32 DSBCAPS_LOCSOFTWARE = 8;
	public const uint32 DSBCAPS_CTRL3D = 16;
	public const uint32 DSBCAPS_CTRLFREQUENCY = 32;
	public const uint32 DSBCAPS_CTRLPAN = 64;
	public const uint32 DSBCAPS_CTRLVOLUME = 128;
	public const uint32 DSBCAPS_CTRLPOSITIONNOTIFY = 256;
	public const uint32 DSBCAPS_CTRLFX = 512;
	public const uint32 DSBCAPS_STICKYFOCUS = 16384;
	public const uint32 DSBCAPS_GLOBALFOCUS = 32768;
	public const uint32 DSBCAPS_GETCURRENTPOSITION2 = 65536;
	public const uint32 DSBCAPS_MUTE3DATMAXDISTANCE = 131072;
	public const uint32 DSBCAPS_LOCDEFER = 262144;
	public const uint32 DSBCAPS_TRUEPLAYPOSITION = 524288;
	public const uint32 DSBPLAY_LOOPING = 1;
	public const uint32 DSBPLAY_LOCHARDWARE = 2;
	public const uint32 DSBPLAY_LOCSOFTWARE = 4;
	public const uint32 DSBPLAY_TERMINATEBY_TIME = 8;
	public const uint64 DSBPLAY_TERMINATEBY_DISTANCE = 16;
	public const uint64 DSBPLAY_TERMINATEBY_PRIORITY = 32;
	public const uint32 DSBSTATUS_PLAYING = 1;
	public const uint32 DSBSTATUS_BUFFERLOST = 2;
	public const uint32 DSBSTATUS_LOOPING = 4;
	public const uint32 DSBSTATUS_LOCHARDWARE = 8;
	public const uint32 DSBSTATUS_LOCSOFTWARE = 16;
	public const uint32 DSBSTATUS_TERMINATED = 32;
	public const uint32 DSBLOCK_FROMWRITECURSOR = 1;
	public const uint32 DSBLOCK_ENTIREBUFFER = 2;
	public const uint32 DSBFREQUENCY_ORIGINAL = 0;
	public const uint32 DSBFREQUENCY_MIN = 100;
	public const uint32 DSBFREQUENCY_MAX = 200000;
	public const int32 DSBPAN_LEFT = -10000;
	public const uint32 DSBPAN_CENTER = 0;
	public const uint32 DSBPAN_RIGHT = 10000;
	public const int32 DSBVOLUME_MIN = -10000;
	public const uint32 DSBVOLUME_MAX = 0;
	public const uint32 DSBSIZE_MIN = 4;
	public const uint32 DSBSIZE_MAX = 268435455;
	public const uint32 DSBSIZE_FX_MIN = 150;
	public const uint32 DSBNOTIFICATIONS_MAX = 100000;
	public const uint32 DS3DMODE_NORMAL = 0;
	public const uint32 DS3DMODE_HEADRELATIVE = 1;
	public const uint32 DS3DMODE_DISABLE = 2;
	public const uint32 DS3D_IMMEDIATE = 0;
	public const uint32 DS3D_DEFERRED = 1;
	public const float DS3D_DEFAULTDISTANCEFACTOR = 1f;
	public const float DS3D_MINROLLOFFFACTOR = 0f;
	public const float DS3D_MAXROLLOFFFACTOR = 10f;
	public const float DS3D_DEFAULTROLLOFFFACTOR = 1f;
	public const float DS3D_MINDOPPLERFACTOR = 0f;
	public const float DS3D_MAXDOPPLERFACTOR = 10f;
	public const float DS3D_DEFAULTDOPPLERFACTOR = 1f;
	public const float DS3D_DEFAULTMINDISTANCE = 1f;
	public const float DS3D_DEFAULTMAXDISTANCE = 1000000000f;
	public const uint32 DS3D_MINCONEANGLE = 0;
	public const uint32 DS3D_MAXCONEANGLE = 360;
	public const uint32 DS3D_DEFAULTCONEANGLE = 360;
	public const uint32 DS3D_DEFAULTCONEOUTSIDEVOLUME = 0;
	public const uint32 DSCCAPS_EMULDRIVER = 32;
	public const uint32 DSCCAPS_CERTIFIED = 64;
	public const uint32 DSCCAPS_MULTIPLECAPTURE = 1;
	public const uint32 DSCBCAPS_WAVEMAPPED = 2147483648;
	public const uint32 DSCBCAPS_CTRLFX = 512;
	public const uint32 DSCBLOCK_ENTIREBUFFER = 1;
	public const uint32 DSCBSTATUS_CAPTURING = 1;
	public const uint32 DSCBSTATUS_LOOPING = 2;
	public const uint32 DSCBSTART_LOOPING = 1;
	public const uint32 DSBPN_OFFSETSTOP = 4294967295;
	public const uint32 DS_CERTIFIED = 0;
	public const uint32 DS_UNCERTIFIED = 1;
	public const Guid DS3DALG_NO_VIRTUALIZATION = .(0xc241333f, 0x1c1b, 0x11d2, 0x94, 0xf5, 0x00, 0xc0, 0x4f, 0xc2, 0x8a, 0xca);
	public const Guid DS3DALG_HRTF_FULL = .(0xc2413340, 0x1c1b, 0x11d2, 0x94, 0xf5, 0x00, 0xc0, 0x4f, 0xc2, 0x8a, 0xca);
	public const Guid DS3DALG_HRTF_LIGHT = .(0xc2413342, 0x1c1b, 0x11d2, 0x94, 0xf5, 0x00, 0xc0, 0x4f, 0xc2, 0x8a, 0xca);
	public const Guid GUID_DSFX_STANDARD_GARGLE = .(0xdafd8210, 0x5711, 0x4b91, 0x9f, 0xe3, 0xf7, 0x5b, 0x7a, 0xe2, 0x79, 0xbf);
	public const Guid GUID_DSFX_STANDARD_CHORUS = .(0xefe6629c, 0x81f7, 0x4281, 0xbd, 0x91, 0xc9, 0xd6, 0x04, 0xa9, 0x5a, 0xf6);
	public const Guid GUID_DSFX_STANDARD_FLANGER = .(0xefca3d92, 0xdfd8, 0x4672, 0xa6, 0x03, 0x74, 0x20, 0x89, 0x4b, 0xad, 0x98);
	public const Guid GUID_DSFX_STANDARD_ECHO = .(0xef3e932c, 0xd40b, 0x4f51, 0x8c, 0xcf, 0x3f, 0x98, 0xf1, 0xb2, 0x9d, 0x5d);
	public const Guid GUID_DSFX_STANDARD_DISTORTION = .(0xef114c90, 0xcd1d, 0x484e, 0x96, 0xe5, 0x09, 0xcf, 0xaf, 0x91, 0x2a, 0x21);
	public const Guid GUID_DSFX_STANDARD_COMPRESSOR = .(0xef011f79, 0x4000, 0x406d, 0x87, 0xaf, 0xbf, 0xfb, 0x3f, 0xc3, 0x9d, 0x57);
	public const Guid GUID_DSFX_STANDARD_PARAMEQ = .(0x120ced89, 0x3bf4, 0x4173, 0xa1, 0x32, 0x3c, 0xb4, 0x06, 0xcf, 0x32, 0x31);
	public const Guid GUID_DSFX_STANDARD_I3DL2REVERB = .(0xef985e71, 0xd5c7, 0x42d4, 0xba, 0x4d, 0x2d, 0x07, 0x3e, 0x2e, 0x96, 0xf4);
	public const Guid GUID_DSFX_WAVES_REVERB = .(0x87fc0268, 0x9a55, 0x4360, 0x95, 0xaa, 0x00, 0x4a, 0x1d, 0x9d, 0xe2, 0x6c);
	public const Guid GUID_DSCFX_CLASS_AEC = .(0xbf963d80, 0xc559, 0x11d0, 0x8a, 0x2b, 0x00, 0xa0, 0xc9, 0x25, 0x5a, 0xc1);
	public const Guid GUID_DSCFX_MS_AEC = .(0xcdebb919, 0x379a, 0x488a, 0x87, 0x65, 0xf5, 0x3c, 0xfd, 0x36, 0xde, 0x40);
	public const Guid GUID_DSCFX_SYSTEM_AEC = .(0x1c22c56d, 0x9879, 0x4f5b, 0xa3, 0x89, 0x27, 0x99, 0x6d, 0xdc, 0x28, 0x10);
	public const Guid GUID_DSCFX_CLASS_NS = .(0xe07f903f, 0x62fd, 0x4e60, 0x8c, 0xdd, 0xde, 0xa7, 0x23, 0x66, 0x65, 0xb5);
	public const Guid GUID_DSCFX_MS_NS = .(0x11c5c73b, 0x66e9, 0x4ba1, 0xa0, 0xba, 0xe8, 0x14, 0xc6, 0xee, 0xd9, 0x2d);
	public const Guid GUID_DSCFX_SYSTEM_NS = .(0x5ab0882e, 0x7274, 0x4516, 0x87, 0x7d, 0x4e, 0xee, 0x99, 0xba, 0x4f, 0xd0);
	public const int32 DSFXR_PRESENT = 0;
	public const int32 DSFXR_LOCHARDWARE = 1;
	public const int32 DSFXR_LOCSOFTWARE = 2;
	public const int32 DSFXR_UNALLOCATED = 3;
	public const int32 DSFXR_FAILED = 4;
	public const int32 DSFXR_UNKNOWN = 5;
	public const int32 DSFXR_SENDLOOP = 6;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_SINGLEWINDOW = 0;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_DOUBLEWINDOW = 1;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_THINDOOR = 2;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_THICKDOOR = 3;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_WOODWALL = 4;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_BRICKWALL = 5;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_STONEWALL = 6;
	public const int32 DSFX_I3DL2_MATERIAL_PRESET_CURTAIN = 7;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_DEFAULT = 0;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_GENERIC = 1;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_PADDEDCELL = 2;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_ROOM = 3;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_BATHROOM = 4;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_LIVINGROOM = 5;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_STONEROOM = 6;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_AUDITORIUM = 7;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_CONCERTHALL = 8;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_CAVE = 9;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_ARENA = 10;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_HANGAR = 11;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_CARPETEDHALLWAY = 12;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_HALLWAY = 13;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_STONECORRIDOR = 14;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_ALLEY = 15;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_FOREST = 16;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_CITY = 17;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_MOUNTAINS = 18;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_QUARRY = 19;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_PLAIN = 20;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_PARKINGLOT = 21;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_SEWERPIPE = 22;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_UNDERWATER = 23;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_SMALLROOM = 24;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_MEDIUMROOM = 25;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_LARGEROOM = 26;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_MEDIUMHALL = 27;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_LARGEHALL = 28;
	public const int32 DSFX_I3DL2_ENVIRONMENT_PRESET_PLATE = 29;
}
#endregion
#region Function Pointers
public function BOOL LPDSENUMCALLBACKA(Guid* param0, PSTR param1, PSTR param2, void* param3);

public function BOOL LPDSENUMCALLBACKW(Guid* param0, PWSTR param1, PWSTR param2, void* param3);

#endregion

#region Structs
[CRepr]
public struct DSCAPS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwMinSecondarySampleRate;
	public uint32 dwMaxSecondarySampleRate;
	public uint32 dwPrimaryBuffers;
	public uint32 dwMaxHwMixingAllBuffers;
	public uint32 dwMaxHwMixingStaticBuffers;
	public uint32 dwMaxHwMixingStreamingBuffers;
	public uint32 dwFreeHwMixingAllBuffers;
	public uint32 dwFreeHwMixingStaticBuffers;
	public uint32 dwFreeHwMixingStreamingBuffers;
	public uint32 dwMaxHw3DAllBuffers;
	public uint32 dwMaxHw3DStaticBuffers;
	public uint32 dwMaxHw3DStreamingBuffers;
	public uint32 dwFreeHw3DAllBuffers;
	public uint32 dwFreeHw3DStaticBuffers;
	public uint32 dwFreeHw3DStreamingBuffers;
	public uint32 dwTotalHwMemBytes;
	public uint32 dwFreeHwMemBytes;
	public uint32 dwMaxContigFreeHwMemBytes;
	public uint32 dwUnlockTransferRateHwBuffers;
	public uint32 dwPlayCpuOverheadSwBuffers;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct DSBCAPS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwBufferBytes;
	public uint32 dwUnlockTransferRate;
	public uint32 dwPlayCpuOverhead;
}

[CRepr]
public struct DSEFFECTDESC
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public Guid guidDSFXClass;
	public uint dwReserved1;
	public uint dwReserved2;
}

[CRepr]
public struct DSCEFFECTDESC
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public Guid guidDSCFXClass;
	public Guid guidDSCFXInstance;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct DSBUFFERDESC
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwBufferBytes;
	public uint32 dwReserved;
	public WAVEFORMATEX* lpwfxFormat;
	public Guid guid3DAlgorithm;
}

[CRepr]
public struct DSBUFFERDESC1
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwBufferBytes;
	public uint32 dwReserved;
	public WAVEFORMATEX* lpwfxFormat;
}

[CRepr]
public struct DS3DBUFFER
{
	public uint32 dwSize;
	public D3DVECTOR vPosition;
	public D3DVECTOR vVelocity;
	public uint32 dwInsideConeAngle;
	public uint32 dwOutsideConeAngle;
	public D3DVECTOR vConeOrientation;
	public int32 lConeOutsideVolume;
	public float flMinDistance;
	public float flMaxDistance;
	public uint32 dwMode;
}

[CRepr]
public struct DS3DLISTENER
{
	public uint32 dwSize;
	public D3DVECTOR vPosition;
	public D3DVECTOR vVelocity;
	public D3DVECTOR vOrientFront;
	public D3DVECTOR vOrientTop;
	public float flDistanceFactor;
	public float flRolloffFactor;
	public float flDopplerFactor;
}

[CRepr]
public struct DSCCAPS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwFormats;
	public uint32 dwChannels;
}

[CRepr]
public struct DSCBUFFERDESC1
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwBufferBytes;
	public uint32 dwReserved;
	public WAVEFORMATEX* lpwfxFormat;
}

[CRepr]
public struct DSCBUFFERDESC
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwBufferBytes;
	public uint32 dwReserved;
	public WAVEFORMATEX* lpwfxFormat;
	public uint32 dwFXCount;
	public DSCEFFECTDESC* lpDSCFXDesc;
}

[CRepr]
public struct DSCBCAPS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwBufferBytes;
	public uint32 dwReserved;
}

[CRepr]
public struct DSBPOSITIONNOTIFY
{
	public uint32 dwOffset;
	public HANDLE hEventNotify;
}

[CRepr]
public struct DSFXGargle
{
	public uint32 dwRateHz;
	public uint32 dwWaveShape;
}

[CRepr]
public struct DSFXChorus
{
	public float fWetDryMix;
	public float fDepth;
	public float fFeedback;
	public float fFrequency;
	public int32 lWaveform;
	public float fDelay;
	public int32 lPhase;
}

[CRepr]
public struct DSFXFlanger
{
	public float fWetDryMix;
	public float fDepth;
	public float fFeedback;
	public float fFrequency;
	public int32 lWaveform;
	public float fDelay;
	public int32 lPhase;
}

[CRepr]
public struct DSFXEcho
{
	public float fWetDryMix;
	public float fFeedback;
	public float fLeftDelay;
	public float fRightDelay;
	public int32 lPanDelay;
}

[CRepr]
public struct DSFXDistortion
{
	public float fGain;
	public float fEdge;
	public float fPostEQCenterFrequency;
	public float fPostEQBandwidth;
	public float fPreLowpassCutoff;
}

[CRepr]
public struct DSFXCompressor
{
	public float fGain;
	public float fAttack;
	public float fRelease;
	public float fThreshold;
	public float fRatio;
	public float fPredelay;
}

[CRepr]
public struct DSFXParamEq
{
	public float fCenter;
	public float fBandwidth;
	public float fGain;
}

[CRepr]
public struct DSFXI3DL2Reverb
{
	public int32 lRoom;
	public int32 lRoomHF;
	public float flRoomRolloffFactor;
	public float flDecayTime;
	public float flDecayHFRatio;
	public int32 lReflections;
	public float flReflectionsDelay;
	public int32 lReverb;
	public float flReverbDelay;
	public float flDiffusion;
	public float flDensity;
	public float flHFReference;
}

[CRepr]
public struct DSFXWavesReverb
{
	public float fInGain;
	public float fReverbMix;
	public float fReverbTime;
	public float fHighFreqRTRatio;
}

[CRepr]
public struct DSCFXAec
{
	public BOOL fEnable;
	public BOOL fNoiseFill;
	public uint32 dwMode;
}

[CRepr]
public struct DSCFXNoiseSuppress
{
	public BOOL fEnable;
}

#endregion

#region COM Types
[CRepr]struct IDirectSound : IUnknown
{
	public new const Guid IID = .(0x279afa83, 0x4981, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSBUFFERDESC* pcDSBufferDesc, IDirectSoundBuffer** ppDSBuffer, IUnknown* pUnkOuter) CreateSoundBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCAPS* pDSCaps) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectSoundBuffer* pDSBufferOriginal, IDirectSoundBuffer** ppDSBufferDuplicate) DuplicateSoundBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 dwLevel) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Compact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSpeakerConfig) GetSpeakerConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSpeakerConfig) SetSpeakerConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pcGuidDevice) Initialize;
	}


	public HRESULT CreateSoundBuffer(DSBUFFERDESC* pcDSBufferDesc, IDirectSoundBuffer** ppDSBuffer, IUnknown* pUnkOuter) mut => VT.[Friend]CreateSoundBuffer(&this, pcDSBufferDesc, ppDSBuffer, pUnkOuter);

	public HRESULT GetCaps(DSCAPS* pDSCaps) mut => VT.[Friend]GetCaps(&this, pDSCaps);

	public HRESULT DuplicateSoundBuffer(IDirectSoundBuffer* pDSBufferOriginal, IDirectSoundBuffer** ppDSBufferDuplicate) mut => VT.[Friend]DuplicateSoundBuffer(&this, pDSBufferOriginal, ppDSBufferDuplicate);

	public HRESULT SetCooperativeLevel(HWND hwnd, uint32 dwLevel) mut => VT.[Friend]SetCooperativeLevel(&this, hwnd, dwLevel);

	public HRESULT Compact() mut => VT.[Friend]Compact(&this);

	public HRESULT GetSpeakerConfig(uint32* pdwSpeakerConfig) mut => VT.[Friend]GetSpeakerConfig(&this, pdwSpeakerConfig);

	public HRESULT SetSpeakerConfig(uint32 dwSpeakerConfig) mut => VT.[Friend]SetSpeakerConfig(&this, dwSpeakerConfig);

	public HRESULT Initialize(Guid* pcGuidDevice) mut => VT.[Friend]Initialize(&this, pcGuidDevice);
}

[CRepr]struct IDirectSound8 : IDirectSound
{
	public new const Guid IID = .(0xc50a7e93, 0xf395, 0x4834, 0x9e, 0xf6, 0x7f, 0xa9, 0x9d, 0xe5, 0x09, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectSound.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCertified) VerifyCertification;
	}


	public HRESULT VerifyCertification(uint32* pdwCertified) mut => VT.[Friend]VerifyCertification(&this, pdwCertified);
}

[CRepr]struct IDirectSoundBuffer : IUnknown
{
	public new const Guid IID = .(0x279afa85, 0x4981, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSBCAPS* pDSBufferCaps) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCurrentPlayCursor, uint32* pdwCurrentWriteCursor) GetCurrentPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pwfxFormat, uint32 dwSizeAllocated, uint32* pdwSizeWritten) GetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plVolume) GetVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPan) GetPan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFrequency) GetFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectSound* pDirectSound, DSBUFFERDESC* pcDSBufferDesc) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOffset, uint32 dwBytes, void** ppvAudioPtr1, uint32* pdwAudioBytes1, void** ppvAudioPtr2, uint32* pdwAudioBytes2, uint32 dwFlags) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved1, uint32 dwPriority, uint32 dwFlags) Play;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwNewPosition) SetCurrentPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pcfxFormat) SetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVolume) SetVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPan) SetPan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFrequency) SetFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvAudioPtr1, uint32 dwAudioBytes1, void* pvAudioPtr2, uint32 dwAudioBytes2) Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
	}


	public HRESULT GetCaps(DSBCAPS* pDSBufferCaps) mut => VT.[Friend]GetCaps(&this, pDSBufferCaps);

	public HRESULT GetCurrentPosition(uint32* pdwCurrentPlayCursor, uint32* pdwCurrentWriteCursor) mut => VT.[Friend]GetCurrentPosition(&this, pdwCurrentPlayCursor, pdwCurrentWriteCursor);

	public HRESULT GetFormat(WAVEFORMATEX* pwfxFormat, uint32 dwSizeAllocated, uint32* pdwSizeWritten) mut => VT.[Friend]GetFormat(&this, pwfxFormat, dwSizeAllocated, pdwSizeWritten);

	public HRESULT GetVolume(int32* plVolume) mut => VT.[Friend]GetVolume(&this, plVolume);

	public HRESULT GetPan(int32* plPan) mut => VT.[Friend]GetPan(&this, plPan);

	public HRESULT GetFrequency(uint32* pdwFrequency) mut => VT.[Friend]GetFrequency(&this, pdwFrequency);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT Initialize(IDirectSound* pDirectSound, DSBUFFERDESC* pcDSBufferDesc) mut => VT.[Friend]Initialize(&this, pDirectSound, pcDSBufferDesc);

	public HRESULT Lock(uint32 dwOffset, uint32 dwBytes, void** ppvAudioPtr1, uint32* pdwAudioBytes1, void** ppvAudioPtr2, uint32* pdwAudioBytes2, uint32 dwFlags) mut => VT.[Friend]Lock(&this, dwOffset, dwBytes, ppvAudioPtr1, pdwAudioBytes1, ppvAudioPtr2, pdwAudioBytes2, dwFlags);

	public HRESULT Play(uint32 dwReserved1, uint32 dwPriority, uint32 dwFlags) mut => VT.[Friend]Play(&this, dwReserved1, dwPriority, dwFlags);

	public HRESULT SetCurrentPosition(uint32 dwNewPosition) mut => VT.[Friend]SetCurrentPosition(&this, dwNewPosition);

	public HRESULT SetFormat(WAVEFORMATEX* pcfxFormat) mut => VT.[Friend]SetFormat(&this, pcfxFormat);

	public HRESULT SetVolume(int32 lVolume) mut => VT.[Friend]SetVolume(&this, lVolume);

	public HRESULT SetPan(int32 lPan) mut => VT.[Friend]SetPan(&this, lPan);

	public HRESULT SetFrequency(uint32 dwFrequency) mut => VT.[Friend]SetFrequency(&this, dwFrequency);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Unlock(void* pvAudioPtr1, uint32 dwAudioBytes1, void* pvAudioPtr2, uint32 dwAudioBytes2) mut => VT.[Friend]Unlock(&this, pvAudioPtr1, dwAudioBytes1, pvAudioPtr2, dwAudioBytes2);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);
}

[CRepr]struct IDirectSoundBuffer8 : IDirectSoundBuffer
{
	public new const Guid IID = .(0x6825a449, 0x7524, 0x4d82, 0x92, 0x0f, 0x50, 0xe3, 0x6a, 0xb3, 0xab, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectSoundBuffer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEffectsCount, DSEFFECTDESC* pDSFXDesc, uint32* pdwResultCodes) SetFX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 dwEffectsCount, uint32* pdwResultCodes) AcquireResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidObject, uint32 dwIndex, in Guid rguidInterface, void** ppObject) GetObjectInPath;
	}


	public HRESULT SetFX(uint32 dwEffectsCount, DSEFFECTDESC* pDSFXDesc, uint32* pdwResultCodes) mut => VT.[Friend]SetFX(&this, dwEffectsCount, pDSFXDesc, pdwResultCodes);

	public HRESULT AcquireResources(uint32 dwFlags, uint32 dwEffectsCount, uint32* pdwResultCodes) mut => VT.[Friend]AcquireResources(&this, dwFlags, dwEffectsCount, pdwResultCodes);

	public HRESULT GetObjectInPath(in Guid rguidObject, uint32 dwIndex, in Guid rguidInterface, void** ppObject) mut => VT.[Friend]GetObjectInPath(&this, rguidObject, dwIndex, rguidInterface, ppObject);
}

[CRepr]struct IDirectSound3DListener : IUnknown
{
	public new const Guid IID = .(0x279afa84, 0x4981, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DS3DLISTENER* pListener) GetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pflDistanceFactor) GetDistanceFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pflDopplerFactor) GetDopplerFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DVECTOR* pvOrientFront, D3DVECTOR* pvOrientTop) GetOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DVECTOR* pvPosition) GetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pflRolloffFactor) GetRolloffFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DVECTOR* pvVelocity) GetVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DS3DLISTENER* pcListener, uint32 dwApply) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float flDistanceFactor, uint32 dwApply) SetDistanceFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float flDopplerFactor, uint32 dwApply) SetDopplerFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float xFront, float yFront, float zFront, float xTop, float yTop, float zTop, uint32 dwApply) SetOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float z, uint32 dwApply) SetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float flRolloffFactor, uint32 dwApply) SetRolloffFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float z, uint32 dwApply) SetVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CommitDeferredSettings;
	}


	public HRESULT GetAllParameters(DS3DLISTENER* pListener) mut => VT.[Friend]GetAllParameters(&this, pListener);

	public HRESULT GetDistanceFactor(float* pflDistanceFactor) mut => VT.[Friend]GetDistanceFactor(&this, pflDistanceFactor);

	public HRESULT GetDopplerFactor(float* pflDopplerFactor) mut => VT.[Friend]GetDopplerFactor(&this, pflDopplerFactor);

	public HRESULT GetOrientation(D3DVECTOR* pvOrientFront, D3DVECTOR* pvOrientTop) mut => VT.[Friend]GetOrientation(&this, pvOrientFront, pvOrientTop);

	public HRESULT GetPosition(D3DVECTOR* pvPosition) mut => VT.[Friend]GetPosition(&this, pvPosition);

	public HRESULT GetRolloffFactor(float* pflRolloffFactor) mut => VT.[Friend]GetRolloffFactor(&this, pflRolloffFactor);

	public HRESULT GetVelocity(D3DVECTOR* pvVelocity) mut => VT.[Friend]GetVelocity(&this, pvVelocity);

	public HRESULT SetAllParameters(DS3DLISTENER* pcListener, uint32 dwApply) mut => VT.[Friend]SetAllParameters(&this, pcListener, dwApply);

	public HRESULT SetDistanceFactor(float flDistanceFactor, uint32 dwApply) mut => VT.[Friend]SetDistanceFactor(&this, flDistanceFactor, dwApply);

	public HRESULT SetDopplerFactor(float flDopplerFactor, uint32 dwApply) mut => VT.[Friend]SetDopplerFactor(&this, flDopplerFactor, dwApply);

	public HRESULT SetOrientation(float xFront, float yFront, float zFront, float xTop, float yTop, float zTop, uint32 dwApply) mut => VT.[Friend]SetOrientation(&this, xFront, yFront, zFront, xTop, yTop, zTop, dwApply);

	public HRESULT SetPosition(float x, float y, float z, uint32 dwApply) mut => VT.[Friend]SetPosition(&this, x, y, z, dwApply);

	public HRESULT SetRolloffFactor(float flRolloffFactor, uint32 dwApply) mut => VT.[Friend]SetRolloffFactor(&this, flRolloffFactor, dwApply);

	public HRESULT SetVelocity(float x, float y, float z, uint32 dwApply) mut => VT.[Friend]SetVelocity(&this, x, y, z, dwApply);

	public HRESULT CommitDeferredSettings() mut => VT.[Friend]CommitDeferredSettings(&this);
}

[CRepr]struct IDirectSound3DBuffer : IUnknown
{
	public new const Guid IID = .(0x279afa86, 0x4981, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DS3DBUFFER* pDs3dBuffer) GetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwInsideConeAngle, uint32* pdwOutsideConeAngle) GetConeAngles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DVECTOR* pvOrientation) GetConeOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plConeOutsideVolume) GetConeOutsideVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pflMaxDistance) GetMaxDistance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pflMinDistance) GetMinDistance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode) GetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DVECTOR* pvPosition) GetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DVECTOR* pvVelocity) GetVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DS3DBUFFER* pcDs3dBuffer, uint32 dwApply) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInsideConeAngle, uint32 dwOutsideConeAngle, uint32 dwApply) SetConeAngles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float z, uint32 dwApply) SetConeOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lConeOutsideVolume, uint32 dwApply) SetConeOutsideVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float flMaxDistance, uint32 dwApply) SetMaxDistance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float flMinDistance, uint32 dwApply) SetMinDistance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode, uint32 dwApply) SetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float z, uint32 dwApply) SetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float z, uint32 dwApply) SetVelocity;
	}


	public HRESULT GetAllParameters(DS3DBUFFER* pDs3dBuffer) mut => VT.[Friend]GetAllParameters(&this, pDs3dBuffer);

	public HRESULT GetConeAngles(uint32* pdwInsideConeAngle, uint32* pdwOutsideConeAngle) mut => VT.[Friend]GetConeAngles(&this, pdwInsideConeAngle, pdwOutsideConeAngle);

	public HRESULT GetConeOrientation(D3DVECTOR* pvOrientation) mut => VT.[Friend]GetConeOrientation(&this, pvOrientation);

	public HRESULT GetConeOutsideVolume(int32* plConeOutsideVolume) mut => VT.[Friend]GetConeOutsideVolume(&this, plConeOutsideVolume);

	public HRESULT GetMaxDistance(float* pflMaxDistance) mut => VT.[Friend]GetMaxDistance(&this, pflMaxDistance);

	public HRESULT GetMinDistance(float* pflMinDistance) mut => VT.[Friend]GetMinDistance(&this, pflMinDistance);

	public HRESULT GetMode(uint32* pdwMode) mut => VT.[Friend]GetMode(&this, pdwMode);

	public HRESULT GetPosition(D3DVECTOR* pvPosition) mut => VT.[Friend]GetPosition(&this, pvPosition);

	public HRESULT GetVelocity(D3DVECTOR* pvVelocity) mut => VT.[Friend]GetVelocity(&this, pvVelocity);

	public HRESULT SetAllParameters(DS3DBUFFER* pcDs3dBuffer, uint32 dwApply) mut => VT.[Friend]SetAllParameters(&this, pcDs3dBuffer, dwApply);

	public HRESULT SetConeAngles(uint32 dwInsideConeAngle, uint32 dwOutsideConeAngle, uint32 dwApply) mut => VT.[Friend]SetConeAngles(&this, dwInsideConeAngle, dwOutsideConeAngle, dwApply);

	public HRESULT SetConeOrientation(float x, float y, float z, uint32 dwApply) mut => VT.[Friend]SetConeOrientation(&this, x, y, z, dwApply);

	public HRESULT SetConeOutsideVolume(int32 lConeOutsideVolume, uint32 dwApply) mut => VT.[Friend]SetConeOutsideVolume(&this, lConeOutsideVolume, dwApply);

	public HRESULT SetMaxDistance(float flMaxDistance, uint32 dwApply) mut => VT.[Friend]SetMaxDistance(&this, flMaxDistance, dwApply);

	public HRESULT SetMinDistance(float flMinDistance, uint32 dwApply) mut => VT.[Friend]SetMinDistance(&this, flMinDistance, dwApply);

	public HRESULT SetMode(uint32 dwMode, uint32 dwApply) mut => VT.[Friend]SetMode(&this, dwMode, dwApply);

	public HRESULT SetPosition(float x, float y, float z, uint32 dwApply) mut => VT.[Friend]SetPosition(&this, x, y, z, dwApply);

	public HRESULT SetVelocity(float x, float y, float z, uint32 dwApply) mut => VT.[Friend]SetVelocity(&this, x, y, z, dwApply);
}

[CRepr]struct IDirectSoundCapture : IUnknown
{
	public new const Guid IID = .(0xb0210781, 0x89cd, 0x11d0, 0xaf, 0x08, 0x00, 0xa0, 0xc9, 0x25, 0xcd, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCBUFFERDESC* pcDSCBufferDesc, IDirectSoundCaptureBuffer** ppDSCBuffer, IUnknown* pUnkOuter) CreateCaptureBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCCAPS* pDSCCaps) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pcGuidDevice) Initialize;
	}


	public HRESULT CreateCaptureBuffer(DSCBUFFERDESC* pcDSCBufferDesc, IDirectSoundCaptureBuffer** ppDSCBuffer, IUnknown* pUnkOuter) mut => VT.[Friend]CreateCaptureBuffer(&this, pcDSCBufferDesc, ppDSCBuffer, pUnkOuter);

	public HRESULT GetCaps(DSCCAPS* pDSCCaps) mut => VT.[Friend]GetCaps(&this, pDSCCaps);

	public HRESULT Initialize(Guid* pcGuidDevice) mut => VT.[Friend]Initialize(&this, pcGuidDevice);
}

[CRepr]struct IDirectSoundCaptureBuffer : IUnknown
{
	public new const Guid IID = .(0xb0210782, 0x89cd, 0x11d0, 0xaf, 0x08, 0x00, 0xa0, 0xc9, 0x25, 0xcd, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCBCAPS* pDSCBCaps) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapturePosition, uint32* pdwReadPosition) GetCurrentPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pwfxFormat, uint32 dwSizeAllocated, uint32* pdwSizeWritten) GetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectSoundCapture* pDirectSoundCapture, DSCBUFFERDESC* pcDSCBufferDesc) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOffset, uint32 dwBytes, void** ppvAudioPtr1, uint32* pdwAudioBytes1, void** ppvAudioPtr2, uint32* pdwAudioBytes2, uint32 dwFlags) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvAudioPtr1, uint32 dwAudioBytes1, void* pvAudioPtr2, uint32 dwAudioBytes2) Unlock;
	}


	public HRESULT GetCaps(DSCBCAPS* pDSCBCaps) mut => VT.[Friend]GetCaps(&this, pDSCBCaps);

	public HRESULT GetCurrentPosition(uint32* pdwCapturePosition, uint32* pdwReadPosition) mut => VT.[Friend]GetCurrentPosition(&this, pdwCapturePosition, pdwReadPosition);

	public HRESULT GetFormat(WAVEFORMATEX* pwfxFormat, uint32 dwSizeAllocated, uint32* pdwSizeWritten) mut => VT.[Friend]GetFormat(&this, pwfxFormat, dwSizeAllocated, pdwSizeWritten);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT Initialize(IDirectSoundCapture* pDirectSoundCapture, DSCBUFFERDESC* pcDSCBufferDesc) mut => VT.[Friend]Initialize(&this, pDirectSoundCapture, pcDSCBufferDesc);

	public HRESULT Lock(uint32 dwOffset, uint32 dwBytes, void** ppvAudioPtr1, uint32* pdwAudioBytes1, void** ppvAudioPtr2, uint32* pdwAudioBytes2, uint32 dwFlags) mut => VT.[Friend]Lock(&this, dwOffset, dwBytes, ppvAudioPtr1, pdwAudioBytes1, ppvAudioPtr2, pdwAudioBytes2, dwFlags);

	public HRESULT Start(uint32 dwFlags) mut => VT.[Friend]Start(&this, dwFlags);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Unlock(void* pvAudioPtr1, uint32 dwAudioBytes1, void* pvAudioPtr2, uint32 dwAudioBytes2) mut => VT.[Friend]Unlock(&this, pvAudioPtr1, dwAudioBytes1, pvAudioPtr2, dwAudioBytes2);
}

[CRepr]struct IDirectSoundCaptureBuffer8 : IDirectSoundCaptureBuffer
{
	public new const Guid IID = .(0x00990df4, 0x0dbb, 0x4872, 0x83, 0x3e, 0x6d, 0x30, 0x3e, 0x80, 0xae, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectSoundCaptureBuffer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidObject, uint32 dwIndex, in Guid rguidInterface, void** ppObject) GetObjectInPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEffectsCount, uint32* pdwFXStatus) GetFXStatus;
	}


	public HRESULT GetObjectInPath(in Guid rguidObject, uint32 dwIndex, in Guid rguidInterface, void** ppObject) mut => VT.[Friend]GetObjectInPath(&this, rguidObject, dwIndex, rguidInterface, ppObject);

	public HRESULT GetFXStatus(uint32 dwEffectsCount, uint32* pdwFXStatus) mut => VT.[Friend]GetFXStatus(&this, dwEffectsCount, pdwFXStatus);
}

[CRepr]struct IDirectSoundNotify : IUnknown
{
	public new const Guid IID = .(0xb0210783, 0x89cd, 0x11d0, 0xaf, 0x08, 0x00, 0xa0, 0xc9, 0x25, 0xcd, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwPositionNotifies, DSBPOSITIONNOTIFY* pcPositionNotifies) SetNotificationPositions;
	}


	public HRESULT SetNotificationPositions(uint32 dwPositionNotifies, DSBPOSITIONNOTIFY* pcPositionNotifies) mut => VT.[Friend]SetNotificationPositions(&this, dwPositionNotifies, pcPositionNotifies);
}

[CRepr]struct IDirectSoundFXGargle : IUnknown
{
	public new const Guid IID = .(0xd616f352, 0xd622, 0x11ce, 0xaa, 0xc5, 0x00, 0x20, 0xaf, 0x0b, 0x99, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXGargle* pcDsFxGargle) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXGargle* pDsFxGargle) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXGargle* pcDsFxGargle) mut => VT.[Friend]SetAllParameters(&this, pcDsFxGargle);

	public HRESULT GetAllParameters(DSFXGargle* pDsFxGargle) mut => VT.[Friend]GetAllParameters(&this, pDsFxGargle);
}

[CRepr]struct IDirectSoundFXChorus : IUnknown
{
	public new const Guid IID = .(0x880842e3, 0x145f, 0x43e6, 0xa9, 0x34, 0xa7, 0x18, 0x06, 0xe5, 0x05, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXChorus* pcDsFxChorus) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXChorus* pDsFxChorus) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXChorus* pcDsFxChorus) mut => VT.[Friend]SetAllParameters(&this, pcDsFxChorus);

	public HRESULT GetAllParameters(DSFXChorus* pDsFxChorus) mut => VT.[Friend]GetAllParameters(&this, pDsFxChorus);
}

[CRepr]struct IDirectSoundFXFlanger : IUnknown
{
	public new const Guid IID = .(0x903e9878, 0x2c92, 0x4072, 0x9b, 0x2c, 0xea, 0x68, 0xf5, 0x39, 0x67, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXFlanger* pcDsFxFlanger) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXFlanger* pDsFxFlanger) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXFlanger* pcDsFxFlanger) mut => VT.[Friend]SetAllParameters(&this, pcDsFxFlanger);

	public HRESULT GetAllParameters(DSFXFlanger* pDsFxFlanger) mut => VT.[Friend]GetAllParameters(&this, pDsFxFlanger);
}

[CRepr]struct IDirectSoundFXEcho : IUnknown
{
	public new const Guid IID = .(0x8bd28edf, 0x50db, 0x4e92, 0xa2, 0xbd, 0x44, 0x54, 0x88, 0xd1, 0xed, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXEcho* pcDsFxEcho) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXEcho* pDsFxEcho) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXEcho* pcDsFxEcho) mut => VT.[Friend]SetAllParameters(&this, pcDsFxEcho);

	public HRESULT GetAllParameters(DSFXEcho* pDsFxEcho) mut => VT.[Friend]GetAllParameters(&this, pDsFxEcho);
}

[CRepr]struct IDirectSoundFXDistortion : IUnknown
{
	public new const Guid IID = .(0x8ecf4326, 0x455f, 0x4d8b, 0xbd, 0xa9, 0x8d, 0x5d, 0x3e, 0x9e, 0x3e, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXDistortion* pcDsFxDistortion) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXDistortion* pDsFxDistortion) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXDistortion* pcDsFxDistortion) mut => VT.[Friend]SetAllParameters(&this, pcDsFxDistortion);

	public HRESULT GetAllParameters(DSFXDistortion* pDsFxDistortion) mut => VT.[Friend]GetAllParameters(&this, pDsFxDistortion);
}

[CRepr]struct IDirectSoundFXCompressor : IUnknown
{
	public new const Guid IID = .(0x4bbd1154, 0x62f6, 0x4e2c, 0xa1, 0x5c, 0xd3, 0xb6, 0xc4, 0x17, 0xf7, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXCompressor* pcDsFxCompressor) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXCompressor* pDsFxCompressor) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXCompressor* pcDsFxCompressor) mut => VT.[Friend]SetAllParameters(&this, pcDsFxCompressor);

	public HRESULT GetAllParameters(DSFXCompressor* pDsFxCompressor) mut => VT.[Friend]GetAllParameters(&this, pDsFxCompressor);
}

[CRepr]struct IDirectSoundFXParamEq : IUnknown
{
	public new const Guid IID = .(0xc03ca9fe, 0xfe90, 0x4204, 0x80, 0x78, 0x82, 0x33, 0x4c, 0xd1, 0x77, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXParamEq* pcDsFxParamEq) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXParamEq* pDsFxParamEq) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXParamEq* pcDsFxParamEq) mut => VT.[Friend]SetAllParameters(&this, pcDsFxParamEq);

	public HRESULT GetAllParameters(DSFXParamEq* pDsFxParamEq) mut => VT.[Friend]GetAllParameters(&this, pDsFxParamEq);
}

[CRepr]struct IDirectSoundFXI3DL2Reverb : IUnknown
{
	public new const Guid IID = .(0x4b166a6a, 0x0d66, 0x43f3, 0x80, 0xe3, 0xee, 0x62, 0x80, 0xde, 0xe1, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXI3DL2Reverb* pcDsFxI3DL2Reverb) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXI3DL2Reverb* pDsFxI3DL2Reverb) GetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwPreset) SetPreset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPreset) GetPreset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lQuality) SetQuality;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQuality) GetQuality;
	}


	public HRESULT SetAllParameters(DSFXI3DL2Reverb* pcDsFxI3DL2Reverb) mut => VT.[Friend]SetAllParameters(&this, pcDsFxI3DL2Reverb);

	public HRESULT GetAllParameters(DSFXI3DL2Reverb* pDsFxI3DL2Reverb) mut => VT.[Friend]GetAllParameters(&this, pDsFxI3DL2Reverb);

	public HRESULT SetPreset(uint32 dwPreset) mut => VT.[Friend]SetPreset(&this, dwPreset);

	public HRESULT GetPreset(uint32* pdwPreset) mut => VT.[Friend]GetPreset(&this, pdwPreset);

	public HRESULT SetQuality(int32 lQuality) mut => VT.[Friend]SetQuality(&this, lQuality);

	public HRESULT GetQuality(int32* plQuality) mut => VT.[Friend]GetQuality(&this, plQuality);
}

[CRepr]struct IDirectSoundFXWavesReverb : IUnknown
{
	public new const Guid IID = .(0x46858c3a, 0x0dc6, 0x45e3, 0xb7, 0x60, 0xd4, 0xee, 0xf1, 0x6c, 0xb3, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXWavesReverb* pcDsFxWavesReverb) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSFXWavesReverb* pDsFxWavesReverb) GetAllParameters;
	}


	public HRESULT SetAllParameters(DSFXWavesReverb* pcDsFxWavesReverb) mut => VT.[Friend]SetAllParameters(&this, pcDsFxWavesReverb);

	public HRESULT GetAllParameters(DSFXWavesReverb* pDsFxWavesReverb) mut => VT.[Friend]GetAllParameters(&this, pDsFxWavesReverb);
}

[CRepr]struct IDirectSoundCaptureFXAec : IUnknown
{
	public new const Guid IID = .(0xad74143d, 0x903d, 0x4ab7, 0x80, 0x66, 0x28, 0xd3, 0x63, 0x03, 0x6d, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCFXAec* pDscFxAec) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCFXAec* pDscFxAec) GetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT SetAllParameters(DSCFXAec* pDscFxAec) mut => VT.[Friend]SetAllParameters(&this, pDscFxAec);

	public HRESULT GetAllParameters(DSCFXAec* pDscFxAec) mut => VT.[Friend]GetAllParameters(&this, pDscFxAec);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IDirectSoundCaptureFXNoiseSuppress : IUnknown
{
	public new const Guid IID = .(0xed311e41, 0xfbae, 0x4175, 0x96, 0x25, 0xcd, 0x08, 0x54, 0xf6, 0x93, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCFXNoiseSuppress* pcDscFxNoiseSuppress) SetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSCFXNoiseSuppress* pDscFxNoiseSuppress) GetAllParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT SetAllParameters(DSCFXNoiseSuppress* pcDscFxNoiseSuppress) mut => VT.[Friend]SetAllParameters(&this, pcDscFxNoiseSuppress);

	public HRESULT GetAllParameters(DSCFXNoiseSuppress* pDscFxNoiseSuppress) mut => VT.[Friend]GetAllParameters(&this, pDscFxNoiseSuppress);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IDirectSoundFullDuplex : IUnknown
{
	public new const Guid IID = .(0xedcb4c7a, 0xdaab, 0x4216, 0xa4, 0x2e, 0x6c, 0x50, 0x59, 0x6d, 0xdc, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pCaptureGuid, in Guid pRenderGuid, DSCBUFFERDESC* lpDscBufferDesc, DSBUFFERDESC* lpDsBufferDesc, HWND hWnd, uint32 dwLevel, IDirectSoundCaptureBuffer8** lplpDirectSoundCaptureBuffer8, IDirectSoundBuffer8** lplpDirectSoundBuffer8) Initialize;
	}


	public HRESULT Initialize(in Guid pCaptureGuid, in Guid pRenderGuid, DSCBUFFERDESC* lpDscBufferDesc, DSBUFFERDESC* lpDsBufferDesc, HWND hWnd, uint32 dwLevel, IDirectSoundCaptureBuffer8** lplpDirectSoundCaptureBuffer8, IDirectSoundBuffer8** lplpDirectSoundBuffer8) mut => VT.[Friend]Initialize(&this, pCaptureGuid, pRenderGuid, lpDscBufferDesc, lpDsBufferDesc, hWnd, dwLevel, lplpDirectSoundCaptureBuffer8, lplpDirectSoundBuffer8);
}

#endregion

#region Functions
public static
{
	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundCreate(Guid* pcGuidDevice, IDirectSound** ppDS, IUnknown* pUnkOuter);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundEnumerateA(LPDSENUMCALLBACKA pDSEnumCallback, void* pContext);
	public static HRESULT DirectSoundEnumerate(LPDSENUMCALLBACKA pDSEnumCallback, void* pContext) => DirectSoundEnumerateA(pDSEnumCallback, pContext);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundEnumerateW(LPDSENUMCALLBACKW pDSEnumCallback, void* pContext);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundCaptureCreate(Guid* pcGuidDevice, IDirectSoundCapture** ppDSC, IUnknown* pUnkOuter);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundCaptureEnumerateA(LPDSENUMCALLBACKA pDSEnumCallback, void* pContext);
	public static HRESULT DirectSoundCaptureEnumerate(LPDSENUMCALLBACKA pDSEnumCallback, void* pContext) => DirectSoundCaptureEnumerateA(pDSEnumCallback, pContext);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundCaptureEnumerateW(LPDSENUMCALLBACKW pDSEnumCallback, void* pContext);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundCreate8(Guid* pcGuidDevice, IDirectSound8** ppDS8, IUnknown* pUnkOuter);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundCaptureCreate8(Guid* pcGuidDevice, IDirectSoundCapture** ppDSC8, IUnknown* pUnkOuter);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectSoundFullDuplexCreate(Guid* pcGuidCaptureDevice, Guid* pcGuidRenderDevice, DSCBUFFERDESC* pcDSCBufferDesc, DSBUFFERDESC* pcDSBufferDesc, HWND hWnd, uint32 dwLevel, IDirectSoundFullDuplex** ppDSFD, IDirectSoundCaptureBuffer8** ppDSCBuffer8, IDirectSoundBuffer8** ppDSBuffer8, IUnknown* pUnkOuter);

	[Import("DSOUND.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDeviceID(Guid* pGuidSrc, Guid* pGuidDest);

}
#endregion
