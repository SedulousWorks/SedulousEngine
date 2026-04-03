using Win32.Foundation;
using Win32.Media.Audio;
using Win32.Graphics.Gdi;
using Win32.Media;
using Win32.System.Com;
using Win32.UI.Controls;
using Win32.System.IO;
using Win32.UI.Controls.Dialogs;
using System;

namespace Win32.Media.Multimedia;

#region Constants
public static
{
	public const uint32 WM_CAP_START = 1024;
	public const uint32 MODM_USER = 16384;
	public const uint32 MIDM_USER = 16384;
	public const uint32 MODM_MAPPER = 8192;
	public const uint32 MIDM_MAPPER = 8192;
	public const uint32 MODM_INIT = 100;
	public const uint32 MIDM_INIT = 100;
	public const uint32 MODM_INIT_EX = 104;
	public const uint32 MIDM_INIT_EX = 104;
	public const uint32 DRV_MCI_FIRST = 2048;
	public const uint32 ACMDM_BASE = 24576;
	public const uint32 ICM_RESERVED = 20480;
	public const int32 MCI_TEST = 32;
	public const uint32 MCI_CAPTURE = 2160;
	public const uint32 MCI_MONITOR = 2161;
	public const uint32 MCI_RESERVE = 2162;
	public const uint32 MCI_SETAUDIO = 2163;
	public const uint32 MCI_SIGNAL = 2165;
	public const uint32 MCI_SETVIDEO = 2166;
	public const uint32 MCI_QUALITY = 2167;
	public const uint32 MCI_LIST = 2168;
	public const uint32 MCI_UNDO = 2169;
	public const uint32 MCI_CONFIGURE = 2170;
	public const uint32 MCI_RESTORE = 2171;
	public const uint32 MCI_ON = 1;
	public const uint32 MCI_OFF = 0;
	public const uint32 MCI_DGV_FILE_MODE_SAVING = 1;
	public const uint32 MCI_DGV_FILE_MODE_LOADING = 2;
	public const uint32 MCI_DGV_FILE_MODE_EDITING = 3;
	public const uint32 MCI_DGV_FILE_MODE_IDLE = 4;
	public const int32 MCI_ON_S = 32768;
	public const int32 MCI_OFF_S = 32769;
	public const int32 MCI_DGV_FILE_S = 32770;
	public const int32 MCI_DGV_INPUT_S = 32771;
	public const int32 MCI_DGV_FILE_MODE_SAVING_S = 32772;
	public const int32 MCI_DGV_FILE_MODE_LOADING_S = 32773;
	public const int32 MCI_DGV_FILE_MODE_EDITING_S = 32774;
	public const int32 MCI_DGV_FILE_MODE_IDLE_S = 32775;
	public const int32 MCI_DGV_SETVIDEO_SRC_NTSC_S = 32784;
	public const int32 MCI_DGV_SETVIDEO_SRC_RGB_S = 32785;
	public const int32 MCI_DGV_SETVIDEO_SRC_SVIDEO_S = 32786;
	public const int32 MCI_DGV_SETVIDEO_SRC_PAL_S = 32787;
	public const int32 MCI_DGV_SETVIDEO_SRC_SECAM_S = 32788;
	public const int32 MCI_DGV_SETVIDEO_SRC_GENERIC_S = 32789;
	public const int32 MCI_DGV_SETAUDIO_SRC_LEFT_S = 32800;
	public const int32 MCI_DGV_SETAUDIO_SRC_RIGHT_S = 32801;
	public const int32 MCI_DGV_SETAUDIO_SRC_AVERAGE_S = 32802;
	public const int32 MCI_DGV_SETAUDIO_SRC_STEREO_S = 32803;
	public const uint32 MCIERR_DGV_DEVICE_LIMIT = 512;
	public const uint32 MCIERR_DGV_IOERR = 513;
	public const uint32 MCIERR_DGV_WORKSPACE_EMPTY = 514;
	public const uint32 MCIERR_DGV_DISK_FULL = 515;
	public const uint32 MCIERR_DGV_DEVICE_MEMORY_FULL = 516;
	public const uint32 MCIERR_DGV_BAD_CLIPBOARD_RANGE = 517;
	public const int32 MCI_DGV_METHOD_PRE = 40960;
	public const int32 MCI_DGV_METHOD_POST = 40961;
	public const int32 MCI_DGV_METHOD_DIRECT = 40962;
	public const int32 MCI_DGV_FF_AVSS = 16384;
	public const int32 MCI_DGV_FF_AVI = 16385;
	public const int32 MCI_DGV_FF_DIB = 16386;
	public const int32 MCI_DGV_FF_RDIB = 16387;
	public const int32 MCI_DGV_FF_JPEG = 16388;
	public const int32 MCI_DGV_FF_RJPEG = 16389;
	public const int32 MCI_DGV_FF_JFIF = 16390;
	public const int32 MCI_DGV_FF_MPEG = 16391;
	public const int32 MCI_DGV_GETDEVCAPS_CAN_LOCK = 16384;
	public const int32 MCI_DGV_GETDEVCAPS_CAN_STRETCH = 16385;
	public const int32 MCI_DGV_GETDEVCAPS_CAN_FREEZE = 16386;
	public const int32 MCI_DGV_GETDEVCAPS_MAX_WINDOWS = 16387;
	public const int32 MCI_DGV_GETDEVCAPS_CAN_REVERSE = 16388;
	public const int32 MCI_DGV_GETDEVCAPS_HAS_STILL = 16389;
	public const int32 MCI_DGV_GETDEVCAPS_PALETTES = 16390;
	public const int32 MCI_DGV_GETDEVCAPS_CAN_STR_IN = 16392;
	public const int32 MCI_DGV_GETDEVCAPS_CAN_TEST = 16393;
	public const int32 MCI_DGV_GETDEVCAPS_MAXIMUM_RATE = 16394;
	public const int32 MCI_DGV_GETDEVCAPS_MINIMUM_RATE = 16395;
	public const int32 MCI_DGV_CAPTURE_AS = 65536;
	public const int32 MCI_DGV_CAPTURE_AT = 131072;
	public const int32 MCI_DGV_COPY_AT = 65536;
	public const int32 MCI_DGV_COPY_AUDIO_STREAM = 131072;
	public const int32 MCI_DGV_COPY_VIDEO_STREAM = 262144;
	public const int32 MCI_DGV_CUE_INPUT = 65536;
	public const int32 MCI_DGV_CUE_OUTPUT = 131072;
	public const int32 MCI_DGV_CUE_NOSHOW = 262144;
	public const int32 MCI_DGV_CUT_AT = 65536;
	public const int32 MCI_DGV_CUT_AUDIO_STREAM = 131072;
	public const int32 MCI_DGV_CUT_VIDEO_STREAM = 262144;
	public const int32 MCI_DGV_DELETE_AT = 65536;
	public const int32 MCI_DGV_DELETE_AUDIO_STREAM = 131072;
	public const int32 MCI_DGV_DELETE_VIDEO_STREAM = 262144;
	public const int32 MCI_DGV_FREEZE_AT = 65536;
	public const int32 MCI_DGV_FREEZE_OUTSIDE = 131072;
	public const int32 MCI_DGV_INFO_TEXT = 65536;
	public const int32 MCI_DGV_INFO_ITEM = 131072;
	public const int32 MCI_INFO_VERSION = 1024;
	public const int32 MCI_DGV_INFO_USAGE = 16384;
	public const int32 MCI_DGV_INFO_AUDIO_QUALITY = 16385;
	public const int32 MCI_DGV_INFO_STILL_QUALITY = 16386;
	public const int32 MCI_DGV_INFO_VIDEO_QUALITY = 16387;
	public const int32 MCI_DGV_INFO_AUDIO_ALG = 16388;
	public const int32 MCI_DGV_INFO_STILL_ALG = 16389;
	public const int32 MCI_DGV_INFO_VIDEO_ALG = 16390;
	public const int32 MCI_DGV_LIST_ITEM = 65536;
	public const int32 MCI_DGV_LIST_COUNT = 131072;
	public const int32 MCI_DGV_LIST_NUMBER = 262144;
	public const int32 MCI_DGV_LIST_ALG = 524288;
	public const int32 MCI_DGV_LIST_AUDIO_ALG = 16384;
	public const int32 MCI_DGV_LIST_AUDIO_QUALITY = 16385;
	public const int32 MCI_DGV_LIST_AUDIO_STREAM = 16386;
	public const int32 MCI_DGV_LIST_STILL_ALG = 16387;
	public const int32 MCI_DGV_LIST_STILL_QUALITY = 16388;
	public const int32 MCI_DGV_LIST_VIDEO_ALG = 16389;
	public const int32 MCI_DGV_LIST_VIDEO_QUALITY = 16390;
	public const int32 MCI_DGV_LIST_VIDEO_STREAM = 16391;
	public const int32 MCI_DGV_LIST_VIDEO_SOURCE = 16392;
	public const int32 MCI_DGV_MONITOR_METHOD = 65536;
	public const int32 MCI_DGV_MONITOR_SOURCE = 131072;
	public const int32 MCI_DGV_MONITOR_INPUT = 16384;
	public const int32 MCI_DGV_MONITOR_FILE = 16385;
	public const int32 MCI_DGV_OPEN_WS = 65536;
	public const int32 MCI_DGV_OPEN_PARENT = 131072;
	public const int32 MCI_DGV_OPEN_NOSTATIC = 262144;
	public const int32 MCI_DGV_OPEN_16BIT = 524288;
	public const int32 MCI_DGV_OPEN_32BIT = 1048576;
	public const int32 MCI_DGV_PASTE_AT = 65536;
	public const int32 MCI_DGV_PASTE_AUDIO_STREAM = 131072;
	public const int32 MCI_DGV_PASTE_VIDEO_STREAM = 262144;
	public const int32 MCI_DGV_PASTE_INSERT = 524288;
	public const int32 MCI_DGV_PASTE_OVERWRITE = 1048576;
	public const int32 MCI_DGV_PLAY_REPEAT = 65536;
	public const int32 MCI_DGV_PLAY_REVERSE = 131072;
	public const int32 MCI_DGV_RECT = 65536;
	public const int32 MCI_DGV_PUT_SOURCE = 131072;
	public const int32 MCI_DGV_PUT_DESTINATION = 262144;
	public const int32 MCI_DGV_PUT_FRAME = 524288;
	public const int32 MCI_DGV_PUT_VIDEO = 1048576;
	public const int32 MCI_DGV_PUT_WINDOW = 2097152;
	public const int32 MCI_DGV_PUT_CLIENT = 4194304;
	public const int32 MCI_QUALITY_ITEM = 65536;
	public const int32 MCI_QUALITY_NAME = 131072;
	public const int32 MCI_QUALITY_ALG = 262144;
	public const int32 MCI_QUALITY_DIALOG = 524288;
	public const int32 MCI_QUALITY_HANDLE = 1048576;
	public const int32 MCI_QUALITY_ITEM_AUDIO = 16384;
	public const int32 MCI_QUALITY_ITEM_STILL = 16385;
	public const int32 MCI_QUALITY_ITEM_VIDEO = 16386;
	public const int32 MCI_DGV_REALIZE_NORM = 65536;
	public const int32 MCI_DGV_REALIZE_BKGD = 131072;
	public const int32 MCI_DGV_RECORD_HOLD = 131072;
	public const int32 MCI_DGV_RECORD_AUDIO_STREAM = 262144;
	public const int32 MCI_DGV_RECORD_VIDEO_STREAM = 524288;
	public const int32 MCI_DGV_RESERVE_IN = 65536;
	public const int32 MCI_DGV_RESERVE_SIZE = 131072;
	public const int32 MCI_DGV_RESTORE_FROM = 65536;
	public const int32 MCI_DGV_RESTORE_AT = 131072;
	public const int32 MCI_DGV_SAVE_ABORT = 131072;
	public const int32 MCI_DGV_SAVE_KEEPRESERVE = 262144;
	public const int32 MCI_DGV_SET_SEEK_EXACTLY = 65536;
	public const int32 MCI_DGV_SET_SPEED = 131072;
	public const int32 MCI_DGV_SET_STILL = 262144;
	public const int32 MCI_DGV_SET_FILEFORMAT = 524288;
	public const int32 MCI_DGV_SETAUDIO_OVER = 65536;
	public const int32 MCI_DGV_SETAUDIO_CLOCKTIME = 131072;
	public const int32 MCI_DGV_SETAUDIO_ALG = 262144;
	public const int32 MCI_DGV_SETAUDIO_QUALITY = 524288;
	public const int32 MCI_DGV_SETAUDIO_RECORD = 1048576;
	public const int32 MCI_DGV_SETAUDIO_LEFT = 2097152;
	public const int32 MCI_DGV_SETAUDIO_RIGHT = 4194304;
	public const int32 MCI_DGV_SETAUDIO_ITEM = 8388608;
	public const int32 MCI_DGV_SETAUDIO_VALUE = 16777216;
	public const int32 MCI_DGV_SETAUDIO_INPUT = 33554432;
	public const int32 MCI_DGV_SETAUDIO_OUTPUT = 67108864;
	public const int32 MCI_DGV_SETAUDIO_TREBLE = 16384;
	public const int32 MCI_DGV_SETAUDIO_BASS = 16385;
	public const int32 MCI_DGV_SETAUDIO_VOLUME = 16386;
	public const int32 MCI_DGV_SETAUDIO_STREAM = 16387;
	public const int32 MCI_DGV_SETAUDIO_SOURCE = 16388;
	public const int32 MCI_DGV_SETAUDIO_SAMPLESPERSEC = 16389;
	public const int32 MCI_DGV_SETAUDIO_AVGBYTESPERSEC = 16390;
	public const int32 MCI_DGV_SETAUDIO_BLOCKALIGN = 16391;
	public const int32 MCI_DGV_SETAUDIO_BITSPERSAMPLE = 16392;
	public const int32 MCI_DGV_SETAUDIO_SOURCE_STEREO = 0;
	public const int32 MCI_DGV_SETAUDIO_SOURCE_LEFT = 1;
	public const int32 MCI_DGV_SETAUDIO_SOURCE_RIGHT = 2;
	public const int32 MCI_DGV_SETAUDIO_SOURCE_AVERAGE = 16384;
	public const int32 MCI_DGV_SETVIDEO_QUALITY = 65536;
	public const int32 MCI_DGV_SETVIDEO_ALG = 131072;
	public const int32 MCI_DGV_SETVIDEO_CLOCKTIME = 262144;
	public const int32 MCI_DGV_SETVIDEO_SRC_NUMBER = 524288;
	public const int32 MCI_DGV_SETVIDEO_ITEM = 1048576;
	public const int32 MCI_DGV_SETVIDEO_OVER = 2097152;
	public const int32 MCI_DGV_SETVIDEO_RECORD = 4194304;
	public const int32 MCI_DGV_SETVIDEO_STILL = 8388608;
	public const int32 MCI_DGV_SETVIDEO_VALUE = 16777216;
	public const int32 MCI_DGV_SETVIDEO_INPUT = 33554432;
	public const int32 MCI_DGV_SETVIDEO_OUTPUT = 67108864;
	public const int32 MCI_DGV_SETVIDEO_SRC_NTSC = 16384;
	public const int32 MCI_DGV_SETVIDEO_SRC_RGB = 16385;
	public const int32 MCI_DGV_SETVIDEO_SRC_SVIDEO = 16386;
	public const int32 MCI_DGV_SETVIDEO_SRC_PAL = 16387;
	public const int32 MCI_DGV_SETVIDEO_SRC_SECAM = 16388;
	public const int32 MCI_DGV_SETVIDEO_SRC_GENERIC = 16389;
	public const int32 MCI_DGV_SETVIDEO_BRIGHTNESS = 16384;
	public const int32 MCI_DGV_SETVIDEO_COLOR = 16385;
	public const int32 MCI_DGV_SETVIDEO_CONTRAST = 16386;
	public const int32 MCI_DGV_SETVIDEO_TINT = 16387;
	public const int32 MCI_DGV_SETVIDEO_SHARPNESS = 16388;
	public const int32 MCI_DGV_SETVIDEO_GAMMA = 16389;
	public const int32 MCI_DGV_SETVIDEO_STREAM = 16390;
	public const int32 MCI_DGV_SETVIDEO_PALHANDLE = 16391;
	public const int32 MCI_DGV_SETVIDEO_FRAME_RATE = 16392;
	public const int32 MCI_DGV_SETVIDEO_SOURCE = 16393;
	public const int32 MCI_DGV_SETVIDEO_KEY_INDEX = 16394;
	public const int32 MCI_DGV_SETVIDEO_KEY_COLOR = 16395;
	public const int32 MCI_DGV_SETVIDEO_BITSPERPEL = 16396;
	public const int32 MCI_DGV_SIGNAL_AT = 65536;
	public const int32 MCI_DGV_SIGNAL_EVERY = 131072;
	public const int32 MCI_DGV_SIGNAL_USERVAL = 262144;
	public const int32 MCI_DGV_SIGNAL_CANCEL = 524288;
	public const int32 MCI_DGV_SIGNAL_POSITION = 1048576;
	public const int32 MCI_DGV_STATUS_NOMINAL = 131072;
	public const int32 MCI_DGV_STATUS_REFERENCE = 262144;
	public const int32 MCI_DGV_STATUS_LEFT = 524288;
	public const int32 MCI_DGV_STATUS_RIGHT = 1048576;
	public const int32 MCI_DGV_STATUS_DISKSPACE = 2097152;
	public const int32 MCI_DGV_STATUS_INPUT = 4194304;
	public const int32 MCI_DGV_STATUS_OUTPUT = 8388608;
	public const int32 MCI_DGV_STATUS_RECORD = 16777216;
	public const int32 MCI_DGV_STATUS_AUDIO_INPUT = 16384;
	public const int32 MCI_DGV_STATUS_HWND = 16385;
	public const int32 MCI_DGV_STATUS_SPEED = 16387;
	public const int32 MCI_DGV_STATUS_HPAL = 16388;
	public const int32 MCI_DGV_STATUS_BRIGHTNESS = 16389;
	public const int32 MCI_DGV_STATUS_COLOR = 16390;
	public const int32 MCI_DGV_STATUS_CONTRAST = 16391;
	public const int32 MCI_DGV_STATUS_FILEFORMAT = 16392;
	public const int32 MCI_DGV_STATUS_AUDIO_SOURCE = 16393;
	public const int32 MCI_DGV_STATUS_GAMMA = 16394;
	public const int32 MCI_DGV_STATUS_MONITOR = 16395;
	public const int32 MCI_DGV_STATUS_MONITOR_METHOD = 16396;
	public const int32 MCI_DGV_STATUS_FRAME_RATE = 16398;
	public const int32 MCI_DGV_STATUS_BASS = 16399;
	public const int32 MCI_DGV_STATUS_SIZE = 16400;
	public const int32 MCI_DGV_STATUS_SEEK_EXACTLY = 16401;
	public const int32 MCI_DGV_STATUS_SHARPNESS = 16402;
	public const int32 MCI_DGV_STATUS_SMPTE = 16403;
	public const int32 MCI_DGV_STATUS_AUDIO = 16404;
	public const int32 MCI_DGV_STATUS_TINT = 16405;
	public const int32 MCI_DGV_STATUS_TREBLE = 16406;
	public const int32 MCI_DGV_STATUS_UNSAVED = 16407;
	public const int32 MCI_DGV_STATUS_VIDEO = 16408;
	public const int32 MCI_DGV_STATUS_VOLUME = 16409;
	public const int32 MCI_DGV_STATUS_AUDIO_RECORD = 16410;
	public const int32 MCI_DGV_STATUS_VIDEO_SOURCE = 16411;
	public const int32 MCI_DGV_STATUS_VIDEO_RECORD = 16412;
	public const int32 MCI_DGV_STATUS_STILL_FILEFORMAT = 16413;
	public const int32 MCI_DGV_STATUS_VIDEO_SRC_NUM = 16414;
	public const int32 MCI_DGV_STATUS_FILE_MODE = 16415;
	public const int32 MCI_DGV_STATUS_FILE_COMPLETION = 16416;
	public const int32 MCI_DGV_STATUS_WINDOW_VISIBLE = 16417;
	public const int32 MCI_DGV_STATUS_WINDOW_MINIMIZED = 16418;
	public const int32 MCI_DGV_STATUS_WINDOW_MAXIMIZED = 16419;
	public const int32 MCI_DGV_STATUS_KEY_INDEX = 16420;
	public const int32 MCI_DGV_STATUS_KEY_COLOR = 16421;
	public const int32 MCI_DGV_STATUS_PAUSE_MODE = 16422;
	public const int32 MCI_DGV_STATUS_SAMPLESPERSEC = 16423;
	public const int32 MCI_DGV_STATUS_AVGBYTESPERSEC = 16424;
	public const int32 MCI_DGV_STATUS_BLOCKALIGN = 16425;
	public const int32 MCI_DGV_STATUS_BITSPERSAMPLE = 16426;
	public const int32 MCI_DGV_STATUS_BITSPERPEL = 16427;
	public const int32 MCI_DGV_STATUS_FORWARD = 16428;
	public const int32 MCI_DGV_STATUS_AUDIO_STREAM = 16429;
	public const int32 MCI_DGV_STATUS_VIDEO_STREAM = 16430;
	public const int32 MCI_DGV_STEP_REVERSE = 65536;
	public const int32 MCI_DGV_STEP_FRAMES = 131072;
	public const int32 MCI_DGV_STOP_HOLD = 65536;
	public const int32 MCI_DGV_UPDATE_HDC = 131072;
	public const int32 MCI_DGV_UPDATE_PAINT = 262144;
	public const int32 MCI_DGV_WHERE_SOURCE = 131072;
	public const int32 MCI_DGV_WHERE_DESTINATION = 262144;
	public const int32 MCI_DGV_WHERE_FRAME = 524288;
	public const int32 MCI_DGV_WHERE_VIDEO = 1048576;
	public const int32 MCI_DGV_WHERE_WINDOW = 2097152;
	public const int32 MCI_DGV_WHERE_MAX = 4194304;
	public const int32 MCI_DGV_WINDOW_HWND = 65536;
	public const int32 MCI_DGV_WINDOW_STATE = 262144;
	public const int32 MCI_DGV_WINDOW_TEXT = 524288;
	public const int32 MCI_DGV_WINDOW_DEFAULT = 0;
	public const uint32 MM_CREATIVE = 2;
	public const uint32 MM_MEDIAVISION = 3;
	public const uint32 MM_FUJITSU = 4;
	public const uint32 MM_PRAGMATRAX = 5;
	public const uint32 MM_CYRIX = 6;
	public const uint32 MM_PHILIPS_SPEECH_PROCESSING = 7;
	public const uint32 MM_NETXL = 8;
	public const uint32 MM_ZYXEL = 9;
	public const uint32 MM_BECUBED = 10;
	public const uint32 MM_AARDVARK = 11;
	public const uint32 MM_BINTEC = 12;
	public const uint32 MM_HEWLETT_PACKARD = 13;
	public const uint32 MM_ACULAB = 14;
	public const uint32 MM_FAITH = 15;
	public const uint32 MM_MITEL = 16;
	public const uint32 MM_QUANTUM3D = 17;
	public const uint32 MM_SNI = 18;
	public const uint32 MM_EMU = 19;
	public const uint32 MM_ARTISOFT = 20;
	public const uint32 MM_TURTLE_BEACH = 21;
	public const uint32 MM_IBM = 22;
	public const uint32 MM_VOCALTEC = 23;
	public const uint32 MM_ROLAND = 24;
	public const uint32 MM_DSP_SOLUTIONS = 25;
	public const uint32 MM_NEC = 26;
	public const uint32 MM_ATI = 27;
	public const uint32 MM_WANGLABS = 28;
	public const uint32 MM_TANDY = 29;
	public const uint32 MM_VOYETRA = 30;
	public const uint32 MM_ANTEX = 31;
	public const uint32 MM_ICL_PS = 32;
	public const uint32 MM_INTEL = 33;
	public const uint32 MM_GRAVIS = 34;
	public const uint32 MM_VAL = 35;
	public const uint32 MM_INTERACTIVE = 36;
	public const uint32 MM_YAMAHA = 37;
	public const uint32 MM_EVEREX = 38;
	public const uint32 MM_ECHO = 39;
	public const uint32 MM_SIERRA = 40;
	public const uint32 MM_CAT = 41;
	public const uint32 MM_APPS = 42;
	public const uint32 MM_DSP_GROUP = 43;
	public const uint32 MM_MELABS = 44;
	public const uint32 MM_COMPUTER_FRIENDS = 45;
	public const uint32 MM_ESS = 46;
	public const uint32 MM_AUDIOFILE = 47;
	public const uint32 MM_MOTOROLA = 48;
	public const uint32 MM_CANOPUS = 49;
	public const uint32 MM_EPSON = 50;
	public const uint32 MM_TRUEVISION = 51;
	public const uint32 MM_AZTECH = 52;
	public const uint32 MM_VIDEOLOGIC = 53;
	public const uint32 MM_SCALACS = 54;
	public const uint32 MM_KORG = 55;
	public const uint32 MM_APT = 56;
	public const uint32 MM_ICS = 57;
	public const uint32 MM_ITERATEDSYS = 58;
	public const uint32 MM_METHEUS = 59;
	public const uint32 MM_LOGITECH = 60;
	public const uint32 MM_WINNOV = 61;
	public const uint32 MM_NCR = 62;
	public const uint32 MM_EXAN = 63;
	public const uint32 MM_AST = 64;
	public const uint32 MM_WILLOWPOND = 65;
	public const uint32 MM_SONICFOUNDRY = 66;
	public const uint32 MM_VITEC = 67;
	public const uint32 MM_MOSCOM = 68;
	public const uint32 MM_SILICONSOFT = 69;
	public const uint32 MM_TERRATEC = 70;
	public const uint32 MM_MEDIASONIC = 71;
	public const uint32 MM_SANYO = 72;
	public const uint32 MM_SUPERMAC = 73;
	public const uint32 MM_AUDIOPT = 74;
	public const uint32 MM_NOGATECH = 75;
	public const uint32 MM_SPEECHCOMP = 76;
	public const uint32 MM_AHEAD = 77;
	public const uint32 MM_DOLBY = 78;
	public const uint32 MM_OKI = 79;
	public const uint32 MM_AURAVISION = 80;
	public const uint32 MM_OLIVETTI = 81;
	public const uint32 MM_IOMAGIC = 82;
	public const uint32 MM_MATSUSHITA = 83;
	public const uint32 MM_CONTROLRES = 84;
	public const uint32 MM_XEBEC = 85;
	public const uint32 MM_NEWMEDIA = 86;
	public const uint32 MM_NMS = 87;
	public const uint32 MM_LYRRUS = 88;
	public const uint32 MM_COMPUSIC = 89;
	public const uint32 MM_OPTI = 90;
	public const uint32 MM_ADLACC = 91;
	public const uint32 MM_COMPAQ = 92;
	public const uint32 MM_DIALOGIC = 93;
	public const uint32 MM_INSOFT = 94;
	public const uint32 MM_MPTUS = 95;
	public const uint32 MM_WEITEK = 96;
	public const uint32 MM_LERNOUT_AND_HAUSPIE = 97;
	public const uint32 MM_QCIAR = 98;
	public const uint32 MM_APPLE = 99;
	public const uint32 MM_DIGITAL = 100;
	public const uint32 MM_MOTU = 101;
	public const uint32 MM_WORKBIT = 102;
	public const uint32 MM_OSITECH = 103;
	public const uint32 MM_MIRO = 104;
	public const uint32 MM_CIRRUSLOGIC = 105;
	public const uint32 MM_ISOLUTION = 106;
	public const uint32 MM_HORIZONS = 107;
	public const uint32 MM_CONCEPTS = 108;
	public const uint32 MM_VTG = 109;
	public const uint32 MM_RADIUS = 110;
	public const uint32 MM_ROCKWELL = 111;
	public const uint32 MM_XYZ = 112;
	public const uint32 MM_OPCODE = 113;
	public const uint32 MM_VOXWARE = 114;
	public const uint32 MM_NORTHERN_TELECOM = 115;
	public const uint32 MM_APICOM = 116;
	public const uint32 MM_GRANDE = 117;
	public const uint32 MM_ADDX = 118;
	public const uint32 MM_WILDCAT = 119;
	public const uint32 MM_RHETOREX = 120;
	public const uint32 MM_BROOKTREE = 121;
	public const uint32 MM_ENSONIQ = 125;
	public const uint32 MM_FAST = 126;
	public const uint32 MM_NVIDIA = 127;
	public const uint32 MM_OKSORI = 128;
	public const uint32 MM_DIACOUSTICS = 129;
	public const uint32 MM_GULBRANSEN = 130;
	public const uint32 MM_KAY_ELEMETRICS = 131;
	public const uint32 MM_CRYSTAL = 132;
	public const uint32 MM_SPLASH_STUDIOS = 133;
	public const uint32 MM_QUARTERDECK = 134;
	public const uint32 MM_TDK = 135;
	public const uint32 MM_DIGITAL_AUDIO_LABS = 136;
	public const uint32 MM_SEERSYS = 137;
	public const uint32 MM_PICTURETEL = 138;
	public const uint32 MM_ATT_MICROELECTRONICS = 139;
	public const uint32 MM_OSPREY = 140;
	public const uint32 MM_MEDIATRIX = 141;
	public const uint32 MM_SOUNDESIGNS = 142;
	public const uint32 MM_ALDIGITAL = 143;
	public const uint32 MM_SPECTRUM_SIGNAL_PROCESSING = 144;
	public const uint32 MM_ECS = 145;
	public const uint32 MM_AMD = 146;
	public const uint32 MM_COREDYNAMICS = 147;
	public const uint32 MM_CANAM = 148;
	public const uint32 MM_SOFTSOUND = 149;
	public const uint32 MM_NORRIS = 150;
	public const uint32 MM_DDD = 151;
	public const uint32 MM_EUPHONICS = 152;
	public const uint32 MM_PRECEPT = 153;
	public const uint32 MM_CRYSTAL_NET = 154;
	public const uint32 MM_CHROMATIC = 155;
	public const uint32 MM_VOICEINFO = 156;
	public const uint32 MM_VIENNASYS = 157;
	public const uint32 MM_CONNECTIX = 158;
	public const uint32 MM_GADGETLABS = 159;
	public const uint32 MM_FRONTIER = 160;
	public const uint32 MM_VIONA = 161;
	public const uint32 MM_CASIO = 162;
	public const uint32 MM_DIAMONDMM = 163;
	public const uint32 MM_S3 = 164;
	public const uint32 MM_DVISION = 165;
	public const uint32 MM_NETSCAPE = 166;
	public const uint32 MM_SOUNDSPACE = 167;
	public const uint32 MM_VANKOEVERING = 168;
	public const uint32 MM_QTEAM = 169;
	public const uint32 MM_ZEFIRO = 170;
	public const uint32 MM_STUDER = 171;
	public const uint32 MM_FRAUNHOFER_IIS = 172;
	public const uint32 MM_QUICKNET = 173;
	public const uint32 MM_ALARIS = 174;
	public const uint32 MM_SICRESOURCE = 175;
	public const uint32 MM_NEOMAGIC = 176;
	public const uint32 MM_MERGING_TECHNOLOGIES = 177;
	public const uint32 MM_XIRLINK = 178;
	public const uint32 MM_COLORGRAPH = 179;
	public const uint32 MM_OTI = 180;
	public const uint32 MM_AUREAL = 181;
	public const uint32 MM_VIVO = 182;
	public const uint32 MM_SHARP = 183;
	public const uint32 MM_LUCENT = 184;
	public const uint32 MM_ATT = 185;
	public const uint32 MM_SUNCOM = 186;
	public const uint32 MM_SORVIS = 187;
	public const uint32 MM_INVISION = 188;
	public const uint32 MM_BERKOM = 189;
	public const uint32 MM_MARIAN = 190;
	public const uint32 MM_DPSINC = 191;
	public const uint32 MM_BCB = 192;
	public const uint32 MM_MOTIONPIXELS = 193;
	public const uint32 MM_QDESIGN = 194;
	public const uint32 MM_NMP = 195;
	public const uint32 MM_DATAFUSION = 196;
	public const uint32 MM_DUCK = 197;
	public const uint32 MM_FTR = 198;
	public const uint32 MM_BERCOS = 199;
	public const uint32 MM_ONLIVE = 200;
	public const uint32 MM_SIEMENS_SBC = 201;
	public const uint32 MM_TERALOGIC = 202;
	public const uint32 MM_PHONET = 203;
	public const uint32 MM_WINBOND = 204;
	public const uint32 MM_VIRTUALMUSIC = 205;
	public const uint32 MM_ENET = 206;
	public const uint32 MM_GUILLEMOT = 207;
	public const uint32 MM_EMAGIC = 208;
	public const uint32 MM_MWM = 209;
	public const uint32 MM_PACIFICRESEARCH = 210;
	public const uint32 MM_SIPROLAB = 211;
	public const uint32 MM_LYNX = 212;
	public const uint32 MM_SPECTRUM_PRODUCTIONS = 213;
	public const uint32 MM_DICTAPHONE = 214;
	public const uint32 MM_QUALCOMM = 215;
	public const uint32 MM_RZS = 216;
	public const uint32 MM_AUDIOSCIENCE = 217;
	public const uint32 MM_PINNACLE = 218;
	public const uint32 MM_EES = 219;
	public const uint32 MM_HAFTMANN = 220;
	public const uint32 MM_LUCID = 221;
	public const uint32 MM_HEADSPACE = 222;
	public const uint32 MM_UNISYS = 223;
	public const uint32 MM_LUMINOSITI = 224;
	public const uint32 MM_ACTIVEVOICE = 225;
	public const uint32 MM_DTS = 226;
	public const uint32 MM_DIGIGRAM = 227;
	public const uint32 MM_SOFTLAB_NSK = 228;
	public const uint32 MM_FORTEMEDIA = 229;
	public const uint32 MM_SONORUS = 230;
	public const uint32 MM_ARRAY = 231;
	public const uint32 MM_DATARAN = 232;
	public const uint32 MM_I_LINK = 233;
	public const uint32 MM_SELSIUS_SYSTEMS = 234;
	public const uint32 MM_ADMOS = 235;
	public const uint32 MM_LEXICON = 236;
	public const uint32 MM_SGI = 237;
	public const uint32 MM_IPI = 238;
	public const uint32 MM_ICE = 239;
	public const uint32 MM_VQST = 240;
	public const uint32 MM_ETEK = 241;
	public const uint32 MM_CS = 242;
	public const uint32 MM_ALESIS = 243;
	public const uint32 MM_INTERNET = 244;
	public const uint32 MM_SONY = 245;
	public const uint32 MM_HYPERACTIVE = 246;
	public const uint32 MM_UHER_INFORMATIC = 247;
	public const uint32 MM_SYDEC_NV = 248;
	public const uint32 MM_FLEXION = 249;
	public const uint32 MM_VIA = 250;
	public const uint32 MM_MICRONAS = 251;
	public const uint32 MM_ANALOGDEVICES = 252;
	public const uint32 MM_HP = 253;
	public const uint32 MM_MATROX_DIV = 254;
	public const uint32 MM_QUICKAUDIO = 255;
	public const uint32 MM_YOUCOM = 256;
	public const uint32 MM_RICHMOND = 257;
	public const uint32 MM_IODD = 258;
	public const uint32 MM_ICCC = 259;
	public const uint32 MM_3COM = 260;
	public const uint32 MM_MALDEN = 261;
	public const uint32 MM_3DFX = 262;
	public const uint32 MM_MINDMAKER = 263;
	public const uint32 MM_TELEKOL = 264;
	public const uint32 MM_ST_MICROELECTRONICS = 265;
	public const uint32 MM_ALGOVISION = 266;
	public const uint32 MM_UNMAPPED = 65535;
	public const uint32 MM_PID_UNMAPPED = 65535;
	public const uint32 MM_PCSPEAKER_WAVEOUT = 13;
	public const uint32 MM_MSFT_WSS_WAVEIN = 14;
	public const uint32 MM_MSFT_WSS_WAVEOUT = 15;
	public const uint32 MM_MSFT_WSS_FMSYNTH_STEREO = 16;
	public const uint32 MM_MSFT_WSS_MIXER = 17;
	public const uint32 MM_MSFT_WSS_OEM_WAVEIN = 18;
	public const uint32 MM_MSFT_WSS_OEM_WAVEOUT = 19;
	public const uint32 MM_MSFT_WSS_OEM_FMSYNTH_STEREO = 20;
	public const uint32 MM_MSFT_WSS_AUX = 21;
	public const uint32 MM_MSFT_WSS_OEM_AUX = 22;
	public const uint32 MM_MSFT_GENERIC_WAVEIN = 23;
	public const uint32 MM_MSFT_GENERIC_WAVEOUT = 24;
	public const uint32 MM_MSFT_GENERIC_MIDIIN = 25;
	public const uint32 MM_MSFT_GENERIC_MIDIOUT = 26;
	public const uint32 MM_MSFT_GENERIC_MIDISYNTH = 27;
	public const uint32 MM_MSFT_GENERIC_AUX_LINE = 28;
	public const uint32 MM_MSFT_GENERIC_AUX_MIC = 29;
	public const uint32 MM_MSFT_GENERIC_AUX_CD = 30;
	public const uint32 MM_MSFT_WSS_OEM_MIXER = 31;
	public const uint32 MM_MSFT_MSACM = 32;
	public const uint32 MM_MSFT_ACM_MSADPCM = 33;
	public const uint32 MM_MSFT_ACM_IMAADPCM = 34;
	public const uint32 MM_MSFT_ACM_MSFILTER = 35;
	public const uint32 MM_MSFT_ACM_GSM610 = 36;
	public const uint32 MM_MSFT_ACM_G711 = 37;
	public const uint32 MM_MSFT_ACM_PCM = 38;
	public const uint32 MM_WSS_SB16_WAVEIN = 39;
	public const uint32 MM_WSS_SB16_WAVEOUT = 40;
	public const uint32 MM_WSS_SB16_MIDIIN = 41;
	public const uint32 MM_WSS_SB16_MIDIOUT = 42;
	public const uint32 MM_WSS_SB16_SYNTH = 43;
	public const uint32 MM_WSS_SB16_AUX_LINE = 44;
	public const uint32 MM_WSS_SB16_AUX_CD = 45;
	public const uint32 MM_WSS_SB16_MIXER = 46;
	public const uint32 MM_WSS_SBPRO_WAVEIN = 47;
	public const uint32 MM_WSS_SBPRO_WAVEOUT = 48;
	public const uint32 MM_WSS_SBPRO_MIDIIN = 49;
	public const uint32 MM_WSS_SBPRO_MIDIOUT = 50;
	public const uint32 MM_WSS_SBPRO_SYNTH = 51;
	public const uint32 MM_WSS_SBPRO_AUX_LINE = 52;
	public const uint32 MM_WSS_SBPRO_AUX_CD = 53;
	public const uint32 MM_WSS_SBPRO_MIXER = 54;
	public const uint32 MM_MSFT_WSS_NT_WAVEIN = 55;
	public const uint32 MM_MSFT_WSS_NT_WAVEOUT = 56;
	public const uint32 MM_MSFT_WSS_NT_FMSYNTH_STEREO = 57;
	public const uint32 MM_MSFT_WSS_NT_MIXER = 58;
	public const uint32 MM_MSFT_WSS_NT_AUX = 59;
	public const uint32 MM_MSFT_SB16_WAVEIN = 60;
	public const uint32 MM_MSFT_SB16_WAVEOUT = 61;
	public const uint32 MM_MSFT_SB16_MIDIIN = 62;
	public const uint32 MM_MSFT_SB16_MIDIOUT = 63;
	public const uint32 MM_MSFT_SB16_SYNTH = 64;
	public const uint32 MM_MSFT_SB16_AUX_LINE = 65;
	public const uint32 MM_MSFT_SB16_AUX_CD = 66;
	public const uint32 MM_MSFT_SB16_MIXER = 67;
	public const uint32 MM_MSFT_SBPRO_WAVEIN = 68;
	public const uint32 MM_MSFT_SBPRO_WAVEOUT = 69;
	public const uint32 MM_MSFT_SBPRO_MIDIIN = 70;
	public const uint32 MM_MSFT_SBPRO_MIDIOUT = 71;
	public const uint32 MM_MSFT_SBPRO_SYNTH = 72;
	public const uint32 MM_MSFT_SBPRO_AUX_LINE = 73;
	public const uint32 MM_MSFT_SBPRO_AUX_CD = 74;
	public const uint32 MM_MSFT_SBPRO_MIXER = 75;
	public const uint32 MM_MSFT_MSOPL_SYNTH = 76;
	public const uint32 MM_MSFT_VMDMS_LINE_WAVEIN = 80;
	public const uint32 MM_MSFT_VMDMS_LINE_WAVEOUT = 81;
	public const uint32 MM_MSFT_VMDMS_HANDSET_WAVEIN = 82;
	public const uint32 MM_MSFT_VMDMS_HANDSET_WAVEOUT = 83;
	public const uint32 MM_MSFT_VMDMW_LINE_WAVEIN = 84;
	public const uint32 MM_MSFT_VMDMW_LINE_WAVEOUT = 85;
	public const uint32 MM_MSFT_VMDMW_HANDSET_WAVEIN = 86;
	public const uint32 MM_MSFT_VMDMW_HANDSET_WAVEOUT = 87;
	public const uint32 MM_MSFT_VMDMW_MIXER = 88;
	public const uint32 MM_MSFT_VMDM_GAME_WAVEOUT = 89;
	public const uint32 MM_MSFT_VMDM_GAME_WAVEIN = 90;
	public const uint32 MM_MSFT_ACM_MSNAUDIO = 91;
	public const uint32 MM_MSFT_ACM_MSG723 = 92;
	public const uint32 MM_MSFT_ACM_MSRT24 = 93;
	public const uint32 MM_MSFT_WDMAUDIO_WAVEOUT = 100;
	public const uint32 MM_MSFT_WDMAUDIO_WAVEIN = 101;
	public const uint32 MM_MSFT_WDMAUDIO_MIDIOUT = 102;
	public const uint32 MM_MSFT_WDMAUDIO_MIDIIN = 103;
	public const uint32 MM_MSFT_WDMAUDIO_MIXER = 104;
	public const uint32 MM_MSFT_WDMAUDIO_AUX = 105;
	public const uint32 MM_CREATIVE_SB15_WAVEIN = 1;
	public const uint32 MM_CREATIVE_SB20_WAVEIN = 2;
	public const uint32 MM_CREATIVE_SBPRO_WAVEIN = 3;
	public const uint32 MM_CREATIVE_SBP16_WAVEIN = 4;
	public const uint32 MM_CREATIVE_PHNBLST_WAVEIN = 5;
	public const uint32 MM_CREATIVE_SB15_WAVEOUT = 101;
	public const uint32 MM_CREATIVE_SB20_WAVEOUT = 102;
	public const uint32 MM_CREATIVE_SBPRO_WAVEOUT = 103;
	public const uint32 MM_CREATIVE_SBP16_WAVEOUT = 104;
	public const uint32 MM_CREATIVE_PHNBLST_WAVEOUT = 105;
	public const uint32 MM_CREATIVE_MIDIOUT = 201;
	public const uint32 MM_CREATIVE_MIDIIN = 202;
	public const uint32 MM_CREATIVE_FMSYNTH_MONO = 301;
	public const uint32 MM_CREATIVE_FMSYNTH_STEREO = 302;
	public const uint32 MM_CREATIVE_MIDI_AWE32 = 303;
	public const uint32 MM_CREATIVE_AUX_CD = 401;
	public const uint32 MM_CREATIVE_AUX_LINE = 402;
	public const uint32 MM_CREATIVE_AUX_MIC = 403;
	public const uint32 MM_CREATIVE_AUX_MASTER = 404;
	public const uint32 MM_CREATIVE_AUX_PCSPK = 405;
	public const uint32 MM_CREATIVE_AUX_WAVE = 406;
	public const uint32 MM_CREATIVE_AUX_MIDI = 407;
	public const uint32 MM_CREATIVE_SBPRO_MIXER = 408;
	public const uint32 MM_CREATIVE_SB16_MIXER = 409;
	public const uint32 MM_MEDIAVISION_PROAUDIO = 16;
	public const uint32 MM_PROAUD_MIDIOUT = 17;
	public const uint32 MM_PROAUD_MIDIIN = 18;
	public const uint32 MM_PROAUD_SYNTH = 19;
	public const uint32 MM_PROAUD_WAVEOUT = 20;
	public const uint32 MM_PROAUD_WAVEIN = 21;
	public const uint32 MM_PROAUD_MIXER = 22;
	public const uint32 MM_PROAUD_AUX = 23;
	public const uint32 MM_MEDIAVISION_THUNDER = 32;
	public const uint32 MM_THUNDER_SYNTH = 35;
	public const uint32 MM_THUNDER_WAVEOUT = 36;
	public const uint32 MM_THUNDER_WAVEIN = 37;
	public const uint32 MM_THUNDER_AUX = 39;
	public const uint32 MM_MEDIAVISION_TPORT = 64;
	public const uint32 MM_TPORT_WAVEOUT = 65;
	public const uint32 MM_TPORT_WAVEIN = 66;
	public const uint32 MM_TPORT_SYNTH = 67;
	public const uint32 MM_MEDIAVISION_PROAUDIO_PLUS = 80;
	public const uint32 MM_PROAUD_PLUS_MIDIOUT = 81;
	public const uint32 MM_PROAUD_PLUS_MIDIIN = 82;
	public const uint32 MM_PROAUD_PLUS_SYNTH = 83;
	public const uint32 MM_PROAUD_PLUS_WAVEOUT = 84;
	public const uint32 MM_PROAUD_PLUS_WAVEIN = 85;
	public const uint32 MM_PROAUD_PLUS_MIXER = 86;
	public const uint32 MM_PROAUD_PLUS_AUX = 87;
	public const uint32 MM_MEDIAVISION_PROAUDIO_16 = 96;
	public const uint32 MM_PROAUD_16_MIDIOUT = 97;
	public const uint32 MM_PROAUD_16_MIDIIN = 98;
	public const uint32 MM_PROAUD_16_SYNTH = 99;
	public const uint32 MM_PROAUD_16_WAVEOUT = 100;
	public const uint32 MM_PROAUD_16_WAVEIN = 101;
	public const uint32 MM_PROAUD_16_MIXER = 102;
	public const uint32 MM_PROAUD_16_AUX = 103;
	public const uint32 MM_MEDIAVISION_PROSTUDIO_16 = 96;
	public const uint32 MM_STUDIO_16_MIDIOUT = 97;
	public const uint32 MM_STUDIO_16_MIDIIN = 98;
	public const uint32 MM_STUDIO_16_SYNTH = 99;
	public const uint32 MM_STUDIO_16_WAVEOUT = 100;
	public const uint32 MM_STUDIO_16_WAVEIN = 101;
	public const uint32 MM_STUDIO_16_MIXER = 102;
	public const uint32 MM_STUDIO_16_AUX = 103;
	public const uint32 MM_MEDIAVISION_CDPC = 112;
	public const uint32 MM_CDPC_MIDIOUT = 113;
	public const uint32 MM_CDPC_MIDIIN = 114;
	public const uint32 MM_CDPC_SYNTH = 115;
	public const uint32 MM_CDPC_WAVEOUT = 116;
	public const uint32 MM_CDPC_WAVEIN = 117;
	public const uint32 MM_CDPC_MIXER = 118;
	public const uint32 MM_CDPC_AUX = 119;
	public const uint32 MM_MEDIAVISION_OPUS1208 = 128;
	public const uint32 MM_OPUS401_MIDIOUT = 129;
	public const uint32 MM_OPUS401_MIDIIN = 130;
	public const uint32 MM_OPUS1208_SYNTH = 131;
	public const uint32 MM_OPUS1208_WAVEOUT = 132;
	public const uint32 MM_OPUS1208_WAVEIN = 133;
	public const uint32 MM_OPUS1208_MIXER = 134;
	public const uint32 MM_OPUS1208_AUX = 135;
	public const uint32 MM_MEDIAVISION_OPUS1216 = 144;
	public const uint32 MM_OPUS1216_MIDIOUT = 145;
	public const uint32 MM_OPUS1216_MIDIIN = 146;
	public const uint32 MM_OPUS1216_SYNTH = 147;
	public const uint32 MM_OPUS1216_WAVEOUT = 148;
	public const uint32 MM_OPUS1216_WAVEIN = 149;
	public const uint32 MM_OPUS1216_MIXER = 150;
	public const uint32 MM_OPUS1216_AUX = 151;
	public const uint32 MM_CYRIX_XASYNTH = 1;
	public const uint32 MM_CYRIX_XAMIDIIN = 2;
	public const uint32 MM_CYRIX_XAMIDIOUT = 3;
	public const uint32 MM_CYRIX_XAWAVEIN = 4;
	public const uint32 MM_CYRIX_XAWAVEOUT = 5;
	public const uint32 MM_CYRIX_XAAUX = 6;
	public const uint32 MM_CYRIX_XAMIXER = 7;
	public const uint32 MM_PHILIPS_ACM_LPCBB = 1;
	public const uint32 MM_NETXL_XLVIDEO = 1;
	public const uint32 MM_ZYXEL_ACM_ADPCM = 1;
	public const uint32 MM_AARDVARK_STUDIO12_WAVEOUT = 1;
	public const uint32 MM_AARDVARK_STUDIO12_WAVEIN = 2;
	public const uint32 MM_AARDVARK_STUDIO88_WAVEOUT = 3;
	public const uint32 MM_AARDVARK_STUDIO88_WAVEIN = 4;
	public const uint32 MM_BINTEC_TAPI_WAVE = 1;
	public const uint32 MM_HEWLETT_PACKARD_CU_CODEC = 1;
	public const uint32 MM_MITEL_TALKTO_LINE_WAVEOUT = 100;
	public const uint32 MM_MITEL_TALKTO_LINE_WAVEIN = 101;
	public const uint32 MM_MITEL_TALKTO_HANDSET_WAVEOUT = 102;
	public const uint32 MM_MITEL_TALKTO_HANDSET_WAVEIN = 103;
	public const uint32 MM_MITEL_TALKTO_BRIDGED_WAVEOUT = 104;
	public const uint32 MM_MITEL_TALKTO_BRIDGED_WAVEIN = 105;
	public const uint32 MM_MITEL_MPA_HANDSET_WAVEOUT = 200;
	public const uint32 MM_MITEL_MPA_HANDSET_WAVEIN = 201;
	public const uint32 MM_MITEL_MPA_HANDSFREE_WAVEOUT = 202;
	public const uint32 MM_MITEL_MPA_HANDSFREE_WAVEIN = 203;
	public const uint32 MM_MITEL_MPA_LINE1_WAVEOUT = 204;
	public const uint32 MM_MITEL_MPA_LINE1_WAVEIN = 205;
	public const uint32 MM_MITEL_MPA_LINE2_WAVEOUT = 206;
	public const uint32 MM_MITEL_MPA_LINE2_WAVEIN = 207;
	public const uint32 MM_MITEL_MEDIAPATH_WAVEOUT = 300;
	public const uint32 MM_MITEL_MEDIAPATH_WAVEIN = 301;
	public const uint32 MM_SNI_ACM_G721 = 1;
	public const uint32 MM_EMU_APSSYNTH = 1;
	public const uint32 MM_EMU_APSMIDIIN = 2;
	public const uint32 MM_EMU_APSMIDIOUT = 3;
	public const uint32 MM_EMU_APSWAVEIN = 4;
	public const uint32 MM_EMU_APSWAVEOUT = 5;
	public const uint32 MM_ARTISOFT_SBWAVEIN = 1;
	public const uint32 MM_ARTISOFT_SBWAVEOUT = 2;
	public const uint32 MM_TBS_TROPEZ_WAVEIN = 37;
	public const uint32 MM_TBS_TROPEZ_WAVEOUT = 38;
	public const uint32 MM_TBS_TROPEZ_AUX1 = 39;
	public const uint32 MM_TBS_TROPEZ_AUX2 = 40;
	public const uint32 MM_TBS_TROPEZ_LINE = 41;
	public const uint32 MM_MMOTION_WAVEAUX = 1;
	public const uint32 MM_MMOTION_WAVEOUT = 2;
	public const uint32 MM_MMOTION_WAVEIN = 3;
	public const uint32 MM_IBM_PCMCIA_WAVEIN = 11;
	public const uint32 MM_IBM_PCMCIA_WAVEOUT = 12;
	public const uint32 MM_IBM_PCMCIA_SYNTH = 13;
	public const uint32 MM_IBM_PCMCIA_MIDIIN = 14;
	public const uint32 MM_IBM_PCMCIA_MIDIOUT = 15;
	public const uint32 MM_IBM_PCMCIA_AUX = 16;
	public const uint32 MM_IBM_THINKPAD200 = 17;
	public const uint32 MM_IBM_MWAVE_WAVEIN = 18;
	public const uint32 MM_IBM_MWAVE_WAVEOUT = 19;
	public const uint32 MM_IBM_MWAVE_MIXER = 20;
	public const uint32 MM_IBM_MWAVE_MIDIIN = 21;
	public const uint32 MM_IBM_MWAVE_MIDIOUT = 22;
	public const uint32 MM_IBM_MWAVE_AUX = 23;
	public const uint32 MM_IBM_WC_MIDIOUT = 30;
	public const uint32 MM_IBM_WC_WAVEOUT = 31;
	public const uint32 MM_IBM_WC_MIXEROUT = 33;
	public const uint32 MM_VOCALTEC_WAVEOUT = 1;
	public const uint32 MM_VOCALTEC_WAVEIN = 2;
	public const uint32 MM_ROLAND_RAP10_MIDIOUT = 10;
	public const uint32 MM_ROLAND_RAP10_MIDIIN = 11;
	public const uint32 MM_ROLAND_RAP10_SYNTH = 12;
	public const uint32 MM_ROLAND_RAP10_WAVEOUT = 13;
	public const uint32 MM_ROLAND_RAP10_WAVEIN = 14;
	public const uint32 MM_ROLAND_MPU401_MIDIOUT = 15;
	public const uint32 MM_ROLAND_MPU401_MIDIIN = 16;
	public const uint32 MM_ROLAND_SMPU_MIDIOUTA = 17;
	public const uint32 MM_ROLAND_SMPU_MIDIOUTB = 18;
	public const uint32 MM_ROLAND_SMPU_MIDIINA = 19;
	public const uint32 MM_ROLAND_SMPU_MIDIINB = 20;
	public const uint32 MM_ROLAND_SC7_MIDIOUT = 21;
	public const uint32 MM_ROLAND_SC7_MIDIIN = 22;
	public const uint32 MM_ROLAND_SERIAL_MIDIOUT = 23;
	public const uint32 MM_ROLAND_SERIAL_MIDIIN = 24;
	public const uint32 MM_ROLAND_SCP_MIDIOUT = 38;
	public const uint32 MM_ROLAND_SCP_MIDIIN = 39;
	public const uint32 MM_ROLAND_SCP_WAVEOUT = 40;
	public const uint32 MM_ROLAND_SCP_WAVEIN = 41;
	public const uint32 MM_ROLAND_SCP_MIXER = 42;
	public const uint32 MM_ROLAND_SCP_AUX = 48;
	public const uint32 MM_DSP_SOLUTIONS_WAVEOUT = 1;
	public const uint32 MM_DSP_SOLUTIONS_WAVEIN = 2;
	public const uint32 MM_DSP_SOLUTIONS_SYNTH = 3;
	public const uint32 MM_DSP_SOLUTIONS_AUX = 4;
	public const uint32 MM_NEC_73_86_SYNTH = 5;
	public const uint32 MM_NEC_73_86_WAVEOUT = 6;
	public const uint32 MM_NEC_73_86_WAVEIN = 7;
	public const uint32 MM_NEC_26_SYNTH = 9;
	public const uint32 MM_NEC_MPU401_MIDIOUT = 10;
	public const uint32 MM_NEC_MPU401_MIDIIN = 11;
	public const uint32 MM_NEC_JOYSTICK = 12;
	public const uint32 MM_WANGLABS_WAVEIN1 = 1;
	public const uint32 MM_WANGLABS_WAVEOUT1 = 2;
	public const uint32 MM_TANDY_VISWAVEIN = 1;
	public const uint32 MM_TANDY_VISWAVEOUT = 2;
	public const uint32 MM_TANDY_VISBIOSSYNTH = 3;
	public const uint32 MM_TANDY_SENS_MMAWAVEIN = 4;
	public const uint32 MM_TANDY_SENS_MMAWAVEOUT = 5;
	public const uint32 MM_TANDY_SENS_MMAMIDIIN = 6;
	public const uint32 MM_TANDY_SENS_MMAMIDIOUT = 7;
	public const uint32 MM_TANDY_SENS_VISWAVEOUT = 8;
	public const uint32 MM_TANDY_PSSJWAVEIN = 9;
	public const uint32 MM_TANDY_PSSJWAVEOUT = 10;
	public const uint32 MM_ANTEX_SX12_WAVEIN = 1;
	public const uint32 MM_ANTEX_SX12_WAVEOUT = 2;
	public const uint32 MM_ANTEX_SX15_WAVEIN = 3;
	public const uint32 MM_ANTEX_SX15_WAVEOUT = 4;
	public const uint32 MM_ANTEX_VP625_WAVEIN = 5;
	public const uint32 MM_ANTEX_VP625_WAVEOUT = 6;
	public const uint32 MM_ANTEX_AUDIOPORT22_WAVEIN = 7;
	public const uint32 MM_ANTEX_AUDIOPORT22_WAVEOUT = 8;
	public const uint32 MM_ANTEX_AUDIOPORT22_FEEDTHRU = 9;
	public const uint32 MM_INTELOPD_WAVEIN = 1;
	public const uint32 MM_INTELOPD_WAVEOUT = 101;
	public const uint32 MM_INTELOPD_AUX = 401;
	public const uint32 MM_INTEL_NSPMODEMLINEIN = 501;
	public const uint32 MM_INTEL_NSPMODEMLINEOUT = 502;
	public const uint32 MM_VAL_MICROKEY_AP_WAVEIN = 1;
	public const uint32 MM_VAL_MICROKEY_AP_WAVEOUT = 2;
	public const uint32 MM_INTERACTIVE_WAVEIN = 69;
	public const uint32 MM_INTERACTIVE_WAVEOUT = 69;
	public const uint32 MM_YAMAHA_GSS_SYNTH = 1;
	public const uint32 MM_YAMAHA_GSS_WAVEOUT = 2;
	public const uint32 MM_YAMAHA_GSS_WAVEIN = 3;
	public const uint32 MM_YAMAHA_GSS_MIDIOUT = 4;
	public const uint32 MM_YAMAHA_GSS_MIDIIN = 5;
	public const uint32 MM_YAMAHA_GSS_AUX = 6;
	public const uint32 MM_YAMAHA_SERIAL_MIDIOUT = 7;
	public const uint32 MM_YAMAHA_SERIAL_MIDIIN = 8;
	public const uint32 MM_YAMAHA_OPL3SA_WAVEOUT = 16;
	public const uint32 MM_YAMAHA_OPL3SA_WAVEIN = 17;
	public const uint32 MM_YAMAHA_OPL3SA_FMSYNTH = 18;
	public const uint32 MM_YAMAHA_OPL3SA_YSYNTH = 19;
	public const uint32 MM_YAMAHA_OPL3SA_MIDIOUT = 20;
	public const uint32 MM_YAMAHA_OPL3SA_MIDIIN = 21;
	public const uint32 MM_YAMAHA_OPL3SA_MIXER = 23;
	public const uint32 MM_YAMAHA_OPL3SA_JOYSTICK = 24;
	public const uint32 MM_YAMAHA_YMF724LEG_MIDIOUT = 25;
	public const uint32 MM_YAMAHA_YMF724LEG_MIDIIN = 26;
	public const uint32 MM_YAMAHA_YMF724_WAVEOUT = 27;
	public const uint32 MM_YAMAHA_YMF724_WAVEIN = 28;
	public const uint32 MM_YAMAHA_YMF724_MIDIOUT = 29;
	public const uint32 MM_YAMAHA_YMF724_AUX = 30;
	public const uint32 MM_YAMAHA_YMF724_MIXER = 31;
	public const uint32 MM_YAMAHA_YMF724LEG_FMSYNTH = 32;
	public const uint32 MM_YAMAHA_YMF724LEG_MIXER = 33;
	public const uint32 MM_YAMAHA_SXG_MIDIOUT = 34;
	public const uint32 MM_YAMAHA_SXG_WAVEOUT = 35;
	public const uint32 MM_YAMAHA_SXG_MIXER = 36;
	public const uint32 MM_YAMAHA_ACXG_WAVEIN = 37;
	public const uint32 MM_YAMAHA_ACXG_WAVEOUT = 38;
	public const uint32 MM_YAMAHA_ACXG_MIDIOUT = 39;
	public const uint32 MM_YAMAHA_ACXG_MIXER = 40;
	public const uint32 MM_YAMAHA_ACXG_AUX = 41;
	public const uint32 MM_EVEREX_CARRIER = 1;
	public const uint32 MM_ECHO_SYNTH = 1;
	public const uint32 MM_ECHO_WAVEOUT = 2;
	public const uint32 MM_ECHO_WAVEIN = 3;
	public const uint32 MM_ECHO_MIDIOUT = 4;
	public const uint32 MM_ECHO_MIDIIN = 5;
	public const uint32 MM_ECHO_AUX = 6;
	public const uint32 MM_SIERRA_ARIA_MIDIOUT = 20;
	public const uint32 MM_SIERRA_ARIA_MIDIIN = 21;
	public const uint32 MM_SIERRA_ARIA_SYNTH = 22;
	public const uint32 MM_SIERRA_ARIA_WAVEOUT = 23;
	public const uint32 MM_SIERRA_ARIA_WAVEIN = 24;
	public const uint32 MM_SIERRA_ARIA_AUX = 25;
	public const uint32 MM_SIERRA_ARIA_AUX2 = 32;
	public const uint32 MM_SIERRA_QUARTET_WAVEIN = 80;
	public const uint32 MM_SIERRA_QUARTET_WAVEOUT = 81;
	public const uint32 MM_SIERRA_QUARTET_MIDIIN = 82;
	public const uint32 MM_SIERRA_QUARTET_MIDIOUT = 83;
	public const uint32 MM_SIERRA_QUARTET_SYNTH = 84;
	public const uint32 MM_SIERRA_QUARTET_AUX_CD = 85;
	public const uint32 MM_SIERRA_QUARTET_AUX_LINE = 86;
	public const uint32 MM_SIERRA_QUARTET_AUX_MODEM = 87;
	public const uint32 MM_SIERRA_QUARTET_MIXER = 88;
	public const uint32 MM_CAT_WAVEOUT = 1;
	public const uint32 MM_DSP_GROUP_TRUESPEECH = 1;
	public const uint32 MM_MELABS_MIDI2GO = 1;
	public const uint32 MM_ESS_AMWAVEOUT = 1;
	public const uint32 MM_ESS_AMWAVEIN = 2;
	public const uint32 MM_ESS_AMAUX = 3;
	public const uint32 MM_ESS_AMSYNTH = 4;
	public const uint32 MM_ESS_AMMIDIOUT = 5;
	public const uint32 MM_ESS_AMMIDIIN = 6;
	public const uint32 MM_ESS_MIXER = 7;
	public const uint32 MM_ESS_AUX_CD = 8;
	public const uint32 MM_ESS_MPU401_MIDIOUT = 9;
	public const uint32 MM_ESS_MPU401_MIDIIN = 10;
	public const uint32 MM_ESS_ES488_WAVEOUT = 16;
	public const uint32 MM_ESS_ES488_WAVEIN = 17;
	public const uint32 MM_ESS_ES488_MIXER = 18;
	public const uint32 MM_ESS_ES688_WAVEOUT = 19;
	public const uint32 MM_ESS_ES688_WAVEIN = 20;
	public const uint32 MM_ESS_ES688_MIXER = 21;
	public const uint32 MM_ESS_ES1488_WAVEOUT = 22;
	public const uint32 MM_ESS_ES1488_WAVEIN = 23;
	public const uint32 MM_ESS_ES1488_MIXER = 24;
	public const uint32 MM_ESS_ES1688_WAVEOUT = 25;
	public const uint32 MM_ESS_ES1688_WAVEIN = 26;
	public const uint32 MM_ESS_ES1688_MIXER = 27;
	public const uint32 MM_ESS_ES1788_WAVEOUT = 28;
	public const uint32 MM_ESS_ES1788_WAVEIN = 29;
	public const uint32 MM_ESS_ES1788_MIXER = 30;
	public const uint32 MM_ESS_ES1888_WAVEOUT = 31;
	public const uint32 MM_ESS_ES1888_WAVEIN = 32;
	public const uint32 MM_ESS_ES1888_MIXER = 33;
	public const uint32 MM_ESS_ES1868_WAVEOUT = 34;
	public const uint32 MM_ESS_ES1868_WAVEIN = 35;
	public const uint32 MM_ESS_ES1868_MIXER = 36;
	public const uint32 MM_ESS_ES1878_WAVEOUT = 37;
	public const uint32 MM_ESS_ES1878_WAVEIN = 38;
	public const uint32 MM_ESS_ES1878_MIXER = 39;
	public const uint32 MM_CANOPUS_ACM_DVREX = 1;
	public const uint32 MM_EPS_FMSND = 1;
	public const uint32 MM_TRUEVISION_WAVEIN1 = 1;
	public const uint32 MM_TRUEVISION_WAVEOUT1 = 2;
	public const uint32 MM_AZTECH_MIDIOUT = 3;
	public const uint32 MM_AZTECH_MIDIIN = 4;
	public const uint32 MM_AZTECH_WAVEIN = 17;
	public const uint32 MM_AZTECH_WAVEOUT = 18;
	public const uint32 MM_AZTECH_FMSYNTH = 20;
	public const uint32 MM_AZTECH_MIXER = 21;
	public const uint32 MM_AZTECH_PRO16_WAVEIN = 33;
	public const uint32 MM_AZTECH_PRO16_WAVEOUT = 34;
	public const uint32 MM_AZTECH_PRO16_FMSYNTH = 38;
	public const uint32 MM_AZTECH_DSP16_WAVEIN = 65;
	public const uint32 MM_AZTECH_DSP16_WAVEOUT = 66;
	public const uint32 MM_AZTECH_DSP16_FMSYNTH = 68;
	public const uint32 MM_AZTECH_DSP16_WAVESYNTH = 70;
	public const uint32 MM_AZTECH_NOVA16_WAVEIN = 71;
	public const uint32 MM_AZTECH_NOVA16_WAVEOUT = 72;
	public const uint32 MM_AZTECH_NOVA16_MIXER = 73;
	public const uint32 MM_AZTECH_WASH16_WAVEIN = 74;
	public const uint32 MM_AZTECH_WASH16_WAVEOUT = 75;
	public const uint32 MM_AZTECH_WASH16_MIXER = 76;
	public const uint32 MM_AZTECH_AUX_CD = 401;
	public const uint32 MM_AZTECH_AUX_LINE = 402;
	public const uint32 MM_AZTECH_AUX_MIC = 403;
	public const uint32 MM_AZTECH_AUX = 404;
	public const uint32 MM_VIDEOLOGIC_MSWAVEIN = 1;
	public const uint32 MM_VIDEOLOGIC_MSWAVEOUT = 2;
	public const uint32 MM_KORG_PCIF_MIDIOUT = 1;
	public const uint32 MM_KORG_PCIF_MIDIIN = 2;
	public const uint32 MM_KORG_1212IO_MSWAVEIN = 3;
	public const uint32 MM_KORG_1212IO_MSWAVEOUT = 4;
	public const uint32 MM_APT_ACE100CD = 1;
	public const uint32 MM_ICS_WAVEDECK_WAVEOUT = 1;
	public const uint32 MM_ICS_WAVEDECK_WAVEIN = 2;
	public const uint32 MM_ICS_WAVEDECK_MIXER = 3;
	public const uint32 MM_ICS_WAVEDECK_AUX = 4;
	public const uint32 MM_ICS_WAVEDECK_SYNTH = 5;
	public const uint32 MM_ICS_WAVEDEC_SB_WAVEOUT = 6;
	public const uint32 MM_ICS_WAVEDEC_SB_WAVEIN = 7;
	public const uint32 MM_ICS_WAVEDEC_SB_FM_MIDIOUT = 8;
	public const uint32 MM_ICS_WAVEDEC_SB_MPU401_MIDIOUT = 9;
	public const uint32 MM_ICS_WAVEDEC_SB_MPU401_MIDIIN = 10;
	public const uint32 MM_ICS_WAVEDEC_SB_MIXER = 11;
	public const uint32 MM_ICS_WAVEDEC_SB_AUX = 12;
	public const uint32 MM_ICS_2115_LITE_MIDIOUT = 13;
	public const uint32 MM_ICS_2120_LITE_MIDIOUT = 14;
	public const uint32 MM_ITERATEDSYS_FUFCODEC = 1;
	public const uint32 MM_METHEUS_ZIPPER = 1;
	public const uint32 MM_WINNOV_CAVIAR_WAVEIN = 1;
	public const uint32 MM_WINNOV_CAVIAR_WAVEOUT = 2;
	public const uint32 MM_WINNOV_CAVIAR_VIDC = 3;
	public const uint32 MM_WINNOV_CAVIAR_CHAMPAGNE = 4;
	public const uint32 MM_WINNOV_CAVIAR_YUV8 = 5;
	public const uint32 MM_NCR_BA_WAVEIN = 1;
	public const uint32 MM_NCR_BA_WAVEOUT = 2;
	public const uint32 MM_NCR_BA_SYNTH = 3;
	public const uint32 MM_NCR_BA_AUX = 4;
	public const uint32 MM_NCR_BA_MIXER = 5;
	public const uint32 MM_AST_MODEMWAVE_WAVEIN = 13;
	public const uint32 MM_AST_MODEMWAVE_WAVEOUT = 14;
	public const uint32 MM_WILLOWPOND_FMSYNTH_STEREO = 20;
	public const uint32 MM_WILLOWPOND_MPU401 = 21;
	public const uint32 MM_WILLOWPOND_SNDPORT_WAVEIN = 100;
	public const uint32 MM_WILLOWPOND_SNDPORT_WAVEOUT = 101;
	public const uint32 MM_WILLOWPOND_SNDPORT_MIXER = 102;
	public const uint32 MM_WILLOWPOND_SNDPORT_AUX = 103;
	public const uint32 MM_WILLOWPOND_PH_WAVEIN = 104;
	public const uint32 MM_WILLOWPOND_PH_WAVEOUT = 105;
	public const uint32 MM_WILLOWPOND_PH_MIXER = 106;
	public const uint32 MM_WILLOWPOND_PH_AUX = 107;
	public const uint32 MM_WILLOPOND_SNDCOMM_WAVEIN = 108;
	public const uint32 MM_WILLOWPOND_SNDCOMM_WAVEOUT = 109;
	public const uint32 MM_WILLOWPOND_SNDCOMM_MIXER = 110;
	public const uint32 MM_WILLOWPOND_SNDCOMM_AUX = 111;
	public const uint32 MM_WILLOWPOND_GENERIC_WAVEIN = 112;
	public const uint32 MM_WILLOWPOND_GENERIC_WAVEOUT = 113;
	public const uint32 MM_WILLOWPOND_GENERIC_MIXER = 114;
	public const uint32 MM_WILLOWPOND_GENERIC_AUX = 115;
	public const uint32 MM_VITEC_VMAKER = 1;
	public const uint32 MM_VITEC_VMPRO = 2;
	public const uint32 MM_MOSCOM_VPC2400_IN = 1;
	public const uint32 MM_MOSCOM_VPC2400_OUT = 2;
	public const uint32 MM_SILICONSOFT_SC1_WAVEIN = 1;
	public const uint32 MM_SILICONSOFT_SC1_WAVEOUT = 2;
	public const uint32 MM_SILICONSOFT_SC2_WAVEIN = 3;
	public const uint32 MM_SILICONSOFT_SC2_WAVEOUT = 4;
	public const uint32 MM_SILICONSOFT_SOUNDJR2_WAVEOUT = 5;
	public const uint32 MM_SILICONSOFT_SOUNDJR2PR_WAVEIN = 6;
	public const uint32 MM_SILICONSOFT_SOUNDJR2PR_WAVEOUT = 7;
	public const uint32 MM_SILICONSOFT_SOUNDJR3_WAVEOUT = 8;
	public const uint32 MM_TTEWS_WAVEIN = 1;
	public const uint32 MM_TTEWS_WAVEOUT = 2;
	public const uint32 MM_TTEWS_MIDIIN = 3;
	public const uint32 MM_TTEWS_MIDIOUT = 4;
	public const uint32 MM_TTEWS_MIDISYNTH = 5;
	public const uint32 MM_TTEWS_MIDIMONITOR = 6;
	public const uint32 MM_TTEWS_VMIDIIN = 7;
	public const uint32 MM_TTEWS_VMIDIOUT = 8;
	public const uint32 MM_TTEWS_AUX = 9;
	public const uint32 MM_TTEWS_MIXER = 10;
	public const uint32 MM_MEDIASONIC_ACM_G723 = 1;
	public const uint32 MM_MEDIASONIC_ICOM = 2;
	public const uint32 MM_ICOM_WAVEIN = 3;
	public const uint32 MM_ICOM_WAVEOUT = 4;
	public const uint32 MM_ICOM_MIXER = 5;
	public const uint32 MM_ICOM_AUX = 6;
	public const uint32 MM_ICOM_LINE = 7;
	public const uint32 MM_SANYO_ACM_LD_ADPCM = 1;
	public const uint32 MM_AHEAD_MULTISOUND = 1;
	public const uint32 MM_AHEAD_SOUNDBLASTER = 2;
	public const uint32 MM_AHEAD_PROAUDIO = 3;
	public const uint32 MM_AHEAD_GENERIC = 4;
	public const uint32 MM_OLIVETTI_WAVEIN = 1;
	public const uint32 MM_OLIVETTI_WAVEOUT = 2;
	public const uint32 MM_OLIVETTI_MIXER = 3;
	public const uint32 MM_OLIVETTI_AUX = 4;
	public const uint32 MM_OLIVETTI_MIDIIN = 5;
	public const uint32 MM_OLIVETTI_MIDIOUT = 6;
	public const uint32 MM_OLIVETTI_SYNTH = 7;
	public const uint32 MM_OLIVETTI_JOYSTICK = 8;
	public const uint32 MM_OLIVETTI_ACM_GSM = 9;
	public const uint32 MM_OLIVETTI_ACM_ADPCM = 10;
	public const uint32 MM_OLIVETTI_ACM_CELP = 11;
	public const uint32 MM_OLIVETTI_ACM_SBC = 12;
	public const uint32 MM_OLIVETTI_ACM_OPR = 13;
	public const uint32 MM_IOMAGIC_TEMPO_WAVEOUT = 1;
	public const uint32 MM_IOMAGIC_TEMPO_WAVEIN = 2;
	public const uint32 MM_IOMAGIC_TEMPO_SYNTH = 3;
	public const uint32 MM_IOMAGIC_TEMPO_MIDIOUT = 4;
	public const uint32 MM_IOMAGIC_TEMPO_MXDOUT = 5;
	public const uint32 MM_IOMAGIC_TEMPO_AUXOUT = 6;
	public const uint32 MM_MATSUSHITA_WAVEIN = 1;
	public const uint32 MM_MATSUSHITA_WAVEOUT = 2;
	public const uint32 MM_MATSUSHITA_FMSYNTH_STEREO = 3;
	public const uint32 MM_MATSUSHITA_MIXER = 4;
	public const uint32 MM_MATSUSHITA_AUX = 5;
	public const uint32 MM_NEWMEDIA_WAVJAMMER = 1;
	public const uint32 MM_LYRRUS_BRIDGE_GUITAR = 1;
	public const uint32 MM_OPTI_M16_FMSYNTH_STEREO = 1;
	public const uint32 MM_OPTI_M16_MIDIIN = 2;
	public const uint32 MM_OPTI_M16_MIDIOUT = 3;
	public const uint32 MM_OPTI_M16_WAVEIN = 4;
	public const uint32 MM_OPTI_M16_WAVEOUT = 5;
	public const uint32 MM_OPTI_M16_MIXER = 6;
	public const uint32 MM_OPTI_M16_AUX = 7;
	public const uint32 MM_OPTI_P16_FMSYNTH_STEREO = 16;
	public const uint32 MM_OPTI_P16_MIDIIN = 17;
	public const uint32 MM_OPTI_P16_MIDIOUT = 18;
	public const uint32 MM_OPTI_P16_WAVEIN = 19;
	public const uint32 MM_OPTI_P16_WAVEOUT = 20;
	public const uint32 MM_OPTI_P16_MIXER = 21;
	public const uint32 MM_OPTI_P16_AUX = 22;
	public const uint32 MM_OPTI_M32_WAVEIN = 32;
	public const uint32 MM_OPTI_M32_WAVEOUT = 33;
	public const uint32 MM_OPTI_M32_MIDIIN = 34;
	public const uint32 MM_OPTI_M32_MIDIOUT = 35;
	public const uint32 MM_OPTI_M32_SYNTH_STEREO = 36;
	public const uint32 MM_OPTI_M32_MIXER = 37;
	public const uint32 MM_OPTI_M32_AUX = 38;
	public const uint32 MM_COMPAQ_BB_WAVEIN = 1;
	public const uint32 MM_COMPAQ_BB_WAVEOUT = 2;
	public const uint32 MM_COMPAQ_BB_WAVEAUX = 3;
	public const uint32 MM_MPTUS_SPWAVEOUT = 1;
	public const uint32 MM_LERNOUT_ANDHAUSPIE_LHCODECACM = 1;
	public const uint32 MM_DIGITAL_AV320_WAVEIN = 1;
	public const uint32 MM_DIGITAL_AV320_WAVEOUT = 2;
	public const uint32 MM_DIGITAL_ACM_G723 = 3;
	public const uint32 MM_DIGITAL_ICM_H263 = 4;
	public const uint32 MM_DIGITAL_ICM_H261 = 5;
	public const uint32 MM_MOTU_MTP_MIDIOUT_ALL = 100;
	public const uint32 MM_MOTU_MTP_MIDIIN_1 = 101;
	public const uint32 MM_MOTU_MTP_MIDIOUT_1 = 101;
	public const uint32 MM_MOTU_MTP_MIDIIN_2 = 102;
	public const uint32 MM_MOTU_MTP_MIDIOUT_2 = 102;
	public const uint32 MM_MOTU_MTP_MIDIIN_3 = 103;
	public const uint32 MM_MOTU_MTP_MIDIOUT_3 = 103;
	public const uint32 MM_MOTU_MTP_MIDIIN_4 = 104;
	public const uint32 MM_MOTU_MTP_MIDIOUT_4 = 104;
	public const uint32 MM_MOTU_MTP_MIDIIN_5 = 105;
	public const uint32 MM_MOTU_MTP_MIDIOUT_5 = 105;
	public const uint32 MM_MOTU_MTP_MIDIIN_6 = 106;
	public const uint32 MM_MOTU_MTP_MIDIOUT_6 = 106;
	public const uint32 MM_MOTU_MTP_MIDIIN_7 = 107;
	public const uint32 MM_MOTU_MTP_MIDIOUT_7 = 107;
	public const uint32 MM_MOTU_MTP_MIDIIN_8 = 108;
	public const uint32 MM_MOTU_MTP_MIDIOUT_8 = 108;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_ALL = 200;
	public const uint32 MM_MOTU_MTPII_MIDIIN_SYNC = 200;
	public const uint32 MM_MOTU_MTPII_MIDIIN_1 = 201;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_1 = 201;
	public const uint32 MM_MOTU_MTPII_MIDIIN_2 = 202;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_2 = 202;
	public const uint32 MM_MOTU_MTPII_MIDIIN_3 = 203;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_3 = 203;
	public const uint32 MM_MOTU_MTPII_MIDIIN_4 = 204;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_4 = 204;
	public const uint32 MM_MOTU_MTPII_MIDIIN_5 = 205;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_5 = 205;
	public const uint32 MM_MOTU_MTPII_MIDIIN_6 = 206;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_6 = 206;
	public const uint32 MM_MOTU_MTPII_MIDIIN_7 = 207;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_7 = 207;
	public const uint32 MM_MOTU_MTPII_MIDIIN_8 = 208;
	public const uint32 MM_MOTU_MTPII_MIDIOUT_8 = 208;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_1 = 209;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_1 = 209;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_2 = 210;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_2 = 210;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_3 = 211;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_3 = 211;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_4 = 212;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_4 = 212;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_5 = 213;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_5 = 213;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_6 = 214;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_6 = 214;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_7 = 215;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_7 = 215;
	public const uint32 MM_MOTU_MTPII_NET_MIDIIN_8 = 216;
	public const uint32 MM_MOTU_MTPII_NET_MIDIOUT_8 = 216;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_ALL = 300;
	public const uint32 MM_MOTU_MXP_MIDIIN_SYNC = 300;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIIN_1 = 301;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_1 = 301;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIIN_2 = 302;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_2 = 302;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIIN_3 = 303;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_3 = 303;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIIN_4 = 304;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_4 = 304;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIIN_5 = 305;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_5 = 305;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIIN_6 = 306;
	public const uint32 MM_MOTU_MXP_MIDIIN_MIDIOUT_6 = 306;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_ALL = 400;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_SYNC = 400;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_1 = 401;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_1 = 401;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_2 = 402;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_2 = 402;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_3 = 403;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_3 = 403;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_4 = 404;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_4 = 404;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_5 = 405;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_5 = 405;
	public const uint32 MM_MOTU_MXPMPU_MIDIIN_6 = 406;
	public const uint32 MM_MOTU_MXPMPU_MIDIOUT_6 = 406;
	public const uint32 MM_MOTU_MXN_MIDIOUT_ALL = 500;
	public const uint32 MM_MOTU_MXN_MIDIIN_SYNC = 500;
	public const uint32 MM_MOTU_MXN_MIDIIN_1 = 501;
	public const uint32 MM_MOTU_MXN_MIDIOUT_1 = 501;
	public const uint32 MM_MOTU_MXN_MIDIIN_2 = 502;
	public const uint32 MM_MOTU_MXN_MIDIOUT_2 = 502;
	public const uint32 MM_MOTU_MXN_MIDIIN_3 = 503;
	public const uint32 MM_MOTU_MXN_MIDIOUT_3 = 503;
	public const uint32 MM_MOTU_MXN_MIDIIN_4 = 504;
	public const uint32 MM_MOTU_MXN_MIDIOUT_4 = 504;
	public const uint32 MM_MOTU_FLYER_MIDI_IN_SYNC = 600;
	public const uint32 MM_MOTU_FLYER_MIDI_IN_A = 601;
	public const uint32 MM_MOTU_FLYER_MIDI_OUT_A = 601;
	public const uint32 MM_MOTU_FLYER_MIDI_IN_B = 602;
	public const uint32 MM_MOTU_FLYER_MIDI_OUT_B = 602;
	public const uint32 MM_MOTU_PKX_MIDI_IN_SYNC = 700;
	public const uint32 MM_MOTU_PKX_MIDI_IN_A = 701;
	public const uint32 MM_MOTU_PKX_MIDI_OUT_A = 701;
	public const uint32 MM_MOTU_PKX_MIDI_IN_B = 702;
	public const uint32 MM_MOTU_PKX_MIDI_OUT_B = 702;
	public const uint32 MM_MOTU_DTX_MIDI_IN_SYNC = 800;
	public const uint32 MM_MOTU_DTX_MIDI_IN_A = 801;
	public const uint32 MM_MOTU_DTX_MIDI_OUT_A = 801;
	public const uint32 MM_MOTU_DTX_MIDI_IN_B = 802;
	public const uint32 MM_MOTU_DTX_MIDI_OUT_B = 802;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_ALL = 900;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_SYNC = 900;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_1 = 901;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_1 = 901;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_2 = 902;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_2 = 902;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_3 = 903;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_3 = 903;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_4 = 904;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_4 = 904;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_5 = 905;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_5 = 905;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_6 = 906;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_6 = 906;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_7 = 907;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_7 = 907;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_8 = 908;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_8 = 908;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_1 = 909;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_1 = 909;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_2 = 910;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_2 = 910;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_3 = 911;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_3 = 911;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_4 = 912;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_4 = 912;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_5 = 913;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_5 = 913;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_6 = 914;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_6 = 914;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_7 = 915;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_7 = 915;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIIN_8 = 916;
	public const uint32 MM_MOTU_MTPAV_NET_MIDIOUT_8 = 916;
	public const uint32 MM_MOTU_MTPAV_MIDIIN_ADAT = 917;
	public const uint32 MM_MOTU_MTPAV_MIDIOUT_ADAT = 917;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_SYNC = 1000;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_ALL = 1000;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_1 = 1001;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_1 = 1001;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_2 = 1002;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_2 = 1002;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_3 = 1003;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_3 = 1003;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_4 = 1004;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_4 = 1004;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_5 = 1005;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_5 = 1005;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_6 = 1006;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_6 = 1006;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_7 = 1007;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_7 = 1007;
	public const uint32 MM_MOTU_MXPXT_MIDIOUT_8 = 1008;
	public const uint32 MM_MOTU_MXPXT_MIDIIN_8 = 1008;
	public const uint32 MM_WORKBIT_MIXER = 1;
	public const uint32 MM_WORKBIT_WAVEOUT = 2;
	public const uint32 MM_WORKBIT_WAVEIN = 3;
	public const uint32 MM_WORKBIT_MIDIIN = 4;
	public const uint32 MM_WORKBIT_MIDIOUT = 5;
	public const uint32 MM_WORKBIT_FMSYNTH = 6;
	public const uint32 MM_WORKBIT_AUX = 7;
	public const uint32 MM_WORKBIT_JOYSTICK = 8;
	public const uint32 MM_OSITECH_TRUMPCARD = 1;
	public const uint32 MM_MIRO_MOVIEPRO = 1;
	public const uint32 MM_MIRO_VIDEOD1 = 2;
	public const uint32 MM_MIRO_VIDEODC1TV = 3;
	public const uint32 MM_MIRO_VIDEOTD = 4;
	public const uint32 MM_MIRO_DC30_WAVEOUT = 5;
	public const uint32 MM_MIRO_DC30_WAVEIN = 6;
	public const uint32 MM_MIRO_DC30_MIX = 7;
	public const uint32 MM_ISOLUTION_PASCAL = 1;
	public const uint32 MM_VOICEMIXER = 1;
	public const uint32 ROCKWELL_WA1_WAVEIN = 100;
	public const uint32 ROCKWELL_WA1_WAVEOUT = 101;
	public const uint32 ROCKWELL_WA1_SYNTH = 102;
	public const uint32 ROCKWELL_WA1_MIXER = 103;
	public const uint32 ROCKWELL_WA1_MPU401_IN = 104;
	public const uint32 ROCKWELL_WA1_MPU401_OUT = 105;
	public const uint32 ROCKWELL_WA2_WAVEIN = 200;
	public const uint32 ROCKWELL_WA2_WAVEOUT = 201;
	public const uint32 ROCKWELL_WA2_SYNTH = 202;
	public const uint32 ROCKWELL_WA2_MIXER = 203;
	public const uint32 ROCKWELL_WA2_MPU401_IN = 204;
	public const uint32 ROCKWELL_WA2_MPU401_OUT = 205;
	public const uint32 MM_VOXWARE_CODEC = 1;
	public const uint32 MM_NORTEL_MPXAC_WAVEIN = 1;
	public const uint32 MM_NORTEL_MPXAC_WAVEOUT = 2;
	public const uint32 MM_ADDX_PCTV_DIGITALMIX = 1;
	public const uint32 MM_ADDX_PCTV_WAVEIN = 2;
	public const uint32 MM_ADDX_PCTV_WAVEOUT = 3;
	public const uint32 MM_ADDX_PCTV_MIXER = 4;
	public const uint32 MM_ADDX_PCTV_AUX_CD = 5;
	public const uint32 MM_ADDX_PCTV_AUX_LINE = 6;
	public const uint32 MM_WILDCAT_AUTOSCOREMIDIIN = 1;
	public const uint32 MM_RHETOREX_WAVEIN = 1;
	public const uint32 MM_RHETOREX_WAVEOUT = 2;
	public const uint32 MM_BTV_WAVEIN = 1;
	public const uint32 MM_BTV_WAVEOUT = 2;
	public const uint32 MM_BTV_MIDIIN = 3;
	public const uint32 MM_BTV_MIDIOUT = 4;
	public const uint32 MM_BTV_MIDISYNTH = 5;
	public const uint32 MM_BTV_AUX_LINE = 6;
	public const uint32 MM_BTV_AUX_MIC = 7;
	public const uint32 MM_BTV_AUX_CD = 8;
	public const uint32 MM_BTV_DIGITALIN = 9;
	public const uint32 MM_BTV_DIGITALOUT = 10;
	public const uint32 MM_BTV_MIDIWAVESTREAM = 11;
	public const uint32 MM_BTV_MIXER = 12;
	public const uint32 MM_ENSONIQ_SOUNDSCAPE = 16;
	public const uint32 MM_SOUNDSCAPE_WAVEOUT = 17;
	public const uint32 MM_SOUNDSCAPE_WAVEOUT_AUX = 18;
	public const uint32 MM_SOUNDSCAPE_WAVEIN = 19;
	public const uint32 MM_SOUNDSCAPE_MIDIOUT = 20;
	public const uint32 MM_SOUNDSCAPE_MIDIIN = 21;
	public const uint32 MM_SOUNDSCAPE_SYNTH = 22;
	public const uint32 MM_SOUNDSCAPE_MIXER = 23;
	public const uint32 MM_SOUNDSCAPE_AUX = 24;
	public const uint32 MM_NVIDIA_WAVEOUT = 1;
	public const uint32 MM_NVIDIA_WAVEIN = 2;
	public const uint32 MM_NVIDIA_MIDIOUT = 3;
	public const uint32 MM_NVIDIA_MIDIIN = 4;
	public const uint32 MM_NVIDIA_GAMEPORT = 5;
	public const uint32 MM_NVIDIA_MIXER = 6;
	public const uint32 MM_NVIDIA_AUX = 7;
	public const uint32 MM_OKSORI_BASE = 0;
	public const uint32 MM_OKSORI_OSR8_WAVEOUT = 1;
	public const uint32 MM_OKSORI_OSR8_WAVEIN = 2;
	public const uint32 MM_OKSORI_OSR16_WAVEOUT = 3;
	public const uint32 MM_OKSORI_OSR16_WAVEIN = 4;
	public const uint32 MM_OKSORI_FM_OPL4 = 5;
	public const uint32 MM_OKSORI_MIX_MASTER = 6;
	public const uint32 MM_OKSORI_MIX_WAVE = 7;
	public const uint32 MM_OKSORI_MIX_FM = 8;
	public const uint32 MM_OKSORI_MIX_LINE = 9;
	public const uint32 MM_OKSORI_MIX_CD = 10;
	public const uint32 MM_OKSORI_MIX_MIC = 11;
	public const uint32 MM_OKSORI_MIX_ECHO = 12;
	public const uint32 MM_OKSORI_MIX_AUX1 = 13;
	public const uint32 MM_OKSORI_MIX_LINE1 = 14;
	public const uint32 MM_OKSORI_EXT_MIC1 = 15;
	public const uint32 MM_OKSORI_EXT_MIC2 = 16;
	public const uint32 MM_OKSORI_MIDIOUT = 17;
	public const uint32 MM_OKSORI_MIDIIN = 18;
	public const uint32 MM_OKSORI_MPEG_CDVISION = 19;
	public const uint32 MM_DIACOUSTICS_DRUM_ACTION = 1;
	public const uint32 MM_KAY_ELEMETRICS_CSL = 17152;
	public const uint32 MM_KAY_ELEMETRICS_CSL_DAT = 17160;
	public const uint32 MM_KAY_ELEMETRICS_CSL_4CHANNEL = 17161;
	public const uint32 MM_CRYSTAL_CS4232_WAVEIN = 1;
	public const uint32 MM_CRYSTAL_CS4232_WAVEOUT = 2;
	public const uint32 MM_CRYSTAL_CS4232_WAVEMIXER = 3;
	public const uint32 MM_CRYSTAL_CS4232_WAVEAUX_AUX1 = 4;
	public const uint32 MM_CRYSTAL_CS4232_WAVEAUX_AUX2 = 5;
	public const uint32 MM_CRYSTAL_CS4232_WAVEAUX_LINE = 6;
	public const uint32 MM_CRYSTAL_CS4232_WAVEAUX_MONO = 7;
	public const uint32 MM_CRYSTAL_CS4232_WAVEAUX_MASTER = 8;
	public const uint32 MM_CRYSTAL_CS4232_MIDIIN = 9;
	public const uint32 MM_CRYSTAL_CS4232_MIDIOUT = 10;
	public const uint32 MM_CRYSTAL_CS4232_INPUTGAIN_AUX1 = 13;
	public const uint32 MM_CRYSTAL_CS4232_INPUTGAIN_LOOP = 14;
	public const uint32 MM_CRYSTAL_SOUND_FUSION_WAVEIN = 21;
	public const uint32 MM_CRYSTAL_SOUND_FUSION_WAVEOUT = 22;
	public const uint32 MM_CRYSTAL_SOUND_FUSION_MIXER = 23;
	public const uint32 MM_CRYSTAL_SOUND_FUSION_MIDIIN = 24;
	public const uint32 MM_CRYSTAL_SOUND_FUSION_MIDIOUT = 25;
	public const uint32 MM_CRYSTAL_SOUND_FUSION_JOYSTICK = 26;
	public const uint32 MM_QUARTERDECK_LHWAVEIN = 0;
	public const uint32 MM_QUARTERDECK_LHWAVEOUT = 1;
	public const uint32 MM_TDK_MW_MIDI_SYNTH = 1;
	public const uint32 MM_TDK_MW_MIDI_IN = 2;
	public const uint32 MM_TDK_MW_MIDI_OUT = 3;
	public const uint32 MM_TDK_MW_WAVE_IN = 4;
	public const uint32 MM_TDK_MW_WAVE_OUT = 5;
	public const uint32 MM_TDK_MW_AUX = 6;
	public const uint32 MM_TDK_MW_MIXER = 10;
	public const uint32 MM_TDK_MW_AUX_MASTER = 100;
	public const uint32 MM_TDK_MW_AUX_BASS = 101;
	public const uint32 MM_TDK_MW_AUX_TREBLE = 102;
	public const uint32 MM_TDK_MW_AUX_MIDI_VOL = 103;
	public const uint32 MM_TDK_MW_AUX_WAVE_VOL = 104;
	public const uint32 MM_TDK_MW_AUX_WAVE_RVB = 105;
	public const uint32 MM_TDK_MW_AUX_WAVE_CHR = 106;
	public const uint32 MM_TDK_MW_AUX_VOL = 107;
	public const uint32 MM_TDK_MW_AUX_RVB = 108;
	public const uint32 MM_TDK_MW_AUX_CHR = 109;
	public const uint32 MM_DIGITAL_AUDIO_LABS_TC = 1;
	public const uint32 MM_DIGITAL_AUDIO_LABS_DOC = 2;
	public const uint32 MM_DIGITAL_AUDIO_LABS_V8 = 16;
	public const uint32 MM_DIGITAL_AUDIO_LABS_CPRO = 17;
	public const uint32 MM_DIGITAL_AUDIO_LABS_VP = 18;
	public const uint32 MM_DIGITAL_AUDIO_LABS_CDLX = 19;
	public const uint32 MM_DIGITAL_AUDIO_LABS_CTDIF = 20;
	public const uint32 MM_SEERSYS_SEERSYNTH = 1;
	public const uint32 MM_SEERSYS_SEERWAVE = 2;
	public const uint32 MM_SEERSYS_SEERMIX = 3;
	public const uint32 MM_SEERSYS_WAVESYNTH = 4;
	public const uint32 MM_SEERSYS_WAVESYNTH_WG = 5;
	public const uint32 MM_SEERSYS_REALITY = 6;
	public const uint32 MM_OSPREY_1000WAVEIN = 1;
	public const uint32 MM_OSPREY_1000WAVEOUT = 2;
	public const uint32 MM_SOUNDESIGNS_WAVEIN = 1;
	public const uint32 MM_SOUNDESIGNS_WAVEOUT = 2;
	public const uint32 MM_SSP_SNDFESWAVEIN = 1;
	public const uint32 MM_SSP_SNDFESWAVEOUT = 2;
	public const uint32 MM_SSP_SNDFESMIDIIN = 3;
	public const uint32 MM_SSP_SNDFESMIDIOUT = 4;
	public const uint32 MM_SSP_SNDFESSYNTH = 5;
	public const uint32 MM_SSP_SNDFESMIX = 6;
	public const uint32 MM_SSP_SNDFESAUX = 7;
	public const uint32 MM_ECS_AADF_MIDI_IN = 10;
	public const uint32 MM_ECS_AADF_MIDI_OUT = 11;
	public const uint32 MM_ECS_AADF_WAVE2MIDI_IN = 12;
	public const uint32 MM_AMD_INTERWAVE_WAVEIN = 1;
	public const uint32 MM_AMD_INTERWAVE_WAVEOUT = 2;
	public const uint32 MM_AMD_INTERWAVE_SYNTH = 3;
	public const uint32 MM_AMD_INTERWAVE_MIXER1 = 4;
	public const uint32 MM_AMD_INTERWAVE_MIXER2 = 5;
	public const uint32 MM_AMD_INTERWAVE_JOYSTICK = 6;
	public const uint32 MM_AMD_INTERWAVE_EX_CD = 7;
	public const uint32 MM_AMD_INTERWAVE_MIDIIN = 8;
	public const uint32 MM_AMD_INTERWAVE_MIDIOUT = 9;
	public const uint32 MM_AMD_INTERWAVE_AUX1 = 10;
	public const uint32 MM_AMD_INTERWAVE_AUX2 = 11;
	public const uint32 MM_AMD_INTERWAVE_AUX_MIC = 12;
	public const uint32 MM_AMD_INTERWAVE_AUX_CD = 13;
	public const uint32 MM_AMD_INTERWAVE_MONO_IN = 14;
	public const uint32 MM_AMD_INTERWAVE_MONO_OUT = 15;
	public const uint32 MM_AMD_INTERWAVE_EX_TELEPHONY = 16;
	public const uint32 MM_AMD_INTERWAVE_WAVEOUT_BASE = 17;
	public const uint32 MM_AMD_INTERWAVE_WAVEOUT_TREBLE = 18;
	public const uint32 MM_AMD_INTERWAVE_STEREO_ENHANCED = 19;
	public const uint32 MM_COREDYNAMICS_DYNAMIXHR = 1;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_SYNTH = 2;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_MIDI_IN = 3;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_MIDI_OUT = 4;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_WAVE_IN = 5;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_WAVE_OUT = 6;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_AUDIO_IN = 7;
	public const uint32 MM_COREDYNAMICS_DYNASONIX_AUDIO_OUT = 8;
	public const uint32 MM_COREDYNAMICS_DYNAGRAFX_VGA = 9;
	public const uint32 MM_COREDYNAMICS_DYNAGRAFX_WAVE_IN = 10;
	public const uint32 MM_COREDYNAMICS_DYNAGRAFX_WAVE_OUT = 11;
	public const uint32 MM_CANAM_CBXWAVEOUT = 1;
	public const uint32 MM_CANAM_CBXWAVEIN = 2;
	public const uint32 MM_SOFTSOUND_CODEC = 1;
	public const uint32 MM_NORRIS_VOICELINK = 1;
	public const uint32 MM_DDD_MIDILINK_MIDIIN = 1;
	public const uint32 MM_DDD_MIDILINK_MIDIOUT = 2;
	public const uint32 MM_EUPHONICS_AUX_CD = 1;
	public const uint32 MM_EUPHONICS_AUX_LINE = 2;
	public const uint32 MM_EUPHONICS_AUX_MASTER = 3;
	public const uint32 MM_EUPHONICS_AUX_MIC = 4;
	public const uint32 MM_EUPHONICS_AUX_MIDI = 5;
	public const uint32 MM_EUPHONICS_AUX_WAVE = 6;
	public const uint32 MM_EUPHONICS_FMSYNTH_MONO = 7;
	public const uint32 MM_EUPHONICS_FMSYNTH_STEREO = 8;
	public const uint32 MM_EUPHONICS_MIDIIN = 9;
	public const uint32 MM_EUPHONICS_MIDIOUT = 10;
	public const uint32 MM_EUPHONICS_MIXER = 11;
	public const uint32 MM_EUPHONICS_WAVEIN = 12;
	public const uint32 MM_EUPHONICS_WAVEOUT = 13;
	public const uint32 MM_EUPHONICS_EUSYNTH = 14;
	public const uint32 CRYSTAL_NET_SFM_CODEC = 1;
	public const uint32 MM_CHROMATIC_M1 = 1;
	public const uint32 MM_CHROMATIC_M1_WAVEIN = 2;
	public const uint32 MM_CHROMATIC_M1_WAVEOUT = 3;
	public const uint32 MM_CHROMATIC_M1_FMSYNTH = 4;
	public const uint32 MM_CHROMATIC_M1_MIXER = 5;
	public const uint32 MM_CHROMATIC_M1_AUX = 6;
	public const uint32 MM_CHROMATIC_M1_AUX_CD = 7;
	public const uint32 MM_CHROMATIC_M1_MIDIIN = 8;
	public const uint32 MM_CHROMATIC_M1_MIDIOUT = 9;
	public const uint32 MM_CHROMATIC_M1_WTSYNTH = 16;
	public const uint32 MM_CHROMATIC_M1_MPEGWAVEIN = 17;
	public const uint32 MM_CHROMATIC_M1_MPEGWAVEOUT = 18;
	public const uint32 MM_CHROMATIC_M2 = 19;
	public const uint32 MM_CHROMATIC_M2_WAVEIN = 20;
	public const uint32 MM_CHROMATIC_M2_WAVEOUT = 21;
	public const uint32 MM_CHROMATIC_M2_FMSYNTH = 22;
	public const uint32 MM_CHROMATIC_M2_MIXER = 23;
	public const uint32 MM_CHROMATIC_M2_AUX = 24;
	public const uint32 MM_CHROMATIC_M2_AUX_CD = 25;
	public const uint32 MM_CHROMATIC_M2_MIDIIN = 32;
	public const uint32 MM_CHROMATIC_M2_MIDIOUT = 33;
	public const uint32 MM_CHROMATIC_M2_WTSYNTH = 34;
	public const uint32 MM_CHROMATIC_M2_MPEGWAVEIN = 35;
	public const uint32 MM_CHROMATIC_M2_MPEGWAVEOUT = 36;
	public const uint32 MM_VIENNASYS_TSP_WAVE_DRIVER = 1;
	public const uint32 MM_CONNECTIX_VIDEC_CODEC = 1;
	public const uint32 MM_GADGETLABS_WAVE44_WAVEIN = 1;
	public const uint32 MM_GADGETLABS_WAVE44_WAVEOUT = 2;
	public const uint32 MM_GADGETLABS_WAVE42_WAVEIN = 3;
	public const uint32 MM_GADGETLABS_WAVE42_WAVEOUT = 4;
	public const uint32 MM_GADGETLABS_WAVE4_MIDIIN = 5;
	public const uint32 MM_GADGETLABS_WAVE4_MIDIOUT = 6;
	public const uint32 MM_FRONTIER_WAVECENTER_MIDIIN = 1;
	public const uint32 MM_FRONTIER_WAVECENTER_MIDIOUT = 2;
	public const uint32 MM_FRONTIER_WAVECENTER_WAVEIN = 3;
	public const uint32 MM_FRONTIER_WAVECENTER_WAVEOUT = 4;
	public const uint32 MM_VIONA_QVINPCI_MIXER = 1;
	public const uint32 MM_VIONA_QVINPCI_WAVEIN = 2;
	public const uint32 MM_VIONAQVINPCI_WAVEOUT = 3;
	public const uint32 MM_VIONA_BUSTER_MIXER = 4;
	public const uint32 MM_VIONA_CINEMASTER_MIXER = 5;
	public const uint32 MM_VIONA_CONCERTO_MIXER = 6;
	public const uint32 MM_CASIO_WP150_MIDIOUT = 1;
	public const uint32 MM_CASIO_WP150_MIDIIN = 2;
	public const uint32 MM_CASIO_LSG_MIDIOUT = 3;
	public const uint32 MM_DIMD_PLATFORM = 0;
	public const uint32 MM_DIMD_DIRSOUND = 1;
	public const uint32 MM_DIMD_VIRTMPU = 2;
	public const uint32 MM_DIMD_VIRTSB = 3;
	public const uint32 MM_DIMD_VIRTJOY = 4;
	public const uint32 MM_DIMD_WAVEIN = 5;
	public const uint32 MM_DIMD_WAVEOUT = 6;
	public const uint32 MM_DIMD_MIDIIN = 7;
	public const uint32 MM_DIMD_MIDIOUT = 8;
	public const uint32 MM_DIMD_AUX_LINE = 9;
	public const uint32 MM_DIMD_MIXER = 10;
	public const uint32 MM_DIMD_WSS_WAVEIN = 14;
	public const uint32 MM_DIMD_WSS_WAVEOUT = 15;
	public const uint32 MM_DIMD_WSS_MIXER = 17;
	public const uint32 MM_DIMD_WSS_AUX = 21;
	public const uint32 MM_DIMD_WSS_SYNTH = 76;
	public const uint32 MM_S3_WAVEOUT = 1;
	public const uint32 MM_S3_WAVEIN = 2;
	public const uint32 MM_S3_MIDIOUT = 3;
	public const uint32 MM_S3_MIDIIN = 4;
	public const uint32 MM_S3_FMSYNTH = 5;
	public const uint32 MM_S3_MIXER = 6;
	public const uint32 MM_S3_AUX = 7;
	public const uint32 MM_VKC_MPU401_MIDIIN = 256;
	public const uint32 MM_VKC_SERIAL_MIDIIN = 257;
	public const uint32 MM_VKC_MPU401_MIDIOUT = 512;
	public const uint32 MM_VKC_SERIAL_MIDIOUT = 513;
	public const uint32 MM_ZEFIRO_ZA2 = 2;
	public const uint32 MM_FHGIIS_MPEGLAYER3_DECODE = 9;
	public const uint32 MM_FHGIIS_MPEGLAYER3 = 10;
	public const uint32 MM_FHGIIS_MPEGLAYER3_LITE = 10;
	public const uint32 MM_FHGIIS_MPEGLAYER3_BASIC = 11;
	public const uint32 MM_FHGIIS_MPEGLAYER3_ADVANCED = 12;
	public const uint32 MM_FHGIIS_MPEGLAYER3_PROFESSIONAL = 13;
	public const uint32 MM_FHGIIS_MPEGLAYER3_ADVANCEDPLUS = 14;
	public const uint32 MM_QUICKNET_PJWAVEIN = 1;
	public const uint32 MM_QUICKNET_PJWAVEOUT = 2;
	public const uint32 MM_SICRESOURCE_SSO3D = 2;
	public const uint32 MM_SICRESOURCE_SSOW3DI = 3;
	public const uint32 MM_NEOMAGIC_SYNTH = 1;
	public const uint32 MM_NEOMAGIC_WAVEOUT = 2;
	public const uint32 MM_NEOMAGIC_WAVEIN = 3;
	public const uint32 MM_NEOMAGIC_MIDIOUT = 4;
	public const uint32 MM_NEOMAGIC_MIDIIN = 5;
	public const uint32 MM_NEOMAGIC_AUX = 6;
	public const uint32 MM_NEOMAGIC_MW3DX_WAVEOUT = 10;
	public const uint32 MM_NEOMAGIC_MW3DX_WAVEIN = 11;
	public const uint32 MM_NEOMAGIC_MW3DX_MIDIOUT = 12;
	public const uint32 MM_NEOMAGIC_MW3DX_MIDIIN = 13;
	public const uint32 MM_NEOMAGIC_MW3DX_FMSYNTH = 14;
	public const uint32 MM_NEOMAGIC_MW3DX_GMSYNTH = 15;
	public const uint32 MM_NEOMAGIC_MW3DX_MIXER = 16;
	public const uint32 MM_NEOMAGIC_MW3DX_AUX = 17;
	public const uint32 MM_NEOMAGIC_MWAVE_WAVEOUT = 20;
	public const uint32 MM_NEOMAGIC_MWAVE_WAVEIN = 21;
	public const uint32 MM_NEOMAGIC_MWAVE_MIDIOUT = 22;
	public const uint32 MM_NEOMAGIC_MWAVE_MIDIIN = 23;
	public const uint32 MM_NEOMAGIC_MWAVE_MIXER = 24;
	public const uint32 MM_NEOMAGIC_MWAVE_AUX = 25;
	public const uint32 MM_MERGING_MPEGL3 = 1;
	public const uint32 MM_XIRLINK_VISIONLINK = 1;
	public const uint32 MM_OTI_611WAVEIN = 5;
	public const uint32 MM_OTI_611WAVEOUT = 6;
	public const uint32 MM_OTI_611MIXER = 7;
	public const uint32 MM_OTI_611MIDIN = 18;
	public const uint32 MM_OTI_611MIDIOUT = 19;
	public const uint32 MM_AUREAL_AU8820 = 16;
	public const uint32 MM_AU8820_SYNTH = 17;
	public const uint32 MM_AU8820_WAVEOUT = 18;
	public const uint32 MM_AU8820_WAVEIN = 19;
	public const uint32 MM_AU8820_MIXER = 20;
	public const uint32 MM_AU8820_AUX = 21;
	public const uint32 MM_AU8820_MIDIOUT = 22;
	public const uint32 MM_AU8820_MIDIIN = 23;
	public const uint32 MM_AUREAL_AU8830 = 32;
	public const uint32 MM_AU8830_SYNTH = 33;
	public const uint32 MM_AU8830_WAVEOUT = 34;
	public const uint32 MM_AU8830_WAVEIN = 35;
	public const uint32 MM_AU8830_MIXER = 36;
	public const uint32 MM_AU8830_AUX = 37;
	public const uint32 MM_AU8830_MIDIOUT = 38;
	public const uint32 MM_AU8830_MIDIIN = 39;
	public const uint32 MM_VIVO_AUDIO_CODEC = 1;
	public const uint32 MM_SHARP_MDC_MIDI_SYNTH = 1;
	public const uint32 MM_SHARP_MDC_MIDI_IN = 2;
	public const uint32 MM_SHARP_MDC_MIDI_OUT = 3;
	public const uint32 MM_SHARP_MDC_WAVE_IN = 4;
	public const uint32 MM_SHARP_MDC_WAVE_OUT = 5;
	public const uint32 MM_SHARP_MDC_AUX = 6;
	public const uint32 MM_SHARP_MDC_MIXER = 10;
	public const uint32 MM_SHARP_MDC_AUX_MASTER = 100;
	public const uint32 MM_SHARP_MDC_AUX_BASS = 101;
	public const uint32 MM_SHARP_MDC_AUX_TREBLE = 102;
	public const uint32 MM_SHARP_MDC_AUX_MIDI_VOL = 103;
	public const uint32 MM_SHARP_MDC_AUX_WAVE_VOL = 104;
	public const uint32 MM_SHARP_MDC_AUX_WAVE_RVB = 105;
	public const uint32 MM_SHARP_MDC_AUX_WAVE_CHR = 106;
	public const uint32 MM_SHARP_MDC_AUX_VOL = 107;
	public const uint32 MM_SHARP_MDC_AUX_RVB = 108;
	public const uint32 MM_SHARP_MDC_AUX_CHR = 109;
	public const uint32 MM_LUCENT_ACM_G723 = 0;
	public const uint32 MM_ATT_G729A = 1;
	public const uint32 MM_MARIAN_ARC44WAVEIN = 1;
	public const uint32 MM_MARIAN_ARC44WAVEOUT = 2;
	public const uint32 MM_MARIAN_PRODIF24WAVEIN = 3;
	public const uint32 MM_MARIAN_PRODIF24WAVEOUT = 4;
	public const uint32 MM_MARIAN_ARC88WAVEIN = 5;
	public const uint32 MM_MARIAN_ARC88WAVEOUT = 6;
	public const uint32 MM_BCB_NETBOARD_10 = 1;
	public const uint32 MM_BCB_TT75_10 = 2;
	public const uint32 MM_MOTIONPIXELS_MVI2 = 1;
	public const uint32 MM_QDESIGN_ACM_MPEG = 1;
	public const uint32 MM_QDESIGN_ACM_QDESIGN_MUSIC = 2;
	public const uint32 MM_NMP_CCP_WAVEIN = 1;
	public const uint32 MM_NMP_CCP_WAVEOUT = 2;
	public const uint32 MM_NMP_ACM_AMR = 10;
	public const uint32 MM_DF_ACM_G726 = 1;
	public const uint32 MM_DF_ACM_GSM610 = 2;
	public const uint32 MM_BERCOS_WAVEIN = 1;
	public const uint32 MM_BERCOS_MIXER = 2;
	public const uint32 MM_BERCOS_WAVEOUT = 3;
	public const uint32 MM_ONLIVE_MPCODEC = 1;
	public const uint32 MM_PHONET_PP_WAVEOUT = 1;
	public const uint32 MM_PHONET_PP_WAVEIN = 2;
	public const uint32 MM_PHONET_PP_MIXER = 3;
	public const uint32 MM_FTR_ENCODER_WAVEIN = 1;
	public const uint32 MM_FTR_ACM = 2;
	public const uint32 MM_ENET_T2000_LINEIN = 1;
	public const uint32 MM_ENET_T2000_LINEOUT = 2;
	public const uint32 MM_ENET_T2000_HANDSETIN = 3;
	public const uint32 MM_ENET_T2000_HANDSETOUT = 4;
	public const uint32 MM_EMAGIC_UNITOR8 = 1;
	public const uint32 MM_SIPROLAB_ACELPNET = 1;
	public const uint32 MM_DICTAPHONE_G726 = 1;
	public const uint32 MM_RZS_ACM_TUBGSM = 1;
	public const uint32 MM_EES_PCMIDI14 = 1;
	public const uint32 MM_EES_PCMIDI14_IN = 2;
	public const uint32 MM_EES_PCMIDI14_OUT1 = 3;
	public const uint32 MM_EES_PCMIDI14_OUT2 = 4;
	public const uint32 MM_EES_PCMIDI14_OUT3 = 5;
	public const uint32 MM_EES_PCMIDI14_OUT4 = 6;
	public const uint32 MM_HAFTMANN_LPTDAC2 = 1;
	public const uint32 MM_LUCID_PCI24WAVEIN = 1;
	public const uint32 MM_LUCID_PCI24WAVEOUT = 2;
	public const uint32 MM_HEADSPACE_HAESYNTH = 1;
	public const uint32 MM_HEADSPACE_HAEWAVEOUT = 2;
	public const uint32 MM_HEADSPACE_HAEWAVEIN = 3;
	public const uint32 MM_HEADSPACE_HAEMIXER = 4;
	public const uint32 MM_UNISYS_ACM_NAP = 1;
	public const uint32 MM_LUMINOSITI_SCWAVEIN = 1;
	public const uint32 MM_LUMINOSITI_SCWAVEOUT = 2;
	public const uint32 MM_LUMINOSITI_SCWAVEMIX = 3;
	public const uint32 MM_ACTIVEVOICE_ACM_VOXADPCM = 1;
	public const uint32 MM_DTS_DS = 1;
	public const uint32 MM_SOFTLAB_NSK_FRW_WAVEIN = 1;
	public const uint32 MM_SOFTLAB_NSK_FRW_WAVEOUT = 2;
	public const uint32 MM_SOFTLAB_NSK_FRW_MIXER = 3;
	public const uint32 MM_SOFTLAB_NSK_FRW_AUX = 4;
	public const uint32 MM_FORTEMEDIA_WAVEIN = 1;
	public const uint32 MM_FORTEMEDIA_WAVEOUT = 2;
	public const uint32 MM_FORTEMEDIA_FMSYNC = 3;
	public const uint32 MM_FORTEMEDIA_MIXER = 4;
	public const uint32 MM_FORTEMEDIA_AUX = 5;
	public const uint32 MM_SONORUS_STUDIO = 1;
	public const uint32 MM_I_LINK_VOICE_CODER = 1;
	public const uint32 MM_SELSIUS_SYSTEMS_RTPWAVEOUT = 1;
	public const uint32 MM_SELSIUS_SYSTEMS_RTPWAVEIN = 2;
	public const uint32 MM_ADMOS_FM_SYNTH = 1;
	public const uint32 MM_ADMOS_QS3AMIDIOUT = 2;
	public const uint32 MM_ADMOS_QS3AMIDIIN = 3;
	public const uint32 MM_ADMOS_QS3AWAVEOUT = 4;
	public const uint32 MM_ADMOS_QS3AWAVEIN = 5;
	public const uint32 MM_LEXICON_STUDIO_WAVE_OUT = 1;
	public const uint32 MM_LEXICON_STUDIO_WAVE_IN = 2;
	public const uint32 MM_SGI_320_WAVEIN = 1;
	public const uint32 MM_SGI_320_WAVEOUT = 2;
	public const uint32 MM_SGI_320_MIXER = 3;
	public const uint32 MM_SGI_540_WAVEIN = 4;
	public const uint32 MM_SGI_540_WAVEOUT = 5;
	public const uint32 MM_SGI_540_MIXER = 6;
	public const uint32 MM_SGI_RAD_ADATMONO1_WAVEIN = 7;
	public const uint32 MM_SGI_RAD_ADATMONO2_WAVEIN = 8;
	public const uint32 MM_SGI_RAD_ADATMONO3_WAVEIN = 9;
	public const uint32 MM_SGI_RAD_ADATMONO4_WAVEIN = 10;
	public const uint32 MM_SGI_RAD_ADATMONO5_WAVEIN = 11;
	public const uint32 MM_SGI_RAD_ADATMONO6_WAVEIN = 12;
	public const uint32 MM_SGI_RAD_ADATMONO7_WAVEIN = 13;
	public const uint32 MM_SGI_RAD_ADATMONO8_WAVEIN = 14;
	public const uint32 MM_SGI_RAD_ADATSTEREO12_WAVEIN = 15;
	public const uint32 MM_SGI_RAD_ADATSTEREO34_WAVEIN = 16;
	public const uint32 MM_SGI_RAD_ADATSTEREO56_WAVEIN = 17;
	public const uint32 MM_SGI_RAD_ADATSTEREO78_WAVEIN = 18;
	public const uint32 MM_SGI_RAD_ADAT8CHAN_WAVEIN = 19;
	public const uint32 MM_SGI_RAD_ADATMONO1_WAVEOUT = 20;
	public const uint32 MM_SGI_RAD_ADATMONO2_WAVEOUT = 21;
	public const uint32 MM_SGI_RAD_ADATMONO3_WAVEOUT = 22;
	public const uint32 MM_SGI_RAD_ADATMONO4_WAVEOUT = 23;
	public const uint32 MM_SGI_RAD_ADATMONO5_WAVEOUT = 24;
	public const uint32 MM_SGI_RAD_ADATMONO6_WAVEOUT = 25;
	public const uint32 MM_SGI_RAD_ADATMONO7_WAVEOUT = 26;
	public const uint32 MM_SGI_RAD_ADATMONO8_WAVEOUT = 27;
	public const uint32 MM_SGI_RAD_ADATSTEREO12_WAVEOUT = 28;
	public const uint32 MM_SGI_RAD_ADATSTEREO32_WAVEOUT = 29;
	public const uint32 MM_SGI_RAD_ADATSTEREO56_WAVEOUT = 30;
	public const uint32 MM_SGI_RAD_ADATSTEREO78_WAVEOUT = 31;
	public const uint32 MM_SGI_RAD_ADAT8CHAN_WAVEOUT = 32;
	public const uint32 MM_SGI_RAD_AESMONO1_WAVEIN = 33;
	public const uint32 MM_SGI_RAD_AESMONO2_WAVEIN = 34;
	public const uint32 MM_SGI_RAD_AESSTEREO_WAVEIN = 35;
	public const uint32 MM_SGI_RAD_AESMONO1_WAVEOUT = 36;
	public const uint32 MM_SGI_RAD_AESMONO2_WAVEOUT = 37;
	public const uint32 MM_SGI_RAD_AESSTEREO_WAVEOUT = 38;
	public const uint32 MM_IPI_ACM_HSX = 1;
	public const uint32 MM_IPI_ACM_RPELP = 2;
	public const uint32 MM_IPI_WF_ASSS = 3;
	public const uint32 MM_IPI_AT_WAVEOUT = 4;
	public const uint32 MM_IPI_AT_WAVEIN = 5;
	public const uint32 MM_IPI_AT_MIXER = 6;
	public const uint32 MM_ICE_WAVEOUT = 1;
	public const uint32 MM_ICE_WAVEIN = 2;
	public const uint32 MM_ICE_MTWAVEOUT = 3;
	public const uint32 MM_ICE_MTWAVEIN = 4;
	public const uint32 MM_ICE_MIDIOUT1 = 5;
	public const uint32 MM_ICE_MIDIIN1 = 6;
	public const uint32 MM_ICE_MIDIOUT2 = 7;
	public const uint32 MM_ICE_MIDIIN2 = 8;
	public const uint32 MM_ICE_SYNTH = 9;
	public const uint32 MM_ICE_MIXER = 10;
	public const uint32 MM_ICE_AUX = 11;
	public const uint32 MM_VQST_VQC1 = 1;
	public const uint32 MM_VQST_VQC2 = 2;
	public const uint32 MM_ETEK_KWIKMIDI_MIDIIN = 1;
	public const uint32 MM_ETEK_KWIKMIDI_MIDIOUT = 2;
	public const uint32 MM_INTERNET_SSW_MIDIOUT = 10;
	public const uint32 MM_INTERNET_SSW_MIDIIN = 11;
	public const uint32 MM_INTERNET_SSW_WAVEOUT = 12;
	public const uint32 MM_INTERNET_SSW_WAVEIN = 13;
	public const uint32 MM_SONY_ACM_SCX = 1;
	public const uint32 MM_UH_ACM_ADPCM = 1;
	public const uint32 MM_SYDEC_NV_WAVEIN = 1;
	public const uint32 MM_SYDEC_NV_WAVEOUT = 2;
	public const uint32 MM_FLEXION_X300_WAVEIN = 1;
	public const uint32 MM_FLEXION_X300_WAVEOUT = 2;
	public const uint32 MM_VIA_WAVEOUT = 1;
	public const uint32 MM_VIA_WAVEIN = 2;
	public const uint32 MM_VIA_MIXER = 3;
	public const uint32 MM_VIA_AUX = 4;
	public const uint32 MM_VIA_MPU401_MIDIOUT = 5;
	public const uint32 MM_VIA_MPU401_MIDIIN = 6;
	public const uint32 MM_VIA_SWFM_SYNTH = 7;
	public const uint32 MM_VIA_WDM_WAVEOUT = 8;
	public const uint32 MM_VIA_WDM_WAVEIN = 9;
	public const uint32 MM_VIA_WDM_MIXER = 10;
	public const uint32 MM_VIA_WDM_MPU401_MIDIOUT = 11;
	public const uint32 MM_VIA_WDM_MPU401_MIDIIN = 12;
	public const uint32 MM_MICRONAS_SC4 = 1;
	public const uint32 MM_MICRONAS_CLP833 = 2;
	public const uint32 MM_HP_WAVEOUT = 1;
	public const uint32 MM_HP_WAVEIN = 2;
	public const uint32 MM_QUICKAUDIO_MINIMIDI = 1;
	public const uint32 MM_QUICKAUDIO_MAXIMIDI = 2;
	public const uint32 MM_ICCC_UNA3_WAVEIN = 1;
	public const uint32 MM_ICCC_UNA3_WAVEOUT = 2;
	public const uint32 MM_ICCC_UNA3_AUX = 3;
	public const uint32 MM_ICCC_UNA3_MIXER = 4;
	public const uint32 MM_3COM_CB_MIXER = 1;
	public const uint32 MM_3COM_CB_WAVEIN = 2;
	public const uint32 MM_3COM_CB_WAVEOUT = 3;
	public const uint32 MM_MINDMAKER_GC_WAVEIN = 1;
	public const uint32 MM_MINDMAKER_GC_WAVEOUT = 2;
	public const uint32 MM_MINDMAKER_GC_MIXER = 3;
	public const uint32 MM_TELEKOL_WAVEOUT = 1;
	public const uint32 MM_TELEKOL_WAVEIN = 2;
	public const uint32 MM_ALGOVISION_VB80WAVEOUT = 1;
	public const uint32 MM_ALGOVISION_VB80WAVEIN = 2;
	public const uint32 MM_ALGOVISION_VB80MIXER = 3;
	public const uint32 MM_ALGOVISION_VB80AUX = 4;
	public const uint32 MM_ALGOVISION_VB80AUX2 = 5;
	public const uint32 WAVE_FORMAT_UNKNOWN = 0;
	public const uint32 WAVE_FORMAT_ADPCM = 2;
	public const uint32 WAVE_FORMAT_IEEE_FLOAT = 3;
	public const uint32 WAVE_FORMAT_VSELP = 4;
	public const uint32 WAVE_FORMAT_IBM_CVSD = 5;
	public const uint32 WAVE_FORMAT_ALAW = 6;
	public const uint32 WAVE_FORMAT_MULAW = 7;
	public const uint32 WAVE_FORMAT_DTS = 8;
	public const uint32 WAVE_FORMAT_DRM = 9;
	public const uint32 WAVE_FORMAT_WMAVOICE9 = 10;
	public const uint32 WAVE_FORMAT_WMAVOICE10 = 11;
	public const uint32 WAVE_FORMAT_OKI_ADPCM = 16;
	public const uint32 WAVE_FORMAT_DVI_ADPCM = 17;
	public const uint32 WAVE_FORMAT_IMA_ADPCM = 17;
	public const uint32 WAVE_FORMAT_MEDIASPACE_ADPCM = 18;
	public const uint32 WAVE_FORMAT_SIERRA_ADPCM = 19;
	public const uint32 WAVE_FORMAT_G723_ADPCM = 20;
	public const uint32 WAVE_FORMAT_DIGISTD = 21;
	public const uint32 WAVE_FORMAT_DIGIFIX = 22;
	public const uint32 WAVE_FORMAT_DIALOGIC_OKI_ADPCM = 23;
	public const uint32 WAVE_FORMAT_MEDIAVISION_ADPCM = 24;
	public const uint32 WAVE_FORMAT_CU_CODEC = 25;
	public const uint32 WAVE_FORMAT_HP_DYN_VOICE = 26;
	public const uint32 WAVE_FORMAT_YAMAHA_ADPCM = 32;
	public const uint32 WAVE_FORMAT_SONARC = 33;
	public const uint32 WAVE_FORMAT_DSPGROUP_TRUESPEECH = 34;
	public const uint32 WAVE_FORMAT_ECHOSC1 = 35;
	public const uint32 WAVE_FORMAT_AUDIOFILE_AF36 = 36;
	public const uint32 WAVE_FORMAT_APTX = 37;
	public const uint32 WAVE_FORMAT_AUDIOFILE_AF10 = 38;
	public const uint32 WAVE_FORMAT_PROSODY_1612 = 39;
	public const uint32 WAVE_FORMAT_LRC = 40;
	public const uint32 WAVE_FORMAT_DOLBY_AC2 = 48;
	public const uint32 WAVE_FORMAT_GSM610 = 49;
	public const uint32 WAVE_FORMAT_MSNAUDIO = 50;
	public const uint32 WAVE_FORMAT_ANTEX_ADPCME = 51;
	public const uint32 WAVE_FORMAT_CONTROL_RES_VQLPC = 52;
	public const uint32 WAVE_FORMAT_DIGIREAL = 53;
	public const uint32 WAVE_FORMAT_DIGIADPCM = 54;
	public const uint32 WAVE_FORMAT_CONTROL_RES_CR10 = 55;
	public const uint32 WAVE_FORMAT_NMS_VBXADPCM = 56;
	public const uint32 WAVE_FORMAT_CS_IMAADPCM = 57;
	public const uint32 WAVE_FORMAT_ECHOSC3 = 58;
	public const uint32 WAVE_FORMAT_ROCKWELL_ADPCM = 59;
	public const uint32 WAVE_FORMAT_ROCKWELL_DIGITALK = 60;
	public const uint32 WAVE_FORMAT_XEBEC = 61;
	public const uint32 WAVE_FORMAT_G721_ADPCM = 64;
	public const uint32 WAVE_FORMAT_G728_CELP = 65;
	public const uint32 WAVE_FORMAT_MSG723 = 66;
	public const uint32 WAVE_FORMAT_INTEL_G723_1 = 67;
	public const uint32 WAVE_FORMAT_INTEL_G729 = 68;
	public const uint32 WAVE_FORMAT_SHARP_G726 = 69;
	public const uint32 WAVE_FORMAT_MPEG = 80;
	public const uint32 WAVE_FORMAT_RT24 = 82;
	public const uint32 WAVE_FORMAT_PAC = 83;
	public const uint32 WAVE_FORMAT_MPEGLAYER3 = 85;
	public const uint32 WAVE_FORMAT_LUCENT_G723 = 89;
	public const uint32 WAVE_FORMAT_CIRRUS = 96;
	public const uint32 WAVE_FORMAT_ESPCM = 97;
	public const uint32 WAVE_FORMAT_VOXWARE = 98;
	public const uint32 WAVE_FORMAT_CANOPUS_ATRAC = 99;
	public const uint32 WAVE_FORMAT_G726_ADPCM = 100;
	public const uint32 WAVE_FORMAT_G722_ADPCM = 101;
	public const uint32 WAVE_FORMAT_DSAT = 102;
	public const uint32 WAVE_FORMAT_DSAT_DISPLAY = 103;
	public const uint32 WAVE_FORMAT_VOXWARE_BYTE_ALIGNED = 105;
	public const uint32 WAVE_FORMAT_VOXWARE_AC8 = 112;
	public const uint32 WAVE_FORMAT_VOXWARE_AC10 = 113;
	public const uint32 WAVE_FORMAT_VOXWARE_AC16 = 114;
	public const uint32 WAVE_FORMAT_VOXWARE_AC20 = 115;
	public const uint32 WAVE_FORMAT_VOXWARE_RT24 = 116;
	public const uint32 WAVE_FORMAT_VOXWARE_RT29 = 117;
	public const uint32 WAVE_FORMAT_VOXWARE_RT29HW = 118;
	public const uint32 WAVE_FORMAT_VOXWARE_VR12 = 119;
	public const uint32 WAVE_FORMAT_VOXWARE_VR18 = 120;
	public const uint32 WAVE_FORMAT_VOXWARE_TQ40 = 121;
	public const uint32 WAVE_FORMAT_VOXWARE_SC3 = 122;
	public const uint32 WAVE_FORMAT_VOXWARE_SC3_1 = 123;
	public const uint32 WAVE_FORMAT_SOFTSOUND = 128;
	public const uint32 WAVE_FORMAT_VOXWARE_TQ60 = 129;
	public const uint32 WAVE_FORMAT_MSRT24 = 130;
	public const uint32 WAVE_FORMAT_G729A = 131;
	public const uint32 WAVE_FORMAT_MVI_MVI2 = 132;
	public const uint32 WAVE_FORMAT_DF_G726 = 133;
	public const uint32 WAVE_FORMAT_DF_GSM610 = 134;
	public const uint32 WAVE_FORMAT_ISIAUDIO = 136;
	public const uint32 WAVE_FORMAT_ONLIVE = 137;
	public const uint32 WAVE_FORMAT_MULTITUDE_FT_SX20 = 138;
	public const uint32 WAVE_FORMAT_INFOCOM_ITS_G721_ADPCM = 139;
	public const uint32 WAVE_FORMAT_CONVEDIA_G729 = 140;
	public const uint32 WAVE_FORMAT_CONGRUENCY = 141;
	public const uint32 WAVE_FORMAT_SBC24 = 145;
	public const uint32 WAVE_FORMAT_DOLBY_AC3_SPDIF = 146;
	public const uint32 WAVE_FORMAT_MEDIASONIC_G723 = 147;
	public const uint32 WAVE_FORMAT_PROSODY_8KBPS = 148;
	public const uint32 WAVE_FORMAT_ZYXEL_ADPCM = 151;
	public const uint32 WAVE_FORMAT_PHILIPS_LPCBB = 152;
	public const uint32 WAVE_FORMAT_PACKED = 153;
	public const uint32 WAVE_FORMAT_MALDEN_PHONYTALK = 160;
	public const uint32 WAVE_FORMAT_RACAL_RECORDER_GSM = 161;
	public const uint32 WAVE_FORMAT_RACAL_RECORDER_G720_A = 162;
	public const uint32 WAVE_FORMAT_RACAL_RECORDER_G723_1 = 163;
	public const uint32 WAVE_FORMAT_RACAL_RECORDER_TETRA_ACELP = 164;
	public const uint32 WAVE_FORMAT_NEC_AAC = 176;
	public const uint32 WAVE_FORMAT_RAW_AAC1 = 255;
	public const uint32 WAVE_FORMAT_RHETOREX_ADPCM = 256;
	public const uint32 WAVE_FORMAT_IRAT = 257;
	public const uint32 WAVE_FORMAT_VIVO_G723 = 273;
	public const uint32 WAVE_FORMAT_VIVO_SIREN = 274;
	public const uint32 WAVE_FORMAT_PHILIPS_CELP = 288;
	public const uint32 WAVE_FORMAT_PHILIPS_GRUNDIG = 289;
	public const uint32 WAVE_FORMAT_DIGITAL_G723 = 291;
	public const uint32 WAVE_FORMAT_SANYO_LD_ADPCM = 293;
	public const uint32 WAVE_FORMAT_SIPROLAB_ACEPLNET = 304;
	public const uint32 WAVE_FORMAT_SIPROLAB_ACELP4800 = 305;
	public const uint32 WAVE_FORMAT_SIPROLAB_ACELP8V3 = 306;
	public const uint32 WAVE_FORMAT_SIPROLAB_G729 = 307;
	public const uint32 WAVE_FORMAT_SIPROLAB_G729A = 308;
	public const uint32 WAVE_FORMAT_SIPROLAB_KELVIN = 309;
	public const uint32 WAVE_FORMAT_VOICEAGE_AMR = 310;
	public const uint32 WAVE_FORMAT_G726ADPCM = 320;
	public const uint32 WAVE_FORMAT_DICTAPHONE_CELP68 = 321;
	public const uint32 WAVE_FORMAT_DICTAPHONE_CELP54 = 322;
	public const uint32 WAVE_FORMAT_QUALCOMM_PUREVOICE = 336;
	public const uint32 WAVE_FORMAT_QUALCOMM_HALFRATE = 337;
	public const uint32 WAVE_FORMAT_TUBGSM = 341;
	public const uint32 WAVE_FORMAT_MSAUDIO1 = 352;
	public const uint32 WAVE_FORMAT_WMAUDIO2 = 353;
	public const uint32 WAVE_FORMAT_WMAUDIO3 = 354;
	public const uint32 WAVE_FORMAT_WMAUDIO_LOSSLESS = 355;
	public const uint32 WAVE_FORMAT_WMASPDIF = 356;
	public const uint32 WAVE_FORMAT_UNISYS_NAP_ADPCM = 368;
	public const uint32 WAVE_FORMAT_UNISYS_NAP_ULAW = 369;
	public const uint32 WAVE_FORMAT_UNISYS_NAP_ALAW = 370;
	public const uint32 WAVE_FORMAT_UNISYS_NAP_16K = 371;
	public const uint32 WAVE_FORMAT_SYCOM_ACM_SYC008 = 372;
	public const uint32 WAVE_FORMAT_SYCOM_ACM_SYC701_G726L = 373;
	public const uint32 WAVE_FORMAT_SYCOM_ACM_SYC701_CELP54 = 374;
	public const uint32 WAVE_FORMAT_SYCOM_ACM_SYC701_CELP68 = 375;
	public const uint32 WAVE_FORMAT_KNOWLEDGE_ADVENTURE_ADPCM = 376;
	public const uint32 WAVE_FORMAT_FRAUNHOFER_IIS_MPEG2_AAC = 384;
	public const uint32 WAVE_FORMAT_DTS_DS = 400;
	public const uint32 WAVE_FORMAT_CREATIVE_ADPCM = 512;
	public const uint32 WAVE_FORMAT_CREATIVE_FASTSPEECH8 = 514;
	public const uint32 WAVE_FORMAT_CREATIVE_FASTSPEECH10 = 515;
	public const uint32 WAVE_FORMAT_UHER_ADPCM = 528;
	public const uint32 WAVE_FORMAT_ULEAD_DV_AUDIO = 533;
	public const uint32 WAVE_FORMAT_ULEAD_DV_AUDIO_1 = 534;
	public const uint32 WAVE_FORMAT_QUARTERDECK = 544;
	public const uint32 WAVE_FORMAT_ILINK_VC = 560;
	public const uint32 WAVE_FORMAT_RAW_SPORT = 576;
	public const uint32 WAVE_FORMAT_ESST_AC3 = 577;
	public const uint32 WAVE_FORMAT_GENERIC_PASSTHRU = 585;
	public const uint32 WAVE_FORMAT_IPI_HSX = 592;
	public const uint32 WAVE_FORMAT_IPI_RPELP = 593;
	public const uint32 WAVE_FORMAT_CS2 = 608;
	public const uint32 WAVE_FORMAT_SONY_SCX = 624;
	public const uint32 WAVE_FORMAT_SONY_SCY = 625;
	public const uint32 WAVE_FORMAT_SONY_ATRAC3 = 626;
	public const uint32 WAVE_FORMAT_SONY_SPC = 627;
	public const uint32 WAVE_FORMAT_TELUM_AUDIO = 640;
	public const uint32 WAVE_FORMAT_TELUM_IA_AUDIO = 641;
	public const uint32 WAVE_FORMAT_NORCOM_VOICE_SYSTEMS_ADPCM = 645;
	public const uint32 WAVE_FORMAT_FM_TOWNS_SND = 768;
	public const uint32 WAVE_FORMAT_MICRONAS = 848;
	public const uint32 WAVE_FORMAT_MICRONAS_CELP833 = 849;
	public const uint32 WAVE_FORMAT_BTV_DIGITAL = 1024;
	public const uint32 WAVE_FORMAT_INTEL_MUSIC_CODER = 1025;
	public const uint32 WAVE_FORMAT_INDEO_AUDIO = 1026;
	public const uint32 WAVE_FORMAT_QDESIGN_MUSIC = 1104;
	public const uint32 WAVE_FORMAT_ON2_VP7_AUDIO = 1280;
	public const uint32 WAVE_FORMAT_ON2_VP6_AUDIO = 1281;
	public const uint32 WAVE_FORMAT_VME_VMPCM = 1664;
	public const uint32 WAVE_FORMAT_TPC = 1665;
	public const uint32 WAVE_FORMAT_LIGHTWAVE_LOSSLESS = 2222;
	public const uint32 WAVE_FORMAT_OLIGSM = 4096;
	public const uint32 WAVE_FORMAT_OLIADPCM = 4097;
	public const uint32 WAVE_FORMAT_OLICELP = 4098;
	public const uint32 WAVE_FORMAT_OLISBC = 4099;
	public const uint32 WAVE_FORMAT_OLIOPR = 4100;
	public const uint32 WAVE_FORMAT_LH_CODEC = 4352;
	public const uint32 WAVE_FORMAT_LH_CODEC_CELP = 4353;
	public const uint32 WAVE_FORMAT_LH_CODEC_SBC8 = 4354;
	public const uint32 WAVE_FORMAT_LH_CODEC_SBC12 = 4355;
	public const uint32 WAVE_FORMAT_LH_CODEC_SBC16 = 4356;
	public const uint32 WAVE_FORMAT_NORRIS = 5120;
	public const uint32 WAVE_FORMAT_ISIAUDIO_2 = 5121;
	public const uint32 WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS = 5376;
	public const uint32 WAVE_FORMAT_MPEG_ADTS_AAC = 5632;
	public const uint32 WAVE_FORMAT_MPEG_RAW_AAC = 5633;
	public const uint32 WAVE_FORMAT_MPEG_LOAS = 5634;
	public const uint32 WAVE_FORMAT_NOKIA_MPEG_ADTS_AAC = 5640;
	public const uint32 WAVE_FORMAT_NOKIA_MPEG_RAW_AAC = 5641;
	public const uint32 WAVE_FORMAT_VODAFONE_MPEG_ADTS_AAC = 5642;
	public const uint32 WAVE_FORMAT_VODAFONE_MPEG_RAW_AAC = 5643;
	public const uint32 WAVE_FORMAT_MPEG_HEAAC = 5648;
	public const uint32 WAVE_FORMAT_VOXWARE_RT24_SPEECH = 6172;
	public const uint32 WAVE_FORMAT_SONICFOUNDRY_LOSSLESS = 6513;
	public const uint32 WAVE_FORMAT_INNINGS_TELECOM_ADPCM = 6521;
	public const uint32 WAVE_FORMAT_LUCENT_SX8300P = 7175;
	public const uint32 WAVE_FORMAT_LUCENT_SX5363S = 7180;
	public const uint32 WAVE_FORMAT_CUSEEME = 7939;
	public const uint32 WAVE_FORMAT_NTCSOFT_ALF2CM_ACM = 8132;
	public const uint32 WAVE_FORMAT_DVM = 8192;
	public const uint32 WAVE_FORMAT_DTS2 = 8193;
	public const uint32 WAVE_FORMAT_MAKEAVIS = 13075;
	public const uint32 WAVE_FORMAT_DIVIO_MPEG4_AAC = 16707;
	public const uint32 WAVE_FORMAT_NOKIA_ADAPTIVE_MULTIRATE = 16897;
	public const uint32 WAVE_FORMAT_DIVIO_G726 = 16963;
	public const uint32 WAVE_FORMAT_LEAD_SPEECH = 17228;
	public const uint32 WAVE_FORMAT_LEAD_VORBIS = 22092;
	public const uint32 WAVE_FORMAT_WAVPACK_AUDIO = 22358;
	public const uint32 WAVE_FORMAT_ALAC = 27745;
	public const uint32 WAVE_FORMAT_OGG_VORBIS_MODE_1 = 26447;
	public const uint32 WAVE_FORMAT_OGG_VORBIS_MODE_2 = 26448;
	public const uint32 WAVE_FORMAT_OGG_VORBIS_MODE_3 = 26449;
	public const uint32 WAVE_FORMAT_OGG_VORBIS_MODE_1_PLUS = 26479;
	public const uint32 WAVE_FORMAT_OGG_VORBIS_MODE_2_PLUS = 26480;
	public const uint32 WAVE_FORMAT_OGG_VORBIS_MODE_3_PLUS = 26481;
	public const uint32 WAVE_FORMAT_3COM_NBX = 28672;
	public const uint32 WAVE_FORMAT_OPUS = 28751;
	public const uint32 WAVE_FORMAT_FAAD_AAC = 28781;
	public const uint32 WAVE_FORMAT_AMR_NB = 29537;
	public const uint32 WAVE_FORMAT_AMR_WB = 29538;
	public const uint32 WAVE_FORMAT_AMR_WP = 29539;
	public const uint32 WAVE_FORMAT_GSM_AMR_CBR = 31265;
	public const uint32 WAVE_FORMAT_GSM_AMR_VBR_SID = 31266;
	public const uint32 WAVE_FORMAT_COMVERSE_INFOSYS_G723_1 = 41216;
	public const uint32 WAVE_FORMAT_COMVERSE_INFOSYS_AVQSBC = 41217;
	public const uint32 WAVE_FORMAT_COMVERSE_INFOSYS_SBC = 41218;
	public const uint32 WAVE_FORMAT_SYMBOL_G729_A = 41219;
	public const uint32 WAVE_FORMAT_VOICEAGE_AMR_WB = 41220;
	public const uint32 WAVE_FORMAT_INGENIENT_G726 = 41221;
	public const uint32 WAVE_FORMAT_MPEG4_AAC = 41222;
	public const uint32 WAVE_FORMAT_ENCORE_G726 = 41223;
	public const uint32 WAVE_FORMAT_ZOLL_ASAO = 41224;
	public const uint32 WAVE_FORMAT_SPEEX_VOICE = 41225;
	public const uint32 WAVE_FORMAT_VIANIX_MASC = 41226;
	public const uint32 WAVE_FORMAT_WM9_SPECTRUM_ANALYZER = 41227;
	public const uint32 WAVE_FORMAT_WMF_SPECTRUM_ANAYZER = 41228;
	public const uint32 WAVE_FORMAT_GSM_610 = 41229;
	public const uint32 WAVE_FORMAT_GSM_620 = 41230;
	public const uint32 WAVE_FORMAT_GSM_660 = 41231;
	public const uint32 WAVE_FORMAT_GSM_690 = 41232;
	public const uint32 WAVE_FORMAT_GSM_ADAPTIVE_MULTIRATE_WB = 41233;
	public const uint32 WAVE_FORMAT_POLYCOM_G722 = 41234;
	public const uint32 WAVE_FORMAT_POLYCOM_G728 = 41235;
	public const uint32 WAVE_FORMAT_POLYCOM_G729_A = 41236;
	public const uint32 WAVE_FORMAT_POLYCOM_SIREN = 41237;
	public const uint32 WAVE_FORMAT_GLOBAL_IP_ILBC = 41238;
	public const uint32 WAVE_FORMAT_RADIOTIME_TIME_SHIFT_RADIO = 41239;
	public const uint32 WAVE_FORMAT_NICE_ACA = 41240;
	public const uint32 WAVE_FORMAT_NICE_ADPCM = 41241;
	public const uint32 WAVE_FORMAT_VOCORD_G721 = 41242;
	public const uint32 WAVE_FORMAT_VOCORD_G726 = 41243;
	public const uint32 WAVE_FORMAT_VOCORD_G722_1 = 41244;
	public const uint32 WAVE_FORMAT_VOCORD_G728 = 41245;
	public const uint32 WAVE_FORMAT_VOCORD_G729 = 41246;
	public const uint32 WAVE_FORMAT_VOCORD_G729_A = 41247;
	public const uint32 WAVE_FORMAT_VOCORD_G723_1 = 41248;
	public const uint32 WAVE_FORMAT_VOCORD_LBC = 41249;
	public const uint32 WAVE_FORMAT_NICE_G728 = 41250;
	public const uint32 WAVE_FORMAT_FRACE_TELECOM_G729 = 41251;
	public const uint32 WAVE_FORMAT_CODIAN = 41252;
	public const uint32 WAVE_FORMAT_DOLBY_AC4 = 44096;
	public const uint32 WAVE_FORMAT_FLAC = 61868;
	public const uint32 WAVE_FORMAT_DEVELOPMENT = 65535;
	public const uint32 ACM_MPEG_LAYER1 = 1;
	public const uint32 ACM_MPEG_LAYER2 = 2;
	public const uint32 ACM_MPEG_LAYER3 = 4;
	public const uint32 ACM_MPEG_STEREO = 1;
	public const uint32 ACM_MPEG_JOINTSTEREO = 2;
	public const uint32 ACM_MPEG_DUALCHANNEL = 4;
	public const uint32 ACM_MPEG_SINGLECHANNEL = 8;
	public const uint32 ACM_MPEG_PRIVATEBIT = 1;
	public const uint32 ACM_MPEG_COPYRIGHT = 2;
	public const uint32 ACM_MPEG_ORIGINALHOME = 4;
	public const uint32 ACM_MPEG_PROTECTIONBIT = 8;
	public const uint32 ACM_MPEG_ID_MPEG1 = 16;
	public const uint32 MPEGLAYER3_WFX_EXTRA_BYTES = 12;
	public const uint32 MPEGLAYER3_ID_UNKNOWN = 0;
	public const uint32 MPEGLAYER3_ID_MPEG = 1;
	public const uint32 MPEGLAYER3_ID_CONSTANTFRAMESIZE = 2;
	public const uint32 MM_MSFT_ACM_WMAUDIO = 39;
	public const uint32 WMAUDIO_BITS_PER_SAMPLE = 16;
	public const uint32 WMAUDIO_MAX_CHANNELS = 2;
	public const uint32 MM_MSFT_ACM_MSAUDIO1 = 39;
	public const uint32 MSAUDIO1_BITS_PER_SAMPLE = 16;
	public const uint32 MSAUDIO1_MAX_CHANNELS = 2;
	public const uint32 MM_MSFT_ACM_WMAUDIO2 = 101;
	public const uint32 WMAUDIO2_BITS_PER_SAMPLE = 16;
	public const uint32 WMAUDIO2_MAX_CHANNELS = 2;
	public const uint32 WAVE_FILTER_UNKNOWN = 0;
	public const uint32 WAVE_FILTER_DEVELOPMENT = 65535;
	public const uint32 WAVE_FILTER_VOLUME = 1;
	public const uint32 WAVE_FILTER_ECHO = 2;
	public const uint32 JPEG_PROCESS_BASELINE = 0;
	public const int32 AVIIF_CONTROLFRAME = 512;
	public const uint32 JIFMK_SOF0 = 65472;
	public const uint32 JIFMK_SOF1 = 65473;
	public const uint32 JIFMK_SOF2 = 65474;
	public const uint32 JIFMK_SOF3 = 65475;
	public const uint32 JIFMK_SOF5 = 65477;
	public const uint32 JIFMK_SOF6 = 65478;
	public const uint32 JIFMK_SOF7 = 65479;
	public const uint32 JIFMK_JPG = 65480;
	public const uint32 JIFMK_SOF9 = 65481;
	public const uint32 JIFMK_SOF10 = 65482;
	public const uint32 JIFMK_SOF11 = 65483;
	public const uint32 JIFMK_SOF13 = 65485;
	public const uint32 JIFMK_SOF14 = 65486;
	public const uint32 JIFMK_SOF15 = 65487;
	public const uint32 JIFMK_DHT = 65476;
	public const uint32 JIFMK_DAC = 65484;
	public const uint32 JIFMK_RST0 = 65488;
	public const uint32 JIFMK_RST1 = 65489;
	public const uint32 JIFMK_RST2 = 65490;
	public const uint32 JIFMK_RST3 = 65491;
	public const uint32 JIFMK_RST4 = 65492;
	public const uint32 JIFMK_RST5 = 65493;
	public const uint32 JIFMK_RST6 = 65494;
	public const uint32 JIFMK_RST7 = 65495;
	public const uint32 JIFMK_SOI = 65496;
	public const uint32 JIFMK_EOI = 65497;
	public const uint32 JIFMK_SOS = 65498;
	public const uint32 JIFMK_DQT = 65499;
	public const uint32 JIFMK_DNL = 65500;
	public const uint32 JIFMK_DRI = 65501;
	public const uint32 JIFMK_DHP = 65502;
	public const uint32 JIFMK_EXP = 65503;
	public const uint32 JIFMK_APP0 = 65504;
	public const uint32 JIFMK_APP1 = 65505;
	public const uint32 JIFMK_APP2 = 65506;
	public const uint32 JIFMK_APP3 = 65507;
	public const uint32 JIFMK_APP4 = 65508;
	public const uint32 JIFMK_APP5 = 65509;
	public const uint32 JIFMK_APP6 = 65510;
	public const uint32 JIFMK_APP7 = 65511;
	public const uint32 JIFMK_JPG0 = 65520;
	public const uint32 JIFMK_JPG1 = 65521;
	public const uint32 JIFMK_JPG2 = 65522;
	public const uint32 JIFMK_JPG3 = 65523;
	public const uint32 JIFMK_JPG4 = 65524;
	public const uint32 JIFMK_JPG5 = 65525;
	public const uint32 JIFMK_JPG6 = 65526;
	public const uint32 JIFMK_JPG7 = 65527;
	public const uint32 JIFMK_JPG8 = 65528;
	public const uint32 JIFMK_JPG9 = 65529;
	public const uint32 JIFMK_JPG10 = 65530;
	public const uint32 JIFMK_JPG11 = 65531;
	public const uint32 JIFMK_JPG12 = 65532;
	public const uint32 JIFMK_JPG13 = 65533;
	public const uint32 JIFMK_COM = 65534;
	public const uint32 JIFMK_TEM = 65281;
	public const uint32 JIFMK_RES = 65282;
	public const uint32 JIFMK_00 = 65280;
	public const uint32 JIFMK_FF = 65535;
	public const uint32 JPEG_Y = 1;
	public const uint32 JPEG_YCbCr = 2;
	public const uint32 JPEG_RGB = 3;
	public const uint32 MIXERCONTROL_CONTROLTYPE_SRS_MTS = 536936454;
	public const uint32 MIXERCONTROL_CONTROLTYPE_SRS_ONOFF = 536936455;
	public const uint32 MIXERCONTROL_CONTROLTYPE_SRS_SYNTHSELECT = 536936456;
	public const uint32 VP_COMMAND_GET = 1;
	public const uint32 VP_COMMAND_SET = 2;
	public const uint32 VP_FLAGS_TV_MODE = 1;
	public const uint32 VP_FLAGS_TV_STANDARD = 2;
	public const uint32 VP_FLAGS_FLICKER = 4;
	public const uint32 VP_FLAGS_OVERSCAN = 8;
	public const uint32 VP_FLAGS_MAX_UNSCALED = 16;
	public const uint32 VP_FLAGS_POSITION = 32;
	public const uint32 VP_FLAGS_BRIGHTNESS = 64;
	public const uint32 VP_FLAGS_CONTRAST = 128;
	public const uint32 VP_FLAGS_COPYPROTECT = 256;
	public const uint32 VP_MODE_WIN_GRAPHICS = 1;
	public const uint32 VP_MODE_TV_PLAYBACK = 2;
	public const uint32 VP_TV_STANDARD_NTSC_M = 1;
	public const uint32 VP_TV_STANDARD_NTSC_M_J = 2;
	public const uint32 VP_TV_STANDARD_PAL_B = 4;
	public const uint32 VP_TV_STANDARD_PAL_D = 8;
	public const uint32 VP_TV_STANDARD_PAL_H = 16;
	public const uint32 VP_TV_STANDARD_PAL_I = 32;
	public const uint32 VP_TV_STANDARD_PAL_M = 64;
	public const uint32 VP_TV_STANDARD_PAL_N = 128;
	public const uint32 VP_TV_STANDARD_SECAM_B = 256;
	public const uint32 VP_TV_STANDARD_SECAM_D = 512;
	public const uint32 VP_TV_STANDARD_SECAM_G = 1024;
	public const uint32 VP_TV_STANDARD_SECAM_H = 2048;
	public const uint32 VP_TV_STANDARD_SECAM_K = 4096;
	public const uint32 VP_TV_STANDARD_SECAM_K1 = 8192;
	public const uint32 VP_TV_STANDARD_SECAM_L = 16384;
	public const uint32 VP_TV_STANDARD_WIN_VGA = 32768;
	public const uint32 VP_TV_STANDARD_NTSC_433 = 65536;
	public const uint32 VP_TV_STANDARD_PAL_G = 131072;
	public const uint32 VP_TV_STANDARD_PAL_60 = 262144;
	public const uint32 VP_TV_STANDARD_SECAM_L1 = 524288;
	public const uint32 VP_CP_TYPE_APS_TRIGGER = 1;
	public const uint32 VP_CP_TYPE_MACROVISION = 2;
	public const uint32 VP_CP_CMD_ACTIVATE = 1;
	public const uint32 VP_CP_CMD_DEACTIVATE = 2;
	public const uint32 VP_CP_CMD_CHANGE = 4;
	public const uint32 ICVERSION = 260;
	public const uint32 BI_1632 = 842217009;
	public const int32 ICERR_OK = 0;
	public const int32 ICERR_DONTDRAW = 1;
	public const int32 ICERR_NEWPALETTE = 2;
	public const int32 ICERR_GOTOKEYFRAME = 3;
	public const int32 ICERR_STOPDRAWING = 4;
	public const int32 ICERR_UNSUPPORTED = -1;
	public const int32 ICERR_BADFORMAT = -2;
	public const int32 ICERR_MEMORY = -3;
	public const int32 ICERR_INTERNAL = -4;
	public const int32 ICERR_BADFLAGS = -5;
	public const int32 ICERR_BADPARAM = -6;
	public const int32 ICERR_BADSIZE = -7;
	public const int32 ICERR_BADHANDLE = -8;
	public const int32 ICERR_CANTUPDATE = -9;
	public const int32 ICERR_ABORT = -10;
	public const int32 ICERR_ERROR = -100;
	public const int32 ICERR_BADBITDEPTH = -200;
	public const int32 ICERR_BADIMAGESIZE = -201;
	public const int32 ICERR_CUSTOM = -400;
	public const uint32 ICMODE_COMPRESS = 1;
	public const uint32 ICMODE_DECOMPRESS = 2;
	public const uint32 ICMODE_FASTDECOMPRESS = 3;
	public const uint32 ICMODE_QUERY = 4;
	public const uint32 ICMODE_FASTCOMPRESS = 5;
	public const uint32 ICMODE_DRAW = 8;
	public const uint32 ICMODE_INTERNALF_FUNCTION32 = 32768;
	public const uint32 ICMODE_INTERNALF_MASK = 32768;
	public const int32 AVIIF_TWOCC = 2;
	public const uint32 ICQUALITY_LOW = 0;
	public const uint32 ICQUALITY_HIGH = 10000;
	public const int32 ICQUALITY_DEFAULT = -1;
	public const uint32 ICM_USER = 16384;
	public const uint32 ICM_RESERVED_LOW = 20480;
	public const uint32 ICM_RESERVED_HIGH = 24576;
	public const uint32 ICM_GETSTATE = 20480;
	public const uint32 ICM_SETSTATE = 20481;
	public const uint32 ICM_GETINFO = 20482;
	public const uint32 ICM_CONFIGURE = 20490;
	public const uint32 ICM_ABOUT = 20491;
	public const uint32 ICM_GETERRORTEXT = 20492;
	public const uint32 ICM_GETFORMATNAME = 20500;
	public const uint32 ICM_ENUMFORMATS = 20501;
	public const uint32 ICM_GETDEFAULTQUALITY = 20510;
	public const uint32 ICM_GETQUALITY = 20511;
	public const uint32 ICM_SETQUALITY = 20512;
	public const uint32 ICM_SET = 20520;
	public const uint32 ICM_GET = 20521;
	public const uint32 ICM_COMPRESS_GET_FORMAT = 16388;
	public const uint32 ICM_COMPRESS_GET_SIZE = 16389;
	public const uint32 ICM_COMPRESS_QUERY = 16390;
	public const uint32 ICM_COMPRESS_BEGIN = 16391;
	public const uint32 ICM_COMPRESS = 16392;
	public const uint32 ICM_COMPRESS_END = 16393;
	public const uint32 ICM_DECOMPRESS_GET_FORMAT = 16394;
	public const uint32 ICM_DECOMPRESS_QUERY = 16395;
	public const uint32 ICM_DECOMPRESS_BEGIN = 16396;
	public const uint32 ICM_DECOMPRESS = 16397;
	public const uint32 ICM_DECOMPRESS_END = 16398;
	public const uint32 ICM_DECOMPRESS_SET_PALETTE = 16413;
	public const uint32 ICM_DECOMPRESS_GET_PALETTE = 16414;
	public const uint32 ICM_DRAW_QUERY = 16415;
	public const uint32 ICM_DRAW_BEGIN = 16399;
	public const uint32 ICM_DRAW_GET_PALETTE = 16400;
	public const uint32 ICM_DRAW_UPDATE = 16401;
	public const uint32 ICM_DRAW_START = 16402;
	public const uint32 ICM_DRAW_STOP = 16403;
	public const uint32 ICM_DRAW_BITS = 16404;
	public const uint32 ICM_DRAW_END = 16405;
	public const uint32 ICM_DRAW_GETTIME = 16416;
	public const uint32 ICM_DRAW = 16417;
	public const uint32 ICM_DRAW_WINDOW = 16418;
	public const uint32 ICM_DRAW_SETTIME = 16419;
	public const uint32 ICM_DRAW_REALIZE = 16420;
	public const uint32 ICM_DRAW_FLUSH = 16421;
	public const uint32 ICM_DRAW_RENDERBUFFER = 16422;
	public const uint32 ICM_DRAW_START_PLAY = 16423;
	public const uint32 ICM_DRAW_STOP_PLAY = 16424;
	public const uint32 ICM_DRAW_SUGGESTFORMAT = 16434;
	public const uint32 ICM_DRAW_CHANGEPALETTE = 16435;
	public const uint32 ICM_DRAW_IDLE = 16436;
	public const uint32 ICM_GETBUFFERSWANTED = 16425;
	public const uint32 ICM_GETDEFAULTKEYFRAMERATE = 16426;
	public const uint32 ICM_DECOMPRESSEX_BEGIN = 16444;
	public const uint32 ICM_DECOMPRESSEX_QUERY = 16445;
	public const uint32 ICM_DECOMPRESSEX = 16446;
	public const uint32 ICM_DECOMPRESSEX_END = 16447;
	public const uint32 ICM_COMPRESS_FRAMES_INFO = 16454;
	public const uint32 ICM_COMPRESS_FRAMES = 16455;
	public const uint32 ICM_SET_STATUS_PROC = 16456;
	public const uint32 VIDCF_QUALITY = 1;
	public const uint32 VIDCF_CRUNCH = 2;
	public const uint32 VIDCF_TEMPORAL = 4;
	public const uint32 VIDCF_COMPRESSFRAMES = 8;
	public const uint32 VIDCF_DRAW = 16;
	public const uint32 VIDCF_FASTTEMPORALC = 32;
	public const uint32 VIDCF_FASTTEMPORALD = 128;
	public const int32 ICCOMPRESS_KEYFRAME = 1;
	public const uint32 ICCOMPRESSFRAMES_PADDING = 1;
	public const uint32 ICSTATUS_START = 0;
	public const uint32 ICSTATUS_STATUS = 1;
	public const uint32 ICSTATUS_END = 2;
	public const uint32 ICSTATUS_ERROR = 3;
	public const uint32 ICSTATUS_YIELD = 4;
	public const int32 ICDECOMPRESS_HURRYUP = -2147483648;
	public const int32 ICDECOMPRESS_UPDATE = 1073741824;
	public const int32 ICDECOMPRESS_PREROLL = 536870912;
	public const int32 ICDECOMPRESS_NULLFRAME = 268435456;
	public const int32 ICDECOMPRESS_NOTKEYFRAME = 134217728;
	public const int32 ICDRAW_QUERY = 1;
	public const int32 ICDRAW_FULLSCREEN = 2;
	public const int32 ICDRAW_HDC = 4;
	public const int32 ICDRAW_ANIMATE = 8;
	public const int32 ICDRAW_CONTINUE = 16;
	public const int32 ICDRAW_MEMORYDC = 32;
	public const int32 ICDRAW_UPDATING = 64;
	public const int32 ICDRAW_RENDER = 128;
	public const int32 ICDRAW_BUFFER = 256;
	public const int32 ICDRAW_HURRYUP = -2147483648;
	public const int32 ICDRAW_UPDATE = 1073741824;
	public const int32 ICDRAW_PREROLL = 536870912;
	public const int32 ICDRAW_NULLFRAME = 268435456;
	public const int32 ICDRAW_NOTKEYFRAME = 134217728;
	public const uint32 ICINSTALL_UNICODE = 32768;
	public const uint32 ICINSTALL_FUNCTION = 1;
	public const uint32 ICINSTALL_DRIVER = 2;
	public const uint32 ICINSTALL_HDRV = 4;
	public const uint32 ICINSTALL_DRIVERW = 32770;
	public const uint32 ICMF_CONFIGURE_QUERY = 1;
	public const uint32 ICMF_ABOUT_QUERY = 1;
	public const uint32 ICMF_COMPVARS_VALID = 1;
	public const uint32 ICMF_CHOOSE_KEYFRAME = 1;
	public const uint32 ICMF_CHOOSE_DATARATE = 2;
	public const uint32 ICMF_CHOOSE_PREVIEW = 4;
	public const uint32 ICMF_CHOOSE_ALLCOMPRESSORS = 8;
	public const uint32 DDF_0001 = 1;
	public const uint32 DDF_UPDATE = 2;
	public const uint32 DDF_SAME_HDC = 4;
	public const uint32 DDF_SAME_DRAW = 8;
	public const uint32 DDF_DONTDRAW = 16;
	public const uint32 DDF_ANIMATE = 32;
	public const uint32 DDF_BUFFER = 64;
	public const uint32 DDF_JUSTDRAWIT = 128;
	public const uint32 DDF_FULLSCREEN = 256;
	public const uint32 DDF_BACKGROUNDPAL = 512;
	public const uint32 DDF_NOTKEYFRAME = 1024;
	public const uint32 DDF_HURRYUP = 2048;
	public const uint32 DDF_HALFTONE = 4096;
	public const uint32 DDF_2000 = 8192;
	public const uint32 DDF_PREROLL = 16;
	public const uint32 DDF_SAME_DIB = 8;
	public const uint32 DDF_SAME_SIZE = 8;
	public const uint32 PD_CAN_DRAW_DIB = 1;
	public const uint32 PD_CAN_STRETCHDIB = 2;
	public const uint32 PD_STRETCHDIB_1_1_OK = 4;
	public const uint32 PD_STRETCHDIB_1_2_OK = 8;
	public const uint32 PD_STRETCHDIB_1_N_OK = 16;
	public const uint32 AVIGETFRAMEF_BESTDISPLAYFMT = 1;
	public const uint32 AVISTREAMINFO_DISABLED = 1;
	public const uint32 AVISTREAMINFO_FORMATCHANGES = 65536;
	public const uint32 AVIFILEINFO_HASINDEX = 16;
	public const uint32 AVIFILEINFO_MUSTUSEINDEX = 32;
	public const uint32 AVIFILEINFO_ISINTERLEAVED = 256;
	public const uint32 AVIFILEINFO_WASCAPTUREFILE = 65536;
	public const uint32 AVIFILEINFO_COPYRIGHTED = 131072;
	public const uint32 AVIFILECAPS_CANREAD = 1;
	public const uint32 AVIFILECAPS_CANWRITE = 2;
	public const uint32 AVIFILECAPS_ALLKEYFRAMES = 16;
	public const uint32 AVIFILECAPS_NOCOMPRESSION = 32;
	public const uint32 AVICOMPRESSF_INTERLEAVE = 1;
	public const uint32 AVICOMPRESSF_DATARATE = 2;
	public const uint32 AVICOMPRESSF_KEYFRAMES = 4;
	public const uint32 AVICOMPRESSF_VALID = 8;
	public const Guid CLSID_AVISimpleUnMarshal = .(0x00020009, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CLSID_AVIFile = .(0x00020000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const uint32 AVIFILEHANDLER_CANREAD = 1;
	public const uint32 AVIFILEHANDLER_CANWRITE = 2;
	public const uint32 AVIFILEHANDLER_CANACCEPTNONRGB = 4;
	public const int32 AVISTREAMREAD_CONVENIENT = -1;
	public const int32 FIND_DIR = 15;
	public const int32 FIND_NEXT = 1;
	public const int32 FIND_PREV = 4;
	public const int32 FIND_FROM_START = 8;
	public const int32 FIND_TYPE = 240;
	public const int32 FIND_KEY = 16;
	public const int32 FIND_ANY = 32;
	public const int32 FIND_FORMAT = 64;
	public const int32 FIND_RET = 61440;
	public const int32 FIND_POS = 0;
	public const int32 FIND_LENGTH = 4096;
	public const int32 FIND_OFFSET = 8192;
	public const int32 FIND_SIZE = 12288;
	public const int32 FIND_INDEX = 16384;
	public const int32 SEARCH_NEAREST = 4;
	public const int32 SEARCH_BACKWARD = 4;
	public const int32 SEARCH_FORWARD = 1;
	public const int32 SEARCH_KEY = 16;
	public const int32 SEARCH_ANY = 32;
	public const int32 AVIERR_OK = 0;
	public const String MCIWND_WINDOW_CLASS = "MCIWndClass";
	public const uint32 MCIWNDOPENF_NEW = 1;
	public const uint32 MCIWNDF_NOAUTOSIZEWINDOW = 1;
	public const uint32 MCIWNDF_NOPLAYBAR = 2;
	public const uint32 MCIWNDF_NOAUTOSIZEMOVIE = 4;
	public const uint32 MCIWNDF_NOMENU = 8;
	public const uint32 MCIWNDF_SHOWNAME = 16;
	public const uint32 MCIWNDF_SHOWPOS = 32;
	public const uint32 MCIWNDF_SHOWMODE = 64;
	public const uint32 MCIWNDF_SHOWALL = 112;
	public const uint32 MCIWNDF_NOTIFYMODE = 256;
	public const uint32 MCIWNDF_NOTIFYPOS = 512;
	public const uint32 MCIWNDF_NOTIFYSIZE = 1024;
	public const uint32 MCIWNDF_NOTIFYERROR = 4096;
	public const uint32 MCIWNDF_NOTIFYALL = 7936;
	public const uint32 MCIWNDF_NOTIFYANSI = 128;
	public const uint32 MCIWNDF_NOTIFYMEDIAA = 2176;
	public const uint32 MCIWNDF_NOTIFYMEDIAW = 2048;
	public const uint32 MCIWNDF_NOTIFYMEDIA = 2048;
	public const uint32 MCIWNDF_RECORD = 8192;
	public const uint32 MCIWNDF_NOERRORDLG = 16384;
	public const uint32 MCIWNDF_NOOPEN = 32768;
	public const uint32 MCIWNDM_GETDEVICEID = 1124;
	public const uint32 MCIWNDM_GETSTART = 1127;
	public const uint32 MCIWNDM_GETLENGTH = 1128;
	public const uint32 MCIWNDM_GETEND = 1129;
	public const uint32 MCIWNDM_EJECT = 1131;
	public const uint32 MCIWNDM_SETZOOM = 1132;
	public const uint32 MCIWNDM_GETZOOM = 1133;
	public const uint32 MCIWNDM_SETVOLUME = 1134;
	public const uint32 MCIWNDM_GETVOLUME = 1135;
	public const uint32 MCIWNDM_SETSPEED = 1136;
	public const uint32 MCIWNDM_GETSPEED = 1137;
	public const uint32 MCIWNDM_SETREPEAT = 1138;
	public const uint32 MCIWNDM_GETREPEAT = 1139;
	public const uint32 MCIWNDM_REALIZE = 1142;
	public const uint32 MCIWNDM_VALIDATEMEDIA = 1145;
	public const uint32 MCIWNDM_PLAYFROM = 1146;
	public const uint32 MCIWNDM_PLAYTO = 1147;
	public const uint32 MCIWNDM_GETPALETTE = 1150;
	public const uint32 MCIWNDM_SETPALETTE = 1151;
	public const uint32 MCIWNDM_SETTIMERS = 1153;
	public const uint32 MCIWNDM_SETACTIVETIMER = 1154;
	public const uint32 MCIWNDM_SETINACTIVETIMER = 1155;
	public const uint32 MCIWNDM_GETACTIVETIMER = 1156;
	public const uint32 MCIWNDM_GETINACTIVETIMER = 1157;
	public const uint32 MCIWNDM_CHANGESTYLES = 1159;
	public const uint32 MCIWNDM_GETSTYLES = 1160;
	public const uint32 MCIWNDM_GETALIAS = 1161;
	public const uint32 MCIWNDM_PLAYREVERSE = 1163;
	public const uint32 MCIWNDM_GET_SOURCE = 1164;
	public const uint32 MCIWNDM_PUT_SOURCE = 1165;
	public const uint32 MCIWNDM_GET_DEST = 1166;
	public const uint32 MCIWNDM_PUT_DEST = 1167;
	public const uint32 MCIWNDM_CAN_PLAY = 1168;
	public const uint32 MCIWNDM_CAN_WINDOW = 1169;
	public const uint32 MCIWNDM_CAN_RECORD = 1170;
	public const uint32 MCIWNDM_CAN_SAVE = 1171;
	public const uint32 MCIWNDM_CAN_EJECT = 1172;
	public const uint32 MCIWNDM_CAN_CONFIG = 1173;
	public const uint32 MCIWNDM_PALETTEKICK = 1174;
	public const uint32 MCIWNDM_OPENINTERFACE = 1175;
	public const uint32 MCIWNDM_SETOWNER = 1176;
	public const uint32 MCIWNDM_SENDSTRINGA = 1125;
	public const uint32 MCIWNDM_GETPOSITIONA = 1126;
	public const uint32 MCIWNDM_GETMODEA = 1130;
	public const uint32 MCIWNDM_SETTIMEFORMATA = 1143;
	public const uint32 MCIWNDM_GETTIMEFORMATA = 1144;
	public const uint32 MCIWNDM_GETFILENAMEA = 1148;
	public const uint32 MCIWNDM_GETDEVICEA = 1149;
	public const uint32 MCIWNDM_GETERRORA = 1152;
	public const uint32 MCIWNDM_NEWA = 1158;
	public const uint32 MCIWNDM_RETURNSTRINGA = 1162;
	public const uint32 MCIWNDM_OPENA = 1177;
	public const uint32 MCIWNDM_SENDSTRINGW = 1225;
	public const uint32 MCIWNDM_GETPOSITIONW = 1226;
	public const uint32 MCIWNDM_GETMODEW = 1230;
	public const uint32 MCIWNDM_SETTIMEFORMATW = 1243;
	public const uint32 MCIWNDM_GETTIMEFORMATW = 1244;
	public const uint32 MCIWNDM_GETFILENAMEW = 1248;
	public const uint32 MCIWNDM_GETDEVICEW = 1249;
	public const uint32 MCIWNDM_GETERRORW = 1252;
	public const uint32 MCIWNDM_NEWW = 1258;
	public const uint32 MCIWNDM_RETURNSTRINGW = 1262;
	public const uint32 MCIWNDM_OPENW = 1276;
	public const uint32 MCIWNDM_SENDSTRING = 1225;
	public const uint32 MCIWNDM_GETPOSITION = 1226;
	public const uint32 MCIWNDM_GETMODE = 1230;
	public const uint32 MCIWNDM_SETTIMEFORMAT = 1243;
	public const uint32 MCIWNDM_GETTIMEFORMAT = 1244;
	public const uint32 MCIWNDM_GETFILENAME = 1248;
	public const uint32 MCIWNDM_GETDEVICE = 1249;
	public const uint32 MCIWNDM_GETERROR = 1252;
	public const uint32 MCIWNDM_NEW = 1258;
	public const uint32 MCIWNDM_RETURNSTRING = 1262;
	public const uint32 MCIWNDM_OPEN = 1276;
	public const uint32 MCIWNDM_NOTIFYMODE = 1224;
	public const uint32 MCIWNDM_NOTIFYPOS = 1225;
	public const uint32 MCIWNDM_NOTIFYSIZE = 1226;
	public const uint32 MCIWNDM_NOTIFYMEDIA = 1227;
	public const uint32 MCIWNDM_NOTIFYERROR = 1229;
	public const int32 MCIWND_START = -1;
	public const int32 MCIWND_END = -2;
	public const uint32 MCI_OPEN = 2051;
	public const uint32 MCI_CLOSE = 2052;
	public const uint32 MCI_PLAY = 2054;
	public const uint32 MCI_SEEK = 2055;
	public const uint32 MCI_STOP = 2056;
	public const uint32 MCI_PAUSE = 2057;
	public const uint32 MCI_STEP = 2062;
	public const uint32 MCI_RECORD = 2063;
	public const uint32 MCI_SAVE = 2067;
	public const uint32 MCI_CUT = 2129;
	public const uint32 MCI_COPY = 2130;
	public const uint32 MCI_PASTE = 2131;
	public const uint32 MCI_RESUME = 2133;
	public const uint32 MCI_DELETE = 2134;
	public const uint32 MCI_MODE_NOT_READY = 524;
	public const uint32 MCI_MODE_STOP = 525;
	public const uint32 MCI_MODE_PLAY = 526;
	public const uint32 MCI_MODE_RECORD = 527;
	public const uint32 MCI_MODE_SEEK = 528;
	public const uint32 MCI_MODE_PAUSE = 529;
	public const uint32 MCI_MODE_OPEN = 530;
	public const uint32 DV_ERR_OK = 0;
	public const uint32 DV_ERR_BASE = 1;
	public const uint32 DV_ERR_NONSPECIFIC = 1;
	public const uint32 DV_ERR_BADFORMAT = 2;
	public const uint32 DV_ERR_STILLPLAYING = 3;
	public const uint32 DV_ERR_UNPREPARED = 4;
	public const uint32 DV_ERR_SYNC = 5;
	public const uint32 DV_ERR_TOOMANYCHANNELS = 6;
	public const uint32 DV_ERR_NOTDETECTED = 7;
	public const uint32 DV_ERR_BADINSTALL = 8;
	public const uint32 DV_ERR_CREATEPALETTE = 9;
	public const uint32 DV_ERR_SIZEFIELD = 10;
	public const uint32 DV_ERR_PARAM1 = 11;
	public const uint32 DV_ERR_PARAM2 = 12;
	public const uint32 DV_ERR_CONFIG1 = 13;
	public const uint32 DV_ERR_CONFIG2 = 14;
	public const uint32 DV_ERR_FLAGS = 15;
	public const uint32 DV_ERR_13 = 16;
	public const uint32 DV_ERR_NOTSUPPORTED = 17;
	public const uint32 DV_ERR_NOMEM = 18;
	public const uint32 DV_ERR_ALLOCATED = 19;
	public const uint32 DV_ERR_BADDEVICEID = 20;
	public const uint32 DV_ERR_INVALHANDLE = 21;
	public const uint32 DV_ERR_BADERRNUM = 22;
	public const uint32 DV_ERR_NO_BUFFERS = 23;
	public const uint32 DV_ERR_MEM_CONFLICT = 24;
	public const uint32 DV_ERR_IO_CONFLICT = 25;
	public const uint32 DV_ERR_DMA_CONFLICT = 26;
	public const uint32 DV_ERR_INT_CONFLICT = 27;
	public const uint32 DV_ERR_PROTECT_ONLY = 28;
	public const uint32 DV_ERR_LASTERROR = 28;
	public const uint32 DV_ERR_USER_MSG = 1001;
	public const uint32 DV_VM_OPEN = 976;
	public const uint32 DV_VM_CLOSE = 977;
	public const uint32 DV_VM_DATA = 978;
	public const uint32 DV_VM_ERROR = 979;
	public const uint32 VHDR_DONE = 1;
	public const uint32 VHDR_PREPARED = 2;
	public const uint32 VHDR_INQUEUE = 4;
	public const uint32 VHDR_KEYFRAME = 8;
	public const uint32 VHDR_VALID = 15;
	public const uint32 VCAPS_OVERLAY = 1;
	public const uint32 VCAPS_SRC_CAN_CLIP = 2;
	public const uint32 VCAPS_DST_CAN_CLIP = 4;
	public const uint32 VCAPS_CAN_SCALE = 8;
	public const uint32 VIDEO_EXTERNALIN = 1;
	public const uint32 VIDEO_EXTERNALOUT = 2;
	public const uint32 VIDEO_IN = 4;
	public const uint32 VIDEO_OUT = 8;
	public const uint32 VIDEO_DLG_QUERY = 16;
	public const uint32 VIDEO_CONFIGURE_QUERY = 32768;
	public const uint32 VIDEO_CONFIGURE_SET = 4096;
	public const uint32 VIDEO_CONFIGURE_GET = 8192;
	public const uint32 VIDEO_CONFIGURE_QUERYSIZE = 1;
	public const uint32 VIDEO_CONFIGURE_CURRENT = 16;
	public const uint32 VIDEO_CONFIGURE_NOMINAL = 32;
	public const uint32 VIDEO_CONFIGURE_MIN = 64;
	public const uint32 VIDEO_CONFIGURE_MAX = 128;
	public const uint32 DVM_USER = 16384;
	public const uint32 DVM_CONFIGURE_START = 4096;
	public const uint32 DVM_CONFIGURE_END = 8191;
	public const uint32 DVM_PALETTE = 4097;
	public const uint32 DVM_FORMAT = 4098;
	public const uint32 DVM_PALETTERGB555 = 4099;
	public const uint32 DVM_SRC_RECT = 4100;
	public const uint32 DVM_DST_RECT = 4101;
	public const uint32 WM_CAP_UNICODE_START = 1124;
	public const uint32 WM_CAP_GET_CAPSTREAMPTR = 1025;
	public const uint32 WM_CAP_SET_CALLBACK_ERRORW = 1126;
	public const uint32 WM_CAP_SET_CALLBACK_STATUSW = 1127;
	public const uint32 WM_CAP_SET_CALLBACK_ERRORA = 1026;
	public const uint32 WM_CAP_SET_CALLBACK_STATUSA = 1027;
	public const uint32 WM_CAP_SET_CALLBACK_ERROR = 1126;
	public const uint32 WM_CAP_SET_CALLBACK_STATUS = 1127;
	public const uint32 WM_CAP_SET_CALLBACK_YIELD = 1028;
	public const uint32 WM_CAP_SET_CALLBACK_FRAME = 1029;
	public const uint32 WM_CAP_SET_CALLBACK_VIDEOSTREAM = 1030;
	public const uint32 WM_CAP_SET_CALLBACK_WAVESTREAM = 1031;
	public const uint32 WM_CAP_GET_USER_DATA = 1032;
	public const uint32 WM_CAP_SET_USER_DATA = 1033;
	public const uint32 WM_CAP_DRIVER_CONNECT = 1034;
	public const uint32 WM_CAP_DRIVER_DISCONNECT = 1035;
	public const uint32 WM_CAP_DRIVER_GET_NAMEA = 1036;
	public const uint32 WM_CAP_DRIVER_GET_VERSIONA = 1037;
	public const uint32 WM_CAP_DRIVER_GET_NAMEW = 1136;
	public const uint32 WM_CAP_DRIVER_GET_VERSIONW = 1137;
	public const uint32 WM_CAP_DRIVER_GET_NAME = 1136;
	public const uint32 WM_CAP_DRIVER_GET_VERSION = 1137;
	public const uint32 WM_CAP_DRIVER_GET_CAPS = 1038;
	public const uint32 WM_CAP_FILE_SET_CAPTURE_FILEA = 1044;
	public const uint32 WM_CAP_FILE_GET_CAPTURE_FILEA = 1045;
	public const uint32 WM_CAP_FILE_SAVEASA = 1047;
	public const uint32 WM_CAP_FILE_SAVEDIBA = 1049;
	public const uint32 WM_CAP_FILE_SET_CAPTURE_FILEW = 1144;
	public const uint32 WM_CAP_FILE_GET_CAPTURE_FILEW = 1145;
	public const uint32 WM_CAP_FILE_SAVEASW = 1147;
	public const uint32 WM_CAP_FILE_SAVEDIBW = 1149;
	public const uint32 WM_CAP_FILE_SET_CAPTURE_FILE = 1144;
	public const uint32 WM_CAP_FILE_GET_CAPTURE_FILE = 1145;
	public const uint32 WM_CAP_FILE_SAVEAS = 1147;
	public const uint32 WM_CAP_FILE_SAVEDIB = 1149;
	public const uint32 WM_CAP_FILE_ALLOCATE = 1046;
	public const uint32 WM_CAP_FILE_SET_INFOCHUNK = 1048;
	public const uint32 WM_CAP_EDIT_COPY = 1054;
	public const uint32 WM_CAP_SET_AUDIOFORMAT = 1059;
	public const uint32 WM_CAP_GET_AUDIOFORMAT = 1060;
	public const uint32 WM_CAP_DLG_VIDEOFORMAT = 1065;
	public const uint32 WM_CAP_DLG_VIDEOSOURCE = 1066;
	public const uint32 WM_CAP_DLG_VIDEODISPLAY = 1067;
	public const uint32 WM_CAP_GET_VIDEOFORMAT = 1068;
	public const uint32 WM_CAP_SET_VIDEOFORMAT = 1069;
	public const uint32 WM_CAP_DLG_VIDEOCOMPRESSION = 1070;
	public const uint32 WM_CAP_SET_PREVIEW = 1074;
	public const uint32 WM_CAP_SET_OVERLAY = 1075;
	public const uint32 WM_CAP_SET_PREVIEWRATE = 1076;
	public const uint32 WM_CAP_SET_SCALE = 1077;
	public const uint32 WM_CAP_GET_STATUS = 1078;
	public const uint32 WM_CAP_SET_SCROLL = 1079;
	public const uint32 WM_CAP_GRAB_FRAME = 1084;
	public const uint32 WM_CAP_GRAB_FRAME_NOSTOP = 1085;
	public const uint32 WM_CAP_SEQUENCE = 1086;
	public const uint32 WM_CAP_SEQUENCE_NOFILE = 1087;
	public const uint32 WM_CAP_SET_SEQUENCE_SETUP = 1088;
	public const uint32 WM_CAP_GET_SEQUENCE_SETUP = 1089;
	public const uint32 WM_CAP_SET_MCI_DEVICEA = 1090;
	public const uint32 WM_CAP_GET_MCI_DEVICEA = 1091;
	public const uint32 WM_CAP_SET_MCI_DEVICEW = 1190;
	public const uint32 WM_CAP_GET_MCI_DEVICEW = 1191;
	public const uint32 WM_CAP_SET_MCI_DEVICE = 1190;
	public const uint32 WM_CAP_GET_MCI_DEVICE = 1191;
	public const uint32 WM_CAP_STOP = 1092;
	public const uint32 WM_CAP_ABORT = 1093;
	public const uint32 WM_CAP_SINGLE_FRAME_OPEN = 1094;
	public const uint32 WM_CAP_SINGLE_FRAME_CLOSE = 1095;
	public const uint32 WM_CAP_SINGLE_FRAME = 1096;
	public const uint32 WM_CAP_PAL_OPENA = 1104;
	public const uint32 WM_CAP_PAL_SAVEA = 1105;
	public const uint32 WM_CAP_PAL_OPENW = 1204;
	public const uint32 WM_CAP_PAL_SAVEW = 1205;
	public const uint32 WM_CAP_PAL_OPEN = 1204;
	public const uint32 WM_CAP_PAL_SAVE = 1205;
	public const uint32 WM_CAP_PAL_PASTE = 1106;
	public const uint32 WM_CAP_PAL_AUTOCREATE = 1107;
	public const uint32 WM_CAP_PAL_MANUALCREATE = 1108;
	public const uint32 WM_CAP_SET_CALLBACK_CAPCONTROL = 1109;
	public const uint32 WM_CAP_UNICODE_END = 1205;
	public const uint32 WM_CAP_END = 1205;
	public const uint32 AVSTREAMMASTER_AUDIO = 0;
	public const uint32 AVSTREAMMASTER_NONE = 1;
	public const uint32 CONTROLCALLBACK_PREROLL = 1;
	public const uint32 CONTROLCALLBACK_CAPTURING = 2;
	public const uint32 IDS_CAP_BEGIN = 300;
	public const uint32 IDS_CAP_END = 301;
	public const uint32 IDS_CAP_INFO = 401;
	public const uint32 IDS_CAP_OUTOFMEM = 402;
	public const uint32 IDS_CAP_FILEEXISTS = 403;
	public const uint32 IDS_CAP_ERRORPALOPEN = 404;
	public const uint32 IDS_CAP_ERRORPALSAVE = 405;
	public const uint32 IDS_CAP_ERRORDIBSAVE = 406;
	public const uint32 IDS_CAP_DEFAVIEXT = 407;
	public const uint32 IDS_CAP_DEFPALEXT = 408;
	public const uint32 IDS_CAP_CANTOPEN = 409;
	public const uint32 IDS_CAP_SEQ_MSGSTART = 410;
	public const uint32 IDS_CAP_SEQ_MSGSTOP = 411;
	public const uint32 IDS_CAP_VIDEDITERR = 412;
	public const uint32 IDS_CAP_READONLYFILE = 413;
	public const uint32 IDS_CAP_WRITEERROR = 414;
	public const uint32 IDS_CAP_NODISKSPACE = 415;
	public const uint32 IDS_CAP_SETFILESIZE = 416;
	public const uint32 IDS_CAP_SAVEASPERCENT = 417;
	public const uint32 IDS_CAP_DRIVER_ERROR = 418;
	public const uint32 IDS_CAP_WAVE_OPEN_ERROR = 419;
	public const uint32 IDS_CAP_WAVE_ALLOC_ERROR = 420;
	public const uint32 IDS_CAP_WAVE_PREPARE_ERROR = 421;
	public const uint32 IDS_CAP_WAVE_ADD_ERROR = 422;
	public const uint32 IDS_CAP_WAVE_SIZE_ERROR = 423;
	public const uint32 IDS_CAP_VIDEO_OPEN_ERROR = 424;
	public const uint32 IDS_CAP_VIDEO_ALLOC_ERROR = 425;
	public const uint32 IDS_CAP_VIDEO_PREPARE_ERROR = 426;
	public const uint32 IDS_CAP_VIDEO_ADD_ERROR = 427;
	public const uint32 IDS_CAP_VIDEO_SIZE_ERROR = 428;
	public const uint32 IDS_CAP_FILE_OPEN_ERROR = 429;
	public const uint32 IDS_CAP_FILE_WRITE_ERROR = 430;
	public const uint32 IDS_CAP_RECORDING_ERROR = 431;
	public const uint32 IDS_CAP_RECORDING_ERROR2 = 432;
	public const uint32 IDS_CAP_AVI_INIT_ERROR = 433;
	public const uint32 IDS_CAP_NO_FRAME_CAP_ERROR = 434;
	public const uint32 IDS_CAP_NO_PALETTE_WARN = 435;
	public const uint32 IDS_CAP_MCI_CONTROL_ERROR = 436;
	public const uint32 IDS_CAP_MCI_CANT_STEP_ERROR = 437;
	public const uint32 IDS_CAP_NO_AUDIO_CAP_ERROR = 438;
	public const uint32 IDS_CAP_AVI_DRAWDIB_ERROR = 439;
	public const uint32 IDS_CAP_COMPRESSOR_ERROR = 440;
	public const uint32 IDS_CAP_AUDIO_DROP_ERROR = 441;
	public const uint32 IDS_CAP_AUDIO_DROP_COMPERROR = 442;
	public const uint32 IDS_CAP_STAT_LIVE_MODE = 500;
	public const uint32 IDS_CAP_STAT_OVERLAY_MODE = 501;
	public const uint32 IDS_CAP_STAT_CAP_INIT = 502;
	public const uint32 IDS_CAP_STAT_CAP_FINI = 503;
	public const uint32 IDS_CAP_STAT_PALETTE_BUILD = 504;
	public const uint32 IDS_CAP_STAT_OPTPAL_BUILD = 505;
	public const uint32 IDS_CAP_STAT_I_FRAMES = 506;
	public const uint32 IDS_CAP_STAT_L_FRAMES = 507;
	public const uint32 IDS_CAP_STAT_CAP_L_FRAMES = 508;
	public const uint32 IDS_CAP_STAT_CAP_AUDIO = 509;
	public const uint32 IDS_CAP_STAT_VIDEOCURRENT = 510;
	public const uint32 IDS_CAP_STAT_VIDEOAUDIO = 511;
	public const uint32 IDS_CAP_STAT_VIDEOONLY = 512;
	public const uint32 IDS_CAP_STAT_FRAMESDROPPED = 513;
	public const uint32 JOYERR_NOERROR = 0;
	public const uint32 JOYERR_PARMS = 165;
	public const uint32 JOYERR_NOCANDO = 166;
	public const uint32 JOYERR_UNPLUGGED = 167;
	public const uint32 JOY_BUTTON1 = 1;
	public const uint32 JOY_BUTTON2 = 2;
	public const uint32 JOY_BUTTON3 = 4;
	public const uint32 JOY_BUTTON4 = 8;
	public const uint32 JOY_BUTTON1CHG = 256;
	public const uint32 JOY_BUTTON2CHG = 512;
	public const uint32 JOY_BUTTON3CHG = 1024;
	public const uint32 JOY_BUTTON4CHG = 2048;
	public const int32 JOY_BUTTON5 = 16;
	public const int32 JOY_BUTTON6 = 32;
	public const int32 JOY_BUTTON7 = 64;
	public const int32 JOY_BUTTON8 = 128;
	public const int32 JOY_BUTTON9 = 256;
	public const int32 JOY_BUTTON10 = 512;
	public const int32 JOY_BUTTON11 = 1024;
	public const int32 JOY_BUTTON12 = 2048;
	public const int32 JOY_BUTTON13 = 4096;
	public const int32 JOY_BUTTON14 = 8192;
	public const int32 JOY_BUTTON15 = 16384;
	public const int32 JOY_BUTTON16 = 32768;
	public const int32 JOY_BUTTON17 = 65536;
	public const int32 JOY_BUTTON18 = 131072;
	public const int32 JOY_BUTTON19 = 262144;
	public const int32 JOY_BUTTON20 = 524288;
	public const int32 JOY_BUTTON21 = 1048576;
	public const int32 JOY_BUTTON22 = 2097152;
	public const int32 JOY_BUTTON23 = 4194304;
	public const int32 JOY_BUTTON24 = 8388608;
	public const int32 JOY_BUTTON25 = 16777216;
	public const int32 JOY_BUTTON26 = 33554432;
	public const int32 JOY_BUTTON27 = 67108864;
	public const int32 JOY_BUTTON28 = 134217728;
	public const int32 JOY_BUTTON29 = 268435456;
	public const int32 JOY_BUTTON30 = 536870912;
	public const int32 JOY_BUTTON31 = 1073741824;
	public const int32 JOY_BUTTON32 = -2147483648;
	public const uint32 JOY_POVFORWARD = 0;
	public const uint32 JOY_POVRIGHT = 9000;
	public const uint32 JOY_POVBACKWARD = 18000;
	public const uint32 JOY_POVLEFT = 27000;
	public const int32 JOY_RETURNX = 1;
	public const int32 JOY_RETURNY = 2;
	public const int32 JOY_RETURNZ = 4;
	public const int32 JOY_RETURNR = 8;
	public const int32 JOY_RETURNU = 16;
	public const int32 JOY_RETURNV = 32;
	public const int32 JOY_RETURNPOV = 64;
	public const int32 JOY_RETURNBUTTONS = 128;
	public const int32 JOY_RETURNRAWDATA = 256;
	public const int32 JOY_RETURNPOVCTS = 512;
	public const int32 JOY_RETURNCENTERED = 1024;
	public const int32 JOY_USEDEADZONE = 2048;
	public const int32 JOY_CAL_READALWAYS = 65536;
	public const int32 JOY_CAL_READXYONLY = 131072;
	public const int32 JOY_CAL_READ3 = 262144;
	public const int32 JOY_CAL_READ4 = 524288;
	public const int32 JOY_CAL_READXONLY = 1048576;
	public const int32 JOY_CAL_READYONLY = 2097152;
	public const int32 JOY_CAL_READ5 = 4194304;
	public const int32 JOY_CAL_READ6 = 8388608;
	public const int32 JOY_CAL_READZONLY = 16777216;
	public const int32 JOY_CAL_READRONLY = 33554432;
	public const int32 JOY_CAL_READUONLY = 67108864;
	public const int32 JOY_CAL_READVONLY = 134217728;
	public const uint32 JOYSTICKID1 = 0;
	public const uint32 JOYSTICKID2 = 1;
	public const uint32 JOYCAPS_HASZ = 1;
	public const uint32 JOYCAPS_HASR = 2;
	public const uint32 JOYCAPS_HASU = 4;
	public const uint32 JOYCAPS_HASV = 8;
	public const uint32 JOYCAPS_HASPOV = 16;
	public const uint32 JOYCAPS_POV4DIR = 32;
	public const uint32 JOYCAPS_POVCTS = 64;
	public const uint32 DRV_LOAD = 1;
	public const uint32 DRV_ENABLE = 2;
	public const uint32 DRV_OPEN = 3;
	public const uint32 DRV_CLOSE = 4;
	public const uint32 DRV_DISABLE = 5;
	public const uint32 DRV_FREE = 6;
	public const uint32 DRV_CONFIGURE = 7;
	public const uint32 DRV_QUERYCONFIGURE = 8;
	public const uint32 DRV_INSTALL = 9;
	public const uint32 DRV_REMOVE = 10;
	public const uint32 DRV_RESERVED = 2048;
	public const uint32 DRV_USER = 16384;
	public const String DRIVERS_SECTION = "DRIVERS32";
	public const String MCI_SECTION = "MCI32";
	public const uint32 DCB_NOSWITCH = 8;
	public const uint32 DCB_TYPEMASK = 7;
	public const uint32 DCB_NULL = 0;
	public const uint32 DCB_WINDOW = 1;
	public const uint32 DCB_TASK = 2;
	public const uint32 DCB_FUNCTION = 3;
	public const uint32 DCB_EVENT = 5;
	public const uint32 DRVM_INIT = 100;
	public const uint32 DRVM_EXIT = 101;
	public const uint32 DRVM_DISABLE = 102;
	public const uint32 DRVM_ENABLE = 103;
	public const uint32 DRVM_INIT_EX = 104;
	public const uint32 DRVM_USER = 16384;
	public const uint32 DRVM_MAPPER_RECONFIGURE = 8193;
	public const uint32 DRVM_MAPPER_PREFERRED_GET = 8213;
	public const uint32 DRVM_MAPPER_CONSOLEVOICECOM_GET = 8215;
	public const uint32 DRV_QUERYDEVNODE = 2050;
	public const uint32 DRV_QUERYMAPPABLE = 2053;
	public const uint32 DRV_QUERYMODULE = 2057;
	public const uint32 DRV_PNPINSTALL = 2059;
	public const uint32 DRV_QUERYDEVICEINTERFACE = 2060;
	public const uint32 DRV_QUERYDEVICEINTERFACESIZE = 2061;
	public const uint32 DRV_QUERYSTRINGID = 2062;
	public const uint32 DRV_QUERYSTRINGIDSIZE = 2063;
	public const uint32 DRV_QUERYIDFROMSTRINGID = 2064;
	public const uint32 DRV_QUERYFUNCTIONINSTANCEID = 2065;
	public const uint32 DRV_QUERYFUNCTIONINSTANCEIDSIZE = 2066;
	public const uint32 DRVM_MAPPER_PREFERRED_FLAGS_PREFERREDONLY = 1;
	public const uint32 DRVM_IOCTL = 256;
	public const uint32 DRVM_ADD_THRU = 257;
	public const uint32 DRVM_REMOVE_THRU = 258;
	public const uint32 DRVM_IOCTL_LAST = 261;
	public const int32 DRVM_IOCTL_CMD_USER = 0;
	public const int32 DRVM_IOCTL_CMD_SYSTEM = -2147483648;
	public const uint32 VADMAD_Device_ID = 1092;
	public const uint32 WODM_INIT = 100;
	public const uint32 WIDM_INIT = 100;
	public const uint32 WODM_INIT_EX = 104;
	public const uint32 WIDM_INIT_EX = 104;
	public const uint32 WODM_GETNUMDEVS = 3;
	public const uint32 WODM_GETDEVCAPS = 4;
	public const uint32 WODM_OPEN = 5;
	public const uint32 WODM_CLOSE = 6;
	public const uint32 WODM_PREPARE = 7;
	public const uint32 WODM_UNPREPARE = 8;
	public const uint32 WODM_WRITE = 9;
	public const uint32 WODM_PAUSE = 10;
	public const uint32 WODM_RESTART = 11;
	public const uint32 WODM_RESET = 12;
	public const uint32 WODM_GETPOS = 13;
	public const uint32 WODM_GETPITCH = 14;
	public const uint32 WODM_SETPITCH = 15;
	public const uint32 WODM_GETVOLUME = 16;
	public const uint32 WODM_SETVOLUME = 17;
	public const uint32 WODM_GETPLAYBACKRATE = 18;
	public const uint32 WODM_SETPLAYBACKRATE = 19;
	public const uint32 WODM_BREAKLOOP = 20;
	public const uint32 WODM_PREFERRED = 21;
	public const uint32 WODM_BUSY = 21;
	public const uint32 WIDM_GETNUMDEVS = 50;
	public const uint32 WIDM_GETDEVCAPS = 51;
	public const uint32 WIDM_OPEN = 52;
	public const uint32 WIDM_CLOSE = 53;
	public const uint32 WIDM_PREPARE = 54;
	public const uint32 WIDM_UNPREPARE = 55;
	public const uint32 WIDM_ADDBUFFER = 56;
	public const uint32 WIDM_START = 57;
	public const uint32 WIDM_STOP = 58;
	public const uint32 WIDM_RESET = 59;
	public const uint32 WIDM_GETPOS = 60;
	public const uint32 WIDM_PREFERRED = 61;
	public const int32 MIDI_IO_PACKED = 0;
	public const int32 MIDI_IO_COOKED = 2;
	public const uint32 MODM_GETNUMDEVS = 1;
	public const uint32 MODM_GETDEVCAPS = 2;
	public const uint32 MODM_OPEN = 3;
	public const uint32 MODM_CLOSE = 4;
	public const uint32 MODM_PREPARE = 5;
	public const uint32 MODM_UNPREPARE = 6;
	public const uint32 MODM_DATA = 7;
	public const uint32 MODM_LONGDATA = 8;
	public const uint32 MODM_RESET = 9;
	public const uint32 MODM_GETVOLUME = 10;
	public const uint32 MODM_SETVOLUME = 11;
	public const uint32 MODM_CACHEPATCHES = 12;
	public const uint32 MODM_CACHEDRUMPATCHES = 13;
	public const uint32 MODM_STRMDATA = 14;
	public const uint32 MODM_GETPOS = 17;
	public const uint32 MODM_PAUSE = 18;
	public const uint32 MODM_RESTART = 19;
	public const uint32 MODM_STOP = 20;
	public const uint32 MODM_PROPERTIES = 21;
	public const uint32 MODM_PREFERRED = 22;
	public const uint32 MODM_RECONFIGURE = 18280;
	public const uint32 MIDM_GETNUMDEVS = 53;
	public const uint32 MIDM_GETDEVCAPS = 54;
	public const uint32 MIDM_OPEN = 55;
	public const uint32 MIDM_CLOSE = 56;
	public const uint32 MIDM_PREPARE = 57;
	public const uint32 MIDM_UNPREPARE = 58;
	public const uint32 MIDM_ADDBUFFER = 59;
	public const uint32 MIDM_START = 60;
	public const uint32 MIDM_STOP = 61;
	public const uint32 MIDM_RESET = 62;
	public const uint32 AUXM_INIT = 100;
	public const uint32 AUXM_INIT_EX = 104;
	public const uint32 AUXDM_GETNUMDEVS = 3;
	public const uint32 AUXDM_GETDEVCAPS = 4;
	public const uint32 AUXDM_GETVOLUME = 5;
	public const uint32 AUXDM_SETVOLUME = 6;
	public const uint32 MXDM_INIT = 100;
	public const uint32 MXDM_INIT_EX = 104;
	public const uint32 MXDM_USER = 16384;
	public const uint32 MXDM_BASE = 1;
	public const uint32 MXDM_GETNUMDEVS = 1;
	public const uint32 MXDM_GETDEVCAPS = 2;
	public const uint32 MXDM_OPEN = 3;
	public const uint32 MXDM_CLOSE = 4;
	public const uint32 MXDM_GETLINEINFO = 5;
	public const uint32 MXDM_GETLINECONTROLS = 6;
	public const uint32 MXDM_GETCONTROLDETAILS = 7;
	public const uint32 MXDM_SETCONTROLDETAILS = 8;
	public const uint32 TDD_KILLTIMEREVENT = 2048;
	public const uint32 TDD_SETTIMEREVENT = 2052;
	public const uint32 TDD_GETSYSTEMTIME = 2056;
	public const uint32 TDD_GETDEVCAPS = 2060;
	public const uint32 TDD_BEGINMINPERIOD = 2064;
	public const uint32 TDD_ENDMINPERIOD = 2068;
	public const String JOY_CONFIGCHANGED_MSGSTRING = "MSJSTICK_VJOYD_MSGSTR";
	public const uint32 JDD_GETNUMDEVS = 2049;
	public const uint32 JDD_GETDEVCAPS = 2050;
	public const uint32 JDD_GETPOS = 2305;
	public const uint32 JDD_SETCALIBRATION = 2306;
	public const uint32 JDD_CONFIGCHANGED = 2307;
	public const uint32 JDD_GETPOSEX = 2308;
	public const uint32 MCI_OPEN_DRIVER = 2049;
	public const uint32 MCI_CLOSE_DRIVER = 2050;
	public const uint32 MCI_FALSE = 531;
	public const uint32 MCI_TRUE = 532;
	public const uint32 MCI_FORMAT_MILLISECONDS_S = 533;
	public const uint32 MCI_FORMAT_HMS_S = 534;
	public const uint32 MCI_FORMAT_MSF_S = 535;
	public const uint32 MCI_FORMAT_FRAMES_S = 536;
	public const uint32 MCI_FORMAT_SMPTE_24_S = 537;
	public const uint32 MCI_FORMAT_SMPTE_25_S = 538;
	public const uint32 MCI_FORMAT_SMPTE_30_S = 539;
	public const uint32 MCI_FORMAT_SMPTE_30DROP_S = 540;
	public const uint32 MCI_FORMAT_BYTES_S = 541;
	public const uint32 MCI_FORMAT_SAMPLES_S = 542;
	public const uint32 MCI_FORMAT_TMSF_S = 543;
	public const uint32 MCI_VD_FORMAT_TRACK_S = 1029;
	public const uint32 WAVE_FORMAT_PCM_S = 1152;
	public const uint32 WAVE_MAPPER_S = 1153;
	public const uint32 MCI_SEQ_MAPPER_S = 1221;
	public const uint32 MCI_SEQ_FILE_S = 1222;
	public const uint32 MCI_SEQ_MIDI_S = 1223;
	public const uint32 MCI_SEQ_SMPTE_S = 1224;
	public const uint32 MCI_SEQ_FORMAT_SONGPTR_S = 1225;
	public const uint32 MCI_SEQ_NONE_S = 1226;
	public const uint32 MIDIMAPPER_S = 1227;
	public const uint32 MCI_MAX_DEVICE_TYPE_LENGTH = 80;
	public const uint32 MCI_RESOURCE_RETURNED = 65536;
	public const uint32 MCI_COLONIZED3_RETURN = 131072;
	public const uint32 MCI_COLONIZED4_RETURN = 262144;
	public const uint32 MCI_INTEGER_RETURNED = 524288;
	public const uint32 MCI_RESOURCE_DRIVER = 1048576;
	public const uint32 MCI_COMMAND_HEAD = 0;
	public const uint32 MCI_STRING = 1;
	public const uint32 MCI_INTEGER = 2;
	public const uint32 MCI_END_COMMAND = 3;
	public const uint32 MCI_RETURN = 4;
	public const uint32 MCI_FLAG = 5;
	public const uint32 MCI_END_COMMAND_LIST = 6;
	public const uint32 MCI_RECT = 7;
	public const uint32 MCI_CONSTANT = 8;
	public const uint32 MCI_END_CONSTANT = 9;
	public const uint32 MCI_HWND = 10;
	public const uint32 MCI_HPAL = 11;
	public const uint32 MCI_HDC = 12;
	public const uint32 MCI_INTEGER64 = 13;
	public const uint32 TASKERR_NOTASKSUPPORT = 1;
	public const uint32 TASKERR_OUTOFMEMORY = 2;
	public const uint32 DRV_EXITSESSION = 11;
	public const uint32 DRV_POWER = 15;
	public const uint32 DRVCNF_CANCEL = 0;
	public const uint32 DRVCNF_OK = 1;
	public const uint32 DRVCNF_RESTART = 2;
	public const uint32 DRV_CANCEL = 0;
	public const uint32 DRV_OK = 1;
	public const uint32 DRV_RESTART = 2;
	public const uint32 DRV_MCI_LAST = 6143;
	public const uint32 MMIOERR_BASE = 256;
	public const uint32 MMIOERR_FILENOTFOUND = 257;
	public const uint32 MMIOERR_OUTOFMEMORY = 258;
	public const uint32 MMIOERR_CANNOTOPEN = 259;
	public const uint32 MMIOERR_CANNOTCLOSE = 260;
	public const uint32 MMIOERR_CANNOTREAD = 261;
	public const uint32 MMIOERR_CANNOTWRITE = 262;
	public const uint32 MMIOERR_CANNOTSEEK = 263;
	public const uint32 MMIOERR_CANNOTEXPAND = 264;
	public const uint32 MMIOERR_CHUNKNOTFOUND = 265;
	public const uint32 MMIOERR_UNBUFFERED = 266;
	public const uint32 MMIOERR_PATHNOTFOUND = 267;
	public const uint32 MMIOERR_ACCESSDENIED = 268;
	public const uint32 MMIOERR_SHARINGVIOLATION = 269;
	public const uint32 MMIOERR_NETWORKERROR = 270;
	public const uint32 MMIOERR_TOOMANYOPENFILES = 271;
	public const uint32 MMIOERR_INVALIDFILE = 272;
	public const uint32 MMIO_RWMODE = 3;
	public const uint32 MMIO_SHAREMODE = 112;
	public const uint32 MMIO_CREATE = 4096;
	public const uint32 MMIO_PARSE = 256;
	public const uint32 MMIO_DELETE = 512;
	public const uint32 MMIO_EXIST = 16384;
	public const uint32 MMIO_ALLOCBUF = 65536;
	public const uint32 MMIO_GETTEMP = 131072;
	public const uint32 MMIO_DIRTY = 268435456;
	public const uint32 MMIO_READ = 0;
	public const uint32 MMIO_WRITE = 1;
	public const uint32 MMIO_READWRITE = 2;
	public const uint32 MMIO_COMPAT = 0;
	public const uint32 MMIO_EXCLUSIVE = 16;
	public const uint32 MMIO_DENYWRITE = 32;
	public const uint32 MMIO_DENYREAD = 48;
	public const uint32 MMIO_DENYNONE = 64;
	public const uint32 MMIO_FHOPEN = 16;
	public const uint32 MMIO_EMPTYBUF = 16;
	public const uint32 MMIO_TOUPPER = 16;
	public const uint32 MMIO_INSTALLPROC = 65536;
	public const uint32 MMIO_GLOBALPROC = 268435456;
	public const uint32 MMIO_REMOVEPROC = 131072;
	public const uint32 MMIO_UNICODEPROC = 16777216;
	public const uint32 MMIO_FINDPROC = 262144;
	public const uint32 MMIO_FINDCHUNK = 16;
	public const uint32 MMIO_FINDRIFF = 32;
	public const uint32 MMIO_FINDLIST = 64;
	public const uint32 MMIO_CREATERIFF = 32;
	public const uint32 MMIO_CREATELIST = 64;
	public const uint32 MMIOM_READ = 0;
	public const uint32 MMIOM_WRITE = 1;
	public const uint32 MMIOM_SEEK = 2;
	public const uint32 MMIOM_OPEN = 3;
	public const uint32 MMIOM_CLOSE = 4;
	public const uint32 MMIOM_WRITEFLUSH = 5;
	public const uint32 MMIOM_RENAME = 6;
	public const uint32 MMIOM_USER = 32768;
	public const uint32 SEEK_SET = 0;
	public const uint32 SEEK_CUR = 1;
	public const uint32 SEEK_END = 2;
	public const uint32 MMIO_DEFAULTBUFFER = 8192;
	public const uint32 FACILITY_NS = 13;
	public const int32 MCI_MCIAVI_PLAY_WINDOW = 16777216;
	public const int32 MCI_MCIAVI_PLAY_FULLSCREEN = 33554432;
	public const int32 MCI_MCIAVI_PLAY_FULLBY2 = 67108864;
	public const int32 MCI_AVI_STATUS_FRAMES_SKIPPED = 32769;
	public const int32 MCI_AVI_STATUS_LAST_PLAY_SPEED = 32770;
	public const int32 MCI_AVI_STATUS_AUDIO_BREAKS = 32771;
	public const int32 MCI_AVI_SETVIDEO_DRAW_PROCEDURE = 32768;
	public const int32 MCI_AVI_SETVIDEO_PALETTE_COLOR = 33024;
	public const int32 MCI_AVI_SETVIDEO_PALETTE_HALFTONE = 65535;
	public const uint32 MCIERR_AVI_OLDAVIFORMAT = 612;
	public const uint32 MCIERR_AVI_NOTINTERLEAVED = 613;
	public const uint32 MCIERR_AVI_NODISPDIB = 614;
	public const uint32 MCIERR_AVI_CANTPLAYFULLSCREEN = 615;
	public const uint32 MCIERR_AVI_TOOBIGFORVGA = 616;
	public const uint32 MCIERR_AVI_NOCOMPRESSOR = 617;
	public const uint32 MCIERR_AVI_DISPLAYERROR = 618;
	public const uint32 MCIERR_AVI_AUDIOERROR = 619;
	public const uint32 MCIERR_AVI_BADPALETTE = 620;
	public const uint32 DLG_ACMFORMATCHOOSE_ID = 70;
	public const uint32 IDD_ACMFORMATCHOOSE_BTN_HELP = 9;
	public const uint32 IDD_ACMFORMATCHOOSE_CMB_CUSTOM = 100;
	public const uint32 IDD_ACMFORMATCHOOSE_CMB_FORMATTAG = 101;
	public const uint32 IDD_ACMFORMATCHOOSE_CMB_FORMAT = 102;
	public const uint32 IDD_ACMFORMATCHOOSE_BTN_SETNAME = 103;
	public const uint32 IDD_ACMFORMATCHOOSE_BTN_DELNAME = 104;
	public const uint32 DLG_ACMFILTERCHOOSE_ID = 71;
	public const uint32 IDD_ACMFILTERCHOOSE_BTN_HELP = 9;
	public const uint32 IDD_ACMFILTERCHOOSE_CMB_CUSTOM = 100;
	public const uint32 IDD_ACMFILTERCHOOSE_CMB_FILTERTAG = 101;
	public const uint32 IDD_ACMFILTERCHOOSE_CMB_FILTER = 102;
	public const uint32 IDD_ACMFILTERCHOOSE_BTN_SETNAME = 103;
	public const uint32 IDD_ACMFILTERCHOOSE_BTN_DELNAME = 104;
	public const uint32 FACILITY_NS_WIN32 = 7;
	public const HRESULT NS_S_CALLPENDING = 851968;
	public const HRESULT NS_S_CALLABORTED = 851969;
	public const HRESULT NS_S_STREAM_TRUNCATED = 851970;
	public const HRESULT NS_W_SERVER_BANDWIDTH_LIMIT = -2146631677;
	public const HRESULT NS_W_FILE_BANDWIDTH_LIMIT = -2146631676;
	public const HRESULT NS_E_NOCONNECTION = -1072889851;
	public const HRESULT NS_E_CANNOTCONNECT = -1072889850;
	public const HRESULT NS_E_CANNOTDESTROYTITLE = -1072889849;
	public const HRESULT NS_E_CANNOTRENAMETITLE = -1072889848;
	public const HRESULT NS_E_CANNOTOFFLINEDISK = -1072889847;
	public const HRESULT NS_E_CANNOTONLINEDISK = -1072889846;
	public const HRESULT NS_E_NOREGISTEREDWALKER = -1072889845;
	public const HRESULT NS_E_NOFUNNEL = -1072889844;
	public const HRESULT NS_E_NO_LOCALPLAY = -1072889843;
	public const HRESULT NS_E_NETWORK_BUSY = -1072889842;
	public const HRESULT NS_E_TOO_MANY_SESS = -1072889841;
	public const HRESULT NS_E_ALREADY_CONNECTED = -1072889840;
	public const HRESULT NS_E_INVALID_INDEX = -1072889839;
	public const HRESULT NS_E_PROTOCOL_MISMATCH = -1072889838;
	public const HRESULT NS_E_TIMEOUT = -1072889837;
	public const HRESULT NS_E_NET_WRITE = -1072889836;
	public const HRESULT NS_E_NET_READ = -1072889835;
	public const HRESULT NS_E_DISK_WRITE = -1072889834;
	public const HRESULT NS_E_DISK_READ = -1072889833;
	public const HRESULT NS_E_FILE_WRITE = -1072889832;
	public const HRESULT NS_E_FILE_READ = -1072889831;
	public const HRESULT NS_E_FILE_NOT_FOUND = -1072889830;
	public const HRESULT NS_E_FILE_EXISTS = -1072889829;
	public const HRESULT NS_E_INVALID_NAME = -1072889828;
	public const HRESULT NS_E_FILE_OPEN_FAILED = -1072889827;
	public const HRESULT NS_E_FILE_ALLOCATION_FAILED = -1072889826;
	public const HRESULT NS_E_FILE_INIT_FAILED = -1072889825;
	public const HRESULT NS_E_FILE_PLAY_FAILED = -1072889824;
	public const HRESULT NS_E_SET_DISK_UID_FAILED = -1072889823;
	public const HRESULT NS_E_INDUCED = -1072889822;
	public const HRESULT NS_E_CCLINK_DOWN = -1072889821;
	public const HRESULT NS_E_INTERNAL = -1072889820;
	public const HRESULT NS_E_BUSY = -1072889819;
	public const HRESULT NS_E_UNRECOGNIZED_STREAM_TYPE = -1072889818;
	public const HRESULT NS_E_NETWORK_SERVICE_FAILURE = -1072889817;
	public const HRESULT NS_E_NETWORK_RESOURCE_FAILURE = -1072889816;
	public const HRESULT NS_E_CONNECTION_FAILURE = -1072889815;
	public const HRESULT NS_E_SHUTDOWN = -1072889814;
	public const HRESULT NS_E_INVALID_REQUEST = -1072889813;
	public const HRESULT NS_E_INSUFFICIENT_BANDWIDTH = -1072889812;
	public const HRESULT NS_E_NOT_REBUILDING = -1072889811;
	public const HRESULT NS_E_LATE_OPERATION = -1072889810;
	public const HRESULT NS_E_INVALID_DATA = -1072889809;
	public const HRESULT NS_E_FILE_BANDWIDTH_LIMIT = -1072889808;
	public const HRESULT NS_E_OPEN_FILE_LIMIT = -1072889807;
	public const HRESULT NS_E_BAD_CONTROL_DATA = -1072889806;
	public const HRESULT NS_E_NO_STREAM = -1072889805;
	public const HRESULT NS_E_STREAM_END = -1072889804;
	public const HRESULT NS_E_SERVER_NOT_FOUND = -1072889803;
	public const HRESULT NS_E_DUPLICATE_NAME = -1072889802;
	public const HRESULT NS_E_DUPLICATE_ADDRESS = -1072889801;
	public const HRESULT NS_E_BAD_MULTICAST_ADDRESS = -1072889800;
	public const HRESULT NS_E_BAD_ADAPTER_ADDRESS = -1072889799;
	public const HRESULT NS_E_BAD_DELIVERY_MODE = -1072889798;
	public const HRESULT NS_E_INVALID_CHANNEL = -1072889797;
	public const HRESULT NS_E_INVALID_STREAM = -1072889796;
	public const HRESULT NS_E_INVALID_ARCHIVE = -1072889795;
	public const HRESULT NS_E_NOTITLES = -1072889794;
	public const HRESULT NS_E_INVALID_CLIENT = -1072889793;
	public const HRESULT NS_E_INVALID_BLACKHOLE_ADDRESS = -1072889792;
	public const HRESULT NS_E_INCOMPATIBLE_FORMAT = -1072889791;
	public const HRESULT NS_E_INVALID_KEY = -1072889790;
	public const HRESULT NS_E_INVALID_PORT = -1072889789;
	public const HRESULT NS_E_INVALID_TTL = -1072889788;
	public const HRESULT NS_E_STRIDE_REFUSED = -1072889787;
	public const HRESULT NS_E_MMSAUTOSERVER_CANTFINDWALKER = -1072889786;
	public const HRESULT NS_E_MAX_BITRATE = -1072889785;
	public const HRESULT NS_E_LOGFILEPERIOD = -1072889784;
	public const HRESULT NS_E_MAX_CLIENTS = -1072889783;
	public const HRESULT NS_E_LOG_FILE_SIZE = -1072889782;
	public const HRESULT NS_E_MAX_FILERATE = -1072889781;
	public const HRESULT NS_E_WALKER_UNKNOWN = -1072889780;
	public const HRESULT NS_E_WALKER_SERVER = -1072889779;
	public const HRESULT NS_E_WALKER_USAGE = -1072889778;
	public const HRESULT NS_I_TIGER_START = 1074593871;
	public const HRESULT NS_E_TIGER_FAIL = -1072889776;
	public const HRESULT NS_I_CUB_START = 1074593873;
	public const HRESULT NS_I_CUB_RUNNING = 1074593874;
	public const HRESULT NS_E_CUB_FAIL = -1072889773;
	public const HRESULT NS_I_DISK_START = 1074593876;
	public const HRESULT NS_E_DISK_FAIL = -1072889771;
	public const HRESULT NS_I_DISK_REBUILD_STARTED = 1074593878;
	public const HRESULT NS_I_DISK_REBUILD_FINISHED = 1074593879;
	public const HRESULT NS_I_DISK_REBUILD_ABORTED = 1074593880;
	public const HRESULT NS_I_LIMIT_FUNNELS = 1074593881;
	public const HRESULT NS_I_START_DISK = 1074593882;
	public const HRESULT NS_I_STOP_DISK = 1074593883;
	public const HRESULT NS_I_STOP_CUB = 1074593884;
	public const HRESULT NS_I_KILL_USERSESSION = 1074593885;
	public const HRESULT NS_I_KILL_CONNECTION = 1074593886;
	public const HRESULT NS_I_REBUILD_DISK = 1074593887;
	public const HRESULT NS_W_UNKNOWN_EVENT = -2146631584;
	public const HRESULT NS_E_MAX_FUNNELS_ALERT = -1072889760;
	public const HRESULT NS_E_ALLOCATE_FILE_FAIL = -1072889759;
	public const HRESULT NS_E_PAGING_ERROR = -1072889758;
	public const HRESULT NS_E_BAD_BLOCK0_VERSION = -1072889757;
	public const HRESULT NS_E_BAD_DISK_UID = -1072889756;
	public const HRESULT NS_E_BAD_FSMAJOR_VERSION = -1072889755;
	public const HRESULT NS_E_BAD_STAMPNUMBER = -1072889754;
	public const HRESULT NS_E_PARTIALLY_REBUILT_DISK = -1072889753;
	public const HRESULT NS_E_ENACTPLAN_GIVEUP = -1072889752;
	public const HRESULT MCMADM_I_NO_EVENTS = 1074593897;
	public const HRESULT MCMADM_E_REGKEY_NOT_FOUND = -1072889750;
	public const HRESULT NS_E_NO_FORMATS = -1072889749;
	public const HRESULT NS_E_NO_REFERENCES = -1072889748;
	public const HRESULT NS_E_WAVE_OPEN = -1072889747;
	public const HRESULT NS_I_LOGGING_FAILED = 1074593902;
	public const HRESULT NS_E_CANNOTCONNECTEVENTS = -1072889745;
	public const HRESULT NS_I_LIMIT_BANDWIDTH = 1074593904;
	public const HRESULT NS_E_NO_DEVICE = -1072889743;
	public const HRESULT NS_E_NO_SPECIFIED_DEVICE = -1072889742;
	public const HRESULT NS_E_NOTHING_TO_DO = -1072887823;
	public const HRESULT NS_E_NO_MULTICAST = -1072887822;
	public const HRESULT NS_E_MONITOR_GIVEUP = -1072889656;
	public const HRESULT NS_E_REMIRRORED_DISK = -1072889655;
	public const HRESULT NS_E_INSUFFICIENT_DATA = -1072889654;
	public const HRESULT NS_E_ASSERT = -1072889653;
	public const HRESULT NS_E_BAD_ADAPTER_NAME = -1072889652;
	public const HRESULT NS_E_NOT_LICENSED = -1072889651;
	public const HRESULT NS_E_NO_SERVER_CONTACT = -1072889650;
	public const HRESULT NS_E_TOO_MANY_TITLES = -1072889649;
	public const HRESULT NS_E_TITLE_SIZE_EXCEEDED = -1072889648;
	public const HRESULT NS_E_UDP_DISABLED = -1072889647;
	public const HRESULT NS_E_TCP_DISABLED = -1072889646;
	public const HRESULT NS_E_HTTP_DISABLED = -1072889645;
	public const HRESULT NS_E_LICENSE_EXPIRED = -1072889644;
	public const HRESULT NS_E_TITLE_BITRATE = -1072889643;
	public const HRESULT NS_E_EMPTY_PROGRAM_NAME = -1072889642;
	public const HRESULT NS_E_MISSING_CHANNEL = -1072889641;
	public const HRESULT NS_E_NO_CHANNELS = -1072889640;
	public const HRESULT NS_E_INVALID_INDEX2 = -1072889639;
	public const HRESULT NS_E_CUB_FAIL_LINK = -1072889456;
	public const HRESULT NS_I_CUB_UNFAIL_LINK = 1074594193;
	public const HRESULT NS_E_BAD_CUB_UID = -1072889454;
	public const HRESULT NS_I_RESTRIPE_START = 1074594195;
	public const HRESULT NS_I_RESTRIPE_DONE = 1074594196;
	public const HRESULT NS_E_GLITCH_MODE = -1072889451;
	public const HRESULT NS_I_RESTRIPE_DISK_OUT = 1074594198;
	public const HRESULT NS_I_RESTRIPE_CUB_OUT = 1074594199;
	public const HRESULT NS_I_DISK_STOP = 1074594200;
	public const HRESULT NS_I_CATATONIC_FAILURE = -2146631271;
	public const HRESULT NS_I_CATATONIC_AUTO_UNFAIL = -2146631270;
	public const HRESULT NS_E_NO_MEDIA_PROTOCOL = -1072889445;
	public const HRESULT NS_E_INVALID_INPUT_FORMAT = -1072886856;
	public const HRESULT NS_E_MSAUDIO_NOT_INSTALLED = -1072886855;
	public const HRESULT NS_E_UNEXPECTED_MSAUDIO_ERROR = -1072886854;
	public const HRESULT NS_E_INVALID_OUTPUT_FORMAT = -1072886853;
	public const HRESULT NS_E_NOT_CONFIGURED = -1072886852;
	public const HRESULT NS_E_PROTECTED_CONTENT = -1072886851;
	public const HRESULT NS_E_LICENSE_REQUIRED = -1072886850;
	public const HRESULT NS_E_TAMPERED_CONTENT = -1072886849;
	public const HRESULT NS_E_LICENSE_OUTOFDATE = -1072886848;
	public const HRESULT NS_E_LICENSE_INCORRECT_RIGHTS = -1072886847;
	public const HRESULT NS_E_AUDIO_CODEC_NOT_INSTALLED = -1072886846;
	public const HRESULT NS_E_AUDIO_CODEC_ERROR = -1072886845;
	public const HRESULT NS_E_VIDEO_CODEC_NOT_INSTALLED = -1072886844;
	public const HRESULT NS_E_VIDEO_CODEC_ERROR = -1072886843;
	public const HRESULT NS_E_INVALIDPROFILE = -1072886842;
	public const HRESULT NS_E_INCOMPATIBLE_VERSION = -1072886841;
	public const HRESULT NS_S_REBUFFERING = 854984;
	public const HRESULT NS_S_DEGRADING_QUALITY = 854985;
	public const HRESULT NS_E_OFFLINE_MODE = -1072886838;
	public const HRESULT NS_E_NOT_CONNECTED = -1072886837;
	public const HRESULT NS_E_TOO_MUCH_DATA = -1072886836;
	public const HRESULT NS_E_UNSUPPORTED_PROPERTY = -1072886835;
	public const HRESULT NS_E_8BIT_WAVE_UNSUPPORTED = -1072886834;
	public const HRESULT NS_E_NO_MORE_SAMPLES = -1072886833;
	public const HRESULT NS_E_INVALID_SAMPLING_RATE = -1072886832;
	public const HRESULT NS_E_MAX_PACKET_SIZE_TOO_SMALL = -1072886831;
	public const HRESULT NS_E_LATE_PACKET = -1072886830;
	public const HRESULT NS_E_DUPLICATE_PACKET = -1072886829;
	public const HRESULT NS_E_SDK_BUFFERTOOSMALL = -1072886828;
	public const HRESULT NS_E_INVALID_NUM_PASSES = -1072886827;
	public const HRESULT NS_E_ATTRIBUTE_READ_ONLY = -1072886826;
	public const HRESULT NS_E_ATTRIBUTE_NOT_ALLOWED = -1072886825;
	public const HRESULT NS_E_INVALID_EDL = -1072886824;
	public const HRESULT NS_E_DATA_UNIT_EXTENSION_TOO_LARGE = -1072886823;
	public const HRESULT NS_E_CODEC_DMO_ERROR = -1072886822;
	public const HRESULT NS_S_TRANSCRYPTOR_EOF = 855003;
	public const HRESULT NS_E_FEATURE_DISABLED_BY_GROUP_POLICY = -1072886820;
	public const HRESULT NS_E_FEATURE_DISABLED_IN_SKU = -1072886819;
	public const HRESULT NS_E_WMDRM_DEPRECATED = -1072886818;
	public const HRESULT NS_E_NO_CD = -1072885856;
	public const HRESULT NS_E_CANT_READ_DIGITAL = -1072885855;
	public const HRESULT NS_E_DEVICE_DISCONNECTED = -1072885854;
	public const HRESULT NS_E_DEVICE_NOT_SUPPORT_FORMAT = -1072885853;
	public const HRESULT NS_E_SLOW_READ_DIGITAL = -1072885852;
	public const HRESULT NS_E_MIXER_INVALID_LINE = -1072885851;
	public const HRESULT NS_E_MIXER_INVALID_CONTROL = -1072885850;
	public const HRESULT NS_E_MIXER_INVALID_VALUE = -1072885849;
	public const HRESULT NS_E_MIXER_UNKNOWN_MMRESULT = -1072885848;
	public const HRESULT NS_E_USER_STOP = -1072885847;
	public const HRESULT NS_E_MP3_FORMAT_NOT_FOUND = -1072885846;
	public const HRESULT NS_E_CD_READ_ERROR_NO_CORRECTION = -1072885845;
	public const HRESULT NS_E_CD_READ_ERROR = -1072885844;
	public const HRESULT NS_E_CD_SLOW_COPY = -1072885843;
	public const HRESULT NS_E_CD_COPYTO_CD = -1072885842;
	public const HRESULT NS_E_MIXER_NODRIVER = -1072885841;
	public const HRESULT NS_E_REDBOOK_ENABLED_WHILE_COPYING = -1072885840;
	public const HRESULT NS_E_CD_REFRESH = -1072885839;
	public const HRESULT NS_E_CD_DRIVER_PROBLEM = -1072885838;
	public const HRESULT NS_E_WONT_DO_DIGITAL = -1072885837;
	public const HRESULT NS_E_WMPXML_NOERROR = -1072885836;
	public const HRESULT NS_E_WMPXML_ENDOFDATA = -1072885835;
	public const HRESULT NS_E_WMPXML_PARSEERROR = -1072885834;
	public const HRESULT NS_E_WMPXML_ATTRIBUTENOTFOUND = -1072885833;
	public const HRESULT NS_E_WMPXML_PINOTFOUND = -1072885832;
	public const HRESULT NS_E_WMPXML_EMPTYDOC = -1072885831;
	public const HRESULT NS_E_WMP_PATH_ALREADY_IN_LIBRARY = -1072885830;
	public const HRESULT NS_E_WMP_FILESCANALREADYSTARTED = -1072885826;
	public const HRESULT NS_E_WMP_HME_INVALIDOBJECTID = -1072885825;
	public const HRESULT NS_E_WMP_MF_CODE_EXPIRED = -1072885824;
	public const HRESULT NS_E_WMP_HME_NOTSEARCHABLEFORITEMS = -1072885823;
	public const HRESULT NS_E_WMP_HME_STALEREQUEST = -1072885822;
	public const HRESULT NS_E_WMP_ADDTOLIBRARY_FAILED = -1072885817;
	public const HRESULT NS_E_WMP_WINDOWSAPIFAILURE = -1072885816;
	public const HRESULT NS_E_WMP_RECORDING_NOT_ALLOWED = -1072885815;
	public const HRESULT NS_E_DEVICE_NOT_READY = -1072885814;
	public const HRESULT NS_E_DAMAGED_FILE = -1072885813;
	public const HRESULT NS_E_MPDB_GENERIC = -1072885812;
	public const HRESULT NS_E_FILE_FAILED_CHECKS = -1072885811;
	public const HRESULT NS_E_MEDIA_LIBRARY_FAILED = -1072885810;
	public const HRESULT NS_E_SHARING_VIOLATION = -1072885809;
	public const HRESULT NS_E_NO_ERROR_STRING_FOUND = -1072885808;
	public const HRESULT NS_E_WMPOCX_NO_REMOTE_CORE = -1072885807;
	public const HRESULT NS_E_WMPOCX_NO_ACTIVE_CORE = -1072885806;
	public const HRESULT NS_E_WMPOCX_NOT_RUNNING_REMOTELY = -1072885805;
	public const HRESULT NS_E_WMPOCX_NO_REMOTE_WINDOW = -1072885804;
	public const HRESULT NS_E_WMPOCX_ERRORMANAGERNOTAVAILABLE = -1072885803;
	public const HRESULT NS_E_PLUGIN_NOTSHUTDOWN = -1072885802;
	public const HRESULT NS_E_WMP_CANNOT_FIND_FOLDER = -1072885801;
	public const HRESULT NS_E_WMP_STREAMING_RECORDING_NOT_ALLOWED = -1072885800;
	public const HRESULT NS_E_WMP_PLUGINDLL_NOTFOUND = -1072885799;
	public const HRESULT NS_E_NEED_TO_ASK_USER = -1072885798;
	public const HRESULT NS_E_WMPOCX_PLAYER_NOT_DOCKED = -1072885797;
	public const HRESULT NS_E_WMP_EXTERNAL_NOTREADY = -1072885796;
	public const HRESULT NS_E_WMP_MLS_STALE_DATA = -1072885795;
	public const HRESULT NS_E_WMP_UI_SUBCONTROLSNOTSUPPORTED = -1072885794;
	public const HRESULT NS_E_WMP_UI_VERSIONMISMATCH = -1072885793;
	public const HRESULT NS_E_WMP_UI_NOTATHEMEFILE = -1072885792;
	public const HRESULT NS_E_WMP_UI_SUBELEMENTNOTFOUND = -1072885791;
	public const HRESULT NS_E_WMP_UI_VERSIONPARSE = -1072885790;
	public const HRESULT NS_E_WMP_UI_VIEWIDNOTFOUND = -1072885789;
	public const HRESULT NS_E_WMP_UI_PASSTHROUGH = -1072885788;
	public const HRESULT NS_E_WMP_UI_OBJECTNOTFOUND = -1072885787;
	public const HRESULT NS_E_WMP_UI_SECONDHANDLER = -1072885786;
	public const HRESULT NS_E_WMP_UI_NOSKININZIP = -1072885785;
	public const HRESULT NS_S_WMP_UI_VERSIONMISMATCH = 856040;
	public const HRESULT NS_S_WMP_EXCEPTION = 856041;
	public const HRESULT NS_E_WMP_URLDOWNLOADFAILED = -1072885782;
	public const HRESULT NS_E_WMPOCX_UNABLE_TO_LOAD_SKIN = -1072885781;
	public const HRESULT NS_E_WMP_INVALID_SKIN = -1072885780;
	public const HRESULT NS_E_WMP_SENDMAILFAILED = -1072885779;
	public const HRESULT NS_E_WMP_LOCKEDINSKINMODE = -1072885778;
	public const HRESULT NS_E_WMP_FAILED_TO_SAVE_FILE = -1072885777;
	public const HRESULT NS_E_WMP_SAVEAS_READONLY = -1072885776;
	public const HRESULT NS_E_WMP_FAILED_TO_SAVE_PLAYLIST = -1072885775;
	public const HRESULT NS_E_WMP_FAILED_TO_OPEN_WMD = -1072885774;
	public const HRESULT NS_E_WMP_CANT_PLAY_PROTECTED = -1072885773;
	public const HRESULT NS_E_SHARING_STATE_OUT_OF_SYNC = -1072885772;
	public const HRESULT NS_E_WMPOCX_REMOTE_PLAYER_ALREADY_RUNNING = -1072885766;
	public const HRESULT NS_E_WMP_RBC_JPGMAPPINGIMAGE = -1072885756;
	public const HRESULT NS_E_WMP_JPGTRANSPARENCY = -1072885755;
	public const HRESULT NS_E_WMP_INVALID_MAX_VAL = -1072885751;
	public const HRESULT NS_E_WMP_INVALID_MIN_VAL = -1072885750;
	public const HRESULT NS_E_WMP_CS_JPGPOSITIONIMAGE = -1072885746;
	public const HRESULT NS_E_WMP_CS_NOTEVENLYDIVISIBLE = -1072885745;
	public const HRESULT NS_E_WMPZIP_NOTAZIPFILE = -1072885736;
	public const HRESULT NS_E_WMPZIP_CORRUPT = -1072885735;
	public const HRESULT NS_E_WMPZIP_FILENOTFOUND = -1072885734;
	public const HRESULT NS_E_WMP_IMAGE_FILETYPE_UNSUPPORTED = -1072885726;
	public const HRESULT NS_E_WMP_IMAGE_INVALID_FORMAT = -1072885725;
	public const HRESULT NS_E_WMP_GIF_UNEXPECTED_ENDOFFILE = -1072885724;
	public const HRESULT NS_E_WMP_GIF_INVALID_FORMAT = -1072885723;
	public const HRESULT NS_E_WMP_GIF_BAD_VERSION_NUMBER = -1072885722;
	public const HRESULT NS_E_WMP_GIF_NO_IMAGE_IN_FILE = -1072885721;
	public const HRESULT NS_E_WMP_PNG_INVALIDFORMAT = -1072885720;
	public const HRESULT NS_E_WMP_PNG_UNSUPPORTED_BITDEPTH = -1072885719;
	public const HRESULT NS_E_WMP_PNG_UNSUPPORTED_COMPRESSION = -1072885718;
	public const HRESULT NS_E_WMP_PNG_UNSUPPORTED_FILTER = -1072885717;
	public const HRESULT NS_E_WMP_PNG_UNSUPPORTED_INTERLACE = -1072885716;
	public const HRESULT NS_E_WMP_PNG_UNSUPPORTED_BAD_CRC = -1072885715;
	public const HRESULT NS_E_WMP_BMP_INVALID_BITMASK = -1072885714;
	public const HRESULT NS_E_WMP_BMP_TOPDOWN_DIB_UNSUPPORTED = -1072885713;
	public const HRESULT NS_E_WMP_BMP_BITMAP_NOT_CREATED = -1072885712;
	public const HRESULT NS_E_WMP_BMP_COMPRESSION_UNSUPPORTED = -1072885711;
	public const HRESULT NS_E_WMP_BMP_INVALID_FORMAT = -1072885710;
	public const HRESULT NS_E_WMP_JPG_JERR_ARITHCODING_NOTIMPL = -1072885709;
	public const HRESULT NS_E_WMP_JPG_INVALID_FORMAT = -1072885708;
	public const HRESULT NS_E_WMP_JPG_BAD_DCTSIZE = -1072885707;
	public const HRESULT NS_E_WMP_JPG_BAD_VERSION_NUMBER = -1072885706;
	public const HRESULT NS_E_WMP_JPG_BAD_PRECISION = -1072885705;
	public const HRESULT NS_E_WMP_JPG_CCIR601_NOTIMPL = -1072885704;
	public const HRESULT NS_E_WMP_JPG_NO_IMAGE_IN_FILE = -1072885703;
	public const HRESULT NS_E_WMP_JPG_READ_ERROR = -1072885702;
	public const HRESULT NS_E_WMP_JPG_FRACT_SAMPLE_NOTIMPL = -1072885701;
	public const HRESULT NS_E_WMP_JPG_IMAGE_TOO_BIG = -1072885700;
	public const HRESULT NS_E_WMP_JPG_UNEXPECTED_ENDOFFILE = -1072885699;
	public const HRESULT NS_E_WMP_JPG_SOF_UNSUPPORTED = -1072885698;
	public const HRESULT NS_E_WMP_JPG_UNKNOWN_MARKER = -1072885697;
	public const HRESULT NS_S_WMP_LOADED_GIF_IMAGE = 856128;
	public const HRESULT NS_S_WMP_LOADED_PNG_IMAGE = 856129;
	public const HRESULT NS_S_WMP_LOADED_BMP_IMAGE = 856130;
	public const HRESULT NS_S_WMP_LOADED_JPG_IMAGE = 856131;
	public const HRESULT NS_E_WMP_FAILED_TO_OPEN_IMAGE = -1072885692;
	public const HRESULT NS_E_WMP_DAI_SONGTOOSHORT = -1072885687;
	public const HRESULT NS_E_WMG_RATEUNAVAILABLE = -1072885686;
	public const HRESULT NS_E_WMG_PLUGINUNAVAILABLE = -1072885685;
	public const HRESULT NS_E_WMG_CANNOTQUEUE = -1072885684;
	public const HRESULT NS_E_WMG_PREROLLLICENSEACQUISITIONNOTALLOWED = -1072885683;
	public const HRESULT NS_E_WMG_UNEXPECTEDPREROLLSTATUS = -1072885682;
	public const HRESULT NS_S_WMG_FORCE_DROP_FRAME = 856143;
	public const HRESULT NS_E_WMG_INVALID_COPP_CERTIFICATE = -1072885679;
	public const HRESULT NS_E_WMG_COPP_SECURITY_INVALID = -1072885678;
	public const HRESULT NS_E_WMG_COPP_UNSUPPORTED = -1072885677;
	public const HRESULT NS_E_WMG_INVALIDSTATE = -1072885676;
	public const HRESULT NS_E_WMG_SINKALREADYEXISTS = -1072885675;
	public const HRESULT NS_E_WMG_NOSDKINTERFACE = -1072885674;
	public const HRESULT NS_E_WMG_NOTALLOUTPUTSRENDERED = -1072885673;
	public const HRESULT NS_E_WMG_FILETRANSFERNOTALLOWED = -1072885672;
	public const HRESULT NS_E_WMR_UNSUPPORTEDSTREAM = -1072885671;
	public const HRESULT NS_E_WMR_PINNOTFOUND = -1072885670;
	public const HRESULT NS_E_WMR_WAITINGONFORMATSWITCH = -1072885669;
	public const HRESULT NS_E_WMR_NOSOURCEFILTER = -1072885668;
	public const HRESULT NS_E_WMR_PINTYPENOMATCH = -1072885667;
	public const HRESULT NS_E_WMR_NOCALLBACKAVAILABLE = -1072885666;
	public const HRESULT NS_S_WMR_ALREADYRENDERED = 856159;
	public const HRESULT NS_S_WMR_PINTYPEPARTIALMATCH = 856160;
	public const HRESULT NS_S_WMR_PINTYPEFULLMATCH = 856161;
	public const HRESULT NS_E_WMR_SAMPLEPROPERTYNOTSET = -1072885662;
	public const HRESULT NS_E_WMR_CANNOT_RENDER_BINARY_STREAM = -1072885661;
	public const HRESULT NS_E_WMG_LICENSE_TAMPERED = -1072885660;
	public const HRESULT NS_E_WMR_WILLNOT_RENDER_BINARY_STREAM = -1072885659;
	public const HRESULT NS_S_WMG_ADVISE_DROP_FRAME = 856166;
	public const HRESULT NS_S_WMG_ADVISE_DROP_TO_KEYFRAME = 856167;
	public const HRESULT NS_E_WMX_UNRECOGNIZED_PLAYLIST_FORMAT = -1072885656;
	public const HRESULT NS_E_ASX_INVALIDFORMAT = -1072885655;
	public const HRESULT NS_E_ASX_INVALIDVERSION = -1072885654;
	public const HRESULT NS_E_ASX_INVALID_REPEAT_BLOCK = -1072885653;
	public const HRESULT NS_E_ASX_NOTHING_TO_WRITE = -1072885652;
	public const HRESULT NS_E_URLLIST_INVALIDFORMAT = -1072885651;
	public const HRESULT NS_E_WMX_ATTRIBUTE_DOES_NOT_EXIST = -1072885650;
	public const HRESULT NS_E_WMX_ATTRIBUTE_ALREADY_EXISTS = -1072885649;
	public const HRESULT NS_E_WMX_ATTRIBUTE_UNRETRIEVABLE = -1072885648;
	public const HRESULT NS_E_WMX_ITEM_DOES_NOT_EXIST = -1072885647;
	public const HRESULT NS_E_WMX_ITEM_TYPE_ILLEGAL = -1072885646;
	public const HRESULT NS_E_WMX_ITEM_UNSETTABLE = -1072885645;
	public const HRESULT NS_E_WMX_PLAYLIST_EMPTY = -1072885644;
	public const HRESULT NS_E_MLS_SMARTPLAYLIST_FILTER_NOT_REGISTERED = -1072885643;
	public const HRESULT NS_E_WMX_INVALID_FORMAT_OVER_NESTING = -1072885642;
	public const HRESULT NS_E_WMPCORE_NOSOURCEURLSTRING = -1072885636;
	public const HRESULT NS_E_WMPCORE_COCREATEFAILEDFORGITOBJECT = -1072885635;
	public const HRESULT NS_E_WMPCORE_FAILEDTOGETMARSHALLEDEVENTHANDLERINTERFACE = -1072885634;
	public const HRESULT NS_E_WMPCORE_BUFFERTOOSMALL = -1072885633;
	public const HRESULT NS_E_WMPCORE_UNAVAILABLE = -1072885632;
	public const HRESULT NS_E_WMPCORE_INVALIDPLAYLISTMODE = -1072885631;
	public const HRESULT NS_E_WMPCORE_ITEMNOTINPLAYLIST = -1072885626;
	public const HRESULT NS_E_WMPCORE_PLAYLISTEMPTY = -1072885625;
	public const HRESULT NS_E_WMPCORE_NOBROWSER = -1072885624;
	public const HRESULT NS_E_WMPCORE_UNRECOGNIZED_MEDIA_URL = -1072885623;
	public const HRESULT NS_E_WMPCORE_GRAPH_NOT_IN_LIST = -1072885622;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_EMPTY_OR_SINGLE_MEDIA = -1072885621;
	public const HRESULT NS_E_WMPCORE_ERRORSINKNOTREGISTERED = -1072885620;
	public const HRESULT NS_E_WMPCORE_ERRORMANAGERNOTAVAILABLE = -1072885619;
	public const HRESULT NS_E_WMPCORE_WEBHELPFAILED = -1072885618;
	public const HRESULT NS_E_WMPCORE_MEDIA_ERROR_RESUME_FAILED = -1072885617;
	public const HRESULT NS_E_WMPCORE_NO_REF_IN_ENTRY = -1072885616;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ATTRIBUTE_NAME_EMPTY = -1072885615;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ATTRIBUTE_NAME_ILLEGAL = -1072885614;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ATTRIBUTE_VALUE_EMPTY = -1072885613;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ATTRIBUTE_VALUE_ILLEGAL = -1072885612;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ITEM_ATTRIBUTE_NAME_EMPTY = -1072885611;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ITEM_ATTRIBUTE_NAME_ILLEGAL = -1072885610;
	public const HRESULT NS_E_WMPCORE_WMX_LIST_ITEM_ATTRIBUTE_VALUE_EMPTY = -1072885609;
	public const HRESULT NS_E_WMPCORE_LIST_ENTRY_NO_REF = -1072885608;
	public const HRESULT NS_E_WMPCORE_MISNAMED_FILE = -1072885607;
	public const HRESULT NS_E_WMPCORE_CODEC_NOT_TRUSTED = -1072885606;
	public const HRESULT NS_E_WMPCORE_CODEC_NOT_FOUND = -1072885605;
	public const HRESULT NS_E_WMPCORE_CODEC_DOWNLOAD_NOT_ALLOWED = -1072885604;
	public const HRESULT NS_E_WMPCORE_ERROR_DOWNLOADING_PLAYLIST = -1072885603;
	public const HRESULT NS_E_WMPCORE_FAILED_TO_BUILD_PLAYLIST = -1072885602;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_ITEM_ALTERNATE_NONE = -1072885601;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_ITEM_ALTERNATE_EXHAUSTED = -1072885600;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_ITEM_ALTERNATE_NAME_NOT_FOUND = -1072885599;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_ITEM_ALTERNATE_MORPH_FAILED = -1072885598;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_ITEM_ALTERNATE_INIT_FAILED = -1072885597;
	public const HRESULT NS_E_WMPCORE_MEDIA_ALTERNATE_REF_EMPTY = -1072885596;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_NO_EVENT_NAME = -1072885595;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_EVENT_ATTRIBUTE_ABSENT = -1072885594;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_EVENT_EMPTY = -1072885593;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_STACK_EMPTY = -1072885592;
	public const HRESULT NS_E_WMPCORE_CURRENT_MEDIA_NOT_ACTIVE = -1072885591;
	public const HRESULT NS_E_WMPCORE_USER_CANCEL = -1072885589;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_REPEAT_EMPTY = -1072885588;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_REPEAT_START_MEDIA_NONE = -1072885587;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_REPEAT_END_MEDIA_NONE = -1072885586;
	public const HRESULT NS_E_WMPCORE_INVALID_PLAYLIST_URL = -1072885585;
	public const HRESULT NS_E_WMPCORE_MISMATCHED_RUNTIME = -1072885584;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_IMPORT_FAILED_NO_ITEMS = -1072885583;
	public const HRESULT NS_E_WMPCORE_VIDEO_TRANSFORM_FILTER_INSERTION = -1072885582;
	public const HRESULT NS_E_WMPCORE_MEDIA_UNAVAILABLE = -1072885581;
	public const HRESULT NS_E_WMPCORE_WMX_ENTRYREF_NO_REF = -1072885580;
	public const HRESULT NS_E_WMPCORE_NO_PLAYABLE_MEDIA_IN_PLAYLIST = -1072885579;
	public const HRESULT NS_E_WMPCORE_PLAYLIST_EMPTY_NESTED_PLAYLIST_SKIPPED_ITEMS = -1072885578;
	public const HRESULT NS_E_WMPCORE_BUSY = -1072885577;
	public const HRESULT NS_E_WMPCORE_MEDIA_CHILD_PLAYLIST_UNAVAILABLE = -1072885576;
	public const HRESULT NS_E_WMPCORE_MEDIA_NO_CHILD_PLAYLIST = -1072885575;
	public const HRESULT NS_E_WMPCORE_FILE_NOT_FOUND = -1072885574;
	public const HRESULT NS_E_WMPCORE_TEMP_FILE_NOT_FOUND = -1072885573;
	public const HRESULT NS_E_WMDM_REVOKED = -1072885572;
	public const HRESULT NS_E_DDRAW_GENERIC = -1072885571;
	public const HRESULT NS_E_DISPLAY_MODE_CHANGE_FAILED = -1072885570;
	public const HRESULT NS_E_PLAYLIST_CONTAINS_ERRORS = -1072885569;
	public const HRESULT NS_E_CHANGING_PROXY_NAME = -1072885568;
	public const HRESULT NS_E_CHANGING_PROXY_PORT = -1072885567;
	public const HRESULT NS_E_CHANGING_PROXY_EXCEPTIONLIST = -1072885566;
	public const HRESULT NS_E_CHANGING_PROXYBYPASS = -1072885565;
	public const HRESULT NS_E_CHANGING_PROXY_PROTOCOL_NOT_FOUND = -1072885564;
	public const HRESULT NS_E_GRAPH_NOAUDIOLANGUAGE = -1072885563;
	public const HRESULT NS_E_GRAPH_NOAUDIOLANGUAGESELECTED = -1072885562;
	public const HRESULT NS_E_CORECD_NOTAMEDIACD = -1072885561;
	public const HRESULT NS_E_WMPCORE_MEDIA_URL_TOO_LONG = -1072885560;
	public const HRESULT NS_E_WMPFLASH_CANT_FIND_COM_SERVER = -1072885559;
	public const HRESULT NS_E_WMPFLASH_INCOMPATIBLEVERSION = -1072885558;
	public const HRESULT NS_E_WMPOCXGRAPH_IE_DISALLOWS_ACTIVEX_CONTROLS = -1072885557;
	public const HRESULT NS_E_NEED_CORE_REFERENCE = -1072885556;
	public const HRESULT NS_E_MEDIACD_READ_ERROR = -1072885555;
	public const HRESULT NS_E_IE_DISALLOWS_ACTIVEX_CONTROLS = -1072885554;
	public const HRESULT NS_E_FLASH_PLAYBACK_NOT_ALLOWED = -1072885553;
	public const HRESULT NS_E_UNABLE_TO_CREATE_RIP_LOCATION = -1072885552;
	public const HRESULT NS_E_WMPCORE_SOME_CODECS_MISSING = -1072885551;
	public const HRESULT NS_E_WMP_RIP_FAILED = -1072885550;
	public const HRESULT NS_E_WMP_FAILED_TO_RIP_TRACK = -1072885549;
	public const HRESULT NS_E_WMP_ERASE_FAILED = -1072885548;
	public const HRESULT NS_E_WMP_FORMAT_FAILED = -1072885547;
	public const HRESULT NS_E_WMP_CANNOT_BURN_NON_LOCAL_FILE = -1072885546;
	public const HRESULT NS_E_WMP_FILE_TYPE_CANNOT_BURN_TO_AUDIO_CD = -1072885545;
	public const HRESULT NS_E_WMP_FILE_DOES_NOT_FIT_ON_CD = -1072885544;
	public const HRESULT NS_E_WMP_FILE_NO_DURATION = -1072885543;
	public const HRESULT NS_E_PDA_FAILED_TO_BURN = -1072885542;
	public const HRESULT NS_S_NEED_TO_BUY_BURN_RIGHTS = 856283;
	public const HRESULT NS_E_FAILED_DOWNLOAD_ABORT_BURN = -1072885540;
	public const HRESULT NS_E_WMPCORE_DEVICE_DRIVERS_MISSING = -1072885539;
	public const HRESULT NS_S_WMPCORE_PLAYLISTCLEARABORT = 856318;
	public const HRESULT NS_S_WMPCORE_PLAYLISTREMOVEITEMABORT = 856319;
	public const HRESULT NS_S_WMPCORE_PLAYLIST_CREATION_PENDING = 856322;
	public const HRESULT NS_S_WMPCORE_MEDIA_VALIDATION_PENDING = 856323;
	public const HRESULT NS_S_WMPCORE_PLAYLIST_REPEAT_SECONDARY_SEGMENTS_IGNORED = 856324;
	public const HRESULT NS_S_WMPCORE_COMMAND_NOT_AVAILABLE = 856325;
	public const HRESULT NS_S_WMPCORE_PLAYLIST_NAME_AUTO_GENERATED = 856326;
	public const HRESULT NS_S_WMPCORE_PLAYLIST_IMPORT_MISSING_ITEMS = 856327;
	public const HRESULT NS_S_WMPCORE_PLAYLIST_COLLAPSED_TO_SINGLE_MEDIA = 856328;
	public const HRESULT NS_S_WMPCORE_MEDIA_CHILD_PLAYLIST_OPEN_PENDING = 856329;
	public const HRESULT NS_S_WMPCORE_MORE_NODES_AVAIABLE = 856330;
	public const HRESULT NS_E_WMPIM_USEROFFLINE = -1072885466;
	public const HRESULT NS_E_WMPIM_USERCANCELED = -1072885465;
	public const HRESULT NS_E_WMPIM_DIALUPFAILED = -1072885464;
	public const HRESULT NS_E_WINSOCK_ERROR_STRING = -1072885463;
	public const HRESULT NS_E_WMPBR_NOLISTENER = -1072885456;
	public const HRESULT NS_E_WMPBR_BACKUPCANCEL = -1072885455;
	public const HRESULT NS_E_WMPBR_RESTORECANCEL = -1072885454;
	public const HRESULT NS_E_WMPBR_ERRORWITHURL = -1072885453;
	public const HRESULT NS_E_WMPBR_NAMECOLLISION = -1072885452;
	public const HRESULT NS_S_WMPBR_SUCCESS = 856373;
	public const HRESULT NS_S_WMPBR_PARTIALSUCCESS = 856374;
	public const HRESULT NS_E_WMPBR_DRIVE_INVALID = -1072885449;
	public const HRESULT NS_E_WMPBR_BACKUPRESTOREFAILED = -1072885448;
	public const HRESULT NS_S_WMPEFFECT_TRANSPARENT = 856388;
	public const HRESULT NS_S_WMPEFFECT_OPAQUE = 856389;
	public const HRESULT NS_S_OPERATION_PENDING = 856398;
	public const HRESULT NS_E_WMP_CONVERT_FILE_FAILED = -1072885416;
	public const HRESULT NS_E_WMP_CONVERT_NO_RIGHTS_ERRORURL = -1072885415;
	public const HRESULT NS_E_WMP_CONVERT_NO_RIGHTS_NOERRORURL = -1072885414;
	public const HRESULT NS_E_WMP_CONVERT_FILE_CORRUPT = -1072885413;
	public const HRESULT NS_E_WMP_CONVERT_PLUGIN_UNAVAILABLE_ERRORURL = -1072885412;
	public const HRESULT NS_E_WMP_CONVERT_PLUGIN_UNAVAILABLE_NOERRORURL = -1072885411;
	public const HRESULT NS_E_WMP_CONVERT_PLUGIN_UNKNOWN_FILE_OWNER = -1072885410;
	public const HRESULT NS_E_DVD_DISC_COPY_PROTECT_OUTPUT_NS = -1072885408;
	public const HRESULT NS_E_DVD_DISC_COPY_PROTECT_OUTPUT_FAILED = -1072885407;
	public const HRESULT NS_E_DVD_NO_SUBPICTURE_STREAM = -1072885406;
	public const HRESULT NS_E_DVD_COPY_PROTECT = -1072885405;
	public const HRESULT NS_E_DVD_AUTHORING_PROBLEM = -1072885404;
	public const HRESULT NS_E_DVD_INVALID_DISC_REGION = -1072885403;
	public const HRESULT NS_E_DVD_COMPATIBLE_VIDEO_CARD = -1072885402;
	public const HRESULT NS_E_DVD_MACROVISION = -1072885401;
	public const HRESULT NS_E_DVD_SYSTEM_DECODER_REGION = -1072885400;
	public const HRESULT NS_E_DVD_DISC_DECODER_REGION = -1072885399;
	public const HRESULT NS_E_DVD_NO_VIDEO_STREAM = -1072885398;
	public const HRESULT NS_E_DVD_NO_AUDIO_STREAM = -1072885397;
	public const HRESULT NS_E_DVD_GRAPH_BUILDING = -1072885396;
	public const HRESULT NS_E_DVD_NO_DECODER = -1072885395;
	public const HRESULT NS_E_DVD_PARENTAL = -1072885394;
	public const HRESULT NS_E_DVD_CANNOT_JUMP = -1072885393;
	public const HRESULT NS_E_DVD_DEVICE_CONTENTION = -1072885392;
	public const HRESULT NS_E_DVD_NO_VIDEO_MEMORY = -1072885391;
	public const HRESULT NS_E_DVD_CANNOT_COPY_PROTECTED = -1072885390;
	public const HRESULT NS_E_DVD_REQUIRED_PROPERTY_NOT_SET = -1072885389;
	public const HRESULT NS_E_DVD_INVALID_TITLE_CHAPTER = -1072885388;
	public const HRESULT NS_E_NO_CD_BURNER = -1072885386;
	public const HRESULT NS_E_DEVICE_IS_NOT_READY = -1072885385;
	public const HRESULT NS_E_PDA_UNSUPPORTED_FORMAT = -1072885384;
	public const HRESULT NS_E_NO_PDA = -1072885383;
	public const HRESULT NS_E_PDA_UNSPECIFIED_ERROR = -1072885382;
	public const HRESULT NS_E_MEMSTORAGE_BAD_DATA = -1072885381;
	public const HRESULT NS_E_PDA_FAIL_SELECT_DEVICE = -1072885380;
	public const HRESULT NS_E_PDA_FAIL_READ_WAVE_FILE = -1072885379;
	public const HRESULT NS_E_IMAPI_LOSSOFSTREAMING = -1072885378;
	public const HRESULT NS_E_PDA_DEVICE_FULL = -1072885377;
	public const HRESULT NS_E_FAIL_LAUNCH_ROXIO_PLUGIN = -1072885376;
	public const HRESULT NS_E_PDA_DEVICE_FULL_IN_SESSION = -1072885375;
	public const HRESULT NS_E_IMAPI_MEDIUM_INVALIDTYPE = -1072885374;
	public const HRESULT NS_E_PDA_MANUALDEVICE = -1072885373;
	public const HRESULT NS_E_PDA_PARTNERSHIPNOTEXIST = -1072885372;
	public const HRESULT NS_E_PDA_CANNOT_CREATE_ADDITIONAL_SYNC_RELATIONSHIP = -1072885371;
	public const HRESULT NS_E_PDA_NO_TRANSCODE_OF_DRM = -1072885370;
	public const HRESULT NS_E_PDA_TRANSCODECACHEFULL = -1072885369;
	public const HRESULT NS_E_PDA_TOO_MANY_FILE_COLLISIONS = -1072885368;
	public const HRESULT NS_E_PDA_CANNOT_TRANSCODE = -1072885367;
	public const HRESULT NS_E_PDA_TOO_MANY_FILES_IN_DIRECTORY = -1072885366;
	public const HRESULT NS_E_PROCESSINGSHOWSYNCWIZARD = -1072885365;
	public const HRESULT NS_E_PDA_TRANSCODE_NOT_PERMITTED = -1072885364;
	public const HRESULT NS_E_PDA_INITIALIZINGDEVICES = -1072885363;
	public const HRESULT NS_E_PDA_OBSOLETE_SP = -1072885362;
	public const HRESULT NS_E_PDA_TITLE_COLLISION = -1072885361;
	public const HRESULT NS_E_PDA_DEVICESUPPORTDISABLED = -1072885360;
	public const HRESULT NS_E_PDA_NO_LONGER_AVAILABLE = -1072885359;
	public const HRESULT NS_E_PDA_ENCODER_NOT_RESPONDING = -1072885358;
	public const HRESULT NS_E_PDA_CANNOT_SYNC_FROM_LOCATION = -1072885357;
	public const HRESULT NS_E_WMP_PROTOCOL_PROBLEM = -1072885356;
	public const HRESULT NS_E_WMP_NO_DISK_SPACE = -1072885355;
	public const HRESULT NS_E_WMP_LOGON_FAILURE = -1072885354;
	public const HRESULT NS_E_WMP_CANNOT_FIND_FILE = -1072885353;
	public const HRESULT NS_E_WMP_SERVER_INACCESSIBLE = -1072885352;
	public const HRESULT NS_E_WMP_UNSUPPORTED_FORMAT = -1072885351;
	public const HRESULT NS_E_WMP_DSHOW_UNSUPPORTED_FORMAT = -1072885350;
	public const HRESULT NS_E_WMP_PLAYLIST_EXISTS = -1072885349;
	public const HRESULT NS_E_WMP_NONMEDIA_FILES = -1072885348;
	public const HRESULT NS_E_WMP_INVALID_ASX = -1072885347;
	public const HRESULT NS_E_WMP_ALREADY_IN_USE = -1072885346;
	public const HRESULT NS_E_WMP_IMAPI_FAILURE = -1072885345;
	public const HRESULT NS_E_WMP_WMDM_FAILURE = -1072885344;
	public const HRESULT NS_E_WMP_CODEC_NEEDED_WITH_4CC = -1072885343;
	public const HRESULT NS_E_WMP_CODEC_NEEDED_WITH_FORMATTAG = -1072885342;
	public const HRESULT NS_E_WMP_MSSAP_NOT_AVAILABLE = -1072885341;
	public const HRESULT NS_E_WMP_WMDM_INTERFACEDEAD = -1072885340;
	public const HRESULT NS_E_WMP_WMDM_NOTCERTIFIED = -1072885339;
	public const HRESULT NS_E_WMP_WMDM_LICENSE_NOTEXIST = -1072885338;
	public const HRESULT NS_E_WMP_WMDM_LICENSE_EXPIRED = -1072885337;
	public const HRESULT NS_E_WMP_WMDM_BUSY = -1072885336;
	public const HRESULT NS_E_WMP_WMDM_NORIGHTS = -1072885335;
	public const HRESULT NS_E_WMP_WMDM_INCORRECT_RIGHTS = -1072885334;
	public const HRESULT NS_E_WMP_IMAPI_GENERIC = -1072885333;
	public const HRESULT NS_E_WMP_IMAPI_DEVICE_NOTPRESENT = -1072885331;
	public const HRESULT NS_E_WMP_IMAPI_DEVICE_BUSY = -1072885330;
	public const HRESULT NS_E_WMP_IMAPI_LOSS_OF_STREAMING = -1072885329;
	public const HRESULT NS_E_WMP_SERVER_UNAVAILABLE = -1072885328;
	public const HRESULT NS_E_WMP_FILE_OPEN_FAILED = -1072885327;
	public const HRESULT NS_E_WMP_VERIFY_ONLINE = -1072885326;
	public const HRESULT NS_E_WMP_SERVER_NOT_RESPONDING = -1072885325;
	public const HRESULT NS_E_WMP_DRM_CORRUPT_BACKUP = -1072885324;
	public const HRESULT NS_E_WMP_DRM_LICENSE_SERVER_UNAVAILABLE = -1072885323;
	public const HRESULT NS_E_WMP_NETWORK_FIREWALL = -1072885322;
	public const HRESULT NS_E_WMP_NO_REMOVABLE_MEDIA = -1072885321;
	public const HRESULT NS_E_WMP_PROXY_CONNECT_TIMEOUT = -1072885320;
	public const HRESULT NS_E_WMP_NEED_UPGRADE = -1072885319;
	public const HRESULT NS_E_WMP_AUDIO_HW_PROBLEM = -1072885318;
	public const HRESULT NS_E_WMP_INVALID_PROTOCOL = -1072885317;
	public const HRESULT NS_E_WMP_INVALID_LIBRARY_ADD = -1072885316;
	public const HRESULT NS_E_WMP_MMS_NOT_SUPPORTED = -1072885315;
	public const HRESULT NS_E_WMP_NO_PROTOCOLS_SELECTED = -1072885314;
	public const HRESULT NS_E_WMP_GOFULLSCREEN_FAILED = -1072885313;
	public const HRESULT NS_E_WMP_NETWORK_ERROR = -1072885312;
	public const HRESULT NS_E_WMP_CONNECT_TIMEOUT = -1072885311;
	public const HRESULT NS_E_WMP_MULTICAST_DISABLED = -1072885310;
	public const HRESULT NS_E_WMP_SERVER_DNS_TIMEOUT = -1072885309;
	public const HRESULT NS_E_WMP_PROXY_NOT_FOUND = -1072885308;
	public const HRESULT NS_E_WMP_TAMPERED_CONTENT = -1072885307;
	public const HRESULT NS_E_WMP_OUTOFMEMORY = -1072885306;
	public const HRESULT NS_E_WMP_AUDIO_CODEC_NOT_INSTALLED = -1072885305;
	public const HRESULT NS_E_WMP_VIDEO_CODEC_NOT_INSTALLED = -1072885304;
	public const HRESULT NS_E_WMP_IMAPI_DEVICE_INVALIDTYPE = -1072885303;
	public const HRESULT NS_E_WMP_DRM_DRIVER_AUTH_FAILURE = -1072885302;
	public const HRESULT NS_E_WMP_NETWORK_RESOURCE_FAILURE = -1072885301;
	public const HRESULT NS_E_WMP_UPGRADE_APPLICATION = -1072885300;
	public const HRESULT NS_E_WMP_UNKNOWN_ERROR = -1072885299;
	public const HRESULT NS_E_WMP_INVALID_KEY = -1072885298;
	public const HRESULT NS_E_WMP_CD_ANOTHER_USER = -1072885297;
	public const HRESULT NS_E_WMP_DRM_NEEDS_AUTHORIZATION = -1072885296;
	public const HRESULT NS_E_WMP_BAD_DRIVER = -1072885295;
	public const HRESULT NS_E_WMP_ACCESS_DENIED = -1072885294;
	public const HRESULT NS_E_WMP_LICENSE_RESTRICTS = -1072885293;
	public const HRESULT NS_E_WMP_INVALID_REQUEST = -1072885292;
	public const HRESULT NS_E_WMP_CD_STASH_NO_SPACE = -1072885291;
	public const HRESULT NS_E_WMP_DRM_NEW_HARDWARE = -1072885290;
	public const HRESULT NS_E_WMP_DRM_INVALID_SIG = -1072885289;
	public const HRESULT NS_E_WMP_DRM_CANNOT_RESTORE = -1072885288;
	public const HRESULT NS_E_WMP_BURN_DISC_OVERFLOW = -1072885287;
	public const HRESULT NS_E_WMP_DRM_GENERIC_LICENSE_FAILURE = -1072885286;
	public const HRESULT NS_E_WMP_DRM_NO_SECURE_CLOCK = -1072885285;
	public const HRESULT NS_E_WMP_DRM_NO_RIGHTS = -1072885284;
	public const HRESULT NS_E_WMP_DRM_INDIV_FAILED = -1072885283;
	public const HRESULT NS_E_WMP_SERVER_NONEWCONNECTIONS = -1072885282;
	public const HRESULT NS_E_WMP_MULTIPLE_ERROR_IN_PLAYLIST = -1072885281;
	public const HRESULT NS_E_WMP_IMAPI2_ERASE_FAIL = -1072885280;
	public const HRESULT NS_E_WMP_IMAPI2_ERASE_DEVICE_BUSY = -1072885279;
	public const HRESULT NS_E_WMP_DRM_COMPONENT_FAILURE = -1072885278;
	public const HRESULT NS_E_WMP_DRM_NO_DEVICE_CERT = -1072885277;
	public const HRESULT NS_E_WMP_SERVER_SECURITY_ERROR = -1072885276;
	public const HRESULT NS_E_WMP_AUDIO_DEVICE_LOST = -1072885275;
	public const HRESULT NS_E_WMP_IMAPI_MEDIA_INCOMPATIBLE = -1072885274;
	public const HRESULT NS_E_SYNCWIZ_DEVICE_FULL = -1072885266;
	public const HRESULT NS_E_SYNCWIZ_CANNOT_CHANGE_SETTINGS = -1072885265;
	public const HRESULT NS_E_TRANSCODE_DELETECACHEERROR = -1072885264;
	public const HRESULT NS_E_CD_NO_BUFFERS_READ = -1072885256;
	public const HRESULT NS_E_CD_EMPTY_TRACK_QUEUE = -1072885255;
	public const HRESULT NS_E_CD_NO_READER = -1072885254;
	public const HRESULT NS_E_CD_ISRC_INVALID = -1072885253;
	public const HRESULT NS_E_CD_MEDIA_CATALOG_NUMBER_INVALID = -1072885252;
	public const HRESULT NS_E_SLOW_READ_DIGITAL_WITH_ERRORCORRECTION = -1072885251;
	public const HRESULT NS_E_CD_SPEEDDETECT_NOT_ENOUGH_READS = -1072885250;
	public const HRESULT NS_E_CD_QUEUEING_DISABLED = -1072885249;
	public const HRESULT NS_E_WMP_DRM_ACQUIRING_LICENSE = -1072885246;
	public const HRESULT NS_E_WMP_DRM_LICENSE_EXPIRED = -1072885245;
	public const HRESULT NS_E_WMP_DRM_LICENSE_NOTACQUIRED = -1072885244;
	public const HRESULT NS_E_WMP_DRM_LICENSE_NOTENABLED = -1072885243;
	public const HRESULT NS_E_WMP_DRM_LICENSE_UNUSABLE = -1072885242;
	public const HRESULT NS_E_WMP_DRM_LICENSE_CONTENT_REVOKED = -1072885241;
	public const HRESULT NS_E_WMP_DRM_LICENSE_NOSAP = -1072885240;
	public const HRESULT NS_E_WMP_DRM_UNABLE_TO_ACQUIRE_LICENSE = -1072885239;
	public const HRESULT NS_E_WMP_LICENSE_REQUIRED = -1072885238;
	public const HRESULT NS_E_WMP_PROTECTED_CONTENT = -1072885237;
	public const HRESULT NS_E_WMP_POLICY_VALUE_NOT_CONFIGURED = -1072885206;
	public const HRESULT NS_E_PDA_CANNOT_SYNC_FROM_INTERNET = -1072885196;
	public const HRESULT NS_E_PDA_CANNOT_SYNC_INVALID_PLAYLIST = -1072885195;
	public const HRESULT NS_E_PDA_FAILED_TO_SYNCHRONIZE_FILE = -1072885194;
	public const HRESULT NS_E_PDA_SYNC_FAILED = -1072885193;
	public const HRESULT NS_E_PDA_DELETE_FAILED = -1072885192;
	public const HRESULT NS_E_PDA_FAILED_TO_RETRIEVE_FILE = -1072885191;
	public const HRESULT NS_E_PDA_DEVICE_NOT_RESPONDING = -1072885190;
	public const HRESULT NS_E_PDA_FAILED_TO_TRANSCODE_PHOTO = -1072885189;
	public const HRESULT NS_E_PDA_FAILED_TO_ENCRYPT_TRANSCODED_FILE = -1072885188;
	public const HRESULT NS_E_PDA_CANNOT_TRANSCODE_TO_AUDIO = -1072885187;
	public const HRESULT NS_E_PDA_CANNOT_TRANSCODE_TO_VIDEO = -1072885186;
	public const HRESULT NS_E_PDA_CANNOT_TRANSCODE_TO_IMAGE = -1072885185;
	public const HRESULT NS_E_PDA_RETRIEVED_FILE_FILENAME_TOO_LONG = -1072885184;
	public const HRESULT NS_E_PDA_CEWMDM_DRM_ERROR = -1072885183;
	public const HRESULT NS_E_INCOMPLETE_PLAYLIST = -1072885182;
	public const HRESULT NS_E_PDA_SYNC_RUNNING = -1072885181;
	public const HRESULT NS_E_PDA_SYNC_LOGIN_ERROR = -1072885180;
	public const HRESULT NS_E_PDA_TRANSCODE_CODEC_NOT_FOUND = -1072885179;
	public const HRESULT NS_E_CANNOT_SYNC_DRM_TO_NON_JANUS_DEVICE = -1072885178;
	public const HRESULT NS_E_CANNOT_SYNC_PREVIOUS_SYNC_RUNNING = -1072885177;
	public const HRESULT NS_E_WMP_HWND_NOTFOUND = -1072885156;
	public const HRESULT NS_E_BKGDOWNLOAD_WRONG_NO_FILES = -1072885155;
	public const HRESULT NS_E_BKGDOWNLOAD_COMPLETECANCELLEDJOB = -1072885154;
	public const HRESULT NS_E_BKGDOWNLOAD_CANCELCOMPLETEDJOB = -1072885153;
	public const HRESULT NS_E_BKGDOWNLOAD_NOJOBPOINTER = -1072885152;
	public const HRESULT NS_E_BKGDOWNLOAD_INVALIDJOBSIGNATURE = -1072885151;
	public const HRESULT NS_E_BKGDOWNLOAD_FAILED_TO_CREATE_TEMPFILE = -1072885150;
	public const HRESULT NS_E_BKGDOWNLOAD_PLUGIN_FAILEDINITIALIZE = -1072885149;
	public const HRESULT NS_E_BKGDOWNLOAD_PLUGIN_FAILEDTOMOVEFILE = -1072885148;
	public const HRESULT NS_E_BKGDOWNLOAD_CALLFUNCFAILED = -1072885147;
	public const HRESULT NS_E_BKGDOWNLOAD_CALLFUNCTIMEOUT = -1072885146;
	public const HRESULT NS_E_BKGDOWNLOAD_CALLFUNCENDED = -1072885145;
	public const HRESULT NS_E_BKGDOWNLOAD_WMDUNPACKFAILED = -1072885144;
	public const HRESULT NS_E_BKGDOWNLOAD_FAILEDINITIALIZE = -1072885143;
	public const HRESULT NS_E_INTERFACE_NOT_REGISTERED_IN_GIT = -1072885142;
	public const HRESULT NS_E_BKGDOWNLOAD_INVALID_FILE_NAME = -1072885141;
	public const HRESULT NS_E_IMAGE_DOWNLOAD_FAILED = -1072885106;
	public const HRESULT NS_E_WMP_UDRM_NOUSERLIST = -1072885056;
	public const HRESULT NS_E_WMP_DRM_NOT_ACQUIRING = -1072885055;
	public const HRESULT NS_E_WMP_BSTR_TOO_LONG = -1072885006;
	public const HRESULT NS_E_WMP_AUTOPLAY_INVALID_STATE = -1072884996;
	public const HRESULT NS_E_WMP_COMPONENT_REVOKED = -1072884986;
	public const HRESULT NS_E_CURL_NOTSAFE = -1072884956;
	public const HRESULT NS_E_CURL_INVALIDCHAR = -1072884955;
	public const HRESULT NS_E_CURL_INVALIDHOSTNAME = -1072884954;
	public const HRESULT NS_E_CURL_INVALIDPATH = -1072884953;
	public const HRESULT NS_E_CURL_INVALIDSCHEME = -1072884952;
	public const HRESULT NS_E_CURL_INVALIDURL = -1072884951;
	public const HRESULT NS_E_CURL_CANTWALK = -1072884949;
	public const HRESULT NS_E_CURL_INVALIDPORT = -1072884948;
	public const HRESULT NS_E_CURLHELPER_NOTADIRECTORY = -1072884947;
	public const HRESULT NS_E_CURLHELPER_NOTAFILE = -1072884946;
	public const HRESULT NS_E_CURL_CANTDECODE = -1072884945;
	public const HRESULT NS_E_CURLHELPER_NOTRELATIVE = -1072884944;
	public const HRESULT NS_E_CURL_INVALIDBUFFERSIZE = -1072884943;
	public const HRESULT NS_E_SUBSCRIPTIONSERVICE_PLAYBACK_DISALLOWED = -1072884906;
	public const HRESULT NS_E_CANNOT_BUY_OR_DOWNLOAD_FROM_MULTIPLE_SERVICES = -1072884905;
	public const HRESULT NS_E_CANNOT_BUY_OR_DOWNLOAD_CONTENT = -1072884904;
	public const HRESULT NS_S_TRACK_BUY_REQUIRES_ALBUM_PURCHASE = 856921;
	public const HRESULT NS_E_NOT_CONTENT_PARTNER_TRACK = -1072884902;
	public const HRESULT NS_E_TRACK_DOWNLOAD_REQUIRES_ALBUM_PURCHASE = -1072884901;
	public const HRESULT NS_E_TRACK_DOWNLOAD_REQUIRES_PURCHASE = -1072884900;
	public const HRESULT NS_E_TRACK_PURCHASE_MAXIMUM_EXCEEDED = -1072884899;
	public const HRESULT NS_S_NAVIGATION_COMPLETE_WITH_ERRORS = 856926;
	public const HRESULT NS_E_SUBSCRIPTIONSERVICE_LOGIN_FAILED = -1072884897;
	public const HRESULT NS_E_SUBSCRIPTIONSERVICE_DOWNLOAD_TIMEOUT = -1072884896;
	public const HRESULT NS_S_TRACK_ALREADY_DOWNLOADED = 856929;
	public const HRESULT NS_E_CONTENT_PARTNER_STILL_INITIALIZING = -1072884894;
	public const HRESULT NS_E_OPEN_CONTAINING_FOLDER_FAILED = -1072884893;
	public const HRESULT NS_E_ADVANCEDEDIT_TOO_MANY_PICTURES = -1072884886;
	public const HRESULT NS_E_REDIRECT = -1072884856;
	public const HRESULT NS_E_STALE_PRESENTATION = -1072884855;
	public const HRESULT NS_E_NAMESPACE_WRONG_PERSIST = -1072884854;
	public const HRESULT NS_E_NAMESPACE_WRONG_TYPE = -1072884853;
	public const HRESULT NS_E_NAMESPACE_NODE_CONFLICT = -1072884852;
	public const HRESULT NS_E_NAMESPACE_NODE_NOT_FOUND = -1072884851;
	public const HRESULT NS_E_NAMESPACE_BUFFER_TOO_SMALL = -1072884850;
	public const HRESULT NS_E_NAMESPACE_TOO_MANY_CALLBACKS = -1072884849;
	public const HRESULT NS_E_NAMESPACE_DUPLICATE_CALLBACK = -1072884848;
	public const HRESULT NS_E_NAMESPACE_CALLBACK_NOT_FOUND = -1072884847;
	public const HRESULT NS_E_NAMESPACE_NAME_TOO_LONG = -1072884846;
	public const HRESULT NS_E_NAMESPACE_DUPLICATE_NAME = -1072884845;
	public const HRESULT NS_E_NAMESPACE_EMPTY_NAME = -1072884844;
	public const HRESULT NS_E_NAMESPACE_INDEX_TOO_LARGE = -1072884843;
	public const HRESULT NS_E_NAMESPACE_BAD_NAME = -1072884842;
	public const HRESULT NS_E_NAMESPACE_WRONG_SECURITY = -1072884841;
	public const HRESULT NS_E_CACHE_ARCHIVE_CONFLICT = -1072884756;
	public const HRESULT NS_E_CACHE_ORIGIN_SERVER_NOT_FOUND = -1072884755;
	public const HRESULT NS_E_CACHE_ORIGIN_SERVER_TIMEOUT = -1072884754;
	public const HRESULT NS_E_CACHE_NOT_BROADCAST = -1072884753;
	public const HRESULT NS_E_CACHE_CANNOT_BE_CACHED = -1072884752;
	public const HRESULT NS_E_CACHE_NOT_MODIFIED = -1072884751;
	public const HRESULT NS_E_CANNOT_REMOVE_PUBLISHING_POINT = -1072884656;
	public const HRESULT NS_E_CANNOT_REMOVE_PLUGIN = -1072884655;
	public const HRESULT NS_E_WRONG_PUBLISHING_POINT_TYPE = -1072884654;
	public const HRESULT NS_E_UNSUPPORTED_LOAD_TYPE = -1072884653;
	public const HRESULT NS_E_INVALID_PLUGIN_LOAD_TYPE_CONFIGURATION = -1072884652;
	public const HRESULT NS_E_INVALID_PUBLISHING_POINT_NAME = -1072884651;
	public const HRESULT NS_E_TOO_MANY_MULTICAST_SINKS = -1072884650;
	public const HRESULT NS_E_PUBLISHING_POINT_INVALID_REQUEST_WHILE_STARTED = -1072884649;
	public const HRESULT NS_E_MULTICAST_PLUGIN_NOT_ENABLED = -1072884648;
	public const HRESULT NS_E_INVALID_OPERATING_SYSTEM_VERSION = -1072884647;
	public const HRESULT NS_E_PUBLISHING_POINT_REMOVED = -1072884646;
	public const HRESULT NS_E_INVALID_PUSH_PUBLISHING_POINT_START_REQUEST = -1072884645;
	public const HRESULT NS_E_UNSUPPORTED_LANGUAGE = -1072884644;
	public const HRESULT NS_E_WRONG_OS_VERSION = -1072884643;
	public const HRESULT NS_E_PUBLISHING_POINT_STOPPED = -1072884642;
	public const HRESULT NS_E_PLAYLIST_ENTRY_ALREADY_PLAYING = -1072884556;
	public const HRESULT NS_E_EMPTY_PLAYLIST = -1072884555;
	public const HRESULT NS_E_PLAYLIST_PARSE_FAILURE = -1072884554;
	public const HRESULT NS_E_PLAYLIST_UNSUPPORTED_ENTRY = -1072884553;
	public const HRESULT NS_E_PLAYLIST_ENTRY_NOT_IN_PLAYLIST = -1072884552;
	public const HRESULT NS_E_PLAYLIST_ENTRY_SEEK = -1072884551;
	public const HRESULT NS_E_PLAYLIST_RECURSIVE_PLAYLISTS = -1072884550;
	public const HRESULT NS_E_PLAYLIST_TOO_MANY_NESTED_PLAYLISTS = -1072884549;
	public const HRESULT NS_E_PLAYLIST_SHUTDOWN = -1072884548;
	public const HRESULT NS_E_PLAYLIST_END_RECEDING = -1072884547;
	public const HRESULT NS_I_PLAYLIST_CHANGE_RECEDING = 1074599102;
	public const HRESULT NS_E_DATAPATH_NO_SINK = -1072884456;
	public const HRESULT NS_S_PUBLISHING_POINT_STARTED_WITH_FAILED_SINKS = 857369;
	public const HRESULT NS_E_INVALID_PUSH_TEMPLATE = -1072884454;
	public const HRESULT NS_E_INVALID_PUSH_PUBLISHING_POINT = -1072884453;
	public const HRESULT NS_E_CRITICAL_ERROR = -1072884452;
	public const HRESULT NS_E_NO_NEW_CONNECTIONS = -1072884451;
	public const HRESULT NS_E_WSX_INVALID_VERSION = -1072884450;
	public const HRESULT NS_E_HEADER_MISMATCH = -1072884449;
	public const HRESULT NS_E_PUSH_DUPLICATE_PUBLISHING_POINT_NAME = -1072884448;
	public const HRESULT NS_E_NO_SCRIPT_ENGINE = -1072884356;
	public const HRESULT NS_E_PLUGIN_ERROR_REPORTED = -1072884355;
	public const HRESULT NS_E_SOURCE_PLUGIN_NOT_FOUND = -1072884354;
	public const HRESULT NS_E_PLAYLIST_PLUGIN_NOT_FOUND = -1072884353;
	public const HRESULT NS_E_DATA_SOURCE_ENUMERATION_NOT_SUPPORTED = -1072884352;
	public const HRESULT NS_E_MEDIA_PARSER_INVALID_FORMAT = -1072884351;
	public const HRESULT NS_E_SCRIPT_DEBUGGER_NOT_INSTALLED = -1072884350;
	public const HRESULT NS_E_FEATURE_REQUIRES_ENTERPRISE_SERVER = -1072884349;
	public const HRESULT NS_E_WIZARD_RUNNING = -1072884348;
	public const HRESULT NS_E_INVALID_LOG_URL = -1072884347;
	public const HRESULT NS_E_INVALID_MTU_RANGE = -1072884346;
	public const HRESULT NS_E_INVALID_PLAY_STATISTICS = -1072884345;
	public const HRESULT NS_E_LOG_NEED_TO_BE_SKIPPED = -1072884344;
	public const HRESULT NS_E_HTTP_TEXT_DATACONTAINER_SIZE_LIMIT_EXCEEDED = -1072884343;
	public const HRESULT NS_E_PORT_IN_USE = -1072884342;
	public const HRESULT NS_E_PORT_IN_USE_HTTP = -1072884341;
	public const HRESULT NS_E_HTTP_TEXT_DATACONTAINER_INVALID_SERVER_RESPONSE = -1072884340;
	public const HRESULT NS_E_ARCHIVE_REACH_QUOTA = -1072884339;
	public const HRESULT NS_E_ARCHIVE_ABORT_DUE_TO_BCAST = -1072884338;
	public const HRESULT NS_E_ARCHIVE_GAP_DETECTED = -1072884337;
	public const HRESULT NS_E_AUTHORIZATION_FILE_NOT_FOUND = -1072884336;
	public const HRESULT NS_E_BAD_MARKIN = -1072882856;
	public const HRESULT NS_E_BAD_MARKOUT = -1072882855;
	public const HRESULT NS_E_NOMATCHING_MEDIASOURCE = -1072882854;
	public const HRESULT NS_E_UNSUPPORTED_SOURCETYPE = -1072882853;
	public const HRESULT NS_E_TOO_MANY_AUDIO = -1072882852;
	public const HRESULT NS_E_TOO_MANY_VIDEO = -1072882851;
	public const HRESULT NS_E_NOMATCHING_ELEMENT = -1072882850;
	public const HRESULT NS_E_MISMATCHED_MEDIACONTENT = -1072882849;
	public const HRESULT NS_E_CANNOT_DELETE_ACTIVE_SOURCEGROUP = -1072882848;
	public const HRESULT NS_E_AUDIODEVICE_BUSY = -1072882847;
	public const HRESULT NS_E_AUDIODEVICE_UNEXPECTED = -1072882846;
	public const HRESULT NS_E_AUDIODEVICE_BADFORMAT = -1072882845;
	public const HRESULT NS_E_VIDEODEVICE_BUSY = -1072882844;
	public const HRESULT NS_E_VIDEODEVICE_UNEXPECTED = -1072882843;
	public const HRESULT NS_E_INVALIDCALL_WHILE_ENCODER_RUNNING = -1072882842;
	public const HRESULT NS_E_NO_PROFILE_IN_SOURCEGROUP = -1072882841;
	public const HRESULT NS_E_VIDEODRIVER_UNSTABLE = -1072882840;
	public const HRESULT NS_E_VIDCAPSTARTFAILED = -1072882839;
	public const HRESULT NS_E_VIDSOURCECOMPRESSION = -1072882838;
	public const HRESULT NS_E_VIDSOURCESIZE = -1072882837;
	public const HRESULT NS_E_ICMQUERYFORMAT = -1072882836;
	public const HRESULT NS_E_VIDCAPCREATEWINDOW = -1072882835;
	public const HRESULT NS_E_VIDCAPDRVINUSE = -1072882834;
	public const HRESULT NS_E_NO_MEDIAFORMAT_IN_SOURCE = -1072882833;
	public const HRESULT NS_E_NO_VALID_OUTPUT_STREAM = -1072882832;
	public const HRESULT NS_E_NO_VALID_SOURCE_PLUGIN = -1072882831;
	public const HRESULT NS_E_NO_ACTIVE_SOURCEGROUP = -1072882830;
	public const HRESULT NS_E_NO_SCRIPT_STREAM = -1072882829;
	public const HRESULT NS_E_INVALIDCALL_WHILE_ARCHIVAL_RUNNING = -1072882828;
	public const HRESULT NS_E_INVALIDPACKETSIZE = -1072882827;
	public const HRESULT NS_E_PLUGIN_CLSID_INVALID = -1072882826;
	public const HRESULT NS_E_UNSUPPORTED_ARCHIVETYPE = -1072882825;
	public const HRESULT NS_E_UNSUPPORTED_ARCHIVEOPERATION = -1072882824;
	public const HRESULT NS_E_ARCHIVE_FILENAME_NOTSET = -1072882823;
	public const HRESULT NS_E_SOURCEGROUP_NOTPREPARED = -1072882822;
	public const HRESULT NS_E_PROFILE_MISMATCH = -1072882821;
	public const HRESULT NS_E_INCORRECTCLIPSETTINGS = -1072882820;
	public const HRESULT NS_E_NOSTATSAVAILABLE = -1072882819;
	public const HRESULT NS_E_NOTARCHIVING = -1072882818;
	public const HRESULT NS_E_INVALIDCALL_WHILE_ENCODER_STOPPED = -1072882817;
	public const HRESULT NS_E_NOSOURCEGROUPS = -1072882816;
	public const HRESULT NS_E_INVALIDINPUTFPS = -1072882815;
	public const HRESULT NS_E_NO_DATAVIEW_SUPPORT = -1072882814;
	public const HRESULT NS_E_CODEC_UNAVAILABLE = -1072882813;
	public const HRESULT NS_E_ARCHIVE_SAME_AS_INPUT = -1072882812;
	public const HRESULT NS_E_SOURCE_NOTSPECIFIED = -1072882811;
	public const HRESULT NS_E_NO_REALTIME_TIMECOMPRESSION = -1072882810;
	public const HRESULT NS_E_UNSUPPORTED_ENCODER_DEVICE = -1072882809;
	public const HRESULT NS_E_UNEXPECTED_DISPLAY_SETTINGS = -1072882808;
	public const HRESULT NS_E_NO_AUDIODATA = -1072882807;
	public const HRESULT NS_E_INPUTSOURCE_PROBLEM = -1072882806;
	public const HRESULT NS_E_WME_VERSION_MISMATCH = -1072882805;
	public const HRESULT NS_E_NO_REALTIME_PREPROCESS = -1072882804;
	public const HRESULT NS_E_NO_REPEAT_PREPROCESS = -1072882803;
	public const HRESULT NS_E_CANNOT_PAUSE_LIVEBROADCAST = -1072882802;
	public const HRESULT NS_E_DRM_PROFILE_NOT_SET = -1072882801;
	public const HRESULT NS_E_DUPLICATE_DRMPROFILE = -1072882800;
	public const HRESULT NS_E_INVALID_DEVICE = -1072882799;
	public const HRESULT NS_E_SPEECHEDL_ON_NON_MIXEDMODE = -1072882798;
	public const HRESULT NS_E_DRM_PASSWORD_TOO_LONG = -1072882797;
	public const HRESULT NS_E_DEVCONTROL_FAILED_SEEK = -1072882796;
	public const HRESULT NS_E_INTERLACE_REQUIRE_SAMESIZE = -1072882795;
	public const HRESULT NS_E_TOO_MANY_DEVICECONTROL = -1072882794;
	public const HRESULT NS_E_NO_MULTIPASS_FOR_LIVEDEVICE = -1072882793;
	public const HRESULT NS_E_MISSING_AUDIENCE = -1072882792;
	public const HRESULT NS_E_AUDIENCE_CONTENTTYPE_MISMATCH = -1072882791;
	public const HRESULT NS_E_MISSING_SOURCE_INDEX = -1072882790;
	public const HRESULT NS_E_NUM_LANGUAGE_MISMATCH = -1072882789;
	public const HRESULT NS_E_LANGUAGE_MISMATCH = -1072882788;
	public const HRESULT NS_E_VBRMODE_MISMATCH = -1072882787;
	public const HRESULT NS_E_INVALID_INPUT_AUDIENCE_INDEX = -1072882786;
	public const HRESULT NS_E_INVALID_INPUT_LANGUAGE = -1072882785;
	public const HRESULT NS_E_INVALID_INPUT_STREAM = -1072882784;
	public const HRESULT NS_E_EXPECT_MONO_WAV_INPUT = -1072882783;
	public const HRESULT NS_E_INPUT_WAVFORMAT_MISMATCH = -1072882782;
	public const HRESULT NS_E_RECORDQ_DISK_FULL = -1072882781;
	public const HRESULT NS_E_NO_PAL_INVERSE_TELECINE = -1072882780;
	public const HRESULT NS_E_ACTIVE_SG_DEVICE_DISCONNECTED = -1072882779;
	public const HRESULT NS_E_ACTIVE_SG_DEVICE_CONTROL_DISCONNECTED = -1072882778;
	public const HRESULT NS_E_NO_FRAMES_SUBMITTED_TO_ANALYZER = -1072882777;
	public const HRESULT NS_E_INPUT_DOESNOT_SUPPORT_SMPTE = -1072882776;
	public const HRESULT NS_E_NO_SMPTE_WITH_MULTIPLE_SOURCEGROUPS = -1072882775;
	public const HRESULT NS_E_BAD_CONTENTEDL = -1072882774;
	public const HRESULT NS_E_INTERLACEMODE_MISMATCH = -1072882773;
	public const HRESULT NS_E_NONSQUAREPIXELMODE_MISMATCH = -1072882772;
	public const HRESULT NS_E_SMPTEMODE_MISMATCH = -1072882771;
	public const HRESULT NS_E_END_OF_TAPE = -1072882770;
	public const HRESULT NS_E_NO_MEDIA_IN_AUDIENCE = -1072882769;
	public const HRESULT NS_E_NO_AUDIENCES = -1072882768;
	public const HRESULT NS_E_NO_AUDIO_COMPAT = -1072882767;
	public const HRESULT NS_E_INVALID_VBR_COMPAT = -1072882766;
	public const HRESULT NS_E_NO_PROFILE_NAME = -1072882765;
	public const HRESULT NS_E_INVALID_VBR_WITH_UNCOMP = -1072882764;
	public const HRESULT NS_E_MULTIPLE_VBR_AUDIENCES = -1072882763;
	public const HRESULT NS_E_UNCOMP_COMP_COMBINATION = -1072882762;
	public const HRESULT NS_E_MULTIPLE_AUDIO_CODECS = -1072882761;
	public const HRESULT NS_E_MULTIPLE_AUDIO_FORMATS = -1072882760;
	public const HRESULT NS_E_AUDIO_BITRATE_STEPDOWN = -1072882759;
	public const HRESULT NS_E_INVALID_AUDIO_PEAKRATE = -1072882758;
	public const HRESULT NS_E_INVALID_AUDIO_PEAKRATE_2 = -1072882757;
	public const HRESULT NS_E_INVALID_AUDIO_BUFFERMAX = -1072882756;
	public const HRESULT NS_E_MULTIPLE_VIDEO_CODECS = -1072882755;
	public const HRESULT NS_E_MULTIPLE_VIDEO_SIZES = -1072882754;
	public const HRESULT NS_E_INVALID_VIDEO_BITRATE = -1072882753;
	public const HRESULT NS_E_VIDEO_BITRATE_STEPDOWN = -1072882752;
	public const HRESULT NS_E_INVALID_VIDEO_PEAKRATE = -1072882751;
	public const HRESULT NS_E_INVALID_VIDEO_PEAKRATE_2 = -1072882750;
	public const HRESULT NS_E_INVALID_VIDEO_WIDTH = -1072882749;
	public const HRESULT NS_E_INVALID_VIDEO_HEIGHT = -1072882748;
	public const HRESULT NS_E_INVALID_VIDEO_FPS = -1072882747;
	public const HRESULT NS_E_INVALID_VIDEO_KEYFRAME = -1072882746;
	public const HRESULT NS_E_INVALID_VIDEO_IQUALITY = -1072882745;
	public const HRESULT NS_E_INVALID_VIDEO_CQUALITY = -1072882744;
	public const HRESULT NS_E_INVALID_VIDEO_BUFFER = -1072882743;
	public const HRESULT NS_E_INVALID_VIDEO_BUFFERMAX = -1072882742;
	public const HRESULT NS_E_INVALID_VIDEO_BUFFERMAX_2 = -1072882741;
	public const HRESULT NS_E_INVALID_VIDEO_WIDTH_ALIGN = -1072882740;
	public const HRESULT NS_E_INVALID_VIDEO_HEIGHT_ALIGN = -1072882739;
	public const HRESULT NS_E_MULTIPLE_SCRIPT_BITRATES = -1072882738;
	public const HRESULT NS_E_INVALID_SCRIPT_BITRATE = -1072882737;
	public const HRESULT NS_E_MULTIPLE_FILE_BITRATES = -1072882736;
	public const HRESULT NS_E_INVALID_FILE_BITRATE = -1072882735;
	public const HRESULT NS_E_SAME_AS_INPUT_COMBINATION = -1072882734;
	public const HRESULT NS_E_SOURCE_CANNOT_LOOP = -1072882733;
	public const HRESULT NS_E_INVALID_FOLDDOWN_COEFFICIENTS = -1072882732;
	public const HRESULT NS_E_DRMPROFILE_NOTFOUND = -1072882731;
	public const HRESULT NS_E_INVALID_TIMECODE = -1072882730;
	public const HRESULT NS_E_NO_AUDIO_TIMECOMPRESSION = -1072882729;
	public const HRESULT NS_E_NO_TWOPASS_TIMECOMPRESSION = -1072882728;
	public const HRESULT NS_E_TIMECODE_REQUIRES_VIDEOSTREAM = -1072882727;
	public const HRESULT NS_E_NO_MBR_WITH_TIMECODE = -1072882726;
	public const HRESULT NS_E_INVALID_INTERLACEMODE = -1072882725;
	public const HRESULT NS_E_INVALID_INTERLACE_COMPAT = -1072882724;
	public const HRESULT NS_E_INVALID_NONSQUAREPIXEL_COMPAT = -1072882723;
	public const HRESULT NS_E_INVALID_SOURCE_WITH_DEVICE_CONTROL = -1072882722;
	public const HRESULT NS_E_CANNOT_GENERATE_BROADCAST_INFO_FOR_QUALITYVBR = -1072882721;
	public const HRESULT NS_E_EXCEED_MAX_DRM_PROFILE_LIMIT = -1072882720;
	public const HRESULT NS_E_DEVICECONTROL_UNSTABLE = -1072882719;
	public const HRESULT NS_E_INVALID_PIXEL_ASPECT_RATIO = -1072882718;
	public const HRESULT NS_E_AUDIENCE__LANGUAGE_CONTENTTYPE_MISMATCH = -1072882717;
	public const HRESULT NS_E_INVALID_PROFILE_CONTENTTYPE = -1072882716;
	public const HRESULT NS_E_TRANSFORM_PLUGIN_NOT_FOUND = -1072882715;
	public const HRESULT NS_E_TRANSFORM_PLUGIN_INVALID = -1072882714;
	public const HRESULT NS_E_EDL_REQUIRED_FOR_DEVICE_MULTIPASS = -1072882713;
	public const HRESULT NS_E_INVALID_VIDEO_WIDTH_FOR_INTERLACED_ENCODING = -1072882712;
	public const HRESULT NS_E_MARKIN_UNSUPPORTED = -1072882711;
	public const HRESULT NS_E_DRM_INVALID_APPLICATION = -1072879855;
	public const HRESULT NS_E_DRM_LICENSE_STORE_ERROR = -1072879854;
	public const HRESULT NS_E_DRM_SECURE_STORE_ERROR = -1072879853;
	public const HRESULT NS_E_DRM_LICENSE_STORE_SAVE_ERROR = -1072879852;
	public const HRESULT NS_E_DRM_SECURE_STORE_UNLOCK_ERROR = -1072879851;
	public const HRESULT NS_E_DRM_INVALID_CONTENT = -1072879850;
	public const HRESULT NS_E_DRM_UNABLE_TO_OPEN_LICENSE = -1072879849;
	public const HRESULT NS_E_DRM_INVALID_LICENSE = -1072879848;
	public const HRESULT NS_E_DRM_INVALID_MACHINE = -1072879847;
	public const HRESULT NS_E_DRM_ENUM_LICENSE_FAILED = -1072879845;
	public const HRESULT NS_E_DRM_INVALID_LICENSE_REQUEST = -1072879844;
	public const HRESULT NS_E_DRM_UNABLE_TO_INITIALIZE = -1072879843;
	public const HRESULT NS_E_DRM_UNABLE_TO_ACQUIRE_LICENSE = -1072879842;
	public const HRESULT NS_E_DRM_INVALID_LICENSE_ACQUIRED = -1072879841;
	public const HRESULT NS_E_DRM_NO_RIGHTS = -1072879840;
	public const HRESULT NS_E_DRM_KEY_ERROR = -1072879839;
	public const HRESULT NS_E_DRM_ENCRYPT_ERROR = -1072879838;
	public const HRESULT NS_E_DRM_DECRYPT_ERROR = -1072879837;
	public const HRESULT NS_E_DRM_LICENSE_INVALID_XML = -1072879835;
	public const HRESULT NS_S_DRM_LICENSE_ACQUIRED = 861990;
	public const HRESULT NS_S_DRM_INDIVIDUALIZED = 861991;
	public const HRESULT NS_E_DRM_NEEDS_INDIVIDUALIZATION = -1072879832;
	public const HRESULT NS_E_DRM_ALREADY_INDIVIDUALIZED = -1072879831;
	public const HRESULT NS_E_DRM_ACTION_NOT_QUERIED = -1072879830;
	public const HRESULT NS_E_DRM_ACQUIRING_LICENSE = -1072879829;
	public const HRESULT NS_E_DRM_INDIVIDUALIZING = -1072879828;
	public const HRESULT NS_E_BACKUP_RESTORE_FAILURE = -1072879827;
	public const HRESULT NS_E_BACKUP_RESTORE_BAD_REQUEST_ID = -1072879826;
	public const HRESULT NS_E_DRM_PARAMETERS_MISMATCHED = -1072879825;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_LICENSE_OBJECT = -1072879824;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_INDI_OBJECT = -1072879823;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_ENCRYPT_OBJECT = -1072879822;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_DECRYPT_OBJECT = -1072879821;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_PROPERTIES_OBJECT = -1072879820;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_BACKUP_OBJECT = -1072879819;
	public const HRESULT NS_E_DRM_INDIVIDUALIZE_ERROR = -1072879818;
	public const HRESULT NS_E_DRM_LICENSE_OPEN_ERROR = -1072879817;
	public const HRESULT NS_E_DRM_LICENSE_CLOSE_ERROR = -1072879816;
	public const HRESULT NS_E_DRM_GET_LICENSE_ERROR = -1072879815;
	public const HRESULT NS_E_DRM_QUERY_ERROR = -1072879814;
	public const HRESULT NS_E_DRM_REPORT_ERROR = -1072879813;
	public const HRESULT NS_E_DRM_GET_LICENSESTRING_ERROR = -1072879812;
	public const HRESULT NS_E_DRM_GET_CONTENTSTRING_ERROR = -1072879811;
	public const HRESULT NS_E_DRM_MONITOR_ERROR = -1072879810;
	public const HRESULT NS_E_DRM_UNABLE_TO_SET_PARAMETER = -1072879809;
	public const HRESULT NS_E_DRM_INVALID_APPDATA = -1072879808;
	public const HRESULT NS_E_DRM_INVALID_APPDATA_VERSION = -1072879807;
	public const HRESULT NS_E_DRM_BACKUP_EXISTS = -1072879806;
	public const HRESULT NS_E_DRM_BACKUP_CORRUPT = -1072879805;
	public const HRESULT NS_E_DRM_BACKUPRESTORE_BUSY = -1072879804;
	public const HRESULT NS_E_BACKUP_RESTORE_BAD_DATA = -1072879803;
	public const HRESULT NS_S_DRM_MONITOR_CANCELLED = 862022;
	public const HRESULT NS_S_DRM_ACQUIRE_CANCELLED = 862023;
	public const HRESULT NS_E_DRM_LICENSE_UNUSABLE = -1072879800;
	public const HRESULT NS_E_DRM_INVALID_PROPERTY = -1072879799;
	public const HRESULT NS_E_DRM_SECURE_STORE_NOT_FOUND = -1072879798;
	public const HRESULT NS_E_DRM_CACHED_CONTENT_ERROR = -1072879797;
	public const HRESULT NS_E_DRM_INDIVIDUALIZATION_INCOMPLETE = -1072879796;
	public const HRESULT NS_E_DRM_DRIVER_AUTH_FAILURE = -1072879795;
	public const HRESULT NS_E_DRM_NEED_UPGRADE_MSSAP = -1072879794;
	public const HRESULT NS_E_DRM_REOPEN_CONTENT = -1072879793;
	public const HRESULT NS_E_DRM_DRIVER_DIGIOUT_FAILURE = -1072879792;
	public const HRESULT NS_E_DRM_INVALID_SECURESTORE_PASSWORD = -1072879791;
	public const HRESULT NS_E_DRM_APPCERT_REVOKED = -1072879790;
	public const HRESULT NS_E_DRM_RESTORE_FRAUD = -1072879789;
	public const HRESULT NS_E_DRM_HARDWARE_INCONSISTENT = -1072879788;
	public const HRESULT NS_E_DRM_SDMI_TRIGGER = -1072879787;
	public const HRESULT NS_E_DRM_SDMI_NOMORECOPIES = -1072879786;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_HEADER_OBJECT = -1072879785;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_KEYS_OBJECT = -1072879784;
	public const HRESULT NS_E_DRM_LICENSE_NOTACQUIRED = -1072879783;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_CODING_OBJECT = -1072879782;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_STATE_DATA_OBJECT = -1072879781;
	public const HRESULT NS_E_DRM_BUFFER_TOO_SMALL = -1072879780;
	public const HRESULT NS_E_DRM_UNSUPPORTED_PROPERTY = -1072879779;
	public const HRESULT NS_E_DRM_ERROR_BAD_NET_RESP = -1072879778;
	public const HRESULT NS_E_DRM_STORE_NOTALLSTORED = -1072879777;
	public const HRESULT NS_E_DRM_SECURITY_COMPONENT_SIGNATURE_INVALID = -1072879776;
	public const HRESULT NS_E_DRM_INVALID_DATA = -1072879775;
	public const HRESULT NS_E_DRM_POLICY_DISABLE_ONLINE = -1072879774;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_AUTHENTICATION_OBJECT = -1072879773;
	public const HRESULT NS_E_DRM_NOT_CONFIGURED = -1072879772;
	public const HRESULT NS_E_DRM_DEVICE_ACTIVATION_CANCELED = -1072879771;
	public const HRESULT NS_E_BACKUP_RESTORE_TOO_MANY_RESETS = -1072879770;
	public const HRESULT NS_E_DRM_DEBUGGING_NOT_ALLOWED = -1072879769;
	public const HRESULT NS_E_DRM_OPERATION_CANCELED = -1072879768;
	public const HRESULT NS_E_DRM_RESTRICTIONS_NOT_RETRIEVED = -1072879767;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_PLAYLIST_OBJECT = -1072879766;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_PLAYLIST_BURN_OBJECT = -1072879765;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_DEVICE_REGISTRATION_OBJECT = -1072879764;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_METERING_OBJECT = -1072879763;
	public const HRESULT NS_S_DRM_BURNABLE_TRACK = 862062;
	public const HRESULT NS_S_DRM_BURNABLE_TRACK_WITH_PLAYLIST_RESTRICTION = 862063;
	public const HRESULT NS_E_DRM_TRACK_EXCEEDED_PLAYLIST_RESTICTION = -1072879760;
	public const HRESULT NS_E_DRM_TRACK_EXCEEDED_TRACKBURN_RESTRICTION = -1072879759;
	public const HRESULT NS_E_DRM_UNABLE_TO_GET_DEVICE_CERT = -1072879758;
	public const HRESULT NS_E_DRM_UNABLE_TO_GET_SECURE_CLOCK = -1072879757;
	public const HRESULT NS_E_DRM_UNABLE_TO_SET_SECURE_CLOCK = -1072879756;
	public const HRESULT NS_E_DRM_UNABLE_TO_GET_SECURE_CLOCK_FROM_SERVER = -1072879755;
	public const HRESULT NS_E_DRM_POLICY_METERING_DISABLED = -1072879754;
	public const HRESULT NS_E_DRM_TRANSFER_CHAINED_LICENSES_UNSUPPORTED = -1072879753;
	public const HRESULT NS_E_DRM_SDK_VERSIONMISMATCH = -1072879752;
	public const HRESULT NS_E_DRM_LIC_NEEDS_DEVICE_CLOCK_SET = -1072879751;
	public const HRESULT NS_E_LICENSE_HEADER_MISSING_URL = -1072879750;
	public const HRESULT NS_E_DEVICE_NOT_WMDRM_DEVICE = -1072879749;
	public const HRESULT NS_E_DRM_INVALID_APPCERT = -1072879748;
	public const HRESULT NS_E_DRM_PROTOCOL_FORCEFUL_TERMINATION_ON_PETITION = -1072879747;
	public const HRESULT NS_E_DRM_PROTOCOL_FORCEFUL_TERMINATION_ON_CHALLENGE = -1072879746;
	public const HRESULT NS_E_DRM_CHECKPOINT_FAILED = -1072879745;
	public const HRESULT NS_E_DRM_BB_UNABLE_TO_INITIALIZE = -1072879744;
	public const HRESULT NS_E_DRM_UNABLE_TO_LOAD_HARDWARE_ID = -1072879743;
	public const HRESULT NS_E_DRM_UNABLE_TO_OPEN_DATA_STORE = -1072879742;
	public const HRESULT NS_E_DRM_DATASTORE_CORRUPT = -1072879741;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_INMEMORYSTORE_OBJECT = -1072879740;
	public const HRESULT NS_E_DRM_STUBLIB_REQUIRED = -1072879739;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_CERTIFICATE_OBJECT = -1072879738;
	public const HRESULT NS_E_DRM_MIGRATION_TARGET_NOT_ONLINE = -1072879737;
	public const HRESULT NS_E_DRM_INVALID_MIGRATION_IMAGE = -1072879736;
	public const HRESULT NS_E_DRM_MIGRATION_TARGET_STATES_CORRUPTED = -1072879735;
	public const HRESULT NS_E_DRM_MIGRATION_IMPORTER_NOT_AVAILABLE = -1072879734;
	public const HRESULT NS_DRM_E_MIGRATION_UPGRADE_WITH_DIFF_SID = -1072879733;
	public const HRESULT NS_DRM_E_MIGRATION_SOURCE_MACHINE_IN_USE = -1072879732;
	public const HRESULT NS_DRM_E_MIGRATION_TARGET_MACHINE_LESS_THAN_LH = -1072879731;
	public const HRESULT NS_DRM_E_MIGRATION_IMAGE_ALREADY_EXISTS = -1072879730;
	public const HRESULT NS_E_DRM_HARDWAREID_MISMATCH = -1072879729;
	public const HRESULT NS_E_INVALID_DRMV2CLT_STUBLIB = -1072879728;
	public const HRESULT NS_E_DRM_MIGRATION_INVALID_LEGACYV2_DATA = -1072879727;
	public const HRESULT NS_E_DRM_MIGRATION_LICENSE_ALREADY_EXISTS = -1072879726;
	public const HRESULT NS_E_DRM_MIGRATION_INVALID_LEGACYV2_SST_PASSWORD = -1072879725;
	public const HRESULT NS_E_DRM_MIGRATION_NOT_SUPPORTED = -1072879724;
	public const HRESULT NS_E_DRM_UNABLE_TO_CREATE_MIGRATION_IMPORTER_OBJECT = -1072879723;
	public const HRESULT NS_E_DRM_CHECKPOINT_MISMATCH = -1072879722;
	public const HRESULT NS_E_DRM_CHECKPOINT_CORRUPT = -1072879721;
	public const HRESULT NS_E_REG_FLUSH_FAILURE = -1072879720;
	public const HRESULT NS_E_HDS_KEY_MISMATCH = -1072879719;
	public const HRESULT NS_E_DRM_MIGRATION_OPERATION_CANCELLED = -1072879718;
	public const HRESULT NS_E_DRM_MIGRATION_OBJECT_IN_USE = -1072879717;
	public const HRESULT NS_E_DRM_MALFORMED_CONTENT_HEADER = -1072879716;
	public const HRESULT NS_E_DRM_LICENSE_EXPIRED = -1072879656;
	public const HRESULT NS_E_DRM_LICENSE_NOTENABLED = -1072879655;
	public const HRESULT NS_E_DRM_LICENSE_APPSECLOW = -1072879654;
	public const HRESULT NS_E_DRM_STORE_NEEDINDI = -1072879653;
	public const HRESULT NS_E_DRM_STORE_NOTALLOWED = -1072879652;
	public const HRESULT NS_E_DRM_LICENSE_APP_NOTALLOWED = -1072879651;
	public const HRESULT NS_S_DRM_NEEDS_INDIVIDUALIZATION = 862174;
	public const HRESULT NS_E_DRM_LICENSE_CERT_EXPIRED = -1072879649;
	public const HRESULT NS_E_DRM_LICENSE_SECLOW = -1072879648;
	public const HRESULT NS_E_DRM_LICENSE_CONTENT_REVOKED = -1072879647;
	public const HRESULT NS_E_DRM_DEVICE_NOT_REGISTERED = -1072879646;
	public const HRESULT NS_E_DRM_LICENSE_NOSAP = -1072879606;
	public const HRESULT NS_E_DRM_LICENSE_NOSVP = -1072879605;
	public const HRESULT NS_E_DRM_LICENSE_NOWDM = -1072879604;
	public const HRESULT NS_E_DRM_LICENSE_NOTRUSTEDCODEC = -1072879603;
	public const HRESULT NS_E_DRM_SOURCEID_NOT_SUPPORTED = -1072879602;
	public const HRESULT NS_E_DRM_NEEDS_UPGRADE_TEMPFILE = -1072879555;
	public const HRESULT NS_E_DRM_NEED_UPGRADE_PD = -1072879554;
	public const HRESULT NS_E_DRM_SIGNATURE_FAILURE = -1072879553;
	public const HRESULT NS_E_DRM_LICENSE_SERVER_INFO_MISSING = -1072879552;
	public const HRESULT NS_E_DRM_BUSY = -1072879551;
	public const HRESULT NS_E_DRM_PD_TOO_MANY_DEVICES = -1072879550;
	public const HRESULT NS_E_DRM_INDIV_FRAUD = -1072879549;
	public const HRESULT NS_E_DRM_INDIV_NO_CABS = -1072879548;
	public const HRESULT NS_E_DRM_INDIV_SERVICE_UNAVAILABLE = -1072879547;
	public const HRESULT NS_E_DRM_RESTORE_SERVICE_UNAVAILABLE = -1072879546;
	public const HRESULT NS_E_DRM_CLIENT_CODE_EXPIRED = -1072879545;
	public const HRESULT NS_E_DRM_NO_UPLINK_LICENSE = -1072879544;
	public const HRESULT NS_E_DRM_INVALID_KID = -1072879543;
	public const HRESULT NS_E_DRM_LICENSE_INITIALIZATION_ERROR = -1072879542;
	public const HRESULT NS_E_DRM_CHAIN_TOO_LONG = -1072879540;
	public const HRESULT NS_E_DRM_UNSUPPORTED_ALGORITHM = -1072879539;
	public const HRESULT NS_E_DRM_LICENSE_DELETION_ERROR = -1072879538;
	public const HRESULT NS_E_DRM_INVALID_CERTIFICATE = -1072879456;
	public const HRESULT NS_E_DRM_CERTIFICATE_REVOKED = -1072879455;
	public const HRESULT NS_E_DRM_LICENSE_UNAVAILABLE = -1072879454;
	public const HRESULT NS_E_DRM_DEVICE_LIMIT_REACHED = -1072879453;
	public const HRESULT NS_E_DRM_UNABLE_TO_VERIFY_PROXIMITY = -1072879452;
	public const HRESULT NS_E_DRM_MUST_REGISTER = -1072879451;
	public const HRESULT NS_E_DRM_MUST_APPROVE = -1072879450;
	public const HRESULT NS_E_DRM_MUST_REVALIDATE = -1072879449;
	public const HRESULT NS_E_DRM_INVALID_PROXIMITY_RESPONSE = -1072879448;
	public const HRESULT NS_E_DRM_INVALID_SESSION = -1072879447;
	public const HRESULT NS_E_DRM_DEVICE_NOT_OPEN = -1072879446;
	public const HRESULT NS_E_DRM_DEVICE_ALREADY_REGISTERED = -1072879445;
	public const HRESULT NS_E_DRM_UNSUPPORTED_PROTOCOL_VERSION = -1072879444;
	public const HRESULT NS_E_DRM_UNSUPPORTED_ACTION = -1072879443;
	public const HRESULT NS_E_DRM_CERTIFICATE_SECURITY_LEVEL_INADEQUATE = -1072879442;
	public const HRESULT NS_E_DRM_UNABLE_TO_OPEN_PORT = -1072879441;
	public const HRESULT NS_E_DRM_BAD_REQUEST = -1072879440;
	public const HRESULT NS_E_DRM_INVALID_CRL = -1072879439;
	public const HRESULT NS_E_DRM_ATTRIBUTE_TOO_LONG = -1072879438;
	public const HRESULT NS_E_DRM_EXPIRED_LICENSEBLOB = -1072879437;
	public const HRESULT NS_E_DRM_INVALID_LICENSEBLOB = -1072879436;
	public const HRESULT NS_E_DRM_INCLUSION_LIST_REQUIRED = -1072879435;
	public const HRESULT NS_E_DRM_DRMV2CLT_REVOKED = -1072879434;
	public const HRESULT NS_E_DRM_RIV_TOO_SMALL = -1072879433;
	public const HRESULT NS_E_OUTPUT_PROTECTION_LEVEL_UNSUPPORTED = -1072879356;
	public const HRESULT NS_E_COMPRESSED_DIGITAL_VIDEO_PROTECTION_LEVEL_UNSUPPORTED = -1072879355;
	public const HRESULT NS_E_UNCOMPRESSED_DIGITAL_VIDEO_PROTECTION_LEVEL_UNSUPPORTED = -1072879354;
	public const HRESULT NS_E_ANALOG_VIDEO_PROTECTION_LEVEL_UNSUPPORTED = -1072879353;
	public const HRESULT NS_E_COMPRESSED_DIGITAL_AUDIO_PROTECTION_LEVEL_UNSUPPORTED = -1072879352;
	public const HRESULT NS_E_UNCOMPRESSED_DIGITAL_AUDIO_PROTECTION_LEVEL_UNSUPPORTED = -1072879351;
	public const HRESULT NS_E_OUTPUT_PROTECTION_SCHEME_UNSUPPORTED = -1072879350;
	public const HRESULT NS_S_REBOOT_RECOMMENDED = 862968;
	public const HRESULT NS_S_REBOOT_REQUIRED = 862969;
	public const HRESULT NS_E_REBOOT_RECOMMENDED = -1072878854;
	public const HRESULT NS_E_REBOOT_REQUIRED = -1072878853;
	public const HRESULT NS_E_SETUP_INCOMPLETE = -1072878852;
	public const HRESULT NS_E_SETUP_DRM_MIGRATION_FAILED = -1072878851;
	public const HRESULT NS_E_SETUP_IGNORABLE_FAILURE = -1072878850;
	public const HRESULT NS_E_SETUP_DRM_MIGRATION_FAILED_AND_IGNORABLE_FAILURE = -1072878849;
	public const HRESULT NS_E_SETUP_BLOCKED = -1072878848;
	public const HRESULT NS_E_UNKNOWN_PROTOCOL = -1072877856;
	public const HRESULT NS_E_REDIRECT_TO_PROXY = -1072877855;
	public const HRESULT NS_E_INTERNAL_SERVER_ERROR = -1072877854;
	public const HRESULT NS_E_BAD_REQUEST = -1072877853;
	public const HRESULT NS_E_ERROR_FROM_PROXY = -1072877852;
	public const HRESULT NS_E_PROXY_TIMEOUT = -1072877851;
	public const HRESULT NS_E_SERVER_UNAVAILABLE = -1072877850;
	public const HRESULT NS_E_REFUSED_BY_SERVER = -1072877849;
	public const HRESULT NS_E_INCOMPATIBLE_SERVER = -1072877848;
	public const HRESULT NS_E_MULTICAST_DISABLED = -1072877847;
	public const HRESULT NS_E_INVALID_REDIRECT = -1072877846;
	public const HRESULT NS_E_ALL_PROTOCOLS_DISABLED = -1072877845;
	public const HRESULT NS_E_MSBD_NO_LONGER_SUPPORTED = -1072877844;
	public const HRESULT NS_E_PROXY_NOT_FOUND = -1072877843;
	public const HRESULT NS_E_CANNOT_CONNECT_TO_PROXY = -1072877842;
	public const HRESULT NS_E_SERVER_DNS_TIMEOUT = -1072877841;
	public const HRESULT NS_E_PROXY_DNS_TIMEOUT = -1072877840;
	public const HRESULT NS_E_CLOSED_ON_SUSPEND = -1072877839;
	public const HRESULT NS_E_CANNOT_READ_PLAYLIST_FROM_MEDIASERVER = -1072877838;
	public const HRESULT NS_E_SESSION_NOT_FOUND = -1072877837;
	public const HRESULT NS_E_REQUIRE_STREAMING_CLIENT = -1072877836;
	public const HRESULT NS_E_PLAYLIST_ENTRY_HAS_CHANGED = -1072877835;
	public const HRESULT NS_E_PROXY_ACCESSDENIED = -1072877834;
	public const HRESULT NS_E_PROXY_SOURCE_ACCESSDENIED = -1072877833;
	public const HRESULT NS_E_NETWORK_SINK_WRITE = -1072877832;
	public const HRESULT NS_E_FIREWALL = -1072877831;
	public const HRESULT NS_E_MMS_NOT_SUPPORTED = -1072877830;
	public const HRESULT NS_E_SERVER_ACCESSDENIED = -1072877829;
	public const HRESULT NS_E_RESOURCE_GONE = -1072877828;
	public const HRESULT NS_E_NO_EXISTING_PACKETIZER = -1072877827;
	public const HRESULT NS_E_BAD_SYNTAX_IN_SERVER_RESPONSE = -1072877826;
	public const HRESULT NS_I_RECONNECTED = 1074605823;
	public const HRESULT NS_E_RESET_SOCKET_CONNECTION = -1072877824;
	public const HRESULT NS_I_NOLOG_STOP = 1074605825;
	public const HRESULT NS_E_TOO_MANY_HOPS = -1072877822;
	public const HRESULT NS_I_EXISTING_PACKETIZER = 1074605827;
	public const HRESULT NS_I_MANUAL_PROXY = 1074605828;
	public const HRESULT NS_E_TOO_MUCH_DATA_FROM_SERVER = -1072877819;
	public const HRESULT NS_E_CONNECT_TIMEOUT = -1072877818;
	public const HRESULT NS_E_PROXY_CONNECT_TIMEOUT = -1072877817;
	public const HRESULT NS_E_SESSION_INVALID = -1072877816;
	public const HRESULT NS_S_EOSRECEDING = 864009;
	public const HRESULT NS_E_PACKETSINK_UNKNOWN_FEC_STREAM = -1072877814;
	public const HRESULT NS_E_PUSH_CANNOTCONNECT = -1072877813;
	public const HRESULT NS_E_INCOMPATIBLE_PUSH_SERVER = -1072877812;
	public const HRESULT NS_S_CHANGENOTICE = 864013;
	public const HRESULT NS_E_END_OF_PLAYLIST = -1072876856;
	public const HRESULT NS_E_USE_FILE_SOURCE = -1072876855;
	public const HRESULT NS_E_PROPERTY_NOT_FOUND = -1072876854;
	public const HRESULT NS_E_PROPERTY_READ_ONLY = -1072876852;
	public const HRESULT NS_E_TABLE_KEY_NOT_FOUND = -1072876851;
	public const HRESULT NS_E_INVALID_QUERY_OPERATOR = -1072876849;
	public const HRESULT NS_E_INVALID_QUERY_PROPERTY = -1072876848;
	public const HRESULT NS_E_PROPERTY_NOT_SUPPORTED = -1072876846;
	public const HRESULT NS_E_SCHEMA_CLASSIFY_FAILURE = -1072876844;
	public const HRESULT NS_E_METADATA_FORMAT_NOT_SUPPORTED = -1072876843;
	public const HRESULT NS_E_METADATA_NO_EDITING_CAPABILITY = -1072876842;
	public const HRESULT NS_E_METADATA_CANNOT_SET_LOCALE = -1072876841;
	public const HRESULT NS_E_METADATA_LANGUAGE_NOT_SUPORTED = -1072876840;
	public const HRESULT NS_E_METADATA_NO_RFC1766_NAME_FOR_LOCALE = -1072876839;
	public const HRESULT NS_E_METADATA_NOT_AVAILABLE = -1072876838;
	public const HRESULT NS_E_METADATA_CACHE_DATA_NOT_AVAILABLE = -1072876837;
	public const HRESULT NS_E_METADATA_INVALID_DOCUMENT_TYPE = -1072876836;
	public const HRESULT NS_E_METADATA_IDENTIFIER_NOT_AVAILABLE = -1072876835;
	public const HRESULT NS_E_METADATA_CANNOT_RETRIEVE_FROM_OFFLINE_CACHE = -1072876834;
	public const uint32 VFW_HIDE_SETTINGS_PAGE = 1;
	public const uint32 VFW_HIDE_VIDEOSRC_PAGE = 2;
	public const uint32 VFW_HIDE_CAMERACONTROL_PAGE = 4;
	public const uint32 VFW_OEM_ADD_PAGE = 2147483648;
	public const uint32 VFW_USE_DEVICE_HANDLE = 1;
	public const uint32 VFW_USE_STREAM_HANDLE = 2;
	public const uint32 VFW_QUERY_DEV_CHANGED = 256;
	public const String TARGET_DEVICE_FRIENDLY_NAME = "TargetDeviceFriendlyName";
	public const String TARGET_DEVICE_OPEN_EXCLUSIVELY = "TargetDeviceOpenExclusively";
	public const uint32 MCIERR_INVALID_DEVICE_ID = 257;
	public const uint32 MCIERR_UNRECOGNIZED_KEYWORD = 259;
	public const uint32 MCIERR_UNRECOGNIZED_COMMAND = 261;
	public const uint32 MCIERR_HARDWARE = 262;
	public const uint32 MCIERR_INVALID_DEVICE_NAME = 263;
	public const uint32 MCIERR_OUT_OF_MEMORY = 264;
	public const uint32 MCIERR_DEVICE_OPEN = 265;
	public const uint32 MCIERR_CANNOT_LOAD_DRIVER = 266;
	public const uint32 MCIERR_MISSING_COMMAND_STRING = 267;
	public const uint32 MCIERR_PARAM_OVERFLOW = 268;
	public const uint32 MCIERR_MISSING_STRING_ARGUMENT = 269;
	public const uint32 MCIERR_BAD_INTEGER = 270;
	public const uint32 MCIERR_PARSER_INTERNAL = 271;
	public const uint32 MCIERR_DRIVER_INTERNAL = 272;
	public const uint32 MCIERR_MISSING_PARAMETER = 273;
	public const uint32 MCIERR_UNSUPPORTED_FUNCTION = 274;
	public const uint32 MCIERR_FILE_NOT_FOUND = 275;
	public const uint32 MCIERR_DEVICE_NOT_READY = 276;
	public const uint32 MCIERR_INTERNAL = 277;
	public const uint32 MCIERR_DRIVER = 278;
	public const uint32 MCIERR_CANNOT_USE_ALL = 279;
	public const uint32 MCIERR_MULTIPLE = 280;
	public const uint32 MCIERR_EXTENSION_NOT_FOUND = 281;
	public const uint32 MCIERR_OUTOFRANGE = 282;
	public const uint32 MCIERR_FLAGS_NOT_COMPATIBLE = 284;
	public const uint32 MCIERR_FILE_NOT_SAVED = 286;
	public const uint32 MCIERR_DEVICE_TYPE_REQUIRED = 287;
	public const uint32 MCIERR_DEVICE_LOCKED = 288;
	public const uint32 MCIERR_DUPLICATE_ALIAS = 289;
	public const uint32 MCIERR_BAD_CONSTANT = 290;
	public const uint32 MCIERR_MUST_USE_SHAREABLE = 291;
	public const uint32 MCIERR_MISSING_DEVICE_NAME = 292;
	public const uint32 MCIERR_BAD_TIME_FORMAT = 293;
	public const uint32 MCIERR_NO_CLOSING_QUOTE = 294;
	public const uint32 MCIERR_DUPLICATE_FLAGS = 295;
	public const uint32 MCIERR_INVALID_FILE = 296;
	public const uint32 MCIERR_NULL_PARAMETER_BLOCK = 297;
	public const uint32 MCIERR_UNNAMED_RESOURCE = 298;
	public const uint32 MCIERR_NEW_REQUIRES_ALIAS = 299;
	public const uint32 MCIERR_NOTIFY_ON_AUTO_OPEN = 300;
	public const uint32 MCIERR_NO_ELEMENT_ALLOWED = 301;
	public const uint32 MCIERR_NONAPPLICABLE_FUNCTION = 302;
	public const uint32 MCIERR_ILLEGAL_FOR_AUTO_OPEN = 303;
	public const uint32 MCIERR_FILENAME_REQUIRED = 304;
	public const uint32 MCIERR_EXTRA_CHARACTERS = 305;
	public const uint32 MCIERR_DEVICE_NOT_INSTALLED = 306;
	public const uint32 MCIERR_GET_CD = 307;
	public const uint32 MCIERR_SET_CD = 308;
	public const uint32 MCIERR_SET_DRIVE = 309;
	public const uint32 MCIERR_DEVICE_LENGTH = 310;
	public const uint32 MCIERR_DEVICE_ORD_LENGTH = 311;
	public const uint32 MCIERR_NO_INTEGER = 312;
	public const uint32 MCIERR_WAVE_OUTPUTSINUSE = 320;
	public const uint32 MCIERR_WAVE_SETOUTPUTINUSE = 321;
	public const uint32 MCIERR_WAVE_INPUTSINUSE = 322;
	public const uint32 MCIERR_WAVE_SETINPUTINUSE = 323;
	public const uint32 MCIERR_WAVE_OUTPUTUNSPECIFIED = 324;
	public const uint32 MCIERR_WAVE_INPUTUNSPECIFIED = 325;
	public const uint32 MCIERR_WAVE_OUTPUTSUNSUITABLE = 326;
	public const uint32 MCIERR_WAVE_SETOUTPUTUNSUITABLE = 327;
	public const uint32 MCIERR_WAVE_INPUTSUNSUITABLE = 328;
	public const uint32 MCIERR_WAVE_SETINPUTUNSUITABLE = 329;
	public const uint32 MCIERR_SEQ_DIV_INCOMPATIBLE = 336;
	public const uint32 MCIERR_SEQ_PORT_INUSE = 337;
	public const uint32 MCIERR_SEQ_PORT_NONEXISTENT = 338;
	public const uint32 MCIERR_SEQ_PORT_MAPNODEVICE = 339;
	public const uint32 MCIERR_SEQ_PORT_MISCERROR = 340;
	public const uint32 MCIERR_SEQ_TIMER = 341;
	public const uint32 MCIERR_SEQ_PORTUNSPECIFIED = 342;
	public const uint32 MCIERR_SEQ_NOMIDIPRESENT = 343;
	public const uint32 MCIERR_NO_WINDOW = 346;
	public const uint32 MCIERR_CREATEWINDOW = 347;
	public const uint32 MCIERR_FILE_READ = 348;
	public const uint32 MCIERR_FILE_WRITE = 349;
	public const uint32 MCIERR_NO_IDENTITY = 350;
	public const uint32 MCIERR_CUSTOM_DRIVER_BASE = 512;
	public const uint32 MCI_FIRST = 2048;
	public const uint32 MCI_ESCAPE = 2053;
	public const uint32 MCI_INFO = 2058;
	public const uint32 MCI_GETDEVCAPS = 2059;
	public const uint32 MCI_SPIN = 2060;
	public const uint32 MCI_SET = 2061;
	public const uint32 MCI_SYSINFO = 2064;
	public const uint32 MCI_BREAK = 2065;
	public const uint32 MCI_STATUS = 2068;
	public const uint32 MCI_CUE = 2096;
	public const uint32 MCI_REALIZE = 2112;
	public const uint32 MCI_WINDOW = 2113;
	public const uint32 MCI_PUT = 2114;
	public const uint32 MCI_WHERE = 2115;
	public const uint32 MCI_FREEZE = 2116;
	public const uint32 MCI_UNFREEZE = 2117;
	public const uint32 MCI_LOAD = 2128;
	public const uint32 MCI_UPDATE = 2132;
	public const uint32 MCI_USER_MESSAGES = 3072;
	public const uint32 MCI_LAST = 4095;
	public const uint32 MCI_DEVTYPE_VCR = 513;
	public const uint32 MCI_DEVTYPE_VIDEODISC = 514;
	public const uint32 MCI_DEVTYPE_OVERLAY = 515;
	public const uint32 MCI_DEVTYPE_CD_AUDIO = 516;
	public const uint32 MCI_DEVTYPE_DAT = 517;
	public const uint32 MCI_DEVTYPE_SCANNER = 518;
	public const uint32 MCI_DEVTYPE_ANIMATION = 519;
	public const uint32 MCI_DEVTYPE_DIGITAL_VIDEO = 520;
	public const uint32 MCI_DEVTYPE_OTHER = 521;
	public const uint32 MCI_DEVTYPE_WAVEFORM_AUDIO = 522;
	public const uint32 MCI_DEVTYPE_SEQUENCER = 523;
	public const uint32 MCI_DEVTYPE_FIRST = 513;
	public const uint32 MCI_DEVTYPE_LAST = 523;
	public const uint32 MCI_DEVTYPE_FIRST_USER = 4096;
	public const uint32 MCI_FORMAT_MILLISECONDS = 0;
	public const uint32 MCI_FORMAT_HMS = 1;
	public const uint32 MCI_FORMAT_MSF = 2;
	public const uint32 MCI_FORMAT_FRAMES = 3;
	public const uint32 MCI_FORMAT_SMPTE_24 = 4;
	public const uint32 MCI_FORMAT_SMPTE_25 = 5;
	public const uint32 MCI_FORMAT_SMPTE_30 = 6;
	public const uint32 MCI_FORMAT_SMPTE_30DROP = 7;
	public const uint32 MCI_FORMAT_BYTES = 8;
	public const uint32 MCI_FORMAT_SAMPLES = 9;
	public const uint32 MCI_FORMAT_TMSF = 10;
	public const uint32 MCI_NOTIFY_SUCCESSFUL = 1;
	public const uint32 MCI_NOTIFY_SUPERSEDED = 2;
	public const uint32 MCI_NOTIFY_ABORTED = 4;
	public const uint32 MCI_NOTIFY_FAILURE = 8;
	public const int32 MCI_NOTIFY = 1;
	public const int32 MCI_WAIT = 2;
	public const int32 MCI_FROM = 4;
	public const int32 MCI_TO = 8;
	public const int32 MCI_TRACK = 16;
	public const int32 MCI_OPEN_SHAREABLE = 256;
	public const int32 MCI_OPEN_ELEMENT = 512;
	public const int32 MCI_OPEN_ALIAS = 1024;
	public const int32 MCI_OPEN_ELEMENT_ID = 2048;
	public const int32 MCI_OPEN_TYPE_ID = 4096;
	public const int32 MCI_OPEN_TYPE = 8192;
	public const int32 MCI_SEEK_TO_START = 256;
	public const int32 MCI_SEEK_TO_END = 512;
	public const int32 MCI_STATUS_ITEM = 256;
	public const int32 MCI_STATUS_START = 512;
	public const int32 MCI_STATUS_LENGTH = 1;
	public const int32 MCI_STATUS_POSITION = 2;
	public const int32 MCI_STATUS_NUMBER_OF_TRACKS = 3;
	public const int32 MCI_STATUS_MODE = 4;
	public const int32 MCI_STATUS_MEDIA_PRESENT = 5;
	public const int32 MCI_STATUS_TIME_FORMAT = 6;
	public const int32 MCI_STATUS_READY = 7;
	public const int32 MCI_STATUS_CURRENT_TRACK = 8;
	public const int32 MCI_INFO_PRODUCT = 256;
	public const int32 MCI_INFO_FILE = 512;
	public const int32 MCI_INFO_MEDIA_UPC = 1024;
	public const int32 MCI_INFO_MEDIA_IDENTITY = 2048;
	public const int32 MCI_INFO_NAME = 4096;
	public const int32 MCI_INFO_COPYRIGHT = 8192;
	public const int32 MCI_GETDEVCAPS_ITEM = 256;
	public const int32 MCI_GETDEVCAPS_CAN_RECORD = 1;
	public const int32 MCI_GETDEVCAPS_HAS_AUDIO = 2;
	public const int32 MCI_GETDEVCAPS_HAS_VIDEO = 3;
	public const int32 MCI_GETDEVCAPS_DEVICE_TYPE = 4;
	public const int32 MCI_GETDEVCAPS_USES_FILES = 5;
	public const int32 MCI_GETDEVCAPS_COMPOUND_DEVICE = 6;
	public const int32 MCI_GETDEVCAPS_CAN_EJECT = 7;
	public const int32 MCI_GETDEVCAPS_CAN_PLAY = 8;
	public const int32 MCI_GETDEVCAPS_CAN_SAVE = 9;
	public const int32 MCI_SYSINFO_QUANTITY = 256;
	public const int32 MCI_SYSINFO_OPEN = 512;
	public const int32 MCI_SYSINFO_NAME = 1024;
	public const int32 MCI_SYSINFO_INSTALLNAME = 2048;
	public const int32 MCI_SET_DOOR_OPEN = 256;
	public const int32 MCI_SET_DOOR_CLOSED = 512;
	public const int32 MCI_SET_TIME_FORMAT = 1024;
	public const int32 MCI_SET_AUDIO = 2048;
	public const int32 MCI_SET_VIDEO = 4096;
	public const int32 MCI_SET_ON = 8192;
	public const int32 MCI_SET_OFF = 16384;
	public const int32 MCI_SET_AUDIO_ALL = 0;
	public const int32 MCI_SET_AUDIO_LEFT = 1;
	public const int32 MCI_SET_AUDIO_RIGHT = 2;
	public const int32 MCI_BREAK_KEY = 256;
	public const int32 MCI_BREAK_HWND = 512;
	public const int32 MCI_BREAK_OFF = 1024;
	public const int32 MCI_RECORD_INSERT = 256;
	public const int32 MCI_RECORD_OVERWRITE = 512;
	public const int32 MCI_SAVE_FILE = 256;
	public const int32 MCI_LOAD_FILE = 256;
	public const uint32 MCI_VD_MODE_PARK = 1025;
	public const uint32 MCI_VD_MEDIA_CLV = 1026;
	public const uint32 MCI_VD_MEDIA_CAV = 1027;
	public const uint32 MCI_VD_MEDIA_OTHER = 1028;
	public const uint32 MCI_VD_FORMAT_TRACK = 16385;
	public const int32 MCI_VD_PLAY_REVERSE = 65536;
	public const int32 MCI_VD_PLAY_FAST = 131072;
	public const int32 MCI_VD_PLAY_SPEED = 262144;
	public const int32 MCI_VD_PLAY_SCAN = 524288;
	public const int32 MCI_VD_PLAY_SLOW = 1048576;
	public const int32 MCI_VD_SEEK_REVERSE = 65536;
	public const int32 MCI_VD_STATUS_SPEED = 16386;
	public const int32 MCI_VD_STATUS_FORWARD = 16387;
	public const int32 MCI_VD_STATUS_MEDIA_TYPE = 16388;
	public const int32 MCI_VD_STATUS_SIDE = 16389;
	public const int32 MCI_VD_STATUS_DISC_SIZE = 16390;
	public const int32 MCI_VD_GETDEVCAPS_CLV = 65536;
	public const int32 MCI_VD_GETDEVCAPS_CAV = 131072;
	public const int32 MCI_VD_SPIN_UP = 65536;
	public const int32 MCI_VD_SPIN_DOWN = 131072;
	public const int32 MCI_VD_GETDEVCAPS_CAN_REVERSE = 16386;
	public const int32 MCI_VD_GETDEVCAPS_FAST_RATE = 16387;
	public const int32 MCI_VD_GETDEVCAPS_SLOW_RATE = 16388;
	public const int32 MCI_VD_GETDEVCAPS_NORMAL_RATE = 16389;
	public const int32 MCI_VD_STEP_FRAMES = 65536;
	public const int32 MCI_VD_STEP_REVERSE = 131072;
	public const int32 MCI_VD_ESCAPE_STRING = 256;
	public const int32 MCI_CDA_STATUS_TYPE_TRACK = 16385;
	public const uint32 MCI_CDA_TRACK_AUDIO = 1088;
	public const uint32 MCI_CDA_TRACK_OTHER = 1089;
	public const uint32 MCI_WAVE_PCM = 1152;
	public const uint32 MCI_WAVE_MAPPER = 1153;
	public const int32 MCI_WAVE_OPEN_BUFFER = 65536;
	public const int32 MCI_WAVE_SET_FORMATTAG = 65536;
	public const int32 MCI_WAVE_SET_CHANNELS = 131072;
	public const int32 MCI_WAVE_SET_SAMPLESPERSEC = 262144;
	public const int32 MCI_WAVE_SET_AVGBYTESPERSEC = 524288;
	public const int32 MCI_WAVE_SET_BLOCKALIGN = 1048576;
	public const int32 MCI_WAVE_SET_BITSPERSAMPLE = 2097152;
	public const int32 MCI_WAVE_INPUT = 4194304;
	public const int32 MCI_WAVE_OUTPUT = 8388608;
	public const int32 MCI_WAVE_STATUS_FORMATTAG = 16385;
	public const int32 MCI_WAVE_STATUS_CHANNELS = 16386;
	public const int32 MCI_WAVE_STATUS_SAMPLESPERSEC = 16387;
	public const int32 MCI_WAVE_STATUS_AVGBYTESPERSEC = 16388;
	public const int32 MCI_WAVE_STATUS_BLOCKALIGN = 16389;
	public const int32 MCI_WAVE_STATUS_BITSPERSAMPLE = 16390;
	public const int32 MCI_WAVE_STATUS_LEVEL = 16391;
	public const int32 MCI_WAVE_SET_ANYINPUT = 67108864;
	public const int32 MCI_WAVE_SET_ANYOUTPUT = 134217728;
	public const int32 MCI_WAVE_GETDEVCAPS_INPUTS = 16385;
	public const int32 MCI_WAVE_GETDEVCAPS_OUTPUTS = 16386;
	public const uint32 MCI_SEQ_FORMAT_SONGPTR = 16385;
	public const uint32 MCI_SEQ_FILE = 16386;
	public const uint32 MCI_SEQ_MIDI = 16387;
	public const uint32 MCI_SEQ_SMPTE = 16388;
	public const uint32 MCI_SEQ_NONE = 65533;
	public const uint32 MCI_SEQ_MAPPER = 65535;
	public const int32 MCI_SEQ_STATUS_TEMPO = 16386;
	public const int32 MCI_SEQ_STATUS_PORT = 16387;
	public const int32 MCI_SEQ_STATUS_SLAVE = 16391;
	public const int32 MCI_SEQ_STATUS_MASTER = 16392;
	public const int32 MCI_SEQ_STATUS_OFFSET = 16393;
	public const int32 MCI_SEQ_STATUS_DIVTYPE = 16394;
	public const int32 MCI_SEQ_STATUS_NAME = 16395;
	public const int32 MCI_SEQ_STATUS_COPYRIGHT = 16396;
	public const int32 MCI_SEQ_SET_TEMPO = 65536;
	public const int32 MCI_SEQ_SET_PORT = 131072;
	public const int32 MCI_SEQ_SET_SLAVE = 262144;
	public const int32 MCI_SEQ_SET_MASTER = 524288;
	public const int32 MCI_SEQ_SET_OFFSET = 16777216;
	public const int32 MCI_ANIM_OPEN_WS = 65536;
	public const int32 MCI_ANIM_OPEN_PARENT = 131072;
	public const int32 MCI_ANIM_OPEN_NOSTATIC = 262144;
	public const int32 MCI_ANIM_PLAY_SPEED = 65536;
	public const int32 MCI_ANIM_PLAY_REVERSE = 131072;
	public const int32 MCI_ANIM_PLAY_FAST = 262144;
	public const int32 MCI_ANIM_PLAY_SLOW = 524288;
	public const int32 MCI_ANIM_PLAY_SCAN = 1048576;
	public const int32 MCI_ANIM_STEP_REVERSE = 65536;
	public const int32 MCI_ANIM_STEP_FRAMES = 131072;
	public const int32 MCI_ANIM_STATUS_SPEED = 16385;
	public const int32 MCI_ANIM_STATUS_FORWARD = 16386;
	public const int32 MCI_ANIM_STATUS_HWND = 16387;
	public const int32 MCI_ANIM_STATUS_HPAL = 16388;
	public const int32 MCI_ANIM_STATUS_STRETCH = 16389;
	public const int32 MCI_ANIM_INFO_TEXT = 65536;
	public const int32 MCI_ANIM_GETDEVCAPS_CAN_REVERSE = 16385;
	public const int32 MCI_ANIM_GETDEVCAPS_FAST_RATE = 16386;
	public const int32 MCI_ANIM_GETDEVCAPS_SLOW_RATE = 16387;
	public const int32 MCI_ANIM_GETDEVCAPS_NORMAL_RATE = 16388;
	public const int32 MCI_ANIM_GETDEVCAPS_PALETTES = 16390;
	public const int32 MCI_ANIM_GETDEVCAPS_CAN_STRETCH = 16391;
	public const int32 MCI_ANIM_GETDEVCAPS_MAX_WINDOWS = 16392;
	public const int32 MCI_ANIM_REALIZE_NORM = 65536;
	public const int32 MCI_ANIM_REALIZE_BKGD = 131072;
	public const int32 MCI_ANIM_WINDOW_HWND = 65536;
	public const int32 MCI_ANIM_WINDOW_STATE = 262144;
	public const int32 MCI_ANIM_WINDOW_TEXT = 524288;
	public const int32 MCI_ANIM_WINDOW_ENABLE_STRETCH = 1048576;
	public const int32 MCI_ANIM_WINDOW_DISABLE_STRETCH = 2097152;
	public const int32 MCI_ANIM_WINDOW_DEFAULT = 0;
	public const int32 MCI_ANIM_RECT = 65536;
	public const int32 MCI_ANIM_PUT_SOURCE = 131072;
	public const int32 MCI_ANIM_PUT_DESTINATION = 262144;
	public const int32 MCI_ANIM_WHERE_SOURCE = 131072;
	public const int32 MCI_ANIM_WHERE_DESTINATION = 262144;
	public const int32 MCI_ANIM_UPDATE_HDC = 131072;
	public const int32 MCI_OVLY_OPEN_WS = 65536;
	public const int32 MCI_OVLY_OPEN_PARENT = 131072;
	public const int32 MCI_OVLY_STATUS_HWND = 16385;
	public const int32 MCI_OVLY_STATUS_STRETCH = 16386;
	public const int32 MCI_OVLY_INFO_TEXT = 65536;
	public const int32 MCI_OVLY_GETDEVCAPS_CAN_STRETCH = 16385;
	public const int32 MCI_OVLY_GETDEVCAPS_CAN_FREEZE = 16386;
	public const int32 MCI_OVLY_GETDEVCAPS_MAX_WINDOWS = 16387;
	public const int32 MCI_OVLY_WINDOW_HWND = 65536;
	public const int32 MCI_OVLY_WINDOW_STATE = 262144;
	public const int32 MCI_OVLY_WINDOW_TEXT = 524288;
	public const int32 MCI_OVLY_WINDOW_ENABLE_STRETCH = 1048576;
	public const int32 MCI_OVLY_WINDOW_DISABLE_STRETCH = 2097152;
	public const int32 MCI_OVLY_WINDOW_DEFAULT = 0;
	public const int32 MCI_OVLY_RECT = 65536;
	public const int32 MCI_OVLY_PUT_SOURCE = 131072;
	public const int32 MCI_OVLY_PUT_DESTINATION = 262144;
	public const int32 MCI_OVLY_PUT_FRAME = 524288;
	public const int32 MCI_OVLY_PUT_VIDEO = 1048576;
	public const int32 MCI_OVLY_WHERE_SOURCE = 131072;
	public const int32 MCI_OVLY_WHERE_DESTINATION = 262144;
	public const int32 MCI_OVLY_WHERE_FRAME = 524288;
	public const int32 MCI_OVLY_WHERE_VIDEO = 1048576;
}
#endregion

#region TypeDefs
typealias HMMIO = int;

typealias HDRVR = int;

typealias HIC = int;

typealias HVIDEO = int;

#endregion

#region Function Pointers
public function uint32 YIELDPROC(uint32 mciId, uint32 dwYieldData);

public function LRESULT DRIVERPROC(uint param0, HDRVR param1, uint32 param2, LPARAM param3, LPARAM param4);

public function uint32 DRIVERMSGPROC(uint32 param0, uint32 param1, uint param2, uint param3, uint param4);

public function LRESULT LPMMIOPROC(PSTR lpmmioinfo, uint32 uMsg, LPARAM lParam1, LPARAM lParam2);

public function BOOL AVISAVECALLBACK(int32 param0);

public function LRESULT CAPYIELDCALLBACK(HWND hWnd);

public function LRESULT CAPSTATUSCALLBACKW(HWND hWnd, int32 nID, PWSTR lpsz);

public function LRESULT CAPERRORCALLBACKW(HWND hWnd, int32 nID, PWSTR lpsz);

public function LRESULT CAPSTATUSCALLBACKA(HWND hWnd, int32 nID, PSTR lpsz);

public function LRESULT CAPERRORCALLBACKA(HWND hWnd, int32 nID, PSTR lpsz);

public function LRESULT CAPVIDEOCALLBACK(HWND hWnd, VIDEOHDR* lpVHdr);

public function LRESULT CAPWAVECALLBACK(HWND hWnd, WAVEHDR* lpWHdr);

public function LRESULT CAPCONTROLCALLBACK(HWND hWnd, int32 nState);

public function void LPTASKCALLBACK(uint dwInst);

public function uint32 VFWWDMExtensionProc(void* pfnDeviceIoControl, LPFNSVADDPROPSHEETPAGE pfnAddPropertyPage, LPARAM lParam);

public function BOOL LPFNEXTDEVIO(LPARAM lParam, uint32 dwFlags, uint32 dwIoControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned, OVERLAPPED* lpOverlapped);

#endregion

#region Structs
[CRepr, Packed(1)]
public struct ADPCMCOEFSET
{
	public int16 iCoef1;
	public int16 iCoef2;
}

[CRepr, Packed(1)]
public struct ADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
	public uint16 wNumCoef;
	public ADPCMCOEFSET* aCoef mut => &aCoef_impl;
	private ADPCMCOEFSET[ANYSIZE_ARRAY] aCoef_impl;
}

[CRepr, Packed(1)]
public struct DRMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wReserved;
	public uint32 ulContentId;
	public WAVEFORMATEX wfxSecure;
}

[CRepr, Packed(1)]
public struct DVIADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct IMAADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct MEDIASPACEADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
}

[CRepr, Packed(1)]
public struct SIERRAADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
}

[CRepr, Packed(1)]
public struct G723_ADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 cbExtraSize;
	public uint16 nAuxBlockSize;
}

[CRepr, Packed(1)]
public struct DIGISTDWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct DIGIFIXWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct DIALOGICOKIADPCMWAVEFORMAT
{
	public WAVEFORMATEX ewf;
}

[CRepr, Packed(1)]
public struct YAMAHA_ADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct SONARCWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wCompType;
}

[CRepr, Packed(1)]
public struct TRUESPEECHWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
	public uint16 nSamplesPerBlock;
	public uint8[28] abReserved;
}

[CRepr, Packed(1)]
public struct ECHOSC1WAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct AUDIOFILE_AF36WAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct APTXWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct AUDIOFILE_AF10WAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct DOLBYAC2WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 nAuxBitsCode;
}

[CRepr, Packed(1)]
public struct GSM610WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct ADPCMEWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct CONTRESVQLPCWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct DIGIREALWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct DIGIADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct CONTRESCR10WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct NMS_VBXADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
}

[CRepr, Packed(1)]
public struct G721_ADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 nAuxBlockSize;
}

[CRepr, Packed(1)]
public struct MSAUDIO1WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wSamplesPerBlock;
	public uint16 wEncodeOptions;
}

[CRepr, Packed(1)]
public struct WMAUDIO2WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint32 dwSamplesPerBlock;
	public uint16 wEncodeOptions;
	public uint32 dwSuperBlockAlign;
}

[CRepr, Packed(1)]
public struct WMAUDIO3WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wValidBitsPerSample;
	public uint32 dwChannelMask;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint16 wEncodeOptions;
	public uint16 wReserved3;
}

[CRepr, Packed(1)]
public struct CREATIVEADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
}

[CRepr, Packed(1)]
public struct CREATIVEFASTSPEECH8WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
}

[CRepr, Packed(1)]
public struct CREATIVEFASTSPEECH10WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
}

[CRepr, Packed(1)]
public struct FMTOWNS_SND_WAVEFORMAT
{
	public WAVEFORMATEX wfx;
	public uint16 wRevision;
}

[CRepr, Packed(1)]
public struct OLIGSMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct OLIADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct OLICELPWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct OLISBCWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct OLIOPRWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr, Packed(1)]
public struct CSIMAADPCMWAVEFORMAT
{
	public WAVEFORMATEX wfx;
}

[CRepr]
public struct s_RIFFWAVE_inst
{
	public uint8 bUnshiftedNote;
	public CHAR chFineTune;
	public CHAR chGain;
	public uint8 bLowNote;
	public uint8 bHighNote;
	public uint8 bLowVelocity;
	public uint8 bHighVelocity;
}

[CRepr, Packed(1)]
public struct EXBMINFOHEADER
{
	public BITMAPINFOHEADER bmi;
	public uint32 biExtDataOffset;
}

[CRepr, Packed(1)]
public struct JPEGINFOHEADER
{
	public uint32 JPEGSize;
	public uint32 JPEGProcess;
	public uint32 JPEGColorSpaceID;
	public uint32 JPEGBitsPerSample;
	public uint32 JPEGHSubSampling;
	public uint32 JPEGVSubSampling;
}

[CRepr, Packed(1)]
public struct MCI_GENERIC_PARMS
{
	public uint dwCallback;
}

[CRepr, Packed(1)]
public struct MCI_OPEN_PARMSA
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PSTR lpstrDeviceType;
	public PSTR lpstrElementName;
	public PSTR lpstrAlias;
}

[CRepr, Packed(1)]
public struct MCI_OPEN_PARMSW
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PWSTR lpstrDeviceType;
	public PWSTR lpstrElementName;
	public PWSTR lpstrAlias;
}

[CRepr, Packed(1)]
public struct MCI_PLAY_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
}

[CRepr, Packed(1)]
public struct MCI_SEEK_PARMS
{
	public uint dwCallback;
	public uint32 dwTo;
}

[CRepr, Packed(1)]
public struct MCI_STATUS_PARMS
{
	public uint dwCallback;
	public uint dwReturn;
	public uint32 dwItem;
	public uint32 dwTrack;
}

[CRepr, Packed(1)]
public struct MCI_INFO_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrReturn;
	public uint32 dwRetSize;
}

[CRepr, Packed(1)]
public struct MCI_INFO_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrReturn;
	public uint32 dwRetSize;
}

[CRepr, Packed(1)]
public struct MCI_GETDEVCAPS_PARMS
{
	public uint dwCallback;
	public uint32 dwReturn;
	public uint32 dwItem;
}

[CRepr, Packed(1)]
public struct MCI_SYSINFO_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrReturn;
	public uint32 dwRetSize;
	public uint32 dwNumber;
	public uint32 wDeviceType;
}

[CRepr, Packed(1)]
public struct MCI_SYSINFO_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrReturn;
	public uint32 dwRetSize;
	public uint32 dwNumber;
	public uint32 wDeviceType;
}

[CRepr, Packed(1)]
public struct MCI_SET_PARMS
{
	public uint dwCallback;
	public uint32 dwTimeFormat;
	public uint32 dwAudio;
}

[CRepr, Packed(1)]
public struct MCI_BREAK_PARMS
{
	public uint dwCallback;
	public int32 nVirtKey;
	public HWND hwndBreak;
}

[CRepr, Packed(1)]
public struct MCI_SAVE_PARMSA
{
	public uint dwCallback;
	public PSTR lpfilename;
}

[CRepr, Packed(1)]
public struct MCI_SAVE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpfilename;
}

[CRepr, Packed(1)]
public struct MCI_LOAD_PARMSA
{
	public uint dwCallback;
	public PSTR lpfilename;
}

[CRepr, Packed(1)]
public struct MCI_LOAD_PARMSW
{
	public uint dwCallback;
	public PWSTR lpfilename;
}

[CRepr, Packed(1)]
public struct MCI_RECORD_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
}

[CRepr, Packed(1)]
public struct MCI_VD_PLAY_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
	public uint32 dwSpeed;
}

[CRepr, Packed(1)]
public struct MCI_VD_STEP_PARMS
{
	public uint dwCallback;
	public uint32 dwFrames;
}

[CRepr, Packed(1)]
public struct MCI_VD_ESCAPE_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrCommand;
}

[CRepr, Packed(1)]
public struct MCI_VD_ESCAPE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrCommand;
}

[CRepr, Packed(1)]
public struct MCI_WAVE_OPEN_PARMSA
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PSTR lpstrDeviceType;
	public PSTR lpstrElementName;
	public PSTR lpstrAlias;
	public uint32 dwBufferSeconds;
}

[CRepr, Packed(1)]
public struct MCI_WAVE_OPEN_PARMSW
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PWSTR lpstrDeviceType;
	public PWSTR lpstrElementName;
	public PWSTR lpstrAlias;
	public uint32 dwBufferSeconds;
}

[CRepr, Packed(1)]
public struct MCI_WAVE_DELETE_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
}

[CRepr, Packed(1)]
public struct MCI_WAVE_SET_PARMS
{
	public uint dwCallback;
	public uint32 dwTimeFormat;
	public uint32 dwAudio;
	public uint32 wInput;
	public uint32 wOutput;
	public uint16 wFormatTag;
	public uint16 wReserved2;
	public uint16 nChannels;
	public uint16 wReserved3;
	public uint32 nSamplesPerSec;
	public uint32 nAvgBytesPerSec;
	public uint16 nBlockAlign;
	public uint16 wReserved4;
	public uint16 wBitsPerSample;
	public uint16 wReserved5;
}

[CRepr, Packed(1)]
public struct MCI_SEQ_SET_PARMS
{
	public uint dwCallback;
	public uint32 dwTimeFormat;
	public uint32 dwAudio;
	public uint32 dwTempo;
	public uint32 dwPort;
	public uint32 dwSlave;
	public uint32 dwMaster;
	public uint32 dwOffset;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_OPEN_PARMSA
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PSTR lpstrDeviceType;
	public PSTR lpstrElementName;
	public PSTR lpstrAlias;
	public uint32 dwStyle;
	public HWND hWndParent;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_OPEN_PARMSW
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PWSTR lpstrDeviceType;
	public PWSTR lpstrElementName;
	public PWSTR lpstrAlias;
	public uint32 dwStyle;
	public HWND hWndParent;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_PLAY_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
	public uint32 dwSpeed;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_STEP_PARMS
{
	public uint dwCallback;
	public uint32 dwFrames;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_WINDOW_PARMSA
{
	public uint dwCallback;
	public HWND hWnd;
	public uint32 nCmdShow;
	public PSTR lpstrText;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_WINDOW_PARMSW
{
	public uint dwCallback;
	public HWND hWnd;
	public uint32 nCmdShow;
	public PWSTR lpstrText;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_RECT_PARMS
{
	public uint dwCallback;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_ANIM_UPDATE_PARMS
{
	public uint dwCallback;
	public RECT rc;
	public HDC hDC;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_OPEN_PARMSA
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PSTR lpstrDeviceType;
	public PSTR lpstrElementName;
	public PSTR lpstrAlias;
	public uint32 dwStyle;
	public HWND hWndParent;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_OPEN_PARMSW
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PWSTR lpstrDeviceType;
	public PWSTR lpstrElementName;
	public PWSTR lpstrAlias;
	public uint32 dwStyle;
	public HWND hWndParent;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_WINDOW_PARMSA
{
	public uint dwCallback;
	public HWND hWnd;
	public uint32 nCmdShow;
	public PSTR lpstrText;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_WINDOW_PARMSW
{
	public uint dwCallback;
	public HWND hWnd;
	public uint32 nCmdShow;
	public PWSTR lpstrText;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_RECT_PARMS
{
	public uint dwCallback;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_SAVE_PARMSA
{
	public uint dwCallback;
	public PSTR lpfilename;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_SAVE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpfilename;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_LOAD_PARMSA
{
	public uint dwCallback;
	public PSTR lpfilename;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_OVLY_LOAD_PARMSW
{
	public uint dwCallback;
	public PWSTR lpfilename;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct DRVCONFIGINFOEX
{
	public uint32 dwDCISize;
	public PWSTR lpszDCISectionName;
	public PWSTR lpszDCIAliasName;
	public uint32 dnDevNode;
}

[CRepr, Packed(1)]
public struct DRVCONFIGINFO
{
	public uint32 dwDCISize;
	public PWSTR lpszDCISectionName;
	public PWSTR lpszDCIAliasName;
}

[CRepr, Packed(1)]
public struct MMIOINFO
{
	public uint32 dwFlags;
	public uint32 fccIOProc;
	public LPMMIOPROC pIOProc;
	public uint32 wErrorRet;
	public HTASK htask;
	public int32 cchBuffer;
	public int8* pchBuffer;
	public int8* pchNext;
	public int8* pchEndRead;
	public int8* pchEndWrite;
	public int32 lBufOffset;
	public int32 lDiskOffset;
	public uint32[3] adwInfo;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public HMMIO hmmio;
}

[CRepr, Packed(1)]
public struct MMCKINFO
{
	public uint32 ckid;
	public uint32 cksize;
	public uint32 fccType;
	public uint32 dwDataOffset;
	public uint32 dwFlags;
}

[CRepr, Packed(1)]
public struct JOYCAPSA
{
	public uint16 wMid;
	public uint16 wPid;
	public CHAR[32] szPname;
	public uint32 wXmin;
	public uint32 wXmax;
	public uint32 wYmin;
	public uint32 wYmax;
	public uint32 wZmin;
	public uint32 wZmax;
	public uint32 wNumButtons;
	public uint32 wPeriodMin;
	public uint32 wPeriodMax;
	public uint32 wRmin;
	public uint32 wRmax;
	public uint32 wUmin;
	public uint32 wUmax;
	public uint32 wVmin;
	public uint32 wVmax;
	public uint32 wCaps;
	public uint32 wMaxAxes;
	public uint32 wNumAxes;
	public uint32 wMaxButtons;
	public CHAR[32] szRegKey;
	public CHAR[260] szOEMVxD;
}

[CRepr, Packed(1)]
public struct JOYCAPSW
{
	public uint16 wMid;
	public uint16 wPid;
	public char16[32] szPname;
	public uint32 wXmin;
	public uint32 wXmax;
	public uint32 wYmin;
	public uint32 wYmax;
	public uint32 wZmin;
	public uint32 wZmax;
	public uint32 wNumButtons;
	public uint32 wPeriodMin;
	public uint32 wPeriodMax;
	public uint32 wRmin;
	public uint32 wRmax;
	public uint32 wUmin;
	public uint32 wUmax;
	public uint32 wVmin;
	public uint32 wVmax;
	public uint32 wCaps;
	public uint32 wMaxAxes;
	public uint32 wNumAxes;
	public uint32 wMaxButtons;
	public char16[32] szRegKey;
	public char16[260] szOEMVxD;
}

[CRepr, Packed(1)]
public struct JOYCAPS2A
{
	public uint16 wMid;
	public uint16 wPid;
	public CHAR[32] szPname;
	public uint32 wXmin;
	public uint32 wXmax;
	public uint32 wYmin;
	public uint32 wYmax;
	public uint32 wZmin;
	public uint32 wZmax;
	public uint32 wNumButtons;
	public uint32 wPeriodMin;
	public uint32 wPeriodMax;
	public uint32 wRmin;
	public uint32 wRmax;
	public uint32 wUmin;
	public uint32 wUmax;
	public uint32 wVmin;
	public uint32 wVmax;
	public uint32 wCaps;
	public uint32 wMaxAxes;
	public uint32 wNumAxes;
	public uint32 wMaxButtons;
	public CHAR[32] szRegKey;
	public CHAR[260] szOEMVxD;
	public Guid ManufacturerGuid;
	public Guid ProductGuid;
	public Guid NameGuid;
}

[CRepr, Packed(1)]
public struct JOYCAPS2W
{
	public uint16 wMid;
	public uint16 wPid;
	public char16[32] szPname;
	public uint32 wXmin;
	public uint32 wXmax;
	public uint32 wYmin;
	public uint32 wYmax;
	public uint32 wZmin;
	public uint32 wZmax;
	public uint32 wNumButtons;
	public uint32 wPeriodMin;
	public uint32 wPeriodMax;
	public uint32 wRmin;
	public uint32 wRmax;
	public uint32 wUmin;
	public uint32 wUmax;
	public uint32 wVmin;
	public uint32 wVmax;
	public uint32 wCaps;
	public uint32 wMaxAxes;
	public uint32 wNumAxes;
	public uint32 wMaxButtons;
	public char16[32] szRegKey;
	public char16[260] szOEMVxD;
	public Guid ManufacturerGuid;
	public Guid ProductGuid;
	public Guid NameGuid;
}

[CRepr, Packed(1)]
public struct JOYINFO
{
	public uint32 wXpos;
	public uint32 wYpos;
	public uint32 wZpos;
	public uint32 wButtons;
}

[CRepr, Packed(1)]
public struct JOYINFOEX
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwXpos;
	public uint32 dwYpos;
	public uint32 dwZpos;
	public uint32 dwRpos;
	public uint32 dwUpos;
	public uint32 dwVpos;
	public uint32 dwButtons;
	public uint32 dwButtonNumber;
	public uint32 dwPOV;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr, Packed(1)]
public struct MCI_DGV_RECT_PARMS
{
	public uint dwCallback;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_CAPTURE_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrFileName;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_CAPTURE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrFileName;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_COPY_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
	public RECT rc;
	public uint32 dwAudioStream;
	public uint32 dwVideoStream;
}

[CRepr, Packed(1)]
public struct MCI_DGV_CUE_PARMS
{
	public uint dwCallback;
	public uint32 dwTo;
}

[CRepr, Packed(1)]
public struct MCI_DGV_CUT_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
	public RECT rc;
	public uint32 dwAudioStream;
	public uint32 dwVideoStream;
}

[CRepr, Packed(1)]
public struct MCI_DGV_DELETE_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
	public RECT rc;
	public uint32 dwAudioStream;
	public uint32 dwVideoStream;
}

[CRepr, Packed(1)]
public struct MCI_DGV_INFO_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrReturn;
	public uint32 dwRetSize;
	public uint32 dwItem;
}

[CRepr, Packed(1)]
public struct MCI_DGV_INFO_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrReturn;
	public uint32 dwRetSize;
	public uint32 dwItem;
}

[CRepr, Packed(1)]
public struct MCI_DGV_LIST_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrReturn;
	public uint32 dwLength;
	public uint32 dwNumber;
	public uint32 dwItem;
	public PSTR lpstrAlgorithm;
}

[CRepr, Packed(1)]
public struct MCI_DGV_LIST_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrReturn;
	public uint32 dwLength;
	public uint32 dwNumber;
	public uint32 dwItem;
	public PWSTR lpstrAlgorithm;
}

[CRepr, Packed(1)]
public struct MCI_DGV_MONITOR_PARMS
{
	public uint dwCallback;
	public uint32 dwSource;
	public uint32 dwMethod;
}

[CRepr, Packed(1)]
public struct MCI_DGV_OPEN_PARMSA
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PSTR lpstrDeviceType;
	public PSTR lpstrElementName;
	public PSTR lpstrAlias;
	public uint32 dwStyle;
	public HWND hWndParent;
}

[CRepr, Packed(1)]
public struct MCI_DGV_OPEN_PARMSW
{
	public uint dwCallback;
	public uint32 wDeviceID;
	public PWSTR lpstrDeviceType;
	public PWSTR lpstrElementName;
	public PWSTR lpstrAlias;
	public uint32 dwStyle;
	public HWND hWndParent;
}

[CRepr, Packed(1)]
public struct MCI_DGV_PASTE_PARMS
{
	public uint dwCallback;
	public uint32 dwTo;
	public RECT rc;
	public uint32 dwAudioStream;
	public uint32 dwVideoStream;
}

[CRepr, Packed(1)]
public struct MCI_DGV_QUALITY_PARMSA
{
	public uint dwCallback;
	public uint32 dwItem;
	public PSTR lpstrName;
	public uint32 lpstrAlgorithm;
	public uint32 dwHandle;
}

[CRepr, Packed(1)]
public struct MCI_DGV_QUALITY_PARMSW
{
	public uint dwCallback;
	public uint32 dwItem;
	public PWSTR lpstrName;
	public uint32 lpstrAlgorithm;
	public uint32 dwHandle;
}

[CRepr, Packed(1)]
public struct MCI_DGV_RECORD_PARMS
{
	public uint dwCallback;
	public uint32 dwFrom;
	public uint32 dwTo;
	public RECT rc;
	public uint32 dwAudioStream;
	public uint32 dwVideoStream;
}

[CRepr, Packed(1)]
public struct MCI_DGV_RESERVE_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrPath;
	public uint32 dwSize;
}

[CRepr, Packed(1)]
public struct MCI_DGV_RESERVE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrPath;
	public uint32 dwSize;
}

[CRepr, Packed(1)]
public struct MCI_DGV_RESTORE_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrFileName;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_RESTORE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrFileName;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SAVE_PARMSA
{
	public uint dwCallback;
	public PSTR lpstrFileName;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SAVE_PARMSW
{
	public uint dwCallback;
	public PWSTR lpstrFileName;
	public RECT rc;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SET_PARMS
{
	public uint dwCallback;
	public uint32 dwTimeFormat;
	public uint32 dwAudio;
	public uint32 dwFileFormat;
	public uint32 dwSpeed;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SETAUDIO_PARMSA
{
	public uint dwCallback;
	public uint32 dwItem;
	public uint32 dwValue;
	public uint32 dwOver;
	public PSTR lpstrAlgorithm;
	public PSTR lpstrQuality;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SETAUDIO_PARMSW
{
	public uint dwCallback;
	public uint32 dwItem;
	public uint32 dwValue;
	public uint32 dwOver;
	public PWSTR lpstrAlgorithm;
	public PWSTR lpstrQuality;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SIGNAL_PARMS
{
	public uint dwCallback;
	public uint32 dwPosition;
	public uint32 dwPeriod;
	public uint32 dwUserParm;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SETVIDEO_PARMSA
{
	public uint dwCallback;
	public uint32 dwItem;
	public uint32 dwValue;
	public uint32 dwOver;
	public PSTR lpstrAlgorithm;
	public PSTR lpstrQuality;
	public uint32 dwSourceNumber;
}

[CRepr, Packed(1)]
public struct MCI_DGV_SETVIDEO_PARMSW
{
	public uint dwCallback;
	public uint32 dwItem;
	public uint32 dwValue;
	public uint32 dwOver;
	public PWSTR lpstrAlgorithm;
	public PWSTR lpstrQuality;
	public uint32 dwSourceNumber;
}

[CRepr, Packed(1)]
public struct MCI_DGV_STATUS_PARMSA
{
	public uint dwCallback;
	public uint dwReturn;
	public uint32 dwItem;
	public uint32 dwTrack;
	public PSTR lpstrDrive;
	public uint32 dwReference;
}

[CRepr, Packed(1)]
public struct MCI_DGV_STATUS_PARMSW
{
	public uint dwCallback;
	public uint dwReturn;
	public uint32 dwItem;
	public uint32 dwTrack;
	public PWSTR lpstrDrive;
	public uint32 dwReference;
}

[CRepr, Packed(1)]
public struct MCI_DGV_STEP_PARMS
{
	public uint dwCallback;
	public uint32 dwFrames;
}

[CRepr, Packed(1)]
public struct MCI_DGV_UPDATE_PARMS
{
	public uint dwCallback;
	public RECT rc;
	public HDC hDC;
}

[CRepr, Packed(1)]
public struct MCI_DGV_WINDOW_PARMSA
{
	public uint dwCallback;
	public HWND hWnd;
	public uint32 nCmdShow;
	public PSTR lpstrText;
}

[CRepr, Packed(1)]
public struct MCI_DGV_WINDOW_PARMSW
{
	public uint dwCallback;
	public HWND hWnd;
	public uint32 nCmdShow;
	public PWSTR lpstrText;
}

[CRepr]
public struct ICOPEN
{
	public uint32 dwSize;
	public uint32 fccType;
	public uint32 fccHandler;
	public uint32 dwVersion;
	public uint32 dwFlags;
	public LRESULT dwError;
	public void* pV1Reserved;
	public void* pV2Reserved;
	public uint32 dnDevNode;
}

[CRepr]
public struct ICINFO
{
	public uint32 dwSize;
	public uint32 fccType;
	public uint32 fccHandler;
	public uint32 dwFlags;
	public uint32 dwVersion;
	public uint32 dwVersionICM;
	public char16[16] szName;
	public char16[128] szDescription;
	public char16[128] szDriver;
}

[CRepr]
public struct ICCOMPRESS
{
	public uint32 dwFlags;
	public BITMAPINFOHEADER* lpbiOutput;
	public void* lpOutput;
	public BITMAPINFOHEADER* lpbiInput;
	public void* lpInput;
	public uint32* lpckid;
	public uint32* lpdwFlags;
	public int32 lFrameNum;
	public uint32 dwFrameSize;
	public uint32 dwQuality;
	public BITMAPINFOHEADER* lpbiPrev;
	public void* lpPrev;
}

[CRepr]
public struct ICCOMPRESSFRAMES
{
	public uint32 dwFlags;
	public BITMAPINFOHEADER* lpbiOutput;
	public LPARAM lOutput;
	public BITMAPINFOHEADER* lpbiInput;
	public LPARAM lInput;
	public int32 lStartFrame;
	public int32 lFrameCount;
	public int32 lQuality;
	public int32 lDataRate;
	public int32 lKeyRate;
	public uint32 dwRate;
	public uint32 dwScale;
	public uint32 dwOverheadPerFrame;
	public uint32 dwReserved2;
	public int GetData;
	public int PutData;
}

[CRepr]
public struct ICSETSTATUSPROC
{
	public uint32 dwFlags;
	public LPARAM lParam;
	public int Status;
}

[CRepr]
public struct ICDECOMPRESS
{
	public uint32 dwFlags;
	public BITMAPINFOHEADER* lpbiInput;
	public void* lpInput;
	public BITMAPINFOHEADER* lpbiOutput;
	public void* lpOutput;
	public uint32 ckid;
}

[CRepr]
public struct ICDECOMPRESSEX
{
	public uint32 dwFlags;
	public BITMAPINFOHEADER* lpbiSrc;
	public void* lpSrc;
	public BITMAPINFOHEADER* lpbiDst;
	public void* lpDst;
	public int32 xDst;
	public int32 yDst;
	public int32 dxDst;
	public int32 dyDst;
	public int32 xSrc;
	public int32 ySrc;
	public int32 dxSrc;
	public int32 dySrc;
}

[CRepr]
public struct ICDRAWBEGIN
{
	public uint32 dwFlags;
	public HPALETTE hpal;
	public HWND hwnd;
	public HDC hdc;
	public int32 xDst;
	public int32 yDst;
	public int32 dxDst;
	public int32 dyDst;
	public BITMAPINFOHEADER* lpbi;
	public int32 xSrc;
	public int32 ySrc;
	public int32 dxSrc;
	public int32 dySrc;
	public uint32 dwRate;
	public uint32 dwScale;
}

[CRepr]
public struct ICDRAW
{
	public uint32 dwFlags;
	public void* lpFormat;
	public void* lpData;
	public uint32 cbData;
	public int32 lTime;
}

[CRepr]
public struct ICDRAWSUGGEST
{
	public BITMAPINFOHEADER* lpbiIn;
	public BITMAPINFOHEADER* lpbiSuggest;
	public int32 dxSrc;
	public int32 dySrc;
	public int32 dxDst;
	public int32 dyDst;
	public HIC hicDecompressor;
}

[CRepr]
public struct ICPALETTE
{
	public uint32 dwFlags;
	public int32 iStart;
	public int32 iLen;
	public PALETTEENTRY* lppe;
}

[CRepr]
public struct COMPVARS
{
	public int32 cbSize;
	public uint32 dwFlags;
	public HIC hic;
	public uint32 fccType;
	public uint32 fccHandler;
	public BITMAPINFO* lpbiIn;
	public BITMAPINFO* lpbiOut;
	public void* lpBitsOut;
	public void* lpBitsPrev;
	public int32 lFrame;
	public int32 lKey;
	public int32 lDataRate;
	public int32 lQ;
	public int32 lKeyCount;
	public void* lpState;
	public int32 cbState;
}

[CRepr]
public struct DRAWDIBTIME
{
	public int32 timeCount;
	public int32 timeDraw;
	public int32 timeDecompress;
	public int32 timeDither;
	public int32 timeStretch;
	public int32 timeBlt;
	public int32 timeSetDIBits;
}

[CRepr]
public struct AVISTREAMINFOW
{
	public uint32 fccType;
	public uint32 fccHandler;
	public uint32 dwFlags;
	public uint32 dwCaps;
	public uint16 wPriority;
	public uint16 wLanguage;
	public uint32 dwScale;
	public uint32 dwRate;
	public uint32 dwStart;
	public uint32 dwLength;
	public uint32 dwInitialFrames;
	public uint32 dwSuggestedBufferSize;
	public uint32 dwQuality;
	public uint32 dwSampleSize;
	public RECT rcFrame;
	public uint32 dwEditCount;
	public uint32 dwFormatChangeCount;
	public char16[64] szName;
}

[CRepr]
public struct AVISTREAMINFOA
{
	public uint32 fccType;
	public uint32 fccHandler;
	public uint32 dwFlags;
	public uint32 dwCaps;
	public uint16 wPriority;
	public uint16 wLanguage;
	public uint32 dwScale;
	public uint32 dwRate;
	public uint32 dwStart;
	public uint32 dwLength;
	public uint32 dwInitialFrames;
	public uint32 dwSuggestedBufferSize;
	public uint32 dwQuality;
	public uint32 dwSampleSize;
	public RECT rcFrame;
	public uint32 dwEditCount;
	public uint32 dwFormatChangeCount;
	public CHAR[64] szName;
}

[CRepr]
public struct AVIFILEINFOW
{
	public uint32 dwMaxBytesPerSec;
	public uint32 dwFlags;
	public uint32 dwCaps;
	public uint32 dwStreams;
	public uint32 dwSuggestedBufferSize;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public uint32 dwScale;
	public uint32 dwRate;
	public uint32 dwLength;
	public uint32 dwEditCount;
	public char16[64] szFileType;
}

[CRepr]
public struct AVIFILEINFOA
{
	public uint32 dwMaxBytesPerSec;
	public uint32 dwFlags;
	public uint32 dwCaps;
	public uint32 dwStreams;
	public uint32 dwSuggestedBufferSize;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public uint32 dwScale;
	public uint32 dwRate;
	public uint32 dwLength;
	public uint32 dwEditCount;
	public CHAR[64] szFileType;
}

[CRepr]
public struct AVICOMPRESSOPTIONS
{
	public uint32 fccType;
	public uint32 fccHandler;
	public uint32 dwKeyFrameEvery;
	public uint32 dwQuality;
	public uint32 dwBytesPerSecond;
	public uint32 dwFlags;
	public void* lpFormat;
	public uint32 cbFormat;
	public void* lpParms;
	public uint32 cbParms;
	public uint32 dwInterleaveEvery;
}

[CRepr]
public struct VIDEOHDR
{
	public uint8* lpData;
	public uint32 dwBufferLength;
	public uint32 dwBytesUsed;
	public uint32 dwTimeCaptured;
	public uint dwUser;
	public uint32 dwFlags;
	public uint[4] dwReserved;
}

[CRepr]
public struct CHANNEL_CAPS
{
	public uint32 dwFlags;
	public uint32 dwSrcRectXMod;
	public uint32 dwSrcRectYMod;
	public uint32 dwSrcRectWidthMod;
	public uint32 dwSrcRectHeightMod;
	public uint32 dwDstRectXMod;
	public uint32 dwDstRectYMod;
	public uint32 dwDstRectWidthMod;
	public uint32 dwDstRectHeightMod;
}

[CRepr]
public struct CAPDRIVERCAPS
{
	public uint32 wDeviceIndex;
	public BOOL fHasOverlay;
	public BOOL fHasDlgVideoSource;
	public BOOL fHasDlgVideoFormat;
	public BOOL fHasDlgVideoDisplay;
	public BOOL fCaptureInitialized;
	public BOOL fDriverSuppliesPalettes;
	public HANDLE hVideoIn;
	public HANDLE hVideoOut;
	public HANDLE hVideoExtIn;
	public HANDLE hVideoExtOut;
}

[CRepr]
public struct CAPSTATUS
{
	public uint32 uiImageWidth;
	public uint32 uiImageHeight;
	public BOOL fLiveWindow;
	public BOOL fOverlayWindow;
	public BOOL fScale;
	public POINT ptScroll;
	public BOOL fUsingDefaultPalette;
	public BOOL fAudioHardware;
	public BOOL fCapFileExists;
	public uint32 dwCurrentVideoFrame;
	public uint32 dwCurrentVideoFramesDropped;
	public uint32 dwCurrentWaveSamples;
	public uint32 dwCurrentTimeElapsedMS;
	public HPALETTE hPalCurrent;
	public BOOL fCapturingNow;
	public uint32 dwReturn;
	public uint32 wNumVideoAllocated;
	public uint32 wNumAudioAllocated;
}

[CRepr]
public struct CAPTUREPARMS
{
	public uint32 dwRequestMicroSecPerFrame;
	public BOOL fMakeUserHitOKToCapture;
	public uint32 wPercentDropForError;
	public BOOL fYield;
	public uint32 dwIndexSize;
	public uint32 wChunkGranularity;
	public BOOL fUsingDOSMemory;
	public uint32 wNumVideoRequested;
	public BOOL fCaptureAudio;
	public uint32 wNumAudioRequested;
	public uint32 vKeyAbort;
	public BOOL fAbortLeftMouse;
	public BOOL fAbortRightMouse;
	public BOOL fLimitEnabled;
	public uint32 wTimeLimit;
	public BOOL fMCIControl;
	public BOOL fStepMCIDevice;
	public uint32 dwMCIStartTime;
	public uint32 dwMCIStopTime;
	public BOOL fStepCaptureAt2x;
	public uint32 wStepCaptureAverageFrames;
	public uint32 dwAudioBufferSize;
	public BOOL fDisableWriteCache;
	public uint32 AVStreamMaster;
}

[CRepr]
public struct CAPINFOCHUNK
{
	public uint32 fccInfoID;
	public void* lpData;
	public int32 cbData;
}

[CRepr, Packed(1)]
public struct DRVM_IOCTL_DATA
{
	public uint32 dwSize;
	public uint32 dwCmd;
}

[CRepr, Packed(1)]
public struct WAVEOPENDESC
{
	public HWAVE hWave;
	public WAVEFORMAT* lpFormat;
	public uint dwCallback;
	public uint dwInstance;
	public uint32 uMappedDeviceID;
	public uint dnDevNode;
}

[CRepr, Packed(1)]
public struct MIDIOPENSTRMID
{
	public uint32 dwStreamID;
	public uint32 uDeviceID;
}

[CRepr, Packed(1)]
public struct MIXEROPENDESC
{
	public HMIXER hmx;
	public void* pReserved0;
	public uint dwCallback;
	public uint dwInstance;
	public uint dnDevNode;
}

[CRepr, Packed(1)]
public struct TIMEREVENT
{
	public uint16 wDelay;
	public uint16 wResolution;
	public LPTIMECALLBACK lpFunction;
	public uint32 dwUser;
	public uint16 wFlags;
	public uint16 wReserved1;
}

[CRepr, Packed(1)]
public struct MCI_OPEN_DRIVER_PARMS
{
	public uint32 wDeviceID;
	public PWSTR lpstrParams;
	public uint32 wCustomCommandTable;
	public uint32 wType;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_KSDATAFORMAT_SUBTYPE_IEEE_FLOAT = .(0x00000003, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);


}
#endregion

#region COM Types
[CRepr]struct IAVIStream : IUnknown
{
	public new const Guid IID = .(0x00020021, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPARAM lParam1, LPARAM lParam2) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AVISTREAMINFOW* psi, int32 lSize) Info;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, int32 lPos, int32 lFlags) FindSample;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPos, void* lpFormat, int32* lpcbFormat) ReadFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPos, void* lpFormat, int32 cbFormat) SetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lStart, int32 lSamples, void* lpBuffer, int32 cbBuffer, int32* plBytes, int32* plSamples) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lStart, int32 lSamples, void* lpBuffer, int32 cbBuffer, uint32 dwFlags, int32* plSampWritten, int32* plBytesWritten) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lStart, int32 lSamples) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fcc, void* lp, int32* lpcb) ReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fcc, void* lp, int32 cb) WriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AVISTREAMINFOW* lpInfo, int32 cbInfo) SetInfo;
	}


	public HRESULT Create(LPARAM lParam1, LPARAM lParam2) mut => VT.[Friend]Create(&this, lParam1, lParam2);

	public HRESULT Info(AVISTREAMINFOW* psi, int32 lSize) mut => VT.[Friend]Info(&this, psi, lSize);

	public int32 FindSample(int32 lPos, int32 lFlags) mut => VT.[Friend]FindSample(&this, lPos, lFlags);

	public HRESULT ReadFormat(int32 lPos, void* lpFormat, int32* lpcbFormat) mut => VT.[Friend]ReadFormat(&this, lPos, lpFormat, lpcbFormat);

	public HRESULT SetFormat(int32 lPos, void* lpFormat, int32 cbFormat) mut => VT.[Friend]SetFormat(&this, lPos, lpFormat, cbFormat);

	public HRESULT Read(int32 lStart, int32 lSamples, void* lpBuffer, int32 cbBuffer, int32* plBytes, int32* plSamples) mut => VT.[Friend]Read(&this, lStart, lSamples, lpBuffer, cbBuffer, plBytes, plSamples);

	public HRESULT Write(int32 lStart, int32 lSamples, void* lpBuffer, int32 cbBuffer, uint32 dwFlags, int32* plSampWritten, int32* plBytesWritten) mut => VT.[Friend]Write(&this, lStart, lSamples, lpBuffer, cbBuffer, dwFlags, plSampWritten, plBytesWritten);

	public HRESULT Delete(int32 lStart, int32 lSamples) mut => VT.[Friend]Delete(&this, lStart, lSamples);

	public HRESULT ReadData(uint32 fcc, void* lp, int32* lpcb) mut => VT.[Friend]ReadData(&this, fcc, lp, lpcb);

	public HRESULT WriteData(uint32 fcc, void* lp, int32 cb) mut => VT.[Friend]WriteData(&this, fcc, lp, cb);

	public HRESULT SetInfo(AVISTREAMINFOW* lpInfo, int32 cbInfo) mut => VT.[Friend]SetInfo(&this, lpInfo, cbInfo);
}

[CRepr]struct IAVIStreaming : IUnknown
{
	public new const Guid IID = .(0x00020022, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lStart, int32 lEnd, int32 lRate) Begin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) End;
	}


	public HRESULT Begin(int32 lStart, int32 lEnd, int32 lRate) mut => VT.[Friend]Begin(&this, lStart, lEnd, lRate);

	public HRESULT End() mut => VT.[Friend]End(&this);
}

[CRepr]struct IAVIEditStream : IUnknown
{
	public new const Guid IID = .(0x00020024, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plStart, int32* plLength, IAVIStream** ppResult) Cut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plStart, int32* plLength, IAVIStream** ppResult) Copy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPos, int32* plLength, IAVIStream* pstream, int32 lStart, int32 lEnd) Paste;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAVIStream** ppResult) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AVISTREAMINFOW* lpInfo, int32 cbInfo) SetInfo;
	}


	public HRESULT Cut(int32* plStart, int32* plLength, IAVIStream** ppResult) mut => VT.[Friend]Cut(&this, plStart, plLength, ppResult);

	public HRESULT Copy(int32* plStart, int32* plLength, IAVIStream** ppResult) mut => VT.[Friend]Copy(&this, plStart, plLength, ppResult);

	public HRESULT Paste(int32* plPos, int32* plLength, IAVIStream* pstream, int32 lStart, int32 lEnd) mut => VT.[Friend]Paste(&this, plPos, plLength, pstream, lStart, lEnd);

	public HRESULT Clone(IAVIStream** ppResult) mut => VT.[Friend]Clone(&this, ppResult);

	public HRESULT SetInfo(AVISTREAMINFOW* lpInfo, int32 cbInfo) mut => VT.[Friend]SetInfo(&this, lpInfo, cbInfo);
}

[CRepr]struct IAVIPersistFile : IPersistFile
{
	public new const Guid IID = .(0x00020025, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistFile.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reserved1;
	}


	public HRESULT Reserved1() mut => VT.[Friend]Reserved1(&this);
}

[CRepr]struct IAVIFile : IUnknown
{
	public new const Guid IID = .(0x00020020, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AVIFILEINFOW* pfi, int32 lSize) Info;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAVIStream** ppStream, uint32 fccType, int32 lParam) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAVIStream** ppStream, AVISTREAMINFOW* psi) CreateStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ckid, void* lpData, int32 cbData) WriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ckid, void* lpData, int32* lpcbData) ReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fccType, int32 lParam) DeleteStream;
	}


	public HRESULT Info(AVIFILEINFOW* pfi, int32 lSize) mut => VT.[Friend]Info(&this, pfi, lSize);

	public HRESULT GetStream(IAVIStream** ppStream, uint32 fccType, int32 lParam) mut => VT.[Friend]GetStream(&this, ppStream, fccType, lParam);

	public HRESULT CreateStream(IAVIStream** ppStream, AVISTREAMINFOW* psi) mut => VT.[Friend]CreateStream(&this, ppStream, psi);

	public HRESULT WriteData(uint32 ckid, void* lpData, int32 cbData) mut => VT.[Friend]WriteData(&this, ckid, lpData, cbData);

	public HRESULT ReadData(uint32 ckid, void* lpData, int32* lpcbData) mut => VT.[Friend]ReadData(&this, ckid, lpData, lpcbData);

	public HRESULT EndRecord() mut => VT.[Friend]EndRecord(&this);

	public HRESULT DeleteStream(uint32 fccType, int32 lParam) mut => VT.[Friend]DeleteStream(&this, fccType, lParam);
}

[CRepr]struct IGetFrame : IUnknown
{
	public new const Guid IID = .(0x00020023, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, int32 lPos) GetFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lStart, int32 lEnd, int32 lRate) Begin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) End;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BITMAPINFOHEADER* lpbi, void* lpBits, int32 x, int32 y, int32 dx, int32 dy) SetFormat;
	}


	public void* GetFrame(int32 lPos) mut => VT.[Friend]GetFrame(&this, lPos);

	public HRESULT Begin(int32 lStart, int32 lEnd, int32 lRate) mut => VT.[Friend]Begin(&this, lStart, lEnd, lRate);

	public HRESULT End() mut => VT.[Friend]End(&this);

	public HRESULT SetFormat(BITMAPINFOHEADER* lpbi, void* lpBits, int32 x, int32 y, int32 dx, int32 dy) mut => VT.[Friend]SetFormat(&this, lpbi, lpBits, x, y, dx, dy);
}

#endregion

#region Functions
public static
{
	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciSendCommandA(uint32 mciId, uint32 uMsg, uint dwParam1, uint dwParam2);
	public static uint32 mciSendCommand(uint32 mciId, uint32 uMsg, uint dwParam1, uint dwParam2) => mciSendCommandA(mciId, uMsg, dwParam1, dwParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciSendCommandW(uint32 mciId, uint32 uMsg, uint dwParam1, uint dwParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciSendStringA(PSTR lpstrCommand, uint8* lpstrReturnString, uint32 uReturnLength, HWND hwndCallback);
	public static uint32 mciSendString(PSTR lpstrCommand, uint8* lpstrReturnString, uint32 uReturnLength, HWND hwndCallback) => mciSendStringA(lpstrCommand, lpstrReturnString, uReturnLength, hwndCallback);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciSendStringW(PWSTR lpstrCommand, char16* lpstrReturnString, uint32 uReturnLength, HWND hwndCallback);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciGetDeviceIDA(PSTR pszDevice);
	public static uint32 mciGetDeviceID(PSTR pszDevice) => mciGetDeviceIDA(pszDevice);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciGetDeviceIDW(PWSTR pszDevice);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciGetDeviceIDFromElementIDA(uint32 dwElementID, PSTR lpstrType);
	public static uint32 mciGetDeviceIDFromElementID(uint32 dwElementID, PSTR lpstrType) => mciGetDeviceIDFromElementIDA(dwElementID, lpstrType);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciGetDeviceIDFromElementIDW(uint32 dwElementID, PWSTR lpstrType);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mciGetErrorStringA(uint32 mcierr, uint8* pszText, uint32 cchText);
	public static BOOL mciGetErrorString(uint32 mcierr, uint8* pszText, uint32 cchText) => mciGetErrorStringA(mcierr, pszText, cchText);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mciGetErrorStringW(uint32 mcierr, char16* pszText, uint32 cchText);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mciSetYieldProc(uint32 mciId, YIELDPROC fpYieldProc, uint32 dwYieldData);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HTASK mciGetCreatorTask(uint32 mciId);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern YIELDPROC mciGetYieldProc(uint32 mciId, uint32* pdwYieldData);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint mciGetDriverData(uint32 wDeviceID);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciLoadCommandResource(HANDLE hInstance, PWSTR lpResName, uint32 wType);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mciSetDriverData(uint32 wDeviceID, uint dwData);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mciDriverYield(uint32 wDeviceID);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mciDriverNotify(HANDLE hwndCallback, uint32 wDeviceID, uint32 uStatus);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mciFreeCommandResource(uint32 wTable);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT CloseDriver(HDRVR hDriver, LPARAM lParam1, LPARAM lParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDRVR OpenDriver(PWSTR szDriverName, PWSTR szSectionName, LPARAM lParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT SendDriverMessage(HDRVR hDriver, uint32 message, LPARAM lParam1, LPARAM lParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE DrvGetModuleHandle(HDRVR hDriver);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE GetDriverModuleHandle(HDRVR hDriver);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT DefDriverProc(uint dwDriverIdentifier, HDRVR hdrvr, uint32 uMsg, LPARAM lParam1, LPARAM lParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DriverCallback(uint dwCallback, uint32 dwFlags, HDRVR hDevice, uint32 dwMsg, uint dwUser, uint dwParam1, uint dwParam2);

	[Import("api-ms-win-mm-misc-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sndOpenSound(PWSTR EventName, PWSTR AppName, int32 Flags, HANDLE* FileHandle);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmDrvInstall(HDRVR hDriver, PWSTR wszDrvEntry, DRIVERMSGPROC drvMessage, uint32 wFlags);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioStringToFOURCCA(PSTR sz, uint32 uFlags);
	public static uint32 mmioStringToFOURCC(PSTR sz, uint32 uFlags) => mmioStringToFOURCCA(sz, uFlags);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioStringToFOURCCW(PWSTR sz, uint32 uFlags);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LPMMIOPROC mmioInstallIOProcA(uint32 fccIOProc, LPMMIOPROC pIOProc, uint32 dwFlags);
	public static LPMMIOPROC mmioInstallIOProc(uint32 fccIOProc, LPMMIOPROC pIOProc, uint32 dwFlags) => mmioInstallIOProcA(fccIOProc, pIOProc, dwFlags);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LPMMIOPROC mmioInstallIOProcW(uint32 fccIOProc, LPMMIOPROC pIOProc, uint32 dwFlags);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMMIO mmioOpenA(uint8* pszFileName, MMIOINFO* pmmioinfo, uint32 fdwOpen);
	public static HMMIO mmioOpen(uint8* pszFileName, MMIOINFO* pmmioinfo, uint32 fdwOpen) => mmioOpenA(pszFileName, pmmioinfo, fdwOpen);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMMIO mmioOpenW(char16* pszFileName, MMIOINFO* pmmioinfo, uint32 fdwOpen);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioRenameA(PSTR pszFileName, PSTR pszNewFileName, MMIOINFO* pmmioinfo, uint32 fdwRename);
	public static uint32 mmioRename(PSTR pszFileName, PSTR pszNewFileName, MMIOINFO* pmmioinfo, uint32 fdwRename) => mmioRenameA(pszFileName, pszNewFileName, pmmioinfo, fdwRename);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioRenameW(PWSTR pszFileName, PWSTR pszNewFileName, MMIOINFO* pmmioinfo, uint32 fdwRename);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioClose(HMMIO hmmio, uint32 fuClose);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 mmioRead(HMMIO hmmio, int8* pch, int32 cch);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 mmioWrite(HMMIO hmmio, PSTR pch, int32 cch);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 mmioSeek(HMMIO hmmio, int32 lOffset, int32 iOrigin);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioGetInfo(HMMIO hmmio, MMIOINFO* pmmioinfo, uint32 fuInfo);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioSetInfo(HMMIO hmmio, MMIOINFO* pmmioinfo, uint32 fuInfo);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioSetBuffer(HMMIO hmmio, uint8* pchBuffer, int32 cchBuffer, uint32 fuBuffer);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioFlush(HMMIO hmmio, uint32 fuFlush);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioAdvance(HMMIO hmmio, MMIOINFO* pmmioinfo, uint32 fuAdvance);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT mmioSendMessage(HMMIO hmmio, uint32 uMsg, LPARAM lParam1, LPARAM lParam2);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioDescend(HMMIO hmmio, MMCKINFO* pmmcki, MMCKINFO* pmmckiParent, uint32 fuDescend);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioAscend(HMMIO hmmio, MMCKINFO* pmmcki, uint32 fuAscend);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmioCreateChunk(HMMIO hmmio, MMCKINFO* pmmcki, uint32 fuCreate);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyGetPosEx(uint32 uJoyID, JOYINFOEX* pji);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyGetNumDevs();

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyGetDevCapsA(uint uJoyID, JOYCAPSA* pjc, uint32 cbjc);
	public static uint32 joyGetDevCaps(uint uJoyID, JOYCAPSA* pjc, uint32 cbjc) => joyGetDevCapsA(uJoyID, pjc, cbjc);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyGetDevCapsW(uint uJoyID, JOYCAPSW* pjc, uint32 cbjc);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyGetPos(uint32 uJoyID, JOYINFO* pji);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyGetThreshold(uint32 uJoyID, uint32* puThreshold);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyReleaseCapture(uint32 uJoyID);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joySetCapture(HWND hwnd, uint32 uJoyID, uint32 uPeriod, BOOL fChanged);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joySetThreshold(uint32 uJoyID, uint32 uThreshold);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 VideoForWindowsVersion();

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ICInfo(uint32 fccType, uint32 fccHandler, ICINFO* lpicinfo);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ICInstall(uint32 fccType, uint32 fccHandler, LPARAM lParam, PSTR szDesc, uint32 wFlags);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ICRemove(uint32 fccType, uint32 fccHandler, uint32 wFlags);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT ICGetInfo(HIC hic, ICINFO* picinfo, uint32 cb);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIC ICOpen(uint32 fccType, uint32 fccHandler, uint32 wMode);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIC ICOpenFunction(uint32 fccType, uint32 fccHandler, uint32 wMode, FARPROC lpfnHandler);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT ICClose(HIC hic);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT ICSendMessage(HIC hic, uint32 msg, uint dw1, uint dw2);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ICCompress(HIC hic, uint32 dwFlags, BITMAPINFOHEADER* lpbiOutput, void* lpData, BITMAPINFOHEADER* lpbiInput, void* lpBits, uint32* lpckid, uint32* lpdwFlags, int32 lFrameNum, uint32 dwFrameSize, uint32 dwQuality, BITMAPINFOHEADER* lpbiPrev, void* lpPrev);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ICDecompress(HIC hic, uint32 dwFlags, BITMAPINFOHEADER* lpbiFormat, void* lpData, BITMAPINFOHEADER* lpbi, void* lpBits);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ICDrawBegin(HIC hic, uint32 dwFlags, HPALETTE hpal, HWND hwnd, HDC hdc, int32 xDst, int32 yDst, int32 dxDst, int32 dyDst, BITMAPINFOHEADER* lpbi, int32 xSrc, int32 ySrc, int32 dxSrc, int32 dySrc, uint32 dwRate, uint32 dwScale);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ICDraw(HIC hic, uint32 dwFlags, void* lpFormat, void* lpData, uint32 cbData, int32 lTime);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIC ICLocate(uint32 fccType, uint32 fccHandler, BITMAPINFOHEADER* lpbiIn, BITMAPINFOHEADER* lpbiOut, uint16 wFlags);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIC ICGetDisplayFormat(HIC hic, BITMAPINFOHEADER* lpbiIn, BITMAPINFOHEADER* lpbiOut, int32 BitDepth, int32 dx, int32 dy);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE ICImageCompress(HIC hic, uint32 uiFlags, BITMAPINFO* lpbiIn, void* lpBits, BITMAPINFO* lpbiOut, int32 lQuality, int32* plSize);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE ICImageDecompress(HIC hic, uint32 uiFlags, BITMAPINFO* lpbiIn, void* lpBits, BITMAPINFO* lpbiOut);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ICCompressorChoose(HWND hwnd, uint32 uiFlags, void* pvIn, void* lpData, COMPVARS* pc, PSTR lpszTitle);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ICSeqCompressFrameStart(COMPVARS* pc, BITMAPINFO* lpbiIn);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ICSeqCompressFrameEnd(COMPVARS* pc);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ICSeqCompressFrame(COMPVARS* pc, uint32 uiFlags, void* lpBits, BOOL* pfKey, int32* plSize);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ICCompressorFree(COMPVARS* pc);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int DrawDibOpen();

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibClose(int hdd);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* DrawDibGetBuffer(int hdd, BITMAPINFOHEADER* lpbi, uint32 dwSize, uint32 dwFlags);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPALETTE DrawDibGetPalette(int hdd);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibSetPalette(int hdd, HPALETTE hpal);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibChangePalette(int hdd, int32 iStart, int32 iLen, PALETTEENTRY* lppe);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DrawDibRealize(int hdd, HDC hdc, BOOL fBackground);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibStart(int hdd, uint32 rate);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibStop(int hdd);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibBegin(int hdd, HDC hdc, int32 dxDst, int32 dyDst, BITMAPINFOHEADER* lpbi, int32 dxSrc, int32 dySrc, uint32 wFlags);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibDraw(int hdd, HDC hdc, int32 xDst, int32 yDst, int32 dxDst, int32 dyDst, BITMAPINFOHEADER* lpbi, void* lpBits, int32 xSrc, int32 ySrc, int32 dxSrc, int32 dySrc, uint32 wFlags);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibEnd(int hdd);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawDibTime(int hdd, DRAWDIBTIME* lpddtime);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT DrawDibProfileDisplay(BITMAPINFOHEADER* lpbi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void AVIFileInit();

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void AVIFileExit();

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AVIFileAddRef(IAVIFile* pfile);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AVIFileRelease(IAVIFile* pfile);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileOpenA(IAVIFile** ppfile, PSTR szFile, uint32 uMode, Guid* lpHandler);
	public static HRESULT AVIFileOpen(IAVIFile** ppfile, PSTR szFile, uint32 uMode, Guid* lpHandler) => AVIFileOpenA(ppfile, szFile, uMode, lpHandler);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileOpenW(IAVIFile** ppfile, PWSTR szFile, uint32 uMode, Guid* lpHandler);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileInfoW(IAVIFile* pfile, AVIFILEINFOW* pfi, int32 lSize);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileInfoA(IAVIFile* pfile, AVIFILEINFOA* pfi, int32 lSize);
	public static HRESULT AVIFileInfo(IAVIFile* pfile, AVIFILEINFOA* pfi, int32 lSize) => AVIFileInfoA(pfile, pfi, lSize);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileGetStream(IAVIFile* pfile, IAVIStream** ppavi, uint32 fccType, int32 lParam);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileCreateStreamW(IAVIFile* pfile, IAVIStream** ppavi, AVISTREAMINFOW* psi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileCreateStreamA(IAVIFile* pfile, IAVIStream** ppavi, AVISTREAMINFOA* psi);
	public static HRESULT AVIFileCreateStream(IAVIFile* pfile, IAVIStream** ppavi, AVISTREAMINFOA* psi) => AVIFileCreateStreamA(pfile, ppavi, psi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileWriteData(IAVIFile* pfile, uint32 ckid, void* lpData, int32 cbData);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileReadData(IAVIFile* pfile, uint32 ckid, void* lpData, int32* lpcbData);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIFileEndRecord(IAVIFile* pfile);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AVIStreamAddRef(IAVIStream* pavi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AVIStreamRelease(IAVIStream* pavi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamInfoW(IAVIStream* pavi, AVISTREAMINFOW* psi, int32 lSize);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamInfoA(IAVIStream* pavi, AVISTREAMINFOA* psi, int32 lSize);
	public static HRESULT AVIStreamInfo(IAVIStream* pavi, AVISTREAMINFOA* psi, int32 lSize) => AVIStreamInfoA(pavi, psi, lSize);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AVIStreamFindSample(IAVIStream* pavi, int32 lPos, int32 lFlags);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamReadFormat(IAVIStream* pavi, int32 lPos, void* lpFormat, int32* lpcbFormat);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamSetFormat(IAVIStream* pavi, int32 lPos, void* lpFormat, int32 cbFormat);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamReadData(IAVIStream* pavi, uint32 fcc, void* lp, int32* lpcb);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamWriteData(IAVIStream* pavi, uint32 fcc, void* lp, int32 cb);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamRead(IAVIStream* pavi, int32 lStart, int32 lSamples, void* lpBuffer, int32 cbBuffer, int32* plBytes, int32* plSamples);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamWrite(IAVIStream* pavi, int32 lStart, int32 lSamples, void* lpBuffer, int32 cbBuffer, uint32 dwFlags, int32* plSampWritten, int32* plBytesWritten);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AVIStreamStart(IAVIStream* pavi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AVIStreamLength(IAVIStream* pavi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AVIStreamTimeToSample(IAVIStream* pavi, int32 lTime);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AVIStreamSampleToTime(IAVIStream* pavi, int32 lSample);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamBeginStreaming(IAVIStream* pavi, int32 lStart, int32 lEnd, int32 lRate);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamEndStreaming(IAVIStream* pavi);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IGetFrame* AVIStreamGetFrameOpen(IAVIStream* pavi, BITMAPINFOHEADER* lpbiWanted);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* AVIStreamGetFrame(IGetFrame* pg, int32 lPos);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamGetFrameClose(IGetFrame* pg);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamOpenFromFileA(IAVIStream** ppavi, PSTR szFile, uint32 fccType, int32 lParam, uint32 mode, Guid* pclsidHandler);
	public static HRESULT AVIStreamOpenFromFile(IAVIStream** ppavi, PSTR szFile, uint32 fccType, int32 lParam, uint32 mode, Guid* pclsidHandler) => AVIStreamOpenFromFileA(ppavi, szFile, fccType, lParam, mode, pclsidHandler);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamOpenFromFileW(IAVIStream** ppavi, PWSTR szFile, uint32 fccType, int32 lParam, uint32 mode, Guid* pclsidHandler);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIStreamCreate(IAVIStream** ppavi, int32 lParam1, int32 lParam2, Guid* pclsidHandler);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIMakeCompressedStream(IAVIStream** ppsCompressed, IAVIStream* ppsSource, AVICOMPRESSOPTIONS* lpOptions, Guid* pclsidHandler);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVISaveA(PSTR szFile, Guid* pclsidHandler, AVISAVECALLBACK lpfnCallback, int32 nStreams, IAVIStream* pfile, AVICOMPRESSOPTIONS* lpOptions);
	public static HRESULT AVISave(PSTR szFile, Guid* pclsidHandler, AVISAVECALLBACK lpfnCallback, int32 nStreams, IAVIStream* pfile, AVICOMPRESSOPTIONS* lpOptions) => AVISaveA(szFile, pclsidHandler, lpfnCallback, nStreams, pfile, lpOptions);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVISaveVA(PSTR szFile, Guid* pclsidHandler, AVISAVECALLBACK lpfnCallback, int32 nStreams, IAVIStream** ppavi, AVICOMPRESSOPTIONS** plpOptions);
	public static HRESULT AVISaveV(PSTR szFile, Guid* pclsidHandler, AVISAVECALLBACK lpfnCallback, int32 nStreams, IAVIStream** ppavi, AVICOMPRESSOPTIONS** plpOptions) => AVISaveVA(szFile, pclsidHandler, lpfnCallback, nStreams, ppavi, plpOptions);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVISaveW(PWSTR szFile, Guid* pclsidHandler, AVISAVECALLBACK lpfnCallback, int32 nStreams, IAVIStream* pfile, AVICOMPRESSOPTIONS* lpOptions);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVISaveVW(PWSTR szFile, Guid* pclsidHandler, AVISAVECALLBACK lpfnCallback, int32 nStreams, IAVIStream** ppavi, AVICOMPRESSOPTIONS** plpOptions);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int AVISaveOptions(HWND hwnd, uint32 uiFlags, int32 nStreams, IAVIStream** ppavi, AVICOMPRESSOPTIONS** plpOptions);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVISaveOptionsFree(int32 nStreams, AVICOMPRESSOPTIONS** plpOptions);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIBuildFilterW(char16* lpszFilter, int32 cbFilter, BOOL fSaving);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIBuildFilterA(uint8* lpszFilter, int32 cbFilter, BOOL fSaving);
	public static HRESULT AVIBuildFilter(uint8* lpszFilter, int32 cbFilter, BOOL fSaving) => AVIBuildFilterA(lpszFilter, cbFilter, fSaving);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIMakeFileFromStreams(IAVIFile** ppfile, int32 nStreams, IAVIStream** papStreams);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIMakeStreamFromClipboard(uint32 cfFormat, HANDLE hGlobal, IAVIStream** ppstream);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIPutFileOnClipboard(IAVIFile* pf);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIGetFromClipboard(IAVIFile** lppf);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AVIClearClipboard();

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateEditableStream(IAVIStream** ppsEditable, IAVIStream* psSource);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamCut(IAVIStream* pavi, int32* plStart, int32* plLength, IAVIStream** ppResult);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamCopy(IAVIStream* pavi, int32* plStart, int32* plLength, IAVIStream** ppResult);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamPaste(IAVIStream* pavi, int32* plPos, int32* plLength, IAVIStream* pstream, int32 lStart, int32 lEnd);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamClone(IAVIStream* pavi, IAVIStream** ppResult);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamSetNameA(IAVIStream* pavi, PSTR lpszName);
	public static HRESULT EditStreamSetName(IAVIStream* pavi, PSTR lpszName) => EditStreamSetNameA(pavi, lpszName);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamSetNameW(IAVIStream* pavi, PWSTR lpszName);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamSetInfoW(IAVIStream* pavi, AVISTREAMINFOW* lpInfo, int32 cbInfo);

	[Import("AVIFIL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EditStreamSetInfoA(IAVIStream* pavi, AVISTREAMINFOA* lpInfo, int32 cbInfo);
	public static HRESULT EditStreamSetInfo(IAVIStream* pavi, AVISTREAMINFOA* lpInfo, int32 cbInfo) => EditStreamSetInfoA(pavi, lpInfo, cbInfo);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND MCIWndCreateA(HWND hwndParent, HINSTANCE hInstance, uint32 dwStyle, PSTR szFile);
	public static HWND MCIWndCreate(HWND hwndParent, HINSTANCE hInstance, uint32 dwStyle, PSTR szFile) => MCIWndCreateA(hwndParent, hInstance, dwStyle, szFile);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND MCIWndCreateW(HWND hwndParent, HINSTANCE hInstance, uint32 dwStyle, PWSTR szFile);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MCIWndRegisterClass();

	[Import("AVICAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND capCreateCaptureWindowA(PSTR lpszWindowName, uint32 dwStyle, int32 x, int32 y, int32 nWidth, int32 nHeight, HWND hwndParent, int32 nID);
	public static HWND capCreateCaptureWindow(PSTR lpszWindowName, uint32 dwStyle, int32 x, int32 y, int32 nWidth, int32 nHeight, HWND hwndParent, int32 nID) => capCreateCaptureWindowA(lpszWindowName, dwStyle, x, y, nWidth, nHeight, hwndParent, nID);

	[Import("AVICAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL capGetDriverDescriptionA(uint32 wDriverIndex, uint8* lpszName, int32 cbName, uint8* lpszVer, int32 cbVer);
	public static BOOL capGetDriverDescription(uint32 wDriverIndex, uint8* lpszName, int32 cbName, uint8* lpszVer, int32 cbVer) => capGetDriverDescriptionA(wDriverIndex, lpszName, cbName, lpszVer, cbVer);

	[Import("AVICAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND capCreateCaptureWindowW(PWSTR lpszWindowName, uint32 dwStyle, int32 x, int32 y, int32 nWidth, int32 nHeight, HWND hwndParent, int32 nID);

	[Import("AVICAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL capGetDriverDescriptionW(uint32 wDriverIndex, char16* lpszName, int32 cbName, char16* lpszVer, int32 cbVer);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOpenFileNamePreviewA(OPENFILENAMEA* lpofn);
	public static BOOL GetOpenFileNamePreview(OPENFILENAMEA* lpofn) => GetOpenFileNamePreviewA(lpofn);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSaveFileNamePreviewA(OPENFILENAMEA* lpofn);
	public static BOOL GetSaveFileNamePreview(OPENFILENAMEA* lpofn) => GetSaveFileNamePreviewA(lpofn);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOpenFileNamePreviewW(OPENFILENAMEW* lpofn);

	[Import("MSVFW32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSaveFileNamePreviewW(OPENFILENAMEW* lpofn);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmTaskCreate(LPTASKCALLBACK lpfn, HANDLE* lph, uint dwInst);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void mmTaskBlock(uint32 h);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL mmTaskSignal(uint32 h);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void mmTaskYield();

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 mmGetCurrentTask();

}
#endregion
