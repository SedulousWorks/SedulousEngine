using Win32.Foundation;
using Win32.System.Com;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Gdi;
using Win32.System.SystemServices;
using Win32.System.Com.StructuredStorage;
using Win32.Media;
using Win32.UI.Controls.Dialogs;
using Win32.UI.Controls;
using System;

namespace Win32.System.Ole;

#region Constants
public static
{
	public const int32 CTL_E_ILLEGALFUNCTIONCALL = -2146828283;
	public const int32 CONNECT_E_FIRST = -2147220992;
	public const int32 SELFREG_E_FIRST = -2147220992;
	public const int32 PERPROP_E_FIRST = -2147220992;
	public const HRESULT OLECMDERR_E_FIRST = -2147221248;
	public const HRESULT OLECMDERR_E_DISABLED = -2147221247;
	public const HRESULT OLECMDERR_E_NOHELP = -2147221246;
	public const HRESULT OLECMDERR_E_CANCELED = -2147221245;
	public const HRESULT OLECMDERR_E_UNKNOWNGROUP = -2147221244;
	public const HRESULT CONNECT_E_NOCONNECTION = -2147220992;
	public const HRESULT CONNECT_E_ADVISELIMIT = -2147220991;
	public const HRESULT CONNECT_E_CANNOTCONNECT = -2147220990;
	public const HRESULT CONNECT_E_OVERRIDDEN = -2147220989;
	public const HRESULT SELFREG_E_TYPELIB = -2147220992;
	public const HRESULT SELFREG_E_CLASS = -2147220991;
	public const HRESULT PERPROP_E_NOPAGEAVAILABLE = -2147220992;
	public const Guid CLSID_CFontPropPage = .(0x0be35200, 0x8f91, 0x11ce, 0x9d, 0xe3, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);
	public const Guid CLSID_CColorPropPage = .(0x0be35201, 0x8f91, 0x11ce, 0x9d, 0xe3, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);
	public const Guid CLSID_CPicturePropPage = .(0x0be35202, 0x8f91, 0x11ce, 0x9d, 0xe3, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);
	public const Guid CLSID_PersistPropset = .(0xfb8f0821, 0x0164, 0x101b, 0x84, 0xed, 0x08, 0x00, 0x2b, 0x2e, 0xc7, 0x13);
	public const Guid CLSID_ConvertVBX = .(0xfb8f0822, 0x0164, 0x101b, 0x84, 0xed, 0x08, 0x00, 0x2b, 0x2e, 0xc7, 0x13);
	public const Guid CLSID_StdFont = .(0x0be35203, 0x8f91, 0x11ce, 0x9d, 0xe3, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);
	public const Guid CLSID_StdPicture = .(0x0be35204, 0x8f91, 0x11ce, 0x9d, 0xe3, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);
	public const Guid GUID_HIMETRIC = .(0x66504300, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_COLOR = .(0x66504301, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_XPOSPIXEL = .(0x66504302, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_YPOSPIXEL = .(0x66504303, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_XSIZEPIXEL = .(0x66504304, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_YSIZEPIXEL = .(0x66504305, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_XPOS = .(0x66504306, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_YPOS = .(0x66504307, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_XSIZE = .(0x66504308, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_YSIZE = .(0x66504309, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_TRISTATE = .(0x6650430a, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_OPTIONVALUEEXCLUSIVE = .(0x6650430b, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_CHECKVALUEEXCLUSIVE = .(0x6650430c, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_FONTNAME = .(0x6650430d, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_FONTSIZE = .(0x6650430e, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_FONTBOLD = .(0x6650430f, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_FONTITALIC = .(0x66504310, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_FONTUNDERSCORE = .(0x66504311, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_FONTSTRIKETHROUGH = .(0x66504312, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const Guid GUID_HANDLE = .(0x66504313, 0xbe0f, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);
	public const HRESULT CONNECT_E_LAST = -2147220977;
	public const HRESULT CONNECT_S_FIRST = 262656;
	public const HRESULT CONNECT_S_LAST = 262671;
	public const HRESULT SELFREG_E_LAST = -2147220977;
	public const HRESULT SELFREG_S_FIRST = 262656;
	public const HRESULT SELFREG_S_LAST = 262671;
	public const HRESULT PERPROP_E_LAST = -2147220977;
	public const HRESULT PERPROP_S_FIRST = 262656;
	public const HRESULT PERPROP_S_LAST = 262671;
	public const int32 OLEIVERB_PROPERTIES = -7;
	public const uint32 VT_STREAMED_PROPSET = 73;
	public const uint32 VT_STORED_PROPSET = 74;
	public const uint32 VT_BLOB_PROPSET = 75;
	public const uint32 VT_VERBOSE_ENUM = 76;
	public const uint32 OCM__BASE = 8192;
	public const int32 DISPID_AUTOSIZE = -500;
	public const int32 DISPID_BACKCOLOR = -501;
	public const int32 DISPID_BACKSTYLE = -502;
	public const int32 DISPID_BORDERCOLOR = -503;
	public const int32 DISPID_BORDERSTYLE = -504;
	public const int32 DISPID_BORDERWIDTH = -505;
	public const int32 DISPID_DRAWMODE = -507;
	public const int32 DISPID_DRAWSTYLE = -508;
	public const int32 DISPID_DRAWWIDTH = -509;
	public const int32 DISPID_FILLCOLOR = -510;
	public const int32 DISPID_FILLSTYLE = -511;
	public const int32 DISPID_FONT = -512;
	public const int32 DISPID_FORECOLOR = -513;
	public const int32 DISPID_ENABLED = -514;
	public const int32 DISPID_HWND = -515;
	public const int32 DISPID_TABSTOP = -516;
	public const int32 DISPID_TEXT = -517;
	public const int32 DISPID_CAPTION = -518;
	public const int32 DISPID_BORDERVISIBLE = -519;
	public const int32 DISPID_APPEARANCE = -520;
	public const int32 DISPID_MOUSEPOINTER = -521;
	public const int32 DISPID_MOUSEICON = -522;
	public const int32 DISPID_PICTURE = -523;
	public const int32 DISPID_VALID = -524;
	public const int32 DISPID_READYSTATE = -525;
	public const int32 DISPID_LISTINDEX = -526;
	public const int32 DISPID_SELECTED = -527;
	public const int32 DISPID_LIST = -528;
	public const int32 DISPID_COLUMN = -529;
	public const int32 DISPID_LISTCOUNT = -531;
	public const int32 DISPID_MULTISELECT = -532;
	public const int32 DISPID_MAXLENGTH = -533;
	public const int32 DISPID_PASSWORDCHAR = -534;
	public const int32 DISPID_SCROLLBARS = -535;
	public const int32 DISPID_WORDWRAP = -536;
	public const int32 DISPID_MULTILINE = -537;
	public const int32 DISPID_NUMBEROFROWS = -538;
	public const int32 DISPID_NUMBEROFCOLUMNS = -539;
	public const int32 DISPID_DISPLAYSTYLE = -540;
	public const int32 DISPID_GROUPNAME = -541;
	public const int32 DISPID_IMEMODE = -542;
	public const int32 DISPID_ACCELERATOR = -543;
	public const int32 DISPID_ENTERKEYBEHAVIOR = -544;
	public const int32 DISPID_TABKEYBEHAVIOR = -545;
	public const int32 DISPID_SELTEXT = -546;
	public const int32 DISPID_SELSTART = -547;
	public const int32 DISPID_SELLENGTH = -548;
	public const int32 DISPID_REFRESH = -550;
	public const int32 DISPID_DOCLICK = -551;
	public const int32 DISPID_ABOUTBOX = -552;
	public const int32 DISPID_ADDITEM = -553;
	public const int32 DISPID_CLEAR = -554;
	public const int32 DISPID_REMOVEITEM = -555;
	public const int32 DISPID_CLICK = -600;
	public const int32 DISPID_DBLCLICK = -601;
	public const int32 DISPID_KEYDOWN = -602;
	public const int32 DISPID_KEYPRESS = -603;
	public const int32 DISPID_KEYUP = -604;
	public const int32 DISPID_MOUSEDOWN = -605;
	public const int32 DISPID_MOUSEMOVE = -606;
	public const int32 DISPID_MOUSEUP = -607;
	public const int32 DISPID_ERROREVENT = -608;
	public const int32 DISPID_READYSTATECHANGE = -609;
	public const int32 DISPID_CLICK_VALUE = -610;
	public const int32 DISPID_RIGHTTOLEFT = -611;
	public const int32 DISPID_TOPTOBOTTOM = -612;
	public const int32 DISPID_THIS = -613;
	public const int32 DISPID_AMBIENT_BACKCOLOR = -701;
	public const int32 DISPID_AMBIENT_DISPLAYNAME = -702;
	public const int32 DISPID_AMBIENT_FONT = -703;
	public const int32 DISPID_AMBIENT_FORECOLOR = -704;
	public const int32 DISPID_AMBIENT_LOCALEID = -705;
	public const int32 DISPID_AMBIENT_MESSAGEREFLECT = -706;
	public const int32 DISPID_AMBIENT_SCALEUNITS = -707;
	public const int32 DISPID_AMBIENT_TEXTALIGN = -708;
	public const int32 DISPID_AMBIENT_USERMODE = -709;
	public const int32 DISPID_AMBIENT_UIDEAD = -710;
	public const int32 DISPID_AMBIENT_SHOWGRABHANDLES = -711;
	public const int32 DISPID_AMBIENT_SHOWHATCHING = -712;
	public const int32 DISPID_AMBIENT_DISPLAYASDEFAULT = -713;
	public const int32 DISPID_AMBIENT_SUPPORTSMNEMONICS = -714;
	public const int32 DISPID_AMBIENT_AUTOCLIP = -715;
	public const int32 DISPID_AMBIENT_APPEARANCE = -716;
	public const int32 DISPID_AMBIENT_CODEPAGE = -725;
	public const int32 DISPID_AMBIENT_PALETTE = -726;
	public const int32 DISPID_AMBIENT_CHARSET = -727;
	public const int32 DISPID_AMBIENT_TRANSFERPRIORITY = -728;
	public const int32 DISPID_AMBIENT_RIGHTTOLEFT = -732;
	public const int32 DISPID_AMBIENT_TOPTOBOTTOM = -733;
	public const int32 DISPID_Name = -800;
	public const int32 DISPID_Delete = -801;
	public const int32 DISPID_Object = -802;
	public const int32 DISPID_Parent = -803;
	public const uint32 DISPID_FONT_NAME = 0;
	public const uint32 DISPID_FONT_SIZE = 2;
	public const uint32 DISPID_FONT_BOLD = 3;
	public const uint32 DISPID_FONT_ITALIC = 4;
	public const uint32 DISPID_FONT_UNDER = 5;
	public const uint32 DISPID_FONT_STRIKE = 6;
	public const uint32 DISPID_FONT_WEIGHT = 7;
	public const uint32 DISPID_FONT_CHARSET = 8;
	public const uint32 DISPID_FONT_CHANGED = 9;
	public const uint32 DISPID_PICT_HANDLE = 0;
	public const uint32 DISPID_PICT_HPAL = 2;
	public const uint32 DISPID_PICT_TYPE = 3;
	public const uint32 DISPID_PICT_WIDTH = 4;
	public const uint32 DISPID_PICT_HEIGHT = 5;
	public const uint32 DISPID_PICT_RENDER = 6;
	public const String STDOLE_TLB = "stdole2.tlb";
	public const String STDTYPE_TLB = "stdole2.tlb";
	public const int32 GC_WCH_SIBLING = 1;
	public const uint32 TIFLAGS_EXTENDDISPATCHONLY = 1;
	public const int32 OLECMDERR_E_NOTSUPPORTED = -2147221248;
	public const int32 MSOCMDERR_E_FIRST = -2147221248;
	public const int32 MSOCMDERR_E_NOTSUPPORTED = -2147221248;
	public const int32 MSOCMDERR_E_DISABLED = -2147221247;
	public const int32 MSOCMDERR_E_NOHELP = -2147221246;
	public const int32 MSOCMDERR_E_CANCELED = -2147221245;
	public const int32 MSOCMDERR_E_UNKNOWNGROUP = -2147221244;
	public const uint32 OLECMD_TASKDLGID_ONBEFOREUNLOAD = 1;
	public const uint32 OLECMDARGINDEX_SHOWPAGEACTIONMENU_HWND = 0;
	public const uint32 OLECMDARGINDEX_SHOWPAGEACTIONMENU_X = 1;
	public const uint32 OLECMDARGINDEX_SHOWPAGEACTIONMENU_Y = 2;
	public const uint32 OLECMDARGINDEX_ACTIVEXINSTALL_PUBLISHER = 0;
	public const uint32 OLECMDARGINDEX_ACTIVEXINSTALL_DISPLAYNAME = 1;
	public const uint32 OLECMDARGINDEX_ACTIVEXINSTALL_CLSID = 2;
	public const uint32 OLECMDARGINDEX_ACTIVEXINSTALL_INSTALLSCOPE = 3;
	public const uint32 OLECMDARGINDEX_ACTIVEXINSTALL_SOURCEURL = 4;
	public const uint32 INSTALL_SCOPE_INVALID = 0;
	public const uint32 INSTALL_SCOPE_MACHINE = 1;
	public const uint32 INSTALL_SCOPE_USER = 2;
	public const uint32 MK_ALT = 32;
	public const uint32 DD_DEFSCROLLINSET = 11;
	public const uint32 DD_DEFSCROLLDELAY = 50;
	public const uint32 DD_DEFSCROLLINTERVAL = 50;
	public const uint32 DD_DEFDRAGDELAY = 200;
	public const uint32 DD_DEFDRAGMINDIST = 2;
	public const int32 OT_LINK = 1;
	public const int32 OT_EMBEDDED = 2;
	public const int32 OT_STATIC = 3;
	public const uint32 OLEVERB_PRIMARY = 0;
	public const uint32 OF_SET = 1;
	public const uint32 OF_GET = 2;
	public const uint32 OF_HANDLER = 4;
	public const uint32 WIN32 = 100;
	public const int32 OLEIVERB_PRIMARY = 0;
	public const int32 OLEIVERB_SHOW = -1;
	public const int32 OLEIVERB_OPEN = -2;
	public const int32 OLEIVERB_HIDE = -3;
	public const int32 OLEIVERB_UIACTIVATE = -4;
	public const int32 OLEIVERB_INPLACEACTIVATE = -5;
	public const int32 OLEIVERB_DISCARDUNDOSTATE = -6;
	public const uint32 IDC_OLEUIHELP = 99;
	public const uint32 IDC_IO_CREATENEW = 2100;
	public const uint32 IDC_IO_CREATEFROMFILE = 2101;
	public const uint32 IDC_IO_LINKFILE = 2102;
	public const uint32 IDC_IO_OBJECTTYPELIST = 2103;
	public const uint32 IDC_IO_DISPLAYASICON = 2104;
	public const uint32 IDC_IO_CHANGEICON = 2105;
	public const uint32 IDC_IO_FILE = 2106;
	public const uint32 IDC_IO_FILEDISPLAY = 2107;
	public const uint32 IDC_IO_RESULTIMAGE = 2108;
	public const uint32 IDC_IO_RESULTTEXT = 2109;
	public const uint32 IDC_IO_ICONDISPLAY = 2110;
	public const uint32 IDC_IO_OBJECTTYPETEXT = 2111;
	public const uint32 IDC_IO_FILETEXT = 2112;
	public const uint32 IDC_IO_FILETYPE = 2113;
	public const uint32 IDC_IO_INSERTCONTROL = 2114;
	public const uint32 IDC_IO_ADDCONTROL = 2115;
	public const uint32 IDC_IO_CONTROLTYPELIST = 2116;
	public const uint32 IDC_PS_PASTE = 500;
	public const uint32 IDC_PS_PASTELINK = 501;
	public const uint32 IDC_PS_SOURCETEXT = 502;
	public const uint32 IDC_PS_PASTELIST = 503;
	public const uint32 IDC_PS_PASTELINKLIST = 504;
	public const uint32 IDC_PS_DISPLAYLIST = 505;
	public const uint32 IDC_PS_DISPLAYASICON = 506;
	public const uint32 IDC_PS_ICONDISPLAY = 507;
	public const uint32 IDC_PS_CHANGEICON = 508;
	public const uint32 IDC_PS_RESULTIMAGE = 509;
	public const uint32 IDC_PS_RESULTTEXT = 510;
	public const uint32 IDC_CI_GROUP = 120;
	public const uint32 IDC_CI_CURRENT = 121;
	public const uint32 IDC_CI_CURRENTICON = 122;
	public const uint32 IDC_CI_DEFAULT = 123;
	public const uint32 IDC_CI_DEFAULTICON = 124;
	public const uint32 IDC_CI_FROMFILE = 125;
	public const uint32 IDC_CI_FROMFILEEDIT = 126;
	public const uint32 IDC_CI_ICONLIST = 127;
	public const uint32 IDC_CI_LABEL = 128;
	public const uint32 IDC_CI_LABELEDIT = 129;
	public const uint32 IDC_CI_BROWSE = 130;
	public const uint32 IDC_CI_ICONDISPLAY = 131;
	public const uint32 IDC_CV_OBJECTTYPE = 150;
	public const uint32 IDC_CV_DISPLAYASICON = 152;
	public const uint32 IDC_CV_CHANGEICON = 153;
	public const uint32 IDC_CV_ACTIVATELIST = 154;
	public const uint32 IDC_CV_CONVERTTO = 155;
	public const uint32 IDC_CV_ACTIVATEAS = 156;
	public const uint32 IDC_CV_RESULTTEXT = 157;
	public const uint32 IDC_CV_CONVERTLIST = 158;
	public const uint32 IDC_CV_ICONDISPLAY = 165;
	public const uint32 IDC_EL_CHANGESOURCE = 201;
	public const uint32 IDC_EL_AUTOMATIC = 202;
	public const uint32 IDC_EL_CANCELLINK = 209;
	public const uint32 IDC_EL_UPDATENOW = 210;
	public const uint32 IDC_EL_OPENSOURCE = 211;
	public const uint32 IDC_EL_MANUAL = 212;
	public const uint32 IDC_EL_LINKSOURCE = 216;
	public const uint32 IDC_EL_LINKTYPE = 217;
	public const uint32 IDC_EL_LINKSLISTBOX = 206;
	public const uint32 IDC_EL_COL1 = 220;
	public const uint32 IDC_EL_COL2 = 221;
	public const uint32 IDC_EL_COL3 = 222;
	public const uint32 IDC_BZ_RETRY = 600;
	public const uint32 IDC_BZ_ICON = 601;
	public const uint32 IDC_BZ_MESSAGE1 = 602;
	public const uint32 IDC_BZ_SWITCHTO = 604;
	public const uint32 IDC_UL_METER = 1029;
	public const uint32 IDC_UL_STOP = 1030;
	public const uint32 IDC_UL_PERCENT = 1031;
	public const uint32 IDC_UL_PROGRESS = 1032;
	public const uint32 IDC_PU_LINKS = 900;
	public const uint32 IDC_PU_TEXT = 901;
	public const uint32 IDC_PU_CONVERT = 902;
	public const uint32 IDC_PU_ICON = 908;
	public const uint32 IDC_GP_OBJECTNAME = 1009;
	public const uint32 IDC_GP_OBJECTTYPE = 1010;
	public const uint32 IDC_GP_OBJECTSIZE = 1011;
	public const uint32 IDC_GP_CONVERT = 1013;
	public const uint32 IDC_GP_OBJECTICON = 1014;
	public const uint32 IDC_GP_OBJECTLOCATION = 1022;
	public const uint32 IDC_VP_PERCENT = 1000;
	public const uint32 IDC_VP_CHANGEICON = 1001;
	public const uint32 IDC_VP_EDITABLE = 1002;
	public const uint32 IDC_VP_ASICON = 1003;
	public const uint32 IDC_VP_RELATIVE = 1005;
	public const uint32 IDC_VP_SPIN = 1006;
	public const uint32 IDC_VP_SCALETXT = 1034;
	public const uint32 IDC_VP_ICONDISPLAY = 1021;
	public const uint32 IDC_VP_RESULTIMAGE = 1033;
	public const uint32 IDC_LP_OPENSOURCE = 1006;
	public const uint32 IDC_LP_UPDATENOW = 1007;
	public const uint32 IDC_LP_BREAKLINK = 1008;
	public const uint32 IDC_LP_LINKSOURCE = 1012;
	public const uint32 IDC_LP_CHANGESOURCE = 1015;
	public const uint32 IDC_LP_AUTOMATIC = 1016;
	public const uint32 IDC_LP_MANUAL = 1017;
	public const uint32 IDC_LP_DATE = 1018;
	public const uint32 IDC_LP_TIME = 1019;
	public const uint32 IDD_INSERTOBJECT = 1000;
	public const uint32 IDD_CHANGEICON = 1001;
	public const uint32 IDD_CONVERT = 1002;
	public const uint32 IDD_PASTESPECIAL = 1003;
	public const uint32 IDD_EDITLINKS = 1004;
	public const uint32 IDD_BUSY = 1006;
	public const uint32 IDD_UPDATELINKS = 1007;
	public const uint32 IDD_CHANGESOURCE = 1009;
	public const uint32 IDD_INSERTFILEBROWSE = 1010;
	public const uint32 IDD_CHANGEICONBROWSE = 1011;
	public const uint32 IDD_CONVERTONLY = 1012;
	public const uint32 IDD_CHANGESOURCE4 = 1013;
	public const uint32 IDD_GNRLPROPS = 1100;
	public const uint32 IDD_VIEWPROPS = 1101;
	public const uint32 IDD_LINKPROPS = 1102;
	public const uint32 IDD_CONVERT4 = 1103;
	public const uint32 IDD_CONVERTONLY4 = 1104;
	public const uint32 IDD_EDITLINKS4 = 1105;
	public const uint32 IDD_GNRLPROPS4 = 1106;
	public const uint32 IDD_LINKPROPS4 = 1107;
	public const uint32 IDD_PASTESPECIAL4 = 1108;
	public const uint32 IDD_CANNOTUPDATELINK = 1008;
	public const uint32 IDD_LINKSOURCEUNAVAILABLE = 1020;
	public const uint32 IDD_SERVERNOTFOUND = 1023;
	public const uint32 IDD_OUTOFMEMORY = 1024;
	public const uint32 IDD_SERVERNOTREGW = 1021;
	public const uint32 IDD_LINKTYPECHANGEDW = 1022;
	public const uint32 IDD_SERVERNOTREGA = 1025;
	public const uint32 IDD_LINKTYPECHANGEDA = 1026;
	public const uint32 IDD_SERVERNOTREG = 1021;
	public const uint32 IDD_LINKTYPECHANGED = 1022;
	public const String OLESTDDELIM = "\\";
	public const String SZOLEUI_MSG_HELP = "OLEUI_MSG_HELP";
	public const String SZOLEUI_MSG_ENDDIALOG = "OLEUI_MSG_ENDDIALOG";
	public const String SZOLEUI_MSG_BROWSE = "OLEUI_MSG_BROWSE";
	public const String SZOLEUI_MSG_CHANGEICON = "OLEUI_MSG_CHANGEICON";
	public const String SZOLEUI_MSG_CLOSEBUSYDIALOG = "OLEUI_MSG_CLOSEBUSYDIALOG";
	public const String SZOLEUI_MSG_CONVERT = "OLEUI_MSG_CONVERT";
	public const String SZOLEUI_MSG_CHANGESOURCE = "OLEUI_MSG_CHANGESOURCE";
	public const String SZOLEUI_MSG_ADDCONTROL = "OLEUI_MSG_ADDCONTROL";
	public const String SZOLEUI_MSG_BROWSE_OFN = "OLEUI_MSG_BROWSE_OFN";
	public const uint32 ID_BROWSE_CHANGEICON = 1;
	public const uint32 ID_BROWSE_INSERTFILE = 2;
	public const uint32 ID_BROWSE_ADDCONTROL = 3;
	public const uint32 ID_BROWSE_CHANGESOURCE = 4;
	public const uint32 OLEUI_FALSE = 0;
	public const uint32 OLEUI_SUCCESS = 1;
	public const uint32 OLEUI_OK = 1;
	public const uint32 OLEUI_CANCEL = 2;
	public const uint32 OLEUI_ERR_STANDARDMIN = 100;
	public const uint32 OLEUI_ERR_OLEMEMALLOC = 100;
	public const uint32 OLEUI_ERR_STRUCTURENULL = 101;
	public const uint32 OLEUI_ERR_STRUCTUREINVALID = 102;
	public const uint32 OLEUI_ERR_CBSTRUCTINCORRECT = 103;
	public const uint32 OLEUI_ERR_HWNDOWNERINVALID = 104;
	public const uint32 OLEUI_ERR_LPSZCAPTIONINVALID = 105;
	public const uint32 OLEUI_ERR_LPFNHOOKINVALID = 106;
	public const uint32 OLEUI_ERR_HINSTANCEINVALID = 107;
	public const uint32 OLEUI_ERR_LPSZTEMPLATEINVALID = 108;
	public const uint32 OLEUI_ERR_HRESOURCEINVALID = 109;
	public const uint32 OLEUI_ERR_FINDTEMPLATEFAILURE = 110;
	public const uint32 OLEUI_ERR_LOADTEMPLATEFAILURE = 111;
	public const uint32 OLEUI_ERR_DIALOGFAILURE = 112;
	public const uint32 OLEUI_ERR_LOCALMEMALLOC = 113;
	public const uint32 OLEUI_ERR_GLOBALMEMALLOC = 114;
	public const uint32 OLEUI_ERR_LOADSTRING = 115;
	public const uint32 OLEUI_ERR_STANDARDMAX = 116;
	public const uint32 OLEUI_IOERR_LPSZFILEINVALID = 116;
	public const uint32 OLEUI_IOERR_LPSZLABELINVALID = 117;
	public const uint32 OLEUI_IOERR_HICONINVALID = 118;
	public const uint32 OLEUI_IOERR_LPFORMATETCINVALID = 119;
	public const uint32 OLEUI_IOERR_PPVOBJINVALID = 120;
	public const uint32 OLEUI_IOERR_LPIOLECLIENTSITEINVALID = 121;
	public const uint32 OLEUI_IOERR_LPISTORAGEINVALID = 122;
	public const uint32 OLEUI_IOERR_SCODEHASERROR = 123;
	public const uint32 OLEUI_IOERR_LPCLSIDEXCLUDEINVALID = 124;
	public const uint32 OLEUI_IOERR_CCHFILEINVALID = 125;
	public const uint32 PS_MAXLINKTYPES = 8;
	public const uint32 OLEUI_IOERR_SRCDATAOBJECTINVALID = 116;
	public const uint32 OLEUI_IOERR_ARRPASTEENTRIESINVALID = 117;
	public const uint32 OLEUI_IOERR_ARRLINKTYPESINVALID = 118;
	public const uint32 OLEUI_PSERR_CLIPBOARDCHANGED = 119;
	public const uint32 OLEUI_PSERR_GETCLIPBOARDFAILED = 120;
	public const uint32 OLEUI_ELERR_LINKCNTRNULL = 116;
	public const uint32 OLEUI_ELERR_LINKCNTRINVALID = 117;
	public const uint32 OLEUI_CIERR_MUSTHAVECLSID = 116;
	public const uint32 OLEUI_CIERR_MUSTHAVECURRENTMETAFILE = 117;
	public const uint32 OLEUI_CIERR_SZICONEXEINVALID = 118;
	public const String PROP_HWND_CHGICONDLG = "HWND_CIDLG";
	public const uint32 OLEUI_CTERR_CLASSIDINVALID = 117;
	public const uint32 OLEUI_CTERR_DVASPECTINVALID = 118;
	public const uint32 OLEUI_CTERR_CBFORMATINVALID = 119;
	public const uint32 OLEUI_CTERR_HMETAPICTINVALID = 120;
	public const uint32 OLEUI_CTERR_STRINGINVALID = 121;
	public const uint32 OLEUI_BZERR_HTASKINVALID = 116;
	public const uint32 OLEUI_BZ_SWITCHTOSELECTED = 117;
	public const uint32 OLEUI_BZ_RETRYSELECTED = 118;
	public const uint32 OLEUI_BZ_CALLUNBLOCKED = 119;
	public const uint32 OLEUI_CSERR_LINKCNTRNULL = 116;
	public const uint32 OLEUI_CSERR_LINKCNTRINVALID = 117;
	public const uint32 OLEUI_CSERR_FROMNOTNULL = 118;
	public const uint32 OLEUI_CSERR_TONOTNULL = 119;
	public const uint32 OLEUI_CSERR_SOURCENULL = 120;
	public const uint32 OLEUI_CSERR_SOURCEINVALID = 121;
	public const uint32 OLEUI_CSERR_SOURCEPARSERROR = 122;
	public const uint32 OLEUI_CSERR_SOURCEPARSEERROR = 122;
	public const uint32 OLEUI_OPERR_SUBPROPNULL = 116;
	public const uint32 OLEUI_OPERR_SUBPROPINVALID = 117;
	public const uint32 OLEUI_OPERR_PROPSHEETNULL = 118;
	public const uint32 OLEUI_OPERR_PROPSHEETINVALID = 119;
	public const uint32 OLEUI_OPERR_SUPPROP = 120;
	public const uint32 OLEUI_OPERR_PROPSINVALID = 121;
	public const uint32 OLEUI_OPERR_PAGESINCORRECT = 122;
	public const uint32 OLEUI_OPERR_INVALIDPAGES = 123;
	public const uint32 OLEUI_OPERR_NOTSUPPORTED = 124;
	public const uint32 OLEUI_OPERR_DLGPROCNOTNULL = 125;
	public const uint32 OLEUI_OPERR_LPARAMNOTZERO = 126;
	public const uint32 OLEUI_GPERR_STRINGINVALID = 127;
	public const uint32 OLEUI_GPERR_CLASSIDINVALID = 128;
	public const uint32 OLEUI_GPERR_LPCLSIDEXCLUDEINVALID = 129;
	public const uint32 OLEUI_GPERR_CBFORMATINVALID = 130;
	public const uint32 OLEUI_VPERR_METAPICTINVALID = 131;
	public const uint32 OLEUI_VPERR_DVASPECTINVALID = 132;
	public const uint32 OLEUI_LPERR_LINKCNTRNULL = 133;
	public const uint32 OLEUI_LPERR_LINKCNTRINVALID = 134;
	public const uint32 OLEUI_OPERR_PROPERTYSHEET = 135;
	public const uint32 OLEUI_OPERR_OBJINFOINVALID = 136;
	public const uint32 OLEUI_OPERR_LINKINFOINVALID = 137;
	public const uint32 OLEUI_QUERY_GETCLASSID = 65280;
	public const uint32 OLEUI_QUERY_LINKBROKEN = 65281;
	public const int32 DISPID_UNKNOWN = -1;
	public const uint32 DISPID_VALUE = 0;
	public const int32 DISPID_PROPERTYPUT = -3;
	public const int32 DISPID_NEWENUM = -4;
	public const int32 DISPID_EVALUATE = -5;
	public const int32 DISPID_CONSTRUCTOR = -6;
	public const int32 DISPID_DESTRUCTOR = -7;
	public const int32 DISPID_COLLECT = -8;
	public const uint32 STDOLE_MAJORVERNUM = 1;
	public const uint32 STDOLE_MINORVERNUM = 0;
	public const uint32 STDOLE_LCID = 0;
	public const uint32 STDOLE2_MAJORVERNUM = 2;
	public const uint32 STDOLE2_MINORVERNUM = 0;
	public const uint32 STDOLE2_LCID = 0;
	public const uint32 VARIANT_NOVALUEPROP = 1;
	public const uint32 VARIANT_ALPHABOOL = 2;
	public const uint32 VARIANT_NOUSEROVERRIDE = 4;
	public const uint32 VARIANT_CALENDAR_HIJRI = 8;
	public const uint32 VARIANT_LOCALBOOL = 16;
	public const uint32 VARIANT_CALENDAR_THAI = 32;
	public const uint32 VARIANT_CALENDAR_GREGORIAN = 64;
	public const uint32 VARIANT_USE_NLS = 128;
	public const uint32 LOCALE_USE_NLS = 268435456;
	public const uint32 VTDATEGRE_MAX = 2958465;
	public const int32 VTDATEGRE_MIN = -657434;
	public const int32 MEMBERID_NIL = -1;
	public const int32 ID_DEFAULTINST = -2;
	public const uint32 LOAD_TLB_AS_32BIT = 32;
	public const uint32 LOAD_TLB_AS_64BIT = 64;
	public const int32 fdexNameCaseSensitive = 1;
	public const int32 fdexNameEnsure = 2;
	public const int32 fdexNameImplicit = 4;
	public const int32 fdexNameCaseInsensitive = 8;
	public const int32 fdexNameInternal = 16;
	public const int32 fdexNameNoDynamicProperties = 32;
	public const int32 fdexEnumDefault = 1;
	public const int32 fdexEnumAll = 2;
	public const uint32 DISPATCH_CONSTRUCT = 16384;
	public const int32 DISPID_STARTENUM = -1;
	public const Guid SID_VariantConversion = .(0x1f101481, 0xbccd, 0x11d0, 0x93, 0x36, 0x00, 0xa0, 0xc9, 0x0d, 0xca, 0xa9);
	public const Guid SID_GetCaller = .(0x4717cc40, 0xbcb9, 0x11d0, 0x93, 0x36, 0x00, 0xa0, 0xc9, 0x0d, 0xca, 0xa9);
	public const Guid SID_ProvideRuntimeContext = .(0x74a5040c, 0xdd0c, 0x48f0, 0xac, 0x85, 0x19, 0x4c, 0x32, 0x59, 0x18, 0x0a);
}
#endregion

#region Enums

[AllowDuplicates]
public enum UPDFCACHE_FLAGS : uint32
{
	UPDFCACHE_ALL = 2147483647,
	UPDFCACHE_ALLBUTNODATACACHE = 2147483646,
	UPDFCACHE_NORMALCACHE = 8,
	UPDFCACHE_IFBLANK = 16,
	UPDFCACHE_ONLYIFBLANK = 2147483648,
	UPDFCACHE_NODATACACHE = 1,
	UPDFCACHE_ONSAVECACHE = 2,
	UPDFCACHE_ONSTOPCACHE = 4,
	UPDFCACHE_IFBLANKORONSAVECACHE = 18,
}


[AllowDuplicates]
public enum ENUM_CONTROLS_WHICH_FLAGS : uint32
{
	GCW_WCH_SIBLING = 1,
	GC_WCH_CONTAINER = 2,
	GC_WCH_CONTAINED = 3,
	GC_WCH_ALL = 4,
	GC_WCH_FREVERSEDIR = 134217728,
	GC_WCH_FONLYAFTER = 268435456,
	GC_WCH_FONLYBEFORE = 536870912,
	GC_WCH_FSELECTED = 1073741824,
}


[AllowDuplicates]
public enum MULTICLASSINFO_FLAGS : uint32
{
	MULTICLASSINFO_GETTYPEINFO = 1,
	MULTICLASSINFO_GETNUMRESERVEDDISPIDS = 2,
	MULTICLASSINFO_GETIIDPRIMARY = 4,
	MULTICLASSINFO_GETIIDSOURCE = 8,
}


[AllowDuplicates]
public enum DROPEFFECT : uint32
{
	DROPEFFECT_NONE = 0,
	DROPEFFECT_COPY = 1,
	DROPEFFECT_MOVE = 2,
	DROPEFFECT_LINK = 4,
	DROPEFFECT_SCROLL = 2147483648,
}


[AllowDuplicates]
public enum KEYMODIFIERS : uint32
{
	KEYMOD_SHIFT = 1,
	KEYMOD_CONTROL = 2,
	KEYMOD_ALT = 4,
}


[AllowDuplicates]
public enum ACTIVEOBJECT_FLAGS : uint32
{
	ACTIVEOBJECT_STRONG = 0,
	ACTIVEOBJECT_WEAK = 1,
}


[AllowDuplicates]
public enum BUSY_DIALOG_FLAGS : uint32
{
	BZ_DISABLECANCELBUTTON = 1,
	BZ_DISABLESWITCHTOBUTTON = 2,
	BZ_DISABLERETRYBUTTON = 4,
	BZ_NOTRESPONDINGDIALOG = 8,
}


[AllowDuplicates]
public enum UI_CONVERT_FLAGS : uint32
{
	CF_SHOWHELPBUTTON = 1,
	CF_SETCONVERTDEFAULT = 2,
	CF_SETACTIVATEDEFAULT = 4,
	CF_SELECTCONVERTTO = 8,
	CF_SELECTACTIVATEAS = 16,
	CF_DISABLEDISPLAYASICON = 32,
	CF_DISABLEACTIVATEAS = 64,
	CF_HIDECHANGEICON = 128,
	CF_CONVERTONLY = 256,
}


[AllowDuplicates]
public enum CHANGE_ICON_FLAGS : int32
{
	CIF_SHOWHELP = 1,
	CIF_SELECTCURRENT = 2,
	CIF_SELECTDEFAULT = 4,
	CIF_SELECTFROMFILE = 8,
	CIF_USEICONEXE = 16,
}


[AllowDuplicates]
public enum CHANGE_SOURCE_FLAGS : uint32
{
	CSF_SHOWHELP = 1,
	CSF_VALIDSOURCE = 2,
	CSF_ONLYGETSOURCE = 4,
	CSF_EXPLORER = 8,
}


[AllowDuplicates]
public enum EDIT_LINKS_FLAGS : uint32
{
	ELF_SHOWHELP = 1,
	ELF_DISABLEUPDATENOW = 2,
	ELF_DISABLEOPENSOURCE = 4,
	ELF_DISABLECHANGESOURCE = 8,
	ELF_DISABLECANCELLINK = 16,
}


[AllowDuplicates]
public enum INSERT_OBJECT_FLAGS : uint32
{
	IOF_SHOWHELP = 1,
	IOF_SELECTCREATENEW = 2,
	IOF_SELECTCREATEFROMFILE = 4,
	IOF_CHECKLINK = 8,
	IOF_CHECKDISPLAYASICON = 16,
	IOF_CREATENEWOBJECT = 32,
	IOF_CREATEFILEOBJECT = 64,
	IOF_CREATELINKOBJECT = 128,
	IOF_DISABLELINK = 256,
	IOF_VERIFYSERVERSEXIST = 512,
	IOF_DISABLEDISPLAYASICON = 1024,
	IOF_HIDECHANGEICON = 2048,
	IOF_SHOWINSERTCONTROL = 4096,
	IOF_SELECTCREATECONTROL = 8192,
}


[AllowDuplicates]
public enum OBJECT_PROPERTIES_FLAGS : uint32
{
	OPF_OBJECTISLINK = 1,
	OPF_NOFILLDEFAULT = 2,
	OPF_SHOWHELP = 4,
	OPF_DISABLECONVERT = 8,
}


[AllowDuplicates]
public enum VIEW_OBJECT_PROPERTIES_FLAGS : uint32
{
	VPF_SELECTRELATIVE = 1,
	VPF_DISABLERELATIVE = 2,
	VPF_DISABLESCALE = 4,
}


[AllowDuplicates]
public enum PARAMFLAGS : uint16
{
	PARAMFLAG_NONE = 0,
	PARAMFLAG_FIN = 1,
	PARAMFLAG_FOUT = 2,
	PARAMFLAG_FLCID = 4,
	PARAMFLAG_FRETVAL = 8,
	PARAMFLAG_FOPT = 16,
	PARAMFLAG_FHASDEFAULT = 32,
	PARAMFLAG_FHASCUSTDATA = 64,
}


[AllowDuplicates]
public enum NUMPARSE_FLAGS : uint32
{
	NUMPRS_LEADING_WHITE = 1,
	NUMPRS_TRAILING_WHITE = 2,
	NUMPRS_LEADING_PLUS = 4,
	NUMPRS_TRAILING_PLUS = 8,
	NUMPRS_LEADING_MINUS = 16,
	NUMPRS_TRAILING_MINUS = 32,
	NUMPRS_HEX_OCT = 64,
	NUMPRS_PARENS = 128,
	NUMPRS_DECIMAL = 256,
	NUMPRS_THOUSANDS = 512,
	NUMPRS_CURRENCY = 1024,
	NUMPRS_EXPONENT = 2048,
	NUMPRS_USE_ALL = 4096,
	NUMPRS_STD = 8191,
	NUMPRS_NEG = 65536,
	NUMPRS_INEXACT = 131072,
}


[AllowDuplicates]
public enum PICTYPE : int32
{
	PICTYPE_UNINITIALIZED = -1,
	PICTYPE_NONE = 0,
	PICTYPE_BITMAP = 1,
	PICTYPE_METAFILE = 2,
	PICTYPE_ICON = 3,
	PICTYPE_ENHMETAFILE = 4,
}


[AllowDuplicates]
public enum VARCMP : uint32
{
	VARCMP_LT = 0,
	VARCMP_EQ = 1,
	VARCMP_GT = 2,
	VARCMP_NULL = 3,
}


[AllowDuplicates]
public enum PASTE_SPECIAL_FLAGS : uint32
{
	PSF_SHOWHELP = 1,
	PSF_SELECTPASTE = 2,
	PSF_SELECTPASTELINK = 4,
	PSF_CHECKDISPLAYASICON = 8,
	PSF_DISABLEDISPLAYASICON = 16,
	PSF_HIDECHANGEICON = 32,
	PSF_STAYONCLIPBOARDCHANGE = 64,
	PSF_NOREFRESHDATAOBJECT = 128,
}


[AllowDuplicates]
public enum EMBDHLP_FLAGS : uint32
{
	EMBDHLP_INPROC_HANDLER = 0,
	EMBDHLP_INPROC_SERVER = 1,
	EMBDHLP_CREATENOW = 0,
	EMBDHLP_DELAYCREATE = 65536,
}


[AllowDuplicates]
public enum FDEX_PROP_FLAGS : uint32
{
	fdexPropCanGet = 1,
	fdexPropCannotGet = 2,
	fdexPropCanPut = 4,
	fdexPropCannotPut = 8,
	fdexPropCanPutRef = 16,
	fdexPropCannotPutRef = 32,
	fdexPropNoSideEffects = 64,
	fdexPropDynamicType = 128,
	fdexPropCanCall = 256,
	fdexPropCannotCall = 512,
	fdexPropCanConstruct = 1024,
	fdexPropCannotConstruct = 2048,
	fdexPropCanSourceEvents = 4096,
	fdexPropCannotSourceEvents = 8192,
}


[AllowDuplicates]
public enum LOAD_PICTURE_FLAGS : uint32
{
	LP_DEFAULT = 0,
	LP_MONOCHROME = 1,
	LP_VGACOLOR = 2,
	LP_COLOR = 4,
}


[AllowDuplicates]
public enum OLECREATE : uint32
{
	OLECREATE_ZERO = 0,
	OLECREATE_LEAVERUNNING = 1,
}


[AllowDuplicates]
public enum VARFORMAT_FIRST_DAY : int32
{
	VARFORMAT_FIRST_DAY_SYSTEMDEFAULT = 0,
	VARFORMAT_FIRST_DAY_MONDAY = 1,
	VARFORMAT_FIRST_DAY_TUESDAY = 2,
	VARFORMAT_FIRST_DAY_WEDNESDAY = 3,
	VARFORMAT_FIRST_DAY_THURSDAY = 4,
	VARFORMAT_FIRST_DAY_FRIDAY = 5,
	VARFORMAT_FIRST_DAY_SATURDAY = 6,
	VARFORMAT_FIRST_DAY_SUNDAY = 7,
}


[AllowDuplicates]
public enum VARFORMAT_FIRST_WEEK : int32
{
	VARFORMAT_FIRST_WEEK_SYSTEMDEFAULT = 0,
	VARFORMAT_FIRST_WEEK_CONTAINS_JANUARY_FIRST = 1,
	VARFORMAT_FIRST_WEEK_LARGER_HALF_IN_CURRENT_YEAR = 2,
	VARFORMAT_FIRST_WEEK_HAS_SEVEN_DAYS = 3,
}


[AllowDuplicates]
public enum VARFORMAT_NAMED_FORMAT : int32
{
	VARFORMAT_NAMED_FORMAT_GENERALDATE = 0,
	VARFORMAT_NAMED_FORMAT_LONGDATE = 1,
	VARFORMAT_NAMED_FORMAT_SHORTDATE = 2,
	VARFORMAT_NAMED_FORMAT_LONGTIME = 3,
	VARFORMAT_NAMED_FORMAT_SHORTTIME = 4,
}


[AllowDuplicates]
public enum VARFORMAT_LEADING_DIGIT : int32
{
	VARFORMAT_LEADING_DIGIT_SYSTEMDEFAULT = -2,
	VARFORMAT_LEADING_DIGIT_INCLUDED = -1,
	VARFORMAT_LEADING_DIGIT_NOTINCLUDED = 0,
}


[AllowDuplicates]
public enum VARFORMAT_PARENTHESES : int32
{
	VARFORMAT_PARENTHESES_SYSTEMDEFAULT = -2,
	VARFORMAT_PARENTHESES_USED = -1,
	VARFORMAT_PARENTHESES_NOTUSED = 0,
}


[AllowDuplicates]
public enum VARFORMAT_GROUP : int32
{
	VARFORMAT_GROUP_SYSTEMDEFAULT = -2,
	VARFORMAT_GROUP_THOUSANDS = -1,
	VARFORMAT_GROUP_NOTTHOUSANDS = 0,
}


[AllowDuplicates]
public enum SF_TYPE : int32
{
	SF_ERROR = 10,
	SF_I1 = 16,
	SF_I2 = 2,
	SF_I4 = 3,
	SF_I8 = 20,
	SF_BSTR = 8,
	SF_UNKNOWN = 13,
	SF_DISPATCH = 9,
	SF_VARIANT = 12,
	SF_RECORD = 36,
	SF_HAVEIID = 32781,
}


[AllowDuplicates]
public enum TYPEFLAGS : int32
{
	TYPEFLAG_FAPPOBJECT = 1,
	TYPEFLAG_FCANCREATE = 2,
	TYPEFLAG_FLICENSED = 4,
	TYPEFLAG_FPREDECLID = 8,
	TYPEFLAG_FHIDDEN = 16,
	TYPEFLAG_FCONTROL = 32,
	TYPEFLAG_FDUAL = 64,
	TYPEFLAG_FNONEXTENSIBLE = 128,
	TYPEFLAG_FOLEAUTOMATION = 256,
	TYPEFLAG_FRESTRICTED = 512,
	TYPEFLAG_FAGGREGATABLE = 1024,
	TYPEFLAG_FREPLACEABLE = 2048,
	TYPEFLAG_FDISPATCHABLE = 4096,
	TYPEFLAG_FREVERSEBIND = 8192,
	TYPEFLAG_FPROXY = 16384,
}


[AllowDuplicates]
public enum LIBFLAGS : int32
{
	LIBFLAG_FRESTRICTED = 1,
	LIBFLAG_FCONTROL = 2,
	LIBFLAG_FHIDDEN = 4,
	LIBFLAG_FHASDISKIMAGE = 8,
}


[AllowDuplicates]
public enum CHANGEKIND : int32
{
	CHANGEKIND_ADDMEMBER = 0,
	CHANGEKIND_DELETEMEMBER = 1,
	CHANGEKIND_SETNAMES = 2,
	CHANGEKIND_SETDOCUMENTATION = 3,
	CHANGEKIND_GENERAL = 4,
	CHANGEKIND_INVALIDATE = 5,
	CHANGEKIND_CHANGEFAILED = 6,
	CHANGEKIND_MAX = 7,
}


[AllowDuplicates]
public enum DISCARDCACHE : int32
{
	DISCARDCACHE_SAVEIFDIRTY = 0,
	DISCARDCACHE_NOSAVE = 1,
}


[AllowDuplicates]
public enum OLEGETMONIKER : int32
{
	OLEGETMONIKER_ONLYIFTHERE = 1,
	OLEGETMONIKER_FORCEASSIGN = 2,
	OLEGETMONIKER_UNASSIGN = 3,
	OLEGETMONIKER_TEMPFORUSER = 4,
}


[AllowDuplicates]
public enum OLEWHICHMK : int32
{
	OLEWHICHMK_CONTAINER = 1,
	OLEWHICHMK_OBJREL = 2,
	OLEWHICHMK_OBJFULL = 3,
}


[AllowDuplicates]
public enum USERCLASSTYPE : int32
{
	USERCLASSTYPE_FULL = 1,
	USERCLASSTYPE_SHORT = 2,
	USERCLASSTYPE_APPNAME = 3,
}


[AllowDuplicates]
public enum OLEMISC : int32
{
	OLEMISC_RECOMPOSEONRESIZE = 1,
	OLEMISC_ONLYICONIC = 2,
	OLEMISC_INSERTNOTREPLACE = 4,
	OLEMISC_STATIC = 8,
	OLEMISC_CANTLINKINSIDE = 16,
	OLEMISC_CANLINKBYOLE1 = 32,
	OLEMISC_ISLINKOBJECT = 64,
	OLEMISC_INSIDEOUT = 128,
	OLEMISC_ACTIVATEWHENVISIBLE = 256,
	OLEMISC_RENDERINGISDEVICEINDEPENDENT = 512,
	OLEMISC_INVISIBLEATRUNTIME = 1024,
	OLEMISC_ALWAYSRUN = 2048,
	OLEMISC_ACTSLIKEBUTTON = 4096,
	OLEMISC_ACTSLIKELABEL = 8192,
	OLEMISC_NOUIACTIVATE = 16384,
	OLEMISC_ALIGNABLE = 32768,
	OLEMISC_SIMPLEFRAME = 65536,
	OLEMISC_SETCLIENTSITEFIRST = 131072,
	OLEMISC_IMEMODE = 262144,
	OLEMISC_IGNOREACTIVATEWHENVISIBLE = 524288,
	OLEMISC_WANTSTOMENUMERGE = 1048576,
	OLEMISC_SUPPORTSMULTILEVELUNDO = 2097152,
}


[AllowDuplicates]
public enum OLECLOSE : int32
{
	OLECLOSE_SAVEIFDIRTY = 0,
	OLECLOSE_NOSAVE = 1,
	OLECLOSE_PROMPTSAVE = 2,
}


[AllowDuplicates]
public enum OLERENDER : int32
{
	OLERENDER_NONE = 0,
	OLERENDER_DRAW = 1,
	OLERENDER_FORMAT = 2,
	OLERENDER_ASIS = 3,
}


[AllowDuplicates]
public enum OLEUPDATE : int32
{
	OLEUPDATE_ALWAYS = 1,
	OLEUPDATE_ONCALL = 3,
}


[AllowDuplicates]
public enum OLELINKBIND : int32
{
	OLELINKBIND_EVENIFCLASSDIFF = 1,
}


[AllowDuplicates]
public enum BINDSPEED : int32
{
	BINDSPEED_INDEFINITE = 1,
	BINDSPEED_MODERATE = 2,
	BINDSPEED_IMMEDIATE = 3,
}


[AllowDuplicates]
public enum OLECONTF : int32
{
	OLECONTF_EMBEDDINGS = 1,
	OLECONTF_LINKS = 2,
	OLECONTF_OTHERS = 4,
	OLECONTF_ONLYUSER = 8,
	OLECONTF_ONLYIFRUNNING = 16,
}


[AllowDuplicates]
public enum OLEVERBATTRIB : int32
{
	OLEVERBATTRIB_NEVERDIRTIES = 1,
	OLEVERBATTRIB_ONCONTAINERMENU = 2,
}


[AllowDuplicates]
public enum REGKIND : int32
{
	REGKIND_DEFAULT = 0,
	REGKIND_REGISTER = 1,
	REGKIND_NONE = 2,
}


[AllowDuplicates]
public enum UASFLAGS : int32
{
	UAS_NORMAL = 0,
	UAS_BLOCKED = 1,
	UAS_NOPARENTENABLE = 2,
	UAS_MASK = 3,
}


[AllowDuplicates]
public enum READYSTATE : int32
{
	READYSTATE_UNINITIALIZED = 0,
	READYSTATE_LOADING = 1,
	READYSTATE_LOADED = 2,
	READYSTATE_INTERACTIVE = 3,
	READYSTATE_COMPLETE = 4,
}


[AllowDuplicates]
public enum GUIDKIND : int32
{
	GUIDKIND_DEFAULT_SOURCE_DISP_IID = 1,
}


[AllowDuplicates]
public enum CTRLINFO : int32
{
	CTRLINFO_EATS_RETURN = 1,
	CTRLINFO_EATS_ESCAPE = 2,
}


[AllowDuplicates]
public enum XFORMCOORDS : int32
{
	XFORMCOORDS_POSITION = 1,
	XFORMCOORDS_SIZE = 2,
	XFORMCOORDS_HIMETRICTOCONTAINER = 4,
	XFORMCOORDS_CONTAINERTOHIMETRIC = 8,
	XFORMCOORDS_EVENTCOMPAT = 16,
}


[AllowDuplicates]
public enum PROPPAGESTATUS : int32
{
	PROPPAGESTATUS_DIRTY = 1,
	PROPPAGESTATUS_VALIDATE = 2,
	PROPPAGESTATUS_CLEAN = 4,
}


[AllowDuplicates]
public enum PICTUREATTRIBUTES : int32
{
	PICTURE_SCALABLE = 1,
	PICTURE_TRANSPARENT = 2,
}


[AllowDuplicates]
public enum ACTIVATEFLAGS : int32
{
	ACTIVATE_WINDOWLESS = 1,
}


[AllowDuplicates]
public enum OLEDCFLAGS : int32
{
	OLEDC_NODRAW = 1,
	OLEDC_PAINTBKGND = 2,
	OLEDC_OFFSCREEN = 4,
}


[AllowDuplicates]
public enum VIEWSTATUS : int32
{
	VIEWSTATUS_OPAQUE = 1,
	VIEWSTATUS_SOLIDBKGND = 2,
	VIEWSTATUS_DVASPECTOPAQUE = 4,
	VIEWSTATUS_DVASPECTTRANSPARENT = 8,
	VIEWSTATUS_SURFACE = 16,
	VIEWSTATUS_3DSURFACE = 32,
}


[AllowDuplicates]
public enum HITRESULT : int32
{
	HITRESULT_OUTSIDE = 0,
	HITRESULT_TRANSPARENT = 1,
	HITRESULT_CLOSE = 2,
	HITRESULT_HIT = 3,
}


[AllowDuplicates]
public enum DVEXTENTMODE : int32
{
	DVEXTENT_CONTENT = 0,
	DVEXTENT_INTEGRAL = 1,
}


[AllowDuplicates]
public enum DVASPECTINFOFLAG : int32
{
	DVASPECTINFOFLAG_CANOPTIMIZE = 1,
}


[AllowDuplicates]
public enum POINTERINACTIVE : int32
{
	POINTERINACTIVE_ACTIVATEONENTRY = 1,
	POINTERINACTIVE_DEACTIVATEONLEAVE = 2,
	POINTERINACTIVE_ACTIVATEONDRAG = 4,
}


[AllowDuplicates]
public enum PROPBAG2_TYPE : int32
{
	PROPBAG2_TYPE_UNDEFINED = 0,
	PROPBAG2_TYPE_DATA = 1,
	PROPBAG2_TYPE_URL = 2,
	PROPBAG2_TYPE_OBJECT = 3,
	PROPBAG2_TYPE_STREAM = 4,
	PROPBAG2_TYPE_STORAGE = 5,
	PROPBAG2_TYPE_MONIKER = 6,
}


[AllowDuplicates]
public enum QACONTAINERFLAGS : int32
{
	QACONTAINER_SHOWHATCHING = 1,
	QACONTAINER_SHOWGRABHANDLES = 2,
	QACONTAINER_USERMODE = 4,
	QACONTAINER_DISPLAYASDEFAULT = 8,
	QACONTAINER_UIDEAD = 16,
	QACONTAINER_AUTOCLIP = 32,
	QACONTAINER_MESSAGEREFLECT = 64,
	QACONTAINER_SUPPORTSMNEMONICS = 128,
}


[AllowDuplicates]
public enum OLE_TRISTATE : int32
{
	triUnchecked = 0,
	triChecked = 1,
	triGray = 2,
}


[AllowDuplicates]
public enum DOCMISC : int32
{
	DOCMISC_CANCREATEMULTIPLEVIEWS = 1,
	DOCMISC_SUPPORTCOMPLEXRECTANGLES = 2,
	DOCMISC_CANTOPENEDIT = 4,
	DOCMISC_NOFILESUPPORT = 8,
}


[AllowDuplicates]
public enum PRINTFLAG : uint32
{
	PRINTFLAG_MAYBOTHERUSER = 1,
	PRINTFLAG_PROMPTUSER = 2,
	PRINTFLAG_USERMAYCHANGEPRINTER = 4,
	PRINTFLAG_RECOMPOSETODEVICE = 8,
	PRINTFLAG_DONTACTUALLYPRINT = 16,
	PRINTFLAG_FORCEPROPERTIES = 32,
	PRINTFLAG_PRINTTOFILE = 64,
}


[AllowDuplicates]
public enum OLECMDF : int32
{
	OLECMDF_SUPPORTED = 1,
	OLECMDF_ENABLED = 2,
	OLECMDF_LATCHED = 4,
	OLECMDF_NINCHED = 8,
	OLECMDF_INVISIBLE = 16,
	OLECMDF_DEFHIDEONCTXTMENU = 32,
}


[AllowDuplicates]
public enum OLECMDTEXTF : int32
{
	OLECMDTEXTF_NONE = 0,
	OLECMDTEXTF_NAME = 1,
	OLECMDTEXTF_STATUS = 2,
}


[AllowDuplicates]
public enum OLECMDEXECOPT : int32
{
	OLECMDEXECOPT_DODEFAULT = 0,
	OLECMDEXECOPT_PROMPTUSER = 1,
	OLECMDEXECOPT_DONTPROMPTUSER = 2,
	OLECMDEXECOPT_SHOWHELP = 3,
}


[AllowDuplicates]
public enum OLECMDID : int32
{
	OLECMDID_OPEN = 1,
	OLECMDID_NEW = 2,
	OLECMDID_SAVE = 3,
	OLECMDID_SAVEAS = 4,
	OLECMDID_SAVECOPYAS = 5,
	OLECMDID_PRINT = 6,
	OLECMDID_PRINTPREVIEW = 7,
	OLECMDID_PAGESETUP = 8,
	OLECMDID_SPELL = 9,
	OLECMDID_PROPERTIES = 10,
	OLECMDID_CUT = 11,
	OLECMDID_COPY = 12,
	OLECMDID_PASTE = 13,
	OLECMDID_PASTESPECIAL = 14,
	OLECMDID_UNDO = 15,
	OLECMDID_REDO = 16,
	OLECMDID_SELECTALL = 17,
	OLECMDID_CLEARSELECTION = 18,
	OLECMDID_ZOOM = 19,
	OLECMDID_GETZOOMRANGE = 20,
	OLECMDID_UPDATECOMMANDS = 21,
	OLECMDID_REFRESH = 22,
	OLECMDID_STOP = 23,
	OLECMDID_HIDETOOLBARS = 24,
	OLECMDID_SETPROGRESSMAX = 25,
	OLECMDID_SETPROGRESSPOS = 26,
	OLECMDID_SETPROGRESSTEXT = 27,
	OLECMDID_SETTITLE = 28,
	OLECMDID_SETDOWNLOADSTATE = 29,
	OLECMDID_STOPDOWNLOAD = 30,
	OLECMDID_ONTOOLBARACTIVATED = 31,
	OLECMDID_FIND = 32,
	OLECMDID_DELETE = 33,
	OLECMDID_HTTPEQUIV = 34,
	OLECMDID_HTTPEQUIV_DONE = 35,
	OLECMDID_ENABLE_INTERACTION = 36,
	OLECMDID_ONUNLOAD = 37,
	OLECMDID_PROPERTYBAG2 = 38,
	OLECMDID_PREREFRESH = 39,
	OLECMDID_SHOWSCRIPTERROR = 40,
	OLECMDID_SHOWMESSAGE = 41,
	OLECMDID_SHOWFIND = 42,
	OLECMDID_SHOWPAGESETUP = 43,
	OLECMDID_SHOWPRINT = 44,
	OLECMDID_CLOSE = 45,
	OLECMDID_ALLOWUILESSSAVEAS = 46,
	OLECMDID_DONTDOWNLOADCSS = 47,
	OLECMDID_UPDATEPAGESTATUS = 48,
	OLECMDID_PRINT2 = 49,
	OLECMDID_PRINTPREVIEW2 = 50,
	OLECMDID_SETPRINTTEMPLATE = 51,
	OLECMDID_GETPRINTTEMPLATE = 52,
	OLECMDID_PAGEACTIONBLOCKED = 55,
	OLECMDID_PAGEACTIONUIQUERY = 56,
	OLECMDID_FOCUSVIEWCONTROLS = 57,
	OLECMDID_FOCUSVIEWCONTROLSQUERY = 58,
	OLECMDID_SHOWPAGEACTIONMENU = 59,
	OLECMDID_ADDTRAVELENTRY = 60,
	OLECMDID_UPDATETRAVELENTRY = 61,
	OLECMDID_UPDATEBACKFORWARDSTATE = 62,
	OLECMDID_OPTICAL_ZOOM = 63,
	OLECMDID_OPTICAL_GETZOOMRANGE = 64,
	OLECMDID_WINDOWSTATECHANGED = 65,
	OLECMDID_ACTIVEXINSTALLSCOPE = 66,
	OLECMDID_UPDATETRAVELENTRY_DATARECOVERY = 67,
	OLECMDID_SHOWTASKDLG = 68,
	OLECMDID_POPSTATEEVENT = 69,
	OLECMDID_VIEWPORT_MODE = 70,
	OLECMDID_LAYOUT_VIEWPORT_WIDTH = 71,
	OLECMDID_VISUAL_VIEWPORT_EXCLUDE_BOTTOM = 72,
	OLECMDID_USER_OPTICAL_ZOOM = 73,
	OLECMDID_PAGEAVAILABLE = 74,
	OLECMDID_GETUSERSCALABLE = 75,
	OLECMDID_UPDATE_CARET = 76,
	OLECMDID_ENABLE_VISIBILITY = 77,
	OLECMDID_MEDIA_PLAYBACK = 78,
	OLECMDID_SETFAVICON = 79,
	OLECMDID_SET_HOST_FULLSCREENMODE = 80,
	OLECMDID_EXITFULLSCREEN = 81,
	OLECMDID_SCROLLCOMPLETE = 82,
	OLECMDID_ONBEFOREUNLOAD = 83,
	OLECMDID_SHOWMESSAGE_BLOCKABLE = 84,
	OLECMDID_SHOWTASKDLG_BLOCKABLE = 85,
}


[AllowDuplicates]
public enum MEDIAPLAYBACK_STATE : int32
{
	MEDIAPLAYBACK_RESUME = 0,
	MEDIAPLAYBACK_PAUSE = 1,
	MEDIAPLAYBACK_PAUSE_AND_SUSPEND = 2,
	MEDIAPLAYBACK_RESUME_FROM_SUSPEND = 3,
}


[AllowDuplicates]
public enum IGNOREMIME : int32
{
	IGNOREMIME_PROMPT = 1,
	IGNOREMIME_TEXT = 2,
}


[AllowDuplicates]
public enum WPCSETTING : int32
{
	WPCSETTING_LOGGING_ENABLED = 1,
	WPCSETTING_FILEDOWNLOAD_BLOCKED = 2,
}


[AllowDuplicates]
public enum OLECMDID_REFRESHFLAG : int32
{
	OLECMDIDF_REFRESH_NORMAL = 0,
	OLECMDIDF_REFRESH_IFEXPIRED = 1,
	OLECMDIDF_REFRESH_CONTINUE = 2,
	OLECMDIDF_REFRESH_COMPLETELY = 3,
	OLECMDIDF_REFRESH_NO_CACHE = 4,
	OLECMDIDF_REFRESH_RELOAD = 5,
	OLECMDIDF_REFRESH_LEVELMASK = 255,
	OLECMDIDF_REFRESH_CLEARUSERINPUT = 4096,
	OLECMDIDF_REFRESH_PROMPTIFOFFLINE = 8192,
	OLECMDIDF_REFRESH_THROUGHSCRIPT = 16384,
	OLECMDIDF_REFRESH_SKIPBEFOREUNLOADEVENT = 32768,
	OLECMDIDF_REFRESH_PAGEACTION_ACTIVEXINSTALL = 65536,
	OLECMDIDF_REFRESH_PAGEACTION_FILEDOWNLOAD = 131072,
	OLECMDIDF_REFRESH_PAGEACTION_LOCALMACHINE = 262144,
	OLECMDIDF_REFRESH_PAGEACTION_POPUPWINDOW = 524288,
	OLECMDIDF_REFRESH_PAGEACTION_PROTLOCKDOWNLOCALMACHINE = 1048576,
	OLECMDIDF_REFRESH_PAGEACTION_PROTLOCKDOWNTRUSTED = 2097152,
	OLECMDIDF_REFRESH_PAGEACTION_PROTLOCKDOWNINTRANET = 4194304,
	OLECMDIDF_REFRESH_PAGEACTION_PROTLOCKDOWNINTERNET = 8388608,
	OLECMDIDF_REFRESH_PAGEACTION_PROTLOCKDOWNRESTRICTED = 16777216,
	OLECMDIDF_REFRESH_PAGEACTION_MIXEDCONTENT = 33554432,
	OLECMDIDF_REFRESH_PAGEACTION_INVALID_CERT = 67108864,
	OLECMDIDF_REFRESH_PAGEACTION_ALLOW_VERSION = 134217728,
}


[AllowDuplicates]
public enum OLECMDID_PAGEACTIONFLAG : int32
{
	OLECMDIDF_PAGEACTION_FILEDOWNLOAD = 1,
	OLECMDIDF_PAGEACTION_ACTIVEXINSTALL = 2,
	OLECMDIDF_PAGEACTION_ACTIVEXTRUSTFAIL = 4,
	OLECMDIDF_PAGEACTION_ACTIVEXUSERDISABLE = 8,
	OLECMDIDF_PAGEACTION_ACTIVEXDISALLOW = 16,
	OLECMDIDF_PAGEACTION_ACTIVEXUNSAFE = 32,
	OLECMDIDF_PAGEACTION_POPUPWINDOW = 64,
	OLECMDIDF_PAGEACTION_LOCALMACHINE = 128,
	OLECMDIDF_PAGEACTION_MIMETEXTPLAIN = 256,
	OLECMDIDF_PAGEACTION_SCRIPTNAVIGATE = 512,
	OLECMDIDF_PAGEACTION_SCRIPTNAVIGATE_ACTIVEXINSTALL = 512,
	OLECMDIDF_PAGEACTION_PROTLOCKDOWNLOCALMACHINE = 1024,
	OLECMDIDF_PAGEACTION_PROTLOCKDOWNTRUSTED = 2048,
	OLECMDIDF_PAGEACTION_PROTLOCKDOWNINTRANET = 4096,
	OLECMDIDF_PAGEACTION_PROTLOCKDOWNINTERNET = 8192,
	OLECMDIDF_PAGEACTION_PROTLOCKDOWNRESTRICTED = 16384,
	OLECMDIDF_PAGEACTION_PROTLOCKDOWNDENY = 32768,
	OLECMDIDF_PAGEACTION_POPUPALLOWED = 65536,
	OLECMDIDF_PAGEACTION_SCRIPTPROMPT = 131072,
	OLECMDIDF_PAGEACTION_ACTIVEXUSERAPPROVAL = 262144,
	OLECMDIDF_PAGEACTION_MIXEDCONTENT = 524288,
	OLECMDIDF_PAGEACTION_INVALID_CERT = 1048576,
	OLECMDIDF_PAGEACTION_INTRANETZONEREQUEST = 2097152,
	OLECMDIDF_PAGEACTION_XSSFILTERED = 4194304,
	OLECMDIDF_PAGEACTION_SPOOFABLEIDNHOST = 8388608,
	OLECMDIDF_PAGEACTION_ACTIVEX_EPM_INCOMPATIBLE = 16777216,
	OLECMDIDF_PAGEACTION_SCRIPTNAVIGATE_ACTIVEXUSERAPPROVAL = 33554432,
	OLECMDIDF_PAGEACTION_WPCBLOCKED = 67108864,
	OLECMDIDF_PAGEACTION_WPCBLOCKED_ACTIVEX = 134217728,
	OLECMDIDF_PAGEACTION_EXTENSION_COMPAT_BLOCKED = 268435456,
	OLECMDIDF_PAGEACTION_NORESETACTIVEX = 536870912,
	OLECMDIDF_PAGEACTION_GENERIC_STATE = 1073741824,
	OLECMDIDF_PAGEACTION_RESET = -2147483648,
}


[AllowDuplicates]
public enum OLECMDID_BROWSERSTATEFLAG : int32
{
	OLECMDIDF_BROWSERSTATE_EXTENSIONSOFF = 1,
	OLECMDIDF_BROWSERSTATE_IESECURITY = 2,
	OLECMDIDF_BROWSERSTATE_PROTECTEDMODE_OFF = 4,
	OLECMDIDF_BROWSERSTATE_RESET = 8,
	OLECMDIDF_BROWSERSTATE_REQUIRESACTIVEX = 16,
	OLECMDIDF_BROWSERSTATE_DESKTOPHTMLDIALOG = 32,
	OLECMDIDF_BROWSERSTATE_BLOCKEDVERSION = 64,
}


[AllowDuplicates]
public enum OLECMDID_OPTICAL_ZOOMFLAG : int32
{
	OLECMDIDF_OPTICAL_ZOOM_NOPERSIST = 1,
	OLECMDIDF_OPTICAL_ZOOM_NOLAYOUT = 16,
	OLECMDIDF_OPTICAL_ZOOM_NOTRANSIENT = 32,
	OLECMDIDF_OPTICAL_ZOOM_RELOADFORNEWTAB = 64,
}


[AllowDuplicates]
public enum PAGEACTION_UI : int32
{
	PAGEACTION_UI_DEFAULT = 0,
	PAGEACTION_UI_MODAL = 1,
	PAGEACTION_UI_MODELESS = 2,
	PAGEACTION_UI_SILENT = 3,
}


[AllowDuplicates]
public enum OLECMDID_WINDOWSTATE_FLAG : int32
{
	OLECMDIDF_WINDOWSTATE_USERVISIBLE = 1,
	OLECMDIDF_WINDOWSTATE_ENABLED = 2,
	OLECMDIDF_WINDOWSTATE_USERVISIBLE_VALID = 65536,
	OLECMDIDF_WINDOWSTATE_ENABLED_VALID = 131072,
}


[AllowDuplicates]
public enum OLECMDID_VIEWPORT_MODE_FLAG : int32
{
	OLECMDIDF_VIEWPORTMODE_FIXED_LAYOUT_WIDTH = 1,
	OLECMDIDF_VIEWPORTMODE_EXCLUDE_VISUAL_BOTTOM = 2,
	OLECMDIDF_VIEWPORTMODE_FIXED_LAYOUT_WIDTH_VALID = 65536,
	OLECMDIDF_VIEWPORTMODE_EXCLUDE_VISUAL_BOTTOM_VALID = 131072,
}


[AllowDuplicates]
public enum OLEUIPASTEFLAG : int32
{
	OLEUIPASTE_ENABLEICON = 2048,
	OLEUIPASTE_PASTEONLY = 0,
	OLEUIPASTE_PASTE = 512,
	OLEUIPASTE_LINKANYTYPE = 1024,
	OLEUIPASTE_LINKTYPE1 = 1,
	OLEUIPASTE_LINKTYPE2 = 2,
	OLEUIPASTE_LINKTYPE3 = 4,
	OLEUIPASTE_LINKTYPE4 = 8,
	OLEUIPASTE_LINKTYPE5 = 16,
	OLEUIPASTE_LINKTYPE6 = 32,
	OLEUIPASTE_LINKTYPE7 = 64,
	OLEUIPASTE_LINKTYPE8 = 128,
}

#endregion

#region Function Pointers
public function uint32 LPFNOLEUIHOOK(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

#endregion

#region Structs
[CRepr]
public struct SAFEARR_BSTR
{
	public uint32 Size;
	public FLAGGED_WORD_BLOB** aBstr;
}

[CRepr]
public struct SAFEARR_UNKNOWN
{
	public uint32 Size;
	public IUnknown** apUnknown;
}

[CRepr]
public struct SAFEARR_DISPATCH
{
	public uint32 Size;
	public IDispatch** apDispatch;
}

[CRepr]
public struct SAFEARR_VARIANT
{
	public uint32 Size;
	public _wireVARIANT** aVariant;
}

[CRepr]
public struct SAFEARR_BRECORD
{
	public uint32 Size;
	public _wireBRECORD** aRecord;
}

[CRepr]
public struct SAFEARR_HAVEIID
{
	public uint32 Size;
	public IUnknown** apUnknown;
	public Guid iid;
}

[CRepr]
public struct SAFEARRAYUNION
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public SAFEARR_BSTR BstrStr;
		public SAFEARR_UNKNOWN UnknownStr;
		public SAFEARR_DISPATCH DispatchStr;
		public SAFEARR_VARIANT VariantStr;
		public SAFEARR_BRECORD RecordStr;
		public SAFEARR_HAVEIID HaveIidStr;
		public BYTE_SIZEDARR ByteStr;
		public WORD_SIZEDARR WordStr;
		public DWORD_SIZEDARR LongStr;
		public HYPER_SIZEDARR HyperStr;
	}
	public uint32 sfType;
	public _u_e__Struct u;
}

[CRepr]
public struct _wireSAFEARRAY
{
	public uint16 cDims;
	public uint16 fFeatures;
	public uint32 cbElements;
	public uint32 cLocks;
	public SAFEARRAYUNION uArrayStructs;
	public SAFEARRAYBOUND* rgsabound mut => &rgsabound_impl;
	private SAFEARRAYBOUND[ANYSIZE_ARRAY] rgsabound_impl;
}

[CRepr]
public struct _wireBRECORD
{
	public uint32 fFlags;
	public uint32 clSize;
	public IRecordInfo* pRecInfo;
	public uint8* pRecord;
}

[CRepr]
public struct _wireVARIANT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int64 llVal;
		public int32 lVal;
		public uint8 bVal;
		public int16 iVal;
		public float fltVal;
		public double dblVal;
		public int16 boolVal;
		public int32 scode;
		public CY cyVal;
		public double date;
		public FLAGGED_WORD_BLOB* bstrVal;
		public IUnknown* punkVal;
		public IDispatch* pdispVal;
		public _wireSAFEARRAY** parray;
		public _wireBRECORD* brecVal;
		public uint8* pbVal;
		public int16* piVal;
		public int32* plVal;
		public int64* pllVal;
		public float* pfltVal;
		public double* pdblVal;
		public int16* pboolVal;
		public int32* pscode;
		public CY* pcyVal;
		public double* pdate;
		public FLAGGED_WORD_BLOB** pbstrVal;
		public IUnknown** ppunkVal;
		public IDispatch** ppdispVal;
		public _wireSAFEARRAY*** pparray;
		public _wireVARIANT** pvarVal;
		public CHAR cVal;
		public uint16 uiVal;
		public uint32 ulVal;
		public uint64 ullVal;
		public int32 intVal;
		public uint32 uintVal;
		public DECIMAL decVal;
		public DECIMAL* pdecVal;
		public PSTR pcVal;
		public uint16* puiVal;
		public uint32* pulVal;
		public uint64* pullVal;
		public int32* pintVal;
		public uint32* puintVal;
	}
	public uint32 clSize;
	public uint32 rpcReserved;
	public uint16 vt;
	public uint16 wReserved1;
	public uint16 wReserved2;
	public uint16 wReserved3;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct ARRAYDESC
{
	public TYPEDESC tdescElem;
	public uint16 cDims;
	public SAFEARRAYBOUND* rgbounds mut => &rgbounds_impl;
	private SAFEARRAYBOUND[ANYSIZE_ARRAY] rgbounds_impl;
}

[CRepr]
public struct PARAMDESCEX
{
	public uint32 cBytes;
	public VARIANT varDefaultValue;
}

[CRepr]
public struct PARAMDESC
{
	public PARAMDESCEX* pparamdescex;
	public PARAMFLAGS wParamFlags;
}

[CRepr]
public struct CLEANLOCALSTORAGE
{
	public IUnknown* pInterface;
	public void* pStorage;
	public uint32 flags;
}

[CRepr]
public struct OBJECTDESCRIPTOR
{
	public uint32 cbSize;
	public Guid clsid;
	public uint32 dwDrawAspect;
	public SIZE sizel;
	public POINTL pointl;
	public uint32 dwStatus;
	public uint32 dwFullUserTypeName;
	public uint32 dwSrcOfCopy;
}

[CRepr]
public struct OLEINPLACEFRAMEINFO
{
	public uint32 cb;
	public BOOL fMDIApp;
	public HWND hwndFrame;
	public HACCEL haccel;
	public uint32 cAccelEntries;
}

[CRepr]
public struct OLEMENUGROUPWIDTHS
{
	public int32[6] width;
}

[CRepr]
public struct OLEVERB
{
	public int32 lVerb;
	public PWSTR lpszVerbName;
	public MENU_ITEM_FLAGS fuFlags;
	public OLEVERBATTRIB grfAttribs;
}

[CRepr]
public struct NUMPARSE
{
	public int32 cDig;
	public NUMPARSE_FLAGS dwInFlags;
	public NUMPARSE_FLAGS dwOutFlags;
	public int32 cchUsed;
	public int32 nBaseShift;
	public int32 nPwr10;
}

[CRepr]
public struct UDATE
{
	public SYSTEMTIME st;
	public uint16 wDayOfYear;
}

[CRepr]
public struct PARAMDATA
{
	public PWSTR szName;
	public VARENUM vt;
}

[CRepr]
public struct METHODDATA
{
	public PWSTR szName;
	public PARAMDATA* ppdata;
	public int32 dispid;
	public uint32 iMeth;
	public CALLCONV cc;
	public uint32 cArgs;
	public uint16 wFlags;
	public VARENUM vtReturn;
}

[CRepr]
public struct INTERFACEDATA
{
	public METHODDATA* pmethdata;
	public uint32 cMembers;
}

[CRepr]
public struct LICINFO
{
	public int32 cbLicInfo;
	public BOOL fRuntimeKeyAvail;
	public BOOL fLicVerified;
}

[CRepr]
public struct CONTROLINFO
{
	public uint32 cb;
	public HACCEL hAccel;
	public uint16 cAccel;
	public CTRLINFO dwFlags;
}

[CRepr]
public struct POINTF
{
	public float x;
	public float y;
}

[CRepr]
public struct PROPPAGEINFO
{
	public uint32 cb;
	public PWSTR pszTitle;
	public SIZE size;
	public PWSTR pszDocString;
	public PWSTR pszHelpFile;
	public uint32 dwHelpContext;
}

[CRepr]
public struct CAUUID
{
	public uint32 cElems;
	public Guid* pElems;
}

[CRepr]
public struct DVEXTENTINFO
{
	public uint32 cb;
	public uint32 dwExtentMode;
	public SIZE sizelProposed;
}

[CRepr]
public struct DVASPECTINFO
{
	public uint32 cb;
	public uint32 dwFlags;
}

[CRepr]
public struct CALPOLESTR
{
	public uint32 cElems;
	public PWSTR* pElems;
}

[CRepr]
public struct CADWORD
{
	public uint32 cElems;
	public uint32* pElems;
}

[CRepr]
public struct QACONTAINER
{
	public uint32 cbSize;
	public IOleClientSite* pClientSite;
	public IAdviseSinkEx* pAdviseSink;
	public IPropertyNotifySink* pPropertyNotifySink;
	public IUnknown* pUnkEventSink;
	public QACONTAINERFLAGS dwAmbientFlags;
	public uint32 colorFore;
	public uint32 colorBack;
	public IFont* pFont;
	public IOleUndoManager* pUndoMgr;
	public uint32 dwAppearance;
	public int32 lcid;
	public HPALETTE hpal;
	public IBindHost* pBindHost;
	public IOleControlSite* pOleControlSite;
	public IServiceProvider* pServiceProvider;
}

[CRepr]
public struct QACONTROL
{
	public uint32 cbSize;
	public OLEMISC dwMiscStatus;
	public VIEWSTATUS dwViewStatus;
	public uint32 dwEventCookie;
	public uint32 dwPropNotifyCookie;
	public POINTERINACTIVE dwPointerActivationPolicy;
}

[CRepr]
public struct OCPFIPARAMS
{
	public uint32 cbStructSize;
	public HWND hWndOwner;
	public int32 x;
	public int32 y;
	public PWSTR lpszCaption;
	public uint32 cObjects;
	public IUnknown** lplpUnk;
	public uint32 cPages;
	public Guid* lpPages;
	public uint32 lcid;
	public int32 dispidInitialProperty;
}

[CRepr]
public struct FONTDESC
{
	public uint32 cbSizeofstruct;
	public PWSTR lpstrName;
	public CY cySize;
	public int16 sWeight;
	public int16 sCharset;
	public BOOL fItalic;
	public BOOL fUnderline;
	public BOOL fStrikethrough;
}

[CRepr]
public struct PICTDESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _icon_e__Struct
		{
			public HICON hicon;
		}
		[CRepr]
		public struct _bmp_e__Struct
		{
			public HBITMAP hbitmap;
			public HPALETTE hpal;
		}
		[CRepr]
		public struct _wmf_e__Struct
		{
			public HMETAFILE hmeta;
			public int32 xExt;
			public int32 yExt;
		}
		[CRepr]
		public struct _emf_e__Struct
		{
			public HENHMETAFILE hemf;
		}
		public _bmp_e__Struct bmp;
		public _wmf_e__Struct wmf;
		public _icon_e__Struct icon;
		public _emf_e__Struct emf;
	}
	public uint32 cbSizeofstruct;
	public PICTYPE picType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PAGERANGE
{
	public int32 nFromPage;
	public int32 nToPage;
}

[CRepr]
public struct PAGESET
{
	public uint32 cbStruct;
	public BOOL fOddPages;
	public BOOL fEvenPages;
	public uint32 cPageRange;
	public PAGERANGE* rgPages mut => &rgPages_impl;
	private PAGERANGE[ANYSIZE_ARRAY] rgPages_impl;
}

[CRepr]
public struct OLECMD
{
	public OLECMDID cmdID;
	public OLECMDF cmdf;
}

[CRepr]
public struct OLECMDTEXT
{
	public uint32 cmdtextf;
	public uint32 cwActual;
	public uint32 cwBuf;
	public char16* rgwz mut => &rgwz_impl;
	private char16[ANYSIZE_ARRAY] rgwz_impl;
}

[CRepr]
public struct OLEUIINSERTOBJECTW
{
	public uint32 cbStruct;
	public INSERT_OBJECT_FLAGS dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public Guid clsid;
	public PWSTR lpszFile;
	public uint32 cchFile;
	public uint32 cClsidExclude;
	public Guid* lpClsidExclude;
	public Guid iid;
	public uint32 oleRender;
	public FORMATETC* lpFormatEtc;
	public IOleClientSite* lpIOleClientSite;
	public IStorage* lpIStorage;
	public void** ppvObj;
	public int32 sc;
	public int hMetaPict;
}

[CRepr]
public struct OLEUIINSERTOBJECTA
{
	public uint32 cbStruct;
	public INSERT_OBJECT_FLAGS dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public Guid clsid;
	public PSTR lpszFile;
	public uint32 cchFile;
	public uint32 cClsidExclude;
	public Guid* lpClsidExclude;
	public Guid iid;
	public uint32 oleRender;
	public FORMATETC* lpFormatEtc;
	public IOleClientSite* lpIOleClientSite;
	public IStorage* lpIStorage;
	public void** ppvObj;
	public int32 sc;
	public int hMetaPict;
}

[CRepr]
public struct OLEUIPASTEENTRYW
{
	public FORMATETC fmtetc;
	public PWSTR lpstrFormatName;
	public PWSTR lpstrResultText;
	public uint32 dwFlags;
	public uint32 dwScratchSpace;
}

[CRepr]
public struct OLEUIPASTEENTRYA
{
	public FORMATETC fmtetc;
	public PSTR lpstrFormatName;
	public PSTR lpstrResultText;
	public uint32 dwFlags;
	public uint32 dwScratchSpace;
}

[CRepr]
public struct OLEUIPASTESPECIALW
{
	public uint32 cbStruct;
	public PASTE_SPECIAL_FLAGS dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public IDataObject* lpSrcDataObj;
	public OLEUIPASTEENTRYW* arrPasteEntries;
	public int32 cPasteEntries;
	public uint32* arrLinkTypes;
	public int32 cLinkTypes;
	public uint32 cClsidExclude;
	public Guid* lpClsidExclude;
	public int32 nSelectedIndex;
	public BOOL fLink;
	public int hMetaPict;
	public SIZE sizel;
}

[CRepr]
public struct OLEUIPASTESPECIALA
{
	public uint32 cbStruct;
	public PASTE_SPECIAL_FLAGS dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public IDataObject* lpSrcDataObj;
	public OLEUIPASTEENTRYA* arrPasteEntries;
	public int32 cPasteEntries;
	public uint32* arrLinkTypes;
	public int32 cLinkTypes;
	public uint32 cClsidExclude;
	public Guid* lpClsidExclude;
	public int32 nSelectedIndex;
	public BOOL fLink;
	public int hMetaPict;
	public SIZE sizel;
}

[CRepr]
public struct OLEUIEDITLINKSW
{
	public uint32 cbStruct;
	public EDIT_LINKS_FLAGS dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public IOleUILinkContainerW* lpOleUILinkContainer;
}

[CRepr]
public struct OLEUIEDITLINKSA
{
	public uint32 cbStruct;
	public EDIT_LINKS_FLAGS dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public IOleUILinkContainerA* lpOleUILinkContainer;
}

[CRepr]
public struct OLEUICHANGEICONW
{
	public uint32 cbStruct;
	public CHANGE_ICON_FLAGS dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public int hMetaPict;
	public Guid clsid;
	public char16[260] szIconExe;
	public int32 cchIconExe;
}

[CRepr]
public struct OLEUICHANGEICONA
{
	public uint32 cbStruct;
	public CHANGE_ICON_FLAGS dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public int hMetaPict;
	public Guid clsid;
	public CHAR[260] szIconExe;
	public int32 cchIconExe;
}

[CRepr]
public struct OLEUICONVERTW
{
	public uint32 cbStruct;
	public UI_CONVERT_FLAGS dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public Guid clsid;
	public Guid clsidConvertDefault;
	public Guid clsidActivateDefault;
	public Guid clsidNew;
	public uint32 dvAspect;
	public uint16 wFormat;
	public BOOL fIsLinkedObject;
	public int hMetaPict;
	public PWSTR lpszUserType;
	public BOOL fObjectsIconChanged;
	public PWSTR lpszDefLabel;
	public uint32 cClsidExclude;
	public Guid* lpClsidExclude;
}

[CRepr]
public struct OLEUICONVERTA
{
	public uint32 cbStruct;
	public UI_CONVERT_FLAGS dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public Guid clsid;
	public Guid clsidConvertDefault;
	public Guid clsidActivateDefault;
	public Guid clsidNew;
	public uint32 dvAspect;
	public uint16 wFormat;
	public BOOL fIsLinkedObject;
	public int hMetaPict;
	public PSTR lpszUserType;
	public BOOL fObjectsIconChanged;
	public PSTR lpszDefLabel;
	public uint32 cClsidExclude;
	public Guid* lpClsidExclude;
}

[CRepr]
public struct OLEUIBUSYW
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public HTASK hTask;
	public HWND* lphWndDialog;
}

[CRepr]
public struct OLEUIBUSYA
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public HTASK hTask;
	public HWND* lphWndDialog;
}

[CRepr]
public struct OLEUICHANGESOURCEW
{
	public uint32 cbStruct;
	public CHANGE_SOURCE_FLAGS dwFlags;
	public HWND hWndOwner;
	public PWSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PWSTR lpszTemplate;
	public HRSRC hResource;
	public OPENFILENAMEW* lpOFN;
	public uint32[4] dwReserved1;
	public IOleUILinkContainerW* lpOleUILinkContainer;
	public uint32 dwLink;
	public PWSTR lpszDisplayName;
	public uint32 nFileLength;
	public PWSTR lpszFrom;
	public PWSTR lpszTo;
}

[CRepr]
public struct OLEUICHANGESOURCEA
{
	public uint32 cbStruct;
	public CHANGE_SOURCE_FLAGS dwFlags;
	public HWND hWndOwner;
	public PSTR lpszCaption;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public HINSTANCE hInstance;
	public PSTR lpszTemplate;
	public HRSRC hResource;
	public OPENFILENAMEA* lpOFN;
	public uint32[4] dwReserved1;
	public IOleUILinkContainerA* lpOleUILinkContainer;
	public uint32 dwLink;
	public PSTR lpszDisplayName;
	public uint32 nFileLength;
	public PSTR lpszFrom;
	public PSTR lpszTo;
}

[CRepr]
public struct OLEUIGNRLPROPSW
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public uint32[2] dwReserved1;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public uint32[3] dwReserved2;
	public OLEUIOBJECTPROPSW* lpOP;
}

[CRepr]
public struct OLEUIGNRLPROPSA
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public uint32[2] dwReserved1;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public uint32[3] dwReserved2;
	public OLEUIOBJECTPROPSA* lpOP;
}

[CRepr]
public struct OLEUIVIEWPROPSW
{
	public uint32 cbStruct;
	public VIEW_OBJECT_PROPERTIES_FLAGS dwFlags;
	public uint32[2] dwReserved1;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public uint32[3] dwReserved2;
	public OLEUIOBJECTPROPSW* lpOP;
	public int32 nScaleMin;
	public int32 nScaleMax;
}

[CRepr]
public struct OLEUIVIEWPROPSA
{
	public uint32 cbStruct;
	public VIEW_OBJECT_PROPERTIES_FLAGS dwFlags;
	public uint32[2] dwReserved1;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public uint32[3] dwReserved2;
	public OLEUIOBJECTPROPSA* lpOP;
	public int32 nScaleMin;
	public int32 nScaleMax;
}

[CRepr]
public struct OLEUILINKPROPSW
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public uint32[2] dwReserved1;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public uint32[3] dwReserved2;
	public OLEUIOBJECTPROPSW* lpOP;
}

[CRepr]
public struct OLEUILINKPROPSA
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public uint32[2] dwReserved1;
	public LPFNOLEUIHOOK lpfnHook;
	public LPARAM lCustData;
	public uint32[3] dwReserved2;
	public OLEUIOBJECTPROPSA* lpOP;
}

[CRepr]
public struct OLEUIOBJECTPROPSW
{
	public uint32 cbStruct;
	public OBJECT_PROPERTIES_FLAGS dwFlags;
	public PROPSHEETHEADERW_V2* lpPS;
	public uint32 dwObject;
	public IOleUIObjInfoW* lpObjInfo;
	public uint32 dwLink;
	public IOleUILinkInfoW* lpLinkInfo;
	public OLEUIGNRLPROPSW* lpGP;
	public OLEUIVIEWPROPSW* lpVP;
	public OLEUILINKPROPSW* lpLP;
}

[CRepr]
public struct OLEUIOBJECTPROPSA
{
	public uint32 cbStruct;
	public OBJECT_PROPERTIES_FLAGS dwFlags;
	public PROPSHEETHEADERA_V2* lpPS;
	public uint32 dwObject;
	public IOleUIObjInfoA* lpObjInfo;
	public uint32 dwLink;
	public IOleUILinkInfoA* lpLinkInfo;
	public OLEUIGNRLPROPSA* lpGP;
	public OLEUIVIEWPROPSA* lpVP;
	public OLEUILINKPROPSA* lpLP;
}

#endregion

#region COM Types
[CRepr]struct ICreateTypeInfo : IUnknown
{
	public new const Guid IID = .(0x00020405, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid) SetGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uTypeFlags) SetTypeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pStrDoc) SetDocString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwHelpContext) SetHelpContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wMajorVerNum, uint16 wMinorVerNum) SetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeInfo* pTInfo, uint32* phRefType) AddRefTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, FUNCDESC* pFuncDesc) AddFuncDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, uint32 hRefType) AddImplType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, int32 implTypeFlags) SetImplTypeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 cbAlignment) SetAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pStrSchema) SetSchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, VARDESC* pVarDesc) AddVarDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR* rgszNames, uint32 cNames) SetFuncAndParamNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR szName) SetVarName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TYPEDESC* pTDescAlias) SetTypeDescAlias;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR szDllName, PWSTR szProcName) DefineFuncAsDllEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR szDocString) SetFuncDocString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR szDocString) SetVarDocString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, uint32 dwHelpContext) SetFuncHelpContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, uint32 dwHelpContext) SetVarHelpContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, BSTR bstrMops) SetMops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDLDESC* pIdlDesc) SetTypeIdldesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) LayOut;
	}


	public HRESULT SetGuid(in Guid guid) mut => VT.[Friend]SetGuid(&this, guid);

	public HRESULT SetTypeFlags(uint32 uTypeFlags) mut => VT.[Friend]SetTypeFlags(&this, uTypeFlags);

	public HRESULT SetDocString(PWSTR pStrDoc) mut => VT.[Friend]SetDocString(&this, pStrDoc);

	public HRESULT SetHelpContext(uint32 dwHelpContext) mut => VT.[Friend]SetHelpContext(&this, dwHelpContext);

	public HRESULT SetVersion(uint16 wMajorVerNum, uint16 wMinorVerNum) mut => VT.[Friend]SetVersion(&this, wMajorVerNum, wMinorVerNum);

	public HRESULT AddRefTypeInfo(ITypeInfo* pTInfo, uint32* phRefType) mut => VT.[Friend]AddRefTypeInfo(&this, pTInfo, phRefType);

	public HRESULT AddFuncDesc(uint32 index, FUNCDESC* pFuncDesc) mut => VT.[Friend]AddFuncDesc(&this, index, pFuncDesc);

	public HRESULT AddImplType(uint32 index, uint32 hRefType) mut => VT.[Friend]AddImplType(&this, index, hRefType);

	public HRESULT SetImplTypeFlags(uint32 index, int32 implTypeFlags) mut => VT.[Friend]SetImplTypeFlags(&this, index, implTypeFlags);

	public HRESULT SetAlignment(uint16 cbAlignment) mut => VT.[Friend]SetAlignment(&this, cbAlignment);

	public HRESULT SetSchema(PWSTR pStrSchema) mut => VT.[Friend]SetSchema(&this, pStrSchema);

	public HRESULT AddVarDesc(uint32 index, VARDESC* pVarDesc) mut => VT.[Friend]AddVarDesc(&this, index, pVarDesc);

	public HRESULT SetFuncAndParamNames(uint32 index, PWSTR* rgszNames, uint32 cNames) mut => VT.[Friend]SetFuncAndParamNames(&this, index, rgszNames, cNames);

	public HRESULT SetVarName(uint32 index, PWSTR szName) mut => VT.[Friend]SetVarName(&this, index, szName);

	public HRESULT SetTypeDescAlias(TYPEDESC* pTDescAlias) mut => VT.[Friend]SetTypeDescAlias(&this, pTDescAlias);

	public HRESULT DefineFuncAsDllEntry(uint32 index, PWSTR szDllName, PWSTR szProcName) mut => VT.[Friend]DefineFuncAsDllEntry(&this, index, szDllName, szProcName);

	public HRESULT SetFuncDocString(uint32 index, PWSTR szDocString) mut => VT.[Friend]SetFuncDocString(&this, index, szDocString);

	public HRESULT SetVarDocString(uint32 index, PWSTR szDocString) mut => VT.[Friend]SetVarDocString(&this, index, szDocString);

	public HRESULT SetFuncHelpContext(uint32 index, uint32 dwHelpContext) mut => VT.[Friend]SetFuncHelpContext(&this, index, dwHelpContext);

	public HRESULT SetVarHelpContext(uint32 index, uint32 dwHelpContext) mut => VT.[Friend]SetVarHelpContext(&this, index, dwHelpContext);

	public HRESULT SetMops(uint32 index, BSTR bstrMops) mut => VT.[Friend]SetMops(&this, index, bstrMops);

	public HRESULT SetTypeIdldesc(IDLDESC* pIdlDesc) mut => VT.[Friend]SetTypeIdldesc(&this, pIdlDesc);

	public HRESULT LayOut() mut => VT.[Friend]LayOut(&this);
}

