using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.System.Memory;

#region Constants
public static
{
	public const uint32 FILE_CACHE_MAX_HARD_ENABLE = 1;
	public const uint32 FILE_CACHE_MAX_HARD_DISABLE = 2;
	public const uint32 FILE_CACHE_MIN_HARD_ENABLE = 4;
	public const uint32 FILE_CACHE_MIN_HARD_DISABLE = 8;
	public const uint32 MEHC_PATROL_SCRUBBER_PRESENT = 1;
}
#endregion

#region TypeDefs
typealias HeapHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum FILE_MAP : uint32
{
	FILE_MAP_WRITE = 2,
	FILE_MAP_READ = 4,
	FILE_MAP_ALL_ACCESS = 983071,
	FILE_MAP_EXECUTE = 32,
	FILE_MAP_COPY = 1,
	FILE_MAP_RESERVE = 2147483648,
	FILE_MAP_TARGETS_INVALID = 1073741824,
	FILE_MAP_LARGE_PAGES = 536870912,
}


[AllowDuplicates]
public enum HEAP_FLAGS : uint32
{
	HEAP_NONE = 0,
	HEAP_NO_SERIALIZE = 1,
	HEAP_GROWABLE = 2,
	HEAP_GENERATE_EXCEPTIONS = 4,
	HEAP_ZERO_MEMORY = 8,
	HEAP_REALLOC_IN_PLACE_ONLY = 16,
	HEAP_TAIL_CHECKING_ENABLED = 32,
	HEAP_FREE_CHECKING_ENABLED = 64,
	HEAP_DISABLE_COALESCE_ON_FREE = 128,
	HEAP_CREATE_ALIGN_16 = 65536,
	HEAP_CREATE_ENABLE_TRACING = 131072,
	HEAP_CREATE_ENABLE_EXECUTE = 262144,
	HEAP_MAXIMUM_TAG = 4095,
	HEAP_PSEUDO_TAG_FLAG = 32768,
	HEAP_TAG_SHIFT = 18,
	HEAP_CREATE_SEGMENT_HEAP = 256,
	HEAP_CREATE_HARDENED = 512,
}


[AllowDuplicates]
public enum PAGE_PROTECTION_FLAGS : uint32
{
	PAGE_NOACCESS = 1,
	PAGE_READONLY = 2,
	PAGE_READWRITE = 4,
	PAGE_WRITECOPY = 8,
	PAGE_EXECUTE = 16,
	PAGE_EXECUTE_READ = 32,
	PAGE_EXECUTE_READWRITE = 64,
	PAGE_EXECUTE_WRITECOPY = 128,
	PAGE_GUARD = 256,
	PAGE_NOCACHE = 512,
	PAGE_WRITECOMBINE = 1024,
	PAGE_GRAPHICS_NOACCESS = 2048,
	PAGE_GRAPHICS_READONLY = 4096,
	PAGE_GRAPHICS_READWRITE = 8192,
	PAGE_GRAPHICS_EXECUTE = 16384,
	PAGE_GRAPHICS_EXECUTE_READ = 32768,
	PAGE_GRAPHICS_EXECUTE_READWRITE = 65536,
	PAGE_GRAPHICS_COHERENT = 131072,
	PAGE_GRAPHICS_NOCACHE = 262144,
	PAGE_ENCLAVE_THREAD_CONTROL = 2147483648,
	PAGE_REVERT_TO_FILE_MAP = 2147483648,
	PAGE_TARGETS_NO_UPDATE = 1073741824,
	PAGE_TARGETS_INVALID = 1073741824,
	PAGE_ENCLAVE_UNVALIDATED = 536870912,
	PAGE_ENCLAVE_MASK = 268435456,
	PAGE_ENCLAVE_DECOMMIT = 268435456,
	PAGE_ENCLAVE_SS_FIRST = 268435457,
	PAGE_ENCLAVE_SS_REST = 268435458,
	SEC_PARTITION_OWNER_HANDLE = 262144,
	SEC_64K_PAGES = 524288,
	SEC_FILE = 8388608,
	SEC_IMAGE = 16777216,
	SEC_PROTECTED_IMAGE = 33554432,
	SEC_RESERVE = 67108864,
	SEC_COMMIT = 134217728,
	SEC_NOCACHE = 268435456,
	SEC_WRITECOMBINE = 1073741824,
	SEC_LARGE_PAGES = 2147483648,
	SEC_IMAGE_NO_EXECUTE = 285212672,
}


