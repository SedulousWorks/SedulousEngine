using Win32.Foundation;
using Win32.Devices.Properties;
using Win32.System.Com;
using Win32.System.Registry;
using System;

namespace Win32.Devices.HumanInterfaceDevice;

#region Constants
public static
{
	public const uint32 DIRECTINPUT_VERSION = 2048;
	public const uint32 JOY_HW_NONE = 0;
	public const uint32 JOY_HW_CUSTOM = 1;
	public const uint32 JOY_HW_2A_2B_GENERIC = 2;
	public const uint32 JOY_HW_2A_4B_GENERIC = 3;
	public const uint32 JOY_HW_2B_GAMEPAD = 4;
	public const uint32 JOY_HW_2B_FLIGHTYOKE = 5;
	public const uint32 JOY_HW_2B_FLIGHTYOKETHROTTLE = 6;
	public const uint32 JOY_HW_3A_2B_GENERIC = 7;
	public const uint32 JOY_HW_3A_4B_GENERIC = 8;
	public const uint32 JOY_HW_4B_GAMEPAD = 9;
	public const uint32 JOY_HW_4B_FLIGHTYOKE = 10;
	public const uint32 JOY_HW_4B_FLIGHTYOKETHROTTLE = 11;
	public const uint32 JOY_HW_TWO_2A_2B_WITH_Y = 12;
	public const uint32 JOY_HW_LASTENTRY = 13;
	public const int32 JOY_ISCAL_XY = 1;
	public const int32 JOY_ISCAL_Z = 2;
	public const int32 JOY_ISCAL_R = 4;
	public const int32 JOY_ISCAL_U = 8;
	public const int32 JOY_ISCAL_V = 16;
	public const int32 JOY_ISCAL_POV = 32;
	public const uint32 JOY_POV_NUMDIRS = 4;
	public const uint32 JOY_POVVAL_FORWARD = 0;
	public const uint32 JOY_POVVAL_BACKWARD = 1;
	public const uint32 JOY_POVVAL_LEFT = 2;
	public const uint32 JOY_POVVAL_RIGHT = 3;
	public const int32 JOY_HWS_HASZ = 1;
	public const int32 JOY_HWS_HASPOV = 2;
	public const int32 JOY_HWS_POVISBUTTONCOMBOS = 4;
	public const int32 JOY_HWS_POVISPOLL = 8;
	public const int32 JOY_HWS_ISYOKE = 16;
	public const int32 JOY_HWS_ISGAMEPAD = 32;
	public const int32 JOY_HWS_ISCARCTRL = 64;
	public const int32 JOY_HWS_XISJ1Y = 128;
	public const int32 JOY_HWS_XISJ2X = 256;
	public const int32 JOY_HWS_XISJ2Y = 512;
	public const int32 JOY_HWS_YISJ1X = 1024;
	public const int32 JOY_HWS_YISJ2X = 2048;
	public const int32 JOY_HWS_YISJ2Y = 4096;
	public const int32 JOY_HWS_ZISJ1X = 8192;
	public const int32 JOY_HWS_ZISJ1Y = 16384;
	public const int32 JOY_HWS_ZISJ2X = 32768;
	public const int32 JOY_HWS_POVISJ1X = 65536;
	public const int32 JOY_HWS_POVISJ1Y = 131072;
	public const int32 JOY_HWS_POVISJ2X = 262144;
	public const int32 JOY_HWS_HASR = 524288;
	public const int32 JOY_HWS_RISJ1X = 1048576;
	public const int32 JOY_HWS_RISJ1Y = 2097152;
	public const int32 JOY_HWS_RISJ2Y = 4194304;
	public const int32 JOY_HWS_HASU = 8388608;
	public const int32 JOY_HWS_HASV = 16777216;
	public const int32 JOY_US_HASRUDDER = 1;
	public const int32 JOY_US_PRESENT = 2;
	public const int32 JOY_US_ISOEM = 4;
	public const int32 JOY_US_RESERVED = -2147483648;
	public const int32 JOYTYPE_ZEROGAMEENUMOEMDATA = 1;
	public const int32 JOYTYPE_NOAUTODETECTGAMEPORT = 2;
	public const int32 JOYTYPE_NOHIDDIRECT = 4;
	public const int32 JOYTYPE_ANALOGCOMPAT = 8;
	public const int32 JOYTYPE_DEFAULTPROPSHEET = -2147483648;
	public const int32 JOYTYPE_DEVICEHIDE = 65536;
	public const int32 JOYTYPE_MOUSEHIDE = 131072;
	public const int32 JOYTYPE_KEYBHIDE = 262144;
	public const int32 JOYTYPE_GAMEHIDE = 524288;
	public const int32 JOYTYPE_HIDEACTIVE = 1048576;
	public const int32 JOYTYPE_INFOMASK = 14680064;
	public const int32 JOYTYPE_INFODEFAULT = 0;
	public const int32 JOYTYPE_INFOYYPEDALS = 2097152;
	public const int32 JOYTYPE_INFOZYPEDALS = 4194304;
	public const int32 JOYTYPE_INFOYRPEDALS = 6291456;
	public const int32 JOYTYPE_INFOZRPEDALS = 8388608;
	public const int32 JOYTYPE_INFOZISSLIDER = 2097152;
	public const int32 JOYTYPE_INFOZISZ = 4194304;
	public const int32 JOYTYPE_ENABLEINPUTREPORT = 16777216;
	public const uint32 MAX_JOYSTRING = 256;
	public const uint32 MAX_JOYSTICKOEMVXDNAME = 260;
	public const uint32 DITC_REGHWSETTINGS = 1;
	public const uint32 DITC_CLSIDCONFIG = 2;
	public const uint32 DITC_DISPLAYNAME = 4;
	public const uint32 DITC_CALLOUT = 8;
	public const uint32 DITC_HARDWAREID = 16;
	public const uint32 DITC_FLAGS1 = 32;
	public const uint32 DITC_FLAGS2 = 64;
	public const uint32 DITC_MAPFILE = 128;
	public const uint32 DIJC_GUIDINSTANCE = 1;
	public const uint32 DIJC_REGHWCONFIGTYPE = 2;
	public const uint32 DIJC_GAIN = 4;
	public const uint32 DIJC_CALLOUT = 8;
	public const uint32 DIJC_WDMGAMEPORT = 16;
	public const uint32 DIJU_USERVALUES = 1;
	public const uint32 DIJU_GLOBALDRIVER = 2;
	public const uint32 DIJU_GAMEPORTEMULATOR = 4;
	public const Guid GUID_KeyboardClass = .(0x4d36e96b, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_MediaClass = .(0x4d36e96c, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_MouseClass = .(0x4d36e96f, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_HIDClass = .(0x745a17a0, 0x74d3, 0x11d0, 0xb6, 0xfe, 0x00, 0xa0, 0xc9, 0x0f, 0x57, 0xda);
	public const String DIRECTINPUT_NOTIFICATION_MSGSTRINGA = "DIRECTINPUT_NOTIFICATION_MSGSTRING";
	public const String DIRECTINPUT_NOTIFICATION_MSGSTRINGW = "DIRECTINPUT_NOTIFICATION_MSGSTRING";
	public const String DIRECTINPUT_NOTIFICATION_MSGSTRING = "DIRECTINPUT_NOTIFICATION_MSGSTRING";
	public const uint32 DIMSGWP_NEWAPPSTART = 1;
	public const uint32 DIMSGWP_DX8APPSTART = 2;
	public const uint32 DIMSGWP_DX8MAPPERAPPSTART = 3;
	public const uint32 DIAPPIDFLAG_NOTIME = 1;
	public const uint32 DIAPPIDFLAG_NOSIZE = 2;
	public const String DIRECTINPUT_REGSTR_VAL_APPIDFLAGA = "AppIdFlag";
	public const String DIRECTINPUT_REGSTR_KEY_LASTAPPA = "MostRecentApplication";
	public const String DIRECTINPUT_REGSTR_KEY_LASTMAPAPPA = "MostRecentMapperApplication";
	public const String DIRECTINPUT_REGSTR_VAL_VERSIONA = "Version";
	public const String DIRECTINPUT_REGSTR_VAL_NAMEA = "Name";
	public const String DIRECTINPUT_REGSTR_VAL_IDA = "Id";
	public const String DIRECTINPUT_REGSTR_VAL_MAPPERA = "UsesMapper";
	public const String DIRECTINPUT_REGSTR_VAL_LASTSTARTA = "MostRecentStart";
	public const String DIRECTINPUT_REGSTR_VAL_APPIDFLAGW = "AppIdFlag";
	public const String DIRECTINPUT_REGSTR_KEY_LASTAPPW = "MostRecentApplication";
	public const String DIRECTINPUT_REGSTR_KEY_LASTMAPAPPW = "MostRecentMapperApplication";
	public const String DIRECTINPUT_REGSTR_VAL_VERSIONW = "Version";
	public const String DIRECTINPUT_REGSTR_VAL_NAMEW = "Name";
	public const String DIRECTINPUT_REGSTR_VAL_IDW = "Id";
	public const String DIRECTINPUT_REGSTR_VAL_MAPPERW = "UsesMapper";
	public const String DIRECTINPUT_REGSTR_VAL_LASTSTARTW = "MostRecentStart";
	public const String DIRECTINPUT_REGSTR_VAL_APPIDFLAG = "AppIdFlag";
	public const String DIRECTINPUT_REGSTR_KEY_LASTAPP = "MostRecentApplication";
	public const String DIRECTINPUT_REGSTR_KEY_LASTMAPAPP = "MostRecentMapperApplication";
	public const String DIRECTINPUT_REGSTR_VAL_VERSION = "Version";
	public const String DIRECTINPUT_REGSTR_VAL_NAME = "Name";
	public const String DIRECTINPUT_REGSTR_VAL_ID = "Id";
	public const String DIRECTINPUT_REGSTR_VAL_MAPPER = "UsesMapper";
	public const String DIRECTINPUT_REGSTR_VAL_LASTSTART = "MostRecentStart";
	public const HRESULT DIERR_NOMOREITEMS = -2147024637;
	public const int32 DIERR_DRIVERFIRST = -2147220736;
	public const int32 DIERR_DRIVERLAST = -2147220481;
	public const int32 DIERR_INVALIDCLASSINSTALLER = -2147220480;
	public const int32 DIERR_CANCELLED = -2147220479;
	public const int32 DIERR_BADINF = -2147220478;
	public const uint32 DIDIFT_DELETE = 16777216;
	public const Guid GUID_DEVINTERFACE_HID = .(0x4d1e55b2, 0xf16f, 0x11cf, 0x88, 0xcb, 0x00, 0x11, 0x11, 0x00, 0x00, 0x30);
	public const Guid GUID_HID_INTERFACE_NOTIFY = .(0x2c4e2e88, 0x25e6, 0x4c33, 0x88, 0x2f, 0x3d, 0x82, 0xe6, 0x07, 0x36, 0x81);
	public const Guid GUID_HID_INTERFACE_HIDPARSE = .(0xf5c315a5, 0x69ac, 0x4bc2, 0x92, 0x79, 0xd0, 0xb6, 0x45, 0x76, 0xf4, 0x4b);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_UsagePage = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 2);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_UsageId = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 3);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_IsReadOnly = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 4);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_VendorId = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 5);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_ProductId = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 6);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_VersionNumber = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 7);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_BackgroundAccess = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 8);
	public const DEVPROPKEY DEVPKEY_DeviceInterface_HID_WakeScreenOnInputCapable = .(.(0xcbf38310, 0x4a17, 0x4310, 0xa1, 0xeb, 0x24, 0x7f, 0x0b, 0x67, 0x59, 0x3b), 9);
	public const uint32 HID_REVISION = 1;
	public const uint16 HID_USAGE_PAGE_UNDEFINED = 0;
	public const uint16 HID_USAGE_PAGE_GENERIC = 1;
	public const uint16 HID_USAGE_PAGE_SIMULATION = 2;
	public const uint16 HID_USAGE_PAGE_VR = 3;
	public const uint16 HID_USAGE_PAGE_SPORT = 4;
	public const uint16 HID_USAGE_PAGE_GAME = 5;
	public const uint16 HID_USAGE_PAGE_GENERIC_DEVICE = 6;
	public const uint16 HID_USAGE_PAGE_KEYBOARD = 7;
	public const uint16 HID_USAGE_PAGE_LED = 8;
	public const uint16 HID_USAGE_PAGE_BUTTON = 9;
	public const uint16 HID_USAGE_PAGE_ORDINAL = 10;
	public const uint16 HID_USAGE_PAGE_TELEPHONY = 11;
	public const uint16 HID_USAGE_PAGE_CONSUMER = 12;
	public const uint16 HID_USAGE_PAGE_DIGITIZER = 13;
	public const uint16 HID_USAGE_PAGE_HAPTICS = 14;
	public const uint16 HID_USAGE_PAGE_PID = 15;
	public const uint16 HID_USAGE_PAGE_UNICODE = 16;
	public const uint16 HID_USAGE_PAGE_ALPHANUMERIC = 20;
	public const uint16 HID_USAGE_PAGE_SENSOR = 32;
	public const uint16 HID_USAGE_PAGE_LIGHTING_ILLUMINATION = 89;
	public const uint16 HID_USAGE_PAGE_BARCODE_SCANNER = 140;
	public const uint16 HID_USAGE_PAGE_WEIGHING_DEVICE = 141;
	public const uint16 HID_USAGE_PAGE_MAGNETIC_STRIPE_READER = 142;
	public const uint16 HID_USAGE_PAGE_CAMERA_CONTROL = 144;
	public const uint16 HID_USAGE_PAGE_ARCADE = 145;
	public const uint16 HID_USAGE_PAGE_MICROSOFT_BLUETOOTH_HANDSFREE = 65523;
	public const uint16 HID_USAGE_PAGE_VENDOR_DEFINED_BEGIN = 65280;
	public const uint16 HID_USAGE_PAGE_VENDOR_DEFINED_END = 65535;
	public const uint16 HID_USAGE_GENERIC_POINTER = 1;
	public const uint16 HID_USAGE_GENERIC_MOUSE = 2;
	public const uint16 HID_USAGE_GENERIC_JOYSTICK = 4;
	public const uint16 HID_USAGE_GENERIC_GAMEPAD = 5;
	public const uint16 HID_USAGE_GENERIC_KEYBOARD = 6;
	public const uint16 HID_USAGE_GENERIC_KEYPAD = 7;
	public const uint16 HID_USAGE_GENERIC_MULTI_AXIS_CONTROLLER = 8;
	public const uint16 HID_USAGE_GENERIC_TABLET_PC_SYSTEM_CTL = 9;
	public const uint16 HID_USAGE_GENERIC_PORTABLE_DEVICE_CONTROL = 13;
	public const uint16 HID_USAGE_GENERIC_INTERACTIVE_CONTROL = 14;
	public const uint16 HID_USAGE_GENERIC_COUNTED_BUFFER = 58;
	public const uint16 HID_USAGE_GENERIC_SYSTEM_CTL = 128;
	public const uint16 HID_USAGE_GENERIC_X = 48;
	public const uint16 HID_USAGE_GENERIC_Y = 49;
	public const uint16 HID_USAGE_GENERIC_Z = 50;
	public const uint16 HID_USAGE_GENERIC_RX = 51;
	public const uint16 HID_USAGE_GENERIC_RY = 52;
	public const uint16 HID_USAGE_GENERIC_RZ = 53;
	public const uint16 HID_USAGE_GENERIC_SLIDER = 54;
	public const uint16 HID_USAGE_GENERIC_DIAL = 55;
	public const uint16 HID_USAGE_GENERIC_WHEEL = 56;
	public const uint16 HID_USAGE_GENERIC_HATSWITCH = 57;
	public const uint16 HID_USAGE_GENERIC_BYTE_COUNT = 59;
	public const uint16 HID_USAGE_GENERIC_MOTION_WAKEUP = 60;
	public const uint16 HID_USAGE_GENERIC_START = 61;
	public const uint16 HID_USAGE_GENERIC_SELECT = 62;
	public const uint16 HID_USAGE_GENERIC_VX = 64;
	public const uint16 HID_USAGE_GENERIC_VY = 65;
	public const uint16 HID_USAGE_GENERIC_VZ = 66;
	public const uint16 HID_USAGE_GENERIC_VBRX = 67;
	public const uint16 HID_USAGE_GENERIC_VBRY = 68;
	public const uint16 HID_USAGE_GENERIC_VBRZ = 69;
	public const uint16 HID_USAGE_GENERIC_VNO = 70;
	public const uint16 HID_USAGE_GENERIC_FEATURE_NOTIFICATION = 71;
	public const uint16 HID_USAGE_GENERIC_RESOLUTION_MULTIPLIER = 72;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_POWER = 129;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_SLEEP = 130;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_WAKE = 131;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_CONTEXT_MENU = 132;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MAIN_MENU = 133;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_APP_MENU = 134;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_HELP_MENU = 135;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MENU_EXIT = 136;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MENU_SELECT = 137;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MENU_RIGHT = 138;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MENU_LEFT = 139;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MENU_UP = 140;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MENU_DOWN = 141;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_COLD_RESTART = 142;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_WARM_RESTART = 143;
	public const uint16 HID_USAGE_GENERIC_DPAD_UP = 144;
	public const uint16 HID_USAGE_GENERIC_DPAD_DOWN = 145;
	public const uint16 HID_USAGE_GENERIC_DPAD_RIGHT = 146;
	public const uint16 HID_USAGE_GENERIC_DPAD_LEFT = 147;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_FN = 151;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_FN_LOCK = 152;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_FN_LOCK_INDICATOR = 153;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISMISS_NOTIFICATION = 154;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DOCK = 160;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_UNDOCK = 161;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_SETUP = 162;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_SYS_BREAK = 163;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_SYS_DBG_BREAK = 164;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_APP_BREAK = 165;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_APP_DBG_BREAK = 166;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_MUTE = 167;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_HIBERNATE = 168;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_INVERT = 176;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_INTERNAL = 177;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_EXTERNAL = 178;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_BOTH = 179;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_DUAL = 180;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_TOGGLE = 181;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_SWAP = 182;
	public const uint16 HID_USAGE_GENERIC_SYSCTL_DISP_AUTOSCALE = 183;
	public const uint16 HID_USAGE_GENERIC_SYSTEM_DISPLAY_ROTATION_LOCK_BUTTON = 201;
	public const uint16 HID_USAGE_GENERIC_SYSTEM_DISPLAY_ROTATION_LOCK_SLIDER_SWITCH = 202;
	public const uint16 HID_USAGE_GENERIC_CONTROL_ENABLE = 203;
	public const uint16 HID_USAGE_SIMULATION_FLIGHT_SIMULATION_DEVICE = 1;
	public const uint16 HID_USAGE_SIMULATION_AUTOMOBILE_SIMULATION_DEVICE = 2;
	public const uint16 HID_USAGE_SIMULATION_TANK_SIMULATION_DEVICE = 3;
	public const uint16 HID_USAGE_SIMULATION_SPACESHIP_SIMULATION_DEVICE = 4;
	public const uint16 HID_USAGE_SIMULATION_SUBMARINE_SIMULATION_DEVICE = 5;
	public const uint16 HID_USAGE_SIMULATION_SAILING_SIMULATION_DEVICE = 6;
	public const uint16 HID_USAGE_SIMULATION_MOTORCYCLE_SIMULATION_DEVICE = 7;
	public const uint16 HID_USAGE_SIMULATION_SPORTS_SIMULATION_DEVICE = 8;
	public const uint16 HID_USAGE_SIMULATION_AIRPLANE_SIMULATION_DEVICE = 9;
	public const uint16 HID_USAGE_SIMULATION_HELICOPTER_SIMULATION_DEVICE = 10;
	public const uint16 HID_USAGE_SIMULATION_MAGIC_CARPET_SIMULATION_DEVICE = 11;
	public const uint16 HID_USAGE_SIMULATION_BICYCLE_SIMULATION_DEVICE = 12;
	public const uint16 HID_USAGE_SIMULATION_FLIGHT_CONTROL_STICK = 32;
	public const uint16 HID_USAGE_SIMULATION_FLIGHT_STICK = 33;
	public const uint16 HID_USAGE_SIMULATION_CYCLIC_CONTROL = 34;
	public const uint16 HID_USAGE_SIMULATION_CYCLIC_TRIM = 35;
	public const uint16 HID_USAGE_SIMULATION_FLIGHT_YOKE = 36;
	public const uint16 HID_USAGE_SIMULATION_TRACK_CONTROL = 37;
	public const uint16 HID_USAGE_SIMULATION_AILERON = 176;
	public const uint16 HID_USAGE_SIMULATION_AILERON_TRIM = 177;
	public const uint16 HID_USAGE_SIMULATION_ANTI_TORQUE_CONTROL = 178;
	public const uint16 HID_USAGE_SIMULATION_AUTOPIOLOT_ENABLE = 179;
	public const uint16 HID_USAGE_SIMULATION_CHAFF_RELEASE = 180;
	public const uint16 HID_USAGE_SIMULATION_COLLECTIVE_CONTROL = 181;
	public const uint16 HID_USAGE_SIMULATION_DIVE_BRAKE = 182;
	public const uint16 HID_USAGE_SIMULATION_ELECTRONIC_COUNTERMEASURES = 183;
	public const uint16 HID_USAGE_SIMULATION_ELEVATOR = 184;
	public const uint16 HID_USAGE_SIMULATION_ELEVATOR_TRIM = 185;
	public const uint16 HID_USAGE_SIMULATION_RUDDER = 186;
	public const uint16 HID_USAGE_SIMULATION_THROTTLE = 187;
	public const uint16 HID_USAGE_SIMULATION_FLIGHT_COMMUNICATIONS = 188;
	public const uint16 HID_USAGE_SIMULATION_FLARE_RELEASE = 189;
	public const uint16 HID_USAGE_SIMULATION_LANDING_GEAR = 190;
	public const uint16 HID_USAGE_SIMULATION_TOE_BRAKE = 191;
	public const uint16 HID_USAGE_SIMULATION_TRIGGER = 192;
	public const uint16 HID_USAGE_SIMULATION_WEAPONS_ARM = 193;
	public const uint16 HID_USAGE_SIMULATION_WEAPONS_SELECT = 194;
	public const uint16 HID_USAGE_SIMULATION_WING_FLAPS = 195;
	public const uint16 HID_USAGE_SIMULATION_ACCELLERATOR = 196;
	public const uint16 HID_USAGE_SIMULATION_BRAKE = 197;
	public const uint16 HID_USAGE_SIMULATION_CLUTCH = 198;
	public const uint16 HID_USAGE_SIMULATION_SHIFTER = 199;
	public const uint16 HID_USAGE_SIMULATION_STEERING = 200;
	public const uint16 HID_USAGE_SIMULATION_TURRET_DIRECTION = 201;
	public const uint16 HID_USAGE_SIMULATION_BARREL_ELEVATION = 202;
	public const uint16 HID_USAGE_SIMULATION_DIVE_PLANE = 203;
	public const uint16 HID_USAGE_SIMULATION_BALLAST = 204;
	public const uint16 HID_USAGE_SIMULATION_BICYCLE_CRANK = 205;
	public const uint16 HID_USAGE_SIMULATION_HANDLE_BARS = 206;
	public const uint16 HID_USAGE_SIMULATION_FRONT_BRAKE = 207;
	public const uint16 HID_USAGE_SIMULATION_REAR_BRAKE = 208;
	public const uint16 HID_USAGE_VR_BELT = 1;
	public const uint16 HID_USAGE_VR_BODY_SUIT = 2;
	public const uint16 HID_USAGE_VR_FLEXOR = 3;
	public const uint16 HID_USAGE_VR_GLOVE = 4;
	public const uint16 HID_USAGE_VR_HEAD_TRACKER = 5;
	public const uint16 HID_USAGE_VR_HEAD_MOUNTED_DISPLAY = 6;
	public const uint16 HID_USAGE_VR_HAND_TRACKER = 7;
	public const uint16 HID_USAGE_VR_OCULOMETER = 8;
	public const uint16 HID_USAGE_VR_VEST = 9;
	public const uint16 HID_USAGE_VR_ANIMATRONIC_DEVICE = 10;
	public const uint16 HID_USAGE_VR_STEREO_ENABLE = 32;
	public const uint16 HID_USAGE_VR_DISPLAY_ENABLE = 33;
	public const uint16 HID_USAGE_SPORT_BASEBALL_BAT = 1;
	public const uint16 HID_USAGE_SPORT_GOLF_CLUB = 2;
	public const uint16 HID_USAGE_SPORT_ROWING_MACHINE = 3;
	public const uint16 HID_USAGE_SPORT_TREADMILL = 4;
	public const uint16 HID_USAGE_SPORT_STICK_TYPE = 56;
	public const uint16 HID_USAGE_SPORT_OAR = 48;
	public const uint16 HID_USAGE_SPORT_SLOPE = 49;
	public const uint16 HID_USAGE_SPORT_RATE = 50;
	public const uint16 HID_USAGE_SPORT_STICK_SPEED = 51;
	public const uint16 HID_USAGE_SPORT_STICK_FACE_ANGLE = 52;
	public const uint16 HID_USAGE_SPORT_HEEL_TOE = 53;
	public const uint16 HID_USAGE_SPORT_FOLLOW_THROUGH = 54;
	public const uint16 HID_USAGE_SPORT_TEMPO = 55;
	public const uint16 HID_USAGE_SPORT_HEIGHT = 57;
	public const uint16 HID_USAGE_SPORT_PUTTER = 80;
	public const uint16 HID_USAGE_SPORT_1_IRON = 81;
	public const uint16 HID_USAGE_SPORT_2_IRON = 82;
	public const uint16 HID_USAGE_SPORT_3_IRON = 83;
	public const uint16 HID_USAGE_SPORT_4_IRON = 84;
	public const uint16 HID_USAGE_SPORT_5_IRON = 85;
	public const uint16 HID_USAGE_SPORT_6_IRON = 86;
	public const uint16 HID_USAGE_SPORT_7_IRON = 87;
	public const uint16 HID_USAGE_SPORT_8_IRON = 88;
	public const uint16 HID_USAGE_SPORT_9_IRON = 89;
	public const uint16 HID_USAGE_SPORT_10_IRON = 90;
	public const uint16 HID_USAGE_SPORT_11_IRON = 91;
	public const uint16 HID_USAGE_SPORT_SAND_WEDGE = 92;
	public const uint16 HID_USAGE_SPORT_LOFT_WEDGE = 93;
	public const uint16 HID_USAGE_SPORT_POWER_WEDGE = 94;
	public const uint16 HID_USAGE_SPORT_1_WOOD = 95;
	public const uint16 HID_USAGE_SPORT_3_WOOD = 96;
	public const uint16 HID_USAGE_SPORT_5_WOOD = 97;
	public const uint16 HID_USAGE_SPORT_7_WOOD = 98;
	public const uint16 HID_USAGE_SPORT_9_WOOD = 99;
	public const uint16 HID_USAGE_GAME_3D_GAME_CONTROLLER = 1;
	public const uint16 HID_USAGE_GAME_PINBALL_DEVICE = 2;
	public const uint16 HID_USAGE_GAME_GUN_DEVICE = 3;
	public const uint16 HID_USAGE_GAME_POINT_OF_VIEW = 32;
	public const uint16 HID_USAGE_GAME_GUN_SELECTOR = 50;
	public const uint16 HID_USAGE_GAME_GAMEPAD_FIRE_JUMP = 55;
	public const uint16 HID_USAGE_GAME_GAMEPAD_TRIGGER = 57;
	public const uint16 HID_USAGE_GAME_TURN_RIGHT_LEFT = 33;
	public const uint16 HID_USAGE_GAME_PITCH_FORWARD_BACK = 34;
	public const uint16 HID_USAGE_GAME_ROLL_RIGHT_LEFT = 35;
	public const uint16 HID_USAGE_GAME_MOVE_RIGHT_LEFT = 36;
	public const uint16 HID_USAGE_GAME_MOVE_FORWARD_BACK = 37;
	public const uint16 HID_USAGE_GAME_MOVE_UP_DOWN = 38;
	public const uint16 HID_USAGE_GAME_LEAN_RIGHT_LEFT = 39;
	public const uint16 HID_USAGE_GAME_LEAN_FORWARD_BACK = 40;
	public const uint16 HID_USAGE_GAME_POV_HEIGHT = 41;
	public const uint16 HID_USAGE_GAME_FLIPPER = 42;
	public const uint16 HID_USAGE_GAME_SECONDARY_FLIPPER = 43;
	public const uint16 HID_USAGE_GAME_BUMP = 44;
	public const uint16 HID_USAGE_GAME_NEW_GAME = 45;
	public const uint16 HID_USAGE_GAME_SHOOT_BALL = 46;
	public const uint16 HID_USAGE_GAME_PLAYER = 47;
	public const uint16 HID_USAGE_GAME_GUN_BOLT = 48;
	public const uint16 HID_USAGE_GAME_GUN_CLIP = 49;
	public const uint16 HID_USAGE_GAME_GUN_SINGLE_SHOT = 51;
	public const uint16 HID_USAGE_GAME_GUN_BURST = 52;
	public const uint16 HID_USAGE_GAME_GUN_AUTOMATIC = 53;
	public const uint16 HID_USAGE_GAME_GUN_SAFETY = 54;
	public const uint16 HID_USAGE_GENERIC_DEVICE_BATTERY_STRENGTH = 32;
	public const uint16 HID_USAGE_GENERIC_DEVICE_WIRELESS_CHANNEL = 33;
	public const uint16 HID_USAGE_GENERIC_DEVICE_WIRELESS_ID = 34;
	public const uint16 HID_USAGE_GENERIC_DEVICE_DISCOVER_WIRELESS_CONTROL = 35;
	public const uint16 HID_USAGE_GENERIC_DEVICE_SECURITY_CODE_CHAR_ENTERED = 36;
	public const uint16 HID_USAGE_GENERIC_DEVICE_SECURITY_CODE_CHAR_ERASED = 37;
	public const uint16 HID_USAGE_GENERIC_DEVICE_SECURITY_CODE_CLEARED = 38;
	public const uint16 HID_USAGE_KEYBOARD_NOEVENT = 0;
	public const uint16 HID_USAGE_KEYBOARD_ROLLOVER = 1;
	public const uint16 HID_USAGE_KEYBOARD_POSTFAIL = 2;
	public const uint16 HID_USAGE_KEYBOARD_UNDEFINED = 3;
	public const uint16 HID_USAGE_KEYBOARD_aA = 4;
	public const uint16 HID_USAGE_KEYBOARD_zZ = 29;
	public const uint16 HID_USAGE_KEYBOARD_ONE = 30;
	public const uint16 HID_USAGE_KEYBOARD_ZERO = 39;
	public const uint16 HID_USAGE_KEYBOARD_LCTRL = 224;
	public const uint16 HID_USAGE_KEYBOARD_LSHFT = 225;
	public const uint16 HID_USAGE_KEYBOARD_LALT = 226;
	public const uint16 HID_USAGE_KEYBOARD_LGUI = 227;
	public const uint16 HID_USAGE_KEYBOARD_RCTRL = 228;
	public const uint16 HID_USAGE_KEYBOARD_RSHFT = 229;
	public const uint16 HID_USAGE_KEYBOARD_RALT = 230;
	public const uint16 HID_USAGE_KEYBOARD_RGUI = 231;
	public const uint16 HID_USAGE_KEYBOARD_SCROLL_LOCK = 71;
	public const uint16 HID_USAGE_KEYBOARD_NUM_LOCK = 83;
	public const uint16 HID_USAGE_KEYBOARD_CAPS_LOCK = 57;
	public const uint16 HID_USAGE_KEYBOARD_F1 = 58;
	public const uint16 HID_USAGE_KEYBOARD_F2 = 59;
	public const uint16 HID_USAGE_KEYBOARD_F3 = 60;
	public const uint16 HID_USAGE_KEYBOARD_F4 = 61;
	public const uint16 HID_USAGE_KEYBOARD_F5 = 62;
	public const uint16 HID_USAGE_KEYBOARD_F6 = 63;
	public const uint16 HID_USAGE_KEYBOARD_F7 = 64;
	public const uint16 HID_USAGE_KEYBOARD_F8 = 65;
	public const uint16 HID_USAGE_KEYBOARD_F9 = 66;
	public const uint16 HID_USAGE_KEYBOARD_F10 = 67;
	public const uint16 HID_USAGE_KEYBOARD_F11 = 68;
	public const uint16 HID_USAGE_KEYBOARD_F12 = 69;
	public const uint16 HID_USAGE_KEYBOARD_F13 = 104;
	public const uint16 HID_USAGE_KEYBOARD_F14 = 105;
	public const uint16 HID_USAGE_KEYBOARD_F15 = 106;
	public const uint16 HID_USAGE_KEYBOARD_F16 = 107;
	public const uint16 HID_USAGE_KEYBOARD_F17 = 108;
	public const uint16 HID_USAGE_KEYBOARD_F18 = 109;
	public const uint16 HID_USAGE_KEYBOARD_F19 = 110;
	public const uint16 HID_USAGE_KEYBOARD_F20 = 111;
	public const uint16 HID_USAGE_KEYBOARD_F21 = 112;
	public const uint16 HID_USAGE_KEYBOARD_F22 = 113;
	public const uint16 HID_USAGE_KEYBOARD_F23 = 114;
	public const uint16 HID_USAGE_KEYBOARD_F24 = 115;
	public const uint16 HID_USAGE_KEYBOARD_RETURN = 40;
	public const uint16 HID_USAGE_KEYBOARD_ESCAPE = 41;
	public const uint16 HID_USAGE_KEYBOARD_DELETE = 42;
	public const uint16 HID_USAGE_KEYBOARD_PRINT_SCREEN = 70;
	public const uint16 HID_USAGE_KEYBOARD_DELETE_FORWARD = 76;
	public const uint16 HID_USAGE_LED_NUM_LOCK = 1;
	public const uint16 HID_USAGE_LED_CAPS_LOCK = 2;
	public const uint16 HID_USAGE_LED_SCROLL_LOCK = 3;
	public const uint16 HID_USAGE_LED_COMPOSE = 4;
	public const uint16 HID_USAGE_LED_KANA = 5;
	public const uint16 HID_USAGE_LED_POWER = 6;
	public const uint16 HID_USAGE_LED_SHIFT = 7;
	public const uint16 HID_USAGE_LED_DO_NOT_DISTURB = 8;
	public const uint16 HID_USAGE_LED_MUTE = 9;
	public const uint16 HID_USAGE_LED_TONE_ENABLE = 10;
	public const uint16 HID_USAGE_LED_HIGH_CUT_FILTER = 11;
	public const uint16 HID_USAGE_LED_LOW_CUT_FILTER = 12;
	public const uint16 HID_USAGE_LED_EQUALIZER_ENABLE = 13;
	public const uint16 HID_USAGE_LED_SOUND_FIELD_ON = 14;
	public const uint16 HID_USAGE_LED_SURROUND_FIELD_ON = 15;
	public const uint16 HID_USAGE_LED_REPEAT = 16;
	public const uint16 HID_USAGE_LED_STEREO = 17;
	public const uint16 HID_USAGE_LED_SAMPLING_RATE_DETECT = 18;
	public const uint16 HID_USAGE_LED_SPINNING = 19;
	public const uint16 HID_USAGE_LED_CAV = 20;
	public const uint16 HID_USAGE_LED_CLV = 21;
	public const uint16 HID_USAGE_LED_RECORDING_FORMAT_DET = 22;
	public const uint16 HID_USAGE_LED_OFF_HOOK = 23;
	public const uint16 HID_USAGE_LED_RING = 24;
	public const uint16 HID_USAGE_LED_MESSAGE_WAITING = 25;
	public const uint16 HID_USAGE_LED_DATA_MODE = 26;
	public const uint16 HID_USAGE_LED_BATTERY_OPERATION = 27;
	public const uint16 HID_USAGE_LED_BATTERY_OK = 28;
	public const uint16 HID_USAGE_LED_BATTERY_LOW = 29;
	public const uint16 HID_USAGE_LED_SPEAKER = 30;
	public const uint16 HID_USAGE_LED_HEAD_SET = 31;
	public const uint16 HID_USAGE_LED_HOLD = 32;
	public const uint16 HID_USAGE_LED_MICROPHONE = 33;
	public const uint16 HID_USAGE_LED_COVERAGE = 34;
	public const uint16 HID_USAGE_LED_NIGHT_MODE = 35;
	public const uint16 HID_USAGE_LED_SEND_CALLS = 36;
	public const uint16 HID_USAGE_LED_CALL_PICKUP = 37;
	public const uint16 HID_USAGE_LED_CONFERENCE = 38;
	public const uint16 HID_USAGE_LED_STAND_BY = 39;
	public const uint16 HID_USAGE_LED_CAMERA_ON = 40;
	public const uint16 HID_USAGE_LED_CAMERA_OFF = 41;
	public const uint16 HID_USAGE_LED_ON_LINE = 42;
	public const uint16 HID_USAGE_LED_OFF_LINE = 43;
	public const uint16 HID_USAGE_LED_BUSY = 44;
	public const uint16 HID_USAGE_LED_READY = 45;
	public const uint16 HID_USAGE_LED_PAPER_OUT = 46;
	public const uint16 HID_USAGE_LED_PAPER_JAM = 47;
	public const uint16 HID_USAGE_LED_REMOTE = 48;
	public const uint16 HID_USAGE_LED_FORWARD = 49;
	public const uint16 HID_USAGE_LED_REVERSE = 50;
	public const uint16 HID_USAGE_LED_STOP = 51;
	public const uint16 HID_USAGE_LED_REWIND = 52;
	public const uint16 HID_USAGE_LED_FAST_FORWARD = 53;
	public const uint16 HID_USAGE_LED_PLAY = 54;
	public const uint16 HID_USAGE_LED_PAUSE = 55;
	public const uint16 HID_USAGE_LED_RECORD = 56;
	public const uint16 HID_USAGE_LED_ERROR = 57;
	public const uint16 HID_USAGE_LED_SELECTED_INDICATOR = 58;
	public const uint16 HID_USAGE_LED_IN_USE_INDICATOR = 59;
	public const uint16 HID_USAGE_LED_MULTI_MODE_INDICATOR = 60;
	public const uint16 HID_USAGE_LED_INDICATOR_ON = 61;
	public const uint16 HID_USAGE_LED_INDICATOR_FLASH = 62;
	public const uint16 HID_USAGE_LED_INDICATOR_SLOW_BLINK = 63;
	public const uint16 HID_USAGE_LED_INDICATOR_FAST_BLINK = 64;
	public const uint16 HID_USAGE_LED_INDICATOR_OFF = 65;
	public const uint16 HID_USAGE_LED_FLASH_ON_TIME = 66;
	public const uint16 HID_USAGE_LED_SLOW_BLINK_ON_TIME = 67;
	public const uint16 HID_USAGE_LED_SLOW_BLINK_OFF_TIME = 68;
	public const uint16 HID_USAGE_LED_FAST_BLINK_ON_TIME = 69;
	public const uint16 HID_USAGE_LED_FAST_BLINK_OFF_TIME = 70;
	public const uint16 HID_USAGE_LED_INDICATOR_COLOR = 71;
	public const uint16 HID_USAGE_LED_RED = 72;
	public const uint16 HID_USAGE_LED_GREEN = 73;
	public const uint16 HID_USAGE_LED_AMBER = 74;
	public const uint16 HID_USAGE_LED_GENERIC_INDICATOR = 75;
	public const uint16 HID_USAGE_LED_SYSTEM_SUSPEND = 76;
	public const uint16 HID_USAGE_LED_EXTERNAL_POWER = 77;
	public const uint16 HID_USAGE_TELEPHONY_PHONE = 1;
	public const uint16 HID_USAGE_TELEPHONY_ANSWERING_MACHINE = 2;
	public const uint16 HID_USAGE_TELEPHONY_MESSAGE_CONTROLS = 3;
	public const uint16 HID_USAGE_TELEPHONY_HANDSET = 4;
	public const uint16 HID_USAGE_TELEPHONY_HEADSET = 5;
	public const uint16 HID_USAGE_TELEPHONY_KEYPAD = 6;
	public const uint16 HID_USAGE_TELEPHONY_PROGRAMMABLE_BUTTON = 7;
	public const uint16 HID_USAGE_TELEPHONY_REDIAL = 36;
	public const uint16 HID_USAGE_TELEPHONY_TRANSFER = 37;
	public const uint16 HID_USAGE_TELEPHONY_DROP = 38;
	public const uint16 HID_USAGE_TELEPHONY_LINE = 42;
	public const uint16 HID_USAGE_TELEPHONY_RING_ENABLE = 45;
	public const uint16 HID_USAGE_TELEPHONY_SEND = 49;
	public const uint16 HID_USAGE_TELEPHONY_KEYPAD_0 = 176;
	public const uint16 HID_USAGE_TELEPHONY_KEYPAD_D = 191;
	public const uint16 HID_USAGE_TELEPHONY_HOST_AVAILABLE = 241;
	public const uint16 HID_USAGE_CONSUMERCTRL = 1;
	public const uint16 HID_USAGE_CONSUMER_CHANNEL_INCREMENT = 156;
	public const uint16 HID_USAGE_CONSUMER_CHANNEL_DECREMENT = 157;
	public const uint16 HID_USAGE_CONSUMER_PLAY = 176;
	public const uint16 HID_USAGE_CONSUMER_PAUSE = 177;
	public const uint16 HID_USAGE_CONSUMER_RECORD = 178;
	public const uint16 HID_USAGE_CONSUMER_FAST_FORWARD = 179;
	public const uint16 HID_USAGE_CONSUMER_REWIND = 180;
	public const uint16 HID_USAGE_CONSUMER_SCAN_NEXT_TRACK = 181;
	public const uint16 HID_USAGE_CONSUMER_SCAN_PREV_TRACK = 182;
	public const uint16 HID_USAGE_CONSUMER_STOP = 183;
	public const uint16 HID_USAGE_CONSUMER_PLAY_PAUSE = 205;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_OPEN_GAMEBAR = 208;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_TOGGLE_RECORD = 209;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_RECORD_CLIP = 210;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_SCREENSHOT = 211;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_TOGGLE_INDICATOR = 212;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_TOGGLE_MICROPHONE = 213;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_TOGGLE_CAMERA = 214;
	public const uint16 HID_USAGE_CONSUMER_GAMEDVR_TOGGLE_BROADCAST = 215;
	public const uint16 HID_USAGE_CONSUMER_VOLUME = 224;
	public const uint16 HID_USAGE_CONSUMER_BALANCE = 225;
	public const uint16 HID_USAGE_CONSUMER_MUTE = 226;
	public const uint16 HID_USAGE_CONSUMER_BASS = 227;
	public const uint16 HID_USAGE_CONSUMER_TREBLE = 228;
	public const uint16 HID_USAGE_CONSUMER_BASS_BOOST = 229;
	public const uint16 HID_USAGE_CONSUMER_SURROUND_MODE = 230;
	public const uint16 HID_USAGE_CONSUMER_LOUDNESS = 231;
	public const uint16 HID_USAGE_CONSUMER_MPX = 232;
	public const uint16 HID_USAGE_CONSUMER_VOLUME_INCREMENT = 233;
	public const uint16 HID_USAGE_CONSUMER_VOLUME_DECREMENT = 234;
	public const uint16 HID_USAGE_CONSUMER_BASS_INCREMENT = 338;
	public const uint16 HID_USAGE_CONSUMER_BASS_DECREMENT = 339;
	public const uint16 HID_USAGE_CONSUMER_TREBLE_INCREMENT = 340;
	public const uint16 HID_USAGE_CONSUMER_TREBLE_DECREMENT = 341;
	public const uint16 HID_USAGE_CONSUMER_AL_CONFIGURATION = 387;
	public const uint16 HID_USAGE_CONSUMER_AL_EMAIL = 394;
	public const uint16 HID_USAGE_CONSUMER_AL_CALCULATOR = 402;
	public const uint16 HID_USAGE_CONSUMER_AL_BROWSER = 404;
	public const uint16 HID_USAGE_CONSUMER_AL_SEARCH = 454;
	public const uint16 HID_USAGE_CONSUMER_AC_SEARCH = 545;
	public const uint16 HID_USAGE_CONSUMER_AC_GOTO = 546;
	public const uint16 HID_USAGE_CONSUMER_AC_HOME = 547;
	public const uint16 HID_USAGE_CONSUMER_AC_BACK = 548;
	public const uint16 HID_USAGE_CONSUMER_AC_FORWARD = 549;
	public const uint16 HID_USAGE_CONSUMER_AC_STOP = 550;
	public const uint16 HID_USAGE_CONSUMER_AC_REFRESH = 551;
	public const uint16 HID_USAGE_CONSUMER_AC_PREVIOUS = 552;
	public const uint16 HID_USAGE_CONSUMER_AC_NEXT = 553;
	public const uint16 HID_USAGE_CONSUMER_AC_BOOKMARKS = 554;
	public const uint16 HID_USAGE_CONSUMER_AC_PAN = 568;
	public const uint16 HID_USAGE_CONSUMER_EXTENDED_KEYBOARD_ATTRIBUTES_COLLECTION = 704;
	public const uint16 HID_USAGE_CONSUMER_KEYBOARD_FORM_FACTOR = 705;
	public const uint16 HID_USAGE_CONSUMER_KEYBOARD_KEY_TYPE = 706;
	public const uint16 HID_USAGE_CONSUMER_KEYBOARD_PHYSICAL_LAYOUT = 707;
	public const uint16 HID_USAGE_CONSUMER_VENDOR_SPECIFIC_KEYBOARD_PHYSICAL_LAYOUT = 708;
	public const uint16 HID_USAGE_CONSUMER_KEYBOARD_IETF_LANGUAGE_TAG_INDEX = 709;
	public const uint16 HID_USAGE_CONSUMER_IMPLEMENTED_KEYBOARD_INPUT_ASSIST_CONTROLS = 710;
	public const uint16 HID_USAGE_DIGITIZER_DIGITIZER = 1;
	public const uint16 HID_USAGE_DIGITIZER_PEN = 2;
	public const uint16 HID_USAGE_DIGITIZER_LIGHT_PEN = 3;
	public const uint16 HID_USAGE_DIGITIZER_TOUCH_SCREEN = 4;
	public const uint16 HID_USAGE_DIGITIZER_TOUCH_PAD = 5;
	public const uint16 HID_USAGE_DIGITIZER_WHITE_BOARD = 6;
	public const uint16 HID_USAGE_DIGITIZER_COORD_MEASURING = 7;
	public const uint16 HID_USAGE_DIGITIZER_3D_DIGITIZER = 8;
	public const uint16 HID_USAGE_DIGITIZER_STEREO_PLOTTER = 9;
	public const uint16 HID_USAGE_DIGITIZER_ARTICULATED_ARM = 10;
	public const uint16 HID_USAGE_DIGITIZER_ARMATURE = 11;
	public const uint16 HID_USAGE_DIGITIZER_MULTI_POINT = 12;
	public const uint16 HID_USAGE_DIGITIZER_FREE_SPACE_WAND = 13;
	public const uint16 HID_USAGE_DIGITIZER_HEAT_MAP = 15;
	public const uint16 HID_USAGE_DIGITIZER_STYLUS = 32;
	public const uint16 HID_USAGE_DIGITIZER_PUCK = 33;
	public const uint16 HID_USAGE_DIGITIZER_FINGER = 34;
	public const uint16 HID_USAGE_DIGITIZER_TABLET_FUNC_KEYS = 57;
	public const uint16 HID_USAGE_DIGITIZER_PROG_CHANGE_KEYS = 58;
	public const uint16 HID_USAGE_DIGITIZER_TIP_PRESSURE = 48;
	public const uint16 HID_USAGE_DIGITIZER_BARREL_PRESSURE = 49;
	public const uint16 HID_USAGE_DIGITIZER_IN_RANGE = 50;
	public const uint16 HID_USAGE_DIGITIZER_TOUCH = 51;
	public const uint16 HID_USAGE_DIGITIZER_UNTOUCH = 52;
	public const uint16 HID_USAGE_DIGITIZER_TAP = 53;
	public const uint16 HID_USAGE_DIGITIZER_QUALITY = 54;
	public const uint16 HID_USAGE_DIGITIZER_DATA_VALID = 55;
	public const uint16 HID_USAGE_DIGITIZER_TRANSDUCER_INDEX = 56;
	public const uint16 HID_USAGE_DIGITIZER_BATTERY_STRENGTH = 59;
	public const uint16 HID_USAGE_DIGITIZER_INVERT = 60;
	public const uint16 HID_USAGE_DIGITIZER_X_TILT = 61;
	public const uint16 HID_USAGE_DIGITIZER_Y_TILT = 62;
	public const uint16 HID_USAGE_DIGITIZER_AZIMUTH = 63;
	public const uint16 HID_USAGE_DIGITIZER_ALTITUDE = 64;
	public const uint16 HID_USAGE_DIGITIZER_TWIST = 65;
	public const uint16 HID_USAGE_DIGITIZER_TIP_SWITCH = 66;
	public const uint16 HID_USAGE_DIGITIZER_SECONDARY_TIP_SWITCH = 67;
	public const uint16 HID_USAGE_DIGITIZER_BARREL_SWITCH = 68;
	public const uint16 HID_USAGE_DIGITIZER_ERASER = 69;
	public const uint16 HID_USAGE_DIGITIZER_TABLET_PICK = 70;
	public const uint16 HID_USAGE_DIGITIZER_TRANSDUCER_SERIAL = 91;
	public const uint16 HID_USAGE_DIGITIZER_HEAT_MAP_PROTOCOL_VENDOR_ID = 106;
	public const uint16 HID_USAGE_DIGITIZER_HEAT_MAP_PROTOCOL_VERSION = 107;
	public const uint16 HID_USAGE_DIGITIZER_HEAT_MAP_FRAME_DATA = 108;
	public const uint16 HID_USAGE_DIGITIZER_TRANSDUCER_VENDOR = 145;
	public const uint16 HID_USAGE_DIGITIZER_TRANSDUCER_PRODUCT = 146;
	public const uint16 HID_USAGE_DIGITIZER_TRANSDUCER_CONNECTED = 162;
	public const uint16 HID_USAGE_HAPTICS_SIMPLE_CONTROLLER = 1;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_LIST = 16;
	public const uint16 HID_USAGE_HAPTICS_DURATION_LIST = 17;
	public const uint16 HID_USAGE_HAPTICS_AUTO_TRIGGER = 32;
	public const uint16 HID_USAGE_HAPTICS_MANUAL_TRIGGER = 33;
	public const uint16 HID_USAGE_HAPTICS_AUTO_ASSOCIATED_CONTROL = 34;
	public const uint16 HID_USAGE_HAPTICS_INTENSITY = 35;
	public const uint16 HID_USAGE_HAPTICS_REPEAT_COUNT = 36;
	public const uint16 HID_USAGE_HAPTICS_RETRIGGER_PERIOD = 37;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_VENDOR_PAGE = 38;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_VENDOR_ID = 39;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_CUTOFF_TIME = 40;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_BEGIN = 4096;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_STOP = 4097;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_NULL = 4098;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_CLICK = 4099;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_BUZZ = 4100;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_RUMBLE = 4101;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_PRESS = 4102;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_RELEASE = 4103;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_END = 8191;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_VENDOR_BEGIN = 8192;
	public const uint16 HID_USAGE_HAPTICS_WAVEFORM_VENDOR_END = 12287;
	public const uint16 HID_USAGE_ALPHANUMERIC_ALPHANUMERIC_DISPLAY = 1;
	public const uint16 HID_USAGE_ALPHANUMERIC_BITMAPPED_DISPLAY = 2;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_ATTRIBUTES_REPORT = 32;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_CONTROL_REPORT = 36;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHARACTER_REPORT = 43;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_STATUS = 45;
	public const uint16 HID_USAGE_ALPHANUMERIC_CURSOR_POSITION_REPORT = 50;
	public const uint16 HID_USAGE_ALPHANUMERIC_FONT_REPORT = 59;
	public const uint16 HID_USAGE_ALPHANUMERIC_FONT_DATA = 60;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHARACTER_ATTRIBUTE = 72;
	public const uint16 HID_USAGE_ALPHANUMERIC_PALETTE_REPORT = 133;
	public const uint16 HID_USAGE_ALPHANUMERIC_PALETTE_DATA = 136;
	public const uint16 HID_USAGE_ALPHANUMERIC_BLIT_REPORT = 138;
	public const uint16 HID_USAGE_ALPHANUMERIC_BLIT_DATA = 143;
	public const uint16 HID_USAGE_ALPHANUMERIC_SOFT_BUTTON = 144;
	public const uint16 HID_USAGE_ALPHANUMERIC_ASCII_CHARACTER_SET = 33;
	public const uint16 HID_USAGE_ALPHANUMERIC_DATA_READ_BACK = 34;
	public const uint16 HID_USAGE_ALPHANUMERIC_FONT_READ_BACK = 35;
	public const uint16 HID_USAGE_ALPHANUMERIC_CLEAR_DISPLAY = 37;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_ENABLE = 38;
	public const uint16 HID_USAGE_ALPHANUMERIC_SCREEN_SAVER_DELAY = 39;
	public const uint16 HID_USAGE_ALPHANUMERIC_SCREEN_SAVER_ENABLE = 40;
	public const uint16 HID_USAGE_ALPHANUMERIC_VERTICAL_SCROLL = 41;
	public const uint16 HID_USAGE_ALPHANUMERIC_HORIZONTAL_SCROLL = 42;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_DATA = 44;
	public const uint16 HID_USAGE_ALPHANUMERIC_STATUS_NOT_READY = 46;
	public const uint16 HID_USAGE_ALPHANUMERIC_STATUS_READY = 47;
	public const uint16 HID_USAGE_ALPHANUMERIC_ERR_NOT_A_LOADABLE_CHARACTER = 48;
	public const uint16 HID_USAGE_ALPHANUMERIC_ERR_FONT_DATA_CANNOT_BE_READ = 49;
	public const uint16 HID_USAGE_ALPHANUMERIC_ROW = 51;
	public const uint16 HID_USAGE_ALPHANUMERIC_COLUMN = 52;
	public const uint16 HID_USAGE_ALPHANUMERIC_ROWS = 53;
	public const uint16 HID_USAGE_ALPHANUMERIC_COLUMNS = 54;
	public const uint16 HID_USAGE_ALPHANUMERIC_CURSOR_PIXEL_POSITIONING = 55;
	public const uint16 HID_USAGE_ALPHANUMERIC_CURSOR_MODE = 56;
	public const uint16 HID_USAGE_ALPHANUMERIC_CURSOR_ENABLE = 57;
	public const uint16 HID_USAGE_ALPHANUMERIC_CURSOR_BLINK = 58;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_WIDTH = 61;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_HEIGHT = 62;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_SPACING_HORIZONTAL = 63;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_SPACING_VERTICAL = 64;
	public const uint16 HID_USAGE_ALPHANUMERIC_UNICODE_CHAR_SET = 65;
	public const uint16 HID_USAGE_ALPHANUMERIC_FONT_7_SEGMENT = 66;
	public const uint16 HID_USAGE_ALPHANUMERIC_7_SEGMENT_DIRECT_MAP = 67;
	public const uint16 HID_USAGE_ALPHANUMERIC_FONT_14_SEGMENT = 68;
	public const uint16 HID_USAGE_ALPHANUMERIC_14_SEGMENT_DIRECT_MAP = 69;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_BRIGHTNESS = 70;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_CONTRAST = 71;
	public const uint16 HID_USAGE_ALPHANUMERIC_ATTRIBUTE_READBACK = 73;
	public const uint16 HID_USAGE_ALPHANUMERIC_ATTRIBUTE_DATA = 74;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_ATTR_ENHANCE = 75;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_ATTR_UNDERLINE = 76;
	public const uint16 HID_USAGE_ALPHANUMERIC_CHAR_ATTR_BLINK = 77;
	public const uint16 HID_USAGE_ALPHANUMERIC_BITMAP_SIZE_X = 128;
	public const uint16 HID_USAGE_ALPHANUMERIC_BITMAP_SIZE_Y = 129;
	public const uint16 HID_USAGE_ALPHANUMERIC_BIT_DEPTH_FORMAT = 131;
	public const uint16 HID_USAGE_ALPHANUMERIC_DISPLAY_ORIENTATION = 132;
	public const uint16 HID_USAGE_ALPHANUMERIC_PALETTE_DATA_SIZE = 134;
	public const uint16 HID_USAGE_ALPHANUMERIC_PALETTE_DATA_OFFSET = 135;
	public const uint16 HID_USAGE_ALPHANUMERIC_BLIT_RECTANGLE_X1 = 139;
	public const uint16 HID_USAGE_ALPHANUMERIC_BLIT_RECTANGLE_Y1 = 140;
	public const uint16 HID_USAGE_ALPHANUMERIC_BLIT_RECTANGLE_X2 = 141;
	public const uint16 HID_USAGE_ALPHANUMERIC_BLIT_RECTANGLE_Y2 = 142;
	public const uint16 HID_USAGE_ALPHANUMERIC_SOFT_BUTTON_ID = 145;
	public const uint16 HID_USAGE_ALPHANUMERIC_SOFT_BUTTON_SIDE = 146;
	public const uint16 HID_USAGE_ALPHANUMERIC_SOFT_BUTTON_OFFSET1 = 147;
	public const uint16 HID_USAGE_ALPHANUMERIC_SOFT_BUTTON_OFFSET2 = 148;
	public const uint16 HID_USAGE_ALPHANUMERIC_SOFT_BUTTON_REPORT = 149;
	public const uint16 HID_USAGE_LAMPARRAY = 1;
	public const uint16 HID_USAGE_LAMPARRAY_ATTRBIUTES_REPORT = 2;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_COUNT = 3;
	public const uint16 HID_USAGE_LAMPARRAY_BOUNDING_BOX_WIDTH_IN_MICROMETERS = 4;
	public const uint16 HID_USAGE_LAMPARRAY_BOUNDING_BOX_HEIGHT_IN_MICROMETERS = 5;
	public const uint16 HID_USAGE_LAMPARRAY_BOUNDING_BOX_DEPTH_IN_MICROMETERS = 6;
	public const uint16 HID_USAGE_LAMPARRAY_KIND = 7;
	public const uint16 HID_USAGE_LAMPARRAY_MIN_UPDATE_INTERVAL_IN_MICROSECONDS = 8;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_ATTRIBUTES_REQUEST_REPORT = 32;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_ID = 33;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_ATTRIBUTES_RESPONSE_REPORT = 34;
	public const uint16 HID_USAGE_LAMPARRAY_POSITION_X_IN_MICROMETERS = 35;
	public const uint16 HID_USAGE_LAMPARRAY_POSITION_Y_IN_MICROMETERS = 36;
	public const uint16 HID_USAGE_LAMPARRAY_POSITION_Z_IN_MICROMETERS = 37;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_PURPOSES = 38;
	public const uint16 HID_USAGE_LAMPARRAY_UPDATE_LATENCY_IN_MICROSECONDS = 39;
	public const uint16 HID_USAGE_LAMPARRAY_RED_LEVEL_COUNT = 40;
	public const uint16 HID_USAGE_LAMPARRAY_GREEN_LEVEL_COUNT = 41;
	public const uint16 HID_USAGE_LAMPARRAY_BLUE_LEVEL_COUNT = 42;
	public const uint16 HID_USAGE_LAMPARRAY_INTENSITY_LEVEL_COUNT = 43;
	public const uint16 HID_USAGE_LAMPARRAY_IS_PROGRAMMABLE = 44;
	public const uint16 HID_USAGE_LAMPARRAY_INPUT_BINDING = 45;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_MULTI_UPDATE_REPORT = 80;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_RED_UPDATE_CHANNEL = 81;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_GREEN_UPDATE_CHANNEL = 82;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_BLUE_UPDATE_CHANNEL = 83;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_INTENSITY_UPDATE_CHANNEL = 84;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_UPDATE_FLAGS = 85;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_RANGE_UPDATE_REPORT = 96;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_ID_START = 97;
	public const uint16 HID_USAGE_LAMPARRAY_LAMP_ID_END = 98;
	public const uint16 HID_USAGE_LAMPARRAY_CONTROL_REPORT = 112;
	public const uint16 HID_USAGE_LAMPARRAY_AUTONOMOUS_MODE = 113;
	public const uint16 HID_USAGE_CAMERA_AUTO_FOCUS = 32;
	public const uint16 HID_USAGE_CAMERA_SHUTTER = 33;
	public const uint16 HID_USAGE_MS_BTH_HF_DIALNUMBER = 33;
	public const uint16 HID_USAGE_MS_BTH_HF_DIALMEMORY = 34;
	public const String DD_KEYBOARD_DEVICE_NAME = "\\Device\\KeyboardClass";
	public const String DD_KEYBOARD_DEVICE_NAME_U = "\\Device\\KeyboardClass";
	public const uint32 IOCTL_KEYBOARD_QUERY_ATTRIBUTES = 720896;
	public const uint32 IOCTL_KEYBOARD_SET_TYPEMATIC = 720900;
	public const uint32 IOCTL_KEYBOARD_SET_INDICATORS = 720904;
	public const uint32 IOCTL_KEYBOARD_QUERY_TYPEMATIC = 720928;
	public const uint32 IOCTL_KEYBOARD_QUERY_INDICATORS = 720960;
	public const uint32 IOCTL_KEYBOARD_QUERY_INDICATOR_TRANSLATION = 721024;
	public const uint32 IOCTL_KEYBOARD_INSERT_DATA = 721152;
	public const uint32 IOCTL_KEYBOARD_QUERY_EXTENDED_ATTRIBUTES = 721408;
	public const uint32 IOCTL_KEYBOARD_QUERY_IME_STATUS = 724992;
	public const uint32 IOCTL_KEYBOARD_SET_IME_STATUS = 724996;
	public const Guid GUID_DEVINTERFACE_KEYBOARD = .(0x884b96c3, 0x56ef, 0x11d1, 0xbc, 0x8c, 0x00, 0xa0, 0xc9, 0x14, 0x05, 0xdd);
	public const uint32 KEYBOARD_OVERRUN_MAKE_CODE = 255;
	public const uint32 KEY_MAKE = 0;
	public const uint32 KEY_BREAK = 1;
	public const uint32 KEY_E0 = 2;
	public const uint32 KEY_E1 = 4;
	public const uint32 KEY_TERMSRV_SET_LED = 8;
	public const uint32 KEY_TERMSRV_SHADOW = 16;
	public const uint32 KEY_TERMSRV_VKPACKET = 32;
	public const uint32 KEY_RIM_VKEY = 64;
	public const uint32 KEY_FROM_KEYBOARD_OVERRIDER = 128;
	public const uint32 KEY_UNICODE_SEQUENCE_ITEM = 256;
	public const uint32 KEY_UNICODE_SEQUENCE_END = 512;
	public const uint32 KEYBOARD_EXTENDED_ATTRIBUTES_STRUCT_VERSION_1 = 1;
	public const uint32 KEYBOARD_LED_INJECTED = 32768;
	public const uint32 KEYBOARD_SHADOW = 16384;
	public const uint32 KEYBOARD_KANA_LOCK_ON = 8;
	public const uint32 KEYBOARD_CAPS_LOCK_ON = 4;
	public const uint32 KEYBOARD_NUM_LOCK_ON = 2;
	public const uint32 KEYBOARD_SCROLL_LOCK_ON = 1;
	public const uint32 KEYBOARD_ERROR_VALUE_BASE = 10000;
	public const String DD_MOUSE_DEVICE_NAME = "\\Device\\PointerClass";
	public const String DD_MOUSE_DEVICE_NAME_U = "\\Device\\PointerClass";
	public const uint32 IOCTL_MOUSE_QUERY_ATTRIBUTES = 983040;
	public const uint32 IOCTL_MOUSE_INSERT_DATA = 983044;
	public const Guid GUID_DEVINTERFACE_MOUSE = .(0x378de44c, 0x56ef, 0x11d1, 0xbc, 0x8c, 0x00, 0xa0, 0xc9, 0x14, 0x05, 0xdd);
	public const uint32 MOUSE_LEFT_BUTTON_DOWN = 1;
	public const uint32 MOUSE_LEFT_BUTTON_UP = 2;
	public const uint32 MOUSE_RIGHT_BUTTON_DOWN = 4;
	public const uint32 MOUSE_RIGHT_BUTTON_UP = 8;
	public const uint32 MOUSE_MIDDLE_BUTTON_DOWN = 16;
	public const uint32 MOUSE_MIDDLE_BUTTON_UP = 32;
	public const uint32 MOUSE_BUTTON_1_DOWN = 1;
	public const uint32 MOUSE_BUTTON_1_UP = 2;
	public const uint32 MOUSE_BUTTON_2_DOWN = 4;
	public const uint32 MOUSE_BUTTON_2_UP = 8;
	public const uint32 MOUSE_BUTTON_3_DOWN = 16;
	public const uint32 MOUSE_BUTTON_3_UP = 32;
	public const uint32 MOUSE_BUTTON_4_DOWN = 64;
	public const uint32 MOUSE_BUTTON_4_UP = 128;
	public const uint32 MOUSE_BUTTON_5_DOWN = 256;
	public const uint32 MOUSE_BUTTON_5_UP = 512;
	public const uint32 MOUSE_WHEEL = 1024;
	public const uint32 MOUSE_HWHEEL = 2048;
	public const uint32 MOUSE_MOVE_RELATIVE = 0;
	public const uint32 MOUSE_MOVE_ABSOLUTE = 1;
	public const uint32 MOUSE_VIRTUAL_DESKTOP = 2;
	public const uint32 MOUSE_ATTRIBUTES_CHANGED = 4;
	public const uint32 MOUSE_MOVE_NOCOALESCE = 8;
	public const uint32 MOUSE_TERMSRV_SRC_SHADOW = 256;
	public const uint32 MOUSE_INPORT_HARDWARE = 1;
	public const uint32 MOUSE_I8042_HARDWARE = 2;
	public const uint32 MOUSE_SERIAL_HARDWARE = 4;
	public const uint32 BALLPOINT_I8042_HARDWARE = 8;
	public const uint32 BALLPOINT_SERIAL_HARDWARE = 16;
	public const uint32 WHEELMOUSE_I8042_HARDWARE = 32;
	public const uint32 WHEELMOUSE_SERIAL_HARDWARE = 64;
	public const uint32 MOUSE_HID_HARDWARE = 128;
	public const uint32 WHEELMOUSE_HID_HARDWARE = 256;
	public const uint32 HORIZONTAL_WHEEL_PRESENT = 32768;
	public const uint32 MOUSE_ERROR_VALUE_BASE = 20000;
	public const uint32 DIRECTINPUT_HEADER_VERSION = 2048;
	public const Guid CLSID_DirectInput = .(0x25e609e0, 0xb259, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid CLSID_DirectInputDevice = .(0x25e609e1, 0xb259, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid CLSID_DirectInput8 = .(0x25e609e4, 0xb259, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid CLSID_DirectInputDevice8 = .(0x25e609e5, 0xb259, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_XAxis = .(0xa36d02e0, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_YAxis = .(0xa36d02e1, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_ZAxis = .(0xa36d02e2, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_RxAxis = .(0xa36d02f4, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_RyAxis = .(0xa36d02f5, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_RzAxis = .(0xa36d02e3, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_Slider = .(0xa36d02e4, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_Button = .(0xa36d02f0, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_Key = .(0x55728220, 0xd33c, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_POV = .(0xa36d02f2, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_Unknown = .(0xa36d02f3, 0xc9f3, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_SysMouse = .(0x6f1d2b60, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_SysKeyboard = .(0x6f1d2b61, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_Joystick = .(0x6f1d2b70, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_SysMouseEm = .(0x6f1d2b80, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_SysMouseEm2 = .(0x6f1d2b81, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_SysKeyboardEm = .(0x6f1d2b82, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_SysKeyboardEm2 = .(0x6f1d2b83, 0xd5a0, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_ConstantForce = .(0x13541c20, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_RampForce = .(0x13541c21, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Square = .(0x13541c22, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Sine = .(0x13541c23, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Triangle = .(0x13541c24, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_SawtoothUp = .(0x13541c25, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_SawtoothDown = .(0x13541c26, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Spring = .(0x13541c27, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Damper = .(0x13541c28, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Inertia = .(0x13541c29, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_Friction = .(0x13541c2a, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const Guid GUID_CustomForce = .(0x13541c2b, 0x8e33, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);
	public const uint32 DIEFT_ALL = 0;
	public const uint32 DIEFT_CONSTANTFORCE = 1;
	public const uint32 DIEFT_RAMPFORCE = 2;
	public const uint32 DIEFT_PERIODIC = 3;
	public const uint32 DIEFT_CONDITION = 4;
	public const uint32 DIEFT_CUSTOMFORCE = 5;
	public const uint32 DIEFT_HARDWARE = 255;
	public const uint32 DIEFT_FFATTACK = 512;
	public const uint32 DIEFT_FFFADE = 1024;
	public const uint32 DIEFT_SATURATION = 2048;
	public const uint32 DIEFT_POSNEGCOEFFICIENTS = 4096;
	public const uint32 DIEFT_POSNEGSATURATION = 8192;
	public const uint32 DIEFT_DEADBAND = 16384;
	public const uint32 DIEFT_STARTDELAY = 32768;
	public const uint32 DI_DEGREES = 100;
	public const uint32 DI_FFNOMINALMAX = 10000;
	public const uint32 DI_SECONDS = 1000000;
	public const uint32 DIEFF_OBJECTIDS = 1;
	public const uint32 DIEFF_OBJECTOFFSETS = 2;
	public const uint32 DIEFF_CARTESIAN = 16;
	public const uint32 DIEFF_POLAR = 32;
	public const uint32 DIEFF_SPHERICAL = 64;
	public const uint32 DIEP_DURATION = 1;
	public const uint32 DIEP_SAMPLEPERIOD = 2;
	public const uint32 DIEP_GAIN = 4;
	public const uint32 DIEP_TRIGGERBUTTON = 8;
	public const uint32 DIEP_TRIGGERREPEATINTERVAL = 16;
	public const uint32 DIEP_AXES = 32;
	public const uint32 DIEP_DIRECTION = 64;
	public const uint32 DIEP_ENVELOPE = 128;
	public const uint32 DIEP_TYPESPECIFICPARAMS = 256;
	public const uint32 DIEP_STARTDELAY = 512;
	public const uint32 DIEP_ALLPARAMS_DX5 = 511;
	public const uint32 DIEP_ALLPARAMS = 1023;
	public const uint32 DIEP_START = 536870912;
	public const uint32 DIEP_NORESTART = 1073741824;
	public const uint32 DIEP_NODOWNLOAD = 2147483648;
	public const uint32 DIEB_NOTRIGGER = 4294967295;
	public const uint32 DIES_SOLO = 1;
	public const uint32 DIES_NODOWNLOAD = 2147483648;
	public const uint32 DIEGES_PLAYING = 1;
	public const uint32 DIEGES_EMULATED = 2;
	public const uint32 DIDEVTYPE_DEVICE = 1;
	public const uint32 DIDEVTYPE_MOUSE = 2;
	public const uint32 DIDEVTYPE_KEYBOARD = 3;
	public const uint32 DIDEVTYPE_JOYSTICK = 4;
	public const uint32 DI8DEVCLASS_ALL = 0;
	public const uint32 DI8DEVCLASS_DEVICE = 1;
	public const uint32 DI8DEVCLASS_POINTER = 2;
	public const uint32 DI8DEVCLASS_KEYBOARD = 3;
	public const uint32 DI8DEVCLASS_GAMECTRL = 4;
	public const uint32 DI8DEVTYPE_DEVICE = 17;
	public const uint32 DI8DEVTYPE_MOUSE = 18;
	public const uint32 DI8DEVTYPE_KEYBOARD = 19;
	public const uint32 DI8DEVTYPE_JOYSTICK = 20;
	public const uint32 DI8DEVTYPE_GAMEPAD = 21;
	public const uint32 DI8DEVTYPE_DRIVING = 22;
	public const uint32 DI8DEVTYPE_FLIGHT = 23;
	public const uint32 DI8DEVTYPE_1STPERSON = 24;
	public const uint32 DI8DEVTYPE_DEVICECTRL = 25;
	public const uint32 DI8DEVTYPE_SCREENPOINTER = 26;
	public const uint32 DI8DEVTYPE_REMOTE = 27;
	public const uint32 DI8DEVTYPE_SUPPLEMENTAL = 28;
	public const uint32 DIDEVTYPE_HID = 65536;
	public const uint32 DIDEVTYPEMOUSE_UNKNOWN = 1;
	public const uint32 DIDEVTYPEMOUSE_TRADITIONAL = 2;
	public const uint32 DIDEVTYPEMOUSE_FINGERSTICK = 3;
	public const uint32 DIDEVTYPEMOUSE_TOUCHPAD = 4;
	public const uint32 DIDEVTYPEMOUSE_TRACKBALL = 5;
	public const uint32 DIDEVTYPEKEYBOARD_UNKNOWN = 0;
	public const uint32 DIDEVTYPEKEYBOARD_PCXT = 1;
	public const uint32 DIDEVTYPEKEYBOARD_OLIVETTI = 2;
	public const uint32 DIDEVTYPEKEYBOARD_PCAT = 3;
	public const uint32 DIDEVTYPEKEYBOARD_PCENH = 4;
	public const uint32 DIDEVTYPEKEYBOARD_NOKIA1050 = 5;
	public const uint32 DIDEVTYPEKEYBOARD_NOKIA9140 = 6;
	public const uint32 DIDEVTYPEKEYBOARD_NEC98 = 7;
	public const uint32 DIDEVTYPEKEYBOARD_NEC98LAPTOP = 8;
	public const uint32 DIDEVTYPEKEYBOARD_NEC98106 = 9;
	public const uint32 DIDEVTYPEKEYBOARD_JAPAN106 = 10;
	public const uint32 DIDEVTYPEKEYBOARD_JAPANAX = 11;
	public const uint32 DIDEVTYPEKEYBOARD_J3100 = 12;
	public const uint32 DIDEVTYPEJOYSTICK_UNKNOWN = 1;
	public const uint32 DIDEVTYPEJOYSTICK_TRADITIONAL = 2;
	public const uint32 DIDEVTYPEJOYSTICK_FLIGHTSTICK = 3;
	public const uint32 DIDEVTYPEJOYSTICK_GAMEPAD = 4;
	public const uint32 DIDEVTYPEJOYSTICK_RUDDER = 5;
	public const uint32 DIDEVTYPEJOYSTICK_WHEEL = 6;
	public const uint32 DIDEVTYPEJOYSTICK_HEADTRACKER = 7;
	public const uint32 DI8DEVTYPEMOUSE_UNKNOWN = 1;
	public const uint32 DI8DEVTYPEMOUSE_TRADITIONAL = 2;
	public const uint32 DI8DEVTYPEMOUSE_FINGERSTICK = 3;
	public const uint32 DI8DEVTYPEMOUSE_TOUCHPAD = 4;
	public const uint32 DI8DEVTYPEMOUSE_TRACKBALL = 5;
	public const uint32 DI8DEVTYPEMOUSE_ABSOLUTE = 6;
	public const uint32 DI8DEVTYPEKEYBOARD_UNKNOWN = 0;
	public const uint32 DI8DEVTYPEKEYBOARD_PCXT = 1;
	public const uint32 DI8DEVTYPEKEYBOARD_OLIVETTI = 2;
	public const uint32 DI8DEVTYPEKEYBOARD_PCAT = 3;
	public const uint32 DI8DEVTYPEKEYBOARD_PCENH = 4;
	public const uint32 DI8DEVTYPEKEYBOARD_NOKIA1050 = 5;
	public const uint32 DI8DEVTYPEKEYBOARD_NOKIA9140 = 6;
	public const uint32 DI8DEVTYPEKEYBOARD_NEC98 = 7;
	public const uint32 DI8DEVTYPEKEYBOARD_NEC98LAPTOP = 8;
	public const uint32 DI8DEVTYPEKEYBOARD_NEC98106 = 9;
	public const uint32 DI8DEVTYPEKEYBOARD_JAPAN106 = 10;
	public const uint32 DI8DEVTYPEKEYBOARD_JAPANAX = 11;
	public const uint32 DI8DEVTYPEKEYBOARD_J3100 = 12;
	public const uint32 DI8DEVTYPE_LIMITEDGAMESUBTYPE = 1;
	public const uint32 DI8DEVTYPEJOYSTICK_LIMITED = 1;
	public const uint32 DI8DEVTYPEJOYSTICK_STANDARD = 2;
	public const uint32 DI8DEVTYPEGAMEPAD_LIMITED = 1;
	public const uint32 DI8DEVTYPEGAMEPAD_STANDARD = 2;
	public const uint32 DI8DEVTYPEGAMEPAD_TILT = 3;
	public const uint32 DI8DEVTYPEDRIVING_LIMITED = 1;
	public const uint32 DI8DEVTYPEDRIVING_COMBINEDPEDALS = 2;
	public const uint32 DI8DEVTYPEDRIVING_DUALPEDALS = 3;
	public const uint32 DI8DEVTYPEDRIVING_THREEPEDALS = 4;
	public const uint32 DI8DEVTYPEDRIVING_HANDHELD = 5;
	public const uint32 DI8DEVTYPEFLIGHT_LIMITED = 1;
	public const uint32 DI8DEVTYPEFLIGHT_STICK = 2;
	public const uint32 DI8DEVTYPEFLIGHT_YOKE = 3;
	public const uint32 DI8DEVTYPEFLIGHT_RC = 4;
	public const uint32 DI8DEVTYPE1STPERSON_LIMITED = 1;
	public const uint32 DI8DEVTYPE1STPERSON_UNKNOWN = 2;
	public const uint32 DI8DEVTYPE1STPERSON_SIXDOF = 3;
	public const uint32 DI8DEVTYPE1STPERSON_SHOOTER = 4;
	public const uint32 DI8DEVTYPESCREENPTR_UNKNOWN = 2;
	public const uint32 DI8DEVTYPESCREENPTR_LIGHTGUN = 3;
	public const uint32 DI8DEVTYPESCREENPTR_LIGHTPEN = 4;
	public const uint32 DI8DEVTYPESCREENPTR_TOUCH = 5;
	public const uint32 DI8DEVTYPEREMOTE_UNKNOWN = 2;
	public const uint32 DI8DEVTYPEDEVICECTRL_UNKNOWN = 2;
	public const uint32 DI8DEVTYPEDEVICECTRL_COMMSSELECTION = 3;
	public const uint32 DI8DEVTYPEDEVICECTRL_COMMSSELECTION_HARDWIRED = 4;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_UNKNOWN = 2;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_2NDHANDCONTROLLER = 3;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_HEADTRACKER = 4;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_HANDTRACKER = 5;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_SHIFTSTICKGATE = 6;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_SHIFTER = 7;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_THROTTLE = 8;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_SPLITTHROTTLE = 9;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_COMBINEDPEDALS = 10;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_DUALPEDALS = 11;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_THREEPEDALS = 12;
	public const uint32 DI8DEVTYPESUPPLEMENTAL_RUDDERPEDALS = 13;
	public const uint32 DIDC_ATTACHED = 1;
	public const uint32 DIDC_POLLEDDEVICE = 2;
	public const uint32 DIDC_EMULATED = 4;
	public const uint32 DIDC_POLLEDDATAFORMAT = 8;
	public const uint32 DIDC_FORCEFEEDBACK = 256;
	public const uint32 DIDC_FFATTACK = 512;
	public const uint32 DIDC_FFFADE = 1024;
	public const uint32 DIDC_SATURATION = 2048;
	public const uint32 DIDC_POSNEGCOEFFICIENTS = 4096;
	public const uint32 DIDC_POSNEGSATURATION = 8192;
	public const uint32 DIDC_DEADBAND = 16384;
	public const uint32 DIDC_STARTDELAY = 32768;
	public const uint32 DIDC_ALIAS = 65536;
	public const uint32 DIDC_PHANTOM = 131072;
	public const uint32 DIDC_HIDDEN = 262144;
	public const uint32 DIDFT_ALL = 0;
	public const uint32 DIDFT_RELAXIS = 1;
	public const uint32 DIDFT_ABSAXIS = 2;
	public const uint32 DIDFT_AXIS = 3;
	public const uint32 DIDFT_PSHBUTTON = 4;
	public const uint32 DIDFT_TGLBUTTON = 8;
	public const uint32 DIDFT_BUTTON = 12;
	public const uint32 DIDFT_POV = 16;
	public const uint32 DIDFT_COLLECTION = 64;
	public const uint32 DIDFT_NODATA = 128;
	public const uint32 DIDFT_ANYINSTANCE = 16776960;
	public const uint32 DIDFT_INSTANCEMASK = 16776960;
	public const uint32 DIDFT_FFACTUATOR = 16777216;
	public const uint32 DIDFT_FFEFFECTTRIGGER = 33554432;
	public const uint32 DIDFT_OUTPUT = 268435456;
	public const uint32 DIDFT_VENDORDEFINED = 67108864;
	public const uint32 DIDFT_ALIAS = 134217728;
	public const uint32 DIDFT_NOCOLLECTION = 16776960;
	public const uint32 DIDF_ABSAXIS = 1;
	public const uint32 DIDF_RELAXIS = 2;
	public const uint32 DIA_FORCEFEEDBACK = 1;
	public const uint32 DIA_APPMAPPED = 2;
	public const uint32 DIA_APPNOMAP = 4;
	public const uint32 DIA_NORANGE = 8;
	public const uint32 DIA_APPFIXED = 16;
	public const uint32 DIAH_UNMAPPED = 0;
	public const uint32 DIAH_USERCONFIG = 1;
	public const uint32 DIAH_APPREQUESTED = 2;
	public const uint32 DIAH_HWAPP = 4;
	public const uint32 DIAH_HWDEFAULT = 8;
	public const uint32 DIAH_DEFAULT = 32;
	public const uint32 DIAH_ERROR = 2147483648;
	public const uint32 DIAFTS_NEWDEVICELOW = 4294967295;
	public const uint32 DIAFTS_NEWDEVICEHIGH = 4294967295;
	public const uint32 DIAFTS_UNUSEDDEVICELOW = 0;
	public const uint32 DIAFTS_UNUSEDDEVICEHIGH = 0;
	public const uint32 DIDBAM_DEFAULT = 0;
	public const uint32 DIDBAM_PRESERVE = 1;
	public const uint32 DIDBAM_INITIALIZE = 2;
	public const uint32 DIDBAM_HWDEFAULTS = 4;
	public const uint32 DIDSAM_DEFAULT = 0;
	public const uint32 DIDSAM_NOUSER = 1;
	public const uint32 DIDSAM_FORCESAVE = 2;
	public const uint32 DICD_DEFAULT = 0;
	public const uint32 DICD_EDIT = 1;
	public const uint32 DIDIFT_CONFIGURATION = 1;
	public const uint32 DIDIFT_OVERLAY = 2;
	public const uint32 DIDAL_CENTERED = 0;
	public const uint32 DIDAL_LEFTALIGNED = 1;
	public const uint32 DIDAL_RIGHTALIGNED = 2;
	public const uint32 DIDAL_MIDDLE = 0;
	public const uint32 DIDAL_TOPALIGNED = 4;
	public const uint32 DIDAL_BOTTOMALIGNED = 8;
	public const uint32 DIDOI_FFACTUATOR = 1;
	public const uint32 DIDOI_FFEFFECTTRIGGER = 2;
	public const uint32 DIDOI_POLLED = 32768;
	public const uint32 DIDOI_ASPECTPOSITION = 256;
	public const uint32 DIDOI_ASPECTVELOCITY = 512;
	public const uint32 DIDOI_ASPECTACCEL = 768;
	public const uint32 DIDOI_ASPECTFORCE = 1024;
	public const uint32 DIDOI_ASPECTMASK = 3840;
	public const uint32 DIDOI_GUIDISUSAGE = 65536;
	public const uint32 DIPH_DEVICE = 0;
	public const uint32 DIPH_BYOFFSET = 1;
	public const uint32 DIPH_BYID = 2;
	public const uint32 DIPH_BYUSAGE = 3;
	public const uint32 MAXCPOINTSNUM = 8;
	public const uint32 DIPROPAXISMODE_ABS = 0;
	public const uint32 DIPROPAXISMODE_REL = 1;
	public const uint32 DIPROPAUTOCENTER_OFF = 0;
	public const uint32 DIPROPAUTOCENTER_ON = 1;
	public const uint32 DIPROPCALIBRATIONMODE_COOKED = 0;
	public const uint32 DIPROPCALIBRATIONMODE_RAW = 1;
	public const uint32 DIGDD_PEEK = 1;
	public const uint32 DISCL_EXCLUSIVE = 1;
	public const uint32 DISCL_NONEXCLUSIVE = 2;
	public const uint32 DISCL_FOREGROUND = 4;
	public const uint32 DISCL_BACKGROUND = 8;
	public const uint32 DISCL_NOWINKEY = 16;
	public const uint32 DISFFC_RESET = 1;
	public const uint32 DISFFC_STOPALL = 2;
	public const uint32 DISFFC_PAUSE = 4;
	public const uint32 DISFFC_CONTINUE = 8;
	public const uint32 DISFFC_SETACTUATORSON = 16;
	public const uint32 DISFFC_SETACTUATORSOFF = 32;
	public const uint32 DIGFFS_EMPTY = 1;
	public const uint32 DIGFFS_STOPPED = 2;
	public const uint32 DIGFFS_PAUSED = 4;
	public const uint32 DIGFFS_ACTUATORSON = 16;
	public const uint32 DIGFFS_ACTUATORSOFF = 32;
	public const uint32 DIGFFS_POWERON = 64;
	public const uint32 DIGFFS_POWEROFF = 128;
	public const uint32 DIGFFS_SAFETYSWITCHON = 256;
	public const uint32 DIGFFS_SAFETYSWITCHOFF = 512;
	public const uint32 DIGFFS_USERFFSWITCHON = 1024;
	public const uint32 DIGFFS_USERFFSWITCHOFF = 2048;
	public const uint32 DIGFFS_DEVICELOST = 2147483648;
	public const uint32 DISDD_CONTINUE = 1;
	public const uint32 DIFEF_DEFAULT = 0;
	public const uint32 DIFEF_INCLUDENONSTANDARD = 1;
	public const uint32 DIFEF_MODIFYIFNEEDED = 16;
	public const uint32 DIK_ESCAPE = 1;
	public const uint32 DIK_1 = 2;
	public const uint32 DIK_2 = 3;
	public const uint32 DIK_3 = 4;
	public const uint32 DIK_4 = 5;
	public const uint32 DIK_5 = 6;
	public const uint32 DIK_6 = 7;
	public const uint32 DIK_7 = 8;
	public const uint32 DIK_8 = 9;
	public const uint32 DIK_9 = 10;
	public const uint32 DIK_0 = 11;
	public const uint32 DIK_MINUS = 12;
	public const uint32 DIK_EQUALS = 13;
	public const uint32 DIK_BACK = 14;
	public const uint32 DIK_TAB = 15;
	public const uint32 DIK_Q = 16;
	public const uint32 DIK_W = 17;
	public const uint32 DIK_E = 18;
	public const uint32 DIK_R = 19;
	public const uint32 DIK_T = 20;
	public const uint32 DIK_Y = 21;
	public const uint32 DIK_U = 22;
	public const uint32 DIK_I = 23;
	public const uint32 DIK_O = 24;
	public const uint32 DIK_P = 25;
	public const uint32 DIK_LBRACKET = 26;
	public const uint32 DIK_RBRACKET = 27;
	public const uint32 DIK_RETURN = 28;
	public const uint32 DIK_LCONTROL = 29;
	public const uint32 DIK_A = 30;
	public const uint32 DIK_S = 31;
	public const uint32 DIK_D = 32;
	public const uint32 DIK_F = 33;
	public const uint32 DIK_G = 34;
	public const uint32 DIK_H = 35;
	public const uint32 DIK_J = 36;
	public const uint32 DIK_K = 37;
	public const uint32 DIK_L = 38;
	public const uint32 DIK_SEMICOLON = 39;
	public const uint32 DIK_APOSTROPHE = 40;
	public const uint32 DIK_GRAVE = 41;
	public const uint32 DIK_LSHIFT = 42;
	public const uint32 DIK_BACKSLASH = 43;
	public const uint32 DIK_Z = 44;
	public const uint32 DIK_X = 45;
	public const uint32 DIK_C = 46;
	public const uint32 DIK_V = 47;
	public const uint32 DIK_B = 48;
	public const uint32 DIK_N = 49;
	public const uint32 DIK_M = 50;
	public const uint32 DIK_COMMA = 51;
	public const uint32 DIK_PERIOD = 52;
	public const uint32 DIK_SLASH = 53;
	public const uint32 DIK_RSHIFT = 54;
	public const uint32 DIK_MULTIPLY = 55;
	public const uint32 DIK_LMENU = 56;
	public const uint32 DIK_SPACE = 57;
	public const uint32 DIK_CAPITAL = 58;
	public const uint32 DIK_F1 = 59;
	public const uint32 DIK_F2 = 60;
	public const uint32 DIK_F3 = 61;
	public const uint32 DIK_F4 = 62;
	public const uint32 DIK_F5 = 63;
	public const uint32 DIK_F6 = 64;
	public const uint32 DIK_F7 = 65;
	public const uint32 DIK_F8 = 66;
	public const uint32 DIK_F9 = 67;
	public const uint32 DIK_F10 = 68;
	public const uint32 DIK_NUMLOCK = 69;
	public const uint32 DIK_SCROLL = 70;
	public const uint32 DIK_NUMPAD7 = 71;
	public const uint32 DIK_NUMPAD8 = 72;
	public const uint32 DIK_NUMPAD9 = 73;
	public const uint32 DIK_SUBTRACT = 74;
	public const uint32 DIK_NUMPAD4 = 75;
	public const uint32 DIK_NUMPAD5 = 76;
	public const uint32 DIK_NUMPAD6 = 77;
	public const uint32 DIK_ADD = 78;
	public const uint32 DIK_NUMPAD1 = 79;
	public const uint32 DIK_NUMPAD2 = 80;
	public const uint32 DIK_NUMPAD3 = 81;
	public const uint32 DIK_NUMPAD0 = 82;
	public const uint32 DIK_DECIMAL = 83;
	public const uint32 DIK_OEM_102 = 86;
	public const uint32 DIK_F11 = 87;
	public const uint32 DIK_F12 = 88;
	public const uint32 DIK_F13 = 100;
	public const uint32 DIK_F14 = 101;
	public const uint32 DIK_F15 = 102;
	public const uint32 DIK_KANA = 112;
	public const uint32 DIK_ABNT_C1 = 115;
	public const uint32 DIK_CONVERT = 121;
	public const uint32 DIK_NOCONVERT = 123;
	public const uint32 DIK_YEN = 125;
	public const uint32 DIK_ABNT_C2 = 126;
	public const uint32 DIK_NUMPADEQUALS = 141;
	public const uint32 DIK_PREVTRACK = 144;
	public const uint32 DIK_AT = 145;
	public const uint32 DIK_COLON = 146;
	public const uint32 DIK_UNDERLINE = 147;
	public const uint32 DIK_KANJI = 148;
	public const uint32 DIK_STOP = 149;
	public const uint32 DIK_AX = 150;
	public const uint32 DIK_UNLABELED = 151;
	public const uint32 DIK_NEXTTRACK = 153;
	public const uint32 DIK_NUMPADENTER = 156;
	public const uint32 DIK_RCONTROL = 157;
	public const uint32 DIK_MUTE = 160;
	public const uint32 DIK_CALCULATOR = 161;
	public const uint32 DIK_PLAYPAUSE = 162;
	public const uint32 DIK_MEDIASTOP = 164;
	public const uint32 DIK_VOLUMEDOWN = 174;
	public const uint32 DIK_VOLUMEUP = 176;
	public const uint32 DIK_WEBHOME = 178;
	public const uint32 DIK_NUMPADCOMMA = 179;
	public const uint32 DIK_DIVIDE = 181;
	public const uint32 DIK_SYSRQ = 183;
	public const uint32 DIK_RMENU = 184;
	public const uint32 DIK_PAUSE = 197;
	public const uint32 DIK_HOME = 199;
	public const uint32 DIK_UP = 200;
	public const uint32 DIK_PRIOR = 201;
	public const uint32 DIK_LEFT = 203;
	public const uint32 DIK_RIGHT = 205;
	public const uint32 DIK_END = 207;
	public const uint32 DIK_DOWN = 208;
	public const uint32 DIK_NEXT = 209;
	public const uint32 DIK_INSERT = 210;
	public const uint32 DIK_DELETE = 211;
	public const uint32 DIK_LWIN = 219;
	public const uint32 DIK_RWIN = 220;
	public const uint32 DIK_APPS = 221;
	public const uint32 DIK_POWER = 222;
	public const uint32 DIK_SLEEP = 223;
	public const uint32 DIK_WAKE = 227;
	public const uint32 DIK_WEBSEARCH = 229;
	public const uint32 DIK_WEBFAVORITES = 230;
	public const uint32 DIK_WEBREFRESH = 231;
	public const uint32 DIK_WEBSTOP = 232;
	public const uint32 DIK_WEBFORWARD = 233;
	public const uint32 DIK_WEBBACK = 234;
	public const uint32 DIK_MYCOMPUTER = 235;
	public const uint32 DIK_MAIL = 236;
	public const uint32 DIK_MEDIASELECT = 237;
	public const uint32 DIK_BACKSPACE = 14;
	public const uint32 DIK_NUMPADSTAR = 55;
	public const uint32 DIK_LALT = 56;
	public const uint32 DIK_CAPSLOCK = 58;
	public const uint32 DIK_NUMPADMINUS = 74;
	public const uint32 DIK_NUMPADPLUS = 78;
	public const uint32 DIK_NUMPADPERIOD = 83;
	public const uint32 DIK_NUMPADSLASH = 181;
	public const uint32 DIK_RALT = 184;
	public const uint32 DIK_UPARROW = 200;
	public const uint32 DIK_PGUP = 201;
	public const uint32 DIK_LEFTARROW = 203;
	public const uint32 DIK_RIGHTARROW = 205;
	public const uint32 DIK_DOWNARROW = 208;
	public const uint32 DIK_PGDN = 209;
	public const uint32 DIK_CIRCUMFLEX = 144;
	public const uint32 DIENUM_STOP = 0;
	public const uint32 DIENUM_CONTINUE = 1;
	public const uint32 DIEDFL_ALLDEVICES = 0;
	public const uint32 DIEDFL_ATTACHEDONLY = 1;
	public const uint32 DIEDFL_FORCEFEEDBACK = 256;
	public const uint32 DIEDFL_INCLUDEALIASES = 65536;
	public const uint32 DIEDFL_INCLUDEPHANTOMS = 131072;
	public const uint32 DIEDFL_INCLUDEHIDDEN = 262144;
	public const uint32 DIEDBS_MAPPEDPRI1 = 1;
	public const uint32 DIEDBS_MAPPEDPRI2 = 2;
	public const uint32 DIEDBS_RECENTDEVICE = 16;
	public const uint32 DIEDBS_NEWDEVICE = 32;
	public const uint32 DIEDBSFL_ATTACHEDONLY = 0;
	public const uint32 DIEDBSFL_THISUSER = 16;
	public const uint32 DIEDBSFL_FORCEFEEDBACK = 256;
	public const uint32 DIEDBSFL_AVAILABLEDEVICES = 4096;
	public const uint32 DIEDBSFL_MULTIMICEKEYBOARDS = 8192;
	public const uint32 DIEDBSFL_NONGAMINGDEVICES = 16384;
	public const uint32 DIEDBSFL_VALID = 28944;
	public const int32 DI_OK = 0;
	public const int32 DI_NOTATTACHED = 1;
	public const int32 DI_BUFFEROVERFLOW = 1;
	public const int32 DI_PROPNOEFFECT = 1;
	public const int32 DI_NOEFFECT = 1;
	public const HRESULT DI_POLLEDDEVICE = 2;
	public const HRESULT DI_DOWNLOADSKIPPED = 3;
	public const HRESULT DI_EFFECTRESTARTED = 4;
	public const HRESULT DI_TRUNCATED = 8;
	public const HRESULT DI_SETTINGSNOTSAVED = 11;
	public const HRESULT DI_TRUNCATEDANDRESTARTED = 12;
	public const HRESULT DI_WRITEPROTECT = 19;
	public const HRESULT DIERR_OLDDIRECTINPUTVERSION = -2147023746;
	public const HRESULT DIERR_BETADIRECTINPUTVERSION = -2147023743;
	public const HRESULT DIERR_BADDRIVERVER = -2147024777;
	public const int32 DIERR_DEVICENOTREG = -2147221164;
	public const HRESULT DIERR_NOTFOUND = -2147024894;
	public const HRESULT DIERR_OBJECTNOTFOUND = -2147024894;
	public const int32 DIERR_INVALIDPARAM = -2147024809;
	public const int32 DIERR_NOINTERFACE = -2147467262;
	public const int32 DIERR_GENERIC = -2147467259;
	public const int32 DIERR_OUTOFMEMORY = -2147024882;
	public const int32 DIERR_UNSUPPORTED = -2147467263;
	public const HRESULT DIERR_NOTINITIALIZED = -2147024875;
	public const HRESULT DIERR_ALREADYINITIALIZED = -2147023649;
	public const int32 DIERR_NOAGGREGATION = -2147221232;
	public const int32 DIERR_OTHERAPPHASPRIO = -2147024891;
	public const HRESULT DIERR_INPUTLOST = -2147024866;
	public const HRESULT DIERR_ACQUIRED = -2147024726;
	public const HRESULT DIERR_NOTACQUIRED = -2147024884;
	public const int32 DIERR_READONLY = -2147024891;
	public const int32 DIERR_HANDLEEXISTS = -2147024891;
	public const int32 DIERR_INSUFFICIENTPRIVS = -2147220992;
	public const int32 DIERR_DEVICEFULL = -2147220991;
	public const int32 DIERR_MOREDATA = -2147220990;
	public const int32 DIERR_NOTDOWNLOADED = -2147220989;
	public const int32 DIERR_HASEFFECTS = -2147220988;
	public const int32 DIERR_NOTEXCLUSIVEACQUIRED = -2147220987;
	public const int32 DIERR_INCOMPLETEEFFECT = -2147220986;
	public const int32 DIERR_NOTBUFFERED = -2147220985;
	public const int32 DIERR_EFFECTPLAYING = -2147220984;
	public const int32 DIERR_UNPLUGGED = -2147220983;
	public const int32 DIERR_REPORTFULL = -2147220982;
	public const int32 DIERR_MAPFILEFAIL = -2147220981;
	public const uint32 DIKEYBOARD_ESCAPE = 2164261889;
	public const uint32 DIKEYBOARD_1 = 2164261890;
	public const uint32 DIKEYBOARD_2 = 2164261891;
	public const uint32 DIKEYBOARD_3 = 2164261892;
	public const uint32 DIKEYBOARD_4 = 2164261893;
	public const uint32 DIKEYBOARD_5 = 2164261894;
	public const uint32 DIKEYBOARD_6 = 2164261895;
	public const uint32 DIKEYBOARD_7 = 2164261896;
	public const uint32 DIKEYBOARD_8 = 2164261897;
	public const uint32 DIKEYBOARD_9 = 2164261898;
	public const uint32 DIKEYBOARD_0 = 2164261899;
	public const uint32 DIKEYBOARD_MINUS = 2164261900;
	public const uint32 DIKEYBOARD_EQUALS = 2164261901;
	public const uint32 DIKEYBOARD_BACK = 2164261902;
	public const uint32 DIKEYBOARD_TAB = 2164261903;
	public const uint32 DIKEYBOARD_Q = 2164261904;
	public const uint32 DIKEYBOARD_W = 2164261905;
	public const uint32 DIKEYBOARD_E = 2164261906;
	public const uint32 DIKEYBOARD_R = 2164261907;
	public const uint32 DIKEYBOARD_T = 2164261908;
	public const uint32 DIKEYBOARD_Y = 2164261909;
	public const uint32 DIKEYBOARD_U = 2164261910;
	public const uint32 DIKEYBOARD_I = 2164261911;
	public const uint32 DIKEYBOARD_O = 2164261912;
	public const uint32 DIKEYBOARD_P = 2164261913;
	public const uint32 DIKEYBOARD_LBRACKET = 2164261914;
	public const uint32 DIKEYBOARD_RBRACKET = 2164261915;
	public const uint32 DIKEYBOARD_RETURN = 2164261916;
	public const uint32 DIKEYBOARD_LCONTROL = 2164261917;
	public const uint32 DIKEYBOARD_A = 2164261918;
	public const uint32 DIKEYBOARD_S = 2164261919;
	public const uint32 DIKEYBOARD_D = 2164261920;
	public const uint32 DIKEYBOARD_F = 2164261921;
	public const uint32 DIKEYBOARD_G = 2164261922;
	public const uint32 DIKEYBOARD_H = 2164261923;
	public const uint32 DIKEYBOARD_J = 2164261924;
	public const uint32 DIKEYBOARD_K = 2164261925;
	public const uint32 DIKEYBOARD_L = 2164261926;
	public const uint32 DIKEYBOARD_SEMICOLON = 2164261927;
	public const uint32 DIKEYBOARD_APOSTROPHE = 2164261928;
	public const uint32 DIKEYBOARD_GRAVE = 2164261929;
	public const uint32 DIKEYBOARD_LSHIFT = 2164261930;
	public const uint32 DIKEYBOARD_BACKSLASH = 2164261931;
	public const uint32 DIKEYBOARD_Z = 2164261932;
	public const uint32 DIKEYBOARD_X = 2164261933;
	public const uint32 DIKEYBOARD_C = 2164261934;
	public const uint32 DIKEYBOARD_V = 2164261935;
	public const uint32 DIKEYBOARD_B = 2164261936;
	public const uint32 DIKEYBOARD_N = 2164261937;
	public const uint32 DIKEYBOARD_M = 2164261938;
	public const uint32 DIKEYBOARD_COMMA = 2164261939;
	public const uint32 DIKEYBOARD_PERIOD = 2164261940;
	public const uint32 DIKEYBOARD_SLASH = 2164261941;
	public const uint32 DIKEYBOARD_RSHIFT = 2164261942;
	public const uint32 DIKEYBOARD_MULTIPLY = 2164261943;
	public const uint32 DIKEYBOARD_LMENU = 2164261944;
	public const uint32 DIKEYBOARD_SPACE = 2164261945;
	public const uint32 DIKEYBOARD_CAPITAL = 2164261946;
	public const uint32 DIKEYBOARD_F1 = 2164261947;
	public const uint32 DIKEYBOARD_F2 = 2164261948;
	public const uint32 DIKEYBOARD_F3 = 2164261949;
	public const uint32 DIKEYBOARD_F4 = 2164261950;
	public const uint32 DIKEYBOARD_F5 = 2164261951;
	public const uint32 DIKEYBOARD_F6 = 2164261952;
	public const uint32 DIKEYBOARD_F7 = 2164261953;
	public const uint32 DIKEYBOARD_F8 = 2164261954;
	public const uint32 DIKEYBOARD_F9 = 2164261955;
	public const uint32 DIKEYBOARD_F10 = 2164261956;
	public const uint32 DIKEYBOARD_NUMLOCK = 2164261957;
	public const uint32 DIKEYBOARD_SCROLL = 2164261958;
	public const uint32 DIKEYBOARD_NUMPAD7 = 2164261959;
	public const uint32 DIKEYBOARD_NUMPAD8 = 2164261960;
	public const uint32 DIKEYBOARD_NUMPAD9 = 2164261961;
	public const uint32 DIKEYBOARD_SUBTRACT = 2164261962;
	public const uint32 DIKEYBOARD_NUMPAD4 = 2164261963;
	public const uint32 DIKEYBOARD_NUMPAD5 = 2164261964;
	public const uint32 DIKEYBOARD_NUMPAD6 = 2164261965;
	public const uint32 DIKEYBOARD_ADD = 2164261966;
	public const uint32 DIKEYBOARD_NUMPAD1 = 2164261967;
	public const uint32 DIKEYBOARD_NUMPAD2 = 2164261968;
	public const uint32 DIKEYBOARD_NUMPAD3 = 2164261969;
	public const uint32 DIKEYBOARD_NUMPAD0 = 2164261970;
	public const uint32 DIKEYBOARD_DECIMAL = 2164261971;
	public const uint32 DIKEYBOARD_OEM_102 = 2164261974;
	public const uint32 DIKEYBOARD_F11 = 2164261975;
	public const uint32 DIKEYBOARD_F12 = 2164261976;
	public const uint32 DIKEYBOARD_F13 = 2164261988;
	public const uint32 DIKEYBOARD_F14 = 2164261989;
	public const uint32 DIKEYBOARD_F15 = 2164261990;
	public const uint32 DIKEYBOARD_KANA = 2164262000;
	public const uint32 DIKEYBOARD_ABNT_C1 = 2164262003;
	public const uint32 DIKEYBOARD_CONVERT = 2164262009;
	public const uint32 DIKEYBOARD_NOCONVERT = 2164262011;
	public const uint32 DIKEYBOARD_YEN = 2164262013;
	public const uint32 DIKEYBOARD_ABNT_C2 = 2164262014;
	public const uint32 DIKEYBOARD_NUMPADEQUALS = 2164262029;
	public const uint32 DIKEYBOARD_PREVTRACK = 2164262032;
	public const uint32 DIKEYBOARD_AT = 2164262033;
	public const uint32 DIKEYBOARD_COLON = 2164262034;
	public const uint32 DIKEYBOARD_UNDERLINE = 2164262035;
	public const uint32 DIKEYBOARD_KANJI = 2164262036;
	public const uint32 DIKEYBOARD_STOP = 2164262037;
	public const uint32 DIKEYBOARD_AX = 2164262038;
	public const uint32 DIKEYBOARD_UNLABELED = 2164262039;
	public const uint32 DIKEYBOARD_NEXTTRACK = 2164262041;
	public const uint32 DIKEYBOARD_NUMPADENTER = 2164262044;
	public const uint32 DIKEYBOARD_RCONTROL = 2164262045;
	public const uint32 DIKEYBOARD_MUTE = 2164262048;
	public const uint32 DIKEYBOARD_CALCULATOR = 2164262049;
	public const uint32 DIKEYBOARD_PLAYPAUSE = 2164262050;
	public const uint32 DIKEYBOARD_MEDIASTOP = 2164262052;
	public const uint32 DIKEYBOARD_VOLUMEDOWN = 2164262062;
	public const uint32 DIKEYBOARD_VOLUMEUP = 2164262064;
	public const uint32 DIKEYBOARD_WEBHOME = 2164262066;
	public const uint32 DIKEYBOARD_NUMPADCOMMA = 2164262067;
	public const uint32 DIKEYBOARD_DIVIDE = 2164262069;
	public const uint32 DIKEYBOARD_SYSRQ = 2164262071;
	public const uint32 DIKEYBOARD_RMENU = 2164262072;
	public const uint32 DIKEYBOARD_PAUSE = 2164262085;
	public const uint32 DIKEYBOARD_HOME = 2164262087;
	public const uint32 DIKEYBOARD_UP = 2164262088;
	public const uint32 DIKEYBOARD_PRIOR = 2164262089;
	public const uint32 DIKEYBOARD_LEFT = 2164262091;
	public const uint32 DIKEYBOARD_RIGHT = 2164262093;
	public const uint32 DIKEYBOARD_END = 2164262095;
	public const uint32 DIKEYBOARD_DOWN = 2164262096;
	public const uint32 DIKEYBOARD_NEXT = 2164262097;
	public const uint32 DIKEYBOARD_INSERT = 2164262098;
	public const uint32 DIKEYBOARD_DELETE = 2164262099;
	public const uint32 DIKEYBOARD_LWIN = 2164262107;
	public const uint32 DIKEYBOARD_RWIN = 2164262108;
	public const uint32 DIKEYBOARD_APPS = 2164262109;
	public const uint32 DIKEYBOARD_POWER = 2164262110;
	public const uint32 DIKEYBOARD_SLEEP = 2164262111;
	public const uint32 DIKEYBOARD_WAKE = 2164262115;
	public const uint32 DIKEYBOARD_WEBSEARCH = 2164262117;
	public const uint32 DIKEYBOARD_WEBFAVORITES = 2164262118;
	public const uint32 DIKEYBOARD_WEBREFRESH = 2164262119;
	public const uint32 DIKEYBOARD_WEBSTOP = 2164262120;
	public const uint32 DIKEYBOARD_WEBFORWARD = 2164262121;
	public const uint32 DIKEYBOARD_WEBBACK = 2164262122;
	public const uint32 DIKEYBOARD_MYCOMPUTER = 2164262123;
	public const uint32 DIKEYBOARD_MAIL = 2164262124;
	public const uint32 DIKEYBOARD_MEDIASELECT = 2164262125;
	public const uint32 DIVOICE_CHANNEL1 = 2197816321;
	public const uint32 DIVOICE_CHANNEL2 = 2197816322;
	public const uint32 DIVOICE_CHANNEL3 = 2197816323;
	public const uint32 DIVOICE_CHANNEL4 = 2197816324;
	public const uint32 DIVOICE_CHANNEL5 = 2197816325;
	public const uint32 DIVOICE_CHANNEL6 = 2197816326;
	public const uint32 DIVOICE_CHANNEL7 = 2197816327;
	public const uint32 DIVOICE_CHANNEL8 = 2197816328;
	public const uint32 DIVOICE_TEAM = 2197816329;
	public const uint32 DIVOICE_ALL = 2197816330;
	public const uint32 DIVOICE_RECORDMUTE = 2197816331;
	public const uint32 DIVOICE_PLAYBACKMUTE = 2197816332;
	public const uint32 DIVOICE_TRANSMIT = 2197816333;
	public const uint32 DIVOICE_VOICECOMMAND = 2197816336;
	public const uint32 DIVIRTUAL_DRIVING_RACE = 16777216;
	public const uint32 DIAXIS_DRIVINGR_STEER = 16812545;
	public const uint32 DIAXIS_DRIVINGR_ACCELERATE = 17011202;
	public const uint32 DIAXIS_DRIVINGR_BRAKE = 17043971;
	public const uint32 DIBUTTON_DRIVINGR_SHIFTUP = 16780289;
	public const uint32 DIBUTTON_DRIVINGR_SHIFTDOWN = 16780290;
	public const uint32 DIBUTTON_DRIVINGR_VIEW = 16784387;
	public const uint32 DIBUTTON_DRIVINGR_MENU = 16778493;
	public const uint32 DIAXIS_DRIVINGR_ACCEL_AND_BRAKE = 16861700;
	public const uint32 DIHATSWITCH_DRIVINGR_GLANCE = 16795137;
	public const uint32 DIBUTTON_DRIVINGR_BRAKE = 16796676;
	public const uint32 DIBUTTON_DRIVINGR_DASHBOARD = 16794629;
	public const uint32 DIBUTTON_DRIVINGR_AIDS = 16794630;
	public const uint32 DIBUTTON_DRIVINGR_MAP = 16794631;
	public const uint32 DIBUTTON_DRIVINGR_BOOST = 16794632;
	public const uint32 DIBUTTON_DRIVINGR_PIT = 16794633;
	public const uint32 DIBUTTON_DRIVINGR_ACCELERATE_LINK = 17028320;
	public const uint32 DIBUTTON_DRIVINGR_STEER_LEFT_LINK = 16829668;
	public const uint32 DIBUTTON_DRIVINGR_STEER_RIGHT_LINK = 16829676;
	public const uint32 DIBUTTON_DRIVINGR_GLANCE_LEFT_LINK = 17286372;
	public const uint32 DIBUTTON_DRIVINGR_GLANCE_RIGHT_LINK = 17286380;
	public const uint32 DIBUTTON_DRIVINGR_DEVICE = 16794878;
	public const uint32 DIBUTTON_DRIVINGR_PAUSE = 16794876;
	public const uint32 DIVIRTUAL_DRIVING_COMBAT = 33554432;
	public const uint32 DIAXIS_DRIVINGC_STEER = 33589761;
	public const uint32 DIAXIS_DRIVINGC_ACCELERATE = 33788418;
	public const uint32 DIAXIS_DRIVINGC_BRAKE = 33821187;
	public const uint32 DIBUTTON_DRIVINGC_FIRE = 33557505;
	public const uint32 DIBUTTON_DRIVINGC_WEAPONS = 33557506;
	public const uint32 DIBUTTON_DRIVINGC_TARGET = 33557507;
	public const uint32 DIBUTTON_DRIVINGC_MENU = 33555709;
	public const uint32 DIAXIS_DRIVINGC_ACCEL_AND_BRAKE = 33638916;
	public const uint32 DIHATSWITCH_DRIVINGC_GLANCE = 33572353;
	public const uint32 DIBUTTON_DRIVINGC_SHIFTUP = 33573892;
	public const uint32 DIBUTTON_DRIVINGC_SHIFTDOWN = 33573893;
	public const uint32 DIBUTTON_DRIVINGC_DASHBOARD = 33571846;
	public const uint32 DIBUTTON_DRIVINGC_AIDS = 33571847;
	public const uint32 DIBUTTON_DRIVINGC_BRAKE = 33573896;
	public const uint32 DIBUTTON_DRIVINGC_FIRESECONDARY = 33573897;
	public const uint32 DIBUTTON_DRIVINGC_ACCELERATE_LINK = 33805536;
	public const uint32 DIBUTTON_DRIVINGC_STEER_LEFT_LINK = 33606884;
	public const uint32 DIBUTTON_DRIVINGC_STEER_RIGHT_LINK = 33606892;
	public const uint32 DIBUTTON_DRIVINGC_GLANCE_LEFT_LINK = 34063588;
	public const uint32 DIBUTTON_DRIVINGC_GLANCE_RIGHT_LINK = 34063596;
	public const uint32 DIBUTTON_DRIVINGC_DEVICE = 33572094;
	public const uint32 DIBUTTON_DRIVINGC_PAUSE = 33572092;
	public const uint32 DIVIRTUAL_DRIVING_TANK = 50331648;
	public const uint32 DIAXIS_DRIVINGT_STEER = 50366977;
	public const uint32 DIAXIS_DRIVINGT_BARREL = 50397698;
	public const uint32 DIAXIS_DRIVINGT_ACCELERATE = 50565635;
	public const uint32 DIAXIS_DRIVINGT_ROTATE = 50463236;
	public const uint32 DIBUTTON_DRIVINGT_FIRE = 50334721;
	public const uint32 DIBUTTON_DRIVINGT_WEAPONS = 50334722;
	public const uint32 DIBUTTON_DRIVINGT_TARGET = 50334723;
	public const uint32 DIBUTTON_DRIVINGT_MENU = 50332925;
	public const uint32 DIHATSWITCH_DRIVINGT_GLANCE = 50349569;
	public const uint32 DIAXIS_DRIVINGT_BRAKE = 50614789;
	public const uint32 DIAXIS_DRIVINGT_ACCEL_AND_BRAKE = 50416134;
	public const uint32 DIBUTTON_DRIVINGT_VIEW = 50355204;
	public const uint32 DIBUTTON_DRIVINGT_DASHBOARD = 50355205;
	public const uint32 DIBUTTON_DRIVINGT_BRAKE = 50351110;
	public const uint32 DIBUTTON_DRIVINGT_FIRESECONDARY = 50351111;
	public const uint32 DIBUTTON_DRIVINGT_ACCELERATE_LINK = 50582752;
	public const uint32 DIBUTTON_DRIVINGT_STEER_LEFT_LINK = 50384100;
	public const uint32 DIBUTTON_DRIVINGT_STEER_RIGHT_LINK = 50384108;
	public const uint32 DIBUTTON_DRIVINGT_BARREL_UP_LINK = 50414816;
	public const uint32 DIBUTTON_DRIVINGT_BARREL_DOWN_LINK = 50414824;
	public const uint32 DIBUTTON_DRIVINGT_ROTATE_LEFT_LINK = 50480356;
	public const uint32 DIBUTTON_DRIVINGT_ROTATE_RIGHT_LINK = 50480364;
	public const uint32 DIBUTTON_DRIVINGT_GLANCE_LEFT_LINK = 50840804;
	public const uint32 DIBUTTON_DRIVINGT_GLANCE_RIGHT_LINK = 50840812;
	public const uint32 DIBUTTON_DRIVINGT_DEVICE = 50349310;
	public const uint32 DIBUTTON_DRIVINGT_PAUSE = 50349308;
	public const uint32 DIVIRTUAL_FLYING_CIVILIAN = 67108864;
	public const uint32 DIAXIS_FLYINGC_BANK = 67144193;
	public const uint32 DIAXIS_FLYINGC_PITCH = 67176962;
	public const uint32 DIAXIS_FLYINGC_THROTTLE = 67342851;
	public const uint32 DIBUTTON_FLYINGC_VIEW = 67118081;
	public const uint32 DIBUTTON_FLYINGC_DISPLAY = 67118082;
	public const uint32 DIBUTTON_FLYINGC_GEAR = 67120131;
	public const uint32 DIBUTTON_FLYINGC_MENU = 67110141;
	public const uint32 DIHATSWITCH_FLYINGC_GLANCE = 67126785;
	public const uint32 DIAXIS_FLYINGC_BRAKE = 67398148;
	public const uint32 DIAXIS_FLYINGC_RUDDER = 67260933;
	public const uint32 DIAXIS_FLYINGC_FLAPS = 67459590;
	public const uint32 DIBUTTON_FLYINGC_FLAPSUP = 67134468;
	public const uint32 DIBUTTON_FLYINGC_FLAPSDOWN = 67134469;
	public const uint32 DIBUTTON_FLYINGC_BRAKE_LINK = 67398880;
	public const uint32 DIBUTTON_FLYINGC_FASTER_LINK = 67359968;
	public const uint32 DIBUTTON_FLYINGC_SLOWER_LINK = 67359976;
	public const uint32 DIBUTTON_FLYINGC_GLANCE_LEFT_LINK = 67618020;
	public const uint32 DIBUTTON_FLYINGC_GLANCE_RIGHT_LINK = 67618028;
	public const uint32 DIBUTTON_FLYINGC_GLANCE_UP_LINK = 67618016;
	public const uint32 DIBUTTON_FLYINGC_GLANCE_DOWN_LINK = 67618024;
	public const uint32 DIBUTTON_FLYINGC_DEVICE = 67126526;
	public const uint32 DIBUTTON_FLYINGC_PAUSE = 67126524;
	public const uint32 DIVIRTUAL_FLYING_MILITARY = 83886080;
	public const uint32 DIAXIS_FLYINGM_BANK = 83921409;
	public const uint32 DIAXIS_FLYINGM_PITCH = 83954178;
	public const uint32 DIAXIS_FLYINGM_THROTTLE = 84120067;
	public const uint32 DIBUTTON_FLYINGM_FIRE = 83889153;
	public const uint32 DIBUTTON_FLYINGM_WEAPONS = 83889154;
	public const uint32 DIBUTTON_FLYINGM_TARGET = 83889155;
	public const uint32 DIBUTTON_FLYINGM_MENU = 83887357;
	public const uint32 DIHATSWITCH_FLYINGM_GLANCE = 83904001;
	public const uint32 DIBUTTON_FLYINGM_COUNTER = 83909636;
	public const uint32 DIAXIS_FLYINGM_RUDDER = 84036100;
	public const uint32 DIAXIS_FLYINGM_BRAKE = 84173317;
	public const uint32 DIBUTTON_FLYINGM_VIEW = 83911685;
	public const uint32 DIBUTTON_FLYINGM_DISPLAY = 83911686;
	public const uint32 DIAXIS_FLYINGM_FLAPS = 84234758;
	public const uint32 DIBUTTON_FLYINGM_FLAPSUP = 83907591;
	public const uint32 DIBUTTON_FLYINGM_FLAPSDOWN = 83907592;
	public const uint32 DIBUTTON_FLYINGM_FIRESECONDARY = 83905545;
	public const uint32 DIBUTTON_FLYINGM_GEAR = 83911690;
	public const uint32 DIBUTTON_FLYINGM_BRAKE_LINK = 84174048;
	public const uint32 DIBUTTON_FLYINGM_FASTER_LINK = 84137184;
	public const uint32 DIBUTTON_FLYINGM_SLOWER_LINK = 84137192;
	public const uint32 DIBUTTON_FLYINGM_GLANCE_LEFT_LINK = 84395236;
	public const uint32 DIBUTTON_FLYINGM_GLANCE_RIGHT_LINK = 84395244;
	public const uint32 DIBUTTON_FLYINGM_GLANCE_UP_LINK = 84395232;
	public const uint32 DIBUTTON_FLYINGM_GLANCE_DOWN_LINK = 84395240;
	public const uint32 DIBUTTON_FLYINGM_DEVICE = 83903742;
	public const uint32 DIBUTTON_FLYINGM_PAUSE = 83903740;
	public const uint32 DIVIRTUAL_FLYING_HELICOPTER = 100663296;
	public const uint32 DIAXIS_FLYINGH_BANK = 100698625;
	public const uint32 DIAXIS_FLYINGH_PITCH = 100731394;
	public const uint32 DIAXIS_FLYINGH_COLLECTIVE = 100764163;
	public const uint32 DIBUTTON_FLYINGH_FIRE = 100668417;
	public const uint32 DIBUTTON_FLYINGH_WEAPONS = 100668418;
	public const uint32 DIBUTTON_FLYINGH_TARGET = 100668419;
	public const uint32 DIBUTTON_FLYINGH_MENU = 100664573;
	public const uint32 DIHATSWITCH_FLYINGH_GLANCE = 100681217;
	public const uint32 DIAXIS_FLYINGH_TORQUE = 100817412;
	public const uint32 DIAXIS_FLYINGH_THROTTLE = 100915717;
	public const uint32 DIBUTTON_FLYINGH_COUNTER = 100684804;
	public const uint32 DIBUTTON_FLYINGH_VIEW = 100688901;
	public const uint32 DIBUTTON_FLYINGH_GEAR = 100688902;
	public const uint32 DIBUTTON_FLYINGH_FIRESECONDARY = 100682759;
	public const uint32 DIBUTTON_FLYINGH_FASTER_LINK = 100916448;
	public const uint32 DIBUTTON_FLYINGH_SLOWER_LINK = 100916456;
	public const uint32 DIBUTTON_FLYINGH_GLANCE_LEFT_LINK = 101172452;
	public const uint32 DIBUTTON_FLYINGH_GLANCE_RIGHT_LINK = 101172460;
	public const uint32 DIBUTTON_FLYINGH_GLANCE_UP_LINK = 101172448;
	public const uint32 DIBUTTON_FLYINGH_GLANCE_DOWN_LINK = 101172456;
	public const uint32 DIBUTTON_FLYINGH_DEVICE = 100680958;
	public const uint32 DIBUTTON_FLYINGH_PAUSE = 100680956;
	public const uint32 DIVIRTUAL_SPACESIM = 117440512;
	public const uint32 DIAXIS_SPACESIM_LATERAL = 117473793;
	public const uint32 DIAXIS_SPACESIM_MOVE = 117506562;
	public const uint32 DIAXIS_SPACESIM_THROTTLE = 117670403;
	public const uint32 DIBUTTON_SPACESIM_FIRE = 117441537;
	public const uint32 DIBUTTON_SPACESIM_WEAPONS = 117441538;
	public const uint32 DIBUTTON_SPACESIM_TARGET = 117441539;
	public const uint32 DIBUTTON_SPACESIM_MENU = 117441789;
	public const uint32 DIHATSWITCH_SPACESIM_GLANCE = 117458433;
	public const uint32 DIAXIS_SPACESIM_CLIMB = 117555716;
	public const uint32 DIAXIS_SPACESIM_ROTATE = 117588485;
	public const uint32 DIBUTTON_SPACESIM_VIEW = 117457924;
	public const uint32 DIBUTTON_SPACESIM_DISPLAY = 117457925;
	public const uint32 DIBUTTON_SPACESIM_RAISE = 117457926;
	public const uint32 DIBUTTON_SPACESIM_LOWER = 117457927;
	public const uint32 DIBUTTON_SPACESIM_GEAR = 117457928;
	public const uint32 DIBUTTON_SPACESIM_FIRESECONDARY = 117457929;
	public const uint32 DIBUTTON_SPACESIM_LEFT_LINK = 117490916;
	public const uint32 DIBUTTON_SPACESIM_RIGHT_LINK = 117490924;
	public const uint32 DIBUTTON_SPACESIM_FORWARD_LINK = 117523680;
	public const uint32 DIBUTTON_SPACESIM_BACKWARD_LINK = 117523688;
	public const uint32 DIBUTTON_SPACESIM_FASTER_LINK = 117687520;
	public const uint32 DIBUTTON_SPACESIM_SLOWER_LINK = 117687528;
	public const uint32 DIBUTTON_SPACESIM_TURN_LEFT_LINK = 117589220;
	public const uint32 DIBUTTON_SPACESIM_TURN_RIGHT_LINK = 117589228;
	public const uint32 DIBUTTON_SPACESIM_GLANCE_LEFT_LINK = 117949668;
	public const uint32 DIBUTTON_SPACESIM_GLANCE_RIGHT_LINK = 117949676;
	public const uint32 DIBUTTON_SPACESIM_GLANCE_UP_LINK = 117949664;
	public const uint32 DIBUTTON_SPACESIM_GLANCE_DOWN_LINK = 117949672;
	public const uint32 DIBUTTON_SPACESIM_DEVICE = 117458174;
	public const uint32 DIBUTTON_SPACESIM_PAUSE = 117458172;
	public const uint32 DIVIRTUAL_FIGHTING_HAND2HAND = 134217728;
	public const uint32 DIAXIS_FIGHTINGH_LATERAL = 134251009;
	public const uint32 DIAXIS_FIGHTINGH_MOVE = 134283778;
	public const uint32 DIBUTTON_FIGHTINGH_PUNCH = 134218753;
	public const uint32 DIBUTTON_FIGHTINGH_KICK = 134218754;
	public const uint32 DIBUTTON_FIGHTINGH_BLOCK = 134218755;
	public const uint32 DIBUTTON_FIGHTINGH_CROUCH = 134218756;
	public const uint32 DIBUTTON_FIGHTINGH_JUMP = 134218757;
	public const uint32 DIBUTTON_FIGHTINGH_SPECIAL1 = 134218758;
	public const uint32 DIBUTTON_FIGHTINGH_SPECIAL2 = 134218759;
	public const uint32 DIBUTTON_FIGHTINGH_MENU = 134219005;
	public const uint32 DIBUTTON_FIGHTINGH_SELECT = 134235144;
	public const uint32 DIHATSWITCH_FIGHTINGH_SLIDE = 134235649;
	public const uint32 DIBUTTON_FIGHTINGH_DISPLAY = 134235145;
	public const uint32 DIAXIS_FIGHTINGH_ROTATE = 134365699;
	public const uint32 DIBUTTON_FIGHTINGH_DODGE = 134235146;
	public const uint32 DIBUTTON_FIGHTINGH_LEFT_LINK = 134268132;
	public const uint32 DIBUTTON_FIGHTINGH_RIGHT_LINK = 134268140;
	public const uint32 DIBUTTON_FIGHTINGH_FORWARD_LINK = 134300896;
	public const uint32 DIBUTTON_FIGHTINGH_BACKWARD_LINK = 134300904;
	public const uint32 DIBUTTON_FIGHTINGH_DEVICE = 134235390;
	public const uint32 DIBUTTON_FIGHTINGH_PAUSE = 134235388;
	public const uint32 DIVIRTUAL_FIGHTING_FPS = 150994944;
	public const uint32 DIAXIS_FPS_ROTATE = 151028225;
	public const uint32 DIAXIS_FPS_MOVE = 151060994;
	public const uint32 DIBUTTON_FPS_FIRE = 150995969;
	public const uint32 DIBUTTON_FPS_WEAPONS = 150995970;
	public const uint32 DIBUTTON_FPS_APPLY = 150995971;
	public const uint32 DIBUTTON_FPS_SELECT = 150995972;
	public const uint32 DIBUTTON_FPS_CROUCH = 150995973;
	public const uint32 DIBUTTON_FPS_JUMP = 150995974;
	public const uint32 DIAXIS_FPS_LOOKUPDOWN = 151093763;
	public const uint32 DIBUTTON_FPS_STRAFE = 150995975;
	public const uint32 DIBUTTON_FPS_MENU = 150996221;
	public const uint32 DIHATSWITCH_FPS_GLANCE = 151012865;
	public const uint32 DIBUTTON_FPS_DISPLAY = 151012360;
	public const uint32 DIAXIS_FPS_SIDESTEP = 151142916;
	public const uint32 DIBUTTON_FPS_DODGE = 151012361;
	public const uint32 DIBUTTON_FPS_GLANCEL = 151012362;
	public const uint32 DIBUTTON_FPS_GLANCER = 151012363;
	public const uint32 DIBUTTON_FPS_FIRESECONDARY = 151012364;
	public const uint32 DIBUTTON_FPS_ROTATE_LEFT_LINK = 151045348;
	public const uint32 DIBUTTON_FPS_ROTATE_RIGHT_LINK = 151045356;
	public const uint32 DIBUTTON_FPS_FORWARD_LINK = 151078112;
	public const uint32 DIBUTTON_FPS_BACKWARD_LINK = 151078120;
	public const uint32 DIBUTTON_FPS_GLANCE_UP_LINK = 151110880;
	public const uint32 DIBUTTON_FPS_GLANCE_DOWN_LINK = 151110888;
	public const uint32 DIBUTTON_FPS_STEP_LEFT_LINK = 151143652;
	public const uint32 DIBUTTON_FPS_STEP_RIGHT_LINK = 151143660;
	public const uint32 DIBUTTON_FPS_DEVICE = 151012606;
	public const uint32 DIBUTTON_FPS_PAUSE = 151012604;
	public const uint32 DIVIRTUAL_FIGHTING_THIRDPERSON = 167772160;
	public const uint32 DIAXIS_TPS_TURN = 167903745;
	public const uint32 DIAXIS_TPS_MOVE = 167838210;
	public const uint32 DIBUTTON_TPS_RUN = 167773185;
	public const uint32 DIBUTTON_TPS_ACTION = 167773186;
	public const uint32 DIBUTTON_TPS_SELECT = 167773187;
	public const uint32 DIBUTTON_TPS_USE = 167773188;
	public const uint32 DIBUTTON_TPS_JUMP = 167773189;
	public const uint32 DIBUTTON_TPS_MENU = 167773437;
	public const uint32 DIHATSWITCH_TPS_GLANCE = 167790081;
	public const uint32 DIBUTTON_TPS_VIEW = 167789574;
	public const uint32 DIBUTTON_TPS_STEPLEFT = 167789575;
	public const uint32 DIBUTTON_TPS_STEPRIGHT = 167789576;
	public const uint32 DIAXIS_TPS_STEP = 167821827;
	public const uint32 DIBUTTON_TPS_DODGE = 167789577;
	public const uint32 DIBUTTON_TPS_INVENTORY = 167789578;
	public const uint32 DIBUTTON_TPS_TURN_LEFT_LINK = 167920868;
	public const uint32 DIBUTTON_TPS_TURN_RIGHT_LINK = 167920876;
	public const uint32 DIBUTTON_TPS_FORWARD_LINK = 167855328;
	public const uint32 DIBUTTON_TPS_BACKWARD_LINK = 167855336;
	public const uint32 DIBUTTON_TPS_GLANCE_UP_LINK = 168281312;
	public const uint32 DIBUTTON_TPS_GLANCE_DOWN_LINK = 168281320;
	public const uint32 DIBUTTON_TPS_GLANCE_LEFT_LINK = 168281316;
	public const uint32 DIBUTTON_TPS_GLANCE_RIGHT_LINK = 168281324;
	public const uint32 DIBUTTON_TPS_DEVICE = 167789822;
	public const uint32 DIBUTTON_TPS_PAUSE = 167789820;
	public const uint32 DIVIRTUAL_STRATEGY_ROLEPLAYING = 184549376;
	public const uint32 DIAXIS_STRATEGYR_LATERAL = 184582657;
	public const uint32 DIAXIS_STRATEGYR_MOVE = 184615426;
	public const uint32 DIBUTTON_STRATEGYR_GET = 184550401;
	public const uint32 DIBUTTON_STRATEGYR_APPLY = 184550402;
	public const uint32 DIBUTTON_STRATEGYR_SELECT = 184550403;
	public const uint32 DIBUTTON_STRATEGYR_ATTACK = 184550404;
	public const uint32 DIBUTTON_STRATEGYR_CAST = 184550405;
	public const uint32 DIBUTTON_STRATEGYR_CROUCH = 184550406;
	public const uint32 DIBUTTON_STRATEGYR_JUMP = 184550407;
	public const uint32 DIBUTTON_STRATEGYR_MENU = 184550653;
	public const uint32 DIHATSWITCH_STRATEGYR_GLANCE = 184567297;
	public const uint32 DIBUTTON_STRATEGYR_MAP = 184566792;
	public const uint32 DIBUTTON_STRATEGYR_DISPLAY = 184566793;
	public const uint32 DIAXIS_STRATEGYR_ROTATE = 184697347;
	public const uint32 DIBUTTON_STRATEGYR_LEFT_LINK = 184599780;
	public const uint32 DIBUTTON_STRATEGYR_RIGHT_LINK = 184599788;
	public const uint32 DIBUTTON_STRATEGYR_FORWARD_LINK = 184632544;
	public const uint32 DIBUTTON_STRATEGYR_BACK_LINK = 184632552;
	public const uint32 DIBUTTON_STRATEGYR_ROTATE_LEFT_LINK = 184698084;
	public const uint32 DIBUTTON_STRATEGYR_ROTATE_RIGHT_LINK = 184698092;
	public const uint32 DIBUTTON_STRATEGYR_DEVICE = 184567038;
	public const uint32 DIBUTTON_STRATEGYR_PAUSE = 184567036;
	public const uint32 DIVIRTUAL_STRATEGY_TURN = 201326592;
	public const uint32 DIAXIS_STRATEGYT_LATERAL = 201359873;
	public const uint32 DIAXIS_STRATEGYT_MOVE = 201392642;
	public const uint32 DIBUTTON_STRATEGYT_SELECT = 201327617;
	public const uint32 DIBUTTON_STRATEGYT_INSTRUCT = 201327618;
	public const uint32 DIBUTTON_STRATEGYT_APPLY = 201327619;
	public const uint32 DIBUTTON_STRATEGYT_TEAM = 201327620;
	public const uint32 DIBUTTON_STRATEGYT_TURN = 201327621;
	public const uint32 DIBUTTON_STRATEGYT_MENU = 201327869;
	public const uint32 DIBUTTON_STRATEGYT_ZOOM = 201344006;
	public const uint32 DIBUTTON_STRATEGYT_MAP = 201344007;
	public const uint32 DIBUTTON_STRATEGYT_DISPLAY = 201344008;
	public const uint32 DIBUTTON_STRATEGYT_LEFT_LINK = 201376996;
	public const uint32 DIBUTTON_STRATEGYT_RIGHT_LINK = 201377004;
	public const uint32 DIBUTTON_STRATEGYT_FORWARD_LINK = 201409760;
	public const uint32 DIBUTTON_STRATEGYT_BACK_LINK = 201409768;
	public const uint32 DIBUTTON_STRATEGYT_DEVICE = 201344254;
	public const uint32 DIBUTTON_STRATEGYT_PAUSE = 201344252;
	public const uint32 DIVIRTUAL_SPORTS_HUNTING = 218103808;
	public const uint32 DIAXIS_HUNTING_LATERAL = 218137089;
	public const uint32 DIAXIS_HUNTING_MOVE = 218169858;
	public const uint32 DIBUTTON_HUNTING_FIRE = 218104833;
	public const uint32 DIBUTTON_HUNTING_AIM = 218104834;
	public const uint32 DIBUTTON_HUNTING_WEAPON = 218104835;
	public const uint32 DIBUTTON_HUNTING_BINOCULAR = 218104836;
	public const uint32 DIBUTTON_HUNTING_CALL = 218104837;
	public const uint32 DIBUTTON_HUNTING_MAP = 218104838;
	public const uint32 DIBUTTON_HUNTING_SPECIAL = 218104839;
	public const uint32 DIBUTTON_HUNTING_MENU = 218105085;
	public const uint32 DIHATSWITCH_HUNTING_GLANCE = 218121729;
	public const uint32 DIBUTTON_HUNTING_DISPLAY = 218121224;
	public const uint32 DIAXIS_HUNTING_ROTATE = 218251779;
	public const uint32 DIBUTTON_HUNTING_CROUCH = 218121225;
	public const uint32 DIBUTTON_HUNTING_JUMP = 218121226;
	public const uint32 DIBUTTON_HUNTING_FIRESECONDARY = 218121227;
	public const uint32 DIBUTTON_HUNTING_LEFT_LINK = 218154212;
	public const uint32 DIBUTTON_HUNTING_RIGHT_LINK = 218154220;
	public const uint32 DIBUTTON_HUNTING_FORWARD_LINK = 218186976;
	public const uint32 DIBUTTON_HUNTING_BACK_LINK = 218186984;
	public const uint32 DIBUTTON_HUNTING_ROTATE_LEFT_LINK = 218252516;
	public const uint32 DIBUTTON_HUNTING_ROTATE_RIGHT_LINK = 218252524;
	public const uint32 DIBUTTON_HUNTING_DEVICE = 218121470;
	public const uint32 DIBUTTON_HUNTING_PAUSE = 218121468;
	public const uint32 DIVIRTUAL_SPORTS_FISHING = 234881024;
	public const uint32 DIAXIS_FISHING_LATERAL = 234914305;
	public const uint32 DIAXIS_FISHING_MOVE = 234947074;
	public const uint32 DIBUTTON_FISHING_CAST = 234882049;
	public const uint32 DIBUTTON_FISHING_TYPE = 234882050;
	public const uint32 DIBUTTON_FISHING_BINOCULAR = 234882051;
	public const uint32 DIBUTTON_FISHING_BAIT = 234882052;
	public const uint32 DIBUTTON_FISHING_MAP = 234882053;
	public const uint32 DIBUTTON_FISHING_MENU = 234882301;
	public const uint32 DIHATSWITCH_FISHING_GLANCE = 234898945;
	public const uint32 DIBUTTON_FISHING_DISPLAY = 234898438;
	public const uint32 DIAXIS_FISHING_ROTATE = 235028995;
	public const uint32 DIBUTTON_FISHING_CROUCH = 234898439;
	public const uint32 DIBUTTON_FISHING_JUMP = 234898440;
	public const uint32 DIBUTTON_FISHING_LEFT_LINK = 234931428;
	public const uint32 DIBUTTON_FISHING_RIGHT_LINK = 234931436;
	public const uint32 DIBUTTON_FISHING_FORWARD_LINK = 234964192;
	public const uint32 DIBUTTON_FISHING_BACK_LINK = 234964200;
	public const uint32 DIBUTTON_FISHING_ROTATE_LEFT_LINK = 235029732;
	public const uint32 DIBUTTON_FISHING_ROTATE_RIGHT_LINK = 235029740;
	public const uint32 DIBUTTON_FISHING_DEVICE = 234898686;
	public const uint32 DIBUTTON_FISHING_PAUSE = 234898684;
	public const uint32 DIVIRTUAL_SPORTS_BASEBALL_BAT = 251658240;
	public const uint32 DIAXIS_BASEBALLB_LATERAL = 251691521;
	public const uint32 DIAXIS_BASEBALLB_MOVE = 251724290;
	public const uint32 DIBUTTON_BASEBALLB_SELECT = 251659265;
	public const uint32 DIBUTTON_BASEBALLB_NORMAL = 251659266;
	public const uint32 DIBUTTON_BASEBALLB_POWER = 251659267;
	public const uint32 DIBUTTON_BASEBALLB_BUNT = 251659268;
	public const uint32 DIBUTTON_BASEBALLB_STEAL = 251659269;
	public const uint32 DIBUTTON_BASEBALLB_BURST = 251659270;
	public const uint32 DIBUTTON_BASEBALLB_SLIDE = 251659271;
	public const uint32 DIBUTTON_BASEBALLB_CONTACT = 251659272;
	public const uint32 DIBUTTON_BASEBALLB_MENU = 251659517;
	public const uint32 DIBUTTON_BASEBALLB_NOSTEAL = 251675657;
	public const uint32 DIBUTTON_BASEBALLB_BOX = 251675658;
	public const uint32 DIBUTTON_BASEBALLB_LEFT_LINK = 251708644;
	public const uint32 DIBUTTON_BASEBALLB_RIGHT_LINK = 251708652;
	public const uint32 DIBUTTON_BASEBALLB_FORWARD_LINK = 251741408;
	public const uint32 DIBUTTON_BASEBALLB_BACK_LINK = 251741416;
	public const uint32 DIBUTTON_BASEBALLB_DEVICE = 251675902;
	public const uint32 DIBUTTON_BASEBALLB_PAUSE = 251675900;
	public const uint32 DIVIRTUAL_SPORTS_BASEBALL_PITCH = 268435456;
	public const uint32 DIAXIS_BASEBALLP_LATERAL = 268468737;
	public const uint32 DIAXIS_BASEBALLP_MOVE = 268501506;
	public const uint32 DIBUTTON_BASEBALLP_SELECT = 268436481;
	public const uint32 DIBUTTON_BASEBALLP_PITCH = 268436482;
	public const uint32 DIBUTTON_BASEBALLP_BASE = 268436483;
	public const uint32 DIBUTTON_BASEBALLP_THROW = 268436484;
	public const uint32 DIBUTTON_BASEBALLP_FAKE = 268436485;
	public const uint32 DIBUTTON_BASEBALLP_MENU = 268436733;
	public const uint32 DIBUTTON_BASEBALLP_WALK = 268452870;
	public const uint32 DIBUTTON_BASEBALLP_LOOK = 268452871;
	public const uint32 DIBUTTON_BASEBALLP_LEFT_LINK = 268485860;
	public const uint32 DIBUTTON_BASEBALLP_RIGHT_LINK = 268485868;
	public const uint32 DIBUTTON_BASEBALLP_FORWARD_LINK = 268518624;
	public const uint32 DIBUTTON_BASEBALLP_BACK_LINK = 268518632;
	public const uint32 DIBUTTON_BASEBALLP_DEVICE = 268453118;
	public const uint32 DIBUTTON_BASEBALLP_PAUSE = 268453116;
	public const uint32 DIVIRTUAL_SPORTS_BASEBALL_FIELD = 285212672;
	public const uint32 DIAXIS_BASEBALLF_LATERAL = 285245953;
	public const uint32 DIAXIS_BASEBALLF_MOVE = 285278722;
	public const uint32 DIBUTTON_BASEBALLF_NEAREST = 285213697;
	public const uint32 DIBUTTON_BASEBALLF_THROW1 = 285213698;
	public const uint32 DIBUTTON_BASEBALLF_THROW2 = 285213699;
	public const uint32 DIBUTTON_BASEBALLF_BURST = 285213700;
	public const uint32 DIBUTTON_BASEBALLF_JUMP = 285213701;
	public const uint32 DIBUTTON_BASEBALLF_DIVE = 285213702;
	public const uint32 DIBUTTON_BASEBALLF_MENU = 285213949;
	public const uint32 DIBUTTON_BASEBALLF_SHIFTIN = 285230087;
	public const uint32 DIBUTTON_BASEBALLF_SHIFTOUT = 285230088;
	public const uint32 DIBUTTON_BASEBALLF_AIM_LEFT_LINK = 285263076;
	public const uint32 DIBUTTON_BASEBALLF_AIM_RIGHT_LINK = 285263084;
	public const uint32 DIBUTTON_BASEBALLF_FORWARD_LINK = 285295840;
	public const uint32 DIBUTTON_BASEBALLF_BACK_LINK = 285295848;
	public const uint32 DIBUTTON_BASEBALLF_DEVICE = 285230334;
	public const uint32 DIBUTTON_BASEBALLF_PAUSE = 285230332;
	public const uint32 DIVIRTUAL_SPORTS_BASKETBALL_OFFENSE = 301989888;
	public const uint32 DIAXIS_BBALLO_LATERAL = 302023169;
	public const uint32 DIAXIS_BBALLO_MOVE = 302055938;
	public const uint32 DIBUTTON_BBALLO_SHOOT = 301990913;
	public const uint32 DIBUTTON_BBALLO_DUNK = 301990914;
	public const uint32 DIBUTTON_BBALLO_PASS = 301990915;
	public const uint32 DIBUTTON_BBALLO_FAKE = 301990916;
	public const uint32 DIBUTTON_BBALLO_SPECIAL = 301990917;
	public const uint32 DIBUTTON_BBALLO_PLAYER = 301990918;
	public const uint32 DIBUTTON_BBALLO_BURST = 301990919;
	public const uint32 DIBUTTON_BBALLO_CALL = 301990920;
	public const uint32 DIBUTTON_BBALLO_MENU = 301991165;
	public const uint32 DIHATSWITCH_BBALLO_GLANCE = 302007809;
	public const uint32 DIBUTTON_BBALLO_SCREEN = 302007305;
	public const uint32 DIBUTTON_BBALLO_PLAY = 302007306;
	public const uint32 DIBUTTON_BBALLO_JAB = 302007307;
	public const uint32 DIBUTTON_BBALLO_POST = 302007308;
	public const uint32 DIBUTTON_BBALLO_TIMEOUT = 302007309;
	public const uint32 DIBUTTON_BBALLO_SUBSTITUTE = 302007310;
	public const uint32 DIBUTTON_BBALLO_LEFT_LINK = 302040292;
	public const uint32 DIBUTTON_BBALLO_RIGHT_LINK = 302040300;
	public const uint32 DIBUTTON_BBALLO_FORWARD_LINK = 302073056;
	public const uint32 DIBUTTON_BBALLO_BACK_LINK = 302073064;
	public const uint32 DIBUTTON_BBALLO_DEVICE = 302007550;
	public const uint32 DIBUTTON_BBALLO_PAUSE = 302007548;
	public const uint32 DIVIRTUAL_SPORTS_BASKETBALL_DEFENSE = 318767104;
	public const uint32 DIAXIS_BBALLD_LATERAL = 318800385;
	public const uint32 DIAXIS_BBALLD_MOVE = 318833154;
	public const uint32 DIBUTTON_BBALLD_JUMP = 318768129;
	public const uint32 DIBUTTON_BBALLD_STEAL = 318768130;
	public const uint32 DIBUTTON_BBALLD_FAKE = 318768131;
	public const uint32 DIBUTTON_BBALLD_SPECIAL = 318768132;
	public const uint32 DIBUTTON_BBALLD_PLAYER = 318768133;
	public const uint32 DIBUTTON_BBALLD_BURST = 318768134;
	public const uint32 DIBUTTON_BBALLD_PLAY = 318768135;
	public const uint32 DIBUTTON_BBALLD_MENU = 318768381;
	public const uint32 DIHATSWITCH_BBALLD_GLANCE = 318785025;
	public const uint32 DIBUTTON_BBALLD_TIMEOUT = 318784520;
	public const uint32 DIBUTTON_BBALLD_SUBSTITUTE = 318784521;
	public const uint32 DIBUTTON_BBALLD_LEFT_LINK = 318817508;
	public const uint32 DIBUTTON_BBALLD_RIGHT_LINK = 318817516;
	public const uint32 DIBUTTON_BBALLD_FORWARD_LINK = 318850272;
	public const uint32 DIBUTTON_BBALLD_BACK_LINK = 318850280;
	public const uint32 DIBUTTON_BBALLD_DEVICE = 318784766;
	public const uint32 DIBUTTON_BBALLD_PAUSE = 318784764;
	public const uint32 DIVIRTUAL_SPORTS_FOOTBALL_FIELD = 335544320;
	public const uint32 DIBUTTON_FOOTBALLP_PLAY = 335545345;
	public const uint32 DIBUTTON_FOOTBALLP_SELECT = 335545346;
	public const uint32 DIBUTTON_FOOTBALLP_HELP = 335545347;
	public const uint32 DIBUTTON_FOOTBALLP_MENU = 335545597;
	public const uint32 DIBUTTON_FOOTBALLP_DEVICE = 335561982;
	public const uint32 DIBUTTON_FOOTBALLP_PAUSE = 335561980;
	public const uint32 DIVIRTUAL_SPORTS_FOOTBALL_QBCK = 352321536;
	public const uint32 DIAXIS_FOOTBALLQ_LATERAL = 352354817;
	public const uint32 DIAXIS_FOOTBALLQ_MOVE = 352387586;
	public const uint32 DIBUTTON_FOOTBALLQ_SELECT = 352322561;
	public const uint32 DIBUTTON_FOOTBALLQ_SNAP = 352322562;
	public const uint32 DIBUTTON_FOOTBALLQ_JUMP = 352322563;
	public const uint32 DIBUTTON_FOOTBALLQ_SLIDE = 352322564;
	public const uint32 DIBUTTON_FOOTBALLQ_PASS = 352322565;
	public const uint32 DIBUTTON_FOOTBALLQ_FAKE = 352322566;
	public const uint32 DIBUTTON_FOOTBALLQ_MENU = 352322813;
	public const uint32 DIBUTTON_FOOTBALLQ_FAKESNAP = 352338951;
	public const uint32 DIBUTTON_FOOTBALLQ_MOTION = 352338952;
	public const uint32 DIBUTTON_FOOTBALLQ_AUDIBLE = 352338953;
	public const uint32 DIBUTTON_FOOTBALLQ_LEFT_LINK = 352371940;
	public const uint32 DIBUTTON_FOOTBALLQ_RIGHT_LINK = 352371948;
	public const uint32 DIBUTTON_FOOTBALLQ_FORWARD_LINK = 352404704;
	public const uint32 DIBUTTON_FOOTBALLQ_BACK_LINK = 352404712;
	public const uint32 DIBUTTON_FOOTBALLQ_DEVICE = 352339198;
	public const uint32 DIBUTTON_FOOTBALLQ_PAUSE = 352339196;
	public const uint32 DIVIRTUAL_SPORTS_FOOTBALL_OFFENSE = 369098752;
	public const uint32 DIAXIS_FOOTBALLO_LATERAL = 369132033;
	public const uint32 DIAXIS_FOOTBALLO_MOVE = 369164802;
	public const uint32 DIBUTTON_FOOTBALLO_JUMP = 369099777;
	public const uint32 DIBUTTON_FOOTBALLO_LEFTARM = 369099778;
	public const uint32 DIBUTTON_FOOTBALLO_RIGHTARM = 369099779;
	public const uint32 DIBUTTON_FOOTBALLO_THROW = 369099780;
	public const uint32 DIBUTTON_FOOTBALLO_SPIN = 369099781;
	public const uint32 DIBUTTON_FOOTBALLO_MENU = 369100029;
	public const uint32 DIBUTTON_FOOTBALLO_JUKE = 369116166;
	public const uint32 DIBUTTON_FOOTBALLO_SHOULDER = 369116167;
	public const uint32 DIBUTTON_FOOTBALLO_TURBO = 369116168;
	public const uint32 DIBUTTON_FOOTBALLO_DIVE = 369116169;
	public const uint32 DIBUTTON_FOOTBALLO_ZOOM = 369116170;
	public const uint32 DIBUTTON_FOOTBALLO_SUBSTITUTE = 369116171;
	public const uint32 DIBUTTON_FOOTBALLO_LEFT_LINK = 369149156;
	public const uint32 DIBUTTON_FOOTBALLO_RIGHT_LINK = 369149164;
	public const uint32 DIBUTTON_FOOTBALLO_FORWARD_LINK = 369181920;
	public const uint32 DIBUTTON_FOOTBALLO_BACK_LINK = 369181928;
	public const uint32 DIBUTTON_FOOTBALLO_DEVICE = 369116414;
	public const uint32 DIBUTTON_FOOTBALLO_PAUSE = 369116412;
	public const uint32 DIVIRTUAL_SPORTS_FOOTBALL_DEFENSE = 385875968;
	public const uint32 DIAXIS_FOOTBALLD_LATERAL = 385909249;
	public const uint32 DIAXIS_FOOTBALLD_MOVE = 385942018;
	public const uint32 DIBUTTON_FOOTBALLD_PLAY = 385876993;
	public const uint32 DIBUTTON_FOOTBALLD_SELECT = 385876994;
	public const uint32 DIBUTTON_FOOTBALLD_JUMP = 385876995;
	public const uint32 DIBUTTON_FOOTBALLD_TACKLE = 385876996;
	public const uint32 DIBUTTON_FOOTBALLD_FAKE = 385876997;
	public const uint32 DIBUTTON_FOOTBALLD_SUPERTACKLE = 385876998;
	public const uint32 DIBUTTON_FOOTBALLD_MENU = 385877245;
	public const uint32 DIBUTTON_FOOTBALLD_SPIN = 385893383;
	public const uint32 DIBUTTON_FOOTBALLD_SWIM = 385893384;
	public const uint32 DIBUTTON_FOOTBALLD_BULLRUSH = 385893385;
	public const uint32 DIBUTTON_FOOTBALLD_RIP = 385893386;
	public const uint32 DIBUTTON_FOOTBALLD_AUDIBLE = 385893387;
	public const uint32 DIBUTTON_FOOTBALLD_ZOOM = 385893388;
	public const uint32 DIBUTTON_FOOTBALLD_SUBSTITUTE = 385893389;
	public const uint32 DIBUTTON_FOOTBALLD_LEFT_LINK = 385926372;
	public const uint32 DIBUTTON_FOOTBALLD_RIGHT_LINK = 385926380;
	public const uint32 DIBUTTON_FOOTBALLD_FORWARD_LINK = 385959136;
	public const uint32 DIBUTTON_FOOTBALLD_BACK_LINK = 385959144;
	public const uint32 DIBUTTON_FOOTBALLD_DEVICE = 385893630;
	public const uint32 DIBUTTON_FOOTBALLD_PAUSE = 385893628;
	public const uint32 DIVIRTUAL_SPORTS_GOLF = 402653184;
	public const uint32 DIAXIS_GOLF_LATERAL = 402686465;
	public const uint32 DIAXIS_GOLF_MOVE = 402719234;
	public const uint32 DIBUTTON_GOLF_SWING = 402654209;
	public const uint32 DIBUTTON_GOLF_SELECT = 402654210;
	public const uint32 DIBUTTON_GOLF_UP = 402654211;
	public const uint32 DIBUTTON_GOLF_DOWN = 402654212;
	public const uint32 DIBUTTON_GOLF_TERRAIN = 402654213;
	public const uint32 DIBUTTON_GOLF_FLYBY = 402654214;
	public const uint32 DIBUTTON_GOLF_MENU = 402654461;
	public const uint32 DIHATSWITCH_GOLF_SCROLL = 402671105;
	public const uint32 DIBUTTON_GOLF_ZOOM = 402670599;
	public const uint32 DIBUTTON_GOLF_TIMEOUT = 402670600;
	public const uint32 DIBUTTON_GOLF_SUBSTITUTE = 402670601;
	public const uint32 DIBUTTON_GOLF_LEFT_LINK = 402703588;
	public const uint32 DIBUTTON_GOLF_RIGHT_LINK = 402703596;
	public const uint32 DIBUTTON_GOLF_FORWARD_LINK = 402736352;
	public const uint32 DIBUTTON_GOLF_BACK_LINK = 402736360;
	public const uint32 DIBUTTON_GOLF_DEVICE = 402670846;
	public const uint32 DIBUTTON_GOLF_PAUSE = 402670844;
	public const uint32 DIVIRTUAL_SPORTS_HOCKEY_OFFENSE = 419430400;
	public const uint32 DIAXIS_HOCKEYO_LATERAL = 419463681;
	public const uint32 DIAXIS_HOCKEYO_MOVE = 419496450;
	public const uint32 DIBUTTON_HOCKEYO_SHOOT = 419431425;
	public const uint32 DIBUTTON_HOCKEYO_PASS = 419431426;
	public const uint32 DIBUTTON_HOCKEYO_BURST = 419431427;
	public const uint32 DIBUTTON_HOCKEYO_SPECIAL = 419431428;
	public const uint32 DIBUTTON_HOCKEYO_FAKE = 419431429;
	public const uint32 DIBUTTON_HOCKEYO_MENU = 419431677;
	public const uint32 DIHATSWITCH_HOCKEYO_SCROLL = 419448321;
	public const uint32 DIBUTTON_HOCKEYO_ZOOM = 419447814;
	public const uint32 DIBUTTON_HOCKEYO_STRATEGY = 419447815;
	public const uint32 DIBUTTON_HOCKEYO_TIMEOUT = 419447816;
	public const uint32 DIBUTTON_HOCKEYO_SUBSTITUTE = 419447817;
	public const uint32 DIBUTTON_HOCKEYO_LEFT_LINK = 419480804;
	public const uint32 DIBUTTON_HOCKEYO_RIGHT_LINK = 419480812;
	public const uint32 DIBUTTON_HOCKEYO_FORWARD_LINK = 419513568;
	public const uint32 DIBUTTON_HOCKEYO_BACK_LINK = 419513576;
	public const uint32 DIBUTTON_HOCKEYO_DEVICE = 419448062;
	public const uint32 DIBUTTON_HOCKEYO_PAUSE = 419448060;
	public const uint32 DIVIRTUAL_SPORTS_HOCKEY_DEFENSE = 436207616;
	public const uint32 DIAXIS_HOCKEYD_LATERAL = 436240897;
	public const uint32 DIAXIS_HOCKEYD_MOVE = 436273666;
	public const uint32 DIBUTTON_HOCKEYD_PLAYER = 436208641;
	public const uint32 DIBUTTON_HOCKEYD_STEAL = 436208642;
	public const uint32 DIBUTTON_HOCKEYD_BURST = 436208643;
	public const uint32 DIBUTTON_HOCKEYD_BLOCK = 436208644;
	public const uint32 DIBUTTON_HOCKEYD_FAKE = 436208645;
	public const uint32 DIBUTTON_HOCKEYD_MENU = 436208893;
	public const uint32 DIHATSWITCH_HOCKEYD_SCROLL = 436225537;
	public const uint32 DIBUTTON_HOCKEYD_ZOOM = 436225030;
	public const uint32 DIBUTTON_HOCKEYD_STRATEGY = 436225031;
	public const uint32 DIBUTTON_HOCKEYD_TIMEOUT = 436225032;
	public const uint32 DIBUTTON_HOCKEYD_SUBSTITUTE = 436225033;
	public const uint32 DIBUTTON_HOCKEYD_LEFT_LINK = 436258020;
	public const uint32 DIBUTTON_HOCKEYD_RIGHT_LINK = 436258028;
	public const uint32 DIBUTTON_HOCKEYD_FORWARD_LINK = 436290784;
	public const uint32 DIBUTTON_HOCKEYD_BACK_LINK = 436290792;
	public const uint32 DIBUTTON_HOCKEYD_DEVICE = 436225278;
	public const uint32 DIBUTTON_HOCKEYD_PAUSE = 436225276;
	public const uint32 DIVIRTUAL_SPORTS_HOCKEY_GOALIE = 452984832;
	public const uint32 DIAXIS_HOCKEYG_LATERAL = 453018113;
	public const uint32 DIAXIS_HOCKEYG_MOVE = 453050882;
	public const uint32 DIBUTTON_HOCKEYG_PASS = 452985857;
	public const uint32 DIBUTTON_HOCKEYG_POKE = 452985858;
	public const uint32 DIBUTTON_HOCKEYG_STEAL = 452985859;
	public const uint32 DIBUTTON_HOCKEYG_BLOCK = 452985860;
	public const uint32 DIBUTTON_HOCKEYG_MENU = 452986109;
	public const uint32 DIHATSWITCH_HOCKEYG_SCROLL = 453002753;
	public const uint32 DIBUTTON_HOCKEYG_ZOOM = 453002245;
	public const uint32 DIBUTTON_HOCKEYG_STRATEGY = 453002246;
	public const uint32 DIBUTTON_HOCKEYG_TIMEOUT = 453002247;
	public const uint32 DIBUTTON_HOCKEYG_SUBSTITUTE = 453002248;
	public const uint32 DIBUTTON_HOCKEYG_LEFT_LINK = 453035236;
	public const uint32 DIBUTTON_HOCKEYG_RIGHT_LINK = 453035244;
	public const uint32 DIBUTTON_HOCKEYG_FORWARD_LINK = 453068000;
	public const uint32 DIBUTTON_HOCKEYG_BACK_LINK = 453068008;
	public const uint32 DIBUTTON_HOCKEYG_DEVICE = 453002494;
	public const uint32 DIBUTTON_HOCKEYG_PAUSE = 453002492;
	public const uint32 DIVIRTUAL_SPORTS_BIKING_MOUNTAIN = 469762048;
	public const uint32 DIAXIS_BIKINGM_TURN = 469795329;
	public const uint32 DIAXIS_BIKINGM_PEDAL = 469828098;
	public const uint32 DIBUTTON_BIKINGM_JUMP = 469763073;
	public const uint32 DIBUTTON_BIKINGM_CAMERA = 469763074;
	public const uint32 DIBUTTON_BIKINGM_SPECIAL1 = 469763075;
	public const uint32 DIBUTTON_BIKINGM_SELECT = 469763076;
	public const uint32 DIBUTTON_BIKINGM_SPECIAL2 = 469763077;
	public const uint32 DIBUTTON_BIKINGM_MENU = 469763325;
	public const uint32 DIHATSWITCH_BIKINGM_SCROLL = 469779969;
	public const uint32 DIBUTTON_BIKINGM_ZOOM = 469779462;
	public const uint32 DIAXIS_BIKINGM_BRAKE = 470041091;
	public const uint32 DIBUTTON_BIKINGM_LEFT_LINK = 469812452;
	public const uint32 DIBUTTON_BIKINGM_RIGHT_LINK = 469812460;
	public const uint32 DIBUTTON_BIKINGM_FASTER_LINK = 469845216;
	public const uint32 DIBUTTON_BIKINGM_SLOWER_LINK = 469845224;
	public const uint32 DIBUTTON_BIKINGM_BRAKE_BUTTON_LINK = 470041832;
	public const uint32 DIBUTTON_BIKINGM_DEVICE = 469779710;
	public const uint32 DIBUTTON_BIKINGM_PAUSE = 469779708;
	public const uint32 DIVIRTUAL_SPORTS_SKIING = 486539264;
	public const uint32 DIAXIS_SKIING_TURN = 486572545;
	public const uint32 DIAXIS_SKIING_SPEED = 486605314;
	public const uint32 DIBUTTON_SKIING_JUMP = 486540289;
	public const uint32 DIBUTTON_SKIING_CROUCH = 486540290;
	public const uint32 DIBUTTON_SKIING_CAMERA = 486540291;
	public const uint32 DIBUTTON_SKIING_SPECIAL1 = 486540292;
	public const uint32 DIBUTTON_SKIING_SELECT = 486540293;
	public const uint32 DIBUTTON_SKIING_SPECIAL2 = 486540294;
	public const uint32 DIBUTTON_SKIING_MENU = 486540541;
	public const uint32 DIHATSWITCH_SKIING_GLANCE = 486557185;
	public const uint32 DIBUTTON_SKIING_ZOOM = 486556679;
	public const uint32 DIBUTTON_SKIING_LEFT_LINK = 486589668;
	public const uint32 DIBUTTON_SKIING_RIGHT_LINK = 486589676;
	public const uint32 DIBUTTON_SKIING_FASTER_LINK = 486622432;
	public const uint32 DIBUTTON_SKIING_SLOWER_LINK = 486622440;
	public const uint32 DIBUTTON_SKIING_DEVICE = 486556926;
	public const uint32 DIBUTTON_SKIING_PAUSE = 486556924;
	public const uint32 DIVIRTUAL_SPORTS_SOCCER_OFFENSE = 503316480;
	public const uint32 DIAXIS_SOCCERO_LATERAL = 503349761;
	public const uint32 DIAXIS_SOCCERO_MOVE = 503382530;
	public const uint32 DIAXIS_SOCCERO_BEND = 503415299;
	public const uint32 DIBUTTON_SOCCERO_SHOOT = 503317505;
	public const uint32 DIBUTTON_SOCCERO_PASS = 503317506;
	public const uint32 DIBUTTON_SOCCERO_FAKE = 503317507;
	public const uint32 DIBUTTON_SOCCERO_PLAYER = 503317508;
	public const uint32 DIBUTTON_SOCCERO_SPECIAL1 = 503317509;
	public const uint32 DIBUTTON_SOCCERO_SELECT = 503317510;
	public const uint32 DIBUTTON_SOCCERO_MENU = 503317757;
	public const uint32 DIHATSWITCH_SOCCERO_GLANCE = 503334401;
	public const uint32 DIBUTTON_SOCCERO_SUBSTITUTE = 503333895;
	public const uint32 DIBUTTON_SOCCERO_SHOOTLOW = 503333896;
	public const uint32 DIBUTTON_SOCCERO_SHOOTHIGH = 503333897;
	public const uint32 DIBUTTON_SOCCERO_PASSTHRU = 503333898;
	public const uint32 DIBUTTON_SOCCERO_SPRINT = 503333899;
	public const uint32 DIBUTTON_SOCCERO_CONTROL = 503333900;
	public const uint32 DIBUTTON_SOCCERO_HEAD = 503333901;
	public const uint32 DIBUTTON_SOCCERO_LEFT_LINK = 503366884;
	public const uint32 DIBUTTON_SOCCERO_RIGHT_LINK = 503366892;
	public const uint32 DIBUTTON_SOCCERO_FORWARD_LINK = 503399648;
	public const uint32 DIBUTTON_SOCCERO_BACK_LINK = 503399656;
	public const uint32 DIBUTTON_SOCCERO_DEVICE = 503334142;
	public const uint32 DIBUTTON_SOCCERO_PAUSE = 503334140;
	public const uint32 DIVIRTUAL_SPORTS_SOCCER_DEFENSE = 520093696;
	public const uint32 DIAXIS_SOCCERD_LATERAL = 520126977;
	public const uint32 DIAXIS_SOCCERD_MOVE = 520159746;
	public const uint32 DIBUTTON_SOCCERD_BLOCK = 520094721;
	public const uint32 DIBUTTON_SOCCERD_STEAL = 520094722;
	public const uint32 DIBUTTON_SOCCERD_FAKE = 520094723;
	public const uint32 DIBUTTON_SOCCERD_PLAYER = 520094724;
	public const uint32 DIBUTTON_SOCCERD_SPECIAL = 520094725;
	public const uint32 DIBUTTON_SOCCERD_SELECT = 520094726;
	public const uint32 DIBUTTON_SOCCERD_SLIDE = 520094727;
	public const uint32 DIBUTTON_SOCCERD_MENU = 520094973;
	public const uint32 DIHATSWITCH_SOCCERD_GLANCE = 520111617;
	public const uint32 DIBUTTON_SOCCERD_FOUL = 520111112;
	public const uint32 DIBUTTON_SOCCERD_HEAD = 520111113;
	public const uint32 DIBUTTON_SOCCERD_CLEAR = 520111114;
	public const uint32 DIBUTTON_SOCCERD_GOALIECHARGE = 520111115;
	public const uint32 DIBUTTON_SOCCERD_SUBSTITUTE = 520111116;
	public const uint32 DIBUTTON_SOCCERD_LEFT_LINK = 520144100;
	public const uint32 DIBUTTON_SOCCERD_RIGHT_LINK = 520144108;
	public const uint32 DIBUTTON_SOCCERD_FORWARD_LINK = 520176864;
	public const uint32 DIBUTTON_SOCCERD_BACK_LINK = 520176872;
	public const uint32 DIBUTTON_SOCCERD_DEVICE = 520111358;
	public const uint32 DIBUTTON_SOCCERD_PAUSE = 520111356;
	public const uint32 DIVIRTUAL_SPORTS_RACQUET = 536870912;
	public const uint32 DIAXIS_RACQUET_LATERAL = 536904193;
	public const uint32 DIAXIS_RACQUET_MOVE = 536936962;
	public const uint32 DIBUTTON_RACQUET_SWING = 536871937;
	public const uint32 DIBUTTON_RACQUET_BACKSWING = 536871938;
	public const uint32 DIBUTTON_RACQUET_SMASH = 536871939;
	public const uint32 DIBUTTON_RACQUET_SPECIAL = 536871940;
	public const uint32 DIBUTTON_RACQUET_SELECT = 536871941;
	public const uint32 DIBUTTON_RACQUET_MENU = 536872189;
	public const uint32 DIHATSWITCH_RACQUET_GLANCE = 536888833;
	public const uint32 DIBUTTON_RACQUET_TIMEOUT = 536888326;
	public const uint32 DIBUTTON_RACQUET_SUBSTITUTE = 536888327;
	public const uint32 DIBUTTON_RACQUET_LEFT_LINK = 536921316;
	public const uint32 DIBUTTON_RACQUET_RIGHT_LINK = 536921324;
	public const uint32 DIBUTTON_RACQUET_FORWARD_LINK = 536954080;
	public const uint32 DIBUTTON_RACQUET_BACK_LINK = 536954088;
	public const uint32 DIBUTTON_RACQUET_DEVICE = 536888574;
	public const uint32 DIBUTTON_RACQUET_PAUSE = 536888572;
	public const uint32 DIVIRTUAL_ARCADE_SIDE2SIDE = 553648128;
	public const uint32 DIAXIS_ARCADES_LATERAL = 553681409;
	public const uint32 DIAXIS_ARCADES_MOVE = 553714178;
	public const uint32 DIBUTTON_ARCADES_THROW = 553649153;
	public const uint32 DIBUTTON_ARCADES_CARRY = 553649154;
	public const uint32 DIBUTTON_ARCADES_ATTACK = 553649155;
	public const uint32 DIBUTTON_ARCADES_SPECIAL = 553649156;
	public const uint32 DIBUTTON_ARCADES_SELECT = 553649157;
	public const uint32 DIBUTTON_ARCADES_MENU = 553649405;
	public const uint32 DIHATSWITCH_ARCADES_VIEW = 553666049;
	public const uint32 DIBUTTON_ARCADES_LEFT_LINK = 553698532;
	public const uint32 DIBUTTON_ARCADES_RIGHT_LINK = 553698540;
	public const uint32 DIBUTTON_ARCADES_FORWARD_LINK = 553731296;
	public const uint32 DIBUTTON_ARCADES_BACK_LINK = 553731304;
	public const uint32 DIBUTTON_ARCADES_VIEW_UP_LINK = 554157280;
	public const uint32 DIBUTTON_ARCADES_VIEW_DOWN_LINK = 554157288;
	public const uint32 DIBUTTON_ARCADES_VIEW_LEFT_LINK = 554157284;
	public const uint32 DIBUTTON_ARCADES_VIEW_RIGHT_LINK = 554157292;
	public const uint32 DIBUTTON_ARCADES_DEVICE = 553665790;
	public const uint32 DIBUTTON_ARCADES_PAUSE = 553665788;
	public const uint32 DIVIRTUAL_ARCADE_PLATFORM = 570425344;
	public const uint32 DIAXIS_ARCADEP_LATERAL = 570458625;
	public const uint32 DIAXIS_ARCADEP_MOVE = 570491394;
	public const uint32 DIBUTTON_ARCADEP_JUMP = 570426369;
	public const uint32 DIBUTTON_ARCADEP_FIRE = 570426370;
	public const uint32 DIBUTTON_ARCADEP_CROUCH = 570426371;
	public const uint32 DIBUTTON_ARCADEP_SPECIAL = 570426372;
	public const uint32 DIBUTTON_ARCADEP_SELECT = 570426373;
	public const uint32 DIBUTTON_ARCADEP_MENU = 570426621;
	public const uint32 DIHATSWITCH_ARCADEP_VIEW = 570443265;
	public const uint32 DIBUTTON_ARCADEP_FIRESECONDARY = 570442758;
	public const uint32 DIBUTTON_ARCADEP_LEFT_LINK = 570475748;
	public const uint32 DIBUTTON_ARCADEP_RIGHT_LINK = 570475756;
	public const uint32 DIBUTTON_ARCADEP_FORWARD_LINK = 570508512;
	public const uint32 DIBUTTON_ARCADEP_BACK_LINK = 570508520;
	public const uint32 DIBUTTON_ARCADEP_VIEW_UP_LINK = 570934496;
	public const uint32 DIBUTTON_ARCADEP_VIEW_DOWN_LINK = 570934504;
	public const uint32 DIBUTTON_ARCADEP_VIEW_LEFT_LINK = 570934500;
	public const uint32 DIBUTTON_ARCADEP_VIEW_RIGHT_LINK = 570934508;
	public const uint32 DIBUTTON_ARCADEP_DEVICE = 570443006;
	public const uint32 DIBUTTON_ARCADEP_PAUSE = 570443004;
	public const uint32 DIVIRTUAL_CAD_2DCONTROL = 587202560;
	public const uint32 DIAXIS_2DCONTROL_LATERAL = 587235841;
	public const uint32 DIAXIS_2DCONTROL_MOVE = 587268610;
	public const uint32 DIAXIS_2DCONTROL_INOUT = 587301379;
	public const uint32 DIBUTTON_2DCONTROL_SELECT = 587203585;
	public const uint32 DIBUTTON_2DCONTROL_SPECIAL1 = 587203586;
	public const uint32 DIBUTTON_2DCONTROL_SPECIAL = 587203587;
	public const uint32 DIBUTTON_2DCONTROL_SPECIAL2 = 587203588;
	public const uint32 DIBUTTON_2DCONTROL_MENU = 587203837;
	public const uint32 DIHATSWITCH_2DCONTROL_HATSWITCH = 587220481;
	public const uint32 DIAXIS_2DCONTROL_ROTATEZ = 587350532;
	public const uint32 DIBUTTON_2DCONTROL_DISPLAY = 587219973;
	public const uint32 DIBUTTON_2DCONTROL_DEVICE = 587220222;
	public const uint32 DIBUTTON_2DCONTROL_PAUSE = 587220220;
	public const uint32 DIVIRTUAL_CAD_3DCONTROL = 603979776;
	public const uint32 DIAXIS_3DCONTROL_LATERAL = 604013057;
	public const uint32 DIAXIS_3DCONTROL_MOVE = 604045826;
	public const uint32 DIAXIS_3DCONTROL_INOUT = 604078595;
	public const uint32 DIBUTTON_3DCONTROL_SELECT = 603980801;
	public const uint32 DIBUTTON_3DCONTROL_SPECIAL1 = 603980802;
	public const uint32 DIBUTTON_3DCONTROL_SPECIAL = 603980803;
	public const uint32 DIBUTTON_3DCONTROL_SPECIAL2 = 603980804;
	public const uint32 DIBUTTON_3DCONTROL_MENU = 603981053;
	public const uint32 DIHATSWITCH_3DCONTROL_HATSWITCH = 603997697;
	public const uint32 DIAXIS_3DCONTROL_ROTATEX = 604193284;
	public const uint32 DIAXIS_3DCONTROL_ROTATEY = 604160517;
	public const uint32 DIAXIS_3DCONTROL_ROTATEZ = 604127750;
	public const uint32 DIBUTTON_3DCONTROL_DISPLAY = 603997189;
	public const uint32 DIBUTTON_3DCONTROL_DEVICE = 603997438;
	public const uint32 DIBUTTON_3DCONTROL_PAUSE = 603997436;
	public const uint32 DIVIRTUAL_CAD_FLYBY = 620756992;
	public const uint32 DIAXIS_CADF_LATERAL = 620790273;
	public const uint32 DIAXIS_CADF_MOVE = 620823042;
	public const uint32 DIAXIS_CADF_INOUT = 620855811;
	public const uint32 DIBUTTON_CADF_SELECT = 620758017;
	public const uint32 DIBUTTON_CADF_SPECIAL1 = 620758018;
	public const uint32 DIBUTTON_CADF_SPECIAL = 620758019;
	public const uint32 DIBUTTON_CADF_SPECIAL2 = 620758020;
	public const uint32 DIBUTTON_CADF_MENU = 620758269;
	public const uint32 DIHATSWITCH_CADF_HATSWITCH = 620774913;
	public const uint32 DIAXIS_CADF_ROTATEX = 620970500;
	public const uint32 DIAXIS_CADF_ROTATEY = 620937733;
	public const uint32 DIAXIS_CADF_ROTATEZ = 620904966;
	public const uint32 DIBUTTON_CADF_DISPLAY = 620774405;
	public const uint32 DIBUTTON_CADF_DEVICE = 620774654;
	public const uint32 DIBUTTON_CADF_PAUSE = 620774652;
	public const uint32 DIVIRTUAL_CAD_MODEL = 637534208;
	public const uint32 DIAXIS_CADM_LATERAL = 637567489;
	public const uint32 DIAXIS_CADM_MOVE = 637600258;
	public const uint32 DIAXIS_CADM_INOUT = 637633027;
	public const uint32 DIBUTTON_CADM_SELECT = 637535233;
	public const uint32 DIBUTTON_CADM_SPECIAL1 = 637535234;
	public const uint32 DIBUTTON_CADM_SPECIAL = 637535235;
	public const uint32 DIBUTTON_CADM_SPECIAL2 = 637535236;
	public const uint32 DIBUTTON_CADM_MENU = 637535485;
	public const uint32 DIHATSWITCH_CADM_HATSWITCH = 637552129;
	public const uint32 DIAXIS_CADM_ROTATEX = 637747716;
	public const uint32 DIAXIS_CADM_ROTATEY = 637714949;
	public const uint32 DIAXIS_CADM_ROTATEZ = 637682182;
	public const uint32 DIBUTTON_CADM_DISPLAY = 637551621;
	public const uint32 DIBUTTON_CADM_DEVICE = 637551870;
	public const uint32 DIBUTTON_CADM_PAUSE = 637551868;
	public const uint32 DIVIRTUAL_REMOTE_CONTROL = 654311424;
	public const uint32 DIAXIS_REMOTE_SLIDER = 654639617;
	public const uint32 DIBUTTON_REMOTE_MUTE = 654312449;
	public const uint32 DIBUTTON_REMOTE_SELECT = 654312450;
	public const uint32 DIBUTTON_REMOTE_PLAY = 654320643;
	public const uint32 DIBUTTON_REMOTE_CUE = 654320644;
	public const uint32 DIBUTTON_REMOTE_REVIEW = 654320645;
	public const uint32 DIBUTTON_REMOTE_CHANGE = 654320646;
	public const uint32 DIBUTTON_REMOTE_RECORD = 654320647;
	public const uint32 DIBUTTON_REMOTE_MENU = 654312701;
	public const uint32 DIAXIS_REMOTE_SLIDER2 = 654656002;
	public const uint32 DIBUTTON_REMOTE_TV = 654334984;
	public const uint32 DIBUTTON_REMOTE_CABLE = 654334985;
	public const uint32 DIBUTTON_REMOTE_CD = 654334986;
	public const uint32 DIBUTTON_REMOTE_VCR = 654334987;
	public const uint32 DIBUTTON_REMOTE_TUNER = 654334988;
	public const uint32 DIBUTTON_REMOTE_DVD = 654334989;
	public const uint32 DIBUTTON_REMOTE_ADJUST = 654334990;
	public const uint32 DIBUTTON_REMOTE_DIGIT0 = 654332943;
	public const uint32 DIBUTTON_REMOTE_DIGIT1 = 654332944;
	public const uint32 DIBUTTON_REMOTE_DIGIT2 = 654332945;
	public const uint32 DIBUTTON_REMOTE_DIGIT3 = 654332946;
	public const uint32 DIBUTTON_REMOTE_DIGIT4 = 654332947;
	public const uint32 DIBUTTON_REMOTE_DIGIT5 = 654332948;
	public const uint32 DIBUTTON_REMOTE_DIGIT6 = 654332949;
	public const uint32 DIBUTTON_REMOTE_DIGIT7 = 654332950;
	public const uint32 DIBUTTON_REMOTE_DIGIT8 = 654332951;
	public const uint32 DIBUTTON_REMOTE_DIGIT9 = 654332952;
	public const uint32 DIBUTTON_REMOTE_DEVICE = 654329086;
	public const uint32 DIBUTTON_REMOTE_PAUSE = 654329084;
	public const uint32 DIVIRTUAL_BROWSER_CONTROL = 671088640;
	public const uint32 DIAXIS_BROWSER_LATERAL = 671121921;
	public const uint32 DIAXIS_BROWSER_MOVE = 671154690;
	public const uint32 DIBUTTON_BROWSER_SELECT = 671089665;
	public const uint32 DIAXIS_BROWSER_VIEW = 671187459;
	public const uint32 DIBUTTON_BROWSER_REFRESH = 671089666;
	public const uint32 DIBUTTON_BROWSER_MENU = 671089917;
	public const uint32 DIBUTTON_BROWSER_SEARCH = 671106051;
	public const uint32 DIBUTTON_BROWSER_STOP = 671106052;
	public const uint32 DIBUTTON_BROWSER_HOME = 671106053;
	public const uint32 DIBUTTON_BROWSER_FAVORITES = 671106054;
	public const uint32 DIBUTTON_BROWSER_NEXT = 671106055;
	public const uint32 DIBUTTON_BROWSER_PREVIOUS = 671106056;
	public const uint32 DIBUTTON_BROWSER_HISTORY = 671106057;
	public const uint32 DIBUTTON_BROWSER_PRINT = 671106058;
	public const uint32 DIBUTTON_BROWSER_DEVICE = 671106302;
	public const uint32 DIBUTTON_BROWSER_PAUSE = 671106300;
	public const uint32 DIVIRTUAL_DRIVING_MECHA = 687865856;
	public const uint32 DIAXIS_MECHA_STEER = 687899137;
	public const uint32 DIAXIS_MECHA_TORSO = 687931906;
	public const uint32 DIAXIS_MECHA_ROTATE = 687997443;
	public const uint32 DIAXIS_MECHA_THROTTLE = 688095748;
	public const uint32 DIBUTTON_MECHA_FIRE = 687866881;
	public const uint32 DIBUTTON_MECHA_WEAPONS = 687866882;
	public const uint32 DIBUTTON_MECHA_TARGET = 687866883;
	public const uint32 DIBUTTON_MECHA_REVERSE = 687866884;
	public const uint32 DIBUTTON_MECHA_ZOOM = 687866885;
	public const uint32 DIBUTTON_MECHA_JUMP = 687866886;
	public const uint32 DIBUTTON_MECHA_MENU = 687867133;
	public const uint32 DIBUTTON_MECHA_CENTER = 687883271;
	public const uint32 DIHATSWITCH_MECHA_GLANCE = 687883777;
	public const uint32 DIBUTTON_MECHA_VIEW = 687883272;
	public const uint32 DIBUTTON_MECHA_FIRESECONDARY = 687883273;
	public const uint32 DIBUTTON_MECHA_LEFT_LINK = 687916260;
	public const uint32 DIBUTTON_MECHA_RIGHT_LINK = 687916268;
	public const uint32 DIBUTTON_MECHA_FORWARD_LINK = 687949024;
	public const uint32 DIBUTTON_MECHA_BACK_LINK = 687949032;
	public const uint32 DIBUTTON_MECHA_ROTATE_LEFT_LINK = 688014564;
	public const uint32 DIBUTTON_MECHA_ROTATE_RIGHT_LINK = 688014572;
	public const uint32 DIBUTTON_MECHA_FASTER_LINK = 688112864;
	public const uint32 DIBUTTON_MECHA_SLOWER_LINK = 688112872;
	public const uint32 DIBUTTON_MECHA_DEVICE = 687883518;
	public const uint32 DIBUTTON_MECHA_PAUSE = 687883516;
	public const uint32 DIAXIS_ANY_X_1 = 4278239745;
	public const uint32 DIAXIS_ANY_X_2 = 4278239746;
	public const uint32 DIAXIS_ANY_Y_1 = 4278272513;
	public const uint32 DIAXIS_ANY_Y_2 = 4278272514;
	public const uint32 DIAXIS_ANY_Z_1 = 4278305281;
	public const uint32 DIAXIS_ANY_Z_2 = 4278305282;
	public const uint32 DIAXIS_ANY_R_1 = 4278338049;
	public const uint32 DIAXIS_ANY_R_2 = 4278338050;
	public const uint32 DIAXIS_ANY_U_1 = 4278370817;
	public const uint32 DIAXIS_ANY_U_2 = 4278370818;
	public const uint32 DIAXIS_ANY_V_1 = 4278403585;
	public const uint32 DIAXIS_ANY_V_2 = 4278403586;
	public const uint32 DIAXIS_ANY_A_1 = 4278436353;
	public const uint32 DIAXIS_ANY_A_2 = 4278436354;
	public const uint32 DIAXIS_ANY_B_1 = 4278469121;
	public const uint32 DIAXIS_ANY_B_2 = 4278469122;
	public const uint32 DIAXIS_ANY_C_1 = 4278501889;
	public const uint32 DIAXIS_ANY_C_2 = 4278501890;
	public const uint32 DIAXIS_ANY_S_1 = 4278534657;
	public const uint32 DIAXIS_ANY_S_2 = 4278534658;
	public const uint32 DIAXIS_ANY_1 = 4278206977;
	public const uint32 DIAXIS_ANY_2 = 4278206978;
	public const uint32 DIAXIS_ANY_3 = 4278206979;
	public const uint32 DIAXIS_ANY_4 = 4278206980;
	public const uint32 DIPOV_ANY_1 = 4278208001;
	public const uint32 DIPOV_ANY_2 = 4278208002;
	public const uint32 DIPOV_ANY_3 = 4278208003;
	public const uint32 DIPOV_ANY_4 = 4278208004;
	public const int32 JOY_PASSDRIVERDATA = 268435456;
	public const int32 JOY_HWS_ISHEADTRACKER = 33554432;
	public const int32 JOY_HWS_ISGAMEPORTDRIVER = 67108864;
	public const int32 JOY_HWS_ISANALOGPORTDRIVER = 134217728;
	public const int32 JOY_HWS_AUTOLOAD = 268435456;
	public const int32 JOY_HWS_NODEVNODE = 536870912;
	public const int32 JOY_HWS_ISGAMEPORTBUS = -2147483648;
	public const int32 JOY_HWS_GAMEPORTBUSBUSY = 1;
	public const int32 JOY_US_VOLATILE = 8;
	public const uint32 JOY_OEMPOLL_PASSDRIVERDATA = 7;
	public const uint32 BUTTON_BIT_POWER = 1;
	public const uint32 BUTTON_BIT_WINDOWS = 2;
	public const uint32 BUTTON_BIT_VOLUMEUP = 4;
	public const uint32 BUTTON_BIT_VOLUMEDOWN = 8;
	public const uint32 BUTTON_BIT_ROTATION_LOCK = 16;
	public const uint32 BUTTON_BIT_BACK = 32;
	public const uint32 BUTTON_BIT_SEARCH = 64;
	public const uint32 BUTTON_BIT_CAMERAFOCUS = 128;
	public const uint32 BUTTON_BIT_CAMERASHUTTER = 256;
	public const uint32 BUTTON_BIT_RINGERTOGGLE = 512;
	public const uint32 BUTTON_BIT_HEADSET = 1024;
	public const uint32 BUTTON_BIT_HWKBDEPLOY = 2048;
	public const uint32 BUTTON_BIT_CAMERALENS = 4096;
	public const uint32 BUTTON_BIT_OEMCUSTOM = 8192;
	public const uint32 BUTTON_BIT_OEMCUSTOM2 = 16384;
	public const uint32 BUTTON_BIT_OEMCUSTOM3 = 32768;
	public const uint32 BUTTON_BIT_ALLBUTTONSMASK = 16383;
	public const uint32 IOCTL_BUTTON_SET_ENABLED_ON_IDLE = 721576;
	public const uint32 IOCTL_BUTTON_GET_ENABLED_ON_IDLE = 721580;
}
#endregion

#region Enums

[AllowDuplicates]
public enum HIDP_REPORT_TYPE : int32
{
	HidP_Input = 0,
	HidP_Output = 1,
	HidP_Feature = 2,
}


[AllowDuplicates]
public enum HIDP_KEYBOARD_DIRECTION : int32
{
	HidP_Keyboard_Break = 0,
	HidP_Keyboard_Make = 1,
}


[AllowDuplicates]
public enum GPIOBUTTONS_BUTTON_TYPE : int32
{
	GPIO_BUTTON_POWER = 0,
	GPIO_BUTTON_WINDOWS = 1,
	GPIO_BUTTON_VOLUME_UP = 2,
	GPIO_BUTTON_VOLUME_DOWN = 3,
	GPIO_BUTTON_ROTATION_LOCK = 4,
	GPIO_BUTTON_BACK = 5,
	GPIO_BUTTON_SEARCH = 6,
	GPIO_BUTTON_CAMERA_FOCUS = 7,
	GPIO_BUTTON_CAMERA_SHUTTER = 8,
	GPIO_BUTTON_RINGER_TOGGLE = 9,
	GPIO_BUTTON_HEADSET = 10,
	GPIO_BUTTON_HWKB_DEPLOY = 11,
	GPIO_BUTTON_CAMERA_LENS = 12,
	GPIO_BUTTON_OEM_CUSTOM = 13,
	GPIO_BUTTON_OEM_CUSTOM2 = 14,
	GPIO_BUTTON_OEM_CUSTOM3 = 15,
	GPIO_BUTTON_COUNT_MIN = 5,
	GPIO_BUTTON_COUNT = 16,
}

#endregion

#region Function Pointers
public function BOOL LPDIENUMEFFECTSINFILECALLBACK(DIFILEEFFECT* param0, void* param1);

public function BOOL LPDIENUMDEVICEOBJECTSCALLBACKA(DIDEVICEOBJECTINSTANCEA* param0, void* param1);

public function BOOL LPDIENUMDEVICEOBJECTSCALLBACKW(DIDEVICEOBJECTINSTANCEW* param0, void* param1);

public function BOOL LPDIENUMEFFECTSCALLBACKA(DIEFFECTINFOA* param0, void* param1);

public function BOOL LPDIENUMEFFECTSCALLBACKW(DIEFFECTINFOW* param0, void* param1);

public function BOOL LPDIENUMCREATEDEFFECTOBJECTSCALLBACK(IDirectInputEffect* param0, void* param1);

public function BOOL LPDIENUMDEVICESCALLBACKA(DIDEVICEINSTANCEA* param0, void* param1);

public function BOOL LPDIENUMDEVICESCALLBACKW(DIDEVICEINSTANCEW* param0, void* param1);

public function BOOL LPDICONFIGUREDEVICESCALLBACK(IUnknown* param0, void* param1);

public function BOOL LPDIENUMDEVICESBYSEMANTICSCBA(DIDEVICEINSTANCEA* param0, IDirectInputDevice8A* param1, uint32 param2, uint32 param3, void* param4);

public function BOOL LPDIENUMDEVICESBYSEMANTICSCBW(DIDEVICEINSTANCEW* param0, IDirectInputDevice8W* param1, uint32 param2, uint32 param3, void* param4);

public function void LPFNSHOWJOYCPL(HWND hWnd);

public function BOOL LPDIJOYTYPECALLBACK(PWSTR param0, void* param1);

public function BOOLEAN PHIDP_INSERT_SCANCODES(void* Context, PSTR NewScanCodes, uint32 Length);

public function NTSTATUS PFN_HidP_GetVersionInternal(uint32* Version);

#endregion

#region Structs
[CRepr]
public struct _HIDP_PREPARSED_DATA
{
}

[CRepr]
public struct DICONSTANTFORCE
{
	public int32 lMagnitude;
}

[CRepr]
public struct DIRAMPFORCE
{
	public int32 lStart;
	public int32 lEnd;
}

[CRepr]
public struct DIPERIODIC
{
	public uint32 dwMagnitude;
	public int32 lOffset;
	public uint32 dwPhase;
	public uint32 dwPeriod;
}

[CRepr]
public struct DICONDITION
{
	public int32 lOffset;
	public int32 lPositiveCoefficient;
	public int32 lNegativeCoefficient;
	public uint32 dwPositiveSaturation;
	public uint32 dwNegativeSaturation;
	public int32 lDeadBand;
}

[CRepr]
public struct DICUSTOMFORCE
{
	public uint32 cChannels;
	public uint32 dwSamplePeriod;
	public uint32 cSamples;
	public int32* rglForceData;
}

[CRepr]
public struct DIENVELOPE
{
	public uint32 dwSize;
	public uint32 dwAttackLevel;
	public uint32 dwAttackTime;
	public uint32 dwFadeLevel;
	public uint32 dwFadeTime;
}

[CRepr]
public struct DIEFFECT_DX5
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwDuration;
	public uint32 dwSamplePeriod;
	public uint32 dwGain;
	public uint32 dwTriggerButton;
	public uint32 dwTriggerRepeatInterval;
	public uint32 cAxes;
	public uint32* rgdwAxes;
	public int32* rglDirection;
	public DIENVELOPE* lpEnvelope;
	public uint32 cbTypeSpecificParams;
	public void* lpvTypeSpecificParams;
}

[CRepr]
public struct DIEFFECT
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwDuration;
	public uint32 dwSamplePeriod;
	public uint32 dwGain;
	public uint32 dwTriggerButton;
	public uint32 dwTriggerRepeatInterval;
	public uint32 cAxes;
	public uint32* rgdwAxes;
	public int32* rglDirection;
	public DIENVELOPE* lpEnvelope;
	public uint32 cbTypeSpecificParams;
	public void* lpvTypeSpecificParams;
	public uint32 dwStartDelay;
}

[CRepr]
public struct DIFILEEFFECT
{
	public uint32 dwSize;
	public Guid GuidEffect;
	public DIEFFECT* lpDiEffect;
	public CHAR[260] szFriendlyName;
}

[CRepr]
public struct DIEFFESCAPE
{
	public uint32 dwSize;
	public uint32 dwCommand;
	public void* lpvInBuffer;
	public uint32 cbInBuffer;
	public void* lpvOutBuffer;
	public uint32 cbOutBuffer;
}

[CRepr]
public struct DIDEVCAPS_DX3
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwDevType;
	public uint32 dwAxes;
	public uint32 dwButtons;
	public uint32 dwPOVs;
}

[CRepr]
public struct DIDEVCAPS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwDevType;
	public uint32 dwAxes;
	public uint32 dwButtons;
	public uint32 dwPOVs;
	public uint32 dwFFSamplePeriod;
	public uint32 dwFFMinTimeResolution;
	public uint32 dwFirmwareRevision;
	public uint32 dwHardwareRevision;
	public uint32 dwFFDriverVersion;
}

[CRepr]
public struct DIOBJECTDATAFORMAT
{
	public Guid* pguid;
	public uint32 dwOfs;
	public uint32 dwType;
	public uint32 dwFlags;
}

[CRepr]
public struct DIDATAFORMAT
{
	public uint32 dwSize;
	public uint32 dwObjSize;
	public uint32 dwFlags;
	public uint32 dwDataSize;
	public uint32 dwNumObjs;
	public DIOBJECTDATAFORMAT* rgodf;
}

[CRepr]
public struct DIACTIONA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PSTR lptszActionName;
		public uint32 uResIdString;
	}
	public uint uAppData;
	public uint32 dwSemantic;
	public uint32 dwFlags;
	public using _Anonymous_e__Union Anonymous;
	public Guid guidInstance;
	public uint32 dwObjID;
	public uint32 dwHow;
}

[CRepr]
public struct DIACTIONW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR lptszActionName;
		public uint32 uResIdString;
	}
	public uint uAppData;
	public uint32 dwSemantic;
	public uint32 dwFlags;
	public using _Anonymous_e__Union Anonymous;
	public Guid guidInstance;
	public uint32 dwObjID;
	public uint32 dwHow;
}

[CRepr]
public struct DIACTIONFORMATA
{
	public uint32 dwSize;
	public uint32 dwActionSize;
	public uint32 dwDataSize;
	public uint32 dwNumActions;
	public DIACTIONA* rgoAction;
	public Guid guidActionMap;
	public uint32 dwGenre;
	public uint32 dwBufferSize;
	public int32 lAxisMin;
	public int32 lAxisMax;
	public HINSTANCE hInstString;
	public FILETIME ftTimeStamp;
	public uint32 dwCRC;
	public CHAR[260] tszActionMap;
}

[CRepr]
public struct DIACTIONFORMATW
{
	public uint32 dwSize;
	public uint32 dwActionSize;
	public uint32 dwDataSize;
	public uint32 dwNumActions;
	public DIACTIONW* rgoAction;
	public Guid guidActionMap;
	public uint32 dwGenre;
	public uint32 dwBufferSize;
	public int32 lAxisMin;
	public int32 lAxisMax;
	public HINSTANCE hInstString;
	public FILETIME ftTimeStamp;
	public uint32 dwCRC;
	public char16[260] tszActionMap;
}

[CRepr]
public struct DICOLORSET
{
	public uint32 dwSize;
	public uint32 cTextFore;
	public uint32 cTextHighlight;
	public uint32 cCalloutLine;
	public uint32 cCalloutHighlight;
	public uint32 cBorder;
	public uint32 cControlFill;
	public uint32 cHighlightFill;
	public uint32 cAreaFill;
}

[CRepr]
public struct DICONFIGUREDEVICESPARAMSA
{
	public uint32 dwSize;
	public uint32 dwcUsers;
	public PSTR lptszUserNames;
	public uint32 dwcFormats;
	public DIACTIONFORMATA* lprgFormats;
	public HWND hwnd;
	public DICOLORSET dics;
	public IUnknown* lpUnkDDSTarget;
}

[CRepr]
public struct DICONFIGUREDEVICESPARAMSW
{
	public uint32 dwSize;
	public uint32 dwcUsers;
	public PWSTR lptszUserNames;
	public uint32 dwcFormats;
	public DIACTIONFORMATW* lprgFormats;
	public HWND hwnd;
	public DICOLORSET dics;
	public IUnknown* lpUnkDDSTarget;
}

[CRepr]
public struct DIDEVICEIMAGEINFOA
{
	public CHAR[260] tszImagePath;
	public uint32 dwFlags;
	public uint32 dwViewID;
	public RECT rcOverlay;
	public uint32 dwObjID;
	public uint32 dwcValidPts;
	public POINT[5] rgptCalloutLine;
	public RECT rcCalloutRect;
	public uint32 dwTextAlign;
}

[CRepr]
public struct DIDEVICEIMAGEINFOW
{
	public char16[260] tszImagePath;
	public uint32 dwFlags;
	public uint32 dwViewID;
	public RECT rcOverlay;
	public uint32 dwObjID;
	public uint32 dwcValidPts;
	public POINT[5] rgptCalloutLine;
	public RECT rcCalloutRect;
	public uint32 dwTextAlign;
}

[CRepr]
public struct DIDEVICEIMAGEINFOHEADERA
{
	public uint32 dwSize;
	public uint32 dwSizeImageInfo;
	public uint32 dwcViews;
	public uint32 dwcButtons;
	public uint32 dwcAxes;
	public uint32 dwcPOVs;
	public uint32 dwBufferSize;
	public uint32 dwBufferUsed;
	public DIDEVICEIMAGEINFOA* lprgImageInfoArray;
}

[CRepr]
public struct DIDEVICEIMAGEINFOHEADERW
{
	public uint32 dwSize;
	public uint32 dwSizeImageInfo;
	public uint32 dwcViews;
	public uint32 dwcButtons;
	public uint32 dwcAxes;
	public uint32 dwcPOVs;
	public uint32 dwBufferSize;
	public uint32 dwBufferUsed;
	public DIDEVICEIMAGEINFOW* lprgImageInfoArray;
}

[CRepr]
public struct DIDEVICEOBJECTINSTANCE_DX3A
{
	public uint32 dwSize;
	public Guid guidType;
	public uint32 dwOfs;
	public uint32 dwType;
	public uint32 dwFlags;
	public CHAR[260] tszName;
}

[CRepr]
public struct DIDEVICEOBJECTINSTANCE_DX3W
{
	public uint32 dwSize;
	public Guid guidType;
	public uint32 dwOfs;
	public uint32 dwType;
	public uint32 dwFlags;
	public char16[260] tszName;
}

[CRepr]
public struct DIDEVICEOBJECTINSTANCEA
{
	public uint32 dwSize;
	public Guid guidType;
	public uint32 dwOfs;
	public uint32 dwType;
	public uint32 dwFlags;
	public CHAR[260] tszName;
	public uint32 dwFFMaxForce;
	public uint32 dwFFForceResolution;
	public uint16 wCollectionNumber;
	public uint16 wDesignatorIndex;
	public uint16 wUsagePage;
	public uint16 wUsage;
	public uint32 dwDimension;
	public uint16 wExponent;
	public uint16 wReportId;
}

[CRepr]
public struct DIDEVICEOBJECTINSTANCEW
{
	public uint32 dwSize;
	public Guid guidType;
	public uint32 dwOfs;
	public uint32 dwType;
	public uint32 dwFlags;
	public char16[260] tszName;
	public uint32 dwFFMaxForce;
	public uint32 dwFFForceResolution;
	public uint16 wCollectionNumber;
	public uint16 wDesignatorIndex;
	public uint16 wUsagePage;
	public uint16 wUsage;
	public uint32 dwDimension;
	public uint16 wExponent;
	public uint16 wReportId;
}

[CRepr]
public struct DIPROPHEADER
{
	public uint32 dwSize;
	public uint32 dwHeaderSize;
	public uint32 dwObj;
	public uint32 dwHow;
}

[CRepr]
public struct DIPROPDWORD
{
	public DIPROPHEADER diph;
	public uint32 dwData;
}

[CRepr]
public struct DIPROPPOINTER
{
	public DIPROPHEADER diph;
	public uint uData;
}

[CRepr]
public struct DIPROPRANGE
{
	public DIPROPHEADER diph;
	public int32 lMin;
	public int32 lMax;
}

[CRepr]
public struct DIPROPCAL
{
	public DIPROPHEADER diph;
	public int32 lMin;
	public int32 lCenter;
	public int32 lMax;
}

[CRepr]
public struct DIPROPCALPOV
{
	public DIPROPHEADER diph;
	public int32[5] lMin;
	public int32[5] lMax;
}

[CRepr]
public struct DIPROPGUIDANDPATH
{
	public DIPROPHEADER diph;
	public Guid guidClass;
	public char16[260] wszPath;
}

[CRepr]
public struct DIPROPSTRING
{
	public DIPROPHEADER diph;
	public char16[260] wsz;
}

[CRepr]
public struct CPOINT
{
	public int32 lP;
	public uint32 dwLog;
}

[CRepr]
public struct DIPROPCPOINTS
{
	public DIPROPHEADER diph;
	public uint32 dwCPointsNum;
	public CPOINT[8] cp;
}

[CRepr]
public struct DIDEVICEOBJECTDATA_DX3
{
	public uint32 dwOfs;
	public uint32 dwData;
	public uint32 dwTimeStamp;
	public uint32 dwSequence;
}

[CRepr]
public struct DIDEVICEOBJECTDATA
{
	public uint32 dwOfs;
	public uint32 dwData;
	public uint32 dwTimeStamp;
	public uint32 dwSequence;
	public uint uAppData;
}

[CRepr]
public struct DIDEVICEINSTANCE_DX3A
{
	public uint32 dwSize;
	public Guid guidInstance;
	public Guid guidProduct;
	public uint32 dwDevType;
	public CHAR[260] tszInstanceName;
	public CHAR[260] tszProductName;
}

[CRepr]
public struct DIDEVICEINSTANCE_DX3W
{
	public uint32 dwSize;
	public Guid guidInstance;
	public Guid guidProduct;
	public uint32 dwDevType;
	public char16[260] tszInstanceName;
	public char16[260] tszProductName;
}

[CRepr]
public struct DIDEVICEINSTANCEA
{
	public uint32 dwSize;
	public Guid guidInstance;
	public Guid guidProduct;
	public uint32 dwDevType;
	public CHAR[260] tszInstanceName;
	public CHAR[260] tszProductName;
	public Guid guidFFDriver;
	public uint16 wUsagePage;
	public uint16 wUsage;
}

[CRepr]
public struct DIDEVICEINSTANCEW
{
	public uint32 dwSize;
	public Guid guidInstance;
	public Guid guidProduct;
	public uint32 dwDevType;
	public char16[260] tszInstanceName;
	public char16[260] tszProductName;
	public Guid guidFFDriver;
	public uint16 wUsagePage;
	public uint16 wUsage;
}

[CRepr]
public struct DIEFFECTINFOA
{
	public uint32 dwSize;
	public Guid guid;
	public uint32 dwEffType;
	public uint32 dwStaticParams;
	public uint32 dwDynamicParams;
	public CHAR[260] tszName;
}

[CRepr]
public struct DIEFFECTINFOW
{
	public uint32 dwSize;
	public Guid guid;
	public uint32 dwEffType;
	public uint32 dwStaticParams;
	public uint32 dwDynamicParams;
	public char16[260] tszName;
}

[CRepr]
public struct DIMOUSESTATE
{
	public int32 lX;
	public int32 lY;
	public int32 lZ;
	public uint8[4] rgbButtons;
}

[CRepr]
public struct DIMOUSESTATE2
{
	public int32 lX;
	public int32 lY;
	public int32 lZ;
	public uint8[8] rgbButtons;
}

[CRepr]
public struct DIJOYSTATE
{
	public int32 lX;
	public int32 lY;
	public int32 lZ;
	public int32 lRx;
	public int32 lRy;
	public int32 lRz;
	public int32[2] rglSlider;
	public uint32[4] rgdwPOV;
	public uint8[32] rgbButtons;
}

[CRepr]
public struct DIJOYSTATE2
{
	public int32 lX;
	public int32 lY;
	public int32 lZ;
	public int32 lRx;
	public int32 lRy;
	public int32 lRz;
	public int32[2] rglSlider;
	public uint32[4] rgdwPOV;
	public uint8[128] rgbButtons;
	public int32 lVX;
	public int32 lVY;
	public int32 lVZ;
	public int32 lVRx;
	public int32 lVRy;
	public int32 lVRz;
	public int32[2] rglVSlider;
	public int32 lAX;
	public int32 lAY;
	public int32 lAZ;
	public int32 lARx;
	public int32 lARy;
	public int32 lARz;
	public int32[2] rglASlider;
	public int32 lFX;
	public int32 lFY;
	public int32 lFZ;
	public int32 lFRx;
	public int32 lFRy;
	public int32 lFRz;
	public int32[2] rglFSlider;
}

[CRepr]
public struct DIOBJECTATTRIBUTES
{
	public uint32 dwFlags;
	public uint16 wUsagePage;
	public uint16 wUsage;
}

[CRepr]
public struct DIFFOBJECTATTRIBUTES
{
	public uint32 dwFFMaxForce;
	public uint32 dwFFForceResolution;
}

[CRepr]
public struct DIOBJECTCALIBRATION
{
	public int32 lMin;
	public int32 lCenter;
	public int32 lMax;
}

[CRepr]
public struct DIPOVCALIBRATION
{
	public int32[5] lMin;
	public int32[5] lMax;
}

[CRepr]
public struct DIEFFECTATTRIBUTES
{
	public uint32 dwEffectId;
	public uint32 dwEffType;
	public uint32 dwStaticParams;
	public uint32 dwDynamicParams;
	public uint32 dwCoords;
}

[CRepr]
public struct DIFFDEVICEATTRIBUTES
{
	public uint32 dwFlags;
	public uint32 dwFFSamplePeriod;
	public uint32 dwFFMinTimeResolution;
}

[CRepr]
public struct DIDRIVERVERSIONS
{
	public uint32 dwSize;
	public uint32 dwFirmwareRevision;
	public uint32 dwHardwareRevision;
	public uint32 dwFFDriverVersion;
}

[CRepr]
public struct DIDEVICESTATE
{
	public uint32 dwSize;
	public uint32 dwState;
	public uint32 dwLoad;
}

[CRepr]
public struct DIHIDFFINITINFO
{
	public uint32 dwSize;
	public PWSTR pwszDeviceInterface;
	public Guid GuidInstance;
}

[CRepr]
public struct JOYPOS
{
	public uint32 dwX;
	public uint32 dwY;
	public uint32 dwZ;
	public uint32 dwR;
	public uint32 dwU;
	public uint32 dwV;
}

[CRepr]
public struct JOYRANGE
{
	public JOYPOS jpMin;
	public JOYPOS jpMax;
	public JOYPOS jpCenter;
}

[CRepr]
public struct JOYREGUSERVALUES
{
	public uint32 dwTimeOut;
	public JOYRANGE jrvRanges;
	public JOYPOS jpDeadZone;
}

[CRepr]
public struct JOYREGHWSETTINGS
{
	public uint32 dwFlags;
	public uint32 dwNumButtons;
}

[CRepr]
public struct JOYREGHWVALUES
{
	public JOYRANGE jrvHardware;
	public uint32[4] dwPOVValues;
	public uint32 dwCalFlags;
}

[CRepr]
public struct JOYREGHWCONFIG
{
	public JOYREGHWSETTINGS hws;
	public uint32 dwUsageSettings;
	public JOYREGHWVALUES hwv;
	public uint32 dwType;
	public uint32 dwReserved;
}

[CRepr]
public struct JOYCALIBRATE
{
	public uint32 wXbase;
	public uint32 wXdelta;
	public uint32 wYbase;
	public uint32 wYdelta;
	public uint32 wZbase;
	public uint32 wZdelta;
}

[CRepr]
public struct DIJOYTYPEINFO_DX5
{
	public uint32 dwSize;
	public JOYREGHWSETTINGS hws;
	public Guid clsidConfig;
	public char16[256] wszDisplayName;
	public char16[260] wszCallout;
}

[CRepr]
public struct DIJOYTYPEINFO_DX6
{
	public uint32 dwSize;
	public JOYREGHWSETTINGS hws;
	public Guid clsidConfig;
	public char16[256] wszDisplayName;
	public char16[260] wszCallout;
	public char16[256] wszHardwareId;
	public uint32 dwFlags1;
}

[CRepr]
public struct DIJOYTYPEINFO
{
	public uint32 dwSize;
	public JOYREGHWSETTINGS hws;
	public Guid clsidConfig;
	public char16[256] wszDisplayName;
	public char16[260] wszCallout;
	public char16[256] wszHardwareId;
	public uint32 dwFlags1;
	public uint32 dwFlags2;
	public char16[256] wszMapFile;
}

[CRepr]
public struct DIJOYCONFIG_DX5
{
	public uint32 dwSize;
	public Guid guidInstance;
	public JOYREGHWCONFIG hwc;
	public uint32 dwGain;
	public char16[256] wszType;
	public char16[256] wszCallout;
}

[CRepr]
public struct DIJOYCONFIG
{
	public uint32 dwSize;
	public Guid guidInstance;
	public JOYREGHWCONFIG hwc;
	public uint32 dwGain;
	public char16[256] wszType;
	public char16[256] wszCallout;
	public Guid guidGameport;
}

[CRepr]
public struct DIJOYUSERVALUES
{
	public uint32 dwSize;
	public JOYREGUSERVALUES ruv;
	public char16[256] wszGlobalDriver;
	public char16[256] wszGameportEmulator;
}

[CRepr]
public struct KEYBOARD_INPUT_DATA
{
	public uint16 UnitId;
	public uint16 MakeCode;
	public uint16 Flags;
	public uint16 Reserved;
	public uint32 ExtraInformation;
}

[CRepr]
public struct KEYBOARD_TYPEMATIC_PARAMETERS
{
	public uint16 UnitId;
	public uint16 Rate;
	public uint16 Delay;
}

[CRepr]
public struct KEYBOARD_ID
{
	public uint8 Type;
	public uint8 Subtype;
}

[CRepr]
public struct KEYBOARD_ATTRIBUTES
{
	public KEYBOARD_ID KeyboardIdentifier;
	public uint16 KeyboardMode;
	public uint16 NumberOfFunctionKeys;
	public uint16 NumberOfIndicators;
	public uint16 NumberOfKeysTotal;
	public uint32 InputDataQueueLength;
	public KEYBOARD_TYPEMATIC_PARAMETERS KeyRepeatMinimum;
	public KEYBOARD_TYPEMATIC_PARAMETERS KeyRepeatMaximum;
}

[CRepr]
public struct KEYBOARD_EXTENDED_ATTRIBUTES
{
	public uint8 Version;
	public uint8 FormFactor;
	public uint8 KeyType;
	public uint8 PhysicalLayout;
	public uint8 VendorSpecificPhysicalLayout;
	public uint8 IETFLanguageTagIndex;
	public uint8 ImplementedInputAssistControls;
}

[CRepr]
public struct KEYBOARD_INDICATOR_PARAMETERS
{
	public uint16 UnitId;
	public uint16 LedFlags;
}

[CRepr]
public struct INDICATOR_LIST
{
	public uint16 MakeCode;
	public uint16 IndicatorFlags;
}

[CRepr]
public struct KEYBOARD_INDICATOR_TRANSLATION
{
	public uint16 NumberOfIndicatorKeys;
	public INDICATOR_LIST* IndicatorList mut => &IndicatorList_impl;
	private INDICATOR_LIST[ANYSIZE_ARRAY] IndicatorList_impl;
}

[CRepr]
public struct KEYBOARD_UNIT_ID_PARAMETER
{
	public uint16 UnitId;
}

[CRepr]
public struct KEYBOARD_IME_STATUS
{
	public uint16 UnitId;
	public uint32 ImeOpen;
	public uint32 ImeConvMode;
}

[CRepr]
public struct MOUSE_INPUT_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 ButtonFlags;
			public uint16 ButtonData;
		}
		public uint32 Buttons;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint16 UnitId;
	public uint16 Flags;
	public using _Anonymous_e__Union Anonymous;
	public uint32 RawButtons;
	public int32 LastX;
	public int32 LastY;
	public uint32 ExtraInformation;
}

[CRepr]
public struct MOUSE_ATTRIBUTES
{
	public uint16 MouseIdentifier;
	public uint16 NumberOfButtons;
	public uint16 SampleRate;
	public uint32 InputDataQueueLength;
}

[CRepr]
public struct MOUSE_UNIT_ID_PARAMETER
{
	public uint16 UnitId;
}

[CRepr]
public struct USAGE_AND_PAGE
{
	public uint16 Usage;
	public uint16 UsagePage;
}

[CRepr]
public struct HIDP_BUTTON_CAPS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Range_e__Struct
		{
			public uint16 UsageMin;
			public uint16 UsageMax;
			public uint16 StringMin;
			public uint16 StringMax;
			public uint16 DesignatorMin;
			public uint16 DesignatorMax;
			public uint16 DataIndexMin;
			public uint16 DataIndexMax;
		}
		[CRepr]
		public struct _NotRange_e__Struct
		{
			public uint16 Usage;
			public uint16 Reserved1;
			public uint16 StringIndex;
			public uint16 Reserved2;
			public uint16 DesignatorIndex;
			public uint16 Reserved3;
			public uint16 DataIndex;
			public uint16 Reserved4;
		}
		public _Range_e__Struct Range;
		public _NotRange_e__Struct NotRange;
	}
	public uint16 UsagePage;
	public uint8 ReportID;
	public BOOLEAN IsAlias;
	public uint16 BitField;
	public uint16 LinkCollection;
	public uint16 LinkUsage;
	public uint16 LinkUsagePage;
	public BOOLEAN IsRange;
	public BOOLEAN IsStringRange;
	public BOOLEAN IsDesignatorRange;
	public BOOLEAN IsAbsolute;
	public uint16 ReportCount;
	public uint16 Reserved2;
	public uint32[9] Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct HIDP_VALUE_CAPS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Range_e__Struct
		{
			public uint16 UsageMin;
			public uint16 UsageMax;
			public uint16 StringMin;
			public uint16 StringMax;
			public uint16 DesignatorMin;
			public uint16 DesignatorMax;
			public uint16 DataIndexMin;
			public uint16 DataIndexMax;
		}
		[CRepr]
		public struct _NotRange_e__Struct
		{
			public uint16 Usage;
			public uint16 Reserved1;
			public uint16 StringIndex;
			public uint16 Reserved2;
			public uint16 DesignatorIndex;
			public uint16 Reserved3;
			public uint16 DataIndex;
			public uint16 Reserved4;
		}
		public _Range_e__Struct Range;
		public _NotRange_e__Struct NotRange;
	}
	public uint16 UsagePage;
	public uint8 ReportID;
	public BOOLEAN IsAlias;
	public uint16 BitField;
	public uint16 LinkCollection;
	public uint16 LinkUsage;
	public uint16 LinkUsagePage;
	public BOOLEAN IsRange;
	public BOOLEAN IsStringRange;
	public BOOLEAN IsDesignatorRange;
	public BOOLEAN IsAbsolute;
	public BOOLEAN HasNull;
	public uint8 Reserved;
	public uint16 BitSize;
	public uint16 ReportCount;
	public uint16[5] Reserved2;
	public uint32 UnitsExp;
	public uint32 Units;
	public int32 LogicalMin;
	public int32 LogicalMax;
	public int32 PhysicalMin;
	public int32 PhysicalMax;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(4)]
public struct HIDP_LINK_COLLECTION_NODE
{
	public uint16 LinkUsage;
	public uint16 LinkUsagePage;
	public uint16 Parent;
	public uint16 NumberOfChildren;
	public uint16 NextSibling;
	public uint16 FirstChild;
	public uint32 _bitfield;
	public void* UserContext;
}

[CRepr]
public struct HIDP_CAPS
{
	public uint16 Usage;
	public uint16 UsagePage;
	public uint16 InputReportByteLength;
	public uint16 OutputReportByteLength;
	public uint16 FeatureReportByteLength;
	public uint16[17] Reserved;
	public uint16 NumberLinkCollectionNodes;
	public uint16 NumberInputButtonCaps;
	public uint16 NumberInputValueCaps;
	public uint16 NumberInputDataIndices;
	public uint16 NumberOutputButtonCaps;
	public uint16 NumberOutputValueCaps;
	public uint16 NumberOutputDataIndices;
	public uint16 NumberFeatureButtonCaps;
	public uint16 NumberFeatureValueCaps;
	public uint16 NumberFeatureDataIndices;
}

[CRepr]
public struct HIDP_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 RawValue;
		public BOOLEAN On;
	}
	public uint16 DataIndex;
	public uint16 Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct HIDP_UNKNOWN_TOKEN
{
	public uint8 Token;
	public uint8[3] Reserved;
	public uint32 BitField;
}

[CRepr, Packed(4)]
public struct HIDP_EXTENDED_ATTRIBUTES
{
	public uint8 NumGlobalUnknowns;
	public uint8[3] Reserved;
	public HIDP_UNKNOWN_TOKEN* GlobalUnknowns;
	public uint32* Data mut => &Data_impl;
	private uint32[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct HIDP_BUTTON_ARRAY_DATA
{
	public uint16 ArrayIndex;
	public BOOLEAN On;
}

[CRepr]
public struct HIDP_KEYBOARD_MODIFIER_STATE
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
		public uint32 ul;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(4)]
public struct HIDD_CONFIGURATION
{
	public void* cookie;
	public uint32 size;
	public uint32 RingBufferSize;
}

[CRepr]
public struct HIDD_ATTRIBUTES
{
	public uint32 Size;
	public uint16 VendorID;
	public uint16 ProductID;
	public uint16 VersionNumber;
}

[CRepr]
public struct HID_XFER_PACKET
{
	public uint8* reportBuffer;
	public uint32 reportBufferLen;
	public uint8 reportId;
}

[CRepr]
public struct HID_COLLECTION_INFORMATION
{
	public uint32 DescriptorSize;
	public BOOLEAN Polled;
	public uint8* Reserved1 mut => &Reserved1_impl;
	private uint8[ANYSIZE_ARRAY] Reserved1_impl;
	public uint16 VendorID;
	public uint16 ProductID;
	public uint16 VersionNumber;
}

[CRepr]
public struct HID_DRIVER_CONFIG
{
	public uint32 Size;
	public uint32 RingBufferSize;
}

[CRepr]
public struct INPUT_BUTTON_ENABLE_INFO
{
	public GPIOBUTTONS_BUTTON_TYPE ButtonType;
	public BOOLEAN Enabled;
}

#endregion

#region COM Types
[CRepr]struct IDirectInputEffect : IUnknown
{
	public new const Guid IID = .(0xe7e1f7c0, 0x88d2, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1, in Guid param2) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* param0) GetEffectGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFECT* param0, uint32 param1) GetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFECT* param0, uint32 param1) SetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetEffectStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Download;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFESCAPE* param0) Escape;
	}


	public HRESULT Initialize(HINSTANCE param0, uint32 param1, in Guid param2) mut => VT.[Friend]Initialize(&this, param0, param1, param2);

	public HRESULT GetEffectGuid(Guid* param0) mut => VT.[Friend]GetEffectGuid(&this, param0);

	public HRESULT GetParameters(DIEFFECT* param0, uint32 param1) mut => VT.[Friend]GetParameters(&this, param0, param1);

	public HRESULT SetParameters(DIEFFECT* param0, uint32 param1) mut => VT.[Friend]SetParameters(&this, param0, param1);

	public HRESULT Start(uint32 param0, uint32 param1) mut => VT.[Friend]Start(&this, param0, param1);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT GetEffectStatus(uint32* param0) mut => VT.[Friend]GetEffectStatus(&this, param0);

	public HRESULT Download() mut => VT.[Friend]Download(&this);

	public HRESULT Unload() mut => VT.[Friend]Unload(&this);

	public HRESULT Escape(DIEFFESCAPE* param0) mut => VT.[Friend]Escape(&this, param0);
}

[CRepr]struct IDirectInputDeviceW : IUnknown
{
	public new const Guid IID = .(0x5944e681, 0xc92e, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVCAPS* param0) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMDEVICEOBJECTSCALLBACKW param0, void* param1, uint32 param2) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unacquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1) GetDeviceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) GetDeviceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDATAFORMAT* param0) SetDataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE param0) SetEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEOBJECTINSTANCEW* param0, uint32 param1, uint32 param2) GetObjectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEINSTANCEW* param0) GetDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1, in Guid param2) Initialize;
	}


	public HRESULT GetCapabilities(DIDEVCAPS* param0) mut => VT.[Friend]GetCapabilities(&this, param0);

	public HRESULT EnumObjects(LPDIENUMDEVICEOBJECTSCALLBACKW param0, void* param1, uint32 param2) mut => VT.[Friend]EnumObjects(&this, param0, param1, param2);

	public HRESULT GetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]GetProperty(&this, param0, param1);

	public HRESULT SetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]SetProperty(&this, param0, param1);

	public HRESULT Acquire() mut => VT.[Friend]Acquire(&this);

	public HRESULT Unacquire() mut => VT.[Friend]Unacquire(&this);

	public HRESULT GetDeviceState(uint32 param0, void* param1) mut => VT.[Friend]GetDeviceState(&this, param0, param1);

	public HRESULT GetDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]GetDeviceData(&this, param0, param1, param2, param3);

	public HRESULT SetDataFormat(DIDATAFORMAT* param0) mut => VT.[Friend]SetDataFormat(&this, param0);

	public HRESULT SetEventNotification(HANDLE param0) mut => VT.[Friend]SetEventNotification(&this, param0);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT GetObjectInfo(DIDEVICEOBJECTINSTANCEW* param0, uint32 param1, uint32 param2) mut => VT.[Friend]GetObjectInfo(&this, param0, param1, param2);

	public HRESULT GetDeviceInfo(DIDEVICEINSTANCEW* param0) mut => VT.[Friend]GetDeviceInfo(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1, in Guid param2) mut => VT.[Friend]Initialize(&this, param0, param1, param2);
}

[CRepr]struct IDirectInputDeviceA : IUnknown
{
	public new const Guid IID = .(0x5944e680, 0xc92e, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVCAPS* param0) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMDEVICEOBJECTSCALLBACKA param0, void* param1, uint32 param2) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unacquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1) GetDeviceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) GetDeviceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDATAFORMAT* param0) SetDataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE param0) SetEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEOBJECTINSTANCEA* param0, uint32 param1, uint32 param2) GetObjectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEINSTANCEA* param0) GetDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1, in Guid param2) Initialize;
	}


	public HRESULT GetCapabilities(DIDEVCAPS* param0) mut => VT.[Friend]GetCapabilities(&this, param0);

	public HRESULT EnumObjects(LPDIENUMDEVICEOBJECTSCALLBACKA param0, void* param1, uint32 param2) mut => VT.[Friend]EnumObjects(&this, param0, param1, param2);

	public HRESULT GetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]GetProperty(&this, param0, param1);

	public HRESULT SetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]SetProperty(&this, param0, param1);

	public HRESULT Acquire() mut => VT.[Friend]Acquire(&this);

	public HRESULT Unacquire() mut => VT.[Friend]Unacquire(&this);

	public HRESULT GetDeviceState(uint32 param0, void* param1) mut => VT.[Friend]GetDeviceState(&this, param0, param1);

	public HRESULT GetDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]GetDeviceData(&this, param0, param1, param2, param3);

	public HRESULT SetDataFormat(DIDATAFORMAT* param0) mut => VT.[Friend]SetDataFormat(&this, param0);

	public HRESULT SetEventNotification(HANDLE param0) mut => VT.[Friend]SetEventNotification(&this, param0);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT GetObjectInfo(DIDEVICEOBJECTINSTANCEA* param0, uint32 param1, uint32 param2) mut => VT.[Friend]GetObjectInfo(&this, param0, param1, param2);

	public HRESULT GetDeviceInfo(DIDEVICEINSTANCEA* param0) mut => VT.[Friend]GetDeviceInfo(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1, in Guid param2) mut => VT.[Friend]Initialize(&this, param0, param1, param2);
}