[CRepr]struct ICreateTypeInfo2 : ICreateTypeInfo
{
	public new const Guid IID = .(0x0002040e, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICreateTypeInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) DeleteFuncDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, INVOKEKIND invKind) DeleteFuncDescByMemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) DeleteVarDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid) DeleteVarDescByMemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) DeleteImplType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, VARIANT* pVarVal) SetCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid guid, VARIANT* pVarVal) SetFuncCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 indexFunc, uint32 indexParam, in Guid guid, VARIANT* pVarVal) SetParamCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid guid, VARIANT* pVarVal) SetVarCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid guid, VARIANT* pVarVal) SetImplTypeCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwHelpStringContext) SetHelpStringContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, uint32 dwHelpStringContext) SetFuncHelpStringContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, uint32 dwHelpStringContext) SetVarHelpStringContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Invalidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName) SetName;
	}


	public HRESULT DeleteFuncDesc(uint32 index) mut => VT.[Friend]DeleteFuncDesc(&this, index);

	public HRESULT DeleteFuncDescByMemId(int32 memid, INVOKEKIND invKind) mut => VT.[Friend]DeleteFuncDescByMemId(&this, memid, invKind);

	public HRESULT DeleteVarDesc(uint32 index) mut => VT.[Friend]DeleteVarDesc(&this, index);

	public HRESULT DeleteVarDescByMemId(int32 memid) mut => VT.[Friend]DeleteVarDescByMemId(&this, memid);

	public HRESULT DeleteImplType(uint32 index) mut => VT.[Friend]DeleteImplType(&this, index);

	public HRESULT SetCustData(in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]SetCustData(&this, guid, pVarVal);

	public HRESULT SetFuncCustData(uint32 index, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]SetFuncCustData(&this, index, guid, pVarVal);

	public HRESULT SetParamCustData(uint32 indexFunc, uint32 indexParam, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]SetParamCustData(&this, indexFunc, indexParam, guid, pVarVal);

	public HRESULT SetVarCustData(uint32 index, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]SetVarCustData(&this, index, guid, pVarVal);

	public HRESULT SetImplTypeCustData(uint32 index, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]SetImplTypeCustData(&this, index, guid, pVarVal);

	public HRESULT SetHelpStringContext(uint32 dwHelpStringContext) mut => VT.[Friend]SetHelpStringContext(&this, dwHelpStringContext);

	public HRESULT SetFuncHelpStringContext(uint32 index, uint32 dwHelpStringContext) mut => VT.[Friend]SetFuncHelpStringContext(&this, index, dwHelpStringContext);

	public HRESULT SetVarHelpStringContext(uint32 index, uint32 dwHelpStringContext) mut => VT.[Friend]SetVarHelpStringContext(&this, index, dwHelpStringContext);

	public HRESULT Invalidate() mut => VT.[Friend]Invalidate(&this);

	public HRESULT SetName(PWSTR szName) mut => VT.[Friend]SetName(&this, szName);
}

