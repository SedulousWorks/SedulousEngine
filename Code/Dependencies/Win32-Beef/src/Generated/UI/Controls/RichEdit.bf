using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using Win32.UI.Controls;
using Win32.System.Ole;
using Win32.UI.WindowsAndMessaging;
using Win32.Globalization;
using Win32.Graphics.Direct2D;
using Win32.System.Com.StructuredStorage;
using Win32.System.SystemServices;
using System;

namespace Win32.UI.Controls.RichEdit;

#region Constants
public static
{
	public const uint32 cchTextLimitDefault = 32767;
	public const String MSFTEDIT_CLASS = "RICHEDIT50W";
	public const String CERICHEDIT_CLASSA = "RichEditCEA";
	public const String CERICHEDIT_CLASSW = "RichEditCEW";
	public const String RICHEDIT_CLASSA = "RichEdit20A";
	public const String RICHEDIT_CLASS10A = "RICHEDIT";
	public const String RICHEDIT_CLASSW = "RichEdit20W";
	public const String RICHEDIT_CLASS = "RichEdit20W";
	public const uint32 EM_CANPASTE = 1074;
	public const uint32 EM_DISPLAYBAND = 1075;
	public const uint32 EM_EXGETSEL = 1076;
	public const uint32 EM_EXLIMITTEXT = 1077;
	public const uint32 EM_EXLINEFROMCHAR = 1078;
	public const uint32 EM_EXSETSEL = 1079;
	public const uint32 EM_FINDTEXT = 1080;
	public const uint32 EM_FORMATRANGE = 1081;
	public const uint32 EM_GETCHARFORMAT = 1082;
	public const uint32 EM_GETEVENTMASK = 1083;
	public const uint32 EM_GETOLEINTERFACE = 1084;
	public const uint32 EM_GETPARAFORMAT = 1085;
	public const uint32 EM_GETSELTEXT = 1086;
	public const uint32 EM_HIDESELECTION = 1087;
	public const uint32 EM_PASTESPECIAL = 1088;
	public const uint32 EM_REQUESTRESIZE = 1089;
	public const uint32 EM_SELECTIONTYPE = 1090;
	public const uint32 EM_SETBKGNDCOLOR = 1091;
	public const uint32 EM_SETCHARFORMAT = 1092;
	public const uint32 EM_SETEVENTMASK = 1093;
	public const uint32 EM_SETOLECALLBACK = 1094;
	public const uint32 EM_SETPARAFORMAT = 1095;
	public const uint32 EM_SETTARGETDEVICE = 1096;
	public const uint32 EM_STREAMIN = 1097;
	public const uint32 EM_STREAMOUT = 1098;
	public const uint32 EM_GETTEXTRANGE = 1099;
	public const uint32 EM_FINDWORDBREAK = 1100;
	public const uint32 EM_SETOPTIONS = 1101;
	public const uint32 EM_GETOPTIONS = 1102;
	public const uint32 EM_FINDTEXTEX = 1103;
	public const uint32 EM_GETWORDBREAKPROCEX = 1104;
	public const uint32 EM_SETWORDBREAKPROCEX = 1105;
	public const uint32 EM_SETUNDOLIMIT = 1106;
	public const uint32 EM_REDO = 1108;
	public const uint32 EM_CANREDO = 1109;
	public const uint32 EM_GETUNDONAME = 1110;
	public const uint32 EM_GETREDONAME = 1111;
	public const uint32 EM_STOPGROUPTYPING = 1112;
	public const uint32 EM_SETTEXTMODE = 1113;
	public const uint32 EM_GETTEXTMODE = 1114;
	public const uint32 EM_AUTOURLDETECT = 1115;
	public const uint32 AURL_ENABLEURL = 1;
	public const uint32 AURL_ENABLEEMAILADDR = 2;
	public const uint32 AURL_ENABLETELNO = 4;
	public const uint32 AURL_ENABLEEAURLS = 8;
	public const uint32 AURL_ENABLEDRIVELETTERS = 16;
	public const uint32 AURL_DISABLEMIXEDLGC = 32;
	public const uint32 EM_GETAUTOURLDETECT = 1116;
	public const uint32 EM_SETPALETTE = 1117;
	public const uint32 EM_GETTEXTEX = 1118;
	public const uint32 EM_GETTEXTLENGTHEX = 1119;
	public const uint32 EM_SHOWSCROLLBAR = 1120;
	public const uint32 EM_SETTEXTEX = 1121;
	public const uint32 EM_SETPUNCTUATION = 1124;
	public const uint32 EM_GETPUNCTUATION = 1125;
	public const uint32 EM_SETWORDWRAPMODE = 1126;
	public const uint32 EM_GETWORDWRAPMODE = 1127;
	public const uint32 EM_SETIMECOLOR = 1128;
	public const uint32 EM_GETIMECOLOR = 1129;
	public const uint32 EM_SETIMEOPTIONS = 1130;
	public const uint32 EM_GETIMEOPTIONS = 1131;
	public const uint32 EM_CONVPOSITION = 1132;
	public const uint32 EM_SETLANGOPTIONS = 1144;
	public const uint32 EM_GETLANGOPTIONS = 1145;
	public const uint32 EM_GETIMECOMPMODE = 1146;
	public const uint32 EM_FINDTEXTW = 1147;
	public const uint32 EM_FINDTEXTEXW = 1148;
	public const uint32 EM_RECONVERSION = 1149;
	public const uint32 EM_SETIMEMODEBIAS = 1150;
	public const uint32 EM_GETIMEMODEBIAS = 1151;
	public const uint32 EM_SETBIDIOPTIONS = 1224;
	public const uint32 EM_GETBIDIOPTIONS = 1225;
	public const uint32 EM_SETTYPOGRAPHYOPTIONS = 1226;
	public const uint32 EM_GETTYPOGRAPHYOPTIONS = 1227;
	public const uint32 EM_SETEDITSTYLE = 1228;
	public const uint32 EM_GETEDITSTYLE = 1229;
	public const uint32 SES_EMULATESYSEDIT = 1;
	public const uint32 SES_BEEPONMAXTEXT = 2;
	public const uint32 SES_EXTENDBACKCOLOR = 4;
	public const uint32 SES_MAPCPS = 8;
	public const uint32 SES_HYPERLINKTOOLTIPS = 8;
	public const uint32 SES_EMULATE10 = 16;
	public const uint32 SES_DEFAULTLATINLIGA = 16;
	public const uint32 SES_USECRLF = 32;
	public const uint32 SES_NOFOCUSLINKNOTIFY = 32;
	public const uint32 SES_USEAIMM = 64;
	public const uint32 SES_NOIME = 128;
	public const uint32 SES_ALLOWBEEPS = 256;
	public const uint32 SES_UPPERCASE = 512;
	public const uint32 SES_LOWERCASE = 1024;
	public const uint32 SES_NOINPUTSEQUENCECHK = 2048;
	public const uint32 SES_BIDI = 4096;
	public const uint32 SES_SCROLLONKILLFOCUS = 8192;
	public const uint32 SES_XLTCRCRLFTOCR = 16384;
	public const uint32 SES_DRAFTMODE = 32768;
	public const uint32 SES_USECTF = 65536;
	public const uint32 SES_HIDEGRIDLINES = 131072;
	public const uint32 SES_USEATFONT = 262144;
	public const uint32 SES_CUSTOMLOOK = 524288;
	public const uint32 SES_LBSCROLLNOTIFY = 1048576;
	public const uint32 SES_CTFALLOWEMBED = 2097152;
	public const uint32 SES_CTFALLOWSMARTTAG = 4194304;
	public const uint32 SES_CTFALLOWPROOFING = 8388608;
	public const uint32 SES_LOGICALCARET = 16777216;
	public const uint32 SES_WORDDRAGDROP = 33554432;
	public const uint32 SES_SMARTDRAGDROP = 67108864;
	public const uint32 SES_MULTISELECT = 134217728;
	public const uint32 SES_CTFNOLOCK = 268435456;
	public const uint32 SES_NOEALINEHEIGHTADJUST = 536870912;
	public const uint32 SES_MAX = 536870912;
	public const uint32 IMF_AUTOKEYBOARD = 1;
	public const uint32 IMF_AUTOFONT = 2;
	public const uint32 IMF_IMECANCELCOMPLETE = 4;
	public const uint32 IMF_IMEALWAYSSENDNOTIFY = 8;
	public const uint32 IMF_AUTOFONTSIZEADJUST = 16;
	public const uint32 IMF_UIFONTS = 32;
	public const uint32 IMF_NOIMPLICITLANG = 64;
	public const uint32 IMF_DUALFONT = 128;
	public const uint32 IMF_NOKBDLIDFIXUP = 512;
	public const uint32 IMF_NORTFFONTSUBSTITUTE = 1024;
	public const uint32 IMF_SPELLCHECKING = 2048;
	public const uint32 IMF_TKBPREDICTION = 4096;
	public const uint32 IMF_IMEUIINTEGRATION = 8192;
	public const uint32 ICM_NOTOPEN = 0;
	public const uint32 ICM_LEVEL3 = 1;
	public const uint32 ICM_LEVEL2 = 2;
	public const uint32 ICM_LEVEL2_5 = 3;
	public const uint32 ICM_LEVEL2_SUI = 4;
	public const uint32 ICM_CTF = 5;
	public const uint32 TO_ADVANCEDTYPOGRAPHY = 1;
	public const uint32 TO_SIMPLELINEBREAK = 2;
	public const uint32 TO_DISABLECUSTOMTEXTOUT = 4;
	public const uint32 TO_ADVANCEDLAYOUT = 8;
	public const uint32 EM_OUTLINE = 1244;
	public const uint32 EM_GETSCROLLPOS = 1245;
	public const uint32 EM_SETSCROLLPOS = 1246;
	public const uint32 EM_SETFONTSIZE = 1247;
	public const uint32 EM_GETZOOM = 1248;
	public const uint32 EM_SETZOOM = 1249;
	public const uint32 EM_GETVIEWKIND = 1250;
	public const uint32 EM_SETVIEWKIND = 1251;
	public const uint32 EM_GETPAGE = 1252;
	public const uint32 EM_SETPAGE = 1253;
	public const uint32 EM_GETHYPHENATEINFO = 1254;
	public const uint32 EM_SETHYPHENATEINFO = 1255;
	public const uint32 EM_GETPAGEROTATE = 1259;
	public const uint32 EM_SETPAGEROTATE = 1260;
	public const uint32 EM_GETCTFMODEBIAS = 1261;
	public const uint32 EM_SETCTFMODEBIAS = 1262;
	public const uint32 EM_GETCTFOPENSTATUS = 1264;
	public const uint32 EM_SETCTFOPENSTATUS = 1265;
	public const uint32 EM_GETIMECOMPTEXT = 1266;
	public const uint32 EM_ISIME = 1267;
	public const uint32 EM_GETIMEPROPERTY = 1268;
	public const uint32 EM_GETQUERYRTFOBJ = 1293;
	public const uint32 EM_SETQUERYRTFOBJ = 1294;
	public const uint32 EPR_0 = 0;
	public const uint32 EPR_270 = 1;
	public const uint32 EPR_180 = 2;
	public const uint32 EPR_90 = 3;
	public const uint32 EPR_SE = 5;
	public const uint32 CTFMODEBIAS_DEFAULT = 0;
	public const uint32 CTFMODEBIAS_FILENAME = 1;
	public const uint32 CTFMODEBIAS_NAME = 2;
	public const uint32 CTFMODEBIAS_READING = 3;
	public const uint32 CTFMODEBIAS_DATETIME = 4;
	public const uint32 CTFMODEBIAS_CONVERSATION = 5;
	public const uint32 CTFMODEBIAS_NUMERIC = 6;
	public const uint32 CTFMODEBIAS_HIRAGANA = 7;
	public const uint32 CTFMODEBIAS_KATAKANA = 8;
	public const uint32 CTFMODEBIAS_HANGUL = 9;
	public const uint32 CTFMODEBIAS_HALFWIDTHKATAKANA = 10;
	public const uint32 CTFMODEBIAS_FULLWIDTHALPHANUMERIC = 11;
	public const uint32 CTFMODEBIAS_HALFWIDTHALPHANUMERIC = 12;
	public const uint32 IMF_SMODE_PLAURALCLAUSE = 1;
	public const uint32 IMF_SMODE_NONE = 2;
	public const uint32 EMO_EXIT = 0;
	public const uint32 EMO_ENTER = 1;
	public const uint32 EMO_PROMOTE = 2;
	public const uint32 EMO_EXPAND = 3;
	public const uint32 EMO_MOVESELECTION = 4;
	public const uint32 EMO_GETVIEWMODE = 5;
	public const uint32 EMO_EXPANDSELECTION = 0;
	public const uint32 EMO_EXPANDDOCUMENT = 1;
	public const uint32 VM_NORMAL = 4;
	public const uint32 VM_OUTLINE = 2;
	public const uint32 VM_PAGE = 9;
	public const uint32 EM_INSERTTABLE = 1256;
	public const uint32 EM_GETAUTOCORRECTPROC = 1257;
	public const uint32 EM_SETAUTOCORRECTPROC = 1258;
	public const uint32 EM_CALLAUTOCORRECTPROC = 1279;
	public const uint32 ATP_NOCHANGE = 0;
	public const uint32 ATP_CHANGE = 1;
	public const uint32 ATP_NODELIMITER = 2;
	public const uint32 ATP_REPLACEALLTEXT = 4;
	public const uint32 EM_GETTABLEPARMS = 1289;
	public const uint32 EM_SETEDITSTYLEEX = 1299;
	public const uint32 EM_GETEDITSTYLEEX = 1300;
	public const uint32 SES_EX_NOTABLE = 4;
	public const uint32 SES_EX_NOMATH = 64;
	public const uint32 SES_EX_HANDLEFRIENDLYURL = 256;
	public const uint32 SES_EX_NOTHEMING = 524288;
	public const uint32 SES_EX_NOACETATESELECTION = 1048576;
	public const uint32 SES_EX_USESINGLELINE = 2097152;
	public const uint32 SES_EX_MULTITOUCH = 134217728;
	public const uint32 SES_EX_HIDETEMPFORMAT = 268435456;
	public const uint32 SES_EX_USEMOUSEWPARAM = 536870912;
	public const uint32 EM_GETSTORYTYPE = 1314;
	public const uint32 EM_SETSTORYTYPE = 1315;
	public const uint32 EM_GETELLIPSISMODE = 1329;
	public const uint32 EM_SETELLIPSISMODE = 1330;
	public const uint32 ELLIPSIS_MASK = 3;
	public const uint32 ELLIPSIS_NONE = 0;
	public const uint32 ELLIPSIS_END = 1;
	public const uint32 ELLIPSIS_WORD = 3;
	public const uint32 EM_SETTABLEPARMS = 1331;
	public const uint32 EM_GETTOUCHOPTIONS = 1334;
	public const uint32 EM_SETTOUCHOPTIONS = 1335;
	public const uint32 EM_INSERTIMAGE = 1338;
	public const uint32 EM_SETUIANAME = 1344;
	public const uint32 EM_GETELLIPSISSTATE = 1346;
	public const uint32 RTO_SHOWHANDLES = 1;
	public const uint32 RTO_DISABLEHANDLES = 2;
	public const uint32 RTO_READINGMODE = 3;
	public const uint32 EN_MSGFILTER = 1792;
	public const uint32 EN_REQUESTRESIZE = 1793;
	public const uint32 EN_SELCHANGE = 1794;
	public const uint32 EN_DROPFILES = 1795;
	public const uint32 EN_PROTECTED = 1796;
	public const uint32 EN_CORRECTTEXT = 1797;
	public const uint32 EN_STOPNOUNDO = 1798;
	public const uint32 EN_IMECHANGE = 1799;
	public const uint32 EN_SAVECLIPBOARD = 1800;
	public const uint32 EN_OLEOPFAILED = 1801;
	public const uint32 EN_OBJECTPOSITIONS = 1802;
	public const uint32 EN_LINK = 1803;
	public const uint32 EN_DRAGDROPDONE = 1804;
	public const uint32 EN_PARAGRAPHEXPANDED = 1805;
	public const uint32 EN_PAGECHANGE = 1806;
	public const uint32 EN_LOWFIRTF = 1807;
	public const uint32 EN_ALIGNLTR = 1808;
	public const uint32 EN_ALIGNRTL = 1809;
	public const uint32 EN_CLIPFORMAT = 1810;
	public const uint32 EN_STARTCOMPOSITION = 1811;
	public const uint32 EN_ENDCOMPOSITION = 1812;
	public const uint32 ENM_NONE = 0;
	public const uint32 ENM_CHANGE = 1;
	public const uint32 ENM_UPDATE = 2;
	public const uint32 ENM_SCROLL = 4;
	public const uint32 ENM_SCROLLEVENTS = 8;
	public const uint32 ENM_DRAGDROPDONE = 16;
	public const uint32 ENM_PARAGRAPHEXPANDED = 32;
	public const uint32 ENM_PAGECHANGE = 64;
	public const uint32 ENM_CLIPFORMAT = 128;
	public const uint32 ENM_KEYEVENTS = 65536;
	public const uint32 ENM_MOUSEEVENTS = 131072;
	public const uint32 ENM_REQUESTRESIZE = 262144;
	public const uint32 ENM_SELCHANGE = 524288;
	public const uint32 ENM_DROPFILES = 1048576;
	public const uint32 ENM_PROTECTED = 2097152;
	public const uint32 ENM_CORRECTTEXT = 4194304;
	public const uint32 ENM_IMECHANGE = 8388608;
	public const uint32 ENM_LANGCHANGE = 16777216;
	public const uint32 ENM_OBJECTPOSITIONS = 33554432;
	public const uint32 ENM_LINK = 67108864;
	public const uint32 ENM_LOWFIRTF = 134217728;
	public const uint32 ENM_STARTCOMPOSITION = 268435456;
	public const uint32 ENM_ENDCOMPOSITION = 536870912;
	public const uint32 ENM_GROUPTYPINGCHANGE = 1073741824;
	public const uint32 ENM_HIDELINKTOOLTIP = 2147483648;
	public const uint32 ES_SAVESEL = 32768;
	public const uint32 ES_SUNKEN = 16384;
	public const uint32 ES_DISABLENOSCROLL = 8192;
	public const uint32 ES_SELECTIONBAR = 16777216;
	public const uint32 ES_NOOLEDRAGDROP = 8;
	public const uint32 ES_EX_NOCALLOLEINIT = 0;
	public const uint32 ES_VERTICAL = 4194304;
	public const uint32 ES_NOIME = 524288;
	public const uint32 ES_SELFIME = 262144;
	public const uint32 ECO_AUTOWORDSELECTION = 1;
	public const uint32 ECO_AUTOVSCROLL = 64;
	public const uint32 ECO_AUTOHSCROLL = 128;
	public const uint32 ECO_NOHIDESEL = 256;
	public const uint32 ECO_READONLY = 2048;
	public const uint32 ECO_WANTRETURN = 4096;
	public const uint32 ECO_SAVESEL = 32768;
	public const uint32 ECO_SELECTIONBAR = 16777216;
	public const uint32 ECO_VERTICAL = 4194304;
	public const uint32 ECOOP_SET = 1;
	public const uint32 ECOOP_OR = 2;
	public const uint32 ECOOP_AND = 3;
	public const uint32 ECOOP_XOR = 4;
	public const uint32 WB_MOVEWORDPREV = 4;
	public const uint32 WB_MOVEWORDNEXT = 5;
	public const uint32 WB_PREVBREAK = 6;
	public const uint32 WB_NEXTBREAK = 7;
	public const uint32 PC_FOLLOWING = 1;
	public const uint32 PC_LEADING = 2;
	public const uint32 PC_OVERFLOW = 3;
	public const uint32 PC_DELIMITER = 4;
	public const uint32 WBF_WORDWRAP = 16;
	public const uint32 WBF_WORDBREAK = 32;
	public const uint32 WBF_OVERFLOW = 64;
	public const uint32 WBF_LEVEL1 = 128;
	public const uint32 WBF_LEVEL2 = 256;
	public const uint32 WBF_CUSTOM = 512;
	public const uint32 IMF_FORCENONE = 1;
	public const uint32 IMF_FORCEENABLE = 2;
	public const uint32 IMF_FORCEDISABLE = 4;
	public const uint32 IMF_CLOSESTATUSWINDOW = 8;
	public const uint32 IMF_VERTICAL = 32;
	public const uint32 IMF_FORCEACTIVE = 64;
	public const uint32 IMF_FORCEINACTIVE = 128;
	public const uint32 IMF_FORCEREMEMBER = 256;
	public const uint32 IMF_MULTIPLEEDIT = 1024;
	public const uint32 yHeightCharPtsMost = 1638;
	public const uint32 SCF_SELECTION = 1;
	public const uint32 SCF_WORD = 2;
	public const uint32 SCF_DEFAULT = 0;
	public const uint32 SCF_ALL = 4;
	public const uint32 SCF_USEUIRULES = 8;
	public const uint32 SCF_ASSOCIATEFONT = 16;
	public const uint32 SCF_NOKBUPDATE = 32;
	public const uint32 SCF_ASSOCIATEFONT2 = 64;
	public const uint32 SCF_SMARTFONT = 128;
	public const uint32 SCF_CHARREPFROMLCID = 256;
	public const uint32 SPF_DONTSETDEFAULT = 2;
	public const uint32 SPF_SETDEFAULT = 4;
	public const uint32 SF_TEXT = 1;
	public const uint32 SF_RTF = 2;
	public const uint32 SF_RTFNOOBJS = 3;
	public const uint32 SF_TEXTIZED = 4;
	public const uint32 SF_UNICODE = 16;
	public const uint32 SF_USECODEPAGE = 32;
	public const uint32 SF_NCRFORNONASCII = 64;
	public const uint32 SFF_WRITEXTRAPAR = 128;
	public const uint32 SFF_SELECTION = 32768;
	public const uint32 SFF_PLAINRTF = 16384;
	public const uint32 SFF_PERSISTVIEWSCALE = 8192;
	public const uint32 SFF_KEEPDOCINFO = 4096;
	public const uint32 SFF_PWD = 2048;
	public const uint32 SF_RTFVAL = 1792;
	public const uint32 MAX_TAB_STOPS = 32;
	public const uint32 lDefaultTab = 720;
	public const uint32 MAX_TABLE_CELLS = 63;
	public const uint32 PFM_SPACEBEFORE = 64;
	public const uint32 PFM_SPACEAFTER = 128;
	public const uint32 PFM_LINESPACING = 256;
	public const uint32 PFM_STYLE = 1024;
	public const uint32 PFM_BORDER = 2048;
	public const uint32 PFM_SHADING = 4096;
	public const uint32 PFM_NUMBERINGSTYLE = 8192;
	public const uint32 PFM_NUMBERINGTAB = 16384;
	public const uint32 PFM_NUMBERINGSTART = 32768;
	public const uint32 PFM_KEEP = 131072;
	public const uint32 PFM_KEEPNEXT = 262144;
	public const uint32 PFM_PAGEBREAKBEFORE = 524288;
	public const uint32 PFM_NOLINENUMBER = 1048576;
	public const uint32 PFM_NOWIDOWCONTROL = 2097152;
	public const uint32 PFM_DONOTHYPHEN = 4194304;
	public const uint32 PFM_SIDEBYSIDE = 8388608;
	public const uint32 PFM_COLLAPSED = 16777216;
	public const uint32 PFM_OUTLINELEVEL = 33554432;
	public const uint32 PFM_BOX = 67108864;
	public const uint32 PFM_RESERVED2 = 134217728;
	public const uint32 PFM_TABLEROWDELIMITER = 268435456;
	public const uint32 PFM_TEXTWRAPPINGBREAK = 536870912;
	public const uint32 PFM_TABLE = 1073741824;
	public const uint32 PFA_JUSTIFY = 4;
	public const uint32 PFA_FULL_INTERWORD = 4;
	public const uint32 GCMF_GRIPPER = 1;
	public const uint32 GCMF_SPELLING = 2;
	public const uint32 GCMF_TOUCHMENU = 16384;
	public const uint32 GCMF_MOUSEMENU = 8192;
	public const uint32 OLEOP_DOVERB = 1;
	public const String CF_RTF = "Rich Text Format";
	public const String CF_RTFNOOBJS = "Rich Text Format Without Objects";
	public const String CF_RETEXTOBJ = "RichEdit Text and Objects";
	public const uint32 ST_DEFAULT = 0;
	public const uint32 ST_KEEPUNDO = 1;
	public const uint32 ST_SELECTION = 2;
	public const uint32 ST_NEWCHARS = 4;
	public const uint32 ST_UNICODE = 8;
	public const uint32 BOM_DEFPARADIR = 1;
	public const uint32 BOM_PLAINTEXT = 2;
	public const uint32 BOM_NEUTRALOVERRIDE = 4;
	public const uint32 BOM_CONTEXTREADING = 8;
	public const uint32 BOM_CONTEXTALIGNMENT = 16;
	public const uint32 BOM_LEGACYBIDICLASS = 64;
	public const uint32 BOM_UNICODEBIDI = 128;
	public const uint32 BOE_RTLDIR = 1;
	public const uint32 BOE_PLAINTEXT = 2;
	public const uint32 BOE_NEUTRALOVERRIDE = 4;
	public const uint32 BOE_CONTEXTREADING = 8;
	public const uint32 BOE_CONTEXTALIGNMENT = 16;
	public const uint32 BOE_FORCERECALC = 32;
	public const uint32 BOE_LEGACYBIDICLASS = 64;
	public const uint32 BOE_UNICODEBIDI = 128;
	public const uint32 FR_MATCHDIAC = 536870912;
	public const uint32 FR_MATCHKASHIDA = 1073741824;
	public const uint32 FR_MATCHALEFHAMZA = 2147483648;
	public const String RICHEDIT60_CLASS = "RICHEDIT60W";
	public const uint32 PFA_FULL_NEWSPAPER = 5;
	public const uint32 PFA_FULL_INTERLETTER = 6;
	public const uint32 PFA_FULL_SCALED = 7;
	public const uint32 PFA_FULL_GLYPHS = 8;
	public const uint32 AURL_ENABLEEA = 1;
	public const uint32 GCM_TOUCHMENU = 16384;
	public const uint32 GCM_MOUSEMENU = 8192;
	public const HRESULT S_MSG_KEY_IGNORED = 262657;
	public const uint32 TXTBIT_RICHTEXT = 1;
	public const uint32 TXTBIT_MULTILINE = 2;
	public const uint32 TXTBIT_READONLY = 4;
	public const uint32 TXTBIT_SHOWACCELERATOR = 8;
	public const uint32 TXTBIT_USEPASSWORD = 16;
	public const uint32 TXTBIT_HIDESELECTION = 32;
	public const uint32 TXTBIT_SAVESELECTION = 64;
	public const uint32 TXTBIT_AUTOWORDSEL = 128;
	public const uint32 TXTBIT_VERTICAL = 256;
	public const uint32 TXTBIT_SELBARCHANGE = 512;
	public const uint32 TXTBIT_WORDWRAP = 1024;
	public const uint32 TXTBIT_ALLOWBEEP = 2048;
	public const uint32 TXTBIT_DISABLEDRAG = 4096;
	public const uint32 TXTBIT_VIEWINSETCHANGE = 8192;
	public const uint32 TXTBIT_BACKSTYLECHANGE = 16384;
	public const uint32 TXTBIT_MAXLENGTHCHANGE = 32768;
	public const uint32 TXTBIT_SCROLLBARCHANGE = 65536;
	public const uint32 TXTBIT_CHARFORMATCHANGE = 131072;
	public const uint32 TXTBIT_PARAFORMATCHANGE = 262144;
	public const uint32 TXTBIT_EXTENTCHANGE = 524288;
	public const uint32 TXTBIT_CLIENTRECTCHANGE = 1048576;
	public const uint32 TXTBIT_USECURRENTBKG = 2097152;
	public const uint32 TXTBIT_NOTHREADREFCOUNT = 4194304;
	public const uint32 TXTBIT_SHOWPASSWORD = 8388608;
	public const uint32 TXTBIT_D2DDWRITE = 16777216;
	public const uint32 TXTBIT_D2DSIMPLETYPOGRAPHY = 33554432;
	public const uint32 TXTBIT_D2DPIXELSNAPPED = 67108864;
	public const uint32 TXTBIT_D2DSUBPIXELLINES = 134217728;
	public const uint32 TXTBIT_FLASHLASTPASSWORDCHAR = 268435456;
	public const uint32 TXTBIT_ADVANCEDINPUT = 536870912;
	public const uint32 TXES_ISDIALOG = 1;
	public const int32 REO_NULL = 0;
	public const int32 REO_READWRITEMASK = 2047;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CFM_MASK : uint32
{
	CFM_SUBSCRIPT = 196608,
	CFM_SUPERSCRIPT = 196608,
	CFM_EFFECTS = 1073741887,
	CFM_ALL = 4160749631,
	CFM_BOLD = 1,
	CFM_CHARSET = 134217728,
	CFM_COLOR = 1073741824,
	CFM_FACE = 536870912,
	CFM_ITALIC = 2,
	CFM_OFFSET = 268435456,
	CFM_PROTECTED = 16,
	CFM_SIZE = 2147483648,
	CFM_STRIKEOUT = 8,
	CFM_UNDERLINE = 4,
	CFM_LINK = 32,
	CFM_SMALLCAPS = 64,
	CFM_ALLCAPS = 128,
	CFM_HIDDEN = 256,
	CFM_OUTLINE = 512,
	CFM_SHADOW = 1024,
	CFM_EMBOSS = 2048,
	CFM_IMPRINT = 4096,
	CFM_DISABLED = 8192,
	CFM_REVISED = 16384,
	CFM_REVAUTHOR = 32768,
	CFM_ANIMATION = 262144,
	CFM_STYLE = 524288,
	CFM_KERNING = 1048576,
	CFM_SPACING = 2097152,
	CFM_WEIGHT = 4194304,
	CFM_UNDERLINETYPE = 8388608,
	CFM_COOKIE = 16777216,
	CFM_LCID = 33554432,
	CFM_BACKCOLOR = 67108864,
	CFM_EFFECTS2 = 1141080063,
	CFM_ALL2 = 4294967295,
	CFM_FONTBOUND = 1048576,
	CFM_LINKPROTECTED = 8388608,
	CFM_EXTENDED = 33554432,
	CFM_MATHNOBUILDUP = 134217728,
	CFM_MATH = 268435456,
	CFM_MATHORDINARY = 536870912,
	CFM_ALLEFFECTS = 2115207167,
}


[AllowDuplicates]
public enum CFE_EFFECTS : uint32
{
	CFE_ALLCAPS = 128,
	CFE_AUTOBACKCOLOR = 67108864,
	CFE_DISABLED = 8192,
	CFE_EMBOSS = 2048,
	CFE_HIDDEN = 256,
	CFE_IMPRINT = 4096,
	CFE_OUTLINE = 512,
	CFE_REVISED = 16384,
	CFE_SHADOW = 1024,
	CFE_SMALLCAPS = 64,
	CFE_AUTOCOLOR = 1073741824,
	CFE_BOLD = 1,
	CFE_ITALIC = 2,
	CFE_STRIKEOUT = 8,
	CFE_UNDERLINE = 4,
	CFE_PROTECTED = 16,
	CFE_LINK = 32,
	CFE_SUBSCRIPT = 65536,
	CFE_SUPERSCRIPT = 131072,
	CFE_FONTBOUND = 1048576,
	CFE_LINKPROTECTED = 8388608,
	CFE_EXTENDED = 33554432,
	CFE_MATHNOBUILDUP = 134217728,
	CFE_MATH = 268435456,
	CFE_MATHORDINARY = 536870912,
}


[AllowDuplicates]
public enum PARAFORMAT_MASK : uint32
{
	PFM_ALIGNMENT = 8,
	PFM_NUMBERING = 32,
	PFM_OFFSET = 4,
	PFM_OFFSETINDENT = 2147483648,
	PFM_RIGHTINDENT = 2,
	PFM_RTLPARA = 65536,
	PFM_STARTINDENT = 1,
	PFM_TABSTOPS = 16,
}


[AllowDuplicates]
public enum RICH_EDIT_GET_CONTEXT_MENU_SEL_TYPE : uint16
{
	SEL_EMPTY = 0,
	SEL_TEXT = 1,
	SEL_OBJECT = 2,
	SEL_MULTICHAR = 4,
	SEL_MULTIOBJECT = 8,
	GCM_RIGHTMOUSEDROP = 32768,
}


[AllowDuplicates]
public enum RICH_EDIT_GET_OBJECT_FLAGS : uint32
{
	REO_GETOBJ_POLEOBJ = 1,
	REO_GETOBJ_PSTG = 2,
	REO_GETOBJ_POLESITE = 4,
	REO_GETOBJ_NO_INTERFACES = 0,
	REO_GETOBJ_ALL_INTERFACES = 7,
}


[AllowDuplicates]
public enum PARAFORMAT_BORDERS : uint16
{
	PARAFORMAT_BORDERS_LEFT = 1,
	PARAFORMAT_BORDERS_RIGHT = 2,
	PARAFORMAT_BORDERS_TOP = 4,
	PARAFORMAT_BORDERS_BOTTOM = 8,
	PARAFORMAT_BORDERS_INSIDE = 16,
	PARAFORMAT_BORDERS_OUTSIDE = 32,
	PARAFORMAT_BORDERS_AUTOCOLOR = 64,
}


[AllowDuplicates]
public enum PARAFORMAT_SHADING_STYLE : uint16
{
	PARAFORMAT_SHADING_STYLE_NONE = 0,
	PARAFORMAT_SHADING_STYLE_DARK_HORIZ = 1,
	PARAFORMAT_SHADING_STYLE_DARK_VERT = 2,
	PARAFORMAT_SHADING_STYLE_DARK_DOWN_DIAG = 3,
	PARAFORMAT_SHADING_STYLE_DARK_UP_DIAG = 4,
	PARAFORMAT_SHADING_STYLE_DARK_GRID = 5,
	PARAFORMAT_SHADING_STYLE_DARK_TRELLIS = 6,
	PARAFORMAT_SHADING_STYLE_LIGHT_HORZ = 7,
	PARAFORMAT_SHADING_STYLE_LIGHT_VERT = 8,
	PARAFORMAT_SHADING_STYLE_LIGHT_DOWN_DIAG = 9,
	PARAFORMAT_SHADING_STYLE_LIGHT_UP_DIAG = 10,
	PARAFORMAT_SHADING_STYLE_LIGHT_GRID = 11,
	PARAFORMAT_SHADING_STYLE_LIGHT_TRELLIS = 12,
}


[AllowDuplicates]
public enum GETTEXTEX_FLAGS : uint32
{
	GT_DEFAULT = 0,
	GT_NOHIDDENTEXT = 8,
	GT_RAWTEXT = 4,
	GT_SELECTION = 2,
	GT_USECRLF = 1,
}


[AllowDuplicates]
public enum ENDCOMPOSITIONNOTIFY_CODE : uint32
{
	ECN_ENDCOMPOSITION = 1,
	ECN_NEWTEXT = 2,
}


[AllowDuplicates]
public enum IMECOMPTEXT_FLAGS : uint32
{
	ICT_RESULTREADSTR = 1,
}


[AllowDuplicates]
public enum GETTEXTLENGTHEX_FLAGS : uint32
{
	GTL_DEFAULT = 0,
	GTL_USECRLF = 1,
	GTL_PRECISE = 2,
	GTL_CLOSE = 4,
	GTL_NUMCHARS = 8,
	GTL_NUMBYTES = 16,
}


[AllowDuplicates]
public enum REOBJECT_FLAGS : uint32
{
	REO_ALIGNTORIGHT = 256,
	REO_BELOWBASELINE = 2,
	REO_BLANK = 16,
	REO_CANROTATE = 128,
	REO_DONTNEEDPALETTE = 32,
	REO_DYNAMICSIZE = 8,
	REO_GETMETAFILE = 4194304,
	REO_HILITED = 16777216,
	REO_INPLACEACTIVE = 33554432,
	REO_INVERTEDSELECT = 4,
	REO_LINK = 2147483648,
	REO_LINKAVAILABLE = 8388608,
	REO_OPEN = 67108864,
	REO_OWNERDRAWSELECT = 64,
	REO_RESIZABLE = 1,
	REO_SELECTED = 134217728,
	REO_STATIC = 1073741824,
	REO_USEASBACKGROUND = 1024,
	REO_WRAPTEXTAROUND = 512,
}


[AllowDuplicates]
public enum PARAFORMAT_NUMBERING_STYLE : uint16
{
	PFNS_PAREN = 0,
	PFNS_PARENS = 256,
	PFNS_PERIOD = 512,
	PFNS_PLAIN = 768,
	PFNS_NONUMBER = 1024,
	PFNS_NEWNUMBER = 32768,
}


[AllowDuplicates]
public enum PARAFORMAT_ALIGNMENT : uint16
{
	PFA_CENTER = 3,
	PFA_LEFT = 1,
	PFA_RIGHT = 2,
}


[AllowDuplicates]
public enum PARAFORMAT_NUMBERING : uint16
{
	PFN_BULLET = 1,
	PFN_ARABIC = 2,
	PFN_LCLETTER = 3,
	PFN_UCLETTER = 4,
	PFN_LCROMAN = 5,
	PFN_UCROMAN = 6,
}


[AllowDuplicates]
public enum TEXTMODE : int32
{
	TM_PLAINTEXT = 1,
	TM_RICHTEXT = 2,
	TM_SINGLELEVELUNDO = 4,
	TM_MULTILEVELUNDO = 8,
	TM_SINGLECODEPAGE = 16,
	TM_MULTICODEPAGE = 32,
}


[AllowDuplicates]
public enum UNDONAMEID : int32
{
	UID_UNKNOWN = 0,
	UID_TYPING = 1,
	UID_DELETE = 2,
	UID_DRAGDROP = 3,
	UID_CUT = 4,
	UID_PASTE = 5,
	UID_AUTOTABLE = 6,
}


[AllowDuplicates]
public enum KHYPH : int32
{
	khyphNil = 0,
	khyphNormal = 1,
	khyphAddBefore = 2,
	khyphChangeBefore = 3,
	khyphDeleteBefore = 4,
	khyphChangeAfter = 5,
	khyphDelAndChange = 6,
}


[AllowDuplicates]
public enum TXTBACKSTYLE : int32
{
	TXTBACK_TRANSPARENT = 0,
	TXTBACK_OPAQUE = 1,
}


[AllowDuplicates]
public enum TXTHITRESULT : int32
{
	TXTHITRESULT_NOHIT = 0,
	TXTHITRESULT_TRANSPARENT = 1,
	TXTHITRESULT_CLOSE = 2,
	TXTHITRESULT_HIT = 3,
}


[AllowDuplicates]
public enum TXTNATURALSIZE : int32
{
	TXTNS_FITTOCONTENT2 = 0,
	TXTNS_FITTOCONTENT = 1,
	TXTNS_ROUNDTOLINE = 2,
	TXTNS_FITTOCONTENT3 = 3,
	TXTNS_FITTOCONTENTWSP = 4,
	TXTNS_INCLUDELASTLINE = 1073741824,
	TXTNS_EMU = -2147483648,
}


[AllowDuplicates]
public enum TXTVIEW : int32
{
	TXTVIEW_ACTIVE = 0,
	TXTVIEW_INACTIVE = -1,
}


[AllowDuplicates]
public enum CHANGETYPE : int32
{
	CN_GENERIC = 0,
	CN_TEXTCHANGED = 1,
	CN_NEWUNDO = 2,
	CN_NEWREDO = 4,
}


[AllowDuplicates]
public enum CARET_FLAGS : int32
{
	CARET_NONE = 0,
	CARET_CUSTOM = 1,
	CARET_RTL = 2,
	CARET_ITALIC = 32,
	CARET_NULL = 64,
	CARET_ROTATE90 = 128,
}


[AllowDuplicates]
public enum tomConstants : int32
{
	tomFalse = 0,
	tomTrue = -1,
	tomUndefined = -9999999,
	tomToggle = -9999998,
	tomAutoColor = -9999997,
	tomDefault = -9999996,
	tomSuspend = -9999995,
	tomResume = -9999994,
	tomApplyNow = 0,
	tomApplyLater = 1,
	tomTrackParms = 2,
	tomCacheParms = 3,
	tomApplyTmp = 4,
	tomDisableSmartFont = 8,
	tomEnableSmartFont = 9,
	tomUsePoints = 10,
	tomUseTwips = 11,
	tomBackward = -1073741823,
	tomForward = 1073741823,
	tomMove = 0,
	tomExtend = 1,
	tomNoSelection = 0,
	tomSelectionIP = 1,
	tomSelectionNormal = 2,
	tomSelectionFrame = 3,
	tomSelectionColumn = 4,
	tomSelectionRow = 5,
	tomSelectionBlock = 6,
	tomSelectionInlineShape = 7,
	tomSelectionShape = 8,
	tomSelStartActive = 1,
	tomSelAtEOL = 2,
	tomSelOvertype = 4,
	tomSelActive = 8,
	tomSelReplace = 16,
	tomEnd = 0,
	tomStart = 32,
	tomCollapseEnd = 0,
	tomCollapseStart = 1,
	tomClientCoord = 256,
	tomAllowOffClient = 512,
	tomTransform = 1024,
	tomObjectArg = 2048,
	tomAtEnd = 4096,
	tomNone = 0,
	tomSingle = 1,
	tomWords = 2,
	tomDouble = 3,
	tomDotted = 4,
	tomDash = 5,
	tomDashDot = 6,
	tomDashDotDot = 7,
	tomWave = 8,
	tomThick = 9,
	tomHair = 10,
	tomDoubleWave = 11,
	tomHeavyWave = 12,
	tomLongDash = 13,
	tomThickDash = 14,
	tomThickDashDot = 15,
	tomThickDashDotDot = 16,
	tomThickDotted = 17,
	tomThickLongDash = 18,
	tomLineSpaceSingle = 0,
	tomLineSpace1pt5 = 1,
	tomLineSpaceDouble = 2,
	tomLineSpaceAtLeast = 3,
	tomLineSpaceExactly = 4,
	tomLineSpaceMultiple = 5,
	tomLineSpacePercent = 6,
	tomAlignLeft = 0,
	tomAlignCenter = 1,
	tomAlignRight = 2,
	tomAlignJustify = 3,
	tomAlignDecimal = 3,
	tomAlignBar = 4,
	tomDefaultTab = 5,
	tomAlignInterWord = 3,
	tomAlignNewspaper = 4,
	tomAlignInterLetter = 5,
	tomAlignScaled = 6,
	tomSpaces = 0,
	tomDots = 1,
	tomDashes = 2,
	tomLines = 3,
	tomThickLines = 4,
	tomEquals = 5,
	tomTabBack = -3,
	tomTabNext = -2,
	tomTabHere = -1,
	tomListNone = 0,
	tomListBullet = 1,
	tomListNumberAsArabic = 2,
	tomListNumberAsLCLetter = 3,
	tomListNumberAsUCLetter = 4,
	tomListNumberAsLCRoman = 5,
	tomListNumberAsUCRoman = 6,
	tomListNumberAsSequence = 7,
	tomListNumberedCircle = 8,
	tomListNumberedBlackCircleWingding = 9,
	tomListNumberedWhiteCircleWingding = 10,
	tomListNumberedArabicWide = 11,
	tomListNumberedChS = 12,
	tomListNumberedChT = 13,
	tomListNumberedJpnChS = 14,
	tomListNumberedJpnKor = 15,
	tomListNumberedArabic1 = 16,
	tomListNumberedArabic2 = 17,
	tomListNumberedHebrew = 18,
	tomListNumberedThaiAlpha = 19,
	tomListNumberedThaiNum = 20,
	tomListNumberedHindiAlpha = 21,
	tomListNumberedHindiAlpha1 = 22,
	tomListNumberedHindiNum = 23,
	tomListParentheses = 65536,
	tomListPeriod = 131072,
	tomListPlain = 196608,
	tomListNoNumber = 262144,
	tomListMinus = 524288,
	tomIgnoreNumberStyle = 16777216,
	tomParaStyleNormal = -1,
	tomParaStyleHeading1 = -2,
	tomParaStyleHeading2 = -3,
	tomParaStyleHeading3 = -4,
	tomParaStyleHeading4 = -5,
	tomParaStyleHeading5 = -6,
	tomParaStyleHeading6 = -7,
	tomParaStyleHeading7 = -8,
	tomParaStyleHeading8 = -9,
	tomParaStyleHeading9 = -10,
	tomCharacter = 1,
	tomWord = 2,
	tomSentence = 3,
	tomParagraph = 4,
	tomLine = 5,
	tomStory = 6,
	tomScreen = 7,
	tomSection = 8,
	tomTableColumn = 9,
	tomColumn = 9,
	tomRow = 10,
	tomWindow = 11,
	tomCell = 12,
	tomCharFormat = 13,
	tomParaFormat = 14,
	tomTable = 15,
	tomObject = 16,
	tomPage = 17,
	tomHardParagraph = 18,
	tomCluster = 19,
	tomInlineObject = 20,
	tomInlineObjectArg = 21,
	tomLeafLine = 22,
	tomLayoutColumn = 23,
	tomProcessId = 1073741825,
	tomMatchWord = 2,
	tomMatchCase = 4,
	tomMatchPattern = 8,
	tomUnknownStory = 0,
	tomMainTextStory = 1,
	tomFootnotesStory = 2,
	tomEndnotesStory = 3,
	tomCommentsStory = 4,
	tomTextFrameStory = 5,
	tomEvenPagesHeaderStory = 6,
	tomPrimaryHeaderStory = 7,
	tomEvenPagesFooterStory = 8,
	tomPrimaryFooterStory = 9,
	tomFirstPageHeaderStory = 10,
	tomFirstPageFooterStory = 11,
	tomScratchStory = 127,
	tomFindStory = 128,
	tomReplaceStory = 129,
	tomStoryInactive = 0,
	tomStoryActiveDisplay = 1,
	tomStoryActiveUI = 2,
	tomStoryActiveDisplayUI = 3,
	tomNoAnimation = 0,
	tomLasVegasLights = 1,
	tomBlinkingBackground = 2,
	tomSparkleText = 3,
	tomMarchingBlackAnts = 4,
	tomMarchingRedAnts = 5,
	tomShimmer = 6,
	tomWipeDown = 7,
	tomWipeRight = 8,
	tomAnimationMax = 8,
	tomLowerCase = 0,
	tomUpperCase = 1,
	tomTitleCase = 2,
	tomSentenceCase = 4,
	tomToggleCase = 5,
	tomReadOnly = 256,
	tomShareDenyRead = 512,
	tomShareDenyWrite = 1024,
	tomPasteFile = 4096,
	tomCreateNew = 16,
	tomCreateAlways = 32,
	tomOpenExisting = 48,
	tomOpenAlways = 64,
	tomTruncateExisting = 80,
	tomRTF = 1,
	tomText = 2,
	tomHTML = 3,
	tomWordDocument = 4,
	tomBold = -2147483647,
	tomItalic = -2147483646,
	tomUnderline = -2147483644,
	tomStrikeout = -2147483640,
	tomProtected = -2147483632,
	tomLink = -2147483616,
	tomSmallCaps = -2147483584,
	tomAllCaps = -2147483520,
	tomHidden = -2147483392,
	tomOutline = -2147483136,
	tomShadow = -2147482624,
	tomEmboss = -2147481600,
	tomImprint = -2147479552,
	tomDisabled = -2147475456,
	tomRevised = -2147467264,
	tomSubscriptCF = -2147418112,
	tomSuperscriptCF = -2147352576,
	tomFontBound = -2146435072,
	tomLinkProtected = -2139095040,
	tomInlineObjectStart = -2130706432,
	tomExtendedChar = -2113929216,
	tomAutoBackColor = -2080374784,
	tomMathZoneNoBuildUp = -2013265920,
	tomMathZone = -1879048192,
	tomMathZoneOrdinary = -1610612736,
	tomAutoTextColor = -1073741824,
	tomMathZoneDisplay = 262144,
	tomParaEffectRTL = 1,
	tomParaEffectKeep = 2,
	tomParaEffectKeepNext = 4,
	tomParaEffectPageBreakBefore = 8,
	tomParaEffectNoLineNumber = 16,
	tomParaEffectNoWidowControl = 32,
	tomParaEffectDoNotHyphen = 64,
	tomParaEffectSideBySide = 128,
	tomParaEffectCollapsed = 256,
	tomParaEffectOutlineLevel = 512,
	tomParaEffectBox = 1024,
	tomParaEffectTableRowDelimiter = 4096,
	tomParaEffectTable = 16384,
	tomModWidthPairs = 1,
	tomModWidthSpace = 2,
	tomAutoSpaceAlpha = 4,
	tomAutoSpaceNumeric = 8,
	tomAutoSpaceParens = 16,
	tomEmbeddedFont = 32,
	tomDoublestrike = 64,
	tomOverlapping = 128,
	tomNormalCaret = 0,
	tomKoreanBlockCaret = 1,
	tomNullCaret = 2,
	tomIncludeInset = 1,
	tomUnicodeBiDi = 1,
	tomMathCFCheck = 4,
	tomUnlink = 8,
	tomUnhide = 16,
	tomCheckTextLimit = 32,
	tomIgnoreCurrentFont = 0,
	tomMatchCharRep = 1,
	tomMatchFontSignature = 2,
	tomMatchAscii = 4,
	tomGetHeightOnly = 8,
	tomMatchMathFont = 16,
	tomCharset = -2147483648,
	tomCharRepFromLcid = 1073741824,
	tomAnsi = 0,
	tomEastEurope = 1,
	tomCyrillic = 2,
	tomGreek = 3,
	tomTurkish = 4,
	tomHebrew = 5,
	tomArabic = 6,
	tomBaltic = 7,
	tomVietnamese = 8,
	tomDefaultCharRep = 9,
	tomSymbol = 10,
	tomThai = 11,
	tomShiftJIS = 12,
	tomGB2312 = 13,
	tomHangul = 14,
	tomBIG5 = 15,
	tomPC437 = 16,
	tomOEM = 17,
	tomMac = 18,
	tomArmenian = 19,
	tomSyriac = 20,
	tomThaana = 21,
	tomDevanagari = 22,
	tomBengali = 23,
	tomGurmukhi = 24,
	tomGujarati = 25,
	tomOriya = 26,
	tomTamil = 27,
	tomTelugu = 28,
	tomKannada = 29,
	tomMalayalam = 30,
	tomSinhala = 31,
	tomLao = 32,
	tomTibetan = 33,
	tomMyanmar = 34,
	tomGeorgian = 35,
	tomJamo = 36,
	tomEthiopic = 37,
	tomCherokee = 38,
	tomAboriginal = 39,
	tomOgham = 40,
	tomRunic = 41,
	tomKhmer = 42,
	tomMongolian = 43,
	tomBraille = 44,
	tomYi = 45,
	tomLimbu = 46,
	tomTaiLe = 47,
	tomNewTaiLue = 48,
	tomSylotiNagri = 49,
	tomKharoshthi = 50,
	tomKayahli = 51,
	tomUsymbol = 52,
	tomEmoji = 53,
	tomGlagolitic = 54,
	tomLisu = 55,
	tomVai = 56,
	tomNKo = 57,
	tomOsmanya = 58,
	tomPhagsPa = 59,
	tomGothic = 60,
	tomDeseret = 61,
	tomTifinagh = 62,
	tomCharRepMax = 63,
	tomRE10Mode = 1,
	tomUseAtFont = 2,
	tomTextFlowMask = 12,
	tomTextFlowES = 0,
	tomTextFlowSW = 4,
	tomTextFlowWN = 8,
	tomTextFlowNE = 12,
	tomNoIME = 524288,
	tomSelfIME = 262144,
	tomNoUpScroll = 65536,
	tomNoVpScroll = 262144,
	tomNoLink = 0,
	tomClientLink = 1,
	tomFriendlyLinkName = 2,
	tomFriendlyLinkAddress = 3,
	tomAutoLinkURL = 4,
	tomAutoLinkEmail = 5,
	tomAutoLinkPhone = 6,
	tomAutoLinkPath = 7,
	tomCompressNone = 0,
	tomCompressPunctuation = 1,
	tomCompressPunctuationAndKana = 2,
	tomCompressMax = 2,
	tomUnderlinePositionAuto = 0,
	tomUnderlinePositionBelow = 1,
	tomUnderlinePositionAbove = 2,
	tomUnderlinePositionMax = 2,
	tomFontAlignmentAuto = 0,
	tomFontAlignmentTop = 1,
	tomFontAlignmentBaseline = 2,
	tomFontAlignmentBottom = 3,
	tomFontAlignmentCenter = 4,
	tomFontAlignmentMax = 4,
	tomRubyBelow = 128,
	tomRubyAlignCenter = 0,
	tomRubyAlign010 = 1,
	tomRubyAlign121 = 2,
	tomRubyAlignLeft = 3,
	tomRubyAlignRight = 4,
	tomLimitsDefault = 0,
	tomLimitsUnderOver = 1,
	tomLimitsSubSup = 2,
	tomUpperLimitAsSuperScript = 3,
	tomLimitsOpposite = 4,
	tomShowLLimPlaceHldr = 8,
	tomShowULimPlaceHldr = 16,
	tomDontGrowWithContent = 64,
	tomGrowWithContent = 128,
	tomSubSupAlign = 1,
	tomLimitAlignMask = 3,
	tomLimitAlignCenter = 0,
	tomLimitAlignLeft = 1,
	tomLimitAlignRight = 2,
	tomShowDegPlaceHldr = 8,
	tomAlignDefault = 0,
	tomAlignMatchAscentDescent = 2,
	tomMathVariant = 32,
	tomStyleDefault = 0,
	tomStyleScriptScriptCramped = 1,
	tomStyleScriptScript = 2,
	tomStyleScriptCramped = 3,
	tomStyleScript = 4,
	tomStyleTextCramped = 5,
	tomStyleText = 6,
	tomStyleDisplayCramped = 7,
	tomStyleDisplay = 8,
	tomMathRelSize = 64,
	tomDecDecSize = 254,
	tomDecSize = 255,
	tomIncSize = 65,
	tomIncIncSize = 66,
	tomGravityUI = 0,
	tomGravityBack = 1,
	tomGravityFore = 2,
	tomGravityIn = 3,
	tomGravityOut = 4,
	tomGravityBackward = 536870912,
	tomGravityForward = 1073741824,
	tomAdjustCRLF = 1,
	tomUseCRLF = 2,
	tomTextize = 4,
	tomAllowFinalEOP = 8,
	tomFoldMathAlpha = 16,
	tomNoHidden = 32,
	tomIncludeNumbering = 64,
	tomTranslateTableCell = 128,
	tomNoMathZoneBrackets = 256,
	tomConvertMathChar = 512,
	tomNoUCGreekItalic = 1024,
	tomAllowMathBold = 2048,
	tomLanguageTag = 4096,
	tomConvertRTF = 8192,
	tomApplyRtfDocProps = 16384,
	tomPhantomShow = 1,
	tomPhantomZeroWidth = 2,
	tomPhantomZeroAscent = 4,
	tomPhantomZeroDescent = 8,
	tomPhantomTransparent = 16,
	tomPhantomASmash = 5,
	tomPhantomDSmash = 9,
	tomPhantomHSmash = 3,
	tomPhantomSmash = 13,
	tomPhantomHorz = 12,
	tomPhantomVert = 2,
	tomBoxHideTop = 1,
	tomBoxHideBottom = 2,
	tomBoxHideLeft = 4,
	tomBoxHideRight = 8,
	tomBoxStrikeH = 16,
	tomBoxStrikeV = 32,
	tomBoxStrikeTLBR = 64,
	tomBoxStrikeBLTR = 128,
	tomBoxAlignCenter = 1,
	tomSpaceMask = 28,
	tomSpaceDefault = 0,
	tomSpaceUnary = 4,
	tomSpaceBinary = 8,
	tomSpaceRelational = 12,
	tomSpaceSkip = 16,
	tomSpaceOrd = 20,
	tomSpaceDifferential = 24,
	tomSizeText = 32,
	tomSizeScript = 64,
	tomSizeScriptScript = 96,
	tomNoBreak = 128,
	tomTransparentForPositioning = 256,
	tomTransparentForSpacing = 512,
	tomStretchCharBelow = 0,
	tomStretchCharAbove = 1,
	tomStretchBaseBelow = 2,
	tomStretchBaseAbove = 3,
	tomMatrixAlignMask = 3,
	tomMatrixAlignCenter = 0,
	tomMatrixAlignTopRow = 1,
	tomMatrixAlignBottomRow = 3,
	tomShowMatPlaceHldr = 8,
	tomEqArrayLayoutWidth = 1,
	tomEqArrayAlignMask = 12,
	tomEqArrayAlignCenter = 0,
	tomEqArrayAlignTopRow = 4,
	tomEqArrayAlignBottomRow = 12,
	tomMathManualBreakMask = 127,
	tomMathBreakLeft = 125,
	tomMathBreakCenter = 126,
	tomMathBreakRight = 127,
	tomMathEqAlign = 128,
	tomMathArgShadingStart = 593,
	tomMathArgShadingEnd = 594,
	tomMathObjShadingStart = 595,
	tomMathObjShadingEnd = 596,
	tomFunctionTypeNone = 0,
	tomFunctionTypeTakesArg = 1,
	tomFunctionTypeTakesLim = 2,
	tomFunctionTypeTakesLim2 = 3,
	tomFunctionTypeIsLim = 4,
	tomMathParaAlignDefault = 0,
	tomMathParaAlignCenterGroup = 1,
	tomMathParaAlignCenter = 2,
	tomMathParaAlignLeft = 3,
	tomMathParaAlignRight = 4,
	tomMathDispAlignMask = 3,
	tomMathDispAlignCenterGroup = 0,
	tomMathDispAlignCenter = 1,
	tomMathDispAlignLeft = 2,
	tomMathDispAlignRight = 3,
	tomMathDispIntUnderOver = 4,
	tomMathDispFracTeX = 8,
	tomMathDispNaryGrow = 16,
	tomMathDocEmptyArgMask = 96,
	tomMathDocEmptyArgAuto = 0,
	tomMathDocEmptyArgAlways = 32,
	tomMathDocEmptyArgNever = 64,
	tomMathDocSbSpOpUnchanged = 128,
	tomMathDocDiffMask = 768,
	tomMathDocDiffDefault = 0,
	tomMathDocDiffUpright = 256,
	tomMathDocDiffItalic = 512,
	tomMathDocDiffOpenItalic = 768,
	tomMathDispNarySubSup = 1024,
	tomMathDispDef = 2048,
	tomMathEnableRtl = 4096,
	tomMathBrkBinMask = 196608,
	tomMathBrkBinBefore = 0,
	tomMathBrkBinAfter = 65536,
	tomMathBrkBinDup = 131072,
	tomMathBrkBinSubMask = 786432,
	tomMathBrkBinSubMM = 0,
	tomMathBrkBinSubPM = 262144,
	tomMathBrkBinSubMP = 524288,
	tomSelRange = 597,
	tomHstring = 596,
	tomFontPropTeXStyle = 828,
	tomFontPropAlign = 829,
	tomFontStretch = 830,
	tomFontStyle = 831,
	tomFontStyleUpright = 0,
	tomFontStyleOblique = 1,
	tomFontStyleItalic = 2,
	tomFontStretchDefault = 0,
	tomFontStretchUltraCondensed = 1,
	tomFontStretchExtraCondensed = 2,
	tomFontStretchCondensed = 3,
	tomFontStretchSemiCondensed = 4,
	tomFontStretchNormal = 5,
	tomFontStretchSemiExpanded = 6,
	tomFontStretchExpanded = 7,
	tomFontStretchExtraExpanded = 8,
	tomFontStretchUltraExpanded = 9,
	tomFontWeightDefault = 0,
	tomFontWeightThin = 100,
	tomFontWeightExtraLight = 200,
	tomFontWeightLight = 300,
	tomFontWeightNormal = 400,
	tomFontWeightRegular = 400,
	tomFontWeightMedium = 500,
	tomFontWeightSemiBold = 600,
	tomFontWeightBold = 700,
	tomFontWeightExtraBold = 800,
	tomFontWeightBlack = 900,
	tomFontWeightHeavy = 900,
	tomFontWeightExtraBlack = 950,
	tomParaPropMathAlign = 1079,
	tomDocMathBuild = 128,
	tomMathLMargin = 129,
	tomMathRMargin = 130,
	tomMathWrapIndent = 131,
	tomMathWrapRight = 132,
	tomMathPostSpace = 134,
	tomMathPreSpace = 133,
	tomMathInterSpace = 135,
	tomMathIntraSpace = 136,
	tomCanCopy = 137,
	tomCanRedo = 138,
	tomCanUndo = 139,
	tomUndoLimit = 140,
	tomDocAutoLink = 141,
	tomEllipsisMode = 142,
	tomEllipsisState = 143,
	tomEllipsisNone = 0,
	tomEllipsisEnd = 1,
	tomEllipsisWord = 3,
	tomEllipsisPresent = 1,
	tomVTopCell = 1,
	tomVLowCell = 2,
	tomHStartCell = 4,
	tomHContCell = 8,
	tomRowUpdate = 1,
	tomRowApplyDefault = 0,
	tomCellStructureChangeOnly = 1,
	tomRowHeightActual = 2059,
}


[AllowDuplicates]
public enum OBJECTTYPE : int32
{
	tomSimpleText = 0,
	tomRuby = 1,
	tomHorzVert = 2,
	tomWarichu = 3,
	tomEq = 9,
	tomMath = 10,
	tomAccent = 10,
	tomBox = 11,
	tomBoxedFormula = 12,
	tomBrackets = 13,
	tomBracketsWithSeps = 14,
	tomEquationArray = 15,
	tomFraction = 16,
	tomFunctionApply = 17,
	tomLeftSubSup = 18,
	tomLowerLimit = 19,
	tomMatrix = 20,
	tomNary = 21,
	tomOpChar = 22,
	tomOverbar = 23,
	tomPhantom = 24,
	tomRadical = 25,
	tomSlashedFraction = 26,
	tomStack = 27,
	tomStretchStack = 28,
	tomSubscript = 29,
	tomSubSup = 30,
	tomSuperscript = 31,
	tomUnderbar = 32,
	tomUpperLimit = 33,
	tomObjectMax = 33,
}


[AllowDuplicates]
public enum MANCODE : int32
{
	MBOLD = 16,
	MITAL = 32,
	MGREEK = 64,
	MROMN = 0,
	MSCRP = 1,
	MFRAK = 2,
	MOPEN = 3,
	MSANS = 4,
	MMONO = 5,
	MMATH = 6,
	MISOL = 7,
	MINIT = 8,
	MTAIL = 9,
	MSTRCH = 10,
	MLOOP = 11,
	MOPENA = 12,
}

#endregion

#region Function Pointers
public function int32 AutoCorrectProc(uint16 langid, PWSTR pszBefore, PWSTR pszAfter, int32 cchAfter, int32* pcchReplaced);

public function int32 EDITWORDBREAKPROCEX(PSTR pchText, int32 cchText, uint8 bCharSet, int32 action);

public function uint32 EDITSTREAMCALLBACK(uint dwCookie, uint8* pbBuff, int32 cb, int32* pcb);

public function HRESULT PCreateTextServices(IUnknown* punkOuter, ITextHost* pITextHost, IUnknown** ppUnk);

public function HRESULT PShutdownTextServices(IUnknown* pTextServices);

#endregion

#region Structs
[CRepr]
public struct IMECOMPTEXT
{
	public int32 cb;
	public IMECOMPTEXT_FLAGS flags;
}

[CRepr]
public struct TABLEROWPARMS
{
	public uint8 cbRow;
	public uint8 cbCell;
	public uint8 cCell;
	public uint8 cRow;
	public int32 dxCellMargin;
	public int32 dxIndent;
	public int32 dyHeight;
	public uint32 _bitfield;
	public int32 cpStartRow;
	public uint8 bTableLevel;
	public uint8 iCell;
}

[CRepr]
public struct TABLECELLPARMS
{
	public int32 dxWidth;
	public uint16 _bitfield;
	public uint16 wShading;
	public int16 dxBrdrLeft;
	public int16 dyBrdrTop;
	public int16 dxBrdrRight;
	public int16 dyBrdrBottom;
	public COLORREF crBrdrLeft;
	public COLORREF crBrdrTop;
	public COLORREF crBrdrRight;
	public COLORREF crBrdrBottom;
	public COLORREF crBackPat;
	public COLORREF crForePat;
}

[CRepr, Packed(4)]
public struct RICHEDIT_IMAGE_PARAMETERS
{
	public int32 xWidth;
	public int32 yHeight;
	public int32 Ascent;
	public TEXT_ALIGN_OPTIONS Type;
	public PWSTR pwszAlternateText;
	public IStream* pIStream;
}

[CRepr, Packed(4)]
public struct ENDCOMPOSITIONNOTIFY
{
	public NMHDR nmhdr;
	public ENDCOMPOSITIONNOTIFY_CODE dwCode;
}

[CRepr]
public struct CHARFORMATA
{
	public uint32 cbSize;
	public CFM_MASK dwMask;
	public CFE_EFFECTS dwEffects;
	public int32 yHeight;
	public int32 yOffset;
	public COLORREF crTextColor;
	public EMBED_FONT_CHARSET bCharSet;
	public uint8 bPitchAndFamily;
	public CHAR[32] szFaceName;
}

[CRepr]
public struct CHARFORMATW
{
	public uint32 cbSize;
	public CFM_MASK dwMask;
	public CFE_EFFECTS dwEffects;
	public int32 yHeight;
	public int32 yOffset;
	public COLORREF crTextColor;
	public EMBED_FONT_CHARSET bCharSet;
	public uint8 bPitchAndFamily;
	public char16[32] szFaceName;
}

[CRepr]
public struct CHARFORMAT2W
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwReserved;
		public uint32 dwCookie;
	}
	public CHARFORMATW Base;
	public uint16 wWeight;
	public int16 sSpacing;
	public COLORREF crBackColor;
	public uint32 lcid;
	public using _Anonymous_e__Union Anonymous;
	public int16 sStyle;
	public uint16 wKerning;
	public uint8 bUnderlineType;
	public uint8 bAnimation;
	public uint8 bRevAuthor;
	public uint8 bUnderlineColor;
}

