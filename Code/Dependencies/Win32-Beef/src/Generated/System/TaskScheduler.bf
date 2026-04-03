using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Controls;
using System;

namespace Win32.System.TaskScheduler;

#region Constants
public static
{
	public const uint32 TASK_SUNDAY = 1;
	public const uint32 TASK_MONDAY = 2;
	public const uint32 TASK_TUESDAY = 4;
	public const uint32 TASK_WEDNESDAY = 8;
	public const uint32 TASK_THURSDAY = 16;
	public const uint32 TASK_FRIDAY = 32;
	public const uint32 TASK_SATURDAY = 64;
	public const uint32 TASK_FIRST_WEEK = 1;
	public const uint32 TASK_SECOND_WEEK = 2;
	public const uint32 TASK_THIRD_WEEK = 3;
	public const uint32 TASK_FOURTH_WEEK = 4;
	public const uint32 TASK_LAST_WEEK = 5;
	public const uint32 TASK_JANUARY = 1;
	public const uint32 TASK_FEBRUARY = 2;
	public const uint32 TASK_MARCH = 4;
	public const uint32 TASK_APRIL = 8;
	public const uint32 TASK_MAY = 16;
	public const uint32 TASK_JUNE = 32;
	public const uint32 TASK_JULY = 64;
	public const uint32 TASK_AUGUST = 128;
	public const uint32 TASK_SEPTEMBER = 256;
	public const uint32 TASK_OCTOBER = 512;
	public const uint32 TASK_NOVEMBER = 1024;
	public const uint32 TASK_DECEMBER = 2048;
	public const uint32 TASK_FLAG_INTERACTIVE = 1;
	public const uint32 TASK_FLAG_DELETE_WHEN_DONE = 2;
	public const uint32 TASK_FLAG_DISABLED = 4;
	public const uint32 TASK_FLAG_START_ONLY_IF_IDLE = 16;
	public const uint32 TASK_FLAG_KILL_ON_IDLE_END = 32;
	public const uint32 TASK_FLAG_DONT_START_IF_ON_BATTERIES = 64;
	public const uint32 TASK_FLAG_KILL_IF_GOING_ON_BATTERIES = 128;
	public const uint32 TASK_FLAG_RUN_ONLY_IF_DOCKED = 256;
	public const uint32 TASK_FLAG_HIDDEN = 512;
	public const uint32 TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET = 1024;
	public const uint32 TASK_FLAG_RESTART_ON_IDLE_RESUME = 2048;
	public const uint32 TASK_FLAG_SYSTEM_REQUIRED = 4096;
	public const uint32 TASK_FLAG_RUN_ONLY_IF_LOGGED_ON = 8192;
	public const uint32 TASK_TRIGGER_FLAG_HAS_END_DATE = 1;
	public const uint32 TASK_TRIGGER_FLAG_KILL_AT_DURATION_END = 2;
	public const uint32 TASK_TRIGGER_FLAG_DISABLED = 4;
	public const uint32 TASK_MAX_RUN_TIMES = 1440;
	public const Guid CLSID_CTask = .(0x148bd520, 0xa2ab, 0x11ce, 0xb1, 0x1f, 0x00, 0xaa, 0x00, 0x53, 0x05, 0x03);
	public const Guid CLSID_CTaskScheduler = .(0x148bd52a, 0xa2ab, 0x11ce, 0xb1, 0x1f, 0x00, 0xaa, 0x00, 0x53, 0x05, 0x03);
}
#endregion

#region Enums

[AllowDuplicates]
public enum TASK_TRIGGER_TYPE : int32
{
	TASK_TIME_TRIGGER_ONCE = 0,
	TASK_TIME_TRIGGER_DAILY = 1,
	TASK_TIME_TRIGGER_WEEKLY = 2,
	TASK_TIME_TRIGGER_MONTHLYDATE = 3,
	TASK_TIME_TRIGGER_MONTHLYDOW = 4,
	TASK_EVENT_TRIGGER_ON_IDLE = 5,
	TASK_EVENT_TRIGGER_AT_SYSTEMSTART = 6,
	TASK_EVENT_TRIGGER_AT_LOGON = 7,
}


[AllowDuplicates]
public enum TASKPAGE : int32
{
	TASKPAGE_TASK = 0,
	TASKPAGE_SCHEDULE = 1,
	TASKPAGE_SETTINGS = 2,
}


[AllowDuplicates]
public enum TASK_RUN_FLAGS : int32
{
	TASK_RUN_NO_FLAGS = 0,
	TASK_RUN_AS_SELF = 1,
	TASK_RUN_IGNORE_CONSTRAINTS = 2,
	TASK_RUN_USE_SESSION_ID = 4,
	TASK_RUN_USER_SID = 8,
}


[AllowDuplicates]
public enum TASK_ENUM_FLAGS : int32
{
	TASK_ENUM_HIDDEN = 1,
}


[AllowDuplicates]
public enum TASK_LOGON_TYPE : int32
{
	TASK_LOGON_NONE = 0,
	TASK_LOGON_PASSWORD = 1,
	TASK_LOGON_S4U = 2,
	TASK_LOGON_INTERACTIVE_TOKEN = 3,
	TASK_LOGON_GROUP = 4,
	TASK_LOGON_SERVICE_ACCOUNT = 5,
	TASK_LOGON_INTERACTIVE_TOKEN_OR_PASSWORD = 6,
}


[AllowDuplicates]
public enum TASK_RUNLEVEL_TYPE : int32
{
	TASK_RUNLEVEL_LUA = 0,
	TASK_RUNLEVEL_HIGHEST = 1,
}


[AllowDuplicates]
public enum TASK_PROCESSTOKENSID_TYPE : int32
{
	TASK_PROCESSTOKENSID_NONE = 0,
	TASK_PROCESSTOKENSID_UNRESTRICTED = 1,
	TASK_PROCESSTOKENSID_DEFAULT = 2,
}


[AllowDuplicates]
public enum TASK_STATE : int32
{
	TASK_STATE_UNKNOWN = 0,
	TASK_STATE_DISABLED = 1,
	TASK_STATE_QUEUED = 2,
	TASK_STATE_READY = 3,
	TASK_STATE_RUNNING = 4,
}


[AllowDuplicates]
public enum TASK_CREATION : int32
{
	TASK_VALIDATE_ONLY = 1,
	TASK_CREATE = 2,
	TASK_UPDATE = 4,
	TASK_CREATE_OR_UPDATE = 6,
	TASK_DISABLE = 8,
	TASK_DONT_ADD_PRINCIPAL_ACE = 16,
	TASK_IGNORE_REGISTRATION_TRIGGERS = 32,
}


[AllowDuplicates]
public enum TASK_TRIGGER_TYPE2 : int32
{
	TASK_TRIGGER_EVENT = 0,
	TASK_TRIGGER_TIME = 1,
	TASK_TRIGGER_DAILY = 2,
	TASK_TRIGGER_WEEKLY = 3,
	TASK_TRIGGER_MONTHLY = 4,
	TASK_TRIGGER_MONTHLYDOW = 5,
	TASK_TRIGGER_IDLE = 6,
	TASK_TRIGGER_REGISTRATION = 7,
	TASK_TRIGGER_BOOT = 8,
	TASK_TRIGGER_LOGON = 9,
	TASK_TRIGGER_SESSION_STATE_CHANGE = 11,
	TASK_TRIGGER_CUSTOM_TRIGGER_01 = 12,
}


[AllowDuplicates]
public enum TASK_SESSION_STATE_CHANGE_TYPE : int32
{
	TASK_CONSOLE_CONNECT = 1,
	TASK_CONSOLE_DISCONNECT = 2,
	TASK_REMOTE_CONNECT = 3,
	TASK_REMOTE_DISCONNECT = 4,
	TASK_SESSION_LOCK = 7,
	TASK_SESSION_UNLOCK = 8,
}


[AllowDuplicates]
public enum TASK_ACTION_TYPE : int32
{
	TASK_ACTION_EXEC = 0,
	TASK_ACTION_COM_HANDLER = 5,
	TASK_ACTION_SEND_EMAIL = 6,
	TASK_ACTION_SHOW_MESSAGE = 7,
}


[AllowDuplicates]
public enum TASK_INSTANCES_POLICY : int32
{
	TASK_INSTANCES_PARALLEL = 0,
	TASK_INSTANCES_QUEUE = 1,
	TASK_INSTANCES_IGNORE_NEW = 2,
	TASK_INSTANCES_STOP_EXISTING = 3,
}


[AllowDuplicates]
public enum TASK_COMPATIBILITY : int32
{
	TASK_COMPATIBILITY_AT = 0,
	TASK_COMPATIBILITY_V1 = 1,
	TASK_COMPATIBILITY_V2 = 2,
	TASK_COMPATIBILITY_V2_1 = 3,
	TASK_COMPATIBILITY_V2_2 = 4,
	TASK_COMPATIBILITY_V2_3 = 5,
	TASK_COMPATIBILITY_V2_4 = 6,
}

#endregion


#region Structs
[CRepr]
public struct DAILY
{
	public uint16 DaysInterval;
}

[CRepr]
public struct WEEKLY
{
	public uint16 WeeksInterval;
	public uint16 rgfDaysOfTheWeek;
}

[CRepr]
public struct MONTHLYDATE
{
	public uint32 rgfDays;
	public uint16 rgfMonths;
}

[CRepr]
public struct MONTHLYDOW
{
	public uint16 wWhichWeek;
	public uint16 rgfDaysOfTheWeek;
	public uint16 rgfMonths;
}

[CRepr, Union]
public struct TRIGGER_TYPE_UNION
{
	public DAILY Daily;
	public WEEKLY Weekly;
	public MONTHLYDATE MonthlyDate;
	public MONTHLYDOW MonthlyDOW;
}

[CRepr]
public struct TASK_TRIGGER
{
	public uint16 cbTriggerSize;
	public uint16 Reserved1;
	public uint16 wBeginYear;
	public uint16 wBeginMonth;
	public uint16 wBeginDay;
	public uint16 wEndYear;
	public uint16 wEndMonth;
	public uint16 wEndDay;
	public uint16 wStartHour;
	public uint16 wStartMinute;
	public uint32 MinutesDuration;
	public uint32 MinutesInterval;
	public uint32 rgFlags;
	public TASK_TRIGGER_TYPE TriggerType;
	public TRIGGER_TYPE_UNION Type;
	public uint16 Reserved2;
	public uint16 wRandomMinutesInterval;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_TaskScheduler = .(0x0f87369f, 0xa4e5, 0x4cfc, 0xbd, 0x3e, 0x73, 0xe6, 0x15, 0x45, 0x72, 0xdd);


	public const Guid CLSID_TaskHandlerPS = .(0xf2a69db7, 0xda2c, 0x4352, 0x90, 0x66, 0x86, 0xfe, 0xe6, 0xda, 0xca, 0xc9);


