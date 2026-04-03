using Win32.Foundation;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Gdi;
using Win32.System.Registry;
using Win32.System.Com;
using Win32.UI.Input.Pointer;
using System;

namespace Win32.UI.Controls;

#region Constants
public static
{
	public const HTREEITEM TVI_ROOT = -65536;
	public const HTREEITEM TVI_FIRST = -65535;
	public const HTREEITEM TVI_LAST = -65534;
	public const HTREEITEM TVI_SORT = -65533;
	public const uint32 BCN_FIRST = 4294966046;
	public const uint32 EM_SCROLLCARET = 183;
	public const uint32 EM_SETLIMITTEXT = 197;
	public const uint32 EM_GETLIMITTEXT = 213;
	public const uint32 EM_POSFROMCHAR = 214;
	public const uint32 EM_CHARFROMPOS = 215;
	public const uint32 WM_CTLCOLOR = 25;
	public const uint32 ODT_HEADER = 100;
	public const uint32 LVM_FIRST = 4096;
	public const uint32 TV_FIRST = 4352;
	public const uint32 HDM_FIRST = 4608;
	public const uint32 TCM_FIRST = 4864;
	public const uint32 PGM_FIRST = 5120;
	public const uint32 ECM_FIRST = 5376;
	public const uint32 BCM_FIRST = 5632;
	public const uint32 CBM_FIRST = 5888;
	public const uint32 CCM_FIRST = 8192;
	public const uint32 CCM_LAST = 8704;
	public const uint32 CCM_SETBKCOLOR = 8193;
	public const uint32 CCM_SETCOLORSCHEME = 8194;
	public const uint32 CCM_GETCOLORSCHEME = 8195;
	public const uint32 CCM_GETDROPTARGET = 8196;
	public const uint32 CCM_SETUNICODEFORMAT = 8197;
	public const uint32 CCM_GETUNICODEFORMAT = 8198;
	public const uint32 COMCTL32_VERSION = 6;
	public const uint32 CCM_SETVERSION = 8199;
	public const uint32 CCM_GETVERSION = 8200;
	public const uint32 CCM_SETNOTIFYWINDOW = 8201;
	public const uint32 CCM_SETWINDOWTHEME = 8203;
	public const uint32 CCM_DPISCALE = 8204;
	public const uint32 INFOTIPSIZE = 1024;
	public const uint32 MSGF_COMMCTRL_BEGINDRAG = 16896;
	public const uint32 MSGF_COMMCTRL_SIZEHEADER = 16897;
	public const uint32 MSGF_COMMCTRL_DRAGSELECT = 16898;
	public const uint32 MSGF_COMMCTRL_TOOLBARCUST = 16899;
	public const uint32 CDRF_DODEFAULT = 0;
	public const uint32 CDRF_NEWFONT = 2;
	public const uint32 CDRF_SKIPDEFAULT = 4;
	public const uint32 CDRF_DOERASE = 8;
	public const uint32 CDRF_SKIPPOSTPAINT = 256;
	public const uint32 CDRF_NOTIFYPOSTPAINT = 16;
	public const uint32 CDRF_NOTIFYITEMDRAW = 32;
	public const uint32 CDRF_NOTIFYSUBITEMDRAW = 32;
	public const uint32 CDRF_NOTIFYPOSTERASE = 64;
	public const uint32 CDDS_POSTERASE = 4;
	public const uint32 CDDS_ITEM = 65536;
	public const uint32 NM_GETCUSTOMSPLITRECT = 4294966049;
	public const int32 CLR_NONE = -1;
	public const int32 CLR_DEFAULT = -16777216;
	public const uint32 ILD_TRANSPARENT = 1;
	public const uint32 ILD_IMAGE = 32;
	public const uint32 ILD_ROP = 64;
	public const uint32 ILD_BLEND25 = 2;
	public const uint32 ILD_OVERLAYMASK = 3840;
	public const uint32 ILD_PRESERVEALPHA = 4096;
	public const uint32 ILD_SCALE = 8192;
	public const uint32 ILD_DPISCALE = 16384;
	public const uint32 ILD_ASYNC = 32768;
	public const int32 CLR_HILIGHT = -16777216;
	public const uint32 ILS_NORMAL = 0;
	public const uint32 ILS_GLOW = 1;
	public const uint32 ILS_SHADOW = 2;
	public const uint32 ILS_SATURATE = 4;
	public const uint32 ILS_ALPHA = 8;
	public const uint32 ILGT_NORMAL = 0;
	public const uint32 ILGT_ASYNC = 1;
	public const String WC_HEADERA = "SysHeader32";
	public const String WC_HEADERW = "SysHeader32";
	public const String WC_HEADER = "SysHeader32";
	public const uint32 HDS_HORZ = 0;
	public const uint32 HDS_BUTTONS = 2;
	public const uint32 HDS_HOTTRACK = 4;
	public const uint32 HDS_HIDDEN = 8;
	public const uint32 HDS_DRAGDROP = 64;
	public const uint32 HDS_FULLDRAG = 128;
	public const uint32 HDS_FILTERBAR = 256;
	public const uint32 HDS_FLAT = 512;
	public const uint32 HDS_CHECKBOXES = 1024;
	public const uint32 HDS_NOSIZING = 2048;
	public const uint32 HDS_OVERFLOW = 4096;
	public const uint32 HDM_GETITEMCOUNT = 4608;
	public const uint32 HDM_INSERTITEMA = 4609;
	public const uint32 HDM_INSERTITEMW = 4618;
	public const uint32 HDM_INSERTITEM = 4618;
	public const uint32 HDM_DELETEITEM = 4610;
	public const uint32 HDM_GETITEMA = 4611;
	public const uint32 HDM_GETITEMW = 4619;
	public const uint32 HDM_GETITEM = 4619;
	public const uint32 HDM_SETITEMA = 4612;
	public const uint32 HDM_SETITEMW = 4620;
	public const uint32 HDM_SETITEM = 4620;
	public const uint32 HDM_LAYOUT = 4613;
	public const uint32 HDSIL_NORMAL = 0;
	public const uint32 HDSIL_STATE = 1;
	public const uint32 HDM_HITTEST = 4614;
	public const uint32 HDM_GETITEMRECT = 4615;
	public const uint32 HDM_SETIMAGELIST = 4616;
	public const uint32 HDM_GETIMAGELIST = 4617;
	public const uint32 HDM_ORDERTOINDEX = 4623;
	public const uint32 HDM_CREATEDRAGIMAGE = 4624;
	public const uint32 HDM_GETORDERARRAY = 4625;
	public const uint32 HDM_SETORDERARRAY = 4626;
	public const uint32 HDM_SETHOTDIVIDER = 4627;
	public const uint32 HDM_SETBITMAPMARGIN = 4628;
	public const uint32 HDM_GETBITMAPMARGIN = 4629;
	public const uint32 HDM_SETUNICODEFORMAT = 8197;
	public const uint32 HDM_GETUNICODEFORMAT = 8198;
	public const uint32 HDM_SETFILTERCHANGETIMEOUT = 4630;
	public const uint32 HDM_EDITFILTER = 4631;
	public const uint32 HDM_CLEARFILTER = 4632;
	public const uint32 HDM_GETITEMDROPDOWNRECT = 4633;
	public const uint32 HDM_GETOVERFLOWRECT = 4634;
	public const uint32 HDM_GETFOCUSEDITEM = 4635;
	public const uint32 HDM_SETFOCUSEDITEM = 4636;
	public const String TOOLBARCLASSNAMEW = "ToolbarWindow32";
	public const String TOOLBARCLASSNAMEA = "ToolbarWindow32";
	public const String TOOLBARCLASSNAME = "ToolbarWindow32";
	public const uint32 CMB_MASKED = 2;
	public const uint32 TBSTATE_CHECKED = 1;
	public const uint32 TBSTATE_PRESSED = 2;
	public const uint32 TBSTATE_ENABLED = 4;
	public const uint32 TBSTATE_HIDDEN = 8;
	public const uint32 TBSTATE_INDETERMINATE = 16;
	public const uint32 TBSTATE_WRAP = 32;
	public const uint32 TBSTATE_ELLIPSES = 64;
	public const uint32 TBSTATE_MARKED = 128;
	public const uint32 TBSTYLE_BUTTON = 0;
	public const uint32 TBSTYLE_SEP = 1;
	public const uint32 TBSTYLE_CHECK = 2;
	public const uint32 TBSTYLE_GROUP = 4;
	public const uint32 TBSTYLE_DROPDOWN = 8;
	public const uint32 TBSTYLE_AUTOSIZE = 16;
	public const uint32 TBSTYLE_NOPREFIX = 32;
	public const uint32 TBSTYLE_TOOLTIPS = 256;
	public const uint32 TBSTYLE_WRAPABLE = 512;
	public const uint32 TBSTYLE_ALTDRAG = 1024;
	public const uint32 TBSTYLE_FLAT = 2048;
	public const uint32 TBSTYLE_LIST = 4096;
	public const uint32 TBSTYLE_CUSTOMERASE = 8192;
	public const uint32 TBSTYLE_REGISTERDROP = 16384;
	public const uint32 TBSTYLE_TRANSPARENT = 32768;
	public const uint32 TBSTYLE_EX_DRAWDDARROWS = 1;
	public const uint32 BTNS_BUTTON = 0;
	public const uint32 BTNS_SEP = 1;
	public const uint32 BTNS_CHECK = 2;
	public const uint32 BTNS_GROUP = 4;
	public const uint32 BTNS_DROPDOWN = 8;
	public const uint32 BTNS_AUTOSIZE = 16;
	public const uint32 BTNS_NOPREFIX = 32;
	public const uint32 BTNS_SHOWTEXT = 64;
	public const uint32 BTNS_WHOLEDROPDOWN = 128;
	public const uint32 TBSTYLE_EX_MIXEDBUTTONS = 8;
	public const uint32 TBSTYLE_EX_HIDECLIPPEDBUTTONS = 16;
	public const uint32 TBSTYLE_EX_MULTICOLUMN = 2;
	public const uint32 TBSTYLE_EX_VERTICAL = 4;
	public const uint32 TBSTYLE_EX_DOUBLEBUFFER = 128;
	public const uint32 TBCDRF_NOEDGES = 65536;
	public const uint32 TBCDRF_HILITEHOTTRACK = 131072;
	public const uint32 TBCDRF_NOOFFSET = 262144;
	public const uint32 TBCDRF_NOMARK = 524288;
	public const uint32 TBCDRF_NOETCHEDEFFECT = 1048576;
	public const uint32 TBCDRF_BLENDICON = 2097152;
	public const uint32 TBCDRF_NOBACKGROUND = 4194304;
	public const uint32 TBCDRF_USECDCOLORS = 8388608;
	public const uint32 TB_ENABLEBUTTON = 1025;
	public const uint32 TB_CHECKBUTTON = 1026;
	public const uint32 TB_PRESSBUTTON = 1027;
	public const uint32 TB_HIDEBUTTON = 1028;
	public const uint32 TB_INDETERMINATE = 1029;
	public const uint32 TB_MARKBUTTON = 1030;
	public const uint32 TB_ISBUTTONENABLED = 1033;
	public const uint32 TB_ISBUTTONCHECKED = 1034;
	public const uint32 TB_ISBUTTONPRESSED = 1035;
	public const uint32 TB_ISBUTTONHIDDEN = 1036;
	public const uint32 TB_ISBUTTONINDETERMINATE = 1037;
	public const uint32 TB_ISBUTTONHIGHLIGHTED = 1038;
	public const uint32 TB_SETSTATE = 1041;
	public const uint32 TB_GETSTATE = 1042;
	public const uint32 TB_ADDBITMAP = 1043;
	public const uint32 IDB_STD_SMALL_COLOR = 0;
	public const uint32 IDB_STD_LARGE_COLOR = 1;
	public const uint32 IDB_VIEW_SMALL_COLOR = 4;
	public const uint32 IDB_VIEW_LARGE_COLOR = 5;
	public const uint32 IDB_HIST_SMALL_COLOR = 8;
	public const uint32 IDB_HIST_LARGE_COLOR = 9;
	public const uint32 IDB_HIST_NORMAL = 12;
	public const uint32 IDB_HIST_HOT = 13;
	public const uint32 IDB_HIST_DISABLED = 14;
	public const uint32 IDB_HIST_PRESSED = 15;
	public const uint32 STD_CUT = 0;
	public const uint32 STD_COPY = 1;
	public const uint32 STD_PASTE = 2;
	public const uint32 STD_UNDO = 3;
	public const uint32 STD_REDOW = 4;
	public const uint32 STD_DELETE = 5;
	public const uint32 STD_FILENEW = 6;
	public const uint32 STD_FILEOPEN = 7;
	public const uint32 STD_FILESAVE = 8;
	public const uint32 STD_PRINTPRE = 9;
	public const uint32 STD_PROPERTIES = 10;
	public const uint32 STD_HELP = 11;
	public const uint32 STD_FIND = 12;
	public const uint32 STD_REPLACE = 13;
	public const uint32 STD_PRINT = 14;
	public const uint32 VIEW_LARGEICONS = 0;
	public const uint32 VIEW_SMALLICONS = 1;
	public const uint32 VIEW_LIST = 2;
	public const uint32 VIEW_DETAILS = 3;
	public const uint32 VIEW_SORTNAME = 4;
	public const uint32 VIEW_SORTSIZE = 5;
	public const uint32 VIEW_SORTDATE = 6;
	public const uint32 VIEW_SORTTYPE = 7;
	public const uint32 VIEW_PARENTFOLDER = 8;
	public const uint32 VIEW_NETCONNECT = 9;
	public const uint32 VIEW_NETDISCONNECT = 10;
	public const uint32 VIEW_NEWFOLDER = 11;
	public const uint32 VIEW_VIEWMENU = 12;
	public const uint32 HIST_BACK = 0;
	public const uint32 HIST_FORWARD = 1;
	public const uint32 HIST_FAVORITES = 2;
	public const uint32 HIST_ADDTOFAVORITES = 3;
	public const uint32 HIST_VIEWTREE = 4;
	public const uint32 TB_ADDBUTTONSA = 1044;
	public const uint32 TB_INSERTBUTTONA = 1045;
	public const uint32 TB_DELETEBUTTON = 1046;
	public const uint32 TB_GETBUTTON = 1047;
	public const uint32 TB_BUTTONCOUNT = 1048;
	public const uint32 TB_COMMANDTOINDEX = 1049;
	public const uint32 TB_SAVERESTOREA = 1050;
	public const uint32 TB_SAVERESTOREW = 1100;
	public const uint32 TB_CUSTOMIZE = 1051;
	public const uint32 TB_ADDSTRINGA = 1052;
	public const uint32 TB_ADDSTRINGW = 1101;
	public const uint32 TB_GETITEMRECT = 1053;
	public const uint32 TB_BUTTONSTRUCTSIZE = 1054;
	public const uint32 TB_SETBUTTONSIZE = 1055;
	public const uint32 TB_SETBITMAPSIZE = 1056;
	public const uint32 TB_AUTOSIZE = 1057;
	public const uint32 TB_GETTOOLTIPS = 1059;
	public const uint32 TB_SETTOOLTIPS = 1060;
	public const uint32 TB_SETPARENT = 1061;
	public const uint32 TB_SETROWS = 1063;
	public const uint32 TB_GETROWS = 1064;
	public const uint32 TB_SETCMDID = 1066;
	public const uint32 TB_CHANGEBITMAP = 1067;
	public const uint32 TB_GETBITMAP = 1068;
	public const uint32 TB_GETBUTTONTEXTA = 1069;
	public const uint32 TB_GETBUTTONTEXTW = 1099;
	public const uint32 TB_REPLACEBITMAP = 1070;
	public const uint32 TB_SETINDENT = 1071;
	public const uint32 TB_SETIMAGELIST = 1072;
	public const uint32 TB_GETIMAGELIST = 1073;
	public const uint32 TB_LOADIMAGES = 1074;
	public const uint32 TB_GETRECT = 1075;
	public const uint32 TB_SETHOTIMAGELIST = 1076;
	public const uint32 TB_GETHOTIMAGELIST = 1077;
	public const uint32 TB_SETDISABLEDIMAGELIST = 1078;
	public const uint32 TB_GETDISABLEDIMAGELIST = 1079;
	public const uint32 TB_SETSTYLE = 1080;
	public const uint32 TB_GETSTYLE = 1081;
	public const uint32 TB_GETBUTTONSIZE = 1082;
	public const uint32 TB_SETBUTTONWIDTH = 1083;
	public const uint32 TB_SETMAXTEXTROWS = 1084;
	public const uint32 TB_GETTEXTROWS = 1085;
	public const uint32 TB_GETBUTTONTEXT = 1099;
	public const uint32 TB_SAVERESTORE = 1100;
	public const uint32 TB_ADDSTRING = 1101;
	public const uint32 TB_GETOBJECT = 1086;
	public const uint32 TB_GETHOTITEM = 1095;
	public const uint32 TB_SETHOTITEM = 1096;
	public const uint32 TB_SETANCHORHIGHLIGHT = 1097;
	public const uint32 TB_GETANCHORHIGHLIGHT = 1098;
	public const uint32 TB_MAPACCELERATORA = 1102;
	public const uint32 TB_GETINSERTMARK = 1103;
	public const uint32 TB_SETINSERTMARK = 1104;
	public const uint32 TB_INSERTMARKHITTEST = 1105;
	public const uint32 TB_MOVEBUTTON = 1106;
	public const uint32 TB_GETMAXSIZE = 1107;
	public const uint32 TB_SETEXTENDEDSTYLE = 1108;
	public const uint32 TB_GETEXTENDEDSTYLE = 1109;
	public const uint32 TB_GETPADDING = 1110;
	public const uint32 TB_SETPADDING = 1111;
	public const uint32 TB_SETINSERTMARKCOLOR = 1112;
	public const uint32 TB_GETINSERTMARKCOLOR = 1113;
	public const uint32 TB_SETCOLORSCHEME = 8194;
	public const uint32 TB_GETCOLORSCHEME = 8195;
	public const uint32 TB_SETUNICODEFORMAT = 8197;
	public const uint32 TB_GETUNICODEFORMAT = 8198;
	public const uint32 TB_MAPACCELERATORW = 1114;
	public const uint32 TB_MAPACCELERATOR = 1114;
	public const uint32 TBBF_LARGE = 1;
	public const uint32 TB_GETBITMAPFLAGS = 1065;
	public const uint32 TB_GETBUTTONINFOW = 1087;
	public const uint32 TB_SETBUTTONINFOW = 1088;
	public const uint32 TB_GETBUTTONINFOA = 1089;
	public const uint32 TB_SETBUTTONINFOA = 1090;
	public const uint32 TB_GETBUTTONINFO = 1087;
	public const uint32 TB_SETBUTTONINFO = 1088;
	public const uint32 TB_INSERTBUTTONW = 1091;
	public const uint32 TB_ADDBUTTONSW = 1092;
	public const uint32 TB_HITTEST = 1093;
	public const uint32 TB_INSERTBUTTON = 1091;
	public const uint32 TB_ADDBUTTONS = 1092;
	public const uint32 TB_SETDRAWTEXTFLAGS = 1094;
	public const uint32 TB_GETSTRINGW = 1115;
	public const uint32 TB_GETSTRINGA = 1116;
	public const uint32 TB_GETSTRING = 1115;
	public const uint32 TB_SETBOUNDINGSIZE = 1117;
	public const uint32 TB_SETHOTITEM2 = 1118;
	public const uint32 TB_HASACCELERATOR = 1119;
	public const uint32 TB_SETLISTGAP = 1120;
	public const uint32 TB_GETIMAGELISTCOUNT = 1122;
	public const uint32 TB_GETIDEALSIZE = 1123;
	public const uint32 TBMF_PAD = 1;
	public const uint32 TBMF_BARPAD = 2;
	public const uint32 TBMF_BUTTONSPACING = 4;
	public const uint32 TB_GETMETRICS = 1125;
	public const uint32 TB_SETMETRICS = 1126;
	public const uint32 TB_GETITEMDROPDOWNRECT = 1127;
	public const uint32 TB_SETPRESSEDIMAGELIST = 1128;
	public const uint32 TB_GETPRESSEDIMAGELIST = 1129;
	public const uint32 TB_SETWINDOWTHEME = 8203;
	public const uint32 TBNRF_HIDEHELP = 1;
	public const uint32 TBNRF_ENDCUSTOMIZE = 2;
	public const uint32 TBDDRET_DEFAULT = 0;
	public const uint32 TBDDRET_NODEFAULT = 1;
	public const uint32 TBDDRET_TREATPRESSED = 2;
	public const String REBARCLASSNAMEW = "ReBarWindow32";
	public const String REBARCLASSNAMEA = "ReBarWindow32";
	public const String REBARCLASSNAME = "ReBarWindow32";
	public const uint32 RBIM_IMAGELIST = 1;
	public const uint32 RBS_TOOLTIPS = 256;
	public const uint32 RBS_VARHEIGHT = 512;
	public const uint32 RBS_BANDBORDERS = 1024;
	public const uint32 RBS_FIXEDORDER = 2048;
	public const uint32 RBS_REGISTERDROP = 4096;
	public const uint32 RBS_AUTOSIZE = 8192;
	public const uint32 RBS_VERTICALGRIPPER = 16384;
	public const uint32 RBS_DBLCLKTOGGLE = 32768;
	public const uint32 RBBS_BREAK = 1;
	public const uint32 RBBS_FIXEDSIZE = 2;
	public const uint32 RBBS_CHILDEDGE = 4;
	public const uint32 RBBS_HIDDEN = 8;
	public const uint32 RBBS_NOVERT = 16;
	public const uint32 RBBS_FIXEDBMP = 32;
	public const uint32 RBBS_VARIABLEHEIGHT = 64;
	public const uint32 RBBS_GRIPPERALWAYS = 128;
	public const uint32 RBBS_NOGRIPPER = 256;
	public const uint32 RBBS_USECHEVRON = 512;
	public const uint32 RBBS_HIDETITLE = 1024;
	public const uint32 RBBS_TOPALIGN = 2048;
	public const uint32 RBBIM_STYLE = 1;
	public const uint32 RBBIM_COLORS = 2;
	public const uint32 RBBIM_TEXT = 4;
	public const uint32 RBBIM_IMAGE = 8;
	public const uint32 RBBIM_CHILD = 16;
	public const uint32 RBBIM_CHILDSIZE = 32;
	public const uint32 RBBIM_SIZE = 64;
	public const uint32 RBBIM_BACKGROUND = 128;
	public const uint32 RBBIM_ID = 256;
	public const uint32 RBBIM_IDEALSIZE = 512;
	public const uint32 RBBIM_LPARAM = 1024;
	public const uint32 RBBIM_HEADERSIZE = 2048;
	public const uint32 RBBIM_CHEVRONLOCATION = 4096;
	public const uint32 RBBIM_CHEVRONSTATE = 8192;
	public const uint32 RB_INSERTBANDA = 1025;
	public const uint32 RB_DELETEBAND = 1026;
	public const uint32 RB_GETBARINFO = 1027;
	public const uint32 RB_SETBARINFO = 1028;
	public const uint32 RB_SETBANDINFOA = 1030;
	public const uint32 RB_SETPARENT = 1031;
	public const uint32 RB_HITTEST = 1032;
	public const uint32 RB_GETRECT = 1033;
	public const uint32 RB_INSERTBANDW = 1034;
	public const uint32 RB_SETBANDINFOW = 1035;
	public const uint32 RB_GETBANDCOUNT = 1036;
	public const uint32 RB_GETROWCOUNT = 1037;
	public const uint32 RB_GETROWHEIGHT = 1038;
	public const uint32 RB_IDTOINDEX = 1040;
	public const uint32 RB_GETTOOLTIPS = 1041;
	public const uint32 RB_SETTOOLTIPS = 1042;
	public const uint32 RB_SETBKCOLOR = 1043;
	public const uint32 RB_GETBKCOLOR = 1044;
	public const uint32 RB_SETTEXTCOLOR = 1045;
	public const uint32 RB_GETTEXTCOLOR = 1046;
	public const uint32 RBSTR_CHANGERECT = 1;
	public const uint32 RB_SIZETORECT = 1047;
	public const uint32 RB_SETCOLORSCHEME = 8194;
	public const uint32 RB_GETCOLORSCHEME = 8195;
	public const uint32 RB_INSERTBAND = 1034;
	public const uint32 RB_SETBANDINFO = 1035;
	public const uint32 RB_BEGINDRAG = 1048;
	public const uint32 RB_ENDDRAG = 1049;
	public const uint32 RB_DRAGMOVE = 1050;
	public const uint32 RB_GETBARHEIGHT = 1051;
	public const uint32 RB_GETBANDINFOW = 1052;
	public const uint32 RB_GETBANDINFOA = 1053;
	public const uint32 RB_GETBANDINFO = 1052;
	public const uint32 RB_MINIMIZEBAND = 1054;
	public const uint32 RB_MAXIMIZEBAND = 1055;
	public const uint32 RB_GETDROPTARGET = 8196;
	public const uint32 RB_GETBANDBORDERS = 1058;
	public const uint32 RB_SHOWBAND = 1059;
	public const uint32 RB_SETPALETTE = 1061;
	public const uint32 RB_GETPALETTE = 1062;
	public const uint32 RB_MOVEBAND = 1063;
	public const uint32 RB_SETUNICODEFORMAT = 8197;
	public const uint32 RB_GETUNICODEFORMAT = 8198;
	public const uint32 RB_GETBANDMARGINS = 1064;
	public const uint32 RB_SETWINDOWTHEME = 8203;
	public const uint32 RB_SETEXTENDEDSTYLE = 1065;
	public const uint32 RB_GETEXTENDEDSTYLE = 1066;
	public const uint32 RB_PUSHCHEVRON = 1067;
	public const uint32 RB_SETBANDWIDTH = 1068;
	public const uint32 RBAB_AUTOSIZE = 1;
	public const uint32 RBAB_ADDBAND = 2;
	public const uint32 RBHT_NOWHERE = 1;
	public const uint32 RBHT_CAPTION = 2;
	public const uint32 RBHT_CLIENT = 3;
	public const uint32 RBHT_GRABBER = 4;
	public const uint32 RBHT_CHEVRON = 8;
	public const uint32 RBHT_SPLITTER = 16;
	public const String TOOLTIPS_CLASSW = "tooltips_class32";
	public const String TOOLTIPS_CLASSA = "tooltips_class32";
	public const String TOOLTIPS_CLASS = "tooltips_class32";
	public const uint32 TTS_ALWAYSTIP = 1;
	public const uint32 TTS_NOPREFIX = 2;
	public const uint32 TTS_NOANIMATE = 16;
	public const uint32 TTS_NOFADE = 32;
	public const uint32 TTS_BALLOON = 64;
	public const uint32 TTS_CLOSE = 128;
	public const uint32 TTS_USEVISUALSTYLE = 256;
	public const uint32 TTDT_AUTOMATIC = 0;
	public const uint32 TTDT_RESHOW = 1;
	public const uint32 TTDT_AUTOPOP = 2;
	public const uint32 TTDT_INITIAL = 3;
	public const uint32 TTM_ACTIVATE = 1025;
	public const uint32 TTM_SETDELAYTIME = 1027;
	public const uint32 TTM_ADDTOOLA = 1028;
	public const uint32 TTM_ADDTOOLW = 1074;
	public const uint32 TTM_DELTOOLA = 1029;
	public const uint32 TTM_DELTOOLW = 1075;
	public const uint32 TTM_NEWTOOLRECTA = 1030;
	public const uint32 TTM_NEWTOOLRECTW = 1076;
	public const uint32 TTM_RELAYEVENT = 1031;
	public const uint32 TTM_GETTOOLINFOA = 1032;
	public const uint32 TTM_GETTOOLINFOW = 1077;
	public const uint32 TTM_SETTOOLINFOA = 1033;
	public const uint32 TTM_SETTOOLINFOW = 1078;
	public const uint32 TTM_HITTESTA = 1034;
	public const uint32 TTM_HITTESTW = 1079;
	public const uint32 TTM_GETTEXTA = 1035;
	public const uint32 TTM_GETTEXTW = 1080;
	public const uint32 TTM_UPDATETIPTEXTA = 1036;
	public const uint32 TTM_UPDATETIPTEXTW = 1081;
	public const uint32 TTM_GETTOOLCOUNT = 1037;
	public const uint32 TTM_ENUMTOOLSA = 1038;
	public const uint32 TTM_ENUMTOOLSW = 1082;
	public const uint32 TTM_GETCURRENTTOOLA = 1039;
	public const uint32 TTM_GETCURRENTTOOLW = 1083;
	public const uint32 TTM_WINDOWFROMPOINT = 1040;
	public const uint32 TTM_TRACKACTIVATE = 1041;
	public const uint32 TTM_TRACKPOSITION = 1042;
	public const uint32 TTM_SETTIPBKCOLOR = 1043;
	public const uint32 TTM_SETTIPTEXTCOLOR = 1044;
	public const uint32 TTM_GETDELAYTIME = 1045;
	public const uint32 TTM_GETTIPBKCOLOR = 1046;
	public const uint32 TTM_GETTIPTEXTCOLOR = 1047;
	public const uint32 TTM_SETMAXTIPWIDTH = 1048;
	public const uint32 TTM_GETMAXTIPWIDTH = 1049;
	public const uint32 TTM_SETMARGIN = 1050;
	public const uint32 TTM_GETMARGIN = 1051;
	public const uint32 TTM_POP = 1052;
	public const uint32 TTM_UPDATE = 1053;
	public const uint32 TTM_GETBUBBLESIZE = 1054;
	public const uint32 TTM_ADJUSTRECT = 1055;
	public const uint32 TTM_SETTITLEA = 1056;
	public const uint32 TTM_SETTITLEW = 1057;
	public const uint32 TTM_POPUP = 1058;
	public const uint32 TTM_GETTITLE = 1059;
	public const uint32 TTM_ADDTOOL = 1074;
	public const uint32 TTM_DELTOOL = 1075;
	public const uint32 TTM_NEWTOOLRECT = 1076;
	public const uint32 TTM_GETTOOLINFO = 1077;
	public const uint32 TTM_SETTOOLINFO = 1078;
	public const uint32 TTM_HITTEST = 1079;
	public const uint32 TTM_GETTEXT = 1080;
	public const uint32 TTM_UPDATETIPTEXT = 1081;
	public const uint32 TTM_ENUMTOOLS = 1082;
	public const uint32 TTM_GETCURRENTTOOL = 1083;
	public const uint32 TTM_SETTITLE = 1057;
	public const uint32 TTM_SETWINDOWTHEME = 8203;
	public const uint32 SBARS_SIZEGRIP = 256;
	public const uint32 SBARS_TOOLTIPS = 2048;
	public const uint32 SBT_TOOLTIPS = 2048;
	public const String STATUSCLASSNAMEW = "msctls_statusbar32";
	public const String STATUSCLASSNAMEA = "msctls_statusbar32";
	public const String STATUSCLASSNAME = "msctls_statusbar32";
	public const uint32 SB_SETTEXTA = 1025;
	public const uint32 SB_SETTEXTW = 1035;
	public const uint32 SB_GETTEXTA = 1026;
	public const uint32 SB_GETTEXTW = 1037;
	public const uint32 SB_GETTEXTLENGTHA = 1027;
	public const uint32 SB_GETTEXTLENGTHW = 1036;
	public const uint32 SB_GETTEXT = 1037;
	public const uint32 SB_SETTEXT = 1035;
	public const uint32 SB_GETTEXTLENGTH = 1036;
	public const uint32 SB_SETPARTS = 1028;
	public const uint32 SB_GETPARTS = 1030;
	public const uint32 SB_GETBORDERS = 1031;
	public const uint32 SB_SETMINHEIGHT = 1032;
	public const uint32 SB_SIMPLE = 1033;
	public const uint32 SB_GETRECT = 1034;
	public const uint32 SB_ISSIMPLE = 1038;
	public const uint32 SB_SETICON = 1039;
	public const uint32 SB_SETTIPTEXTA = 1040;
	public const uint32 SB_SETTIPTEXTW = 1041;
	public const uint32 SB_GETTIPTEXTA = 1042;
	public const uint32 SB_GETTIPTEXTW = 1043;
	public const uint32 SB_GETICON = 1044;
	public const uint32 SB_SETUNICODEFORMAT = 8197;
	public const uint32 SB_GETUNICODEFORMAT = 8198;
	public const uint32 SBT_OWNERDRAW = 4096;
	public const uint32 SBT_NOBORDERS = 256;
	public const uint32 SBT_POPOUT = 512;
	public const uint32 SBT_RTLREADING = 1024;
	public const uint32 SBT_NOTABPARSING = 2048;
	public const uint32 SB_SETBKCOLOR = 8193;
	public const uint32 SB_SIMPLEID = 255;
	public const String TRACKBAR_CLASSA = "msctls_trackbar32";
	public const String TRACKBAR_CLASSW = "msctls_trackbar32";
	public const String TRACKBAR_CLASS = "msctls_trackbar32";
	public const uint32 TBS_AUTOTICKS = 1;
	public const uint32 TBS_VERT = 2;
	public const uint32 TBS_HORZ = 0;
	public const uint32 TBS_TOP = 4;
	public const uint32 TBS_BOTTOM = 0;
	public const uint32 TBS_LEFT = 4;
	public const uint32 TBS_RIGHT = 0;
	public const uint32 TBS_BOTH = 8;
	public const uint32 TBS_NOTICKS = 16;
	public const uint32 TBS_ENABLESELRANGE = 32;
	public const uint32 TBS_FIXEDLENGTH = 64;
	public const uint32 TBS_NOTHUMB = 128;
	public const uint32 TBS_TOOLTIPS = 256;
	public const uint32 TBS_REVERSED = 512;
	public const uint32 TBS_DOWNISLEFT = 1024;
	public const uint32 TBS_NOTIFYBEFOREMOVE = 2048;
	public const uint32 TBS_TRANSPARENTBKGND = 4096;
	public const uint32 TBM_GETRANGEMIN = 1025;
	public const uint32 TBM_GETRANGEMAX = 1026;
	public const uint32 TBM_GETTIC = 1027;
	public const uint32 TBM_SETTIC = 1028;
	public const uint32 TBM_SETPOS = 1029;
	public const uint32 TBM_SETRANGE = 1030;
	public const uint32 TBM_SETRANGEMIN = 1031;
	public const uint32 TBM_SETRANGEMAX = 1032;
	public const uint32 TBM_CLEARTICS = 1033;
	public const uint32 TBM_SETSEL = 1034;
	public const uint32 TBM_SETSELSTART = 1035;
	public const uint32 TBM_SETSELEND = 1036;
	public const uint32 TBM_GETPTICS = 1038;
	public const uint32 TBM_GETTICPOS = 1039;
	public const uint32 TBM_GETNUMTICS = 1040;
	public const uint32 TBM_GETSELSTART = 1041;
	public const uint32 TBM_GETSELEND = 1042;
	public const uint32 TBM_CLEARSEL = 1043;
	public const uint32 TBM_SETTICFREQ = 1044;
	public const uint32 TBM_SETPAGESIZE = 1045;
	public const uint32 TBM_GETPAGESIZE = 1046;
	public const uint32 TBM_SETLINESIZE = 1047;
	public const uint32 TBM_GETLINESIZE = 1048;
	public const uint32 TBM_GETTHUMBRECT = 1049;
	public const uint32 TBM_GETCHANNELRECT = 1050;
	public const uint32 TBM_SETTHUMBLENGTH = 1051;
	public const uint32 TBM_GETTHUMBLENGTH = 1052;
	public const uint32 TBM_SETTOOLTIPS = 1053;
	public const uint32 TBM_GETTOOLTIPS = 1054;
	public const uint32 TBM_SETTIPSIDE = 1055;
	public const uint32 TBTS_TOP = 0;
	public const uint32 TBTS_LEFT = 1;
	public const uint32 TBTS_BOTTOM = 2;
	public const uint32 TBTS_RIGHT = 3;
	public const uint32 TBM_SETBUDDY = 1056;
	public const uint32 TBM_GETBUDDY = 1057;
	public const uint32 TBM_SETPOSNOTIFY = 1058;
	public const uint32 TBM_SETUNICODEFORMAT = 8197;
	public const uint32 TBM_GETUNICODEFORMAT = 8198;
	public const uint32 TB_LINEUP = 0;
	public const uint32 TB_LINEDOWN = 1;
	public const uint32 TB_PAGEUP = 2;
	public const uint32 TB_PAGEDOWN = 3;
	public const uint32 TB_THUMBPOSITION = 4;
	public const uint32 TB_THUMBTRACK = 5;
	public const uint32 TB_TOP = 6;
	public const uint32 TB_BOTTOM = 7;
	public const uint32 TB_ENDTRACK = 8;
	public const uint32 TBCD_TICS = 1;
	public const uint32 TBCD_THUMB = 2;
	public const uint32 TBCD_CHANNEL = 3;
	public const uint32 DL_CURSORSET = 0;
	public const uint32 DL_STOPCURSOR = 1;
	public const uint32 DL_COPYCURSOR = 2;
	public const uint32 DL_MOVECURSOR = 3;
	public const String DRAGLISTMSGSTRING = "commctrl_DragListMsg";
	public const String UPDOWN_CLASSA = "msctls_updown32";
	public const String UPDOWN_CLASSW = "msctls_updown32";
	public const String UPDOWN_CLASS = "msctls_updown32";
	public const uint32 UD_MAXVAL = 32767;
	public const uint32 UDS_WRAP = 1;
	public const uint32 UDS_SETBUDDYINT = 2;
	public const uint32 UDS_ALIGNRIGHT = 4;
	public const uint32 UDS_ALIGNLEFT = 8;
	public const uint32 UDS_AUTOBUDDY = 16;
	public const uint32 UDS_ARROWKEYS = 32;
	public const uint32 UDS_HORZ = 64;
	public const uint32 UDS_NOTHOUSANDS = 128;
	public const uint32 UDS_HOTTRACK = 256;
	public const uint32 UDM_SETRANGE = 1125;
	public const uint32 UDM_GETRANGE = 1126;
	public const uint32 UDM_SETPOS = 1127;
	public const uint32 UDM_GETPOS = 1128;
	public const uint32 UDM_SETBUDDY = 1129;
	public const uint32 UDM_GETBUDDY = 1130;
	public const uint32 UDM_SETACCEL = 1131;
	public const uint32 UDM_GETACCEL = 1132;
	public const uint32 UDM_SETBASE = 1133;
	public const uint32 UDM_GETBASE = 1134;
	public const uint32 UDM_SETRANGE32 = 1135;
	public const uint32 UDM_GETRANGE32 = 1136;
	public const uint32 UDM_SETUNICODEFORMAT = 8197;
	public const uint32 UDM_GETUNICODEFORMAT = 8198;
	public const uint32 UDM_SETPOS32 = 1137;
	public const uint32 UDM_GETPOS32 = 1138;
	public const String PROGRESS_CLASSA = "msctls_progress32";
	public const String PROGRESS_CLASSW = "msctls_progress32";
	public const String PROGRESS_CLASS = "msctls_progress32";
	public const uint32 PBS_SMOOTH = 1;
	public const uint32 PBS_VERTICAL = 4;
	public const uint32 PBM_SETRANGE = 1025;
	public const uint32 PBM_SETPOS = 1026;
	public const uint32 PBM_DELTAPOS = 1027;
	public const uint32 PBM_SETSTEP = 1028;
	public const uint32 PBM_STEPIT = 1029;
	public const uint32 PBM_SETRANGE32 = 1030;
	public const uint32 PBM_GETRANGE = 1031;
	public const uint32 PBM_GETPOS = 1032;
	public const uint32 PBM_SETBARCOLOR = 1033;
	public const uint32 PBM_SETBKCOLOR = 8193;
	public const uint32 PBS_MARQUEE = 8;
	public const uint32 PBM_SETMARQUEE = 1034;
	public const uint32 PBS_SMOOTHREVERSE = 16;
	public const uint32 PBM_GETSTEP = 1037;
	public const uint32 PBM_GETBKCOLOR = 1038;
	public const uint32 PBM_GETBARCOLOR = 1039;
	public const uint32 PBM_SETSTATE = 1040;
	public const uint32 PBM_GETSTATE = 1041;
	public const uint32 PBST_NORMAL = 1;
	public const uint32 PBST_ERROR = 2;
	public const uint32 PBST_PAUSED = 3;
	public const uint32 HOTKEYF_SHIFT = 1;
	public const uint32 HOTKEYF_CONTROL = 2;
	public const uint32 HOTKEYF_ALT = 4;
	public const uint32 HOTKEYF_EXT = 128;
	public const uint32 HKCOMB_NONE = 1;
	public const uint32 HKCOMB_S = 2;
	public const uint32 HKCOMB_C = 4;
	public const uint32 HKCOMB_A = 8;
	public const uint32 HKCOMB_SC = 16;
	public const uint32 HKCOMB_SA = 32;
	public const uint32 HKCOMB_CA = 64;
	public const uint32 HKCOMB_SCA = 128;
	public const uint32 HKM_SETHOTKEY = 1025;
	public const uint32 HKM_GETHOTKEY = 1026;
	public const uint32 HKM_SETRULES = 1027;
	public const String HOTKEY_CLASSA = "msctls_hotkey32";
	public const String HOTKEY_CLASSW = "msctls_hotkey32";
	public const String HOTKEY_CLASS = "msctls_hotkey32";
	public const int32 CCS_TOP = 1;
	public const int32 CCS_NOMOVEY = 2;
	public const int32 CCS_BOTTOM = 3;
	public const int32 CCS_NORESIZE = 4;
	public const int32 CCS_NOPARENTALIGN = 8;
	public const int32 CCS_ADJUSTABLE = 32;
	public const int32 CCS_NODIVIDER = 64;
	public const int32 CCS_VERT = 128;
	public const int32 INVALID_LINK_INDEX = -1;
	public const uint32 MAX_LINKID_TEXT = 48;
	public const String WC_LINK = "SysLink";
	public const uint32 LWS_TRANSPARENT = 1;
	public const uint32 LWS_IGNORERETURN = 2;
	public const uint32 LWS_NOPREFIX = 4;
	public const uint32 LWS_USEVISUALSTYLE = 8;
	public const uint32 LWS_USECUSTOMTEXT = 16;
	public const uint32 LWS_RIGHT = 32;
	public const uint32 LM_HITTEST = 1792;
	public const uint32 LM_GETIDEALHEIGHT = 1793;
	public const uint32 LM_SETITEM = 1794;
	public const uint32 LM_GETITEM = 1795;
	public const uint32 LM_GETIDEALSIZE = 1793;
	public const String WC_LISTVIEWA = "SysListView32";
	public const String WC_LISTVIEWW = "SysListView32";
	public const String WC_LISTVIEW = "SysListView32";
	public const uint32 LVS_ICON = 0;
	public const uint32 LVS_REPORT = 1;
	public const uint32 LVS_SMALLICON = 2;
	public const uint32 LVS_LIST = 3;
	public const uint32 LVS_TYPEMASK = 3;
	public const uint32 LVS_SINGLESEL = 4;
	public const uint32 LVS_SHOWSELALWAYS = 8;
	public const uint32 LVS_SORTASCENDING = 16;
	public const uint32 LVS_SORTDESCENDING = 32;
	public const uint32 LVS_SHAREIMAGELISTS = 64;
	public const uint32 LVS_NOLABELWRAP = 128;
	public const uint32 LVS_AUTOARRANGE = 256;
	public const uint32 LVS_EDITLABELS = 512;
	public const uint32 LVS_OWNERDATA = 4096;
	public const uint32 LVS_NOSCROLL = 8192;
	public const uint32 LVS_TYPESTYLEMASK = 64512;
	public const uint32 LVS_ALIGNTOP = 0;
	public const uint32 LVS_ALIGNLEFT = 2048;
	public const uint32 LVS_ALIGNMASK = 3072;
	public const uint32 LVS_OWNERDRAWFIXED = 1024;
	public const uint32 LVS_NOCOLUMNHEADER = 16384;
	public const uint32 LVS_NOSORTHEADER = 32768;
	public const uint32 LVM_SETUNICODEFORMAT = 8197;
	public const uint32 LVM_GETUNICODEFORMAT = 8198;
	public const uint32 LVM_GETBKCOLOR = 4096;
	public const uint32 LVM_SETBKCOLOR = 4097;
	public const uint32 LVM_GETIMAGELIST = 4098;
	public const uint32 LVSIL_NORMAL = 0;
	public const uint32 LVSIL_SMALL = 1;
	public const uint32 LVSIL_STATE = 2;
	public const uint32 LVSIL_GROUPHEADER = 3;
	public const uint32 LVM_SETIMAGELIST = 4099;
	public const uint32 LVM_GETITEMCOUNT = 4100;
	public const int32 I_INDENTCALLBACK = -1;
	public const int32 I_IMAGECALLBACK = -1;
	public const int32 I_IMAGENONE = -2;
	public const uint32 LVM_GETITEMA = 4101;
	public const uint32 LVM_GETITEMW = 4171;
	public const uint32 LVM_GETITEM = 4171;
	public const uint32 LVM_SETITEMA = 4102;
	public const uint32 LVM_SETITEMW = 4172;
	public const uint32 LVM_SETITEM = 4172;
	public const uint32 LVM_INSERTITEMA = 4103;
	public const uint32 LVM_INSERTITEMW = 4173;
	public const uint32 LVM_INSERTITEM = 4173;
	public const uint32 LVM_DELETEITEM = 4104;
	public const uint32 LVM_DELETEALLITEMS = 4105;
	public const uint32 LVM_GETCALLBACKMASK = 4106;
	public const uint32 LVM_SETCALLBACKMASK = 4107;
	public const uint32 LVNI_ALL = 0;
	public const uint32 LVNI_FOCUSED = 1;
	public const uint32 LVNI_SELECTED = 2;
	public const uint32 LVNI_CUT = 4;
	public const uint32 LVNI_DROPHILITED = 8;
	public const uint32 LVNI_VISIBLEORDER = 16;
	public const uint32 LVNI_PREVIOUS = 32;
	public const uint32 LVNI_VISIBLEONLY = 64;
	public const uint32 LVNI_SAMEGROUPONLY = 128;
	public const uint32 LVNI_ABOVE = 256;
	public const uint32 LVNI_BELOW = 512;
	public const uint32 LVNI_TOLEFT = 1024;
	public const uint32 LVNI_TORIGHT = 2048;
	public const uint32 LVM_GETNEXTITEM = 4108;
	public const uint32 LVM_FINDITEMA = 4109;
	public const uint32 LVM_FINDITEMW = 4179;
	public const uint32 LVM_FINDITEM = 4179;
	public const uint32 LVIR_BOUNDS = 0;
	public const uint32 LVIR_ICON = 1;
	public const uint32 LVIR_LABEL = 2;
	public const uint32 LVIR_SELECTBOUNDS = 3;
	public const uint32 LVM_GETITEMRECT = 4110;
	public const uint32 LVM_SETITEMPOSITION = 4111;
	public const uint32 LVM_GETITEMPOSITION = 4112;
	public const uint32 LVM_GETSTRINGWIDTHA = 4113;
	public const uint32 LVM_GETSTRINGWIDTHW = 4183;
	public const uint32 LVM_GETSTRINGWIDTH = 4183;
	public const uint32 LVM_HITTEST = 4114;
	public const uint32 LVM_ENSUREVISIBLE = 4115;
	public const uint32 LVM_SCROLL = 4116;
	public const uint32 LVM_REDRAWITEMS = 4117;
	public const uint32 LVA_DEFAULT = 0;
	public const uint32 LVA_ALIGNLEFT = 1;
	public const uint32 LVA_ALIGNTOP = 2;
	public const uint32 LVA_SNAPTOGRID = 5;
	public const uint32 LVM_ARRANGE = 4118;
	public const uint32 LVM_EDITLABELA = 4119;
	public const uint32 LVM_EDITLABELW = 4214;
	public const uint32 LVM_EDITLABEL = 4214;
	public const uint32 LVM_GETEDITCONTROL = 4120;
	public const uint32 LVM_GETCOLUMNA = 4121;
	public const uint32 LVM_GETCOLUMNW = 4191;
	public const uint32 LVM_GETCOLUMN = 4191;
	public const uint32 LVM_SETCOLUMNA = 4122;
	public const uint32 LVM_SETCOLUMNW = 4192;
	public const uint32 LVM_SETCOLUMN = 4192;
	public const uint32 LVM_INSERTCOLUMNA = 4123;
	public const uint32 LVM_INSERTCOLUMNW = 4193;
	public const uint32 LVM_INSERTCOLUMN = 4193;
	public const uint32 LVM_DELETECOLUMN = 4124;
	public const uint32 LVM_GETCOLUMNWIDTH = 4125;
	public const int32 LVSCW_AUTOSIZE = -1;
	public const int32 LVSCW_AUTOSIZE_USEHEADER = -2;
	public const uint32 LVM_SETCOLUMNWIDTH = 4126;
	public const uint32 LVM_GETHEADER = 4127;
	public const uint32 LVM_CREATEDRAGIMAGE = 4129;
	public const uint32 LVM_GETVIEWRECT = 4130;
	public const uint32 LVM_GETTEXTCOLOR = 4131;
	public const uint32 LVM_SETTEXTCOLOR = 4132;
	public const uint32 LVM_GETTEXTBKCOLOR = 4133;
	public const uint32 LVM_SETTEXTBKCOLOR = 4134;
	public const uint32 LVM_GETTOPINDEX = 4135;
	public const uint32 LVM_GETCOUNTPERPAGE = 4136;
	public const uint32 LVM_GETORIGIN = 4137;
	public const uint32 LVM_UPDATE = 4138;
	public const uint32 LVM_SETITEMSTATE = 4139;
	public const uint32 LVM_GETITEMSTATE = 4140;
	public const uint32 LVM_GETITEMTEXTA = 4141;
	public const uint32 LVM_GETITEMTEXTW = 4211;
	public const uint32 LVM_GETITEMTEXT = 4211;
	public const uint32 LVM_SETITEMTEXTA = 4142;
	public const uint32 LVM_SETITEMTEXTW = 4212;
	public const uint32 LVM_SETITEMTEXT = 4212;
	public const uint32 LVSICF_NOINVALIDATEALL = 1;
	public const uint32 LVSICF_NOSCROLL = 2;
	public const uint32 LVM_SETITEMCOUNT = 4143;
	public const uint32 LVM_SORTITEMS = 4144;
	public const uint32 LVM_SETITEMPOSITION32 = 4145;
	public const uint32 LVM_GETSELECTEDCOUNT = 4146;
	public const uint32 LVM_GETITEMSPACING = 4147;
	public const uint32 LVM_GETISEARCHSTRINGA = 4148;
	public const uint32 LVM_GETISEARCHSTRINGW = 4213;
	public const uint32 LVM_GETISEARCHSTRING = 4213;
	public const uint32 LVM_SETICONSPACING = 4149;
	public const uint32 LVM_SETEXTENDEDLISTVIEWSTYLE = 4150;
	public const uint32 LVM_GETEXTENDEDLISTVIEWSTYLE = 4151;
	public const uint32 LVS_EX_GRIDLINES = 1;
	public const uint32 LVS_EX_SUBITEMIMAGES = 2;
	public const uint32 LVS_EX_CHECKBOXES = 4;
	public const uint32 LVS_EX_TRACKSELECT = 8;
	public const uint32 LVS_EX_HEADERDRAGDROP = 16;
	public const uint32 LVS_EX_FULLROWSELECT = 32;
	public const uint32 LVS_EX_ONECLICKACTIVATE = 64;
	public const uint32 LVS_EX_TWOCLICKACTIVATE = 128;
	public const uint32 LVS_EX_FLATSB = 256;
	public const uint32 LVS_EX_REGIONAL = 512;
	public const uint32 LVS_EX_INFOTIP = 1024;
	public const uint32 LVS_EX_UNDERLINEHOT = 2048;
	public const uint32 LVS_EX_UNDERLINECOLD = 4096;
	public const uint32 LVS_EX_MULTIWORKAREAS = 8192;
	public const uint32 LVS_EX_LABELTIP = 16384;
	public const uint32 LVS_EX_BORDERSELECT = 32768;
	public const uint32 LVS_EX_DOUBLEBUFFER = 65536;
	public const uint32 LVS_EX_HIDELABELS = 131072;
	public const uint32 LVS_EX_SINGLEROW = 262144;
	public const uint32 LVS_EX_SNAPTOGRID = 524288;
	public const uint32 LVS_EX_SIMPLESELECT = 1048576;
	public const uint32 LVS_EX_JUSTIFYCOLUMNS = 2097152;
	public const uint32 LVS_EX_TRANSPARENTBKGND = 4194304;
	public const uint32 LVS_EX_TRANSPARENTSHADOWTEXT = 8388608;
	public const uint32 LVS_EX_AUTOAUTOARRANGE = 16777216;
	public const uint32 LVS_EX_HEADERINALLVIEWS = 33554432;
	public const uint32 LVS_EX_AUTOCHECKSELECT = 134217728;
	public const uint32 LVS_EX_AUTOSIZECOLUMNS = 268435456;
	public const uint32 LVS_EX_COLUMNSNAPPOINTS = 1073741824;
	public const uint32 LVS_EX_COLUMNOVERFLOW = 2147483648;
	public const uint32 LVM_GETSUBITEMRECT = 4152;
	public const uint32 LVM_SUBITEMHITTEST = 4153;
	public const uint32 LVM_SETCOLUMNORDERARRAY = 4154;
	public const uint32 LVM_GETCOLUMNORDERARRAY = 4155;
	public const uint32 LVM_SETHOTITEM = 4156;
	public const uint32 LVM_GETHOTITEM = 4157;
	public const uint32 LVM_SETHOTCURSOR = 4158;
	public const uint32 LVM_GETHOTCURSOR = 4159;
	public const uint32 LVM_APPROXIMATEVIEWRECT = 4160;
	public const uint32 LV_MAX_WORKAREAS = 16;
	public const uint32 LVM_SETWORKAREAS = 4161;
	public const uint32 LVM_GETWORKAREAS = 4166;
	public const uint32 LVM_GETNUMBEROFWORKAREAS = 4169;
	public const uint32 LVM_GETSELECTIONMARK = 4162;
	public const uint32 LVM_SETSELECTIONMARK = 4163;
	public const uint32 LVM_SETHOVERTIME = 4167;
	public const uint32 LVM_GETHOVERTIME = 4168;
	public const uint32 LVM_SETTOOLTIPS = 4170;
	public const uint32 LVM_GETTOOLTIPS = 4174;
	public const uint32 LVM_SORTITEMSEX = 4177;
	public const uint32 LVM_SETBKIMAGEA = 4164;
	public const uint32 LVM_SETBKIMAGEW = 4234;
	public const uint32 LVM_GETBKIMAGEA = 4165;
	public const uint32 LVM_GETBKIMAGEW = 4235;
	public const uint32 LVM_SETSELECTEDCOLUMN = 4236;
	public const uint32 LV_VIEW_ICON = 0;
	public const uint32 LV_VIEW_DETAILS = 1;
	public const uint32 LV_VIEW_SMALLICON = 2;
	public const uint32 LV_VIEW_LIST = 3;
	public const uint32 LV_VIEW_TILE = 4;
	public const uint32 LV_VIEW_MAX = 4;
	public const uint32 LVM_SETVIEW = 4238;
	public const uint32 LVM_GETVIEW = 4239;
	public const uint32 LVGF_ALIGN = 8;
	public const uint32 LVGF_GROUPID = 16;
	public const uint32 LVGF_SUBTITLE = 256;
	public const uint32 LVGF_TASK = 512;
	public const uint32 LVGF_DESCRIPTIONTOP = 1024;
	public const uint32 LVGF_DESCRIPTIONBOTTOM = 2048;
	public const uint32 LVGF_TITLEIMAGE = 4096;
	public const uint32 LVGF_EXTENDEDIMAGE = 8192;
	public const uint32 LVGF_ITEMS = 16384;
	public const uint32 LVGF_SUBSET = 32768;
	public const uint32 LVGF_SUBSETITEMS = 65536;
	public const uint32 LVM_INSERTGROUP = 4241;
	public const uint32 LVM_SETGROUPINFO = 4243;
	public const uint32 LVM_GETGROUPINFO = 4245;
	public const uint32 LVM_REMOVEGROUP = 4246;
	public const uint32 LVM_MOVEGROUP = 4247;
	public const uint32 LVM_GETGROUPCOUNT = 4248;
	public const uint32 LVM_GETGROUPINFOBYINDEX = 4249;
	public const uint32 LVM_MOVEITEMTOGROUP = 4250;
	public const uint32 LVGGR_GROUP = 0;
	public const uint32 LVGGR_HEADER = 1;
	public const uint32 LVGGR_LABEL = 2;
	public const uint32 LVGGR_SUBSETLINK = 3;
	public const uint32 LVM_GETGROUPRECT = 4194;
	public const uint32 LVGMF_NONE = 0;
	public const uint32 LVGMF_BORDERSIZE = 1;
	public const uint32 LVGMF_BORDERCOLOR = 2;
	public const uint32 LVGMF_TEXTCOLOR = 4;
	public const uint32 LVM_SETGROUPMETRICS = 4251;
	public const uint32 LVM_GETGROUPMETRICS = 4252;
	public const uint32 LVM_ENABLEGROUPVIEW = 4253;
	public const uint32 LVM_SORTGROUPS = 4254;
	public const uint32 LVM_INSERTGROUPSORTED = 4255;
	public const uint32 LVM_REMOVEALLGROUPS = 4256;
	public const uint32 LVM_HASGROUP = 4257;
	public const uint32 LVM_GETGROUPSTATE = 4188;
	public const uint32 LVM_GETFOCUSEDGROUP = 4189;
	public const uint32 LVTVIF_EXTENDED = 4;
	public const uint32 LVM_SETTILEVIEWINFO = 4258;
	public const uint32 LVM_GETTILEVIEWINFO = 4259;
	public const uint32 LVM_SETTILEINFO = 4260;
	public const uint32 LVM_GETTILEINFO = 4261;
	public const uint32 LVM_SETINSERTMARK = 4262;
	public const uint32 LVM_GETINSERTMARK = 4263;
	public const uint32 LVM_INSERTMARKHITTEST = 4264;
	public const uint32 LVM_GETINSERTMARKRECT = 4265;
	public const uint32 LVM_SETINSERTMARKCOLOR = 4266;
	public const uint32 LVM_GETINSERTMARKCOLOR = 4267;
	public const uint32 LVM_SETINFOTIP = 4269;
	public const uint32 LVM_GETSELECTEDCOLUMN = 4270;
	public const uint32 LVM_ISGROUPVIEWENABLED = 4271;
	public const uint32 LVM_GETOUTLINECOLOR = 4272;
	public const uint32 LVM_SETOUTLINECOLOR = 4273;
	public const uint32 LVM_CANCELEDITLABEL = 4275;
	public const uint32 LVM_MAPINDEXTOID = 4276;
	public const uint32 LVM_MAPIDTOINDEX = 4277;
	public const uint32 LVM_ISITEMVISIBLE = 4278;
	public const uint32 LVM_GETEMPTYTEXT = 4300;
	public const uint32 LVM_GETFOOTERRECT = 4301;
	public const uint32 LVFF_ITEMCOUNT = 1;
	public const uint32 LVM_GETFOOTERINFO = 4302;
	public const uint32 LVM_GETFOOTERITEMRECT = 4303;
	public const uint32 LVFIS_FOCUSED = 1;
	public const uint32 LVM_GETFOOTERITEM = 4304;
	public const uint32 LVM_GETITEMINDEXRECT = 4305;
	public const uint32 LVM_SETITEMINDEXSTATE = 4306;
	public const uint32 LVM_GETNEXTITEMINDEX = 4307;
	public const uint32 LVM_SETBKIMAGE = 4234;
	public const uint32 LVM_GETBKIMAGE = 4235;
	public const uint32 LVKF_ALT = 1;
	public const uint32 LVKF_CONTROL = 2;
	public const uint32 LVKF_SHIFT = 4;
	public const uint32 LVCDRF_NOSELECT = 65536;
	public const uint32 LVCDRF_NOGROUPFRAME = 131072;
	public const int32 LVNSCH_DEFAULT = -1;
	public const int32 LVNSCH_ERROR = -2;
	public const int32 LVNSCH_IGNORE = -3;
	public const String WC_TREEVIEWA = "SysTreeView32";
	public const String WC_TREEVIEWW = "SysTreeView32";
	public const String WC_TREEVIEW = "SysTreeView32";
	public const uint32 TVS_HASBUTTONS = 1;
	public const uint32 TVS_HASLINES = 2;
	public const uint32 TVS_LINESATROOT = 4;
	public const uint32 TVS_EDITLABELS = 8;
	public const uint32 TVS_DISABLEDRAGDROP = 16;
	public const uint32 TVS_SHOWSELALWAYS = 32;
	public const uint32 TVS_RTLREADING = 64;
	public const uint32 TVS_NOTOOLTIPS = 128;
	public const uint32 TVS_CHECKBOXES = 256;
	public const uint32 TVS_TRACKSELECT = 512;
	public const uint32 TVS_SINGLEEXPAND = 1024;
	public const uint32 TVS_INFOTIP = 2048;
	public const uint32 TVS_FULLROWSELECT = 4096;
	public const uint32 TVS_NOSCROLL = 8192;
	public const uint32 TVS_NONEVENHEIGHT = 16384;
	public const uint32 TVS_NOHSCROLL = 32768;
	public const uint32 TVS_EX_NOSINGLECOLLAPSE = 1;
	public const uint32 TVS_EX_MULTISELECT = 2;
	public const uint32 TVS_EX_DOUBLEBUFFER = 4;
	public const uint32 TVS_EX_NOINDENTSTATE = 8;
	public const uint32 TVS_EX_RICHTOOLTIP = 16;
	public const uint32 TVS_EX_AUTOHSCROLL = 32;
	public const uint32 TVS_EX_FADEINOUTEXPANDOS = 64;
	public const uint32 TVS_EX_PARTIALCHECKBOXES = 128;
	public const uint32 TVS_EX_EXCLUSIONCHECKBOXES = 256;
	public const uint32 TVS_EX_DIMMEDCHECKBOXES = 512;
	public const uint32 TVS_EX_DRAWIMAGEASYNC = 1024;
	public const uint32 TVM_INSERTITEMA = 4352;
	public const uint32 TVM_INSERTITEMW = 4402;
	public const uint32 TVM_INSERTITEM = 4402;
	public const uint32 TVM_DELETEITEM = 4353;
	public const uint32 TVM_EXPAND = 4354;
	public const uint32 TVM_GETITEMRECT = 4356;
	public const uint32 TVM_GETCOUNT = 4357;
	public const uint32 TVM_GETINDENT = 4358;
	public const uint32 TVM_SETINDENT = 4359;
	public const uint32 TVM_GETIMAGELIST = 4360;
	public const uint32 TVSIL_NORMAL = 0;
	public const uint32 TVSIL_STATE = 2;
	public const uint32 TVM_SETIMAGELIST = 4361;
	public const uint32 TVM_GETNEXTITEM = 4362;
	public const uint32 TVGN_ROOT = 0;
	public const uint32 TVGN_NEXT = 1;
	public const uint32 TVGN_PREVIOUS = 2;
	public const uint32 TVGN_PARENT = 3;
	public const uint32 TVGN_CHILD = 4;
	public const uint32 TVGN_FIRSTVISIBLE = 5;
	public const uint32 TVGN_NEXTVISIBLE = 6;
	public const uint32 TVGN_PREVIOUSVISIBLE = 7;
	public const uint32 TVGN_DROPHILITE = 8;
	public const uint32 TVGN_CARET = 9;
	public const uint32 TVGN_LASTVISIBLE = 10;
	public const uint32 TVGN_NEXTSELECTED = 11;
	public const uint32 TVSI_NOSINGLEEXPAND = 32768;
	public const uint32 TVM_SELECTITEM = 4363;
	public const uint32 TVM_GETITEMA = 4364;
	public const uint32 TVM_GETITEMW = 4414;
	public const uint32 TVM_GETITEM = 4414;
	public const uint32 TVM_SETITEMA = 4365;
	public const uint32 TVM_SETITEMW = 4415;
	public const uint32 TVM_SETITEM = 4415;
	public const uint32 TVM_EDITLABELA = 4366;
	public const uint32 TVM_EDITLABELW = 4417;
	public const uint32 TVM_EDITLABEL = 4417;
	public const uint32 TVM_GETEDITCONTROL = 4367;
	public const uint32 TVM_GETVISIBLECOUNT = 4368;
	public const uint32 TVM_HITTEST = 4369;
	public const uint32 TVM_CREATEDRAGIMAGE = 4370;
	public const uint32 TVM_SORTCHILDREN = 4371;
	public const uint32 TVM_ENSUREVISIBLE = 4372;
	public const uint32 TVM_SORTCHILDRENCB = 4373;
	public const uint32 TVM_ENDEDITLABELNOW = 4374;
	public const uint32 TVM_GETISEARCHSTRINGA = 4375;
	public const uint32 TVM_GETISEARCHSTRINGW = 4416;
	public const uint32 TVM_GETISEARCHSTRING = 4416;
	public const uint32 TVM_SETTOOLTIPS = 4376;
	public const uint32 TVM_GETTOOLTIPS = 4377;
	public const uint32 TVM_SETINSERTMARK = 4378;
	public const uint32 TVM_SETUNICODEFORMAT = 8197;
	public const uint32 TVM_GETUNICODEFORMAT = 8198;
	public const uint32 TVM_SETITEMHEIGHT = 4379;
	public const uint32 TVM_GETITEMHEIGHT = 4380;
	public const uint32 TVM_SETBKCOLOR = 4381;
	public const uint32 TVM_SETTEXTCOLOR = 4382;
	public const uint32 TVM_GETBKCOLOR = 4383;
	public const uint32 TVM_GETTEXTCOLOR = 4384;
	public const uint32 TVM_SETSCROLLTIME = 4385;
	public const uint32 TVM_GETSCROLLTIME = 4386;
	public const uint32 TVM_SETINSERTMARKCOLOR = 4389;
	public const uint32 TVM_GETINSERTMARKCOLOR = 4390;
	public const uint32 TVM_SETBORDER = 4387;
	public const uint32 TVSBF_XBORDER = 1;
	public const uint32 TVSBF_YBORDER = 2;
	public const uint32 TVM_GETITEMSTATE = 4391;
	public const uint32 TVM_SETLINECOLOR = 4392;
	public const uint32 TVM_GETLINECOLOR = 4393;
	public const uint32 TVM_MAPACCIDTOHTREEITEM = 4394;
	public const uint32 TVM_MAPHTREEITEMTOACCID = 4395;
	public const uint32 TVM_SETEXTENDEDSTYLE = 4396;
	public const uint32 TVM_GETEXTENDEDSTYLE = 4397;
	public const uint32 TVM_SETAUTOSCROLLINFO = 4411;
	public const uint32 TVM_SETHOT = 4410;
	public const uint32 TVM_GETSELECTEDCOUNT = 4422;
	public const uint32 TVM_SHOWINFOTIP = 4423;
	public const uint32 TVM_GETITEMPARTRECT = 4424;
	public const uint32 TVNRET_DEFAULT = 0;
	public const uint32 TVNRET_SKIPOLD = 1;
	public const uint32 TVNRET_SKIPNEW = 2;
	public const uint32 TVCDRF_NOIMAGES = 65536;
	public const String WC_COMBOBOXEXW = "ComboBoxEx32";
	public const String WC_COMBOBOXEXA = "ComboBoxEx32";
	public const String WC_COMBOBOXEX = "ComboBoxEx32";
	public const uint32 CBEM_INSERTITEMA = 1025;
	public const uint32 CBEM_SETIMAGELIST = 1026;
	public const uint32 CBEM_GETIMAGELIST = 1027;
	public const uint32 CBEM_GETITEMA = 1028;
	public const uint32 CBEM_SETITEMA = 1029;
	public const uint32 CBEM_GETCOMBOCONTROL = 1030;
	public const uint32 CBEM_GETEDITCONTROL = 1031;
	public const uint32 CBEM_SETEXSTYLE = 1032;
	public const uint32 CBEM_SETEXTENDEDSTYLE = 1038;
	public const uint32 CBEM_GETEXSTYLE = 1033;
	public const uint32 CBEM_GETEXTENDEDSTYLE = 1033;
	public const uint32 CBEM_SETUNICODEFORMAT = 8197;
	public const uint32 CBEM_GETUNICODEFORMAT = 8198;
	public const uint32 CBEM_HASEDITCHANGED = 1034;
	public const uint32 CBEM_INSERTITEMW = 1035;
	public const uint32 CBEM_SETITEMW = 1036;
	public const uint32 CBEM_GETITEMW = 1037;
	public const uint32 CBEM_INSERTITEM = 1035;
	public const uint32 CBEM_SETITEM = 1036;
	public const uint32 CBEM_GETITEM = 1037;
	public const uint32 CBEM_SETWINDOWTHEME = 8203;
	public const uint32 CBES_EX_NOEDITIMAGE = 1;
	public const uint32 CBES_EX_NOEDITIMAGEINDENT = 2;
	public const uint32 CBES_EX_PATHWORDBREAKPROC = 4;
	public const uint32 CBES_EX_NOSIZELIMIT = 8;
	public const uint32 CBES_EX_CASESENSITIVE = 16;
	public const uint32 CBES_EX_TEXTENDELLIPSIS = 32;
	public const uint32 CBENF_KILLFOCUS = 1;
	public const uint32 CBENF_RETURN = 2;
	public const uint32 CBENF_ESCAPE = 3;
	public const uint32 CBENF_DROPDOWN = 4;
	public const uint32 CBEMAXSTRLEN = 260;
	public const String WC_TABCONTROLA = "SysTabControl32";
	public const String WC_TABCONTROLW = "SysTabControl32";
	public const String WC_TABCONTROL = "SysTabControl32";
	public const uint32 TCS_SCROLLOPPOSITE = 1;
	public const uint32 TCS_BOTTOM = 2;
	public const uint32 TCS_RIGHT = 2;
	public const uint32 TCS_MULTISELECT = 4;
	public const uint32 TCS_FLATBUTTONS = 8;
	public const uint32 TCS_FORCEICONLEFT = 16;
	public const uint32 TCS_FORCELABELLEFT = 32;
	public const uint32 TCS_HOTTRACK = 64;
	public const uint32 TCS_VERTICAL = 128;
	public const uint32 TCS_TABS = 0;
	public const uint32 TCS_BUTTONS = 256;
	public const uint32 TCS_SINGLELINE = 0;
	public const uint32 TCS_MULTILINE = 512;
	public const uint32 TCS_RIGHTJUSTIFY = 0;
	public const uint32 TCS_FIXEDWIDTH = 1024;
	public const uint32 TCS_RAGGEDRIGHT = 2048;
	public const uint32 TCS_FOCUSONBUTTONDOWN = 4096;
	public const uint32 TCS_OWNERDRAWFIXED = 8192;
	public const uint32 TCS_TOOLTIPS = 16384;
	public const uint32 TCS_FOCUSNEVER = 32768;
	public const uint32 TCS_EX_FLATSEPARATORS = 1;
	public const uint32 TCS_EX_REGISTERDROP = 2;
	public const uint32 TCM_GETIMAGELIST = 4866;
	public const uint32 TCM_SETIMAGELIST = 4867;
	public const uint32 TCM_GETITEMCOUNT = 4868;
	public const uint32 TCM_GETITEMA = 4869;
	public const uint32 TCM_GETITEMW = 4924;
	public const uint32 TCM_GETITEM = 4924;
	public const uint32 TCM_SETITEMA = 4870;
	public const uint32 TCM_SETITEMW = 4925;
	public const uint32 TCM_SETITEM = 4925;
	public const uint32 TCM_INSERTITEMA = 4871;
	public const uint32 TCM_INSERTITEMW = 4926;
	public const uint32 TCM_INSERTITEM = 4926;
	public const uint32 TCM_DELETEITEM = 4872;
	public const uint32 TCM_DELETEALLITEMS = 4873;
	public const uint32 TCM_GETITEMRECT = 4874;
	public const uint32 TCM_GETCURSEL = 4875;
	public const uint32 TCM_SETCURSEL = 4876;
	public const uint32 TCM_HITTEST = 4877;
	public const uint32 TCM_SETITEMEXTRA = 4878;
	public const uint32 TCM_ADJUSTRECT = 4904;
	public const uint32 TCM_SETITEMSIZE = 4905;
	public const uint32 TCM_REMOVEIMAGE = 4906;
	public const uint32 TCM_SETPADDING = 4907;
	public const uint32 TCM_GETROWCOUNT = 4908;
	public const uint32 TCM_GETTOOLTIPS = 4909;
	public const uint32 TCM_SETTOOLTIPS = 4910;
	public const uint32 TCM_GETCURFOCUS = 4911;
	public const uint32 TCM_SETCURFOCUS = 4912;
	public const uint32 TCM_SETMINTABWIDTH = 4913;
	public const uint32 TCM_DESELECTALL = 4914;
	public const uint32 TCM_HIGHLIGHTITEM = 4915;
	public const uint32 TCM_SETEXTENDEDSTYLE = 4916;
	public const uint32 TCM_GETEXTENDEDSTYLE = 4917;
	public const uint32 TCM_SETUNICODEFORMAT = 8197;
	public const uint32 TCM_GETUNICODEFORMAT = 8198;
	public const String ANIMATE_CLASSW = "SysAnimate32";
	public const String ANIMATE_CLASSA = "SysAnimate32";
	public const String ANIMATE_CLASS = "SysAnimate32";
	public const uint32 ACS_CENTER = 1;
	public const uint32 ACS_TRANSPARENT = 2;
	public const uint32 ACS_AUTOPLAY = 4;
	public const uint32 ACS_TIMER = 8;
	public const uint32 ACM_OPENA = 1124;
	public const uint32 ACM_OPENW = 1127;
	public const uint32 ACM_OPEN = 1127;
	public const uint32 ACM_PLAY = 1125;
	public const uint32 ACM_STOP = 1126;
	public const uint32 ACM_ISPLAYING = 1128;
	public const uint32 ACN_START = 1;
	public const uint32 ACN_STOP = 2;
	public const String MONTHCAL_CLASSW = "SysMonthCal32";
	public const String MONTHCAL_CLASSA = "SysMonthCal32";
	public const String MONTHCAL_CLASS = "SysMonthCal32";
	public const uint32 MCM_FIRST = 4096;
	public const uint32 MCM_GETCURSEL = 4097;
	public const uint32 MCM_SETCURSEL = 4098;
	public const uint32 MCM_GETMAXSELCOUNT = 4099;
	public const uint32 MCM_SETMAXSELCOUNT = 4100;
	public const uint32 MCM_GETSELRANGE = 4101;
	public const uint32 MCM_SETSELRANGE = 4102;
	public const uint32 MCM_GETMONTHRANGE = 4103;
	public const uint32 MCM_SETDAYSTATE = 4104;
	public const uint32 MCM_GETMINREQRECT = 4105;
	public const uint32 MCM_SETCOLOR = 4106;
	public const uint32 MCM_GETCOLOR = 4107;
	public const uint32 MCSC_BACKGROUND = 0;
	public const uint32 MCSC_TEXT = 1;
	public const uint32 MCSC_TITLEBK = 2;
	public const uint32 MCSC_TITLETEXT = 3;
	public const uint32 MCSC_MONTHBK = 4;
	public const uint32 MCSC_TRAILINGTEXT = 5;
	public const uint32 MCM_SETTODAY = 4108;
	public const uint32 MCM_GETTODAY = 4109;
	public const uint32 MCM_HITTEST = 4110;
	public const uint32 MCM_SETFIRSTDAYOFWEEK = 4111;
	public const uint32 MCM_GETFIRSTDAYOFWEEK = 4112;
	public const uint32 MCM_GETRANGE = 4113;
	public const uint32 MCM_SETRANGE = 4114;
	public const uint32 MCM_GETMONTHDELTA = 4115;
	public const uint32 MCM_SETMONTHDELTA = 4116;
	public const uint32 MCM_GETMAXTODAYWIDTH = 4117;
	public const uint32 MCM_SETUNICODEFORMAT = 8197;
	public const uint32 MCM_GETUNICODEFORMAT = 8198;
	public const uint32 MCM_GETCURRENTVIEW = 4118;
	public const uint32 MCM_GETCALENDARCOUNT = 4119;
	public const uint32 MCM_GETCALENDARGRIDINFO = 4120;
	public const uint32 MCM_GETCALID = 4123;
	public const uint32 MCM_SETCALID = 4124;
	public const uint32 MCM_SIZERECTTOMIN = 4125;
	public const uint32 MCM_SETCALENDARBORDER = 4126;
	public const uint32 MCM_GETCALENDARBORDER = 4127;
	public const uint32 MCM_SETCURRENTVIEW = 4128;
	public const uint32 MCS_DAYSTATE = 1;
	public const uint32 MCS_MULTISELECT = 2;
	public const uint32 MCS_WEEKNUMBERS = 4;
	public const uint32 MCS_NOTODAYCIRCLE = 8;
	public const uint32 MCS_NOTODAY = 16;
	public const uint32 MCS_NOTRAILINGDATES = 64;
	public const uint32 MCS_SHORTDAYSOFWEEK = 128;
	public const uint32 MCS_NOSELCHANGEONNAV = 256;
	public const uint32 GMR_VISIBLE = 0;
	public const uint32 GMR_DAYSTATE = 1;
	public const String DATETIMEPICK_CLASSW = "SysDateTimePick32";
	public const String DATETIMEPICK_CLASSA = "SysDateTimePick32";
	public const String DATETIMEPICK_CLASS = "SysDateTimePick32";
	public const uint32 DTM_FIRST = 4096;
	public const uint32 DTM_GETSYSTEMTIME = 4097;
	public const uint32 DTM_SETSYSTEMTIME = 4098;
	public const uint32 DTM_GETRANGE = 4099;
	public const uint32 DTM_SETRANGE = 4100;
	public const uint32 DTM_SETFORMATA = 4101;
	public const uint32 DTM_SETFORMATW = 4146;
	public const uint32 DTM_SETFORMAT = 4146;
	public const uint32 DTM_SETMCCOLOR = 4102;
	public const uint32 DTM_GETMCCOLOR = 4103;
	public const uint32 DTM_GETMONTHCAL = 4104;
	public const uint32 DTM_SETMCFONT = 4105;
	public const uint32 DTM_GETMCFONT = 4106;
	public const uint32 DTM_SETMCSTYLE = 4107;
	public const uint32 DTM_GETMCSTYLE = 4108;
	public const uint32 DTM_CLOSEMONTHCAL = 4109;
	public const uint32 DTM_GETDATETIMEPICKERINFO = 4110;
	public const uint32 DTM_GETIDEALSIZE = 4111;
	public const uint32 DTS_UPDOWN = 1;
	public const uint32 DTS_SHOWNONE = 2;
	public const uint32 DTS_SHORTDATEFORMAT = 0;
	public const uint32 DTS_LONGDATEFORMAT = 4;
	public const uint32 DTS_SHORTDATECENTURYFORMAT = 12;
	public const uint32 DTS_TIMEFORMAT = 9;
	public const uint32 DTS_APPCANPARSE = 16;
	public const uint32 DTS_RIGHTALIGN = 32;
	public const uint32 GDTR_MIN = 1;
	public const uint32 GDTR_MAX = 2;
	public const int32 GDT_ERROR = -1;
	public const uint32 IPM_CLEARADDRESS = 1124;
	public const uint32 IPM_SETADDRESS = 1125;
	public const uint32 IPM_GETADDRESS = 1126;
	public const uint32 IPM_SETRANGE = 1127;
	public const uint32 IPM_SETFOCUS = 1128;
	public const uint32 IPM_ISBLANK = 1129;
	public const String WC_IPADDRESSW = "SysIPAddress32";
	public const String WC_IPADDRESSA = "SysIPAddress32";
	public const String WC_IPADDRESS = "SysIPAddress32";
	public const String WC_PAGESCROLLERW = "SysPager";
	public const String WC_PAGESCROLLERA = "SysPager";
	public const String WC_PAGESCROLLER = "SysPager";
	public const uint32 PGS_VERT = 0;
	public const uint32 PGS_HORZ = 1;
	public const uint32 PGS_AUTOSCROLL = 2;
	public const uint32 PGS_DRAGNDROP = 4;
	public const uint32 PGF_INVISIBLE = 0;
	public const uint32 PGF_NORMAL = 1;
	public const uint32 PGF_GRAYED = 2;
	public const uint32 PGF_DEPRESSED = 4;
	public const uint32 PGF_HOT = 8;
	public const uint32 PGB_TOPORLEFT = 0;
	public const uint32 PGB_BOTTOMORRIGHT = 1;
	public const uint32 PGM_SETCHILD = 5121;
	public const uint32 PGM_RECALCSIZE = 5122;
	public const uint32 PGM_FORWARDMOUSE = 5123;
	public const uint32 PGM_SETBKCOLOR = 5124;
	public const uint32 PGM_GETBKCOLOR = 5125;
	public const uint32 PGM_SETBORDER = 5126;
	public const uint32 PGM_GETBORDER = 5127;
	public const uint32 PGM_SETPOS = 5128;
	public const uint32 PGM_GETPOS = 5129;
	public const uint32 PGM_SETBUTTONSIZE = 5130;
	public const uint32 PGM_GETBUTTONSIZE = 5131;
	public const uint32 PGM_GETBUTTONSTATE = 5132;
	public const uint32 PGM_GETDROPTARGET = 8196;
	public const uint32 PGM_SETSCROLLINFO = 5133;
	public const String WC_NATIVEFONTCTLW = "NativeFontCtl";
	public const String WC_NATIVEFONTCTLA = "NativeFontCtl";
	public const String WC_NATIVEFONTCTL = "NativeFontCtl";
	public const uint32 NFS_EDIT = 1;
	public const uint32 NFS_STATIC = 2;
	public const uint32 NFS_LISTCOMBO = 4;
	public const uint32 NFS_BUTTON = 8;
	public const uint32 NFS_ALL = 16;
	public const uint32 NFS_USEFONTASSOC = 32;
	public const String WC_BUTTONA = "Button";
	public const String WC_BUTTONW = "Button";
	public const String WC_BUTTON = "Button";
	public const uint32 BCM_GETIDEALSIZE = 5633;
	public const uint32 BCM_SETIMAGELIST = 5634;
	public const uint32 BCM_GETIMAGELIST = 5635;
	public const uint32 BCM_SETTEXTMARGIN = 5636;
	public const uint32 BCM_GETTEXTMARGIN = 5637;
	public const uint32 BCN_HOTITEMCHANGE = 4294966047;
	public const uint32 BST_HOT = 512;
	public const uint32 BST_DROPDOWNPUSHED = 1024;
	public const int32 BS_SPLITBUTTON = 12;
	public const int32 BS_DEFSPLITBUTTON = 13;
	public const int32 BS_COMMANDLINK = 14;
	public const int32 BS_DEFCOMMANDLINK = 15;
	public const uint32 BCSIF_GLYPH = 1;
	public const uint32 BCSIF_IMAGE = 2;
	public const uint32 BCSIF_STYLE = 4;
	public const uint32 BCSIF_SIZE = 8;
	public const uint32 BCSS_NOSPLIT = 1;
	public const uint32 BCSS_STRETCH = 2;
	public const uint32 BCSS_ALIGNLEFT = 4;
	public const uint32 BCSS_IMAGE = 8;
	public const uint32 BCM_SETDROPDOWNSTATE = 5638;
	public const uint32 BCM_SETSPLITINFO = 5639;
	public const uint32 BCM_GETSPLITINFO = 5640;
	public const uint32 BCM_SETNOTE = 5641;
	public const uint32 BCM_GETNOTE = 5642;
	public const uint32 BCM_GETNOTELENGTH = 5643;
	public const uint32 BCM_SETSHIELD = 5644;
	public const uint32 BCN_DROPDOWN = 4294966048;
	public const String WC_STATICA = "Static";
	public const String WC_STATICW = "Static";
	public const String WC_STATIC = "Static";
	public const String WC_EDITA = "Edit";
	public const String WC_EDITW = "Edit";
	public const String WC_EDIT = "Edit";
	public const int32 ES_EX_ALLOWEOL_CR = 1;
	public const int32 ES_EX_ALLOWEOL_LF = 2;
	public const int32 ES_EX_CONVERT_EOL_ON_PASTE = 4;
	public const int32 ES_EX_ZOOMABLE = 16;
	public const uint32 EM_SETCUEBANNER = 5377;
	public const uint32 EM_GETCUEBANNER = 5378;
	public const uint32 EM_SHOWBALLOONTIP = 5379;
	public const uint32 EM_HIDEBALLOONTIP = 5380;
	public const uint32 EM_SETHILITE = 5381;
	public const uint32 EM_GETHILITE = 5382;
	public const uint32 EM_NOSETFOCUS = 5383;
	public const uint32 EM_TAKEFOCUS = 5384;
	public const uint32 EM_SETEXTENDEDSTYLE = 5386;
	public const uint32 EM_GETEXTENDEDSTYLE = 5387;
	public const uint32 EM_SETENDOFLINE = 5388;
	public const uint32 EM_GETENDOFLINE = 5389;
	public const uint32 EM_ENABLESEARCHWEB = 5390;
	public const uint32 EM_SEARCHWEB = 5391;
	public const uint32 EM_SETCARETINDEX = 5393;
	public const uint32 EM_GETCARETINDEX = 5394;
	public const uint32 EM_FILELINEFROMCHAR = 5395;
	public const uint32 EM_FILELINEINDEX = 5396;
	public const uint32 EM_FILELINELENGTH = 5397;
	public const uint32 EM_GETFILELINE = 5398;
	public const uint32 EM_GETFILELINECOUNT = 5399;
	public const String WC_LISTBOXA = "ListBox";
	public const String WC_LISTBOXW = "ListBox";
	public const String WC_LISTBOX = "ListBox";
	public const String WC_COMBOBOXA = "ComboBox";
	public const String WC_COMBOBOXW = "ComboBox";
	public const String WC_COMBOBOX = "ComboBox";
	public const uint32 CB_SETMINVISIBLE = 5889;
	public const uint32 CB_GETMINVISIBLE = 5890;
	public const uint32 CB_SETCUEBANNER = 5891;
	public const uint32 CB_GETCUEBANNER = 5892;
	public const String WC_SCROLLBARA = "ScrollBar";
	public const String WC_SCROLLBARW = "ScrollBar";
	public const String WC_SCROLLBAR = "ScrollBar";
	public const PWSTR TD_WARNING_ICON = (PWSTR)(void*)-1;
	public const PWSTR TD_ERROR_ICON = (PWSTR)(void*)-2;
	public const PWSTR TD_INFORMATION_ICON = (PWSTR)(void*)-3;
	public const PWSTR TD_SHIELD_ICON = (PWSTR)(void*)-4;
	public const uint32 WM_MOUSEHOVER = 673;
	public const uint32 WM_MOUSELEAVE = 675;
	public const uint32 HOVER_DEFAULT = 4294967295;
	public const int32 WSB_PROP_MASK = 4095;
	public const uint32 FSB_FLAT_MODE = 2;
	public const uint32 FSB_ENCARTA_MODE = 1;
	public const uint32 FSB_REGULAR_MODE = 0;
	public const uint32 ILDRF_IMAGELOWQUALITY = 1;
	public const uint32 ILDRF_OVERLAYLOWQUALITY = 16;
	public const uint32 ILR_DEFAULT = 0;
	public const uint32 ILR_HORIZONTAL_LEFT = 0;
	public const uint32 ILR_HORIZONTAL_CENTER = 1;
	public const uint32 ILR_HORIZONTAL_RIGHT = 2;
	public const uint32 ILR_VERTICAL_TOP = 0;
	public const uint32 ILR_VERTICAL_CENTER = 16;
	public const uint32 ILR_VERTICAL_BOTTOM = 32;
	public const uint32 ILR_SCALE_CLIP = 0;
	public const uint32 ILR_SCALE_ASPECTRATIO = 256;
	public const uint32 ILGOS_ALWAYS = 0;
	public const uint32 ILGOS_FROMSTANDBY = 1;
	public const uint32 ILFIP_ALWAYS = 0;
	public const uint32 ILFIP_FROMSTANDBY = 1;
	public const uint32 ILDI_PURGE = 1;
	public const uint32 ILDI_STANDBY = 2;
	public const uint32 ILDI_RESETACCESS = 4;
	public const uint32 ILDI_QUERYACCESS = 8;
	public const uint32 CCHCCCLASS = 32;
	public const uint32 CCHCCDESC = 32;
	public const uint32 CCHCCTEXT = 256;
	public const uint32 CCF_NOTEXT = 1;
	public const uint32 ctlFirst = 1024;
	public const uint32 ctlLast = 1279;
	public const uint32 psh1 = 1024;
	public const uint32 psh2 = 1025;
	public const uint32 psh3 = 1026;
	public const uint32 psh4 = 1027;
	public const uint32 psh5 = 1028;
	public const uint32 psh6 = 1029;
	public const uint32 psh7 = 1030;
	public const uint32 psh8 = 1031;
	public const uint32 psh9 = 1032;
	public const uint32 psh10 = 1033;
	public const uint32 psh11 = 1034;
	public const uint32 psh12 = 1035;
	public const uint32 psh13 = 1036;
	public const uint32 psh14 = 1037;
	public const uint32 psh15 = 1038;
	public const uint32 pshHelp = 1038;
	public const uint32 psh16 = 1039;
	public const uint32 chx1 = 1040;
	public const uint32 chx2 = 1041;
	public const uint32 chx3 = 1042;
	public const uint32 chx4 = 1043;
	public const uint32 chx5 = 1044;
	public const uint32 chx6 = 1045;
	public const uint32 chx7 = 1046;
	public const uint32 chx8 = 1047;
	public const uint32 chx9 = 1048;
	public const uint32 chx10 = 1049;
	public const uint32 chx11 = 1050;
	public const uint32 chx12 = 1051;
	public const uint32 chx13 = 1052;
	public const uint32 chx14 = 1053;
	public const uint32 chx15 = 1054;
	public const uint32 chx16 = 1055;
	public const uint32 rad1 = 1056;
	public const uint32 rad2 = 1057;
	public const uint32 rad3 = 1058;
	public const uint32 rad4 = 1059;
	public const uint32 rad5 = 1060;
	public const uint32 rad6 = 1061;
	public const uint32 rad7 = 1062;
	public const uint32 rad8 = 1063;
	public const uint32 rad9 = 1064;
	public const uint32 rad10 = 1065;
	public const uint32 rad11 = 1066;
	public const uint32 rad12 = 1067;
	public const uint32 rad13 = 1068;
	public const uint32 rad14 = 1069;
	public const uint32 rad15 = 1070;
	public const uint32 rad16 = 1071;
	public const uint32 grp1 = 1072;
	public const uint32 grp2 = 1073;
	public const uint32 grp3 = 1074;
	public const uint32 grp4 = 1075;
	public const uint32 frm1 = 1076;
	public const uint32 frm2 = 1077;
	public const uint32 frm3 = 1078;
	public const uint32 frm4 = 1079;
	public const uint32 rct1 = 1080;
	public const uint32 rct2 = 1081;
	public const uint32 rct3 = 1082;
	public const uint32 rct4 = 1083;
	public const uint32 ico1 = 1084;
	public const uint32 ico2 = 1085;
	public const uint32 ico3 = 1086;
	public const uint32 ico4 = 1087;
	public const uint32 stc1 = 1088;
	public const uint32 stc2 = 1089;
	public const uint32 stc3 = 1090;
	public const uint32 stc4 = 1091;
	public const uint32 stc5 = 1092;
	public const uint32 stc6 = 1093;
	public const uint32 stc7 = 1094;
	public const uint32 stc8 = 1095;
	public const uint32 stc9 = 1096;
	public const uint32 stc10 = 1097;
	public const uint32 stc11 = 1098;
	public const uint32 stc12 = 1099;
	public const uint32 stc13 = 1100;
	public const uint32 stc14 = 1101;
	public const uint32 stc15 = 1102;
	public const uint32 stc16 = 1103;
	public const uint32 stc17 = 1104;
	public const uint32 stc18 = 1105;
	public const uint32 stc19 = 1106;
	public const uint32 stc20 = 1107;
	public const uint32 stc21 = 1108;
	public const uint32 stc22 = 1109;
	public const uint32 stc23 = 1110;
	public const uint32 stc24 = 1111;
	public const uint32 stc25 = 1112;
	public const uint32 stc26 = 1113;
	public const uint32 stc27 = 1114;
	public const uint32 stc28 = 1115;
	public const uint32 stc29 = 1116;
	public const uint32 stc30 = 1117;
	public const uint32 stc31 = 1118;
	public const uint32 stc32 = 1119;
	public const uint32 lst1 = 1120;
	public const uint32 lst2 = 1121;
	public const uint32 lst3 = 1122;
	public const uint32 lst4 = 1123;
	public const uint32 lst5 = 1124;
	public const uint32 lst6 = 1125;
	public const uint32 lst7 = 1126;
	public const uint32 lst8 = 1127;
	public const uint32 lst9 = 1128;
	public const uint32 lst10 = 1129;
	public const uint32 lst11 = 1130;
	public const uint32 lst12 = 1131;
	public const uint32 lst13 = 1132;
	public const uint32 lst14 = 1133;
	public const uint32 lst15 = 1134;
	public const uint32 lst16 = 1135;
	public const uint32 cmb1 = 1136;
	public const uint32 cmb2 = 1137;
	public const uint32 cmb3 = 1138;
	public const uint32 cmb4 = 1139;
	public const uint32 cmb5 = 1140;
	public const uint32 cmb6 = 1141;
	public const uint32 cmb7 = 1142;
	public const uint32 cmb8 = 1143;
	public const uint32 cmb9 = 1144;
	public const uint32 cmb10 = 1145;
	public const uint32 cmb11 = 1146;
	public const uint32 cmb12 = 1147;
	public const uint32 cmb13 = 1148;
	public const uint32 cmb14 = 1149;
	public const uint32 cmb15 = 1150;
	public const uint32 cmb16 = 1151;
	public const uint32 edt1 = 1152;
	public const uint32 edt2 = 1153;
	public const uint32 edt3 = 1154;
	public const uint32 edt4 = 1155;
	public const uint32 edt5 = 1156;
	public const uint32 edt6 = 1157;
	public const uint32 edt7 = 1158;
	public const uint32 edt8 = 1159;
	public const uint32 edt9 = 1160;
	public const uint32 edt10 = 1161;
	public const uint32 edt11 = 1162;
	public const uint32 edt12 = 1163;
	public const uint32 edt13 = 1164;
	public const uint32 edt14 = 1165;
	public const uint32 edt15 = 1166;
	public const uint32 edt16 = 1167;
	public const uint32 scr1 = 1168;
	public const uint32 scr2 = 1169;
	public const uint32 scr3 = 1170;
	public const uint32 scr4 = 1171;
	public const uint32 scr5 = 1172;
	public const uint32 scr6 = 1173;
	public const uint32 scr7 = 1174;
	public const uint32 scr8 = 1175;
	public const uint32 ctl1 = 1184;
	public const uint32 FILEOPENORD = 1536;
	public const uint32 MULTIFILEOPENORD = 1537;
	public const uint32 PRINTDLGORD = 1538;
	public const uint32 PRNSETUPDLGORD = 1539;
	public const uint32 FINDDLGORD = 1540;
	public const uint32 REPLACEDLGORD = 1541;
	public const uint32 FONTDLGORD = 1542;
	public const uint32 FORMATDLGORD31 = 1543;
	public const uint32 FORMATDLGORD30 = 1544;
	public const uint32 RUNDLGORD = 1545;
	public const uint32 PAGESETUPDLGORD = 1546;
	public const uint32 NEWFILEOPENORD = 1547;
	public const uint32 PRINTDLGEXORD = 1549;
	public const uint32 PAGESETUPDLGORDMOTIF = 1550;
	public const uint32 COLORMGMTDLGORD = 1551;
	public const uint32 NEWFILEOPENV2ORD = 1552;
	public const uint32 NEWFILEOPENV3ORD = 1553;
	public const uint32 NEWFORMATDLGWITHLINK = 1591;
	public const uint32 IDC_MANAGE_LINK = 1592;
	public const uint32 DA_LAST = 2147483647;
	public const int32 DA_ERR = -1;
	public const uint32 DSA_APPEND = 2147483647;
	public const int32 DSA_ERR = -1;
	public const uint32 DPAM_SORTED = 1;
	public const uint32 DPAM_NORMAL = 2;
	public const uint32 DPAM_UNION = 4;
	public const uint32 DPAM_INTERSECT = 8;
	public const uint32 DPAS_SORTED = 1;
	public const uint32 DPAS_INSERTBEFORE = 2;
	public const uint32 DPAS_INSERTAFTER = 4;
	public const uint32 DPA_APPEND = 2147483647;
	public const int32 DPA_ERR = -1;
	public const uint32 MAXPROPPAGES = 100;
	public const uint32 PSP_DEFAULT = 0;
	public const uint32 PSP_DLGINDIRECT = 1;
	public const uint32 PSP_USEHICON = 2;
	public const uint32 PSP_USEICONID = 4;
	public const uint32 PSP_USETITLE = 8;
	public const uint32 PSP_RTLREADING = 16;
	public const uint32 PSP_HASHELP = 32;
	public const uint32 PSP_USEREFPARENT = 64;
	public const uint32 PSP_USECALLBACK = 128;
	public const uint32 PSP_PREMATURE = 1024;
	public const uint32 PSP_HIDEHEADER = 2048;
	public const uint32 PSP_USEHEADERTITLE = 4096;
	public const uint32 PSP_USEHEADERSUBTITLE = 8192;
	public const uint32 PSP_USEFUSIONCONTEXT = 16384;
	public const uint32 PSH_DEFAULT = 0;
	public const uint32 PSH_PROPTITLE = 1;
	public const uint32 PSH_USEHICON = 2;
	public const uint32 PSH_USEICONID = 4;
	public const uint32 PSH_PROPSHEETPAGE = 8;
	public const uint32 PSH_WIZARDHASFINISH = 16;
	public const uint32 PSH_WIZARD = 32;
	public const uint32 PSH_USEPSTARTPAGE = 64;
	public const uint32 PSH_NOAPPLYNOW = 128;
	public const uint32 PSH_USECALLBACK = 256;
	public const uint32 PSH_HASHELP = 512;
	public const uint32 PSH_MODELESS = 1024;
	public const uint32 PSH_RTLREADING = 2048;
	public const uint32 PSH_WIZARDCONTEXTHELP = 4096;
	public const uint32 PSH_WIZARD97 = 8192;
	public const uint32 PSH_WATERMARK = 32768;
	public const uint32 PSH_USEHBMWATERMARK = 65536;
	public const uint32 PSH_USEHPLWATERMARK = 131072;
	public const uint32 PSH_STRETCHWATERMARK = 262144;
	public const uint32 PSH_HEADER = 524288;
	public const uint32 PSH_USEHBMHEADER = 1048576;
	public const uint32 PSH_USEPAGELANG = 2097152;
	public const uint32 PSH_WIZARD_LITE = 4194304;
	public const uint32 PSH_NOCONTEXTHELP = 33554432;
	public const uint32 PSH_AEROWIZARD = 16384;
	public const uint32 PSH_RESIZABLE = 67108864;
	public const uint32 PSH_HEADERBITMAP = 134217728;
	public const uint32 PSH_NOMARGIN = 268435456;
	public const uint32 PSCB_INITIALIZED = 1;
	public const uint32 PSCB_PRECREATE = 2;
	public const uint32 PSCB_BUTTONPRESSED = 3;
	public const uint32 PSNRET_NOERROR = 0;
	public const uint32 PSNRET_INVALID = 1;
	public const uint32 PSNRET_INVALID_NOCHANGEPAGE = 2;
	public const uint32 PSNRET_MESSAGEHANDLED = 3;
	public const uint32 PSM_SETCURSEL = 1125;
	public const uint32 PSM_REMOVEPAGE = 1126;
	public const uint32 PSM_ADDPAGE = 1127;
	public const uint32 PSM_CHANGED = 1128;
	public const uint32 PSM_RESTARTWINDOWS = 1129;
	public const uint32 PSM_REBOOTSYSTEM = 1130;
	public const uint32 PSM_CANCELTOCLOSE = 1131;
	public const uint32 PSM_QUERYSIBLINGS = 1132;
	public const uint32 PSM_UNCHANGED = 1133;
	public const uint32 PSM_APPLY = 1134;
	public const uint32 PSM_SETTITLEA = 1135;
	public const uint32 PSM_SETTITLEW = 1144;
	public const uint32 PSM_SETTITLE = 1144;
	public const uint32 PSM_SETWIZBUTTONS = 1136;
	public const uint32 PSWIZB_BACK = 1;
	public const uint32 PSWIZB_NEXT = 2;
	public const uint32 PSWIZB_FINISH = 4;
	public const uint32 PSWIZB_DISABLEDFINISH = 8;
	public const uint32 PSWIZBF_ELEVATIONREQUIRED = 1;
	public const uint32 PSWIZB_CANCEL = 16;
	public const uint32 PSM_PRESSBUTTON = 1137;
	public const uint32 PSBTN_BACK = 0;
	public const uint32 PSBTN_NEXT = 1;
	public const uint32 PSBTN_FINISH = 2;
	public const uint32 PSBTN_OK = 3;
	public const uint32 PSBTN_APPLYNOW = 4;
	public const uint32 PSBTN_CANCEL = 5;
	public const uint32 PSBTN_HELP = 6;
	public const uint32 PSBTN_MAX = 6;
	public const uint32 PSM_SETCURSELID = 1138;
	public const uint32 PSM_SETFINISHTEXTA = 1139;
	public const uint32 PSM_SETFINISHTEXTW = 1145;
	public const uint32 PSM_SETFINISHTEXT = 1145;
	public const uint32 PSM_GETTABCONTROL = 1140;
	public const uint32 PSM_ISDIALOGMESSAGE = 1141;
	public const uint32 PSM_GETCURRENTPAGEHWND = 1142;
	public const uint32 PSM_INSERTPAGE = 1143;
	public const uint32 PSM_SETHEADERTITLEA = 1149;
	public const uint32 PSM_SETHEADERTITLEW = 1150;
	public const uint32 PSM_SETHEADERTITLE = 1150;
	public const uint32 PSM_SETHEADERSUBTITLEA = 1151;
	public const uint32 PSM_SETHEADERSUBTITLEW = 1152;
	public const uint32 PSM_SETHEADERSUBTITLE = 1152;
	public const uint32 PSM_HWNDTOINDEX = 1153;
	public const uint32 PSM_INDEXTOHWND = 1154;
	public const uint32 PSM_PAGETOINDEX = 1155;
	public const uint32 PSM_INDEXTOPAGE = 1156;
	public const uint32 PSM_IDTOINDEX = 1157;
	public const uint32 PSM_INDEXTOID = 1158;
	public const uint32 PSM_GETRESULT = 1159;
	public const uint32 PSM_RECALCPAGESIZES = 1160;
	public const uint32 PSM_SETNEXTTEXTW = 1161;
	public const uint32 PSM_SETNEXTTEXT = 1161;
	public const uint32 PSWIZB_SHOW = 0;
	public const uint32 PSWIZB_RESTORE = 1;
	public const uint32 PSM_SHOWWIZBUTTONS = 1162;
	public const uint32 PSM_ENABLEWIZBUTTONS = 1163;
	public const uint32 PSM_SETBUTTONTEXTW = 1164;
	public const uint32 PSM_SETBUTTONTEXT = 1164;
	public const uint32 ID_PSRESTARTWINDOWS = 2;
	public const uint32 WIZ_CXDLG = 276;
	public const uint32 WIZ_CYDLG = 140;
	public const uint32 WIZ_CXBMP = 80;
	public const uint32 WIZ_BODYX = 92;
	public const uint32 WIZ_BODYCX = 184;
	public const uint32 PROP_SM_CXDLG = 212;
	public const uint32 PROP_SM_CYDLG = 188;
	public const uint32 PROP_MED_CXDLG = 227;
	public const uint32 PROP_MED_CYDLG = 215;
	public const uint32 PROP_LG_CXDLG = 252;
	public const uint32 PROP_LG_CYDLG = 218;
	public const uint32 MAX_THEMECOLOR = 64;
	public const uint32 MAX_THEMESIZE = 64;
	public const uint32 DTBG_CLIPRECT = 1;
	public const uint32 DTBG_DRAWSOLID = 2;
	public const uint32 DTBG_OMITBORDER = 4;
	public const uint32 DTBG_OMITCONTENT = 8;
	public const uint32 DTBG_COMPUTINGREGION = 16;
	public const uint32 DTBG_MIRRORDC = 32;
	public const uint32 DTBG_NOMIRROR = 64;
	public const uint32 DTT_GRAYED = 1;
	public const uint32 DTT_FLAGS2VALIDBITS = 1;
	public const uint32 MAX_INTLIST_COUNT = 402;
	public const uint32 ETDT_DISABLE = 1;
	public const uint32 ETDT_ENABLE = 2;
	public const uint32 ETDT_USETABTEXTURE = 4;
	public const uint32 ETDT_USEAEROWIZARDTABTEXTURE = 8;
	public const String SZ_THDOCPROP_DISPLAYNAME = "DisplayName";
	public const String SZ_THDOCPROP_CANONICALNAME = "ThemeName";
	public const String SZ_THDOCPROP_TOOLTIP = "ToolTip";
	public const String SZ_THDOCPROP_AUTHOR = "author";
	public const uint32 WTNCA_NODRAWCAPTION = 1;
	public const uint32 WTNCA_NODRAWICON = 2;
	public const uint32 WTNCA_NOSYSMENU = 4;
	public const uint32 WTNCA_NOMIRRORHELP = 8;
	public const uint32 TMTVS_RESERVEDLOW = 100000;
	public const uint32 TMTVS_RESERVEDHIGH = 19999;
	public const String VSCLASS_AEROWIZARDSTYLE = "AEROWIZARDSTYLE";
	public const String VSCLASS_AEROWIZARD = "AEROWIZARD";
	public const String VSCLASS_BUTTONSTYLE = "BUTTONSTYLE";
	public const String VSCLASS_BUTTON = "BUTTON";
	public const String VSCLASS_COMBOBOXSTYLE = "COMBOBOXSTYLE";
	public const String VSCLASS_COMBOBOX = "COMBOBOX";
	public const String VSCLASS_COMMUNICATIONSSTYLE = "COMMUNICATIONSSTYLE";
	public const String VSCLASS_COMMUNICATIONS = "COMMUNICATIONS";
	public const String VSCLASS_CONTROLPANELSTYLE = "CONTROLPANELSTYLE";
	public const String VSCLASS_CONTROLPANEL = "CONTROLPANEL";
	public const String VSCLASS_DATEPICKERSTYLE = "DATEPICKERSTYLE";
	public const String VSCLASS_DATEPICKER = "DATEPICKER";
	public const String VSCLASS_DRAGDROPSTYLE = "DRAGDROPSTYLE";
	public const String VSCLASS_DRAGDROP = "DRAGDROP";
	public const String VSCLASS_EDITSTYLE = "EDITSTYLE";
	public const String VSCLASS_EDIT = "EDIT";
	public const String VSCLASS_EXPLORERBARSTYLE = "EXPLORERBARSTYLE";
	public const String VSCLASS_EXPLORERBAR = "EXPLORERBAR";
	public const String VSCLASS_FLYOUTSTYLE = "FLYOUTSTYLE";
	public const String VSCLASS_FLYOUT = "FLYOUT";
	public const String VSCLASS_HEADERSTYLE = "HEADERSTYLE";
	public const String VSCLASS_HEADER = "HEADER";
	public const String VSCLASS_LISTBOXSTYLE = "LISTBOXSTYLE";
	public const String VSCLASS_LISTBOX = "LISTBOX";
	public const String VSCLASS_LISTVIEWSTYLE = "LISTVIEWSTYLE";
	public const String VSCLASS_LISTVIEW = "LISTVIEW";
	public const String VSCLASS_MENUSTYLE = "MENUSTYLE";
	public const String VSCLASS_MENU = "MENU";
	public const String VSCLASS_NAVIGATION = "NAVIGATION";
	public const String VSCLASS_PROGRESSSTYLE = "PROGRESSSTYLE";
	public const String VSCLASS_PROGRESS = "PROGRESS";
	public const String VSCLASS_REBARSTYLE = "REBARSTYLE";
	public const String VSCLASS_REBAR = "REBAR";
	public const String VSCLASS_SCROLLBARSTYLE = "SCROLLBARSTYLE";
	public const String VSCLASS_SCROLLBAR = "SCROLLBAR";
	public const String VSCLASS_SPINSTYLE = "SPINSTYLE";
	public const String VSCLASS_SPIN = "SPIN";
	public const String VSCLASS_STATUSSTYLE = "STATUSSTYLE";
	public const String VSCLASS_STATUS = "STATUS";
	public const String VSCLASS_TABSTYLE = "TABSTYLE";
	public const String VSCLASS_TAB = "TAB";
	public const String VSCLASS_TASKDIALOGSTYLE = "TASKDIALOGSTYLE";
	public const String VSCLASS_TASKDIALOG = "TASKDIALOG";
	public const String VSCLASS_TEXTSTYLE = "TEXTSTYLE";
	public const String VSCLASS_TOOLBARSTYLE = "TOOLBARSTYLE";
	public const String VSCLASS_TOOLBAR = "TOOLBAR";
	public const String VSCLASS_TOOLTIPSTYLE = "TOOLTIPSTYLE";
	public const String VSCLASS_TOOLTIP = "TOOLTIP";
	public const String VSCLASS_TRACKBARSTYLE = "TRACKBARSTYLE";
	public const String VSCLASS_TRACKBAR = "TRACKBAR";
	public const String VSCLASS_TREEVIEWSTYLE = "TREEVIEWSTYLE";
	public const String VSCLASS_TREEVIEW = "TREEVIEW";
	public const String VSCLASS_USERTILE = "USERTILE";
	public const String VSCLASS_TEXTSELECTIONGRIPPER = "TEXTSELECTIONGRIPPER";
	public const String VSCLASS_WINDOWSTYLE = "WINDOWSTYLE";
	public const String VSCLASS_WINDOW = "WINDOW";
	public const String VSCLASS_LINK = "LINK";
	public const String VSCLASS_EMPTYMARKUP = "EMPTYMARKUP";
	public const String VSCLASS_STATIC = "STATIC";
	public const String VSCLASS_PAGE = "PAGE";
	public const String VSCLASS_MONTHCAL = "MONTHCAL";
	public const String VSCLASS_CLOCK = "CLOCK";
	public const String VSCLASS_TRAYNOTIFY = "TRAYNOTIFY";
	public const String VSCLASS_TASKBAR = "TASKBAR";
	public const String VSCLASS_TASKBAND = "TASKBAND";
	public const String VSCLASS_STARTPANEL = "STARTPANEL";
	public const String VSCLASS_MENUBAND = "MENUBAND";
	public const uint32 EM_GETSEL = 176;
	public const uint32 EM_SETSEL = 177;
	public const uint32 EM_GETRECT = 178;
	public const uint32 EM_SETRECT = 179;
	public const uint32 EM_SETRECTNP = 180;
	public const uint32 EM_SCROLL = 181;
	public const uint32 EM_LINESCROLL = 182;
	public const uint32 EM_GETMODIFY = 184;
	public const uint32 EM_SETMODIFY = 185;
	public const uint32 EM_GETLINECOUNT = 186;
	public const uint32 EM_LINEINDEX = 187;
	public const uint32 EM_SETHANDLE = 188;
	public const uint32 EM_GETHANDLE = 189;
	public const uint32 EM_GETTHUMB = 190;
	public const uint32 EM_LINELENGTH = 193;
	public const uint32 EM_REPLACESEL = 194;
	public const uint32 EM_GETLINE = 196;
	public const uint32 EM_LIMITTEXT = 197;
	public const uint32 EM_CANUNDO = 198;
	public const uint32 EM_UNDO = 199;
	public const uint32 EM_FMTLINES = 200;
	public const uint32 EM_LINEFROMCHAR = 201;
	public const uint32 EM_SETTABSTOPS = 203;
	public const uint32 EM_SETPASSWORDCHAR = 204;
	public const uint32 EM_EMPTYUNDOBUFFER = 205;
	public const uint32 EM_GETFIRSTVISIBLELINE = 206;
	public const uint32 EM_SETREADONLY = 207;
	public const uint32 EM_SETWORDBREAKPROC = 208;
	public const uint32 EM_GETWORDBREAKPROC = 209;
	public const uint32 EM_GETPASSWORDCHAR = 210;
	public const uint32 EM_SETMARGINS = 211;
	public const uint32 EM_GETMARGINS = 212;
	public const uint32 EM_SETIMESTATUS = 216;
	public const uint32 EM_GETIMESTATUS = 217;
	public const uint32 EM_ENABLEFEATURE = 218;
}
#endregion

#region TypeDefs
typealias HPROPSHEETPAGE = int;

typealias HIMAGELIST = int;

typealias HSYNTHETICPOINTERDEVICE = int;

typealias HTREEITEM = int;

typealias HDSA = int;

typealias HDPA = int;

#endregion


#region Enums

[AllowDuplicates]
public enum THEME_PROPERTY_SYMBOL_ID : uint32
{
	TMT_RESERVEDLOW = 0,
	TMT_RESERVEDHIGH = 7999,
	TMT_DIBDATA = 2,
	TMT_GLYPHDIBDATA = 8,
	TMT_ENUM = 200,
	TMT_STRING = 201,
	TMT_INT = 202,
	TMT_BOOL = 203,
	TMT_COLOR = 204,
	TMT_MARGINS = 205,
	TMT_FILENAME = 206,
	TMT_SIZE = 207,
	TMT_POSITION = 208,
	TMT_RECT = 209,
	TMT_FONT = 210,
	TMT_INTLIST = 211,
	TMT_HBITMAP = 212,
	TMT_DISKSTREAM = 213,
	TMT_STREAM = 214,
	TMT_BITMAPREF = 215,
	TMT_FLOAT = 216,
	TMT_FLOATLIST = 217,
	TMT_COLORSCHEMES = 401,
	TMT_SIZES = 402,
	TMT_CHARSET = 403,
	TMT_NAME = 600,
	TMT_DISPLAYNAME = 601,
	TMT_TOOLTIP = 602,
	TMT_COMPANY = 603,
	TMT_AUTHOR = 604,
	TMT_COPYRIGHT = 605,
	TMT_URL = 606,
	TMT_VERSION = 607,
	TMT_DESCRIPTION = 608,
	TMT_FIRST_RCSTRING_NAME = 601,
	TMT_LAST_RCSTRING_NAME = 608,
	TMT_CAPTIONFONT = 801,
	TMT_SMALLCAPTIONFONT = 802,
	TMT_MENUFONT = 803,
	TMT_STATUSFONT = 804,
	TMT_MSGBOXFONT = 805,
	TMT_ICONTITLEFONT = 806,
	TMT_HEADING1FONT = 807,
	TMT_HEADING2FONT = 808,
	TMT_BODYFONT = 809,
	TMT_FIRSTFONT = 801,
	TMT_LASTFONT = 809,
	TMT_FLATMENUS = 1001,
	TMT_FIRSTBOOL = 1001,
	TMT_LASTBOOL = 1001,
	TMT_SIZINGBORDERWIDTH = 1201,
	TMT_SCROLLBARWIDTH = 1202,
	TMT_SCROLLBARHEIGHT = 1203,
	TMT_CAPTIONBARWIDTH = 1204,
	TMT_CAPTIONBARHEIGHT = 1205,
	TMT_SMCAPTIONBARWIDTH = 1206,
	TMT_SMCAPTIONBARHEIGHT = 1207,
	TMT_MENUBARWIDTH = 1208,
	TMT_MENUBARHEIGHT = 1209,
	TMT_PADDEDBORDERWIDTH = 1210,
	TMT_FIRSTSIZE = 1201,
	TMT_LASTSIZE = 1210,
	TMT_MINCOLORDEPTH = 1301,
	TMT_FIRSTINT = 1301,
	TMT_LASTINT = 1301,
	TMT_CSSNAME = 1401,
	TMT_XMLNAME = 1402,
	TMT_LASTUPDATED = 1403,
	TMT_ALIAS = 1404,
	TMT_FIRSTSTRING = 1401,
	TMT_LASTSTRING = 1404,
	TMT_SCROLLBAR = 1601,
	TMT_BACKGROUND = 1602,
	TMT_ACTIVECAPTION = 1603,
	TMT_INACTIVECAPTION = 1604,
	TMT_MENU = 1605,
	TMT_WINDOW = 1606,
	TMT_WINDOWFRAME = 1607,
	TMT_MENUTEXT = 1608,
	TMT_WINDOWTEXT = 1609,
	TMT_CAPTIONTEXT = 1610,
	TMT_ACTIVEBORDER = 1611,
	TMT_INACTIVEBORDER = 1612,
	TMT_APPWORKSPACE = 1613,
	TMT_HIGHLIGHT = 1614,
	TMT_HIGHLIGHTTEXT = 1615,
	TMT_BTNFACE = 1616,
	TMT_BTNSHADOW = 1617,
	TMT_GRAYTEXT = 1618,
	TMT_BTNTEXT = 1619,
	TMT_INACTIVECAPTIONTEXT = 1620,
	TMT_BTNHIGHLIGHT = 1621,
	TMT_DKSHADOW3D = 1622,
	TMT_LIGHT3D = 1623,
	TMT_INFOTEXT = 1624,
	TMT_INFOBK = 1625,
	TMT_BUTTONALTERNATEFACE = 1626,
	TMT_HOTTRACKING = 1627,
	TMT_GRADIENTACTIVECAPTION = 1628,
	TMT_GRADIENTINACTIVECAPTION = 1629,
	TMT_MENUHILIGHT = 1630,
	TMT_MENUBAR = 1631,
	TMT_FIRSTCOLOR = 1601,
	TMT_LASTCOLOR = 1631,
	TMT_FROMHUE1 = 1801,
	TMT_FROMHUE2 = 1802,
	TMT_FROMHUE3 = 1803,
	TMT_FROMHUE4 = 1804,
	TMT_FROMHUE5 = 1805,
	TMT_TOHUE1 = 1806,
	TMT_TOHUE2 = 1807,
	TMT_TOHUE3 = 1808,
	TMT_TOHUE4 = 1809,
	TMT_TOHUE5 = 1810,
	TMT_FROMCOLOR1 = 2001,
	TMT_FROMCOLOR2 = 2002,
	TMT_FROMCOLOR3 = 2003,
	TMT_FROMCOLOR4 = 2004,
	TMT_FROMCOLOR5 = 2005,
	TMT_TOCOLOR1 = 2006,
	TMT_TOCOLOR2 = 2007,
	TMT_TOCOLOR3 = 2008,
	TMT_TOCOLOR4 = 2009,
	TMT_TOCOLOR5 = 2010,
	TMT_TRANSPARENT = 2201,
	TMT_AUTOSIZE = 2202,
	TMT_BORDERONLY = 2203,
	TMT_COMPOSITED = 2204,
	TMT_BGFILL = 2205,
	TMT_GLYPHTRANSPARENT = 2206,
	TMT_GLYPHONLY = 2207,
	TMT_ALWAYSSHOWSIZINGBAR = 2208,
	TMT_MIRRORIMAGE = 2209,
	TMT_UNIFORMSIZING = 2210,
	TMT_INTEGRALSIZING = 2211,
	TMT_SOURCEGROW = 2212,
	TMT_SOURCESHRINK = 2213,
	TMT_DRAWBORDERS = 2214,
	TMT_NOETCHEDEFFECT = 2215,
	TMT_TEXTAPPLYOVERLAY = 2216,
	TMT_TEXTGLOW = 2217,
	TMT_TEXTITALIC = 2218,
	TMT_COMPOSITEDOPAQUE = 2219,
	TMT_LOCALIZEDMIRRORIMAGE = 2220,
	TMT_IMAGECOUNT = 2401,
	TMT_ALPHALEVEL = 2402,
	TMT_BORDERSIZE = 2403,
	TMT_ROUNDCORNERWIDTH = 2404,
	TMT_ROUNDCORNERHEIGHT = 2405,
	TMT_GRADIENTRATIO1 = 2406,
	TMT_GRADIENTRATIO2 = 2407,
	TMT_GRADIENTRATIO3 = 2408,
	TMT_GRADIENTRATIO4 = 2409,
	TMT_GRADIENTRATIO5 = 2410,
	TMT_PROGRESSCHUNKSIZE = 2411,
	TMT_PROGRESSSPACESIZE = 2412,
	TMT_SATURATION = 2413,
	TMT_TEXTBORDERSIZE = 2414,
	TMT_ALPHATHRESHOLD = 2415,
	TMT_WIDTH = 2416,
	TMT_HEIGHT = 2417,
	TMT_GLYPHINDEX = 2418,
	TMT_TRUESIZESTRETCHMARK = 2419,
	TMT_MINDPI1 = 2420,
	TMT_MINDPI2 = 2421,
	TMT_MINDPI3 = 2422,
	TMT_MINDPI4 = 2423,
	TMT_MINDPI5 = 2424,
	TMT_TEXTGLOWSIZE = 2425,
	TMT_FRAMESPERSECOND = 2426,
	TMT_PIXELSPERFRAME = 2427,
	TMT_ANIMATIONDELAY = 2428,
	TMT_GLOWINTENSITY = 2429,
	TMT_OPACITY = 2430,
	TMT_COLORIZATIONCOLOR = 2431,
	TMT_COLORIZATIONOPACITY = 2432,
	TMT_MINDPI6 = 2433,
	TMT_MINDPI7 = 2434,
	TMT_GLYPHFONT = 2601,
	TMT_IMAGEFILE = 3001,
	TMT_IMAGEFILE1 = 3002,
	TMT_IMAGEFILE2 = 3003,
	TMT_IMAGEFILE3 = 3004,
	TMT_IMAGEFILE4 = 3005,
	TMT_IMAGEFILE5 = 3006,
	TMT_GLYPHIMAGEFILE = 3008,
	TMT_IMAGEFILE6 = 3009,
	TMT_IMAGEFILE7 = 3010,
	TMT_TEXT = 3201,
	TMT_CLASSICVALUE = 3202,
	TMT_OFFSET = 3401,
	TMT_TEXTSHADOWOFFSET = 3402,
	TMT_MINSIZE = 3403,
	TMT_MINSIZE1 = 3404,
	TMT_MINSIZE2 = 3405,
	TMT_MINSIZE3 = 3406,
	TMT_MINSIZE4 = 3407,
	TMT_MINSIZE5 = 3408,
	TMT_NORMALSIZE = 3409,
	TMT_MINSIZE6 = 3410,
	TMT_MINSIZE7 = 3411,
	TMT_SIZINGMARGINS = 3601,
	TMT_CONTENTMARGINS = 3602,
	TMT_CAPTIONMARGINS = 3603,
	TMT_BORDERCOLOR = 3801,
	TMT_FILLCOLOR = 3802,
	TMT_TEXTCOLOR = 3803,
	TMT_EDGELIGHTCOLOR = 3804,
	TMT_EDGEHIGHLIGHTCOLOR = 3805,
	TMT_EDGESHADOWCOLOR = 3806,
	TMT_EDGEDKSHADOWCOLOR = 3807,
	TMT_EDGEFILLCOLOR = 3808,
	TMT_TRANSPARENTCOLOR = 3809,
	TMT_GRADIENTCOLOR1 = 3810,
	TMT_GRADIENTCOLOR2 = 3811,
	TMT_GRADIENTCOLOR3 = 3812,
	TMT_GRADIENTCOLOR4 = 3813,
	TMT_GRADIENTCOLOR5 = 3814,
	TMT_SHADOWCOLOR = 3815,
	TMT_GLOWCOLOR = 3816,
	TMT_TEXTBORDERCOLOR = 3817,
	TMT_TEXTSHADOWCOLOR = 3818,
	TMT_GLYPHTEXTCOLOR = 3819,
	TMT_GLYPHTRANSPARENTCOLOR = 3820,
	TMT_FILLCOLORHINT = 3821,
	TMT_BORDERCOLORHINT = 3822,
	TMT_ACCENTCOLORHINT = 3823,
	TMT_TEXTCOLORHINT = 3824,
	TMT_HEADING1TEXTCOLOR = 3825,
	TMT_HEADING2TEXTCOLOR = 3826,
	TMT_BODYTEXTCOLOR = 3827,
	TMT_BGTYPE = 4001,
	TMT_BORDERTYPE = 4002,
	TMT_FILLTYPE = 4003,
	TMT_SIZINGTYPE = 4004,
	TMT_HALIGN = 4005,
	TMT_CONTENTALIGNMENT = 4006,
	TMT_VALIGN = 4007,
	TMT_OFFSETTYPE = 4008,
	TMT_ICONEFFECT = 4009,
	TMT_TEXTSHADOWTYPE = 4010,
	TMT_IMAGELAYOUT = 4011,
	TMT_GLYPHTYPE = 4012,
	TMT_IMAGESELECTTYPE = 4013,
	TMT_GLYPHFONTSIZINGTYPE = 4014,
	TMT_TRUESIZESCALINGTYPE = 4015,
	TMT_USERPICTURE = 5001,
	TMT_DEFAULTPANESIZE = 5002,
	TMT_BLENDCOLOR = 5003,
	TMT_CUSTOMSPLITRECT = 5004,
	TMT_ANIMATIONBUTTONRECT = 5005,
	TMT_ANIMATIONDURATION = 5006,
	TMT_TRANSITIONDURATIONS = 6000,
	TMT_SCALEDBACKGROUND = 7001,
	TMT_ATLASIMAGE = 8000,
	TMT_ATLASINPUTIMAGE = 8001,
	TMT_ATLASRECT = 8002,
}


[AllowDuplicates]
public enum SET_THEME_APP_PROPERTIES_FLAGS : uint32
{
	ALLOW_NONCLIENT = 1,
	ALLOW_CONTROLS = 2,
	ALLOW_WEBCONTENT = 4,
	VALIDBITS = 7,
}


[AllowDuplicates]
public enum DRAGLISTINFO_NOTIFICATION_FLAGS : uint32
{
	DL_BEGINDRAG = 1157,
	DL_CANCELDRAG = 1160,
	DL_DRAGGING = 1158,
	DL_DROPPED = 1159,
}


[AllowDuplicates]
public enum WORD_BREAK_ACTION : uint32
{
	WB_CLASSIFY = 3,
	WB_ISDELIMITER = 2,
	WB_LEFT = 0,
	WB_LEFTBREAK = 6,
	WB_MOVEWORDLEFT = 4,
	WB_MOVEWORDRIGHT = 5,
	WB_RIGHT = 1,
	WB_RIGHTBREAK = 7,
}


[AllowDuplicates]
public enum DPAMM_MESSAGE : uint32
{
	DPAMM_MERGE = 1,
	DPAMM_DELETE = 2,
	DPAMM_INSERT = 3,
}


[AllowDuplicates]
public enum DLG_DIR_LIST_FILE_TYPE : uint32
{
	DDL_ARCHIVE = 32,
	DDL_DIRECTORY = 16,
	DDL_DRIVES = 16384,
	DDL_EXCLUSIVE = 32768,
	DDL_HIDDEN = 2,
	DDL_READONLY = 1,
	DDL_READWRITE = 0,
	DDL_SYSTEM = 4,
	DDL_POSTMSGS = 8192,
}


[AllowDuplicates]
public enum OPEN_THEME_DATA_FLAGS : uint32
{
	OTD_FORCE_RECT_SIZING = 1,
	OTD_NONCLIENT = 2,
}


[AllowDuplicates]
public enum GET_THEME_BITMAP_FLAGS : uint32
{
	GBF_DIRECT = 1,
	GBF_COPY = 2,
	GBF_VALIDBITS = 3,
}


[AllowDuplicates]
public enum ENABLE_SCROLL_BAR_ARROWS : uint32
{
	ESB_DISABLE_BOTH = 3,
	ESB_DISABLE_DOWN = 2,
	ESB_DISABLE_LEFT = 1,
	ESB_DISABLE_LTUP = 1,
	ESB_DISABLE_RIGHT = 2,
	ESB_DISABLE_RTDN = 2,
	ESB_DISABLE_UP = 1,
	ESB_ENABLE_BOTH = 0,
}


[AllowDuplicates]
public enum IMAGE_LIST_DRAW_STYLE : uint32
{
	ILD_BLEND = 4,
	ILD_BLEND50 = 4,
	ILD_FOCUS = 2,
	ILD_MASK = 16,
	ILD_NORMAL = 0,
	ILD_SELECTED = 4,
}


[AllowDuplicates]
public enum WSB_PROP : int32
{
	WSB_PROP_CXHSCROLL = 2,
	WSB_PROP_CXHTHUMB = 16,
	WSB_PROP_CXVSCROLL = 8,
	WSB_PROP_CYHSCROLL = 4,
	WSB_PROP_CYVSCROLL = 1,
	WSB_PROP_CYVTHUMB = 32,
	WSB_PROP_HBKGCOLOR = 128,
	WSB_PROP_HSTYLE = 512,
	WSB_PROP_PALETTE = 2048,
	WSB_PROP_VBKGCOLOR = 64,
	WSB_PROP_VSTYLE = 256,
	WSB_PROP_WINSTYLE = 1024,
}


[AllowDuplicates]
public enum PSPCB_MESSAGE : uint32
{
	PSPCB_ADDREF = 0,
	PSPCB_CREATE = 2,
	PSPCB_RELEASE = 1,
	PSPCB_SI_INITDIALOG = 1025,
}


[AllowDuplicates]
public enum HEADER_CONTROL_NOTIFICATION_BUTTON : uint32
{
	HEADER_CONTROL_NOTIFICATION_BUTTON_LEFT = 0,
	HEADER_CONTROL_NOTIFICATION_BUTTON_RIGHT = 1,
	HEADER_CONTROL_NOTIFICATION_BUTTON_MIDDLE = 2,
}


[AllowDuplicates]
public enum IMAGE_LIST_COPY_FLAGS : uint32
{
	ILCF_MOVE = 0,
	ILCF_SWAP = 1,
}


[AllowDuplicates]
public enum DLG_BUTTON_CHECK_STATE : uint32
{
	BST_CHECKED = 1,
	BST_INDETERMINATE = 2,
	BST_UNCHECKED = 0,
}


[AllowDuplicates]
public enum DRAW_THEME_PARENT_BACKGROUND_FLAGS : uint32
{
	DTPB_WINDOWDC = 1,
	DTPB_USECTLCOLORSTATIC = 2,
	DTPB_USEERASEBKGND = 4,
}


[AllowDuplicates]
public enum IMAGE_LIST_ITEM_FLAGS : uint32
{
	ILIF_ALPHA = 1,
	ILIF_LOWQUALITY = 2,
}


[AllowDuplicates]
public enum HDI_MASK : uint32
{
	HDI_WIDTH = 1,
	HDI_HEIGHT = 1,
	HDI_TEXT = 2,
	HDI_FORMAT = 4,
	HDI_LPARAM = 8,
	HDI_BITMAP = 16,
	HDI_IMAGE = 32,
	HDI_DI_SETITEM = 64,
	HDI_ORDER = 128,
	HDI_FILTER = 256,
	HDI_STATE = 512,
}


[AllowDuplicates]
public enum NMREBAR_MASK_FLAGS : uint32
{
	RBNM_ID = 1,
	RBNM_LPARAM = 4,
	RBNM_STYLE = 2,
}


[AllowDuplicates]
public enum EDITBALLOONTIP_ICON : uint32
{
	TTI_ERROR = 3,
	TTI_INFO = 1,
	TTI_NONE = 0,
	TTI_WARNING = 2,
	TTI_INFO_LARGE = 4,
	TTI_WARNING_LARGE = 5,
	TTI_ERROR_LARGE = 6,
}


[AllowDuplicates]
public enum LVCOLUMNW_FORMAT : uint32
{
	LVCFMT_LEFT = 0,
	LVCFMT_RIGHT = 1,
	LVCFMT_CENTER = 2,
	LVCFMT_JUSTIFYMASK = 3,
	LVCFMT_IMAGE = 2048,
	LVCFMT_BITMAP_ON_RIGHT = 4096,
	LVCFMT_COL_HAS_IMAGES = 32768,
	LVCFMT_FIXED_WIDTH = 256,
	LVCFMT_NO_DPI_SCALE = 262144,
	LVCFMT_FIXED_RATIO = 524288,
	LVCFMT_SPLITBUTTON = 16777216,
}


[AllowDuplicates]
public enum NMPGSCROLL_KEYS : uint16
{
	PGK_NONE = 0,
	PGK_SHIFT = 1,
	PGK_CONTROL = 2,
	PGK_MENU = 4,
}


[AllowDuplicates]
public enum COMBOBOX_EX_ITEM_FLAGS : uint32
{
	CBEIF_DI_SETITEM = 268435456,
	CBEIF_IMAGE = 2,
	CBEIF_INDENT = 16,
	CBEIF_LPARAM = 32,
	CBEIF_OVERLAY = 8,
	CBEIF_SELECTEDIMAGE = 4,
	CBEIF_TEXT = 1,
}


[AllowDuplicates]
public enum TVITEMEXW_CHILDREN : int32
{
	I_ZERO = 0,
	I_ONE_OR_MORE = 1,
	I_CHILDRENCALLBACK = -1,
	I_CHILDRENAUTO = -2,
}


[AllowDuplicates]
public enum TVITEM_MASK : uint32
{
	TVIF_CHILDREN = 64,
	TVIF_DI_SETITEM = 4096,
	TVIF_HANDLE = 16,
	TVIF_IMAGE = 2,
	TVIF_PARAM = 4,
	TVIF_SELECTEDIMAGE = 32,
	TVIF_STATE = 8,
	TVIF_TEXT = 1,
	TVIF_EXPANDEDIMAGE = 512,
	TVIF_INTEGRAL = 128,
	TVIF_STATEEX = 256,
}


[AllowDuplicates]
public enum TCITEMHEADERA_MASK : uint32
{
	TCIF_IMAGE = 2,
	TCIF_RTLREADING = 4,
	TCIF_TEXT = 1,
	TCIF_PARAM = 8,
	TCIF_STATE = 16,
}


[AllowDuplicates]
public enum TCHITTESTINFO_FLAGS : uint32
{
	TCHT_NOWHERE = 1,
	TCHT_ONITEM = 6,
	TCHT_ONITEMICON = 2,
	TCHT_ONITEMLABEL = 4,
}


[AllowDuplicates]
public enum COMBOBOXINFO_BUTTON_STATE : uint32
{
	STATE_SYSTEM_INVISIBLE = 32768,
	STATE_SYSTEM_PRESSED = 8,
	STATE_SYSTEM_FOCUSABLE = 1048576,
	STATE_SYSTEM_OFFSCREEN = 65536,
	STATE_SYSTEM_UNAVAILABLE = 1,
}


[AllowDuplicates]
public enum NMCUSTOMDRAW_DRAW_STAGE : uint32
{
	CDDS_POSTPAINT = 2,
	CDDS_PREERASE = 3,
	CDDS_PREPAINT = 1,
	CDDS_ITEMPOSTERASE = 65540,
	CDDS_ITEMPOSTPAINT = 65538,
	CDDS_ITEMPREERASE = 65539,
	CDDS_ITEMPREPAINT = 65537,
	CDDS_SUBITEM = 131072,
}


[AllowDuplicates]
public enum MCGRIDINFO_PART : uint32
{
	MCGIP_CALENDARCONTROL = 0,
	MCGIP_NEXT = 1,
	MCGIP_PREV = 2,
	MCGIP_FOOTER = 3,
	MCGIP_CALENDAR = 4,
	MCGIP_CALENDARHEADER = 5,
	MCGIP_CALENDARBODY = 6,
	MCGIP_CALENDARROW = 7,
	MCGIP_CALENDARCELL = 8,
}


[AllowDuplicates]
public enum LVITEMA_GROUP_ID : int32
{
	I_GROUPIDCALLBACK = -1,
	I_GROUPIDNONE = -2,
}


[AllowDuplicates]
public enum NMTBHOTITEM_FLAGS : uint32
{
	HICF_ACCELERATOR = 4,
	HICF_ARROWKEYS = 2,
	HICF_DUPACCEL = 8,
	HICF_ENTERING = 16,
	HICF_LEAVING = 32,
	HICF_LMOUSE = 128,
	HICF_MOUSE = 1,
	HICF_OTHER = 0,
	HICF_RESELECT = 64,
	HICF_TOGGLEDROPDOWN = 256,
}


[AllowDuplicates]
public enum TOOLTIP_FLAGS : uint32
{
	TTF_IDISHWND = 1,
	TTF_CENTERTIP = 2,
	TTF_RTLREADING = 4,
	TTF_SUBCLASS = 16,
	TTF_TRACK = 32,
	TTF_ABSOLUTE = 128,
	TTF_TRANSPARENT = 256,
	TTF_PARSELINKS = 4096,
	TTF_DI_SETITEM = 32768,
}


[AllowDuplicates]
public enum LVTILEVIEWINFO_FLAGS : uint32
{
	LVTVIF_AUTOSIZE = 0,
	LVTVIF_FIXEDWIDTH = 1,
	LVTVIF_FIXEDHEIGHT = 2,
	LVTVIF_FIXEDSIZE = 3,
}


[AllowDuplicates]
public enum LVTILEVIEWINFO_MASK : uint32
{
	LVTVIM_TILESIZE = 1,
	LVTVIM_COLUMNS = 2,
	LVTVIM_LABELMARGIN = 4,
}


[AllowDuplicates]
public enum NMPGSCROLL_DIR : uint32
{
	PGF_SCROLLDOWN = 2,
	PGF_SCROLLLEFT = 4,
	PGF_SCROLLRIGHT = 8,
	PGF_SCROLLUP = 1,
}


[AllowDuplicates]
public enum LVCOLUMNW_MASK : uint32
{
	LVCF_FMT = 1,
	LVCF_WIDTH = 2,
	LVCF_TEXT = 4,
	LVCF_SUBITEM = 8,
	LVCF_IMAGE = 16,
	LVCF_ORDER = 32,
	LVCF_MINWIDTH = 64,
	LVCF_DEFAULTWIDTH = 128,
	LVCF_IDEALWIDTH = 256,
}


[AllowDuplicates]
public enum LVFINDINFOW_FLAGS : uint32
{
	LVFI_PARAM = 1,
	LVFI_PARTIAL = 8,
	LVFI_STRING = 2,
	LVFI_SUBSTRING = 4,
	LVFI_WRAP = 32,
	LVFI_NEARESTXY = 64,
}


[AllowDuplicates]
public enum BUTTON_IMAGELIST_ALIGN : uint32
{
	BUTTON_IMAGELIST_ALIGN_LEFT = 0,
	BUTTON_IMAGELIST_ALIGN_RIGHT = 1,
	BUTTON_IMAGELIST_ALIGN_TOP = 2,
	BUTTON_IMAGELIST_ALIGN_BOTTOM = 3,
	BUTTON_IMAGELIST_ALIGN_CENTER = 4,
}


[AllowDuplicates]
public enum TBBUTTONINFOW_MASK : uint32
{
	TBIF_BYINDEX = 2147483648,
	TBIF_COMMAND = 32,
	TBIF_IMAGE = 1,
	TBIF_LPARAM = 16,
	TBIF_SIZE = 64,
	TBIF_STATE = 4,
	TBIF_STYLE = 8,
	TBIF_TEXT = 2,
}


[AllowDuplicates]
public enum TBINSERTMARK_FLAGS : uint32
{
	TBIMHT_NONE = 0,
	TBIMHT_AFTER = 1,
	TBIMHT_BACKGROUND = 2,
}


[AllowDuplicates]
public enum LVGROUP_MASK : uint32
{
	LVGF_NONE = 0,
	LVGF_HEADER = 1,
	LVGF_FOOTER = 2,
	LVGF_STATE = 4,
}


[AllowDuplicates]
public enum BP_PAINTPARAMS_FLAGS : uint32
{
	BPPF_ERASE = 1,
	BPPF_NOCLIP = 2,
	BPPF_NONCLIENT = 4,
}


[AllowDuplicates]
public enum TVHITTESTINFO_FLAGS : uint32
{
	TVHT_ABOVE = 256,
	TVHT_BELOW = 512,
	TVHT_NOWHERE = 1,
	TVHT_ONITEM = 70,
	TVHT_ONITEMBUTTON = 16,
	TVHT_ONITEMICON = 2,
	TVHT_ONITEMINDENT = 8,
	TVHT_ONITEMLABEL = 4,
	TVHT_ONITEMRIGHT = 32,
	TVHT_ONITEMSTATEICON = 64,
	TVHT_TOLEFT = 2048,
	TVHT_TORIGHT = 1024,
}


[AllowDuplicates]
public enum DRAWITEMSTRUCT_CTL_TYPE : uint32
{
	ODT_BUTTON = 4,
	ODT_COMBOBOX = 3,
	ODT_LISTBOX = 2,
	ODT_LISTVIEW = 102,
	ODT_MENU = 1,
	ODT_STATIC = 5,
	ODT_TAB = 101,
}


[AllowDuplicates]
public enum NMPGCALCSIZE_FLAGS : uint32
{
	PGF_CALCHEIGHT = 2,
	PGF_CALCWIDTH = 1,
}


[AllowDuplicates]
public enum MCGRIDINFO_FLAGS : uint32
{
	MCGIF_DATE = 1,
	MCGIF_RECT = 2,
	MCGIF_NAME = 4,
}


[AllowDuplicates]
public enum LVHITTESTINFO_FLAGS : uint32
{
	LVHT_ABOVE = 8,
	LVHT_BELOW = 16,
	LVHT_NOWHERE = 1,
	LVHT_ONITEMICON = 2,
	LVHT_ONITEMLABEL = 4,
	LVHT_ONITEMSTATEICON = 8,
	LVHT_TOLEFT = 64,
	LVHT_TORIGHT = 32,
	LVHT_EX_GROUP_HEADER = 268435456,
	LVHT_EX_GROUP_FOOTER = 536870912,
	LVHT_EX_GROUP_COLLAPSE = 1073741824,
	LVHT_EX_GROUP_BACKGROUND = 2147483648,
	LVHT_EX_GROUP_STATEICON = 16777216,
	LVHT_EX_GROUP_SUBSETLINK = 33554432,
	LVHT_EX_GROUP = 4076863488,
	LVHT_EX_ONCONTENTS = 67108864,
	LVHT_EX_FOOTER = 134217728,
}


[AllowDuplicates]
public enum INITCOMMONCONTROLSEX_ICC : uint32
{
	ICC_ANIMATE_CLASS = 128,
	ICC_BAR_CLASSES = 4,
	ICC_COOL_CLASSES = 1024,
	ICC_DATE_CLASSES = 256,
	ICC_HOTKEY_CLASS = 64,
	ICC_INTERNET_CLASSES = 2048,
	ICC_LINK_CLASS = 32768,
	ICC_LISTVIEW_CLASSES = 1,
	ICC_NATIVEFNTCTL_CLASS = 8192,
	ICC_PAGESCROLLER_CLASS = 4096,
	ICC_PROGRESS_CLASS = 32,
	ICC_STANDARD_CLASSES = 16384,
	ICC_TAB_CLASSES = 8,
	ICC_TREEVIEW_CLASSES = 2,
	ICC_UPDOWN_CLASS = 16,
	ICC_USEREX_CLASSES = 512,
	ICC_WIN95_CLASSES = 255,
}


[AllowDuplicates]
public enum NMLVCUSTOMDRAW_ITEM_TYPE : uint32
{
	LVCDI_ITEM = 0,
	LVCDI_GROUP = 1,
	LVCDI_ITEMSLIST = 2,
}


[AllowDuplicates]
public enum NMTBDISPINFOW_MASK : uint32
{
	TBNF_IMAGE = 1,
	TBNF_TEXT = 2,
	TBNF_DI_SETITEM = 268435456,
}


[AllowDuplicates]
public enum NMLVEMPTYMARKUP_FLAGS : uint32
{
	EMF_CENTERED = 1,
}


[AllowDuplicates]
public enum LVFOOTERITEM_MASK : uint32
{
	LVFIF_TEXT = 1,
	LVFIF_STATE = 2,
}


[AllowDuplicates]
public enum IMAGELIST_CREATION_FLAGS : uint32
{
	ILC_MASK = 1,
	ILC_COLOR = 0,
	ILC_COLORDDB = 254,
	ILC_COLOR4 = 4,
	ILC_COLOR8 = 8,
	ILC_COLOR16 = 16,
	ILC_COLOR24 = 24,
	ILC_COLOR32 = 32,
	ILC_PALETTE = 2048,
	ILC_MIRROR = 8192,
	ILC_PERITEMMIRROR = 32768,
	ILC_ORIGINALSIZE = 65536,
	ILC_HIGHQUALITYSCALE = 131072,
}


[AllowDuplicates]
public enum DTTOPTS_FLAGS : uint32
{
	DTT_TEXTCOLOR = 1,
	DTT_BORDERCOLOR = 2,
	DTT_SHADOWCOLOR = 4,
	DTT_SHADOWTYPE = 8,
	DTT_SHADOWOFFSET = 16,
	DTT_BORDERSIZE = 32,
	DTT_FONTPROP = 64,
	DTT_COLORPROP = 128,
	DTT_STATEID = 256,
	DTT_CALCRECT = 512,
	DTT_APPLYOVERLAY = 1024,
	DTT_GLOWSIZE = 2048,
	DTT_CALLBACK = 4096,
	DTT_COMPOSITED = 8192,
	DTT_VALIDBITS = 12287,
}


[AllowDuplicates]
public enum NMLVGETINFOTIP_FLAGS : uint32
{
	LVGIT_UNFOLDED = 1,
	LVGIT_ZERO = 0,
}


[AllowDuplicates]
public enum LIST_VIEW_ITEM_STATE_FLAGS : uint32
{
	LVIS_FOCUSED = 1,
	LVIS_SELECTED = 2,
	LVIS_CUT = 4,
	LVIS_DROPHILITED = 8,
	LVIS_GLOW = 16,
	LVIS_ACTIVATING = 32,
	LVIS_OVERLAYMASK = 3840,
	LVIS_STATEIMAGEMASK = 61440,
}


[AllowDuplicates]
public enum NM_TREEVIEW_ACTION : uint32
{
	TVE_COLLAPSE = 1,
	TVE_EXPAND = 2,
	TVE_TOGGLE = 3,
	TVE_EXPANDPARTIAL = 16384,
	TVE_COLLAPSERESET = 32768,
	TVC_UNKNOWN = 0,
	TVC_BYMOUSE = 1,
	TVC_BYKEYBOARD = 2,
}


[AllowDuplicates]
public enum MONTH_CALDENDAR_MESSAGES_VIEW : uint32
{
	MCMV_MONTH = 0,
	MCMV_YEAR = 1,
	MCMV_DECADE = 2,
	MCMV_CENTURY = 3,
	MCMV_MAX = 3,
}


[AllowDuplicates]
public enum TAB_CONTROL_ITEM_STATE : uint32
{
	TCIS_BUTTONPRESSED = 1,
	TCIS_HIGHLIGHTED = 2,
}


[AllowDuplicates]
public enum TREE_VIEW_ITEM_STATE_FLAGS : uint32
{
	TVIS_SELECTED = 2,
	TVIS_CUT = 4,
	TVIS_DROPHILITED = 8,
	TVIS_BOLD = 16,
	TVIS_EXPANDED = 32,
	TVIS_EXPANDEDONCE = 64,
	TVIS_EXPANDPARTIAL = 128,
	TVIS_OVERLAYMASK = 3840,
	TVIS_STATEIMAGEMASK = 61440,
	TVIS_USERMASK = 61440,
	TVIS_EX_FLAT = 1,
	TVIS_EX_DISABLED = 2,
	TVIS_EX_ALL = 2,
}


[AllowDuplicates]
public enum HEADER_CONTROL_FORMAT_FLAGS : int32
{
	HDF_LEFT = 0,
	HDF_RIGHT = 1,
	HDF_CENTER = 2,
	HDF_JUSTIFYMASK = 3,
	HDF_RTLREADING = 4,
	HDF_BITMAP = 8192,
	HDF_STRING = 16384,
	HDF_OWNERDRAW = 32768,
	HDF_IMAGE = 2048,
	HDF_BITMAP_ON_RIGHT = 4096,
	HDF_SORTUP = 1024,
	HDF_SORTDOWN = 512,
	HDF_CHECKBOX = 64,
	HDF_CHECKED = 128,
	HDF_FIXEDWIDTH = 256,
	HDF_SPLITBUTTON = 16777216,
}


[AllowDuplicates]
public enum HEADER_CONTROL_FORMAT_TYPE : uint32
{
	HDFT_ISSTRING = 0,
	HDFT_ISNUMBER = 1,
	HDFT_ISDATE = 2,
	HDFT_HASNOVALUE = 32768,
}


[AllowDuplicates]
public enum HEADER_CONTROL_FORMAT_STATE : uint32
{
	HDIS_FOCUSED = 1,
}


[AllowDuplicates]
public enum HEADER_HITTEST_INFO_FLAGS : uint32
{
	HHT_NOWHERE = 1,
	HHT_ONHEADER = 2,
	HHT_ONDIVIDER = 4,
	HHT_ONDIVOPEN = 8,
	HHT_ONFILTER = 16,
	HHT_ONFILTERBUTTON = 32,
	HHT_ABOVE = 256,
	HHT_BELOW = 512,
	HHT_TORIGHT = 1024,
	HHT_TOLEFT = 2048,
	HHT_ONITEMSTATEICON = 4096,
	HHT_ONDROPDOWN = 8192,
	HHT_ONOVERFLOW = 16384,
}


[AllowDuplicates]
public enum IMAGE_LIST_WRITE_STREAM_FLAGS : uint32
{
	ILP_NORMAL = 0,
	ILP_DOWNLEVEL = 1,
}


[AllowDuplicates]
public enum LIST_ITEM_FLAGS : uint32
{
	LIF_ITEMINDEX = 1,
	LIF_STATE = 2,
	LIF_ITEMID = 4,
	LIF_URL = 8,
}


[AllowDuplicates]
public enum LIST_ITEM_STATE_FLAGS : uint32
{
	LIS_FOCUSED = 1,
	LIS_ENABLED = 2,
	LIS_VISITED = 4,
	LIS_HOTTRACK = 8,
	LIS_DEFAULTCOLORS = 16,
}


[AllowDuplicates]
public enum LIST_VIEW_BACKGROUND_IMAGE_FLAGS : uint32
{
	LVBKIF_SOURCE_NONE = 0,
	LVBKIF_SOURCE_HBITMAP = 1,
	LVBKIF_SOURCE_URL = 2,
	LVBKIF_SOURCE_MASK = 3,
	LVBKIF_STYLE_NORMAL = 0,
	LVBKIF_STYLE_TILE = 16,
	LVBKIF_STYLE_MASK = 16,
	LVBKIF_FLAG_TILEOFFSET = 256,
	LVBKIF_TYPE_WATERMARK = 268435456,
	LVBKIF_FLAG_ALPHABLEND = 536870912,
}


[AllowDuplicates]
public enum LIST_VIEW_GROUP_STATE_FLAGS : uint32
{
	LVGS_NORMAL = 0,
	LVGS_COLLAPSED = 1,
	LVGS_HIDDEN = 2,
	LVGS_NOHEADER = 4,
	LVGS_COLLAPSIBLE = 8,
	LVGS_FOCUSED = 16,
	LVGS_SELECTED = 32,
	LVGS_SUBSETED = 64,
	LVGS_SUBSETLINKFOCUSED = 128,
}


[AllowDuplicates]
public enum LIST_VIEW_GROUP_ALIGN_FLAGS : uint32
{
	LVGA_HEADER_LEFT = 1,
	LVGA_HEADER_CENTER = 2,
	LVGA_HEADER_RIGHT = 4,
	LVGA_FOOTER_LEFT = 8,
	LVGA_FOOTER_CENTER = 16,
	LVGA_FOOTER_RIGHT = 32,
}


[AllowDuplicates]
public enum LIST_VIEW_INSERT_MARK_FLAGS : uint32
{
	LVIM_AFTER = 1,
}


[AllowDuplicates]
public enum LIST_VIEW_ITEM_COLUMN_FORMAT_FLAGS : int32
{
	LVCFMT_LINE_BREAK = 1048576,
	LVCFMT_FILL = 2097152,
	LVCFMT_WRAP = 4194304,
	LVCFMT_NO_TITLE = 8388608,
	LVCFMT_TILE_PLACEMENTMASK = 3145728,
}


[AllowDuplicates]
public enum MCHITTESTINFO_HIT_FLAGS : uint32
{
	MCHT_TITLE = 65536,
	MCHT_CALENDAR = 131072,
	MCHT_TODAYLINK = 196608,
	MCHT_CALENDARCONTROL = 1048576,
	MCHT_NEXT = 16777216,
	MCHT_PREV = 33554432,
	MCHT_NOWHERE = 0,
	MCHT_TITLEBK = 65536,
	MCHT_TITLEMONTH = 65537,
	MCHT_TITLEYEAR = 65538,
	MCHT_TITLEBTNNEXT = 16842755,
	MCHT_TITLEBTNPREV = 33619971,
	MCHT_CALENDARBK = 131072,
	MCHT_CALENDARDATE = 131073,
	MCHT_CALENDARDATENEXT = 16908289,
	MCHT_CALENDARDATEPREV = 33685505,
	MCHT_CALENDARDAY = 131074,
	MCHT_CALENDARWEEKNUM = 131075,
	MCHT_CALENDARDATEMIN = 131076,
	MCHT_CALENDARDATEMAX = 131077,
}


[AllowDuplicates]
public enum NMCUSTOMDRAW_DRAW_STATE_FLAGS : uint32
{
	CDIS_SELECTED = 1,
	CDIS_GRAYED = 2,
	CDIS_DISABLED = 4,
	CDIS_CHECKED = 8,
	CDIS_FOCUS = 16,
	CDIS_DEFAULT = 32,
	CDIS_HOT = 64,
	CDIS_MARKED = 128,
	CDIS_INDETERMINATE = 256,
	CDIS_SHOWKEYBOARDCUES = 512,
	CDIS_NEARHOT = 1024,
	CDIS_OTHERSIDEHOT = 2048,
	CDIS_DROPHILITED = 4096,
}


[AllowDuplicates]
public enum NMDATETIMECHANGE_FLAGS : uint32
{
	GDT_NONE = 1,
	GDT_VALID = 0,
}


[AllowDuplicates]
public enum LIST_VIEW_ITEM_FLAGS : uint32
{
	LVIF_TEXT = 1,
	LVIF_IMAGE = 2,
	LVIF_PARAM = 4,
	LVIF_STATE = 8,
	LVIF_INDENT = 16,
	LVIF_NORECOMPUTE = 2048,
	LVIF_GROUPID = 256,
	LVIF_COLUMNS = 512,
	LVIF_COLFMT = 65536,
	LVIF_DI_SETITEM = 4096,
}


[AllowDuplicates]
public enum ODA_FLAGS : uint32
{
	ODA_DRAWENTIRE = 1,
	ODA_SELECT = 2,
	ODA_FOCUS = 4,
}


[AllowDuplicates]
public enum ODS_FLAGS : uint32
{
	ODS_SELECTED = 1,
	ODS_GRAYED = 2,
	ODS_DISABLED = 4,
	ODS_CHECKED = 8,
	ODS_FOCUS = 16,
	ODS_DEFAULT = 32,
	ODS_COMBOBOXEDIT = 4096,
	ODS_HOTLIGHT = 64,
	ODS_INACTIVE = 128,
	ODS_NOACCEL = 256,
	ODS_NOFOCUSRECT = 512,
}


[AllowDuplicates]
public enum HIT_TEST_BACKGROUND_OPTIONS : uint32
{
	HTTB_BACKGROUNDSEG = 0,
	HTTB_FIXEDBORDER = 2,
	HTTB_CAPTION = 4,
	HTTB_RESIZINGBORDER_LEFT = 16,
	HTTB_RESIZINGBORDER_TOP = 32,
	HTTB_RESIZINGBORDER_RIGHT = 64,
	HTTB_RESIZINGBORDER_BOTTOM = 128,
	HTTB_RESIZINGBORDER = 240,
	HTTB_SIZINGTEMPLATE = 256,
	HTTB_SYSTEMSIZINGMARGINS = 512,
}


[AllowDuplicates]
public enum TVITEMPART : int32
{
	TVGIPR_BUTTON = 1,
}


[AllowDuplicates]
public enum EC_ENDOFLINE : int32
{
	EC_ENDOFLINE_DETECTFROMCONTENT = 0,
	EC_ENDOFLINE_CRLF = 1,
	EC_ENDOFLINE_CR = 2,
	EC_ENDOFLINE_LF = 3,
}


[AllowDuplicates]
public enum EC_SEARCHWEB_ENTRYPOINT : int32
{
	EC_SEARCHWEB_ENTRYPOINT_EXTERNAL = 0,
	EC_SEARCHWEB_ENTRYPOINT_CONTEXTMENU = 1,
}


[AllowDuplicates]
public enum TASKDIALOG_FLAGS : int32
{
	TDF_ENABLE_HYPERLINKS = 1,
	TDF_USE_HICON_MAIN = 2,
	TDF_USE_HICON_FOOTER = 4,
	TDF_ALLOW_DIALOG_CANCELLATION = 8,
	TDF_USE_COMMAND_LINKS = 16,
	TDF_USE_COMMAND_LINKS_NO_ICON = 32,
	TDF_EXPAND_FOOTER_AREA = 64,
	TDF_EXPANDED_BY_DEFAULT = 128,
	TDF_VERIFICATION_FLAG_CHECKED = 256,
	TDF_SHOW_PROGRESS_BAR = 512,
	TDF_SHOW_MARQUEE_PROGRESS_BAR = 1024,
	TDF_CALLBACK_TIMER = 2048,
	TDF_POSITION_RELATIVE_TO_WINDOW = 4096,
	TDF_RTL_LAYOUT = 8192,
	TDF_NO_DEFAULT_RADIO_BUTTON = 16384,
	TDF_CAN_BE_MINIMIZED = 32768,
	TDF_NO_SET_FOREGROUND = 65536,
	TDF_SIZE_TO_CONTENT = 16777216,
}


[AllowDuplicates]
public enum TASKDIALOG_MESSAGES : int32
{
	TDM_NAVIGATE_PAGE = 1125,
	TDM_CLICK_BUTTON = 1126,
	TDM_SET_MARQUEE_PROGRESS_BAR = 1127,
	TDM_SET_PROGRESS_BAR_STATE = 1128,
	TDM_SET_PROGRESS_BAR_RANGE = 1129,
	TDM_SET_PROGRESS_BAR_POS = 1130,
	TDM_SET_PROGRESS_BAR_MARQUEE = 1131,
	TDM_SET_ELEMENT_TEXT = 1132,
	TDM_CLICK_RADIO_BUTTON = 1134,
	TDM_ENABLE_BUTTON = 1135,
	TDM_ENABLE_RADIO_BUTTON = 1136,
	TDM_CLICK_VERIFICATION = 1137,
	TDM_UPDATE_ELEMENT_TEXT = 1138,
	TDM_SET_BUTTON_ELEVATION_REQUIRED_STATE = 1139,
	TDM_UPDATE_ICON = 1140,
}


[AllowDuplicates]
public enum TASKDIALOG_NOTIFICATIONS : int32
{
	TDN_CREATED = 0,
	TDN_NAVIGATED = 1,
	TDN_BUTTON_CLICKED = 2,
	TDN_HYPERLINK_CLICKED = 3,
	TDN_TIMER = 4,
	TDN_DESTROYED = 5,
	TDN_RADIO_BUTTON_CLICKED = 6,
	TDN_DIALOG_CONSTRUCTED = 7,
	TDN_VERIFICATION_CLICKED = 8,
	TDN_HELP = 9,
	TDN_EXPANDO_BUTTON_CLICKED = 10,
}


[AllowDuplicates]
public enum TASKDIALOG_ELEMENTS : int32
{
	TDE_CONTENT = 0,
	TDE_EXPANDED_INFORMATION = 1,
	TDE_FOOTER = 2,
	TDE_MAIN_INSTRUCTION = 3,
}


[AllowDuplicates]
public enum TASKDIALOG_ICON_ELEMENTS : int32
{
	TDIE_ICON_MAIN = 0,
	TDIE_ICON_FOOTER = 1,
}


[AllowDuplicates]
public enum TASKDIALOG_COMMON_BUTTON_FLAGS : int32
{
	TDCBF_OK_BUTTON = 1,
	TDCBF_YES_BUTTON = 2,
	TDCBF_NO_BUTTON = 4,
	TDCBF_CANCEL_BUTTON = 8,
	TDCBF_RETRY_BUTTON = 16,
	TDCBF_CLOSE_BUTTON = 32,
}


[AllowDuplicates]
public enum _LI_METRIC : int32
{
	LIM_SMALL = 0,
	LIM_LARGE = 1,
}


[AllowDuplicates]
public enum TA_PROPERTY : int32
{
	TAP_FLAGS = 0,
	TAP_TRANSFORMCOUNT = 1,
	TAP_STAGGERDELAY = 2,
	TAP_STAGGERDELAYCAP = 3,
	TAP_STAGGERDELAYFACTOR = 4,
	TAP_ZORDER = 5,
}


[AllowDuplicates]
public enum TA_PROPERTY_FLAG : uint32
{
	TAPF_NONE = 0,
	TAPF_HASSTAGGER = 1,
	TAPF_ISRTLAWARE = 2,
	TAPF_ALLOWCOLLECTION = 4,
	TAPF_HASBACKGROUND = 8,
	TAPF_HASPERSPECTIVE = 16,
}


[AllowDuplicates]
public enum TA_TRANSFORM_TYPE : int32
{
	TATT_TRANSLATE_2D = 0,
	TATT_SCALE_2D = 1,
	TATT_OPACITY = 2,
	TATT_CLIP = 3,
}


[AllowDuplicates]
public enum TA_TRANSFORM_FLAG : int32
{
	TATF_NONE = 0,
	TATF_TARGETVALUES_USER = 1,
	TATF_HASINITIALVALUES = 2,
	TATF_HASORIGINVALUES = 4,
}


[AllowDuplicates]
public enum TA_TIMINGFUNCTION_TYPE : int32
{
	TTFT_UNDEFINED = 0,
	TTFT_CUBIC_BEZIER = 1,
}


[AllowDuplicates]
public enum THEMESIZE : int32
{
	TS_MIN = 0,
	TS_TRUE = 1,
	TS_DRAW = 2,
}


[AllowDuplicates]
public enum PROPERTYORIGIN : int32
{
	PO_STATE = 0,
	PO_PART = 1,
	PO_CLASS = 2,
	PO_GLOBAL = 3,
	PO_NOTFOUND = 4,
}


[AllowDuplicates]
public enum WINDOWTHEMEATTRIBUTETYPE : int32
{
	WTA_NONCLIENT = 1,
}


[AllowDuplicates]
public enum BP_BUFFERFORMAT : int32
{
	BPBF_COMPATIBLEBITMAP = 0,
	BPBF_DIB = 1,
	BPBF_TOPDOWNDIB = 2,
	BPBF_TOPDOWNMONODIB = 3,
}


[AllowDuplicates]
public enum BP_ANIMATIONSTYLE : int32
{
	BPAS_NONE = 0,
	BPAS_LINEAR = 1,
	BPAS_CUBIC = 2,
	BPAS_SINE = 3,
}


[AllowDuplicates]
public enum AEROWIZARDPARTS : int32
{
	AW_TITLEBAR = 1,
	AW_HEADERAREA = 2,
	AW_CONTENTAREA = 3,
	AW_COMMANDAREA = 4,
	AW_BUTTON = 5,
}


[AllowDuplicates]
public enum TITLEBARSTATES : int32
{
	AW_S_TITLEBAR_ACTIVE = 1,
	AW_S_TITLEBAR_INACTIVE = 2,
}


[AllowDuplicates]
public enum HEADERAREASTATES : int32
{
	AW_S_HEADERAREA_NOMARGIN = 1,
}


[AllowDuplicates]
public enum CONTENTAREASTATES : int32
{
	AW_S_CONTENTAREA_NOMARGIN = 1,
}


[AllowDuplicates]
public enum BUTTONPARTS : int32
{
	BP_PUSHBUTTON = 1,
	BP_RADIOBUTTON = 2,
	BP_CHECKBOX = 3,
	BP_GROUPBOX = 4,
	BP_USERBUTTON = 5,
	BP_COMMANDLINK = 6,
	BP_COMMANDLINKGLYPH = 7,
	BP_RADIOBUTTON_HCDISABLED = 8,
	BP_CHECKBOX_HCDISABLED = 9,
	BP_GROUPBOX_HCDISABLED = 10,
	BP_PUSHBUTTONDROPDOWN = 11,
}


[AllowDuplicates]
public enum PUSHBUTTONSTATES : int32
{
	PBS_NORMAL = 1,
	PBS_HOT = 2,
	PBS_PRESSED = 3,
	PBS_DISABLED = 4,
	PBS_DEFAULTED = 5,
	PBS_DEFAULTED_ANIMATING = 6,
}


[AllowDuplicates]
public enum RADIOBUTTONSTATES : int32
{
	RBS_UNCHECKEDNORMAL = 1,
	RBS_UNCHECKEDHOT = 2,
	RBS_UNCHECKEDPRESSED = 3,
	RBS_UNCHECKEDDISABLED = 4,
	RBS_CHECKEDNORMAL = 5,
	RBS_CHECKEDHOT = 6,
	RBS_CHECKEDPRESSED = 7,
	RBS_CHECKEDDISABLED = 8,
}


[AllowDuplicates]
public enum CHECKBOXSTATES : int32
{
	CBS_UNCHECKEDNORMAL = 1,
	CBS_UNCHECKEDHOT = 2,
	CBS_UNCHECKEDPRESSED = 3,
	CBS_UNCHECKEDDISABLED = 4,
	CBS_CHECKEDNORMAL = 5,
	CBS_CHECKEDHOT = 6,
	CBS_CHECKEDPRESSED = 7,
	CBS_CHECKEDDISABLED = 8,
	CBS_MIXEDNORMAL = 9,
	CBS_MIXEDHOT = 10,
	CBS_MIXEDPRESSED = 11,
	CBS_MIXEDDISABLED = 12,
	CBS_IMPLICITNORMAL = 13,
	CBS_IMPLICITHOT = 14,
	CBS_IMPLICITPRESSED = 15,
	CBS_IMPLICITDISABLED = 16,
	CBS_EXCLUDEDNORMAL = 17,
	CBS_EXCLUDEDHOT = 18,
	CBS_EXCLUDEDPRESSED = 19,
	CBS_EXCLUDEDDISABLED = 20,
}


[AllowDuplicates]
public enum GROUPBOXSTATES : int32
{
	GBS_NORMAL = 1,
	GBS_DISABLED = 2,
}


[AllowDuplicates]
public enum COMMANDLINKSTATES : int32
{
	CMDLS_NORMAL = 1,
	CMDLS_HOT = 2,
	CMDLS_PRESSED = 3,
	CMDLS_DISABLED = 4,
	CMDLS_DEFAULTED = 5,
	CMDLS_DEFAULTED_ANIMATING = 6,
}


[AllowDuplicates]
public enum COMMANDLINKGLYPHSTATES : int32
{
	CMDLGS_NORMAL = 1,
	CMDLGS_HOT = 2,
	CMDLGS_PRESSED = 3,
	CMDLGS_DISABLED = 4,
	CMDLGS_DEFAULTED = 5,
}


[AllowDuplicates]
public enum PUSHBUTTONDROPDOWNSTATES : int32
{
	PBDDS_NORMAL = 1,
	PBDDS_DISABLED = 2,
}


[AllowDuplicates]
public enum COMBOBOXPARTS : int32
{
	CP_DROPDOWNBUTTON = 1,
	CP_BACKGROUND = 2,
	CP_TRANSPARENTBACKGROUND = 3,
	CP_BORDER = 4,
	CP_READONLY = 5,
	CP_DROPDOWNBUTTONRIGHT = 6,
	CP_DROPDOWNBUTTONLEFT = 7,
	CP_CUEBANNER = 8,
	CP_DROPDOWNITEM = 9,
}


[AllowDuplicates]
public enum COMBOBOXSTYLESTATES : int32
{
	CBXS_NORMAL = 1,
	CBXS_HOT = 2,
	CBXS_PRESSED = 3,
	CBXS_DISABLED = 4,
}


[AllowDuplicates]
public enum DROPDOWNBUTTONRIGHTSTATES : int32
{
	CBXSR_NORMAL = 1,
	CBXSR_HOT = 2,
	CBXSR_PRESSED = 3,
	CBXSR_DISABLED = 4,
}


[AllowDuplicates]
public enum DROPDOWNBUTTONLEFTSTATES : int32
{
	CBXSL_NORMAL = 1,
	CBXSL_HOT = 2,
	CBXSL_PRESSED = 3,
	CBXSL_DISABLED = 4,
}


[AllowDuplicates]
public enum TRANSPARENTBACKGROUNDSTATES : int32
{
	CBTBS_NORMAL = 1,
	CBTBS_HOT = 2,
	CBTBS_DISABLED = 3,
	CBTBS_FOCUSED = 4,
}


[AllowDuplicates]
public enum BORDERSTATES : int32
{
	CBB_NORMAL = 1,
	CBB_HOT = 2,
	CBB_FOCUSED = 3,
	CBB_DISABLED = 4,
}


[AllowDuplicates]
public enum READONLYSTATES : int32
{
	CBRO_NORMAL = 1,
	CBRO_HOT = 2,
	CBRO_PRESSED = 3,
	CBRO_DISABLED = 4,
}


[AllowDuplicates]
public enum CUEBANNERSTATES : int32
{
	CBCB_NORMAL = 1,
	CBCB_HOT = 2,
	CBCB_PRESSED = 3,
	CBCB_DISABLED = 4,
}


[AllowDuplicates]
public enum DROPDOWNITEMSTATES : int32
{
	CBDI_NORMAL = 1,
	CBDI_HIGHLIGHTED = 2,
}


[AllowDuplicates]
public enum COMMUNICATIONSPARTS : int32
{
	CSST_TAB = 1,
}


[AllowDuplicates]
public enum TABSTATES : int32
{
	CSTB_NORMAL = 1,
	CSTB_HOT = 2,
	CSTB_SELECTED = 3,
}


[AllowDuplicates]
public enum CONTROLPANELPARTS : int32
{
	CPANEL_NAVIGATIONPANE = 1,
	CPANEL_CONTENTPANE = 2,
	CPANEL_NAVIGATIONPANELABEL = 3,
	CPANEL_CONTENTPANELABEL = 4,
	CPANEL_TITLE = 5,
	CPANEL_BODYTEXT = 6,
	CPANEL_HELPLINK = 7,
	CPANEL_TASKLINK = 8,
	CPANEL_GROUPTEXT = 9,
	CPANEL_CONTENTLINK = 10,
	CPANEL_SECTIONTITLELINK = 11,
	CPANEL_LARGECOMMANDAREA = 12,
	CPANEL_SMALLCOMMANDAREA = 13,
	CPANEL_BUTTON = 14,
	CPANEL_MESSAGETEXT = 15,
	CPANEL_NAVIGATIONPANELINE = 16,
	CPANEL_CONTENTPANELINE = 17,
	CPANEL_BANNERAREA = 18,
	CPANEL_BODYTITLE = 19,
}


[AllowDuplicates]
public enum HELPLINKSTATES : int32
{
	CPHL_NORMAL = 1,
	CPHL_HOT = 2,
	CPHL_PRESSED = 3,
	CPHL_DISABLED = 4,
}


[AllowDuplicates]
public enum TASKLINKSTATES : int32
{
	CPTL_NORMAL = 1,
	CPTL_HOT = 2,
	CPTL_PRESSED = 3,
	CPTL_DISABLED = 4,
	CPTL_PAGE = 5,
}


[AllowDuplicates]
public enum CONTENTLINKSTATES : int32
{
	CPCL_NORMAL = 1,
	CPCL_HOT = 2,
	CPCL_PRESSED = 3,
	CPCL_DISABLED = 4,
}


[AllowDuplicates]
public enum SECTIONTITLELINKSTATES : int32
{
	CPSTL_NORMAL = 1,
	CPSTL_HOT = 2,
}


[AllowDuplicates]
public enum DATEPICKERPARTS : int32
{
	DP_DATETEXT = 1,
	DP_DATEBORDER = 2,
	DP_SHOWCALENDARBUTTONRIGHT = 3,
}


[AllowDuplicates]
public enum DATETEXTSTATES : int32
{
	DPDT_NORMAL = 1,
	DPDT_DISABLED = 2,
	DPDT_SELECTED = 3,
}


[AllowDuplicates]
public enum DATEBORDERSTATES : int32
{
	DPDB_NORMAL = 1,
	DPDB_HOT = 2,
	DPDB_FOCUSED = 3,
	DPDB_DISABLED = 4,
}


[AllowDuplicates]
public enum SHOWCALENDARBUTTONRIGHTSTATES : int32
{
	DPSCBR_NORMAL = 1,
	DPSCBR_HOT = 2,
	DPSCBR_PRESSED = 3,
	DPSCBR_DISABLED = 4,
}


[AllowDuplicates]
public enum DRAGDROPPARTS : int32
{
	DD_COPY = 1,
	DD_MOVE = 2,
	DD_UPDATEMETADATA = 3,
	DD_CREATELINK = 4,
	DD_WARNING = 5,
	DD_NONE = 6,
	DD_IMAGEBG = 7,
	DD_TEXTBG = 8,
}


[AllowDuplicates]
public enum COPYSTATES : int32
{
	DDCOPY_HIGHLIGHT = 1,
	DDCOPY_NOHIGHLIGHT = 2,
}


[AllowDuplicates]
public enum MOVESTATES : int32
{
	DDMOVE_HIGHLIGHT = 1,
	DDMOVE_NOHIGHLIGHT = 2,
}


[AllowDuplicates]
public enum UPDATEMETADATASTATES : int32
{
	DDUPDATEMETADATA_HIGHLIGHT = 1,
	DDUPDATEMETADATA_NOHIGHLIGHT = 2,
}


[AllowDuplicates]
public enum CREATELINKSTATES : int32
{
	DDCREATELINK_HIGHLIGHT = 1,
	DDCREATELINK_NOHIGHLIGHT = 2,
}


[AllowDuplicates]
public enum WARNINGSTATES : int32
{
	DDWARNING_HIGHLIGHT = 1,
	DDWARNING_NOHIGHLIGHT = 2,
}


[AllowDuplicates]
public enum NONESTATES : int32
{
	DDNONE_HIGHLIGHT = 1,
	DDNONE_NOHIGHLIGHT = 2,
}


[AllowDuplicates]
public enum EDITPARTS : int32
{
	EP_EDITTEXT = 1,
	EP_CARET = 2,
	EP_BACKGROUND = 3,
	EP_PASSWORD = 4,
	EP_BACKGROUNDWITHBORDER = 5,
	EP_EDITBORDER_NOSCROLL = 6,
	EP_EDITBORDER_HSCROLL = 7,
	EP_EDITBORDER_VSCROLL = 8,
	EP_EDITBORDER_HVSCROLL = 9,
}


[AllowDuplicates]
public enum EDITTEXTSTATES : int32
{
	ETS_NORMAL = 1,
	ETS_HOT = 2,
	ETS_SELECTED = 3,
	ETS_DISABLED = 4,
	ETS_FOCUSED = 5,
	ETS_READONLY = 6,
	ETS_ASSIST = 7,
	ETS_CUEBANNER = 8,
}


[AllowDuplicates]
public enum BACKGROUNDSTATES : int32
{
	EBS_NORMAL = 1,
	EBS_HOT = 2,
	EBS_DISABLED = 3,
	EBS_FOCUSED = 4,
	EBS_READONLY = 5,
	EBS_ASSIST = 6,
}


[AllowDuplicates]
public enum BACKGROUNDWITHBORDERSTATES : int32
{
	EBWBS_NORMAL = 1,
	EBWBS_HOT = 2,
	EBWBS_DISABLED = 3,
	EBWBS_FOCUSED = 4,
}


[AllowDuplicates]
public enum EDITBORDER_NOSCROLLSTATES : int32
{
	EPSN_NORMAL = 1,
	EPSN_HOT = 2,
	EPSN_FOCUSED = 3,
	EPSN_DISABLED = 4,
}


[AllowDuplicates]
public enum EDITBORDER_HSCROLLSTATES : int32
{
	EPSH_NORMAL = 1,
	EPSH_HOT = 2,
	EPSH_FOCUSED = 3,
	EPSH_DISABLED = 4,
}


[AllowDuplicates]
public enum EDITBORDER_VSCROLLSTATES : int32
{
	EPSV_NORMAL = 1,
	EPSV_HOT = 2,
	EPSV_FOCUSED = 3,
	EPSV_DISABLED = 4,
}


[AllowDuplicates]
public enum EDITBORDER_HVSCROLLSTATES : int32
{
	EPSHV_NORMAL = 1,
	EPSHV_HOT = 2,
	EPSHV_FOCUSED = 3,
	EPSHV_DISABLED = 4,
}


[AllowDuplicates]
public enum EXPLORERBARPARTS : int32
{
	EBP_HEADERBACKGROUND = 1,
	EBP_HEADERCLOSE = 2,
	EBP_HEADERPIN = 3,
	EBP_IEBARMENU = 4,
	EBP_NORMALGROUPBACKGROUND = 5,
	EBP_NORMALGROUPCOLLAPSE = 6,
	EBP_NORMALGROUPEXPAND = 7,
	EBP_NORMALGROUPHEAD = 8,
	EBP_SPECIALGROUPBACKGROUND = 9,
	EBP_SPECIALGROUPCOLLAPSE = 10,
	EBP_SPECIALGROUPEXPAND = 11,
	EBP_SPECIALGROUPHEAD = 12,
}


[AllowDuplicates]
public enum HEADERCLOSESTATES : int32
{
	EBHC_NORMAL = 1,
	EBHC_HOT = 2,
	EBHC_PRESSED = 3,
}


[AllowDuplicates]
public enum HEADERPINSTATES : int32
{
	EBHP_NORMAL = 1,
	EBHP_HOT = 2,
	EBHP_PRESSED = 3,
	EBHP_SELECTEDNORMAL = 4,
	EBHP_SELECTEDHOT = 5,
	EBHP_SELECTEDPRESSED = 6,
}


[AllowDuplicates]
public enum IEBARMENUSTATES : int32
{
	EBM_NORMAL = 1,
	EBM_HOT = 2,
	EBM_PRESSED = 3,
}


[AllowDuplicates]
public enum NORMALGROUPCOLLAPSESTATES : int32
{
	EBNGC_NORMAL = 1,
	EBNGC_HOT = 2,
	EBNGC_PRESSED = 3,
}


[AllowDuplicates]
public enum NORMALGROUPEXPANDSTATES : int32
{
	EBNGE_NORMAL = 1,
	EBNGE_HOT = 2,
	EBNGE_PRESSED = 3,
}


[AllowDuplicates]
public enum SPECIALGROUPCOLLAPSESTATES : int32
{
	EBSGC_NORMAL = 1,
	EBSGC_HOT = 2,
	EBSGC_PRESSED = 3,
}


[AllowDuplicates]
public enum SPECIALGROUPEXPANDSTATES : int32
{
	EBSGE_NORMAL = 1,
	EBSGE_HOT = 2,
	EBSGE_PRESSED = 3,
}


[AllowDuplicates]
public enum FLYOUTPARTS : int32
{
	FLYOUT_HEADER = 1,
	FLYOUT_BODY = 2,
	FLYOUT_LABEL = 3,
	FLYOUT_LINK = 4,
	FLYOUT_DIVIDER = 5,
	FLYOUT_WINDOW = 6,
	FLYOUT_LINKAREA = 7,
	FLYOUT_LINKHEADER = 8,
}


[AllowDuplicates]
public enum LABELSTATES : int32
{
	FLS_NORMAL = 1,
	FLS_SELECTED = 2,
	FLS_EMPHASIZED = 3,
	FLS_DISABLED = 4,
}


[AllowDuplicates]
public enum LINKSTATES : int32
{
	FLYOUTLINK_NORMAL = 1,
	FLYOUTLINK_HOVER = 2,
}


[AllowDuplicates]
public enum BODYSTATES : int32
{
	FBS_NORMAL = 1,
	FBS_EMPHASIZED = 2,
}


[AllowDuplicates]
public enum LINKHEADERSTATES : int32
{
	FLH_NORMAL = 1,
	FLH_HOVER = 2,
}


[AllowDuplicates]
public enum HEADERPARTS : int32
{
	HP_HEADERITEM = 1,
	HP_HEADERITEMLEFT = 2,
	HP_HEADERITEMRIGHT = 3,
	HP_HEADERSORTARROW = 4,
	HP_HEADERDROPDOWN = 5,
	HP_HEADERDROPDOWNFILTER = 6,
	HP_HEADEROVERFLOW = 7,
}


[AllowDuplicates]
public enum HEADERSTYLESTATES : int32
{
	HBG_DETAILS = 1,
	HBG_ICON = 2,
}


[AllowDuplicates]
public enum HEADERITEMSTATES : int32
{
	HIS_NORMAL = 1,
	HIS_HOT = 2,
	HIS_PRESSED = 3,
	HIS_SORTEDNORMAL = 4,
	HIS_SORTEDHOT = 5,
	HIS_SORTEDPRESSED = 6,
	HIS_ICONNORMAL = 7,
	HIS_ICONHOT = 8,
	HIS_ICONPRESSED = 9,
	HIS_ICONSORTEDNORMAL = 10,
	HIS_ICONSORTEDHOT = 11,
	HIS_ICONSORTEDPRESSED = 12,
}


[AllowDuplicates]
public enum HEADERITEMLEFTSTATES : int32
{
	HILS_NORMAL = 1,
	HILS_HOT = 2,
	HILS_PRESSED = 3,
}


[AllowDuplicates]
public enum HEADERITEMRIGHTSTATES : int32
{
	HIRS_NORMAL = 1,
	HIRS_HOT = 2,
	HIRS_PRESSED = 3,
}


[AllowDuplicates]
public enum HEADERSORTARROWSTATES : int32
{
	HSAS_SORTEDUP = 1,
	HSAS_SORTEDDOWN = 2,
}


[AllowDuplicates]
public enum HEADERDROPDOWNSTATES : int32
{
	HDDS_NORMAL = 1,
	HDDS_SOFTHOT = 2,
	HDDS_HOT = 3,
}


[AllowDuplicates]
public enum HEADERDROPDOWNFILTERSTATES : int32
{
	HDDFS_NORMAL = 1,
	HDDFS_SOFTHOT = 2,
	HDDFS_HOT = 3,
}


[AllowDuplicates]
public enum HEADEROVERFLOWSTATES : int32
{
	HOFS_NORMAL = 1,
	HOFS_HOT = 2,
}


[AllowDuplicates]
public enum LISTBOXPARTS : int32
{
	LBCP_BORDER_HSCROLL = 1,
	LBCP_BORDER_HVSCROLL = 2,
	LBCP_BORDER_NOSCROLL = 3,
	LBCP_BORDER_VSCROLL = 4,
	LBCP_ITEM = 5,
}


[AllowDuplicates]
public enum BORDER_HSCROLLSTATES : int32
{
	LBPSH_NORMAL = 1,
	LBPSH_FOCUSED = 2,
	LBPSH_HOT = 3,
	LBPSH_DISABLED = 4,
}


[AllowDuplicates]
public enum BORDER_HVSCROLLSTATES : int32
{
	LBPSHV_NORMAL = 1,
	LBPSHV_FOCUSED = 2,
	LBPSHV_HOT = 3,
	LBPSHV_DISABLED = 4,
}


[AllowDuplicates]
public enum BORDER_NOSCROLLSTATES : int32
{
	LBPSN_NORMAL = 1,
	LBPSN_FOCUSED = 2,
	LBPSN_HOT = 3,
	LBPSN_DISABLED = 4,
}


[AllowDuplicates]
public enum BORDER_VSCROLLSTATES : int32
{
	LBPSV_NORMAL = 1,
	LBPSV_FOCUSED = 2,
	LBPSV_HOT = 3,
	LBPSV_DISABLED = 4,
}


[AllowDuplicates]
public enum ITEMSTATES : int32
{
	LBPSI_HOT = 1,
	LBPSI_HOTSELECTED = 2,
	LBPSI_SELECTED = 3,
	LBPSI_SELECTEDNOTFOCUS = 4,
}


[AllowDuplicates]
public enum LISTVIEWPARTS : int32
{
	LVP_LISTITEM = 1,
	LVP_LISTGROUP = 2,
	LVP_LISTDETAIL = 3,
	LVP_LISTSORTEDDETAIL = 4,
	LVP_EMPTYTEXT = 5,
	LVP_GROUPHEADER = 6,
	LVP_GROUPHEADERLINE = 7,
	LVP_EXPANDBUTTON = 8,
	LVP_COLLAPSEBUTTON = 9,
	LVP_COLUMNDETAIL = 10,
}


[AllowDuplicates]
public enum LISTITEMSTATES : int32
{
	LISS_NORMAL = 1,
	LISS_HOT = 2,
	LISS_SELECTED = 3,
	LISS_DISABLED = 4,
	LISS_SELECTEDNOTFOCUS = 5,
	LISS_HOTSELECTED = 6,
}


[AllowDuplicates]
public enum GROUPHEADERSTATES : int32
{
	LVGH_OPEN = 1,
	LVGH_OPENHOT = 2,
	LVGH_OPENSELECTED = 3,
	LVGH_OPENSELECTEDHOT = 4,
	LVGH_OPENSELECTEDNOTFOCUSED = 5,
	LVGH_OPENSELECTEDNOTFOCUSEDHOT = 6,
	LVGH_OPENMIXEDSELECTION = 7,
	LVGH_OPENMIXEDSELECTIONHOT = 8,
	LVGH_CLOSE = 9,
	LVGH_CLOSEHOT = 10,
	LVGH_CLOSESELECTED = 11,
	LVGH_CLOSESELECTEDHOT = 12,
	LVGH_CLOSESELECTEDNOTFOCUSED = 13,
	LVGH_CLOSESELECTEDNOTFOCUSEDHOT = 14,
	LVGH_CLOSEMIXEDSELECTION = 15,
	LVGH_CLOSEMIXEDSELECTIONHOT = 16,
}


[AllowDuplicates]
public enum GROUPHEADERLINESTATES : int32
{
	LVGHL_OPEN = 1,
	LVGHL_OPENHOT = 2,
	LVGHL_OPENSELECTED = 3,
	LVGHL_OPENSELECTEDHOT = 4,
	LVGHL_OPENSELECTEDNOTFOCUSED = 5,
	LVGHL_OPENSELECTEDNOTFOCUSEDHOT = 6,
	LVGHL_OPENMIXEDSELECTION = 7,
	LVGHL_OPENMIXEDSELECTIONHOT = 8,
	LVGHL_CLOSE = 9,
	LVGHL_CLOSEHOT = 10,
	LVGHL_CLOSESELECTED = 11,
	LVGHL_CLOSESELECTEDHOT = 12,
	LVGHL_CLOSESELECTEDNOTFOCUSED = 13,
	LVGHL_CLOSESELECTEDNOTFOCUSEDHOT = 14,
	LVGHL_CLOSEMIXEDSELECTION = 15,
	LVGHL_CLOSEMIXEDSELECTIONHOT = 16,
}


[AllowDuplicates]
public enum EXPANDBUTTONSTATES : int32
{
	LVEB_NORMAL = 1,
	LVEB_HOVER = 2,
	LVEB_PUSHED = 3,
}


[AllowDuplicates]
public enum COLLAPSEBUTTONSTATES : int32
{
	LVCB_NORMAL = 1,
	LVCB_HOVER = 2,
	LVCB_PUSHED = 3,
}


[AllowDuplicates]
public enum MENUPARTS : int32
{
	MENU_MENUITEM_TMSCHEMA = 1,
	MENU_MENUDROPDOWN_TMSCHEMA = 2,
	MENU_MENUBARITEM_TMSCHEMA = 3,
	MENU_MENUBARDROPDOWN_TMSCHEMA = 4,
	MENU_CHEVRON_TMSCHEMA = 5,
	MENU_SEPARATOR_TMSCHEMA = 6,
	MENU_BARBACKGROUND = 7,
	MENU_BARITEM = 8,
	MENU_POPUPBACKGROUND = 9,
	MENU_POPUPBORDERS = 10,
	MENU_POPUPCHECK = 11,
	MENU_POPUPCHECKBACKGROUND = 12,
	MENU_POPUPGUTTER = 13,
	MENU_POPUPITEM = 14,
	MENU_POPUPSEPARATOR = 15,
	MENU_POPUPSUBMENU = 16,
	MENU_SYSTEMCLOSE = 17,
	MENU_SYSTEMMAXIMIZE = 18,
	MENU_SYSTEMMINIMIZE = 19,
	MENU_SYSTEMRESTORE = 20,
}


[AllowDuplicates]
public enum BARBACKGROUNDSTATES : int32
{
	MB_ACTIVE = 1,
	MB_INACTIVE = 2,
}


[AllowDuplicates]
public enum BARITEMSTATES : int32
{
	MBI_NORMAL = 1,
	MBI_HOT = 2,
	MBI_PUSHED = 3,
	MBI_DISABLED = 4,
	MBI_DISABLEDHOT = 5,
	MBI_DISABLEDPUSHED = 6,
}


[AllowDuplicates]
public enum POPUPCHECKSTATES : int32
{
	MC_CHECKMARKNORMAL = 1,
	MC_CHECKMARKDISABLED = 2,
	MC_BULLETNORMAL = 3,
	MC_BULLETDISABLED = 4,
}


[AllowDuplicates]
public enum POPUPCHECKBACKGROUNDSTATES : int32
{
	MCB_DISABLED = 1,
	MCB_NORMAL = 2,
	MCB_BITMAP = 3,
}


[AllowDuplicates]
public enum POPUPITEMSTATES : int32
{
	MPI_NORMAL = 1,
	MPI_HOT = 2,
	MPI_DISABLED = 3,
	MPI_DISABLEDHOT = 4,
}


[AllowDuplicates]
public enum POPUPSUBMENUSTATES : int32
{
	MSM_NORMAL = 1,
	MSM_DISABLED = 2,
}


[AllowDuplicates]
public enum SYSTEMCLOSESTATES : int32
{
	MSYSC_NORMAL = 1,
	MSYSC_DISABLED = 2,
}


[AllowDuplicates]
public enum SYSTEMMAXIMIZESTATES : int32
{
	MSYSMX_NORMAL = 1,
	MSYSMX_DISABLED = 2,
}


[AllowDuplicates]
public enum SYSTEMMINIMIZESTATES : int32
{
	MSYSMN_NORMAL = 1,
	MSYSMN_DISABLED = 2,
}


[AllowDuplicates]
public enum SYSTEMRESTORESTATES : int32
{
	MSYSR_NORMAL = 1,
	MSYSR_DISABLED = 2,
}


[AllowDuplicates]
public enum NAVIGATIONPARTS : int32
{
	NAV_BACKBUTTON = 1,
	NAV_FORWARDBUTTON = 2,
	NAV_MENUBUTTON = 3,
}


[AllowDuplicates]
public enum NAV_BACKBUTTONSTATES : int32
{
	NAV_BB_NORMAL = 1,
	NAV_BB_HOT = 2,
	NAV_BB_PRESSED = 3,
	NAV_BB_DISABLED = 4,
}


[AllowDuplicates]
public enum NAV_FORWARDBUTTONSTATES : int32
{
	NAV_FB_NORMAL = 1,
	NAV_FB_HOT = 2,
	NAV_FB_PRESSED = 3,
	NAV_FB_DISABLED = 4,
}


[AllowDuplicates]
public enum NAV_MENUBUTTONSTATES : int32
{
	NAV_MB_NORMAL = 1,
	NAV_MB_HOT = 2,
	NAV_MB_PRESSED = 3,
	NAV_MB_DISABLED = 4,
}


[AllowDuplicates]
public enum PROGRESSPARTS : int32
{
	PP_BAR = 1,
	PP_BARVERT = 2,
	PP_CHUNK = 3,
	PP_CHUNKVERT = 4,
	PP_FILL = 5,
	PP_FILLVERT = 6,
	PP_PULSEOVERLAY = 7,
	PP_MOVEOVERLAY = 8,
	PP_PULSEOVERLAYVERT = 9,
	PP_MOVEOVERLAYVERT = 10,
	PP_TRANSPARENTBAR = 11,
	PP_TRANSPARENTBARVERT = 12,
}


[AllowDuplicates]
public enum TRANSPARENTBARSTATES : int32
{
	PBBS_NORMAL = 1,
	PBBS_PARTIAL = 2,
}


[AllowDuplicates]
public enum TRANSPARENTBARVERTSTATES : int32
{
	PBBVS_NORMAL = 1,
	PBBVS_PARTIAL = 2,
}


[AllowDuplicates]
public enum FILLSTATES : int32
{
	PBFS_NORMAL = 1,
	PBFS_ERROR = 2,
	PBFS_PAUSED = 3,
	PBFS_PARTIAL = 4,
}


[AllowDuplicates]
public enum FILLVERTSTATES : int32
{
	PBFVS_NORMAL = 1,
	PBFVS_ERROR = 2,
	PBFVS_PAUSED = 3,
	PBFVS_PARTIAL = 4,
}


[AllowDuplicates]
public enum REBARPARTS : int32
{
	RP_GRIPPER = 1,
	RP_GRIPPERVERT = 2,
	RP_BAND = 3,
	RP_CHEVRON = 4,
	RP_CHEVRONVERT = 5,
	RP_BACKGROUND = 6,
	RP_SPLITTER = 7,
	RP_SPLITTERVERT = 8,
}


[AllowDuplicates]
public enum CHEVRONSTATES : int32
{
	CHEVS_NORMAL = 1,
	CHEVS_HOT = 2,
	CHEVS_PRESSED = 3,
}


[AllowDuplicates]
public enum CHEVRONVERTSTATES : int32
{
	CHEVSV_NORMAL = 1,
	CHEVSV_HOT = 2,
	CHEVSV_PRESSED = 3,
}


[AllowDuplicates]
public enum SPLITTERSTATES : int32
{
	SPLITS_NORMAL = 1,
	SPLITS_HOT = 2,
	SPLITS_PRESSED = 3,
}


[AllowDuplicates]
public enum SPLITTERVERTSTATES : int32
{
	SPLITSV_NORMAL = 1,
	SPLITSV_HOT = 2,
	SPLITSV_PRESSED = 3,
}


[AllowDuplicates]
public enum SCROLLBARPARTS : int32
{
	SBP_ARROWBTN = 1,
	SBP_THUMBBTNHORZ = 2,
	SBP_THUMBBTNVERT = 3,
	SBP_LOWERTRACKHORZ = 4,
	SBP_UPPERTRACKHORZ = 5,
	SBP_LOWERTRACKVERT = 6,
	SBP_UPPERTRACKVERT = 7,
	SBP_GRIPPERHORZ = 8,
	SBP_GRIPPERVERT = 9,
	SBP_SIZEBOX = 10,
	SBP_SIZEBOXBKGND = 11,
}


[AllowDuplicates]
public enum ARROWBTNSTATES : int32
{
	ABS_UPNORMAL = 1,
	ABS_UPHOT = 2,
	ABS_UPPRESSED = 3,
	ABS_UPDISABLED = 4,
	ABS_DOWNNORMAL = 5,
	ABS_DOWNHOT = 6,
	ABS_DOWNPRESSED = 7,
	ABS_DOWNDISABLED = 8,
	ABS_LEFTNORMAL = 9,
	ABS_LEFTHOT = 10,
	ABS_LEFTPRESSED = 11,
	ABS_LEFTDISABLED = 12,
	ABS_RIGHTNORMAL = 13,
	ABS_RIGHTHOT = 14,
	ABS_RIGHTPRESSED = 15,
	ABS_RIGHTDISABLED = 16,
	ABS_UPHOVER = 17,
	ABS_DOWNHOVER = 18,
	ABS_LEFTHOVER = 19,
	ABS_RIGHTHOVER = 20,
}


[AllowDuplicates]
public enum SCROLLBARSTYLESTATES : int32
{
	SCRBS_NORMAL = 1,
	SCRBS_HOT = 2,
	SCRBS_PRESSED = 3,
	SCRBS_DISABLED = 4,
	SCRBS_HOVER = 5,
}


[AllowDuplicates]
public enum SIZEBOXSTATES : int32
{
	SZB_RIGHTALIGN = 1,
	SZB_LEFTALIGN = 2,
	SZB_TOPRIGHTALIGN = 3,
	SZB_TOPLEFTALIGN = 4,
	SZB_HALFBOTTOMRIGHTALIGN = 5,
	SZB_HALFBOTTOMLEFTALIGN = 6,
	SZB_HALFTOPRIGHTALIGN = 7,
	SZB_HALFTOPLEFTALIGN = 8,
}


[AllowDuplicates]
public enum SPINPARTS : int32
{
	SPNP_UP = 1,
	SPNP_DOWN = 2,
	SPNP_UPHORZ = 3,
	SPNP_DOWNHORZ = 4,
}


[AllowDuplicates]
public enum UPSTATES : int32
{
	UPS_NORMAL = 1,
	UPS_HOT = 2,
	UPS_PRESSED = 3,
	UPS_DISABLED = 4,
}


[AllowDuplicates]
public enum DOWNSTATES : int32
{
	DNS_NORMAL = 1,
	DNS_HOT = 2,
	DNS_PRESSED = 3,
	DNS_DISABLED = 4,
}


[AllowDuplicates]
public enum UPHORZSTATES : int32
{
	UPHZS_NORMAL = 1,
	UPHZS_HOT = 2,
	UPHZS_PRESSED = 3,
	UPHZS_DISABLED = 4,
}


[AllowDuplicates]
public enum DOWNHORZSTATES : int32
{
	DNHZS_NORMAL = 1,
	DNHZS_HOT = 2,
	DNHZS_PRESSED = 3,
	DNHZS_DISABLED = 4,
}


[AllowDuplicates]
public enum STATUSPARTS : int32
{
	SP_PANE = 1,
	SP_GRIPPERPANE = 2,
	SP_GRIPPER = 3,
}


[AllowDuplicates]
public enum TABPARTS : int32
{
	TABP_TABITEM = 1,
	TABP_TABITEMLEFTEDGE = 2,
	TABP_TABITEMRIGHTEDGE = 3,
	TABP_TABITEMBOTHEDGE = 4,
	TABP_TOPTABITEM = 5,
	TABP_TOPTABITEMLEFTEDGE = 6,
	TABP_TOPTABITEMRIGHTEDGE = 7,
	TABP_TOPTABITEMBOTHEDGE = 8,
	TABP_PANE = 9,
	TABP_BODY = 10,
	TABP_AEROWIZARDBODY = 11,
}


[AllowDuplicates]
public enum TABITEMSTATES : int32
{
	TIS_NORMAL = 1,
	TIS_HOT = 2,
	TIS_SELECTED = 3,
	TIS_DISABLED = 4,
	TIS_FOCUSED = 5,
}


[AllowDuplicates]
public enum TABITEMLEFTEDGESTATES : int32
{
	TILES_NORMAL = 1,
	TILES_HOT = 2,
	TILES_SELECTED = 3,
	TILES_DISABLED = 4,
	TILES_FOCUSED = 5,
}


[AllowDuplicates]
public enum TABITEMRIGHTEDGESTATES : int32
{
	TIRES_NORMAL = 1,
	TIRES_HOT = 2,
	TIRES_SELECTED = 3,
	TIRES_DISABLED = 4,
	TIRES_FOCUSED = 5,
}


[AllowDuplicates]
public enum TABITEMBOTHEDGESTATES : int32
{
	TIBES_NORMAL = 1,
	TIBES_HOT = 2,
	TIBES_SELECTED = 3,
	TIBES_DISABLED = 4,
	TIBES_FOCUSED = 5,
}


[AllowDuplicates]
public enum TOPTABITEMSTATES : int32
{
	TTIS_NORMAL = 1,
	TTIS_HOT = 2,
	TTIS_SELECTED = 3,
	TTIS_DISABLED = 4,
	TTIS_FOCUSED = 5,
}


[AllowDuplicates]
public enum TOPTABITEMLEFTEDGESTATES : int32
{
	TTILES_NORMAL = 1,
	TTILES_HOT = 2,
	TTILES_SELECTED = 3,
	TTILES_DISABLED = 4,
	TTILES_FOCUSED = 5,
}


[AllowDuplicates]
public enum TOPTABITEMRIGHTEDGESTATES : int32
{
	TTIRES_NORMAL = 1,
	TTIRES_HOT = 2,
	TTIRES_SELECTED = 3,
	TTIRES_DISABLED = 4,
	TTIRES_FOCUSED = 5,
}


[AllowDuplicates]
public enum TOPTABITEMBOTHEDGESTATES : int32
{
	TTIBES_NORMAL = 1,
	TTIBES_HOT = 2,
	TTIBES_SELECTED = 3,
	TTIBES_DISABLED = 4,
	TTIBES_FOCUSED = 5,
}


[AllowDuplicates]
public enum TASKDIALOGPARTS : int32
{
	TDLG_PRIMARYPANEL = 1,
	TDLG_MAININSTRUCTIONPANE = 2,
	TDLG_MAINICON = 3,
	TDLG_CONTENTPANE = 4,
	TDLG_CONTENTICON = 5,
	TDLG_EXPANDEDCONTENT = 6,
	TDLG_COMMANDLINKPANE = 7,
	TDLG_SECONDARYPANEL = 8,
	TDLG_CONTROLPANE = 9,
	TDLG_BUTTONSECTION = 10,
	TDLG_BUTTONWRAPPER = 11,
	TDLG_EXPANDOTEXT = 12,
	TDLG_EXPANDOBUTTON = 13,
	TDLG_VERIFICATIONTEXT = 14,
	TDLG_FOOTNOTEPANE = 15,
	TDLG_FOOTNOTEAREA = 16,
	TDLG_FOOTNOTESEPARATOR = 17,
	TDLG_EXPANDEDFOOTERAREA = 18,
	TDLG_PROGRESSBAR = 19,
	TDLG_IMAGEALIGNMENT = 20,
	TDLG_RADIOBUTTONPANE = 21,
}


[AllowDuplicates]
public enum CONTENTPANESTATES : int32
{
	TDLGCPS_STANDALONE = 1,
}


[AllowDuplicates]
public enum EXPANDOBUTTONSTATES : int32
{
	TDLGEBS_NORMAL = 1,
	TDLGEBS_HOVER = 2,
	TDLGEBS_PRESSED = 3,
	TDLGEBS_EXPANDEDNORMAL = 4,
	TDLGEBS_EXPANDEDHOVER = 5,
	TDLGEBS_EXPANDEDPRESSED = 6,
	TDLGEBS_NORMALDISABLED = 7,
	TDLGEBS_EXPANDEDDISABLED = 8,
}


[AllowDuplicates]
public enum TEXTSTYLEPARTS : int32
{
	TEXT_MAININSTRUCTION = 1,
	TEXT_INSTRUCTION = 2,
	TEXT_BODYTITLE = 3,
	TEXT_BODYTEXT = 4,
	TEXT_SECONDARYTEXT = 5,
	TEXT_HYPERLINKTEXT = 6,
	TEXT_EXPANDED = 7,
	TEXT_LABEL = 8,
	TEXT_CONTROLLABEL = 9,
}


[AllowDuplicates]
public enum HYPERLINKTEXTSTATES : int32
{
	TS_HYPERLINK_NORMAL = 1,
	TS_HYPERLINK_HOT = 2,
	TS_HYPERLINK_PRESSED = 3,
	TS_HYPERLINK_DISABLED = 4,
}


[AllowDuplicates]
public enum CONTROLLABELSTATES : int32
{
	TS_CONTROLLABEL_NORMAL = 1,
	TS_CONTROLLABEL_DISABLED = 2,
}


[AllowDuplicates]
public enum TOOLBARPARTS : int32
{
	TP_BUTTON = 1,
	TP_DROPDOWNBUTTON = 2,
	TP_SPLITBUTTON = 3,
	TP_SPLITBUTTONDROPDOWN = 4,
	TP_SEPARATOR = 5,
	TP_SEPARATORVERT = 6,
	TP_DROPDOWNBUTTONGLYPH = 7,
}


[AllowDuplicates]
public enum TOOLBARSTYLESTATES : int32
{
	TS_NORMAL = 1,
	TS_HOT = 2,
	TS_PRESSED = 3,
	TS_DISABLED = 4,
	TS_CHECKED = 5,
	TS_HOTCHECKED = 6,
	TS_NEARHOT = 7,
	TS_OTHERSIDEHOT = 8,
}


[AllowDuplicates]
public enum TOOLTIPPARTS : int32
{
	TTP_STANDARD = 1,
	TTP_STANDARDTITLE = 2,
	TTP_BALLOON = 3,
	TTP_BALLOONTITLE = 4,
	TTP_CLOSE = 5,
	TTP_BALLOONSTEM = 6,
	TTP_WRENCH = 7,
}


[AllowDuplicates]
public enum CLOSESTATES : int32
{
	TTCS_NORMAL = 1,
	TTCS_HOT = 2,
	TTCS_PRESSED = 3,
}


[AllowDuplicates]
public enum STANDARDSTATES : int32
{
	TTSS_NORMAL = 1,
	TTSS_LINK = 2,
}


[AllowDuplicates]
public enum BALLOONSTATES : int32
{
	TTBS_NORMAL = 1,
	TTBS_LINK = 2,
}


[AllowDuplicates]
public enum BALLOONSTEMSTATES : int32
{
	TTBSS_POINTINGUPLEFTWALL = 1,
	TTBSS_POINTINGUPCENTERED = 2,
	TTBSS_POINTINGUPRIGHTWALL = 3,
	TTBSS_POINTINGDOWNRIGHTWALL = 4,
	TTBSS_POINTINGDOWNCENTERED = 5,
	TTBSS_POINTINGDOWNLEFTWALL = 6,
}


[AllowDuplicates]
public enum WRENCHSTATES : int32
{
	TTWS_NORMAL = 1,
	TTWS_HOT = 2,
	TTWS_PRESSED = 3,
}


[AllowDuplicates]
public enum TRACKBARPARTS : int32
{
	TKP_TRACK = 1,
	TKP_TRACKVERT = 2,
	TKP_THUMB = 3,
	TKP_THUMBBOTTOM = 4,
	TKP_THUMBTOP = 5,
	TKP_THUMBVERT = 6,
	TKP_THUMBLEFT = 7,
	TKP_THUMBRIGHT = 8,
	TKP_TICS = 9,
	TKP_TICSVERT = 10,
}


[AllowDuplicates]
public enum TRACKBARSTYLESTATES : int32
{
	TKS_NORMAL = 1,
}


[AllowDuplicates]
public enum TRACKSTATES : int32
{
	TRS_NORMAL = 1,
}


[AllowDuplicates]
public enum TRACKVERTSTATES : int32
{
	TRVS_NORMAL = 1,
}


[AllowDuplicates]
public enum THUMBSTATES : int32
{
	TUS_NORMAL = 1,
	TUS_HOT = 2,
	TUS_PRESSED = 3,
	TUS_FOCUSED = 4,
	TUS_DISABLED = 5,
}


[AllowDuplicates]
public enum THUMBBOTTOMSTATES : int32
{
	TUBS_NORMAL = 1,
	TUBS_HOT = 2,
	TUBS_PRESSED = 3,
	TUBS_FOCUSED = 4,
	TUBS_DISABLED = 5,
}


[AllowDuplicates]
public enum THUMBTOPSTATES : int32
{
	TUTS_NORMAL = 1,
	TUTS_HOT = 2,
	TUTS_PRESSED = 3,
	TUTS_FOCUSED = 4,
	TUTS_DISABLED = 5,
}


[AllowDuplicates]
public enum THUMBVERTSTATES : int32
{
	TUVS_NORMAL = 1,
	TUVS_HOT = 2,
	TUVS_PRESSED = 3,
	TUVS_FOCUSED = 4,
	TUVS_DISABLED = 5,
}


[AllowDuplicates]
public enum THUMBLEFTSTATES : int32
{
	TUVLS_NORMAL = 1,
	TUVLS_HOT = 2,
	TUVLS_PRESSED = 3,
	TUVLS_FOCUSED = 4,
	TUVLS_DISABLED = 5,
}


[AllowDuplicates]
public enum THUMBRIGHTSTATES : int32
{
	TUVRS_NORMAL = 1,
	TUVRS_HOT = 2,
	TUVRS_PRESSED = 3,
	TUVRS_FOCUSED = 4,
	TUVRS_DISABLED = 5,
}


[AllowDuplicates]
public enum TICSSTATES : int32
{
	TSS_NORMAL = 1,
}


[AllowDuplicates]
public enum TICSVERTSTATES : int32
{
	TSVS_NORMAL = 1,
}


[AllowDuplicates]
public enum TREEVIEWPARTS : int32
{
	TVP_TREEITEM = 1,
	TVP_GLYPH = 2,
	TVP_BRANCH = 3,
	TVP_HOTGLYPH = 4,
}


[AllowDuplicates]
public enum TREEITEMSTATES : int32
{
	TREIS_NORMAL = 1,
	TREIS_HOT = 2,
	TREIS_SELECTED = 3,
	TREIS_DISABLED = 4,
	TREIS_SELECTEDNOTFOCUS = 5,
	TREIS_HOTSELECTED = 6,
}


[AllowDuplicates]
public enum GLYPHSTATES : int32
{
	GLPS_CLOSED = 1,
	GLPS_OPENED = 2,
}


[AllowDuplicates]
public enum HOTGLYPHSTATES : int32
{
	HGLPS_CLOSED = 1,
	HGLPS_OPENED = 2,
}


[AllowDuplicates]
public enum USERTILEPARTS : int32
{
	UTP_STROKEBACKGROUND = 1,
	UTP_HOVERBACKGROUND = 2,
}


[AllowDuplicates]
public enum HOVERBACKGROUNDSTATES : int32
{
	UTS_NORMAL = 1,
	UTS_HOT = 2,
	UTS_PRESSED = 3,
}


[AllowDuplicates]
public enum TEXTSELECTIONGRIPPERPARTS : int32
{
	TSGP_GRIPPER = 1,
}


[AllowDuplicates]
public enum GRIPPERSTATES : int32
{
	TSGS_NORMAL = 1,
	TSGS_CENTERED = 2,
}


[AllowDuplicates]
public enum WINDOWPARTS : int32
{
	WP_CAPTION = 1,
	WP_SMALLCAPTION = 2,
	WP_MINCAPTION = 3,
	WP_SMALLMINCAPTION = 4,
	WP_MAXCAPTION = 5,
	WP_SMALLMAXCAPTION = 6,
	WP_FRAMELEFT = 7,
	WP_FRAMERIGHT = 8,
	WP_FRAMEBOTTOM = 9,
	WP_SMALLFRAMELEFT = 10,
	WP_SMALLFRAMERIGHT = 11,
	WP_SMALLFRAMEBOTTOM = 12,
	WP_SYSBUTTON = 13,
	WP_MDISYSBUTTON = 14,
	WP_MINBUTTON = 15,
	WP_MDIMINBUTTON = 16,
	WP_MAXBUTTON = 17,
	WP_CLOSEBUTTON = 18,
	WP_SMALLCLOSEBUTTON = 19,
	WP_MDICLOSEBUTTON = 20,
	WP_RESTOREBUTTON = 21,
	WP_MDIRESTOREBUTTON = 22,
	WP_HELPBUTTON = 23,
	WP_MDIHELPBUTTON = 24,
	WP_HORZSCROLL = 25,
	WP_HORZTHUMB = 26,
	WP_VERTSCROLL = 27,
	WP_VERTTHUMB = 28,
	WP_DIALOG = 29,
	WP_CAPTIONSIZINGTEMPLATE = 30,
	WP_SMALLCAPTIONSIZINGTEMPLATE = 31,
	WP_FRAMELEFTSIZINGTEMPLATE = 32,
	WP_SMALLFRAMELEFTSIZINGTEMPLATE = 33,
	WP_FRAMERIGHTSIZINGTEMPLATE = 34,
	WP_SMALLFRAMERIGHTSIZINGTEMPLATE = 35,
	WP_FRAMEBOTTOMSIZINGTEMPLATE = 36,
	WP_SMALLFRAMEBOTTOMSIZINGTEMPLATE = 37,
	WP_FRAME = 38,
	WP_BORDER = 39,
}


[AllowDuplicates]
public enum FRAMESTATES : int32
{
	FS_ACTIVE = 1,
	FS_INACTIVE = 2,
}


[AllowDuplicates]
public enum CAPTIONSTATES : int32
{
	CS_ACTIVE = 1,
	CS_INACTIVE = 2,
	CS_DISABLED = 3,
}


[AllowDuplicates]
public enum MAXCAPTIONSTATES : int32
{
	MXCS_ACTIVE = 1,
	MXCS_INACTIVE = 2,
	MXCS_DISABLED = 3,
}


[AllowDuplicates]
public enum MINCAPTIONSTATES : int32
{
	MNCS_ACTIVE = 1,
	MNCS_INACTIVE = 2,
	MNCS_DISABLED = 3,
}


[AllowDuplicates]
public enum HORZSCROLLSTATES : int32
{
	HSS_NORMAL = 1,
	HSS_HOT = 2,
	HSS_PUSHED = 3,
	HSS_DISABLED = 4,
}


[AllowDuplicates]
public enum HORZTHUMBSTATES : int32
{
	HTS_NORMAL = 1,
	HTS_HOT = 2,
	HTS_PUSHED = 3,
	HTS_DISABLED = 4,
}


[AllowDuplicates]
public enum VERTSCROLLSTATES : int32
{
	VSS_NORMAL = 1,
	VSS_HOT = 2,
	VSS_PUSHED = 3,
	VSS_DISABLED = 4,
}


[AllowDuplicates]
public enum VERTTHUMBSTATES : int32
{
	VTS_NORMAL = 1,
	VTS_HOT = 2,
	VTS_PUSHED = 3,
	VTS_DISABLED = 4,
}


[AllowDuplicates]
public enum SYSBUTTONSTATES : int32
{
	SBS_NORMAL = 1,
	SBS_HOT = 2,
	SBS_PUSHED = 3,
	SBS_DISABLED = 4,
}


[AllowDuplicates]
public enum MINBUTTONSTATES : int32
{
	MINBS_NORMAL = 1,
	MINBS_HOT = 2,
	MINBS_PUSHED = 3,
	MINBS_DISABLED = 4,
}


[AllowDuplicates]
public enum MAXBUTTONSTATES : int32
{
	MAXBS_NORMAL = 1,
	MAXBS_HOT = 2,
	MAXBS_PUSHED = 3,
	MAXBS_DISABLED = 4,
}


[AllowDuplicates]
public enum RESTOREBUTTONSTATES : int32
{
	RBS_NORMAL = 1,
	RBS_HOT = 2,
	RBS_PUSHED = 3,
	RBS_DISABLED = 4,
}


[AllowDuplicates]
public enum HELPBUTTONSTATES : int32
{
	HBS_NORMAL = 1,
	HBS_HOT = 2,
	HBS_PUSHED = 3,
	HBS_DISABLED = 4,
}


[AllowDuplicates]
public enum CLOSEBUTTONSTATES : int32
{
	CBS_NORMAL = 1,
	CBS_HOT = 2,
	CBS_PUSHED = 3,
	CBS_DISABLED = 4,
}


[AllowDuplicates]
public enum SMALLCLOSEBUTTONSTATES : int32
{
	SCBS_NORMAL = 1,
	SCBS_HOT = 2,
	SCBS_PUSHED = 3,
	SCBS_DISABLED = 4,
}


[AllowDuplicates]
public enum FRAMEBOTTOMSTATES : int32
{
	FRB_ACTIVE = 1,
	FRB_INACTIVE = 2,
}


[AllowDuplicates]
public enum FRAMELEFTSTATES : int32
{
	FRL_ACTIVE = 1,
	FRL_INACTIVE = 2,
}


[AllowDuplicates]
public enum FRAMERIGHTSTATES : int32
{
	FRR_ACTIVE = 1,
	FRR_INACTIVE = 2,
}


[AllowDuplicates]
public enum SMALLCAPTIONSTATES : int32
{
	SCS_ACTIVE = 1,
	SCS_INACTIVE = 2,
	SCS_DISABLED = 3,
}


[AllowDuplicates]
public enum SMALLFRAMEBOTTOMSTATES : int32
{
	SFRB_ACTIVE = 1,
	SFRB_INACTIVE = 2,
}


[AllowDuplicates]
public enum SMALLFRAMELEFTSTATES : int32
{
	SFRL_ACTIVE = 1,
	SFRL_INACTIVE = 2,
}


[AllowDuplicates]
public enum SMALLFRAMERIGHTSTATES : int32
{
	SFRR_ACTIVE = 1,
	SFRR_INACTIVE = 2,
}


[AllowDuplicates]
public enum MDICLOSEBUTTONSTATES : int32
{
	MDCL_NORMAL = 1,
	MDCL_HOT = 2,
	MDCL_PUSHED = 3,
	MDCL_DISABLED = 4,
}


[AllowDuplicates]
public enum MDIMINBUTTONSTATES : int32
{
	MDMI_NORMAL = 1,
	MDMI_HOT = 2,
	MDMI_PUSHED = 3,
	MDMI_DISABLED = 4,
}


[AllowDuplicates]
public enum MDIRESTOREBUTTONSTATES : int32
{
	MDRE_NORMAL = 1,
	MDRE_HOT = 2,
	MDRE_PUSHED = 3,
	MDRE_DISABLED = 4,
}


[AllowDuplicates]
public enum BGTYPE : int32
{
	BT_IMAGEFILE = 0,
	BT_BORDERFILL = 1,
	BT_NONE = 2,
}


[AllowDuplicates]
public enum IMAGELAYOUT : int32
{
	IL_VERTICAL = 0,
	IL_HORIZONTAL = 1,
}


[AllowDuplicates]
public enum BORDERTYPE : int32
{
	BT_RECT = 0,
	BT_ROUNDRECT = 1,
	BT_ELLIPSE = 2,
}


[AllowDuplicates]
public enum FILLTYPE : int32
{
	FT_SOLID = 0,
	FT_VERTGRADIENT = 1,
	FT_HORZGRADIENT = 2,
	FT_RADIALGRADIENT = 3,
	FT_TILEIMAGE = 4,
}


[AllowDuplicates]
public enum SIZINGTYPE : int32
{
	ST_TRUESIZE = 0,
	ST_STRETCH = 1,
	ST_TILE = 2,
}


[AllowDuplicates]
public enum HALIGN : int32
{
	HA_LEFT = 0,
	HA_CENTER = 1,
	HA_RIGHT = 2,
}


[AllowDuplicates]
public enum CONTENTALIGNMENT : int32
{
	CA_LEFT = 0,
	CA_CENTER = 1,
	CA_RIGHT = 2,
}


[AllowDuplicates]
public enum VALIGN : int32
{
	VA_TOP = 0,
	VA_CENTER = 1,
	VA_BOTTOM = 2,
}


[AllowDuplicates]
public enum OFFSETTYPE : int32
{
	OT_TOPLEFT = 0,
	OT_TOPRIGHT = 1,
	OT_TOPMIDDLE = 2,
	OT_BOTTOMLEFT = 3,
	OT_BOTTOMRIGHT = 4,
	OT_BOTTOMMIDDLE = 5,
	OT_MIDDLELEFT = 6,
	OT_MIDDLERIGHT = 7,
	OT_LEFTOFCAPTION = 8,
	OT_RIGHTOFCAPTION = 9,
	OT_LEFTOFLASTBUTTON = 10,
	OT_RIGHTOFLASTBUTTON = 11,
	OT_ABOVELASTBUTTON = 12,
	OT_BELOWLASTBUTTON = 13,
}


[AllowDuplicates]
public enum ICONEFFECT : int32
{
	ICE_NONE = 0,
	ICE_GLOW = 1,
	ICE_SHADOW = 2,
	ICE_PULSE = 3,
	ICE_ALPHA = 4,
}


[AllowDuplicates]
public enum TEXTSHADOWTYPE : int32
{
	TST_NONE = 0,
	TST_SINGLE = 1,
	TST_CONTINUOUS = 2,
}


[AllowDuplicates]
public enum GLYPHTYPE : int32
{
	GT_NONE = 0,
	GT_IMAGEGLYPH = 1,
	GT_FONTGLYPH = 2,
}


[AllowDuplicates]
public enum IMAGESELECTTYPE : int32
{
	IST_NONE = 0,
	IST_SIZE = 1,
	IST_DPI = 2,
}


[AllowDuplicates]
public enum TRUESIZESCALINGTYPE : int32
{
	TSST_NONE = 0,
	TSST_SIZE = 1,
	TSST_DPI = 2,
}


[AllowDuplicates]
public enum GLYPHFONTSIZINGTYPE : int32
{
	GFST_NONE = 0,
	GFST_SIZE = 1,
	GFST_DPI = 2,
}


[AllowDuplicates]
public enum LINKPARTS : int32
{
	LP_HYPERLINK = 1,
}


[AllowDuplicates]
public enum HYPERLINKSTATES : int32
{
	HLS_NORMALTEXT = 1,
	HLS_LINKTEXT = 2,
}


[AllowDuplicates]
public enum EMPTYMARKUPPARTS : int32
{
	EMP_MARKUPTEXT = 1,
}


[AllowDuplicates]
public enum MARKUPTEXTSTATES : int32
{
	EMT_NORMALTEXT = 1,
	EMT_LINKTEXT = 2,
}


[AllowDuplicates]
public enum STATICPARTS : int32
{
	STAT_TEXT = 1,
}


[AllowDuplicates]
public enum PAGEPARTS : int32
{
	PGRP_UP = 1,
	PGRP_DOWN = 2,
	PGRP_UPHORZ = 3,
	PGRP_DOWNHORZ = 4,
}


[AllowDuplicates]
public enum MONTHCALPARTS : int32
{
	MC_BACKGROUND = 1,
	MC_BORDERS = 2,
	MC_GRIDBACKGROUND = 3,
	MC_COLHEADERSPLITTER = 4,
	MC_GRIDCELLBACKGROUND = 5,
	MC_GRIDCELL = 6,
	MC_GRIDCELLUPPER = 7,
	MC_TRAILINGGRIDCELL = 8,
	MC_TRAILINGGRIDCELLUPPER = 9,
	MC_NAVNEXT = 10,
	MC_NAVPREV = 11,
}


[AllowDuplicates]
public enum GRIDCELLBACKGROUNDSTATES : int32
{
	MCGCB_SELECTED = 1,
	MCGCB_HOT = 2,
	MCGCB_SELECTEDHOT = 3,
	MCGCB_SELECTEDNOTFOCUSED = 4,
	MCGCB_TODAY = 5,
	MCGCB_TODAYSELECTED = 6,
}


[AllowDuplicates]
public enum GRIDCELLSTATES : int32
{
	MCGC_HOT = 1,
	MCGC_HASSTATE = 2,
	MCGC_HASSTATEHOT = 3,
	MCGC_TODAY = 4,
	MCGC_TODAYSELECTED = 5,
	MCGC_SELECTED = 6,
	MCGC_SELECTEDHOT = 7,
}


[AllowDuplicates]
public enum GRIDCELLUPPERSTATES : int32
{
	MCGCU_HOT = 1,
	MCGCU_HASSTATE = 2,
	MCGCU_HASSTATEHOT = 3,
	MCGCU_SELECTED = 4,
	MCGCU_SELECTEDHOT = 5,
}


[AllowDuplicates]
public enum TRAILINGGRIDCELLSTATES : int32
{
	MCTGC_HOT = 1,
	MCTGC_HASSTATE = 2,
	MCTGC_HASSTATEHOT = 3,
	MCTGC_TODAY = 4,
	MCTGC_TODAYSELECTED = 5,
	MCTGC_SELECTED = 6,
	MCTGC_SELECTEDHOT = 7,
}


[AllowDuplicates]
public enum TRAILINGGRIDCELLUPPERSTATES : int32
{
	MCTGCU_HOT = 1,
	MCTGCU_HASSTATE = 2,
	MCTGCU_HASSTATEHOT = 3,
	MCTGCU_SELECTED = 4,
	MCTGCU_SELECTEDHOT = 5,
}


[AllowDuplicates]
public enum NAVNEXTSTATES : int32
{
	MCNN_NORMAL = 1,
	MCNN_HOT = 2,
	MCNN_PRESSED = 3,
	MCNN_DISABLED = 4,
}


[AllowDuplicates]
public enum NAVPREVSTATES : int32
{
	MCNP_NORMAL = 1,
	MCNP_HOT = 2,
	MCNP_PRESSED = 3,
	MCNP_DISABLED = 4,
}


[AllowDuplicates]
public enum CLOCKPARTS : int32
{
	CLP_TIME = 1,
}


[AllowDuplicates]
public enum CLOCKSTATES : int32
{
	CLS_NORMAL = 1,
	CLS_HOT = 2,
	CLS_PRESSED = 3,
}


[AllowDuplicates]
public enum TRAYNOTIFYPARTS : int32
{
	TNP_BACKGROUND = 1,
	TNP_ANIMBACKGROUND = 2,
}


[AllowDuplicates]
public enum TASKBARPARTS : int32
{
	TBP_BACKGROUNDBOTTOM = 1,
	TBP_BACKGROUNDRIGHT = 2,
	TBP_BACKGROUNDTOP = 3,
	TBP_BACKGROUNDLEFT = 4,
	TBP_SIZINGBARBOTTOM = 5,
	TBP_SIZINGBARRIGHT = 6,
	TBP_SIZINGBARTOP = 7,
	TBP_SIZINGBARLEFT = 8,
}


[AllowDuplicates]
public enum TASKBANDPARTS : int32
{
	TDP_GROUPCOUNT = 1,
	TDP_FLASHBUTTON = 2,
	TDP_FLASHBUTTONGROUPMENU = 3,
}


[AllowDuplicates]
public enum STARTPANELPARTS : int32
{
	SPP_USERPANE = 1,
	SPP_MOREPROGRAMS = 2,
	SPP_MOREPROGRAMSARROW = 3,
	SPP_PROGLIST = 4,
	SPP_PROGLISTSEPARATOR = 5,
	SPP_PLACESLIST = 6,
	SPP_PLACESLISTSEPARATOR = 7,
	SPP_LOGOFF = 8,
	SPP_LOGOFFBUTTONS = 9,
	SPP_USERPICTURE = 10,
	SPP_PREVIEW = 11,
	SPP_MOREPROGRAMSTAB = 12,
	SPP_NSCHOST = 13,
	SPP_SOFTWAREEXPLORER = 14,
	SPP_OPENBOX = 15,
	SPP_SEARCHVIEW = 16,
	SPP_MOREPROGRAMSARROWBACK = 17,
	SPP_TOPMATCH = 18,
	SPP_LOGOFFSPLITBUTTONDROPDOWN = 19,
}


[AllowDuplicates]
public enum MOREPROGRAMSTABSTATES : int32
{
	SPMPT_NORMAL = 1,
	SPMPT_HOT = 2,
	SPMPT_SELECTED = 3,
	SPMPT_DISABLED = 4,
	SPMPT_FOCUSED = 5,
}


[AllowDuplicates]
public enum SOFTWAREEXPLORERSTATES : int32
{
	SPSE_NORMAL = 1,
	SPSE_HOT = 2,
	SPSE_SELECTED = 3,
	SPSE_DISABLED = 4,
	SPSE_FOCUSED = 5,
}


[AllowDuplicates]
public enum OPENBOXSTATES : int32
{
	SPOB_NORMAL = 1,
	SPOB_HOT = 2,
	SPOB_SELECTED = 3,
	SPOB_DISABLED = 4,
	SPOB_FOCUSED = 5,
}


[AllowDuplicates]
public enum MOREPROGRAMSARROWSTATES : int32
{
	SPS_NORMAL = 1,
	SPS_HOT = 2,
	SPS_PRESSED = 3,
}


[AllowDuplicates]
public enum MOREPROGRAMSARROWBACKSTATES : int32
{
	SPSB_NORMAL = 1,
	SPSB_HOT = 2,
	SPSB_PRESSED = 3,
}


[AllowDuplicates]
public enum LOGOFFBUTTONSSTATES : int32
{
	SPLS_NORMAL = 1,
	SPLS_HOT = 2,
	SPLS_PRESSED = 3,
}


[AllowDuplicates]
public enum MENUBANDPARTS : int32
{
	MDP_NEWAPPBUTTON = 1,
	MDP_SEPERATOR = 2,
}


[AllowDuplicates]
public enum MENUBANDSTATES : int32
{
	MDS_NORMAL = 1,
	MDS_HOT = 2,
	MDS_PRESSED = 3,
	MDS_DISABLED = 4,
	MDS_CHECKED = 5,
	MDS_HOTCHECKED = 6,
}


[AllowDuplicates]
public enum POINTER_FEEDBACK_MODE : int32
{
	POINTER_FEEDBACK_DEFAULT = 1,
	POINTER_FEEDBACK_INDIRECT = 2,
	POINTER_FEEDBACK_NONE = 3,
}


[AllowDuplicates]
public enum FEEDBACK_TYPE : int32
{
	FEEDBACK_TOUCH_CONTACTVISUALIZATION = 1,
	FEEDBACK_PEN_BARRELVISUALIZATION = 2,
	FEEDBACK_PEN_TAP = 3,
	FEEDBACK_PEN_DOUBLETAP = 4,
	FEEDBACK_PEN_PRESSANDHOLD = 5,
	FEEDBACK_PEN_RIGHTTAP = 6,
	FEEDBACK_TOUCH_TAP = 7,
	FEEDBACK_TOUCH_DOUBLETAP = 8,
	FEEDBACK_TOUCH_PRESSANDHOLD = 9,
	FEEDBACK_TOUCH_RIGHTTAP = 10,
	FEEDBACK_GESTURE_PRESSANDTAP = 11,
	FEEDBACK_MAX = -1,
}


[AllowDuplicates]
public enum POINTER_DEVICE_TYPE : int32
{
	POINTER_DEVICE_TYPE_INTEGRATED_PEN = 1,
	POINTER_DEVICE_TYPE_EXTERNAL_PEN = 2,
	POINTER_DEVICE_TYPE_TOUCH = 3,
	POINTER_DEVICE_TYPE_TOUCH_PAD = 4,
	POINTER_DEVICE_TYPE_MAX = -1,
}


[AllowDuplicates]
public enum POINTER_DEVICE_CURSOR_TYPE : int32
{
	POINTER_DEVICE_CURSOR_TYPE_UNKNOWN = 0,
	POINTER_DEVICE_CURSOR_TYPE_TIP = 1,
	POINTER_DEVICE_CURSOR_TYPE_ERASER = 2,
	POINTER_DEVICE_CURSOR_TYPE_MAX = -1,
}

#endregion

#region Function Pointers
public function uint32 LPFNPSPCALLBACKA(HWND hwnd, PSPCB_MESSAGE uMsg, PROPSHEETPAGEA* ppsp);

public function uint32 LPFNPSPCALLBACKW(HWND hwnd, PSPCB_MESSAGE uMsg, PROPSHEETPAGEW* ppsp);

public function int32 PFNPROPSHEETCALLBACK(HWND param0, uint32 param1, LPARAM param2);

public function BOOL LPFNSVADDPROPSHEETPAGE(HPROPSHEETPAGE param0, LPARAM param1);

public function BOOL LPFNADDPROPSHEETPAGES(void* param0, LPFNSVADDPROPSHEETPAGE param1, LPARAM param2);

public function int32 PFNLVCOMPARE(LPARAM param0, LPARAM param1, LPARAM param2);

public function int32 PFNLVGROUPCOMPARE(int32 param0, int32 param1, void* param2);

public function int32 PFNTVCOMPARE(LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort);

public function HRESULT PFTASKDIALOGCALLBACK(HWND hwnd, uint32 msg, WPARAM wParam, LPARAM lParam, int lpRefData);

public function int32 PFNDAENUMCALLBACK(void* p, void* pData);

public function int32 PFNDAENUMCALLBACKCONST(void* p, void* pData);

public function int32 PFNDACOMPARE(void* p1, void* p2, LPARAM lParam);

public function int32 PFNDACOMPARECONST(void* p1, void* p2, LPARAM lParam);

public function HRESULT PFNDPASTREAM(DPASTREAMINFO* pinfo, IStream* pstream, void* pvInstData);

public function void* PFNDPAMERGE(DPAMM_MESSAGE uMsg, void* pvDest, void* pvSrc, LPARAM lParam);

public function void* PFNDPAMERGECONST(DPAMM_MESSAGE uMsg, void* pvDest, void* pvSrc, LPARAM lParam);

public function int32 DTT_CALLBACK_PROC(HDC hdc, char16* pszText, int32 cchText, RECT* prc, uint32 dwFlags, LPARAM lParam);

public function BOOL LPFNCCSTYLEA(HWND hwndParent, CCSTYLEA* pccs);

public function BOOL LPFNCCSTYLEW(HWND hwndParent, CCSTYLEW* pccs);

public function int32 LPFNCCSIZETOTEXTA(uint32 flStyle, uint32 flExtStyle, HFONT hfont, PSTR pszText);

public function int32 LPFNCCSIZETOTEXTW(uint32 flStyle, uint32 flExtStyle, HFONT hfont, PWSTR pszText);

public function uint32 LPFNCCINFOA(CCINFOA* acci);

public function uint32 LPFNCCINFOW(CCINFOW* acci);

public function int32 EDITWORDBREAKPROCA(PSTR lpch, int32 ichCurrent, int32 cch, WORD_BREAK_ACTION code);

public function int32 EDITWORDBREAKPROCW(PWSTR lpch, int32 ichCurrent, int32 cch, WORD_BREAK_ACTION code);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct TBBUTTON
{
	public int32 iBitmap;
	public int32 idCommand;
	public uint8 fsState;
	public uint8 fsStyle;
	public uint8[6] bReserved;
	public uint dwData;
	public int iString;
}
#endif

[CRepr]
public struct PROPSHEETPAGEA_V1
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PSTR pszIcon;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKA pfnCallback;
	public uint32* pcRefParent;
}

[CRepr]
public struct PROPSHEETPAGEA_V2
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PSTR pszIcon;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKA pfnCallback;
	public uint32* pcRefParent;
	public PSTR pszHeaderTitle;
	public PSTR pszHeaderSubTitle;
}

[CRepr]
public struct PROPSHEETPAGEA_V3
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PSTR pszIcon;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKA pfnCallback;
	public uint32* pcRefParent;
	public PSTR pszHeaderTitle;
	public PSTR pszHeaderSubTitle;
	public HANDLE hActCtx;
}

[CRepr]
public struct PROPSHEETPAGEA
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PSTR pszIcon;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public HBITMAP hbmHeader;
		public PSTR pszbmHeader;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKA pfnCallback;
	public uint32* pcRefParent;
	public PSTR pszHeaderTitle;
	public PSTR pszHeaderSubTitle;
	public HANDLE hActCtx;
	public using _Anonymous3_e__Union Anonymous3;
}

[CRepr]
public struct PROPSHEETPAGEW_V1
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PWSTR pszIcon;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKW pfnCallback;
	public uint32* pcRefParent;
}

[CRepr]
public struct PROPSHEETPAGEW_V2
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PWSTR pszIcon;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKW pfnCallback;
	public uint32* pcRefParent;
	public PWSTR pszHeaderTitle;
	public PWSTR pszHeaderSubTitle;
}

[CRepr]
public struct PROPSHEETPAGEW_V3
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PWSTR pszIcon;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKW pfnCallback;
	public uint32* pcRefParent;
	public PWSTR pszHeaderTitle;
	public PWSTR pszHeaderSubTitle;
	public HANDLE hActCtx;
}

[CRepr]
public struct PROPSHEETPAGEW
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public HBITMAP hbmHeader;
		public PWSTR pszbmHeader;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pszTemplate;
		public DLGTEMPLATE* pResource;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public HICON hIcon;
		public PWSTR pszIcon;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR pszTitle;
	public DLGPROC pfnDlgProc;
	public LPARAM lParam;
	public LPFNPSPCALLBACKW pfnCallback;
	public uint32* pcRefParent;
	public PWSTR pszHeaderTitle;
	public PWSTR pszHeaderSubTitle;
	public HANDLE hActCtx;
	public using _Anonymous3_e__Union Anonymous3;
}

[CRepr]
public struct PROPSHEETHEADERA_V1
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 nStartPage;
		public PSTR pStartPage;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public PROPSHEETPAGEA* ppsp;
		public HPROPSHEETPAGE* phpage;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public HICON hIcon;
		public PSTR pszIcon;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public PSTR pszCaption;
	public uint32 nPages;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public PFNPROPSHEETCALLBACK pfnCallback;
}

[CRepr]
public struct PROPSHEETHEADERA_V2
{
	[CRepr, Union]
	public struct _Anonymous5_e__Union
	{
		public HBITMAP hbmHeader;
		public PSTR pszbmHeader;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public PROPSHEETPAGEA* ppsp;
		public HPROPSHEETPAGE* phpage;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public HICON hIcon;
		public PSTR pszIcon;
	}
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		public HBITMAP hbmWatermark;
		public PSTR pszbmWatermark;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 nStartPage;
		public PSTR pStartPage;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public PSTR pszCaption;
	public uint32 nPages;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public PFNPROPSHEETCALLBACK pfnCallback;
	public using _Anonymous4_e__Union Anonymous4;
	public HPALETTE hplWatermark;
	public using _Anonymous5_e__Union Anonymous5;
}

[CRepr]
public struct PROPSHEETHEADERW_V1
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 nStartPage;
		public PWSTR pStartPage;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public PROPSHEETPAGEW* ppsp;
		public HPROPSHEETPAGE* phpage;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public HICON hIcon;
		public PWSTR pszIcon;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public PWSTR pszCaption;
	public uint32 nPages;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public PFNPROPSHEETCALLBACK pfnCallback;
}

[CRepr]
public struct PROPSHEETHEADERW_V2
{
	[CRepr, Union]
	public struct _Anonymous5_e__Union
	{
		public HBITMAP hbmHeader;
		public PWSTR pszbmHeader;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public PROPSHEETPAGEW* ppsp;
		public HPROPSHEETPAGE* phpage;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public HICON hIcon;
		public PWSTR pszIcon;
	}
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		public HBITMAP hbmWatermark;
		public PWSTR pszbmWatermark;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 nStartPage;
		public PWSTR pStartPage;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public using _Anonymous1_e__Union Anonymous1;
	public PWSTR pszCaption;
	public uint32 nPages;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public PFNPROPSHEETCALLBACK pfnCallback;
	public using _Anonymous4_e__Union Anonymous4;
	public HPALETTE hplWatermark;
	public using _Anonymous5_e__Union Anonymous5;
}

[CRepr]
public struct PSHNOTIFY
{
	public NMHDR hdr;
	public LPARAM lParam;
}

[CRepr]
public struct INITCOMMONCONTROLSEX
{
	public uint32 dwSize;
	public INITCOMMONCONTROLSEX_ICC dwICC;
}

[CRepr]
public struct COLORSCHEME
{
	public uint32 dwSize;
	public COLORREF clrBtnHighlight;
	public COLORREF clrBtnShadow;
}

[CRepr]
public struct NMTOOLTIPSCREATED
{
	public NMHDR hdr;
	public HWND hwndToolTips;
}

[CRepr]
public struct NMMOUSE
{
	public NMHDR hdr;
	public uint dwItemSpec;
	public uint dwItemData;
	public POINT pt;
	public LPARAM dwHitInfo;
}

[CRepr]
public struct NMOBJECTNOTIFY
{
	public NMHDR hdr;
	public int32 iItem;
	public Guid* piid;
	public void* pObject;
	public HRESULT hResult;
	public uint32 dwFlags;
}

[CRepr]
public struct NMKEY
{
	public NMHDR hdr;
	public uint32 nVKey;
	public uint32 uFlags;
}

[CRepr]
public struct NMCHAR
{
	public NMHDR hdr;
	public uint32 ch;
	public uint32 dwItemPrev;
	public uint32 dwItemNext;
}

[CRepr]
public struct NMCUSTOMTEXT
{
	public NMHDR hdr;
	public HDC hDC;
	public PWSTR lpString;
	public int32 nCount;
	public RECT* lpRect;
	public uint32 uFormat;
	public BOOL fLink;
}

[CRepr]
public struct NMCUSTOMDRAW
{
	public NMHDR hdr;
	public NMCUSTOMDRAW_DRAW_STAGE dwDrawStage;
	public HDC hdc;
	public RECT rc;
	public uint dwItemSpec;
	public NMCUSTOMDRAW_DRAW_STATE_FLAGS uItemState;
	public LPARAM lItemlParam;
}

[CRepr]
public struct NMTTCUSTOMDRAW
{
	public NMCUSTOMDRAW nmcd;
	public uint32 uDrawFlags;
}

[CRepr]
public struct NMCUSTOMSPLITRECTINFO
{
	public NMHDR hdr;
	public RECT rcClient;
	public RECT rcButton;
	public RECT rcSplit;
}

[CRepr]
public struct IMAGELISTDRAWPARAMS
{
	public uint32 cbSize;
	public HIMAGELIST himl;
	public int32 i;
	public HDC hdcDst;
	public int32 x;
	public int32 y;
	public int32 cx;
	public int32 cy;
	public int32 xBitmap;
	public int32 yBitmap;
	public COLORREF rgbBk;
	public COLORREF rgbFg;
	public uint32 fStyle;
	public uint32 dwRop;
	public uint32 fState;
	public uint32 Frame;
	public COLORREF crEffect;
}

[CRepr]
public struct IMAGEINFO
{
	public HBITMAP hbmImage;
	public HBITMAP hbmMask;
	public int32 Unused1;
	public int32 Unused2;
	public RECT rcImage;
}

[CRepr]
public struct HD_TEXTFILTERA
{
	public PSTR pszText;
	public int32 cchTextMax;
}

[CRepr]
public struct HD_TEXTFILTERW
{
	public PWSTR pszText;
	public int32 cchTextMax;
}

[CRepr]
public struct HDITEMA
{
	public HDI_MASK mask;
	public int32 cxy;
	public PSTR pszText;
	public HBITMAP hbm;
	public int32 cchTextMax;
	public HEADER_CONTROL_FORMAT_FLAGS fmt;
	public LPARAM lParam;
	public int32 iImage;
	public int32 iOrder;
	public HEADER_CONTROL_FORMAT_TYPE type;
	public void* pvFilter;
	public HEADER_CONTROL_FORMAT_STATE state;
}

[CRepr]
public struct HDITEMW
{
	public HDI_MASK mask;
	public int32 cxy;
	public PWSTR pszText;
	public HBITMAP hbm;
	public int32 cchTextMax;
	public HEADER_CONTROL_FORMAT_FLAGS fmt;
	public LPARAM lParam;
	public int32 iImage;
	public int32 iOrder;
	public HEADER_CONTROL_FORMAT_TYPE type;
	public void* pvFilter;
	public HEADER_CONTROL_FORMAT_STATE state;
}

[CRepr]
public struct HDLAYOUT
{
	public RECT* prc;
	public WINDOWPOS* pwpos;
}

[CRepr]
public struct HDHITTESTINFO
{
	public POINT pt;
	public HEADER_HITTEST_INFO_FLAGS flags;
	public int32 iItem;
}

[CRepr]
public struct NMHEADERA
{
	public NMHDR hdr;
	public int32 iItem;
	public HEADER_CONTROL_NOTIFICATION_BUTTON iButton;
	public HDITEMA* pitem;
}

[CRepr]
public struct NMHEADERW
{
	public NMHDR hdr;
	public int32 iItem;
	public HEADER_CONTROL_NOTIFICATION_BUTTON iButton;
	public HDITEMW* pitem;
}

[CRepr]
public struct NMHDDISPINFOW
{
	public NMHDR hdr;
	public int32 iItem;
	public HDI_MASK mask;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public LPARAM lParam;
}

[CRepr]
public struct NMHDDISPINFOA
{
	public NMHDR hdr;
	public int32 iItem;
	public HDI_MASK mask;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public LPARAM lParam;
}

[CRepr]
public struct NMHDFILTERBTNCLICK
{
	public NMHDR hdr;
	public int32 iItem;
	public RECT rc;
}

#if BF_32_BIT
[CRepr]
public struct TBBUTTON
{
	public int32 iBitmap;
	public int32 idCommand;
	public uint8 fsState;
	public uint8 fsStyle;
	public uint8[2] bReserved;
	public uint dwData;
	public int iString;
}
#endif

[CRepr]
public struct COLORMAP
{
	public COLORREF from;
	public COLORREF to;
}

[CRepr]
public struct NMTBCUSTOMDRAW
{
	public NMCUSTOMDRAW nmcd;
	public HBRUSH hbrMonoDither;
	public HBRUSH hbrLines;
	public HPEN hpenLines;
	public COLORREF clrText;
	public COLORREF clrMark;
	public COLORREF clrTextHighlight;
	public COLORREF clrBtnFace;
	public COLORREF clrBtnHighlight;
	public COLORREF clrHighlightHotTrack;
	public RECT rcText;
	public int32 nStringBkMode;
	public int32 nHLStringBkMode;
	public int32 iListGap;
}

[CRepr]
public struct TBADDBITMAP
{
	public HINSTANCE hInst;
	public uint nID;
}

[CRepr]
public struct TBSAVEPARAMSA
{
	public HKEY hkr;
	public PSTR pszSubKey;
	public PSTR pszValueName;
}

[CRepr]
public struct TBSAVEPARAMSW
{
	public HKEY hkr;
	public PWSTR pszSubKey;
	public PWSTR pszValueName;
}

[CRepr]
public struct TBINSERTMARK
{
	public int32 iButton;
	public TBINSERTMARK_FLAGS dwFlags;
}

[CRepr]
public struct TBREPLACEBITMAP
{
	public HINSTANCE hInstOld;
	public uint nIDOld;
	public HINSTANCE hInstNew;
	public uint nIDNew;
	public int32 nButtons;
}

[CRepr]
public struct TBBUTTONINFOA
{
	public uint32 cbSize;
	public TBBUTTONINFOW_MASK dwMask;
	public int32 idCommand;
	public int32 iImage;
	public uint8 fsState;
	public uint8 fsStyle;
	public uint16 cx;
	public uint lParam;
	public PSTR pszText;
	public int32 cchText;
}

[CRepr]
public struct TBBUTTONINFOW
{
	public uint32 cbSize;
	public TBBUTTONINFOW_MASK dwMask;
	public int32 idCommand;
	public int32 iImage;
	public uint8 fsState;
	public uint8 fsStyle;
	public uint16 cx;
	public uint lParam;
	public PWSTR pszText;
	public int32 cchText;
}

[CRepr]
public struct TBMETRICS
{
	public uint32 cbSize;
	public uint32 dwMask;
	public int32 cxPad;
	public int32 cyPad;
	public int32 cxBarPad;
	public int32 cyBarPad;
	public int32 cxButtonSpacing;
	public int32 cyButtonSpacing;
}

[CRepr]
public struct NMTBHOTITEM
{
	public NMHDR hdr;
	public int32 idOld;
	public int32 idNew;
	public NMTBHOTITEM_FLAGS dwFlags;
}

[CRepr]
public struct NMTBSAVE
{
	public NMHDR hdr;
	public uint32* pData;
	public uint32* pCurrent;
	public uint32 cbData;
	public int32 iItem;
	public int32 cButtons;
	public TBBUTTON tbButton;
}

[CRepr]
public struct NMTBRESTORE
{
	public NMHDR hdr;
	public uint32* pData;
	public uint32* pCurrent;
	public uint32 cbData;
	public int32 iItem;
	public int32 cButtons;
	public int32 cbBytesPerRecord;
	public TBBUTTON tbButton;
}

[CRepr]
public struct NMTBGETINFOTIPA
{
	public NMHDR hdr;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iItem;
	public LPARAM lParam;
}

[CRepr]
public struct NMTBGETINFOTIPW
{
	public NMHDR hdr;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iItem;
	public LPARAM lParam;
}

[CRepr]
public struct NMTBDISPINFOA
{
	public NMHDR hdr;
	public NMTBDISPINFOW_MASK dwMask;
	public int32 idCommand;
	public uint lParam;
	public int32 iImage;
	public PSTR pszText;
	public int32 cchText;
}

[CRepr]
public struct NMTBDISPINFOW
{
	public NMHDR hdr;
	public NMTBDISPINFOW_MASK dwMask;
	public int32 idCommand;
	public uint lParam;
	public int32 iImage;
	public PWSTR pszText;
	public int32 cchText;
}

[CRepr]
public struct NMTOOLBARA
{
	public NMHDR hdr;
	public int32 iItem;
	public TBBUTTON tbButton;
	public int32 cchText;
	public PSTR pszText;
	public RECT rcButton;
}

[CRepr]
public struct NMTOOLBARW
{
	public NMHDR hdr;
	public int32 iItem;
	public TBBUTTON tbButton;
	public int32 cchText;
	public PWSTR pszText;
	public RECT rcButton;
}

[CRepr]
public struct REBARINFO
{
	public uint32 cbSize;
	public uint32 fMask;
	public HIMAGELIST himl;
}

[CRepr]
public struct REBARBANDINFOA
{
	public uint32 cbSize;
	public uint32 fMask;
	public uint32 fStyle;
	public COLORREF clrFore;
	public COLORREF clrBack;
	public PSTR lpText;
	public uint32 cch;
	public int32 iImage;
	public HWND hwndChild;
	public uint32 cxMinChild;
	public uint32 cyMinChild;
	public uint32 cx;
	public HBITMAP hbmBack;
	public uint32 wID;
	public uint32 cyChild;
	public uint32 cyMaxChild;
	public uint32 cyIntegral;
	public uint32 cxIdeal;
	public LPARAM lParam;
	public uint32 cxHeader;
	public RECT rcChevronLocation;
	public uint32 uChevronState;
}

[CRepr]
public struct REBARBANDINFOW
{
	public uint32 cbSize;
	public uint32 fMask;
	public uint32 fStyle;
	public COLORREF clrFore;
	public COLORREF clrBack;
	public PWSTR lpText;
	public uint32 cch;
	public int32 iImage;
	public HWND hwndChild;
	public uint32 cxMinChild;
	public uint32 cyMinChild;
	public uint32 cx;
	public HBITMAP hbmBack;
	public uint32 wID;
	public uint32 cyChild;
	public uint32 cyMaxChild;
	public uint32 cyIntegral;
	public uint32 cxIdeal;
	public LPARAM lParam;
	public uint32 cxHeader;
	public RECT rcChevronLocation;
	public uint32 uChevronState;
}

[CRepr]
public struct NMREBARCHILDSIZE
{
	public NMHDR hdr;
	public uint32 uBand;
	public uint32 wID;
	public RECT rcChild;
	public RECT rcBand;
}

[CRepr]
public struct NMREBAR
{
	public NMHDR hdr;
	public NMREBAR_MASK_FLAGS dwMask;
	public uint32 uBand;
	public uint32 fStyle;
	public uint32 wID;
	public LPARAM lParam;
}

[CRepr]
public struct NMRBAUTOSIZE
{
	public NMHDR hdr;
	public BOOL fChanged;
	public RECT rcTarget;
	public RECT rcActual;
}

[CRepr]
public struct NMREBARCHEVRON
{
	public NMHDR hdr;
	public uint32 uBand;
	public uint32 wID;
	public LPARAM lParam;
	public RECT rc;
	public LPARAM lParamNM;
}

[CRepr]
public struct NMREBARSPLITTER
{
	public NMHDR hdr;
	public RECT rcSizing;
}

[CRepr]
public struct NMREBARAUTOBREAK
{
	public NMHDR hdr;
	public uint32 uBand;
	public uint32 wID;
	public LPARAM lParam;
	public uint32 uMsg;
	public uint32 fStyleCurrent;
	public BOOL fAutoBreak;
}

[CRepr]
public struct RBHITTESTINFO
{
	public POINT pt;
	public uint32 flags;
	public int32 iBand;
}

[CRepr]
public struct TTTOOLINFOA
{
	public uint32 cbSize;
	public TOOLTIP_FLAGS uFlags;
	public HWND hwnd;
	public uint uId;
	public RECT rect;
	public HINSTANCE hinst;
	public PSTR lpszText;
	public LPARAM lParam;
	public void* lpReserved;
}

[CRepr]
public struct TTTOOLINFOW
{
	public uint32 cbSize;
	public TOOLTIP_FLAGS uFlags;
	public HWND hwnd;
	public uint uId;
	public RECT rect;
	public HINSTANCE hinst;
	public PWSTR lpszText;
	public LPARAM lParam;
	public void* lpReserved;
}

[CRepr]
public struct TTGETTITLE
{
	public uint32 dwSize;
	public uint32 uTitleBitmap;
	public uint32 cch;
	public PWSTR pszTitle;
}

[CRepr]
public struct TTHITTESTINFOA
{
	public HWND hwnd;
	public POINT pt;
	public TTTOOLINFOA ti;
}

[CRepr]
public struct TTHITTESTINFOW
{
	public HWND hwnd;
	public POINT pt;
	public TTTOOLINFOW ti;
}

[CRepr]
public struct NMTTDISPINFOA
{
	public NMHDR hdr;
	public PSTR lpszText;
	public CHAR[80] szText;
	public HINSTANCE hinst;
	public TOOLTIP_FLAGS uFlags;
	public LPARAM lParam;
}

[CRepr]
public struct NMTTDISPINFOW
{
	public NMHDR hdr;
	public PWSTR lpszText;
	public char16[80] szText;
	public HINSTANCE hinst;
	public TOOLTIP_FLAGS uFlags;
	public LPARAM lParam;
}

[CRepr]
public struct NMTRBTHUMBPOSCHANGING
{
	public NMHDR hdr;
	public uint32 dwPos;
	public int32 nReason;
}

[CRepr]
public struct DRAGLISTINFO
{
	public DRAGLISTINFO_NOTIFICATION_FLAGS uNotification;
	public HWND hWnd;
	public POINT ptCursor;
}

[CRepr]
public struct UDACCEL
{
	public uint32 nSec;
	public uint32 nInc;
}

[CRepr]
public struct NMUPDOWN
{
	public NMHDR hdr;
	public int32 iPos;
	public int32 iDelta;
}

[CRepr]
public struct PBRANGE
{
	public int32 iLow;
	public int32 iHigh;
}

[CRepr]
public struct LITEM
{
	public LIST_ITEM_FLAGS mask;
	public int32 iLink;
	public LIST_ITEM_STATE_FLAGS state;
	public LIST_ITEM_STATE_FLAGS stateMask;
	public char16[48] szID;
	public char16[2084] szUrl;
}

[CRepr]
public struct LHITTESTINFO
{
	public POINT pt;
	public LITEM item;
}

[CRepr]
public struct NMLINK
{
	public NMHDR hdr;
	public LITEM item;
}

[CRepr]
public struct LVITEMA
{
	public LIST_VIEW_ITEM_FLAGS mask;
	public int32 iItem;
	public int32 iSubItem;
	public LIST_VIEW_ITEM_STATE_FLAGS state;
	public LIST_VIEW_ITEM_STATE_FLAGS stateMask;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public LPARAM lParam;
	public int32 iIndent;
	public LVITEMA_GROUP_ID iGroupId;
	public uint32 cColumns;
	public uint32* puColumns;
	public LIST_VIEW_ITEM_COLUMN_FORMAT_FLAGS* piColFmt;
	public int32 iGroup;
}

[CRepr]
public struct LVITEMW
{
	public LIST_VIEW_ITEM_FLAGS mask;
	public int32 iItem;
	public int32 iSubItem;
	public LIST_VIEW_ITEM_STATE_FLAGS state;
	public LIST_VIEW_ITEM_STATE_FLAGS stateMask;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public LPARAM lParam;
	public int32 iIndent;
	public LVITEMA_GROUP_ID iGroupId;
	public uint32 cColumns;
	public uint32* puColumns;
	public LIST_VIEW_ITEM_COLUMN_FORMAT_FLAGS* piColFmt;
	public int32 iGroup;
}

[CRepr]
public struct LVFINDINFOA
{
	public LVFINDINFOW_FLAGS flags;
	public PSTR psz;
	public LPARAM lParam;
	public POINT pt;
	public uint32 vkDirection;
}

[CRepr]
public struct LVFINDINFOW
{
	public LVFINDINFOW_FLAGS flags;
	public PWSTR psz;
	public LPARAM lParam;
	public POINT pt;
	public uint32 vkDirection;
}

[CRepr]
public struct LVHITTESTINFO
{
	public POINT pt;
	public LVHITTESTINFO_FLAGS flags;
	public int32 iItem;
	public int32 iSubItem;
	public int32 iGroup;
}

[CRepr]
public struct LVCOLUMNA
{
	public LVCOLUMNW_MASK mask;
	public LVCOLUMNW_FORMAT fmt;
	public int32 cx;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iSubItem;
	public int32 iImage;
	public int32 iOrder;
	public int32 cxMin;
	public int32 cxDefault;
	public int32 cxIdeal;
}

[CRepr]
public struct LVCOLUMNW
{
	public LVCOLUMNW_MASK mask;
	public LVCOLUMNW_FORMAT fmt;
	public int32 cx;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iSubItem;
	public int32 iImage;
	public int32 iOrder;
	public int32 cxMin;
	public int32 cxDefault;
	public int32 cxIdeal;
}

[CRepr]
public struct LVBKIMAGEA
{
	public LIST_VIEW_BACKGROUND_IMAGE_FLAGS ulFlags;
	public HBITMAP hbm;
	public PSTR pszImage;
	public uint32 cchImageMax;
	public int32 xOffsetPercent;
	public int32 yOffsetPercent;
}

[CRepr]
public struct LVBKIMAGEW
{
	public LIST_VIEW_BACKGROUND_IMAGE_FLAGS ulFlags;
	public HBITMAP hbm;
	public PWSTR pszImage;
	public uint32 cchImageMax;
	public int32 xOffsetPercent;
	public int32 yOffsetPercent;
}

[CRepr]
public struct LVGROUP
{
	public uint32 cbSize;
	public LVGROUP_MASK mask;
	public PWSTR pszHeader;
	public int32 cchHeader;
	public PWSTR pszFooter;
	public int32 cchFooter;
	public int32 iGroupId;
	public LIST_VIEW_GROUP_STATE_FLAGS stateMask;
	public LIST_VIEW_GROUP_STATE_FLAGS state;
	public LIST_VIEW_GROUP_ALIGN_FLAGS uAlign;
	public PWSTR pszSubtitle;
	public uint32 cchSubtitle;
	public PWSTR pszTask;
	public uint32 cchTask;
	public PWSTR pszDescriptionTop;
	public uint32 cchDescriptionTop;
	public PWSTR pszDescriptionBottom;
	public uint32 cchDescriptionBottom;
	public int32 iTitleImage;
	public int32 iExtendedImage;
	public int32 iFirstItem;
	public uint32 cItems;
	public PWSTR pszSubsetTitle;
	public uint32 cchSubsetTitle;
}

[CRepr]
public struct LVGROUPMETRICS
{
	public uint32 cbSize;
	public uint32 mask;
	public uint32 Left;
	public uint32 Top;
	public uint32 Right;
	public uint32 Bottom;
	public COLORREF crLeft;
	public COLORREF crTop;
	public COLORREF crRight;
	public COLORREF crBottom;
	public COLORREF crHeader;
	public COLORREF crFooter;
}

[CRepr]
public struct LVINSERTGROUPSORTED
{
	public PFNLVGROUPCOMPARE pfnGroupCompare;
	public void* pvData;
	public LVGROUP lvGroup;
}

[CRepr]
public struct LVTILEVIEWINFO
{
	public uint32 cbSize;
	public LVTILEVIEWINFO_MASK dwMask;
	public LVTILEVIEWINFO_FLAGS dwFlags;
	public SIZE sizeTile;
	public int32 cLines;
	public RECT rcLabelMargin;
}

[CRepr]
public struct LVTILEINFO
{
	public uint32 cbSize;
	public int32 iItem;
	public uint32 cColumns;
	public uint32* puColumns;
	public int32* piColFmt;
}

[CRepr]
public struct LVINSERTMARK
{
	public uint32 cbSize;
	public LIST_VIEW_INSERT_MARK_FLAGS dwFlags;
	public int32 iItem;
	public uint32 dwReserved;
}

[CRepr]
public struct LVSETINFOTIP
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public PWSTR pszText;
	public int32 iItem;
	public int32 iSubItem;
}

[CRepr]
public struct LVFOOTERINFO
{
	public uint32 mask;
	public PWSTR pszText;
	public int32 cchTextMax;
	public uint32 cItems;
}

[CRepr]
public struct LVFOOTERITEM
{
	public LVFOOTERITEM_MASK mask;
	public int32 iItem;
	public PWSTR pszText;
	public int32 cchTextMax;
	public uint32 state;
	public uint32 stateMask;
}

[CRepr]
public struct LVITEMINDEX
{
	public int32 iItem;
	public int32 iGroup;
}

[CRepr]
public struct NMLISTVIEW
{
	public NMHDR hdr;
	public int32 iItem;
	public int32 iSubItem;
	public uint32 uNewState;
	public uint32 uOldState;
	public LIST_VIEW_ITEM_FLAGS uChanged;
	public POINT ptAction;
	public LPARAM lParam;
}

[CRepr]
public struct NMITEMACTIVATE
{
	public NMHDR hdr;
	public int32 iItem;
	public int32 iSubItem;
	public uint32 uNewState;
	public uint32 uOldState;
	public uint32 uChanged;
	public POINT ptAction;
	public LPARAM lParam;
	public uint32 uKeyFlags;
}

[CRepr]
public struct NMLVCUSTOMDRAW
{
	public NMCUSTOMDRAW nmcd;
	public COLORREF clrText;
	public COLORREF clrTextBk;
	public int32 iSubItem;
	public NMLVCUSTOMDRAW_ITEM_TYPE dwItemType;
	public COLORREF clrFace;
	public int32 iIconEffect;
	public int32 iIconPhase;
	public int32 iPartId;
	public int32 iStateId;
	public RECT rcText;
	public LIST_VIEW_GROUP_ALIGN_FLAGS uAlign;
}

[CRepr]
public struct NMLVCACHEHINT
{
	public NMHDR hdr;
	public int32 iFrom;
	public int32 iTo;
}

[CRepr]
public struct NMLVFINDITEMA
{
	public NMHDR hdr;
	public int32 iStart;
	public LVFINDINFOA lvfi;
}

[CRepr]
public struct NMLVFINDITEMW
{
	public NMHDR hdr;
	public int32 iStart;
	public LVFINDINFOW lvfi;
}

[CRepr]
public struct NMLVODSTATECHANGE
{
	public NMHDR hdr;
	public int32 iFrom;
	public int32 iTo;
	public LIST_VIEW_ITEM_STATE_FLAGS uNewState;
	public LIST_VIEW_ITEM_STATE_FLAGS uOldState;
}

[CRepr]
public struct NMLVDISPINFOA
{
	public NMHDR hdr;
	public LVITEMA item;
}

[CRepr]
public struct NMLVDISPINFOW
{
	public NMHDR hdr;
	public LVITEMW item;
}

[CRepr, Packed(1)]
public struct NMLVKEYDOWN
{
	public NMHDR hdr;
	public uint16 wVKey;
	public uint32 flags;
}

[CRepr]
public struct NMLVLINK
{
	public NMHDR hdr;
	public LITEM link;
	public int32 iItem;
	public int32 iSubItem;
}

[CRepr]
public struct NMLVGETINFOTIPA
{
	public NMHDR hdr;
	public NMLVGETINFOTIP_FLAGS dwFlags;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iItem;
	public int32 iSubItem;
	public LPARAM lParam;
}

[CRepr]
public struct NMLVGETINFOTIPW
{
	public NMHDR hdr;
	public NMLVGETINFOTIP_FLAGS dwFlags;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iItem;
	public int32 iSubItem;
	public LPARAM lParam;
}

[CRepr]
public struct NMLVSCROLL
{
	public NMHDR hdr;
	public int32 dx;
	public int32 dy;
}

[CRepr]
public struct NMLVEMPTYMARKUP
{
	public NMHDR hdr;
	public NMLVEMPTYMARKUP_FLAGS dwFlags;
	public char16[2084] szMarkup;
}

[CRepr]
public struct NMTVSTATEIMAGECHANGING
{
	public NMHDR hdr;
	public HTREEITEM hti;
	public int32 iOldStateImageIndex;
	public int32 iNewStateImageIndex;
}

[CRepr]
public struct TVITEMA
{
	public TVITEM_MASK mask;
	public HTREEITEM hItem;
	public TREE_VIEW_ITEM_STATE_FLAGS state;
	public TREE_VIEW_ITEM_STATE_FLAGS stateMask;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public int32 iSelectedImage;
	public TVITEMEXW_CHILDREN cChildren;
	public LPARAM lParam;
}

[CRepr]
public struct TVITEMW
{
	public TVITEM_MASK mask;
	public HTREEITEM hItem;
	public TREE_VIEW_ITEM_STATE_FLAGS state;
	public TREE_VIEW_ITEM_STATE_FLAGS stateMask;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public int32 iSelectedImage;
	public TVITEMEXW_CHILDREN cChildren;
	public LPARAM lParam;
}

[CRepr]
public struct TVITEMEXA
{
	public TVITEM_MASK mask;
	public HTREEITEM hItem;
	public uint32 state;
	public uint32 stateMask;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public int32 iSelectedImage;
	public TVITEMEXW_CHILDREN cChildren;
	public LPARAM lParam;
	public int32 iIntegral;
	public uint32 uStateEx;
	public HWND hwnd;
	public int32 iExpandedImage;
	public int32 iReserved;
}

[CRepr]
public struct TVITEMEXW
{
	public TVITEM_MASK mask;
	public HTREEITEM hItem;
	public uint32 state;
	public uint32 stateMask;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public int32 iSelectedImage;
	public TVITEMEXW_CHILDREN cChildren;
	public LPARAM lParam;
	public int32 iIntegral;
	public uint32 uStateEx;
	public HWND hwnd;
	public int32 iExpandedImage;
	public int32 iReserved;
}

[CRepr]
public struct TVINSERTSTRUCTA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public TVITEMEXA itemex;
		public TVITEMA item;
	}
	public HTREEITEM hParent;
	public HTREEITEM hInsertAfter;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TVINSERTSTRUCTW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public TVITEMEXW itemex;
		public TVITEMW item;
	}
	public HTREEITEM hParent;
	public HTREEITEM hInsertAfter;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TVHITTESTINFO
{
	public POINT pt;
	public TVHITTESTINFO_FLAGS flags;
	public HTREEITEM hItem;
}

[CRepr]
public struct TVGETITEMPARTRECTINFO
{
	public HTREEITEM hti;
	public RECT* prc;
	public TVITEMPART partID;
}

[CRepr]
public struct TVSORTCB
{
	public HTREEITEM hParent;
	public PFNTVCOMPARE lpfnCompare;
	public LPARAM lParam;
}

[CRepr]
public struct NMTREEVIEWA
{
	public NMHDR hdr;
	public NM_TREEVIEW_ACTION action;
	public TVITEMA itemOld;
	public TVITEMA itemNew;
	public POINT ptDrag;
}

[CRepr]
public struct NMTREEVIEWW
{
	public NMHDR hdr;
	public NM_TREEVIEW_ACTION action;
	public TVITEMW itemOld;
	public TVITEMW itemNew;
	public POINT ptDrag;
}

[CRepr]
public struct NMTVDISPINFOA
{
	public NMHDR hdr;
	public TVITEMA item;
}

[CRepr]
public struct NMTVDISPINFOW
{
	public NMHDR hdr;
	public TVITEMW item;
}

[CRepr]
public struct NMTVDISPINFOEXA
{
	public NMHDR hdr;
	public TVITEMEXA item;
}

[CRepr]
public struct NMTVDISPINFOEXW
{
	public NMHDR hdr;
	public TVITEMEXW item;
}

[CRepr, Packed(1)]
public struct NMTVKEYDOWN
{
	public NMHDR hdr;
	public uint16 wVKey;
	public uint32 flags;
}

[CRepr]
public struct NMTVCUSTOMDRAW
{
	public NMCUSTOMDRAW nmcd;
	public COLORREF clrText;
	public COLORREF clrTextBk;
	public int32 iLevel;
}

[CRepr]
public struct NMTVGETINFOTIPA
{
	public NMHDR hdr;
	public PSTR pszText;
	public int32 cchTextMax;
	public HTREEITEM hItem;
	public LPARAM lParam;
}

[CRepr]
public struct NMTVGETINFOTIPW
{
	public NMHDR hdr;
	public PWSTR pszText;
	public int32 cchTextMax;
	public HTREEITEM hItem;
	public LPARAM lParam;
}

[CRepr]
public struct NMTVITEMCHANGE
{
	public NMHDR hdr;
	public uint32 uChanged;
	public HTREEITEM hItem;
	public uint32 uStateNew;
	public uint32 uStateOld;
	public LPARAM lParam;
}

[CRepr]
public struct NMTVASYNCDRAW
{
	public NMHDR hdr;
	public IMAGELISTDRAWPARAMS* pimldp;
	public HRESULT hr;
	public HTREEITEM hItem;
	public LPARAM lParam;
	public uint32 dwRetFlags;
	public int32 iRetImageIndex;
}

[CRepr]
public struct COMBOBOXEXITEMA
{
	public COMBOBOX_EX_ITEM_FLAGS mask;
	public int iItem;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public int32 iSelectedImage;
	public int32 iOverlay;
	public int32 iIndent;
	public LPARAM lParam;
}

[CRepr]
public struct COMBOBOXEXITEMW
{
	public COMBOBOX_EX_ITEM_FLAGS mask;
	public int iItem;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public int32 iSelectedImage;
	public int32 iOverlay;
	public int32 iIndent;
	public LPARAM lParam;
}

[CRepr]
public struct NMCOMBOBOXEXA
{
	public NMHDR hdr;
	public COMBOBOXEXITEMA ceItem;
}

[CRepr]
public struct NMCOMBOBOXEXW
{
	public NMHDR hdr;
	public COMBOBOXEXITEMW ceItem;
}

[CRepr]
public struct NMCBEDRAGBEGINW
{
	public NMHDR hdr;
	public int32 iItemid;
	public char16[260] szText;
}

[CRepr]
public struct NMCBEDRAGBEGINA
{
	public NMHDR hdr;
	public int32 iItemid;
	public CHAR[260] szText;
}

[CRepr]
public struct NMCBEENDEDITW
{
	public NMHDR hdr;
	public BOOL fChanged;
	public int32 iNewSelection;
	public char16[260] szText;
	public int32 iWhy;
}

[CRepr]
public struct NMCBEENDEDITA
{
	public NMHDR hdr;
	public BOOL fChanged;
	public int32 iNewSelection;
	public CHAR[260] szText;
	public int32 iWhy;
}

[CRepr]
public struct TCITEMHEADERA
{
	public TCITEMHEADERA_MASK mask;
	public uint32 lpReserved1;
	public uint32 lpReserved2;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
}

[CRepr]
public struct TCITEMHEADERW
{
	public TCITEMHEADERA_MASK mask;
	public uint32 lpReserved1;
	public uint32 lpReserved2;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
}

[CRepr]
public struct TCITEMA
{
	public TCITEMHEADERA_MASK mask;
	public TAB_CONTROL_ITEM_STATE dwState;
	public TAB_CONTROL_ITEM_STATE dwStateMask;
	public PSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public LPARAM lParam;
}

[CRepr]
public struct TCITEMW
{
	public TCITEMHEADERA_MASK mask;
	public TAB_CONTROL_ITEM_STATE dwState;
	public TAB_CONTROL_ITEM_STATE dwStateMask;
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 iImage;
	public LPARAM lParam;
}

[CRepr]
public struct TCHITTESTINFO
{
	public POINT pt;
	public TCHITTESTINFO_FLAGS flags;
}

[CRepr, Packed(1)]
public struct NMTCKEYDOWN
{
	public NMHDR hdr;
	public uint16 wVKey;
	public uint32 flags;
}

[CRepr]
public struct MCHITTESTINFO
{
	public uint32 cbSize;
	public POINT pt;
	public MCHITTESTINFO_HIT_FLAGS uHit;
	public SYSTEMTIME st;
	public RECT rc;
	public int32 iOffset;
	public int32 iRow;
	public int32 iCol;
}

[CRepr]
public struct MCGRIDINFO
{
	public uint32 cbSize;
	public MCGRIDINFO_PART dwPart;
	public MCGRIDINFO_FLAGS dwFlags;
	public int32 iCalendar;
	public int32 iRow;
	public int32 iCol;
	public BOOL bSelected;
	public SYSTEMTIME stStart;
	public SYSTEMTIME stEnd;
	public RECT rc;
	public PWSTR pszName;
	public uint cchName;
}

[CRepr]
public struct NMSELCHANGE
{
	public NMHDR nmhdr;
	public SYSTEMTIME stSelStart;
	public SYSTEMTIME stSelEnd;
}

[CRepr]
public struct NMDAYSTATE
{
	public NMHDR nmhdr;
	public SYSTEMTIME stStart;
	public int32 cDayState;
	public uint32* prgDayState;
}

[CRepr]
public struct NMVIEWCHANGE
{
	public NMHDR nmhdr;
	public MONTH_CALDENDAR_MESSAGES_VIEW dwOldView;
	public MONTH_CALDENDAR_MESSAGES_VIEW dwNewView;
}

[CRepr]
public struct DATETIMEPICKERINFO
{
	public uint32 cbSize;
	public RECT rcCheck;
	public uint32 stateCheck;
	public RECT rcButton;
	public uint32 stateButton;
	public HWND hwndEdit;
	public HWND hwndUD;
	public HWND hwndDropDown;
}

[CRepr]
public struct NMDATETIMECHANGE
{
	public NMHDR nmhdr;
	public NMDATETIMECHANGE_FLAGS dwFlags;
	public SYSTEMTIME st;
}

[CRepr]
public struct NMDATETIMESTRINGA
{
	public NMHDR nmhdr;
	public PSTR pszUserString;
	public SYSTEMTIME st;
	public uint32 dwFlags;
}

[CRepr]
public struct NMDATETIMESTRINGW
{
	public NMHDR nmhdr;
	public PWSTR pszUserString;
	public SYSTEMTIME st;
	public uint32 dwFlags;
}

[CRepr]
public struct NMDATETIMEWMKEYDOWNA
{
	public NMHDR nmhdr;
	public int32 nVirtKey;
	public PSTR pszFormat;
	public SYSTEMTIME st;
}

[CRepr]
public struct NMDATETIMEWMKEYDOWNW
{
	public NMHDR nmhdr;
	public int32 nVirtKey;
	public PWSTR pszFormat;
	public SYSTEMTIME st;
}

[CRepr]
public struct NMDATETIMEFORMATA
{
	public NMHDR nmhdr;
	public PSTR pszFormat;
	public SYSTEMTIME st;
	public PSTR pszDisplay;
	public CHAR[64] szDisplay;
}

[CRepr]
public struct NMDATETIMEFORMATW
{
	public NMHDR nmhdr;
	public PWSTR pszFormat;
	public SYSTEMTIME st;
	public PWSTR pszDisplay;
	public char16[64] szDisplay;
}

[CRepr]
public struct NMDATETIMEFORMATQUERYA
{
	public NMHDR nmhdr;
	public PSTR pszFormat;
	public SIZE szMax;
}

[CRepr]
public struct NMDATETIMEFORMATQUERYW
{
	public NMHDR nmhdr;
	public PWSTR pszFormat;
	public SIZE szMax;
}

[CRepr]
public struct NMIPADDRESS
{
	public NMHDR hdr;
	public int32 iField;
	public int32 iValue;
}

[CRepr, Packed(1)]
public struct NMPGSCROLL
{
	public NMHDR hdr;
	public NMPGSCROLL_KEYS fwKeys;
	public RECT rcParent;
	public NMPGSCROLL_DIR iDir;
	public int32 iXpos;
	public int32 iYpos;
	public int32 iScroll;
}

[CRepr]
public struct NMPGCALCSIZE
{
	public NMHDR hdr;
	public NMPGCALCSIZE_FLAGS dwFlag;
	public int32 iWidth;
	public int32 iHeight;
}

[CRepr]
public struct NMPGHOTITEM
{
	public NMHDR hdr;
	public int32 idOld;
	public int32 idNew;
	public uint32 dwFlags;
}

[CRepr]
public struct BUTTON_IMAGELIST
{
	public HIMAGELIST himl;
	public RECT margin;
	public BUTTON_IMAGELIST_ALIGN uAlign;
}

[CRepr]
public struct NMBCHOTITEM
{
	public NMHDR hdr;
	public NMTBHOTITEM_FLAGS dwFlags;
}

[CRepr]
public struct BUTTON_SPLITINFO
{
	public uint32 mask;
	public HIMAGELIST himlGlyph;
	public uint32 uSplitStyle;
	public SIZE size;
}

[CRepr]
public struct NMBCDROPDOWN
{
	public NMHDR hdr;
	public RECT rcButton;
}

[CRepr]
public struct EDITBALLOONTIP
{
	public uint32 cbStruct;
	public PWSTR pszTitle;
	public PWSTR pszText;
	public EDITBALLOONTIP_ICON ttiIcon;
}

[CRepr]
public struct NMSEARCHWEB
{
	public NMHDR hdr;
	public EC_SEARCHWEB_ENTRYPOINT entrypoint;
	public BOOL hasQueryText;
	public BOOL invokeSucceeded;
}

[CRepr, Packed(1)]
public struct TASKDIALOG_BUTTON
{
	public int32 nButtonID;
	public PWSTR pszButtonText;
}

[CRepr, Packed(1)]
public struct TASKDIALOGCONFIG
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous2_e__Union
	{
		public HICON hFooterIcon;
		public PWSTR pszFooterIcon;
	}
	[CRepr, Union, Packed(1)]
	public struct _Anonymous1_e__Union
	{
		public HICON hMainIcon;
		public PWSTR pszMainIcon;
	}
	public uint32 cbSize;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public TASKDIALOG_FLAGS dwFlags;
	public TASKDIALOG_COMMON_BUTTON_FLAGS dwCommonButtons;
	public PWSTR pszWindowTitle;
	public using _Anonymous1_e__Union Anonymous1;
	public PWSTR pszMainInstruction;
	public PWSTR pszContent;
	public uint32 cButtons;
	public TASKDIALOG_BUTTON* pButtons;
	public int32 nDefaultButton;
	public uint32 cRadioButtons;
	public TASKDIALOG_BUTTON* pRadioButtons;
	public int32 nDefaultRadioButton;
	public PWSTR pszVerificationText;
	public PWSTR pszExpandedInformation;
	public PWSTR pszExpandedControlText;
	public PWSTR pszCollapsedControlText;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR pszFooter;
	public PFTASKDIALOGCALLBACK pfCallback;
	public int lpCallbackData;
	public uint32 cxWidth;
}

[CRepr]
public struct DPASTREAMINFO
{
	public int32 iPos;
	public void* pvItem;
}

[CRepr]
public struct IMAGELISTSTATS
{
	public uint32 cbSize;
	public int32 cAlloc;
	public int32 cUsed;
	public int32 cStandby;
}

[CRepr]
public struct TA_TRANSFORM
{
	public TA_TRANSFORM_TYPE eTransformType;
	public uint32 dwTimingFunctionId;
	public uint32 dwStartTime;
	public uint32 dwDurationTime;
	public TA_TRANSFORM_FLAG eFlags;
}

[CRepr]
public struct TA_TRANSFORM_2D
{
	public TA_TRANSFORM header;
	public float rX;
	public float rY;
	public float rInitialX;
	public float rInitialY;
	public float rOriginX;
	public float rOriginY;
}

[CRepr]
public struct TA_TRANSFORM_OPACITY
{
	public TA_TRANSFORM header;
	public float rOpacity;
	public float rInitialOpacity;
}

[CRepr]
public struct TA_TRANSFORM_CLIP
{
	public TA_TRANSFORM header;
	public float rLeft;
	public float rTop;
	public float rRight;
	public float rBottom;
	public float rInitialLeft;
	public float rInitialTop;
	public float rInitialRight;
	public float rInitialBottom;
}

[CRepr]
public struct TA_TIMINGFUNCTION
{
	public TA_TIMINGFUNCTION_TYPE eTimingFunctionType;
}

[CRepr]
public struct TA_CUBIC_BEZIER
{
	public TA_TIMINGFUNCTION header;
	public float rX0;
	public float rY0;
	public float rX1;
	public float rY1;
}

[CRepr]
public struct DTBGOPTS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public RECT rcClip;
}

[CRepr]
public struct MARGINS
{
	public int32 cxLeftWidth;
	public int32 cxRightWidth;
	public int32 cyTopHeight;
	public int32 cyBottomHeight;
}

[CRepr]
public struct INTLIST
{
	public int32 iValueCount;
	public int32[402] iValues;
}

[CRepr]
public struct WTA_OPTIONS
{
	public uint32 dwFlags;
	public uint32 dwMask;
}

[CRepr]
public struct DTTOPTS
{
	public uint32 dwSize;
	public DTTOPTS_FLAGS dwFlags;
	public COLORREF crText;
	public COLORREF crBorder;
	public COLORREF crShadow;
	public int32 iTextShadowType;
	public POINT ptShadowOffset;
	public int32 iBorderSize;
	public int32 iFontPropId;
	public int32 iColorPropId;
	public int32 iStateId;
	public BOOL fApplyOverlay;
	public int32 iGlowSize;
	public DTT_CALLBACK_PROC pfnDrawTextCallback;
	public LPARAM lParam;
}

[CRepr]
public struct BP_ANIMATIONPARAMS
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public BP_ANIMATIONSTYLE style;
	public uint32 dwDuration;
}

[CRepr]
public struct BP_PAINTPARAMS
{
	public uint32 cbSize;
	public BP_PAINTPARAMS_FLAGS dwFlags;
	public RECT* prcExclude;
	public BLENDFUNCTION* pBlendFunction;
}

[CRepr]
public struct CCSTYLEA
{
	public uint32 flStyle;
	public uint32 flExtStyle;
	public CHAR[256] szText;
	public uint16 lgid;
	public uint16 wReserved1;
}

[CRepr]
public struct CCSTYLEW
{
	public uint32 flStyle;
	public uint32 flExtStyle;
	public char16[256] szText;
	public uint16 lgid;
	public uint16 wReserved1;
}

[CRepr]
public struct CCSTYLEFLAGA
{
	public uint32 flStyle;
	public uint32 flStyleMask;
	public PSTR pszStyle;
}

[CRepr]
public struct CCSTYLEFLAGW
{
	public uint32 flStyle;
	public uint32 flStyleMask;
	public PWSTR pszStyle;
}

[CRepr]
public struct CCINFOA
{
	public CHAR[32] szClass;
	public uint32 flOptions;
	public CHAR[32] szDesc;
	public uint32 cxDefault;
	public uint32 cyDefault;
	public uint32 flStyleDefault;
	public uint32 flExtStyleDefault;
	public uint32 flCtrlTypeMask;
	public CHAR[256] szTextDefault;
	public int32 cStyleFlags;
	public CCSTYLEFLAGA* aStyleFlags;
	public LPFNCCSTYLEA lpfnStyle;
	public LPFNCCSIZETOTEXTA lpfnSizeToText;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct CCINFOW
{
	public char16[32] szClass;
	public uint32 flOptions;
	public char16[32] szDesc;
	public uint32 cxDefault;
	public uint32 cyDefault;
	public uint32 flStyleDefault;
	public uint32 flExtStyleDefault;
	public uint32 flCtrlTypeMask;
	public int32 cStyleFlags;
	public CCSTYLEFLAGW* aStyleFlags;
	public char16[256] szTextDefault;
	public LPFNCCSTYLEW lpfnStyle;
	public LPFNCCSIZETOTEXTW lpfnSizeToText;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct NMHDR
{
	public HWND hwndFrom;
	public uint idFrom;
	public uint32 code;
}

[CRepr]
public struct MEASUREITEMSTRUCT
{
	public DRAWITEMSTRUCT_CTL_TYPE CtlType;
	public uint32 CtlID;
	public uint32 itemID;
	public uint32 itemWidth;
	public uint32 itemHeight;
	public uint itemData;
}

[CRepr]
public struct DRAWITEMSTRUCT
{
	public DRAWITEMSTRUCT_CTL_TYPE CtlType;
	public uint32 CtlID;
	public uint32 itemID;
	public ODA_FLAGS itemAction;
	public ODS_FLAGS itemState;
	public HWND hwndItem;
	public HDC hDC;
	public RECT rcItem;
	public uint itemData;
}

[CRepr]
public struct DELETEITEMSTRUCT
{
	public DRAWITEMSTRUCT_CTL_TYPE CtlType;
	public uint32 CtlID;
	public uint32 itemID;
	public HWND hwndItem;
	public uint itemData;
}

[CRepr]
public struct COMPAREITEMSTRUCT
{
	public DRAWITEMSTRUCT_CTL_TYPE CtlType;
	public uint32 CtlID;
	public HWND hwndItem;
	public uint32 itemID1;
	public uint itemData1;
	public uint32 itemID2;
	public uint itemData2;
	public uint32 dwLocaleId;
}

[CRepr]
public struct USAGE_PROPERTIES
{
	public uint16 level;
	public uint16 page;
	public uint16 usage;
	public int32 logicalMinimum;
	public int32 logicalMaximum;
	public uint16 unit;
	public uint16 exponent;
	public uint8 count;
	public int32 physicalMinimum;
	public int32 physicalMaximum;
}

[CRepr]
public struct POINTER_TYPE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public POINTER_TOUCH_INFO touchInfo;
		public POINTER_PEN_INFO penInfo;
	}
	public POINTER_INPUT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TOUCH_HIT_TESTING_PROXIMITY_EVALUATION
{
	public uint16 score;
	public POINT adjustedPoint;
}

[CRepr]
public struct TOUCH_HIT_TESTING_INPUT
{
	public uint32 pointerId;
	public POINT point;
	public RECT boundingBox;
	public RECT nonOccludedBoundingBox;
	public uint32 orientation;
}

[CRepr]
public struct COMBOBOXINFO
{
	public uint32 cbSize;
	public RECT rcItem;
	public RECT rcButton;
	public COMBOBOXINFO_BUTTON_STATE stateButton;
	public HWND hwndCombo;
	public HWND hwndItem;
	public HWND hwndList;
}

[CRepr]
public struct POINTER_DEVICE_INFO
{
	public uint32 displayOrientation;
	public HANDLE device;
	public POINTER_DEVICE_TYPE pointerDeviceType;
	public HMONITOR monitor;
	public uint32 startingCursorId;
	public uint16 maxActiveContacts;
	public char16[520] productString;
}

[CRepr]
public struct POINTER_DEVICE_PROPERTY
{
	public int32 logicalMin;
	public int32 logicalMax;
	public int32 physicalMin;
	public int32 physicalMax;
	public uint32 unit;
	public uint32 unitExponent;
	public uint16 usagePageId;
	public uint16 usageId;
}

[CRepr]
public struct POINTER_DEVICE_CURSOR_INFO
{
	public uint32 cursorId;
	public POINTER_DEVICE_CURSOR_TYPE cursor;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_ImageList = .(0x7c476ba2, 0x02b1, 0x48f4, 0x80, 0x48, 0xb2, 0x46, 0x19, 0xdd, 0xc0, 0x58);


}
#endregion

#region COM Types
[CRepr]struct IImageList : IUnknown
{
	public new const Guid IID = .(0x46eb5926, 0x582e, 0x4017, 0x9f, 0xdf, 0xe8, 0x99, 0x8d, 0xaa, 0x09, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP hbmImage, HBITMAP hbmMask, int32* pi) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, HICON hicon, int32* pi) ReplaceIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iImage, int32 iOverlay) SetOverlayImage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, HBITMAP hbmImage, HBITMAP hbmMask) Replace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP hbmImage, COLORREF crMask, int32* pi) AddMasked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMAGELISTDRAWPARAMS* pimldp) Draw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, uint32 flags, HICON* picon) GetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, IMAGEINFO* pImageInfo) GetImageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iDst, IUnknown* punkSrc, int32 iSrc, uint32 uFlags) Copy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i1, IUnknown* punk2, int32 i2, int32 dx, int32 dy, in Guid riid, void** ppv) Merge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, RECT* prc) GetImageRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* cx, int32* cy) GetIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cx, int32 cy) SetIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pi) GetImageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uNewCount) SetImageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COLORREF clrBk, COLORREF* pclr) SetBkColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COLORREF* pclr) GetBkColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iTrack, int32 dxHotspot, int32 dyHotspot) BeginDrag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndDrag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndLock, int32 x, int32 y) DragEnter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndLock) DragLeave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y) DragMove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, int32 iDrag, int32 dxHotspot, int32 dyHotspot) SetDragCursorImage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) DragShowNolock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt, POINT* pptHotspot, in Guid riid, void** ppv) GetDragImage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, IMAGE_LIST_ITEM_FLAGS* dwFlags) GetItemFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iOverlay, int32* piIndex) GetOverlayImage;
	}


	public HRESULT Add(HBITMAP hbmImage, HBITMAP hbmMask, int32* pi) mut => VT.[Friend]Add(&this, hbmImage, hbmMask, pi);

	public HRESULT ReplaceIcon(int32 i, HICON hicon, int32* pi) mut => VT.[Friend]ReplaceIcon(&this, i, hicon, pi);

	public HRESULT SetOverlayImage(int32 iImage, int32 iOverlay) mut => VT.[Friend]SetOverlayImage(&this, iImage, iOverlay);

	public HRESULT Replace(int32 i, HBITMAP hbmImage, HBITMAP hbmMask) mut => VT.[Friend]Replace(&this, i, hbmImage, hbmMask);

	public HRESULT AddMasked(HBITMAP hbmImage, COLORREF crMask, int32* pi) mut => VT.[Friend]AddMasked(&this, hbmImage, crMask, pi);

	public HRESULT Draw(IMAGELISTDRAWPARAMS* pimldp) mut => VT.[Friend]Draw(&this, pimldp);

	public HRESULT Remove(int32 i) mut => VT.[Friend]Remove(&this, i);

	public HRESULT GetIcon(int32 i, uint32 flags, HICON* picon) mut => VT.[Friend]GetIcon(&this, i, flags, picon);

	public HRESULT GetImageInfo(int32 i, IMAGEINFO* pImageInfo) mut => VT.[Friend]GetImageInfo(&this, i, pImageInfo);

	public HRESULT Copy(int32 iDst, IUnknown* punkSrc, int32 iSrc, uint32 uFlags) mut => VT.[Friend]Copy(&this, iDst, punkSrc, iSrc, uFlags);

	public HRESULT Merge(int32 i1, IUnknown* punk2, int32 i2, int32 dx, int32 dy, in Guid riid, void** ppv) mut => VT.[Friend]Merge(&this, i1, punk2, i2, dx, dy, riid, ppv);

	public HRESULT Clone(in Guid riid, void** ppv) mut => VT.[Friend]Clone(&this, riid, ppv);

	public HRESULT GetImageRect(int32 i, RECT* prc) mut => VT.[Friend]GetImageRect(&this, i, prc);

	public HRESULT GetIconSize(int32* cx, int32* cy) mut => VT.[Friend]GetIconSize(&this, cx, cy);

	public HRESULT SetIconSize(int32 cx, int32 cy) mut => VT.[Friend]SetIconSize(&this, cx, cy);

	public HRESULT GetImageCount(int32* pi) mut => VT.[Friend]GetImageCount(&this, pi);

	public HRESULT SetImageCount(uint32 uNewCount) mut => VT.[Friend]SetImageCount(&this, uNewCount);

	public HRESULT SetBkColor(COLORREF clrBk, COLORREF* pclr) mut => VT.[Friend]SetBkColor(&this, clrBk, pclr);

	public HRESULT GetBkColor(COLORREF* pclr) mut => VT.[Friend]GetBkColor(&this, pclr);

	public HRESULT BeginDrag(int32 iTrack, int32 dxHotspot, int32 dyHotspot) mut => VT.[Friend]BeginDrag(&this, iTrack, dxHotspot, dyHotspot);

	public HRESULT EndDrag() mut => VT.[Friend]EndDrag(&this);

	public HRESULT DragEnter(HWND hwndLock, int32 x, int32 y) mut => VT.[Friend]DragEnter(&this, hwndLock, x, y);

	public HRESULT DragLeave(HWND hwndLock) mut => VT.[Friend]DragLeave(&this, hwndLock);

	public HRESULT DragMove(int32 x, int32 y) mut => VT.[Friend]DragMove(&this, x, y);

	public HRESULT SetDragCursorImage(IUnknown* punk, int32 iDrag, int32 dxHotspot, int32 dyHotspot) mut => VT.[Friend]SetDragCursorImage(&this, punk, iDrag, dxHotspot, dyHotspot);

	public HRESULT DragShowNolock(BOOL fShow) mut => VT.[Friend]DragShowNolock(&this, fShow);

	public HRESULT GetDragImage(POINT* ppt, POINT* pptHotspot, in Guid riid, void** ppv) mut => VT.[Friend]GetDragImage(&this, ppt, pptHotspot, riid, ppv);

	public HRESULT GetItemFlags(int32 i, IMAGE_LIST_ITEM_FLAGS* dwFlags) mut => VT.[Friend]GetItemFlags(&this, i, dwFlags);

	public HRESULT GetOverlayImage(int32 iOverlay, int32* piIndex) mut => VT.[Friend]GetOverlayImage(&this, iOverlay, piIndex);
}

[CRepr]struct IImageList2 : IImageList
{
	public new const Guid IID = .(0x192b9d83, 0x50fc, 0x457b, 0x90, 0xa0, 0x2b, 0x82, 0xa8, 0xb5, 0xda, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IImageList.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cxNewIconSize, int32 cyNewIconSize) Resize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iImage, uint32 dwFlags, int32* pcx, int32* pcy) GetOriginalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iImage, int32 cx, int32 cy) SetOriginalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) SetCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iImage, uint32 dwFlags) ForceImagePresent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iFirstImage, int32 iLastImage, uint32 dwFlags) DiscardImages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMAGELISTDRAWPARAMS* pimldp) PreloadImages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMAGELISTSTATS* pils) GetStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cx, int32 cy, IMAGELIST_CREATION_FLAGS flags, int32 cInitial, int32 cGrow) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, HBITMAP hbmImage, HBITMAP hbmMask, IUnknown* punk, uint32 dwFlags) Replace2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 i, Win32.UI.Controls.IImageList* pil, int32 iSrc, IUnknown* punk, uint32 dwFlags) ReplaceFromImageList;
	}


	public HRESULT Resize(int32 cxNewIconSize, int32 cyNewIconSize) mut => VT.[Friend]Resize(&this, cxNewIconSize, cyNewIconSize);

	public HRESULT GetOriginalSize(int32 iImage, uint32 dwFlags, int32* pcx, int32* pcy) mut => VT.[Friend]GetOriginalSize(&this, iImage, dwFlags, pcx, pcy);

	public HRESULT SetOriginalSize(int32 iImage, int32 cx, int32 cy) mut => VT.[Friend]SetOriginalSize(&this, iImage, cx, cy);

	public HRESULT SetCallback(IUnknown* punk) mut => VT.[Friend]SetCallback(&this, punk);

	public HRESULT GetCallback(in Guid riid, void** ppv) mut => VT.[Friend]GetCallback(&this, riid, ppv);

	public HRESULT ForceImagePresent(int32 iImage, uint32 dwFlags) mut => VT.[Friend]ForceImagePresent(&this, iImage, dwFlags);

	public HRESULT DiscardImages(int32 iFirstImage, int32 iLastImage, uint32 dwFlags) mut => VT.[Friend]DiscardImages(&this, iFirstImage, iLastImage, dwFlags);

	public HRESULT PreloadImages(IMAGELISTDRAWPARAMS* pimldp) mut => VT.[Friend]PreloadImages(&this, pimldp);

	public HRESULT GetStatistics(IMAGELISTSTATS* pils) mut => VT.[Friend]GetStatistics(&this, pils);

	public HRESULT Initialize(int32 cx, int32 cy, IMAGELIST_CREATION_FLAGS flags, int32 cInitial, int32 cGrow) mut => VT.[Friend]Initialize(&this, cx, cy, flags, cInitial, cGrow);

	public HRESULT Replace2(int32 i, HBITMAP hbmImage, HBITMAP hbmMask, IUnknown* punk, uint32 dwFlags) mut => VT.[Friend]Replace2(&this, i, hbmImage, hbmMask, punk, dwFlags);

	public HRESULT ReplaceFromImageList(int32 i, Win32.UI.Controls.IImageList* pil, int32 iSrc, IUnknown* punk, uint32 dwFlags) mut => VT.[Friend]ReplaceFromImageList(&this, i, pil, iSrc, punk, dwFlags);
}

#endregion

#region Functions
public static
{
	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPROPSHEETPAGE CreatePropertySheetPageA(PROPSHEETPAGEA* constPropSheetPagePointer);
	public static HPROPSHEETPAGE CreatePropertySheetPage(PROPSHEETPAGEA* constPropSheetPagePointer) => CreatePropertySheetPageA(constPropSheetPagePointer);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPROPSHEETPAGE CreatePropertySheetPageW(PROPSHEETPAGEW* constPropSheetPagePointer);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DestroyPropertySheetPage(HPROPSHEETPAGE param0);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int PropertySheetA(PROPSHEETHEADERA_V2* param0);
	public static int PropertySheet(PROPSHEETHEADERA_V2* param0) => PropertySheetA(param0);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int PropertySheetW(PROPSHEETHEADERW_V2* param0);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitCommonControls();

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitCommonControlsEx(INITCOMMONCONTROLSEX* picce);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_Create(int32 cx, int32 cy, IMAGELIST_CREATION_FLAGS flags, int32 cInitial, int32 cGrow);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_Destroy(HIMAGELIST himl);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ImageList_GetImageCount(HIMAGELIST himl);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_SetImageCount(HIMAGELIST himl, uint32 uNewCount);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ImageList_Add(HIMAGELIST himl, HBITMAP hbmImage, HBITMAP hbmMask);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ImageList_ReplaceIcon(HIMAGELIST himl, int32 i, HICON hicon);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF ImageList_SetBkColor(HIMAGELIST himl, COLORREF clrBk);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF ImageList_GetBkColor(HIMAGELIST himl);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_SetOverlayImage(HIMAGELIST himl, int32 iImage, int32 iOverlay);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_Draw(HIMAGELIST himl, int32 i, HDC hdcDst, int32 x, int32 y, IMAGE_LIST_DRAW_STYLE fStyle);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_Replace(HIMAGELIST himl, int32 i, HBITMAP hbmImage, HBITMAP hbmMask);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ImageList_AddMasked(HIMAGELIST himl, HBITMAP hbmImage, COLORREF crMask);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_DrawEx(HIMAGELIST himl, int32 i, HDC hdcDst, int32 x, int32 y, int32 dx, int32 dy, COLORREF rgbBk, COLORREF rgbFg, IMAGE_LIST_DRAW_STYLE fStyle);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_DrawIndirect(IMAGELISTDRAWPARAMS* pimldp);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_Remove(HIMAGELIST himl, int32 i);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ImageList_GetIcon(HIMAGELIST himl, int32 i, uint32 flags);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_LoadImageA(HINSTANCE hi, PSTR lpbmp, int32 cx, int32 cGrow, COLORREF crMask, uint32 uType, IMAGE_FLAGS uFlags);
	public static HIMAGELIST ImageList_LoadImage(HINSTANCE hi, PSTR lpbmp, int32 cx, int32 cGrow, COLORREF crMask, uint32 uType, IMAGE_FLAGS uFlags) => ImageList_LoadImageA(hi, lpbmp, cx, cGrow, crMask, uType, uFlags);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_LoadImageW(HINSTANCE hi, PWSTR lpbmp, int32 cx, int32 cGrow, COLORREF crMask, uint32 uType, IMAGE_FLAGS uFlags);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_Copy(HIMAGELIST himlDst, int32 iDst, HIMAGELIST himlSrc, int32 iSrc, IMAGE_LIST_COPY_FLAGS uFlags);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_BeginDrag(HIMAGELIST himlTrack, int32 iTrack, int32 dxHotspot, int32 dyHotspot);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ImageList_EndDrag();

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_DragEnter(HWND hwndLock, int32 x, int32 y);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_DragLeave(HWND hwndLock);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_DragMove(int32 x, int32 y);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_SetDragCursorImage(HIMAGELIST himlDrag, int32 iDrag, int32 dxHotspot, int32 dyHotspot);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_DragShowNolock(BOOL fShow);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_GetDragImage(POINT* ppt, POINT* pptHotspot);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_Read(IStream* pstm);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_Write(HIMAGELIST himl, IStream* pstm);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImageList_ReadEx(uint32 dwFlags, IStream* pstm, in Guid riid, void** ppv);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImageList_WriteEx(HIMAGELIST himl, IMAGE_LIST_WRITE_STREAM_FLAGS dwFlags, IStream* pstm);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_GetIconSize(HIMAGELIST himl, int32* cx, int32* cy);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_SetIconSize(HIMAGELIST himl, int32 cx, int32 cy);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImageList_GetImageInfo(HIMAGELIST himl, int32 i, IMAGEINFO* pImageInfo);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_Merge(HIMAGELIST himl1, int32 i1, HIMAGELIST himl2, int32 i2, int32 dx, int32 dy);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HIMAGELIST ImageList_Duplicate(HIMAGELIST himl);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HIMAGELIST_QueryInterface(HIMAGELIST himl, in Guid riid, void** ppv);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND CreateToolbarEx(HWND hwnd, uint32 ws, uint32 wID, int32 nBitmaps, HINSTANCE hBMInst, uint wBMID, TBBUTTON* lpButtons, int32 iNumButtons, int32 dxButton, int32 dyButton, int32 dxBitmap, int32 dyBitmap, uint32 uStructSize);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateMappedBitmap(HINSTANCE hInstance, int idBitmap, uint32 wFlags, COLORMAP* lpColorMap, int32 iNumMaps);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrawStatusTextA(HDC hDC, RECT* lprc, PSTR pszText, uint32 uFlags);
	public static void DrawStatusText(HDC hDC, RECT* lprc, PSTR pszText, uint32 uFlags) => DrawStatusTextA(hDC, lprc, pszText, uFlags);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrawStatusTextW(HDC hDC, RECT* lprc, PWSTR pszText, uint32 uFlags);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND CreateStatusWindowA(int32 style, PSTR lpszText, HWND hwndParent, uint32 wID);
	public static HWND CreateStatusWindow(int32 style, PSTR lpszText, HWND hwndParent, uint32 wID) => CreateStatusWindowA(style, lpszText, hwndParent, wID);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND CreateStatusWindowW(int32 style, PWSTR lpszText, HWND hwndParent, uint32 wID);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void MenuHelp(uint32 uMsg, WPARAM wParam, LPARAM lParam, HMENU hMainMenu, HINSTANCE hInst, HWND hwndStatus, uint32* lpwIDs);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShowHideMenuCtl(HWND hWnd, uint uFlags, int32* lpInfo);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetEffectiveClientRect(HWND hWnd, RECT* lprc, int32* lpInfo);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MakeDragList(HWND hLB);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrawInsert(HWND handParent, HWND hLB, int32 nItem);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LBItemFromPt(HWND hLB, POINT pt, BOOL bAutoScroll);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND CreateUpDownControl(uint32 dwStyle, int32 x, int32 y, int32 cx, int32 cy, HWND hParent, int32 nID, HINSTANCE hInst, HWND hBuddy, int32 nUpper, int32 nLower, int32 nPos);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TaskDialogIndirect(TASKDIALOGCONFIG* pTaskConfig, int32* pnButton, int32* pnRadioButton, BOOL* pfVerificationFlagChecked);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TaskDialog(HWND hwndOwner, HINSTANCE hInstance, PWSTR pszWindowTitle, PWSTR pszMainInstruction, PWSTR pszContent, TASKDIALOG_COMMON_BUTTON_FLAGS dwCommonButtons, PWSTR pszIcon, int32* pnButton);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitMUILanguage(uint16 uiLang);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetMUILanguage();

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDSA DSA_Create(int32 cbItem, int32 cItemGrow);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DSA_Destroy(HDSA hdsa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DSA_DestroyCallback(HDSA hdsa, PFNDAENUMCALLBACK pfnCB, void* pData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DSA_DeleteItem(HDSA hdsa, int32 i);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DSA_DeleteAllItems(HDSA hdsa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DSA_EnumCallback(HDSA hdsa, PFNDAENUMCALLBACK pfnCB, void* pData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DSA_InsertItem(HDSA hdsa, int32 i, void* pitem);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* DSA_GetItemPtr(HDSA hdsa, int32 i);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DSA_GetItem(HDSA hdsa, int32 i, void* pitem);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DSA_SetItem(HDSA hdsa, int32 i, void* pitem);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDSA DSA_Clone(HDSA hdsa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 DSA_GetSize(HDSA hdsa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DSA_Sort(HDSA pdsa, PFNDACOMPARE pfnCompare, LPARAM lParam);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDPA DPA_Create(int32 cItemGrow);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDPA DPA_CreateEx(int32 cpGrow, HANDLE hheap);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDPA DPA_Clone(HDPA hdpa, HDPA hdpaNew);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPA_Destroy(HDPA hdpa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DPA_DestroyCallback(HDPA hdpa, PFNDAENUMCALLBACK pfnCB, void* pData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* DPA_DeletePtr(HDPA hdpa, int32 i);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPA_DeleteAllPtrs(HDPA hdpa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DPA_EnumCallback(HDPA hdpa, PFNDAENUMCALLBACK pfnCB, void* pData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPA_Grow(HDPA pdpa, int32 cp);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DPA_InsertPtr(HDPA hdpa, int32 i, void* p);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPA_SetPtr(HDPA hdpa, int32 i, void* p);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* DPA_GetPtr(HDPA hdpa, int i);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DPA_GetPtrIndex(HDPA hdpa, void* p);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 DPA_GetSize(HDPA hdpa);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPA_Sort(HDPA hdpa, PFNDACOMPARE pfnCompare, LPARAM lParam);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DPA_LoadStream(HDPA* phdpa, PFNDPASTREAM pfn, IStream* pstream, void* pvInstData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DPA_SaveStream(HDPA hdpa, PFNDPASTREAM pfn, IStream* pstream, void* pvInstData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPA_Merge(HDPA hdpaDest, HDPA hdpaSrc, uint32 dwFlags, PFNDACOMPARE pfnCompare, PFNDPAMERGE pfnMerge, LPARAM lParam);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DPA_Search(HDPA hdpa, void* pFind, int32 iStart, PFNDACOMPARE pfnCompare, LPARAM lParam, uint32 options);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Str_SetPtrW(PWSTR* ppsz, PWSTR psz);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlatSB_EnableScrollBar(HWND param0, int32 param1, uint32 param2);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlatSB_ShowScrollBar(HWND param0, SCROLLBAR_CONSTANTS code, BOOL param2);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlatSB_GetScrollRange(HWND param0, SCROLLBAR_CONSTANTS code, int32* param2, int32* param3);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlatSB_GetScrollInfo(HWND param0, SCROLLBAR_CONSTANTS code, SCROLLINFO* param2);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FlatSB_GetScrollPos(HWND param0, SCROLLBAR_CONSTANTS code);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlatSB_GetScrollProp(HWND param0, WSB_PROP propIndex, int32* param2);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FlatSB_SetScrollPos(HWND param0, SCROLLBAR_CONSTANTS code, int32 pos, BOOL fRedraw);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FlatSB_SetScrollInfo(HWND param0, SCROLLBAR_CONSTANTS code, SCROLLINFO* psi, BOOL fRedraw);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FlatSB_SetScrollRange(HWND param0, SCROLLBAR_CONSTANTS code, int32 min, int32 max, BOOL fRedraw);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlatSB_SetScrollProp(HWND param0, WSB_PROP index, int newValue, BOOL param3);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeFlatSB(HWND param0);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UninitializeFlatSB(HWND param0);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadIconMetric(HINSTANCE hinst, PWSTR pszName, _LI_METRIC lims, HICON* phico);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadIconWithScaleDown(HINSTANCE hinst, PWSTR pszName, int32 cx, int32 cy, HICON* phico);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DrawShadowText(HDC hdc, char16* pszText, uint32 cch, RECT* prc, uint32 dwFlags, COLORREF crText, COLORREF crShadow, int32 ixOffset, int32 iyOffset);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImageList_CoCreateInstance(in Guid rclsid, IUnknown* punkOuter, in Guid riid, void** ppv);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BeginPanningFeedback(HWND hwnd);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdatePanningFeedback(HWND hwnd, int32 lTotalOverpanOffsetX, int32 lTotalOverpanOffsetY, BOOL fInInertia);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndPanningFeedback(HWND hwnd, BOOL fAnimateBack);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeAnimationProperty(int hTheme, int32 iStoryboardId, int32 iTargetId, TA_PROPERTY eProperty, void* pvProperty, uint32 cbSize, uint32* pcbSizeOut);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeAnimationTransform(int hTheme, int32 iStoryboardId, int32 iTargetId, uint32 dwTransformIndex, TA_TRANSFORM* pTransform, uint32 cbSize, uint32* pcbSizeOut);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeTimingFunction(int hTheme, int32 iTimingFunctionId, TA_TIMINGFUNCTION* pTimingFunction, uint32 cbSize, uint32* pcbSizeOut);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OpenThemeData(HWND hwnd, PWSTR pszClassList);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OpenThemeDataEx(HWND hwnd, PWSTR pszClassList, OPEN_THEME_DATA_FLAGS dwFlags);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CloseThemeData(int hTheme);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeBackground(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pRect, RECT* pClipRect);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeBackgroundEx(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pRect, DTBGOPTS* pOptions);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeText(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, char16* pszText, int32 cchText, DRAW_TEXT_FORMAT dwTextFlags, uint32 dwTextFlags2, RECT* pRect);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeBackgroundContentRect(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pBoundingRect, RECT* pContentRect);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeBackgroundExtent(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pContentRect, RECT* pExtentRect);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeBackgroundRegion(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pRect, HRGN* pRegion);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemePartSize(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* prc, THEMESIZE eSize, SIZE* psz);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeTextExtent(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, char16* pszText, int32 cchCharCount, DRAW_TEXT_FORMAT dwTextFlags, RECT* pBoundingRect, RECT* pExtentRect);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeTextMetrics(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, TEXTMETRICW* ptm);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HitTestThemeBackground(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, HIT_TEST_BACKGROUND_OPTIONS dwOptions, RECT* pRect, HRGN hrgn, POINT ptTest, uint16* pwHitTestCode);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeEdge(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pDestRect, DRAWEDGE_FLAGS uEdge, DRAW_EDGE_FLAGS uFlags, RECT* pContentRect);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeIcon(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, RECT* pRect, HIMAGELIST himl, int32 iImageIndex);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsThemePartDefined(int hTheme, int32 iPartId, int32 iStateId);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsThemeBackgroundPartiallyTransparent(int hTheme, int32 iPartId, int32 iStateId);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeColor(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, COLORREF* pColor);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeMetric(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, int32* piVal);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeString(int hTheme, int32 iPartId, int32 iStateId, int32 iPropId, char16* pszBuff, int32 cchMaxBuffChars);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeBool(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, BOOL* pfVal);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeInt(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, int32* piVal);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeEnumValue(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, int32* piVal);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemePosition(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, POINT* pPoint);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeFont(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, int32 iPropId, LOGFONTW* pFont);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeRect(int hTheme, int32 iPartId, int32 iStateId, int32 iPropId, RECT* pRect);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeMargins(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, RECT* prc, MARGINS* pMargins);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeIntList(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, INTLIST* pIntList);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemePropertyOrigin(int hTheme, int32 iPartId, int32 iStateId, int32 iPropId, PROPERTYORIGIN* pOrigin);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetWindowTheme(HWND hwnd, PWSTR pszSubAppName, PWSTR pszSubIdList);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeFilename(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, char16* pszThemeFileName, int32 cchMaxBuffChars);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetThemeSysColor(int hTheme, int32 iColorId);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH GetThemeSysColorBrush(int hTheme, THEME_PROPERTY_SYMBOL_ID iColorId);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThemeSysBool(int hTheme, THEME_PROPERTY_SYMBOL_ID iBoolId);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetThemeSysSize(int hTheme, int32 iSizeId);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeSysFont(int hTheme, THEME_PROPERTY_SYMBOL_ID iFontId, LOGFONTW* plf);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeSysString(int hTheme, THEME_PROPERTY_SYMBOL_ID iStringId, char16* pszStringBuff, int32 cchMaxStringChars);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeSysInt(int hTheme, THEME_PROPERTY_SYMBOL_ID iIntId, int32* piValue);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsThemeActive();

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsAppThemed();

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int GetWindowTheme(HWND hwnd);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnableThemeDialogTexture(HWND hwnd, uint32 dwFlags);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsThemeDialogTextureEnabled(HWND hwnd);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SET_THEME_APP_PROPERTIES_FLAGS GetThemeAppProperties();

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetThemeAppProperties(SET_THEME_APP_PROPERTIES_FLAGS dwFlags);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetCurrentThemeName(char16* pszThemeFileName, int32 cchMaxNameChars, char16* pszColorBuff, int32 cchMaxColorChars, char16* pszSizeBuff, int32 cchMaxSizeChars);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeDocumentationProperty(PWSTR pszThemeName, PWSTR pszPropertyName, char16* pszValueBuff, int32 cchMaxValChars);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeParentBackground(HWND hwnd, HDC hdc, RECT* prc);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnableTheming(BOOL fEnable);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeParentBackgroundEx(HWND hwnd, HDC hdc, DRAW_THEME_PARENT_BACKGROUND_FLAGS dwFlags, RECT* prc);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetWindowThemeAttribute(HWND hwnd, WINDOWTHEMEATTRIBUTETYPE eAttribute, void* pvAttribute, uint32 cbAttribute);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrawThemeTextEx(int hTheme, HDC hdc, int32 iPartId, int32 iStateId, char16* pszText, int32 cchText, DRAW_TEXT_FORMAT dwTextFlags, RECT* pRect, DTTOPTS* pOptions);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeBitmap(int hTheme, int32 iPartId, int32 iStateId, THEME_PROPERTY_SYMBOL_ID iPropId, GET_THEME_BITMAP_FLAGS dwFlags, HBITMAP* phBitmap);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeStream(int hTheme, int32 iPartId, int32 iStateId, int32 iPropId, void** ppvStream, uint32* pcbStream, HINSTANCE hInst);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BufferedPaintInit();

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BufferedPaintUnInit();

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int BeginBufferedPaint(HDC hdcTarget, RECT* prcTarget, BP_BUFFERFORMAT dwFormat, BP_PAINTPARAMS* pPaintParams, HDC* phdc);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EndBufferedPaint(int hBufferedPaint, BOOL fUpdateTarget);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetBufferedPaintTargetRect(int hBufferedPaint, RECT* prc);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC GetBufferedPaintTargetDC(int hBufferedPaint);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC GetBufferedPaintDC(int hBufferedPaint);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetBufferedPaintBits(int hBufferedPaint, RGBQUAD** ppbBuffer, int32* pcxRow);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BufferedPaintClear(int hBufferedPaint, RECT* prc);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BufferedPaintSetAlpha(int hBufferedPaint, RECT* prc, uint8 alpha);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BufferedPaintStopAllAnimations(HWND hwnd);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int BeginBufferedAnimation(HWND hwnd, HDC hdcTarget, RECT* prcTarget, BP_BUFFERFORMAT dwFormat, BP_PAINTPARAMS* pPaintParams, BP_ANIMATIONPARAMS* pAnimationParams, HDC* phdcFrom, HDC* phdcTo);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EndBufferedAnimation(int hbpAnimation, BOOL fUpdateTarget);

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BufferedPaintRenderAnimation(HWND hwnd, HDC hdcTarget);

	[Import("UXTHEME.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsCompositionActive();

	[Import("UxTheme.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThemeTransitionDuration(int hTheme, int32 iPartId, int32 iStateIdFrom, int32 iStateIdTo, int32 iPropId, uint32* pdwDuration);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckDlgButton(HWND hDlg, int32 nIDButton, DLG_BUTTON_CHECK_STATE uCheck);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckRadioButton(HWND hDlg, int32 nIDFirstButton, int32 nIDLastButton, int32 nIDCheckButton);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IsDlgButtonChecked(HWND hDlg, int32 nIDButton);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsCharLowerW(char16 ch);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HSYNTHETICPOINTERDEVICE CreateSyntheticPointerDevice(POINTER_INPUT_TYPE pointerType, uint32 maxCount, POINTER_FEEDBACK_MODE mode);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DestroySyntheticPointerDevice(HSYNTHETICPOINTERDEVICE device);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterTouchHitTestingWindow(HWND hwnd, uint32 value);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvaluateProximityToRect(RECT* controlBoundingBox, TOUCH_HIT_TESTING_INPUT* pHitTestingInput, TOUCH_HIT_TESTING_PROXIMITY_EVALUATION* pProximityEval);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvaluateProximityToPolygon(uint32 numVertices, POINT* controlPolygon, TOUCH_HIT_TESTING_INPUT* pHitTestingInput, TOUCH_HIT_TESTING_PROXIMITY_EVALUATION* pProximityEval);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT PackTouchHitTestingProximityEvaluation(TOUCH_HIT_TESTING_INPUT* pHitTestingInput, TOUCH_HIT_TESTING_PROXIMITY_EVALUATION* pProximityEval);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetWindowFeedbackSetting(HWND hwnd, FEEDBACK_TYPE feedback, uint32 dwFlags, uint32* pSize, void* config);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWindowFeedbackSetting(HWND hwnd, FEEDBACK_TYPE feedback, uint32 dwFlags, uint32 size, void* configuration);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetScrollPos(HWND hWnd, SCROLLBAR_CONSTANTS nBar, int32 nPos, BOOL bRedraw);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetScrollRange(HWND hWnd, SCROLLBAR_CONSTANTS nBar, int32 nMinPos, int32 nMaxPos, BOOL bRedraw);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShowScrollBar(HWND hWnd, SCROLLBAR_CONSTANTS wBar, BOOL bShow);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnableScrollBar(HWND hWnd, SCROLLBAR_CONSTANTS wSBflags, ENABLE_SCROLL_BAR_ARROWS wArrows);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DlgDirListA(HWND hDlg, PSTR lpPathSpec, int32 nIDListBox, int32 nIDStaticPath, DLG_DIR_LIST_FILE_TYPE uFileType);
	public static int32 DlgDirList(HWND hDlg, PSTR lpPathSpec, int32 nIDListBox, int32 nIDStaticPath, DLG_DIR_LIST_FILE_TYPE uFileType) => DlgDirListA(hDlg, lpPathSpec, nIDListBox, nIDStaticPath, uFileType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DlgDirListW(HWND hDlg, PWSTR lpPathSpec, int32 nIDListBox, int32 nIDStaticPath, DLG_DIR_LIST_FILE_TYPE uFileType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DlgDirSelectExA(HWND hwndDlg, uint8* lpString, int32 chCount, int32 idListBox);
	public static BOOL DlgDirSelectEx(HWND hwndDlg, uint8* lpString, int32 chCount, int32 idListBox) => DlgDirSelectExA(hwndDlg, lpString, chCount, idListBox);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DlgDirSelectExW(HWND hwndDlg, char16* lpString, int32 chCount, int32 idListBox);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DlgDirListComboBoxA(HWND hDlg, PSTR lpPathSpec, int32 nIDComboBox, int32 nIDStaticPath, DLG_DIR_LIST_FILE_TYPE uFiletype);
	public static int32 DlgDirListComboBox(HWND hDlg, PSTR lpPathSpec, int32 nIDComboBox, int32 nIDStaticPath, DLG_DIR_LIST_FILE_TYPE uFiletype) => DlgDirListComboBoxA(hDlg, lpPathSpec, nIDComboBox, nIDStaticPath, uFiletype);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DlgDirListComboBoxW(HWND hDlg, PWSTR lpPathSpec, int32 nIDComboBox, int32 nIDStaticPath, DLG_DIR_LIST_FILE_TYPE uFiletype);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DlgDirSelectComboBoxExA(HWND hwndDlg, uint8* lpString, int32 cchOut, int32 idComboBox);
	public static BOOL DlgDirSelectComboBoxEx(HWND hwndDlg, uint8* lpString, int32 cchOut, int32 idComboBox) => DlgDirSelectComboBoxExA(hwndDlg, lpString, cchOut, idComboBox);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DlgDirSelectComboBoxExW(HWND hwndDlg, char16* lpString, int32 cchOut, int32 idComboBox);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetScrollInfo(HWND hwnd, SCROLLBAR_CONSTANTS nBar, SCROLLINFO* lpsi, BOOL redraw);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetComboBoxInfo(HWND hwndCombo, COMBOBOXINFO* pcbi);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetListBoxInfo(HWND hwnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterPointerDeviceNotifications(HWND window, BOOL notifyRange);

}
#endregion