[CRepr]
public struct CHARFORMAT2A
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwReserved;
		public uint32 dwCookie;
	}
	public CHARFORMATA Base;
	public uint16 wWeight;
	public int16 sSpacing;
	public COLORREF crBackColor;
	public uint32 lcid;
	public using _Anonymous_e__Union Anonymous;
	public int16 sStyle;
	public uint16 wKerning;
	public uint8 bUnderlineType;
	public uint8 bAnimation;
	public uint8 bRevAuthor;
	public uint8 bUnderlineColor;
}

[CRepr]
public struct CHARRANGE
{
	public int32 cpMin;
	public int32 cpMax;
}

[CRepr, Packed(4)]
public struct TEXTRANGEA
{
	public CHARRANGE chrg;
	public PSTR lpstrText;
}

[CRepr, Packed(4)]
public struct TEXTRANGEW
{
	public CHARRANGE chrg;
	public PWSTR lpstrText;
}

[CRepr, Packed(4)]
public struct EDITSTREAM
{
	public uint dwCookie;
	public uint32 dwError;
	public EDITSTREAMCALLBACK pfnCallback;
}

[CRepr, Packed(4)]
public struct FINDTEXTA
{
	public CHARRANGE chrg;
	public PSTR lpstrText;
}

[CRepr, Packed(4)]
public struct FINDTEXTW
{
	public CHARRANGE chrg;
	public PWSTR lpstrText;
}