	public const Guid CLSID_TaskHandlerStatusPS = .(0x9f15266d, 0xd7ba, 0x48f0, 0x93, 0xc1, 0xe6, 0x89, 0x5f, 0x6f, 0xe5, 0xac);


}
#endregion

#region COM Types
[CRepr]struct ITaskTrigger : IUnknown
{
	public new const Guid IID = .(0x148bd52b, 0xa2ab, 0x11ce, 0xb1, 0x1f, 0x00, 0xaa, 0x00, 0x53, 0x05, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_TRIGGER* pTrigger) SetTrigger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_TRIGGER* pTrigger) GetTrigger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszTrigger) GetTriggerString;
	}


	public HRESULT SetTrigger(TASK_TRIGGER* pTrigger) mut => VT.[Friend]SetTrigger(&this, pTrigger);

	public HRESULT GetTrigger(TASK_TRIGGER* pTrigger) mut => VT.[Friend]GetTrigger(&this, pTrigger);

	public HRESULT GetTriggerString(PWSTR* ppwszTrigger) mut => VT.[Friend]GetTriggerString(&this, ppwszTrigger);
}

[CRepr]struct IScheduledWorkItem : IUnknown
{
	public new const Guid IID = .(0xa6b952f0, 0xa4b1, 0x11d0, 0x99, 0x7d, 0x00, 0xaa, 0x00, 0x68, 0x87, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* piNewTrigger, ITaskTrigger** ppTrigger) CreateTrigger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 iTrigger) DeleteTrigger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwCount) GetTriggerCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 iTrigger, ITaskTrigger** ppTrigger) GetTrigger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 iTrigger, PWSTR* ppwszTrigger) GetTriggerString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstBegin, SYSTEMTIME* pstEnd, uint16* pCount, SYSTEMTIME** rgstTaskTimes) GetRunTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstNextRun) GetNextRunTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wIdleMinutes, uint16 wDeadlineMinutes) SetIdleWait;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwIdleMinutes, uint16* pwDeadlineMinutes) GetIdleWait;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Run;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hParent, uint32 dwReserved) EditWorkItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstLastRun) GetMostRecentRunTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phrStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwExitCode) GetExitCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszComment) SetComment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszComment) GetComment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszCreator) SetCreator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszCreator) GetCreator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 cbData, uint8* rgbData) SetWorkItemData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pcbData, uint8** prgbData) GetWorkItemData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRetryCount) SetErrorRetryCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwRetryCount) GetErrorRetryCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wRetryInterval) SetErrorRetryInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwRetryInterval) GetErrorRetryInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAccountName, PWSTR pwszPassword) SetAccountInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszAccountName) GetAccountInformation;
	}


	public HRESULT CreateTrigger(uint16* piNewTrigger, ITaskTrigger** ppTrigger) mut => VT.[Friend]CreateTrigger(&this, piNewTrigger, ppTrigger);

	public HRESULT DeleteTrigger(uint16 iTrigger) mut => VT.[Friend]DeleteTrigger(&this, iTrigger);

	public HRESULT GetTriggerCount(uint16* pwCount) mut => VT.[Friend]GetTriggerCount(&this, pwCount);

	public HRESULT GetTrigger(uint16 iTrigger, ITaskTrigger** ppTrigger) mut => VT.[Friend]GetTrigger(&this, iTrigger, ppTrigger);

	public HRESULT GetTriggerString(uint16 iTrigger, PWSTR* ppwszTrigger) mut => VT.[Friend]GetTriggerString(&this, iTrigger, ppwszTrigger);

	public HRESULT GetRunTimes(SYSTEMTIME* pstBegin, SYSTEMTIME* pstEnd, uint16* pCount, SYSTEMTIME** rgstTaskTimes) mut => VT.[Friend]GetRunTimes(&this, pstBegin, pstEnd, pCount, rgstTaskTimes);

	public HRESULT GetNextRunTime(SYSTEMTIME* pstNextRun) mut => VT.[Friend]GetNextRunTime(&this, pstNextRun);

	public HRESULT SetIdleWait(uint16 wIdleMinutes, uint16 wDeadlineMinutes) mut => VT.[Friend]SetIdleWait(&this, wIdleMinutes, wDeadlineMinutes);

	public HRESULT GetIdleWait(uint16* pwIdleMinutes, uint16* pwDeadlineMinutes) mut => VT.[Friend]GetIdleWait(&this, pwIdleMinutes, pwDeadlineMinutes);

	public HRESULT Run() mut => VT.[Friend]Run(&this);

	public HRESULT Terminate() mut => VT.[Friend]Terminate(&this);

	public HRESULT EditWorkItem(HWND hParent, uint32 dwReserved) mut => VT.[Friend]EditWorkItem(&this, hParent, dwReserved);

	public HRESULT GetMostRecentRunTime(SYSTEMTIME* pstLastRun) mut => VT.[Friend]GetMostRecentRunTime(&this, pstLastRun);

	public HRESULT GetStatus(HRESULT* phrStatus) mut => VT.[Friend]GetStatus(&this, phrStatus);

	public HRESULT GetExitCode(uint32* pdwExitCode) mut => VT.[Friend]GetExitCode(&this, pdwExitCode);

	public HRESULT SetComment(PWSTR pwszComment) mut => VT.[Friend]SetComment(&this, pwszComment);

	public HRESULT GetComment(PWSTR* ppwszComment) mut => VT.[Friend]GetComment(&this, ppwszComment);

	public HRESULT SetCreator(PWSTR pwszCreator) mut => VT.[Friend]SetCreator(&this, pwszCreator);

	public HRESULT GetCreator(PWSTR* ppwszCreator) mut => VT.[Friend]GetCreator(&this, ppwszCreator);

	public HRESULT SetWorkItemData(uint16 cbData, uint8* rgbData) mut => VT.[Friend]SetWorkItemData(&this, cbData, rgbData);

	public HRESULT GetWorkItemData(uint16* pcbData, uint8** prgbData) mut => VT.[Friend]GetWorkItemData(&this, pcbData, prgbData);

	public HRESULT SetErrorRetryCount(uint16 wRetryCount) mut => VT.[Friend]SetErrorRetryCount(&this, wRetryCount);

	public HRESULT GetErrorRetryCount(uint16* pwRetryCount) mut => VT.[Friend]GetErrorRetryCount(&this, pwRetryCount);

	public HRESULT SetErrorRetryInterval(uint16 wRetryInterval) mut => VT.[Friend]SetErrorRetryInterval(&this, wRetryInterval);

	public HRESULT GetErrorRetryInterval(uint16* pwRetryInterval) mut => VT.[Friend]GetErrorRetryInterval(&this, pwRetryInterval);

	public HRESULT SetFlags(uint32 dwFlags) mut => VT.[Friend]SetFlags(&this, dwFlags);

	public HRESULT GetFlags(uint32* pdwFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwFlags);

	public HRESULT SetAccountInformation(PWSTR pwszAccountName, PWSTR pwszPassword) mut => VT.[Friend]SetAccountInformation(&this, pwszAccountName, pwszPassword);

	public HRESULT GetAccountInformation(PWSTR* ppwszAccountName) mut => VT.[Friend]GetAccountInformation(&this, ppwszAccountName);
}

[CRepr]struct ITask : IScheduledWorkItem
{
	public new const Guid IID = .(0x148bd524, 0xa2ab, 0x11ce, 0xb1, 0x1f, 0x00, 0xaa, 0x00, 0x53, 0x05, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IScheduledWorkItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszApplicationName) SetApplicationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszApplicationName) GetApplicationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszParameters) SetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszParameters) GetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszWorkingDirectory) SetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszWorkingDirectory) GetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwPriority) SetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPriority) GetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetTaskFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetTaskFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxRunTimeMS) SetMaxRunTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxRunTimeMS) GetMaxRunTime;
	}


	public HRESULT SetApplicationName(PWSTR pwszApplicationName) mut => VT.[Friend]SetApplicationName(&this, pwszApplicationName);

	public HRESULT GetApplicationName(PWSTR* ppwszApplicationName) mut => VT.[Friend]GetApplicationName(&this, ppwszApplicationName);

	public HRESULT SetParameters(PWSTR pwszParameters) mut => VT.[Friend]SetParameters(&this, pwszParameters);

	public HRESULT GetParameters(PWSTR* ppwszParameters) mut => VT.[Friend]GetParameters(&this, ppwszParameters);

	public HRESULT SetWorkingDirectory(PWSTR pwszWorkingDirectory) mut => VT.[Friend]SetWorkingDirectory(&this, pwszWorkingDirectory);

	public HRESULT GetWorkingDirectory(PWSTR* ppwszWorkingDirectory) mut => VT.[Friend]GetWorkingDirectory(&this, ppwszWorkingDirectory);

	public HRESULT SetPriority(uint32 dwPriority) mut => VT.[Friend]SetPriority(&this, dwPriority);

	public HRESULT GetPriority(uint32* pdwPriority) mut => VT.[Friend]GetPriority(&this, pdwPriority);

	public HRESULT SetTaskFlags(uint32 dwFlags) mut => VT.[Friend]SetTaskFlags(&this, dwFlags);

	public HRESULT GetTaskFlags(uint32* pdwFlags) mut => VT.[Friend]GetTaskFlags(&this, pdwFlags);

	public HRESULT SetMaxRunTime(uint32 dwMaxRunTimeMS) mut => VT.[Friend]SetMaxRunTime(&this, dwMaxRunTimeMS);

	public HRESULT GetMaxRunTime(uint32* pdwMaxRunTimeMS) mut => VT.[Friend]GetMaxRunTime(&this, pdwMaxRunTimeMS);
}

[CRepr]struct IEnumWorkItems : IUnknown
{
	public new const Guid IID = .(0x148bd528, 0xa2ab, 0x11ce, 0xb1, 0x1f, 0x00, 0xaa, 0x00, 0x53, 0x05, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, PWSTR** rgpwszNames, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWorkItems** ppEnumWorkItems) Clone;
	}


	public HRESULT Next(uint32 celt, PWSTR** rgpwszNames, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgpwszNames, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumWorkItems** ppEnumWorkItems) mut => VT.[Friend]Clone(&this, ppEnumWorkItems);
}

