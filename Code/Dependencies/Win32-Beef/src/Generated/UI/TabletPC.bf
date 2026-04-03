using Win32.Foundation;
using Win32.System.Com;
using Win32.Graphics.Gdi;
using Win32.System.Ole;
using Win32.UI.Controls;
using System;

namespace Win32.UI.TabletPC;

#region Constants
public static
{
	public const String MICROSOFT_URL_EXPERIENCE_PROPERTY = "Microsoft TIP URL Experience";
	public const String MICROSOFT_TIP_NO_INSERT_BUTTON_PROPERTY = "Microsoft TIP No Insert Option";
	public const String MICROSOFT_TIP_COMBOBOXLIST_PROPERTY = "Microsoft TIP ComboBox List Window Identifier";
	public const String MICROSOFT_TIP_OPENING_MSG = "TabletInputPanelOpening";
	public const uint32 SAFE_PARTIAL = 1;
	public const uint32 BEST_COMPLETE = 2;
	public const uint32 MAX_VENDORNAME = 32;
	public const uint32 MAX_FRIENDLYNAME = 64;
	public const uint32 MAX_LANGUAGES = 64;
	public const uint32 CAC_FULL = 0;
	public const uint32 CAC_PREFIX = 1;
	public const uint32 CAC_RANDOM = 2;
	public const uint32 ASYNC_RECO_INTERRUPTED = 1;
	public const uint32 ASYNC_RECO_PROCESS_FAILED = 2;
	public const uint32 ASYNC_RECO_ADDSTROKE_FAILED = 4;
	public const uint32 ASYNC_RECO_SETCACMODE_FAILED = 8;
	public const uint32 ASYNC_RECO_RESETCONTEXT_FAILED = 16;
	public const uint32 ASYNC_RECO_SETGUIDE_FAILED = 32;
	public const uint32 ASYNC_RECO_SETFLAGS_FAILED = 64;
	public const uint32 ASYNC_RECO_SETFACTOID_FAILED = 128;
	public const uint32 ASYNC_RECO_SETTEXTCONTEXT_FAILED = 256;
	public const uint32 ASYNC_RECO_SETWORDLIST_FAILED = 512;
	public const int32 RF_DONTCARE = 1;
	public const int32 RF_OBJECT = 2;
	public const int32 RF_FREE_INPUT = 4;
	public const int32 RF_LINED_INPUT = 8;
	public const int32 RF_BOXED_INPUT = 16;
	public const int32 RF_CAC_INPUT = 32;
	public const int32 RF_RIGHT_AND_DOWN = 64;
	public const int32 RF_LEFT_AND_DOWN = 128;
	public const int32 RF_DOWN_AND_LEFT = 256;
	public const int32 RF_DOWN_AND_RIGHT = 512;
	public const int32 RF_ARBITRARY_ANGLE = 1024;
	public const int32 RF_LATTICE = 2048;
	public const int32 RF_ADVISEINKCHANGE = 4096;
	public const int32 RF_STROKEREORDER = 8192;
	public const int32 RF_PERSONALIZABLE = 16384;
	public const int32 RF_PERFORMSLINEBREAKING = 65536;
	public const int32 RF_REQUIRESSEGMENTATIONBREAKING = 131072;
	public const uint32 FLICK_WM_HANDLED_MASK = 1;
	public const uint32 NUM_FLICK_DIRECTIONS = 8;
	public const uint32 WM_TABLET_DEFBASE = 704;
	public const uint32 WM_TABLET_MAXOFFSET = 32;
	public const uint32 WM_TABLET_ADDED = 712;
	public const uint32 WM_TABLET_DELETED = 713;
	public const uint32 WM_TABLET_FLICK = 715;
	public const uint32 WM_TABLET_QUERYSYSTEMGESTURESTATUS = 716;
	public const uint32 TABLET_DISABLE_PRESSANDHOLD = 1;
	public const uint32 TABLET_DISABLE_PENTAPFEEDBACK = 8;
	public const uint32 TABLET_DISABLE_PENBARRELFEEDBACK = 16;
	public const uint32 TABLET_DISABLE_TOUCHUIFORCEON = 256;
	public const uint32 TABLET_DISABLE_TOUCHUIFORCEOFF = 512;
	public const uint32 TABLET_DISABLE_TOUCHSWITCH = 32768;
	public const uint32 TABLET_DISABLE_FLICKS = 65536;
	public const uint32 TABLET_ENABLE_FLICKSONCONTEXT = 131072;
	public const uint32 TABLET_ENABLE_FLICKLEARNINGMODE = 262144;
	public const uint32 TABLET_DISABLE_SMOOTHSCROLLING = 524288;
	public const uint32 TABLET_DISABLE_FLICKFALLBACKKEYS = 1048576;
	public const uint32 TABLET_ENABLE_MULTITOUCHDATA = 16777216;
	public const uint32 MAX_PACKET_PROPERTY_COUNT = 32;
	public const uint32 MAX_PACKET_BUTTON_COUNT = 32;
	public const uint32 IP_CURSOR_DOWN = 1;
	public const uint32 IP_INVERTED = 2;
	public const uint32 IP_MARGIN = 4;
	public const String INK_SERIALIZED_FORMAT = "Ink Serialized Format";
	public const String STR_GUID_X = "{598A6A8F-52C0-4BA0-93AF-AF357411A561}";
	public const String STR_GUID_Y = "{B53F9F75-04E0-4498-A7EE-C30DBB5A9011}";
	public const String STR_GUID_Z = "{735ADB30-0EBB-4788-A0E4-0F316490055D}";
	public const String STR_GUID_PAKETSTATUS = "{6E0E07BF-AFE7-4CF7-87D1-AF6446208418}";
	public const String STR_GUID_TIMERTICK = "{436510C5-FED3-45D1-8B76-71D3EA7A829D}";
	public const String STR_GUID_SERIALNUMBER = "{78A81B56-0935-4493-BAAE-00541A8A16C4}";
	public const String STR_GUID_NORMALPRESSURE = "{7307502D-F9F4-4E18-B3F2-2CE1B1A3610C}";
	public const String STR_GUID_TANGENTPRESSURE = "{6DA4488B-5244-41EC-905B-32D89AB80809}";
	public const String STR_GUID_BUTTONPRESSURE = "{8B7FEFC4-96AA-4BFE-AC26-8A5F0BE07BF5}";
	public const String STR_GUID_XTILTORIENTATION = "{A8D07B3A-8BF0-40B0-95A9-B80A6BB787BF}";
	public const String STR_GUID_YTILTORIENTATION = "{0E932389-1D77-43AF-AC00-5B950D6D4B2D}";
	public const String STR_GUID_AZIMUTHORIENTATION = "{029123B4-8828-410B-B250-A0536595E5DC}";
	public const String STR_GUID_ALTITUDEORIENTATION = "{82DEC5C7-F6BA-4906-894F-66D68DFC456C}";
	public const String STR_GUID_TWISTORIENTATION = "{0D324960-13B2-41E4-ACE6-7AE9D43D2D3B}";
	public const String STR_GUID_PITCHROTATION = "{7F7E57B7-BE37-4BE1-A356-7A84160E1893}";
	public const String STR_GUID_ROLLROTATION = "{5D5D5E56-6BA9-4C5B-9FB0-851C91714E56}";
	public const String STR_GUID_YAWROTATION = "{6A849980-7C3A-45B7-AA82-90A262950E89}";
	public const String STR_GUID_WIDTH = "{BAABE94D-2712-48F5-BE9D-8F8B5EA0711A}";
	public const String STR_GUID_HEIGHT = "{E61858D2-E447-4218-9D3F-18865C203DF4}";
	public const String STR_GUID_FINGERCONTACTCONFIDENCE = "{E706C804-57F0-4F00-8A0C-853D57789BE9}";
	public const String STR_GUID_DEVICE_CONTACT_ID = "{02585B91-049B-4750-9615-DF8948AB3C9C}";
	public const String INKRECOGNITIONPROPERTY_LINENUMBER = "{DBF29F2C-5289-4BE8-B3D8-6EF63246253E}";
	public const String INKRECOGNITIONPROPERTY_BOXNUMBER = "{2C243E3A-F733-4EB6-B1F8-B5DC5C2C4CDA}";
	public const String INKRECOGNITIONPROPERTY_SEGMENTATION = "{B3C0FE6C-FB51-4164-BA2F-844AF8F983DA}";
	public const String INKRECOGNITIONPROPERTY_HOTPOINT = "{CA6F40DC-5292-452a-91FB-2181C0BEC0DE}";
	public const String INKRECOGNITIONPROPERTY_MAXIMUMSTROKECOUNT = "{BF0EEC4E-4B7D-47a9-8CFA-234DD24BD22A}";
	public const String INKRECOGNITIONPROPERTY_POINTSPERINCH = "{7ED16B76-889C-468e-8276-0021B770187E}";
	public const String INKRECOGNITIONPROPERTY_CONFIDENCELEVEL = "{7DFE11A7-FB5D-4958-8765-154ADF0D833F}";
	public const String INKRECOGNITIONPROPERTY_LINEMETRICS = "{8CC24B27-30A9-4b96-9056-2D3A90DA0727}";
	public const String FACTOID_NONE = "NONE";
	public const String FACTOID_DEFAULT = "DEFAULT";
	public const String FACTOID_SYSTEMDICTIONARY = "SYSDICT";
	public const String FACTOID_WORDLIST = "WORDLIST";
	public const String FACTOID_EMAIL = "EMAIL";
	public const String FACTOID_WEB = "WEB";
	public const String FACTOID_ONECHAR = "ONECHAR";
	public const String FACTOID_NUMBER = "NUMBER";
	public const String FACTOID_DIGIT = "DIGIT";
	public const String FACTOID_NUMBERSIMPLE = "NUMSIMPLE";
	public const String FACTOID_CURRENCY = "CURRENCY";
	public const String FACTOID_POSTALCODE = "POSTALCODE";
	public const String FACTOID_PERCENT = "PERCENT";
	public const String FACTOID_DATE = "DATE";
	public const String FACTOID_TIME = "TIME";
	public const String FACTOID_TELEPHONE = "TELEPHONE";
	public const String FACTOID_FILENAME = "FILENAME";
	public const String FACTOID_UPPERCHAR = "UPPERCHAR";
	public const String FACTOID_LOWERCHAR = "LOWERCHAR";
	public const String FACTOID_PUNCCHAR = "PUNCCHAR";
	public const String FACTOID_JAPANESECOMMON = "JPN_COMMON";
	public const String FACTOID_CHINESESIMPLECOMMON = "CHS_COMMON";
	public const String FACTOID_CHINESETRADITIONALCOMMON = "CHT_COMMON";
	public const String FACTOID_KOREANCOMMON = "KOR_COMMON";
	public const String FACTOID_HIRAGANA = "HIRAGANA";
	public const String FACTOID_KATAKANA = "KATAKANA";
	public const String FACTOID_KANJICOMMON = "KANJI_COMMON";
	public const String FACTOID_KANJIRARE = "KANJI_RARE";
	public const String FACTOID_BOPOMOFO = "BOPOMOFO";
	public const String FACTOID_JAMO = "JAMO";
	public const String FACTOID_HANGULCOMMON = "HANGUL_COMMON";
	public const String FACTOID_HANGULRARE = "HANGUL_RARE";
	public const String MICROSOFT_PENINPUT_PANEL_PROPERTY_T = "Microsoft PenInputPanel 1.5";
	public const String INKEDIT_CLASSW = "INKEDIT";
	public const String INKEDIT_CLASS = "INKEDIT";
	public const uint32 IEC__BASE = 1536;
	public const uint32 EM_GETINKMODE = 1537;
	public const uint32 EM_SETINKMODE = 1538;
	public const uint32 EM_GETINKINSERTMODE = 1539;
	public const uint32 EM_SETINKINSERTMODE = 1540;
	public const uint32 EM_GETDRAWATTR = 1541;
	public const uint32 EM_SETDRAWATTR = 1542;
	public const uint32 EM_GETRECOTIMEOUT = 1543;
	public const uint32 EM_SETRECOTIMEOUT = 1544;
	public const uint32 EM_GETGESTURESTATUS = 1545;
	public const uint32 EM_SETGESTURESTATUS = 1546;
	public const uint32 EM_GETRECOGNIZER = 1547;
	public const uint32 EM_SETRECOGNIZER = 1548;
	public const uint32 EM_GETFACTOID = 1549;
	public const uint32 EM_SETFACTOID = 1550;
	public const uint32 EM_GETSELINK = 1551;
	public const uint32 EM_SETSELINK = 1552;
	public const uint32 EM_GETMOUSEICON = 1553;
	public const uint32 EM_SETMOUSEICON = 1554;
	public const uint32 EM_GETMOUSEPOINTER = 1555;
	public const uint32 EM_SETMOUSEPOINTER = 1556;
	public const uint32 EM_GETSTATUS = 1557;
	public const uint32 EM_RECOGNIZE = 1558;
	public const uint32 EM_GETUSEMOUSEFORINPUT = 1559;
	public const uint32 EM_SETUSEMOUSEFORINPUT = 1560;
	public const uint32 EM_SETSELINKDISPLAYMODE = 1561;
	public const uint32 EM_GETSELINKDISPLAYMODE = 1562;
	public const uint32 IECN__BASE = 2048;
	public const uint32 IECN_STROKE = 2049;
	public const uint32 IECN_GESTURE = 2050;
	public const uint32 IECN_RECOGNITIONRESULT = 2051;
	public const uint32 RECOFLAG_WORDMODE = 1;
	public const uint32 RECOFLAG_COERCE = 2;
	public const uint32 RECOFLAG_SINGLESEG = 4;
	public const uint32 RECOFLAG_PREFIXOK = 8;
	public const uint32 RECOFLAG_LINEMODE = 16;
	public const uint32 RECOFLAG_DISABLEPERSONALIZATION = 32;
	public const uint32 RECOFLAG_AUTOSPACE = 64;
	public const int32 RECOCONF_LOWCONFIDENCE = -1;
	public const uint32 RECOCONF_MEDIUMCONFIDENCE = 0;
	public const uint32 RECOCONF_HIGHCONFIDENCE = 1;
	public const uint32 RECOCONF_NOTSET = 128;
	public const uint32 GESTURE_NULL = 61440;
	public const uint32 GESTURE_SCRATCHOUT = 61441;
	public const uint32 GESTURE_TRIANGLE = 61442;
	public const uint32 GESTURE_SQUARE = 61443;
	public const uint32 GESTURE_STAR = 61444;
	public const uint32 GESTURE_CHECK = 61445;
	public const uint32 GESTURE_INFINITY = 61446;
	public const uint32 GESTURE_CROSS = 61447;
	public const uint32 GESTURE_PARAGRAPH = 61448;
	public const uint32 GESTURE_SECTION = 61449;
	public const uint32 GESTURE_BULLET = 61450;
	public const uint32 GESTURE_BULLET_CROSS = 61451;
	public const uint32 GESTURE_SQUIGGLE = 61452;
	public const uint32 GESTURE_SWAP = 61453;
	public const uint32 GESTURE_OPENUP = 61454;
	public const uint32 GESTURE_CLOSEUP = 61455;
	public const uint32 GESTURE_CURLICUE = 61456;
	public const uint32 GESTURE_DOUBLE_CURLICUE = 61457;
	public const uint32 GESTURE_RECTANGLE = 61458;
	public const uint32 GESTURE_CIRCLE = 61472;
	public const uint32 GESTURE_DOUBLE_CIRCLE = 61473;
	public const uint32 GESTURE_CIRCLE_TAP = 61474;
	public const uint32 GESTURE_CIRCLE_CIRCLE = 61475;
	public const uint32 GESTURE_CIRCLE_CROSS = 61477;
	public const uint32 GESTURE_CIRCLE_LINE_VERT = 61478;
	public const uint32 GESTURE_CIRCLE_LINE_HORZ = 61479;
	public const uint32 GESTURE_SEMICIRCLE_LEFT = 61480;
	public const uint32 GESTURE_SEMICIRCLE_RIGHT = 61481;
	public const uint32 GESTURE_CHEVRON_UP = 61488;
	public const uint32 GESTURE_CHEVRON_DOWN = 61489;
	public const uint32 GESTURE_CHEVRON_LEFT = 61490;
	public const uint32 GESTURE_CHEVRON_RIGHT = 61491;
	public const uint32 GESTURE_ARROW_UP = 61496;
	public const uint32 GESTURE_ARROW_DOWN = 61497;
	public const uint32 GESTURE_ARROW_LEFT = 61498;
	public const uint32 GESTURE_ARROW_RIGHT = 61499;
	public const uint32 GESTURE_DOUBLE_ARROW_UP = 61500;
	public const uint32 GESTURE_DOUBLE_ARROW_DOWN = 61501;
	public const uint32 GESTURE_DOUBLE_ARROW_LEFT = 61502;
	public const uint32 GESTURE_DOUBLE_ARROW_RIGHT = 61503;
	public const uint32 GESTURE_UP_ARROW_LEFT = 61504;
	public const uint32 GESTURE_UP_ARROW_RIGHT = 61505;
	public const uint32 GESTURE_DOWN_ARROW_LEFT = 61506;
	public const uint32 GESTURE_DOWN_ARROW_RIGHT = 61507;
	public const uint32 GESTURE_LEFT_ARROW_UP = 61508;
	public const uint32 GESTURE_LEFT_ARROW_DOWN = 61509;
	public const uint32 GESTURE_RIGHT_ARROW_UP = 61510;
	public const uint32 GESTURE_RIGHT_ARROW_DOWN = 61511;
	public const uint32 GESTURE_UP = 61528;
	public const uint32 GESTURE_DOWN = 61529;
	public const uint32 GESTURE_LEFT = 61530;
	public const uint32 GESTURE_RIGHT = 61531;
	public const uint32 GESTURE_DIAGONAL_LEFTUP = 61532;
	public const uint32 GESTURE_DIAGONAL_RIGHTUP = 61533;
	public const uint32 GESTURE_DIAGONAL_LEFTDOWN = 61534;
	public const uint32 GESTURE_DIAGONAL_RIGHTDOWN = 61535;
	public const uint32 GESTURE_UP_DOWN = 61536;
	public const uint32 GESTURE_DOWN_UP = 61537;
	public const uint32 GESTURE_LEFT_RIGHT = 61538;
	public const uint32 GESTURE_RIGHT_LEFT = 61539;
	public const uint32 GESTURE_UP_LEFT_LONG = 61540;
	public const uint32 GESTURE_UP_RIGHT_LONG = 61541;
	public const uint32 GESTURE_DOWN_LEFT_LONG = 61542;
	public const uint32 GESTURE_DOWN_RIGHT_LONG = 61543;
	public const uint32 GESTURE_UP_LEFT = 61544;
	public const uint32 GESTURE_UP_RIGHT = 61545;
	public const uint32 GESTURE_DOWN_LEFT = 61546;
	public const uint32 GESTURE_DOWN_RIGHT = 61547;
	public const uint32 GESTURE_LEFT_UP = 61548;
	public const uint32 GESTURE_LEFT_DOWN = 61549;
	public const uint32 GESTURE_RIGHT_UP = 61550;
	public const uint32 GESTURE_RIGHT_DOWN = 61551;
	public const uint32 GESTURE_LETTER_A = 61568;
	public const uint32 GESTURE_LETTER_B = 61569;
	public const uint32 GESTURE_LETTER_C = 61570;
	public const uint32 GESTURE_LETTER_D = 61571;
	public const uint32 GESTURE_LETTER_E = 61572;
	public const uint32 GESTURE_LETTER_F = 61573;
	public const uint32 GESTURE_LETTER_G = 61574;
	public const uint32 GESTURE_LETTER_H = 61575;
	public const uint32 GESTURE_LETTER_I = 61576;
	public const uint32 GESTURE_LETTER_J = 61577;
	public const uint32 GESTURE_LETTER_K = 61578;
	public const uint32 GESTURE_LETTER_L = 61579;
	public const uint32 GESTURE_LETTER_M = 61580;
	public const uint32 GESTURE_LETTER_N = 61581;
	public const uint32 GESTURE_LETTER_O = 61582;
	public const uint32 GESTURE_LETTER_P = 61583;
	public const uint32 GESTURE_LETTER_Q = 61584;
	public const uint32 GESTURE_LETTER_R = 61585;
	public const uint32 GESTURE_LETTER_S = 61586;
	public const uint32 GESTURE_LETTER_T = 61587;
	public const uint32 GESTURE_LETTER_U = 61588;
	public const uint32 GESTURE_LETTER_V = 61589;
	public const uint32 GESTURE_LETTER_W = 61590;
	public const uint32 GESTURE_LETTER_X = 61591;
	public const uint32 GESTURE_LETTER_Y = 61592;
	public const uint32 GESTURE_LETTER_Z = 61593;
	public const uint32 GESTURE_DIGIT_0 = 61594;
	public const uint32 GESTURE_DIGIT_1 = 61595;
	public const uint32 GESTURE_DIGIT_2 = 61596;
	public const uint32 GESTURE_DIGIT_3 = 61597;
	public const uint32 GESTURE_DIGIT_4 = 61598;
	public const uint32 GESTURE_DIGIT_5 = 61599;
	public const uint32 GESTURE_DIGIT_6 = 61600;
	public const uint32 GESTURE_DIGIT_7 = 61601;
	public const uint32 GESTURE_DIGIT_8 = 61602;
	public const uint32 GESTURE_DIGIT_9 = 61603;
	public const uint32 GESTURE_EXCLAMATION = 61604;
	public const uint32 GESTURE_QUESTION = 61605;
	public const uint32 GESTURE_SHARP = 61606;
	public const uint32 GESTURE_DOLLAR = 61607;
	public const uint32 GESTURE_ASTERISK = 61608;
	public const uint32 GESTURE_PLUS = 61609;
	public const uint32 GESTURE_DOUBLE_UP = 61624;
	public const uint32 GESTURE_DOUBLE_DOWN = 61625;
	public const uint32 GESTURE_DOUBLE_LEFT = 61626;
	public const uint32 GESTURE_DOUBLE_RIGHT = 61627;
	public const uint32 GESTURE_TRIPLE_UP = 61628;
	public const uint32 GESTURE_TRIPLE_DOWN = 61629;
	public const uint32 GESTURE_TRIPLE_LEFT = 61630;
	public const uint32 GESTURE_TRIPLE_RIGHT = 61631;
	public const uint32 GESTURE_BRACKET_OVER = 61668;
	public const uint32 GESTURE_BRACKET_UNDER = 61669;
	public const uint32 GESTURE_BRACKET_LEFT = 61670;
	public const uint32 GESTURE_BRACKET_RIGHT = 61671;
	public const uint32 GESTURE_BRACE_OVER = 61672;
	public const uint32 GESTURE_BRACE_UNDER = 61673;
	public const uint32 GESTURE_BRACE_LEFT = 61674;
	public const uint32 GESTURE_BRACE_RIGHT = 61675;
	public const uint32 GESTURE_TAP = 61680;
	public const uint32 GESTURE_DOUBLE_TAP = 61681;
	public const uint32 GESTURE_TRIPLE_TAP = 61682;
	public const uint32 GESTURE_QUAD_TAP = 61683;
	public const uint32 FACILITY_INK = 40;
	public const Guid GUID_PACKETPROPERTY_GUID_X = .(0x598a6a8f, 0x52c0, 0x4ba0, 0x93, 0xaf, 0xaf, 0x35, 0x74, 0x11, 0xa5, 0x61);
	public const Guid GUID_PACKETPROPERTY_GUID_Y = .(0xb53f9f75, 0x04e0, 0x4498, 0xa7, 0xee, 0xc3, 0x0d, 0xbb, 0x5a, 0x90, 0x11);
	public const Guid GUID_PACKETPROPERTY_GUID_Z = .(0x735adb30, 0x0ebb, 0x4788, 0xa0, 0xe4, 0x0f, 0x31, 0x64, 0x90, 0x05, 0x5d);
	public const Guid GUID_PACKETPROPERTY_GUID_PACKET_STATUS = .(0x6e0e07bf, 0xafe7, 0x4cf7, 0x87, 0xd1, 0xaf, 0x64, 0x46, 0x20, 0x84, 0x18);
	public const Guid GUID_PACKETPROPERTY_GUID_TIMER_TICK = .(0x436510c5, 0xfed3, 0x45d1, 0x8b, 0x76, 0x71, 0xd3, 0xea, 0x7a, 0x82, 0x9d);
	public const Guid GUID_PACKETPROPERTY_GUID_SERIAL_NUMBER = .(0x78a81b56, 0x0935, 0x4493, 0xba, 0xae, 0x00, 0x54, 0x1a, 0x8a, 0x16, 0xc4);
	public const Guid GUID_PACKETPROPERTY_GUID_NORMAL_PRESSURE = .(0x7307502d, 0xf9f4, 0x4e18, 0xb3, 0xf2, 0x2c, 0xe1, 0xb1, 0xa3, 0x61, 0x0c);
	public const Guid GUID_PACKETPROPERTY_GUID_TANGENT_PRESSURE = .(0x6da4488b, 0x5244, 0x41ec, 0x90, 0x5b, 0x32, 0xd8, 0x9a, 0xb8, 0x08, 0x09);
	public const Guid GUID_PACKETPROPERTY_GUID_BUTTON_PRESSURE = .(0x8b7fefc4, 0x96aa, 0x4bfe, 0xac, 0x26, 0x8a, 0x5f, 0x0b, 0xe0, 0x7b, 0xf5);
	public const Guid GUID_PACKETPROPERTY_GUID_X_TILT_ORIENTATION = .(0xa8d07b3a, 0x8bf0, 0x40b0, 0x95, 0xa9, 0xb8, 0x0a, 0x6b, 0xb7, 0x87, 0xbf);
	public const Guid GUID_PACKETPROPERTY_GUID_Y_TILT_ORIENTATION = .(0x0e932389, 0x1d77, 0x43af, 0xac, 0x00, 0x5b, 0x95, 0x0d, 0x6d, 0x4b, 0x2d);
	public const Guid GUID_PACKETPROPERTY_GUID_AZIMUTH_ORIENTATION = .(0x029123b4, 0x8828, 0x410b, 0xb2, 0x50, 0xa0, 0x53, 0x65, 0x95, 0xe5, 0xdc);
	public const Guid GUID_PACKETPROPERTY_GUID_ALTITUDE_ORIENTATION = .(0x82dec5c7, 0xf6ba, 0x4906, 0x89, 0x4f, 0x66, 0xd6, 0x8d, 0xfc, 0x45, 0x6c);
	public const Guid GUID_PACKETPROPERTY_GUID_TWIST_ORIENTATION = .(0x0d324960, 0x13b2, 0x41e4, 0xac, 0xe6, 0x7a, 0xe9, 0xd4, 0x3d, 0x2d, 0x3b);
	public const Guid GUID_PACKETPROPERTY_GUID_PITCH_ROTATION = .(0x7f7e57b7, 0xbe37, 0x4be1, 0xa3, 0x56, 0x7a, 0x84, 0x16, 0x0e, 0x18, 0x93);
	public const Guid GUID_PACKETPROPERTY_GUID_ROLL_ROTATION = .(0x5d5d5e56, 0x6ba9, 0x4c5b, 0x9f, 0xb0, 0x85, 0x1c, 0x91, 0x71, 0x4e, 0x56);
	public const Guid GUID_PACKETPROPERTY_GUID_YAW_ROTATION = .(0x6a849980, 0x7c3a, 0x45b7, 0xaa, 0x82, 0x90, 0xa2, 0x62, 0x95, 0x0e, 0x89);
	public const Guid GUID_PACKETPROPERTY_GUID_WIDTH = .(0xbaabe94d, 0x2712, 0x48f5, 0xbe, 0x9d, 0x8f, 0x8b, 0x5e, 0xa0, 0x71, 0x1a);
	public const Guid GUID_PACKETPROPERTY_GUID_HEIGHT = .(0xe61858d2, 0xe447, 0x4218, 0x9d, 0x3f, 0x18, 0x86, 0x5c, 0x20, 0x3d, 0xf4);
	public const Guid GUID_PACKETPROPERTY_GUID_FINGERCONTACTCONFIDENCE = .(0xe706c804, 0x57f0, 0x4f00, 0x8a, 0x0c, 0x85, 0x3d, 0x57, 0x78, 0x9b, 0xe9);
	public const Guid GUID_PACKETPROPERTY_GUID_DEVICE_CONTACT_ID = .(0x02585b91, 0x049b, 0x4750, 0x96, 0x15, 0xdf, 0x89, 0x48, 0xab, 0x3c, 0x9c);
	public const int32 InkMinTransparencyValue = 0;
	public const int32 InkMaxTransparencyValue = 255;
	public const int32 InkCollectorClipInkToMargin = 0;
	public const int32 InkCollectorDefaultMargin = -2147483648;
	public const Guid GUID_GESTURE_DATA = .(0x41e4ec0f, 0x26aa, 0x455a, 0x9a, 0xa5, 0x2c, 0xd3, 0x6c, 0xf6, 0x3f, 0xb9);
	public const Guid GUID_DYNAMIC_RENDERER_CACHED_DATA = .(0xbf531b92, 0x25bf, 0x4a95, 0x89, 0xad, 0x0e, 0x47, 0x6b, 0x34, 0xb4, 0xf5);
}
#endregion

#region TypeDefs
typealias HRECOALT = int;

typealias HRECOCONTEXT = int;

typealias HRECOGNIZER = int;

typealias HRECOLATTICE = int;

typealias HRECOWORDLIST = int;

#endregion


#region Enums

