using Win32.Devices.Properties;
using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using Win32.Graphics.OpenGL;
using Win32.Graphics.DirectDraw;
using Win32.UI.ColorSystem;
using Win32.System.Console;
using Win32.Graphics.Direct3D9;
using System;

namespace Win32.Devices.Display;

#region Constants
public static
{
	public const Guid GUID_DEVINTERFACE_DISPLAY_ADAPTER = .(0x5b45201d, 0xf2f2, 0x4f3b, 0x85, 0xbb, 0x30, 0xff, 0x1f, 0x95, 0x35, 0x99);
	public const Guid GUID_DEVINTERFACE_MONITOR = .(0xe6f07b5f, 0xee97, 0x4a90, 0xb0, 0x76, 0x33, 0xf5, 0x7b, 0xf4, 0xea, 0xa7);
	public const Guid GUID_DISPLAY_DEVICE_ARRIVAL = .(0x1ca05180, 0xa699, 0x450a, 0x9a, 0x0c, 0xde, 0x4f, 0xbe, 0x3d, 0xdd, 0x89);
	public const Guid GUID_DEVINTERFACE_VIDEO_OUTPUT_ARRIVAL = .(0x1ad9e4f0, 0xf88d, 0x4360, 0xba, 0xb9, 0x4c, 0x2d, 0x55, 0xe5, 0x64, 0xcd);
	public const DEVPROPKEY DEVPKEY_IndirectDisplay = .(.(0xc50a3f10, 0xaa5c, 0x4247, 0xb8, 0x30, 0xd6, 0xa6, 0xf8, 0xea, 0xa3, 0x10), 1);
	public const DEVPROPKEY DEVPKEY_Device_TerminalLuid = .(.(0xc50a3f10, 0xaa5c, 0x4247, 0xb8, 0x30, 0xd6, 0xa6, 0xf8, 0xea, 0xa3, 0x10), 2);
	public const DEVPROPKEY DEVPKEY_Device_AdapterLuid = .(.(0xc50a3f10, 0xaa5c, 0x4247, 0xb8, 0x30, 0xd6, 0xa6, 0xf8, 0xea, 0xa3, 0x10), 3);
	public const DEVPROPKEY DEVPKEY_Device_ActivityId = .(.(0xc50a3f10, 0xaa5c, 0x4247, 0xb8, 0x30, 0xd6, 0xa6, 0xf8, 0xea, 0xa3, 0x10), 4);
	public const uint32 INDIRECT_DISPLAY_INFO_FLAGS_CREATED_IDDCX_ADAPTER = 1;
	public const String VIDEO_DEVICE_NAME = "DISPLAY%d";
	public const String WVIDEO_DEVICE_NAME = "DISPLAY%d";
	public const uint32 IOCTL_VIDEO_DISABLE_VDM = 2293764;
	public const uint32 IOCTL_VIDEO_REGISTER_VDM = 2293768;
	public const uint32 IOCTL_VIDEO_SET_OUTPUT_DEVICE_POWER_STATE = 2293772;
	public const uint32 IOCTL_VIDEO_GET_OUTPUT_DEVICE_POWER_STATE = 2293776;
	public const uint32 IOCTL_VIDEO_MONITOR_DEVICE = 2293780;
	public const uint32 IOCTL_VIDEO_ENUM_MONITOR_PDO = 2293784;
	public const uint32 IOCTL_VIDEO_INIT_WIN32K_CALLBACKS = 2293788;
	public const uint32 IOCTL_VIDEO_IS_VGA_DEVICE = 2293796;
	public const uint32 IOCTL_VIDEO_USE_DEVICE_IN_SESSION = 2293800;
	public const uint32 IOCTL_VIDEO_PREPARE_FOR_EARECOVERY = 2293804;
	public const uint32 IOCTL_VIDEO_ENABLE_VDM = 2293760;
	public const uint32 IOCTL_VIDEO_SAVE_HARDWARE_STATE = 2294272;
	public const uint32 IOCTL_VIDEO_RESTORE_HARDWARE_STATE = 2294276;
	public const uint32 IOCTL_VIDEO_HANDLE_VIDEOPARAMETERS = 2293792;
	public const uint32 IOCTL_VIDEO_QUERY_AVAIL_MODES = 2294784;
	public const uint32 IOCTL_VIDEO_QUERY_NUM_AVAIL_MODES = 2294788;
	public const uint32 IOCTL_VIDEO_QUERY_CURRENT_MODE = 2294792;
	public const uint32 IOCTL_VIDEO_SET_CURRENT_MODE = 2294796;
	public const uint32 IOCTL_VIDEO_RESET_DEVICE = 2294800;
	public const uint32 IOCTL_VIDEO_LOAD_AND_SET_FONT = 2294804;
	public const uint32 IOCTL_VIDEO_SET_PALETTE_REGISTERS = 2294808;
	public const uint32 IOCTL_VIDEO_SET_COLOR_REGISTERS = 2294812;
	public const uint32 IOCTL_VIDEO_ENABLE_CURSOR = 2294816;
	public const uint32 IOCTL_VIDEO_DISABLE_CURSOR = 2294820;
	public const uint32 IOCTL_VIDEO_SET_CURSOR_ATTR = 2294824;
	public const uint32 IOCTL_VIDEO_QUERY_CURSOR_ATTR = 2294828;
	public const uint32 IOCTL_VIDEO_SET_CURSOR_POSITION = 2294832;
	public const uint32 IOCTL_VIDEO_QUERY_CURSOR_POSITION = 2294836;
	public const uint32 IOCTL_VIDEO_ENABLE_POINTER = 2294840;
	public const uint32 IOCTL_VIDEO_DISABLE_POINTER = 2294844;
	public const uint32 IOCTL_VIDEO_SET_POINTER_ATTR = 2294848;
	public const uint32 IOCTL_VIDEO_QUERY_POINTER_ATTR = 2294852;
	public const uint32 IOCTL_VIDEO_SET_POINTER_POSITION = 2294856;
	public const uint32 IOCTL_VIDEO_QUERY_POINTER_POSITION = 2294860;
	public const uint32 IOCTL_VIDEO_QUERY_POINTER_CAPABILITIES = 2294864;
	public const uint32 IOCTL_VIDEO_GET_BANK_SELECT_CODE = 2294868;
	public const uint32 IOCTL_VIDEO_MAP_VIDEO_MEMORY = 2294872;
	public const uint32 IOCTL_VIDEO_UNMAP_VIDEO_MEMORY = 2294876;
	public const uint32 IOCTL_VIDEO_QUERY_PUBLIC_ACCESS_RANGES = 2294880;
	public const uint32 IOCTL_VIDEO_FREE_PUBLIC_ACCESS_RANGES = 2294884;
	public const uint32 IOCTL_VIDEO_QUERY_COLOR_CAPABILITIES = 2294888;
	public const uint32 IOCTL_VIDEO_SET_POWER_MANAGEMENT = 2294892;
	public const uint32 IOCTL_VIDEO_GET_POWER_MANAGEMENT = 2294896;
	public const uint32 IOCTL_VIDEO_SHARE_VIDEO_MEMORY = 2294900;
	public const uint32 IOCTL_VIDEO_UNSHARE_VIDEO_MEMORY = 2294904;
	public const uint32 IOCTL_VIDEO_SET_COLOR_LUT_DATA = 2294908;
	public const uint32 IOCTL_VIDEO_GET_CHILD_STATE = 2294912;
	public const uint32 IOCTL_VIDEO_VALIDATE_CHILD_STATE_CONFIGURATION = 2294916;
	public const uint32 IOCTL_VIDEO_SET_CHILD_STATE_CONFIGURATION = 2294920;
	public const uint32 IOCTL_VIDEO_SWITCH_DUALVIEW = 2294924;
	public const uint32 IOCTL_VIDEO_SET_BANK_POSITION = 2294928;
	public const uint32 IOCTL_VIDEO_QUERY_SUPPORTED_BRIGHTNESS = 2294932;
	public const uint32 IOCTL_VIDEO_QUERY_DISPLAY_BRIGHTNESS = 2294936;
	public const uint32 IOCTL_VIDEO_SET_DISPLAY_BRIGHTNESS = 2294940;
	public const uint32 IOCTL_FSVIDEO_COPY_FRAME_BUFFER = 3409920;
	public const uint32 IOCTL_FSVIDEO_WRITE_TO_FRAME_BUFFER = 3409924;
	public const uint32 IOCTL_FSVIDEO_REVERSE_MOUSE_POINTER = 3409928;
	public const uint32 IOCTL_FSVIDEO_SET_CURRENT_MODE = 3409932;
	public const uint32 IOCTL_FSVIDEO_SET_SCREEN_INFORMATION = 3409936;
	public const uint32 IOCTL_FSVIDEO_SET_CURSOR_POSITION = 3409940;
	public const uint32 IOCTL_PANEL_QUERY_BRIGHTNESS_CAPS = 2296832;
	public const uint32 IOCTL_PANEL_QUERY_BRIGHTNESS_RANGES = 2296836;
	public const uint32 IOCTL_PANEL_GET_BRIGHTNESS = 2296840;
	public const uint32 IOCTL_PANEL_SET_BRIGHTNESS = 2296844;
	public const uint32 IOCTL_PANEL_SET_BRIGHTNESS_STATE = 2296848;
	public const uint32 IOCTL_PANEL_SET_BACKLIGHT_OPTIMIZATION = 2296852;
	public const uint32 IOCTL_PANEL_GET_BACKLIGHT_REDUCTION = 2296856;
	public const uint32 IOCTL_COLORSPACE_TRANSFORM_QUERY_TARGET_CAPS = 2297856;
	public const uint32 IOCTL_COLORSPACE_TRANSFORM_SET = 2297860;
	public const uint32 IOCTL_SET_ACTIVE_COLOR_PROFILE_NAME = 2297864;
	public const uint32 IOCTL_MIPI_DSI_QUERY_CAPS = 2298880;
	public const uint32 IOCTL_MIPI_DSI_TRANSMISSION = 2298884;
	public const uint32 IOCTL_MIPI_DSI_RESET = 2298888;
	public const uint32 DXGK_WIN32K_PARAM_FLAG_UPDATEREGISTRY = 1;
	public const uint32 DXGK_WIN32K_PARAM_FLAG_MODESWITCH = 2;
	public const uint32 DXGK_WIN32K_PARAM_FLAG_DISABLEVIEW = 4;
	public const uint32 VIDEO_DUALVIEW_REMOVABLE = 1;
	public const uint32 VIDEO_DUALVIEW_PRIMARY = 2147483648;
	public const uint32 VIDEO_DUALVIEW_SECONDARY = 1073741824;
	public const uint32 VIDEO_DUALVIEW_WDDM_VGA = 536870912;
	public const uint32 VIDEO_STATE_NON_STANDARD_VGA = 1;
	public const uint32 VIDEO_STATE_UNEMULATED_VGA_STATE = 2;
	public const uint32 VIDEO_STATE_PACKED_CHAIN4_MODE = 4;
	public const uint32 VIDEO_MODE_NO_ZERO_MEMORY = 2147483648;
	public const uint32 VIDEO_MODE_MAP_MEM_LINEAR = 1073741824;
	public const uint32 VIDEO_MODE_COLOR = 1;
	public const uint32 VIDEO_MODE_GRAPHICS = 2;
	public const uint32 VIDEO_MODE_PALETTE_DRIVEN = 4;
	public const uint32 VIDEO_MODE_MANAGED_PALETTE = 8;
	public const uint32 VIDEO_MODE_INTERLACED = 16;
	public const uint32 VIDEO_MODE_NO_OFF_SCREEN = 32;
	public const uint32 VIDEO_MODE_NO_64_BIT_ACCESS = 64;
	public const uint32 VIDEO_MODE_BANKED = 128;
	public const uint32 VIDEO_MODE_LINEAR = 256;
	public const uint32 VIDEO_MODE_ASYNC_POINTER = 1;
	public const uint32 VIDEO_MODE_MONO_POINTER = 2;
	public const uint32 VIDEO_MODE_COLOR_POINTER = 4;
	public const uint32 VIDEO_MODE_ANIMATE_START = 8;
	public const uint32 VIDEO_MODE_ANIMATE_UPDATE = 16;
	public const uint32 PLANAR_HC = 1;
	public const uint32 VIDEO_DEVICE_COLOR = 1;
	public const uint32 VIDEO_OPTIONAL_GAMMET_TABLE = 2;
	public const uint32 VIDEO_COLOR_LUT_DATA_FORMAT_RGB256WORDS = 1;
	public const uint32 VIDEO_COLOR_LUT_DATA_FORMAT_PRIVATEFORMAT = 2147483648;
	public const uint32 DISPLAYPOLICY_AC = 1;
	public const uint32 DISPLAYPOLICY_DC = 2;
	public const uint32 CHAR_TYPE_SBCS = 0;
	public const uint32 CHAR_TYPE_LEADING = 2;
	public const uint32 CHAR_TYPE_TRAILING = 3;
	public const uint32 BITMAP_BITS_BYTE_ALIGN = 8;
	public const uint32 BITMAP_BITS_WORD_ALIGN = 16;
	public const uint32 BITMAP_ARRAY_BYTE = 3;
	public const uint32 BITMAP_PLANES = 1;
	public const uint32 BITMAP_BITS_PIXEL = 1;
	public const String DD_FULLSCREEN_VIDEO_DEVICE_NAME = "\\Device\\FSVideo";
	public const uint32 VIDEO_REASON_NONE = 0;
	public const uint32 VIDEO_REASON_POLICY1 = 1;
	public const uint32 VIDEO_REASON_POLICY2 = 2;
	public const uint32 VIDEO_REASON_POLICY3 = 3;
	public const uint32 VIDEO_REASON_POLICY4 = 4;
	public const uint32 VIDEO_REASON_LOCK = 5;
	public const uint32 VIDEO_REASON_FAILED_ROTATION = 5;
	public const uint32 VIDEO_REASON_ALLOCATION = 6;
	public const uint32 VIDEO_REASON_SCRATCH = 8;
	public const uint32 VIDEO_REASON_CONFIGURATION = 9;
	public const uint32 VIDEO_MAX_REASON = 9;
	public const uint32 BRIGHTNESS_MAX_LEVEL_COUNT = 103;
	public const uint32 BRIGHTNESS_MAX_NIT_RANGE_COUNT = 16;
	public const uint32 DSI_PACKET_EMBEDDED_PAYLOAD_SIZE = 8;
	public const uint32 MAX_PACKET_COUNT = 128;
	public const uint32 DSI_INVALID_PACKET_INDEX = 255;
	public const uint32 DSI_SOT_ERROR = 1;
	public const uint32 DSI_SOT_SYNC_ERROR = 2;
	public const uint32 DSI_EOT_SYNC_ERROR = 4;
	public const uint32 DSI_ESCAPE_MODE_ENTRY_COMMAND_ERROR = 8;
	public const uint32 DSI_LOW_POWER_TRANSMIT_SYNC_ERROR = 16;
	public const uint32 DSI_PERIPHERAL_TIMEOUT_ERROR = 32;
	public const uint32 DSI_FALSE_CONTROL_ERROR = 64;
	public const uint32 DSI_CONTENTION_DETECTED = 128;
	public const uint32 DSI_CHECKSUM_ERROR_CORRECTED = 256;
	public const uint32 DSI_CHECKSUM_ERROR_NOT_CORRECTED = 512;
	public const uint32 DSI_LONG_PACKET_PAYLOAD_CHECKSUM_ERROR = 1024;
	public const uint32 DSI_DSI_DATA_TYPE_NOT_RECOGNIZED = 2048;
	public const uint32 DSI_DSI_VC_ID_INVALID = 4096;
	public const uint32 DSI_INVALID_TRANSMISSION_LENGTH = 8192;
	public const uint32 DSI_DSI_PROTOCOL_VIOLATION = 32768;
	public const uint32 HOST_DSI_DEVICE_NOT_READY = 1;
	public const uint32 HOST_DSI_INTERFACE_RESET = 2;
	public const uint32 HOST_DSI_DEVICE_RESET = 4;
	public const uint32 HOST_DSI_TRANSMISSION_CANCELLED = 16;
	public const uint32 HOST_DSI_TRANSMISSION_DROPPED = 32;
	public const uint32 HOST_DSI_TRANSMISSION_TIMEOUT = 64;
	public const uint32 HOST_DSI_INVALID_TRANSMISSION = 256;
	public const uint32 HOST_DSI_OS_REJECTED_PACKET = 512;
	public const uint32 HOST_DSI_DRIVER_REJECTED_PACKET = 1024;
	public const uint32 HOST_DSI_BAD_TRANSMISSION_MODE = 4096;
	public const Guid GUID_MONITOR_OVERRIDE_PSEUDO_SPECIALIZED = .(0xf196c02f, 0xf86f, 0x4f9a, 0xaa, 0x15, 0xe9, 0xce, 0xbd, 0xfe, 0x3b, 0x96);
	public const uint32 FD_ERROR = 4294967295;
	public const uint32 DDI_ERROR = 4294967295;
	public const uint32 FDM_TYPE_BM_SIDE_CONST = 1;
	public const uint32 FDM_TYPE_MAXEXT_EQUAL_BM_SIDE = 2;
	public const uint32 FDM_TYPE_CHAR_INC_EQUAL_BM_BASE = 4;
	public const uint32 FDM_TYPE_ZERO_BEARINGS = 8;
	public const uint32 FDM_TYPE_CONST_BEARINGS = 16;
	public const uint32 GS_UNICODE_HANDLES = 1;
	public const uint32 GS_8BIT_HANDLES = 2;
	public const uint32 GS_16BIT_HANDLES = 4;
	public const uint32 FM_VERSION_NUMBER = 0;
	public const uint32 FM_TYPE_LICENSED = 2;
	public const uint32 FM_READONLY_EMBED = 4;
	public const uint32 FM_EDITABLE_EMBED = 8;
	public const uint32 FM_NO_EMBEDDING = 2;
	public const uint32 FM_INFO_TECH_TRUETYPE = 1;
	public const uint32 FM_INFO_TECH_BITMAP = 2;
	public const uint32 FM_INFO_TECH_STROKE = 4;
	public const uint32 FM_INFO_TECH_OUTLINE_NOT_TRUETYPE = 8;
	public const uint32 FM_INFO_ARB_XFORMS = 16;
	public const uint32 FM_INFO_1BPP = 32;
	public const uint32 FM_INFO_4BPP = 64;
	public const uint32 FM_INFO_8BPP = 128;
	public const uint32 FM_INFO_16BPP = 256;
	public const uint32 FM_INFO_24BPP = 512;
	public const uint32 FM_INFO_32BPP = 1024;
	public const uint32 FM_INFO_INTEGER_WIDTH = 2048;
	public const uint32 FM_INFO_CONSTANT_WIDTH = 4096;
	public const uint32 FM_INFO_NOT_CONTIGUOUS = 8192;
	public const uint32 FM_INFO_TECH_MM = 16384;
	public const uint32 FM_INFO_RETURNS_OUTLINES = 32768;
	public const uint32 FM_INFO_RETURNS_STROKES = 65536;
	public const uint32 FM_INFO_RETURNS_BITMAPS = 131072;
	public const uint32 FM_INFO_DSIG = 262144;
	public const uint32 FM_INFO_RIGHT_HANDED = 524288;
	public const uint32 FM_INFO_INTEGRAL_SCALING = 1048576;
	public const uint32 FM_INFO_90DEGREE_ROTATIONS = 2097152;
	public const uint32 FM_INFO_OPTICALLY_FIXED_PITCH = 4194304;
	public const uint32 FM_INFO_DO_NOT_ENUMERATE = 8388608;
	public const uint32 FM_INFO_ISOTROPIC_SCALING_ONLY = 16777216;
	public const uint32 FM_INFO_ANISOTROPIC_SCALING_ONLY = 33554432;
	public const uint32 FM_INFO_TECH_CFF = 67108864;
	public const uint32 FM_INFO_FAMILY_EQUIV = 134217728;
	public const uint32 FM_INFO_DBCS_FIXED_PITCH = 268435456;
	public const uint32 FM_INFO_NONNEGATIVE_AC = 536870912;
	public const uint32 FM_INFO_IGNORE_TC_RA_ABLE = 1073741824;
	public const uint32 FM_INFO_TECH_TYPE1 = 2147483648;
	public const uint32 MAXCHARSETS = 16;
	public const uint32 FM_PANOSE_CULTURE_LATIN = 0;
	public const uint32 FM_SEL_ITALIC = 1;
	public const uint32 FM_SEL_UNDERSCORE = 2;
	public const uint32 FM_SEL_NEGATIVE = 4;
	public const uint32 FM_SEL_OUTLINED = 8;
	public const uint32 FM_SEL_STRIKEOUT = 16;
	public const uint32 FM_SEL_BOLD = 32;
	public const uint32 FM_SEL_REGULAR = 64;
	public const uint32 OPENGL_CMD = 4352;
	public const uint32 OPENGL_GETINFO = 4353;
	public const uint32 WNDOBJ_SETUP = 4354;
	public const uint32 DDI_DRIVER_VERSION_NT4 = 131072;
	public const uint32 DDI_DRIVER_VERSION_SP3 = 131075;
	public const uint32 DDI_DRIVER_VERSION_NT5 = 196608;
	public const uint32 DDI_DRIVER_VERSION_NT5_01 = 196864;
	public const uint32 DDI_DRIVER_VERSION_NT5_01_SP1 = 196865;
	public const uint32 GDI_DRIVER_VERSION = 16384;
	public const int32 INDEX_DrvEnablePDEV = 0;
	public const int32 INDEX_DrvCompletePDEV = 1;
	public const int32 INDEX_DrvDisablePDEV = 2;
	public const int32 INDEX_DrvEnableSurface = 3;
	public const int32 INDEX_DrvDisableSurface = 4;
	public const int32 INDEX_DrvAssertMode = 5;
	public const int32 INDEX_DrvOffset = 6;
	public const int32 INDEX_DrvResetPDEV = 7;
	public const int32 INDEX_DrvDisableDriver = 8;
	public const int32 INDEX_DrvCreateDeviceBitmap = 10;
	public const int32 INDEX_DrvDeleteDeviceBitmap = 11;
	public const int32 INDEX_DrvRealizeBrush = 12;
	public const int32 INDEX_DrvDitherColor = 13;
	public const int32 INDEX_DrvStrokePath = 14;
	public const int32 INDEX_DrvFillPath = 15;
	public const int32 INDEX_DrvStrokeAndFillPath = 16;
	public const int32 INDEX_DrvPaint = 17;
	public const int32 INDEX_DrvBitBlt = 18;
	public const int32 INDEX_DrvCopyBits = 19;
	public const int32 INDEX_DrvStretchBlt = 20;
	public const int32 INDEX_DrvSetPalette = 22;
	public const int32 INDEX_DrvTextOut = 23;
	public const int32 INDEX_DrvEscape = 24;
	public const int32 INDEX_DrvDrawEscape = 25;
	public const int32 INDEX_DrvQueryFont = 26;
	public const int32 INDEX_DrvQueryFontTree = 27;
	public const int32 INDEX_DrvQueryFontData = 28;
	public const int32 INDEX_DrvSetPointerShape = 29;
	public const int32 INDEX_DrvMovePointer = 30;
	public const int32 INDEX_DrvLineTo = 31;
	public const int32 INDEX_DrvSendPage = 32;
	public const int32 INDEX_DrvStartPage = 33;
	public const int32 INDEX_DrvEndDoc = 34;
	public const int32 INDEX_DrvStartDoc = 35;
	public const int32 INDEX_DrvGetGlyphMode = 37;
	public const int32 INDEX_DrvSynchronize = 38;
	public const int32 INDEX_DrvSaveScreenBits = 40;
	public const int32 INDEX_DrvGetModes = 41;
	public const int32 INDEX_DrvFree = 42;
	public const int32 INDEX_DrvDestroyFont = 43;
	public const int32 INDEX_DrvQueryFontCaps = 44;
	public const int32 INDEX_DrvLoadFontFile = 45;
	public const int32 INDEX_DrvUnloadFontFile = 46;
	public const int32 INDEX_DrvFontManagement = 47;
	public const int32 INDEX_DrvQueryTrueTypeTable = 48;
	public const int32 INDEX_DrvQueryTrueTypeOutline = 49;
	public const int32 INDEX_DrvGetTrueTypeFile = 50;
	public const int32 INDEX_DrvQueryFontFile = 51;
	public const int32 INDEX_DrvMovePanning = 52;
	public const int32 INDEX_DrvQueryAdvanceWidths = 53;
	public const int32 INDEX_DrvSetPixelFormat = 54;
	public const int32 INDEX_DrvDescribePixelFormat = 55;
	public const int32 INDEX_DrvSwapBuffers = 56;
	public const int32 INDEX_DrvStartBanding = 57;
	public const int32 INDEX_DrvNextBand = 58;
	public const int32 INDEX_DrvGetDirectDrawInfo = 59;
	public const int32 INDEX_DrvEnableDirectDraw = 60;
	public const int32 INDEX_DrvDisableDirectDraw = 61;
	public const int32 INDEX_DrvQuerySpoolType = 62;
	public const int32 INDEX_DrvIcmCreateColorTransform = 64;
	public const int32 INDEX_DrvIcmDeleteColorTransform = 65;
	public const int32 INDEX_DrvIcmCheckBitmapBits = 66;
	public const int32 INDEX_DrvIcmSetDeviceGammaRamp = 67;
	public const int32 INDEX_DrvGradientFill = 68;
	public const int32 INDEX_DrvStretchBltROP = 69;
	public const int32 INDEX_DrvPlgBlt = 70;
	public const int32 INDEX_DrvAlphaBlend = 71;
	public const int32 INDEX_DrvSynthesizeFont = 72;
	public const int32 INDEX_DrvGetSynthesizedFontFiles = 73;
	public const int32 INDEX_DrvTransparentBlt = 74;
	public const int32 INDEX_DrvQueryPerBandInfo = 75;
	public const int32 INDEX_DrvQueryDeviceSupport = 76;
	public const int32 INDEX_DrvReserved1 = 77;
	public const int32 INDEX_DrvReserved2 = 78;
	public const int32 INDEX_DrvReserved3 = 79;
	public const int32 INDEX_DrvReserved4 = 80;
	public const int32 INDEX_DrvReserved5 = 81;
	public const int32 INDEX_DrvReserved6 = 82;
	public const int32 INDEX_DrvReserved7 = 83;
	public const int32 INDEX_DrvReserved8 = 84;
	public const int32 INDEX_DrvDeriveSurface = 85;
	public const int32 INDEX_DrvQueryGlyphAttrs = 86;
	public const int32 INDEX_DrvNotify = 87;
	public const int32 INDEX_DrvSynchronizeSurface = 88;
	public const int32 INDEX_DrvResetDevice = 89;
	public const int32 INDEX_DrvReserved9 = 90;
	public const int32 INDEX_DrvReserved10 = 91;
	public const int32 INDEX_DrvReserved11 = 92;
	public const int32 INDEX_DrvRenderHint = 93;
	public const int32 INDEX_DrvCreateDeviceBitmapEx = 94;
	public const int32 INDEX_DrvDeleteDeviceBitmapEx = 95;
	public const int32 INDEX_DrvAssociateSharedSurface = 96;
	public const int32 INDEX_DrvSynchronizeRedirectionBitmaps = 97;
	public const int32 INDEX_DrvAccumulateD3DDirtyRect = 98;
	public const int32 INDEX_DrvStartDxInterop = 99;
	public const int32 INDEX_DrvEndDxInterop = 100;
	public const int32 INDEX_DrvLockDisplayArea = 101;
	public const int32 INDEX_DrvUnlockDisplayArea = 102;
	public const int32 INDEX_DrvSurfaceComplete = 103;
	public const int32 INDEX_LAST = 89;
	public const uint32 GCAPS_BEZIERS = 1;
	public const uint32 GCAPS_GEOMETRICWIDE = 2;
	public const uint32 GCAPS_ALTERNATEFILL = 4;
	public const uint32 GCAPS_WINDINGFILL = 8;
	public const uint32 GCAPS_HALFTONE = 16;
	public const uint32 GCAPS_COLOR_DITHER = 32;
	public const uint32 GCAPS_HORIZSTRIKE = 64;
	public const uint32 GCAPS_VERTSTRIKE = 128;
	public const uint32 GCAPS_OPAQUERECT = 256;
	public const uint32 GCAPS_VECTORFONT = 512;
	public const uint32 GCAPS_MONO_DITHER = 1024;
	public const uint32 GCAPS_ASYNCCHANGE = 2048;
	public const uint32 GCAPS_ASYNCMOVE = 4096;
	public const uint32 GCAPS_DONTJOURNAL = 8192;
	public const uint32 GCAPS_DIRECTDRAW = 16384;
	public const uint32 GCAPS_ARBRUSHOPAQUE = 32768;
	public const uint32 GCAPS_PANNING = 65536;
	public const uint32 GCAPS_HIGHRESTEXT = 262144;
	public const uint32 GCAPS_PALMANAGED = 524288;
	public const uint32 GCAPS_DITHERONREALIZE = 2097152;
	public const uint32 GCAPS_NO64BITMEMACCESS = 4194304;
	public const uint32 GCAPS_FORCEDITHER = 8388608;
	public const uint32 GCAPS_GRAY16 = 16777216;
	public const uint32 GCAPS_ICM = 33554432;
	public const uint32 GCAPS_CMYKCOLOR = 67108864;
	public const uint32 GCAPS_LAYERED = 134217728;
	public const uint32 GCAPS_ARBRUSHTEXT = 268435456;
	public const uint32 GCAPS_SCREENPRECISION = 536870912;
	public const uint32 GCAPS_FONT_RASTERIZER = 1073741824;
	public const uint32 GCAPS_NUP = 2147483648;
	public const uint32 GCAPS2_JPEGSRC = 1;
	public const uint32 GCAPS2_xxxx = 2;
	public const uint32 GCAPS2_PNGSRC = 8;
	public const uint32 GCAPS2_CHANGEGAMMARAMP = 16;
	public const uint32 GCAPS2_ALPHACURSOR = 32;
	public const uint32 GCAPS2_SYNCFLUSH = 64;
	public const uint32 GCAPS2_SYNCTIMER = 128;
	public const uint32 GCAPS2_ICD_MULTIMON = 256;
	public const uint32 GCAPS2_MOUSETRAILS = 512;
	public const uint32 GCAPS2_RESERVED1 = 1024;
	public const uint32 GCAPS2_REMOTEDRIVER = 1024;
	public const uint32 GCAPS2_EXCLUDELAYERED = 2048;
	public const uint32 GCAPS2_INCLUDEAPIBITMAPS = 4096;
	public const uint32 GCAPS2_SHOWHIDDENPOINTER = 8192;
	public const uint32 GCAPS2_CLEARTYPE = 16384;
	public const uint32 GCAPS2_ACC_DRIVER = 32768;
	public const uint32 GCAPS2_BITMAPEXREUSE = 65536;
	public const uint32 LA_GEOMETRIC = 1;
	public const uint32 LA_ALTERNATE = 2;
	public const uint32 LA_STARTGAP = 4;
	public const uint32 LA_STYLED = 8;
	public const int32 JOIN_ROUND = 0;
	public const int32 JOIN_BEVEL = 1;
	public const int32 JOIN_MITER = 2;
	public const int32 ENDCAP_ROUND = 0;
	public const int32 ENDCAP_SQUARE = 1;
	public const int32 ENDCAP_BUTT = 2;
	public const uint32 PRIMARY_ORDER_ABC = 0;
	public const uint32 PRIMARY_ORDER_ACB = 1;
	public const uint32 PRIMARY_ORDER_BAC = 2;
	public const uint32 PRIMARY_ORDER_BCA = 3;
	public const uint32 PRIMARY_ORDER_CBA = 4;
	public const uint32 PRIMARY_ORDER_CAB = 5;
	public const uint32 HT_PATSIZE_2x2 = 0;
	public const uint32 HT_PATSIZE_2x2_M = 1;
	public const uint32 HT_PATSIZE_4x4 = 2;
	public const uint32 HT_PATSIZE_4x4_M = 3;
	public const uint32 HT_PATSIZE_6x6 = 4;
	public const uint32 HT_PATSIZE_6x6_M = 5;
	public const uint32 HT_PATSIZE_8x8 = 6;
	public const uint32 HT_PATSIZE_8x8_M = 7;
	public const uint32 HT_PATSIZE_10x10 = 8;
	public const uint32 HT_PATSIZE_10x10_M = 9;
	public const uint32 HT_PATSIZE_12x12 = 10;
	public const uint32 HT_PATSIZE_12x12_M = 11;
	public const uint32 HT_PATSIZE_14x14 = 12;
	public const uint32 HT_PATSIZE_14x14_M = 13;
	public const uint32 HT_PATSIZE_16x16 = 14;
	public const uint32 HT_PATSIZE_16x16_M = 15;
	public const uint32 HT_PATSIZE_SUPERCELL = 16;
	public const uint32 HT_PATSIZE_SUPERCELL_M = 17;
	public const uint32 HT_PATSIZE_USER = 18;
	public const uint32 HT_PATSIZE_MAX_INDEX = 18;
	public const uint32 HT_PATSIZE_DEFAULT = 17;
	public const uint32 HT_USERPAT_CX_MIN = 4;
	public const uint32 HT_USERPAT_CX_MAX = 256;
	public const uint32 HT_USERPAT_CY_MIN = 4;
	public const uint32 HT_USERPAT_CY_MAX = 256;
	public const uint32 HT_FORMAT_1BPP = 0;
	public const uint32 HT_FORMAT_4BPP = 2;
	public const uint32 HT_FORMAT_4BPP_IRGB = 3;
	public const uint32 HT_FORMAT_8BPP = 4;
	public const uint32 HT_FORMAT_16BPP = 5;
	public const uint32 HT_FORMAT_24BPP = 6;
	public const uint32 HT_FORMAT_32BPP = 7;
	public const uint32 WINDDI_MAX_BROADCAST_CONTEXT = 64;
	public const uint32 HT_FLAG_SQUARE_DEVICE_PEL = 1;
	public const uint32 HT_FLAG_HAS_BLACK_DYE = 2;
	public const uint32 HT_FLAG_ADDITIVE_PRIMS = 4;
	public const uint32 HT_FLAG_USE_8BPP_BITMASK = 8;
	public const uint32 HT_FLAG_INK_HIGH_ABSORPTION = 16;
	public const uint32 HT_FLAG_INK_ABSORPTION_INDICES = 96;
	public const uint32 HT_FLAG_DO_DEVCLR_XFORM = 128;
	public const uint32 HT_FLAG_OUTPUT_CMY = 256;
	public const uint32 HT_FLAG_PRINT_DRAFT_MODE = 512;
	public const uint32 HT_FLAG_INVERT_8BPP_BITMASK_IDX = 1024;
	public const uint32 HT_FLAG_8BPP_CMY332_MASK = 4278190080;
	public const uint32 HT_FLAG_INK_ABSORPTION_IDX0 = 0;
	public const uint32 HT_FLAG_INK_ABSORPTION_IDX1 = 32;
	public const uint32 HT_FLAG_INK_ABSORPTION_IDX2 = 64;
	public const uint32 HT_FLAG_INK_ABSORPTION_IDX3 = 96;
	public const uint32 HT_FLAG_NORMAL_INK_ABSORPTION = 0;
	public const uint32 HT_FLAG_LOW_INK_ABSORPTION = 32;
	public const uint32 HT_FLAG_LOWER_INK_ABSORPTION = 64;
	public const uint32 HT_FLAG_LOWEST_INK_ABSORPTION = 96;
	public const uint32 PPC_DEFAULT = 0;
	public const uint32 PPC_UNDEFINED = 1;
	public const uint32 PPC_RGB_ORDER_VERTICAL_STRIPES = 2;
	public const uint32 PPC_BGR_ORDER_VERTICAL_STRIPES = 3;
	public const uint32 PPC_RGB_ORDER_HORIZONTAL_STRIPES = 4;
	public const uint32 PPC_BGR_ORDER_HORIZONTAL_STRIPES = 5;
	public const uint32 PPG_DEFAULT = 0;
	public const uint32 PPG_SRGB = 1;
	public const uint32 BR_DEVICE_ICM = 1;
	public const uint32 BR_HOST_ICM = 2;
	public const uint32 BR_CMYKCOLOR = 4;
	public const uint32 BR_ORIGCOLOR = 8;
	public const uint32 FO_SIM_BOLD = 8192;
	public const uint32 FO_SIM_ITALIC = 16384;
	public const uint32 FO_EM_HEIGHT = 32768;
	public const uint32 FO_GRAY16 = 65536;
	public const uint32 FO_NOGRAY16 = 131072;
	public const uint32 FO_NOHINTS = 262144;
	public const uint32 FO_NO_CHOICE = 524288;
	public const uint32 FO_CFF = 1048576;
	public const uint32 FO_POSTSCRIPT = 2097152;
	public const uint32 FO_MULTIPLEMASTER = 4194304;
	public const uint32 FO_VERT_FACE = 8388608;
	public const uint32 FO_DBCS_FONT = 16777216;
	public const uint32 FO_NOCLEARTYPE = 33554432;
	public const uint32 FO_CLEARTYPE_X = 268435456;
	public const uint32 FO_CLEARTYPE_Y = 536870912;
	public const uint32 FO_CLEARTYPENATURAL_X = 1073741824;
	public const uint32 DC_TRIVIAL = 0;
	public const uint32 DC_RECT = 1;
	public const uint32 DC_COMPLEX = 3;
	public const uint32 FC_RECT = 1;
	public const uint32 FC_RECT4 = 2;
	public const uint32 FC_COMPLEX = 3;
	public const uint32 TC_RECTANGLES = 0;
	public const uint32 TC_PATHOBJ = 2;
	public const uint32 OC_BANK_CLIP = 1;
	public const int32 CT_RECTANGLES = 0;
	public const int32 CD_RIGHTDOWN = 0;
	public const int32 CD_LEFTDOWN = 1;
	public const int32 CD_RIGHTUP = 2;
	public const int32 CD_LEFTUP = 3;
	public const int32 CD_ANY = 4;
	public const int32 CD_LEFTWARDS = 1;
	public const int32 CD_UPWARDS = 2;
	public const int32 FO_HGLYPHS = 0;
	public const int32 FO_GLYPHBITS = 1;
	public const int32 FO_PATHOBJ = 2;
	public const int32 FD_NEGATIVE_FONT = 1;
	public const int32 FO_DEVICE_FONT = 1;
	public const int32 FO_OUTLINE_CAPABLE = 2;
	public const uint32 SO_FLAG_DEFAULT_PLACEMENT = 1;
	public const uint32 SO_HORIZONTAL = 2;
	public const uint32 SO_VERTICAL = 4;
	public const uint32 SO_REVERSED = 8;
	public const uint32 SO_ZERO_BEARINGS = 16;
	public const uint32 SO_CHAR_INC_EQUAL_BM_BASE = 32;
	public const uint32 SO_MAXEXT_EQUAL_BM_SIDE = 64;
	public const uint32 SO_DO_NOT_SUBSTITUTE_DEVICE_FONT = 128;
	public const uint32 SO_GLYPHINDEX_TEXTOUT = 256;
	public const uint32 SO_ESC_NOT_ORIENT = 512;
	public const uint32 SO_DXDY = 1024;
	public const uint32 SO_CHARACTER_EXTRA = 2048;
	public const uint32 SO_BREAK_EXTRA = 4096;
	public const uint32 FO_ATTR_MODE_ROTATE = 1;
	public const uint32 PAL_INDEXED = 1;
	public const uint32 PAL_BITFIELDS = 2;
	public const uint32 PAL_RGB = 4;
	public const uint32 PAL_BGR = 8;
	public const uint32 PAL_CMYK = 16;
	public const uint32 PO_BEZIERS = 1;
	public const uint32 PO_ELLIPSE = 2;
	public const uint32 PO_ALL_INTEGERS = 4;
	public const uint32 PO_ENUM_AS_INTEGERS = 8;
	public const uint32 PO_WIDENED = 16;
	public const uint32 PD_BEGINSUBPATH = 1;
	public const uint32 PD_ENDSUBPATH = 2;
	public const uint32 PD_RESETSTYLE = 4;
	public const uint32 PD_CLOSEFIGURE = 8;
	public const uint32 PD_BEZIERS = 16;
	public const uint32 SGI_EXTRASPACE = 0;
	public const int32 STYPE_BITMAP = 0;
	public const int32 STYPE_DEVBITMAP = 3;
	public const int32 BMF_1BPP = 1;
	public const int32 BMF_4BPP = 2;
	public const int32 BMF_8BPP = 3;
	public const int32 BMF_16BPP = 4;
	public const int32 BMF_24BPP = 5;
	public const int32 BMF_32BPP = 6;
	public const int32 BMF_4RLE = 7;
	public const int32 BMF_8RLE = 8;
	public const int32 BMF_JPEG = 9;
	public const int32 BMF_PNG = 10;
	public const uint32 BMF_TOPDOWN = 1;
	public const uint32 BMF_NOZEROINIT = 2;
	public const uint32 BMF_DONTCACHE = 4;
	public const uint32 BMF_USERMEM = 8;
	public const uint32 BMF_KMSECTION = 16;
	public const uint32 BMF_NOTSYSMEM = 32;
	public const uint32 BMF_WINDOW_BLT = 64;
	public const uint32 BMF_UMPDMEM = 128;
	public const uint32 BMF_TEMP_ALPHA = 256;
	public const uint32 BMF_ACC_NOTIFY = 32768;
	public const uint32 BMF_RMT_ENTER = 16384;
	public const uint32 BMF_RESERVED = 15872;
	public const int32 GX_IDENTITY = 0;
	public const int32 GX_OFFSET = 1;
	public const int32 GX_SCALE = 2;
	public const int32 GX_GENERAL = 3;
	public const int32 XF_LTOL = 0;
	public const int32 XF_INV_LTOL = 1;
	public const int32 XF_LTOFX = 2;
	public const int32 XF_INV_FXTOL = 3;
	public const uint32 XO_TRIVIAL = 1;
	public const uint32 XO_TABLE = 2;
	public const uint32 XO_TO_MONO = 4;
	public const uint32 XO_FROM_CMYK = 8;
	public const uint32 XO_DEVICE_ICM = 16;
	public const uint32 XO_HOST_ICM = 32;
	public const uint32 XO_SRCPALETTE = 1;
	public const uint32 XO_DESTPALETTE = 2;
	public const uint32 XO_DESTDCPALETTE = 3;
	public const uint32 XO_SRCBITFIELDS = 4;
	public const uint32 XO_DESTBITFIELDS = 5;
	public const uint32 HOOK_BITBLT = 1;
	public const uint32 HOOK_STRETCHBLT = 2;
	public const uint32 HOOK_PLGBLT = 4;
	public const uint32 HOOK_TEXTOUT = 8;
	public const uint32 HOOK_PAINT = 16;
	public const uint32 HOOK_STROKEPATH = 32;
	public const uint32 HOOK_FILLPATH = 64;
	public const uint32 HOOK_STROKEANDFILLPATH = 128;
	public const uint32 HOOK_LINETO = 256;
	public const uint32 HOOK_COPYBITS = 1024;
	public const uint32 HOOK_MOVEPANNING = 2048;
	public const uint32 HOOK_SYNCHRONIZE = 4096;
	public const uint32 HOOK_STRETCHBLTROP = 8192;
	public const uint32 HOOK_SYNCHRONIZEACCESS = 16384;
	public const uint32 HOOK_TRANSPARENTBLT = 32768;
	public const uint32 HOOK_ALPHABLEND = 65536;
	public const uint32 HOOK_GRADIENTFILL = 131072;
	public const uint32 HOOK_FLAGS = 243199;
	public const uint32 MS_NOTSYSTEMMEMORY = 1;
	public const uint32 MS_SHAREDACCESS = 2;
	public const uint32 MS_CDDDEVICEBITMAP = 4;
	public const uint32 MS_REUSEDDEVICEBITMAP = 8;
	public const uint32 DRVQUERY_USERMODE = 1;
	public const uint32 HS_DDI_MAX = 6;
	public const uint32 DRD_SUCCESS = 0;
	public const uint32 DRD_ERROR = 1;
	public const uint32 SS_SAVE = 0;
	public const uint32 SS_RESTORE = 1;
	public const uint32 SS_FREE = 2;
	public const uint32 CDBEX_REDIRECTION = 1;
	public const uint32 CDBEX_DXINTEROP = 2;
	public const uint32 CDBEX_NTSHAREDSURFACEHANDLE = 4;
	public const uint32 CDBEX_CROSSADAPTER = 8;
	public const uint32 CDBEX_REUSE = 16;
	public const uint32 WINDDI_MAXSETPALETTECOLORS = 256;
	public const uint32 WINDDI_MAXSETPALETTECOLORINDEX = 255;
	public const uint32 DM_DEFAULT = 1;
	public const uint32 DM_MONOCHROME = 2;
	public const uint32 DCR_SOLID = 0;
	public const uint32 DCR_DRIVER = 1;
	public const uint32 DCR_HALFTONE = 2;
	public const int32 RB_DITHERCOLOR = -2147483648;
	public const int32 QFT_LIGATURES = 1;
	public const int32 QFT_KERNPAIRS = 2;
	public const int32 QFT_GLYPHSET = 3;
	public const int32 QFD_GLYPHANDBITMAP = 1;
	public const int32 QFD_GLYPHANDOUTLINE = 2;
	public const int32 QFD_MAXEXTENTS = 3;
	public const int32 QFD_TT_GLYPHANDBITMAP = 4;
	public const int32 QFD_TT_GRAY1_BITMAP = 5;
	public const int32 QFD_TT_GRAY2_BITMAP = 6;
	public const int32 QFD_TT_GRAY4_BITMAP = 8;
	public const int32 QFD_TT_GRAY8_BITMAP = 9;
	public const int32 QFD_TT_MONO_BITMAP = 5;
	public const uint32 QC_OUTLINES = 1;
	public const uint32 QC_1BIT = 2;
	public const uint32 QC_4BIT = 4;
	public const uint32 FF_SIGNATURE_VERIFIED = 1;
	public const uint32 FF_IGNORED_SIGNATURE = 2;
	public const uint32 QAW_GETWIDTHS = 0;
	public const uint32 QAW_GETEASYWIDTHS = 1;
	public const uint32 TTO_METRICS_ONLY = 1;
	public const uint32 TTO_QUBICS = 2;
	public const uint32 TTO_UNHINTED = 4;
	public const int32 QFF_DESCRIPTION = 1;
	public const int32 QFF_NUMFACES = 2;
	public const int32 FP_ALTERNATEMODE = 1;
	public const int32 FP_WINDINGMODE = 2;
	public const uint32 SPS_ERROR = 0;
	public const uint32 SPS_DECLINE = 1;
	public const uint32 SPS_ACCEPT_NOEXCLUDE = 2;
	public const uint32 SPS_ACCEPT_EXCLUDE = 3;
	public const uint32 SPS_ACCEPT_SYNCHRONOUS = 4;
	public const int32 SPS_CHANGE = 1;
	public const int32 SPS_ASYNCCHANGE = 2;
	public const int32 SPS_ANIMATESTART = 4;
	public const int32 SPS_ANIMATEUPDATE = 8;
	public const int32 SPS_ALPHA = 16;
	public const int32 SPS_RESERVED = 32;
	public const int32 SPS_RESERVED1 = 64;
	public const int32 SPS_FLAGSMASK = 255;
	public const int32 SPS_LENGTHMASK = 3840;
	public const int32 SPS_FREQMASK = 1044480;
	public const uint32 ED_ABORTDOC = 1;
	public const uint32 IGRF_RGB_256BYTES = 0;
	public const uint32 IGRF_RGB_256WORDS = 1;
	public const uint32 QDS_CHECKJPEGFORMAT = 0;
	public const uint32 QDS_CHECKPNGFORMAT = 1;
	public const uint32 DSS_TIMER_EVENT = 1;
	public const uint32 DSS_FLUSH_EVENT = 2;
	public const uint32 DSS_RESERVED = 4;
	public const uint32 DSS_RESERVED1 = 8;
	public const uint32 DSS_RESERVED2 = 16;
	public const uint32 DN_ACCELERATION_LEVEL = 1;
	public const uint32 DN_DEVICE_ORIGIN = 2;
	public const uint32 DN_SLEEP_MODE = 3;
	public const uint32 DN_DRAWING_BEGIN = 4;
	public const uint32 DN_ASSOCIATE_WINDOW = 5;
	public const uint32 DN_COMPOSITION_CHANGED = 6;
	public const uint32 DN_DRAWING_BEGIN_APIBITMAP = 7;
	public const uint32 DN_SURFOBJ_DESTRUCTION = 8;
	public const uint32 WOC_RGN_CLIENT_DELTA = 1;
	public const uint32 WOC_RGN_CLIENT = 2;
	public const uint32 WOC_RGN_SURFACE_DELTA = 4;
	public const uint32 WOC_RGN_SURFACE = 8;
	public const uint32 WOC_CHANGED = 16;
	public const uint32 WOC_DELETE = 32;
	public const uint32 WOC_DRAWN = 64;
	public const uint32 WOC_SPRITE_OVERLAP = 128;
	public const uint32 WOC_SPRITE_NO_OVERLAP = 256;
	public const uint32 WOC_RGN_SPRITE = 512;
	public const uint32 WO_RGN_CLIENT_DELTA = 1;
	public const uint32 WO_RGN_CLIENT = 2;
	public const uint32 WO_RGN_SURFACE_DELTA = 4;
	public const uint32 WO_RGN_SURFACE = 8;
	public const uint32 WO_RGN_UPDATE_ALL = 16;
	public const uint32 WO_RGN_WINDOW = 32;
	public const uint32 WO_DRAW_NOTIFY = 64;
	public const uint32 WO_SPRITE_NOTIFY = 128;
	public const uint32 WO_RGN_DESKTOP_COORD = 256;
	public const uint32 WO_RGN_SPRITE = 512;
	public const uint32 EHN_RESTORED = 0;
	public const uint32 EHN_ERROR = 1;
	public const uint32 ECS_TEARDOWN = 1;
	public const uint32 ECS_REDRAW = 2;
	public const uint32 DEVHTADJF_COLOR_DEVICE = 1;
	public const uint32 DEVHTADJF_ADDITIVE_DEVICE = 2;
	public const uint32 FL_ZERO_MEMORY = 1;
	public const uint32 FL_NONPAGED_MEMORY = 2;
	public const uint32 FL_NON_SESSION = 4;
	public const uint32 QSA_MMX = 256;
	public const uint32 QSA_SSE = 8192;
	public const uint32 QSA_3DNOW = 16384;
	public const uint32 QSA_SSE1 = 8192;
	public const uint32 QSA_SSE2 = 65536;
	public const uint32 QSA_SSE3 = 524288;
	public const uint32 ENG_FNT_CACHE_READ_FAULT = 1;
	public const uint32 ENG_FNT_CACHE_WRITE_FAULT = 2;
	public const uint32 DRH_APIBITMAP = 1;
	public const uint32 MC_CAPS_NONE = 0;
	public const uint32 MC_CAPS_MONITOR_TECHNOLOGY_TYPE = 1;
	public const uint32 MC_CAPS_BRIGHTNESS = 2;
	public const uint32 MC_CAPS_CONTRAST = 4;
	public const uint32 MC_CAPS_COLOR_TEMPERATURE = 8;
	public const uint32 MC_CAPS_RED_GREEN_BLUE_GAIN = 16;
	public const uint32 MC_CAPS_RED_GREEN_BLUE_DRIVE = 32;
	public const uint32 MC_CAPS_DEGAUSS = 64;
	public const uint32 MC_CAPS_DISPLAY_AREA_POSITION = 128;
	public const uint32 MC_CAPS_DISPLAY_AREA_SIZE = 256;
	public const uint32 MC_CAPS_RESTORE_FACTORY_DEFAULTS = 1024;
	public const uint32 MC_CAPS_RESTORE_FACTORY_COLOR_DEFAULTS = 2048;
	public const uint32 MC_RESTORE_FACTORY_DEFAULTS_ENABLES_MONITOR_SETTINGS = 4096;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_NONE = 0;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_4000K = 1;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_5000K = 2;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_6500K = 4;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_7500K = 8;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_8200K = 16;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_9300K = 32;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_10000K = 64;
	public const uint32 MC_SUPPORTED_COLOR_TEMPERATURE_11500K = 128;
	public const uint32 PHYSICAL_MONITOR_DESCRIPTION_SIZE = 128;
	public const uint32 GETCONNECTEDIDS_TARGET = 0;
	public const uint32 GETCONNECTEDIDS_SOURCE = 1;
	public const uint32 S_INIT = 2;
	public const uint32 SETCONFIGURATION_STATUS_APPLIED = 0;
	public const uint32 SETCONFIGURATION_STATUS_ADDITIONAL = 1;
	public const uint32 SETCONFIGURATION_STATUS_OVERRIDDEN = 2;
}
#endregion

