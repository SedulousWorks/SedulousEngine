using Win32.Foundation;
using Win32.UI.Controls;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using System;

namespace Win32.UI.Controls.Dialogs;

#region Constants
public static
{
	public const uint32 OFN_SHAREFALLTHROUGH = 2;
	public const uint32 OFN_SHARENOWARN = 1;
	public const uint32 OFN_SHAREWARN = 0;
	public const uint32 CDM_FIRST = 1124;
	public const uint32 CDM_LAST = 1224;
	public const uint32 CDM_GETSPEC = 1124;
	public const uint32 CDM_GETFILEPATH = 1125;
	public const uint32 CDM_GETFOLDERPATH = 1126;
	public const uint32 CDM_GETFOLDERIDLIST = 1127;
	public const uint32 CDM_SETCONTROLTEXT = 1128;
	public const uint32 CDM_HIDECONTROL = 1129;
	public const uint32 CDM_SETDEFEXT = 1130;
	public const uint32 FR_RAW = 131072;
	public const uint32 FR_SHOWWRAPAROUND = 262144;
	public const uint32 FR_NOWRAPAROUND = 524288;
	public const uint32 FR_WRAPAROUND = 1048576;
	public const uint32 FRM_FIRST = 1124;
	public const uint32 FRM_LAST = 1224;
	public const uint32 FRM_SETOPERATIONRESULT = 1124;
	public const uint32 FRM_SETOPERATIONRESULTTEXT = 1125;
	public const uint32 PS_OPENTYPE_FONTTYPE = 65536;
	public const uint32 TT_OPENTYPE_FONTTYPE = 131072;
	public const uint32 TYPE1_FONTTYPE = 262144;
	public const uint32 SYMBOL_FONTTYPE = 524288;
	public const uint32 WM_CHOOSEFONT_GETLOGFONT = 1025;
	public const uint32 WM_CHOOSEFONT_SETLOGFONT = 1125;
	public const uint32 WM_CHOOSEFONT_SETFLAGS = 1126;
	public const String LBSELCHSTRINGA = "commdlg_LBSelChangedNotify";
	public const String SHAREVISTRINGA = "commdlg_ShareViolation";
	public const String FILEOKSTRINGA = "commdlg_FileNameOK";
	public const String COLOROKSTRINGA = "commdlg_ColorOK";
	public const String SETRGBSTRINGA = "commdlg_SetRGBColor";
	public const String HELPMSGSTRINGA = "commdlg_help";
	public const String FINDMSGSTRINGA = "commdlg_FindReplace";
	public const String LBSELCHSTRINGW = "commdlg_LBSelChangedNotify";
	public const String SHAREVISTRINGW = "commdlg_ShareViolation";
	public const String FILEOKSTRINGW = "commdlg_FileNameOK";
	public const String COLOROKSTRINGW = "commdlg_ColorOK";
	public const String SETRGBSTRINGW = "commdlg_SetRGBColor";
	public const String HELPMSGSTRINGW = "commdlg_help";
	public const String FINDMSGSTRINGW = "commdlg_FindReplace";
	public const String LBSELCHSTRING = "commdlg_LBSelChangedNotify";
	public const String SHAREVISTRING = "commdlg_ShareViolation";
	public const String FILEOKSTRING = "commdlg_FileNameOK";
	public const String COLOROKSTRING = "commdlg_ColorOK";
	public const String SETRGBSTRING = "commdlg_SetRGBColor";
	public const String HELPMSGSTRING = "commdlg_help";
	public const String FINDMSGSTRING = "commdlg_FindReplace";
	public const int32 CD_LBSELNOITEMS = -1;
	public const uint32 CD_LBSELCHANGE = 0;
	public const uint32 CD_LBSELSUB = 1;
	public const uint32 CD_LBSELADD = 2;
	public const uint32 START_PAGE_GENERAL = 4294967295;
	public const uint32 PD_RESULT_CANCEL = 0;
	public const uint32 PD_RESULT_PRINT = 1;
	public const uint32 PD_RESULT_APPLY = 2;
	public const uint32 DN_DEFAULTPRN = 1;
	public const uint32 WM_PSD_FULLPAGERECT = 1025;
	public const uint32 WM_PSD_MINMARGINRECT = 1026;
	public const uint32 WM_PSD_MARGINRECT = 1027;
	public const uint32 WM_PSD_GREEKTEXTRECT = 1028;
	public const uint32 WM_PSD_ENVSTAMPRECT = 1029;
	public const uint32 WM_PSD_YAFULLPAGERECT = 1030;
	public const uint32 DLG_COLOR = 10;
	public const uint32 COLOR_HUESCROLL = 700;
	public const uint32 COLOR_SATSCROLL = 701;
	public const uint32 COLOR_LUMSCROLL = 702;
	public const uint32 COLOR_HUE = 703;
	public const uint32 COLOR_SAT = 704;
	public const uint32 COLOR_LUM = 705;
	public const uint32 COLOR_RED = 706;
	public const uint32 COLOR_GREEN = 707;
	public const uint32 COLOR_BLUE = 708;
	public const uint32 COLOR_CURRENT = 709;
	public const uint32 COLOR_RAINBOW = 710;
	public const uint32 COLOR_SAVE = 711;
	public const uint32 COLOR_ADD = 712;
	public const uint32 COLOR_SOLID = 713;
	public const uint32 COLOR_TUNE = 714;
	public const uint32 COLOR_SCHEMES = 715;
	public const uint32 COLOR_ELEMENT = 716;
	public const uint32 COLOR_SAMPLES = 717;
	public const uint32 COLOR_PALETTE = 718;
	public const uint32 COLOR_MIX = 719;
	public const uint32 COLOR_BOX1 = 720;
	public const uint32 COLOR_CUSTOM1 = 721;
	public const uint32 COLOR_HUEACCEL = 723;
	public const uint32 COLOR_SATACCEL = 724;
	public const uint32 COLOR_LUMACCEL = 725;
	public const uint32 COLOR_REDACCEL = 726;
	public const uint32 COLOR_GREENACCEL = 727;
	public const uint32 COLOR_BLUEACCEL = 728;
	public const uint32 COLOR_SOLID_LEFT = 730;
	public const uint32 COLOR_SOLID_RIGHT = 731;
	public const uint32 NUM_BASIC_COLORS = 48;
	public const uint32 NUM_CUSTOM_COLORS = 16;
}
#endregion

