using Win32.Security;
using Win32.Foundation;
using Win32.Graphics.Gdi;
using System;

namespace Win32.System.DataExchange;

#region Constants
public static
{
	public const uint32 WM_DDE_FIRST = 992;
	public const uint32 WM_DDE_INITIATE = 992;
	public const uint32 WM_DDE_TERMINATE = 993;
	public const uint32 WM_DDE_ADVISE = 994;
	public const uint32 WM_DDE_UNADVISE = 995;
	public const uint32 WM_DDE_ACK = 996;
	public const uint32 WM_DDE_DATA = 997;
	public const uint32 WM_DDE_REQUEST = 998;
	public const uint32 WM_DDE_POKE = 999;
	public const uint32 WM_DDE_EXECUTE = 1000;
	public const uint32 WM_DDE_LAST = 1000;
	public const uint32 CADV_LATEACK = 65535;
	public const uint32 DDE_FACK = 32768;
	public const uint32 DDE_FBUSY = 16384;
	public const uint32 DDE_FDEFERUPD = 16384;
	public const uint32 DDE_FACKREQ = 32768;
	public const uint32 DDE_FRELEASE = 8192;
	public const uint32 DDE_FREQUESTED = 4096;
	public const uint32 DDE_FAPPSTATUS = 255;
	public const uint32 DDE_FNOTPROCESSED = 0;
	public const uint32 MSGF_DDEMGR = 32769;
	public const int32 CP_WINANSI = 1004;
	public const int32 CP_WINUNICODE = 1200;
	public const int32 CP_WINNEUTRAL = 1200;
	public const uint32 XTYPF_NOBLOCK = 2;
	public const uint32 XTYPF_NODATA = 4;
	public const uint32 XTYPF_ACKREQ = 8;
	public const uint32 XCLASS_MASK = 64512;
	public const uint32 XCLASS_BOOL = 4096;
	public const uint32 XCLASS_DATA = 8192;
	public const uint32 XCLASS_FLAGS = 16384;
	public const uint32 XCLASS_NOTIFICATION = 32768;
	public const uint32 XTYP_MASK = 240;
	public const uint32 XTYP_SHIFT = 4;
	public const uint32 TIMEOUT_ASYNC = 4294967295;
	public const uint32 QID_SYNC = 4294967295;
	public const String SZDDESYS_TOPIC = "System";
	public const String SZDDESYS_ITEM_TOPICS = "Topics";
	public const String SZDDESYS_ITEM_SYSITEMS = "SysItems";
	public const String SZDDESYS_ITEM_RTNMSG = "ReturnMessage";
	public const String SZDDESYS_ITEM_STATUS = "Status";
	public const String SZDDESYS_ITEM_FORMATS = "Formats";
	public const String SZDDESYS_ITEM_HELP = "Help";
	public const String SZDDE_ITEM_ITEMLIST = "TopicItemList";
	public const int32 APPCMD_MASK = 4080;
	public const int32 APPCLASS_MASK = 15;
	public const uint32 HDATA_APPOWNED = 1;
	public const uint32 DMLERR_NO_ERROR = 0;
	public const uint32 DMLERR_FIRST = 16384;
	public const uint32 DMLERR_ADVACKTIMEOUT = 16384;
	public const uint32 DMLERR_BUSY = 16385;
	public const uint32 DMLERR_DATAACKTIMEOUT = 16386;
	public const uint32 DMLERR_DLL_NOT_INITIALIZED = 16387;
	public const uint32 DMLERR_DLL_USAGE = 16388;
	public const uint32 DMLERR_EXECACKTIMEOUT = 16389;
	public const uint32 DMLERR_INVALIDPARAMETER = 16390;
	public const uint32 DMLERR_LOW_MEMORY = 16391;
	public const uint32 DMLERR_MEMORY_ERROR = 16392;
	public const uint32 DMLERR_NOTPROCESSED = 16393;
	public const uint32 DMLERR_NO_CONV_ESTABLISHED = 16394;
	public const uint32 DMLERR_POKEACKTIMEOUT = 16395;
	public const uint32 DMLERR_POSTMSG_FAILED = 16396;
	public const uint32 DMLERR_REENTRANCY = 16397;
	public const uint32 DMLERR_SERVER_DIED = 16398;
	public const uint32 DMLERR_SYS_ERROR = 16399;
	public const uint32 DMLERR_UNADVACKTIMEOUT = 16400;
	public const uint32 DMLERR_UNFOUND_QUEUE_ID = 16401;
	public const uint32 DMLERR_LAST = 16401;
	public const uint32 MH_CREATE = 1;
	public const uint32 MH_KEEP = 2;
	public const uint32 MH_DELETE = 3;
	public const uint32 MH_CLEANUP = 4;
	public const uint32 MAX_MONITORS = 4;
	public const uint32 MF_MASK = 4278190080;
}
#endregion

