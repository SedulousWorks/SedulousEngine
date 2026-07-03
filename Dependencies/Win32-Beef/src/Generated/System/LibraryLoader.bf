using Win32.Foundation;
using System;

namespace Win32.System.LibraryLoader;

#region Constants
public static
{
	public const uint32 FIND_RESOURCE_DIRECTORY_TYPES = 256;
	public const uint32 FIND_RESOURCE_DIRECTORY_NAMES = 512;
	public const uint32 FIND_RESOURCE_DIRECTORY_LANGUAGES = 1024;
	public const uint32 RESOURCE_ENUM_LN = 1;
	public const uint32 RESOURCE_ENUM_MUI = 2;
	public const uint32 RESOURCE_ENUM_MUI_SYSTEM = 4;
	public const uint32 RESOURCE_ENUM_VALIDATE = 8;
	public const uint32 RESOURCE_ENUM_MODULE_EXACT = 16;
	public const uint32 SUPPORT_LANG_NUMBER = 32;
	public const uint32 GET_MODULE_HANDLE_EX_FLAG_PIN = 1;
	public const uint32 GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = 2;
	public const uint32 GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = 4;
	public const uint32 CURRENT_IMPORT_REDIRECTION_VERSION = 1;
	public const uint32 LOAD_LIBRARY_OS_INTEGRITY_CONTINUITY = 32768;
}
#endregion

#region Enums

[AllowDuplicates]
public enum LOAD_LIBRARY_FLAGS : uint32
{
	DONT_RESOLVE_DLL_REFERENCES = 1,
	LOAD_LIBRARY_AS_DATAFILE = 2,
	LOAD_WITH_ALTERED_SEARCH_PATH = 8,
	LOAD_IGNORE_CODE_AUTHZ_LEVEL = 16,
	LOAD_LIBRARY_AS_IMAGE_RESOURCE = 32,
	LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE = 64,
	LOAD_LIBRARY_REQUIRE_SIGNED_TARGET = 128,
	LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR = 256,
	LOAD_LIBRARY_SEARCH_APPLICATION_DIR = 512,
	LOAD_LIBRARY_SEARCH_USER_DIRS = 1024,
	LOAD_LIBRARY_SEARCH_SYSTEM32 = 2048,
	LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 4096,
	LOAD_LIBRARY_SAFE_CURRENT_DIRS = 8192,
	LOAD_LIBRARY_SEARCH_SYSTEM32_NO_FORWARDER = 16384,
}

#endregion

#region Function Pointers
public function BOOL ENUMRESLANGPROCA(HINSTANCE hModule, PSTR lpType, PSTR lpName, uint16 wLanguage, int lParam);

public function BOOL ENUMRESLANGPROCW(HINSTANCE hModule, PWSTR lpType, PWSTR lpName, uint16 wLanguage, int lParam);

public function BOOL ENUMRESNAMEPROCA(HINSTANCE hModule, PSTR lpType, PSTR lpName, int lParam);

public function BOOL ENUMRESNAMEPROCW(HINSTANCE hModule, PWSTR lpType, PWSTR lpName, int lParam);

public function BOOL ENUMRESTYPEPROCA(HINSTANCE hModule, PSTR lpType, int lParam);

public function BOOL ENUMRESTYPEPROCW(HINSTANCE hModule, PWSTR lpType, int lParam);

public function BOOL PGET_MODULE_HANDLE_EXA(uint32 dwFlags, PSTR lpModuleName, HINSTANCE* phModule);

public function BOOL PGET_MODULE_HANDLE_EXW(uint32 dwFlags, PWSTR lpModuleName, HINSTANCE* phModule);

#endregion

#region Structs
[CRepr]
public struct ENUMUILANG
{
	public uint32 NumOfEnumUILang;
	public uint32 SizeOfEnumUIBuffer;
	public uint16* pEnumUIBuffer;
}

[CRepr]
public struct REDIRECTION_FUNCTION_DESCRIPTOR
{
	public PSTR DllName;
	public PSTR FunctionName;
	public void* RedirectionTarget;
}

