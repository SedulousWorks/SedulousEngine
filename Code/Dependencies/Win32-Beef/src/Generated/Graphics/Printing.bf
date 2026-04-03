using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Ole;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Gdi;
using Win32.Security;
using Win32.Data.Xml.MsXml;
using Win32.Devices.Display;
using Win32.System.Registry;
using Win32.Graphics.Imaging;
using Win32.Storage.Xps;
using Win32.Graphics.Dxgi;
using System;

namespace Win32.Graphics.Printing;

#region Constants
public static
{
	public const uint32 USB_PRINTER_INTERFACE_CLASSIC = 1;
	public const uint32 USB_PRINTER_INTERFACE_IPP = 2;
	public const uint32 USB_PRINTER_INTERFACE_DUAL = 3;
	public const uint32 USBPRINT_IOCTL_INDEX = 0;
	public const uint32 IOCTL_USBPRINT_GET_LPT_STATUS = 2228272;
	public const uint32 IOCTL_USBPRINT_GET_1284_ID = 2228276;
	public const uint32 IOCTL_USBPRINT_VENDOR_SET_COMMAND = 2228280;
	public const uint32 IOCTL_USBPRINT_VENDOR_GET_COMMAND = 2228284;
	public const uint32 IOCTL_USBPRINT_SOFT_RESET = 2228288;
	public const uint32 IOCTL_USBPRINT_GET_PROTOCOL = 2228292;
	public const uint32 IOCTL_USBPRINT_SET_PROTOCOL = 2228296;
	public const uint32 IOCTL_USBPRINT_GET_INTERFACE_TYPE = 2228300;
	public const uint32 IOCTL_USBPRINT_SET_PORT_NUMBER = 2228304;
	public const uint32 IOCTL_USBPRINT_ADD_MSIPP_COMPAT_ID = 2228308;
	public const uint32 IOCTL_USBPRINT_SET_DEVICE_ID = 2228312;
	public const uint32 IOCTL_USBPRINT_ADD_CHILD_DEVICE = 2228316;
	public const uint32 IOCTL_USBPRINT_CYCLE_PORT = 2228320;
	public const uint32 TVOT_2STATES = 0;
	public const uint32 TVOT_3STATES = 1;
	public const uint32 TVOT_UDARROW = 2;
	public const uint32 TVOT_TRACKBAR = 3;
	public const uint32 TVOT_SCROLLBAR = 4;
	public const uint32 TVOT_LISTBOX = 5;
	public const uint32 TVOT_COMBOBOX = 6;
	public const uint32 TVOT_EDITBOX = 7;
	public const uint32 TVOT_PUSHBUTTON = 8;
	public const uint32 TVOT_CHKBOX = 9;
	public const uint32 TVOT_NSTATES_EX = 10;
	public const uint32 CHKBOXS_FALSE_TRUE = 0;
	public const uint32 CHKBOXS_NO_YES = 1;
	public const uint32 CHKBOXS_OFF_ON = 2;
	public const uint32 CHKBOXS_FALSE_PDATA = 3;
	public const uint32 CHKBOXS_NO_PDATA = 4;
	public const uint32 CHKBOXS_OFF_PDATA = 5;
	public const uint32 CHKBOXS_NONE_PDATA = 6;
	public const uint32 PUSHBUTTON_TYPE_DLGPROC = 0;
	public const uint32 PUSHBUTTON_TYPE_CALLBACK = 1;
	public const uint32 PUSHBUTTON_TYPE_HTCLRADJ = 2;
	public const uint32 PUSHBUTTON_TYPE_HTSETUP = 3;
	public const uint32 MAX_RES_STR_CHARS = 160;
	public const uint32 OPTPF_HIDE = 1;
	public const uint32 OPTPF_DISABLED = 2;
	public const uint32 OPTPF_ICONID_AS_HICON = 4;
	public const uint32 OPTPF_OVERLAY_WARNING_ICON = 8;
	public const uint32 OPTPF_OVERLAY_STOP_ICON = 16;
	public const uint32 OPTPF_OVERLAY_NO_ICON = 32;
	public const uint32 OPTPF_USE_HDLGTEMPLATE = 64;
	public const uint32 OPTPF_MASK = 127;
	public const uint32 OPTCF_HIDE = 1;
	public const uint32 OPTCF_MASK = 1;
	public const uint32 OPTTF_TYPE_DISABLED = 1;
	public const uint32 OPTTF_NOSPACE_BEFORE_POSTFIX = 2;
	public const uint32 OPTTF_MASK = 3;
	public const uint32 OTS_LBCB_SORT = 1;
	public const uint32 OTS_LBCB_PROPPAGE_LBUSECB = 2;
	public const uint32 OTS_LBCB_PROPPAGE_CBUSELB = 4;
	public const uint32 OTS_LBCB_INCL_ITEM_NONE = 8;
	public const uint32 OTS_LBCB_NO_ICON16_IN_ITEM = 16;
	public const uint32 OTS_PUSH_INCL_SETUP_TITLE = 32;
	public const uint32 OTS_PUSH_NO_DOT_DOT_DOT = 64;
	public const uint32 OTS_PUSH_ENABLE_ALWAYS = 128;
	public const uint32 OTS_MASK = 255;
	public const uint32 EPF_PUSH_TYPE_DLGPROC = 1;
	public const uint32 EPF_INCL_SETUP_TITLE = 2;
	public const uint32 EPF_NO_DOT_DOT_DOT = 4;
	public const uint32 EPF_ICONID_AS_HICON = 8;
	public const uint32 EPF_OVERLAY_WARNING_ICON = 16;
	public const uint32 EPF_OVERLAY_STOP_ICON = 32;
	public const uint32 EPF_OVERLAY_NO_ICON = 64;
	public const uint32 EPF_USE_HDLGTEMPLATE = 128;
	public const uint32 EPF_MASK = 255;
	public const uint32 ECBF_CHECKNAME_AT_FRONT = 1;
	public const uint32 ECBF_CHECKNAME_ONLY_ENABLED = 2;
	public const uint32 ECBF_ICONID_AS_HICON = 4;
	public const uint32 ECBF_OVERLAY_WARNING_ICON = 8;
	public const uint32 ECBF_OVERLAY_ECBICON_IF_CHECKED = 16;
	public const uint32 ECBF_OVERLAY_STOP_ICON = 32;
	public const uint32 ECBF_OVERLAY_NO_ICON = 64;
	public const uint32 ECBF_CHECKNAME_ONLY = 128;
	public const uint32 ECBF_MASK = 255;
	public const int32 OPTIF_COLLAPSE = 1;
	public const int32 OPTIF_HIDE = 2;
	public const int32 OPTIF_CALLBACK = 4;
	public const int32 OPTIF_CHANGED = 8;
	public const int32 OPTIF_CHANGEONCE = 16;
	public const int32 OPTIF_DISABLED = 32;
	public const int32 OPTIF_ECB_CHECKED = 64;
	public const int32 OPTIF_EXT_HIDE = 128;
	public const int32 OPTIF_EXT_DISABLED = 256;
	public const int32 OPTIF_SEL_AS_HICON = 512;
	public const int32 OPTIF_EXT_IS_EXTPUSH = 1024;
	public const int32 OPTIF_NO_GROUPBOX_NAME = 2048;
	public const int32 OPTIF_OVERLAY_WARNING_ICON = 4096;
	public const int32 OPTIF_OVERLAY_STOP_ICON = 8192;
	public const int32 OPTIF_OVERLAY_NO_ICON = 16384;
	public const int32 OPTIF_INITIAL_TVITEM = 32768;
	public const int32 OPTIF_HAS_POIEXT = 65536;
	public const int32 OPTIF_MASK = 131071;
	public const uint32 DMPUB_NONE = 0;
	public const uint32 DMPUB_FIRST = 1;
	public const uint32 DMPUB_ORIENTATION = 1;
	public const uint32 DMPUB_SCALE = 2;
	public const uint32 DMPUB_COPIES_COLLATE = 3;
	public const uint32 DMPUB_DEFSOURCE = 4;
	public const uint32 DMPUB_PRINTQUALITY = 5;
	public const uint32 DMPUB_COLOR = 6;
	public const uint32 DMPUB_DUPLEX = 7;
	public const uint32 DMPUB_TTOPTION = 8;
	public const uint32 DMPUB_FORMNAME = 9;
	public const uint32 DMPUB_ICMMETHOD = 10;
	public const uint32 DMPUB_ICMINTENT = 11;
	public const uint32 DMPUB_MEDIATYPE = 12;
	public const uint32 DMPUB_DITHERTYPE = 13;
	public const uint32 DMPUB_OUTPUTBIN = 14;
	public const uint32 DMPUB_QUALITY = 15;
	public const uint32 DMPUB_NUP = 16;
	public const uint32 DMPUB_PAGEORDER = 17;
	public const uint32 DMPUB_NUP_DIRECTION = 18;
	public const uint32 DMPUB_MANUAL_DUPLEX = 19;
	public const uint32 DMPUB_STAPLE = 20;
	public const uint32 DMPUB_BOOKLET_EDGE = 21;
	public const uint32 DMPUB_LAST = 21;
	public const uint32 DMPUB_OEM_PAPER_ITEM = 97;
	public const uint32 DMPUB_OEM_GRAPHIC_ITEM = 98;
	public const uint32 DMPUB_OEM_ROOT_ITEM = 99;
	public const uint32 DMPUB_USER = 100;
	public const uint32 OIEXTF_ANSI_STRING = 1;
	public const uint32 CPSUICB_REASON_SEL_CHANGED = 0;
	public const uint32 CPSUICB_REASON_PUSHBUTTON = 1;
	public const uint32 CPSUICB_REASON_ECB_CHANGED = 2;
	public const uint32 CPSUICB_REASON_DLGPROC = 3;
	public const uint32 CPSUICB_REASON_UNDO_CHANGES = 4;
	public const uint32 CPSUICB_REASON_EXTPUSH = 5;
	public const uint32 CPSUICB_REASON_APPLYNOW = 6;
	public const uint32 CPSUICB_REASON_OPTITEM_SETFOCUS = 7;
	public const uint32 CPSUICB_REASON_ITEMS_REVERTED = 8;
	public const uint32 CPSUICB_REASON_ABOUT = 9;
	public const uint32 CPSUICB_REASON_SETACTIVE = 10;
	public const uint32 CPSUICB_REASON_KILLACTIVE = 11;
	public const uint32 CPSUICB_ACTION_NONE = 0;
	public const uint32 CPSUICB_ACTION_OPTIF_CHANGED = 1;
	public const uint32 CPSUICB_ACTION_REINIT_ITEMS = 2;
	public const uint32 CPSUICB_ACTION_NO_APPLY_EXIT = 3;
	public const uint32 CPSUICB_ACTION_ITEMS_APPLIED = 4;
	public const uint32 DP_STD_TREEVIEWPAGE = 65535;
	public const uint32 DP_STD_DOCPROPPAGE2 = 65534;
	public const uint32 DP_STD_DOCPROPPAGE1 = 65533;
	public const uint32 DP_STD_RESERVED_START = 65520;
	public const uint32 MAX_DLGPAGE_COUNT = 64;
	public const uint32 DPF_ICONID_AS_HICON = 1;
	public const uint32 DPF_USE_HDLGTEMPLATE = 2;
	public const uint32 CPSUIF_UPDATE_PERMISSION = 1;
	public const uint32 CPSUIF_ICONID_AS_HICON = 2;
	public const uint32 CPSUIF_ABOUT_CALLBACK = 4;
	public const uint32 CPSFUNC_ADD_HPROPSHEETPAGE = 0;
	public const uint32 CPSFUNC_ADD_PROPSHEETPAGEW = 1;
	public const uint32 CPSFUNC_ADD_PCOMPROPSHEETUIA = 2;
	public const uint32 CPSFUNC_ADD_PCOMPROPSHEETUIW = 3;
	public const uint32 CPSFUNC_ADD_PFNPROPSHEETUIA = 4;
	public const uint32 CPSFUNC_ADD_PFNPROPSHEETUIW = 5;
	public const uint32 CPSFUNC_DELETE_HCOMPROPSHEET = 6;
	public const uint32 CPSFUNC_SET_HSTARTPAGE = 7;
	public const uint32 CPSFUNC_GET_PAGECOUNT = 8;
	public const uint32 CPSFUNC_SET_RESULT = 9;
	public const uint32 CPSFUNC_GET_HPSUIPAGES = 10;
	public const uint32 CPSFUNC_LOAD_CPSUI_STRINGA = 11;
	public const uint32 CPSFUNC_LOAD_CPSUI_STRINGW = 12;
	public const uint32 CPSFUNC_LOAD_CPSUI_ICON = 13;
	public const uint32 CPSFUNC_GET_PFNPROPSHEETUI_ICON = 14;
	public const uint32 CPSFUNC_ADD_PROPSHEETPAGEA = 15;
	public const uint32 CPSFUNC_INSERT_PSUIPAGEA = 16;
	public const uint32 CPSFUNC_INSERT_PSUIPAGEW = 17;
	public const uint32 CPSFUNC_SET_PSUIPAGE_TITLEA = 18;
	public const uint32 CPSFUNC_SET_PSUIPAGE_TITLEW = 19;
	public const uint32 CPSFUNC_SET_PSUIPAGE_ICON = 20;
	public const uint32 CPSFUNC_SET_DATABLOCK = 21;
	public const uint32 CPSFUNC_QUERY_DATABLOCK = 22;
	public const uint32 CPSFUNC_SET_DMPUB_HIDEBITS = 23;
	public const uint32 CPSFUNC_IGNORE_CPSUI_PSN_APPLY = 24;
	public const uint32 CPSFUNC_DO_APPLY_CPSUI = 25;
	public const uint32 CPSFUNC_SET_FUSION_CONTEXT = 26;
	public const uint32 MAX_CPSFUNC_INDEX = 26;
	public const uint32 CPSFUNC_ADD_PCOMPROPSHEETUI = 3;
	public const uint32 CPSFUNC_ADD_PFNPROPSHEETUI = 5;
	public const uint32 CPSFUNC_LOAD_CPSUI_STRING = 12;
	public const uint32 CPSFUNC_ADD_PROPSHEETPAGE = 1;
	public const uint32 CPSFUNC_INSERT_PSUIPAGE = 17;
	public const uint32 CPSFUNC_SET_PSUIPAGE_TITLE = 19;
	public const uint32 SR_OWNER = 0;
	public const uint32 SR_OWNER_PARENT = 1;
	public const uint32 PSUIPAGEINSERT_GROUP_PARENT = 0;
	public const uint32 PSUIPAGEINSERT_PCOMPROPSHEETUI = 1;
	public const uint32 PSUIPAGEINSERT_PFNPROPSHEETUI = 2;
	public const uint32 PSUIPAGEINSERT_PROPSHEETPAGE = 3;
	public const uint32 PSUIPAGEINSERT_HPROPSHEETPAGE = 4;
	public const uint32 PSUIPAGEINSERT_DLL = 5;
	public const uint32 MAX_PSUIPAGEINSERT_INDEX = 5;
	public const uint32 INSPSUIPAGE_MODE_BEFORE = 0;
	public const uint32 INSPSUIPAGE_MODE_AFTER = 1;
	public const uint32 INSPSUIPAGE_MODE_FIRST_CHILD = 2;
	public const uint32 INSPSUIPAGE_MODE_LAST_CHILD = 3;
	public const uint32 INSPSUIPAGE_MODE_INDEX = 4;
	public const uint32 SSP_TVPAGE = 10000;
	public const uint32 SSP_STDPAGE1 = 10001;
	public const uint32 SSP_STDPAGE2 = 10002;
	public const uint32 APPLYCPSUI_NO_NEWDEF = 1;
	public const uint32 APPLYCPSUI_OK_CANCEL_BUTTON = 2;
	public const uint32 PROPSHEETUI_REASON_INIT = 0;
	public const uint32 PROPSHEETUI_REASON_GET_INFO_HEADER = 1;
	public const uint32 PROPSHEETUI_REASON_DESTROY = 2;
	public const uint32 PROPSHEETUI_REASON_SET_RESULT = 3;
	public const uint32 PROPSHEETUI_REASON_GET_ICON = 4;
	public const uint32 PROPSHEETUI_REASON_BEFORE_INIT = 5;
	public const uint32 MAX_PROPSHEETUI_REASON_INDEX = 5;
	public const uint32 PROPSHEETUI_INFO_VERSION = 256;
	public const uint32 PSUIINFO_UNICODE = 1;
	public const uint32 PSUIHDRF_OBSOLETE = 1;
	public const uint32 PSUIHDRF_NOAPPLYNOW = 2;
	public const uint32 PSUIHDRF_PROPTITLE = 4;
	public const uint32 PSUIHDRF_USEHICON = 8;
	public const uint32 PSUIHDRF_DEFTITLE = 16;
	public const uint32 PSUIHDRF_EXACT_PTITLE = 32;
	public const uint32 CPSUI_CANCEL = 0;
	public const uint32 CPSUI_OK = 1;
	public const uint32 CPSUI_RESTARTWINDOWS = 2;
	public const uint32 CPSUI_REBOOTSYSTEM = 3;
	public const int32 ERR_CPSUI_GETLASTERROR = -1;
	public const int32 ERR_CPSUI_ALLOCMEM_FAILED = -2;
	public const int32 ERR_CPSUI_INVALID_PDATA = -3;
	public const int32 ERR_CPSUI_INVALID_LPARAM = -4;
	public const int32 ERR_CPSUI_NULL_HINST = -5;
	public const int32 ERR_CPSUI_NULL_CALLERNAME = -6;
	public const int32 ERR_CPSUI_NULL_OPTITEMNAME = -7;
	public const int32 ERR_CPSUI_NO_PROPSHEETPAGE = -8;
	public const int32 ERR_CPSUI_TOO_MANY_PROPSHEETPAGES = -9;
	public const int32 ERR_CPSUI_CREATEPROPPAGE_FAILED = -10;
	public const int32 ERR_CPSUI_MORE_THAN_ONE_TVPAGE = -11;
	public const int32 ERR_CPSUI_MORE_THAN_ONE_STDPAGE = -12;
	public const int32 ERR_CPSUI_INVALID_PDLGPAGE = -13;
	public const int32 ERR_CPSUI_INVALID_DLGPAGE_CBSIZE = -14;
	public const int32 ERR_CPSUI_TOO_MANY_DLGPAGES = -15;
	public const int32 ERR_CPSUI_INVALID_DLGPAGEIDX = -16;
	public const int32 ERR_CPSUI_SUBITEM_DIFF_DLGPAGEIDX = -17;
	public const int32 ERR_CPSUI_NULL_POPTITEM = -18;
	public const int32 ERR_CPSUI_INVALID_OPTITEM_CBSIZE = -19;
	public const int32 ERR_CPSUI_INVALID_OPTTYPE_CBSIZE = -20;
	public const int32 ERR_CPSUI_INVALID_OPTTYPE_COUNT = -21;
	public const int32 ERR_CPSUI_NULL_POPTPARAM = -22;
	public const int32 ERR_CPSUI_INVALID_OPTPARAM_CBSIZE = -23;
	public const int32 ERR_CPSUI_INVALID_EDITBOX_PSEL = -24;
	public const int32 ERR_CPSUI_INVALID_EDITBOX_BUF_SIZE = -25;
	public const int32 ERR_CPSUI_INVALID_ECB_CBSIZE = -26;
	public const int32 ERR_CPSUI_NULL_ECB_PTITLE = -27;
	public const int32 ERR_CPSUI_NULL_ECB_PCHECKEDNAME = -28;
	public const int32 ERR_CPSUI_INVALID_DMPUBID = -29;
	public const int32 ERR_CPSUI_INVALID_DMPUB_TVOT = -30;
	public const int32 ERR_CPSUI_CREATE_TRACKBAR_FAILED = -31;
	public const int32 ERR_CPSUI_CREATE_UDARROW_FAILED = -32;
	public const int32 ERR_CPSUI_CREATE_IMAGELIST_FAILED = -33;
	public const int32 ERR_CPSUI_INVALID_TVOT_TYPE = -34;
	public const int32 ERR_CPSUI_INVALID_LBCB_TYPE = -35;
	public const int32 ERR_CPSUI_SUBITEM_DIFF_OPTIF_HIDE = -36;
	public const int32 ERR_CPSUI_INVALID_PUSHBUTTON_TYPE = -38;
	public const int32 ERR_CPSUI_INVALID_EXTPUSH_CBSIZE = -39;
	public const int32 ERR_CPSUI_NULL_EXTPUSH_DLGPROC = -40;
	public const int32 ERR_CPSUI_NO_EXTPUSH_DLGTEMPLATEID = -41;
	public const int32 ERR_CPSUI_NULL_EXTPUSH_CALLBACK = -42;
	public const int32 ERR_CPSUI_DMCOPIES_USE_EXTPUSH = -43;
	public const int32 ERR_CPSUI_ZERO_OPTITEM = -44;
	public const int32 ERR_CPSUI_FUNCTION_NOT_IMPLEMENTED = -9999;
	public const int32 ERR_CPSUI_INTERNAL_ERROR = -10000;
	public const uint32 IDI_CPSUI_ICONID_FIRST = 64000;
	public const uint32 IDI_CPSUI_EMPTY = 64000;
	public const uint32 IDI_CPSUI_SEL_NONE = 64001;
	public const uint32 IDI_CPSUI_WARNING = 64002;
	public const uint32 IDI_CPSUI_NO = 64003;
	public const uint32 IDI_CPSUI_YES = 64004;
	public const uint32 IDI_CPSUI_FALSE = 64005;
	public const uint32 IDI_CPSUI_TRUE = 64006;
	public const uint32 IDI_CPSUI_OFF = 64007;
	public const uint32 IDI_CPSUI_ON = 64008;
	public const uint32 IDI_CPSUI_PAPER_OUTPUT = 64009;
	public const uint32 IDI_CPSUI_ENVELOPE = 64010;
	public const uint32 IDI_CPSUI_MEM = 64011;
	public const uint32 IDI_CPSUI_FONTCARTHDR = 64012;
	public const uint32 IDI_CPSUI_FONTCART = 64013;
	public const uint32 IDI_CPSUI_STAPLER_ON = 64014;
	public const uint32 IDI_CPSUI_STAPLER_OFF = 64015;
	public const uint32 IDI_CPSUI_HT_HOST = 64016;
	public const uint32 IDI_CPSUI_HT_DEVICE = 64017;
	public const uint32 IDI_CPSUI_TT_PRINTASGRAPHIC = 64018;
	public const uint32 IDI_CPSUI_TT_DOWNLOADSOFT = 64019;
	public const uint32 IDI_CPSUI_TT_DOWNLOADVECT = 64020;
	public const uint32 IDI_CPSUI_TT_SUBDEV = 64021;
	public const uint32 IDI_CPSUI_PORTRAIT = 64022;
	public const uint32 IDI_CPSUI_LANDSCAPE = 64023;
	public const uint32 IDI_CPSUI_ROT_LAND = 64024;
	public const uint32 IDI_CPSUI_AUTOSEL = 64025;
	public const uint32 IDI_CPSUI_PAPER_TRAY = 64026;
	public const uint32 IDI_CPSUI_PAPER_TRAY2 = 64027;
	public const uint32 IDI_CPSUI_PAPER_TRAY3 = 64028;
	public const uint32 IDI_CPSUI_TRANSPARENT = 64029;
	public const uint32 IDI_CPSUI_COLLATE = 64030;
	public const uint32 IDI_CPSUI_DUPLEX_NONE = 64031;
	public const uint32 IDI_CPSUI_DUPLEX_HORZ = 64032;
	public const uint32 IDI_CPSUI_DUPLEX_VERT = 64033;
	public const uint32 IDI_CPSUI_RES_DRAFT = 64034;
	public const uint32 IDI_CPSUI_RES_LOW = 64035;
	public const uint32 IDI_CPSUI_RES_MEDIUM = 64036;
	public const uint32 IDI_CPSUI_RES_HIGH = 64037;
	public const uint32 IDI_CPSUI_RES_PRESENTATION = 64038;
	public const uint32 IDI_CPSUI_MONO = 64039;
	public const uint32 IDI_CPSUI_COLOR = 64040;
	public const uint32 IDI_CPSUI_DITHER_NONE = 64041;
	public const uint32 IDI_CPSUI_DITHER_COARSE = 64042;
	public const uint32 IDI_CPSUI_DITHER_FINE = 64043;
	public const uint32 IDI_CPSUI_DITHER_LINEART = 64044;
	public const uint32 IDI_CPSUI_SCALING = 64045;
	public const uint32 IDI_CPSUI_COPY = 64046;
	public const uint32 IDI_CPSUI_HTCLRADJ = 64047;
	public const uint32 IDI_CPSUI_HALFTONE_SETUP = 64048;
	public const uint32 IDI_CPSUI_WATERMARK = 64049;
	public const uint32 IDI_CPSUI_ERROR = 64050;
	public const uint32 IDI_CPSUI_ICM_OPTION = 64051;
	public const uint32 IDI_CPSUI_ICM_METHOD = 64052;
	public const uint32 IDI_CPSUI_ICM_INTENT = 64053;
	public const uint32 IDI_CPSUI_STD_FORM = 64054;
	public const uint32 IDI_CPSUI_OUTBIN = 64055;
	public const uint32 IDI_CPSUI_OUTPUT = 64056;
	public const uint32 IDI_CPSUI_GRAPHIC = 64057;
	public const uint32 IDI_CPSUI_ADVANCE = 64058;
	public const uint32 IDI_CPSUI_DOCUMENT = 64059;
	public const uint32 IDI_CPSUI_DEVICE = 64060;
	public const uint32 IDI_CPSUI_DEVICE2 = 64061;
	public const uint32 IDI_CPSUI_PRINTER = 64062;
	public const uint32 IDI_CPSUI_PRINTER2 = 64063;
	public const uint32 IDI_CPSUI_PRINTER3 = 64064;
	public const uint32 IDI_CPSUI_PRINTER4 = 64065;
	public const uint32 IDI_CPSUI_OPTION = 64066;
	public const uint32 IDI_CPSUI_OPTION2 = 64067;
	public const uint32 IDI_CPSUI_STOP = 64068;
	public const uint32 IDI_CPSUI_NOTINSTALLED = 64069;
	public const uint32 IDI_CPSUI_WARNING_OVERLAY = 64070;
	public const uint32 IDI_CPSUI_STOP_WARNING_OVERLAY = 64071;
	public const uint32 IDI_CPSUI_GENERIC_OPTION = 64072;
	public const uint32 IDI_CPSUI_GENERIC_ITEM = 64073;
	public const uint32 IDI_CPSUI_RUN_DIALOG = 64074;
	public const uint32 IDI_CPSUI_QUESTION = 64075;
	public const uint32 IDI_CPSUI_FORMTRAYASSIGN = 64076;
	public const uint32 IDI_CPSUI_PRINTER_FOLDER = 64077;
	public const uint32 IDI_CPSUI_INSTALLABLE_OPTION = 64078;
	public const uint32 IDI_CPSUI_PRINTER_FEATURE = 64079;
	public const uint32 IDI_CPSUI_DEVICE_FEATURE = 64080;
	public const uint32 IDI_CPSUI_FONTSUB = 64081;
	public const uint32 IDI_CPSUI_POSTSCRIPT = 64082;
	public const uint32 IDI_CPSUI_TELEPHONE = 64083;
	public const uint32 IDI_CPSUI_DUPLEX_NONE_L = 64084;
	public const uint32 IDI_CPSUI_DUPLEX_HORZ_L = 64085;
	public const uint32 IDI_CPSUI_DUPLEX_VERT_L = 64086;
	public const uint32 IDI_CPSUI_LF_PEN_PLOTTER = 64087;
	public const uint32 IDI_CPSUI_SF_PEN_PLOTTER = 64088;
	public const uint32 IDI_CPSUI_LF_RASTER_PLOTTER = 64089;
	public const uint32 IDI_CPSUI_SF_RASTER_PLOTTER = 64090;
	public const uint32 IDI_CPSUI_ROLL_PAPER = 64091;
	public const uint32 IDI_CPSUI_PEN_CARROUSEL = 64092;
	public const uint32 IDI_CPSUI_PLOTTER_PEN = 64093;
	public const uint32 IDI_CPSUI_MANUAL_FEED = 64094;
	public const uint32 IDI_CPSUI_FAX = 64095;
	public const uint32 IDI_CPSUI_PAGE_PROTECT = 64096;
	public const uint32 IDI_CPSUI_ENVELOPE_FEED = 64097;
	public const uint32 IDI_CPSUI_FONTCART_SLOT = 64098;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_PORTRAIT = 64099;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_ARROWL = 64100;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_ARROWS = 64101;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_BOOKLETL = 64102;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_BOOKLETP = 64103;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_ARROWLR = 64104;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_ROT_PORT = 64105;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_BOOKLETL_NB = 64106;
	public const uint32 IDI_CPSUI_LAYOUT_BMP_BOOKLETP_NB = 64107;
	public const uint32 IDI_CPSUI_ROT_PORT = 64110;
	public const uint32 IDI_CPSUI_NUP_BORDER = 64111;
	public const uint32 IDI_CPSUI_ICONID_LAST = 64111;
	public const uint32 IDS_CPSUI_STRID_FIRST = 64700;
	public const uint32 IDS_CPSUI_SETUP = 64700;
	public const uint32 IDS_CPSUI_MORE = 64701;
	public const uint32 IDS_CPSUI_CHANGE = 64702;
	public const uint32 IDS_CPSUI_OPTION = 64703;
	public const uint32 IDS_CPSUI_OF = 64704;
	public const uint32 IDS_CPSUI_RANGE_FROM = 64705;
	public const uint32 IDS_CPSUI_TO = 64706;
	public const uint32 IDS_CPSUI_COLON_SEP = 64707;
	public const uint32 IDS_CPSUI_LEFT_ANGLE = 64708;
	public const uint32 IDS_CPSUI_RIGHT_ANGLE = 64709;
	public const uint32 IDS_CPSUI_SLASH_SEP = 64710;
	public const uint32 IDS_CPSUI_PERCENT = 64711;
	public const uint32 IDS_CPSUI_LBCB_NOSEL = 64712;
	public const uint32 IDS_CPSUI_PROPERTIES = 64713;
	public const uint32 IDS_CPSUI_DEFAULTDOCUMENT = 64714;
	public const uint32 IDS_CPSUI_DOCUMENT = 64715;
	public const uint32 IDS_CPSUI_ADVANCEDOCUMENT = 64716;
	public const uint32 IDS_CPSUI_PRINTER = 64717;
	public const uint32 IDS_CPSUI_AUTOSELECT = 64718;
	public const uint32 IDS_CPSUI_PAPER_OUTPUT = 64719;
	public const uint32 IDS_CPSUI_GRAPHIC = 64720;
	public const uint32 IDS_CPSUI_OPTIONS = 64721;
	public const uint32 IDS_CPSUI_ADVANCED = 64722;
	public const uint32 IDS_CPSUI_STDDOCPROPTAB = 64723;
	public const uint32 IDS_CPSUI_STDDOCPROPTVTAB = 64724;
	public const uint32 IDS_CPSUI_DEVICEOPTIONS = 64725;
	public const uint32 IDS_CPSUI_FALSE = 64726;
	public const uint32 IDS_CPSUI_TRUE = 64727;
	public const uint32 IDS_CPSUI_NO = 64728;
	public const uint32 IDS_CPSUI_YES = 64729;
	public const uint32 IDS_CPSUI_OFF = 64730;
	public const uint32 IDS_CPSUI_ON = 64731;
	public const uint32 IDS_CPSUI_DEFAULT = 64732;
	public const uint32 IDS_CPSUI_ERROR = 64733;
	public const uint32 IDS_CPSUI_NONE = 64734;
	public const uint32 IDS_CPSUI_NOT = 64735;
	public const uint32 IDS_CPSUI_EXIST = 64736;
	public const uint32 IDS_CPSUI_NOTINSTALLED = 64737;
	public const uint32 IDS_CPSUI_ORIENTATION = 64738;
	public const uint32 IDS_CPSUI_SCALING = 64739;
	public const uint32 IDS_CPSUI_NUM_OF_COPIES = 64740;
	public const uint32 IDS_CPSUI_SOURCE = 64741;
	public const uint32 IDS_CPSUI_PRINTQUALITY = 64742;
	public const uint32 IDS_CPSUI_RESOLUTION = 64743;
	public const uint32 IDS_CPSUI_COLOR_APPERANCE = 64744;
	public const uint32 IDS_CPSUI_DUPLEX = 64745;
	public const uint32 IDS_CPSUI_TTOPTION = 64746;
	public const uint32 IDS_CPSUI_FORMNAME = 64747;
	public const uint32 IDS_CPSUI_ICM = 64748;
	public const uint32 IDS_CPSUI_ICMMETHOD = 64749;
	public const uint32 IDS_CPSUI_ICMINTENT = 64750;
	public const uint32 IDS_CPSUI_MEDIA = 64751;
	public const uint32 IDS_CPSUI_DITHERING = 64752;
	public const uint32 IDS_CPSUI_PORTRAIT = 64753;
	public const uint32 IDS_CPSUI_LANDSCAPE = 64754;
	public const uint32 IDS_CPSUI_ROT_LAND = 64755;
	public const uint32 IDS_CPSUI_COLLATE = 64756;
	public const uint32 IDS_CPSUI_COLLATED = 64757;
	public const uint32 IDS_CPSUI_PRINTFLDSETTING = 64758;
	public const uint32 IDS_CPSUI_DRAFT = 64759;
	public const uint32 IDS_CPSUI_LOW = 64760;
	public const uint32 IDS_CPSUI_MEDIUM = 64761;
	public const uint32 IDS_CPSUI_HIGH = 64762;
	public const uint32 IDS_CPSUI_PRESENTATION = 64763;
	public const uint32 IDS_CPSUI_COLOR = 64764;
	public const uint32 IDS_CPSUI_GRAYSCALE = 64765;
	public const uint32 IDS_CPSUI_MONOCHROME = 64766;
	public const uint32 IDS_CPSUI_SIMPLEX = 64767;
	public const uint32 IDS_CPSUI_HORIZONTAL = 64768;
	public const uint32 IDS_CPSUI_VERTICAL = 64769;
	public const uint32 IDS_CPSUI_LONG_SIDE = 64770;
	public const uint32 IDS_CPSUI_SHORT_SIDE = 64771;
	public const uint32 IDS_CPSUI_TT_PRINTASGRAPHIC = 64772;
	public const uint32 IDS_CPSUI_TT_DOWNLOADSOFT = 64773;
	public const uint32 IDS_CPSUI_TT_DOWNLOADVECT = 64774;
	public const uint32 IDS_CPSUI_TT_SUBDEV = 64775;
	public const uint32 IDS_CPSUI_ICM_BLACKWHITE = 64776;
	public const uint32 IDS_CPSUI_ICM_NO = 64777;
	public const uint32 IDS_CPSUI_ICM_YES = 64778;
	public const uint32 IDS_CPSUI_ICM_SATURATION = 64779;
	public const uint32 IDS_CPSUI_ICM_CONTRAST = 64780;
	public const uint32 IDS_CPSUI_ICM_COLORMETRIC = 64781;
	public const uint32 IDS_CPSUI_STANDARD = 64782;
	public const uint32 IDS_CPSUI_GLOSSY = 64783;
	public const uint32 IDS_CPSUI_TRANSPARENCY = 64784;
	public const uint32 IDS_CPSUI_REGULAR = 64785;
	public const uint32 IDS_CPSUI_BOND = 64786;
	public const uint32 IDS_CPSUI_COARSE = 64787;
	public const uint32 IDS_CPSUI_FINE = 64788;
	public const uint32 IDS_CPSUI_LINEART = 64789;
	public const uint32 IDS_CPSUI_ERRDIFFUSE = 64790;
	public const uint32 IDS_CPSUI_HALFTONE = 64791;
	public const uint32 IDS_CPSUI_HTCLRADJ = 64792;
	public const uint32 IDS_CPSUI_USE_HOST_HT = 64793;
	public const uint32 IDS_CPSUI_USE_DEVICE_HT = 64794;
	public const uint32 IDS_CPSUI_USE_PRINTER_HT = 64795;
	public const uint32 IDS_CPSUI_OUTBINASSIGN = 64796;
	public const uint32 IDS_CPSUI_WATERMARK = 64797;
	public const uint32 IDS_CPSUI_FORMTRAYASSIGN = 64798;
	public const uint32 IDS_CPSUI_UPPER_TRAY = 64799;
	public const uint32 IDS_CPSUI_ONLYONE = 64800;
	public const uint32 IDS_CPSUI_LOWER_TRAY = 64801;
	public const uint32 IDS_CPSUI_MIDDLE_TRAY = 64802;
	public const uint32 IDS_CPSUI_MANUAL_TRAY = 64803;
	public const uint32 IDS_CPSUI_ENVELOPE_TRAY = 64804;
	public const uint32 IDS_CPSUI_ENVMANUAL_TRAY = 64805;
	public const uint32 IDS_CPSUI_TRACTOR_TRAY = 64806;
	public const uint32 IDS_CPSUI_SMALLFMT_TRAY = 64807;
	public const uint32 IDS_CPSUI_LARGEFMT_TRAY = 64808;
	public const uint32 IDS_CPSUI_LARGECAP_TRAY = 64809;
	public const uint32 IDS_CPSUI_CASSETTE_TRAY = 64810;
	public const uint32 IDS_CPSUI_DEFAULT_TRAY = 64811;
	public const uint32 IDS_CPSUI_FORMSOURCE = 64812;
	public const uint32 IDS_CPSUI_MANUALFEED = 64813;
	public const uint32 IDS_CPSUI_PRINTERMEM_KB = 64814;
	public const uint32 IDS_CPSUI_PRINTERMEM_MB = 64815;
	public const uint32 IDS_CPSUI_PAGEPROTECT = 64816;
	public const uint32 IDS_CPSUI_HALFTONE_SETUP = 64817;
	public const uint32 IDS_CPSUI_INSTFONTCART = 64818;
	public const uint32 IDS_CPSUI_SLOT1 = 64819;
	public const uint32 IDS_CPSUI_SLOT2 = 64820;
	public const uint32 IDS_CPSUI_SLOT3 = 64821;
	public const uint32 IDS_CPSUI_SLOT4 = 64822;
	public const uint32 IDS_CPSUI_LEFT_SLOT = 64823;
	public const uint32 IDS_CPSUI_RIGHT_SLOT = 64824;
	public const uint32 IDS_CPSUI_STAPLER = 64825;
	public const uint32 IDS_CPSUI_STAPLER_ON = 64826;
	public const uint32 IDS_CPSUI_STAPLER_OFF = 64827;
	public const uint32 IDS_CPSUI_STACKER = 64828;
	public const uint32 IDS_CPSUI_MAILBOX = 64829;
	public const uint32 IDS_CPSUI_COPY = 64830;
	public const uint32 IDS_CPSUI_COPIES = 64831;
	public const uint32 IDS_CPSUI_TOTAL = 64832;
	public const uint32 IDS_CPSUI_MAKE = 64833;
	public const uint32 IDS_CPSUI_PRINT = 64834;
	public const uint32 IDS_CPSUI_FAX = 64835;
	public const uint32 IDS_CPSUI_PLOT = 64836;
	public const uint32 IDS_CPSUI_SLOW = 64837;
	public const uint32 IDS_CPSUI_FAST = 64838;
	public const uint32 IDS_CPSUI_ROTATED = 64839;
	public const uint32 IDS_CPSUI_RESET = 64840;
	public const uint32 IDS_CPSUI_ALL = 64841;
	public const uint32 IDS_CPSUI_DEVICE = 64842;
	public const uint32 IDS_CPSUI_SETTINGS = 64843;
	public const uint32 IDS_CPSUI_REVERT = 64844;
	public const uint32 IDS_CPSUI_CHANGES = 64845;
	public const uint32 IDS_CPSUI_CHANGED = 64846;
	public const uint32 IDS_CPSUI_WARNING = 64847;
	public const uint32 IDS_CPSUI_ABOUT = 64848;
	public const uint32 IDS_CPSUI_VERSION = 64849;
	public const uint32 IDS_CPSUI_NO_NAME = 64850;
	public const uint32 IDS_CPSUI_SETTING = 64851;
	public const uint32 IDS_CPSUI_DEVICE_SETTINGS = 64852;
	public const uint32 IDS_CPSUI_STDDOCPROPTAB1 = 64853;
	public const uint32 IDS_CPSUI_STDDOCPROPTAB2 = 64854;
	public const uint32 IDS_CPSUI_PAGEORDER = 64855;
	public const uint32 IDS_CPSUI_FRONTTOBACK = 64856;
	public const uint32 IDS_CPSUI_BACKTOFRONT = 64857;
	public const uint32 IDS_CPSUI_QUALITY_SETTINGS = 64858;
	public const uint32 IDS_CPSUI_QUALITY_DRAFT = 64859;
	public const uint32 IDS_CPSUI_QUALITY_BETTER = 64860;
	public const uint32 IDS_CPSUI_QUALITY_BEST = 64861;
	public const uint32 IDS_CPSUI_QUALITY_CUSTOM = 64862;
	public const uint32 IDS_CPSUI_OUTPUTBIN = 64863;
	public const uint32 IDS_CPSUI_NUP = 64864;
	public const uint32 IDS_CPSUI_NUP_NORMAL = 64865;
	public const uint32 IDS_CPSUI_NUP_TWOUP = 64866;
	public const uint32 IDS_CPSUI_NUP_FOURUP = 64867;
	public const uint32 IDS_CPSUI_NUP_SIXUP = 64868;
	public const uint32 IDS_CPSUI_NUP_NINEUP = 64869;
	public const uint32 IDS_CPSUI_NUP_SIXTEENUP = 64870;
	public const uint32 IDS_CPSUI_SIDE1 = 64871;
	public const uint32 IDS_CPSUI_SIDE2 = 64872;
	public const uint32 IDS_CPSUI_BOOKLET = 64873;
	public const uint32 IDS_CPSUI_POSTER = 64874;
	public const uint32 IDS_CPSUI_POSTER_2x2 = 64875;
	public const uint32 IDS_CPSUI_POSTER_3x3 = 64876;
	public const uint32 IDS_CPSUI_POSTER_4x4 = 64877;
	public const uint32 IDS_CPSUI_NUP_DIRECTION = 64878;
	public const uint32 IDS_CPSUI_RIGHT_THEN_DOWN = 64879;
	public const uint32 IDS_CPSUI_DOWN_THEN_RIGHT = 64880;
	public const uint32 IDS_CPSUI_LEFT_THEN_DOWN = 64881;
	public const uint32 IDS_CPSUI_DOWN_THEN_LEFT = 64882;
	public const uint32 IDS_CPSUI_MANUAL_DUPLEX = 64883;
	public const uint32 IDS_CPSUI_MANUAL_DUPLEX_ON = 64884;
	public const uint32 IDS_CPSUI_MANUAL_DUPLEX_OFF = 64885;
	public const uint32 IDS_CPSUI_ROT_PORT = 64886;
	public const uint32 IDS_CPSUI_STAPLE = 64887;
	public const uint32 IDS_CPSUI_BOOKLET_EDGE = 64888;
	public const uint32 IDS_CPSUI_BOOKLET_EDGE_LEFT = 64889;
	public const uint32 IDS_CPSUI_BOOKLET_EDGE_RIGHT = 64890;
	public const uint32 IDS_CPSUI_NUP_BORDER = 64891;
	public const uint32 IDS_CPSUI_NUP_BORDERED = 64892;
	public const uint32 IDS_CPSUI_STRID_LAST = 64892;
	public const String XPS_FP_PRINTER_NAME = "PrinterName";
	public const String XPS_FP_PROGRESS_REPORT = "ProgressReport";
	public const String XPS_FP_PRINTER_HANDLE = "PrinterHandle";
	public const String XPS_FP_USER_PRINT_TICKET = "PerUserPrintTicket";
	public const String XPS_FP_USER_TOKEN = "UserSecurityToken";
	public const String XPS_FP_JOB_ID = "PrintJobId";
	public const String XPS_FP_PRINT_CLASS_FACTORY = "PrintClassFactory";
	public const String XPS_FP_OUTPUT_FILE = "PrintOutputFileName";
	public const String XPS_FP_MS_CONTENT_TYPE = "DriverMultiContentType";
	public const String XPS_FP_MS_CONTENT_TYPE_XPS = "XPS";
	public const String XPS_FP_MS_CONTENT_TYPE_OPENXPS = "OpenXPS";
	public const String XPS_FP_DRIVER_PROPERTY_BAG = "DriverPropertyBag";
	public const String XPS_FP_QUEUE_PROPERTY_BAG = "QueuePropertyBag";
	public const String XPS_FP_MERGED_DATAFILE_PATH = "MergedDataFilePath";
	public const String XPS_FP_RESOURCE_DLL_PATHS = "ResourceDLLPaths";
	public const String XPS_FP_JOB_LEVEL_PRINTTICKET = "JobPrintTicket";
	public const String XPS_FP_PRINTDEVICECAPABILITIES = "PrintDeviceCapabilities";
	public const uint32 MXDC_ESCAPE = 4122;
	public const uint32 MXDCOP_GET_FILENAME = 14;
	public const uint32 MXDCOP_PRINTTICKET_FIXED_DOC_SEQ = 22;
	public const uint32 MXDCOP_PRINTTICKET_FIXED_DOC = 24;
	public const uint32 MXDCOP_PRINTTICKET_FIXED_PAGE = 26;
	public const uint32 MXDCOP_SET_S0PAGE = 28;
	public const uint32 MXDCOP_SET_S0PAGE_RESOURCE = 30;
	public const uint32 MXDCOP_SET_XPSPASSTHRU_MODE = 32;
	public const Guid CLSID_OEMRENDER = .(0x6d6abf26, 0x9f38, 0x11d1, 0x88, 0x2a, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0xec);
	public const Guid CLSID_OEMUI = .(0xabce80d7, 0x9f46, 0x11d1, 0x88, 0x2a, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0xec);
	public const Guid CLSID_OEMUIMXDC = .(0x4e144300, 0x5b43, 0x4288, 0x93, 0x2a, 0x5e, 0x4d, 0xd6, 0xd8, 0x2b, 0xed);
	public const Guid CLSID_OEMPTPROVIDER = .(0x91723892, 0x45d2, 0x48e2, 0x9e, 0xc9, 0x56, 0x23, 0x79, 0xda, 0xf9, 0x92);
	public const HRESULT S_DEVCAP_OUTPUT_FULL_REPLACEMENT = 318465;
	public const Guid CLSID_PTPROVIDER = .(0x46ac151b, 0x8490, 0x4531, 0x96, 0xcc, 0x55, 0xbf, 0x2b, 0xf1, 0x9e, 0x11);
	public const uint32 E_VERSION_NOT_SUPPORTED = 2147745793;
	public const uint32 S_NO_CONFLICT = 262145;
	public const uint32 S_CONFLICT_RESOLVED = 262146;
	public const Guid PRINTER_EXTENSION_DETAILEDREASON_PRINTER_STATUS = .(0x5d5a1704, 0xdfd1, 0x4181, 0x8e, 0xee, 0x81, 0x5c, 0x86, 0xed, 0xad, 0x31);
	public const Guid PRINTER_EXTENSION_REASON_PRINT_PREFERENCES = .(0xec8f261f, 0x267c, 0x469f, 0xb5, 0xd6, 0x39, 0x33, 0x02, 0x3c, 0x29, 0xcc);
	public const Guid PRINTER_EXTENSION_REASON_DRIVER_EVENT = .(0x23bb1328, 0x63de, 0x4293, 0x91, 0x5b, 0xa6, 0xa2, 0x3d, 0x92, 0x9a, 0xcb);
	public const Guid FMTID_PrinterPropertyBag = .(0x75f9adca, 0x097d, 0x45c3, 0xa6, 0xe4, 0xba, 0xb2, 0x9e, 0x27, 0x6f, 0x3e);
	public const uint32 PRINTER_OEMINTF_VERSION = 65536;
	public const uint32 OEM_MODE_PUBLISHER = 1;
	public const uint32 OEMGI_GETSIGNATURE = 1;
	public const uint32 OEMGI_GETINTERFACEVERSION = 2;
	public const uint32 OEMGI_GETVERSION = 3;
	public const uint32 OEMGI_GETPUBLISHERINFO = 4;
	public const uint32 OEMGI_GETREQUESTEDHELPERINTERFACES = 5;
	public const uint32 OEMPUBLISH_DEFAULT = 0;
	public const uint32 OEMPUBLISH_IPRINTCOREHELPER = 1;
	public const uint32 OEMDM_SIZE = 1;
	public const uint32 OEMDM_DEFAULT = 2;
	public const uint32 OEMDM_CONVERT = 3;
	public const uint32 OEMDM_MERGE = 4;
	public const uint32 OEMGDS_MIN_DOCSTICKY = 1;
	public const uint32 OEMGDS_PSDM_FLAGS = 1;
	public const uint32 OEMGDS_PSDM_DIALECT = 2;
	public const uint32 OEMGDS_PSDM_TTDLFMT = 3;
	public const uint32 OEMGDS_PSDM_NUP = 4;
	public const uint32 OEMGDS_PSDM_PSLEVEL = 5;
	public const uint32 OEMGDS_PSDM_CUSTOMSIZE = 6;
	public const uint32 OEMGDS_UNIDM_GPDVER = 16384;
	public const uint32 OEMGDS_UNIDM_FLAGS = 16385;
	public const uint32 OEMGDS_MIN_PRINTERSTICKY = 32768;
	public const uint32 OEMGDS_PRINTFLAGS = 32768;
	public const uint32 OEMGDS_FREEMEM = 32769;
	public const uint32 OEMGDS_JOBTIMEOUT = 32770;
	public const uint32 OEMGDS_WAITTIMEOUT = 32771;
	public const uint32 OEMGDS_PROTOCOL = 32772;
	public const uint32 OEMGDS_MINOUTLINE = 32773;
	public const uint32 OEMGDS_MAXBITMAP = 32774;
	public const uint32 OEMGDS_MAX = 65536;
	public const uint32 GPD_OEMCUSTOMDATA = 1;
	public const uint32 MV_UPDATE = 1;
	public const uint32 MV_RELATIVE = 2;
	public const uint32 MV_GRAPHICS = 4;
	public const uint32 MV_PHYSICAL = 8;
	public const uint32 MV_SENDXMOVECMD = 16;
	public const uint32 MV_SENDYMOVECMD = 32;
	public const uint32 OEMTTY_INFO_MARGINS = 1;
	public const uint32 OEMTTY_INFO_CODEPAGE = 2;
	public const uint32 OEMTTY_INFO_NUM_UFMS = 3;
	public const uint32 OEMTTY_INFO_UFM_IDS = 4;
	public const uint32 UFOFLAG_TTFONT = 1;
	public const uint32 UFOFLAG_TTDOWNLOAD_BITMAP = 2;
	public const uint32 UFOFLAG_TTDOWNLOAD_TTOUTLINE = 4;
	public const uint32 UFOFLAG_TTOUTLINE_BOLD_SIM = 8;
	public const uint32 UFOFLAG_TTOUTLINE_ITALIC_SIM = 16;
	public const uint32 UFOFLAG_TTOUTLINE_VERTICAL = 32;
	public const uint32 UFOFLAG_TTSUBSTITUTED = 64;
	public const uint32 UFO_GETINFO_FONTOBJ = 1;
	public const uint32 UFO_GETINFO_GLYPHSTRING = 2;
	public const uint32 UFO_GETINFO_GLYPHBITMAP = 3;
	public const uint32 UFO_GETINFO_GLYPHWIDTH = 4;
	public const uint32 UFO_GETINFO_MEMORY = 5;
	public const uint32 UFO_GETINFO_STDVARIABLE = 6;
	public const uint32 FNT_INFO_PRINTDIRINCCDEGREES = 0;
	public const uint32 FNT_INFO_GRAYPERCENTAGE = 1;
	public const uint32 FNT_INFO_NEXTFONTID = 2;
	public const uint32 FNT_INFO_NEXTGLYPH = 3;
	public const uint32 FNT_INFO_FONTHEIGHT = 4;
	public const uint32 FNT_INFO_FONTWIDTH = 5;
	public const uint32 FNT_INFO_FONTBOLD = 6;
	public const uint32 FNT_INFO_FONTITALIC = 7;
	public const uint32 FNT_INFO_FONTUNDERLINE = 8;
	public const uint32 FNT_INFO_FONTSTRIKETHRU = 9;
	public const uint32 FNT_INFO_CURRENTFONTID = 10;
	public const uint32 FNT_INFO_TEXTYRES = 11;
	public const uint32 FNT_INFO_TEXTXRES = 12;
	public const uint32 FNT_INFO_FONTMAXWIDTH = 13;
	public const uint32 FNT_INFO_MAX = 14;
	public const uint32 TTDOWNLOAD_DONTCARE = 0;
	public const uint32 TTDOWNLOAD_GRAPHICS = 1;
	public const uint32 TTDOWNLOAD_BITMAP = 2;
	public const uint32 TTDOWNLOAD_TTOUTLINE = 3;
	public const uint32 TYPE_UNICODE = 1;
	public const uint32 TYPE_TRANSDATA = 2;
	public const uint32 TYPE_GLYPHHANDLE = 3;
	public const uint32 TYPE_GLYPHID = 4;
	public const uint32 PDEV_ADJUST_PAPER_MARGIN_TYPE = 1;
	public const uint32 PDEV_HOSTFONT_ENABLED_TYPE = 2;
	public const uint32 PDEV_USE_TRUE_COLOR_TYPE = 3;
	public const uint32 OEMCUIP_DOCPROP = 1;
	public const uint32 OEMCUIP_PRNPROP = 2;
	public const uint32 CUSTOMPARAM_WIDTH = 0;
	public const uint32 CUSTOMPARAM_HEIGHT = 1;
	public const uint32 CUSTOMPARAM_WIDTHOFFSET = 2;
	public const uint32 CUSTOMPARAM_HEIGHTOFFSET = 3;
	public const uint32 CUSTOMPARAM_ORIENTATION = 4;
	public const uint32 CUSTOMPARAM_MAX = 5;
	public const uint32 SETOPTIONS_FLAG_RESOLVE_CONFLICT = 1;
	public const uint32 SETOPTIONS_FLAG_KEEP_CONFLICT = 2;
	public const uint32 SETOPTIONS_RESULT_NO_CONFLICT = 0;
	public const uint32 SETOPTIONS_RESULT_CONFLICT_RESOLVED = 1;
	public const uint32 SETOPTIONS_RESULT_CONFLICT_REMAINED = 2;
	public const uint32 UNIFM_VERSION_1_0 = 65536;
	public const uint32 UFM_SOFT = 1;
	public const uint32 UFM_CART = 2;
	public const uint32 UFM_SCALABLE = 4;
	public const uint32 DF_TYPE_HPINTELLIFONT = 0;
	public const uint32 DF_TYPE_TRUETYPE = 1;
	public const uint32 DF_TYPE_PST1 = 2;
	public const uint32 DF_TYPE_CAPSL = 3;
	public const uint32 DF_TYPE_OEM1 = 4;
	public const uint32 DF_TYPE_OEM2 = 5;
	public const uint32 DF_NOITALIC = 1;
	public const uint32 DF_NOUNDER = 2;
	public const uint32 DF_XM_CR = 4;
	public const uint32 DF_NO_BOLD = 8;
	public const uint32 DF_NO_DOUBLE_UNDERLINE = 16;
	public const uint32 DF_NO_STRIKETHRU = 32;
	public const uint32 DF_BKSP_OK = 64;
	public const uint32 UNI_GLYPHSETDATA_VERSION_1_0 = 65536;
	public const uint32 MTYPE_FORMAT_MASK = 7;
	public const uint32 MTYPE_COMPOSE = 1;
	public const uint32 MTYPE_DIRECT = 2;
	public const uint32 MTYPE_PAIRED = 4;
	public const uint32 MTYPE_DOUBLEBYTECHAR_MASK = 24;
	public const uint32 MTYPE_SINGLE = 8;
	public const uint32 MTYPE_DOUBLE = 16;
	public const uint32 MTYPE_PREDEFIN_MASK = 224;
	public const uint32 MTYPE_REPLACE = 32;
	public const uint32 MTYPE_ADD = 64;
	public const uint32 MTYPE_DISABLE = 128;
	public const uint32 CC_NOPRECNV = 65535;
	public const uint32 CC_DEFAULT = 0;
	public const int32 CC_CP437 = -1;
	public const int32 CC_CP850 = -2;
	public const int32 CC_CP863 = -3;
	public const int32 CC_BIG5 = -10;
	public const int32 CC_ISC = -11;
	public const int32 CC_JIS = -12;
	public const int32 CC_JIS_ANK = -13;
	public const int32 CC_NS86 = -14;
	public const int32 CC_TCA = -15;
	public const int32 CC_GB2312 = -16;
	public const int32 CC_SJIS = -17;
	public const int32 CC_WANSUNG = -18;
	public const uint32 UFF_VERSION_NUMBER = 65537;
	public const uint32 FONT_DIR_SORTED = 1;
	public const uint32 FONT_FL_UFM = 1;
	public const uint32 FONT_FL_IFI = 2;
	public const uint32 FONT_FL_SOFTFONT = 4;
	public const uint32 FONT_FL_PERMANENT_SF = 8;
	public const uint32 FONT_FL_DEVICEFONT = 16;
	public const uint32 FONT_FL_GLYPHSET_GTT = 32;
	public const uint32 FONT_FL_GLYPHSET_RLE = 64;
	public const uint32 FONT_FL_RESERVED = 32768;
	public const uint32 FG_CANCHANGE = 128;
	public const uint32 WM_FI_FILENAME = 900;
	public const uint32 UNKNOWN_PROTOCOL = 0;
	public const uint32 PROTOCOL_UNKNOWN_TYPE = 0;
	public const uint32 RAWTCP = 1;
	public const uint32 PROTOCOL_RAWTCP_TYPE = 1;
	public const uint32 LPR = 2;
	public const uint32 PROTOCOL_LPR_TYPE = 2;
	public const uint32 MAX_PORTNAME_LEN = 64;
	public const uint32 MAX_NETWORKNAME_LEN = 49;
	public const uint32 MAX_NETWORKNAME2_LEN = 128;
	public const uint32 MAX_SNMP_COMMUNITY_STR_LEN = 33;
	public const uint32 MAX_QUEUENAME_LEN = 33;
	public const uint32 MAX_IPADDR_STR_LEN = 16;
	public const uint32 MAX_ADDRESS_STR_LEN = 13;
	public const uint32 MAX_DEVICEDESCRIPTION_STR_LEN = 257;
	public const uint32 DPS_NOPERMISSION = 1;
	public const uint32 DM_ADVANCED = 16;
	public const uint32 DM_NOPERMISSION = 32;
	public const uint32 DM_USER_DEFAULT = 64;
	public const uint32 DM_PROMPT_NON_MODAL = 1073741824;
	public const uint32 DM_INVALIDATE_DRIVER_CACHE = 536870912;
	public const uint32 DM_RESERVED = 2147483648;
	public const uint32 CDM_CONVERT = 1;
	public const uint32 CDM_CONVERT351 = 2;
	public const uint32 CDM_DRIVER_DEFAULT = 4;
	public const uint32 DOCUMENTEVENT_FIRST = 1;
	public const uint32 DOCUMENTEVENT_CREATEDCPRE = 1;
	public const uint32 DOCUMENTEVENT_CREATEDCPOST = 2;
	public const uint32 DOCUMENTEVENT_RESETDCPRE = 3;
	public const uint32 DOCUMENTEVENT_RESETDCPOST = 4;
	public const uint32 DOCUMENTEVENT_STARTDOC = 5;
	public const uint32 DOCUMENTEVENT_STARTDOCPRE = 5;
	public const uint32 DOCUMENTEVENT_STARTPAGE = 6;
	public const uint32 DOCUMENTEVENT_ENDPAGE = 7;
	public const uint32 DOCUMENTEVENT_ENDDOC = 8;
	public const uint32 DOCUMENTEVENT_ENDDOCPRE = 8;
	public const uint32 DOCUMENTEVENT_ABORTDOC = 9;
	public const uint32 DOCUMENTEVENT_DELETEDC = 10;
	public const uint32 DOCUMENTEVENT_ESCAPE = 11;
	public const uint32 DOCUMENTEVENT_ENDDOCPOST = 12;
	public const uint32 DOCUMENTEVENT_STARTDOCPOST = 13;
	public const uint32 DOCUMENTEVENT_QUERYFILTER = 14;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTSEQUENCEPRE = 1;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTPRE = 2;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDPAGEEPRE = 3;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDPAGEPOST = 4;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTPOST = 5;
	public const uint32 DOCUMENTEVENT_XPS_CANCELJOB = 6;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTSEQUENCEPRINTTICKETPRE = 7;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTPRINTTICKETPRE = 8;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDPAGEPRINTTICKETPRE = 9;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDPAGEPRINTTICKETPOST = 10;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTPRINTTICKETPOST = 11;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTSEQUENCEPRINTTICKETPOST = 12;
	public const uint32 DOCUMENTEVENT_XPS_ADDFIXEDDOCUMENTSEQUENCEPOST = 13;
	public const uint32 DOCUMENTEVENT_LAST = 15;
	public const uint32 DOCUMENTEVENT_SPOOLED = 65536;
	public const uint32 DOCUMENTEVENT_SUCCESS = 1;
	public const uint32 DOCUMENTEVENT_UNSUPPORTED = 0;
	public const int32 DOCUMENTEVENT_FAILURE = -1;
	public const uint32 PRINTER_EVENT_CONFIGURATION_CHANGE = 0;
	public const uint32 PRINTER_EVENT_ADD_CONNECTION = 1;
	public const uint32 PRINTER_EVENT_DELETE_CONNECTION = 2;
	public const uint32 PRINTER_EVENT_INITIALIZE = 3;
	public const uint32 PRINTER_EVENT_DELETE = 4;
	public const uint32 PRINTER_EVENT_CACHE_REFRESH = 5;
	public const uint32 PRINTER_EVENT_CACHE_DELETE = 6;
	public const uint32 PRINTER_EVENT_ATTRIBUTES_CHANGED = 7;
	public const uint32 PRINTER_EVENT_CONFIGURATION_UPDATE = 8;
	public const uint32 PRINTER_EVENT_ADD_CONNECTION_NO_UI = 9;
	public const uint32 PRINTER_EVENT_DELETE_CONNECTION_NO_UI = 10;
	public const uint32 PRINTER_EVENT_FLAG_NO_UI = 1;
	public const uint32 DRIVER_EVENT_INITIALIZE = 1;
	public const uint32 DRIVER_EVENT_DELETE = 2;
	public const uint32 BORDER_PRINT = 0;
	public const uint32 NO_BORDER_PRINT = 1;
	public const uint32 NORMAL_PRINT = 0;
	public const uint32 REVERSE_PRINT = 1;
	public const uint32 BOOKLET_PRINT = 2;
	public const uint32 NO_COLOR_OPTIMIZATION = 0;
	public const uint32 COLOR_OPTIMIZATION = 1;
	public const uint32 REVERSE_PAGES_FOR_REVERSE_DUPLEX = 1;
	public const uint32 RIGHT_THEN_DOWN = 1;
	public const uint32 BOOKLET_EDGE_LEFT = 0;
	public const uint32 BOOKLET_EDGE_RIGHT = 1;
	public const uint32 QCP_DEVICEPROFILE = 0;
	public const uint32 QCP_SOURCEPROFILE = 1;
	public const uint32 QCP_PROFILEMEMORY = 1;
	public const uint32 QCP_PROFILEDISK = 2;
	public const String SPLPRINTER_USER_MODE_PRINTER_DRIVER = "SPLUserModePrinterDriver";
	public const uint32 EMF_PP_COLOR_OPTIMIZATION = 1;
	public const uint32 PRINTER_NOTIFY_STATUS_ENDPOINT = 1;
	public const uint32 PRINTER_NOTIFY_STATUS_POLL = 2;
	public const uint32 PRINTER_NOTIFY_STATUS_INFO = 4;
	public const uint32 ROUTER_UNKNOWN = 0;
	public const uint32 ROUTER_SUCCESS = 1;
	public const uint32 ROUTER_STOP_ROUTING = 2;
	public const uint32 FILL_WITH_DEFAULTS = 1;
	public const uint32 PRINTER_NOTIFY_INFO_DATA_COMPACT = 1;
	public const uint32 COPYFILE_EVENT_SET_PRINTER_DATAEX = 1;
	public const uint32 COPYFILE_EVENT_DELETE_PRINTER = 2;
	public const uint32 COPYFILE_EVENT_ADD_PRINTER_CONNECTION = 3;
	public const uint32 COPYFILE_EVENT_DELETE_PRINTER_CONNECTION = 4;
	public const uint32 COPYFILE_EVENT_FILES_CHANGED = 5;
	public const uint32 COPYFILE_FLAG_CLIENT_SPOOLER = 1;
	public const uint32 COPYFILE_FLAG_SERVER_SPOOLER = 2;
	public const uint32 DSPRINT_PUBLISH = 1;
	public const uint32 DSPRINT_UPDATE = 2;
	public const uint32 DSPRINT_UNPUBLISH = 4;
	public const uint32 DSPRINT_REPUBLISH = 8;
	public const uint32 DSPRINT_PENDING = 2147483648;
	public const uint32 PRINTER_CONTROL_PAUSE = 1;
	public const uint32 PRINTER_CONTROL_RESUME = 2;
	public const uint32 PRINTER_CONTROL_PURGE = 3;
	public const uint32 PRINTER_CONTROL_SET_STATUS = 4;
	public const uint32 PRINTER_STATUS_PAUSED = 1;
	public const uint32 PRINTER_STATUS_ERROR = 2;
	public const uint32 PRINTER_STATUS_PENDING_DELETION = 4;
	public const uint32 PRINTER_STATUS_PAPER_JAM = 8;
	public const uint32 PRINTER_STATUS_PAPER_OUT = 16;
	public const uint32 PRINTER_STATUS_MANUAL_FEED = 32;
	public const uint32 PRINTER_STATUS_PAPER_PROBLEM = 64;
	public const uint32 PRINTER_STATUS_OFFLINE = 128;
	public const uint32 PRINTER_STATUS_IO_ACTIVE = 256;
	public const uint32 PRINTER_STATUS_BUSY = 512;
	public const uint32 PRINTER_STATUS_PRINTING = 1024;
	public const uint32 PRINTER_STATUS_OUTPUT_BIN_FULL = 2048;
	public const uint32 PRINTER_STATUS_NOT_AVAILABLE = 4096;
	public const uint32 PRINTER_STATUS_WAITING = 8192;
	public const uint32 PRINTER_STATUS_PROCESSING = 16384;
	public const uint32 PRINTER_STATUS_INITIALIZING = 32768;
	public const uint32 PRINTER_STATUS_WARMING_UP = 65536;
	public const uint32 PRINTER_STATUS_TONER_LOW = 131072;
	public const uint32 PRINTER_STATUS_NO_TONER = 262144;
	public const uint32 PRINTER_STATUS_PAGE_PUNT = 524288;
	public const uint32 PRINTER_STATUS_USER_INTERVENTION = 1048576;
	public const uint32 PRINTER_STATUS_OUT_OF_MEMORY = 2097152;
	public const uint32 PRINTER_STATUS_DOOR_OPEN = 4194304;
	public const uint32 PRINTER_STATUS_SERVER_UNKNOWN = 8388608;
	public const uint32 PRINTER_STATUS_POWER_SAVE = 16777216;
	public const uint32 PRINTER_STATUS_SERVER_OFFLINE = 33554432;
	public const uint32 PRINTER_STATUS_DRIVER_UPDATE_NEEDED = 67108864;
	public const uint32 PRINTER_ATTRIBUTE_QUEUED = 1;
	public const uint32 PRINTER_ATTRIBUTE_DIRECT = 2;
	public const uint32 PRINTER_ATTRIBUTE_DEFAULT = 4;
	public const uint32 PRINTER_ATTRIBUTE_SHARED = 8;
	public const uint32 PRINTER_ATTRIBUTE_NETWORK = 16;
	public const uint32 PRINTER_ATTRIBUTE_HIDDEN = 32;
	public const uint32 PRINTER_ATTRIBUTE_LOCAL = 64;
	public const uint32 PRINTER_ATTRIBUTE_ENABLE_DEVQ = 128;
	public const uint32 PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS = 256;
	public const uint32 PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST = 512;
	public const uint32 PRINTER_ATTRIBUTE_WORK_OFFLINE = 1024;
	public const uint32 PRINTER_ATTRIBUTE_ENABLE_BIDI = 2048;
	public const uint32 PRINTER_ATTRIBUTE_RAW_ONLY = 4096;
	public const uint32 PRINTER_ATTRIBUTE_PUBLISHED = 8192;
	public const uint32 PRINTER_ATTRIBUTE_FAX = 16384;
	public const uint32 PRINTER_ATTRIBUTE_TS = 32768;
	public const uint32 PRINTER_ATTRIBUTE_PUSHED_USER = 131072;
	public const uint32 PRINTER_ATTRIBUTE_PUSHED_MACHINE = 262144;
	public const uint32 PRINTER_ATTRIBUTE_MACHINE = 524288;
	public const uint32 PRINTER_ATTRIBUTE_FRIENDLY_NAME = 1048576;
	public const uint32 PRINTER_ATTRIBUTE_TS_GENERIC_DRIVER = 2097152;
	public const uint32 PRINTER_ATTRIBUTE_PER_USER = 4194304;
	public const uint32 PRINTER_ATTRIBUTE_ENTERPRISE_CLOUD = 8388608;
	public const uint32 NO_PRIORITY = 0;
	public const uint32 MAX_PRIORITY = 99;
	public const uint32 MIN_PRIORITY = 1;
	public const uint32 DEF_PRIORITY = 1;
	public const uint32 JOB_CONTROL_PAUSE = 1;
	public const uint32 JOB_CONTROL_RESUME = 2;
	public const uint32 JOB_CONTROL_CANCEL = 3;
	public const uint32 JOB_CONTROL_RESTART = 4;
	public const uint32 JOB_CONTROL_DELETE = 5;
	public const uint32 JOB_CONTROL_SENT_TO_PRINTER = 6;
	public const uint32 JOB_CONTROL_LAST_PAGE_EJECTED = 7;
	public const uint32 JOB_CONTROL_RETAIN = 8;
	public const uint32 JOB_CONTROL_RELEASE = 9;
	public const uint32 JOB_STATUS_PAUSED = 1;
	public const uint32 JOB_STATUS_ERROR = 2;
	public const uint32 JOB_STATUS_DELETING = 4;
	public const uint32 JOB_STATUS_SPOOLING = 8;
	public const uint32 JOB_STATUS_PRINTING = 16;
	public const uint32 JOB_STATUS_OFFLINE = 32;
	public const uint32 JOB_STATUS_PAPEROUT = 64;
	public const uint32 JOB_STATUS_PRINTED = 128;
	public const uint32 JOB_STATUS_DELETED = 256;
	public const uint32 JOB_STATUS_BLOCKED_DEVQ = 512;
	public const uint32 JOB_STATUS_USER_INTERVENTION = 1024;
	public const uint32 JOB_STATUS_RESTART = 2048;
	public const uint32 JOB_STATUS_COMPLETE = 4096;
	public const uint32 JOB_STATUS_RETAINED = 8192;
	public const uint32 JOB_STATUS_RENDERING_LOCALLY = 16384;
	public const uint32 JOB_POSITION_UNSPECIFIED = 0;
	public const uint32 PRINTER_DRIVER_PACKAGE_AWARE = 1;
	public const uint32 PRINTER_DRIVER_XPS = 2;
	public const uint32 PRINTER_DRIVER_SANDBOX_ENABLED = 4;
	public const uint32 PRINTER_DRIVER_CLASS = 8;
	public const uint32 PRINTER_DRIVER_DERIVED = 16;
	public const uint32 PRINTER_DRIVER_NOT_SHAREABLE = 32;
	public const uint32 PRINTER_DRIVER_CATEGORY_FAX = 64;
	public const uint32 PRINTER_DRIVER_CATEGORY_FILE = 128;
	public const uint32 PRINTER_DRIVER_CATEGORY_VIRTUAL = 256;
	public const uint32 PRINTER_DRIVER_CATEGORY_SERVICE = 512;
	public const uint32 PRINTER_DRIVER_SOFT_RESET_REQUIRED = 1024;
	public const uint32 PRINTER_DRIVER_SANDBOX_DISABLED = 2048;
	public const uint32 PRINTER_DRIVER_CATEGORY_3D = 4096;
	public const uint32 PRINTER_DRIVER_CATEGORY_CLOUD = 8192;
	public const uint32 DRIVER_KERNELMODE = 1;
	public const uint32 DRIVER_USERMODE = 2;
	public const uint32 DPD_DELETE_UNUSED_FILES = 1;
	public const uint32 DPD_DELETE_SPECIFIC_VERSION = 2;
	public const uint32 DPD_DELETE_ALL_FILES = 4;
	public const uint32 APD_STRICT_UPGRADE = 1;
	public const uint32 APD_STRICT_DOWNGRADE = 2;
	public const uint32 APD_COPY_ALL_FILES = 4;
	public const uint32 APD_COPY_NEW_FILES = 8;
	public const uint32 APD_COPY_FROM_DIRECTORY = 16;
	public const uint32 STRING_NONE = 1;
	public const uint32 STRING_MUIDLL = 2;
	public const uint32 STRING_LANGPAIR = 4;
	public const uint32 MAX_FORM_KEYWORD_LENGTH = 64;
	public const uint32 DI_CHANNEL = 1;
	public const uint32 DI_READ_SPOOL_JOB = 3;
	public const uint32 DI_MEMORYMAP_WRITE = 1;
	public const uint32 FORM_USER = 0;
	public const uint32 FORM_BUILTIN = 1;
	public const uint32 FORM_PRINTER = 2;
	public const uint32 PPCAPS_RIGHT_THEN_DOWN = 1;
	public const uint32 PPCAPS_BORDER_PRINT = 1;
	public const uint32 PPCAPS_BOOKLET_EDGE = 1;
	public const uint32 PPCAPS_REVERSE_PAGES_FOR_REVERSE_DUPLEX = 1;
	public const uint32 PPCAPS_SQUARE_SCALING = 1;
	public const uint32 PORT_TYPE_WRITE = 1;
	public const uint32 PORT_TYPE_READ = 2;
	public const uint32 PORT_TYPE_REDIRECTED = 4;
	public const uint32 PORT_TYPE_NET_ATTACHED = 8;
	public const uint32 PORT_STATUS_TYPE_ERROR = 1;
	public const uint32 PORT_STATUS_TYPE_WARNING = 2;
	public const uint32 PORT_STATUS_TYPE_INFO = 3;
	public const uint32 PORT_STATUS_OFFLINE = 1;
	public const uint32 PORT_STATUS_PAPER_JAM = 2;
	public const uint32 PORT_STATUS_PAPER_OUT = 3;
	public const uint32 PORT_STATUS_OUTPUT_BIN_FULL = 4;
	public const uint32 PORT_STATUS_PAPER_PROBLEM = 5;
	public const uint32 PORT_STATUS_NO_TONER = 6;
	public const uint32 PORT_STATUS_DOOR_OPEN = 7;
	public const uint32 PORT_STATUS_USER_INTERVENTION = 8;
	public const uint32 PORT_STATUS_OUT_OF_MEMORY = 9;
	public const uint32 PORT_STATUS_TONER_LOW = 10;
	public const uint32 PORT_STATUS_WARMING_UP = 11;
	public const uint32 PORT_STATUS_POWER_SAVE = 12;
	public const uint32 PRINTER_ENUM_DEFAULT = 1;
	public const uint32 PRINTER_ENUM_LOCAL = 2;
	public const uint32 PRINTER_ENUM_CONNECTIONS = 4;
	public const uint32 PRINTER_ENUM_FAVORITE = 4;
	public const uint32 PRINTER_ENUM_NAME = 8;
	public const uint32 PRINTER_ENUM_REMOTE = 16;
	public const uint32 PRINTER_ENUM_SHARED = 32;
	public const uint32 PRINTER_ENUM_NETWORK = 64;
	public const uint32 PRINTER_ENUM_EXPAND = 16384;
	public const uint32 PRINTER_ENUM_CONTAINER = 32768;
	public const uint32 PRINTER_ENUM_ICONMASK = 16711680;
	public const uint32 PRINTER_ENUM_ICON1 = 65536;
	public const uint32 PRINTER_ENUM_ICON2 = 131072;
	public const uint32 PRINTER_ENUM_ICON3 = 262144;
	public const uint32 PRINTER_ENUM_ICON4 = 524288;
	public const uint32 PRINTER_ENUM_ICON5 = 1048576;
	public const uint32 PRINTER_ENUM_ICON6 = 2097152;
	public const uint32 PRINTER_ENUM_ICON7 = 4194304;
	public const uint32 PRINTER_ENUM_ICON8 = 8388608;
	public const uint32 PRINTER_ENUM_HIDE = 16777216;
	public const uint32 PRINTER_ENUM_CATEGORY_ALL = 33554432;
	public const uint32 PRINTER_ENUM_CATEGORY_3D = 67108864;
	public const uint32 SPOOL_FILE_PERSISTENT = 1;
	public const uint32 SPOOL_FILE_TEMPORARY = 2;
	public const uint32 PRINTER_NOTIFY_TYPE = 0;
	public const uint32 JOB_NOTIFY_TYPE = 1;
	public const uint32 SERVER_NOTIFY_TYPE = 2;
	public const uint32 PRINTER_NOTIFY_FIELD_SERVER_NAME = 0;
	public const uint32 PRINTER_NOTIFY_FIELD_PRINTER_NAME = 1;
	public const uint32 PRINTER_NOTIFY_FIELD_SHARE_NAME = 2;
	public const uint32 PRINTER_NOTIFY_FIELD_PORT_NAME = 3;
	public const uint32 PRINTER_NOTIFY_FIELD_DRIVER_NAME = 4;
	public const uint32 PRINTER_NOTIFY_FIELD_COMMENT = 5;
	public const uint32 PRINTER_NOTIFY_FIELD_LOCATION = 6;
	public const uint32 PRINTER_NOTIFY_FIELD_DEVMODE = 7;
	public const uint32 PRINTER_NOTIFY_FIELD_SEPFILE = 8;
	public const uint32 PRINTER_NOTIFY_FIELD_PRINT_PROCESSOR = 9;
	public const uint32 PRINTER_NOTIFY_FIELD_PARAMETERS = 10;
	public const uint32 PRINTER_NOTIFY_FIELD_DATATYPE = 11;
	public const uint32 PRINTER_NOTIFY_FIELD_SECURITY_DESCRIPTOR = 12;
	public const uint32 PRINTER_NOTIFY_FIELD_ATTRIBUTES = 13;
	public const uint32 PRINTER_NOTIFY_FIELD_PRIORITY = 14;
	public const uint32 PRINTER_NOTIFY_FIELD_DEFAULT_PRIORITY = 15;
	public const uint32 PRINTER_NOTIFY_FIELD_START_TIME = 16;
	public const uint32 PRINTER_NOTIFY_FIELD_UNTIL_TIME = 17;
	public const uint32 PRINTER_NOTIFY_FIELD_STATUS = 18;
	public const uint32 PRINTER_NOTIFY_FIELD_STATUS_STRING = 19;
	public const uint32 PRINTER_NOTIFY_FIELD_CJOBS = 20;
	public const uint32 PRINTER_NOTIFY_FIELD_AVERAGE_PPM = 21;
	public const uint32 PRINTER_NOTIFY_FIELD_TOTAL_PAGES = 22;
	public const uint32 PRINTER_NOTIFY_FIELD_PAGES_PRINTED = 23;
	public const uint32 PRINTER_NOTIFY_FIELD_TOTAL_BYTES = 24;
	public const uint32 PRINTER_NOTIFY_FIELD_BYTES_PRINTED = 25;
	public const uint32 PRINTER_NOTIFY_FIELD_OBJECT_GUID = 26;
	public const uint32 PRINTER_NOTIFY_FIELD_FRIENDLY_NAME = 27;
	public const uint32 PRINTER_NOTIFY_FIELD_BRANCH_OFFICE_PRINTING = 28;
	public const uint32 JOB_NOTIFY_FIELD_PRINTER_NAME = 0;
	public const uint32 JOB_NOTIFY_FIELD_MACHINE_NAME = 1;
	public const uint32 JOB_NOTIFY_FIELD_PORT_NAME = 2;
	public const uint32 JOB_NOTIFY_FIELD_USER_NAME = 3;
	public const uint32 JOB_NOTIFY_FIELD_NOTIFY_NAME = 4;
	public const uint32 JOB_NOTIFY_FIELD_DATATYPE = 5;
	public const uint32 JOB_NOTIFY_FIELD_PRINT_PROCESSOR = 6;
	public const uint32 JOB_NOTIFY_FIELD_PARAMETERS = 7;
	public const uint32 JOB_NOTIFY_FIELD_DRIVER_NAME = 8;
	public const uint32 JOB_NOTIFY_FIELD_DEVMODE = 9;
	public const uint32 JOB_NOTIFY_FIELD_STATUS = 10;
	public const uint32 JOB_NOTIFY_FIELD_STATUS_STRING = 11;
	public const uint32 JOB_NOTIFY_FIELD_SECURITY_DESCRIPTOR = 12;
	public const uint32 JOB_NOTIFY_FIELD_DOCUMENT = 13;
	public const uint32 JOB_NOTIFY_FIELD_PRIORITY = 14;
	public const uint32 JOB_NOTIFY_FIELD_POSITION = 15;
	public const uint32 JOB_NOTIFY_FIELD_SUBMITTED = 16;
	public const uint32 JOB_NOTIFY_FIELD_START_TIME = 17;
	public const uint32 JOB_NOTIFY_FIELD_UNTIL_TIME = 18;
	public const uint32 JOB_NOTIFY_FIELD_TIME = 19;
	public const uint32 JOB_NOTIFY_FIELD_TOTAL_PAGES = 20;
	public const uint32 JOB_NOTIFY_FIELD_PAGES_PRINTED = 21;
	public const uint32 JOB_NOTIFY_FIELD_TOTAL_BYTES = 22;
	public const uint32 JOB_NOTIFY_FIELD_BYTES_PRINTED = 23;
	public const uint32 JOB_NOTIFY_FIELD_REMOTE_JOB_ID = 24;
	public const uint32 SERVER_NOTIFY_FIELD_PRINT_DRIVER_ISOLATION_GROUP = 0;
	public const uint32 PRINTER_NOTIFY_CATEGORY_ALL = 4096;
	public const uint32 PRINTER_NOTIFY_CATEGORY_3D = 8192;
	public const uint32 PRINTER_NOTIFY_OPTIONS_REFRESH = 1;
	public const uint32 PRINTER_NOTIFY_INFO_DISCARDED = 1;
	public const String BIDI_ACTION_ENUM_SCHEMA = "EnumSchema";
	public const String BIDI_ACTION_GET = "Get";
	public const String BIDI_ACTION_SET = "Set";
	public const String BIDI_ACTION_GET_ALL = "GetAll";
	public const String BIDI_ACTION_GET_WITH_ARGUMENT = "GetWithArgument";
	public const uint32 BIDI_ACCESS_ADMINISTRATOR = 1;
	public const uint32 BIDI_ACCESS_USER = 2;
	public const uint32 ERROR_BIDI_STATUS_OK = 0;
	public const uint32 ERROR_BIDI_ERROR_BASE = 13000;
	public const uint32 ERROR_BIDI_STATUS_WARNING = 13001;
	public const uint32 ERROR_BIDI_SCHEMA_READ_ONLY = 13002;
	public const uint32 ERROR_BIDI_SERVER_OFFLINE = 13003;
	public const uint32 ERROR_BIDI_DEVICE_OFFLINE = 13004;
	public const uint32 ERROR_BIDI_SCHEMA_NOT_SUPPORTED = 13005;
	public const uint32 ERROR_BIDI_SET_DIFFERENT_TYPE = 13006;
	public const uint32 ERROR_BIDI_SET_MULTIPLE_SCHEMAPATH = 13007;
	public const uint32 ERROR_BIDI_SET_INVALID_SCHEMAPATH = 13008;
	public const uint32 ERROR_BIDI_SET_UNKNOWN_FAILURE = 13009;
	public const uint32 ERROR_BIDI_SCHEMA_WRITE_ONLY = 13010;
	public const uint32 ERROR_BIDI_GET_REQUIRES_ARGUMENT = 13011;
	public const uint32 ERROR_BIDI_GET_ARGUMENT_NOT_SUPPORTED = 13012;
	public const uint32 ERROR_BIDI_GET_MISSING_ARGUMENT = 13013;
	public const uint32 ERROR_BIDI_DEVICE_CONFIG_UNCHANGED = 13014;
	public const uint32 ERROR_BIDI_NO_LOCALIZED_RESOURCES = 13015;
	public const uint32 ERROR_BIDI_NO_BIDI_SCHEMA_EXTENSIONS = 13016;
	public const uint32 ERROR_BIDI_UNSUPPORTED_CLIENT_LANGUAGE = 13017;
	public const uint32 ERROR_BIDI_UNSUPPORTED_RESOURCE_FORMAT = 13018;
	public const uint32 PRINTER_CHANGE_ADD_PRINTER = 1;
	public const uint32 PRINTER_CHANGE_SET_PRINTER = 2;
	public const uint32 PRINTER_CHANGE_DELETE_PRINTER = 4;
	public const uint32 PRINTER_CHANGE_FAILED_CONNECTION_PRINTER = 8;
	public const uint32 PRINTER_CHANGE_PRINTER = 255;
	public const uint32 PRINTER_CHANGE_ADD_JOB = 256;
	public const uint32 PRINTER_CHANGE_SET_JOB = 512;
	public const uint32 PRINTER_CHANGE_DELETE_JOB = 1024;
	public const uint32 PRINTER_CHANGE_WRITE_JOB = 2048;
	public const uint32 PRINTER_CHANGE_JOB = 65280;
	public const uint32 PRINTER_CHANGE_ADD_FORM = 65536;
	public const uint32 PRINTER_CHANGE_SET_FORM = 131072;
	public const uint32 PRINTER_CHANGE_DELETE_FORM = 262144;
	public const uint32 PRINTER_CHANGE_FORM = 458752;
	public const uint32 PRINTER_CHANGE_ADD_PORT = 1048576;
	public const uint32 PRINTER_CHANGE_CONFIGURE_PORT = 2097152;
	public const uint32 PRINTER_CHANGE_DELETE_PORT = 4194304;
	public const uint32 PRINTER_CHANGE_PORT = 7340032;
	public const uint32 PRINTER_CHANGE_ADD_PRINT_PROCESSOR = 16777216;
	public const uint32 PRINTER_CHANGE_DELETE_PRINT_PROCESSOR = 67108864;
	public const uint32 PRINTER_CHANGE_PRINT_PROCESSOR = 117440512;
	public const uint32 PRINTER_CHANGE_SERVER = 134217728;
	public const uint32 PRINTER_CHANGE_ADD_PRINTER_DRIVER = 268435456;
	public const uint32 PRINTER_CHANGE_SET_PRINTER_DRIVER = 536870912;
	public const uint32 PRINTER_CHANGE_DELETE_PRINTER_DRIVER = 1073741824;
	public const uint32 PRINTER_CHANGE_PRINTER_DRIVER = 1879048192;
	public const uint32 PRINTER_CHANGE_TIMEOUT = 2147483648;
	public const uint32 PRINTER_CHANGE_ALL = 2138570751;
	public const uint32 PRINTER_ERROR_INFORMATION = 2147483648;
	public const uint32 PRINTER_ERROR_WARNING = 1073741824;
	public const uint32 PRINTER_ERROR_SEVERE = 536870912;
	public const uint32 PRINTER_ERROR_OUTOFPAPER = 1;
	public const uint32 PRINTER_ERROR_JAM = 2;
	public const uint32 PRINTER_ERROR_OUTOFTONER = 4;
	public const String SPLREG_DEFAULT_SPOOL_DIRECTORY = "DefaultSpoolDirectory";
	public const String SPLREG_PORT_THREAD_PRIORITY_DEFAULT = "PortThreadPriorityDefault";
	public const String SPLREG_PORT_THREAD_PRIORITY = "PortThreadPriority";
	public const String SPLREG_SCHEDULER_THREAD_PRIORITY_DEFAULT = "SchedulerThreadPriorityDefault";
	public const String SPLREG_SCHEDULER_THREAD_PRIORITY = "SchedulerThreadPriority";
	public const String SPLREG_BEEP_ENABLED = "BeepEnabled";
	public const String SPLREG_NET_POPUP = "NetPopup";
	public const String SPLREG_RETRY_POPUP = "RetryPopup";
	public const String SPLREG_NET_POPUP_TO_COMPUTER = "NetPopupToComputer";
	public const String SPLREG_EVENT_LOG = "EventLog";
	public const String SPLREG_MAJOR_VERSION = "MajorVersion";
	public const String SPLREG_MINOR_VERSION = "MinorVersion";
	public const String SPLREG_ARCHITECTURE = "Architecture";
	public const String SPLREG_OS_VERSION = "OSVersion";
	public const String SPLREG_OS_VERSIONEX = "OSVersionEx";
	public const String SPLREG_DS_PRESENT = "DsPresent";
	public const String SPLREG_DS_PRESENT_FOR_USER = "DsPresentForUser";
	public const String SPLREG_REMOTE_FAX = "RemoteFax";
	public const String SPLREG_RESTART_JOB_ON_POOL_ERROR = "RestartJobOnPoolError";
	public const String SPLREG_RESTART_JOB_ON_POOL_ENABLED = "RestartJobOnPoolEnabled";
	public const String SPLREG_DNS_MACHINE_NAME = "DNSMachineName";
	public const String SPLREG_ALLOW_USER_MANAGEFORMS = "AllowUserManageForms";
	public const String SPLREG_WEBSHAREMGMT = "WebShareMgmt";
	public const String SPLREG_PRINT_DRIVER_ISOLATION_GROUPS = "PrintDriverIsolationGroups";
	public const String SPLREG_PRINT_DRIVER_ISOLATION_TIME_BEFORE_RECYCLE = "PrintDriverIsolationTimeBeforeRecycle";
	public const String SPLREG_PRINT_DRIVER_ISOLATION_MAX_OBJECTS_BEFORE_RECYCLE = "PrintDriverIsolationMaxobjsBeforeRecycle";
	public const String SPLREG_PRINT_DRIVER_ISOLATION_IDLE_TIMEOUT = "PrintDriverIsolationIdleTimeout";
	public const String SPLREG_PRINT_DRIVER_ISOLATION_EXECUTION_POLICY = "PrintDriverIsolationExecutionPolicy";
	public const String SPLREG_PRINT_DRIVER_ISOLATION_OVERRIDE_POLICY = "PrintDriverIsolationOverrideCompat";
	public const String SPLREG_PRINT_QUEUE_V4_DRIVER_DIRECTORY = "PrintQueueV4DriverDirectory";
	public const uint32 JOB_ACCESS_ADMINISTER = 16;
	public const uint32 JOB_ACCESS_READ = 32;
	public const String SPLDS_SPOOLER_KEY = "DsSpooler";
	public const String SPLDS_DRIVER_KEY = "DsDriver";
	public const String SPLDS_USER_KEY = "DsUser";
	public const String SPLDS_ASSET_NUMBER = "assetNumber";
	public const String SPLDS_BYTES_PER_MINUTE = "bytesPerMinute";
	public const String SPLDS_DESCRIPTION = "description";
	public const String SPLDS_DRIVER_NAME = "driverName";
	public const String SPLDS_DRIVER_VERSION = "driverVersion";
	public const String SPLDS_LOCATION = "location";
	public const String SPLDS_PORT_NAME = "portName";
	public const String SPLDS_PRINT_ATTRIBUTES = "printAttributes";
	public const String SPLDS_PRINT_BIN_NAMES = "printBinNames";
	public const String SPLDS_PRINT_COLLATE = "printCollate";
	public const String SPLDS_PRINT_COLOR = "printColor";
	public const String SPLDS_PRINT_DUPLEX_SUPPORTED = "printDuplexSupported";
	public const String SPLDS_PRINT_END_TIME = "printEndTime";
	public const String SPLDS_PRINTER_CLASS = "printQueue";
	public const String SPLDS_PRINTER_NAME = "printerName";
	public const String SPLDS_PRINT_KEEP_PRINTED_JOBS = "printKeepPrintedJobs";
	public const String SPLDS_PRINT_LANGUAGE = "printLanguage";
	public const String SPLDS_PRINT_MAC_ADDRESS = "printMACAddress";
	public const String SPLDS_PRINT_MAX_X_EXTENT = "printMaxXExtent";
	public const String SPLDS_PRINT_MAX_Y_EXTENT = "printMaxYExtent";
	public const String SPLDS_PRINT_MAX_RESOLUTION_SUPPORTED = "printMaxResolutionSupported";
	public const String SPLDS_PRINT_MEDIA_READY = "printMediaReady";
	public const String SPLDS_PRINT_MEDIA_SUPPORTED = "printMediaSupported";
	public const String SPLDS_PRINT_MEMORY = "printMemory";
	public const String SPLDS_PRINT_MIN_X_EXTENT = "printMinXExtent";
	public const String SPLDS_PRINT_MIN_Y_EXTENT = "printMinYExtent";
	public const String SPLDS_PRINT_NETWORK_ADDRESS = "printNetworkAddress";
	public const String SPLDS_PRINT_NOTIFY = "printNotify";
	public const String SPLDS_PRINT_NUMBER_UP = "printNumberUp";
	public const String SPLDS_PRINT_ORIENTATIONS_SUPPORTED = "printOrientationsSupported";
	public const String SPLDS_PRINT_OWNER = "printOwner";
	public const String SPLDS_PRINT_PAGES_PER_MINUTE = "printPagesPerMinute";
	public const String SPLDS_PRINT_RATE = "printRate";
	public const String SPLDS_PRINT_RATE_UNIT = "printRateUnit";
	public const String SPLDS_PRINT_SEPARATOR_FILE = "printSeparatorFile";
	public const String SPLDS_PRINT_SHARE_NAME = "printShareName";
	public const String SPLDS_PRINT_SPOOLING = "printSpooling";
	public const String SPLDS_PRINT_STAPLING_SUPPORTED = "printStaplingSupported";
	public const String SPLDS_PRINT_START_TIME = "printStartTime";
	public const String SPLDS_PRINT_STATUS = "printStatus";
	public const String SPLDS_PRIORITY = "priority";
	public const String SPLDS_SERVER_NAME = "serverName";
	public const String SPLDS_SHORT_SERVER_NAME = "shortServerName";
	public const String SPLDS_UNC_NAME = "uNCName";
	public const String SPLDS_URL = "url";
	public const String SPLDS_FLAGS = "flags";
	public const String SPLDS_VERSION_NUMBER = "versionNumber";
	public const String SPLDS_PRINTER_NAME_ALIASES = "printerNameAliases";
	public const String SPLDS_PRINTER_LOCATIONS = "printerLocations";
	public const String SPLDS_PRINTER_MODEL = "printerModel";
	public const uint32 PRINTER_CONNECTION_MISMATCH = 32;
	public const uint32 PRINTER_CONNECTION_NO_UI = 64;
	public const uint32 IPDFP_COPY_ALL_FILES = 1;
	public const uint32 UPDP_SILENT_UPLOAD = 1;
	public const uint32 UPDP_UPLOAD_ALWAYS = 2;
	public const uint32 UPDP_CHECK_DRIVERSTORE = 4;
	public const String MS_PRINT_JOB_OUTPUT_FILE = "MsPrintJobOutputFile";
	public const uint32 DISPID_PRINTSCHEMA_ELEMENT = 10000;
	public const uint32 DISPID_PRINTSCHEMA_ELEMENT_XMLNODE = 10001;
	public const uint32 DISPID_PRINTSCHEMA_ELEMENT_NAME = 10002;
	public const uint32 DISPID_PRINTSCHEMA_ELEMENT_NAMESPACEURI = 10003;
	public const uint32 DISPID_PRINTSCHEMA_DISPLAYABLEELEMENT = 10100;
	public const uint32 DISPID_PRINTSCHEMA_DISPLAYABLEELEMENT_DISPLAYNAME = 10101;
	public const uint32 DISPID_PRINTSCHEMA_OPTION = 10200;
	public const uint32 DISPID_PRINTSCHEMA_OPTION_SELECTED = 10201;
	public const uint32 DISPID_PRINTSCHEMA_OPTION_CONSTRAINED = 10202;
	public const uint32 DISPID_PRINTSCHEMA_OPTION_GETPROPERTYVALUE = 10203;
	public const uint32 DISPID_PRINTSCHEMA_PAGEMEDIASIZEOPTION = 10300;
	public const uint32 DISPID_PRINTSCHEMA_PAGEMEDIASIZEOPTION_WIDTH = 10301;
	public const uint32 DISPID_PRINTSCHEMA_PAGEMEDIASIZEOPTION_HEIGHT = 10302;
	public const uint32 DISPID_PRINTSCHEMA_NUPOPTION = 10400;
	public const uint32 DISPID_PRINTSCHEMA_NUPOPTION_PAGESPERSHEET = 10401;
	public const uint32 DISPID_PRINTSCHEMA_OPTIONCOLLECTION = 10500;
	public const uint32 DISPID_PRINTSCHEMA_OPTIONCOLLECTION_COUNT = 10501;
	public const uint32 DISPID_PRINTSCHEMA_OPTIONCOLLECTION_GETAT = 10502;
	public const uint32 DISPID_PRINTSCHEMA_FEATURE = 10600;
	public const uint32 DISPID_PRINTSCHEMA_FEATURE_SELECTEDOPTION = 10601;
	public const uint32 DISPID_PRINTSCHEMA_FEATURE_SELECTIONTYPE = 10602;
	public const uint32 DISPID_PRINTSCHEMA_FEATURE_GETOPTION = 10603;
	public const uint32 DISPID_PRINTSCHEMA_FEATURE_DISPLAYUI = 10604;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE = 10700;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE_IMAGEABLE_WIDTH = 10701;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE_IMAGEABLE_HEIGHT = 10702;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE_ORIGIN_WIDTH = 10703;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE_ORIGIN_HEIGHT = 10704;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE_EXTENT_WIDTH = 10705;
	public const uint32 DISPID_PRINTSCHEMA_PAGEIMAGEABLESIZE_EXTENT_HEIGHT = 10706;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES = 10800;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_GETFEATURE_KEYNAME = 10801;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_GETFEATURE = 10802;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_PAGEIMAGEABLESIZE = 10803;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_JOBCOPIESMINVALUE = 10804;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_JOBCOPIESMAXVALUE = 10805;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_GETSELECTEDOPTION = 10806;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_GETOPTIONS = 10807;
	public const uint32 DISPID_PRINTSCHEMA_CAPABILITIES_GETPARAMETERDEFINITION = 10808;
	public const uint32 DISPID_PRINTSCHEMA_ASYNCOPERATION = 10900;
	public const uint32 DISPID_PRINTSCHEMA_ASYNCOPERATION_START = 10901;
	public const uint32 DISPID_PRINTSCHEMA_ASYNCOPERATION_CANCEL = 10902;
	public const uint32 DISPID_PRINTSCHEMA_TICKET = 11000;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_GETFEATURE_KEYNAME = 11001;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_GETFEATURE = 11002;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_VALIDATEASYNC = 11003;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_COMMITASYNC = 11004;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_NOTIFYXMLCHANGED = 11005;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_GETCAPABILITIES = 11006;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_JOBCOPIESALLDOCUMENTS = 11007;
	public const uint32 DISPID_PRINTSCHEMA_TICKET_GETPARAMETERINITIALIZER = 11008;
	public const uint32 DISPID_PRINTSCHEMA_ASYNCOPERATIONEVENT = 11100;
	public const uint32 DISPID_PRINTSCHEMA_ASYNCOPERATIONEVENT_COMPLETED = 11101;
	public const uint32 DISPID_PRINTERSCRIPTABLESEQUENTIALSTREAM = 11200;
	public const uint32 DISPID_PRINTERSCRIPTABLESEQUENTIALSTREAM_READ = 11201;
	public const uint32 DISPID_PRINTERSCRIPTABLESEQUENTIALSTREAM_WRITE = 11202;
	public const uint32 DISPID_PRINTERSCRIPTABLESTREAM = 11300;
	public const uint32 DISPID_PRINTERSCRIPTABLESTREAM_COMMIT = 11301;
	public const uint32 DISPID_PRINTERSCRIPTABLESTREAM_SEEK = 11302;
	public const uint32 DISPID_PRINTERSCRIPTABLESTREAM_SETSIZE = 11303;
	public const uint32 DISPID_PRINTERPROPERTYBAG = 11400;
	public const uint32 DISPID_PRINTERPROPERTYBAG_GETBOOL = 11401;
	public const uint32 DISPID_PRINTERPROPERTYBAG_SETBOOL = 11402;
	public const uint32 DISPID_PRINTERPROPERTYBAG_GETINT32 = 11403;
	public const uint32 DISPID_PRINTERPROPERTYBAG_SETINT32 = 11404;
	public const uint32 DISPID_PRINTERPROPERTYBAG_GETSTRING = 11405;
	public const uint32 DISPID_PRINTERPROPERTYBAG_SETSTRING = 11406;
	public const uint32 DISPID_PRINTERPROPERTYBAG_GETBYTES = 11407;
	public const uint32 DISPID_PRINTERPROPERTYBAG_SETBYTES = 11408;
	public const uint32 DISPID_PRINTERPROPERTYBAG_GETREADSTREAM = 11409;
	public const uint32 DISPID_PRINTERPROPERTYBAG_GETWRITESTREAM = 11410;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETSTREAMASXML = 11411;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG = 11500;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETBOOL = 11501;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_SETBOOL = 11502;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETINT32 = 11503;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_SETINT32 = 11504;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETSTRING = 11505;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_SETSTRING = 11506;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETBYTES = 11507;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_SETBYTES = 11508;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETREADSTREAM = 11509;
	public const uint32 DISPID_PRINTERSCRIPTABLEPROPERTYBAG_GETWRITESTREAM = 11510;
	public const uint32 DISPID_PRINTERQUEUE = 11600;
	public const uint32 DISPID_PRINTERQUEUE_HANDLE = 11601;
	public const uint32 DISPID_PRINTERQUEUE_NAME = 11602;
	public const uint32 DISPID_PRINTERQUEUE_SENDBIDIQUERY = 11603;
	public const uint32 DISPID_PRINTERQUEUE_GETPROPERTIES = 11604;
	public const uint32 DISPID_PRINTERQUEUE_SENDBIDISETREQUESTASYNC = 11605;
	public const uint32 DISPID_PRINTERQUEUE_GETPRINTERQUEUEVIEW = 11606;
	public const uint32 DISPID_PRINTERQUEUEEVENT = 11700;
	public const uint32 DISPID_PRINTERQUEUEEVENT_ONBIDIRESPONSERECEIVED = 11701;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXT = 11800;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXT_PRINTERQUEUE = 11801;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXT_PRINTSCHEMATICKET = 11802;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXT_DRIVERPROPERTIES = 11803;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXT_USERPROPERTIES = 11804;
	public const uint32 DISPID_PRINTEREXTENSION_REQUEST = 11900;
	public const uint32 DISPID_PRINTEREXTENSION_REQUEST_CANCEL = 11901;
	public const uint32 DISPID_PRINTEREXTENSION_REQUEST_COMPLETE = 11902;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS = 12000;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_BIDINOTIFICATION = 12001;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_REASONID = 12002;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_REQUEST = 12003;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_SOURCEAPPLICATION = 12004;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_DETAILEDREASONID = 12005;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_WINDOWMODAL = 12006;
	public const uint32 DISPID_PRINTEREXTENSION_EVENTARGS_WINDOWPARENT = 12007;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXTCOLLECTION = 12100;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXTCOLLECTION_COUNT = 12101;
	public const uint32 DISPID_PRINTEREXTENSION_CONTEXTCOLLECTION_GETAT = 12102;
	public const uint32 DISPID_PRINTEREXTENSION_EVENT = 12200;
	public const uint32 DISPID_PRINTEREXTENSION_EVENT_ONDRIVEREVENT = 12201;
	public const uint32 DISPID_PRINTEREXTENSION_EVENT_ONPRINTERQUEUESENUMERATED = 12202;
	public const uint32 DISPID_PRINTERSCRIPTCONTEXT = 12300;
	public const uint32 DISPID_PRINTERSCRIPTCONTEXT_DRIVERPROPERTIES = 12301;
	public const uint32 DISPID_PRINTERSCRIPTCONTEXT_QUEUEPROPERTIES = 12302;
	public const uint32 DISPID_PRINTERSCRIPTCONTEXT_USERPROPERTIES = 12303;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERINITIALIZER = 12400;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERINITIALIZER_VALUE = 12401;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERDEFINITION = 12500;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERDEFINITION_USERINPUTREQUIRED = 12501;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERDEFINITION_UNITTYPE = 12502;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERDEFINITION_DATATYPE = 12503;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERDEFINITION_RANGEMIN = 12504;
	public const uint32 DISPID_PRINTSCHEMA_PARAMETERDEFINITION_RANGEMAX = 12505;
	public const uint32 DISPID_PRINTJOBCOLLECTION = 12600;
	public const uint32 DISPID_PRINTJOBCOLLECTION_COUNT = 12601;
	public const uint32 DISPID_PRINTJOBCOLLECTION_GETAT = 12602;
	public const uint32 DISPID_PRINTERQUEUEVIEW = 12700;
	public const uint32 DISPID_PRINTERQUEUEVIEW_SETVIEWRANGE = 12701;
	public const uint32 DISPID_PRINTERQUEUEVIEW_EVENT = 12800;
	public const uint32 DISPID_PRINTERQUEUEVIEW_EVENT_ONCHANGED = 12801;
	public const Guid NOTIFICATION_RELEASE = .(0xba9a5027, 0xa70e, 0x4ae7, 0x9b, 0x7d, 0xeb, 0x3e, 0x06, 0xad, 0x41, 0x57);
	public const Guid PRINT_APP_BIDI_NOTIFY_CHANNEL = .(0x2abad223, 0xb994, 0x4aca, 0x82, 0xfc, 0x45, 0x71, 0xb1, 0xb5, 0x85, 0xac);
	public const Guid PRINT_PORT_MONITOR_NOTIFY_CHANNEL = .(0x25df3b0e, 0x74a9, 0x47f5, 0x80, 0xce, 0x79, 0xb4, 0xb1, 0xeb, 0x5c, 0x58);
	public const Guid GUID_DEVINTERFACE_USBPRINT = .(0x28d78fad, 0x5a12, 0x11d1, 0xae, 0x5b, 0x00, 0x00, 0xf8, 0x03, 0xa8, 0xc2);
	public const Guid GUID_DEVINTERFACE_IPPUSB_PRINT = .(0xf2f40381, 0xf46d, 0x4e51, 0xbc, 0xe7, 0x62, 0xde, 0x6c, 0xf2, 0xd0, 0x98);
	public const Guid CLSID_XPSRASTERIZER_FACTORY = .(0x503e79bf, 0x1d09, 0x4764, 0x9d, 0x72, 0x1e, 0xb0, 0xc6, 0x59, 0x67, 0xc6);
}
#endregion

