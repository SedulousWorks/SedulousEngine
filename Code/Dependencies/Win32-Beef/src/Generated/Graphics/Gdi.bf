using Win32.Foundation;
using System;

namespace Win32.Graphics.Gdi;

#region Constants
public static
{
	public const int32 GDI_ERROR = -1;
	public const int32 ERROR = 0;
	public const uint32 MAXSTRETCHBLTMODE = 4;
	public const uint32 POLYFILL_LAST = 2;
	public const uint32 LAYOUT_BTT = 2;
	public const uint32 LAYOUT_VBH = 4;
	public const uint32 ASPECT_FILTERING = 1;
	public const uint32 META_SETBKCOLOR = 513;
	public const uint32 META_SETBKMODE = 258;
	public const uint32 META_SETMAPMODE = 259;
	public const uint32 META_SETROP2 = 260;
	public const uint32 META_SETRELABS = 261;
	public const uint32 META_SETPOLYFILLMODE = 262;
	public const uint32 META_SETSTRETCHBLTMODE = 263;
	public const uint32 META_SETTEXTCHAREXTRA = 264;
	public const uint32 META_SETTEXTCOLOR = 521;
	public const uint32 META_SETTEXTJUSTIFICATION = 522;
	public const uint32 META_SETWINDOWORG = 523;
	public const uint32 META_SETWINDOWEXT = 524;
	public const uint32 META_SETVIEWPORTORG = 525;
	public const uint32 META_SETVIEWPORTEXT = 526;
	public const uint32 META_OFFSETWINDOWORG = 527;
	public const uint32 META_SCALEWINDOWEXT = 1040;
	public const uint32 META_OFFSETVIEWPORTORG = 529;
	public const uint32 META_SCALEVIEWPORTEXT = 1042;
	public const uint32 META_LINETO = 531;
	public const uint32 META_MOVETO = 532;
	public const uint32 META_EXCLUDECLIPRECT = 1045;
	public const uint32 META_INTERSECTCLIPRECT = 1046;
	public const uint32 META_ARC = 2071;
	public const uint32 META_ELLIPSE = 1048;
	public const uint32 META_FLOODFILL = 1049;
	public const uint32 META_PIE = 2074;
	public const uint32 META_RECTANGLE = 1051;
	public const uint32 META_ROUNDRECT = 1564;
	public const uint32 META_PATBLT = 1565;
	public const uint32 META_SAVEDC = 30;
	public const uint32 META_SETPIXEL = 1055;
	public const uint32 META_OFFSETCLIPRGN = 544;
	public const uint32 META_TEXTOUT = 1313;
	public const uint32 META_BITBLT = 2338;
	public const uint32 META_STRETCHBLT = 2851;
	public const uint32 META_POLYGON = 804;
	public const uint32 META_POLYLINE = 805;
	public const uint32 META_ESCAPE = 1574;
	public const uint32 META_RESTOREDC = 295;
	public const uint32 META_FILLREGION = 552;
	public const uint32 META_FRAMEREGION = 1065;
	public const uint32 META_INVERTREGION = 298;
	public const uint32 META_PAINTREGION = 299;
	public const uint32 META_SELECTCLIPREGION = 300;
	public const uint32 META_SELECTOBJECT = 301;
	public const uint32 META_SETTEXTALIGN = 302;
	public const uint32 META_CHORD = 2096;
	public const uint32 META_SETMAPPERFLAGS = 561;
	public const uint32 META_EXTTEXTOUT = 2610;
	public const uint32 META_SETDIBTODEV = 3379;
	public const uint32 META_SELECTPALETTE = 564;
	public const uint32 META_REALIZEPALETTE = 53;
	public const uint32 META_ANIMATEPALETTE = 1078;
	public const uint32 META_SETPALENTRIES = 55;
	public const uint32 META_POLYPOLYGON = 1336;
	public const uint32 META_RESIZEPALETTE = 313;
	public const uint32 META_DIBBITBLT = 2368;
	public const uint32 META_DIBSTRETCHBLT = 2881;
	public const uint32 META_DIBCREATEPATTERNBRUSH = 322;
	public const uint32 META_STRETCHDIB = 3907;
	public const uint32 META_EXTFLOODFILL = 1352;
	public const uint32 META_SETLAYOUT = 329;
	public const uint32 META_DELETEOBJECT = 496;
	public const uint32 META_CREATEPALETTE = 247;
	public const uint32 META_CREATEPATTERNBRUSH = 505;
	public const uint32 META_CREATEPENINDIRECT = 762;
	public const uint32 META_CREATEFONTINDIRECT = 763;
	public const uint32 META_CREATEBRUSHINDIRECT = 764;
	public const uint32 META_CREATEREGION = 1791;
	public const uint32 NEWFRAME = 1;
	public const uint32 ABORTDOC = 2;
	public const uint32 NEXTBAND = 3;
	public const uint32 SETCOLORTABLE = 4;
	public const uint32 GETCOLORTABLE = 5;
	public const uint32 FLUSHOUTPUT = 6;
	public const uint32 DRAFTMODE = 7;
	public const uint32 QUERYESCSUPPORT = 8;
	public const uint32 SETABORTPROC = 9;
	public const uint32 STARTDOC = 10;
	public const uint32 ENDDOC = 11;
	public const uint32 GETPHYSPAGESIZE = 12;
	public const uint32 GETPRINTINGOFFSET = 13;
	public const uint32 GETSCALINGFACTOR = 14;
	public const uint32 MFCOMMENT = 15;
	public const uint32 GETPENWIDTH = 16;
	public const uint32 SETCOPYCOUNT = 17;
	public const uint32 SELECTPAPERSOURCE = 18;
	public const uint32 DEVICEDATA = 19;
	public const uint32 PASSTHROUGH = 19;
	public const uint32 GETTECHNOLGY = 20;
	public const uint32 GETTECHNOLOGY = 20;
	public const uint32 SETLINECAP = 21;
	public const uint32 SETLINEJOIN = 22;
	public const uint32 SETMITERLIMIT = 23;
	public const uint32 BANDINFO = 24;
	public const uint32 DRAWPATTERNRECT = 25;
	public const uint32 GETVECTORPENSIZE = 26;
	public const uint32 GETVECTORBRUSHSIZE = 27;
	public const uint32 ENABLEDUPLEX = 28;
	public const uint32 GETSETPAPERBINS = 29;
	public const uint32 GETSETPRINTORIENT = 30;
	public const uint32 ENUMPAPERBINS = 31;
	public const uint32 SETDIBSCALING = 32;
	public const uint32 EPSPRINTING = 33;
	public const uint32 ENUMPAPERMETRICS = 34;
	public const uint32 GETSETPAPERMETRICS = 35;
	public const uint32 POSTSCRIPT_DATA = 37;
	public const uint32 POSTSCRIPT_IGNORE = 38;
	public const uint32 MOUSETRAILS = 39;
	public const uint32 GETDEVICEUNITS = 42;
	public const uint32 GETEXTENDEDTEXTMETRICS = 256;
	public const uint32 GETEXTENTTABLE = 257;
	public const uint32 GETPAIRKERNTABLE = 258;
	public const uint32 GETTRACKKERNTABLE = 259;
	public const uint32 EXTTEXTOUT = 512;
	public const uint32 GETFACENAME = 513;
	public const uint32 DOWNLOADFACE = 514;
	public const uint32 ENABLERELATIVEWIDTHS = 768;
	public const uint32 ENABLEPAIRKERNING = 769;
	public const uint32 SETKERNTRACK = 770;
	public const uint32 SETALLJUSTVALUES = 771;
	public const uint32 SETCHARSET = 772;
	public const uint32 STRETCHBLT = 2048;
	public const uint32 METAFILE_DRIVER = 2049;
	public const uint32 GETSETSCREENPARAMS = 3072;
	public const uint32 QUERYDIBSUPPORT = 3073;
	public const uint32 BEGIN_PATH = 4096;
	public const uint32 CLIP_TO_PATH = 4097;
	public const uint32 END_PATH = 4098;
	public const uint32 EXT_DEVICE_CAPS = 4099;
	public const uint32 RESTORE_CTM = 4100;
	public const uint32 SAVE_CTM = 4101;
	public const uint32 SET_ARC_DIRECTION = 4102;
	public const uint32 SET_BACKGROUND_COLOR = 4103;
	public const uint32 SET_POLY_MODE = 4104;
	public const uint32 SET_SCREEN_ANGLE = 4105;
	public const uint32 SET_SPREAD = 4106;
	public const uint32 TRANSFORM_CTM = 4107;
	public const uint32 SET_CLIP_BOX = 4108;
	public const uint32 SET_BOUNDS = 4109;
	public const uint32 SET_MIRROR_MODE = 4110;
	public const uint32 OPENCHANNEL = 4110;
	public const uint32 DOWNLOADHEADER = 4111;
	public const uint32 CLOSECHANNEL = 4112;
	public const uint32 POSTSCRIPT_PASSTHROUGH = 4115;
	public const uint32 ENCAPSULATED_POSTSCRIPT = 4116;
	public const uint32 POSTSCRIPT_IDENTIFY = 4117;
	public const uint32 POSTSCRIPT_INJECTION = 4118;
	public const uint32 CHECKJPEGFORMAT = 4119;
	public const uint32 CHECKPNGFORMAT = 4120;
	public const uint32 GET_PS_FEATURESETTING = 4121;
	public const uint32 GDIPLUS_TS_QUERYVER = 4122;
	public const uint32 GDIPLUS_TS_RECORD = 4123;
	public const uint32 MILCORE_TS_QUERYVER_RESULT_FALSE = 0;
	public const uint32 MILCORE_TS_QUERYVER_RESULT_TRUE = 2147483647;
	public const uint32 SPCLPASSTHROUGH2 = 4568;
	public const uint32 PSIDENT_GDICENTRIC = 0;
	public const uint32 PSIDENT_PSCENTRIC = 1;
	public const uint32 PSINJECT_DLFONT = 3722304989;
	public const uint32 FEATURESETTING_NUP = 0;
	public const uint32 FEATURESETTING_OUTPUT = 1;
	public const uint32 FEATURESETTING_PSLEVEL = 2;
	public const uint32 FEATURESETTING_CUSTPAPER = 3;
	public const uint32 FEATURESETTING_MIRROR = 4;
	public const uint32 FEATURESETTING_NEGATIVE = 5;
	public const uint32 FEATURESETTING_PROTOCOL = 6;
	public const uint32 FEATURESETTING_PRIVATE_BEGIN = 4096;
	public const uint32 FEATURESETTING_PRIVATE_END = 8191;
	public const uint32 PSPROTOCOL_ASCII = 0;
	public const uint32 PSPROTOCOL_BCP = 1;
	public const uint32 PSPROTOCOL_TBCP = 2;
	public const uint32 PSPROTOCOL_BINARY = 3;
	public const uint32 QDI_SETDIBITS = 1;
	public const uint32 QDI_GETDIBITS = 2;
	public const uint32 QDI_DIBTOSCREEN = 4;
	public const uint32 QDI_STRETCHDIB = 8;
	public const uint32 SP_NOTREPORTED = 16384;
	public const int32 SP_ERROR = -1;
	public const int32 SP_APPABORT = -2;
	public const int32 SP_USERABORT = -3;
	public const int32 SP_OUTOFDISK = -4;
	public const int32 SP_OUTOFMEMORY = -5;
	public const uint32 PR_JOBSTATUS = 0;
	public const int32 LCS_CALIBRATED_RGB = 0;
	public const int32 LCS_GM_BUSINESS = 1;
	public const int32 LCS_GM_GRAPHICS = 2;
	public const int32 LCS_GM_IMAGES = 4;
	public const int32 LCS_GM_ABS_COLORIMETRIC = 8;
	public const uint32 CM_OUT_OF_GAMUT = 255;
	public const uint32 CM_IN_GAMUT = 0;
	public const int32 NTM_REGULAR = 64;
	public const int32 NTM_BOLD = 32;
	public const int32 NTM_ITALIC = 1;
	public const uint32 NTM_NONNEGATIVE_AC = 65536;
	public const uint32 NTM_PS_OPENTYPE = 131072;
	public const uint32 NTM_TT_OPENTYPE = 262144;
	public const uint32 NTM_MULTIPLEMASTER = 524288;
	public const uint32 NTM_TYPE1 = 1048576;
	public const uint32 NTM_DSIG = 2097152;
	public const uint32 LF_FACESIZE = 32;
	public const uint32 LF_FULLFACESIZE = 64;
	public const uint32 CLEARTYPE_NATURAL_QUALITY = 6;
	public const uint32 MONO_FONT = 8;
	public const int32 FS_LATIN1 = 1;
	public const int32 FS_LATIN2 = 2;
	public const int32 FS_CYRILLIC = 4;
	public const int32 FS_GREEK = 8;
	public const int32 FS_TURKISH = 16;
	public const int32 FS_HEBREW = 32;
	public const int32 FS_ARABIC = 64;
	public const int32 FS_BALTIC = 128;
	public const int32 FS_VIETNAMESE = 256;
	public const int32 FS_THAI = 65536;
	public const int32 FS_JISJAPAN = 131072;
	public const int32 FS_CHINESESIMP = 262144;
	public const int32 FS_WANSUNG = 524288;
	public const int32 FS_CHINESETRAD = 1048576;
	public const int32 FS_JOHAB = 2097152;
	public const int32 FS_SYMBOL = -2147483648;
	public const uint32 PANOSE_COUNT = 10;
	public const uint32 PAN_FAMILYTYPE_INDEX = 0;
	public const uint32 PAN_SERIFSTYLE_INDEX = 1;
	public const uint32 PAN_PROPORTION_INDEX = 3;
	public const uint32 PAN_STROKEVARIATION_INDEX = 5;
	public const uint32 PAN_ARMSTYLE_INDEX = 6;
	public const uint32 PAN_LETTERFORM_INDEX = 7;
	public const uint32 PAN_CULTURE_LATIN = 0;
	public const uint32 PAN_ANY = 0;
	public const uint32 PAN_NO_FIT = 1;
	public const uint32 ELF_VENDOR_SIZE = 4;
	public const uint32 ELF_VERSION = 0;
	public const uint32 ELF_CULTURE_LATIN = 0;
	public const uint32 RASTER_FONTTYPE = 1;
	public const uint32 DEVICE_FONTTYPE = 2;
	public const uint32 TRUETYPE_FONTTYPE = 4;
	public const uint32 PC_RESERVED = 1;
	public const uint32 PC_EXPLICIT = 2;
	public const uint32 PC_NOCOLLAPSE = 4;
	public const uint32 BKMODE_LAST = 2;
	public const uint32 GM_LAST = 2;
	public const uint32 PT_CLOSEFIGURE = 1;
	public const uint32 PT_LINETO = 2;
	public const uint32 PT_BEZIERTO = 4;
	public const uint32 PT_MOVETO = 6;
	public const uint32 ABSOLUTE = 1;
	public const uint32 RELATIVE = 2;
	public const uint32 STOCK_LAST = 19;
	public const uint32 CLR_INVALID = 4294967295;
	public const uint32 HS_API_MAX = 12;
	public const uint32 DT_PLOTTER = 0;
	public const uint32 DT_RASDISPLAY = 1;
	public const uint32 DT_RASPRINTER = 2;
	public const uint32 DT_RASCAMERA = 3;
	public const uint32 DT_CHARSTREAM = 4;
	public const uint32 DT_METAFILE = 5;
	public const uint32 DT_DISPFILE = 6;
	public const uint32 CC_NONE = 0;
	public const uint32 CC_CIRCLES = 1;
	public const uint32 CC_PIE = 2;
	public const uint32 CC_CHORD = 4;
	public const uint32 CC_ELLIPSES = 8;
	public const uint32 CC_WIDE = 16;
	public const uint32 CC_STYLED = 32;
	public const uint32 CC_WIDESTYLED = 64;
	public const uint32 CC_INTERIORS = 128;
	public const uint32 CC_ROUNDRECT = 256;
	public const uint32 LC_NONE = 0;
	public const uint32 LC_POLYLINE = 2;
	public const uint32 LC_MARKER = 4;
	public const uint32 LC_POLYMARKER = 8;
	public const uint32 LC_WIDE = 16;
	public const uint32 LC_STYLED = 32;
	public const uint32 LC_WIDESTYLED = 64;
	public const uint32 LC_INTERIORS = 128;
	public const uint32 PC_NONE = 0;
	public const uint32 PC_POLYGON = 1;
	public const uint32 PC_RECTANGLE = 2;
	public const uint32 PC_WINDPOLYGON = 4;
	public const uint32 PC_TRAPEZOID = 4;
	public const uint32 PC_SCANLINE = 8;
	public const uint32 PC_WIDE = 16;
	public const uint32 PC_STYLED = 32;
	public const uint32 PC_WIDESTYLED = 64;
	public const uint32 PC_INTERIORS = 128;
	public const uint32 PC_POLYPOLYGON = 256;
	public const uint32 PC_PATHS = 512;
	public const uint32 CP_NONE = 0;
	public const uint32 CP_RECTANGLE = 1;
	public const uint32 CP_REGION = 2;
	public const uint32 TC_OP_CHARACTER = 1;
	public const uint32 TC_OP_STROKE = 2;
	public const uint32 TC_CP_STROKE = 4;
	public const uint32 TC_CR_90 = 8;
	public const uint32 TC_CR_ANY = 16;
	public const uint32 TC_SF_X_YINDEP = 32;
	public const uint32 TC_SA_DOUBLE = 64;
	public const uint32 TC_SA_INTEGER = 128;
	public const uint32 TC_SA_CONTIN = 256;
	public const uint32 TC_EA_DOUBLE = 512;
	public const uint32 TC_IA_ABLE = 1024;
	public const uint32 TC_UA_ABLE = 2048;
	public const uint32 TC_SO_ABLE = 4096;
	public const uint32 TC_RA_ABLE = 8192;
	public const uint32 TC_VA_ABLE = 16384;
	public const uint32 TC_RESERVED = 32768;
	public const uint32 TC_SCROLLBLT = 65536;
	public const uint32 RC_BITBLT = 1;
	public const uint32 RC_BANDING = 2;
	public const uint32 RC_SCALING = 4;
	public const uint32 RC_BITMAP64 = 8;
	public const uint32 RC_GDI20_OUTPUT = 16;
	public const uint32 RC_GDI20_STATE = 32;
	public const uint32 RC_SAVEBITMAP = 64;
	public const uint32 RC_DI_BITMAP = 128;
	public const uint32 RC_PALETTE = 256;
	public const uint32 RC_DIBTODEV = 512;
	public const uint32 RC_BIGFONT = 1024;
	public const uint32 RC_STRETCHBLT = 2048;
	public const uint32 RC_FLOODFILL = 4096;
	public const uint32 RC_STRETCHDIB = 8192;
	public const uint32 RC_OP_DX_OUTPUT = 16384;
	public const uint32 RC_DEVBITS = 32768;
	public const uint32 SB_NONE = 0;
	public const uint32 SB_CONST_ALPHA = 1;
	public const uint32 SB_PIXEL_ALPHA = 2;
	public const uint32 SB_PREMULT_ALPHA = 4;
	public const uint32 SB_GRAD_RECT = 16;
	public const uint32 SB_GRAD_TRI = 32;
	public const uint32 CM_NONE = 0;
	public const uint32 CM_DEVICE_ICM = 1;
	public const uint32 CM_GAMMA_RAMP = 2;
	public const uint32 CM_CMYK_COLOR = 4;
	public const uint32 SYSPAL_ERROR = 0;
	public const int32 CBM_INIT = 4;
	public const uint32 CCHFORMNAME = 32;
	public const uint32 DMORIENT_PORTRAIT = 1;
	public const uint32 DMORIENT_LANDSCAPE = 2;
	public const uint32 DMPAPER_LETTER = 1;
	public const uint32 DMPAPER_LETTERSMALL = 2;
	public const uint32 DMPAPER_TABLOID = 3;
	public const uint32 DMPAPER_LEDGER = 4;
	public const uint32 DMPAPER_LEGAL = 5;
	public const uint32 DMPAPER_STATEMENT = 6;
	public const uint32 DMPAPER_EXECUTIVE = 7;
	public const uint32 DMPAPER_A3 = 8;
	public const uint32 DMPAPER_A4 = 9;
	public const uint32 DMPAPER_A4SMALL = 10;
	public const uint32 DMPAPER_A5 = 11;
	public const uint32 DMPAPER_B4 = 12;
	public const uint32 DMPAPER_B5 = 13;
	public const uint32 DMPAPER_FOLIO = 14;
	public const uint32 DMPAPER_QUARTO = 15;
	public const uint32 DMPAPER_10X14 = 16;
	public const uint32 DMPAPER_11X17 = 17;
	public const uint32 DMPAPER_NOTE = 18;
	public const uint32 DMPAPER_ENV_9 = 19;
	public const uint32 DMPAPER_ENV_10 = 20;
	public const uint32 DMPAPER_ENV_11 = 21;
	public const uint32 DMPAPER_ENV_12 = 22;
	public const uint32 DMPAPER_ENV_14 = 23;
	public const uint32 DMPAPER_CSHEET = 24;
	public const uint32 DMPAPER_DSHEET = 25;
	public const uint32 DMPAPER_ESHEET = 26;
	public const uint32 DMPAPER_ENV_DL = 27;
	public const uint32 DMPAPER_ENV_C5 = 28;
	public const uint32 DMPAPER_ENV_C3 = 29;
	public const uint32 DMPAPER_ENV_C4 = 30;
	public const uint32 DMPAPER_ENV_C6 = 31;
	public const uint32 DMPAPER_ENV_C65 = 32;
	public const uint32 DMPAPER_ENV_B4 = 33;
	public const uint32 DMPAPER_ENV_B5 = 34;
	public const uint32 DMPAPER_ENV_B6 = 35;
	public const uint32 DMPAPER_ENV_ITALY = 36;
	public const uint32 DMPAPER_ENV_MONARCH = 37;
	public const uint32 DMPAPER_ENV_PERSONAL = 38;
	public const uint32 DMPAPER_FANFOLD_US = 39;
	public const uint32 DMPAPER_FANFOLD_STD_GERMAN = 40;
	public const uint32 DMPAPER_FANFOLD_LGL_GERMAN = 41;
	public const uint32 DMPAPER_ISO_B4 = 42;
	public const uint32 DMPAPER_JAPANESE_POSTCARD = 43;
	public const uint32 DMPAPER_9X11 = 44;
	public const uint32 DMPAPER_10X11 = 45;
	public const uint32 DMPAPER_15X11 = 46;
	public const uint32 DMPAPER_ENV_INVITE = 47;
	public const uint32 DMPAPER_RESERVED_48 = 48;
	public const uint32 DMPAPER_RESERVED_49 = 49;
	public const uint32 DMPAPER_LETTER_EXTRA = 50;
	public const uint32 DMPAPER_LEGAL_EXTRA = 51;
	public const uint32 DMPAPER_TABLOID_EXTRA = 52;
	public const uint32 DMPAPER_A4_EXTRA = 53;
	public const uint32 DMPAPER_LETTER_TRANSVERSE = 54;
	public const uint32 DMPAPER_A4_TRANSVERSE = 55;
	public const uint32 DMPAPER_LETTER_EXTRA_TRANSVERSE = 56;
	public const uint32 DMPAPER_A_PLUS = 57;
	public const uint32 DMPAPER_B_PLUS = 58;
	public const uint32 DMPAPER_LETTER_PLUS = 59;
	public const uint32 DMPAPER_A4_PLUS = 60;
	public const uint32 DMPAPER_A5_TRANSVERSE = 61;
	public const uint32 DMPAPER_B5_TRANSVERSE = 62;
	public const uint32 DMPAPER_A3_EXTRA = 63;
	public const uint32 DMPAPER_A5_EXTRA = 64;
	public const uint32 DMPAPER_B5_EXTRA = 65;
	public const uint32 DMPAPER_A2 = 66;
	public const uint32 DMPAPER_A3_TRANSVERSE = 67;
	public const uint32 DMPAPER_A3_EXTRA_TRANSVERSE = 68;
	public const uint32 DMPAPER_DBL_JAPANESE_POSTCARD = 69;
	public const uint32 DMPAPER_A6 = 70;
	public const uint32 DMPAPER_JENV_KAKU2 = 71;
	public const uint32 DMPAPER_JENV_KAKU3 = 72;
	public const uint32 DMPAPER_JENV_CHOU3 = 73;
	public const uint32 DMPAPER_JENV_CHOU4 = 74;
	public const uint32 DMPAPER_LETTER_ROTATED = 75;
	public const uint32 DMPAPER_A3_ROTATED = 76;
	public const uint32 DMPAPER_A4_ROTATED = 77;
	public const uint32 DMPAPER_A5_ROTATED = 78;
	public const uint32 DMPAPER_B4_JIS_ROTATED = 79;
	public const uint32 DMPAPER_B5_JIS_ROTATED = 80;
	public const uint32 DMPAPER_JAPANESE_POSTCARD_ROTATED = 81;
	public const uint32 DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED = 82;
	public const uint32 DMPAPER_A6_ROTATED = 83;
	public const uint32 DMPAPER_JENV_KAKU2_ROTATED = 84;
	public const uint32 DMPAPER_JENV_KAKU3_ROTATED = 85;
	public const uint32 DMPAPER_JENV_CHOU3_ROTATED = 86;
	public const uint32 DMPAPER_JENV_CHOU4_ROTATED = 87;
	public const uint32 DMPAPER_B6_JIS = 88;
	public const uint32 DMPAPER_B6_JIS_ROTATED = 89;
	public const uint32 DMPAPER_12X11 = 90;
	public const uint32 DMPAPER_JENV_YOU4 = 91;
	public const uint32 DMPAPER_JENV_YOU4_ROTATED = 92;
	public const uint32 DMPAPER_P16K = 93;
	public const uint32 DMPAPER_P32K = 94;
	public const uint32 DMPAPER_P32KBIG = 95;
	public const uint32 DMPAPER_PENV_1 = 96;
	public const uint32 DMPAPER_PENV_2 = 97;
	public const uint32 DMPAPER_PENV_3 = 98;
	public const uint32 DMPAPER_PENV_4 = 99;
	public const uint32 DMPAPER_PENV_5 = 100;
	public const uint32 DMPAPER_PENV_6 = 101;
	public const uint32 DMPAPER_PENV_7 = 102;
	public const uint32 DMPAPER_PENV_8 = 103;
	public const uint32 DMPAPER_PENV_9 = 104;
	public const uint32 DMPAPER_PENV_10 = 105;
	public const uint32 DMPAPER_P16K_ROTATED = 106;
	public const uint32 DMPAPER_P32K_ROTATED = 107;
	public const uint32 DMPAPER_P32KBIG_ROTATED = 108;
	public const uint32 DMPAPER_PENV_1_ROTATED = 109;
	public const uint32 DMPAPER_PENV_2_ROTATED = 110;
	public const uint32 DMPAPER_PENV_3_ROTATED = 111;
	public const uint32 DMPAPER_PENV_4_ROTATED = 112;
	public const uint32 DMPAPER_PENV_5_ROTATED = 113;
	public const uint32 DMPAPER_PENV_6_ROTATED = 114;
	public const uint32 DMPAPER_PENV_7_ROTATED = 115;
	public const uint32 DMPAPER_PENV_8_ROTATED = 116;
	public const uint32 DMPAPER_PENV_9_ROTATED = 117;
	public const uint32 DMPAPER_PENV_10_ROTATED = 118;
	public const uint32 DMPAPER_LAST = 118;
	public const uint32 DMPAPER_USER = 256;
	public const uint32 DMBIN_UPPER = 1;
	public const uint32 DMBIN_ONLYONE = 1;
	public const uint32 DMBIN_LOWER = 2;
	public const uint32 DMBIN_MIDDLE = 3;
	public const uint32 DMBIN_MANUAL = 4;
	public const uint32 DMBIN_ENVELOPE = 5;
	public const uint32 DMBIN_ENVMANUAL = 6;
	public const uint32 DMBIN_AUTO = 7;
	public const uint32 DMBIN_TRACTOR = 8;
	public const uint32 DMBIN_SMALLFMT = 9;
	public const uint32 DMBIN_LARGEFMT = 10;
	public const uint32 DMBIN_LARGECAPACITY = 11;
	public const uint32 DMBIN_CASSETTE = 14;
	public const uint32 DMBIN_FORMSOURCE = 15;
	public const uint32 DMBIN_LAST = 15;
	public const uint32 DMBIN_USER = 256;
	public const int32 DMRES_DRAFT = -1;
	public const int32 DMRES_LOW = -2;
	public const int32 DMRES_MEDIUM = -3;
	public const int32 DMRES_HIGH = -4;
	public const uint32 DMDO_DEFAULT = 0;
	public const uint32 DMDO_90 = 1;
	public const uint32 DMDO_180 = 2;
	public const uint32 DMDO_270 = 3;
	public const uint32 DMDFO_DEFAULT = 0;
	public const uint32 DMDFO_STRETCH = 1;
	public const uint32 DMDFO_CENTER = 2;
	public const uint32 DMDISPLAYFLAGS_TEXTMODE = 4;
	public const uint32 DMNUP_SYSTEM = 1;
	public const uint32 DMNUP_ONEUP = 2;
	public const uint32 DMICMMETHOD_NONE = 1;
	public const uint32 DMICMMETHOD_SYSTEM = 2;
	public const uint32 DMICMMETHOD_DRIVER = 3;
	public const uint32 DMICMMETHOD_DEVICE = 4;
	public const uint32 DMICMMETHOD_USER = 256;
	public const uint32 DMICM_SATURATE = 1;
	public const uint32 DMICM_CONTRAST = 2;
	public const uint32 DMICM_COLORIMETRIC = 3;
	public const uint32 DMICM_ABS_COLORIMETRIC = 4;
	public const uint32 DMICM_USER = 256;
	public const uint32 DMMEDIA_STANDARD = 1;
	public const uint32 DMMEDIA_TRANSPARENCY = 2;
	public const uint32 DMMEDIA_GLOSSY = 3;
	public const uint32 DMMEDIA_USER = 256;
	public const uint32 DMDITHER_NONE = 1;
	public const uint32 DMDITHER_COARSE = 2;
	public const uint32 DMDITHER_FINE = 3;
	public const uint32 DMDITHER_LINEART = 4;
	public const uint32 DMDITHER_ERRORDIFFUSION = 5;
	public const uint32 DMDITHER_RESERVED6 = 6;
	public const uint32 DMDITHER_RESERVED7 = 7;
	public const uint32 DMDITHER_RESERVED8 = 8;
	public const uint32 DMDITHER_RESERVED9 = 9;
	public const uint32 DMDITHER_GRAYSCALE = 10;
	public const uint32 DMDITHER_USER = 256;
	public const uint32 DISPLAY_DEVICE_ATTACHED_TO_DESKTOP = 1;
	public const uint32 DISPLAY_DEVICE_MULTI_DRIVER = 2;
	public const uint32 DISPLAY_DEVICE_PRIMARY_DEVICE = 4;
	public const uint32 DISPLAY_DEVICE_MIRRORING_DRIVER = 8;
	public const uint32 DISPLAY_DEVICE_VGA_COMPATIBLE = 16;
	public const uint32 DISPLAY_DEVICE_REMOVABLE = 32;
	public const uint32 DISPLAY_DEVICE_ACC_DRIVER = 64;
	public const uint32 DISPLAY_DEVICE_MODESPRUNED = 134217728;
	public const uint32 DISPLAY_DEVICE_RDPUDD = 16777216;
	public const uint32 DISPLAY_DEVICE_REMOTE = 67108864;
	public const uint32 DISPLAY_DEVICE_DISCONNECT = 33554432;
	public const uint32 DISPLAY_DEVICE_TS_COMPATIBLE = 2097152;
	public const uint32 DISPLAY_DEVICE_UNSAFE_MODES_ON = 524288;
	public const uint32 DISPLAY_DEVICE_ACTIVE = 1;
	public const uint32 DISPLAY_DEVICE_ATTACHED = 2;
	public const uint32 DISPLAYCONFIG_MAXPATH = 1024;
	public const uint32 DISPLAYCONFIG_PATH_MODE_IDX_INVALID = 4294967295;
	public const uint32 DISPLAYCONFIG_PATH_TARGET_MODE_IDX_INVALID = 65535;
	public const uint32 DISPLAYCONFIG_PATH_DESKTOP_IMAGE_IDX_INVALID = 65535;
	public const uint32 DISPLAYCONFIG_PATH_SOURCE_MODE_IDX_INVALID = 65535;
	public const uint32 DISPLAYCONFIG_PATH_CLONE_GROUP_INVALID = 65535;
	public const uint32 DISPLAYCONFIG_SOURCE_IN_USE = 1;
	public const uint32 DISPLAYCONFIG_TARGET_IN_USE = 1;
	public const uint32 DISPLAYCONFIG_TARGET_FORCIBLE = 2;
	public const uint32 DISPLAYCONFIG_TARGET_FORCED_AVAILABILITY_BOOT = 4;
	public const uint32 DISPLAYCONFIG_TARGET_FORCED_AVAILABILITY_PATH = 8;
	public const uint32 DISPLAYCONFIG_TARGET_FORCED_AVAILABILITY_SYSTEM = 16;
	public const uint32 DISPLAYCONFIG_TARGET_IS_HMD = 32;
	public const uint32 DISPLAYCONFIG_PATH_ACTIVE = 1;
	public const uint32 DISPLAYCONFIG_PATH_PREFERRED_UNSCALED = 4;
	public const uint32 DISPLAYCONFIG_PATH_SUPPORT_VIRTUAL_MODE = 8;
	public const uint32 DISPLAYCONFIG_PATH_VALID_FLAGS = 29;
	public const uint32 QDC_ALL_PATHS = 1;
	public const uint32 QDC_ONLY_ACTIVE_PATHS = 2;
	public const uint32 QDC_DATABASE_CURRENT = 4;
	public const uint32 QDC_VIRTUAL_MODE_AWARE = 16;
	public const uint32 QDC_INCLUDE_HMD = 32;
	public const uint32 QDC_VIRTUAL_REFRESH_RATE_AWARE = 64;
	public const uint32 SDC_TOPOLOGY_INTERNAL = 1;
	public const uint32 SDC_TOPOLOGY_CLONE = 2;
	public const uint32 SDC_TOPOLOGY_EXTEND = 4;
	public const uint32 SDC_TOPOLOGY_EXTERNAL = 8;
	public const uint32 SDC_TOPOLOGY_SUPPLIED = 16;
	public const uint32 SDC_USE_SUPPLIED_DISPLAY_CONFIG = 32;
	public const uint32 SDC_VALIDATE = 64;
	public const uint32 SDC_APPLY = 128;
	public const uint32 SDC_NO_OPTIMIZATION = 256;
	public const uint32 SDC_SAVE_TO_DATABASE = 512;
	public const uint32 SDC_ALLOW_CHANGES = 1024;
	public const uint32 SDC_PATH_PERSIST_IF_REQUIRED = 2048;
	public const uint32 SDC_FORCE_MODE_ENUMERATION = 4096;
	public const uint32 SDC_ALLOW_PATH_ORDER_CHANGES = 8192;
	public const uint32 SDC_VIRTUAL_MODE_AWARE = 32768;
	public const uint32 SDC_VIRTUAL_REFRESH_RATE_AWARE = 131072;
	public const uint32 RDH_RECTANGLES = 1;
	public const uint32 SYSRGN = 4;
	public const uint32 TT_POLYGON_TYPE = 24;
	public const uint32 TT_PRIM_LINE = 1;
	public const uint32 TT_PRIM_QSPLINE = 2;
	public const uint32 TT_PRIM_CSPLINE = 3;
	public const uint32 GCP_DBCS = 1;
	public const uint32 GCP_ERROR = 32768;
	public const uint32 FLI_MASK = 4155;
	public const int32 FLI_GLYPHS = 262144;
	public const int32 GCP_JUSTIFYIN = 2097152;
	public const uint32 GCPCLASS_LATIN = 1;
	public const uint32 GCPCLASS_HEBREW = 2;
	public const uint32 GCPCLASS_ARABIC = 2;
	public const uint32 GCPCLASS_NEUTRAL = 3;
	public const uint32 GCPCLASS_LOCALNUMBER = 4;
	public const uint32 GCPCLASS_LATINNUMBER = 5;
	public const uint32 GCPCLASS_LATINNUMERICTERMINATOR = 6;
	public const uint32 GCPCLASS_LATINNUMERICSEPARATOR = 7;
	public const uint32 GCPCLASS_NUMERICSEPARATOR = 8;
	public const uint32 GCPCLASS_PREBOUNDLTR = 128;
	public const uint32 GCPCLASS_PREBOUNDRTL = 64;
	public const uint32 GCPCLASS_POSTBOUNDLTR = 32;
	public const uint32 GCPCLASS_POSTBOUNDRTL = 16;
	public const uint32 GCPGLYPH_LINKBEFORE = 32768;
	public const uint32 GCPGLYPH_LINKAFTER = 16384;
	public const uint32 TT_AVAILABLE = 1;
	public const uint32 TT_ENABLED = 2;
	public const uint32 DC_BINADJUST = 19;
	public const uint32 DC_EMF_COMPLIANT = 20;
	public const uint32 DC_DATATYPE_PRODUCED = 21;
	public const uint32 DC_MANUFACTURER = 23;
	public const uint32 DC_MODEL = 24;
	public const uint32 PRINTRATEUNIT_PPM = 1;
	public const uint32 PRINTRATEUNIT_CPS = 2;
	public const uint32 PRINTRATEUNIT_LPM = 3;
	public const uint32 PRINTRATEUNIT_IPM = 4;
	public const int32 DCTT_BITMAP = 1;
	public const int32 DCTT_DOWNLOAD = 2;
	public const int32 DCTT_SUBDEV = 4;
	public const int32 DCTT_DOWNLOAD_OUTLINE = 8;
	public const uint32 DCBA_FACEUPNONE = 0;
	public const uint32 DCBA_FACEUPCENTER = 1;
	public const uint32 DCBA_FACEUPLEFT = 2;
	public const uint32 DCBA_FACEUPRIGHT = 3;
	public const uint32 DCBA_FACEDOWNNONE = 256;
	public const uint32 DCBA_FACEDOWNCENTER = 257;
	public const uint32 DCBA_FACEDOWNLEFT = 258;
	public const uint32 DCBA_FACEDOWNRIGHT = 259;
	public const uint32 GS_8BIT_INDICES = 1;
	public const uint32 GGI_MARK_NONEXISTING_GLYPHS = 1;
	public const uint32 MM_MAX_NUMAXES = 16;
	public const uint32 MM_MAX_AXES_NAMELEN = 16;
	public const uint32 GDIREGISTERDDRAWPACKETVERSION = 1;
	public const uint32 AC_SRC_OVER = 0;
	public const uint32 AC_SRC_ALPHA = 1;
	public const uint32 GRADIENT_FILL_OP_FLAG = 255;
	public const uint32 CA_NEGATIVE = 1;
	public const uint32 CA_LOG_FILTER = 2;
	public const uint32 ILLUMINANT_DEVICE_DEFAULT = 0;
	public const uint32 ILLUMINANT_A = 1;
	public const uint32 ILLUMINANT_B = 2;
	public const uint32 ILLUMINANT_C = 3;
	public const uint32 ILLUMINANT_D50 = 4;
	public const uint32 ILLUMINANT_D55 = 5;
	public const uint32 ILLUMINANT_D65 = 6;
	public const uint32 ILLUMINANT_D75 = 7;
	public const uint32 ILLUMINANT_F2 = 8;
	public const uint32 ILLUMINANT_MAX_INDEX = 8;
	public const uint32 ILLUMINANT_TUNGSTEN = 1;
	public const uint32 ILLUMINANT_DAYLIGHT = 3;
	public const uint32 ILLUMINANT_FLUORESCENT = 8;
	public const uint32 ILLUMINANT_NTSC = 3;
	public const uint32 DI_APPBANDING = 1;
	public const uint32 DI_ROPS_READ_DESTINATION = 2;
	public const uint32 FONTMAPPER_MAX = 10;
	public const uint32 ENHMETA_SIGNATURE = 1179469088;
	public const uint32 ENHMETA_STOCK_OBJECT = 2147483648;
	public const uint32 SETICMPROFILE_EMBEDED = 1;
	public const uint32 CREATECOLORSPACE_EMBEDED = 1;
	public const uint32 COLORMATCHTOTARGET_EMBEDED = 1;
	public const uint32 GDICOMMENT_IDENTIFIER = 1128875079;
	public const uint32 GDICOMMENT_WINDOWS_METAFILE = 2147483649;
	public const uint32 GDICOMMENT_BEGINGROUP = 2;
	public const uint32 GDICOMMENT_ENDGROUP = 3;
	public const uint32 GDICOMMENT_MULTIFORMATS = 1073741828;
	public const uint32 EPS_SIGNATURE = 1179865157;
	public const uint32 GDICOMMENT_UNICODE_STRING = 64;
	public const uint32 GDICOMMENT_UNICODE_END = 128;
	public const uint32 WGL_FONT_LINES = 0;
	public const uint32 WGL_FONT_POLYGONS = 1;
	public const uint32 LPD_DOUBLEBUFFER = 1;
	public const uint32 LPD_STEREO = 2;
	public const uint32 LPD_SUPPORT_GDI = 16;
	public const uint32 LPD_SUPPORT_OPENGL = 32;
	public const uint32 LPD_SHARE_DEPTH = 64;
	public const uint32 LPD_SHARE_STENCIL = 128;
	public const uint32 LPD_SHARE_ACCUM = 256;
	public const uint32 LPD_SWAP_EXCHANGE = 512;
	public const uint32 LPD_SWAP_COPY = 1024;
	public const uint32 LPD_TRANSPARENT = 4096;
	public const uint32 LPD_TYPE_RGBA = 0;
	public const uint32 LPD_TYPE_COLORINDEX = 1;
	public const uint32 WGL_SWAP_MAIN_PLANE = 1;
	public const uint32 WGL_SWAP_OVERLAY1 = 2;
	public const uint32 WGL_SWAP_OVERLAY2 = 4;
	public const uint32 WGL_SWAP_OVERLAY3 = 8;
	public const uint32 WGL_SWAP_OVERLAY4 = 16;
	public const uint32 WGL_SWAP_OVERLAY5 = 32;
	public const uint32 WGL_SWAP_OVERLAY6 = 64;
	public const uint32 WGL_SWAP_OVERLAY7 = 128;
	public const uint32 WGL_SWAP_OVERLAY8 = 256;
	public const uint32 WGL_SWAP_OVERLAY9 = 512;
	public const uint32 WGL_SWAP_OVERLAY10 = 1024;
	public const uint32 WGL_SWAP_OVERLAY11 = 2048;
	public const uint32 WGL_SWAP_OVERLAY12 = 4096;
	public const uint32 WGL_SWAP_OVERLAY13 = 8192;
	public const uint32 WGL_SWAP_OVERLAY14 = 16384;
	public const uint32 WGL_SWAP_OVERLAY15 = 32768;
	public const uint32 WGL_SWAP_UNDERLAY1 = 65536;
	public const uint32 WGL_SWAP_UNDERLAY2 = 131072;
	public const uint32 WGL_SWAP_UNDERLAY3 = 262144;
	public const uint32 WGL_SWAP_UNDERLAY4 = 524288;
	public const uint32 WGL_SWAP_UNDERLAY5 = 1048576;
	public const uint32 WGL_SWAP_UNDERLAY6 = 2097152;
	public const uint32 WGL_SWAP_UNDERLAY7 = 4194304;
	public const uint32 WGL_SWAP_UNDERLAY8 = 8388608;
	public const uint32 WGL_SWAP_UNDERLAY9 = 16777216;
	public const uint32 WGL_SWAP_UNDERLAY10 = 33554432;
	public const uint32 WGL_SWAP_UNDERLAY11 = 67108864;
	public const uint32 WGL_SWAP_UNDERLAY12 = 134217728;
	public const uint32 WGL_SWAP_UNDERLAY13 = 268435456;
	public const uint32 WGL_SWAP_UNDERLAY14 = 536870912;
	public const uint32 WGL_SWAP_UNDERLAY15 = 1073741824;
	public const uint32 WGL_SWAPMULTIPLE_MAX = 16;
	public const uint32 NEWTRANSPARENT = 3;
	public const uint32 QUERYROPSUPPORT = 40;
	public const uint32 SELECTDIB = 41;
	public const uint32 SC_SCREENSAVE = 61760;
	public const uint32 TTFCFP_SUBSET = 0;
	public const uint32 TTFCFP_SUBSET1 = 1;
	public const uint32 TTFCFP_DELTA = 2;
	public const uint32 TTFCFP_APPLE_PLATFORMID = 1;
	public const uint32 TTFCFP_MS_PLATFORMID = 3;
	public const uint32 TTFCFP_DONT_CARE = 65535;
	public const uint32 TTFCFP_LANG_KEEP_ALL = 0;
	public const uint32 TTFCFP_FLAGS_SUBSET = 1;
	public const uint32 TTFCFP_FLAGS_COMPRESS = 2;
	public const uint32 TTFCFP_FLAGS_TTC = 4;
	public const uint32 TTFCFP_FLAGS_GLYPHLIST = 8;
	public const uint32 TTFMFP_SUBSET = 0;
	public const uint32 TTFMFP_SUBSET1 = 1;
	public const uint32 TTFMFP_DELTA = 2;
	public const uint32 ERR_GENERIC = 1000;
	public const uint32 ERR_READOUTOFBOUNDS = 1001;
	public const uint32 ERR_WRITEOUTOFBOUNDS = 1002;
	public const uint32 ERR_READCONTROL = 1003;
	public const uint32 ERR_WRITECONTROL = 1004;
	public const uint32 ERR_MEM = 1005;
	public const uint32 ERR_FORMAT = 1006;
	public const uint32 ERR_WOULD_GROW = 1007;
	public const uint32 ERR_VERSION = 1008;
	public const uint32 ERR_NO_GLYPHS = 1009;
	public const uint32 ERR_INVALID_MERGE_FORMATS = 1010;
	public const uint32 ERR_INVALID_MERGE_CHECKSUMS = 1011;
	public const uint32 ERR_INVALID_MERGE_NUMGLYPHS = 1012;
	public const uint32 ERR_INVALID_DELTA_FORMAT = 1013;
	public const uint32 ERR_NOT_TTC = 1014;
	public const uint32 ERR_INVALID_TTC_INDEX = 1015;
	public const uint32 ERR_MISSING_CMAP = 1030;
	public const uint32 ERR_MISSING_GLYF = 1031;
	public const uint32 ERR_MISSING_HEAD = 1032;
	public const uint32 ERR_MISSING_HHEA = 1033;
	public const uint32 ERR_MISSING_HMTX = 1034;
	public const uint32 ERR_MISSING_LOCA = 1035;
	public const uint32 ERR_MISSING_MAXP = 1036;
	public const uint32 ERR_MISSING_NAME = 1037;
	public const uint32 ERR_MISSING_POST = 1038;
	public const uint32 ERR_MISSING_OS2 = 1039;
	public const uint32 ERR_MISSING_VHEA = 1040;
	public const uint32 ERR_MISSING_VMTX = 1041;
	public const uint32 ERR_MISSING_HHEA_OR_VHEA = 1042;
	public const uint32 ERR_MISSING_HMTX_OR_VMTX = 1043;
	public const uint32 ERR_MISSING_EBDT = 1044;
	public const uint32 ERR_INVALID_CMAP = 1060;
	public const uint32 ERR_INVALID_GLYF = 1061;
	public const uint32 ERR_INVALID_HEAD = 1062;
	public const uint32 ERR_INVALID_HHEA = 1063;
	public const uint32 ERR_INVALID_HMTX = 1064;
	public const uint32 ERR_INVALID_LOCA = 1065;
	public const uint32 ERR_INVALID_MAXP = 1066;
	public const uint32 ERR_INVALID_NAME = 1067;
	public const uint32 ERR_INVALID_POST = 1068;
	public const uint32 ERR_INVALID_OS2 = 1069;
	public const uint32 ERR_INVALID_VHEA = 1070;
	public const uint32 ERR_INVALID_VMTX = 1071;
	public const uint32 ERR_INVALID_HHEA_OR_VHEA = 1072;
	public const uint32 ERR_INVALID_HMTX_OR_VMTX = 1073;
	public const uint32 ERR_INVALID_TTO = 1080;
	public const uint32 ERR_INVALID_GSUB = 1081;
	public const uint32 ERR_INVALID_GPOS = 1082;
	public const uint32 ERR_INVALID_GDEF = 1083;
	public const uint32 ERR_INVALID_JSTF = 1084;
	public const uint32 ERR_INVALID_BASE = 1085;
	public const uint32 ERR_INVALID_EBLC = 1086;
	public const uint32 ERR_INVALID_LTSH = 1087;
	public const uint32 ERR_INVALID_VDMX = 1088;
	public const uint32 ERR_INVALID_HDMX = 1089;
	public const uint32 ERR_PARAMETER0 = 1100;
	public const uint32 ERR_PARAMETER1 = 1101;
	public const uint32 ERR_PARAMETER2 = 1102;
	public const uint32 ERR_PARAMETER3 = 1103;
	public const uint32 ERR_PARAMETER4 = 1104;
	public const uint32 ERR_PARAMETER5 = 1105;
	public const uint32 ERR_PARAMETER6 = 1106;
	public const uint32 ERR_PARAMETER7 = 1107;
	public const uint32 ERR_PARAMETER8 = 1108;
	public const uint32 ERR_PARAMETER9 = 1109;
	public const uint32 ERR_PARAMETER10 = 1110;
	public const uint32 ERR_PARAMETER11 = 1111;
	public const uint32 ERR_PARAMETER12 = 1112;
	public const uint32 ERR_PARAMETER13 = 1113;
	public const uint32 ERR_PARAMETER14 = 1114;
	public const uint32 ERR_PARAMETER15 = 1115;
	public const uint32 ERR_PARAMETER16 = 1116;
	public const uint32 CHARSET_DEFAULT = 1;
	public const uint32 CHARSET_GLYPHIDX = 3;
	public const uint32 TTEMBED_FAILIFVARIATIONSIMULATED = 16;
	public const uint32 TTEMBED_WEBOBJECT = 128;
	public const uint32 TTEMBED_XORENCRYPTDATA = 268435456;
	public const uint32 TTEMBED_VARIATIONSIMULATED = 1;
	public const uint32 TTEMBED_EUDCEMBEDDED = 2;
	public const uint32 TTEMBED_SUBSETCANCEL = 4;
	public const uint32 TTLOAD_PRIVATE = 1;
	public const uint32 TTLOAD_EUDC_OVERWRITE = 2;
	public const uint32 TTLOAD_EUDC_SET = 4;
	public const uint32 TTDELETE_DONTREMOVEFONT = 1;
	public const int32 E_NONE = 0;
	public const int32 E_API_NOTIMPL = 1;
	public const int32 E_CHARCODECOUNTINVALID = 2;
	public const int32 E_CHARCODESETINVALID = 3;
	public const int32 E_DEVICETRUETYPEFONT = 4;
	public const int32 E_HDCINVALID = 6;
	public const int32 E_NOFREEMEMORY = 7;
	public const int32 E_FONTREFERENCEINVALID = 8;
	public const int32 E_NOTATRUETYPEFONT = 10;
	public const int32 E_ERRORACCESSINGFONTDATA = 12;
	public const int32 E_ERRORACCESSINGFACENAME = 13;
	public const int32 E_ERRORUNICODECONVERSION = 17;
	public const int32 E_ERRORCONVERTINGCHARS = 18;
	public const int32 E_EXCEPTION = 19;
	public const int32 E_RESERVEDPARAMNOTNULL = 20;
	public const int32 E_CHARSETINVALID = 21;
	public const int32 E_FILE_NOT_FOUND = 23;
	public const int32 E_TTC_INDEX_OUT_OF_RANGE = 24;
	public const int32 E_INPUTPARAMINVALID = 25;
	public const int32 E_ERRORCOMPRESSINGFONTDATA = 256;
	public const int32 E_FONTDATAINVALID = 258;
	public const int32 E_NAMECHANGEFAILED = 259;
	public const int32 E_FONTNOTEMBEDDABLE = 260;
	public const int32 E_PRIVSINVALID = 261;
	public const int32 E_SUBSETTINGFAILED = 262;
	public const int32 E_READFROMSTREAMFAILED = 263;
	public const int32 E_SAVETOSTREAMFAILED = 264;
	public const int32 E_NOOS2 = 265;
	public const int32 E_T2NOFREEMEMORY = 266;
	public const int32 E_ERRORREADINGFONTDATA = 267;
	public const int32 E_FLAGSINVALID = 268;
	public const int32 E_ERRORCREATINGFONTFILE = 269;
	public const int32 E_FONTALREADYEXISTS = 270;
	public const int32 E_FONTNAMEALREADYEXISTS = 271;
	public const int32 E_FONTINSTALLFAILED = 272;
	public const int32 E_ERRORDECOMPRESSINGFONTDATA = 273;
	public const int32 E_ERRORACCESSINGEXCLUDELIST = 274;
	public const int32 E_FACENAMEINVALID = 275;
	public const int32 E_STREAMINVALID = 276;
	public const int32 E_STATUSINVALID = 277;
	public const int32 E_PRIVSTATUSINVALID = 278;
	public const int32 E_PERMISSIONSINVALID = 279;
	public const int32 E_PBENABLEDINVALID = 280;
	public const int32 E_SUBSETTINGEXCEPTION = 281;
	public const int32 E_SUBSTRING_TEST_FAIL = 282;
	public const int32 E_FONTVARIATIONSIMULATED = 283;
	public const int32 E_FONTFAMILYNAMENOTINFULL = 285;
	public const int32 E_ADDFONTFAILED = 512;
	public const int32 E_COULDNTCREATETEMPFILE = 513;
	public const int32 E_FONTFILECREATEFAILED = 515;
	public const int32 E_WINDOWSAPI = 516;
	public const int32 E_FONTFILENOTFOUND = 517;
	public const int32 E_RESOURCEFILECREATEFAILED = 518;
	public const int32 E_ERROREXPANDINGFONTDATA = 519;
	public const int32 E_ERRORGETTINGDC = 520;
	public const int32 E_EXCEPTIONINDECOMPRESSION = 521;
	public const int32 E_EXCEPTIONINCOMPRESSION = 522;
}
#endregion

