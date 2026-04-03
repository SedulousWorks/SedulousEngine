using Win32.Foundation;
using Win32.System.Threading;
using Win32.Security;
using System;

namespace Win32.System.JobObjects;

#region Enums

[AllowDuplicates]
public enum JOB_OBJECT_LIMIT : uint32
{
	JOB_OBJECT_LIMIT_WORKINGSET = 1,
	JOB_OBJECT_LIMIT_PROCESS_TIME = 2,
	JOB_OBJECT_LIMIT_JOB_TIME = 4,
	JOB_OBJECT_LIMIT_ACTIVE_PROCESS = 8,
	JOB_OBJECT_LIMIT_AFFINITY = 16,
	JOB_OBJECT_LIMIT_PRIORITY_CLASS = 32,
	JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME = 64,
	JOB_OBJECT_LIMIT_SCHEDULING_CLASS = 128,
	JOB_OBJECT_LIMIT_PROCESS_MEMORY = 256,
	JOB_OBJECT_LIMIT_JOB_MEMORY = 512,
	JOB_OBJECT_LIMIT_JOB_MEMORY_HIGH = 512,
	JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = 1024,
	JOB_OBJECT_LIMIT_BREAKAWAY_OK = 2048,
	JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK = 4096,
	JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 8192,
	JOB_OBJECT_LIMIT_SUBSET_AFFINITY = 16384,
	JOB_OBJECT_LIMIT_JOB_MEMORY_LOW = 32768,
	JOB_OBJECT_LIMIT_JOB_READ_BYTES = 65536,
	JOB_OBJECT_LIMIT_JOB_WRITE_BYTES = 131072,
	JOB_OBJECT_LIMIT_RATE_CONTROL = 262144,
	JOB_OBJECT_LIMIT_CPU_RATE_CONTROL = 262144,
	JOB_OBJECT_LIMIT_IO_RATE_CONTROL = 524288,
	JOB_OBJECT_LIMIT_NET_RATE_CONTROL = 1048576,
	JOB_OBJECT_LIMIT_VALID_FLAGS = 524287,
	JOB_OBJECT_BASIC_LIMIT_VALID_FLAGS = 255,
	JOB_OBJECT_EXTENDED_LIMIT_VALID_FLAGS = 32767,
	JOB_OBJECT_NOTIFICATION_LIMIT_VALID_FLAGS = 2064900,
}


[AllowDuplicates]
public enum JOB_OBJECT_UILIMIT : uint32
{
	JOB_OBJECT_UILIMIT_NONE = 0,
	JOB_OBJECT_UILIMIT_HANDLES = 1,
	JOB_OBJECT_UILIMIT_READCLIPBOARD = 2,
	JOB_OBJECT_UILIMIT_WRITECLIPBOARD = 4,
	JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = 8,
	JOB_OBJECT_UILIMIT_DISPLAYSETTINGS = 16,
	JOB_OBJECT_UILIMIT_GLOBALATOMS = 32,
	JOB_OBJECT_UILIMIT_DESKTOP = 64,
	JOB_OBJECT_UILIMIT_EXITWINDOWS = 128,
}


[AllowDuplicates]
public enum JOB_OBJECT_SECURITY : uint32
{
	JOB_OBJECT_SECURITY_NO_ADMIN = 1,
	JOB_OBJECT_SECURITY_RESTRICTED_TOKEN = 2,
	JOB_OBJECT_SECURITY_ONLY_TOKEN = 4,
	JOB_OBJECT_SECURITY_FILTER_TOKENS = 8,
	JOB_OBJECT_SECURITY_VALID_FLAGS = 15,
}


[AllowDuplicates]
public enum JOB_OBJECT_CPU_RATE_CONTROL : uint32
{
	JOB_OBJECT_CPU_RATE_CONTROL_ENABLE = 1,
	JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED = 2,
	JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP = 4,
	JOB_OBJECT_CPU_RATE_CONTROL_NOTIFY = 8,
	JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE = 16,
	JOB_OBJECT_CPU_RATE_CONTROL_VALID_FLAGS = 31,
}