#region TypeDefs
typealias HSEMAPHORE = int;

typealias HSURF = int;

typealias HFASTMUTEX = int;

typealias HDRVOBJ = int;

typealias HDEV = int;

typealias HBM = int;

typealias DHSURF = int;

typealias DHPDEV = int;

#endregion


#region Enums

[AllowDuplicates]
public enum DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY : int32
{
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_OTHER = -1,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_HD15 = 0,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_SVIDEO = 1,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_COMPOSITE_VIDEO = 2,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_COMPONENT_VIDEO = 3,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_DVI = 4,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_HDMI = 5,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_LVDS = 6,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_D_JPN = 8,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_SDI = 9,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_DISPLAYPORT_EXTERNAL = 10,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_DISPLAYPORT_EMBEDDED = 11,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_UDI_EXTERNAL = 12,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_UDI_EMBEDDED = 13,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_SDTVDONGLE = 14,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_MIRACAST = 15,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_INDIRECT_WIRED = 16,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_INDIRECT_VIRTUAL = 17,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_DISPLAYPORT_USB_TUNNEL = 18,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_INTERNAL = -2147483648,
	DISPLAYCONFIG_OUTPUT_TECHNOLOGY_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_SCANLINE_ORDERING : int32
{
	DISPLAYCONFIG_SCANLINE_ORDERING_UNSPECIFIED = 0,
	DISPLAYCONFIG_SCANLINE_ORDERING_PROGRESSIVE = 1,
	DISPLAYCONFIG_SCANLINE_ORDERING_INTERLACED = 2,
	DISPLAYCONFIG_SCANLINE_ORDERING_INTERLACED_UPPERFIELDFIRST = 2,
	DISPLAYCONFIG_SCANLINE_ORDERING_INTERLACED_LOWERFIELDFIRST = 3,
	DISPLAYCONFIG_SCANLINE_ORDERING_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_SCALING : int32
{
	DISPLAYCONFIG_SCALING_IDENTITY = 1,
	DISPLAYCONFIG_SCALING_CENTERED = 2,
	DISPLAYCONFIG_SCALING_STRETCHED = 3,
	DISPLAYCONFIG_SCALING_ASPECTRATIOCENTEREDMAX = 4,
	DISPLAYCONFIG_SCALING_CUSTOM = 5,
	DISPLAYCONFIG_SCALING_PREFERRED = 128,
	DISPLAYCONFIG_SCALING_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_ROTATION : int32
{
	DISPLAYCONFIG_ROTATION_IDENTITY = 1,
	DISPLAYCONFIG_ROTATION_ROTATE90 = 2,
	DISPLAYCONFIG_ROTATION_ROTATE180 = 3,
	DISPLAYCONFIG_ROTATION_ROTATE270 = 4,
	DISPLAYCONFIG_ROTATION_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_MODE_INFO_TYPE : int32
{
	DISPLAYCONFIG_MODE_INFO_TYPE_SOURCE = 1,
	DISPLAYCONFIG_MODE_INFO_TYPE_TARGET = 2,
	DISPLAYCONFIG_MODE_INFO_TYPE_DESKTOP_IMAGE = 3,
	DISPLAYCONFIG_MODE_INFO_TYPE_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_PIXELFORMAT : int32
{
	DISPLAYCONFIG_PIXELFORMAT_8BPP = 1,
	DISPLAYCONFIG_PIXELFORMAT_16BPP = 2,
	DISPLAYCONFIG_PIXELFORMAT_24BPP = 3,
	DISPLAYCONFIG_PIXELFORMAT_32BPP = 4,
	DISPLAYCONFIG_PIXELFORMAT_NONGDI = 5,
	DISPLAYCONFIG_PIXELFORMAT_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_TOPOLOGY_ID : int32
{
	DISPLAYCONFIG_TOPOLOGY_INTERNAL = 1,
	DISPLAYCONFIG_TOPOLOGY_CLONE = 2,
	DISPLAYCONFIG_TOPOLOGY_EXTEND = 4,
	DISPLAYCONFIG_TOPOLOGY_EXTERNAL = 8,
	DISPLAYCONFIG_TOPOLOGY_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_DEVICE_INFO_TYPE : int32
{
	DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME = 1,
	DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME = 2,
	DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_PREFERRED_MODE = 3,
	DISPLAYCONFIG_DEVICE_INFO_GET_ADAPTER_NAME = 4,
	DISPLAYCONFIG_DEVICE_INFO_SET_TARGET_PERSISTENCE = 5,
	DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_BASE_TYPE = 6,
	DISPLAYCONFIG_DEVICE_INFO_GET_SUPPORT_VIRTUAL_RESOLUTION = 7,
	DISPLAYCONFIG_DEVICE_INFO_SET_SUPPORT_VIRTUAL_RESOLUTION = 8,
	DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO = 9,
	DISPLAYCONFIG_DEVICE_INFO_SET_ADVANCED_COLOR_STATE = 10,
	DISPLAYCONFIG_DEVICE_INFO_GET_SDR_WHITE_LEVEL = 11,
	DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_SPECIALIZATION = 12,
	DISPLAYCONFIG_DEVICE_INFO_SET_MONITOR_SPECIALIZATION = 13,
	DISPLAYCONFIG_DEVICE_INFO_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum MC_VCP_CODE_TYPE : int32
{
	MC_MOMENTARY = 0,
	MC_SET_PARAMETER = 1,
}


[AllowDuplicates]
public enum MC_DISPLAY_TECHNOLOGY_TYPE : int32
{
	MC_SHADOW_MASK_CATHODE_RAY_TUBE = 0,
	MC_APERTURE_GRILL_CATHODE_RAY_TUBE = 1,
	MC_THIN_FILM_TRANSISTOR = 2,
	MC_LIQUID_CRYSTAL_ON_SILICON = 3,
	MC_PLASMA = 4,
	MC_ORGANIC_LIGHT_EMITTING_DIODE = 5,
	MC_ELECTROLUMINESCENT = 6,
	MC_MICROELECTROMECHANICAL = 7,
	MC_FIELD_EMISSION_DEVICE = 8,
}


[AllowDuplicates]
public enum MC_DRIVE_TYPE : int32
{
	MC_RED_DRIVE = 0,
	MC_GREEN_DRIVE = 1,
	MC_BLUE_DRIVE = 2,
}


[AllowDuplicates]
public enum MC_GAIN_TYPE : int32
{
	MC_RED_GAIN = 0,
	MC_GREEN_GAIN = 1,
	MC_BLUE_GAIN = 2,
}


[AllowDuplicates]
public enum MC_POSITION_TYPE : int32
{
	MC_HORIZONTAL_POSITION = 0,
	MC_VERTICAL_POSITION = 1,
}


[AllowDuplicates]
public enum MC_SIZE_TYPE : int32
{
	MC_WIDTH = 0,
	MC_HEIGHT = 1,
}


[AllowDuplicates]
public enum MC_COLOR_TEMPERATURE : int32
{
	MC_COLOR_TEMPERATURE_UNKNOWN = 0,
	MC_COLOR_TEMPERATURE_4000K = 1,
	MC_COLOR_TEMPERATURE_5000K = 2,
	MC_COLOR_TEMPERATURE_6500K = 3,
	MC_COLOR_TEMPERATURE_7500K = 4,
	MC_COLOR_TEMPERATURE_8200K = 5,
	MC_COLOR_TEMPERATURE_9300K = 6,
	MC_COLOR_TEMPERATURE_10000K = 7,
	MC_COLOR_TEMPERATURE_11500K = 8,
}


[AllowDuplicates]
public enum ENG_SYSTEM_ATTRIBUTE : int32
{
	EngProcessorFeature = 1,
	EngNumberOfProcessors = 2,
	EngOptimumAvailableUserMemory = 3,
	EngOptimumAvailableSystemMemory = 4,
}


[AllowDuplicates]
public enum ENG_DEVICE_ATTRIBUTE : int32
{
	QDA_RESERVED = 0,
	QDA_ACCELERATION_LEVEL = 1,
}


[AllowDuplicates]
public enum VIDEO_WIN32K_CALLBACKS_PARAMS_TYPE : int32
{
	VideoPowerNotifyCallout = 1,
	VideoEnumChildPdoNotifyCallout = 3,
	VideoFindAdapterCallout = 4,
	VideoPnpNotifyCallout = 7,
	VideoDxgkDisplaySwitchCallout = 8,
	VideoDxgkFindAdapterTdrCallout = 10,
	VideoDxgkHardwareProtectionTeardown = 11,
	VideoRepaintDesktop = 12,
	VideoUpdateCursor = 13,
	VideoDisableMultiPlaneOverlay = 14,
	VideoDesktopDuplicationChange = 15,
	VideoBlackScreenDiagnostics = 16,
}


[AllowDuplicates]
public enum BlackScreenDiagnosticsCalloutParam : int32
{
	BlackScreenDiagnosticsData = 1,
	BlackScreenDisplayRecovery = 2,
}


[AllowDuplicates]
public enum VIDEO_BANK_TYPE : int32
{
	VideoNotBanked = 0,
	VideoBanked1RW = 1,
	VideoBanked1R1W = 2,
	VideoBanked2RW = 3,
	NumVideoBankTypes = 4,
}


[AllowDuplicates]
public enum VIDEO_POWER_STATE : int32
{
	VideoPowerUnspecified = 0,
	VideoPowerOn = 1,
	VideoPowerStandBy = 2,
	VideoPowerSuspend = 3,
	VideoPowerOff = 4,
	VideoPowerHibernate = 5,
	VideoPowerShutdown = 6,
	VideoPowerMaximum = 7,
}


[AllowDuplicates]
public enum BRIGHTNESS_INTERFACE_VERSION : int32
{
	BRIGHTNESS_INTERFACE_VERSION_1 = 1,
	BRIGHTNESS_INTERFACE_VERSION_2 = 2,
	BRIGHTNESS_INTERFACE_VERSION_3 = 3,
}


[AllowDuplicates]
public enum BACKLIGHT_OPTIMIZATION_LEVEL : int32
{
	BacklightOptimizationDisable = 0,
	BacklightOptimizationDesktop = 1,
	BacklightOptimizationDynamic = 2,
	BacklightOptimizationDimmed = 3,
	BacklightOptimizationEDR = 4,
}


[AllowDuplicates]
public enum COLORSPACE_TRANSFORM_DATA_TYPE : int32
{
	COLORSPACE_TRANSFORM_DATA_TYPE_FIXED_POINT = 0,
	COLORSPACE_TRANSFORM_DATA_TYPE_FLOAT = 1,
}


[AllowDuplicates]
public enum COLORSPACE_TRANSFORM_TARGET_CAPS_VERSION : int32
{
	COLORSPACE_TRANSFORM_VERSION_DEFAULT = 0,
	COLORSPACE_TRANSFORM_VERSION_1 = 1,
	COLORSPACE_TRANSFORM_VERSION_NOT_SUPPORTED = 0,
}


[AllowDuplicates]
public enum COLORSPACE_TRANSFORM_TYPE : int32
{
	COLORSPACE_TRANSFORM_TYPE_UNINITIALIZED = 0,
	COLORSPACE_TRANSFORM_TYPE_DEFAULT = 1,
	COLORSPACE_TRANSFORM_TYPE_RGB256x3x16 = 2,
	COLORSPACE_TRANSFORM_TYPE_DXGI_1 = 3,
	COLORSPACE_TRANSFORM_TYPE_MATRIX_3x4 = 4,
	COLORSPACE_TRANSFORM_TYPE_MATRIX_V2 = 5,
}


[AllowDuplicates]
public enum OUTPUT_WIRE_COLOR_SPACE_TYPE : int32
{
	OUTPUT_WIRE_COLOR_SPACE_G22_P709 = 0,
	OUTPUT_WIRE_COLOR_SPACE_RESERVED = 4,
	OUTPUT_WIRE_COLOR_SPACE_G2084_P2020 = 12,
	OUTPUT_WIRE_COLOR_SPACE_G22_P709_WCG = 30,
	OUTPUT_WIRE_COLOR_SPACE_G22_P2020 = 31,
	OUTPUT_WIRE_COLOR_SPACE_G2084_P2020_HDR10PLUS = 32,
	OUTPUT_WIRE_COLOR_SPACE_G2084_P2020_DVLL = 33,
}


[AllowDuplicates]
public enum OUTPUT_COLOR_ENCODING : int32
{
	OUTPUT_COLOR_ENCODING_RGB = 0,
	OUTPUT_COLOR_ENCODING_YCBCR444 = 1,
	OUTPUT_COLOR_ENCODING_YCBCR422 = 2,
	OUTPUT_COLOR_ENCODING_YCBCR420 = 3,
	OUTPUT_COLOR_ENCODING_INTENSITY = 4,
	OUTPUT_COLOR_ENCODING_FORCE_UINT32 = -1,
}


[AllowDuplicates]
public enum COLORSPACE_TRANSFORM_STAGE_CONTROL : int32
{
	ColorSpaceTransformStageControl_No_Change = 0,
	ColorSpaceTransformStageControl_Enable = 1,
	ColorSpaceTransformStageControl_Bypass = 2,
}


[AllowDuplicates]
public enum DSI_CONTROL_TRANSMISSION_MODE : int32
{
	DCT_DEFAULT = 0,
	DCT_FORCE_LOW_POWER = 1,
	DCT_FORCE_HIGH_PERFORMANCE = 2,
}


[AllowDuplicates]
public enum AR_STATE : int32
{
	AR_ENABLED = 0,
	AR_DISABLED = 1,
	AR_SUPPRESSED = 2,
	AR_REMOTESESSION = 4,
	AR_MULTIMON = 8,
	AR_NOSENSOR = 16,
	AR_NOT_SUPPORTED = 32,
	AR_DOCKED = 64,
	AR_LAPTOP = 128,
}


[AllowDuplicates]
public enum ORIENTATION_PREFERENCE : int32
{
	ORIENTATION_PREFERENCE_NONE = 0,
	ORIENTATION_PREFERENCE_LANDSCAPE = 1,
	ORIENTATION_PREFERENCE_PORTRAIT = 2,
	ORIENTATION_PREFERENCE_LANDSCAPE_FLIPPED = 4,
	ORIENTATION_PREFERENCE_PORTRAIT_FLIPPED = 8,
}

#endregion

#region Function Pointers
public function int PFN();

public function BOOL FREEOBJPROC(DRIVEROBJ* pDriverObj);

public function void WNDOBJCHANGEPROC(WNDOBJ* pwo, uint32 fl);

public function int32 SORTCOMP(void* pv1, void* pv2);

public function BOOL PFN_DrvEnableDriver(uint32 param0, uint32 param1, DRVENABLEDATA* param2);

public function DHPDEV PFN_DrvEnablePDEV(DEVMODEW* param0, PWSTR param1, uint32 param2, HSURF* param3, uint32 param4, GDIINFO* param5, uint32 param6, DEVINFO* param7, HDEV param8, PWSTR param9, HANDLE param10);

public function void PFN_DrvCompletePDEV(DHPDEV param0, HDEV param1);

public function uint32 PFN_DrvResetDevice(DHPDEV param0, void* param1);

public function void PFN_DrvDisablePDEV(DHPDEV param0);

public function void PFN_DrvSynchronize(DHPDEV param0, RECTL* param1);

public function HSURF PFN_DrvEnableSurface(DHPDEV param0);

public function void PFN_DrvDisableDriver();

public function void PFN_DrvDisableSurface(DHPDEV param0);

public function BOOL PFN_DrvAssertMode(DHPDEV param0, BOOL param1);

public function BOOL PFN_DrvTextOut(SURFOBJ* param0, STROBJ* param1, FONTOBJ* param2, CLIPOBJ* param3, RECTL* param4, RECTL* param5, BRUSHOBJ* param6, BRUSHOBJ* param7, POINTL* param8, uint32 param9);

public function BOOL PFN_DrvStretchBlt(SURFOBJ* param0, SURFOBJ* param1, SURFOBJ* param2, CLIPOBJ* param3, XLATEOBJ* param4, COLORADJUSTMENT* param5, POINTL* param6, RECTL* param7, RECTL* param8, POINTL* param9, uint32 param10);

public function BOOL PFN_DrvStretchBltROP(SURFOBJ* param0, SURFOBJ* param1, SURFOBJ* param2, CLIPOBJ* param3, XLATEOBJ* param4, COLORADJUSTMENT* param5, POINTL* param6, RECTL* param7, RECTL* param8, POINTL* param9, uint32 param10, BRUSHOBJ* param11, uint32 param12);

public function BOOL PFN_DrvTransparentBlt(SURFOBJ* param0, SURFOBJ* param1, CLIPOBJ* param2, XLATEOBJ* param3, RECTL* param4, RECTL* param5, uint32 param6, uint32 param7);

public function BOOL PFN_DrvPlgBlt(SURFOBJ* param0, SURFOBJ* param1, SURFOBJ* param2, CLIPOBJ* param3, XLATEOBJ* param4, COLORADJUSTMENT* param5, POINTL* param6, POINTFIX* param7, RECTL* param8, POINTL* param9, uint32 param10);

public function BOOL PFN_DrvBitBlt(SURFOBJ* param0, SURFOBJ* param1, SURFOBJ* param2, CLIPOBJ* param3, XLATEOBJ* param4, RECTL* param5, POINTL* param6, POINTL* param7, BRUSHOBJ* param8, POINTL* param9, uint32 param10);

public function BOOL PFN_DrvRealizeBrush(BRUSHOBJ* param0, SURFOBJ* param1, SURFOBJ* param2, SURFOBJ* param3, XLATEOBJ* param4, uint32 param5);

public function BOOL PFN_DrvCopyBits(SURFOBJ* param0, SURFOBJ* param1, CLIPOBJ* param2, XLATEOBJ* param3, RECTL* param4, POINTL* param5);

public function uint32 PFN_DrvDitherColor(DHPDEV param0, uint32 param1, uint32 param2, uint32* param3);

public function HBITMAP PFN_DrvCreateDeviceBitmap(DHPDEV param0, SIZE param1, uint32 param2);

public function void PFN_DrvDeleteDeviceBitmap(DHSURF param0);

public function BOOL PFN_DrvSetPalette(DHPDEV param0, PALOBJ* param1, uint32 param2, uint32 param3, uint32 param4);

public function uint32 PFN_DrvEscape(SURFOBJ* param0, uint32 param1, uint32 param2, void* param3, uint32 param4, void* param5);

public function uint32 PFN_DrvDrawEscape(SURFOBJ* param0, uint32 param1, CLIPOBJ* param2, RECTL* param3, uint32 param4, void* param5);

public function IFIMETRICS* PFN_DrvQueryFont(DHPDEV param0, uint param1, uint32 param2, uint* param3);

public function void* PFN_DrvQueryFontTree(DHPDEV param0, uint param1, uint32 param2, uint32 param3, uint* param4);

public function int32 PFN_DrvQueryFontData(DHPDEV param0, FONTOBJ* param1, uint32 param2, uint32 param3, GLYPHDATA* param4, void* param5, uint32 param6);

public function void PFN_DrvFree(void* param0, uint param1);

public function void PFN_DrvDestroyFont(FONTOBJ* param0);

public function int32 PFN_DrvQueryFontCaps(uint32 param0, uint32* param1);

public function uint PFN_DrvLoadFontFile(uint32 param0, uint* param1, void** param2, uint32* param3, DESIGNVECTOR* param4, uint32 param5, uint32 param6);

public function BOOL PFN_DrvUnloadFontFile(uint param0);

public function uint32 PFN_DrvSetPointerShape(SURFOBJ* param0, SURFOBJ* param1, SURFOBJ* param2, XLATEOBJ* param3, int32 param4, int32 param5, int32 param6, int32 param7, RECTL* param8, uint32 param9);

public function void PFN_DrvMovePointer(SURFOBJ* pso, int32 x, int32 y, RECTL* prcl);

public function BOOL PFN_DrvSendPage(SURFOBJ* param0);

public function BOOL PFN_DrvStartPage(SURFOBJ* pso);

public function BOOL PFN_DrvStartDoc(SURFOBJ* pso, PWSTR pwszDocName, uint32 dwJobId);

public function BOOL PFN_DrvEndDoc(SURFOBJ* pso, uint32 fl);

public function BOOL PFN_DrvQuerySpoolType(DHPDEV dhpdev, PWSTR pwchType);

public function BOOL PFN_DrvLineTo(SURFOBJ* param0, CLIPOBJ* param1, BRUSHOBJ* param2, int32 param3, int32 param4, int32 param5, int32 param6, RECTL* param7, uint32 param8);

public function BOOL PFN_DrvStrokePath(SURFOBJ* param0, PATHOBJ* param1, CLIPOBJ* param2, XFORMOBJ* param3, BRUSHOBJ* param4, POINTL* param5, LINEATTRS* param6, uint32 param7);

public function BOOL PFN_DrvFillPath(SURFOBJ* param0, PATHOBJ* param1, CLIPOBJ* param2, BRUSHOBJ* param3, POINTL* param4, uint32 param5, uint32 param6);

public function BOOL PFN_DrvStrokeAndFillPath(SURFOBJ* param0, PATHOBJ* param1, CLIPOBJ* param2, XFORMOBJ* param3, BRUSHOBJ* param4, LINEATTRS* param5, BRUSHOBJ* param6, POINTL* param7, uint32 param8, uint32 param9);

public function BOOL PFN_DrvPaint(SURFOBJ* param0, CLIPOBJ* param1, BRUSHOBJ* param2, POINTL* param3, uint32 param4);

public function uint32 PFN_DrvGetGlyphMode(DHPDEV dhpdev, FONTOBJ* pfo);

public function BOOL PFN_DrvResetPDEV(DHPDEV dhpdevOld, DHPDEV dhpdevNew);

public function uint PFN_DrvSaveScreenBits(SURFOBJ* param0, uint32 param1, uint param2, RECTL* param3);

public function uint32 PFN_DrvGetModes(HANDLE param0, uint32 param1, DEVMODEW* param2);

public function int32 PFN_DrvQueryTrueTypeTable(uint param0, uint32 param1, uint32 param2, int32 param3, uint32 param4, uint8* param5, uint8** param6, uint32* param7);

public function int32 PFN_DrvQueryTrueTypeSection(uint32 param0, uint32 param1, uint32 param2, HANDLE* param3, int32* param4);

public function int32 PFN_DrvQueryTrueTypeOutline(DHPDEV param0, FONTOBJ* param1, uint32 param2, BOOL param3, GLYPHDATA* param4, uint32 param5, TTPOLYGONHEADER* param6);

public function void* PFN_DrvGetTrueTypeFile(uint param0, uint32* param1);

public function int32 PFN_DrvQueryFontFile(uint param0, uint32 param1, uint32 param2, uint32* param3);

public function FD_GLYPHATTR* PFN_DrvQueryGlyphAttrs(FONTOBJ* param0, uint32 param1);

public function BOOL PFN_DrvQueryAdvanceWidths(DHPDEV param0, FONTOBJ* param1, uint32 param2, uint32* param3, void* param4, uint32 param5);

public function uint32 PFN_DrvFontManagement(SURFOBJ* param0, FONTOBJ* param1, uint32 param2, uint32 param3, void* param4, uint32 param5, void* param6);

public function BOOL PFN_DrvSetPixelFormat(SURFOBJ* param0, int32 param1, HWND param2);

public function int32 PFN_DrvDescribePixelFormat(DHPDEV param0, int32 param1, uint32 param2, PIXELFORMATDESCRIPTOR* param3);

public function BOOL PFN_DrvSwapBuffers(SURFOBJ* param0, WNDOBJ* param1);

public function BOOL PFN_DrvStartBanding(SURFOBJ* param0, POINTL* ppointl);

public function BOOL PFN_DrvNextBand(SURFOBJ* param0, POINTL* ppointl);

public function BOOL PFN_DrvQueryPerBandInfo(SURFOBJ* param0, PERBANDINFO* param1);

public function BOOL PFN_DrvEnableDirectDraw(DHPDEV param0, DD_CALLBACKS* param1, DD_SURFACECALLBACKS* param2, DD_PALETTECALLBACKS* param3);

public function void PFN_DrvDisableDirectDraw(DHPDEV param0);

public function BOOL PFN_DrvGetDirectDrawInfo(DHPDEV param0, DD_HALINFO* param1, uint32* param2, VIDEOMEMORY* param3, uint32* param4, uint32* param5);

public function HANDLE PFN_DrvIcmCreateColorTransform(DHPDEV param0, LOGCOLORSPACEW* param1, void* param2, uint32 param3, void* param4, uint32 param5, void* param6, uint32 param7, uint32 param8);

public function BOOL PFN_DrvIcmDeleteColorTransform(DHPDEV param0, HANDLE param1);

public function BOOL PFN_DrvIcmCheckBitmapBits(DHPDEV param0, HANDLE param1, SURFOBJ* param2, uint8* param3);

public function BOOL PFN_DrvIcmSetDeviceGammaRamp(DHPDEV param0, uint32 param1, void* param2);

public function BOOL PFN_DrvAlphaBlend(SURFOBJ* param0, SURFOBJ* param1, CLIPOBJ* param2, XLATEOBJ* param3, RECTL* param4, RECTL* param5, BLENDOBJ* param6);

public function BOOL PFN_DrvGradientFill(SURFOBJ* param0, CLIPOBJ* param1, XLATEOBJ* param2, TRIVERTEX* param3, uint32 param4, void* param5, uint32 param6, RECTL* param7, POINTL* param8, uint32 param9);

public function BOOL PFN_DrvQueryDeviceSupport(SURFOBJ* param0, XLATEOBJ* param1, XFORMOBJ* param2, uint32 param3, uint32 param4, void* param5, uint32 param6, void* param7);

public function HBITMAP PFN_DrvDeriveSurface(DD_DIRECTDRAW_GLOBAL* param0, DD_SURFACE_LOCAL* param1);

public function void PFN_DrvSynchronizeSurface(SURFOBJ* param0, RECTL* param1, uint32 param2);

public function void PFN_DrvNotify(SURFOBJ* param0, uint32 param1, void* param2);

public function int32 PFN_DrvRenderHint(DHPDEV dhpdev, uint32 NotifyCode, uint Length, void* Data);

public function HANDLE PFN_EngCreateRectRgn(int32 left, int32 top, int32 right, int32 bottom);

public function void PFN_EngDeleteRgn(HANDLE hrgn);

public function int32 PFN_EngCombineRgn(HANDLE hrgnTrg, HANDLE hrgnSrc1, HANDLE hrgnSrc2, int32 imode);

public function int32 PFN_EngCopyRgn(HANDLE hrgnDst, HANDLE hrgnSrc);

public function int32 PFN_EngIntersectRgn(HANDLE hrgnResult, HANDLE hRgnA, HANDLE hRgnB);

public function int32 PFN_EngSubtractRgn(HANDLE hrgnResult, HANDLE hRgnA, HANDLE hRgnB);

public function int32 PFN_EngUnionRgn(HANDLE hrgnResult, HANDLE hRgnA, HANDLE hRgnB);

public function int32 PFN_EngXorRgn(HANDLE hrgnResult, HANDLE hRgnA, HANDLE hRgnB);

public function HBITMAP PFN_DrvCreateDeviceBitmapEx(DHPDEV param0, SIZE param1, uint32 param2, uint32 param3, DHSURF param4, uint32 param5, uint32 param6, HANDLE* param7);

public function void PFN_DrvDeleteDeviceBitmapEx(DHSURF param0);

public function BOOL PFN_DrvAssociateSharedSurface(SURFOBJ* param0, HANDLE param1, HANDLE param2, SIZE param3);

public function NTSTATUS PFN_DrvSynchronizeRedirectionBitmaps(DHPDEV param0, uint64* param1);

public function BOOL PFN_DrvAccumulateD3DDirtyRect(SURFOBJ* param0, CDDDXGK_REDIRBITMAPPRESENTINFO* param1);

public function BOOL PFN_DrvStartDxInterop(SURFOBJ* param0, BOOL param1, void* KernelModeDeviceHandle);

public function BOOL PFN_DrvEndDxInterop(SURFOBJ* param0, BOOL param1, BOOL* param2, void* KernelModeDeviceHandle);

public function void PFN_DrvLockDisplayArea(DHPDEV param0, RECTL* param1);

public function void PFN_DrvUnlockDisplayArea(DHPDEV param0, RECTL* param1);

public function BOOL PFN_DrvSurfaceComplete(DHPDEV param0, HANDLE param1);

public function void PVIDEO_WIN32K_CALLOUT(void* Params);

#endregion

#region Structs
[CRepr]
public struct DISPLAYCONFIG_RATIONAL
{
	public uint32 Numerator;
	public uint32 Denominator;
}

[CRepr]
public struct DISPLAYCONFIG_2DREGION
{
	public uint32 cx;
	public uint32 cy;
}

[CRepr]
public struct DISPLAYCONFIG_VIDEO_SIGNAL_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _AdditionalSignalInfo_e__Struct
		{
			public uint32 _bitfield;
		}
		public _AdditionalSignalInfo_e__Struct AdditionalSignalInfo;
		public uint32 videoStandard;
	}
	public uint64 pixelRate;
	public DISPLAYCONFIG_RATIONAL hSyncFreq;
	public DISPLAYCONFIG_RATIONAL vSyncFreq;
	public DISPLAYCONFIG_2DREGION activeSize;
	public DISPLAYCONFIG_2DREGION totalSize;
	public using _Anonymous_e__Union Anonymous;
	public DISPLAYCONFIG_SCANLINE_ORDERING scanLineOrdering;
}

[CRepr]
public struct DISPLAYCONFIG_SOURCE_MODE
{
	public uint32 width;
	public uint32 height;
	public DISPLAYCONFIG_PIXELFORMAT pixelFormat;
	public POINTL position;
}

[CRepr]
public struct DISPLAYCONFIG_TARGET_MODE
{
	public DISPLAYCONFIG_VIDEO_SIGNAL_INFO targetVideoSignalInfo;
}

[CRepr]
public struct DISPLAYCONFIG_DESKTOP_IMAGE_INFO
{
	public POINTL PathSourceSize;
	public RECTL DesktopImageRegion;
	public RECTL DesktopImageClip;
}

[CRepr]
public struct DISPLAYCONFIG_MODE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public DISPLAYCONFIG_TARGET_MODE targetMode;
		public DISPLAYCONFIG_SOURCE_MODE sourceMode;
		public DISPLAYCONFIG_DESKTOP_IMAGE_INFO desktopImageInfo;
	}
	public DISPLAYCONFIG_MODE_INFO_TYPE infoType;
	public uint32 id;
	public LUID adapterId;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DISPLAYCONFIG_PATH_SOURCE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 modeInfoIdx;
		public using _Anonymous_e__Struct Anonymous;
	}
	public LUID adapterId;
	public uint32 id;
	public using _Anonymous_e__Union Anonymous;
	public uint32 statusFlags;
}

[CRepr]
public struct DISPLAYCONFIG_PATH_TARGET_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 modeInfoIdx;
		public using _Anonymous_e__Struct Anonymous;
	}
	public LUID adapterId;
	public uint32 id;
	public using _Anonymous_e__Union Anonymous;
	public DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY outputTechnology;
	public DISPLAYCONFIG_ROTATION rotation;
	public DISPLAYCONFIG_SCALING scaling;
	public DISPLAYCONFIG_RATIONAL refreshRate;
	public DISPLAYCONFIG_SCANLINE_ORDERING scanLineOrdering;
	public BOOL targetAvailable;
	public uint32 statusFlags;
}

[CRepr]
public struct DISPLAYCONFIG_PATH_INFO
{
	public DISPLAYCONFIG_PATH_SOURCE_INFO sourceInfo;
	public DISPLAYCONFIG_PATH_TARGET_INFO targetInfo;
	public uint32 flags;
}

[CRepr]
public struct DISPLAYCONFIG_DEVICE_INFO_HEADER
{
	public DISPLAYCONFIG_DEVICE_INFO_TYPE type;
	public uint32 size;
	public LUID adapterId;
	public uint32 id;
}

[CRepr]
public struct DISPLAYCONFIG_SOURCE_DEVICE_NAME
{
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public char16[32] viewGdiDeviceName;
}

[CRepr]
public struct DISPLAYCONFIG_TARGET_DEVICE_NAME_FLAGS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DISPLAYCONFIG_TARGET_DEVICE_NAME
{
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public DISPLAYCONFIG_TARGET_DEVICE_NAME_FLAGS flags;
	public DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY outputTechnology;
	public uint16 edidManufactureId;
	public uint16 edidProductCodeId;
	public uint32 connectorInstance;
	public char16[64] monitorFriendlyDeviceName;
	public char16[128] monitorDevicePath;
}

[CRepr]
public struct DISPLAYCONFIG_TARGET_PREFERRED_MODE
{
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public uint32 width;
	public uint32 height;
	public DISPLAYCONFIG_TARGET_MODE targetMode;
}

[CRepr]
public struct DISPLAYCONFIG_ADAPTER_NAME
{
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public char16[128] adapterDevicePath;
}

[CRepr]
public struct DISPLAYCONFIG_TARGET_BASE_TYPE
{
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY baseOutputTechnology;
}

[CRepr]
public struct DISPLAYCONFIG_SET_TARGET_PERSISTENCE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DISPLAYCONFIG_SUPPORT_VIRTUAL_RESOLUTION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public using _Anonymous_e__Union Anonymous;
	public DISPLAYCONFIG_COLOR_ENCODING colorEncoding;
	public uint32 bitsPerColorChannel;
}