[AllowDuplicates]
public enum UNMAP_VIEW_OF_FILE_FLAGS : uint32
{
	MEM_UNMAP_NONE = 0,
	MEM_UNMAP_WITH_TRANSIENT_BOOST = 1,
	MEM_PRESERVE_PLACEHOLDER = 2,
}


[AllowDuplicates]
public enum VIRTUAL_FREE_TYPE : uint32
{
	MEM_DECOMMIT = 16384,
	MEM_RELEASE = 32768,
}


[AllowDuplicates]
public enum VIRTUAL_ALLOCATION_TYPE : uint32
{
	MEM_COMMIT = 4096,
	MEM_RESERVE = 8192,
	MEM_RESET = 524288,
	MEM_RESET_UNDO = 16777216,
	MEM_REPLACE_PLACEHOLDER = 16384,
	MEM_LARGE_PAGES = 536870912,
	MEM_RESERVE_PLACEHOLDER = 262144,
	MEM_FREE = 65536,
}


[AllowDuplicates]
public enum LOCAL_ALLOC_FLAGS : uint32
{
	LHND = 66,
	LMEM_FIXED = 0,
	LMEM_MOVEABLE = 2,
	LMEM_ZEROINIT = 64,
	LPTR = 64,
	NONZEROLHND = 2,
	NONZEROLPTR = 0,
}


[AllowDuplicates]
public enum GLOBAL_ALLOC_FLAGS : uint32
{
	GHND = 66,
	GMEM_FIXED = 0,
	GMEM_MOVEABLE = 2,
	GMEM_ZEROINIT = 64,
	GPTR = 64,
}


[AllowDuplicates]
public enum PAGE_TYPE : uint32
{
	MEM_PRIVATE = 131072,
	MEM_MAPPED = 262144,
	MEM_IMAGE = 16777216,
}


[AllowDuplicates]
public enum MEMORY_RESOURCE_NOTIFICATION_TYPE : int32
{
	LowMemoryResourceNotification = 0,
	HighMemoryResourceNotification = 1,
}


[AllowDuplicates]
public enum OFFER_PRIORITY : int32
{
	VmOfferPriorityVeryLow = 1,
	VmOfferPriorityLow = 2,
	VmOfferPriorityBelowNormal = 3,
	VmOfferPriorityNormal = 4,
}


[AllowDuplicates]
public enum WIN32_MEMORY_INFORMATION_CLASS : int32
{
	MemoryRegionInfo = 0,
}


[AllowDuplicates]
public enum WIN32_MEMORY_PARTITION_INFORMATION_CLASS : int32
{
	MemoryPartitionInfo = 0,
	MemoryPartitionDedicatedMemoryInfo = 1,
}


[AllowDuplicates]
public enum MEM_EXTENDED_PARAMETER_TYPE : int32
{
	MemExtendedParameterInvalidType = 0,
	MemExtendedParameterAddressRequirements = 1,
	MemExtendedParameterNumaNode = 2,
	MemExtendedParameterPartitionHandle = 3,
	MemExtendedParameterUserPhysicalHandle = 4,
	MemExtendedParameterAttributeFlags = 5,
	MemExtendedParameterImageMachine = 6,
	MemExtendedParameterMax = 7,
}


[AllowDuplicates]
public enum HEAP_INFORMATION_CLASS : int32
{
	HeapCompatibilityInformation = 0,
	HeapEnableTerminationOnCorruption = 1,
	HeapOptimizeResources = 3,
	HeapTag = 7,
}

#endregion