[CRepr, Packed(4)]
public struct FINDTEXTEXA
{
	public CHARRANGE chrg;
	public PSTR lpstrText;
	public CHARRANGE chrgText;
}

[CRepr, Packed(4)]
public struct FINDTEXTEXW
{
	public CHARRANGE chrg;
	public PWSTR lpstrText;
	public CHARRANGE chrgText;
}

[CRepr, Packed(4)]
public struct FORMATRANGE
{
	public HDC hdc;
	public HDC hdcTarget;
	public RECT rc;
	public RECT rcPage;
	public CHARRANGE chrg;
}

[CRepr]
public struct PARAFORMAT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 wReserved;
		public uint16 wEffects;
	}
	public uint32 cbSize;
	public PARAFORMAT_MASK dwMask;
	public PARAFORMAT_NUMBERING wNumbering;
	public using _Anonymous_e__Union Anonymous;
	public int32 dxStartIndent;
	public int32 dxRightIndent;
	public int32 dxOffset;
	public PARAFORMAT_ALIGNMENT wAlignment;
	public int16 cTabCount;
	public uint32[32] rgxTabs;
}

[CRepr]
public struct PARAFORMAT2
{
	public PARAFORMAT Base;
	public int32 dySpaceBefore;
	public int32 dySpaceAfter;
	public int32 dyLineSpacing;
	public int16 sStyle;
	public uint8 bLineSpacingRule;
	public uint8 bOutlineLevel;
	public uint16 wShadingWeight;
	public PARAFORMAT_SHADING_STYLE wShadingStyle;
	public uint16 wNumberingStart;
	public PARAFORMAT_NUMBERING_STYLE wNumberingStyle;
	public uint16 wNumberingTab;
	public uint16 wBorderSpace;
	public uint16 wBorderWidth;
	public PARAFORMAT_BORDERS wBorders;
}