[CRepr]struct ITaskScheduler : IUnknown
{
	public new const Guid IID = .(0x148bd527, 0xa2ab, 0x11ce, 0xb1, 0x1f, 0x00, 0xaa, 0x00, 0x53, 0x05, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszComputer) SetTargetComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszComputer) GetTargetComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWorkItems** ppEnumWorkItems) Enum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, in Guid riid, IUnknown** ppUnk) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszTaskName, in Guid rclsid, in Guid riid, IUnknown** ppUnk) NewWorkItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszTaskName, IScheduledWorkItem* pWorkItem) AddWorkItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, in Guid riid) IsOfType;
	}


	public HRESULT SetTargetComputer(PWSTR pwszComputer) mut => VT.[Friend]SetTargetComputer(&this, pwszComputer);

	public HRESULT GetTargetComputer(PWSTR* ppwszComputer) mut => VT.[Friend]GetTargetComputer(&this, ppwszComputer);

	public HRESULT Enum(IEnumWorkItems** ppEnumWorkItems) mut => VT.[Friend]Enum(&this, ppEnumWorkItems);

	public HRESULT Activate(PWSTR pwszName, in Guid riid, IUnknown** ppUnk) mut => VT.[Friend]Activate(&this, pwszName, riid, ppUnk);

	public HRESULT Delete(PWSTR pwszName) mut => VT.[Friend]Delete(&this, pwszName);

	public HRESULT NewWorkItem(PWSTR pwszTaskName, in Guid rclsid, in Guid riid, IUnknown** ppUnk) mut => VT.[Friend]NewWorkItem(&this, pwszTaskName, rclsid, riid, ppUnk);

	public HRESULT AddWorkItem(PWSTR pwszTaskName, IScheduledWorkItem* pWorkItem) mut => VT.[Friend]AddWorkItem(&this, pwszTaskName, pWorkItem);

	public HRESULT IsOfType(PWSTR pwszName, in Guid riid) mut => VT.[Friend]IsOfType(&this, pwszName, riid);
}

[CRepr]struct IProvideTaskPage : IUnknown
{
	public new const Guid IID = .(0x4086658a, 0xcbbb, 0x11cf, 0xb6, 0x04, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASKPAGE tpType, BOOL fPersistChanges, HPROPSHEETPAGE* phPage) GetPage;
	}


	public HRESULT GetPage(TASKPAGE tpType, BOOL fPersistChanges, HPROPSHEETPAGE* phPage) mut => VT.[Friend]GetPage(&this, tpType, fPersistChanges, phPage);
}

[CRepr]struct ITaskFolderCollection : IDispatch
{
	public new const Guid IID = .(0x79184a66, 0x8664, 0x423f, 0x97, 0xf1, 0x63, 0x73, 0x56, 0xa5, 0xd8, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index, ITaskFolder** ppFolder) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT get_Item(VARIANT index, ITaskFolder** ppFolder) mut => VT.[Friend]get_Item(&this, index, ppFolder);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);
}

[CRepr]struct ITaskService : IDispatch
{
	public new const Guid IID = .(0x2faba4c7, 0x4da9, 0x4013, 0x96, 0x97, 0x20, 0xcc, 0x3f, 0xd4, 0x0f, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, ITaskFolder** ppFolder) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flags, IRunningTaskCollection** ppRunningTasks) GetRunningTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, ITaskDefinition** ppDefinition) NewTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT serverName, VARIANT user, VARIANT domain, VARIANT password) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pConnected) get_Connected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pServer) get_TargetServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pUser) get_ConnectedUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDomain) get_ConnectedDomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVersion) get_HighestVersion;
	}


	public HRESULT GetFolder(BSTR path, ITaskFolder** ppFolder) mut => VT.[Friend]GetFolder(&this, path, ppFolder);

	public HRESULT GetRunningTasks(int32 flags, IRunningTaskCollection** ppRunningTasks) mut => VT.[Friend]GetRunningTasks(&this, flags, ppRunningTasks);

	public HRESULT NewTask(uint32 flags, ITaskDefinition** ppDefinition) mut => VT.[Friend]NewTask(&this, flags, ppDefinition);

	public HRESULT Connect(VARIANT serverName, VARIANT user, VARIANT domain, VARIANT password) mut => VT.[Friend]Connect(&this, serverName, user, domain, password);

	public HRESULT get_Connected(int16* pConnected) mut => VT.[Friend]get_Connected(&this, pConnected);

	public HRESULT get_TargetServer(BSTR* pServer) mut => VT.[Friend]get_TargetServer(&this, pServer);

	public HRESULT get_ConnectedUser(BSTR* pUser) mut => VT.[Friend]get_ConnectedUser(&this, pUser);

	public HRESULT get_ConnectedDomain(BSTR* pDomain) mut => VT.[Friend]get_ConnectedDomain(&this, pDomain);

	public HRESULT get_HighestVersion(uint32* pVersion) mut => VT.[Friend]get_HighestVersion(&this, pVersion);
}

[CRepr]struct ITaskHandler : IUnknown
{
	public new const Guid IID = .(0x839d7762, 0x5121, 0x4009, 0x92, 0x34, 0x4f, 0x0d, 0x19, 0x39, 0x4f, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pHandlerServices, BSTR data) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* pRetCode) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
	}


	public HRESULT Start(IUnknown* pHandlerServices, BSTR data) mut => VT.[Friend]Start(&this, pHandlerServices, data);

	public HRESULT Stop(HRESULT* pRetCode) mut => VT.[Friend]Stop(&this, pRetCode);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);
}

[CRepr]struct ITaskHandlerStatus : IUnknown
{
	public new const Guid IID = .(0xeaec7a8f, 0x27a0, 0x4ddc, 0x86, 0x75, 0x14, 0x72, 0x6a, 0x01, 0xa3, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 percentComplete, BSTR statusMessage) UpdateStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT taskErrCode) TaskCompleted;
	}


	public HRESULT UpdateStatus(int16 percentComplete, BSTR statusMessage) mut => VT.[Friend]UpdateStatus(&this, percentComplete, statusMessage);

	public HRESULT TaskCompleted(HRESULT taskErrCode) mut => VT.[Friend]TaskCompleted(&this, taskErrCode);
}

[CRepr]struct ITaskVariables : IUnknown
{
	public new const Guid IID = .(0x3e4c9351, 0xd966, 0x4b8b, 0xbb, 0x87, 0xce, 0xba, 0x68, 0xbb, 0x01, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pInput) GetInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR input) SetOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pContext) GetContext;
	}


	public HRESULT GetInput(BSTR* pInput) mut => VT.[Friend]GetInput(&this, pInput);

	public HRESULT SetOutput(BSTR input) mut => VT.[Friend]SetOutput(&this, input);

	public HRESULT GetContext(BSTR* pContext) mut => VT.[Friend]GetContext(&this, pContext);
}

[CRepr]struct ITaskNamedValuePair : IDispatch
{
	public new const Guid IID = .(0x39038068, 0x2b46, 0x4afd, 0x86, 0x62, 0x7b, 0xb6, 0xf8, 0x68, 0xd2, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR value) put_Value;
	}


	public HRESULT get_Name(BSTR* pName) mut => VT.[Friend]get_Name(&this, pName);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Value(BSTR* pValue) mut => VT.[Friend]get_Value(&this, pValue);

	public HRESULT put_Value(BSTR value) mut => VT.[Friend]put_Value(&this, value);
}

[CRepr]struct ITaskNamedValueCollection : IDispatch
{
	public new const Guid IID = .(0xb4ef826b, 0x63c3, 0x46e4, 0xa5, 0x04, 0xef, 0x69, 0xe4, 0xf7, 0xea, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, ITaskNamedValuePair** ppPair) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, BSTR value, ITaskNamedValuePair** ppPair) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT get_Item(int32 index, ITaskNamedValuePair** ppPair) mut => VT.[Friend]get_Item(&this, index, ppPair);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);

	public HRESULT Create(BSTR name, BSTR value, ITaskNamedValuePair** ppPair) mut => VT.[Friend]Create(&this, name, value, ppPair);

	public HRESULT Remove(int32 index) mut => VT.[Friend]Remove(&this, index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IRunningTask : IDispatch
{
	public new const Guid IID = .(0x653758fb, 0x7b9a, 0x4f1e, 0xa4, 0x71, 0xbe, 0xeb, 0x8e, 0x9b, 0x83, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pGuid) get_InstanceGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pPath) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_STATE* pState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_CurrentAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pPID) get_EnginePID;
	}


	public HRESULT get_Name(BSTR* pName) mut => VT.[Friend]get_Name(&this, pName);

	public HRESULT get_InstanceGuid(BSTR* pGuid) mut => VT.[Friend]get_InstanceGuid(&this, pGuid);

	public HRESULT get_Path(BSTR* pPath) mut => VT.[Friend]get_Path(&this, pPath);

	public HRESULT get_State(TASK_STATE* pState) mut => VT.[Friend]get_State(&this, pState);

	public HRESULT get_CurrentAction(BSTR* pName) mut => VT.[Friend]get_CurrentAction(&this, pName);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_EnginePID(uint32* pPID) mut => VT.[Friend]get_EnginePID(&this, pPID);
}

[CRepr]struct IRunningTaskCollection : IDispatch
{
	public new const Guid IID = .(0x6a67614b, 0x6828, 0x4fec, 0xaa, 0x54, 0x6d, 0x52, 0xe8, 0xf1, 0xf2, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index, IRunningTask** ppRunningTask) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT get_Item(VARIANT index, IRunningTask** ppRunningTask) mut => VT.[Friend]get_Item(&this, index, ppRunningTask);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);
}

[CRepr]struct IRegisteredTask : IDispatch
{
	public new const Guid IID = .(0x9c86f320, 0xdee3, 0x4dd1, 0xb9, 0x72, 0xa3, 0x03, 0xf2, 0x6b, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pPath) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_STATE* pState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT @params, IRunningTask** ppRunningTask) Run;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT @params, int32 flags, int32 sessionID, BSTR user, IRunningTask** ppRunningTask) RunEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flags, IRunningTaskCollection** ppRunningTasks) GetInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pLastRunTime) get_LastRunTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pLastTaskResult) get_LastTaskResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pNumberOfMissedRuns) get_NumberOfMissedRuns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pNextRunTime) get_NextRunTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskDefinition** ppDefinition) get_Definition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pXml) get_Xml;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 securityInformation, BSTR* pSddl) GetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR sddl, int32 flags) SetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flags) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstStart, SYSTEMTIME* pstEnd, uint32* pCount, SYSTEMTIME** pRunTimes) GetRunTimes;
	}


	public HRESULT get_Name(BSTR* pName) mut => VT.[Friend]get_Name(&this, pName);

	public HRESULT get_Path(BSTR* pPath) mut => VT.[Friend]get_Path(&this, pPath);

	public HRESULT get_State(TASK_STATE* pState) mut => VT.[Friend]get_State(&this, pState);

	public HRESULT get_Enabled(int16* pEnabled) mut => VT.[Friend]get_Enabled(&this, pEnabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT Run(VARIANT @params, IRunningTask** ppRunningTask) mut => VT.[Friend]Run(&this, @params, ppRunningTask);

	public HRESULT RunEx(VARIANT @params, int32 flags, int32 sessionID, BSTR user, IRunningTask** ppRunningTask) mut => VT.[Friend]RunEx(&this, @params, flags, sessionID, user, ppRunningTask);

	public HRESULT GetInstances(int32 flags, IRunningTaskCollection** ppRunningTasks) mut => VT.[Friend]GetInstances(&this, flags, ppRunningTasks);

	public HRESULT get_LastRunTime(double* pLastRunTime) mut => VT.[Friend]get_LastRunTime(&this, pLastRunTime);

	public HRESULT get_LastTaskResult(int32* pLastTaskResult) mut => VT.[Friend]get_LastTaskResult(&this, pLastTaskResult);

	public HRESULT get_NumberOfMissedRuns(int32* pNumberOfMissedRuns) mut => VT.[Friend]get_NumberOfMissedRuns(&this, pNumberOfMissedRuns);

	public HRESULT get_NextRunTime(double* pNextRunTime) mut => VT.[Friend]get_NextRunTime(&this, pNextRunTime);

	public HRESULT get_Definition(ITaskDefinition** ppDefinition) mut => VT.[Friend]get_Definition(&this, ppDefinition);

	public HRESULT get_Xml(BSTR* pXml) mut => VT.[Friend]get_Xml(&this, pXml);

	public HRESULT GetSecurityDescriptor(int32 securityInformation, BSTR* pSddl) mut => VT.[Friend]GetSecurityDescriptor(&this, securityInformation, pSddl);

	public HRESULT SetSecurityDescriptor(BSTR sddl, int32 flags) mut => VT.[Friend]SetSecurityDescriptor(&this, sddl, flags);

	public HRESULT Stop(int32 flags) mut => VT.[Friend]Stop(&this, flags);

	public HRESULT GetRunTimes(SYSTEMTIME* pstStart, SYSTEMTIME* pstEnd, uint32* pCount, SYSTEMTIME** pRunTimes) mut => VT.[Friend]GetRunTimes(&this, pstStart, pstEnd, pCount, pRunTimes);
}

