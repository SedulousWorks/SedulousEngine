using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Ole;
using System;

namespace Win32.Networking.NetworkListManager;

#region Constants
public static
{
	public const String NA_DomainAuthenticationFailed = "NA_DomainAuthenticationFailed";
	public const String NA_NetworkClass = "NA_NetworkClass";
	public const String NA_NameSetByPolicy = "NA_NameSetByPolicy";
	public const String NA_IconSetByPolicy = "NA_IconSetByPolicy";
	public const String NA_DescriptionSetByPolicy = "NA_DescriptionSetByPolicy";
	public const String NA_CategorySetByPolicy = "NA_CategorySetByPolicy";
	public const String NA_NameReadOnly = "NA_NameReadOnly";
	public const String NA_IconReadOnly = "NA_IconReadOnly";
	public const String NA_DescriptionReadOnly = "NA_DescriptionReadOnly";
	public const String NA_CategoryReadOnly = "NA_CategoryReadOnly";
	public const String NA_AllowMerge = "NA_AllowMerge";
	public const String NA_InternetConnectivityV4 = "NA_InternetConnectivityV4";
	public const String NA_InternetConnectivityV6 = "NA_InternetConnectivityV6";
	public const uint32 NLM_MAX_ADDRESS_LIST_SIZE = 10;
	public const uint32 NLM_UNKNOWN_DATAPLAN_STATUS = 4294967295;
}
#endregion

#region Enums

[AllowDuplicates]
public enum NLM_CONNECTION_COST : int32
{
	NLM_CONNECTION_COST_UNKNOWN = 0,
	NLM_CONNECTION_COST_UNRESTRICTED = 1,
	NLM_CONNECTION_COST_FIXED = 2,
	NLM_CONNECTION_COST_VARIABLE = 4,
	NLM_CONNECTION_COST_OVERDATALIMIT = 65536,
	NLM_CONNECTION_COST_CONGESTED = 131072,
	NLM_CONNECTION_COST_ROAMING = 262144,
	NLM_CONNECTION_COST_APPROACHINGDATALIMIT = 524288,
}


[AllowDuplicates]
public enum NLM_NETWORK_CLASS : int32
{
	NLM_NETWORK_IDENTIFYING = 1,
	NLM_NETWORK_IDENTIFIED = 2,
	NLM_NETWORK_UNIDENTIFIED = 3,
}


[AllowDuplicates]
public enum NLM_INTERNET_CONNECTIVITY : int32
{
	NLM_INTERNET_CONNECTIVITY_WEBHIJACK = 1,
	NLM_INTERNET_CONNECTIVITY_PROXIED = 2,
	NLM_INTERNET_CONNECTIVITY_CORPORATE = 4,
}


[AllowDuplicates]
public enum NLM_CONNECTIVITY : int32
{
	NLM_CONNECTIVITY_DISCONNECTED = 0,
	NLM_CONNECTIVITY_IPV4_NOTRAFFIC = 1,
	NLM_CONNECTIVITY_IPV6_NOTRAFFIC = 2,
	NLM_CONNECTIVITY_IPV4_SUBNET = 16,
	NLM_CONNECTIVITY_IPV4_LOCALNETWORK = 32,
	NLM_CONNECTIVITY_IPV4_INTERNET = 64,
	NLM_CONNECTIVITY_IPV6_SUBNET = 256,
	NLM_CONNECTIVITY_IPV6_LOCALNETWORK = 512,
	NLM_CONNECTIVITY_IPV6_INTERNET = 1024,
}


[AllowDuplicates]
public enum NLM_DOMAIN_TYPE : int32
{
	NLM_DOMAIN_TYPE_NON_DOMAIN_NETWORK = 0,
	NLM_DOMAIN_TYPE_DOMAIN_NETWORK = 1,
	NLM_DOMAIN_TYPE_DOMAIN_AUTHENTICATED = 2,
}


