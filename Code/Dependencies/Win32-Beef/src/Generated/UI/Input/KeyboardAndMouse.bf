using Win32.Foundation;
using Win32.UI.TextServices;
using System;

namespace Win32.UI.Input.KeyboardAndMouse;

#region Constants
public static
{
	public const uint32 EXTENDED_BIT = 16777216;
	public const uint32 DONTCARE_BIT = 33554432;
	public const uint32 FAKE_KEYSTROKE = 33554432;
	public const uint32 KBDBASE = 0;
	public const uint32 KBDSHIFT = 1;
	public const uint32 KBDCTRL = 2;
	public const uint32 KBDALT = 4;
	public const uint32 KBDKANA = 8;
	public const uint32 KBDROYA = 16;
	public const uint32 KBDLOYA = 32;
	public const uint32 KBDGRPSELTAP = 128;
	public const uint32 GRAVE = 768;
	public const uint32 ACUTE = 769;
	public const uint32 CIRCUMFLEX = 770;
	public const uint32 TILDE = 771;
	public const uint32 MACRON = 772;
	public const uint32 OVERSCORE = 773;
	public const uint32 BREVE = 774;
	public const uint32 DOT_ABOVE = 775;
	public const uint32 UMLAUT = 776;
	public const uint32 DIARESIS = 776;
	public const uint32 HOOK_ABOVE = 777;
	public const uint32 RING = 778;
	public const uint32 DOUBLE_ACUTE = 779;
	public const uint32 HACEK = 780;
	public const uint32 CEDILLA = 807;
	public const uint32 OGONEK = 808;
	public const uint32 TONOS = 900;
	public const uint32 DIARESIS_TONOS = 901;
	public const String wszGRAVE = "̀";
	public const String wszACUTE = "́";
	public const String wszCIRCUMFLEX = "̂";
	public const String wszTILDE = "̃";
	public const String wszMACRON = "̄";
	public const String wszOVERSCORE = "̅";
	public const String wszBREVE = "̆";
	public const String wszDOT_ABOVE = "̇";
	public const String wszUMLAUT = "̈";
	public const String wszHOOK_ABOVE = "̉";
	public const String wszRING = "̊";
	public const String wszDOUBLE_ACUTE = "̋";
	public const String wszHACEK = "̌";
	public const String wszCEDILLA = "̧";
	public const String wszOGONEK = "̨";
	public const String wszTONOS = "΄";
	public const String wszDIARESIS_TONOS = "΅";
	public const uint32 SHFT_INVALID = 15;
	public const uint32 WCH_NONE = 61440;
	public const uint32 WCH_DEAD = 61441;
	public const uint32 WCH_LGTR = 61442;
	public const uint32 CAPLOK = 1;
	public const uint32 SGCAPS = 2;
	public const uint32 CAPLOKALTGR = 4;
	public const uint32 KANALOK = 8;
	public const uint32 GRPSELTAP = 128;
	public const uint32 DKF_DEAD = 1;
	public const uint32 KBD_VERSION = 1;
	public const uint32 KLLF_ALTGR = 1;
	public const uint32 KLLF_SHIFTLOCK = 2;
	public const uint32 KLLF_LRM_RLM = 4;
	public const uint32 KLLF_GLOBAL_ATTRS = 2;
	public const uint32 KBDTABLE_MULTI_MAX = 8;
	public const uint32 KEYBOARD_TYPE_GENERIC_101 = 4;
	public const uint32 KEYBOARD_TYPE_JAPAN = 7;
	public const uint32 KEYBOARD_TYPE_KOREA = 8;
	public const uint32 KEYBOARD_TYPE_UNKNOWN = 81;
	public const uint32 NLSKBD_OEM_MICROSOFT = 0;
	public const uint32 NLSKBD_OEM_AX = 1;
	public const uint32 NLSKBD_OEM_EPSON = 4;
	public const uint32 NLSKBD_OEM_FUJITSU = 5;
	public const uint32 NLSKBD_OEM_IBM = 7;
	public const uint32 NLSKBD_OEM_MATSUSHITA = 10;
	public const uint32 NLSKBD_OEM_NEC = 13;
	public const uint32 NLSKBD_OEM_TOSHIBA = 18;
	public const uint32 NLSKBD_OEM_DEC = 24;
	public const uint32 MICROSOFT_KBD_101_TYPE = 0;
	public const uint32 MICROSOFT_KBD_AX_TYPE = 1;
	public const uint32 MICROSOFT_KBD_106_TYPE = 2;
	public const uint32 MICROSOFT_KBD_002_TYPE = 3;
	public const uint32 MICROSOFT_KBD_001_TYPE = 4;
	public const uint32 MICROSOFT_KBD_FUNC = 12;
	public const uint32 AX_KBD_DESKTOP_TYPE = 1;
	public const uint32 FMR_KBD_JIS_TYPE = 0;
	public const uint32 FMR_KBD_OASYS_TYPE = 1;
	public const uint32 FMV_KBD_OASYS_TYPE = 2;
	public const uint32 NEC_KBD_NORMAL_TYPE = 1;
	public const uint32 NEC_KBD_N_MODE_TYPE = 2;
	public const uint32 NEC_KBD_H_MODE_TYPE = 3;
	public const uint32 NEC_KBD_LAPTOP_TYPE = 4;
	public const uint32 NEC_KBD_106_TYPE = 5;
	public const uint32 TOSHIBA_KBD_DESKTOP_TYPE = 13;
	public const uint32 TOSHIBA_KBD_LAPTOP_TYPE = 15;
	public const uint32 DEC_KBD_ANSI_LAYOUT_TYPE = 1;
	public const uint32 DEC_KBD_JIS_LAYOUT_TYPE = 2;
	public const uint32 MICROSOFT_KBD_101A_TYPE = 0;
	public const uint32 MICROSOFT_KBD_101B_TYPE = 4;
	public const uint32 MICROSOFT_KBD_101C_TYPE = 5;
	public const uint32 MICROSOFT_KBD_103_TYPE = 6;
	public const uint32 NLSKBD_INFO_SEND_IME_NOTIFICATION = 1;
	public const uint32 NLSKBD_INFO_ACCESSIBILITY_KEYMAP = 2;
	public const uint32 NLSKBD_INFO_EMURATE_101_KEYBOARD = 16;
	public const uint32 NLSKBD_INFO_EMURATE_106_KEYBOARD = 32;
	public const uint32 KBDNLS_TYPE_NULL = 0;
	public const uint32 KBDNLS_TYPE_NORMAL = 1;
	public const uint32 KBDNLS_TYPE_TOGGLE = 2;
	public const uint32 KBDNLS_INDEX_NORMAL = 1;
	public const uint32 KBDNLS_INDEX_ALT = 2;
	public const uint32 KBDNLS_NULL = 0;
	public const uint32 KBDNLS_NOEVENT = 1;
	public const uint32 KBDNLS_SEND_BASE_VK = 2;
	public const uint32 KBDNLS_SEND_PARAM_VK = 3;
	public const uint32 KBDNLS_KANALOCK = 4;
	public const uint32 KBDNLS_ALPHANUM = 5;
	public const uint32 KBDNLS_HIRAGANA = 6;
	public const uint32 KBDNLS_KATAKANA = 7;
	public const uint32 KBDNLS_SBCSDBCS = 8;
	public const uint32 KBDNLS_ROMAN = 9;
	public const uint32 KBDNLS_CODEINPUT = 10;
	public const uint32 KBDNLS_HELP_OR_END = 11;
	public const uint32 KBDNLS_HOME_OR_CLEAR = 12;
	public const uint32 KBDNLS_NUMPAD = 13;
	public const uint32 KBDNLS_KANAEVENT = 14;
	public const uint32 KBDNLS_CONV_OR_NONCONV = 15;
	public const uint32 KBD_TYPE = 4;
	public const uint32 VK__none_ = 255;
	public const uint32 VK_ABNT_C1 = 193;
	public const uint32 VK_ABNT_C2 = 194;
	public const uint32 SCANCODE_LSHIFT = 42;
	public const uint32 SCANCODE_RSHIFT = 54;
	public const uint32 SCANCODE_CTRL = 29;
	public const uint32 SCANCODE_ALT = 56;
	public const uint32 SCANCODE_NUMPAD_FIRST = 71;
	public const uint32 SCANCODE_NUMPAD_LAST = 82;
	public const uint32 SCANCODE_LWIN = 91;
	public const uint32 SCANCODE_RWIN = 92;
	public const uint32 SCANCODE_THAI_LAYOUT_TOGGLE = 41;
	public const uint32 VK_DBE_ALPHANUMERIC = 240;
	public const uint32 VK_DBE_KATAKANA = 241;
	public const uint32 VK_DBE_HIRAGANA = 242;
	public const uint32 VK_DBE_SBCSCHAR = 243;
	public const uint32 VK_DBE_DBCSCHAR = 244;
	public const uint32 VK_DBE_ROMAN = 245;
	public const uint32 VK_DBE_NOROMAN = 246;
	public const uint32 VK_DBE_ENTERWORDREGISTERMODE = 247;
	public const uint32 VK_DBE_ENTERIMECONFIGMODE = 248;
	public const uint32 VK_DBE_FLUSHSTRING = 249;
	public const uint32 VK_DBE_CODEINPUT = 250;
	public const uint32 VK_DBE_NOCODEINPUT = 251;
	public const uint32 VK_DBE_DETERMINESTRING = 252;
	public const uint32 VK_DBE_ENTERDLGCONVERSIONMODE = 253;
}
#endregion