[AllowDuplicates]
public enum JOB_OBJECT_TERMINATE_AT_END_ACTION : uint32
{
	JOB_OBJECT_TERMINATE_AT_END_OF_JOB = 0,
	JOB_OBJECT_POST_AT_END_OF_JOB = 1,
}


[AllowDuplicates]
public enum JOBOBJECT_RATE_CONTROL_TOLERANCE : int32
{
	ToleranceLow = 1,
	ToleranceMedium = 2,
	ToleranceHigh = 3,
}


[AllowDuplicates]
public enum JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL : int32
{
	ToleranceIntervalShort = 1,
	ToleranceIntervalMedium = 2,
	ToleranceIntervalLong = 3,
}


[AllowDuplicates]
public enum JOB_OBJECT_NET_RATE_CONTROL_FLAGS : uint32
{
	JOB_OBJECT_NET_RATE_CONTROL_ENABLE = 1,
	JOB_OBJECT_NET_RATE_CONTROL_MAX_BANDWIDTH = 2,
	JOB_OBJECT_NET_RATE_CONTROL_DSCP_TAG = 4,
	JOB_OBJECT_NET_RATE_CONTROL_VALID_FLAGS = 7,
}


[AllowDuplicates]
public enum JOB_OBJECT_IO_RATE_CONTROL_FLAGS : int32
{
	JOB_OBJECT_IO_RATE_CONTROL_ENABLE = 1,
	JOB_OBJECT_IO_RATE_CONTROL_STANDALONE_VOLUME = 2,
	JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ALL = 4,
	JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ON_SOFT_CAP = 8,
	JOB_OBJECT_IO_RATE_CONTROL_VALID_FLAGS = 15,
}


[AllowDuplicates]
public enum JOBOBJECT_IO_ATTRIBUTION_CONTROL_FLAGS : int32
{
	JOBOBJECT_IO_ATTRIBUTION_CONTROL_ENABLE = 1,
	JOBOBJECT_IO_ATTRIBUTION_CONTROL_DISABLE = 2,
	JOBOBJECT_IO_ATTRIBUTION_CONTROL_VALID_FLAGS = 3,
}


[AllowDuplicates]
public enum JOBOBJECTINFOCLASS : int32
{
	JobObjectBasicAccountingInformation = 1,
	JobObjectBasicLimitInformation = 2,
	JobObjectBasicProcessIdList = 3,
	JobObjectBasicUIRestrictions = 4,
	JobObjectSecurityLimitInformation = 5,
	JobObjectEndOfJobTimeInformation = 6,
	JobObjectAssociateCompletionPortInformation = 7,
	JobObjectBasicAndIoAccountingInformation = 8,
	JobObjectExtendedLimitInformation = 9,
	JobObjectJobSetInformation = 10,
	JobObjectGroupInformation = 11,
	JobObjectNotificationLimitInformation = 12,
	JobObjectLimitViolationInformation = 13,
	JobObjectGroupInformationEx = 14,
	JobObjectCpuRateControlInformation = 15,
	JobObjectCompletionFilter = 16,
	JobObjectCompletionCounter = 17,
	JobObjectReserved1Information = 18,
	JobObjectReserved2Information = 19,
	JobObjectReserved3Information = 20,
	JobObjectReserved4Information = 21,
	JobObjectReserved5Information = 22,
	JobObjectReserved6Information = 23,
	JobObjectReserved7Information = 24,
	JobObjectReserved8Information = 25,
	JobObjectReserved9Information = 26,
	JobObjectReserved10Information = 27,
	JobObjectReserved11Information = 28,
	JobObjectReserved12Information = 29,
	JobObjectReserved13Information = 30,
	JobObjectReserved14Information = 31,
	JobObjectNetRateControlInformation = 32,
	JobObjectNotificationLimitInformation2 = 33,
	JobObjectLimitViolationInformation2 = 34,
	JobObjectCreateSilo = 35,
	JobObjectSiloBasicInformation = 36,
	JobObjectReserved15Information = 37,
	JobObjectReserved16Information = 38,
	JobObjectReserved17Information = 39,
	JobObjectReserved18Information = 40,
	JobObjectReserved19Information = 41,
	JobObjectReserved20Information = 42,
	JobObjectReserved21Information = 43,
	JobObjectReserved22Information = 44,
	JobObjectReserved23Information = 45,
	JobObjectReserved24Information = 46,
	JobObjectReserved25Information = 47,
	MaxJobObjectInfoClass = 48,
}