#region Enums

[AllowDuplicates]
public enum PRINTER_ACCESS_RIGHTS : uint32
{
	PRINTER_ALL_ACCESS = 983052,
	PRINTER_READ = 131080,
	PRINTER_WRITE = 131080,
	PRINTER_EXECUTE = 131080,
	SERVER_ALL_ACCESS = 983043,
	SERVER_READ = 131074,
	SERVER_WRITE = 131075,
	SERVER_EXECUTE = 131074,
	PRINTER_DELETE = 65536,
	PRINTER_READ_CONTROL = 131072,
	PRINTER_WRITE_DAC = 262144,
	PRINTER_WRITE_OWNER = 524288,
	PRINTER_SYNCHRONIZE = 1048576,
	PRINTER_STANDARD_RIGHTS_REQUIRED = 983040,
	PRINTER_STANDARD_RIGHTS_READ = 131072,
	PRINTER_STANDARD_RIGHTS_WRITE = 131072,
	PRINTER_STANDARD_RIGHTS_EXECUTE = 131072,
	SERVER_ACCESS_ADMINISTER = 1,
	SERVER_ACCESS_ENUMERATE = 2,
	PRINTER_ACCESS_ADMINISTER = 4,
	PRINTER_ACCESS_USE = 8,
	PRINTER_ACCESS_MANAGE_LIMITED = 64,
}