[AllowDuplicates]
public enum NLM_ENUM_NETWORK : int32
{
	NLM_ENUM_NETWORK_CONNECTED = 1,
	NLM_ENUM_NETWORK_DISCONNECTED = 2,
	NLM_ENUM_NETWORK_ALL = 3,
}


[AllowDuplicates]
public enum NLM_NETWORK_CATEGORY : int32
{
	NLM_NETWORK_CATEGORY_PUBLIC = 0,
	NLM_NETWORK_CATEGORY_PRIVATE = 1,
	NLM_NETWORK_CATEGORY_DOMAIN_AUTHENTICATED = 2,
}


[AllowDuplicates]
public enum NLM_NETWORK_PROPERTY_CHANGE : int32
{
	NLM_NETWORK_PROPERTY_CHANGE_CONNECTION = 1,
	NLM_NETWORK_PROPERTY_CHANGE_DESCRIPTION = 2,
	NLM_NETWORK_PROPERTY_CHANGE_NAME = 4,
	NLM_NETWORK_PROPERTY_CHANGE_ICON = 8,
	NLM_NETWORK_PROPERTY_CHANGE_CATEGORY_VALUE = 16,
}


[AllowDuplicates]
public enum NLM_CONNECTION_PROPERTY_CHANGE : int32
{
	NLM_CONNECTION_PROPERTY_CHANGE_AUTHENTICATION = 1,
}

#endregion


#region Structs
[CRepr]
public struct NLM_USAGE_DATA
{
	public uint32 UsageInMegabytes;
	public FILETIME LastSyncTime;
}

[CRepr]
public struct NLM_DATAPLAN_STATUS
{
	public Guid InterfaceGuid;
	public NLM_USAGE_DATA UsageData;
	public uint32 DataLimitInMegabytes;
	public uint32 InboundBandwidthInKbps;
	public uint32 OutboundBandwidthInKbps;
	public FILETIME NextBillingCycle;
	public uint32 MaxTransferSizeInMegabytes;
	public uint32 Reserved;
}

[CRepr]
public struct NLM_SOCKADDR
{
	public uint8[128] data;
}

[CRepr]
public struct NLM_SIMULATED_PROFILE_INFO
{
	public char16[256] ProfileName;
	public NLM_CONNECTION_COST cost;
	public uint32 UsageInMegabytes;
	public uint32 DataLimitInMegabytes;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_NetworkListManager = .(0xdcb00c01, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);


}
#endregion

#region COM Types
[CRepr]struct INetworkListManager : IDispatch
{
	public new const Guid IID = .(0xdcb00000, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_ENUM_NETWORK Flags, IEnumNetworks** ppEnumNetwork) GetNetworks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid gdNetworkId, INetwork** ppNetwork) GetNetwork;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetworkConnections** ppEnum) GetNetworkConnections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid gdNetworkConnectionId, INetworkConnection** ppNetworkConnection) GetNetworkConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsConnected) get_IsConnectedToInternet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsConnected) get_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_CONNECTIVITY* pConnectivity) GetConnectivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_SIMULATED_PROFILE_INFO* pSimulatedInfo) SetSimulatedProfileInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearSimulatedProfileInfo;
	}


	public HRESULT GetNetworks(NLM_ENUM_NETWORK Flags, IEnumNetworks** ppEnumNetwork) mut => VT.[Friend]GetNetworks(&this, Flags, ppEnumNetwork);

	public HRESULT GetNetwork(Guid gdNetworkId, INetwork** ppNetwork) mut => VT.[Friend]GetNetwork(&this, gdNetworkId, ppNetwork);

	public HRESULT GetNetworkConnections(IEnumNetworkConnections** ppEnum) mut => VT.[Friend]GetNetworkConnections(&this, ppEnum);

	public HRESULT GetNetworkConnection(Guid gdNetworkConnectionId, INetworkConnection** ppNetworkConnection) mut => VT.[Friend]GetNetworkConnection(&this, gdNetworkConnectionId, ppNetworkConnection);

	public HRESULT get_IsConnectedToInternet(int16* pbIsConnected) mut => VT.[Friend]get_IsConnectedToInternet(&this, pbIsConnected);

	public HRESULT get_IsConnected(int16* pbIsConnected) mut => VT.[Friend]get_IsConnected(&this, pbIsConnected);

	public HRESULT GetConnectivity(NLM_CONNECTIVITY* pConnectivity) mut => VT.[Friend]GetConnectivity(&this, pConnectivity);

	public HRESULT SetSimulatedProfileInfo(NLM_SIMULATED_PROFILE_INFO* pSimulatedInfo) mut => VT.[Friend]SetSimulatedProfileInfo(&this, pSimulatedInfo);

	public HRESULT ClearSimulatedProfileInfo() mut => VT.[Friend]ClearSimulatedProfileInfo(&this);
}