[AllowDuplicates]
public enum PROPERTY_UNITS : int32
{
	PROPERTY_UNITS_DEFAULT = 0,
	PROPERTY_UNITS_INCHES = 1,
	PROPERTY_UNITS_CENTIMETERS = 2,
	PROPERTY_UNITS_DEGREES = 3,
	PROPERTY_UNITS_RADIANS = 4,
	PROPERTY_UNITS_SECONDS = 5,
	PROPERTY_UNITS_POUNDS = 6,
	PROPERTY_UNITS_GRAMS = 7,
	PROPERTY_UNITS_SILINEAR = 8,
	PROPERTY_UNITS_SIROTATION = 9,
	PROPERTY_UNITS_ENGLINEAR = 10,
	PROPERTY_UNITS_ENGROTATION = 11,
	PROPERTY_UNITS_SLUGS = 12,
	PROPERTY_UNITS_KELVIN = 13,
	PROPERTY_UNITS_FAHRENHEIT = 14,
	PROPERTY_UNITS_AMPERE = 15,
	PROPERTY_UNITS_CANDELA = 16,
}


[AllowDuplicates]
public enum INK_METRIC_FLAGS : int32
{
	IMF_FONT_SELECTED_IN_HDC = 1,
	IMF_ITALIC = 2,
	IMF_BOLD = 4,
}


[AllowDuplicates]
public enum GET_DANDIDATE_FLAGS : int32
{
	TCF_ALLOW_RECOGNITION = 1,
	TCF_FORCE_RECOGNITION = 2,
}


[AllowDuplicates]
public enum InkSelectionConstants : int32
{
	ISC_FirstElement = 0,
	ISC_AllElements = -1,
}


[AllowDuplicates]
public enum InkBoundingBoxMode : int32
{
	IBBM_Default = 0,
	IBBM_NoCurveFit = 1,
	IBBM_CurveFit = 2,
	IBBM_PointsOnly = 3,
	IBBM_Union = 4,
}


[AllowDuplicates]
public enum InkExtractFlags : int32
{
	IEF_CopyFromOriginal = 0,
	IEF_RemoveFromOriginal = 1,
	IEF_Default = 1,
}


[AllowDuplicates]
public enum InkPersistenceFormat : int32
{
	IPF_InkSerializedFormat = 0,
	IPF_Base64InkSerializedFormat = 1,
	IPF_GIF = 2,
	IPF_Base64GIF = 3,
}


[AllowDuplicates]
public enum InkPersistenceCompressionMode : int32
{
	IPCM_Default = 0,
	IPCM_MaximumCompression = 1,
	IPCM_NoCompression = 2,
}


[AllowDuplicates]
public enum InkPenTip : int32
{
	IPT_Ball = 0,
	IPT_Rectangle = 1,
}


[AllowDuplicates]
public enum InkRasterOperation : int32
{
	IRO_Black = 1,
	IRO_NotMergePen = 2,
	IRO_MaskNotPen = 3,
	IRO_NotCopyPen = 4,
	IRO_MaskPenNot = 5,
	IRO_Not = 6,
	IRO_XOrPen = 7,
	IRO_NotMaskPen = 8,
	IRO_MaskPen = 9,
	IRO_NotXOrPen = 10,
	IRO_NoOperation = 11,
	IRO_MergeNotPen = 12,
	IRO_CopyPen = 13,
	IRO_MergePenNot = 14,
	IRO_MergePen = 15,
	IRO_White = 16,
}


[AllowDuplicates]
public enum InkMousePointer : int32
{
	IMP_Default = 0,
	IMP_Arrow = 1,
	IMP_Crosshair = 2,
	IMP_Ibeam = 3,
	IMP_SizeNESW = 4,
	IMP_SizeNS = 5,
	IMP_SizeNWSE = 6,
	IMP_SizeWE = 7,
	IMP_UpArrow = 8,
	IMP_Hourglass = 9,
	IMP_NoDrop = 10,
	IMP_ArrowHourglass = 11,
	IMP_ArrowQuestion = 12,
	IMP_SizeAll = 13,
	IMP_Hand = 14,
	IMP_Custom = 99,
}


[AllowDuplicates]
public enum InkClipboardModes : int32
{
	ICB_Copy = 0,
	ICB_Cut = 1,
	ICB_ExtractOnly = 48,
	ICB_DelayedCopy = 32,
	ICB_Default = 0,
}


[AllowDuplicates]
public enum InkClipboardFormats : int32
{
	ICF_None = 0,
	ICF_InkSerializedFormat = 1,
	ICF_SketchInk = 2,
	ICF_TextInk = 6,
	ICF_EnhancedMetafile = 8,
	ICF_Metafile = 32,
	ICF_Bitmap = 64,
	ICF_PasteMask = 7,
	ICF_CopyMask = 127,
	ICF_Default = 127,
}


[AllowDuplicates]
public enum SelectionHitResult : int32
{
	SHR_None = 0,
	SHR_NW = 1,
	SHR_SE = 2,
	SHR_NE = 3,
	SHR_SW = 4,
	SHR_E = 5,
	SHR_W = 6,
	SHR_N = 7,
	SHR_S = 8,
	SHR_Selection = 9,
}


[AllowDuplicates]
public enum InkRecognitionStatus : int32
{
	IRS_NoError = 0,
	IRS_Interrupted = 1,
	IRS_ProcessFailed = 2,
	IRS_InkAddedFailed = 4,
	IRS_SetAutoCompletionModeFailed = 8,
	IRS_SetStrokesFailed = 16,
	IRS_SetGuideFailed = 32,
	IRS_SetFlagsFailed = 64,
	IRS_SetFactoidFailed = 128,
	IRS_SetPrefixSuffixFailed = 256,
	IRS_SetWordListFailed = 512,
}


[AllowDuplicates]
public enum DISPID_InkRectangle : int32
{
	DISPID_IRTop = 1,
	DISPID_IRLeft = 2,
	DISPID_IRBottom = 3,
	DISPID_IRRight = 4,
	DISPID_IRGetRectangle = 5,
	DISPID_IRSetRectangle = 6,
	DISPID_IRData = 7,
}


[AllowDuplicates]
public enum DISPID_InkExtendedProperty : int32
{
	DISPID_IEPGuid = 1,
	DISPID_IEPData = 2,
}


[AllowDuplicates]
public enum DISPID_InkExtendedProperties : int32
{
	DISPID_IEPs_NewEnum = -4,
	DISPID_IEPsItem = 0,
	DISPID_IEPsCount = 1,
	DISPID_IEPsAdd = 2,
	DISPID_IEPsRemove = 3,
	DISPID_IEPsClear = 4,
	DISPID_IEPsDoesPropertyExist = 5,
}


[AllowDuplicates]
public enum DISPID_InkDrawingAttributes : int32
{
	DISPID_DAHeight = 1,
	DISPID_DAColor = 2,
	DISPID_DAWidth = 3,
	DISPID_DAFitToCurve = 4,
	DISPID_DAIgnorePressure = 5,
	DISPID_DAAntiAliased = 6,
	DISPID_DATransparency = 7,
	DISPID_DARasterOperation = 8,
	DISPID_DAPenTip = 9,
	DISPID_DAClone = 10,
	DISPID_DAExtendedProperties = 11,
}


[AllowDuplicates]
public enum DISPID_InkTransform : int32
{
	DISPID_ITReset = 1,
	DISPID_ITTranslate = 2,
	DISPID_ITRotate = 3,
	DISPID_ITReflect = 4,
	DISPID_ITShear = 5,
	DISPID_ITScale = 6,
	DISPID_ITeM11 = 7,
	DISPID_ITeM12 = 8,
	DISPID_ITeM21 = 9,
	DISPID_ITeM22 = 10,
	DISPID_ITeDx = 11,
	DISPID_ITeDy = 12,
	DISPID_ITGetTransform = 13,
	DISPID_ITSetTransform = 14,
	DISPID_ITData = 15,
}


[AllowDuplicates]
public enum InkApplicationGesture : int32
{
	IAG_AllGestures = 0,
	IAG_NoGesture = 61440,
	IAG_Scratchout = 61441,
	IAG_Triangle = 61442,
	IAG_Square = 61443,
	IAG_Star = 61444,
	IAG_Check = 61445,
	IAG_Curlicue = 61456,
	IAG_DoubleCurlicue = 61457,
	IAG_Circle = 61472,
	IAG_DoubleCircle = 61473,
	IAG_SemiCircleLeft = 61480,
	IAG_SemiCircleRight = 61481,
	IAG_ChevronUp = 61488,
	IAG_ChevronDown = 61489,
	IAG_ChevronLeft = 61490,
	IAG_ChevronRight = 61491,
	IAG_ArrowUp = 61496,
	IAG_ArrowDown = 61497,
	IAG_ArrowLeft = 61498,
	IAG_ArrowRight = 61499,
	IAG_Up = 61528,
	IAG_Down = 61529,
	IAG_Left = 61530,
	IAG_Right = 61531,
	IAG_UpDown = 61536,
	IAG_DownUp = 61537,
	IAG_LeftRight = 61538,
	IAG_RightLeft = 61539,
	IAG_UpLeftLong = 61540,
	IAG_UpRightLong = 61541,
	IAG_DownLeftLong = 61542,
	IAG_DownRightLong = 61543,
	IAG_UpLeft = 61544,
	IAG_UpRight = 61545,
	IAG_DownLeft = 61546,
	IAG_DownRight = 61547,
	IAG_LeftUp = 61548,
	IAG_LeftDown = 61549,
	IAG_RightUp = 61550,
	IAG_RightDown = 61551,
	IAG_Exclamation = 61604,
	IAG_Tap = 61680,
	IAG_DoubleTap = 61681,
}


[AllowDuplicates]
public enum InkSystemGesture : int32
{
	ISG_Tap = 16,
	ISG_DoubleTap = 17,
	ISG_RightTap = 18,
	ISG_Drag = 19,
	ISG_RightDrag = 20,
	ISG_HoldEnter = 21,
	ISG_HoldLeave = 22,
	ISG_HoverEnter = 23,
	ISG_HoverLeave = 24,
	ISG_Flick = 31,
}


[AllowDuplicates]
public enum InkRecognitionConfidence : int32
{
	IRC_Strong = 0,
	IRC_Intermediate = 1,
	IRC_Poor = 2,
}


[AllowDuplicates]
public enum DISPID_InkGesture : int32
{
	DISPID_IGId = 0,
	DISPID_IGGetHotPoint = 1,
	DISPID_IGConfidence = 2,
}


[AllowDuplicates]
public enum DISPID_InkCursor : int32
{
	DISPID_ICsrName = 0,
	DISPID_ICsrId = 1,
	DISPID_ICsrDrawingAttributes = 2,
	DISPID_ICsrButtons = 3,
	DISPID_ICsrInverted = 4,
	DISPID_ICsrTablet = 5,
}


[AllowDuplicates]
public enum DISPID_InkCursors : int32
{
	DISPID_ICs_NewEnum = -4,
	DISPID_ICsItem = 0,
	DISPID_ICsCount = 1,
}


[AllowDuplicates]
public enum InkCursorButtonState : int32
{
	ICBS_Unavailable = 0,
	ICBS_Up = 1,
	ICBS_Down = 2,
}


[AllowDuplicates]
public enum DISPID_InkCursorButton : int32
{
	DISPID_ICBName = 0,
	DISPID_ICBId = 1,
	DISPID_ICBState = 2,
}


[AllowDuplicates]
public enum DISPID_InkCursorButtons : int32
{
	DISPID_ICBs_NewEnum = -4,
	DISPID_ICBsItem = 0,
	DISPID_ICBsCount = 1,
}


[AllowDuplicates]
public enum TabletHardwareCapabilities : int32
{
	THWC_Integrated = 1,
	THWC_CursorMustTouch = 2,
	THWC_HardProximity = 4,
	THWC_CursorsHavePhysicalIds = 8,
}


[AllowDuplicates]
public enum TabletPropertyMetricUnit : int32
{
	TPMU_Default = 0,
	TPMU_Inches = 1,
	TPMU_Centimeters = 2,
	TPMU_Degrees = 3,
	TPMU_Radians = 4,
	TPMU_Seconds = 5,
	TPMU_Pounds = 6,
	TPMU_Grams = 7,
}


[AllowDuplicates]
public enum DISPID_InkTablet : int32
{
	DISPID_ITName = 0,
	DISPID_ITPlugAndPlayId = 1,
	DISPID_ITPropertyMetrics = 2,
	DISPID_ITIsPacketPropertySupported = 3,
	DISPID_ITMaximumInputRectangle = 4,
	DISPID_ITHardwareCapabilities = 5,
}


[AllowDuplicates]
public enum TabletDeviceKind : int32
{
	TDK_Mouse = 0,
	TDK_Pen = 1,
	TDK_Touch = 2,
}


[AllowDuplicates]
public enum DISPID_InkTablet2 : int32
{
	DISPID_IT2DeviceKind = 0,
}


[AllowDuplicates]
public enum DISPID_InkTablet3 : int32
{
	DISPID_IT3IsMultiTouch = 0,
	DISPID_IT3MaximumCursors = 1,
}


[AllowDuplicates]
public enum DISPID_InkTablets : int32
{
	DISPID_ITs_NewEnum = -4,
	DISPID_ITsItem = 0,
	DISPID_ITsDefaultTablet = 1,
	DISPID_ITsCount = 2,
	DISPID_ITsIsPacketPropertySupported = 3,
}


[AllowDuplicates]
public enum DISPID_InkStrokeDisp : int32
{
	DISPID_ISDInkIndex = 1,
	DISPID_ISDID = 2,
	DISPID_ISDGetBoundingBox = 3,
	DISPID_ISDDrawingAttributes = 4,
	DISPID_ISDFindIntersections = 5,
	DISPID_ISDGetRectangleIntersections = 6,
	DISPID_ISDClip = 7,
	DISPID_ISDHitTestCircle = 8,
	DISPID_ISDNearestPoint = 9,
	DISPID_ISDSplit = 10,
	DISPID_ISDExtendedProperties = 11,
	DISPID_ISDInk = 12,
	DISPID_ISDBezierPoints = 13,
	DISPID_ISDPolylineCusps = 14,
	DISPID_ISDBezierCusps = 15,
	DISPID_ISDSelfIntersections = 16,
	DISPID_ISDPacketCount = 17,
	DISPID_ISDPacketSize = 18,
	DISPID_ISDPacketDescription = 19,
	DISPID_ISDDeleted = 20,
	DISPID_ISDGetPacketDescriptionPropertyMetrics = 21,
	DISPID_ISDGetPoints = 22,
	DISPID_ISDSetPoints = 23,
	DISPID_ISDGetPacketData = 24,
	DISPID_ISDGetPacketValuesByProperty = 25,
	DISPID_ISDSetPacketValuesByProperty = 26,
	DISPID_ISDGetFlattenedBezierPoints = 27,
	DISPID_ISDScaleToRectangle = 28,
	DISPID_ISDTransform = 29,
	DISPID_ISDMove = 30,
	DISPID_ISDRotate = 31,
	DISPID_ISDShear = 32,
	DISPID_ISDScale = 33,
}


[AllowDuplicates]
public enum DISPID_InkStrokes : int32
{
	DISPID_ISs_NewEnum = -4,
	DISPID_ISsItem = 0,
	DISPID_ISsCount = 1,
	DISPID_ISsValid = 2,
	DISPID_ISsInk = 3,
	DISPID_ISsAdd = 4,
	DISPID_ISsAddStrokes = 5,
	DISPID_ISsRemove = 6,
	DISPID_ISsRemoveStrokes = 7,
	DISPID_ISsToString = 8,
	DISPID_ISsModifyDrawingAttributes = 9,
	DISPID_ISsGetBoundingBox = 10,
	DISPID_ISsScaleToRectangle = 11,
	DISPID_ISsTransform = 12,
	DISPID_ISsMove = 13,
	DISPID_ISsRotate = 14,
	DISPID_ISsShear = 15,
	DISPID_ISsScale = 16,
	DISPID_ISsClip = 17,
	DISPID_ISsRecognitionResult = 18,
	DISPID_ISsRemoveRecognitionResult = 19,
}


[AllowDuplicates]
public enum DISPID_InkCustomStrokes : int32
{
	DISPID_ICSs_NewEnum = -4,
	DISPID_ICSsItem = 0,
	DISPID_ICSsCount = 1,
	DISPID_ICSsAdd = 2,
	DISPID_ICSsRemove = 3,
	DISPID_ICSsClear = 4,
}


[AllowDuplicates]
public enum DISPID_StrokeEvent : int32
{
	DISPID_SEStrokesAdded = 1,
	DISPID_SEStrokesRemoved = 2,
}


[AllowDuplicates]
public enum DISPID_Ink : int32
{
	DISPID_IStrokes = 1,
	DISPID_IExtendedProperties = 2,
	DISPID_IGetBoundingBox = 3,
	DISPID_IDeleteStrokes = 4,
	DISPID_IDeleteStroke = 5,
	DISPID_IExtractStrokes = 6,
	DISPID_IExtractWithRectangle = 7,
	DISPID_IDirty = 8,
	DISPID_ICustomStrokes = 9,
	DISPID_IClone = 10,
	DISPID_IHitTestCircle = 11,
	DISPID_IHitTestWithRectangle = 12,
	DISPID_IHitTestWithLasso = 13,
	DISPID_INearestPoint = 14,
	DISPID_ICreateStrokes = 15,
	DISPID_ICreateStroke = 16,
	DISPID_IAddStrokesAtRectangle = 17,
	DISPID_IClip = 18,
	DISPID_ISave = 19,
	DISPID_ILoad = 20,
	DISPID_ICreateStrokeFromPoints = 21,
	DISPID_IClipboardCopyWithRectangle = 22,
	DISPID_IClipboardCopy = 23,
	DISPID_ICanPaste = 24,
	DISPID_IClipboardPaste = 25,
}


[AllowDuplicates]
public enum DISPID_InkEvent : int32
{
	DISPID_IEInkAdded = 1,
	DISPID_IEInkDeleted = 2,
}


[AllowDuplicates]
public enum DISPID_InkRenderer : int32
{
	DISPID_IRGetViewTransform = 1,
	DISPID_IRSetViewTransform = 2,
	DISPID_IRGetObjectTransform = 3,
	DISPID_IRSetObjectTransform = 4,
	DISPID_IRDraw = 5,
	DISPID_IRDrawStroke = 6,
	DISPID_IRPixelToInkSpace = 7,
	DISPID_IRInkSpaceToPixel = 8,
	DISPID_IRPixelToInkSpaceFromPoints = 9,
	DISPID_IRInkSpaceToPixelFromPoints = 10,
	DISPID_IRMeasure = 11,
	DISPID_IRMeasureStroke = 12,
	DISPID_IRMove = 13,
	DISPID_IRRotate = 14,
	DISPID_IRScale = 15,
}


[AllowDuplicates]
public enum InkCollectorEventInterest : int32
{
	ICEI_DefaultEvents = -1,
	ICEI_CursorDown = 0,
	ICEI_Stroke = 1,
	ICEI_NewPackets = 2,
	ICEI_NewInAirPackets = 3,
	ICEI_CursorButtonDown = 4,
	ICEI_CursorButtonUp = 5,
	ICEI_CursorInRange = 6,
	ICEI_CursorOutOfRange = 7,
	ICEI_SystemGesture = 8,
	ICEI_TabletAdded = 9,
	ICEI_TabletRemoved = 10,
	ICEI_MouseDown = 11,
	ICEI_MouseMove = 12,
	ICEI_MouseUp = 13,
	ICEI_MouseWheel = 14,
	ICEI_DblClick = 15,
	ICEI_AllEvents = 16,
}


[AllowDuplicates]
public enum InkMouseButton : int32
{
	IMF_Left = 1,
	IMF_Right = 2,
	IMF_Middle = 4,
}


[AllowDuplicates]
public enum InkShiftKeyModifierFlags : int32
{
	IKM_Shift = 1,
	IKM_Control = 2,
	IKM_Alt = 4,
}


[AllowDuplicates]
public enum DISPID_InkCollectorEvent : int32
{
	DISPID_ICEStroke = 1,
	DISPID_ICECursorDown = 2,
	DISPID_ICENewPackets = 3,
	DISPID_ICENewInAirPackets = 4,
	DISPID_ICECursorButtonDown = 5,
	DISPID_ICECursorButtonUp = 6,
	DISPID_ICECursorInRange = 7,
	DISPID_ICECursorOutOfRange = 8,
	DISPID_ICESystemGesture = 9,
	DISPID_ICEGesture = 10,
	DISPID_ICETabletAdded = 11,
	DISPID_ICETabletRemoved = 12,
	DISPID_IOEPainting = 13,
	DISPID_IOEPainted = 14,
	DISPID_IOESelectionChanging = 15,
	DISPID_IOESelectionChanged = 16,
	DISPID_IOESelectionMoving = 17,
	DISPID_IOESelectionMoved = 18,
	DISPID_IOESelectionResizing = 19,
	DISPID_IOESelectionResized = 20,
	DISPID_IOEStrokesDeleting = 21,
	DISPID_IOEStrokesDeleted = 22,
	DISPID_IPEChangeUICues = 23,
	DISPID_IPEClick = 24,
	DISPID_IPEDblClick = 25,
	DISPID_IPEInvalidated = 26,
	DISPID_IPEMouseDown = 27,
	DISPID_IPEMouseEnter = 28,
	DISPID_IPEMouseHover = 29,
	DISPID_IPEMouseLeave = 30,
	DISPID_IPEMouseMove = 31,
	DISPID_IPEMouseUp = 32,
	DISPID_IPEMouseWheel = 33,
	DISPID_IPESizeModeChanged = 34,
	DISPID_IPEStyleChanged = 35,
	DISPID_IPESystemColorsChanged = 36,
	DISPID_IPEKeyDown = 37,
	DISPID_IPEKeyPress = 38,
	DISPID_IPEKeyUp = 39,
	DISPID_IPEResize = 40,
	DISPID_IPESizeChanged = 41,
}


[AllowDuplicates]
public enum InkOverlayEditingMode : int32
{
	IOEM_Ink = 0,
	IOEM_Delete = 1,
	IOEM_Select = 2,
}


[AllowDuplicates]
public enum InkOverlayAttachMode : int32
{
	IOAM_Behind = 0,
	IOAM_InFront = 1,
}


[AllowDuplicates]
public enum InkPictureSizeMode : int32
{
	IPSM_AutoSize = 0,
	IPSM_CenterImage = 1,
	IPSM_Normal = 2,
	IPSM_StretchImage = 3,
}


[AllowDuplicates]
public enum InkOverlayEraserMode : int32
{
	IOERM_StrokeErase = 0,
	IOERM_PointErase = 1,
}


[AllowDuplicates]
public enum InkCollectionMode : int32
{
	ICM_InkOnly = 0,
	ICM_GestureOnly = 1,
	ICM_InkAndGesture = 2,
}


[AllowDuplicates]
public enum DISPID_InkCollector : int32
{
	DISPID_ICEnabled = 1,
	DISPID_ICHwnd = 2,
	DISPID_ICPaint = 3,
	DISPID_ICText = 4,
	DISPID_ICDefaultDrawingAttributes = 5,
	DISPID_ICRenderer = 6,
	DISPID_ICInk = 7,
	DISPID_ICAutoRedraw = 8,
	DISPID_ICCollectingInk = 9,
	DISPID_ICSetEventInterest = 10,
	DISPID_ICGetEventInterest = 11,
	DISPID_IOEditingMode = 12,
	DISPID_IOSelection = 13,
	DISPID_IOAttachMode = 14,
	DISPID_IOHitTestSelection = 15,
	DISPID_IODraw = 16,
	DISPID_IPPicture = 17,
	DISPID_IPSizeMode = 18,
	DISPID_IPBackColor = 19,
	DISPID_ICCursors = 20,
	DISPID_ICMarginX = 21,
	DISPID_ICMarginY = 22,
	DISPID_ICSetWindowInputRectangle = 23,
	DISPID_ICGetWindowInputRectangle = 24,
	DISPID_ICTablet = 25,
	DISPID_ICSetAllTabletsMode = 26,
	DISPID_ICSetSingleTabletIntegratedMode = 27,
	DISPID_ICCollectionMode = 28,
	DISPID_ICSetGestureStatus = 29,
	DISPID_ICGetGestureStatus = 30,
	DISPID_ICDynamicRendering = 31,
	DISPID_ICDesiredPacketDescription = 32,
	DISPID_IOEraserMode = 33,
	DISPID_IOEraserWidth = 34,
	DISPID_ICMouseIcon = 35,
	DISPID_ICMousePointer = 36,
	DISPID_IPInkEnabled = 37,
	DISPID_ICSupportHighContrastInk = 38,
	DISPID_IOSupportHighContrastSelectionUI = 39,
}


[AllowDuplicates]
public enum DISPID_InkRecognizer : int32
{
	DISPID_RecoClsid = 1,
	DISPID_RecoName = 2,
	DISPID_RecoVendor = 3,
	DISPID_RecoCapabilities = 4,
	DISPID_RecoLanguageID = 5,
	DISPID_RecoPreferredPacketDescription = 6,
	DISPID_RecoCreateRecognizerContext = 7,
	DISPID_RecoSupportedProperties = 8,
}


[AllowDuplicates]
public enum InkRecognizerCapabilities : int32
{
	IRC_DontCare = 1,
	IRC_Object = 2,
	IRC_FreeInput = 4,
	IRC_LinedInput = 8,
	IRC_BoxedInput = 16,
	IRC_CharacterAutoCompletionInput = 32,
	IRC_RightAndDown = 64,
	IRC_LeftAndDown = 128,
	IRC_DownAndLeft = 256,
	IRC_DownAndRight = 512,
	IRC_ArbitraryAngle = 1024,
	IRC_Lattice = 2048,
	IRC_AdviseInkChange = 4096,
	IRC_StrokeReorder = 8192,
	IRC_Personalizable = 16384,
	IRC_PrefersArbitraryAngle = 32768,
	IRC_PrefersParagraphBreaking = 65536,
	IRC_PrefersSegmentation = 131072,
	IRC_Cursive = 262144,
	IRC_TextPrediction = 524288,
	IRC_Alpha = 1048576,
	IRC_Beta = 2097152,
}


[AllowDuplicates]
public enum DISPID_InkRecognizer2 : int32
{
	DISPID_RecoId = 0,
	DISPID_RecoUnicodeRanges = 1,
}


[AllowDuplicates]
public enum DISPID_InkRecognizers : int32
{
	DISPID_IRecos_NewEnum = -4,
	DISPID_IRecosItem = 0,
	DISPID_IRecosCount = 1,
	DISPID_IRecosGetDefaultRecognizer = 2,
}


[AllowDuplicates]
public enum InkRecognizerCharacterAutoCompletionMode : int32
{
	IRCACM_Full = 0,
	IRCACM_Prefix = 1,
	IRCACM_Random = 2,
}


[AllowDuplicates]
public enum InkRecognitionModes : int32
{
	IRM_None = 0,
	IRM_WordModeOnly = 1,
	IRM_Coerce = 2,
	IRM_TopInkBreaksOnly = 4,
	IRM_PrefixOk = 8,
	IRM_LineMode = 16,
	IRM_DisablePersonalization = 32,
	IRM_AutoSpace = 64,
	IRM_Max = 128,
}


[AllowDuplicates]
public enum DISPID_InkRecognitionEvent : int32
{
	DISPID_IRERecognitionWithAlternates = 1,
	DISPID_IRERecognition = 2,
}


[AllowDuplicates]
public enum DISPID_InkRecoContext : int32
{
	DISPID_IRecoCtx_Strokes = 1,
	DISPID_IRecoCtx_CharacterAutoCompletionMode = 2,
	DISPID_IRecoCtx_Factoid = 3,
	DISPID_IRecoCtx_WordList = 4,
	DISPID_IRecoCtx_Recognizer = 5,
	DISPID_IRecoCtx_Guide = 6,
	DISPID_IRecoCtx_Flags = 7,
	DISPID_IRecoCtx_PrefixText = 8,
	DISPID_IRecoCtx_SuffixText = 9,
	DISPID_IRecoCtx_StopRecognition = 10,
	DISPID_IRecoCtx_Clone = 11,
	DISPID_IRecoCtx_Recognize = 12,
	DISPID_IRecoCtx_StopBackgroundRecognition = 13,
	DISPID_IRecoCtx_EndInkInput = 14,
	DISPID_IRecoCtx_BackgroundRecognize = 15,
	DISPID_IRecoCtx_BackgroundRecognizeWithAlternates = 16,
	DISPID_IRecoCtx_IsStringSupported = 17,
}


[AllowDuplicates]
public enum DISPID_InkRecoContext2 : int32
{
	DISPID_IRecoCtx2_EnabledUnicodeRanges = 0,
}


[AllowDuplicates]
public enum InkRecognitionAlternatesSelection : int32
{
	IRAS_Start = 0,
	IRAS_DefaultCount = 10,
	IRAS_All = -1,
}


[AllowDuplicates]
public enum DISPID_InkRecognitionResult : int32
{
	DISPID_InkRecognitionResult_TopString = 1,
	DISPID_InkRecognitionResult_TopAlternate = 2,
	DISPID_InkRecognitionResult_Strokes = 3,
	DISPID_InkRecognitionResult_TopConfidence = 4,
	DISPID_InkRecognitionResult_AlternatesFromSelection = 5,
	DISPID_InkRecognitionResult_ModifyTopAlternate = 6,
	DISPID_InkRecognitionResult_SetResultOnStrokes = 7,
}


[AllowDuplicates]
public enum DISPID_InkRecoAlternate : int32
{
	DISPID_InkRecoAlternate_String = 1,
	DISPID_InkRecoAlternate_LineNumber = 2,
	DISPID_InkRecoAlternate_Baseline = 3,
	DISPID_InkRecoAlternate_Midline = 4,
	DISPID_InkRecoAlternate_Ascender = 5,
	DISPID_InkRecoAlternate_Descender = 6,
	DISPID_InkRecoAlternate_Confidence = 7,
	DISPID_InkRecoAlternate_Strokes = 8,
	DISPID_InkRecoAlternate_GetStrokesFromStrokeRanges = 9,
	DISPID_InkRecoAlternate_GetStrokesFromTextRange = 10,
	DISPID_InkRecoAlternate_GetTextRangeFromStrokes = 11,
	DISPID_InkRecoAlternate_GetPropertyValue = 12,
	DISPID_InkRecoAlternate_LineAlternates = 13,
	DISPID_InkRecoAlternate_ConfidenceAlternates = 14,
	DISPID_InkRecoAlternate_AlternatesWithConstantPropertyValues = 15,
}


