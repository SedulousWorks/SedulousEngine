using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.WNet;

#region Constants
public static
{
	public const uint32 WNGETCON_CONNECTED = 0;
	public const uint32 WNGETCON_DISCONNECTED = 1;
	public const uint32 WNNC_SPEC_VERSION = 1;
	public const uint32 WNNC_SPEC_VERSION51 = 327681;
	public const uint32 WNNC_NET_TYPE = 2;
	public const uint32 WNNC_NET_NONE = 0;
	public const uint32 WNNC_DRIVER_VERSION = 3;
	public const uint32 WNNC_USER = 4;
	public const uint32 WNNC_USR_GETUSER = 1;
	public const uint32 WNNC_CONNECTION = 6;
	public const uint32 WNNC_CON_ADDCONNECTION = 1;
	public const uint32 WNNC_CON_CANCELCONNECTION = 2;
	public const uint32 WNNC_CON_GETCONNECTIONS = 4;
	public const uint32 WNNC_CON_ADDCONNECTION3 = 8;
	public const uint32 WNNC_CON_ADDCONNECTION4 = 16;
	public const uint32 WNNC_CON_CANCELCONNECTION2 = 32;
	public const uint32 WNNC_CON_GETPERFORMANCE = 64;
	public const uint32 WNNC_CON_DEFER = 128;
	public const uint32 WNNC_DIALOG = 8;
	public const uint32 WNNC_DLG_DEVICEMODE = 1;
	public const uint32 WNNC_DLG_PROPERTYDIALOG = 32;
	public const uint32 WNNC_DLG_SEARCHDIALOG = 64;
	public const uint32 WNNC_DLG_FORMATNETWORKNAME = 128;
	public const uint32 WNNC_DLG_PERMISSIONEDITOR = 256;
	public const uint32 WNNC_DLG_GETRESOURCEPARENT = 512;
	public const uint32 WNNC_DLG_GETRESOURCEINFORMATION = 2048;
	public const uint32 WNNC_ADMIN = 9;
	public const uint32 WNNC_ADM_GETDIRECTORYTYPE = 1;
	public const uint32 WNNC_ADM_DIRECTORYNOTIFY = 2;
	public const uint32 WNNC_ENUMERATION = 11;
	public const uint32 WNNC_ENUM_GLOBAL = 1;
	public const uint32 WNNC_ENUM_LOCAL = 2;
	public const uint32 WNNC_ENUM_CONTEXT = 4;
	public const uint32 WNNC_ENUM_SHAREABLE = 8;
	public const uint32 WNNC_START = 12;
	public const uint32 WNNC_WAIT_FOR_START = 1;
	public const uint32 WNNC_CONNECTION_FLAGS = 13;
	public const uint32 WNTYPE_DRIVE = 1;
	public const uint32 WNTYPE_FILE = 2;
	public const uint32 WNTYPE_PRINTER = 3;
	public const uint32 WNTYPE_COMM = 4;
	public const uint32 WNSRCH_REFRESH_FIRST_LEVEL = 1;
	public const uint32 WNDT_NORMAL = 0;
	public const uint32 WNDT_NETWORK = 1;
	public const uint32 WN_NETWORK_CLASS = 1;
	public const uint32 WN_CREDENTIAL_CLASS = 2;
	public const uint32 WN_PRIMARY_AUTHENT_CLASS = 4;
	public const uint32 WN_SERVICE_CLASS = 8;
	public const uint32 WN_VALID_LOGON_ACCOUNT = 1;
	public const uint32 WN_NT_PASSWORD_CHANGED = 2;
	public const uint32 NOTIFY_PRE = 1;
	public const uint32 NOTIFY_POST = 2;
	public const uint32 WNPERMC_PERM = 1;
	public const uint32 WNPERMC_AUDIT = 2;
	public const uint32 WNPERMC_OWNER = 4;
	public const uint32 RESOURCE_RECENT = 4;
	public const uint32 RESOURCETYPE_RESERVED = 8;
	public const uint32 RESOURCETYPE_UNKNOWN = 4294967295;
	public const uint32 RESOURCEUSAGE_NOLOCALDEVICE = 4;
	public const uint32 RESOURCEUSAGE_SIBLING = 8;
	public const uint32 RESOURCEUSAGE_RESERVED = 2147483648;
	public const uint32 RESOURCEDISPLAYTYPE_NETWORK = 6;
	public const uint32 RESOURCEDISPLAYTYPE_ROOT = 7;
	public const uint32 RESOURCEDISPLAYTYPE_SHAREADMIN = 8;
	public const uint32 RESOURCEDISPLAYTYPE_DIRECTORY = 9;
	public const uint32 RESOURCEDISPLAYTYPE_NDSCONTAINER = 11;
	public const uint32 NETPROPERTY_PERSISTENT = 1;
	public const uint32 CONNECT_NEED_DRIVE = 32;
	public const uint32 CONNECT_REFCOUNT = 64;
	public const uint32 CONNECT_LOCALDRIVE = 256;
	public const uint32 CONNECT_CURRENT_MEDIA = 512;
	public const uint32 CONNECT_RESERVED = 4278190080;
	public const uint32 CONNECT_CRED_RESET = 8192;
	public const uint32 CONNECT_REQUIRE_INTEGRITY = 16384;
	public const uint32 CONNECT_REQUIRE_PRIVACY = 32768;
	public const uint32 CONNECT_WRITE_THROUGH_SEMANTICS = 65536;
	public const uint32 CONNECT_GLOBAL_MAPPING = 262144;
	public const uint32 WNFMT_INENUM = 16;
	public const uint32 WNFMT_CONNECTION = 32;
	public const uint32 WNCON_FORNETCARD = 1;
	public const uint32 WNCON_NOTROUTED = 2;
	public const uint32 WNCON_SLOWLINK = 4;
	public const uint32 WNCON_DYNAMIC = 8;
}
#endregion