[CRepr]struct INetworkListManagerEvents : IUnknown
{
	public new const Guid IID = .(0xdcb00001, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_CONNECTIVITY newConnectivity) ConnectivityChanged;
	}


	public HRESULT ConnectivityChanged(NLM_CONNECTIVITY newConnectivity) mut => VT.[Friend]ConnectivityChanged(&this, newConnectivity);
}

[CRepr]struct INetwork : IDispatch
{
	public new const Guid IID = .(0xdcb00002, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszNetworkName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szNetworkNewName) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szDescription) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pgdGuidNetworkId) GetNetworkId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_DOMAIN_TYPE* pNetworkType) GetDomainType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetworkConnections** ppEnumNetworkConnection) GetNetworkConnections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLowDateTimeCreated, uint32* pdwHighDateTimeCreated, uint32* pdwLowDateTimeConnected, uint32* pdwHighDateTimeConnected) GetTimeCreatedAndConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsConnected) get_IsConnectedToInternet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsConnected) get_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_CONNECTIVITY* pConnectivity) GetConnectivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_NETWORK_CATEGORY* pCategory) GetCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_NETWORK_CATEGORY NewCategory) SetCategory;
	}


	public HRESULT GetName(BSTR* pszNetworkName) mut => VT.[Friend]GetName(&this, pszNetworkName);

	public HRESULT SetName(BSTR szNetworkNewName) mut => VT.[Friend]SetName(&this, szNetworkNewName);

	public HRESULT GetDescription(BSTR* pszDescription) mut => VT.[Friend]GetDescription(&this, pszDescription);

	public HRESULT SetDescription(BSTR szDescription) mut => VT.[Friend]SetDescription(&this, szDescription);

	public HRESULT GetNetworkId(Guid* pgdGuidNetworkId) mut => VT.[Friend]GetNetworkId(&this, pgdGuidNetworkId);

	public HRESULT GetDomainType(NLM_DOMAIN_TYPE* pNetworkType) mut => VT.[Friend]GetDomainType(&this, pNetworkType);

	public HRESULT GetNetworkConnections(IEnumNetworkConnections** ppEnumNetworkConnection) mut => VT.[Friend]GetNetworkConnections(&this, ppEnumNetworkConnection);

	public HRESULT GetTimeCreatedAndConnected(uint32* pdwLowDateTimeCreated, uint32* pdwHighDateTimeCreated, uint32* pdwLowDateTimeConnected, uint32* pdwHighDateTimeConnected) mut => VT.[Friend]GetTimeCreatedAndConnected(&this, pdwLowDateTimeCreated, pdwHighDateTimeCreated, pdwLowDateTimeConnected, pdwHighDateTimeConnected);

	public HRESULT get_IsConnectedToInternet(int16* pbIsConnected) mut => VT.[Friend]get_IsConnectedToInternet(&this, pbIsConnected);

	public HRESULT get_IsConnected(int16* pbIsConnected) mut => VT.[Friend]get_IsConnected(&this, pbIsConnected);

	public HRESULT GetConnectivity(NLM_CONNECTIVITY* pConnectivity) mut => VT.[Friend]GetConnectivity(&this, pConnectivity);

	public HRESULT GetCategory(NLM_NETWORK_CATEGORY* pCategory) mut => VT.[Friend]GetCategory(&this, pCategory);

	public HRESULT SetCategory(NLM_NETWORK_CATEGORY NewCategory) mut => VT.[Friend]SetCategory(&this, NewCategory);
}