[AllowDuplicates]
public enum DISPID_InkRecognitionAlternates : int32
{
	DISPID_InkRecognitionAlternates_NewEnum = -4,
	DISPID_InkRecognitionAlternates_Item = 0,
	DISPID_InkRecognitionAlternates_Count = 1,
	DISPID_InkRecognitionAlternates_Strokes = 2,
}


[AllowDuplicates]
public enum DISPID_InkRecognizerGuide : int32
{
	DISPID_IRGWritingBox = 1,
	DISPID_IRGDrawnBox = 2,
	DISPID_IRGRows = 3,
	DISPID_IRGColumns = 4,
	DISPID_IRGMidline = 5,
	DISPID_IRGGuideData = 6,
}


[AllowDuplicates]
public enum DISPID_InkWordList : int32
{
	DISPID_InkWordList_AddWord = 0,
	DISPID_InkWordList_RemoveWord = 1,
	DISPID_InkWordList_Merge = 2,
}


[AllowDuplicates]
public enum DISPID_InkWordList2 : int32
{
	DISPID_InkWordList2_AddWords = 3,
}


[AllowDuplicates]
public enum InkDivisionType : int32
{
	IDT_Segment = 0,
	IDT_Line = 1,
	IDT_Paragraph = 2,
	IDT_Drawing = 3,
}


[AllowDuplicates]
public enum DISPID_InkDivider : int32
{
	DISPID_IInkDivider_Strokes = 1,
	DISPID_IInkDivider_RecognizerContext = 2,
	DISPID_IInkDivider_LineHeight = 3,
	DISPID_IInkDivider_Divide = 4,
}


[AllowDuplicates]
public enum DISPID_InkDivisionResult : int32
{
	DISPID_IInkDivisionResult_Strokes = 1,
	DISPID_IInkDivisionResult_ResultByType = 2,
}


[AllowDuplicates]
public enum DISPID_InkDivisionUnit : int32
{
	DISPID_IInkDivisionUnit_Strokes = 1,
	DISPID_IInkDivisionUnit_DivisionType = 2,
	DISPID_IInkDivisionUnit_RecognizedString = 3,
	DISPID_IInkDivisionUnit_RotationTransform = 4,
}


[AllowDuplicates]
public enum DISPID_InkDivisionUnits : int32
{
	DISPID_IInkDivisionUnits_NewEnum = -4,
	DISPID_IInkDivisionUnits_Item = 0,
	DISPID_IInkDivisionUnits_Count = 1,
}


[AllowDuplicates]
public enum DISPID_PenInputPanel : int32
{
	DISPID_PIPAttachedEditWindow = 0,
	DISPID_PIPFactoid = 1,
	DISPID_PIPCurrentPanel = 2,
	DISPID_PIPDefaultPanel = 3,
	DISPID_PIPVisible = 4,
	DISPID_PIPTop = 5,
	DISPID_PIPLeft = 6,
	DISPID_PIPWidth = 7,
	DISPID_PIPHeight = 8,
	DISPID_PIPMoveTo = 9,
	DISPID_PIPCommitPendingInput = 10,
	DISPID_PIPRefresh = 11,
	DISPID_PIPBusy = 12,
	DISPID_PIPVerticalOffset = 13,
	DISPID_PIPHorizontalOffset = 14,
	DISPID_PIPEnableTsf = 15,
	DISPID_PIPAutoShow = 16,
}


[AllowDuplicates]
public enum DISPID_PenInputPanelEvents : int32
{
	DISPID_PIPEVisibleChanged = 0,
	DISPID_PIPEPanelChanged = 1,
	DISPID_PIPEInputFailed = 2,
	DISPID_PIPEPanelMoving = 3,
}


[AllowDuplicates]
public enum VisualState : int32
{
	InPlace = 0,
	Floating = 1,
	DockedTop = 2,
	DockedBottom = 3,
	Closed = 4,
}


[AllowDuplicates]
public enum InteractionMode : int32
{
	InteractionMode_InPlace = 0,
	InteractionMode_Floating = 1,
	InteractionMode_DockedTop = 2,
	InteractionMode_DockedBottom = 3,
}


[AllowDuplicates]
public enum InPlaceState : int32
{
	InPlaceState_Auto = 0,
	InPlaceState_HoverTarget = 1,
	InPlaceState_Expanded = 2,
}


[AllowDuplicates]
public enum PanelInputArea : int32
{
	PanelInputArea_Auto = 0,
	PanelInputArea_Keyboard = 1,
	PanelInputArea_WritingPad = 2,
	PanelInputArea_CharacterPad = 3,
}


[AllowDuplicates]
public enum CorrectionMode : int32
{
	CorrectionMode_NotVisible = 0,
	CorrectionMode_PreInsertion = 1,
	CorrectionMode_PostInsertionCollapsed = 2,
	CorrectionMode_PostInsertionExpanded = 3,
}


[AllowDuplicates]
public enum CorrectionPosition : int32
{
	CorrectionPosition_Auto = 0,
	CorrectionPosition_Bottom = 1,
	CorrectionPosition_Top = 2,
}


[AllowDuplicates]
public enum InPlaceDirection : int32
{
	InPlaceDirection_Auto = 0,
	InPlaceDirection_Bottom = 1,
	InPlaceDirection_Top = 2,
}


[AllowDuplicates]
public enum EventMask : int32
{
	EventMask_InPlaceStateChanging = 1,
	EventMask_InPlaceStateChanged = 2,
	EventMask_InPlaceSizeChanging = 4,
	EventMask_InPlaceSizeChanged = 8,
	EventMask_InputAreaChanging = 16,
	EventMask_InputAreaChanged = 32,
	EventMask_CorrectionModeChanging = 64,
	EventMask_CorrectionModeChanged = 128,
	EventMask_InPlaceVisibilityChanging = 256,
	EventMask_InPlaceVisibilityChanged = 512,
	EventMask_TextInserting = 1024,
	EventMask_TextInserted = 2048,
	EventMask_All = 4095,
}


[AllowDuplicates]
public enum PanelType : int32
{
	PT_Default = 0,
	PT_Inactive = 1,
	PT_Handwriting = 2,
	PT_Keyboard = 3,
}


[AllowDuplicates]
public enum FLICKDIRECTION : int32
{
	FLICKDIRECTION_MIN = 0,
	FLICKDIRECTION_RIGHT = 0,
	FLICKDIRECTION_UPRIGHT = 1,
	FLICKDIRECTION_UP = 2,
	FLICKDIRECTION_UPLEFT = 3,
	FLICKDIRECTION_LEFT = 4,
	FLICKDIRECTION_DOWNLEFT = 5,
	FLICKDIRECTION_DOWN = 6,
	FLICKDIRECTION_DOWNRIGHT = 7,
	FLICKDIRECTION_INVALID = 8,
}


[AllowDuplicates]
public enum FLICKMODE : int32
{
	FLICKMODE_MIN = 0,
	FLICKMODE_OFF = 0,
	FLICKMODE_ON = 1,
	FLICKMODE_LEARNING = 2,
	FLICKMODE_MAX = 2,
	FLICKMODE_DEFAULT = 1,
}


[AllowDuplicates]
public enum FLICKACTION_COMMANDCODE : int32
{
	FLICKACTION_COMMANDCODE_NULL = 0,
	FLICKACTION_COMMANDCODE_SCROLL = 1,
	FLICKACTION_COMMANDCODE_APPCOMMAND = 2,
	FLICKACTION_COMMANDCODE_CUSTOMKEY = 3,
	FLICKACTION_COMMANDCODE_KEYMODIFIER = 4,
}


[AllowDuplicates]
public enum SCROLLDIRECTION : int32
{
	SCROLLDIRECTION_UP = 0,
	SCROLLDIRECTION_DOWN = 1,
}


[AllowDuplicates]
public enum KEYMODIFIER : int32
{
	KEYMODIFIER_CONTROL = 1,
	KEYMODIFIER_MENU = 2,
	KEYMODIFIER_SHIFT = 4,
	KEYMODIFIER_WIN = 8,
	KEYMODIFIER_ALTGR = 16,
	KEYMODIFIER_EXT = 32,
}


[AllowDuplicates]
public enum MouseButton : int32
{
	NO_BUTTON = 0,
	LEFT_BUTTON = 1,
	RIGHT_BUTTON = 2,
	MIDDLE_BUTTON = 4,
}


[AllowDuplicates]
public enum SelAlignmentConstants : int32
{
	rtfLeft = 0,
	rtfRight = 1,
	rtfCenter = 2,
}


[AllowDuplicates]
public enum DISPID_InkEdit : int32
{
	DISPID_Text = 0,
	DISPID_TextRTF = 1,
	DISPID_Hwnd = 2,
	DISPID_DisableNoScroll = 3,
	DISPID_Locked = 4,
	DISPID_Enabled = 5,
	DISPID_MaxLength = 6,
	DISPID_MultiLine = 7,
	DISPID_ScrollBars = 8,
	DISPID_RTSelStart = 9,
	DISPID_RTSelLength = 10,
	DISPID_RTSelText = 11,
	DISPID_SelAlignment = 12,
	DISPID_SelBold = 13,
	DISPID_SelCharOffset = 14,
	DISPID_SelColor = 15,
	DISPID_SelFontName = 16,
	DISPID_SelFontSize = 17,
	DISPID_SelItalic = 18,
	DISPID_SelRTF = 19,
	DISPID_SelUnderline = 20,
	DISPID_DragIcon = 21,
	DISPID_Status = 22,
	DISPID_UseMouseForInput = 23,
	DISPID_InkMode = 24,
	DISPID_InkInsertMode = 25,
	DISPID_RecoTimeout = 26,
	DISPID_DrawAttr = 27,
	DISPID_Recognizer = 28,
	DISPID_Factoid = 29,
	DISPID_SelInk = 30,
	DISPID_SelInksDisplayMode = 31,
	DISPID_Recognize = 32,
	DISPID_GetGestStatus = 33,
	DISPID_SetGestStatus = 34,
	DISPID_Refresh = 35,
}


[AllowDuplicates]
public enum DISPID_InkEditEvents : int32
{
	DISPID_IeeChange = 1,
	DISPID_IeeSelChange = 2,
	DISPID_IeeKeyDown = 3,
	DISPID_IeeKeyUp = 4,
	DISPID_IeeMouseUp = 5,
	DISPID_IeeMouseDown = 6,
	DISPID_IeeKeyPress = 7,
	DISPID_IeeDblClick = 8,
	DISPID_IeeClick = 9,
	DISPID_IeeMouseMove = 10,
	DISPID_IeeCursorDown = 21,
	DISPID_IeeStroke = 22,
	DISPID_IeeGesture = 23,
	DISPID_IeeRecognitionResult = 24,
}


[AllowDuplicates]
public enum InkMode : int32
{
	IEM_Disabled = 0,
	IEM_Ink = 1,
	IEM_InkAndGesture = 2,
}


[AllowDuplicates]
public enum InkInsertMode : int32
{
	IEM_InsertText = 0,
	IEM_InsertInk = 1,
}


[AllowDuplicates]
public enum InkEditStatus : int32
{
	IES_Idle = 0,
	IES_Collecting = 1,
	IES_Recognizing = 2,
}


[AllowDuplicates]
public enum InkDisplayMode : int32
{
	IDM_Ink = 0,
	IDM_Text = 1,
}


[AllowDuplicates]
public enum AppearanceConstants : int32
{
	rtfFlat = 0,
	rtfThreeD = 1,
}


[AllowDuplicates]
public enum BorderStyleConstants : int32
{
	rtfNoBorder = 0,
	rtfFixedSingle = 1,
}


[AllowDuplicates]
public enum ScrollBarsConstants : int32
{
	rtfNone = 0,
	rtfHorizontal = 1,
	rtfVertical = 2,
	rtfBoth = 3,
}


[AllowDuplicates]
public enum MICUIELEMENT : int32
{
	MICUIELEMENT_BUTTON_WRITE = 1,
	MICUIELEMENT_BUTTON_ERASE = 2,
	MICUIELEMENT_BUTTON_CORRECT = 4,
	MICUIELEMENT_BUTTON_CLEAR = 8,
	MICUIELEMENT_BUTTON_UNDO = 16,
	MICUIELEMENT_BUTTON_REDO = 32,
	MICUIELEMENT_BUTTON_INSERT = 64,
	MICUIELEMENT_BUTTON_CANCEL = 128,
	MICUIELEMENT_INKPANEL_BACKGROUND = 256,
	MICUIELEMENT_RESULTPANEL_BACKGROUND = 512,
}


[AllowDuplicates]
public enum MICUIELEMENTSTATE : int32
{
	MICUIELEMENTSTATE_NORMAL = 1,
	MICUIELEMENTSTATE_HOT = 2,
	MICUIELEMENTSTATE_PRESSED = 3,
	MICUIELEMENTSTATE_DISABLED = 4,
}


[AllowDuplicates]
public enum DISPID_MathInputControlEvents : int32
{
	DISPID_MICInsert = 0,
	DISPID_MICClose = 1,
	DISPID_MICPaint = 2,
	DISPID_MICClear = 3,
}


[AllowDuplicates]
public enum RealTimeStylusDataInterest : int32
{
	RTSDI_AllData = -1,
	RTSDI_None = 0,
	RTSDI_Error = 1,
	RTSDI_RealTimeStylusEnabled = 2,
	RTSDI_RealTimeStylusDisabled = 4,
	RTSDI_StylusNew = 8,
	RTSDI_StylusInRange = 16,
	RTSDI_InAirPackets = 32,
	RTSDI_StylusOutOfRange = 64,
	RTSDI_StylusDown = 128,
	RTSDI_Packets = 256,
	RTSDI_StylusUp = 512,
	RTSDI_StylusButtonUp = 1024,
	RTSDI_StylusButtonDown = 2048,
	RTSDI_SystemEvents = 4096,
	RTSDI_TabletAdded = 8192,
	RTSDI_TabletRemoved = 16384,
	RTSDI_CustomStylusDataAdded = 32768,
	RTSDI_UpdateMapping = 65536,
	RTSDI_DefaultEvents = 37766,
}


[AllowDuplicates]
public enum StylusQueue : int32
{
	SyncStylusQueue = 1,
	AsyncStylusQueueImmediate = 2,
	AsyncStylusQueue = 3,
}


[AllowDuplicates]
public enum RealTimeStylusLockType : int32
{
	RTSLT_ObjLock = 1,
	RTSLT_SyncEventLock = 2,
	RTSLT_AsyncEventLock = 4,
	RTSLT_ExcludeCallback = 8,
	RTSLT_SyncObjLock = 11,
	RTSLT_AsyncObjLock = 13,
}


[AllowDuplicates]
public enum LINE_METRICS : int32
{
	LM_BASELINE = 0,
	LM_MIDLINE = 1,
	LM_ASCENDER = 2,
	LM_DESCENDER = 3,
}


[AllowDuplicates]
public enum CONFIDENCE_LEVEL : int32
{
	CFL_STRONG = 0,
	CFL_INTERMEDIATE = 1,
	CFL_POOR = 2,
}


[AllowDuplicates]
public enum ALT_BREAKS : int32
{
	ALT_BREAKS_SAME = 0,
	ALT_BREAKS_UNIQUE = 1,
	ALT_BREAKS_FULL = 2,
}


[AllowDuplicates]
public enum RECO_TYPE : int32
{
	RECO_TYPE_WSTRING = 0,
	RECO_TYPE_WCHAR = 1,
}

#endregion

#region Function Pointers
public function HRESULT PfnRecoCallback(uint32 param0, uint8* param1, HRECOCONTEXT param2);

#endregion

#region Structs
[CRepr]
public struct SYSTEM_EVENT_DATA
{
	public uint8 bModifier;
	public char16 wKey;
	public int32 xPos;
	public int32 yPos;
	public uint8 bCursorMode;
	public uint32 dwButtonState;
}

[CRepr]
public struct STROKE_RANGE
{
	public uint32 iStrokeBegin;
	public uint32 iStrokeEnd;
}

[CRepr]
public struct PROPERTY_METRICS
{
	public int32 nLogicalMin;
	public int32 nLogicalMax;
	public PROPERTY_UNITS Units;
	public float fResolution;
}

[CRepr]
public struct PACKET_PROPERTY
{
	public Guid guid;
	public PROPERTY_METRICS PropertyMetrics;
}

[CRepr]
public struct PACKET_DESCRIPTION
{
	public uint32 cbPacketSize;
	public uint32 cPacketProperties;
	public PACKET_PROPERTY* pPacketProperties;
	public uint32 cButtons;
	public Guid* pguidButtons;
}

[CRepr]
public struct INKMETRIC
{
	public int32 iHeight;
	public int32 iFontAscent;
	public int32 iFontDescent;
	public uint32 dwFlags;
	public COLORREF color;
}

[CRepr]
public struct InkRecoGuide
{
	public RECT rectWritingBox;
	public RECT rectDrawnBox;
	public int32 cRows;
	public int32 cColumns;
	public int32 midline;
}

[CRepr]
public struct FLICK_POINT
{
	public int32 _bitfield;
}

[CRepr]
public struct FLICK_DATA
{
	public int32 _bitfield;
}

[CRepr]
public struct IEC_STROKEINFO
{
	public NMHDR nmhdr;
	public IInkCursor* Cursor;
	public IInkStrokeDisp* Stroke;
}

[CRepr]
public struct IEC_GESTUREINFO
{
	public NMHDR nmhdr;
	public IInkCursor* Cursor;
	public IInkStrokes* Strokes;
	public VARIANT Gestures;
}

[CRepr]
public struct IEC_RECOGNITIONRESULTINFO
{
	public NMHDR nmhdr;
	public IInkRecognitionResult* RecognitionResult;
}

[CRepr]
public struct StylusInfo
{
	public uint32 tcid;
	public uint32 cid;
	public BOOL bIsInvertedCursor;
}

[CRepr]
public struct GESTURE_DATA
{
	public int32 gestureId;
	public int32 recoConfidence;
	public int32 strokeCount;
}

[CRepr]
public struct DYNAMIC_RENDERER_CACHED_DATA
{
	public int32 strokeId;
	public IDynamicRenderer* dynamicRenderer;
}

[CRepr]
public struct RECO_GUIDE
{
	public int32 xOrigin;
	public int32 yOrigin;
	public int32 cxBox;
	public int32 cyBox;
	public int32 cxBase;
	public int32 cyBase;
	public int32 cHorzBox;
	public int32 cVertBox;
	public int32 cyMid;
}

[CRepr]
public struct RECO_ATTRS
{
	public uint32 dwRecoCapabilityFlags;
	public char16[32] awcVendorName;
	public char16[64] awcFriendlyName;
	public uint16[64] awLanguageId;
}

[CRepr]
public struct RECO_RANGE
{
	public uint32 iwcBegin;
	public uint32 cCount;
}

[CRepr]
public struct LINE_SEGMENT
{
	public POINT PtA;
	public POINT PtB;
}

[CRepr]
public struct LATTICE_METRICS
{
	public LINE_SEGMENT lsBaseline;
	public int16 iMidlineOffset;
}

[CRepr]
public struct RECO_LATTICE_PROPERTY
{
	public Guid guidProperty;
	public uint16 cbPropertyValue;
	public uint8* pPropertyValue;
}

[CRepr]
public struct RECO_LATTICE_PROPERTIES
{
	public uint32 cProperties;
	public RECO_LATTICE_PROPERTY** apProps;
}

[CRepr]
public struct RECO_LATTICE_ELEMENT
{
	public int32 score;
	public uint16 type;
	public uint8* pData;
	public uint32 ulNextColumn;
	public uint32 ulStrokeNumber;
	public RECO_LATTICE_PROPERTIES epProp;
}

[CRepr]
public struct RECO_LATTICE_COLUMN
{
	public uint32 key;
	public RECO_LATTICE_PROPERTIES cpProp;
	public uint32 cStrokes;
	public uint32* pStrokes;
	public uint32 cLatticeElements;
	public RECO_LATTICE_ELEMENT* pLatticeElements;
}

[CRepr]
public struct RECO_LATTICE
{
	public uint32 ulColumnCount;
	public RECO_LATTICE_COLUMN* pLatticeColumns;
	public uint32 ulPropertyCount;
	public Guid* pGuidProperties;
	public uint32 ulBestResultColumnCount;
	public uint32* pulBestResultColumns;
	public uint32* pulBestResultIndexes;
}

[CRepr]
public struct CHARACTER_RANGE
{
	public char16 wcLow;
	public uint16 cChars;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_InkDisp = .(0x937c1a34, 0x151d, 0x4610, 0x9c, 0xa6, 0xa8, 0xcc, 0x9b, 0xdb, 0x5d, 0x83);


	public const Guid CLSID_InkOverlay = .(0x65d00646, 0xcde3, 0x4a88, 0x91, 0x63, 0x67, 0x69, 0xf0, 0xf1, 0xa9, 0x7d);


	public const Guid CLSID_InkPicture = .(0x04a1e553, 0xfe36, 0x4fde, 0x86, 0x5e, 0x34, 0x41, 0x94, 0xe6, 0x94, 0x24);


	public const Guid CLSID_InkCollector = .(0x43fb1553, 0xad74, 0x4ee8, 0x88, 0xe4, 0x3e, 0x6d, 0xaa, 0xc9, 0x15, 0xdb);


	public const Guid CLSID_InkDrawingAttributes = .(0xd8bf32a2, 0x05a5, 0x44c3, 0xb3, 0xaa, 0x5e, 0x80, 0xac, 0x7d, 0x25, 0x76);


	public const Guid CLSID_InkRectangle = .(0x43b07326, 0xaae0, 0x4b62, 0xa8, 0x3d, 0x5f, 0xd7, 0x68, 0xb7, 0x35, 0x3c);


	public const Guid CLSID_InkRenderer = .(0x9c1cc6e4, 0xd7eb, 0x4eeb, 0x90, 0x91, 0x15, 0xa7, 0xc8, 0x79, 0x1e, 0xd9);


	public const Guid CLSID_InkTransform = .(0xe3d5d93c, 0x1663, 0x4a78, 0xa1, 0xa7, 0x22, 0x37, 0x5d, 0xfe, 0xba, 0xee);


	public const Guid CLSID_InkRecognizers = .(0x9fd4e808, 0xf6e6, 0x4e65, 0x98, 0xd3, 0xaa, 0x39, 0x05, 0x4c, 0x12, 0x55);


	public const Guid CLSID_InkRecognizerContext = .(0xaac46a37, 0x9229, 0x4fc0, 0x8c, 0xce, 0x44, 0x97, 0x56, 0x9b, 0xf4, 0xd1);


	public const Guid CLSID_InkRecognizerGuide = .(0x8770d941, 0xa63a, 0x4671, 0xa3, 0x75, 0x28, 0x55, 0xa1, 0x8e, 0xba, 0x73);


	public const Guid CLSID_InkTablets = .(0x6e4fcb12, 0x510a, 0x4d40, 0x93, 0x04, 0x1d, 0xa1, 0x0a, 0xe9, 0x14, 0x7c);


	public const Guid CLSID_InkWordList = .(0x9de85094, 0xf71f, 0x44f1, 0x84, 0x71, 0x15, 0xa2, 0xfa, 0x76, 0xfc, 0xf3);


	public const Guid CLSID_InkStrokes = .(0x48f491bc, 0x240e, 0x4860, 0xb0, 0x79, 0xa1, 0xe9, 0x4d, 0x3d, 0x2c, 0x86);


	public const Guid CLSID_Ink = .(0x13de4a42, 0x8d21, 0x4c8e, 0xbf, 0x9c, 0x8f, 0x69, 0xcb, 0x06, 0x8f, 0xca);


	public const Guid CLSID_SketchInk = .(0xf0291081, 0xe87c, 0x4e07, 0x97, 0xda, 0xa0, 0xa0, 0x37, 0x61, 0xe5, 0x86);


	public const Guid CLSID_InkDivider = .(0x8854f6a0, 0x4683, 0x4ae7, 0x91, 0x91, 0x75, 0x2f, 0xe6, 0x46, 0x12, 0xc3);


	public const Guid CLSID_HandwrittenTextInsertion = .(0x9f074ee2, 0xe6e9, 0x4d8a, 0xa0, 0x47, 0xeb, 0x5b, 0x5c, 0x3c, 0x55, 0xda);


	public const Guid CLSID_PenInputPanel = .(0xf744e496, 0x1b5a, 0x489e, 0x81, 0xdc, 0xfb, 0xd7, 0xac, 0x62, 0x98, 0xa8);


	public const Guid CLSID_TextInputPanel = .(0xf9b189d7, 0x228b, 0x4f2b, 0x86, 0x50, 0xb9, 0x7f, 0x59, 0xe0, 0x2c, 0x8c);


	public const Guid CLSID_PenInputPanel_Internal = .(0x802b1fb9, 0x056b, 0x4720, 0xb0, 0xcc, 0x80, 0xd2, 0x3b, 0x71, 0x17, 0x1e);


	public const Guid CLSID_InkEdit = .(0xe5ca59f5, 0x57c4, 0x4dd8, 0x9b, 0xd6, 0x1d, 0xee, 0xed, 0xd2, 0x7a, 0xf4);


	public const Guid CLSID_MathInputControl = .(0xc561816c, 0x14d8, 0x4090, 0x83, 0x0c, 0x98, 0xd9, 0x94, 0xb2, 0x1c, 0x7b);


	public const Guid CLSID_RealTimeStylus = .(0xe26b366d, 0xf998, 0x43ce, 0x83, 0x6f, 0xcb, 0x6d, 0x90, 0x44, 0x32, 0xb0);


	public const Guid CLSID_DynamicRenderer = .(0xecd32aea, 0x746f, 0x4dcb, 0xbf, 0x68, 0x08, 0x27, 0x57, 0xfa, 0xff, 0x18);


	public const Guid CLSID_GestureRecognizer = .(0xea30c654, 0xc62c, 0x441f, 0xac, 0x00, 0x95, 0xf9, 0xa1, 0x96, 0x78, 0x2c);


	public const Guid CLSID_StrokeBuilder = .(0xe810cee7, 0x6e51, 0x4cb0, 0xaa, 0x3a, 0x0b, 0x98, 0x5b, 0x70, 0xda, 0xf7);


	public const Guid CLSID_TipAutoCompleteClient = .(0x807c1e6c, 0x1d00, 0x453f, 0xb9, 0x20, 0xb6, 0x1b, 0xb7, 0xcd, 0xd9, 0x97);


}
#endregion

#region COM Types
[CRepr]struct IInkRectangle : IDispatch
{
	public new const Guid IID = .(0x9794ff82, 0x6071, 0x4717, 0x8a, 0x8b, 0x6a, 0xc7, 0xc6, 0x4a, 0x68, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Bottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Bottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Right;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Right;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* Rect) get_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT Rect) put_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Top, int32* Left, int32* Bottom, int32* Right) GetRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Top, int32 Left, int32 Bottom, int32 Right) SetRectangle;
	}


	public HRESULT get_Top(int32* Units) mut => VT.[Friend]get_Top(&this, Units);

	public HRESULT put_Top(int32 Units) mut => VT.[Friend]put_Top(&this, Units);

	public HRESULT get_Left(int32* Units) mut => VT.[Friend]get_Left(&this, Units);

	public HRESULT put_Left(int32 Units) mut => VT.[Friend]put_Left(&this, Units);

	public HRESULT get_Bottom(int32* Units) mut => VT.[Friend]get_Bottom(&this, Units);

	public HRESULT put_Bottom(int32 Units) mut => VT.[Friend]put_Bottom(&this, Units);

	public HRESULT get_Right(int32* Units) mut => VT.[Friend]get_Right(&this, Units);

	public HRESULT put_Right(int32 Units) mut => VT.[Friend]put_Right(&this, Units);

	public HRESULT get_Data(RECT* Rect) mut => VT.[Friend]get_Data(&this, Rect);

	public HRESULT put_Data(RECT Rect) mut => VT.[Friend]put_Data(&this, Rect);

	public HRESULT GetRectangle(int32* Top, int32* Left, int32* Bottom, int32* Right) mut => VT.[Friend]GetRectangle(&this, Top, Left, Bottom, Right);

	public HRESULT SetRectangle(int32 Top, int32 Left, int32 Bottom, int32 Right) mut => VT.[Friend]SetRectangle(&this, Top, Left, Bottom, Right);
}

[CRepr]struct IInkExtendedProperty : IDispatch
{
	public new const Guid IID = .(0xdb489209, 0xb7c3, 0x411d, 0x90, 0xf6, 0x15, 0x48, 0xcf, 0xff, 0x27, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Guid) get_Guid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Data) get_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Data) put_Data;
	}


	public HRESULT get_Guid(BSTR* Guid) mut => VT.[Friend]get_Guid(&this, Guid);

	public HRESULT get_Data(VARIANT* Data) mut => VT.[Friend]get_Data(&this, Data);

	public HRESULT put_Data(VARIANT Data) mut => VT.[Friend]put_Data(&this, Data);
}

