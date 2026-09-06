using Win32.Foundation;
using System;

namespace Win32.System.ProcessStatus;

#region Constants
public static
{
	public const uint32 PSAPI_VERSION = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum ENUM_PROCESS_MODULES_EX_FLAGS : uint32
{
	LIST_MODULES_ALL = 3,
	LIST_MODULES_DEFAULT = 0,
	LIST_MODULES_32BIT = 1,
	LIST_MODULES_64BIT = 2,
}

#endregion

#region Function Pointers
public function BOOL PENUM_PAGE_FILE_CALLBACKW(void* pContext, ENUM_PAGE_FILE_INFORMATION* pPageFileInfo, PWSTR lpFilename);

public function BOOL PENUM_PAGE_FILE_CALLBACKA(void* pContext, ENUM_PAGE_FILE_INFORMATION* pPageFileInfo, PSTR lpFilename);

#endregion

#region Structs
[CRepr]
public struct MODULEINFO
{
	public void* lpBaseOfDll;
	public uint32 SizeOfImage;
	public void* EntryPoint;
}

[CRepr]
public struct PSAPI_WS_WATCH_INFORMATION
{
	public void* FaultingPc;
	public void* FaultingVa;
}

[CRepr]
public struct PSAPI_WS_WATCH_INFORMATION_EX
{
	public PSAPI_WS_WATCH_INFORMATION BasicInfo;
	public uint FaultingThreadId;
	public uint Flags;
}

[CRepr, Union]
public struct PSAPI_WORKING_SET_BLOCK
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint _bitfield;
	}
	public uint Flags;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct PSAPI_WORKING_SET_INFORMATION
{
	public uint NumberOfEntries;
	public PSAPI_WORKING_SET_BLOCK* WorkingSetInfo mut => &WorkingSetInfo_impl;
	private PSAPI_WORKING_SET_BLOCK[ANYSIZE_ARRAY] WorkingSetInfo_impl;
}

[CRepr, Union]
public struct PSAPI_WORKING_SET_EX_BLOCK
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Invalid_e__Struct
		{
			public uint _bitfield;
		}
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public _Invalid_e__Struct Invalid;
	}
	public uint Flags;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PSAPI_WORKING_SET_EX_INFORMATION
{
	public void* VirtualAddress;
	public PSAPI_WORKING_SET_EX_BLOCK VirtualAttributes;
}

[CRepr]
public struct PROCESS_MEMORY_COUNTERS
{
	public uint32 cb;
	public uint32 PageFaultCount;
	public uint PeakWorkingSetSize;
	public uint WorkingSetSize;
	public uint QuotaPeakPagedPoolUsage;
	public uint QuotaPagedPoolUsage;
	public uint QuotaPeakNonPagedPoolUsage;
	public uint QuotaNonPagedPoolUsage;
	public uint PagefileUsage;
	public uint PeakPagefileUsage;
}

[CRepr]
public struct PROCESS_MEMORY_COUNTERS_EX
{
	public uint32 cb;
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
}

[CRepr]
public struct PERFORMANCE_INFORMATION
{
	public uint32 cb;
	public uint CommitTotal;
	public uint CommitLimit;
	public uint CommitPeak;
	public uint PhysicalTotal;
	public uint PhysicalAvailable;
	public uint SystemCache;
	public uint KernelTotal;
	public uint KernelPaged;
	public uint KernelNonpaged;
	public uint PageSize;
	public uint32 HandleCount;
	public uint32 ProcessCount;
	public uint32 ThreadCount;
}