[AllowDuplicates]
public enum EXpsCompressionOptions : int32
{
	Compression_NotCompressed = 0,
	Compression_Normal = 1,
	Compression_Small = 2,
	Compression_Fast = 3,
}


[AllowDuplicates]
public enum EXpsFontOptions : int32
{
	Font_Normal = 0,
	Font_Obfusticate = 1,
}


[AllowDuplicates]
public enum EXpsJobConsumption : int32
{
	XpsJob_DocumentSequenceAdded = 0,
	XpsJob_FixedDocumentAdded = 1,
	XpsJob_FixedPageAdded = 2,
}


[AllowDuplicates]
public enum EXpsFontRestriction : int32
{
	Xps_Restricted_Font_Installable = 0,
	Xps_Restricted_Font_NoEmbedding = 2,
	Xps_Restricted_Font_PreviewPrint = 4,
	Xps_Restricted_Font_Editable = 8,
}


[AllowDuplicates]
public enum BIDI_TYPE : int32
{
	BIDI_NULL = 0,
	BIDI_INT = 1,
	BIDI_FLOAT = 2,
	BIDI_BOOL = 3,
	BIDI_STRING = 4,
	BIDI_TEXT = 5,
	BIDI_ENUM = 6,
	BIDI_BLOB = 7,
}


[AllowDuplicates]
public enum PRINTER_OPTION_FLAGS : int32
{
	PRINTER_OPTION_NO_CACHE = 1,
	PRINTER_OPTION_CACHE = 2,
	PRINTER_OPTION_CLIENT_CHANGE = 4,
	PRINTER_OPTION_NO_CLIENT_DATA = 8,
}


[AllowDuplicates]
public enum EPrintPropertyType : int32
{
	kPropertyTypeString = 1,
	kPropertyTypeInt32 = 2,
	kPropertyTypeInt64 = 3,
	kPropertyTypeByte = 4,
	kPropertyTypeTime = 5,
	kPropertyTypeDevMode = 6,
	kPropertyTypeSD = 7,
	kPropertyTypeNotificationReply = 8,
	kPropertyTypeNotificationOptions = 9,
	kPropertyTypeBuffer = 10,
}


[AllowDuplicates]
public enum EPrintXPSJobProgress : int32
{
	kAddingDocumentSequence = 0,
	kDocumentSequenceAdded = 1,
	kAddingFixedDocument = 2,
	kFixedDocumentAdded = 3,
	kAddingFixedPage = 4,
	kFixedPageAdded = 5,
	kResourceAdded = 6,
	kFontAdded = 7,
	kImageAdded = 8,
	kXpsDocumentCommitted = 9,
}


[AllowDuplicates]
public enum EPrintXPSJobOperation : int32
{
	kJobProduction = 1,
	kJobConsumption = 2,
}


[AllowDuplicates]
public enum PRINT_EXECUTION_CONTEXT : int32
{
	PRINT_EXECUTION_CONTEXT_APPLICATION = 0,
	PRINT_EXECUTION_CONTEXT_SPOOLER_SERVICE = 1,
	PRINT_EXECUTION_CONTEXT_SPOOLER_ISOLATION_HOST = 2,
	PRINT_EXECUTION_CONTEXT_FILTER_PIPELINE = 3,
	PRINT_EXECUTION_CONTEXT_WOW64 = 4,
}


[AllowDuplicates]
public enum MXDC_LANDSCAPE_ROTATION_ENUMS : int32
{
	MXDC_LANDSCAPE_ROTATE_COUNTERCLOCKWISE_90_DEGREES = 90,
	MXDC_LANDSCAPE_ROTATE_NONE = 0,
	MXDC_LANDSCAPE_ROTATE_COUNTERCLOCKWISE_270_DEGREES = -90,
}


[AllowDuplicates]
public enum MXDC_IMAGE_TYPE_ENUMS : int32
{
	MXDC_IMAGETYPE_JPEGHIGH_COMPRESSION = 1,
	MXDC_IMAGETYPE_JPEGMEDIUM_COMPRESSION = 2,
	MXDC_IMAGETYPE_JPEGLOW_COMPRESSION = 3,
	MXDC_IMAGETYPE_PNG = 4,
}


[AllowDuplicates]
public enum MXDC_S0_PAGE_ENUMS : int32
{
	MXDC_RESOURCE_TTF = 0,
	MXDC_RESOURCE_JPEG = 1,
	MXDC_RESOURCE_PNG = 2,
	MXDC_RESOURCE_TIFF = 3,
	MXDC_RESOURCE_WDP = 4,
	MXDC_RESOURCE_DICTIONARY = 5,
	MXDC_RESOURCE_ICC_PROFILE = 6,
	MXDC_RESOURCE_JPEG_THUMBNAIL = 7,
	MXDC_RESOURCE_PNG_THUMBNAIL = 8,
	MXDC_RESOURCE_MAX = 9,
}


[AllowDuplicates]
public enum EATTRIBUTE_DATATYPE : int32
{
	kADT_UNKNOWN = 0,
	kADT_BOOL = 1,
	kADT_INT = 2,
	kADT_LONG = 3,
	kADT_DWORD = 4,
	kADT_ASCII = 5,
	kADT_UNICODE = 6,
	kADT_BINARY = 7,
	kADT_SIZE = 8,
	kADT_RECT = 9,
	kADT_CUSTOMSIZEPARAMS = 10,
}


[AllowDuplicates]
public enum SHIMOPTS : int32
{
	PTSHIM_DEFAULT = 0,
	PTSHIM_NOSNAPSHOT = 1,
}


[AllowDuplicates]
public enum PrintSchemaConstrainedSetting : int32
{
	PrintSchemaConstrainedSetting_None = 0,
	PrintSchemaConstrainedSetting_PrintTicket = 1,
	PrintSchemaConstrainedSetting_Admin = 2,
	PrintSchemaConstrainedSetting_Device = 3,
}


[AllowDuplicates]
public enum PrintSchemaSelectionType : int32
{
	PrintSchemaSelectionType_PickOne = 0,
	PrintSchemaSelectionType_PickMany = 1,
}


[AllowDuplicates]
public enum PrintSchemaParameterDataType : int32
{
	PrintSchemaParameterDataType_Integer = 0,
	PrintSchemaParameterDataType_NumericString = 1,
	PrintSchemaParameterDataType_String = 2,
}


[AllowDuplicates]
public enum PrintJobStatus : int32
{
	PrintJobStatus_Paused = 1,
	PrintJobStatus_Error = 2,
	PrintJobStatus_Deleting = 4,
	PrintJobStatus_Spooling = 8,
	PrintJobStatus_Printing = 16,
	PrintJobStatus_Offline = 32,
	PrintJobStatus_PaperOut = 64,
	PrintJobStatus_Printed = 128,
	PrintJobStatus_Deleted = 256,
	PrintJobStatus_BlockedDeviceQueue = 512,
	PrintJobStatus_UserIntervention = 1024,
	PrintJobStatus_Restarted = 2048,
	PrintJobStatus_Complete = 4096,
	PrintJobStatus_Retained = 8192,
}


[AllowDuplicates]
public enum PrintAsyncNotifyUserFilter : int32
{
	kPerUser = 0,
	kAllUsers = 1,
}


[AllowDuplicates]
public enum PrintAsyncNotifyConversationStyle : int32
{
	kBiDirectional = 0,
	kUniDirectional = 1,
}


[AllowDuplicates]
public enum PrintAsyncNotifyError : int32
{
	CHANNEL_CLOSED_BY_SERVER = 1,
	CHANNEL_CLOSED_BY_ANOTHER_LISTENER = 2,
	CHANNEL_CLOSED_BY_SAME_LISTENER = 3,
	CHANNEL_RELEASED_BY_LISTENER = 4,
	UNIRECTIONAL_NOTIFICATION_LOST = 5,
	ASYNC_NOTIFICATION_FAILURE = 6,
	NO_LISTENERS = 7,
	CHANNEL_ALREADY_CLOSED = 8,
	CHANNEL_ALREADY_OPENED = 9,
	CHANNEL_WAITING_FOR_CLIENT_NOTIFICATION = 10,
	CHANNEL_NOT_OPENED = 11,
	ASYNC_CALL_ALREADY_PARKED = 12,
	NOT_REGISTERED = 13,
	ALREADY_UNREGISTERED = 14,
	ALREADY_REGISTERED = 15,
	CHANNEL_ACQUIRED = 16,
	ASYNC_CALL_IN_PROGRESS = 17,
	MAX_NOTIFICATION_SIZE_EXCEEDED = 18,
	INTERNAL_NOTIFICATION_QUEUE_IS_FULL = 19,
	INVALID_NOTIFICATION_TYPE = 20,
	MAX_REGISTRATION_COUNT_EXCEEDED = 21,
	MAX_CHANNEL_COUNT_EXCEEDED = 22,
	LOCAL_ONLY_REGISTRATION = 23,
	REMOTE_ONLY_REGISTRATION = 24,
}


[AllowDuplicates]
public enum EBranchOfficeJobEventType : int32
{
	kInvalidJobState = 0,
	kLogJobPrinted = 1,
	kLogJobRendered = 2,
	kLogJobError = 3,
	kLogJobPipelineError = 4,
	kLogOfflineFileFull = 5,
}


[AllowDuplicates]
public enum NOTIFICATION_CALLBACK_COMMANDS : int32
{
	NOTIFICATION_COMMAND_NOTIFY = 0,
	NOTIFICATION_COMMAND_CONTEXT_ACQUIRE = 1,
	NOTIFICATION_COMMAND_CONTEXT_RELEASE = 2,
}


[AllowDuplicates]
public enum NOTIFICATION_CONFIG_FLAGS : int32
{
	NOTIFICATION_CONFIG_CREATE_EVENT = 1,
	NOTIFICATION_CONFIG_REGISTER_CALLBACK = 2,
	NOTIFICATION_CONFIG_EVENT_TRIGGER = 4,
	NOTIFICATION_CONFIG_ASYNC_CHANNEL = 8,
}


