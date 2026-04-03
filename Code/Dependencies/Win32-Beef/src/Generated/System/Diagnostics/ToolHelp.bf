using Win32.Foundation;
using System;

namespace Win32.System.Diagnostics.ToolHelp;

#region Constants
public static
{
	public const uint32 MAX_MODULE_NAME32 = 255;
	public const uint32 HF32_DEFAULT = 1;
	public const uint32 HF32_SHARED = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CREATE_TOOLHELP_SNAPSHOT_FLAGS : uint32
{
	TH32CS_INHERIT = 2147483648,
	TH32CS_SNAPALL = 15,
	TH32CS_SNAPHEAPLIST = 1,
	TH32CS_SNAPMODULE = 8,
	TH32CS_SNAPMODULE32 = 16,
	TH32CS_SNAPPROCESS = 2,
	TH32CS_SNAPTHREAD = 4,
}


[AllowDuplicates]
public enum HEAPENTRY32_FLAGS : uint32
{
	LF32_FIXED = 1,
	LF32_FREE = 2,
	LF32_MOVEABLE = 4,
}

#endregion


#region Structs
[CRepr]
public struct HEAPLIST32
{
	public uint dwSize;
	public uint32 th32ProcessID;
	public uint th32HeapID;
	public uint32 dwFlags;
}

[CRepr]
public struct HEAPENTRY32
{
	public uint dwSize;
	public HANDLE hHandle;
	public uint dwAddress;
	public uint dwBlockSize;
	public HEAPENTRY32_FLAGS dwFlags;
	public uint32 dwLockCount;
	public uint32 dwResvd;
	public uint32 th32ProcessID;
	public uint th32HeapID;
}

[CRepr]
public struct PROCESSENTRY32W
{
	public uint32 dwSize;
	public uint32 cntUsage;
	public uint32 th32ProcessID;
	public uint th32DefaultHeapID;
	public uint32 th32ModuleID;
	public uint32 cntThreads;
	public uint32 th32ParentProcessID;
	public int32 pcPriClassBase;
	public uint32 dwFlags;
	public char16[260] szExeFile;
}

[CRepr]
public struct PROCESSENTRY32
{
	public uint32 dwSize;
	public uint32 cntUsage;
	public uint32 th32ProcessID;
	public uint th32DefaultHeapID;
	public uint32 th32ModuleID;
	public uint32 cntThreads;
	public uint32 th32ParentProcessID;
	public int32 pcPriClassBase;
	public uint32 dwFlags;
	public CHAR[260] szExeFile;
}

[CRepr]
public struct THREADENTRY32
{
	public uint32 dwSize;
	public uint32 cntUsage;
	public uint32 th32ThreadID;
	public uint32 th32OwnerProcessID;
	public int32 tpBasePri;
	public int32 tpDeltaPri;
	public uint32 dwFlags;
}

[CRepr]
public struct MODULEENTRY32W
{
	public uint32 dwSize;
	public uint32 th32ModuleID;
	public uint32 th32ProcessID;
	public uint32 GlblcntUsage;
	public uint32 ProccntUsage;
	public uint8* modBaseAddr;
	public uint32 modBaseSize;
	public HINSTANCE hModule;
	public char16[256] szModule;
	public char16[260] szExePath;
}

[CRepr]
public struct MODULEENTRY32
{
	public uint32 dwSize;
	public uint32 th32ModuleID;
	public uint32 th32ProcessID;
	public uint32 GlblcntUsage;
	public uint32 ProccntUsage;
	public uint8* modBaseAddr;
	public uint32 modBaseSize;
	public HINSTANCE hModule;
	public CHAR[256] szModule;
	public CHAR[260] szExePath;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateToolhelp32Snapshot(CREATE_TOOLHELP_SNAPSHOT_FLAGS dwFlags, uint32 th32ProcessID);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Heap32ListFirst(HANDLE hSnapshot, HEAPLIST32* lphl);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Heap32ListNext(HANDLE hSnapshot, HEAPLIST32* lphl);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Heap32First(HEAPENTRY32* lphe, uint32 th32ProcessID, uint th32HeapID);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Heap32Next(HEAPENTRY32* lphe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Toolhelp32ReadProcessMemory(uint32 th32ProcessID, void* lpBaseAddress, void* lpBuffer, uint cbRead, uint* lpNumberOfBytesRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Process32FirstW(HANDLE hSnapshot, PROCESSENTRY32W* lppe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Process32NextW(HANDLE hSnapshot, PROCESSENTRY32W* lppe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Process32First(HANDLE hSnapshot, PROCESSENTRY32* lppe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Process32Next(HANDLE hSnapshot, PROCESSENTRY32* lppe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Thread32First(HANDLE hSnapshot, THREADENTRY32* lpte);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Thread32Next(HANDLE hSnapshot, THREADENTRY32* lpte);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Module32FirstW(HANDLE hSnapshot, MODULEENTRY32W* lpme);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Module32NextW(HANDLE hSnapshot, MODULEENTRY32W* lpme);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Module32First(HANDLE hSnapshot, MODULEENTRY32* lpme);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Module32Next(HANDLE hSnapshot, MODULEENTRY32* lpme);

}
#endregion