#region Enums

[AllowDuplicates]
public enum COMMON_DLG_ERRORS : uint32
{
	CDERR_DIALOGFAILURE = 65535,
	CDERR_GENERALCODES = 0,
	CDERR_STRUCTSIZE = 1,
	CDERR_INITIALIZATION = 2,
	CDERR_NOTEMPLATE = 3,
	CDERR_NOHINSTANCE = 4,
	CDERR_LOADSTRFAILURE = 5,
	CDERR_FINDRESFAILURE = 6,
	CDERR_LOADRESFAILURE = 7,
	CDERR_LOCKRESFAILURE = 8,
	CDERR_MEMALLOCFAILURE = 9,
	CDERR_MEMLOCKFAILURE = 10,
	CDERR_NOHOOK = 11,
	CDERR_REGISTERMSGFAIL = 12,
	PDERR_PRINTERCODES = 4096,
	PDERR_SETUPFAILURE = 4097,
	PDERR_PARSEFAILURE = 4098,
	PDERR_RETDEFFAILURE = 4099,
	PDERR_LOADDRVFAILURE = 4100,
	PDERR_GETDEVMODEFAIL = 4101,
	PDERR_INITFAILURE = 4102,
	PDERR_NODEVICES = 4103,
	PDERR_NODEFAULTPRN = 4104,
	PDERR_DNDMMISMATCH = 4105,
	PDERR_CREATEICFAILURE = 4106,
	PDERR_PRINTERNOTFOUND = 4107,
	PDERR_DEFAULTDIFFERENT = 4108,
	CFERR_CHOOSEFONTCODES = 8192,
	CFERR_NOFONTS = 8193,
	CFERR_MAXLESSTHANMIN = 8194,
	FNERR_FILENAMECODES = 12288,
	FNERR_SUBCLASSFAILURE = 12289,
	FNERR_INVALIDFILENAME = 12290,
	FNERR_BUFFERTOOSMALL = 12291,
	FRERR_FINDREPLACECODES = 16384,
	FRERR_BUFFERLENGTHZERO = 16385,
	CCERR_CHOOSECOLORCODES = 20480,
}


[AllowDuplicates]
public enum CHOOSECOLOR_FLAGS : uint32
{
	CC_RGBINIT = 1,
	CC_FULLOPEN = 2,
	CC_PREVENTFULLOPEN = 4,
	CC_SHOWHELP = 8,
	CC_ENABLEHOOK = 16,
	CC_ENABLETEMPLATE = 32,
	CC_ENABLETEMPLATEHANDLE = 64,
	CC_SOLIDCOLOR = 128,
	CC_ANYCOLOR = 256,
}


