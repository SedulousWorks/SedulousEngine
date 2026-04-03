using Win32.Foundation;
using Win32.System.SystemInformation;
using Win32.System.SystemServices;
using Win32.System.Kernel;
using Win32.Security;
using System;

namespace Win32.System.Threading;

#region Constants
public static
{
	public const uint32 PRIVATE_NAMESPACE_FLAG_DESTROY = 1;
	public const uint32 PROC_THREAD_ATTRIBUTE_REPLACE_VALUE = 1;
	public const uint32 THREAD_POWER_THROTTLING_CURRENT_VERSION = 1;
	public const uint32 THREAD_POWER_THROTTLING_EXECUTION_SPEED = 1;
	public const uint32 THREAD_POWER_THROTTLING_VALID_FLAGS = 1;
	public const uint32 PME_CURRENT_VERSION = 1;
	public const uint32 PME_FAILFAST_ON_COMMIT_FAIL_DISABLE = 0;
	public const uint32 PME_FAILFAST_ON_COMMIT_FAIL_ENABLE = 1;
	public const uint32 PROCESS_POWER_THROTTLING_CURRENT_VERSION = 1;
	public const uint32 PROCESS_POWER_THROTTLING_EXECUTION_SPEED = 1;
	public const uint32 PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION = 4;
	public const uint32 PROCESS_LEAP_SECOND_INFO_FLAG_ENABLE_SIXTY_SECOND = 1;
	public const uint32 PROCESS_LEAP_SECOND_INFO_VALID_FLAGS = 1;
	public const uint32 INIT_ONCE_CHECK_ONLY = 1;
	public const uint32 INIT_ONCE_ASYNC = 2;
	public const uint32 INIT_ONCE_INIT_FAILED = 4;
	public const uint32 INIT_ONCE_CTX_RESERVED_BITS = 2;
	public const uint32 CONDITION_VARIABLE_LOCKMODE_SHARED = 1;
	public const uint32 CREATE_MUTEX_INITIAL_OWNER = 1;
	public const uint32 CREATE_WAITABLE_TIMER_MANUAL_RESET = 1;
	public const uint32 CREATE_WAITABLE_TIMER_HIGH_RESOLUTION = 2;
	public const uint32 SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY = 1;
	public const uint32 SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY = 2;
	public const uint32 SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE = 4;
	public const uint32 PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = 131072;
	public const uint32 PROC_THREAD_ATTRIBUTE_HANDLE_LIST = 131074;
	public const uint32 PROC_THREAD_ATTRIBUTE_GROUP_AFFINITY = 196611;
	public const uint32 PROC_THREAD_ATTRIBUTE_PREFERRED_NODE = 131076;
	public const uint32 PROC_THREAD_ATTRIBUTE_IDEAL_PROCESSOR = 196613;
	public const uint32 PROC_THREAD_ATTRIBUTE_UMS_THREAD = 196614;
	public const uint32 PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY = 131079;
	public const uint32 PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES = 131081;
	public const uint32 PROC_THREAD_ATTRIBUTE_PROTECTION_LEVEL = 131083;
	public const uint32 PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = 131094;
	public const uint32 PROC_THREAD_ATTRIBUTE_MACHINE_TYPE = 131097;
	public const uint32 PROC_THREAD_ATTRIBUTE_ENABLE_OPTIONAL_XSTATE_FEATURES = 196635;
	public const uint32 PROC_THREAD_ATTRIBUTE_WIN32K_FILTER = 131088;
	public const uint32 PROC_THREAD_ATTRIBUTE_JOB_LIST = 131085;
	public const uint32 PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY = 131086;
	public const uint32 PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY = 131087;
	public const uint32 PROC_THREAD_ATTRIBUTE_DESKTOP_APP_POLICY = 131090;
	public const uint32 PROC_THREAD_ATTRIBUTE_MITIGATION_AUDIT_POLICY = 131096;
	public const uint32 PROC_THREAD_ATTRIBUTE_COMPONENT_FILTER = 131098;
}
#endregion

#region TypeDefs
typealias TimerQueueHandle = int;

typealias PTP_POOL = int;

typealias NamespaceHandle = int;

typealias BoundaryDescriptorHandle = int;

typealias LPPROC_THREAD_ATTRIBUTE_LIST = void*;

#endregion


#region Enums

[AllowDuplicates]
public enum THREAD_CREATION_FLAGS : uint32
{
	THREAD_CREATE_RUN_IMMEDIATELY = 0,
	THREAD_CREATE_SUSPENDED = 4,
	STACK_SIZE_PARAM_IS_A_RESERVATION = 65536,
}


[AllowDuplicates]
public enum THREAD_PRIORITY : int32
{
	THREAD_MODE_BACKGROUND_BEGIN = 65536,
	THREAD_MODE_BACKGROUND_END = 131072,
	THREAD_PRIORITY_ABOVE_NORMAL = 1,
	THREAD_PRIORITY_BELOW_NORMAL = -1,
	THREAD_PRIORITY_HIGHEST = 2,
	THREAD_PRIORITY_IDLE = -15,
	THREAD_PRIORITY_MIN = -2,
	THREAD_PRIORITY_LOWEST = -2,
	THREAD_PRIORITY_NORMAL = 0,
	THREAD_PRIORITY_TIME_CRITICAL = 15,
}


[AllowDuplicates]
public enum WORKER_THREAD_FLAGS : uint32
{
	WT_EXECUTEDEFAULT = 0,
	WT_EXECUTEINIOTHREAD = 1,
	WT_EXECUTEINPERSISTENTTHREAD = 128,
	WT_EXECUTEINWAITTHREAD = 4,
	WT_EXECUTELONGFUNCTION = 16,
	WT_EXECUTEONLYONCE = 8,
	WT_TRANSFER_IMPERSONATION = 256,
	WT_EXECUTEINTIMERTHREAD = 32,
}


[AllowDuplicates]
public enum CREATE_EVENT : uint32
{
	CREATE_EVENT_INITIAL_SET = 2,
	CREATE_EVENT_MANUAL_RESET = 1,
}


[AllowDuplicates]
public enum CREATE_PROCESS_LOGON_FLAGS : uint32
{
	LOGON_WITH_PROFILE = 1,
	LOGON_NETCREDENTIALS_ONLY = 2,
}


[AllowDuplicates]
public enum PROCESS_AFFINITY_AUTO_UPDATE_FLAGS : uint32
{
	PROCESS_AFFINITY_DISABLE_AUTO_UPDATE = 0,
	PROCESS_AFFINITY_ENABLE_AUTO_UPDATE = 1,
}


[AllowDuplicates]
public enum PROCESS_DEP_FLAGS : uint32
{
	PROCESS_DEP_ENABLE = 1,
	PROCESS_DEP_DISABLE_ATL_THUNK_EMULATION = 2,
	PROCESS_DEP_NONE = 0,
}


[AllowDuplicates]
public enum PROCESS_NAME_FORMAT : uint32
{
	PROCESS_NAME_WIN32 = 0,
	PROCESS_NAME_NATIVE = 1,
}


[AllowDuplicates]
public enum PROCESSOR_FEATURE_ID : uint32
{
	PF_ARM_64BIT_LOADSTORE_ATOMIC = 25,
	PF_ARM_DIVIDE_INSTRUCTION_AVAILABLE = 24,
	PF_ARM_EXTERNAL_CACHE_AVAILABLE = 26,
	PF_ARM_FMAC_INSTRUCTIONS_AVAILABLE = 27,
	PF_ARM_VFP_32_REGISTERS_AVAILABLE = 18,
	PF_3DNOW_INSTRUCTIONS_AVAILABLE = 7,
	PF_CHANNELS_ENABLED = 16,
	PF_COMPARE_EXCHANGE_DOUBLE = 2,
	PF_COMPARE_EXCHANGE128 = 14,
	PF_COMPARE64_EXCHANGE128 = 15,
	PF_FASTFAIL_AVAILABLE = 23,
	PF_FLOATING_POINT_EMULATED = 1,
	PF_FLOATING_POINT_PRECISION_ERRATA = 0,
	PF_MMX_INSTRUCTIONS_AVAILABLE = 3,
	PF_NX_ENABLED = 12,
	PF_PAE_ENABLED = 9,
	PF_RDTSC_INSTRUCTION_AVAILABLE = 8,
	PF_RDWRFSGSBASE_AVAILABLE = 22,
	PF_SECOND_LEVEL_ADDRESS_TRANSLATION = 20,
	PF_SSE3_INSTRUCTIONS_AVAILABLE = 13,
	PF_VIRT_FIRMWARE_ENABLED = 21,
	PF_XMMI_INSTRUCTIONS_AVAILABLE = 6,
	PF_XMMI64_INSTRUCTIONS_AVAILABLE = 10,
	PF_XSAVE_ENABLED = 17,
	PF_ARM_V8_INSTRUCTIONS_AVAILABLE = 29,
	PF_ARM_V8_CRYPTO_INSTRUCTIONS_AVAILABLE = 30,
	PF_ARM_V8_CRC32_INSTRUCTIONS_AVAILABLE = 31,
	PF_ARM_V81_ATOMIC_INSTRUCTIONS_AVAILABLE = 34,
}