[CRepr, Packed(4)]
public struct MSGFILTER
{
	public NMHDR nmhdr;
	public uint32 msg;
	public WPARAM wParam;
	public LPARAM lParam;
}

[CRepr, Packed(4)]
public struct REQRESIZE
{
	public NMHDR nmhdr;
	public RECT rc;
}

[CRepr, Packed(4)]
public struct SELCHANGE
{
	public NMHDR nmhdr;
	public CHARRANGE chrg;
	public RICH_EDIT_GET_CONTEXT_MENU_SEL_TYPE seltyp;
}

[CRepr, Packed(4)]
public struct GROUPTYPINGCHANGE
{
	public NMHDR nmhdr;
	public BOOL fGroupTyping;
}

[CRepr, Packed(4)]
public struct CLIPBOARDFORMAT
{
	public NMHDR nmhdr;
	public uint16 cf;
}

[CRepr, Packed(4)]
public struct GETCONTEXTMENUEX
{
	public CHARRANGE chrg;
	public uint32 dwFlags;
	public POINT pt;
	public void* pvReserved;
}

[CRepr, Packed(4)]
public struct ENDROPFILES
{
	public NMHDR nmhdr;
	public HANDLE hDrop;
	public int32 cp;
	public BOOL fProtected;
}

[CRepr, Packed(4)]
public struct ENPROTECTED
{
	public NMHDR nmhdr;
	public uint32 msg;
	public WPARAM wParam;
	public LPARAM lParam;
	public CHARRANGE chrg;
}

[CRepr, Packed(4)]
public struct ENSAVECLIPBOARD
{
	public NMHDR nmhdr;
	public int32 cObjectCount;
	public int32 cch;
}

[CRepr, Packed(4)]
public struct ENOLEOPFAILED
{
	public NMHDR nmhdr;
	public int32 iob;
	public int32 lOper;
	public HRESULT hr;
}

[CRepr, Packed(4)]
public struct OBJECTPOSITIONS
{
	public NMHDR nmhdr;
	public int32 cObjectCount;
	public int32* pcpPositions;
}

[CRepr, Packed(4)]
public struct ENLINK
{
	public NMHDR nmhdr;
	public uint32 msg;
	public WPARAM wParam;
	public LPARAM lParam;
	public CHARRANGE chrg;
}

[CRepr, Packed(4)]
public struct ENLOWFIRTF
{
	public NMHDR nmhdr;
	public PSTR szControl;
}

[CRepr, Packed(4)]
public struct ENCORRECTTEXT
{
	public NMHDR nmhdr;
	public CHARRANGE chrg;
	public RICH_EDIT_GET_CONTEXT_MENU_SEL_TYPE seltyp;
}

[CRepr, Packed(4)]
public struct PUNCTUATION
{
	public uint32 iSize;
	public PSTR szPunctuation;
}

[CRepr]
public struct COMPCOLOR
{
	public COLORREF crText;
	public COLORREF crBackground;
	public uint32 dwEffects;
}

[CRepr, Packed(4)]
public struct REPASTESPECIAL
{
	public DVASPECT dwAspect;
	public uint dwParam;
}

[CRepr]
public struct SETTEXTEX
{
	public uint32 flags;
	public uint32 codepage;
}

[CRepr, Packed(4)]
public struct GETTEXTEX
{
	public uint32 cb;
	public GETTEXTEX_FLAGS flags;
	public uint32 codepage;
	public PSTR lpDefaultChar;
	public int32* lpUsedDefChar;
}

[CRepr]
public struct GETTEXTLENGTHEX
{
	public GETTEXTLENGTHEX_FLAGS flags;
	public uint32 codepage;
}

[CRepr]
public struct BIDIOPTIONS
{
	public uint32 cbSize;
	public uint16 wMask;
	public uint16 wEffects;
}

[CRepr]
public struct HYPHRESULT
{
	public KHYPH khyph;
	public int32 ichHyph;
	public char16 chHyph;
}

[CRepr, Packed(4)]
public struct HYPHENATEINFO
{
	public int16 cbSize;
	public int16 dxHyphenateZone;
	public int pfnHyphenate;
}

[CRepr]
public struct CHANGENOTIFY
{
	public CHANGETYPE dwChangeType;
	public void* pvCookieData;
}

[CRepr, Union]
public struct CARET_INFO
{
	public HBITMAP hbitmap;
	public CARET_FLAGS caretFlags;
}

[CRepr]
public struct REOBJECT
{
	public uint32 cbStruct;
	public int32 cp;
	public Guid clsid;
	public IOleObject* poleobj;
	public IStorage* pstg;
	public IOleClientSite* polesite;
	public SIZE sizel;
	public uint32 dvaspect;
	public REOBJECT_FLAGS dwFlags;
	public uint32 dwUser;
}

#endregion

#region COM Types
[CRepr]struct ITextServices : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msg, WPARAM wparam, LPARAM lparam, LRESULT* plresult) TxSendMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcDraw, HDC hicTargetDev, RECTL* lprcBounds, RECTL* lprcWBounds, RECT* lprcUpdate, int pfnContinue, uint32 dwContinue, int32 lViewId) TxDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMin, int32* plMax, int32* plPos, int32* plPage, BOOL* pfEnabled) TxGetHScroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMin, int32* plMax, int32* plPos, int32* plPage, BOOL* pfEnabled) TxGetVScroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcDraw, HDC hicTargetDev, RECT* lprcClient, int32 x, int32 y) OnTxSetCursor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcDraw, HDC hicTargetDev, RECT* lprcClient, int32 x, int32 y, uint32* pHitResult) TxQueryHitPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcClient) OnTxInPlaceActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnTxInPlaceDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnTxUIActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnTxUIDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrText) TxGetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText) TxSetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) TxGetCurTargetX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) TxGetBaseLinePos;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAspect, HDC hdcDraw, HDC hicTargetDev, DVTARGETDEVICE* ptd, uint32 dwMode, SIZE* psizelExtent, int32* pwidth, int32* pheight) TxGetNaturalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDropTarget** ppDropTarget) TxGetDropTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMask, uint32 dwBits) OnTxPropertyBitsChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwWidth, uint32* pdwHeight) TxGetCachedSize;
	}


	public HRESULT TxSendMessage(uint32 msg, WPARAM wparam, LPARAM lparam, LRESULT* plresult) mut => VT.[Friend]TxSendMessage(&this, msg, wparam, lparam, plresult);

	public HRESULT TxDraw(DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcDraw, HDC hicTargetDev, RECTL* lprcBounds, RECTL* lprcWBounds, RECT* lprcUpdate, int pfnContinue, uint32 dwContinue, int32 lViewId) mut => VT.[Friend]TxDraw(&this, dwDrawAspect, lindex, pvAspect, ptd, hdcDraw, hicTargetDev, lprcBounds, lprcWBounds, lprcUpdate, pfnContinue, dwContinue, lViewId);

	public HRESULT TxGetHScroll(int32* plMin, int32* plMax, int32* plPos, int32* plPage, BOOL* pfEnabled) mut => VT.[Friend]TxGetHScroll(&this, plMin, plMax, plPos, plPage, pfEnabled);

	public HRESULT TxGetVScroll(int32* plMin, int32* plMax, int32* plPos, int32* plPage, BOOL* pfEnabled) mut => VT.[Friend]TxGetVScroll(&this, plMin, plMax, plPos, plPage, pfEnabled);

	public HRESULT OnTxSetCursor(DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcDraw, HDC hicTargetDev, RECT* lprcClient, int32 x, int32 y) mut => VT.[Friend]OnTxSetCursor(&this, dwDrawAspect, lindex, pvAspect, ptd, hdcDraw, hicTargetDev, lprcClient, x, y);

	public HRESULT TxQueryHitPoint(DVASPECT dwDrawAspect, int32 lindex, void* pvAspect, DVTARGETDEVICE* ptd, HDC hdcDraw, HDC hicTargetDev, RECT* lprcClient, int32 x, int32 y, uint32* pHitResult) mut => VT.[Friend]TxQueryHitPoint(&this, dwDrawAspect, lindex, pvAspect, ptd, hdcDraw, hicTargetDev, lprcClient, x, y, pHitResult);

	public HRESULT OnTxInPlaceActivate(RECT* prcClient) mut => VT.[Friend]OnTxInPlaceActivate(&this, prcClient);

	public HRESULT OnTxInPlaceDeactivate() mut => VT.[Friend]OnTxInPlaceDeactivate(&this);

	public HRESULT OnTxUIActivate() mut => VT.[Friend]OnTxUIActivate(&this);

	public HRESULT OnTxUIDeactivate() mut => VT.[Friend]OnTxUIDeactivate(&this);

	public HRESULT TxGetText(BSTR* pbstrText) mut => VT.[Friend]TxGetText(&this, pbstrText);

	public HRESULT TxSetText(PWSTR pszText) mut => VT.[Friend]TxSetText(&this, pszText);

	public HRESULT TxGetCurTargetX(int32* param0) mut => VT.[Friend]TxGetCurTargetX(&this, param0);

	public HRESULT TxGetBaseLinePos(int32* param0) mut => VT.[Friend]TxGetBaseLinePos(&this, param0);

	public HRESULT TxGetNaturalSize(uint32 dwAspect, HDC hdcDraw, HDC hicTargetDev, DVTARGETDEVICE* ptd, uint32 dwMode, SIZE* psizelExtent, int32* pwidth, int32* pheight) mut => VT.[Friend]TxGetNaturalSize(&this, dwAspect, hdcDraw, hicTargetDev, ptd, dwMode, psizelExtent, pwidth, pheight);

	public HRESULT TxGetDropTarget(IDropTarget** ppDropTarget) mut => VT.[Friend]TxGetDropTarget(&this, ppDropTarget);

	public HRESULT OnTxPropertyBitsChange(uint32 dwMask, uint32 dwBits) mut => VT.[Friend]OnTxPropertyBitsChange(&this, dwMask, dwBits);

	public HRESULT TxGetCachedSize(uint32* pdwWidth, uint32* pdwHeight) mut => VT.[Friend]TxGetCachedSize(&this, pdwWidth, pdwHeight);
}

[CRepr]struct ITextHost : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HDC(SelfOuter* self) TxGetDC;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, HDC hdc) TxReleaseDC;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, int32 fnBar, BOOL fShow) TxShowScrollBar;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, SCROLLBAR_CONSTANTS fuSBFlags, ENABLE_SCROLL_BAR_ARROWS fuArrowflags) TxEnableScrollBar;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, int32 fnBar, int32 nMinPos, int32 nMaxPos, BOOL fRedraw) TxSetScrollRange;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, int32 fnBar, int32 nPos, BOOL fRedraw) TxSetScrollPos;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, RECT* prc, BOOL fMode) TxInvalidateRect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BOOL fUpdate) TxViewChange;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, HBITMAP hbmp, int32 xWidth, int32 yHeight) TxCreateCaret;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, BOOL fShow) TxShowCaret;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, int32 x, int32 y) TxSetCaretPos;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, uint32 idTimer, uint32 uTimeout) TxSetTimer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 idTimer) TxKillTimer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 dx, int32 dy, RECT* lprcScroll, RECT* lprcClip, HRGN hrgnUpdate, RECT* lprcUpdate, SHOW_WINDOW_CMD fuScroll) TxScrollWindowEx;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BOOL fCapture) TxSetCapture;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) TxSetFocus;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, HCURSOR hcur, BOOL fText) TxSetCursor;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, POINT* lppt) TxScreenToClient;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, POINT* lppt) TxClientToScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plOldState) TxActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lNewState) TxDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) TxGetClientRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) TxGetViewInset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHARFORMATW** ppCF) TxGetCharFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PARAFORMAT** ppPF) TxGetParaFormat;
		protected new function [CallingConvention(.Stdcall)] COLORREF(SelfOuter* self, SYS_COLOR_INDEX nIndex) TxGetSysColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TXTBACKSTYLE* pstyle) TxGetBackStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* plength) TxGetMaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwScrollBar) TxGetScrollBars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* pch) TxGetPasswordChar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcp) TxGetAcceleratorPos;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* lpExtent) TxGetExtent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHARFORMATW* pCF) OnTxCharFormatChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PARAFORMAT* pPF) OnTxParaFormatChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMask, uint32* pdwBits) TxGetPropertyBits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iNotify, void* pv) TxNotify;
		protected new function [CallingConvention(.Stdcall)] HIMC(SelfOuter* self) TxImmGetContext;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, HIMC himc) TxImmReleaseContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lSelBarWidth) TxGetSelectionBarWidth;
	}


	public HDC TxGetDC() mut => VT.[Friend]TxGetDC(&this);

	public int32 TxReleaseDC(HDC hdc) mut => VT.[Friend]TxReleaseDC(&this, hdc);

	public BOOL TxShowScrollBar(int32 fnBar, BOOL fShow) mut => VT.[Friend]TxShowScrollBar(&this, fnBar, fShow);

	public BOOL TxEnableScrollBar(SCROLLBAR_CONSTANTS fuSBFlags, ENABLE_SCROLL_BAR_ARROWS fuArrowflags) mut => VT.[Friend]TxEnableScrollBar(&this, fuSBFlags, fuArrowflags);

	public BOOL TxSetScrollRange(int32 fnBar, int32 nMinPos, int32 nMaxPos, BOOL fRedraw) mut => VT.[Friend]TxSetScrollRange(&this, fnBar, nMinPos, nMaxPos, fRedraw);

	public BOOL TxSetScrollPos(int32 fnBar, int32 nPos, BOOL fRedraw) mut => VT.[Friend]TxSetScrollPos(&this, fnBar, nPos, fRedraw);

	public void TxInvalidateRect(RECT* prc, BOOL fMode) mut => VT.[Friend]TxInvalidateRect(&this, prc, fMode);

	public void TxViewChange(BOOL fUpdate) mut => VT.[Friend]TxViewChange(&this, fUpdate);

	public BOOL TxCreateCaret(HBITMAP hbmp, int32 xWidth, int32 yHeight) mut => VT.[Friend]TxCreateCaret(&this, hbmp, xWidth, yHeight);

	public BOOL TxShowCaret(BOOL fShow) mut => VT.[Friend]TxShowCaret(&this, fShow);

	public BOOL TxSetCaretPos(int32 x, int32 y) mut => VT.[Friend]TxSetCaretPos(&this, x, y);

	public BOOL TxSetTimer(uint32 idTimer, uint32 uTimeout) mut => VT.[Friend]TxSetTimer(&this, idTimer, uTimeout);

	public void TxKillTimer(uint32 idTimer) mut => VT.[Friend]TxKillTimer(&this, idTimer);

	public void TxScrollWindowEx(int32 dx, int32 dy, RECT* lprcScroll, RECT* lprcClip, HRGN hrgnUpdate, RECT* lprcUpdate, SHOW_WINDOW_CMD fuScroll) mut => VT.[Friend]TxScrollWindowEx(&this, dx, dy, lprcScroll, lprcClip, hrgnUpdate, lprcUpdate, fuScroll);

	public void TxSetCapture(BOOL fCapture) mut => VT.[Friend]TxSetCapture(&this, fCapture);

	public void TxSetFocus() mut => VT.[Friend]TxSetFocus(&this);

	public void TxSetCursor(HCURSOR hcur, BOOL fText) mut => VT.[Friend]TxSetCursor(&this, hcur, fText);

	public BOOL TxScreenToClient(POINT* lppt) mut => VT.[Friend]TxScreenToClient(&this, lppt);

	public BOOL TxClientToScreen(POINT* lppt) mut => VT.[Friend]TxClientToScreen(&this, lppt);

	public HRESULT TxActivate(int32* plOldState) mut => VT.[Friend]TxActivate(&this, plOldState);

	public HRESULT TxDeactivate(int32 lNewState) mut => VT.[Friend]TxDeactivate(&this, lNewState);

	public HRESULT TxGetClientRect(RECT* prc) mut => VT.[Friend]TxGetClientRect(&this, prc);

	public HRESULT TxGetViewInset(RECT* prc) mut => VT.[Friend]TxGetViewInset(&this, prc);

	public HRESULT TxGetCharFormat(CHARFORMATW** ppCF) mut => VT.[Friend]TxGetCharFormat(&this, ppCF);

	public HRESULT TxGetParaFormat(PARAFORMAT** ppPF) mut => VT.[Friend]TxGetParaFormat(&this, ppPF);

	public COLORREF TxGetSysColor(SYS_COLOR_INDEX nIndex) mut => VT.[Friend]TxGetSysColor(&this, nIndex);

	public HRESULT TxGetBackStyle(TXTBACKSTYLE* pstyle) mut => VT.[Friend]TxGetBackStyle(&this, pstyle);

	public HRESULT TxGetMaxLength(uint32* plength) mut => VT.[Friend]TxGetMaxLength(&this, plength);

	public HRESULT TxGetScrollBars(uint32* pdwScrollBar) mut => VT.[Friend]TxGetScrollBars(&this, pdwScrollBar);

	public HRESULT TxGetPasswordChar(int8* pch) mut => VT.[Friend]TxGetPasswordChar(&this, pch);

	public HRESULT TxGetAcceleratorPos(int32* pcp) mut => VT.[Friend]TxGetAcceleratorPos(&this, pcp);

	public HRESULT TxGetExtent(SIZE* lpExtent) mut => VT.[Friend]TxGetExtent(&this, lpExtent);

	public HRESULT OnTxCharFormatChange(CHARFORMATW* pCF) mut => VT.[Friend]OnTxCharFormatChange(&this, pCF);

	public HRESULT OnTxParaFormatChange(PARAFORMAT* pPF) mut => VT.[Friend]OnTxParaFormatChange(&this, pPF);

	public HRESULT TxGetPropertyBits(uint32 dwMask, uint32* pdwBits) mut => VT.[Friend]TxGetPropertyBits(&this, dwMask, pdwBits);

	public HRESULT TxNotify(uint32 iNotify, void* pv) mut => VT.[Friend]TxNotify(&this, iNotify, pv);

	public HIMC TxImmGetContext() mut => VT.[Friend]TxImmGetContext(&this);

	public void TxImmReleaseContext(HIMC himc) mut => VT.[Friend]TxImmReleaseContext(&this, himc);

	public HRESULT TxGetSelectionBarWidth(int32* lSelBarWidth) mut => VT.[Friend]TxGetSelectionBarWidth(&this, lSelBarWidth);
}

