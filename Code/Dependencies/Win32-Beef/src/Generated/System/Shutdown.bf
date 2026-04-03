using Win32.Foundation;
using System;

namespace Win32.System.Shutdown;

#region Constants
public static
{
	public const uint32 MAX_REASON_NAME_LEN = 64;
	public const uint32 MAX_REASON_DESC_LEN = 256;
	public const uint32 MAX_REASON_BUGID_LEN = 32;
	public const uint32 MAX_REASON_COMMENT_LEN = 512;
	public const uint32 SHUTDOWN_TYPE_LEN = 32;
	public const uint32 POLICY_SHOWREASONUI_NEVER = 0;
	public const uint32 POLICY_SHOWREASONUI_ALWAYS = 1;
	public const uint32 POLICY_SHOWREASONUI_WORKSTATIONONLY = 2;
	public const uint32 POLICY_SHOWREASONUI_SERVERONLY = 3;
	public const uint32 SNAPSHOT_POLICY_NEVER = 0;
	public const uint32 SNAPSHOT_POLICY_ALWAYS = 1;
	public const uint32 SNAPSHOT_POLICY_UNPLANNED = 2;
	public const uint32 MAX_NUM_REASONS = 256;
}
#endregion

#region Enums

[AllowDuplicates]
public enum SHUTDOWN_REASON : uint32
{
	SHTDN_REASON_NONE = 0,
	SHTDN_REASON_FLAG_COMMENT_REQUIRED = 16777216,
	SHTDN_REASON_FLAG_DIRTY_PROBLEM_ID_REQUIRED = 33554432,
	SHTDN_REASON_FLAG_CLEAN_UI = 67108864,
	SHTDN_REASON_FLAG_DIRTY_UI = 134217728,
	SHTDN_REASON_FLAG_MOBILE_UI_RESERVED = 268435456,
	SHTDN_REASON_FLAG_USER_DEFINED = 1073741824,
	SHTDN_REASON_FLAG_PLANNED = 2147483648,
	SHTDN_REASON_MAJOR_OTHER = 0,
	SHTDN_REASON_MAJOR_NONE = 0,
	SHTDN_REASON_MAJOR_HARDWARE = 65536,
	SHTDN_REASON_MAJOR_OPERATINGSYSTEM = 131072,
	SHTDN_REASON_MAJOR_SOFTWARE = 196608,
	SHTDN_REASON_MAJOR_APPLICATION = 262144,
	SHTDN_REASON_MAJOR_SYSTEM = 327680,
	SHTDN_REASON_MAJOR_POWER = 393216,
	SHTDN_REASON_MAJOR_LEGACY_API = 458752,
	SHTDN_REASON_MINOR_OTHER = 0,
	SHTDN_REASON_MINOR_NONE = 255,
	SHTDN_REASON_MINOR_MAINTENANCE = 1,
	SHTDN_REASON_MINOR_INSTALLATION = 2,
	SHTDN_REASON_MINOR_UPGRADE = 3,
	SHTDN_REASON_MINOR_RECONFIG = 4,
	SHTDN_REASON_MINOR_HUNG = 5,
	SHTDN_REASON_MINOR_UNSTABLE = 6,
	SHTDN_REASON_MINOR_DISK = 7,
	SHTDN_REASON_MINOR_PROCESSOR = 8,
	SHTDN_REASON_MINOR_NETWORKCARD = 9,
	SHTDN_REASON_MINOR_POWER_SUPPLY = 10,
	SHTDN_REASON_MINOR_CORDUNPLUGGED = 11,
	SHTDN_REASON_MINOR_ENVIRONMENT = 12,
	SHTDN_REASON_MINOR_HARDWARE_DRIVER = 13,
	SHTDN_REASON_MINOR_OTHERDRIVER = 14,
	SHTDN_REASON_MINOR_BLUESCREEN = 15,
	SHTDN_REASON_MINOR_SERVICEPACK = 16,
	SHTDN_REASON_MINOR_HOTFIX = 17,
	SHTDN_REASON_MINOR_SECURITYFIX = 18,
	SHTDN_REASON_MINOR_SECURITY = 19,
	SHTDN_REASON_MINOR_NETWORK_CONNECTIVITY = 20,
	SHTDN_REASON_MINOR_WMI = 21,
	SHTDN_REASON_MINOR_SERVICEPACK_UNINSTALL = 22,
	SHTDN_REASON_MINOR_HOTFIX_UNINSTALL = 23,
	SHTDN_REASON_MINOR_SECURITYFIX_UNINSTALL = 24,
	SHTDN_REASON_MINOR_MMC = 25,
	SHTDN_REASON_MINOR_SYSTEMRESTORE = 26,
	SHTDN_REASON_MINOR_TERMSRV = 32,
	SHTDN_REASON_MINOR_DC_PROMOTION = 33,
	SHTDN_REASON_MINOR_DC_DEMOTION = 34,
	SHTDN_REASON_UNKNOWN = 255,
	SHTDN_REASON_LEGACY_API = 2147942400,
	SHTDN_REASON_VALID_BIT_MASK = 3238002687,
}