[AllowDuplicates]
public enum UI_TYPE : int32
{
	kMessageBox = 0,
}


[AllowDuplicates]
public enum XPSRAS_RENDERING_MODE : int32
{
	XPSRAS_RENDERING_MODE_ANTIALIASED = 0,
	XPSRAS_RENDERING_MODE_ALIASED = 1,
}


[AllowDuplicates]
public enum XPSRAS_PIXEL_FORMAT : int32
{
	XPSRAS_PIXEL_FORMAT_32BPP_PBGRA_UINT_SRGB = 1,
	XPSRAS_PIXEL_FORMAT_64BPP_PRGBA_HALF_SCRGB = 2,
	XPSRAS_PIXEL_FORMAT_128BPP_PRGBA_FLOAT_SCRGB = 3,
}


[AllowDuplicates]
public enum XPSRAS_BACKGROUND_COLOR : int32
{
	XPSRAS_BACKGROUND_COLOR_TRANSPARENT = 0,
	XPSRAS_BACKGROUND_COLOR_OPAQUE = 1,
}


[AllowDuplicates]
public enum PageCountType : int32
{
	FinalPageCount = 0,
	IntermediatePageCount = 1,
}

#endregion

#region Function Pointers
public function int32 _CPSUICALLBACK(CPSUICBPARAM* pCPSUICBParam);

public function int PFNCOMPROPSHEET(HANDLE hComPropSheet, uint32 Function, LPARAM lParam1, LPARAM lParam2);

public function int32 PFNPROPSHEETUI(PROPSHEETUI_INFO* pPSUIInfo, LPARAM lParam);

public function BOOL PFN_DrvGetDriverSetting(void* pdriverobj, PSTR Feature, void* pOutput, uint32 cbSize, uint32* pcbNeeded, uint32* pdwOptionsReturned);

public function BOOL PFN_DrvUpgradeRegistrySetting(HANDLE hPrinter, PSTR pFeature, PSTR pOption);

public function BOOL PFN_DrvUpdateUISetting(void* pdriverobj, void* pOptItem, uint32 dwPreviousSelection, uint32 dwMode);

public function int32 OEMCUIPCALLBACK(CPSUICBPARAM* param0, OEMCUIPPARAM* param1);

public function int32 EMFPLAYPROC(HDC param0, int32 param1, HANDLE param2);

public function BOOL ROUTER_NOTIFY_CALLBACK(uint32 dwCommand, void* pContext, uint32 dwColor, PRINTER_NOTIFY_INFO* pNofityInfo, uint32 fdwFlags, uint32* pdwResult);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SPLCLIENT_INFO_2_WINXP
{
	public uint64 hSplPrinter;
}
#endif

[CRepr]
public struct ImgErrorInfo
{
	public BSTR description;
	public Guid guid;
	public uint32 helpContext;
	public BSTR helpFile;
	public BSTR source;
	public BSTR devDescription;
	public Guid errorID;
	public uint32 cUserParameters;
	public BSTR* aUserParameters;
	public BSTR userFallback;
	public uint32 exceptionID;
}

[CRepr]
public struct OPTPARAM
{
	public uint16 cbSize;
	public uint8 Flags;
	public uint8 Style;
	public int8* pData;
	public uint IconID;
	public LPARAM lParam;
	public uint[2] dwReserved;
}

[CRepr]
public struct OPTCOMBO
{
	public uint16 cbSize;
	public uint8 Flags;
	public uint16 cListItem;
	public OPTPARAM* pListItem;
	public int32 Sel;
	public uint32[3] dwReserved;
}

[CRepr]
public struct OPTTYPE
{
	public uint16 cbSize;
	public uint8 Type;
	public uint8 Flags;
	public uint16 Count;
	public uint16 BegCtrlID;
	public OPTPARAM* pOptParam;
	public uint16 Style;
	public uint16[3] wReserved;
	public uint[3] dwReserved;
}

[CRepr]
public struct EXTPUSH
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint16 DlgTemplateID;
		public HANDLE hDlgTemplate;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public DLGPROC DlgProc;
		public FARPROC pfnCallBack;
	}
	public uint16 cbSize;
	public uint16 Flags;
	public int8* pTitle;
	public using _Anonymous1_e__Union Anonymous1;
	public uint IconID;
	public using _Anonymous2_e__Union Anonymous2;
	public uint[3] dwReserved;
}

[CRepr]
public struct EXTCHKBOX
{
	public uint16 cbSize;
	public uint16 Flags;
	public int8* pTitle;
	public int8* pSeparator;
	public int8* pCheckedName;
	public uint IconID;
	public uint16[4] wReserved;
	public uint[2] dwReserved;
}

[CRepr]
public struct OIEXT
{
	public uint16 cbSize;
	public uint16 Flags;
	public HINSTANCE hInstCaller;
	public int8* pHelpFile;
	public uint[4] dwReserved;
}

[CRepr]
public struct OPTITEM
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public EXTCHKBOX* pExtChkBox;
		public EXTPUSH* pExtPush;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public int32 Sel;
		public int8* pSel;
	}
	public uint16 cbSize;
	public uint8 Level;
	public uint8 DlgPageIdx;
	public uint32 Flags;
	public uint UserData;
	public int8* pName;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public OPTTYPE* pOptType;
	public uint32 HelpIndex;
	public uint8 DMPubID;
	public uint8 UserItemID;
	public uint16 wReserved;
	public OIEXT* pOIExt;
	public uint[3] dwReserved;
}

[CRepr]
public struct CPSUICBPARAM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int32 OldSel;
		public int8* pOldSel;
	}
	public uint16 cbSize;
	public uint16 Reason;
	public HWND hDlg;
	public OPTITEM* pOptItem;
	public uint16 cOptItem;
	public uint16 Flags;
	public OPTITEM* pCurItem;
	public using _Anonymous_e__Union Anonymous;
	public uint UserData;
	public uint Result;
}

[CRepr]
public struct DLGPAGE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 DlgTemplateID;
		public HANDLE hDlgTemplate;
	}
	public uint16 cbSize;
	public uint16 Flags;
	public DLGPROC DlgProc;
	public int8* pTabName;
	public uint IconID;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct COMPROPSHEETUI
{
	public uint16 cbSize;
	public uint16 Flags;
	public HINSTANCE hInstCaller;
	public int8* pCallerName;
	public uint UserData;
	public int8* pHelpFile;
	public _CPSUICALLBACK pfnCallBack;
	public OPTITEM* pOptItem;
	public DLGPAGE* pDlgPage;
	public uint16 cOptItem;
	public uint16 cDlgPage;
	public uint IconID;
	public int8* pOptItemName;
	public uint16 CallerVersion;
	public uint16 OptItemVersion;
	public uint[4] dwReserved;
}

[CRepr]
public struct SETRESULT_INFO
{
	public uint16 cbSize;
	public uint16 wReserved;
	public HANDLE hSetResult;
	public LRESULT Result;
}

[CRepr]
public struct INSERTPSUIPAGE_INFO
{
	public uint16 cbSize;
	public uint8 Type;
	public uint8 Mode;
	public uint dwData1;
	public uint dwData2;
	public uint dwData3;
}

[CRepr]
public struct PSPINFO
{
	public uint16 cbSize;
	public uint16 wReserved;
	public HANDLE hComPropSheet;
	public HANDLE hCPSUIPage;
	public PFNCOMPROPSHEET pfnComPropSheet;
}

[CRepr]
public struct CPSUIDATABLOCK
{
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct PROPSHEETUI_INFO
{
	public uint16 cbSize;
	public uint16 Version;
	public uint16 Flags;
	public uint16 Reason;
	public HANDLE hComPropSheet;
	public PFNCOMPROPSHEET pfnComPropSheet;
	public LPARAM lParamInit;
	public uint UserData;
	public uint Result;
}

[CRepr]
public struct PROPSHEETUI_GETICON_INFO
{
	public uint16 cbSize;
	public uint16 Flags;
	public uint16 cxIcon;
	public uint16 cyIcon;
	public HICON hIcon;
}

[CRepr]
public struct PROPSHEETUI_INFO_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public HICON hIcon;
		public uint IconID;
	}
	public uint16 cbSize;
	public uint16 Flags;
	public int8* pTitle;
	public HWND hWndParent;
	public HINSTANCE hInst;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PRINTER_INFO_1A
{
	public uint32 Flags;
	public PSTR pDescription;
	public PSTR pName;
	public PSTR pComment;
}

[CRepr]
public struct PRINTER_INFO_1W
{
	public uint32 Flags;
	public PWSTR pDescription;
	public PWSTR pName;
	public PWSTR pComment;
}

[CRepr]
public struct PRINTER_INFO_2A
{
	public PSTR pServerName;
	public PSTR pPrinterName;
	public PSTR pShareName;
	public PSTR pPortName;
	public PSTR pDriverName;
	public PSTR pComment;
	public PSTR pLocation;
	public DEVMODEA* pDevMode;
	public PSTR pSepFile;
	public PSTR pPrintProcessor;
	public PSTR pDatatype;
	public PSTR pParameters;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
	public uint32 Attributes;
	public uint32 Priority;
	public uint32 DefaultPriority;
	public uint32 StartTime;
	public uint32 UntilTime;
	public uint32 Status;
	public uint32 cJobs;
	public uint32 AveragePPM;
}

[CRepr]
public struct PRINTER_INFO_2W
{
	public PWSTR pServerName;
	public PWSTR pPrinterName;
	public PWSTR pShareName;
	public PWSTR pPortName;
	public PWSTR pDriverName;
	public PWSTR pComment;
	public PWSTR pLocation;
	public DEVMODEW* pDevMode;
	public PWSTR pSepFile;
	public PWSTR pPrintProcessor;
	public PWSTR pDatatype;
	public PWSTR pParameters;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
	public uint32 Attributes;
	public uint32 Priority;
	public uint32 DefaultPriority;
	public uint32 StartTime;
	public uint32 UntilTime;
	public uint32 Status;
	public uint32 cJobs;
	public uint32 AveragePPM;
}

[CRepr]
public struct PRINTER_INFO_3
{
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
}

[CRepr]
public struct PRINTER_INFO_4A
{
	public PSTR pPrinterName;
	public PSTR pServerName;
	public uint32 Attributes;
}

[CRepr]
public struct PRINTER_INFO_4W
{
	public PWSTR pPrinterName;
	public PWSTR pServerName;
	public uint32 Attributes;
}

[CRepr]
public struct PRINTER_INFO_5A
{
	public PSTR pPrinterName;
	public PSTR pPortName;
	public uint32 Attributes;
	public uint32 DeviceNotSelectedTimeout;
	public uint32 TransmissionRetryTimeout;
}

[CRepr]
public struct PRINTER_INFO_5W
{
	public PWSTR pPrinterName;
	public PWSTR pPortName;
	public uint32 Attributes;
	public uint32 DeviceNotSelectedTimeout;
	public uint32 TransmissionRetryTimeout;
}

[CRepr]
public struct PRINTER_INFO_6
{
	public uint32 dwStatus;
}

[CRepr]
public struct PRINTER_INFO_7A
{
	public PSTR pszObjectGUID;
	public uint32 dwAction;
}

[CRepr]
public struct PRINTER_INFO_7W
{
	public PWSTR pszObjectGUID;
	public uint32 dwAction;
}

[CRepr]
public struct PRINTER_INFO_8A
{
	public DEVMODEA* pDevMode;
}

[CRepr]
public struct PRINTER_INFO_8W
{
	public DEVMODEW* pDevMode;
}

[CRepr]
public struct PRINTER_INFO_9A
{
	public DEVMODEA* pDevMode;
}

[CRepr]
public struct PRINTER_INFO_9W
{
	public DEVMODEW* pDevMode;
}

[CRepr]
public struct JOB_INFO_1A
{
	public uint32 JobId;
	public PSTR pPrinterName;
	public PSTR pMachineName;
	public PSTR pUserName;
	public PSTR pDocument;
	public PSTR pDatatype;
	public PSTR pStatus;
	public uint32 Status;
	public uint32 Priority;
	public uint32 Position;
	public uint32 TotalPages;
	public uint32 PagesPrinted;
	public SYSTEMTIME Submitted;
}

[CRepr]
public struct JOB_INFO_1W
{
	public uint32 JobId;
	public PWSTR pPrinterName;
	public PWSTR pMachineName;
	public PWSTR pUserName;
	public PWSTR pDocument;
	public PWSTR pDatatype;
	public PWSTR pStatus;
	public uint32 Status;
	public uint32 Priority;
	public uint32 Position;
	public uint32 TotalPages;
	public uint32 PagesPrinted;
	public SYSTEMTIME Submitted;
}

[CRepr]
public struct JOB_INFO_2A
{
	public uint32 JobId;
	public PSTR pPrinterName;
	public PSTR pMachineName;
	public PSTR pUserName;
	public PSTR pDocument;
	public PSTR pNotifyName;
	public PSTR pDatatype;
	public PSTR pPrintProcessor;
	public PSTR pParameters;
	public PSTR pDriverName;
	public DEVMODEA* pDevMode;
	public PSTR pStatus;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
	public uint32 Status;
	public uint32 Priority;
	public uint32 Position;
	public uint32 StartTime;
	public uint32 UntilTime;
	public uint32 TotalPages;
	public uint32 Size;
	public SYSTEMTIME Submitted;
	public uint32 Time;
	public uint32 PagesPrinted;
}

[CRepr]
public struct JOB_INFO_2W
{
	public uint32 JobId;
	public PWSTR pPrinterName;
	public PWSTR pMachineName;
	public PWSTR pUserName;
	public PWSTR pDocument;
	public PWSTR pNotifyName;
	public PWSTR pDatatype;
	public PWSTR pPrintProcessor;
	public PWSTR pParameters;
	public PWSTR pDriverName;
	public DEVMODEW* pDevMode;
	public PWSTR pStatus;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
	public uint32 Status;
	public uint32 Priority;
	public uint32 Position;
	public uint32 StartTime;
	public uint32 UntilTime;
	public uint32 TotalPages;
	public uint32 Size;
	public SYSTEMTIME Submitted;
	public uint32 Time;
	public uint32 PagesPrinted;
}

[CRepr]
public struct JOB_INFO_3
{
	public uint32 JobId;
	public uint32 NextJobId;
	public uint32 Reserved;
}

[CRepr]
public struct JOB_INFO_4A
{
	public uint32 JobId;
	public PSTR pPrinterName;
	public PSTR pMachineName;
	public PSTR pUserName;
	public PSTR pDocument;
	public PSTR pNotifyName;
	public PSTR pDatatype;
	public PSTR pPrintProcessor;
	public PSTR pParameters;
	public PSTR pDriverName;
	public DEVMODEA* pDevMode;
	public PSTR pStatus;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
	public uint32 Status;
	public uint32 Priority;
	public uint32 Position;
	public uint32 StartTime;
	public uint32 UntilTime;
	public uint32 TotalPages;
	public uint32 Size;
	public SYSTEMTIME Submitted;
	public uint32 Time;
	public uint32 PagesPrinted;
	public int32 SizeHigh;
}

[CRepr]
public struct JOB_INFO_4W
{
	public uint32 JobId;
	public PWSTR pPrinterName;
	public PWSTR pMachineName;
	public PWSTR pUserName;
	public PWSTR pDocument;
	public PWSTR pNotifyName;
	public PWSTR pDatatype;
	public PWSTR pPrintProcessor;
	public PWSTR pParameters;
	public PWSTR pDriverName;
	public DEVMODEW* pDevMode;
	public PWSTR pStatus;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
	public uint32 Status;
	public uint32 Priority;
	public uint32 Position;
	public uint32 StartTime;
	public uint32 UntilTime;
	public uint32 TotalPages;
	public uint32 Size;
	public SYSTEMTIME Submitted;
	public uint32 Time;
	public uint32 PagesPrinted;
	public int32 SizeHigh;
}

[CRepr]
public struct ADDJOB_INFO_1A
{
	public PSTR Path;
	public uint32 JobId;
}

[CRepr]
public struct ADDJOB_INFO_1W
{
	public PWSTR Path;
	public uint32 JobId;
}

[CRepr]
public struct DRIVER_INFO_1A
{
	public PSTR pName;
}

[CRepr]
public struct DRIVER_INFO_1W
{
	public PWSTR pName;
}

[CRepr]
public struct DRIVER_INFO_2A
{
	public uint32 cVersion;
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDriverPath;
	public PSTR pDataFile;
	public PSTR pConfigFile;
}

[CRepr]
public struct DRIVER_INFO_2W
{
	public uint32 cVersion;
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDriverPath;
	public PWSTR pDataFile;
	public PWSTR pConfigFile;
}

[CRepr]
public struct DRIVER_INFO_3A
{
	public uint32 cVersion;
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDriverPath;
	public PSTR pDataFile;
	public PSTR pConfigFile;
	public PSTR pHelpFile;
	public PSTR pDependentFiles;
	public PSTR pMonitorName;
	public PSTR pDefaultDataType;
}

[CRepr]
public struct DRIVER_INFO_3W
{
	public uint32 cVersion;
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDriverPath;
	public PWSTR pDataFile;
	public PWSTR pConfigFile;
	public PWSTR pHelpFile;
	public PWSTR pDependentFiles;
	public PWSTR pMonitorName;
	public PWSTR pDefaultDataType;
}

[CRepr]
public struct DRIVER_INFO_4A
{
	public uint32 cVersion;
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDriverPath;
	public PSTR pDataFile;
	public PSTR pConfigFile;
	public PSTR pHelpFile;
	public PSTR pDependentFiles;
	public PSTR pMonitorName;
	public PSTR pDefaultDataType;
	public PSTR pszzPreviousNames;
}

[CRepr]
public struct DRIVER_INFO_4W
{
	public uint32 cVersion;
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDriverPath;
	public PWSTR pDataFile;
	public PWSTR pConfigFile;
	public PWSTR pHelpFile;
	public PWSTR pDependentFiles;
	public PWSTR pMonitorName;
	public PWSTR pDefaultDataType;
	public PWSTR pszzPreviousNames;
}

[CRepr]
public struct DRIVER_INFO_5A
{
	public uint32 cVersion;
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDriverPath;
	public PSTR pDataFile;
	public PSTR pConfigFile;
	public uint32 dwDriverAttributes;
	public uint32 dwConfigVersion;
	public uint32 dwDriverVersion;
}

[CRepr]
public struct DRIVER_INFO_5W
{
	public uint32 cVersion;
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDriverPath;
	public PWSTR pDataFile;
	public PWSTR pConfigFile;
	public uint32 dwDriverAttributes;
	public uint32 dwConfigVersion;
	public uint32 dwDriverVersion;
}

[CRepr]
public struct DRIVER_INFO_6A
{
	public uint32 cVersion;
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDriverPath;
	public PSTR pDataFile;
	public PSTR pConfigFile;
	public PSTR pHelpFile;
	public PSTR pDependentFiles;
	public PSTR pMonitorName;
	public PSTR pDefaultDataType;
	public PSTR pszzPreviousNames;
	public FILETIME ftDriverDate;
	public uint64 dwlDriverVersion;
	public PSTR pszMfgName;
	public PSTR pszOEMUrl;
	public PSTR pszHardwareID;
	public PSTR pszProvider;
}

[CRepr]
public struct DRIVER_INFO_6W
{
	public uint32 cVersion;
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDriverPath;
	public PWSTR pDataFile;
	public PWSTR pConfigFile;
	public PWSTR pHelpFile;
	public PWSTR pDependentFiles;
	public PWSTR pMonitorName;
	public PWSTR pDefaultDataType;
	public PWSTR pszzPreviousNames;
	public FILETIME ftDriverDate;
	public uint64 dwlDriverVersion;
	public PWSTR pszMfgName;
	public PWSTR pszOEMUrl;
	public PWSTR pszHardwareID;
	public PWSTR pszProvider;
}

[CRepr]
public struct DRIVER_INFO_8A
{
	public uint32 cVersion;
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDriverPath;
	public PSTR pDataFile;
	public PSTR pConfigFile;
	public PSTR pHelpFile;
	public PSTR pDependentFiles;
	public PSTR pMonitorName;
	public PSTR pDefaultDataType;
	public PSTR pszzPreviousNames;
	public FILETIME ftDriverDate;
	public uint64 dwlDriverVersion;
	public PSTR pszMfgName;
	public PSTR pszOEMUrl;
	public PSTR pszHardwareID;
	public PSTR pszProvider;
	public PSTR pszPrintProcessor;
	public PSTR pszVendorSetup;
	public PSTR pszzColorProfiles;
	public PSTR pszInfPath;
	public uint32 dwPrinterDriverAttributes;
	public PSTR pszzCoreDriverDependencies;
	public FILETIME ftMinInboxDriverVerDate;
	public uint64 dwlMinInboxDriverVerVersion;
}

[CRepr]
public struct DRIVER_INFO_8W
{
	public uint32 cVersion;
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDriverPath;
	public PWSTR pDataFile;
	public PWSTR pConfigFile;
	public PWSTR pHelpFile;
	public PWSTR pDependentFiles;
	public PWSTR pMonitorName;
	public PWSTR pDefaultDataType;
	public PWSTR pszzPreviousNames;
	public FILETIME ftDriverDate;
	public uint64 dwlDriverVersion;
	public PWSTR pszMfgName;
	public PWSTR pszOEMUrl;
	public PWSTR pszHardwareID;
	public PWSTR pszProvider;
	public PWSTR pszPrintProcessor;
	public PWSTR pszVendorSetup;
	public PWSTR pszzColorProfiles;
	public PWSTR pszInfPath;
	public uint32 dwPrinterDriverAttributes;
	public PWSTR pszzCoreDriverDependencies;
	public FILETIME ftMinInboxDriverVerDate;
	public uint64 dwlMinInboxDriverVerVersion;
}

[CRepr]
public struct DOC_INFO_1A
{
	public PSTR pDocName;
	public PSTR pOutputFile;
	public PSTR pDatatype;
}

[CRepr]
public struct DOC_INFO_1W
{
	public PWSTR pDocName;
	public PWSTR pOutputFile;
	public PWSTR pDatatype;
}

[CRepr]
public struct FORM_INFO_1A
{
	public uint32 Flags;
	public PSTR pName;
	public SIZE Size;
	public RECTL ImageableArea;
}

[CRepr]
public struct FORM_INFO_1W
{
	public uint32 Flags;
	public PWSTR pName;
	public SIZE Size;
	public RECTL ImageableArea;
}

[CRepr]
public struct FORM_INFO_2A
{
	public uint32 Flags;
	public PSTR pName;
	public SIZE Size;
	public RECTL ImageableArea;
	public PSTR pKeyword;
	public uint32 StringType;
	public PSTR pMuiDll;
	public uint32 dwResourceId;
	public PSTR pDisplayName;
	public uint16 wLangId;
}

[CRepr]
public struct FORM_INFO_2W
{
	public uint32 Flags;
	public PWSTR pName;
	public SIZE Size;
	public RECTL ImageableArea;
	public PSTR pKeyword;
	public uint32 StringType;
	public PWSTR pMuiDll;
	public uint32 dwResourceId;
	public PWSTR pDisplayName;
	public uint16 wLangId;
}

[CRepr]
public struct DOC_INFO_2A
{
	public PSTR pDocName;
	public PSTR pOutputFile;
	public PSTR pDatatype;
	public uint32 dwMode;
	public uint32 JobId;
}

[CRepr]
public struct DOC_INFO_2W
{
	public PWSTR pDocName;
	public PWSTR pOutputFile;
	public PWSTR pDatatype;
	public uint32 dwMode;
	public uint32 JobId;
}

[CRepr]
public struct DOC_INFO_3A
{
	public PSTR pDocName;
	public PSTR pOutputFile;
	public PSTR pDatatype;
	public uint32 dwFlags;
}

[CRepr]
public struct DOC_INFO_3W
{
	public PWSTR pDocName;
	public PWSTR pOutputFile;
	public PWSTR pDatatype;
	public uint32 dwFlags;
}

[CRepr]
public struct PRINTPROCESSOR_INFO_1A
{
	public PSTR pName;
}

[CRepr]
public struct PRINTPROCESSOR_INFO_1W
{
	public PWSTR pName;
}

[CRepr]
public struct PRINTPROCESSOR_CAPS_1
{
	public uint32 dwLevel;
	public uint32 dwNupOptions;
	public uint32 dwPageOrderFlags;
	public uint32 dwNumberOfCopies;
}

[CRepr]
public struct PRINTPROCESSOR_CAPS_2
{
	public uint32 dwLevel;
	public uint32 dwNupOptions;
	public uint32 dwPageOrderFlags;
	public uint32 dwNumberOfCopies;
	public uint32 dwDuplexHandlingCaps;
	public uint32 dwNupDirectionCaps;
	public uint32 dwNupBorderCaps;
	public uint32 dwBookletHandlingCaps;
	public uint32 dwScalingCaps;
}

[CRepr]
public struct PORT_INFO_1A
{
	public PSTR pName;
}

[CRepr]
public struct PORT_INFO_1W
{
	public PWSTR pName;
}

[CRepr]
public struct PORT_INFO_2A
{
	public PSTR pPortName;
	public PSTR pMonitorName;
	public PSTR pDescription;
	public uint32 fPortType;
	public uint32 Reserved;
}

[CRepr]
public struct PORT_INFO_2W
{
	public PWSTR pPortName;
	public PWSTR pMonitorName;
	public PWSTR pDescription;
	public uint32 fPortType;
	public uint32 Reserved;
}

[CRepr]
public struct PORT_INFO_3A
{
	public uint32 dwStatus;
	public PSTR pszStatus;
	public uint32 dwSeverity;
}

[CRepr]
public struct PORT_INFO_3W
{
	public uint32 dwStatus;
	public PWSTR pszStatus;
	public uint32 dwSeverity;
}

[CRepr]
public struct MONITOR_INFO_1A
{
	public PSTR pName;
}

[CRepr]
public struct MONITOR_INFO_1W
{
	public PWSTR pName;
}

[CRepr]
public struct MONITOR_INFO_2A
{
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDLLName;
}

[CRepr]
public struct MONITOR_INFO_2W
{
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDLLName;
}

[CRepr]
public struct DATATYPES_INFO_1A
{
	public PSTR pName;
}

[CRepr]
public struct DATATYPES_INFO_1W
{
	public PWSTR pName;
}

[CRepr]
public struct PRINTER_DEFAULTSA
{
	public PSTR pDatatype;
	public DEVMODEA* pDevMode;
	public PRINTER_ACCESS_RIGHTS DesiredAccess;
}

[CRepr]
public struct PRINTER_DEFAULTSW
{
	public PWSTR pDatatype;
	public DEVMODEW* pDevMode;
	public PRINTER_ACCESS_RIGHTS DesiredAccess;
}

[CRepr]
public struct PRINTER_ENUM_VALUESA
{
	public PSTR pValueName;
	public uint32 cbValueName;
	public uint32 dwType;
	public uint8* pData;
	public uint32 cbData;
}

[CRepr]
public struct PRINTER_ENUM_VALUESW
{
	public PWSTR pValueName;
	public uint32 cbValueName;
	public uint32 dwType;
	public uint8* pData;
	public uint32 cbData;
}

[CRepr]
public struct PRINTER_NOTIFY_OPTIONS_TYPE
{
	public uint16 Type;
	public uint16 Reserved0;
	public uint32 Reserved1;
	public uint32 Reserved2;
	public uint32 Count;
	public uint16* pFields;
}

[CRepr]
public struct PRINTER_NOTIFY_OPTIONS
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 Count;
	public PRINTER_NOTIFY_OPTIONS_TYPE* pTypes;
}

[CRepr]
public struct PRINTER_NOTIFY_INFO_DATA
{
	[CRepr, Union]
	public struct _NotifyData_e__Union
	{
		[CRepr]
		public struct _Data_e__Struct
		{
			public uint32 cbBuf;
			public void* pBuf;
		}
		public uint32[2] adwData;
		public _Data_e__Struct Data;
	}
	public uint16 Type;
	public uint16 Field;
	public uint32 Reserved;
	public uint32 Id;
	public _NotifyData_e__Union NotifyData;
}

[CRepr]
public struct PRINTER_NOTIFY_INFO
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 Count;
	public PRINTER_NOTIFY_INFO_DATA* aData mut => &aData_impl;
	private PRINTER_NOTIFY_INFO_DATA[ANYSIZE_ARRAY] aData_impl;
}

[CRepr]
public struct BINARY_CONTAINER
{
	public uint32 cbBuf;
	public uint8* pData;
}

[CRepr]
public struct BIDI_DATA
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public BOOL bData;
		public int32 iData;
		public PWSTR sData;
		public float fData;
		public BINARY_CONTAINER biData;
	}
	public uint32 dwBidiType;
	public _u_e__Union u;
}

[CRepr]
public struct BIDI_REQUEST_DATA
{
	public uint32 dwReqNumber;
	public PWSTR pSchema;
	public BIDI_DATA data;
}

[CRepr]
public struct BIDI_REQUEST_CONTAINER
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 Count;
	public BIDI_REQUEST_DATA* aData mut => &aData_impl;
	private BIDI_REQUEST_DATA[ANYSIZE_ARRAY] aData_impl;
}

[CRepr]
public struct BIDI_RESPONSE_DATA
{
	public uint32 dwResult;
	public uint32 dwReqNumber;
	public PWSTR pSchema;
	public BIDI_DATA data;
}

[CRepr]
public struct BIDI_RESPONSE_CONTAINER
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 Count;
	public BIDI_RESPONSE_DATA* aData mut => &aData_impl;
	private BIDI_RESPONSE_DATA[ANYSIZE_ARRAY] aData_impl;
}

[CRepr]
public struct PROVIDOR_INFO_1A
{
	public PSTR pName;
	public PSTR pEnvironment;
	public PSTR pDLLName;
}

[CRepr]
public struct PROVIDOR_INFO_1W
{
	public PWSTR pName;
	public PWSTR pEnvironment;
	public PWSTR pDLLName;
}

[CRepr]
public struct PROVIDOR_INFO_2A
{
	public PSTR pOrder;
}

[CRepr]
public struct PROVIDOR_INFO_2W
{
	public PWSTR pOrder;
}

[CRepr]
public struct PRINTER_OPTIONSA
{
	public uint32 cbSize;
	public PRINTER_OPTION_FLAGS dwFlags;
}

[CRepr]
public struct PRINTER_OPTIONSW
{
	public uint32 cbSize;
	public PRINTER_OPTION_FLAGS dwFlags;
}

[CRepr]
public struct PRINTER_CONNECTION_INFO_1A
{
	public uint32 dwFlags;
	public PSTR pszDriverName;
}

[CRepr]
public struct PRINTER_CONNECTION_INFO_1W
{
	public uint32 dwFlags;
	public PWSTR pszDriverName;
}

[CRepr]
public struct CORE_PRINTER_DRIVERA
{
	public Guid CoreDriverGUID;
	public FILETIME ftDriverDate;
	public uint64 dwlDriverVersion;
	public CHAR[260] szPackageID;
}

[CRepr]
public struct CORE_PRINTER_DRIVERW
{
	public Guid CoreDriverGUID;
	public FILETIME ftDriverDate;
	public uint64 dwlDriverVersion;
	public char16[260] szPackageID;
}

[CRepr]
public struct PrintPropertyValue
{
	[CRepr, Union]
	public struct _value_e__Union
	{
		[CRepr]
		public struct _propertyBlob_e__Struct
		{
			public uint32 cbBuf;
			public void* pBuf;
		}
		public uint8 propertyByte;
		public PWSTR propertyString;
		public int32 propertyInt32;
		public int64 propertyInt64;
		public _propertyBlob_e__Struct propertyBlob;
	}
	public EPrintPropertyType ePropertyType;
	public _value_e__Union value;
}

[CRepr]
public struct PrintNamedProperty
{
	public PWSTR propertyName;
	public PrintPropertyValue propertyValue;
}

[CRepr]
public struct PrintPropertiesCollection
{
	public uint32 numberOfProperties;
	public PrintNamedProperty* propertiesCollection;
}

[CRepr]
public struct PRINT_EXECUTION_DATA
{
	public PRINT_EXECUTION_CONTEXT context;
	public uint32 clientAppPID;
}

[CRepr, Packed(1)]
public struct MXDC_ESCAPE_HEADER_T
{
	public uint32 cbInput;
	public uint32 cbOutput;
	public uint32 opCode;
}

[CRepr, Packed(1)]
public struct MXDC_GET_FILENAME_DATA_T
{
	public uint32 cbOutput;
	public char16* wszData mut => &wszData_impl;
	private char16[ANYSIZE_ARRAY] wszData_impl;
}

[CRepr, Packed(1)]
public struct MXDC_S0PAGE_DATA_T
{
	public uint32 dwSize;
	public uint8* bData mut => &bData_impl;
	private uint8[ANYSIZE_ARRAY] bData_impl;
}

[CRepr, Packed(1)]
public struct MXDC_XPS_S0PAGE_RESOURCE_T
{
	public uint32 dwSize;
	public uint32 dwResourceType;
	public uint8[260] szUri;
	public uint32 dwDataSize;
	public uint8* bData mut => &bData_impl;
	private uint8[ANYSIZE_ARRAY] bData_impl;
}

[CRepr, Packed(1)]
public struct MXDC_PRINTTICKET_DATA_T
{
	public uint32 dwDataSize;
	public uint8* bData mut => &bData_impl;
	private uint8[ANYSIZE_ARRAY] bData_impl;
}

[CRepr, Packed(1)]
public struct MXDC_PRINTTICKET_ESCAPE_T
{
	public MXDC_ESCAPE_HEADER_T mxdcEscape;
	public MXDC_PRINTTICKET_DATA_T printTicketData;
}

[CRepr, Packed(1)]
public struct MXDC_S0PAGE_PASSTHROUGH_ESCAPE_T
{
	public MXDC_ESCAPE_HEADER_T mxdcEscape;
	public MXDC_S0PAGE_DATA_T xpsS0PageData;
}

[CRepr, Packed(1)]
public struct MXDC_S0PAGE_RESOURCE_ESCAPE_T
{
	public MXDC_ESCAPE_HEADER_T mxdcEscape;
	public MXDC_XPS_S0PAGE_RESOURCE_T xpsS0PageResourcePassthrough;
}

[CRepr]
public struct DEVICEPROPERTYHEADER
{
	public uint16 cbSize;
	public uint16 Flags;
	public HANDLE hPrinter;
	public int8* pszPrinterName;
}

[CRepr]
public struct DOCUMENTPROPERTYHEADER
{
	public uint16 cbSize;
	public uint16 Reserved;
	public HANDLE hPrinter;
	public int8* pszPrinterName;
	public DEVMODEA* pdmIn;
	public DEVMODEA* pdmOut;
	public uint32 cbOut;
	public uint32 fMode;
}

[CRepr]
public struct DEVQUERYPRINT_INFO
{
	public uint16 cbSize;
	public uint16 Level;
	public HANDLE hPrinter;
	public DEVMODEA* pDevMode;
	public PWSTR pszErrorStr;
	public uint32 cchErrorStr;
	public uint32 cchNeeded;
}

[CRepr]
public struct DRIVER_UPGRADE_INFO_1
{
	public int8* pPrinterName;
	public int8* pOldDriverDirectory;
}

[CRepr]
public struct DRIVER_UPGRADE_INFO_2
{
	public int8* pPrinterName;
	public int8* pOldDriverDirectory;
	public uint32 cVersion;
	public int8* pName;
	public int8* pEnvironment;
	public int8* pDriverPath;
	public int8* pDataFile;
	public int8* pConfigFile;
	public int8* pHelpFile;
	public int8* pDependentFiles;
	public int8* pMonitorName;
	public int8* pDefaultDataType;
	public int8* pszzPreviousNames;
}

[CRepr]
public struct DOCEVENT_FILTER
{
	public uint32 cbSize;
	public uint32 cElementsAllocated;
	public uint32 cElementsNeeded;
	public uint32 cElementsReturned;
	public uint32* aDocEventCall mut => &aDocEventCall_impl;
	private uint32[ANYSIZE_ARRAY] aDocEventCall_impl;
}

[CRepr]
public struct DOCEVENT_CREATEDCPRE
{
	public PWSTR pszDriver;
	public PWSTR pszDevice;
	public DEVMODEW* pdm;
	public BOOL bIC;
}

[CRepr]
public struct DOCEVENT_ESCAPE
{
	public int32 iEscape;
	public int32 cjInput;
	public void* pvInData;
}

[CRepr]
public struct PRINTER_EVENT_ATTRIBUTES_INFO
{
	public uint32 cbSize;
	public uint32 dwOldAttributes;
	public uint32 dwNewAttributes;
}

[CRepr]
public struct ATTRIBUTE_INFO_1
{
	public uint32 dwJobNumberOfPagesPerSide;
	public uint32 dwDrvNumberOfPagesPerSide;
	public uint32 dwNupBorderFlags;
	public uint32 dwJobPageOrderFlags;
	public uint32 dwDrvPageOrderFlags;
	public uint32 dwJobNumberOfCopies;
	public uint32 dwDrvNumberOfCopies;
}

[CRepr]
public struct ATTRIBUTE_INFO_2
{
	public uint32 dwJobNumberOfPagesPerSide;
	public uint32 dwDrvNumberOfPagesPerSide;
	public uint32 dwNupBorderFlags;
	public uint32 dwJobPageOrderFlags;
	public uint32 dwDrvPageOrderFlags;
	public uint32 dwJobNumberOfCopies;
	public uint32 dwDrvNumberOfCopies;
	public uint32 dwColorOptimization;
}

[CRepr]
public struct ATTRIBUTE_INFO_3
{
	public uint32 dwJobNumberOfPagesPerSide;
	public uint32 dwDrvNumberOfPagesPerSide;
	public uint32 dwNupBorderFlags;
	public uint32 dwJobPageOrderFlags;
	public uint32 dwDrvPageOrderFlags;
	public uint32 dwJobNumberOfCopies;
	public uint32 dwDrvNumberOfCopies;
	public uint32 dwColorOptimization;
	public int16 dmPrintQuality;
	public int16 dmYResolution;
}

[CRepr]
public struct ATTRIBUTE_INFO_4
{
	public uint32 dwJobNumberOfPagesPerSide;
	public uint32 dwDrvNumberOfPagesPerSide;
	public uint32 dwNupBorderFlags;
	public uint32 dwJobPageOrderFlags;
	public uint32 dwDrvPageOrderFlags;
	public uint32 dwJobNumberOfCopies;
	public uint32 dwDrvNumberOfCopies;
	public uint32 dwColorOptimization;
	public int16 dmPrintQuality;
	public int16 dmYResolution;
	public uint32 dwDuplexFlags;
	public uint32 dwNupDirection;
	public uint32 dwBookletFlags;
	public uint32 dwScalingPercentX;
	public uint32 dwScalingPercentY;
}

[CRepr]
public struct PSCRIPT5_PRIVATE_DEVMODE
{
	public uint16[57] wReserved;
	public uint16 wSize;
}

[CRepr]
public struct UNIDRV_PRIVATE_DEVMODE
{
	public uint16[4] wReserved;
	public uint16 wSize;
}

[CRepr]
public struct PUBLISHERINFO
{
	public uint32 dwMode;
	public uint16 wMinoutlinePPEM;
	public uint16 wMaxbitmapPPEM;
}

[CRepr]
public struct OEMDMPARAM
{
	public uint32 cbSize;
	public void* pdriverobj;
	public HANDLE hPrinter;
	public HANDLE hModule;
	public DEVMODEA* pPublicDMIn;
	public DEVMODEA* pPublicDMOut;
	public void* pOEMDMIn;
	public void* pOEMDMOut;
	public uint32 cbBufSize;
}