[CRepr]struct IInkExtendedProperties : IDispatch
{
	public new const Guid IID = .(0x89f2a8be, 0x95a9, 0x4530, 0x8b, 0x8f, 0x88, 0xe9, 0x71, 0xe3, 0xe2, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Identifier, IInkExtendedProperty** Item) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Guid, VARIANT Data, IInkExtendedProperty** InkExtendedProperty) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Identifier) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Guid, int16* DoesPropertyExist) DoesPropertyExist;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT Item(VARIANT Identifier, IInkExtendedProperty** Item) mut => VT.[Friend]Item(&this, Identifier, Item);

	public HRESULT Add(BSTR Guid, VARIANT Data, IInkExtendedProperty** InkExtendedProperty) mut => VT.[Friend]Add(&this, Guid, Data, InkExtendedProperty);

	public HRESULT Remove(VARIANT Identifier) mut => VT.[Friend]Remove(&this, Identifier);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT DoesPropertyExist(BSTR Guid, int16* DoesPropertyExist) mut => VT.[Friend]DoesPropertyExist(&this, Guid, DoesPropertyExist);
}

[CRepr]struct IInkDrawingAttributes : IDispatch
{
	public new const Guid IID = .(0xbf519b75, 0x0a15, 0x4623, 0xad, 0xc9, 0xc0, 0x0d, 0x43, 0x6a, 0x80, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* CurrentColor) get_Color;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewColor) put_Color;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* CurrentWidth) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float NewWidth) put_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* CurrentHeight) get_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float NewHeight) put_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Flag) get_FitToCurve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Flag) put_FitToCurve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Flag) get_IgnorePressure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Flag) put_IgnorePressure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Flag) get_AntiAliased;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Flag) put_AntiAliased;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* CurrentTransparency) get_Transparency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewTransparency) put_Transparency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRasterOperation* CurrentRasterOperation) get_RasterOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRasterOperation NewRasterOperation) put_RasterOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkPenTip* CurrentPenTip) get_PenTip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkPenTip NewPenTip) put_PenTip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkExtendedProperties** Properties) get_ExtendedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** DrawingAttributes) Clone;
	}


	public HRESULT get_Color(int32* CurrentColor) mut => VT.[Friend]get_Color(&this, CurrentColor);

	public HRESULT put_Color(int32 NewColor) mut => VT.[Friend]put_Color(&this, NewColor);

	public HRESULT get_Width(float* CurrentWidth) mut => VT.[Friend]get_Width(&this, CurrentWidth);

	public HRESULT put_Width(float NewWidth) mut => VT.[Friend]put_Width(&this, NewWidth);

	public HRESULT get_Height(float* CurrentHeight) mut => VT.[Friend]get_Height(&this, CurrentHeight);

	public HRESULT put_Height(float NewHeight) mut => VT.[Friend]put_Height(&this, NewHeight);

	public HRESULT get_FitToCurve(int16* Flag) mut => VT.[Friend]get_FitToCurve(&this, Flag);

	public HRESULT put_FitToCurve(int16 Flag) mut => VT.[Friend]put_FitToCurve(&this, Flag);

	public HRESULT get_IgnorePressure(int16* Flag) mut => VT.[Friend]get_IgnorePressure(&this, Flag);

	public HRESULT put_IgnorePressure(int16 Flag) mut => VT.[Friend]put_IgnorePressure(&this, Flag);

	public HRESULT get_AntiAliased(int16* Flag) mut => VT.[Friend]get_AntiAliased(&this, Flag);

	public HRESULT put_AntiAliased(int16 Flag) mut => VT.[Friend]put_AntiAliased(&this, Flag);

	public HRESULT get_Transparency(int32* CurrentTransparency) mut => VT.[Friend]get_Transparency(&this, CurrentTransparency);

	public HRESULT put_Transparency(int32 NewTransparency) mut => VT.[Friend]put_Transparency(&this, NewTransparency);

	public HRESULT get_RasterOperation(InkRasterOperation* CurrentRasterOperation) mut => VT.[Friend]get_RasterOperation(&this, CurrentRasterOperation);

	public HRESULT put_RasterOperation(InkRasterOperation NewRasterOperation) mut => VT.[Friend]put_RasterOperation(&this, NewRasterOperation);

	public HRESULT get_PenTip(InkPenTip* CurrentPenTip) mut => VT.[Friend]get_PenTip(&this, CurrentPenTip);

	public HRESULT put_PenTip(InkPenTip NewPenTip) mut => VT.[Friend]put_PenTip(&this, NewPenTip);

	public HRESULT get_ExtendedProperties(IInkExtendedProperties** Properties) mut => VT.[Friend]get_ExtendedProperties(&this, Properties);

	public HRESULT Clone(IInkDrawingAttributes** DrawingAttributes) mut => VT.[Friend]Clone(&this, DrawingAttributes);
}

[CRepr]struct IInkTransform : IDispatch
{
	public new const Guid IID = .(0x615f1d43, 0x8703, 0x4565, 0x88, 0xe2, 0x82, 0x01, 0xd2, 0xec, 0xd7, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalComponent, float VerticalComponent) Translate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Degrees, float x, float y) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Horizontally, int16 Vertically) Reflect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalComponent, float VerticalComponent) Shear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalMultiplier, float VerticalMultiplier) ScaleTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* eM11, float* eM12, float* eM21, float* eM22, float* eDx, float* eDy) GetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float eM11, float eM12, float eM21, float eM22, float eDx, float eDy) SetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Value) get_eM11;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) put_eM11;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Value) get_eM12;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) put_eM12;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Value) get_eM21;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) put_eM21;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Value) get_eM22;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) put_eM22;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Value) get_eDx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) put_eDx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* Value) get_eDy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) put_eDy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XFORM* XForm) get_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XFORM XForm) put_Data;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Translate(float HorizontalComponent, float VerticalComponent) mut => VT.[Friend]Translate(&this, HorizontalComponent, VerticalComponent);

	public HRESULT Rotate(float Degrees, float x, float y) mut => VT.[Friend]Rotate(&this, Degrees, x, y);

	public HRESULT Reflect(int16 Horizontally, int16 Vertically) mut => VT.[Friend]Reflect(&this, Horizontally, Vertically);

	public HRESULT Shear(float HorizontalComponent, float VerticalComponent) mut => VT.[Friend]Shear(&this, HorizontalComponent, VerticalComponent);

	public HRESULT ScaleTransform(float HorizontalMultiplier, float VerticalMultiplier) mut => VT.[Friend]ScaleTransform(&this, HorizontalMultiplier, VerticalMultiplier);

	public HRESULT GetTransform(float* eM11, float* eM12, float* eM21, float* eM22, float* eDx, float* eDy) mut => VT.[Friend]GetTransform(&this, eM11, eM12, eM21, eM22, eDx, eDy);

	public HRESULT SetTransform(float eM11, float eM12, float eM21, float eM22, float eDx, float eDy) mut => VT.[Friend]SetTransform(&this, eM11, eM12, eM21, eM22, eDx, eDy);

	public HRESULT get_eM11(float* Value) mut => VT.[Friend]get_eM11(&this, Value);

	public HRESULT put_eM11(float Value) mut => VT.[Friend]put_eM11(&this, Value);

	public HRESULT get_eM12(float* Value) mut => VT.[Friend]get_eM12(&this, Value);

	public HRESULT put_eM12(float Value) mut => VT.[Friend]put_eM12(&this, Value);

	public HRESULT get_eM21(float* Value) mut => VT.[Friend]get_eM21(&this, Value);

	public HRESULT put_eM21(float Value) mut => VT.[Friend]put_eM21(&this, Value);

	public HRESULT get_eM22(float* Value) mut => VT.[Friend]get_eM22(&this, Value);

	public HRESULT put_eM22(float Value) mut => VT.[Friend]put_eM22(&this, Value);

	public HRESULT get_eDx(float* Value) mut => VT.[Friend]get_eDx(&this, Value);

	public HRESULT put_eDx(float Value) mut => VT.[Friend]put_eDx(&this, Value);

	public HRESULT get_eDy(float* Value) mut => VT.[Friend]get_eDy(&this, Value);

	public HRESULT put_eDy(float Value) mut => VT.[Friend]put_eDy(&this, Value);

	public HRESULT get_Data(XFORM* XForm) mut => VT.[Friend]get_Data(&this, XForm);

	public HRESULT put_Data(XFORM XForm) mut => VT.[Friend]put_Data(&this, XForm);
}

[CRepr]struct IInkGesture : IDispatch
{
	public new const Guid IID = .(0x3bdc0a97, 0x04e5, 0x4e26, 0xb8, 0x13, 0x18, 0xf0, 0x52, 0xd4, 0x1d, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognitionConfidence* Confidence) get_Confidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* X, int32* Y) GetHotPoint;
	}


	public HRESULT get_Confidence(InkRecognitionConfidence* Confidence) mut => VT.[Friend]get_Confidence(&this, Confidence);

	public HRESULT get_Id(InkApplicationGesture* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT GetHotPoint(int32* X, int32* Y) mut => VT.[Friend]GetHotPoint(&this, X, Y);
}

[CRepr]struct IInkCursor : IDispatch
{
	public new const Guid IID = .(0xad30c630, 0x40c5, 0x4350, 0x84, 0x05, 0x9c, 0x71, 0x01, 0x2f, 0xc5, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Status) get_Inverted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** Attributes) get_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* Attributes) putref_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet** Tablet) get_Tablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCursorButtons** Buttons) get_Buttons;
	}


	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Id(int32* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT get_Inverted(int16* Status) mut => VT.[Friend]get_Inverted(&this, Status);

	public HRESULT get_DrawingAttributes(IInkDrawingAttributes** Attributes) mut => VT.[Friend]get_DrawingAttributes(&this, Attributes);

	public HRESULT putref_DrawingAttributes(IInkDrawingAttributes* Attributes) mut => VT.[Friend]putref_DrawingAttributes(&this, Attributes);

	public HRESULT get_Tablet(IInkTablet** Tablet) mut => VT.[Friend]get_Tablet(&this, Tablet);

	public HRESULT get_Buttons(IInkCursorButtons** Buttons) mut => VT.[Friend]get_Buttons(&this, Buttons);
}

[CRepr]struct IInkCursors : IDispatch
{
	public new const Guid IID = .(0xa248c1ac, 0xc698, 0x4e06, 0x9e, 0x5c, 0xd5, 0x7f, 0x77, 0xc7, 0xe6, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IInkCursor** Cursor) Item;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT Item(int32 Index, IInkCursor** Cursor) mut => VT.[Friend]Item(&this, Index, Cursor);
}

[CRepr]struct IInkCursorButton : IDispatch
{
	public new const Guid IID = .(0x85ef9417, 0x1d59, 0x49b2, 0xa1, 0x3c, 0x70, 0x2c, 0x85, 0x43, 0x08, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCursorButtonState* CurrentState) get_State;
	}


	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Id(BSTR* Id) mut => VT.[Friend]get_Id(&this, Id);

	public HRESULT get_State(InkCursorButtonState* CurrentState) mut => VT.[Friend]get_State(&this, CurrentState);
}

[CRepr]struct IInkCursorButtons : IDispatch
{
	public new const Guid IID = .(0x3671cc40, 0xb624, 0x4671, 0x9f, 0xa0, 0xdb, 0x11, 0x9d, 0x95, 0x2d, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Identifier, IInkCursorButton** Button) Item;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT Item(VARIANT Identifier, IInkCursorButton** Button) mut => VT.[Friend]Item(&this, Identifier, Button);
}

[CRepr]struct IInkTablet : IDispatch
{
	public new const Guid IID = .(0x2de25eaa, 0x6ef8, 0x42d5, 0xae, 0xe9, 0x18, 0x5b, 0xc8, 0x1b, 0x91, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Id) get_PlugAndPlayId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle** Rectangle) get_MaximumInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TabletHardwareCapabilities* Capabilities) get_HardwareCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR packetPropertyName, int16* Supported) IsPacketPropertySupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR propertyName, int32* Minimum, int32* Maximum, TabletPropertyMetricUnit* Units, float* Resolution) GetPropertyMetrics;
	}


	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_PlugAndPlayId(BSTR* Id) mut => VT.[Friend]get_PlugAndPlayId(&this, Id);

	public HRESULT get_MaximumInputRectangle(IInkRectangle** Rectangle) mut => VT.[Friend]get_MaximumInputRectangle(&this, Rectangle);

	public HRESULT get_HardwareCapabilities(TabletHardwareCapabilities* Capabilities) mut => VT.[Friend]get_HardwareCapabilities(&this, Capabilities);

	public HRESULT IsPacketPropertySupported(BSTR packetPropertyName, int16* Supported) mut => VT.[Friend]IsPacketPropertySupported(&this, packetPropertyName, Supported);

	public HRESULT GetPropertyMetrics(BSTR propertyName, int32* Minimum, int32* Maximum, TabletPropertyMetricUnit* Units, float* Resolution) mut => VT.[Friend]GetPropertyMetrics(&this, propertyName, Minimum, Maximum, Units, Resolution);
}

[CRepr]struct IInkTablet2 : IDispatch
{
	public new const Guid IID = .(0x90c91ad2, 0xfa36, 0x49d6, 0x95, 0x16, 0xce, 0x8d, 0x57, 0x0f, 0x6f, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TabletDeviceKind* Kind) get_DeviceKind;
	}


	public HRESULT get_DeviceKind(TabletDeviceKind* Kind) mut => VT.[Friend]get_DeviceKind(&this, Kind);
}

[CRepr]struct IInkTablet3 : IDispatch
{
	public new const Guid IID = .(0x7e313997, 0x1327, 0x41dd, 0x8c, 0xa9, 0x79, 0xf2, 0x4b, 0xe1, 0x72, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pIsMultiTouch) get_IsMultiTouch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMaximumCursors) get_MaximumCursors;
	}


	public HRESULT get_IsMultiTouch(int16* pIsMultiTouch) mut => VT.[Friend]get_IsMultiTouch(&this, pIsMultiTouch);

	public HRESULT get_MaximumCursors(uint32* pMaximumCursors) mut => VT.[Friend]get_MaximumCursors(&this, pMaximumCursors);
}

[CRepr]struct IInkTablets : IDispatch
{
	public new const Guid IID = .(0x112086d9, 0x7779, 0x4535, 0xa6, 0x99, 0x86, 0x2b, 0x43, 0xac, 0x18, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet** DefaultTablet) get_DefaultTablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IInkTablet** Tablet) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR packetPropertyName, int16* Supported) IsPacketPropertySupported;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT get_DefaultTablet(IInkTablet** DefaultTablet) mut => VT.[Friend]get_DefaultTablet(&this, DefaultTablet);

	public HRESULT Item(int32 Index, IInkTablet** Tablet) mut => VT.[Friend]Item(&this, Index, Tablet);

	public HRESULT IsPacketPropertySupported(BSTR packetPropertyName, int16* Supported) mut => VT.[Friend]IsPacketPropertySupported(&this, packetPropertyName, Supported);
}

[CRepr]struct IInkStrokeDisp : IDispatch
{
	public new const Guid IID = .(0x43242fea, 0x91d1, 0x4a72, 0x96, 0x3e, 0xfb, 0xb9, 0x18, 0x29, 0xcf, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* ID) get_ID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Points) get_BezierPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** DrawAttrs) get_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* DrawAttrs) putref_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** Ink) get_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkExtendedProperties** Properties) get_ExtendedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cusps) get_PolylineCusps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cusps) get_BezierCusps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Intersections) get_SelfIntersections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_PacketCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_PacketSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PacketDescription) get_PacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Deleted) get_Deleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkBoundingBoxMode BoundingBoxMode, IInkRectangle** Rectangle) GetBoundingBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes, VARIANT* Intersections) FindIntersections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle, VARIANT* Intersections) GetRectangleIntersections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) Clip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 X, int32 Y, float Radius, int16* Intersects) HitTestCircle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 X, int32 Y, float* Distance, float* Point) NearestPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float SplitAt, IInkStrokeDisp** NewStroke) Split;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyName, int32* Minimum, int32* Maximum, TabletPropertyMetricUnit* Units, float* Resolution) GetPacketDescriptionPropertyMetrics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32 Count, VARIANT* Points) GetPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Points, int32 Index, int32 Count, int32* NumberOfPointsSet) SetPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32 Count, VARIANT* PacketData) GetPacketData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyName, int32 Index, int32 Count, VARIANT* PacketValues) GetPacketValuesByProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT PacketValues, int32 Index, int32 Count, int32* NumberOfPacketsSet) SetPacketValuesByProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 FittingError, VARIANT* FlattenedBezierPoints) GetFlattenedBezierPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform* Transform, int16 ApplyOnPenWidth) Transform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) ScaleToRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalComponent, float VerticalComponent) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Degrees, float x, float y) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalMultiplier, float VerticalMultiplier) Shear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalMultiplier, float VerticalMultiplier) ScaleTransform;
	}


	public HRESULT get_ID(int32* ID) mut => VT.[Friend]get_ID(&this, ID);

	public HRESULT get_BezierPoints(VARIANT* Points) mut => VT.[Friend]get_BezierPoints(&this, Points);

	public HRESULT get_DrawingAttributes(IInkDrawingAttributes** DrawAttrs) mut => VT.[Friend]get_DrawingAttributes(&this, DrawAttrs);

	public HRESULT putref_DrawingAttributes(IInkDrawingAttributes* DrawAttrs) mut => VT.[Friend]putref_DrawingAttributes(&this, DrawAttrs);

	public HRESULT get_Ink(IInkDisp** Ink) mut => VT.[Friend]get_Ink(&this, Ink);

	public HRESULT get_ExtendedProperties(IInkExtendedProperties** Properties) mut => VT.[Friend]get_ExtendedProperties(&this, Properties);

	public HRESULT get_PolylineCusps(VARIANT* Cusps) mut => VT.[Friend]get_PolylineCusps(&this, Cusps);

	public HRESULT get_BezierCusps(VARIANT* Cusps) mut => VT.[Friend]get_BezierCusps(&this, Cusps);

	public HRESULT get_SelfIntersections(VARIANT* Intersections) mut => VT.[Friend]get_SelfIntersections(&this, Intersections);

	public HRESULT get_PacketCount(int32* plCount) mut => VT.[Friend]get_PacketCount(&this, plCount);

	public HRESULT get_PacketSize(int32* plSize) mut => VT.[Friend]get_PacketSize(&this, plSize);

	public HRESULT get_PacketDescription(VARIANT* PacketDescription) mut => VT.[Friend]get_PacketDescription(&this, PacketDescription);

	public HRESULT get_Deleted(int16* Deleted) mut => VT.[Friend]get_Deleted(&this, Deleted);

	public HRESULT GetBoundingBox(InkBoundingBoxMode BoundingBoxMode, IInkRectangle** Rectangle) mut => VT.[Friend]GetBoundingBox(&this, BoundingBoxMode, Rectangle);

	public HRESULT FindIntersections(IInkStrokes* Strokes, VARIANT* Intersections) mut => VT.[Friend]FindIntersections(&this, Strokes, Intersections);

	public HRESULT GetRectangleIntersections(IInkRectangle* Rectangle, VARIANT* Intersections) mut => VT.[Friend]GetRectangleIntersections(&this, Rectangle, Intersections);

	public HRESULT Clip(IInkRectangle* Rectangle) mut => VT.[Friend]Clip(&this, Rectangle);

	public HRESULT HitTestCircle(int32 X, int32 Y, float Radius, int16* Intersects) mut => VT.[Friend]HitTestCircle(&this, X, Y, Radius, Intersects);

	public HRESULT NearestPoint(int32 X, int32 Y, float* Distance, float* Point) mut => VT.[Friend]NearestPoint(&this, X, Y, Distance, Point);

	public HRESULT Split(float SplitAt, IInkStrokeDisp** NewStroke) mut => VT.[Friend]Split(&this, SplitAt, NewStroke);

	public HRESULT GetPacketDescriptionPropertyMetrics(BSTR PropertyName, int32* Minimum, int32* Maximum, TabletPropertyMetricUnit* Units, float* Resolution) mut => VT.[Friend]GetPacketDescriptionPropertyMetrics(&this, PropertyName, Minimum, Maximum, Units, Resolution);

	public HRESULT GetPoints(int32 Index, int32 Count, VARIANT* Points) mut => VT.[Friend]GetPoints(&this, Index, Count, Points);

	public HRESULT SetPoints(VARIANT Points, int32 Index, int32 Count, int32* NumberOfPointsSet) mut => VT.[Friend]SetPoints(&this, Points, Index, Count, NumberOfPointsSet);

	public HRESULT GetPacketData(int32 Index, int32 Count, VARIANT* PacketData) mut => VT.[Friend]GetPacketData(&this, Index, Count, PacketData);

	public HRESULT GetPacketValuesByProperty(BSTR PropertyName, int32 Index, int32 Count, VARIANT* PacketValues) mut => VT.[Friend]GetPacketValuesByProperty(&this, PropertyName, Index, Count, PacketValues);

	public HRESULT SetPacketValuesByProperty(BSTR bstrPropertyName, VARIANT PacketValues, int32 Index, int32 Count, int32* NumberOfPacketsSet) mut => VT.[Friend]SetPacketValuesByProperty(&this, bstrPropertyName, PacketValues, Index, Count, NumberOfPacketsSet);

	public HRESULT GetFlattenedBezierPoints(int32 FittingError, VARIANT* FlattenedBezierPoints) mut => VT.[Friend]GetFlattenedBezierPoints(&this, FittingError, FlattenedBezierPoints);

	public HRESULT Transform(IInkTransform* Transform, int16 ApplyOnPenWidth) mut => VT.[Friend]Transform(&this, Transform, ApplyOnPenWidth);

	public HRESULT ScaleToRectangle(IInkRectangle* Rectangle) mut => VT.[Friend]ScaleToRectangle(&this, Rectangle);

	public HRESULT Move(float HorizontalComponent, float VerticalComponent) mut => VT.[Friend]Move(&this, HorizontalComponent, VerticalComponent);

	public HRESULT Rotate(float Degrees, float x, float y) mut => VT.[Friend]Rotate(&this, Degrees, x, y);

	public HRESULT Shear(float HorizontalMultiplier, float VerticalMultiplier) mut => VT.[Friend]Shear(&this, HorizontalMultiplier, VerticalMultiplier);

	public HRESULT ScaleTransform(float HorizontalMultiplier, float VerticalMultiplier) mut => VT.[Friend]ScaleTransform(&this, HorizontalMultiplier, VerticalMultiplier);
}

[CRepr]struct IInkStrokes : IDispatch
{
	public new const Guid IID = .(0xf1f4c9d8, 0x590a, 0x4963, 0xb3, 0xae, 0x19, 0x35, 0x67, 0x1b, 0xb6, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** Ink) get_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognitionResult** RecognitionResult) get_RecognitionResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ToString) COM_ToString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IInkStrokeDisp** Stroke) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokeDisp* InkStroke) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* InkStrokes) AddStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokeDisp* InkStroke) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* InkStrokes) RemoveStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* DrawAttrs) ModifyDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkBoundingBoxMode BoundingBoxMode, IInkRectangle** BoundingBox) GetBoundingBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform* Transform, int16 ApplyOnPenWidth) Transform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) ScaleToRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalComponent, float VerticalComponent) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Degrees, float x, float y) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalMultiplier, float VerticalMultiplier) Shear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalMultiplier, float VerticalMultiplier) ScaleTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) Clip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveRecognitionResult;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT get_Ink(IInkDisp** Ink) mut => VT.[Friend]get_Ink(&this, Ink);

	public HRESULT get_RecognitionResult(IInkRecognitionResult** RecognitionResult) mut => VT.[Friend]get_RecognitionResult(&this, RecognitionResult);

	public HRESULT ToString(BSTR* ToString) mut => VT.[Friend]COM_ToString(&this, ToString);

	public HRESULT Item(int32 Index, IInkStrokeDisp** Stroke) mut => VT.[Friend]Item(&this, Index, Stroke);

	public HRESULT Add(IInkStrokeDisp* InkStroke) mut => VT.[Friend]Add(&this, InkStroke);

	public HRESULT AddStrokes(IInkStrokes* InkStrokes) mut => VT.[Friend]AddStrokes(&this, InkStrokes);

	public HRESULT Remove(IInkStrokeDisp* InkStroke) mut => VT.[Friend]Remove(&this, InkStroke);

	public HRESULT RemoveStrokes(IInkStrokes* InkStrokes) mut => VT.[Friend]RemoveStrokes(&this, InkStrokes);

	public HRESULT ModifyDrawingAttributes(IInkDrawingAttributes* DrawAttrs) mut => VT.[Friend]ModifyDrawingAttributes(&this, DrawAttrs);

	public HRESULT GetBoundingBox(InkBoundingBoxMode BoundingBoxMode, IInkRectangle** BoundingBox) mut => VT.[Friend]GetBoundingBox(&this, BoundingBoxMode, BoundingBox);

	public HRESULT Transform(IInkTransform* Transform, int16 ApplyOnPenWidth) mut => VT.[Friend]Transform(&this, Transform, ApplyOnPenWidth);

	public HRESULT ScaleToRectangle(IInkRectangle* Rectangle) mut => VT.[Friend]ScaleToRectangle(&this, Rectangle);

	public HRESULT Move(float HorizontalComponent, float VerticalComponent) mut => VT.[Friend]Move(&this, HorizontalComponent, VerticalComponent);

	public HRESULT Rotate(float Degrees, float x, float y) mut => VT.[Friend]Rotate(&this, Degrees, x, y);

	public HRESULT Shear(float HorizontalMultiplier, float VerticalMultiplier) mut => VT.[Friend]Shear(&this, HorizontalMultiplier, VerticalMultiplier);

	public HRESULT ScaleTransform(float HorizontalMultiplier, float VerticalMultiplier) mut => VT.[Friend]ScaleTransform(&this, HorizontalMultiplier, VerticalMultiplier);

	public HRESULT Clip(IInkRectangle* Rectangle) mut => VT.[Friend]Clip(&this, Rectangle);

	public HRESULT RemoveRecognitionResult() mut => VT.[Friend]RemoveRecognitionResult(&this);
}

[CRepr]struct IInkCustomStrokes : IDispatch
{
	public new const Guid IID = .(0x7e23a88f, 0xc30e, 0x420f, 0x9b, 0xdb, 0x28, 0x90, 0x25, 0x43, 0xf0, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Identifier, IInkStrokes** Strokes) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, IInkStrokes* Strokes) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Identifier) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT Item(VARIANT Identifier, IInkStrokes** Strokes) mut => VT.[Friend]Item(&this, Identifier, Strokes);

	public HRESULT Add(BSTR Name, IInkStrokes* Strokes) mut => VT.[Friend]Add(&this, Name, Strokes);

	public HRESULT Remove(VARIANT Identifier) mut => VT.[Friend]Remove(&this, Identifier);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct _IInkStrokesEvents : IDispatch
{
	public new const Guid IID = .(0xf33053ec, 0x5d25, 0x430a, 0x92, 0x8f, 0x76, 0xa6, 0x49, 0x1d, 0xde, 0x15);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkDisp : IDispatch
{
	public new const Guid IID = .(0x9d398fa0, 0xc4e2, 0x4fcd, 0x99, 0x73, 0x97, 0x5c, 0xaa, 0xf4, 0x7e, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkExtendedProperties** Properties) get_ExtendedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Dirty) get_Dirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Dirty) put_Dirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCustomStrokes** ppunkInkCustomStrokes) get_CustomStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkBoundingBoxMode BoundingBoxMode, IInkRectangle** Rectangle) GetBoundingBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes) DeleteStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokeDisp* Stroke) DeleteStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes, InkExtractFlags ExtractFlags, IInkDisp** ExtractedInk) ExtractStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle, InkExtractFlags extractFlags, IInkDisp** ExtractedInk) ExtractWithRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) Clip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** NewInk) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 X, int32 Y, float radius, IInkStrokes** Strokes) HitTestCircle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* SelectionRectangle, float IntersectPercent, IInkStrokes** Strokes) HitTestWithRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Points, float IntersectPercent, VARIANT* LassoPoints, IInkStrokes** Strokes) HitTestWithLasso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 X, int32 Y, float* PointOnStroke, float* DistanceFromPacket, IInkStrokeDisp** Stroke) NearestPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT StrokeIds, IInkStrokes** Strokes) CreateStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* SourceStrokes, IInkRectangle* TargetRectangle) AddStrokesAtRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkPersistenceFormat PersistenceFormat, InkPersistenceCompressionMode CompressionMode, VARIANT* Data) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Data) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT PacketData, VARIANT PacketDescription, IInkStrokeDisp** Stroke) CreateStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle, InkClipboardFormats ClipboardFormats, InkClipboardModes ClipboardModes, IDataObject** DataObject) ClipboardCopyWithRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* strokes, InkClipboardFormats ClipboardFormats, InkClipboardModes ClipboardModes, IDataObject** DataObject) ClipboardCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* DataObject, int16* CanPaste) CanPaste;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, IDataObject* DataObject, IInkStrokes** Strokes) ClipboardPaste;
	}


	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT get_ExtendedProperties(IInkExtendedProperties** Properties) mut => VT.[Friend]get_ExtendedProperties(&this, Properties);

	public HRESULT get_Dirty(int16* Dirty) mut => VT.[Friend]get_Dirty(&this, Dirty);

	public HRESULT put_Dirty(int16 Dirty) mut => VT.[Friend]put_Dirty(&this, Dirty);

	public HRESULT get_CustomStrokes(IInkCustomStrokes** ppunkInkCustomStrokes) mut => VT.[Friend]get_CustomStrokes(&this, ppunkInkCustomStrokes);

	public HRESULT GetBoundingBox(InkBoundingBoxMode BoundingBoxMode, IInkRectangle** Rectangle) mut => VT.[Friend]GetBoundingBox(&this, BoundingBoxMode, Rectangle);

	public HRESULT DeleteStrokes(IInkStrokes* Strokes) mut => VT.[Friend]DeleteStrokes(&this, Strokes);

	public HRESULT DeleteStroke(IInkStrokeDisp* Stroke) mut => VT.[Friend]DeleteStroke(&this, Stroke);

	public HRESULT ExtractStrokes(IInkStrokes* Strokes, InkExtractFlags ExtractFlags, IInkDisp** ExtractedInk) mut => VT.[Friend]ExtractStrokes(&this, Strokes, ExtractFlags, ExtractedInk);

	public HRESULT ExtractWithRectangle(IInkRectangle* Rectangle, InkExtractFlags extractFlags, IInkDisp** ExtractedInk) mut => VT.[Friend]ExtractWithRectangle(&this, Rectangle, extractFlags, ExtractedInk);

	public HRESULT Clip(IInkRectangle* Rectangle) mut => VT.[Friend]Clip(&this, Rectangle);

	public HRESULT Clone(IInkDisp** NewInk) mut => VT.[Friend]Clone(&this, NewInk);

	public HRESULT HitTestCircle(int32 X, int32 Y, float radius, IInkStrokes** Strokes) mut => VT.[Friend]HitTestCircle(&this, X, Y, radius, Strokes);

	public HRESULT HitTestWithRectangle(IInkRectangle* SelectionRectangle, float IntersectPercent, IInkStrokes** Strokes) mut => VT.[Friend]HitTestWithRectangle(&this, SelectionRectangle, IntersectPercent, Strokes);

	public HRESULT HitTestWithLasso(VARIANT Points, float IntersectPercent, VARIANT* LassoPoints, IInkStrokes** Strokes) mut => VT.[Friend]HitTestWithLasso(&this, Points, IntersectPercent, LassoPoints, Strokes);

	public HRESULT NearestPoint(int32 X, int32 Y, float* PointOnStroke, float* DistanceFromPacket, IInkStrokeDisp** Stroke) mut => VT.[Friend]NearestPoint(&this, X, Y, PointOnStroke, DistanceFromPacket, Stroke);

	public HRESULT CreateStrokes(VARIANT StrokeIds, IInkStrokes** Strokes) mut => VT.[Friend]CreateStrokes(&this, StrokeIds, Strokes);

	public HRESULT AddStrokesAtRectangle(IInkStrokes* SourceStrokes, IInkRectangle* TargetRectangle) mut => VT.[Friend]AddStrokesAtRectangle(&this, SourceStrokes, TargetRectangle);

	public HRESULT Save(InkPersistenceFormat PersistenceFormat, InkPersistenceCompressionMode CompressionMode, VARIANT* Data) mut => VT.[Friend]Save(&this, PersistenceFormat, CompressionMode, Data);

	public HRESULT Load(VARIANT Data) mut => VT.[Friend]Load(&this, Data);

	public HRESULT CreateStroke(VARIANT PacketData, VARIANT PacketDescription, IInkStrokeDisp** Stroke) mut => VT.[Friend]CreateStroke(&this, PacketData, PacketDescription, Stroke);

	public HRESULT ClipboardCopyWithRectangle(IInkRectangle* Rectangle, InkClipboardFormats ClipboardFormats, InkClipboardModes ClipboardModes, IDataObject** DataObject) mut => VT.[Friend]ClipboardCopyWithRectangle(&this, Rectangle, ClipboardFormats, ClipboardModes, DataObject);

	public HRESULT ClipboardCopy(IInkStrokes* strokes, InkClipboardFormats ClipboardFormats, InkClipboardModes ClipboardModes, IDataObject** DataObject) mut => VT.[Friend]ClipboardCopy(&this, strokes, ClipboardFormats, ClipboardModes, DataObject);

	public HRESULT CanPaste(IDataObject* DataObject, int16* CanPaste) mut => VT.[Friend]CanPaste(&this, DataObject, CanPaste);

	public HRESULT ClipboardPaste(int32 x, int32 y, IDataObject* DataObject, IInkStrokes** Strokes) mut => VT.[Friend]ClipboardPaste(&this, x, y, DataObject, Strokes);
}

