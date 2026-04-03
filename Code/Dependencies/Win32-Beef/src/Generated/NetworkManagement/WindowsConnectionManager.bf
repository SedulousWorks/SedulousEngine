using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.WindowsConnectionManager;

#region Constants
public static
{
	public const uint32 WCM_API_VERSION_1_0 = 1;
	public const uint32 WCM_API_VERSION = 1;
	public const uint32 WCM_UNKNOWN_DATAPLAN_STATUS = 4294967295;
	public const uint32 WCM_MAX_PROFILE_NAME = 256;
	public const uint32 NET_INTERFACE_FLAG_NONE = 0;
	public const uint32 NET_INTERFACE_FLAG_CONNECT_IF_NEEDED = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WCM_PROPERTY : int32
{
	wcm_global_property_domain_policy = 0,
	wcm_global_property_minimize_policy = 1,
	wcm_global_property_roaming_policy = 2,
	wcm_global_property_powermanagement_policy = 3,
	wcm_intf_property_connection_cost = 4,
	wcm_intf_property_dataplan_status = 5,
	wcm_intf_property_hotspot_profile = 6,
}


[AllowDuplicates]
public enum WCM_MEDIA_TYPE : int32
{
	wcm_media_unknown = 0,
	wcm_media_ethernet = 1,
	wcm_media_wlan = 2,
	wcm_media_mbn = 3,
	wcm_media_invalid = 4,
	wcm_media_max = 5,
}


[AllowDuplicates]
public enum WCM_CONNECTION_COST : int32
{
	WCM_CONNECTION_COST_UNKNOWN = 0,
	WCM_CONNECTION_COST_UNRESTRICTED = 1,
	WCM_CONNECTION_COST_FIXED = 2,
	WCM_CONNECTION_COST_VARIABLE = 4,
	WCM_CONNECTION_COST_OVERDATALIMIT = 65536,
	WCM_CONNECTION_COST_CONGESTED = 131072,
	WCM_CONNECTION_COST_ROAMING = 262144,
	WCM_CONNECTION_COST_APPROACHINGDATALIMIT = 524288,
}


[AllowDuplicates]
public enum WCM_CONNECTION_COST_SOURCE : int32
{
	WCM_CONNECTION_COST_SOURCE_DEFAULT = 0,
	WCM_CONNECTION_COST_SOURCE_GP = 1,
	WCM_CONNECTION_COST_SOURCE_USER = 2,
	WCM_CONNECTION_COST_SOURCE_OPERATOR = 3,
}

#endregion

#region Function Pointers
public function void ONDEMAND_NOTIFICATION_CALLBACK(void* param0);

#endregion

#region Structs
[CRepr]
public struct WCM_POLICY_VALUE
{
	public BOOL fValue;
	public BOOL fIsGroupPolicy;
}

[CRepr]
public struct WCM_PROFILE_INFO
{
	public char16[256] strProfileName;
	public Guid AdapterGUID;
	public WCM_MEDIA_TYPE Media;
}

[CRepr]
public struct WCM_PROFILE_INFO_LIST
{
	public uint32 dwNumberOfItems;
	public WCM_PROFILE_INFO* ProfileInfo mut => &ProfileInfo_impl;
	private WCM_PROFILE_INFO[ANYSIZE_ARRAY] ProfileInfo_impl;
}

[CRepr]
public struct WCM_CONNECTION_COST_DATA
{
	public uint32 ConnectionCost;
	public WCM_CONNECTION_COST_SOURCE CostSource;
}

[CRepr]
public struct WCM_TIME_INTERVAL
{
	public uint16 wYear;
	public uint16 wMonth;
	public uint16 wDay;
	public uint16 wHour;
	public uint16 wMinute;
	public uint16 wSecond;
	public uint16 wMilliseconds;
}

[CRepr]
public struct WCM_USAGE_DATA
{
	public uint32 UsageInMegabytes;
	public FILETIME LastSyncTime;
}

[CRepr]
public struct WCM_BILLING_CYCLE_INFO
{
	public FILETIME StartDate;
	public WCM_TIME_INTERVAL Duration;
	public BOOL Reset;
}

[CRepr]
public struct WCM_DATAPLAN_STATUS
{
	public WCM_USAGE_DATA UsageData;
	public uint32 DataLimitInMegabytes;
	public uint32 InboundBandwidthInKbps;
	public uint32 OutboundBandwidthInKbps;
	public WCM_BILLING_CYCLE_INFO BillingCycle;
	public uint32 MaxTransferSizeInMegabytes;
	public uint32 Reserved;
}

[CRepr]
public struct NET_INTERFACE_CONTEXT
{
	public uint32 InterfaceIndex;
	public PWSTR ConfigurationName;
}

[CRepr]
public struct NET_INTERFACE_CONTEXT_TABLE
{
	public HANDLE InterfaceContextHandle;
	public uint32 NumberOfEntries;
	public NET_INTERFACE_CONTEXT* InterfaceContextArray;
}

#endregion

#region Functions
public static
{
	[Import("wcmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WcmQueryProperty(Guid* pInterface, PWSTR strProfileName, WCM_PROPERTY Property, void* pReserved, uint32* pdwDataSize, uint8** ppData);

	[Import("wcmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WcmSetProperty(Guid* pInterface, PWSTR strProfileName, WCM_PROPERTY Property, void* pReserved, uint32 dwDataSize, uint8* pbData);

	[Import("wcmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WcmGetProfileList(void* pReserved, WCM_PROFILE_INFO_LIST** ppProfileList);

	[Import("wcmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WcmSetProfileList(WCM_PROFILE_INFO_LIST* pProfileList, uint32 dwPosition, BOOL fIgnoreUnknownProfiles, void* pReserved);

	[Import("wcmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WcmFreeMemory(void* pMemory);

	[Import("OnDemandConnRouteHelper.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OnDemandGetRoutingHint(PWSTR destinationHostName, uint32* interfaceIndex);

	[Import("OnDemandConnRouteHelper.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OnDemandRegisterNotification(ONDEMAND_NOTIFICATION_CALLBACK callback, void* callbackContext, HANDLE* registrationHandle);

	[Import("OnDemandConnRouteHelper.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OnDemandUnRegisterNotification(HANDLE registrationHandle);

	[Import("OnDemandConnRouteHelper.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetInterfaceContextTableForHostName(PWSTR HostName, PWSTR ProxyName, uint32 Flags, uint8* ConnectionProfileFilterRawData, uint32 ConnectionProfileFilterRawDataSize, NET_INTERFACE_CONTEXT_TABLE** InterfaceContextTable);

	[Import("OnDemandConnRouteHelper.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeInterfaceContextTable(NET_INTERFACE_CONTEXT_TABLE* InterfaceContextTable);

}
#endregion