[CRepr]
public struct OEM_DMEXTRAHEADER
{
	public uint32 dwSize;
	public uint32 dwSignature;
	public uint32 dwVersion;
}

[CRepr]
public struct USERDATA
{
	public uint32 dwSize;
	public uint dwItemID;
	public PSTR pKeyWordName;
	public uint32[8] dwReserved;
}

[CRepr]
public struct SIMULATE_CAPS_1
{
	public uint32 dwLevel;
	public uint32 dwPageOrderFlags;
	public uint32 dwNumberOfCopies;
	public uint32 dwCollate;
	public uint32 dwNupOptions;
}

[CRepr]
public struct OEMUIPROCS
{
	public PFN_DrvGetDriverSetting DrvGetDriverSetting;
	public PFN_DrvUpdateUISetting DrvUpdateUISetting;
}

[CRepr]
public struct OEMUIOBJ
{
	public uint32 cbSize;
	public OEMUIPROCS* pOemUIProcs;
}

[CRepr]
public struct OEMCUIPPARAM
{
	public uint32 cbSize;
	public OEMUIOBJ* poemuiobj;
	public HANDLE hPrinter;
	public PWSTR pPrinterName;
	public HANDLE hModule;
	public HANDLE hOEMHeap;
	public DEVMODEA* pPublicDM;
	public void* pOEMDM;
	public uint32 dwFlags;
	public OPTITEM* pDrvOptItems;
	public uint32 cDrvOptItems;
	public OPTITEM* pOEMOptItems;
	public uint32 cOEMOptItems;
	public void* pOEMUserData;
	public OEMCUIPCALLBACK OEMCUIPCallback;
}

[CRepr]
public struct OEMUIPSPARAM
{
	public uint32 cbSize;
	public OEMUIOBJ* poemuiobj;
	public HANDLE hPrinter;
	public PWSTR pPrinterName;
	public HANDLE hModule;
	public HANDLE hOEMHeap;
	public DEVMODEA* pPublicDM;
	public void* pOEMDM;
	public void* pOEMUserData;
	public uint32 dwFlags;
	public void* pOemEntry;
}

[CRepr]
public struct CUSTOMSIZEPARAM
{
	public int32 dwOrder;
	public int32 lMinVal;
	public int32 lMaxVal;
}

[CRepr]
public struct PRINT_FEATURE_OPTION
{
	public PSTR pszFeature;
	public PSTR pszOption;
}

[CRepr]
public struct UNIFM_HDR
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 ulDefaultCodepage;
	public int32 lGlyphSetDataRCID;
	public uint32 loUnidrvInfo;
	public uint32 loIFIMetrics;
	public uint32 loExtTextMetric;
	public uint32 loWidthTable;
	public uint32 loKernPair;
	public uint32[2] dwReserved;
}

[CRepr]
public struct INVOC
{
	public uint32 dwCount;
	public uint32 loOffset;
}

[CRepr]
public struct UNIDRVINFO
{
	public uint32 dwSize;
	public uint32 flGenFlags;
	public uint16 wType;
	public uint16 fCaps;
	public uint16 wXRes;
	public uint16 wYRes;
	public int16 sYAdjust;
	public int16 sYMoved;
	public uint16 wPrivateData;
	public int16 sShift;
	public INVOC SelectFont;
	public INVOC UnSelectFont;
	public uint16[4] wReserved;
}

[CRepr]
public struct PRINTIFI32
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

[CRepr]
public struct EXTTEXTMETRIC
{
	public int16 emSize;
	public int16 emPointSize;
	public int16 emOrientation;
	public int16 emMasterHeight;
	public int16 emMinScale;
	public int16 emMaxScale;
	public int16 emMasterUnits;
	public int16 emCapHeight;
	public int16 emXHeight;
	public int16 emLowerCaseAscent;
	public int16 emLowerCaseDescent;
	public int16 emSlant;
	public int16 emSuperScript;
	public int16 emSubScript;
	public int16 emSuperScriptSize;
	public int16 emSubScriptSize;
	public int16 emUnderlineOffset;
	public int16 emUnderlineWidth;
	public int16 emDoubleUpperUnderlineOffset;
	public int16 emDoubleLowerUnderlineOffset;
	public int16 emDoubleUpperUnderlineWidth;
	public int16 emDoubleLowerUnderlineWidth;
	public int16 emStrikeOutOffset;
	public int16 emStrikeOutWidth;
	public uint16 emKernPairs;
	public uint16 emKernTracks;
}

[CRepr]
public struct WIDTHRUN
{
	public uint16 wStartGlyph;
	public uint16 wGlyphCount;
	public uint32 loCharWidthOffset;
}

[CRepr]
public struct WIDTHTABLE
{
	public uint32 dwSize;
	public uint32 dwRunNum;
	public WIDTHRUN* WidthRun mut => &WidthRun_impl;
	private WIDTHRUN[ANYSIZE_ARRAY] WidthRun_impl;
}

[CRepr]
public struct KERNDATA
{
	public uint32 dwSize;
	public uint32 dwKernPairNum;
	public FD_KERNINGPAIR* KernPair mut => &KernPair_impl;
	private FD_KERNINGPAIR[ANYSIZE_ARRAY] KernPair_impl;
}

[CRepr]
public struct UNI_GLYPHSETDATA
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 dwFlags;
	public int32 lPredefinedID;
	public uint32 dwGlyphCount;
	public uint32 dwRunCount;
	public uint32 loRunOffset;
	public uint32 dwCodePageCount;
	public uint32 loCodePageOffset;
	public uint32 loMapTableOffset;
	public uint32[2] dwReserved;
}

[CRepr]
public struct UNI_CODEPAGEINFO
{
	public uint32 dwCodePage;
	public INVOC SelectSymbolSet;
	public INVOC UnSelectSymbolSet;
}

[CRepr]
public struct GLYPHRUN
{
	public char16 wcLow;
	public uint16 wGlyphCount;
}

[CRepr]
public struct TRANSDATA
{
	[CRepr, Union]
	public struct _uCode_e__Union
	{
		public int16 sCode;
		public uint8 ubCode;
		public uint8[2] ubPairs;
	}
	public uint8 ubCodePageID;
	public uint8 ubType;
	public _uCode_e__Union uCode;
}

[CRepr]
public struct MAPTABLE
{
	public uint32 dwSize;
	public uint32 dwGlyphNum;
	public TRANSDATA* Trans mut => &Trans_impl;
	private TRANSDATA[ANYSIZE_ARRAY] Trans_impl;
}

[CRepr]
public struct UFF_FILEHEADER
{
	public uint32 dwSignature;
	public uint32 dwVersion;
	public uint32 dwSize;
	public uint32 nFonts;
	public uint32 nGlyphSets;
	public uint32 nVarData;
	public uint32 offFontDir;
	public uint32 dwFlags;
	public uint32[4] dwReserved;
}

[CRepr]
public struct UFF_FONTDIRECTORY
{
	public uint32 dwSignature;
	public uint16 wSize;
	public uint16 wFontID;
	public int16 sGlyphID;
	public uint16 wFlags;
	public uint32 dwInstallerSig;
	public uint32 offFontName;
	public uint32 offCartridgeName;
	public uint32 offFontData;
	public uint32 offGlyphData;
	public uint32 offVarData;
}

[CRepr]
public struct DATA_HEADER
{
	public uint32 dwSignature;
	public uint16 wSize;
	public uint16 wDataID;
	public uint32 dwDataSize;
	public uint32 dwReserved;
}

[CRepr]
public struct OEMFONTINSTPARAM
{
	public uint32 cbSize;
	public HANDLE hPrinter;
	public HANDLE hModule;
	public HANDLE hHeap;
	public uint32 dwFlags;
	public PWSTR pFontInstallerName;
}

[CRepr]
public struct PORT_DATA_1
{
	public char16[64] sztPortName;
	public uint32 dwVersion;
	public uint32 dwProtocol;
	public uint32 cbSize;
	public uint32 dwReserved;
	public char16[49] sztHostAddress;
	public char16[33] sztSNMPCommunity;
	public uint32 dwDoubleSpool;
	public char16[33] sztQueue;
	public char16[16] sztIPAddress;
	public uint8[540] Reserved;
	public uint32 dwPortNumber;
	public uint32 dwSNMPEnabled;
	public uint32 dwSNMPDevIndex;
}

[CRepr]
public struct PORT_DATA_2
{
	public char16[64] sztPortName;
	public uint32 dwVersion;
	public uint32 dwProtocol;
	public uint32 cbSize;
	public uint32 dwReserved;
	public char16[128] sztHostAddress;
	public char16[33] sztSNMPCommunity;
	public uint32 dwDoubleSpool;
	public char16[33] sztQueue;
	public uint8[514] Reserved;
	public uint32 dwPortNumber;
	public uint32 dwSNMPEnabled;
	public uint32 dwSNMPDevIndex;
	public uint32 dwPortMonitorMibIndex;
}

[CRepr]
public struct PORT_DATA_LIST_1
{
	public uint32 dwVersion;
	public uint32 cPortData;
	public PORT_DATA_2* pPortData mut => &pPortData_impl;
	private PORT_DATA_2[ANYSIZE_ARRAY] pPortData_impl;
}

[CRepr]
public struct DELETE_PORT_DATA_1
{
	public char16[64] psztPortName;
	public uint8[98] Reserved;
	public uint32 dwVersion;
	public uint32 dwReserved;
}

[CRepr]
public struct CONFIG_INFO_DATA_1
{
	public uint8[128] Reserved;
	public uint32 dwVersion;
}

[CRepr]
public struct BranchOfficeJobDataPrinted
{
	public uint32 Status;
	public PWSTR pDocumentName;
	public PWSTR pUserName;
	public PWSTR pMachineName;
	public PWSTR pPrinterName;
	public PWSTR pPortName;
	public int64 Size;
	public uint32 TotalPages;
}

[CRepr]
public struct BranchOfficeJobDataError
{
	public uint32 LastError;
	public PWSTR pDocumentName;
	public PWSTR pUserName;
	public PWSTR pPrinterName;
	public PWSTR pDataType;
	public int64 TotalSize;
	public int64 PrintedSize;
	public uint32 TotalPages;
	public uint32 PrintedPages;
	public PWSTR pMachineName;
	public PWSTR pJobError;
	public PWSTR pErrorDescription;
}

[CRepr]
public struct BranchOfficeJobDataRendered
{
	public int64 Size;
	public uint32 ICMMethod;
	public int16 Color;
	public int16 PrintQuality;
	public int16 YResolution;
	public int16 Copies;
	public int16 TTOption;
}

[CRepr]
public struct BranchOfficeJobDataPipelineFailed
{
	public PWSTR pDocumentName;
	public PWSTR pPrinterName;
	public PWSTR pExtraErrorInfo;
}

[CRepr]
public struct BranchOfficeLogOfflineFileFull
{
	public PWSTR pMachineName;
}

[CRepr]
public struct BranchOfficeJobData
{
	[CRepr, Union]
	public struct _JobInfo_e__Union
	{
		public BranchOfficeJobDataPrinted LogJobPrinted;
		public BranchOfficeJobDataRendered LogJobRendered;
		public BranchOfficeJobDataError LogJobError;
		public BranchOfficeJobDataPipelineFailed LogPipelineFailed;
		public BranchOfficeLogOfflineFileFull LogOfflineFileFull;
	}
	public EBranchOfficeJobEventType eEventType;
	public uint32 JobId;
	public _JobInfo_e__Union JobInfo;
}

[CRepr]
public struct BranchOfficeJobDataContainer
{
	public uint32 cJobDataEntries;
	public BranchOfficeJobData* JobData mut => &JobData_impl;
	private BranchOfficeJobData[ANYSIZE_ARRAY] JobData_impl;
}

[CRepr]
public struct PRINTER_NOTIFY_INIT
{
	public uint32 Size;
	public uint32 Reserved;
	public uint32 PollTime;
}

[CRepr]
public struct SPLCLIENT_INFO_1
{
	public uint32 dwSize;
	public PWSTR pMachineName;
	public PWSTR pUserName;
	public uint32 dwBuildNum;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint16 wProcessorArchitecture;
}

[CRepr]
public struct SPLCLIENT_INFO_2_W2K
{
	public uint hSplPrinter;
}

#if BF_32_BIT
[CRepr]
public struct SPLCLIENT_INFO_2_WINXP
{
	public uint32 hSplPrinter;
}
#endif

[CRepr]
public struct _SPLCLIENT_INFO_2_V3
{
	public uint64 hSplPrinter;
}

[CRepr]
public struct SPLCLIENT_INFO_3_VISTA
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32 dwSize;
	public PWSTR pMachineName;
	public PWSTR pUserName;
	public uint32 dwBuildNum;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint16 wProcessorArchitecture;
	public uint64 hSplPrinter;
}

[CRepr]
public struct PRINTPROVIDOR
{
	public int fpOpenPrinter;
	public int fpSetJob;
	public int fpGetJob;
	public int fpEnumJobs;
	public int fpAddPrinter;
	public int fpDeletePrinter;
	public int fpSetPrinter;
	public int fpGetPrinter;
	public int fpEnumPrinters;
	public int fpAddPrinterDriver;
	public int fpEnumPrinterDrivers;
	public int fpGetPrinterDriver;
	public int fpGetPrinterDriverDirectory;
	public int fpDeletePrinterDriver;
	public int fpAddPrintProcessor;
	public int fpEnumPrintProcessors;
	public int fpGetPrintProcessorDirectory;
	public int fpDeletePrintProcessor;
	public int fpEnumPrintProcessorDatatypes;
	public int fpStartDocPrinter;
	public int fpStartPagePrinter;
	public int fpWritePrinter;
	public int fpEndPagePrinter;
	public int fpAbortPrinter;
	public int fpReadPrinter;
	public int fpEndDocPrinter;
	public int fpAddJob;
	public int fpScheduleJob;
	public int fpGetPrinterData;
	public int fpSetPrinterData;
	public int fpWaitForPrinterChange;
	public int fpClosePrinter;
	public int fpAddForm;
	public int fpDeleteForm;
	public int fpGetForm;
	public int fpSetForm;
	public int fpEnumForms;
	public int fpEnumMonitors;
	public int fpEnumPorts;
	public int fpAddPort;
	public int fpConfigurePort;
	public int fpDeletePort;
	public int fpCreatePrinterIC;
	public int fpPlayGdiScriptOnPrinterIC;
	public int fpDeletePrinterIC;
	public int fpAddPrinterConnection;
	public int fpDeletePrinterConnection;
	public int fpPrinterMessageBox;
	public int fpAddMonitor;
	public int fpDeleteMonitor;
	public int fpResetPrinter;
	public int fpGetPrinterDriverEx;
	public int fpFindFirstPrinterChangeNotification;
	public int fpFindClosePrinterChangeNotification;
	public int fpAddPortEx;
	public int fpShutDown;
	public int fpRefreshPrinterChangeNotification;
	public int fpOpenPrinterEx;
	public int fpAddPrinterEx;
	public int fpSetPort;
	public int fpEnumPrinterData;
	public int fpDeletePrinterData;
	public int fpClusterSplOpen;
	public int fpClusterSplClose;
	public int fpClusterSplIsAlive;
	public int fpSetPrinterDataEx;
	public int fpGetPrinterDataEx;
	public int fpEnumPrinterDataEx;
	public int fpEnumPrinterKey;
	public int fpDeletePrinterDataEx;
	public int fpDeletePrinterKey;
	public int fpSeekPrinter;
	public int fpDeletePrinterDriverEx;
	public int fpAddPerMachineConnection;
	public int fpDeletePerMachineConnection;
	public int fpEnumPerMachineConnections;
	public int fpXcvData;
	public int fpAddPrinterDriverEx;
	public int fpSplReadPrinter;
	public int fpDriverUnloadComplete;
	public int fpGetSpoolFileInfo;
	public int fpCommitSpoolData;
	public int fpCloseSpoolFileHandle;
	public int fpFlushPrinter;
	public int fpSendRecvBidiData;
	public int fpAddPrinterConnection2;
	public int fpGetPrintClassObject;
	public int fpReportJobProcessingProgress;
	public int fpEnumAndLogProvidorObjects;
	public int fpInternalGetPrinterDriver;
	public int fpFindCompatibleDriver;
	public int fpGetJobNamedPropertyValue;
	public int fpSetJobNamedProperty;
	public int fpDeleteJobNamedProperty;
	public int fpEnumJobNamedProperties;
	public int fpPowerEvent;
	public int fpGetUserPropertyBag;
	public int fpCanShutdown;
	public int fpLogJobInfoForBranchOffice;
	public int fpRegeneratePrintDeviceCapabilities;
	public int fpPrintSupportOperation;
	public int fpIppCreateJobOnPrinter;
	public int fpIppGetJobAttributes;
	public int fpIppSetJobAttributes;
	public int fpIppGetPrinterAttributes;
	public int fpIppSetPrinterAttributes;
}

[CRepr]
public struct PRINTPROCESSOROPENDATA
{
	public DEVMODEA* pDevMode;
	public PWSTR pDatatype;
	public PWSTR pParameters;
	public PWSTR pDocumentName;
	public uint32 JobId;
	public PWSTR pOutputFile;
	public PWSTR pPrinterName;
}

[CRepr]
public struct MONITORREG
{
	public uint32 cbSize;
	public int fpCreateKey;
	public int fpOpenKey;
	public int fpCloseKey;
	public int fpDeleteKey;
	public int fpEnumKey;
	public int fpQueryInfoKey;
	public int fpSetValue;
	public int fpDeleteValue;
	public int fpEnumValue;
	public int fpQueryValue;
}

[CRepr]
public struct MONITORINIT
{
	public uint32 cbSize;
	public HANDLE hSpooler;
	public HKEY hckRegistryRoot;
	public MONITORREG* pMonitorReg;
	public BOOL bLocal;
	public PWSTR pszServerName;
}

[CRepr]
public struct MONITOR
{
	public int pfnEnumPorts;
	public int pfnOpenPort;
	public int pfnOpenPortEx;
	public int pfnStartDocPort;
	public int pfnWritePort;
	public int pfnReadPort;
	public int pfnEndDocPort;
	public int pfnClosePort;
	public int pfnAddPort;
	public int pfnAddPortEx;
	public int pfnConfigurePort;
	public int pfnDeletePort;
	public int pfnGetPrinterDataFromPort;
	public int pfnSetPortTimeOuts;
	public int pfnXcvOpenPort;
	public int pfnXcvDataPort;
	public int pfnXcvClosePort;
}

[CRepr]
public struct MONITOREX
{
	public uint32 dwMonitorSize;
	public MONITOR Monitor;
}

[CRepr]
public struct MONITOR2
{
	public uint32 cbSize;
	public int pfnEnumPorts;
	public int pfnOpenPort;
	public int pfnOpenPortEx;
	public int pfnStartDocPort;
	public int pfnWritePort;
	public int pfnReadPort;
	public int pfnEndDocPort;
	public int pfnClosePort;
	public int pfnAddPort;
	public int pfnAddPortEx;
	public int pfnConfigurePort;
	public int pfnDeletePort;
	public int pfnGetPrinterDataFromPort;
	public int pfnSetPortTimeOuts;
	public int pfnXcvOpenPort;
	public int pfnXcvDataPort;
	public int pfnXcvClosePort;
	public int pfnShutdown;
	public int pfnSendRecvBidiDataFromPort;
	public int pfnNotifyUsedPorts;
	public int pfnNotifyUnusedPorts;
	public int pfnPowerEvent;
}

[CRepr]
public struct MONITORUI
{
	public uint32 dwMonitorUISize;
	public int pfnAddPortUI;
	public int pfnConfigurePortUI;
	public int pfnDeletePortUI;
}

[CRepr]
public struct NOTIFICATION_CONFIG_1
{
	public uint32 cbSize;
	public uint32 fdwFlags;
	public ROUTER_NOTIFY_CALLBACK pfnNotifyCallback;
	public void* pContext;
}

[CRepr]
public struct MESSAGEBOX_PARAMS
{
	public uint32 cbSize;
	public PWSTR pTitle;
	public PWSTR pMessage;
	public uint32 Style;
	public uint32 dwTimeout;
	public BOOL bWait;
}

[CRepr]
public struct SHOWUIPARAMS
{
	public UI_TYPE UIType;
	public MESSAGEBOX_PARAMS MessageBoxParams;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_BidiRequest = .(0xb9162a23, 0x45f9, 0x47cc, 0x80, 0xf5, 0xfe, 0x0f, 0xe9, 0xb9, 0xe1, 0xa2);


	public const Guid CLSID_BidiRequestContainer = .(0xfc5b8a24, 0xdb05, 0x4a01, 0x83, 0x88, 0x22, 0xed, 0xf6, 0xc2, 0xbb, 0xba);


	public const Guid CLSID_BidiSpl = .(0x2a614240, 0xa4c5, 0x4c33, 0xbd, 0x87, 0x1b, 0xc7, 0x09, 0x33, 0x16, 0x39);


	public const Guid CLSID_PrinterQueue = .(0xeb54c230, 0x798c, 0x4c9e, 0xb4, 0x61, 0x29, 0xfa, 0xd0, 0x40, 0x39, 0xb1);


	public const Guid CLSID_PrinterQueueView = .(0xeb54c231, 0x798c, 0x4c9e, 0xb4, 0x61, 0x29, 0xfa, 0xd0, 0x40, 0x39, 0xb1);


	public const Guid CLSID_PrintSchemaAsyncOperation = .(0x43b2f83d, 0x10f2, 0x48ab, 0x83, 0x1b, 0x55, 0xfd, 0xbd, 0xbd, 0x34, 0xa4);


	public const Guid CLSID_PrinterExtensionManager = .(0x331b60da, 0x9e90, 0x4dd0, 0x9c, 0x84, 0xea, 0xc4, 0xe6, 0x59, 0xb6, 0x1f);


}
#endregion

#region COM Types
[CRepr]struct IBidiRequest : IUnknown
{
	public new const Guid IID = .(0x8f348bd7, 0x4b47, 0x4755, 0x8a, 0x9d, 0x0f, 0x42, 0x2d, 0xf3, 0xdc, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSchema) SetSchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwType, uint8* pData, uint32 uSize) SetInputData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phr) GetResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, PWSTR* ppszSchema, uint32* pdwType, uint8** ppData, uint32* uSize) GetOutputData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwTotal) GetEnumCount;
	}


	public HRESULT SetSchema(PWSTR pszSchema) mut => VT.[Friend]SetSchema(&this, pszSchema);

	public HRESULT SetInputData(uint32 dwType, uint8* pData, uint32 uSize) mut => VT.[Friend]SetInputData(&this, dwType, pData, uSize);

	public HRESULT GetResult(HRESULT* phr) mut => VT.[Friend]GetResult(&this, phr);

	public HRESULT GetOutputData(uint32 dwIndex, PWSTR* ppszSchema, uint32* pdwType, uint8** ppData, uint32* uSize) mut => VT.[Friend]GetOutputData(&this, dwIndex, ppszSchema, pdwType, ppData, uSize);

	public HRESULT GetEnumCount(uint32* pdwTotal) mut => VT.[Friend]GetEnumCount(&this, pdwTotal);
}

[CRepr]struct IBidiRequestContainer : IUnknown
{
	public new const Guid IID = .(0xd752f6c0, 0x94a8, 0x4275, 0xa7, 0x7d, 0x8f, 0x1d, 0x1a, 0x11, 0x21, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBidiRequest* pRequest) AddRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** ppenum) GetEnumObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetRequestCount;
	}


	public HRESULT AddRequest(IBidiRequest* pRequest) mut => VT.[Friend]AddRequest(&this, pRequest);

	public HRESULT GetEnumObject(IEnumUnknown** ppenum) mut => VT.[Friend]GetEnumObject(&this, ppenum);

	public HRESULT GetRequestCount(uint32* puCount) mut => VT.[Friend]GetRequestCount(&this, puCount);
}

[CRepr]struct IBidiSpl : IUnknown
{
	public new const Guid IID = .(0xd580dc0e, 0xde39, 0x4649, 0xba, 0xa8, 0xbf, 0x0b, 0x85, 0xa0, 0x3a, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceName, uint32 dwAccess) BindDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnbindDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAction, IBidiRequest* pRequest) SendRecv;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAction, IBidiRequestContainer* pRequestContainer) MultiSendRecv;
	}


	public HRESULT BindDevice(PWSTR pszDeviceName, uint32 dwAccess) mut => VT.[Friend]BindDevice(&this, pszDeviceName, dwAccess);

	public HRESULT UnbindDevice() mut => VT.[Friend]UnbindDevice(&this);

	public HRESULT SendRecv(PWSTR pszAction, IBidiRequest* pRequest) mut => VT.[Friend]SendRecv(&this, pszAction, pRequest);

	public HRESULT MultiSendRecv(PWSTR pszAction, IBidiRequestContainer* pRequestContainer) mut => VT.[Friend]MultiSendRecv(&this, pszAction, pRequestContainer);
}

[CRepr]struct IBidiSpl2 : IUnknown
{
	public new const Guid IID = .(0x0e8f51b8, 0x8273, 0x4906, 0x8e, 0x7b, 0xbe, 0x45, 0x3f, 0xfd, 0x2e, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceName, uint32 dwAccess) BindDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnbindDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRequest, BSTR* pbstrResponse) SendRecvXMLString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pSRequest, IStream** ppSResponse) SendRecvXMLStream;
	}


	public HRESULT BindDevice(PWSTR pszDeviceName, uint32 dwAccess) mut => VT.[Friend]BindDevice(&this, pszDeviceName, dwAccess);

	public HRESULT UnbindDevice() mut => VT.[Friend]UnbindDevice(&this);

	public HRESULT SendRecvXMLString(BSTR bstrRequest, BSTR* pbstrResponse) mut => VT.[Friend]SendRecvXMLString(&this, bstrRequest, pbstrResponse);

	public HRESULT SendRecvXMLStream(IStream* pSRequest, IStream** ppSResponse) mut => VT.[Friend]SendRecvXMLStream(&this, pSRequest, ppSResponse);
}

[CRepr]struct IImgErrorInfo : IErrorInfo
{
	public new const Guid IID = .(0x2bce4ece, 0xd30e, 0x445a, 0x94, 0x23, 0x68, 0x29, 0xbe, 0x94, 0x5a, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IErrorInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDevDescription) GetDeveloperDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pErrorId) GetUserErrorId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcUserParams) GetUserParameterCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cParam, BSTR* pbstrParam) GetUserParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFallback) GetUserFallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pExceptionId) GetExceptionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ImgErrorInfo* pErrorInfo) DetachErrorInfo;
	}


	public HRESULT GetDeveloperDescription(BSTR* pbstrDevDescription) mut => VT.[Friend]GetDeveloperDescription(&this, pbstrDevDescription);

	public HRESULT GetUserErrorId(Guid* pErrorId) mut => VT.[Friend]GetUserErrorId(&this, pErrorId);

	public HRESULT GetUserParameterCount(uint32* pcUserParams) mut => VT.[Friend]GetUserParameterCount(&this, pcUserParams);

	public HRESULT GetUserParameter(uint32 cParam, BSTR* pbstrParam) mut => VT.[Friend]GetUserParameter(&this, cParam, pbstrParam);

	public HRESULT GetUserFallback(BSTR* pbstrFallback) mut => VT.[Friend]GetUserFallback(&this, pbstrFallback);

	public HRESULT GetExceptionId(uint32* pExceptionId) mut => VT.[Friend]GetExceptionId(&this, pExceptionId);

	public HRESULT DetachErrorInfo(ImgErrorInfo* pErrorInfo) mut => VT.[Friend]DetachErrorInfo(&this, pErrorInfo);
}

[CRepr]struct IImgCreateErrorInfo : ICreateErrorInfo
{
	public new const Guid IID = .(0x1c55a64c, 0x07cd, 0x4fb5, 0x90, 0xf7, 0xb7, 0x53, 0xd9, 0x1f, 0x0c, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICreateErrorInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ImgErrorInfo* pErrorInfo) AttachToErrorInfo;
	}


	public HRESULT AttachToErrorInfo(ImgErrorInfo* pErrorInfo) mut => VT.[Friend]AttachToErrorInfo(&this, pErrorInfo);
}

[CRepr]struct IPrintReadStream : IUnknown
{
	public new const Guid IID = .(0x4d47a67c, 0x66cc, 0x4430, 0x85, 0x0e, 0xda, 0xf4, 0x66, 0xfe, 0x5b, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 dlibMove, uint32 dwOrigin, uint64* plibNewPosition) Seek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvBuffer, uint32 cbRequested, uint32* pcbRead, BOOL* pbEndOfFile) ReadBytes;
	}


	public HRESULT Seek(int64 dlibMove, uint32 dwOrigin, uint64* plibNewPosition) mut => VT.[Friend]Seek(&this, dlibMove, dwOrigin, plibNewPosition);

	public HRESULT ReadBytes(void* pvBuffer, uint32 cbRequested, uint32* pcbRead, BOOL* pbEndOfFile) mut => VT.[Friend]ReadBytes(&this, pvBuffer, cbRequested, pcbRead, pbEndOfFile);
}

[CRepr]struct IPrintWriteStream : IUnknown
{
	public new const Guid IID = .(0x65bb7f1b, 0x371e, 0x4571, 0x8a, 0xc7, 0x91, 0x2f, 0x51, 0x0c, 0x1a, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvBuffer, uint32 cbBuffer, uint32* pcbWritten) WriteBytes;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Close;
	}


	public HRESULT WriteBytes(void* pvBuffer, uint32 cbBuffer, uint32* pcbWritten) mut => VT.[Friend]WriteBytes(&this, pvBuffer, cbBuffer, pcbWritten);

	public void Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IPrintWriteStreamFlush : IUnknown
{
	public new const Guid IID = .(0x07d11ff8, 0x1753, 0x4873, 0xb7, 0x49, 0x6c, 0xda, 0xf0, 0x68, 0xe4, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlushData;
	}


	public HRESULT FlushData() mut => VT.[Friend]FlushData(&this);
}

[CRepr]struct IInterFilterCommunicator : IUnknown
{
	public new const Guid IID = .(0x4daf1e69, 0x81fd, 0x462d, 0x94, 0x0f, 0x8c, 0xd3, 0xdd, 0xf5, 0x6f, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** ppIReader) RequestReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** ppIWriter) RequestWriter;
	}


	public HRESULT RequestReader(void** ppIReader) mut => VT.[Friend]RequestReader(&this, ppIReader);

	public HRESULT RequestWriter(void** ppIWriter) mut => VT.[Friend]RequestWriter(&this, ppIWriter);
}

[CRepr]struct IPrintPipelineManagerControl : IUnknown
{
	public new const Guid IID = .(0xaa3e4910, 0x5889, 0x4681, 0x91, 0xef, 0x82, 0x3a, 0xd4, 0xed, 0x4e, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrReason, IImgErrorInfo* pReason) RequestShutdown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FilterFinished;
	}


	public HRESULT RequestShutdown(HRESULT hrReason, IImgErrorInfo* pReason) mut => VT.[Friend]RequestShutdown(&this, hrReason, pReason);

	public HRESULT FilterFinished() mut => VT.[Friend]FilterFinished(&this);
}

[CRepr]struct IPrintPipelinePropertyBag : IUnknown
{
	public new const Guid IID = .(0x8b8c99dc, 0x7892, 0x4a95, 0x8a, 0x04, 0x57, 0x42, 0x2e, 0x9f, 0xbb, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, VARIANT* pVar) AddProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, VARIANT* pVar) GetProperty;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, PWSTR pszName) DeleteProperty;
	}


	public HRESULT AddProperty(PWSTR pszName, VARIANT* pVar) mut => VT.[Friend]AddProperty(&this, pszName, pVar);

	public HRESULT GetProperty(PWSTR pszName, VARIANT* pVar) mut => VT.[Friend]GetProperty(&this, pszName, pVar);

	public BOOL DeleteProperty(PWSTR pszName) mut => VT.[Friend]DeleteProperty(&this, pszName);
}

[CRepr]struct IPrintPipelineProgressReport : IUnknown
{
	public new const Guid IID = .(0xedc12c7c, 0xed40, 0x4ea5, 0x96, 0xa6, 0x5e, 0x43, 0x97, 0x49, 0x7a, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXpsJobConsumption update) ReportProgress;
	}


	public HRESULT ReportProgress(EXpsJobConsumption update) mut => VT.[Friend]ReportProgress(&this, update);
}

[CRepr]struct IPrintClassObjectFactory : IUnknown
{
	public new const Guid IID = .(0x9af593dd, 0x9b02, 0x48a8, 0x9b, 0xad, 0x69, 0xac, 0xe4, 0x23, 0xf8, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPrinterName, in Guid riid, void** ppNewObject) GetPrintClassObject;
	}


	public HRESULT GetPrintClassObject(PWSTR pszPrinterName, in Guid riid, void** ppNewObject) mut => VT.[Friend]GetPrintClassObject(&this, pszPrinterName, riid, ppNewObject);
}

[CRepr]struct IPrintPipelineFilter : IUnknown
{
	public new const Guid IID = .(0xcdb62fc0, 0x8bed, 0x434e, 0x86, 0xfb, 0xa2, 0xca, 0xe5, 0x5f, 0x19, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInterFilterCommunicator* pINegotiation, IPrintPipelinePropertyBag* pIPropertyBag, IPrintPipelineManagerControl* pIPipelineControl) InitializeFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShutdownOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartOperation;
	}


	public HRESULT InitializeFilter(IInterFilterCommunicator* pINegotiation, IPrintPipelinePropertyBag* pIPropertyBag, IPrintPipelineManagerControl* pIPipelineControl) mut => VT.[Friend]InitializeFilter(&this, pINegotiation, pIPropertyBag, pIPipelineControl);

	public HRESULT ShutdownOperation() mut => VT.[Friend]ShutdownOperation(&this);

	public HRESULT StartOperation() mut => VT.[Friend]StartOperation(&this);
}

[CRepr]struct IXpsDocumentProvider : IUnknown
{
	public new const Guid IID = .(0xb8cf8530, 0x5562, 0x47c4, 0xab, 0x67, 0xb1, 0xf6, 0x9e, 0xcf, 0x96, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppIXpsPart) GetXpsPart;
	}


	public HRESULT GetXpsPart(IUnknown** ppIXpsPart) mut => VT.[Friend]GetXpsPart(&this, ppIXpsPart);
}

[CRepr]struct IXpsDocumentConsumer : IUnknown
{
	public new const Guid IID = .(0x4368d8a2, 0x4181, 0x4a9f, 0xb2, 0x95, 0x3d, 0x9a, 0x38, 0xbb, 0x9b, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnknown) SendXpsUnknown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsDocument* pIXpsDocument) SendXpsDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFixedDocumentSequence* pIFixedDocumentSequence) SendFixedDocumentSequence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFixedDocument* pIFixedDocument) SendFixedDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFixedPage* pIFixedPage) SendFixedPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CloseSender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR uri, in Guid riid, void** ppNewObject, IPrintWriteStream** ppWriteStream) GetNewEmptyPart;
	}


	public HRESULT SendXpsUnknown(IUnknown* pUnknown) mut => VT.[Friend]SendXpsUnknown(&this, pUnknown);

	public HRESULT SendXpsDocument(IXpsDocument* pIXpsDocument) mut => VT.[Friend]SendXpsDocument(&this, pIXpsDocument);

	public HRESULT SendFixedDocumentSequence(IFixedDocumentSequence* pIFixedDocumentSequence) mut => VT.[Friend]SendFixedDocumentSequence(&this, pIFixedDocumentSequence);

	public HRESULT SendFixedDocument(IFixedDocument* pIFixedDocument) mut => VT.[Friend]SendFixedDocument(&this, pIFixedDocument);

	public HRESULT SendFixedPage(IFixedPage* pIFixedPage) mut => VT.[Friend]SendFixedPage(&this, pIFixedPage);

	public HRESULT CloseSender() mut => VT.[Friend]CloseSender(&this);

	public HRESULT GetNewEmptyPart(PWSTR uri, in Guid riid, void** ppNewObject, IPrintWriteStream** ppWriteStream) mut => VT.[Friend]GetNewEmptyPart(&this, uri, riid, ppNewObject, ppWriteStream);
}

[CRepr]struct IXpsDocument : IUnknown
{
	public new const Guid IID = .(0xe8d907db, 0x62a9, 0x4a95, 0xab, 0xe7, 0xe0, 0x17, 0x63, 0xdd, 0x30, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartThumbnail** ppThumbnail) GetThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartThumbnail* pThumbnail) SetThumbnail;
	}


	public HRESULT GetThumbnail(IPartThumbnail** ppThumbnail) mut => VT.[Friend]GetThumbnail(&this, ppThumbnail);

	public HRESULT SetThumbnail(IPartThumbnail* pThumbnail) mut => VT.[Friend]SetThumbnail(&this, pThumbnail);
}

[CRepr]struct IFixedDocumentSequence : IUnknown
{
	public new const Guid IID = .(0x8028d181, 0x2c32, 0x4249, 0x84, 0x93, 0x1b, 0xfb, 0x22, 0x04, 0x55, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* uri) GetUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartPrintTicket** ppPrintTicket) GetPrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartPrintTicket* pPrintTicket) SetPrintTicket;
	}


	public HRESULT GetUri(BSTR* uri) mut => VT.[Friend]GetUri(&this, uri);

	public HRESULT GetPrintTicket(IPartPrintTicket** ppPrintTicket) mut => VT.[Friend]GetPrintTicket(&this, ppPrintTicket);

	public HRESULT SetPrintTicket(IPartPrintTicket* pPrintTicket) mut => VT.[Friend]SetPrintTicket(&this, pPrintTicket);
}

[CRepr]struct IFixedDocument : IUnknown
{
	public new const Guid IID = .(0xf222ca9f, 0x9968, 0x4db9, 0x81, 0xbd, 0xab, 0xae, 0xbf, 0x15, 0xf9, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* uri) GetUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartPrintTicket** ppPrintTicket) GetPrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartPrintTicket* pPrintTicket) SetPrintTicket;
	}


	public HRESULT GetUri(BSTR* uri) mut => VT.[Friend]GetUri(&this, uri);

	public HRESULT GetPrintTicket(IPartPrintTicket** ppPrintTicket) mut => VT.[Friend]GetPrintTicket(&this, ppPrintTicket);

	public HRESULT SetPrintTicket(IPartPrintTicket* pPrintTicket) mut => VT.[Friend]SetPrintTicket(&this, pPrintTicket);
}

[CRepr]struct IPartBase : IUnknown
{
	public new const Guid IID = .(0x36d51e28, 0x369e, 0x43ba, 0xa6, 0x66, 0x95, 0x40, 0xc6, 0x2c, 0x3f, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* uri) GetUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintReadStream** ppStream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXpsCompressionOptions* pCompression) GetPartCompression;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXpsCompressionOptions compression) SetPartCompression;
	}


	public HRESULT GetUri(BSTR* uri) mut => VT.[Friend]GetUri(&this, uri);

	public HRESULT GetStream(IPrintReadStream** ppStream) mut => VT.[Friend]GetStream(&this, ppStream);

	public HRESULT GetPartCompression(EXpsCompressionOptions* pCompression) mut => VT.[Friend]GetPartCompression(&this, pCompression);

	public HRESULT SetPartCompression(EXpsCompressionOptions compression) mut => VT.[Friend]SetPartCompression(&this, compression);
}