#region Enums

[AllowDuplicates]
public enum HOT_KEY_MODIFIERS : uint32
{
	MOD_ALT = 1,
	MOD_CONTROL = 2,
	MOD_NOREPEAT = 16384,
	MOD_SHIFT = 4,
	MOD_WIN = 8,
}


[AllowDuplicates]
public enum ACTIVATE_KEYBOARD_LAYOUT_FLAGS : uint32
{
	KLF_REORDER = 8,
	KLF_RESET = 1073741824,
	KLF_SETFORPROCESS = 256,
	KLF_SHIFTLOCK = 65536,
	KLF_ACTIVATE = 1,
	KLF_NOTELLSHELL = 128,
	KLF_REPLACELANG = 16,
	KLF_SUBSTITUTE_OK = 2,
}


[AllowDuplicates]
public enum GET_MOUSE_MOVE_POINTS_EX_RESOLUTION : uint32
{
	GMMP_USE_DISPLAY_POINTS = 1,
	GMMP_USE_HIGH_RESOLUTION_POINTS = 2,
}


[AllowDuplicates]
public enum KEYBD_EVENT_FLAGS : uint32
{
	KEYEVENTF_EXTENDEDKEY = 1,
	KEYEVENTF_KEYUP = 2,
	KEYEVENTF_SCANCODE = 8,
	KEYEVENTF_UNICODE = 4,
}