#endregion


#region Structs
[CRepr]
public struct JOBOBJECT_IO_RATE_CONTROL_INFORMATION
{
	public int64 MaxIops;
	public int64 MaxBandwidth;
	public int64 ReservationIops;
	public PWSTR VolumeName;
	public uint32 BaseIoSize;
	public JOB_OBJECT_IO_RATE_CONTROL_FLAGS ControlFlags;
}

[CRepr]
public struct JOB_SET_ARRAY
{
	public HANDLE JobHandle;
	public uint32 MemberLevel;
	public uint32 Flags;
}

[CRepr]
public struct JOBOBJECT_BASIC_ACCOUNTING_INFORMATION
{
	public LARGE_INTEGER TotalUserTime;
	public LARGE_INTEGER TotalKernelTime;
	public LARGE_INTEGER ThisPeriodTotalUserTime;
	public LARGE_INTEGER ThisPeriodTotalKernelTime;
	public uint32 TotalPageFaultCount;
	public uint32 TotalProcesses;
	public uint32 ActiveProcesses;
	public uint32 TotalTerminatedProcesses;
}

[CRepr]
public struct JOBOBJECT_BASIC_LIMIT_INFORMATION
{
	public LARGE_INTEGER PerProcessUserTimeLimit;
	public LARGE_INTEGER PerJobUserTimeLimit;
	public JOB_OBJECT_LIMIT LimitFlags;
	public uint MinimumWorkingSetSize;
	public uint MaximumWorkingSetSize;
	public uint32 ActiveProcessLimit;
	public uint Affinity;
	public uint32 PriorityClass;
	public uint32 SchedulingClass;
}

[CRepr]
public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
{
	public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
	public IO_COUNTERS IoInfo;
	public uint ProcessMemoryLimit;
	public uint JobMemoryLimit;
	public uint PeakProcessMemoryUsed;
	public uint PeakJobMemoryUsed;
}

[CRepr]
public struct JOBOBJECT_BASIC_PROCESS_ID_LIST
{
	public uint32 NumberOfAssignedProcesses;
	public uint32 NumberOfProcessIdsInList;
	public uint* ProcessIdList mut => &ProcessIdList_impl;
	private uint[ANYSIZE_ARRAY] ProcessIdList_impl;
}

[CRepr]
public struct JOBOBJECT_BASIC_UI_RESTRICTIONS
{
	public JOB_OBJECT_UILIMIT UIRestrictionsClass;
}

[CRepr]
public struct JOBOBJECT_SECURITY_LIMIT_INFORMATION
{
	public JOB_OBJECT_SECURITY SecurityLimitFlags;
	public HANDLE JobToken;
	public TOKEN_GROUPS* SidsToDisable;
	public TOKEN_PRIVILEGES* PrivilegesToDelete;
	public TOKEN_GROUPS* RestrictedSids;
}

[CRepr]
public struct JOBOBJECT_END_OF_JOB_TIME_INFORMATION
{
	public JOB_OBJECT_TERMINATE_AT_END_ACTION EndOfJobTimeAction;
}

[CRepr]
public struct JOBOBJECT_ASSOCIATE_COMPLETION_PORT
{
	public void* CompletionKey;
	public HANDLE CompletionPort;
}

[CRepr]
public struct JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION
{
	public JOBOBJECT_BASIC_ACCOUNTING_INFORMATION BasicInfo;
	public IO_COUNTERS IoInfo;
}

[CRepr]
public struct JOBOBJECT_JOBSET_INFORMATION
{
	public uint32 MemberLevel;
}