[CRepr]struct IDirectInputDevice2W : IDirectInputDeviceW
{
	public new const Guid IID = .(0x5944e683, 0xc92e, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInputDeviceW.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) CreateEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMEFFECTSCALLBACKW param0, void* param1, uint32 param2) EnumEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFECTINFOW* param0, in Guid param1) GetEffectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetForceFeedbackState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) SendForceFeedbackCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) EnumCreatedEffectObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFESCAPE* param0) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Poll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) SendDeviceData;
	}


	public HRESULT CreateEffect(in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) mut => VT.[Friend]CreateEffect(&this, param0, param1, param2, param3);

	public HRESULT EnumEffects(LPDIENUMEFFECTSCALLBACKW param0, void* param1, uint32 param2) mut => VT.[Friend]EnumEffects(&this, param0, param1, param2);

	public HRESULT GetEffectInfo(DIEFFECTINFOW* param0, in Guid param1) mut => VT.[Friend]GetEffectInfo(&this, param0, param1);

	public HRESULT GetForceFeedbackState(uint32* param0) mut => VT.[Friend]GetForceFeedbackState(&this, param0);

	public HRESULT SendForceFeedbackCommand(uint32 param0) mut => VT.[Friend]SendForceFeedbackCommand(&this, param0);

	public HRESULT EnumCreatedEffectObjects(LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) mut => VT.[Friend]EnumCreatedEffectObjects(&this, param0, param1, param2);

	public HRESULT Escape(DIEFFESCAPE* param0) mut => VT.[Friend]Escape(&this, param0);

	public HRESULT Poll() mut => VT.[Friend]Poll(&this);

	public HRESULT SendDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]SendDeviceData(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInputDevice2A : IDirectInputDeviceA
{
	public new const Guid IID = .(0x5944e682, 0xc92e, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInputDeviceA.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) CreateEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMEFFECTSCALLBACKA param0, void* param1, uint32 param2) EnumEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFECTINFOA* param0, in Guid param1) GetEffectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetForceFeedbackState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) SendForceFeedbackCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) EnumCreatedEffectObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFESCAPE* param0) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Poll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) SendDeviceData;
	}


	public HRESULT CreateEffect(in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) mut => VT.[Friend]CreateEffect(&this, param0, param1, param2, param3);

	public HRESULT EnumEffects(LPDIENUMEFFECTSCALLBACKA param0, void* param1, uint32 param2) mut => VT.[Friend]EnumEffects(&this, param0, param1, param2);

	public HRESULT GetEffectInfo(DIEFFECTINFOA* param0, in Guid param1) mut => VT.[Friend]GetEffectInfo(&this, param0, param1);

	public HRESULT GetForceFeedbackState(uint32* param0) mut => VT.[Friend]GetForceFeedbackState(&this, param0);

	public HRESULT SendForceFeedbackCommand(uint32 param0) mut => VT.[Friend]SendForceFeedbackCommand(&this, param0);

	public HRESULT EnumCreatedEffectObjects(LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) mut => VT.[Friend]EnumCreatedEffectObjects(&this, param0, param1, param2);

	public HRESULT Escape(DIEFFESCAPE* param0) mut => VT.[Friend]Escape(&this, param0);

	public HRESULT Poll() mut => VT.[Friend]Poll(&this);

	public HRESULT SendDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]SendDeviceData(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInputDevice7W : IDirectInputDevice2W
{
	public new const Guid IID = .(0x57d7c6bd, 0x2356, 0x11d3, 0x8e, 0x9d, 0x00, 0xc0, 0x4f, 0x68, 0x44, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInputDevice2W.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) EnumEffectsInFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) WriteEffectToFile;
	}


	public HRESULT EnumEffectsInFile(PWSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) mut => VT.[Friend]EnumEffectsInFile(&this, param0, param1, param2, param3);

	public HRESULT WriteEffectToFile(PWSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) mut => VT.[Friend]WriteEffectToFile(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInputDevice7A : IDirectInputDevice2A
{
	public new const Guid IID = .(0x57d7c6bc, 0x2356, 0x11d3, 0x8e, 0x9d, 0x00, 0xc0, 0x4f, 0x68, 0x44, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInputDevice2A.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) EnumEffectsInFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) WriteEffectToFile;
	}


	public HRESULT EnumEffectsInFile(PSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) mut => VT.[Friend]EnumEffectsInFile(&this, param0, param1, param2, param3);

	public HRESULT WriteEffectToFile(PSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) mut => VT.[Friend]WriteEffectToFile(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInputDevice8W : IUnknown
{
	public new const Guid IID = .(0x54d41081, 0xdc15, 0x4833, 0xa4, 0x1b, 0x74, 0x8f, 0x73, 0xa3, 0x81, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVCAPS* param0) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMDEVICEOBJECTSCALLBACKW param0, void* param1, uint32 param2) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unacquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1) GetDeviceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) GetDeviceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDATAFORMAT* param0) SetDataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE param0) SetEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEOBJECTINSTANCEW* param0, uint32 param1, uint32 param2) GetObjectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEINSTANCEW* param0) GetDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1, in Guid param2) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) CreateEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMEFFECTSCALLBACKW param0, void* param1, uint32 param2) EnumEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFECTINFOW* param0, in Guid param1) GetEffectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetForceFeedbackState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) SendForceFeedbackCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) EnumCreatedEffectObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFESCAPE* param0) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Poll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) SendDeviceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) EnumEffectsInFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) WriteEffectToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIACTIONFORMATW* param0, PWSTR param1, uint32 param2) BuildActionMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIACTIONFORMATW* param0, PWSTR param1, uint32 param2) SetActionMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEIMAGEINFOHEADERW* param0) GetImageInfo;
	}


	public HRESULT GetCapabilities(DIDEVCAPS* param0) mut => VT.[Friend]GetCapabilities(&this, param0);

	public HRESULT EnumObjects(LPDIENUMDEVICEOBJECTSCALLBACKW param0, void* param1, uint32 param2) mut => VT.[Friend]EnumObjects(&this, param0, param1, param2);

	public HRESULT GetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]GetProperty(&this, param0, param1);

	public HRESULT SetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]SetProperty(&this, param0, param1);

	public HRESULT Acquire() mut => VT.[Friend]Acquire(&this);

	public HRESULT Unacquire() mut => VT.[Friend]Unacquire(&this);

	public HRESULT GetDeviceState(uint32 param0, void* param1) mut => VT.[Friend]GetDeviceState(&this, param0, param1);

	public HRESULT GetDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]GetDeviceData(&this, param0, param1, param2, param3);

	public HRESULT SetDataFormat(DIDATAFORMAT* param0) mut => VT.[Friend]SetDataFormat(&this, param0);

	public HRESULT SetEventNotification(HANDLE param0) mut => VT.[Friend]SetEventNotification(&this, param0);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT GetObjectInfo(DIDEVICEOBJECTINSTANCEW* param0, uint32 param1, uint32 param2) mut => VT.[Friend]GetObjectInfo(&this, param0, param1, param2);

	public HRESULT GetDeviceInfo(DIDEVICEINSTANCEW* param0) mut => VT.[Friend]GetDeviceInfo(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1, in Guid param2) mut => VT.[Friend]Initialize(&this, param0, param1, param2);

	public HRESULT CreateEffect(in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) mut => VT.[Friend]CreateEffect(&this, param0, param1, param2, param3);

	public HRESULT EnumEffects(LPDIENUMEFFECTSCALLBACKW param0, void* param1, uint32 param2) mut => VT.[Friend]EnumEffects(&this, param0, param1, param2);

	public HRESULT GetEffectInfo(DIEFFECTINFOW* param0, in Guid param1) mut => VT.[Friend]GetEffectInfo(&this, param0, param1);

	public HRESULT GetForceFeedbackState(uint32* param0) mut => VT.[Friend]GetForceFeedbackState(&this, param0);

	public HRESULT SendForceFeedbackCommand(uint32 param0) mut => VT.[Friend]SendForceFeedbackCommand(&this, param0);

	public HRESULT EnumCreatedEffectObjects(LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) mut => VT.[Friend]EnumCreatedEffectObjects(&this, param0, param1, param2);

	public HRESULT Escape(DIEFFESCAPE* param0) mut => VT.[Friend]Escape(&this, param0);

	public HRESULT Poll() mut => VT.[Friend]Poll(&this);

	public HRESULT SendDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]SendDeviceData(&this, param0, param1, param2, param3);

	public HRESULT EnumEffectsInFile(PWSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) mut => VT.[Friend]EnumEffectsInFile(&this, param0, param1, param2, param3);

	public HRESULT WriteEffectToFile(PWSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) mut => VT.[Friend]WriteEffectToFile(&this, param0, param1, param2, param3);

	public HRESULT BuildActionMap(DIACTIONFORMATW* param0, PWSTR param1, uint32 param2) mut => VT.[Friend]BuildActionMap(&this, param0, param1, param2);

	public HRESULT SetActionMap(DIACTIONFORMATW* param0, PWSTR param1, uint32 param2) mut => VT.[Friend]SetActionMap(&this, param0, param1, param2);

	public HRESULT GetImageInfo(DIDEVICEIMAGEINFOHEADERW* param0) mut => VT.[Friend]GetImageInfo(&this, param0);
}