[CRepr]struct ICreateTypeLib : IUnknown
{
	public new const Guid IID = .(0x00020406, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName, TYPEKIND tkind, ICreateTypeInfo** ppCTInfo) CreateTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wMajorVerNum, uint16 wMinorVerNum) SetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid) SetGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szDoc) SetDocString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szHelpFileName) SetHelpFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwHelpContext) SetHelpContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid) SetLcid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uLibFlags) SetLibFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveAllChanges;
	}


	public HRESULT CreateTypeInfo(PWSTR szName, TYPEKIND tkind, ICreateTypeInfo** ppCTInfo) mut => VT.[Friend]CreateTypeInfo(&this, szName, tkind, ppCTInfo);

	public HRESULT SetName(PWSTR szName) mut => VT.[Friend]SetName(&this, szName);

	public HRESULT SetVersion(uint16 wMajorVerNum, uint16 wMinorVerNum) mut => VT.[Friend]SetVersion(&this, wMajorVerNum, wMinorVerNum);

	public HRESULT SetGuid(in Guid guid) mut => VT.[Friend]SetGuid(&this, guid);

	public HRESULT SetDocString(PWSTR szDoc) mut => VT.[Friend]SetDocString(&this, szDoc);

	public HRESULT SetHelpFileName(PWSTR szHelpFileName) mut => VT.[Friend]SetHelpFileName(&this, szHelpFileName);

	public HRESULT SetHelpContext(uint32 dwHelpContext) mut => VT.[Friend]SetHelpContext(&this, dwHelpContext);

	public HRESULT SetLcid(uint32 lcid) mut => VT.[Friend]SetLcid(&this, lcid);

	public HRESULT SetLibFlags(uint32 uLibFlags) mut => VT.[Friend]SetLibFlags(&this, uLibFlags);

	public HRESULT SaveAllChanges() mut => VT.[Friend]SaveAllChanges(&this);
}