[CRepr]struct IRicheditUiaOverrides : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 propertyId, VARIANT* pRetValue) GetPropertyOverrideValue;
	}


	public HRESULT GetPropertyOverrideValue(int32 propertyId, VARIANT* pRetValue) mut => VT.[Friend]GetPropertyOverrideValue(&this, propertyId, pRetValue);
}

[CRepr]struct ITextHost2 : ITextHost
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextHost.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) TxIsDoubleClickPending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) TxGetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TxSetForegroundWindow;
		protected new function [CallingConvention(.Stdcall)] HPALETTE(SelfOuter* self) TxGetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pFlags) TxGetEastAsianFlags;
		protected new function [CallingConvention(.Stdcall)] HCURSOR(SelfOuter* self, HCURSOR hcur, BOOL bText) TxSetCursor2;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) TxFreeTextServicesNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwItem, uint32* pdwData) TxGetEditStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStyle, uint32* pdwExStyle) TxGetWindowStyles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow, HDC hdc, RECT* prc) TxShowDropCaret;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TxDestroyCaret;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHorzExtent) TxGetHorzExtent;
	}


	public BOOL TxIsDoubleClickPending() mut => VT.[Friend]TxIsDoubleClickPending(&this);

	public HRESULT TxGetWindow(HWND* phwnd) mut => VT.[Friend]TxGetWindow(&this, phwnd);

	public HRESULT TxSetForegroundWindow() mut => VT.[Friend]TxSetForegroundWindow(&this);

	public HPALETTE TxGetPalette() mut => VT.[Friend]TxGetPalette(&this);

	public HRESULT TxGetEastAsianFlags(int32* pFlags) mut => VT.[Friend]TxGetEastAsianFlags(&this, pFlags);

	public HCURSOR TxSetCursor2(HCURSOR hcur, BOOL bText) mut => VT.[Friend]TxSetCursor2(&this, hcur, bText);

	public void TxFreeTextServicesNotification() mut => VT.[Friend]TxFreeTextServicesNotification(&this);

	public HRESULT TxGetEditStyle(uint32 dwItem, uint32* pdwData) mut => VT.[Friend]TxGetEditStyle(&this, dwItem, pdwData);

	public HRESULT TxGetWindowStyles(uint32* pdwStyle, uint32* pdwExStyle) mut => VT.[Friend]TxGetWindowStyles(&this, pdwStyle, pdwExStyle);

	public HRESULT TxShowDropCaret(BOOL fShow, HDC hdc, RECT* prc) mut => VT.[Friend]TxShowDropCaret(&this, fShow, hdc, prc);

	public HRESULT TxDestroyCaret() mut => VT.[Friend]TxDestroyCaret(&this);

	public HRESULT TxGetHorzExtent(int32* plHorzExtent) mut => VT.[Friend]TxGetHorzExtent(&this, plHorzExtent);
}

[CRepr]struct ITextServices2 : ITextServices
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextServices.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAspect, HDC hdcDraw, HDC hicTargetDev, DVTARGETDEVICE* ptd, uint32 dwMode, SIZE* psizelExtent, int32* pwidth, int32* pheight, int32* pascent) TxGetNaturalSize2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1RenderTarget* pRenderTarget, RECTL* lprcBounds, RECT* lprcUpdate, int32 lViewId) TxDrawD2D;
	}


	public HRESULT TxGetNaturalSize2(uint32 dwAspect, HDC hdcDraw, HDC hicTargetDev, DVTARGETDEVICE* ptd, uint32 dwMode, SIZE* psizelExtent, int32* pwidth, int32* pheight, int32* pascent) mut => VT.[Friend]TxGetNaturalSize2(&this, dwAspect, hdcDraw, hicTargetDev, ptd, dwMode, psizelExtent, pwidth, pheight, pascent);

	public HRESULT TxDrawD2D(ID2D1RenderTarget* pRenderTarget, RECTL* lprcBounds, RECT* lprcUpdate, int32 lViewId) mut => VT.[Friend]TxDrawD2D(&this, pRenderTarget, lprcBounds, lprcUpdate, lViewId);
}

[CRepr]struct IRichEditOle : IUnknown
{
	public new const Guid IID = .(0x00020d00, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleClientSite** lplpolesite) GetClientSite;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self) GetObjectCount;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self) GetLinkCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iob, REOBJECT* lpreobject, RICH_EDIT_GET_OBJECT_FLAGS dwFlags) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, REOBJECT* lpreobject) InsertObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iob, in Guid rclsidNew, PSTR lpstrUserTypeNew) ConvertObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rclsidAs) ActivateAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR lpstrContainerApp, PSTR lpstrContainerObj) SetHostNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iob, BOOL fAvailable) SetLinkAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iob, uint32 dvaspect) SetDvaspect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iob) HandsOffStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iob, IStorage* lpstg) SaveCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InPlaceDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnterMode) ContextSensitiveHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHARRANGE* lpchrg, uint32 reco, IDataObject** lplpdataobj) GetClipboardData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpdataobj, uint16 cf, int hMetaPict) ImportDataObject;
	}


	public HRESULT GetClientSite(IOleClientSite** lplpolesite) mut => VT.[Friend]GetClientSite(&this, lplpolesite);

	public int32 GetObjectCount() mut => VT.[Friend]GetObjectCount(&this);

	public int32 GetLinkCount() mut => VT.[Friend]GetLinkCount(&this);

	public HRESULT GetObject(int32 iob, REOBJECT* lpreobject, RICH_EDIT_GET_OBJECT_FLAGS dwFlags) mut => VT.[Friend]GetObject(&this, iob, lpreobject, dwFlags);

	public HRESULT InsertObject(REOBJECT* lpreobject) mut => VT.[Friend]InsertObject(&this, lpreobject);

	public HRESULT ConvertObject(int32 iob, in Guid rclsidNew, PSTR lpstrUserTypeNew) mut => VT.[Friend]ConvertObject(&this, iob, rclsidNew, lpstrUserTypeNew);

	public HRESULT ActivateAs(in Guid rclsid, in Guid rclsidAs) mut => VT.[Friend]ActivateAs(&this, rclsid, rclsidAs);

	public HRESULT SetHostNames(PSTR lpstrContainerApp, PSTR lpstrContainerObj) mut => VT.[Friend]SetHostNames(&this, lpstrContainerApp, lpstrContainerObj);

	public HRESULT SetLinkAvailable(int32 iob, BOOL fAvailable) mut => VT.[Friend]SetLinkAvailable(&this, iob, fAvailable);

	public HRESULT SetDvaspect(int32 iob, uint32 dvaspect) mut => VT.[Friend]SetDvaspect(&this, iob, dvaspect);

	public HRESULT HandsOffStorage(int32 iob) mut => VT.[Friend]HandsOffStorage(&this, iob);

	public HRESULT SaveCompleted(int32 iob, IStorage* lpstg) mut => VT.[Friend]SaveCompleted(&this, iob, lpstg);

	public HRESULT InPlaceDeactivate() mut => VT.[Friend]InPlaceDeactivate(&this);

	public HRESULT ContextSensitiveHelp(BOOL fEnterMode) mut => VT.[Friend]ContextSensitiveHelp(&this, fEnterMode);

	public HRESULT GetClipboardData(CHARRANGE* lpchrg, uint32 reco, IDataObject** lplpdataobj) mut => VT.[Friend]GetClipboardData(&this, lpchrg, reco, lplpdataobj);

	public HRESULT ImportDataObject(IDataObject* lpdataobj, uint16 cf, int hMetaPict) mut => VT.[Friend]ImportDataObject(&this, lpdataobj, cf, hMetaPict);
}

[CRepr]struct IRichEditOleCallback : IUnknown
{
	public new const Guid IID = .(0x00020d03, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage** lplpstg) GetNewStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceFrame** lplpFrame, IOleInPlaceUIWindow** lplpDoc, OLEINPLACEFRAMEINFO* lpFrameInfo) GetInPlaceContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) ShowContainerUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* lpclsid, IStorage* lpstg, int32 cp) QueryInsertObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleObject* lpoleobj) DeleteObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpdataobj, uint16* lpcfFormat, RECO_FLAGS reco, BOOL fReally, int hMetaPict) QueryAcceptData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnterMode) ContextSensitiveHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHARRANGE* lpchrg, uint32 reco, IDataObject** lplpdataobj) GetClipboardData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDrag, MODIFIERKEYS_FLAGS grfKeyState, DROPEFFECT* pdwEffect) GetDragDropEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RICH_EDIT_GET_CONTEXT_MENU_SEL_TYPE seltype, IOleObject* lpoleobj, CHARRANGE* lpchrg, HMENU* lphmenu) GetContextMenu;
	}


	public HRESULT GetNewStorage(IStorage** lplpstg) mut => VT.[Friend]GetNewStorage(&this, lplpstg);

	public HRESULT GetInPlaceContext(IOleInPlaceFrame** lplpFrame, IOleInPlaceUIWindow** lplpDoc, OLEINPLACEFRAMEINFO* lpFrameInfo) mut => VT.[Friend]GetInPlaceContext(&this, lplpFrame, lplpDoc, lpFrameInfo);

	public HRESULT ShowContainerUI(BOOL fShow) mut => VT.[Friend]ShowContainerUI(&this, fShow);

	public HRESULT QueryInsertObject(Guid* lpclsid, IStorage* lpstg, int32 cp) mut => VT.[Friend]QueryInsertObject(&this, lpclsid, lpstg, cp);

	public HRESULT DeleteObject(IOleObject* lpoleobj) mut => VT.[Friend]DeleteObject(&this, lpoleobj);

	public HRESULT QueryAcceptData(IDataObject* lpdataobj, uint16* lpcfFormat, RECO_FLAGS reco, BOOL fReally, int hMetaPict) mut => VT.[Friend]QueryAcceptData(&this, lpdataobj, lpcfFormat, reco, fReally, hMetaPict);

	public HRESULT ContextSensitiveHelp(BOOL fEnterMode) mut => VT.[Friend]ContextSensitiveHelp(&this, fEnterMode);

	public HRESULT GetClipboardData(CHARRANGE* lpchrg, uint32 reco, IDataObject** lplpdataobj) mut => VT.[Friend]GetClipboardData(&this, lpchrg, reco, lplpdataobj);

	public HRESULT GetDragDropEffect(BOOL fDrag, MODIFIERKEYS_FLAGS grfKeyState, DROPEFFECT* pdwEffect) mut => VT.[Friend]GetDragDropEffect(&this, fDrag, grfKeyState, pdwEffect);

	public HRESULT GetContextMenu(RICH_EDIT_GET_CONTEXT_MENU_SEL_TYPE seltype, IOleObject* lpoleobj, CHARRANGE* lpchrg, HMENU* lphmenu) mut => VT.[Friend]GetContextMenu(&this, seltype, lpoleobj, lpchrg, lphmenu);
}

[CRepr]struct ITextDocument : IDispatch
{
	public new const Guid IID = .(0x8cc497c0, 0xa1df, 0x11ce, 0x80, 0x98, 0x00, 0xaa, 0x00, 0x47, 0xbe, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextSelection** ppSel) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetStoryCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStoryRanges** ppStories) GetStoryRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetSaved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants Value) SetSaved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetDefaultTabStop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetDefaultTabStop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) New;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar, tomConstants Flags, int32 CodePage) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar, tomConstants Flags, int32 CodePage) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) Freeze;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) Unfreeze;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginEditCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndEditCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Count, int32* pCount) Undo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Count, int32* pCount) Redo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpActive, int32 cpAnchor, ITextRange** ppRange) Range;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, ITextRange** ppRange) RangeFromPoint;
	}


	public HRESULT GetName(BSTR* pName) mut => VT.[Friend]GetName(&this, pName);

	public HRESULT GetSelection(ITextSelection** ppSel) mut => VT.[Friend]GetSelection(&this, ppSel);

	public HRESULT GetStoryCount(int32* pCount) mut => VT.[Friend]GetStoryCount(&this, pCount);

	public HRESULT GetStoryRanges(ITextStoryRanges** ppStories) mut => VT.[Friend]GetStoryRanges(&this, ppStories);

	public HRESULT GetSaved(int32* pValue) mut => VT.[Friend]GetSaved(&this, pValue);

	public HRESULT SetSaved(tomConstants Value) mut => VT.[Friend]SetSaved(&this, Value);

	public HRESULT GetDefaultTabStop(float* pValue) mut => VT.[Friend]GetDefaultTabStop(&this, pValue);

	public HRESULT SetDefaultTabStop(float Value) mut => VT.[Friend]SetDefaultTabStop(&this, Value);

	public HRESULT New() mut => VT.[Friend]New(&this);

	public HRESULT Open(VARIANT* pVar, tomConstants Flags, int32 CodePage) mut => VT.[Friend]Open(&this, pVar, Flags, CodePage);

	public HRESULT Save(VARIANT* pVar, tomConstants Flags, int32 CodePage) mut => VT.[Friend]Save(&this, pVar, Flags, CodePage);

	public HRESULT Freeze(int32* pCount) mut => VT.[Friend]Freeze(&this, pCount);

	public HRESULT Unfreeze(int32* pCount) mut => VT.[Friend]Unfreeze(&this, pCount);

	public HRESULT BeginEditCollection() mut => VT.[Friend]BeginEditCollection(&this);

	public HRESULT EndEditCollection() mut => VT.[Friend]EndEditCollection(&this);

	public HRESULT Undo(int32 Count, int32* pCount) mut => VT.[Friend]Undo(&this, Count, pCount);

	public HRESULT Redo(int32 Count, int32* pCount) mut => VT.[Friend]Redo(&this, Count, pCount);

	public HRESULT Range(int32 cpActive, int32 cpAnchor, ITextRange** ppRange) mut => VT.[Friend]Range(&this, cpActive, cpAnchor, ppRange);

	public HRESULT RangeFromPoint(int32 x, int32 y, ITextRange** ppRange) mut => VT.[Friend]RangeFromPoint(&this, x, y, ppRange);
}