[CRepr]struct IDirectInputDevice8A : IUnknown
{
	public new const Guid IID = .(0x54d41080, 0xdc15, 0x4833, 0xa4, 0x1b, 0x74, 0x8f, 0x73, 0xa3, 0x81, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVCAPS* param0) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMDEVICEOBJECTSCALLBACKA param0, void* param1, uint32 param2) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIPROPHEADER* param1) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unacquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1) GetDeviceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) GetDeviceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDATAFORMAT* param0) SetDataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE param0) SetEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEOBJECTINSTANCEA* param0, uint32 param1, uint32 param2) GetObjectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEINSTANCEA* param0) GetDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1, in Guid param2) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) CreateEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMEFFECTSCALLBACKA param0, void* param1, uint32 param2) EnumEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFECTINFOA* param0, in Guid param1) GetEffectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetForceFeedbackState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) SendForceFeedbackCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) EnumCreatedEffectObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIEFFESCAPE* param0) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Poll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) SendDeviceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) EnumEffectsInFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) WriteEffectToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIACTIONFORMATA* param0, PSTR param1, uint32 param2) BuildActionMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIACTIONFORMATA* param0, PSTR param1, uint32 param2) SetActionMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDEVICEIMAGEINFOHEADERA* param0) GetImageInfo;
	}


	public HRESULT GetCapabilities(DIDEVCAPS* param0) mut => VT.[Friend]GetCapabilities(&this, param0);

	public HRESULT EnumObjects(LPDIENUMDEVICEOBJECTSCALLBACKA param0, void* param1, uint32 param2) mut => VT.[Friend]EnumObjects(&this, param0, param1, param2);

	public HRESULT GetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]GetProperty(&this, param0, param1);

	public HRESULT SetProperty(in Guid param0, DIPROPHEADER* param1) mut => VT.[Friend]SetProperty(&this, param0, param1);

	public HRESULT Acquire() mut => VT.[Friend]Acquire(&this);

	public HRESULT Unacquire() mut => VT.[Friend]Unacquire(&this);

	public HRESULT GetDeviceState(uint32 param0, void* param1) mut => VT.[Friend]GetDeviceState(&this, param0, param1);

	public HRESULT GetDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]GetDeviceData(&this, param0, param1, param2, param3);

	public HRESULT SetDataFormat(DIDATAFORMAT* param0) mut => VT.[Friend]SetDataFormat(&this, param0);

	public HRESULT SetEventNotification(HANDLE param0) mut => VT.[Friend]SetEventNotification(&this, param0);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT GetObjectInfo(DIDEVICEOBJECTINSTANCEA* param0, uint32 param1, uint32 param2) mut => VT.[Friend]GetObjectInfo(&this, param0, param1, param2);

	public HRESULT GetDeviceInfo(DIDEVICEINSTANCEA* param0) mut => VT.[Friend]GetDeviceInfo(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1, in Guid param2) mut => VT.[Friend]Initialize(&this, param0, param1, param2);

	public HRESULT CreateEffect(in Guid param0, DIEFFECT* param1, IDirectInputEffect** param2, IUnknown* param3) mut => VT.[Friend]CreateEffect(&this, param0, param1, param2, param3);

	public HRESULT EnumEffects(LPDIENUMEFFECTSCALLBACKA param0, void* param1, uint32 param2) mut => VT.[Friend]EnumEffects(&this, param0, param1, param2);

	public HRESULT GetEffectInfo(DIEFFECTINFOA* param0, in Guid param1) mut => VT.[Friend]GetEffectInfo(&this, param0, param1);

	public HRESULT GetForceFeedbackState(uint32* param0) mut => VT.[Friend]GetForceFeedbackState(&this, param0);

	public HRESULT SendForceFeedbackCommand(uint32 param0) mut => VT.[Friend]SendForceFeedbackCommand(&this, param0);

	public HRESULT EnumCreatedEffectObjects(LPDIENUMCREATEDEFFECTOBJECTSCALLBACK param0, void* param1, uint32 param2) mut => VT.[Friend]EnumCreatedEffectObjects(&this, param0, param1, param2);

	public HRESULT Escape(DIEFFESCAPE* param0) mut => VT.[Friend]Escape(&this, param0);

	public HRESULT Poll() mut => VT.[Friend]Poll(&this);

	public HRESULT SendDeviceData(uint32 param0, DIDEVICEOBJECTDATA* param1, uint32* param2, uint32 param3) mut => VT.[Friend]SendDeviceData(&this, param0, param1, param2, param3);

	public HRESULT EnumEffectsInFile(PSTR param0, LPDIENUMEFFECTSINFILECALLBACK param1, void* param2, uint32 param3) mut => VT.[Friend]EnumEffectsInFile(&this, param0, param1, param2, param3);

	public HRESULT WriteEffectToFile(PSTR param0, uint32 param1, DIFILEEFFECT* param2, uint32 param3) mut => VT.[Friend]WriteEffectToFile(&this, param0, param1, param2, param3);

	public HRESULT BuildActionMap(DIACTIONFORMATA* param0, PSTR param1, uint32 param2) mut => VT.[Friend]BuildActionMap(&this, param0, param1, param2);

	public HRESULT SetActionMap(DIACTIONFORMATA* param0, PSTR param1, uint32 param2) mut => VT.[Friend]SetActionMap(&this, param0, param1, param2);

	public HRESULT GetImageInfo(DIDEVICEIMAGEINFOHEADERA* param0) mut => VT.[Friend]GetImageInfo(&this, param0);
}

