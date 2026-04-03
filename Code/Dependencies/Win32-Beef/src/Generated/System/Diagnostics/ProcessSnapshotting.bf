using Win32.Foundation;
using Win32.System.Memory;
using Win32.System.Diagnostics.Debug;
using System;

namespace Win32.System.Diagnostics.ProcessSnapshotting;

#region Constants
public static
{
	public const uint32 PSS_PERF_RESOLUTION = 1000000;
}
#endregion

#region TypeDefs
typealias HPSS = int;

typealias HPSSWALK = int;

#endregion


#region Enums

[AllowDuplicates]
public enum PSS_HANDLE_FLAGS : uint32
{
	PSS_HANDLE_NONE = 0,
	PSS_HANDLE_HAVE_TYPE = 1,
	PSS_HANDLE_HAVE_NAME = 2,
	PSS_HANDLE_HAVE_BASIC_INFORMATION = 4,
	PSS_HANDLE_HAVE_TYPE_SPECIFIC_INFORMATION = 8,
}


[AllowDuplicates]
public enum PSS_OBJECT_TYPE : int32
{
	PSS_OBJECT_TYPE_UNKNOWN = 0,
	PSS_OBJECT_TYPE_PROCESS = 1,
	PSS_OBJECT_TYPE_THREAD = 2,
	PSS_OBJECT_TYPE_MUTANT = 3,
	PSS_OBJECT_TYPE_EVENT = 4,
	PSS_OBJECT_TYPE_SECTION = 5,
	PSS_OBJECT_TYPE_SEMAPHORE = 6,
}


[AllowDuplicates]
public enum PSS_CAPTURE_FLAGS : uint32
{
	PSS_CAPTURE_NONE = 0,
	PSS_CAPTURE_VA_CLONE = 1,
	PSS_CAPTURE_RESERVED_00000002 = 2,
	PSS_CAPTURE_HANDLES = 4,
	PSS_CAPTURE_HANDLE_NAME_INFORMATION = 8,
	PSS_CAPTURE_HANDLE_BASIC_INFORMATION = 16,
	PSS_CAPTURE_HANDLE_TYPE_SPECIFIC_INFORMATION = 32,
	PSS_CAPTURE_HANDLE_TRACE = 64,
	PSS_CAPTURE_THREADS = 128,
	PSS_CAPTURE_THREAD_CONTEXT = 256,
	PSS_CAPTURE_THREAD_CONTEXT_EXTENDED = 512,
	PSS_CAPTURE_RESERVED_00000400 = 1024,
	PSS_CAPTURE_VA_SPACE = 2048,
	PSS_CAPTURE_VA_SPACE_SECTION_INFORMATION = 4096,
	PSS_CAPTURE_IPT_TRACE = 8192,
	PSS_CAPTURE_RESERVED_00004000 = 16384,
	PSS_CREATE_BREAKAWAY_OPTIONAL = 67108864,
	PSS_CREATE_BREAKAWAY = 134217728,
	PSS_CREATE_FORCE_BREAKAWAY = 268435456,
	PSS_CREATE_USE_VM_ALLOCATIONS = 536870912,
	PSS_CREATE_MEASURE_PERFORMANCE = 1073741824,
	PSS_CREATE_RELEASE_SECTION = 2147483648,
}


[AllowDuplicates]
public enum PSS_QUERY_INFORMATION_CLASS : int32
{
	PSS_QUERY_PROCESS_INFORMATION = 0,
	PSS_QUERY_VA_CLONE_INFORMATION = 1,
	PSS_QUERY_AUXILIARY_PAGES_INFORMATION = 2,
	PSS_QUERY_VA_SPACE_INFORMATION = 3,
	PSS_QUERY_HANDLE_INFORMATION = 4,
	PSS_QUERY_THREAD_INFORMATION = 5,
	PSS_QUERY_HANDLE_TRACE_INFORMATION = 6,
	PSS_QUERY_PERFORMANCE_COUNTERS = 7,
}


[AllowDuplicates]
public enum PSS_WALK_INFORMATION_CLASS : int32
{
	PSS_WALK_AUXILIARY_PAGES = 0,
	PSS_WALK_VA_SPACE = 1,
	PSS_WALK_HANDLES = 2,
	PSS_WALK_THREADS = 3,
}


[AllowDuplicates]
public enum PSS_DUPLICATE_FLAGS : uint32
{
	PSS_DUPLICATE_NONE = 0,
	PSS_DUPLICATE_CLOSE_SOURCE = 1,
}