[CRepr]
public struct DISPLAYCONFIG_SET_ADVANCED_COLOR_STATE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DISPLAYCONFIG_SDR_WHITE_LEVEL
{
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public uint32 SDRWhiteLevel;
}

[CRepr]
public struct DISPLAYCONFIG_GET_MONITOR_SPECIALIZATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DISPLAYCONFIG_SET_MONITOR_SPECIALIZATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 value;
	}
	public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
	public using _Anonymous_e__Union Anonymous;
	public Guid specializationType;
	public Guid specializationSubType;
	public char16[128] specializationApplicationName;
}

[CRepr, Packed(1)]
public struct PHYSICAL_MONITOR
{
	public HANDLE hPhysicalMonitor;
	public char16[128] szPhysicalMonitorDescription;
}

[CRepr, Packed(1)]
public struct MC_TIMING_REPORT
{
	public uint32 dwHorizontalFrequencyInHZ;
	public uint32 dwVerticalFrequencyInHZ;
	public uint8 bTimingStatusByte;
}

[CRepr]
public struct Sources
{
	public uint32 sourceId;
	public int32 numTargets;
	public uint32* aTargets mut => &aTargets_impl;
	private uint32[ANYSIZE_ARRAY] aTargets_impl;
}

[CRepr]
public struct Adapter
{
	public char16[128] AdapterName;
	public int32 numSources;
	public Sources* sources mut => &sources_impl;
	private Sources[ANYSIZE_ARRAY] sources_impl;
}

