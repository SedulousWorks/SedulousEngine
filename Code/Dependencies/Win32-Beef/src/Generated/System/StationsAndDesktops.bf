using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.Security;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.System.StationsAndDesktops;

#region TypeDefs
typealias HWINSTA = int;

typealias HDESK = int;

#endregion


#region Enums

[AllowDuplicates]
public enum BROADCAST_SYSTEM_MESSAGE_FLAGS : uint32
{
	BSF_ALLOWSFW = 128,
	BSF_FLUSHDISK = 4,
	BSF_FORCEIFHUNG = 32,
	BSF_IGNORECURRENTTASK = 2,
	BSF_NOHANG = 8,
	BSF_NOTIMEOUTIFNOTHUNG = 64,
	BSF_POSTMESSAGE = 16,
	BSF_QUERY = 1,
	BSF_SENDNOTIFYMESSAGE = 256,
	BSF_LUID = 1024,
	BSF_RETURNHDESK = 512,
}


[AllowDuplicates]
public enum BROADCAST_SYSTEM_MESSAGE_INFO : uint32
{
	BSM_ALLCOMPONENTS = 0,
	BSM_ALLDESKTOPS = 16,
	BSM_APPLICATIONS = 8,
}


[AllowDuplicates]
public enum USER_OBJECT_INFORMATION_INDEX : uint32
{
	UOI_FLAGS = 1,
	UOI_HEAPSIZE = 5,
	UOI_IO = 6,
	UOI_NAME = 2,
	UOI_TYPE = 3,
	UOI_USER_SID = 4,
}


[AllowDuplicates]
public enum DESKTOP_CONTROL_FLAGS : uint32
{
	DF_ALLOWOTHERACCOUNTHOOK = 1,
}

#endregion

#region Function Pointers
public function BOOL WINSTAENUMPROCA(PSTR param0, LPARAM param1);

public function BOOL WINSTAENUMPROCW(PWSTR param0, LPARAM param1);

public function BOOL DESKTOPENUMPROCA(PSTR param0, LPARAM param1);

public function BOOL DESKTOPENUMPROCW(PWSTR param0, LPARAM param1);

#endregion

#region Structs
[CRepr]
public struct USEROBJECTFLAGS
{
	public BOOL fInherit;
	public BOOL fReserved;
	public uint32 dwFlags;
}

[CRepr]
public struct BSMINFO
{
	public uint32 cbSize;
	public HDESK hdesk;
	public HWND hwnd;
	public LUID luid;
}

#endregion