[AllowDuplicates]
public enum MOUSE_EVENT_FLAGS : uint32
{
	MOUSEEVENTF_ABSOLUTE = 32768,
	MOUSEEVENTF_LEFTDOWN = 2,
	MOUSEEVENTF_LEFTUP = 4,
	MOUSEEVENTF_MIDDLEDOWN = 32,
	MOUSEEVENTF_MIDDLEUP = 64,
	MOUSEEVENTF_MOVE = 1,
	MOUSEEVENTF_RIGHTDOWN = 8,
	MOUSEEVENTF_RIGHTUP = 16,
	MOUSEEVENTF_WHEEL = 2048,
	MOUSEEVENTF_XDOWN = 128,
	MOUSEEVENTF_XUP = 256,
	MOUSEEVENTF_HWHEEL = 4096,
	MOUSEEVENTF_MOVE_NOCOALESCE = 8192,
	MOUSEEVENTF_VIRTUALDESK = 16384,
}


[AllowDuplicates]
public enum INPUT_TYPE : uint32
{
	INPUT_MOUSE = 0,
	INPUT_KEYBOARD = 1,
	INPUT_HARDWARE = 2,
}


[AllowDuplicates]
public enum TRACKMOUSEEVENT_FLAGS : uint32
{
	TME_CANCEL = 2147483648,
	TME_HOVER = 1,
	TME_LEAVE = 2,
	TME_NONCLIENT = 16,
	TME_QUERY = 1073741824,
}