[CRepr]struct ITrigger : IDispatch
{
	public new const Guid IID = .(0x09941815, 0xea89, 0x4b5b, 0x89, 0xe0, 0x2a, 0x77, 0x38, 0x01, 0xfa, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_TRIGGER_TYPE2* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR id) put_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRepetitionPattern** ppRepeat) get_Repetition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRepetitionPattern* pRepeat) put_Repetition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pTimeLimit) get_ExecutionTimeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR timelimit) put_ExecutionTimeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pStart) get_StartBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR start) put_StartBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pEnd) get_EndBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR end) put_EndBoundary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
	}


	public HRESULT get_Type(TASK_TRIGGER_TYPE2* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT get_Id(BSTR* pId) mut => VT.[Friend]get_Id(&this, pId);

	public HRESULT put_Id(BSTR id) mut => VT.[Friend]put_Id(&this, id);

	public HRESULT get_Repetition(IRepetitionPattern** ppRepeat) mut => VT.[Friend]get_Repetition(&this, ppRepeat);

	public HRESULT put_Repetition(IRepetitionPattern* pRepeat) mut => VT.[Friend]put_Repetition(&this, pRepeat);

	public HRESULT get_ExecutionTimeLimit(BSTR* pTimeLimit) mut => VT.[Friend]get_ExecutionTimeLimit(&this, pTimeLimit);

	public HRESULT put_ExecutionTimeLimit(BSTR timelimit) mut => VT.[Friend]put_ExecutionTimeLimit(&this, timelimit);

	public HRESULT get_StartBoundary(BSTR* pStart) mut => VT.[Friend]get_StartBoundary(&this, pStart);

	public HRESULT put_StartBoundary(BSTR start) mut => VT.[Friend]put_StartBoundary(&this, start);

	public HRESULT get_EndBoundary(BSTR* pEnd) mut => VT.[Friend]get_EndBoundary(&this, pEnd);

	public HRESULT put_EndBoundary(BSTR end) mut => VT.[Friend]put_EndBoundary(&this, end);

	public HRESULT get_Enabled(int16* pEnabled) mut => VT.[Friend]get_Enabled(&this, pEnabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);
}

[CRepr]struct IIdleTrigger : ITrigger
{
	public new const Guid IID = .(0xd537d2b0, 0x9fb3, 0x4d34, 0x97, 0x39, 0x1f, 0xf5, 0xce, 0x7b, 0x1e, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
	}

}

[CRepr]struct ILogonTrigger : ITrigger
{
	public new const Guid IID = .(0x72dade38, 0xfae4, 0x4b3e, 0xba, 0xf4, 0x5d, 0x00, 0x9a, 0xf0, 0x2b, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDelay) get_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR delay) put_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pUser) get_UserId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR user) put_UserId;
	}


	public HRESULT get_Delay(BSTR* pDelay) mut => VT.[Friend]get_Delay(&this, pDelay);

	public HRESULT put_Delay(BSTR delay) mut => VT.[Friend]put_Delay(&this, delay);

	public HRESULT get_UserId(BSTR* pUser) mut => VT.[Friend]get_UserId(&this, pUser);

	public HRESULT put_UserId(BSTR user) mut => VT.[Friend]put_UserId(&this, user);
}

[CRepr]struct ISessionStateChangeTrigger : ITrigger
{
	public new const Guid IID = .(0x754da71b, 0x4385, 0x4475, 0x9d, 0xd9, 0x59, 0x82, 0x94, 0xfa, 0x36, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDelay) get_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR delay) put_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pUser) get_UserId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR user) put_UserId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_SESSION_STATE_CHANGE_TYPE* pType) get_StateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_SESSION_STATE_CHANGE_TYPE type) put_StateChange;
	}


	public HRESULT get_Delay(BSTR* pDelay) mut => VT.[Friend]get_Delay(&this, pDelay);

	public HRESULT put_Delay(BSTR delay) mut => VT.[Friend]put_Delay(&this, delay);

	public HRESULT get_UserId(BSTR* pUser) mut => VT.[Friend]get_UserId(&this, pUser);

	public HRESULT put_UserId(BSTR user) mut => VT.[Friend]put_UserId(&this, user);

	public HRESULT get_StateChange(TASK_SESSION_STATE_CHANGE_TYPE* pType) mut => VT.[Friend]get_StateChange(&this, pType);

	public HRESULT put_StateChange(TASK_SESSION_STATE_CHANGE_TYPE type) mut => VT.[Friend]put_StateChange(&this, type);
}

[CRepr]struct IEventTrigger : ITrigger
{
	public new const Guid IID = .(0xd45b0167, 0x9653, 0x4eef, 0xb9, 0x4f, 0x07, 0x32, 0xca, 0x7a, 0xf2, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pQuery) get_Subscription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR query) put_Subscription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDelay) get_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR delay) put_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskNamedValueCollection** ppNamedXPaths) get_ValueQueries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskNamedValueCollection* pNamedXPaths) put_ValueQueries;
	}


	public HRESULT get_Subscription(BSTR* pQuery) mut => VT.[Friend]get_Subscription(&this, pQuery);

	public HRESULT put_Subscription(BSTR query) mut => VT.[Friend]put_Subscription(&this, query);

	public HRESULT get_Delay(BSTR* pDelay) mut => VT.[Friend]get_Delay(&this, pDelay);

	public HRESULT put_Delay(BSTR delay) mut => VT.[Friend]put_Delay(&this, delay);

	public HRESULT get_ValueQueries(ITaskNamedValueCollection** ppNamedXPaths) mut => VT.[Friend]get_ValueQueries(&this, ppNamedXPaths);

	public HRESULT put_ValueQueries(ITaskNamedValueCollection* pNamedXPaths) mut => VT.[Friend]put_ValueQueries(&this, pNamedXPaths);
}

[CRepr]struct ITimeTrigger : ITrigger
{
	public new const Guid IID = .(0xb45747e0, 0xeba7, 0x4276, 0x9f, 0x29, 0x85, 0xc5, 0xbb, 0x30, 0x00, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRandomDelay) get_RandomDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR randomDelay) put_RandomDelay;
	}


	public HRESULT get_RandomDelay(BSTR* pRandomDelay) mut => VT.[Friend]get_RandomDelay(&this, pRandomDelay);

	public HRESULT put_RandomDelay(BSTR randomDelay) mut => VT.[Friend]put_RandomDelay(&this, randomDelay);
}

[CRepr]struct IDailyTrigger : ITrigger
{
	public new const Guid IID = .(0x126c5cd8, 0xb288, 0x41d5, 0x8d, 0xbf, 0xe4, 0x91, 0x44, 0x6a, 0xdc, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pDays) get_DaysInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 days) put_DaysInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRandomDelay) get_RandomDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR randomDelay) put_RandomDelay;
	}


	public HRESULT get_DaysInterval(int16* pDays) mut => VT.[Friend]get_DaysInterval(&this, pDays);

	public HRESULT put_DaysInterval(int16 days) mut => VT.[Friend]put_DaysInterval(&this, days);

	public HRESULT get_RandomDelay(BSTR* pRandomDelay) mut => VT.[Friend]get_RandomDelay(&this, pRandomDelay);

	public HRESULT put_RandomDelay(BSTR randomDelay) mut => VT.[Friend]put_RandomDelay(&this, randomDelay);
}

[CRepr]struct IWeeklyTrigger : ITrigger
{
	public new const Guid IID = .(0x5038fc98, 0x82ff, 0x436d, 0x87, 0x28, 0xa5, 0x12, 0xa5, 0x7c, 0x9d, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pDays) get_DaysOfWeek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 days) put_DaysOfWeek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pWeeks) get_WeeksInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 weeks) put_WeeksInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRandomDelay) get_RandomDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR randomDelay) put_RandomDelay;
	}


	public HRESULT get_DaysOfWeek(int16* pDays) mut => VT.[Friend]get_DaysOfWeek(&this, pDays);

	public HRESULT put_DaysOfWeek(int16 days) mut => VT.[Friend]put_DaysOfWeek(&this, days);

	public HRESULT get_WeeksInterval(int16* pWeeks) mut => VT.[Friend]get_WeeksInterval(&this, pWeeks);

	public HRESULT put_WeeksInterval(int16 weeks) mut => VT.[Friend]put_WeeksInterval(&this, weeks);

	public HRESULT get_RandomDelay(BSTR* pRandomDelay) mut => VT.[Friend]get_RandomDelay(&this, pRandomDelay);

	public HRESULT put_RandomDelay(BSTR randomDelay) mut => VT.[Friend]put_RandomDelay(&this, randomDelay);
}