#region Function Pointers
public function void PBAD_MEMORY_CALLBACK_ROUTINE();

public function BOOLEAN PSECURE_MEMORY_CACHE_CALLBACK(void* Addr, uint Range);

#endregion

#region Structs
[CRepr]
public struct PROCESS_HEAP_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Region_e__Struct
		{
			public uint32 dwCommittedSize;
			public uint32 dwUnCommittedSize;
			public void* lpFirstBlock;
			public void* lpLastBlock;
		}
		[CRepr]
		public struct _Block_e__Struct
		{
			public HANDLE hMem;
			public uint32[3] dwReserved;
		}
		public _Block_e__Struct Block;
		public _Region_e__Struct Region;
	}
	public void* lpData;
	public uint32 cbData;
	public uint8 cbOverhead;
	public uint8 iRegionIndex;
	public uint16 wFlags;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct HEAP_SUMMARY
{
	public uint32 cb;
	public uint cbAllocated;
	public uint cbCommitted;
	public uint cbReserved;
	public uint cbMaxReserve;
}

[CRepr]
public struct WIN32_MEMORY_RANGE_ENTRY
{
	public void* VirtualAddress;
	public uint NumberOfBytes;
}

[CRepr]
public struct WIN32_MEMORY_REGION_INFORMATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public void* AllocationBase;
	public uint32 AllocationProtect;
	public using _Anonymous_e__Union Anonymous;
	public uint RegionSize;
	public uint CommitSize;
}