#region TypeDefs
typealias NetEnumHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum UNC_INFO_LEVEL : uint32
{
	UNIVERSAL_NAME_INFO_LEVEL = 1,
	REMOTE_NAME_INFO_LEVEL = 2,
}


[AllowDuplicates]
public enum WNPERM_DLG : uint32
{
	WNPERM_DLG_PERM = 0,
	WNPERM_DLG_AUDIT = 1,
	WNPERM_DLG_OWNER = 2,
}


[AllowDuplicates]
public enum WNET_OPEN_ENUM_USAGE : uint32
{
	RESOURCEUSAGE_NONE = 0,
	RESOURCEUSAGE_CONNECTABLE = 1,
	RESOURCEUSAGE_CONTAINER = 2,
	RESOURCEUSAGE_ATTACHED = 16,
	RESOURCEUSAGE_ALL = 19,
}


[AllowDuplicates]
public enum NET_USE_CONNECT_FLAGS : uint32
{
	CONNECT_INTERACTIVE = 8,
	CONNECT_PROMPT = 16,
	CONNECT_REDIRECT = 128,
	CONNECT_UPDATE_PROFILE = 1,
	CONNECT_COMMANDLINE = 2048,
	CONNECT_CMD_SAVECRED = 4096,
	CONNECT_TEMPORARY = 4,
	CONNECT_DEFERRED = 1024,
	CONNECT_UPDATE_RECENT = 2,
}


[AllowDuplicates]
public enum NP_PROPERTY_DIALOG_SELECTION : uint32
{
	WNPS_FILE = 0,
	WNPS_DIR = 1,
	WNPS_MULT = 2,
}


[AllowDuplicates]
public enum NPDIRECTORY_NOTIFY_OPERATION : uint32
{
	WNDN_MKDIR = 1,
	WNDN_RMDIR = 2,
	WNDN_MVDIR = 3,
}


[AllowDuplicates]
public enum NET_RESOURCE_TYPE : uint32
{
	RESOURCETYPE_ANY = 0,
	RESOURCETYPE_DISK = 1,
	RESOURCETYPE_PRINT = 2,
}