[CRepr]struct IMonthlyTrigger : ITrigger
{
	public new const Guid IID = .(0x97c45ef1, 0x6b02, 0x4a1a, 0x9c, 0x0e, 0x1e, 0xbf, 0xba, 0x15, 0x00, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pDays) get_DaysOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 days) put_DaysOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pMonths) get_MonthsOfYear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 months) put_MonthsOfYear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pLastDay) get_RunOnLastDayOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 lastDay) put_RunOnLastDayOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRandomDelay) get_RandomDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR randomDelay) put_RandomDelay;
	}


	public HRESULT get_DaysOfMonth(int32* pDays) mut => VT.[Friend]get_DaysOfMonth(&this, pDays);

	public HRESULT put_DaysOfMonth(int32 days) mut => VT.[Friend]put_DaysOfMonth(&this, days);

	public HRESULT get_MonthsOfYear(int16* pMonths) mut => VT.[Friend]get_MonthsOfYear(&this, pMonths);

	public HRESULT put_MonthsOfYear(int16 months) mut => VT.[Friend]put_MonthsOfYear(&this, months);

	public HRESULT get_RunOnLastDayOfMonth(int16* pLastDay) mut => VT.[Friend]get_RunOnLastDayOfMonth(&this, pLastDay);

	public HRESULT put_RunOnLastDayOfMonth(int16 lastDay) mut => VT.[Friend]put_RunOnLastDayOfMonth(&this, lastDay);

	public HRESULT get_RandomDelay(BSTR* pRandomDelay) mut => VT.[Friend]get_RandomDelay(&this, pRandomDelay);

	public HRESULT put_RandomDelay(BSTR randomDelay) mut => VT.[Friend]put_RandomDelay(&this, randomDelay);
}

[CRepr]struct IMonthlyDOWTrigger : ITrigger
{
	public new const Guid IID = .(0x77d025a3, 0x90fa, 0x43aa, 0xb5, 0x2e, 0xcd, 0xa5, 0x49, 0x9b, 0x94, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pDays) get_DaysOfWeek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 days) put_DaysOfWeek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pWeeks) get_WeeksOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 weeks) put_WeeksOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pMonths) get_MonthsOfYear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 months) put_MonthsOfYear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pLastWeek) get_RunOnLastWeekOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 lastWeek) put_RunOnLastWeekOfMonth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRandomDelay) get_RandomDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR randomDelay) put_RandomDelay;
	}


	public HRESULT get_DaysOfWeek(int16* pDays) mut => VT.[Friend]get_DaysOfWeek(&this, pDays);

	public HRESULT put_DaysOfWeek(int16 days) mut => VT.[Friend]put_DaysOfWeek(&this, days);

	public HRESULT get_WeeksOfMonth(int16* pWeeks) mut => VT.[Friend]get_WeeksOfMonth(&this, pWeeks);

	public HRESULT put_WeeksOfMonth(int16 weeks) mut => VT.[Friend]put_WeeksOfMonth(&this, weeks);

	public HRESULT get_MonthsOfYear(int16* pMonths) mut => VT.[Friend]get_MonthsOfYear(&this, pMonths);

	public HRESULT put_MonthsOfYear(int16 months) mut => VT.[Friend]put_MonthsOfYear(&this, months);

	public HRESULT get_RunOnLastWeekOfMonth(int16* pLastWeek) mut => VT.[Friend]get_RunOnLastWeekOfMonth(&this, pLastWeek);

	public HRESULT put_RunOnLastWeekOfMonth(int16 lastWeek) mut => VT.[Friend]put_RunOnLastWeekOfMonth(&this, lastWeek);

	public HRESULT get_RandomDelay(BSTR* pRandomDelay) mut => VT.[Friend]get_RandomDelay(&this, pRandomDelay);

	public HRESULT put_RandomDelay(BSTR randomDelay) mut => VT.[Friend]put_RandomDelay(&this, randomDelay);
}

[CRepr]struct IBootTrigger : ITrigger
{
	public new const Guid IID = .(0x2a9c35da, 0xd357, 0x41f4, 0xbb, 0xc1, 0x20, 0x7a, 0xc1, 0xb1, 0xf3, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDelay) get_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR delay) put_Delay;
	}


	public HRESULT get_Delay(BSTR* pDelay) mut => VT.[Friend]get_Delay(&this, pDelay);

	public HRESULT put_Delay(BSTR delay) mut => VT.[Friend]put_Delay(&this, delay);
}

[CRepr]struct IRegistrationTrigger : ITrigger
{
	public new const Guid IID = .(0x4c8fec3a, 0xc218, 0x4e0c, 0xb2, 0x3d, 0x62, 0x90, 0x24, 0xdb, 0x91, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITrigger.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDelay) get_Delay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR delay) put_Delay;
	}


	public HRESULT get_Delay(BSTR* pDelay) mut => VT.[Friend]get_Delay(&this, pDelay);

	public HRESULT put_Delay(BSTR delay) mut => VT.[Friend]put_Delay(&this, delay);
}

[CRepr]struct IAction : IDispatch
{
	public new const Guid IID = .(0xbae54997, 0x48b1, 0x4cbe, 0x99, 0x65, 0xd6, 0xbe, 0x26, 0x3e, 0xbe, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Id) put_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_ACTION_TYPE* pType) get_Type;
	}


	public HRESULT get_Id(BSTR* pId) mut => VT.[Friend]get_Id(&this, pId);

	public HRESULT put_Id(BSTR Id) mut => VT.[Friend]put_Id(&this, Id);

	public HRESULT get_Type(TASK_ACTION_TYPE* pType) mut => VT.[Friend]get_Type(&this, pType);
}

[CRepr]struct IExecAction : IAction
{
	public new const Guid IID = .(0x4c3d624d, 0xfd6b, 0x49a3, 0xb9, 0xb7, 0x09, 0xcb, 0x3c, 0xd3, 0xf0, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pPath) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) put_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pArgument) get_Arguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR argument) put_Arguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pWorkingDirectory) get_WorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR workingDirectory) put_WorkingDirectory;
	}


	public HRESULT get_Path(BSTR* pPath) mut => VT.[Friend]get_Path(&this, pPath);

	public HRESULT put_Path(BSTR path) mut => VT.[Friend]put_Path(&this, path);

	public HRESULT get_Arguments(BSTR* pArgument) mut => VT.[Friend]get_Arguments(&this, pArgument);

	public HRESULT put_Arguments(BSTR argument) mut => VT.[Friend]put_Arguments(&this, argument);

	public HRESULT get_WorkingDirectory(BSTR* pWorkingDirectory) mut => VT.[Friend]get_WorkingDirectory(&this, pWorkingDirectory);

	public HRESULT put_WorkingDirectory(BSTR workingDirectory) mut => VT.[Friend]put_WorkingDirectory(&this, workingDirectory);
}

[CRepr]struct IExecAction2 : IExecAction
{
	public new const Guid IID = .(0xf2a82542, 0xbda5, 0x4e6b, 0x91, 0x43, 0xe2, 0xbf, 0x4f, 0x89, 0x87, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IExecAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pHideAppWindow) get_HideAppWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 hideAppWindow) put_HideAppWindow;
	}


	public HRESULT get_HideAppWindow(int16* pHideAppWindow) mut => VT.[Friend]get_HideAppWindow(&this, pHideAppWindow);

	public HRESULT put_HideAppWindow(int16 hideAppWindow) mut => VT.[Friend]put_HideAppWindow(&this, hideAppWindow);
}

[CRepr]struct IShowMessageAction : IAction
{
	public new const Guid IID = .(0x505e9e68, 0xaf89, 0x46b8, 0xa3, 0x0f, 0x56, 0x16, 0x2a, 0x83, 0xd5, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pTitle) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR title) put_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pMessageBody) get_MessageBody;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR messageBody) put_MessageBody;
	}


	public HRESULT get_Title(BSTR* pTitle) mut => VT.[Friend]get_Title(&this, pTitle);

	public HRESULT put_Title(BSTR title) mut => VT.[Friend]put_Title(&this, title);

	public HRESULT get_MessageBody(BSTR* pMessageBody) mut => VT.[Friend]get_MessageBody(&this, pMessageBody);

	public HRESULT put_MessageBody(BSTR messageBody) mut => VT.[Friend]put_MessageBody(&this, messageBody);
}

[CRepr]struct IComHandlerAction : IAction
{
	public new const Guid IID = .(0x6d2fd252, 0x75c5, 0x4f66, 0x90, 0xba, 0x2a, 0x7d, 0x8c, 0xc3, 0x03, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pClsid) get_ClassId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR clsid) put_ClassId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pData) get_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR data) put_Data;
	}


	public HRESULT get_ClassId(BSTR* pClsid) mut => VT.[Friend]get_ClassId(&this, pClsid);

	public HRESULT put_ClassId(BSTR clsid) mut => VT.[Friend]put_ClassId(&this, clsid);

	public HRESULT get_Data(BSTR* pData) mut => VT.[Friend]get_Data(&this, pData);

	public HRESULT put_Data(BSTR data) mut => VT.[Friend]put_Data(&this, data);
}

[CRepr]struct IEmailAction : IAction
{
	public new const Guid IID = .(0x10f62c64, 0x7e16, 0x4314, 0xa0, 0xc2, 0x0c, 0x36, 0x83, 0xf9, 0x9d, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pServer) get_Server;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR server) put_Server;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pSubject) get_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR subject) put_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pTo) get_To;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR to) put_To;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pCc) get_Cc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR cc) put_Cc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBcc) get_Bcc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bcc) put_Bcc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pReplyTo) get_ReplyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR replyTo) put_ReplyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pFrom) get_From;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR from) put_From;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskNamedValueCollection** ppHeaderFields) get_HeaderFields;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskNamedValueCollection* pHeaderFields) put_HeaderFields;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBody) get_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR body) put_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pAttachements) get_Attachments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* pAttachements) put_Attachments;
	}


	public HRESULT get_Server(BSTR* pServer) mut => VT.[Friend]get_Server(&this, pServer);

	public HRESULT put_Server(BSTR server) mut => VT.[Friend]put_Server(&this, server);

	public HRESULT get_Subject(BSTR* pSubject) mut => VT.[Friend]get_Subject(&this, pSubject);

	public HRESULT put_Subject(BSTR subject) mut => VT.[Friend]put_Subject(&this, subject);

	public HRESULT get_To(BSTR* pTo) mut => VT.[Friend]get_To(&this, pTo);

	public HRESULT put_To(BSTR to) mut => VT.[Friend]put_To(&this, to);

	public HRESULT get_Cc(BSTR* pCc) mut => VT.[Friend]get_Cc(&this, pCc);

	public HRESULT put_Cc(BSTR cc) mut => VT.[Friend]put_Cc(&this, cc);

	public HRESULT get_Bcc(BSTR* pBcc) mut => VT.[Friend]get_Bcc(&this, pBcc);

	public HRESULT put_Bcc(BSTR bcc) mut => VT.[Friend]put_Bcc(&this, bcc);

	public HRESULT get_ReplyTo(BSTR* pReplyTo) mut => VT.[Friend]get_ReplyTo(&this, pReplyTo);

	public HRESULT put_ReplyTo(BSTR replyTo) mut => VT.[Friend]put_ReplyTo(&this, replyTo);

	public HRESULT get_From(BSTR* pFrom) mut => VT.[Friend]get_From(&this, pFrom);

	public HRESULT put_From(BSTR from) mut => VT.[Friend]put_From(&this, from);

	public HRESULT get_HeaderFields(ITaskNamedValueCollection** ppHeaderFields) mut => VT.[Friend]get_HeaderFields(&this, ppHeaderFields);

	public HRESULT put_HeaderFields(ITaskNamedValueCollection* pHeaderFields) mut => VT.[Friend]put_HeaderFields(&this, pHeaderFields);

	public HRESULT get_Body(BSTR* pBody) mut => VT.[Friend]get_Body(&this, pBody);

	public HRESULT put_Body(BSTR body) mut => VT.[Friend]put_Body(&this, body);

	public HRESULT get_Attachments(SAFEARRAY** pAttachements) mut => VT.[Friend]get_Attachments(&this, pAttachements);

	public HRESULT put_Attachments(SAFEARRAY* pAttachements) mut => VT.[Friend]put_Attachments(&this, pAttachements);
}