[CRepr]struct _IInkEvents : IDispatch
{
	public new const Guid IID = .(0x427b1865, 0xca3f, 0x479a, 0x83, 0xa9, 0x0f, 0x42, 0x0f, 0x2a, 0x00, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkRenderer : IDispatch
{
	public new const Guid IID = .(0xe6257a9c, 0xb511, 0x4f4c, 0xa8, 0xb0, 0xa7, 0xdb, 0xc9, 0x50, 0x6b, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform* ViewTransform) GetViewTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform* ViewTransform) SetViewTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform* ObjectTransform) GetObjectTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform* ObjectTransform) SetObjectTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hDC, IInkStrokes* Strokes) Draw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hDC, IInkStrokeDisp* Stroke, IInkDrawingAttributes* DrawingAttributes) DrawStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hDC, int32* x, int32* y) PixelToInkSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hdcDisplay, int32* x, int32* y) InkSpaceToPixel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hDC, VARIANT* Points) PixelToInkSpaceFromPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hDC, VARIANT* Points) InkSpaceToPixelFromPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes, IInkRectangle** Rectangle) Measure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokeDisp* Stroke, IInkDrawingAttributes* DrawingAttributes, IInkRectangle** Rectangle) MeasureStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalComponent, float VerticalComponent) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Degrees, float x, float y) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float HorizontalMultiplier, float VerticalMultiplier, int16 ApplyOnPenWidth) ScaleTransform;
	}


	public HRESULT GetViewTransform(IInkTransform* ViewTransform) mut => VT.[Friend]GetViewTransform(&this, ViewTransform);

	public HRESULT SetViewTransform(IInkTransform* ViewTransform) mut => VT.[Friend]SetViewTransform(&this, ViewTransform);

	public HRESULT GetObjectTransform(IInkTransform* ObjectTransform) mut => VT.[Friend]GetObjectTransform(&this, ObjectTransform);

	public HRESULT SetObjectTransform(IInkTransform* ObjectTransform) mut => VT.[Friend]SetObjectTransform(&this, ObjectTransform);

	public HRESULT Draw(int hDC, IInkStrokes* Strokes) mut => VT.[Friend]Draw(&this, hDC, Strokes);

	public HRESULT DrawStroke(int hDC, IInkStrokeDisp* Stroke, IInkDrawingAttributes* DrawingAttributes) mut => VT.[Friend]DrawStroke(&this, hDC, Stroke, DrawingAttributes);

	public HRESULT PixelToInkSpace(int hDC, int32* x, int32* y) mut => VT.[Friend]PixelToInkSpace(&this, hDC, x, y);

	public HRESULT InkSpaceToPixel(int hdcDisplay, int32* x, int32* y) mut => VT.[Friend]InkSpaceToPixel(&this, hdcDisplay, x, y);

	public HRESULT PixelToInkSpaceFromPoints(int hDC, VARIANT* Points) mut => VT.[Friend]PixelToInkSpaceFromPoints(&this, hDC, Points);

	public HRESULT InkSpaceToPixelFromPoints(int hDC, VARIANT* Points) mut => VT.[Friend]InkSpaceToPixelFromPoints(&this, hDC, Points);

	public HRESULT Measure(IInkStrokes* Strokes, IInkRectangle** Rectangle) mut => VT.[Friend]Measure(&this, Strokes, Rectangle);

	public HRESULT MeasureStroke(IInkStrokeDisp* Stroke, IInkDrawingAttributes* DrawingAttributes, IInkRectangle** Rectangle) mut => VT.[Friend]MeasureStroke(&this, Stroke, DrawingAttributes, Rectangle);

	public HRESULT Move(float HorizontalComponent, float VerticalComponent) mut => VT.[Friend]Move(&this, HorizontalComponent, VerticalComponent);

	public HRESULT Rotate(float Degrees, float x, float y) mut => VT.[Friend]Rotate(&this, Degrees, x, y);

	public HRESULT ScaleTransform(float HorizontalMultiplier, float VerticalMultiplier, int16 ApplyOnPenWidth) mut => VT.[Friend]ScaleTransform(&this, HorizontalMultiplier, VerticalMultiplier, ApplyOnPenWidth);
}

[CRepr]struct IInkCollector : IDispatch
{
	public new const Guid IID = .(0xf0f060b5, 0x8b1f, 0x4a7c, 0x89, 0xec, 0x88, 0x06, 0x92, 0x58, 0x8a, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* CurrentWindow) get_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int NewWindow) put_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Collecting) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Collecting) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** CurrentAttributes) get_DefaultDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* NewAttributes) putref_DefaultDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRenderer** CurrentInkRenderer) get_Renderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRenderer* NewInkRenderer) putref_Renderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** Ink) get_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp* NewInk) putref_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* AutoRedraw) get_AutoRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 AutoRedraw) put_AutoRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Collecting) get_CollectingInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectionMode* Mode) get_CollectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectionMode Mode) put_CollectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Enabled) get_DynamicRendering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Enabled) put_DynamicRendering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PacketGuids) get_DesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT PacketGuids) put_DesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp** MouseIcon) get_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) put_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) putref_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer* MousePointer) get_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer MousePointer) put_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCursors** Cursors) get_Cursors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MarginX) get_MarginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarginX) put_MarginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MarginY) get_MarginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarginY) put_MarginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet** SingleTablet) get_Tablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Support) get_SupportHighContrastInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Support) put_SupportHighContrastInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16 Listen) SetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16* Listening) GetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle** WindowInputRectangle) GetWindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* WindowInputRectangle) SetWindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 UseMouseForInput) SetAllTabletsMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet* Tablet) SetSingleTabletIntegratedMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectorEventInterest EventId, int16* Listen) GetEventInterest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectorEventInterest EventId, int16 Listen) SetEventInterest;
	}


	public HRESULT get_hWnd(int* CurrentWindow) mut => VT.[Friend]get_hWnd(&this, CurrentWindow);

	public HRESULT put_hWnd(int NewWindow) mut => VT.[Friend]put_hWnd(&this, NewWindow);

	public HRESULT get_Enabled(int16* Collecting) mut => VT.[Friend]get_Enabled(&this, Collecting);

	public HRESULT put_Enabled(int16 Collecting) mut => VT.[Friend]put_Enabled(&this, Collecting);

	public HRESULT get_DefaultDrawingAttributes(IInkDrawingAttributes** CurrentAttributes) mut => VT.[Friend]get_DefaultDrawingAttributes(&this, CurrentAttributes);

	public HRESULT putref_DefaultDrawingAttributes(IInkDrawingAttributes* NewAttributes) mut => VT.[Friend]putref_DefaultDrawingAttributes(&this, NewAttributes);

	public HRESULT get_Renderer(IInkRenderer** CurrentInkRenderer) mut => VT.[Friend]get_Renderer(&this, CurrentInkRenderer);

	public HRESULT putref_Renderer(IInkRenderer* NewInkRenderer) mut => VT.[Friend]putref_Renderer(&this, NewInkRenderer);

	public HRESULT get_Ink(IInkDisp** Ink) mut => VT.[Friend]get_Ink(&this, Ink);

	public HRESULT putref_Ink(IInkDisp* NewInk) mut => VT.[Friend]putref_Ink(&this, NewInk);

	public HRESULT get_AutoRedraw(int16* AutoRedraw) mut => VT.[Friend]get_AutoRedraw(&this, AutoRedraw);

	public HRESULT put_AutoRedraw(int16 AutoRedraw) mut => VT.[Friend]put_AutoRedraw(&this, AutoRedraw);

	public HRESULT get_CollectingInk(int16* Collecting) mut => VT.[Friend]get_CollectingInk(&this, Collecting);

	public HRESULT get_CollectionMode(InkCollectionMode* Mode) mut => VT.[Friend]get_CollectionMode(&this, Mode);

	public HRESULT put_CollectionMode(InkCollectionMode Mode) mut => VT.[Friend]put_CollectionMode(&this, Mode);

	public HRESULT get_DynamicRendering(int16* Enabled) mut => VT.[Friend]get_DynamicRendering(&this, Enabled);

	public HRESULT put_DynamicRendering(int16 Enabled) mut => VT.[Friend]put_DynamicRendering(&this, Enabled);

	public HRESULT get_DesiredPacketDescription(VARIANT* PacketGuids) mut => VT.[Friend]get_DesiredPacketDescription(&this, PacketGuids);

	public HRESULT put_DesiredPacketDescription(VARIANT PacketGuids) mut => VT.[Friend]put_DesiredPacketDescription(&this, PacketGuids);

	public HRESULT get_MouseIcon(IPictureDisp** MouseIcon) mut => VT.[Friend]get_MouseIcon(&this, MouseIcon);

	public HRESULT put_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]put_MouseIcon(&this, MouseIcon);

	public HRESULT putref_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]putref_MouseIcon(&this, MouseIcon);

	public HRESULT get_MousePointer(InkMousePointer* MousePointer) mut => VT.[Friend]get_MousePointer(&this, MousePointer);

	public HRESULT put_MousePointer(InkMousePointer MousePointer) mut => VT.[Friend]put_MousePointer(&this, MousePointer);

	public HRESULT get_Cursors(IInkCursors** Cursors) mut => VT.[Friend]get_Cursors(&this, Cursors);

	public HRESULT get_MarginX(int32* MarginX) mut => VT.[Friend]get_MarginX(&this, MarginX);

	public HRESULT put_MarginX(int32 MarginX) mut => VT.[Friend]put_MarginX(&this, MarginX);

	public HRESULT get_MarginY(int32* MarginY) mut => VT.[Friend]get_MarginY(&this, MarginY);

	public HRESULT put_MarginY(int32 MarginY) mut => VT.[Friend]put_MarginY(&this, MarginY);

	public HRESULT get_Tablet(IInkTablet** SingleTablet) mut => VT.[Friend]get_Tablet(&this, SingleTablet);

	public HRESULT get_SupportHighContrastInk(int16* Support) mut => VT.[Friend]get_SupportHighContrastInk(&this, Support);

	public HRESULT put_SupportHighContrastInk(int16 Support) mut => VT.[Friend]put_SupportHighContrastInk(&this, Support);

	public HRESULT SetGestureStatus(InkApplicationGesture Gesture, int16 Listen) mut => VT.[Friend]SetGestureStatus(&this, Gesture, Listen);

	public HRESULT GetGestureStatus(InkApplicationGesture Gesture, int16* Listening) mut => VT.[Friend]GetGestureStatus(&this, Gesture, Listening);

	public HRESULT GetWindowInputRectangle(IInkRectangle** WindowInputRectangle) mut => VT.[Friend]GetWindowInputRectangle(&this, WindowInputRectangle);

	public HRESULT SetWindowInputRectangle(IInkRectangle* WindowInputRectangle) mut => VT.[Friend]SetWindowInputRectangle(&this, WindowInputRectangle);

	public HRESULT SetAllTabletsMode(int16 UseMouseForInput) mut => VT.[Friend]SetAllTabletsMode(&this, UseMouseForInput);

	public HRESULT SetSingleTabletIntegratedMode(IInkTablet* Tablet) mut => VT.[Friend]SetSingleTabletIntegratedMode(&this, Tablet);

	public HRESULT GetEventInterest(InkCollectorEventInterest EventId, int16* Listen) mut => VT.[Friend]GetEventInterest(&this, EventId, Listen);

	public HRESULT SetEventInterest(InkCollectorEventInterest EventId, int16 Listen) mut => VT.[Friend]SetEventInterest(&this, EventId, Listen);
}

[CRepr]struct _IInkCollectorEvents : IDispatch
{
	public new const Guid IID = .(0x11a583f2, 0x712d, 0x4fea, 0xab, 0xcf, 0xab, 0x4a, 0xf3, 0x8e, 0xa0, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkOverlay : IDispatch
{
	public new const Guid IID = .(0xb82a463b, 0xc1c5, 0x45a3, 0x99, 0x7c, 0xde, 0xab, 0x56, 0x51, 0xb6, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* CurrentWindow) get_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int NewWindow) put_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Collecting) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Collecting) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** CurrentAttributes) get_DefaultDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* NewAttributes) putref_DefaultDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRenderer** CurrentInkRenderer) get_Renderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRenderer* NewInkRenderer) putref_Renderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** Ink) get_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp* NewInk) putref_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* AutoRedraw) get_AutoRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 AutoRedraw) put_AutoRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Collecting) get_CollectingInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectionMode* Mode) get_CollectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectionMode Mode) put_CollectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Enabled) get_DynamicRendering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Enabled) put_DynamicRendering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PacketGuids) get_DesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT PacketGuids) put_DesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp** MouseIcon) get_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) put_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) putref_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer* MousePointer) get_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer MousePointer) put_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEditingMode* EditingMode) get_EditingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEditingMode EditingMode) put_EditingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Selection) get_Selection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Selection) put_Selection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEraserMode* EraserMode) get_EraserMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEraserMode EraserMode) put_EraserMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* EraserWidth) get_EraserWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 newEraserWidth) put_EraserWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayAttachMode* AttachMode) get_AttachMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayAttachMode AttachMode) put_AttachMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCursors** Cursors) get_Cursors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MarginX) get_MarginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarginX) put_MarginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MarginY) get_MarginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarginY) put_MarginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet** SingleTablet) get_Tablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Support) get_SupportHighContrastInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Support) put_SupportHighContrastInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Support) get_SupportHighContrastSelectionUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Support) put_SupportHighContrastSelectionUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, SelectionHitResult* SelArea) HitTestSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rect) Draw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16 Listen) SetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16* Listening) GetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle** WindowInputRectangle) GetWindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* WindowInputRectangle) SetWindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 UseMouseForInput) SetAllTabletsMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet* Tablet) SetSingleTabletIntegratedMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectorEventInterest EventId, int16* Listen) GetEventInterest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectorEventInterest EventId, int16 Listen) SetEventInterest;
	}


	public HRESULT get_hWnd(int* CurrentWindow) mut => VT.[Friend]get_hWnd(&this, CurrentWindow);

	public HRESULT put_hWnd(int NewWindow) mut => VT.[Friend]put_hWnd(&this, NewWindow);

	public HRESULT get_Enabled(int16* Collecting) mut => VT.[Friend]get_Enabled(&this, Collecting);

	public HRESULT put_Enabled(int16 Collecting) mut => VT.[Friend]put_Enabled(&this, Collecting);

	public HRESULT get_DefaultDrawingAttributes(IInkDrawingAttributes** CurrentAttributes) mut => VT.[Friend]get_DefaultDrawingAttributes(&this, CurrentAttributes);

	public HRESULT putref_DefaultDrawingAttributes(IInkDrawingAttributes* NewAttributes) mut => VT.[Friend]putref_DefaultDrawingAttributes(&this, NewAttributes);

	public HRESULT get_Renderer(IInkRenderer** CurrentInkRenderer) mut => VT.[Friend]get_Renderer(&this, CurrentInkRenderer);

	public HRESULT putref_Renderer(IInkRenderer* NewInkRenderer) mut => VT.[Friend]putref_Renderer(&this, NewInkRenderer);

	public HRESULT get_Ink(IInkDisp** Ink) mut => VT.[Friend]get_Ink(&this, Ink);

	public HRESULT putref_Ink(IInkDisp* NewInk) mut => VT.[Friend]putref_Ink(&this, NewInk);

	public HRESULT get_AutoRedraw(int16* AutoRedraw) mut => VT.[Friend]get_AutoRedraw(&this, AutoRedraw);

	public HRESULT put_AutoRedraw(int16 AutoRedraw) mut => VT.[Friend]put_AutoRedraw(&this, AutoRedraw);

	public HRESULT get_CollectingInk(int16* Collecting) mut => VT.[Friend]get_CollectingInk(&this, Collecting);

	public HRESULT get_CollectionMode(InkCollectionMode* Mode) mut => VT.[Friend]get_CollectionMode(&this, Mode);

	public HRESULT put_CollectionMode(InkCollectionMode Mode) mut => VT.[Friend]put_CollectionMode(&this, Mode);

	public HRESULT get_DynamicRendering(int16* Enabled) mut => VT.[Friend]get_DynamicRendering(&this, Enabled);

	public HRESULT put_DynamicRendering(int16 Enabled) mut => VT.[Friend]put_DynamicRendering(&this, Enabled);

	public HRESULT get_DesiredPacketDescription(VARIANT* PacketGuids) mut => VT.[Friend]get_DesiredPacketDescription(&this, PacketGuids);

	public HRESULT put_DesiredPacketDescription(VARIANT PacketGuids) mut => VT.[Friend]put_DesiredPacketDescription(&this, PacketGuids);

	public HRESULT get_MouseIcon(IPictureDisp** MouseIcon) mut => VT.[Friend]get_MouseIcon(&this, MouseIcon);

	public HRESULT put_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]put_MouseIcon(&this, MouseIcon);

	public HRESULT putref_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]putref_MouseIcon(&this, MouseIcon);

	public HRESULT get_MousePointer(InkMousePointer* MousePointer) mut => VT.[Friend]get_MousePointer(&this, MousePointer);

	public HRESULT put_MousePointer(InkMousePointer MousePointer) mut => VT.[Friend]put_MousePointer(&this, MousePointer);

	public HRESULT get_EditingMode(InkOverlayEditingMode* EditingMode) mut => VT.[Friend]get_EditingMode(&this, EditingMode);

	public HRESULT put_EditingMode(InkOverlayEditingMode EditingMode) mut => VT.[Friend]put_EditingMode(&this, EditingMode);

	public HRESULT get_Selection(IInkStrokes** Selection) mut => VT.[Friend]get_Selection(&this, Selection);

	public HRESULT put_Selection(IInkStrokes* Selection) mut => VT.[Friend]put_Selection(&this, Selection);

	public HRESULT get_EraserMode(InkOverlayEraserMode* EraserMode) mut => VT.[Friend]get_EraserMode(&this, EraserMode);

	public HRESULT put_EraserMode(InkOverlayEraserMode EraserMode) mut => VT.[Friend]put_EraserMode(&this, EraserMode);

	public HRESULT get_EraserWidth(int32* EraserWidth) mut => VT.[Friend]get_EraserWidth(&this, EraserWidth);

	public HRESULT put_EraserWidth(int32 newEraserWidth) mut => VT.[Friend]put_EraserWidth(&this, newEraserWidth);

	public HRESULT get_AttachMode(InkOverlayAttachMode* AttachMode) mut => VT.[Friend]get_AttachMode(&this, AttachMode);

	public HRESULT put_AttachMode(InkOverlayAttachMode AttachMode) mut => VT.[Friend]put_AttachMode(&this, AttachMode);

	public HRESULT get_Cursors(IInkCursors** Cursors) mut => VT.[Friend]get_Cursors(&this, Cursors);

	public HRESULT get_MarginX(int32* MarginX) mut => VT.[Friend]get_MarginX(&this, MarginX);

	public HRESULT put_MarginX(int32 MarginX) mut => VT.[Friend]put_MarginX(&this, MarginX);

	public HRESULT get_MarginY(int32* MarginY) mut => VT.[Friend]get_MarginY(&this, MarginY);

	public HRESULT put_MarginY(int32 MarginY) mut => VT.[Friend]put_MarginY(&this, MarginY);

	public HRESULT get_Tablet(IInkTablet** SingleTablet) mut => VT.[Friend]get_Tablet(&this, SingleTablet);

	public HRESULT get_SupportHighContrastInk(int16* Support) mut => VT.[Friend]get_SupportHighContrastInk(&this, Support);

	public HRESULT put_SupportHighContrastInk(int16 Support) mut => VT.[Friend]put_SupportHighContrastInk(&this, Support);

	public HRESULT get_SupportHighContrastSelectionUI(int16* Support) mut => VT.[Friend]get_SupportHighContrastSelectionUI(&this, Support);

	public HRESULT put_SupportHighContrastSelectionUI(int16 Support) mut => VT.[Friend]put_SupportHighContrastSelectionUI(&this, Support);

	public HRESULT HitTestSelection(int32 x, int32 y, SelectionHitResult* SelArea) mut => VT.[Friend]HitTestSelection(&this, x, y, SelArea);

	public HRESULT Draw(IInkRectangle* Rect) mut => VT.[Friend]Draw(&this, Rect);

	public HRESULT SetGestureStatus(InkApplicationGesture Gesture, int16 Listen) mut => VT.[Friend]SetGestureStatus(&this, Gesture, Listen);

	public HRESULT GetGestureStatus(InkApplicationGesture Gesture, int16* Listening) mut => VT.[Friend]GetGestureStatus(&this, Gesture, Listening);

	public HRESULT GetWindowInputRectangle(IInkRectangle** WindowInputRectangle) mut => VT.[Friend]GetWindowInputRectangle(&this, WindowInputRectangle);

	public HRESULT SetWindowInputRectangle(IInkRectangle* WindowInputRectangle) mut => VT.[Friend]SetWindowInputRectangle(&this, WindowInputRectangle);

	public HRESULT SetAllTabletsMode(int16 UseMouseForInput) mut => VT.[Friend]SetAllTabletsMode(&this, UseMouseForInput);

	public HRESULT SetSingleTabletIntegratedMode(IInkTablet* Tablet) mut => VT.[Friend]SetSingleTabletIntegratedMode(&this, Tablet);

	public HRESULT GetEventInterest(InkCollectorEventInterest EventId, int16* Listen) mut => VT.[Friend]GetEventInterest(&this, EventId, Listen);

	public HRESULT SetEventInterest(InkCollectorEventInterest EventId, int16 Listen) mut => VT.[Friend]SetEventInterest(&this, EventId, Listen);
}