[AllowDuplicates]
public enum VIRTUAL_KEY : uint16
{
	VK_0 = 48,
	VK_1 = 49,
	VK_2 = 50,
	VK_3 = 51,
	VK_4 = 52,
	VK_5 = 53,
	VK_6 = 54,
	VK_7 = 55,
	VK_8 = 56,
	VK_9 = 57,
	VK_A = 65,
	VK_B = 66,
	VK_C = 67,
	VK_D = 68,
	VK_E = 69,
	VK_F = 70,
	VK_G = 71,
	VK_H = 72,
	VK_I = 73,
	VK_J = 74,
	VK_K = 75,
	VK_L = 76,
	VK_M = 77,
	VK_N = 78,
	VK_O = 79,
	VK_P = 80,
	VK_Q = 81,
	VK_R = 82,
	VK_S = 83,
	VK_T = 84,
	VK_U = 85,
	VK_V = 86,
	VK_W = 87,
	VK_X = 88,
	VK_Y = 89,
	VK_Z = 90,
	VK_LBUTTON = 1,
	VK_RBUTTON = 2,
	VK_CANCEL = 3,
	VK_MBUTTON = 4,
	VK_XBUTTON1 = 5,
	VK_XBUTTON2 = 6,
	VK_BACK = 8,
	VK_TAB = 9,
	VK_CLEAR = 12,
	VK_RETURN = 13,
	VK_SHIFT = 16,
	VK_CONTROL = 17,
	VK_MENU = 18,
	VK_PAUSE = 19,
	VK_CAPITAL = 20,
	VK_KANA = 21,
	VK_HANGEUL = 21,
	VK_HANGUL = 21,
	VK_IME_ON = 22,
	VK_JUNJA = 23,
	VK_FINAL = 24,
	VK_HANJA = 25,
	VK_KANJI = 25,
	VK_IME_OFF = 26,
	VK_ESCAPE = 27,
	VK_CONVERT = 28,
	VK_NONCONVERT = 29,
	VK_ACCEPT = 30,
	VK_MODECHANGE = 31,
	VK_SPACE = 32,
	VK_PRIOR = 33,
	VK_NEXT = 34,
	VK_END = 35,
	VK_HOME = 36,
	VK_LEFT = 37,
	VK_UP = 38,
	VK_RIGHT = 39,
	VK_DOWN = 40,
	VK_SELECT = 41,
	VK_PRINT = 42,
	VK_EXECUTE = 43,
	VK_SNAPSHOT = 44,
	VK_INSERT = 45,
	VK_DELETE = 46,
	VK_HELP = 47,
	VK_LWIN = 91,
	VK_RWIN = 92,
	VK_APPS = 93,
	VK_SLEEP = 95,
	VK_NUMPAD0 = 96,
	VK_NUMPAD1 = 97,
	VK_NUMPAD2 = 98,
	VK_NUMPAD3 = 99,
	VK_NUMPAD4 = 100,
	VK_NUMPAD5 = 101,
	VK_NUMPAD6 = 102,
	VK_NUMPAD7 = 103,
	VK_NUMPAD8 = 104,
	VK_NUMPAD9 = 105,
	VK_MULTIPLY = 106,
	VK_ADD = 107,
	VK_SEPARATOR = 108,
	VK_SUBTRACT = 109,
	VK_DECIMAL = 110,
	VK_DIVIDE = 111,
	VK_F1 = 112,
	VK_F2 = 113,
	VK_F3 = 114,
	VK_F4 = 115,
	VK_F5 = 116,
	VK_F6 = 117,
	VK_F7 = 118,
	VK_F8 = 119,
	VK_F9 = 120,
	VK_F10 = 121,
	VK_F11 = 122,
	VK_F12 = 123,
	VK_F13 = 124,
	VK_F14 = 125,
	VK_F15 = 126,
	VK_F16 = 127,
	VK_F17 = 128,
	VK_F18 = 129,
	VK_F19 = 130,
	VK_F20 = 131,
	VK_F21 = 132,
	VK_F22 = 133,
	VK_F23 = 134,
	VK_F24 = 135,
	VK_NAVIGATION_VIEW = 136,
	VK_NAVIGATION_MENU = 137,
	VK_NAVIGATION_UP = 138,
	VK_NAVIGATION_DOWN = 139,
	VK_NAVIGATION_LEFT = 140,
	VK_NAVIGATION_RIGHT = 141,
	VK_NAVIGATION_ACCEPT = 142,
	VK_NAVIGATION_CANCEL = 143,
	VK_NUMLOCK = 144,
	VK_SCROLL = 145,
	VK_OEM_NEC_EQUAL = 146,
	VK_OEM_FJ_JISHO = 146,
	VK_OEM_FJ_MASSHOU = 147,
	VK_OEM_FJ_TOUROKU = 148,
	VK_OEM_FJ_LOYA = 149,
	VK_OEM_FJ_ROYA = 150,
	VK_LSHIFT = 160,
	VK_RSHIFT = 161,
	VK_LCONTROL = 162,
	VK_RCONTROL = 163,
	VK_LMENU = 164,
	VK_RMENU = 165,
	VK_BROWSER_BACK = 166,
	VK_BROWSER_FORWARD = 167,
	VK_BROWSER_REFRESH = 168,
	VK_BROWSER_STOP = 169,
	VK_BROWSER_SEARCH = 170,
	VK_BROWSER_FAVORITES = 171,
	VK_BROWSER_HOME = 172,
	VK_VOLUME_MUTE = 173,
	VK_VOLUME_DOWN = 174,
	VK_VOLUME_UP = 175,
	VK_MEDIA_NEXT_TRACK = 176,
	VK_MEDIA_PREV_TRACK = 177,
	VK_MEDIA_STOP = 178,
	VK_MEDIA_PLAY_PAUSE = 179,
	VK_LAUNCH_MAIL = 180,
	VK_LAUNCH_MEDIA_SELECT = 181,
	VK_LAUNCH_APP1 = 182,
	VK_LAUNCH_APP2 = 183,
	VK_OEM_1 = 186,
	VK_OEM_PLUS = 187,
	VK_OEM_COMMA = 188,
	VK_OEM_MINUS = 189,
	VK_OEM_PERIOD = 190,
	VK_OEM_2 = 191,
	VK_OEM_3 = 192,
	VK_GAMEPAD_A = 195,
	VK_GAMEPAD_B = 196,
	VK_GAMEPAD_X = 197,
	VK_GAMEPAD_Y = 198,
	VK_GAMEPAD_RIGHT_SHOULDER = 199,
	VK_GAMEPAD_LEFT_SHOULDER = 200,
	VK_GAMEPAD_LEFT_TRIGGER = 201,
	VK_GAMEPAD_RIGHT_TRIGGER = 202,
	VK_GAMEPAD_DPAD_UP = 203,
	VK_GAMEPAD_DPAD_DOWN = 204,
	VK_GAMEPAD_DPAD_LEFT = 205,
	VK_GAMEPAD_DPAD_RIGHT = 206,
	VK_GAMEPAD_MENU = 207,
	VK_GAMEPAD_VIEW = 208,
	VK_GAMEPAD_LEFT_THUMBSTICK_BUTTON = 209,
	VK_GAMEPAD_RIGHT_THUMBSTICK_BUTTON = 210,
	VK_GAMEPAD_LEFT_THUMBSTICK_UP = 211,
	VK_GAMEPAD_LEFT_THUMBSTICK_DOWN = 212,
	VK_GAMEPAD_LEFT_THUMBSTICK_RIGHT = 213,
	VK_GAMEPAD_LEFT_THUMBSTICK_LEFT = 214,
	VK_GAMEPAD_RIGHT_THUMBSTICK_UP = 215,
	VK_GAMEPAD_RIGHT_THUMBSTICK_DOWN = 216,
	VK_GAMEPAD_RIGHT_THUMBSTICK_RIGHT = 217,
	VK_GAMEPAD_RIGHT_THUMBSTICK_LEFT = 218,
	VK_OEM_4 = 219,
	VK_OEM_5 = 220,
	VK_OEM_6 = 221,
	VK_OEM_7 = 222,
	VK_OEM_8 = 223,
	VK_OEM_AX = 225,
	VK_OEM_102 = 226,
	VK_ICO_HELP = 227,
	VK_ICO_00 = 228,
	VK_PROCESSKEY = 229,
	VK_ICO_CLEAR = 230,
	VK_PACKET = 231,
	VK_OEM_RESET = 233,
	VK_OEM_JUMP = 234,
	VK_OEM_PA1 = 235,
	VK_OEM_PA2 = 236,
	VK_OEM_PA3 = 237,
	VK_OEM_WSCTRL = 238,
	VK_OEM_CUSEL = 239,
	VK_OEM_ATTN = 240,
	VK_OEM_FINISH = 241,
	VK_OEM_COPY = 242,
	VK_OEM_AUTO = 243,
	VK_OEM_ENLW = 244,
	VK_OEM_BACKTAB = 245,
	VK_ATTN = 246,
	VK_CRSEL = 247,
	VK_EXSEL = 248,
	VK_EREOF = 249,
	VK_PLAY = 250,
	VK_ZOOM = 251,
	VK_NONAME = 252,
	VK_PA1 = 253,
	VK_OEM_CLEAR = 254,
}