[CRepr]struct IFixedPage : IPartBase
{
	public new const Guid IID = .(0x3d9f6448, 0x7e95, 0x4cb5, 0x94, 0xfb, 0x01, 0x80, 0xc2, 0x88, 0x3a, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartPrintTicket** ppPrintTicket) GetPrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR uri, IUnknown** ppUnk) GetPagePart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintWriteStream** ppWriteStream) GetWriteStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPartPrintTicket* ppPrintTicket) SetPrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnk) SetPagePart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR uri) DeleteResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsPartIterator** pXpsPartIt) GetXpsPartIterator;
	}


	public HRESULT GetPrintTicket(IPartPrintTicket** ppPrintTicket) mut => VT.[Friend]GetPrintTicket(&this, ppPrintTicket);

	public HRESULT GetPagePart(PWSTR uri, IUnknown** ppUnk) mut => VT.[Friend]GetPagePart(&this, uri, ppUnk);

	public HRESULT GetWriteStream(IPrintWriteStream** ppWriteStream) mut => VT.[Friend]GetWriteStream(&this, ppWriteStream);

	public HRESULT SetPrintTicket(IPartPrintTicket* ppPrintTicket) mut => VT.[Friend]SetPrintTicket(&this, ppPrintTicket);

	public HRESULT SetPagePart(IUnknown* pUnk) mut => VT.[Friend]SetPagePart(&this, pUnk);

	public HRESULT DeleteResource(PWSTR uri) mut => VT.[Friend]DeleteResource(&this, uri);

	public HRESULT GetXpsPartIterator(IXpsPartIterator** pXpsPartIt) mut => VT.[Friend]GetXpsPartIterator(&this, pXpsPartIt);
}

[CRepr]struct IPartImage : IPartBase
{
	public new const Guid IID = .(0x725f2e3c, 0x401a, 0x4705, 0x9d, 0xe0, 0xfe, 0x6f, 0x13, 0x53, 0xb8, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pContentType) GetImageProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pContentType) SetImageContent;
	}


	public HRESULT GetImageProperties(BSTR* pContentType) mut => VT.[Friend]GetImageProperties(&this, pContentType);

	public HRESULT SetImageContent(PWSTR pContentType) mut => VT.[Friend]SetImageContent(&this, pContentType);
}

[CRepr]struct IPartFont : IPartBase
{
	public new const Guid IID = .(0xe07fe0ab, 0x1124, 0x43d0, 0xa8, 0x65, 0xe8, 0xff, 0xb6, 0xa3, 0xea, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pContentType, EXpsFontOptions* pFontOptions) GetFontProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pContentType) SetFontContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXpsFontOptions options) SetFontOptions;
	}


	public HRESULT GetFontProperties(BSTR* pContentType, EXpsFontOptions* pFontOptions) mut => VT.[Friend]GetFontProperties(&this, pContentType, pFontOptions);

	public HRESULT SetFontContent(PWSTR pContentType) mut => VT.[Friend]SetFontContent(&this, pContentType);

	public HRESULT SetFontOptions(EXpsFontOptions options) mut => VT.[Friend]SetFontOptions(&this, options);
}

[CRepr]struct IPartFont2 : IPartFont
{
	public new const Guid IID = .(0x511e025f, 0xd6cb, 0x43be, 0xbf, 0x65, 0x63, 0xfe, 0x88, 0x51, 0x5a, 0x39);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartFont.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXpsFontRestriction* pRestriction) GetFontRestriction;
	}


	public HRESULT GetFontRestriction(EXpsFontRestriction* pRestriction) mut => VT.[Friend]GetFontRestriction(&this, pRestriction);
}

[CRepr]struct IPartThumbnail : IPartBase
{
	public new const Guid IID = .(0x027ed1c9, 0xba39, 0x4cc5, 0xaa, 0x55, 0x7e, 0xc3, 0xa0, 0xde, 0x17, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pContentType) GetThumbnailProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pContentType) SetThumbnailContent;
	}


	public HRESULT GetThumbnailProperties(BSTR* pContentType) mut => VT.[Friend]GetThumbnailProperties(&this, pContentType);

	public HRESULT SetThumbnailContent(PWSTR pContentType) mut => VT.[Friend]SetThumbnailContent(&this, pContentType);
}

[CRepr]struct IPartPrintTicket : IPartBase
{
	public new const Guid IID = .(0x4a0f50f6, 0xf9a2, 0x41f0, 0x99, 0xe7, 0x5a, 0xe9, 0x55, 0xbe, 0x8e, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
	}

}

[CRepr]struct IPartColorProfile : IPartBase
{
	public new const Guid IID = .(0x63cca95b, 0x7d18, 0x4762, 0xb1, 0x5e, 0x98, 0x65, 0x86, 0x93, 0xd2, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
	}

}

[CRepr]struct IPartResourceDictionary : IPartBase
{
	public new const Guid IID = .(0x16cfce6d, 0xe744, 0x4fb3, 0xb4, 0x74, 0xf1, 0xd5, 0x4f, 0x02, 0x4a, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPartBase.VTable
	{
	}

}

[CRepr]struct IXpsPartIterator : IUnknown
{
	public new const Guid IID = .(0x0021d3cd, 0xaf6f, 0x42ab, 0x99, 0x99, 0x14, 0xbc, 0x82, 0xa6, 0x2d, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pUri, IUnknown** ppXpsPart) Current;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsDone;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Next;
	}


	public void Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Current(BSTR* pUri, IUnknown** ppXpsPart) mut => VT.[Friend]Current(&this, pUri, ppXpsPart);

	public BOOL IsDone() mut => VT.[Friend]IsDone(&this);

	public void Next() mut => VT.[Friend]Next(&this);
}

[CRepr]struct IPrintReadStreamFactory : IUnknown
{
	public new const Guid IID = .(0xacb971e3, 0xdf8d, 0x4fc2, 0xbe, 0xe6, 0x06, 0x09, 0xd1, 0x5f, 0x3c, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintReadStream** ppStream) GetStream;
	}


	public HRESULT GetStream(IPrintReadStream** ppStream) mut => VT.[Friend]GetStream(&this, ppStream);
}

[CRepr]struct IPartDiscardControl : IUnknown
{
	public new const Guid IID = .(0xcc350c00, 0x095b, 0x42a5, 0xbf, 0x0f, 0xc8, 0x78, 0x0e, 0xda, 0xdb, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* uriSentinelPage, BSTR* uriPartToDiscard) GetDiscardProperties;
	}


	public HRESULT GetDiscardProperties(BSTR* uriSentinelPage, BSTR* uriPartToDiscard) mut => VT.[Friend]GetDiscardProperties(&this, uriSentinelPage, uriPartToDiscard);
}

[CRepr]struct IPrintCoreHelper : IUnknown
{
	public new const Guid IID = .(0xa89ec53e, 0x3905, 0x49c6, 0x9c, 0x1a, 0xc0, 0xa8, 0x81, 0x17, 0xfd, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevmode, uint32 cbSize, PSTR pszFeatureRequested, PSTR* ppszOption) GetOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevmode, uint32 cbSize, BOOL bResolveConflicts, PRINT_FEATURE_OPTION* pFOPairs, uint32 cPairs, uint32* pcPairsWritten, uint32* pdwResult) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevmode, uint32 cbSize, PSTR pszFeatureKeyword, PSTR*** pConstrainedOptionList, uint32* pdwNumOptions) EnumConstrainedOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevmode, uint32 cbSize, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PRINT_FEATURE_OPTION** ppFOConstraints, uint32* pdwNumOptions) WhyConstrained;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR*** pFeatureList, uint32* pdwNumFeatures) EnumFeatures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFeatureKeyword, PSTR*** pOptionList, uint32* pdwNumOptions) EnumOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTrueTypeFontName, PWSTR* ppszDevFontName) GetFontSubstitution;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTrueTypeFontName, PWSTR pszDevFontName) SetFontSubstitution;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, IUnknown* pUnkOuter, uint32 dwClsContext, in Guid riid, void** ppv) CreateInstanceOfMSXMLObject;
	}


	public HRESULT GetOption(DEVMODEA* pDevmode, uint32 cbSize, PSTR pszFeatureRequested, PSTR* ppszOption) mut => VT.[Friend]GetOption(&this, pDevmode, cbSize, pszFeatureRequested, ppszOption);

	public HRESULT SetOptions(DEVMODEA* pDevmode, uint32 cbSize, BOOL bResolveConflicts, PRINT_FEATURE_OPTION* pFOPairs, uint32 cPairs, uint32* pcPairsWritten, uint32* pdwResult) mut => VT.[Friend]SetOptions(&this, pDevmode, cbSize, bResolveConflicts, pFOPairs, cPairs, pcPairsWritten, pdwResult);

	public HRESULT EnumConstrainedOptions(DEVMODEA* pDevmode, uint32 cbSize, PSTR pszFeatureKeyword, PSTR*** pConstrainedOptionList, uint32* pdwNumOptions) mut => VT.[Friend]EnumConstrainedOptions(&this, pDevmode, cbSize, pszFeatureKeyword, pConstrainedOptionList, pdwNumOptions);

	public HRESULT WhyConstrained(DEVMODEA* pDevmode, uint32 cbSize, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PRINT_FEATURE_OPTION** ppFOConstraints, uint32* pdwNumOptions) mut => VT.[Friend]WhyConstrained(&this, pDevmode, cbSize, pszFeatureKeyword, pszOptionKeyword, ppFOConstraints, pdwNumOptions);

	public HRESULT EnumFeatures(PSTR*** pFeatureList, uint32* pdwNumFeatures) mut => VT.[Friend]EnumFeatures(&this, pFeatureList, pdwNumFeatures);

	public HRESULT EnumOptions(PSTR pszFeatureKeyword, PSTR*** pOptionList, uint32* pdwNumOptions) mut => VT.[Friend]EnumOptions(&this, pszFeatureKeyword, pOptionList, pdwNumOptions);

	public HRESULT GetFontSubstitution(PWSTR pszTrueTypeFontName, PWSTR* ppszDevFontName) mut => VT.[Friend]GetFontSubstitution(&this, pszTrueTypeFontName, ppszDevFontName);

	public HRESULT SetFontSubstitution(PWSTR pszTrueTypeFontName, PWSTR pszDevFontName) mut => VT.[Friend]SetFontSubstitution(&this, pszTrueTypeFontName, pszDevFontName);

	public HRESULT CreateInstanceOfMSXMLObject(in Guid rclsid, IUnknown* pUnkOuter, uint32 dwClsContext, in Guid riid, void** ppv) mut => VT.[Friend]CreateInstanceOfMSXMLObject(&this, rclsid, pUnkOuter, dwClsContext, riid, ppv);
}

[CRepr]struct IPrintCoreHelperUni : IPrintCoreHelper
{
	public new const Guid IID = .(0x7e8e51d6, 0xe5ee, 0x4426, 0x81, 0x7b, 0x95, 0x8b, 0x94, 0x44, 0xeb, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintCoreHelper.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevmode, uint32 cbSize, uint32 dwFlags, IStream** ppSnapshotStream) CreateGDLSnapshot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IStream** ppSnapshotStream) CreateDefaultGDLSnapshot;
	}


	public HRESULT CreateGDLSnapshot(DEVMODEA* pDevmode, uint32 cbSize, uint32 dwFlags, IStream** ppSnapshotStream) mut => VT.[Friend]CreateGDLSnapshot(&this, pDevmode, cbSize, dwFlags, ppSnapshotStream);

	public HRESULT CreateDefaultGDLSnapshot(uint32 dwFlags, IStream** ppSnapshotStream) mut => VT.[Friend]CreateDefaultGDLSnapshot(&this, dwFlags, ppSnapshotStream);
}

[CRepr]struct IPrintCoreHelperUni2 : IPrintCoreHelperUni
{
	public new const Guid IID = .(0x6c8afdfc, 0xead0, 0x4d2d, 0x80, 0x71, 0x9b, 0xf0, 0x17, 0x5a, 0x6c, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintCoreHelperUni.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVMODEA* pDevmode, uint32 cbSize, PWSTR pszCommandName, uint8** ppCommandBytes, uint32* pcbCommandSize) GetNamedCommand;
	}


	public HRESULT GetNamedCommand(DEVMODEA* pDevmode, uint32 cbSize, PWSTR pszCommandName, uint8** ppCommandBytes, uint32* pcbCommandSize) mut => VT.[Friend]GetNamedCommand(&this, pDevmode, cbSize, pszCommandName, ppCommandBytes, pcbCommandSize);
}

[CRepr]struct IPrintCoreHelperPS : IPrintCoreHelper
{
	public new const Guid IID = .(0xc2c14f6f, 0x95d3, 0x4d63, 0x96, 0xcf, 0x6b, 0xd9, 0xe6, 0xc9, 0x07, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintCoreHelper.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszAttribute, uint32* pdwDataType, uint8** ppbData, uint32* pcbSize) GetGlobalAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFeatureKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8** ppbData, uint32* pcbSize) GetFeatureAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8** ppbData, uint32* pcbSize) GetOptionAttribute;
	}


	public HRESULT GetGlobalAttribute(PSTR pszAttribute, uint32* pdwDataType, uint8** ppbData, uint32* pcbSize) mut => VT.[Friend]GetGlobalAttribute(&this, pszAttribute, pdwDataType, ppbData, pcbSize);

	public HRESULT GetFeatureAttribute(PSTR pszFeatureKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8** ppbData, uint32* pcbSize) mut => VT.[Friend]GetFeatureAttribute(&this, pszFeatureKeyword, pszAttribute, pdwDataType, ppbData, pcbSize);

	public HRESULT GetOptionAttribute(PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8** ppbData, uint32* pcbSize) mut => VT.[Friend]GetOptionAttribute(&this, pszFeatureKeyword, pszOptionKeyword, pszAttribute, pdwDataType, ppbData, pcbSize);
}

[CRepr]struct IPrintOemCommon : IUnknown
{
	public new const Guid IID = .(0x7f42285e, 0x91d5, 0x11d1, 0x88, 0x20, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode, void* pBuffer, uint32 cbSize, uint32* pcbNeeded) GetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode, OEMDMPARAM* pOemDMParam) DevMode;
	}


	public HRESULT GetInfo(uint32 dwMode, void* pBuffer, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]GetInfo(&this, dwMode, pBuffer, cbSize, pcbNeeded);

	public HRESULT DevMode(uint32 dwMode, OEMDMPARAM* pOemDMParam) mut => VT.[Friend]DevMode(&this, dwMode, pOemDMParam);
}

[CRepr]struct IPrintOemUI : IPrintOemCommon
{
	public new const Guid IID = .(0xc6a7a9d0, 0x774c, 0x11d1, 0x94, 0x7f, 0x00, 0xa0, 0xc9, 0x06, 0x40, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintOemCommon.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pIUnknown) PublishDriverInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode, OEMCUIPPARAM* pOemCUIPParam) CommonUIProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPSHEETUI_INFO* pPSUIInfo, LPARAM lParam) DocumentPropertySheets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPSHEETUI_INFO* pPSUIInfo, LPARAM lParam) DevicePropertySheets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, DEVQUERYPRINT_INFO* pDQPInfo, DEVMODEA* pPublicDM, void* pOEMDM) DevQueryPrintEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, HANDLE hPrinter, PWSTR pDeviceName, uint16 wCapability, void* pOutput, DEVMODEA* pPublicDM, void* pOEMDM, uint32 dwOld, uint32* dwResult) DeviceCapabilitiesA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLevel, uint8* pDriverUpgradeInfo) UpgradePrinter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pPrinterName, int32 iDriverEvent, uint32 dwFlags, LPARAM lParam) PrinterEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDriverEvent, uint32 dwLevel, uint8* pDriverInfo, LPARAM lParam) DriverEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, OEMUIOBJ* poemuiobj, DEVMODEA* pPublicDM, void* pOEMDM, uint32 ulQueryMode, void* pvProfileData, uint32* pcbProfileData, uint32* pflProfileData) QueryColorProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, uint32 usMsg, WPARAM wParam, LPARAM lParam) FontInstallerDlgProc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, HANDLE hHeap, PWSTR pwstrCartridges) UpdateExternalFonts;
	}


	public HRESULT PublishDriverInterface(IUnknown* pIUnknown) mut => VT.[Friend]PublishDriverInterface(&this, pIUnknown);

	public HRESULT CommonUIProp(uint32 dwMode, OEMCUIPPARAM* pOemCUIPParam) mut => VT.[Friend]CommonUIProp(&this, dwMode, pOemCUIPParam);

	public HRESULT DocumentPropertySheets(PROPSHEETUI_INFO* pPSUIInfo, LPARAM lParam) mut => VT.[Friend]DocumentPropertySheets(&this, pPSUIInfo, lParam);

	public HRESULT DevicePropertySheets(PROPSHEETUI_INFO* pPSUIInfo, LPARAM lParam) mut => VT.[Friend]DevicePropertySheets(&this, pPSUIInfo, lParam);

	public HRESULT DevQueryPrintEx(OEMUIOBJ* poemuiobj, DEVQUERYPRINT_INFO* pDQPInfo, DEVMODEA* pPublicDM, void* pOEMDM) mut => VT.[Friend]DevQueryPrintEx(&this, poemuiobj, pDQPInfo, pPublicDM, pOEMDM);

	public HRESULT DeviceCapabilitiesA(OEMUIOBJ* poemuiobj, HANDLE hPrinter, PWSTR pDeviceName, uint16 wCapability, void* pOutput, DEVMODEA* pPublicDM, void* pOEMDM, uint32 dwOld, uint32* dwResult) mut => VT.[Friend]DeviceCapabilitiesA(&this, poemuiobj, hPrinter, pDeviceName, wCapability, pOutput, pPublicDM, pOEMDM, dwOld, dwResult);

	public HRESULT UpgradePrinter(uint32 dwLevel, uint8* pDriverUpgradeInfo) mut => VT.[Friend]UpgradePrinter(&this, dwLevel, pDriverUpgradeInfo);

	public HRESULT PrinterEvent(PWSTR pPrinterName, int32 iDriverEvent, uint32 dwFlags, LPARAM lParam) mut => VT.[Friend]PrinterEvent(&this, pPrinterName, iDriverEvent, dwFlags, lParam);

	public HRESULT DriverEvent(uint32 dwDriverEvent, uint32 dwLevel, uint8* pDriverInfo, LPARAM lParam) mut => VT.[Friend]DriverEvent(&this, dwDriverEvent, dwLevel, pDriverInfo, lParam);

	public HRESULT QueryColorProfile(HANDLE hPrinter, OEMUIOBJ* poemuiobj, DEVMODEA* pPublicDM, void* pOEMDM, uint32 ulQueryMode, void* pvProfileData, uint32* pcbProfileData, uint32* pflProfileData) mut => VT.[Friend]QueryColorProfile(&this, hPrinter, poemuiobj, pPublicDM, pOEMDM, ulQueryMode, pvProfileData, pcbProfileData, pflProfileData);

	public HRESULT FontInstallerDlgProc(HWND hWnd, uint32 usMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]FontInstallerDlgProc(&this, hWnd, usMsg, wParam, lParam);

	public HRESULT UpdateExternalFonts(HANDLE hPrinter, HANDLE hHeap, PWSTR pwstrCartridges) mut => VT.[Friend]UpdateExternalFonts(&this, hPrinter, hHeap, pwstrCartridges);
}

[CRepr]struct IPrintOemUI2 : IPrintOemUI
{
	public new const Guid IID = .(0x292515f9, 0xb54b, 0x489b, 0x92, 0x75, 0xba, 0xb5, 0x68, 0x21, 0x39, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintOemUI.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, DEVMODEA* pDevmode, uint32 dwLevel, uint8* lpAttributeInfo) QueryJobAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode) HideStandardUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, HDC hdc, int32 iEsc, uint32 cbIn, void* pvIn, uint32 cbOut, void* pvOut, int32* piResult) DocumentEvent;
	}


	public HRESULT QueryJobAttributes(HANDLE hPrinter, DEVMODEA* pDevmode, uint32 dwLevel, uint8* lpAttributeInfo) mut => VT.[Friend]QueryJobAttributes(&this, hPrinter, pDevmode, dwLevel, lpAttributeInfo);

	public HRESULT HideStandardUI(uint32 dwMode) mut => VT.[Friend]HideStandardUI(&this, dwMode);

	public HRESULT DocumentEvent(HANDLE hPrinter, HDC hdc, int32 iEsc, uint32 cbIn, void* pvIn, uint32 cbOut, void* pvOut, int32* piResult) mut => VT.[Friend]DocumentEvent(&this, hPrinter, hdc, iEsc, cbIn, pvIn, cbOut, pvOut, piResult);
}

[CRepr]struct IPrintOemUIMXDC : IUnknown
{
	public new const Guid IID = .(0x7349d725, 0xe2c1, 0x4dca, 0xaf, 0xb5, 0xc1, 0x3e, 0x91, 0xbc, 0x93, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, uint32 cbDevMode, DEVMODEA* pDevMode, uint32 cbOEMDM, void* pOEMDM, RECTL* prclImageableArea) AdjustImageableArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, uint32 cbDevMode, DEVMODEA* pDevMode, uint32 cbOEMDM, void* pOEMDM, int32* pCompressionMode) AdjustImageCompression;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, uint32 cbDevMode, DEVMODEA* pDevMode, uint32 cbOEMDM, void* pOEMDM, int32* pDPI) AdjustDPI;
	}


	public HRESULT AdjustImageableArea(HANDLE hPrinter, uint32 cbDevMode, DEVMODEA* pDevMode, uint32 cbOEMDM, void* pOEMDM, RECTL* prclImageableArea) mut => VT.[Friend]AdjustImageableArea(&this, hPrinter, cbDevMode, pDevMode, cbOEMDM, pOEMDM, prclImageableArea);

	public HRESULT AdjustImageCompression(HANDLE hPrinter, uint32 cbDevMode, DEVMODEA* pDevMode, uint32 cbOEMDM, void* pOEMDM, int32* pCompressionMode) mut => VT.[Friend]AdjustImageCompression(&this, hPrinter, cbDevMode, pDevMode, cbOEMDM, pOEMDM, pCompressionMode);

	public HRESULT AdjustDPI(HANDLE hPrinter, uint32 cbDevMode, DEVMODEA* pDevMode, uint32 cbOEMDM, void* pOEMDM, int32* pDPI) mut => VT.[Friend]AdjustDPI(&this, hPrinter, cbDevMode, pDevMode, cbOEMDM, pOEMDM, pDPI);
}

[CRepr]struct IPrintOemDriverUI : IUnknown
{
	public new const Guid IID = .(0x92b05d50, 0x78bc, 0x11d1, 0x94, 0x80, 0x00, 0xa0, 0xc9, 0x06, 0x40, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pci, PSTR Feature, void* pOutput, uint32 cbSize, uint32* pcbNeeded, uint32* pdwOptionsReturned) DrvGetDriverSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, PSTR pFeature, PSTR pOption) DrvUpgradeRegistrySetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pci, void* pOptItem, uint32 dwPreviousSelection, uint32 dwMode) DrvUpdateUISetting;
	}


	public HRESULT DrvGetDriverSetting(void* pci, PSTR Feature, void* pOutput, uint32 cbSize, uint32* pcbNeeded, uint32* pdwOptionsReturned) mut => VT.[Friend]DrvGetDriverSetting(&this, pci, Feature, pOutput, cbSize, pcbNeeded, pdwOptionsReturned);

	public HRESULT DrvUpgradeRegistrySetting(HANDLE hPrinter, PSTR pFeature, PSTR pOption) mut => VT.[Friend]DrvUpgradeRegistrySetting(&this, hPrinter, pFeature, pOption);

	public HRESULT DrvUpdateUISetting(void* pci, void* pOptItem, uint32 dwPreviousSelection, uint32 dwMode) mut => VT.[Friend]DrvUpdateUISetting(&this, pci, pOptItem, dwPreviousSelection, dwMode);
}

[CRepr]struct IPrintCoreUI2 : IPrintOemDriverUI
{
	public new const Guid IID = .(0x085ccfca, 0x3adf, 0x4c9e, 0xb4, 0x91, 0xd8, 0x51, 0xa6, 0xed, 0xc9, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintOemDriverUI.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, int8* pmszFeaturesRequested, uint32 cbIn, PSTR pmszFeatureOptionBuf, uint32 cbSize, uint32* pcbNeeded) GetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, int8* pmszFeatureOptionBuf, uint32 cbIn, uint32* pdwResult) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pmszConstrainedOptionList, uint32 cbSize, uint32* pcbNeeded) EnumConstrainedOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PSTR pmszReasonList, uint32 cbSize, uint32* pcbNeeded) WhyConstrained;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszAttribute, uint32* pdwDataType, uint8* pbData, uint32 cbSize, uint32* pcbNeeded) GetGlobalAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8* pbData, uint32 cbSize, uint32* pcbNeeded) GetFeatureAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8* pbData, uint32 cbSize, uint32* pcbNeeded) GetOptionAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pmszFeatureList, uint32 cbSize, uint32* pcbNeeded) EnumFeatures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pmszOptionList, uint32 cbSize, uint32* pcbNeeded) EnumOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, uint32 dwLevel, uint8* pCaps, uint32 cbSize, uint32* pcbNeeded) QuerySimulationSupport;
	}


	public HRESULT GetOptions(OEMUIOBJ* poemuiobj, uint32 dwFlags, int8* pmszFeaturesRequested, uint32 cbIn, PSTR pmszFeatureOptionBuf, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]GetOptions(&this, poemuiobj, dwFlags, pmszFeaturesRequested, cbIn, pmszFeatureOptionBuf, cbSize, pcbNeeded);

	public HRESULT SetOptions(OEMUIOBJ* poemuiobj, uint32 dwFlags, int8* pmszFeatureOptionBuf, uint32 cbIn, uint32* pdwResult) mut => VT.[Friend]SetOptions(&this, poemuiobj, dwFlags, pmszFeatureOptionBuf, cbIn, pdwResult);

	public HRESULT EnumConstrainedOptions(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pmszConstrainedOptionList, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]EnumConstrainedOptions(&this, poemuiobj, dwFlags, pszFeatureKeyword, pmszConstrainedOptionList, cbSize, pcbNeeded);

	public HRESULT WhyConstrained(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PSTR pmszReasonList, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]WhyConstrained(&this, poemuiobj, dwFlags, pszFeatureKeyword, pszOptionKeyword, pmszReasonList, cbSize, pcbNeeded);

	public HRESULT GetGlobalAttribute(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszAttribute, uint32* pdwDataType, uint8* pbData, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]GetGlobalAttribute(&this, poemuiobj, dwFlags, pszAttribute, pdwDataType, pbData, cbSize, pcbNeeded);

	public HRESULT GetFeatureAttribute(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8* pbData, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]GetFeatureAttribute(&this, poemuiobj, dwFlags, pszFeatureKeyword, pszAttribute, pdwDataType, pbData, cbSize, pcbNeeded);

	public HRESULT GetOptionAttribute(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pszOptionKeyword, PSTR pszAttribute, uint32* pdwDataType, uint8* pbData, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]GetOptionAttribute(&this, poemuiobj, dwFlags, pszFeatureKeyword, pszOptionKeyword, pszAttribute, pdwDataType, pbData, cbSize, pcbNeeded);

	public HRESULT EnumFeatures(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pmszFeatureList, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]EnumFeatures(&this, poemuiobj, dwFlags, pmszFeatureList, cbSize, pcbNeeded);

	public HRESULT EnumOptions(OEMUIOBJ* poemuiobj, uint32 dwFlags, PSTR pszFeatureKeyword, PSTR pmszOptionList, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]EnumOptions(&this, poemuiobj, dwFlags, pszFeatureKeyword, pmszOptionList, cbSize, pcbNeeded);

	public HRESULT QuerySimulationSupport(HANDLE hPrinter, uint32 dwLevel, uint8* pCaps, uint32 cbSize, uint32* pcbNeeded) mut => VT.[Friend]QuerySimulationSupport(&this, hPrinter, dwLevel, pCaps, cbSize, pcbNeeded);
}

[CRepr]struct IPrintTicketProvider : IUnknown
{
	public new const Guid IID = .(0xbb5116db, 0x0a23, 0x4c3a, 0xa6, 0xb6, 0x89, 0xe5, 0x55, 0x8d, 0xfb, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, int32** ppVersions, int32* cVersions) GetSupportedVersions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hPrinter, int32 version, SHIMOPTS* pOptions, uint32* pDevModeFlags, int32* cNamespaces, BSTR** ppNamespaces) BindPrinter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDefaultNamespace) QueryDeviceNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXMLDOMDocument2* pPrintTicket, uint32 cbDevmodeIn, DEVMODEA* pDevmodeIn, uint32* pcbDevmodeOut, DEVMODEA** ppDevmodeOut) ConvertPrintTicketToDevMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbDevmode, DEVMODEA* pDevmode, IXMLDOMDocument2* pPrintTicket) ConvertDevModeToPrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXMLDOMDocument2* pPrintTicket, IXMLDOMDocument2** ppCapabilities) GetPrintCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXMLDOMDocument2* pBaseTicket) ValidatePrintTicket;
	}


	public HRESULT GetSupportedVersions(HANDLE hPrinter, int32** ppVersions, int32* cVersions) mut => VT.[Friend]GetSupportedVersions(&this, hPrinter, ppVersions, cVersions);

	public HRESULT BindPrinter(HANDLE hPrinter, int32 version, SHIMOPTS* pOptions, uint32* pDevModeFlags, int32* cNamespaces, BSTR** ppNamespaces) mut => VT.[Friend]BindPrinter(&this, hPrinter, version, pOptions, pDevModeFlags, cNamespaces, ppNamespaces);

	public HRESULT QueryDeviceNamespace(BSTR* pDefaultNamespace) mut => VT.[Friend]QueryDeviceNamespace(&this, pDefaultNamespace);

	public HRESULT ConvertPrintTicketToDevMode(IXMLDOMDocument2* pPrintTicket, uint32 cbDevmodeIn, DEVMODEA* pDevmodeIn, uint32* pcbDevmodeOut, DEVMODEA** ppDevmodeOut) mut => VT.[Friend]ConvertPrintTicketToDevMode(&this, pPrintTicket, cbDevmodeIn, pDevmodeIn, pcbDevmodeOut, ppDevmodeOut);

	public HRESULT ConvertDevModeToPrintTicket(uint32 cbDevmode, DEVMODEA* pDevmode, IXMLDOMDocument2* pPrintTicket) mut => VT.[Friend]ConvertDevModeToPrintTicket(&this, cbDevmode, pDevmode, pPrintTicket);

	public HRESULT GetPrintCapabilities(IXMLDOMDocument2* pPrintTicket, IXMLDOMDocument2** ppCapabilities) mut => VT.[Friend]GetPrintCapabilities(&this, pPrintTicket, ppCapabilities);

	public HRESULT ValidatePrintTicket(IXMLDOMDocument2* pBaseTicket) mut => VT.[Friend]ValidatePrintTicket(&this, pBaseTicket);
}

[CRepr]struct IPrintTicketProvider2 : IPrintTicketProvider
{
	public new const Guid IID = .(0xb8a70ab2, 0x3dfc, 0x4fec, 0xa0, 0x74, 0x51, 0x1b, 0x13, 0xc6, 0x51, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintTicketProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXMLDOMDocument2* pPrintTicket, IXMLDOMDocument2** ppDeviceCapabilities) GetPrintDeviceCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLocaleName, IXMLDOMDocument2* pPrintTicket, IXMLDOMDocument2** ppDeviceResources) GetPrintDeviceResources;
	}


	public HRESULT GetPrintDeviceCapabilities(IXMLDOMDocument2* pPrintTicket, IXMLDOMDocument2** ppDeviceCapabilities) mut => VT.[Friend]GetPrintDeviceCapabilities(&this, pPrintTicket, ppDeviceCapabilities);

	public HRESULT GetPrintDeviceResources(PWSTR pszLocaleName, IXMLDOMDocument2* pPrintTicket, IXMLDOMDocument2** ppDeviceResources) mut => VT.[Friend]GetPrintDeviceResources(&this, pszLocaleName, pPrintTicket, ppDeviceResources);
}

[CRepr]struct IPrintSchemaElement : IDispatch
{
	public new const Guid IID = .(0x724c1646, 0xe64b, 0x4bbf, 0x8e, 0xb4, 0xd4, 0x5e, 0x4f, 0xd5, 0x80, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppXmlNode) get_XmlNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrNamespaceUri) get_NamespaceUri;
	}


	public HRESULT get_XmlNode(IUnknown** ppXmlNode) mut => VT.[Friend]get_XmlNode(&this, ppXmlNode);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_NamespaceUri(BSTR* pbstrNamespaceUri) mut => VT.[Friend]get_NamespaceUri(&this, pbstrNamespaceUri);
}

[CRepr]struct IPrintSchemaDisplayableElement : IPrintSchemaElement
{
	public new const Guid IID = .(0xaf45af49, 0xd6aa, 0x407d, 0xbf, 0x87, 0x39, 0x12, 0x23, 0x6e, 0x9d, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDisplayName) get_DisplayName;
	}


	public HRESULT get_DisplayName(BSTR* pbstrDisplayName) mut => VT.[Friend]get_DisplayName(&this, pbstrDisplayName);
}

[CRepr]struct IPrintSchemaOption : IPrintSchemaDisplayableElement
{
	public new const Guid IID = .(0x66bb2f51, 0x5844, 0x4997, 0x8d, 0x70, 0x4b, 0x7c, 0xc2, 0x21, 0xcf, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaDisplayableElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsSelected) get_Selected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PrintSchemaConstrainedSetting* pSetting) get_Constrained;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrNamespaceUri, IUnknown** ppXmlValueNode) GetPropertyValue;
	}


	public HRESULT get_Selected(BOOL* pbIsSelected) mut => VT.[Friend]get_Selected(&this, pbIsSelected);

	public HRESULT get_Constrained(PrintSchemaConstrainedSetting* pSetting) mut => VT.[Friend]get_Constrained(&this, pSetting);

	public HRESULT GetPropertyValue(BSTR bstrName, BSTR bstrNamespaceUri, IUnknown** ppXmlValueNode) mut => VT.[Friend]GetPropertyValue(&this, bstrName, bstrNamespaceUri, ppXmlValueNode);
}

[CRepr]struct IPrintSchemaPageMediaSizeOption : IPrintSchemaOption
{
	public new const Guid IID = .(0x68746729, 0xf493, 0x4830, 0xa1, 0x0f, 0x69, 0x02, 0x87, 0x74, 0x60, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaOption.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulWidth) get_WidthInMicrons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulHeight) get_HeightInMicrons;
	}


	public HRESULT get_WidthInMicrons(uint32* pulWidth) mut => VT.[Friend]get_WidthInMicrons(&this, pulWidth);

	public HRESULT get_HeightInMicrons(uint32* pulHeight) mut => VT.[Friend]get_HeightInMicrons(&this, pulHeight);
}

[CRepr]struct IPrintSchemaNUpOption : IPrintSchemaOption
{
	public new const Guid IID = .(0x1f6342f2, 0xd848, 0x42e3, 0x89, 0x95, 0xc1, 0x0a, 0x9e, 0xf9, 0xa3, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaOption.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulPagesPerSheet) get_PagesPerSheet;
	}


	public HRESULT get_PagesPerSheet(uint32* pulPagesPerSheet) mut => VT.[Friend]get_PagesPerSheet(&this, pulPagesPerSheet);
}

[CRepr]struct IPrintSchemaOptionCollection : IDispatch
{
	public new const Guid IID = .(0xbaecb0bd, 0xa946, 0x4771, 0xbc, 0x30, 0xe8, 0xb2, 0x4f, 0x8d, 0x45, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, IPrintSchemaOption** ppOption) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
	}


	public HRESULT get_Count(uint32* pulCount) mut => VT.[Friend]get_Count(&this, pulCount);

	public HRESULT GetAt(uint32 ulIndex, IPrintSchemaOption** ppOption) mut => VT.[Friend]GetAt(&this, ulIndex, ppOption);

	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);
}

[CRepr]struct IPrintSchemaFeature : IPrintSchemaDisplayableElement
{
	public new const Guid IID = .(0xef189461, 0x5d62, 0x4626, 0x8e, 0x57, 0xff, 0x83, 0x58, 0x3c, 0x48, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaDisplayableElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaOption** ppOption) get_SelectedOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaOption* pOption) put_SelectedOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PrintSchemaSelectionType* pSelectionType) get_SelectionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaOption** ppOption) GetOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbShow) get_DisplayUI;
	}


	public HRESULT get_SelectedOption(IPrintSchemaOption** ppOption) mut => VT.[Friend]get_SelectedOption(&this, ppOption);

	public HRESULT put_SelectedOption(IPrintSchemaOption* pOption) mut => VT.[Friend]put_SelectedOption(&this, pOption);

	public HRESULT get_SelectionType(PrintSchemaSelectionType* pSelectionType) mut => VT.[Friend]get_SelectionType(&this, pSelectionType);

	public HRESULT GetOption(BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaOption** ppOption) mut => VT.[Friend]GetOption(&this, bstrName, bstrNamespaceUri, ppOption);

	public HRESULT get_DisplayUI(BOOL* pbShow) mut => VT.[Friend]get_DisplayUI(&this, pbShow);
}

[CRepr]struct IPrintSchemaPageImageableSize : IPrintSchemaElement
{
	public new const Guid IID = .(0x7c85bf5e, 0xdc7c, 0x4f61, 0x83, 0x9b, 0x41, 0x07, 0xe1, 0xc9, 0xb6, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulImageableSizeWidth) get_ImageableSizeWidthInMicrons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulImageableSizeHeight) get_ImageableSizeHeightInMicrons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulOriginWidth) get_OriginWidthInMicrons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulOriginHeight) get_OriginHeightInMicrons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulExtentWidth) get_ExtentWidthInMicrons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulExtentHeight) get_ExtentHeightInMicrons;
	}


	public HRESULT get_ImageableSizeWidthInMicrons(uint32* pulImageableSizeWidth) mut => VT.[Friend]get_ImageableSizeWidthInMicrons(&this, pulImageableSizeWidth);

	public HRESULT get_ImageableSizeHeightInMicrons(uint32* pulImageableSizeHeight) mut => VT.[Friend]get_ImageableSizeHeightInMicrons(&this, pulImageableSizeHeight);

	public HRESULT get_OriginWidthInMicrons(uint32* pulOriginWidth) mut => VT.[Friend]get_OriginWidthInMicrons(&this, pulOriginWidth);

	public HRESULT get_OriginHeightInMicrons(uint32* pulOriginHeight) mut => VT.[Friend]get_OriginHeightInMicrons(&this, pulOriginHeight);

	public HRESULT get_ExtentWidthInMicrons(uint32* pulExtentWidth) mut => VT.[Friend]get_ExtentWidthInMicrons(&this, pulExtentWidth);

	public HRESULT get_ExtentHeightInMicrons(uint32* pulExtentHeight) mut => VT.[Friend]get_ExtentHeightInMicrons(&this, pulExtentHeight);
}

[CRepr]struct IPrintSchemaParameterDefinition : IPrintSchemaDisplayableElement
{
	public new const Guid IID = .(0xb5ade81e, 0x0e61, 0x4fe1, 0x81, 0xc6, 0xc3, 0x33, 0xe4, 0xff, 0xe0, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaDisplayableElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsRequired) get_UserInputRequired;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUnitType) get_UnitType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PrintSchemaParameterDataType* pDataType) get_DataType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRangeMin) get_RangeMin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRangeMax) get_RangeMax;
	}


	public HRESULT get_UserInputRequired(BOOL* pbIsRequired) mut => VT.[Friend]get_UserInputRequired(&this, pbIsRequired);

	public HRESULT get_UnitType(BSTR* pbstrUnitType) mut => VT.[Friend]get_UnitType(&this, pbstrUnitType);

	public HRESULT get_DataType(PrintSchemaParameterDataType* pDataType) mut => VT.[Friend]get_DataType(&this, pDataType);

	public HRESULT get_RangeMin(int32* pRangeMin) mut => VT.[Friend]get_RangeMin(&this, pRangeMin);

	public HRESULT get_RangeMax(int32* pRangeMax) mut => VT.[Friend]get_RangeMax(&this, pRangeMax);
}