[CRepr]
public struct JOBOBJECT_NOTIFICATION_LIMIT_INFORMATION
{
	public uint64 IoReadBytesLimit;
	public uint64 IoWriteBytesLimit;
	public LARGE_INTEGER PerJobUserTimeLimit;
	public uint64 JobMemoryLimit;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE RateControlTolerance;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL RateControlToleranceInterval;
	public JOB_OBJECT_LIMIT LimitFlags;
}

[CRepr]
public struct JOBOBJECT_NOTIFICATION_LIMIT_INFORMATION_2
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL RateControlToleranceInterval;
		public JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL CpuRateControlToleranceInterval;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint64 JobHighMemoryLimit;
		public uint64 JobMemoryLimit;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public JOBOBJECT_RATE_CONTROL_TOLERANCE RateControlTolerance;
		public JOBOBJECT_RATE_CONTROL_TOLERANCE CpuRateControlTolerance;
	}
	public uint64 IoReadBytesLimit;
	public uint64 IoWriteBytesLimit;
	public LARGE_INTEGER PerJobUserTimeLimit;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public JOB_OBJECT_LIMIT LimitFlags;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE IoRateControlTolerance;
	public uint64 JobLowMemoryLimit;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL IoRateControlToleranceInterval;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE NetRateControlTolerance;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL NetRateControlToleranceInterval;
}

[CRepr]
public struct JOBOBJECT_LIMIT_VIOLATION_INFORMATION
{
	public JOB_OBJECT_LIMIT LimitFlags;
	public JOB_OBJECT_LIMIT ViolationLimitFlags;
	public uint64 IoReadBytes;
	public uint64 IoReadBytesLimit;
	public uint64 IoWriteBytes;
	public uint64 IoWriteBytesLimit;
	public LARGE_INTEGER PerJobUserTime;
	public LARGE_INTEGER PerJobUserTimeLimit;
	public uint64 JobMemory;
	public uint64 JobMemoryLimit;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE RateControlTolerance;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE RateControlToleranceLimit;
}

[CRepr]
public struct JOBOBJECT_LIMIT_VIOLATION_INFORMATION_2
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public JOBOBJECT_RATE_CONTROL_TOLERANCE RateControlTolerance;
		public JOBOBJECT_RATE_CONTROL_TOLERANCE CpuRateControlTolerance;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public JOBOBJECT_RATE_CONTROL_TOLERANCE RateControlToleranceLimit;
		public JOBOBJECT_RATE_CONTROL_TOLERANCE CpuRateControlToleranceLimit;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint64 JobHighMemoryLimit;
		public uint64 JobMemoryLimit;
	}
	public JOB_OBJECT_LIMIT LimitFlags;
	public JOB_OBJECT_LIMIT ViolationLimitFlags;
	public uint64 IoReadBytes;
	public uint64 IoReadBytesLimit;
	public uint64 IoWriteBytes;
	public uint64 IoWriteBytesLimit;
	public LARGE_INTEGER PerJobUserTime;
	public LARGE_INTEGER PerJobUserTimeLimit;
	public uint64 JobMemory;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public uint64 JobLowMemoryLimit;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE IoRateControlTolerance;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE IoRateControlToleranceLimit;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE NetRateControlTolerance;
	public JOBOBJECT_RATE_CONTROL_TOLERANCE NetRateControlToleranceLimit;
}

[CRepr]
public struct JOBOBJECT_CPU_RATE_CONTROL_INFORMATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 MinRate;
			public uint16 MaxRate;
		}
		public uint32 CpuRate;
		public uint32 Weight;
		public using _Anonymous_e__Struct Anonymous;
	}
	public JOB_OBJECT_CPU_RATE_CONTROL ControlFlags;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct JOBOBJECT_NET_RATE_CONTROL_INFORMATION
{
	public uint64 MaxBandwidth;
	public JOB_OBJECT_NET_RATE_CONTROL_FLAGS ControlFlags;
	public uint8 DscpTag;
}