[CRepr]
public struct Adapters
{
	public int32 numAdapters;
	public Adapter* adapter mut => &adapter_impl;
	private Adapter[ANYSIZE_ARRAY] adapter_impl;
}

[CRepr]
public struct DisplayMode
{
	public char16[32] DeviceName;
	public DEVMODEW devMode;
}

[CRepr]
public struct DisplayModes
{
	public int32 numDisplayModes;
	public DisplayMode* displayMode mut => &displayMode_impl;
	private DisplayMode[ANYSIZE_ARRAY] displayMode_impl;
}

[CRepr]
public struct VIDEOPARAMETERS
{
	public Guid Guid;
	public uint32 dwOffset;
	public uint32 dwCommand;
	public uint32 dwFlags;
	public uint32 dwMode;
	public uint32 dwTVStandard;
	public uint32 dwAvailableModes;
	public uint32 dwAvailableTVStandard;
	public uint32 dwFlickerFilter;
	public uint32 dwOverScanX;
	public uint32 dwOverScanY;
	public uint32 dwMaxUnscaledX;
	public uint32 dwMaxUnscaledY;
	public uint32 dwPositionX;
	public uint32 dwPositionY;
	public uint32 dwBrightness;
	public uint32 dwContrast;
	public uint32 dwCPType;
	public uint32 dwCPCommand;
	public uint32 dwCPStandard;
	public uint32 dwCPKey;
	public uint32 bCP_APSTriggerBits;
	public uint8[256] bOEMCopyProtection;
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct POINTE
{
	public float x;
	public float y;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr, Union]
public struct FLOAT_LONG
{
	public float e;
	public int32 l;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FD_XFORM
{
	public float eXX;
	public float eXY;
	public float eYX;
	public float eYY;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct IFIMETRICS
{
	public uint32 cjThis;
	public uint32 cjIfiExtra;
	public int32 dpwszFamilyName;
	public int32 dpwszStyleName;
	public int32 dpwszFaceName;
	public int32 dpwszUniqueName;
	public int32 dpFontSim;
	public int32 lEmbedId;
	public int32 lItalicAngle;
	public int32 lCharBias;
	public int32 dpCharSets;
	public uint8 jWinCharSet;
	public uint8 jWinPitchAndFamily;
	public uint16 usWinWeight;
	public uint32 flInfo;
	public uint16 fsSelection;
	public uint16 fsType;
	public int16 fwdUnitsPerEm;
	public int16 fwdLowestPPEm;
	public int16 fwdWinAscender;
	public int16 fwdWinDescender;
	public int16 fwdMacAscender;
	public int16 fwdMacDescender;
	public int16 fwdMacLineGap;
	public int16 fwdTypoAscender;
	public int16 fwdTypoDescender;
	public int16 fwdTypoLineGap;
	public int16 fwdAveCharWidth;
	public int16 fwdMaxCharInc;
	public int16 fwdCapHeight;
	public int16 fwdXHeight;
	public int16 fwdSubscriptXSize;
	public int16 fwdSubscriptYSize;
	public int16 fwdSubscriptXOffset;
	public int16 fwdSubscriptYOffset;
	public int16 fwdSuperscriptXSize;
	public int16 fwdSuperscriptYSize;
	public int16 fwdSuperscriptXOffset;
	public int16 fwdSuperscriptYOffset;
	public int16 fwdUnderscoreSize;
	public int16 fwdUnderscorePosition;
	public int16 fwdStrikeoutSize;
	public int16 fwdStrikeoutPosition;
	public uint8 chFirstChar;
	public uint8 chLastChar;
	public uint8 chDefaultChar;
	public uint8 chBreakChar;
	public char16 wcFirstChar;
	public char16 wcLastChar;
	public char16 wcDefaultChar;
	public char16 wcBreakChar;
	public POINTL ptlBaseline;
	public POINTL ptlAspect;
	public POINTL ptlCaret;
	public RECTL rclFontBox;
	public uint8[4] achVendId;
	public uint32 cKerningPairs;
	public uint32 ulPanoseCulture;
	public PANOSE panose;
	public void* Align;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct LINEATTRS
{
	public uint32 fl;
	public uint32 iJoin;
	public uint32 iEndCap;
	public FLOAT_LONG elWidth;
	public float eMiterLimit;
	public uint32 cstyle;
	public FLOAT_LONG* pstyle;
	public FLOAT_LONG elStyleState;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct XFORML
{
	public float eM11;
	public float eM12;
	public float eM21;
	public float eM22;
	public float eDx;
	public float eDy;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FLOATOBJ_XFORM
{
	public float eM11;
	public float eM12;
	public float eM21;
	public float eM22;
	public float eDx;
	public float eDy;
}
#endif

#if BF_32_BIT
[CRepr]
public struct POINTE
{
	public uint32 x;
	public uint32 y;
}
#endif

#if BF_32_BIT
[CRepr, Union]
public struct FLOAT_LONG
{
	public uint32 e;
	public int32 l;
}
#endif

[CRepr]
public struct POINTFIX
{
	public int32 x;
	public int32 y;
}

[CRepr]
public struct RECTFX
{
	public int32 xLeft;
	public int32 yTop;
	public int32 xRight;
	public int32 yBottom;
}

#if BF_32_BIT
[CRepr]
public struct FD_XFORM
{
	public uint32 eXX;
	public uint32 eXY;
	public uint32 eYX;
	public uint32 eYY;
}
#endif

[CRepr]
public struct FD_DEVICEMETRICS
{
	public uint32 flRealizedType;
	public POINTE pteBase;
	public POINTE pteSide;
	public int32 lD;
	public int32 fxMaxAscender;
	public int32 fxMaxDescender;
	public POINTL ptlUnderline1;
	public POINTL ptlStrikeOut;
	public POINTL ptlULThickness;
	public POINTL ptlSOThickness;
	public uint32 cxMax;
	public uint32 cyMax;
	public uint32 cjGlyphMax;
	public FD_XFORM fdxQuantized;
	public int32 lNonLinearExtLeading;
	public int32 lNonLinearIntLeading;
	public int32 lNonLinearMaxCharWidth;
	public int32 lNonLinearAvgCharWidth;
	public int32 lMinA;
	public int32 lMinC;
	public int32 lMinD;
	public int32* alReserved mut => &alReserved_impl;
	private int32[ANYSIZE_ARRAY] alReserved_impl;
}

[CRepr]
public struct LIGATURE
{
	public uint32 culSize;
	public PWSTR pwsz;
	public uint32 chglyph;
	public uint32* ahglyph mut => &ahglyph_impl;
	private uint32[ANYSIZE_ARRAY] ahglyph_impl;
}

[CRepr]
public struct FD_LIGATURE
{
	public uint32 culThis;
	public uint32 ulType;
	public uint32 cLigatures;
	public LIGATURE* alig mut => &alig_impl;
	private LIGATURE[ANYSIZE_ARRAY] alig_impl;
}

[CRepr]
public struct POINTQF
{
	public LARGE_INTEGER x;
	public LARGE_INTEGER y;
}

[CRepr]
public struct WCRUN
{
	public char16 wcLow;
	public uint16 cGlyphs;
	public uint32* phg;
}

[CRepr]
public struct FD_GLYPHSET
{
	public uint32 cjThis;
	public uint32 flAccel;
	public uint32 cGlyphsSupported;
	public uint32 cRuns;
	public WCRUN* awcrun mut => &awcrun_impl;
	private WCRUN[ANYSIZE_ARRAY] awcrun_impl;
}

[CRepr]
public struct FD_GLYPHATTR
{
	public uint32 cjThis;
	public uint32 cGlyphs;
	public uint32 iMode;
	public uint8* aGlyphAttr mut => &aGlyphAttr_impl;
	private uint8[ANYSIZE_ARRAY] aGlyphAttr_impl;
}

[CRepr]
public struct FD_KERNINGPAIR
{
	public char16 wcFirst;
	public char16 wcSecond;
	public int16 fwdKern;
}

[CRepr]
public struct FONTDIFF
{
	public uint8 jReserved1;
	public uint8 jReserved2;
	public uint8 jReserved3;
	public uint8 bWeight;
	public uint16 usWinWeight;
	public uint16 fsSelection;
	public int16 fwdAveCharWidth;
	public int16 fwdMaxCharInc;
	public POINTL ptlCaret;
}

[CRepr]
public struct FONTSIM
{
	public int32 dpBold;
	public int32 dpItalic;
	public int32 dpBoldItalic;
}

#if BF_32_BIT
[CRepr]
public struct IFIMETRICS
{
	public uint32 cjThis;
	public uint32 cjIfiExtra;
	public int32 dpwszFamilyName;
	public int32 dpwszStyleName;
	public int32 dpwszFaceName;
	public int32 dpwszUniqueName;
	public int32 dpFontSim;
	public int32 lEmbedId;
	public int32 lItalicAngle;
	public int32 lCharBias;
	public int32 dpCharSets;
	public uint8 jWinCharSet;
	public uint8 jWinPitchAndFamily;
	public uint16 usWinWeight;
	public uint32 flInfo;
	public uint16 fsSelection;
	public uint16 fsType;
	public int16 fwdUnitsPerEm;
	public int16 fwdLowestPPEm;
	public int16 fwdWinAscender;
	public int16 fwdWinDescender;
	public int16 fwdMacAscender;
	public int16 fwdMacDescender;
	public int16 fwdMacLineGap;
	public int16 fwdTypoAscender;
	public int16 fwdTypoDescender;
	public int16 fwdTypoLineGap;
	public int16 fwdAveCharWidth;
	public int16 fwdMaxCharInc;
	public int16 fwdCapHeight;
	public int16 fwdXHeight;
	public int16 fwdSubscriptXSize;
	public int16 fwdSubscriptYSize;
	public int16 fwdSubscriptXOffset;
	public int16 fwdSubscriptYOffset;
	public int16 fwdSuperscriptXSize;
	public int16 fwdSuperscriptYSize;
	public int16 fwdSuperscriptXOffset;
	public int16 fwdSuperscriptYOffset;
	public int16 fwdUnderscoreSize;
	public int16 fwdUnderscorePosition;
	public int16 fwdStrikeoutSize;
	public int16 fwdStrikeoutPosition;
	public uint8 chFirstChar;
	public uint8 chLastChar;
	public uint8 chDefaultChar;
	public uint8 chBreakChar;
	public char16 wcFirstChar;
	public char16 wcLastChar;
	public char16 wcDefaultChar;
	public char16 wcBreakChar;
	public POINTL ptlBaseline;
	public POINTL ptlAspect;
	public POINTL ptlCaret;
	public RECTL rclFontBox;
	public uint8[4] achVendId;
	public uint32 cKerningPairs;
	public uint32 ulPanoseCulture;
	public PANOSE panose;
}
#endif

[CRepr]
public struct IFIEXTRA
{
	public uint32 ulIdentifier;
	public int32 dpFontSig;
	public uint32 cig;
	public int32 dpDesignVector;
	public int32 dpAxesInfoW;
	public uint32* aulReserved mut => &aulReserved_impl;
	private uint32[ANYSIZE_ARRAY] aulReserved_impl;
}

[CRepr]
public struct DRVFN
{
	public uint32 iFunc;
	public PFN pfn;
}

[CRepr]
public struct DRVENABLEDATA
{
	public uint32 iDriverVersion;
	public uint32 c;
	public DRVFN* pdrvfn;
}

[CRepr]
public struct DEVINFO
{
	public uint32 flGraphicsCaps;
	public LOGFONTW lfDefaultFont;
	public LOGFONTW lfAnsiVarFont;
	public LOGFONTW lfAnsiFixFont;
	public uint32 cFonts;
	public uint32 iDitherFormat;
	public uint16 cxDither;
	public uint16 cyDither;
	public HPALETTE hpalDefault;
	public uint32 flGraphicsCaps2;
}

#if BF_32_BIT
[CRepr]
public struct LINEATTRS
{
	public uint32 fl;
	public uint32 iJoin;
	public uint32 iEndCap;
	public FLOAT_LONG elWidth;
	public uint32 eMiterLimit;
	public uint32 cstyle;
	public FLOAT_LONG* pstyle;
	public FLOAT_LONG elStyleState;
}
#endif

#if BF_32_BIT
[CRepr]
public struct XFORML
{
	public uint32 eM11;
	public uint32 eM12;
	public uint32 eM21;
	public uint32 eM22;
	public uint32 eDx;
	public uint32 eDy;
}
#endif

[CRepr]
public struct CIECHROMA
{
	public int32 x;
	public int32 y;
	public int32 Y;
}

[CRepr]
public struct COLORINFO
{
	public CIECHROMA Red;
	public CIECHROMA Green;
	public CIECHROMA Blue;
	public CIECHROMA Cyan;
	public CIECHROMA Magenta;
	public CIECHROMA Yellow;
	public CIECHROMA AlignmentWhite;
	public int32 RedGamma;
	public int32 GreenGamma;
	public int32 BlueGamma;
	public int32 MagentaInCyanDye;
	public int32 YellowInCyanDye;
	public int32 CyanInMagentaDye;
	public int32 YellowInMagentaDye;
	public int32 CyanInYellowDye;
	public int32 MagentaInYellowDye;
}

[CRepr]
public struct CDDDXGK_REDIRBITMAPPRESENTINFO
{
	public uint32 NumDirtyRects;
	public RECT* DirtyRect;
	public uint32 NumContexts;
	public HANDLE[65] hContext;
	public BOOLEAN bDoNotSynchronizeWithDxContent;
}

[CRepr]
public struct GDIINFO
{
	public uint32 ulVersion;
	public uint32 ulTechnology;
	public uint32 ulHorzSize;
	public uint32 ulVertSize;
	public uint32 ulHorzRes;
	public uint32 ulVertRes;
	public uint32 cBitsPixel;
	public uint32 cPlanes;
	public uint32 ulNumColors;
	public uint32 flRaster;
	public uint32 ulLogPixelsX;
	public uint32 ulLogPixelsY;
	public uint32 flTextCaps;
	public uint32 ulDACRed;
	public uint32 ulDACGreen;
	public uint32 ulDACBlue;
	public uint32 ulAspectX;
	public uint32 ulAspectY;
	public uint32 ulAspectXY;
	public int32 xStyleStep;
	public int32 yStyleStep;
	public int32 denStyleStep;
	public POINTL ptlPhysOffset;
	public SIZE szlPhysSize;
	public uint32 ulNumPalReg;
	public COLORINFO ciDevice;
	public uint32 ulDevicePelsDPI;
	public uint32 ulPrimaryOrder;
	public uint32 ulHTPatternSize;
	public uint32 ulHTOutputFormat;
	public uint32 flHTFlags;
	public uint32 ulVRefresh;
	public uint32 ulBltAlignment;
	public uint32 ulPanningHorzRes;
	public uint32 ulPanningVertRes;
	public uint32 xPanningAlignment;
	public uint32 yPanningAlignment;
	public uint32 cxHTPat;
	public uint32 cyHTPat;
	public uint8* pHTPatA;
	public uint8* pHTPatB;
	public uint8* pHTPatC;
	public uint32 flShadeBlend;
	public uint32 ulPhysicalPixelCharacteristics;
	public uint32 ulPhysicalPixelGamma;
}

[CRepr]
public struct BRUSHOBJ
{
	public uint32 iSolidColor;
	public void* pvRbrush;
	public uint32 flColorType;
}

[CRepr]
public struct CLIPOBJ
{
	public uint32 iUniq;
	public RECTL rclBounds;
	public uint8 iDComplexity;
	public uint8 iFComplexity;
	public uint8 iMode;
	public uint8 fjOptions;
}

[CRepr]
public struct DRIVEROBJ
{
	public void* pvObj;
	public FREEOBJPROC pFreeProc;
	public HDEV hdev;
	public DHPDEV dhpdev;
}

[CRepr]
public struct FONTOBJ
{
	public uint32 iUniq;
	public uint32 iFace;
	public uint32 cxMax;
	public uint32 flFontType;
	public uint iTTUniq;
	public uint iFile;
	public SIZE sizLogResPpi;
	public uint32 ulStyleSize;
	public void* pvConsumer;
	public void* pvProducer;
}

[CRepr]
public struct BLENDOBJ
{
	public BLENDFUNCTION BlendFunction;
}

[CRepr]
public struct PALOBJ
{
	public uint32 ulReserved;
}

[CRepr]
public struct PATHOBJ
{
	public uint32 fl;
	public uint32 cCurves;
}

[CRepr]
public struct SURFOBJ
{
	public DHSURF dhsurf;
	public HSURF hsurf;
	public DHPDEV dhpdev;
	public HDEV hdev;
	public SIZE sizlBitmap;
	public uint32 cjBits;
	public void* pvBits;
	public void* pvScan0;
	public int32 lDelta;
	public uint32 iUniq;
	public uint32 iBitmapFormat;
	public uint16 iType;
	public uint16 fjBitmap;
}

[CRepr]
public struct WNDOBJ
{
	public CLIPOBJ coClient;
	public void* pvConsumer;
	public RECTL rclClient;
	public SURFOBJ* psoOwner;
}

[CRepr]
public struct XFORMOBJ
{
	public uint32 ulReserved;
}

[CRepr]
public struct XLATEOBJ
{
	public uint32 iUniq;
	public uint32 flXlate;
	public uint16 iSrcType;
	public uint16 iDstType;
	public uint32 cEntries;
	public uint32* pulXlate;
}

[CRepr]
public struct ENUMRECTS
{
	public uint32 c;
	public RECTL* arcl mut => &arcl_impl;
	private RECTL[ANYSIZE_ARRAY] arcl_impl;
}

[CRepr]
public struct GLYPHBITS
{
	public POINTL ptlOrigin;
	public SIZE sizlBitmap;
	public uint8* aj mut => &aj_impl;
	private uint8[ANYSIZE_ARRAY] aj_impl;
}

[CRepr, Union]
public struct GLYPHDEF
{
	public GLYPHBITS* pgb;
	public PATHOBJ* ppo;
}

[CRepr]
public struct GLYPHPOS
{
	public uint32 hg;
	public GLYPHDEF* pgdf;
	public POINTL ptl;
}

[CRepr]
public struct GLYPHDATA
{
	public GLYPHDEF gdf;
	public uint32 hg;
	public int32 fxD;
	public int32 fxA;
	public int32 fxAB;
	public int32 fxInkTop;
	public int32 fxInkBottom;
	public RECTL rclInk;
	public POINTQF ptqD;
}

[CRepr]
public struct STROBJ
{
	public uint32 cGlyphs;
	public uint32 flAccel;
	public uint32 ulCharInc;
	public RECTL rclBkGround;
	public GLYPHPOS* pgp;
	public PWSTR pwszOrg;
}

[CRepr]
public struct FONTINFO
{
	public uint32 cjThis;
	public uint32 flCaps;
	public uint32 cGlyphsSupported;
	public uint32 cjMaxGlyph1;
	public uint32 cjMaxGlyph4;
	public uint32 cjMaxGlyph8;
	public uint32 cjMaxGlyph32;
}

[CRepr]
public struct PATHDATA
{
	public uint32 flags;
	public uint32 count;
	public POINTFIX* pptfx;
}

[CRepr]
public struct RUN
{
	public int32 iStart;
	public int32 iStop;
}

[CRepr]
public struct CLIPLINE
{
	public POINTFIX ptfxA;
	public POINTFIX ptfxB;
	public int32 lStyleState;
	public uint32 c;
	public RUN* arun mut => &arun_impl;
	private RUN[ANYSIZE_ARRAY] arun_impl;
}

[CRepr]
public struct PERBANDINFO
{
	public BOOL bRepeatThisBand;
	public SIZE szlBand;
	public uint32 ulHorzRes;
	public uint32 ulVertRes;
}

[CRepr]
public struct GAMMARAMP
{
	public uint16[256] Red;
	public uint16[256] Green;
	public uint16[256] Blue;
}

[CRepr]
public struct DEVHTINFO
{
	public uint32 HTFlags;
	public uint32 HTPatternSize;
	public uint32 DevPelsDPI;
	public COLORINFO ColorInfo;
}

[CRepr]
public struct DEVHTADJDATA
{
	public uint32 DeviceFlags;
	public uint32 DeviceXDPI;
	public uint32 DeviceYDPI;
	public DEVHTINFO* pDefHTInfo;
	public DEVHTINFO* pAdjHTInfo;
}

[CRepr]
public struct TYPE1_FONT
{
	public HANDLE hPFM;
	public HANDLE hPFB;
	public uint32 ulIdentifier;
}

[CRepr]
public struct ENGSAFESEMAPHORE
{
	public HSEMAPHORE hsem;
	public int32 lCount;
}

#if BF_32_BIT
[CRepr]
public struct FLOATOBJ
{
	public uint32 ul1;
	public uint32 ul2;
}
#endif

#if BF_32_BIT
[CRepr]
public struct FLOATOBJ_XFORM
{
	public FLOATOBJ eM11;
	public FLOATOBJ eM12;
	public FLOATOBJ eM21;
	public FLOATOBJ eM22;
	public FLOATOBJ eDx;
	public FLOATOBJ eDy;
}
#endif

[CRepr]
public struct ENG_TIME_FIELDS
{
	public uint16 usYear;
	public uint16 usMonth;
	public uint16 usDay;
	public uint16 usHour;
	public uint16 usMinute;
	public uint16 usSecond;
	public uint16 usMilliseconds;
	public uint16 usWeekday;
}

[CRepr]
public struct EMFINFO
{
	public uint32 nSize;
	public HDC hdc;
	public uint8* pvEMF;
	public uint8* pvCurrentRecord;
}

[CRepr]
public struct DRH_APIBITMAPDATA
{
	public SURFOBJ* pso;
	public BOOL b;
}

[CRepr]
public struct INDIRECT_DISPLAY_INFO
{
	public LUID DisplayAdapterLuid;
	public uint32 Flags;
	public uint32 NumMonitors;
	public uint32 DisplayAdapterTargetBase;
}

[CRepr]
public struct VIDEO_VDM
{
	public HANDLE ProcessHandle;
}

[CRepr]
public struct VIDEO_REGISTER_VDM
{
	public uint32 MinimumStateSize;
}

[CRepr]
public struct VIDEO_MONITOR_DESCRIPTOR
{
	public uint32 DescriptorSize;
	public uint8* Descriptor mut => &Descriptor_impl;
	private uint8[ANYSIZE_ARRAY] Descriptor_impl;
}

[CRepr]
public struct DXGK_WIN32K_PARAM_DATA
{
	public void* PathsArray;
	public void* ModesArray;
	public uint32 NumPathArrayElements;
	public uint32 NumModeArrayElements;
	public uint32 SDCFlags;
}

[CRepr]
public struct VIDEO_WIN32K_CALLBACKS_PARAMS
{
	public VIDEO_WIN32K_CALLBACKS_PARAMS_TYPE CalloutType;
	public void* PhysDisp;
	public uint Param;
	public int32 Status;
	public BOOLEAN LockUserSession;
	public BOOLEAN IsPostDevice;
	public BOOLEAN SurpriseRemoval;
	public BOOLEAN WaitForQueueReady;
}

[CRepr]
public struct VIDEO_WIN32K_CALLBACKS
{
	public void* PhysDisp;
	public PVIDEO_WIN32K_CALLOUT Callout;
	public uint32 bACPI;
	public HANDLE pPhysDeviceObject;
	public uint32 DualviewFlags;
}

[CRepr]
public struct VIDEO_DEVICE_SESSION_STATUS
{
	public uint32 bEnable;
	public uint32 bSuccess;
}

[CRepr]
public struct VIDEO_HARDWARE_STATE_HEADER
{
	public uint32 Length;
	public uint8[48] PortValue;
	public uint32 AttribIndexDataState;
	public uint32 BasicSequencerOffset;
	public uint32 BasicCrtContOffset;
	public uint32 BasicGraphContOffset;
	public uint32 BasicAttribContOffset;
	public uint32 BasicDacOffset;
	public uint32 BasicLatchesOffset;
	public uint32 ExtendedSequencerOffset;
	public uint32 ExtendedCrtContOffset;
	public uint32 ExtendedGraphContOffset;
	public uint32 ExtendedAttribContOffset;
	public uint32 ExtendedDacOffset;
	public uint32 ExtendedValidatorStateOffset;
	public uint32 ExtendedMiscDataOffset;
	public uint32 PlaneLength;
	public uint32 Plane1Offset;
	public uint32 Plane2Offset;
	public uint32 Plane3Offset;
	public uint32 Plane4Offset;
	public uint32 VGAStateFlags;
	public uint32 DIBOffset;
	public uint32 DIBBitsPerPixel;
	public uint32 DIBXResolution;
	public uint32 DIBYResolution;
	public uint32 DIBXlatOffset;
	public uint32 DIBXlatLength;
	public uint32 VesaInfoOffset;
	public void* FrameBufferData;
}

[CRepr]
public struct VIDEO_HARDWARE_STATE
{
	public VIDEO_HARDWARE_STATE_HEADER* StateHeader;
	public uint32 StateLength;
}

[CRepr]
public struct VIDEO_NUM_MODES
{
	public uint32 NumModes;
	public uint32 ModeInformationLength;
}

[CRepr]
public struct VIDEO_MODE
{
	public uint32 RequestedMode;
}

[CRepr]
public struct VIDEO_MODE_INFORMATION
{
	public uint32 Length;
	public uint32 ModeIndex;
	public uint32 VisScreenWidth;
	public uint32 VisScreenHeight;
	public uint32 ScreenStride;
	public uint32 NumberOfPlanes;
	public uint32 BitsPerPlane;
	public uint32 Frequency;
	public uint32 XMillimeter;
	public uint32 YMillimeter;
	public uint32 NumberRedBits;
	public uint32 NumberGreenBits;
	public uint32 NumberBlueBits;
	public uint32 RedMask;
	public uint32 GreenMask;
	public uint32 BlueMask;
	public uint32 AttributeFlags;
	public uint32 VideoMemoryBitmapWidth;
	public uint32 VideoMemoryBitmapHeight;
	public uint32 DriverSpecificAttributeFlags;
}

[CRepr]
public struct VIDEO_LOAD_FONT_INFORMATION
{
	public uint16 WidthInPixels;
	public uint16 HeightInPixels;
	public uint32 FontSize;
	public uint8* Font mut => &Font_impl;
	private uint8[ANYSIZE_ARRAY] Font_impl;
}

[CRepr]
public struct VIDEO_PALETTE_DATA
{
	public uint16 NumEntries;
	public uint16 FirstEntry;
	public uint16* Colors mut => &Colors_impl;
	private uint16[ANYSIZE_ARRAY] Colors_impl;
}

[CRepr]
public struct VIDEO_CLUTDATA
{
	public uint8 Red;
	public uint8 Green;
	public uint8 Blue;
	public uint8 Unused;
}

[CRepr]
public struct VIDEO_CLUT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public VIDEO_CLUTDATA RgbArray;
		public uint32 RgbLong;
	}
	public uint16 NumEntries;
	public uint16 FirstEntry;
	public _Anonymous_e__Union* LookupTable mut => &LookupTable_impl;
	private _Anonymous_e__Union[ANYSIZE_ARRAY] LookupTable_impl;
}

[CRepr]
public struct VIDEO_CURSOR_POSITION
{
	public int16 Column;
	public int16 Row;
}

[CRepr]
public struct VIDEO_CURSOR_ATTRIBUTES
{
	public uint16 Width;
	public uint16 Height;
	public int16 Column;
	public int16 Row;
	public uint8 Rate;
	public uint8 Enable;
}

[CRepr]
public struct VIDEO_POINTER_POSITION
{
	public int16 Column;
	public int16 Row;
}

[CRepr]
public struct VIDEO_POINTER_ATTRIBUTES
{
	public uint32 Flags;
	public uint32 Width;
	public uint32 Height;
	public uint32 WidthInBytes;
	public uint32 Enable;
	public int16 Column;
	public int16 Row;
	public uint8* Pixels mut => &Pixels_impl;
	private uint8[ANYSIZE_ARRAY] Pixels_impl;
}

[CRepr]
public struct VIDEO_POINTER_CAPABILITIES
{
	public uint32 Flags;
	public uint32 MaxWidth;
	public uint32 MaxHeight;
	public uint32 HWPtrBitmapStart;
	public uint32 HWPtrBitmapEnd;
}

[CRepr]
public struct VIDEO_BANK_SELECT
{
	public uint32 Length;
	public uint32 Size;
	public uint32 BankingFlags;
	public uint32 BankingType;
	public uint32 PlanarHCBankingType;
	public uint32 BitmapWidthInBytes;
	public uint32 BitmapSize;
	public uint32 Granularity;
	public uint32 PlanarHCGranularity;
	public uint32 CodeOffset;
	public uint32 PlanarHCBankCodeOffset;
	public uint32 PlanarHCEnableCodeOffset;
	public uint32 PlanarHCDisableCodeOffset;
}

[CRepr]
public struct VIDEO_MEMORY
{
	public void* RequestedVirtualAddress;
}

[CRepr]
public struct VIDEO_SHARE_MEMORY
{
	public HANDLE ProcessHandle;
	public uint32 ViewOffset;
	public uint32 ViewSize;
	public void* RequestedVirtualAddress;
}

[CRepr]
public struct VIDEO_SHARE_MEMORY_INFORMATION
{
	public uint32 SharedViewOffset;
	public uint32 SharedViewSize;
	public void* VirtualAddress;
}

[CRepr]
public struct VIDEO_MEMORY_INFORMATION
{
	public void* VideoRamBase;
	public uint32 VideoRamLength;
	public void* FrameBufferBase;
	public uint32 FrameBufferLength;
}

[CRepr]
public struct VIDEO_PUBLIC_ACCESS_RANGES
{
	public uint32 InIoSpace;
	public uint32 MappedInIoSpace;
	public void* VirtualAddress;
}

[CRepr]
public struct VIDEO_COLOR_CAPABILITIES
{
	public uint32 Length;
	public uint32 AttributeFlags;
	public int32 RedPhosphoreDecay;
	public int32 GreenPhosphoreDecay;
	public int32 BluePhosphoreDecay;
	public int32 WhiteChromaticity_x;
	public int32 WhiteChromaticity_y;
	public int32 WhiteChromaticity_Y;
	public int32 RedChromaticity_x;
	public int32 RedChromaticity_y;
	public int32 GreenChromaticity_x;
	public int32 GreenChromaticity_y;
	public int32 BlueChromaticity_x;
	public int32 BlueChromaticity_y;
	public int32 WhiteGamma;
	public int32 RedGamma;
	public int32 GreenGamma;
	public int32 BlueGamma;
}

[CRepr]
public struct VIDEO_POWER_MANAGEMENT
{
	public uint32 Length;
	public uint32 DPMSVersion;
	public uint32 PowerState;
}

[CRepr]
public struct VIDEO_COLOR_LUT_DATA
{
	public uint32 Length;
	public uint32 LutDataFormat;
	public uint8* LutData mut => &LutData_impl;
	private uint8[ANYSIZE_ARRAY] LutData_impl;
}

[CRepr]
public struct VIDEO_LUT_RGB256WORDS
{
	public uint16[256] Red;
	public uint16[256] Green;
	public uint16[256] Blue;
}

[CRepr]
public struct BANK_POSITION
{
	public uint32 ReadBankPosition;
	public uint32 WriteBankPosition;
}

[CRepr]
public struct DISPLAY_BRIGHTNESS
{
	public uint8 ucDisplayPolicy;
	public uint8 ucACBrightness;
	public uint8 ucDCBrightness;
}

[CRepr]
public struct VIDEO_BRIGHTNESS_POLICY
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint8 BatteryLevel;
		public uint8 Brightness;
	}
	public BOOLEAN DefaultToBiosPolicy;
	public uint8 LevelCount;
	public _Anonymous_e__Struct* Level mut => &Level_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] Level_impl;
}

[CRepr]
public struct FSCNTL_SCREEN_INFO
{
	public COORD Position;
	public COORD ScreenSize;
	public uint32 nNumberOfChars;
}

[CRepr]
public struct FONT_IMAGE_INFO
{
	public COORD FontSize;
	public uint8* ImageBits;
}

[CRepr]
public struct CHAR_IMAGE_INFO
{
	public CHAR_INFO CharInfo;
	public FONT_IMAGE_INFO FontImageInfo;
}

[CRepr]
public struct VGA_CHAR
{
	public CHAR Char;
	public CHAR Attributes;
}

[CRepr]
public struct FSVIDEO_COPY_FRAME_BUFFER
{
	public FSCNTL_SCREEN_INFO SrcScreen;
	public FSCNTL_SCREEN_INFO DestScreen;
}

[CRepr]
public struct FSVIDEO_WRITE_TO_FRAME_BUFFER
{
	public CHAR_IMAGE_INFO* SrcBuffer;
	public FSCNTL_SCREEN_INFO DestScreen;
}

[CRepr]
public struct FSVIDEO_REVERSE_MOUSE_POINTER
{
	public FSCNTL_SCREEN_INFO Screen;
	public uint32 dwType;
}

[CRepr]
public struct FSVIDEO_MODE_INFORMATION
{
	public VIDEO_MODE_INFORMATION VideoMode;
	public VIDEO_MEMORY_INFORMATION VideoMemory;
}

[CRepr]
public struct FSVIDEO_SCREEN_INFORMATION
{
	public COORD ScreenSize;
	public COORD FontSize;
}

[CRepr]
public struct FSVIDEO_CURSOR_POSITION
{
	public VIDEO_CURSOR_POSITION Coord;
	public uint32 dwType;
}

[CRepr]
public struct ENG_EVENT
{
	public void* pKEvent;
	public uint32 fFlags;
}

[CRepr]
public struct VIDEO_PERFORMANCE_COUNTER
{
	public uint64[10] NbOfAllocationEvicted;
	public uint64[10] NbOfAllocationMarked;
	public uint64[10] NbOfAllocationRestored;
	public uint64[10] KBytesEvicted;
	public uint64[10] KBytesMarked;
	public uint64[10] KBytesRestored;
	public uint64 NbProcessCommited;
	public uint64 NbAllocationCommited;
	public uint64 NbAllocationMarked;
	public uint64 KBytesAllocated;
	public uint64 KBytesAvailable;
	public uint64 KBytesCurMarked;
	public uint64 Reference;
	public uint64 Unreference;
	public uint64 TrueReference;
	public uint64 NbOfPageIn;
	public uint64 KBytesPageIn;
	public uint64 NbOfPageOut;
	public uint64 KBytesPageOut;
	public uint64 NbOfRotateOut;
	public uint64 KBytesRotateOut;
}

[CRepr]
public struct VIDEO_QUERY_PERFORMANCE_COUNTER
{
	public uint32 BufferSize;
	public VIDEO_PERFORMANCE_COUNTER* Buffer;
}

[CRepr]
public struct PANEL_QUERY_BRIGHTNESS_CAPS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Value;
	}
	public BRIGHTNESS_INTERFACE_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct BRIGHTNESS_LEVEL
{
	public uint8 Count;
	public uint8[103] Level;
}