[CRepr]struct ITriggerCollection : IDispatch
{
	public new const Guid IID = .(0x85df5081, 0x1b24, 0x4f32, 0x87, 0x8a, 0xd9, 0xd1, 0x4d, 0xf4, 0xcb, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, ITrigger** ppTrigger) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_TRIGGER_TYPE2 type, ITrigger** ppTrigger) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT get_Item(int32 index, ITrigger** ppTrigger) mut => VT.[Friend]get_Item(&this, index, ppTrigger);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);

	public HRESULT Create(TASK_TRIGGER_TYPE2 type, ITrigger** ppTrigger) mut => VT.[Friend]Create(&this, type, ppTrigger);

	public HRESULT Remove(VARIANT index) mut => VT.[Friend]Remove(&this, index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IActionCollection : IDispatch
{
	public new const Guid IID = .(0x02820e19, 0x7b98, 0x4ed2, 0xb2, 0xe8, 0xfd, 0xcc, 0xce, 0xff, 0x61, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, IAction** ppAction) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pText) get_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR text) put_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_ACTION_TYPE type, IAction** ppAction) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pContext) get_Context;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR context) put_Context;
	}


	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT get_Item(int32 index, IAction** ppAction) mut => VT.[Friend]get_Item(&this, index, ppAction);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);

	public HRESULT get_XmlText(BSTR* pText) mut => VT.[Friend]get_XmlText(&this, pText);

	public HRESULT put_XmlText(BSTR text) mut => VT.[Friend]put_XmlText(&this, text);

	public HRESULT Create(TASK_ACTION_TYPE type, IAction** ppAction) mut => VT.[Friend]Create(&this, type, ppAction);

	public HRESULT Remove(VARIANT index) mut => VT.[Friend]Remove(&this, index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_Context(BSTR* pContext) mut => VT.[Friend]get_Context(&this, pContext);

	public HRESULT put_Context(BSTR context) mut => VT.[Friend]put_Context(&this, context);
}

[CRepr]struct IPrincipal : IDispatch
{
	public new const Guid IID = .(0xd98d51e5, 0xc9b4, 0x496a, 0xa9, 0xc1, 0x18, 0x98, 0x02, 0x61, 0xcf, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Id) put_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pUser) get_UserId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR user) put_UserId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_LOGON_TYPE* pLogon) get_LogonType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_LOGON_TYPE logon) put_LogonType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pGroup) get_GroupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR group) put_GroupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_RUNLEVEL_TYPE* pRunLevel) get_RunLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_RUNLEVEL_TYPE runLevel) put_RunLevel;
	}


	public HRESULT get_Id(BSTR* pId) mut => VT.[Friend]get_Id(&this, pId);

	public HRESULT put_Id(BSTR Id) mut => VT.[Friend]put_Id(&this, Id);

	public HRESULT get_DisplayName(BSTR* pName) mut => VT.[Friend]get_DisplayName(&this, pName);

	public HRESULT put_DisplayName(BSTR name) mut => VT.[Friend]put_DisplayName(&this, name);

	public HRESULT get_UserId(BSTR* pUser) mut => VT.[Friend]get_UserId(&this, pUser);

	public HRESULT put_UserId(BSTR user) mut => VT.[Friend]put_UserId(&this, user);

	public HRESULT get_LogonType(TASK_LOGON_TYPE* pLogon) mut => VT.[Friend]get_LogonType(&this, pLogon);

	public HRESULT put_LogonType(TASK_LOGON_TYPE logon) mut => VT.[Friend]put_LogonType(&this, logon);

	public HRESULT get_GroupId(BSTR* pGroup) mut => VT.[Friend]get_GroupId(&this, pGroup);

	public HRESULT put_GroupId(BSTR group) mut => VT.[Friend]put_GroupId(&this, group);

	public HRESULT get_RunLevel(TASK_RUNLEVEL_TYPE* pRunLevel) mut => VT.[Friend]get_RunLevel(&this, pRunLevel);

	public HRESULT put_RunLevel(TASK_RUNLEVEL_TYPE runLevel) mut => VT.[Friend]put_RunLevel(&this, runLevel);
}

[CRepr]struct IPrincipal2 : IDispatch
{
	public new const Guid IID = .(0x248919ae, 0xe345, 0x4a6d, 0x8a, 0xeb, 0xe0, 0xd3, 0x16, 0x5c, 0x90, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_PROCESSTOKENSID_TYPE* pProcessTokenSidType) get_ProcessTokenSidType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_PROCESSTOKENSID_TYPE processTokenSidType) put_ProcessTokenSidType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_RequiredPrivilegeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, BSTR* pPrivilege) get_RequiredPrivilege;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR privilege) AddRequiredPrivilege;
	}


	public HRESULT get_ProcessTokenSidType(TASK_PROCESSTOKENSID_TYPE* pProcessTokenSidType) mut => VT.[Friend]get_ProcessTokenSidType(&this, pProcessTokenSidType);

	public HRESULT put_ProcessTokenSidType(TASK_PROCESSTOKENSID_TYPE processTokenSidType) mut => VT.[Friend]put_ProcessTokenSidType(&this, processTokenSidType);

	public HRESULT get_RequiredPrivilegeCount(int32* pCount) mut => VT.[Friend]get_RequiredPrivilegeCount(&this, pCount);

	public HRESULT get_RequiredPrivilege(int32 index, BSTR* pPrivilege) mut => VT.[Friend]get_RequiredPrivilege(&this, index, pPrivilege);

	public HRESULT AddRequiredPrivilege(BSTR privilege) mut => VT.[Friend]AddRequiredPrivilege(&this, privilege);
}

[CRepr]struct IRegistrationInfo : IDispatch
{
	public new const Guid IID = .(0x416d8b73, 0xcb41, 0x4ea1, 0x80, 0x5c, 0x9b, 0xe9, 0xa5, 0xac, 0x4a, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR description) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pAuthor) get_Author;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR author) put_Author;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVersion) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR version) put_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDate) get_Date;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR date) put_Date;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDocumentation) get_Documentation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR documentation) put_Documentation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pText) get_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR text) put_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pUri) get_URI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR uri) put_URI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pSddl) get_SecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT sddl) put_SecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pSource) get_Source;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR source) put_Source;
	}


	public HRESULT get_Description(BSTR* pDescription) mut => VT.[Friend]get_Description(&this, pDescription);

	public HRESULT put_Description(BSTR description) mut => VT.[Friend]put_Description(&this, description);

	public HRESULT get_Author(BSTR* pAuthor) mut => VT.[Friend]get_Author(&this, pAuthor);

	public HRESULT put_Author(BSTR author) mut => VT.[Friend]put_Author(&this, author);

	public HRESULT get_Version(BSTR* pVersion) mut => VT.[Friend]get_Version(&this, pVersion);

	public HRESULT put_Version(BSTR version) mut => VT.[Friend]put_Version(&this, version);

	public HRESULT get_Date(BSTR* pDate) mut => VT.[Friend]get_Date(&this, pDate);

	public HRESULT put_Date(BSTR date) mut => VT.[Friend]put_Date(&this, date);

	public HRESULT get_Documentation(BSTR* pDocumentation) mut => VT.[Friend]get_Documentation(&this, pDocumentation);

	public HRESULT put_Documentation(BSTR documentation) mut => VT.[Friend]put_Documentation(&this, documentation);

	public HRESULT get_XmlText(BSTR* pText) mut => VT.[Friend]get_XmlText(&this, pText);

	public HRESULT put_XmlText(BSTR text) mut => VT.[Friend]put_XmlText(&this, text);

	public HRESULT get_URI(BSTR* pUri) mut => VT.[Friend]get_URI(&this, pUri);

	public HRESULT put_URI(BSTR uri) mut => VT.[Friend]put_URI(&this, uri);

	public HRESULT get_SecurityDescriptor(VARIANT* pSddl) mut => VT.[Friend]get_SecurityDescriptor(&this, pSddl);

	public HRESULT put_SecurityDescriptor(VARIANT sddl) mut => VT.[Friend]put_SecurityDescriptor(&this, sddl);

	public HRESULT get_Source(BSTR* pSource) mut => VT.[Friend]get_Source(&this, pSource);

	public HRESULT put_Source(BSTR source) mut => VT.[Friend]put_Source(&this, source);
}

[CRepr]struct ITaskDefinition : IDispatch
{
	public new const Guid IID = .(0xf5bc8fc5, 0x536d, 0x4f77, 0xb8, 0x52, 0xfb, 0xc1, 0x35, 0x6f, 0xde, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRegistrationInfo** ppRegistrationInfo) get_RegistrationInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRegistrationInfo* pRegistrationInfo) put_RegistrationInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITriggerCollection** ppTriggers) get_Triggers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITriggerCollection* pTriggers) put_Triggers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskSettings** ppSettings) get_Settings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITaskSettings* pSettings) put_Settings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pData) get_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR data) put_Data;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrincipal** ppPrincipal) get_Principal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrincipal* pPrincipal) put_Principal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IActionCollection** ppActions) get_Actions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IActionCollection* pActions) put_Actions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pXml) get_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR xml) put_XmlText;
	}


	public HRESULT get_RegistrationInfo(IRegistrationInfo** ppRegistrationInfo) mut => VT.[Friend]get_RegistrationInfo(&this, ppRegistrationInfo);

	public HRESULT put_RegistrationInfo(IRegistrationInfo* pRegistrationInfo) mut => VT.[Friend]put_RegistrationInfo(&this, pRegistrationInfo);

	public HRESULT get_Triggers(ITriggerCollection** ppTriggers) mut => VT.[Friend]get_Triggers(&this, ppTriggers);

	public HRESULT put_Triggers(ITriggerCollection* pTriggers) mut => VT.[Friend]put_Triggers(&this, pTriggers);

	public HRESULT get_Settings(ITaskSettings** ppSettings) mut => VT.[Friend]get_Settings(&this, ppSettings);

	public HRESULT put_Settings(ITaskSettings* pSettings) mut => VT.[Friend]put_Settings(&this, pSettings);

	public HRESULT get_Data(BSTR* pData) mut => VT.[Friend]get_Data(&this, pData);

	public HRESULT put_Data(BSTR data) mut => VT.[Friend]put_Data(&this, data);

	public HRESULT get_Principal(IPrincipal** ppPrincipal) mut => VT.[Friend]get_Principal(&this, ppPrincipal);

	public HRESULT put_Principal(IPrincipal* pPrincipal) mut => VT.[Friend]put_Principal(&this, pPrincipal);

	public HRESULT get_Actions(IActionCollection** ppActions) mut => VT.[Friend]get_Actions(&this, ppActions);

	public HRESULT put_Actions(IActionCollection* pActions) mut => VT.[Friend]put_Actions(&this, pActions);

	public HRESULT get_XmlText(BSTR* pXml) mut => VT.[Friend]get_XmlText(&this, pXml);

	public HRESULT put_XmlText(BSTR xml) mut => VT.[Friend]put_XmlText(&this, xml);
}