#region TypeDefs
typealias HSZ = int;

typealias HCONV = int;

typealias HCONVLIST = int;

typealias HDDEDATA = int;

#endregion


#region Enums

[AllowDuplicates]
public enum DDE_ENABLE_CALLBACK_CMD : uint32
{
	EC_ENABLEALL = 0,
	EC_ENABLEONE = 128,
	EC_DISABLE = 8,
	EC_QUERYWAITING = 2,
}


[AllowDuplicates]
public enum DDE_INITIALIZE_COMMAND : uint32
{
	APPCLASS_MONITOR = 1,
	APPCLASS_STANDARD = 0,
	APPCMD_CLIENTONLY = 16,
	APPCMD_FILTERINITS = 32,
	CBF_FAIL_ALLSVRXACTIONS = 258048,
	CBF_FAIL_ADVISES = 16384,
	CBF_FAIL_CONNECTIONS = 8192,
	CBF_FAIL_EXECUTES = 32768,
	CBF_FAIL_POKES = 65536,
	CBF_FAIL_REQUESTS = 131072,
	CBF_FAIL_SELFCONNECTIONS = 4096,
	CBF_SKIP_ALLNOTIFICATIONS = 3932160,
	CBF_SKIP_CONNECT_CONFIRMS = 262144,
	CBF_SKIP_DISCONNECTS = 2097152,
	CBF_SKIP_REGISTRATIONS = 524288,
	CBF_SKIP_UNREGISTRATIONS = 1048576,
	MF_CALLBACKS = 134217728,
	MF_CONV = 1073741824,
	MF_ERRORS = 268435456,
	MF_HSZ_INFO = 16777216,
	MF_LINKS = 536870912,
	MF_POSTMSGS = 67108864,
	MF_SENDMSGS = 33554432,
}


[AllowDuplicates]
public enum DDE_NAME_SERVICE_CMD : uint32
{
	DNS_REGISTER = 1,
	DNS_UNREGISTER = 2,
	DNS_FILTERON = 4,
	DNS_FILTEROFF = 8,
}


[AllowDuplicates]
public enum DDE_CLIENT_TRANSACTION_TYPE : uint32
{
	XTYP_ADVSTART = 4144,
	XTYP_ADVSTOP = 32832,
	XTYP_EXECUTE = 16464,
	XTYP_POKE = 16528,
	XTYP_REQUEST = 8368,
	XTYP_ADVDATA = 16400,
	XTYP_ADVREQ = 8226,
	XTYP_CONNECT = 4194,
	XTYP_CONNECT_CONFIRM = 32882,
	XTYP_DISCONNECT = 32962,
	XTYP_MONITOR = 33010,
	XTYP_REGISTER = 32930,
	XTYP_UNREGISTER = 32978,
	XTYP_WILDCONNECT = 8418,
	XTYP_XACT_COMPLETE = 32896,
}


[AllowDuplicates]
public enum CONVINFO_CONVERSATION_STATE : uint32
{
	XST_ADVACKRCVD = 13,
	XST_ADVDATAACKRCVD = 16,
	XST_ADVDATASENT = 15,
	XST_ADVSENT = 11,
	XST_CONNECTED = 2,
	XST_DATARCVD = 6,
	XST_EXECACKRCVD = 10,
	XST_EXECSENT = 9,
	XST_INCOMPLETE = 1,
	XST_INIT1 = 3,
	XST_INIT2 = 4,
	XST_NULL = 0,
	XST_POKEACKRCVD = 8,
	XST_POKESENT = 7,
	XST_REQSENT = 5,
	XST_UNADVACKRCVD = 14,
	XST_UNADVSENT = 12,
}


[AllowDuplicates]
public enum CONVINFO_STATUS : uint32
{
	ST_ADVISE = 2,
	ST_BLOCKED = 8,
	ST_BLOCKNEXT = 128,
	ST_CLIENT = 16,
	ST_CONNECTED = 1,
	ST_INLIST = 64,
	ST_ISLOCAL = 4,
	ST_ISSELF = 256,
	ST_TERMINATED = 32,
}