[CRepr]struct ICreateTypeLib2 : ICreateTypeLib
{
	public new const Guid IID = .(0x0002040f, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICreateTypeLib.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName) DeleteTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, VARIANT* pVarVal) SetCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwHelpStringContext) SetHelpStringContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szFileName) SetHelpStringDll;
	}


	public HRESULT DeleteTypeInfo(PWSTR szName) mut => VT.[Friend]DeleteTypeInfo(&this, szName);

	public HRESULT SetCustData(in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]SetCustData(&this, guid, pVarVal);

	public HRESULT SetHelpStringContext(uint32 dwHelpStringContext) mut => VT.[Friend]SetHelpStringContext(&this, dwHelpStringContext);

	public HRESULT SetHelpStringDll(PWSTR szFileName) mut => VT.[Friend]SetHelpStringDll(&this, szFileName);
}

[CRepr]struct IEnumVARIANT : IUnknown
{
	public new const Guid IID = .(0x00020404, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VARIANT* rgVar, uint32* pCeltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppEnum) Clone;
	}


	public HRESULT Next(uint32 celt, VARIANT* rgVar, uint32* pCeltFetched) mut => VT.[Friend]Next(&this, celt, rgVar, pCeltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumVARIANT** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct ITypeChangeEvents : IUnknown
{
	public new const Guid IID = .(0x00020410, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHANGEKIND changeKind, ITypeInfo* pTInfoBefore, PWSTR pStrName, int32* pfCancel) RequestTypeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHANGEKIND changeKind, ITypeInfo* pTInfoAfter, PWSTR pStrName) AfterTypeChange;
	}


	public HRESULT RequestTypeChange(CHANGEKIND changeKind, ITypeInfo* pTInfoBefore, PWSTR pStrName, int32* pfCancel) mut => VT.[Friend]RequestTypeChange(&this, changeKind, pTInfoBefore, pStrName, pfCancel);

	public HRESULT AfterTypeChange(CHANGEKIND changeKind, ITypeInfo* pTInfoAfter, PWSTR pStrName) mut => VT.[Friend]AfterTypeChange(&this, changeKind, pTInfoAfter, pStrName);
}

[CRepr]struct ICreateErrorInfo : IUnknown
{
	public new const Guid IID = .(0x22f03340, 0x547d, 0x101b, 0x8e, 0x65, 0x08, 0x00, 0x2b, 0x2b, 0xd1, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid) SetGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szSource) SetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szDescription) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szHelpFile) SetHelpFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwHelpContext) SetHelpContext;
	}


	public HRESULT SetGUID(in Guid rguid) mut => VT.[Friend]SetGUID(&this, rguid);

	public HRESULT SetSource(PWSTR szSource) mut => VT.[Friend]SetSource(&this, szSource);

	public HRESULT SetDescription(PWSTR szDescription) mut => VT.[Friend]SetDescription(&this, szDescription);

	public HRESULT SetHelpFile(PWSTR szHelpFile) mut => VT.[Friend]SetHelpFile(&this, szHelpFile);

	public HRESULT SetHelpContext(uint32 dwHelpContext) mut => VT.[Friend]SetHelpContext(&this, dwHelpContext);
}

[CRepr]struct ITypeFactory : IUnknown
{
	public new const Guid IID = .(0x0000002e, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeInfo* pTypeInfo, in Guid riid, IUnknown** ppv) CreateFromTypeInfo;
	}


	public HRESULT CreateFromTypeInfo(ITypeInfo* pTypeInfo, in Guid riid, IUnknown** ppv) mut => VT.[Friend]CreateFromTypeInfo(&this, pTypeInfo, riid, ppv);
}

[CRepr]struct ITypeMarshal : IUnknown
{
	public new const Guid IID = .(0x0000002d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvType, uint32 dwDestContext, void* pvDestContext, uint32* pSize) Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvType, uint32 dwDestContext, void* pvDestContext, uint32 cbBufferLength, uint8* pBuffer, uint32* pcbWritten) Marshal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvType, uint32 dwFlags, uint32 cbBufferLength, uint8* pBuffer, uint32* pcbRead) Unmarshal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvType) Free;
	}


	public HRESULT Size(void* pvType, uint32 dwDestContext, void* pvDestContext, uint32* pSize) mut => VT.[Friend]Size(&this, pvType, dwDestContext, pvDestContext, pSize);

	public HRESULT Marshal(void* pvType, uint32 dwDestContext, void* pvDestContext, uint32 cbBufferLength, uint8* pBuffer, uint32* pcbWritten) mut => VT.[Friend]Marshal(&this, pvType, dwDestContext, pvDestContext, cbBufferLength, pBuffer, pcbWritten);

	public HRESULT Unmarshal(void* pvType, uint32 dwFlags, uint32 cbBufferLength, uint8* pBuffer, uint32* pcbRead) mut => VT.[Friend]Unmarshal(&this, pvType, dwFlags, cbBufferLength, pBuffer, pcbRead);

	public HRESULT Free(void* pvType) mut => VT.[Friend]Free(&this, pvType);
}

[CRepr]struct IRecordInfo : IUnknown
{
	public new const Guid IID = .(0x0000002f, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvNew) RecordInit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvExisting) RecordClear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvExisting, void* pvNew) RecordCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) GetGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbSize) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeInfo** ppTypeInfo) GetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvData, PWSTR szFieldName, VARIANT* pvarField) GetField;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvData, PWSTR szFieldName, VARIANT* pvarField, void** ppvDataCArray) GetFieldNoCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INVOKEKIND wFlags, void* pvData, PWSTR szFieldName, VARIANT* pvarField) PutField;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INVOKEKIND wFlags, void* pvData, PWSTR szFieldName, VARIANT* pvarField) PutFieldNoCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcNames, BSTR* rgBstrNames) GetFieldNames;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, IRecordInfo* pRecordInfo) IsMatchingType;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self) RecordCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvSource, void** ppvDest) RecordCreateCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvRecord) RecordDestroy;
	}


	public HRESULT RecordInit(void* pvNew) mut => VT.[Friend]RecordInit(&this, pvNew);

	public HRESULT RecordClear(void* pvExisting) mut => VT.[Friend]RecordClear(&this, pvExisting);

	public HRESULT RecordCopy(void* pvExisting, void* pvNew) mut => VT.[Friend]RecordCopy(&this, pvExisting, pvNew);

	public HRESULT GetGuid(Guid* pguid) mut => VT.[Friend]GetGuid(&this, pguid);

	public HRESULT GetName(BSTR* pbstrName) mut => VT.[Friend]GetName(&this, pbstrName);

	public HRESULT GetSize(uint32* pcbSize) mut => VT.[Friend]GetSize(&this, pcbSize);

	public HRESULT GetTypeInfo(ITypeInfo** ppTypeInfo) mut => VT.[Friend]GetTypeInfo(&this, ppTypeInfo);

	public HRESULT GetField(void* pvData, PWSTR szFieldName, VARIANT* pvarField) mut => VT.[Friend]GetField(&this, pvData, szFieldName, pvarField);

	public HRESULT GetFieldNoCopy(void* pvData, PWSTR szFieldName, VARIANT* pvarField, void** ppvDataCArray) mut => VT.[Friend]GetFieldNoCopy(&this, pvData, szFieldName, pvarField, ppvDataCArray);

	public HRESULT PutField(INVOKEKIND wFlags, void* pvData, PWSTR szFieldName, VARIANT* pvarField) mut => VT.[Friend]PutField(&this, wFlags, pvData, szFieldName, pvarField);

	public HRESULT PutFieldNoCopy(INVOKEKIND wFlags, void* pvData, PWSTR szFieldName, VARIANT* pvarField) mut => VT.[Friend]PutFieldNoCopy(&this, wFlags, pvData, szFieldName, pvarField);

	public HRESULT GetFieldNames(uint32* pcNames, BSTR* rgBstrNames) mut => VT.[Friend]GetFieldNames(&this, pcNames, rgBstrNames);

	public BOOL IsMatchingType(IRecordInfo* pRecordInfo) mut => VT.[Friend]IsMatchingType(&this, pRecordInfo);

	public void* RecordCreate() mut => VT.[Friend]RecordCreate(&this);

	public HRESULT RecordCreateCopy(void* pvSource, void** ppvDest) mut => VT.[Friend]RecordCreateCopy(&this, pvSource, ppvDest);

	public HRESULT RecordDestroy(void* pvRecord) mut => VT.[Friend]RecordDestroy(&this, pvRecord);
}

[CRepr]struct IOleAdviseHolder : IUnknown
{
	public new const Guid IID = .(0x00000111, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAdviseSink* pAdvise, uint32* pdwConnection) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnection) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATDATA** ppenumAdvise) EnumAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmk) SendOnRename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SendOnSave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SendOnClose;
	}


	public HRESULT Advise(IAdviseSink* pAdvise, uint32* pdwConnection) mut => VT.[Friend]Advise(&this, pAdvise, pdwConnection);

	public HRESULT Unadvise(uint32 dwConnection) mut => VT.[Friend]Unadvise(&this, dwConnection);

	public HRESULT EnumAdvise(IEnumSTATDATA** ppenumAdvise) mut => VT.[Friend]EnumAdvise(&this, ppenumAdvise);

	public HRESULT SendOnRename(IMoniker* pmk) mut => VT.[Friend]SendOnRename(&this, pmk);

	public HRESULT SendOnSave() mut => VT.[Friend]SendOnSave(&this);

	public HRESULT SendOnClose() mut => VT.[Friend]SendOnClose(&this);
}

[CRepr]struct IOleCache : IUnknown
{
	public new const Guid IID = .(0x0000011e, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetc, uint32 advf, uint32* pdwConnection) Cache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnection) Uncache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATDATA** ppenumSTATDATA) EnumCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject) InitCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetc, STGMEDIUM* pmedium, BOOL fRelease) SetData;
	}


	public HRESULT Cache(FORMATETC* pformatetc, uint32 advf, uint32* pdwConnection) mut => VT.[Friend]Cache(&this, pformatetc, advf, pdwConnection);

	public HRESULT Uncache(uint32 dwConnection) mut => VT.[Friend]Uncache(&this, dwConnection);

	public HRESULT EnumCache(IEnumSTATDATA** ppenumSTATDATA) mut => VT.[Friend]EnumCache(&this, ppenumSTATDATA);

	public HRESULT InitCache(IDataObject* pDataObject) mut => VT.[Friend]InitCache(&this, pDataObject);

	public HRESULT SetData(FORMATETC* pformatetc, STGMEDIUM* pmedium, BOOL fRelease) mut => VT.[Friend]SetData(&this, pformatetc, pmedium, fRelease);
}

[CRepr]struct IOleCache2 : IOleCache
{
	public new const Guid IID = .(0x00000128, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleCache.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, UPDFCACHE_FLAGS grfUpdf, void* pReserved) UpdateCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDiscardOptions) DiscardCache;
	}


	public HRESULT UpdateCache(IDataObject* pDataObject, UPDFCACHE_FLAGS grfUpdf, void* pReserved) mut => VT.[Friend]UpdateCache(&this, pDataObject, grfUpdf, pReserved);

	public HRESULT DiscardCache(uint32 dwDiscardOptions) mut => VT.[Friend]DiscardCache(&this, dwDiscardOptions);
}

[CRepr]struct IOleCacheControl : IUnknown
{
	public new const Guid IID = .(0x00000129, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject) OnRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnStop;
	}


	public HRESULT OnRun(IDataObject* pDataObject) mut => VT.[Friend]OnRun(&this, pDataObject);

	public HRESULT OnStop() mut => VT.[Friend]OnStop(&this);
}

[CRepr]struct IParseDisplayName : IUnknown
{
	public new const Guid IID = .(0x0000011a, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, PWSTR pszDisplayName, uint32* pchEaten, IMoniker** ppmkOut) ParseDisplayName;
	}


	public HRESULT ParseDisplayName(IBindCtx* pbc, PWSTR pszDisplayName, uint32* pchEaten, IMoniker** ppmkOut) mut => VT.[Friend]ParseDisplayName(&this, pbc, pszDisplayName, pchEaten, ppmkOut);
}

[CRepr]struct IOleContainer : IParseDisplayName
{
	public new const Guid IID = .(0x0000011b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IParseDisplayName.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLECONTF grfFlags, IEnumUnknown** ppenum) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLock) LockContainer;
	}


	public HRESULT EnumObjects(OLECONTF grfFlags, IEnumUnknown** ppenum) mut => VT.[Friend]EnumObjects(&this, grfFlags, ppenum);

	public HRESULT LockContainer(BOOL fLock) mut => VT.[Friend]LockContainer(&this, fLock);
}

[CRepr]struct IOleClientSite : IUnknown
{
	public new const Guid IID = .(0x00000118, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLEGETMONIKER dwAssign, OLEWHICHMK dwWhichMoniker, IMoniker** ppmk) GetMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleContainer** ppContainer) GetContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) OnShowWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestNewObjectLayout;
	}


	public HRESULT SaveObject() mut => VT.[Friend]SaveObject(&this);

	public HRESULT GetMoniker(OLEGETMONIKER dwAssign, OLEWHICHMK dwWhichMoniker, IMoniker** ppmk) mut => VT.[Friend]GetMoniker(&this, dwAssign, dwWhichMoniker, ppmk);

	public HRESULT GetContainer(IOleContainer** ppContainer) mut => VT.[Friend]GetContainer(&this, ppContainer);

	public HRESULT ShowObject() mut => VT.[Friend]ShowObject(&this);

	public HRESULT OnShowWindow(BOOL fShow) mut => VT.[Friend]OnShowWindow(&this, fShow);

	public HRESULT RequestNewObjectLayout() mut => VT.[Friend]RequestNewObjectLayout(&this);
}