[AllowDuplicates]
public enum NETWORK_NAME_FORMAT_FLAGS : uint32
{
	WNFMT_MULTILINE = 1,
	WNFMT_ABBREVIATED = 2,
}


[AllowDuplicates]
public enum NET_RESOURCE_SCOPE : uint32
{
	RESOURCE_CONNECTED = 1,
	RESOURCE_CONTEXT = 5,
	RESOURCE_GLOBALNET = 2,
	RESOURCE_REMEMBERED = 3,
}


[AllowDuplicates]
public enum NETINFOSTRUCT_CHARACTERISTICS : uint32
{
	NETINFO_DLL16 = 1,
	NETINFO_DISKRED = 4,
	NETINFO_PRINTERRED = 8,
}


[AllowDuplicates]
public enum CONNECTDLGSTRUCT_FLAGS : uint32
{
	CONNDLG_RO_PATH = 1,
	CONNDLG_CONN_POINT = 2,
	CONNDLG_USE_MRU = 4,
	CONNDLG_HIDE_BOX = 8,
	CONNDLG_PERSIST = 16,
	CONNDLG_NOT_PERSIST = 32,
}


[AllowDuplicates]
public enum DISCDLGSTRUCT_FLAGS : uint32
{
	DISC_UPDATE_PROFILE = 1,
	DISC_NO_FORCE = 64,
}

#endregion

#region Function Pointers
public function uint32 PF_NPAddConnection(NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserName);

public function uint32 PF_NPAddConnection3(HWND hwndOwner, NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserName, uint32 dwFlags);

public function uint32 PF_NPAddConnection4(HWND hwndOwner, NETRESOURCEW* lpNetResource, void* lpAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions);

public function uint32 PF_NPCancelConnection(PWSTR lpName, BOOL fForce);

public function uint32 PF_NPCancelConnection2(PWSTR lpName, BOOL fForce, uint32 dwFlags);

public function uint32 PF_NPGetConnection(PWSTR lpLocalName, char16* lpRemoteName, uint32* lpnBufferLen);

public function uint32 PF_NPGetConnection3(PWSTR lpLocalName, uint32 dwLevel, void* lpBuffer, uint32* lpBufferSize);

public function uint32 PF_NPGetUniversalName(PWSTR lpLocalPath, uint32 dwInfoLevel, void* lpBuffer, uint32* lpnBufferSize);

public function uint32 PF_NPGetConnectionPerformance(PWSTR lpRemoteName, NETCONNECTINFOSTRUCT* lpNetConnectInfo);

public function uint32 PF_NPOpenEnum(uint32 dwScope, uint32 dwType, uint32 dwUsage, NETRESOURCEW* lpNetResource, HANDLE* lphEnum);

public function uint32 PF_NPEnumResource(HANDLE hEnum, uint32* lpcCount, void* lpBuffer, uint32* lpBufferSize);

public function uint32 PF_NPCloseEnum(HANDLE hEnum);

public function uint32 PF_NPGetCaps(uint32 ndex);

public function uint32 PF_NPGetUser(PWSTR lpName, char16* lpUserName, uint32* lpnBufferLen);

public function uint32 PF_NPGetPersistentUseOptionsForConnection(PWSTR lpRemotePath, uint8* lpReadUseOptions, uint32 cbReadUseOptions, uint8* lpWriteUseOptions, uint32* lpSizeWriteUseOptions);

public function uint32 PF_NPDeviceMode(HWND hParent);

public function uint32 PF_NPSearchDialog(HWND hwndParent, NETRESOURCEW* lpNetResource, void* lpBuffer, uint32 cbBuffer, uint32* lpnFlags);

public function uint32 PF_NPGetResourceParent(NETRESOURCEW* lpNetResource, void* lpBuffer, uint32* lpBufferSize);

public function uint32 PF_NPGetResourceInformation(NETRESOURCEW* lpNetResource, void* lpBuffer, uint32* lpBufferSize, PWSTR* lplpSystem);