#region TypeDefs
typealias HDC = int;

typealias CreatedHDC = int;

typealias HBITMAP = int;

typealias HRGN = int;

typealias HPEN = int;

typealias HBRUSH = int;

typealias HFONT = int;

typealias HMETAFILE = int;

typealias HENHMETAFILE = int;

typealias HPALETTE = int;

typealias HdcMetdataFileHandle = int;

typealias HdcMetdataEnhFileHandle = int;

typealias HGDIOBJ = int;

typealias HMONITOR = int;

#endregion


#region Enums

[AllowDuplicates]
public enum R2_MODE : int32
{
	R2_BLACK = 1,
	R2_NOTMERGEPEN = 2,
	R2_MASKNOTPEN = 3,
	R2_NOTCOPYPEN = 4,
	R2_MASKPENNOT = 5,
	R2_NOT = 6,
	R2_XORPEN = 7,
	R2_NOTMASKPEN = 8,
	R2_MASKPEN = 9,
	R2_NOTXORPEN = 10,
	R2_NOP = 11,
	R2_MERGENOTPEN = 12,
	R2_COPYPEN = 13,
	R2_MERGEPENNOT = 14,
	R2_MERGEPEN = 15,
	R2_WHITE = 16,
	R2_LAST = 16,
}


[AllowDuplicates]
public enum RGN_COMBINE_MODE : int32
{
	RGN_AND = 1,
	RGN_OR = 2,
	RGN_XOR = 3,
	RGN_DIFF = 4,
	RGN_COPY = 5,
	RGN_MIN = 1,
	RGN_MAX = 5,
}