#endregion


#region Structs
[CRepr]
public struct VK_TO_BIT
{
	public uint8 Vk;
	public uint8 ModBits;
}

[CRepr]
public struct MODIFIERS
{
	public VK_TO_BIT* pVkToBit;
	public uint16 wMaxModBits;
	public uint8* ModNumber mut => &ModNumber_impl;
	private uint8[ANYSIZE_ARRAY] ModNumber_impl;
}

[CRepr]
public struct VSC_VK
{
	public uint8 Vsc;
	public uint16 Vk;
}

[CRepr]
public struct VK_VSC
{
	public uint8 Vk;
	public uint8 Vsc;
}

[CRepr]
public struct VK_TO_WCHARS1
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16* wch mut => &wch_impl;
	private char16[ANYSIZE_ARRAY] wch_impl;
}

[CRepr]
public struct VK_TO_WCHARS2
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[2] wch;
}

[CRepr]
public struct VK_TO_WCHARS3
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[3] wch;
}

[CRepr]
public struct VK_TO_WCHARS4
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[4] wch;
}

[CRepr]
public struct VK_TO_WCHARS5
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[5] wch;
}

[CRepr]
public struct VK_TO_WCHARS6
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[6] wch;
}

[CRepr]
public struct VK_TO_WCHARS7
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[7] wch;
}

