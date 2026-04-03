using Win32.Foundation;
using System;

namespace Win32.System.ApplicationVerifier;

#region Constants
public static
{
	public const uint32 AVRF_MAX_TRACES = 32;
}
#endregion

#region Enums

[AllowDuplicates]
public enum VERIFIER_ENUM_RESOURCE_FLAGS : uint32
{
	AVRF_ENUM_RESOURCES_FLAGS_DONT_RESOLVE_TRACES = 2,
	AVRF_ENUM_RESOURCES_FLAGS_SUSPEND = 1,
}


[AllowDuplicates]
public enum eUserAllocationState : int32
{
	AllocationStateUnknown = 0,
	AllocationStateBusy = 1,
	AllocationStateFree = 2,
}


[AllowDuplicates]
public enum eHeapAllocationState : int32
{
	HeapFullPageHeap = 1073741824,
	HeapMetadata = -2147483648,
	HeapStateMask = -65536,
}


[AllowDuplicates]
public enum eHeapEnumerationLevel : int32
{
	HeapEnumerationEverything = 0,
	HeapEnumerationStop = -1,
}


[AllowDuplicates]
public enum eHANDLE_TRACE_OPERATIONS : int32
{
	OperationDbUnused = 0,
	OperationDbOPEN = 1,
	OperationDbCLOSE = 2,
	OperationDbBADREF = 3,
}


[AllowDuplicates]
public enum eAvrfResourceTypes : int32
{
	AvrfResourceHeapAllocation = 0,
	AvrfResourceHandleTrace = 1,
	AvrfResourceMax = 2,
}

#endregion

#region Function Pointers
public function uint32 AVRF_RESOURCE_ENUMERATE_CALLBACK(void* ResourceDescription, void* EnumerationContext, uint32* EnumerationLevel);

public function uint32 AVRF_HEAPALLOCATION_ENUMERATE_CALLBACK(AVRF_HEAP_ALLOCATION* HeapAllocation, void* EnumerationContext, uint32* EnumerationLevel);

public function uint32 AVRF_HANDLEOPERATION_ENUMERATE_CALLBACK(AVRF_HANDLE_OPERATION* HandleOperation, void* EnumerationContext, uint32* EnumerationLevel);

#endregion

#region Structs
[CRepr]
public struct AVRF_BACKTRACE_INFORMATION
{
	public uint32 Depth;
	public uint32 Index;
	public uint64[32] ReturnAddresses;
}

[CRepr]
public struct AVRF_HEAP_ALLOCATION
{
	public uint64 HeapHandle;
	public uint64 UserAllocation;
	public uint64 UserAllocationSize;
	public uint64 Allocation;
	public uint64 AllocationSize;
	public uint32 UserAllocationState;
	public uint32 HeapState;
	public uint64 HeapContext;
	public AVRF_BACKTRACE_INFORMATION* BackTraceInformation;
}

[CRepr]
public struct AVRF_HANDLE_OPERATION
{
	public uint64 Handle;
	public uint32 ProcessId;
	public uint32 ThreadId;
	public uint32 OperationType;
	public uint32 Spare0;
	public AVRF_BACKTRACE_INFORMATION BackTraceInformation;
}

#endregion

#region Functions
public static
{
	[Import("verifier.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 VerifierEnumerateResource(HANDLE Process, VERIFIER_ENUM_RESOURCE_FLAGS Flags, eAvrfResourceTypes ResourceType, AVRF_RESOURCE_ENUMERATE_CALLBACK ResourceCallback, void* EnumerationContext);

}
#endregion
