using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.EventNotificationService;

#region Constants
public static
{
	public const uint32 NETWORK_ALIVE_LAN = 1;
	public const uint32 NETWORK_ALIVE_WAN = 2;
	public const uint32 NETWORK_ALIVE_AOL = 4;
	public const uint32 NETWORK_ALIVE_INTERNET = 8;
	public const uint32 CONNECTION_AOL = 4;
	public const Guid SENSGUID_PUBLISHER = .(0x5fee1bd6, 0x5b9b, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
	public const Guid SENSGUID_SUBSCRIBER_LCE = .(0xd3938ab0, 0x5b9d, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
	public const Guid SENSGUID_SUBSCRIBER_WININET = .(0xd3938ab5, 0x5b9d, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
	public const Guid SENSGUID_EVENTCLASS_NETWORK = .(0xd5978620, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
	public const Guid SENSGUID_EVENTCLASS_LOGON = .(0xd5978630, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
	public const Guid SENSGUID_EVENTCLASS_ONNOW = .(0xd5978640, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
	public const Guid SENSGUID_EVENTCLASS_LOGON2 = .(0xd5978650, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);
}
#endregion

#region Enums

[AllowDuplicates]
public enum SENS_CONNECTION_TYPE : uint32
{
	CONNECTION_LAN = 0,
	CONNECTION_WAN = 1,
}

#endregion


#region Structs
[CRepr]
public struct QOCINFO
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwInSpeed;
	public uint32 dwOutSpeed;
}

[CRepr]
public struct SENS_QOCINFO
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwOutSpeed;
	public uint32 dwInSpeed;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_SENS = .(0xd597cafe, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);


}
#endregion

#region COM Types
[CRepr]struct ISensNetwork : IDispatch
{
	public new const Guid IID = .(0xd597bab1, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnection, uint32 ulType, SENS_QOCINFO* lpQOCInfo) ConnectionMade;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnection, uint32 ulType) ConnectionMadeNoQOCInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnection, SENS_CONNECTION_TYPE ulType) ConnectionLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDestination, BSTR bstrConnection, uint32 ulType, SENS_QOCINFO* lpQOCInfo) DestinationReachable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDestination, BSTR bstrConnection, uint32 ulType) DestinationReachableNoQOCInfo;
	}


	public HRESULT ConnectionMade(BSTR bstrConnection, uint32 ulType, SENS_QOCINFO* lpQOCInfo) mut => VT.[Friend]ConnectionMade(&this, bstrConnection, ulType, lpQOCInfo);

	public HRESULT ConnectionMadeNoQOCInfo(BSTR bstrConnection, uint32 ulType) mut => VT.[Friend]ConnectionMadeNoQOCInfo(&this, bstrConnection, ulType);

	public HRESULT ConnectionLost(BSTR bstrConnection, SENS_CONNECTION_TYPE ulType) mut => VT.[Friend]ConnectionLost(&this, bstrConnection, ulType);

	public HRESULT DestinationReachable(BSTR bstrDestination, BSTR bstrConnection, uint32 ulType, SENS_QOCINFO* lpQOCInfo) mut => VT.[Friend]DestinationReachable(&this, bstrDestination, bstrConnection, ulType, lpQOCInfo);

	public HRESULT DestinationReachableNoQOCInfo(BSTR bstrDestination, BSTR bstrConnection, uint32 ulType) mut => VT.[Friend]DestinationReachableNoQOCInfo(&this, bstrDestination, bstrConnection, ulType);
}

[CRepr]struct ISensOnNow : IDispatch
{
	public new const Guid IID = .(0xd597bab2, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnACPower;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBatteryLifePercent) OnBatteryPower;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBatteryLifePercent) BatteryLow;
	}


	public HRESULT OnACPower() mut => VT.[Friend]OnACPower(&this);

	public HRESULT OnBatteryPower(uint32 dwBatteryLifePercent) mut => VT.[Friend]OnBatteryPower(&this, dwBatteryLifePercent);

	public HRESULT BatteryLow(uint32 dwBatteryLifePercent) mut => VT.[Friend]BatteryLow(&this, dwBatteryLifePercent);
}

[CRepr]struct ISensLogon : IDispatch
{
	public new const Guid IID = .(0xd597bab3, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) Logon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) Logoff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) StartShell;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) DisplayLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) DisplayUnlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) StartScreenSaver;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName) StopScreenSaver;
	}


	public HRESULT Logon(BSTR bstrUserName) mut => VT.[Friend]Logon(&this, bstrUserName);

	public HRESULT Logoff(BSTR bstrUserName) mut => VT.[Friend]Logoff(&this, bstrUserName);

	public HRESULT StartShell(BSTR bstrUserName) mut => VT.[Friend]StartShell(&this, bstrUserName);

	public HRESULT DisplayLock(BSTR bstrUserName) mut => VT.[Friend]DisplayLock(&this, bstrUserName);

	public HRESULT DisplayUnlock(BSTR bstrUserName) mut => VT.[Friend]DisplayUnlock(&this, bstrUserName);

	public HRESULT StartScreenSaver(BSTR bstrUserName) mut => VT.[Friend]StartScreenSaver(&this, bstrUserName);

	public HRESULT StopScreenSaver(BSTR bstrUserName) mut => VT.[Friend]StopScreenSaver(&this, bstrUserName);
}

[CRepr]struct ISensLogon2 : IDispatch
{
	public new const Guid IID = .(0xd597bab4, 0x5b9f, 0x11d1, 0x8d, 0xd2, 0x00, 0xaa, 0x00, 0x4a, 0xbd, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName, uint32 dwSessionId) Logon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName, uint32 dwSessionId) Logoff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName, uint32 dwSessionId) SessionDisconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName, uint32 dwSessionId) SessionReconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName, uint32 dwSessionId) PostShell;
	}


	public HRESULT Logon(BSTR bstrUserName, uint32 dwSessionId) mut => VT.[Friend]Logon(&this, bstrUserName, dwSessionId);

	public HRESULT Logoff(BSTR bstrUserName, uint32 dwSessionId) mut => VT.[Friend]Logoff(&this, bstrUserName, dwSessionId);

	public HRESULT SessionDisconnect(BSTR bstrUserName, uint32 dwSessionId) mut => VT.[Friend]SessionDisconnect(&this, bstrUserName, dwSessionId);

	public HRESULT SessionReconnect(BSTR bstrUserName, uint32 dwSessionId) mut => VT.[Friend]SessionReconnect(&this, bstrUserName, dwSessionId);

	public HRESULT PostShell(BSTR bstrUserName, uint32 dwSessionId) mut => VT.[Friend]PostShell(&this, bstrUserName, dwSessionId);
}

#endregion

#region Functions
public static
{
	[Import("SensApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsDestinationReachableA(PSTR lpszDestination, QOCINFO* lpQOCInfo);
	public static BOOL IsDestinationReachable(PSTR lpszDestination, QOCINFO* lpQOCInfo) => IsDestinationReachableA(lpszDestination, lpQOCInfo);

	[Import("SensApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsDestinationReachableW(PWSTR lpszDestination, QOCINFO* lpQOCInfo);

	[Import("SensApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsNetworkAlive(uint32* lpdwFlags);

}
#endregion