[CRepr]struct _IInkOverlayEvents : IDispatch
{
	public new const Guid IID = .(0x31179b69, 0xe563, 0x489e, 0xb1, 0x6f, 0x71, 0x2f, 0x1e, 0x8a, 0x06, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkPicture : IDispatch
{
	public new const Guid IID = .(0xe85662e0, 0x379a, 0x40d7, 0x9b, 0x5c, 0x75, 0x7d, 0x23, 0x3f, 0x99, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* CurrentWindow) get_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** CurrentAttributes) get_DefaultDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* NewAttributes) putref_DefaultDrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRenderer** CurrentInkRenderer) get_Renderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRenderer* NewInkRenderer) putref_Renderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** Ink) get_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp* NewInk) putref_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* AutoRedraw) get_AutoRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 AutoRedraw) put_AutoRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Collecting) get_CollectingInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectionMode* Mode) get_CollectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectionMode Mode) put_CollectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Enabled) get_DynamicRendering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Enabled) put_DynamicRendering;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PacketGuids) get_DesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT PacketGuids) put_DesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp** MouseIcon) get_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) put_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) putref_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer* MousePointer) get_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer MousePointer) put_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEditingMode* EditingMode) get_EditingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEditingMode EditingMode) put_EditingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Selection) get_Selection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Selection) put_Selection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEraserMode* EraserMode) get_EraserMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkOverlayEraserMode EraserMode) put_EraserMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* EraserWidth) get_EraserWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 newEraserWidth) put_EraserWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* pPicture) putref_Picture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* pPicture) put_Picture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp** ppPicture) get_Picture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkPictureSizeMode smNewSizeMode) put_SizeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkPictureSizeMode* smSizeMode) get_SizeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 newColor) put_BackColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pColor) get_BackColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCursors** Cursors) get_Cursors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MarginX) get_MarginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarginX) put_MarginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* MarginY) get_MarginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarginY) put_MarginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet** SingleTablet) get_Tablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Support) get_SupportHighContrastInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Support) put_SupportHighContrastInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Support) get_SupportHighContrastSelectionUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Support) put_SupportHighContrastSelectionUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, SelectionHitResult* SelArea) HitTestSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16 Listen) SetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16* Listening) GetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle** WindowInputRectangle) GetWindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* WindowInputRectangle) SetWindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 UseMouseForInput) SetAllTabletsMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet* Tablet) SetSingleTabletIntegratedMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectorEventInterest EventId, int16* Listen) GetEventInterest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkCollectorEventInterest EventId, int16 Listen) SetEventInterest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Collecting) get_InkEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Collecting) put_InkEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbool) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbool) put_Enabled;
	}


	public HRESULT get_hWnd(int* CurrentWindow) mut => VT.[Friend]get_hWnd(&this, CurrentWindow);

	public HRESULT get_DefaultDrawingAttributes(IInkDrawingAttributes** CurrentAttributes) mut => VT.[Friend]get_DefaultDrawingAttributes(&this, CurrentAttributes);

	public HRESULT putref_DefaultDrawingAttributes(IInkDrawingAttributes* NewAttributes) mut => VT.[Friend]putref_DefaultDrawingAttributes(&this, NewAttributes);

	public HRESULT get_Renderer(IInkRenderer** CurrentInkRenderer) mut => VT.[Friend]get_Renderer(&this, CurrentInkRenderer);

	public HRESULT putref_Renderer(IInkRenderer* NewInkRenderer) mut => VT.[Friend]putref_Renderer(&this, NewInkRenderer);

	public HRESULT get_Ink(IInkDisp** Ink) mut => VT.[Friend]get_Ink(&this, Ink);

	public HRESULT putref_Ink(IInkDisp* NewInk) mut => VT.[Friend]putref_Ink(&this, NewInk);

	public HRESULT get_AutoRedraw(int16* AutoRedraw) mut => VT.[Friend]get_AutoRedraw(&this, AutoRedraw);

	public HRESULT put_AutoRedraw(int16 AutoRedraw) mut => VT.[Friend]put_AutoRedraw(&this, AutoRedraw);

	public HRESULT get_CollectingInk(int16* Collecting) mut => VT.[Friend]get_CollectingInk(&this, Collecting);

	public HRESULT get_CollectionMode(InkCollectionMode* Mode) mut => VT.[Friend]get_CollectionMode(&this, Mode);

	public HRESULT put_CollectionMode(InkCollectionMode Mode) mut => VT.[Friend]put_CollectionMode(&this, Mode);

	public HRESULT get_DynamicRendering(int16* Enabled) mut => VT.[Friend]get_DynamicRendering(&this, Enabled);

	public HRESULT put_DynamicRendering(int16 Enabled) mut => VT.[Friend]put_DynamicRendering(&this, Enabled);

	public HRESULT get_DesiredPacketDescription(VARIANT* PacketGuids) mut => VT.[Friend]get_DesiredPacketDescription(&this, PacketGuids);

	public HRESULT put_DesiredPacketDescription(VARIANT PacketGuids) mut => VT.[Friend]put_DesiredPacketDescription(&this, PacketGuids);

	public HRESULT get_MouseIcon(IPictureDisp** MouseIcon) mut => VT.[Friend]get_MouseIcon(&this, MouseIcon);

	public HRESULT put_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]put_MouseIcon(&this, MouseIcon);

	public HRESULT putref_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]putref_MouseIcon(&this, MouseIcon);

	public HRESULT get_MousePointer(InkMousePointer* MousePointer) mut => VT.[Friend]get_MousePointer(&this, MousePointer);

	public HRESULT put_MousePointer(InkMousePointer MousePointer) mut => VT.[Friend]put_MousePointer(&this, MousePointer);

	public HRESULT get_EditingMode(InkOverlayEditingMode* EditingMode) mut => VT.[Friend]get_EditingMode(&this, EditingMode);

	public HRESULT put_EditingMode(InkOverlayEditingMode EditingMode) mut => VT.[Friend]put_EditingMode(&this, EditingMode);

	public HRESULT get_Selection(IInkStrokes** Selection) mut => VT.[Friend]get_Selection(&this, Selection);

	public HRESULT put_Selection(IInkStrokes* Selection) mut => VT.[Friend]put_Selection(&this, Selection);

	public HRESULT get_EraserMode(InkOverlayEraserMode* EraserMode) mut => VT.[Friend]get_EraserMode(&this, EraserMode);

	public HRESULT put_EraserMode(InkOverlayEraserMode EraserMode) mut => VT.[Friend]put_EraserMode(&this, EraserMode);

	public HRESULT get_EraserWidth(int32* EraserWidth) mut => VT.[Friend]get_EraserWidth(&this, EraserWidth);

	public HRESULT put_EraserWidth(int32 newEraserWidth) mut => VT.[Friend]put_EraserWidth(&this, newEraserWidth);

	public HRESULT putref_Picture(IPictureDisp* pPicture) mut => VT.[Friend]putref_Picture(&this, pPicture);

	public HRESULT put_Picture(IPictureDisp* pPicture) mut => VT.[Friend]put_Picture(&this, pPicture);

	public HRESULT get_Picture(IPictureDisp** ppPicture) mut => VT.[Friend]get_Picture(&this, ppPicture);

	public HRESULT put_SizeMode(InkPictureSizeMode smNewSizeMode) mut => VT.[Friend]put_SizeMode(&this, smNewSizeMode);

	public HRESULT get_SizeMode(InkPictureSizeMode* smSizeMode) mut => VT.[Friend]get_SizeMode(&this, smSizeMode);

	public HRESULT put_BackColor(uint32 newColor) mut => VT.[Friend]put_BackColor(&this, newColor);

	public HRESULT get_BackColor(uint32* pColor) mut => VT.[Friend]get_BackColor(&this, pColor);

	public HRESULT get_Cursors(IInkCursors** Cursors) mut => VT.[Friend]get_Cursors(&this, Cursors);

	public HRESULT get_MarginX(int32* MarginX) mut => VT.[Friend]get_MarginX(&this, MarginX);

	public HRESULT put_MarginX(int32 MarginX) mut => VT.[Friend]put_MarginX(&this, MarginX);

	public HRESULT get_MarginY(int32* MarginY) mut => VT.[Friend]get_MarginY(&this, MarginY);

	public HRESULT put_MarginY(int32 MarginY) mut => VT.[Friend]put_MarginY(&this, MarginY);

	public HRESULT get_Tablet(IInkTablet** SingleTablet) mut => VT.[Friend]get_Tablet(&this, SingleTablet);

	public HRESULT get_SupportHighContrastInk(int16* Support) mut => VT.[Friend]get_SupportHighContrastInk(&this, Support);

	public HRESULT put_SupportHighContrastInk(int16 Support) mut => VT.[Friend]put_SupportHighContrastInk(&this, Support);

	public HRESULT get_SupportHighContrastSelectionUI(int16* Support) mut => VT.[Friend]get_SupportHighContrastSelectionUI(&this, Support);

	public HRESULT put_SupportHighContrastSelectionUI(int16 Support) mut => VT.[Friend]put_SupportHighContrastSelectionUI(&this, Support);

	public HRESULT HitTestSelection(int32 x, int32 y, SelectionHitResult* SelArea) mut => VT.[Friend]HitTestSelection(&this, x, y, SelArea);

	public HRESULT SetGestureStatus(InkApplicationGesture Gesture, int16 Listen) mut => VT.[Friend]SetGestureStatus(&this, Gesture, Listen);

	public HRESULT GetGestureStatus(InkApplicationGesture Gesture, int16* Listening) mut => VT.[Friend]GetGestureStatus(&this, Gesture, Listening);

	public HRESULT GetWindowInputRectangle(IInkRectangle** WindowInputRectangle) mut => VT.[Friend]GetWindowInputRectangle(&this, WindowInputRectangle);

	public HRESULT SetWindowInputRectangle(IInkRectangle* WindowInputRectangle) mut => VT.[Friend]SetWindowInputRectangle(&this, WindowInputRectangle);

	public HRESULT SetAllTabletsMode(int16 UseMouseForInput) mut => VT.[Friend]SetAllTabletsMode(&this, UseMouseForInput);

	public HRESULT SetSingleTabletIntegratedMode(IInkTablet* Tablet) mut => VT.[Friend]SetSingleTabletIntegratedMode(&this, Tablet);

	public HRESULT GetEventInterest(InkCollectorEventInterest EventId, int16* Listen) mut => VT.[Friend]GetEventInterest(&this, EventId, Listen);

	public HRESULT SetEventInterest(InkCollectorEventInterest EventId, int16 Listen) mut => VT.[Friend]SetEventInterest(&this, EventId, Listen);

	public HRESULT get_InkEnabled(int16* Collecting) mut => VT.[Friend]get_InkEnabled(&this, Collecting);

	public HRESULT put_InkEnabled(int16 Collecting) mut => VT.[Friend]put_InkEnabled(&this, Collecting);

	public HRESULT get_Enabled(int16* pbool) mut => VT.[Friend]get_Enabled(&this, pbool);

	public HRESULT put_Enabled(int16 vbool) mut => VT.[Friend]put_Enabled(&this, vbool);
}

[CRepr]struct _IInkPictureEvents : IDispatch
{
	public new const Guid IID = .(0x60ff4fee, 0x22ff, 0x4484, 0xac, 0xc1, 0xd3, 0x08, 0xd9, 0xcd, 0x7e, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkRecognizer : IDispatch
{
	public new const Guid IID = .(0x782bf7cf, 0x034b, 0x4396, 0x8a, 0x32, 0x3a, 0x18, 0x33, 0xcf, 0x6b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Vendor) get_Vendor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognizerCapabilities* CapabilitiesFlags) get_Capabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Languages) get_Languages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* SupportedProperties) get_SupportedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PreferredPacketDescription) get_PreferredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizerContext** Context) CreateRecognizerContext;
	}


	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Vendor(BSTR* Vendor) mut => VT.[Friend]get_Vendor(&this, Vendor);

	public HRESULT get_Capabilities(InkRecognizerCapabilities* CapabilitiesFlags) mut => VT.[Friend]get_Capabilities(&this, CapabilitiesFlags);

	public HRESULT get_Languages(VARIANT* Languages) mut => VT.[Friend]get_Languages(&this, Languages);

	public HRESULT get_SupportedProperties(VARIANT* SupportedProperties) mut => VT.[Friend]get_SupportedProperties(&this, SupportedProperties);

	public HRESULT get_PreferredPacketDescription(VARIANT* PreferredPacketDescription) mut => VT.[Friend]get_PreferredPacketDescription(&this, PreferredPacketDescription);

	public HRESULT CreateRecognizerContext(IInkRecognizerContext** Context) mut => VT.[Friend]CreateRecognizerContext(&this, Context);
}

[CRepr]struct IInkRecognizer2 : IDispatch
{
	public new const Guid IID = .(0x6110118a, 0x3a75, 0x4ad6, 0xb2, 0xaa, 0x04, 0xb2, 0xb7, 0x2b, 0xbe, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* UnicodeRanges) get_UnicodeRanges;
	}


	public HRESULT get_Id(BSTR* pbstrId) mut => VT.[Friend]get_Id(&this, pbstrId);

	public HRESULT get_UnicodeRanges(VARIANT* UnicodeRanges) mut => VT.[Friend]get_UnicodeRanges(&this, UnicodeRanges);
}

[CRepr]struct IInkRecognizers : IDispatch
{
	public new const Guid IID = .(0x9ccc4f12, 0xb0b7, 0x4a8b, 0xbf, 0x58, 0x4a, 0xec, 0xa4, 0xe8, 0xce, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lcid, IInkRecognizer** DefaultRecognizer) GetDefaultRecognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IInkRecognizer** InkRecognizer) Item;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT GetDefaultRecognizer(int32 lcid, IInkRecognizer** DefaultRecognizer) mut => VT.[Friend]GetDefaultRecognizer(&this, lcid, DefaultRecognizer);

	public HRESULT Item(int32 Index, IInkRecognizer** InkRecognizer) mut => VT.[Friend]Item(&this, Index, InkRecognizer);
}

[CRepr]struct _IInkRecognitionEvents : IDispatch
{
	public new const Guid IID = .(0x17bce92f, 0x2e21, 0x47fd, 0x9d, 0x33, 0x3c, 0x6a, 0xfb, 0xfd, 0x8c, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkRecognizerContext : IDispatch
{
	public new const Guid IID = .(0xc68f52f9, 0x32a3, 0x4625, 0x90, 0x6c, 0x44, 0xfc, 0x23, 0xb4, 0x09, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes) putref_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognizerCharacterAutoCompletionMode* Mode) get_CharacterAutoCompletionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognizerCharacterAutoCompletionMode Mode) put_CharacterAutoCompletionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Factoid) get_Factoid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR factoid) put_Factoid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizerGuide** RecognizerGuide) get_Guide;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizerGuide* RecognizerGuide) putref_Guide;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Prefix) get_PrefixText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Prefix) put_PrefixText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Suffix) get_SuffixText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Suffix) put_SuffixText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognitionModes* Modes) get_RecognitionFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognitionModes Modes) put_RecognitionFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkWordList** WordList) get_WordList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkWordList* WordList) putref_WordList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizer** Recognizer) get_Recognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognitionStatus* RecognitionStatus, IInkRecognitionResult** RecognitionResult) Recognize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopBackgroundRecognition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndInkInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT CustomData) BackgroundRecognize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT CustomData) BackgroundRecognizeWithAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizerContext** RecoContext) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR String, int16* Supported) IsStringSupported;
	}


	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT putref_Strokes(IInkStrokes* Strokes) mut => VT.[Friend]putref_Strokes(&this, Strokes);

	public HRESULT get_CharacterAutoCompletionMode(InkRecognizerCharacterAutoCompletionMode* Mode) mut => VT.[Friend]get_CharacterAutoCompletionMode(&this, Mode);

	public HRESULT put_CharacterAutoCompletionMode(InkRecognizerCharacterAutoCompletionMode Mode) mut => VT.[Friend]put_CharacterAutoCompletionMode(&this, Mode);

	public HRESULT get_Factoid(BSTR* Factoid) mut => VT.[Friend]get_Factoid(&this, Factoid);

	public HRESULT put_Factoid(BSTR factoid) mut => VT.[Friend]put_Factoid(&this, factoid);

	public HRESULT get_Guide(IInkRecognizerGuide** RecognizerGuide) mut => VT.[Friend]get_Guide(&this, RecognizerGuide);

	public HRESULT putref_Guide(IInkRecognizerGuide* RecognizerGuide) mut => VT.[Friend]putref_Guide(&this, RecognizerGuide);

	public HRESULT get_PrefixText(BSTR* Prefix) mut => VT.[Friend]get_PrefixText(&this, Prefix);

	public HRESULT put_PrefixText(BSTR Prefix) mut => VT.[Friend]put_PrefixText(&this, Prefix);

	public HRESULT get_SuffixText(BSTR* Suffix) mut => VT.[Friend]get_SuffixText(&this, Suffix);

	public HRESULT put_SuffixText(BSTR Suffix) mut => VT.[Friend]put_SuffixText(&this, Suffix);

	public HRESULT get_RecognitionFlags(InkRecognitionModes* Modes) mut => VT.[Friend]get_RecognitionFlags(&this, Modes);

	public HRESULT put_RecognitionFlags(InkRecognitionModes Modes) mut => VT.[Friend]put_RecognitionFlags(&this, Modes);

	public HRESULT get_WordList(IInkWordList** WordList) mut => VT.[Friend]get_WordList(&this, WordList);

	public HRESULT putref_WordList(IInkWordList* WordList) mut => VT.[Friend]putref_WordList(&this, WordList);

	public HRESULT get_Recognizer(IInkRecognizer** Recognizer) mut => VT.[Friend]get_Recognizer(&this, Recognizer);

	public HRESULT Recognize(InkRecognitionStatus* RecognitionStatus, IInkRecognitionResult** RecognitionResult) mut => VT.[Friend]Recognize(&this, RecognitionStatus, RecognitionResult);

	public HRESULT StopBackgroundRecognition() mut => VT.[Friend]StopBackgroundRecognition(&this);

	public HRESULT EndInkInput() mut => VT.[Friend]EndInkInput(&this);

	public HRESULT BackgroundRecognize(VARIANT CustomData) mut => VT.[Friend]BackgroundRecognize(&this, CustomData);

	public HRESULT BackgroundRecognizeWithAlternates(VARIANT CustomData) mut => VT.[Friend]BackgroundRecognizeWithAlternates(&this, CustomData);

	public HRESULT Clone(IInkRecognizerContext** RecoContext) mut => VT.[Friend]Clone(&this, RecoContext);

	public HRESULT IsStringSupported(BSTR String, int16* Supported) mut => VT.[Friend]IsStringSupported(&this, String, Supported);
}

[CRepr]struct IInkRecognizerContext2 : IDispatch
{
	public new const Guid IID = .(0xd6f0e32f, 0x73d8, 0x408e, 0x8e, 0x9f, 0x5f, 0xea, 0x59, 0x2c, 0x36, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* UnicodeRanges) get_EnabledUnicodeRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT UnicodeRanges) put_EnabledUnicodeRanges;
	}


	public HRESULT get_EnabledUnicodeRanges(VARIANT* UnicodeRanges) mut => VT.[Friend]get_EnabledUnicodeRanges(&this, UnicodeRanges);

	public HRESULT put_EnabledUnicodeRanges(VARIANT UnicodeRanges) mut => VT.[Friend]put_EnabledUnicodeRanges(&this, UnicodeRanges);
}

[CRepr]struct IInkRecognitionResult : IDispatch
{
	public new const Guid IID = .(0x3bc129a8, 0x86cd, 0x45ad, 0xbd, 0xe8, 0xe0, 0xd3, 0x2d, 0x61, 0xc1, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* TopString) get_TopString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognitionAlternate** TopAlternate) get_TopAlternate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognitionConfidence* TopConfidence) get_TopConfidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 selectionStart, int32 selectionLength, int32 maximumAlternates, IInkRecognitionAlternates** AlternatesFromSelection) AlternatesFromSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognitionAlternate* Alternate) ModifyTopAlternate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetResultOnStrokes;
	}


	public HRESULT get_TopString(BSTR* TopString) mut => VT.[Friend]get_TopString(&this, TopString);

	public HRESULT get_TopAlternate(IInkRecognitionAlternate** TopAlternate) mut => VT.[Friend]get_TopAlternate(&this, TopAlternate);

	public HRESULT get_TopConfidence(InkRecognitionConfidence* TopConfidence) mut => VT.[Friend]get_TopConfidence(&this, TopConfidence);

	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT AlternatesFromSelection(int32 selectionStart, int32 selectionLength, int32 maximumAlternates, IInkRecognitionAlternates** AlternatesFromSelection) mut => VT.[Friend]AlternatesFromSelection(&this, selectionStart, selectionLength, maximumAlternates, AlternatesFromSelection);

	public HRESULT ModifyTopAlternate(IInkRecognitionAlternate* Alternate) mut => VT.[Friend]ModifyTopAlternate(&this, Alternate);

	public HRESULT SetResultOnStrokes() mut => VT.[Friend]SetResultOnStrokes(&this);
}

[CRepr]struct IInkRecognitionAlternate : IDispatch
{
	public new const Guid IID = .(0xb7e660ad, 0x77e4, 0x429b, 0xad, 0xda, 0x87, 0x37, 0x80, 0xd1, 0xfc, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* RecoString) get_String;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecognitionConfidence* Confidence) get_Confidence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Baseline) get_Baseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Midline) get_Midline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Ascender) get_Ascender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Descender) get_Descender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LineNumber) get_LineNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognitionAlternates** LineAlternates) get_LineAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognitionAlternates** ConfidenceAlternates) get_ConfidenceAlternates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes, IInkStrokes** GetStrokesFromStrokeRanges) GetStrokesFromStrokeRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* selectionStart, int32* selectionLength, IInkStrokes** GetStrokesFromTextRange) GetStrokesFromTextRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes, int32* selectionStart, int32* selectionLength) GetTextRangeFromStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyType, IInkRecognitionAlternates** AlternatesWithConstantPropertyValues) AlternatesWithConstantPropertyValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyType, VARIANT* PropertyValue) GetPropertyValue;
	}


	public HRESULT get_String(BSTR* RecoString) mut => VT.[Friend]get_String(&this, RecoString);

	public HRESULT get_Confidence(InkRecognitionConfidence* Confidence) mut => VT.[Friend]get_Confidence(&this, Confidence);

	public HRESULT get_Baseline(VARIANT* Baseline) mut => VT.[Friend]get_Baseline(&this, Baseline);

	public HRESULT get_Midline(VARIANT* Midline) mut => VT.[Friend]get_Midline(&this, Midline);

	public HRESULT get_Ascender(VARIANT* Ascender) mut => VT.[Friend]get_Ascender(&this, Ascender);

	public HRESULT get_Descender(VARIANT* Descender) mut => VT.[Friend]get_Descender(&this, Descender);

	public HRESULT get_LineNumber(int32* LineNumber) mut => VT.[Friend]get_LineNumber(&this, LineNumber);

	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT get_LineAlternates(IInkRecognitionAlternates** LineAlternates) mut => VT.[Friend]get_LineAlternates(&this, LineAlternates);

	public HRESULT get_ConfidenceAlternates(IInkRecognitionAlternates** ConfidenceAlternates) mut => VT.[Friend]get_ConfidenceAlternates(&this, ConfidenceAlternates);

	public HRESULT GetStrokesFromStrokeRanges(IInkStrokes* Strokes, IInkStrokes** GetStrokesFromStrokeRanges) mut => VT.[Friend]GetStrokesFromStrokeRanges(&this, Strokes, GetStrokesFromStrokeRanges);

	public HRESULT GetStrokesFromTextRange(int32* selectionStart, int32* selectionLength, IInkStrokes** GetStrokesFromTextRange) mut => VT.[Friend]GetStrokesFromTextRange(&this, selectionStart, selectionLength, GetStrokesFromTextRange);

	public HRESULT GetTextRangeFromStrokes(IInkStrokes* Strokes, int32* selectionStart, int32* selectionLength) mut => VT.[Friend]GetTextRangeFromStrokes(&this, Strokes, selectionStart, selectionLength);

	public HRESULT AlternatesWithConstantPropertyValues(BSTR PropertyType, IInkRecognitionAlternates** AlternatesWithConstantPropertyValues) mut => VT.[Friend]AlternatesWithConstantPropertyValues(&this, PropertyType, AlternatesWithConstantPropertyValues);

	public HRESULT GetPropertyValue(BSTR PropertyType, VARIANT* PropertyValue) mut => VT.[Friend]GetPropertyValue(&this, PropertyType, PropertyValue);
}

[CRepr]struct IInkRecognitionAlternates : IDispatch
{
	public new const Guid IID = .(0x286a167f, 0x9f19, 0x4c61, 0x9d, 0x53, 0x4f, 0x07, 0xbe, 0x62, 0x2b, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IInkRecognitionAlternate** InkRecoAlternate) Item;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT Item(int32 Index, IInkRecognitionAlternate** InkRecoAlternate) mut => VT.[Friend]Item(&this, Index, InkRecoAlternate);
}

[CRepr]struct IInkRecognizerGuide : IDispatch
{
	public new const Guid IID = .(0xd934be07, 0x7b84, 0x4208, 0x91, 0x36, 0x83, 0xc2, 0x09, 0x94, 0xe9, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle** Rectangle) get_WritingBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) put_WritingBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle** Rectangle) get_DrawnBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRectangle* Rectangle) put_DrawnBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Rows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Rows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Columns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Columns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Units) get_Midline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Units) put_Midline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecoGuide* pRecoGuide) get_GuideData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkRecoGuide recoGuide) put_GuideData;
	}


	public HRESULT get_WritingBox(IInkRectangle** Rectangle) mut => VT.[Friend]get_WritingBox(&this, Rectangle);

	public HRESULT put_WritingBox(IInkRectangle* Rectangle) mut => VT.[Friend]put_WritingBox(&this, Rectangle);

	public HRESULT get_DrawnBox(IInkRectangle** Rectangle) mut => VT.[Friend]get_DrawnBox(&this, Rectangle);

	public HRESULT put_DrawnBox(IInkRectangle* Rectangle) mut => VT.[Friend]put_DrawnBox(&this, Rectangle);

	public HRESULT get_Rows(int32* Units) mut => VT.[Friend]get_Rows(&this, Units);

	public HRESULT put_Rows(int32 Units) mut => VT.[Friend]put_Rows(&this, Units);

	public HRESULT get_Columns(int32* Units) mut => VT.[Friend]get_Columns(&this, Units);

	public HRESULT put_Columns(int32 Units) mut => VT.[Friend]put_Columns(&this, Units);

	public HRESULT get_Midline(int32* Units) mut => VT.[Friend]get_Midline(&this, Units);

	public HRESULT put_Midline(int32 Units) mut => VT.[Friend]put_Midline(&this, Units);

	public HRESULT get_GuideData(InkRecoGuide* pRecoGuide) mut => VT.[Friend]get_GuideData(&this, pRecoGuide);

	public HRESULT put_GuideData(InkRecoGuide recoGuide) mut => VT.[Friend]put_GuideData(&this, recoGuide);
}

[CRepr]struct IInkWordList : IDispatch
{
	public new const Guid IID = .(0x76ba3491, 0xcb2f, 0x406b, 0x99, 0x61, 0x0e, 0x0c, 0x4c, 0xda, 0xae, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR NewWord) AddWord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR RemoveWord) RemoveWord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkWordList* MergeWordList) Merge;
	}


	public HRESULT AddWord(BSTR NewWord) mut => VT.[Friend]AddWord(&this, NewWord);

	public HRESULT RemoveWord(BSTR RemoveWord) mut => VT.[Friend]RemoveWord(&this, RemoveWord);

	public HRESULT Merge(IInkWordList* MergeWordList) mut => VT.[Friend]Merge(&this, MergeWordList);
}

[CRepr]struct IInkWordList2 : IDispatch
{
	public new const Guid IID = .(0x14542586, 0x11bf, 0x4f5f, 0xb6, 0xe7, 0x49, 0xd0, 0x74, 0x4a, 0xab, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR NewWords) AddWords;
	}


	public HRESULT AddWords(BSTR NewWords) mut => VT.[Friend]AddWords(&this, NewWords);
}

[CRepr]struct IInk : IDispatch
{
	public new const Guid IID = .(0x03f8e511, 0x43a1, 0x11d3, 0x8b, 0xb6, 0x00, 0x80, 0xc7, 0xd6, 0xba, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkLineInfo : IUnknown
{
	public new const Guid IID = .(0x9c1c5ad6, 0xf22f, 0x4de4, 0xb4, 0x53, 0xa2, 0xcc, 0x48, 0x2e, 0x7c, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INKMETRIC* pim) SetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INKMETRIC* pim) GetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INKMETRIC* pim, uint32* pnWidth) GetInkExtent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCandidateNum, PWSTR pwcRecogWord, uint32* pcwcRecogWord, uint32 dwFlags) GetCandidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCandidateNum, PWSTR strRecogWord) SetCandidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Recognize;
	}


	public HRESULT SetFormat(INKMETRIC* pim) mut => VT.[Friend]SetFormat(&this, pim);

	public HRESULT GetFormat(INKMETRIC* pim) mut => VT.[Friend]GetFormat(&this, pim);

	public HRESULT GetInkExtent(INKMETRIC* pim, uint32* pnWidth) mut => VT.[Friend]GetInkExtent(&this, pim, pnWidth);

	public HRESULT GetCandidate(uint32 nCandidateNum, PWSTR pwcRecogWord, uint32* pcwcRecogWord, uint32 dwFlags) mut => VT.[Friend]GetCandidate(&this, nCandidateNum, pwcRecogWord, pcwcRecogWord, dwFlags);

	public HRESULT SetCandidate(uint32 nCandidateNum, PWSTR strRecogWord) mut => VT.[Friend]SetCandidate(&this, nCandidateNum, strRecogWord);

	public HRESULT Recognize() mut => VT.[Friend]Recognize(&this);
}

[CRepr]struct ISketchInk : IDispatch
{
	public new const Guid IID = .(0xb4563688, 0x98eb, 0x4646, 0xb2, 0x79, 0x44, 0xda, 0x14, 0xd4, 0x57, 0x48);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IInkDivider : IDispatch
{
	public new const Guid IID = .(0x5de00405, 0xf9a4, 0x4651, 0xb0, 0xc5, 0xc3, 0x17, 0xde, 0xfd, 0x58, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes* Strokes) putref_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizerContext** RecognizerContext) get_RecognizerContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizerContext* RecognizerContext) putref_RecognizerContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* LineHeight) get_LineHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 LineHeight) put_LineHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDivisionResult** InkDivisionResult) Divide;
	}


	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT putref_Strokes(IInkStrokes* Strokes) mut => VT.[Friend]putref_Strokes(&this, Strokes);

	public HRESULT get_RecognizerContext(IInkRecognizerContext** RecognizerContext) mut => VT.[Friend]get_RecognizerContext(&this, RecognizerContext);

	public HRESULT putref_RecognizerContext(IInkRecognizerContext* RecognizerContext) mut => VT.[Friend]putref_RecognizerContext(&this, RecognizerContext);

	public HRESULT get_LineHeight(int32* LineHeight) mut => VT.[Friend]get_LineHeight(&this, LineHeight);

	public HRESULT put_LineHeight(int32 LineHeight) mut => VT.[Friend]put_LineHeight(&this, LineHeight);

	public HRESULT Divide(IInkDivisionResult** InkDivisionResult) mut => VT.[Friend]Divide(&this, InkDivisionResult);
}

[CRepr]struct IInkDivisionResult : IDispatch
{
	public new const Guid IID = .(0x2dbec0a7, 0x74c7, 0x4b38, 0x81, 0xeb, 0xaa, 0x8e, 0xf0, 0xc2, 0x49, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkDivisionType divisionType, IInkDivisionUnits** InkDivisionUnits) ResultByType;
	}


	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT ResultByType(InkDivisionType divisionType, IInkDivisionUnits** InkDivisionUnits) mut => VT.[Friend]ResultByType(&this, divisionType, InkDivisionUnits);
}

[CRepr]struct IInkDivisionUnit : IDispatch
{
	public new const Guid IID = .(0x85aee342, 0x48b0, 0x4244, 0x9d, 0xd5, 0x1e, 0xd4, 0x35, 0x41, 0x0f, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkStrokes** Strokes) get_Strokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkDivisionType* divisionType) get_DivisionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* RecoString) get_RecognizedString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTransform** RotationTransform) get_RotationTransform;
	}


	public HRESULT get_Strokes(IInkStrokes** Strokes) mut => VT.[Friend]get_Strokes(&this, Strokes);

	public HRESULT get_DivisionType(InkDivisionType* divisionType) mut => VT.[Friend]get_DivisionType(&this, divisionType);

	public HRESULT get_RecognizedString(BSTR* RecoString) mut => VT.[Friend]get_RecognizedString(&this, RecoString);

	public HRESULT get_RotationTransform(IInkTransform** RotationTransform) mut => VT.[Friend]get_RotationTransform(&this, RotationTransform);
}

[CRepr]struct IInkDivisionUnits : IDispatch
{
	public new const Guid IID = .(0x1bb5ddc2, 0x31cc, 0x4135, 0xab, 0x82, 0x2c, 0x66, 0xc9, 0xf0, 0x0c, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** _NewEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IInkDivisionUnit** InkDivisionUnit) Item;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** _NewEnum) mut => VT.[Friend]get__NewEnum(&this, _NewEnum);

	public HRESULT Item(int32 Index, IInkDivisionUnit** InkDivisionUnit) mut => VT.[Friend]Item(&this, Index, InkDivisionUnit);
}