[AllowDuplicates]
public enum OPEN_FILENAME_FLAGS : uint32
{
	OFN_READONLY = 1,
	OFN_OVERWRITEPROMPT = 2,
	OFN_HIDEREADONLY = 4,
	OFN_NOCHANGEDIR = 8,
	OFN_SHOWHELP = 16,
	OFN_ENABLEHOOK = 32,
	OFN_ENABLETEMPLATE = 64,
	OFN_ENABLETEMPLATEHANDLE = 128,
	OFN_NOVALIDATE = 256,
	OFN_ALLOWMULTISELECT = 512,
	OFN_EXTENSIONDIFFERENT = 1024,
	OFN_PATHMUSTEXIST = 2048,
	OFN_FILEMUSTEXIST = 4096,
	OFN_CREATEPROMPT = 8192,
	OFN_SHAREAWARE = 16384,
	OFN_NOREADONLYRETURN = 32768,
	OFN_NOTESTFILECREATE = 65536,
	OFN_NONETWORKBUTTON = 131072,
	OFN_NOLONGNAMES = 262144,
	OFN_EXPLORER = 524288,
	OFN_NODEREFERENCELINKS = 1048576,
	OFN_LONGNAMES = 2097152,
	OFN_ENABLEINCLUDENOTIFY = 4194304,
	OFN_ENABLESIZING = 8388608,
	OFN_DONTADDTORECENT = 33554432,
	OFN_FORCESHOWHIDDEN = 268435456,
}


[AllowDuplicates]
public enum OPEN_FILENAME_FLAGS_EX : uint32
{
	OFN_EX_NONE = 0,
	OFN_EX_NOPLACESBAR = 1,
}


[AllowDuplicates]
public enum PAGESETUPDLG_FLAGS : uint32
{
	PSD_DEFAULTMINMARGINS = 0,
	PSD_DISABLEMARGINS = 16,
	PSD_DISABLEORIENTATION = 256,
	PSD_DISABLEPAGEPAINTING = 524288,
	PSD_DISABLEPAPER = 512,
	PSD_DISABLEPRINTER = 32,
	PSD_ENABLEPAGEPAINTHOOK = 262144,
	PSD_ENABLEPAGESETUPHOOK = 8192,
	PSD_ENABLEPAGESETUPTEMPLATE = 32768,
	PSD_ENABLEPAGESETUPTEMPLATEHANDLE = 131072,
	PSD_INHUNDREDTHSOFMILLIMETERS = 8,
	PSD_INTHOUSANDTHSOFINCHES = 4,
	PSD_INWININIINTLMEASURE = 0,
	PSD_MARGINS = 2,
	PSD_MINMARGINS = 1,
	PSD_NONETWORKBUTTON = 2097152,
	PSD_NOWARNING = 128,
	PSD_RETURNDEFAULT = 1024,
	PSD_SHOWHELP = 2048,
}


[AllowDuplicates]
public enum CHOOSEFONT_FLAGS : uint32
{
	CF_APPLY = 512,
	CF_ANSIONLY = 1024,
	CF_BOTH = 3,
	CF_EFFECTS = 256,
	CF_ENABLEHOOK = 8,
	CF_ENABLETEMPLATE = 16,
	CF_ENABLETEMPLATEHANDLE = 32,
	CF_FIXEDPITCHONLY = 16384,
	CF_FORCEFONTEXIST = 65536,
	CF_INACTIVEFONTS = 33554432,
	CF_INITTOLOGFONTSTRUCT = 64,
	CF_LIMITSIZE = 8192,
	CF_NOOEMFONTS = 2048,
	CF_NOFACESEL = 524288,
	CF_NOSCRIPTSEL = 8388608,
	CF_NOSIMULATIONS = 4096,
	CF_NOSIZESEL = 2097152,
	CF_NOSTYLESEL = 1048576,
	CF_NOVECTORFONTS = 2048,
	CF_NOVERTFONTS = 16777216,
	CF_PRINTERFONTS = 2,
	CF_SCALABLEONLY = 131072,
	CF_SCREENFONTS = 1,
	CF_SCRIPTSONLY = 1024,
	CF_SELECTSCRIPT = 4194304,
	CF_SHOWHELP = 4,
	CF_TTONLY = 262144,
	CF_USESTYLE = 128,
	CF_WYSIWYG = 32768,
}