public function uint32 PF_NPFormatNetworkName(PWSTR lpRemoteName, char16* lpFormattedName, uint32* lpnLength, uint32 dwFlags, uint32 dwAveCharPerLine);

public function uint32 PF_NPGetPropertyText(uint32 iButton, uint32 nPropSel, PWSTR lpName, char16* lpButtonName, uint32 nButtonNameLen, uint32 nType);

public function uint32 PF_NPPropertyDialog(HWND hwndParent, uint32 iButtonDlg, uint32 nPropSel, PWSTR lpFileName, uint32 nType);

public function uint32 PF_NPGetDirectoryType(PWSTR lpName, int32* lpType, BOOL bFlushCache);

public function uint32 PF_NPDirectoryNotify(HWND hwnd, PWSTR lpDir, uint32 dwOper);

public function uint32 PF_NPLogonNotify(LUID* lpLogonId, PWSTR lpAuthentInfoType, void* lpAuthentInfo, PWSTR lpPreviousAuthentInfoType, void* lpPreviousAuthentInfo, PWSTR lpStationName, void* StationHandle, PWSTR* lpLogonScript);

public function uint32 PF_NPPasswordChangeNotify(PWSTR lpAuthentInfoType, void* lpAuthentInfo, PWSTR lpPreviousAuthentInfoType, void* lpPreviousAuthentInfo, PWSTR lpStationName, void* StationHandle, uint32 dwChangeInfo);

public function uint32 PF_AddConnectNotify(NOTIFYINFO* lpNotifyInfo, NOTIFYADD* lpAddInfo);

public function uint32 PF_CancelConnectNotify(NOTIFYINFO* lpNotifyInfo, NOTIFYCANCEL* lpCancelInfo);

public function uint32 PF_NPFMXGetPermCaps(PWSTR lpDriveName);

public function uint32 PF_NPFMXEditPerm(PWSTR lpDriveName, HWND hwndFMX, uint32 nDialogType);

public function uint32 PF_NPFMXGetPermHelp(PWSTR lpDriveName, uint32 nDialogType, BOOL fDirectory, void* lpFileNameBuffer, uint32* lpBufferSize, uint32* lpnHelpContext);

#endregion

#region Structs
[CRepr]
public struct NETRESOURCEA
{
	public NET_RESOURCE_SCOPE dwScope;
	public NET_RESOURCE_TYPE dwType;
	public uint32 dwDisplayType;
	public uint32 dwUsage;
	public PSTR lpLocalName;
	public PSTR lpRemoteName;
	public PSTR lpComment;
	public PSTR lpProvider;
}

[CRepr]
public struct NETRESOURCEW
{
	public NET_RESOURCE_SCOPE dwScope;
	public NET_RESOURCE_TYPE dwType;
	public uint32 dwDisplayType;
	public uint32 dwUsage;
	public PWSTR lpLocalName;
	public PWSTR lpRemoteName;
	public PWSTR lpComment;
	public PWSTR lpProvider;
}

[CRepr]
public struct CONNECTDLGSTRUCTA
{
	public uint32 cbStructure;
	public HWND hwndOwner;
	public NETRESOURCEA* lpConnRes;
	public CONNECTDLGSTRUCT_FLAGS dwFlags;
	public uint32 dwDevNum;
}

[CRepr]
public struct CONNECTDLGSTRUCTW
{
	public uint32 cbStructure;
	public HWND hwndOwner;
	public NETRESOURCEW* lpConnRes;
	public CONNECTDLGSTRUCT_FLAGS dwFlags;
	public uint32 dwDevNum;
}

[CRepr]
public struct DISCDLGSTRUCTA
{
	public uint32 cbStructure;
	public HWND hwndOwner;
	public PSTR lpLocalName;
	public PSTR lpRemoteName;
	public DISCDLGSTRUCT_FLAGS dwFlags;
}