[AllowDuplicates]
public enum PSS_PROCESS_FLAGS : uint32
{
	PSS_PROCESS_FLAGS_NONE = 0,
	PSS_PROCESS_FLAGS_PROTECTED = 1,
	PSS_PROCESS_FLAGS_WOW64 = 2,
	PSS_PROCESS_FLAGS_RESERVED_03 = 4,
	PSS_PROCESS_FLAGS_RESERVED_04 = 8,
	PSS_PROCESS_FLAGS_FROZEN = 16,
}


[AllowDuplicates]
public enum PSS_THREAD_FLAGS : uint32
{
	PSS_THREAD_FLAGS_NONE = 0,
	PSS_THREAD_FLAGS_TERMINATED = 1,
}

#endregion


#region Structs
[CRepr]
public struct PSS_PROCESS_INFORMATION
{
	public uint32 ExitStatus;
	public void* PebBaseAddress;
	public uint AffinityMask;
	public int32 BasePriority;
	public uint32 ProcessId;
	public uint32 ParentProcessId;
	public PSS_PROCESS_FLAGS Flags;
	public FILETIME CreateTime;
	public FILETIME ExitTime;
	public FILETIME KernelTime;
	public FILETIME UserTime;
	public uint32 PriorityClass;
	public uint PeakVirtualSize;
	public uint VirtualSize;
	public uint32 PageFaultCount;
	public uint PeakWorkingSetSize;
	public uint WorkingSetSize;
	public uint QuotaPeakPagedPoolUsage;
	public uint QuotaPagedPoolUsage;
	public uint QuotaPeakNonPagedPoolUsage;
	public uint QuotaNonPagedPoolUsage;
	public uint PagefileUsage;
	public uint PeakPagefileUsage;
	public uint PrivateUsage;
	public uint32 ExecuteFlags;
	public char16[260] ImageFileName;
}

[CRepr]
public struct PSS_VA_CLONE_INFORMATION
{
	public HANDLE VaCloneHandle;
}

[CRepr]
public struct PSS_AUXILIARY_PAGES_INFORMATION
{
	public uint32 AuxPagesCaptured;
}

[CRepr]
public struct PSS_VA_SPACE_INFORMATION
{
	public uint32 RegionCount;
}

[CRepr]
public struct PSS_HANDLE_INFORMATION
{
	public uint32 HandlesCaptured;
}

[CRepr]
public struct PSS_THREAD_INFORMATION
{
	public uint32 ThreadsCaptured;
	public uint32 ContextLength;
}

[CRepr]
public struct PSS_HANDLE_TRACE_INFORMATION
{
	public HANDLE SectionHandle;
	public uint32 Size;
}

[CRepr]
public struct PSS_PERFORMANCE_COUNTERS
{
	public uint64 TotalCycleCount;
	public uint64 TotalWallClockPeriod;
	public uint64 VaCloneCycleCount;
	public uint64 VaCloneWallClockPeriod;
	public uint64 VaSpaceCycleCount;
	public uint64 VaSpaceWallClockPeriod;
	public uint64 AuxPagesCycleCount;
	public uint64 AuxPagesWallClockPeriod;
	public uint64 HandlesCycleCount;
	public uint64 HandlesWallClockPeriod;
	public uint64 ThreadsCycleCount;
	public uint64 ThreadsWallClockPeriod;
}

[CRepr]
public struct PSS_AUXILIARY_PAGE_ENTRY
{
	public void* Address;
	public MEMORY_BASIC_INFORMATION BasicInformation;
	public FILETIME CaptureTime;
	public void* PageContents;
	public uint32 PageSize;
}

[CRepr]
public struct PSS_VA_SPACE_ENTRY
{
	public void* BaseAddress;
	public void* AllocationBase;
	public uint32 AllocationProtect;
	public uint RegionSize;
	public uint32 State;
	public uint32 Protect;
	public uint32 Type;
	public uint32 TimeDateStamp;
	public uint32 SizeOfImage;
	public void* ImageBase;
	public uint32 CheckSum;
	public uint16 MappedFileNameLength;
	public PWSTR MappedFileName;
}