[CRepr]struct IPrintSchemaParameterInitializer : IPrintSchemaElement
{
	public new const Guid IID = .(0x52027082, 0x0b74, 0x4648, 0x95, 0x64, 0x82, 0x8c, 0xc6, 0xcb, 0x65, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar) put_Value;
	}


	public HRESULT get_Value(VARIANT* pVar) mut => VT.[Friend]get_Value(&this, pVar);

	public HRESULT put_Value(VARIANT* pVar) mut => VT.[Friend]put_Value(&this, pVar);
}

[CRepr]struct IPrintSchemaCapabilities : IPrintSchemaElement
{
	public new const Guid IID = .(0x5a577640, 0x501d, 0x4927, 0xbc, 0xd0, 0x5e, 0xf5, 0x7a, 0x7e, 0xd1, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrKeyName, IPrintSchemaFeature** ppFeature) GetFeatureByKeyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaFeature** ppFeature) GetFeature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaPageImageableSize** ppPageImageableSize) get_PageImageableSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulJobCopiesAllDocumentsMinValue) get_JobCopiesAllDocumentsMinValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulJobCopiesAllDocumentsMaxValue) get_JobCopiesAllDocumentsMaxValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaFeature* pFeature, IPrintSchemaOption** ppOption) GetSelectedOptionInPrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaFeature* pFeature, IPrintSchemaOptionCollection** ppOptionCollection) GetOptions;
	}


	public HRESULT GetFeatureByKeyName(BSTR bstrKeyName, IPrintSchemaFeature** ppFeature) mut => VT.[Friend]GetFeatureByKeyName(&this, bstrKeyName, ppFeature);

	public HRESULT GetFeature(BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaFeature** ppFeature) mut => VT.[Friend]GetFeature(&this, bstrName, bstrNamespaceUri, ppFeature);

	public HRESULT get_PageImageableSize(IPrintSchemaPageImageableSize** ppPageImageableSize) mut => VT.[Friend]get_PageImageableSize(&this, ppPageImageableSize);

	public HRESULT get_JobCopiesAllDocumentsMinValue(uint32* pulJobCopiesAllDocumentsMinValue) mut => VT.[Friend]get_JobCopiesAllDocumentsMinValue(&this, pulJobCopiesAllDocumentsMinValue);

	public HRESULT get_JobCopiesAllDocumentsMaxValue(uint32* pulJobCopiesAllDocumentsMaxValue) mut => VT.[Friend]get_JobCopiesAllDocumentsMaxValue(&this, pulJobCopiesAllDocumentsMaxValue);

	public HRESULT GetSelectedOptionInPrintTicket(IPrintSchemaFeature* pFeature, IPrintSchemaOption** ppOption) mut => VT.[Friend]GetSelectedOptionInPrintTicket(&this, pFeature, ppOption);

	public HRESULT GetOptions(IPrintSchemaFeature* pFeature, IPrintSchemaOptionCollection** ppOptionCollection) mut => VT.[Friend]GetOptions(&this, pFeature, ppOptionCollection);
}

[CRepr]struct IPrintSchemaCapabilities2 : IPrintSchemaCapabilities
{
	public new const Guid IID = .(0xb58845f4, 0x9970, 0x4d87, 0xa6, 0x36, 0x16, 0x9f, 0xb8, 0x2e, 0xd6, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaCapabilities.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaParameterDefinition** ppParameterDefinition) GetParameterDefinition;
	}


	public HRESULT GetParameterDefinition(BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaParameterDefinition** ppParameterDefinition) mut => VT.[Friend]GetParameterDefinition(&this, bstrName, bstrNamespaceUri, ppParameterDefinition);
}

[CRepr]struct IPrintSchemaAsyncOperation : IDispatch
{
	public new const Guid IID = .(0x143c8dcb, 0xd37f, 0x47f7, 0x88, 0xe8, 0x6b, 0x1d, 0x21, 0xf2, 0xc5, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT Start() mut => VT.[Friend]Start(&this);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPrintSchemaTicket : IPrintSchemaElement
{
	public new const Guid IID = .(0xe480b861, 0x4708, 0x4e6d, 0xa5, 0xb4, 0xa2, 0xb4, 0xee, 0xb9, 0xba, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrKeyName, IPrintSchemaFeature** ppFeature) GetFeatureByKeyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaFeature** ppFeature) GetFeature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaAsyncOperation** ppAsyncOperation) ValidateAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaTicket* pPrintTicketCommit, IPrintSchemaAsyncOperation** ppAsyncOperation) CommitAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NotifyXmlChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaCapabilities** ppCapabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulJobCopiesAllDocuments) get_JobCopiesAllDocuments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulJobCopiesAllDocuments) put_JobCopiesAllDocuments;
	}


	public HRESULT GetFeatureByKeyName(BSTR bstrKeyName, IPrintSchemaFeature** ppFeature) mut => VT.[Friend]GetFeatureByKeyName(&this, bstrKeyName, ppFeature);

	public HRESULT GetFeature(BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaFeature** ppFeature) mut => VT.[Friend]GetFeature(&this, bstrName, bstrNamespaceUri, ppFeature);

	public HRESULT ValidateAsync(IPrintSchemaAsyncOperation** ppAsyncOperation) mut => VT.[Friend]ValidateAsync(&this, ppAsyncOperation);

	public HRESULT CommitAsync(IPrintSchemaTicket* pPrintTicketCommit, IPrintSchemaAsyncOperation** ppAsyncOperation) mut => VT.[Friend]CommitAsync(&this, pPrintTicketCommit, ppAsyncOperation);

	public HRESULT NotifyXmlChanged() mut => VT.[Friend]NotifyXmlChanged(&this);

	public HRESULT GetCapabilities(IPrintSchemaCapabilities** ppCapabilities) mut => VT.[Friend]GetCapabilities(&this, ppCapabilities);

	public HRESULT get_JobCopiesAllDocuments(uint32* pulJobCopiesAllDocuments) mut => VT.[Friend]get_JobCopiesAllDocuments(&this, pulJobCopiesAllDocuments);

	public HRESULT put_JobCopiesAllDocuments(uint32 ulJobCopiesAllDocuments) mut => VT.[Friend]put_JobCopiesAllDocuments(&this, ulJobCopiesAllDocuments);
}

[CRepr]struct IPrintSchemaTicket2 : IPrintSchemaTicket
{
	public new const Guid IID = .(0x2ec1f844, 0x766a, 0x47a1, 0x91, 0xf4, 0x2e, 0xeb, 0x61, 0x90, 0xf8, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintSchemaTicket.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaParameterInitializer** ppParameterInitializer) GetParameterInitializer;
	}


	public HRESULT GetParameterInitializer(BSTR bstrName, BSTR bstrNamespaceUri, IPrintSchemaParameterInitializer** ppParameterInitializer) mut => VT.[Friend]GetParameterInitializer(&this, bstrName, bstrNamespaceUri, ppParameterInitializer);
}

[CRepr]struct IPrintSchemaAsyncOperationEvent : IDispatch
{
	public new const Guid IID = .(0x23adbb16, 0x0133, 0x4906, 0xb2, 0x9a, 0x1d, 0xce, 0x1d, 0x02, 0x63, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaTicket* pTicket, HRESULT hrOperation) Completed;
	}


	public HRESULT Completed(IPrintSchemaTicket* pTicket, HRESULT hrOperation) mut => VT.[Friend]Completed(&this, pTicket, hrOperation);
}

[CRepr]struct IPrinterScriptableSequentialStream : IDispatch
{
	public new const Guid IID = .(0x2072838a, 0x316f, 0x467a, 0xa9, 0x49, 0x27, 0xf6, 0x8c, 0x44, 0xa8, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cbRead, IDispatch** ppArray) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pArray, int32* pcbWritten) Write;
	}


	public HRESULT Read(int32 cbRead, IDispatch** ppArray) mut => VT.[Friend]Read(&this, cbRead, ppArray);

	public HRESULT Write(IDispatch* pArray, int32* pcbWritten) mut => VT.[Friend]Write(&this, pArray, pcbWritten);
}

[CRepr]struct IPrinterScriptableStream : IPrinterScriptableSequentialStream
{
	public new const Guid IID = .(0x7edf9a92, 0x4750, 0x41a5, 0xa1, 0x7f, 0x87, 0x9a, 0x6f, 0x4f, 0x7d, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrinterScriptableSequentialStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lOffset, STREAM_SEEK streamSeek, int32* plPosition) Seek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSize) SetSize;
	}


	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT Seek(int32 lOffset, STREAM_SEEK streamSeek, int32* plPosition) mut => VT.[Friend]Seek(&this, lOffset, streamSeek, plPosition);

	public HRESULT SetSize(int32 lSize) mut => VT.[Friend]SetSize(&this, lSize);
}

[CRepr]struct IPrinterPropertyBag : IDispatch
{
	public new const Guid IID = .(0xfea77364, 0xdf95, 0x4a23, 0xa9, 0x05, 0x01, 0x9b, 0x79, 0xa8, 0xe4, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BOOL* pbValue) GetBool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BOOL bValue) SetBool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, int32* pnValue) GetInt32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, int32 nValue) SetInt32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR* pbstrValue) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrValue) SetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, uint32* pcbValue, uint8** ppValue) GetBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, uint32 cbValue, uint8* pValue) SetBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IStream** ppValue) GetReadStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IStream** ppValue) GetWriteStream;
	}


	public HRESULT GetBool(BSTR bstrName, BOOL* pbValue) mut => VT.[Friend]GetBool(&this, bstrName, pbValue);

	public HRESULT SetBool(BSTR bstrName, BOOL bValue) mut => VT.[Friend]SetBool(&this, bstrName, bValue);

	public HRESULT GetInt32(BSTR bstrName, int32* pnValue) mut => VT.[Friend]GetInt32(&this, bstrName, pnValue);

	public HRESULT SetInt32(BSTR bstrName, int32 nValue) mut => VT.[Friend]SetInt32(&this, bstrName, nValue);

	public HRESULT GetString(BSTR bstrName, BSTR* pbstrValue) mut => VT.[Friend]GetString(&this, bstrName, pbstrValue);

	public HRESULT SetString(BSTR bstrName, BSTR bstrValue) mut => VT.[Friend]SetString(&this, bstrName, bstrValue);

	public HRESULT GetBytes(BSTR bstrName, uint32* pcbValue, uint8** ppValue) mut => VT.[Friend]GetBytes(&this, bstrName, pcbValue, ppValue);

	public HRESULT SetBytes(BSTR bstrName, uint32 cbValue, uint8* pValue) mut => VT.[Friend]SetBytes(&this, bstrName, cbValue, pValue);

	public HRESULT GetReadStream(BSTR bstrName, IStream** ppValue) mut => VT.[Friend]GetReadStream(&this, bstrName, ppValue);

	public HRESULT GetWriteStream(BSTR bstrName, IStream** ppValue) mut => VT.[Friend]GetWriteStream(&this, bstrName, ppValue);
}

[CRepr]struct IPrinterScriptablePropertyBag : IDispatch
{
	public new const Guid IID = .(0x91c7765f, 0xed57, 0x49ad, 0x8b, 0x01, 0xdc, 0x24, 0x81, 0x6a, 0x52, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BOOL* pbValue) GetBool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BOOL bValue) SetBool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, int32* pnValue) GetInt32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, int32 nValue) SetInt32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR* pbstrValue) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrValue) SetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IDispatch** ppArray) GetBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IDispatch* pArray) SetBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IPrinterScriptableStream** ppStream) GetReadStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IPrinterScriptableStream** ppStream) GetWriteStream;
	}


	public HRESULT GetBool(BSTR bstrName, BOOL* pbValue) mut => VT.[Friend]GetBool(&this, bstrName, pbValue);

	public HRESULT SetBool(BSTR bstrName, BOOL bValue) mut => VT.[Friend]SetBool(&this, bstrName, bValue);

	public HRESULT GetInt32(BSTR bstrName, int32* pnValue) mut => VT.[Friend]GetInt32(&this, bstrName, pnValue);

	public HRESULT SetInt32(BSTR bstrName, int32 nValue) mut => VT.[Friend]SetInt32(&this, bstrName, nValue);

	public HRESULT GetString(BSTR bstrName, BSTR* pbstrValue) mut => VT.[Friend]GetString(&this, bstrName, pbstrValue);

	public HRESULT SetString(BSTR bstrName, BSTR bstrValue) mut => VT.[Friend]SetString(&this, bstrName, bstrValue);

	public HRESULT GetBytes(BSTR bstrName, IDispatch** ppArray) mut => VT.[Friend]GetBytes(&this, bstrName, ppArray);

	public HRESULT SetBytes(BSTR bstrName, IDispatch* pArray) mut => VT.[Friend]SetBytes(&this, bstrName, pArray);

	public HRESULT GetReadStream(BSTR bstrName, IPrinterScriptableStream** ppStream) mut => VT.[Friend]GetReadStream(&this, bstrName, ppStream);

	public HRESULT GetWriteStream(BSTR bstrName, IPrinterScriptableStream** ppStream) mut => VT.[Friend]GetWriteStream(&this, bstrName, ppStream);
}

[CRepr]struct IPrinterScriptablePropertyBag2 : IPrinterScriptablePropertyBag
{
	public new const Guid IID = .(0x2a1c53c4, 0x8638, 0x4b3e, 0xb5, 0x18, 0x27, 0x73, 0xc9, 0x45, 0x56, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrinterScriptablePropertyBag.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IUnknown** ppXmlNode) GetReadStreamAsXML;
	}


	public HRESULT GetReadStreamAsXML(BSTR bstrName, IUnknown** ppXmlNode) mut => VT.[Friend]GetReadStreamAsXML(&this, bstrName, ppXmlNode);
}

[CRepr]struct IPrinterQueue : IDispatch
{
	public new const Guid IID = .(0x3580a828, 0x07fe, 0x4b94, 0xac, 0x1a, 0x75, 0x7d, 0x9d, 0x2d, 0x30, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phPrinter) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBidiQuery) SendBidiQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterPropertyBag** ppPropertyBag) GetProperties;
	}


	public HRESULT get_Handle(HANDLE* phPrinter) mut => VT.[Friend]get_Handle(&this, phPrinter);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT SendBidiQuery(BSTR bstrBidiQuery) mut => VT.[Friend]SendBidiQuery(&this, bstrBidiQuery);

	public HRESULT GetProperties(IPrinterPropertyBag** ppPropertyBag) mut => VT.[Friend]GetProperties(&this, ppPropertyBag);
}

[CRepr]struct IPrintJob : IUnknown
{
	public new const Guid IID = .(0xb771dab8, 0x1282, 0x41b7, 0x85, 0x8c, 0xf2, 0x06, 0xe4, 0xd2, 0x05, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulID) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulPages) get_PrintedPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulPages) get_TotalPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PrintJobStatus* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pSubmissionTime) get_SubmissionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestCancel;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_Id(uint32* pulID) mut => VT.[Friend]get_Id(&this, pulID);

	public HRESULT get_PrintedPages(uint32* pulPages) mut => VT.[Friend]get_PrintedPages(&this, pulPages);

	public HRESULT get_TotalPages(uint32* pulPages) mut => VT.[Friend]get_TotalPages(&this, pulPages);

	public HRESULT get_Status(PrintJobStatus* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_SubmissionTime(double* pSubmissionTime) mut => VT.[Friend]get_SubmissionTime(&this, pSubmissionTime);

	public HRESULT RequestCancel() mut => VT.[Friend]RequestCancel(&this);
}

[CRepr]struct IPrintJobCollection : IDispatch
{
	public new const Guid IID = .(0x72b82a24, 0xa598, 0x4e87, 0x89, 0x5f, 0xcd, 0xb2, 0x3a, 0x49, 0xe9, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, IPrintJob** ppJob) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
	}


	public HRESULT get_Count(uint32* pulCount) mut => VT.[Friend]get_Count(&this, pulCount);

	public HRESULT GetAt(uint32 ulIndex, IPrintJob** ppJob) mut => VT.[Friend]GetAt(&this, ulIndex, ppJob);

	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);
}

[CRepr]struct IPrinterQueueViewEvent : IDispatch
{
	public new const Guid IID = .(0xc5b6042b, 0xfd21, 0x404a, 0xa0, 0xef, 0xe2, 0xfb, 0xb5, 0x2b, 0x90, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintJobCollection* pCollection, uint32 ulViewOffset, uint32 ulViewSize, uint32 ulCountJobsInPrintQueue) OnChanged;
	}


	public HRESULT OnChanged(IPrintJobCollection* pCollection, uint32 ulViewOffset, uint32 ulViewSize, uint32 ulCountJobsInPrintQueue) mut => VT.[Friend]OnChanged(&this, pCollection, ulViewOffset, ulViewSize, ulCountJobsInPrintQueue);
}

[CRepr]struct IPrinterQueueView : IDispatch
{
	public new const Guid IID = .(0x476e2969, 0x3b2b, 0x4b3f, 0x82, 0x77, 0xcf, 0xf6, 0x05, 0x60, 0x42, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulViewOffset, uint32 ulViewSize) SetViewRange;
	}


	public HRESULT SetViewRange(uint32 ulViewOffset, uint32 ulViewSize) mut => VT.[Friend]SetViewRange(&this, ulViewOffset, ulViewSize);
}

[CRepr]struct IPrinterQueueEvent : IDispatch
{
	public new const Guid IID = .(0x214685f6, 0x7b78, 0x4681, 0x87, 0xe0, 0x49, 0x5f, 0x73, 0x92, 0x73, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResponse, HRESULT hrStatus) OnBidiResponseReceived;
	}


	public HRESULT OnBidiResponseReceived(BSTR bstrResponse, HRESULT hrStatus) mut => VT.[Friend]OnBidiResponseReceived(&this, bstrResponse, hrStatus);
}

[CRepr]struct IPrinterBidiSetRequestCallback : IUnknown
{
	public new const Guid IID = .(0xc52d32dd, 0xf2b4, 0x4052, 0x85, 0x02, 0xec, 0x43, 0x05, 0xec, 0xb7, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResponse, HRESULT hrStatus) Completed;
	}


	public HRESULT Completed(BSTR bstrResponse, HRESULT hrStatus) mut => VT.[Friend]Completed(&this, bstrResponse, hrStatus);
}

[CRepr]struct IPrinterExtensionAsyncOperation : IUnknown
{
	public new const Guid IID = .(0x108d6a23, 0x6a4b, 0x4552, 0x94, 0x48, 0x68, 0xb4, 0x27, 0x18, 0x6a, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPrinterQueue2 : IPrinterQueue
{
	public new const Guid IID = .(0x8cd444e8, 0xc9bb, 0x49b3, 0x8e, 0x38, 0xe0, 0x32, 0x09, 0x41, 0x61, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrinterQueue.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBidiRequest, IPrinterBidiSetRequestCallback* pCallback, IPrinterExtensionAsyncOperation** ppAsyncOperation) SendBidiSetRequestAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulViewOffset, uint32 ulViewSize, IPrinterQueueView** ppJobView) GetPrinterQueueView;
	}


	public HRESULT SendBidiSetRequestAsync(BSTR bstrBidiRequest, IPrinterBidiSetRequestCallback* pCallback, IPrinterExtensionAsyncOperation** ppAsyncOperation) mut => VT.[Friend]SendBidiSetRequestAsync(&this, bstrBidiRequest, pCallback, ppAsyncOperation);

	public HRESULT GetPrinterQueueView(uint32 ulViewOffset, uint32 ulViewSize, IPrinterQueueView** ppJobView) mut => VT.[Friend]GetPrinterQueueView(&this, ulViewOffset, ulViewSize, ppJobView);
}

[CRepr]struct IPrinterExtensionContext : IDispatch
{
	public new const Guid IID = .(0x39843bf2, 0xc4d2, 0x41fd, 0xb4, 0xb2, 0xae, 0xdb, 0xee, 0x5e, 0x19, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterQueue** ppQueue) get_PrinterQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintSchemaTicket** ppTicket) get_PrintSchemaTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterPropertyBag** ppPropertyBag) get_DriverProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterPropertyBag** ppPropertyBag) get_UserProperties;
	}


	public HRESULT get_PrinterQueue(IPrinterQueue** ppQueue) mut => VT.[Friend]get_PrinterQueue(&this, ppQueue);

	public HRESULT get_PrintSchemaTicket(IPrintSchemaTicket** ppTicket) mut => VT.[Friend]get_PrintSchemaTicket(&this, ppTicket);

	public HRESULT get_DriverProperties(IPrinterPropertyBag** ppPropertyBag) mut => VT.[Friend]get_DriverProperties(&this, ppPropertyBag);

	public HRESULT get_UserProperties(IPrinterPropertyBag** ppPropertyBag) mut => VT.[Friend]get_UserProperties(&this, ppPropertyBag);
}

[CRepr]struct IPrinterExtensionRequest : IDispatch
{
	public new const Guid IID = .(0x39843bf3, 0xc4d2, 0x41fd, 0xb4, 0xb2, 0xae, 0xdb, 0xee, 0x5e, 0x19, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrStatus, BSTR bstrLogMessage) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Complete;
	}


	public HRESULT Cancel(HRESULT hrStatus, BSTR bstrLogMessage) mut => VT.[Friend]Cancel(&this, hrStatus, bstrLogMessage);

	public HRESULT Complete() mut => VT.[Friend]Complete(&this);
}

[CRepr]struct IPrinterExtensionEventArgs : IPrinterExtensionContext
{
	public new const Guid IID = .(0x39843bf4, 0xc4d2, 0x41fd, 0xb4, 0xb2, 0xae, 0xdb, 0xee, 0x5e, 0x19, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrinterExtensionContext.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBidiNotification) get_BidiNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pReasonId) get_ReasonId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterExtensionRequest** ppRequest) get_Request;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplication) get_SourceApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pDetailedReasonId) get_DetailedReasonId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbModal) get_WindowModal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phwndParent) get_WindowParent;
	}


	public HRESULT get_BidiNotification(BSTR* pbstrBidiNotification) mut => VT.[Friend]get_BidiNotification(&this, pbstrBidiNotification);

	public HRESULT get_ReasonId(Guid* pReasonId) mut => VT.[Friend]get_ReasonId(&this, pReasonId);

	public HRESULT get_Request(IPrinterExtensionRequest** ppRequest) mut => VT.[Friend]get_Request(&this, ppRequest);

	public HRESULT get_SourceApplication(BSTR* pbstrApplication) mut => VT.[Friend]get_SourceApplication(&this, pbstrApplication);

	public HRESULT get_DetailedReasonId(Guid* pDetailedReasonId) mut => VT.[Friend]get_DetailedReasonId(&this, pDetailedReasonId);

	public HRESULT get_WindowModal(BOOL* pbModal) mut => VT.[Friend]get_WindowModal(&this, pbModal);

	public HRESULT get_WindowParent(HANDLE* phwndParent) mut => VT.[Friend]get_WindowParent(&this, phwndParent);
}

[CRepr]struct IPrinterExtensionContextCollection : IDispatch
{
	public new const Guid IID = .(0xfb476970, 0x9bab, 0x4861, 0x81, 0x1e, 0x3e, 0x98, 0xb0, 0xc5, 0xad, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, IPrinterExtensionContext** ppContext) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
	}


	public HRESULT get_Count(uint32* pulCount) mut => VT.[Friend]get_Count(&this, pulCount);

	public HRESULT GetAt(uint32 ulIndex, IPrinterExtensionContext** ppContext) mut => VT.[Friend]GetAt(&this, ulIndex, ppContext);

	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);
}

[CRepr]struct IPrinterExtensionEvent : IDispatch
{
	public new const Guid IID = .(0xc093cb63, 0x5ef5, 0x4585, 0xaf, 0x8e, 0x4d, 0x56, 0x37, 0x48, 0x7b, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterExtensionEventArgs* pEventArgs) OnDriverEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterExtensionContextCollection* pContextCollection) OnPrinterQueuesEnumerated;
	}


	public HRESULT OnDriverEvent(IPrinterExtensionEventArgs* pEventArgs) mut => VT.[Friend]OnDriverEvent(&this, pEventArgs);

	public HRESULT OnPrinterQueuesEnumerated(IPrinterExtensionContextCollection* pContextCollection) mut => VT.[Friend]OnPrinterQueuesEnumerated(&this, pContextCollection);
}

[CRepr]struct IPrinterExtensionManager : IUnknown
{
	public new const Guid IID = .(0x93c6eb8c, 0xb001, 0x4355, 0x96, 0x29, 0x8e, 0x8a, 0x1b, 0x3f, 0x8e, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid printerDriverId) EnableEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableEvents;
	}


	public HRESULT EnableEvents(Guid printerDriverId) mut => VT.[Friend]EnableEvents(&this, printerDriverId);

	public HRESULT DisableEvents() mut => VT.[Friend]DisableEvents(&this);
}

[CRepr]struct IPrinterScriptContext : IDispatch
{
	public new const Guid IID = .(0x066acbca, 0x8881, 0x49c9, 0xbb, 0x98, 0xfa, 0xe1, 0x6b, 0x48, 0x89, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterScriptablePropertyBag** ppPropertyBag) get_DriverProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterScriptablePropertyBag** ppPropertyBag) get_QueueProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterScriptablePropertyBag** ppPropertyBag) get_UserProperties;
	}


	public HRESULT get_DriverProperties(IPrinterScriptablePropertyBag** ppPropertyBag) mut => VT.[Friend]get_DriverProperties(&this, ppPropertyBag);

	public HRESULT get_QueueProperties(IPrinterScriptablePropertyBag** ppPropertyBag) mut => VT.[Friend]get_QueueProperties(&this, ppPropertyBag);

	public HRESULT get_UserProperties(IPrinterScriptablePropertyBag** ppPropertyBag) mut => VT.[Friend]get_UserProperties(&this, ppPropertyBag);
}

[CRepr]struct IPrintAsyncNotifyDataObject : IUnknown
{
	public new const Guid IID = .(0x77cf513e, 0x5d49, 0x4789, 0x9f, 0x30, 0xd0, 0x82, 0x2b, 0x33, 0x5c, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppNotificationData, uint32* pSize, Guid** ppSchema) AcquireData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseData;
	}


	public HRESULT AcquireData(uint8** ppNotificationData, uint32* pSize, Guid** ppSchema) mut => VT.[Friend]AcquireData(&this, ppNotificationData, pSize, ppSchema);

	public HRESULT ReleaseData() mut => VT.[Friend]ReleaseData(&this);
}

[CRepr]struct IPrintAsyncNotifyChannel : IUnknown
{
	public new const Guid IID = .(0x4a5031b1, 0x1f3f, 0x4db0, 0xa4, 0x62, 0x45, 0x30, 0xed, 0x8b, 0x04, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject* pData) SendNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject* pData) CloseChannel;
	}


	public HRESULT SendNotification(IPrintAsyncNotifyDataObject* pData) mut => VT.[Friend]SendNotification(&this, pData);

	public HRESULT CloseChannel(IPrintAsyncNotifyDataObject* pData) mut => VT.[Friend]CloseChannel(&this, pData);
}

[CRepr]struct IPrintAsyncNotifyCallback : IUnknown
{
	public new const Guid IID = .(0x7def34c1, 0x9d92, 0x4c99, 0xb3, 0xb3, 0xdb, 0x94, 0xa9, 0xd4, 0x19, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyChannel* pChannel, IPrintAsyncNotifyDataObject* pData) OnEventNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyChannel* pChannel, IPrintAsyncNotifyDataObject* pData) ChannelClosed;
	}


	public HRESULT OnEventNotify(IPrintAsyncNotifyChannel* pChannel, IPrintAsyncNotifyDataObject* pData) mut => VT.[Friend]OnEventNotify(&this, pChannel, pData);

	public HRESULT ChannelClosed(IPrintAsyncNotifyChannel* pChannel, IPrintAsyncNotifyDataObject* pData) mut => VT.[Friend]ChannelClosed(&this, pChannel, pData);
}

[CRepr]struct IPrintAsyncNotifyRegistration : IUnknown
{
	public new const Guid IID = .(0x0f6f27b6, 0x6f86, 0x4591, 0x92, 0x03, 0x64, 0xc3, 0xbf, 0xad, 0xed, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RegisterForNotifications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnregisterForNotifications;
	}


	public HRESULT RegisterForNotifications() mut => VT.[Friend]RegisterForNotifications(&this);

	public HRESULT UnregisterForNotifications() mut => VT.[Friend]UnregisterForNotifications(&this);
}

[CRepr]struct IPrintAsyncNotify : IUnknown
{
	public new const Guid IID = .(0x532818f7, 0x921b, 0x4fb2, 0xbf, 0xf8, 0x2f, 0x4f, 0xd5, 0x2e, 0xbe, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, Guid* param1, PrintAsyncNotifyUserFilter param2, PrintAsyncNotifyConversationStyle param3, IPrintAsyncNotifyCallback* param4, IPrintAsyncNotifyChannel** param5) CreatePrintAsyncNotifyChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* param0, PrintAsyncNotifyUserFilter param1, PrintAsyncNotifyConversationStyle param2, IPrintAsyncNotifyCallback* param3, IPrintAsyncNotifyRegistration** param4) CreatePrintAsyncNotifyRegistration;
	}


	public HRESULT CreatePrintAsyncNotifyChannel(uint32 param0, Guid* param1, PrintAsyncNotifyUserFilter param2, PrintAsyncNotifyConversationStyle param3, IPrintAsyncNotifyCallback* param4, IPrintAsyncNotifyChannel** param5) mut => VT.[Friend]CreatePrintAsyncNotifyChannel(&this, param0, param1, param2, param3, param4, param5);

	public HRESULT CreatePrintAsyncNotifyRegistration(Guid* param0, PrintAsyncNotifyUserFilter param1, PrintAsyncNotifyConversationStyle param2, IPrintAsyncNotifyCallback* param3, IPrintAsyncNotifyRegistration** param4) mut => VT.[Friend]CreatePrintAsyncNotifyRegistration(&this, param0, param1, param2, param3, param4);
}

[CRepr]struct IPrintAsyncCookie : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT param0) FinishAsyncCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT param0) CancelAsyncCall;
	}


	public HRESULT FinishAsyncCall(HRESULT param0) mut => VT.[Friend]FinishAsyncCall(&this, param0);

	public HRESULT CancelAsyncCall(HRESULT param0) mut => VT.[Friend]CancelAsyncCall(&this, param0);
}

[CRepr]struct IPrintAsyncNewChannelCookie : IPrintAsyncCookie
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintAsyncCookie.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyChannel** param0, uint32 param1) FinishAsyncCallWithData;
	}


	public HRESULT FinishAsyncCallWithData(IPrintAsyncNotifyChannel** param0, uint32 param1) mut => VT.[Friend]FinishAsyncCallWithData(&this, param0, param1);
}

[CRepr]struct IAsyncGetSendNotificationCookie : IPrintAsyncCookie
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintAsyncCookie.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject* param0, BOOL param1) FinishAsyncCallWithData;
	}


	public HRESULT FinishAsyncCallWithData(IPrintAsyncNotifyDataObject* param0, BOOL param1) mut => VT.[Friend]FinishAsyncCallWithData(&this, param0, param1);
}

[CRepr]struct IAsyncGetSrvReferralCookie : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT param0) FinishAsyncCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT param0) CancelAsyncCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR param0) FinishAsyncCallWithData;
	}


	public HRESULT FinishAsyncCall(HRESULT param0) mut => VT.[Friend]FinishAsyncCall(&this, param0);

	public HRESULT CancelAsyncCall(HRESULT param0) mut => VT.[Friend]CancelAsyncCall(&this, param0);

	public HRESULT FinishAsyncCallWithData(PWSTR param0) mut => VT.[Friend]FinishAsyncCallWithData(&this, param0);
}

[CRepr]struct IPrintBidiAsyncNotifyRegistration : IPrintAsyncNotifyRegistration
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintAsyncNotifyRegistration.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNewChannelCookie* param0) AsyncGetNewChannel;
	}


	public HRESULT AsyncGetNewChannel(IPrintAsyncNewChannelCookie* param0) mut => VT.[Friend]AsyncGetNewChannel(&this, param0);
}

[CRepr]struct IPrintUnidiAsyncNotifyRegistration : IPrintAsyncNotifyRegistration
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintAsyncNotifyRegistration.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAsyncGetSendNotificationCookie* param0) AsyncGetNotification;
	}


	public HRESULT AsyncGetNotification(IAsyncGetSendNotificationCookie* param0) mut => VT.[Friend]AsyncGetNotification(&this, param0);
}

[CRepr]struct IPrintAsyncNotifyServerReferral : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* param0) GetServerReferral;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAsyncGetSrvReferralCookie* param0) AsyncGetServerReferral;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pRmtServerReferral) SetServerReferral;
	}


	public HRESULT GetServerReferral(PWSTR* param0) mut => VT.[Friend]GetServerReferral(&this, param0);

	public HRESULT AsyncGetServerReferral(IAsyncGetSrvReferralCookie* param0) mut => VT.[Friend]AsyncGetServerReferral(&this, param0);

	public HRESULT SetServerReferral(PWSTR pRmtServerReferral) mut => VT.[Friend]SetServerReferral(&this, pRmtServerReferral);
}

[CRepr]struct IBidiAsyncNotifyChannel : IPrintAsyncNotifyChannel
{
	public new const Guid IID = .(0x532818f7, 0x921b, 0x4fb2, 0xbf, 0xf8, 0x2f, 0x4f, 0xd5, 0x2e, 0xbe, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintAsyncNotifyChannel.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CreateNotificationChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject** param0) GetPrintName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject** param0) GetChannelNotificationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject* param0, IAsyncGetSendNotificationCookie* param1) AsyncGetNotificationSendResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintAsyncNotifyDataObject* param0, IPrintAsyncCookie* param1) AsyncCloseChannel;
	}


	public HRESULT CreateNotificationChannel() mut => VT.[Friend]CreateNotificationChannel(&this);

	public HRESULT GetPrintName(IPrintAsyncNotifyDataObject** param0) mut => VT.[Friend]GetPrintName(&this, param0);

	public HRESULT GetChannelNotificationType(IPrintAsyncNotifyDataObject** param0) mut => VT.[Friend]GetChannelNotificationType(&this, param0);

	public HRESULT AsyncGetNotificationSendResponse(IPrintAsyncNotifyDataObject* param0, IAsyncGetSendNotificationCookie* param1) mut => VT.[Friend]AsyncGetNotificationSendResponse(&this, param0, param1);

	public HRESULT AsyncCloseChannel(IPrintAsyncNotifyDataObject* param0, IPrintAsyncCookie* param1) mut => VT.[Friend]AsyncCloseChannel(&this, param0, param1);
}

[CRepr]struct IXpsRasterizerNotificationCallback : IUnknown
{
	public new const Guid IID = .(0x9ab8fd0d, 0xcb94, 0x49c2, 0x9c, 0xb0, 0x97, 0xec, 0x1d, 0x54, 0x69, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Continue;
	}


	public HRESULT Continue() mut => VT.[Friend]Continue(&this);
}

[CRepr]struct IXpsRasterizer : IUnknown
{
	public new const Guid IID = .(0x7567cfc8, 0xc156, 0x47a8, 0x9d, 0xac, 0x11, 0xa2, 0xae, 0x5b, 0xdd, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, int32 width, int32 height, IXpsRasterizerNotificationCallback* notificationCallback, IWICBitmap** bitmap) RasterizeRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 width) SetMinimalLineWidth;
	}


	public HRESULT RasterizeRect(int32 x, int32 y, int32 width, int32 height, IXpsRasterizerNotificationCallback* notificationCallback, IWICBitmap** bitmap) mut => VT.[Friend]RasterizeRect(&this, x, y, width, height, notificationCallback, bitmap);

	public HRESULT SetMinimalLineWidth(int32 width) mut => VT.[Friend]SetMinimalLineWidth(&this, width);
}

[CRepr]struct IXpsRasterizationFactory : IUnknown
{
	public new const Guid IID = .(0xe094808a, 0x24c6, 0x482b, 0xa3, 0xa7, 0xc2, 0x1a, 0xc9, 0xb5, 0x5f, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage* xpsPage, float DPI, XPSRAS_RENDERING_MODE nonTextRenderingMode, XPSRAS_RENDERING_MODE textRenderingMode, IXpsRasterizer** ppIXPSRasterizer) CreateRasterizer;
	}


	public HRESULT CreateRasterizer(IXpsOMPage* xpsPage, float DPI, XPSRAS_RENDERING_MODE nonTextRenderingMode, XPSRAS_RENDERING_MODE textRenderingMode, IXpsRasterizer** ppIXPSRasterizer) mut => VT.[Friend]CreateRasterizer(&this, xpsPage, DPI, nonTextRenderingMode, textRenderingMode, ppIXPSRasterizer);
}

[CRepr]struct IXpsRasterizationFactory1 : IUnknown
{
	public new const Guid IID = .(0x2d6e5f77, 0x6414, 0x4a1e, 0xa8, 0xe0, 0xd4, 0x19, 0x4c, 0xe6, 0xa2, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage* xpsPage, float DPI, XPSRAS_RENDERING_MODE nonTextRenderingMode, XPSRAS_RENDERING_MODE textRenderingMode, XPSRAS_PIXEL_FORMAT pixelFormat, IXpsRasterizer** ppIXPSRasterizer) CreateRasterizer;
	}


	public HRESULT CreateRasterizer(IXpsOMPage* xpsPage, float DPI, XPSRAS_RENDERING_MODE nonTextRenderingMode, XPSRAS_RENDERING_MODE textRenderingMode, XPSRAS_PIXEL_FORMAT pixelFormat, IXpsRasterizer** ppIXPSRasterizer) mut => VT.[Friend]CreateRasterizer(&this, xpsPage, DPI, nonTextRenderingMode, textRenderingMode, pixelFormat, ppIXPSRasterizer);
}

[CRepr]struct IXpsRasterizationFactory2 : IUnknown
{
	public new const Guid IID = .(0x9c16ce3e, 0x10f5, 0x41fd, 0x9d, 0xdc, 0x68, 0x26, 0x66, 0x9c, 0x2f, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage* xpsPage, float DPIX, float DPIY, XPSRAS_RENDERING_MODE nonTextRenderingMode, XPSRAS_RENDERING_MODE textRenderingMode, XPSRAS_PIXEL_FORMAT pixelFormat, XPSRAS_BACKGROUND_COLOR backgroundColor, IXpsRasterizer** ppIXpsRasterizer) CreateRasterizer;
	}


	public HRESULT CreateRasterizer(IXpsOMPage* xpsPage, float DPIX, float DPIY, XPSRAS_RENDERING_MODE nonTextRenderingMode, XPSRAS_RENDERING_MODE textRenderingMode, XPSRAS_PIXEL_FORMAT pixelFormat, XPSRAS_BACKGROUND_COLOR backgroundColor, IXpsRasterizer** ppIXpsRasterizer) mut => VT.[Friend]CreateRasterizer(&this, xpsPage, DPIX, DPIY, nonTextRenderingMode, textRenderingMode, pixelFormat, backgroundColor, ppIXpsRasterizer);
}