[AllowDuplicates]
public enum ETO_OPTIONS : uint32
{
	ETO_OPAQUE = 2,
	ETO_CLIPPED = 4,
	ETO_GLYPH_INDEX = 16,
	ETO_RTLREADING = 128,
	ETO_NUMERICSLOCAL = 1024,
	ETO_NUMERICSLATIN = 2048,
	ETO_IGNORELANGUAGE = 4096,
	ETO_PDY = 8192,
	ETO_REVERSE_INDEX_MAP = 65536,
}


[AllowDuplicates]
public enum OBJ_TYPE : int32
{
	OBJ_PEN = 1,
	OBJ_BRUSH = 2,
	OBJ_DC = 3,
	OBJ_METADC = 4,
	OBJ_PAL = 5,
	OBJ_FONT = 6,
	OBJ_BITMAP = 7,
	OBJ_REGION = 8,
	OBJ_METAFILE = 9,
	OBJ_MEMDC = 10,
	OBJ_EXTPEN = 11,
	OBJ_ENHMETADC = 12,
	OBJ_ENHMETAFILE = 13,
	OBJ_COLORSPACE = 14,
}


[AllowDuplicates]
public enum DIB_USAGE : uint32
{
	DIB_RGB_COLORS = 0,
	DIB_PAL_COLORS = 1,
}


[AllowDuplicates]
public enum DRAWEDGE_FLAGS : uint32
{
	BDR_RAISEDOUTER = 1,
	BDR_SUNKENOUTER = 2,
	BDR_RAISEDINNER = 4,
	BDR_SUNKENINNER = 8,
	BDR_OUTER = 3,
	BDR_INNER = 12,
	BDR_RAISED = 5,
	BDR_SUNKEN = 10,
	EDGE_RAISED = 5,
	EDGE_SUNKEN = 10,
	EDGE_ETCHED = 6,
	EDGE_BUMP = 9,
}


[AllowDuplicates]
public enum DFC_TYPE : uint32
{
	DFC_CAPTION = 1,
	DFC_MENU = 2,
	DFC_SCROLL = 3,
	DFC_BUTTON = 4,
	DFC_POPUPMENU = 5,
}


[AllowDuplicates]
public enum DFCS_STATE : uint32
{
	DFCS_CAPTIONCLOSE = 0,
	DFCS_CAPTIONMIN = 1,
	DFCS_CAPTIONMAX = 2,
	DFCS_CAPTIONRESTORE = 3,
	DFCS_CAPTIONHELP = 4,
	DFCS_MENUARROW = 0,
	DFCS_MENUCHECK = 1,
	DFCS_MENUBULLET = 2,
	DFCS_MENUARROWRIGHT = 4,
	DFCS_SCROLLUP = 0,
	DFCS_SCROLLDOWN = 1,
	DFCS_SCROLLLEFT = 2,
	DFCS_SCROLLRIGHT = 3,
	DFCS_SCROLLCOMBOBOX = 5,
	DFCS_SCROLLSIZEGRIP = 8,
	DFCS_SCROLLSIZEGRIPRIGHT = 16,
	DFCS_BUTTONCHECK = 0,
	DFCS_BUTTONRADIOIMAGE = 1,
	DFCS_BUTTONRADIOMASK = 2,
	DFCS_BUTTONRADIO = 4,
	DFCS_BUTTON3STATE = 8,
	DFCS_BUTTONPUSH = 16,
	DFCS_INACTIVE = 256,
	DFCS_PUSHED = 512,
	DFCS_CHECKED = 1024,
	DFCS_TRANSPARENT = 2048,
	DFCS_HOT = 4096,
	DFCS_ADJUSTRECT = 8192,
	DFCS_FLAT = 16384,
	DFCS_MONO = 32768,
}


[AllowDuplicates]
public enum CDS_TYPE : uint32
{
	CDS_FULLSCREEN = 4,
	CDS_GLOBAL = 8,
	CDS_NORESET = 268435456,
	CDS_RESET = 1073741824,
	CDS_SET_PRIMARY = 16,
	CDS_TEST = 2,
	CDS_UPDATEREGISTRY = 1,
	CDS_VIDEOPARAMETERS = 32,
	CDS_ENABLE_UNSAFE_MODES = 256,
	CDS_DISABLE_UNSAFE_MODES = 512,
	CDS_RESET_EX = 536870912,
}


[AllowDuplicates]
public enum DISP_CHANGE : int32
{
	DISP_CHANGE_SUCCESSFUL = 0,
	DISP_CHANGE_RESTART = 1,
	DISP_CHANGE_FAILED = -1,
	DISP_CHANGE_BADMODE = -2,
	DISP_CHANGE_NOTUPDATED = -3,
	DISP_CHANGE_BADFLAGS = -4,
	DISP_CHANGE_BADPARAM = -5,
	DISP_CHANGE_BADDUALVIEW = -6,
}


[AllowDuplicates]
public enum DRAWSTATE_FLAGS : uint32
{
	DST_COMPLEX = 0,
	DST_TEXT = 1,
	DST_PREFIXTEXT = 2,
	DST_ICON = 3,
	DST_BITMAP = 4,
	DSS_NORMAL = 0,
	DSS_UNION = 16,
	DSS_DISABLED = 32,
	DSS_MONO = 128,
	DSS_HIDEPREFIX = 512,
	DSS_PREFIXONLY = 1024,
	DSS_RIGHT = 32768,
}


[AllowDuplicates]
public enum REDRAW_WINDOW_FLAGS : uint32
{
	RDW_INVALIDATE = 1,
	RDW_INTERNALPAINT = 2,
	RDW_ERASE = 4,
	RDW_VALIDATE = 8,
	RDW_NOINTERNALPAINT = 16,
	RDW_NOERASE = 32,
	RDW_NOCHILDREN = 64,
	RDW_ALLCHILDREN = 128,
	RDW_UPDATENOW = 256,
	RDW_ERASENOW = 512,
	RDW_FRAME = 1024,
	RDW_NOFRAME = 2048,
}


[AllowDuplicates]
public enum ENUM_DISPLAY_SETTINGS_MODE : uint32
{
	ENUM_CURRENT_SETTINGS = 4294967295,
	ENUM_REGISTRY_SETTINGS = 4294967294,
}


[AllowDuplicates]
public enum TEXT_ALIGN_OPTIONS : uint32
{
	TA_NOUPDATECP = 0,
	TA_UPDATECP = 1,
	TA_LEFT = 0,
	TA_RIGHT = 2,
	TA_CENTER = 6,
	TA_TOP = 0,
	TA_BOTTOM = 8,
	TA_BASELINE = 24,
	TA_RTLREADING = 256,
	TA_MASK = 287,
	VTA_BASELINE = 24,
	VTA_LEFT = 8,
	VTA_RIGHT = 0,
	VTA_CENTER = 6,
	VTA_BOTTOM = 2,
	VTA_TOP = 0,
}


[AllowDuplicates]
public enum PEN_STYLE : uint32
{
	PS_GEOMETRIC = 65536,
	PS_COSMETIC = 0,
	PS_SOLID = 0,
	PS_DASH = 1,
	PS_DOT = 2,
	PS_DASHDOT = 3,
	PS_DASHDOTDOT = 4,
	PS_NULL = 5,
	PS_INSIDEFRAME = 6,
	PS_USERSTYLE = 7,
	PS_ALTERNATE = 8,
	PS_STYLE_MASK = 15,
	PS_ENDCAP_ROUND = 0,
	PS_ENDCAP_SQUARE = 256,
	PS_ENDCAP_FLAT = 512,
	PS_ENDCAP_MASK = 3840,
	PS_JOIN_ROUND = 0,
	PS_JOIN_BEVEL = 4096,
	PS_JOIN_MITER = 8192,
	PS_JOIN_MASK = 61440,
	PS_TYPE_MASK = 983040,
}


[AllowDuplicates]
public enum TTEMBED_FLAGS : uint32
{
	TTEMBED_EMBEDEUDC = 32,
	TTEMBED_RAW = 0,
	TTEMBED_SUBSET = 1,
	TTEMBED_TTCOMPRESSED = 4,
}


[AllowDuplicates]
public enum DRAW_TEXT_FORMAT : uint32
{
	DT_BOTTOM = 8,
	DT_CALCRECT = 1024,
	DT_CENTER = 1,
	DT_EDITCONTROL = 8192,
	DT_END_ELLIPSIS = 32768,
	DT_EXPANDTABS = 64,
	DT_EXTERNALLEADING = 512,
	DT_HIDEPREFIX = 1048576,
	DT_INTERNAL = 4096,
	DT_LEFT = 0,
	DT_MODIFYSTRING = 65536,
	DT_NOCLIP = 256,
	DT_NOFULLWIDTHCHARBREAK = 524288,
	DT_NOPREFIX = 2048,
	DT_PATH_ELLIPSIS = 16384,
	DT_PREFIXONLY = 2097152,
	DT_RIGHT = 2,
	DT_RTLREADING = 131072,
	DT_SINGLELINE = 32,
	DT_TABSTOP = 128,
	DT_TOP = 0,
	DT_VCENTER = 4,
	DT_WORDBREAK = 16,
	DT_WORD_ELLIPSIS = 262144,
}


[AllowDuplicates]
public enum EMBED_FONT_CHARSET : uint32
{
	CHARSET_UNICODE = 1,
	CHARSET_SYMBOL = 2,
}


[AllowDuplicates]
public enum GET_DCX_FLAGS : uint32
{
	DCX_WINDOW = 1,
	DCX_CACHE = 2,
	DCX_PARENTCLIP = 32,
	DCX_CLIPSIBLINGS = 16,
	DCX_CLIPCHILDREN = 8,
	DCX_NORESETATTRS = 4,
	DCX_LOCKWINDOWUPDATE = 1024,
	DCX_EXCLUDERGN = 64,
	DCX_INTERSECTRGN = 128,
	DCX_INTERSECTUPDATE = 512,
	DCX_VALIDATE = 2097152,
}


[AllowDuplicates]
public enum GET_GLYPH_OUTLINE_FORMAT : uint32
{
	GGO_BEZIER = 3,
	GGO_BITMAP = 1,
	GGO_GLYPH_INDEX = 128,
	GGO_GRAY2_BITMAP = 4,
	GGO_GRAY4_BITMAP = 5,
	GGO_GRAY8_BITMAP = 6,
	GGO_METRICS = 0,
	GGO_NATIVE = 2,
	GGO_UNHINTED = 256,
}


[AllowDuplicates]
public enum SET_BOUNDS_RECT_FLAGS : uint32
{
	DCB_ACCUMULATE = 2,
	DCB_DISABLE = 8,
	DCB_ENABLE = 4,
	DCB_RESET = 1,
}


[AllowDuplicates]
public enum GET_STOCK_OBJECT_FLAGS : uint32
{
	BLACK_BRUSH = 4,
	DKGRAY_BRUSH = 3,
	DC_BRUSH = 18,
	GRAY_BRUSH = 2,
	HOLLOW_BRUSH = 5,
	LTGRAY_BRUSH = 1,
	NULL_BRUSH = 5,
	WHITE_BRUSH = 0,
	BLACK_PEN = 7,
	DC_PEN = 19,
	NULL_PEN = 8,
	WHITE_PEN = 6,
	ANSI_FIXED_FONT = 11,
	ANSI_VAR_FONT = 12,
	DEVICE_DEFAULT_FONT = 14,
	DEFAULT_GUI_FONT = 17,
	OEM_FIXED_FONT = 10,
	SYSTEM_FONT = 13,
	SYSTEM_FIXED_FONT = 16,
	DEFAULT_PALETTE = 15,
}


[AllowDuplicates]
public enum MODIFY_WORLD_TRANSFORM_MODE : uint32
{
	MWT_IDENTITY = 1,
	MWT_LEFTMULTIPLY = 2,
	MWT_RIGHTMULTIPLY = 3,
}


[AllowDuplicates]
public enum FONT_CLIP_PRECISION : uint8
{
	CLIP_DEFAULT_PRECIS = 0,
	CLIP_CHARACTER_PRECIS = 1,
	CLIP_STROKE_PRECIS = 2,
	CLIP_MASK = 15,
	CLIP_LH_ANGLES = 16,
	CLIP_TT_ALWAYS = 32,
	CLIP_DFA_DISABLE = 64,
	CLIP_EMBEDDED = 128,
	CLIP_DFA_OVERRIDE = 64,
}


[AllowDuplicates]
public enum CREATE_POLYGON_RGN_MODE : uint32
{
	ALTERNATE = 1,
	WINDING = 2,
}


[AllowDuplicates]
public enum EMBEDDED_FONT_PRIV_STATUS : uint32
{
	EMBED_PREVIEWPRINT = 1,
	EMBED_EDITABLE = 2,
	EMBED_INSTALLABLE = 3,
	EMBED_NOEMBEDDING = 4,
}


[AllowDuplicates]
public enum MONITOR_FROM_FLAGS : uint32
{
	MONITOR_DEFAULTTONEAREST = 2,
	MONITOR_DEFAULTTONULL = 0,
	MONITOR_DEFAULTTOPRIMARY = 1,
}


[AllowDuplicates]
public enum FONT_RESOURCE_CHARACTERISTICS : uint32
{
	FR_PRIVATE = 16,
	FR_NOT_ENUM = 32,
}


[AllowDuplicates]
public enum DC_LAYOUT : uint32
{
	LAYOUT_BITMAPORIENTATIONPRESERVED = 8,
	LAYOUT_RTL = 1,
}


[AllowDuplicates]
public enum GET_DEVICE_CAPS_INDEX : uint32
{
	DRIVERVERSION = 0,
	TECHNOLOGY = 2,
	HORZSIZE = 4,
	VERTSIZE = 6,
	HORZRES = 8,
	VERTRES = 10,
	BITSPIXEL = 12,
	PLANES = 14,
	NUMBRUSHES = 16,
	NUMPENS = 18,
	NUMMARKERS = 20,
	NUMFONTS = 22,
	NUMCOLORS = 24,
	PDEVICESIZE = 26,
	CURVECAPS = 28,
	LINECAPS = 30,
	POLYGONALCAPS = 32,
	TEXTCAPS = 34,
	CLIPCAPS = 36,
	RASTERCAPS = 38,
	ASPECTX = 40,
	ASPECTY = 42,
	ASPECTXY = 44,
	LOGPIXELSX = 88,
	LOGPIXELSY = 90,
	SIZEPALETTE = 104,
	NUMRESERVED = 106,
	COLORRES = 108,
	PHYSICALWIDTH = 110,
	PHYSICALHEIGHT = 111,
	PHYSICALOFFSETX = 112,
	PHYSICALOFFSETY = 113,
	SCALINGFACTORX = 114,
	SCALINGFACTORY = 115,
	VREFRESH = 116,
	DESKTOPVERTRES = 117,
	DESKTOPHORZRES = 118,
	BLTALIGNMENT = 119,
	SHADEBLENDCAPS = 120,
	COLORMGMTCAPS = 121,
}


[AllowDuplicates]
public enum FONT_OUTPUT_PRECISION : uint8
{
	OUT_DEFAULT_PRECIS = 0,
	OUT_STRING_PRECIS = 1,
	OUT_CHARACTER_PRECIS = 2,
	OUT_STROKE_PRECIS = 3,
	OUT_TT_PRECIS = 4,
	OUT_DEVICE_PRECIS = 5,
	OUT_RASTER_PRECIS = 6,
	OUT_TT_ONLY_PRECIS = 7,
	OUT_OUTLINE_PRECIS = 8,
	OUT_SCREEN_OUTLINE_PRECIS = 9,
	OUT_PS_ONLY_PRECIS = 10,
}


[AllowDuplicates]
public enum FONT_WEIGHT : uint32
{
	FW_DONTCARE = 0,
	FW_THIN = 100,
	FW_EXTRALIGHT = 200,
	FW_LIGHT = 300,
	FW_NORMAL = 400,
	FW_MEDIUM = 500,
	FW_SEMIBOLD = 600,
	FW_BOLD = 700,
	FW_EXTRABOLD = 800,
	FW_HEAVY = 900,
	FW_ULTRALIGHT = 200,
	FW_REGULAR = 400,
	FW_DEMIBOLD = 600,
	FW_ULTRABOLD = 800,
	FW_BLACK = 900,
}


[AllowDuplicates]
public enum FONT_CHARSET : uint8
{
	ANSI_CHARSET = 0,
	DEFAULT_CHARSET = 1,
	SYMBOL_CHARSET = 2,
	SHIFTJIS_CHARSET = 128,
	HANGEUL_CHARSET = 129,
	HANGUL_CHARSET = 129,
	GB2312_CHARSET = 134,
	CHINESEBIG5_CHARSET = 136,
	OEM_CHARSET = 255,
	JOHAB_CHARSET = 130,
	HEBREW_CHARSET = 177,
	ARABIC_CHARSET = 178,
	GREEK_CHARSET = 161,
	TURKISH_CHARSET = 162,
	VIETNAMESE_CHARSET = 163,
	THAI_CHARSET = 222,
	EASTEUROPE_CHARSET = 238,
	RUSSIAN_CHARSET = 204,
	MAC_CHARSET = 77,
	BALTIC_CHARSET = 186,
}


[AllowDuplicates]
public enum ARC_DIRECTION : uint32
{
	AD_COUNTERCLOCKWISE = 1,
	AD_CLOCKWISE = 2,
}


[AllowDuplicates]
public enum TTLOAD_EMBEDDED_FONT_STATUS : uint32
{
	TTLOAD_FONT_SUBSETTED = 1,
	TTLOAD_FONT_IN_SYSSTARTUP = 2,
}


[AllowDuplicates]
public enum STRETCH_BLT_MODE : uint32
{
	BLACKONWHITE = 1,
	COLORONCOLOR = 3,
	HALFTONE = 4,
	STRETCH_ANDSCANS = 1,
	STRETCH_DELETESCANS = 3,
	STRETCH_HALFTONE = 4,
	STRETCH_ORSCANS = 2,
	WHITEONBLACK = 2,
}