[CRepr]
public struct DISCDLGSTRUCTW
{
	public uint32 cbStructure;
	public HWND hwndOwner;
	public PWSTR lpLocalName;
	public PWSTR lpRemoteName;
	public DISCDLGSTRUCT_FLAGS dwFlags;
}

[CRepr]
public struct UNIVERSAL_NAME_INFOA
{
	public PSTR lpUniversalName;
}

[CRepr]
public struct UNIVERSAL_NAME_INFOW
{
	public PWSTR lpUniversalName;
}

[CRepr]
public struct REMOTE_NAME_INFOA
{
	public PSTR lpUniversalName;
	public PSTR lpConnectionName;
	public PSTR lpRemainingPath;
}

[CRepr]
public struct REMOTE_NAME_INFOW
{
	public PWSTR lpUniversalName;
	public PWSTR lpConnectionName;
	public PWSTR lpRemainingPath;
}

[CRepr]
public struct NETINFOSTRUCT
{
	public uint32 cbStructure;
	public uint32 dwProviderVersion;
	public WIN32_ERROR dwStatus;
	public NETINFOSTRUCT_CHARACTERISTICS dwCharacteristics;
	public uint dwHandle;
	public uint16 wNetType;
	public uint32 dwPrinters;
	public uint32 dwDrives;
}

[CRepr]
public struct NETCONNECTINFOSTRUCT
{
	public uint32 cbStructure;
	public uint32 dwFlags;
	public uint32 dwSpeed;
	public uint32 dwDelay;
	public uint32 dwOptDataSize;
}

[CRepr]
public struct NOTIFYINFO
{
	public uint32 dwNotifyStatus;
	public uint32 dwOperationStatus;
	public void* lpContext;
}

[CRepr]
public struct NOTIFYADD
{
	public HWND hwndOwner;
	public NETRESOURCEA NetResource;
	public NET_USE_CONNECT_FLAGS dwAddFlags;
}

[CRepr]
public struct NOTIFYCANCEL
{
	public PWSTR lpName;
	public PWSTR lpProvider;
	public uint32 dwFlags;
	public BOOL fForce;
}

#endregion