[CRepr]
public struct VK_TO_WCHARS8
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[8] wch;
}

[CRepr]
public struct VK_TO_WCHARS9
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[9] wch;
}

[CRepr]
public struct VK_TO_WCHARS10
{
	public uint8 VirtualKey;
	public uint8 Attributes;
	public char16[10] wch;
}

[CRepr]
public struct VK_TO_WCHAR_TABLE
{
	public VK_TO_WCHARS1* pVkToWchars;
	public uint8 nModifications;
	public uint8 cbSize;
}

[CRepr]
public struct DEADKEY
{
	public uint32 dwBoth;
	public char16 wchComposed;
	public uint16 uFlags;
}

[CRepr]
public struct LIGATURE1
{
	public uint8 VirtualKey;
	public uint16 ModificationNumber;
	public char16* wch mut => &wch_impl;
	private char16[ANYSIZE_ARRAY] wch_impl;
}

[CRepr]
public struct LIGATURE2
{
	public uint8 VirtualKey;
	public uint16 ModificationNumber;
	public char16[2] wch;
}

[CRepr]
public struct LIGATURE3
{
	public uint8 VirtualKey;
	public uint16 ModificationNumber;
	public char16[3] wch;
}

[CRepr]
public struct LIGATURE4
{
	public uint8 VirtualKey;
	public uint16 ModificationNumber;
	public char16[4] wch;
}

[CRepr]
public struct LIGATURE5
{
	public uint8 VirtualKey;
	public uint16 ModificationNumber;
	public char16[5] wch;
}

[CRepr]
public struct VSC_LPWSTR
{
	public uint8 vsc;
	public PWSTR pwsz;
}