[CRepr]struct IOleObject : IUnknown
{
	public new const Guid IID = .(0x00000112, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleClientSite* pClientSite) SetClientSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleClientSite** ppClientSite) GetClientSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szContainerApp, PWSTR szContainerObj) SetHostNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLECLOSE dwSaveOption) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLEWHICHMK dwWhichMoniker, IMoniker* pmk) SetMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLEGETMONIKER dwAssign, OLEWHICHMK dwWhichMoniker, IMoniker** ppmk) GetMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, BOOL fCreation, uint32 dwReserved) InitFromData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved, IDataObject** ppDataObject) GetClipboardData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iVerb, MSG* lpmsg, IOleClientSite* pActiveSite, int32 lindex, HWND hwndParent, RECT* lprcPosRect) DoVerb;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOLEVERB** ppEnumOleVerb) EnumVerbs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsUpToDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pClsid) GetUserClassID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, USERCLASSTYPE dwFormOfType, PWSTR* pszUserType) GetUserType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, SIZE* psizel) SetExtent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, SIZE* psizel) GetExtent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAdviseSink* pAdvSink, uint32* pdwConnection) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnection) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATDATA** ppenumAdvise) EnumAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwAspect, OLEMISC* pdwStatus) GetMiscStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LOGPALETTE* pLogpal) SetColorScheme;
	}


	public HRESULT SetClientSite(IOleClientSite* pClientSite) mut => VT.[Friend]SetClientSite(&this, pClientSite);

	public HRESULT GetClientSite(IOleClientSite** ppClientSite) mut => VT.[Friend]GetClientSite(&this, ppClientSite);

	public HRESULT SetHostNames(PWSTR szContainerApp, PWSTR szContainerObj) mut => VT.[Friend]SetHostNames(&this, szContainerApp, szContainerObj);

	public HRESULT Close(OLECLOSE dwSaveOption) mut => VT.[Friend]Close(&this, dwSaveOption);

	public HRESULT SetMoniker(OLEWHICHMK dwWhichMoniker, IMoniker* pmk) mut => VT.[Friend]SetMoniker(&this, dwWhichMoniker, pmk);

	public HRESULT GetMoniker(OLEGETMONIKER dwAssign, OLEWHICHMK dwWhichMoniker, IMoniker** ppmk) mut => VT.[Friend]GetMoniker(&this, dwAssign, dwWhichMoniker, ppmk);

	public HRESULT InitFromData(IDataObject* pDataObject, BOOL fCreation, uint32 dwReserved) mut => VT.[Friend]InitFromData(&this, pDataObject, fCreation, dwReserved);

	public HRESULT GetClipboardData(uint32 dwReserved, IDataObject** ppDataObject) mut => VT.[Friend]GetClipboardData(&this, dwReserved, ppDataObject);

	public HRESULT DoVerb(int32 iVerb, MSG* lpmsg, IOleClientSite* pActiveSite, int32 lindex, HWND hwndParent, RECT* lprcPosRect) mut => VT.[Friend]DoVerb(&this, iVerb, lpmsg, pActiveSite, lindex, hwndParent, lprcPosRect);

	public HRESULT EnumVerbs(IEnumOLEVERB** ppEnumOleVerb) mut => VT.[Friend]EnumVerbs(&this, ppEnumOleVerb);

	public HRESULT Update() mut => VT.[Friend]Update(&this);

	public HRESULT IsUpToDate() mut => VT.[Friend]IsUpToDate(&this);

	public HRESULT GetUserClassID(Guid* pClsid) mut => VT.[Friend]GetUserClassID(&this, pClsid);

	public HRESULT GetUserType(USERCLASSTYPE dwFormOfType, PWSTR* pszUserType) mut => VT.[Friend]GetUserType(&this, dwFormOfType, pszUserType);

	public HRESULT SetExtent(DVASPECT dwDrawAspect, SIZE* psizel) mut => VT.[Friend]SetExtent(&this, dwDrawAspect, psizel);

	public HRESULT GetExtent(DVASPECT dwDrawAspect, SIZE* psizel) mut => VT.[Friend]GetExtent(&this, dwDrawAspect, psizel);

	public HRESULT Advise(IAdviseSink* pAdvSink, uint32* pdwConnection) mut => VT.[Friend]Advise(&this, pAdvSink, pdwConnection);

	public HRESULT Unadvise(uint32 dwConnection) mut => VT.[Friend]Unadvise(&this, dwConnection);

	public HRESULT EnumAdvise(IEnumSTATDATA** ppenumAdvise) mut => VT.[Friend]EnumAdvise(&this, ppenumAdvise);

	public HRESULT GetMiscStatus(DVASPECT dwAspect, OLEMISC* pdwStatus) mut => VT.[Friend]GetMiscStatus(&this, dwAspect, pdwStatus);

	public HRESULT SetColorScheme(LOGPALETTE* pLogpal) mut => VT.[Friend]SetColorScheme(&this, pLogpal);
}

[CRepr]struct IOleWindow : IUnknown
{
	public new const Guid IID = .(0x00000114, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) GetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnterMode) ContextSensitiveHelp;
	}


	public HRESULT GetWindow(HWND* phwnd) mut => VT.[Friend]GetWindow(&this, phwnd);

	public HRESULT ContextSensitiveHelp(BOOL fEnterMode) mut => VT.[Friend]ContextSensitiveHelp(&this, fEnterMode);
}

[CRepr]struct IOleLink : IUnknown
{
	public new const Guid IID = .(0x0000011d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUpdateOpt) SetUpdateOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwUpdateOpt) GetUpdateOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmk, in Guid rclsid) SetSourceMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker** ppmk) GetSourceMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStatusText) SetSourceDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszDisplayName) GetSourceDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 bindflags, IBindCtx* pbc) BindToSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BindIfRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) GetBoundSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnbindSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc) Update;
	}


	public HRESULT SetUpdateOptions(uint32 dwUpdateOpt) mut => VT.[Friend]SetUpdateOptions(&this, dwUpdateOpt);

	public HRESULT GetUpdateOptions(uint32* pdwUpdateOpt) mut => VT.[Friend]GetUpdateOptions(&this, pdwUpdateOpt);

	public HRESULT SetSourceMoniker(IMoniker* pmk, in Guid rclsid) mut => VT.[Friend]SetSourceMoniker(&this, pmk, rclsid);

	public HRESULT GetSourceMoniker(IMoniker** ppmk) mut => VT.[Friend]GetSourceMoniker(&this, ppmk);

	public HRESULT SetSourceDisplayName(PWSTR pszStatusText) mut => VT.[Friend]SetSourceDisplayName(&this, pszStatusText);

	public HRESULT GetSourceDisplayName(PWSTR* ppszDisplayName) mut => VT.[Friend]GetSourceDisplayName(&this, ppszDisplayName);

	public HRESULT BindToSource(uint32 bindflags, IBindCtx* pbc) mut => VT.[Friend]BindToSource(&this, bindflags, pbc);

	public HRESULT BindIfRunning() mut => VT.[Friend]BindIfRunning(&this);

	public HRESULT GetBoundSource(IUnknown** ppunk) mut => VT.[Friend]GetBoundSource(&this, ppunk);

	public HRESULT UnbindSource() mut => VT.[Friend]UnbindSource(&this);

	public HRESULT Update(IBindCtx* pbc) mut => VT.[Friend]Update(&this, pbc);
}

[CRepr]struct IOleItemContainer : IOleContainer
{
	public new const Guid IID = .(0x0000011c, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleContainer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItem, uint32 dwSpeedNeeded, IBindCtx* pbc, in Guid riid, void** ppvObject) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItem, IBindCtx* pbc, in Guid riid, void** ppvStorage) GetObjectStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItem) IsRunning;
	}


	public HRESULT GetObject(PWSTR pszItem, uint32 dwSpeedNeeded, IBindCtx* pbc, in Guid riid, void** ppvObject) mut => VT.[Friend]GetObject(&this, pszItem, dwSpeedNeeded, pbc, riid, ppvObject);

	public HRESULT GetObjectStorage(PWSTR pszItem, IBindCtx* pbc, in Guid riid, void** ppvStorage) mut => VT.[Friend]GetObjectStorage(&this, pszItem, pbc, riid, ppvStorage);

	public HRESULT IsRunning(PWSTR pszItem) mut => VT.[Friend]IsRunning(&this, pszItem);
}

[CRepr]struct IOleInPlaceUIWindow : IOleWindow
{
	public new const Guid IID = .(0x00000115, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* lprectBorder) GetBorder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pborderwidths) RequestBorderSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pborderwidths) SetBorderSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceActiveObject* pActiveObject, PWSTR pszObjName) SetActiveObject;
	}


	public HRESULT GetBorder(RECT* lprectBorder) mut => VT.[Friend]GetBorder(&this, lprectBorder);

	public HRESULT RequestBorderSpace(RECT* pborderwidths) mut => VT.[Friend]RequestBorderSpace(&this, pborderwidths);

	public HRESULT SetBorderSpace(RECT* pborderwidths) mut => VT.[Friend]SetBorderSpace(&this, pborderwidths);

	public HRESULT SetActiveObject(IOleInPlaceActiveObject* pActiveObject, PWSTR pszObjName) mut => VT.[Friend]SetActiveObject(&this, pActiveObject, pszObjName);
}

[CRepr]struct IOleInPlaceActiveObject : IOleWindow
{
	public new const Guid IID = .(0x00000117, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* lpmsg) TranslateAccelerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fActivate) OnFrameWindowActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fActivate) OnDocWindowActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcBorder, IOleInPlaceUIWindow* pUIWindow, BOOL fFrameWindow) ResizeBorder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) EnableModeless;
	}


	public HRESULT TranslateAccelerator(MSG* lpmsg) mut => VT.[Friend]TranslateAccelerator(&this, lpmsg);

	public HRESULT OnFrameWindowActivate(BOOL fActivate) mut => VT.[Friend]OnFrameWindowActivate(&this, fActivate);

	public HRESULT OnDocWindowActivate(BOOL fActivate) mut => VT.[Friend]OnDocWindowActivate(&this, fActivate);

	public HRESULT ResizeBorder(RECT* prcBorder, IOleInPlaceUIWindow* pUIWindow, BOOL fFrameWindow) mut => VT.[Friend]ResizeBorder(&this, prcBorder, pUIWindow, fFrameWindow);

	public HRESULT EnableModeless(BOOL fEnable) mut => VT.[Friend]EnableModeless(&this, fEnable);
}

[CRepr]struct IOleInPlaceFrame : IOleInPlaceUIWindow
{
	public new const Guid IID = .(0x00000116, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleInPlaceUIWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenuShared, OLEMENUGROUPWIDTHS* lpMenuWidths) InsertMenus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenuShared, int holemenu, HWND hwndActiveObject) SetMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenuShared) RemoveMenus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStatusText) SetStatusText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) EnableModeless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* lpmsg, uint16 wID) TranslateAccelerator;
	}


	public HRESULT InsertMenus(HMENU hmenuShared, OLEMENUGROUPWIDTHS* lpMenuWidths) mut => VT.[Friend]InsertMenus(&this, hmenuShared, lpMenuWidths);

	public HRESULT SetMenu(HMENU hmenuShared, int holemenu, HWND hwndActiveObject) mut => VT.[Friend]SetMenu(&this, hmenuShared, holemenu, hwndActiveObject);

	public HRESULT RemoveMenus(HMENU hmenuShared) mut => VT.[Friend]RemoveMenus(&this, hmenuShared);

	public HRESULT SetStatusText(PWSTR pszStatusText) mut => VT.[Friend]SetStatusText(&this, pszStatusText);

	public HRESULT EnableModeless(BOOL fEnable) mut => VT.[Friend]EnableModeless(&this, fEnable);

	public HRESULT TranslateAccelerator(MSG* lpmsg, uint16 wID) mut => VT.[Friend]TranslateAccelerator(&this, lpmsg, wID);
}

[CRepr]struct IOleInPlaceObject : IOleWindow
{
	public new const Guid IID = .(0x00000113, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InPlaceDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UIDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* lprcPosRect, RECT* lprcClipRect) SetObjectRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReactivateAndUndo;
	}


	public HRESULT InPlaceDeactivate() mut => VT.[Friend]InPlaceDeactivate(&this);

	public HRESULT UIDeactivate() mut => VT.[Friend]UIDeactivate(&this);

	public HRESULT SetObjectRects(RECT* lprcPosRect, RECT* lprcClipRect) mut => VT.[Friend]SetObjectRects(&this, lprcPosRect, lprcClipRect);

	public HRESULT ReactivateAndUndo() mut => VT.[Friend]ReactivateAndUndo(&this);
}

[CRepr]struct IOleInPlaceSite : IOleWindow
{
	public new const Guid IID = .(0x00000119, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CanInPlaceActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnInPlaceActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnUIActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceFrame** ppFrame, IOleInPlaceUIWindow** ppDoc, RECT* lprcPosRect, RECT* lprcClipRect, OLEINPLACEFRAMEINFO* lpFrameInfo) GetWindowContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE scrollExtant) Scroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUndoable) OnUIDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnInPlaceDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DiscardUndoState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeactivateAndUndo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* lprcPosRect) OnPosRectChange;
	}


	public HRESULT CanInPlaceActivate() mut => VT.[Friend]CanInPlaceActivate(&this);

	public HRESULT OnInPlaceActivate() mut => VT.[Friend]OnInPlaceActivate(&this);

	public HRESULT OnUIActivate() mut => VT.[Friend]OnUIActivate(&this);

	public HRESULT GetWindowContext(IOleInPlaceFrame** ppFrame, IOleInPlaceUIWindow** ppDoc, RECT* lprcPosRect, RECT* lprcClipRect, OLEINPLACEFRAMEINFO* lpFrameInfo) mut => VT.[Friend]GetWindowContext(&this, ppFrame, ppDoc, lprcPosRect, lprcClipRect, lpFrameInfo);

	public HRESULT Scroll(SIZE scrollExtant) mut => VT.[Friend]Scroll(&this, scrollExtant);

	public HRESULT OnUIDeactivate(BOOL fUndoable) mut => VT.[Friend]OnUIDeactivate(&this, fUndoable);

	public HRESULT OnInPlaceDeactivate() mut => VT.[Friend]OnInPlaceDeactivate(&this);

	public HRESULT DiscardUndoState() mut => VT.[Friend]DiscardUndoState(&this);

	public HRESULT DeactivateAndUndo() mut => VT.[Friend]DeactivateAndUndo(&this);

	public HRESULT OnPosRectChange(RECT* lprcPosRect) mut => VT.[Friend]OnPosRectChange(&this, lprcPosRect);
}

[CRepr]struct IContinue : IUnknown
{
	public new const Guid IID = .(0x0000012a, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FContinue;
	}


	public HRESULT FContinue() mut => VT.[Friend]FContinue(&this);
}

[CRepr]struct IViewObject : IUnknown
{
	public new const Guid IID = .(0x0000010d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcTargetDev, HDC hdcDraw, RECTL* lprcBounds, RECTL* lprcWBounds, int pfnContinue, uint dwContinue) Draw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hicTargetDev, LOGPALETTE** ppColorSet) GetColorSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, uint32* pdwFreeze) Freeze;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFreeze) Unfreeze;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT aspects, ADVF advf, IAdviseSink* pAdvSink) SetAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pAspects, uint32* pAdvf, IAdviseSink** ppAdvSink) GetAdvise;
	}


	public HRESULT Draw(DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcTargetDev, HDC hdcDraw, RECTL* lprcBounds, RECTL* lprcWBounds, int pfnContinue, uint dwContinue) mut => VT.[Friend]Draw(&this, dwDrawAspect, lindex, pvAspect, ptd, hdcTargetDev, hdcDraw, lprcBounds, lprcWBounds, pfnContinue, dwContinue);

	public HRESULT GetColorSet(DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hicTargetDev, LOGPALETTE** ppColorSet) mut => VT.[Friend]GetColorSet(&this, dwDrawAspect, lindex, pvAspect, ptd, hicTargetDev, ppColorSet);

	public HRESULT Freeze(DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, uint32* pdwFreeze) mut => VT.[Friend]Freeze(&this, dwDrawAspect, lindex, pvAspect, pdwFreeze);

	public HRESULT Unfreeze(uint32 dwFreeze) mut => VT.[Friend]Unfreeze(&this, dwFreeze);

	public HRESULT SetAdvise(DVASPECT aspects, ADVF advf, IAdviseSink* pAdvSink) mut => VT.[Friend]SetAdvise(&this, aspects, advf, pAdvSink);

	public HRESULT GetAdvise(uint32* pAspects, uint32* pAdvf, IAdviseSink** ppAdvSink) mut => VT.[Friend]GetAdvise(&this, pAspects, pAdvf, ppAdvSink);
}

[CRepr]struct IViewObject2 : IViewObject
{
	public new const Guid IID = .(0x00000127, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IViewObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, DVTARGETDEVICE* ptd, SIZE* lpsizel) GetExtent;
	}


	public HRESULT GetExtent(DVASPECT dwDrawAspect, int32 lindex, DVTARGETDEVICE* ptd, SIZE* lpsizel) mut => VT.[Friend]GetExtent(&this, dwDrawAspect, lindex, ptd, lpsizel);
}

[CRepr]struct IDropSource : IUnknown
{
	public new const Guid IID = .(0x00000121, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEscapePressed, MODIFIERKEYS_FLAGS grfKeyState) QueryContinueDrag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DROPEFFECT dwEffect) GiveFeedback;
	}


	public HRESULT QueryContinueDrag(BOOL fEscapePressed, MODIFIERKEYS_FLAGS grfKeyState) mut => VT.[Friend]QueryContinueDrag(&this, fEscapePressed, grfKeyState);

	public HRESULT GiveFeedback(DROPEFFECT dwEffect) mut => VT.[Friend]GiveFeedback(&this, dwEffect);
}

[CRepr]struct IDropTarget : IUnknown
{
	public new const Guid IID = .(0x00000122, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObj, MODIFIERKEYS_FLAGS grfKeyState, POINTL pt, DROPEFFECT* pdwEffect) DragEnter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MODIFIERKEYS_FLAGS grfKeyState, POINTL pt, DROPEFFECT* pdwEffect) DragOver;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DragLeave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObj, MODIFIERKEYS_FLAGS grfKeyState, POINTL pt, DROPEFFECT* pdwEffect) Drop;
	}


	public HRESULT DragEnter(IDataObject* pDataObj, MODIFIERKEYS_FLAGS grfKeyState, POINTL pt, DROPEFFECT* pdwEffect) mut => VT.[Friend]DragEnter(&this, pDataObj, grfKeyState, pt, pdwEffect);

	public HRESULT DragOver(MODIFIERKEYS_FLAGS grfKeyState, POINTL pt, DROPEFFECT* pdwEffect) mut => VT.[Friend]DragOver(&this, grfKeyState, pt, pdwEffect);

	public HRESULT DragLeave() mut => VT.[Friend]DragLeave(&this);

	public HRESULT Drop(IDataObject* pDataObj, MODIFIERKEYS_FLAGS grfKeyState, POINTL pt, DROPEFFECT* pdwEffect) mut => VT.[Friend]Drop(&this, pDataObj, grfKeyState, pt, pdwEffect);
}

[CRepr]struct IDropSourceNotify : IUnknown
{
	public new const Guid IID = .(0x0000012b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTarget) DragEnterTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DragLeaveTarget;
	}


	public HRESULT DragEnterTarget(HWND hwndTarget) mut => VT.[Friend]DragEnterTarget(&this, hwndTarget);

	public HRESULT DragLeaveTarget() mut => VT.[Friend]DragLeaveTarget(&this);
}

[CRepr]struct IEnterpriseDropTarget : IUnknown
{
	public new const Guid IID = .(0x390e3878, 0xfd55, 0x4e18, 0x81, 0x9d, 0x46, 0x82, 0x08, 0x1c, 0x0c, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR identity) SetDropSourceEnterpriseId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* value) IsEvaluatingEdpPolicy;
	}


	public HRESULT SetDropSourceEnterpriseId(PWSTR identity) mut => VT.[Friend]SetDropSourceEnterpriseId(&this, identity);

	public HRESULT IsEvaluatingEdpPolicy(BOOL* value) mut => VT.[Friend]IsEvaluatingEdpPolicy(&this, value);
}

[CRepr]struct IEnumOLEVERB : IUnknown
{
	public new const Guid IID = .(0x00000104, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, OLEVERB* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOLEVERB** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, OLEVERB* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumOLEVERB** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IClassFactory2 : IClassFactory
{
	public new const Guid IID = .(0xb196b28f, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IClassFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LICINFO* pLicInfo) GetLicInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved, BSTR* pBstrKey) RequestLicKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, IUnknown* pUnkReserved, in Guid riid, BSTR bstrKey, void** ppvObj) CreateInstanceLic;
	}


	public HRESULT GetLicInfo(LICINFO* pLicInfo) mut => VT.[Friend]GetLicInfo(&this, pLicInfo);

	public HRESULT RequestLicKey(uint32 dwReserved, BSTR* pBstrKey) mut => VT.[Friend]RequestLicKey(&this, dwReserved, pBstrKey);

	public HRESULT CreateInstanceLic(IUnknown* pUnkOuter, IUnknown* pUnkReserved, in Guid riid, BSTR bstrKey, void** ppvObj) mut => VT.[Friend]CreateInstanceLic(&this, pUnkOuter, pUnkReserved, riid, bstrKey, ppvObj);
}

[CRepr]struct IProvideClassInfo : IUnknown
{
	public new const Guid IID = .(0xb196b283, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeInfo** ppTI) GetClassInfo;
	}


	public HRESULT GetClassInfo(ITypeInfo** ppTI) mut => VT.[Friend]GetClassInfo(&this, ppTI);
}

[CRepr]struct IProvideClassInfo2 : IProvideClassInfo
{
	public new const Guid IID = .(0xa6bc3ac0, 0xdbaa, 0x11ce, 0x9d, 0xe3, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IProvideClassInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwGuidKind, Guid* pGUID) GetGUID;
	}


	public HRESULT GetGUID(uint32 dwGuidKind, Guid* pGUID) mut => VT.[Friend]GetGUID(&this, dwGuidKind, pGUID);
}

[CRepr]struct IProvideMultipleClassInfo : IProvideClassInfo2
{
	public new const Guid IID = .(0xa7aba9c1, 0x8983, 0x11cf, 0x8f, 0x20, 0x00, 0x80, 0x5f, 0x2c, 0xd0, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IProvideClassInfo2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcti) GetMultiTypeInfoCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iti, MULTICLASSINFO_FLAGS dwFlags, ITypeInfo** pptiCoClass, uint32* pdwTIFlags, uint32* pcdispidReserved, Guid* piidPrimary, Guid* piidSource) GetInfoOfIndex;
	}


	public HRESULT GetMultiTypeInfoCount(uint32* pcti) mut => VT.[Friend]GetMultiTypeInfoCount(&this, pcti);

	public HRESULT GetInfoOfIndex(uint32 iti, MULTICLASSINFO_FLAGS dwFlags, ITypeInfo** pptiCoClass, uint32* pdwTIFlags, uint32* pcdispidReserved, Guid* piidPrimary, Guid* piidSource) mut => VT.[Friend]GetInfoOfIndex(&this, iti, dwFlags, pptiCoClass, pdwTIFlags, pcdispidReserved, piidPrimary, piidSource);
}

[CRepr]struct IOleControl : IUnknown
{
	public new const Guid IID = .(0xb196b288, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTROLINFO* pCI) GetControlInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg) OnMnemonic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID) OnAmbientPropertyChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bFreeze) FreezeEvents;
	}


	public HRESULT GetControlInfo(CONTROLINFO* pCI) mut => VT.[Friend]GetControlInfo(&this, pCI);

	public HRESULT OnMnemonic(MSG* pMsg) mut => VT.[Friend]OnMnemonic(&this, pMsg);

	public HRESULT OnAmbientPropertyChange(int32 dispID) mut => VT.[Friend]OnAmbientPropertyChange(&this, dispID);

	public HRESULT FreezeEvents(BOOL bFreeze) mut => VT.[Friend]FreezeEvents(&this, bFreeze);
}

[CRepr]struct IOleControlSite : IUnknown
{
	public new const Guid IID = .(0xb196b289, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnControlInfoChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLock) LockInPlaceActive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDisp) GetExtendedControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINTL* pPtlHimetric, POINTF* pPtfContainer, XFORMCOORDS dwFlags) TransformCoords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, KEYMODIFIERS grfModifiers) TranslateAccelerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fGotFocus) OnFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowPropertyFrame;
	}


	public HRESULT OnControlInfoChanged() mut => VT.[Friend]OnControlInfoChanged(&this);

	public HRESULT LockInPlaceActive(BOOL fLock) mut => VT.[Friend]LockInPlaceActive(&this, fLock);

	public HRESULT GetExtendedControl(IDispatch** ppDisp) mut => VT.[Friend]GetExtendedControl(&this, ppDisp);

	public HRESULT TransformCoords(POINTL* pPtlHimetric, POINTF* pPtfContainer, XFORMCOORDS dwFlags) mut => VT.[Friend]TransformCoords(&this, pPtlHimetric, pPtfContainer, dwFlags);

	public HRESULT TranslateAccelerator(MSG* pMsg, KEYMODIFIERS grfModifiers) mut => VT.[Friend]TranslateAccelerator(&this, pMsg, grfModifiers);

	public HRESULT OnFocus(BOOL fGotFocus) mut => VT.[Friend]OnFocus(&this, fGotFocus);

	public HRESULT ShowPropertyFrame() mut => VT.[Friend]ShowPropertyFrame(&this);
}

[CRepr]struct IPropertyPage : IUnknown
{
	public new const Guid IID = .(0xb196b28d, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyPageSite* pPageSite) SetPageSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, RECT* pRect, BOOL bModal) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Deactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPPAGEINFO* pPageInfo) GetPageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cObjects, IUnknown** ppUnk) SetObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCmdShow) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsPageDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Apply;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHelpDir) Help;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg) TranslateAccelerator;
	}


	public HRESULT SetPageSite(IPropertyPageSite* pPageSite) mut => VT.[Friend]SetPageSite(&this, pPageSite);

	public HRESULT Activate(HWND hWndParent, RECT* pRect, BOOL bModal) mut => VT.[Friend]Activate(&this, hWndParent, pRect, bModal);

	public HRESULT Deactivate() mut => VT.[Friend]Deactivate(&this);

	public HRESULT GetPageInfo(PROPPAGEINFO* pPageInfo) mut => VT.[Friend]GetPageInfo(&this, pPageInfo);

	public HRESULT SetObjects(uint32 cObjects, IUnknown** ppUnk) mut => VT.[Friend]SetObjects(&this, cObjects, ppUnk);

	public HRESULT Show(uint32 nCmdShow) mut => VT.[Friend]Show(&this, nCmdShow);

	public HRESULT Move(RECT* pRect) mut => VT.[Friend]Move(&this, pRect);

	public HRESULT IsPageDirty() mut => VT.[Friend]IsPageDirty(&this);

	public HRESULT Apply() mut => VT.[Friend]Apply(&this);

	public HRESULT Help(PWSTR pszHelpDir) mut => VT.[Friend]Help(&this, pszHelpDir);

	public HRESULT TranslateAccelerator(MSG* pMsg) mut => VT.[Friend]TranslateAccelerator(&this, pMsg);
}

[CRepr]struct IPropertyPage2 : IPropertyPage
{
	public new const Guid IID = .(0x01e44665, 0x24ac, 0x101b, 0x84, 0xed, 0x08, 0x00, 0x2b, 0x2e, 0xc7, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyPage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID) EditProperty;
	}


	public HRESULT EditProperty(int32 dispID) mut => VT.[Friend]EditProperty(&this, dispID);
}

[CRepr]struct IPropertyPageSite : IUnknown
{
	public new const Guid IID = .(0xb196b28c, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPPAGESTATUS dwFlags) OnStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLocaleID) GetLocaleID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) GetPageContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg) TranslateAccelerator;
	}


	public HRESULT OnStatusChange(PROPPAGESTATUS dwFlags) mut => VT.[Friend]OnStatusChange(&this, dwFlags);

	public HRESULT GetLocaleID(uint32* pLocaleID) mut => VT.[Friend]GetLocaleID(&this, pLocaleID);

	public HRESULT GetPageContainer(IUnknown** ppUnk) mut => VT.[Friend]GetPageContainer(&this, ppUnk);

	public HRESULT TranslateAccelerator(MSG* pMsg) mut => VT.[Friend]TranslateAccelerator(&this, pMsg);
}