[CRepr]
public struct JOBOBJECT_IO_RATE_CONTROL_INFORMATION_NATIVE_V2
{
	public int64 MaxIops;
	public int64 MaxBandwidth;
	public int64 ReservationIops;
	public PWSTR VolumeName;
	public uint32 BaseIoSize;
	public JOB_OBJECT_IO_RATE_CONTROL_FLAGS ControlFlags;
	public uint16 VolumeNameLength;
	public int64 CriticalReservationIops;
	public int64 ReservationBandwidth;
	public int64 CriticalReservationBandwidth;
	public int64 MaxTimePercent;
	public int64 ReservationTimePercent;
	public int64 CriticalReservationTimePercent;
}

[CRepr]
public struct JOBOBJECT_IO_RATE_CONTROL_INFORMATION_NATIVE_V3
{
	public int64 MaxIops;
	public int64 MaxBandwidth;
	public int64 ReservationIops;
	public PWSTR VolumeName;
	public uint32 BaseIoSize;
	public JOB_OBJECT_IO_RATE_CONTROL_FLAGS ControlFlags;
	public uint16 VolumeNameLength;
	public int64 CriticalReservationIops;
	public int64 ReservationBandwidth;
	public int64 CriticalReservationBandwidth;
	public int64 MaxTimePercent;
	public int64 ReservationTimePercent;
	public int64 CriticalReservationTimePercent;
	public int64 SoftMaxIops;
	public int64 SoftMaxBandwidth;
	public int64 SoftMaxTimePercent;
	public int64 LimitExcessNotifyIops;
	public int64 LimitExcessNotifyBandwidth;
	public int64 LimitExcessNotifyTimePercent;
}

[CRepr]
public struct JOBOBJECT_IO_ATTRIBUTION_STATS
{
	public uint IoCount;
	public uint64 TotalNonOverlappedQueueTime;
	public uint64 TotalNonOverlappedServiceTime;
	public uint64 TotalSize;
}

[CRepr]
public struct JOBOBJECT_IO_ATTRIBUTION_INFORMATION
{
	public uint32 ControlFlags;
	public JOBOBJECT_IO_ATTRIBUTION_STATS ReadStats;
	public JOBOBJECT_IO_ATTRIBUTION_STATS WriteStats;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsProcessInJob(HANDLE ProcessHandle, HANDLE JobHandle, BOOL* Result);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateJobObjectW(SECURITY_ATTRIBUTES* lpJobAttributes, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeMemoryJobObject(void* Buffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenJobObjectW(uint32 dwDesiredAccess, BOOL bInheritHandle, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AssignProcessToJobObject(HANDLE hJob, HANDLE hProcess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TerminateJobObject(HANDLE hJob, uint32 uExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetInformationJobObject(HANDLE hJob, JOBOBJECTINFOCLASS JobObjectInformationClass, void* lpJobObjectInformation, uint32 cbJobObjectInformationLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIoRateControlInformationJobObject(HANDLE hJob, JOBOBJECT_IO_RATE_CONTROL_INFORMATION* IoRateControlInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryInformationJobObject(HANDLE hJob, JOBOBJECTINFOCLASS JobObjectInformationClass, void* lpJobObjectInformation, uint32 cbJobObjectInformationLength, uint32* lpReturnLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryIoRateControlInformationJobObject(HANDLE hJob, PWSTR VolumeName, JOBOBJECT_IO_RATE_CONTROL_INFORMATION** InfoBlocks, uint32* InfoBlockCount);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UserHandleGrantAccess(HANDLE hUserHandle, HANDLE hJob, BOOL bGrant);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateJobObjectA(SECURITY_ATTRIBUTES* lpJobAttributes, PSTR lpName);
	public static HANDLE CreateJobObject(SECURITY_ATTRIBUTES* lpJobAttributes, PSTR lpName) => CreateJobObjectA(lpJobAttributes, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenJobObjectA(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpName);
	public static HANDLE OpenJobObject(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpName) => OpenJobObjectA(dwDesiredAccess, bInheritHandle, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateJobSet(uint32 NumJob, JOB_SET_ARRAY* UserJobSet, uint32 Flags);

}
#endregion