[AllowDuplicates]
public enum FINDREPLACE_FLAGS : uint32
{
	FR_DIALOGTERM = 64,
	FR_DOWN = 1,
	FR_ENABLEHOOK = 256,
	FR_ENABLETEMPLATE = 512,
	FR_ENABLETEMPLATEHANDLE = 8192,
	FR_FINDNEXT = 8,
	FR_HIDEUPDOWN = 16384,
	FR_HIDEMATCHCASE = 32768,
	FR_HIDEWHOLEWORD = 65536,
	FR_MATCHCASE = 4,
	FR_NOMATCHCASE = 2048,
	FR_NOUPDOWN = 1024,
	FR_NOWHOLEWORD = 4096,
	FR_REPLACE = 16,
	FR_REPLACEALL = 32,
	FR_SHOWHELP = 128,
	FR_WHOLEWORD = 2,
}


[AllowDuplicates]
public enum PRINTDLGEX_FLAGS : uint32
{
	PD_ALLPAGES = 0,
	PD_COLLATE = 16,
	PD_CURRENTPAGE = 4194304,
	PD_DISABLEPRINTTOFILE = 524288,
	PD_ENABLEPRINTTEMPLATE = 16384,
	PD_ENABLEPRINTTEMPLATEHANDLE = 65536,
	PD_EXCLUSIONFLAGS = 16777216,
	PD_HIDEPRINTTOFILE = 1048576,
	PD_NOCURRENTPAGE = 8388608,
	PD_NOPAGENUMS = 8,
	PD_NOSELECTION = 4,
	PD_NOWARNING = 128,
	PD_PAGENUMS = 2,
	PD_PRINTTOFILE = 32,
	PD_RETURNDC = 256,
	PD_RETURNDEFAULT = 1024,
	PD_RETURNIC = 512,
	PD_SELECTION = 1,
	PD_USEDEVMODECOPIES = 262144,
	PD_USEDEVMODECOPIESANDCOLLATE = 262144,
	PD_USELARGETEMPLATE = 268435456,
	PD_ENABLEPRINTHOOK = 4096,
	PD_ENABLESETUPHOOK = 8192,
	PD_ENABLESETUPTEMPLATE = 32768,
	PD_ENABLESETUPTEMPLATEHANDLE = 131072,
	PD_NONETWORKBUTTON = 2097152,
	PD_PRINTSETUP = 64,
	PD_SHOWHELP = 2048,
}


[AllowDuplicates]
public enum CHOOSEFONT_FONT_TYPE : uint16
{
	BOLD_FONTTYPE = 256,
	ITALIC_FONTTYPE = 512,
	PRINTER_FONTTYPE = 16384,
	REGULAR_FONTTYPE = 1024,
	SCREEN_FONTTYPE = 8192,
	SIMULATED_FONTTYPE = 32768,
}

#endregion