[AllowDuplicates]
public enum GET_GUI_RESOURCES_FLAGS : uint32
{
	GR_GDIOBJECTS = 0,
	GR_GDIOBJECTS_PEAK = 2,
	GR_USEROBJECTS = 1,
	GR_USEROBJECTS_PEAK = 4,
}


[AllowDuplicates]
public enum STARTUPINFOW_FLAGS : uint32
{
	STARTF_FORCEONFEEDBACK = 64,
	STARTF_FORCEOFFFEEDBACK = 128,
	STARTF_PREVENTPINNING = 8192,
	STARTF_RUNFULLSCREEN = 32,
	STARTF_TITLEISAPPID = 4096,
	STARTF_TITLEISLINKNAME = 2048,
	STARTF_UNTRUSTEDSOURCE = 32768,
	STARTF_USECOUNTCHARS = 8,
	STARTF_USEFILLATTRIBUTE = 16,
	STARTF_USEHOTKEY = 512,
	STARTF_USEPOSITION = 4,
	STARTF_USESHOWWINDOW = 1,
	STARTF_USESIZE = 2,
	STARTF_USESTDHANDLES = 256,
}


[AllowDuplicates]
public enum MEMORY_PRIORITY : uint32
{
	MEMORY_PRIORITY_VERY_LOW = 1,
	MEMORY_PRIORITY_LOW = 2,
	MEMORY_PRIORITY_MEDIUM = 3,
	MEMORY_PRIORITY_BELOW_NORMAL = 4,
	MEMORY_PRIORITY_NORMAL = 5,
}


[AllowDuplicates]
public enum PROCESS_PROTECTION_LEVEL : uint32
{
	PROTECTION_LEVEL_WINTCB_LIGHT = 0,
	PROTECTION_LEVEL_WINDOWS = 1,
	PROTECTION_LEVEL_WINDOWS_LIGHT = 2,
	PROTECTION_LEVEL_ANTIMALWARE_LIGHT = 3,
	PROTECTION_LEVEL_LSA_LIGHT = 4,
	PROTECTION_LEVEL_WINTCB = 5,
	PROTECTION_LEVEL_CODEGEN_LIGHT = 6,
	PROTECTION_LEVEL_AUTHENTICODE = 7,
	PROTECTION_LEVEL_PPL_APP = 8,
	PROTECTION_LEVEL_NONE = 4294967294,
}


[AllowDuplicates]
public enum POWER_REQUEST_CONTEXT_FLAGS : uint32
{
	POWER_REQUEST_CONTEXT_DETAILED_STRING = 2,
	POWER_REQUEST_CONTEXT_SIMPLE_STRING = 1,
}


[AllowDuplicates]
public enum THREAD_ACCESS_RIGHTS : uint32
{
	THREAD_TERMINATE = 1,
	THREAD_SUSPEND_RESUME = 2,
	THREAD_GET_CONTEXT = 8,
	THREAD_SET_CONTEXT = 16,
	THREAD_SET_INFORMATION = 32,
	THREAD_QUERY_INFORMATION = 64,
	THREAD_SET_THREAD_TOKEN = 128,
	THREAD_IMPERSONATE = 256,
	THREAD_DIRECT_IMPERSONATION = 512,
	THREAD_SET_LIMITED_INFORMATION = 1024,
	THREAD_QUERY_LIMITED_INFORMATION = 2048,
	THREAD_RESUME = 4096,
	THREAD_ALL_ACCESS = 2097151,
	THREAD_DELETE = 65536,
	THREAD_READ_CONTROL = 131072,
	THREAD_WRITE_DAC = 262144,
	THREAD_WRITE_OWNER = 524288,
	THREAD_SYNCHRONIZE = 1048576,
	THREAD_STANDARD_RIGHTS_REQUIRED = 983040,
}


[AllowDuplicates]
public enum SYNCHRONIZATION_ACCESS_RIGHTS : uint32
{
	EVENT_ALL_ACCESS = 2031619,
	EVENT_MODIFY_STATE = 2,
	MUTEX_ALL_ACCESS = 2031617,
	MUTEX_MODIFY_STATE = 1,
	SEMAPHORE_ALL_ACCESS = 2031619,
	SEMAPHORE_MODIFY_STATE = 2,
	TIMER_ALL_ACCESS = 2031619,
	TIMER_MODIFY_STATE = 2,
	TIMER_QUERY_STATE = 1,
	SYNCHRONIZATION_DELETE = 65536,
	SYNCHRONIZATION_READ_CONTROL = 131072,
	SYNCHRONIZATION_WRITE_DAC = 262144,
	SYNCHRONIZATION_WRITE_OWNER = 524288,
	SYNCHRONIZATION_SYNCHRONIZE = 1048576,
}


[AllowDuplicates]
public enum PROCESS_CREATION_FLAGS : uint32
{
	DEBUG_PROCESS = 1,
	DEBUG_ONLY_THIS_PROCESS = 2,
	CREATE_SUSPENDED = 4,
	DETACHED_PROCESS = 8,
	CREATE_NEW_CONSOLE = 16,
	NORMAL_PRIORITY_CLASS = 32,
	IDLE_PRIORITY_CLASS = 64,
	HIGH_PRIORITY_CLASS = 128,
	REALTIME_PRIORITY_CLASS = 256,
	CREATE_NEW_PROCESS_GROUP = 512,
	CREATE_UNICODE_ENVIRONMENT = 1024,
	CREATE_SEPARATE_WOW_VDM = 2048,
	CREATE_SHARED_WOW_VDM = 4096,
	CREATE_FORCEDOS = 8192,
	BELOW_NORMAL_PRIORITY_CLASS = 16384,
	ABOVE_NORMAL_PRIORITY_CLASS = 32768,
	INHERIT_PARENT_AFFINITY = 65536,
	INHERIT_CALLER_PRIORITY = 131072,
	CREATE_PROTECTED_PROCESS = 262144,
	EXTENDED_STARTUPINFO_PRESENT = 524288,
	PROCESS_MODE_BACKGROUND_BEGIN = 1048576,
	PROCESS_MODE_BACKGROUND_END = 2097152,
	CREATE_SECURE_PROCESS = 4194304,
	CREATE_BREAKAWAY_FROM_JOB = 16777216,
	CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 33554432,
	CREATE_DEFAULT_ERROR_MODE = 67108864,
	CREATE_NO_WINDOW = 134217728,
	PROFILE_USER = 268435456,
	PROFILE_KERNEL = 536870912,
	PROFILE_SERVER = 1073741824,
	CREATE_IGNORE_SYSTEM_DEFAULT = 2147483648,
}


[AllowDuplicates]
public enum PROCESS_ACCESS_RIGHTS : uint32
{
	PROCESS_TERMINATE = 1,
	PROCESS_CREATE_THREAD = 2,
	PROCESS_SET_SESSIONID = 4,
	PROCESS_VM_OPERATION = 8,
	PROCESS_VM_READ = 16,
	PROCESS_VM_WRITE = 32,
	PROCESS_DUP_HANDLE = 64,
	PROCESS_CREATE_PROCESS = 128,
	PROCESS_SET_QUOTA = 256,
	PROCESS_SET_INFORMATION = 512,
	PROCESS_QUERY_INFORMATION = 1024,
	PROCESS_SUSPEND_RESUME = 2048,
	PROCESS_QUERY_LIMITED_INFORMATION = 4096,
	PROCESS_SET_LIMITED_INFORMATION = 8192,
	PROCESS_ALL_ACCESS = 2097151,
	PROCESS_DELETE = 65536,
	PROCESS_READ_CONTROL = 131072,
	PROCESS_WRITE_DAC = 262144,
	PROCESS_WRITE_OWNER = 524288,
	PROCESS_SYNCHRONIZE = 1048576,
	PROCESS_STANDARD_RIGHTS_REQUIRED = 983040,
}


[AllowDuplicates]
public enum QUEUE_USER_APC_FLAGS : int32
{
	QUEUE_USER_APC_FLAGS_NONE = 0,
	QUEUE_USER_APC_FLAGS_SPECIAL_USER_APC = 1,
}


[AllowDuplicates]
public enum THREAD_INFORMATION_CLASS : int32
{
	ThreadMemoryPriority = 0,
	ThreadAbsoluteCpuPriority = 1,
	ThreadDynamicCodePolicy = 2,
	ThreadPowerThrottling = 3,
	ThreadInformationClassMax = 4,
}