[CRepr]struct IPenInputPanel : IDispatch
{
	public new const Guid IID = .(0xfa7a4083, 0x5747, 0x4040, 0xa1, 0x82, 0x0b, 0x0e, 0x9f, 0xd4, 0xfa, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Busy) get_Busy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Factoid) get_Factoid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Factoid) put_Factoid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AttachedEditWindow) get_AttachedEditWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 AttachedEditWindow) put_AttachedEditWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelType* CurrentPanel) get_CurrentPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelType CurrentPanel) put_CurrentPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelType* pDefaultPanel) get_DefaultPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelType DefaultPanel) put_DefaultPanel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Visible) get_Visible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Visible) put_Visible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Top) get_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Left) get_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Width) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Height) get_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* VerticalOffset) get_VerticalOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 VerticalOffset) put_VerticalOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* HorizontalOffset) get_HorizontalOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 HorizontalOffset) put_HorizontalOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pAutoShow) get_AutoShow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 AutoShow) put_AutoShow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Left, int32 Top) MoveTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CommitPendingInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Enable) EnableTsf;
	}


	public HRESULT get_Busy(int16* Busy) mut => VT.[Friend]get_Busy(&this, Busy);

	public HRESULT get_Factoid(BSTR* Factoid) mut => VT.[Friend]get_Factoid(&this, Factoid);

	public HRESULT put_Factoid(BSTR Factoid) mut => VT.[Friend]put_Factoid(&this, Factoid);

	public HRESULT get_AttachedEditWindow(int32* AttachedEditWindow) mut => VT.[Friend]get_AttachedEditWindow(&this, AttachedEditWindow);

	public HRESULT put_AttachedEditWindow(int32 AttachedEditWindow) mut => VT.[Friend]put_AttachedEditWindow(&this, AttachedEditWindow);

	public HRESULT get_CurrentPanel(PanelType* CurrentPanel) mut => VT.[Friend]get_CurrentPanel(&this, CurrentPanel);

	public HRESULT put_CurrentPanel(PanelType CurrentPanel) mut => VT.[Friend]put_CurrentPanel(&this, CurrentPanel);

	public HRESULT get_DefaultPanel(PanelType* pDefaultPanel) mut => VT.[Friend]get_DefaultPanel(&this, pDefaultPanel);

	public HRESULT put_DefaultPanel(PanelType DefaultPanel) mut => VT.[Friend]put_DefaultPanel(&this, DefaultPanel);

	public HRESULT get_Visible(int16* Visible) mut => VT.[Friend]get_Visible(&this, Visible);

	public HRESULT put_Visible(int16 Visible) mut => VT.[Friend]put_Visible(&this, Visible);

	public HRESULT get_Top(int32* Top) mut => VT.[Friend]get_Top(&this, Top);

	public HRESULT get_Left(int32* Left) mut => VT.[Friend]get_Left(&this, Left);

	public HRESULT get_Width(int32* Width) mut => VT.[Friend]get_Width(&this, Width);

	public HRESULT get_Height(int32* Height) mut => VT.[Friend]get_Height(&this, Height);

	public HRESULT get_VerticalOffset(int32* VerticalOffset) mut => VT.[Friend]get_VerticalOffset(&this, VerticalOffset);

	public HRESULT put_VerticalOffset(int32 VerticalOffset) mut => VT.[Friend]put_VerticalOffset(&this, VerticalOffset);

	public HRESULT get_HorizontalOffset(int32* HorizontalOffset) mut => VT.[Friend]get_HorizontalOffset(&this, HorizontalOffset);

	public HRESULT put_HorizontalOffset(int32 HorizontalOffset) mut => VT.[Friend]put_HorizontalOffset(&this, HorizontalOffset);

	public HRESULT get_AutoShow(int16* pAutoShow) mut => VT.[Friend]get_AutoShow(&this, pAutoShow);

	public HRESULT put_AutoShow(int16 AutoShow) mut => VT.[Friend]put_AutoShow(&this, AutoShow);

	public HRESULT MoveTo(int32 Left, int32 Top) mut => VT.[Friend]MoveTo(&this, Left, Top);

	public HRESULT CommitPendingInput() mut => VT.[Friend]CommitPendingInput(&this);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT EnableTsf(int16 Enable) mut => VT.[Friend]EnableTsf(&this, Enable);
}

[CRepr]struct _IPenInputPanelEvents : IDispatch
{
	public new const Guid IID = .(0xb7e489da, 0x3719, 0x439f, 0x84, 0x8f, 0xe7, 0xac, 0xbd, 0x82, 0x0f, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IHandwrittenTextInsertion : IUnknown
{
	public new const Guid IID = .(0x56fdea97, 0xecd6, 0x43e7, 0xaa, 0x3a, 0x81, 0x6b, 0xe7, 0x78, 0x58, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* psaAlternates, uint32 locale, BOOL fAlternateContainsAutoSpacingInformation) InsertRecognitionResultsArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognitionResult* pIInkRecoResult, uint32 locale, BOOL fAlternateContainsAutoSpacingInformation) InsertInkRecognitionResult;
	}


	public HRESULT InsertRecognitionResultsArray(SAFEARRAY* psaAlternates, uint32 locale, BOOL fAlternateContainsAutoSpacingInformation) mut => VT.[Friend]InsertRecognitionResultsArray(&this, psaAlternates, locale, fAlternateContainsAutoSpacingInformation);

	public HRESULT InsertInkRecognitionResult(IInkRecognitionResult* pIInkRecoResult, uint32 locale, BOOL fAlternateContainsAutoSpacingInformation) mut => VT.[Friend]InsertInkRecognitionResult(&this, pIInkRecoResult, locale, fAlternateContainsAutoSpacingInformation);
}

[CRepr]struct ITextInputPanelEventSink : IUnknown
{
	public new const Guid IID = .(0x27560408, 0x8e64, 0x4fe1, 0x80, 0x4e, 0x42, 0x12, 0x01, 0x58, 0x4b, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceState oldInPlaceState, InPlaceState newInPlaceState) InPlaceStateChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceState oldInPlaceState, InPlaceState newInPlaceState) InPlaceStateChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT oldBoundingRectangle, RECT newBoundingRectangle) InPlaceSizeChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT oldBoundingRectangle, RECT newBoundingRectangle) InPlaceSizeChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelInputArea oldInputArea, PanelInputArea newInputArea) InputAreaChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelInputArea oldInputArea, PanelInputArea newInputArea) InputAreaChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CorrectionMode oldCorrectionMode, CorrectionMode newCorrectionMode) CorrectionModeChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CorrectionMode oldCorrectionMode, CorrectionMode newCorrectionMode) CorrectionModeChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL oldVisible, BOOL newVisible) InPlaceVisibilityChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL oldVisible, BOOL newVisible) InPlaceVisibilityChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* Ink) TextInserting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* Ink) TextInserted;
	}


	public HRESULT InPlaceStateChanging(InPlaceState oldInPlaceState, InPlaceState newInPlaceState) mut => VT.[Friend]InPlaceStateChanging(&this, oldInPlaceState, newInPlaceState);

	public HRESULT InPlaceStateChanged(InPlaceState oldInPlaceState, InPlaceState newInPlaceState) mut => VT.[Friend]InPlaceStateChanged(&this, oldInPlaceState, newInPlaceState);

	public HRESULT InPlaceSizeChanging(RECT oldBoundingRectangle, RECT newBoundingRectangle) mut => VT.[Friend]InPlaceSizeChanging(&this, oldBoundingRectangle, newBoundingRectangle);

	public HRESULT InPlaceSizeChanged(RECT oldBoundingRectangle, RECT newBoundingRectangle) mut => VT.[Friend]InPlaceSizeChanged(&this, oldBoundingRectangle, newBoundingRectangle);

	public HRESULT InputAreaChanging(PanelInputArea oldInputArea, PanelInputArea newInputArea) mut => VT.[Friend]InputAreaChanging(&this, oldInputArea, newInputArea);

	public HRESULT InputAreaChanged(PanelInputArea oldInputArea, PanelInputArea newInputArea) mut => VT.[Friend]InputAreaChanged(&this, oldInputArea, newInputArea);

	public HRESULT CorrectionModeChanging(CorrectionMode oldCorrectionMode, CorrectionMode newCorrectionMode) mut => VT.[Friend]CorrectionModeChanging(&this, oldCorrectionMode, newCorrectionMode);

	public HRESULT CorrectionModeChanged(CorrectionMode oldCorrectionMode, CorrectionMode newCorrectionMode) mut => VT.[Friend]CorrectionModeChanged(&this, oldCorrectionMode, newCorrectionMode);

	public HRESULT InPlaceVisibilityChanging(BOOL oldVisible, BOOL newVisible) mut => VT.[Friend]InPlaceVisibilityChanging(&this, oldVisible, newVisible);

	public HRESULT InPlaceVisibilityChanged(BOOL oldVisible, BOOL newVisible) mut => VT.[Friend]InPlaceVisibilityChanged(&this, oldVisible, newVisible);

	public HRESULT TextInserting(SAFEARRAY* Ink) mut => VT.[Friend]TextInserting(&this, Ink);

	public HRESULT TextInserted(SAFEARRAY* Ink) mut => VT.[Friend]TextInserted(&this, Ink);
}

[CRepr]struct ITextInputPanel : IUnknown
{
	public new const Guid IID = .(0x6b6a65a5, 0x6af3, 0x46c2, 0xb6, 0xea, 0x56, 0xcd, 0x1f, 0x80, 0xdf, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* AttachedEditWindow) get_AttachedEditWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND AttachedEditWindow) put_AttachedEditWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InteractionMode* CurrentInteractionMode) get_CurrentInteractionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceState* State) get_DefaultInPlaceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceState State) put_DefaultInPlaceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceState* State) get_CurrentInPlaceState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelInputArea* Area) get_DefaultInputArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelInputArea Area) put_DefaultInputArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PanelInputArea* Area) get_CurrentInputArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CorrectionMode* Mode) get_CurrentCorrectionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceDirection* Direction) get_PreferredInPlaceDirection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InPlaceDirection Direction) put_PreferredInPlaceDirection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Expand) get_ExpandPostInsertionCorrection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Expand) put_ExpandPostInsertionCorrection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Visible) get_InPlaceVisibleOnFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Visible) put_InPlaceVisibleOnFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* BoundingRectangle) get_InPlaceBoundingRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Height) get_PopUpCorrectionHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Height) get_PopDownCorrectionHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CommitPendingInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Visible) SetInPlaceVisibility;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 xPosition, int32 yPosition, CorrectionPosition position) SetInPlacePosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 xPosition, int32 yPosition) SetInPlaceHoverTargetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextInputPanelEventSink* EventSink, uint32 EventMask) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextInputPanelEventSink* EventSink) Unadvise;
	}


	public HRESULT get_AttachedEditWindow(HWND* AttachedEditWindow) mut => VT.[Friend]get_AttachedEditWindow(&this, AttachedEditWindow);

	public HRESULT put_AttachedEditWindow(HWND AttachedEditWindow) mut => VT.[Friend]put_AttachedEditWindow(&this, AttachedEditWindow);

	public HRESULT get_CurrentInteractionMode(InteractionMode* CurrentInteractionMode) mut => VT.[Friend]get_CurrentInteractionMode(&this, CurrentInteractionMode);

	public HRESULT get_DefaultInPlaceState(InPlaceState* State) mut => VT.[Friend]get_DefaultInPlaceState(&this, State);

	public HRESULT put_DefaultInPlaceState(InPlaceState State) mut => VT.[Friend]put_DefaultInPlaceState(&this, State);

	public HRESULT get_CurrentInPlaceState(InPlaceState* State) mut => VT.[Friend]get_CurrentInPlaceState(&this, State);

	public HRESULT get_DefaultInputArea(PanelInputArea* Area) mut => VT.[Friend]get_DefaultInputArea(&this, Area);

	public HRESULT put_DefaultInputArea(PanelInputArea Area) mut => VT.[Friend]put_DefaultInputArea(&this, Area);

	public HRESULT get_CurrentInputArea(PanelInputArea* Area) mut => VT.[Friend]get_CurrentInputArea(&this, Area);

	public HRESULT get_CurrentCorrectionMode(CorrectionMode* Mode) mut => VT.[Friend]get_CurrentCorrectionMode(&this, Mode);

	public HRESULT get_PreferredInPlaceDirection(InPlaceDirection* Direction) mut => VT.[Friend]get_PreferredInPlaceDirection(&this, Direction);

	public HRESULT put_PreferredInPlaceDirection(InPlaceDirection Direction) mut => VT.[Friend]put_PreferredInPlaceDirection(&this, Direction);

	public HRESULT get_ExpandPostInsertionCorrection(BOOL* Expand) mut => VT.[Friend]get_ExpandPostInsertionCorrection(&this, Expand);

	public HRESULT put_ExpandPostInsertionCorrection(BOOL Expand) mut => VT.[Friend]put_ExpandPostInsertionCorrection(&this, Expand);

	public HRESULT get_InPlaceVisibleOnFocus(BOOL* Visible) mut => VT.[Friend]get_InPlaceVisibleOnFocus(&this, Visible);

	public HRESULT put_InPlaceVisibleOnFocus(BOOL Visible) mut => VT.[Friend]put_InPlaceVisibleOnFocus(&this, Visible);

	public HRESULT get_InPlaceBoundingRectangle(RECT* BoundingRectangle) mut => VT.[Friend]get_InPlaceBoundingRectangle(&this, BoundingRectangle);

	public HRESULT get_PopUpCorrectionHeight(int32* Height) mut => VT.[Friend]get_PopUpCorrectionHeight(&this, Height);

	public HRESULT get_PopDownCorrectionHeight(int32* Height) mut => VT.[Friend]get_PopDownCorrectionHeight(&this, Height);

	public HRESULT CommitPendingInput() mut => VT.[Friend]CommitPendingInput(&this);

	public HRESULT SetInPlaceVisibility(BOOL Visible) mut => VT.[Friend]SetInPlaceVisibility(&this, Visible);

	public HRESULT SetInPlacePosition(int32 xPosition, int32 yPosition, CorrectionPosition position) mut => VT.[Friend]SetInPlacePosition(&this, xPosition, yPosition, position);

	public HRESULT SetInPlaceHoverTargetPosition(int32 xPosition, int32 yPosition) mut => VT.[Friend]SetInPlaceHoverTargetPosition(&this, xPosition, yPosition);

	public HRESULT Advise(ITextInputPanelEventSink* EventSink, uint32 EventMask) mut => VT.[Friend]Advise(&this, EventSink, EventMask);

	public HRESULT Unadvise(ITextInputPanelEventSink* EventSink) mut => VT.[Friend]Unadvise(&this, EventSink);
}

[CRepr]struct IInputPanelWindowHandle : IUnknown
{
	public new const Guid IID = .(0x4af81847, 0xfdc4, 0x4fc3, 0xad, 0x0b, 0x42, 0x24, 0x79, 0xc1, 0xb9, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* AttachedEditWindow) get_AttachedEditWindow32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 AttachedEditWindow) put_AttachedEditWindow32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* AttachedEditWindow) get_AttachedEditWindow64;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 AttachedEditWindow) put_AttachedEditWindow64;
	}


	public HRESULT get_AttachedEditWindow32(int32* AttachedEditWindow) mut => VT.[Friend]get_AttachedEditWindow32(&this, AttachedEditWindow);

	public HRESULT put_AttachedEditWindow32(int32 AttachedEditWindow) mut => VT.[Friend]put_AttachedEditWindow32(&this, AttachedEditWindow);

	public HRESULT get_AttachedEditWindow64(int64* AttachedEditWindow) mut => VT.[Friend]get_AttachedEditWindow64(&this, AttachedEditWindow);

	public HRESULT put_AttachedEditWindow64(int64 AttachedEditWindow) mut => VT.[Friend]put_AttachedEditWindow64(&this, AttachedEditWindow);
}

[CRepr]struct ITextInputPanelRunInfo : IUnknown
{
	public new const Guid IID = .(0x9f424568, 0x1920, 0x48cc, 0x98, 0x11, 0xa9, 0x93, 0xcb, 0xf5, 0xad, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfRunning) IsTipRunning;
	}


	public HRESULT IsTipRunning(BOOL* pfRunning) mut => VT.[Friend]IsTipRunning(&this, pfRunning);
}

[CRepr]struct IInkEdit : IDispatch
{
	public new const Guid IID = .(0xf2127a19, 0xfbfb, 0x4aed, 0x84, 0x64, 0x3f, 0x36, 0xd7, 0x8c, 0xfe, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkEditStatus* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_UseMouseForInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_UseMouseForInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMode* pVal) get_InkMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMode newVal) put_InkMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkInsertMode* pVal) get_InkInsertMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkInsertMode newVal) put_InkInsertMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** pVal) get_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* newVal) putref_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_RecognitionTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 newVal) put_RecognitionTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizer** pVal) get_Recognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkRecognizer* newVal) putref_Recognizer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Factoid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_Factoid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pSelInk) get_SelInks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT SelInk) put_SelInks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkDisplayMode* pInkDisplayMode) get_SelInksDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkDisplayMode InkDisplayMode) put_SelInksDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Recognize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16* pListen) GetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkApplicationGesture Gesture, int16 Listen) SetGestureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 clr) put_BackColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pclr) get_BackColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AppearanceConstants* pAppearance) get_Appearance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AppearanceConstants pAppearance) put_Appearance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BorderStyleConstants* pBorderStyle) get_BorderStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BorderStyleConstants pBorderStyle) put_BorderStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pohHwnd) get_Hwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFontDisp** ppFont) get_Font;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFontDisp* ppFont) putref_Font;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrText) get_Text;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pbstrText) put_Text;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp** MouseIcon) get_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) put_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp* MouseIcon) putref_MouseIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer* MousePointer) get_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InkMousePointer MousePointer) put_MousePointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Locked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_Locked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxLength) get_MaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxLength) put_MaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_MultiLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_MultiLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ScrollBarsConstants* pVal) get_ScrollBars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ScrollBarsConstants newVal) put_ScrollBars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_DisableNoScroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_DisableNoScroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelAlignment) get_SelAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelAlignment) put_SelAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelBold) get_SelBold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelBold) put_SelBold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelItalic) get_SelItalic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelItalic) put_SelItalic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelUnderline) get_SelUnderline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelUnderline) put_SelUnderline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelColor) get_SelColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelColor) put_SelColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelFontName) get_SelFontName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelFontName) put_SelFontName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelFontSize) get_SelFontSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelFontSize) put_SelFontSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSelCharOffset) get_SelCharOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvarSelCharOffset) put_SelCharOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTextRTF) get_TextRTF;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pbstrTextRTF) put_TextRTF;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSelStart) get_SelStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 plSelStart) put_SelStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSelLength) get_SelLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 plSelLength) put_SelLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSelText) get_SelText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pbstrSelText) put_SelText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSelRTF) get_SelRTF;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pbstrSelRTF) put_SelRTF;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
	}


	public HRESULT get_Status(InkEditStatus* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_UseMouseForInput(int16* pVal) mut => VT.[Friend]get_UseMouseForInput(&this, pVal);

	public HRESULT put_UseMouseForInput(int16 newVal) mut => VT.[Friend]put_UseMouseForInput(&this, newVal);

	public HRESULT get_InkMode(InkMode* pVal) mut => VT.[Friend]get_InkMode(&this, pVal);

	public HRESULT put_InkMode(InkMode newVal) mut => VT.[Friend]put_InkMode(&this, newVal);

	public HRESULT get_InkInsertMode(InkInsertMode* pVal) mut => VT.[Friend]get_InkInsertMode(&this, pVal);

	public HRESULT put_InkInsertMode(InkInsertMode newVal) mut => VT.[Friend]put_InkInsertMode(&this, newVal);

	public HRESULT get_DrawingAttributes(IInkDrawingAttributes** pVal) mut => VT.[Friend]get_DrawingAttributes(&this, pVal);

	public HRESULT putref_DrawingAttributes(IInkDrawingAttributes* newVal) mut => VT.[Friend]putref_DrawingAttributes(&this, newVal);

	public HRESULT get_RecognitionTimeout(int32* pVal) mut => VT.[Friend]get_RecognitionTimeout(&this, pVal);

	public HRESULT put_RecognitionTimeout(int32 newVal) mut => VT.[Friend]put_RecognitionTimeout(&this, newVal);

	public HRESULT get_Recognizer(IInkRecognizer** pVal) mut => VT.[Friend]get_Recognizer(&this, pVal);

	public HRESULT putref_Recognizer(IInkRecognizer* newVal) mut => VT.[Friend]putref_Recognizer(&this, newVal);

	public HRESULT get_Factoid(BSTR* pVal) mut => VT.[Friend]get_Factoid(&this, pVal);

	public HRESULT put_Factoid(BSTR newVal) mut => VT.[Friend]put_Factoid(&this, newVal);

	public HRESULT get_SelInks(VARIANT* pSelInk) mut => VT.[Friend]get_SelInks(&this, pSelInk);

	public HRESULT put_SelInks(VARIANT SelInk) mut => VT.[Friend]put_SelInks(&this, SelInk);

	public HRESULT get_SelInksDisplayMode(InkDisplayMode* pInkDisplayMode) mut => VT.[Friend]get_SelInksDisplayMode(&this, pInkDisplayMode);

	public HRESULT put_SelInksDisplayMode(InkDisplayMode InkDisplayMode) mut => VT.[Friend]put_SelInksDisplayMode(&this, InkDisplayMode);

	public HRESULT Recognize() mut => VT.[Friend]Recognize(&this);

	public HRESULT GetGestureStatus(InkApplicationGesture Gesture, int16* pListen) mut => VT.[Friend]GetGestureStatus(&this, Gesture, pListen);

	public HRESULT SetGestureStatus(InkApplicationGesture Gesture, int16 Listen) mut => VT.[Friend]SetGestureStatus(&this, Gesture, Listen);

	public HRESULT put_BackColor(uint32 clr) mut => VT.[Friend]put_BackColor(&this, clr);

	public HRESULT get_BackColor(uint32* pclr) mut => VT.[Friend]get_BackColor(&this, pclr);

	public HRESULT get_Appearance(AppearanceConstants* pAppearance) mut => VT.[Friend]get_Appearance(&this, pAppearance);

	public HRESULT put_Appearance(AppearanceConstants pAppearance) mut => VT.[Friend]put_Appearance(&this, pAppearance);

	public HRESULT get_BorderStyle(BorderStyleConstants* pBorderStyle) mut => VT.[Friend]get_BorderStyle(&this, pBorderStyle);

	public HRESULT put_BorderStyle(BorderStyleConstants pBorderStyle) mut => VT.[Friend]put_BorderStyle(&this, pBorderStyle);

	public HRESULT get_Hwnd(uint32* pohHwnd) mut => VT.[Friend]get_Hwnd(&this, pohHwnd);

	public HRESULT get_Font(IFontDisp** ppFont) mut => VT.[Friend]get_Font(&this, ppFont);

	public HRESULT putref_Font(IFontDisp* ppFont) mut => VT.[Friend]putref_Font(&this, ppFont);

	public HRESULT get_Text(BSTR* pbstrText) mut => VT.[Friend]get_Text(&this, pbstrText);

	public HRESULT put_Text(BSTR pbstrText) mut => VT.[Friend]put_Text(&this, pbstrText);

	public HRESULT get_MouseIcon(IPictureDisp** MouseIcon) mut => VT.[Friend]get_MouseIcon(&this, MouseIcon);

	public HRESULT put_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]put_MouseIcon(&this, MouseIcon);

	public HRESULT putref_MouseIcon(IPictureDisp* MouseIcon) mut => VT.[Friend]putref_MouseIcon(&this, MouseIcon);

	public HRESULT get_MousePointer(InkMousePointer* MousePointer) mut => VT.[Friend]get_MousePointer(&this, MousePointer);

	public HRESULT put_MousePointer(InkMousePointer MousePointer) mut => VT.[Friend]put_MousePointer(&this, MousePointer);

	public HRESULT get_Locked(int16* pVal) mut => VT.[Friend]get_Locked(&this, pVal);

	public HRESULT put_Locked(int16 newVal) mut => VT.[Friend]put_Locked(&this, newVal);

	public HRESULT get_Enabled(int16* pVal) mut => VT.[Friend]get_Enabled(&this, pVal);

	public HRESULT put_Enabled(int16 newVal) mut => VT.[Friend]put_Enabled(&this, newVal);

	public HRESULT get_MaxLength(int32* plMaxLength) mut => VT.[Friend]get_MaxLength(&this, plMaxLength);

	public HRESULT put_MaxLength(int32 lMaxLength) mut => VT.[Friend]put_MaxLength(&this, lMaxLength);

	public HRESULT get_MultiLine(int16* pVal) mut => VT.[Friend]get_MultiLine(&this, pVal);

	public HRESULT put_MultiLine(int16 newVal) mut => VT.[Friend]put_MultiLine(&this, newVal);

	public HRESULT get_ScrollBars(ScrollBarsConstants* pVal) mut => VT.[Friend]get_ScrollBars(&this, pVal);

	public HRESULT put_ScrollBars(ScrollBarsConstants newVal) mut => VT.[Friend]put_ScrollBars(&this, newVal);

	public HRESULT get_DisableNoScroll(int16* pVal) mut => VT.[Friend]get_DisableNoScroll(&this, pVal);

	public HRESULT put_DisableNoScroll(int16 newVal) mut => VT.[Friend]put_DisableNoScroll(&this, newVal);

	public HRESULT get_SelAlignment(VARIANT* pvarSelAlignment) mut => VT.[Friend]get_SelAlignment(&this, pvarSelAlignment);

	public HRESULT put_SelAlignment(VARIANT pvarSelAlignment) mut => VT.[Friend]put_SelAlignment(&this, pvarSelAlignment);

	public HRESULT get_SelBold(VARIANT* pvarSelBold) mut => VT.[Friend]get_SelBold(&this, pvarSelBold);

	public HRESULT put_SelBold(VARIANT pvarSelBold) mut => VT.[Friend]put_SelBold(&this, pvarSelBold);

	public HRESULT get_SelItalic(VARIANT* pvarSelItalic) mut => VT.[Friend]get_SelItalic(&this, pvarSelItalic);

	public HRESULT put_SelItalic(VARIANT pvarSelItalic) mut => VT.[Friend]put_SelItalic(&this, pvarSelItalic);

	public HRESULT get_SelUnderline(VARIANT* pvarSelUnderline) mut => VT.[Friend]get_SelUnderline(&this, pvarSelUnderline);

	public HRESULT put_SelUnderline(VARIANT pvarSelUnderline) mut => VT.[Friend]put_SelUnderline(&this, pvarSelUnderline);

	public HRESULT get_SelColor(VARIANT* pvarSelColor) mut => VT.[Friend]get_SelColor(&this, pvarSelColor);

	public HRESULT put_SelColor(VARIANT pvarSelColor) mut => VT.[Friend]put_SelColor(&this, pvarSelColor);

	public HRESULT get_SelFontName(VARIANT* pvarSelFontName) mut => VT.[Friend]get_SelFontName(&this, pvarSelFontName);

	public HRESULT put_SelFontName(VARIANT pvarSelFontName) mut => VT.[Friend]put_SelFontName(&this, pvarSelFontName);

	public HRESULT get_SelFontSize(VARIANT* pvarSelFontSize) mut => VT.[Friend]get_SelFontSize(&this, pvarSelFontSize);

	public HRESULT put_SelFontSize(VARIANT pvarSelFontSize) mut => VT.[Friend]put_SelFontSize(&this, pvarSelFontSize);

	public HRESULT get_SelCharOffset(VARIANT* pvarSelCharOffset) mut => VT.[Friend]get_SelCharOffset(&this, pvarSelCharOffset);

	public HRESULT put_SelCharOffset(VARIANT pvarSelCharOffset) mut => VT.[Friend]put_SelCharOffset(&this, pvarSelCharOffset);

	public HRESULT get_TextRTF(BSTR* pbstrTextRTF) mut => VT.[Friend]get_TextRTF(&this, pbstrTextRTF);

	public HRESULT put_TextRTF(BSTR pbstrTextRTF) mut => VT.[Friend]put_TextRTF(&this, pbstrTextRTF);

	public HRESULT get_SelStart(int32* plSelStart) mut => VT.[Friend]get_SelStart(&this, plSelStart);

	public HRESULT put_SelStart(int32 plSelStart) mut => VT.[Friend]put_SelStart(&this, plSelStart);

	public HRESULT get_SelLength(int32* plSelLength) mut => VT.[Friend]get_SelLength(&this, plSelLength);

	public HRESULT put_SelLength(int32 plSelLength) mut => VT.[Friend]put_SelLength(&this, plSelLength);

	public HRESULT get_SelText(BSTR* pbstrSelText) mut => VT.[Friend]get_SelText(&this, pbstrSelText);

	public HRESULT put_SelText(BSTR pbstrSelText) mut => VT.[Friend]put_SelText(&this, pbstrSelText);

	public HRESULT get_SelRTF(BSTR* pbstrSelRTF) mut => VT.[Friend]get_SelRTF(&this, pbstrSelRTF);

	public HRESULT put_SelRTF(BSTR pbstrSelRTF) mut => VT.[Friend]put_SelRTF(&this, pbstrSelRTF);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);
}