[CRepr]struct IPropertyNotifySink : IUnknown
{
	public new const Guid IID = .(0x9bfbbc02, 0xeff1, 0x101a, 0x84, 0xed, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID) OnChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID) OnRequestEdit;
	}


	public HRESULT OnChanged(int32 dispID) mut => VT.[Friend]OnChanged(&this, dispID);

	public HRESULT OnRequestEdit(int32 dispID) mut => VT.[Friend]OnRequestEdit(&this, dispID);
}

[CRepr]struct ISpecifyPropertyPages : IUnknown
{
	public new const Guid IID = .(0xb196b28b, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CAUUID* pPages) GetPages;
	}


	public HRESULT GetPages(CAUUID* pPages) mut => VT.[Friend]GetPages(&this, pPages);
}

[CRepr]struct IPersistPropertyBag : IPersist
{
	public new const Guid IID = .(0x37d84f60, 0x42cb, 0x11ce, 0x81, 0x35, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag* pPropBag, IErrorLog* pErrorLog) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag* pPropBag, BOOL fClearDirty, BOOL fSaveAllProperties) Save;
	}


	public HRESULT InitNew() mut => VT.[Friend]InitNew(&this);

	public HRESULT Load(IPropertyBag* pPropBag, IErrorLog* pErrorLog) mut => VT.[Friend]Load(&this, pPropBag, pErrorLog);

	public HRESULT Save(IPropertyBag* pPropBag, BOOL fClearDirty, BOOL fSaveAllProperties) mut => VT.[Friend]Save(&this, pPropBag, fClearDirty, fSaveAllProperties);
}

[CRepr]struct ISimpleFrameSite : IUnknown
{
	public new const Guid IID = .(0x742b0e01, 0x14e6, 0x101b, 0x91, 0x4e, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, uint32 msg, WPARAM wp, LPARAM lp, LRESULT* plResult, uint32* pdwCookie) PreMessageFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, uint32 msg, WPARAM wp, LPARAM lp, LRESULT* plResult, uint32 dwCookie) PostMessageFilter;
	}


	public HRESULT PreMessageFilter(HWND hWnd, uint32 msg, WPARAM wp, LPARAM lp, LRESULT* plResult, uint32* pdwCookie) mut => VT.[Friend]PreMessageFilter(&this, hWnd, msg, wp, lp, plResult, pdwCookie);

	public HRESULT PostMessageFilter(HWND hWnd, uint32 msg, WPARAM wp, LPARAM lp, LRESULT* plResult, uint32 dwCookie) mut => VT.[Friend]PostMessageFilter(&this, hWnd, msg, wp, lp, plResult, dwCookie);
}

[CRepr]struct IFont : IUnknown
{
	public new const Guid IID = .(0xbef6e002, 0xa874, 0x101a, 0x8b, 0xba, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CY* pSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CY size) put_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pBold) get_Bold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bold) put_Bold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pItalic) get_Italic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL italic) put_Italic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pUnderline) get_Underline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL underline) put_Underline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pStrikethrough) get_Strikethrough;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL strikethrough) put_Strikethrough;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pWeight) get_Weight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 weight) put_Weight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pCharset) get_Charset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 charset) put_Charset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HFONT* phFont) get_hFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFont** ppFont) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFont* pFontOther) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cyLogical, int32 cyHimetric) SetRatio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TEXTMETRICW* pTM) QueryTextMetrics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HFONT hFont) AddRefHfont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HFONT hFont) ReleaseHfont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC) SetHdc;
	}


	public HRESULT get_Name(BSTR* pName) mut => VT.[Friend]get_Name(&this, pName);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Size(CY* pSize) mut => VT.[Friend]get_Size(&this, pSize);

	public HRESULT put_Size(CY size) mut => VT.[Friend]put_Size(&this, size);

	public HRESULT get_Bold(BOOL* pBold) mut => VT.[Friend]get_Bold(&this, pBold);

	public HRESULT put_Bold(BOOL bold) mut => VT.[Friend]put_Bold(&this, bold);

	public HRESULT get_Italic(BOOL* pItalic) mut => VT.[Friend]get_Italic(&this, pItalic);

	public HRESULT put_Italic(BOOL italic) mut => VT.[Friend]put_Italic(&this, italic);

	public HRESULT get_Underline(BOOL* pUnderline) mut => VT.[Friend]get_Underline(&this, pUnderline);

	public HRESULT put_Underline(BOOL underline) mut => VT.[Friend]put_Underline(&this, underline);

	public HRESULT get_Strikethrough(BOOL* pStrikethrough) mut => VT.[Friend]get_Strikethrough(&this, pStrikethrough);

	public HRESULT put_Strikethrough(BOOL strikethrough) mut => VT.[Friend]put_Strikethrough(&this, strikethrough);

	public HRESULT get_Weight(int16* pWeight) mut => VT.[Friend]get_Weight(&this, pWeight);

	public HRESULT put_Weight(int16 weight) mut => VT.[Friend]put_Weight(&this, weight);

	public HRESULT get_Charset(int16* pCharset) mut => VT.[Friend]get_Charset(&this, pCharset);

	public HRESULT put_Charset(int16 charset) mut => VT.[Friend]put_Charset(&this, charset);

	public HRESULT get_hFont(HFONT* phFont) mut => VT.[Friend]get_hFont(&this, phFont);

	public HRESULT Clone(IFont** ppFont) mut => VT.[Friend]Clone(&this, ppFont);

	public HRESULT IsEqual(IFont* pFontOther) mut => VT.[Friend]IsEqual(&this, pFontOther);

	public HRESULT SetRatio(int32 cyLogical, int32 cyHimetric) mut => VT.[Friend]SetRatio(&this, cyLogical, cyHimetric);

	public HRESULT QueryTextMetrics(TEXTMETRICW* pTM) mut => VT.[Friend]QueryTextMetrics(&this, pTM);

	public HRESULT AddRefHfont(HFONT hFont) mut => VT.[Friend]AddRefHfont(&this, hFont);

	public HRESULT ReleaseHfont(HFONT hFont) mut => VT.[Friend]ReleaseHfont(&this, hFont);

	public HRESULT SetHdc(HDC hDC) mut => VT.[Friend]SetHdc(&this, hDC);
}

[CRepr]struct IPicture : IUnknown
{
	public new const Guid IID = .(0x7bf80980, 0xbf32, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* phPal) get_hPal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pWidth) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pHeight) get_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, int32 x, int32 y, int32 cx, int32 cy, int32 xSrc, int32 ySrc, int32 cxSrc, int32 cySrc, RECT* pRcWBounds) Render;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hPal) set_hPal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* phDC) get_CurDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDCIn, HDC* phDCOut, uint32* phBmpOut) SelectPicture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pKeep) get_KeepOriginalFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL keep) put_KeepOriginalFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PictureChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, BOOL fSaveMemCopy, int32* pCbSize) SaveAsFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pDwAttr) get_Attributes;
	}


	public HRESULT get_Handle(uint32* pHandle) mut => VT.[Friend]get_Handle(&this, pHandle);

	public HRESULT get_hPal(uint32* phPal) mut => VT.[Friend]get_hPal(&this, phPal);

	public HRESULT get_Type(int16* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT get_Width(int32* pWidth) mut => VT.[Friend]get_Width(&this, pWidth);

	public HRESULT get_Height(int32* pHeight) mut => VT.[Friend]get_Height(&this, pHeight);

	public HRESULT Render(HDC hDC, int32 x, int32 y, int32 cx, int32 cy, int32 xSrc, int32 ySrc, int32 cxSrc, int32 cySrc, RECT* pRcWBounds) mut => VT.[Friend]Render(&this, hDC, x, y, cx, cy, xSrc, ySrc, cxSrc, cySrc, pRcWBounds);

	public HRESULT set_hPal(uint32 hPal) mut => VT.[Friend]set_hPal(&this, hPal);

	public HRESULT get_CurDC(HDC* phDC) mut => VT.[Friend]get_CurDC(&this, phDC);

	public HRESULT SelectPicture(HDC hDCIn, HDC* phDCOut, uint32* phBmpOut) mut => VT.[Friend]SelectPicture(&this, hDCIn, phDCOut, phBmpOut);

	public HRESULT get_KeepOriginalFormat(BOOL* pKeep) mut => VT.[Friend]get_KeepOriginalFormat(&this, pKeep);

	public HRESULT put_KeepOriginalFormat(BOOL keep) mut => VT.[Friend]put_KeepOriginalFormat(&this, keep);

	public HRESULT PictureChanged() mut => VT.[Friend]PictureChanged(&this);

	public HRESULT SaveAsFile(IStream* pStream, BOOL fSaveMemCopy, int32* pCbSize) mut => VT.[Friend]SaveAsFile(&this, pStream, fSaveMemCopy, pCbSize);

	public HRESULT get_Attributes(uint32* pDwAttr) mut => VT.[Friend]get_Attributes(&this, pDwAttr);
}

[CRepr]struct IPicture2 : IUnknown
{
	public new const Guid IID = .(0xf5185dd8, 0x2012, 0x4b0b, 0xaa, 0xd9, 0xf0, 0x52, 0xc6, 0xbd, 0x48, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phPal) get_hPal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pWidth) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pHeight) get_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, int32 x, int32 y, int32 cx, int32 cy, int32 xSrc, int32 ySrc, int32 cxSrc, int32 cySrc, RECT* pRcWBounds) Render;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hPal) set_hPal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* phDC) get_CurDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDCIn, HDC* phDCOut, uint* phBmpOut) SelectPicture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pKeep) get_KeepOriginalFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL keep) put_KeepOriginalFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PictureChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, BOOL fSaveMemCopy, int32* pCbSize) SaveAsFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pDwAttr) get_Attributes;
	}


	public HRESULT get_Handle(uint* pHandle) mut => VT.[Friend]get_Handle(&this, pHandle);

	public HRESULT get_hPal(uint* phPal) mut => VT.[Friend]get_hPal(&this, phPal);

	public HRESULT get_Type(int16* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT get_Width(int32* pWidth) mut => VT.[Friend]get_Width(&this, pWidth);

	public HRESULT get_Height(int32* pHeight) mut => VT.[Friend]get_Height(&this, pHeight);

	public HRESULT Render(HDC hDC, int32 x, int32 y, int32 cx, int32 cy, int32 xSrc, int32 ySrc, int32 cxSrc, int32 cySrc, RECT* pRcWBounds) mut => VT.[Friend]Render(&this, hDC, x, y, cx, cy, xSrc, ySrc, cxSrc, cySrc, pRcWBounds);

	public HRESULT set_hPal(uint hPal) mut => VT.[Friend]set_hPal(&this, hPal);

	public HRESULT get_CurDC(HDC* phDC) mut => VT.[Friend]get_CurDC(&this, phDC);

	public HRESULT SelectPicture(HDC hDCIn, HDC* phDCOut, uint* phBmpOut) mut => VT.[Friend]SelectPicture(&this, hDCIn, phDCOut, phBmpOut);

	public HRESULT get_KeepOriginalFormat(BOOL* pKeep) mut => VT.[Friend]get_KeepOriginalFormat(&this, pKeep);

	public HRESULT put_KeepOriginalFormat(BOOL keep) mut => VT.[Friend]put_KeepOriginalFormat(&this, keep);

	public HRESULT PictureChanged() mut => VT.[Friend]PictureChanged(&this);

	public HRESULT SaveAsFile(IStream* pStream, BOOL fSaveMemCopy, int32* pCbSize) mut => VT.[Friend]SaveAsFile(&this, pStream, fSaveMemCopy, pCbSize);

	public HRESULT get_Attributes(uint32* pDwAttr) mut => VT.[Friend]get_Attributes(&this, pDwAttr);
}

[CRepr]struct IFontEventsDisp : IDispatch
{
	public new const Guid IID = .(0x4ef6100a, 0xaf88, 0x11d0, 0x98, 0x46, 0x00, 0xc0, 0x4f, 0xc2, 0x99, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IFontDisp : IDispatch
{
	public new const Guid IID = .(0xbef6e003, 0xa874, 0x101a, 0x8b, 0xba, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IPictureDisp : IDispatch
{
	public new const Guid IID = .(0x7bf80981, 0xbf32, 0x101a, 0x8b, 0xbb, 0x00, 0xaa, 0x00, 0x30, 0x0c, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IOleInPlaceObjectWindowless : IOleInPlaceObject
{
	public new const Guid IID = .(0x1c2056cc, 0x5ef4, 0x101b, 0x8b, 0xc8, 0x00, 0xaa, 0x00, 0x3e, 0x3b, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleInPlaceObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msg, WPARAM wParam, LPARAM lParam, LRESULT* plResult) OnWindowMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDropTarget** ppDropTarget) GetDropTarget;
	}


	public HRESULT OnWindowMessage(uint32 msg, WPARAM wParam, LPARAM lParam, LRESULT* plResult) mut => VT.[Friend]OnWindowMessage(&this, msg, wParam, lParam, plResult);

	public HRESULT GetDropTarget(IDropTarget** ppDropTarget) mut => VT.[Friend]GetDropTarget(&this, ppDropTarget);
}

[CRepr]struct IOleInPlaceSiteEx : IOleInPlaceSite
{
	public new const Guid IID = .(0x9c2cad80, 0x3424, 0x11cf, 0xb6, 0x70, 0x00, 0xaa, 0x00, 0x4c, 0xd6, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleInPlaceSite.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfNoRedraw, uint32 dwFlags) OnInPlaceActivateEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fNoRedraw) OnInPlaceDeactivateEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestUIActivate;
	}


	public HRESULT OnInPlaceActivateEx(BOOL* pfNoRedraw, uint32 dwFlags) mut => VT.[Friend]OnInPlaceActivateEx(&this, pfNoRedraw, dwFlags);

	public HRESULT OnInPlaceDeactivateEx(BOOL fNoRedraw) mut => VT.[Friend]OnInPlaceDeactivateEx(&this, fNoRedraw);

	public HRESULT RequestUIActivate() mut => VT.[Friend]RequestUIActivate(&this);
}

[CRepr]struct IOleInPlaceSiteWindowless : IOleInPlaceSiteEx
{
	public new const Guid IID = .(0x922eada0, 0x3424, 0x11cf, 0xb6, 0x70, 0x00, 0xaa, 0x00, 0x4c, 0xd6, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleInPlaceSiteEx.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CanWindowlessActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetCapture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fCapture) SetCapture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFocus) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect, uint32 grfFlags, HDC* phDC) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC) ReleaseDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect, BOOL fErase) InvalidateRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRGN hRGN, BOOL fErase) InvalidateRgn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dx, int32 dy, RECT* pRectScroll, RECT* pRectClip) ScrollRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) AdjustRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msg, WPARAM wParam, LPARAM lParam, LRESULT* plResult) OnDefWindowMessage;
	}


	public HRESULT CanWindowlessActivate() mut => VT.[Friend]CanWindowlessActivate(&this);

	public HRESULT GetCapture() mut => VT.[Friend]GetCapture(&this);

	public HRESULT SetCapture(BOOL fCapture) mut => VT.[Friend]SetCapture(&this, fCapture);

	public HRESULT GetFocus() mut => VT.[Friend]GetFocus(&this);

	public HRESULT SetFocus(BOOL fFocus) mut => VT.[Friend]SetFocus(&this, fFocus);

	public HRESULT GetDC(RECT* pRect, uint32 grfFlags, HDC* phDC) mut => VT.[Friend]GetDC(&this, pRect, grfFlags, phDC);

	public HRESULT ReleaseDC(HDC hDC) mut => VT.[Friend]ReleaseDC(&this, hDC);

	public HRESULT InvalidateRect(RECT* pRect, BOOL fErase) mut => VT.[Friend]InvalidateRect(&this, pRect, fErase);

	public HRESULT InvalidateRgn(HRGN hRGN, BOOL fErase) mut => VT.[Friend]InvalidateRgn(&this, hRGN, fErase);

	public HRESULT ScrollRect(int32 dx, int32 dy, RECT* pRectScroll, RECT* pRectClip) mut => VT.[Friend]ScrollRect(&this, dx, dy, pRectScroll, pRectClip);

	public HRESULT AdjustRect(RECT* prc) mut => VT.[Friend]AdjustRect(&this, prc);

	public HRESULT OnDefWindowMessage(uint32 msg, WPARAM wParam, LPARAM lParam, LRESULT* plResult) mut => VT.[Friend]OnDefWindowMessage(&this, msg, wParam, lParam, plResult);
}

[CRepr]struct IViewObjectEx : IViewObject2
{
	public new const Guid IID = .(0x3af24292, 0x0c96, 0x11ce, 0xa0, 0xcf, 0x00, 0xaa, 0x00, 0x60, 0x0a, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IViewObject2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAspect, RECTL* pRect) GetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetViewStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAspect, RECT* pRectBounds, POINT ptlLoc, int32 lCloseHint, uint32* pHitResult) QueryHitPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAspect, RECT* pRectBounds, RECT* pRectLoc, int32 lCloseHint, uint32* pHitResult) QueryHitRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwAspect, int32 lindex, DVTARGETDEVICE* ptd, HDC hicTargetDev, DVEXTENTINFO* pExtentInfo, SIZE* pSizel) GetNaturalExtent;
	}


	public HRESULT GetRect(uint32 dwAspect, RECTL* pRect) mut => VT.[Friend]GetRect(&this, dwAspect, pRect);

	public HRESULT GetViewStatus(uint32* pdwStatus) mut => VT.[Friend]GetViewStatus(&this, pdwStatus);

	public HRESULT QueryHitPoint(uint32 dwAspect, RECT* pRectBounds, POINT ptlLoc, int32 lCloseHint, uint32* pHitResult) mut => VT.[Friend]QueryHitPoint(&this, dwAspect, pRectBounds, ptlLoc, lCloseHint, pHitResult);

	public HRESULT QueryHitRect(uint32 dwAspect, RECT* pRectBounds, RECT* pRectLoc, int32 lCloseHint, uint32* pHitResult) mut => VT.[Friend]QueryHitRect(&this, dwAspect, pRectBounds, pRectLoc, lCloseHint, pHitResult);

	public HRESULT GetNaturalExtent(DVASPECT dwAspect, int32 lindex, DVTARGETDEVICE* ptd, HDC hicTargetDev, DVEXTENTINFO* pExtentInfo, SIZE* pSizel) mut => VT.[Friend]GetNaturalExtent(&this, dwAspect, lindex, ptd, hicTargetDev, pExtentInfo, pSizel);
}

[CRepr]struct IOleUndoUnit : IUnknown
{
	public new const Guid IID = .(0x894ad3b0, 0xef97, 0x11ce, 0x9b, 0xc9, 0x00, 0xaa, 0x00, 0x60, 0x8e, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoManager* pUndoManager) Do;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstr) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pClsid, int32* plID) GetUnitType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnNextAdd;
	}


	public HRESULT Do(IOleUndoManager* pUndoManager) mut => VT.[Friend]Do(&this, pUndoManager);

	public HRESULT GetDescription(BSTR* pBstr) mut => VT.[Friend]GetDescription(&this, pBstr);

	public HRESULT GetUnitType(Guid* pClsid, int32* plID) mut => VT.[Friend]GetUnitType(&this, pClsid, plID);

	public HRESULT OnNextAdd() mut => VT.[Friend]OnNextAdd(&this);
}

[CRepr]struct IOleParentUndoUnit : IOleUndoUnit
{
	public new const Guid IID = .(0xa1faf330, 0xef97, 0x11ce, 0x9b, 0xc9, 0x00, 0xaa, 0x00, 0x60, 0x8e, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleUndoUnit.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleParentUndoUnit* pPUU) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleParentUndoUnit* pPUU, BOOL fCommit) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoUnit* pUU) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoUnit* pUU) FindUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwState) GetParentState;
	}


	public HRESULT Open(IOleParentUndoUnit* pPUU) mut => VT.[Friend]Open(&this, pPUU);

	public HRESULT Close(IOleParentUndoUnit* pPUU, BOOL fCommit) mut => VT.[Friend]Close(&this, pPUU, fCommit);

	public HRESULT Add(IOleUndoUnit* pUU) mut => VT.[Friend]Add(&this, pUU);

	public HRESULT FindUnit(IOleUndoUnit* pUU) mut => VT.[Friend]FindUnit(&this, pUU);

	public HRESULT GetParentState(uint32* pdwState) mut => VT.[Friend]GetParentState(&this, pdwState);
}

[CRepr]struct IEnumOleUndoUnits : IUnknown
{
	public new const Guid IID = .(0xb3e7c340, 0xef97, 0x11ce, 0x9b, 0xc9, 0x00, 0xaa, 0x00, 0x60, 0x8e, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt, IOleUndoUnit** rgElt, uint32* pcEltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOleUndoUnits** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cElt, IOleUndoUnit** rgElt, uint32* pcEltFetched) mut => VT.[Friend]Next(&this, cElt, rgElt, pcEltFetched);

	public HRESULT Skip(uint32 cElt) mut => VT.[Friend]Skip(&this, cElt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumOleUndoUnits** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IOleUndoManager : IUnknown
{
	public new const Guid IID = .(0xd001f200, 0xef97, 0x11ce, 0x9b, 0xc9, 0x00, 0xaa, 0x00, 0x60, 0x8e, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleParentUndoUnit* pPUU) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleParentUndoUnit* pPUU, BOOL fCommit) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoUnit* pUU) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwState) GetOpenParentState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoUnit* pUU) DiscardFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoUnit* pUU) UndoTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleUndoUnit* pUU) RedoTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOleUndoUnits** ppEnum) EnumUndoable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOleUndoUnits** ppEnum) EnumRedoable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstr) GetLastUndoDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstr) GetLastRedoDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) Enable;
	}


	public HRESULT Open(IOleParentUndoUnit* pPUU) mut => VT.[Friend]Open(&this, pPUU);

	public HRESULT Close(IOleParentUndoUnit* pPUU, BOOL fCommit) mut => VT.[Friend]Close(&this, pPUU, fCommit);

	public HRESULT Add(IOleUndoUnit* pUU) mut => VT.[Friend]Add(&this, pUU);

	public HRESULT GetOpenParentState(uint32* pdwState) mut => VT.[Friend]GetOpenParentState(&this, pdwState);

	public HRESULT DiscardFrom(IOleUndoUnit* pUU) mut => VT.[Friend]DiscardFrom(&this, pUU);

	public HRESULT UndoTo(IOleUndoUnit* pUU) mut => VT.[Friend]UndoTo(&this, pUU);

	public HRESULT RedoTo(IOleUndoUnit* pUU) mut => VT.[Friend]RedoTo(&this, pUU);

	public HRESULT EnumUndoable(IEnumOleUndoUnits** ppEnum) mut => VT.[Friend]EnumUndoable(&this, ppEnum);

	public HRESULT EnumRedoable(IEnumOleUndoUnits** ppEnum) mut => VT.[Friend]EnumRedoable(&this, ppEnum);

	public HRESULT GetLastUndoDescription(BSTR* pBstr) mut => VT.[Friend]GetLastUndoDescription(&this, pBstr);

	public HRESULT GetLastRedoDescription(BSTR* pBstr) mut => VT.[Friend]GetLastRedoDescription(&this, pBstr);

	public HRESULT Enable(BOOL fEnable) mut => VT.[Friend]Enable(&this, fEnable);
}

[CRepr]struct IPointerInactive : IUnknown
{
	public new const Guid IID = .(0x55980ba0, 0x35aa, 0x11cf, 0xb6, 0x71, 0x00, 0xaa, 0x00, 0x4c, 0xd6, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINTERINACTIVE* pdwPolicy) GetActivationPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRectBounds, int32 x, int32 y, uint32 grfKeyState) OnInactiveMouseMove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRectBounds, int32 x, int32 y, uint32 dwMouseMsg, BOOL fSetAlways) OnInactiveSetCursor;
	}


	public HRESULT GetActivationPolicy(POINTERINACTIVE* pdwPolicy) mut => VT.[Friend]GetActivationPolicy(&this, pdwPolicy);

	public HRESULT OnInactiveMouseMove(RECT* pRectBounds, int32 x, int32 y, uint32 grfKeyState) mut => VT.[Friend]OnInactiveMouseMove(&this, pRectBounds, x, y, grfKeyState);

	public HRESULT OnInactiveSetCursor(RECT* pRectBounds, int32 x, int32 y, uint32 dwMouseMsg, BOOL fSetAlways) mut => VT.[Friend]OnInactiveSetCursor(&this, pRectBounds, x, y, dwMouseMsg, fSetAlways);
}

[CRepr]struct IObjectWithSite : IUnknown
{
	public new const Guid IID = .(0xfc4801a3, 0x2ba9, 0x11cf, 0xa2, 0x29, 0x00, 0xaa, 0x00, 0x3d, 0x73, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkSite) SetSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvSite) GetSite;
	}


	public HRESULT SetSite(IUnknown* pUnkSite) mut => VT.[Friend]SetSite(&this, pUnkSite);

	public HRESULT GetSite(in Guid riid, void** ppvSite) mut => VT.[Friend]GetSite(&this, riid, ppvSite);
}

[CRepr]struct IPerPropertyBrowsing : IUnknown
{
	public new const Guid IID = .(0x376bd3aa, 0x3845, 0x101b, 0x84, 0xed, 0x08, 0x00, 0x2b, 0x2e, 0xc7, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID, BSTR* pBstr) GetDisplayString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID, Guid* pClsid) MapPropertyToPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID, CALPOLESTR* pCaStringsOut, CADWORD* pCaCookiesOut) GetPredefinedStrings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispID, uint32 dwCookie, VARIANT* pVarOut) GetPredefinedValue;
	}


	public HRESULT GetDisplayString(int32 dispID, BSTR* pBstr) mut => VT.[Friend]GetDisplayString(&this, dispID, pBstr);

	public HRESULT MapPropertyToPage(int32 dispID, Guid* pClsid) mut => VT.[Friend]MapPropertyToPage(&this, dispID, pClsid);

	public HRESULT GetPredefinedStrings(int32 dispID, CALPOLESTR* pCaStringsOut, CADWORD* pCaCookiesOut) mut => VT.[Friend]GetPredefinedStrings(&this, dispID, pCaStringsOut, pCaCookiesOut);

	public HRESULT GetPredefinedValue(int32 dispID, uint32 dwCookie, VARIANT* pVarOut) mut => VT.[Friend]GetPredefinedValue(&this, dispID, dwCookie, pVarOut);
}

[CRepr]struct IPersistPropertyBag2 : IPersist
{
	public new const Guid IID = .(0x22f55881, 0x280b, 0x11d0, 0xa8, 0xa9, 0x00, 0xa0, 0xc9, 0x0c, 0x20, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag2* pPropBag, IErrorLog* pErrLog) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag2* pPropBag, BOOL fClearDirty, BOOL fSaveAllProperties) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirty;
	}


	public HRESULT InitNew() mut => VT.[Friend]InitNew(&this);

	public HRESULT Load(IPropertyBag2* pPropBag, IErrorLog* pErrLog) mut => VT.[Friend]Load(&this, pPropBag, pErrLog);

	public HRESULT Save(IPropertyBag2* pPropBag, BOOL fClearDirty, BOOL fSaveAllProperties) mut => VT.[Friend]Save(&this, pPropBag, fClearDirty, fSaveAllProperties);

	public HRESULT IsDirty() mut => VT.[Friend]IsDirty(&this);
}

[CRepr]struct IAdviseSinkEx : IAdviseSink
{
	public new const Guid IID = .(0x3af24290, 0x0c96, 0x11ce, 0xa0, 0xcf, 0x00, 0xaa, 0x00, 0x60, 0x0a, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAdviseSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwViewStatus) OnViewStatusChange;
	}


	public void OnViewStatusChange(uint32 dwViewStatus) mut => VT.[Friend]OnViewStatusChange(&this, dwViewStatus);
}

[CRepr]struct IQuickActivate : IUnknown
{
	public new const Guid IID = .(0xcf51ed10, 0x62fe, 0x11cf, 0xbf, 0x86, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, QACONTAINER* pQaContainer, QACONTROL* pQaControl) QuickActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pSizel) SetContentExtent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pSizel) GetContentExtent;
	}


	public HRESULT QuickActivate(QACONTAINER* pQaContainer, QACONTROL* pQaControl) mut => VT.[Friend]QuickActivate(&this, pQaContainer, pQaControl);

	public HRESULT SetContentExtent(SIZE* pSizel) mut => VT.[Friend]SetContentExtent(&this, pSizel);

	public HRESULT GetContentExtent(SIZE* pSizel) mut => VT.[Friend]GetContentExtent(&this, pSizel);
}