[CRepr]struct ITextRange : IDispatch
{
	public new const Guid IID = .(0x8cc497c2, 0xa1df, 0x11ce, 0x80, 0x98, 0x00, 0xaa, 0x00, 0x47, 0xbe, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) SetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pChar) GetChar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Char) SetChar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange** ppRange) GetDuplicate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange** ppRange) GetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange* pRange) SetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcpFirst) GetStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpFirst) SetStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcpLim) GetEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpLim) SetEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont** ppFont) GetFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont* pFont) SetFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara** ppPara) GetPara;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara* pPara) SetPara;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetStoryLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetStoryType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 bStart) Collapse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32* pDelta) Expand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32* pIndex) GetIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Index, int32 Extend) SetIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpAnchor, int32 cpActive) SetRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange* pRange, int32* pValue) InRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange* pRange, int32* pValue) InStory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange* pRange, int32* pValue) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Extend, int32* pDelta) StartOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Extend, int32* pDelta) EndOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32* pDelta) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32* pDelta) MoveStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32* pDelta) MoveEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cset, int32 Count, int32* pDelta) MoveWhile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cset, int32 Count, int32* pDelta) MoveStartWhile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cset, int32 Count, int32* pDelta) MoveEndWhile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cset, int32 Count, int32* pDelta) MoveUntil;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cset, int32 Count, int32* pDelta) MoveStartUntil;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Cset, int32 Count, int32* pDelta) MoveEndUntil;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr, int32 Count, tomConstants Flags, int32* pLength) FindText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr, int32 Count, tomConstants Flags, int32* pLength) FindTextStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr, int32 Count, tomConstants Flags, int32* pLength) FindTextEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32* pDelta) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar) Cut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar) Copy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar, int32 Format) Paste;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar, int32 Format, int32* pValue) CanPaste;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) CanEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants Type) ChangeCase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants Type, int32* px, int32* py) GetPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, tomConstants Type, int32 Extend) SetPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) ScrollIntoView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppObject) GetEmbeddedObject;
	}


	public HRESULT GetText(BSTR* pbstr) mut => VT.[Friend]GetText(&this, pbstr);

	public HRESULT SetText(BSTR bstr) mut => VT.[Friend]SetText(&this, bstr);

	public HRESULT GetChar(int32* pChar) mut => VT.[Friend]GetChar(&this, pChar);

	public HRESULT SetChar(int32 Char) mut => VT.[Friend]SetChar(&this, Char);

	public HRESULT GetDuplicate(ITextRange** ppRange) mut => VT.[Friend]GetDuplicate(&this, ppRange);

	public HRESULT GetFormattedText(ITextRange** ppRange) mut => VT.[Friend]GetFormattedText(&this, ppRange);

	public HRESULT SetFormattedText(ITextRange* pRange) mut => VT.[Friend]SetFormattedText(&this, pRange);

	public HRESULT GetStart(int32* pcpFirst) mut => VT.[Friend]GetStart(&this, pcpFirst);

	public HRESULT SetStart(int32 cpFirst) mut => VT.[Friend]SetStart(&this, cpFirst);

	public HRESULT GetEnd(int32* pcpLim) mut => VT.[Friend]GetEnd(&this, pcpLim);

	public HRESULT SetEnd(int32 cpLim) mut => VT.[Friend]SetEnd(&this, cpLim);

	public HRESULT GetFont(ITextFont** ppFont) mut => VT.[Friend]GetFont(&this, ppFont);

	public HRESULT SetFont(ITextFont* pFont) mut => VT.[Friend]SetFont(&this, pFont);

	public HRESULT GetPara(ITextPara** ppPara) mut => VT.[Friend]GetPara(&this, ppPara);

	public HRESULT SetPara(ITextPara* pPara) mut => VT.[Friend]SetPara(&this, pPara);

	public HRESULT GetStoryLength(int32* pCount) mut => VT.[Friend]GetStoryLength(&this, pCount);

	public HRESULT GetStoryType(int32* pValue) mut => VT.[Friend]GetStoryType(&this, pValue);

	public HRESULT Collapse(int32 bStart) mut => VT.[Friend]Collapse(&this, bStart);

	public HRESULT Expand(int32 Unit, int32* pDelta) mut => VT.[Friend]Expand(&this, Unit, pDelta);

	public HRESULT GetIndex(int32 Unit, int32* pIndex) mut => VT.[Friend]GetIndex(&this, Unit, pIndex);

	public HRESULT SetIndex(int32 Unit, int32 Index, int32 Extend) mut => VT.[Friend]SetIndex(&this, Unit, Index, Extend);

	public HRESULT SetRange(int32 cpAnchor, int32 cpActive) mut => VT.[Friend]SetRange(&this, cpAnchor, cpActive);

	public HRESULT InRange(ITextRange* pRange, int32* pValue) mut => VT.[Friend]InRange(&this, pRange, pValue);

	public HRESULT InStory(ITextRange* pRange, int32* pValue) mut => VT.[Friend]InStory(&this, pRange, pValue);

	public HRESULT IsEqual(ITextRange* pRange, int32* pValue) mut => VT.[Friend]IsEqual(&this, pRange, pValue);

	public HRESULT Select() mut => VT.[Friend]Select(&this);

	public HRESULT StartOf(int32 Unit, int32 Extend, int32* pDelta) mut => VT.[Friend]StartOf(&this, Unit, Extend, pDelta);

	public HRESULT EndOf(int32 Unit, int32 Extend, int32* pDelta) mut => VT.[Friend]EndOf(&this, Unit, Extend, pDelta);

	public HRESULT Move(int32 Unit, int32 Count, int32* pDelta) mut => VT.[Friend]Move(&this, Unit, Count, pDelta);

	public HRESULT MoveStart(int32 Unit, int32 Count, int32* pDelta) mut => VT.[Friend]MoveStart(&this, Unit, Count, pDelta);

	public HRESULT MoveEnd(int32 Unit, int32 Count, int32* pDelta) mut => VT.[Friend]MoveEnd(&this, Unit, Count, pDelta);

	public HRESULT MoveWhile(VARIANT* Cset, int32 Count, int32* pDelta) mut => VT.[Friend]MoveWhile(&this, Cset, Count, pDelta);

	public HRESULT MoveStartWhile(VARIANT* Cset, int32 Count, int32* pDelta) mut => VT.[Friend]MoveStartWhile(&this, Cset, Count, pDelta);

	public HRESULT MoveEndWhile(VARIANT* Cset, int32 Count, int32* pDelta) mut => VT.[Friend]MoveEndWhile(&this, Cset, Count, pDelta);

	public HRESULT MoveUntil(VARIANT* Cset, int32 Count, int32* pDelta) mut => VT.[Friend]MoveUntil(&this, Cset, Count, pDelta);

	public HRESULT MoveStartUntil(VARIANT* Cset, int32 Count, int32* pDelta) mut => VT.[Friend]MoveStartUntil(&this, Cset, Count, pDelta);

	public HRESULT MoveEndUntil(VARIANT* Cset, int32 Count, int32* pDelta) mut => VT.[Friend]MoveEndUntil(&this, Cset, Count, pDelta);

	public HRESULT FindText(BSTR bstr, int32 Count, tomConstants Flags, int32* pLength) mut => VT.[Friend]FindText(&this, bstr, Count, Flags, pLength);

	public HRESULT FindTextStart(BSTR bstr, int32 Count, tomConstants Flags, int32* pLength) mut => VT.[Friend]FindTextStart(&this, bstr, Count, Flags, pLength);

	public HRESULT FindTextEnd(BSTR bstr, int32 Count, tomConstants Flags, int32* pLength) mut => VT.[Friend]FindTextEnd(&this, bstr, Count, Flags, pLength);

	public HRESULT Delete(int32 Unit, int32 Count, int32* pDelta) mut => VT.[Friend]Delete(&this, Unit, Count, pDelta);

	public HRESULT Cut(VARIANT* pVar) mut => VT.[Friend]Cut(&this, pVar);

	public HRESULT Copy(VARIANT* pVar) mut => VT.[Friend]Copy(&this, pVar);

	public HRESULT Paste(VARIANT* pVar, int32 Format) mut => VT.[Friend]Paste(&this, pVar, Format);

	public HRESULT CanPaste(VARIANT* pVar, int32 Format, int32* pValue) mut => VT.[Friend]CanPaste(&this, pVar, Format, pValue);

	public HRESULT CanEdit(int32* pValue) mut => VT.[Friend]CanEdit(&this, pValue);

	public HRESULT ChangeCase(tomConstants Type) mut => VT.[Friend]ChangeCase(&this, Type);

	public HRESULT GetPoint(tomConstants Type, int32* px, int32* py) mut => VT.[Friend]GetPoint(&this, Type, px, py);

	public HRESULT SetPoint(int32 x, int32 y, tomConstants Type, int32 Extend) mut => VT.[Friend]SetPoint(&this, x, y, Type, Extend);

	public HRESULT ScrollIntoView(int32 Value) mut => VT.[Friend]ScrollIntoView(&this, Value);

	public HRESULT GetEmbeddedObject(IUnknown** ppObject) mut => VT.[Friend]GetEmbeddedObject(&this, ppObject);
}

[CRepr]struct ITextSelection : ITextRange
{
	public new const Guid IID = .(0x8cc497c1, 0xa1df, 0x11ce, 0x80, 0x98, 0x00, 0xaa, 0x00, 0x47, 0xbe, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextRange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) SetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32 Extend, int32* pDelta) MoveLeft;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32 Extend, int32* pDelta) MoveRight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32 Extend, int32* pDelta) MoveUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Count, int32 Extend, int32* pDelta) MoveDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants Unit, int32 Extend, int32* pDelta) HomeKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Unit, int32 Extend, int32* pDelta) EndKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) TypeText;
	}


	public HRESULT GetFlags(int32* pFlags) mut => VT.[Friend]COM_GetFlags(&this, pFlags);

	public HRESULT SetFlags(int32 Flags) mut => VT.[Friend]SetFlags(&this, Flags);

	public HRESULT GetType(int32* pType) mut => VT.[Friend]COM_GetType(&this, pType);

	public HRESULT MoveLeft(int32 Unit, int32 Count, int32 Extend, int32* pDelta) mut => VT.[Friend]MoveLeft(&this, Unit, Count, Extend, pDelta);

	public HRESULT MoveRight(int32 Unit, int32 Count, int32 Extend, int32* pDelta) mut => VT.[Friend]MoveRight(&this, Unit, Count, Extend, pDelta);

	public HRESULT MoveUp(int32 Unit, int32 Count, int32 Extend, int32* pDelta) mut => VT.[Friend]MoveUp(&this, Unit, Count, Extend, pDelta);

	public HRESULT MoveDown(int32 Unit, int32 Count, int32 Extend, int32* pDelta) mut => VT.[Friend]MoveDown(&this, Unit, Count, Extend, pDelta);

	public HRESULT HomeKey(tomConstants Unit, int32 Extend, int32* pDelta) mut => VT.[Friend]HomeKey(&this, Unit, Extend, pDelta);

	public HRESULT EndKey(int32 Unit, int32 Extend, int32* pDelta) mut => VT.[Friend]EndKey(&this, Unit, Extend, pDelta);

	public HRESULT TypeText(BSTR bstr) mut => VT.[Friend]TypeText(&this, bstr);
}

[CRepr]struct ITextFont : IDispatch
{
	public new const Guid IID = .(0x8cc497c3, 0xa1df, 0x11ce, 0x80, 0x98, 0x00, 0xaa, 0x00, 0x47, 0xbe, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont** ppFont) GetDuplicate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont* pFont) SetDuplicate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) CanChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont* pFont, int32* pValue) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants Value) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAllCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAllCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAnimation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAnimation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetBackColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetBackColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetBold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetBold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetEmboss;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetEmboss;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetForeColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetForeColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetHidden;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetHidden;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetEngrave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetEngrave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetItalic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetItalic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetKerning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetKerning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetLanguageID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetLanguageID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetOutline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetOutline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetProtected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetProtected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetShadow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetShadow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetSmallCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetSmallCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetStrikeThrough;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetStrikeThrough;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetSubscript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetSubscript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetSuperscript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetSuperscript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetUnderline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetUnderline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetWeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetWeight;
	}


	public HRESULT GetDuplicate(ITextFont** ppFont) mut => VT.[Friend]GetDuplicate(&this, ppFont);

	public HRESULT SetDuplicate(ITextFont* pFont) mut => VT.[Friend]SetDuplicate(&this, pFont);

	public HRESULT CanChange(int32* pValue) mut => VT.[Friend]CanChange(&this, pValue);

	public HRESULT IsEqual(ITextFont* pFont, int32* pValue) mut => VT.[Friend]IsEqual(&this, pFont, pValue);

	public HRESULT Reset(tomConstants Value) mut => VT.[Friend]Reset(&this, Value);

	public HRESULT GetStyle(int32* pValue) mut => VT.[Friend]GetStyle(&this, pValue);

	public HRESULT SetStyle(int32 Value) mut => VT.[Friend]SetStyle(&this, Value);

	public HRESULT GetAllCaps(int32* pValue) mut => VT.[Friend]GetAllCaps(&this, pValue);

	public HRESULT SetAllCaps(int32 Value) mut => VT.[Friend]SetAllCaps(&this, Value);

	public HRESULT GetAnimation(int32* pValue) mut => VT.[Friend]GetAnimation(&this, pValue);

	public HRESULT SetAnimation(int32 Value) mut => VT.[Friend]SetAnimation(&this, Value);

	public HRESULT GetBackColor(int32* pValue) mut => VT.[Friend]GetBackColor(&this, pValue);

	public HRESULT SetBackColor(int32 Value) mut => VT.[Friend]SetBackColor(&this, Value);

	public HRESULT GetBold(int32* pValue) mut => VT.[Friend]GetBold(&this, pValue);

	public HRESULT SetBold(int32 Value) mut => VT.[Friend]SetBold(&this, Value);

	public HRESULT GetEmboss(int32* pValue) mut => VT.[Friend]GetEmboss(&this, pValue);

	public HRESULT SetEmboss(int32 Value) mut => VT.[Friend]SetEmboss(&this, Value);

	public HRESULT GetForeColor(int32* pValue) mut => VT.[Friend]GetForeColor(&this, pValue);

	public HRESULT SetForeColor(int32 Value) mut => VT.[Friend]SetForeColor(&this, Value);

	public HRESULT GetHidden(int32* pValue) mut => VT.[Friend]GetHidden(&this, pValue);

	public HRESULT SetHidden(int32 Value) mut => VT.[Friend]SetHidden(&this, Value);

	public HRESULT GetEngrave(int32* pValue) mut => VT.[Friend]GetEngrave(&this, pValue);

	public HRESULT SetEngrave(int32 Value) mut => VT.[Friend]SetEngrave(&this, Value);

	public HRESULT GetItalic(int32* pValue) mut => VT.[Friend]GetItalic(&this, pValue);

	public HRESULT SetItalic(int32 Value) mut => VT.[Friend]SetItalic(&this, Value);

	public HRESULT GetKerning(float* pValue) mut => VT.[Friend]GetKerning(&this, pValue);

	public HRESULT SetKerning(float Value) mut => VT.[Friend]SetKerning(&this, Value);

	public HRESULT GetLanguageID(int32* pValue) mut => VT.[Friend]GetLanguageID(&this, pValue);

	public HRESULT SetLanguageID(int32 Value) mut => VT.[Friend]SetLanguageID(&this, Value);

	public HRESULT GetName(BSTR* pbstr) mut => VT.[Friend]GetName(&this, pbstr);

	public HRESULT SetName(BSTR bstr) mut => VT.[Friend]SetName(&this, bstr);

	public HRESULT GetOutline(int32* pValue) mut => VT.[Friend]GetOutline(&this, pValue);

	public HRESULT SetOutline(int32 Value) mut => VT.[Friend]SetOutline(&this, Value);

	public HRESULT GetPosition(float* pValue) mut => VT.[Friend]GetPosition(&this, pValue);

	public HRESULT SetPosition(float Value) mut => VT.[Friend]SetPosition(&this, Value);

	public HRESULT GetProtected(int32* pValue) mut => VT.[Friend]GetProtected(&this, pValue);

	public HRESULT SetProtected(int32 Value) mut => VT.[Friend]SetProtected(&this, Value);

	public HRESULT GetShadow(int32* pValue) mut => VT.[Friend]GetShadow(&this, pValue);

	public HRESULT SetShadow(int32 Value) mut => VT.[Friend]SetShadow(&this, Value);

	public HRESULT GetSize(float* pValue) mut => VT.[Friend]GetSize(&this, pValue);

	public HRESULT SetSize(float Value) mut => VT.[Friend]SetSize(&this, Value);

	public HRESULT GetSmallCaps(int32* pValue) mut => VT.[Friend]GetSmallCaps(&this, pValue);

	public HRESULT SetSmallCaps(int32 Value) mut => VT.[Friend]SetSmallCaps(&this, Value);

	public HRESULT GetSpacing(float* pValue) mut => VT.[Friend]GetSpacing(&this, pValue);

	public HRESULT SetSpacing(float Value) mut => VT.[Friend]SetSpacing(&this, Value);

	public HRESULT GetStrikeThrough(int32* pValue) mut => VT.[Friend]GetStrikeThrough(&this, pValue);

	public HRESULT SetStrikeThrough(int32 Value) mut => VT.[Friend]SetStrikeThrough(&this, Value);

	public HRESULT GetSubscript(int32* pValue) mut => VT.[Friend]GetSubscript(&this, pValue);

	public HRESULT SetSubscript(int32 Value) mut => VT.[Friend]SetSubscript(&this, Value);

	public HRESULT GetSuperscript(int32* pValue) mut => VT.[Friend]GetSuperscript(&this, pValue);

	public HRESULT SetSuperscript(int32 Value) mut => VT.[Friend]SetSuperscript(&this, Value);

	public HRESULT GetUnderline(int32* pValue) mut => VT.[Friend]GetUnderline(&this, pValue);

	public HRESULT SetUnderline(int32 Value) mut => VT.[Friend]SetUnderline(&this, Value);

	public HRESULT GetWeight(int32* pValue) mut => VT.[Friend]GetWeight(&this, pValue);

	public HRESULT SetWeight(int32 Value) mut => VT.[Friend]SetWeight(&this, Value);
}

[CRepr]struct ITextPara : IDispatch
{
	public new const Guid IID = .(0x8cc497c4, 0xa1df, 0x11ce, 0x80, 0x98, 0x00, 0xaa, 0x00, 0x47, 0xbe, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara** ppPara) GetDuplicate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara* pPara) SetDuplicate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) CanChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara* pPara, int32* pValue) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants* pValue) GetHyphenation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetHyphenation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetFirstLineIndent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants* pValue) GetKeepTogether;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetKeepTogether;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants* pValue) GetKeepWithNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetKeepWithNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetLeftIndent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetLineSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetLineSpacingRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetListAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetListAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetListLevelIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetListLevelIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetListStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetListStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetListTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetListTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetListType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetListType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetNoLineNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetNoLineNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetPageBreakBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetPageBreakBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetRightIndent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetRightIndent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float First, float Left, float Right) SetIndents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Rule, float Spacing) SetLineSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetSpaceAfter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetSpaceAfter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetSpaceBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetSpaceBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetWidowControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetWidowControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetTabCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float tbPos, int32 tbAlign, int32 tbLeader) AddTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearAllTabs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float tbPos) DeleteTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iTab, float* ptbPos, int32* ptbAlign, int32* ptbLeader) GetTab;
	}


	public HRESULT GetDuplicate(ITextPara** ppPara) mut => VT.[Friend]GetDuplicate(&this, ppPara);

	public HRESULT SetDuplicate(ITextPara* pPara) mut => VT.[Friend]SetDuplicate(&this, pPara);

	public HRESULT CanChange(int32* pValue) mut => VT.[Friend]CanChange(&this, pValue);

	public HRESULT IsEqual(ITextPara* pPara, int32* pValue) mut => VT.[Friend]IsEqual(&this, pPara, pValue);

	public HRESULT Reset(int32 Value) mut => VT.[Friend]Reset(&this, Value);

	public HRESULT GetStyle(int32* pValue) mut => VT.[Friend]GetStyle(&this, pValue);

	public HRESULT SetStyle(int32 Value) mut => VT.[Friend]SetStyle(&this, Value);

	public HRESULT GetAlignment(int32* pValue) mut => VT.[Friend]GetAlignment(&this, pValue);

	public HRESULT SetAlignment(int32 Value) mut => VT.[Friend]SetAlignment(&this, Value);

	public HRESULT GetHyphenation(tomConstants* pValue) mut => VT.[Friend]GetHyphenation(&this, pValue);

	public HRESULT SetHyphenation(int32 Value) mut => VT.[Friend]SetHyphenation(&this, Value);

	public HRESULT GetFirstLineIndent(float* pValue) mut => VT.[Friend]GetFirstLineIndent(&this, pValue);

	public HRESULT GetKeepTogether(tomConstants* pValue) mut => VT.[Friend]GetKeepTogether(&this, pValue);

	public HRESULT SetKeepTogether(int32 Value) mut => VT.[Friend]SetKeepTogether(&this, Value);

	public HRESULT GetKeepWithNext(tomConstants* pValue) mut => VT.[Friend]GetKeepWithNext(&this, pValue);

	public HRESULT SetKeepWithNext(int32 Value) mut => VT.[Friend]SetKeepWithNext(&this, Value);

	public HRESULT GetLeftIndent(float* pValue) mut => VT.[Friend]GetLeftIndent(&this, pValue);

	public HRESULT GetLineSpacing(float* pValue) mut => VT.[Friend]GetLineSpacing(&this, pValue);

	public HRESULT GetLineSpacingRule(int32* pValue) mut => VT.[Friend]GetLineSpacingRule(&this, pValue);

	public HRESULT GetListAlignment(int32* pValue) mut => VT.[Friend]GetListAlignment(&this, pValue);

	public HRESULT SetListAlignment(int32 Value) mut => VT.[Friend]SetListAlignment(&this, Value);

	public HRESULT GetListLevelIndex(int32* pValue) mut => VT.[Friend]GetListLevelIndex(&this, pValue);

	public HRESULT SetListLevelIndex(int32 Value) mut => VT.[Friend]SetListLevelIndex(&this, Value);

	public HRESULT GetListStart(int32* pValue) mut => VT.[Friend]GetListStart(&this, pValue);

	public HRESULT SetListStart(int32 Value) mut => VT.[Friend]SetListStart(&this, Value);

	public HRESULT GetListTab(float* pValue) mut => VT.[Friend]GetListTab(&this, pValue);

	public HRESULT SetListTab(float Value) mut => VT.[Friend]SetListTab(&this, Value);

	public HRESULT GetListType(int32* pValue) mut => VT.[Friend]GetListType(&this, pValue);

	public HRESULT SetListType(int32 Value) mut => VT.[Friend]SetListType(&this, Value);

	public HRESULT GetNoLineNumber(int32* pValue) mut => VT.[Friend]GetNoLineNumber(&this, pValue);

	public HRESULT SetNoLineNumber(int32 Value) mut => VT.[Friend]SetNoLineNumber(&this, Value);

	public HRESULT GetPageBreakBefore(int32* pValue) mut => VT.[Friend]GetPageBreakBefore(&this, pValue);

	public HRESULT SetPageBreakBefore(int32 Value) mut => VT.[Friend]SetPageBreakBefore(&this, Value);

	public HRESULT GetRightIndent(float* pValue) mut => VT.[Friend]GetRightIndent(&this, pValue);

	public HRESULT SetRightIndent(float Value) mut => VT.[Friend]SetRightIndent(&this, Value);

	public HRESULT SetIndents(float First, float Left, float Right) mut => VT.[Friend]SetIndents(&this, First, Left, Right);

	public HRESULT SetLineSpacing(int32 Rule, float Spacing) mut => VT.[Friend]SetLineSpacing(&this, Rule, Spacing);

	public HRESULT GetSpaceAfter(float* pValue) mut => VT.[Friend]GetSpaceAfter(&this, pValue);

	public HRESULT SetSpaceAfter(float Value) mut => VT.[Friend]SetSpaceAfter(&this, Value);

	public HRESULT GetSpaceBefore(float* pValue) mut => VT.[Friend]GetSpaceBefore(&this, pValue);

	public HRESULT SetSpaceBefore(float Value) mut => VT.[Friend]SetSpaceBefore(&this, Value);

	public HRESULT GetWidowControl(int32* pValue) mut => VT.[Friend]GetWidowControl(&this, pValue);

	public HRESULT SetWidowControl(int32 Value) mut => VT.[Friend]SetWidowControl(&this, Value);

	public HRESULT GetTabCount(int32* pCount) mut => VT.[Friend]GetTabCount(&this, pCount);

	public HRESULT AddTab(float tbPos, int32 tbAlign, int32 tbLeader) mut => VT.[Friend]AddTab(&this, tbPos, tbAlign, tbLeader);

	public HRESULT ClearAllTabs() mut => VT.[Friend]ClearAllTabs(&this);

	public HRESULT DeleteTab(float tbPos) mut => VT.[Friend]DeleteTab(&this, tbPos);

	public HRESULT GetTab(int32 iTab, float* ptbPos, int32* ptbAlign, int32* ptbLeader) mut => VT.[Friend]GetTab(&this, iTab, ptbPos, ptbAlign, ptbLeader);
}