[CRepr]
public struct KBDTABLES
{
	public MODIFIERS* pCharModifiers;
	public VK_TO_WCHAR_TABLE* pVkToWcharTable;
	public DEADKEY* pDeadKey;
	public VSC_LPWSTR* pKeyNames;
	public VSC_LPWSTR* pKeyNamesExt;
	public uint16** pKeyNamesDead;
	public uint16* pusVSCtoVK;
	public uint8 bMaxVSCtoVK;
	public VSC_VK* pVSCtoVK_E0;
	public VSC_VK* pVSCtoVK_E1;
	public uint32 fLocaleFlags;
	public uint8 nLgMax;
	public uint8 cbLgEntry;
	public LIGATURE1* pLigature;
	public uint32 dwType;
	public uint32 dwSubType;
}

[CRepr]
public struct VK_FPARAM
{
	public uint8 NLSFEProcIndex;
	public uint32 NLSFEProcParam;
}

[CRepr]
public struct VK_F
{
	public uint8 Vk;
	public uint8 NLSFEProcType;
	public uint8 NLSFEProcCurrent;
	public uint8 NLSFEProcSwitch;
	public VK_FPARAM[8] NLSFEProc;
	public VK_FPARAM[8] NLSFEProcAlt;
}

[CRepr]
public struct KBDNLSTABLES
{
	public uint16 OEMIdentifier;
	public uint16 LayoutInformation;
	public uint32 NumOfVkToF;
	public VK_F* pVkToF;
	public int32 NumOfMouseVKey;
	public uint16* pusMouseVKey;
}

[CRepr]
public struct KBDTABLE_DESC
{
	public char16[32] wszDllName;
	public uint32 dwType;
	public uint32 dwSubType;
}

[CRepr]
public struct KBDTABLE_MULTI
{
	public uint32 nTables;
	public KBDTABLE_DESC[8] aKbdTables;
}

[CRepr]
public struct KBD_TYPE_INFO
{
	public uint32 dwVersion;
	public uint32 dwType;
	public uint32 dwSubType;
}

[CRepr]
public struct MOUSEMOVEPOINT
{
	public int32 x;
	public int32 y;
	public uint32 time;
	public uint dwExtraInfo;
}

[CRepr]
public struct TRACKMOUSEEVENT
{
	public uint32 cbSize;
	public TRACKMOUSEEVENT_FLAGS dwFlags;
	public HWND hwndTrack;
	public uint32 dwHoverTime;
}

[CRepr]
public struct MOUSEINPUT
{
	public int32 dx;
	public int32 dy;
	public int32 mouseData;
	public MOUSE_EVENT_FLAGS dwFlags;
	public uint32 time;
	public uint dwExtraInfo;
}

[CRepr]
public struct KEYBDINPUT
{
	public VIRTUAL_KEY wVk;
	public uint16 wScan;
	public KEYBD_EVENT_FLAGS dwFlags;
	public uint32 time;
	public uint dwExtraInfo;
}

[CRepr]
public struct HARDWAREINPUT
{
	public uint32 uMsg;
	public uint16 wParamL;
	public uint16 wParamH;
}

[CRepr]
public struct INPUT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public MOUSEINPUT mi;
		public KEYBDINPUT ki;
		public HARDWAREINPUT hi;
	}
	public INPUT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct LASTINPUTINFO
{
	public uint32 cbSize;
	public uint32 dwTime;
}

#endregion