[CRepr]struct ITaskSettings : IDispatch
{
	public new const Guid IID = .(0x8fd4711d, 0x2d02, 0x4c8c, 0x87, 0xe3, 0xef, 0xf6, 0x99, 0xde, 0x12, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pAllowDemandStart) get_AllowDemandStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allowDemandStart) put_AllowDemandStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRestartInterval) get_RestartInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR restartInterval) put_RestartInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRestartCount) get_RestartCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 restartCount) put_RestartCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_INSTANCES_POLICY* pPolicy) get_MultipleInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_INSTANCES_POLICY policy) put_MultipleInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pStopIfOnBatteries) get_StopIfGoingOnBatteries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 stopIfOnBatteries) put_StopIfGoingOnBatteries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pDisallowStart) get_DisallowStartIfOnBatteries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 disallowStart) put_DisallowStartIfOnBatteries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pAllowHardTerminate) get_AllowHardTerminate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allowHardTerminate) put_AllowHardTerminate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pStartWhenAvailable) get_StartWhenAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 startWhenAvailable) put_StartWhenAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pText) get_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR text) put_XmlText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRunOnlyIfNetworkAvailable) get_RunOnlyIfNetworkAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 runOnlyIfNetworkAvailable) put_RunOnlyIfNetworkAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pExecutionTimeLimit) get_ExecutionTimeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR executionTimeLimit) put_ExecutionTimeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pExpirationDelay) get_DeleteExpiredTaskAfter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR expirationDelay) put_DeleteExpiredTaskAfter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 priority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_COMPATIBILITY* pCompatLevel) get_Compatibility;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TASK_COMPATIBILITY compatLevel) put_Compatibility;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pHidden) get_Hidden;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 hidden) put_Hidden;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IIdleSettings** ppIdleSettings) get_IdleSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IIdleSettings* pIdleSettings) put_IdleSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRunOnlyIfIdle) get_RunOnlyIfIdle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 runOnlyIfIdle) put_RunOnlyIfIdle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pWake) get_WakeToRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 wake) put_WakeToRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetworkSettings** ppNetworkSettings) get_NetworkSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetworkSettings* pNetworkSettings) put_NetworkSettings;
	}


	public HRESULT get_AllowDemandStart(int16* pAllowDemandStart) mut => VT.[Friend]get_AllowDemandStart(&this, pAllowDemandStart);

	public HRESULT put_AllowDemandStart(int16 allowDemandStart) mut => VT.[Friend]put_AllowDemandStart(&this, allowDemandStart);

	public HRESULT get_RestartInterval(BSTR* pRestartInterval) mut => VT.[Friend]get_RestartInterval(&this, pRestartInterval);

	public HRESULT put_RestartInterval(BSTR restartInterval) mut => VT.[Friend]put_RestartInterval(&this, restartInterval);

	public HRESULT get_RestartCount(int32* pRestartCount) mut => VT.[Friend]get_RestartCount(&this, pRestartCount);

	public HRESULT put_RestartCount(int32 restartCount) mut => VT.[Friend]put_RestartCount(&this, restartCount);

	public HRESULT get_MultipleInstances(TASK_INSTANCES_POLICY* pPolicy) mut => VT.[Friend]get_MultipleInstances(&this, pPolicy);

	public HRESULT put_MultipleInstances(TASK_INSTANCES_POLICY policy) mut => VT.[Friend]put_MultipleInstances(&this, policy);

	public HRESULT get_StopIfGoingOnBatteries(int16* pStopIfOnBatteries) mut => VT.[Friend]get_StopIfGoingOnBatteries(&this, pStopIfOnBatteries);

	public HRESULT put_StopIfGoingOnBatteries(int16 stopIfOnBatteries) mut => VT.[Friend]put_StopIfGoingOnBatteries(&this, stopIfOnBatteries);

	public HRESULT get_DisallowStartIfOnBatteries(int16* pDisallowStart) mut => VT.[Friend]get_DisallowStartIfOnBatteries(&this, pDisallowStart);

	public HRESULT put_DisallowStartIfOnBatteries(int16 disallowStart) mut => VT.[Friend]put_DisallowStartIfOnBatteries(&this, disallowStart);

	public HRESULT get_AllowHardTerminate(int16* pAllowHardTerminate) mut => VT.[Friend]get_AllowHardTerminate(&this, pAllowHardTerminate);

	public HRESULT put_AllowHardTerminate(int16 allowHardTerminate) mut => VT.[Friend]put_AllowHardTerminate(&this, allowHardTerminate);

	public HRESULT get_StartWhenAvailable(int16* pStartWhenAvailable) mut => VT.[Friend]get_StartWhenAvailable(&this, pStartWhenAvailable);

	public HRESULT put_StartWhenAvailable(int16 startWhenAvailable) mut => VT.[Friend]put_StartWhenAvailable(&this, startWhenAvailable);

	public HRESULT get_XmlText(BSTR* pText) mut => VT.[Friend]get_XmlText(&this, pText);

	public HRESULT put_XmlText(BSTR text) mut => VT.[Friend]put_XmlText(&this, text);

	public HRESULT get_RunOnlyIfNetworkAvailable(int16* pRunOnlyIfNetworkAvailable) mut => VT.[Friend]get_RunOnlyIfNetworkAvailable(&this, pRunOnlyIfNetworkAvailable);

	public HRESULT put_RunOnlyIfNetworkAvailable(int16 runOnlyIfNetworkAvailable) mut => VT.[Friend]put_RunOnlyIfNetworkAvailable(&this, runOnlyIfNetworkAvailable);

	public HRESULT get_ExecutionTimeLimit(BSTR* pExecutionTimeLimit) mut => VT.[Friend]get_ExecutionTimeLimit(&this, pExecutionTimeLimit);

	public HRESULT put_ExecutionTimeLimit(BSTR executionTimeLimit) mut => VT.[Friend]put_ExecutionTimeLimit(&this, executionTimeLimit);

	public HRESULT get_Enabled(int16* pEnabled) mut => VT.[Friend]get_Enabled(&this, pEnabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_DeleteExpiredTaskAfter(BSTR* pExpirationDelay) mut => VT.[Friend]get_DeleteExpiredTaskAfter(&this, pExpirationDelay);

	public HRESULT put_DeleteExpiredTaskAfter(BSTR expirationDelay) mut => VT.[Friend]put_DeleteExpiredTaskAfter(&this, expirationDelay);

	public HRESULT get_Priority(int32* pPriority) mut => VT.[Friend]get_Priority(&this, pPriority);

	public HRESULT put_Priority(int32 priority) mut => VT.[Friend]put_Priority(&this, priority);

	public HRESULT get_Compatibility(TASK_COMPATIBILITY* pCompatLevel) mut => VT.[Friend]get_Compatibility(&this, pCompatLevel);

	public HRESULT put_Compatibility(TASK_COMPATIBILITY compatLevel) mut => VT.[Friend]put_Compatibility(&this, compatLevel);

	public HRESULT get_Hidden(int16* pHidden) mut => VT.[Friend]get_Hidden(&this, pHidden);

	public HRESULT put_Hidden(int16 hidden) mut => VT.[Friend]put_Hidden(&this, hidden);

	public HRESULT get_IdleSettings(IIdleSettings** ppIdleSettings) mut => VT.[Friend]get_IdleSettings(&this, ppIdleSettings);

	public HRESULT put_IdleSettings(IIdleSettings* pIdleSettings) mut => VT.[Friend]put_IdleSettings(&this, pIdleSettings);

	public HRESULT get_RunOnlyIfIdle(int16* pRunOnlyIfIdle) mut => VT.[Friend]get_RunOnlyIfIdle(&this, pRunOnlyIfIdle);

	public HRESULT put_RunOnlyIfIdle(int16 runOnlyIfIdle) mut => VT.[Friend]put_RunOnlyIfIdle(&this, runOnlyIfIdle);

	public HRESULT get_WakeToRun(int16* pWake) mut => VT.[Friend]get_WakeToRun(&this, pWake);

	public HRESULT put_WakeToRun(int16 wake) mut => VT.[Friend]put_WakeToRun(&this, wake);

	public HRESULT get_NetworkSettings(INetworkSettings** ppNetworkSettings) mut => VT.[Friend]get_NetworkSettings(&this, ppNetworkSettings);

	public HRESULT put_NetworkSettings(INetworkSettings* pNetworkSettings) mut => VT.[Friend]put_NetworkSettings(&this, pNetworkSettings);
}

[CRepr]struct ITaskSettings2 : IDispatch
{
	public new const Guid IID = .(0x2c05c3f0, 0x6eed, 0x4c05, 0xa1, 0x5f, 0xed, 0x7d, 0x7a, 0x98, 0xa3, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pDisallowStart) get_DisallowStartOnRemoteAppSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 disallowStart) put_DisallowStartOnRemoteAppSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pUseUnifiedEngine) get_UseUnifiedSchedulingEngine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 useUnifiedEngine) put_UseUnifiedSchedulingEngine;
	}


	public HRESULT get_DisallowStartOnRemoteAppSession(int16* pDisallowStart) mut => VT.[Friend]get_DisallowStartOnRemoteAppSession(&this, pDisallowStart);

	public HRESULT put_DisallowStartOnRemoteAppSession(int16 disallowStart) mut => VT.[Friend]put_DisallowStartOnRemoteAppSession(&this, disallowStart);

	public HRESULT get_UseUnifiedSchedulingEngine(int16* pUseUnifiedEngine) mut => VT.[Friend]get_UseUnifiedSchedulingEngine(&this, pUseUnifiedEngine);

	public HRESULT put_UseUnifiedSchedulingEngine(int16 useUnifiedEngine) mut => VT.[Friend]put_UseUnifiedSchedulingEngine(&this, useUnifiedEngine);
}