[CRepr]struct IEnumNetworks : IDispatch
{
	public new const Guid IID = .(0xdcb00003, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppEnumVar) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, INetwork** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetworks** ppEnumNetwork) Clone;
	}


	public HRESULT get__NewEnum(IEnumVARIANT** ppEnumVar) mut => VT.[Friend]get__NewEnum(&this, ppEnumVar);

	public HRESULT Next(uint32 celt, INetwork** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetworks** ppEnumNetwork) mut => VT.[Friend]Clone(&this, ppEnumNetwork);
}

[CRepr]struct INetworkEvents : IUnknown
{
	public new const Guid IID = .(0xdcb00004, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid networkId) NetworkAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid networkId) NetworkDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid networkId, NLM_CONNECTIVITY newConnectivity) NetworkConnectivityChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid networkId, NLM_NETWORK_PROPERTY_CHANGE flags) NetworkPropertyChanged;
	}


	public HRESULT NetworkAdded(Guid networkId) mut => VT.[Friend]NetworkAdded(&this, networkId);

	public HRESULT NetworkDeleted(Guid networkId) mut => VT.[Friend]NetworkDeleted(&this, networkId);

	public HRESULT NetworkConnectivityChanged(Guid networkId, NLM_CONNECTIVITY newConnectivity) mut => VT.[Friend]NetworkConnectivityChanged(&this, networkId, newConnectivity);

	public HRESULT NetworkPropertyChanged(Guid networkId, NLM_NETWORK_PROPERTY_CHANGE flags) mut => VT.[Friend]NetworkPropertyChanged(&this, networkId, flags);
}

[CRepr]struct INetworkConnection : IDispatch
{
	public new const Guid IID = .(0xdcb00005, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetwork** ppNetwork) GetNetwork;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsConnected) get_IsConnectedToInternet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsConnected) get_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_CONNECTIVITY* pConnectivity) GetConnectivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pgdConnectionId) GetConnectionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pgdAdapterId) GetAdapterId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_DOMAIN_TYPE* pDomainType) GetDomainType;
	}


	public HRESULT GetNetwork(INetwork** ppNetwork) mut => VT.[Friend]GetNetwork(&this, ppNetwork);

	public HRESULT get_IsConnectedToInternet(int16* pbIsConnected) mut => VT.[Friend]get_IsConnectedToInternet(&this, pbIsConnected);

	public HRESULT get_IsConnected(int16* pbIsConnected) mut => VT.[Friend]get_IsConnected(&this, pbIsConnected);

	public HRESULT GetConnectivity(NLM_CONNECTIVITY* pConnectivity) mut => VT.[Friend]GetConnectivity(&this, pConnectivity);

	public HRESULT GetConnectionId(Guid* pgdConnectionId) mut => VT.[Friend]GetConnectionId(&this, pgdConnectionId);

	public HRESULT GetAdapterId(Guid* pgdAdapterId) mut => VT.[Friend]GetAdapterId(&this, pgdAdapterId);

	public HRESULT GetDomainType(NLM_DOMAIN_TYPE* pDomainType) mut => VT.[Friend]GetDomainType(&this, pDomainType);
}

[CRepr]struct IEnumNetworkConnections : IDispatch
{
	public new const Guid IID = .(0xdcb00006, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppEnumVar) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, INetworkConnection** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetworkConnections** ppEnumNetwork) Clone;
	}


	public HRESULT get__NewEnum(IEnumVARIANT** ppEnumVar) mut => VT.[Friend]get__NewEnum(&this, ppEnumVar);

	public HRESULT Next(uint32 celt, INetworkConnection** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetworkConnections** ppEnumNetwork) mut => VT.[Friend]Clone(&this, ppEnumNetwork);
}