[CRepr]
public struct BRIGHTNESS_NIT_RANGE
{
	public uint32 MinLevelInMillinit;
	public uint32 MaxLevelInMillinit;
	public uint32 StepSizeInMillinit;
}

[CRepr]
public struct BRIGHTNESS_NIT_RANGES
{
	public uint32 NormalRangeCount;
	public uint32 RangeCount;
	public uint32 PreferredMaximumBrightness;
	public BRIGHTNESS_NIT_RANGE[16] SupportedRanges;
}

[CRepr]
public struct PANEL_QUERY_BRIGHTNESS_RANGES
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public BRIGHTNESS_LEVEL BrightnessLevel;
		public BRIGHTNESS_NIT_RANGES NitRanges;
	}
	public BRIGHTNESS_INTERFACE_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PANEL_GET_BRIGHTNESS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 CurrentInMillinits;
			public uint32 TargetInMillinits;
		}
		public uint8 Level;
		public using _Anonymous_e__Struct Anonymous;
	}
	public BRIGHTNESS_INTERFACE_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CHROMATICITY_COORDINATE
{
	public float x;
	public float y;
}

[CRepr]
public struct PANEL_BRIGHTNESS_SENSOR_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Value;
	}
	public using _Anonymous_e__Union Anonymous;
	public float AlsReading;
	public CHROMATICITY_COORDINATE ChromaticityCoordinate;
	public float ColorTemperature;
}