[CRepr]
public struct WIN32_MEMORY_PARTITION_INFORMATION
{
	public uint32 Flags;
	public uint32 NumaNode;
	public uint32 Channel;
	public uint32 NumberOfNumaNodes;
	public uint64 ResidentAvailablePages;
	public uint64 CommittedPages;
	public uint64 CommitLimit;
	public uint64 PeakCommitment;
	public uint64 TotalNumberOfPages;
	public uint64 AvailablePages;
	public uint64 ZeroPages;
	public uint64 FreePages;
	public uint64 StandbyPages;
	public uint64[16] Reserved;
	public uint64 MaximumCommitLimit;
	public uint64 Reserved2;
	public uint32 PartitionId;
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct MEMORY_BASIC_INFORMATION
{
	public void* BaseAddress;
	public void* AllocationBase;
	public PAGE_PROTECTION_FLAGS AllocationProtect;
	public uint16 PartitionId;
	public uint RegionSize;
	public VIRTUAL_ALLOCATION_TYPE State;
	public PAGE_PROTECTION_FLAGS Protect;
	public PAGE_TYPE Type;
}
#endif

#if BF_32_BIT
[CRepr]
public struct MEMORY_BASIC_INFORMATION
{
	public void* BaseAddress;
	public void* AllocationBase;
	public PAGE_PROTECTION_FLAGS AllocationProtect;
	public uint RegionSize;
	public VIRTUAL_ALLOCATION_TYPE State;
	public PAGE_PROTECTION_FLAGS Protect;
	public PAGE_TYPE Type;
}
#endif

[CRepr]
public struct MEMORY_BASIC_INFORMATION32
{
	public uint32 BaseAddress;
	public uint32 AllocationBase;
	public PAGE_PROTECTION_FLAGS AllocationProtect;
	public uint32 RegionSize;
	public VIRTUAL_ALLOCATION_TYPE State;
	public PAGE_PROTECTION_FLAGS Protect;
	public PAGE_TYPE Type;
}

[CRepr]
public struct MEMORY_BASIC_INFORMATION64
{
	public uint64 BaseAddress;
	public uint64 AllocationBase;
	public PAGE_PROTECTION_FLAGS AllocationProtect;
	public uint32 __alignment1;
	public uint64 RegionSize;
	public VIRTUAL_ALLOCATION_TYPE State;
	public PAGE_PROTECTION_FLAGS Protect;
	public PAGE_TYPE Type;
	public uint32 __alignment2;
}

[CRepr]
public struct CFG_CALL_TARGET_INFO
{
	public uint Offset;
	public uint Flags;
}

[CRepr]
public struct MEM_ADDRESS_REQUIREMENTS
{
	public void* LowestStartingAddress;
	public void* HighestEndingAddress;
	public uint Alignment;
}

[CRepr]
public struct MEM_EXTENDED_PARAMETER
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint64 ULong64;
		public void* Pointer;
		public uint Size;
		public HANDLE Handle;
		public uint32 ULong;
	}
	[CRepr]
	public struct _Anonymous1_e__Struct
	{
		public uint64 _bitfield;
	}
	public using _Anonymous1_e__Struct Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HeapHandle HeapCreate(HEAP_FLAGS flOptions, uint dwInitialSize, uint dwMaximumSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapDestroy(HeapHandle hHeap);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* HeapAlloc(HeapHandle hHeap, HEAP_FLAGS dwFlags, uint dwBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* HeapReAlloc(HeapHandle hHeap, HEAP_FLAGS dwFlags, void* lpMem, uint dwBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapFree(HeapHandle hHeap, HEAP_FLAGS dwFlags, void* lpMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint HeapSize(HeapHandle hHeap, HEAP_FLAGS dwFlags, void* lpMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HeapHandle GetProcessHeap();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint HeapCompact(HeapHandle hHeap, HEAP_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapSetInformation(HeapHandle HeapHandle, HEAP_INFORMATION_CLASS HeapInformationClass, void* HeapInformation, uint HeapInformationLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapValidate(HeapHandle hHeap, HEAP_FLAGS dwFlags, void* lpMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapSummary(HANDLE hHeap, uint32 dwFlags, HEAP_SUMMARY* lpSummary);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProcessHeaps(uint32 NumberOfHeaps, HeapHandle* ProcessHeaps);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapLock(HeapHandle hHeap);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapUnlock(HeapHandle hHeap);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapWalk(HeapHandle hHeap, PROCESS_HEAP_ENTRY* lpEntry);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HeapQueryInformation(HeapHandle HeapHandle, HEAP_INFORMATION_CLASS HeapInformationClass, void* HeapInformation, uint HeapInformationLength, uint* ReturnLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* VirtualAlloc(void* lpAddress, uint dwSize, VIRTUAL_ALLOCATION_TYPE flAllocationType, PAGE_PROTECTION_FLAGS flProtect);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualProtect(void* lpAddress, uint dwSize, PAGE_PROTECTION_FLAGS flNewProtect, PAGE_PROTECTION_FLAGS* lpflOldProtect);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualFree(void* lpAddress, uint dwSize, VIRTUAL_FREE_TYPE dwFreeType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint VirtualQuery(void* lpAddress, MEMORY_BASIC_INFORMATION* lpBuffer, uint dwLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* VirtualAllocEx(HANDLE hProcess, void* lpAddress, uint dwSize, VIRTUAL_ALLOCATION_TYPE flAllocationType, PAGE_PROTECTION_FLAGS flProtect);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualProtectEx(HANDLE hProcess, void* lpAddress, uint dwSize, PAGE_PROTECTION_FLAGS flNewProtect, PAGE_PROTECTION_FLAGS* lpflOldProtect);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint VirtualQueryEx(HANDLE hProcess, void* lpAddress, MEMORY_BASIC_INFORMATION* lpBuffer, uint dwLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileMappingW(HANDLE hFile, SECURITY_ATTRIBUTES* lpFileMappingAttributes, PAGE_PROTECTION_FLAGS flProtect, uint32 dwMaximumSizeHigh, uint32 dwMaximumSizeLow, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenFileMappingW(uint32 dwDesiredAccess, BOOL bInheritHandle, PWSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFile(HANDLE hFileMappingObject, FILE_MAP dwDesiredAccess, uint32 dwFileOffsetHigh, uint32 dwFileOffsetLow, uint dwNumberOfBytesToMap);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFileEx(HANDLE hFileMappingObject, FILE_MAP dwDesiredAccess, uint32 dwFileOffsetHigh, uint32 dwFileOffsetLow, uint dwNumberOfBytesToMap, void* lpBaseAddress);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualFreeEx(HANDLE hProcess, void* lpAddress, uint dwSize, VIRTUAL_FREE_TYPE dwFreeType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlushViewOfFile(void* lpBaseAddress, uint dwNumberOfBytesToFlush);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnmapViewOfFile(void* lpBaseAddress);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint GetLargePageMinimum();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessWorkingSetSizeEx(HANDLE hProcess, uint* lpMinimumWorkingSetSize, uint* lpMaximumWorkingSetSize, uint32* Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessWorkingSetSizeEx(HANDLE hProcess, uint dwMinimumWorkingSetSize, uint dwMaximumWorkingSetSize, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualLock(void* lpAddress, uint dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualUnlock(void* lpAddress, uint dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetWriteWatch(uint32 dwFlags, void* lpBaseAddress, uint dwRegionSize, void** lpAddresses, uint* lpdwCount, uint32* lpdwGranularity);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResetWriteWatch(void* lpBaseAddress, uint dwRegionSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateMemoryResourceNotification(MEMORY_RESOURCE_NOTIFICATION_TYPE NotificationType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryMemoryResourceNotification(HANDLE ResourceNotificationHandle, BOOL* ResourceState);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemFileCacheSize(uint* lpMinimumFileCacheSize, uint* lpMaximumFileCacheSize, uint32* lpFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSystemFileCacheSize(uint MinimumFileCacheSize, uint MaximumFileCacheSize, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileMappingNumaW(HANDLE hFile, SECURITY_ATTRIBUTES* lpFileMappingAttributes, PAGE_PROTECTION_FLAGS flProtect, uint32 dwMaximumSizeHigh, uint32 dwMaximumSizeLow, PWSTR lpName, uint32 nndPreferred);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrefetchVirtualMemory(HANDLE hProcess, uint NumberOfEntries, WIN32_MEMORY_RANGE_ENTRY* VirtualAddresses, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileMappingFromApp(HANDLE hFile, SECURITY_ATTRIBUTES* SecurityAttributes, PAGE_PROTECTION_FLAGS PageProtection, uint64 MaximumSize, PWSTR Name);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFileFromApp(HANDLE hFileMappingObject, FILE_MAP DesiredAccess, uint64 FileOffset, uint NumberOfBytesToMap);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnmapViewOfFileEx(void* BaseAddress, UNMAP_VIEW_OF_FILE_FLAGS UnmapFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocateUserPhysicalPages(HANDLE hProcess, uint* NumberOfPages, uint* PageArray);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeUserPhysicalPages(HANDLE hProcess, uint* NumberOfPages, uint* PageArray);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MapUserPhysicalPages(void* VirtualAddress, uint NumberOfPages, uint* PageArray);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocateUserPhysicalPagesNuma(HANDLE hProcess, uint* NumberOfPages, uint* PageArray, uint32 nndPreferred);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* VirtualAllocExNuma(HANDLE hProcess, void* lpAddress, uint dwSize, VIRTUAL_ALLOCATION_TYPE flAllocationType, uint32 flProtect, uint32 nndPreferred);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetMemoryErrorHandlingCapabilities(uint32* Capabilities);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* RegisterBadMemoryNotification(PBAD_MEMORY_CALLBACK_ROUTINE Callback);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterBadMemoryNotification(void* RegistrationHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfferVirtualMemory(void* VirtualAddress, uint Size, OFFER_PRIORITY Priority);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReclaimVirtualMemory(void* VirtualAddress, uint Size);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DiscardVirtualMemory(void* VirtualAddress, uint Size);

	[Import("api-ms-win-core-memory-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessValidCallTargets(HANDLE hProcess, void* VirtualAddress, uint RegionSize, uint32 NumberOfOffsets, CFG_CALL_TARGET_INFO* OffsetInformation);

	[Import("api-ms-win-core-memory-l1-1-7.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessValidCallTargetsForMappedView(HANDLE Process, void* VirtualAddress, uint RegionSize, uint32 NumberOfOffsets, CFG_CALL_TARGET_INFO* OffsetInformation, HANDLE Section, uint64 ExpectedFileOffset);

	[Import("api-ms-win-core-memory-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* VirtualAllocFromApp(void* BaseAddress, uint Size, VIRTUAL_ALLOCATION_TYPE AllocationType, uint32 Protection);

	[Import("api-ms-win-core-memory-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualProtectFromApp(void* Address, uint Size, uint32 NewProtection, uint32* OldProtection);

	[Import("api-ms-win-core-memory-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenFileMappingFromApp(uint32 DesiredAccess, BOOL InheritHandle, PWSTR Name);

	[Import("api-ms-win-core-memory-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryVirtualMemoryInformation(HANDLE Process, void* VirtualAddress, WIN32_MEMORY_INFORMATION_CLASS MemoryInformationClass, void* MemoryInformation, uint MemoryInformationSize, uint* ReturnSize);

	[Import("api-ms-win-core-memory-l1-1-5.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFileNuma2(HANDLE FileMappingHandle, HANDLE ProcessHandle, uint64 Offset, void* BaseAddress, uint ViewSize, uint32 AllocationType, uint32 PageProtection, uint32 PreferredNode);

	[Import("api-ms-win-core-memory-l1-1-5.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnmapViewOfFile2(HANDLE Process, void* BaseAddress, UNMAP_VIEW_OF_FILE_FLAGS UnmapFlags);

	[Import("api-ms-win-core-memory-l1-1-5.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VirtualUnlockEx(HANDLE Process, void* Address, uint Size);

	[Import("api-ms-win-core-memory-l1-1-6.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* VirtualAlloc2(HANDLE Process, void* BaseAddress, uint Size, VIRTUAL_ALLOCATION_TYPE AllocationType, uint32 PageProtection, MEM_EXTENDED_PARAMETER* ExtendedParameters, uint32 ParameterCount);

	[Import("api-ms-win-core-memory-l1-1-6.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFile3(HANDLE FileMapping, HANDLE Process, void* BaseAddress, uint64 Offset, uint ViewSize, VIRTUAL_ALLOCATION_TYPE AllocationType, uint32 PageProtection, MEM_EXTENDED_PARAMETER* ExtendedParameters, uint32 ParameterCount);

	[Import("api-ms-win-core-memory-l1-1-6.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* VirtualAlloc2FromApp(HANDLE Process, void* BaseAddress, uint Size, VIRTUAL_ALLOCATION_TYPE AllocationType, uint32 PageProtection, MEM_EXTENDED_PARAMETER* ExtendedParameters, uint32 ParameterCount);

	[Import("api-ms-win-core-memory-l1-1-6.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFile3FromApp(HANDLE FileMapping, HANDLE Process, void* BaseAddress, uint64 Offset, uint ViewSize, VIRTUAL_ALLOCATION_TYPE AllocationType, uint32 PageProtection, MEM_EXTENDED_PARAMETER* ExtendedParameters, uint32 ParameterCount);

	[Import("api-ms-win-core-memory-l1-1-7.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileMapping2(HANDLE File, SECURITY_ATTRIBUTES* SecurityAttributes, uint32 DesiredAccess, PAGE_PROTECTION_FLAGS PageProtection, uint32 AllocationAttributes, uint64 MaximumSize, PWSTR Name, MEM_EXTENDED_PARAMETER* ExtendedParameters, uint32 ParameterCount);

	[Import("api-ms-win-core-memory-l1-1-8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocateUserPhysicalPages2(HANDLE ObjectHandle, uint* NumberOfPages, uint* PageArray, MEM_EXTENDED_PARAMETER* ExtendedParameters, uint32 ExtendedParameterCount);

	[Import("api-ms-win-core-memory-l1-1-8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenDedicatedMemoryPartition(HANDLE Partition, uint64 DedicatedMemoryTypeId, uint32 DesiredAccess, BOOL InheritHandle);

	[Import("api-ms-win-core-memory-l1-1-8.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryPartitionInformation(HANDLE Partition, WIN32_MEMORY_PARTITION_INFORMATION_CLASS PartitionInformationClass, void* PartitionInformation, uint32 PartitionInformationLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint RtlCompareMemory(void* Source1, void* Source2, uint Length);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlCrc32(void* Buffer, uint Size, uint32 InitialCrc);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 RtlCrc64(void* Buffer, uint Size, uint64 InitialCrc);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN RtlIsZeroMemory(void* Buffer, uint Length);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int GlobalAlloc(GLOBAL_ALLOC_FLAGS uFlags, uint dwBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int GlobalReAlloc(int hMem, uint dwBytes, uint32 uFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint GlobalSize(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GlobalUnlock(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* GlobalLock(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GlobalFlags(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int GlobalHandle(void* pMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int GlobalFree(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int LocalAlloc(LOCAL_ALLOC_FLAGS uFlags, uint uBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int LocalReAlloc(int hMem, uint uBytes, uint32 uFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* LocalLock(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int LocalHandle(void* pMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LocalUnlock(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint LocalSize(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LocalFlags(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int LocalFree(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileMappingA(HANDLE hFile, SECURITY_ATTRIBUTES* lpFileMappingAttributes, PAGE_PROTECTION_FLAGS flProtect, uint32 dwMaximumSizeHigh, uint32 dwMaximumSizeLow, PSTR lpName);
	public static HANDLE CreateFileMapping(HANDLE hFile, SECURITY_ATTRIBUTES* lpFileMappingAttributes, PAGE_PROTECTION_FLAGS flProtect, uint32 dwMaximumSizeHigh, uint32 dwMaximumSizeLow, PSTR lpName) => CreateFileMappingA(hFile, lpFileMappingAttributes, flProtect, dwMaximumSizeHigh, dwMaximumSizeLow, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileMappingNumaA(HANDLE hFile, SECURITY_ATTRIBUTES* lpFileMappingAttributes, PAGE_PROTECTION_FLAGS flProtect, uint32 dwMaximumSizeHigh, uint32 dwMaximumSizeLow, PSTR lpName, uint32 nndPreferred);
	public static HANDLE CreateFileMappingNuma(HANDLE hFile, SECURITY_ATTRIBUTES* lpFileMappingAttributes, PAGE_PROTECTION_FLAGS flProtect, uint32 dwMaximumSizeHigh, uint32 dwMaximumSizeLow, PSTR lpName, uint32 nndPreferred) => CreateFileMappingNumaA(hFile, lpFileMappingAttributes, flProtect, dwMaximumSizeHigh, dwMaximumSizeLow, lpName, nndPreferred);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenFileMappingA(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpName);
	public static HANDLE OpenFileMapping(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpName) => OpenFileMappingA(dwDesiredAccess, bInheritHandle, lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* MapViewOfFileExNuma(HANDLE hFileMappingObject, FILE_MAP dwDesiredAccess, uint32 dwFileOffsetHigh, uint32 dwFileOffsetLow, uint dwNumberOfBytesToMap, void* lpBaseAddress, uint32 nndPreferred);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadReadPtr(void* lp, uint ucb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadWritePtr(void* lp, uint ucb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadCodePtr(FARPROC lpfn);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadStringPtrA(PSTR lpsz, uint ucchMax);
	public static BOOL IsBadStringPtr(PSTR lpsz, uint ucchMax) => IsBadStringPtrA(lpsz, ucchMax);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadStringPtrW(PWSTR lpsz, uint ucchMax);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MapUserPhysicalPagesScatter(void** VirtualAddresses, uint NumberOfPages, uint* PageArray);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddSecureMemoryCacheCallback(PSECURE_MEMORY_CACHE_CALLBACK pfnCallBack);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveSecureMemoryCacheCallback(PSECURE_MEMORY_CACHE_CALLBACK pfnCallBack);

}
#endregion