[CRepr]struct _IInkEditEvents : IDispatch
{
	public new const Guid IID = .(0xe3b0b797, 0xa72e, 0x46db, 0xa0, 0xd7, 0x6c, 0x9e, 0xba, 0x8e, 0x9b, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IMathInputControl : IDispatch
{
	public new const Guid IID = .(0xeba615aa, 0xfac6, 0x4738, 0xba, 0x5f, 0xff, 0x09, 0xe9, 0xfe, 0x47, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Hide;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbShown) IsVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Left, int32* Top, int32* Right, int32* Bottom) GetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Left, int32 Top, int32 Right, int32 Bottom) SetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Element, int16 Paint) SetCustomPaint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR CaptionText) SetCaptionText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp* Ink) LoadInk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int OwnerWindow) SetOwnerWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Extended) EnableExtendedButtons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Height) GetPreviewHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Height) SetPreviewHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 AutoGrow) EnableAutoGrow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FunctionName) AddFunctionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FunctionName) RemoveFunctionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPictureDisp** HoverImage) GetHoverIcon;
	}


	public HRESULT Show() mut => VT.[Friend]Show(&this);

	public HRESULT Hide() mut => VT.[Friend]Hide(&this);

	public HRESULT IsVisible(int16* pvbShown) mut => VT.[Friend]IsVisible(&this, pvbShown);

	public HRESULT GetPosition(int32* Left, int32* Top, int32* Right, int32* Bottom) mut => VT.[Friend]GetPosition(&this, Left, Top, Right, Bottom);

	public HRESULT SetPosition(int32 Left, int32 Top, int32 Right, int32 Bottom) mut => VT.[Friend]SetPosition(&this, Left, Top, Right, Bottom);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT SetCustomPaint(int32 Element, int16 Paint) mut => VT.[Friend]SetCustomPaint(&this, Element, Paint);

	public HRESULT SetCaptionText(BSTR CaptionText) mut => VT.[Friend]SetCaptionText(&this, CaptionText);

	public HRESULT LoadInk(IInkDisp* Ink) mut => VT.[Friend]LoadInk(&this, Ink);

	public HRESULT SetOwnerWindow(int OwnerWindow) mut => VT.[Friend]SetOwnerWindow(&this, OwnerWindow);

	public HRESULT EnableExtendedButtons(int16 Extended) mut => VT.[Friend]EnableExtendedButtons(&this, Extended);

	public HRESULT GetPreviewHeight(int32* Height) mut => VT.[Friend]GetPreviewHeight(&this, Height);

	public HRESULT SetPreviewHeight(int32 Height) mut => VT.[Friend]SetPreviewHeight(&this, Height);

	public HRESULT EnableAutoGrow(int16 AutoGrow) mut => VT.[Friend]EnableAutoGrow(&this, AutoGrow);

	public HRESULT AddFunctionName(BSTR FunctionName) mut => VT.[Friend]AddFunctionName(&this, FunctionName);

	public HRESULT RemoveFunctionName(BSTR FunctionName) mut => VT.[Friend]RemoveFunctionName(&this, FunctionName);

	public HRESULT GetHoverIcon(IPictureDisp** HoverImage) mut => VT.[Friend]GetHoverIcon(&this, HoverImage);
}

[CRepr]struct _IMathInputControlEvents : IDispatch
{
	public new const Guid IID = .(0x683336b5, 0xa47d, 0x4358, 0x96, 0xf9, 0x87, 0x5a, 0x47, 0x2a, 0xe7, 0x0a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IRealTimeStylus : IUnknown
{
	public new const Guid IID = .(0xa8bb5d22, 0x3144, 0x4a7b, 0x93, 0xcd, 0xf3, 0x4a, 0x16, 0xbe, 0x51, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnable) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR* phwnd) get_HWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hwnd) put_HWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcWndInputRect) get_WindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcWndInputRect) put_WindowInputRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IStylusSyncPlugin* piPlugin) AddStylusSyncPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IStylusSyncPlugin** ppiPlugin) RemoveStylusSyncPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllStylusSyncPlugins;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IStylusSyncPlugin** ppiPlugin) GetStylusSyncPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcPlugins) GetStylusSyncPluginCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IStylusAsyncPlugin* piPlugin) AddStylusAsyncPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IStylusAsyncPlugin** ppiPlugin) RemoveStylusAsyncPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllStylusAsyncPlugins;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IStylusAsyncPlugin** ppiPlugin) GetStylusAsyncPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcPlugins) GetStylusAsyncPluginCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus** ppiRTS) get_ChildRealTimeStylusPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRTS) putref_ChildRealTimeStylusPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, StylusQueue sq, in Guid pGuidId, uint32 cbData, uint8* pbData) AddCustomStylusDataToQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearStylusQueues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUseMouseForInput) SetAllTabletsMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet* piTablet) SetSingleTabletMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet** ppiSingleTablet) GetTablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkTablet* piTablet, uint32* ptcid) GetTabletContextIdFromTablet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tcid, IInkTablet** ppiTablet) GetTabletFromTabletContextId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcTcidCount, uint32** ppTcids) GetAllTabletContextIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCursors** ppiInkCursors) GetStyluses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 sid, IInkCursor** ppiInkCursor) GetStylusForId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cProperties, Guid* pPropertyGuids) SetDesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcProperties, Guid** ppPropertyGuids) GetDesiredPacketDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tcid, float* pfInkToDeviceScaleX, float* pfInkToDeviceScaleY, uint32* pcPacketProperties, PACKET_PROPERTY** ppPacketProperties) GetPacketDescriptionData;
	}


	public HRESULT get_Enabled(BOOL* pfEnable) mut => VT.[Friend]get_Enabled(&this, pfEnable);

	public HRESULT put_Enabled(BOOL fEnable) mut => VT.[Friend]put_Enabled(&this, fEnable);

	public HRESULT get_HWND(HANDLE_PTR* phwnd) mut => VT.[Friend]get_HWND(&this, phwnd);

	public HRESULT put_HWND(HANDLE_PTR hwnd) mut => VT.[Friend]put_HWND(&this, hwnd);

	public HRESULT get_WindowInputRectangle(RECT* prcWndInputRect) mut => VT.[Friend]get_WindowInputRectangle(&this, prcWndInputRect);

	public HRESULT put_WindowInputRectangle(RECT* prcWndInputRect) mut => VT.[Friend]put_WindowInputRectangle(&this, prcWndInputRect);

	public HRESULT AddStylusSyncPlugin(uint32 iIndex, IStylusSyncPlugin* piPlugin) mut => VT.[Friend]AddStylusSyncPlugin(&this, iIndex, piPlugin);

	public HRESULT RemoveStylusSyncPlugin(uint32 iIndex, IStylusSyncPlugin** ppiPlugin) mut => VT.[Friend]RemoveStylusSyncPlugin(&this, iIndex, ppiPlugin);

	public HRESULT RemoveAllStylusSyncPlugins() mut => VT.[Friend]RemoveAllStylusSyncPlugins(&this);

	public HRESULT GetStylusSyncPlugin(uint32 iIndex, IStylusSyncPlugin** ppiPlugin) mut => VT.[Friend]GetStylusSyncPlugin(&this, iIndex, ppiPlugin);

	public HRESULT GetStylusSyncPluginCount(uint32* pcPlugins) mut => VT.[Friend]GetStylusSyncPluginCount(&this, pcPlugins);

	public HRESULT AddStylusAsyncPlugin(uint32 iIndex, IStylusAsyncPlugin* piPlugin) mut => VT.[Friend]AddStylusAsyncPlugin(&this, iIndex, piPlugin);

	public HRESULT RemoveStylusAsyncPlugin(uint32 iIndex, IStylusAsyncPlugin** ppiPlugin) mut => VT.[Friend]RemoveStylusAsyncPlugin(&this, iIndex, ppiPlugin);

	public HRESULT RemoveAllStylusAsyncPlugins() mut => VT.[Friend]RemoveAllStylusAsyncPlugins(&this);

	public HRESULT GetStylusAsyncPlugin(uint32 iIndex, IStylusAsyncPlugin** ppiPlugin) mut => VT.[Friend]GetStylusAsyncPlugin(&this, iIndex, ppiPlugin);

	public HRESULT GetStylusAsyncPluginCount(uint32* pcPlugins) mut => VT.[Friend]GetStylusAsyncPluginCount(&this, pcPlugins);

	public HRESULT get_ChildRealTimeStylusPlugin(IRealTimeStylus** ppiRTS) mut => VT.[Friend]get_ChildRealTimeStylusPlugin(&this, ppiRTS);

	public HRESULT putref_ChildRealTimeStylusPlugin(IRealTimeStylus* piRTS) mut => VT.[Friend]putref_ChildRealTimeStylusPlugin(&this, piRTS);

	public HRESULT AddCustomStylusDataToQueue(StylusQueue sq, in Guid pGuidId, uint32 cbData, uint8* pbData) mut => VT.[Friend]AddCustomStylusDataToQueue(&this, sq, pGuidId, cbData, pbData);

	public HRESULT ClearStylusQueues() mut => VT.[Friend]ClearStylusQueues(&this);

	public HRESULT SetAllTabletsMode(BOOL fUseMouseForInput) mut => VT.[Friend]SetAllTabletsMode(&this, fUseMouseForInput);

	public HRESULT SetSingleTabletMode(IInkTablet* piTablet) mut => VT.[Friend]SetSingleTabletMode(&this, piTablet);

	public HRESULT GetTablet(IInkTablet** ppiSingleTablet) mut => VT.[Friend]GetTablet(&this, ppiSingleTablet);

	public HRESULT GetTabletContextIdFromTablet(IInkTablet* piTablet, uint32* ptcid) mut => VT.[Friend]GetTabletContextIdFromTablet(&this, piTablet, ptcid);

	public HRESULT GetTabletFromTabletContextId(uint32 tcid, IInkTablet** ppiTablet) mut => VT.[Friend]GetTabletFromTabletContextId(&this, tcid, ppiTablet);

	public HRESULT GetAllTabletContextIds(uint32* pcTcidCount, uint32** ppTcids) mut => VT.[Friend]GetAllTabletContextIds(&this, pcTcidCount, ppTcids);

	public HRESULT GetStyluses(IInkCursors** ppiInkCursors) mut => VT.[Friend]GetStyluses(&this, ppiInkCursors);

	public HRESULT GetStylusForId(uint32 sid, IInkCursor** ppiInkCursor) mut => VT.[Friend]GetStylusForId(&this, sid, ppiInkCursor);

	public HRESULT SetDesiredPacketDescription(uint32 cProperties, Guid* pPropertyGuids) mut => VT.[Friend]SetDesiredPacketDescription(&this, cProperties, pPropertyGuids);

	public HRESULT GetDesiredPacketDescription(uint32* pcProperties, Guid** ppPropertyGuids) mut => VT.[Friend]GetDesiredPacketDescription(&this, pcProperties, ppPropertyGuids);

	public HRESULT GetPacketDescriptionData(uint32 tcid, float* pfInkToDeviceScaleX, float* pfInkToDeviceScaleY, uint32* pcPacketProperties, PACKET_PROPERTY** ppPacketProperties) mut => VT.[Friend]GetPacketDescriptionData(&this, tcid, pfInkToDeviceScaleX, pfInkToDeviceScaleY, pcPacketProperties, ppPacketProperties);
}

[CRepr]struct IRealTimeStylus2 : IUnknown
{
	public new const Guid IID = .(0xb5f2a6cd, 0x3179, 0x4a3e, 0xb9, 0xc4, 0xbb, 0x58, 0x65, 0x96, 0x2b, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnable) get_FlicksEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) put_FlicksEnabled;
	}


	public HRESULT get_FlicksEnabled(BOOL* pfEnable) mut => VT.[Friend]get_FlicksEnabled(&this, pfEnable);

	public HRESULT put_FlicksEnabled(BOOL fEnable) mut => VT.[Friend]put_FlicksEnabled(&this, fEnable);
}

[CRepr]struct IRealTimeStylus3 : IUnknown
{
	public new const Guid IID = .(0xd70230a3, 0x6986, 0x4051, 0xb5, 0x7a, 0x1c, 0xf6, 0x9f, 0x4d, 0x9d, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnable) get_MultiTouchEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) put_MultiTouchEnabled;
	}


	public HRESULT get_MultiTouchEnabled(BOOL* pfEnable) mut => VT.[Friend]get_MultiTouchEnabled(&this, pfEnable);

	public HRESULT put_MultiTouchEnabled(BOOL fEnable) mut => VT.[Friend]put_MultiTouchEnabled(&this, fEnable);
}

[CRepr]struct IRealTimeStylusSynchronization : IUnknown
{
	public new const Guid IID = .(0xaa87eab8, 0xab4a, 0x4cea, 0xb5, 0xcb, 0x46, 0xd8, 0x4c, 0x6a, 0x25, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RealTimeStylusLockType lock) AcquireLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RealTimeStylusLockType lock) ReleaseLock;
	}


	public HRESULT AcquireLock(RealTimeStylusLockType lock) mut => VT.[Friend]AcquireLock(&this, lock);

	public HRESULT ReleaseLock(RealTimeStylusLockType lock) mut => VT.[Friend]ReleaseLock(&this, lock);
}

[CRepr]struct IStrokeBuilder : IUnknown
{
	public new const Guid IID = .(0xa5fd4e2d, 0xc44b, 0x4092, 0x91, 0x77, 0x26, 0x09, 0x05, 0xeb, 0x67, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPktBuffLength, int32* pPackets, uint32 cPacketProperties, PACKET_PROPERTY* pPacketProperties, float fInkToDeviceScaleX, float fInkToDeviceScaleY, IInkStrokeDisp** ppIInkStroke) CreateStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tcid, uint32 sid, int32* pPacket, uint32 cPacketProperties, PACKET_PROPERTY* pPacketProperties, float fInkToDeviceScaleX, float fInkToDeviceScaleY, IInkStrokeDisp** ppIInkStroke) BeginStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tcid, uint32 sid, uint32 cPktBuffLength, int32* pPackets) AppendPackets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tcid, uint32 sid, IInkStrokeDisp** ppIInkStroke, RECT* pDirtyRect) EndStroke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp** ppiInkObj) get_Ink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDisp* piInkObj) putref_Ink;
	}


	public HRESULT CreateStroke(uint32 cPktBuffLength, int32* pPackets, uint32 cPacketProperties, PACKET_PROPERTY* pPacketProperties, float fInkToDeviceScaleX, float fInkToDeviceScaleY, IInkStrokeDisp** ppIInkStroke) mut => VT.[Friend]CreateStroke(&this, cPktBuffLength, pPackets, cPacketProperties, pPacketProperties, fInkToDeviceScaleX, fInkToDeviceScaleY, ppIInkStroke);

	public HRESULT BeginStroke(uint32 tcid, uint32 sid, int32* pPacket, uint32 cPacketProperties, PACKET_PROPERTY* pPacketProperties, float fInkToDeviceScaleX, float fInkToDeviceScaleY, IInkStrokeDisp** ppIInkStroke) mut => VT.[Friend]BeginStroke(&this, tcid, sid, pPacket, cPacketProperties, pPacketProperties, fInkToDeviceScaleX, fInkToDeviceScaleY, ppIInkStroke);

	public HRESULT AppendPackets(uint32 tcid, uint32 sid, uint32 cPktBuffLength, int32* pPackets) mut => VT.[Friend]AppendPackets(&this, tcid, sid, cPktBuffLength, pPackets);

	public HRESULT EndStroke(uint32 tcid, uint32 sid, IInkStrokeDisp** ppIInkStroke, RECT* pDirtyRect) mut => VT.[Friend]EndStroke(&this, tcid, sid, ppIInkStroke, pDirtyRect);

	public HRESULT get_Ink(IInkDisp** ppiInkObj) mut => VT.[Friend]get_Ink(&this, ppiInkObj);

	public HRESULT putref_Ink(IInkDisp* piInkObj) mut => VT.[Friend]putref_Ink(&this, piInkObj);
}

[CRepr]struct IStylusPlugin : IUnknown
{
	public new const Guid IID = .(0xa81436d8, 0x4757, 0x4fd1, 0xa1, 0x85, 0x13, 0x3f, 0x97, 0xc6, 0xc5, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 cTcidCount, uint32* pTcids) RealTimeStylusEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 cTcidCount, uint32* pTcids) RealTimeStylusDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 tcid, uint32 sid) StylusInRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 tcid, uint32 sid) StylusOutOfRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPropCountPerPkt, int32* pPacket, int32** ppInOutPkt) StylusDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPropCountPerPkt, int32* pPacket, int32** ppInOutPkt) StylusUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 sid, in Guid pGuidStylusButton, POINT* pStylusPos) StylusButtonDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 sid, in Guid pGuidStylusButton, POINT* pStylusPos) StylusButtonUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPktCount, uint32 cPktBuffLength, int32* pPackets, uint32* pcInOutPkts, int32** ppInOutPkts) InAirPackets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPktCount, uint32 cPktBuffLength, int32* pPackets, uint32* pcInOutPkts, int32** ppInOutPkts) Packets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, in Guid pGuidId, uint32 cbData, uint8* pbData) CustomStylusDataAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, uint32 tcid, uint32 sid, uint16 event, SYSTEM_EVENT_DATA eventdata) SystemEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, IInkTablet* piTablet) TabletAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, int32 iTabletIndex) TabletRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc, IStylusPlugin* piPlugin, RealTimeStylusDataInterest dataInterest, HRESULT hrErrorCode, int* lptrKey) Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRealTimeStylus* piRtsSrc) UpdateMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RealTimeStylusDataInterest* pDataInterest) DataInterest;
	}


	public HRESULT RealTimeStylusEnabled(IRealTimeStylus* piRtsSrc, uint32 cTcidCount, uint32* pTcids) mut => VT.[Friend]RealTimeStylusEnabled(&this, piRtsSrc, cTcidCount, pTcids);

	public HRESULT RealTimeStylusDisabled(IRealTimeStylus* piRtsSrc, uint32 cTcidCount, uint32* pTcids) mut => VT.[Friend]RealTimeStylusDisabled(&this, piRtsSrc, cTcidCount, pTcids);

	public HRESULT StylusInRange(IRealTimeStylus* piRtsSrc, uint32 tcid, uint32 sid) mut => VT.[Friend]StylusInRange(&this, piRtsSrc, tcid, sid);

	public HRESULT StylusOutOfRange(IRealTimeStylus* piRtsSrc, uint32 tcid, uint32 sid) mut => VT.[Friend]StylusOutOfRange(&this, piRtsSrc, tcid, sid);

	public HRESULT StylusDown(IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPropCountPerPkt, int32* pPacket, int32** ppInOutPkt) mut => VT.[Friend]StylusDown(&this, piRtsSrc, pStylusInfo, cPropCountPerPkt, pPacket, ppInOutPkt);

	public HRESULT StylusUp(IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPropCountPerPkt, int32* pPacket, int32** ppInOutPkt) mut => VT.[Friend]StylusUp(&this, piRtsSrc, pStylusInfo, cPropCountPerPkt, pPacket, ppInOutPkt);

	public HRESULT StylusButtonDown(IRealTimeStylus* piRtsSrc, uint32 sid, in Guid pGuidStylusButton, POINT* pStylusPos) mut => VT.[Friend]StylusButtonDown(&this, piRtsSrc, sid, pGuidStylusButton, pStylusPos);

	public HRESULT StylusButtonUp(IRealTimeStylus* piRtsSrc, uint32 sid, in Guid pGuidStylusButton, POINT* pStylusPos) mut => VT.[Friend]StylusButtonUp(&this, piRtsSrc, sid, pGuidStylusButton, pStylusPos);

	public HRESULT InAirPackets(IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPktCount, uint32 cPktBuffLength, int32* pPackets, uint32* pcInOutPkts, int32** ppInOutPkts) mut => VT.[Friend]InAirPackets(&this, piRtsSrc, pStylusInfo, cPktCount, cPktBuffLength, pPackets, pcInOutPkts, ppInOutPkts);

	public HRESULT Packets(IRealTimeStylus* piRtsSrc, StylusInfo* pStylusInfo, uint32 cPktCount, uint32 cPktBuffLength, int32* pPackets, uint32* pcInOutPkts, int32** ppInOutPkts) mut => VT.[Friend]Packets(&this, piRtsSrc, pStylusInfo, cPktCount, cPktBuffLength, pPackets, pcInOutPkts, ppInOutPkts);

	public HRESULT CustomStylusDataAdded(IRealTimeStylus* piRtsSrc, in Guid pGuidId, uint32 cbData, uint8* pbData) mut => VT.[Friend]CustomStylusDataAdded(&this, piRtsSrc, pGuidId, cbData, pbData);

	public HRESULT SystemEvent(IRealTimeStylus* piRtsSrc, uint32 tcid, uint32 sid, uint16 event, SYSTEM_EVENT_DATA eventdata) mut => VT.[Friend]SystemEvent(&this, piRtsSrc, tcid, sid, event, eventdata);

	public HRESULT TabletAdded(IRealTimeStylus* piRtsSrc, IInkTablet* piTablet) mut => VT.[Friend]TabletAdded(&this, piRtsSrc, piTablet);

	public HRESULT TabletRemoved(IRealTimeStylus* piRtsSrc, int32 iTabletIndex) mut => VT.[Friend]TabletRemoved(&this, piRtsSrc, iTabletIndex);

	public HRESULT Error(IRealTimeStylus* piRtsSrc, IStylusPlugin* piPlugin, RealTimeStylusDataInterest dataInterest, HRESULT hrErrorCode, int* lptrKey) mut => VT.[Friend]Error(&this, piRtsSrc, piPlugin, dataInterest, hrErrorCode, lptrKey);

	public HRESULT UpdateMapping(IRealTimeStylus* piRtsSrc) mut => VT.[Friend]UpdateMapping(&this, piRtsSrc);

	public HRESULT DataInterest(RealTimeStylusDataInterest* pDataInterest) mut => VT.[Friend]DataInterest(&this, pDataInterest);
}

[CRepr]struct IStylusSyncPlugin : IStylusPlugin
{
	public new const Guid IID = .(0xa157b174, 0x482f, 0x4d71, 0xa3, 0xf6, 0x3a, 0x41, 0xdd, 0xd1, 0x1b, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IStylusPlugin.VTable
	{
	}

}

[CRepr]struct IStylusAsyncPlugin : IStylusPlugin
{
	public new const Guid IID = .(0xa7cca85a, 0x31bc, 0x4cd2, 0xaa, 0xdc, 0x32, 0x89, 0xa3, 0xaf, 0x11, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IStylusPlugin.VTable
	{
	}

}

[CRepr]struct IDynamicRenderer : IUnknown
{
	public new const Guid IID = .(0xa079468e, 0x7165, 0x46f9, 0xb7, 0xaf, 0x98, 0xad, 0x01, 0xa9, 0x30, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* bEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bEnabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR* hwnd) get_HWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hwnd) put_HWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcClipRect) get_ClipRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcClipRect) put_ClipRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR* phClipRgn) get_ClipRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hClipRgn) put_ClipRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes** ppiDA) get_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkDrawingAttributes* piDA) putref_DrawingAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCacheData) get_DataCacheEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fCacheData) put_DataCacheEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 strokeId) ReleaseCachedData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hDC) Draw;
	}


	public HRESULT get_Enabled(BOOL* bEnabled) mut => VT.[Friend]get_Enabled(&this, bEnabled);

	public HRESULT put_Enabled(BOOL bEnabled) mut => VT.[Friend]put_Enabled(&this, bEnabled);

	public HRESULT get_HWND(HANDLE_PTR* hwnd) mut => VT.[Friend]get_HWND(&this, hwnd);

	public HRESULT put_HWND(HANDLE_PTR hwnd) mut => VT.[Friend]put_HWND(&this, hwnd);

	public HRESULT get_ClipRectangle(RECT* prcClipRect) mut => VT.[Friend]get_ClipRectangle(&this, prcClipRect);

	public HRESULT put_ClipRectangle(RECT* prcClipRect) mut => VT.[Friend]put_ClipRectangle(&this, prcClipRect);

	public HRESULT get_ClipRegion(HANDLE_PTR* phClipRgn) mut => VT.[Friend]get_ClipRegion(&this, phClipRgn);

	public HRESULT put_ClipRegion(HANDLE_PTR hClipRgn) mut => VT.[Friend]put_ClipRegion(&this, hClipRgn);

	public HRESULT get_DrawingAttributes(IInkDrawingAttributes** ppiDA) mut => VT.[Friend]get_DrawingAttributes(&this, ppiDA);

	public HRESULT putref_DrawingAttributes(IInkDrawingAttributes* piDA) mut => VT.[Friend]putref_DrawingAttributes(&this, piDA);

	public HRESULT get_DataCacheEnabled(BOOL* pfCacheData) mut => VT.[Friend]get_DataCacheEnabled(&this, pfCacheData);

	public HRESULT put_DataCacheEnabled(BOOL fCacheData) mut => VT.[Friend]put_DataCacheEnabled(&this, fCacheData);

	public HRESULT ReleaseCachedData(uint32 strokeId) mut => VT.[Friend]ReleaseCachedData(&this, strokeId);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Draw(HANDLE_PTR hDC) mut => VT.[Friend]Draw(&this, hDC);
}

[CRepr]struct IGestureRecognizer : IUnknown
{
	public new const Guid IID = .(0xae9ef86b, 0x7054, 0x45e3, 0xae, 0x22, 0x31, 0x74, 0xdc, 0x88, 0x11, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcStrokes) get_MaxStrokeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cStrokes) put_MaxStrokeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cGestures, int32* pGestures) EnableGestures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT get_Enabled(BOOL* pfEnabled) mut => VT.[Friend]get_Enabled(&this, pfEnabled);

	public HRESULT put_Enabled(BOOL fEnabled) mut => VT.[Friend]put_Enabled(&this, fEnabled);

	public HRESULT get_MaxStrokeCount(int32* pcStrokes) mut => VT.[Friend]get_MaxStrokeCount(&this, pcStrokes);

	public HRESULT put_MaxStrokeCount(int32 cStrokes) mut => VT.[Friend]put_MaxStrokeCount(&this, cStrokes);

	public HRESULT EnableGestures(uint32 cGestures, int32* pGestures) mut => VT.[Friend]EnableGestures(&this, cGestures, pGestures);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct ITipAutoCompleteProvider : IUnknown
{
	public new const Guid IID = .(0x7c6cf46d, 0x8404, 0x46b9, 0xad, 0x33, 0xf5, 0xb6, 0x03, 0x6d, 0x40, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPendingText) UpdatePendingText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) Show;
	}


	public HRESULT UpdatePendingText(BSTR bstrPendingText) mut => VT.[Friend]UpdatePendingText(&this, bstrPendingText);

	public HRESULT Show(BOOL fShow) mut => VT.[Friend]Show(&this, fShow);
}

[CRepr]struct ITipAutoCompleteClient : IUnknown
{
	public new const Guid IID = .(0x5e078e03, 0x8265, 0x4bbe, 0x94, 0x87, 0xd2, 0x42, 0xed, 0xbe, 0xf9, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndField, ITipAutoCompleteProvider* pIProvider) AdviseProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndField, ITipAutoCompleteProvider* pIProvider) UnadviseProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UserSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcACList, RECT* prcField, RECT* prcModifiedACList, BOOL* pfShownAboveTip) PreferredRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndList, BOOL* pfAllowShowing) RequestShowUI;
	}


	public HRESULT AdviseProvider(HWND hWndField, ITipAutoCompleteProvider* pIProvider) mut => VT.[Friend]AdviseProvider(&this, hWndField, pIProvider);

	public HRESULT UnadviseProvider(HWND hWndField, ITipAutoCompleteProvider* pIProvider) mut => VT.[Friend]UnadviseProvider(&this, hWndField, pIProvider);

	public HRESULT UserSelection() mut => VT.[Friend]UserSelection(&this);

	public HRESULT PreferredRects(RECT* prcACList, RECT* prcField, RECT* prcModifiedACList, BOOL* pfShownAboveTip) mut => VT.[Friend]PreferredRects(&this, prcACList, prcField, prcModifiedACList, pfShownAboveTip);

	public HRESULT RequestShowUI(HWND hWndList, BOOL* pfAllowShowing) mut => VT.[Friend]RequestShowUI(&this, hWndList, pfAllowShowing);
}

#endregion

#region Functions
public static
{
	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateRecognizer(Guid* pCLSID, HRECOGNIZER* phrec);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DestroyRecognizer(HRECOGNIZER hrec);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRecoAttributes(HRECOGNIZER hrec, RECO_ATTRS* pRecoAttrs);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateContext(HRECOGNIZER hrec, HRECOCONTEXT* phrc);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DestroyContext(HRECOCONTEXT hrc);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetResultPropertyList(HRECOGNIZER hrec, uint32* pPropertyCount, Guid* pPropertyGuid);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetUnicodeRanges(HRECOGNIZER hrec, uint32* pcRanges, CHARACTER_RANGE* pcr);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddStroke(HRECOCONTEXT hrc, PACKET_DESCRIPTION* pPacketDesc, uint32 cbPacket, uint8* pPacket, XFORM* pXForm);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetBestResultString(HRECOCONTEXT hrc, uint32* pcSize, char16* pwcBestResult);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetGuide(HRECOCONTEXT hrc, RECO_GUIDE* pGuide, uint32 iIndex);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AdviseInkChange(HRECOCONTEXT hrc, BOOL bNewStroke);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EndInkInput(HRECOCONTEXT hrc);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT Process(HRECOCONTEXT hrc, BOOL* pbPartialProcessing);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetFactoid(HRECOCONTEXT hrc, uint32 cwcFactoid, PWSTR pwcFactoid);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetFlags(HRECOCONTEXT hrc, uint32 dwFlags);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetLatticePtr(HRECOCONTEXT hrc, RECO_LATTICE** ppLattice);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetTextContext(HRECOCONTEXT hrc, uint32 cwcBefore, char16* pwcBefore, uint32 cwcAfter, char16* pwcAfter);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetEnabledUnicodeRanges(HRECOCONTEXT hrc, uint32 cRanges, CHARACTER_RANGE* pcr);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsStringSupported(HRECOCONTEXT hrc, uint32 wcString, PWSTR pwcString);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetWordList(HRECOCONTEXT hrc, HRECOWORDLIST hwl);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRightSeparator(HRECOCONTEXT hrc, uint32* pcSize, char16* pwcRightSeparator);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetLeftSeparator(HRECOCONTEXT hrc, uint32* pcSize, char16* pwcLeftSeparator);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DestroyWordList(HRECOWORDLIST hwl);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddWordsToWordList(HRECOWORDLIST hwl, PWSTR pwcWords);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MakeWordList(HRECOGNIZER hrec, PWSTR pBuffer, HRECOWORDLIST* phwl);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetAllRecognizers(Guid** recognizerClsids, uint32* count);

	[Import("inkobjcore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadCachedAttributes(Guid clsid, RECO_ATTRS* pRecoAttributes);

}
#endregion