[CRepr]
public struct PANEL_SET_BRIGHTNESS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 Millinits;
			public uint32 TransitionTimeInMs;
			public PANEL_BRIGHTNESS_SENSOR_DATA SensorData;
		}
		public uint8 Level;
		public using _Anonymous_e__Struct Anonymous;
	}
	public BRIGHTNESS_INTERFACE_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PANEL_SET_BRIGHTNESS_STATE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Value;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PANEL_SET_BACKLIGHT_OPTIMIZATION
{
	public BACKLIGHT_OPTIMIZATION_LEVEL Level;
}

[CRepr]
public struct BACKLIGHT_REDUCTION_GAMMA_RAMP
{
	public uint16[256] R;
	public uint16[256] G;
	public uint16[256] B;
}

[CRepr]
public struct PANEL_GET_BACKLIGHT_REDUCTION
{
	public uint16 BacklightUsersetting;
	public uint16 BacklightEffective;
	public BACKLIGHT_REDUCTION_GAMMA_RAMP GammaRamp;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_DATA_CAP
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 _bitfield;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
		public uint32 Value;
	}
	public COLORSPACE_TRANSFORM_DATA_TYPE DataType;
	public using _Anonymous_e__Union Anonymous;
	public float NumericRangeMin;
	public float NumericRangeMax;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_1DLUT_CAP
{
	public uint32 NumberOfLUTEntries;
	public COLORSPACE_TRANSFORM_DATA_CAP DataCap;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_MATRIX_CAP
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Value;
	}
	public using _Anonymous_e__Union Anonymous;
	public COLORSPACE_TRANSFORM_DATA_CAP DataCap;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_TARGET_CAPS
{
	public COLORSPACE_TRANSFORM_TARGET_CAPS_VERSION Version;
	public COLORSPACE_TRANSFORM_1DLUT_CAP LookupTable1DDegammaCap;
	public COLORSPACE_TRANSFORM_MATRIX_CAP ColorMatrix3x3Cap;
	public COLORSPACE_TRANSFORM_1DLUT_CAP LookupTable1DRegammaCap;
}