[AllowDuplicates]
public enum SHUTDOWN_FLAGS : uint32
{
	SHUTDOWN_FORCE_OTHERS = 1,
	SHUTDOWN_FORCE_SELF = 2,
	SHUTDOWN_RESTART = 4,
	SHUTDOWN_POWEROFF = 8,
	SHUTDOWN_NOREBOOT = 16,
	SHUTDOWN_GRACE_OVERRIDE = 32,
	SHUTDOWN_INSTALL_UPDATES = 64,
	SHUTDOWN_RESTARTAPPS = 128,
	SHUTDOWN_SKIP_SVC_PRESHUTDOWN = 256,
	SHUTDOWN_HYBRID = 512,
	SHUTDOWN_RESTART_BOOTOPTIONS = 1024,
	SHUTDOWN_SOFT_REBOOT = 2048,
	SHUTDOWN_MOBILE_UI = 4096,
	SHUTDOWN_ARSO = 8192,
	SHUTDOWN_CHECK_SAFE_FOR_SERVER = 16384,
	SHUTDOWN_VAIL_CONTAINER = 32768,
	SHUTDOWN_SYSTEM_INITIATED = 65536,
}


[AllowDuplicates]
public enum EXIT_WINDOWS_FLAGS : uint32
{
	EWX_HYBRID_SHUTDOWN = 4194304,
	EWX_LOGOFF = 0,
	EWX_POWEROFF = 8,
	EWX_REBOOT = 2,
	EWX_RESTARTAPPS = 64,
	EWX_SHUTDOWN = 1,
}

#endregion


#region Functions
public static
{
	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitiateSystemShutdownA(PSTR lpMachineName, PSTR lpMessage, uint32 dwTimeout, BOOL bForceAppsClosed, BOOL bRebootAfterShutdown);
	public static BOOL InitiateSystemShutdown(PSTR lpMachineName, PSTR lpMessage, uint32 dwTimeout, BOOL bForceAppsClosed, BOOL bRebootAfterShutdown) => InitiateSystemShutdownA(lpMachineName, lpMessage, dwTimeout, bForceAppsClosed, bRebootAfterShutdown);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitiateSystemShutdownW(PWSTR lpMachineName, PWSTR lpMessage, uint32 dwTimeout, BOOL bForceAppsClosed, BOOL bRebootAfterShutdown);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AbortSystemShutdownA(PSTR lpMachineName);
	public static BOOL AbortSystemShutdown(PSTR lpMachineName) => AbortSystemShutdownA(lpMachineName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AbortSystemShutdownW(PWSTR lpMachineName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitiateSystemShutdownExA(PSTR lpMachineName, PSTR lpMessage, uint32 dwTimeout, BOOL bForceAppsClosed, BOOL bRebootAfterShutdown, SHUTDOWN_REASON dwReason);
	public static BOOL InitiateSystemShutdownEx(PSTR lpMachineName, PSTR lpMessage, uint32 dwTimeout, BOOL bForceAppsClosed, BOOL bRebootAfterShutdown, SHUTDOWN_REASON dwReason) => InitiateSystemShutdownExA(lpMachineName, lpMessage, dwTimeout, bForceAppsClosed, bRebootAfterShutdown, dwReason);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitiateSystemShutdownExW(PWSTR lpMachineName, PWSTR lpMessage, uint32 dwTimeout, BOOL bForceAppsClosed, BOOL bRebootAfterShutdown, SHUTDOWN_REASON dwReason);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 InitiateShutdownA(PSTR lpMachineName, PSTR lpMessage, uint32 dwGracePeriod, SHUTDOWN_FLAGS dwShutdownFlags, SHUTDOWN_REASON dwReason);
	public static uint32 InitiateShutdown(PSTR lpMachineName, PSTR lpMessage, uint32 dwGracePeriod, SHUTDOWN_FLAGS dwShutdownFlags, SHUTDOWN_REASON dwReason) => InitiateShutdownA(lpMachineName, lpMessage, dwGracePeriod, dwShutdownFlags, dwReason);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 InitiateShutdownW(PWSTR lpMachineName, PWSTR lpMessage, uint32 dwGracePeriod, SHUTDOWN_FLAGS dwShutdownFlags, SHUTDOWN_REASON dwReason);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CheckForHiberboot(BOOLEAN* pHiberboot, BOOLEAN bClearFlag);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExitWindowsEx(EXIT_WINDOWS_FLAGS uFlags, SHUTDOWN_REASON dwReason);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LockWorkStation();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShutdownBlockReasonCreate(HWND hWnd, PWSTR pwszReason);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShutdownBlockReasonQuery(HWND hWnd, char16* pwszBuff, uint32* pcchBuff);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShutdownBlockReasonDestroy(HWND hWnd);

}
#endregion