[CRepr]struct IDirectInputW : IUnknown
{
	public new const Guid IID = .(0x89521361, 0xaa8a, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, IDirectInputDeviceW** param1, IUnknown* param2) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, LPDIENUMDEVICESCALLBACKW param1, void* param2, uint32 param3) EnumDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0) GetDeviceStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1) Initialize;
	}


	public HRESULT CreateDevice(in Guid param0, IDirectInputDeviceW** param1, IUnknown* param2) mut => VT.[Friend]CreateDevice(&this, param0, param1, param2);

	public HRESULT EnumDevices(uint32 param0, LPDIENUMDEVICESCALLBACKW param1, void* param2, uint32 param3) mut => VT.[Friend]EnumDevices(&this, param0, param1, param2, param3);

	public HRESULT GetDeviceStatus(in Guid param0) mut => VT.[Friend]GetDeviceStatus(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1) mut => VT.[Friend]Initialize(&this, param0, param1);
}

[CRepr]struct IDirectInputA : IUnknown
{
	public new const Guid IID = .(0x89521360, 0xaa8a, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, IDirectInputDeviceA** param1, IUnknown* param2) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, LPDIENUMDEVICESCALLBACKA param1, void* param2, uint32 param3) EnumDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0) GetDeviceStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1) Initialize;
	}


	public HRESULT CreateDevice(in Guid param0, IDirectInputDeviceA** param1, IUnknown* param2) mut => VT.[Friend]CreateDevice(&this, param0, param1, param2);

	public HRESULT EnumDevices(uint32 param0, LPDIENUMDEVICESCALLBACKA param1, void* param2, uint32 param3) mut => VT.[Friend]EnumDevices(&this, param0, param1, param2, param3);

	public HRESULT GetDeviceStatus(in Guid param0) mut => VT.[Friend]GetDeviceStatus(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1) mut => VT.[Friend]Initialize(&this, param0, param1);
}