[AllowDuplicates]
public enum FONT_QUALITY : uint8
{
	DEFAULT_QUALITY = 0,
	DRAFT_QUALITY = 1,
	PROOF_QUALITY = 2,
	NONANTIALIASED_QUALITY = 3,
	ANTIALIASED_QUALITY = 4,
	CLEARTYPE_QUALITY = 5,
}


[AllowDuplicates]
public enum BACKGROUND_MODE : uint32
{
	OPAQUE = 2,
	TRANSPARENT = 1,
}


[AllowDuplicates]
public enum GET_CHARACTER_PLACEMENT_FLAGS : uint32
{
	GCP_CLASSIN = 524288,
	GCP_DIACRITIC = 256,
	GCP_DISPLAYZWG = 4194304,
	GCP_GLYPHSHAPE = 16,
	GCP_JUSTIFY = 65536,
	GCP_KASHIDA = 1024,
	GCP_LIGATE = 32,
	GCP_MAXEXTENT = 1048576,
	GCP_NEUTRALOVERRIDE = 33554432,
	GCP_NUMERICOVERRIDE = 16777216,
	GCP_NUMERICSLATIN = 67108864,
	GCP_NUMERICSLOCAL = 134217728,
	GCP_REORDER = 2,
	GCP_SYMSWAPOFF = 8388608,
	GCP_USEKERNING = 8,
}


[AllowDuplicates]
public enum DRAW_EDGE_FLAGS : uint32
{
	BF_ADJUST = 8192,
	BF_BOTTOM = 8,
	BF_BOTTOMLEFT = 9,
	BF_BOTTOMRIGHT = 12,
	BF_DIAGONAL = 16,
	BF_DIAGONAL_ENDBOTTOMLEFT = 25,
	BF_DIAGONAL_ENDBOTTOMRIGHT = 28,
	BF_DIAGONAL_ENDTOPLEFT = 19,
	BF_DIAGONAL_ENDTOPRIGHT = 22,
	BF_FLAT = 16384,
	BF_LEFT = 1,
	BF_MIDDLE = 2048,
	BF_MONO = 32768,
	BF_RECT = 15,
	BF_RIGHT = 4,
	BF_SOFT = 4096,
	BF_TOP = 2,
	BF_TOPLEFT = 3,
	BF_TOPRIGHT = 6,
}


[AllowDuplicates]
public enum SYS_COLOR_INDEX : int32
{
	COLOR_SCROLLBAR = 0,
	COLOR_BACKGROUND = 1,
	COLOR_ACTIVECAPTION = 2,
	COLOR_INACTIVECAPTION = 3,
	COLOR_MENU = 4,
	COLOR_WINDOW = 5,
	COLOR_WINDOWFRAME = 6,
	COLOR_MENUTEXT = 7,
	COLOR_WINDOWTEXT = 8,
	COLOR_CAPTIONTEXT = 9,
	COLOR_ACTIVEBORDER = 10,
	COLOR_INACTIVEBORDER = 11,
	COLOR_APPWORKSPACE = 12,
	COLOR_HIGHLIGHT = 13,
	COLOR_HIGHLIGHTTEXT = 14,
	COLOR_BTNFACE = 15,
	COLOR_BTNSHADOW = 16,
	COLOR_GRAYTEXT = 17,
	COLOR_BTNTEXT = 18,
	COLOR_INACTIVECAPTIONTEXT = 19,
	COLOR_BTNHIGHLIGHT = 20,
	COLOR_3DDKSHADOW = 21,
	COLOR_3DLIGHT = 22,
	COLOR_INFOTEXT = 23,
	COLOR_INFOBK = 24,
	COLOR_HOTLIGHT = 26,
	COLOR_GRADIENTACTIVECAPTION = 27,
	COLOR_GRADIENTINACTIVECAPTION = 28,
	COLOR_MENUHILIGHT = 29,
	COLOR_MENUBAR = 30,
	COLOR_DESKTOP = 1,
	COLOR_3DFACE = 15,
	COLOR_3DSHADOW = 16,
	COLOR_3DHIGHLIGHT = 20,
	COLOR_3DHILIGHT = 20,
	COLOR_BTNHILIGHT = 20,
}


[AllowDuplicates]
public enum FONT_LICENSE_PRIVS : uint32
{
	LICENSE_PREVIEWPRINT = 4,
	LICENSE_EDITABLE = 8,
	LICENSE_INSTALLABLE = 0,
	LICENSE_NOEMBEDDING = 2,
	LICENSE_DEFAULT = 0,
}


[AllowDuplicates]
public enum GRADIENT_FILL : uint32
{
	GRADIENT_FILL_RECT_H = 0,
	GRADIENT_FILL_RECT_V = 1,
	GRADIENT_FILL_TRIANGLE = 2,
}


[AllowDuplicates]
public enum CREATE_FONT_PACKAGE_SUBSET_ENCODING : uint16
{
	TTFCFP_STD_MAC_CHAR_SET = 0,
	TTFCFP_SYMBOL_CHAR_SET = 0,
	TTFCFP_UNICODE_CHAR_SET = 1,
}


[AllowDuplicates]
public enum EXT_FLOOD_FILL_TYPE : uint32
{
	FLOODFILLBORDER = 0,
	FLOODFILLSURFACE = 1,
}


[AllowDuplicates]
public enum HATCH_BRUSH_STYLE : uint32
{
	HS_BDIAGONAL = 3,
	HS_CROSS = 4,
	HS_DIAGCROSS = 5,
	HS_FDIAGONAL = 2,
	HS_HORIZONTAL = 0,
	HS_VERTICAL = 1,
}


[AllowDuplicates]
public enum DRAW_CAPTION_FLAGS : uint32
{
	DC_ACTIVE = 1,
	DC_BUTTONS = 4096,
	DC_GRADIENT = 32,
	DC_ICON = 4,
	DC_INBUTTON = 16,
	DC_SMALLCAP = 2,
	DC_TEXT = 8,
}


[AllowDuplicates]
public enum SYSTEM_PALETTE_USE : uint32
{
	SYSPAL_NOSTATIC = 2,
	SYSPAL_NOSTATIC256 = 3,
	SYSPAL_STATIC = 1,
}


[AllowDuplicates]
public enum GRAPHICS_MODE : uint32
{
	GM_COMPATIBLE = 1,
	GM_ADVANCED = 2,
}


[AllowDuplicates]
public enum FONT_PITCH : uint8
{
	DEFAULT_PITCH = 0,
	FIXED_PITCH = 1,
	VARIABLE_PITCH = 2,
}


[AllowDuplicates]
public enum FONT_FAMILY : uint8
{
	FF_DECORATIVE = 80,
	FF_DONTCARE = 0,
	FF_MODERN = 48,
	FF_ROMAN = 16,
	FF_SCRIPT = 64,
	FF_SWISS = 32,
}


[AllowDuplicates]
public enum ROP_CODE : uint32
{
	BLACKNESS = 66,
	NOTSRCERASE = 1114278,
	NOTSRCCOPY = 3342344,
	SRCERASE = 4457256,
	DSTINVERT = 5570569,
	PATINVERT = 5898313,
	SRCINVERT = 6684742,
	SRCAND = 8913094,
	MERGEPAINT = 12255782,
	MERGECOPY = 12583114,
	SRCCOPY = 13369376,
	SRCPAINT = 15597702,
	PATCOPY = 15728673,
	PATPAINT = 16452105,
	WHITENESS = 16711778,
	CAPTUREBLT = 1073741824,
	NOMIRRORBITMAP = 2147483648,
}


[AllowDuplicates]
public enum CREATE_FONT_PACKAGE_SUBSET_PLATFORM : uint16
{
	TTFCFP_UNICODE_PLATFORMID = 0,
	TTFCFP_ISO_PLATFORMID = 2,
}


[AllowDuplicates]
public enum HDC_MAP_MODE : uint32
{
	MM_ANISOTROPIC = 8,
	MM_HIENGLISH = 5,
	MM_HIMETRIC = 3,
	MM_ISOTROPIC = 7,
	MM_LOENGLISH = 4,
	MM_LOMETRIC = 2,
	MM_TEXT = 1,
	MM_TWIPS = 6,
}


[AllowDuplicates]
public enum GDI_REGION_TYPE : int32
{
	RGN_ERROR = 0,
	NULLREGION = 1,
	SIMPLEREGION = 2,
	COMPLEXREGION = 3,
}


[AllowDuplicates]
public enum BRUSH_STYLE : uint32
{
	BS_SOLID = 0,
	BS_NULL = 1,
	BS_HOLLOW = 1,
	BS_HATCHED = 2,
	BS_PATTERN = 3,
	BS_INDEXED = 4,
	BS_DIBPATTERN = 5,
	BS_DIBPATTERNPT = 6,
	BS_PATTERN8X8 = 7,
	BS_DIBPATTERN8X8 = 8,
	BS_MONOPATTERN = 9,
}


[AllowDuplicates]
public enum TMPF_FLAGS : uint8
{
	TMPF_FIXED_PITCH = 1,
	TMPF_VECTOR = 2,
	TMPF_DEVICE = 8,
	TMPF_TRUETYPE = 4,
}


[AllowDuplicates]
public enum BI_COMPRESSION : int32
{
	BI_RGB = 0,
	BI_RLE8 = 1,
	BI_RLE4 = 2,
	BI_BITFIELDS = 3,
	BI_JPEG = 4,
	BI_PNG = 5,
}


[AllowDuplicates]
public enum ENHANCED_METAFILE_RECORD_TYPE : uint32
{
	EMR_HEADER = 1,
	EMR_POLYBEZIER = 2,
	EMR_POLYGON = 3,
	EMR_POLYLINE = 4,
	EMR_POLYBEZIERTO = 5,
	EMR_POLYLINETO = 6,
	EMR_POLYPOLYLINE = 7,
	EMR_POLYPOLYGON = 8,
	EMR_SETWINDOWEXTEX = 9,
	EMR_SETWINDOWORGEX = 10,
	EMR_SETVIEWPORTEXTEX = 11,
	EMR_SETVIEWPORTORGEX = 12,
	EMR_SETBRUSHORGEX = 13,
	EMR_EOF = 14,
	EMR_SETPIXELV = 15,
	EMR_SETMAPPERFLAGS = 16,
	EMR_SETMAPMODE = 17,
	EMR_SETBKMODE = 18,
	EMR_SETPOLYFILLMODE = 19,
	EMR_SETROP2 = 20,
	EMR_SETSTRETCHBLTMODE = 21,
	EMR_SETTEXTALIGN = 22,
	EMR_SETCOLORADJUSTMENT = 23,
	EMR_SETTEXTCOLOR = 24,
	EMR_SETBKCOLOR = 25,
	EMR_OFFSETCLIPRGN = 26,
	EMR_MOVETOEX = 27,
	EMR_SETMETARGN = 28,
	EMR_EXCLUDECLIPRECT = 29,
	EMR_INTERSECTCLIPRECT = 30,
	EMR_SCALEVIEWPORTEXTEX = 31,
	EMR_SCALEWINDOWEXTEX = 32,
	EMR_SAVEDC = 33,
	EMR_RESTOREDC = 34,
	EMR_SETWORLDTRANSFORM = 35,
	EMR_MODIFYWORLDTRANSFORM = 36,
	EMR_SELECTOBJECT = 37,
	EMR_CREATEPEN = 38,
	EMR_CREATEBRUSHINDIRECT = 39,
	EMR_DELETEOBJECT = 40,
	EMR_ANGLEARC = 41,
	EMR_ELLIPSE = 42,
	EMR_RECTANGLE = 43,
	EMR_ROUNDRECT = 44,
	EMR_ARC = 45,
	EMR_CHORD = 46,
	EMR_PIE = 47,
	EMR_SELECTPALETTE = 48,
	EMR_CREATEPALETTE = 49,
	EMR_SETPALETTEENTRIES = 50,
	EMR_RESIZEPALETTE = 51,
	EMR_REALIZEPALETTE = 52,
	EMR_EXTFLOODFILL = 53,
	EMR_LINETO = 54,
	EMR_ARCTO = 55,
	EMR_POLYDRAW = 56,
	EMR_SETARCDIRECTION = 57,
	EMR_SETMITERLIMIT = 58,
	EMR_BEGINPATH = 59,
	EMR_ENDPATH = 60,
	EMR_CLOSEFIGURE = 61,
	EMR_FILLPATH = 62,
	EMR_STROKEANDFILLPATH = 63,
	EMR_STROKEPATH = 64,
	EMR_FLATTENPATH = 65,
	EMR_WIDENPATH = 66,
	EMR_SELECTCLIPPATH = 67,
	EMR_ABORTPATH = 68,
	EMR_GDICOMMENT = 70,
	EMR_FILLRGN = 71,
	EMR_FRAMERGN = 72,
	EMR_INVERTRGN = 73,
	EMR_PAINTRGN = 74,
	EMR_EXTSELECTCLIPRGN = 75,
	EMR_BITBLT = 76,
	EMR_STRETCHBLT = 77,
	EMR_MASKBLT = 78,
	EMR_PLGBLT = 79,
	EMR_SETDIBITSTODEVICE = 80,
	EMR_STRETCHDIBITS = 81,
	EMR_EXTCREATEFONTINDIRECTW = 82,
	EMR_EXTTEXTOUTA = 83,
	EMR_EXTTEXTOUTW = 84,
	EMR_POLYBEZIER16 = 85,
	EMR_POLYGON16 = 86,
	EMR_POLYLINE16 = 87,
	EMR_POLYBEZIERTO16 = 88,
	EMR_POLYLINETO16 = 89,
	EMR_POLYPOLYLINE16 = 90,
	EMR_POLYPOLYGON16 = 91,
	EMR_POLYDRAW16 = 92,
	EMR_CREATEMONOBRUSH = 93,
	EMR_CREATEDIBPATTERNBRUSHPT = 94,
	EMR_EXTCREATEPEN = 95,
	EMR_POLYTEXTOUTA = 96,
	EMR_POLYTEXTOUTW = 97,
	EMR_SETICMMODE = 98,
	EMR_CREATECOLORSPACE = 99,
	EMR_SETCOLORSPACE = 100,
	EMR_DELETECOLORSPACE = 101,
	EMR_GLSRECORD = 102,
	EMR_GLSBOUNDEDRECORD = 103,
	EMR_PIXELFORMAT = 104,
	EMR_RESERVED_105 = 105,
	EMR_RESERVED_106 = 106,
	EMR_RESERVED_107 = 107,
	EMR_RESERVED_108 = 108,
	EMR_RESERVED_109 = 109,
	EMR_RESERVED_110 = 110,
	EMR_COLORCORRECTPALETTE = 111,
	EMR_SETICMPROFILEA = 112,
	EMR_SETICMPROFILEW = 113,
	EMR_ALPHABLEND = 114,
	EMR_SETLAYOUT = 115,
	EMR_TRANSPARENTBLT = 116,
	EMR_RESERVED_117 = 117,
	EMR_GRADIENTFILL = 118,
	EMR_RESERVED_119 = 119,
	EMR_RESERVED_120 = 120,
	EMR_COLORMATCHTOTARGETW = 121,
	EMR_CREATECOLORSPACEW = 122,
	EMR_MIN = 1,
	EMR_MAX = 122,
}


[AllowDuplicates]
public enum DEVMODE_FIELD_FLAGS : uint32
{
	DM_SPECVERSION = 1025,
	DM_ORIENTATION = 1,
	DM_PAPERSIZE = 2,
	DM_PAPERLENGTH = 4,
	DM_PAPERWIDTH = 8,
	DM_SCALE = 16,
	DM_POSITION = 32,
	DM_NUP = 64,
	DM_DISPLAYORIENTATION = 128,
	DM_COPIES = 256,
	DM_DEFAULTSOURCE = 512,
	DM_PRINTQUALITY = 1024,
	DM_COLOR = 2048,
	DM_DUPLEX = 4096,
	DM_YRESOLUTION = 8192,
	DM_TTOPTION = 16384,
	DM_COLLATE = 32768,
	DM_FORMNAME = 65536,
	DM_LOGPIXELS = 131072,
	DM_BITSPERPEL = 262144,
	DM_PELSWIDTH = 524288,
	DM_PELSHEIGHT = 1048576,
	DM_DISPLAYFLAGS = 2097152,
	DM_DISPLAYFREQUENCY = 4194304,
	DM_ICMMETHOD = 8388608,
	DM_ICMINTENT = 16777216,
	DM_MEDIATYPE = 33554432,
	DM_DITHERTYPE = 67108864,
	DM_PANNINGWIDTH = 134217728,
	DM_PANNINGHEIGHT = 268435456,
	DM_DISPLAYFIXEDOUTPUT = 536870912,
	DM_INTERLACED = 2,
	DM_UPDATE = 1,
	DM_COPY = 2,
	DM_PROMPT = 4,
	DM_MODIFY = 8,
	DM_IN_BUFFER = 8,
	DM_IN_PROMPT = 4,
	DM_OUT_BUFFER = 2,
	DM_OUT_DEFAULT = 1,
}


[AllowDuplicates]
public enum DEVMODE_COLOR : uint32
{
	DMCOLOR_MONOCHROME = 1,
	DMCOLOR_COLOR = 2,
}


[AllowDuplicates]
public enum DEVMODE_DUPLEX : uint32
{
	DMDUP_SIMPLEX = 1,
	DMDUP_VERTICAL = 2,
	DMDUP_HORIZONTAL = 3,
}


[AllowDuplicates]
public enum DEVMODE_COLLATE : uint32
{
	DMCOLLATE_FALSE = 0,
	DMCOLLATE_TRUE = 1,
}


[AllowDuplicates]
public enum DEVMODE_TRUETYPE_OPTION : uint32
{
	DMTT_BITMAP = 1,
	DMTT_DOWNLOAD = 2,
	DMTT_SUBDEV = 3,
	DMTT_DOWNLOAD_OUTLINE = 4,
}


[AllowDuplicates]
public enum PAN_FAMILY_TYPE : uint32
{
	PAN_FAMILY_ANY = 0,
	PAN_FAMILY_NO_FIT = 1,
	PAN_FAMILY_TEXT_DISPLAY = 2,
	PAN_FAMILY_SCRIPT = 3,
	PAN_FAMILY_DECORATIVE = 4,
	PAN_FAMILY_PICTORIAL = 5,
}


[AllowDuplicates]
public enum PAN_SERIF_STYLE : uint32
{
	PAN_SERIF_ANY = 0,
	PAN_SERIF_NO_FIT = 1,
	PAN_SERIF_COVE = 2,
	PAN_SERIF_OBTUSE_COVE = 3,
	PAN_SERIF_SQUARE_COVE = 4,
	PAN_SERIF_OBTUSE_SQUARE_COVE = 5,
	PAN_SERIF_SQUARE = 6,
	PAN_SERIF_THIN = 7,
	PAN_SERIF_BONE = 8,
	PAN_SERIF_EXAGGERATED = 9,
	PAN_SERIF_TRIANGLE = 10,
	PAN_SERIF_NORMAL_SANS = 11,
	PAN_SERIF_OBTUSE_SANS = 12,
	PAN_SERIF_PERP_SANS = 13,
	PAN_SERIF_FLARED = 14,
	PAN_SERIF_ROUNDED = 15,
}


[AllowDuplicates]
public enum PAN_WEIGHT : uint32
{
	PAN_WEIGHT_ANY = 0,
	PAN_WEIGHT_NO_FIT = 1,
	PAN_WEIGHT_INDEX = 2,
	PAN_WEIGHT_VERY_LIGHT = 2,
	PAN_WEIGHT_LIGHT = 3,
	PAN_WEIGHT_THIN = 4,
	PAN_WEIGHT_BOOK = 5,
	PAN_WEIGHT_MEDIUM = 6,
	PAN_WEIGHT_DEMI = 7,
	PAN_WEIGHT_BOLD = 8,
	PAN_WEIGHT_HEAVY = 9,
	PAN_WEIGHT_BLACK = 10,
	PAN_WEIGHT_NORD = 11,
}


[AllowDuplicates]
public enum PAN_STROKE_VARIATION : uint32
{
	PAN_STROKE_ANY = 0,
	PAN_STROKE_NO_FIT = 1,
	PAN_STROKE_GRADUAL_DIAG = 2,
	PAN_STROKE_GRADUAL_TRAN = 3,
	PAN_STROKE_GRADUAL_VERT = 4,
	PAN_STROKE_GRADUAL_HORZ = 5,
	PAN_STROKE_RAPID_VERT = 6,
	PAN_STROKE_RAPID_HORZ = 7,
	PAN_STROKE_INSTANT_VERT = 8,
}


[AllowDuplicates]
public enum PAN_PROPORTION : uint32
{
	PAN_PROP_ANY = 0,
	PAN_PROP_NO_FIT = 1,
	PAN_PROP_OLD_STYLE = 2,
	PAN_PROP_MODERN = 3,
	PAN_PROP_EVEN_WIDTH = 4,
	PAN_PROP_EXPANDED = 5,
	PAN_PROP_CONDENSED = 6,
	PAN_PROP_VERY_EXPANDED = 7,
	PAN_PROP_VERY_CONDENSED = 8,
	PAN_PROP_MONOSPACED = 9,
}


[AllowDuplicates]
public enum PAN_CONTRAST : uint32
{
	PAN_CONTRAST_ANY = 0,
	PAN_CONTRAST_NO_FIT = 1,
	PAN_CONTRAST_INDEX = 4,
	PAN_CONTRAST_NONE = 2,
	PAN_CONTRAST_VERY_LOW = 3,
	PAN_CONTRAST_LOW = 4,
	PAN_CONTRAST_MEDIUM_LOW = 5,
	PAN_CONTRAST_MEDIUM = 6,
	PAN_CONTRAST_MEDIUM_HIGH = 7,
	PAN_CONTRAST_HIGH = 8,
	PAN_CONTRAST_VERY_HIGH = 9,
}


[AllowDuplicates]
public enum PAN_ARM_STYLE : uint32
{
	PAN_ARM_ANY = 0,
	PAN_ARM_NO_FIT = 1,
	PAN_STRAIGHT_ARMS_HORZ = 2,
	PAN_STRAIGHT_ARMS_WEDGE = 3,
	PAN_STRAIGHT_ARMS_VERT = 4,
	PAN_STRAIGHT_ARMS_SINGLE_SERIF = 5,
	PAN_STRAIGHT_ARMS_DOUBLE_SERIF = 6,
	PAN_BENT_ARMS_HORZ = 7,
	PAN_BENT_ARMS_WEDGE = 8,
	PAN_BENT_ARMS_VERT = 9,
	PAN_BENT_ARMS_SINGLE_SERIF = 10,
	PAN_BENT_ARMS_DOUBLE_SERIF = 11,
}


[AllowDuplicates]
public enum PAN_LETT_FORM : uint32
{
	PAN_LETT_FORM_ANY = 0,
	PAN_LETT_FORM_NO_FIT = 1,
	PAN_LETT_NORMAL_CONTACT = 2,
	PAN_LETT_NORMAL_WEIGHTED = 3,
	PAN_LETT_NORMAL_BOXED = 4,
	PAN_LETT_NORMAL_FLATTENED = 5,
	PAN_LETT_NORMAL_ROUNDED = 6,
	PAN_LETT_NORMAL_OFF_CENTER = 7,
	PAN_LETT_NORMAL_SQUARE = 8,
	PAN_LETT_OBLIQUE_CONTACT = 9,
	PAN_LETT_OBLIQUE_WEIGHTED = 10,
	PAN_LETT_OBLIQUE_BOXED = 11,
	PAN_LETT_OBLIQUE_FLATTENED = 12,
	PAN_LETT_OBLIQUE_ROUNDED = 13,
	PAN_LETT_OBLIQUE_OFF_CENTER = 14,
	PAN_LETT_OBLIQUE_SQUARE = 15,
}


[AllowDuplicates]
public enum PAN_MIDLINE : uint32
{
	PAN_MIDLINE_ANY = 0,
	PAN_MIDLINE_NO_FIT = 1,
	PAN_MIDLINE_INDEX = 8,
	PAN_MIDLINE_STANDARD_TRIMMED = 2,
	PAN_MIDLINE_STANDARD_POINTED = 3,
	PAN_MIDLINE_STANDARD_SERIFED = 4,
	PAN_MIDLINE_HIGH_TRIMMED = 5,
	PAN_MIDLINE_HIGH_POINTED = 6,
	PAN_MIDLINE_HIGH_SERIFED = 7,
	PAN_MIDLINE_CONSTANT_TRIMMED = 8,
	PAN_MIDLINE_CONSTANT_POINTED = 9,
	PAN_MIDLINE_CONSTANT_SERIFED = 10,
	PAN_MIDLINE_LOW_TRIMMED = 11,
	PAN_MIDLINE_LOW_POINTED = 12,
	PAN_MIDLINE_LOW_SERIFED = 13,
}