[AllowDuplicates]
public enum PROCESS_INFORMATION_CLASS : int32
{
	ProcessMemoryPriority = 0,
	ProcessMemoryExhaustionInfo = 1,
	ProcessAppMemoryInfo = 2,
	ProcessInPrivateInfo = 3,
	ProcessPowerThrottling = 4,
	ProcessReservedValue1 = 5,
	ProcessTelemetryCoverageInfo = 6,
	ProcessProtectionLevelInfo = 7,
	ProcessLeapSecondInfo = 8,
	ProcessMachineTypeInfo = 9,
	ProcessInformationClassMax = 10,
}


[AllowDuplicates]
public enum MACHINE_ATTRIBUTES : uint32
{
	UserEnabled = 1,
	KernelEnabled = 2,
	Wow64Container = 4,
}


[AllowDuplicates]
public enum PROCESS_MEMORY_EXHAUSTION_TYPE : int32
{
	PMETypeFailFastOnCommitFailure = 0,
	PMETypeMax = 1,
}


[AllowDuplicates]
public enum AVRT_PRIORITY : int32
{
	AVRT_PRIORITY_VERYLOW = -2,
	AVRT_PRIORITY_LOW = -1,
	AVRT_PRIORITY_NORMAL = 0,
	AVRT_PRIORITY_HIGH = 1,
	AVRT_PRIORITY_CRITICAL = 2,
}


[AllowDuplicates]
public enum PROCESS_MITIGATION_POLICY : int32
{
	ProcessDEPPolicy = 0,
	ProcessASLRPolicy = 1,
	ProcessDynamicCodePolicy = 2,
	ProcessStrictHandleCheckPolicy = 3,
	ProcessSystemCallDisablePolicy = 4,
	ProcessMitigationOptionsMask = 5,
	ProcessExtensionPointDisablePolicy = 6,
	ProcessControlFlowGuardPolicy = 7,
	ProcessSignaturePolicy = 8,
	ProcessFontDisablePolicy = 9,
	ProcessImageLoadPolicy = 10,
	ProcessSystemCallFilterPolicy = 11,
	ProcessPayloadRestrictionPolicy = 12,
	ProcessChildProcessPolicy = 13,
	ProcessSideChannelIsolationPolicy = 14,
	ProcessUserShadowStackPolicy = 15,
	ProcessRedirectionTrustPolicy = 16,
	MaxProcessMitigationPolicy = 17,
}


[AllowDuplicates]
public enum RTL_UMS_THREAD_INFO_CLASS : int32
{
	UmsThreadInvalidInfoClass = 0,
	UmsThreadUserContext = 1,
	UmsThreadPriority = 2,
	UmsThreadAffinity = 3,
	UmsThreadTeb = 4,
	UmsThreadIsSuspended = 5,
	UmsThreadIsTerminated = 6,
	UmsThreadMaxInfoClass = 7,
}


[AllowDuplicates]
public enum TP_CALLBACK_PRIORITY : int32
{
	TP_CALLBACK_PRIORITY_HIGH = 0,
	TP_CALLBACK_PRIORITY_NORMAL = 1,
	TP_CALLBACK_PRIORITY_LOW = 2,
	TP_CALLBACK_PRIORITY_INVALID = 3,
	TP_CALLBACK_PRIORITY_COUNT = 3,
}


[AllowDuplicates]
public enum PROC_THREAD_ATTRIBUTE_NUM : uint32
{
	ProcThreadAttributeParentProcess = 0,
	ProcThreadAttributeHandleList = 2,
	ProcThreadAttributeGroupAffinity = 3,
	ProcThreadAttributePreferredNode = 4,
	ProcThreadAttributeIdealProcessor = 5,
	ProcThreadAttributeUmsThread = 6,
	ProcThreadAttributeMitigationPolicy = 7,
	ProcThreadAttributeSecurityCapabilities = 9,
	ProcThreadAttributeProtectionLevel = 11,
	ProcThreadAttributeJobList = 13,
	ProcThreadAttributeChildProcessPolicy = 14,
	ProcThreadAttributeAllApplicationPackagesPolicy = 15,
	ProcThreadAttributeWin32kFilter = 16,
	ProcThreadAttributeSafeOpenPromptOriginClaim = 17,
	ProcThreadAttributeDesktopAppPolicy = 18,
	ProcThreadAttributePseudoConsole = 22,
	ProcThreadAttributeMitigationAuditPolicy = 24,
	ProcThreadAttributeMachineType = 25,
	ProcThreadAttributeComponentFilter = 26,
	ProcThreadAttributeEnableOptionalXStateFeatures = 27,
}


[AllowDuplicates]
public enum PROCESSINFOCLASS : int32
{
	ProcessBasicInformation = 0,
	ProcessDebugPort = 7,
	ProcessWow64Information = 26,
	ProcessImageFileName = 27,
	ProcessBreakOnTermination = 29,
}


[AllowDuplicates]
public enum THREADINFOCLASS : int32
{
	ThreadIsIoPending = 16,
	ThreadNameInformation = 38,
}

#endregion

#region Function Pointers
public function uint32 LPTHREAD_START_ROUTINE(void* lpThreadParameter);

public function BOOL PINIT_ONCE_FN(RTL_RUN_ONCE* InitOnce, void* Parameter, void** Context);

public function void PTIMERAPCROUTINE(void* lpArgToCompletionRoutine, uint32 dwTimerLowValue, uint32 dwTimerHighValue);

public function void PTP_WIN32_IO_CALLBACK(TP_CALLBACK_INSTANCE* Instance, void* Context, void* Overlapped, uint32 IoResult, uint NumberOfBytesTransferred, TP_IO* Io);

public function void PRTL_UMS_SCHEDULER_ENTRY_POINT(RTL_UMS_SCHEDULER_REASON Reason, uint ActivationPayload, void* SchedulerParam);

public function void WAITORTIMERCALLBACK(void* param0, BOOLEAN param1);

public function void PFLS_CALLBACK_FUNCTION(void* lpFlsData);

public function void PTP_SIMPLE_CALLBACK(TP_CALLBACK_INSTANCE* Instance, void* Context);

public function void PTP_CLEANUP_GROUP_CANCEL_CALLBACK(void* ObjectContext, void* CleanupContext);

public function void PTP_WORK_CALLBACK(TP_CALLBACK_INSTANCE* Instance, void* Context, TP_WORK* Work);

public function void PTP_TIMER_CALLBACK(TP_CALLBACK_INSTANCE* Instance, void* Context, TP_TIMER* Timer);

public function void PTP_WAIT_CALLBACK(TP_CALLBACK_INSTANCE* Instance, void* Context, TP_WAIT* Wait, uint32 WaitResult);

public function void LPFIBER_START_ROUTINE(void* lpFiberParameter);

public function void PPS_POST_PROCESS_INIT_ROUTINE();

#endregion

#region Structs
[CRepr]
public struct TP_CALLBACK_INSTANCE
{
}

[CRepr]
public struct TP_WORK
{
}

[CRepr]
public struct TP_TIMER
{
}

[CRepr]
public struct TP_WAIT
{
}

[CRepr]
public struct TP_IO
{
}

[CRepr]
public struct REASON_CONTEXT
{
	[CRepr, Union]
	public struct _Reason_e__Union
	{
		[CRepr]
		public struct _Detailed_e__Struct
		{
			public HINSTANCE LocalizedReasonModule;
			public uint32 LocalizedReasonId;
			public uint32 ReasonStringCount;
			public PWSTR* ReasonStrings;
		}
		public _Detailed_e__Struct Detailed;
		public PWSTR SimpleReasonString;
	}
	public uint32 Version;
	public POWER_REQUEST_CONTEXT_FLAGS Flags;
	public _Reason_e__Union Reason;
}

[CRepr]
public struct PROCESS_INFORMATION
{
	public HANDLE hProcess;
	public HANDLE hThread;
	public uint32 dwProcessId;
	public uint32 dwThreadId;
}

[CRepr]
public struct STARTUPINFOA
{
	public uint32 cb;
	public PSTR lpReserved;
	public PSTR lpDesktop;
	public PSTR lpTitle;
	public uint32 dwX;
	public uint32 dwY;
	public uint32 dwXSize;
	public uint32 dwYSize;
	public uint32 dwXCountChars;
	public uint32 dwYCountChars;
	public uint32 dwFillAttribute;
	public STARTUPINFOW_FLAGS dwFlags;
	public uint16 wShowWindow;
	public uint16 cbReserved2;
	public uint8* lpReserved2;
	public HANDLE hStdInput;
	public HANDLE hStdOutput;
	public HANDLE hStdError;
}

