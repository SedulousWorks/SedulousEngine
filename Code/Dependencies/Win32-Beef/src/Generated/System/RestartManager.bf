using Win32.Foundation;
using System;

namespace Win32.System.RestartManager;

#region Constants
public static
{
	public const uint32 CCH_RM_SESSION_KEY = 32;
	public const uint32 CCH_RM_MAX_APP_NAME = 255;
	public const uint32 CCH_RM_MAX_SVC_NAME = 63;
	public const int32 RM_INVALID_TS_SESSION = -1;
	public const int32 RM_INVALID_PROCESS = -1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum RM_APP_TYPE : int32
{
	RmUnknownApp = 0,
	RmMainWindow = 1,
	RmOtherWindow = 2,
	RmService = 3,
	RmExplorer = 4,
	RmConsole = 5,
	RmCritical = 1000,
}


[AllowDuplicates]
public enum RM_SHUTDOWN_TYPE : int32
{
	RmForceShutdown = 1,
	RmShutdownOnlyRegistered = 16,
}


[AllowDuplicates]
public enum RM_APP_STATUS : int32
{
	RmStatusUnknown = 0,
	RmStatusRunning = 1,
	RmStatusStopped = 2,
	RmStatusStoppedOther = 4,
	RmStatusRestarted = 8,
	RmStatusErrorOnStop = 16,
	RmStatusErrorOnRestart = 32,
	RmStatusShutdownMasked = 64,
	RmStatusRestartMasked = 128,
}


[AllowDuplicates]
public enum RM_REBOOT_REASON : int32
{
	RmRebootReasonNone = 0,
	RmRebootReasonPermissionDenied = 1,
	RmRebootReasonSessionMismatch = 2,
	RmRebootReasonCriticalProcess = 4,
	RmRebootReasonCriticalService = 8,
	RmRebootReasonDetectedSelf = 16,
}


[AllowDuplicates]
public enum RM_FILTER_TRIGGER : int32
{
	RmFilterTriggerInvalid = 0,
	RmFilterTriggerFile = 1,
	RmFilterTriggerProcess = 2,
	RmFilterTriggerService = 3,
}


[AllowDuplicates]
public enum RM_FILTER_ACTION : int32
{
	RmInvalidFilterAction = 0,
	RmNoRestart = 1,
	RmNoShutdown = 2,
}

#endregion

#region Function Pointers
public function void RM_WRITE_STATUS_CALLBACK(uint32 nPercentComplete);

#endregion

#region Structs
[CRepr]
public struct RM_UNIQUE_PROCESS
{
	public uint32 dwProcessId;
	public FILETIME ProcessStartTime;
}

[CRepr]
public struct RM_PROCESS_INFO
{
	public RM_UNIQUE_PROCESS Process;
	public char16[256] strAppName;
	public char16[64] strServiceShortName;
	public RM_APP_TYPE ApplicationType;
	public uint32 AppStatus;
	public uint32 TSSessionId;
	public BOOL bRestartable;
}

[CRepr]
public struct RM_FILTER_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR strFilename;
		public RM_UNIQUE_PROCESS Process;
		public PWSTR strServiceShortName;
	}
	public RM_FILTER_ACTION FilterAction;
	public RM_FILTER_TRIGGER FilterTrigger;
	public uint32 cbNextOffset;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region Functions
public static
{
	[Import("rstrtmgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmStartSession(uint32* pSessionHandle, uint32 dwSessionFlags, PWSTR strSessionKey);

	[Import("RstrtMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmJoinSession(uint32* pSessionHandle, PWSTR strSessionKey);

	[Import("rstrtmgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmEndSession(uint32 dwSessionHandle);

	[Import("rstrtmgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmRegisterResources(uint32 dwSessionHandle, uint32 nFiles, PWSTR* rgsFileNames, uint32 nApplications, RM_UNIQUE_PROCESS* rgApplications, uint32 nServices, PWSTR* rgsServiceNames);

	[Import("rstrtmgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmGetList(uint32 dwSessionHandle, uint32* pnProcInfoNeeded, uint32* pnProcInfo, RM_PROCESS_INFO* rgAffectedApps, uint32* lpdwRebootReasons);

	[Import("rstrtmgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmShutdown(uint32 dwSessionHandle, uint32 lActionFlags, RM_WRITE_STATUS_CALLBACK fnStatus);

	[Import("rstrtmgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmRestart(uint32 dwSessionHandle, uint32 dwRestartFlags, RM_WRITE_STATUS_CALLBACK fnStatus);

	[Import("RstrtMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmCancelCurrentTask(uint32 dwSessionHandle);

	[Import("RstrtMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmAddFilter(uint32 dwSessionHandle, PWSTR strModuleName, RM_UNIQUE_PROCESS* pProcess, PWSTR strServiceShortName, RM_FILTER_ACTION FilterAction);

	[Import("RstrtMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmRemoveFilter(uint32 dwSessionHandle, PWSTR strModuleName, RM_UNIQUE_PROCESS* pProcess, PWSTR strServiceShortName);

	[Import("RstrtMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RmGetFilterList(uint32 dwSessionHandle, uint8* pbFilterBuf, uint32 cbFilterBuf, uint32* cbFilterBufNeeded);

}
#endregion