[CRepr]struct IPrintPreviewDxgiPackageTarget : IUnknown
{
	public new const Guid IID = .(0x1a6dd0ad, 0x1e2a, 0x4e99, 0xa5, 0xba, 0x91, 0xf1, 0x78, 0x18, 0x29, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PageCountType countType, uint32 count) SetJobPageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 jobPageNumber, IDXGISurface* pageImage, float dpiX, float dpiY) DrawPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InvalidatePreview;
	}


	public HRESULT SetJobPageCount(PageCountType countType, uint32 count) mut => VT.[Friend]SetJobPageCount(&this, countType, count);

	public HRESULT DrawPage(uint32 jobPageNumber, IDXGISurface* pageImage, float dpiX, float dpiY) mut => VT.[Friend]DrawPage(&this, jobPageNumber, pageImage, dpiX, dpiY);

	public HRESULT InvalidatePreview() mut => VT.[Friend]InvalidatePreview(&this);
}

#endregion

#region Functions
public static
{
	[Import("COMPSTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CommonPropertySheetUIA(HWND hWndOwner, PFNPROPSHEETUI pfnPropSheetUI, LPARAM lParam, uint32* pResult);
	public static int32 CommonPropertySheetUI(HWND hWndOwner, PFNPROPSHEETUI pfnPropSheetUI, LPARAM lParam, uint32* pResult) => CommonPropertySheetUIA(hWndOwner, pfnPropSheetUI, lParam, pResult);

	[Import("COMPSTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CommonPropertySheetUIW(HWND hWndOwner, PFNPROPSHEETUI pfnPropSheetUI, LPARAM lParam, uint32* pResult);

	[Import("COMPSTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint GetCPSUIUserData(HWND hDlg);

	[Import("COMPSTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCPSUIUserData(HWND hDlg, uint CPSUIUserData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrintersA(uint32 Flags, PSTR Name, uint32 Level, uint8* pPrinterEnum, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumPrinters(uint32 Flags, PSTR Name, uint32 Level, uint8* pPrinterEnum, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumPrintersA(Flags, Name, Level, pPrinterEnum, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrintersW(uint32 Flags, PWSTR Name, uint32 Level, uint8* pPrinterEnum, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GetSpoolFileHandle(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CommitSpoolData(HANDLE hPrinter, HANDLE hSpoolFile, uint32 cbCommit);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseSpoolFileHandle(HANDLE hPrinter, HANDLE hSpoolFile);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenPrinterA(PSTR pPrinterName, HANDLE* phPrinter, PRINTER_DEFAULTSA* pDefault);
	public static BOOL OpenPrinter(PSTR pPrinterName, HANDLE* phPrinter, PRINTER_DEFAULTSA* pDefault) => OpenPrinterA(pPrinterName, phPrinter, pDefault);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenPrinterW(PWSTR pPrinterName, HANDLE* phPrinter, PRINTER_DEFAULTSW* pDefault);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResetPrinterA(HANDLE hPrinter, PRINTER_DEFAULTSA* pDefault);
	public static BOOL ResetPrinter(HANDLE hPrinter, PRINTER_DEFAULTSA* pDefault) => ResetPrinterA(hPrinter, pDefault);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResetPrinterW(HANDLE hPrinter, PRINTER_DEFAULTSW* pDefault);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetJobA(HANDLE hPrinter, uint32 JobId, uint32 Level, uint8* pJob, uint32 Command);
	public static BOOL SetJob(HANDLE hPrinter, uint32 JobId, uint32 Level, uint8* pJob, uint32 Command) => SetJobA(hPrinter, JobId, Level, pJob, Command);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetJobW(HANDLE hPrinter, uint32 JobId, uint32 Level, uint8* pJob, uint32 Command);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetJobA(HANDLE hPrinter, uint32 JobId, uint32 Level, uint8* pJob, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetJob(HANDLE hPrinter, uint32 JobId, uint32 Level, uint8* pJob, uint32 cbBuf, uint32* pcbNeeded) => GetJobA(hPrinter, JobId, Level, pJob, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetJobW(HANDLE hPrinter, uint32 JobId, uint32 Level, uint8* pJob, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumJobsA(HANDLE hPrinter, uint32 FirstJob, uint32 NoJobs, uint32 Level, uint8* pJob, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumJobs(HANDLE hPrinter, uint32 FirstJob, uint32 NoJobs, uint32 Level, uint8* pJob, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumJobsA(hPrinter, FirstJob, NoJobs, Level, pJob, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumJobsW(HANDLE hPrinter, uint32 FirstJob, uint32 NoJobs, uint32 Level, uint8* pJob, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AddPrinterA(PSTR pName, uint32 Level, uint8* pPrinter);
	public static HANDLE AddPrinter(PSTR pName, uint32 Level, uint8* pPrinter) => AddPrinterA(pName, Level, pPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AddPrinterW(PWSTR pName, uint32 Level, uint8* pPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinter(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPrinterA(HANDLE hPrinter, uint32 Level, uint8* pPrinter, uint32 Command);
	public static BOOL SetPrinter(HANDLE hPrinter, uint32 Level, uint8* pPrinter, uint32 Command) => SetPrinterA(hPrinter, Level, pPrinter, Command);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPrinterW(HANDLE hPrinter, uint32 Level, uint8* pPrinter, uint32 Command);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterA(HANDLE hPrinter, uint32 Level, uint8* pPrinter, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetPrinter(HANDLE hPrinter, uint32 Level, uint8* pPrinter, uint32 cbBuf, uint32* pcbNeeded) => GetPrinterA(hPrinter, Level, pPrinter, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterW(HANDLE hPrinter, uint32 Level, uint8* pPrinter, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterDriverA(PSTR pName, uint32 Level, uint8* pDriverInfo);
	public static BOOL AddPrinterDriver(PSTR pName, uint32 Level, uint8* pDriverInfo) => AddPrinterDriverA(pName, Level, pDriverInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterDriverW(PWSTR pName, uint32 Level, uint8* pDriverInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterDriverExA(PSTR pName, uint32 Level, uint8* lpbDriverInfo, uint32 dwFileCopyFlags);
	public static BOOL AddPrinterDriverEx(PSTR pName, uint32 Level, uint8* lpbDriverInfo, uint32 dwFileCopyFlags) => AddPrinterDriverExA(pName, Level, lpbDriverInfo, dwFileCopyFlags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterDriverExW(PWSTR pName, uint32 Level, uint8* lpbDriverInfo, uint32 dwFileCopyFlags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrinterDriversA(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumPrinterDrivers(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumPrinterDriversA(pName, pEnvironment, Level, pDriverInfo, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrinterDriversW(PWSTR pName, PWSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterDriverA(HANDLE hPrinter, PSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetPrinterDriver(HANDLE hPrinter, PSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded) => GetPrinterDriverA(hPrinter, pEnvironment, Level, pDriverInfo, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterDriverW(HANDLE hPrinter, PWSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterDriverDirectoryA(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pDriverDirectory, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetPrinterDriverDirectory(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pDriverDirectory, uint32 cbBuf, uint32* pcbNeeded) => GetPrinterDriverDirectoryA(pName, pEnvironment, Level, pDriverDirectory, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterDriverDirectoryW(PWSTR pName, PWSTR pEnvironment, uint32 Level, uint8* pDriverDirectory, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterDriverA(PSTR pName, PSTR pEnvironment, PSTR pDriverName);
	public static BOOL DeletePrinterDriver(PSTR pName, PSTR pEnvironment, PSTR pDriverName) => DeletePrinterDriverA(pName, pEnvironment, pDriverName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterDriverW(PWSTR pName, PWSTR pEnvironment, PWSTR pDriverName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterDriverExA(PSTR pName, PSTR pEnvironment, PSTR pDriverName, uint32 dwDeleteFlag, uint32 dwVersionFlag);
	public static BOOL DeletePrinterDriverEx(PSTR pName, PSTR pEnvironment, PSTR pDriverName, uint32 dwDeleteFlag, uint32 dwVersionFlag) => DeletePrinterDriverExA(pName, pEnvironment, pDriverName, dwDeleteFlag, dwVersionFlag);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterDriverExW(PWSTR pName, PWSTR pEnvironment, PWSTR pDriverName, uint32 dwDeleteFlag, uint32 dwVersionFlag);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrintProcessorA(PSTR pName, PSTR pEnvironment, PSTR pPathName, PSTR pPrintProcessorName);
	public static BOOL AddPrintProcessor(PSTR pName, PSTR pEnvironment, PSTR pPathName, PSTR pPrintProcessorName) => AddPrintProcessorA(pName, pEnvironment, pPathName, pPrintProcessorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrintProcessorW(PWSTR pName, PWSTR pEnvironment, PWSTR pPathName, PWSTR pPrintProcessorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrintProcessorsA(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pPrintProcessorInfo, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumPrintProcessors(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pPrintProcessorInfo, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumPrintProcessorsA(pName, pEnvironment, Level, pPrintProcessorInfo, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrintProcessorsW(PWSTR pName, PWSTR pEnvironment, uint32 Level, uint8* pPrintProcessorInfo, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrintProcessorDirectoryA(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pPrintProcessorInfo, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetPrintProcessorDirectory(PSTR pName, PSTR pEnvironment, uint32 Level, uint8* pPrintProcessorInfo, uint32 cbBuf, uint32* pcbNeeded) => GetPrintProcessorDirectoryA(pName, pEnvironment, Level, pPrintProcessorInfo, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrintProcessorDirectoryW(PWSTR pName, PWSTR pEnvironment, uint32 Level, uint8* pPrintProcessorInfo, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrintProcessorDatatypesA(PSTR pName, PSTR pPrintProcessorName, uint32 Level, uint8* pDatatypes, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumPrintProcessorDatatypes(PSTR pName, PSTR pPrintProcessorName, uint32 Level, uint8* pDatatypes, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumPrintProcessorDatatypesA(pName, pPrintProcessorName, Level, pDatatypes, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPrintProcessorDatatypesW(PWSTR pName, PWSTR pPrintProcessorName, uint32 Level, uint8* pDatatypes, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrintProcessorA(PSTR pName, PSTR pEnvironment, PSTR pPrintProcessorName);
	public static BOOL DeletePrintProcessor(PSTR pName, PSTR pEnvironment, PSTR pPrintProcessorName) => DeletePrintProcessorA(pName, pEnvironment, pPrintProcessorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrintProcessorW(PWSTR pName, PWSTR pEnvironment, PWSTR pPrintProcessorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 StartDocPrinterA(HANDLE hPrinter, uint32 Level, DOC_INFO_1A* pDocInfo);
	public static uint32 StartDocPrinter(HANDLE hPrinter, uint32 Level, DOC_INFO_1A* pDocInfo) => StartDocPrinterA(hPrinter, Level, pDocInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 StartDocPrinterW(HANDLE hPrinter, uint32 Level, DOC_INFO_1W* pDocInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StartPagePrinter(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrinter(HANDLE hPrinter, void* pBuf, uint32 cbBuf, uint32* pcWritten);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlushPrinter(HANDLE hPrinter, void* pBuf, uint32 cbBuf, uint32* pcWritten, uint32 cSleep);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndPagePrinter(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AbortPrinter(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadPrinter(HANDLE hPrinter, void* pBuf, uint32 cbBuf, uint32* pNoBytesRead);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndDocPrinter(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddJobA(HANDLE hPrinter, uint32 Level, uint8* pData, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL AddJob(HANDLE hPrinter, uint32 Level, uint8* pData, uint32 cbBuf, uint32* pcbNeeded) => AddJobA(hPrinter, Level, pData, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddJobW(HANDLE hPrinter, uint32 Level, uint8* pData, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScheduleJob(HANDLE hPrinter, uint32 JobId);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrinterProperties(HWND hWnd, HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DocumentPropertiesA(HWND hWnd, HANDLE hPrinter, PSTR pDeviceName, DEVMODEA* pDevModeOutput, DEVMODEA* pDevModeInput, uint32 fMode);
	public static int32 DocumentProperties(HWND hWnd, HANDLE hPrinter, PSTR pDeviceName, DEVMODEA* pDevModeOutput, DEVMODEA* pDevModeInput, uint32 fMode) => DocumentPropertiesA(hWnd, hPrinter, pDeviceName, pDevModeOutput, pDevModeInput, fMode);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DocumentPropertiesW(HWND hWnd, HANDLE hPrinter, PWSTR pDeviceName, DEVMODEW* pDevModeOutput, DEVMODEW* pDevModeInput, uint32 fMode);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AdvancedDocumentPropertiesA(HWND hWnd, HANDLE hPrinter, PSTR pDeviceName, DEVMODEA* pDevModeOutput, DEVMODEA* pDevModeInput);
	public static int32 AdvancedDocumentProperties(HWND hWnd, HANDLE hPrinter, PSTR pDeviceName, DEVMODEA* pDevModeOutput, DEVMODEA* pDevModeInput) => AdvancedDocumentPropertiesA(hWnd, hPrinter, pDeviceName, pDevModeOutput, pDevModeInput);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AdvancedDocumentPropertiesW(HWND hWnd, HANDLE hPrinter, PWSTR pDeviceName, DEVMODEW* pDevModeOutput, DEVMODEW* pDevModeInput);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ExtDeviceMode(HWND hWnd, HANDLE hInst, DEVMODEA* pDevModeOutput, PSTR pDeviceName, PSTR pPort, DEVMODEA* pDevModeInput, PSTR pProfile, uint32 fMode);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrinterDataA(HANDLE hPrinter, PSTR pValueName, uint32* pType, uint8* pData, uint32 nSize, uint32* pcbNeeded);
	public static uint32 GetPrinterData(HANDLE hPrinter, PSTR pValueName, uint32* pType, uint8* pData, uint32 nSize, uint32* pcbNeeded) => GetPrinterDataA(hPrinter, pValueName, pType, pData, nSize, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrinterDataW(HANDLE hPrinter, PWSTR pValueName, uint32* pType, uint8* pData, uint32 nSize, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrinterDataExA(HANDLE hPrinter, PSTR pKeyName, PSTR pValueName, uint32* pType, uint8* pData, uint32 nSize, uint32* pcbNeeded);
	public static uint32 GetPrinterDataEx(HANDLE hPrinter, PSTR pKeyName, PSTR pValueName, uint32* pType, uint8* pData, uint32 nSize, uint32* pcbNeeded) => GetPrinterDataExA(hPrinter, pKeyName, pValueName, pType, pData, nSize, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrinterDataExW(HANDLE hPrinter, PWSTR pKeyName, PWSTR pValueName, uint32* pType, uint8* pData, uint32 nSize, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumPrinterDataA(HANDLE hPrinter, uint32 dwIndex, PSTR pValueName, uint32 cbValueName, uint32* pcbValueName, uint32* pType, uint8* pData, uint32 cbData, uint32* pcbData);
	public static uint32 EnumPrinterData(HANDLE hPrinter, uint32 dwIndex, PSTR pValueName, uint32 cbValueName, uint32* pcbValueName, uint32* pType, uint8* pData, uint32 cbData, uint32* pcbData) => EnumPrinterDataA(hPrinter, dwIndex, pValueName, cbValueName, pcbValueName, pType, pData, cbData, pcbData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumPrinterDataW(HANDLE hPrinter, uint32 dwIndex, PWSTR pValueName, uint32 cbValueName, uint32* pcbValueName, uint32* pType, uint8* pData, uint32 cbData, uint32* pcbData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumPrinterDataExA(HANDLE hPrinter, PSTR pKeyName, uint8* pEnumValues, uint32 cbEnumValues, uint32* pcbEnumValues, uint32* pnEnumValues);
	public static uint32 EnumPrinterDataEx(HANDLE hPrinter, PSTR pKeyName, uint8* pEnumValues, uint32 cbEnumValues, uint32* pcbEnumValues, uint32* pnEnumValues) => EnumPrinterDataExA(hPrinter, pKeyName, pEnumValues, cbEnumValues, pcbEnumValues, pnEnumValues);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumPrinterDataExW(HANDLE hPrinter, PWSTR pKeyName, uint8* pEnumValues, uint32 cbEnumValues, uint32* pcbEnumValues, uint32* pnEnumValues);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumPrinterKeyA(HANDLE hPrinter, PSTR pKeyName, PSTR pSubkey, uint32 cbSubkey, uint32* pcbSubkey);
	public static uint32 EnumPrinterKey(HANDLE hPrinter, PSTR pKeyName, PSTR pSubkey, uint32 cbSubkey, uint32* pcbSubkey) => EnumPrinterKeyA(hPrinter, pKeyName, pSubkey, cbSubkey, pcbSubkey);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumPrinterKeyW(HANDLE hPrinter, PWSTR pKeyName, PWSTR pSubkey, uint32 cbSubkey, uint32* pcbSubkey);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetPrinterDataA(HANDLE hPrinter, PSTR pValueName, uint32 Type, uint8* pData, uint32 cbData);
	public static uint32 SetPrinterData(HANDLE hPrinter, PSTR pValueName, uint32 Type, uint8* pData, uint32 cbData) => SetPrinterDataA(hPrinter, pValueName, Type, pData, cbData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetPrinterDataW(HANDLE hPrinter, PWSTR pValueName, uint32 Type, uint8* pData, uint32 cbData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetPrinterDataExA(HANDLE hPrinter, PSTR pKeyName, PSTR pValueName, uint32 Type, uint8* pData, uint32 cbData);
	public static uint32 SetPrinterDataEx(HANDLE hPrinter, PSTR pKeyName, PSTR pValueName, uint32 Type, uint8* pData, uint32 cbData) => SetPrinterDataExA(hPrinter, pKeyName, pValueName, Type, pData, cbData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetPrinterDataExW(HANDLE hPrinter, PWSTR pKeyName, PWSTR pValueName, uint32 Type, uint8* pData, uint32 cbData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeletePrinterDataA(HANDLE hPrinter, PSTR pValueName);
	public static uint32 DeletePrinterData(HANDLE hPrinter, PSTR pValueName) => DeletePrinterDataA(hPrinter, pValueName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeletePrinterDataW(HANDLE hPrinter, PWSTR pValueName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeletePrinterDataExA(HANDLE hPrinter, PSTR pKeyName, PSTR pValueName);
	public static uint32 DeletePrinterDataEx(HANDLE hPrinter, PSTR pKeyName, PSTR pValueName) => DeletePrinterDataExA(hPrinter, pKeyName, pValueName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeletePrinterDataExW(HANDLE hPrinter, PWSTR pKeyName, PWSTR pValueName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeletePrinterKeyA(HANDLE hPrinter, PSTR pKeyName);
	public static uint32 DeletePrinterKey(HANDLE hPrinter, PSTR pKeyName) => DeletePrinterKeyA(hPrinter, pKeyName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeletePrinterKeyW(HANDLE hPrinter, PWSTR pKeyName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WaitForPrinterChange(HANDLE hPrinter, uint32 Flags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE FindFirstPrinterChangeNotification(HANDLE hPrinter, uint32 fdwFilter, uint32 fdwOptions, void* pPrinterNotifyOptions);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextPrinterChangeNotification(HANDLE hChange, uint32* pdwChange, void* pvReserved, void** ppPrinterNotifyInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreePrinterNotifyInfo(PRINTER_NOTIFY_INFO* pPrinterNotifyInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindClosePrinterChangeNotification(HANDLE hChange);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PrinterMessageBoxA(HANDLE hPrinter, uint32 Error, HWND hWnd, PSTR pText, PSTR pCaption, uint32 dwType);
	public static uint32 PrinterMessageBox(HANDLE hPrinter, uint32 Error, HWND hWnd, PSTR pText, PSTR pCaption, uint32 dwType) => PrinterMessageBoxA(hPrinter, Error, hWnd, pText, pCaption, dwType);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PrinterMessageBoxW(HANDLE hPrinter, uint32 Error, HWND hWnd, PWSTR pText, PWSTR pCaption, uint32 dwType);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClosePrinter(HANDLE hPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddFormA(HANDLE hPrinter, uint32 Level, uint8* pForm);
	public static BOOL AddForm(HANDLE hPrinter, uint32 Level, uint8* pForm) => AddFormA(hPrinter, Level, pForm);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddFormW(HANDLE hPrinter, uint32 Level, uint8* pForm);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFormA(HANDLE hPrinter, PSTR pFormName);
	public static BOOL DeleteForm(HANDLE hPrinter, PSTR pFormName) => DeleteFormA(hPrinter, pFormName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFormW(HANDLE hPrinter, PWSTR pFormName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFormA(HANDLE hPrinter, PSTR pFormName, uint32 Level, uint8* pForm, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetForm(HANDLE hPrinter, PSTR pFormName, uint32 Level, uint8* pForm, uint32 cbBuf, uint32* pcbNeeded) => GetFormA(hPrinter, pFormName, Level, pForm, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFormW(HANDLE hPrinter, PWSTR pFormName, uint32 Level, uint8* pForm, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFormA(HANDLE hPrinter, PSTR pFormName, uint32 Level, uint8* pForm);
	public static BOOL SetForm(HANDLE hPrinter, PSTR pFormName, uint32 Level, uint8* pForm) => SetFormA(hPrinter, pFormName, Level, pForm);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFormW(HANDLE hPrinter, PWSTR pFormName, uint32 Level, uint8* pForm);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumFormsA(HANDLE hPrinter, uint32 Level, uint8* pForm, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumForms(HANDLE hPrinter, uint32 Level, uint8* pForm, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumFormsA(hPrinter, Level, pForm, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumFormsW(HANDLE hPrinter, uint32 Level, uint8* pForm, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumMonitorsA(PSTR pName, uint32 Level, uint8* pMonitor, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumMonitors(PSTR pName, uint32 Level, uint8* pMonitor, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumMonitorsA(pName, Level, pMonitor, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumMonitorsW(PWSTR pName, uint32 Level, uint8* pMonitor, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddMonitorA(PSTR pName, uint32 Level, uint8* pMonitors);
	public static BOOL AddMonitor(PSTR pName, uint32 Level, uint8* pMonitors) => AddMonitorA(pName, Level, pMonitors);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddMonitorW(PWSTR pName, uint32 Level, uint8* pMonitors);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteMonitorA(PSTR pName, PSTR pEnvironment, PSTR pMonitorName);
	public static BOOL DeleteMonitor(PSTR pName, PSTR pEnvironment, PSTR pMonitorName) => DeleteMonitorA(pName, pEnvironment, pMonitorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteMonitorW(PWSTR pName, PWSTR pEnvironment, PWSTR pMonitorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPortsA(PSTR pName, uint32 Level, uint8* pPort, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);
	public static BOOL EnumPorts(PSTR pName, uint32 Level, uint8* pPort, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned) => EnumPortsA(pName, Level, pPort, cbBuf, pcbNeeded, pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumPortsW(PWSTR pName, uint32 Level, uint8* pPort, uint32 cbBuf, uint32* pcbNeeded, uint32* pcReturned);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPortA(PSTR pName, HWND hWnd, PSTR pMonitorName);
	public static BOOL AddPort(PSTR pName, HWND hWnd, PSTR pMonitorName) => AddPortA(pName, hWnd, pMonitorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPortW(PWSTR pName, HWND hWnd, PWSTR pMonitorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConfigurePortA(PSTR pName, HWND hWnd, PSTR pPortName);
	public static BOOL ConfigurePort(PSTR pName, HWND hWnd, PSTR pPortName) => ConfigurePortA(pName, hWnd, pPortName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConfigurePortW(PWSTR pName, HWND hWnd, PWSTR pPortName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePortA(PSTR pName, HWND hWnd, PSTR pPortName);
	public static BOOL DeletePort(PSTR pName, HWND hWnd, PSTR pPortName) => DeletePortA(pName, hWnd, pPortName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePortW(PWSTR pName, HWND hWnd, PWSTR pPortName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL XcvDataW(HANDLE hXcv, PWSTR pszDataName, uint8* pInputData, uint32 cbInputData, uint8* pOutputData, uint32 cbOutputData, uint32* pcbOutputNeeded, uint32* pdwStatus);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDefaultPrinterA(uint8* pszBuffer, uint32* pcchBuffer);
	public static BOOL GetDefaultPrinter(uint8* pszBuffer, uint32* pcchBuffer) => GetDefaultPrinterA(pszBuffer, pcchBuffer);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDefaultPrinterW(char16* pszBuffer, uint32* pcchBuffer);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDefaultPrinterA(PSTR pszPrinter);
	public static BOOL SetDefaultPrinter(PSTR pszPrinter) => SetDefaultPrinterA(pszPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDefaultPrinterW(PWSTR pszPrinter);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPortA(PSTR pName, PSTR pPortName, uint32 dwLevel, uint8* pPortInfo);
	public static BOOL SetPort(PSTR pName, PSTR pPortName, uint32 dwLevel, uint8* pPortInfo) => SetPortA(pName, pPortName, dwLevel, pPortInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPortW(PWSTR pName, PWSTR pPortName, uint32 dwLevel, uint8* pPortInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterConnectionA(PSTR pName);
	public static BOOL AddPrinterConnection(PSTR pName) => AddPrinterConnectionA(pName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterConnectionW(PWSTR pName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterConnectionA(PSTR pName);
	public static BOOL DeletePrinterConnection(PSTR pName) => DeletePrinterConnectionA(pName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterConnectionW(PWSTR pName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE ConnectToPrinterDlg(HWND hwnd, uint32 Flags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrintProvidorA(PSTR pName, uint32 Level, uint8* pProvidorInfo);
	public static BOOL AddPrintProvidor(PSTR pName, uint32 Level, uint8* pProvidorInfo) => AddPrintProvidorA(pName, Level, pProvidorInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrintProvidorW(PWSTR pName, uint32 Level, uint8* pProvidorInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrintProvidorA(PSTR pName, PSTR pEnvironment, PSTR pPrintProvidorName);
	public static BOOL DeletePrintProvidor(PSTR pName, PSTR pEnvironment, PSTR pPrintProvidorName) => DeletePrintProvidorA(pName, pEnvironment, pPrintProvidorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrintProvidorW(PWSTR pName, PWSTR pEnvironment, PWSTR pPrintProvidorName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidDevmodeA(DEVMODEA* pDevmode, uint DevmodeSize);
	public static BOOL IsValidDevmode(DEVMODEA* pDevmode, uint DevmodeSize) => IsValidDevmodeA(pDevmode, DevmodeSize);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidDevmodeW(DEVMODEW* pDevmode, uint DevmodeSize);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenPrinter2A(PSTR pPrinterName, HANDLE* phPrinter, PRINTER_DEFAULTSA* pDefault, PRINTER_OPTIONSA* pOptions);
	public static BOOL OpenPrinter2(PSTR pPrinterName, HANDLE* phPrinter, PRINTER_DEFAULTSA* pDefault, PRINTER_OPTIONSA* pOptions) => OpenPrinter2A(pPrinterName, phPrinter, pDefault, pOptions);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenPrinter2W(PWSTR pPrinterName, HANDLE* phPrinter, PRINTER_DEFAULTSW* pDefault, PRINTER_OPTIONSW* pOptions);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterConnection2A(HWND hWnd, PSTR pszName, uint32 dwLevel, void* pConnectionInfo);
	public static BOOL AddPrinterConnection2(HWND hWnd, PSTR pszName, uint32 dwLevel, void* pConnectionInfo) => AddPrinterConnection2A(hWnd, pszName, dwLevel, pConnectionInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddPrinterConnection2W(HWND hWnd, PWSTR pszName, uint32 dwLevel, void* pConnectionInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InstallPrinterDriverFromPackageA(PSTR pszServer, PSTR pszInfPath, PSTR pszDriverName, PSTR pszEnvironment, uint32 dwFlags);
	public static HRESULT InstallPrinterDriverFromPackage(PSTR pszServer, PSTR pszInfPath, PSTR pszDriverName, PSTR pszEnvironment, uint32 dwFlags) => InstallPrinterDriverFromPackageA(pszServer, pszInfPath, pszDriverName, pszEnvironment, dwFlags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InstallPrinterDriverFromPackageW(PWSTR pszServer, PWSTR pszInfPath, PWSTR pszDriverName, PWSTR pszEnvironment, uint32 dwFlags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UploadPrinterDriverPackageA(PSTR pszServer, PSTR pszInfPath, PSTR pszEnvironment, uint32 dwFlags, HWND hwnd, uint8* pszDestInfPath, uint32* pcchDestInfPath);
	public static HRESULT UploadPrinterDriverPackage(PSTR pszServer, PSTR pszInfPath, PSTR pszEnvironment, uint32 dwFlags, HWND hwnd, uint8* pszDestInfPath, uint32* pcchDestInfPath) => UploadPrinterDriverPackageA(pszServer, pszInfPath, pszEnvironment, dwFlags, hwnd, pszDestInfPath, pcchDestInfPath);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UploadPrinterDriverPackageW(PWSTR pszServer, PWSTR pszInfPath, PWSTR pszEnvironment, uint32 dwFlags, HWND hwnd, char16* pszDestInfPath, uint32* pcchDestInfPath);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetCorePrinterDriversA(PSTR pszServer, PSTR pszEnvironment, PSTR pszzCoreDriverDependencies, uint32 cCorePrinterDrivers, CORE_PRINTER_DRIVERA* pCorePrinterDrivers);
	public static HRESULT GetCorePrinterDrivers(PSTR pszServer, PSTR pszEnvironment, PSTR pszzCoreDriverDependencies, uint32 cCorePrinterDrivers, CORE_PRINTER_DRIVERA* pCorePrinterDrivers) => GetCorePrinterDriversA(pszServer, pszEnvironment, pszzCoreDriverDependencies, cCorePrinterDrivers, pCorePrinterDrivers);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetCorePrinterDriversW(PWSTR pszServer, PWSTR pszEnvironment, PWSTR pszzCoreDriverDependencies, uint32 cCorePrinterDrivers, CORE_PRINTER_DRIVERW* pCorePrinterDrivers);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CorePrinterDriverInstalledA(PSTR pszServer, PSTR pszEnvironment, Guid CoreDriverGUID, FILETIME ftDriverDate, uint64 dwlDriverVersion, BOOL* pbDriverInstalled);
	public static HRESULT CorePrinterDriverInstalled(PSTR pszServer, PSTR pszEnvironment, Guid CoreDriverGUID, FILETIME ftDriverDate, uint64 dwlDriverVersion, BOOL* pbDriverInstalled) => CorePrinterDriverInstalledA(pszServer, pszEnvironment, CoreDriverGUID, ftDriverDate, dwlDriverVersion, pbDriverInstalled);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CorePrinterDriverInstalledW(PWSTR pszServer, PWSTR pszEnvironment, Guid CoreDriverGUID, FILETIME ftDriverDate, uint64 dwlDriverVersion, BOOL* pbDriverInstalled);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetPrinterDriverPackagePathA(PSTR pszServer, PSTR pszEnvironment, PSTR pszLanguage, PSTR pszPackageID, uint8* pszDriverPackageCab, uint32 cchDriverPackageCab, uint32* pcchRequiredSize);
	public static HRESULT GetPrinterDriverPackagePath(PSTR pszServer, PSTR pszEnvironment, PSTR pszLanguage, PSTR pszPackageID, uint8* pszDriverPackageCab, uint32 cchDriverPackageCab, uint32* pcchRequiredSize) => GetPrinterDriverPackagePathA(pszServer, pszEnvironment, pszLanguage, pszPackageID, pszDriverPackageCab, cchDriverPackageCab, pcchRequiredSize);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetPrinterDriverPackagePathW(PWSTR pszServer, PWSTR pszEnvironment, PWSTR pszLanguage, PWSTR pszPackageID, char16* pszDriverPackageCab, uint32 cchDriverPackageCab, uint32* pcchRequiredSize);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeletePrinterDriverPackageA(PSTR pszServer, PSTR pszInfPath, PSTR pszEnvironment);
	public static HRESULT DeletePrinterDriverPackage(PSTR pszServer, PSTR pszInfPath, PSTR pszEnvironment) => DeletePrinterDriverPackageA(pszServer, pszInfPath, pszEnvironment);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeletePrinterDriverPackageW(PWSTR pszServer, PWSTR pszInfPath, PWSTR pszEnvironment);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReportJobProcessingProgress(HANDLE printerHandle, uint32 jobId, EPrintXPSJobOperation jobOperation, EPrintXPSJobProgress jobProgress);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterDriver2A(HWND hWnd, HANDLE hPrinter, PSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded);
	public static BOOL GetPrinterDriver2(HWND hWnd, HANDLE hPrinter, PSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded) => GetPrinterDriver2A(hWnd, hPrinter, pEnvironment, Level, pDriverInfo, cbBuf, pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrinterDriver2W(HWND hWnd, HANDLE hPrinter, PWSTR pEnvironment, uint32 Level, uint8* pDriverInfo, uint32 cbBuf, uint32* pcbNeeded);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrintExecutionData(PRINT_EXECUTION_DATA* pData);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetJobNamedPropertyValue(HANDLE hPrinter, uint32 JobId, PWSTR pszName, PrintPropertyValue* pValue);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreePrintPropertyValue(PrintPropertyValue* pValue);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreePrintNamedPropertyArray(uint32 cProperties, PrintNamedProperty** ppProperties);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetJobNamedProperty(HANDLE hPrinter, uint32 JobId, PrintNamedProperty* pProperty);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeleteJobNamedProperty(HANDLE hPrinter, uint32 JobId, PWSTR pszName);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumJobNamedProperties(HANDLE hPrinter, uint32 JobId, uint32* pcProperties, PrintNamedProperty** ppProperties);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetPrintOutputInfo(HWND hWnd, PWSTR pszPrinter, HANDLE* phFile, PWSTR* ppszOutputFile);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DevQueryPrintEx(DEVQUERYPRINT_INFO* pDQPInfo);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterForPrintAsyncNotifications(PWSTR pszName, Guid* pNotificationType, PrintAsyncNotifyUserFilter eUserFilter, PrintAsyncNotifyConversationStyle eConversationStyle, IPrintAsyncNotifyCallback* pCallback, HANDLE* phNotify);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnRegisterForPrintAsyncNotifications(HANDLE param0);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreatePrintAsyncNotifyChannel(PWSTR pszName, Guid* pNotificationType, PrintAsyncNotifyUserFilter eUserFilter, PrintAsyncNotifyConversationStyle eConversationStyle, IPrintAsyncNotifyCallback* pCallback, IPrintAsyncNotifyChannel** ppIAsynchNotification);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GdiGetSpoolFileHandle(PWSTR pwszPrinterName, DEVMODEW* pDevmode, PWSTR pwszDocName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiDeleteSpoolFileHandle(HANDLE SpoolFileHandle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GdiGetPageCount(HANDLE SpoolFileHandle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC GdiGetDC(HANDLE SpoolFileHandle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GdiGetPageHandle(HANDLE SpoolFileHandle, uint32 Page, uint32* pdwPageType);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiStartDocEMF(HANDLE SpoolFileHandle, DOCINFOW* pDocInfo);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiStartPageEMF(HANDLE SpoolFileHandle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiPlayPageEMF(HANDLE SpoolFileHandle, HANDLE hemf, RECT* prectDocument, RECT* prectBorder, RECT* prectClip);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiEndPageEMF(HANDLE SpoolFileHandle, uint32 dwOptimization);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiEndDocEMF(HANDLE SpoolFileHandle);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiGetDevmodeForPage(HANDLE SpoolFileHandle, uint32 dwPageNumber, DEVMODEW** pCurrDM, DEVMODEW** pLastDM);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GdiResetDCEMF(HANDLE SpoolFileHandle, DEVMODEW* pCurrDM);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetJobAttributes(PWSTR pPrinterName, DEVMODEW* pDevmode, ATTRIBUTE_INFO_3* pAttributeInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetJobAttributesEx(PWSTR pPrinterName, DEVMODEW* pDevmode, uint32 dwLevel, uint8* pAttributeInfo, uint32 nSize, uint32 dwFlags);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreatePrinterIC(HANDLE hPrinter, DEVMODEW* pDevMode);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PlayGdiScriptOnPrinterIC(HANDLE hPrinterIC, uint8* pIn, uint32 cIn, uint8* pOut, uint32 cOut, uint32 ul);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeletePrinterIC(HANDLE hPrinterIC);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DevQueryPrint(HANDLE hPrinter, DEVMODEA* pDevMode, uint32* pResID);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE RevertToPrinterSelf();

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImpersonatePrinterClient(HANDLE hToken);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReplyPrinterChangeNotification(HANDLE hPrinter, uint32 fdwChangeFlags, uint32* pdwResult, void* pPrinterNotifyInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReplyPrinterChangeNotificationEx(HANDLE hNotify, uint32 dwColor, uint32 fdwFlags, uint32* pdwResult, void* pPrinterNotifyInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PartialReplyPrinterChangeNotification(HANDLE hPrinter, PRINTER_NOTIFY_INFO_DATA* pDataSrc);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PRINTER_NOTIFY_INFO* RouterAllocPrinterNotifyInfo(uint32 cPrinterNotifyInfoData);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RouterFreePrinterNotifyInfo(PRINTER_NOTIFY_INFO* pInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BIDI_RESPONSE_CONTAINER* RouterAllocBidiResponseContainer(uint32 Count);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* RouterAllocBidiMem(uint NumBytes);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RouterFreeBidiResponseContainer(BIDI_RESPONSE_CONTAINER* pData);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterFreeBidiMem(void* pMemPointer);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AppendPrinterNotifyInfoData(PRINTER_NOTIFY_INFO* pInfoDest, PRINTER_NOTIFY_INFO_DATA* pDataSrc, uint32 fdwFlags);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CallRouterFindFirstPrinterChangeNotification(HANDLE hPrinterRPC, uint32 fdwFilterFlags, uint32 fdwOptions, HANDLE hNotify, PRINTER_NOTIFY_OPTIONS* pPrinterNotifyOptions);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ProvidorFindFirstPrinterChangeNotification(HANDLE hPrinter, uint32 fdwFlags, uint32 fdwOptions, HANDLE hNotify, void* pPrinterNotifyOptions, void* pvReserved1);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ProvidorFindClosePrinterChangeNotification(HANDLE hPrinter);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SpoolerFindFirstPrinterChangeNotification(HANDLE hPrinter, uint32 fdwFilterFlags, uint32 fdwOptions, void* pPrinterNotifyOptions, void* pvReserved, void* pNotificationConfig, HANDLE* phNotify, HANDLE* phEvent);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SpoolerFindNextPrinterChangeNotification(HANDLE hPrinter, uint32* pfdwChange, void* pPrinterNotifyOptions, void** ppPrinterNotifyInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SpoolerRefreshPrinterChangeNotification(HANDLE hPrinter, uint32 dwColor, PRINTER_NOTIFY_OPTIONS* pOptions, PRINTER_NOTIFY_INFO** ppInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SpoolerFreePrinterNotifyInfo(PRINTER_NOTIFY_INFO* pInfo);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SpoolerFindClosePrinterChangeNotification(HANDLE hPrinter);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SpoolerCopyFileEvent(PWSTR pszPrinterName, PWSTR pszKey, uint32 dwCopyFileEvent);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GenerateCopyFilePaths(PWSTR pszPrinterName, PWSTR pszDirectory, uint8* pSplClientInfo, uint32 dwLevel, char16* pszSourceDir, uint32* pcchSourceDirSize, char16* pszTargetDir, uint32* pcchTargetDirSize, uint32 dwFlags);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SplPromptUIInUsersSession(HANDLE hPrinter, uint32 JobId, SHOWUIPARAMS* pUIParams, uint32* pResponse);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SplIsSessionZero(HANDLE hPrinter, uint32 JobId, BOOL* pIsSessionZero);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddPrintDeviceObject(HANDLE hPrinter, HANDLE* phDeviceObject);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UpdatePrintDeviceObject(HANDLE hPrinter, HANDLE hDeviceObject);

	[Import("SPOOLSS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RemovePrintDeviceObject(HANDLE hDeviceObject);

}
#endregion