[CRepr]struct INetworkConnectionEvents : IUnknown
{
	public new const Guid IID = .(0xdcb00007, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid connectionId, NLM_CONNECTIVITY newConnectivity) NetworkConnectionConnectivityChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid connectionId, NLM_CONNECTION_PROPERTY_CHANGE flags) NetworkConnectionPropertyChanged;
	}


	public HRESULT NetworkConnectionConnectivityChanged(Guid connectionId, NLM_CONNECTIVITY newConnectivity) mut => VT.[Friend]NetworkConnectionConnectivityChanged(&this, connectionId, newConnectivity);

	public HRESULT NetworkConnectionPropertyChanged(Guid connectionId, NLM_CONNECTION_PROPERTY_CHANGE flags) mut => VT.[Friend]NetworkConnectionPropertyChanged(&this, connectionId, flags);
}

[CRepr]struct INetworkCostManager : IUnknown
{
	public new const Guid IID = .(0xdcb00008, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCost, NLM_SOCKADDR* pDestIPAddr) GetCost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_DATAPLAN_STATUS* pDataPlanStatus, NLM_SOCKADDR* pDestIPAddr) GetDataPlanStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 length, NLM_SOCKADDR* pDestIPAddrList, int16 bAppend) SetDestinationAddresses;
	}


	public HRESULT GetCost(uint32* pCost, NLM_SOCKADDR* pDestIPAddr) mut => VT.[Friend]GetCost(&this, pCost, pDestIPAddr);

	public HRESULT GetDataPlanStatus(NLM_DATAPLAN_STATUS* pDataPlanStatus, NLM_SOCKADDR* pDestIPAddr) mut => VT.[Friend]GetDataPlanStatus(&this, pDataPlanStatus, pDestIPAddr);

	public HRESULT SetDestinationAddresses(uint32 length, NLM_SOCKADDR* pDestIPAddrList, int16 bAppend) mut => VT.[Friend]SetDestinationAddresses(&this, length, pDestIPAddrList, bAppend);
}

[CRepr]struct INetworkCostManagerEvents : IUnknown
{
	public new const Guid IID = .(0xdcb00009, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 newCost, NLM_SOCKADDR* pDestAddr) CostChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_SOCKADDR* pDestAddr) DataPlanStatusChanged;
	}


	public HRESULT CostChanged(uint32 newCost, NLM_SOCKADDR* pDestAddr) mut => VT.[Friend]CostChanged(&this, newCost, pDestAddr);

	public HRESULT DataPlanStatusChanged(NLM_SOCKADDR* pDestAddr) mut => VT.[Friend]DataPlanStatusChanged(&this, pDestAddr);
}

[CRepr]struct INetworkConnectionCost : IUnknown
{
	public new const Guid IID = .(0xdcb0000a, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCost) GetCost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NLM_DATAPLAN_STATUS* pDataPlanStatus) GetDataPlanStatus;
	}


	public HRESULT GetCost(uint32* pCost) mut => VT.[Friend]GetCost(&this, pCost);

	public HRESULT GetDataPlanStatus(NLM_DATAPLAN_STATUS* pDataPlanStatus) mut => VT.[Friend]GetDataPlanStatus(&this, pDataPlanStatus);
}

[CRepr]struct INetworkConnectionCostEvents : IUnknown
{
	public new const Guid IID = .(0xdcb0000b, 0x570f, 0x4a9b, 0x8d, 0x69, 0x19, 0x9f, 0xdb, 0xa5, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid connectionId, uint32 newCost) ConnectionCostChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid connectionId) ConnectionDataPlanStatusChanged;
	}


	public HRESULT ConnectionCostChanged(Guid connectionId, uint32 newCost) mut => VT.[Friend]ConnectionCostChanged(&this, connectionId, newCost);

	public HRESULT ConnectionDataPlanStatusChanged(Guid connectionId) mut => VT.[Friend]ConnectionDataPlanStatusChanged(&this, connectionId);
}

#endregion