[CRepr]struct IDirectInput2W : IDirectInputW
{
	public new const Guid IID = .(0x5944e663, 0xaa8a, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInputW.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, PWSTR param1, Guid* param2) FindDevice;
	}


	public HRESULT FindDevice(in Guid param0, PWSTR param1, Guid* param2) mut => VT.[Friend]FindDevice(&this, param0, param1, param2);
}

[CRepr]struct IDirectInput2A : IDirectInputA
{
	public new const Guid IID = .(0x5944e662, 0xaa8a, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInputA.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, PSTR param1, Guid* param2) FindDevice;
	}


	public HRESULT FindDevice(in Guid param0, PSTR param1, Guid* param2) mut => VT.[Friend]FindDevice(&this, param0, param1, param2);
}

[CRepr]struct IDirectInput7W : IDirectInput2W
{
	public new const Guid IID = .(0x9a4cb685, 0x236d, 0x11d3, 0x8e, 0x9d, 0x00, 0xc0, 0x4f, 0x68, 0x44, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInput2W.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, in Guid param1, void** param2, IUnknown* param3) CreateDeviceEx;
	}


	public HRESULT CreateDeviceEx(in Guid param0, in Guid param1, void** param2, IUnknown* param3) mut => VT.[Friend]CreateDeviceEx(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInput7A : IDirectInput2A
{
	public new const Guid IID = .(0x9a4cb684, 0x236d, 0x11d3, 0x8e, 0x9d, 0x00, 0xc0, 0x4f, 0x68, 0x44, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectInput2A.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, in Guid param1, void** param2, IUnknown* param3) CreateDeviceEx;
	}


	public HRESULT CreateDeviceEx(in Guid param0, in Guid param1, void** param2, IUnknown* param3) mut => VT.[Friend]CreateDeviceEx(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInput8W : IUnknown
{
	public new const Guid IID = .(0xbf798031, 0x483a, 0x4da2, 0xaa, 0x99, 0x5d, 0x64, 0xed, 0x36, 0x97, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, IDirectInputDevice8W** param1, IUnknown* param2) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, LPDIENUMDEVICESCALLBACKW param1, void* param2, uint32 param3) EnumDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0) GetDeviceStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, PWSTR param1, Guid* param2) FindDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, DIACTIONFORMATW* param1, LPDIENUMDEVICESBYSEMANTICSCBW param2, void* param3, uint32 param4) EnumDevicesBySemantics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDICONFIGUREDEVICESCALLBACK param0, DICONFIGUREDEVICESPARAMSW* param1, uint32 param2, void* param3) ConfigureDevices;
	}


	public HRESULT CreateDevice(in Guid param0, IDirectInputDevice8W** param1, IUnknown* param2) mut => VT.[Friend]CreateDevice(&this, param0, param1, param2);

	public HRESULT EnumDevices(uint32 param0, LPDIENUMDEVICESCALLBACKW param1, void* param2, uint32 param3) mut => VT.[Friend]EnumDevices(&this, param0, param1, param2, param3);

	public HRESULT GetDeviceStatus(in Guid param0) mut => VT.[Friend]GetDeviceStatus(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT FindDevice(in Guid param0, PWSTR param1, Guid* param2) mut => VT.[Friend]FindDevice(&this, param0, param1, param2);

	public HRESULT EnumDevicesBySemantics(PWSTR param0, DIACTIONFORMATW* param1, LPDIENUMDEVICESBYSEMANTICSCBW param2, void* param3, uint32 param4) mut => VT.[Friend]EnumDevicesBySemantics(&this, param0, param1, param2, param3, param4);

	public HRESULT ConfigureDevices(LPDICONFIGUREDEVICESCALLBACK param0, DICONFIGUREDEVICESPARAMSW* param1, uint32 param2, void* param3) mut => VT.[Friend]ConfigureDevices(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInput8A : IUnknown
{
	public new const Guid IID = .(0xbf798030, 0x483a, 0x4da2, 0xaa, 0x99, 0x5d, 0x64, 0xed, 0x36, 0x97, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, IDirectInputDevice8A** param1, IUnknown* param2) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, LPDIENUMDEVICESCALLBACKA param1, void* param2, uint32 param3) EnumDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0) GetDeviceStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) RunControlPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE param0, uint32 param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, PSTR param1, Guid* param2) FindDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR param0, DIACTIONFORMATA* param1, LPDIENUMDEVICESBYSEMANTICSCBA param2, void* param3, uint32 param4) EnumDevicesBySemantics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDICONFIGUREDEVICESCALLBACK param0, DICONFIGUREDEVICESPARAMSA* param1, uint32 param2, void* param3) ConfigureDevices;
	}


	public HRESULT CreateDevice(in Guid param0, IDirectInputDevice8A** param1, IUnknown* param2) mut => VT.[Friend]CreateDevice(&this, param0, param1, param2);

	public HRESULT EnumDevices(uint32 param0, LPDIENUMDEVICESCALLBACKA param1, void* param2, uint32 param3) mut => VT.[Friend]EnumDevices(&this, param0, param1, param2, param3);

	public HRESULT GetDeviceStatus(in Guid param0) mut => VT.[Friend]GetDeviceStatus(&this, param0);

	public HRESULT RunControlPanel(HWND param0, uint32 param1) mut => VT.[Friend]RunControlPanel(&this, param0, param1);

	public HRESULT Initialize(HINSTANCE param0, uint32 param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT FindDevice(in Guid param0, PSTR param1, Guid* param2) mut => VT.[Friend]FindDevice(&this, param0, param1, param2);

	public HRESULT EnumDevicesBySemantics(PSTR param0, DIACTIONFORMATA* param1, LPDIENUMDEVICESBYSEMANTICSCBA param2, void* param3, uint32 param4) mut => VT.[Friend]EnumDevicesBySemantics(&this, param0, param1, param2, param3, param4);

	public HRESULT ConfigureDevices(LPDICONFIGUREDEVICESCALLBACK param0, DICONFIGUREDEVICESPARAMSA* param1, uint32 param2, void* param3) mut => VT.[Friend]ConfigureDevices(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectInputEffectDriver : IUnknown
{
	public new const Guid IID = .(0x02538130, 0x898f, 0x11d0, 0x9a, 0xd0, 0x00, 0xa0, 0xc9, 0xa0, 0x6e, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, uint32 param3, void* param4) DeviceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIDRIVERVERSIONS* param0) GetVersions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, DIEFFESCAPE* param2) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1) SetGain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1) SendForceFeedbackCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIDEVICESTATE* param1) GetForceFeedbackState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32* param2, DIEFFECT* param3, uint32 param4) DownloadEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1) DestroyEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, uint32 param3) StartEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1) StopEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32* param2) GetEffectStatus;
	}


	public HRESULT DeviceID(uint32 param0, uint32 param1, uint32 param2, uint32 param3, void* param4) mut => VT.[Friend]DeviceID(&this, param0, param1, param2, param3, param4);

	public HRESULT GetVersions(DIDRIVERVERSIONS* param0) mut => VT.[Friend]GetVersions(&this, param0);

	public HRESULT Escape(uint32 param0, uint32 param1, DIEFFESCAPE* param2) mut => VT.[Friend]Escape(&this, param0, param1, param2);

	public HRESULT SetGain(uint32 param0, uint32 param1) mut => VT.[Friend]SetGain(&this, param0, param1);

	public HRESULT SendForceFeedbackCommand(uint32 param0, uint32 param1) mut => VT.[Friend]SendForceFeedbackCommand(&this, param0, param1);

	public HRESULT GetForceFeedbackState(uint32 param0, DIDEVICESTATE* param1) mut => VT.[Friend]GetForceFeedbackState(&this, param0, param1);

	public HRESULT DownloadEffect(uint32 param0, uint32 param1, uint32* param2, DIEFFECT* param3, uint32 param4) mut => VT.[Friend]DownloadEffect(&this, param0, param1, param2, param3, param4);

	public HRESULT DestroyEffect(uint32 param0, uint32 param1) mut => VT.[Friend]DestroyEffect(&this, param0, param1);

	public HRESULT StartEffect(uint32 param0, uint32 param1, uint32 param2, uint32 param3) mut => VT.[Friend]StartEffect(&this, param0, param1, param2, param3);

	public HRESULT StopEffect(uint32 param0, uint32 param1) mut => VT.[Friend]StopEffect(&this, param0, param1);

	public HRESULT GetEffectStatus(uint32 param0, uint32 param1, uint32* param2) mut => VT.[Friend]GetEffectStatus(&this, param0, param1, param2);
}