[CRepr]struct ITaskSettings3 : ITaskSettings
{
	public new const Guid IID = .(0x0ad9d0d7, 0x0c7f, 0x4ebb, 0x9a, 0x5f, 0xd1, 0xc6, 0x48, 0xdc, 0xa5, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITaskSettings.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pDisallowStart) get_DisallowStartOnRemoteAppSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 disallowStart) put_DisallowStartOnRemoteAppSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pUseUnifiedEngine) get_UseUnifiedSchedulingEngine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 useUnifiedEngine) put_UseUnifiedSchedulingEngine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMaintenanceSettings** ppMaintenanceSettings) get_MaintenanceSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMaintenanceSettings* pMaintenanceSettings) put_MaintenanceSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMaintenanceSettings** ppMaintenanceSettings) CreateMaintenanceSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVolatile) get_Volatile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Volatile) put_Volatile;
	}


	public HRESULT get_DisallowStartOnRemoteAppSession(int16* pDisallowStart) mut => VT.[Friend]get_DisallowStartOnRemoteAppSession(&this, pDisallowStart);

	public HRESULT put_DisallowStartOnRemoteAppSession(int16 disallowStart) mut => VT.[Friend]put_DisallowStartOnRemoteAppSession(&this, disallowStart);

	public HRESULT get_UseUnifiedSchedulingEngine(int16* pUseUnifiedEngine) mut => VT.[Friend]get_UseUnifiedSchedulingEngine(&this, pUseUnifiedEngine);

	public HRESULT put_UseUnifiedSchedulingEngine(int16 useUnifiedEngine) mut => VT.[Friend]put_UseUnifiedSchedulingEngine(&this, useUnifiedEngine);

	public HRESULT get_MaintenanceSettings(IMaintenanceSettings** ppMaintenanceSettings) mut => VT.[Friend]get_MaintenanceSettings(&this, ppMaintenanceSettings);

	public HRESULT put_MaintenanceSettings(IMaintenanceSettings* pMaintenanceSettings) mut => VT.[Friend]put_MaintenanceSettings(&this, pMaintenanceSettings);

	public HRESULT CreateMaintenanceSettings(IMaintenanceSettings** ppMaintenanceSettings) mut => VT.[Friend]CreateMaintenanceSettings(&this, ppMaintenanceSettings);

	public HRESULT get_Volatile(int16* pVolatile) mut => VT.[Friend]get_Volatile(&this, pVolatile);

	public HRESULT put_Volatile(int16 Volatile) mut => VT.[Friend]put_Volatile(&this, Volatile);
}

[CRepr]struct IMaintenanceSettings : IDispatch
{
	public new const Guid IID = .(0xa6024fa8, 0x9652, 0x4adb, 0xa6, 0xbf, 0x5c, 0xfc, 0xd8, 0x77, 0xa7, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR value) put_Period;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* target) get_Period;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR value) put_Deadline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* target) get_Deadline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 value) put_Exclusive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* target) get_Exclusive;
	}


	public HRESULT put_Period(BSTR value) mut => VT.[Friend]put_Period(&this, value);

	public HRESULT get_Period(BSTR* target) mut => VT.[Friend]get_Period(&this, target);

	public HRESULT put_Deadline(BSTR value) mut => VT.[Friend]put_Deadline(&this, value);

	public HRESULT get_Deadline(BSTR* target) mut => VT.[Friend]get_Deadline(&this, target);

	public HRESULT put_Exclusive(int16 value) mut => VT.[Friend]put_Exclusive(&this, value);

	public HRESULT get_Exclusive(int16* target) mut => VT.[Friend]get_Exclusive(&this, target);
}

[CRepr]struct IRegisteredTaskCollection : IDispatch
{
	public new const Guid IID = .(0x86627eb4, 0x42a7, 0x41e4, 0xa4, 0xd9, 0xac, 0x33, 0xa7, 0x2f, 0x2d, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index, IRegisteredTask** ppRegisteredTask) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT get_Item(VARIANT index, IRegisteredTask** ppRegisteredTask) mut => VT.[Friend]get_Item(&this, index, ppRegisteredTask);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);
}

[CRepr]struct ITaskFolder : IDispatch
{
	public new const Guid IID = .(0x8cfac062, 0xa080, 0x4c15, 0x9a, 0x88, 0xaa, 0x7c, 0x2a, 0xf8, 0x0d, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pPath) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, ITaskFolder** ppFolder) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flags, ITaskFolderCollection** ppFolders) GetFolders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR subFolderName, VARIANT sddl, ITaskFolder** ppFolder) CreateFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR subFolderName, int32 flags) DeleteFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IRegisteredTask** ppTask) GetTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flags, IRegisteredTaskCollection** ppTasks) GetTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, int32 flags) DeleteTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR xmlText, int32 flags, VARIANT userId, VARIANT password, TASK_LOGON_TYPE logonType, VARIANT sddl, IRegisteredTask** ppTask) RegisterTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, ITaskDefinition* pDefinition, int32 flags, VARIANT userId, VARIANT password, TASK_LOGON_TYPE logonType, VARIANT sddl, IRegisteredTask** ppTask) RegisterTaskDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 securityInformation, BSTR* pSddl) GetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR sddl, int32 flags) SetSecurityDescriptor;
	}


	public HRESULT get_Name(BSTR* pName) mut => VT.[Friend]get_Name(&this, pName);

	public HRESULT get_Path(BSTR* pPath) mut => VT.[Friend]get_Path(&this, pPath);

	public HRESULT GetFolder(BSTR path, ITaskFolder** ppFolder) mut => VT.[Friend]GetFolder(&this, path, ppFolder);

	public HRESULT GetFolders(int32 flags, ITaskFolderCollection** ppFolders) mut => VT.[Friend]GetFolders(&this, flags, ppFolders);

	public HRESULT CreateFolder(BSTR subFolderName, VARIANT sddl, ITaskFolder** ppFolder) mut => VT.[Friend]CreateFolder(&this, subFolderName, sddl, ppFolder);

	public HRESULT DeleteFolder(BSTR subFolderName, int32 flags) mut => VT.[Friend]DeleteFolder(&this, subFolderName, flags);

	public HRESULT GetTask(BSTR path, IRegisteredTask** ppTask) mut => VT.[Friend]GetTask(&this, path, ppTask);

	public HRESULT GetTasks(int32 flags, IRegisteredTaskCollection** ppTasks) mut => VT.[Friend]GetTasks(&this, flags, ppTasks);

	public HRESULT DeleteTask(BSTR name, int32 flags) mut => VT.[Friend]DeleteTask(&this, name, flags);

	public HRESULT RegisterTask(BSTR path, BSTR xmlText, int32 flags, VARIANT userId, VARIANT password, TASK_LOGON_TYPE logonType, VARIANT sddl, IRegisteredTask** ppTask) mut => VT.[Friend]RegisterTask(&this, path, xmlText, flags, userId, password, logonType, sddl, ppTask);

	public HRESULT RegisterTaskDefinition(BSTR path, ITaskDefinition* pDefinition, int32 flags, VARIANT userId, VARIANT password, TASK_LOGON_TYPE logonType, VARIANT sddl, IRegisteredTask** ppTask) mut => VT.[Friend]RegisterTaskDefinition(&this, path, pDefinition, flags, userId, password, logonType, sddl, ppTask);

	public HRESULT GetSecurityDescriptor(int32 securityInformation, BSTR* pSddl) mut => VT.[Friend]GetSecurityDescriptor(&this, securityInformation, pSddl);

	public HRESULT SetSecurityDescriptor(BSTR sddl, int32 flags) mut => VT.[Friend]SetSecurityDescriptor(&this, sddl, flags);
}

[CRepr]struct IIdleSettings : IDispatch
{
	public new const Guid IID = .(0x84594461, 0x0053, 0x4342, 0xa8, 0xfd, 0x08, 0x8f, 0xab, 0xf1, 0x1f, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDelay) get_IdleDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR delay) put_IdleDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pTimeout) get_WaitTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR timeout) put_WaitTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pStop) get_StopOnIdleEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 stop) put_StopOnIdleEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRestart) get_RestartOnIdle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 restart) put_RestartOnIdle;
	}


	public HRESULT get_IdleDuration(BSTR* pDelay) mut => VT.[Friend]get_IdleDuration(&this, pDelay);

	public HRESULT put_IdleDuration(BSTR delay) mut => VT.[Friend]put_IdleDuration(&this, delay);

	public HRESULT get_WaitTimeout(BSTR* pTimeout) mut => VT.[Friend]get_WaitTimeout(&this, pTimeout);

	public HRESULT put_WaitTimeout(BSTR timeout) mut => VT.[Friend]put_WaitTimeout(&this, timeout);

	public HRESULT get_StopOnIdleEnd(int16* pStop) mut => VT.[Friend]get_StopOnIdleEnd(&this, pStop);

	public HRESULT put_StopOnIdleEnd(int16 stop) mut => VT.[Friend]put_StopOnIdleEnd(&this, stop);

	public HRESULT get_RestartOnIdle(int16* pRestart) mut => VT.[Friend]get_RestartOnIdle(&this, pRestart);

	public HRESULT put_RestartOnIdle(int16 restart) mut => VT.[Friend]put_RestartOnIdle(&this, restart);
}

[CRepr]struct INetworkSettings : IDispatch
{
	public new const Guid IID = .(0x9f7dea84, 0xc30b, 0x4245, 0x80, 0xb6, 0x00, 0xe9, 0xf6, 0x46, 0xf1, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR id) put_Id;
	}


	public HRESULT get_Name(BSTR* pName) mut => VT.[Friend]get_Name(&this, pName);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Id(BSTR* pId) mut => VT.[Friend]get_Id(&this, pId);

	public HRESULT put_Id(BSTR id) mut => VT.[Friend]put_Id(&this, id);
}

[CRepr]struct IRepetitionPattern : IDispatch
{
	public new const Guid IID = .(0x7fb9acf1, 0x26be, 0x400e, 0x85, 0xb5, 0x29, 0x4b, 0x9c, 0x75, 0xdf, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pInterval) get_Interval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR interval) put_Interval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDuration) get_Duration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR duration) put_Duration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pStop) get_StopAtDurationEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 stop) put_StopAtDurationEnd;
	}


	public HRESULT get_Interval(BSTR* pInterval) mut => VT.[Friend]get_Interval(&this, pInterval);

	public HRESULT put_Interval(BSTR interval) mut => VT.[Friend]put_Interval(&this, interval);

	public HRESULT get_Duration(BSTR* pDuration) mut => VT.[Friend]get_Duration(&this, pDuration);

	public HRESULT put_Duration(BSTR duration) mut => VT.[Friend]put_Duration(&this, duration);

	public HRESULT get_StopAtDurationEnd(int16* pStop) mut => VT.[Friend]get_StopAtDurationEnd(&this, pStop);

	public HRESULT put_StopAtDurationEnd(int16 stop) mut => VT.[Friend]put_StopAtDurationEnd(&this, stop);
}

#endregion