[CRepr]struct IVBGetControl : IUnknown
{
	public new const Guid IID = .(0x40a050a0, 0x3c31, 0x101b, 0xa8, 0x2e, 0x08, 0x00, 0x2b, 0x2b, 0x23, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLECONTF dwOleContF, ENUM_CONTROLS_WHICH_FLAGS dwWhich, IEnumUnknown** ppenumUnk) EnumControls;
	}


	public HRESULT EnumControls(OLECONTF dwOleContF, ENUM_CONTROLS_WHICH_FLAGS dwWhich, IEnumUnknown** ppenumUnk) mut => VT.[Friend]EnumControls(&this, dwOleContF, dwWhich, ppenumUnk);
}

[CRepr]struct IGetOleObject : IUnknown
{
	public new const Guid IID = .(0x8a701da0, 0x4feb, 0x101b, 0xa8, 0x2e, 0x08, 0x00, 0x2b, 0x2b, 0x23, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvObj) GetOleObject;
	}


	public HRESULT GetOleObject(in Guid riid, void** ppvObj) mut => VT.[Friend]GetOleObject(&this, riid, ppvObj);
}

[CRepr]struct IVBFormat : IUnknown
{
	public new const Guid IID = .(0x9849fd60, 0x3768, 0x101b, 0x8d, 0x72, 0xae, 0x61, 0x64, 0xff, 0xe3, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* vData, BSTR bstrFormat, void* lpBuffer, uint16 cb, int32 lcid, int16 sFirstDayOfWeek, uint16 sFirstWeekOfYear, uint16* rcb) Format;
	}


	public HRESULT Format(VARIANT* vData, BSTR bstrFormat, void* lpBuffer, uint16 cb, int32 lcid, int16 sFirstDayOfWeek, uint16 sFirstWeekOfYear, uint16* rcb) mut => VT.[Friend]Format(&this, vData, bstrFormat, lpBuffer, cb, lcid, sFirstDayOfWeek, sFirstWeekOfYear, rcb);
}

[CRepr]struct IGetVBAObject : IUnknown
{
	public new const Guid IID = .(0x91733a60, 0x3f4c, 0x101b, 0xa3, 0xf6, 0x00, 0xaa, 0x00, 0x34, 0xe4, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvObj, uint32 dwReserved) GetObject;
	}


	public HRESULT GetObject(in Guid riid, void** ppvObj, uint32 dwReserved) mut => VT.[Friend]GetObject(&this, riid, ppvObj, dwReserved);
}

[CRepr]struct IOleDocument : IUnknown
{
	public new const Guid IID = .(0xb722bcc5, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceSite* pIPSite, IStream* pstm, uint32 dwReserved, IOleDocumentView** ppView) CreateView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetDocMiscStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOleDocumentViews** ppEnum, IOleDocumentView** ppView) EnumViews;
	}


	public HRESULT CreateView(IOleInPlaceSite* pIPSite, IStream* pstm, uint32 dwReserved, IOleDocumentView** ppView) mut => VT.[Friend]CreateView(&this, pIPSite, pstm, dwReserved, ppView);

	public HRESULT GetDocMiscStatus(uint32* pdwStatus) mut => VT.[Friend]GetDocMiscStatus(&this, pdwStatus);

	public HRESULT EnumViews(IEnumOleDocumentViews** ppEnum, IOleDocumentView** ppView) mut => VT.[Friend]EnumViews(&this, ppEnum, ppView);
}

[CRepr]struct IOleDocumentSite : IUnknown
{
	public new const Guid IID = .(0xb722bcc7, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleDocumentView* pViewToActivate) ActivateMe;
	}


	public HRESULT ActivateMe(IOleDocumentView* pViewToActivate) mut => VT.[Friend]ActivateMe(&this, pViewToActivate);
}

[CRepr]struct IOleDocumentView : IUnknown
{
	public new const Guid IID = .(0xb722bcc6, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceSite* pIPSite) SetInPlaceSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceSite** ppIPSite) GetInPlaceSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) GetDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcView) SetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcView) GetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcView, RECT* prcHScroll, RECT* prcVScroll, RECT* prcSizeBox) SetRectComplex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUIActivate) UIActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved) CloseView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstm) SaveViewState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstm) ApplyViewState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceSite* pIPSiteNew, IOleDocumentView** ppViewNew) Clone;
	}


	public HRESULT SetInPlaceSite(IOleInPlaceSite* pIPSite) mut => VT.[Friend]SetInPlaceSite(&this, pIPSite);

	public HRESULT GetInPlaceSite(IOleInPlaceSite** ppIPSite) mut => VT.[Friend]GetInPlaceSite(&this, ppIPSite);

	public HRESULT GetDocument(IUnknown** ppunk) mut => VT.[Friend]GetDocument(&this, ppunk);

	public HRESULT SetRect(RECT* prcView) mut => VT.[Friend]SetRect(&this, prcView);

	public HRESULT GetRect(RECT* prcView) mut => VT.[Friend]GetRect(&this, prcView);

	public HRESULT SetRectComplex(RECT* prcView, RECT* prcHScroll, RECT* prcVScroll, RECT* prcSizeBox) mut => VT.[Friend]SetRectComplex(&this, prcView, prcHScroll, prcVScroll, prcSizeBox);

	public HRESULT Show(BOOL fShow) mut => VT.[Friend]Show(&this, fShow);

	public HRESULT UIActivate(BOOL fUIActivate) mut => VT.[Friend]UIActivate(&this, fUIActivate);

	public HRESULT Open() mut => VT.[Friend]Open(&this);

	public HRESULT CloseView(uint32 dwReserved) mut => VT.[Friend]CloseView(&this, dwReserved);

	public HRESULT SaveViewState(IStream* pstm) mut => VT.[Friend]SaveViewState(&this, pstm);

	public HRESULT ApplyViewState(IStream* pstm) mut => VT.[Friend]ApplyViewState(&this, pstm);

	public HRESULT Clone(IOleInPlaceSite* pIPSiteNew, IOleDocumentView** ppViewNew) mut => VT.[Friend]Clone(&this, pIPSiteNew, ppViewNew);
}

[CRepr]struct IEnumOleDocumentViews : IUnknown
{
	public new const Guid IID = .(0xb722bcc8, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cViews, IOleDocumentView** rgpView, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cViews) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOleDocumentViews** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cViews, IOleDocumentView** rgpView, uint32* pcFetched) mut => VT.[Friend]Next(&this, cViews, rgpView, pcFetched);

	public HRESULT Skip(uint32 cViews) mut => VT.[Friend]Skip(&this, cViews);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumOleDocumentViews** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IContinueCallback : IUnknown
{
	public new const Guid IID = .(0xb722bcca, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FContinue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCntPrinted, int32 nCurPage, PWSTR pwszPrintStatus) FContinuePrinting;
	}


	public HRESULT FContinue() mut => VT.[Friend]FContinue(&this);

	public HRESULT FContinuePrinting(int32 nCntPrinted, int32 nCurPage, PWSTR pwszPrintStatus) mut => VT.[Friend]FContinuePrinting(&this, nCntPrinted, nCurPage, pwszPrintStatus);
}

[CRepr]struct IPrint : IUnknown
{
	public new const Guid IID = .(0xb722bcc9, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nFirstPage) SetInitialPageNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnFirstPage, int32* pcPages) GetPageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfFlags, DVTARGETDEVICE** pptd, PAGESET** ppPageSet, STGMEDIUM* pstgmOptions, IContinueCallback* pcallback, int32 nFirstPage, int32* pcPagesPrinted, int32* pnLastPage) Print;
	}


	public HRESULT SetInitialPageNum(int32 nFirstPage) mut => VT.[Friend]SetInitialPageNum(&this, nFirstPage);

	public HRESULT GetPageInfo(int32* pnFirstPage, int32* pcPages) mut => VT.[Friend]GetPageInfo(&this, pnFirstPage, pcPages);

	public HRESULT Print(uint32 grfFlags, DVTARGETDEVICE** pptd, PAGESET** ppPageSet, STGMEDIUM* pstgmOptions, IContinueCallback* pcallback, int32 nFirstPage, int32* pcPagesPrinted, int32* pnLastPage) mut => VT.[Friend]Print(&this, grfFlags, pptd, ppPageSet, pstgmOptions, pcallback, nFirstPage, pcPagesPrinted, pnLastPage);
}

[CRepr]struct IOleCommandTarget : IUnknown
{
	public new const Guid IID = .(0xb722bccb, 0x4e68, 0x101b, 0xa2, 0xbc, 0x00, 0xaa, 0x00, 0x40, 0x47, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidCmdGroup, uint32 cCmds, OLECMD* prgCmds, OLECMDTEXT* pCmdText) QueryStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidCmdGroup, uint32 nCmdID, uint32 nCmdexecopt, VARIANT* pvaIn, VARIANT* pvaOut) Exec;
	}


	public HRESULT QueryStatus(in Guid pguidCmdGroup, uint32 cCmds, OLECMD* prgCmds, OLECMDTEXT* pCmdText) mut => VT.[Friend]QueryStatus(&this, pguidCmdGroup, cCmds, prgCmds, pCmdText);

	public HRESULT Exec(in Guid pguidCmdGroup, uint32 nCmdID, uint32 nCmdexecopt, VARIANT* pvaIn, VARIANT* pvaOut) mut => VT.[Friend]Exec(&this, pguidCmdGroup, nCmdID, nCmdexecopt, pvaIn, pvaOut);
}

[CRepr]struct IZoomEvents : IUnknown
{
	public new const Guid IID = .(0x41b68150, 0x904c, 0x4e17, 0xa0, 0xba, 0xa4, 0x38, 0x18, 0x2e, 0x35, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulZoomPercent) OnZoomPercentChanged;
	}


	public HRESULT OnZoomPercentChanged(uint32 ulZoomPercent) mut => VT.[Friend]OnZoomPercentChanged(&this, ulZoomPercent);
}

[CRepr]struct IProtectFocus : IUnknown
{
	public new const Guid IID = .(0xd81f90a3, 0x8156, 0x44f7, 0xad, 0x28, 0x5a, 0xbb, 0x87, 0x00, 0x32, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAllow) AllowFocusChange;
	}


	public HRESULT AllowFocusChange(BOOL* pfAllow) mut => VT.[Friend]AllowFocusChange(&this, pfAllow);
}

[CRepr]struct IProtectedModeMenuServices : IUnknown
{
	public new const Guid IID = .(0x73c105ee, 0x9dff, 0x4a07, 0xb8, 0x3c, 0x7e, 0xff, 0x29, 0x0c, 0x26, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU* phMenu) CreateMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszModuleName, PWSTR pszMenuName, HMENU* phMenu) LoadMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszModuleName, uint16 wResourceID, HMENU* phMenu) LoadMenuID;
	}


	public HRESULT CreateMenu(HMENU* phMenu) mut => VT.[Friend]CreateMenu(&this, phMenu);

	public HRESULT LoadMenu(PWSTR pszModuleName, PWSTR pszMenuName, HMENU* phMenu) mut => VT.[Friend]LoadMenu(&this, pszModuleName, pszMenuName, phMenu);

	public HRESULT LoadMenuID(PWSTR pszModuleName, uint16 wResourceID, HMENU* phMenu) mut => VT.[Friend]LoadMenuID(&this, pszModuleName, wResourceID, phMenu);
}

[CRepr]struct IOleUILinkContainerW : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 dwLink) GetNextLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, uint32 dwUpdateOpt) SetLinkUpdateOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, uint32* lpdwUpdateOpt) GetLinkUpdateOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, PWSTR lpszDisplayName, uint32 lenFileName, uint32* pchEaten, BOOL fValidateSource) SetLinkSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, PWSTR* lplpszDisplayName, uint32* lplenFileName, PWSTR* lplpszFullLinkType, PWSTR* lplpszShortLinkType, BOOL* lpfSourceAvailable, BOOL* lpfIsSelected) GetLinkSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink) OpenLinkSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, BOOL fErrorMessage, BOOL fReserved) UpdateLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink) CancelLink;
	}


	public uint32 GetNextLink(uint32 dwLink) mut => VT.[Friend]GetNextLink(&this, dwLink);

	public HRESULT SetLinkUpdateOptions(uint32 dwLink, uint32 dwUpdateOpt) mut => VT.[Friend]SetLinkUpdateOptions(&this, dwLink, dwUpdateOpt);

	public HRESULT GetLinkUpdateOptions(uint32 dwLink, uint32* lpdwUpdateOpt) mut => VT.[Friend]GetLinkUpdateOptions(&this, dwLink, lpdwUpdateOpt);

	public HRESULT SetLinkSource(uint32 dwLink, PWSTR lpszDisplayName, uint32 lenFileName, uint32* pchEaten, BOOL fValidateSource) mut => VT.[Friend]SetLinkSource(&this, dwLink, lpszDisplayName, lenFileName, pchEaten, fValidateSource);

	public HRESULT GetLinkSource(uint32 dwLink, PWSTR* lplpszDisplayName, uint32* lplenFileName, PWSTR* lplpszFullLinkType, PWSTR* lplpszShortLinkType, BOOL* lpfSourceAvailable, BOOL* lpfIsSelected) mut => VT.[Friend]GetLinkSource(&this, dwLink, lplpszDisplayName, lplenFileName, lplpszFullLinkType, lplpszShortLinkType, lpfSourceAvailable, lpfIsSelected);

	public HRESULT OpenLinkSource(uint32 dwLink) mut => VT.[Friend]OpenLinkSource(&this, dwLink);

	public HRESULT UpdateLink(uint32 dwLink, BOOL fErrorMessage, BOOL fReserved) mut => VT.[Friend]UpdateLink(&this, dwLink, fErrorMessage, fReserved);

	public HRESULT CancelLink(uint32 dwLink) mut => VT.[Friend]CancelLink(&this, dwLink);
}

[CRepr]struct IOleUILinkContainerA : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 dwLink) GetNextLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, uint32 dwUpdateOpt) SetLinkUpdateOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, uint32* lpdwUpdateOpt) GetLinkUpdateOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, PSTR lpszDisplayName, uint32 lenFileName, uint32* pchEaten, BOOL fValidateSource) SetLinkSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, PSTR* lplpszDisplayName, uint32* lplenFileName, PSTR* lplpszFullLinkType, PSTR* lplpszShortLinkType, BOOL* lpfSourceAvailable, BOOL* lpfIsSelected) GetLinkSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink) OpenLinkSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, BOOL fErrorMessage, BOOL fReserved) UpdateLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink) CancelLink;
	}


	public uint32 GetNextLink(uint32 dwLink) mut => VT.[Friend]GetNextLink(&this, dwLink);

	public HRESULT SetLinkUpdateOptions(uint32 dwLink, uint32 dwUpdateOpt) mut => VT.[Friend]SetLinkUpdateOptions(&this, dwLink, dwUpdateOpt);

	public HRESULT GetLinkUpdateOptions(uint32 dwLink, uint32* lpdwUpdateOpt) mut => VT.[Friend]GetLinkUpdateOptions(&this, dwLink, lpdwUpdateOpt);

	public HRESULT SetLinkSource(uint32 dwLink, PSTR lpszDisplayName, uint32 lenFileName, uint32* pchEaten, BOOL fValidateSource) mut => VT.[Friend]SetLinkSource(&this, dwLink, lpszDisplayName, lenFileName, pchEaten, fValidateSource);

	public HRESULT GetLinkSource(uint32 dwLink, PSTR* lplpszDisplayName, uint32* lplenFileName, PSTR* lplpszFullLinkType, PSTR* lplpszShortLinkType, BOOL* lpfSourceAvailable, BOOL* lpfIsSelected) mut => VT.[Friend]GetLinkSource(&this, dwLink, lplpszDisplayName, lplenFileName, lplpszFullLinkType, lplpszShortLinkType, lpfSourceAvailable, lpfIsSelected);

	public HRESULT OpenLinkSource(uint32 dwLink) mut => VT.[Friend]OpenLinkSource(&this, dwLink);

	public HRESULT UpdateLink(uint32 dwLink, BOOL fErrorMessage, BOOL fReserved) mut => VT.[Friend]UpdateLink(&this, dwLink, fErrorMessage, fReserved);

	public HRESULT CancelLink(uint32 dwLink) mut => VT.[Friend]CancelLink(&this, dwLink);
}

[CRepr]struct IOleUIObjInfoW : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, uint32* lpdwObjSize, PWSTR* lplpszLabel, PWSTR* lplpszType, PWSTR* lplpszShortType, PWSTR* lplpszLocation) GetObjectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, Guid* lpClassID, uint16* lpwFormat, Guid* lpConvertDefaultClassID, Guid** lplpClsidExclude, uint32* lpcClsidExclude) GetConvertInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, in Guid clsidNew) ConvertObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, int* phMetaPict, uint32* pdvAspect, int32* pnCurrentScale) GetViewInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, int hMetaPict, uint32 dvAspect, int32 nCurrentScale, BOOL bRelativeToOrig) SetViewInfo;
	}


	public HRESULT GetObjectInfo(uint32 dwObject, uint32* lpdwObjSize, PWSTR* lplpszLabel, PWSTR* lplpszType, PWSTR* lplpszShortType, PWSTR* lplpszLocation) mut => VT.[Friend]GetObjectInfo(&this, dwObject, lpdwObjSize, lplpszLabel, lplpszType, lplpszShortType, lplpszLocation);

	public HRESULT GetConvertInfo(uint32 dwObject, Guid* lpClassID, uint16* lpwFormat, Guid* lpConvertDefaultClassID, Guid** lplpClsidExclude, uint32* lpcClsidExclude) mut => VT.[Friend]GetConvertInfo(&this, dwObject, lpClassID, lpwFormat, lpConvertDefaultClassID, lplpClsidExclude, lpcClsidExclude);

	public HRESULT ConvertObject(uint32 dwObject, in Guid clsidNew) mut => VT.[Friend]ConvertObject(&this, dwObject, clsidNew);

	public HRESULT GetViewInfo(uint32 dwObject, int* phMetaPict, uint32* pdvAspect, int32* pnCurrentScale) mut => VT.[Friend]GetViewInfo(&this, dwObject, phMetaPict, pdvAspect, pnCurrentScale);

	public HRESULT SetViewInfo(uint32 dwObject, int hMetaPict, uint32 dvAspect, int32 nCurrentScale, BOOL bRelativeToOrig) mut => VT.[Friend]SetViewInfo(&this, dwObject, hMetaPict, dvAspect, nCurrentScale, bRelativeToOrig);
}

[CRepr]struct IOleUIObjInfoA : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, uint32* lpdwObjSize, PSTR* lplpszLabel, PSTR* lplpszType, PSTR* lplpszShortType, PSTR* lplpszLocation) GetObjectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, Guid* lpClassID, uint16* lpwFormat, Guid* lpConvertDefaultClassID, Guid** lplpClsidExclude, uint32* lpcClsidExclude) GetConvertInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, in Guid clsidNew) ConvertObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, int* phMetaPict, uint32* pdvAspect, int32* pnCurrentScale) GetViewInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwObject, int hMetaPict, uint32 dvAspect, int32 nCurrentScale, BOOL bRelativeToOrig) SetViewInfo;
	}


	public HRESULT GetObjectInfo(uint32 dwObject, uint32* lpdwObjSize, PSTR* lplpszLabel, PSTR* lplpszType, PSTR* lplpszShortType, PSTR* lplpszLocation) mut => VT.[Friend]GetObjectInfo(&this, dwObject, lpdwObjSize, lplpszLabel, lplpszType, lplpszShortType, lplpszLocation);

	public HRESULT GetConvertInfo(uint32 dwObject, Guid* lpClassID, uint16* lpwFormat, Guid* lpConvertDefaultClassID, Guid** lplpClsidExclude, uint32* lpcClsidExclude) mut => VT.[Friend]GetConvertInfo(&this, dwObject, lpClassID, lpwFormat, lpConvertDefaultClassID, lplpClsidExclude, lpcClsidExclude);

	public HRESULT ConvertObject(uint32 dwObject, in Guid clsidNew) mut => VT.[Friend]ConvertObject(&this, dwObject, clsidNew);

	public HRESULT GetViewInfo(uint32 dwObject, int* phMetaPict, uint32* pdvAspect, int32* pnCurrentScale) mut => VT.[Friend]GetViewInfo(&this, dwObject, phMetaPict, pdvAspect, pnCurrentScale);

	public HRESULT SetViewInfo(uint32 dwObject, int hMetaPict, uint32 dvAspect, int32 nCurrentScale, BOOL bRelativeToOrig) mut => VT.[Friend]SetViewInfo(&this, dwObject, hMetaPict, dvAspect, nCurrentScale, bRelativeToOrig);
}

[CRepr]struct IOleUILinkInfoW : IOleUILinkContainerW
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleUILinkContainerW.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, FILETIME* lpLastUpdate) GetLastUpdate;
	}


	public HRESULT GetLastUpdate(uint32 dwLink, FILETIME* lpLastUpdate) mut => VT.[Friend]GetLastUpdate(&this, dwLink, lpLastUpdate);
}

[CRepr]struct IOleUILinkInfoA : IOleUILinkContainerA
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleUILinkContainerA.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLink, FILETIME* lpLastUpdate) GetLastUpdate;
	}


	public HRESULT GetLastUpdate(uint32 dwLink, FILETIME* lpLastUpdate) mut => VT.[Friend]GetLastUpdate(&this, dwLink, lpLastUpdate);
}

[CRepr]struct IDispatchEx : IDispatch
{
	public new const Guid IID = .(0xa6ef9860, 0xc720, 0x11d0, 0x93, 0x37, 0x00, 0xa0, 0xc9, 0x0d, 0xca, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, uint32 grfdex, int32* pid) GetDispID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 id, uint32 lcid, uint16 wFlags, DISPPARAMS* pdp, VARIANT* pvarRes, EXCEPINFO* pei, IServiceProvider* pspCaller) InvokeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, uint32 grfdex) DeleteMemberByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 id) DeleteMemberByDispID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 id, uint32 grfdexFetch, FDEX_PROP_FLAGS* pgrfdex) GetMemberProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 id, BSTR* pbstrName) GetMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfdex, int32 id, int32* pid) GetNextDispID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) GetNameSpaceParent;
	}


	public HRESULT GetDispID(BSTR bstrName, uint32 grfdex, int32* pid) mut => VT.[Friend]GetDispID(&this, bstrName, grfdex, pid);

	public HRESULT InvokeEx(int32 id, uint32 lcid, uint16 wFlags, DISPPARAMS* pdp, VARIANT* pvarRes, EXCEPINFO* pei, IServiceProvider* pspCaller) mut => VT.[Friend]InvokeEx(&this, id, lcid, wFlags, pdp, pvarRes, pei, pspCaller);

	public HRESULT DeleteMemberByName(BSTR bstrName, uint32 grfdex) mut => VT.[Friend]DeleteMemberByName(&this, bstrName, grfdex);

	public HRESULT DeleteMemberByDispID(int32 id) mut => VT.[Friend]DeleteMemberByDispID(&this, id);

	public HRESULT GetMemberProperties(int32 id, uint32 grfdexFetch, FDEX_PROP_FLAGS* pgrfdex) mut => VT.[Friend]GetMemberProperties(&this, id, grfdexFetch, pgrfdex);

	public HRESULT GetMemberName(int32 id, BSTR* pbstrName) mut => VT.[Friend]GetMemberName(&this, id, pbstrName);

	public HRESULT GetNextDispID(uint32 grfdex, int32 id, int32* pid) mut => VT.[Friend]GetNextDispID(&this, grfdex, id, pid);

	public HRESULT GetNameSpaceParent(IUnknown** ppunk) mut => VT.[Friend]GetNameSpaceParent(&this, ppunk);
}

[CRepr]struct IDispError : IUnknown
{
	public new const Guid IID = .(0xa6ef9861, 0xc720, 0x11d0, 0x93, 0x37, 0x00, 0xa0, 0xc9, 0x0d, 0xca, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidErrorType, IDispError** ppde) QueryErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispError** ppde) GetNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phr) GetHresult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSource) GetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFileName, uint32* pdwContext) GetHelpInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) GetDescription;
	}


	public HRESULT QueryErrorInfo(Guid guidErrorType, IDispError** ppde) mut => VT.[Friend]QueryErrorInfo(&this, guidErrorType, ppde);

	public HRESULT GetNext(IDispError** ppde) mut => VT.[Friend]GetNext(&this, ppde);

	public HRESULT GetHresult(HRESULT* phr) mut => VT.[Friend]GetHresult(&this, phr);

	public HRESULT GetSource(BSTR* pbstrSource) mut => VT.[Friend]GetSource(&this, pbstrSource);

	public HRESULT GetHelpInfo(BSTR* pbstrFileName, uint32* pdwContext) mut => VT.[Friend]GetHelpInfo(&this, pbstrFileName, pdwContext);

	public HRESULT GetDescription(BSTR* pbstrDescription) mut => VT.[Friend]GetDescription(&this, pbstrDescription);
}

[CRepr]struct IVariantChangeType : IUnknown
{
	public new const Guid IID = .(0xa6ef9862, 0xc720, 0x11d0, 0x93, 0x37, 0x00, 0xa0, 0xc9, 0x0d, 0xca, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDst, VARIANT* pvarSrc, uint32 lcid, VARENUM vtNew) ChangeType;
	}


	public HRESULT ChangeType(VARIANT* pvarDst, VARIANT* pvarSrc, uint32 lcid, VARENUM vtNew) mut => VT.[Friend]ChangeType(&this, pvarDst, pvarSrc, lcid, vtNew);
}

[CRepr]struct IObjectIdentity : IUnknown
{
	public new const Guid IID = .(0xca04b7e6, 0x0d21, 0x11d1, 0x8c, 0xc5, 0x00, 0xc0, 0x4f, 0xc2, 0xb0, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) IsEqualObject;
	}


	public HRESULT IsEqualObject(IUnknown* punk) mut => VT.[Friend]IsEqualObject(&this, punk);
}

[CRepr]struct ICanHandleException : IUnknown
{
	public new const Guid IID = .(0xc5598e60, 0xb307, 0x11d1, 0xb2, 0x7d, 0x00, 0x60, 0x08, 0xc3, 0xfb, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXCEPINFO* pExcepInfo, VARIANT* pvar) CanHandleException;
	}


	public HRESULT CanHandleException(EXCEPINFO* pExcepInfo, VARIANT* pvar) mut => VT.[Friend]CanHandleException(&this, pExcepInfo, pvar);
}

[CRepr]struct IProvideRuntimeContext : IUnknown
{
	public new const Guid IID = .(0x10e2414a, 0xec59, 0x49d2, 0xbc, 0x51, 0x5a, 0xdd, 0x2c, 0x36, 0xfe, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pdwContext, int16* pfExecutingGlobalCode) GetCurrentSourceContext;
	}


	public HRESULT GetCurrentSourceContext(uint* pdwContext, int16* pfExecutingGlobalCode) mut => VT.[Friend]GetCurrentSourceContext(&this, pdwContext, pfExecutingGlobalCode);
}

#endregion