[CRepr]struct IDirectInputJoyConfig : IUnknown
{
	public new const Guid IID = .(0x1de12ab1, 0xc9f5, 0x11cf, 0xbf, 0xc7, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unacquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SendNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIJOYTYPECALLBACK param0, void* param1) EnumTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2) GetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2) SetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0) DeleteType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIJOYCONFIG* param1, uint32 param2) GetConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIJOYCONFIG* param1, uint32 param2) SetConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) DeleteConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIJOYUSERVALUES* param0, uint32 param1) GetUserValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIJOYUSERVALUES* param0, uint32 param1) SetUserValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, in Guid param1) AddNewHardware;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, uint32 param1, HKEY* param2) OpenTypeKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, HKEY* param2) OpenConfigKey;
	}


	public HRESULT Acquire() mut => VT.[Friend]Acquire(&this);

	public HRESULT Unacquire() mut => VT.[Friend]Unacquire(&this);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT SendNotify() mut => VT.[Friend]SendNotify(&this);

	public HRESULT EnumTypes(LPDIJOYTYPECALLBACK param0, void* param1) mut => VT.[Friend]EnumTypes(&this, param0, param1);

	public HRESULT GetTypeInfo(PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2) mut => VT.[Friend]GetTypeInfo(&this, param0, param1, param2);

	public HRESULT SetTypeInfo(PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2) mut => VT.[Friend]SetTypeInfo(&this, param0, param1, param2);

	public HRESULT DeleteType(PWSTR param0) mut => VT.[Friend]DeleteType(&this, param0);

	public HRESULT GetConfig(uint32 param0, DIJOYCONFIG* param1, uint32 param2) mut => VT.[Friend]GetConfig(&this, param0, param1, param2);

	public HRESULT SetConfig(uint32 param0, DIJOYCONFIG* param1, uint32 param2) mut => VT.[Friend]SetConfig(&this, param0, param1, param2);

	public HRESULT DeleteConfig(uint32 param0) mut => VT.[Friend]DeleteConfig(&this, param0);

	public HRESULT GetUserValues(DIJOYUSERVALUES* param0, uint32 param1) mut => VT.[Friend]GetUserValues(&this, param0, param1);

	public HRESULT SetUserValues(DIJOYUSERVALUES* param0, uint32 param1) mut => VT.[Friend]SetUserValues(&this, param0, param1);

	public HRESULT AddNewHardware(HWND param0, in Guid param1) mut => VT.[Friend]AddNewHardware(&this, param0, param1);

	public HRESULT OpenTypeKey(PWSTR param0, uint32 param1, HKEY* param2) mut => VT.[Friend]OpenTypeKey(&this, param0, param1, param2);

	public HRESULT OpenConfigKey(uint32 param0, uint32 param1, HKEY* param2) mut => VT.[Friend]OpenConfigKey(&this, param0, param1, param2);
}

