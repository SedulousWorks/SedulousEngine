using Win32.Foundation;
using Win32.Security;
using Win32.System.StationsAndDesktops;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.Security.WinWlx;

#region Constants
public static
{
	public const uint32 WLX_VERSION_1_0 = 65536;
	public const uint32 WLX_VERSION_1_1 = 65537;
	public const uint32 WLX_VERSION_1_2 = 65538;
	public const uint32 WLX_VERSION_1_3 = 65539;
	public const uint32 WLX_VERSION_1_4 = 65540;
	public const uint32 WLX_CURRENT_VERSION = 65540;
	public const uint32 WLX_SAS_TYPE_TIMEOUT = 0;
	public const uint32 WLX_SAS_TYPE_CTRL_ALT_DEL = 1;
	public const uint32 WLX_SAS_TYPE_SCRNSVR_TIMEOUT = 2;
	public const uint32 WLX_SAS_TYPE_SCRNSVR_ACTIVITY = 3;
	public const uint32 WLX_SAS_TYPE_USER_LOGOFF = 4;
	public const uint32 WLX_SAS_TYPE_SC_INSERT = 5;
	public const uint32 WLX_SAS_TYPE_SC_REMOVE = 6;
	public const uint32 WLX_SAS_TYPE_AUTHENTICATED = 7;
	public const uint32 WLX_SAS_TYPE_SC_FIRST_READER_ARRIVED = 8;
	public const uint32 WLX_SAS_TYPE_SC_LAST_READER_REMOVED = 9;
	public const uint32 WLX_SAS_TYPE_SWITCHUSER = 10;
	public const uint32 WLX_SAS_TYPE_MAX_MSFT_VALUE = 127;
	public const uint32 WLX_LOGON_OPT_NO_PROFILE = 1;
	public const uint32 WLX_PROFILE_TYPE_V1_0 = 1;
	public const uint32 WLX_PROFILE_TYPE_V2_0 = 2;
	public const uint32 WLX_SAS_ACTION_LOGON = 1;
	public const uint32 WLX_SAS_ACTION_NONE = 2;
	public const uint32 WLX_SAS_ACTION_LOCK_WKSTA = 3;
	public const uint32 WLX_SAS_ACTION_LOGOFF = 4;
	public const uint32 WLX_SAS_ACTION_PWD_CHANGED = 6;
	public const uint32 WLX_SAS_ACTION_TASKLIST = 7;
	public const uint32 WLX_SAS_ACTION_UNLOCK_WKSTA = 8;
	public const uint32 WLX_SAS_ACTION_FORCE_LOGOFF = 9;
	public const uint32 WLX_SAS_ACTION_SHUTDOWN_SLEEP = 12;
	public const uint32 WLX_SAS_ACTION_SHUTDOWN_SLEEP2 = 13;
	public const uint32 WLX_SAS_ACTION_SHUTDOWN_HIBERNATE = 14;
	public const uint32 WLX_SAS_ACTION_RECONNECTED = 15;
	public const uint32 WLX_SAS_ACTION_DELAYED_FORCE_LOGOFF = 16;
	public const uint32 WLX_SAS_ACTION_SWITCH_CONSOLE = 17;
	public const uint32 WLX_WM_SAS = 1625;
	public const uint32 WLX_DLG_SAS = 101;
	public const uint32 WLX_DLG_INPUT_TIMEOUT = 102;
	public const uint32 WLX_DLG_SCREEN_SAVER_TIMEOUT = 103;
	public const uint32 WLX_DLG_USER_LOGOFF = 104;
	public const uint32 WLX_DIRECTORY_LENGTH = 256;
	public const uint32 WLX_CREDENTIAL_TYPE_V1_0 = 1;
	public const uint32 WLX_CREDENTIAL_TYPE_V2_0 = 2;
	public const uint32 WLX_CONSOLESWITCHCREDENTIAL_TYPE_V1_0 = 1;
	public const uint32 STATUSMSG_OPTION_NOANIMATION = 1;
	public const uint32 STATUSMSG_OPTION_SETFOREGROUND = 2;
	public const uint32 WLX_DESKTOP_NAME = 1;
	public const uint32 WLX_DESKTOP_HANDLE = 2;
	public const uint32 WLX_CREATE_INSTANCE_ONLY = 1;
	public const uint32 WLX_CREATE_USER = 2;
	public const uint32 WLX_OPTION_USE_CTRL_ALT_DEL = 1;
	public const uint32 WLX_OPTION_CONTEXT_POINTER = 2;
	public const uint32 WLX_OPTION_USE_SMART_CARD = 3;
	public const uint32 WLX_OPTION_FORCE_LOGOFF_TIME = 4;
	public const uint32 WLX_OPTION_IGNORE_AUTO_LOGON = 8;
	public const uint32 WLX_OPTION_NO_SWITCH_ON_SAS = 9;
	public const uint32 WLX_OPTION_SMART_CARD_PRESENT = 65537;
	public const uint32 WLX_OPTION_SMART_CARD_INFO = 65538;
	public const uint32 WLX_OPTION_DISPATCH_TABLE_SIZE = 65539;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WLX_SHUTDOWN_TYPE : uint32
{
	WLX_SAS_ACTION_SHUTDOWN = 5,
	WLX_SAS_ACTION_SHUTDOWN_REBOOT = 11,
	WLX_SAS_ACTION_SHUTDOWN_POWER_OFF = 10,
}

#endregion

#region Function Pointers
public function void PWLX_USE_CTRL_ALT_DEL(HANDLE hWlx);

public function void PWLX_SET_CONTEXT_POINTER(HANDLE hWlx, void* pWlxContext);

public function void PWLX_SAS_NOTIFY(HANDLE hWlx, uint32 dwSasType);

public function BOOL PWLX_SET_TIMEOUT(HANDLE hWlx, uint32 Timeout);

public function int32 PWLX_ASSIGN_SHELL_PROTECTION(HANDLE hWlx, HANDLE hToken, HANDLE hProcess, HANDLE hThread);

public function int32 PWLX_MESSAGE_BOX(HANDLE hWlx, HWND hwndOwner, PWSTR lpszText, PWSTR lpszTitle, uint32 fuStyle);

public function int32 PWLX_DIALOG_BOX(HANDLE hWlx, HANDLE hInst, PWSTR lpszTemplate, HWND hwndOwner, DLGPROC dlgprc);

public function int32 PWLX_DIALOG_BOX_INDIRECT(HANDLE hWlx, HANDLE hInst, DLGTEMPLATE* hDialogTemplate, HWND hwndOwner, DLGPROC dlgprc);

public function int32 PWLX_DIALOG_BOX_PARAM(HANDLE hWlx, HANDLE hInst, PWSTR lpszTemplate, HWND hwndOwner, DLGPROC dlgprc, LPARAM dwInitParam);

public function int32 PWLX_DIALOG_BOX_INDIRECT_PARAM(HANDLE hWlx, HANDLE hInst, DLGTEMPLATE* hDialogTemplate, HWND hwndOwner, DLGPROC dlgprc, LPARAM dwInitParam);

public function int32 PWLX_SWITCH_DESKTOP_TO_USER(HANDLE hWlx);

public function int32 PWLX_SWITCH_DESKTOP_TO_WINLOGON(HANDLE hWlx);

public function int32 PWLX_CHANGE_PASSWORD_NOTIFY(HANDLE hWlx, WLX_MPR_NOTIFY_INFO* pMprInfo, uint32 dwChangeInfo);

public function BOOL PWLX_GET_SOURCE_DESKTOP(HANDLE hWlx, WLX_DESKTOP** ppDesktop);

public function BOOL PWLX_SET_RETURN_DESKTOP(HANDLE hWlx, WLX_DESKTOP* pDesktop);

public function BOOL PWLX_CREATE_USER_DESKTOP(HANDLE hWlx, HANDLE hToken, uint32 Flags, PWSTR pszDesktopName, WLX_DESKTOP** ppDesktop);

public function int32 PWLX_CHANGE_PASSWORD_NOTIFY_EX(HANDLE hWlx, WLX_MPR_NOTIFY_INFO* pMprInfo, uint32 dwChangeInfo, PWSTR ProviderName, void* Reserved);

public function BOOL PWLX_CLOSE_USER_DESKTOP(HANDLE hWlx, WLX_DESKTOP* pDesktop, HANDLE hToken);

public function BOOL PWLX_SET_OPTION(HANDLE hWlx, uint32 Option, uint Value, uint* OldValue);

public function BOOL PWLX_GET_OPTION(HANDLE hWlx, uint32 Option, uint* Value);

public function void PWLX_WIN31_MIGRATE(HANDLE hWlx);

public function BOOL PWLX_QUERY_CLIENT_CREDENTIALS(WLX_CLIENT_CREDENTIALS_INFO_V1_0* pCred);

public function BOOL PWLX_QUERY_IC_CREDENTIALS(WLX_CLIENT_CREDENTIALS_INFO_V1_0* pCred);

public function BOOL PWLX_QUERY_TS_LOGON_CREDENTIALS(WLX_CLIENT_CREDENTIALS_INFO_V2_0* pCred);

public function BOOL PWLX_DISCONNECT();

public function uint32 PWLX_QUERY_TERMINAL_SERVICES_DATA(HANDLE hWlx, WLX_TERMINAL_SERVICES_DATA* pTSData, PWSTR UserName, PWSTR Domain);

public function uint32 PWLX_QUERY_CONSOLESWITCH_CREDENTIALS(WLX_CONSOLESWITCH_CREDENTIALS_INFO_V1_0* pCred);

public function uint32 PFNMSGECALLBACK(BOOL bVerbose, PWSTR lpMessage);

#endregion

#region Structs
[CRepr]
public struct WLX_SC_NOTIFICATION_INFO
{
	public PWSTR pszCard;
	public PWSTR pszReader;
	public PWSTR pszContainer;
	public PWSTR pszCryptoProvider;
}

[CRepr]
public struct WLX_PROFILE_V1_0
{
	public uint32 dwType;
	public PWSTR pszProfile;
}

[CRepr]
public struct WLX_PROFILE_V2_0
{
	public uint32 dwType;
	public PWSTR pszProfile;
	public PWSTR pszPolicy;
	public PWSTR pszNetworkDefaultUserProfile;
	public PWSTR pszServerName;
	public PWSTR pszEnvironment;
}

[CRepr]
public struct WLX_MPR_NOTIFY_INFO
{
	public PWSTR pszUserName;
	public PWSTR pszDomain;
	public PWSTR pszPassword;
	public PWSTR pszOldPassword;
}

[CRepr]
public struct WLX_TERMINAL_SERVICES_DATA
{
	public char16[257] ProfilePath;
	public char16[257] HomeDir;
	public char16[4] HomeDirDrive;
}

[CRepr]
public struct WLX_CLIENT_CREDENTIALS_INFO_V1_0
{
	public uint32 dwType;
	public PWSTR pszUserName;
	public PWSTR pszDomain;
	public PWSTR pszPassword;
	public BOOL fPromptForPassword;
}

[CRepr]
public struct WLX_CLIENT_CREDENTIALS_INFO_V2_0
{
	public uint32 dwType;
	public PWSTR pszUserName;
	public PWSTR pszDomain;
	public PWSTR pszPassword;
	public BOOL fPromptForPassword;
	public BOOL fDisconnectOnLogonFailure;
}

[CRepr]
public struct WLX_CONSOLESWITCH_CREDENTIALS_INFO_V1_0
{
	public uint32 dwType;
	public HANDLE UserToken;
	public LUID LogonId;
	public QUOTA_LIMITS Quotas;
	public PWSTR UserName;
	public PWSTR Domain;
	public LARGE_INTEGER LogonTime;
	public BOOL SmartCardLogon;
	public uint32 ProfileLength;
	public uint32 MessageType;
	public uint16 LogonCount;
	public uint16 BadPasswordCount;
	public LARGE_INTEGER ProfileLogonTime;
	public LARGE_INTEGER LogoffTime;
	public LARGE_INTEGER KickOffTime;
	public LARGE_INTEGER PasswordLastSet;
	public LARGE_INTEGER PasswordCanChange;
	public LARGE_INTEGER PasswordMustChange;
	public PWSTR LogonScript;
	public PWSTR HomeDirectory;
	public PWSTR FullName;
	public PWSTR ProfilePath;
	public PWSTR HomeDirectoryDrive;
	public PWSTR LogonServer;
	public uint32 UserFlags;
	public uint32 PrivateDataLen;
	public uint8* PrivateData;
}

[CRepr]
public struct WLX_DESKTOP
{
	public uint32 Size;
	public uint32 Flags;
	public HDESK hDesktop;
	public PWSTR pszDesktopName;
}

[CRepr]
public struct WLX_DISPATCH_VERSION_1_0
{
	public PWLX_USE_CTRL_ALT_DEL WlxUseCtrlAltDel;
	public PWLX_SET_CONTEXT_POINTER WlxSetContextPointer;
	public PWLX_SAS_NOTIFY WlxSasNotify;
	public PWLX_SET_TIMEOUT WlxSetTimeout;
	public PWLX_ASSIGN_SHELL_PROTECTION WlxAssignShellProtection;
	public PWLX_MESSAGE_BOX WlxMessageBox;
	public PWLX_DIALOG_BOX WlxDialogBox;
	public PWLX_DIALOG_BOX_PARAM WlxDialogBoxParam;
	public PWLX_DIALOG_BOX_INDIRECT WlxDialogBoxIndirect;
	public PWLX_DIALOG_BOX_INDIRECT_PARAM WlxDialogBoxIndirectParam;
	public PWLX_SWITCH_DESKTOP_TO_USER WlxSwitchDesktopToUser;
	public PWLX_SWITCH_DESKTOP_TO_WINLOGON WlxSwitchDesktopToWinlogon;
	public PWLX_CHANGE_PASSWORD_NOTIFY WlxChangePasswordNotify;
}

[CRepr]
public struct WLX_DISPATCH_VERSION_1_1
{
	public PWLX_USE_CTRL_ALT_DEL WlxUseCtrlAltDel;
	public PWLX_SET_CONTEXT_POINTER WlxSetContextPointer;
	public PWLX_SAS_NOTIFY WlxSasNotify;
	public PWLX_SET_TIMEOUT WlxSetTimeout;
	public PWLX_ASSIGN_SHELL_PROTECTION WlxAssignShellProtection;
	public PWLX_MESSAGE_BOX WlxMessageBox;
	public PWLX_DIALOG_BOX WlxDialogBox;
	public PWLX_DIALOG_BOX_PARAM WlxDialogBoxParam;
	public PWLX_DIALOG_BOX_INDIRECT WlxDialogBoxIndirect;
	public PWLX_DIALOG_BOX_INDIRECT_PARAM WlxDialogBoxIndirectParam;
	public PWLX_SWITCH_DESKTOP_TO_USER WlxSwitchDesktopToUser;
	public PWLX_SWITCH_DESKTOP_TO_WINLOGON WlxSwitchDesktopToWinlogon;
	public PWLX_CHANGE_PASSWORD_NOTIFY WlxChangePasswordNotify;
	public PWLX_GET_SOURCE_DESKTOP WlxGetSourceDesktop;
	public PWLX_SET_RETURN_DESKTOP WlxSetReturnDesktop;
	public PWLX_CREATE_USER_DESKTOP WlxCreateUserDesktop;
	public PWLX_CHANGE_PASSWORD_NOTIFY_EX WlxChangePasswordNotifyEx;
}

[CRepr]
public struct WLX_DISPATCH_VERSION_1_2
{
	public PWLX_USE_CTRL_ALT_DEL WlxUseCtrlAltDel;
	public PWLX_SET_CONTEXT_POINTER WlxSetContextPointer;
	public PWLX_SAS_NOTIFY WlxSasNotify;
	public PWLX_SET_TIMEOUT WlxSetTimeout;
	public PWLX_ASSIGN_SHELL_PROTECTION WlxAssignShellProtection;
	public PWLX_MESSAGE_BOX WlxMessageBox;
	public PWLX_DIALOG_BOX WlxDialogBox;
	public PWLX_DIALOG_BOX_PARAM WlxDialogBoxParam;
	public PWLX_DIALOG_BOX_INDIRECT WlxDialogBoxIndirect;
	public PWLX_DIALOG_BOX_INDIRECT_PARAM WlxDialogBoxIndirectParam;
	public PWLX_SWITCH_DESKTOP_TO_USER WlxSwitchDesktopToUser;
	public PWLX_SWITCH_DESKTOP_TO_WINLOGON WlxSwitchDesktopToWinlogon;
	public PWLX_CHANGE_PASSWORD_NOTIFY WlxChangePasswordNotify;
	public PWLX_GET_SOURCE_DESKTOP WlxGetSourceDesktop;
	public PWLX_SET_RETURN_DESKTOP WlxSetReturnDesktop;
	public PWLX_CREATE_USER_DESKTOP WlxCreateUserDesktop;
	public PWLX_CHANGE_PASSWORD_NOTIFY_EX WlxChangePasswordNotifyEx;
	public PWLX_CLOSE_USER_DESKTOP WlxCloseUserDesktop;
}

[CRepr]
public struct WLX_DISPATCH_VERSION_1_3
{
	public PWLX_USE_CTRL_ALT_DEL WlxUseCtrlAltDel;
	public PWLX_SET_CONTEXT_POINTER WlxSetContextPointer;
	public PWLX_SAS_NOTIFY WlxSasNotify;
	public PWLX_SET_TIMEOUT WlxSetTimeout;
	public PWLX_ASSIGN_SHELL_PROTECTION WlxAssignShellProtection;
	public PWLX_MESSAGE_BOX WlxMessageBox;
	public PWLX_DIALOG_BOX WlxDialogBox;
	public PWLX_DIALOG_BOX_PARAM WlxDialogBoxParam;
	public PWLX_DIALOG_BOX_INDIRECT WlxDialogBoxIndirect;
	public PWLX_DIALOG_BOX_INDIRECT_PARAM WlxDialogBoxIndirectParam;
	public PWLX_SWITCH_DESKTOP_TO_USER WlxSwitchDesktopToUser;
	public PWLX_SWITCH_DESKTOP_TO_WINLOGON WlxSwitchDesktopToWinlogon;
	public PWLX_CHANGE_PASSWORD_NOTIFY WlxChangePasswordNotify;
	public PWLX_GET_SOURCE_DESKTOP WlxGetSourceDesktop;
	public PWLX_SET_RETURN_DESKTOP WlxSetReturnDesktop;
	public PWLX_CREATE_USER_DESKTOP WlxCreateUserDesktop;
	public PWLX_CHANGE_PASSWORD_NOTIFY_EX WlxChangePasswordNotifyEx;
	public PWLX_CLOSE_USER_DESKTOP WlxCloseUserDesktop;
	public PWLX_SET_OPTION WlxSetOption;
	public PWLX_GET_OPTION WlxGetOption;
	public PWLX_WIN31_MIGRATE WlxWin31Migrate;
	public PWLX_QUERY_CLIENT_CREDENTIALS WlxQueryClientCredentials;
	public PWLX_QUERY_IC_CREDENTIALS WlxQueryInetConnectorCredentials;
	public PWLX_DISCONNECT WlxDisconnect;
	public PWLX_QUERY_TERMINAL_SERVICES_DATA WlxQueryTerminalServicesData;
}

[CRepr]
public struct WLX_DISPATCH_VERSION_1_4
{
	public PWLX_USE_CTRL_ALT_DEL WlxUseCtrlAltDel;
	public PWLX_SET_CONTEXT_POINTER WlxSetContextPointer;
	public PWLX_SAS_NOTIFY WlxSasNotify;
	public PWLX_SET_TIMEOUT WlxSetTimeout;
	public PWLX_ASSIGN_SHELL_PROTECTION WlxAssignShellProtection;
	public PWLX_MESSAGE_BOX WlxMessageBox;
	public PWLX_DIALOG_BOX WlxDialogBox;
	public PWLX_DIALOG_BOX_PARAM WlxDialogBoxParam;
	public PWLX_DIALOG_BOX_INDIRECT WlxDialogBoxIndirect;
	public PWLX_DIALOG_BOX_INDIRECT_PARAM WlxDialogBoxIndirectParam;
	public PWLX_SWITCH_DESKTOP_TO_USER WlxSwitchDesktopToUser;
	public PWLX_SWITCH_DESKTOP_TO_WINLOGON WlxSwitchDesktopToWinlogon;
	public PWLX_CHANGE_PASSWORD_NOTIFY WlxChangePasswordNotify;
	public PWLX_GET_SOURCE_DESKTOP WlxGetSourceDesktop;
	public PWLX_SET_RETURN_DESKTOP WlxSetReturnDesktop;
	public PWLX_CREATE_USER_DESKTOP WlxCreateUserDesktop;
	public PWLX_CHANGE_PASSWORD_NOTIFY_EX WlxChangePasswordNotifyEx;
	public PWLX_CLOSE_USER_DESKTOP WlxCloseUserDesktop;
	public PWLX_SET_OPTION WlxSetOption;
	public PWLX_GET_OPTION WlxGetOption;
	public PWLX_WIN31_MIGRATE WlxWin31Migrate;
	public PWLX_QUERY_CLIENT_CREDENTIALS WlxQueryClientCredentials;
	public PWLX_QUERY_IC_CREDENTIALS WlxQueryInetConnectorCredentials;
	public PWLX_DISCONNECT WlxDisconnect;
	public PWLX_QUERY_TERMINAL_SERVICES_DATA WlxQueryTerminalServicesData;
	public PWLX_QUERY_CONSOLESWITCH_CREDENTIALS WlxQueryConsoleSwitchCredentials;
	public PWLX_QUERY_TS_LOGON_CREDENTIALS WlxQueryTsLogonCredentials;
}

[CRepr]
public struct WLX_NOTIFICATION_INFO
{
	public uint32 Size;
	public uint32 Flags;
	public PWSTR UserName;
	public PWSTR Domain;
	public PWSTR WindowStation;
	public HANDLE hToken;
	public HDESK hDesktop;
	public PFNMSGECALLBACK pStatusCallback;
}

#endregion