[CRepr]
public struct REDIRECTION_DESCRIPTOR
{
	public uint32 Version;
	public uint32 FunctionCount;
	public REDIRECTION_FUNCTION_DESCRIPTOR* Redirections;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DisableThreadLibraryCalls(HINSTANCE hLibModule);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRSRC FindResourceExW(HINSTANCE hModule, PWSTR lpType, PWSTR lpName, uint16 wLanguage);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeLibrary(HINSTANCE hLibModule);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeLibraryAndExitThread(HINSTANCE hLibModule, uint32 dwExitCode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeResource(int hResData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetModuleFileNameA(HINSTANCE hModule, uint8* lpFilename, uint32 nSize);
	public static uint32 GetModuleFileName(HINSTANCE hModule, uint8* lpFilename, uint32 nSize) => GetModuleFileNameA(hModule, lpFilename, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetModuleFileNameW(HINSTANCE hModule, char16* lpFilename, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE GetModuleHandleA(PSTR lpModuleName);
	public static HINSTANCE GetModuleHandle(PSTR lpModuleName) => GetModuleHandleA(lpModuleName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE GetModuleHandleW(PWSTR lpModuleName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetModuleHandleExA(uint32 dwFlags, PSTR lpModuleName, HINSTANCE* phModule);
	public static BOOL GetModuleHandleEx(uint32 dwFlags, PSTR lpModuleName, HINSTANCE* phModule) => GetModuleHandleExA(dwFlags, lpModuleName, phModule);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetModuleHandleExW(uint32 dwFlags, PWSTR lpModuleName, HINSTANCE* phModule);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FARPROC GetProcAddress(HINSTANCE hModule, PSTR lpProcName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE LoadLibraryExA(PSTR lpLibFileName, HANDLE hFile, LOAD_LIBRARY_FLAGS dwFlags);
	public static HINSTANCE LoadLibraryEx(PSTR lpLibFileName, HANDLE hFile, LOAD_LIBRARY_FLAGS dwFlags) => LoadLibraryExA(lpLibFileName, hFile, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE LoadLibraryExW(PWSTR lpLibFileName, HANDLE hFile, LOAD_LIBRARY_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int LoadResource(HINSTANCE hModule, HRSRC hResInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* LockResource(int hResData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SizeofResource(HINSTANCE hModule, HRSRC hResInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* AddDllDirectory(PWSTR NewDirectory);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveDllDirectory(void* Cookie);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDefaultDllDirectories(LOAD_LIBRARY_FLAGS DirectoryFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceLanguagesExA(HINSTANCE hModule, PSTR lpType, PSTR lpName, ENUMRESLANGPROCA lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId);
	public static BOOL EnumResourceLanguagesEx(HINSTANCE hModule, PSTR lpType, PSTR lpName, ENUMRESLANGPROCA lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId) => EnumResourceLanguagesExA(hModule, lpType, lpName, lpEnumFunc, lParam, dwFlags, LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceLanguagesExW(HINSTANCE hModule, PWSTR lpType, PWSTR lpName, ENUMRESLANGPROCW lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceNamesExA(HINSTANCE hModule, PSTR lpType, ENUMRESNAMEPROCA lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId);
	public static BOOL EnumResourceNamesEx(HINSTANCE hModule, PSTR lpType, ENUMRESNAMEPROCA lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId) => EnumResourceNamesExA(hModule, lpType, lpEnumFunc, lParam, dwFlags, LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceNamesExW(HINSTANCE hModule, PWSTR lpType, ENUMRESNAMEPROCW lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceTypesExA(HINSTANCE hModule, ENUMRESTYPEPROCA lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId);
	public static BOOL EnumResourceTypesEx(HINSTANCE hModule, ENUMRESTYPEPROCA lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId) => EnumResourceTypesExA(hModule, lpEnumFunc, lParam, dwFlags, LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceTypesExW(HINSTANCE hModule, ENUMRESTYPEPROCW lpEnumFunc, int lParam, uint32 dwFlags, uint16 LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRSRC FindResourceW(HINSTANCE hModule, PWSTR lpName, PWSTR lpType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE LoadLibraryA(PSTR lpLibFileName);
	public static HINSTANCE LoadLibrary(PSTR lpLibFileName) => LoadLibraryA(lpLibFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE LoadLibraryW(PWSTR lpLibFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceNamesW(HINSTANCE hModule, PWSTR lpType, ENUMRESNAMEPROCW lpEnumFunc, int lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceNamesA(HINSTANCE hModule, PSTR lpType, ENUMRESNAMEPROCA lpEnumFunc, int lParam);
	public static BOOL EnumResourceNames(HINSTANCE hModule, PSTR lpType, ENUMRESNAMEPROCA lpEnumFunc, int lParam) => EnumResourceNamesA(hModule, lpType, lpEnumFunc, lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LoadModule(PSTR lpModuleName, void* lpParameterBlock);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE LoadPackagedLibrary(PWSTR lpwLibFileName, uint32 Reserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRSRC FindResourceA(HINSTANCE hModule, PSTR lpName, PSTR lpType);
	public static HRSRC FindResource(HINSTANCE hModule, PSTR lpName, PSTR lpType) => FindResourceA(hModule, lpName, lpType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRSRC FindResourceExA(HINSTANCE hModule, PSTR lpType, PSTR lpName, uint16 wLanguage);
	public static HRSRC FindResourceEx(HINSTANCE hModule, PSTR lpType, PSTR lpName, uint16 wLanguage) => FindResourceExA(hModule, lpType, lpName, wLanguage);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceTypesA(HINSTANCE hModule, ENUMRESTYPEPROCA lpEnumFunc, int lParam);
	public static BOOL EnumResourceTypes(HINSTANCE hModule, ENUMRESTYPEPROCA lpEnumFunc, int lParam) => EnumResourceTypesA(hModule, lpEnumFunc, lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceTypesW(HINSTANCE hModule, ENUMRESTYPEPROCW lpEnumFunc, int lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceLanguagesA(HINSTANCE hModule, PSTR lpType, PSTR lpName, ENUMRESLANGPROCA lpEnumFunc, int lParam);
	public static BOOL EnumResourceLanguages(HINSTANCE hModule, PSTR lpType, PSTR lpName, ENUMRESLANGPROCA lpEnumFunc, int lParam) => EnumResourceLanguagesA(hModule, lpType, lpName, lpEnumFunc, lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumResourceLanguagesW(HINSTANCE hModule, PWSTR lpType, PWSTR lpName, ENUMRESLANGPROCW lpEnumFunc, int lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE BeginUpdateResourceA(PSTR pFileName, BOOL bDeleteExistingResources);
	public static HANDLE BeginUpdateResource(PSTR pFileName, BOOL bDeleteExistingResources) => BeginUpdateResourceA(pFileName, bDeleteExistingResources);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE BeginUpdateResourceW(PWSTR pFileName, BOOL bDeleteExistingResources);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateResourceA(HANDLE hUpdate, PSTR lpType, PSTR lpName, uint16 wLanguage, void* lpData, uint32 cb);
	public static BOOL UpdateResource(HANDLE hUpdate, PSTR lpType, PSTR lpName, uint16 wLanguage, void* lpData, uint32 cb) => UpdateResourceA(hUpdate, lpType, lpName, wLanguage, lpData, cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateResourceW(HANDLE hUpdate, PWSTR lpType, PWSTR lpName, uint16 wLanguage, void* lpData, uint32 cb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndUpdateResourceA(HANDLE hUpdate, BOOL fDiscard);
	public static BOOL EndUpdateResource(HANDLE hUpdate, BOOL fDiscard) => EndUpdateResourceA(hUpdate, fDiscard);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EndUpdateResourceW(HANDLE hUpdate, BOOL fDiscard);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDllDirectoryA(PSTR lpPathName);
	public static BOOL SetDllDirectory(PSTR lpPathName) => SetDllDirectoryA(lpPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDllDirectoryW(PWSTR lpPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDllDirectoryA(uint32 nBufferLength, uint8* lpBuffer);
	public static uint32 GetDllDirectory(uint32 nBufferLength, uint8* lpBuffer) => GetDllDirectoryA(nBufferLength, lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDllDirectoryW(uint32 nBufferLength, char16* lpBuffer);

}
#endregion