[AllowDuplicates]
public enum PAN_XHEIGHT : uint32
{
	PAN_XHEIGHT_ANY = 0,
	PAN_XHEIGHT_NO_FIT = 1,
	PAN_XHEIGHT_INDEX = 9,
	PAN_XHEIGHT_CONSTANT_SMALL = 2,
	PAN_XHEIGHT_CONSTANT_STD = 3,
	PAN_XHEIGHT_CONSTANT_LARGE = 4,
	PAN_XHEIGHT_DUCKING_SMALL = 5,
	PAN_XHEIGHT_DUCKING_STD = 6,
	PAN_XHEIGHT_DUCKING_LARGE = 7,
}


[AllowDuplicates]
public enum DISPLAYCONFIG_COLOR_ENCODING : int32
{
	DISPLAYCONFIG_COLOR_ENCODING_RGB = 0,
	DISPLAYCONFIG_COLOR_ENCODING_YCBCR444 = 1,
	DISPLAYCONFIG_COLOR_ENCODING_YCBCR422 = 2,
	DISPLAYCONFIG_COLOR_ENCODING_YCBCR420 = 3,
	DISPLAYCONFIG_COLOR_ENCODING_INTENSITY = 4,
	DISPLAYCONFIG_COLOR_ENCODING_FORCE_UINT32 = -1,
}

#endregion

#region Function Pointers
public function int32 FONTENUMPROCA(LOGFONTA* param0, TEXTMETRICA* param1, uint32 param2, LPARAM param3);

public function int32 FONTENUMPROCW(LOGFONTW* param0, TEXTMETRICW* param1, uint32 param2, LPARAM param3);

public function int32 GOBJENUMPROC(void* param0, LPARAM param1);

public function void LINEDDAPROC(int32 param0, int32 param1, LPARAM param2);

public function uint32 LPFNDEVMODE(HWND param0, HINSTANCE param1, DEVMODEA* param2, PSTR param3, PSTR param4, DEVMODEA* param5, PSTR param6, uint32 param7);

public function uint32 LPFNDEVCAPS(PSTR param0, PSTR param1, uint32 param2, PSTR param3, DEVMODEA* param4);

public function int32 MFENUMPROC(HDC hdc, HANDLETABLE* lpht, METARECORD* lpMR, int32 nObj, LPARAM param4);

public function int32 ENHMFENUMPROC(HDC hdc, HANDLETABLE* lpht, ENHMETARECORD* lpmr, int32 nHandles, LPARAM data);

public function void* CFP_ALLOCPROC(uint param0);

public function void* CFP_REALLOCPROC(void* param0, uint param1);

public function void CFP_FREEPROC(void* param0);

public function uint32 READEMBEDPROC(void* param0, void* param1, uint32 param2);

public function uint32 WRITEEMBEDPROC(void* param0, void* param1, uint32 param2);

public function BOOL GRAYSTRINGPROC(HDC param0, LPARAM param1, int32 param2);

public function BOOL DRAWSTATEPROC(HDC hdc, LPARAM lData, WPARAM wData, int32 cx, int32 cy);

public function BOOL MONITORENUMPROC(HMONITOR param0, HDC param1, RECT* param2, LPARAM param3);

#endregion

#region Structs
[CRepr]
public struct MONITORINFOEXA
{
	public MONITORINFO monitorInfo;
	public CHAR[32] szDevice;
}

[CRepr]
public struct MONITORINFOEXW
{
	public MONITORINFO monitorInfo;
	public char16[32] szDevice;
}

[CRepr]
public struct XFORM
{
	public float eM11;
	public float eM12;
	public float eM21;
	public float eM22;
	public float eDx;
	public float eDy;
}

[CRepr]
public struct BITMAP
{
	public int32 bmType;
	public int32 bmWidth;
	public int32 bmHeight;
	public int32 bmWidthBytes;
	public uint16 bmPlanes;
	public uint16 bmBitsPixel;
	public void* bmBits;
}

[CRepr]
public struct RGBTRIPLE
{
	public uint8 rgbtBlue;
	public uint8 rgbtGreen;
	public uint8 rgbtRed;
}

[CRepr]
public struct RGBQUAD
{
	public uint8 rgbBlue;
	public uint8 rgbGreen;
	public uint8 rgbRed;
	public uint8 rgbReserved;
}

[CRepr]
public struct CIEXYZ
{
	public int32 ciexyzX;
	public int32 ciexyzY;
	public int32 ciexyzZ;
}

[CRepr]
public struct CIEXYZTRIPLE
{
	public CIEXYZ ciexyzRed;
	public CIEXYZ ciexyzGreen;
	public CIEXYZ ciexyzBlue;
}

[CRepr]
public struct BITMAPCOREHEADER
{
	public uint32 bcSize;
	public uint16 bcWidth;
	public uint16 bcHeight;
	public uint16 bcPlanes;
	public uint16 bcBitCount;
}

[CRepr]
public struct BITMAPINFOHEADER
{
	public uint32 biSize;
	public int32 biWidth;
	public int32 biHeight;
	public uint16 biPlanes;
	public uint16 biBitCount;
	public BI_COMPRESSION biCompression;
	public uint32 biSizeImage;
	public int32 biXPelsPerMeter;
	public int32 biYPelsPerMeter;
	public uint32 biClrUsed;
	public uint32 biClrImportant;
}

[CRepr]
public struct BITMAPV4HEADER
{
	public uint32 bV4Size;
	public int32 bV4Width;
	public int32 bV4Height;
	public uint16 bV4Planes;
	public uint16 bV4BitCount;
	public BI_COMPRESSION bV4V4Compression;
	public uint32 bV4SizeImage;
	public int32 bV4XPelsPerMeter;
	public int32 bV4YPelsPerMeter;
	public uint32 bV4ClrUsed;
	public uint32 bV4ClrImportant;
	public uint32 bV4RedMask;
	public uint32 bV4GreenMask;
	public uint32 bV4BlueMask;
	public uint32 bV4AlphaMask;
	public uint32 bV4CSType;
	public CIEXYZTRIPLE bV4Endpoints;
	public uint32 bV4GammaRed;
	public uint32 bV4GammaGreen;
	public uint32 bV4GammaBlue;
}

[CRepr]
public struct BITMAPV5HEADER
{
	public uint32 bV5Size;
	public int32 bV5Width;
	public int32 bV5Height;
	public uint16 bV5Planes;
	public uint16 bV5BitCount;
	public BI_COMPRESSION bV5Compression;
	public uint32 bV5SizeImage;
	public int32 bV5XPelsPerMeter;
	public int32 bV5YPelsPerMeter;
	public uint32 bV5ClrUsed;
	public uint32 bV5ClrImportant;
	public uint32 bV5RedMask;
	public uint32 bV5GreenMask;
	public uint32 bV5BlueMask;
	public uint32 bV5AlphaMask;
	public uint32 bV5CSType;
	public CIEXYZTRIPLE bV5Endpoints;
	public uint32 bV5GammaRed;
	public uint32 bV5GammaGreen;
	public uint32 bV5GammaBlue;
	public uint32 bV5Intent;
	public uint32 bV5ProfileData;
	public uint32 bV5ProfileSize;
	public uint32 bV5Reserved;
}

[CRepr]
public struct BITMAPINFO
{
	public BITMAPINFOHEADER bmiHeader;
	public RGBQUAD* bmiColors mut => &bmiColors_impl;
	private RGBQUAD[ANYSIZE_ARRAY] bmiColors_impl;
}

[CRepr]
public struct BITMAPCOREINFO
{
	public BITMAPCOREHEADER bmciHeader;
	public RGBTRIPLE* bmciColors mut => &bmciColors_impl;
	private RGBTRIPLE[ANYSIZE_ARRAY] bmciColors_impl;
}

[CRepr, Packed(2)]
public struct BITMAPFILEHEADER
{
	public uint16 bfType;
	public uint32 bfSize;
	public uint16 bfReserved1;
	public uint16 bfReserved2;
	public uint32 bfOffBits;
}

[CRepr]
public struct HANDLETABLE
{
	public HGDIOBJ* objectHandle mut => &objectHandle_impl;
	private HGDIOBJ[ANYSIZE_ARRAY] objectHandle_impl;
}

[CRepr]
public struct METARECORD
{
	public uint32 rdSize;
	public uint16 rdFunction;
	public uint16* rdParm mut => &rdParm_impl;
	private uint16[ANYSIZE_ARRAY] rdParm_impl;
}

[CRepr, Packed(2)]
public struct METAHEADER
{
	public uint16 mtType;
	public uint16 mtHeaderSize;
	public uint16 mtVersion;
	public uint32 mtSize;
	public uint16 mtNoObjects;
	public uint32 mtMaxRecord;
	public uint16 mtNoParameters;
}

[CRepr]
public struct ENHMETARECORD
{
	public ENHANCED_METAFILE_RECORD_TYPE iType;
	public uint32 nSize;
	public uint32* dParm mut => &dParm_impl;
	private uint32[ANYSIZE_ARRAY] dParm_impl;
}

[CRepr]
public struct ENHMETAHEADER
{
	public uint32 iType;
	public uint32 nSize;
	public RECTL rclBounds;
	public RECTL rclFrame;
	public uint32 dSignature;
	public uint32 nVersion;
	public uint32 nBytes;
	public uint32 nRecords;
	public uint16 nHandles;
	public uint16 sReserved;
	public uint32 nDescription;
	public uint32 offDescription;
	public uint32 nPalEntries;
	public SIZE szlDevice;
	public SIZE szlMillimeters;
	public uint32 cbPixelFormat;
	public uint32 offPixelFormat;
	public uint32 bOpenGL;
	public SIZE szlMicrometers;
}

[CRepr]
public struct TEXTMETRICA
{
	public int32 tmHeight;
	public int32 tmAscent;
	public int32 tmDescent;
	public int32 tmInternalLeading;
	public int32 tmExternalLeading;
	public int32 tmAveCharWidth;
	public int32 tmMaxCharWidth;
	public int32 tmWeight;
	public int32 tmOverhang;
	public int32 tmDigitizedAspectX;
	public int32 tmDigitizedAspectY;
	public uint8 tmFirstChar;
	public uint8 tmLastChar;
	public uint8 tmDefaultChar;
	public uint8 tmBreakChar;
	public uint8 tmItalic;
	public uint8 tmUnderlined;
	public uint8 tmStruckOut;
	public TMPF_FLAGS tmPitchAndFamily;
	public uint8 tmCharSet;
}

[CRepr]
public struct TEXTMETRICW
{
	public int32 tmHeight;
	public int32 tmAscent;
	public int32 tmDescent;
	public int32 tmInternalLeading;
	public int32 tmExternalLeading;
	public int32 tmAveCharWidth;
	public int32 tmMaxCharWidth;
	public int32 tmWeight;
	public int32 tmOverhang;
	public int32 tmDigitizedAspectX;
	public int32 tmDigitizedAspectY;
	public char16 tmFirstChar;
	public char16 tmLastChar;
	public char16 tmDefaultChar;
	public char16 tmBreakChar;
	public uint8 tmItalic;
	public uint8 tmUnderlined;
	public uint8 tmStruckOut;
	public TMPF_FLAGS tmPitchAndFamily;
	public uint8 tmCharSet;
}

[CRepr]
public struct NEWTEXTMETRICA
{
	public int32 tmHeight;
	public int32 tmAscent;
	public int32 tmDescent;
	public int32 tmInternalLeading;
	public int32 tmExternalLeading;
	public int32 tmAveCharWidth;
	public int32 tmMaxCharWidth;
	public int32 tmWeight;
	public int32 tmOverhang;
	public int32 tmDigitizedAspectX;
	public int32 tmDigitizedAspectY;
	public uint8 tmFirstChar;
	public uint8 tmLastChar;
	public uint8 tmDefaultChar;
	public uint8 tmBreakChar;
	public uint8 tmItalic;
	public uint8 tmUnderlined;
	public uint8 tmStruckOut;
	public TMPF_FLAGS tmPitchAndFamily;
	public uint8 tmCharSet;
	public uint32 ntmFlags;
	public uint32 ntmSizeEM;
	public uint32 ntmCellHeight;
	public uint32 ntmAvgWidth;
}

[CRepr]
public struct NEWTEXTMETRICW
{
	public int32 tmHeight;
	public int32 tmAscent;
	public int32 tmDescent;
	public int32 tmInternalLeading;
	public int32 tmExternalLeading;
	public int32 tmAveCharWidth;
	public int32 tmMaxCharWidth;
	public int32 tmWeight;
	public int32 tmOverhang;
	public int32 tmDigitizedAspectX;
	public int32 tmDigitizedAspectY;
	public char16 tmFirstChar;
	public char16 tmLastChar;
	public char16 tmDefaultChar;
	public char16 tmBreakChar;
	public uint8 tmItalic;
	public uint8 tmUnderlined;
	public uint8 tmStruckOut;
	public TMPF_FLAGS tmPitchAndFamily;
	public uint8 tmCharSet;
	public uint32 ntmFlags;
	public uint32 ntmSizeEM;
	public uint32 ntmCellHeight;
	public uint32 ntmAvgWidth;
}

[CRepr]
public struct PELARRAY
{
	public int32 paXCount;
	public int32 paYCount;
	public int32 paXExt;
	public int32 paYExt;
	public uint8 paRGBs;
}

[CRepr]
public struct LOGBRUSH
{
	public BRUSH_STYLE lbStyle;
	public COLORREF lbColor;
	public uint lbHatch;
}

[CRepr]
public struct LOGBRUSH32
{
	public BRUSH_STYLE lbStyle;
	public COLORREF lbColor;
	public uint32 lbHatch;
}

[CRepr]
public struct LOGPEN
{
	public PEN_STYLE lopnStyle;
	public POINT lopnWidth;
	public COLORREF lopnColor;
}

[CRepr]
public struct EXTLOGPEN
{
	public PEN_STYLE elpPenStyle;
	public uint32 elpWidth;
	public uint32 elpBrushStyle;
	public COLORREF elpColor;
	public uint elpHatch;
	public uint32 elpNumEntries;
	public uint32* elpStyleEntry mut => &elpStyleEntry_impl;
	private uint32[ANYSIZE_ARRAY] elpStyleEntry_impl;
}

[CRepr]
public struct EXTLOGPEN32
{
	public PEN_STYLE elpPenStyle;
	public uint32 elpWidth;
	public uint32 elpBrushStyle;
	public COLORREF elpColor;
	public uint32 elpHatch;
	public uint32 elpNumEntries;
	public uint32* elpStyleEntry mut => &elpStyleEntry_impl;
	private uint32[ANYSIZE_ARRAY] elpStyleEntry_impl;
}

[CRepr]
public struct PALETTEENTRY
{
	public uint8 peRed;
	public uint8 peGreen;
	public uint8 peBlue;
	public uint8 peFlags;
}

[CRepr]
public struct LOGPALETTE
{
	public uint16 palVersion;
	public uint16 palNumEntries;
	public PALETTEENTRY* palPalEntry mut => &palPalEntry_impl;
	private PALETTEENTRY[ANYSIZE_ARRAY] palPalEntry_impl;
}

[CRepr]
public struct LOGFONTA
{
	public int32 lfHeight;
	public int32 lfWidth;
	public int32 lfEscapement;
	public int32 lfOrientation;
	public int32 lfWeight;
	public uint8 lfItalic;
	public uint8 lfUnderline;
	public uint8 lfStrikeOut;
	public FONT_CHARSET lfCharSet;
	public FONT_OUTPUT_PRECISION lfOutPrecision;
	public FONT_CLIP_PRECISION lfClipPrecision;
	public FONT_QUALITY lfQuality;
	public uint8 lfPitchAndFamily;
	public CHAR[32] lfFaceName;
}

[CRepr]
public struct LOGFONTW
{
	public int32 lfHeight;
	public int32 lfWidth;
	public int32 lfEscapement;
	public int32 lfOrientation;
	public int32 lfWeight;
	public uint8 lfItalic;
	public uint8 lfUnderline;
	public uint8 lfStrikeOut;
	public FONT_CHARSET lfCharSet;
	public FONT_OUTPUT_PRECISION lfOutPrecision;
	public FONT_CLIP_PRECISION lfClipPrecision;
	public FONT_QUALITY lfQuality;
	public uint8 lfPitchAndFamily;
	public char16[32] lfFaceName;
}

[CRepr]
public struct ENUMLOGFONTA
{
	public LOGFONTA elfLogFont;
	public uint8[64] elfFullName;
	public uint8[32] elfStyle;
}

[CRepr]
public struct ENUMLOGFONTW
{
	public LOGFONTW elfLogFont;
	public char16[64] elfFullName;
	public char16[32] elfStyle;
}

[CRepr]
public struct ENUMLOGFONTEXA
{
	public LOGFONTA elfLogFont;
	public uint8[64] elfFullName;
	public uint8[32] elfStyle;
	public uint8[32] elfScript;
}

[CRepr]
public struct ENUMLOGFONTEXW
{
	public LOGFONTW elfLogFont;
	public char16[64] elfFullName;
	public char16[32] elfStyle;
	public char16[32] elfScript;
}

[CRepr]
public struct PANOSE
{
	public PAN_FAMILY_TYPE bFamilyType;
	public PAN_SERIF_STYLE bSerifStyle;
	public PAN_WEIGHT bWeight;
	public PAN_PROPORTION bProportion;
	public PAN_CONTRAST bContrast;
	public PAN_STROKE_VARIATION bStrokeVariation;
	public PAN_ARM_STYLE bArmStyle;
	public PAN_LETT_FORM bLetterform;
	public PAN_MIDLINE bMidline;
	public PAN_XHEIGHT bXHeight;
}

[CRepr]
public struct EXTLOGFONTA
{
	public LOGFONTA elfLogFont;
	public uint8[64] elfFullName;
	public uint8[32] elfStyle;
	public uint32 elfVersion;
	public uint32 elfStyleSize;
	public uint32 elfMatch;
	public uint32 elfReserved;
	public uint8[4] elfVendorId;
	public uint32 elfCulture;
	public PANOSE elfPanose;
}

[CRepr]
public struct EXTLOGFONTW
{
	public LOGFONTW elfLogFont;
	public char16[64] elfFullName;
	public char16[32] elfStyle;
	public uint32 elfVersion;
	public uint32 elfStyleSize;
	public uint32 elfMatch;
	public uint32 elfReserved;
	public uint8[4] elfVendorId;
	public uint32 elfCulture;
	public PANOSE elfPanose;
}

[CRepr]
public struct DEVMODEA
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public POINTL dmPosition;
			public uint32 dmDisplayOrientation;
			public uint32 dmDisplayFixedOutput;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public int16 dmOrientation;
			public int16 dmPaperSize;
			public int16 dmPaperLength;
			public int16 dmPaperWidth;
			public int16 dmScale;
			public int16 dmCopies;
			public int16 dmDefaultSource;
			public int16 dmPrintQuality;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dmDisplayFlags;
		public uint32 dmNup;
	}
	public uint8[32] dmDeviceName;
	public uint16 dmSpecVersion;
	public uint16 dmDriverVersion;
	public uint16 dmSize;
	public uint16 dmDriverExtra;
	public DEVMODE_FIELD_FLAGS dmFields;
	public using _Anonymous1_e__Union Anonymous1;
	public DEVMODE_COLOR dmColor;
	public int16 dmDuplex;
	public int16 dmYResolution;
	public DEVMODE_TRUETYPE_OPTION dmTTOption;
	public DEVMODE_COLLATE dmCollate;
	public uint8[32] dmFormName;
	public uint16 dmLogPixels;
	public uint32 dmBitsPerPel;
	public uint32 dmPelsWidth;
	public uint32 dmPelsHeight;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 dmDisplayFrequency;
	public uint32 dmICMMethod;
	public uint32 dmICMIntent;
	public uint32 dmMediaType;
	public uint32 dmDitherType;
	public uint32 dmReserved1;
	public uint32 dmReserved2;
	public uint32 dmPanningWidth;
	public uint32 dmPanningHeight;
}

[CRepr]
public struct DEVMODEW
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public int16 dmOrientation;
			public int16 dmPaperSize;
			public int16 dmPaperLength;
			public int16 dmPaperWidth;
			public int16 dmScale;
			public int16 dmCopies;
			public int16 dmDefaultSource;
			public int16 dmPrintQuality;
		}
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public POINTL dmPosition;
			public uint32 dmDisplayOrientation;
			public uint32 dmDisplayFixedOutput;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dmDisplayFlags;
		public uint32 dmNup;
	}
	public char16[32] dmDeviceName;
	public uint16 dmSpecVersion;
	public uint16 dmDriverVersion;
	public uint16 dmSize;
	public uint16 dmDriverExtra;
	public DEVMODE_FIELD_FLAGS dmFields;
	public using _Anonymous1_e__Union Anonymous1;
	public DEVMODE_COLOR dmColor;
	public int16 dmDuplex;
	public int16 dmYResolution;
	public DEVMODE_TRUETYPE_OPTION dmTTOption;
	public DEVMODE_COLLATE dmCollate;
	public char16[32] dmFormName;
	public uint16 dmLogPixels;
	public uint32 dmBitsPerPel;
	public uint32 dmPelsWidth;
	public uint32 dmPelsHeight;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 dmDisplayFrequency;
	public uint32 dmICMMethod;
	public uint32 dmICMIntent;
	public uint32 dmMediaType;
	public uint32 dmDitherType;
	public uint32 dmReserved1;
	public uint32 dmReserved2;
	public uint32 dmPanningWidth;
	public uint32 dmPanningHeight;
}

[CRepr]
public struct DISPLAY_DEVICEA
{
	public uint32 cb;
	public CHAR[32] DeviceName;
	public CHAR[128] DeviceString;
	public uint32 StateFlags;
	public CHAR[128] DeviceID;
	public CHAR[128] DeviceKey;
}

[CRepr]
public struct DISPLAY_DEVICEW
{
	public uint32 cb;
	public char16[32] DeviceName;
	public char16[128] DeviceString;
	public uint32 StateFlags;
	public char16[128] DeviceID;
	public char16[128] DeviceKey;
}

[CRepr]
public struct RGNDATAHEADER
{
	public uint32 dwSize;
	public uint32 iType;
	public uint32 nCount;
	public uint32 nRgnSize;
	public RECT rcBound;
}