#region Functions
public static
{
	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnectionA(PSTR lpRemoteName, PSTR lpPassword, PSTR lpLocalName);
	public static uint32 WNetAddConnection(PSTR lpRemoteName, PSTR lpPassword, PSTR lpLocalName) => WNetAddConnectionA(lpRemoteName, lpPassword, lpLocalName);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnectionW(PWSTR lpRemoteName, PWSTR lpPassword, PWSTR lpLocalName);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnection2A(NETRESOURCEA* lpNetResource, PSTR lpPassword, PSTR lpUserName, uint32 dwFlags);
	public static uint32 WNetAddConnection2(NETRESOURCEA* lpNetResource, PSTR lpPassword, PSTR lpUserName, uint32 dwFlags) => WNetAddConnection2A(lpNetResource, lpPassword, lpUserName, dwFlags);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnection2W(NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserName, uint32 dwFlags);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnection3A(HWND hwndOwner, NETRESOURCEA* lpNetResource, PSTR lpPassword, PSTR lpUserName, uint32 dwFlags);
	public static uint32 WNetAddConnection3(HWND hwndOwner, NETRESOURCEA* lpNetResource, PSTR lpPassword, PSTR lpUserName, uint32 dwFlags) => WNetAddConnection3A(hwndOwner, lpNetResource, lpPassword, lpUserName, dwFlags);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnection3W(HWND hwndOwner, NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserName, uint32 dwFlags);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnection4A(HWND hwndOwner, NETRESOURCEA* lpNetResource, void* pAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions);
	public static uint32 WNetAddConnection4(HWND hwndOwner, NETRESOURCEA* lpNetResource, void* pAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions) => WNetAddConnection4A(hwndOwner, lpNetResource, pAuthBuffer, cbAuthBuffer, dwFlags, lpUseOptions, cbUseOptions);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetAddConnection4W(HWND hwndOwner, NETRESOURCEW* lpNetResource, void* pAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetCancelConnectionA(PSTR lpName, BOOL fForce);
	public static uint32 WNetCancelConnection(PSTR lpName, BOOL fForce) => WNetCancelConnectionA(lpName, fForce);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetCancelConnectionW(PWSTR lpName, BOOL fForce);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetCancelConnection2A(PSTR lpName, uint32 dwFlags, BOOL fForce);
	public static uint32 WNetCancelConnection2(PSTR lpName, uint32 dwFlags, BOOL fForce) => WNetCancelConnection2A(lpName, dwFlags, fForce);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetCancelConnection2W(PWSTR lpName, uint32 dwFlags, BOOL fForce);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetConnectionA(PSTR lpLocalName, uint8* lpRemoteName, uint32* lpnLength);
	public static uint32 WNetGetConnection(PSTR lpLocalName, uint8* lpRemoteName, uint32* lpnLength) => WNetGetConnectionA(lpLocalName, lpRemoteName, lpnLength);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetConnectionW(PWSTR lpLocalName, char16* lpRemoteName, uint32* lpnLength);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetUseConnectionA(HWND hwndOwner, NETRESOURCEA* lpNetResource, PSTR lpPassword, PSTR lpUserId, NET_USE_CONNECT_FLAGS dwFlags, uint8* lpAccessName, uint32* lpBufferSize, uint32* lpResult);
	public static uint32 WNetUseConnection(HWND hwndOwner, NETRESOURCEA* lpNetResource, PSTR lpPassword, PSTR lpUserId, NET_USE_CONNECT_FLAGS dwFlags, uint8* lpAccessName, uint32* lpBufferSize, uint32* lpResult) => WNetUseConnectionA(hwndOwner, lpNetResource, lpPassword, lpUserId, dwFlags, lpAccessName, lpBufferSize, lpResult);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetUseConnectionW(HWND hwndOwner, NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserId, NET_USE_CONNECT_FLAGS dwFlags, char16* lpAccessName, uint32* lpBufferSize, uint32* lpResult);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetUseConnection4A(HWND hwndOwner, NETRESOURCEA* lpNetResource, void* pAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions, uint8* lpAccessName, uint32* lpBufferSize, uint32* lpResult);
	public static uint32 WNetUseConnection4(HWND hwndOwner, NETRESOURCEA* lpNetResource, void* pAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions, uint8* lpAccessName, uint32* lpBufferSize, uint32* lpResult) => WNetUseConnection4A(hwndOwner, lpNetResource, pAuthBuffer, cbAuthBuffer, dwFlags, lpUseOptions, cbUseOptions, lpAccessName, lpBufferSize, lpResult);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetUseConnection4W(HWND hwndOwner, NETRESOURCEW* lpNetResource, void* pAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions, char16* lpAccessName, uint32* lpBufferSize, uint32* lpResult);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetConnectionDialog(HWND hwnd, uint32 dwType);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetDisconnectDialog(HWND hwnd, uint32 dwType);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetConnectionDialog1A(CONNECTDLGSTRUCTA* lpConnDlgStruct);
	public static uint32 WNetConnectionDialog1(CONNECTDLGSTRUCTA* lpConnDlgStruct) => WNetConnectionDialog1A(lpConnDlgStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetConnectionDialog1W(CONNECTDLGSTRUCTW* lpConnDlgStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetDisconnectDialog1A(DISCDLGSTRUCTA* lpConnDlgStruct);
	public static uint32 WNetDisconnectDialog1(DISCDLGSTRUCTA* lpConnDlgStruct) => WNetDisconnectDialog1A(lpConnDlgStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetDisconnectDialog1W(DISCDLGSTRUCTW* lpConnDlgStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetOpenEnumA(NET_RESOURCE_SCOPE dwScope, NET_RESOURCE_TYPE dwType, WNET_OPEN_ENUM_USAGE dwUsage, NETRESOURCEA* lpNetResource, NetEnumHandle* lphEnum);
	public static uint32 WNetOpenEnum(NET_RESOURCE_SCOPE dwScope, NET_RESOURCE_TYPE dwType, WNET_OPEN_ENUM_USAGE dwUsage, NETRESOURCEA* lpNetResource, NetEnumHandle* lphEnum) => WNetOpenEnumA(dwScope, dwType, dwUsage, lpNetResource, lphEnum);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetOpenEnumW(NET_RESOURCE_SCOPE dwScope, NET_RESOURCE_TYPE dwType, WNET_OPEN_ENUM_USAGE dwUsage, NETRESOURCEW* lpNetResource, NetEnumHandle* lphEnum);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetEnumResourceA(HANDLE hEnum, uint32* lpcCount, void* lpBuffer, uint32* lpBufferSize);
	public static uint32 WNetEnumResource(HANDLE hEnum, uint32* lpcCount, void* lpBuffer, uint32* lpBufferSize) => WNetEnumResourceA(hEnum, lpcCount, lpBuffer, lpBufferSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetEnumResourceW(HANDLE hEnum, uint32* lpcCount, void* lpBuffer, uint32* lpBufferSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetCloseEnum(HANDLE hEnum);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetResourceParentA(NETRESOURCEA* lpNetResource, void* lpBuffer, uint32* lpcbBuffer);
	public static uint32 WNetGetResourceParent(NETRESOURCEA* lpNetResource, void* lpBuffer, uint32* lpcbBuffer) => WNetGetResourceParentA(lpNetResource, lpBuffer, lpcbBuffer);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetResourceParentW(NETRESOURCEW* lpNetResource, void* lpBuffer, uint32* lpcbBuffer);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetResourceInformationA(NETRESOURCEA* lpNetResource, void* lpBuffer, uint32* lpcbBuffer, PSTR* lplpSystem);
	public static uint32 WNetGetResourceInformation(NETRESOURCEA* lpNetResource, void* lpBuffer, uint32* lpcbBuffer, PSTR* lplpSystem) => WNetGetResourceInformationA(lpNetResource, lpBuffer, lpcbBuffer, lplpSystem);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetResourceInformationW(NETRESOURCEW* lpNetResource, void* lpBuffer, uint32* lpcbBuffer, PWSTR* lplpSystem);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetUniversalNameA(PSTR lpLocalPath, UNC_INFO_LEVEL dwInfoLevel, void* lpBuffer, uint32* lpBufferSize);
	public static uint32 WNetGetUniversalName(PSTR lpLocalPath, UNC_INFO_LEVEL dwInfoLevel, void* lpBuffer, uint32* lpBufferSize) => WNetGetUniversalNameA(lpLocalPath, dwInfoLevel, lpBuffer, lpBufferSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetUniversalNameW(PWSTR lpLocalPath, UNC_INFO_LEVEL dwInfoLevel, void* lpBuffer, uint32* lpBufferSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetUserA(PSTR lpName, uint8* lpUserName, uint32* lpnLength);
	public static uint32 WNetGetUser(PSTR lpName, uint8* lpUserName, uint32* lpnLength) => WNetGetUserA(lpName, lpUserName, lpnLength);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetUserW(PWSTR lpName, char16* lpUserName, uint32* lpnLength);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetProviderNameA(uint32 dwNetType, uint8* lpProviderName, uint32* lpBufferSize);
	public static uint32 WNetGetProviderName(uint32 dwNetType, uint8* lpProviderName, uint32* lpBufferSize) => WNetGetProviderNameA(dwNetType, lpProviderName, lpBufferSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetProviderNameW(uint32 dwNetType, char16* lpProviderName, uint32* lpBufferSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetNetworkInformationA(PSTR lpProvider, NETINFOSTRUCT* lpNetInfoStruct);
	public static uint32 WNetGetNetworkInformation(PSTR lpProvider, NETINFOSTRUCT* lpNetInfoStruct) => WNetGetNetworkInformationA(lpProvider, lpNetInfoStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetNetworkInformationW(PWSTR lpProvider, NETINFOSTRUCT* lpNetInfoStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetLastErrorA(uint32* lpError, uint8* lpErrorBuf, uint32 nErrorBufSize, uint8* lpNameBuf, uint32 nNameBufSize);
	public static uint32 WNetGetLastError(uint32* lpError, uint8* lpErrorBuf, uint32 nErrorBufSize, uint8* lpNameBuf, uint32 nNameBufSize) => WNetGetLastErrorA(lpError, lpErrorBuf, nErrorBufSize, lpNameBuf, nNameBufSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WNetGetLastErrorW(uint32* lpError, char16* lpErrorBuf, uint32 nErrorBufSize, char16* lpNameBuf, uint32 nNameBufSize);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MultinetGetConnectionPerformanceA(NETRESOURCEA* lpNetResource, NETCONNECTINFOSTRUCT* lpNetConnectInfoStruct);
	public static uint32 MultinetGetConnectionPerformance(NETRESOURCEA* lpNetResource, NETCONNECTINFOSTRUCT* lpNetConnectInfoStruct) => MultinetGetConnectionPerformanceA(lpNetResource, lpNetConnectInfoStruct);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MultinetGetConnectionPerformanceW(NETRESOURCEW* lpNetResource, NETCONNECTINFOSTRUCT* lpNetConnectInfoStruct);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPAddConnection(NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserName);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPAddConnection3(HWND hwndOwner, NETRESOURCEW* lpNetResource, PWSTR lpPassword, PWSTR lpUserName, NET_USE_CONNECT_FLAGS dwFlags);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPAddConnection4(HWND hwndOwner, NETRESOURCEW* lpNetResource, void* lpAuthBuffer, uint32 cbAuthBuffer, uint32 dwFlags, uint8* lpUseOptions, uint32 cbUseOptions);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPCancelConnection(PWSTR lpName, BOOL fForce);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPCancelConnection2(PWSTR lpName, BOOL fForce, uint32 dwFlags);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetConnection(PWSTR lpLocalName, char16* lpRemoteName, uint32* lpnBufferLen);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetConnection3(PWSTR lpLocalName, uint32 dwLevel, void* lpBuffer, uint32* lpBufferSize);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetUniversalName(PWSTR lpLocalPath, UNC_INFO_LEVEL dwInfoLevel, void* lpBuffer, uint32* lpBufferSize);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetConnectionPerformance(PWSTR lpRemoteName, NETCONNECTINFOSTRUCT* lpNetConnectInfo);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPOpenEnum(uint32 dwScope, uint32 dwType, uint32 dwUsage, NETRESOURCEW* lpNetResource, HANDLE* lphEnum);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPEnumResource(HANDLE hEnum, uint32* lpcCount, void* lpBuffer, uint32* lpBufferSize);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPCloseEnum(HANDLE hEnum);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetCaps(uint32 ndex);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetUser(PWSTR lpName, char16* lpUserName, uint32* lpnBufferLen);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetPersistentUseOptionsForConnection(PWSTR lpRemotePath, uint8* lpReadUseOptions, uint32 cbReadUseOptions, uint8* lpWriteUseOptions, uint32* lpSizeWriteUseOptions);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetResourceParent(NETRESOURCEW* lpNetResource, void* lpBuffer, uint32* lpBufferSize);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPGetResourceInformation(NETRESOURCEW* lpNetResource, void* lpBuffer, uint32* lpBufferSize, PWSTR* lplpSystem);

	[Import("davclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NPFormatNetworkName(PWSTR lpRemoteName, char16* lpFormattedName, uint32* lpnLength, NETWORK_NAME_FORMAT_FLAGS dwFlags, uint32 dwAveCharPerLine);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WNetSetLastErrorA(uint32 err, PSTR lpError, PSTR lpProviders);
	public static void WNetSetLastError(uint32 err, PSTR lpError, PSTR lpProviders) => WNetSetLastErrorA(err, lpError, lpProviders);

	[Import("MPR.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WNetSetLastErrorW(uint32 err, PWSTR lpError, PWSTR lpProviders);

}
#endregion