[CRepr]
public struct GAMMA_RAMP_RGB256x3x16
{
	public uint16[256] Red;
	public uint16[256] Green;
	public uint16[256] Blue;
}

[CRepr]
public struct GAMMA_RAMP_RGB
{
	public float Red;
	public float Green;
	public float Blue;
}

[CRepr]
public struct GAMMA_RAMP_DXGI_1
{
	public GAMMA_RAMP_RGB Scale;
	public GAMMA_RAMP_RGB Offset;
	public GAMMA_RAMP_RGB[1025] GammaCurve;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_3x4
{
	public float[12] ColorMatrix3x4;
	public float ScalarMultiplier;
	public GAMMA_RAMP_RGB[4096] LookupTable1D;
}

[CRepr]
public struct OUTPUT_WIRE_FORMAT
{
	public OUTPUT_COLOR_ENCODING ColorEncoding;
	public uint32 BitsPerPixel;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_MATRIX_V2
{
	public COLORSPACE_TRANSFORM_STAGE_CONTROL StageControlLookupTable1DDegamma;
	public GAMMA_RAMP_RGB[4096] LookupTable1DDegamma;
	public COLORSPACE_TRANSFORM_STAGE_CONTROL StageControlColorMatrix3x3;
	public float[9] ColorMatrix3x3;
	public COLORSPACE_TRANSFORM_STAGE_CONTROL StageControlLookupTable1DRegamma;
	public GAMMA_RAMP_RGB[4096] LookupTable1DRegamma;
}

[CRepr]
public struct COLORSPACE_TRANSFORM
{
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public GAMMA_RAMP_RGB256x3x16 Rgb256x3x16;
		public GAMMA_RAMP_DXGI_1 Dxgi1;
		public COLORSPACE_TRANSFORM_3x4 T3x4;
		public COLORSPACE_TRANSFORM_MATRIX_V2 MatrixV2;
	}
	public COLORSPACE_TRANSFORM_TYPE Type;
	public _Data_e__Union Data;
}

[CRepr]
public struct COLORSPACE_TRANSFORM_SET_INPUT
{
	public OUTPUT_WIRE_COLOR_SPACE_TYPE OutputWireColorSpaceExpected;
	public OUTPUT_WIRE_FORMAT OutputWireFormatExpected;
	public COLORSPACE_TRANSFORM ColorSpaceTransform;
}

[CRepr]
public struct SET_ACTIVE_COLOR_PROFILE_NAME
{
	public char16* ColorProfileName mut => &ColorProfileName_impl;
	private char16[ANYSIZE_ARRAY] ColorProfileName_impl;
}

[CRepr]
public struct MIPI_DSI_CAPS
{
	public uint8 DSITypeMajor;
	public uint8 DSITypeMinor;
	public uint8 SpecVersionMajor;
	public uint8 SpecVersionMinor;
	public uint8 SpecVersionPatch;
	public uint16 TargetMaximumReturnPacketSize;
	public uint8 ResultCodeFlags;
	public uint8 ResultCodeStatus;
	public uint8 Revision;
	public uint8 Level;
	public uint8 DeviceClassHi;
	public uint8 DeviceClassLo;
	public uint8 ManufacturerHi;
	public uint8 ManufacturerLo;
	public uint8 ProductHi;
	public uint8 ProductLo;
	public uint8 LengthHi;
	public uint8 LengthLo;
}

[CRepr]
public struct MIPI_DSI_PACKET
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 Data0;
			public uint8 Data1;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint16 LongWriteWordCount;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 DataId;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint8 EccFiller;
	public uint8[8] Payload;
}

[CRepr]
public struct MIPI_DSI_TRANSMISSION
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint32 TotalBufferSize;
	public uint8 PacketCount;
	public uint8 FailedPacket;
	public using _Anonymous_e__Struct Anonymous;
	public uint16 ReadWordCount;
	public uint16 FinalCommandExtraPayload;
	public uint16 MipiErrors;
	public uint16 HostErrors;
	public MIPI_DSI_PACKET* Packets mut => &Packets_impl;
	private MIPI_DSI_PACKET[ANYSIZE_ARRAY] Packets_impl;
}

[CRepr]
public struct MIPI_DSI_RESET
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Results;
	}
	public uint32 Flags;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region COM Types
