using Win32.Foundation;
using Win32.System.Com;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.UI.Accessibility;

#region Constants
public static
{
	public const Guid LIBID_Accessibility = .(0x1ea4dbf0, 0x3c3b, 0x11cf, 0x81, 0x0c, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);
	public const Guid CLSID_AccPropServices = .(0xb5f8350b, 0x0548, 0x48b1, 0xa6, 0xee, 0x88, 0xbd, 0x00, 0xb4, 0xa5, 0xe7);
	public const Guid IIS_IsOleaccProxy = .(0x902697fa, 0x80e4, 0x4560, 0x80, 0x2a, 0xa1, 0x3f, 0x22, 0xa6, 0x47, 0x09);
	public const Guid IIS_ControlAccessible = .(0x38c682a6, 0x9731, 0x43f2, 0x9f, 0xae, 0xe9, 0x01, 0xe6, 0x41, 0xb1, 0x01);
	public const uint32 ANRUS_PRIORITY_AUDIO_DYNAMIC_DUCK = 16;
	public const int32 MSAA_MENU_SIG = -1441927155;
	public const Guid PROPID_ACC_NAME = .(0x608d3df8, 0x8128, 0x4aa7, 0xa4, 0x28, 0xf5, 0x5e, 0x49, 0x26, 0x72, 0x91);
	public const Guid PROPID_ACC_VALUE = .(0x123fe443, 0x211a, 0x4615, 0x95, 0x27, 0xc4, 0x5a, 0x7e, 0x93, 0x71, 0x7a);
	public const Guid PROPID_ACC_DESCRIPTION = .(0x4d48dfe4, 0xbd3f, 0x491f, 0xa6, 0x48, 0x49, 0x2d, 0x6f, 0x20, 0xc5, 0x88);
	public const Guid PROPID_ACC_ROLE = .(0xcb905ff2, 0x7bd1, 0x4c05, 0xb3, 0xc8, 0xe6, 0xc2, 0x41, 0x36, 0x4d, 0x70);
	public const Guid PROPID_ACC_STATE = .(0xa8d4d5b0, 0x0a21, 0x42d0, 0xa5, 0xc0, 0x51, 0x4e, 0x98, 0x4f, 0x45, 0x7b);
	public const Guid PROPID_ACC_HELP = .(0xc831e11f, 0x44db, 0x4a99, 0x97, 0x68, 0xcb, 0x8f, 0x97, 0x8b, 0x72, 0x31);
	public const Guid PROPID_ACC_KEYBOARDSHORTCUT = .(0x7d9bceee, 0x7d1e, 0x4979, 0x93, 0x82, 0x51, 0x80, 0xf4, 0x17, 0x2c, 0x34);
	public const Guid PROPID_ACC_DEFAULTACTION = .(0x180c072b, 0xc27f, 0x43c7, 0x99, 0x22, 0xf6, 0x35, 0x62, 0xa4, 0x63, 0x2b);
	public const Guid PROPID_ACC_HELPTOPIC = .(0x787d1379, 0x8ede, 0x440b, 0x8a, 0xec, 0x11, 0xf7, 0xbf, 0x90, 0x30, 0xb3);
	public const Guid PROPID_ACC_FOCUS = .(0x6eb335df, 0x1c29, 0x4127, 0xb1, 0x2c, 0xde, 0xe9, 0xfd, 0x15, 0x7f, 0x2b);
	public const Guid PROPID_ACC_SELECTION = .(0xb99d073c, 0xd731, 0x405b, 0x90, 0x61, 0xd9, 0x5e, 0x8f, 0x84, 0x29, 0x84);
	public const Guid PROPID_ACC_PARENT = .(0x474c22b6, 0xffc2, 0x467a, 0xb1, 0xb5, 0xe9, 0x58, 0xb4, 0x65, 0x73, 0x30);
	public const Guid PROPID_ACC_NAV_UP = .(0x016e1a2b, 0x1a4e, 0x4767, 0x86, 0x12, 0x33, 0x86, 0xf6, 0x69, 0x35, 0xec);
	public const Guid PROPID_ACC_NAV_DOWN = .(0x031670ed, 0x3cdf, 0x48d2, 0x96, 0x13, 0x13, 0x8f, 0x2d, 0xd8, 0xa6, 0x68);
	public const Guid PROPID_ACC_NAV_LEFT = .(0x228086cb, 0x82f1, 0x4a39, 0x87, 0x05, 0xdc, 0xdc, 0x0f, 0xff, 0x92, 0xf5);
	public const Guid PROPID_ACC_NAV_RIGHT = .(0xcd211d9f, 0xe1cb, 0x4fe5, 0xa7, 0x7c, 0x92, 0x0b, 0x88, 0x4d, 0x09, 0x5b);
	public const Guid PROPID_ACC_NAV_PREV = .(0x776d3891, 0xc73b, 0x4480, 0xb3, 0xf6, 0x07, 0x6a, 0x16, 0xa1, 0x5a, 0xf6);
	public const Guid PROPID_ACC_NAV_NEXT = .(0x1cdc5455, 0x8cd9, 0x4c92, 0xa3, 0x71, 0x39, 0x39, 0xa2, 0xfe, 0x3e, 0xee);
	public const Guid PROPID_ACC_NAV_FIRSTCHILD = .(0xcfd02558, 0x557b, 0x4c67, 0x84, 0xf9, 0x2a, 0x09, 0xfc, 0xe4, 0x07, 0x49);
	public const Guid PROPID_ACC_NAV_LASTCHILD = .(0x302ecaa5, 0x48d5, 0x4f8d, 0xb6, 0x71, 0x1a, 0x8d, 0x20, 0xa7, 0x78, 0x32);
	public const Guid PROPID_ACC_ROLEMAP = .(0xf79acda2, 0x140d, 0x4fe6, 0x89, 0x14, 0x20, 0x84, 0x76, 0x32, 0x82, 0x69);
	public const Guid PROPID_ACC_VALUEMAP = .(0xda1c3d79, 0xfc5c, 0x420e, 0xb3, 0x99, 0x9d, 0x15, 0x33, 0x54, 0x9e, 0x75);
	public const Guid PROPID_ACC_STATEMAP = .(0x43946c5e, 0x0ac0, 0x4042, 0xb5, 0x25, 0x07, 0xbb, 0xdb, 0xe1, 0x7f, 0xa7);
	public const Guid PROPID_ACC_DESCRIPTIONMAP = .(0x1ff1435f, 0x8a14, 0x477b, 0xb2, 0x26, 0xa0, 0xab, 0xe2, 0x79, 0x97, 0x5d);
	public const Guid PROPID_ACC_DODEFAULTACTION = .(0x1ba09523, 0x2e3b, 0x49a6, 0xa0, 0x59, 0x59, 0x68, 0x2a, 0x3c, 0x48, 0xfd);
	public const int32 DISPID_ACC_PARENT = -5000;
	public const int32 DISPID_ACC_CHILDCOUNT = -5001;
	public const int32 DISPID_ACC_CHILD = -5002;
	public const int32 DISPID_ACC_NAME = -5003;
	public const int32 DISPID_ACC_VALUE = -5004;
	public const int32 DISPID_ACC_DESCRIPTION = -5005;
	public const int32 DISPID_ACC_ROLE = -5006;
	public const int32 DISPID_ACC_STATE = -5007;
	public const int32 DISPID_ACC_HELP = -5008;
	public const int32 DISPID_ACC_HELPTOPIC = -5009;
	public const int32 DISPID_ACC_KEYBOARDSHORTCUT = -5010;
	public const int32 DISPID_ACC_FOCUS = -5011;
	public const int32 DISPID_ACC_SELECTION = -5012;
	public const int32 DISPID_ACC_DEFAULTACTION = -5013;
	public const int32 DISPID_ACC_SELECT = -5014;
	public const int32 DISPID_ACC_LOCATION = -5015;
	public const int32 DISPID_ACC_NAVIGATE = -5016;
	public const int32 DISPID_ACC_HITTEST = -5017;
	public const int32 DISPID_ACC_DODEFAULTACTION = -5018;
	public const uint32 NAVDIR_MIN = 0;
	public const uint32 NAVDIR_UP = 1;
	public const uint32 NAVDIR_DOWN = 2;
	public const uint32 NAVDIR_LEFT = 3;
	public const uint32 NAVDIR_RIGHT = 4;
	public const uint32 NAVDIR_NEXT = 5;
	public const uint32 NAVDIR_PREVIOUS = 6;
	public const uint32 NAVDIR_FIRSTCHILD = 7;
	public const uint32 NAVDIR_LASTCHILD = 8;
	public const uint32 NAVDIR_MAX = 9;
	public const uint32 SELFLAG_NONE = 0;
	public const uint32 SELFLAG_TAKEFOCUS = 1;
	public const uint32 SELFLAG_TAKESELECTION = 2;
	public const uint32 SELFLAG_EXTENDSELECTION = 4;
	public const uint32 SELFLAG_ADDSELECTION = 8;
	public const uint32 SELFLAG_REMOVESELECTION = 16;
	public const uint32 SELFLAG_VALID = 31;
	public const uint32 STATE_SYSTEM_NORMAL = 0;
	public const uint32 STATE_SYSTEM_HASPOPUP = 1073741824;
	public const uint32 ROLE_SYSTEM_TITLEBAR = 1;
	public const uint32 ROLE_SYSTEM_MENUBAR = 2;
	public const uint32 ROLE_SYSTEM_SCROLLBAR = 3;
	public const uint32 ROLE_SYSTEM_GRIP = 4;
	public const uint32 ROLE_SYSTEM_SOUND = 5;
	public const uint32 ROLE_SYSTEM_CURSOR = 6;
	public const uint32 ROLE_SYSTEM_CARET = 7;
	public const uint32 ROLE_SYSTEM_ALERT = 8;
	public const uint32 ROLE_SYSTEM_WINDOW = 9;
	public const uint32 ROLE_SYSTEM_CLIENT = 10;
	public const uint32 ROLE_SYSTEM_MENUPOPUP = 11;
	public const uint32 ROLE_SYSTEM_MENUITEM = 12;
	public const uint32 ROLE_SYSTEM_TOOLTIP = 13;
	public const uint32 ROLE_SYSTEM_APPLICATION = 14;
	public const uint32 ROLE_SYSTEM_DOCUMENT = 15;
	public const uint32 ROLE_SYSTEM_PANE = 16;
	public const uint32 ROLE_SYSTEM_CHART = 17;
	public const uint32 ROLE_SYSTEM_DIALOG = 18;
	public const uint32 ROLE_SYSTEM_BORDER = 19;
	public const uint32 ROLE_SYSTEM_GROUPING = 20;
	public const uint32 ROLE_SYSTEM_SEPARATOR = 21;
	public const uint32 ROLE_SYSTEM_TOOLBAR = 22;
	public const uint32 ROLE_SYSTEM_STATUSBAR = 23;
	public const uint32 ROLE_SYSTEM_TABLE = 24;
	public const uint32 ROLE_SYSTEM_COLUMNHEADER = 25;
	public const uint32 ROLE_SYSTEM_ROWHEADER = 26;
	public const uint32 ROLE_SYSTEM_COLUMN = 27;
	public const uint32 ROLE_SYSTEM_ROW = 28;
	public const uint32 ROLE_SYSTEM_CELL = 29;
	public const uint32 ROLE_SYSTEM_LINK = 30;
	public const uint32 ROLE_SYSTEM_HELPBALLOON = 31;
	public const uint32 ROLE_SYSTEM_CHARACTER = 32;
	public const uint32 ROLE_SYSTEM_LIST = 33;
	public const uint32 ROLE_SYSTEM_LISTITEM = 34;
	public const uint32 ROLE_SYSTEM_OUTLINE = 35;
	public const uint32 ROLE_SYSTEM_OUTLINEITEM = 36;
	public const uint32 ROLE_SYSTEM_PAGETAB = 37;
	public const uint32 ROLE_SYSTEM_PROPERTYPAGE = 38;
	public const uint32 ROLE_SYSTEM_INDICATOR = 39;
	public const uint32 ROLE_SYSTEM_GRAPHIC = 40;
	public const uint32 ROLE_SYSTEM_STATICTEXT = 41;
	public const uint32 ROLE_SYSTEM_TEXT = 42;
	public const uint32 ROLE_SYSTEM_PUSHBUTTON = 43;
	public const uint32 ROLE_SYSTEM_CHECKBUTTON = 44;
	public const uint32 ROLE_SYSTEM_RADIOBUTTON = 45;
	public const uint32 ROLE_SYSTEM_COMBOBOX = 46;
	public const uint32 ROLE_SYSTEM_DROPLIST = 47;
	public const uint32 ROLE_SYSTEM_PROGRESSBAR = 48;
	public const uint32 ROLE_SYSTEM_DIAL = 49;
	public const uint32 ROLE_SYSTEM_HOTKEYFIELD = 50;
	public const uint32 ROLE_SYSTEM_SLIDER = 51;
	public const uint32 ROLE_SYSTEM_SPINBUTTON = 52;
	public const uint32 ROLE_SYSTEM_DIAGRAM = 53;
	public const uint32 ROLE_SYSTEM_ANIMATION = 54;
	public const uint32 ROLE_SYSTEM_EQUATION = 55;
	public const uint32 ROLE_SYSTEM_BUTTONDROPDOWN = 56;
	public const uint32 ROLE_SYSTEM_BUTTONMENU = 57;
	public const uint32 ROLE_SYSTEM_BUTTONDROPDOWNGRID = 58;
	public const uint32 ROLE_SYSTEM_WHITESPACE = 59;
	public const uint32 ROLE_SYSTEM_PAGETABLIST = 60;
	public const uint32 ROLE_SYSTEM_CLOCK = 61;
	public const uint32 ROLE_SYSTEM_SPLITBUTTON = 62;
	public const uint32 ROLE_SYSTEM_IPADDRESS = 63;
	public const uint32 ROLE_SYSTEM_OUTLINEBUTTON = 64;
	public const uint32 UIA_E_ELEMENTNOTENABLED = 2147746304;
	public const uint32 UIA_E_ELEMENTNOTAVAILABLE = 2147746305;
	public const uint32 UIA_E_NOCLICKABLEPOINT = 2147746306;
	public const uint32 UIA_E_PROXYASSEMBLYNOTLOADED = 2147746307;
	public const uint32 UIA_E_NOTSUPPORTED = 2147746308;
	public const uint32 UIA_E_INVALIDOPERATION = 2148734217;
	public const uint32 UIA_E_TIMEOUT = 2148734213;
	public const uint32 UiaAppendRuntimeId = 3;
	public const int32 UiaRootObjectId = -25;
	public const Guid RuntimeId_Property_GUID = .(0xa39eebfa, 0x7fba, 0x4c89, 0xb4, 0xd4, 0xb9, 0x9e, 0x2d, 0xe7, 0xd1, 0x60);
	public const Guid BoundingRectangle_Property_GUID = .(0x7bbfe8b2, 0x3bfc, 0x48dd, 0xb7, 0x29, 0xc7, 0x94, 0xb8, 0x46, 0xe9, 0xa1);
	public const Guid ProcessId_Property_GUID = .(0x40499998, 0x9c31, 0x4245, 0xa4, 0x03, 0x87, 0x32, 0x0e, 0x59, 0xea, 0xf6);
	public const Guid ControlType_Property_GUID = .(0xca774fea, 0x28ac, 0x4bc2, 0x94, 0xca, 0xac, 0xec, 0x6d, 0x6c, 0x10, 0xa3);
	public const Guid LocalizedControlType_Property_GUID = .(0x8763404f, 0xa1bd, 0x452a, 0x89, 0xc4, 0x3f, 0x01, 0xd3, 0x83, 0x38, 0x06);
	public const Guid Name_Property_GUID = .(0xc3a6921b, 0x4a99, 0x44f1, 0xbc, 0xa6, 0x61, 0x18, 0x70, 0x52, 0xc4, 0x31);
	public const Guid AcceleratorKey_Property_GUID = .(0x514865df, 0x2557, 0x4cb9, 0xae, 0xed, 0x6c, 0xed, 0x08, 0x4c, 0xe5, 0x2c);
	public const Guid AccessKey_Property_GUID = .(0x06827b12, 0xa7f9, 0x4a15, 0x91, 0x7c, 0xff, 0xa5, 0xad, 0x3e, 0xb0, 0xa7);
	public const Guid HasKeyboardFocus_Property_GUID = .(0xcf8afd39, 0x3f46, 0x4800, 0x96, 0x56, 0xb2, 0xbf, 0x12, 0x52, 0x99, 0x05);
	public const Guid IsKeyboardFocusable_Property_GUID = .(0xf7b8552a, 0x0859, 0x4b37, 0xb9, 0xcb, 0x51, 0xe7, 0x20, 0x92, 0xf2, 0x9f);
	public const Guid IsEnabled_Property_GUID = .(0x2109427f, 0xda60, 0x4fed, 0xbf, 0x1b, 0x26, 0x4b, 0xdc, 0xe6, 0xeb, 0x3a);
	public const Guid AutomationId_Property_GUID = .(0xc82c0500, 0xb60e, 0x4310, 0xa2, 0x67, 0x30, 0x3c, 0x53, 0x1f, 0x8e, 0xe5);
	public const Guid ClassName_Property_GUID = .(0x157b7215, 0x894f, 0x4b65, 0x84, 0xe2, 0xaa, 0xc0, 0xda, 0x08, 0xb1, 0x6b);
	public const Guid HelpText_Property_GUID = .(0x08555685, 0x0977, 0x45c7, 0xa7, 0xa6, 0xab, 0xaf, 0x56, 0x84, 0x12, 0x1a);
	public const Guid ClickablePoint_Property_GUID = .(0x0196903b, 0xb203, 0x4818, 0xa9, 0xf3, 0xf0, 0x8e, 0x67, 0x5f, 0x23, 0x41);
	public const Guid Culture_Property_GUID = .(0xe2d74f27, 0x3d79, 0x4dc2, 0xb8, 0x8b, 0x30, 0x44, 0x96, 0x3a, 0x8a, 0xfb);
	public const Guid IsControlElement_Property_GUID = .(0x95f35085, 0xabcc, 0x4afd, 0xa5, 0xf4, 0xdb, 0xb4, 0x6c, 0x23, 0x0f, 0xdb);
	public const Guid IsContentElement_Property_GUID = .(0x4bda64a8, 0xf5d8, 0x480b, 0x81, 0x55, 0xef, 0x2e, 0x89, 0xad, 0xb6, 0x72);
	public const Guid LabeledBy_Property_GUID = .(0xe5b8924b, 0xfc8a, 0x4a35, 0x80, 0x31, 0xcf, 0x78, 0xac, 0x43, 0xe5, 0x5e);
	public const Guid IsPassword_Property_GUID = .(0xe8482eb1, 0x687c, 0x497b, 0xbe, 0xbc, 0x03, 0xbe, 0x53, 0xec, 0x14, 0x54);
	public const Guid NewNativeWindowHandle_Property_GUID = .(0x5196b33b, 0x380a, 0x4982, 0x95, 0xe1, 0x91, 0xf3, 0xef, 0x60, 0xe0, 0x24);
	public const Guid ItemType_Property_GUID = .(0xcdda434d, 0x6222, 0x413b, 0xa6, 0x8a, 0x32, 0x5d, 0xd1, 0xd4, 0x0f, 0x39);
	public const Guid IsOffscreen_Property_GUID = .(0x03c3d160, 0xdb79, 0x42db, 0xa2, 0xef, 0x1c, 0x23, 0x1e, 0xed, 0xe5, 0x07);
	public const Guid Orientation_Property_GUID = .(0xa01eee62, 0x3884, 0x4415, 0x88, 0x7e, 0x67, 0x8e, 0xc2, 0x1e, 0x39, 0xba);
	public const Guid FrameworkId_Property_GUID = .(0xdbfd9900, 0x7e1a, 0x4f58, 0xb6, 0x1b, 0x70, 0x63, 0x12, 0x0f, 0x77, 0x3b);
	public const Guid IsRequiredForForm_Property_GUID = .(0x4f5f43cf, 0x59fb, 0x4bde, 0xa2, 0x70, 0x60, 0x2e, 0x5e, 0x11, 0x41, 0xe9);
	public const Guid ItemStatus_Property_GUID = .(0x51de0321, 0x3973, 0x43e7, 0x89, 0x13, 0x0b, 0x08, 0xe8, 0x13, 0xc3, 0x7f);
	public const Guid AriaRole_Property_GUID = .(0xdd207b95, 0xbe4a, 0x4e0d, 0xb7, 0x27, 0x63, 0xac, 0xe9, 0x4b, 0x69, 0x16);
	public const Guid AriaProperties_Property_GUID = .(0x4213678c, 0xe025, 0x4922, 0xbe, 0xb5, 0xe4, 0x3b, 0xa0, 0x8e, 0x62, 0x21);
	public const Guid IsDataValidForForm_Property_GUID = .(0x445ac684, 0xc3fc, 0x4dd9, 0xac, 0xf8, 0x84, 0x5a, 0x57, 0x92, 0x96, 0xba);
	public const Guid ControllerFor_Property_GUID = .(0x51124c8a, 0xa5d2, 0x4f13, 0x9b, 0xe6, 0x7f, 0xa8, 0xba, 0x9d, 0x3a, 0x90);
	public const Guid DescribedBy_Property_GUID = .(0x7c5865b8, 0x9992, 0x40fd, 0x8d, 0xb0, 0x6b, 0xf1, 0xd3, 0x17, 0xf9, 0x98);
	public const Guid FlowsTo_Property_GUID = .(0xe4f33d20, 0x559a, 0x47fb, 0xa8, 0x30, 0xf9, 0xcb, 0x4f, 0xf1, 0xa7, 0x0a);
	public const Guid ProviderDescription_Property_GUID = .(0xdca5708a, 0xc16b, 0x4cd9, 0xb8, 0x89, 0xbe, 0xb1, 0x6a, 0x80, 0x49, 0x04);
	public const Guid OptimizeForVisualContent_Property_GUID = .(0x6a852250, 0xc75a, 0x4e5d, 0xb8, 0x58, 0xe3, 0x81, 0xb0, 0xf7, 0x88, 0x61);
	public const Guid IsDockPatternAvailable_Property_GUID = .(0x2600a4c4, 0x2ff8, 0x4c96, 0xae, 0x31, 0x8f, 0xe6, 0x19, 0xa1, 0x3c, 0x6c);
	public const Guid IsExpandCollapsePatternAvailable_Property_GUID = .(0x929d3806, 0x5287, 0x4725, 0xaa, 0x16, 0x22, 0x2a, 0xfc, 0x63, 0xd5, 0x95);
	public const Guid IsGridItemPatternAvailable_Property_GUID = .(0x5a43e524, 0xf9a2, 0x4b12, 0x84, 0xc8, 0xb4, 0x8a, 0x3e, 0xfe, 0xdd, 0x34);
	public const Guid IsGridPatternAvailable_Property_GUID = .(0x5622c26c, 0xf0ef, 0x4f3b, 0x97, 0xcb, 0x71, 0x4c, 0x08, 0x68, 0x58, 0x8b);
	public const Guid IsInvokePatternAvailable_Property_GUID = .(0x4e725738, 0x8364, 0x4679, 0xaa, 0x6c, 0xf3, 0xf4, 0x19, 0x31, 0xf7, 0x50);
	public const Guid IsMultipleViewPatternAvailable_Property_GUID = .(0xff0a31eb, 0x8e25, 0x469d, 0x8d, 0x6e, 0xe7, 0x71, 0xa2, 0x7c, 0x1b, 0x90);
	public const Guid IsRangeValuePatternAvailable_Property_GUID = .(0xfda4244a, 0xeb4d, 0x43ff, 0xb5, 0xad, 0xed, 0x36, 0xd3, 0x73, 0xec, 0x4c);
	public const Guid IsScrollPatternAvailable_Property_GUID = .(0x3ebb7b4a, 0x828a, 0x4b57, 0x9d, 0x22, 0x2f, 0xea, 0x16, 0x32, 0xed, 0x0d);
	public const Guid IsScrollItemPatternAvailable_Property_GUID = .(0x1cad1a05, 0x0927, 0x4b76, 0x97, 0xe1, 0x0f, 0xcd, 0xb2, 0x09, 0xb9, 0x8a);
	public const Guid IsSelectionItemPatternAvailable_Property_GUID = .(0x8becd62d, 0x0bc3, 0x4109, 0xbe, 0xe2, 0x8e, 0x67, 0x15, 0x29, 0x0e, 0x68);
	public const Guid IsSelectionPatternAvailable_Property_GUID = .(0xf588acbe, 0xc769, 0x4838, 0x9a, 0x60, 0x26, 0x86, 0xdc, 0x11, 0x88, 0xc4);
	public const Guid IsTablePatternAvailable_Property_GUID = .(0xcb83575f, 0x45c2, 0x4048, 0x9c, 0x76, 0x15, 0x97, 0x15, 0xa1, 0x39, 0xdf);
	public const Guid IsTableItemPatternAvailable_Property_GUID = .(0xeb36b40d, 0x8ea4, 0x489b, 0xa0, 0x13, 0xe6, 0x0d, 0x59, 0x51, 0xfe, 0x34);
	public const Guid IsTextPatternAvailable_Property_GUID = .(0xfbe2d69d, 0xaff6, 0x4a45, 0x82, 0xe2, 0xfc, 0x92, 0xa8, 0x2f, 0x59, 0x17);
	public const Guid IsTogglePatternAvailable_Property_GUID = .(0x78686d53, 0xfcd0, 0x4b83, 0x9b, 0x78, 0x58, 0x32, 0xce, 0x63, 0xbb, 0x5b);
	public const Guid IsTransformPatternAvailable_Property_GUID = .(0xa7f78804, 0xd68b, 0x4077, 0xa5, 0xc6, 0x7a, 0x5e, 0xa1, 0xac, 0x31, 0xc5);
	public const Guid IsValuePatternAvailable_Property_GUID = .(0x0b5020a7, 0x2119, 0x473b, 0xbe, 0x37, 0x5c, 0xeb, 0x98, 0xbb, 0xfb, 0x22);
	public const Guid IsWindowPatternAvailable_Property_GUID = .(0xe7a57bb1, 0x5888, 0x4155, 0x98, 0xdc, 0xb4, 0x22, 0xfd, 0x57, 0xf2, 0xbc);
	public const Guid IsLegacyIAccessiblePatternAvailable_Property_GUID = .(0xd8ebd0c7, 0x929a, 0x4ee7, 0x8d, 0x3a, 0xd3, 0xd9, 0x44, 0x13, 0x02, 0x7b);
	public const Guid IsItemContainerPatternAvailable_Property_GUID = .(0x624b5ca7, 0xfe40, 0x4957, 0xa0, 0x19, 0x20, 0xc4, 0xcf, 0x11, 0x92, 0x0f);
	public const Guid IsVirtualizedItemPatternAvailable_Property_GUID = .(0x302cb151, 0x2ac8, 0x45d6, 0x97, 0x7b, 0xd2, 0xb3, 0xa5, 0xa5, 0x3f, 0x20);
	public const Guid IsSynchronizedInputPatternAvailable_Property_GUID = .(0x75d69cc5, 0xd2bf, 0x4943, 0x87, 0x6e, 0xb4, 0x5b, 0x62, 0xa6, 0xcc, 0x66);
	public const Guid IsObjectModelPatternAvailable_Property_GUID = .(0x6b21d89b, 0x2841, 0x412f, 0x8e, 0xf2, 0x15, 0xca, 0x95, 0x23, 0x18, 0xba);
	public const Guid IsAnnotationPatternAvailable_Property_GUID = .(0x0b5b3238, 0x6d5c, 0x41b6, 0xbc, 0xc4, 0x5e, 0x80, 0x7f, 0x65, 0x51, 0xc4);
	public const Guid IsTextPattern2Available_Property_GUID = .(0x41cf921d, 0xe3f1, 0x4b22, 0x9c, 0x81, 0xe1, 0xc3, 0xed, 0x33, 0x1c, 0x22);
	public const Guid IsTextEditPatternAvailable_Property_GUID = .(0x7843425c, 0x8b32, 0x484c, 0x9a, 0xb5, 0xe3, 0x20, 0x05, 0x71, 0xff, 0xda);
	public const Guid IsCustomNavigationPatternAvailable_Property_GUID = .(0x8f8e80d4, 0x2351, 0x48e0, 0x87, 0x4a, 0x54, 0xaa, 0x73, 0x13, 0x88, 0x9a);
	public const Guid IsStylesPatternAvailable_Property_GUID = .(0x27f353d3, 0x459c, 0x4b59, 0xa4, 0x90, 0x50, 0x61, 0x1d, 0xac, 0xaf, 0xb5);
	public const Guid IsSpreadsheetPatternAvailable_Property_GUID = .(0x6ff43732, 0xe4b4, 0x4555, 0x97, 0xbc, 0xec, 0xdb, 0xbc, 0x4d, 0x18, 0x88);
	public const Guid IsSpreadsheetItemPatternAvailable_Property_GUID = .(0x9fe79b2a, 0x2f94, 0x43fd, 0x99, 0x6b, 0x54, 0x9e, 0x31, 0x6f, 0x4a, 0xcd);
	public const Guid IsTransformPattern2Available_Property_GUID = .(0x25980b4b, 0xbe04, 0x4710, 0xab, 0x4a, 0xfd, 0xa3, 0x1d, 0xbd, 0x28, 0x95);
	public const Guid IsTextChildPatternAvailable_Property_GUID = .(0x559e65df, 0x30ff, 0x43b5, 0xb5, 0xed, 0x5b, 0x28, 0x3b, 0x80, 0xc7, 0xe9);
	public const Guid IsDragPatternAvailable_Property_GUID = .(0xe997a7b7, 0x1d39, 0x4ca7, 0xbe, 0x0f, 0x27, 0x7f, 0xcf, 0x56, 0x05, 0xcc);
	public const Guid IsDropTargetPatternAvailable_Property_GUID = .(0x0686b62e, 0x8e19, 0x4aaf, 0x87, 0x3d, 0x38, 0x4f, 0x6d, 0x3b, 0x92, 0xbe);
	public const Guid IsStructuredMarkupPatternAvailable_Property_GUID = .(0xb0d4c196, 0x2c0b, 0x489c, 0xb1, 0x65, 0xa4, 0x05, 0x92, 0x8c, 0x6f, 0x3d);
	public const Guid IsPeripheral_Property_GUID = .(0xda758276, 0x7ed5, 0x49d4, 0x8e, 0x68, 0xec, 0xc9, 0xa2, 0xd3, 0x00, 0xdd);
	public const Guid PositionInSet_Property_GUID = .(0x33d1dc54, 0x641e, 0x4d76, 0xa6, 0xb1, 0x13, 0xf3, 0x41, 0xc1, 0xf8, 0x96);
	public const Guid SizeOfSet_Property_GUID = .(0x1600d33c, 0x3b9f, 0x4369, 0x94, 0x31, 0xaa, 0x29, 0x3f, 0x34, 0x4c, 0xf1);
	public const Guid Level_Property_GUID = .(0x242ac529, 0xcd36, 0x400f, 0xaa, 0xd9, 0x78, 0x76, 0xef, 0x3a, 0xf6, 0x27);
	public const Guid AnnotationTypes_Property_GUID = .(0x64b71f76, 0x53c4, 0x4696, 0xa2, 0x19, 0x20, 0xe9, 0x40, 0xc9, 0xa1, 0x76);
	public const Guid AnnotationObjects_Property_GUID = .(0x310910c8, 0x7c6e, 0x4f20, 0xbe, 0xcd, 0x4a, 0xaf, 0x6d, 0x19, 0x11, 0x56);
	public const Guid LandmarkType_Property_GUID = .(0x454045f2, 0x6f61, 0x49f7, 0xa4, 0xf8, 0xb5, 0xf0, 0xcf, 0x82, 0xda, 0x1e);
	public const Guid LocalizedLandmarkType_Property_GUID = .(0x7ac81980, 0xeafb, 0x4fb2, 0xbf, 0x91, 0xf4, 0x85, 0xbe, 0xf5, 0xe8, 0xe1);
	public const Guid FullDescription_Property_GUID = .(0x0d4450ff, 0x6aef, 0x4f33, 0x95, 0xdd, 0x7b, 0xef, 0xa7, 0x2a, 0x43, 0x91);
	public const Guid Value_Value_Property_GUID = .(0xe95f5e64, 0x269f, 0x4a85, 0xba, 0x99, 0x40, 0x92, 0xc3, 0xea, 0x29, 0x86);
	public const Guid Value_IsReadOnly_Property_GUID = .(0xeb090f30, 0xe24c, 0x4799, 0xa7, 0x05, 0x0d, 0x24, 0x7b, 0xc0, 0x37, 0xf8);
	public const Guid RangeValue_Value_Property_GUID = .(0x131f5d98, 0xc50c, 0x489d, 0xab, 0xe5, 0xae, 0x22, 0x08, 0x98, 0xc5, 0xf7);
	public const Guid RangeValue_IsReadOnly_Property_GUID = .(0x25fa1055, 0xdebf, 0x4373, 0xa7, 0x9e, 0x1f, 0x1a, 0x19, 0x08, 0xd3, 0xc4);
	public const Guid RangeValue_Minimum_Property_GUID = .(0x78cbd3b2, 0x684d, 0x4860, 0xaf, 0x93, 0xd1, 0xf9, 0x5c, 0xb0, 0x22, 0xfd);
	public const Guid RangeValue_Maximum_Property_GUID = .(0x19319914, 0xf979, 0x4b35, 0xa1, 0xa6, 0xd3, 0x7e, 0x05, 0x43, 0x34, 0x73);
	public const Guid RangeValue_LargeChange_Property_GUID = .(0xa1f96325, 0x3a3d, 0x4b44, 0x8e, 0x1f, 0x4a, 0x46, 0xd9, 0x84, 0x40, 0x19);
	public const Guid RangeValue_SmallChange_Property_GUID = .(0x81c2c457, 0x3941, 0x4107, 0x99, 0x75, 0x13, 0x97, 0x60, 0xf7, 0xc0, 0x72);
	public const Guid Scroll_HorizontalScrollPercent_Property_GUID = .(0xc7c13c0e, 0xeb21, 0x47ff, 0xac, 0xc4, 0xb5, 0xa3, 0x35, 0x0f, 0x51, 0x91);
	public const Guid Scroll_HorizontalViewSize_Property_GUID = .(0x70c2e5d4, 0xfcb0, 0x4713, 0xa9, 0xaa, 0xaf, 0x92, 0xff, 0x79, 0xe4, 0xcd);
	public const Guid Scroll_VerticalScrollPercent_Property_GUID = .(0x6c8d7099, 0xb2a8, 0x4948, 0xbf, 0xf7, 0x3c, 0xf9, 0x05, 0x8b, 0xfe, 0xfb);
	public const Guid Scroll_VerticalViewSize_Property_GUID = .(0xde6a2e22, 0xd8c7, 0x40c5, 0x83, 0xba, 0xe5, 0xf6, 0x81, 0xd5, 0x31, 0x08);
	public const Guid Scroll_HorizontallyScrollable_Property_GUID = .(0x8b925147, 0x28cd, 0x49ae, 0xbd, 0x63, 0xf4, 0x41, 0x18, 0xd2, 0xe7, 0x19);
	public const Guid Scroll_VerticallyScrollable_Property_GUID = .(0x89164798, 0x0068, 0x4315, 0xb8, 0x9a, 0x1e, 0x7c, 0xfb, 0xbc, 0x3d, 0xfc);
	public const Guid Selection_Selection_Property_GUID = .(0xaa6dc2a2, 0x0e2b, 0x4d38, 0x96, 0xd5, 0x34, 0xe4, 0x70, 0xb8, 0x18, 0x53);
	public const Guid Selection_CanSelectMultiple_Property_GUID = .(0x49d73da5, 0xc883, 0x4500, 0x88, 0x3d, 0x8f, 0xcf, 0x8d, 0xaf, 0x6c, 0xbe);
	public const Guid Selection_IsSelectionRequired_Property_GUID = .(0xb1ae4422, 0x63fe, 0x44e7, 0xa5, 0xa5, 0xa7, 0x38, 0xc8, 0x29, 0xb1, 0x9a);
	public const Guid Grid_RowCount_Property_GUID = .(0x2a9505bf, 0xc2eb, 0x4fb6, 0xb3, 0x56, 0x82, 0x45, 0xae, 0x53, 0x70, 0x3e);
	public const Guid Grid_ColumnCount_Property_GUID = .(0xfe96f375, 0x44aa, 0x4536, 0xac, 0x7a, 0x2a, 0x75, 0xd7, 0x1a, 0x3e, 0xfc);
	public const Guid GridItem_Row_Property_GUID = .(0x6223972a, 0xc945, 0x4563, 0x93, 0x29, 0xfd, 0xc9, 0x74, 0xaf, 0x25, 0x53);
	public const Guid GridItem_Column_Property_GUID = .(0xc774c15c, 0x62c0, 0x4519, 0x8b, 0xdc, 0x47, 0xbe, 0x57, 0x3c, 0x8a, 0xd5);
	public const Guid GridItem_RowSpan_Property_GUID = .(0x4582291c, 0x466b, 0x4e93, 0x8e, 0x83, 0x3d, 0x17, 0x15, 0xec, 0x0c, 0x5e);
	public const Guid GridItem_ColumnSpan_Property_GUID = .(0x583ea3f5, 0x86d0, 0x4b08, 0xa6, 0xec, 0x2c, 0x54, 0x63, 0xff, 0xc1, 0x09);
	public const Guid GridItem_Parent_Property_GUID = .(0x9d912252, 0xb97f, 0x4ecc, 0x85, 0x10, 0xea, 0x0e, 0x33, 0x42, 0x7c, 0x72);
	public const Guid Dock_DockPosition_Property_GUID = .(0x6d67f02e, 0xc0b0, 0x4b10, 0xb5, 0xb9, 0x18, 0xd6, 0xec, 0xf9, 0x87, 0x60);
	public const Guid ExpandCollapse_ExpandCollapseState_Property_GUID = .(0x275a4c48, 0x85a7, 0x4f69, 0xab, 0xa0, 0xaf, 0x15, 0x76, 0x10, 0x00, 0x2b);
	public const Guid MultipleView_CurrentView_Property_GUID = .(0x7a81a67a, 0xb94f, 0x4875, 0x91, 0x8b, 0x65, 0xc8, 0xd2, 0xf9, 0x98, 0xe5);
	public const Guid MultipleView_SupportedViews_Property_GUID = .(0x8d5db9fd, 0xce3c, 0x4ae7, 0xb7, 0x88, 0x40, 0x0a, 0x3c, 0x64, 0x55, 0x47);
	public const Guid Window_CanMaximize_Property_GUID = .(0x64fff53f, 0x635d, 0x41c1, 0x95, 0x0c, 0xcb, 0x5a, 0xdf, 0xbe, 0x28, 0xe3);
	public const Guid Window_CanMinimize_Property_GUID = .(0xb73b4625, 0x5988, 0x4b97, 0xb4, 0xc2, 0xa6, 0xfe, 0x6e, 0x78, 0xc8, 0xc6);
	public const Guid Window_WindowVisualState_Property_GUID = .(0x4ab7905f, 0xe860, 0x453e, 0xa3, 0x0a, 0xf6, 0x43, 0x1e, 0x5d, 0xaa, 0xd5);
	public const Guid Window_WindowInteractionState_Property_GUID = .(0x4fed26a4, 0x0455, 0x4fa2, 0xb2, 0x1c, 0xc4, 0xda, 0x2d, 0xb1, 0xff, 0x9c);
	public const Guid Window_IsModal_Property_GUID = .(0xff4e6892, 0x37b9, 0x4fca, 0x85, 0x32, 0xff, 0xe6, 0x74, 0xec, 0xfe, 0xed);
	public const Guid Window_IsTopmost_Property_GUID = .(0xef7d85d3, 0x0937, 0x4962, 0x92, 0x41, 0xb6, 0x23, 0x45, 0xf2, 0x40, 0x41);
	public const Guid SelectionItem_IsSelected_Property_GUID = .(0xf122835f, 0xcd5f, 0x43df, 0xb7, 0x9d, 0x4b, 0x84, 0x9e, 0x9e, 0x60, 0x20);
	public const Guid SelectionItem_SelectionContainer_Property_GUID = .(0xa4365b6e, 0x9c1e, 0x4b63, 0x8b, 0x53, 0xc2, 0x42, 0x1d, 0xd1, 0xe8, 0xfb);
	public const Guid Table_RowHeaders_Property_GUID = .(0xd9e35b87, 0x6eb8, 0x4562, 0xaa, 0xc6, 0xa8, 0xa9, 0x07, 0x52, 0x36, 0xa8);
	public const Guid Table_ColumnHeaders_Property_GUID = .(0xaff1d72b, 0x968d, 0x42b1, 0xb4, 0x59, 0x15, 0x0b, 0x29, 0x9d, 0xa6, 0x64);
	public const Guid Table_RowOrColumnMajor_Property_GUID = .(0x83be75c3, 0x29fe, 0x4a30, 0x85, 0xe1, 0x2a, 0x62, 0x77, 0xfd, 0x10, 0x6e);
	public const Guid TableItem_RowHeaderItems_Property_GUID = .(0xb3f853a0, 0x0574, 0x4cd8, 0xbc, 0xd7, 0xed, 0x59, 0x23, 0x57, 0x2d, 0x97);
	public const Guid TableItem_ColumnHeaderItems_Property_GUID = .(0x967a56a3, 0x74b6, 0x431e, 0x8d, 0xe6, 0x99, 0xc4, 0x11, 0x03, 0x1c, 0x58);
	public const Guid Toggle_ToggleState_Property_GUID = .(0xb23cdc52, 0x22c2, 0x4c6c, 0x9d, 0xed, 0xf5, 0xc4, 0x22, 0x47, 0x9e, 0xde);
	public const Guid Transform_CanMove_Property_GUID = .(0x1b75824d, 0x208b, 0x4fdf, 0xbc, 0xcd, 0xf1, 0xf4, 0xe5, 0x74, 0x1f, 0x4f);
	public const Guid Transform_CanResize_Property_GUID = .(0xbb98dca5, 0x4c1a, 0x41d4, 0xa4, 0xf6, 0xeb, 0xc1, 0x28, 0x64, 0x41, 0x80);
	public const Guid Transform_CanRotate_Property_GUID = .(0x10079b48, 0x3849, 0x476f, 0xac, 0x96, 0x44, 0xa9, 0x5c, 0x84, 0x40, 0xd9);
	public const Guid LegacyIAccessible_ChildId_Property_GUID = .(0x9a191b5d, 0x9ef2, 0x4787, 0xa4, 0x59, 0xdc, 0xde, 0x88, 0x5d, 0xd4, 0xe8);
	public const Guid LegacyIAccessible_Name_Property_GUID = .(0xcaeb063d, 0x40ae, 0x4869, 0xaa, 0x5a, 0x1b, 0x8e, 0x5d, 0x66, 0x67, 0x39);
	public const Guid LegacyIAccessible_Value_Property_GUID = .(0xb5c5b0b6, 0x8217, 0x4a77, 0x97, 0xa5, 0x19, 0x0a, 0x85, 0xed, 0x01, 0x56);
	public const Guid LegacyIAccessible_Description_Property_GUID = .(0x46448418, 0x7d70, 0x4ea9, 0x9d, 0x27, 0xb7, 0xe7, 0x75, 0xcf, 0x2a, 0xd7);
	public const Guid LegacyIAccessible_Role_Property_GUID = .(0x6856e59f, 0xcbaf, 0x4e31, 0x93, 0xe8, 0xbc, 0xbf, 0x6f, 0x7e, 0x49, 0x1c);
	public const Guid LegacyIAccessible_State_Property_GUID = .(0xdf985854, 0x2281, 0x4340, 0xab, 0x9c, 0xc6, 0x0e, 0x2c, 0x58, 0x03, 0xf6);
	public const Guid LegacyIAccessible_Help_Property_GUID = .(0x94402352, 0x161c, 0x4b77, 0xa9, 0x8d, 0xa8, 0x72, 0xcc, 0x33, 0x94, 0x7a);
	public const Guid LegacyIAccessible_KeyboardShortcut_Property_GUID = .(0x8f6909ac, 0x00b8, 0x4259, 0xa4, 0x1c, 0x96, 0x62, 0x66, 0xd4, 0x3a, 0x8a);
	public const Guid LegacyIAccessible_Selection_Property_GUID = .(0x8aa8b1e0, 0x0891, 0x40cc, 0x8b, 0x06, 0x90, 0xd7, 0xd4, 0x16, 0x62, 0x19);
	public const Guid LegacyIAccessible_DefaultAction_Property_GUID = .(0x3b331729, 0xeaad, 0x4502, 0xb8, 0x5f, 0x92, 0x61, 0x56, 0x22, 0x91, 0x3c);
	public const Guid Annotation_AnnotationTypeId_Property_GUID = .(0x20ae484f, 0x69ef, 0x4c48, 0x8f, 0x5b, 0xc4, 0x93, 0x8b, 0x20, 0x6a, 0xc7);
	public const Guid Annotation_AnnotationTypeName_Property_GUID = .(0x9b818892, 0x5ac9, 0x4af9, 0xaa, 0x96, 0xf5, 0x8a, 0x77, 0xb0, 0x58, 0xe3);
	public const Guid Annotation_Author_Property_GUID = .(0x7a528462, 0x9c5c, 0x4a03, 0xa9, 0x74, 0x8b, 0x30, 0x7a, 0x99, 0x37, 0xf2);
	public const Guid Annotation_DateTime_Property_GUID = .(0x99b5ca5d, 0x1acf, 0x414b, 0xa4, 0xd0, 0x6b, 0x35, 0x0b, 0x04, 0x75, 0x78);
	public const Guid Annotation_Target_Property_GUID = .(0xb71b302d, 0x2104, 0x44ad, 0x9c, 0x5c, 0x09, 0x2b, 0x49, 0x07, 0xd7, 0x0f);
	public const Guid Styles_StyleId_Property_GUID = .(0xda82852f, 0x3817, 0x4233, 0x82, 0xaf, 0x02, 0x27, 0x9e, 0x72, 0xcc, 0x77);
	public const Guid Styles_StyleName_Property_GUID = .(0x1c12b035, 0x05d1, 0x4f55, 0x9e, 0x8e, 0x14, 0x89, 0xf3, 0xff, 0x55, 0x0d);
	public const Guid Styles_FillColor_Property_GUID = .(0x63eff97a, 0xa1c5, 0x4b1d, 0x84, 0xeb, 0xb7, 0x65, 0xf2, 0xed, 0xd6, 0x32);
	public const Guid Styles_FillPatternStyle_Property_GUID = .(0x81cf651f, 0x482b, 0x4451, 0xa3, 0x0a, 0xe1, 0x54, 0x5e, 0x55, 0x4f, 0xb8);
	public const Guid Styles_Shape_Property_GUID = .(0xc71a23f8, 0x778c, 0x400d, 0x84, 0x58, 0x3b, 0x54, 0x3e, 0x52, 0x69, 0x84);
	public const Guid Styles_FillPatternColor_Property_GUID = .(0x939a59fe, 0x8fbd, 0x4e75, 0xa2, 0x71, 0xac, 0x45, 0x95, 0x19, 0x51, 0x63);
	public const Guid Styles_ExtendedProperties_Property_GUID = .(0xf451cda0, 0xba0a, 0x4681, 0xb0, 0xb0, 0x0d, 0xbd, 0xb5, 0x3e, 0x58, 0xf3);
	public const Guid SpreadsheetItem_Formula_Property_GUID = .(0xe602e47d, 0x1b47, 0x4bea, 0x87, 0xcf, 0x3b, 0x0b, 0x0b, 0x5c, 0x15, 0xb6);
	public const Guid SpreadsheetItem_AnnotationObjects_Property_GUID = .(0xa3194c38, 0xc9bc, 0x4604, 0x93, 0x96, 0xae, 0x3f, 0x9f, 0x45, 0x7f, 0x7b);
	public const Guid SpreadsheetItem_AnnotationTypes_Property_GUID = .(0xc70c51d0, 0xd602, 0x4b45, 0xaf, 0xbc, 0xb4, 0x71, 0x2b, 0x96, 0xd7, 0x2b);
	public const Guid Transform2_CanZoom_Property_GUID = .(0xf357e890, 0xa756, 0x4359, 0x9c, 0xa6, 0x86, 0x70, 0x2b, 0xf8, 0xf3, 0x81);
	public const Guid LiveSetting_Property_GUID = .(0xc12bcd8e, 0x2a8e, 0x4950, 0x8a, 0xe7, 0x36, 0x25, 0x11, 0x1d, 0x58, 0xeb);
	public const Guid Drag_IsGrabbed_Property_GUID = .(0x45f206f3, 0x75cc, 0x4cca, 0xa9, 0xb9, 0xfc, 0xdf, 0xb9, 0x82, 0xd8, 0xa2);
	public const Guid Drag_GrabbedItems_Property_GUID = .(0x77c1562c, 0x7b86, 0x4b21, 0x9e, 0xd7, 0x3c, 0xef, 0xda, 0x6f, 0x4c, 0x43);
	public const Guid Drag_DropEffect_Property_GUID = .(0x646f2779, 0x48d3, 0x4b23, 0x89, 0x02, 0x4b, 0xf1, 0x00, 0x00, 0x5d, 0xf3);
	public const Guid Drag_DropEffects_Property_GUID = .(0xf5d61156, 0x7ce6, 0x49be, 0xa8, 0x36, 0x92, 0x69, 0xdc, 0xec, 0x92, 0x0f);
	public const Guid DropTarget_DropTargetEffect_Property_GUID = .(0x8bb75975, 0xa0ca, 0x4981, 0xb8, 0x18, 0x87, 0xfc, 0x66, 0xe9, 0x50, 0x9d);
	public const Guid DropTarget_DropTargetEffects_Property_GUID = .(0xbc1dd4ed, 0xcb89, 0x45f1, 0xa5, 0x92, 0xe0, 0x3b, 0x08, 0xae, 0x79, 0x0f);
	public const Guid Transform2_ZoomLevel_Property_GUID = .(0xeee29f1a, 0xf4a2, 0x4b5b, 0xac, 0x65, 0x95, 0xcf, 0x93, 0x28, 0x33, 0x87);
	public const Guid Transform2_ZoomMinimum_Property_GUID = .(0x742ccc16, 0x4ad1, 0x4e07, 0x96, 0xfe, 0xb1, 0x22, 0xc6, 0xe6, 0xb2, 0x2b);
	public const Guid Transform2_ZoomMaximum_Property_GUID = .(0x42ab6b77, 0xceb0, 0x4eca, 0xb8, 0x2a, 0x6c, 0xfa, 0x5f, 0xa1, 0xfc, 0x08);
	public const Guid FlowsFrom_Property_GUID = .(0x05c6844f, 0x19de, 0x48f8, 0x95, 0xfa, 0x88, 0x0d, 0x5b, 0x0f, 0xd6, 0x15);
	public const Guid FillColor_Property_GUID = .(0x6e0ec4d0, 0xe2a8, 0x4a56, 0x9d, 0xe7, 0x95, 0x33, 0x89, 0x93, 0x3b, 0x39);
	public const Guid OutlineColor_Property_GUID = .(0xc395d6c0, 0x4b55, 0x4762, 0xa0, 0x73, 0xfd, 0x30, 0x3a, 0x63, 0x4f, 0x52);
	public const Guid FillType_Property_GUID = .(0xc6fc74e4, 0x8cb9, 0x429c, 0xa9, 0xe1, 0x9b, 0xc4, 0xac, 0x37, 0x2b, 0x62);
	public const Guid VisualEffects_Property_GUID = .(0xe61a8565, 0xaad9, 0x46d7, 0x9e, 0x70, 0x4e, 0x8a, 0x84, 0x20, 0xd4, 0x20);
	public const Guid OutlineThickness_Property_GUID = .(0x13e67cc7, 0xdac2, 0x4888, 0xbd, 0xd3, 0x37, 0x5c, 0x62, 0xfa, 0x96, 0x18);
	public const Guid CenterPoint_Property_GUID = .(0x0cb00c08, 0x540c, 0x4edb, 0x94, 0x45, 0x26, 0x35, 0x9e, 0xa6, 0x97, 0x85);
	public const Guid Rotation_Property_GUID = .(0x767cdc7d, 0xaec0, 0x4110, 0xad, 0x32, 0x30, 0xed, 0xd4, 0x03, 0x49, 0x2e);
	public const Guid Size_Property_GUID = .(0x2b5f761d, 0xf885, 0x4404, 0x97, 0x3f, 0x9b, 0x1d, 0x98, 0xe3, 0x6d, 0x8f);
	public const Guid ToolTipOpened_Event_GUID = .(0x3f4b97ff, 0x2edc, 0x451d, 0xbc, 0xa4, 0x95, 0xa3, 0x18, 0x8d, 0x5b, 0x03);
	public const Guid ToolTipClosed_Event_GUID = .(0x276d71ef, 0x24a9, 0x49b6, 0x8e, 0x97, 0xda, 0x98, 0xb4, 0x01, 0xbb, 0xcd);
	public const Guid StructureChanged_Event_GUID = .(0x59977961, 0x3edd, 0x4b11, 0xb1, 0x3b, 0x67, 0x6b, 0x2a, 0x2a, 0x6c, 0xa9);
	public const Guid MenuOpened_Event_GUID = .(0xebe2e945, 0x66ca, 0x4ed1, 0x9f, 0xf8, 0x2a, 0xd7, 0xdf, 0x0a, 0x1b, 0x08);
	public const Guid AutomationPropertyChanged_Event_GUID = .(0x2527fba1, 0x8d7a, 0x4630, 0xa4, 0xcc, 0xe6, 0x63, 0x15, 0x94, 0x2f, 0x52);
	public const Guid AutomationFocusChanged_Event_GUID = .(0xb68a1f17, 0xf60d, 0x41a7, 0xa3, 0xcc, 0xb0, 0x52, 0x92, 0x15, 0x5f, 0xe0);
	public const Guid ActiveTextPositionChanged_Event_GUID = .(0xa5c09e9c, 0xc77d, 0x4f25, 0xb4, 0x91, 0xe5, 0xbb, 0x70, 0x17, 0xcb, 0xd4);
	public const Guid AsyncContentLoaded_Event_GUID = .(0x5fdee11c, 0xd2fa, 0x4fb9, 0x90, 0x4e, 0x5c, 0xbe, 0xe8, 0x94, 0xd5, 0xef);
	public const Guid MenuClosed_Event_GUID = .(0x3cf1266e, 0x1582, 0x4041, 0xac, 0xd7, 0x88, 0xa3, 0x5a, 0x96, 0x52, 0x97);
	public const Guid LayoutInvalidated_Event_GUID = .(0xed7d6544, 0xa6bd, 0x4595, 0x9b, 0xae, 0x3d, 0x28, 0x94, 0x6c, 0xc7, 0x15);
	public const Guid Invoke_Invoked_Event_GUID = .(0xdfd699f0, 0xc915, 0x49dd, 0xb4, 0x22, 0xdd, 0xe7, 0x85, 0xc3, 0xd2, 0x4b);
	public const Guid SelectionItem_ElementAddedToSelectionEvent_Event_GUID = .(0x3c822dd1, 0xc407, 0x4dba, 0x91, 0xdd, 0x79, 0xd4, 0xae, 0xd0, 0xae, 0xc6);
	public const Guid SelectionItem_ElementRemovedFromSelectionEvent_Event_GUID = .(0x097fa8a9, 0x7079, 0x41af, 0x8b, 0x9c, 0x09, 0x34, 0xd8, 0x30, 0x5e, 0x5c);
	public const Guid SelectionItem_ElementSelectedEvent_Event_GUID = .(0xb9c7dbfb, 0x4ebe, 0x4532, 0xaa, 0xf4, 0x00, 0x8c, 0xf6, 0x47, 0x23, 0x3c);
	public const Guid Selection_InvalidatedEvent_Event_GUID = .(0xcac14904, 0x16b4, 0x4b53, 0x8e, 0x47, 0x4c, 0xb1, 0xdf, 0x26, 0x7b, 0xb7);
	public const Guid Text_TextSelectionChangedEvent_Event_GUID = .(0x918edaa1, 0x71b3, 0x49ae, 0x97, 0x41, 0x79, 0xbe, 0xb8, 0xd3, 0x58, 0xf3);
	public const Guid Text_TextChangedEvent_Event_GUID = .(0x4a342082, 0xf483, 0x48c4, 0xac, 0x11, 0xa8, 0x4b, 0x43, 0x5e, 0x2a, 0x84);
	public const Guid Window_WindowOpened_Event_GUID = .(0xd3e81d06, 0xde45, 0x4f2f, 0x96, 0x33, 0xde, 0x9e, 0x02, 0xfb, 0x65, 0xaf);
	public const Guid Window_WindowClosed_Event_GUID = .(0xedf141f8, 0xfa67, 0x4e22, 0xbb, 0xf7, 0x94, 0x4e, 0x05, 0x73, 0x5e, 0xe2);
	public const Guid MenuModeStart_Event_GUID = .(0x18d7c631, 0x166a, 0x4ac9, 0xae, 0x3b, 0xef, 0x4b, 0x54, 0x20, 0xe6, 0x81);
	public const Guid MenuModeEnd_Event_GUID = .(0x9ecd4c9f, 0x80dd, 0x47b8, 0x82, 0x67, 0x5a, 0xec, 0x06, 0xbb, 0x2c, 0xff);
	public const Guid InputReachedTarget_Event_GUID = .(0x93ed549a, 0x0549, 0x40f0, 0xbe, 0xdb, 0x28, 0xe4, 0x4f, 0x7d, 0xe2, 0xa3);
	public const Guid InputReachedOtherElement_Event_GUID = .(0xed201d8a, 0x4e6c, 0x415e, 0xa8, 0x74, 0x24, 0x60, 0xc9, 0xb6, 0x6b, 0xa8);
	public const Guid InputDiscarded_Event_GUID = .(0x7f36c367, 0x7b18, 0x417c, 0x97, 0xe3, 0x9d, 0x58, 0xdd, 0xc9, 0x44, 0xab);
	public const Guid SystemAlert_Event_GUID = .(0xd271545d, 0x7a3a, 0x47a7, 0x84, 0x74, 0x81, 0xd2, 0x9a, 0x24, 0x51, 0xc9);
	public const Guid LiveRegionChanged_Event_GUID = .(0x102d5e90, 0xe6a9, 0x41b6, 0xb1, 0xc5, 0xa9, 0xb1, 0x92, 0x9d, 0x95, 0x10);
	public const Guid HostedFragmentRootsInvalidated_Event_GUID = .(0xe6bdb03e, 0x0921, 0x4ec5, 0x8d, 0xcf, 0xea, 0xe8, 0x77, 0xb0, 0x42, 0x6b);
	public const Guid Drag_DragStart_Event_GUID = .(0x883a480b, 0x3aa9, 0x429d, 0x95, 0xe4, 0xd9, 0xc8, 0xd0, 0x11, 0xf0, 0xdd);
	public const Guid Drag_DragCancel_Event_GUID = .(0xc3ede6fa, 0x3451, 0x4e0f, 0x9e, 0x71, 0xdf, 0x9c, 0x28, 0x0a, 0x46, 0x57);
	public const Guid Drag_DragComplete_Event_GUID = .(0x38e96188, 0xef1f, 0x463e, 0x91, 0xca, 0x3a, 0x77, 0x92, 0xc2, 0x9c, 0xaf);
	public const Guid DropTarget_DragEnter_Event_GUID = .(0xaad9319b, 0x032c, 0x4a88, 0x96, 0x1d, 0x1c, 0xf5, 0x79, 0x58, 0x1e, 0x34);
	public const Guid DropTarget_DragLeave_Event_GUID = .(0x0f82eb15, 0x24a2, 0x4988, 0x92, 0x17, 0xde, 0x16, 0x2a, 0xee, 0x27, 0x2b);
	public const Guid DropTarget_Dropped_Event_GUID = .(0x622cead8, 0x1edb, 0x4a3d, 0xab, 0xbc, 0xbe, 0x22, 0x11, 0xff, 0x68, 0xb5);
	public const Guid StructuredMarkup_CompositionComplete_Event_GUID = .(0xc48a3c17, 0x677a, 0x4047, 0xa6, 0x8d, 0xfc, 0x12, 0x57, 0x52, 0x8a, 0xef);
	public const Guid StructuredMarkup_Deleted_Event_GUID = .(0xf9d0a020, 0xe1c1, 0x4ecf, 0xb9, 0xaa, 0x52, 0xef, 0xde, 0x7e, 0x41, 0xe1);
	public const Guid StructuredMarkup_SelectionChanged_Event_GUID = .(0xa7c815f7, 0xff9f, 0x41c7, 0xa3, 0xa7, 0xab, 0x6c, 0xbf, 0xdb, 0x49, 0x03);
	public const Guid Invoke_Pattern_GUID = .(0xd976c2fc, 0x66ea, 0x4a6e, 0xb2, 0x8f, 0xc2, 0x4c, 0x75, 0x46, 0xad, 0x37);
	public const Guid Selection_Pattern_GUID = .(0x66e3b7e8, 0xd821, 0x4d25, 0x87, 0x61, 0x43, 0x5d, 0x2c, 0x8b, 0x25, 0x3f);
	public const Guid Value_Pattern_GUID = .(0x17faad9e, 0xc877, 0x475b, 0xb9, 0x33, 0x77, 0x33, 0x27, 0x79, 0xb6, 0x37);
	public const Guid RangeValue_Pattern_GUID = .(0x18b00d87, 0xb1c9, 0x476a, 0xbf, 0xbd, 0x5f, 0x0b, 0xdb, 0x92, 0x6f, 0x63);
	public const Guid Scroll_Pattern_GUID = .(0x895fa4b4, 0x759d, 0x4c50, 0x8e, 0x15, 0x03, 0x46, 0x06, 0x72, 0x00, 0x3c);
	public const Guid ExpandCollapse_Pattern_GUID = .(0xae05efa2, 0xf9d1, 0x428a, 0x83, 0x4c, 0x53, 0xa5, 0xc5, 0x2f, 0x9b, 0x8b);
	public const Guid Grid_Pattern_GUID = .(0x260a2ccb, 0x93a8, 0x4e44, 0xa4, 0xc1, 0x3d, 0xf3, 0x97, 0xf2, 0xb0, 0x2b);
	public const Guid GridItem_Pattern_GUID = .(0xf2d5c877, 0xa462, 0x4957, 0xa2, 0xa5, 0x2c, 0x96, 0xb3, 0x03, 0xbc, 0x63);
	public const Guid MultipleView_Pattern_GUID = .(0x547a6ae4, 0x113f, 0x47c4, 0x85, 0x0f, 0xdb, 0x4d, 0xfa, 0x46, 0x6b, 0x1d);
	public const Guid Window_Pattern_GUID = .(0x27901735, 0xc760, 0x4994, 0xad, 0x11, 0x59, 0x19, 0xe6, 0x06, 0xb1, 0x10);
	public const Guid SelectionItem_Pattern_GUID = .(0x9bc64eeb, 0x87c7, 0x4b28, 0x94, 0xbb, 0x4d, 0x9f, 0xa4, 0x37, 0xb6, 0xef);
	public const Guid Dock_Pattern_GUID = .(0x9cbaa846, 0x83c8, 0x428d, 0x82, 0x7f, 0x7e, 0x60, 0x63, 0xfe, 0x06, 0x20);
	public const Guid Table_Pattern_GUID = .(0xc415218e, 0xa028, 0x461e, 0xaa, 0x92, 0x8f, 0x92, 0x5c, 0xf7, 0x93, 0x51);
	public const Guid TableItem_Pattern_GUID = .(0xdf1343bd, 0x1888, 0x4a29, 0xa5, 0x0c, 0xb9, 0x2e, 0x6d, 0xe3, 0x7f, 0x6f);
	public const Guid Text_Pattern_GUID = .(0x8615f05d, 0x7de5, 0x44fd, 0xa6, 0x79, 0x2c, 0xa4, 0xb4, 0x60, 0x33, 0xa8);
	public const Guid Toggle_Pattern_GUID = .(0x0b419760, 0xe2f4, 0x43ff, 0x8c, 0x5f, 0x94, 0x57, 0xc8, 0x2b, 0x56, 0xe9);
	public const Guid Transform_Pattern_GUID = .(0x24b46fdb, 0x587e, 0x49f1, 0x9c, 0x4a, 0xd8, 0xe9, 0x8b, 0x66, 0x4b, 0x7b);
	public const Guid ScrollItem_Pattern_GUID = .(0x4591d005, 0xa803, 0x4d5c, 0xb4, 0xd5, 0x8d, 0x28, 0x00, 0xf9, 0x06, 0xa7);
	public const Guid LegacyIAccessible_Pattern_GUID = .(0x54cc0a9f, 0x3395, 0x48af, 0xba, 0x8d, 0x73, 0xf8, 0x56, 0x90, 0xf3, 0xe0);
	public const Guid ItemContainer_Pattern_GUID = .(0x3d13da0f, 0x8b9a, 0x4a99, 0x85, 0xfa, 0xc5, 0xc9, 0xa6, 0x9f, 0x1e, 0xd4);
	public const Guid VirtualizedItem_Pattern_GUID = .(0xf510173e, 0x2e71, 0x45e9, 0xa6, 0xe5, 0x62, 0xf6, 0xed, 0x82, 0x89, 0xd5);
	public const Guid SynchronizedInput_Pattern_GUID = .(0x05c288a6, 0xc47b, 0x488b, 0xb6, 0x53, 0x33, 0x97, 0x7a, 0x55, 0x1b, 0x8b);
	public const Guid ObjectModel_Pattern_GUID = .(0x3e04acfe, 0x08fc, 0x47ec, 0x96, 0xbc, 0x35, 0x3f, 0xa3, 0xb3, 0x4a, 0xa7);
	public const Guid Annotation_Pattern_GUID = .(0xf6c72ad7, 0x356c, 0x4850, 0x92, 0x91, 0x31, 0x6f, 0x60, 0x8a, 0x8c, 0x84);
	public const Guid Text_Pattern2_GUID = .(0x498479a2, 0x5b22, 0x448d, 0xb6, 0xe4, 0x64, 0x74, 0x90, 0x86, 0x06, 0x98);
	public const Guid TextEdit_Pattern_GUID = .(0x69f3ff89, 0x5af9, 0x4c75, 0x93, 0x40, 0xf2, 0xde, 0x29, 0x2e, 0x45, 0x91);
	public const Guid CustomNavigation_Pattern_GUID = .(0xafea938a, 0x621e, 0x4054, 0xbb, 0x2c, 0x2f, 0x46, 0x11, 0x4d, 0xac, 0x3f);
	public const Guid Styles_Pattern_GUID = .(0x1ae62655, 0xda72, 0x4d60, 0xa1, 0x53, 0xe5, 0xaa, 0x69, 0x88, 0xe3, 0xbf);
	public const Guid Spreadsheet_Pattern_GUID = .(0x6a5b24c9, 0x9d1e, 0x4b85, 0x9e, 0x44, 0xc0, 0x2e, 0x31, 0x69, 0xb1, 0x0b);
	public const Guid SpreadsheetItem_Pattern_GUID = .(0x32cf83ff, 0xf1a8, 0x4a8c, 0x86, 0x58, 0xd4, 0x7b, 0xa7, 0x4e, 0x20, 0xba);
	public const Guid Tranform_Pattern2_GUID = .(0x8afcfd07, 0xa369, 0x44de, 0x98, 0x8b, 0x2f, 0x7f, 0xf4, 0x9f, 0xb8, 0xa8);
	public const Guid TextChild_Pattern_GUID = .(0x7533cab7, 0x3bfe, 0x41ef, 0x9e, 0x85, 0xe2, 0x63, 0x8c, 0xbe, 0x16, 0x9e);
	public const Guid Drag_Pattern_GUID = .(0xc0bee21f, 0xccb3, 0x4fed, 0x99, 0x5b, 0x11, 0x4f, 0x6e, 0x3d, 0x27, 0x28);
	public const Guid DropTarget_Pattern_GUID = .(0x0bcbec56, 0xbd34, 0x4b7b, 0x9f, 0xd5, 0x26, 0x59, 0x90, 0x5e, 0xa3, 0xdc);
	public const Guid StructuredMarkup_Pattern_GUID = .(0xabbd0878, 0x8665, 0x4f5c, 0x94, 0xfc, 0x36, 0xe7, 0xd8, 0xbb, 0x70, 0x6b);
	public const Guid Button_Control_GUID = .(0x5a78e369, 0xc6a1, 0x4f33, 0xa9, 0xd7, 0x79, 0xf2, 0x0d, 0x0c, 0x78, 0x8e);
	public const Guid Calendar_Control_GUID = .(0x8913eb88, 0x00e5, 0x46bc, 0x8e, 0x4e, 0x14, 0xa7, 0x86, 0xe1, 0x65, 0xa1);
	public const Guid CheckBox_Control_GUID = .(0xfb50f922, 0xa3db, 0x49c0, 0x8b, 0xc3, 0x06, 0xda, 0xd5, 0x57, 0x78, 0xe2);
	public const Guid ComboBox_Control_GUID = .(0x54cb426c, 0x2f33, 0x4fff, 0xaa, 0xa1, 0xae, 0xf6, 0x0d, 0xac, 0x5d, 0xeb);
	public const Guid Edit_Control_GUID = .(0x6504a5c8, 0x2c86, 0x4f87, 0xae, 0x7b, 0x1a, 0xbd, 0xdc, 0x81, 0x0c, 0xf9);
	public const Guid Hyperlink_Control_GUID = .(0x8a56022c, 0xb00d, 0x4d15, 0x8f, 0xf0, 0x5b, 0x6b, 0x26, 0x6e, 0x5e, 0x02);
	public const Guid Image_Control_GUID = .(0x2d3736e4, 0x6b16, 0x4c57, 0xa9, 0x62, 0xf9, 0x32, 0x60, 0xa7, 0x52, 0x43);
	public const Guid ListItem_Control_GUID = .(0x7b3717f2, 0x44d1, 0x4a58, 0x98, 0xa8, 0xf1, 0x2a, 0x9b, 0x8f, 0x78, 0xe2);
	public const Guid List_Control_GUID = .(0x9b149ee1, 0x7cca, 0x4cfc, 0x9a, 0xf1, 0xca, 0xc7, 0xbd, 0xdd, 0x30, 0x31);
	public const Guid Menu_Control_GUID = .(0x2e9b1440, 0x0ea8, 0x41fd, 0xb3, 0x74, 0xc1, 0xea, 0x6f, 0x50, 0x3c, 0xd1);
	public const Guid MenuBar_Control_GUID = .(0xcc384250, 0x0e7b, 0x4ae8, 0x95, 0xae, 0xa0, 0x8f, 0x26, 0x1b, 0x52, 0xee);
	public const Guid MenuItem_Control_GUID = .(0xf45225d3, 0xd0a0, 0x49d8, 0x98, 0x34, 0x9a, 0x00, 0x0d, 0x2a, 0xed, 0xdc);
	public const Guid ProgressBar_Control_GUID = .(0x228c9f86, 0xc36c, 0x47bb, 0x9f, 0xb6, 0xa5, 0x83, 0x4b, 0xfc, 0x53, 0xa4);
	public const Guid RadioButton_Control_GUID = .(0x3bdb49db, 0xfe2c, 0x4483, 0xb3, 0xe1, 0xe5, 0x7f, 0x21, 0x94, 0x40, 0xc6);
	public const Guid ScrollBar_Control_GUID = .(0xdaf34b36, 0x5065, 0x4946, 0xb2, 0x2f, 0x92, 0x59, 0x5f, 0xc0, 0x75, 0x1a);
	public const Guid Slider_Control_GUID = .(0xb033c24b, 0x3b35, 0x4cea, 0xb6, 0x09, 0x76, 0x36, 0x82, 0xfa, 0x66, 0x0b);
	public const Guid Spinner_Control_GUID = .(0x60cc4b38, 0x3cb1, 0x4161, 0xb4, 0x42, 0xc6, 0xb7, 0x26, 0xc1, 0x78, 0x25);
	public const Guid StatusBar_Control_GUID = .(0xd45e7d1b, 0x5873, 0x475f, 0x95, 0xa4, 0x04, 0x33, 0xe1, 0xf1, 0xb0, 0x0a);
	public const Guid Tab_Control_GUID = .(0x38cd1f2d, 0x337a, 0x4bd2, 0xa5, 0xe3, 0xad, 0xb4, 0x69, 0xe3, 0x0b, 0xd3);
	public const Guid TabItem_Control_GUID = .(0x2c6a634f, 0x921b, 0x4e6e, 0xb2, 0x6e, 0x08, 0xfc, 0xb0, 0x79, 0x8f, 0x4c);
	public const Guid Text_Control_GUID = .(0xae9772dc, 0xd331, 0x4f09, 0xbe, 0x20, 0x7e, 0x6d, 0xfa, 0xf0, 0x7b, 0x0a);
	public const Guid ToolBar_Control_GUID = .(0x8f06b751, 0xe182, 0x4e98, 0x88, 0x93, 0x22, 0x84, 0x54, 0x3a, 0x7d, 0xce);
	public const Guid ToolTip_Control_GUID = .(0x05ddc6d1, 0x2137, 0x4768, 0x98, 0xea, 0x73, 0xf5, 0x2f, 0x71, 0x34, 0xf3);
	public const Guid Tree_Control_GUID = .(0x7561349c, 0xd241, 0x43f4, 0x99, 0x08, 0xb5, 0xf0, 0x91, 0xbe, 0xe6, 0x11);
	public const Guid TreeItem_Control_GUID = .(0x62c9feb9, 0x8ffc, 0x4878, 0xa3, 0xa4, 0x96, 0xb0, 0x30, 0x31, 0x5c, 0x18);
	public const Guid Custom_Control_GUID = .(0xf29ea0c3, 0xadb7, 0x430a, 0xba, 0x90, 0xe5, 0x2c, 0x73, 0x13, 0xe6, 0xed);
	public const Guid Group_Control_GUID = .(0xad50aa1c, 0xe8c8, 0x4774, 0xae, 0x1b, 0xdd, 0x86, 0xdf, 0x0b, 0x3b, 0xdc);
	public const Guid Thumb_Control_GUID = .(0x701ca877, 0xe310, 0x4dd6, 0xb6, 0x44, 0x79, 0x7e, 0x4f, 0xae, 0xa2, 0x13);
	public const Guid DataGrid_Control_GUID = .(0x84b783af, 0xd103, 0x4b0a, 0x84, 0x15, 0xe7, 0x39, 0x42, 0x41, 0x0f, 0x4b);
	public const Guid DataItem_Control_GUID = .(0xa0177842, 0xd94f, 0x42a5, 0x81, 0x4b, 0x60, 0x68, 0xad, 0xdc, 0x8d, 0xa5);
	public const Guid Document_Control_GUID = .(0x3cd6bb6f, 0x6f08, 0x4562, 0xb2, 0x29, 0xe4, 0xe2, 0xfc, 0x7a, 0x9e, 0xb4);
	public const Guid SplitButton_Control_GUID = .(0x7011f01f, 0x4ace, 0x4901, 0xb4, 0x61, 0x92, 0x0a, 0x6f, 0x1c, 0xa6, 0x50);
	public const Guid Window_Control_GUID = .(0xe13a7242, 0xf462, 0x4f4d, 0xae, 0xc1, 0x53, 0xb2, 0x8d, 0x6c, 0x32, 0x90);
	public const Guid Pane_Control_GUID = .(0x5c2b3f5b, 0x9182, 0x42a3, 0x8d, 0xec, 0x8c, 0x04, 0xc1, 0xee, 0x63, 0x4d);
	public const Guid Header_Control_GUID = .(0x5b90cbce, 0x78fb, 0x4614, 0x82, 0xb6, 0x55, 0x4d, 0x74, 0x71, 0x8e, 0x67);
	public const Guid HeaderItem_Control_GUID = .(0xe6bc12cb, 0x7c8e, 0x49cf, 0xb1, 0x68, 0x4a, 0x93, 0xa3, 0x2b, 0xeb, 0xb0);
	public const Guid Table_Control_GUID = .(0x773bfa0e, 0x5bc4, 0x4deb, 0x92, 0x1b, 0xde, 0x7b, 0x32, 0x06, 0x22, 0x9e);
	public const Guid TitleBar_Control_GUID = .(0x98aa55bf, 0x3bb0, 0x4b65, 0x83, 0x6e, 0x2e, 0xa3, 0x0d, 0xbc, 0x17, 0x1f);
	public const Guid Separator_Control_GUID = .(0x8767eba3, 0x2a63, 0x4ab0, 0xac, 0x8d, 0xaa, 0x50, 0xe2, 0x3d, 0xe9, 0x78);
	public const Guid SemanticZoom_Control_GUID = .(0x5fd34a43, 0x061e, 0x42c8, 0xb5, 0x89, 0x9d, 0xcc, 0xf7, 0x4b, 0xc4, 0x3a);
	public const Guid AppBar_Control_GUID = .(0x6114908d, 0xcc02, 0x4d37, 0x87, 0x5b, 0xb5, 0x30, 0xc7, 0x13, 0x95, 0x54);
	public const Guid Text_AnimationStyle_Attribute_GUID = .(0x628209f0, 0x7c9a, 0x4d57, 0xbe, 0x64, 0x1f, 0x18, 0x36, 0x57, 0x1f, 0xf5);
	public const Guid Text_BackgroundColor_Attribute_GUID = .(0xfdc49a07, 0x583d, 0x4f17, 0xad, 0x27, 0x77, 0xfc, 0x83, 0x2a, 0x3c, 0x0b);
	public const Guid Text_BulletStyle_Attribute_GUID = .(0xc1097c90, 0xd5c4, 0x4237, 0x97, 0x81, 0x3b, 0xec, 0x8b, 0xa5, 0x4e, 0x48);
	public const Guid Text_CapStyle_Attribute_GUID = .(0xfb059c50, 0x92cc, 0x49a5, 0xba, 0x8f, 0x0a, 0xa8, 0x72, 0xbb, 0xa2, 0xf3);
	public const Guid Text_Culture_Attribute_GUID = .(0xc2025af9, 0xa42d, 0x4ced, 0xa1, 0xfb, 0xc6, 0x74, 0x63, 0x15, 0x22, 0x2e);
	public const Guid Text_FontName_Attribute_GUID = .(0x64e63ba8, 0xf2e5, 0x476e, 0xa4, 0x77, 0x17, 0x34, 0xfe, 0xaa, 0xf7, 0x26);
	public const Guid Text_FontSize_Attribute_GUID = .(0xdc5eeeff, 0x0506, 0x4673, 0x93, 0xf2, 0x37, 0x7e, 0x4a, 0x8e, 0x01, 0xf1);
	public const Guid Text_FontWeight_Attribute_GUID = .(0x6fc02359, 0xb316, 0x4f5f, 0xb4, 0x01, 0xf1, 0xce, 0x55, 0x74, 0x18, 0x53);
	public const Guid Text_ForegroundColor_Attribute_GUID = .(0x72d1c95d, 0x5e60, 0x471a, 0x96, 0xb1, 0x6c, 0x1b, 0x3b, 0x77, 0xa4, 0x36);
	public const Guid Text_HorizontalTextAlignment_Attribute_GUID = .(0x04ea6161, 0xfba3, 0x477a, 0x95, 0x2a, 0xbb, 0x32, 0x6d, 0x02, 0x6a, 0x5b);
	public const Guid Text_IndentationFirstLine_Attribute_GUID = .(0x206f9ad5, 0xc1d3, 0x424a, 0x81, 0x82, 0x6d, 0xa9, 0xa7, 0xf3, 0xd6, 0x32);
	public const Guid Text_IndentationLeading_Attribute_GUID = .(0x5cf66bac, 0x2d45, 0x4a4b, 0xb6, 0xc9, 0xf7, 0x22, 0x1d, 0x28, 0x15, 0xb0);
	public const Guid Text_IndentationTrailing_Attribute_GUID = .(0x97ff6c0f, 0x1ce4, 0x408a, 0xb6, 0x7b, 0x94, 0xd8, 0x3e, 0xb6, 0x9b, 0xf2);
	public const Guid Text_IsHidden_Attribute_GUID = .(0x360182fb, 0xbdd7, 0x47f6, 0xab, 0x69, 0x19, 0xe3, 0x3f, 0x8a, 0x33, 0x44);
	public const Guid Text_IsItalic_Attribute_GUID = .(0xfce12a56, 0x1336, 0x4a34, 0x96, 0x63, 0x1b, 0xab, 0x47, 0x23, 0x93, 0x20);
	public const Guid Text_IsReadOnly_Attribute_GUID = .(0xa738156b, 0xca3e, 0x495e, 0x95, 0x14, 0x83, 0x3c, 0x44, 0x0f, 0xeb, 0x11);
	public const Guid Text_IsSubscript_Attribute_GUID = .(0xf0ead858, 0x8f53, 0x413c, 0x87, 0x3f, 0x1a, 0x7d, 0x7f, 0x5e, 0x0d, 0xe4);
	public const Guid Text_IsSuperscript_Attribute_GUID = .(0xda706ee4, 0xb3aa, 0x4645, 0xa4, 0x1f, 0xcd, 0x25, 0x15, 0x7d, 0xea, 0x76);
	public const Guid Text_MarginBottom_Attribute_GUID = .(0x7ee593c4, 0x72b4, 0x4cac, 0x92, 0x71, 0x3e, 0xd2, 0x4b, 0x0e, 0x4d, 0x42);
	public const Guid Text_MarginLeading_Attribute_GUID = .(0x9e9242d0, 0x5ed0, 0x4900, 0x8e, 0x8a, 0xee, 0xcc, 0x03, 0x83, 0x5a, 0xfc);
	public const Guid Text_MarginTop_Attribute_GUID = .(0x683d936f, 0xc9b9, 0x4a9a, 0xb3, 0xd9, 0xd2, 0x0d, 0x33, 0x31, 0x1e, 0x2a);
	public const Guid Text_MarginTrailing_Attribute_GUID = .(0xaf522f98, 0x999d, 0x40af, 0xa5, 0xb2, 0x01, 0x69, 0xd0, 0x34, 0x20, 0x02);
	public const Guid Text_OutlineStyles_Attribute_GUID = .(0x5b675b27, 0xdb89, 0x46fe, 0x97, 0x0c, 0x61, 0x4d, 0x52, 0x3b, 0xb9, 0x7d);
	public const Guid Text_OverlineColor_Attribute_GUID = .(0x83ab383a, 0xfd43, 0x40da, 0xab, 0x3e, 0xec, 0xf8, 0x16, 0x5c, 0xbb, 0x6d);
	public const Guid Text_OverlineStyle_Attribute_GUID = .(0x0a234d66, 0x617e, 0x427f, 0x87, 0x1d, 0xe1, 0xff, 0x1e, 0x0c, 0x21, 0x3f);
	public const Guid Text_StrikethroughColor_Attribute_GUID = .(0xbfe15a18, 0x8c41, 0x4c5a, 0x9a, 0x0b, 0x04, 0xaf, 0x0e, 0x07, 0xf4, 0x87);
	public const Guid Text_StrikethroughStyle_Attribute_GUID = .(0x72913ef1, 0xda00, 0x4f01, 0x89, 0x9c, 0xac, 0x5a, 0x85, 0x77, 0xa3, 0x07);
	public const Guid Text_Tabs_Attribute_GUID = .(0x2e68d00b, 0x92fe, 0x42d8, 0x89, 0x9a, 0xa7, 0x84, 0xaa, 0x44, 0x54, 0xa1);
	public const Guid Text_TextFlowDirections_Attribute_GUID = .(0x8bdf8739, 0xf420, 0x423e, 0xaf, 0x77, 0x20, 0xa5, 0xd9, 0x73, 0xa9, 0x07);
	public const Guid Text_UnderlineColor_Attribute_GUID = .(0xbfa12c73, 0xfde2, 0x4473, 0xbf, 0x64, 0x10, 0x36, 0xd6, 0xaa, 0x0f, 0x45);
	public const Guid Text_UnderlineStyle_Attribute_GUID = .(0x5f3b21c0, 0xede4, 0x44bd, 0x9c, 0x36, 0x38, 0x53, 0x03, 0x8c, 0xbf, 0xeb);
	public const Guid Text_AnnotationTypes_Attribute_GUID = .(0xad2eb431, 0xee4e, 0x4be1, 0xa7, 0xba, 0x55, 0x59, 0x15, 0x5a, 0x73, 0xef);
	public const Guid Text_AnnotationObjects_Attribute_GUID = .(0xff41cf68, 0xe7ab, 0x40b9, 0x8c, 0x72, 0x72, 0xa8, 0xed, 0x94, 0x01, 0x7d);
	public const Guid Text_StyleName_Attribute_GUID = .(0x22c9e091, 0x4d66, 0x45d8, 0xa8, 0x28, 0x73, 0x7b, 0xab, 0x4c, 0x98, 0xa7);
	public const Guid Text_StyleId_Attribute_GUID = .(0x14c300de, 0xc32b, 0x449b, 0xab, 0x7c, 0xb0, 0xe0, 0x78, 0x9a, 0xea, 0x5d);
	public const Guid Text_Link_Attribute_GUID = .(0xb38ef51d, 0x9e8d, 0x4e46, 0x91, 0x44, 0x56, 0xeb, 0xe1, 0x77, 0x32, 0x9b);
	public const Guid Text_IsActive_Attribute_GUID = .(0xf5a4e533, 0xe1b8, 0x436b, 0x93, 0x5d, 0xb5, 0x7a, 0xa3, 0xf5, 0x58, 0xc4);
	public const Guid Text_SelectionActiveEnd_Attribute_GUID = .(0x1f668cc3, 0x9bbf, 0x416b, 0xb0, 0xa2, 0xf8, 0x9f, 0x86, 0xf6, 0x61, 0x2c);
	public const Guid Text_CaretPosition_Attribute_GUID = .(0xb227b131, 0x9889, 0x4752, 0xa9, 0x1b, 0x73, 0x3e, 0xfd, 0xc5, 0xc5, 0xa0);
	public const Guid Text_CaretBidiMode_Attribute_GUID = .(0x929ee7a6, 0x51d3, 0x4715, 0x96, 0xdc, 0xb6, 0x94, 0xfa, 0x24, 0xa1, 0x68);
	public const Guid Text_BeforeParagraphSpacing_Attribute_GUID = .(0xbe7b0ab1, 0xc822, 0x4a24, 0x85, 0xe9, 0xc8, 0xf2, 0x65, 0x0f, 0xc7, 0x9c);
	public const Guid Text_AfterParagraphSpacing_Attribute_GUID = .(0x588cbb38, 0xe62f, 0x497c, 0xb5, 0xd1, 0xcc, 0xdf, 0x0e, 0xe8, 0x23, 0xd8);
	public const Guid Text_LineSpacing_Attribute_GUID = .(0x63ff70ae, 0xd943, 0x4b47, 0x8a, 0xb7, 0xa7, 0xa0, 0x33, 0xd3, 0x21, 0x4b);
	public const Guid Text_BeforeSpacing_Attribute_GUID = .(0xbe7b0ab1, 0xc822, 0x4a24, 0x85, 0xe9, 0xc8, 0xf2, 0x65, 0x0f, 0xc7, 0x9c);
	public const Guid Text_AfterSpacing_Attribute_GUID = .(0x588cbb38, 0xe62f, 0x497c, 0xb5, 0xd1, 0xcc, 0xdf, 0x0e, 0xe8, 0x23, 0xd8);
	public const Guid Text_SayAsInterpretAs_Attribute_GUID = .(0xb38ad6ac, 0xeee1, 0x4b6e, 0x88, 0xcc, 0x01, 0x4c, 0xef, 0xa9, 0x3f, 0xcb);
	public const Guid TextEdit_TextChanged_Event_GUID = .(0x120b0308, 0xec22, 0x4eb8, 0x9c, 0x98, 0x98, 0x67, 0xcd, 0xa1, 0xb1, 0x65);
	public const Guid TextEdit_ConversionTargetChanged_Event_GUID = .(0x3388c183, 0xed4f, 0x4c8b, 0x9b, 0xaa, 0x36, 0x4d, 0x51, 0xd8, 0x84, 0x7f);
	public const Guid Changes_Event_GUID = .(0x7df26714, 0x614f, 0x4e05, 0x94, 0x88, 0x71, 0x6c, 0x5b, 0xa1, 0x94, 0x36);
	public const Guid Annotation_Custom_GUID = .(0x9ec82750, 0x3931, 0x4952, 0x85, 0xbc, 0x1d, 0xbf, 0xf7, 0x8a, 0x43, 0xe3);
	public const Guid Annotation_SpellingError_GUID = .(0xae85567e, 0x9ece, 0x423f, 0x81, 0xb7, 0x96, 0xc4, 0x3d, 0x53, 0xe5, 0x0e);
	public const Guid Annotation_GrammarError_GUID = .(0x757a048d, 0x4518, 0x41c6, 0x85, 0x4c, 0xdc, 0x00, 0x9b, 0x7c, 0xfb, 0x53);
	public const Guid Annotation_Comment_GUID = .(0xfd2fda30, 0x26b3, 0x4c06, 0x8b, 0xc7, 0x98, 0xf1, 0x53, 0x2e, 0x46, 0xfd);
	public const Guid Annotation_FormulaError_GUID = .(0x95611982, 0x0cab, 0x46d5, 0xa2, 0xf0, 0xe3, 0x0d, 0x19, 0x05, 0xf8, 0xbf);
	public const Guid Annotation_TrackChanges_GUID = .(0x21e6e888, 0xdc14, 0x4016, 0xac, 0x27, 0x19, 0x05, 0x53, 0xc8, 0xc4, 0x70);
	public const Guid Annotation_Header_GUID = .(0x867b409b, 0xb216, 0x4472, 0xa2, 0x19, 0x52, 0x5e, 0x31, 0x06, 0x81, 0xf8);
	public const Guid Annotation_Footer_GUID = .(0xcceab046, 0x1833, 0x47aa, 0x80, 0x80, 0x70, 0x1e, 0xd0, 0xb0, 0xc8, 0x32);
	public const Guid Annotation_Highlighted_GUID = .(0x757c884e, 0x8083, 0x4081, 0x8b, 0x9c, 0xe8, 0x7f, 0x50, 0x72, 0xf0, 0xe4);
	public const Guid Annotation_Endnote_GUID = .(0x7565725c, 0x2d99, 0x4839, 0x96, 0x0d, 0x33, 0xd3, 0xb8, 0x66, 0xab, 0xa5);
	public const Guid Annotation_Footnote_GUID = .(0x3de10e21, 0x4125, 0x42db, 0x86, 0x20, 0xbe, 0x80, 0x83, 0x08, 0x06, 0x24);
	public const Guid Annotation_InsertionChange_GUID = .(0x0dbeb3a6, 0xdf15, 0x4164, 0xa3, 0xc0, 0xe2, 0x1a, 0x8c, 0xe9, 0x31, 0xc4);
	public const Guid Annotation_DeletionChange_GUID = .(0xbe3d5b05, 0x951d, 0x42e7, 0x90, 0x1d, 0xad, 0xc8, 0xc2, 0xcf, 0x34, 0xd0);
	public const Guid Annotation_MoveChange_GUID = .(0x9da587eb, 0x23e5, 0x4490, 0xb3, 0x85, 0x1a, 0x22, 0xdd, 0xc8, 0xb1, 0x87);
	public const Guid Annotation_FormatChange_GUID = .(0xeb247345, 0xd4f1, 0x41ce, 0x8e, 0x52, 0xf7, 0x9b, 0x69, 0x63, 0x5e, 0x48);
	public const Guid Annotation_UnsyncedChange_GUID = .(0x1851116a, 0x0e47, 0x4b30, 0x8c, 0xb5, 0xd7, 0xda, 0xe4, 0xfb, 0xcd, 0x1b);
	public const Guid Annotation_EditingLockedChange_GUID = .(0xc31f3e1c, 0x7423, 0x4dac, 0x83, 0x48, 0x41, 0xf0, 0x99, 0xff, 0x6f, 0x64);
	public const Guid Annotation_ExternalChange_GUID = .(0x75a05b31, 0x5f11, 0x42fd, 0x88, 0x7d, 0xdf, 0xa0, 0x10, 0xdb, 0x23, 0x92);
	public const Guid Annotation_ConflictingChange_GUID = .(0x98af8802, 0x517c, 0x459f, 0xaf, 0x13, 0x01, 0x6d, 0x3f, 0xab, 0x87, 0x7e);
	public const Guid Annotation_Author_GUID = .(0xf161d3a7, 0xf81b, 0x4128, 0xb1, 0x7f, 0x71, 0xf6, 0x90, 0x91, 0x45, 0x20);
	public const Guid Annotation_AdvancedProofingIssue_GUID = .(0xdac7b72c, 0xc0f2, 0x4b84, 0xb9, 0x0d, 0x5f, 0xaf, 0xc0, 0xf0, 0xef, 0x1c);
	public const Guid Annotation_DataValidationError_GUID = .(0xc8649fa8, 0x9775, 0x437e, 0xad, 0x46, 0xe7, 0x09, 0xd9, 0x3c, 0x23, 0x43);
	public const Guid Annotation_CircularReferenceError_GUID = .(0x25bd9cf4, 0x1745, 0x4659, 0xba, 0x67, 0x72, 0x7f, 0x03, 0x18, 0xc6, 0x16);
	public const Guid Annotation_Mathematics_GUID = .(0xeaab634b, 0x26d0, 0x40c1, 0x80, 0x73, 0x57, 0xca, 0x1c, 0x63, 0x3c, 0x9b);
	public const Guid Annotation_Sensitive_GUID = .(0x37f4c04f, 0x0f12, 0x4464, 0x92, 0x9c, 0x82, 0x8f, 0xd1, 0x52, 0x92, 0xe3);
	public const Guid Changes_Summary_GUID = .(0x313d65a6, 0xe60f, 0x4d62, 0x98, 0x61, 0x55, 0xaf, 0xd7, 0x28, 0xd2, 0x07);
	public const Guid StyleId_Custom_GUID = .(0xef2edd3e, 0xa999, 0x4b7c, 0xa3, 0x78, 0x09, 0xbb, 0xd5, 0x2a, 0x35, 0x16);
	public const Guid StyleId_Heading1_GUID = .(0x7f7e8f69, 0x6866, 0x4621, 0x93, 0x0c, 0x9a, 0x5d, 0x0c, 0xa5, 0x96, 0x1c);
	public const Guid StyleId_Heading2_GUID = .(0xbaa9b241, 0x5c69, 0x469d, 0x85, 0xad, 0x47, 0x47, 0x37, 0xb5, 0x2b, 0x14);
	public const Guid StyleId_Heading3_GUID = .(0xbf8be9d2, 0xd8b8, 0x4ec5, 0x8c, 0x52, 0x9c, 0xfb, 0x0d, 0x03, 0x59, 0x70);
	public const Guid StyleId_Heading4_GUID = .(0x8436ffc0, 0x9578, 0x45fc, 0x83, 0xa4, 0xff, 0x40, 0x05, 0x33, 0x15, 0xdd);
	public const Guid StyleId_Heading5_GUID = .(0x909f424d, 0x0dbf, 0x406e, 0x97, 0xbb, 0x4e, 0x77, 0x3d, 0x97, 0x98, 0xf7);
	public const Guid StyleId_Heading6_GUID = .(0x89d23459, 0x5d5b, 0x4824, 0xa4, 0x20, 0x11, 0xd3, 0xed, 0x82, 0xe4, 0x0f);
	public const Guid StyleId_Heading7_GUID = .(0xa3790473, 0xe9ae, 0x422d, 0xb8, 0xe3, 0x3b, 0x67, 0x5c, 0x61, 0x81, 0xa4);
	public const Guid StyleId_Heading8_GUID = .(0x2bc14145, 0xa40c, 0x4881, 0x84, 0xae, 0xf2, 0x23, 0x56, 0x85, 0x38, 0x0c);
	public const Guid StyleId_Heading9_GUID = .(0xc70d9133, 0xbb2a, 0x43d3, 0x8a, 0xc6, 0x33, 0x65, 0x78, 0x84, 0xb0, 0xf0);
	public const Guid StyleId_Title_GUID = .(0x15d8201a, 0xffcf, 0x481f, 0xb0, 0xa1, 0x30, 0xb6, 0x3b, 0xe9, 0x8f, 0x07);
	public const Guid StyleId_Subtitle_GUID = .(0xb5d9fc17, 0x5d6f, 0x4420, 0xb4, 0x39, 0x7c, 0xb1, 0x9a, 0xd4, 0x34, 0xe2);
	public const Guid StyleId_Normal_GUID = .(0xcd14d429, 0xe45e, 0x4475, 0xa1, 0xc5, 0x7f, 0x9e, 0x6b, 0xe9, 0x6e, 0xba);
	public const Guid StyleId_Emphasis_GUID = .(0xca6e7dbe, 0x355e, 0x4820, 0x95, 0xa0, 0x92, 0x5f, 0x04, 0x1d, 0x34, 0x70);
	public const Guid StyleId_Quote_GUID = .(0x5d1c21ea, 0x8195, 0x4f6c, 0x87, 0xea, 0x5d, 0xab, 0xec, 0xe6, 0x4c, 0x1d);
	public const Guid StyleId_BulletedList_GUID = .(0x5963ed64, 0x6426, 0x4632, 0x8c, 0xaf, 0xa3, 0x2a, 0xd4, 0x02, 0xd9, 0x1a);
	public const Guid StyleId_NumberedList_GUID = .(0x1e96dbd5, 0x64c3, 0x43d0, 0xb1, 0xee, 0xb5, 0x3b, 0x06, 0xe3, 0xed, 0xdf);
	public const Guid Notification_Event_GUID = .(0x72c5a2f7, 0x9788, 0x480f, 0xb8, 0xeb, 0x4d, 0xee, 0x00, 0xf6, 0x18, 0x6f);
	public const Guid SID_IsUIAutomationObject = .(0xb96fdb85, 0x7204, 0x4724, 0x84, 0x2b, 0xc7, 0x05, 0x9d, 0xed, 0xb9, 0xd0);
	public const Guid SID_ControlElementProvider = .(0xf4791d68, 0xe254, 0x4ba3, 0x9a, 0x53, 0x26, 0xa5, 0xc5, 0x49, 0x79, 0x46);
	public const Guid IsSelectionPattern2Available_Property_GUID = .(0x490806fb, 0x6e89, 0x4a47, 0x83, 0x19, 0xd2, 0x66, 0xe5, 0x11, 0xf0, 0x21);
	public const Guid Selection2_FirstSelectedItem_Property_GUID = .(0xcc24ea67, 0x369c, 0x4e55, 0x9f, 0xf7, 0x38, 0xda, 0x69, 0x54, 0x0c, 0x29);
	public const Guid Selection2_LastSelectedItem_Property_GUID = .(0xcf7bda90, 0x2d83, 0x49f8, 0x86, 0x0c, 0x9c, 0xe3, 0x94, 0xcf, 0x89, 0xb4);
	public const Guid Selection2_CurrentSelectedItem_Property_GUID = .(0x34257c26, 0x83b5, 0x41a6, 0x93, 0x9c, 0xae, 0x84, 0x1c, 0x13, 0x62, 0x36);
	public const Guid Selection2_ItemCount_Property_GUID = .(0xbb49eb9f, 0x456d, 0x4048, 0xb5, 0x91, 0x9c, 0x20, 0x26, 0xb8, 0x46, 0x36);
	public const Guid Selection_Pattern2_GUID = .(0xfba25cab, 0xab98, 0x49f7, 0xa7, 0xdc, 0xfe, 0x53, 0x9d, 0xc1, 0x5b, 0xe7);
	public const Guid HeadingLevel_Property_GUID = .(0x29084272, 0xaaaf, 0x4a30, 0x87, 0x96, 0x3c, 0x12, 0xf6, 0x2b, 0x6b, 0xbb);
	public const Guid IsDialog_Property_GUID = .(0x9d0dfb9b, 0x8436, 0x4501, 0xbb, 0xbb, 0xe5, 0x34, 0xa4, 0xfb, 0x3b, 0x3f);
	public const uint32 UIA_IAFP_DEFAULT = 0;
	public const uint32 UIA_IAFP_UNWRAP_BRIDGE = 1;
	public const uint32 UIA_PFIA_DEFAULT = 0;
	public const uint32 UIA_PFIA_UNWRAP_BRIDGE = 1;
	public const double UIA_ScrollPatternNoScroll = -1;
}
#endregion

#region TypeDefs
typealias HWINEVENTHOOK = int;

typealias HUIANODE = int;

typealias HUIAPATTERNOBJECT = int;

typealias HUIATEXTRANGE = int;

typealias HUIAEVENT = int;

#endregion


#region Enums

[AllowDuplicates]
public enum UIA_TEXTATTRIBUTE_ID : uint32
{
	UIA_AnimationStyleAttributeId = 40000,
	UIA_BackgroundColorAttributeId = 40001,
	UIA_BulletStyleAttributeId = 40002,
	UIA_CapStyleAttributeId = 40003,
	UIA_CultureAttributeId = 40004,
	UIA_FontNameAttributeId = 40005,
	UIA_FontSizeAttributeId = 40006,
	UIA_FontWeightAttributeId = 40007,
	UIA_ForegroundColorAttributeId = 40008,
	UIA_HorizontalTextAlignmentAttributeId = 40009,
	UIA_IndentationFirstLineAttributeId = 40010,
	UIA_IndentationLeadingAttributeId = 40011,
	UIA_IndentationTrailingAttributeId = 40012,
	UIA_IsHiddenAttributeId = 40013,
	UIA_IsItalicAttributeId = 40014,
	UIA_IsReadOnlyAttributeId = 40015,
	UIA_IsSubscriptAttributeId = 40016,
	UIA_IsSuperscriptAttributeId = 40017,
	UIA_MarginBottomAttributeId = 40018,
	UIA_MarginLeadingAttributeId = 40019,
	UIA_MarginTopAttributeId = 40020,
	UIA_MarginTrailingAttributeId = 40021,
	UIA_OutlineStylesAttributeId = 40022,
	UIA_OverlineColorAttributeId = 40023,
	UIA_OverlineStyleAttributeId = 40024,
	UIA_StrikethroughColorAttributeId = 40025,
	UIA_StrikethroughStyleAttributeId = 40026,
	UIA_TabsAttributeId = 40027,
	UIA_TextFlowDirectionsAttributeId = 40028,
	UIA_UnderlineColorAttributeId = 40029,
	UIA_UnderlineStyleAttributeId = 40030,
	UIA_AnnotationTypesAttributeId = 40031,
	UIA_AnnotationObjectsAttributeId = 40032,
	UIA_StyleNameAttributeId = 40033,
	UIA_StyleIdAttributeId = 40034,
	UIA_LinkAttributeId = 40035,
	UIA_IsActiveAttributeId = 40036,
	UIA_SelectionActiveEndAttributeId = 40037,
	UIA_CaretPositionAttributeId = 40038,
	UIA_CaretBidiModeAttributeId = 40039,
	UIA_LineSpacingAttributeId = 40040,
	UIA_BeforeParagraphSpacingAttributeId = 40041,
	UIA_AfterParagraphSpacingAttributeId = 40042,
	UIA_SayAsInterpretAsAttributeId = 40043,
}


[AllowDuplicates]
public enum UIA_CONTROLTYPE_ID : uint32
{
	UIA_ButtonControlTypeId = 50000,
	UIA_CalendarControlTypeId = 50001,
	UIA_CheckBoxControlTypeId = 50002,
	UIA_ComboBoxControlTypeId = 50003,
	UIA_EditControlTypeId = 50004,
	UIA_HyperlinkControlTypeId = 50005,
	UIA_ImageControlTypeId = 50006,
	UIA_ListItemControlTypeId = 50007,
	UIA_ListControlTypeId = 50008,
	UIA_MenuControlTypeId = 50009,
	UIA_MenuBarControlTypeId = 50010,
	UIA_MenuItemControlTypeId = 50011,
	UIA_ProgressBarControlTypeId = 50012,
	UIA_RadioButtonControlTypeId = 50013,
	UIA_ScrollBarControlTypeId = 50014,
	UIA_SliderControlTypeId = 50015,
	UIA_SpinnerControlTypeId = 50016,
	UIA_StatusBarControlTypeId = 50017,
	UIA_TabControlTypeId = 50018,
	UIA_TabItemControlTypeId = 50019,
	UIA_TextControlTypeId = 50020,
	UIA_ToolBarControlTypeId = 50021,
	UIA_ToolTipControlTypeId = 50022,
	UIA_TreeControlTypeId = 50023,
	UIA_TreeItemControlTypeId = 50024,
	UIA_CustomControlTypeId = 50025,
	UIA_GroupControlTypeId = 50026,
	UIA_ThumbControlTypeId = 50027,
	UIA_DataGridControlTypeId = 50028,
	UIA_DataItemControlTypeId = 50029,
	UIA_DocumentControlTypeId = 50030,
	UIA_SplitButtonControlTypeId = 50031,
	UIA_WindowControlTypeId = 50032,
	UIA_PaneControlTypeId = 50033,
	UIA_HeaderControlTypeId = 50034,
	UIA_HeaderItemControlTypeId = 50035,
	UIA_TableControlTypeId = 50036,
	UIA_TitleBarControlTypeId = 50037,
	UIA_SeparatorControlTypeId = 50038,
	UIA_SemanticZoomControlTypeId = 50039,
	UIA_AppBarControlTypeId = 50040,
}


[AllowDuplicates]
public enum UIA_ANNOTATIONTYPE : uint32
{
	AnnotationType_Unknown = 60000,
	AnnotationType_SpellingError = 60001,
	AnnotationType_GrammarError = 60002,
	AnnotationType_Comment = 60003,
	AnnotationType_FormulaError = 60004,
	AnnotationType_TrackChanges = 60005,
	AnnotationType_Header = 60006,
	AnnotationType_Footer = 60007,
	AnnotationType_Highlighted = 60008,
	AnnotationType_Endnote = 60009,
	AnnotationType_Footnote = 60010,
	AnnotationType_InsertionChange = 60011,
	AnnotationType_DeletionChange = 60012,
	AnnotationType_MoveChange = 60013,
	AnnotationType_FormatChange = 60014,
	AnnotationType_UnsyncedChange = 60015,
	AnnotationType_EditingLockedChange = 60016,
	AnnotationType_ExternalChange = 60017,
	AnnotationType_ConflictingChange = 60018,
	AnnotationType_Author = 60019,
	AnnotationType_AdvancedProofingIssue = 60020,
	AnnotationType_DataValidationError = 60021,
	AnnotationType_CircularReferenceError = 60022,
	AnnotationType_Mathematics = 60023,
	AnnotationType_Sensitive = 60024,
}


[AllowDuplicates]
public enum UIA_STYLE_ID : uint32
{
	StyleId_Custom = 70000,
	StyleId_Heading1 = 70001,
	StyleId_Heading2 = 70002,
	StyleId_Heading3 = 70003,
	StyleId_Heading4 = 70004,
	StyleId_Heading5 = 70005,
	StyleId_Heading6 = 70006,
	StyleId_Heading7 = 70007,
	StyleId_Heading8 = 70008,
	StyleId_Heading9 = 70009,
	StyleId_Title = 70010,
	StyleId_Subtitle = 70011,
	StyleId_Normal = 70012,
	StyleId_Emphasis = 70013,
	StyleId_Quote = 70014,
	StyleId_BulletedList = 70015,
	StyleId_NumberedList = 70016,
}


[AllowDuplicates]
public enum UIA_LANDMARKTYPE_ID : uint32
{
	UIA_CustomLandmarkTypeId = 80000,
	UIA_FormLandmarkTypeId = 80001,
	UIA_MainLandmarkTypeId = 80002,
	UIA_NavigationLandmarkTypeId = 80003,
	UIA_SearchLandmarkTypeId = 80004,
}


[AllowDuplicates]
public enum UIA_HEADINGLEVEL_ID : uint32
{
	HeadingLevel_None = 80050,
	HeadingLevel1 = 80051,
	HeadingLevel2 = 80052,
	HeadingLevel3 = 80053,
	HeadingLevel4 = 80054,
	HeadingLevel5 = 80055,
	HeadingLevel6 = 80056,
	HeadingLevel7 = 80057,
	HeadingLevel8 = 80058,
	HeadingLevel9 = 80059,
}


[AllowDuplicates]
public enum UIA_CHANGE_ID : uint32
{
	UIA_SummaryChangeId = 90000,
}


[AllowDuplicates]
public enum UIA_METADATA_ID : uint32
{
	UIA_SayAsInterpretAsMetadataId = 100000,
}


[AllowDuplicates]
public enum STICKYKEYS_FLAGS : uint32
{
	SKF_STICKYKEYSON = 1,
	SKF_AVAILABLE = 2,
	SKF_HOTKEYACTIVE = 4,
	SKF_CONFIRMHOTKEY = 8,
	SKF_HOTKEYSOUND = 16,
	SKF_INDICATOR = 32,
	SKF_AUDIBLEFEEDBACK = 64,
	SKF_TRISTATE = 128,
	SKF_TWOKEYSOFF = 256,
	SKF_LALTLATCHED = 268435456,
	SKF_LCTLLATCHED = 67108864,
	SKF_LSHIFTLATCHED = 16777216,
	SKF_RALTLATCHED = 536870912,
	SKF_RCTLLATCHED = 134217728,
	SKF_RSHIFTLATCHED = 33554432,
	SKF_LWINLATCHED = 1073741824,
	SKF_RWINLATCHED = 2147483648,
	SKF_LALTLOCKED = 1048576,
	SKF_LCTLLOCKED = 262144,
	SKF_LSHIFTLOCKED = 65536,
	SKF_RALTLOCKED = 2097152,
	SKF_RCTLLOCKED = 524288,
	SKF_RSHIFTLOCKED = 131072,
	SKF_LWINLOCKED = 4194304,
	SKF_RWINLOCKED = 8388608,
}


[AllowDuplicates]
public enum SOUNDSENTRY_FLAGS : uint32
{
	SSF_SOUNDSENTRYON = 1,
	SSF_AVAILABLE = 2,
	SSF_INDICATOR = 4,
}


[AllowDuplicates]
public enum ACC_UTILITY_STATE_FLAGS : uint32
{
	ANRUS_ON_SCREEN_KEYBOARD_ACTIVE = 1,
	ANRUS_TOUCH_MODIFICATION_ACTIVE = 2,
	ANRUS_PRIORITY_AUDIO_ACTIVE = 4,
	ANRUS_PRIORITY_AUDIO_ACTIVE_NODUCK = 8,
}


[AllowDuplicates]
public enum SOUND_SENTRY_GRAPHICS_EFFECT : uint32
{
	SSGF_DISPLAY = 3,
	SSGF_NONE = 0,
}


[AllowDuplicates]
public enum SERIALKEYS_FLAGS : uint32
{
	SERKF_AVAILABLE = 2,
	SERKF_INDICATOR = 4,
	SERKF_SERIALKEYSON = 1,
}


[AllowDuplicates]
public enum HIGHCONTRASTW_FLAGS : uint32
{
	HCF_HIGHCONTRASTON = 1,
	HCF_AVAILABLE = 2,
	HCF_HOTKEYACTIVE = 4,
	HCF_CONFIRMHOTKEY = 8,
	HCF_HOTKEYSOUND = 16,
	HCF_INDICATOR = 32,
	HCF_HOTKEYAVAILABLE = 64,
	HCF_OPTION_NOTHEMECHANGE = 4096,
}


[AllowDuplicates]
public enum SOUNDSENTRY_TEXT_EFFECT : uint32
{
	SSTF_BORDER = 2,
	SSTF_CHARS = 1,
	SSTF_DISPLAY = 3,
	SSTF_NONE = 0,
}


[AllowDuplicates]
public enum SOUNDSENTRY_WINDOWS_EFFECT : uint32
{
	SSWF_CUSTOM = 4,
	SSWF_DISPLAY = 3,
	SSWF_NONE = 0,
	SSWF_TITLE = 1,
	SSWF_WINDOW = 2,
}


[AllowDuplicates]
public enum UIA_PATTERN_ID : uint32
{
	UIA_InvokePatternId = 10000,
	UIA_SelectionPatternId = 10001,
	UIA_ValuePatternId = 10002,
	UIA_RangeValuePatternId = 10003,
	UIA_ScrollPatternId = 10004,
	UIA_ExpandCollapsePatternId = 10005,
	UIA_GridPatternId = 10006,
	UIA_GridItemPatternId = 10007,
	UIA_MultipleViewPatternId = 10008,
	UIA_WindowPatternId = 10009,
	UIA_SelectionItemPatternId = 10010,
	UIA_DockPatternId = 10011,
	UIA_TablePatternId = 10012,
	UIA_TableItemPatternId = 10013,
	UIA_TextPatternId = 10014,
	UIA_TogglePatternId = 10015,
	UIA_TransformPatternId = 10016,
	UIA_ScrollItemPatternId = 10017,
	UIA_LegacyIAccessiblePatternId = 10018,
	UIA_ItemContainerPatternId = 10019,
	UIA_VirtualizedItemPatternId = 10020,
	UIA_SynchronizedInputPatternId = 10021,
	UIA_ObjectModelPatternId = 10022,
	UIA_AnnotationPatternId = 10023,
	UIA_TextPattern2Id = 10024,
	UIA_StylesPatternId = 10025,
	UIA_SpreadsheetPatternId = 10026,
	UIA_SpreadsheetItemPatternId = 10027,
	UIA_TransformPattern2Id = 10028,
	UIA_TextChildPatternId = 10029,
	UIA_DragPatternId = 10030,
	UIA_DropTargetPatternId = 10031,
	UIA_TextEditPatternId = 10032,
	UIA_CustomNavigationPatternId = 10033,
	UIA_SelectionPattern2Id = 10034,
}


[AllowDuplicates]
public enum UIA_EVENT_ID : uint32
{
	UIA_ToolTipOpenedEventId = 20000,
	UIA_ToolTipClosedEventId = 20001,
	UIA_StructureChangedEventId = 20002,
	UIA_MenuOpenedEventId = 20003,
	UIA_AutomationPropertyChangedEventId = 20004,
	UIA_AutomationFocusChangedEventId = 20005,
	UIA_AsyncContentLoadedEventId = 20006,
	UIA_MenuClosedEventId = 20007,
	UIA_LayoutInvalidatedEventId = 20008,
	UIA_Invoke_InvokedEventId = 20009,
	UIA_SelectionItem_ElementAddedToSelectionEventId = 20010,
	UIA_SelectionItem_ElementRemovedFromSelectionEventId = 20011,
	UIA_SelectionItem_ElementSelectedEventId = 20012,
	UIA_Selection_InvalidatedEventId = 20013,
	UIA_Text_TextSelectionChangedEventId = 20014,
	UIA_Text_TextChangedEventId = 20015,
	UIA_Window_WindowOpenedEventId = 20016,
	UIA_Window_WindowClosedEventId = 20017,
	UIA_MenuModeStartEventId = 20018,
	UIA_MenuModeEndEventId = 20019,
	UIA_InputReachedTargetEventId = 20020,
	UIA_InputReachedOtherElementEventId = 20021,
	UIA_InputDiscardedEventId = 20022,
	UIA_SystemAlertEventId = 20023,
	UIA_LiveRegionChangedEventId = 20024,
	UIA_HostedFragmentRootsInvalidatedEventId = 20025,
	UIA_Drag_DragStartEventId = 20026,
	UIA_Drag_DragCancelEventId = 20027,
	UIA_Drag_DragCompleteEventId = 20028,
	UIA_DropTarget_DragEnterEventId = 20029,
	UIA_DropTarget_DragLeaveEventId = 20030,
	UIA_DropTarget_DroppedEventId = 20031,
	UIA_TextEdit_TextChangedEventId = 20032,
	UIA_TextEdit_ConversionTargetChangedEventId = 20033,
	UIA_ChangesEventId = 20034,
	UIA_NotificationEventId = 20035,
	UIA_ActiveTextPositionChangedEventId = 20036,
}


[AllowDuplicates]
public enum UIA_PROPERTY_ID : uint32
{
	UIA_RuntimeIdPropertyId = 30000,
	UIA_BoundingRectanglePropertyId = 30001,
	UIA_ProcessIdPropertyId = 30002,
	UIA_ControlTypePropertyId = 30003,
	UIA_LocalizedControlTypePropertyId = 30004,
	UIA_NamePropertyId = 30005,
	UIA_AcceleratorKeyPropertyId = 30006,
	UIA_AccessKeyPropertyId = 30007,
	UIA_HasKeyboardFocusPropertyId = 30008,
	UIA_IsKeyboardFocusablePropertyId = 30009,
	UIA_IsEnabledPropertyId = 30010,
	UIA_AutomationIdPropertyId = 30011,
	UIA_ClassNamePropertyId = 30012,
	UIA_HelpTextPropertyId = 30013,
	UIA_ClickablePointPropertyId = 30014,
	UIA_CulturePropertyId = 30015,
	UIA_IsControlElementPropertyId = 30016,
	UIA_IsContentElementPropertyId = 30017,
	UIA_LabeledByPropertyId = 30018,
	UIA_IsPasswordPropertyId = 30019,
	UIA_NativeWindowHandlePropertyId = 30020,
	UIA_ItemTypePropertyId = 30021,
	UIA_IsOffscreenPropertyId = 30022,
	UIA_OrientationPropertyId = 30023,
	UIA_FrameworkIdPropertyId = 30024,
	UIA_IsRequiredForFormPropertyId = 30025,
	UIA_ItemStatusPropertyId = 30026,
	UIA_IsDockPatternAvailablePropertyId = 30027,
	UIA_IsExpandCollapsePatternAvailablePropertyId = 30028,
	UIA_IsGridItemPatternAvailablePropertyId = 30029,
	UIA_IsGridPatternAvailablePropertyId = 30030,
	UIA_IsInvokePatternAvailablePropertyId = 30031,
	UIA_IsMultipleViewPatternAvailablePropertyId = 30032,
	UIA_IsRangeValuePatternAvailablePropertyId = 30033,
	UIA_IsScrollPatternAvailablePropertyId = 30034,
	UIA_IsScrollItemPatternAvailablePropertyId = 30035,
	UIA_IsSelectionItemPatternAvailablePropertyId = 30036,
	UIA_IsSelectionPatternAvailablePropertyId = 30037,
	UIA_IsTablePatternAvailablePropertyId = 30038,
	UIA_IsTableItemPatternAvailablePropertyId = 30039,
	UIA_IsTextPatternAvailablePropertyId = 30040,
	UIA_IsTogglePatternAvailablePropertyId = 30041,
	UIA_IsTransformPatternAvailablePropertyId = 30042,
	UIA_IsValuePatternAvailablePropertyId = 30043,
	UIA_IsWindowPatternAvailablePropertyId = 30044,
	UIA_ValueValuePropertyId = 30045,
	UIA_ValueIsReadOnlyPropertyId = 30046,
	UIA_RangeValueValuePropertyId = 30047,
	UIA_RangeValueIsReadOnlyPropertyId = 30048,
	UIA_RangeValueMinimumPropertyId = 30049,
	UIA_RangeValueMaximumPropertyId = 30050,
	UIA_RangeValueLargeChangePropertyId = 30051,
	UIA_RangeValueSmallChangePropertyId = 30052,
	UIA_ScrollHorizontalScrollPercentPropertyId = 30053,
	UIA_ScrollHorizontalViewSizePropertyId = 30054,
	UIA_ScrollVerticalScrollPercentPropertyId = 30055,
	UIA_ScrollVerticalViewSizePropertyId = 30056,
	UIA_ScrollHorizontallyScrollablePropertyId = 30057,
	UIA_ScrollVerticallyScrollablePropertyId = 30058,
	UIA_SelectionSelectionPropertyId = 30059,
	UIA_SelectionCanSelectMultiplePropertyId = 30060,
	UIA_SelectionIsSelectionRequiredPropertyId = 30061,
	UIA_GridRowCountPropertyId = 30062,
	UIA_GridColumnCountPropertyId = 30063,
	UIA_GridItemRowPropertyId = 30064,
	UIA_GridItemColumnPropertyId = 30065,
	UIA_GridItemRowSpanPropertyId = 30066,
	UIA_GridItemColumnSpanPropertyId = 30067,
	UIA_GridItemContainingGridPropertyId = 30068,
	UIA_DockDockPositionPropertyId = 30069,
	UIA_ExpandCollapseExpandCollapseStatePropertyId = 30070,
	UIA_MultipleViewCurrentViewPropertyId = 30071,
	UIA_MultipleViewSupportedViewsPropertyId = 30072,
	UIA_WindowCanMaximizePropertyId = 30073,
	UIA_WindowCanMinimizePropertyId = 30074,
	UIA_WindowWindowVisualStatePropertyId = 30075,
	UIA_WindowWindowInteractionStatePropertyId = 30076,
	UIA_WindowIsModalPropertyId = 30077,
	UIA_WindowIsTopmostPropertyId = 30078,
	UIA_SelectionItemIsSelectedPropertyId = 30079,
	UIA_SelectionItemSelectionContainerPropertyId = 30080,
	UIA_TableRowHeadersPropertyId = 30081,
	UIA_TableColumnHeadersPropertyId = 30082,
	UIA_TableRowOrColumnMajorPropertyId = 30083,
	UIA_TableItemRowHeaderItemsPropertyId = 30084,
	UIA_TableItemColumnHeaderItemsPropertyId = 30085,
	UIA_ToggleToggleStatePropertyId = 30086,
	UIA_TransformCanMovePropertyId = 30087,
	UIA_TransformCanResizePropertyId = 30088,
	UIA_TransformCanRotatePropertyId = 30089,
	UIA_IsLegacyIAccessiblePatternAvailablePropertyId = 30090,
	UIA_LegacyIAccessibleChildIdPropertyId = 30091,
	UIA_LegacyIAccessibleNamePropertyId = 30092,
	UIA_LegacyIAccessibleValuePropertyId = 30093,
	UIA_LegacyIAccessibleDescriptionPropertyId = 30094,
	UIA_LegacyIAccessibleRolePropertyId = 30095,
	UIA_LegacyIAccessibleStatePropertyId = 30096,
	UIA_LegacyIAccessibleHelpPropertyId = 30097,
	UIA_LegacyIAccessibleKeyboardShortcutPropertyId = 30098,
	UIA_LegacyIAccessibleSelectionPropertyId = 30099,
	UIA_LegacyIAccessibleDefaultActionPropertyId = 30100,
	UIA_AriaRolePropertyId = 30101,
	UIA_AriaPropertiesPropertyId = 30102,
	UIA_IsDataValidForFormPropertyId = 30103,
	UIA_ControllerForPropertyId = 30104,
	UIA_DescribedByPropertyId = 30105,
	UIA_FlowsToPropertyId = 30106,
	UIA_ProviderDescriptionPropertyId = 30107,
	UIA_IsItemContainerPatternAvailablePropertyId = 30108,
	UIA_IsVirtualizedItemPatternAvailablePropertyId = 30109,
	UIA_IsSynchronizedInputPatternAvailablePropertyId = 30110,
	UIA_OptimizeForVisualContentPropertyId = 30111,
	UIA_IsObjectModelPatternAvailablePropertyId = 30112,
	UIA_AnnotationAnnotationTypeIdPropertyId = 30113,
	UIA_AnnotationAnnotationTypeNamePropertyId = 30114,
	UIA_AnnotationAuthorPropertyId = 30115,
	UIA_AnnotationDateTimePropertyId = 30116,
	UIA_AnnotationTargetPropertyId = 30117,
	UIA_IsAnnotationPatternAvailablePropertyId = 30118,
	UIA_IsTextPattern2AvailablePropertyId = 30119,
	UIA_StylesStyleIdPropertyId = 30120,
	UIA_StylesStyleNamePropertyId = 30121,
	UIA_StylesFillColorPropertyId = 30122,
	UIA_StylesFillPatternStylePropertyId = 30123,
	UIA_StylesShapePropertyId = 30124,
	UIA_StylesFillPatternColorPropertyId = 30125,
	UIA_StylesExtendedPropertiesPropertyId = 30126,
	UIA_IsStylesPatternAvailablePropertyId = 30127,
	UIA_IsSpreadsheetPatternAvailablePropertyId = 30128,
	UIA_SpreadsheetItemFormulaPropertyId = 30129,
	UIA_SpreadsheetItemAnnotationObjectsPropertyId = 30130,
	UIA_SpreadsheetItemAnnotationTypesPropertyId = 30131,
	UIA_IsSpreadsheetItemPatternAvailablePropertyId = 30132,
	UIA_Transform2CanZoomPropertyId = 30133,
	UIA_IsTransformPattern2AvailablePropertyId = 30134,
	UIA_LiveSettingPropertyId = 30135,
	UIA_IsTextChildPatternAvailablePropertyId = 30136,
	UIA_IsDragPatternAvailablePropertyId = 30137,
	UIA_DragIsGrabbedPropertyId = 30138,
	UIA_DragDropEffectPropertyId = 30139,
	UIA_DragDropEffectsPropertyId = 30140,
	UIA_IsDropTargetPatternAvailablePropertyId = 30141,
	UIA_DropTargetDropTargetEffectPropertyId = 30142,
	UIA_DropTargetDropTargetEffectsPropertyId = 30143,
	UIA_DragGrabbedItemsPropertyId = 30144,
	UIA_Transform2ZoomLevelPropertyId = 30145,
	UIA_Transform2ZoomMinimumPropertyId = 30146,
	UIA_Transform2ZoomMaximumPropertyId = 30147,
	UIA_FlowsFromPropertyId = 30148,
	UIA_IsTextEditPatternAvailablePropertyId = 30149,
	UIA_IsPeripheralPropertyId = 30150,
	UIA_IsCustomNavigationPatternAvailablePropertyId = 30151,
	UIA_PositionInSetPropertyId = 30152,
	UIA_SizeOfSetPropertyId = 30153,
	UIA_LevelPropertyId = 30154,
	UIA_AnnotationTypesPropertyId = 30155,
	UIA_AnnotationObjectsPropertyId = 30156,
	UIA_LandmarkTypePropertyId = 30157,
	UIA_LocalizedLandmarkTypePropertyId = 30158,
	UIA_FullDescriptionPropertyId = 30159,
	UIA_FillColorPropertyId = 30160,
	UIA_OutlineColorPropertyId = 30161,
	UIA_FillTypePropertyId = 30162,
	UIA_VisualEffectsPropertyId = 30163,
	UIA_OutlineThicknessPropertyId = 30164,
	UIA_CenterPointPropertyId = 30165,
	UIA_RotationPropertyId = 30166,
	UIA_SizePropertyId = 30167,
	UIA_IsSelectionPattern2AvailablePropertyId = 30168,
	UIA_Selection2FirstSelectedItemPropertyId = 30169,
	UIA_Selection2LastSelectedItemPropertyId = 30170,
	UIA_Selection2CurrentSelectedItemPropertyId = 30171,
	UIA_Selection2ItemCountPropertyId = 30172,
	UIA_HeadingLevelPropertyId = 30173,
	UIA_IsDialogPropertyId = 30174,
}


[AllowDuplicates]
public enum AnnoScope : int32
{
	ANNO_THIS = 0,
	ANNO_CONTAINER = 1,
}


[AllowDuplicates]
public enum NavigateDirection : int32
{
	NavigateDirection_Parent = 0,
	NavigateDirection_NextSibling = 1,
	NavigateDirection_PreviousSibling = 2,
	NavigateDirection_FirstChild = 3,
	NavigateDirection_LastChild = 4,
}


[AllowDuplicates]
public enum ProviderOptions : int32
{
	ProviderOptions_ClientSideProvider = 1,
	ProviderOptions_ServerSideProvider = 2,
	ProviderOptions_NonClientAreaProvider = 4,
	ProviderOptions_OverrideProvider = 8,
	ProviderOptions_ProviderOwnsSetFocus = 16,
	ProviderOptions_UseComThreading = 32,
	ProviderOptions_RefuseNonClientSupport = 64,
	ProviderOptions_HasNativeIAccessible = 128,
	ProviderOptions_UseClientCoordinates = 256,
}


[AllowDuplicates]
public enum StructureChangeType : int32
{
	StructureChangeType_ChildAdded = 0,
	StructureChangeType_ChildRemoved = 1,
	StructureChangeType_ChildrenInvalidated = 2,
	StructureChangeType_ChildrenBulkAdded = 3,
	StructureChangeType_ChildrenBulkRemoved = 4,
	StructureChangeType_ChildrenReordered = 5,
}


[AllowDuplicates]
public enum TextEditChangeType : int32
{
	TextEditChangeType_None = 0,
	TextEditChangeType_AutoCorrect = 1,
	TextEditChangeType_Composition = 2,
	TextEditChangeType_CompositionFinalized = 3,
	TextEditChangeType_AutoComplete = 4,
}


[AllowDuplicates]
public enum OrientationType : int32
{
	OrientationType_None = 0,
	OrientationType_Horizontal = 1,
	OrientationType_Vertical = 2,
}


[AllowDuplicates]
public enum DockPosition : int32
{
	DockPosition_Top = 0,
	DockPosition_Left = 1,
	DockPosition_Bottom = 2,
	DockPosition_Right = 3,
	DockPosition_Fill = 4,
	DockPosition_None = 5,
}


[AllowDuplicates]
public enum ExpandCollapseState : int32
{
	ExpandCollapseState_Collapsed = 0,
	ExpandCollapseState_Expanded = 1,
	ExpandCollapseState_PartiallyExpanded = 2,
	ExpandCollapseState_LeafNode = 3,
}


[AllowDuplicates]
public enum ScrollAmount : int32
{
	ScrollAmount_LargeDecrement = 0,
	ScrollAmount_SmallDecrement = 1,
	ScrollAmount_NoAmount = 2,
	ScrollAmount_LargeIncrement = 3,
	ScrollAmount_SmallIncrement = 4,
}


[AllowDuplicates]
public enum RowOrColumnMajor : int32
{
	RowOrColumnMajor_RowMajor = 0,
	RowOrColumnMajor_ColumnMajor = 1,
	RowOrColumnMajor_Indeterminate = 2,
}


[AllowDuplicates]
public enum ToggleState : int32
{
	ToggleState_Off = 0,
	ToggleState_On = 1,
	ToggleState_Indeterminate = 2,
}


[AllowDuplicates]
public enum WindowVisualState : int32
{
	WindowVisualState_Normal = 0,
	WindowVisualState_Maximized = 1,
	WindowVisualState_Minimized = 2,
}


[AllowDuplicates]
public enum SynchronizedInputType : int32
{
	SynchronizedInputType_KeyUp = 1,
	SynchronizedInputType_KeyDown = 2,
	SynchronizedInputType_LeftMouseUp = 4,
	SynchronizedInputType_LeftMouseDown = 8,
	SynchronizedInputType_RightMouseUp = 16,
	SynchronizedInputType_RightMouseDown = 32,
}


[AllowDuplicates]
public enum WindowInteractionState : int32
{
	WindowInteractionState_Running = 0,
	WindowInteractionState_Closing = 1,
	WindowInteractionState_ReadyForUserInteraction = 2,
	WindowInteractionState_BlockedByModalWindow = 3,
	WindowInteractionState_NotResponding = 4,
}


[AllowDuplicates]
public enum SayAsInterpretAs : int32
{
	SayAsInterpretAs_None = 0,
	SayAsInterpretAs_Spell = 1,
	SayAsInterpretAs_Cardinal = 2,
	SayAsInterpretAs_Ordinal = 3,
	SayAsInterpretAs_Number = 4,
	SayAsInterpretAs_Date = 5,
	SayAsInterpretAs_Time = 6,
	SayAsInterpretAs_Telephone = 7,
	SayAsInterpretAs_Currency = 8,
	SayAsInterpretAs_Net = 9,
	SayAsInterpretAs_Url = 10,
	SayAsInterpretAs_Address = 11,
	SayAsInterpretAs_Alphanumeric = 12,
	SayAsInterpretAs_Name = 13,
	SayAsInterpretAs_Media = 14,
	SayAsInterpretAs_Date_MonthDayYear = 15,
	SayAsInterpretAs_Date_DayMonthYear = 16,
	SayAsInterpretAs_Date_YearMonthDay = 17,
	SayAsInterpretAs_Date_YearMonth = 18,
	SayAsInterpretAs_Date_MonthYear = 19,
	SayAsInterpretAs_Date_DayMonth = 20,
	SayAsInterpretAs_Date_MonthDay = 21,
	SayAsInterpretAs_Date_Year = 22,
	SayAsInterpretAs_Time_HoursMinutesSeconds12 = 23,
	SayAsInterpretAs_Time_HoursMinutes12 = 24,
	SayAsInterpretAs_Time_HoursMinutesSeconds24 = 25,
	SayAsInterpretAs_Time_HoursMinutes24 = 26,
}


[AllowDuplicates]
public enum TextUnit : int32
{
	TextUnit_Character = 0,
	TextUnit_Format = 1,
	TextUnit_Word = 2,
	TextUnit_Line = 3,
	TextUnit_Paragraph = 4,
	TextUnit_Page = 5,
	TextUnit_Document = 6,
}


[AllowDuplicates]
public enum TextPatternRangeEndpoint : int32
{
	TextPatternRangeEndpoint_Start = 0,
	TextPatternRangeEndpoint_End = 1,
}


[AllowDuplicates]
public enum SupportedTextSelection : int32
{
	SupportedTextSelection_None = 0,
	SupportedTextSelection_Single = 1,
	SupportedTextSelection_Multiple = 2,
}


[AllowDuplicates]
public enum LiveSetting : int32
{
	Off = 0,
	Polite = 1,
	Assertive = 2,
}


[AllowDuplicates]
public enum ActiveEnd : int32
{
	ActiveEnd_None = 0,
	ActiveEnd_Start = 1,
	ActiveEnd_End = 2,
}


[AllowDuplicates]
public enum CaretPosition : int32
{
	CaretPosition_Unknown = 0,
	CaretPosition_EndOfLine = 1,
	CaretPosition_BeginningOfLine = 2,
}


[AllowDuplicates]
public enum CaretBidiMode : int32
{
	CaretBidiMode_LTR = 0,
	CaretBidiMode_RTL = 1,
}


[AllowDuplicates]
public enum ZoomUnit : int32
{
	ZoomUnit_NoAmount = 0,
	ZoomUnit_LargeDecrement = 1,
	ZoomUnit_SmallDecrement = 2,
	ZoomUnit_LargeIncrement = 3,
	ZoomUnit_SmallIncrement = 4,
}


[AllowDuplicates]
public enum AnimationStyle : int32
{
	AnimationStyle_None = 0,
	AnimationStyle_LasVegasLights = 1,
	AnimationStyle_BlinkingBackground = 2,
	AnimationStyle_SparkleText = 3,
	AnimationStyle_MarchingBlackAnts = 4,
	AnimationStyle_MarchingRedAnts = 5,
	AnimationStyle_Shimmer = 6,
	AnimationStyle_Other = -1,
}


[AllowDuplicates]
public enum BulletStyle : int32
{
	BulletStyle_None = 0,
	BulletStyle_HollowRoundBullet = 1,
	BulletStyle_FilledRoundBullet = 2,
	BulletStyle_HollowSquareBullet = 3,
	BulletStyle_FilledSquareBullet = 4,
	BulletStyle_DashBullet = 5,
	BulletStyle_Other = -1,
}


[AllowDuplicates]
public enum CapStyle : int32
{
	CapStyle_None = 0,
	CapStyle_SmallCap = 1,
	CapStyle_AllCap = 2,
	CapStyle_AllPetiteCaps = 3,
	CapStyle_PetiteCaps = 4,
	CapStyle_Unicase = 5,
	CapStyle_Titling = 6,
	CapStyle_Other = -1,
}


[AllowDuplicates]
public enum FillType : int32
{
	FillType_None = 0,
	FillType_Color = 1,
	FillType_Gradient = 2,
	FillType_Picture = 3,
	FillType_Pattern = 4,
}


[AllowDuplicates]
public enum FlowDirections : int32
{
	FlowDirections_Default = 0,
	FlowDirections_RightToLeft = 1,
	FlowDirections_BottomToTop = 2,
	FlowDirections_Vertical = 4,
}


[AllowDuplicates]
public enum HorizontalTextAlignment : int32
{
	HorizontalTextAlignment_Left = 0,
	HorizontalTextAlignment_Centered = 1,
	HorizontalTextAlignment_Right = 2,
	HorizontalTextAlignment_Justified = 3,
}


[AllowDuplicates]
public enum OutlineStyles : int32
{
	OutlineStyles_None = 0,
	OutlineStyles_Outline = 1,
	OutlineStyles_Shadow = 2,
	OutlineStyles_Engraved = 4,
	OutlineStyles_Embossed = 8,
}


[AllowDuplicates]
public enum TextDecorationLineStyle : int32
{
	TextDecorationLineStyle_None = 0,
	TextDecorationLineStyle_Single = 1,
	TextDecorationLineStyle_WordsOnly = 2,
	TextDecorationLineStyle_Double = 3,
	TextDecorationLineStyle_Dot = 4,
	TextDecorationLineStyle_Dash = 5,
	TextDecorationLineStyle_DashDot = 6,
	TextDecorationLineStyle_DashDotDot = 7,
	TextDecorationLineStyle_Wavy = 8,
	TextDecorationLineStyle_ThickSingle = 9,
	TextDecorationLineStyle_DoubleWavy = 11,
	TextDecorationLineStyle_ThickWavy = 12,
	TextDecorationLineStyle_LongDash = 13,
	TextDecorationLineStyle_ThickDash = 14,
	TextDecorationLineStyle_ThickDashDot = 15,
	TextDecorationLineStyle_ThickDashDotDot = 16,
	TextDecorationLineStyle_ThickDot = 17,
	TextDecorationLineStyle_ThickLongDash = 18,
	TextDecorationLineStyle_Other = -1,
}


[AllowDuplicates]
public enum VisualEffects : int32
{
	VisualEffects_None = 0,
	VisualEffects_Shadow = 1,
	VisualEffects_Reflection = 2,
	VisualEffects_Glow = 4,
	VisualEffects_SoftEdges = 8,
	VisualEffects_Bevel = 16,
}


[AllowDuplicates]
public enum NotificationProcessing : int32
{
	NotificationProcessing_ImportantAll = 0,
	NotificationProcessing_ImportantMostRecent = 1,
	NotificationProcessing_All = 2,
	NotificationProcessing_MostRecent = 3,
	NotificationProcessing_CurrentThenMostRecent = 4,
}


[AllowDuplicates]
public enum NotificationKind : int32
{
	NotificationKind_ItemAdded = 0,
	NotificationKind_ItemRemoved = 1,
	NotificationKind_ActionCompleted = 2,
	NotificationKind_ActionAborted = 3,
	NotificationKind_Other = 4,
}


[AllowDuplicates]
public enum UIAutomationType : int32
{
	UIAutomationType_Int = 1,
	UIAutomationType_Bool = 2,
	UIAutomationType_String = 3,
	UIAutomationType_Double = 4,
	UIAutomationType_Point = 5,
	UIAutomationType_Rect = 6,
	UIAutomationType_Element = 7,
	UIAutomationType_Array = 65536,
	UIAutomationType_Out = 131072,
	UIAutomationType_IntArray = 65537,
	UIAutomationType_BoolArray = 65538,
	UIAutomationType_StringArray = 65539,
	UIAutomationType_DoubleArray = 65540,
	UIAutomationType_PointArray = 65541,
	UIAutomationType_RectArray = 65542,
	UIAutomationType_ElementArray = 65543,
	UIAutomationType_OutInt = 131073,
	UIAutomationType_OutBool = 131074,
	UIAutomationType_OutString = 131075,
	UIAutomationType_OutDouble = 131076,
	UIAutomationType_OutPoint = 131077,
	UIAutomationType_OutRect = 131078,
	UIAutomationType_OutElement = 131079,
	UIAutomationType_OutIntArray = 196609,
	UIAutomationType_OutBoolArray = 196610,
	UIAutomationType_OutStringArray = 196611,
	UIAutomationType_OutDoubleArray = 196612,
	UIAutomationType_OutPointArray = 196613,
	UIAutomationType_OutRectArray = 196614,
	UIAutomationType_OutElementArray = 196615,
}


[AllowDuplicates]
public enum TreeScope : int32
{
	TreeScope_None = 0,
	TreeScope_Element = 1,
	TreeScope_Children = 2,
	TreeScope_Descendants = 4,
	TreeScope_Parent = 8,
	TreeScope_Ancestors = 16,
	TreeScope_Subtree = 7,
}


[AllowDuplicates]
public enum PropertyConditionFlags : int32
{
	PropertyConditionFlags_None = 0,
	PropertyConditionFlags_IgnoreCase = 1,
	PropertyConditionFlags_MatchSubstring = 2,
}


[AllowDuplicates]
public enum AutomationElementMode : int32
{
	AutomationElementMode_None = 0,
	AutomationElementMode_Full = 1,
}


[AllowDuplicates]
public enum TreeTraversalOptions : int32
{
	TreeTraversalOptions_Default = 0,
	TreeTraversalOptions_PostOrder = 1,
	TreeTraversalOptions_LastToFirstOrder = 2,
}


[AllowDuplicates]
public enum ConnectionRecoveryBehaviorOptions : int32
{
	ConnectionRecoveryBehaviorOptions_Disabled = 0,
	ConnectionRecoveryBehaviorOptions_Enabled = 1,
}


[AllowDuplicates]
public enum CoalesceEventsOptions : int32
{
	CoalesceEventsOptions_Disabled = 0,
	CoalesceEventsOptions_Enabled = 1,
}


[AllowDuplicates]
public enum ConditionType : int32
{
	ConditionType_True = 0,
	ConditionType_False = 1,
	ConditionType_Property = 2,
	ConditionType_And = 3,
	ConditionType_Or = 4,
	ConditionType_Not = 5,
}


[AllowDuplicates]
public enum NormalizeState : int32
{
	NormalizeState_None = 0,
	NormalizeState_View = 1,
	NormalizeState_Custom = 2,
}


[AllowDuplicates]
public enum ProviderType : int32
{
	ProviderType_BaseHwnd = 0,
	ProviderType_Proxy = 1,
	ProviderType_NonClientArea = 2,
}


[AllowDuplicates]
public enum AutomationIdentifierType : int32
{
	AutomationIdentifierType_Property = 0,
	AutomationIdentifierType_Pattern = 1,
	AutomationIdentifierType_Event = 2,
	AutomationIdentifierType_ControlType = 3,
	AutomationIdentifierType_TextAttribute = 4,
	AutomationIdentifierType_LandmarkType = 5,
	AutomationIdentifierType_Annotation = 6,
	AutomationIdentifierType_Changes = 7,
	AutomationIdentifierType_Style = 8,
}


[AllowDuplicates]
public enum EventArgsType : int32
{
	EventArgsType_Simple = 0,
	EventArgsType_PropertyChanged = 1,
	EventArgsType_StructureChanged = 2,
	EventArgsType_AsyncContentLoaded = 3,
	EventArgsType_WindowClosed = 4,
	EventArgsType_TextEditTextChanged = 5,
	EventArgsType_Changes = 6,
	EventArgsType_Notification = 7,
	EventArgsType_ActiveTextPositionChanged = 8,
	EventArgsType_StructuredMarkup = 9,
}


[AllowDuplicates]
public enum AsyncContentLoadedState : int32
{
	AsyncContentLoadedState_Beginning = 0,
	AsyncContentLoadedState_Progress = 1,
	AsyncContentLoadedState_Completed = 2,
}

#endregion

#region Function Pointers
public function LRESULT LPFNLRESULTFROMOBJECT(in Guid riid, WPARAM wParam, IUnknown* punk);

public function HRESULT LPFNOBJECTFROMLRESULT(LRESULT lResult, in Guid riid, WPARAM wParam, void** ppvObject);

public function HRESULT LPFNACCESSIBLEOBJECTFROMWINDOW(HWND hwnd, uint32 dwId, in Guid riid, void** ppvObject);

public function HRESULT LPFNACCESSIBLEOBJECTFROMPOINT(POINT ptScreen, IAccessible** ppacc, VARIANT* pvarChild);

public function HRESULT LPFNCREATESTDACCESSIBLEOBJECT(HWND hwnd, int32 idObject, in Guid riid, void** ppvObject);

public function HRESULT LPFNACCESSIBLECHILDREN(IAccessible* paccContainer, int32 iChildStart, int32 cChildren, VARIANT* rgvarChildren, int32* pcObtained);

public function SAFEARRAY* UiaProviderCallback(HWND hwnd, ProviderType providerType);

public function void UiaEventCallback(UiaEventArgs* pArgs, SAFEARRAY* pRequestedData, BSTR pTreeStructure);

public function void WINEVENTPROC(HWINEVENTHOOK hWinEventHook, uint32 event, HWND hwnd, int32 idObject, int32 idChild, uint32 idEventThread, uint32 dwmsEventTime);

#endregion

#region Structs
[CRepr]
public struct MSAAMENUINFO
{
	public uint32 dwMSAASignature;
	public uint32 cchWText;
	public PWSTR pszWText;
}

[CRepr]
public struct UiaRect
{
	public double left;
	public double top;
	public double width;
	public double height;
}

[CRepr]
public struct UiaPoint
{
	public double x;
	public double y;
}

[CRepr]
public struct UiaChangeInfo
{
	public int32 uiaId;
	public VARIANT payload;
	public VARIANT extraInfo;
}

[CRepr]
public struct UIAutomationParameter
{
	public UIAutomationType type;
	public void* pData;
}

[CRepr]
public struct UIAutomationPropertyInfo
{
	public Guid guid;
	public PWSTR pProgrammaticName;
	public UIAutomationType type;
}

[CRepr]
public struct UIAutomationEventInfo
{
	public Guid guid;
	public PWSTR pProgrammaticName;
}

[CRepr]
public struct UIAutomationMethodInfo
{
	public PWSTR pProgrammaticName;
	public BOOL doSetFocus;
	public uint32 cInParameters;
	public uint32 cOutParameters;
	public UIAutomationType* pParameterTypes;
	public PWSTR* pParameterNames;
}

[CRepr]
public struct UIAutomationPatternInfo
{
	public Guid guid;
	public PWSTR pProgrammaticName;
	public Guid providerInterfaceId;
	public Guid clientInterfaceId;
	public uint32 cProperties;
	public UIAutomationPropertyInfo* pProperties;
	public uint32 cMethods;
	public UIAutomationMethodInfo* pMethods;
	public uint32 cEvents;
	public UIAutomationEventInfo* pEvents;
	public IUIAutomationPatternHandler* pPatternHandler;
}

[CRepr]
public struct ExtendedProperty
{
	public BSTR PropertyName;
	public BSTR PropertyValue;
}

[CRepr]
public struct UiaCondition
{
	public ConditionType ConditionType;
}

[CRepr]
public struct UiaPropertyCondition
{
	public ConditionType ConditionType;
	public UIA_PROPERTY_ID PropertyId;
	public VARIANT Value;
	public PropertyConditionFlags Flags;
}

[CRepr]
public struct UiaAndOrCondition
{
	public ConditionType ConditionType;
	public UiaCondition** ppConditions;
	public int32 cConditions;
}

[CRepr]
public struct UiaNotCondition
{
	public ConditionType ConditionType;
	public UiaCondition* pCondition;
}

[CRepr]
public struct UiaCacheRequest
{
	public UiaCondition* pViewCondition;
	public TreeScope Scope;
	public int32* pProperties;
	public int32 cProperties;
	public int32* pPatterns;
	public int32 cPatterns;
	public AutomationElementMode automationElementMode;
}

[CRepr]
public struct UiaFindParams
{
	public int32 MaxDepth;
	public BOOL FindFirst;
	public BOOL ExcludeRoot;
	public UiaCondition* pFindCondition;
}

[CRepr]
public struct UiaEventArgs
{
	public EventArgsType Type;
	public int32 EventId;
}

[CRepr]
public struct UiaPropertyChangedEventArgs
{
	public EventArgsType Type;
	public UIA_EVENT_ID EventId;
	public int32 PropertyId;
	public VARIANT OldValue;
	public VARIANT NewValue;
}

[CRepr]
public struct UiaStructureChangedEventArgs
{
	public EventArgsType Type;
	public int32 EventId;
	public StructureChangeType StructureChangeType;
	public int32* pRuntimeId;
	public int32 cRuntimeIdLen;
}

[CRepr]
public struct UiaTextEditTextChangedEventArgs
{
	public EventArgsType Type;
	public int32 EventId;
	public TextEditChangeType TextEditChangeType;
	public SAFEARRAY* pTextChange;
}

[CRepr]
public struct UiaChangesEventArgs
{
	public EventArgsType Type;
	public int32 EventId;
	public int32 EventIdCount;
	public UiaChangeInfo* pUiaChanges;
}

[CRepr]
public struct UiaAsyncContentLoadedEventArgs
{
	public EventArgsType Type;
	public int32 EventId;
	public AsyncContentLoadedState AsyncContentLoadedState;
	public double PercentComplete;
}

[CRepr]
public struct UiaWindowClosedEventArgs
{
	public EventArgsType Type;
	public int32 EventId;
	public int32* pRuntimeId;
	public int32 cRuntimeIdLen;
}

[CRepr]
public struct SERIALKEYSA
{
	public uint32 cbSize;
	public SERIALKEYS_FLAGS dwFlags;
	public PSTR lpszActivePort;
	public PSTR lpszPort;
	public uint32 iBaudRate;
	public uint32 iPortState;
	public uint32 iActive;
}

[CRepr]
public struct SERIALKEYSW
{
	public uint32 cbSize;
	public SERIALKEYS_FLAGS dwFlags;
	public PWSTR lpszActivePort;
	public PWSTR lpszPort;
	public uint32 iBaudRate;
	public uint32 iPortState;
	public uint32 iActive;
}

[CRepr]
public struct HIGHCONTRASTA
{
	public uint32 cbSize;
	public HIGHCONTRASTW_FLAGS dwFlags;
	public PSTR lpszDefaultScheme;
}

[CRepr]
public struct HIGHCONTRASTW
{
	public uint32 cbSize;
	public HIGHCONTRASTW_FLAGS dwFlags;
	public PWSTR lpszDefaultScheme;
}

[CRepr]
public struct FILTERKEYS
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32 iWaitMSec;
	public uint32 iDelayMSec;
	public uint32 iRepeatMSec;
	public uint32 iBounceMSec;
}

[CRepr]
public struct STICKYKEYS
{
	public uint32 cbSize;
	public STICKYKEYS_FLAGS dwFlags;
}

[CRepr]
public struct MOUSEKEYS
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32 iMaxSpeed;
	public uint32 iTimeToMaxSpeed;
	public uint32 iCtrlSpeed;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct ACCESSTIMEOUT
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32 iTimeOutMSec;
}

[CRepr]
public struct SOUNDSENTRYA
{
	public uint32 cbSize;
	public SOUNDSENTRY_FLAGS dwFlags;
	public SOUNDSENTRY_TEXT_EFFECT iFSTextEffect;
	public uint32 iFSTextEffectMSec;
	public uint32 iFSTextEffectColorBits;
	public SOUND_SENTRY_GRAPHICS_EFFECT iFSGrafEffect;
	public uint32 iFSGrafEffectMSec;
	public uint32 iFSGrafEffectColor;
	public SOUNDSENTRY_WINDOWS_EFFECT iWindowsEffect;
	public uint32 iWindowsEffectMSec;
	public PSTR lpszWindowsEffectDLL;
	public uint32 iWindowsEffectOrdinal;
}

[CRepr]
public struct SOUNDSENTRYW
{
	public uint32 cbSize;
	public SOUNDSENTRY_FLAGS dwFlags;
	public SOUNDSENTRY_TEXT_EFFECT iFSTextEffect;
	public uint32 iFSTextEffectMSec;
	public uint32 iFSTextEffectColorBits;
	public SOUND_SENTRY_GRAPHICS_EFFECT iFSGrafEffect;
	public uint32 iFSGrafEffectMSec;
	public uint32 iFSGrafEffectColor;
	public SOUNDSENTRY_WINDOWS_EFFECT iWindowsEffect;
	public uint32 iWindowsEffectMSec;
	public PWSTR lpszWindowsEffectDLL;
	public uint32 iWindowsEffectOrdinal;
}

[CRepr]
public struct TOGGLEKEYS
{
	public uint32 cbSize;
	public uint32 dwFlags;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CAccPropServices = .(0xb5f8350b, 0x0548, 0x48b1, 0xa6, 0xee, 0x88, 0xbd, 0x00, 0xb4, 0xa5, 0xe7);


	public const Guid CLSID_CUIAutomation = .(0xff48dba4, 0x60ef, 0x4201, 0xaa, 0x87, 0x54, 0x10, 0x3e, 0xef, 0x59, 0x4e);


	public const Guid CLSID_CUIAutomation8 = .(0xe22ad333, 0xb25f, 0x460c, 0x83, 0xd0, 0x05, 0x81, 0x10, 0x73, 0x95, 0xc9);


	public const Guid CLSID_CUIAutomationRegistrar = .(0x6e29fabf, 0x9977, 0x42d1, 0x8d, 0x0e, 0xca, 0x7e, 0x61, 0xad, 0x87, 0xe6);


}
#endregion

#region COM Types
[CRepr]struct IAccessible : IDispatch
{
	public new const Guid IID = .(0x618736e0, 0x3c3d, 0x11cf, 0x81, 0x0c, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppdispParent) get_accParent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcountChildren) get_accChildCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, IDispatch** ppdispChild) get_accChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR* pszName) get_accName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR* pszValue) get_accValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR* pszDescription) get_accDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, VARIANT* pvarRole) get_accRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, VARIANT* pvarState) get_accState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR* pszHelp) get_accHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszHelpFile, VARIANT varChild, int32* pidTopic) get_accHelpTopic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR* pszKeyboardShortcut) get_accKeyboardShortcut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarChild) get_accFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarChildren) get_accSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR* pszDefaultAction) get_accDefaultAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flagsSelect, VARIANT varChild) accSelect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pxLeft, int32* pyTop, int32* pcxWidth, int32* pcyHeight, VARIANT varChild) accLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 navDir, VARIANT varStart, VARIANT* pvarEndUpAt) accNavigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 xLeft, int32 yTop, VARIANT* pvarChild) accHitTest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild) accDoDefaultAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR szName) put_accName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varChild, BSTR szValue) put_accValue;
	}


	public HRESULT get_accParent(IDispatch** ppdispParent) mut => VT.[Friend]get_accParent(&this, ppdispParent);

	public HRESULT get_accChildCount(int32* pcountChildren) mut => VT.[Friend]get_accChildCount(&this, pcountChildren);

	public HRESULT get_accChild(VARIANT varChild, IDispatch** ppdispChild) mut => VT.[Friend]get_accChild(&this, varChild, ppdispChild);

	public HRESULT get_accName(VARIANT varChild, BSTR* pszName) mut => VT.[Friend]get_accName(&this, varChild, pszName);

	public HRESULT get_accValue(VARIANT varChild, BSTR* pszValue) mut => VT.[Friend]get_accValue(&this, varChild, pszValue);

	public HRESULT get_accDescription(VARIANT varChild, BSTR* pszDescription) mut => VT.[Friend]get_accDescription(&this, varChild, pszDescription);

	public HRESULT get_accRole(VARIANT varChild, VARIANT* pvarRole) mut => VT.[Friend]get_accRole(&this, varChild, pvarRole);

	public HRESULT get_accState(VARIANT varChild, VARIANT* pvarState) mut => VT.[Friend]get_accState(&this, varChild, pvarState);

	public HRESULT get_accHelp(VARIANT varChild, BSTR* pszHelp) mut => VT.[Friend]get_accHelp(&this, varChild, pszHelp);

	public HRESULT get_accHelpTopic(BSTR* pszHelpFile, VARIANT varChild, int32* pidTopic) mut => VT.[Friend]get_accHelpTopic(&this, pszHelpFile, varChild, pidTopic);

	public HRESULT get_accKeyboardShortcut(VARIANT varChild, BSTR* pszKeyboardShortcut) mut => VT.[Friend]get_accKeyboardShortcut(&this, varChild, pszKeyboardShortcut);

	public HRESULT get_accFocus(VARIANT* pvarChild) mut => VT.[Friend]get_accFocus(&this, pvarChild);

	public HRESULT get_accSelection(VARIANT* pvarChildren) mut => VT.[Friend]get_accSelection(&this, pvarChildren);

	public HRESULT get_accDefaultAction(VARIANT varChild, BSTR* pszDefaultAction) mut => VT.[Friend]get_accDefaultAction(&this, varChild, pszDefaultAction);

	public HRESULT accSelect(int32 flagsSelect, VARIANT varChild) mut => VT.[Friend]accSelect(&this, flagsSelect, varChild);

	public HRESULT accLocation(int32* pxLeft, int32* pyTop, int32* pcxWidth, int32* pcyHeight, VARIANT varChild) mut => VT.[Friend]accLocation(&this, pxLeft, pyTop, pcxWidth, pcyHeight, varChild);

	public HRESULT accNavigate(int32 navDir, VARIANT varStart, VARIANT* pvarEndUpAt) mut => VT.[Friend]accNavigate(&this, navDir, varStart, pvarEndUpAt);

	public HRESULT accHitTest(int32 xLeft, int32 yTop, VARIANT* pvarChild) mut => VT.[Friend]accHitTest(&this, xLeft, yTop, pvarChild);

	public HRESULT accDoDefaultAction(VARIANT varChild) mut => VT.[Friend]accDoDefaultAction(&this, varChild);

	public HRESULT put_accName(VARIANT varChild, BSTR szName) mut => VT.[Friend]put_accName(&this, varChild, szName);

	public HRESULT put_accValue(VARIANT varChild, BSTR szValue) mut => VT.[Friend]put_accValue(&this, varChild, szValue);
}

[CRepr]struct IAccessibleHandler : IUnknown
{
	public new const Guid IID = .(0x03022430, 0xabc4, 0x11d0, 0xbd, 0xe2, 0x00, 0xaa, 0x00, 0x1a, 0x19, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hwnd, int32 lObjectID, IAccessible** pIAccessible) AccessibleObjectFromID;
	}


	public HRESULT AccessibleObjectFromID(int32 hwnd, int32 lObjectID, IAccessible** pIAccessible) mut => VT.[Friend]AccessibleObjectFromID(&this, hwnd, lObjectID, pIAccessible);
}

[CRepr]struct IAccessibleWindowlessSite : IUnknown
{
	public new const Guid IID = .(0xbf3abd9c, 0x76da, 0x4389, 0x9e, 0xb6, 0x14, 0x27, 0xd2, 0x5a, 0xba, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 rangeSize, IAccessibleHandler* pRangeOwner, int32* pRangeBase) AcquireObjectIdRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 rangeBase, IAccessibleHandler* pRangeOwner) ReleaseObjectIdRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessibleHandler* pRangesOwner, SAFEARRAY** psaRanges) QueryObjectIdRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessible** ppParent) GetParentAccessible;
	}


	public HRESULT AcquireObjectIdRange(int32 rangeSize, IAccessibleHandler* pRangeOwner, int32* pRangeBase) mut => VT.[Friend]AcquireObjectIdRange(&this, rangeSize, pRangeOwner, pRangeBase);

	public HRESULT ReleaseObjectIdRange(int32 rangeBase, IAccessibleHandler* pRangeOwner) mut => VT.[Friend]ReleaseObjectIdRange(&this, rangeBase, pRangeOwner);

	public HRESULT QueryObjectIdRanges(IAccessibleHandler* pRangesOwner, SAFEARRAY** psaRanges) mut => VT.[Friend]QueryObjectIdRanges(&this, pRangesOwner, psaRanges);

	public HRESULT GetParentAccessible(IAccessible** ppParent) mut => VT.[Friend]GetParentAccessible(&this, ppParent);
}

[CRepr]struct IAccIdentity : IUnknown
{
	public new const Guid IID = .(0x7852b78d, 0x1cfd, 0x41c1, 0xa6, 0x15, 0x9c, 0x0c, 0x85, 0x96, 0x0b, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDChild, uint8** ppIDString, uint32* pdwIDStringLen) GetIdentityString;
	}


	public HRESULT GetIdentityString(uint32 dwIDChild, uint8** ppIDString, uint32* pdwIDStringLen) mut => VT.[Friend]GetIdentityString(&this, dwIDChild, ppIDString, pdwIDStringLen);
}

[CRepr]struct IAccPropServer : IUnknown
{
	public new const Guid IID = .(0x76c0dbbb, 0x15e0, 0x4e7b, 0xb6, 0x1b, 0x20, 0xee, 0xea, 0x20, 0x01, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pIDString, uint32 dwIDStringLen, Guid idProp, VARIANT* pvarValue, BOOL* pfHasProp) GetPropValue;
	}


	public HRESULT GetPropValue(uint8* pIDString, uint32 dwIDStringLen, Guid idProp, VARIANT* pvarValue, BOOL* pfHasProp) mut => VT.[Friend]GetPropValue(&this, pIDString, dwIDStringLen, idProp, pvarValue, pfHasProp);
}

[CRepr]struct IAccPropServices : IUnknown
{
	public new const Guid IID = .(0x6e26e776, 0x04f0, 0x495d, 0x80, 0xe4, 0x33, 0x30, 0x35, 0x2e, 0x31, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pIDString, uint32 dwIDStringLen, Guid idProp, VARIANT @var) SetPropValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pIDString, uint32 dwIDStringLen, Guid* paProps, int32 cProps, IAccPropServer* pServer, AnnoScope annoScope) SetPropServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pIDString, uint32 dwIDStringLen, Guid* paProps, int32 cProps) ClearProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 idObject, uint32 idChild, Guid idProp, VARIANT @var) SetHwndProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 idObject, uint32 idChild, Guid idProp, PWSTR str) SetHwndPropStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 idObject, uint32 idChild, Guid* paProps, int32 cProps, IAccPropServer* pServer, AnnoScope annoScope) SetHwndPropServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 idObject, uint32 idChild, Guid* paProps, int32 cProps) ClearHwndProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 idObject, uint32 idChild, uint8** ppIDString, uint32* pdwIDStringLen) ComposeHwndIdentityString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pIDString, uint32 dwIDStringLen, HWND* phwnd, uint32* pidObject, uint32* pidChild) DecomposeHwndIdentityString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, uint32 idChild, Guid idProp, VARIANT @var) SetHmenuProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, uint32 idChild, Guid idProp, PWSTR str) SetHmenuPropStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, uint32 idChild, Guid* paProps, int32 cProps, IAccPropServer* pServer, AnnoScope annoScope) SetHmenuPropServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, uint32 idChild, Guid* paProps, int32 cProps) ClearHmenuProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, uint32 idChild, uint8** ppIDString, uint32* pdwIDStringLen) ComposeHmenuIdentityString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pIDString, uint32 dwIDStringLen, HMENU* phmenu, uint32* pidChild) DecomposeHmenuIdentityString;
	}


	public HRESULT SetPropValue(uint8* pIDString, uint32 dwIDStringLen, Guid idProp, VARIANT @var) mut => VT.[Friend]SetPropValue(&this, pIDString, dwIDStringLen, idProp, @var);

	public HRESULT SetPropServer(uint8* pIDString, uint32 dwIDStringLen, Guid* paProps, int32 cProps, IAccPropServer* pServer, AnnoScope annoScope) mut => VT.[Friend]SetPropServer(&this, pIDString, dwIDStringLen, paProps, cProps, pServer, annoScope);

	public HRESULT ClearProps(uint8* pIDString, uint32 dwIDStringLen, Guid* paProps, int32 cProps) mut => VT.[Friend]ClearProps(&this, pIDString, dwIDStringLen, paProps, cProps);

	public HRESULT SetHwndProp(HWND hwnd, uint32 idObject, uint32 idChild, Guid idProp, VARIANT @var) mut => VT.[Friend]SetHwndProp(&this, hwnd, idObject, idChild, idProp, @var);

	public HRESULT SetHwndPropStr(HWND hwnd, uint32 idObject, uint32 idChild, Guid idProp, PWSTR str) mut => VT.[Friend]SetHwndPropStr(&this, hwnd, idObject, idChild, idProp, str);

	public HRESULT SetHwndPropServer(HWND hwnd, uint32 idObject, uint32 idChild, Guid* paProps, int32 cProps, IAccPropServer* pServer, AnnoScope annoScope) mut => VT.[Friend]SetHwndPropServer(&this, hwnd, idObject, idChild, paProps, cProps, pServer, annoScope);

	public HRESULT ClearHwndProps(HWND hwnd, uint32 idObject, uint32 idChild, Guid* paProps, int32 cProps) mut => VT.[Friend]ClearHwndProps(&this, hwnd, idObject, idChild, paProps, cProps);

	public HRESULT ComposeHwndIdentityString(HWND hwnd, uint32 idObject, uint32 idChild, uint8** ppIDString, uint32* pdwIDStringLen) mut => VT.[Friend]ComposeHwndIdentityString(&this, hwnd, idObject, idChild, ppIDString, pdwIDStringLen);

	public HRESULT DecomposeHwndIdentityString(uint8* pIDString, uint32 dwIDStringLen, HWND* phwnd, uint32* pidObject, uint32* pidChild) mut => VT.[Friend]DecomposeHwndIdentityString(&this, pIDString, dwIDStringLen, phwnd, pidObject, pidChild);

	public HRESULT SetHmenuProp(HMENU hmenu, uint32 idChild, Guid idProp, VARIANT @var) mut => VT.[Friend]SetHmenuProp(&this, hmenu, idChild, idProp, @var);

	public HRESULT SetHmenuPropStr(HMENU hmenu, uint32 idChild, Guid idProp, PWSTR str) mut => VT.[Friend]SetHmenuPropStr(&this, hmenu, idChild, idProp, str);

	public HRESULT SetHmenuPropServer(HMENU hmenu, uint32 idChild, Guid* paProps, int32 cProps, IAccPropServer* pServer, AnnoScope annoScope) mut => VT.[Friend]SetHmenuPropServer(&this, hmenu, idChild, paProps, cProps, pServer, annoScope);

	public HRESULT ClearHmenuProps(HMENU hmenu, uint32 idChild, Guid* paProps, int32 cProps) mut => VT.[Friend]ClearHmenuProps(&this, hmenu, idChild, paProps, cProps);

	public HRESULT ComposeHmenuIdentityString(HMENU hmenu, uint32 idChild, uint8** ppIDString, uint32* pdwIDStringLen) mut => VT.[Friend]ComposeHmenuIdentityString(&this, hmenu, idChild, ppIDString, pdwIDStringLen);

	public HRESULT DecomposeHmenuIdentityString(uint8* pIDString, uint32 dwIDStringLen, HMENU* phmenu, uint32* pidChild) mut => VT.[Friend]DecomposeHmenuIdentityString(&this, pIDString, dwIDStringLen, phmenu, pidChild);
}

[CRepr]struct IRawElementProviderSimple : IUnknown
{
	public new const Guid IID = .(0xd6dd68d1, 0x86fd, 0x4332, 0x86, 0x66, 0x9a, 0xbe, 0xde, 0xa2, 0xd2, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ProviderOptions* pRetVal) get_ProviderOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UIA_PATTERN_ID patternId, IUnknown** pRetVal) GetPatternProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UIA_PROPERTY_ID propertyId, VARIANT* pRetVal) GetPropertyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** pRetVal) get_HostRawElementProvider;
	}


	public HRESULT get_ProviderOptions(ProviderOptions* pRetVal) mut => VT.[Friend]get_ProviderOptions(&this, pRetVal);

	public HRESULT GetPatternProvider(UIA_PATTERN_ID patternId, IUnknown** pRetVal) mut => VT.[Friend]GetPatternProvider(&this, patternId, pRetVal);

	public HRESULT GetPropertyValue(UIA_PROPERTY_ID propertyId, VARIANT* pRetVal) mut => VT.[Friend]GetPropertyValue(&this, propertyId, pRetVal);

	public HRESULT get_HostRawElementProvider(IRawElementProviderSimple** pRetVal) mut => VT.[Friend]get_HostRawElementProvider(&this, pRetVal);
}

[CRepr]struct IAccessibleEx : IUnknown
{
	public new const Guid IID = .(0xf8b80ada, 0x2c44, 0x48d0, 0x89, 0xbe, 0x5f, 0xf2, 0x3c, 0x9c, 0xd8, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 idChild, IAccessibleEx** pRetVal) GetObjectForChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessible** ppAcc, int32* pidChild) GetIAccessiblePair;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetRuntimeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* pIn, IAccessibleEx** ppRetValOut) ConvertReturnedElement;
	}


	public HRESULT GetObjectForChild(int32 idChild, IAccessibleEx** pRetVal) mut => VT.[Friend]GetObjectForChild(&this, idChild, pRetVal);

	public HRESULT GetIAccessiblePair(IAccessible** ppAcc, int32* pidChild) mut => VT.[Friend]GetIAccessiblePair(&this, ppAcc, pidChild);

	public HRESULT GetRuntimeId(SAFEARRAY** pRetVal) mut => VT.[Friend]GetRuntimeId(&this, pRetVal);

	public HRESULT ConvertReturnedElement(IRawElementProviderSimple* pIn, IAccessibleEx** ppRetValOut) mut => VT.[Friend]ConvertReturnedElement(&this, pIn, ppRetValOut);
}

[CRepr]struct IRawElementProviderSimple2 : IRawElementProviderSimple
{
	public new const Guid IID = .(0xa0a839a9, 0x8da1, 0x4a82, 0x80, 0x6a, 0x8e, 0x0d, 0x44, 0xe7, 0x9f, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRawElementProviderSimple.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowContextMenu;
	}


	public HRESULT ShowContextMenu() mut => VT.[Friend]ShowContextMenu(&this);
}

[CRepr]struct IRawElementProviderSimple3 : IRawElementProviderSimple2
{
	public new const Guid IID = .(0xfcf5d820, 0xd7ec, 0x4613, 0xbd, 0xf6, 0x42, 0xa8, 0x4c, 0xe7, 0xda, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRawElementProviderSimple2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 targetId, int32 metadataId, VARIANT* returnVal) GetMetadataValue;
	}


	public HRESULT GetMetadataValue(int32 targetId, int32 metadataId, VARIANT* returnVal) mut => VT.[Friend]GetMetadataValue(&this, targetId, metadataId, returnVal);
}

[CRepr]struct IRawElementProviderFragmentRoot : IUnknown
{
	public new const Guid IID = .(0x620ce2a5, 0xab8f, 0x40a9, 0x86, 0xcb, 0xde, 0x3c, 0x75, 0x59, 0x9b, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double x, double y, IRawElementProviderFragment** pRetVal) ElementProviderFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderFragment** pRetVal) GetFocus;
	}


	public HRESULT ElementProviderFromPoint(double x, double y, IRawElementProviderFragment** pRetVal) mut => VT.[Friend]ElementProviderFromPoint(&this, x, y, pRetVal);

	public HRESULT GetFocus(IRawElementProviderFragment** pRetVal) mut => VT.[Friend]GetFocus(&this, pRetVal);
}

[CRepr]struct IRawElementProviderFragment : IUnknown
{
	public new const Guid IID = .(0xf7063da8, 0x8359, 0x439c, 0x92, 0x97, 0xbb, 0xc5, 0x29, 0x9a, 0x7d, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NavigateDirection direction, IRawElementProviderFragment** pRetVal) Navigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetRuntimeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UiaRect* pRetVal) get_BoundingRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetEmbeddedFragmentRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderFragmentRoot** pRetVal) get_FragmentRoot;
	}


	public HRESULT Navigate(NavigateDirection direction, IRawElementProviderFragment** pRetVal) mut => VT.[Friend]Navigate(&this, direction, pRetVal);

	public HRESULT GetRuntimeId(SAFEARRAY** pRetVal) mut => VT.[Friend]GetRuntimeId(&this, pRetVal);

	public HRESULT get_BoundingRectangle(UiaRect* pRetVal) mut => VT.[Friend]get_BoundingRectangle(&this, pRetVal);

	public HRESULT GetEmbeddedFragmentRoots(SAFEARRAY** pRetVal) mut => VT.[Friend]GetEmbeddedFragmentRoots(&this, pRetVal);

	public HRESULT SetFocus() mut => VT.[Friend]SetFocus(&this);

	public HRESULT get_FragmentRoot(IRawElementProviderFragmentRoot** pRetVal) mut => VT.[Friend]get_FragmentRoot(&this, pRetVal);
}

[CRepr]struct IRawElementProviderAdviseEvents : IUnknown
{
	public new const Guid IID = .(0xa407b27b, 0x0f6d, 0x4427, 0x92, 0x92, 0x47, 0x3c, 0x7b, 0xf9, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, SAFEARRAY* propertyIDs) AdviseEventAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, SAFEARRAY* propertyIDs) AdviseEventRemoved;
	}


	public HRESULT AdviseEventAdded(int32 eventId, SAFEARRAY* propertyIDs) mut => VT.[Friend]AdviseEventAdded(&this, eventId, propertyIDs);

	public HRESULT AdviseEventRemoved(int32 eventId, SAFEARRAY* propertyIDs) mut => VT.[Friend]AdviseEventRemoved(&this, eventId, propertyIDs);
}

[CRepr]struct IRawElementProviderHwndOverride : IUnknown
{
	public new const Guid IID = .(0x1d5df27c, 0x8947, 0x4425, 0xb8, 0xd9, 0x79, 0x78, 0x7b, 0xb4, 0x60, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IRawElementProviderSimple** pRetVal) GetOverrideProviderForHwnd;
	}


	public HRESULT GetOverrideProviderForHwnd(HWND hwnd, IRawElementProviderSimple** pRetVal) mut => VT.[Friend]GetOverrideProviderForHwnd(&this, hwnd, pRetVal);
}

[CRepr]struct IProxyProviderWinEventSink : IUnknown
{
	public new const Guid IID = .(0x4fd82b78, 0xa43e, 0x46ac, 0x98, 0x03, 0x0a, 0x69, 0x69, 0xc7, 0xc1, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* pProvider, int32 id, VARIANT newValue) AddAutomationPropertyChangedEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* pProvider, int32 id) AddAutomationEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* pProvider, StructureChangeType structureChangeType, SAFEARRAY* runtimeId) AddStructureChangedEvent;
	}


	public HRESULT AddAutomationPropertyChangedEvent(IRawElementProviderSimple* pProvider, int32 id, VARIANT newValue) mut => VT.[Friend]AddAutomationPropertyChangedEvent(&this, pProvider, id, newValue);

	public HRESULT AddAutomationEvent(IRawElementProviderSimple* pProvider, int32 id) mut => VT.[Friend]AddAutomationEvent(&this, pProvider, id);

	public HRESULT AddStructureChangedEvent(IRawElementProviderSimple* pProvider, StructureChangeType structureChangeType, SAFEARRAY* runtimeId) mut => VT.[Friend]AddStructureChangedEvent(&this, pProvider, structureChangeType, runtimeId);
}

[CRepr]struct IProxyProviderWinEventHandler : IUnknown
{
	public new const Guid IID = .(0x89592ad4, 0xf4e0, 0x43d5, 0xa3, 0xb6, 0xba, 0xd7, 0xe1, 0x11, 0xb4, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idWinEvent, HWND hwnd, int32 idObject, int32 idChild, IProxyProviderWinEventSink* pSink) RespondToWinEvent;
	}


	public HRESULT RespondToWinEvent(uint32 idWinEvent, HWND hwnd, int32 idObject, int32 idChild, IProxyProviderWinEventSink* pSink) mut => VT.[Friend]RespondToWinEvent(&this, idWinEvent, hwnd, idObject, idChild, pSink);
}

[CRepr]struct IRawElementProviderWindowlessSite : IUnknown
{
	public new const Guid IID = .(0x0a2a93cc, 0xbfad, 0x42ac, 0x9b, 0x2e, 0x09, 0x91, 0xfb, 0x0d, 0x3e, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NavigateDirection direction, IRawElementProviderFragment** ppParent) GetAdjacentFragment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetRuntimeIdPrefix;
	}


	public HRESULT GetAdjacentFragment(NavigateDirection direction, IRawElementProviderFragment** ppParent) mut => VT.[Friend]GetAdjacentFragment(&this, direction, ppParent);

	public HRESULT GetRuntimeIdPrefix(SAFEARRAY** pRetVal) mut => VT.[Friend]GetRuntimeIdPrefix(&this, pRetVal);
}

[CRepr]struct IAccessibleHostingElementProviders : IUnknown
{
	public new const Guid IID = .(0x33ac331b, 0x943e, 0x4020, 0xb2, 0x95, 0xdb, 0x37, 0x78, 0x49, 0x74, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetEmbeddedFragmentRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* pProvider, int32* pidObject) GetObjectIdForProvider;
	}


	public HRESULT GetEmbeddedFragmentRoots(SAFEARRAY** pRetVal) mut => VT.[Friend]GetEmbeddedFragmentRoots(&this, pRetVal);

	public HRESULT GetObjectIdForProvider(IRawElementProviderSimple* pProvider, int32* pidObject) mut => VT.[Friend]GetObjectIdForProvider(&this, pProvider, pidObject);
}

[CRepr]struct IRawElementProviderHostingAccessibles : IUnknown
{
	public new const Guid IID = .(0x24be0b07, 0xd37d, 0x487a, 0x98, 0xcf, 0xa1, 0x3e, 0xd4, 0x65, 0xe9, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetEmbeddedAccessibles;
	}


	public HRESULT GetEmbeddedAccessibles(SAFEARRAY** pRetVal) mut => VT.[Friend]GetEmbeddedAccessibles(&this, pRetVal);
}

[CRepr]struct IDockProvider : IUnknown
{
	public new const Guid IID = .(0x159bc72c, 0x4ad3, 0x485e, 0x96, 0x37, 0xd7, 0x05, 0x2e, 0xdf, 0x01, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DockPosition dockPosition) SetDockPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DockPosition* pRetVal) get_DockPosition;
	}


	public HRESULT SetDockPosition(DockPosition dockPosition) mut => VT.[Friend]SetDockPosition(&this, dockPosition);

	public HRESULT get_DockPosition(DockPosition* pRetVal) mut => VT.[Friend]get_DockPosition(&this, pRetVal);
}

[CRepr]struct IExpandCollapseProvider : IUnknown
{
	public new const Guid IID = .(0xd847d3a5, 0xcab0, 0x4a98, 0x8c, 0x32, 0xec, 0xb4, 0x5c, 0x59, 0xad, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Expand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Collapse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ExpandCollapseState* pRetVal) get_ExpandCollapseState;
	}


	public HRESULT Expand() mut => VT.[Friend]Expand(&this);

	public HRESULT Collapse() mut => VT.[Friend]Collapse(&this);

	public HRESULT get_ExpandCollapseState(ExpandCollapseState* pRetVal) mut => VT.[Friend]get_ExpandCollapseState(&this, pRetVal);
}

[CRepr]struct IGridProvider : IUnknown
{
	public new const Guid IID = .(0xb17d6187, 0x0907, 0x464b, 0xa1, 0x68, 0x0e, 0xf1, 0x7a, 0x15, 0x72, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, IRawElementProviderSimple** pRetVal) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_RowCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_ColumnCount;
	}


	public HRESULT GetItem(int32 row, int32 column, IRawElementProviderSimple** pRetVal) mut => VT.[Friend]GetItem(&this, row, column, pRetVal);

	public HRESULT get_RowCount(int32* pRetVal) mut => VT.[Friend]get_RowCount(&this, pRetVal);

	public HRESULT get_ColumnCount(int32* pRetVal) mut => VT.[Friend]get_ColumnCount(&this, pRetVal);
}

[CRepr]struct IGridItemProvider : IUnknown
{
	public new const Guid IID = .(0xd02541f1, 0xfb81, 0x4d64, 0xae, 0x32, 0xf5, 0x20, 0xf8, 0xa6, 0xdb, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_Row;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_Column;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_RowSpan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_ColumnSpan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** pRetVal) get_ContainingGrid;
	}


	public HRESULT get_Row(int32* pRetVal) mut => VT.[Friend]get_Row(&this, pRetVal);

	public HRESULT get_Column(int32* pRetVal) mut => VT.[Friend]get_Column(&this, pRetVal);

	public HRESULT get_RowSpan(int32* pRetVal) mut => VT.[Friend]get_RowSpan(&this, pRetVal);

	public HRESULT get_ColumnSpan(int32* pRetVal) mut => VT.[Friend]get_ColumnSpan(&this, pRetVal);

	public HRESULT get_ContainingGrid(IRawElementProviderSimple** pRetVal) mut => VT.[Friend]get_ContainingGrid(&this, pRetVal);
}

[CRepr]struct IInvokeProvider : IUnknown
{
	public new const Guid IID = .(0x54fcb24b, 0xe18e, 0x47a2, 0xb4, 0xd3, 0xec, 0xcb, 0xe7, 0x75, 0x99, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Invoke;
	}


	public HRESULT Invoke() mut => VT.[Friend]Invoke(&this);
}

[CRepr]struct IMultipleViewProvider : IUnknown
{
	public new const Guid IID = .(0x6278cab1, 0xb556, 0x4a1a, 0xb4, 0xe0, 0x41, 0x8a, 0xcc, 0x52, 0x32, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 viewId, BSTR* pRetVal) GetViewName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 viewId) SetCurrentView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_CurrentView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetSupportedViews;
	}


	public HRESULT GetViewName(int32 viewId, BSTR* pRetVal) mut => VT.[Friend]GetViewName(&this, viewId, pRetVal);

	public HRESULT SetCurrentView(int32 viewId) mut => VT.[Friend]SetCurrentView(&this, viewId);

	public HRESULT get_CurrentView(int32* pRetVal) mut => VT.[Friend]get_CurrentView(&this, pRetVal);

	public HRESULT GetSupportedViews(SAFEARRAY** pRetVal) mut => VT.[Friend]GetSupportedViews(&this, pRetVal);
}

[CRepr]struct IRangeValueProvider : IUnknown
{
	public new const Guid IID = .(0x36dc7aef, 0x33e6, 0x4691, 0xaf, 0xe1, 0x2b, 0xe7, 0x27, 0x4b, 0x3d, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double val) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_Maximum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_Minimum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_LargeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_SmallChange;
	}


	public HRESULT SetValue(double val) mut => VT.[Friend]SetValue(&this, val);

	public HRESULT get_Value(double* pRetVal) mut => VT.[Friend]get_Value(&this, pRetVal);

	public HRESULT get_IsReadOnly(BOOL* pRetVal) mut => VT.[Friend]get_IsReadOnly(&this, pRetVal);

	public HRESULT get_Maximum(double* pRetVal) mut => VT.[Friend]get_Maximum(&this, pRetVal);

	public HRESULT get_Minimum(double* pRetVal) mut => VT.[Friend]get_Minimum(&this, pRetVal);

	public HRESULT get_LargeChange(double* pRetVal) mut => VT.[Friend]get_LargeChange(&this, pRetVal);

	public HRESULT get_SmallChange(double* pRetVal) mut => VT.[Friend]get_SmallChange(&this, pRetVal);
}

[CRepr]struct IScrollItemProvider : IUnknown
{
	public new const Guid IID = .(0x2360c714, 0x4bf1, 0x4b26, 0xba, 0x65, 0x9b, 0x21, 0x31, 0x61, 0x27, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ScrollIntoView;
	}


	public HRESULT ScrollIntoView() mut => VT.[Friend]ScrollIntoView(&this);
}

[CRepr]struct ISelectionProvider : IUnknown
{
	public new const Guid IID = .(0xfb8b03af, 0x3bdf, 0x48d4, 0xbd, 0x36, 0x1a, 0x65, 0x79, 0x3b, 0xe1, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanSelectMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsSelectionRequired;
	}


	public HRESULT GetSelection(SAFEARRAY** pRetVal) mut => VT.[Friend]GetSelection(&this, pRetVal);

	public HRESULT get_CanSelectMultiple(BOOL* pRetVal) mut => VT.[Friend]get_CanSelectMultiple(&this, pRetVal);

	public HRESULT get_IsSelectionRequired(BOOL* pRetVal) mut => VT.[Friend]get_IsSelectionRequired(&this, pRetVal);
}

[CRepr]struct ISelectionProvider2 : ISelectionProvider
{
	public new const Guid IID = .(0x14f68475, 0xee1c, 0x44f6, 0xa8, 0x69, 0xd2, 0x39, 0x38, 0x1f, 0x0f, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISelectionProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** retVal) get_FirstSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** retVal) get_LastSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** retVal) get_CurrentSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_ItemCount;
	}


	public HRESULT get_FirstSelectedItem(IRawElementProviderSimple** retVal) mut => VT.[Friend]get_FirstSelectedItem(&this, retVal);

	public HRESULT get_LastSelectedItem(IRawElementProviderSimple** retVal) mut => VT.[Friend]get_LastSelectedItem(&this, retVal);

	public HRESULT get_CurrentSelectedItem(IRawElementProviderSimple** retVal) mut => VT.[Friend]get_CurrentSelectedItem(&this, retVal);

	public HRESULT get_ItemCount(int32* retVal) mut => VT.[Friend]get_ItemCount(&this, retVal);
}

[CRepr]struct IScrollProvider : IUnknown
{
	public new const Guid IID = .(0xb38b8077, 0x1fc3, 0x42a5, 0x8c, 0xae, 0xd4, 0x0c, 0x22, 0x15, 0x05, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ScrollAmount horizontalAmount, ScrollAmount verticalAmount) Scroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double horizontalPercent, double verticalPercent) SetScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_HorizontalScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_VerticalScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_HorizontalViewSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_VerticalViewSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_HorizontallyScrollable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_VerticallyScrollable;
	}


	public HRESULT Scroll(ScrollAmount horizontalAmount, ScrollAmount verticalAmount) mut => VT.[Friend]Scroll(&this, horizontalAmount, verticalAmount);

	public HRESULT SetScrollPercent(double horizontalPercent, double verticalPercent) mut => VT.[Friend]SetScrollPercent(&this, horizontalPercent, verticalPercent);

	public HRESULT get_HorizontalScrollPercent(double* pRetVal) mut => VT.[Friend]get_HorizontalScrollPercent(&this, pRetVal);

	public HRESULT get_VerticalScrollPercent(double* pRetVal) mut => VT.[Friend]get_VerticalScrollPercent(&this, pRetVal);

	public HRESULT get_HorizontalViewSize(double* pRetVal) mut => VT.[Friend]get_HorizontalViewSize(&this, pRetVal);

	public HRESULT get_VerticalViewSize(double* pRetVal) mut => VT.[Friend]get_VerticalViewSize(&this, pRetVal);

	public HRESULT get_HorizontallyScrollable(BOOL* pRetVal) mut => VT.[Friend]get_HorizontallyScrollable(&this, pRetVal);

	public HRESULT get_VerticallyScrollable(BOOL* pRetVal) mut => VT.[Friend]get_VerticallyScrollable(&this, pRetVal);
}

[CRepr]struct ISelectionItemProvider : IUnknown
{
	public new const Guid IID = .(0x2acad808, 0xb2d4, 0x452d, 0xa4, 0x07, 0x91, 0xff, 0x1a, 0xd1, 0x67, 0xb2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddToSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveFromSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** pRetVal) get_SelectionContainer;
	}


	public HRESULT Select() mut => VT.[Friend]Select(&this);

	public HRESULT AddToSelection() mut => VT.[Friend]AddToSelection(&this);

	public HRESULT RemoveFromSelection() mut => VT.[Friend]RemoveFromSelection(&this);

	public HRESULT get_IsSelected(BOOL* pRetVal) mut => VT.[Friend]get_IsSelected(&this, pRetVal);

	public HRESULT get_SelectionContainer(IRawElementProviderSimple** pRetVal) mut => VT.[Friend]get_SelectionContainer(&this, pRetVal);
}

[CRepr]struct ISynchronizedInputProvider : IUnknown
{
	public new const Guid IID = .(0x29db1a06, 0x02ce, 0x4cf7, 0x9b, 0x42, 0x56, 0x5d, 0x4f, 0xab, 0x20, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SynchronizedInputType inputType) StartListening;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT StartListening(SynchronizedInputType inputType) mut => VT.[Friend]StartListening(&this, inputType);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct ITableProvider : IUnknown
{
	public new const Guid IID = .(0x9c860395, 0x97b3, 0x490a, 0xb5, 0x2a, 0x85, 0x8c, 0xc2, 0x2a, 0xf1, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetRowHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetColumnHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RowOrColumnMajor* pRetVal) get_RowOrColumnMajor;
	}


	public HRESULT GetRowHeaders(SAFEARRAY** pRetVal) mut => VT.[Friend]GetRowHeaders(&this, pRetVal);

	public HRESULT GetColumnHeaders(SAFEARRAY** pRetVal) mut => VT.[Friend]GetColumnHeaders(&this, pRetVal);

	public HRESULT get_RowOrColumnMajor(RowOrColumnMajor* pRetVal) mut => VT.[Friend]get_RowOrColumnMajor(&this, pRetVal);
}

[CRepr]struct ITableItemProvider : IUnknown
{
	public new const Guid IID = .(0xb9734fa6, 0x771f, 0x4d78, 0x9c, 0x90, 0x25, 0x17, 0x99, 0x93, 0x49, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetRowHeaderItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetColumnHeaderItems;
	}


	public HRESULT GetRowHeaderItems(SAFEARRAY** pRetVal) mut => VT.[Friend]GetRowHeaderItems(&this, pRetVal);

	public HRESULT GetColumnHeaderItems(SAFEARRAY** pRetVal) mut => VT.[Friend]GetColumnHeaderItems(&this, pRetVal);
}

[CRepr]struct IToggleProvider : IUnknown
{
	public new const Guid IID = .(0x56d00bd0, 0xc4f4, 0x433c, 0xa8, 0x36, 0x1a, 0x52, 0xa5, 0x7e, 0x08, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Toggle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ToggleState* pRetVal) get_ToggleState;
	}


	public HRESULT Toggle() mut => VT.[Friend]Toggle(&this);

	public HRESULT get_ToggleState(ToggleState* pRetVal) mut => VT.[Friend]get_ToggleState(&this, pRetVal);
}

[CRepr]struct ITransformProvider : IUnknown
{
	public new const Guid IID = .(0x6829ddc4, 0x4f91, 0x4ffa, 0xb8, 0x6f, 0xbd, 0x3e, 0x29, 0x87, 0xcb, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double x, double y) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double width, double height) Resize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double degrees) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanMove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanResize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanRotate;
	}


	public HRESULT Move(double x, double y) mut => VT.[Friend]Move(&this, x, y);

	public HRESULT Resize(double width, double height) mut => VT.[Friend]Resize(&this, width, height);

	public HRESULT Rotate(double degrees) mut => VT.[Friend]Rotate(&this, degrees);

	public HRESULT get_CanMove(BOOL* pRetVal) mut => VT.[Friend]get_CanMove(&this, pRetVal);

	public HRESULT get_CanResize(BOOL* pRetVal) mut => VT.[Friend]get_CanResize(&this, pRetVal);

	public HRESULT get_CanRotate(BOOL* pRetVal) mut => VT.[Friend]get_CanRotate(&this, pRetVal);
}

[CRepr]struct IValueProvider : IUnknown
{
	public new const Guid IID = .(0xc7935180, 0x6fb3, 0x4201, 0xb1, 0x74, 0x7d, 0xf7, 0x3a, 0xdb, 0xf6, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR val) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRetVal) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsReadOnly;
	}


	public HRESULT SetValue(PWSTR val) mut => VT.[Friend]SetValue(&this, val);

	public HRESULT get_Value(BSTR* pRetVal) mut => VT.[Friend]get_Value(&this, pRetVal);

	public HRESULT get_IsReadOnly(BOOL* pRetVal) mut => VT.[Friend]get_IsReadOnly(&this, pRetVal);
}

[CRepr]struct IWindowProvider : IUnknown
{
	public new const Guid IID = .(0x987df77b, 0xdb06, 0x4d77, 0x8f, 0x8a, 0x86, 0xa9, 0xc3, 0xbb, 0x90, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowVisualState state) SetVisualState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 milliseconds, BOOL* pRetVal) WaitForInputIdle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanMaximize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanMinimize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsModal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowVisualState* pRetVal) get_WindowVisualState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowInteractionState* pRetVal) get_WindowInteractionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsTopmost;
	}


	public HRESULT SetVisualState(WindowVisualState state) mut => VT.[Friend]SetVisualState(&this, state);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT WaitForInputIdle(int32 milliseconds, BOOL* pRetVal) mut => VT.[Friend]WaitForInputIdle(&this, milliseconds, pRetVal);

	public HRESULT get_CanMaximize(BOOL* pRetVal) mut => VT.[Friend]get_CanMaximize(&this, pRetVal);

	public HRESULT get_CanMinimize(BOOL* pRetVal) mut => VT.[Friend]get_CanMinimize(&this, pRetVal);

	public HRESULT get_IsModal(BOOL* pRetVal) mut => VT.[Friend]get_IsModal(&this, pRetVal);

	public HRESULT get_WindowVisualState(WindowVisualState* pRetVal) mut => VT.[Friend]get_WindowVisualState(&this, pRetVal);

	public HRESULT get_WindowInteractionState(WindowInteractionState* pRetVal) mut => VT.[Friend]get_WindowInteractionState(&this, pRetVal);

	public HRESULT get_IsTopmost(BOOL* pRetVal) mut => VT.[Friend]get_IsTopmost(&this, pRetVal);
}

[CRepr]struct ILegacyIAccessibleProvider : IUnknown
{
	public new const Guid IID = .(0xe44c3566, 0x915d, 0x4070, 0x99, 0xc6, 0x04, 0x7b, 0xff, 0x5a, 0x08, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flagsSelect) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DoDefaultAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szValue) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessible** ppAccessible) GetIAccessible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_ChildId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRole) get_Role;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszHelp) get_Help;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszKeyboardShortcut) get_KeyboardShortcut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pvarSelectedChildren) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDefaultAction) get_DefaultAction;
	}


	public HRESULT Select(int32 flagsSelect) mut => VT.[Friend]Select(&this, flagsSelect);

	public HRESULT DoDefaultAction() mut => VT.[Friend]DoDefaultAction(&this);

	public HRESULT SetValue(PWSTR szValue) mut => VT.[Friend]SetValue(&this, szValue);

	public HRESULT GetIAccessible(IAccessible** ppAccessible) mut => VT.[Friend]GetIAccessible(&this, ppAccessible);

	public HRESULT get_ChildId(int32* pRetVal) mut => VT.[Friend]get_ChildId(&this, pRetVal);

	public HRESULT get_Name(BSTR* pszName) mut => VT.[Friend]get_Name(&this, pszName);

	public HRESULT get_Value(BSTR* pszValue) mut => VT.[Friend]get_Value(&this, pszValue);

	public HRESULT get_Description(BSTR* pszDescription) mut => VT.[Friend]get_Description(&this, pszDescription);

	public HRESULT get_Role(uint32* pdwRole) mut => VT.[Friend]get_Role(&this, pdwRole);

	public HRESULT get_State(uint32* pdwState) mut => VT.[Friend]get_State(&this, pdwState);

	public HRESULT get_Help(BSTR* pszHelp) mut => VT.[Friend]get_Help(&this, pszHelp);

	public HRESULT get_KeyboardShortcut(BSTR* pszKeyboardShortcut) mut => VT.[Friend]get_KeyboardShortcut(&this, pszKeyboardShortcut);

	public HRESULT GetSelection(SAFEARRAY** pvarSelectedChildren) mut => VT.[Friend]GetSelection(&this, pvarSelectedChildren);

	public HRESULT get_DefaultAction(BSTR* pszDefaultAction) mut => VT.[Friend]get_DefaultAction(&this, pszDefaultAction);
}

[CRepr]struct IItemContainerProvider : IUnknown
{
	public new const Guid IID = .(0xe747770b, 0x39ce, 0x4382, 0xab, 0x30, 0xd8, 0xfb, 0x3f, 0x33, 0x6f, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* pStartAfter, int32 propertyId, VARIANT value, IRawElementProviderSimple** pFound) FindItemByProperty;
	}


	public HRESULT FindItemByProperty(IRawElementProviderSimple* pStartAfter, int32 propertyId, VARIANT value, IRawElementProviderSimple** pFound) mut => VT.[Friend]FindItemByProperty(&this, pStartAfter, propertyId, value, pFound);
}

[CRepr]struct IVirtualizedItemProvider : IUnknown
{
	public new const Guid IID = .(0xcb98b665, 0x2d35, 0x4fac, 0xad, 0x35, 0xf3, 0xc6, 0x0d, 0x0c, 0x0b, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Realize;
	}


	public HRESULT Realize() mut => VT.[Friend]Realize(&this);
}

[CRepr]struct IObjectModelProvider : IUnknown
{
	public new const Guid IID = .(0x3ad86ebd, 0xf5ef, 0x483d, 0xbb, 0x18, 0xb1, 0x04, 0x2a, 0x47, 0x5d, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnknown) GetUnderlyingObjectModel;
	}


	public HRESULT GetUnderlyingObjectModel(IUnknown** ppUnknown) mut => VT.[Friend]GetUnderlyingObjectModel(&this, ppUnknown);
}

[CRepr]struct IAnnotationProvider : IUnknown
{
	public new const Guid IID = .(0xf95c7e80, 0xbd63, 0x4601, 0x97, 0x82, 0x44, 0x5e, 0xbf, 0xf0, 0x11, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_AnnotationTypeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_AnnotationTypeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_Author;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_DateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** retVal) get_Target;
	}


	public HRESULT get_AnnotationTypeId(int32* retVal) mut => VT.[Friend]get_AnnotationTypeId(&this, retVal);

	public HRESULT get_AnnotationTypeName(BSTR* retVal) mut => VT.[Friend]get_AnnotationTypeName(&this, retVal);

	public HRESULT get_Author(BSTR* retVal) mut => VT.[Friend]get_Author(&this, retVal);

	public HRESULT get_DateTime(BSTR* retVal) mut => VT.[Friend]get_DateTime(&this, retVal);

	public HRESULT get_Target(IRawElementProviderSimple** retVal) mut => VT.[Friend]get_Target(&this, retVal);
}

[CRepr]struct IStylesProvider : IUnknown
{
	public new const Guid IID = .(0x19b6b649, 0xf5d7, 0x4a6d, 0xbd, 0xcb, 0x12, 0x92, 0x52, 0xbe, 0x58, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_StyleId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_StyleName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_FillColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_FillPatternStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_Shape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_FillPatternColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_ExtendedProperties;
	}


	public HRESULT get_StyleId(int32* retVal) mut => VT.[Friend]get_StyleId(&this, retVal);

	public HRESULT get_StyleName(BSTR* retVal) mut => VT.[Friend]get_StyleName(&this, retVal);

	public HRESULT get_FillColor(int32* retVal) mut => VT.[Friend]get_FillColor(&this, retVal);

	public HRESULT get_FillPatternStyle(BSTR* retVal) mut => VT.[Friend]get_FillPatternStyle(&this, retVal);

	public HRESULT get_Shape(BSTR* retVal) mut => VT.[Friend]get_Shape(&this, retVal);

	public HRESULT get_FillPatternColor(int32* retVal) mut => VT.[Friend]get_FillPatternColor(&this, retVal);

	public HRESULT get_ExtendedProperties(BSTR* retVal) mut => VT.[Friend]get_ExtendedProperties(&this, retVal);
}

[CRepr]struct ISpreadsheetProvider : IUnknown
{
	public new const Guid IID = .(0x6f6b5d35, 0x5525, 0x4f80, 0xb7, 0x58, 0x85, 0x47, 0x38, 0x32, 0xff, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, IRawElementProviderSimple** pRetVal) GetItemByName;
	}


	public HRESULT GetItemByName(PWSTR name, IRawElementProviderSimple** pRetVal) mut => VT.[Friend]GetItemByName(&this, name, pRetVal);
}

[CRepr]struct ISpreadsheetItemProvider : IUnknown
{
	public new const Guid IID = .(0xeaed4660, 0x7b3d, 0x4879, 0xa2, 0xe6, 0x36, 0x5c, 0xe6, 0x03, 0xf3, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRetVal) get_Formula;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetAnnotationObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetAnnotationTypes;
	}


	public HRESULT get_Formula(BSTR* pRetVal) mut => VT.[Friend]get_Formula(&this, pRetVal);

	public HRESULT GetAnnotationObjects(SAFEARRAY** pRetVal) mut => VT.[Friend]GetAnnotationObjects(&this, pRetVal);

	public HRESULT GetAnnotationTypes(SAFEARRAY** pRetVal) mut => VT.[Friend]GetAnnotationTypes(&this, pRetVal);
}

[CRepr]struct ITransformProvider2 : ITransformProvider
{
	public new const Guid IID = .(0x4758742f, 0x7ac2, 0x460c, 0xbc, 0x48, 0x09, 0xfc, 0x09, 0x30, 0x8a, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITransformProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double zoom) Zoom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_CanZoom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_ZoomLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_ZoomMinimum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRetVal) get_ZoomMaximum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ZoomUnit zoomUnit) ZoomByUnit;
	}


	public HRESULT Zoom(double zoom) mut => VT.[Friend]Zoom(&this, zoom);

	public HRESULT get_CanZoom(BOOL* pRetVal) mut => VT.[Friend]get_CanZoom(&this, pRetVal);

	public HRESULT get_ZoomLevel(double* pRetVal) mut => VT.[Friend]get_ZoomLevel(&this, pRetVal);

	public HRESULT get_ZoomMinimum(double* pRetVal) mut => VT.[Friend]get_ZoomMinimum(&this, pRetVal);

	public HRESULT get_ZoomMaximum(double* pRetVal) mut => VT.[Friend]get_ZoomMaximum(&this, pRetVal);

	public HRESULT ZoomByUnit(ZoomUnit zoomUnit) mut => VT.[Friend]ZoomByUnit(&this, zoomUnit);
}

[CRepr]struct IDragProvider : IUnknown
{
	public new const Guid IID = .(0x6aa7bbbb, 0x7ff9, 0x497d, 0x90, 0x4f, 0xd2, 0x0b, 0x89, 0x79, 0x29, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pRetVal) get_IsGrabbed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRetVal) get_DropEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) get_DropEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetGrabbedItems;
	}


	public HRESULT get_IsGrabbed(BOOL* pRetVal) mut => VT.[Friend]get_IsGrabbed(&this, pRetVal);

	public HRESULT get_DropEffect(BSTR* pRetVal) mut => VT.[Friend]get_DropEffect(&this, pRetVal);

	public HRESULT get_DropEffects(SAFEARRAY** pRetVal) mut => VT.[Friend]get_DropEffects(&this, pRetVal);

	public HRESULT GetGrabbedItems(SAFEARRAY** pRetVal) mut => VT.[Friend]GetGrabbedItems(&this, pRetVal);
}

[CRepr]struct IDropTargetProvider : IUnknown
{
	public new const Guid IID = .(0xbae82bfd, 0x358a, 0x481c, 0x85, 0xa0, 0xd8, 0xb4, 0xd9, 0x0a, 0x5d, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRetVal) get_DropTargetEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) get_DropTargetEffects;
	}


	public HRESULT get_DropTargetEffect(BSTR* pRetVal) mut => VT.[Friend]get_DropTargetEffect(&this, pRetVal);

	public HRESULT get_DropTargetEffects(SAFEARRAY** pRetVal) mut => VT.[Friend]get_DropTargetEffects(&this, pRetVal);
}

[CRepr]struct ITextRangeProvider : IUnknown
{
	public new const Guid IID = .(0x5347ad7b, 0xc355, 0x46f8, 0xaf, 0xf5, 0x90, 0x90, 0x33, 0x58, 0x2f, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRangeProvider** pRetVal) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRangeProvider* range, BOOL* pRetVal) Compare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextPatternRangeEndpoint endpoint, ITextRangeProvider* targetRange, TextPatternRangeEndpoint targetEndpoint, int32* pRetVal) CompareEndpoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextUnit unit) ExpandToEnclosingUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 attributeId, VARIANT val, BOOL backward, ITextRangeProvider** pRetVal) FindAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR text, BOOL backward, BOOL ignoreCase, ITextRangeProvider** pRetVal) FindText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 attributeId, VARIANT* pRetVal) GetAttributeValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetBoundingRectangles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** pRetVal) GetEnclosingElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 maxLength, BSTR* pRetVal) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextUnit unit, int32 count, int32* pRetVal) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextPatternRangeEndpoint endpoint, TextUnit unit, int32 count, int32* pRetVal) MoveEndpointByUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextPatternRangeEndpoint endpoint, ITextRangeProvider* targetRange, TextPatternRangeEndpoint targetEndpoint) MoveEndpointByRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddToSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveFromSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL alignToTop) ScrollIntoView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetChildren;
	}


	public HRESULT Clone(ITextRangeProvider** pRetVal) mut => VT.[Friend]Clone(&this, pRetVal);

	public HRESULT Compare(ITextRangeProvider* range, BOOL* pRetVal) mut => VT.[Friend]Compare(&this, range, pRetVal);

	public HRESULT CompareEndpoints(TextPatternRangeEndpoint endpoint, ITextRangeProvider* targetRange, TextPatternRangeEndpoint targetEndpoint, int32* pRetVal) mut => VT.[Friend]CompareEndpoints(&this, endpoint, targetRange, targetEndpoint, pRetVal);

	public HRESULT ExpandToEnclosingUnit(TextUnit unit) mut => VT.[Friend]ExpandToEnclosingUnit(&this, unit);

	public HRESULT FindAttribute(int32 attributeId, VARIANT val, BOOL backward, ITextRangeProvider** pRetVal) mut => VT.[Friend]FindAttribute(&this, attributeId, val, backward, pRetVal);

	public HRESULT FindText(BSTR text, BOOL backward, BOOL ignoreCase, ITextRangeProvider** pRetVal) mut => VT.[Friend]FindText(&this, text, backward, ignoreCase, pRetVal);

	public HRESULT GetAttributeValue(int32 attributeId, VARIANT* pRetVal) mut => VT.[Friend]GetAttributeValue(&this, attributeId, pRetVal);

	public HRESULT GetBoundingRectangles(SAFEARRAY** pRetVal) mut => VT.[Friend]GetBoundingRectangles(&this, pRetVal);

	public HRESULT GetEnclosingElement(IRawElementProviderSimple** pRetVal) mut => VT.[Friend]GetEnclosingElement(&this, pRetVal);

	public HRESULT GetText(int32 maxLength, BSTR* pRetVal) mut => VT.[Friend]GetText(&this, maxLength, pRetVal);

	public HRESULT Move(TextUnit unit, int32 count, int32* pRetVal) mut => VT.[Friend]Move(&this, unit, count, pRetVal);

	public HRESULT MoveEndpointByUnit(TextPatternRangeEndpoint endpoint, TextUnit unit, int32 count, int32* pRetVal) mut => VT.[Friend]MoveEndpointByUnit(&this, endpoint, unit, count, pRetVal);

	public HRESULT MoveEndpointByRange(TextPatternRangeEndpoint endpoint, ITextRangeProvider* targetRange, TextPatternRangeEndpoint targetEndpoint) mut => VT.[Friend]MoveEndpointByRange(&this, endpoint, targetRange, targetEndpoint);

	public HRESULT Select() mut => VT.[Friend]Select(&this);

	public HRESULT AddToSelection() mut => VT.[Friend]AddToSelection(&this);

	public HRESULT RemoveFromSelection() mut => VT.[Friend]RemoveFromSelection(&this);

	public HRESULT ScrollIntoView(BOOL alignToTop) mut => VT.[Friend]ScrollIntoView(&this, alignToTop);

	public HRESULT GetChildren(SAFEARRAY** pRetVal) mut => VT.[Friend]GetChildren(&this, pRetVal);
}

[CRepr]struct ITextProvider : IUnknown
{
	public new const Guid IID = .(0x3589c92c, 0x63f3, 0x4367, 0x99, 0xbb, 0xad, 0xa6, 0x53, 0xb7, 0x7c, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pRetVal) GetVisibleRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* childElement, ITextRangeProvider** pRetVal) RangeFromChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UiaPoint point, ITextRangeProvider** pRetVal) RangeFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRangeProvider** pRetVal) get_DocumentRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SupportedTextSelection* pRetVal) get_SupportedTextSelection;
	}


	public HRESULT GetSelection(SAFEARRAY** pRetVal) mut => VT.[Friend]GetSelection(&this, pRetVal);

	public HRESULT GetVisibleRanges(SAFEARRAY** pRetVal) mut => VT.[Friend]GetVisibleRanges(&this, pRetVal);

	public HRESULT RangeFromChild(IRawElementProviderSimple* childElement, ITextRangeProvider** pRetVal) mut => VT.[Friend]RangeFromChild(&this, childElement, pRetVal);

	public HRESULT RangeFromPoint(UiaPoint point, ITextRangeProvider** pRetVal) mut => VT.[Friend]RangeFromPoint(&this, point, pRetVal);

	public HRESULT get_DocumentRange(ITextRangeProvider** pRetVal) mut => VT.[Friend]get_DocumentRange(&this, pRetVal);

	public HRESULT get_SupportedTextSelection(SupportedTextSelection* pRetVal) mut => VT.[Friend]get_SupportedTextSelection(&this, pRetVal);
}

[CRepr]struct ITextProvider2 : ITextProvider
{
	public new const Guid IID = .(0x0dc5e6ed, 0x3e16, 0x4bf1, 0x8f, 0x9a, 0xa9, 0x79, 0x87, 0x8b, 0xc1, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple* annotationElement, ITextRangeProvider** pRetVal) RangeFromAnnotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isActive, ITextRangeProvider** pRetVal) GetCaretRange;
	}


	public HRESULT RangeFromAnnotation(IRawElementProviderSimple* annotationElement, ITextRangeProvider** pRetVal) mut => VT.[Friend]RangeFromAnnotation(&this, annotationElement, pRetVal);

	public HRESULT GetCaretRange(BOOL* isActive, ITextRangeProvider** pRetVal) mut => VT.[Friend]GetCaretRange(&this, isActive, pRetVal);
}

[CRepr]struct ITextEditProvider : ITextProvider
{
	public new const Guid IID = .(0xea3605b4, 0x3a05, 0x400e, 0xb5, 0xf9, 0x4e, 0x91, 0xb4, 0x0f, 0x61, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRangeProvider** pRetVal) GetActiveComposition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRangeProvider** pRetVal) GetConversionTarget;
	}


	public HRESULT GetActiveComposition(ITextRangeProvider** pRetVal) mut => VT.[Friend]GetActiveComposition(&this, pRetVal);

	public HRESULT GetConversionTarget(ITextRangeProvider** pRetVal) mut => VT.[Friend]GetConversionTarget(&this, pRetVal);
}

[CRepr]struct ITextRangeProvider2 : ITextRangeProvider
{
	public new const Guid IID = .(0x9bbce42c, 0x1921, 0x4f18, 0x89, 0xca, 0xdb, 0xa1, 0x91, 0x0a, 0x03, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextRangeProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowContextMenu;
	}


	public HRESULT ShowContextMenu() mut => VT.[Friend]ShowContextMenu(&this);
}

[CRepr]struct ITextChildProvider : IUnknown
{
	public new const Guid IID = .(0x4c2de2b9, 0xc88f, 0x4f88, 0xa1, 0x11, 0xf1, 0xd3, 0x36, 0xb7, 0xd1, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderSimple** pRetVal) get_TextContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRangeProvider** pRetVal) get_TextRange;
	}


	public HRESULT get_TextContainer(IRawElementProviderSimple** pRetVal) mut => VT.[Friend]get_TextContainer(&this, pRetVal);

	public HRESULT get_TextRange(ITextRangeProvider** pRetVal) mut => VT.[Friend]get_TextRange(&this, pRetVal);
}

[CRepr]struct ICustomNavigationProvider : IUnknown
{
	public new const Guid IID = .(0x2062a28a, 0x8c07, 0x4b94, 0x8e, 0x12, 0x70, 0x37, 0xc6, 0x22, 0xae, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NavigateDirection direction, IRawElementProviderSimple** pRetVal) Navigate;
	}


	public HRESULT Navigate(NavigateDirection direction, IRawElementProviderSimple** pRetVal) mut => VT.[Friend]Navigate(&this, direction, pRetVal);
}

[CRepr]struct IUIAutomationPatternInstance : IUnknown
{
	public new const Guid IID = .(0xc03a7fe4, 0x9431, 0x409f, 0xbe, 0xd8, 0xae, 0x7c, 0x22, 0x99, 0xbc, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, BOOL cached, UIAutomationType type, void* pPtr) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, UIAutomationParameter* pParams, uint32 cParams) CallMethod;
	}


	public HRESULT GetProperty(uint32 index, BOOL cached, UIAutomationType type, void* pPtr) mut => VT.[Friend]GetProperty(&this, index, cached, type, pPtr);

	public HRESULT CallMethod(uint32 index, UIAutomationParameter* pParams, uint32 cParams) mut => VT.[Friend]CallMethod(&this, index, pParams, cParams);
}

[CRepr]struct IUIAutomationPatternHandler : IUnknown
{
	public new const Guid IID = .(0xd97022f3, 0xa947, 0x465e, 0x8b, 0x2a, 0xac, 0x43, 0x15, 0xfa, 0x54, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationPatternInstance* pPatternInstance, IUnknown** pClientWrapper) CreateClientWrapper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pTarget, uint32 index, UIAutomationParameter* pParams, uint32 cParams) Dispatch;
	}


	public HRESULT CreateClientWrapper(IUIAutomationPatternInstance* pPatternInstance, IUnknown** pClientWrapper) mut => VT.[Friend]CreateClientWrapper(&this, pPatternInstance, pClientWrapper);

	public HRESULT Dispatch(IUnknown* pTarget, uint32 index, UIAutomationParameter* pParams, uint32 cParams) mut => VT.[Friend]Dispatch(&this, pTarget, index, pParams, cParams);
}

[CRepr]struct IUIAutomationRegistrar : IUnknown
{
	public new const Guid IID = .(0x8609c4ec, 0x4a1a, 0x4d88, 0xa3, 0x57, 0x5a, 0x66, 0xe0, 0x60, 0xe1, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UIAutomationPropertyInfo* property, int32* propertyId) RegisterProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UIAutomationEventInfo* event, int32* eventId) RegisterEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UIAutomationPatternInfo* pattern, int32* pPatternId, int32* pPatternAvailablePropertyId, uint32 propertyIdCount, int32* pPropertyIds, uint32 eventIdCount, int32* pEventIds) RegisterPattern;
	}


	public HRESULT RegisterProperty(UIAutomationPropertyInfo* property, int32* propertyId) mut => VT.[Friend]RegisterProperty(&this, property, propertyId);

	public HRESULT RegisterEvent(UIAutomationEventInfo* event, int32* eventId) mut => VT.[Friend]RegisterEvent(&this, event, eventId);

	public HRESULT RegisterPattern(UIAutomationPatternInfo* pattern, int32* pPatternId, int32* pPatternAvailablePropertyId, uint32 propertyIdCount, int32* pPropertyIds, uint32 eventIdCount, int32* pEventIds) mut => VT.[Friend]RegisterPattern(&this, pattern, pPatternId, pPatternAvailablePropertyId, propertyIdCount, pPropertyIds, eventIdCount, pEventIds);
}

[CRepr]struct IUIAutomationElement : IUnknown
{
	public new const Guid IID = .(0xd22108aa, 0x8ac5, 0x49a5, 0x83, 0x7b, 0x37, 0xbb, 0xb3, 0xd7, 0x59, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** runtimeId) GetRuntimeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationElement** found) FindFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationElementArray** found) FindAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** found) FindFirstBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElementArray** found) FindAllBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** updatedElement) BuildUpdatedCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, VARIANT* retVal) GetCurrentPropertyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, BOOL ignoreDefaultValue, VARIANT* retVal) GetCurrentPropertyValueEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, VARIANT* retVal) GetCachedPropertyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, BOOL ignoreDefaultValue, VARIANT* retVal) GetCachedPropertyValueEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 patternId, in Guid riid, void** patternObject) GetCurrentPatternAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 patternId, in Guid riid, void** patternObject) GetCachedPatternAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 patternId, IUnknown** patternObject) GetCurrentPattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 patternId, IUnknown** patternObject) GetCachedPattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** parent) GetCachedParent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** children) GetCachedChildren;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentProcessId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentControlType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentLocalizedControlType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAcceleratorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAccessKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentHasKeyboardFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsKeyboardFocusable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAutomationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentHelpText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentCulture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsControlElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsContentElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* retVal) get_CurrentNativeWindowHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentItemType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsOffscreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OrientationType* retVal) get_CurrentOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentFrameworkId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsRequiredForForm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentItemStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* retVal) get_CurrentBoundingRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentLabeledBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAriaRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAriaProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsDataValidForForm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CurrentControllerFor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CurrentDescribedBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CurrentFlowsTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentProviderDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedProcessId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedControlType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedLocalizedControlType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAcceleratorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAccessKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedHasKeyboardFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsKeyboardFocusable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAutomationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedHelpText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedCulture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsControlElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsContentElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* retVal) get_CachedNativeWindowHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedItemType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsOffscreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OrientationType* retVal) get_CachedOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedFrameworkId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsRequiredForForm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedItemStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* retVal) get_CachedBoundingRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedLabeledBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAriaRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAriaProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsDataValidForForm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CachedControllerFor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CachedDescribedBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CachedFlowsTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedProviderDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* clickable, BOOL* gotClickable) GetClickablePoint;
	}


	public HRESULT SetFocus() mut => VT.[Friend]SetFocus(&this);

	public HRESULT GetRuntimeId(SAFEARRAY** runtimeId) mut => VT.[Friend]GetRuntimeId(&this, runtimeId);

	public HRESULT FindFirst(TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationElement** found) mut => VT.[Friend]FindFirst(&this, @scope, condition, found);

	public HRESULT FindAll(TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationElementArray** found) mut => VT.[Friend]FindAll(&this, @scope, condition, found);

	public HRESULT FindFirstBuildCache(TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** found) mut => VT.[Friend]FindFirstBuildCache(&this, @scope, condition, cacheRequest, found);

	public HRESULT FindAllBuildCache(TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElementArray** found) mut => VT.[Friend]FindAllBuildCache(&this, @scope, condition, cacheRequest, found);

	public HRESULT BuildUpdatedCache(IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** updatedElement) mut => VT.[Friend]BuildUpdatedCache(&this, cacheRequest, updatedElement);

	public HRESULT GetCurrentPropertyValue(int32 propertyId, VARIANT* retVal) mut => VT.[Friend]GetCurrentPropertyValue(&this, propertyId, retVal);

	public HRESULT GetCurrentPropertyValueEx(int32 propertyId, BOOL ignoreDefaultValue, VARIANT* retVal) mut => VT.[Friend]GetCurrentPropertyValueEx(&this, propertyId, ignoreDefaultValue, retVal);

	public HRESULT GetCachedPropertyValue(int32 propertyId, VARIANT* retVal) mut => VT.[Friend]GetCachedPropertyValue(&this, propertyId, retVal);

	public HRESULT GetCachedPropertyValueEx(int32 propertyId, BOOL ignoreDefaultValue, VARIANT* retVal) mut => VT.[Friend]GetCachedPropertyValueEx(&this, propertyId, ignoreDefaultValue, retVal);

	public HRESULT GetCurrentPatternAs(int32 patternId, in Guid riid, void** patternObject) mut => VT.[Friend]GetCurrentPatternAs(&this, patternId, riid, patternObject);

	public HRESULT GetCachedPatternAs(int32 patternId, in Guid riid, void** patternObject) mut => VT.[Friend]GetCachedPatternAs(&this, patternId, riid, patternObject);

	public HRESULT GetCurrentPattern(int32 patternId, IUnknown** patternObject) mut => VT.[Friend]GetCurrentPattern(&this, patternId, patternObject);

	public HRESULT GetCachedPattern(int32 patternId, IUnknown** patternObject) mut => VT.[Friend]GetCachedPattern(&this, patternId, patternObject);

	public HRESULT GetCachedParent(IUIAutomationElement** parent) mut => VT.[Friend]GetCachedParent(&this, parent);

	public HRESULT GetCachedChildren(IUIAutomationElementArray** children) mut => VT.[Friend]GetCachedChildren(&this, children);

	public HRESULT get_CurrentProcessId(int32* retVal) mut => VT.[Friend]get_CurrentProcessId(&this, retVal);

	public HRESULT get_CurrentControlType(int32* retVal) mut => VT.[Friend]get_CurrentControlType(&this, retVal);

	public HRESULT get_CurrentLocalizedControlType(BSTR* retVal) mut => VT.[Friend]get_CurrentLocalizedControlType(&this, retVal);

	public HRESULT get_CurrentName(BSTR* retVal) mut => VT.[Friend]get_CurrentName(&this, retVal);

	public HRESULT get_CurrentAcceleratorKey(BSTR* retVal) mut => VT.[Friend]get_CurrentAcceleratorKey(&this, retVal);

	public HRESULT get_CurrentAccessKey(BSTR* retVal) mut => VT.[Friend]get_CurrentAccessKey(&this, retVal);

	public HRESULT get_CurrentHasKeyboardFocus(BOOL* retVal) mut => VT.[Friend]get_CurrentHasKeyboardFocus(&this, retVal);

	public HRESULT get_CurrentIsKeyboardFocusable(BOOL* retVal) mut => VT.[Friend]get_CurrentIsKeyboardFocusable(&this, retVal);

	public HRESULT get_CurrentIsEnabled(BOOL* retVal) mut => VT.[Friend]get_CurrentIsEnabled(&this, retVal);

	public HRESULT get_CurrentAutomationId(BSTR* retVal) mut => VT.[Friend]get_CurrentAutomationId(&this, retVal);

	public HRESULT get_CurrentClassName(BSTR* retVal) mut => VT.[Friend]get_CurrentClassName(&this, retVal);

	public HRESULT get_CurrentHelpText(BSTR* retVal) mut => VT.[Friend]get_CurrentHelpText(&this, retVal);

	public HRESULT get_CurrentCulture(int32* retVal) mut => VT.[Friend]get_CurrentCulture(&this, retVal);

	public HRESULT get_CurrentIsControlElement(BOOL* retVal) mut => VT.[Friend]get_CurrentIsControlElement(&this, retVal);

	public HRESULT get_CurrentIsContentElement(BOOL* retVal) mut => VT.[Friend]get_CurrentIsContentElement(&this, retVal);

	public HRESULT get_CurrentIsPassword(BOOL* retVal) mut => VT.[Friend]get_CurrentIsPassword(&this, retVal);

	public HRESULT get_CurrentNativeWindowHandle(HWND* retVal) mut => VT.[Friend]get_CurrentNativeWindowHandle(&this, retVal);

	public HRESULT get_CurrentItemType(BSTR* retVal) mut => VT.[Friend]get_CurrentItemType(&this, retVal);

	public HRESULT get_CurrentIsOffscreen(BOOL* retVal) mut => VT.[Friend]get_CurrentIsOffscreen(&this, retVal);

	public HRESULT get_CurrentOrientation(OrientationType* retVal) mut => VT.[Friend]get_CurrentOrientation(&this, retVal);

	public HRESULT get_CurrentFrameworkId(BSTR* retVal) mut => VT.[Friend]get_CurrentFrameworkId(&this, retVal);

	public HRESULT get_CurrentIsRequiredForForm(BOOL* retVal) mut => VT.[Friend]get_CurrentIsRequiredForForm(&this, retVal);

	public HRESULT get_CurrentItemStatus(BSTR* retVal) mut => VT.[Friend]get_CurrentItemStatus(&this, retVal);

	public HRESULT get_CurrentBoundingRectangle(RECT* retVal) mut => VT.[Friend]get_CurrentBoundingRectangle(&this, retVal);

	public HRESULT get_CurrentLabeledBy(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentLabeledBy(&this, retVal);

	public HRESULT get_CurrentAriaRole(BSTR* retVal) mut => VT.[Friend]get_CurrentAriaRole(&this, retVal);

	public HRESULT get_CurrentAriaProperties(BSTR* retVal) mut => VT.[Friend]get_CurrentAriaProperties(&this, retVal);

	public HRESULT get_CurrentIsDataValidForForm(BOOL* retVal) mut => VT.[Friend]get_CurrentIsDataValidForForm(&this, retVal);

	public HRESULT get_CurrentControllerFor(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CurrentControllerFor(&this, retVal);

	public HRESULT get_CurrentDescribedBy(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CurrentDescribedBy(&this, retVal);

	public HRESULT get_CurrentFlowsTo(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CurrentFlowsTo(&this, retVal);

	public HRESULT get_CurrentProviderDescription(BSTR* retVal) mut => VT.[Friend]get_CurrentProviderDescription(&this, retVal);

	public HRESULT get_CachedProcessId(int32* retVal) mut => VT.[Friend]get_CachedProcessId(&this, retVal);

	public HRESULT get_CachedControlType(int32* retVal) mut => VT.[Friend]get_CachedControlType(&this, retVal);

	public HRESULT get_CachedLocalizedControlType(BSTR* retVal) mut => VT.[Friend]get_CachedLocalizedControlType(&this, retVal);

	public HRESULT get_CachedName(BSTR* retVal) mut => VT.[Friend]get_CachedName(&this, retVal);

	public HRESULT get_CachedAcceleratorKey(BSTR* retVal) mut => VT.[Friend]get_CachedAcceleratorKey(&this, retVal);

	public HRESULT get_CachedAccessKey(BSTR* retVal) mut => VT.[Friend]get_CachedAccessKey(&this, retVal);

	public HRESULT get_CachedHasKeyboardFocus(BOOL* retVal) mut => VT.[Friend]get_CachedHasKeyboardFocus(&this, retVal);

	public HRESULT get_CachedIsKeyboardFocusable(BOOL* retVal) mut => VT.[Friend]get_CachedIsKeyboardFocusable(&this, retVal);

	public HRESULT get_CachedIsEnabled(BOOL* retVal) mut => VT.[Friend]get_CachedIsEnabled(&this, retVal);

	public HRESULT get_CachedAutomationId(BSTR* retVal) mut => VT.[Friend]get_CachedAutomationId(&this, retVal);

	public HRESULT get_CachedClassName(BSTR* retVal) mut => VT.[Friend]get_CachedClassName(&this, retVal);

	public HRESULT get_CachedHelpText(BSTR* retVal) mut => VT.[Friend]get_CachedHelpText(&this, retVal);

	public HRESULT get_CachedCulture(int32* retVal) mut => VT.[Friend]get_CachedCulture(&this, retVal);

	public HRESULT get_CachedIsControlElement(BOOL* retVal) mut => VT.[Friend]get_CachedIsControlElement(&this, retVal);

	public HRESULT get_CachedIsContentElement(BOOL* retVal) mut => VT.[Friend]get_CachedIsContentElement(&this, retVal);

	public HRESULT get_CachedIsPassword(BOOL* retVal) mut => VT.[Friend]get_CachedIsPassword(&this, retVal);

	public HRESULT get_CachedNativeWindowHandle(HWND* retVal) mut => VT.[Friend]get_CachedNativeWindowHandle(&this, retVal);

	public HRESULT get_CachedItemType(BSTR* retVal) mut => VT.[Friend]get_CachedItemType(&this, retVal);

	public HRESULT get_CachedIsOffscreen(BOOL* retVal) mut => VT.[Friend]get_CachedIsOffscreen(&this, retVal);

	public HRESULT get_CachedOrientation(OrientationType* retVal) mut => VT.[Friend]get_CachedOrientation(&this, retVal);

	public HRESULT get_CachedFrameworkId(BSTR* retVal) mut => VT.[Friend]get_CachedFrameworkId(&this, retVal);

	public HRESULT get_CachedIsRequiredForForm(BOOL* retVal) mut => VT.[Friend]get_CachedIsRequiredForForm(&this, retVal);

	public HRESULT get_CachedItemStatus(BSTR* retVal) mut => VT.[Friend]get_CachedItemStatus(&this, retVal);

	public HRESULT get_CachedBoundingRectangle(RECT* retVal) mut => VT.[Friend]get_CachedBoundingRectangle(&this, retVal);

	public HRESULT get_CachedLabeledBy(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedLabeledBy(&this, retVal);

	public HRESULT get_CachedAriaRole(BSTR* retVal) mut => VT.[Friend]get_CachedAriaRole(&this, retVal);

	public HRESULT get_CachedAriaProperties(BSTR* retVal) mut => VT.[Friend]get_CachedAriaProperties(&this, retVal);

	public HRESULT get_CachedIsDataValidForForm(BOOL* retVal) mut => VT.[Friend]get_CachedIsDataValidForForm(&this, retVal);

	public HRESULT get_CachedControllerFor(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CachedControllerFor(&this, retVal);

	public HRESULT get_CachedDescribedBy(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CachedDescribedBy(&this, retVal);

	public HRESULT get_CachedFlowsTo(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CachedFlowsTo(&this, retVal);

	public HRESULT get_CachedProviderDescription(BSTR* retVal) mut => VT.[Friend]get_CachedProviderDescription(&this, retVal);

	public HRESULT GetClickablePoint(POINT* clickable, BOOL* gotClickable) mut => VT.[Friend]GetClickablePoint(&this, clickable, gotClickable);
}

[CRepr]struct IUIAutomationElementArray : IUnknown
{
	public new const Guid IID = .(0x14314595, 0xb4bc, 0x4055, 0x95, 0xf2, 0x58, 0xf2, 0xe4, 0x2c, 0x98, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* length) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, IUIAutomationElement** element) GetElement;
	}


	public HRESULT get_Length(int32* length) mut => VT.[Friend]get_Length(&this, length);

	public HRESULT GetElement(int32 index, IUIAutomationElement** element) mut => VT.[Friend]GetElement(&this, index, element);
}

[CRepr]struct IUIAutomationCondition : IUnknown
{
	public new const Guid IID = .(0x352ffba8, 0x0973, 0x437c, 0xa6, 0x1f, 0xf6, 0x4c, 0xaf, 0xd8, 0x1d, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IUIAutomationBoolCondition : IUIAutomationCondition
{
	public new const Guid IID = .(0x1b4e1f2e, 0x75eb, 0x4d0b, 0x89, 0x52, 0x5a, 0x69, 0x98, 0x8e, 0x23, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationCondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* boolVal) get_BooleanValue;
	}


	public HRESULT get_BooleanValue(BOOL* boolVal) mut => VT.[Friend]get_BooleanValue(&this, boolVal);
}

[CRepr]struct IUIAutomationPropertyCondition : IUIAutomationCondition
{
	public new const Guid IID = .(0x99ebf2cb, 0x5578, 0x4267, 0x9a, 0xd4, 0xaf, 0xd6, 0xea, 0x77, 0xe9, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationCondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* propertyId) get_PropertyId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* propertyValue) get_PropertyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PropertyConditionFlags* flags) get_PropertyConditionFlags;
	}


	public HRESULT get_PropertyId(int32* propertyId) mut => VT.[Friend]get_PropertyId(&this, propertyId);

	public HRESULT get_PropertyValue(VARIANT* propertyValue) mut => VT.[Friend]get_PropertyValue(&this, propertyValue);

	public HRESULT get_PropertyConditionFlags(PropertyConditionFlags* flags) mut => VT.[Friend]get_PropertyConditionFlags(&this, flags);
}

[CRepr]struct IUIAutomationAndCondition : IUIAutomationCondition
{
	public new const Guid IID = .(0xa7d0af36, 0xb912, 0x45fe, 0x98, 0x55, 0x09, 0x1d, 0xdc, 0x17, 0x4a, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationCondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* childCount) get_ChildCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition*** childArray, int32* childArrayCount) GetChildrenAsNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** childArray) GetChildren;
	}


	public HRESULT get_ChildCount(int32* childCount) mut => VT.[Friend]get_ChildCount(&this, childCount);

	public HRESULT GetChildrenAsNativeArray(IUIAutomationCondition*** childArray, int32* childArrayCount) mut => VT.[Friend]GetChildrenAsNativeArray(&this, childArray, childArrayCount);

	public HRESULT GetChildren(SAFEARRAY** childArray) mut => VT.[Friend]GetChildren(&this, childArray);
}

[CRepr]struct IUIAutomationOrCondition : IUIAutomationCondition
{
	public new const Guid IID = .(0x8753f032, 0x3db1, 0x47b5, 0xa1, 0xfc, 0x6e, 0x34, 0xa2, 0x66, 0xc7, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationCondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* childCount) get_ChildCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition*** childArray, int32* childArrayCount) GetChildrenAsNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** childArray) GetChildren;
	}


	public HRESULT get_ChildCount(int32* childCount) mut => VT.[Friend]get_ChildCount(&this, childCount);

	public HRESULT GetChildrenAsNativeArray(IUIAutomationCondition*** childArray, int32* childArrayCount) mut => VT.[Friend]GetChildrenAsNativeArray(&this, childArray, childArrayCount);

	public HRESULT GetChildren(SAFEARRAY** childArray) mut => VT.[Friend]GetChildren(&this, childArray);
}

[CRepr]struct IUIAutomationNotCondition : IUIAutomationCondition
{
	public new const Guid IID = .(0xf528b657, 0x847b, 0x498c, 0x88, 0x96, 0xd5, 0x2b, 0x56, 0x54, 0x07, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationCondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** condition) GetChild;
	}


	public HRESULT GetChild(IUIAutomationCondition** condition) mut => VT.[Friend]GetChild(&this, condition);
}

[CRepr]struct IUIAutomationCacheRequest : IUnknown
{
	public new const Guid IID = .(0xb32a92b5, 0xbc25, 0x4078, 0x9c, 0x08, 0xd7, 0xee, 0x95, 0xc4, 0x8e, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId) AddProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 patternId) AddPattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest** clonedRequest) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope* @scope) get_TreeScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope) put_TreeScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** filter) get_TreeFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition* filter) put_TreeFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AutomationElementMode* mode) get_AutomationElementMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AutomationElementMode mode) put_AutomationElementMode;
	}


	public HRESULT AddProperty(int32 propertyId) mut => VT.[Friend]AddProperty(&this, propertyId);

	public HRESULT AddPattern(int32 patternId) mut => VT.[Friend]AddPattern(&this, patternId);

	public HRESULT Clone(IUIAutomationCacheRequest** clonedRequest) mut => VT.[Friend]Clone(&this, clonedRequest);

	public HRESULT get_TreeScope(TreeScope* @scope) mut => VT.[Friend]get_TreeScope(&this, @scope);

	public HRESULT put_TreeScope(TreeScope @scope) mut => VT.[Friend]put_TreeScope(&this, @scope);

	public HRESULT get_TreeFilter(IUIAutomationCondition** filter) mut => VT.[Friend]get_TreeFilter(&this, filter);

	public HRESULT put_TreeFilter(IUIAutomationCondition* filter) mut => VT.[Friend]put_TreeFilter(&this, filter);

	public HRESULT get_AutomationElementMode(AutomationElementMode* mode) mut => VT.[Friend]get_AutomationElementMode(&this, mode);

	public HRESULT put_AutomationElementMode(AutomationElementMode mode) mut => VT.[Friend]put_AutomationElementMode(&this, mode);
}

[CRepr]struct IUIAutomationTreeWalker : IUnknown
{
	public new const Guid IID = .(0x4042c624, 0x389c, 0x4afc, 0xa6, 0x30, 0x9d, 0xf8, 0x54, 0xa5, 0x41, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationElement** parent) GetParentElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationElement** first) GetFirstChildElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationElement** last) GetLastChildElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationElement** next) GetNextSiblingElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationElement** previous) GetPreviousSiblingElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationElement** normalized) NormalizeElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** parent) GetParentElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** first) GetFirstChildElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** last) GetLastChildElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** next) GetNextSiblingElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** previous) GetPreviousSiblingElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** normalized) NormalizeElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** condition) get_Condition;
	}


	public HRESULT GetParentElement(IUIAutomationElement* element, IUIAutomationElement** parent) mut => VT.[Friend]GetParentElement(&this, element, parent);

	public HRESULT GetFirstChildElement(IUIAutomationElement* element, IUIAutomationElement** first) mut => VT.[Friend]GetFirstChildElement(&this, element, first);

	public HRESULT GetLastChildElement(IUIAutomationElement* element, IUIAutomationElement** last) mut => VT.[Friend]GetLastChildElement(&this, element, last);

	public HRESULT GetNextSiblingElement(IUIAutomationElement* element, IUIAutomationElement** next) mut => VT.[Friend]GetNextSiblingElement(&this, element, next);

	public HRESULT GetPreviousSiblingElement(IUIAutomationElement* element, IUIAutomationElement** previous) mut => VT.[Friend]GetPreviousSiblingElement(&this, element, previous);

	public HRESULT NormalizeElement(IUIAutomationElement* element, IUIAutomationElement** normalized) mut => VT.[Friend]NormalizeElement(&this, element, normalized);

	public HRESULT GetParentElementBuildCache(IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** parent) mut => VT.[Friend]GetParentElementBuildCache(&this, element, cacheRequest, parent);

	public HRESULT GetFirstChildElementBuildCache(IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** first) mut => VT.[Friend]GetFirstChildElementBuildCache(&this, element, cacheRequest, first);

	public HRESULT GetLastChildElementBuildCache(IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** last) mut => VT.[Friend]GetLastChildElementBuildCache(&this, element, cacheRequest, last);

	public HRESULT GetNextSiblingElementBuildCache(IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** next) mut => VT.[Friend]GetNextSiblingElementBuildCache(&this, element, cacheRequest, next);

	public HRESULT GetPreviousSiblingElementBuildCache(IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** previous) mut => VT.[Friend]GetPreviousSiblingElementBuildCache(&this, element, cacheRequest, previous);

	public HRESULT NormalizeElementBuildCache(IUIAutomationElement* element, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** normalized) mut => VT.[Friend]NormalizeElementBuildCache(&this, element, cacheRequest, normalized);

	public HRESULT get_Condition(IUIAutomationCondition** condition) mut => VT.[Friend]get_Condition(&this, condition);
}

[CRepr]struct IUIAutomationEventHandler : IUnknown
{
	public new const Guid IID = .(0x146c3c17, 0xf12e, 0x4e22, 0x8c, 0x27, 0xf8, 0x94, 0xb9, 0xb7, 0x9c, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, int32 eventId) HandleAutomationEvent;
	}


	public HRESULT HandleAutomationEvent(IUIAutomationElement* sender, int32 eventId) mut => VT.[Friend]HandleAutomationEvent(&this, sender, eventId);
}

[CRepr]struct IUIAutomationPropertyChangedEventHandler : IUnknown
{
	public new const Guid IID = .(0x40cd37d4, 0xc756, 0x4b0c, 0x8c, 0x6f, 0xbd, 0xdf, 0xee, 0xb1, 0x3b, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, int32 propertyId, VARIANT newValue) HandlePropertyChangedEvent;
	}


	public HRESULT HandlePropertyChangedEvent(IUIAutomationElement* sender, int32 propertyId, VARIANT newValue) mut => VT.[Friend]HandlePropertyChangedEvent(&this, sender, propertyId, newValue);
}

[CRepr]struct IUIAutomationStructureChangedEventHandler : IUnknown
{
	public new const Guid IID = .(0xe81d1b4e, 0x11c5, 0x42f8, 0x97, 0x54, 0xe7, 0x03, 0x6c, 0x79, 0xf0, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, StructureChangeType changeType, SAFEARRAY* runtimeId) HandleStructureChangedEvent;
	}


	public HRESULT HandleStructureChangedEvent(IUIAutomationElement* sender, StructureChangeType changeType, SAFEARRAY* runtimeId) mut => VT.[Friend]HandleStructureChangedEvent(&this, sender, changeType, runtimeId);
}

[CRepr]struct IUIAutomationFocusChangedEventHandler : IUnknown
{
	public new const Guid IID = .(0xc270f6b5, 0x5c69, 0x4290, 0x97, 0x45, 0x7a, 0x7f, 0x97, 0x16, 0x94, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender) HandleFocusChangedEvent;
	}


	public HRESULT HandleFocusChangedEvent(IUIAutomationElement* sender) mut => VT.[Friend]HandleFocusChangedEvent(&this, sender);
}

[CRepr]struct IUIAutomationTextEditTextChangedEventHandler : IUnknown
{
	public new const Guid IID = .(0x92faa680, 0xe704, 0x4156, 0x93, 0x1a, 0xe3, 0x2d, 0x5b, 0xb3, 0x8f, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, TextEditChangeType textEditChangeType, SAFEARRAY* eventStrings) HandleTextEditTextChangedEvent;
	}


	public HRESULT HandleTextEditTextChangedEvent(IUIAutomationElement* sender, TextEditChangeType textEditChangeType, SAFEARRAY* eventStrings) mut => VT.[Friend]HandleTextEditTextChangedEvent(&this, sender, textEditChangeType, eventStrings);
}

[CRepr]struct IUIAutomationChangesEventHandler : IUnknown
{
	public new const Guid IID = .(0x58edca55, 0x2c3e, 0x4980, 0xb1, 0xb9, 0x56, 0xc1, 0x7f, 0x27, 0xa2, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, UiaChangeInfo* uiaChanges, int32 changesCount) HandleChangesEvent;
	}


	public HRESULT HandleChangesEvent(IUIAutomationElement* sender, UiaChangeInfo* uiaChanges, int32 changesCount) mut => VT.[Friend]HandleChangesEvent(&this, sender, uiaChanges, changesCount);
}

[CRepr]struct IUIAutomationNotificationEventHandler : IUnknown
{
	public new const Guid IID = .(0xc7cb2637, 0xe6c2, 0x4d0c, 0x85, 0xde, 0x49, 0x48, 0xc0, 0x21, 0x75, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, NotificationKind notificationKind, NotificationProcessing notificationProcessing, BSTR displayString, BSTR activityId) HandleNotificationEvent;
	}


	public HRESULT HandleNotificationEvent(IUIAutomationElement* sender, NotificationKind notificationKind, NotificationProcessing notificationProcessing, BSTR displayString, BSTR activityId) mut => VT.[Friend]HandleNotificationEvent(&this, sender, notificationKind, notificationProcessing, displayString, activityId);
}

[CRepr]struct IUIAutomationInvokePattern : IUnknown
{
	public new const Guid IID = .(0xfb377fbe, 0x8ea6, 0x46d5, 0x9c, 0x73, 0x64, 0x99, 0x64, 0x2d, 0x30, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Invoke;
	}


	public HRESULT Invoke() mut => VT.[Friend]Invoke(&this);
}

[CRepr]struct IUIAutomationDockPattern : IUnknown
{
	public new const Guid IID = .(0xfde5ef97, 0x1464, 0x48f6, 0x90, 0xbf, 0x43, 0xd0, 0x94, 0x8e, 0x86, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DockPosition dockPos) SetDockPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DockPosition* retVal) get_CurrentDockPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DockPosition* retVal) get_CachedDockPosition;
	}


	public HRESULT SetDockPosition(DockPosition dockPos) mut => VT.[Friend]SetDockPosition(&this, dockPos);

	public HRESULT get_CurrentDockPosition(DockPosition* retVal) mut => VT.[Friend]get_CurrentDockPosition(&this, retVal);

	public HRESULT get_CachedDockPosition(DockPosition* retVal) mut => VT.[Friend]get_CachedDockPosition(&this, retVal);
}

[CRepr]struct IUIAutomationExpandCollapsePattern : IUnknown
{
	public new const Guid IID = .(0x619be086, 0x1f4e, 0x4ee4, 0xba, 0xfa, 0x21, 0x01, 0x28, 0x73, 0x87, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Expand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Collapse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ExpandCollapseState* retVal) get_CurrentExpandCollapseState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ExpandCollapseState* retVal) get_CachedExpandCollapseState;
	}


	public HRESULT Expand() mut => VT.[Friend]Expand(&this);

	public HRESULT Collapse() mut => VT.[Friend]Collapse(&this);

	public HRESULT get_CurrentExpandCollapseState(ExpandCollapseState* retVal) mut => VT.[Friend]get_CurrentExpandCollapseState(&this, retVal);

	public HRESULT get_CachedExpandCollapseState(ExpandCollapseState* retVal) mut => VT.[Friend]get_CachedExpandCollapseState(&this, retVal);
}

[CRepr]struct IUIAutomationGridPattern : IUnknown
{
	public new const Guid IID = .(0x414c3cdc, 0x856b, 0x4f5b, 0x85, 0x38, 0x31, 0x31, 0xc6, 0x30, 0x25, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, IUIAutomationElement** element) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentRowCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedRowCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedColumnCount;
	}


	public HRESULT GetItem(int32 row, int32 column, IUIAutomationElement** element) mut => VT.[Friend]GetItem(&this, row, column, element);

	public HRESULT get_CurrentRowCount(int32* retVal) mut => VT.[Friend]get_CurrentRowCount(&this, retVal);

	public HRESULT get_CurrentColumnCount(int32* retVal) mut => VT.[Friend]get_CurrentColumnCount(&this, retVal);

	public HRESULT get_CachedRowCount(int32* retVal) mut => VT.[Friend]get_CachedRowCount(&this, retVal);

	public HRESULT get_CachedColumnCount(int32* retVal) mut => VT.[Friend]get_CachedColumnCount(&this, retVal);
}

[CRepr]struct IUIAutomationGridItemPattern : IUnknown
{
	public new const Guid IID = .(0x78f8ef57, 0x66c3, 0x4e09, 0xbd, 0x7c, 0xe7, 0x9b, 0x20, 0x04, 0x89, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentContainingGrid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentRowSpan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentColumnSpan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedContainingGrid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedRowSpan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedColumnSpan;
	}


	public HRESULT get_CurrentContainingGrid(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentContainingGrid(&this, retVal);

	public HRESULT get_CurrentRow(int32* retVal) mut => VT.[Friend]get_CurrentRow(&this, retVal);

	public HRESULT get_CurrentColumn(int32* retVal) mut => VT.[Friend]get_CurrentColumn(&this, retVal);

	public HRESULT get_CurrentRowSpan(int32* retVal) mut => VT.[Friend]get_CurrentRowSpan(&this, retVal);

	public HRESULT get_CurrentColumnSpan(int32* retVal) mut => VT.[Friend]get_CurrentColumnSpan(&this, retVal);

	public HRESULT get_CachedContainingGrid(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedContainingGrid(&this, retVal);

	public HRESULT get_CachedRow(int32* retVal) mut => VT.[Friend]get_CachedRow(&this, retVal);

	public HRESULT get_CachedColumn(int32* retVal) mut => VT.[Friend]get_CachedColumn(&this, retVal);

	public HRESULT get_CachedRowSpan(int32* retVal) mut => VT.[Friend]get_CachedRowSpan(&this, retVal);

	public HRESULT get_CachedColumnSpan(int32* retVal) mut => VT.[Friend]get_CachedColumnSpan(&this, retVal);
}

[CRepr]struct IUIAutomationMultipleViewPattern : IUnknown
{
	public new const Guid IID = .(0x8d253c91, 0x1dc5, 0x4bb5, 0xb1, 0x8f, 0xad, 0xe1, 0x6f, 0xa4, 0x95, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 view, BSTR* name) GetViewName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 view) SetCurrentView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentCurrentView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) GetCurrentSupportedViews;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedCurrentView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) GetCachedSupportedViews;
	}


	public HRESULT GetViewName(int32 view, BSTR* name) mut => VT.[Friend]GetViewName(&this, view, name);

	public HRESULT SetCurrentView(int32 view) mut => VT.[Friend]SetCurrentView(&this, view);

	public HRESULT get_CurrentCurrentView(int32* retVal) mut => VT.[Friend]get_CurrentCurrentView(&this, retVal);

	public HRESULT GetCurrentSupportedViews(SAFEARRAY** retVal) mut => VT.[Friend]GetCurrentSupportedViews(&this, retVal);

	public HRESULT get_CachedCurrentView(int32* retVal) mut => VT.[Friend]get_CachedCurrentView(&this, retVal);

	public HRESULT GetCachedSupportedViews(SAFEARRAY** retVal) mut => VT.[Friend]GetCachedSupportedViews(&this, retVal);
}

[CRepr]struct IUIAutomationObjectModelPattern : IUnknown
{
	public new const Guid IID = .(0x71c284b3, 0xc14d, 0x4d14, 0x98, 0x1e, 0x19, 0x75, 0x1b, 0x0d, 0x75, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retVal) GetUnderlyingObjectModel;
	}


	public HRESULT GetUnderlyingObjectModel(IUnknown** retVal) mut => VT.[Friend]GetUnderlyingObjectModel(&this, retVal);
}

[CRepr]struct IUIAutomationRangeValuePattern : IUnknown
{
	public new const Guid IID = .(0x59213f4f, 0x7346, 0x49e5, 0xb1, 0x20, 0x80, 0x55, 0x59, 0x87, 0xa1, 0x48);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double val) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentMaximum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentMinimum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentLargeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentSmallChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedMaximum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedMinimum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedLargeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedSmallChange;
	}


	public HRESULT SetValue(double val) mut => VT.[Friend]SetValue(&this, val);

	public HRESULT get_CurrentValue(double* retVal) mut => VT.[Friend]get_CurrentValue(&this, retVal);

	public HRESULT get_CurrentIsReadOnly(BOOL* retVal) mut => VT.[Friend]get_CurrentIsReadOnly(&this, retVal);

	public HRESULT get_CurrentMaximum(double* retVal) mut => VT.[Friend]get_CurrentMaximum(&this, retVal);

	public HRESULT get_CurrentMinimum(double* retVal) mut => VT.[Friend]get_CurrentMinimum(&this, retVal);

	public HRESULT get_CurrentLargeChange(double* retVal) mut => VT.[Friend]get_CurrentLargeChange(&this, retVal);

	public HRESULT get_CurrentSmallChange(double* retVal) mut => VT.[Friend]get_CurrentSmallChange(&this, retVal);

	public HRESULT get_CachedValue(double* retVal) mut => VT.[Friend]get_CachedValue(&this, retVal);

	public HRESULT get_CachedIsReadOnly(BOOL* retVal) mut => VT.[Friend]get_CachedIsReadOnly(&this, retVal);

	public HRESULT get_CachedMaximum(double* retVal) mut => VT.[Friend]get_CachedMaximum(&this, retVal);

	public HRESULT get_CachedMinimum(double* retVal) mut => VT.[Friend]get_CachedMinimum(&this, retVal);

	public HRESULT get_CachedLargeChange(double* retVal) mut => VT.[Friend]get_CachedLargeChange(&this, retVal);

	public HRESULT get_CachedSmallChange(double* retVal) mut => VT.[Friend]get_CachedSmallChange(&this, retVal);
}

[CRepr]struct IUIAutomationScrollPattern : IUnknown
{
	public new const Guid IID = .(0x88f4d42a, 0xe881, 0x459d, 0xa7, 0x7c, 0x73, 0xbb, 0xbb, 0x7e, 0x02, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ScrollAmount horizontalAmount, ScrollAmount verticalAmount) Scroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double horizontalPercent, double verticalPercent) SetScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentHorizontalScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentVerticalScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentHorizontalViewSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentVerticalViewSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentHorizontallyScrollable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentVerticallyScrollable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedHorizontalScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedVerticalScrollPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedHorizontalViewSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedVerticalViewSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedHorizontallyScrollable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedVerticallyScrollable;
	}


	public HRESULT Scroll(ScrollAmount horizontalAmount, ScrollAmount verticalAmount) mut => VT.[Friend]Scroll(&this, horizontalAmount, verticalAmount);

	public HRESULT SetScrollPercent(double horizontalPercent, double verticalPercent) mut => VT.[Friend]SetScrollPercent(&this, horizontalPercent, verticalPercent);

	public HRESULT get_CurrentHorizontalScrollPercent(double* retVal) mut => VT.[Friend]get_CurrentHorizontalScrollPercent(&this, retVal);

	public HRESULT get_CurrentVerticalScrollPercent(double* retVal) mut => VT.[Friend]get_CurrentVerticalScrollPercent(&this, retVal);

	public HRESULT get_CurrentHorizontalViewSize(double* retVal) mut => VT.[Friend]get_CurrentHorizontalViewSize(&this, retVal);

	public HRESULT get_CurrentVerticalViewSize(double* retVal) mut => VT.[Friend]get_CurrentVerticalViewSize(&this, retVal);

	public HRESULT get_CurrentHorizontallyScrollable(BOOL* retVal) mut => VT.[Friend]get_CurrentHorizontallyScrollable(&this, retVal);

	public HRESULT get_CurrentVerticallyScrollable(BOOL* retVal) mut => VT.[Friend]get_CurrentVerticallyScrollable(&this, retVal);

	public HRESULT get_CachedHorizontalScrollPercent(double* retVal) mut => VT.[Friend]get_CachedHorizontalScrollPercent(&this, retVal);

	public HRESULT get_CachedVerticalScrollPercent(double* retVal) mut => VT.[Friend]get_CachedVerticalScrollPercent(&this, retVal);

	public HRESULT get_CachedHorizontalViewSize(double* retVal) mut => VT.[Friend]get_CachedHorizontalViewSize(&this, retVal);

	public HRESULT get_CachedVerticalViewSize(double* retVal) mut => VT.[Friend]get_CachedVerticalViewSize(&this, retVal);

	public HRESULT get_CachedHorizontallyScrollable(BOOL* retVal) mut => VT.[Friend]get_CachedHorizontallyScrollable(&this, retVal);

	public HRESULT get_CachedVerticallyScrollable(BOOL* retVal) mut => VT.[Friend]get_CachedVerticallyScrollable(&this, retVal);
}

[CRepr]struct IUIAutomationScrollItemPattern : IUnknown
{
	public new const Guid IID = .(0xb488300f, 0xd015, 0x4f19, 0x9c, 0x29, 0xbb, 0x59, 0x5e, 0x36, 0x45, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ScrollIntoView;
	}


	public HRESULT ScrollIntoView() mut => VT.[Friend]ScrollIntoView(&this);
}

[CRepr]struct IUIAutomationSelectionPattern : IUnknown
{
	public new const Guid IID = .(0x5ed5202e, 0xb2ac, 0x47a6, 0xb6, 0x38, 0x4b, 0x0b, 0xf1, 0x40, 0xd7, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanSelectMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsSelectionRequired;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanSelectMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsSelectionRequired;
	}


	public HRESULT GetCurrentSelection(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentSelection(&this, retVal);

	public HRESULT get_CurrentCanSelectMultiple(BOOL* retVal) mut => VT.[Friend]get_CurrentCanSelectMultiple(&this, retVal);

	public HRESULT get_CurrentIsSelectionRequired(BOOL* retVal) mut => VT.[Friend]get_CurrentIsSelectionRequired(&this, retVal);

	public HRESULT GetCachedSelection(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedSelection(&this, retVal);

	public HRESULT get_CachedCanSelectMultiple(BOOL* retVal) mut => VT.[Friend]get_CachedCanSelectMultiple(&this, retVal);

	public HRESULT get_CachedIsSelectionRequired(BOOL* retVal) mut => VT.[Friend]get_CachedIsSelectionRequired(&this, retVal);
}

[CRepr]struct IUIAutomationSelectionPattern2 : IUIAutomationSelectionPattern
{
	public new const Guid IID = .(0x0532bfae, 0xc011, 0x4e32, 0xa3, 0x43, 0x6d, 0x64, 0x2d, 0x79, 0x85, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationSelectionPattern.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentFirstSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentLastSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentCurrentSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedFirstSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedLastSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedCurrentSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedItemCount;
	}


	public HRESULT get_CurrentFirstSelectedItem(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentFirstSelectedItem(&this, retVal);

	public HRESULT get_CurrentLastSelectedItem(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentLastSelectedItem(&this, retVal);

	public HRESULT get_CurrentCurrentSelectedItem(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentCurrentSelectedItem(&this, retVal);

	public HRESULT get_CurrentItemCount(int32* retVal) mut => VT.[Friend]get_CurrentItemCount(&this, retVal);

	public HRESULT get_CachedFirstSelectedItem(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedFirstSelectedItem(&this, retVal);

	public HRESULT get_CachedLastSelectedItem(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedLastSelectedItem(&this, retVal);

	public HRESULT get_CachedCurrentSelectedItem(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedCurrentSelectedItem(&this, retVal);

	public HRESULT get_CachedItemCount(int32* retVal) mut => VT.[Friend]get_CachedItemCount(&this, retVal);
}

[CRepr]struct IUIAutomationSelectionItemPattern : IUnknown
{
	public new const Guid IID = .(0xa8efa66a, 0x0fda, 0x421a, 0x91, 0x94, 0x38, 0x02, 0x1f, 0x35, 0x78, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddToSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveFromSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentSelectionContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedSelectionContainer;
	}


	public HRESULT Select() mut => VT.[Friend]Select(&this);

	public HRESULT AddToSelection() mut => VT.[Friend]AddToSelection(&this);

	public HRESULT RemoveFromSelection() mut => VT.[Friend]RemoveFromSelection(&this);

	public HRESULT get_CurrentIsSelected(BOOL* retVal) mut => VT.[Friend]get_CurrentIsSelected(&this, retVal);

	public HRESULT get_CurrentSelectionContainer(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentSelectionContainer(&this, retVal);

	public HRESULT get_CachedIsSelected(BOOL* retVal) mut => VT.[Friend]get_CachedIsSelected(&this, retVal);

	public HRESULT get_CachedSelectionContainer(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedSelectionContainer(&this, retVal);
}

[CRepr]struct IUIAutomationSynchronizedInputPattern : IUnknown
{
	public new const Guid IID = .(0x2233be0b, 0xafb7, 0x448b, 0x9f, 0xda, 0x3b, 0x37, 0x8a, 0xa5, 0xea, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SynchronizedInputType inputType) StartListening;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT StartListening(SynchronizedInputType inputType) mut => VT.[Friend]StartListening(&this, inputType);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IUIAutomationTablePattern : IUnknown
{
	public new const Guid IID = .(0x620e691c, 0xea96, 0x4710, 0xa8, 0x50, 0x75, 0x4b, 0x24, 0xce, 0x24, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentRowHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentColumnHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RowOrColumnMajor* retVal) get_CurrentRowOrColumnMajor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedRowHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedColumnHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RowOrColumnMajor* retVal) get_CachedRowOrColumnMajor;
	}


	public HRESULT GetCurrentRowHeaders(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentRowHeaders(&this, retVal);

	public HRESULT GetCurrentColumnHeaders(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentColumnHeaders(&this, retVal);

	public HRESULT get_CurrentRowOrColumnMajor(RowOrColumnMajor* retVal) mut => VT.[Friend]get_CurrentRowOrColumnMajor(&this, retVal);

	public HRESULT GetCachedRowHeaders(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedRowHeaders(&this, retVal);

	public HRESULT GetCachedColumnHeaders(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedColumnHeaders(&this, retVal);

	public HRESULT get_CachedRowOrColumnMajor(RowOrColumnMajor* retVal) mut => VT.[Friend]get_CachedRowOrColumnMajor(&this, retVal);
}

[CRepr]struct IUIAutomationTableItemPattern : IUnknown
{
	public new const Guid IID = .(0x0b964eb3, 0xef2e, 0x4464, 0x9c, 0x79, 0x61, 0xd6, 0x17, 0x37, 0xa2, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentRowHeaderItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentColumnHeaderItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedRowHeaderItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedColumnHeaderItems;
	}


	public HRESULT GetCurrentRowHeaderItems(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentRowHeaderItems(&this, retVal);

	public HRESULT GetCurrentColumnHeaderItems(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentColumnHeaderItems(&this, retVal);

	public HRESULT GetCachedRowHeaderItems(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedRowHeaderItems(&this, retVal);

	public HRESULT GetCachedColumnHeaderItems(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedColumnHeaderItems(&this, retVal);
}

[CRepr]struct IUIAutomationTogglePattern : IUnknown
{
	public new const Guid IID = .(0x94cf8058, 0x9b8d, 0x4ab9, 0x8b, 0xfd, 0x4c, 0xd0, 0xa3, 0x3c, 0x8c, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Toggle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ToggleState* retVal) get_CurrentToggleState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ToggleState* retVal) get_CachedToggleState;
	}


	public HRESULT Toggle() mut => VT.[Friend]Toggle(&this);

	public HRESULT get_CurrentToggleState(ToggleState* retVal) mut => VT.[Friend]get_CurrentToggleState(&this, retVal);

	public HRESULT get_CachedToggleState(ToggleState* retVal) mut => VT.[Friend]get_CachedToggleState(&this, retVal);
}

[CRepr]struct IUIAutomationTransformPattern : IUnknown
{
	public new const Guid IID = .(0xa9b55844, 0xa55d, 0x4ef0, 0x92, 0x6d, 0x56, 0x9c, 0x16, 0xff, 0x89, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double x, double y) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double width, double height) Resize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double degrees) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanMove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanResize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanRotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanMove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanResize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanRotate;
	}


	public HRESULT Move(double x, double y) mut => VT.[Friend]Move(&this, x, y);

	public HRESULT Resize(double width, double height) mut => VT.[Friend]Resize(&this, width, height);

	public HRESULT Rotate(double degrees) mut => VT.[Friend]Rotate(&this, degrees);

	public HRESULT get_CurrentCanMove(BOOL* retVal) mut => VT.[Friend]get_CurrentCanMove(&this, retVal);

	public HRESULT get_CurrentCanResize(BOOL* retVal) mut => VT.[Friend]get_CurrentCanResize(&this, retVal);

	public HRESULT get_CurrentCanRotate(BOOL* retVal) mut => VT.[Friend]get_CurrentCanRotate(&this, retVal);

	public HRESULT get_CachedCanMove(BOOL* retVal) mut => VT.[Friend]get_CachedCanMove(&this, retVal);

	public HRESULT get_CachedCanResize(BOOL* retVal) mut => VT.[Friend]get_CachedCanResize(&this, retVal);

	public HRESULT get_CachedCanRotate(BOOL* retVal) mut => VT.[Friend]get_CachedCanRotate(&this, retVal);
}

[CRepr]struct IUIAutomationValuePattern : IUnknown
{
	public new const Guid IID = .(0xa94cd8b1, 0x0844, 0x4cd6, 0x9d, 0x2d, 0x64, 0x05, 0x37, 0xab, 0x39, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR val) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsReadOnly;
	}


	public HRESULT SetValue(BSTR val) mut => VT.[Friend]SetValue(&this, val);

	public HRESULT get_CurrentValue(BSTR* retVal) mut => VT.[Friend]get_CurrentValue(&this, retVal);

	public HRESULT get_CurrentIsReadOnly(BOOL* retVal) mut => VT.[Friend]get_CurrentIsReadOnly(&this, retVal);

	public HRESULT get_CachedValue(BSTR* retVal) mut => VT.[Friend]get_CachedValue(&this, retVal);

	public HRESULT get_CachedIsReadOnly(BOOL* retVal) mut => VT.[Friend]get_CachedIsReadOnly(&this, retVal);
}

[CRepr]struct IUIAutomationWindowPattern : IUnknown
{
	public new const Guid IID = .(0x0faef453, 0x9208, 0x43ef, 0xbb, 0xb2, 0x3b, 0x48, 0x51, 0x77, 0x86, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 milliseconds, BOOL* success) WaitForInputIdle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowVisualState state) SetWindowVisualState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanMaximize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanMinimize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsModal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsTopmost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowVisualState* retVal) get_CurrentWindowVisualState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowInteractionState* retVal) get_CurrentWindowInteractionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanMaximize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanMinimize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsModal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsTopmost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowVisualState* retVal) get_CachedWindowVisualState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowInteractionState* retVal) get_CachedWindowInteractionState;
	}


	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT WaitForInputIdle(int32 milliseconds, BOOL* success) mut => VT.[Friend]WaitForInputIdle(&this, milliseconds, success);

	public HRESULT SetWindowVisualState(WindowVisualState state) mut => VT.[Friend]SetWindowVisualState(&this, state);

	public HRESULT get_CurrentCanMaximize(BOOL* retVal) mut => VT.[Friend]get_CurrentCanMaximize(&this, retVal);

	public HRESULT get_CurrentCanMinimize(BOOL* retVal) mut => VT.[Friend]get_CurrentCanMinimize(&this, retVal);

	public HRESULT get_CurrentIsModal(BOOL* retVal) mut => VT.[Friend]get_CurrentIsModal(&this, retVal);

	public HRESULT get_CurrentIsTopmost(BOOL* retVal) mut => VT.[Friend]get_CurrentIsTopmost(&this, retVal);

	public HRESULT get_CurrentWindowVisualState(WindowVisualState* retVal) mut => VT.[Friend]get_CurrentWindowVisualState(&this, retVal);

	public HRESULT get_CurrentWindowInteractionState(WindowInteractionState* retVal) mut => VT.[Friend]get_CurrentWindowInteractionState(&this, retVal);

	public HRESULT get_CachedCanMaximize(BOOL* retVal) mut => VT.[Friend]get_CachedCanMaximize(&this, retVal);

	public HRESULT get_CachedCanMinimize(BOOL* retVal) mut => VT.[Friend]get_CachedCanMinimize(&this, retVal);

	public HRESULT get_CachedIsModal(BOOL* retVal) mut => VT.[Friend]get_CachedIsModal(&this, retVal);

	public HRESULT get_CachedIsTopmost(BOOL* retVal) mut => VT.[Friend]get_CachedIsTopmost(&this, retVal);

	public HRESULT get_CachedWindowVisualState(WindowVisualState* retVal) mut => VT.[Friend]get_CachedWindowVisualState(&this, retVal);

	public HRESULT get_CachedWindowInteractionState(WindowInteractionState* retVal) mut => VT.[Friend]get_CachedWindowInteractionState(&this, retVal);
}

[CRepr]struct IUIAutomationTextRange : IUnknown
{
	public new const Guid IID = .(0xa543cc6a, 0xf4ae, 0x494b, 0x82, 0x39, 0xc8, 0x14, 0x48, 0x11, 0x87, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRange** clonedRange) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRange* range, BOOL* areSame) Compare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextPatternRangeEndpoint srcEndPoint, IUIAutomationTextRange* range, TextPatternRangeEndpoint targetEndPoint, int32* compValue) CompareEndpoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextUnit textUnit) ExpandToEnclosingUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 attr, VARIANT val, BOOL backward, IUIAutomationTextRange** found) FindAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR text, BOOL backward, BOOL ignoreCase, IUIAutomationTextRange** found) FindText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 attr, VARIANT* value) GetAttributeValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** boundingRects) GetBoundingRectangles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** enclosingElement) GetEnclosingElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 maxLength, BSTR* text) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextUnit unit, int32 count, int32* moved) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextPatternRangeEndpoint endpoint, TextUnit unit, int32 count, int32* moved) MoveEndpointByUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TextPatternRangeEndpoint srcEndPoint, IUIAutomationTextRange* range, TextPatternRangeEndpoint targetEndPoint) MoveEndpointByRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddToSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveFromSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL alignToTop) ScrollIntoView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** children) GetChildren;
	}


	public HRESULT Clone(IUIAutomationTextRange** clonedRange) mut => VT.[Friend]Clone(&this, clonedRange);

	public HRESULT Compare(IUIAutomationTextRange* range, BOOL* areSame) mut => VT.[Friend]Compare(&this, range, areSame);

	public HRESULT CompareEndpoints(TextPatternRangeEndpoint srcEndPoint, IUIAutomationTextRange* range, TextPatternRangeEndpoint targetEndPoint, int32* compValue) mut => VT.[Friend]CompareEndpoints(&this, srcEndPoint, range, targetEndPoint, compValue);

	public HRESULT ExpandToEnclosingUnit(TextUnit textUnit) mut => VT.[Friend]ExpandToEnclosingUnit(&this, textUnit);

	public HRESULT FindAttribute(int32 attr, VARIANT val, BOOL backward, IUIAutomationTextRange** found) mut => VT.[Friend]FindAttribute(&this, attr, val, backward, found);

	public HRESULT FindText(BSTR text, BOOL backward, BOOL ignoreCase, IUIAutomationTextRange** found) mut => VT.[Friend]FindText(&this, text, backward, ignoreCase, found);

	public HRESULT GetAttributeValue(int32 attr, VARIANT* value) mut => VT.[Friend]GetAttributeValue(&this, attr, value);

	public HRESULT GetBoundingRectangles(SAFEARRAY** boundingRects) mut => VT.[Friend]GetBoundingRectangles(&this, boundingRects);

	public HRESULT GetEnclosingElement(IUIAutomationElement** enclosingElement) mut => VT.[Friend]GetEnclosingElement(&this, enclosingElement);

	public HRESULT GetText(int32 maxLength, BSTR* text) mut => VT.[Friend]GetText(&this, maxLength, text);

	public HRESULT Move(TextUnit unit, int32 count, int32* moved) mut => VT.[Friend]Move(&this, unit, count, moved);

	public HRESULT MoveEndpointByUnit(TextPatternRangeEndpoint endpoint, TextUnit unit, int32 count, int32* moved) mut => VT.[Friend]MoveEndpointByUnit(&this, endpoint, unit, count, moved);

	public HRESULT MoveEndpointByRange(TextPatternRangeEndpoint srcEndPoint, IUIAutomationTextRange* range, TextPatternRangeEndpoint targetEndPoint) mut => VT.[Friend]MoveEndpointByRange(&this, srcEndPoint, range, targetEndPoint);

	public HRESULT Select() mut => VT.[Friend]Select(&this);

	public HRESULT AddToSelection() mut => VT.[Friend]AddToSelection(&this);

	public HRESULT RemoveFromSelection() mut => VT.[Friend]RemoveFromSelection(&this);

	public HRESULT ScrollIntoView(BOOL alignToTop) mut => VT.[Friend]ScrollIntoView(&this, alignToTop);

	public HRESULT GetChildren(IUIAutomationElementArray** children) mut => VT.[Friend]GetChildren(&this, children);
}

[CRepr]struct IUIAutomationTextRange2 : IUIAutomationTextRange
{
	public new const Guid IID = .(0xbb9b40e0, 0x5e04, 0x46bd, 0x9b, 0xe0, 0x4b, 0x60, 0x1b, 0x9a, 0xfa, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationTextRange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowContextMenu;
	}


	public HRESULT ShowContextMenu() mut => VT.[Friend]ShowContextMenu(&this);
}

[CRepr]struct IUIAutomationTextRange3 : IUIAutomationTextRange2
{
	public new const Guid IID = .(0x6a315d69, 0x5512, 0x4c2e, 0x85, 0xf0, 0x53, 0xfc, 0xe6, 0xdd, 0x4b, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationTextRange2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** enclosingElement) GetEnclosingElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElementArray** children) GetChildrenBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* attributeIds, int32 attributeIdCount, SAFEARRAY** attributeValues) GetAttributeValues;
	}


	public HRESULT GetEnclosingElementBuildCache(IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** enclosingElement) mut => VT.[Friend]GetEnclosingElementBuildCache(&this, cacheRequest, enclosingElement);

	public HRESULT GetChildrenBuildCache(IUIAutomationCacheRequest* cacheRequest, IUIAutomationElementArray** children) mut => VT.[Friend]GetChildrenBuildCache(&this, cacheRequest, children);

	public HRESULT GetAttributeValues(int32* attributeIds, int32 attributeIdCount, SAFEARRAY** attributeValues) mut => VT.[Friend]GetAttributeValues(&this, attributeIds, attributeIdCount, attributeValues);
}

[CRepr]struct IUIAutomationTextRangeArray : IUnknown
{
	public new const Guid IID = .(0xce4ae76a, 0xe717, 0x4c98, 0x81, 0xea, 0x47, 0x37, 0x1d, 0x02, 0x8e, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* length) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, IUIAutomationTextRange** element) GetElement;
	}


	public HRESULT get_Length(int32* length) mut => VT.[Friend]get_Length(&this, length);

	public HRESULT GetElement(int32 index, IUIAutomationTextRange** element) mut => VT.[Friend]GetElement(&this, index, element);
}

[CRepr]struct IUIAutomationTextPattern : IUnknown
{
	public new const Guid IID = .(0x32eba289, 0x3583, 0x42c9, 0x9c, 0x59, 0x3b, 0x6d, 0x9a, 0x1e, 0x9b, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT pt, IUIAutomationTextRange** range) RangeFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* child, IUIAutomationTextRange** range) RangeFromChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRangeArray** ranges) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRangeArray** ranges) GetVisibleRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRange** range) get_DocumentRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SupportedTextSelection* supportedTextSelection) get_SupportedTextSelection;
	}


	public HRESULT RangeFromPoint(POINT pt, IUIAutomationTextRange** range) mut => VT.[Friend]RangeFromPoint(&this, pt, range);

	public HRESULT RangeFromChild(IUIAutomationElement* child, IUIAutomationTextRange** range) mut => VT.[Friend]RangeFromChild(&this, child, range);

	public HRESULT GetSelection(IUIAutomationTextRangeArray** ranges) mut => VT.[Friend]GetSelection(&this, ranges);

	public HRESULT GetVisibleRanges(IUIAutomationTextRangeArray** ranges) mut => VT.[Friend]GetVisibleRanges(&this, ranges);

	public HRESULT get_DocumentRange(IUIAutomationTextRange** range) mut => VT.[Friend]get_DocumentRange(&this, range);

	public HRESULT get_SupportedTextSelection(SupportedTextSelection* supportedTextSelection) mut => VT.[Friend]get_SupportedTextSelection(&this, supportedTextSelection);
}

[CRepr]struct IUIAutomationTextPattern2 : IUIAutomationTextPattern
{
	public new const Guid IID = .(0x506a921a, 0xfcc9, 0x409f, 0xb2, 0x3b, 0x37, 0xeb, 0x74, 0x10, 0x68, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationTextPattern.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* annotation, IUIAutomationTextRange** range) RangeFromAnnotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isActive, IUIAutomationTextRange** range) GetCaretRange;
	}


	public HRESULT RangeFromAnnotation(IUIAutomationElement* annotation, IUIAutomationTextRange** range) mut => VT.[Friend]RangeFromAnnotation(&this, annotation, range);

	public HRESULT GetCaretRange(BOOL* isActive, IUIAutomationTextRange** range) mut => VT.[Friend]GetCaretRange(&this, isActive, range);
}

[CRepr]struct IUIAutomationTextEditPattern : IUIAutomationTextPattern
{
	public new const Guid IID = .(0x17e21576, 0x996c, 0x4870, 0x99, 0xd9, 0xbf, 0xf3, 0x23, 0x38, 0x0c, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationTextPattern.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRange** range) GetActiveComposition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRange** range) GetConversionTarget;
	}


	public HRESULT GetActiveComposition(IUIAutomationTextRange** range) mut => VT.[Friend]GetActiveComposition(&this, range);

	public HRESULT GetConversionTarget(IUIAutomationTextRange** range) mut => VT.[Friend]GetConversionTarget(&this, range);
}

[CRepr]struct IUIAutomationCustomNavigationPattern : IUnknown
{
	public new const Guid IID = .(0x01ea217a, 0x1766, 0x47ed, 0xa6, 0xcc, 0xac, 0xf4, 0x92, 0x85, 0x4b, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NavigateDirection direction, IUIAutomationElement** pRetVal) Navigate;
	}


	public HRESULT Navigate(NavigateDirection direction, IUIAutomationElement** pRetVal) mut => VT.[Friend]Navigate(&this, direction, pRetVal);
}

[CRepr]struct IUIAutomationActiveTextPositionChangedEventHandler : IUnknown
{
	public new const Guid IID = .(0xf97933b0, 0x8dae, 0x4496, 0x89, 0x97, 0x5b, 0xa0, 0x15, 0xfe, 0x0d, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* sender, IUIAutomationTextRange* range) HandleActiveTextPositionChangedEvent;
	}


	public HRESULT HandleActiveTextPositionChangedEvent(IUIAutomationElement* sender, IUIAutomationTextRange* range) mut => VT.[Friend]HandleActiveTextPositionChangedEvent(&this, sender, range);
}

[CRepr]struct IUIAutomationLegacyIAccessiblePattern : IUnknown
{
	public new const Guid IID = .(0x828055ad, 0x355b, 0x4435, 0x86, 0xd5, 0x3b, 0x51, 0xc1, 0x4a, 0x9b, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flagsSelect) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DoDefaultAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szValue) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_CurrentChildId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszName) get_CurrentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszValue) get_CurrentValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDescription) get_CurrentDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRole) get_CurrentRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwState) get_CurrentState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszHelp) get_CurrentHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszKeyboardShortcut) get_CurrentKeyboardShortcut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** pvarSelectedChildren) GetCurrentSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDefaultAction) get_CurrentDefaultAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_CachedChildId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszName) get_CachedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszValue) get_CachedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDescription) get_CachedDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRole) get_CachedRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwState) get_CachedState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszHelp) get_CachedHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszKeyboardShortcut) get_CachedKeyboardShortcut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** pvarSelectedChildren) GetCachedSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDefaultAction) get_CachedDefaultAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessible** ppAccessible) GetIAccessible;
	}


	public HRESULT Select(int32 flagsSelect) mut => VT.[Friend]Select(&this, flagsSelect);

	public HRESULT DoDefaultAction() mut => VT.[Friend]DoDefaultAction(&this);

	public HRESULT SetValue(PWSTR szValue) mut => VT.[Friend]SetValue(&this, szValue);

	public HRESULT get_CurrentChildId(int32* pRetVal) mut => VT.[Friend]get_CurrentChildId(&this, pRetVal);

	public HRESULT get_CurrentName(BSTR* pszName) mut => VT.[Friend]get_CurrentName(&this, pszName);

	public HRESULT get_CurrentValue(BSTR* pszValue) mut => VT.[Friend]get_CurrentValue(&this, pszValue);

	public HRESULT get_CurrentDescription(BSTR* pszDescription) mut => VT.[Friend]get_CurrentDescription(&this, pszDescription);

	public HRESULT get_CurrentRole(uint32* pdwRole) mut => VT.[Friend]get_CurrentRole(&this, pdwRole);

	public HRESULT get_CurrentState(uint32* pdwState) mut => VT.[Friend]get_CurrentState(&this, pdwState);

	public HRESULT get_CurrentHelp(BSTR* pszHelp) mut => VT.[Friend]get_CurrentHelp(&this, pszHelp);

	public HRESULT get_CurrentKeyboardShortcut(BSTR* pszKeyboardShortcut) mut => VT.[Friend]get_CurrentKeyboardShortcut(&this, pszKeyboardShortcut);

	public HRESULT GetCurrentSelection(IUIAutomationElementArray** pvarSelectedChildren) mut => VT.[Friend]GetCurrentSelection(&this, pvarSelectedChildren);

	public HRESULT get_CurrentDefaultAction(BSTR* pszDefaultAction) mut => VT.[Friend]get_CurrentDefaultAction(&this, pszDefaultAction);

	public HRESULT get_CachedChildId(int32* pRetVal) mut => VT.[Friend]get_CachedChildId(&this, pRetVal);

	public HRESULT get_CachedName(BSTR* pszName) mut => VT.[Friend]get_CachedName(&this, pszName);

	public HRESULT get_CachedValue(BSTR* pszValue) mut => VT.[Friend]get_CachedValue(&this, pszValue);

	public HRESULT get_CachedDescription(BSTR* pszDescription) mut => VT.[Friend]get_CachedDescription(&this, pszDescription);

	public HRESULT get_CachedRole(uint32* pdwRole) mut => VT.[Friend]get_CachedRole(&this, pdwRole);

	public HRESULT get_CachedState(uint32* pdwState) mut => VT.[Friend]get_CachedState(&this, pdwState);

	public HRESULT get_CachedHelp(BSTR* pszHelp) mut => VT.[Friend]get_CachedHelp(&this, pszHelp);

	public HRESULT get_CachedKeyboardShortcut(BSTR* pszKeyboardShortcut) mut => VT.[Friend]get_CachedKeyboardShortcut(&this, pszKeyboardShortcut);

	public HRESULT GetCachedSelection(IUIAutomationElementArray** pvarSelectedChildren) mut => VT.[Friend]GetCachedSelection(&this, pvarSelectedChildren);

	public HRESULT get_CachedDefaultAction(BSTR* pszDefaultAction) mut => VT.[Friend]get_CachedDefaultAction(&this, pszDefaultAction);

	public HRESULT GetIAccessible(IAccessible** ppAccessible) mut => VT.[Friend]GetIAccessible(&this, ppAccessible);
}

[CRepr]struct IUIAutomationItemContainerPattern : IUnknown
{
	public new const Guid IID = .(0xc690fdb2, 0x27a8, 0x423c, 0x81, 0x2d, 0x42, 0x97, 0x73, 0xc9, 0x08, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* pStartAfter, int32 propertyId, VARIANT value, IUIAutomationElement** pFound) FindItemByProperty;
	}


	public HRESULT FindItemByProperty(IUIAutomationElement* pStartAfter, int32 propertyId, VARIANT value, IUIAutomationElement** pFound) mut => VT.[Friend]FindItemByProperty(&this, pStartAfter, propertyId, value, pFound);
}

[CRepr]struct IUIAutomationVirtualizedItemPattern : IUnknown
{
	public new const Guid IID = .(0x6ba3d7a6, 0x04cf, 0x4f11, 0x87, 0x93, 0xa8, 0xd1, 0xcd, 0xe9, 0x96, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Realize;
	}


	public HRESULT Realize() mut => VT.[Friend]Realize(&this);
}

[CRepr]struct IUIAutomationAnnotationPattern : IUnknown
{
	public new const Guid IID = .(0x9a175b21, 0x339e, 0x41b1, 0x8e, 0x8b, 0x62, 0x3f, 0x6b, 0x68, 0x10, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentAnnotationTypeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAnnotationTypeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentAuthor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentDateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CurrentTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedAnnotationTypeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAnnotationTypeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedAuthor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedDateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** retVal) get_CachedTarget;
	}


	public HRESULT get_CurrentAnnotationTypeId(int32* retVal) mut => VT.[Friend]get_CurrentAnnotationTypeId(&this, retVal);

	public HRESULT get_CurrentAnnotationTypeName(BSTR* retVal) mut => VT.[Friend]get_CurrentAnnotationTypeName(&this, retVal);

	public HRESULT get_CurrentAuthor(BSTR* retVal) mut => VT.[Friend]get_CurrentAuthor(&this, retVal);

	public HRESULT get_CurrentDateTime(BSTR* retVal) mut => VT.[Friend]get_CurrentDateTime(&this, retVal);

	public HRESULT get_CurrentTarget(IUIAutomationElement** retVal) mut => VT.[Friend]get_CurrentTarget(&this, retVal);

	public HRESULT get_CachedAnnotationTypeId(int32* retVal) mut => VT.[Friend]get_CachedAnnotationTypeId(&this, retVal);

	public HRESULT get_CachedAnnotationTypeName(BSTR* retVal) mut => VT.[Friend]get_CachedAnnotationTypeName(&this, retVal);

	public HRESULT get_CachedAuthor(BSTR* retVal) mut => VT.[Friend]get_CachedAuthor(&this, retVal);

	public HRESULT get_CachedDateTime(BSTR* retVal) mut => VT.[Friend]get_CachedDateTime(&this, retVal);

	public HRESULT get_CachedTarget(IUIAutomationElement** retVal) mut => VT.[Friend]get_CachedTarget(&this, retVal);
}

[CRepr]struct IUIAutomationStylesPattern : IUnknown
{
	public new const Guid IID = .(0x85b5f0a2, 0xbd79, 0x484a, 0xad, 0x2b, 0x38, 0x8c, 0x98, 0x38, 0xd5, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentStyleId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentStyleName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentFillColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentFillPatternStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentShape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentFillPatternColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentExtendedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ExtendedProperty** propertyArray, int32* propertyCount) GetCurrentExtendedPropertiesAsArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedStyleId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedStyleName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedFillColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedFillPatternStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedShape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedFillPatternColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedExtendedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ExtendedProperty** propertyArray, int32* propertyCount) GetCachedExtendedPropertiesAsArray;
	}


	public HRESULT get_CurrentStyleId(int32* retVal) mut => VT.[Friend]get_CurrentStyleId(&this, retVal);

	public HRESULT get_CurrentStyleName(BSTR* retVal) mut => VT.[Friend]get_CurrentStyleName(&this, retVal);

	public HRESULT get_CurrentFillColor(int32* retVal) mut => VT.[Friend]get_CurrentFillColor(&this, retVal);

	public HRESULT get_CurrentFillPatternStyle(BSTR* retVal) mut => VT.[Friend]get_CurrentFillPatternStyle(&this, retVal);

	public HRESULT get_CurrentShape(BSTR* retVal) mut => VT.[Friend]get_CurrentShape(&this, retVal);

	public HRESULT get_CurrentFillPatternColor(int32* retVal) mut => VT.[Friend]get_CurrentFillPatternColor(&this, retVal);

	public HRESULT get_CurrentExtendedProperties(BSTR* retVal) mut => VT.[Friend]get_CurrentExtendedProperties(&this, retVal);

	public HRESULT GetCurrentExtendedPropertiesAsArray(ExtendedProperty** propertyArray, int32* propertyCount) mut => VT.[Friend]GetCurrentExtendedPropertiesAsArray(&this, propertyArray, propertyCount);

	public HRESULT get_CachedStyleId(int32* retVal) mut => VT.[Friend]get_CachedStyleId(&this, retVal);

	public HRESULT get_CachedStyleName(BSTR* retVal) mut => VT.[Friend]get_CachedStyleName(&this, retVal);

	public HRESULT get_CachedFillColor(int32* retVal) mut => VT.[Friend]get_CachedFillColor(&this, retVal);

	public HRESULT get_CachedFillPatternStyle(BSTR* retVal) mut => VT.[Friend]get_CachedFillPatternStyle(&this, retVal);

	public HRESULT get_CachedShape(BSTR* retVal) mut => VT.[Friend]get_CachedShape(&this, retVal);

	public HRESULT get_CachedFillPatternColor(int32* retVal) mut => VT.[Friend]get_CachedFillPatternColor(&this, retVal);

	public HRESULT get_CachedExtendedProperties(BSTR* retVal) mut => VT.[Friend]get_CachedExtendedProperties(&this, retVal);

	public HRESULT GetCachedExtendedPropertiesAsArray(ExtendedProperty** propertyArray, int32* propertyCount) mut => VT.[Friend]GetCachedExtendedPropertiesAsArray(&this, propertyArray, propertyCount);
}

[CRepr]struct IUIAutomationSpreadsheetPattern : IUnknown
{
	public new const Guid IID = .(0x7517a7c8, 0xfaae, 0x4de9, 0x9f, 0x08, 0x29, 0xb9, 0x1e, 0x85, 0x95, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IUIAutomationElement** element) GetItemByName;
	}


	public HRESULT GetItemByName(BSTR name, IUIAutomationElement** element) mut => VT.[Friend]GetItemByName(&this, name, element);
}

[CRepr]struct IUIAutomationSpreadsheetItemPattern : IUnknown
{
	public new const Guid IID = .(0x7d4fb86c, 0x8d34, 0x40e1, 0x8e, 0x83, 0x62, 0xc1, 0x52, 0x04, 0xe3, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentFormula;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentAnnotationObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) GetCurrentAnnotationTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedFormula;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedAnnotationObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) GetCachedAnnotationTypes;
	}


	public HRESULT get_CurrentFormula(BSTR* retVal) mut => VT.[Friend]get_CurrentFormula(&this, retVal);

	public HRESULT GetCurrentAnnotationObjects(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentAnnotationObjects(&this, retVal);

	public HRESULT GetCurrentAnnotationTypes(SAFEARRAY** retVal) mut => VT.[Friend]GetCurrentAnnotationTypes(&this, retVal);

	public HRESULT get_CachedFormula(BSTR* retVal) mut => VT.[Friend]get_CachedFormula(&this, retVal);

	public HRESULT GetCachedAnnotationObjects(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedAnnotationObjects(&this, retVal);

	public HRESULT GetCachedAnnotationTypes(SAFEARRAY** retVal) mut => VT.[Friend]GetCachedAnnotationTypes(&this, retVal);
}

[CRepr]struct IUIAutomationTransformPattern2 : IUIAutomationTransformPattern
{
	public new const Guid IID = .(0x6d74d017, 0x6ecb, 0x4381, 0xb3, 0x8b, 0x3c, 0x17, 0xa4, 0x8f, 0xf1, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationTransformPattern.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double zoomValue) Zoom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ZoomUnit zoomUnit) ZoomByUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentCanZoom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedCanZoom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentZoomLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedZoomLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentZoomMinimum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedZoomMinimum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CurrentZoomMaximum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retVal) get_CachedZoomMaximum;
	}


	public HRESULT Zoom(double zoomValue) mut => VT.[Friend]Zoom(&this, zoomValue);

	public HRESULT ZoomByUnit(ZoomUnit zoomUnit) mut => VT.[Friend]ZoomByUnit(&this, zoomUnit);

	public HRESULT get_CurrentCanZoom(BOOL* retVal) mut => VT.[Friend]get_CurrentCanZoom(&this, retVal);

	public HRESULT get_CachedCanZoom(BOOL* retVal) mut => VT.[Friend]get_CachedCanZoom(&this, retVal);

	public HRESULT get_CurrentZoomLevel(double* retVal) mut => VT.[Friend]get_CurrentZoomLevel(&this, retVal);

	public HRESULT get_CachedZoomLevel(double* retVal) mut => VT.[Friend]get_CachedZoomLevel(&this, retVal);

	public HRESULT get_CurrentZoomMinimum(double* retVal) mut => VT.[Friend]get_CurrentZoomMinimum(&this, retVal);

	public HRESULT get_CachedZoomMinimum(double* retVal) mut => VT.[Friend]get_CachedZoomMinimum(&this, retVal);

	public HRESULT get_CurrentZoomMaximum(double* retVal) mut => VT.[Friend]get_CurrentZoomMaximum(&this, retVal);

	public HRESULT get_CachedZoomMaximum(double* retVal) mut => VT.[Friend]get_CachedZoomMaximum(&this, retVal);
}

[CRepr]struct IUIAutomationTextChildPattern : IUnknown
{
	public new const Guid IID = .(0x6552b038, 0xae05, 0x40c8, 0xab, 0xfd, 0xaa, 0x08, 0x35, 0x2a, 0xab, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** container) get_TextContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTextRange** range) get_TextRange;
	}


	public HRESULT get_TextContainer(IUIAutomationElement** container) mut => VT.[Friend]get_TextContainer(&this, container);

	public HRESULT get_TextRange(IUIAutomationTextRange** range) mut => VT.[Friend]get_TextRange(&this, range);
}

[CRepr]struct IUIAutomationDragPattern : IUnknown
{
	public new const Guid IID = .(0x1dc7b570, 0x1f54, 0x4bad, 0xbc, 0xda, 0xd3, 0x6a, 0x72, 0x2f, 0xb7, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsGrabbed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsGrabbed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentDropEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedDropEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) get_CurrentDropEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) get_CachedDropEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCurrentGrabbedItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) GetCachedGrabbedItems;
	}


	public HRESULT get_CurrentIsGrabbed(BOOL* retVal) mut => VT.[Friend]get_CurrentIsGrabbed(&this, retVal);

	public HRESULT get_CachedIsGrabbed(BOOL* retVal) mut => VT.[Friend]get_CachedIsGrabbed(&this, retVal);

	public HRESULT get_CurrentDropEffect(BSTR* retVal) mut => VT.[Friend]get_CurrentDropEffect(&this, retVal);

	public HRESULT get_CachedDropEffect(BSTR* retVal) mut => VT.[Friend]get_CachedDropEffect(&this, retVal);

	public HRESULT get_CurrentDropEffects(SAFEARRAY** retVal) mut => VT.[Friend]get_CurrentDropEffects(&this, retVal);

	public HRESULT get_CachedDropEffects(SAFEARRAY** retVal) mut => VT.[Friend]get_CachedDropEffects(&this, retVal);

	public HRESULT GetCurrentGrabbedItems(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCurrentGrabbedItems(&this, retVal);

	public HRESULT GetCachedGrabbedItems(IUIAutomationElementArray** retVal) mut => VT.[Friend]GetCachedGrabbedItems(&this, retVal);
}

[CRepr]struct IUIAutomationDropTargetPattern : IUnknown
{
	public new const Guid IID = .(0x69a095f7, 0xeee4, 0x430e, 0xa4, 0x6b, 0xfb, 0x73, 0xb1, 0xae, 0x39, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentDropTargetEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedDropTargetEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) get_CurrentDropTargetEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) get_CachedDropTargetEffects;
	}


	public HRESULT get_CurrentDropTargetEffect(BSTR* retVal) mut => VT.[Friend]get_CurrentDropTargetEffect(&this, retVal);

	public HRESULT get_CachedDropTargetEffect(BSTR* retVal) mut => VT.[Friend]get_CachedDropTargetEffect(&this, retVal);

	public HRESULT get_CurrentDropTargetEffects(SAFEARRAY** retVal) mut => VT.[Friend]get_CurrentDropTargetEffects(&this, retVal);

	public HRESULT get_CachedDropTargetEffects(SAFEARRAY** retVal) mut => VT.[Friend]get_CachedDropTargetEffects(&this, retVal);
}

[CRepr]struct IUIAutomationElement2 : IUIAutomationElement
{
	public new const Guid IID = .(0x6749c683, 0xf70d, 0x4487, 0xa6, 0x98, 0x5f, 0x79, 0xd5, 0x52, 0x90, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentOptimizeForVisualContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedOptimizeForVisualContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LiveSetting* retVal) get_CurrentLiveSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LiveSetting* retVal) get_CachedLiveSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CurrentFlowsFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CachedFlowsFrom;
	}


	public HRESULT get_CurrentOptimizeForVisualContent(BOOL* retVal) mut => VT.[Friend]get_CurrentOptimizeForVisualContent(&this, retVal);

	public HRESULT get_CachedOptimizeForVisualContent(BOOL* retVal) mut => VT.[Friend]get_CachedOptimizeForVisualContent(&this, retVal);

	public HRESULT get_CurrentLiveSetting(LiveSetting* retVal) mut => VT.[Friend]get_CurrentLiveSetting(&this, retVal);

	public HRESULT get_CachedLiveSetting(LiveSetting* retVal) mut => VT.[Friend]get_CachedLiveSetting(&this, retVal);

	public HRESULT get_CurrentFlowsFrom(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CurrentFlowsFrom(&this, retVal);

	public HRESULT get_CachedFlowsFrom(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CachedFlowsFrom(&this, retVal);
}

[CRepr]struct IUIAutomationElement3 : IUIAutomationElement2
{
	public new const Guid IID = .(0x8471df34, 0xaee0, 0x4a01, 0xa7, 0xde, 0x7d, 0xb9, 0xaf, 0x12, 0xc2, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsPeripheral;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsPeripheral;
	}


	public HRESULT ShowContextMenu() mut => VT.[Friend]ShowContextMenu(&this);

	public HRESULT get_CurrentIsPeripheral(BOOL* retVal) mut => VT.[Friend]get_CurrentIsPeripheral(&this, retVal);

	public HRESULT get_CachedIsPeripheral(BOOL* retVal) mut => VT.[Friend]get_CachedIsPeripheral(&this, retVal);
}

[CRepr]struct IUIAutomationElement4 : IUIAutomationElement3
{
	public new const Guid IID = .(0x3b6e233c, 0x52fb, 0x4063, 0xa4, 0xc9, 0x77, 0xc0, 0x75, 0xc2, 0xa0, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentPositionInSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentSizeOfSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) get_CurrentAnnotationTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CurrentAnnotationObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedPositionInSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedSizeOfSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** retVal) get_CachedAnnotationTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElementArray** retVal) get_CachedAnnotationObjects;
	}


	public HRESULT get_CurrentPositionInSet(int32* retVal) mut => VT.[Friend]get_CurrentPositionInSet(&this, retVal);

	public HRESULT get_CurrentSizeOfSet(int32* retVal) mut => VT.[Friend]get_CurrentSizeOfSet(&this, retVal);

	public HRESULT get_CurrentLevel(int32* retVal) mut => VT.[Friend]get_CurrentLevel(&this, retVal);

	public HRESULT get_CurrentAnnotationTypes(SAFEARRAY** retVal) mut => VT.[Friend]get_CurrentAnnotationTypes(&this, retVal);

	public HRESULT get_CurrentAnnotationObjects(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CurrentAnnotationObjects(&this, retVal);

	public HRESULT get_CachedPositionInSet(int32* retVal) mut => VT.[Friend]get_CachedPositionInSet(&this, retVal);

	public HRESULT get_CachedSizeOfSet(int32* retVal) mut => VT.[Friend]get_CachedSizeOfSet(&this, retVal);

	public HRESULT get_CachedLevel(int32* retVal) mut => VT.[Friend]get_CachedLevel(&this, retVal);

	public HRESULT get_CachedAnnotationTypes(SAFEARRAY** retVal) mut => VT.[Friend]get_CachedAnnotationTypes(&this, retVal);

	public HRESULT get_CachedAnnotationObjects(IUIAutomationElementArray** retVal) mut => VT.[Friend]get_CachedAnnotationObjects(&this, retVal);
}

[CRepr]struct IUIAutomationElement5 : IUIAutomationElement4
{
	public new const Guid IID = .(0x98141c1d, 0x0d0e, 0x4175, 0xbb, 0xe2, 0x6b, 0xff, 0x45, 0x58, 0x42, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentLandmarkType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentLocalizedLandmarkType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedLandmarkType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedLocalizedLandmarkType;
	}


	public HRESULT get_CurrentLandmarkType(int32* retVal) mut => VT.[Friend]get_CurrentLandmarkType(&this, retVal);

	public HRESULT get_CurrentLocalizedLandmarkType(BSTR* retVal) mut => VT.[Friend]get_CurrentLocalizedLandmarkType(&this, retVal);

	public HRESULT get_CachedLandmarkType(int32* retVal) mut => VT.[Friend]get_CachedLandmarkType(&this, retVal);

	public HRESULT get_CachedLocalizedLandmarkType(BSTR* retVal) mut => VT.[Friend]get_CachedLocalizedLandmarkType(&this, retVal);
}

[CRepr]struct IUIAutomationElement6 : IUIAutomationElement5
{
	public new const Guid IID = .(0x4780d450, 0x8bca, 0x4977, 0xaf, 0xa5, 0xa4, 0xa5, 0x17, 0xf5, 0x55, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CurrentFullDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retVal) get_CachedFullDescription;
	}


	public HRESULT get_CurrentFullDescription(BSTR* retVal) mut => VT.[Friend]get_CurrentFullDescription(&this, retVal);

	public HRESULT get_CachedFullDescription(BSTR* retVal) mut => VT.[Friend]get_CachedFullDescription(&this, retVal);
}

[CRepr]struct IUIAutomationElement7 : IUIAutomationElement6
{
	public new const Guid IID = .(0x204e8572, 0xcfc3, 0x4c11, 0xb0, 0xc8, 0x7d, 0xa7, 0x42, 0x07, 0x50, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement6.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElement** found) FindFirstWithOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElementArray** found) FindAllWithOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElement** found) FindFirstWithOptionsBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElementArray** found) FindAllWithOptionsBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 targetId, int32 metadataId, VARIANT* returnVal) GetCurrentMetadataValue;
	}


	public HRESULT FindFirstWithOptions(TreeScope @scope, IUIAutomationCondition* condition, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElement** found) mut => VT.[Friend]FindFirstWithOptions(&this, @scope, condition, traversalOptions, root, found);

	public HRESULT FindAllWithOptions(TreeScope @scope, IUIAutomationCondition* condition, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElementArray** found) mut => VT.[Friend]FindAllWithOptions(&this, @scope, condition, traversalOptions, root, found);

	public HRESULT FindFirstWithOptionsBuildCache(TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElement** found) mut => VT.[Friend]FindFirstWithOptionsBuildCache(&this, @scope, condition, cacheRequest, traversalOptions, root, found);

	public HRESULT FindAllWithOptionsBuildCache(TreeScope @scope, IUIAutomationCondition* condition, IUIAutomationCacheRequest* cacheRequest, TreeTraversalOptions traversalOptions, IUIAutomationElement* root, IUIAutomationElementArray** found) mut => VT.[Friend]FindAllWithOptionsBuildCache(&this, @scope, condition, cacheRequest, traversalOptions, root, found);

	public HRESULT GetCurrentMetadataValue(int32 targetId, int32 metadataId, VARIANT* returnVal) mut => VT.[Friend]GetCurrentMetadataValue(&this, targetId, metadataId, returnVal);
}

[CRepr]struct IUIAutomationElement8 : IUIAutomationElement7
{
	public new const Guid IID = .(0x8c60217d, 0x5411, 0x4cde, 0xbc, 0xc0, 0x1c, 0xed, 0xa2, 0x23, 0x83, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement7.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CurrentHeadingLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retVal) get_CachedHeadingLevel;
	}


	public HRESULT get_CurrentHeadingLevel(int32* retVal) mut => VT.[Friend]get_CurrentHeadingLevel(&this, retVal);

	public HRESULT get_CachedHeadingLevel(int32* retVal) mut => VT.[Friend]get_CachedHeadingLevel(&this, retVal);
}

[CRepr]struct IUIAutomationElement9 : IUIAutomationElement8
{
	public new const Guid IID = .(0x39325fac, 0x039d, 0x440e, 0xa3, 0xa3, 0x5e, 0xb8, 0x1a, 0x5c, 0xec, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomationElement8.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CurrentIsDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* retVal) get_CachedIsDialog;
	}


	public HRESULT get_CurrentIsDialog(BOOL* retVal) mut => VT.[Friend]get_CurrentIsDialog(&this, retVal);

	public HRESULT get_CachedIsDialog(BOOL* retVal) mut => VT.[Friend]get_CachedIsDialog(&this, retVal);
}

[CRepr]struct IUIAutomationProxyFactory : IUnknown
{
	public new const Guid IID = .(0x85b94ecd, 0x849d, 0x42b6, 0xb9, 0x4d, 0xd6, 0xdb, 0x23, 0xfd, 0xf5, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, int32 idObject, int32 idChild, IRawElementProviderSimple** provider) CreateProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* factoryId) get_ProxyFactoryId;
	}


	public HRESULT CreateProvider(HWND hwnd, int32 idObject, int32 idChild, IRawElementProviderSimple** provider) mut => VT.[Friend]CreateProvider(&this, hwnd, idObject, idChild, provider);

	public HRESULT get_ProxyFactoryId(BSTR* factoryId) mut => VT.[Friend]get_ProxyFactoryId(&this, factoryId);
}

[CRepr]struct IUIAutomationProxyFactoryEntry : IUnknown
{
	public new const Guid IID = .(0xd50e472e, 0xb64b, 0x490c, 0xbc, 0xa1, 0xd3, 0x06, 0x96, 0xf9, 0xf2, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationProxyFactory** factory) get_ProxyFactory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* className) get_ClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* imageName) get_ImageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* allowSubstringMatch) get_AllowSubstringMatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* canCheckBaseClass) get_CanCheckBaseClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* adviseEvents) get_NeedsAdviseEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR className) put_ClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR imageName) put_ImageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL allowSubstringMatch) put_AllowSubstringMatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL canCheckBaseClass) put_CanCheckBaseClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL adviseEvents) put_NeedsAdviseEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, int32 propertyId, SAFEARRAY* winEvents) SetWinEventsForAutomationEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, int32 propertyId, SAFEARRAY** winEvents) GetWinEventsForAutomationEvent;
	}


	public HRESULT get_ProxyFactory(IUIAutomationProxyFactory** factory) mut => VT.[Friend]get_ProxyFactory(&this, factory);

	public HRESULT get_ClassName(BSTR* className) mut => VT.[Friend]get_ClassName(&this, className);

	public HRESULT get_ImageName(BSTR* imageName) mut => VT.[Friend]get_ImageName(&this, imageName);

	public HRESULT get_AllowSubstringMatch(BOOL* allowSubstringMatch) mut => VT.[Friend]get_AllowSubstringMatch(&this, allowSubstringMatch);

	public HRESULT get_CanCheckBaseClass(BOOL* canCheckBaseClass) mut => VT.[Friend]get_CanCheckBaseClass(&this, canCheckBaseClass);

	public HRESULT get_NeedsAdviseEvents(BOOL* adviseEvents) mut => VT.[Friend]get_NeedsAdviseEvents(&this, adviseEvents);

	public HRESULT put_ClassName(PWSTR className) mut => VT.[Friend]put_ClassName(&this, className);

	public HRESULT put_ImageName(PWSTR imageName) mut => VT.[Friend]put_ImageName(&this, imageName);

	public HRESULT put_AllowSubstringMatch(BOOL allowSubstringMatch) mut => VT.[Friend]put_AllowSubstringMatch(&this, allowSubstringMatch);

	public HRESULT put_CanCheckBaseClass(BOOL canCheckBaseClass) mut => VT.[Friend]put_CanCheckBaseClass(&this, canCheckBaseClass);

	public HRESULT put_NeedsAdviseEvents(BOOL adviseEvents) mut => VT.[Friend]put_NeedsAdviseEvents(&this, adviseEvents);

	public HRESULT SetWinEventsForAutomationEvent(int32 eventId, int32 propertyId, SAFEARRAY* winEvents) mut => VT.[Friend]SetWinEventsForAutomationEvent(&this, eventId, propertyId, winEvents);

	public HRESULT GetWinEventsForAutomationEvent(int32 eventId, int32 propertyId, SAFEARRAY** winEvents) mut => VT.[Friend]GetWinEventsForAutomationEvent(&this, eventId, propertyId, winEvents);
}

[CRepr]struct IUIAutomationProxyFactoryMapping : IUnknown
{
	public new const Guid IID = .(0x09e31e18, 0x872d, 0x4873, 0x93, 0xd1, 0x1e, 0x54, 0x1e, 0xc1, 0x33, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** table) GetTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IUIAutomationProxyFactoryEntry** entry) GetEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* factoryList) SetTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 before, SAFEARRAY* factoryList) InsertEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 before, IUIAutomationProxyFactoryEntry* factory) InsertEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreDefaultTable;
	}


	public HRESULT get_Count(uint32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT GetTable(SAFEARRAY** table) mut => VT.[Friend]GetTable(&this, table);

	public HRESULT GetEntry(uint32 index, IUIAutomationProxyFactoryEntry** entry) mut => VT.[Friend]GetEntry(&this, index, entry);

	public HRESULT SetTable(SAFEARRAY* factoryList) mut => VT.[Friend]SetTable(&this, factoryList);

	public HRESULT InsertEntries(uint32 before, SAFEARRAY* factoryList) mut => VT.[Friend]InsertEntries(&this, before, factoryList);

	public HRESULT InsertEntry(uint32 before, IUIAutomationProxyFactoryEntry* factory) mut => VT.[Friend]InsertEntry(&this, before, factory);

	public HRESULT RemoveEntry(uint32 index) mut => VT.[Friend]RemoveEntry(&this, index);

	public HRESULT ClearTable() mut => VT.[Friend]ClearTable(&this);

	public HRESULT RestoreDefaultTable() mut => VT.[Friend]RestoreDefaultTable(&this);
}

[CRepr]struct IUIAutomationEventHandlerGroup : IUnknown
{
	public new const Guid IID = .(0xc9ee12f2, 0xc13b, 0x4408, 0x99, 0x7c, 0x63, 0x99, 0x14, 0x37, 0x7f, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationActiveTextPositionChangedEventHandler* handler) AddActiveTextPositionChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationEventHandler* handler) AddAutomationEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, int32* changeTypes, int32 changesCount, IUIAutomationCacheRequest* cacheRequest, IUIAutomationChangesEventHandler* handler) AddChangesEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationNotificationEventHandler* handler) AddNotificationEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationPropertyChangedEventHandler* handler, int32* propertyArray, int32 propertyCount) AddPropertyChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationStructureChangedEventHandler* handler) AddStructureChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TreeScope @scope, TextEditChangeType textEditChangeType, IUIAutomationCacheRequest* cacheRequest, IUIAutomationTextEditTextChangedEventHandler* handler) AddTextEditTextChangedEventHandler;
	}


	public HRESULT AddActiveTextPositionChangedEventHandler(TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationActiveTextPositionChangedEventHandler* handler) mut => VT.[Friend]AddActiveTextPositionChangedEventHandler(&this, @scope, cacheRequest, handler);

	public HRESULT AddAutomationEventHandler(int32 eventId, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationEventHandler* handler) mut => VT.[Friend]AddAutomationEventHandler(&this, eventId, @scope, cacheRequest, handler);

	public HRESULT AddChangesEventHandler(TreeScope @scope, int32* changeTypes, int32 changesCount, IUIAutomationCacheRequest* cacheRequest, IUIAutomationChangesEventHandler* handler) mut => VT.[Friend]AddChangesEventHandler(&this, @scope, changeTypes, changesCount, cacheRequest, handler);

	public HRESULT AddNotificationEventHandler(TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationNotificationEventHandler* handler) mut => VT.[Friend]AddNotificationEventHandler(&this, @scope, cacheRequest, handler);

	public HRESULT AddPropertyChangedEventHandler(TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationPropertyChangedEventHandler* handler, int32* propertyArray, int32 propertyCount) mut => VT.[Friend]AddPropertyChangedEventHandler(&this, @scope, cacheRequest, handler, propertyArray, propertyCount);

	public HRESULT AddStructureChangedEventHandler(TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationStructureChangedEventHandler* handler) mut => VT.[Friend]AddStructureChangedEventHandler(&this, @scope, cacheRequest, handler);

	public HRESULT AddTextEditTextChangedEventHandler(TreeScope @scope, TextEditChangeType textEditChangeType, IUIAutomationCacheRequest* cacheRequest, IUIAutomationTextEditTextChangedEventHandler* handler) mut => VT.[Friend]AddTextEditTextChangedEventHandler(&this, @scope, textEditChangeType, cacheRequest, handler);
}

[CRepr]struct IUIAutomation : IUnknown
{
	public new const Guid IID = .(0x30cbe57d, 0xd9d0, 0x452a, 0xab, 0x13, 0x7a, 0xc5, 0xac, 0x48, 0x25, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* el1, IUIAutomationElement* el2, BOOL* areSame) CompareElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* runtimeId1, SAFEARRAY* runtimeId2, BOOL* areSame) CompareRuntimeIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** root) GetRootElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IUIAutomationElement** element) ElementFromHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT pt, IUIAutomationElement** element) ElementFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement** element) GetFocusedElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** root) GetRootElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) ElementFromHandleBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT pt, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) ElementFromPointBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) GetFocusedElementBuildCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition* pCondition, IUIAutomationTreeWalker** walker) CreateTreeWalker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTreeWalker** walker) get_ControlViewWalker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTreeWalker** walker) get_ContentViewWalker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationTreeWalker** walker) get_RawViewWalker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** condition) get_RawViewCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** condition) get_ControlViewCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** condition) get_ContentViewCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest** cacheRequest) CreateCacheRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** newCondition) CreateTrueCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** newCondition) CreateFalseCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, VARIANT value, IUIAutomationCondition** newCondition) CreatePropertyCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, VARIANT value, PropertyConditionFlags flags, IUIAutomationCondition** newCondition) CreatePropertyConditionEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition* condition1, IUIAutomationCondition* condition2, IUIAutomationCondition** newCondition) CreateAndCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* conditions, IUIAutomationCondition** newCondition) CreateAndConditionFromArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** conditions, int32 conditionCount, IUIAutomationCondition** newCondition) CreateAndConditionFromNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition* condition1, IUIAutomationCondition* condition2, IUIAutomationCondition** newCondition) CreateOrCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* conditions, IUIAutomationCondition** newCondition) CreateOrConditionFromArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition** conditions, int32 conditionCount, IUIAutomationCondition** newCondition) CreateOrConditionFromNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCondition* condition, IUIAutomationCondition** newCondition) CreateNotCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationEventHandler* handler) AddAutomationEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eventId, IUIAutomationElement* element, IUIAutomationEventHandler* handler) RemoveAutomationEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationPropertyChangedEventHandler* handler, int32* propertyArray, int32 propertyCount) AddPropertyChangedEventHandlerNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationPropertyChangedEventHandler* handler, SAFEARRAY* propertyArray) AddPropertyChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationPropertyChangedEventHandler* handler) RemovePropertyChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationStructureChangedEventHandler* handler) AddStructureChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationStructureChangedEventHandler* handler) RemoveStructureChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationCacheRequest* cacheRequest, IUIAutomationFocusChangedEventHandler* handler) AddFocusChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationFocusChangedEventHandler* handler) RemoveFocusChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllEventHandlers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* array, int32 arrayCount, SAFEARRAY** safeArray) IntNativeArrayToSafeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* intArray, int32** array, int32* arrayCount) IntSafeArrayToNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT rc, VARIANT* @var) RectToVariant;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT @var, RECT* rc) VariantToRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* rects, RECT** rectArray, int32* rectArrayCount) SafeArrayToRectNativeArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationProxyFactory* factory, IUIAutomationProxyFactoryEntry** factoryEntry) CreateProxyFactoryEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationProxyFactoryMapping** factoryMapping) get_ProxyFactoryMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 property, BSTR* name) GetPropertyProgrammaticName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 pattern, BSTR* name) GetPatternProgrammaticName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* pElement, SAFEARRAY** patternIds, SAFEARRAY** patternNames) PollForPotentialSupportedPatterns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* pElement, SAFEARRAY** propertyIds, SAFEARRAY** propertyNames) PollForPotentialSupportedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT value, BOOL* isNotSupported) CheckNotSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** notSupportedValue) get_ReservedNotSupportedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** mixedAttributeValue) get_ReservedMixedAttributeValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessible* accessible, int32 childId, IUIAutomationElement** element) ElementFromIAccessible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAccessible* accessible, int32 childId, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) ElementFromIAccessibleBuildCache;
	}


	public HRESULT CompareElements(IUIAutomationElement* el1, IUIAutomationElement* el2, BOOL* areSame) mut => VT.[Friend]CompareElements(&this, el1, el2, areSame);

	public HRESULT CompareRuntimeIds(SAFEARRAY* runtimeId1, SAFEARRAY* runtimeId2, BOOL* areSame) mut => VT.[Friend]CompareRuntimeIds(&this, runtimeId1, runtimeId2, areSame);

	public HRESULT GetRootElement(IUIAutomationElement** root) mut => VT.[Friend]GetRootElement(&this, root);

	public HRESULT ElementFromHandle(HWND hwnd, IUIAutomationElement** element) mut => VT.[Friend]ElementFromHandle(&this, hwnd, element);

	public HRESULT ElementFromPoint(POINT pt, IUIAutomationElement** element) mut => VT.[Friend]ElementFromPoint(&this, pt, element);

	public HRESULT GetFocusedElement(IUIAutomationElement** element) mut => VT.[Friend]GetFocusedElement(&this, element);

	public HRESULT GetRootElementBuildCache(IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** root) mut => VT.[Friend]GetRootElementBuildCache(&this, cacheRequest, root);

	public HRESULT ElementFromHandleBuildCache(HWND hwnd, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) mut => VT.[Friend]ElementFromHandleBuildCache(&this, hwnd, cacheRequest, element);

	public HRESULT ElementFromPointBuildCache(POINT pt, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) mut => VT.[Friend]ElementFromPointBuildCache(&this, pt, cacheRequest, element);

	public HRESULT GetFocusedElementBuildCache(IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) mut => VT.[Friend]GetFocusedElementBuildCache(&this, cacheRequest, element);

	public HRESULT CreateTreeWalker(IUIAutomationCondition* pCondition, IUIAutomationTreeWalker** walker) mut => VT.[Friend]CreateTreeWalker(&this, pCondition, walker);

	public HRESULT get_ControlViewWalker(IUIAutomationTreeWalker** walker) mut => VT.[Friend]get_ControlViewWalker(&this, walker);

	public HRESULT get_ContentViewWalker(IUIAutomationTreeWalker** walker) mut => VT.[Friend]get_ContentViewWalker(&this, walker);

	public HRESULT get_RawViewWalker(IUIAutomationTreeWalker** walker) mut => VT.[Friend]get_RawViewWalker(&this, walker);

	public HRESULT get_RawViewCondition(IUIAutomationCondition** condition) mut => VT.[Friend]get_RawViewCondition(&this, condition);

	public HRESULT get_ControlViewCondition(IUIAutomationCondition** condition) mut => VT.[Friend]get_ControlViewCondition(&this, condition);

	public HRESULT get_ContentViewCondition(IUIAutomationCondition** condition) mut => VT.[Friend]get_ContentViewCondition(&this, condition);

	public HRESULT CreateCacheRequest(IUIAutomationCacheRequest** cacheRequest) mut => VT.[Friend]CreateCacheRequest(&this, cacheRequest);

	public HRESULT CreateTrueCondition(IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateTrueCondition(&this, newCondition);

	public HRESULT CreateFalseCondition(IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateFalseCondition(&this, newCondition);

	public HRESULT CreatePropertyCondition(int32 propertyId, VARIANT value, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreatePropertyCondition(&this, propertyId, value, newCondition);

	public HRESULT CreatePropertyConditionEx(int32 propertyId, VARIANT value, PropertyConditionFlags flags, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreatePropertyConditionEx(&this, propertyId, value, flags, newCondition);

	public HRESULT CreateAndCondition(IUIAutomationCondition* condition1, IUIAutomationCondition* condition2, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateAndCondition(&this, condition1, condition2, newCondition);

	public HRESULT CreateAndConditionFromArray(SAFEARRAY* conditions, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateAndConditionFromArray(&this, conditions, newCondition);

	public HRESULT CreateAndConditionFromNativeArray(IUIAutomationCondition** conditions, int32 conditionCount, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateAndConditionFromNativeArray(&this, conditions, conditionCount, newCondition);

	public HRESULT CreateOrCondition(IUIAutomationCondition* condition1, IUIAutomationCondition* condition2, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateOrCondition(&this, condition1, condition2, newCondition);

	public HRESULT CreateOrConditionFromArray(SAFEARRAY* conditions, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateOrConditionFromArray(&this, conditions, newCondition);

	public HRESULT CreateOrConditionFromNativeArray(IUIAutomationCondition** conditions, int32 conditionCount, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateOrConditionFromNativeArray(&this, conditions, conditionCount, newCondition);

	public HRESULT CreateNotCondition(IUIAutomationCondition* condition, IUIAutomationCondition** newCondition) mut => VT.[Friend]CreateNotCondition(&this, condition, newCondition);

	public HRESULT AddAutomationEventHandler(int32 eventId, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationEventHandler* handler) mut => VT.[Friend]AddAutomationEventHandler(&this, eventId, element, @scope, cacheRequest, handler);

	public HRESULT RemoveAutomationEventHandler(int32 eventId, IUIAutomationElement* element, IUIAutomationEventHandler* handler) mut => VT.[Friend]RemoveAutomationEventHandler(&this, eventId, element, handler);

	public HRESULT AddPropertyChangedEventHandlerNativeArray(IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationPropertyChangedEventHandler* handler, int32* propertyArray, int32 propertyCount) mut => VT.[Friend]AddPropertyChangedEventHandlerNativeArray(&this, element, @scope, cacheRequest, handler, propertyArray, propertyCount);

	public HRESULT AddPropertyChangedEventHandler(IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationPropertyChangedEventHandler* handler, SAFEARRAY* propertyArray) mut => VT.[Friend]AddPropertyChangedEventHandler(&this, element, @scope, cacheRequest, handler, propertyArray);

	public HRESULT RemovePropertyChangedEventHandler(IUIAutomationElement* element, IUIAutomationPropertyChangedEventHandler* handler) mut => VT.[Friend]RemovePropertyChangedEventHandler(&this, element, handler);

	public HRESULT AddStructureChangedEventHandler(IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationStructureChangedEventHandler* handler) mut => VT.[Friend]AddStructureChangedEventHandler(&this, element, @scope, cacheRequest, handler);

	public HRESULT RemoveStructureChangedEventHandler(IUIAutomationElement* element, IUIAutomationStructureChangedEventHandler* handler) mut => VT.[Friend]RemoveStructureChangedEventHandler(&this, element, handler);

	public HRESULT AddFocusChangedEventHandler(IUIAutomationCacheRequest* cacheRequest, IUIAutomationFocusChangedEventHandler* handler) mut => VT.[Friend]AddFocusChangedEventHandler(&this, cacheRequest, handler);

	public HRESULT RemoveFocusChangedEventHandler(IUIAutomationFocusChangedEventHandler* handler) mut => VT.[Friend]RemoveFocusChangedEventHandler(&this, handler);

	public HRESULT RemoveAllEventHandlers() mut => VT.[Friend]RemoveAllEventHandlers(&this);

	public HRESULT IntNativeArrayToSafeArray(int32* array, int32 arrayCount, SAFEARRAY** safeArray) mut => VT.[Friend]IntNativeArrayToSafeArray(&this, array, arrayCount, safeArray);

	public HRESULT IntSafeArrayToNativeArray(SAFEARRAY* intArray, int32** array, int32* arrayCount) mut => VT.[Friend]IntSafeArrayToNativeArray(&this, intArray, array, arrayCount);

	public HRESULT RectToVariant(RECT rc, VARIANT* @var) mut => VT.[Friend]RectToVariant(&this, rc, @var);

	public HRESULT VariantToRect(VARIANT @var, RECT* rc) mut => VT.[Friend]VariantToRect(&this, @var, rc);

	public HRESULT SafeArrayToRectNativeArray(SAFEARRAY* rects, RECT** rectArray, int32* rectArrayCount) mut => VT.[Friend]SafeArrayToRectNativeArray(&this, rects, rectArray, rectArrayCount);

	public HRESULT CreateProxyFactoryEntry(IUIAutomationProxyFactory* factory, IUIAutomationProxyFactoryEntry** factoryEntry) mut => VT.[Friend]CreateProxyFactoryEntry(&this, factory, factoryEntry);

	public HRESULT get_ProxyFactoryMapping(IUIAutomationProxyFactoryMapping** factoryMapping) mut => VT.[Friend]get_ProxyFactoryMapping(&this, factoryMapping);

	public HRESULT GetPropertyProgrammaticName(int32 property, BSTR* name) mut => VT.[Friend]GetPropertyProgrammaticName(&this, property, name);

	public HRESULT GetPatternProgrammaticName(int32 pattern, BSTR* name) mut => VT.[Friend]GetPatternProgrammaticName(&this, pattern, name);

	public HRESULT PollForPotentialSupportedPatterns(IUIAutomationElement* pElement, SAFEARRAY** patternIds, SAFEARRAY** patternNames) mut => VT.[Friend]PollForPotentialSupportedPatterns(&this, pElement, patternIds, patternNames);

	public HRESULT PollForPotentialSupportedProperties(IUIAutomationElement* pElement, SAFEARRAY** propertyIds, SAFEARRAY** propertyNames) mut => VT.[Friend]PollForPotentialSupportedProperties(&this, pElement, propertyIds, propertyNames);

	public HRESULT CheckNotSupported(VARIANT value, BOOL* isNotSupported) mut => VT.[Friend]CheckNotSupported(&this, value, isNotSupported);

	public HRESULT get_ReservedNotSupportedValue(IUnknown** notSupportedValue) mut => VT.[Friend]get_ReservedNotSupportedValue(&this, notSupportedValue);

	public HRESULT get_ReservedMixedAttributeValue(IUnknown** mixedAttributeValue) mut => VT.[Friend]get_ReservedMixedAttributeValue(&this, mixedAttributeValue);

	public HRESULT ElementFromIAccessible(IAccessible* accessible, int32 childId, IUIAutomationElement** element) mut => VT.[Friend]ElementFromIAccessible(&this, accessible, childId, element);

	public HRESULT ElementFromIAccessibleBuildCache(IAccessible* accessible, int32 childId, IUIAutomationCacheRequest* cacheRequest, IUIAutomationElement** element) mut => VT.[Friend]ElementFromIAccessibleBuildCache(&this, accessible, childId, cacheRequest, element);
}

[CRepr]struct IUIAutomation2 : IUIAutomation
{
	public new const Guid IID = .(0x34723aff, 0x0c9d, 0x49d0, 0x98, 0x96, 0x7a, 0xb5, 0x2d, 0xf8, 0xcd, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* autoSetFocus) get_AutoSetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL autoSetFocus) put_AutoSetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* timeout) get_ConnectionTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 timeout) put_ConnectionTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* timeout) get_TransactionTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 timeout) put_TransactionTimeout;
	}


	public HRESULT get_AutoSetFocus(BOOL* autoSetFocus) mut => VT.[Friend]get_AutoSetFocus(&this, autoSetFocus);

	public HRESULT put_AutoSetFocus(BOOL autoSetFocus) mut => VT.[Friend]put_AutoSetFocus(&this, autoSetFocus);

	public HRESULT get_ConnectionTimeout(uint32* timeout) mut => VT.[Friend]get_ConnectionTimeout(&this, timeout);

	public HRESULT put_ConnectionTimeout(uint32 timeout) mut => VT.[Friend]put_ConnectionTimeout(&this, timeout);

	public HRESULT get_TransactionTimeout(uint32* timeout) mut => VT.[Friend]get_TransactionTimeout(&this, timeout);

	public HRESULT put_TransactionTimeout(uint32 timeout) mut => VT.[Friend]put_TransactionTimeout(&this, timeout);
}

[CRepr]struct IUIAutomation3 : IUIAutomation2
{
	public new const Guid IID = .(0x73d768da, 0x9b51, 0x4b89, 0x93, 0x6e, 0xc2, 0x09, 0x29, 0x09, 0x73, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomation2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, TextEditChangeType textEditChangeType, IUIAutomationCacheRequest* cacheRequest, IUIAutomationTextEditTextChangedEventHandler* handler) AddTextEditTextChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationTextEditTextChangedEventHandler* handler) RemoveTextEditTextChangedEventHandler;
	}


	public HRESULT AddTextEditTextChangedEventHandler(IUIAutomationElement* element, TreeScope @scope, TextEditChangeType textEditChangeType, IUIAutomationCacheRequest* cacheRequest, IUIAutomationTextEditTextChangedEventHandler* handler) mut => VT.[Friend]AddTextEditTextChangedEventHandler(&this, element, @scope, textEditChangeType, cacheRequest, handler);

	public HRESULT RemoveTextEditTextChangedEventHandler(IUIAutomationElement* element, IUIAutomationTextEditTextChangedEventHandler* handler) mut => VT.[Friend]RemoveTextEditTextChangedEventHandler(&this, element, handler);
}

[CRepr]struct IUIAutomation4 : IUIAutomation3
{
	public new const Guid IID = .(0x1189c02a, 0x05f8, 0x4319, 0x8e, 0x21, 0xe8, 0x17, 0xe3, 0xdb, 0x28, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomation3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, int32* changeTypes, int32 changesCount, IUIAutomationCacheRequest* pCacheRequest, IUIAutomationChangesEventHandler* handler) AddChangesEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationChangesEventHandler* handler) RemoveChangesEventHandler;
	}


	public HRESULT AddChangesEventHandler(IUIAutomationElement* element, TreeScope @scope, int32* changeTypes, int32 changesCount, IUIAutomationCacheRequest* pCacheRequest, IUIAutomationChangesEventHandler* handler) mut => VT.[Friend]AddChangesEventHandler(&this, element, @scope, changeTypes, changesCount, pCacheRequest, handler);

	public HRESULT RemoveChangesEventHandler(IUIAutomationElement* element, IUIAutomationChangesEventHandler* handler) mut => VT.[Friend]RemoveChangesEventHandler(&this, element, handler);
}

[CRepr]struct IUIAutomation5 : IUIAutomation4
{
	public new const Guid IID = .(0x25f700c8, 0xd816, 0x4057, 0xa9, 0xdc, 0x3c, 0xbd, 0xee, 0x77, 0xe2, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomation4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationNotificationEventHandler* handler) AddNotificationEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationNotificationEventHandler* handler) RemoveNotificationEventHandler;
	}


	public HRESULT AddNotificationEventHandler(IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationNotificationEventHandler* handler) mut => VT.[Friend]AddNotificationEventHandler(&this, element, @scope, cacheRequest, handler);

	public HRESULT RemoveNotificationEventHandler(IUIAutomationElement* element, IUIAutomationNotificationEventHandler* handler) mut => VT.[Friend]RemoveNotificationEventHandler(&this, element, handler);
}

[CRepr]struct IUIAutomation6 : IUIAutomation5
{
	public new const Guid IID = .(0xaae072da, 0x29e3, 0x413d, 0x87, 0xa7, 0x19, 0x2d, 0xbf, 0x81, 0xed, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUIAutomation5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationEventHandlerGroup** handlerGroup) CreateEventHandlerGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationEventHandlerGroup* handlerGroup) AddEventHandlerGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationEventHandlerGroup* handlerGroup) RemoveEventHandlerGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ConnectionRecoveryBehaviorOptions* connectionRecoveryBehaviorOptions) get_ConnectionRecoveryBehavior;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ConnectionRecoveryBehaviorOptions connectionRecoveryBehaviorOptions) put_ConnectionRecoveryBehavior;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CoalesceEventsOptions* coalesceEventsOptions) get_CoalesceEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CoalesceEventsOptions coalesceEventsOptions) put_CoalesceEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationActiveTextPositionChangedEventHandler* handler) AddActiveTextPositionChangedEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAutomationElement* element, IUIAutomationActiveTextPositionChangedEventHandler* handler) RemoveActiveTextPositionChangedEventHandler;
	}


	public HRESULT CreateEventHandlerGroup(IUIAutomationEventHandlerGroup** handlerGroup) mut => VT.[Friend]CreateEventHandlerGroup(&this, handlerGroup);

	public HRESULT AddEventHandlerGroup(IUIAutomationElement* element, IUIAutomationEventHandlerGroup* handlerGroup) mut => VT.[Friend]AddEventHandlerGroup(&this, element, handlerGroup);

	public HRESULT RemoveEventHandlerGroup(IUIAutomationElement* element, IUIAutomationEventHandlerGroup* handlerGroup) mut => VT.[Friend]RemoveEventHandlerGroup(&this, element, handlerGroup);

	public HRESULT get_ConnectionRecoveryBehavior(ConnectionRecoveryBehaviorOptions* connectionRecoveryBehaviorOptions) mut => VT.[Friend]get_ConnectionRecoveryBehavior(&this, connectionRecoveryBehaviorOptions);

	public HRESULT put_ConnectionRecoveryBehavior(ConnectionRecoveryBehaviorOptions connectionRecoveryBehaviorOptions) mut => VT.[Friend]put_ConnectionRecoveryBehavior(&this, connectionRecoveryBehaviorOptions);

	public HRESULT get_CoalesceEvents(CoalesceEventsOptions* coalesceEventsOptions) mut => VT.[Friend]get_CoalesceEvents(&this, coalesceEventsOptions);

	public HRESULT put_CoalesceEvents(CoalesceEventsOptions coalesceEventsOptions) mut => VT.[Friend]put_CoalesceEvents(&this, coalesceEventsOptions);

	public HRESULT AddActiveTextPositionChangedEventHandler(IUIAutomationElement* element, TreeScope @scope, IUIAutomationCacheRequest* cacheRequest, IUIAutomationActiveTextPositionChangedEventHandler* handler) mut => VT.[Friend]AddActiveTextPositionChangedEventHandler(&this, element, @scope, cacheRequest, handler);

	public HRESULT RemoveActiveTextPositionChangedEventHandler(IUIAutomationElement* element, IUIAutomationActiveTextPositionChangedEventHandler* handler) mut => VT.[Friend]RemoveActiveTextPositionChangedEventHandler(&this, element, handler);
}

[CRepr]struct IRicheditWindowlessAccessibility : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRawElementProviderWindowlessSite* pSite, IRawElementProviderSimple** ppProvider) CreateProvider;
	}


	public HRESULT CreateProvider(IRawElementProviderWindowlessSite* pSite, IRawElementProviderSimple** ppProvider) mut => VT.[Friend]CreateProvider(&this, pSite, ppProvider);
}

[CRepr]struct IRichEditUiaInformation : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UiaRect* pUiaRect) GetBoundaryRectangle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsVisible;
	}


	public HRESULT GetBoundaryRectangle(UiaRect* pUiaRect) mut => VT.[Friend]GetBoundaryRectangle(&this, pUiaRect);

	public HRESULT IsVisible() mut => VT.[Friend]IsVisible(&this);
}

#endregion

#region Functions
public static
{
	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT LresultFromObject(in Guid riid, WPARAM wParam, IUnknown* punk);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ObjectFromLresult(LRESULT lResult, in Guid riid, WPARAM wParam, void** ppvObject);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowFromAccessibleObject(IAccessible* param0, HWND* phwnd);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AccessibleObjectFromWindow(HWND hwnd, uint32 dwId, in Guid riid, void** ppvObject);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AccessibleObjectFromEvent(HWND hwnd, uint32 dwId, uint32 dwChildId, IAccessible** ppacc, VARIANT* pvarChild);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AccessibleObjectFromPoint(POINT ptScreen, IAccessible** ppacc, VARIANT* pvarChild);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AccessibleChildren(IAccessible* paccContainer, int32 iChildStart, int32 cChildren, VARIANT* rgvarChildren, int32* pcObtained);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRoleTextA(uint32 lRole, uint8* lpszRole, uint32 cchRoleMax);
	public static uint32 GetRoleText(uint32 lRole, uint8* lpszRole, uint32 cchRoleMax) => GetRoleTextA(lRole, lpszRole, cchRoleMax);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRoleTextW(uint32 lRole, char16* lpszRole, uint32 cchRoleMax);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetStateTextA(uint32 lStateBit, uint8* lpszState, uint32 cchState);
	public static uint32 GetStateText(uint32 lStateBit, uint8* lpszState, uint32 cchState) => GetStateTextA(lStateBit, lpszState, cchState);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetStateTextW(uint32 lStateBit, char16* lpszState, uint32 cchState);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetOleaccVersionInfo(uint32* pVer, uint32* pBuild);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStdAccessibleObject(HWND hwnd, int32 idObject, in Guid riid, void** ppvObject);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStdAccessibleProxyA(HWND hwnd, PSTR pClassName, int32 idObject, in Guid riid, void** ppvObject);
	public static HRESULT CreateStdAccessibleProxy(HWND hwnd, PSTR pClassName, int32 idObject, in Guid riid, void** ppvObject) => CreateStdAccessibleProxyA(hwnd, pClassName, idObject, riid, ppvObject);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStdAccessibleProxyW(HWND hwnd, PWSTR pClassName, int32 idObject, in Guid riid, void** ppvObject);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AccSetRunningUtilityState(HWND hwndApp, uint32 dwUtilityStateMask, ACC_UTILITY_STATE_FLAGS dwUtilityState);

	[Import("OLEACC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AccNotifyTouchInteraction(HWND hwndApp, HWND hwndTarget, POINT ptTarget);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UiaGetErrorDescription(BSTR* pDescription);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaHUiaNodeFromVariant(VARIANT* pvar, HUIANODE* phnode);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaHPatternObjectFromVariant(VARIANT* pvar, HUIAPATTERNOBJECT* phobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaHTextRangeFromVariant(VARIANT* pvar, HUIATEXTRANGE* phtextrange);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UiaNodeRelease(HUIANODE hnode);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetPropertyValue(HUIANODE hnode, int32 propertyId, VARIANT* pValue);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetPatternProvider(HUIANODE hnode, int32 patternId, HUIAPATTERNOBJECT* phobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetRuntimeId(HUIANODE hnode, SAFEARRAY** pruntimeId);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaSetFocus(HUIANODE hnode);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaNavigate(HUIANODE hnode, NavigateDirection direction, UiaCondition* pCondition, UiaCacheRequest* pRequest, SAFEARRAY** ppRequestedData, BSTR* ppTreeStructure);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetUpdatedCache(HUIANODE hnode, UiaCacheRequest* pRequest, NormalizeState normalizeState, UiaCondition* pNormalizeCondition, SAFEARRAY** ppRequestedData, BSTR* ppTreeStructure);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaFind(HUIANODE hnode, UiaFindParams* pParams, UiaCacheRequest* pRequest, SAFEARRAY** ppRequestedData, SAFEARRAY** ppOffsets, SAFEARRAY** ppTreeStructures);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaNodeFromPoint(double x, double y, UiaCacheRequest* pRequest, SAFEARRAY** ppRequestedData, BSTR* ppTreeStructure);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaNodeFromFocus(UiaCacheRequest* pRequest, SAFEARRAY** ppRequestedData, BSTR* ppTreeStructure);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaNodeFromHandle(HWND hwnd, HUIANODE* phnode);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaNodeFromProvider(IRawElementProviderSimple* pProvider, HUIANODE* phnode);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetRootNode(HUIANODE* phnode);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UiaRegisterProviderCallback(UiaProviderCallback* pCallback);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 UiaLookupId(AutomationIdentifierType type, in Guid pGuid);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetReservedNotSupportedValue(IUnknown** punkNotSupportedValue);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaGetReservedMixedAttributeValue(IUnknown** punkMixedAttributeValue);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UiaClientsAreListening();

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseAutomationPropertyChangedEvent(IRawElementProviderSimple* pProvider, UIA_PROPERTY_ID id, VARIANT oldValue, VARIANT newValue);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseAutomationEvent(IRawElementProviderSimple* pProvider, UIA_EVENT_ID id);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseStructureChangedEvent(IRawElementProviderSimple* pProvider, StructureChangeType structureChangeType, int32* pRuntimeId, int32 cRuntimeIdLen);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseAsyncContentLoadedEvent(IRawElementProviderSimple* pProvider, AsyncContentLoadedState asyncContentLoadedState, double percentComplete);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseTextEditTextChangedEvent(IRawElementProviderSimple* pProvider, TextEditChangeType textEditChangeType, SAFEARRAY* pChangedData);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseChangesEvent(IRawElementProviderSimple* pProvider, int32 eventIdCount, UiaChangeInfo* pUiaChanges);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseNotificationEvent(IRawElementProviderSimple* provider, NotificationKind notificationKind, NotificationProcessing notificationProcessing, BSTR displayString, BSTR activityId);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRaiseActiveTextPositionChangedEvent(IRawElementProviderSimple* provider, ITextRangeProvider* textRange);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaAddEvent(HUIANODE hnode, int32 eventId, UiaEventCallback* pCallback, TreeScope @scope, int32* pProperties, int32 cProperties, UiaCacheRequest* pRequest, HUIAEVENT* phEvent);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaRemoveEvent(HUIAEVENT hEvent);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaEventAddWindow(HUIAEVENT hEvent, HWND hwnd);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaEventRemoveWindow(HUIAEVENT hEvent, HWND hwnd);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DockPattern_SetDockPosition(HUIAPATTERNOBJECT hobj, DockPosition dockPosition);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExpandCollapsePattern_Collapse(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExpandCollapsePattern_Expand(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GridPattern_GetItem(HUIAPATTERNOBJECT hobj, int32 row, int32 column, HUIANODE* pResult);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InvokePattern_Invoke(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MultipleViewPattern_GetViewName(HUIAPATTERNOBJECT hobj, int32 viewId, BSTR* ppStr);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MultipleViewPattern_SetCurrentView(HUIAPATTERNOBJECT hobj, int32 viewId);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RangeValuePattern_SetValue(HUIAPATTERNOBJECT hobj, double val);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScrollItemPattern_ScrollIntoView(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScrollPattern_Scroll(HUIAPATTERNOBJECT hobj, ScrollAmount horizontalAmount, ScrollAmount verticalAmount);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScrollPattern_SetScrollPercent(HUIAPATTERNOBJECT hobj, double horizontalPercent, double verticalPercent);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SelectionItemPattern_AddToSelection(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SelectionItemPattern_RemoveFromSelection(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SelectionItemPattern_Select(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TogglePattern_Toggle(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TransformPattern_Move(HUIAPATTERNOBJECT hobj, double x, double y);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TransformPattern_Resize(HUIAPATTERNOBJECT hobj, double width, double height);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TransformPattern_Rotate(HUIAPATTERNOBJECT hobj, double degrees);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ValuePattern_SetValue(HUIAPATTERNOBJECT hobj, PWSTR pVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowPattern_Close(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowPattern_SetWindowVisualState(HUIAPATTERNOBJECT hobj, WindowVisualState state);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowPattern_WaitForInputIdle(HUIAPATTERNOBJECT hobj, int32 milliseconds, BOOL* pResult);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextPattern_GetSelection(HUIAPATTERNOBJECT hobj, SAFEARRAY** pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextPattern_GetVisibleRanges(HUIAPATTERNOBJECT hobj, SAFEARRAY** pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextPattern_RangeFromChild(HUIAPATTERNOBJECT hobj, HUIANODE hnodeChild, HUIATEXTRANGE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextPattern_RangeFromPoint(HUIAPATTERNOBJECT hobj, UiaPoint point, HUIATEXTRANGE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextPattern_get_DocumentRange(HUIAPATTERNOBJECT hobj, HUIATEXTRANGE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextPattern_get_SupportedTextSelection(HUIAPATTERNOBJECT hobj, SupportedTextSelection* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_Clone(HUIATEXTRANGE hobj, HUIATEXTRANGE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_Compare(HUIATEXTRANGE hobj, HUIATEXTRANGE range, BOOL* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_CompareEndpoints(HUIATEXTRANGE hobj, TextPatternRangeEndpoint endpoint, HUIATEXTRANGE targetRange, TextPatternRangeEndpoint targetEndpoint, int32* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_ExpandToEnclosingUnit(HUIATEXTRANGE hobj, TextUnit unit);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_GetAttributeValue(HUIATEXTRANGE hobj, int32 attributeId, VARIANT* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_FindAttribute(HUIATEXTRANGE hobj, int32 attributeId, VARIANT val, BOOL backward, HUIATEXTRANGE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_FindText(HUIATEXTRANGE hobj, BSTR text, BOOL backward, BOOL ignoreCase, HUIATEXTRANGE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_GetBoundingRectangles(HUIATEXTRANGE hobj, SAFEARRAY** pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_GetEnclosingElement(HUIATEXTRANGE hobj, HUIANODE* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_GetText(HUIATEXTRANGE hobj, int32 maxLength, BSTR* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_Move(HUIATEXTRANGE hobj, TextUnit unit, int32 count, int32* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_MoveEndpointByUnit(HUIATEXTRANGE hobj, TextPatternRangeEndpoint endpoint, TextUnit unit, int32 count, int32* pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_MoveEndpointByRange(HUIATEXTRANGE hobj, TextPatternRangeEndpoint endpoint, HUIATEXTRANGE targetRange, TextPatternRangeEndpoint targetEndpoint);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_Select(HUIATEXTRANGE hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_AddToSelection(HUIATEXTRANGE hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_RemoveFromSelection(HUIATEXTRANGE hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_ScrollIntoView(HUIATEXTRANGE hobj, BOOL alignToTop);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TextRange_GetChildren(HUIATEXTRANGE hobj, SAFEARRAY** pRetVal);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ItemContainerPattern_FindItemByProperty(HUIAPATTERNOBJECT hobj, HUIANODE hnodeStartAfter, int32 propertyId, VARIANT value, HUIANODE* pFound);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LegacyIAccessiblePattern_Select(HUIAPATTERNOBJECT hobj, int32 flagsSelect);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LegacyIAccessiblePattern_DoDefaultAction(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LegacyIAccessiblePattern_SetValue(HUIAPATTERNOBJECT hobj, PWSTR szValue);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LegacyIAccessiblePattern_GetIAccessible(HUIAPATTERNOBJECT hobj, IAccessible** pAccessible);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SynchronizedInputPattern_StartListening(HUIAPATTERNOBJECT hobj, SynchronizedInputType inputType);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SynchronizedInputPattern_Cancel(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VirtualizedItemPattern_Realize(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UiaPatternRelease(HUIAPATTERNOBJECT hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UiaTextRangeRelease(HUIATEXTRANGE hobj);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT UiaReturnRawElementProvider(HWND hwnd, WPARAM wParam, LPARAM lParam, IRawElementProviderSimple* el);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaHostProviderFromHwnd(HWND hwnd, IRawElementProviderSimple** ppProvider);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaProviderForNonClient(HWND hwnd, int32 idObject, int32 idChild, IRawElementProviderSimple** ppProvider);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaIAccessibleFromProvider(IRawElementProviderSimple* pProvider, uint32 dwFlags, IAccessible** ppAccessible, VARIANT* pvarChild);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaProviderFromIAccessible(IAccessible* pAccessible, int32 idChild, uint32 dwFlags, IRawElementProviderSimple** ppProvider);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaDisconnectAllProviders();

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UiaDisconnectProvider(IRawElementProviderSimple* pProvider);

	[Import("UIAutomationCore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UiaHasServerSideProvider(HWND hwnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterPointerInputTarget(HWND hwnd, POINTER_INPUT_TYPE pointerType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterPointerInputTarget(HWND hwnd, POINTER_INPUT_TYPE pointerType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterPointerInputTargetEx(HWND hwnd, POINTER_INPUT_TYPE pointerType, BOOL fObserve);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterPointerInputTargetEx(HWND hwnd, POINTER_INPUT_TYPE pointerType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NotifyWinEvent(uint32 event, HWND hwnd, int32 idObject, int32 idChild);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINEVENTHOOK SetWinEventHook(uint32 eventMin, uint32 eventMax, HINSTANCE hmodWinEventProc, WINEVENTPROC pfnWinEventProc, uint32 idProcess, uint32 idThread, uint32 dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsWinEventHookInstalled(uint32 event);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnhookWinEvent(HWINEVENTHOOK hWinEventHook);

}
#endregion