#region Functions
public static
{
	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL _TrackMouseEvent(TRACKMOUSEEVENT* lpEventTrack);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKL LoadKeyboardLayoutA(PSTR pwszKLID, ACTIVATE_KEYBOARD_LAYOUT_FLAGS Flags);
	public static HKL LoadKeyboardLayout(PSTR pwszKLID, ACTIVATE_KEYBOARD_LAYOUT_FLAGS Flags) => LoadKeyboardLayoutA(pwszKLID, Flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKL LoadKeyboardLayoutW(PWSTR pwszKLID, ACTIVATE_KEYBOARD_LAYOUT_FLAGS Flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKL ActivateKeyboardLayout(HKL hkl, ACTIVATE_KEYBOARD_LAYOUT_FLAGS Flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ToUnicodeEx(uint32 wVirtKey, uint32 wScanCode, uint8* lpKeyState, char16* pwszBuff, int32 cchBuff, uint32 wFlags, HKL dwhkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnloadKeyboardLayout(HKL hkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetKeyboardLayoutNameA(uint8* pwszKLID);
	public static BOOL GetKeyboardLayoutName(uint8* pwszKLID) => GetKeyboardLayoutNameA(pwszKLID);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetKeyboardLayoutNameW(char16* pwszKLID);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetKeyboardLayoutList(int32 nBuff, HKL* lpList);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKL GetKeyboardLayout(uint32 idThread);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMouseMovePointsEx(uint32 cbSize, MOUSEMOVEPOINT* lppt, MOUSEMOVEPOINT* lpptBuf, int32 nBufPoints, GET_MOUSE_MOVE_POINTS_EX_RESOLUTION resolution);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TrackMouseEvent(TRACKMOUSEEVENT* lpEventTrack);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterHotKey(HWND hWnd, int32 id, HOT_KEY_MODIFIERS fsModifiers, uint32 vk);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterHotKey(HWND hWnd, int32 id);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SwapMouseButton(BOOL fSwap);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDoubleClickTime();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDoubleClickTime(uint32 param0);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND SetFocus(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetActiveWindow();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetFocus();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetKBCodePage();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 GetKeyState(int32 nVirtKey);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 GetAsyncKeyState(int32 vKey);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetKeyboardState(uint8* lpKeyState);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetKeyboardState(uint8* lpKeyState);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetKeyNameTextA(int32 lParam, uint8* lpString, int32 cchSize);
	public static int32 GetKeyNameText(int32 lParam, uint8* lpString, int32 cchSize) => GetKeyNameTextA(lParam, lpString, cchSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetKeyNameTextW(int32 lParam, char16* lpString, int32 cchSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetKeyboardType(int32 nTypeFlag);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ToAscii(uint32 uVirtKey, uint32 uScanCode, uint8* lpKeyState, uint16* lpChar, uint32 uFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ToAsciiEx(uint32 uVirtKey, uint32 uScanCode, uint8* lpKeyState, uint16* lpChar, uint32 uFlags, HKL dwhkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ToUnicode(uint32 wVirtKey, uint32 wScanCode, uint8* lpKeyState, char16* pwszBuff, int32 cchBuff, uint32 wFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OemKeyScan(uint16 wOemChar);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 VkKeyScanA(CHAR ch);
	public static int16 VkKeyScan(CHAR ch) => VkKeyScanA(ch);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 VkKeyScanW(char16 ch);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 VkKeyScanExA(CHAR ch, HKL dwhkl);
	public static int16 VkKeyScanEx(CHAR ch, HKL dwhkl) => VkKeyScanExA(ch, dwhkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 VkKeyScanExW(char16 ch, HKL dwhkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void keybd_event(uint8 bVk, uint8 bScan, KEYBD_EVENT_FLAGS dwFlags, uint dwExtraInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void mouse_event(MOUSE_EVENT_FLAGS dwFlags, int32 dx, int32 dy, uint32 dwData, uint dwExtraInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SendInput(uint32 cInputs, INPUT* pInputs, int32 cbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLastInputInfo(LASTINPUTINFO* plii);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MapVirtualKeyA(uint32 uCode, uint32 uMapType);
	public static uint32 MapVirtualKey(uint32 uCode, uint32 uMapType) => MapVirtualKeyA(uCode, uMapType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MapVirtualKeyW(uint32 uCode, uint32 uMapType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MapVirtualKeyExA(uint32 uCode, uint32 uMapType, HKL dwhkl);
	public static uint32 MapVirtualKeyEx(uint32 uCode, uint32 uMapType, HKL dwhkl) => MapVirtualKeyExA(uCode, uMapType, dwhkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MapVirtualKeyExW(uint32 uCode, uint32 uMapType, HKL dwhkl);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetCapture();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND SetCapture(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReleaseCapture();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnableWindow(HWND hWnd, BOOL bEnable);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsWindowEnabled(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DragDetect(HWND hwnd, POINT pt);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND SetActiveWindow(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BlockInput(BOOL fBlockIt);

}
#endregion