[CRepr]struct IDirectInputJoyConfig8 : IUnknown
{
	public new const Guid IID = .(0xeb0d7dfa, 0x1990, 0x4f27, 0xb4, 0xd6, 0xed, 0xf2, 0xee, 0xc4, 0xa4, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unacquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SendNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPDIJOYTYPECALLBACK param0, void* param1) EnumTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2) GetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2, PWSTR param3) SetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0) DeleteType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIJOYCONFIG* param1, uint32 param2) GetConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DIJOYCONFIG* param1, uint32 param2) SetConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) DeleteConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIJOYUSERVALUES* param0, uint32 param1) GetUserValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIJOYUSERVALUES* param0, uint32 param1) SetUserValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, in Guid param1) AddNewHardware;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0, uint32 param1, HKEY* param2) OpenTypeKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY* param0) OpenAppStatusKey;
	}


	public HRESULT Acquire() mut => VT.[Friend]Acquire(&this);

	public HRESULT Unacquire() mut => VT.[Friend]Unacquire(&this);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT SendNotify() mut => VT.[Friend]SendNotify(&this);

	public HRESULT EnumTypes(LPDIJOYTYPECALLBACK param0, void* param1) mut => VT.[Friend]EnumTypes(&this, param0, param1);

	public HRESULT GetTypeInfo(PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2) mut => VT.[Friend]GetTypeInfo(&this, param0, param1, param2);

	public HRESULT SetTypeInfo(PWSTR param0, DIJOYTYPEINFO* param1, uint32 param2, PWSTR param3) mut => VT.[Friend]SetTypeInfo(&this, param0, param1, param2, param3);

	public HRESULT DeleteType(PWSTR param0) mut => VT.[Friend]DeleteType(&this, param0);

	public HRESULT GetConfig(uint32 param0, DIJOYCONFIG* param1, uint32 param2) mut => VT.[Friend]GetConfig(&this, param0, param1, param2);

	public HRESULT SetConfig(uint32 param0, DIJOYCONFIG* param1, uint32 param2) mut => VT.[Friend]SetConfig(&this, param0, param1, param2);

	public HRESULT DeleteConfig(uint32 param0) mut => VT.[Friend]DeleteConfig(&this, param0);

	public HRESULT GetUserValues(DIJOYUSERVALUES* param0, uint32 param1) mut => VT.[Friend]GetUserValues(&this, param0, param1);

	public HRESULT SetUserValues(DIJOYUSERVALUES* param0, uint32 param1) mut => VT.[Friend]SetUserValues(&this, param0, param1);

	public HRESULT AddNewHardware(HWND param0, in Guid param1) mut => VT.[Friend]AddNewHardware(&this, param0, param1);

	public HRESULT OpenTypeKey(PWSTR param0, uint32 param1, HKEY* param2) mut => VT.[Friend]OpenTypeKey(&this, param0, param1, param2);

	public HRESULT OpenAppStatusKey(HKEY* param0) mut => VT.[Friend]OpenAppStatusKey(&this, param0);
}