[CRepr]
public struct PSS_HANDLE_ENTRY
{
	[CRepr, Union]
	public struct _TypeSpecificInformation_e__Union
	{
		[CRepr]
		public struct _Section_e__Struct
		{
			public void* BaseAddress;
			public uint32 AllocationAttributes;
			public LARGE_INTEGER MaximumSize;
		}
		[CRepr]
		public struct _Mutant_e__Struct
		{
			public int32 CurrentCount;
			public BOOL Abandoned;
			public uint32 OwnerProcessId;
			public uint32 OwnerThreadId;
		}
		[CRepr]
		public struct _Process_e__Struct
		{
			public uint32 ExitStatus;
			public void* PebBaseAddress;
			public uint AffinityMask;
			public int32 BasePriority;
			public uint32 ProcessId;
			public uint32 ParentProcessId;
			public uint32 Flags;
		}
		[CRepr]
		public struct _Event_e__Struct
		{
			public BOOL ManualReset;
			public BOOL Signaled;
		}
		[CRepr]
		public struct _Thread_e__Struct
		{
			public uint32 ExitStatus;
			public void* TebBaseAddress;
			public uint32 ProcessId;
			public uint32 ThreadId;
			public uint AffinityMask;
			public int32 Priority;
			public int32 BasePriority;
			public void* Win32StartAddress;
		}
		[CRepr]
		public struct _Semaphore_e__Struct
		{
			public int32 CurrentCount;
			public int32 MaximumCount;
		}
		public _Process_e__Struct Process;
		public _Thread_e__Struct Thread;
		public _Mutant_e__Struct Mutant;
		public _Event_e__Struct Event;
		public _Section_e__Struct Section;
		public _Semaphore_e__Struct Semaphore;
	}
	public HANDLE Handle;
	public PSS_HANDLE_FLAGS Flags;
	public PSS_OBJECT_TYPE ObjectType;
	public FILETIME CaptureTime;
	public uint32 Attributes;
	public uint32 GrantedAccess;
	public uint32 HandleCount;
	public uint32 PointerCount;
	public uint32 PagedPoolCharge;
	public uint32 NonPagedPoolCharge;
	public FILETIME CreationTime;
	public uint16 TypeNameLength;
	public PWSTR TypeName;
	public uint16 ObjectNameLength;
	public PWSTR ObjectName;
	public _TypeSpecificInformation_e__Union TypeSpecificInformation;
}

[CRepr]
public struct PSS_THREAD_ENTRY
{
	public uint32 ExitStatus;
	public void* TebBaseAddress;
	public uint32 ProcessId;
	public uint32 ThreadId;
	public uint AffinityMask;
	public int32 Priority;
	public int32 BasePriority;
	public void* LastSyscallFirstArgument;
	public uint16 LastSyscallNumber;
	public FILETIME CreateTime;
	public FILETIME ExitTime;
	public FILETIME KernelTime;
	public FILETIME UserTime;
	public void* Win32StartAddress;
	public FILETIME CaptureTime;
	public PSS_THREAD_FLAGS Flags;
	public uint16 SuspendCount;
	public uint16 SizeOfContextRecord;
	public CONTEXT* ContextRecord;
}

[CRepr]
public struct PSS_ALLOCATOR
{
	public void* Context;
	public int AllocRoutine;
	public int FreeRoutine;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssCaptureSnapshot(HANDLE ProcessHandle, PSS_CAPTURE_FLAGS CaptureFlags, uint32 ThreadContextFlags, HPSS* SnapshotHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssFreeSnapshot(HANDLE ProcessHandle, HPSS SnapshotHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssQuerySnapshot(HPSS SnapshotHandle, PSS_QUERY_INFORMATION_CLASS InformationClass, void* Buffer, uint32 BufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssWalkSnapshot(HPSS SnapshotHandle, PSS_WALK_INFORMATION_CLASS InformationClass, HPSSWALK WalkMarkerHandle, void* Buffer, uint32 BufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssDuplicateSnapshot(HANDLE SourceProcessHandle, HPSS SnapshotHandle, HANDLE TargetProcessHandle, HPSS* TargetSnapshotHandle, PSS_DUPLICATE_FLAGS Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssWalkMarkerCreate(PSS_ALLOCATOR* Allocator, HPSSWALK* WalkMarkerHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssWalkMarkerFree(HPSSWALK WalkMarkerHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssWalkMarkerGetPosition(HPSSWALK WalkMarkerHandle, uint* Position);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssWalkMarkerSetPosition(HPSSWALK WalkMarkerHandle, uint Position);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PssWalkMarkerSeekToBeginning(HPSSWALK WalkMarkerHandle);

}
#endregion