[CRepr]struct ITextStoryRanges : IDispatch
{
	public new const Guid IID = .(0x8cc497c5, 0xa1df, 0x11ce, 0x80, 0x98, 0x00, 0xaa, 0x00, 0x47, 0xbe, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunkEnum) _NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ITextRange** ppRange) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
	}


	public HRESULT _NewEnum(IUnknown** ppunkEnum) mut => VT.[Friend]_NewEnum(&this, ppunkEnum);

	public HRESULT Item(int32 Index, ITextRange** ppRange) mut => VT.[Friend]Item(&this, Index, ppRange);

	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);
}

[CRepr]struct ITextDocument2 : ITextDocument
{
	public new const Guid IID = .(0xc241f5e0, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextDocument.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCaretType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCaretType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextDisplays** ppDisplays) GetDisplays;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2** ppFont) GetDocumentFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2* pFont) SetDocumentFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2** ppPara) GetDocumentPara;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2* pPara) SetDocumentPara;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants* pFlags) GetEastAsianFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) GetGenerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetIMEInProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetNotificationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetNotificationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextSelection2** ppSel) GetSelection2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStoryRanges2** ppStories) GetStoryRanges2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pOptions) GetTypographyOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pHwnd) GetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pFilter) AttachMsgFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cch, int32* pcch) CheckTextLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppVoid) GetCallManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, tomConstants Type, int32* pLeft, int32* pTop, int32* pRight, int32* pBottom) GetClientRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32* pValue) GetEffectColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pContext) GetImmContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cp, int32 CharRep, int32 Options, int32 curCharRep, int32 curFontSize, BSTR* pbstr, int32* pPitchAndFamily, int32* pNewFontSize) GetPreferredFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStrings** ppStrs) GetStrings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Notify) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpActive, int32 cpAnchor, ITextRange2** ppRange) Range2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, int32 Type, ITextRange2** ppRange) RangeFromPoint2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pVoid) ReleaseCallManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 Context) ReleaseImmContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32 Value) SetEffectColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Value) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Options, int32 Mask) SetTypographyOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SysBeep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pOptions) GetMathProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Options, int32 Mask) SetMathProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStory** ppStory) GetActiveStory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStory* pStory) SetActiveStory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStory** ppStory) GetMainStory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextStory** ppStory) GetNewStory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ITextStory** ppStory) GetStory;
	}


	public HRESULT GetCaretType(int32* pValue) mut => VT.[Friend]GetCaretType(&this, pValue);

	public HRESULT SetCaretType(int32 Value) mut => VT.[Friend]SetCaretType(&this, Value);

	public HRESULT GetDisplays(ITextDisplays** ppDisplays) mut => VT.[Friend]GetDisplays(&this, ppDisplays);

	public HRESULT GetDocumentFont(ITextFont2** ppFont) mut => VT.[Friend]GetDocumentFont(&this, ppFont);

	public HRESULT SetDocumentFont(ITextFont2* pFont) mut => VT.[Friend]SetDocumentFont(&this, pFont);

	public HRESULT GetDocumentPara(ITextPara2** ppPara) mut => VT.[Friend]GetDocumentPara(&this, ppPara);

	public HRESULT SetDocumentPara(ITextPara2* pPara) mut => VT.[Friend]SetDocumentPara(&this, pPara);

	public HRESULT GetEastAsianFlags(tomConstants* pFlags) mut => VT.[Friend]GetEastAsianFlags(&this, pFlags);

	public HRESULT GetGenerator(BSTR* pbstr) mut => VT.[Friend]GetGenerator(&this, pbstr);

	public HRESULT SetIMEInProgress(int32 Value) mut => VT.[Friend]SetIMEInProgress(&this, Value);

	public HRESULT GetNotificationMode(int32* pValue) mut => VT.[Friend]GetNotificationMode(&this, pValue);

	public HRESULT SetNotificationMode(int32 Value) mut => VT.[Friend]SetNotificationMode(&this, Value);

	public HRESULT GetSelection2(ITextSelection2** ppSel) mut => VT.[Friend]GetSelection2(&this, ppSel);

	public HRESULT GetStoryRanges2(ITextStoryRanges2** ppStories) mut => VT.[Friend]GetStoryRanges2(&this, ppStories);

	public HRESULT GetTypographyOptions(int32* pOptions) mut => VT.[Friend]GetTypographyOptions(&this, pOptions);

	public HRESULT GetVersion(int32* pValue) mut => VT.[Friend]GetVersion(&this, pValue);

	public HRESULT GetWindow(int64* pHwnd) mut => VT.[Friend]GetWindow(&this, pHwnd);

	public HRESULT AttachMsgFilter(IUnknown* pFilter) mut => VT.[Friend]AttachMsgFilter(&this, pFilter);

	public HRESULT CheckTextLimit(int32 cch, int32* pcch) mut => VT.[Friend]CheckTextLimit(&this, cch, pcch);

	public HRESULT GetCallManager(IUnknown** ppVoid) mut => VT.[Friend]GetCallManager(&this, ppVoid);

	public HRESULT GetClientRect(tomConstants Type, int32* pLeft, int32* pTop, int32* pRight, int32* pBottom) mut => VT.[Friend]GetClientRect(&this, Type, pLeft, pTop, pRight, pBottom);

	public HRESULT GetEffectColor(int32 Index, int32* pValue) mut => VT.[Friend]GetEffectColor(&this, Index, pValue);

	public HRESULT GetImmContext(int64* pContext) mut => VT.[Friend]GetImmContext(&this, pContext);

	public HRESULT GetPreferredFont(int32 cp, int32 CharRep, int32 Options, int32 curCharRep, int32 curFontSize, BSTR* pbstr, int32* pPitchAndFamily, int32* pNewFontSize) mut => VT.[Friend]GetPreferredFont(&this, cp, CharRep, Options, curCharRep, curFontSize, pbstr, pPitchAndFamily, pNewFontSize);

	public HRESULT GetProperty(int32 Type, int32* pValue) mut => VT.[Friend]GetProperty(&this, Type, pValue);

	public HRESULT GetStrings(ITextStrings** ppStrs) mut => VT.[Friend]GetStrings(&this, ppStrs);

	public HRESULT Notify(int32 Notify) mut => VT.[Friend]Notify(&this, Notify);

	public HRESULT Range2(int32 cpActive, int32 cpAnchor, ITextRange2** ppRange) mut => VT.[Friend]Range2(&this, cpActive, cpAnchor, ppRange);

	public HRESULT RangeFromPoint2(int32 x, int32 y, int32 Type, ITextRange2** ppRange) mut => VT.[Friend]RangeFromPoint2(&this, x, y, Type, ppRange);

	public HRESULT ReleaseCallManager(IUnknown* pVoid) mut => VT.[Friend]ReleaseCallManager(&this, pVoid);

	public HRESULT ReleaseImmContext(int64 Context) mut => VT.[Friend]ReleaseImmContext(&this, Context);

	public HRESULT SetEffectColor(int32 Index, int32 Value) mut => VT.[Friend]SetEffectColor(&this, Index, Value);

	public HRESULT SetProperty(int32 Type, int32 Value) mut => VT.[Friend]SetProperty(&this, Type, Value);

	public HRESULT SetTypographyOptions(int32 Options, int32 Mask) mut => VT.[Friend]SetTypographyOptions(&this, Options, Mask);

	public HRESULT SysBeep() mut => VT.[Friend]SysBeep(&this);

	public HRESULT Update(int32 Value) mut => VT.[Friend]Update(&this, Value);

	public HRESULT UpdateWindow() mut => VT.[Friend]UpdateWindow(&this);

	public HRESULT GetMathProperties(int32* pOptions) mut => VT.[Friend]GetMathProperties(&this, pOptions);

	public HRESULT SetMathProperties(int32 Options, int32 Mask) mut => VT.[Friend]SetMathProperties(&this, Options, Mask);

	public HRESULT GetActiveStory(ITextStory** ppStory) mut => VT.[Friend]GetActiveStory(&this, ppStory);

	public HRESULT SetActiveStory(ITextStory* pStory) mut => VT.[Friend]SetActiveStory(&this, pStory);

	public HRESULT GetMainStory(ITextStory** ppStory) mut => VT.[Friend]GetMainStory(&this, ppStory);

	public HRESULT GetNewStory(ITextStory** ppStory) mut => VT.[Friend]GetNewStory(&this, ppStory);

	public HRESULT GetStory(int32 Index, ITextStory** ppStory) mut => VT.[Friend]GetStory(&this, Index, ppStory);
}

[CRepr]struct ITextRange2 : ITextSelection
{
	public new const Guid IID = .(0xc241f5e2, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextSelection.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcch) GetCch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppCells) GetCells;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppColumn) GetColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2** ppRange) GetDuplicate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2** ppFont) GetFont2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2* pFont) SetFont2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2** ppRange) GetFormattedText2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2* pRange) SetFormattedText2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetGravity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetGravity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2** ppPara) GetPara2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2* pPara) SetPara2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRow** ppRow) GetRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetStartPara;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppTable) GetTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) GetURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) SetURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cp1, int32 cp2, int32 Activate) AddSubrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) BuildUpMath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpFirst, int32 cpLim) DeleteSubrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2* pRange, int32 Count, int32 Flags, int32* pDelta) Find;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pChar, int32 Offset) GetChar2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcLine, int32* pPosition) GetDropCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pType, int32* pAlign, int32* pChar, int32* pChar1, int32* pChar2, int32* pCount, int32* pTeXStyle, int32* pcCol, int32* pLevel) GetInlineObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pLeft, int32* pTop, int32* pRight, int32* pBottom, int32* pHit) GetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iSubrange, int32* pcpFirst, int32* pcpLim) GetSubrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR* pbstr) GetText2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) HexToUnicode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cCol, int32 cRow, int32 AutoFit) InsertTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) Linearize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpAnchor, int32 cpActive) SetActiveSubrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cLine, int32 Position) SetDropCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Value) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR bstr) SetText2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnicodeToHex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Align, int32 Char, int32 Char1, int32 Char2, int32 Count, int32 TeXStyle, int32 cCol) SetInlineObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr, int32* pValue) GetMathFunctionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 width, int32 height, int32 ascent, TEXT_ALIGN_OPTIONS Type, BSTR bstrAltText, IStream* pStream) InsertImage;
	}


	public HRESULT GetCch(int32* pcch) mut => VT.[Friend]GetCch(&this, pcch);

	public HRESULT GetCells(IUnknown** ppCells) mut => VT.[Friend]GetCells(&this, ppCells);

	public HRESULT GetColumn(IUnknown** ppColumn) mut => VT.[Friend]GetColumn(&this, ppColumn);

	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetDuplicate2(ITextRange2** ppRange) mut => VT.[Friend]GetDuplicate2(&this, ppRange);

	public HRESULT GetFont2(ITextFont2** ppFont) mut => VT.[Friend]GetFont2(&this, ppFont);

	public HRESULT SetFont2(ITextFont2* pFont) mut => VT.[Friend]SetFont2(&this, pFont);

	public HRESULT GetFormattedText2(ITextRange2** ppRange) mut => VT.[Friend]GetFormattedText2(&this, ppRange);

	public HRESULT SetFormattedText2(ITextRange2* pRange) mut => VT.[Friend]SetFormattedText2(&this, pRange);

	public HRESULT GetGravity(int32* pValue) mut => VT.[Friend]GetGravity(&this, pValue);

	public HRESULT SetGravity(int32 Value) mut => VT.[Friend]SetGravity(&this, Value);

	public HRESULT GetPara2(ITextPara2** ppPara) mut => VT.[Friend]GetPara2(&this, ppPara);

	public HRESULT SetPara2(ITextPara2* pPara) mut => VT.[Friend]SetPara2(&this, pPara);

	public HRESULT GetRow(ITextRow** ppRow) mut => VT.[Friend]GetRow(&this, ppRow);

	public HRESULT GetStartPara(int32* pValue) mut => VT.[Friend]GetStartPara(&this, pValue);

	public HRESULT GetTable(IUnknown** ppTable) mut => VT.[Friend]GetTable(&this, ppTable);

	public HRESULT GetURL(BSTR* pbstr) mut => VT.[Friend]GetURL(&this, pbstr);

	public HRESULT SetURL(BSTR bstr) mut => VT.[Friend]SetURL(&this, bstr);

	public HRESULT AddSubrange(int32 cp1, int32 cp2, int32 Activate) mut => VT.[Friend]AddSubrange(&this, cp1, cp2, Activate);

	public HRESULT BuildUpMath(int32 Flags) mut => VT.[Friend]BuildUpMath(&this, Flags);

	public HRESULT DeleteSubrange(int32 cpFirst, int32 cpLim) mut => VT.[Friend]DeleteSubrange(&this, cpFirst, cpLim);

	public HRESULT Find(ITextRange2* pRange, int32 Count, int32 Flags, int32* pDelta) mut => VT.[Friend]Find(&this, pRange, Count, Flags, pDelta);

	public HRESULT GetChar2(int32* pChar, int32 Offset) mut => VT.[Friend]GetChar2(&this, pChar, Offset);

	public HRESULT GetDropCap(int32* pcLine, int32* pPosition) mut => VT.[Friend]GetDropCap(&this, pcLine, pPosition);

	public HRESULT GetInlineObject(int32* pType, int32* pAlign, int32* pChar, int32* pChar1, int32* pChar2, int32* pCount, int32* pTeXStyle, int32* pcCol, int32* pLevel) mut => VT.[Friend]GetInlineObject(&this, pType, pAlign, pChar, pChar1, pChar2, pCount, pTeXStyle, pcCol, pLevel);

	public HRESULT GetProperty(int32 Type, int32* pValue) mut => VT.[Friend]GetProperty(&this, Type, pValue);

	public HRESULT GetRect(int32 Type, int32* pLeft, int32* pTop, int32* pRight, int32* pBottom, int32* pHit) mut => VT.[Friend]GetRect(&this, Type, pLeft, pTop, pRight, pBottom, pHit);

	public HRESULT GetSubrange(int32 iSubrange, int32* pcpFirst, int32* pcpLim) mut => VT.[Friend]GetSubrange(&this, iSubrange, pcpFirst, pcpLim);

	public HRESULT GetText2(int32 Flags, BSTR* pbstr) mut => VT.[Friend]GetText2(&this, Flags, pbstr);

	public HRESULT HexToUnicode() mut => VT.[Friend]HexToUnicode(&this);

	public HRESULT InsertTable(int32 cCol, int32 cRow, int32 AutoFit) mut => VT.[Friend]InsertTable(&this, cCol, cRow, AutoFit);

	public HRESULT Linearize(int32 Flags) mut => VT.[Friend]Linearize(&this, Flags);

	public HRESULT SetActiveSubrange(int32 cpAnchor, int32 cpActive) mut => VT.[Friend]SetActiveSubrange(&this, cpAnchor, cpActive);

	public HRESULT SetDropCap(int32 cLine, int32 Position) mut => VT.[Friend]SetDropCap(&this, cLine, Position);

	public HRESULT SetProperty(int32 Type, int32 Value) mut => VT.[Friend]SetProperty(&this, Type, Value);

	public HRESULT SetText2(int32 Flags, BSTR bstr) mut => VT.[Friend]SetText2(&this, Flags, bstr);

	public HRESULT UnicodeToHex() mut => VT.[Friend]UnicodeToHex(&this);

	public HRESULT SetInlineObject(int32 Type, int32 Align, int32 Char, int32 Char1, int32 Char2, int32 Count, int32 TeXStyle, int32 cCol) mut => VT.[Friend]SetInlineObject(&this, Type, Align, Char, Char1, Char2, Count, TeXStyle, cCol);

	public HRESULT GetMathFunctionType(BSTR bstr, int32* pValue) mut => VT.[Friend]GetMathFunctionType(&this, bstr, pValue);

	public HRESULT InsertImage(int32 width, int32 height, int32 ascent, TEXT_ALIGN_OPTIONS Type, BSTR bstrAltText, IStream* pStream) mut => VT.[Friend]InsertImage(&this, width, height, ascent, Type, bstrAltText, pStream);
}

[CRepr]struct ITextSelection2 : ITextRange2
{
	public new const Guid IID = .(0xc241f5e1, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextRange2.VTable
	{
	}

}

[CRepr]struct ITextFont2 : ITextFont
{
	public new const Guid IID = .(0xc241f5e3, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextFont.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAutoLigatures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAutoLigatures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAutospaceAlpha;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAutospaceAlpha;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAutospaceNumeric;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAutospaceNumeric;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAutospaceParens;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAutospaceParens;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCharRep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCharRep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCompressionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCompressionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCookie;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCookie;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetDoubleStrike;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetDoubleStrike;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2** ppFont) GetDuplicate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2* pFont) SetDuplicate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetLinkType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetMathZone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetMathZone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetModWidthPairs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetModWidthPairs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetModWidthSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetModWidthSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetOldNumbers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetOldNumbers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetOverlapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetOverlapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetPositionSubSuper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetPositionSubSuper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetScaling;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetScaling;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pValue) GetSpaceExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Value) SetSpaceExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetUnderlinePositionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetUnderlinePositionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue, int32* pMask) GetEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue, int32* pMask) GetEffects2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32* pType, int32* pValue) GetPropertyInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont2* pFont, int32* pB) IsEqual2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value, int32 Mask) SetEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value, int32 Mask) SetEffects2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Value) SetProperty;
	}


	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetAutoLigatures(int32* pValue) mut => VT.[Friend]GetAutoLigatures(&this, pValue);

	public HRESULT SetAutoLigatures(int32 Value) mut => VT.[Friend]SetAutoLigatures(&this, Value);

	public HRESULT GetAutospaceAlpha(int32* pValue) mut => VT.[Friend]GetAutospaceAlpha(&this, pValue);

	public HRESULT SetAutospaceAlpha(int32 Value) mut => VT.[Friend]SetAutospaceAlpha(&this, Value);

	public HRESULT GetAutospaceNumeric(int32* pValue) mut => VT.[Friend]GetAutospaceNumeric(&this, pValue);

	public HRESULT SetAutospaceNumeric(int32 Value) mut => VT.[Friend]SetAutospaceNumeric(&this, Value);

	public HRESULT GetAutospaceParens(int32* pValue) mut => VT.[Friend]GetAutospaceParens(&this, pValue);

	public HRESULT SetAutospaceParens(int32 Value) mut => VT.[Friend]SetAutospaceParens(&this, Value);

	public HRESULT GetCharRep(int32* pValue) mut => VT.[Friend]GetCharRep(&this, pValue);

	public HRESULT SetCharRep(int32 Value) mut => VT.[Friend]SetCharRep(&this, Value);

	public HRESULT GetCompressionMode(int32* pValue) mut => VT.[Friend]GetCompressionMode(&this, pValue);

	public HRESULT SetCompressionMode(int32 Value) mut => VT.[Friend]SetCompressionMode(&this, Value);

	public HRESULT GetCookie(int32* pValue) mut => VT.[Friend]GetCookie(&this, pValue);

	public HRESULT SetCookie(int32 Value) mut => VT.[Friend]SetCookie(&this, Value);

	public HRESULT GetDoubleStrike(int32* pValue) mut => VT.[Friend]GetDoubleStrike(&this, pValue);

	public HRESULT SetDoubleStrike(int32 Value) mut => VT.[Friend]SetDoubleStrike(&this, Value);

	public HRESULT GetDuplicate2(ITextFont2** ppFont) mut => VT.[Friend]GetDuplicate2(&this, ppFont);

	public HRESULT SetDuplicate2(ITextFont2* pFont) mut => VT.[Friend]SetDuplicate2(&this, pFont);

	public HRESULT GetLinkType(int32* pValue) mut => VT.[Friend]GetLinkType(&this, pValue);

	public HRESULT GetMathZone(int32* pValue) mut => VT.[Friend]GetMathZone(&this, pValue);

	public HRESULT SetMathZone(int32 Value) mut => VT.[Friend]SetMathZone(&this, Value);

	public HRESULT GetModWidthPairs(int32* pValue) mut => VT.[Friend]GetModWidthPairs(&this, pValue);

	public HRESULT SetModWidthPairs(int32 Value) mut => VT.[Friend]SetModWidthPairs(&this, Value);

	public HRESULT GetModWidthSpace(int32* pValue) mut => VT.[Friend]GetModWidthSpace(&this, pValue);

	public HRESULT SetModWidthSpace(int32 Value) mut => VT.[Friend]SetModWidthSpace(&this, Value);

	public HRESULT GetOldNumbers(int32* pValue) mut => VT.[Friend]GetOldNumbers(&this, pValue);

	public HRESULT SetOldNumbers(int32 Value) mut => VT.[Friend]SetOldNumbers(&this, Value);

	public HRESULT GetOverlapping(int32* pValue) mut => VT.[Friend]GetOverlapping(&this, pValue);

	public HRESULT SetOverlapping(int32 Value) mut => VT.[Friend]SetOverlapping(&this, Value);

	public HRESULT GetPositionSubSuper(int32* pValue) mut => VT.[Friend]GetPositionSubSuper(&this, pValue);

	public HRESULT SetPositionSubSuper(int32 Value) mut => VT.[Friend]SetPositionSubSuper(&this, Value);

	public HRESULT GetScaling(int32* pValue) mut => VT.[Friend]GetScaling(&this, pValue);

	public HRESULT SetScaling(int32 Value) mut => VT.[Friend]SetScaling(&this, Value);

	public HRESULT GetSpaceExtension(float* pValue) mut => VT.[Friend]GetSpaceExtension(&this, pValue);

	public HRESULT SetSpaceExtension(float Value) mut => VT.[Friend]SetSpaceExtension(&this, Value);

	public HRESULT GetUnderlinePositionMode(int32* pValue) mut => VT.[Friend]GetUnderlinePositionMode(&this, pValue);

	public HRESULT SetUnderlinePositionMode(int32 Value) mut => VT.[Friend]SetUnderlinePositionMode(&this, Value);

	public HRESULT GetEffects(int32* pValue, int32* pMask) mut => VT.[Friend]GetEffects(&this, pValue, pMask);

	public HRESULT GetEffects2(int32* pValue, int32* pMask) mut => VT.[Friend]GetEffects2(&this, pValue, pMask);

	public HRESULT GetProperty(int32 Type, int32* pValue) mut => VT.[Friend]GetProperty(&this, Type, pValue);

	public HRESULT GetPropertyInfo(int32 Index, int32* pType, int32* pValue) mut => VT.[Friend]GetPropertyInfo(&this, Index, pType, pValue);

	public HRESULT IsEqual2(ITextFont2* pFont, int32* pB) mut => VT.[Friend]IsEqual2(&this, pFont, pB);

	public HRESULT SetEffects(int32 Value, int32 Mask) mut => VT.[Friend]SetEffects(&this, Value, Mask);

	public HRESULT SetEffects2(int32 Value, int32 Mask) mut => VT.[Friend]SetEffects2(&this, Value, Mask);

	public HRESULT SetProperty(int32 Type, int32 Value) mut => VT.[Friend]SetProperty(&this, Type, Value);
}