#region Functions
public static
{
	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DosDateTimeToVariantTime(uint16 wDosDate, uint16 wDosTime, double* pvtime);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 VariantTimeToDosDateTime(double vtime, uint16* pwDosDate, uint16* pwDosTime);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SystemTimeToVariantTime(SYSTEMTIME* lpSystemTime, double* pvtime);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 VariantTimeToSystemTime(double vtime, SYSTEMTIME* lpSystemTime);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayAllocDescriptor(uint32 cDims, SAFEARRAY** ppsaOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayAllocDescriptorEx(VARENUM vt, uint32 cDims, SAFEARRAY** ppsaOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayAllocData(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SAFEARRAY* SafeArrayCreate(VARENUM vt, uint32 cDims, SAFEARRAYBOUND* rgsabound);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SAFEARRAY* SafeArrayCreateEx(VARENUM vt, uint32 cDims, SAFEARRAYBOUND* rgsabound, void* pvExtra);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayCopyData(SAFEARRAY* psaSource, SAFEARRAY* psaTarget);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SafeArrayReleaseDescriptor(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayDestroyDescriptor(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SafeArrayReleaseData(void* pData);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayDestroyData(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayAddRef(SAFEARRAY* psa, void** ppDataToRelease);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayDestroy(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayRedim(SAFEARRAY* psa, SAFEARRAYBOUND* psaboundNew);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SafeArrayGetDim(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SafeArrayGetElemsize(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayGetUBound(SAFEARRAY* psa, uint32 nDim, int32* plUbound);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayGetLBound(SAFEARRAY* psa, uint32 nDim, int32* plLbound);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayLock(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayUnlock(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayAccessData(SAFEARRAY* psa, void** ppvData);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayUnaccessData(SAFEARRAY* psa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayGetElement(SAFEARRAY* psa, int32* rgIndices, void* pv);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayPutElement(SAFEARRAY* psa, int32* rgIndices, void* pv);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayCopy(SAFEARRAY* psa, SAFEARRAY** ppsaOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayPtrOfIndex(SAFEARRAY* psa, int32* rgIndices, void** ppvData);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArraySetRecordInfo(SAFEARRAY* psa, IRecordInfo* prinfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayGetRecordInfo(SAFEARRAY* psa, IRecordInfo** prinfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArraySetIID(SAFEARRAY* psa, in Guid guid);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayGetIID(SAFEARRAY* psa, Guid* pguid);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SafeArrayGetVartype(SAFEARRAY* psa, VARENUM* pvt);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SAFEARRAY* SafeArrayCreateVector(VARENUM vt, int32 lLbound, uint32 cElements);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SAFEARRAY* SafeArrayCreateVectorEx(VARENUM vt, int32 lLbound, uint32 cElements, void* pvExtra);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void VariantInit(VARIANT* pvarg);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantClear(VARIANT* pvarg);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantCopy(VARIANT* pvargDest, VARIANT* pvargSrc);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantCopyInd(VARIANT* pvarDest, VARIANT* pvargSrc);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantChangeType(VARIANT* pvargDest, VARIANT* pvarSrc, uint16 wFlags, VARENUM vt);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantChangeTypeEx(VARIANT* pvargDest, VARIANT* pvarSrc, uint32 lcid, uint16 wFlags, VARENUM vt);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VectorFromBstr(BSTR bstr, SAFEARRAY** ppsa);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BstrFromVector(SAFEARRAY* psa, BSTR* pbstr);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromI2(int16 sIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromI4(int32 lIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromI8(int64 i64In, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromR4(float fltIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromR8(double dblIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromCy(CY cyIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromDate(double dateIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromDisp(IDispatch* pdispIn, uint32 lcid, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromBool(int16 boolIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromI1(CHAR cIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromUI2(uint16 uiIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromUI4(uint32 ulIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromUI8(uint64 ui64In, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI1FromDec(DECIMAL* pdecIn, uint8* pbOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromUI1(uint8 bIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromI4(int32 lIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromI8(int64 i64In, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromR4(float fltIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromR8(double dblIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromCy(CY cyIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromDate(double dateIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromDisp(IDispatch* pdispIn, uint32 lcid, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromBool(int16 boolIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromI1(CHAR cIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromUI2(uint16 uiIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromUI4(uint32 ulIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromUI8(uint64 ui64In, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI2FromDec(DECIMAL* pdecIn, int16* psOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromUI1(uint8 bIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromI2(int16 sIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromI8(int64 i64In, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromR4(float fltIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromR8(double dblIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromCy(CY cyIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromDate(double dateIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromDisp(IDispatch* pdispIn, uint32 lcid, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromBool(int16 boolIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromI1(CHAR cIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromUI2(uint16 uiIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromUI4(uint32 ulIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromUI8(uint64 ui64In, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI4FromDec(DECIMAL* pdecIn, int32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromUI1(uint8 bIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromI2(int16 sIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromR4(float fltIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromR8(double dblIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromCy(CY cyIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromDate(double dateIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromDisp(IDispatch* pdispIn, uint32 lcid, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromBool(int16 boolIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromI1(CHAR cIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromUI2(uint16 uiIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromUI4(uint32 ulIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromUI8(uint64 ui64In, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI8FromDec(DECIMAL* pdecIn, int64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromUI1(uint8 bIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromI2(int16 sIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromI4(int32 lIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromI8(int64 i64In, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromR8(double dblIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromCy(CY cyIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromDate(double dateIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromDisp(IDispatch* pdispIn, uint32 lcid, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromBool(int16 boolIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromI1(CHAR cIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromUI2(uint16 uiIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromUI4(uint32 ulIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromUI8(uint64 ui64In, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR4FromDec(DECIMAL* pdecIn, float* pfltOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromUI1(uint8 bIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromI2(int16 sIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromI4(int32 lIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromI8(int64 i64In, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromR4(float fltIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromCy(CY cyIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromDate(double dateIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromDisp(IDispatch* pdispIn, uint32 lcid, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromBool(int16 boolIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromI1(CHAR cIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromUI2(uint16 uiIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromUI4(uint32 ulIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromUI8(uint64 ui64In, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8FromDec(DECIMAL* pdecIn, double* pdblOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromUI1(uint8 bIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromI2(int16 sIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromI4(int32 lIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromI8(int64 i64In, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromR4(float fltIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromR8(double dblIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromCy(CY cyIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromDisp(IDispatch* pdispIn, uint32 lcid, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromBool(int16 boolIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromI1(CHAR cIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromUI2(uint16 uiIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromUI4(uint32 ulIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromUI8(uint64 ui64In, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromDec(DECIMAL* pdecIn, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromUI1(uint8 bIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromI2(int16 sIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromI4(int32 lIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromI8(int64 i64In, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromR4(float fltIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromR8(double dblIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromDate(double dateIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromDisp(IDispatch* pdispIn, uint32 lcid, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromBool(int16 boolIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromI1(CHAR cIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromUI2(uint16 uiIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromUI4(uint32 ulIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromUI8(uint64 ui64In, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFromDec(DECIMAL* pdecIn, CY* pcyOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromUI1(uint8 bVal, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromI2(int16 iVal, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromI4(int32 lIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromI8(int64 i64In, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromR4(float fltIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromR8(double dblIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromCy(CY cyIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromDate(double dateIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromDisp(IDispatch* pdispIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromBool(int16 boolIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromI1(CHAR cIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromUI2(uint16 uiIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromUI4(uint32 ulIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromUI8(uint64 ui64In, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrFromDec(DECIMAL* pdecIn, uint32 lcid, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromUI1(uint8 bIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromI2(int16 sIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromI4(int32 lIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromI8(int64 i64In, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromR4(float fltIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromR8(double dblIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromDate(double dateIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromCy(CY cyIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromDisp(IDispatch* pdispIn, uint32 lcid, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromI1(CHAR cIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromUI2(uint16 uiIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromUI4(uint32 ulIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromUI8(uint64 i64In, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBoolFromDec(DECIMAL* pdecIn, int16* pboolOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromUI1(uint8 bIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromI2(int16 uiIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromI4(int32 lIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromI8(int64 i64In, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromR4(float fltIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromR8(double dblIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromDate(double dateIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromCy(CY cyIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromDisp(IDispatch* pdispIn, uint32 lcid, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromBool(int16 boolIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromUI2(uint16 uiIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromUI4(uint32 ulIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromUI8(uint64 i64In, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarI1FromDec(DECIMAL* pdecIn, PSTR pcOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromUI1(uint8 bIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromI2(int16 uiIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromI4(int32 lIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromI8(int64 i64In, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromR4(float fltIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromR8(double dblIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromDate(double dateIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromCy(CY cyIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromDisp(IDispatch* pdispIn, uint32 lcid, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromBool(int16 boolIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromI1(CHAR cIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromUI4(uint32 ulIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromUI8(uint64 i64In, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI2FromDec(DECIMAL* pdecIn, uint16* puiOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromUI1(uint8 bIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromI2(int16 uiIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromI4(int32 lIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromI8(int64 i64In, uint32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromR4(float fltIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromR8(double dblIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromDate(double dateIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromCy(CY cyIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromDisp(IDispatch* pdispIn, uint32 lcid, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromBool(int16 boolIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromI1(CHAR cIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromUI2(uint16 uiIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromUI8(uint64 ui64In, uint32* plOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI4FromDec(DECIMAL* pdecIn, uint32* pulOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromUI1(uint8 bIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromI2(int16 sIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromI8(int64 ui64In, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromR4(float fltIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromR8(double dblIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromCy(CY cyIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromDate(double dateIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromDisp(IDispatch* pdispIn, uint32 lcid, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromBool(int16 boolIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromI1(CHAR cIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromUI2(uint16 uiIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromUI4(uint32 ulIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUI8FromDec(DECIMAL* pdecIn, uint64* pi64Out);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromUI1(uint8 bIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromI2(int16 uiIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromI4(int32 lIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromI8(int64 i64In, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromR4(float fltIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromR8(double dblIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromDate(double dateIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromCy(CY cyIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromDisp(IDispatch* pdispIn, uint32 lcid, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromBool(int16 boolIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromI1(CHAR cIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromUI2(uint16 uiIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromUI4(uint32 ulIn, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFromUI8(uint64 ui64In, DECIMAL* pdecOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarParseNumFromStr(PWSTR strIn, uint32 lcid, uint32 dwFlags, NUMPARSE* pnumprs, uint8* rgbDig);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarNumFromParseNum(NUMPARSE* pnumprs, uint8* rgbDig, uint32 dwVtBits, VARIANT* pvar);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarAdd(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarAnd(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCat(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDiv(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarEqv(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarIdiv(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarImp(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarMod(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarMul(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarOr(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarPow(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarSub(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarXor(VARIANT* pvarLeft, VARIANT* pvarRight, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarAbs(VARIANT* pvarIn, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFix(VARIANT* pvarIn, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarInt(VARIANT* pvarIn, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarNeg(VARIANT* pvarIn, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarNot(VARIANT* pvarIn, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarRound(VARIANT* pvarIn, int32 cDecimals, VARIANT* pvarResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VARCMP VarCmp(VARIANT* pvarLeft, VARIANT* pvarRight, uint32 lcid, uint32 dwFlags);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecAdd(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecDiv(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecMul(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecSub(DECIMAL* pdecLeft, DECIMAL* pdecRight, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecAbs(DECIMAL* pdecIn, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecFix(DECIMAL* pdecIn, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecInt(DECIMAL* pdecIn, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecNeg(DECIMAL* pdecIn, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDecRound(DECIMAL* pdecIn, int32 cDecimals, DECIMAL* pdecResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VARCMP VarDecCmp(DECIMAL* pdecLeft, DECIMAL* pdecRight);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VARCMP VarDecCmpR8(DECIMAL* pdecLeft, double dblRight);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyAdd(CY cyLeft, CY cyRight, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyMul(CY cyLeft, CY cyRight, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyMulI4(CY cyLeft, int32 lRight, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyMulI8(CY cyLeft, int64 lRight, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCySub(CY cyLeft, CY cyRight, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyAbs(CY cyIn, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyFix(CY cyIn, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyInt(CY cyIn, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyNeg(CY cyIn, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarCyRound(CY cyIn, int32 cDecimals, CY* pcyResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VARCMP VarCyCmp(CY cyLeft, CY cyRight);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VARCMP VarCyCmpR8(CY cyLeft, double dblRight);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrCat(BSTR bstrLeft, BSTR bstrRight, uint16** pbstrResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarBstrCmp(BSTR bstrLeft, BSTR bstrRight, uint32 lcid, uint32 dwFlags);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8Pow(double dblLeft, double dblRight, double* pdblResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VARCMP VarR4CmpR8(float fltLeft, double dblRight);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarR8Round(double dblIn, int32 cDecimals, double* pdblResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromUdate(UDATE* pudateIn, uint32 dwFlags, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarDateFromUdateEx(UDATE* pudateIn, uint32 lcid, uint32 dwFlags, double* pdateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarUdateFromDate(double dateIn, uint32 dwFlags, UDATE* pudateOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetAltMonthNames(uint32 lcid, PWSTR** prgp);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFormat(VARIANT* pvarIn, PWSTR pstrFormat, VARFORMAT_FIRST_DAY iFirstDay, VARFORMAT_FIRST_WEEK iFirstWeek, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFormatDateTime(VARIANT* pvarIn, VARFORMAT_NAMED_FORMAT iNamedFormat, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFormatNumber(VARIANT* pvarIn, int32 iNumDig, VARFORMAT_LEADING_DIGIT iIncLead, VARFORMAT_PARENTHESES iUseParens, VARFORMAT_GROUP iGroup, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFormatPercent(VARIANT* pvarIn, int32 iNumDig, VARFORMAT_LEADING_DIGIT iIncLead, VARFORMAT_PARENTHESES iUseParens, VARFORMAT_GROUP iGroup, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFormatCurrency(VARIANT* pvarIn, int32 iNumDig, int32 iIncLead, int32 iUseParens, int32 iGroup, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarWeekdayName(int32 iWeekday, int32 fAbbrev, int32 iFirstDay, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarMonthName(int32 iMonth, int32 fAbbrev, uint32 dwFlags, BSTR* pbstrOut);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarFormatFromTokens(VARIANT* pvarIn, PWSTR pstrFormat, uint8* pbTokCur, uint32 dwFlags, BSTR* pbstrOut, uint32 lcid);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VarTokenizeFormatString(PWSTR pstrFormat, uint8* rgbTok, int32 cbTok, VARFORMAT_FIRST_DAY iFirstDay, VARFORMAT_FIRST_WEEK iFirstWeek, uint32 lcid, int32* pcbActual);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LHashValOfNameSysA(SYSKIND syskind, uint32 lcid, PSTR szName);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LHashValOfNameSys(SYSKIND syskind, uint32 lcid, PWSTR szName);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadTypeLib(PWSTR szFile, ITypeLib** pptlib);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadTypeLibEx(PWSTR szFile, REGKIND regkind, ITypeLib** pptlib);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadRegTypeLib(in Guid rguid, uint16 wVerMajor, uint16 wVerMinor, uint32 lcid, ITypeLib** pptlib);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryPathOfRegTypeLib(in Guid guid, uint16 wMaj, uint16 wMin, uint32 lcid, uint16** lpbstrPathName);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterTypeLib(ITypeLib* ptlib, PWSTR szFullPath, PWSTR szHelpDir);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnRegisterTypeLib(in Guid libID, uint16 wVerMajor, uint16 wVerMinor, uint32 lcid, SYSKIND syskind);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterTypeLibForUser(ITypeLib* ptlib, PWSTR szFullPath, PWSTR szHelpDir);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnRegisterTypeLibForUser(in Guid libID, uint16 wMajorVerNum, uint16 wMinorVerNum, uint32 lcid, SYSKIND syskind);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateTypeLib(SYSKIND syskind, PWSTR szFile, ICreateTypeLib** ppctlib);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateTypeLib2(SYSKIND syskind, PWSTR szFile, ICreateTypeLib2** ppctlib);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DispGetParam(DISPPARAMS* pdispparams, uint32 position, VARENUM vtTarg, VARIANT* pvarResult, uint32* puArgErr);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DispGetIDsOfNames(ITypeInfo* ptinfo, PWSTR* rgszNames, uint32 cNames, int32* rgdispid);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DispInvoke(void* _this, ITypeInfo* ptinfo, int32 dispidMember, uint16 wFlags, DISPPARAMS* pparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDispTypeInfo(INTERFACEDATA* pidata, uint32 lcid, ITypeInfo** pptinfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStdDispatch(IUnknown* punkOuter, void* pvThis, ITypeInfo* ptinfo, IUnknown** ppunkStdDisp);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DispCallFunc(void* pvInstance, uint oVft, CALLCONV cc, VARENUM vtReturn, uint32 cActuals, uint16* prgvt, VARIANT** prgpvarg, VARIANT* pvargResult);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterActiveObject(IUnknown* punk, in Guid rclsid, ACTIVEOBJECT_FLAGS dwFlags, uint32* pdwRegister);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RevokeActiveObject(uint32 dwRegister, void* pvReserved);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetActiveObject(in Guid rclsid, void* pvReserved, IUnknown** ppunk);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateErrorInfo(ICreateErrorInfo** pperrinfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRecordInfoFromTypeInfo(ITypeInfo* pTypeInfo, IRecordInfo** ppRecInfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRecordInfoFromGuids(in Guid rGuidTypeLib, uint32 uVerMajor, uint32 uVerMinor, uint32 lcid, in Guid rGuidTypeInfo, IRecordInfo** ppRecInfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OaBuildVersion();

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ClearCustData(CUSTDATA* pCustData);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void OaEnablePerUserTLibRegistration();

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleBuildVersion();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleInitialize(void* pvReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void OleUninitialize();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleQueryLinkFromData(IDataObject* pSrcDataObject);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleQueryCreateFromData(IDataObject* pSrcDataObject);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreate(in Guid rclsid, in Guid riid, OLERENDER renderopt, FORMATETC* pFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateEx(in Guid rclsid, in Guid riid, OLECREATE dwFlags, OLERENDER renderopt, uint32 cFormats, uint32* rgAdvf, FORMATETC* rgFormatEtc, IAdviseSink* lpAdviseSink, uint32* rgdwConnection, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateFromData(IDataObject* pSrcDataObj, in Guid riid, OLERENDER renderopt, FORMATETC* pFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateFromDataEx(IDataObject* pSrcDataObj, in Guid riid, OLECREATE dwFlags, OLERENDER renderopt, uint32 cFormats, uint32* rgAdvf, FORMATETC* rgFormatEtc, IAdviseSink* lpAdviseSink, uint32* rgdwConnection, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateLinkFromData(IDataObject* pSrcDataObj, in Guid riid, OLERENDER renderopt, FORMATETC* pFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateLinkFromDataEx(IDataObject* pSrcDataObj, in Guid riid, OLECREATE dwFlags, OLERENDER renderopt, uint32 cFormats, uint32* rgAdvf, FORMATETC* rgFormatEtc, IAdviseSink* lpAdviseSink, uint32* rgdwConnection, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateStaticFromData(IDataObject* pSrcDataObj, in Guid iid, OLERENDER renderopt, FORMATETC* pFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateLink(IMoniker* pmkLinkSrc, in Guid riid, OLERENDER renderopt, FORMATETC* lpFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateLinkEx(IMoniker* pmkLinkSrc, in Guid riid, OLECREATE dwFlags, OLERENDER renderopt, uint32 cFormats, uint32* rgAdvf, FORMATETC* rgFormatEtc, IAdviseSink* lpAdviseSink, uint32* rgdwConnection, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateLinkToFile(PWSTR lpszFileName, in Guid riid, OLERENDER renderopt, FORMATETC* lpFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateLinkToFileEx(PWSTR lpszFileName, in Guid riid, OLECREATE dwFlags, OLERENDER renderopt, uint32 cFormats, uint32* rgAdvf, FORMATETC* rgFormatEtc, IAdviseSink* lpAdviseSink, uint32* rgdwConnection, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateFromFile(in Guid rclsid, PWSTR lpszFileName, in Guid riid, OLERENDER renderopt, FORMATETC* lpFormatEtc, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateFromFileEx(in Guid rclsid, PWSTR lpszFileName, in Guid riid, OLECREATE dwFlags, OLERENDER renderopt, uint32 cFormats, uint32* rgAdvf, FORMATETC* rgFormatEtc, IAdviseSink* lpAdviseSink, uint32* rgdwConnection, IOleClientSite* pClientSite, IStorage* pStg, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoad(IStorage* pStg, in Guid riid, IOleClientSite* pClientSite, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSave(IPersistStorage* pPS, IStorage* pStg, BOOL fSameAsLoad);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoadFromStream(IStream* pStm, in Guid iidInterface, void** ppvObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSaveToStream(IPersistStream* pPStm, IStream* pStm);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSetContainedObject(IUnknown* pUnknown, BOOL fContained);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleNoteObjectVisible(IUnknown* pUnknown, BOOL fVisible);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterDragDrop(HWND hwnd, IDropTarget* pDropTarget);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RevokeDragDrop(HWND hwnd);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DoDragDrop(IDataObject* pDataObj, IDropSource* pDropSource, DROPEFFECT dwOKEffects, DROPEFFECT* pdwEffect);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSetClipboard(IDataObject* pDataObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleGetClipboard(IDataObject** ppDataObj);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleGetClipboardWithEnterpriseInfo(IDataObject** dataObject, PWSTR* dataEnterpriseId, PWSTR* sourceDescription, PWSTR* targetDescription, PWSTR* dataDescription);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleFlushClipboard();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleIsCurrentClipboard(IDataObject* pDataObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OleCreateMenuDescriptor(HMENU hmenuCombined, OLEMENUGROUPWIDTHS* lpMenuWidths);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSetMenuDescriptor(int holemenu, HWND hwndFrame, HWND hwndActiveObject, IOleInPlaceFrame* lpFrame, IOleInPlaceActiveObject* lpActiveObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleDestroyMenuDescriptor(int holemenu);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleTranslateAccelerator(IOleInPlaceFrame* lpFrame, OLEINPLACEFRAMEINFO* lpFrameInfo, MSG* lpmsg);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OleDuplicateData(HANDLE hSrc, uint16 cfFormat, uint32 uiFlags);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleDraw(IUnknown* pUnknown, uint32 dwAspect, HDC hdcDraw, RECT* lprcBounds);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleRun(IUnknown* pUnknown);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OleIsRunning(IOleObject* pObject);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLockRunning(IUnknown* pUnknown, BOOL fLock, BOOL fLastUnlockCloses);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ReleaseStgMedium(STGMEDIUM* param0);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateOleAdviseHolder(IOleAdviseHolder** ppOAHolder);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateDefaultHandler(in Guid clsid, IUnknown* pUnkOuter, in Guid riid, void** lplpObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateEmbeddingHelper(in Guid clsid, IUnknown* pUnkOuter, EMBDHLP_FLAGS flags, IClassFactory* pCF, in Guid riid, void** lplpObj);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsAccelerator(HACCEL hAccel, int32 cAccelEntries, MSG* lpMsg, uint16* lpwCmd);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OleGetIconOfFile(PWSTR lpszPath, BOOL fUseFileAsLabel);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OleGetIconOfClass(in Guid rclsid, PWSTR lpszLabel, BOOL fUseTypeAsLabel);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OleMetafilePictFromIconAndLabel(HICON hIcon, PWSTR lpszLabel, PWSTR lpszSourceFile, uint32 iIconIndex);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleRegGetUserType(in Guid clsid, USERCLASSTYPE dwFormOfType, PWSTR* pszUserType);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleRegGetMiscStatus(in Guid clsid, uint32 dwAspect, uint32* pdwStatus);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleRegEnumFormatEtc(in Guid clsid, uint32 dwDirection, IEnumFORMATETC** ppenum);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleRegEnumVerbs(in Guid clsid, IEnumOLEVERB** ppenum);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleDoAutoConvert(IStorage* pStg, Guid* pClsidNew);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleGetAutoConvert(in Guid clsidOld, Guid* pClsidNew);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSetAutoConvert(in Guid clsidOld, in Guid clsidNew);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HRGN_UserSize(uint32* param0, uint32 param1, HRGN* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HRGN_UserMarshal(uint32* param0, uint8* param1, HRGN* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HRGN_UserUnmarshal(uint32* param0, uint8* param1, HRGN* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HRGN_UserFree(uint32* param0, HRGN* param1);

	[Import("api-ms-win-core-marshal-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HRGN_UserSize64(uint32* param0, uint32 param1, HRGN* param2);

	[Import("api-ms-win-core-marshal-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HRGN_UserMarshal64(uint32* param0, uint8* param1, HRGN* param2);

	[Import("api-ms-win-core-marshal-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HRGN_UserUnmarshal64(uint32* param0, uint8* param1, HRGN* param2);

	[Import("api-ms-win-core-marshal-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HRGN_UserFree64(uint32* param0, HRGN* param1);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreatePropertyFrame(HWND hwndOwner, uint32 x, uint32 y, PWSTR lpszCaption, uint32 cObjects, IUnknown** ppUnk, uint32 cPages, Guid* pPageClsID, uint32 lcid, uint32 dwReserved, void* pvReserved);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreatePropertyFrameIndirect(OCPFIPARAMS* lpParams);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleTranslateColor(uint32 clr, HPALETTE hpal, COLORREF* lpcolorref);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreateFontIndirect(FONTDESC* lpFontDesc, in Guid riid, void** lplpvObj);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleCreatePictureIndirect(PICTDESC* lpPictDesc, in Guid riid, BOOL fOwn, void** lplpvObj);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoadPicture(IStream* lpstream, int32 lSize, BOOL fRunmode, in Guid riid, void** lplpvObj);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoadPictureEx(IStream* lpstream, int32 lSize, BOOL fRunmode, in Guid riid, uint32 xSizeDesired, uint32 ySizeDesired, LOAD_PICTURE_FLAGS dwFlags, void** lplpvObj);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoadPicturePath(PWSTR szURLorPath, IUnknown* punkCaller, uint32 dwReserved, uint32 clrReserved, in Guid riid, void** ppvRet);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoadPictureFile(VARIANT varFileName, IDispatch** lplpdispPicture);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleLoadPictureFileEx(VARIANT varFileName, uint32 xSizeDesired, uint32 ySizeDesired, LOAD_PICTURE_FLAGS dwFlags, IDispatch** lplpdispPicture);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSavePictureFile(IDispatch* lpdispPicture, BSTR bstrFileName);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCURSOR OleIconToCursor(HINSTANCE hinstExe, HICON hIcon);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OleUIAddVerbMenuW(IOleObject* lpOleObj, PWSTR lpszShortType, HMENU hMenu, uint32 uPos, uint32 uIDVerbMin, uint32 uIDVerbMax, BOOL bAddConvert, uint32 idConvert, HMENU* lphMenu);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OleUIAddVerbMenuA(IOleObject* lpOleObj, PSTR lpszShortType, HMENU hMenu, uint32 uPos, uint32 uIDVerbMin, uint32 uIDVerbMax, BOOL bAddConvert, uint32 idConvert, HMENU* lphMenu);
	public static BOOL OleUIAddVerbMenu(IOleObject* lpOleObj, PSTR lpszShortType, HMENU hMenu, uint32 uPos, uint32 uIDVerbMin, uint32 uIDVerbMax, BOOL bAddConvert, uint32 idConvert, HMENU* lphMenu) => OleUIAddVerbMenuA(lpOleObj, lpszShortType, hMenu, uPos, uIDVerbMin, uIDVerbMax, bAddConvert, idConvert, lphMenu);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIInsertObjectW(OLEUIINSERTOBJECTW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIInsertObjectA(OLEUIINSERTOBJECTA* param0);
	public static uint32 OleUIInsertObject(OLEUIINSERTOBJECTA* param0) => OleUIInsertObjectA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIPasteSpecialW(OLEUIPASTESPECIALW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIPasteSpecialA(OLEUIPASTESPECIALA* param0);
	public static uint32 OleUIPasteSpecial(OLEUIPASTESPECIALA* param0) => OleUIPasteSpecialA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIEditLinksW(OLEUIEDITLINKSW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIEditLinksA(OLEUIEDITLINKSA* param0);
	public static uint32 OleUIEditLinks(OLEUIEDITLINKSA* param0) => OleUIEditLinksA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIChangeIconW(OLEUICHANGEICONW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIChangeIconA(OLEUICHANGEICONA* param0);
	public static uint32 OleUIChangeIcon(OLEUICHANGEICONA* param0) => OleUIChangeIconA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIConvertW(OLEUICONVERTW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIConvertA(OLEUICONVERTA* param0);
	public static uint32 OleUIConvert(OLEUICONVERTA* param0) => OleUIConvertA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OleUICanConvertOrActivateAs(in Guid rClsid, BOOL fIsLinkedObject, uint16 wFormat);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIBusyW(OLEUIBUSYW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIBusyA(OLEUIBUSYA* param0);
	public static uint32 OleUIBusy(OLEUIBUSYA* param0) => OleUIBusyA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIChangeSourceW(OLEUICHANGESOURCEW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIChangeSourceA(OLEUICHANGESOURCEA* param0);
	public static uint32 OleUIChangeSource(OLEUICHANGESOURCEA* param0) => OleUIChangeSourceA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIObjectPropertiesW(OLEUIOBJECTPROPSW* param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OleUIObjectPropertiesA(OLEUIOBJECTPROPSA* param0);
	public static uint32 OleUIObjectProperties(OLEUIOBJECTPROPSA* param0) => OleUIObjectPropertiesA(param0);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 OleUIPromptUserW(int32 nTemplate, HWND hwndParent);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 OleUIPromptUserA(int32 nTemplate, HWND hwndParent);
	public static int32 OleUIPromptUser(int32 nTemplate, HWND hwndParent) => OleUIPromptUserA(nTemplate, hwndParent);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OleUIUpdateLinksW(IOleUILinkContainerW* lpOleUILinkCntr, HWND hwndParent, PWSTR lpszTitle, int32 cLinks);

	[Import("oledlg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OleUIUpdateLinksA(IOleUILinkContainerA* lpOleUILinkCntr, HWND hwndParent, PSTR lpszTitle, int32 cLinks);
	public static BOOL OleUIUpdateLinks(IOleUILinkContainerA* lpOleUILinkCntr, HWND hwndParent, PSTR lpszTitle, int32 cLinks) => OleUIUpdateLinksA(lpOleUILinkCntr, hwndParent, lpszTitle, cLinks);

}
#endregion