[CRepr]
public struct ENUM_PAGE_FILE_INFORMATION
{
	public uint32 cb;
	public uint32 Reserved;
	public uint TotalSize;
	public uint TotalInUse;
	public uint PeakUsage;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EnumProcesses(uint32* lpidProcess, uint32 cb, uint32* lpcbNeeded);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EnumProcessModules(HANDLE hProcess, HINSTANCE* lphModule, uint32 cb, uint32* lpcbNeeded);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EnumProcessModulesEx(HANDLE hProcess, HINSTANCE* lphModule, uint32 cb, uint32* lpcbNeeded, ENUM_PROCESS_MODULES_EX_FLAGS dwFilterFlag);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetModuleBaseNameA(HANDLE hProcess, HINSTANCE hModule, uint8* lpBaseName, uint32 nSize);
	public static uint32 K32GetModuleBaseName(HANDLE hProcess, HINSTANCE hModule, uint8* lpBaseName, uint32 nSize) => K32GetModuleBaseNameA(hProcess, hModule, lpBaseName, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetModuleBaseNameW(HANDLE hProcess, HINSTANCE hModule, char16* lpBaseName, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetModuleFileNameExA(HANDLE hProcess, HINSTANCE hModule, uint8* lpFilename, uint32 nSize);
	public static uint32 K32GetModuleFileNameEx(HANDLE hProcess, HINSTANCE hModule, uint8* lpFilename, uint32 nSize) => K32GetModuleFileNameExA(hProcess, hModule, lpFilename, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetModuleFileNameExW(HANDLE hProcess, HINSTANCE hModule, char16* lpFilename, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32GetModuleInformation(HANDLE hProcess, HINSTANCE hModule, MODULEINFO* lpmodinfo, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EmptyWorkingSet(HANDLE hProcess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32InitializeProcessForWsWatch(HANDLE hProcess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32GetWsChanges(HANDLE hProcess, PSAPI_WS_WATCH_INFORMATION* lpWatchInfo, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32GetWsChangesEx(HANDLE hProcess, PSAPI_WS_WATCH_INFORMATION_EX* lpWatchInfoEx, uint32* cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetMappedFileNameW(HANDLE hProcess, void* lpv, char16* lpFilename, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetMappedFileNameA(HANDLE hProcess, void* lpv, uint8* lpFilename, uint32 nSize);
	public static uint32 K32GetMappedFileName(HANDLE hProcess, void* lpv, uint8* lpFilename, uint32 nSize) => K32GetMappedFileNameA(hProcess, lpv, lpFilename, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EnumDeviceDrivers(void** lpImageBase, uint32 cb, uint32* lpcbNeeded);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetDeviceDriverBaseNameA(void* ImageBase, uint8* lpFilename, uint32 nSize);
	public static uint32 K32GetDeviceDriverBaseName(void* ImageBase, uint8* lpFilename, uint32 nSize) => K32GetDeviceDriverBaseNameA(ImageBase, lpFilename, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetDeviceDriverBaseNameW(void* ImageBase, char16* lpBaseName, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetDeviceDriverFileNameA(void* ImageBase, uint8* lpFilename, uint32 nSize);
	public static uint32 K32GetDeviceDriverFileName(void* ImageBase, uint8* lpFilename, uint32 nSize) => K32GetDeviceDriverFileNameA(ImageBase, lpFilename, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetDeviceDriverFileNameW(void* ImageBase, char16* lpFilename, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32QueryWorkingSet(HANDLE hProcess, void* pv, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32QueryWorkingSetEx(HANDLE hProcess, void* pv, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32GetProcessMemoryInfo(HANDLE Process, PROCESS_MEMORY_COUNTERS* ppsmemCounters, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32GetPerformanceInfo(PERFORMANCE_INFORMATION* pPerformanceInformation, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EnumPageFilesW(PENUM_PAGE_FILE_CALLBACKW pCallBackRoutine, void* pContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL K32EnumPageFilesA(PENUM_PAGE_FILE_CALLBACKA pCallBackRoutine, void* pContext);
	public static BOOL K32EnumPageFiles(PENUM_PAGE_FILE_CALLBACKA pCallBackRoutine, void* pContext) => K32EnumPageFilesA(pCallBackRoutine, pContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetProcessImageFileNameA(HANDLE hProcess, uint8* lpImageFileName, uint32 nSize);
	public static uint32 K32GetProcessImageFileName(HANDLE hProcess, uint8* lpImageFileName, uint32 nSize) => K32GetProcessImageFileNameA(hProcess, lpImageFileName, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 K32GetProcessImageFileNameW(HANDLE hProcess, char16* lpImageFileName, uint32 nSize);

}
#endregion