[CRepr]struct ITextPara2 : ITextPara
{
	public new const Guid IID = .(0xc241f5e4, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextPara.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppBorders) GetBorders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2** ppPara) GetDuplicate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2* pPara) SetDuplicate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetFontAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetFontAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetHangingPunctuation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetHangingPunctuation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetSnapToGrid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetSnapToGrid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetTrimPunctuationAtStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetTrimPunctuationAtStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue, int32* pMask) GetEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara2* pPara, int32* pB) IsEqual2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value, int32 Mask) SetEffects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Value) SetProperty;
	}


	public HRESULT GetBorders(IUnknown** ppBorders) mut => VT.[Friend]GetBorders(&this, ppBorders);

	public HRESULT GetDuplicate2(ITextPara2** ppPara) mut => VT.[Friend]GetDuplicate2(&this, ppPara);

	public HRESULT SetDuplicate2(ITextPara2* pPara) mut => VT.[Friend]SetDuplicate2(&this, pPara);

	public HRESULT GetFontAlignment(int32* pValue) mut => VT.[Friend]GetFontAlignment(&this, pValue);

	public HRESULT SetFontAlignment(int32 Value) mut => VT.[Friend]SetFontAlignment(&this, Value);

	public HRESULT GetHangingPunctuation(int32* pValue) mut => VT.[Friend]GetHangingPunctuation(&this, pValue);

	public HRESULT SetHangingPunctuation(int32 Value) mut => VT.[Friend]SetHangingPunctuation(&this, Value);

	public HRESULT GetSnapToGrid(int32* pValue) mut => VT.[Friend]GetSnapToGrid(&this, pValue);

	public HRESULT SetSnapToGrid(int32 Value) mut => VT.[Friend]SetSnapToGrid(&this, Value);

	public HRESULT GetTrimPunctuationAtStart(int32* pValue) mut => VT.[Friend]GetTrimPunctuationAtStart(&this, pValue);

	public HRESULT SetTrimPunctuationAtStart(int32 Value) mut => VT.[Friend]SetTrimPunctuationAtStart(&this, Value);

	public HRESULT GetEffects(int32* pValue, int32* pMask) mut => VT.[Friend]GetEffects(&this, pValue, pMask);

	public HRESULT GetProperty(int32 Type, int32* pValue) mut => VT.[Friend]GetProperty(&this, Type, pValue);

	public HRESULT IsEqual2(ITextPara2* pPara, int32* pB) mut => VT.[Friend]IsEqual2(&this, pPara, pB);

	public HRESULT SetEffects(int32 Value, int32 Mask) mut => VT.[Friend]SetEffects(&this, Value, Mask);

	public HRESULT SetProperty(int32 Type, int32 Value) mut => VT.[Friend]SetProperty(&this, Type, Value);
}

[CRepr]struct ITextStoryRanges2 : ITextStoryRanges
{
	public new const Guid IID = .(0xc241f5e5, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextStoryRanges.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ITextRange2** ppRange) Item2;
	}


	public HRESULT Item2(int32 Index, ITextRange2** ppRange) mut => VT.[Friend]Item2(&this, Index, ppRange);
}

[CRepr]struct ITextStory : IUnknown
{
	public new const Guid IID = .(0xc241f5f3, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetActive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetActive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppDisplay) GetDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cpActive, int32 cpAnchor, ITextRange2** ppRange) GetRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR* pbstr) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnk) SetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Value) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR bstr) SetText;
	}


	public HRESULT GetActive(int32* pValue) mut => VT.[Friend]GetActive(&this, pValue);

	public HRESULT SetActive(int32 Value) mut => VT.[Friend]SetActive(&this, Value);

	public HRESULT GetDisplay(IUnknown** ppDisplay) mut => VT.[Friend]GetDisplay(&this, ppDisplay);

	public HRESULT GetIndex(int32* pValue) mut => VT.[Friend]GetIndex(&this, pValue);

	public HRESULT GetType(int32* pValue) mut => VT.[Friend]COM_GetType(&this, pValue);

	public HRESULT SetType(int32 Value) mut => VT.[Friend]SetType(&this, Value);

	public HRESULT GetProperty(int32 Type, int32* pValue) mut => VT.[Friend]GetProperty(&this, Type, pValue);

	public HRESULT GetRange(int32 cpActive, int32 cpAnchor, ITextRange2** ppRange) mut => VT.[Friend]GetRange(&this, cpActive, cpAnchor, ppRange);

	public HRESULT GetText(int32 Flags, BSTR* pbstr) mut => VT.[Friend]GetText(&this, Flags, pbstr);

	public HRESULT SetFormattedText(IUnknown* pUnk) mut => VT.[Friend]SetFormattedText(&this, pUnk);

	public HRESULT SetProperty(int32 Type, int32 Value) mut => VT.[Friend]SetProperty(&this, Type, Value);

	public HRESULT SetText(int32 Flags, BSTR bstr) mut => VT.[Friend]SetText(&this, Flags, bstr);
}

[CRepr]struct ITextStrings : IDispatch
{
	public new const Guid IID = .(0xc241f5e7, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ITextRange2** ppRange) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2* pRange, int32 iString) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iString) Cat2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) CatTop2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2* pRange) DeleteRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Align, int32 Char, int32 Char1, int32 Char2, int32 Count, int32 TeXStyle, int32 cCol, ITextRange2* pRange) EncodeFunction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iString, int32* pcch) GetCch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iString) InsertNullStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iString, int32 cch) MoveBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) PrefixTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iString, int32 cString) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRange2* pRangeD, ITextRange2* pRangeS) SetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iString, int32 cp) SetOpCp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr, ITextRange2* pRange) SuffixTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Swap;
	}


	public HRESULT Item(int32 Index, ITextRange2** ppRange) mut => VT.[Friend]Item(&this, Index, ppRange);

	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT Add(BSTR bstr) mut => VT.[Friend]Add(&this, bstr);

	public HRESULT Append(ITextRange2* pRange, int32 iString) mut => VT.[Friend]Append(&this, pRange, iString);

	public HRESULT Cat2(int32 iString) mut => VT.[Friend]Cat2(&this, iString);

	public HRESULT CatTop2(BSTR bstr) mut => VT.[Friend]CatTop2(&this, bstr);

	public HRESULT DeleteRange(ITextRange2* pRange) mut => VT.[Friend]DeleteRange(&this, pRange);

	public HRESULT EncodeFunction(int32 Type, int32 Align, int32 Char, int32 Char1, int32 Char2, int32 Count, int32 TeXStyle, int32 cCol, ITextRange2* pRange) mut => VT.[Friend]EncodeFunction(&this, Type, Align, Char, Char1, Char2, Count, TeXStyle, cCol, pRange);

	public HRESULT GetCch(int32 iString, int32* pcch) mut => VT.[Friend]GetCch(&this, iString, pcch);

	public HRESULT InsertNullStr(int32 iString) mut => VT.[Friend]InsertNullStr(&this, iString);

	public HRESULT MoveBoundary(int32 iString, int32 cch) mut => VT.[Friend]MoveBoundary(&this, iString, cch);

	public HRESULT PrefixTop(BSTR bstr) mut => VT.[Friend]PrefixTop(&this, bstr);

	public HRESULT Remove(int32 iString, int32 cString) mut => VT.[Friend]Remove(&this, iString, cString);

	public HRESULT SetFormattedText(ITextRange2* pRangeD, ITextRange2* pRangeS) mut => VT.[Friend]SetFormattedText(&this, pRangeD, pRangeS);

	public HRESULT SetOpCp(int32 iString, int32 cp) mut => VT.[Friend]SetOpCp(&this, iString, cp);

	public HRESULT SuffixTop(BSTR bstr, ITextRange2* pRange) mut => VT.[Friend]SuffixTop(&this, bstr, pRange);

	public HRESULT Swap() mut => VT.[Friend]Swap(&this);
}

[CRepr]struct ITextRow : IDispatch
{
	public new const Guid IID = .(0xc241f5ef, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellCountCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellCountCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellMargin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellMargin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetIndent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetIndent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetKeepTogether;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetKeepTogether;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetKeepWithNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetKeepWithNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetNestLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetRTL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetRTL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellColorBack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellColorBack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellColorFore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellColorFore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellMergeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellMergeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellShading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellShading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellVerticalText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellVerticalText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) GetCellWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) SetCellWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcrLeft, int32* pcrTop, int32* pcrRight, int32* pcrBottom) GetCellBorderColors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pduLeft, int32* pduTop, int32* pduRight, int32* pduBottom) GetCellBorderWidths;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 crLeft, int32 crTop, int32 crRight, int32 crBottom) SetCellBorderColors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 duLeft, int32 duTop, int32 duRight, int32 duBottom) SetCellBorderWidths;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cRow, tomConstants Flags) Apply;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) CanChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cRow) Insert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextRow* pRow, int32* pB) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32 Value) SetProperty;
	}


	public HRESULT GetAlignment(int32* pValue) mut => VT.[Friend]GetAlignment(&this, pValue);

	public HRESULT SetAlignment(int32 Value) mut => VT.[Friend]SetAlignment(&this, Value);

	public HRESULT GetCellCount(int32* pValue) mut => VT.[Friend]GetCellCount(&this, pValue);

	public HRESULT SetCellCount(int32 Value) mut => VT.[Friend]SetCellCount(&this, Value);

	public HRESULT GetCellCountCache(int32* pValue) mut => VT.[Friend]GetCellCountCache(&this, pValue);

	public HRESULT SetCellCountCache(int32 Value) mut => VT.[Friend]SetCellCountCache(&this, Value);

	public HRESULT GetCellIndex(int32* pValue) mut => VT.[Friend]GetCellIndex(&this, pValue);

	public HRESULT SetCellIndex(int32 Value) mut => VT.[Friend]SetCellIndex(&this, Value);

	public HRESULT GetCellMargin(int32* pValue) mut => VT.[Friend]GetCellMargin(&this, pValue);

	public HRESULT SetCellMargin(int32 Value) mut => VT.[Friend]SetCellMargin(&this, Value);

	public HRESULT GetHeight(int32* pValue) mut => VT.[Friend]GetHeight(&this, pValue);

	public HRESULT SetHeight(int32 Value) mut => VT.[Friend]SetHeight(&this, Value);

	public HRESULT GetIndent(int32* pValue) mut => VT.[Friend]GetIndent(&this, pValue);

	public HRESULT SetIndent(int32 Value) mut => VT.[Friend]SetIndent(&this, Value);

	public HRESULT GetKeepTogether(int32* pValue) mut => VT.[Friend]GetKeepTogether(&this, pValue);

	public HRESULT SetKeepTogether(int32 Value) mut => VT.[Friend]SetKeepTogether(&this, Value);

	public HRESULT GetKeepWithNext(int32* pValue) mut => VT.[Friend]GetKeepWithNext(&this, pValue);

	public HRESULT SetKeepWithNext(int32 Value) mut => VT.[Friend]SetKeepWithNext(&this, Value);

	public HRESULT GetNestLevel(int32* pValue) mut => VT.[Friend]GetNestLevel(&this, pValue);

	public HRESULT GetRTL(int32* pValue) mut => VT.[Friend]GetRTL(&this, pValue);

	public HRESULT SetRTL(int32 Value) mut => VT.[Friend]SetRTL(&this, Value);

	public HRESULT GetCellAlignment(int32* pValue) mut => VT.[Friend]GetCellAlignment(&this, pValue);

	public HRESULT SetCellAlignment(int32 Value) mut => VT.[Friend]SetCellAlignment(&this, Value);

	public HRESULT GetCellColorBack(int32* pValue) mut => VT.[Friend]GetCellColorBack(&this, pValue);

	public HRESULT SetCellColorBack(int32 Value) mut => VT.[Friend]SetCellColorBack(&this, Value);

	public HRESULT GetCellColorFore(int32* pValue) mut => VT.[Friend]GetCellColorFore(&this, pValue);

	public HRESULT SetCellColorFore(int32 Value) mut => VT.[Friend]SetCellColorFore(&this, Value);

	public HRESULT GetCellMergeFlags(int32* pValue) mut => VT.[Friend]GetCellMergeFlags(&this, pValue);

	public HRESULT SetCellMergeFlags(int32 Value) mut => VT.[Friend]SetCellMergeFlags(&this, Value);

	public HRESULT GetCellShading(int32* pValue) mut => VT.[Friend]GetCellShading(&this, pValue);

	public HRESULT SetCellShading(int32 Value) mut => VT.[Friend]SetCellShading(&this, Value);

	public HRESULT GetCellVerticalText(int32* pValue) mut => VT.[Friend]GetCellVerticalText(&this, pValue);

	public HRESULT SetCellVerticalText(int32 Value) mut => VT.[Friend]SetCellVerticalText(&this, Value);

	public HRESULT GetCellWidth(int32* pValue) mut => VT.[Friend]GetCellWidth(&this, pValue);

	public HRESULT SetCellWidth(int32 Value) mut => VT.[Friend]SetCellWidth(&this, Value);

	public HRESULT GetCellBorderColors(int32* pcrLeft, int32* pcrTop, int32* pcrRight, int32* pcrBottom) mut => VT.[Friend]GetCellBorderColors(&this, pcrLeft, pcrTop, pcrRight, pcrBottom);

	public HRESULT GetCellBorderWidths(int32* pduLeft, int32* pduTop, int32* pduRight, int32* pduBottom) mut => VT.[Friend]GetCellBorderWidths(&this, pduLeft, pduTop, pduRight, pduBottom);

	public HRESULT SetCellBorderColors(int32 crLeft, int32 crTop, int32 crRight, int32 crBottom) mut => VT.[Friend]SetCellBorderColors(&this, crLeft, crTop, crRight, crBottom);

	public HRESULT SetCellBorderWidths(int32 duLeft, int32 duTop, int32 duRight, int32 duBottom) mut => VT.[Friend]SetCellBorderWidths(&this, duLeft, duTop, duRight, duBottom);

	public HRESULT Apply(int32 cRow, tomConstants Flags) mut => VT.[Friend]Apply(&this, cRow, Flags);

	public HRESULT CanChange(int32* pValue) mut => VT.[Friend]CanChange(&this, pValue);

	public HRESULT GetProperty(int32 Type, int32* pValue) mut => VT.[Friend]GetProperty(&this, Type, pValue);

	public HRESULT Insert(int32 cRow) mut => VT.[Friend]Insert(&this, cRow);

	public HRESULT IsEqual(ITextRow* pRow, int32* pB) mut => VT.[Friend]IsEqual(&this, pRow, pB);

	public HRESULT Reset(int32 Value) mut => VT.[Friend]Reset(&this, Value);

	public HRESULT SetProperty(int32 Type, int32 Value) mut => VT.[Friend]SetProperty(&this, Type, Value);
}

[CRepr]struct ITextDisplays : IDispatch
{
	public new const Guid IID = .(0xc241f5f2, 0x7206, 0x11d8, 0xa2, 0xc7, 0x00, 0xa0, 0xd1, 0xd6, 0xc6, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct ITextDocument2Old : ITextDocument
{
	public new const Guid IID = .(0x01c25500, 0x4268, 0x11d1, 0x88, 0x3a, 0x3c, 0x8b, 0x00, 0xc1, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextDocument.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pFilter) AttachMsgFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, COLORREF cr) SetEffectColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, COLORREF* pcr) GetEffectColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCaretType) GetCaretType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 CaretType) SetCaretType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pContext) GetImmContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 Context) ReleaseImmContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cp, int32 CharRep, int32 Option, int32 CharRepCur, int32 curFontSize, BSTR* pbstr, int32* pPitchAndFamily, int32* pNewFontSize) GetPreferredFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pMode) GetNotificationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Mode) SetNotificationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Type, int32* pLeft, int32* pTop, int32* pRight, int32* pBottom) GetClientRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextSelection** ppSel) GetSelection2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* phWnd) GetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pFlags) GetFEFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cch, int32* pcch) CheckTextLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) IMEInProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SysBeep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Mode) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Notify) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextFont** ppITextFont) GetDocumentFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITextPara** ppITextPara) GetDocumentPara;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppVoid) GetCallManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pVoid) ReleaseCallManager;
	}


	public HRESULT AttachMsgFilter(IUnknown* pFilter) mut => VT.[Friend]AttachMsgFilter(&this, pFilter);

	public HRESULT SetEffectColor(int32 Index, COLORREF cr) mut => VT.[Friend]SetEffectColor(&this, Index, cr);

	public HRESULT GetEffectColor(int32 Index, COLORREF* pcr) mut => VT.[Friend]GetEffectColor(&this, Index, pcr);

	public HRESULT GetCaretType(int32* pCaretType) mut => VT.[Friend]GetCaretType(&this, pCaretType);

	public HRESULT SetCaretType(int32 CaretType) mut => VT.[Friend]SetCaretType(&this, CaretType);

	public HRESULT GetImmContext(int64* pContext) mut => VT.[Friend]GetImmContext(&this, pContext);

	public HRESULT ReleaseImmContext(int64 Context) mut => VT.[Friend]ReleaseImmContext(&this, Context);

	public HRESULT GetPreferredFont(int32 cp, int32 CharRep, int32 Option, int32 CharRepCur, int32 curFontSize, BSTR* pbstr, int32* pPitchAndFamily, int32* pNewFontSize) mut => VT.[Friend]GetPreferredFont(&this, cp, CharRep, Option, CharRepCur, curFontSize, pbstr, pPitchAndFamily, pNewFontSize);

	public HRESULT GetNotificationMode(int32* pMode) mut => VT.[Friend]GetNotificationMode(&this, pMode);

	public HRESULT SetNotificationMode(int32 Mode) mut => VT.[Friend]SetNotificationMode(&this, Mode);

	public HRESULT GetClientRect(int32 Type, int32* pLeft, int32* pTop, int32* pRight, int32* pBottom) mut => VT.[Friend]GetClientRect(&this, Type, pLeft, pTop, pRight, pBottom);

	public HRESULT GetSelection2(ITextSelection** ppSel) mut => VT.[Friend]GetSelection2(&this, ppSel);

	public HRESULT GetWindow(int32* phWnd) mut => VT.[Friend]GetWindow(&this, phWnd);

	public HRESULT GetFEFlags(int32* pFlags) mut => VT.[Friend]GetFEFlags(&this, pFlags);

	public HRESULT UpdateWindow() mut => VT.[Friend]UpdateWindow(&this);

	public HRESULT CheckTextLimit(int32 cch, int32* pcch) mut => VT.[Friend]CheckTextLimit(&this, cch, pcch);

	public HRESULT IMEInProgress(int32 Value) mut => VT.[Friend]IMEInProgress(&this, Value);

	public HRESULT SysBeep() mut => VT.[Friend]SysBeep(&this);

	public HRESULT Update(int32 Mode) mut => VT.[Friend]Update(&this, Mode);

	public HRESULT Notify(int32 Notify) mut => VT.[Friend]Notify(&this, Notify);

	public HRESULT GetDocumentFont(ITextFont** ppITextFont) mut => VT.[Friend]GetDocumentFont(&this, ppITextFont);

	public HRESULT GetDocumentPara(ITextPara** ppITextPara) mut => VT.[Friend]GetDocumentPara(&this, ppITextPara);

	public HRESULT GetCallManager(IUnknown** ppVoid) mut => VT.[Friend]GetCallManager(&this, ppVoid);

	public HRESULT ReleaseCallManager(IUnknown* pVoid) mut => VT.[Friend]ReleaseCallManager(&this, pVoid);
}

#endregion