[CRepr]struct ICloneViewHelper : IUnknown
{
	public new const Guid IID = .(0xf6a3d4c4, 0x5632, 0x4d83, 0xb0, 0xa1, 0xfb, 0x88, 0x71, 0x2b, 0x1e, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszAdaptorName, uint32* pulCount, uint32* pulID, uint32 ulFlags) GetConnectedIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszAdaptorName, uint32 ulSourceID, uint32* pulCount, uint32* pulTargetID) GetActiveTopology;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszAdaptorName, uint32 ulSourceID, uint32 ulCount, uint32* pulTargetID) SetActiveTopology;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFinalCall) Commit;
	}


	public HRESULT GetConnectedIDs(PWSTR wszAdaptorName, uint32* pulCount, uint32* pulID, uint32 ulFlags) mut => VT.[Friend]GetConnectedIDs(&this, wszAdaptorName, pulCount, pulID, ulFlags);

	public HRESULT GetActiveTopology(PWSTR wszAdaptorName, uint32 ulSourceID, uint32* pulCount, uint32* pulTargetID) mut => VT.[Friend]GetActiveTopology(&this, wszAdaptorName, ulSourceID, pulCount, pulTargetID);

	public HRESULT SetActiveTopology(PWSTR wszAdaptorName, uint32 ulSourceID, uint32 ulCount, uint32* pulTargetID) mut => VT.[Friend]SetActiveTopology(&this, wszAdaptorName, ulSourceID, ulCount, pulTargetID);

	public HRESULT Commit(BOOL fFinalCall) mut => VT.[Friend]Commit(&this, fFinalCall);
}

[CRepr]struct IViewHelper : IUnknown
{
	public new const Guid IID = .(0xe85ccef5, 0xaaaa, 0x47f0, 0xb5, 0xe3, 0x61, 0xf7, 0xae, 0xcd, 0xc4, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszAdaptorName, uint32* pulCount, uint32* pulID, uint32 ulFlags) GetConnectedIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszAdaptorName, uint32 ulSourceID, uint32* pulCount, uint32* pulTargetID) GetActiveTopology;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszAdaptorName, uint32 ulSourceID, uint32 ulCount, uint32* pulTargetID) SetActiveTopology;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, uint32* pulStatus) SetConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetProceedOnNewConfiguration;
	}


	public HRESULT GetConnectedIDs(PWSTR wszAdaptorName, uint32* pulCount, uint32* pulID, uint32 ulFlags) mut => VT.[Friend]GetConnectedIDs(&this, wszAdaptorName, pulCount, pulID, ulFlags);

	public HRESULT GetActiveTopology(PWSTR wszAdaptorName, uint32 ulSourceID, uint32* pulCount, uint32* pulTargetID) mut => VT.[Friend]GetActiveTopology(&this, wszAdaptorName, ulSourceID, pulCount, pulTargetID);

	public HRESULT SetActiveTopology(PWSTR wszAdaptorName, uint32 ulSourceID, uint32 ulCount, uint32* pulTargetID) mut => VT.[Friend]SetActiveTopology(&this, wszAdaptorName, ulSourceID, ulCount, pulTargetID);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT SetConfiguration(IStream* pIStream, uint32* pulStatus) mut => VT.[Friend]SetConfiguration(&this, pIStream, pulStatus);

	public HRESULT GetProceedOnNewConfiguration() mut => VT.[Friend]GetProceedOnNewConfiguration(&this);
}

#endregion

#region Functions
public static
{
	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNumberOfPhysicalMonitorsFromHMONITOR(HMONITOR hMonitor, uint32* pdwNumberOfPhysicalMonitors);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetNumberOfPhysicalMonitorsFromIDirect3DDevice9(IDirect3DDevice9* pDirect3DDevice9, uint32* pdwNumberOfPhysicalMonitors);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetPhysicalMonitorsFromHMONITOR(HMONITOR hMonitor, uint32 dwPhysicalMonitorArraySize, PHYSICAL_MONITOR* pPhysicalMonitorArray);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetPhysicalMonitorsFromIDirect3DDevice9(IDirect3DDevice9* pDirect3DDevice9, uint32 dwPhysicalMonitorArraySize, PHYSICAL_MONITOR* pPhysicalMonitorArray);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DestroyPhysicalMonitor(HANDLE hMonitor);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DestroyPhysicalMonitors(uint32 dwPhysicalMonitorArraySize, PHYSICAL_MONITOR* pPhysicalMonitorArray);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetVCPFeatureAndVCPFeatureReply(HANDLE hMonitor, uint8 bVCPCode, MC_VCP_CODE_TYPE* pvct, uint32* pdwCurrentValue, uint32* pdwMaximumValue);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetVCPFeature(HANDLE hMonitor, uint8 bVCPCode, uint32 dwNewValue);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SaveCurrentSettings(HANDLE hMonitor);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCapabilitiesStringLength(HANDLE hMonitor, uint32* pdwCapabilitiesStringLengthInCharacters);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CapabilitiesRequestAndCapabilitiesReply(HANDLE hMonitor, uint8* pszASCIICapabilitiesString, uint32 dwCapabilitiesStringLengthInCharacters);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTimingReport(HANDLE hMonitor, MC_TIMING_REPORT* pmtrMonitorTimingReport);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorCapabilities(HANDLE hMonitor, uint32* pdwMonitorCapabilities, uint32* pdwSupportedColorTemperatures);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SaveCurrentMonitorSettings(HANDLE hMonitor);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorTechnologyType(HANDLE hMonitor, MC_DISPLAY_TECHNOLOGY_TYPE* pdtyDisplayTechnologyType);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorBrightness(HANDLE hMonitor, uint32* pdwMinimumBrightness, uint32* pdwCurrentBrightness, uint32* pdwMaximumBrightness);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorContrast(HANDLE hMonitor, uint32* pdwMinimumContrast, uint32* pdwCurrentContrast, uint32* pdwMaximumContrast);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorColorTemperature(HANDLE hMonitor, MC_COLOR_TEMPERATURE* pctCurrentColorTemperature);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorRedGreenOrBlueDrive(HANDLE hMonitor, MC_DRIVE_TYPE dtDriveType, uint32* pdwMinimumDrive, uint32* pdwCurrentDrive, uint32* pdwMaximumDrive);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorRedGreenOrBlueGain(HANDLE hMonitor, MC_GAIN_TYPE gtGainType, uint32* pdwMinimumGain, uint32* pdwCurrentGain, uint32* pdwMaximumGain);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorBrightness(HANDLE hMonitor, uint32 dwNewBrightness);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorContrast(HANDLE hMonitor, uint32 dwNewContrast);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorColorTemperature(HANDLE hMonitor, MC_COLOR_TEMPERATURE ctCurrentColorTemperature);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorRedGreenOrBlueDrive(HANDLE hMonitor, MC_DRIVE_TYPE dtDriveType, uint32 dwNewDrive);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorRedGreenOrBlueGain(HANDLE hMonitor, MC_GAIN_TYPE gtGainType, uint32 dwNewGain);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DegaussMonitor(HANDLE hMonitor);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorDisplayAreaSize(HANDLE hMonitor, MC_SIZE_TYPE stSizeType, uint32* pdwMinimumWidthOrHeight, uint32* pdwCurrentWidthOrHeight, uint32* pdwMaximumWidthOrHeight);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMonitorDisplayAreaPosition(HANDLE hMonitor, MC_POSITION_TYPE ptPositionType, uint32* pdwMinimumPosition, uint32* pdwCurrentPosition, uint32* pdwMaximumPosition);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorDisplayAreaSize(HANDLE hMonitor, MC_SIZE_TYPE stSizeType, uint32 dwNewDisplayAreaWidthOrHeight);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMonitorDisplayAreaPosition(HANDLE hMonitor, MC_POSITION_TYPE ptPositionType, uint32 dwNewPosition);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RestoreMonitorFactoryColorDefaults(HANDLE hMonitor);

	[Import("dxva2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RestoreMonitorFactoryDefaults(HANDLE hMonitor);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* BRUSHOBJ_pvAllocRbrush(BRUSHOBJ* pbo, uint32 cj);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* BRUSHOBJ_pvGetRbrush(BRUSHOBJ* pbo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BRUSHOBJ_ulGetBrushColor(BRUSHOBJ* pbo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE BRUSHOBJ_hGetColorTransform(BRUSHOBJ* pbo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CLIPOBJ_cEnumStart(CLIPOBJ* pco, BOOL bAll, uint32 iType, uint32 iDirection, uint32 cLimit);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CLIPOBJ_bEnum(CLIPOBJ* pco, uint32 cj, uint32* pul);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PATHOBJ* CLIPOBJ_ppoGetPath(CLIPOBJ* pco);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FONTOBJ_cGetAllGlyphHandles(FONTOBJ* pfo, uint32* phg);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FONTOBJ_vGetInfo(FONTOBJ* pfo, uint32 cjSize, FONTINFO* pfi);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FONTOBJ_cGetGlyphs(FONTOBJ* pfo, uint32 iMode, uint32 cGlyph, uint32* phg, void** ppvGlyph);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern XFORMOBJ* FONTOBJ_pxoGetXform(FONTOBJ* pfo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IFIMETRICS* FONTOBJ_pifi(FONTOBJ* pfo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FD_GLYPHSET* FONTOBJ_pfdg(FONTOBJ* pfo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* FONTOBJ_pvTrueTypeFontFile(FONTOBJ* pfo, uint32* pcjFile);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FD_GLYPHATTR* FONTOBJ_pQueryGlyphAttrs(FONTOBJ* pfo, uint32 iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PATHOBJ_vEnumStart(PATHOBJ* ppo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PATHOBJ_bEnum(PATHOBJ* ppo, PATHDATA* ppd);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PATHOBJ_vEnumStartClipLines(PATHOBJ* ppo, CLIPOBJ* pco, SURFOBJ* pso, LINEATTRS* pla);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PATHOBJ_bEnumClipLines(PATHOBJ* ppo, uint32 cb, CLIPLINE* pcl);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PATHOBJ_vGetBounds(PATHOBJ* ppo, RECTFX* prectfx);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void STROBJ_vEnumStart(STROBJ* pstro);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL STROBJ_bEnum(STROBJ* pstro, uint32* pc, GLYPHPOS** ppgpos);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL STROBJ_bEnumPositionsOnly(STROBJ* pstro, uint32* pc, GLYPHPOS** ppgpos);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 STROBJ_dwGetCodePage(STROBJ* pstro);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL STROBJ_bGetAdvanceWidths(STROBJ* pso, uint32 iFirst, uint32 c, POINTQF* pptqD);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XFORMOBJ_iGetXform(XFORMOBJ* pxo, XFORML* pxform);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL XFORMOBJ_bApplyXform(XFORMOBJ* pxo, uint32 iMode, uint32 cPoints, void* pvIn, void* pvOut);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XLATEOBJ_iXlate(XLATEOBJ* pxlo, uint32 iColor);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32* XLATEOBJ_piVector(XLATEOBJ* pxlo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XLATEOBJ_cGetPalette(XLATEOBJ* pxlo, uint32 iPal, uint32 cPal, uint32* pPal);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE XLATEOBJ_hGetColorTransform(XLATEOBJ* pxlo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP EngCreateBitmap(SIZE sizl, int32 lWidth, uint32 iFormat, uint32 fl, void* pvBits);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HSURF EngCreateDeviceSurface(DHSURF dhsurf, SIZE sizl, uint32 iFormatCompat);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP EngCreateDeviceBitmap(DHSURF dhsurf, SIZE sizl, uint32 iFormatCompat);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngDeleteSurface(HSURF hsurf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SURFOBJ* EngLockSurface(HSURF hsurf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngUnlockSurface(SURFOBJ* pso);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngEraseSurface(SURFOBJ* pso, RECTL* prcl, uint32 iColor);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngAssociateSurface(HSURF hsurf, HDEV hdev, uint32 flHooks);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngMarkBandingSurface(HSURF hsurf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngCheckAbort(SURFOBJ* pso);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngDeletePath(PATHOBJ* ppo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPALETTE EngCreatePalette(uint32 iMode, uint32 cColors, uint32* pulColors, uint32 flRed, uint32 flGreen, uint32 flBlue);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngDeletePalette(HPALETTE hpal);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIPOBJ* EngCreateClip();

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngDeleteClip(CLIPOBJ* pco);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngBitBlt(SURFOBJ* psoTrg, SURFOBJ* psoSrc, SURFOBJ* psoMask, CLIPOBJ* pco, XLATEOBJ* pxlo, RECTL* prclTrg, POINTL* pptlSrc, POINTL* pptlMask, BRUSHOBJ* pbo, POINTL* pptlBrush, uint32 rop4);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngLineTo(SURFOBJ* pso, CLIPOBJ* pco, BRUSHOBJ* pbo, int32 x1, int32 y1, int32 x2, int32 y2, RECTL* prclBounds, uint32 mix);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngStretchBlt(SURFOBJ* psoDest, SURFOBJ* psoSrc, SURFOBJ* psoMask, CLIPOBJ* pco, XLATEOBJ* pxlo, COLORADJUSTMENT* pca, POINTL* pptlHTOrg, RECTL* prclDest, RECTL* prclSrc, POINTL* pptlMask, uint32 iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngStretchBltROP(SURFOBJ* psoDest, SURFOBJ* psoSrc, SURFOBJ* psoMask, CLIPOBJ* pco, XLATEOBJ* pxlo, COLORADJUSTMENT* pca, POINTL* pptlHTOrg, RECTL* prclDest, RECTL* prclSrc, POINTL* pptlMask, uint32 iMode, BRUSHOBJ* pbo, uint32 rop4);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngAlphaBlend(SURFOBJ* psoDest, SURFOBJ* psoSrc, CLIPOBJ* pco, XLATEOBJ* pxlo, RECTL* prclDest, RECTL* prclSrc, BLENDOBJ* pBlendObj);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngGradientFill(SURFOBJ* psoDest, CLIPOBJ* pco, XLATEOBJ* pxlo, TRIVERTEX* pVertex, uint32 nVertex, void* pMesh, uint32 nMesh, RECTL* prclExtents, POINTL* pptlDitherOrg, uint32 ulMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngTransparentBlt(SURFOBJ* psoDst, SURFOBJ* psoSrc, CLIPOBJ* pco, XLATEOBJ* pxlo, RECTL* prclDst, RECTL* prclSrc, uint32 TransColor, uint32 bCalledFromBitBlt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngTextOut(SURFOBJ* pso, STROBJ* pstro, FONTOBJ* pfo, CLIPOBJ* pco, RECTL* prclExtra, RECTL* prclOpaque, BRUSHOBJ* pboFore, BRUSHOBJ* pboOpaque, POINTL* pptlOrg, uint32 mix);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngStrokePath(SURFOBJ* pso, PATHOBJ* ppo, CLIPOBJ* pco, XFORMOBJ* pxo, BRUSHOBJ* pbo, POINTL* pptlBrushOrg, LINEATTRS* plineattrs, uint32 mix);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngFillPath(SURFOBJ* pso, PATHOBJ* ppo, CLIPOBJ* pco, BRUSHOBJ* pbo, POINTL* pptlBrushOrg, uint32 mix, uint32 flOptions);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngStrokeAndFillPath(SURFOBJ* pso, PATHOBJ* ppo, CLIPOBJ* pco, XFORMOBJ* pxo, BRUSHOBJ* pboStroke, LINEATTRS* plineattrs, BRUSHOBJ* pboFill, POINTL* pptlBrushOrg, uint32 mixFill, uint32 flOptions);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngPaint(SURFOBJ* pso, CLIPOBJ* pco, BRUSHOBJ* pbo, POINTL* pptlBrushOrg, uint32 mix);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngCopyBits(SURFOBJ* psoDest, SURFOBJ* psoSrc, CLIPOBJ* pco, XLATEOBJ* pxlo, RECTL* prclDest, POINTL* pptlSrc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngPlgBlt(SURFOBJ* psoTrg, SURFOBJ* psoSrc, SURFOBJ* psoMsk, CLIPOBJ* pco, XLATEOBJ* pxlo, COLORADJUSTMENT* pca, POINTL* pptlBrushOrg, POINTFIX* pptfx, RECTL* prcl, POINTL* pptl, uint32 iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 HT_Get8BPPFormatPalette(PALETTEENTRY* pPaletteEntry, uint16 RedGamma, uint16 GreenGamma, uint16 BlueGamma);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 HT_Get8BPPMaskPalette(PALETTEENTRY* pPaletteEntry, BOOL Use8BPPMaskPal, uint8 CMYMask, uint16 RedGamma, uint16 GreenGamma, uint16 BlueGamma);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR EngGetPrinterDataFileName(HDEV hdev);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR EngGetDriverName(HDEV hdev);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE EngLoadModule(PWSTR pwsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* EngFindResource(HANDLE h, int32 iName, int32 iType, uint32* pulSize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngFreeModule(HANDLE h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HSEMAPHORE EngCreateSemaphore();

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngAcquireSemaphore(HSEMAPHORE hsem);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngReleaseSemaphore(HSEMAPHORE hsem);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngDeleteSemaphore(HSEMAPHORE hsem);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngMultiByteToUnicodeN(PWSTR UnicodeString, uint32 MaxBytesInUnicodeString, uint32* BytesInUnicodeString, PSTR MultiByteString, uint32 BytesInMultiByteString);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngUnicodeToMultiByteN(PSTR MultiByteString, uint32 MaxBytesInMultiByteString, uint32* BytesInMultiByteString, PWSTR UnicodeString, uint32 BytesInUnicodeString);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngQueryLocalTime(ENG_TIME_FIELDS* param0);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FD_GLYPHSET* EngComputeGlyphSet(int32 nCodePage, int32 nFirstChar, int32 cChars);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EngMultiByteToWideChar(uint32 CodePage, PWSTR WideCharString, int32 BytesInWideCharString, PSTR MultiByteString, int32 BytesInMultiByteString);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EngWideCharToMultiByte(uint32 CodePage, PWSTR WideCharString, int32 BytesInWideCharString, PSTR MultiByteString, int32 BytesInMultiByteString);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EngGetCurrentCodePage(uint16* OemCodePage, uint16* AnsiCodePage);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EngQueryEMFInfo(HDEV hdev, EMFINFO* pEMFInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDisplayConfigBufferSizes(uint32 flags, uint32* numPathArrayElements, uint32* numModeInfoArrayElements);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetDisplayConfig(uint32 numPathArrayElements, DISPLAYCONFIG_PATH_INFO* pathArray, uint32 numModeInfoArrayElements, DISPLAYCONFIG_MODE_INFO* modeInfoArray, uint32 flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 QueryDisplayConfig(uint32 flags, uint32* numPathArrayElements, DISPLAYCONFIG_PATH_INFO* pathArray, uint32* numModeInfoArrayElements, DISPLAYCONFIG_MODE_INFO* modeInfoArray, DISPLAYCONFIG_TOPOLOGY_ID* currentTopologyId);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DisplayConfigGetDeviceInfo(DISPLAYCONFIG_DEVICE_INFO_HEADER* requestPacket);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DisplayConfigSetDeviceInfo(DISPLAYCONFIG_DEVICE_INFO_HEADER* setPacket);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAutoRotationState(AR_STATE* pState);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDisplayAutoRotationPreferences(ORIENTATION_PREFERENCE* pOrientation);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDisplayAutoRotationPreferences(ORIENTATION_PREFERENCE orientation);

}
#endregion