#region Function Pointers
public function uint LPOFNHOOKPROC(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPCCHOOKPROC(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPFRHOOKPROC(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPCFHOOKPROC(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPPRINTHOOKPROC(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPSETUPHOOKPROC(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPPAGEPAINTHOOK(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

public function uint LPPAGESETUPHOOK(HWND param0, uint32 param1, WPARAM param2, LPARAM param3);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OPENFILENAME_NT4A
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PSTR lpstrFilter;
	public PSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PSTR lpstrFile;
	public uint32 nMaxFile;
	public PSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PSTR lpstrInitialDir;
	public PSTR lpstrTitle;
	public uint32 Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OPENFILENAME_NT4W
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PWSTR lpstrFilter;
	public PWSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PWSTR lpstrFile;
	public uint32 nMaxFile;
	public PWSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PWSTR lpstrInitialDir;
	public PWSTR lpstrTitle;
	public uint32 Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PWSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OPENFILENAMEA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PSTR lpstrFilter;
	public PSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PSTR lpstrFile;
	public uint32 nMaxFile;
	public PSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PSTR lpstrInitialDir;
	public PSTR lpstrTitle;
	public OPEN_FILENAME_FLAGS Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
	public void* pvReserved;
	public uint32 dwReserved;
	public OPEN_FILENAME_FLAGS_EX FlagsEx;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OPENFILENAMEW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PWSTR lpstrFilter;
	public PWSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PWSTR lpstrFile;
	public uint32 nMaxFile;
	public PWSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PWSTR lpstrInitialDir;
	public PWSTR lpstrTitle;
	public OPEN_FILENAME_FLAGS Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PWSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
	public void* pvReserved;
	public uint32 dwReserved;
	public OPEN_FILENAME_FLAGS_EX FlagsEx;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OFNOTIFYA
{
	public NMHDR hdr;
	public OPENFILENAMEA* lpOFN;
	public PSTR pszFile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OFNOTIFYW
{
	public NMHDR hdr;
	public OPENFILENAMEW* lpOFN;
	public PWSTR pszFile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OFNOTIFYEXA
{
	public NMHDR hdr;
	public OPENFILENAMEA* lpOFN;
	public void* psf;
	public void* pidl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OFNOTIFYEXW
{
	public NMHDR hdr;
	public OPENFILENAMEW* lpOFN;
	public void* psf;
	public void* pidl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct CHOOSECOLORA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HWND hInstance;
	public COLORREF rgbResult;
	public COLORREF* lpCustColors;
	public CHOOSECOLOR_FLAGS Flags;
	public LPARAM lCustData;
	public LPCCHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct CHOOSECOLORW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HWND hInstance;
	public COLORREF rgbResult;
	public COLORREF* lpCustColors;
	public CHOOSECOLOR_FLAGS Flags;
	public LPARAM lCustData;
	public LPCCHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FINDREPLACEA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public FINDREPLACE_FLAGS Flags;
	public PSTR lpstrFindWhat;
	public PSTR lpstrReplaceWith;
	public uint16 wFindWhatLen;
	public uint16 wReplaceWithLen;
	public LPARAM lCustData;
	public LPFRHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FINDREPLACEW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public FINDREPLACE_FLAGS Flags;
	public PWSTR lpstrFindWhat;
	public PWSTR lpstrReplaceWith;
	public uint16 wFindWhatLen;
	public uint16 wReplaceWithLen;
	public LPARAM lCustData;
	public LPFRHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct CHOOSEFONTA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HDC hDC;
	public LOGFONTA* lpLogFont;
	public int32 iPointSize;
	public CHOOSEFONT_FLAGS Flags;
	public COLORREF rgbColors;
	public LPARAM lCustData;
	public LPCFHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
	public HINSTANCE hInstance;
	public PSTR lpszStyle;
	public CHOOSEFONT_FONT_TYPE nFontType;
	public uint16 ___MISSING_ALIGNMENT__;
	public int32 nSizeMin;
	public int32 nSizeMax;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct CHOOSEFONTW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HDC hDC;
	public LOGFONTW* lpLogFont;
	public int32 iPointSize;
	public CHOOSEFONT_FLAGS Flags;
	public COLORREF rgbColors;
	public LPARAM lCustData;
	public LPCFHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
	public HINSTANCE hInstance;
	public PWSTR lpszStyle;
	public CHOOSEFONT_FONT_TYPE nFontType;
	public uint16 ___MISSING_ALIGNMENT__;
	public int32 nSizeMin;
	public int32 nSizeMax;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PRINTDLGA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint16 nFromPage;
	public uint16 nToPage;
	public uint16 nMinPage;
	public uint16 nMaxPage;
	public uint16 nCopies;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPRINTHOOKPROC lpfnPrintHook;
	public LPSETUPHOOKPROC lpfnSetupHook;
	public PSTR lpPrintTemplateName;
	public PSTR lpSetupTemplateName;
	public int hPrintTemplate;
	public int hSetupTemplate;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PRINTDLGW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint16 nFromPage;
	public uint16 nToPage;
	public uint16 nMinPage;
	public uint16 nMaxPage;
	public uint16 nCopies;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPRINTHOOKPROC lpfnPrintHook;
	public LPSETUPHOOKPROC lpfnSetupHook;
	public PWSTR lpPrintTemplateName;
	public PWSTR lpSetupTemplateName;
	public int hPrintTemplate;
	public int hSetupTemplate;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PRINTPAGERANGE
{
	public uint32 nFromPage;
	public uint32 nToPage;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PRINTDLGEXA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint32 Flags2;
	public uint32 ExclusionFlags;
	public uint32 nPageRanges;
	public uint32 nMaxPageRanges;
	public PRINTPAGERANGE* lpPageRanges;
	public uint32 nMinPage;
	public uint32 nMaxPage;
	public uint32 nCopies;
	public HINSTANCE hInstance;
	public PSTR lpPrintTemplateName;
	public IUnknown* lpCallback;
	public uint32 nPropertyPages;
	public HPROPSHEETPAGE* lphPropertyPages;
	public uint32 nStartPage;
	public uint32 dwResultAction;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PRINTDLGEXW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint32 Flags2;
	public uint32 ExclusionFlags;
	public uint32 nPageRanges;
	public uint32 nMaxPageRanges;
	public PRINTPAGERANGE* lpPageRanges;
	public uint32 nMinPage;
	public uint32 nMaxPage;
	public uint32 nCopies;
	public HINSTANCE hInstance;
	public PWSTR lpPrintTemplateName;
	public IUnknown* lpCallback;
	public uint32 nPropertyPages;
	public HPROPSHEETPAGE* lphPropertyPages;
	public uint32 nStartPage;
	public uint32 dwResultAction;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DEVNAMES
{
	public uint16 wDriverOffset;
	public uint16 wDeviceOffset;
	public uint16 wOutputOffset;
	public uint16 wDefault;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PAGESETUPDLGA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public PAGESETUPDLG_FLAGS Flags;
	public POINT ptPaperSize;
	public RECT rtMinMargin;
	public RECT rtMargin;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPAGESETUPHOOK lpfnPageSetupHook;
	public LPPAGEPAINTHOOK lpfnPagePaintHook;
	public PSTR lpPageSetupTemplateName;
	public int hPageSetupTemplate;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct PAGESETUPDLGW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public PAGESETUPDLG_FLAGS Flags;
	public POINT ptPaperSize;
	public RECT rtMinMargin;
	public RECT rtMargin;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPAGESETUPHOOK lpfnPageSetupHook;
	public LPPAGEPAINTHOOK lpfnPagePaintHook;
	public PWSTR lpPageSetupTemplateName;
	public int hPageSetupTemplate;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OPENFILENAME_NT4A
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PSTR lpstrFilter;
	public PSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PSTR lpstrFile;
	public uint32 nMaxFile;
	public PSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PSTR lpstrInitialDir;
	public PSTR lpstrTitle;
	public uint32 Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OPENFILENAME_NT4W
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PWSTR lpstrFilter;
	public PWSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PWSTR lpstrFile;
	public uint32 nMaxFile;
	public PWSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PWSTR lpstrInitialDir;
	public PWSTR lpstrTitle;
	public uint32 Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PWSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OPENFILENAMEA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PSTR lpstrFilter;
	public PSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PSTR lpstrFile;
	public uint32 nMaxFile;
	public PSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PSTR lpstrInitialDir;
	public PSTR lpstrTitle;
	public OPEN_FILENAME_FLAGS Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
	public void* pvReserved;
	public uint32 dwReserved;
	public OPEN_FILENAME_FLAGS_EX FlagsEx;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OPENFILENAMEW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public PWSTR lpstrFilter;
	public PWSTR lpstrCustomFilter;
	public uint32 nMaxCustFilter;
	public uint32 nFilterIndex;
	public PWSTR lpstrFile;
	public uint32 nMaxFile;
	public PWSTR lpstrFileTitle;
	public uint32 nMaxFileTitle;
	public PWSTR lpstrInitialDir;
	public PWSTR lpstrTitle;
	public OPEN_FILENAME_FLAGS Flags;
	public uint16 nFileOffset;
	public uint16 nFileExtension;
	public PWSTR lpstrDefExt;
	public LPARAM lCustData;
	public LPOFNHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
	public void* pvReserved;
	public uint32 dwReserved;
	public OPEN_FILENAME_FLAGS_EX FlagsEx;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OFNOTIFYA
{
	public NMHDR hdr;
	public OPENFILENAMEA* lpOFN;
	public PSTR pszFile;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OFNOTIFYW
{
	public NMHDR hdr;
	public OPENFILENAMEW* lpOFN;
	public PWSTR pszFile;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OFNOTIFYEXA
{
	public NMHDR hdr;
	public OPENFILENAMEA* lpOFN;
	public void* psf;
	public void* pidl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OFNOTIFYEXW
{
	public NMHDR hdr;
	public OPENFILENAMEW* lpOFN;
	public void* psf;
	public void* pidl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct CHOOSECOLORA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HWND hInstance;
	public COLORREF rgbResult;
	public COLORREF* lpCustColors;
	public CHOOSECOLOR_FLAGS Flags;
	public LPARAM lCustData;
	public LPCCHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct CHOOSECOLORW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HWND hInstance;
	public COLORREF rgbResult;
	public COLORREF* lpCustColors;
	public CHOOSECOLOR_FLAGS Flags;
	public LPARAM lCustData;
	public LPCCHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FINDREPLACEA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public FINDREPLACE_FLAGS Flags;
	public PSTR lpstrFindWhat;
	public PSTR lpstrReplaceWith;
	public uint16 wFindWhatLen;
	public uint16 wReplaceWithLen;
	public LPARAM lCustData;
	public LPFRHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FINDREPLACEW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HINSTANCE hInstance;
	public FINDREPLACE_FLAGS Flags;
	public PWSTR lpstrFindWhat;
	public PWSTR lpstrReplaceWith;
	public uint16 wFindWhatLen;
	public uint16 wReplaceWithLen;
	public LPARAM lCustData;
	public LPFRHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct CHOOSEFONTA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HDC hDC;
	public LOGFONTA* lpLogFont;
	public int32 iPointSize;
	public CHOOSEFONT_FLAGS Flags;
	public COLORREF rgbColors;
	public LPARAM lCustData;
	public LPCFHOOKPROC lpfnHook;
	public PSTR lpTemplateName;
	public HINSTANCE hInstance;
	public PSTR lpszStyle;
	public CHOOSEFONT_FONT_TYPE nFontType;
	public uint16 ___MISSING_ALIGNMENT__;
	public int32 nSizeMin;
	public int32 nSizeMax;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct CHOOSEFONTW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public HDC hDC;
	public LOGFONTW* lpLogFont;
	public int32 iPointSize;
	public CHOOSEFONT_FLAGS Flags;
	public COLORREF rgbColors;
	public LPARAM lCustData;
	public LPCFHOOKPROC lpfnHook;
	public PWSTR lpTemplateName;
	public HINSTANCE hInstance;
	public PWSTR lpszStyle;
	public CHOOSEFONT_FONT_TYPE nFontType;
	public uint16 ___MISSING_ALIGNMENT__;
	public int32 nSizeMin;
	public int32 nSizeMax;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PRINTDLGA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint16 nFromPage;
	public uint16 nToPage;
	public uint16 nMinPage;
	public uint16 nMaxPage;
	public uint16 nCopies;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPRINTHOOKPROC lpfnPrintHook;
	public LPSETUPHOOKPROC lpfnSetupHook;
	public PSTR lpPrintTemplateName;
	public PSTR lpSetupTemplateName;
	public int hPrintTemplate;
	public int hSetupTemplate;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PRINTDLGW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint16 nFromPage;
	public uint16 nToPage;
	public uint16 nMinPage;
	public uint16 nMaxPage;
	public uint16 nCopies;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPRINTHOOKPROC lpfnPrintHook;
	public LPSETUPHOOKPROC lpfnSetupHook;
	public PWSTR lpPrintTemplateName;
	public PWSTR lpSetupTemplateName;
	public int hPrintTemplate;
	public int hSetupTemplate;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PRINTPAGERANGE
{
	public uint32 nFromPage;
	public uint32 nToPage;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PRINTDLGEXA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint32 Flags2;
	public uint32 ExclusionFlags;
	public uint32 nPageRanges;
	public uint32 nMaxPageRanges;
	public PRINTPAGERANGE* lpPageRanges;
	public uint32 nMinPage;
	public uint32 nMaxPage;
	public uint32 nCopies;
	public HINSTANCE hInstance;
	public PSTR lpPrintTemplateName;
	public IUnknown* lpCallback;
	public uint32 nPropertyPages;
	public HPROPSHEETPAGE* lphPropertyPages;
	public uint32 nStartPage;
	public uint32 dwResultAction;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PRINTDLGEXW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public HDC hDC;
	public PRINTDLGEX_FLAGS Flags;
	public uint32 Flags2;
	public uint32 ExclusionFlags;
	public uint32 nPageRanges;
	public uint32 nMaxPageRanges;
	public PRINTPAGERANGE* lpPageRanges;
	public uint32 nMinPage;
	public uint32 nMaxPage;
	public uint32 nCopies;
	public HINSTANCE hInstance;
	public PWSTR lpPrintTemplateName;
	public IUnknown* lpCallback;
	public uint32 nPropertyPages;
	public HPROPSHEETPAGE* lphPropertyPages;
	public uint32 nStartPage;
	public uint32 dwResultAction;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct DEVNAMES
{
	public uint16 wDriverOffset;
	public uint16 wDeviceOffset;
	public uint16 wOutputOffset;
	public uint16 wDefault;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PAGESETUPDLGA
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public PAGESETUPDLG_FLAGS Flags;
	public POINT ptPaperSize;
	public RECT rtMinMargin;
	public RECT rtMargin;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPAGESETUPHOOK lpfnPageSetupHook;
	public LPPAGEPAINTHOOK lpfnPagePaintHook;
	public PSTR lpPageSetupTemplateName;
	public int hPageSetupTemplate;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct PAGESETUPDLGW
{
	public uint32 lStructSize;
	public HWND hwndOwner;
	public int hDevMode;
	public int hDevNames;
	public PAGESETUPDLG_FLAGS Flags;
	public POINT ptPaperSize;
	public RECT rtMinMargin;
	public RECT rtMargin;
	public HINSTANCE hInstance;
	public LPARAM lCustData;
	public LPPAGESETUPHOOK lpfnPageSetupHook;
	public LPPAGEPAINTHOOK lpfnPagePaintHook;
	public PWSTR lpPageSetupTemplateName;
	public int hPageSetupTemplate;
}
#endif

#endregion

#region COM Types
[CRepr]struct IPrintDialogCallback : IUnknown
{
	public new const Guid IID = .(0x5852a2c3, 0x6530, 0x11d1, 0xb6, 0xa3, 0x00, 0x00, 0xf8, 0x75, 0x7b, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SelectionChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hDlg, uint32 uMsg, WPARAM wParam, LPARAM lParam, LRESULT* pResult) HandleMessage;
	}


	public HRESULT InitDone() mut => VT.[Friend]InitDone(&this);

	public HRESULT SelectionChange() mut => VT.[Friend]SelectionChange(&this);

	public HRESULT HandleMessage(HWND hDlg, uint32 uMsg, WPARAM wParam, LPARAM lParam, LRESULT* pResult) mut => VT.[Friend]HandleMessage(&this, hDlg, uMsg, wParam, lParam, pResult);
}

[CRepr]struct IPrintDialogServices : IUnknown
{
	public new const Guid IID = .(0x509aaeda, 0x5639, 0x11d1, 0xb6, 0xa1, 0x00, 0x00, 0xf8, 0x75, 0x7b, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevMode, uint32* pcbSize) GetCurrentDevMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pPrinterName, uint32* pcchSize) GetCurrentPrinterName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pPortName, uint32* pcchSize) GetCurrentPortName;
	}


	public HRESULT GetCurrentDevMode(DEVMODEA* pDevMode, uint32* pcbSize) mut => VT.[Friend]GetCurrentDevMode(&this, pDevMode, pcbSize);

	public HRESULT GetCurrentPrinterName(char16* pPrinterName, uint32* pcchSize) mut => VT.[Friend]GetCurrentPrinterName(&this, pPrinterName, pcchSize);

	public HRESULT GetCurrentPortName(char16* pPortName, uint32* pcchSize) mut => VT.[Friend]GetCurrentPortName(&this, pPortName, pcchSize);
}

#endregion

#region Functions
public static
{
	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOpenFileNameA(OPENFILENAMEA* param0);
	public static BOOL GetOpenFileName(OPENFILENAMEA* param0) => GetOpenFileNameA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOpenFileNameW(OPENFILENAMEW* param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSaveFileNameA(OPENFILENAMEA* param0);
	public static BOOL GetSaveFileName(OPENFILENAMEA* param0) => GetSaveFileNameA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSaveFileNameW(OPENFILENAMEW* param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 GetFileTitleA(PSTR param0, uint8* Buf, uint16 cchSize);
	public static int16 GetFileTitle(PSTR param0, uint8* Buf, uint16 cchSize) => GetFileTitleA(param0, Buf, cchSize);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 GetFileTitleW(PWSTR param0, char16* Buf, uint16 cchSize);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChooseColorA(CHOOSECOLORA* param0);
	public static BOOL ChooseColor(CHOOSECOLORA* param0) => ChooseColorA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChooseColorW(CHOOSECOLORW* param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND FindTextA(FINDREPLACEA* param0);
	public static HWND FindText(FINDREPLACEA* param0) => FindTextA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND FindTextW(FINDREPLACEW* param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND ReplaceTextA(FINDREPLACEA* param0);
	public static HWND ReplaceText(FINDREPLACEA* param0) => ReplaceTextA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND ReplaceTextW(FINDREPLACEW* param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChooseFontA(CHOOSEFONTA* param0);
	public static BOOL ChooseFont(CHOOSEFONTA* param0) => ChooseFontA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChooseFontW(CHOOSEFONTW* param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrintDlgA(PRINTDLGA* pPD);
	public static BOOL PrintDlg(PRINTDLGA* pPD) => PrintDlgA(pPD);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrintDlgW(PRINTDLGW* pPD);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrintDlgExA(PRINTDLGEXA* pPD);
	public static HRESULT PrintDlgEx(PRINTDLGEXA* pPD) => PrintDlgExA(pPD);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrintDlgExW(PRINTDLGEXW* pPD);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COMMON_DLG_ERRORS CommDlgExtendedError();

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PageSetupDlgA(PAGESETUPDLGA* param0);
	public static BOOL PageSetupDlg(PAGESETUPDLGA* param0) => PageSetupDlgA(param0);

	[Import("COMDLG32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PageSetupDlgW(PAGESETUPDLGW* param0);

}
#endregion