#endregion

#region Function Pointers
public function HDDEDATA PFNCALLBACK(uint32 wType, uint32 wFmt, HCONV hConv, HSZ hsz1, HSZ hsz2, HDDEDATA hData, uint dwData1, uint dwData2);

#endregion

#region Structs
[CRepr]
public struct DDEACK
{
	public uint16 _bitfield;
}

[CRepr]
public struct DDEADVISE
{
	public uint16 _bitfield;
	public int16 cfFormat;
}

[CRepr]
public struct DDEDATA
{
	public uint16 _bitfield;
	public int16 cfFormat;
	public uint8* Value mut => &Value_impl;
	private uint8[ANYSIZE_ARRAY] Value_impl;
}

[CRepr]
public struct DDEPOKE
{
	public uint16 _bitfield;
	public int16 cfFormat;
	public uint8* Value mut => &Value_impl;
	private uint8[ANYSIZE_ARRAY] Value_impl;
}

[CRepr]
public struct DDELN
{
	public uint16 _bitfield;
	public int16 cfFormat;
}

[CRepr]
public struct DDEUP
{
	public uint16 _bitfield;
	public int16 cfFormat;
	public uint8* rgb mut => &rgb_impl;
	private uint8[ANYSIZE_ARRAY] rgb_impl;
}

[CRepr]
public struct HSZPAIR
{
	public HSZ hszSvc;
	public HSZ hszTopic;
}

[CRepr]
public struct CONVCONTEXT
{
	public uint32 cb;
	public uint32 wFlags;
	public uint32 wCountryID;
	public int32 iCodePage;
	public uint32 dwLangID;
	public uint32 dwSecurity;
	public SECURITY_QUALITY_OF_SERVICE qos;
}

[CRepr]
public struct CONVINFO
{
	public uint32 cb;
	public uint hUser;
	public HCONV hConvPartner;
	public HSZ hszSvcPartner;
	public HSZ hszServiceReq;
	public HSZ hszTopic;
	public HSZ hszItem;
	public uint32 wFmt;
	public DDE_CLIENT_TRANSACTION_TYPE wType;
	public CONVINFO_STATUS wStatus;
	public CONVINFO_CONVERSATION_STATE wConvst;
	public uint32 wLastError;
	public HCONVLIST hConvList;
	public CONVCONTEXT ConvCtxt;
	public HWND hwnd;
	public HWND hwndPartner;
}

[CRepr]
public struct DDEML_MSG_HOOK_DATA
{
	public uint uiLo;
	public uint uiHi;
	public uint32 cbData;
	public uint32[8] Data;
}

[CRepr]
public struct MONMSGSTRUCT
{
	public uint32 cb;
	public HWND hwndTo;
	public uint32 dwTime;
	public HANDLE hTask;
	public uint32 wMsg;
	public WPARAM wParam;
	public LPARAM lParam;
	public DDEML_MSG_HOOK_DATA dmhd;
}

[CRepr]
public struct MONCBSTRUCT
{
	public uint32 cb;
	public uint32 dwTime;
	public HANDLE hTask;
	public uint32 dwRet;
	public uint32 wType;
	public uint32 wFmt;
	public HCONV hConv;
	public HSZ hsz1;
	public HSZ hsz2;
	public HDDEDATA hData;
	public uint dwData1;
	public uint dwData2;
	public CONVCONTEXT cc;
	public uint32 cbData;
	public uint32[8] Data;
}

[CRepr]
public struct MONHSZSTRUCTA
{
	public uint32 cb;
	public BOOL fsAction;
	public uint32 dwTime;
	public HSZ hsz;
	public HANDLE hTask;
	public CHAR* str mut => &str_impl;
	private CHAR[ANYSIZE_ARRAY] str_impl;
}

[CRepr]
public struct MONHSZSTRUCTW
{
	public uint32 cb;
	public BOOL fsAction;
	public uint32 dwTime;
	public HSZ hsz;
	public HANDLE hTask;
	public char16* str mut => &str_impl;
	private char16[ANYSIZE_ARRAY] str_impl;
}

[CRepr]
public struct MONERRSTRUCT
{
	public uint32 cb;
	public uint32 wLastError;
	public uint32 dwTime;
	public HANDLE hTask;
}