[CRepr]
public struct STARTUPINFOW
{
	public uint32 cb;
	public PWSTR lpReserved;
	public PWSTR lpDesktop;
	public PWSTR lpTitle;
	public uint32 dwX;
	public uint32 dwY;
	public uint32 dwXSize;
	public uint32 dwYSize;
	public uint32 dwXCountChars;
	public uint32 dwYCountChars;
	public uint32 dwFillAttribute;
	public STARTUPINFOW_FLAGS dwFlags;
	public uint16 wShowWindow;
	public uint16 cbReserved2;
	public uint8* lpReserved2;
	public HANDLE hStdInput;
	public HANDLE hStdOutput;
	public HANDLE hStdError;
}

[CRepr]
public struct MEMORY_PRIORITY_INFORMATION
{
	public MEMORY_PRIORITY MemoryPriority;
}

[CRepr]
public struct THREAD_POWER_THROTTLING_STATE
{
	public uint32 Version;
	public uint32 ControlMask;
	public uint32 StateMask;
}

[CRepr]
public struct APP_MEMORY_INFORMATION
{
	public uint64 AvailableCommit;
	public uint64 PrivateCommitUsage;
	public uint64 PeakPrivateCommitUsage;
	public uint64 TotalCommitUsage;
}

[CRepr]
public struct PROCESS_MACHINE_INFORMATION
{
	public IMAGE_FILE_MACHINE ProcessMachine;
	public uint16 Res0;
	public MACHINE_ATTRIBUTES MachineAttributes;
}

[CRepr]
public struct PROCESS_MEMORY_EXHAUSTION_INFO
{
	public uint16 Version;
	public uint16 Reserved;
	public PROCESS_MEMORY_EXHAUSTION_TYPE Type;
	public uint Value;
}

[CRepr]
public struct PROCESS_POWER_THROTTLING_STATE
{
	public uint32 Version;
	public uint32 ControlMask;
	public uint32 StateMask;
}

[CRepr]
public struct PROCESS_PROTECTION_LEVEL_INFORMATION
{
	public PROCESS_PROTECTION_LEVEL ProtectionLevel;
}

[CRepr]
public struct PROCESS_LEAP_SECOND_INFO
{
	public uint32 Flags;
	public uint32 Reserved;
}

[CRepr]
public struct PROCESS_DYNAMIC_EH_CONTINUATION_TARGET
{
	public uint TargetAddress;
	public uint Flags;
}

[CRepr]
public struct PROCESS_DYNAMIC_EH_CONTINUATION_TARGETS_INFORMATION
{
	public uint16 NumberOfTargets;
	public uint16 Reserved;
	public uint32 Reserved2;
	public PROCESS_DYNAMIC_EH_CONTINUATION_TARGET* Targets;
}

[CRepr]
public struct PROCESS_DYNAMIC_ENFORCED_ADDRESS_RANGE
{
	public uint BaseAddress;
	public uint Size;
	public uint32 Flags;
}

[CRepr]
public struct PROCESS_DYNAMIC_ENFORCED_ADDRESS_RANGES_INFORMATION
{
	public uint16 NumberOfRanges;
	public uint16 Reserved;
	public uint32 Reserved2;
	public PROCESS_DYNAMIC_ENFORCED_ADDRESS_RANGE* Ranges;
}

[CRepr]
public struct IO_COUNTERS
{
	public uint64 ReadOperationCount;
	public uint64 WriteOperationCount;
	public uint64 OtherOperationCount;
	public uint64 ReadTransferCount;
	public uint64 WriteTransferCount;
	public uint64 OtherTransferCount;
}

[CRepr, Union]
public struct RTL_RUN_ONCE
{
	public void* Ptr;
}

[CRepr]
public struct RTL_BARRIER
{
	public uint32 Reserved1;
	public uint32 Reserved2;
	public uint[2] Reserved3;
	public uint32 Reserved4;
	public uint32 Reserved5;
}

[CRepr]
public struct RTL_CRITICAL_SECTION_DEBUG
{
	public uint16 Type;
	public uint16 CreatorBackTraceIndex;
	public RTL_CRITICAL_SECTION* CriticalSection;
	public LIST_ENTRY ProcessLocksList;
	public uint32 EntryCount;
	public uint32 ContentionCount;
	public uint32 Flags;
	public uint16 CreatorBackTraceIndexHigh;
	public uint16 SpareWORD;
}

[CRepr]
public struct RTL_CRITICAL_SECTION
{
	public RTL_CRITICAL_SECTION_DEBUG* DebugInfo;
	public int32 LockCount;
	public int32 RecursionCount;
	public HANDLE OwningThread;
	public HANDLE LockSemaphore;
	public uint SpinCount;
}

[CRepr]
public struct RTL_SRWLOCK
{
	public void* Ptr;
}

[CRepr]
public struct RTL_CONDITION_VARIABLE
{
	public void* Ptr;
}

[CRepr]
public struct TP_POOL_STACK_INFORMATION
{
	public uint StackReserve;
	public uint StackCommit;
}

[CRepr]
public struct TP_CALLBACK_ENVIRON_V3
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		[CRepr]
		public struct _s_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public _s_e__Struct s;
	}
	[CRepr]
	public struct _ACTIVATION_CONTEXT
	{
	}
	public uint32 Version;
	public PTP_POOL Pool;
	public int CleanupGroup;
	public PTP_CLEANUP_GROUP_CANCEL_CALLBACK CleanupGroupCancelCallback;
	public void* RaceDll;
	public int ActivationContext;
	public PTP_SIMPLE_CALLBACK FinalizationCallback;
	public _u_e__Union u;
	public TP_CALLBACK_PRIORITY CallbackPriority;
	public uint32 Size;
}

[CRepr]
public struct UMS_SCHEDULER_STARTUP_INFO
{
	public uint32 UmsVersion;
	public void* CompletionList;
	public PRTL_UMS_SCHEDULER_ENTRY_POINT SchedulerProc;
	public void* SchedulerParam;
}

[CRepr]
public struct UMS_SYSTEM_THREAD_INFORMATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 ThreadUmsFlags;
	}
	public uint32 UmsVersion;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct STARTUPINFOEXA
{
	public STARTUPINFOA StartupInfo;
	public LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList;
}

[CRepr]
public struct STARTUPINFOEXW
{
	public STARTUPINFOW StartupInfo;
	public LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList;
}

[CRepr]
public struct PEB_LDR_DATA
{
	public uint8[8] Reserved1;
	public void*[3] Reserved2;
	public LIST_ENTRY InMemoryOrderModuleList;
}

[CRepr]
public struct RTL_USER_PROCESS_PARAMETERS
{
	public uint8[16] Reserved1;
	public void*[10] Reserved2;
	public UNICODE_STRING ImagePathName;
	public UNICODE_STRING CommandLine;
}

[CRepr]
public struct PEB
{
	public uint8[2] Reserved1;
	public uint8 BeingDebugged;
	public uint8* Reserved2 mut => &Reserved2_impl;
	private uint8[ANYSIZE_ARRAY] Reserved2_impl;
	public void*[2] Reserved3;
	public PEB_LDR_DATA* Ldr;
	public RTL_USER_PROCESS_PARAMETERS* ProcessParameters;
	public void*[3] Reserved4;
	public void* AtlThunkSListPtr;
	public void* Reserved5;
	public uint32 Reserved6;
	public void* Reserved7;
	public uint32 Reserved8;
	public uint32 AtlThunkSListPtr32;
	public void*[45] Reserved9;
	public uint8[96] Reserved10;
	public PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
	public uint8[128] Reserved11;
	public void** Reserved12 mut => &Reserved12_impl;
	private void*[ANYSIZE_ARRAY] Reserved12_impl;
	public uint32 SessionId;
}