#region Functions
public static
{
	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK CreateDesktopA(PSTR lpszDesktop, PSTR lpszDevice, DEVMODEA* pDevmode, DESKTOP_CONTROL_FLAGS dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa);
	public static HDESK CreateDesktop(PSTR lpszDesktop, PSTR lpszDevice, DEVMODEA* pDevmode, DESKTOP_CONTROL_FLAGS dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa) => CreateDesktopA(lpszDesktop, lpszDevice, pDevmode, dwFlags, dwDesiredAccess, lpsa);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK CreateDesktopW(PWSTR lpszDesktop, PWSTR lpszDevice, DEVMODEW* pDevmode, DESKTOP_CONTROL_FLAGS dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK CreateDesktopExA(PSTR lpszDesktop, PSTR lpszDevice, DEVMODEA* pDevmode, DESKTOP_CONTROL_FLAGS dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa, uint32 ulHeapSize, void* pvoid);
	public static HDESK CreateDesktopEx(PSTR lpszDesktop, PSTR lpszDevice, DEVMODEA* pDevmode, DESKTOP_CONTROL_FLAGS dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa, uint32 ulHeapSize, void* pvoid) => CreateDesktopExA(lpszDesktop, lpszDevice, pDevmode, dwFlags, dwDesiredAccess, lpsa, ulHeapSize, pvoid);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK CreateDesktopExW(PWSTR lpszDesktop, PWSTR lpszDevice, DEVMODEW* pDevmode, DESKTOP_CONTROL_FLAGS dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa, uint32 ulHeapSize, void* pvoid);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK OpenDesktopA(PSTR lpszDesktop, DESKTOP_CONTROL_FLAGS dwFlags, BOOL fInherit, uint32 dwDesiredAccess);
	public static HDESK OpenDesktop(PSTR lpszDesktop, DESKTOP_CONTROL_FLAGS dwFlags, BOOL fInherit, uint32 dwDesiredAccess) => OpenDesktopA(lpszDesktop, dwFlags, fInherit, dwDesiredAccess);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK OpenDesktopW(PWSTR lpszDesktop, DESKTOP_CONTROL_FLAGS dwFlags, BOOL fInherit, uint32 dwDesiredAccess);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK OpenInputDesktop(DESKTOP_CONTROL_FLAGS dwFlags, BOOL fInherit, uint32 dwDesiredAccess);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDesktopsA(HWINSTA hwinsta, DESKTOPENUMPROCA lpEnumFunc, LPARAM lParam);
	public static BOOL EnumDesktops(HWINSTA hwinsta, DESKTOPENUMPROCA lpEnumFunc, LPARAM lParam) => EnumDesktopsA(hwinsta, lpEnumFunc, lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDesktopsW(HWINSTA hwinsta, DESKTOPENUMPROCW lpEnumFunc, LPARAM lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDesktopWindows(HDESK hDesktop, WNDENUMPROC lpfn, LPARAM lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SwitchDesktop(HDESK hDesktop);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadDesktop(HDESK hDesktop);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseDesktop(HDESK hDesktop);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDESK GetThreadDesktop(uint32 dwThreadId);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINSTA CreateWindowStationA(PSTR lpwinsta, uint32 dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa);
	public static HWINSTA CreateWindowStation(PSTR lpwinsta, uint32 dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa) => CreateWindowStationA(lpwinsta, dwFlags, dwDesiredAccess, lpsa);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINSTA CreateWindowStationW(PWSTR lpwinsta, uint32 dwFlags, uint32 dwDesiredAccess, SECURITY_ATTRIBUTES* lpsa);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINSTA OpenWindowStationA(PSTR lpszWinSta, BOOL fInherit, uint32 dwDesiredAccess);
	public static HWINSTA OpenWindowStation(PSTR lpszWinSta, BOOL fInherit, uint32 dwDesiredAccess) => OpenWindowStationA(lpszWinSta, fInherit, dwDesiredAccess);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINSTA OpenWindowStationW(PWSTR lpszWinSta, BOOL fInherit, uint32 dwDesiredAccess);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumWindowStationsA(WINSTAENUMPROCA lpEnumFunc, LPARAM lParam);
	public static BOOL EnumWindowStations(WINSTAENUMPROCA lpEnumFunc, LPARAM lParam) => EnumWindowStationsA(lpEnumFunc, lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumWindowStationsW(WINSTAENUMPROCW lpEnumFunc, LPARAM lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseWindowStation(HWINSTA hWinSta);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessWindowStation(HWINSTA hWinSta);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINSTA GetProcessWindowStation();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserObjectInformationA(HANDLE hObj, USER_OBJECT_INFORMATION_INDEX nIndex, void* pvInfo, uint32 nLength, uint32* lpnLengthNeeded);
	public static BOOL GetUserObjectInformation(HANDLE hObj, USER_OBJECT_INFORMATION_INDEX nIndex, void* pvInfo, uint32 nLength, uint32* lpnLengthNeeded) => GetUserObjectInformationA(hObj, nIndex, pvInfo, nLength, lpnLengthNeeded);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserObjectInformationW(HANDLE hObj, USER_OBJECT_INFORMATION_INDEX nIndex, void* pvInfo, uint32 nLength, uint32* lpnLengthNeeded);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetUserObjectInformationA(HANDLE hObj, int32 nIndex, void* pvInfo, uint32 nLength);
	public static BOOL SetUserObjectInformation(HANDLE hObj, int32 nIndex, void* pvInfo, uint32 nLength) => SetUserObjectInformationA(hObj, nIndex, pvInfo, nLength);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetUserObjectInformationW(HANDLE hObj, int32 nIndex, void* pvInfo, uint32 nLength);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 BroadcastSystemMessageExA(BROADCAST_SYSTEM_MESSAGE_FLAGS flags, BROADCAST_SYSTEM_MESSAGE_INFO* lpInfo, uint32 Msg, WPARAM wParam, LPARAM lParam, BSMINFO* pbsmInfo);
	public static int32 BroadcastSystemMessageEx(BROADCAST_SYSTEM_MESSAGE_FLAGS flags, BROADCAST_SYSTEM_MESSAGE_INFO* lpInfo, uint32 Msg, WPARAM wParam, LPARAM lParam, BSMINFO* pbsmInfo) => BroadcastSystemMessageExA(flags, lpInfo, Msg, wParam, lParam, pbsmInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 BroadcastSystemMessageExW(BROADCAST_SYSTEM_MESSAGE_FLAGS flags, BROADCAST_SYSTEM_MESSAGE_INFO* lpInfo, uint32 Msg, WPARAM wParam, LPARAM lParam, BSMINFO* pbsmInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 BroadcastSystemMessageA(uint32 flags, uint32* lpInfo, uint32 Msg, WPARAM wParam, LPARAM lParam);
	public static int32 BroadcastSystemMessage(uint32 flags, uint32* lpInfo, uint32 Msg, WPARAM wParam, LPARAM lParam) => BroadcastSystemMessageA(flags, lpInfo, Msg, wParam, lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 BroadcastSystemMessageW(BROADCAST_SYSTEM_MESSAGE_FLAGS flags, BROADCAST_SYSTEM_MESSAGE_INFO* lpInfo, uint32 Msg, WPARAM wParam, LPARAM lParam);

}
#endregion