[CRepr]
public struct MONLINKSTRUCT
{
	public uint32 cb;
	public uint32 dwTime;
	public HANDLE hTask;
	public BOOL fEstablished;
	public BOOL fNoData;
	public HSZ hszSvc;
	public HSZ hszTopic;
	public HSZ hszItem;
	public uint32 wFmt;
	public BOOL fServer;
	public HCONV hConvServer;
	public HCONV hConvClient;
}

[CRepr]
public struct MONCONVSTRUCT
{
	public uint32 cb;
	public BOOL fConnect;
	public uint32 dwTime;
	public HANDLE hTask;
	public HSZ hszSvc;
	public HSZ hszTopic;
	public HCONV hConvClient;
	public HCONV hConvServer;
}

[CRepr]
public struct METAFILEPICT
{
	public int32 mm;
	public int32 xExt;
	public int32 yExt;
	public HMETAFILE hMF;
}

[CRepr]
public struct COPYDATASTRUCT
{
	public uint dwData;
	public uint32 cbData;
	public void* lpData;
}

#endregion

#region Functions
public static
{
	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeSetQualityOfService(HWND hwndClient, SECURITY_QUALITY_OF_SERVICE* pqosNew, SECURITY_QUALITY_OF_SERVICE* pqosPrev);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImpersonateDdeClientWindow(HWND hWndClient, HWND hWndServer);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LPARAM PackDDElParam(uint32 msg, uint uiLo, uint uiHi);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnpackDDElParam(uint32 msg, LPARAM lParam, uint* puiLo, uint* puiHi);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeDDElParam(uint32 msg, LPARAM lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LPARAM ReuseDDElParam(LPARAM lParam, uint32 msgIn, uint32 msgOut, uint uiLo, uint uiHi);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeInitializeA(uint32* pidInst, PFNCALLBACK pfnCallback, DDE_INITIALIZE_COMMAND afCmd, uint32 ulRes);
	public static uint32 DdeInitialize(uint32* pidInst, PFNCALLBACK pfnCallback, DDE_INITIALIZE_COMMAND afCmd, uint32 ulRes) => DdeInitializeA(pidInst, pfnCallback, afCmd, ulRes);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeInitializeW(uint32* pidInst, PFNCALLBACK pfnCallback, DDE_INITIALIZE_COMMAND afCmd, uint32 ulRes);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeUninitialize(uint32 idInst);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCONVLIST DdeConnectList(uint32 idInst, HSZ hszService, HSZ hszTopic, HCONVLIST hConvList, CONVCONTEXT* pCC);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCONV DdeQueryNextServer(HCONVLIST hConvList, HCONV hConvPrev);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeDisconnectList(HCONVLIST hConvList);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCONV DdeConnect(uint32 idInst, HSZ hszService, HSZ hszTopic, CONVCONTEXT* pCC);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeDisconnect(HCONV hConv);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCONV DdeReconnect(HCONV hConv);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeQueryConvInfo(HCONV hConv, uint32 idTransaction, CONVINFO* pConvInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeSetUserHandle(HCONV hConv, uint32 id, uint hUser);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeAbandonTransaction(uint32 idInst, HCONV hConv, uint32 idTransaction);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdePostAdvise(uint32 idInst, HSZ hszTopic, HSZ hszItem);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeEnableCallback(uint32 idInst, HCONV hConv, DDE_ENABLE_CALLBACK_CMD wCmd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeImpersonateClient(HCONV hConv);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDDEDATA DdeNameService(uint32 idInst, HSZ hsz1, HSZ hsz2, DDE_NAME_SERVICE_CMD afCmd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDDEDATA DdeClientTransaction(uint8* pData, uint32 cbData, HCONV hConv, HSZ hszItem, uint32 wFmt, DDE_CLIENT_TRANSACTION_TYPE wType, uint32 dwTimeout, uint32* pdwResult);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDDEDATA DdeCreateDataHandle(uint32 idInst, uint8* pSrc, uint32 cb, uint32 cbOff, HSZ hszItem, uint32 wFmt, uint32 afCmd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDDEDATA DdeAddData(HDDEDATA hData, uint8* pSrc, uint32 cb, uint32 cbOff);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeGetData(HDDEDATA hData, uint8* pDst, uint32 cbMax, uint32 cbOff);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* DdeAccessData(HDDEDATA hData, uint32* pcbDataSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeUnaccessData(HDDEDATA hData);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeFreeDataHandle(HDDEDATA hData);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeGetLastError(uint32 idInst);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HSZ DdeCreateStringHandleA(uint32 idInst, PSTR psz, int32 iCodePage);
	public static HSZ DdeCreateStringHandle(uint32 idInst, PSTR psz, int32 iCodePage) => DdeCreateStringHandleA(idInst, psz, iCodePage);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HSZ DdeCreateStringHandleW(uint32 idInst, PWSTR psz, int32 iCodePage);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeQueryStringA(uint32 idInst, HSZ hsz, uint8* psz, uint32 cchMax, int32 iCodePage);
	public static uint32 DdeQueryString(uint32 idInst, HSZ hsz, uint8* psz, uint32 cchMax, int32 iCodePage) => DdeQueryStringA(idInst, hsz, psz, cchMax, iCodePage);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DdeQueryStringW(uint32 idInst, HSZ hsz, char16* psz, uint32 cchMax, int32 iCodePage);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeFreeStringHandle(uint32 idInst, HSZ hsz);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DdeKeepStringHandle(uint32 idInst, HSZ hsz);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DdeCmpStringHandles(HSZ hsz1, HSZ hsz2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HENHMETAFILE SetWinMetaFileBits(uint32 nSize, uint8* lpMeta16Data, HDC hdcRef, METAFILEPICT* lpMFP);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenClipboard(HWND hWndNewOwner);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClipboard();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClipboardSequenceNumber();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetClipboardOwner();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND SetClipboardViewer(HWND hWndNewViewer);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetClipboardViewer();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChangeClipboardChain(HWND hWndRemove, HWND hWndNewNext);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE SetClipboardData(uint32 uFormat, HANDLE hMem);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GetClipboardData(uint32 uFormat);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterClipboardFormatA(PSTR lpszFormat);
	public static uint32 RegisterClipboardFormat(PSTR lpszFormat) => RegisterClipboardFormatA(lpszFormat);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterClipboardFormatW(PWSTR lpszFormat);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CountClipboardFormats();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumClipboardFormats(uint32 format);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetClipboardFormatNameA(uint32 format, uint8* lpszFormatName, int32 cchMaxCount);
	public static int32 GetClipboardFormatName(uint32 format, uint8* lpszFormatName, int32 cchMaxCount) => GetClipboardFormatNameA(format, lpszFormatName, cchMaxCount);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetClipboardFormatNameW(uint32 format, char16* lpszFormatName, int32 cchMaxCount);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EmptyClipboard();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsClipboardFormatAvailable(uint32 format);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetPriorityClipboardFormat(uint32* paFormatPriorityList, int32 cFormats);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetOpenClipboardWindow();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddClipboardFormatListener(HWND hwnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveClipboardFormatListener(HWND hwnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUpdatedClipboardFormats(uint32* lpuiFormats, uint32 cFormats, uint32* pcFormatsOut);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalDeleteAtom(uint16 nAtom);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitAtomTable(uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 DeleteAtom(uint16 nAtom);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalAddAtomA(PSTR lpString);
	public static uint16 GlobalAddAtom(PSTR lpString) => GlobalAddAtomA(lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalAddAtomW(PWSTR lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalAddAtomExA(PSTR lpString, uint32 Flags);
	public static uint16 GlobalAddAtomEx(PSTR lpString, uint32 Flags) => GlobalAddAtomExA(lpString, Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalAddAtomExW(PWSTR lpString, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalFindAtomA(PSTR lpString);
	public static uint16 GlobalFindAtom(PSTR lpString) => GlobalFindAtomA(lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GlobalFindAtomW(PWSTR lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GlobalGetAtomNameA(uint16 nAtom, uint8* lpBuffer, int32 nSize);
	public static uint32 GlobalGetAtomName(uint16 nAtom, uint8* lpBuffer, int32 nSize) => GlobalGetAtomNameA(nAtom, lpBuffer, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GlobalGetAtomNameW(uint16 nAtom, char16* lpBuffer, int32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 AddAtomA(PSTR lpString);
	public static uint16 AddAtom(PSTR lpString) => AddAtomA(lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 AddAtomW(PWSTR lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 FindAtomA(PSTR lpString);
	public static uint16 FindAtom(PSTR lpString) => FindAtomA(lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 FindAtomW(PWSTR lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetAtomNameA(uint16 nAtom, uint8* lpBuffer, int32 nSize);
	public static uint32 GetAtomName(uint16 nAtom, uint8* lpBuffer, int32 nSize) => GetAtomNameA(nAtom, lpBuffer, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetAtomNameW(uint16 nAtom, char16* lpBuffer, int32 nSize);

}
#endregion