#endregion

#region Functions
public static
{
	[Import("DINPUT8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectInput8Create(HINSTANCE hinst, uint32 dwVersion, in Guid riidltf, void** ppvOut, IUnknown* punkOuter);

	[Import("WINMM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 joyConfigChanged(uint32 dwFlags);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetCaps(int PreparsedData, HIDP_CAPS* Capabilities);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetLinkCollectionNodes(HIDP_LINK_COLLECTION_NODE* LinkCollectionNodes, uint32* LinkCollectionNodesLength, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetSpecificButtonCaps(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, HIDP_BUTTON_CAPS* ButtonCaps, uint16* ButtonCapsLength, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetButtonCaps(HIDP_REPORT_TYPE ReportType, HIDP_BUTTON_CAPS* ButtonCaps, uint16* ButtonCapsLength, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetSpecificValueCaps(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, HIDP_VALUE_CAPS* ValueCaps, uint16* ValueCapsLength, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetValueCaps(HIDP_REPORT_TYPE ReportType, HIDP_VALUE_CAPS* ValueCaps, uint16* ValueCapsLength, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetExtendedAttributes(HIDP_REPORT_TYPE ReportType, uint16 DataIndex, int PreparsedData, HIDP_EXTENDED_ATTRIBUTES* Attributes, uint32* LengthAttributes);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_InitializeReportForID(HIDP_REPORT_TYPE ReportType, uint8 ReportID, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_SetData(HIDP_REPORT_TYPE ReportType, HIDP_DATA* DataList, uint32* DataLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetData(HIDP_REPORT_TYPE ReportType, HIDP_DATA* DataList, uint32* DataLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HidP_MaxDataListLength(HIDP_REPORT_TYPE ReportType, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_SetUsages(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16* UsageList, uint32* UsageLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_UnsetUsages(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16* UsageList, uint32* UsageLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetUsages(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16* UsageList, uint32* UsageLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetUsagesEx(HIDP_REPORT_TYPE ReportType, uint16 LinkCollection, USAGE_AND_PAGE* ButtonList, uint32* UsageLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HidP_MaxUsageListLength(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_SetUsageValue(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, uint32 UsageValue, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_SetScaledUsageValue(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, int32 UsageValue, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_SetUsageValueArray(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, PSTR UsageValue, uint16 UsageValueByteLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetUsageValue(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, uint32* UsageValue, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetScaledUsageValue(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, int32* UsageValue, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetUsageValueArray(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, PSTR UsageValue, uint16 UsageValueByteLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_UsageListDifference(uint16* PreviousUsageList, uint16* CurrentUsageList, uint16* BreakUsageList, uint16* MakeUsageList, uint32 UsageListLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_GetButtonArray(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, HIDP_BUTTON_ARRAY_DATA* ButtonData, uint16* ButtonDataLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_SetButtonArray(HIDP_REPORT_TYPE ReportType, uint16 UsagePage, uint16 LinkCollection, uint16 Usage, HIDP_BUTTON_ARRAY_DATA* ButtonData, uint16 ButtonDataLength, int PreparsedData, PSTR Report, uint32 ReportLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS HidP_TranslateUsagesToI8042ScanCodes(uint16* ChangedUsageList, uint32 UsageListLength, HIDP_KEYBOARD_DIRECTION KeyAction, HIDP_KEYBOARD_MODIFIER_STATE* ModifierState, PHIDP_INSERT_SCANCODES InsertCodesProcedure, void* InsertCodesContext);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetAttributes(HANDLE HidDeviceObject, HIDD_ATTRIBUTES* Attributes);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HidD_GetHidGuid(Guid* HidGuid);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetPreparsedData(HANDLE HidDeviceObject, int* PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_FreePreparsedData(int PreparsedData);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_FlushQueue(HANDLE HidDeviceObject);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetConfiguration(HANDLE HidDeviceObject, HIDD_CONFIGURATION* Configuration, uint32 ConfigurationLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_SetConfiguration(HANDLE HidDeviceObject, HIDD_CONFIGURATION* Configuration, uint32 ConfigurationLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetFeature(HANDLE HidDeviceObject, void* ReportBuffer, uint32 ReportBufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_SetFeature(HANDLE HidDeviceObject, void* ReportBuffer, uint32 ReportBufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetInputReport(HANDLE HidDeviceObject, void* ReportBuffer, uint32 ReportBufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_SetOutputReport(HANDLE HidDeviceObject, void* ReportBuffer, uint32 ReportBufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetNumInputBuffers(HANDLE HidDeviceObject, uint32* NumberBuffers);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_SetNumInputBuffers(HANDLE HidDeviceObject, uint32 NumberBuffers);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetPhysicalDescriptor(HANDLE HidDeviceObject, void* Buffer, uint32 BufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetManufacturerString(HANDLE HidDeviceObject, void* Buffer, uint32 BufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetProductString(HANDLE HidDeviceObject, void* Buffer, uint32 BufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetIndexedString(HANDLE HidDeviceObject, uint32 StringIndex, void* Buffer, uint32 BufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetSerialNumberString(HANDLE HidDeviceObject, void* Buffer, uint32 BufferLength);

	[Import("HID.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN HidD_GetMsGenreDescriptor(HANDLE HidDeviceObject, void* Buffer, uint32 BufferLength);

}
#endregion