[CRepr]
public struct PROCESS_BASIC_INFORMATION
{
	public void* Reserved1;
	public PEB* PebBaseAddress;
	public void*[2] Reserved2;
	public uint UniqueProcessId;
	public void* Reserved3;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessWorkingSetSize(HANDLE hProcess, uint* lpMinimumWorkingSetSize, uint* lpMaximumWorkingSetSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessWorkingSetSize(HANDLE hProcess, uint dwMinimumWorkingSetSize, uint dwMaximumWorkingSetSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FlsAlloc(PFLS_CALLBACK_FUNCTION lpCallback);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* FlsGetValue(uint32 dwFlsIndex);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlsSetValue(uint32 dwFlsIndex, void* lpFlsData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlsFree(uint32 dwFlsIndex);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsThreadAFiber();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitializeSRWLock(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ReleaseSRWLockExclusive(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ReleaseSRWLockShared(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void AcquireSRWLockExclusive(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void AcquireSRWLockShared(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN TryAcquireSRWLockExclusive(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN TryAcquireSRWLockShared(RTL_SRWLOCK* SRWLock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitializeCriticalSection(RTL_CRITICAL_SECTION* lpCriticalSection);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EnterCriticalSection(RTL_CRITICAL_SECTION* lpCriticalSection);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LeaveCriticalSection(RTL_CRITICAL_SECTION* lpCriticalSection);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeCriticalSectionAndSpinCount(RTL_CRITICAL_SECTION* lpCriticalSection, uint32 dwSpinCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeCriticalSectionEx(RTL_CRITICAL_SECTION* lpCriticalSection, uint32 dwSpinCount, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetCriticalSectionSpinCount(RTL_CRITICAL_SECTION* lpCriticalSection, uint32 dwSpinCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TryEnterCriticalSection(RTL_CRITICAL_SECTION* lpCriticalSection);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeleteCriticalSection(RTL_CRITICAL_SECTION* lpCriticalSection);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitOnceInitialize(RTL_RUN_ONCE* InitOnce);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitOnceExecuteOnce(RTL_RUN_ONCE* InitOnce, PINIT_ONCE_FN InitFn, void* Parameter, void** Context);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitOnceBeginInitialize(RTL_RUN_ONCE* lpInitOnce, uint32 dwFlags, BOOL* fPending, void** lpContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitOnceComplete(RTL_RUN_ONCE* lpInitOnce, uint32 dwFlags, void* lpContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitializeConditionVariable(RTL_CONDITION_VARIABLE* ConditionVariable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WakeConditionVariable(RTL_CONDITION_VARIABLE* ConditionVariable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WakeAllConditionVariable(RTL_CONDITION_VARIABLE* ConditionVariable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SleepConditionVariableCS(RTL_CONDITION_VARIABLE* ConditionVariable, RTL_CRITICAL_SECTION* CriticalSection, uint32 dwMilliseconds);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SleepConditionVariableSRW(RTL_CONDITION_VARIABLE* ConditionVariable, RTL_SRWLOCK* SRWLock, uint32 dwMilliseconds, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEvent(HANDLE hEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResetEvent(HANDLE hEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReleaseSemaphore(HANDLE hSemaphore, int32 lReleaseCount, int32* lpPreviousCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReleaseMutex(HANDLE hMutex);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR WaitForSingleObject(HANDLE hHandle, uint32 dwMilliseconds);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SleepEx(uint32 dwMilliseconds, BOOL bAlertable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR WaitForSingleObjectEx(HANDLE hHandle, uint32 dwMilliseconds, BOOL bAlertable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR WaitForMultipleObjectsEx(uint32 nCount, HANDLE* lpHandles, BOOL bWaitAll, uint32 dwMilliseconds, BOOL bAlertable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateMutexA(SECURITY_ATTRIBUTES* lpMutexAttributes, BOOL bInitialOwner, PSTR lpName);
	public static HANDLE CreateMutex(SECURITY_ATTRIBUTES* lpMutexAttributes, BOOL bInitialOwner, PSTR lpName) => CreateMutexA(lpMutexAttributes, bInitialOwner, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateMutexW(SECURITY_ATTRIBUTES* lpMutexAttributes, BOOL bInitialOwner, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenMutexW(SYNCHRONIZATION_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateEventA(SECURITY_ATTRIBUTES* lpEventAttributes, BOOL bManualReset, BOOL bInitialState, PSTR lpName);
	public static HANDLE CreateEvent(SECURITY_ATTRIBUTES* lpEventAttributes, BOOL bManualReset, BOOL bInitialState, PSTR lpName) => CreateEventA(lpEventAttributes, bManualReset, bInitialState, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateEventW(SECURITY_ATTRIBUTES* lpEventAttributes, BOOL bManualReset, BOOL bInitialState, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenEventA(SYNCHRONIZATION_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, PSTR lpName);
	public static HANDLE OpenEvent(SYNCHRONIZATION_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, PSTR lpName) => OpenEventA(dwDesiredAccess, bInheritHandle, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenEventW(SYNCHRONIZATION_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenSemaphoreW(SYNCHRONIZATION_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenWaitableTimerW(SYNCHRONIZATION_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, PWSTR lpTimerName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWaitableTimerEx(HANDLE hTimer, LARGE_INTEGER* lpDueTime, int32 lPeriod, PTIMERAPCROUTINE pfnCompletionRoutine, void* lpArgToCompletionRoutine, REASON_CONTEXT* WakeContext, uint32 TolerableDelay);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWaitableTimer(HANDLE hTimer, LARGE_INTEGER* lpDueTime, int32 lPeriod, PTIMERAPCROUTINE pfnCompletionRoutine, void* lpArgToCompletionRoutine, BOOL fResume);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelWaitableTimer(HANDLE hTimer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateMutexExA(SECURITY_ATTRIBUTES* lpMutexAttributes, PSTR lpName, uint32 dwFlags, uint32 dwDesiredAccess);
	public static HANDLE CreateMutexEx(SECURITY_ATTRIBUTES* lpMutexAttributes, PSTR lpName, uint32 dwFlags, uint32 dwDesiredAccess) => CreateMutexExA(lpMutexAttributes, lpName, dwFlags, dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateMutexExW(SECURITY_ATTRIBUTES* lpMutexAttributes, PWSTR lpName, uint32 dwFlags, uint32 dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateEventExA(SECURITY_ATTRIBUTES* lpEventAttributes, PSTR lpName, CREATE_EVENT dwFlags, uint32 dwDesiredAccess);
	public static HANDLE CreateEventEx(SECURITY_ATTRIBUTES* lpEventAttributes, PSTR lpName, CREATE_EVENT dwFlags, uint32 dwDesiredAccess) => CreateEventExA(lpEventAttributes, lpName, dwFlags, dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateEventExW(SECURITY_ATTRIBUTES* lpEventAttributes, PWSTR lpName, CREATE_EVENT dwFlags, uint32 dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateSemaphoreExW(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int32 lInitialCount, int32 lMaximumCount, PWSTR lpName, uint32 dwFlags, uint32 dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateWaitableTimerExW(SECURITY_ATTRIBUTES* lpTimerAttributes, PWSTR lpTimerName, uint32 dwFlags, uint32 dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnterSynchronizationBarrier(RTL_BARRIER* lpBarrier, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeSynchronizationBarrier(RTL_BARRIER* lpBarrier, int32 lTotalThreads, int32 lSpinCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteSynchronizationBarrier(RTL_BARRIER* lpBarrier);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void Sleep(uint32 dwMilliseconds);

	[Import("api-ms-win-core-synch-l1-2-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WaitOnAddress(void* Address, void* CompareAddress, uint AddressSize, uint32 dwMilliseconds);

	[Import("api-ms-win-core-synch-l1-2-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WakeByAddressSingle(void* Address);

	[Import("api-ms-win-core-synch-l1-2-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WakeByAddressAll(void* Address);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR WaitForMultipleObjects(uint32 nCount, HANDLE* lpHandles, BOOL bWaitAll, uint32 dwMilliseconds);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateSemaphoreW(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int32 lInitialCount, int32 lMaximumCount, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateWaitableTimerW(SECURITY_ATTRIBUTES* lpTimerAttributes, BOOL bManualReset, PWSTR lpTimerName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InitializeSListHead(SLIST_HEADER* ListHead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* InterlockedPopEntrySList(SLIST_HEADER* ListHead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* InterlockedPushEntrySList(SLIST_HEADER* ListHead, SLIST_ENTRY* ListEntry);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* InterlockedPushListSListEx(SLIST_HEADER* ListHead, SLIST_ENTRY* List, SLIST_ENTRY* ListEnd, uint32 Count);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* InterlockedFlushSList(SLIST_HEADER* ListHead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 QueryDepthSList(SLIST_HEADER* ListHead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueueUserAPC(PAPCFUNC pfnAPC, HANDLE hThread, uint dwData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueueUserAPC2(PAPCFUNC ApcRoutine, HANDLE Thread, uint Data, QUEUE_USER_APC_FLAGS Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessTimes(HANDLE hProcess, FILETIME* lpCreationTime, FILETIME* lpExitTime, FILETIME* lpKernelTime, FILETIME* lpUserTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GetCurrentProcess();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCurrentProcessId();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ExitProcess(uint32 uExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TerminateProcess(HANDLE hProcess, uint32 uExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetExitCodeProcess(HANDLE hProcess, uint32* lpExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SwitchToThread();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateThread(SECURITY_ATTRIBUTES* lpThreadAttributes, uint dwStackSize, LPTHREAD_START_ROUTINE lpStartAddress, void* lpParameter, THREAD_CREATION_FLAGS dwCreationFlags, uint32* lpThreadId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateRemoteThread(HANDLE hProcess, SECURITY_ATTRIBUTES* lpThreadAttributes, uint dwStackSize, LPTHREAD_START_ROUTINE lpStartAddress, void* lpParameter, uint32 dwCreationFlags, uint32* lpThreadId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GetCurrentThread();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCurrentThreadId();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenThread(THREAD_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, uint32 dwThreadId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadPriority(HANDLE hThread, THREAD_PRIORITY nPriority);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadPriorityBoost(HANDLE hThread, BOOL bDisablePriorityBoost);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadPriorityBoost(HANDLE hThread, BOOL* pDisablePriorityBoost);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetThreadPriority(HANDLE hThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ExitThread(uint32 dwExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TerminateThread(HANDLE hThread, uint32 dwExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetExitCodeThread(HANDLE hThread, uint32* lpExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SuspendThread(HANDLE hThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResumeThread(HANDLE hThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TlsAlloc();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* TlsGetValue(uint32 dwTlsIndex);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TlsSetValue(uint32 dwTlsIndex, void* lpTlsValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TlsFree(uint32 dwTlsIndex);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProcessA(PSTR lpApplicationName, PSTR lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandles, PROCESS_CREATION_FLAGS dwCreationFlags, void* lpEnvironment, PSTR lpCurrentDirectory, STARTUPINFOA* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);
	public static BOOL CreateProcess(PSTR lpApplicationName, PSTR lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandles, PROCESS_CREATION_FLAGS dwCreationFlags, void* lpEnvironment, PSTR lpCurrentDirectory, STARTUPINFOA* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation) => CreateProcessA(lpApplicationName, lpCommandLine, lpProcessAttributes, lpThreadAttributes, bInheritHandles, dwCreationFlags, lpEnvironment, lpCurrentDirectory, lpStartupInfo, lpProcessInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProcessW(PWSTR lpApplicationName, PWSTR lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandles, PROCESS_CREATION_FLAGS dwCreationFlags, void* lpEnvironment, PWSTR lpCurrentDirectory, STARTUPINFOW* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessShutdownParameters(uint32 dwLevel, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProcessVersion(uint32 ProcessId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetStartupInfoW(STARTUPINFOW* lpStartupInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProcessAsUserW(HANDLE hToken, PWSTR lpApplicationName, PWSTR lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandles, uint32 dwCreationFlags, void* lpEnvironment, PWSTR lpCurrentDirectory, STARTUPINFOW* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadToken(HANDLE* Thread, HANDLE Token);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenProcessToken(HANDLE ProcessHandle, TOKEN_ACCESS_MASK DesiredAccess, HANDLE* TokenHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenThreadToken(HANDLE ThreadHandle, TOKEN_ACCESS_MASK DesiredAccess, BOOL OpenAsSelf, HANDLE* TokenHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPriorityClass(HANDLE hProcess, PROCESS_CREATION_FLAGS dwPriorityClass);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPriorityClass(HANDLE hProcess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadStackGuarantee(uint32* StackSizeInBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProcessId(HANDLE Process);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetThreadId(HANDLE Thread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FlushProcessWriteBuffers();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProcessIdOfThread(HANDLE Thread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeProcThreadAttributeList(LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList, uint32 dwAttributeCount, uint32 dwFlags, uint* lpSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeleteProcThreadAttributeList(LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateProcThreadAttribute(LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList, uint32 dwFlags, uint Attribute, void* lpValue, uint cbSize, void* lpPreviousValue, uint* lpReturnSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessDynamicEHContinuationTargets(HANDLE Process, uint16 NumberOfTargets, PROCESS_DYNAMIC_EH_CONTINUATION_TARGET* Targets);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessDynamicEnforcedCetCompatibleRanges(HANDLE Process, uint16 NumberOfRanges, PROCESS_DYNAMIC_ENFORCED_ADDRESS_RANGE* Ranges);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessAffinityUpdateMode(HANDLE hProcess, PROCESS_AFFINITY_AUTO_UPDATE_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryProcessAffinityUpdateMode(HANDLE hProcess, PROCESS_AFFINITY_AUTO_UPDATE_FLAGS* lpdwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateRemoteThreadEx(HANDLE hProcess, SECURITY_ATTRIBUTES* lpThreadAttributes, uint dwStackSize, LPTHREAD_START_ROUTINE lpStartAddress, void* lpParameter, uint32 dwCreationFlags, LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList, uint32* lpThreadId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetCurrentThreadStackLimits(uint* LowLimit, uint* HighLimit);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessMitigationPolicy(HANDLE hProcess, PROCESS_MITIGATION_POLICY MitigationPolicy, void* lpBuffer, uint dwLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessMitigationPolicy(PROCESS_MITIGATION_POLICY MitigationPolicy, void* lpBuffer, uint dwLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadTimes(HANDLE hThread, FILETIME* lpCreationTime, FILETIME* lpExitTime, FILETIME* lpKernelTime, FILETIME* lpUserTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenProcess(PROCESS_ACCESS_RIGHTS dwDesiredAccess, BOOL bInheritHandle, uint32 dwProcessId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsProcessorFeaturePresent(PROCESSOR_FEATURE_ID ProcessorFeature);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessHandleCount(HANDLE hProcess, uint32* pdwHandleCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCurrentProcessorNumber();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadIdealProcessorEx(HANDLE hThread, PROCESSOR_NUMBER* lpIdealProcessor, PROCESSOR_NUMBER* lpPreviousIdealProcessor);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadIdealProcessorEx(HANDLE hThread, PROCESSOR_NUMBER* lpIdealProcessor);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetCurrentProcessorNumberEx(PROCESSOR_NUMBER* ProcNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessPriorityBoost(HANDLE hProcess, BOOL* pDisablePriorityBoost);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessPriorityBoost(HANDLE hProcess, BOOL bDisablePriorityBoost);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadIOPendingFlag(HANDLE hThread, BOOL* lpIOIsPending);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemTimes(FILETIME* lpIdleTime, FILETIME* lpKernelTime, FILETIME* lpUserTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadInformation(HANDLE hThread, THREAD_INFORMATION_CLASS ThreadInformationClass, void* ThreadInformation, uint32 ThreadInformationSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadInformation(HANDLE hThread, THREAD_INFORMATION_CLASS ThreadInformationClass, void* ThreadInformation, uint32 ThreadInformationSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsProcessCritical(HANDLE hProcess, BOOL* Critical);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProtectedPolicy(in Guid PolicyGuid, uint PolicyValue, uint* OldPolicyValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryProtectedPolicy(in Guid PolicyGuid, uint* PolicyValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetThreadIdealProcessor(HANDLE hThread, uint32 dwIdealProcessor);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessInformation(HANDLE hProcess, PROCESS_INFORMATION_CLASS ProcessInformationClass, void* ProcessInformation, uint32 ProcessInformationSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessInformation(HANDLE hProcess, PROCESS_INFORMATION_CLASS ProcessInformationClass, void* ProcessInformation, uint32 ProcessInformationSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessDefaultCpuSets(HANDLE Process, uint32* CpuSetIds, uint32 CpuSetIdCount, uint32* RequiredIdCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessDefaultCpuSets(HANDLE Process, uint32* CpuSetIds, uint32 CpuSetIdCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadSelectedCpuSets(HANDLE Thread, uint32* CpuSetIds, uint32 CpuSetIdCount, uint32* RequiredIdCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadSelectedCpuSets(HANDLE Thread, uint32* CpuSetIds, uint32 CpuSetIdCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProcessAsUserA(HANDLE hToken, PSTR lpApplicationName, PSTR lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandles, uint32 dwCreationFlags, void* lpEnvironment, PSTR lpCurrentDirectory, STARTUPINFOA* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);
	public static BOOL CreateProcessAsUser(HANDLE hToken, PSTR lpApplicationName, PSTR lpCommandLine, SECURITY_ATTRIBUTES* lpProcessAttributes, SECURITY_ATTRIBUTES* lpThreadAttributes, BOOL bInheritHandles, uint32 dwCreationFlags, void* lpEnvironment, PSTR lpCurrentDirectory, STARTUPINFOA* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation) => CreateProcessAsUserA(hToken, lpApplicationName, lpCommandLine, lpProcessAttributes, lpThreadAttributes, bInheritHandles, dwCreationFlags, lpEnvironment, lpCurrentDirectory, lpStartupInfo, lpProcessInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessShutdownParameters(uint32* lpdwLevel, uint32* lpdwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessDefaultCpuSetMasks(HANDLE Process, GROUP_AFFINITY* CpuSetMasks, uint16 CpuSetMaskCount, uint16* RequiredMaskCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessDefaultCpuSetMasks(HANDLE Process, GROUP_AFFINITY* CpuSetMasks, uint16 CpuSetMaskCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadSelectedCpuSetMasks(HANDLE Thread, GROUP_AFFINITY* CpuSetMasks, uint16 CpuSetMaskCount, uint16* RequiredMaskCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadSelectedCpuSetMasks(HANDLE Thread, GROUP_AFFINITY* CpuSetMasks, uint16 CpuSetMaskCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetMachineTypeAttributes(uint16 Machine, MACHINE_ATTRIBUTES* MachineTypeAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetThreadDescription(HANDLE hThread, PWSTR lpThreadDescription);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetThreadDescription(HANDLE hThread, PWSTR* ppszThreadDescription);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueueUserWorkItem(LPTHREAD_START_ROUTINE Function, void* Context, WORKER_THREAD_FLAGS Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterWaitEx(HANDLE WaitHandle, HANDLE CompletionEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateTimerQueue();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateTimerQueueTimer(HANDLE* phNewTimer, HANDLE TimerQueue, WAITORTIMERCALLBACK Callback, void* Parameter, uint32 DueTime, uint32 Period, WORKER_THREAD_FLAGS Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChangeTimerQueueTimer(HANDLE TimerQueue, HANDLE Timer, uint32 DueTime, uint32 Period);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteTimerQueueTimer(HANDLE TimerQueue, HANDLE Timer, HANDLE CompletionEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteTimerQueue(HANDLE TimerQueue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteTimerQueueEx(HANDLE TimerQueue, HANDLE CompletionEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PTP_POOL CreateThreadpool(void* reserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetThreadpoolThreadMaximum(PTP_POOL ptpp, uint32 cthrdMost);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadpoolThreadMinimum(PTP_POOL ptpp, uint32 cthrdMic);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadpoolStackInformation(PTP_POOL ptpp, TP_POOL_STACK_INFORMATION* ptpsi);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryThreadpoolStackInformation(PTP_POOL ptpp, TP_POOL_STACK_INFORMATION* ptpsi);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpool(PTP_POOL ptpp);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CreateThreadpoolCleanupGroup();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpoolCleanupGroupMembers(int ptpcg, BOOL fCancelPendingCallbacks, void* pvCleanupContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpoolCleanupGroup(int ptpcg);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetEventWhenCallbackReturns(TP_CALLBACK_INSTANCE* pci, HANDLE evt);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ReleaseSemaphoreWhenCallbackReturns(TP_CALLBACK_INSTANCE* pci, HANDLE sem, uint32 crel);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ReleaseMutexWhenCallbackReturns(TP_CALLBACK_INSTANCE* pci, HANDLE @mut);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LeaveCriticalSectionWhenCallbackReturns(TP_CALLBACK_INSTANCE* pci, RTL_CRITICAL_SECTION* pcs);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeLibraryWhenCallbackReturns(TP_CALLBACK_INSTANCE* pci, HINSTANCE mod);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CallbackMayRunLong(TP_CALLBACK_INSTANCE* pci);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DisassociateCurrentThreadFromCallback(TP_CALLBACK_INSTANCE* pci);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TrySubmitThreadpoolCallback(PTP_SIMPLE_CALLBACK pfns, void* pv, TP_CALLBACK_ENVIRON_V3* pcbe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TP_WORK* CreateThreadpoolWork(PTP_WORK_CALLBACK pfnwk, void* pv, TP_CALLBACK_ENVIRON_V3* pcbe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SubmitThreadpoolWork(TP_WORK* pwk);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WaitForThreadpoolWorkCallbacks(TP_WORK* pwk, BOOL fCancelPendingCallbacks);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpoolWork(TP_WORK* pwk);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TP_TIMER* CreateThreadpoolTimer(PTP_TIMER_CALLBACK pfnti, void* pv, TP_CALLBACK_ENVIRON_V3* pcbe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetThreadpoolTimer(TP_TIMER* pti, FILETIME* pftDueTime, uint32 msPeriod, uint32 msWindowLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsThreadpoolTimerSet(TP_TIMER* pti);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WaitForThreadpoolTimerCallbacks(TP_TIMER* pti, BOOL fCancelPendingCallbacks);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpoolTimer(TP_TIMER* pti);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TP_WAIT* CreateThreadpoolWait(PTP_WAIT_CALLBACK pfnwa, void* pv, TP_CALLBACK_ENVIRON_V3* pcbe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetThreadpoolWait(TP_WAIT* pwa, HANDLE h, FILETIME* pftTimeout);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WaitForThreadpoolWaitCallbacks(TP_WAIT* pwa, BOOL fCancelPendingCallbacks);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpoolWait(TP_WAIT* pwa);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TP_IO* CreateThreadpoolIo(HANDLE fl, PTP_WIN32_IO_CALLBACK pfnio, void* pv, TP_CALLBACK_ENVIRON_V3* pcbe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void StartThreadpoolIo(TP_IO* pio);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CancelThreadpoolIo(TP_IO* pio);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WaitForThreadpoolIoCallbacks(TP_IO* pio, BOOL fCancelPendingCallbacks);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseThreadpoolIo(TP_IO* pio);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadpoolTimerEx(TP_TIMER* pti, FILETIME* pftDueTime, uint32 msPeriod, uint32 msWindowLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadpoolWaitEx(TP_WAIT* pwa, HANDLE h, FILETIME* pftTimeout, void* Reserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsWow64Process(HANDLE hProcess, BOOL* Wow64Process);

	[Import("api-ms-win-core-wow64-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 Wow64SetThreadDefaultGuestMachine(uint16 Machine);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsWow64Process2(HANDLE hProcess, IMAGE_FILE_MACHINE* pProcessMachine, IMAGE_FILE_MACHINE* pNativeMachine);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Wow64SuspendThread(HANDLE hThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NamespaceHandle CreatePrivateNamespaceW(SECURITY_ATTRIBUTES* lpPrivateNamespaceAttributes, void* lpBoundaryDescriptor, PWSTR lpAliasPrefix);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NamespaceHandle OpenPrivateNamespaceW(void* lpBoundaryDescriptor, PWSTR lpAliasPrefix);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN ClosePrivateNamespace(NamespaceHandle Handle, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BoundaryDescriptorHandle CreateBoundaryDescriptorW(PWSTR Name, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddSIDToBoundaryDescriptor(HANDLE* BoundaryDescriptor, PSID RequiredSid);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeleteBoundaryDescriptor(BoundaryDescriptorHandle BoundaryDescriptor);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaHighestNodeNumber(uint32* HighestNodeNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaNodeProcessorMaskEx(uint16 Node, GROUP_AFFINITY* ProcessorMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaNodeProcessorMask2(uint16 NodeNumber, GROUP_AFFINITY* ProcessorMasks, uint16 ProcessorMaskCount, uint16* RequiredMaskCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaProximityNodeEx(uint32 ProximityId, uint16* NodeNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessGroupAffinity(HANDLE hProcess, uint16* GroupCount, uint16* GroupArray);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadGroupAffinity(HANDLE hThread, GROUP_AFFINITY* GroupAffinity);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadGroupAffinity(HANDLE hThread, GROUP_AFFINITY* GroupAffinity, GROUP_AFFINITY* PreviousGroupAffinity);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AvSetMmThreadCharacteristicsA(PSTR TaskName, uint32* TaskIndex);
	public static HANDLE AvSetMmThreadCharacteristics(PSTR TaskName, uint32* TaskIndex) => AvSetMmThreadCharacteristicsA(TaskName, TaskIndex);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AvSetMmThreadCharacteristicsW(PWSTR TaskName, uint32* TaskIndex);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AvSetMmMaxThreadCharacteristicsA(PSTR FirstTask, PSTR SecondTask, uint32* TaskIndex);
	public static HANDLE AvSetMmMaxThreadCharacteristics(PSTR FirstTask, PSTR SecondTask, uint32* TaskIndex) => AvSetMmMaxThreadCharacteristicsA(FirstTask, SecondTask, TaskIndex);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AvSetMmMaxThreadCharacteristicsW(PWSTR FirstTask, PWSTR SecondTask, uint32* TaskIndex);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRevertMmThreadCharacteristics(HANDLE AvrtHandle);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvSetMmThreadPriority(HANDLE AvrtHandle, AVRT_PRIORITY Priority);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtCreateThreadOrderingGroup(HANDLE* Context, LARGE_INTEGER* Period, Guid* ThreadOrderingGuid, LARGE_INTEGER* Timeout);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtCreateThreadOrderingGroupExA(HANDLE* Context, LARGE_INTEGER* Period, Guid* ThreadOrderingGuid, LARGE_INTEGER* Timeout, PSTR TaskName);
	public static BOOL AvRtCreateThreadOrderingGroupEx(HANDLE* Context, LARGE_INTEGER* Period, Guid* ThreadOrderingGuid, LARGE_INTEGER* Timeout, PSTR TaskName) => AvRtCreateThreadOrderingGroupExA(Context, Period, ThreadOrderingGuid, Timeout, TaskName);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtCreateThreadOrderingGroupExW(HANDLE* Context, LARGE_INTEGER* Period, Guid* ThreadOrderingGuid, LARGE_INTEGER* Timeout, PWSTR TaskName);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtJoinThreadOrderingGroup(HANDLE* Context, Guid* ThreadOrderingGuid, BOOL Before);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtWaitOnThreadOrderingGroup(HANDLE Context);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtLeaveThreadOrderingGroup(HANDLE Context);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvRtDeleteThreadOrderingGroup(HANDLE Context);

	[Import("AVRT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AvQuerySystemResponsiveness(HANDLE AvrtHandle, uint32* SystemResponsivenessValue);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AttachThreadInput(uint32 idAttach, uint32 idAttachTo, BOOL fAttach);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WaitForInputIdle(HANDLE hProcess, uint32 dwMilliseconds);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetGuiResources(HANDLE hProcess, GET_GUI_RESOURCES_FLAGS uiFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsImmersiveProcess(HANDLE hProcess);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessRestrictionExemption(BOOL fEnableExemption);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessAffinityMask(HANDLE hProcess, uint* lpProcessAffinityMask, uint* lpSystemAffinityMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessAffinityMask(HANDLE hProcess, uint dwProcessAffinityMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessIoCounters(HANDLE hProcess, IO_COUNTERS* lpIoCounters);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SwitchToFiber(void* lpFiber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeleteFiber(void* lpFiber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertFiberToThread();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CreateFiberEx(uint dwStackCommitSize, uint dwStackReserveSize, uint32 dwFlags, LPFIBER_START_ROUTINE lpStartAddress, void* lpParameter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ConvertThreadToFiberEx(void* lpParameter, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CreateFiber(uint dwStackSize, LPFIBER_START_ROUTINE lpStartAddress, void* lpParameter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ConvertThreadToFiber(void* lpParameter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateUmsCompletionList(void** UmsCompletionList);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DequeueUmsCompletionListItems(void* UmsCompletionList, uint32 WaitTimeOut, void** UmsThreadList);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUmsCompletionListEvent(void* UmsCompletionList, HANDLE* UmsCompletionEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ExecuteUmsThread(void* UmsThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UmsThreadYield(void* SchedulerParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteUmsCompletionList(void* UmsCompletionList);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* GetCurrentUmsThread();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* GetNextUmsListItem(void* UmsContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryUmsThreadInformation(void* UmsThread, RTL_UMS_THREAD_INFO_CLASS UmsThreadInfoClass, void* UmsThreadInformation, uint32 UmsThreadInformationLength, uint32* ReturnLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetUmsThreadInformation(void* UmsThread, RTL_UMS_THREAD_INFO_CLASS UmsThreadInfoClass, void* UmsThreadInformation, uint32 UmsThreadInformationLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteUmsThreadContext(void* UmsThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateUmsThreadContext(void** lpUmsThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnterUmsSchedulingMode(UMS_SCHEDULER_STARTUP_INFO* SchedulerStartupInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUmsSystemThreadInformation(HANDLE ThreadHandle, UMS_SYSTEM_THREAD_INFORMATION* SystemThreadInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint SetThreadAffinityMask(HANDLE hThread, uint dwThreadAffinityMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessDEPPolicy(PROCESS_DEP_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessDEPPolicy(HANDLE hProcess, uint32* lpFlags, BOOL* lpPermanent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PulseEvent(HANDLE hEvent);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinExec(PSTR lpCmdLine, uint32 uCmdShow);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateSemaphoreA(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int32 lInitialCount, int32 lMaximumCount, PSTR lpName);
	public static HANDLE CreateSemaphore(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int32 lInitialCount, int32 lMaximumCount, PSTR lpName) => CreateSemaphoreA(lpSemaphoreAttributes, lInitialCount, lMaximumCount, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateSemaphoreExA(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int32 lInitialCount, int32 lMaximumCount, PSTR lpName, uint32 dwFlags, uint32 dwDesiredAccess);
	public static HANDLE CreateSemaphoreEx(SECURITY_ATTRIBUTES* lpSemaphoreAttributes, int32 lInitialCount, int32 lMaximumCount, PSTR lpName, uint32 dwFlags, uint32 dwDesiredAccess) => CreateSemaphoreExA(lpSemaphoreAttributes, lInitialCount, lMaximumCount, lpName, dwFlags, dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryFullProcessImageNameA(HANDLE hProcess, PROCESS_NAME_FORMAT dwFlags, uint8* lpExeName, uint32* lpdwSize);
	public static BOOL QueryFullProcessImageName(HANDLE hProcess, PROCESS_NAME_FORMAT dwFlags, uint8* lpExeName, uint32* lpdwSize) => QueryFullProcessImageNameA(hProcess, dwFlags, lpExeName, lpdwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryFullProcessImageNameW(HANDLE hProcess, PROCESS_NAME_FORMAT dwFlags, char16* lpExeName, uint32* lpdwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetStartupInfoA(STARTUPINFOA* lpStartupInfo);
	public static void GetStartupInfo(STARTUPINFOA* lpStartupInfo) => GetStartupInfoA(lpStartupInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProcessWithLogonW(PWSTR lpUsername, PWSTR lpDomain, PWSTR lpPassword, CREATE_PROCESS_LOGON_FLAGS dwLogonFlags, PWSTR lpApplicationName, PWSTR lpCommandLine, uint32 dwCreationFlags, void* lpEnvironment, PWSTR lpCurrentDirectory, STARTUPINFOW* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProcessWithTokenW(HANDLE hToken, CREATE_PROCESS_LOGON_FLAGS dwLogonFlags, PWSTR lpApplicationName, PWSTR lpCommandLine, uint32 dwCreationFlags, void* lpEnvironment, PWSTR lpCurrentDirectory, STARTUPINFOW* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterWaitForSingleObject(HANDLE* phNewWaitObject, HANDLE hObject, WAITORTIMERCALLBACK Callback, void* Context, uint32 dwMilliseconds, WORKER_THREAD_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterWait(HANDLE WaitHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE SetTimerQueueTimer(HANDLE TimerQueue, WAITORTIMERCALLBACK Callback, void* Parameter, uint32 DueTime, uint32 Period, BOOL PreferIo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NamespaceHandle CreatePrivateNamespaceA(SECURITY_ATTRIBUTES* lpPrivateNamespaceAttributes, void* lpBoundaryDescriptor, PSTR lpAliasPrefix);
	public static NamespaceHandle CreatePrivateNamespace(SECURITY_ATTRIBUTES* lpPrivateNamespaceAttributes, void* lpBoundaryDescriptor, PSTR lpAliasPrefix) => CreatePrivateNamespaceA(lpPrivateNamespaceAttributes, lpBoundaryDescriptor, lpAliasPrefix);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NamespaceHandle OpenPrivateNamespaceA(void* lpBoundaryDescriptor, PSTR lpAliasPrefix);
	public static NamespaceHandle OpenPrivateNamespace(void* lpBoundaryDescriptor, PSTR lpAliasPrefix) => OpenPrivateNamespaceA(lpBoundaryDescriptor, lpAliasPrefix);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BoundaryDescriptorHandle CreateBoundaryDescriptorA(PSTR Name, uint32 Flags);
	public static BoundaryDescriptorHandle CreateBoundaryDescriptor(PSTR Name, uint32 Flags) => CreateBoundaryDescriptorA(Name, Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddIntegrityLabelToBoundaryDescriptor(HANDLE* BoundaryDescriptor, PSID IntegrityLabel);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetActiveProcessorGroupCount();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetMaximumProcessorGroupCount();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetActiveProcessorCount(uint16 GroupNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetMaximumProcessorCount(uint16 GroupNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaProcessorNode(uint8 Processor, uint8* NodeNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaNodeNumberFromHandle(HANDLE hFile, uint16* NodeNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaProcessorNodeEx(PROCESSOR_NUMBER* Processor, uint16* NodeNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaNodeProcessorMask(uint8 Node, uint64* ProcessorMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaAvailableMemoryNode(uint8 Node, uint64* AvailableBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaAvailableMemoryNodeEx(uint16 Node, uint64* AvailableBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumaProximityNode(uint32 ProximityId, uint8* NodeNumber);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQueryInformationProcess(HANDLE ProcessHandle, PROCESSINFOCLASS ProcessInformationClass, void* ProcessInformation, uint32 ProcessInformationLength, uint32* ReturnLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQueryInformationThread(HANDLE ThreadHandle, THREADINFOCLASS ThreadInformationClass, void* ThreadInformation, uint32 ThreadInformationLength, uint32* ReturnLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtSetInformationThread(HANDLE ThreadHandle, THREADINFOCLASS ThreadInformationClass, void* ThreadInformation, uint32 ThreadInformationLength);

}
#endregion