[CRepr]
public struct RGNDATA
{
	public RGNDATAHEADER rdh;
	public CHAR* Buffer mut => &Buffer_impl;
	private CHAR[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct ABC
{
	public int32 abcA;
	public uint32 abcB;
	public int32 abcC;
}

[CRepr]
public struct ABCFLOAT
{
	public float abcfA;
	public float abcfB;
	public float abcfC;
}

[CRepr]
public struct OUTLINETEXTMETRICA
{
	public uint32 otmSize;
	public TEXTMETRICA otmTextMetrics;
	public uint8 otmFiller;
	public PANOSE otmPanoseNumber;
	public uint32 otmfsSelection;
	public uint32 otmfsType;
	public int32 otmsCharSlopeRise;
	public int32 otmsCharSlopeRun;
	public int32 otmItalicAngle;
	public uint32 otmEMSquare;
	public int32 otmAscent;
	public int32 otmDescent;
	public uint32 otmLineGap;
	public uint32 otmsCapEmHeight;
	public uint32 otmsXHeight;
	public RECT otmrcFontBox;
	public int32 otmMacAscent;
	public int32 otmMacDescent;
	public uint32 otmMacLineGap;
	public uint32 otmusMinimumPPEM;
	public POINT otmptSubscriptSize;
	public POINT otmptSubscriptOffset;
	public POINT otmptSuperscriptSize;
	public POINT otmptSuperscriptOffset;
	public uint32 otmsStrikeoutSize;
	public int32 otmsStrikeoutPosition;
	public int32 otmsUnderscoreSize;
	public int32 otmsUnderscorePosition;
	public PSTR otmpFamilyName;
	public PSTR otmpFaceName;
	public PSTR otmpStyleName;
	public PSTR otmpFullName;
}

[CRepr]
public struct OUTLINETEXTMETRICW
{
	public uint32 otmSize;
	public TEXTMETRICW otmTextMetrics;
	public uint8 otmFiller;
	public PANOSE otmPanoseNumber;
	public uint32 otmfsSelection;
	public uint32 otmfsType;
	public int32 otmsCharSlopeRise;
	public int32 otmsCharSlopeRun;
	public int32 otmItalicAngle;
	public uint32 otmEMSquare;
	public int32 otmAscent;
	public int32 otmDescent;
	public uint32 otmLineGap;
	public uint32 otmsCapEmHeight;
	public uint32 otmsXHeight;
	public RECT otmrcFontBox;
	public int32 otmMacAscent;
	public int32 otmMacDescent;
	public uint32 otmMacLineGap;
	public uint32 otmusMinimumPPEM;
	public POINT otmptSubscriptSize;
	public POINT otmptSubscriptOffset;
	public POINT otmptSuperscriptSize;
	public POINT otmptSuperscriptOffset;
	public uint32 otmsStrikeoutSize;
	public int32 otmsStrikeoutPosition;
	public int32 otmsUnderscoreSize;
	public int32 otmsUnderscorePosition;
	public PSTR otmpFamilyName;
	public PSTR otmpFaceName;
	public PSTR otmpStyleName;
	public PSTR otmpFullName;
}

[CRepr]
public struct POLYTEXTA
{
	public int32 x;
	public int32 y;
	public uint32 n;
	public PSTR lpstr;
	public uint32 uiFlags;
	public RECT rcl;
	public int32* pdx;
}

[CRepr]
public struct POLYTEXTW
{
	public int32 x;
	public int32 y;
	public uint32 n;
	public PWSTR lpstr;
	public uint32 uiFlags;
	public RECT rcl;
	public int32* pdx;
}

[CRepr]
public struct FIXED
{
	public uint16 fract;
	public int16 value;
}

[CRepr]
public struct MAT2
{
	public FIXED eM11;
	public FIXED eM12;
	public FIXED eM21;
	public FIXED eM22;
}

[CRepr]
public struct GLYPHMETRICS
{
	public uint32 gmBlackBoxX;
	public uint32 gmBlackBoxY;
	public POINT gmptGlyphOrigin;
	public int16 gmCellIncX;
	public int16 gmCellIncY;
}

[CRepr]
public struct POINTFX
{
	public FIXED x;
	public FIXED y;
}

[CRepr]
public struct TTPOLYCURVE
{
	public uint16 wType;
	public uint16 cpfx;
	public POINTFX* apfx mut => &apfx_impl;
	private POINTFX[ANYSIZE_ARRAY] apfx_impl;
}

[CRepr]
public struct TTPOLYGONHEADER
{
	public uint32 cb;
	public uint32 dwType;
	public POINTFX pfxStart;
}

[CRepr]
public struct GCP_RESULTSA
{
	public uint32 lStructSize;
	public PSTR lpOutString;
	public uint32* lpOrder;
	public int32* lpDx;
	public int32* lpCaretPos;
	public PSTR lpClass;
	public PWSTR lpGlyphs;
	public uint32 nGlyphs;
	public int32 nMaxFit;
}

[CRepr]
public struct GCP_RESULTSW
{
	public uint32 lStructSize;
	public PWSTR lpOutString;
	public uint32* lpOrder;
	public int32* lpDx;
	public int32* lpCaretPos;
	public PSTR lpClass;
	public PWSTR lpGlyphs;
	public uint32 nGlyphs;
	public int32 nMaxFit;
}

[CRepr]
public struct RASTERIZER_STATUS
{
	public int16 nSize;
	public int16 wFlags;
	public int16 nLanguageID;
}

[CRepr]
public struct WCRANGE
{
	public char16 wcLow;
	public uint16 cGlyphs;
}

[CRepr]
public struct GLYPHSET
{
	public uint32 cbThis;
	public uint32 flAccel;
	public uint32 cGlyphsSupported;
	public uint32 cRanges;
	public WCRANGE* ranges mut => &ranges_impl;
	private WCRANGE[ANYSIZE_ARRAY] ranges_impl;
}

[CRepr]
public struct DESIGNVECTOR
{
	public uint32 dvReserved;
	public uint32 dvNumAxes;
	public int32[16] dvValues;
}

[CRepr]
public struct AXISINFOA
{
	public int32 axMinValue;
	public int32 axMaxValue;
	public uint8[16] axAxisName;
}

[CRepr]
public struct AXISINFOW
{
	public int32 axMinValue;
	public int32 axMaxValue;
	public char16[16] axAxisName;
}

[CRepr]
public struct AXESLISTA
{
	public uint32 axlReserved;
	public uint32 axlNumAxes;
	public AXISINFOA[16] axlAxisInfo;
}

[CRepr]
public struct AXESLISTW
{
	public uint32 axlReserved;
	public uint32 axlNumAxes;
	public AXISINFOW[16] axlAxisInfo;
}

[CRepr]
public struct ENUMLOGFONTEXDVA
{
	public ENUMLOGFONTEXA elfEnumLogfontEx;
	public DESIGNVECTOR elfDesignVector;
}

[CRepr]
public struct ENUMLOGFONTEXDVW
{
	public ENUMLOGFONTEXW elfEnumLogfontEx;
	public DESIGNVECTOR elfDesignVector;
}

[CRepr]
public struct TRIVERTEX
{
	public int32 x;
	public int32 y;
	public uint16 Red;
	public uint16 Green;
	public uint16 Blue;
	public uint16 Alpha;
}

[CRepr]
public struct GRADIENT_TRIANGLE
{
	public uint32 Vertex1;
	public uint32 Vertex2;
	public uint32 Vertex3;
}

[CRepr]
public struct GRADIENT_RECT
{
	public uint32 UpperLeft;
	public uint32 LowerRight;
}

[CRepr]
public struct BLENDFUNCTION
{
	public uint8 BlendOp;
	public uint8 BlendFlags;
	public uint8 SourceConstantAlpha;
	public uint8 AlphaFormat;
}

[CRepr]
public struct DIBSECTION
{
	public BITMAP dsBm;
	public BITMAPINFOHEADER dsBmih;
	public uint32[3] dsBitfields;
	public HANDLE dshSection;
	public uint32 dsOffset;
}

[CRepr]
public struct COLORADJUSTMENT
{
	public uint16 caSize;
	public uint16 caFlags;
	public uint16 caIlluminantIndex;
	public uint16 caRedGamma;
	public uint16 caGreenGamma;
	public uint16 caBlueGamma;
	public uint16 caReferenceBlack;
	public uint16 caReferenceWhite;
	public int16 caContrast;
	public int16 caBrightness;
	public int16 caColorfulness;
	public int16 caRedGreenTint;
}

[CRepr]
public struct KERNINGPAIR
{
	public uint16 wFirst;
	public uint16 wSecond;
	public int32 iKernAmount;
}

[CRepr]
public struct EMR
{
	public ENHANCED_METAFILE_RECORD_TYPE iType;
	public uint32 nSize;
}

[CRepr]
public struct EMRTEXT
{
	public POINTL ptlReference;
	public uint32 nChars;
	public uint32 offString;
	public uint32 fOptions;
	public RECTL rcl;
	public uint32 offDx;
}

[CRepr]
public struct ABORTPATH
{
	public EMR emr;
}

[CRepr]
public struct EMRSELECTCLIPPATH
{
	public EMR emr;
	public uint32 iMode;
}

[CRepr]
public struct EMRSETMITERLIMIT
{
	public EMR emr;
	public float eMiterLimit;
}

[CRepr]
public struct EMRRESTOREDC
{
	public EMR emr;
	public int32 iRelative;
}

[CRepr]
public struct EMRSETARCDIRECTION
{
	public EMR emr;
	public uint32 iArcDirection;
}

[CRepr]
public struct EMRSETMAPPERFLAGS
{
	public EMR emr;
	public uint32 dwFlags;
}

[CRepr]
public struct EMRSETTEXTCOLOR
{
	public EMR emr;
	public COLORREF crColor;
}

[CRepr]
public struct EMRSELECTOBJECT
{
	public EMR emr;
	public uint32 ihObject;
}

[CRepr]
public struct EMRSELECTPALETTE
{
	public EMR emr;
	public uint32 ihPal;
}

[CRepr]
public struct EMRRESIZEPALETTE
{
	public EMR emr;
	public uint32 ihPal;
	public uint32 cEntries;
}

[CRepr]
public struct EMRSETPALETTEENTRIES
{
	public EMR emr;
	public uint32 ihPal;
	public uint32 iStart;
	public uint32 cEntries;
	public PALETTEENTRY* aPalEntries mut => &aPalEntries_impl;
	private PALETTEENTRY[ANYSIZE_ARRAY] aPalEntries_impl;
}

[CRepr]
public struct EMRSETCOLORADJUSTMENT
{
	public EMR emr;
	public COLORADJUSTMENT ColorAdjustment;
}

[CRepr]
public struct EMRGDICOMMENT
{
	public EMR emr;
	public uint32 cbData;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct EMREOF
{
	public EMR emr;
	public uint32 nPalEntries;
	public uint32 offPalEntries;
	public uint32 nSizeLast;
}

[CRepr]
public struct EMRLINETO
{
	public EMR emr;
	public POINTL ptl;
}

[CRepr]
public struct EMROFFSETCLIPRGN
{
	public EMR emr;
	public POINTL ptlOffset;
}

[CRepr]
public struct EMRFILLPATH
{
	public EMR emr;
	public RECTL rclBounds;
}

[CRepr]
public struct EMREXCLUDECLIPRECT
{
	public EMR emr;
	public RECTL rclClip;
}

[CRepr]
public struct EMRSETVIEWPORTORGEX
{
	public EMR emr;
	public POINTL ptlOrigin;
}

[CRepr]
public struct EMRSETVIEWPORTEXTEX
{
	public EMR emr;
	public SIZE szlExtent;
}

[CRepr]
public struct EMRSCALEVIEWPORTEXTEX
{
	public EMR emr;
	public int32 xNum;
	public int32 xDenom;
	public int32 yNum;
	public int32 yDenom;
}

[CRepr]
public struct EMRSETWORLDTRANSFORM
{
	public EMR emr;
	public XFORM xform;
}

[CRepr]
public struct EMRMODIFYWORLDTRANSFORM
{
	public EMR emr;
	public XFORM xform;
	public MODIFY_WORLD_TRANSFORM_MODE iMode;
}

[CRepr]
public struct EMRSETPIXELV
{
	public EMR emr;
	public POINTL ptlPixel;
	public COLORREF crColor;
}

[CRepr]
public struct EMREXTFLOODFILL
{
	public EMR emr;
	public POINTL ptlStart;
	public COLORREF crColor;
	public uint32 iMode;
}

[CRepr]
public struct EMRELLIPSE
{
	public EMR emr;
	public RECTL rclBox;
}

[CRepr]
public struct EMRROUNDRECT
{
	public EMR emr;
	public RECTL rclBox;
	public SIZE szlCorner;
}

[CRepr]
public struct EMRARC
{
	public EMR emr;
	public RECTL rclBox;
	public POINTL ptlStart;
	public POINTL ptlEnd;
}

[CRepr]
public struct EMRANGLEARC
{
	public EMR emr;
	public POINTL ptlCenter;
	public uint32 nRadius;
	public float eStartAngle;
	public float eSweepAngle;
}

[CRepr]
public struct EMRPOLYLINE
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cptl;
	public POINTL* aptl mut => &aptl_impl;
	private POINTL[ANYSIZE_ARRAY] aptl_impl;
}

[CRepr]
public struct EMRPOLYLINE16
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cpts;
	public POINTS* apts mut => &apts_impl;
	private POINTS[ANYSIZE_ARRAY] apts_impl;
}

[CRepr]
public struct EMRPOLYDRAW
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cptl;
	public POINTL* aptl mut => &aptl_impl;
	private POINTL[ANYSIZE_ARRAY] aptl_impl;
	public uint8* abTypes mut => &abTypes_impl;
	private uint8[ANYSIZE_ARRAY] abTypes_impl;
}

[CRepr]
public struct EMRPOLYDRAW16
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cpts;
	public POINTS* apts mut => &apts_impl;
	private POINTS[ANYSIZE_ARRAY] apts_impl;
	public uint8* abTypes mut => &abTypes_impl;
	private uint8[ANYSIZE_ARRAY] abTypes_impl;
}

[CRepr]
public struct EMRPOLYPOLYLINE
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 nPolys;
	public uint32 cptl;
	public uint32* aPolyCounts mut => &aPolyCounts_impl;
	private uint32[ANYSIZE_ARRAY] aPolyCounts_impl;
	public POINTL* aptl mut => &aptl_impl;
	private POINTL[ANYSIZE_ARRAY] aptl_impl;
}

[CRepr]
public struct EMRPOLYPOLYLINE16
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 nPolys;
	public uint32 cpts;
	public uint32* aPolyCounts mut => &aPolyCounts_impl;
	private uint32[ANYSIZE_ARRAY] aPolyCounts_impl;
	public POINTS* apts mut => &apts_impl;
	private POINTS[ANYSIZE_ARRAY] apts_impl;
}

[CRepr]
public struct EMRINVERTRGN
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cbRgnData;
	public uint8* RgnData mut => &RgnData_impl;
	private uint8[ANYSIZE_ARRAY] RgnData_impl;
}

[CRepr]
public struct EMRFILLRGN
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cbRgnData;
	public uint32 ihBrush;
	public uint8* RgnData mut => &RgnData_impl;
	private uint8[ANYSIZE_ARRAY] RgnData_impl;
}

[CRepr]
public struct EMRFRAMERGN
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cbRgnData;
	public uint32 ihBrush;
	public SIZE szlStroke;
	public uint8* RgnData mut => &RgnData_impl;
	private uint8[ANYSIZE_ARRAY] RgnData_impl;
}

[CRepr]
public struct EMREXTSELECTCLIPRGN
{
	public EMR emr;
	public uint32 cbRgnData;
	public RGN_COMBINE_MODE iMode;
	public uint8* RgnData mut => &RgnData_impl;
	private uint8[ANYSIZE_ARRAY] RgnData_impl;
}

[CRepr]
public struct EMREXTTEXTOUTA
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 iGraphicsMode;
	public float exScale;
	public float eyScale;
	public EMRTEXT emrtext;
}

[CRepr]
public struct EMRPOLYTEXTOUTA
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 iGraphicsMode;
	public float exScale;
	public float eyScale;
	public int32 cStrings;
	public EMRTEXT* aemrtext mut => &aemrtext_impl;
	private EMRTEXT[ANYSIZE_ARRAY] aemrtext_impl;
}

[CRepr]
public struct EMRBITBLT
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 cxDest;
	public int32 cyDest;
	public uint32 dwRop;
	public int32 xSrc;
	public int32 ySrc;
	public XFORM xformSrc;
	public COLORREF crBkColorSrc;
	public uint32 iUsageSrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
}

[CRepr]
public struct EMRSTRETCHBLT
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 cxDest;
	public int32 cyDest;
	public uint32 dwRop;
	public int32 xSrc;
	public int32 ySrc;
	public XFORM xformSrc;
	public COLORREF crBkColorSrc;
	public uint32 iUsageSrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public int32 cxSrc;
	public int32 cySrc;
}

[CRepr]
public struct EMRMASKBLT
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 cxDest;
	public int32 cyDest;
	public uint32 dwRop;
	public int32 xSrc;
	public int32 ySrc;
	public XFORM xformSrc;
	public COLORREF crBkColorSrc;
	public uint32 iUsageSrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public int32 xMask;
	public int32 yMask;
	public uint32 iUsageMask;
	public uint32 offBmiMask;
	public uint32 cbBmiMask;
	public uint32 offBitsMask;
	public uint32 cbBitsMask;
}

[CRepr]
public struct EMRPLGBLT
{
	public EMR emr;
	public RECTL rclBounds;
	public POINTL[3] aptlDest;
	public int32 xSrc;
	public int32 ySrc;
	public int32 cxSrc;
	public int32 cySrc;
	public XFORM xformSrc;
	public COLORREF crBkColorSrc;
	public uint32 iUsageSrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public int32 xMask;
	public int32 yMask;
	public uint32 iUsageMask;
	public uint32 offBmiMask;
	public uint32 cbBmiMask;
	public uint32 offBitsMask;
	public uint32 cbBitsMask;
}

[CRepr]
public struct EMRSETDIBITSTODEVICE
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 xSrc;
	public int32 ySrc;
	public int32 cxSrc;
	public int32 cySrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public uint32 iUsageSrc;
	public uint32 iStartScan;
	public uint32 cScans;
}

[CRepr]
public struct EMRSTRETCHDIBITS
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 xSrc;
	public int32 ySrc;
	public int32 cxSrc;
	public int32 cySrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public uint32 iUsageSrc;
	public uint32 dwRop;
	public int32 cxDest;
	public int32 cyDest;
}

[CRepr]
public struct EMREXTCREATEFONTINDIRECTW
{
	public EMR emr;
	public uint32 ihFont;
	public EXTLOGFONTW elfw;
}

[CRepr]
public struct EMRCREATEPALETTE
{
	public EMR emr;
	public uint32 ihPal;
	public LOGPALETTE lgpl;
}

[CRepr]
public struct EMRCREATEPEN
{
	public EMR emr;
	public uint32 ihPen;
	public LOGPEN lopn;
}

[CRepr]
public struct EMREXTCREATEPEN
{
	public EMR emr;
	public uint32 ihPen;
	public uint32 offBmi;
	public uint32 cbBmi;
	public uint32 offBits;
	public uint32 cbBits;
	public EXTLOGPEN32 elp;
}

[CRepr]
public struct EMRCREATEBRUSHINDIRECT
{
	public EMR emr;
	public uint32 ihBrush;
	public LOGBRUSH32 lb;
}

[CRepr]
public struct EMRCREATEMONOBRUSH
{
	public EMR emr;
	public uint32 ihBrush;
	public uint32 iUsage;
	public uint32 offBmi;
	public uint32 cbBmi;
	public uint32 offBits;
	public uint32 cbBits;
}

[CRepr]
public struct EMRCREATEDIBPATTERNBRUSHPT
{
	public EMR emr;
	public uint32 ihBrush;
	public uint32 iUsage;
	public uint32 offBmi;
	public uint32 cbBmi;
	public uint32 offBits;
	public uint32 cbBits;
}

[CRepr]
public struct EMRFORMAT
{
	public uint32 dSignature;
	public uint32 nVersion;
	public uint32 cbData;
	public uint32 offData;
}

[CRepr]
public struct EMRGLSRECORD
{
	public EMR emr;
	public uint32 cbData;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct EMRGLSBOUNDEDRECORD
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 cbData;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct EMRSETCOLORSPACE
{
	public EMR emr;
	public uint32 ihCS;
}

[CRepr]
public struct EMREXTESCAPE
{
	public EMR emr;
	public int32 iEscape;
	public int32 cbEscData;
	public uint8* EscData mut => &EscData_impl;
	private uint8[ANYSIZE_ARRAY] EscData_impl;
}

[CRepr]
public struct EMRNAMEDESCAPE
{
	public EMR emr;
	public int32 iEscape;
	public int32 cbDriver;
	public int32 cbEscData;
	public uint8* EscData mut => &EscData_impl;
	private uint8[ANYSIZE_ARRAY] EscData_impl;
}

[CRepr]
public struct EMRSETICMPROFILE
{
	public EMR emr;
	public uint32 dwFlags;
	public uint32 cbName;
	public uint32 cbData;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct EMRCOLORMATCHTOTARGET
{
	public EMR emr;
	public uint32 dwAction;
	public uint32 dwFlags;
	public uint32 cbName;
	public uint32 cbData;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct EMRCOLORCORRECTPALETTE
{
	public EMR emr;
	public uint32 ihPalette;
	public uint32 nFirstEntry;
	public uint32 nPalEntries;
	public uint32 nReserved;
}

[CRepr]
public struct EMRALPHABLEND
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 cxDest;
	public int32 cyDest;
	public uint32 dwRop;
	public int32 xSrc;
	public int32 ySrc;
	public XFORM xformSrc;
	public COLORREF crBkColorSrc;
	public uint32 iUsageSrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public int32 cxSrc;
	public int32 cySrc;
}

[CRepr]
public struct EMRGRADIENTFILL
{
	public EMR emr;
	public RECTL rclBounds;
	public uint32 nVer;
	public uint32 nTri;
	public GRADIENT_FILL ulMode;
	public TRIVERTEX* Ver mut => &Ver_impl;
	private TRIVERTEX[ANYSIZE_ARRAY] Ver_impl;
}

[CRepr]
public struct EMRTRANSPARENTBLT
{
	public EMR emr;
	public RECTL rclBounds;
	public int32 xDest;
	public int32 yDest;
	public int32 cxDest;
	public int32 cyDest;
	public uint32 dwRop;
	public int32 xSrc;
	public int32 ySrc;
	public XFORM xformSrc;
	public COLORREF crBkColorSrc;
	public uint32 iUsageSrc;
	public uint32 offBmiSrc;
	public uint32 cbBmiSrc;
	public uint32 offBitsSrc;
	public uint32 cbBitsSrc;
	public int32 cxSrc;
	public int32 cySrc;
}

[CRepr]
public struct WGLSWAP
{
	public HDC hdc;
	public uint32 uiFlags;
}

[CRepr]
public struct TTLOADINFO
{
	public uint16 usStructSize;
	public uint16 usRefStrSize;
	public uint16* pusRefStr;
}

[CRepr]
public struct TTEMBEDINFO
{
	public uint16 usStructSize;
	public uint16 usRootStrSize;
	public uint16* pusRootStr;
}

[CRepr]
public struct TTVALIDATIONTESTSPARAMS
{
	public uint32 ulStructSize;
	public int32 lTestFromSize;
	public int32 lTestToSize;
	public uint32 ulCharSet;
	public uint16 usReserved1;
	public uint16 usCharCodeCount;
	public uint16* pusCharCodeSet;
}

[CRepr]
public struct TTVALIDATIONTESTSPARAMSEX
{
	public uint32 ulStructSize;
	public int32 lTestFromSize;
	public int32 lTestToSize;
	public uint32 ulCharSet;
	public uint16 usReserved1;
	public uint16 usCharCodeCount;
	public uint32* pulCharCodeSet;
}

[CRepr]
public struct PAINTSTRUCT
{
	public HDC hdc;
	public BOOL fErase;
	public RECT rcPaint;
	public BOOL fRestore;
	public BOOL fIncUpdate;
	public uint8[32] rgbReserved;
}

[CRepr]
public struct DRAWTEXTPARAMS
{
	public uint32 cbSize;
	public int32 iTabLength;
	public int32 iLeftMargin;
	public int32 iRightMargin;
	public uint32 uiLengthDrawn;
}

[CRepr]
public struct MONITORINFO
{
	public uint32 cbSize;
	public RECT rcMonitor;
	public RECT rcWork;
	public uint32 dwFlags;
}

#endregion

#region Functions
public static
{
	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetObjectA(HGDIOBJ h, int32 c, void* pv);
	public static int32 GetObject(HGDIOBJ h, int32 c, void* pv) => GetObjectA(h, c, pv);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AddFontResourceA(PSTR param0);
	public static int32 AddFontResource(PSTR param0) => AddFontResourceA(param0);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AddFontResourceW(PWSTR param0);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AnimatePalette(HPALETTE hPal, uint32 iStartIndex, uint32 cEntries, PALETTEENTRY* ppe);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Arc(HDC hdc, int32 x1, int32 y1, int32 x2, int32 y2, int32 x3, int32 y3, int32 x4, int32 y4);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BitBlt(HDC hdc, int32 x, int32 y, int32 cx, int32 cy, HDC hdcSrc, int32 x1, int32 y1, ROP_CODE rop);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelDC(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Chord(HDC hdc, int32 x1, int32 y1, int32 x2, int32 y2, int32 x3, int32 y3, int32 x4, int32 y4);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMETAFILE CloseMetaFile(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE CombineRgn(HRGN hrgnDst, HRGN hrgnSrc1, HRGN hrgnSrc2, RGN_COMBINE_MODE iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMETAFILE CopyMetaFileA(HMETAFILE param0, PSTR param1);
	public static HMETAFILE CopyMetaFile(HMETAFILE param0, PSTR param1) => CopyMetaFileA(param0, param1);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMETAFILE CopyMetaFileW(HMETAFILE param0, PWSTR param1);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateBitmap(int32 nWidth, int32 nHeight, uint32 nPlanes, uint32 nBitCount, void* lpBits);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateBitmapIndirect(BITMAP* pbm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH CreateBrushIndirect(LOGBRUSH* plbrush);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateCompatibleBitmap(HDC hdc, int32 cx, int32 cy);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateDiscardableBitmap(HDC hdc, int32 cx, int32 cy);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CreatedHDC CreateCompatibleDC(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CreatedHDC CreateDCA(PSTR pwszDriver, PSTR pwszDevice, PSTR pszPort, DEVMODEA* pdm);
	public static CreatedHDC CreateDC(PSTR pwszDriver, PSTR pwszDevice, PSTR pszPort, DEVMODEA* pdm) => CreateDCA(pwszDriver, pwszDevice, pszPort, pdm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CreatedHDC CreateDCW(PWSTR pwszDriver, PWSTR pwszDevice, PWSTR pszPort, DEVMODEW* pdm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateDIBitmap(HDC hdc, BITMAPINFOHEADER* pbmih, uint32 flInit, void* pjBits, BITMAPINFO* pbmi, DIB_USAGE iUsage);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH CreateDIBPatternBrush(int h, DIB_USAGE iUsage);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH CreateDIBPatternBrushPt(void* lpPackedDIB, DIB_USAGE iUsage);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreateEllipticRgn(int32 x1, int32 y1, int32 x2, int32 y2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreateEllipticRgnIndirect(RECT* lprect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HFONT CreateFontIndirectA(LOGFONTA* lplf);
	public static HFONT CreateFontIndirect(LOGFONTA* lplf) => CreateFontIndirectA(lplf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HFONT CreateFontIndirectW(LOGFONTW* lplf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HFONT CreateFontA(int32 cHeight, int32 cWidth, int32 cEscapement, int32 cOrientation, int32 cWeight, uint32 bItalic, uint32 bUnderline, uint32 bStrikeOut, uint32 iCharSet, uint32 iOutPrecision, uint32 iClipPrecision, uint32 iQuality, uint32 iPitchAndFamily, PSTR pszFaceName);
	public static HFONT CreateFont(int32 cHeight, int32 cWidth, int32 cEscapement, int32 cOrientation, int32 cWeight, uint32 bItalic, uint32 bUnderline, uint32 bStrikeOut, uint32 iCharSet, uint32 iOutPrecision, uint32 iClipPrecision, uint32 iQuality, uint32 iPitchAndFamily, PSTR pszFaceName) => CreateFontA(cHeight, cWidth, cEscapement, cOrientation, cWeight, bItalic, bUnderline, bStrikeOut, iCharSet, iOutPrecision, iClipPrecision, iQuality, iPitchAndFamily, pszFaceName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HFONT CreateFontW(int32 cHeight, int32 cWidth, int32 cEscapement, int32 cOrientation, int32 cWeight, uint32 bItalic, uint32 bUnderline, uint32 bStrikeOut, uint32 iCharSet, uint32 iOutPrecision, uint32 iClipPrecision, uint32 iQuality, uint32 iPitchAndFamily, PWSTR pszFaceName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH CreateHatchBrush(HATCH_BRUSH_STYLE iHatch, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CreatedHDC CreateICA(PSTR pszDriver, PSTR pszDevice, PSTR pszPort, DEVMODEA* pdm);
	public static CreatedHDC CreateIC(PSTR pszDriver, PSTR pszDevice, PSTR pszPort, DEVMODEA* pdm) => CreateICA(pszDriver, pszDevice, pszPort, pdm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CreatedHDC CreateICW(PWSTR pszDriver, PWSTR pszDevice, PWSTR pszPort, DEVMODEW* pdm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HdcMetdataFileHandle CreateMetaFileA(PSTR pszFile);
	public static HdcMetdataFileHandle CreateMetaFile(PSTR pszFile) => CreateMetaFileA(pszFile);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HdcMetdataFileHandle CreateMetaFileW(PWSTR pszFile);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPALETTE CreatePalette(LOGPALETTE* plpal);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPEN CreatePen(PEN_STYLE iStyle, int32 cWidth, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPEN CreatePenIndirect(LOGPEN* plpen);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreatePolyPolygonRgn(POINT* pptl, int32* pc, int32 cPoly, CREATE_POLYGON_RGN_MODE iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH CreatePatternBrush(HBITMAP hbm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreateRectRgn(int32 x1, int32 y1, int32 x2, int32 y2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreateRectRgnIndirect(RECT* lprect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreateRoundRectRgn(int32 x1, int32 y1, int32 x2, int32 y2, int32 w, int32 h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateScalableFontResourceA(uint32 fdwHidden, PSTR lpszFont, PSTR lpszFile, PSTR lpszPath);
	public static BOOL CreateScalableFontResource(uint32 fdwHidden, PSTR lpszFont, PSTR lpszFile, PSTR lpszPath) => CreateScalableFontResourceA(fdwHidden, lpszFont, lpszFile, lpszPath);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateScalableFontResourceW(uint32 fdwHidden, PWSTR lpszFont, PWSTR lpszFile, PWSTR lpszPath);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH CreateSolidBrush(COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteDC(CreatedHDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteMetaFile(HMETAFILE hmf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteObject(HGDIOBJ ho);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DrawEscape(HDC hdc, int32 iEscape, int32 cjIn, PSTR lpIn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Ellipse(HDC hdc, int32 left, int32 top, int32 right, int32 bottom);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumFontFamiliesExA(HDC hdc, LOGFONTA* lpLogfont, FONTENUMPROCA lpProc, LPARAM lParam, uint32 dwFlags);
	public static int32 EnumFontFamiliesEx(HDC hdc, LOGFONTA* lpLogfont, FONTENUMPROCA lpProc, LPARAM lParam, uint32 dwFlags) => EnumFontFamiliesExA(hdc, lpLogfont, lpProc, lParam, dwFlags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumFontFamiliesExW(HDC hdc, LOGFONTW* lpLogfont, FONTENUMPROCW lpProc, LPARAM lParam, uint32 dwFlags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumFontFamiliesA(HDC hdc, PSTR lpLogfont, FONTENUMPROCA lpProc, LPARAM lParam);
	public static int32 EnumFontFamilies(HDC hdc, PSTR lpLogfont, FONTENUMPROCA lpProc, LPARAM lParam) => EnumFontFamiliesA(hdc, lpLogfont, lpProc, lParam);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumFontFamiliesW(HDC hdc, PWSTR lpLogfont, FONTENUMPROCW lpProc, LPARAM lParam);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumFontsA(HDC hdc, PSTR lpLogfont, FONTENUMPROCA lpProc, LPARAM lParam);
	public static int32 EnumFonts(HDC hdc, PSTR lpLogfont, FONTENUMPROCA lpProc, LPARAM lParam) => EnumFontsA(hdc, lpLogfont, lpProc, lParam);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumFontsW(HDC hdc, PWSTR lpLogfont, FONTENUMPROCW lpProc, LPARAM lParam);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumObjects(HDC hdc, OBJ_TYPE nType, GOBJENUMPROC lpFunc, LPARAM lParam);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EqualRgn(HRGN hrgn1, HRGN hrgn2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE ExcludeClipRect(HDC hdc, int32 left, int32 top, int32 right, int32 bottom);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN ExtCreateRegion(XFORM* lpx, uint32 nCount, RGNDATA* lpData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExtFloodFill(HDC hdc, int32 x, int32 y, COLORREF color, EXT_FLOOD_FILL_TYPE type);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FillRgn(HDC hdc, HRGN hrgn, HBRUSH hbr);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FloodFill(HDC hdc, int32 x, int32 y, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FrameRgn(HDC hdc, HRGN hrgn, HBRUSH hbr, int32 w, int32 h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern R2_MODE GetROP2(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAspectRatioFilterEx(HDC hdc, SIZE* lpsize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetBkColor(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetDCBrushColor(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetDCPenColor(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BACKGROUND_MODE GetBkMode(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetBitmapBits(HBITMAP hbit, int32 cb, void* lpvBits);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetBitmapDimensionEx(HBITMAP hbit, SIZE* lpsize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetBoundsRect(HDC hdc, RECT* lprect, uint32 flags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetBrushOrgEx(HDC hdc, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidthA(HDC hdc, uint32 iFirst, uint32 iLast, int32* lpBuffer);
	public static BOOL GetCharWidth(HDC hdc, uint32 iFirst, uint32 iLast, int32* lpBuffer) => GetCharWidthA(hdc, iFirst, iLast, lpBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidthW(HDC hdc, uint32 iFirst, uint32 iLast, int32* lpBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidth32A(HDC hdc, uint32 iFirst, uint32 iLast, int32* lpBuffer);
	public static BOOL GetCharWidth32(HDC hdc, uint32 iFirst, uint32 iLast, int32* lpBuffer) => GetCharWidth32A(hdc, iFirst, iLast, lpBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidth32W(HDC hdc, uint32 iFirst, uint32 iLast, int32* lpBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidthFloatA(HDC hdc, uint32 iFirst, uint32 iLast, float* lpBuffer);
	public static BOOL GetCharWidthFloat(HDC hdc, uint32 iFirst, uint32 iLast, float* lpBuffer) => GetCharWidthFloatA(hdc, iFirst, iLast, lpBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidthFloatW(HDC hdc, uint32 iFirst, uint32 iLast, float* lpBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharABCWidthsA(HDC hdc, uint32 wFirst, uint32 wLast, ABC* lpABC);
	public static BOOL GetCharABCWidths(HDC hdc, uint32 wFirst, uint32 wLast, ABC* lpABC) => GetCharABCWidthsA(hdc, wFirst, wLast, lpABC);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharABCWidthsW(HDC hdc, uint32 wFirst, uint32 wLast, ABC* lpABC);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharABCWidthsFloatA(HDC hdc, uint32 iFirst, uint32 iLast, ABCFLOAT* lpABC);
	public static BOOL GetCharABCWidthsFloat(HDC hdc, uint32 iFirst, uint32 iLast, ABCFLOAT* lpABC) => GetCharABCWidthsFloatA(hdc, iFirst, iLast, lpABC);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharABCWidthsFloatW(HDC hdc, uint32 iFirst, uint32 iLast, ABCFLOAT* lpABC);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE GetClipBox(HDC hdc, RECT* lprect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetClipRgn(HDC hdc, HRGN hrgn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMetaRgn(HDC hdc, HRGN hrgn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HGDIOBJ GetCurrentObject(HDC hdc, OBJ_TYPE type);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentPositionEx(HDC hdc, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDeviceCaps(HDC hdc, GET_DEVICE_CAPS_INDEX index);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDIBits(HDC hdc, HBITMAP hbm, uint32 start, uint32 cLines, void* lpvBits, BITMAPINFO* lpbmi, DIB_USAGE usage);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFontData(HDC hdc, uint32 dwTable, uint32 dwOffset, void* pvBuffer, uint32 cjBuffer);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetGlyphOutlineA(HDC hdc, uint32 uChar, GET_GLYPH_OUTLINE_FORMAT fuFormat, GLYPHMETRICS* lpgm, uint32 cjBuffer, void* pvBuffer, MAT2* lpmat2);
	public static uint32 GetGlyphOutline(HDC hdc, uint32 uChar, GET_GLYPH_OUTLINE_FORMAT fuFormat, GLYPHMETRICS* lpgm, uint32 cjBuffer, void* pvBuffer, MAT2* lpmat2) => GetGlyphOutlineA(hdc, uChar, fuFormat, lpgm, cjBuffer, pvBuffer, lpmat2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetGlyphOutlineW(HDC hdc, uint32 uChar, GET_GLYPH_OUTLINE_FORMAT fuFormat, GLYPHMETRICS* lpgm, uint32 cjBuffer, void* pvBuffer, MAT2* lpmat2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetGraphicsMode(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC_MAP_MODE GetMapMode(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetMetaFileBitsEx(HMETAFILE hMF, uint32 cbBuffer, void* lpData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMETAFILE GetMetaFileA(PSTR lpName);
	public static HMETAFILE GetMetaFile(PSTR lpName) => GetMetaFileA(lpName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMETAFILE GetMetaFileW(PWSTR lpName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetNearestColor(HDC hdc, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetNearestPaletteIndex(HPALETTE h, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetObjectType(HGDIOBJ h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetOutlineTextMetricsA(HDC hdc, uint32 cjCopy, OUTLINETEXTMETRICA* potm);
	public static uint32 GetOutlineTextMetrics(HDC hdc, uint32 cjCopy, OUTLINETEXTMETRICA* potm) => GetOutlineTextMetricsA(hdc, cjCopy, potm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetOutlineTextMetricsW(HDC hdc, uint32 cjCopy, OUTLINETEXTMETRICW* potm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPaletteEntries(HPALETTE hpal, uint32 iStart, uint32 cEntries, PALETTEENTRY* pPalEntries);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetPixel(HDC hdc, int32 x, int32 y);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetPolyFillMode(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetRasterizerCaps(RASTERIZER_STATUS* lpraststat, uint32 cjBytes);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetRandomRgn(HDC hdc, HRGN hrgn, int32 i);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRegionData(HRGN hrgn, uint32 nCount, RGNDATA* lpRgnData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE GetRgnBox(HRGN hrgn, RECT* lprc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HGDIOBJ GetStockObject(GET_STOCK_OBJECT_FLAGS i);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetStretchBltMode(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemPaletteEntries(HDC hdc, uint32 iStart, uint32 cEntries, PALETTEENTRY* pPalEntries);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemPaletteUse(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTextCharacterExtra(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TEXT_ALIGN_OPTIONS GetTextAlign(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF GetTextColor(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentPointA(HDC hdc, uint8* lpString, int32 c, SIZE* lpsz);
	public static BOOL GetTextExtentPoint(HDC hdc, uint8* lpString, int32 c, SIZE* lpsz) => GetTextExtentPointA(hdc, lpString, c, lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentPointW(HDC hdc, char16* lpString, int32 c, SIZE* lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentPoint32A(HDC hdc, uint8* lpString, int32 c, SIZE* psizl);
	public static BOOL GetTextExtentPoint32(HDC hdc, uint8* lpString, int32 c, SIZE* psizl) => GetTextExtentPoint32A(hdc, lpString, c, psizl);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentPoint32W(HDC hdc, char16* lpString, int32 c, SIZE* psizl);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentExPointA(HDC hdc, uint8* lpszString, int32 cchString, int32 nMaxExtent, int32* lpnFit, int32* lpnDx, SIZE* lpSize);
	public static BOOL GetTextExtentExPoint(HDC hdc, uint8* lpszString, int32 cchString, int32 nMaxExtent, int32* lpnFit, int32* lpnDx, SIZE* lpSize) => GetTextExtentExPointA(hdc, lpszString, cchString, nMaxExtent, lpnFit, lpnDx, lpSize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentExPointW(HDC hdc, char16* lpszString, int32 cchString, int32 nMaxExtent, int32* lpnFit, int32* lpnDx, SIZE* lpSize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFontLanguageInfo(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCharacterPlacementA(HDC hdc, uint8* lpString, int32 nCount, int32 nMexExtent, GCP_RESULTSA* lpResults, GET_CHARACTER_PLACEMENT_FLAGS dwFlags);
	public static uint32 GetCharacterPlacement(HDC hdc, uint8* lpString, int32 nCount, int32 nMexExtent, GCP_RESULTSA* lpResults, GET_CHARACTER_PLACEMENT_FLAGS dwFlags) => GetCharacterPlacementA(hdc, lpString, nCount, nMexExtent, lpResults, dwFlags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCharacterPlacementW(HDC hdc, char16* lpString, int32 nCount, int32 nMexExtent, GCP_RESULTSW* lpResults, GET_CHARACTER_PLACEMENT_FLAGS dwFlags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFontUnicodeRanges(HDC hdc, GLYPHSET* lpgs);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetGlyphIndicesA(HDC hdc, uint8* lpstr, int32 c, uint16* pgi, uint32 fl);
	public static uint32 GetGlyphIndices(HDC hdc, uint8* lpstr, int32 c, uint16* pgi, uint32 fl) => GetGlyphIndicesA(hdc, lpstr, c, pgi, fl);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetGlyphIndicesW(HDC hdc, char16* lpstr, int32 c, uint16* pgi, uint32 fl);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentPointI(HDC hdc, uint16* pgiIn, int32 cgi, SIZE* psize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextExtentExPointI(HDC hdc, uint16* lpwszString, int32 cwchString, int32 nMaxExtent, int32* lpnFit, int32* lpnDx, SIZE* lpSize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharWidthI(HDC hdc, uint32 giFirst, uint32 cgi, uint16* pgi, int32* piWidths);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCharABCWidthsI(HDC hdc, uint32 giFirst, uint32 cgi, uint16* pgi, ABC* pabc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AddFontResourceExA(PSTR name, FONT_RESOURCE_CHARACTERISTICS fl, void* res);
	public static int32 AddFontResourceEx(PSTR name, FONT_RESOURCE_CHARACTERISTICS fl, void* res) => AddFontResourceExA(name, fl, res);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AddFontResourceExW(PWSTR name, FONT_RESOURCE_CHARACTERISTICS fl, void* res);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveFontResourceExA(PSTR name, uint32 fl, void* pdv);
	public static BOOL RemoveFontResourceEx(PSTR name, uint32 fl, void* pdv) => RemoveFontResourceExA(name, fl, pdv);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveFontResourceExW(PWSTR name, uint32 fl, void* pdv);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AddFontMemResourceEx(void* pFileView, uint32 cjSize, void* pvResrved, uint32* pNumFonts);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveFontMemResourceEx(HANDLE h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HFONT CreateFontIndirectExA(ENUMLOGFONTEXDVA* param0);
	public static HFONT CreateFontIndirectEx(ENUMLOGFONTEXDVA* param0) => CreateFontIndirectExA(param0);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HFONT CreateFontIndirectExW(ENUMLOGFONTEXDVW* param0);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetViewportExtEx(HDC hdc, SIZE* lpsize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetViewportOrgEx(HDC hdc, POINT* lppoint);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetWindowExtEx(HDC hdc, SIZE* lpsize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetWindowOrgEx(HDC hdc, POINT* lppoint);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE IntersectClipRect(HDC hdc, int32 left, int32 top, int32 right, int32 bottom);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InvertRgn(HDC hdc, HRGN hrgn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LineDDA(int32 xStart, int32 yStart, int32 xEnd, int32 yEnd, LINEDDAPROC lpProc, LPARAM data);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LineTo(HDC hdc, int32 x, int32 y);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MaskBlt(HDC hdcDest, int32 xDest, int32 yDest, int32 width, int32 height, HDC hdcSrc, int32 xSrc, int32 ySrc, HBITMAP hbmMask, int32 xMask, int32 yMask, uint32 rop);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PlgBlt(HDC hdcDest, POINT* lpPoint, HDC hdcSrc, int32 xSrc, int32 ySrc, int32 width, int32 height, HBITMAP hbmMask, int32 xMask, int32 yMask);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE OffsetClipRgn(HDC hdc, int32 x, int32 y);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE OffsetRgn(HRGN hrgn, int32 x, int32 y);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PatBlt(HDC hdc, int32 x, int32 y, int32 w, int32 h, ROP_CODE rop);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Pie(HDC hdc, int32 left, int32 top, int32 right, int32 bottom, int32 xr1, int32 yr1, int32 xr2, int32 yr2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PlayMetaFile(HDC hdc, HMETAFILE hmf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PaintRgn(HDC hdc, HRGN hrgn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyPolygon(HDC hdc, POINT* apt, int32* asz, int32 csz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PtInRegion(HRGN hrgn, int32 x, int32 y);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PtVisible(HDC hdc, int32 x, int32 y);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RectInRegion(HRGN hrgn, RECT* lprect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RectVisible(HDC hdc, RECT* lprect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Rectangle(HDC hdc, int32 left, int32 top, int32 right, int32 bottom);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RestoreDC(HDC hdc, int32 nSavedDC);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC ResetDCA(HDC hdc, DEVMODEA* lpdm);
	public static HDC ResetDC(HDC hdc, DEVMODEA* lpdm) => ResetDCA(hdc, lpdm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC ResetDCW(HDC hdc, DEVMODEW* lpdm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RealizePalette(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveFontResourceA(PSTR lpFileName);
	public static BOOL RemoveFontResource(PSTR lpFileName) => RemoveFontResourceA(lpFileName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveFontResourceW(PWSTR lpFileName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RoundRect(HDC hdc, int32 left, int32 top, int32 right, int32 bottom, int32 width, int32 height);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResizePalette(HPALETTE hpal, uint32 n);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SaveDC(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE SelectClipRgn(HDC hdc, HRGN hrgn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE ExtSelectClipRgn(HDC hdc, HRGN hrgn, RGN_COMBINE_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE SetMetaRgn(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HGDIOBJ SelectObject(HDC hdc, HGDIOBJ h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPALETTE SelectPalette(HDC hdc, HPALETTE hPal, BOOL bForceBkgd);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF SetBkColor(HDC hdc, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF SetDCBrushColor(HDC hdc, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF SetDCPenColor(HDC hdc, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetBkMode(HDC hdc, BACKGROUND_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetBitmapBits(HBITMAP hbm, uint32 cb, void* pvBits);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetBoundsRect(HDC hdc, RECT* lprect, SET_BOUNDS_RECT_FLAGS flags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetDIBits(HDC hdc, HBITMAP hbm, uint32 start, uint32 cLines, void* lpBits, BITMAPINFO* lpbmi, DIB_USAGE ColorUse);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetDIBitsToDevice(HDC hdc, int32 xDest, int32 yDest, uint32 w, uint32 h, int32 xSrc, int32 ySrc, uint32 StartScan, uint32 cLines, void* lpvBits, BITMAPINFO* lpbmi, DIB_USAGE ColorUse);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetMapperFlags(HDC hdc, uint32 flags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetGraphicsMode(HDC hdc, GRAPHICS_MODE iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetMapMode(HDC hdc, HDC_MAP_MODE iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetLayout(HDC hdc, DC_LAYOUT l);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLayout(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMETAFILE SetMetaFileBitsEx(uint32 cbBuffer, uint8* lpData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetPaletteEntries(HPALETTE hpal, uint32 iStart, uint32 cEntries, PALETTEENTRY* pPalEntries);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF SetPixel(HDC hdc, int32 x, int32 y, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPixelV(HDC hdc, int32 x, int32 y, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetPolyFillMode(HDC hdc, CREATE_POLYGON_RGN_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StretchBlt(HDC hdcDest, int32 xDest, int32 yDest, int32 wDest, int32 hDest, HDC hdcSrc, int32 xSrc, int32 ySrc, int32 wSrc, int32 hSrc, ROP_CODE rop);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetRectRgn(HRGN hrgn, int32 left, int32 top, int32 right, int32 bottom);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StretchDIBits(HDC hdc, int32 xDest, int32 yDest, int32 DestWidth, int32 DestHeight, int32 xSrc, int32 ySrc, int32 SrcWidth, int32 SrcHeight, void* lpBits, BITMAPINFO* lpbmi, DIB_USAGE iUsage, ROP_CODE rop);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetROP2(HDC hdc, R2_MODE rop2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetStretchBltMode(HDC hdc, STRETCH_BLT_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetSystemPaletteUse(HDC hdc, SYSTEM_PALETTE_USE use);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetTextCharacterExtra(HDC hdc, int32 extra);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF SetTextColor(HDC hdc, COLORREF color);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetTextAlign(HDC hdc, TEXT_ALIGN_OPTIONS align);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetTextJustification(HDC hdc, int32 extra, int32 count);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateColors(HDC hdc);

	[Import("MSIMG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AlphaBlend(HDC hdcDest, int32 xoriginDest, int32 yoriginDest, int32 wDest, int32 hDest, HDC hdcSrc, int32 xoriginSrc, int32 yoriginSrc, int32 wSrc, int32 hSrc, BLENDFUNCTION ftn);

	[Import("MSIMG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TransparentBlt(HDC hdcDest, int32 xoriginDest, int32 yoriginDest, int32 wDest, int32 hDest, HDC hdcSrc, int32 xoriginSrc, int32 yoriginSrc, int32 wSrc, int32 hSrc, uint32 crTransparent);

	[Import("MSIMG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GradientFill(HDC hdc, TRIVERTEX* pVertex, uint32 nVertex, void* pMesh, uint32 nMesh, GRADIENT_FILL ulMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiAlphaBlend(HDC hdcDest, int32 xoriginDest, int32 yoriginDest, int32 wDest, int32 hDest, HDC hdcSrc, int32 xoriginSrc, int32 yoriginSrc, int32 wSrc, int32 hSrc, BLENDFUNCTION ftn);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiTransparentBlt(HDC hdcDest, int32 xoriginDest, int32 yoriginDest, int32 wDest, int32 hDest, HDC hdcSrc, int32 xoriginSrc, int32 yoriginSrc, int32 wSrc, int32 hSrc, uint32 crTransparent);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiGradientFill(HDC hdc, TRIVERTEX* pVertex, uint32 nVertex, void* pMesh, uint32 nCount, GRADIENT_FILL ulMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PlayMetaFileRecord(HDC hdc, HANDLETABLE* lpHandleTable, METARECORD* lpMR, uint32 noObjs);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumMetaFile(HDC hdc, HMETAFILE hmf, MFENUMPROC proc, LPARAM param3);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE CloseEnhMetaFile(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE CopyEnhMetaFileA(HENHMETAFILE hEnh, PSTR lpFileName);
	public static HENHMETAFILE CopyEnhMetaFile(HENHMETAFILE hEnh, PSTR lpFileName) => CopyEnhMetaFileA(hEnh, lpFileName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE CopyEnhMetaFileW(HENHMETAFILE hEnh, PWSTR lpFileName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HdcMetdataEnhFileHandle CreateEnhMetaFileA(HDC hdc, PSTR lpFilename, RECT* lprc, PSTR lpDesc);
	public static HdcMetdataEnhFileHandle CreateEnhMetaFile(HDC hdc, PSTR lpFilename, RECT* lprc, PSTR lpDesc) => CreateEnhMetaFileA(hdc, lpFilename, lprc, lpDesc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HdcMetdataEnhFileHandle CreateEnhMetaFileW(HDC hdc, PWSTR lpFilename, RECT* lprc, PWSTR lpDesc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteEnhMetaFile(HENHMETAFILE hmf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumEnhMetaFile(HDC hdc, HENHMETAFILE hmf, ENHMFENUMPROC proc, void* param3, RECT* lpRect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE GetEnhMetaFileA(PSTR lpName);
	public static HENHMETAFILE GetEnhMetaFile(PSTR lpName) => GetEnhMetaFileA(lpName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE GetEnhMetaFileW(PWSTR lpName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnhMetaFileBits(HENHMETAFILE hEMF, uint32 nSize, uint8* lpData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnhMetaFileDescriptionA(HENHMETAFILE hemf, uint32 cchBuffer, uint8* lpDescription);
	public static uint32 GetEnhMetaFileDescription(HENHMETAFILE hemf, uint32 cchBuffer, uint8* lpDescription) => GetEnhMetaFileDescriptionA(hemf, cchBuffer, lpDescription);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnhMetaFileDescriptionW(HENHMETAFILE hemf, uint32 cchBuffer, char16* lpDescription);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnhMetaFileHeader(HENHMETAFILE hemf, uint32 nSize, ENHMETAHEADER* lpEnhMetaHeader);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnhMetaFilePaletteEntries(HENHMETAFILE hemf, uint32 nNumEntries, PALETTEENTRY* lpPaletteEntries);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetWinMetaFileBits(HENHMETAFILE hemf, uint32 cbData16, uint8* pData16, int32 iMapMode, HDC hdcRef);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PlayEnhMetaFile(HDC hdc, HENHMETAFILE hmf, RECT* lprect);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PlayEnhMetaFileRecord(HDC hdc, HANDLETABLE* pht, ENHMETARECORD* pmr, uint32 cht);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE SetEnhMetaFileBits(uint32 nSize, uint8* pb);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiComment(HDC hdc, uint32 nSize, uint8* lpData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextMetricsA(HDC hdc, TEXTMETRICA* lptm);
	public static BOOL GetTextMetrics(HDC hdc, TEXTMETRICA* lptm) => GetTextMetricsA(hdc, lptm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTextMetricsW(HDC hdc, TEXTMETRICW* lptm);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AngleArc(HDC hdc, int32 x, int32 y, uint32 r, float StartAngle, float SweepAngle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyPolyline(HDC hdc, POINT* apt, uint32* asz, uint32 csz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetWorldTransform(HDC hdc, XFORM* lpxf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWorldTransform(HDC hdc, XFORM* lpxf);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ModifyWorldTransform(HDC hdc, XFORM* lpxf, MODIFY_WORLD_TRANSFORM_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CombineTransform(XFORM* lpxfOut, XFORM* lpxf1, XFORM* lpxf2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP CreateDIBSection(HDC hdc, BITMAPINFO* pbmi, DIB_USAGE usage, void** ppvBits, HANDLE hSection, uint32 offset);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDIBColorTable(HDC hdc, uint32 iStart, uint32 cEntries, RGBQUAD* prgbq);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetDIBColorTable(HDC hdc, uint32 iStart, uint32 cEntries, RGBQUAD* prgbq);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetColorAdjustment(HDC hdc, COLORADJUSTMENT* lpca);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorAdjustment(HDC hdc, COLORADJUSTMENT* lpca);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPALETTE CreateHalftonePalette(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AbortPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ArcTo(HDC hdc, int32 left, int32 top, int32 right, int32 bottom, int32 xr1, int32 yr1, int32 xr2, int32 yr2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BeginPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseFigure(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FillPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlattenPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetPath(HDC hdc, POINT* apt, uint8* aj, int32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN PathToRegion(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyDraw(HDC hdc, POINT* apt, uint8* aj, int32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SelectClipPath(HDC hdc, RGN_COMBINE_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetArcDirection(HDC hdc, ARC_DIRECTION dir);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetMiterLimit(HDC hdc, float limit, float* old);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrokeAndFillPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrokePath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WidenPath(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPEN ExtCreatePen(PEN_STYLE iPenStyle, uint32 cWidth, LOGBRUSH* plbrush, uint32 cStyle, uint32* pstyle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetMiterLimit(HDC hdc, float* plimit);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetArcDirection(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetObjectW(HGDIOBJ h, int32 c, void* pv);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveToEx(HDC hdc, int32 x, int32 y, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TextOutA(HDC hdc, int32 x, int32 y, uint8* lpString, int32 c);
	public static BOOL TextOut(HDC hdc, int32 x, int32 y, uint8* lpString, int32 c) => TextOutA(hdc, x, y, lpString, c);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TextOutW(HDC hdc, int32 x, int32 y, char16* lpString, int32 c);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExtTextOutA(HDC hdc, int32 x, int32 y, ETO_OPTIONS options, RECT* lprect, uint8* lpString, uint32 c, int32* lpDx);
	public static BOOL ExtTextOut(HDC hdc, int32 x, int32 y, ETO_OPTIONS options, RECT* lprect, uint8* lpString, uint32 c, int32* lpDx) => ExtTextOutA(hdc, x, y, options, lprect, lpString, c, lpDx);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExtTextOutW(HDC hdc, int32 x, int32 y, ETO_OPTIONS options, RECT* lprect, char16* lpString, uint32 c, int32* lpDx);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyTextOutA(HDC hdc, POLYTEXTA* ppt, int32 nstrings);
	public static BOOL PolyTextOut(HDC hdc, POLYTEXTA* ppt, int32 nstrings) => PolyTextOutA(hdc, ppt, nstrings);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyTextOutW(HDC hdc, POLYTEXTW* ppt, int32 nstrings);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRGN CreatePolygonRgn(POINT* pptl, int32 cPoint, CREATE_POLYGON_RGN_MODE iMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DPtoLP(HDC hdc, POINT* lppt, int32 c);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LPtoDP(HDC hdc, POINT* lppt, int32 c);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Polygon(HDC hdc, POINT* apt, int32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Polyline(HDC hdc, POINT* apt, int32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyBezier(HDC hdc, POINT* apt, uint32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolyBezierTo(HDC hdc, POINT* apt, uint32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PolylineTo(HDC hdc, POINT* apt, uint32 cpt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetViewportExtEx(HDC hdc, int32 x, int32 y, SIZE* lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetViewportOrgEx(HDC hdc, int32 x, int32 y, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWindowExtEx(HDC hdc, int32 x, int32 y, SIZE* lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWindowOrgEx(HDC hdc, int32 x, int32 y, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OffsetViewportOrgEx(HDC hdc, int32 x, int32 y, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OffsetWindowOrgEx(HDC hdc, int32 x, int32 y, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScaleViewportExtEx(HDC hdc, int32 xn, int32 dx, int32 yn, int32 yd, SIZE* lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScaleWindowExtEx(HDC hdc, int32 xn, int32 xd, int32 yn, int32 yd, SIZE* lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetBitmapDimensionEx(HBITMAP hbm, int32 w, int32 h, SIZE* lpsz);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetBrushOrgEx(HDC hdc, int32 x, int32 y, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTextFaceA(HDC hdc, int32 c, uint8* lpName);
	public static int32 GetTextFace(HDC hdc, int32 c, uint8* lpName) => GetTextFaceA(hdc, c, lpName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTextFaceW(HDC hdc, int32 c, char16* lpName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetKerningPairsA(HDC hdc, uint32 nPairs, KERNINGPAIR* lpKernPair);
	public static uint32 GetKerningPairs(HDC hdc, uint32 nPairs, KERNINGPAIR* lpKernPair) => GetKerningPairsA(hdc, nPairs, lpKernPair);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetKerningPairsW(HDC hdc, uint32 nPairs, KERNINGPAIR* lpKernPair);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDCOrgEx(HDC hdc, POINT* lppt);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FixBrushOrgEx(HDC hdc, int32 x, int32 y, POINT* ptl);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnrealizeObject(HGDIOBJ h);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiFlush();

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GdiSetBatchLimit(uint32 dw);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GdiGetBatchLimit();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 wglSwapMultipleBuffers(uint32 param0, WGLSWAP* param1);

	[Import("FONTSUB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CreateFontPackage(uint8* puchSrcBuffer, uint32 ulSrcBufferSize, uint8** ppuchFontPackageBuffer, uint32* pulFontPackageBufferSize, uint32* pulBytesWritten, uint16 usFlag, uint16 usTTCIndex, uint16 usSubsetFormat, uint16 usSubsetLanguage, CREATE_FONT_PACKAGE_SUBSET_PLATFORM usSubsetPlatform, CREATE_FONT_PACKAGE_SUBSET_ENCODING usSubsetEncoding, uint16* pusSubsetKeepList, uint16 usSubsetListCount, CFP_ALLOCPROC lpfnAllocate, CFP_REALLOCPROC lpfnReAllocate, CFP_FREEPROC lpfnFree, void* lpvReserved);

	[Import("FONTSUB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MergeFontPackage(uint8* puchMergeFontBuffer, uint32 ulMergeFontBufferSize, uint8* puchFontPackageBuffer, uint32 ulFontPackageBufferSize, uint8** ppuchDestBuffer, uint32* pulDestBufferSize, uint32* pulBytesWritten, uint16 usMode, CFP_ALLOCPROC lpfnAllocate, CFP_REALLOCPROC lpfnReAllocate, CFP_FREEPROC lpfnFree, void* lpvReserved);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTEmbedFont(HDC hDC, TTEMBED_FLAGS ulFlags, EMBED_FONT_CHARSET ulCharSet, EMBEDDED_FONT_PRIV_STATUS* pulPrivStatus, uint32* pulStatus, WRITEEMBEDPROC lpfnWriteToStream, void* lpvWriteStream, uint16* pusCharCodeSet, uint16 usCharCodeCount, uint16 usLanguage, TTEMBEDINFO* pTTEmbedInfo);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTEmbedFontFromFileA(HDC hDC, PSTR szFontFileName, uint16 usTTCIndex, TTEMBED_FLAGS ulFlags, EMBED_FONT_CHARSET ulCharSet, EMBEDDED_FONT_PRIV_STATUS* pulPrivStatus, uint32* pulStatus, WRITEEMBEDPROC lpfnWriteToStream, void* lpvWriteStream, uint16* pusCharCodeSet, uint16 usCharCodeCount, uint16 usLanguage, TTEMBEDINFO* pTTEmbedInfo);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTLoadEmbeddedFont(HANDLE* phFontReference, uint32 ulFlags, EMBEDDED_FONT_PRIV_STATUS* pulPrivStatus, FONT_LICENSE_PRIVS ulPrivs, TTLOAD_EMBEDDED_FONT_STATUS* pulStatus, READEMBEDPROC lpfnReadFromStream, void* lpvReadStream, PWSTR szWinFamilyName, PSTR szMacFamilyName, TTLOADINFO* pTTLoadInfo);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTGetEmbeddedFontInfo(TTEMBED_FLAGS ulFlags, uint32* pulPrivStatus, FONT_LICENSE_PRIVS ulPrivs, uint32* pulStatus, READEMBEDPROC lpfnReadFromStream, void* lpvReadStream, TTLOADINFO* pTTLoadInfo);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTDeleteEmbeddedFont(HANDLE hFontReference, uint32 ulFlags, uint32* pulStatus);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTGetEmbeddingType(HDC hDC, EMBEDDED_FONT_PRIV_STATUS* pulEmbedType);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTCharToUnicode(HDC hDC, uint8* pucCharCodes, uint32 ulCharCodeSize, uint16* pusShortCodes, uint32 ulShortCodeSize, uint32 ulFlags);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTRunValidationTests(HDC hDC, TTVALIDATIONTESTSPARAMS* pTestParam);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTIsEmbeddingEnabled(HDC hDC, BOOL* pbEnabled);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTIsEmbeddingEnabledForFacename(PSTR lpszFacename, BOOL* pbEnabled);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTEnableEmbeddingForFacename(PSTR lpszFacename, BOOL bEnable);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTEmbedFontEx(HDC hDC, TTEMBED_FLAGS ulFlags, EMBED_FONT_CHARSET ulCharSet, EMBEDDED_FONT_PRIV_STATUS* pulPrivStatus, uint32* pulStatus, WRITEEMBEDPROC lpfnWriteToStream, void* lpvWriteStream, uint32* pulCharCodeSet, uint16 usCharCodeCount, uint16 usLanguage, TTEMBEDINFO* pTTEmbedInfo);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTRunValidationTestsEx(HDC hDC, TTVALIDATIONTESTSPARAMSEX* pTestParam);

	[Import("t2embed.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TTGetNewFontName(HANDLE* phFontReference, char16* wzWinFamilyName, int32 cchMaxWinName, uint8* szMacFamilyName, int32 cchMaxMacName);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawEdge(HDC hdc, RECT* qrc, DRAWEDGE_FLAGS edge, DRAW_EDGE_FLAGS grfFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawFrameControl(HDC param0, RECT* param1, DFC_TYPE param2, DFCS_STATE param3);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawCaption(HWND hwnd, HDC hdc, RECT* lprect, DRAW_CAPTION_FLAGS flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawAnimatedRects(HWND hwnd, int32 idAni, RECT* lprcFrom, RECT* lprcTo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DrawTextA(HDC hdc, uint8* lpchText, int32 cchText, RECT* lprc, DRAW_TEXT_FORMAT format);
	public static int32 DrawText(HDC hdc, uint8* lpchText, int32 cchText, RECT* lprc, DRAW_TEXT_FORMAT format) => DrawTextA(hdc, lpchText, cchText, lprc, format);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DrawTextW(HDC hdc, char16* lpchText, int32 cchText, RECT* lprc, DRAW_TEXT_FORMAT format);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DrawTextExA(HDC hdc, uint8* lpchText, int32 cchText, RECT* lprc, DRAW_TEXT_FORMAT format, DRAWTEXTPARAMS* lpdtp);
	public static int32 DrawTextEx(HDC hdc, uint8* lpchText, int32 cchText, RECT* lprc, DRAW_TEXT_FORMAT format, DRAWTEXTPARAMS* lpdtp) => DrawTextExA(hdc, lpchText, cchText, lprc, format, lpdtp);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DrawTextExW(HDC hdc, char16* lpchText, int32 cchText, RECT* lprc, DRAW_TEXT_FORMAT format, DRAWTEXTPARAMS* lpdtp);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GrayStringA(HDC hDC, HBRUSH hBrush, GRAYSTRINGPROC lpOutputFunc, LPARAM lpData, int32 nCount, int32 X, int32 Y, int32 nWidth, int32 nHeight);
	public static BOOL GrayString(HDC hDC, HBRUSH hBrush, GRAYSTRINGPROC lpOutputFunc, LPARAM lpData, int32 nCount, int32 X, int32 Y, int32 nWidth, int32 nHeight) => GrayStringA(hDC, hBrush, lpOutputFunc, lpData, nCount, X, Y, nWidth, nHeight);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GrayStringW(HDC hDC, HBRUSH hBrush, GRAYSTRINGPROC lpOutputFunc, LPARAM lpData, int32 nCount, int32 X, int32 Y, int32 nWidth, int32 nHeight);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawStateA(HDC hdc, HBRUSH hbrFore, DRAWSTATEPROC qfnCallBack, LPARAM lData, WPARAM wData, int32 x, int32 y, int32 cx, int32 cy, DRAWSTATE_FLAGS uFlags);
	public static BOOL DrawState(HDC hdc, HBRUSH hbrFore, DRAWSTATEPROC qfnCallBack, LPARAM lData, WPARAM wData, int32 x, int32 y, int32 cx, int32 cy, DRAWSTATE_FLAGS uFlags) => DrawStateA(hdc, hbrFore, qfnCallBack, lData, wData, x, y, cx, cy, uFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawStateW(HDC hdc, HBRUSH hbrFore, DRAWSTATEPROC qfnCallBack, LPARAM lData, WPARAM wData, int32 x, int32 y, int32 cx, int32 cy, DRAWSTATE_FLAGS uFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TabbedTextOutA(HDC hdc, int32 x, int32 y, uint8* lpString, int32 chCount, int32 nTabPositions, int32* lpnTabStopPositions, int32 nTabOrigin);
	public static int32 TabbedTextOut(HDC hdc, int32 x, int32 y, uint8* lpString, int32 chCount, int32 nTabPositions, int32* lpnTabStopPositions, int32 nTabOrigin) => TabbedTextOutA(hdc, x, y, lpString, chCount, nTabPositions, lpnTabStopPositions, nTabOrigin);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 TabbedTextOutW(HDC hdc, int32 x, int32 y, char16* lpString, int32 chCount, int32 nTabPositions, int32* lpnTabStopPositions, int32 nTabOrigin);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTabbedTextExtentA(HDC hdc, uint8* lpString, int32 chCount, int32 nTabPositions, int32* lpnTabStopPositions);
	public static uint32 GetTabbedTextExtent(HDC hdc, uint8* lpString, int32 chCount, int32 nTabPositions, int32* lpnTabStopPositions) => GetTabbedTextExtentA(hdc, lpString, chCount, nTabPositions, lpnTabStopPositions);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTabbedTextExtentW(HDC hdc, char16* lpString, int32 chCount, int32 nTabPositions, int32* lpnTabStopPositions);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateWindow(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PaintDesktop(HDC hdc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND WindowFromDC(HDC hDC);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC GetDC(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC GetDCEx(HWND hWnd, HRGN hrgnClip, GET_DCX_FLAGS flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC GetWindowDC(HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ReleaseDC(HWND hWnd, HDC hDC);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC BeginPaint(HWND hWnd, PAINTSTRUCT* lpPaint);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndPaint(HWND hWnd, PAINTSTRUCT* lpPaint);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUpdateRect(HWND hWnd, RECT* lpRect, BOOL bErase);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE GetUpdateRgn(HWND hWnd, HRGN hRgn, BOOL bErase);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetWindowRgn(HWND hWnd, HRGN hRgn, BOOL bRedraw);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE GetWindowRgn(HWND hWnd, HRGN hRgn);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GDI_REGION_TYPE GetWindowRgnBox(HWND hWnd, RECT* lprc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ExcludeUpdateRgn(HDC hDC, HWND hWnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InvalidateRect(HWND hWnd, RECT* lpRect, BOOL bErase);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ValidateRect(HWND hWnd, RECT* lpRect);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InvalidateRgn(HWND hWnd, HRGN hRgn, BOOL bErase);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ValidateRgn(HWND hWnd, HRGN hRgn);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RedrawWindow(HWND hWnd, RECT* lprcUpdate, HRGN hrgnUpdate, REDRAW_WINDOW_FLAGS flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LockWindowUpdate(HWND hWndLock);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClientToScreen(HWND hWnd, POINT* lpPoint);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScreenToClient(HWND hWnd, POINT* lpPoint);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 MapWindowPoints(HWND hWndFrom, HWND hWndTo, POINT* lpPoints, uint32 cPoints);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSysColor(SYS_COLOR_INDEX nIndex);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBRUSH GetSysColorBrush(SYS_COLOR_INDEX nIndex);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSysColors(int32 cElements, int32* lpaElements, COLORREF* lpaRgbValues);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DrawFocusRect(HDC hDC, RECT* lprc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FillRect(HDC hDC, RECT* lprc, HBRUSH hbr);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FrameRect(HDC hDC, RECT* lprc, HBRUSH hbr);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InvertRect(HDC hDC, RECT* lprc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetRect(RECT* lprc, int32 xLeft, int32 yTop, int32 xRight, int32 yBottom);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetRectEmpty(RECT* lprc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyRect(RECT* lprcDst, RECT* lprcSrc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InflateRect(RECT* lprc, int32 dx, int32 dy);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IntersectRect(RECT* lprcDst, RECT* lprcSrc1, RECT* lprcSrc2);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnionRect(RECT* lprcDst, RECT* lprcSrc1, RECT* lprcSrc2);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SubtractRect(RECT* lprcDst, RECT* lprcSrc1, RECT* lprcSrc2);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OffsetRect(RECT* lprc, int32 dx, int32 dy);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsRectEmpty(RECT* lprc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EqualRect(RECT* lprc1, RECT* lprc2);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PtInRect(RECT* lprc, POINT pt);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP LoadBitmapA(HINSTANCE hInstance, PSTR lpBitmapName);
	public static HBITMAP LoadBitmap(HINSTANCE hInstance, PSTR lpBitmapName) => LoadBitmapA(hInstance, lpBitmapName);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HBITMAP LoadBitmapW(HINSTANCE hInstance, PWSTR lpBitmapName);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DISP_CHANGE ChangeDisplaySettingsA(DEVMODEA* lpDevMode, CDS_TYPE dwFlags);
	public static DISP_CHANGE ChangeDisplaySettings(DEVMODEA* lpDevMode, CDS_TYPE dwFlags) => ChangeDisplaySettingsA(lpDevMode, dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DISP_CHANGE ChangeDisplaySettingsW(DEVMODEW* lpDevMode, CDS_TYPE dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DISP_CHANGE ChangeDisplaySettingsExA(PSTR lpszDeviceName, DEVMODEA* lpDevMode, HWND hwnd, CDS_TYPE dwflags, void* lParam);
	public static DISP_CHANGE ChangeDisplaySettingsEx(PSTR lpszDeviceName, DEVMODEA* lpDevMode, HWND hwnd, CDS_TYPE dwflags, void* lParam) => ChangeDisplaySettingsExA(lpszDeviceName, lpDevMode, hwnd, dwflags, lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DISP_CHANGE ChangeDisplaySettingsExW(PWSTR lpszDeviceName, DEVMODEW* lpDevMode, HWND hwnd, CDS_TYPE dwflags, void* lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplaySettingsA(PSTR lpszDeviceName, ENUM_DISPLAY_SETTINGS_MODE iModeNum, DEVMODEA* lpDevMode);
	public static BOOL EnumDisplaySettings(PSTR lpszDeviceName, ENUM_DISPLAY_SETTINGS_MODE iModeNum, DEVMODEA* lpDevMode) => EnumDisplaySettingsA(lpszDeviceName, iModeNum, lpDevMode);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplaySettingsW(PWSTR lpszDeviceName, ENUM_DISPLAY_SETTINGS_MODE iModeNum, DEVMODEW* lpDevMode);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplaySettingsExA(PSTR lpszDeviceName, ENUM_DISPLAY_SETTINGS_MODE iModeNum, DEVMODEA* lpDevMode, uint32 dwFlags);
	public static BOOL EnumDisplaySettingsEx(PSTR lpszDeviceName, ENUM_DISPLAY_SETTINGS_MODE iModeNum, DEVMODEA* lpDevMode, uint32 dwFlags) => EnumDisplaySettingsExA(lpszDeviceName, iModeNum, lpDevMode, dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplaySettingsExW(PWSTR lpszDeviceName, ENUM_DISPLAY_SETTINGS_MODE iModeNum, DEVMODEW* lpDevMode, uint32 dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplayDevicesA(PSTR lpDevice, uint32 iDevNum, DISPLAY_DEVICEA* lpDisplayDevice, uint32 dwFlags);
	public static BOOL EnumDisplayDevices(PSTR lpDevice, uint32 iDevNum, DISPLAY_DEVICEA* lpDisplayDevice, uint32 dwFlags) => EnumDisplayDevicesA(lpDevice, iDevNum, lpDisplayDevice, dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplayDevicesW(PWSTR lpDevice, uint32 iDevNum, DISPLAY_DEVICEW* lpDisplayDevice, uint32 dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMONITOR MonitorFromPoint(POINT pt, MONITOR_FROM_FLAGS dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMONITOR MonitorFromRect(RECT* lprc, MONITOR_FROM_FLAGS dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HMONITOR MonitorFromWindow(HWND hwnd, MONITOR_FROM_FLAGS dwFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetMonitorInfoA(HMONITOR hMonitor, MONITORINFO* lpmi);
	public static BOOL GetMonitorInfo(HMONITOR hMonitor, MONITORINFO* lpmi) => GetMonitorInfoA(hMonitor, lpmi);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetMonitorInfoW(HMONITOR hMonitor, MONITORINFO* lpmi);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDisplayMonitors(HDC hdc, RECT* lprcClip, MONITORENUMPROC lpfnEnum, LPARAM dwData);

}
#endregion
