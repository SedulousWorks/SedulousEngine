using Win32.Foundation;
using Win32.System.Com;
using Win32.Security;
using System;

namespace Win32.NetworkManagement.WindowsFirewall;

#region Constants
public static
{
	public const uint32 NETCON_MAX_NAME_LEN = 256;
	public const HRESULT S_OBJECT_NO_LONGER_VALID = 2;
	public const uint32 NETISO_GEID_FOR_WDAG = 1;
	public const uint32 NETISO_GEID_FOR_NEUTRAL_AWARE = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum NETCON_CHARACTERISTIC_FLAGS : int32
{
	NCCF_NONE = 0,
	NCCF_ALL_USERS = 1,
	NCCF_ALLOW_DUPLICATION = 2,
	NCCF_ALLOW_REMOVAL = 4,
	NCCF_ALLOW_RENAME = 8,
	NCCF_INCOMING_ONLY = 32,
	NCCF_OUTGOING_ONLY = 64,
	NCCF_BRANDED = 128,
	NCCF_SHARED = 256,
	NCCF_BRIDGED = 512,
	NCCF_FIREWALLED = 1024,
	NCCF_DEFAULT = 2048,
	NCCF_HOMENET_CAPABLE = 4096,
	NCCF_SHARED_PRIVATE = 8192,
	NCCF_QUARANTINED = 16384,
	NCCF_RESERVED = 32768,
	NCCF_HOSTED_NETWORK = 65536,
	NCCF_VIRTUAL_STATION = 131072,
	NCCF_WIFI_DIRECT = 262144,
	NCCF_BLUETOOTH_MASK = 983040,
	NCCF_LAN_MASK = 15728640,
}


[AllowDuplicates]
public enum NETCON_STATUS : int32
{
	NCS_DISCONNECTED = 0,
	NCS_CONNECTING = 1,
	NCS_CONNECTED = 2,
	NCS_DISCONNECTING = 3,
	NCS_HARDWARE_NOT_PRESENT = 4,
	NCS_HARDWARE_DISABLED = 5,
	NCS_HARDWARE_MALFUNCTION = 6,
	NCS_MEDIA_DISCONNECTED = 7,
	NCS_AUTHENTICATING = 8,
	NCS_AUTHENTICATION_SUCCEEDED = 9,
	NCS_AUTHENTICATION_FAILED = 10,
	NCS_INVALID_ADDRESS = 11,
	NCS_CREDENTIALS_REQUIRED = 12,
	NCS_ACTION_REQUIRED = 13,
	NCS_ACTION_REQUIRED_RETRY = 14,
	NCS_CONNECT_FAILED = 15,
}


[AllowDuplicates]
public enum NETCON_TYPE : int32
{
	NCT_DIRECT_CONNECT = 0,
	NCT_INBOUND = 1,
	NCT_INTERNET = 2,
	NCT_LAN = 3,
	NCT_PHONE = 4,
	NCT_TUNNEL = 5,
	NCT_BRIDGE = 6,
}


[AllowDuplicates]
public enum NETCON_MEDIATYPE : int32
{
	NCM_NONE = 0,
	NCM_DIRECT = 1,
	NCM_ISDN = 2,
	NCM_LAN = 3,
	NCM_PHONE = 4,
	NCM_TUNNEL = 5,
	NCM_PPPOE = 6,
	NCM_BRIDGE = 7,
	NCM_SHAREDACCESSHOST_LAN = 8,
	NCM_SHAREDACCESSHOST_RAS = 9,
}


[AllowDuplicates]
public enum NETCONMGR_ENUM_FLAGS : int32
{
	NCME_DEFAULT = 0,
	NCME_HIDDEN = 1,
}


[AllowDuplicates]
public enum NETCONUI_CONNECT_FLAGS : int32
{
	NCUC_DEFAULT = 0,
	NCUC_NO_UI = 1,
	NCUC_ENABLE_DISABLE = 2,
}


[AllowDuplicates]
public enum SHARINGCONNECTIONTYPE : int32
{
	ICSSHARINGTYPE_PUBLIC = 0,
	ICSSHARINGTYPE_PRIVATE = 1,
}


[AllowDuplicates]
public enum SHARINGCONNECTION_ENUM_FLAGS : int32
{
	ICSSC_DEFAULT = 0,
	ICSSC_ENABLED = 1,
}


[AllowDuplicates]
public enum ICS_TARGETTYPE : int32
{
	ICSTT_NAME = 0,
	ICSTT_IPADDRESS = 1,
}


[AllowDuplicates]
public enum NET_FW_POLICY_TYPE : int32
{
	NET_FW_POLICY_GROUP = 0,
	NET_FW_POLICY_LOCAL = 1,
	NET_FW_POLICY_EFFECTIVE = 2,
	NET_FW_POLICY_TYPE_MAX = 3,
}


[AllowDuplicates]
public enum NET_FW_PROFILE_TYPE : int32
{
	NET_FW_PROFILE_DOMAIN = 0,
	NET_FW_PROFILE_STANDARD = 1,
	NET_FW_PROFILE_CURRENT = 2,
	NET_FW_PROFILE_TYPE_MAX = 3,
}


[AllowDuplicates]
public enum NET_FW_PROFILE_TYPE2 : int32
{
	NET_FW_PROFILE2_DOMAIN = 1,
	NET_FW_PROFILE2_PRIVATE = 2,
	NET_FW_PROFILE2_PUBLIC = 4,
	NET_FW_PROFILE2_ALL = 2147483647,
}


[AllowDuplicates]
public enum NET_FW_IP_VERSION : int32
{
	NET_FW_IP_VERSION_V4 = 0,
	NET_FW_IP_VERSION_V6 = 1,
	NET_FW_IP_VERSION_ANY = 2,
	NET_FW_IP_VERSION_MAX = 3,
}


[AllowDuplicates]
public enum NET_FW_SCOPE : int32
{
	NET_FW_SCOPE_ALL = 0,
	NET_FW_SCOPE_LOCAL_SUBNET = 1,
	NET_FW_SCOPE_CUSTOM = 2,
	NET_FW_SCOPE_MAX = 3,
}


[AllowDuplicates]
public enum NET_FW_IP_PROTOCOL : int32
{
	NET_FW_IP_PROTOCOL_TCP = 6,
	NET_FW_IP_PROTOCOL_UDP = 17,
	NET_FW_IP_PROTOCOL_ANY = 256,
}


[AllowDuplicates]
public enum NET_FW_SERVICE_TYPE : int32
{
	NET_FW_SERVICE_FILE_AND_PRINT = 0,
	NET_FW_SERVICE_UPNP = 1,
	NET_FW_SERVICE_REMOTE_DESKTOP = 2,
	NET_FW_SERVICE_NONE = 3,
	NET_FW_SERVICE_TYPE_MAX = 4,
}


[AllowDuplicates]
public enum NET_FW_RULE_DIRECTION : int32
{
	NET_FW_RULE_DIR_IN = 1,
	NET_FW_RULE_DIR_OUT = 2,
	NET_FW_RULE_DIR_MAX = 3,
}


[AllowDuplicates]
public enum NET_FW_ACTION : int32
{
	NET_FW_ACTION_BLOCK = 0,
	NET_FW_ACTION_ALLOW = 1,
	NET_FW_ACTION_MAX = 2,
}


[AllowDuplicates]
public enum NET_FW_MODIFY_STATE : int32
{
	NET_FW_MODIFY_STATE_OK = 0,
	NET_FW_MODIFY_STATE_GP_OVERRIDE = 1,
	NET_FW_MODIFY_STATE_INBOUND_BLOCKED = 2,
}


[AllowDuplicates]
public enum NET_FW_RULE_CATEGORY : int32
{
	NET_FW_RULE_CATEGORY_BOOT = 0,
	NET_FW_RULE_CATEGORY_STEALTH = 1,
	NET_FW_RULE_CATEGORY_FIREWALL = 2,
	NET_FW_RULE_CATEGORY_CONSEC = 3,
	NET_FW_RULE_CATEGORY_MAX = 4,
}


[AllowDuplicates]
public enum NET_FW_EDGE_TRAVERSAL_TYPE : int32
{
	NET_FW_EDGE_TRAVERSAL_TYPE_DENY = 0,
	NET_FW_EDGE_TRAVERSAL_TYPE_ALLOW = 1,
	NET_FW_EDGE_TRAVERSAL_TYPE_DEFER_TO_APP = 2,
	NET_FW_EDGE_TRAVERSAL_TYPE_DEFER_TO_USER = 3,
}


[AllowDuplicates]
public enum NET_FW_AUTHENTICATE_TYPE : int32
{
	NET_FW_AUTHENTICATE_NONE = 0,
	NET_FW_AUTHENTICATE_NO_ENCAPSULATION = 1,
	NET_FW_AUTHENTICATE_WITH_INTEGRITY = 2,
	NET_FW_AUTHENTICATE_AND_NEGOTIATE_ENCRYPTION = 3,
	NET_FW_AUTHENTICATE_AND_ENCRYPT = 4,
}


[AllowDuplicates]
public enum NETISO_FLAG : int32
{
	NETISO_FLAG_FORCE_COMPUTE_BINARIES = 1,
	NETISO_FLAG_MAX = 2,
}


[AllowDuplicates]
public enum INET_FIREWALL_AC_CREATION_TYPE : int32
{
	INET_FIREWALL_AC_NONE = 0,
	INET_FIREWALL_AC_PACKAGE_ID_ONLY = 1,
	INET_FIREWALL_AC_BINARY = 2,
	INET_FIREWALL_AC_MAX = 4,
}


[AllowDuplicates]
public enum INET_FIREWALL_AC_CHANGE_TYPE : int32
{
	INET_FIREWALL_AC_CHANGE_INVALID = 0,
	INET_FIREWALL_AC_CHANGE_CREATE = 1,
	INET_FIREWALL_AC_CHANGE_DELETE = 2,
	INET_FIREWALL_AC_CHANGE_MAX = 3,
}


[AllowDuplicates]
public enum NETISO_ERROR_TYPE : int32
{
	NETISO_ERROR_TYPE_NONE = 0,
	NETISO_ERROR_TYPE_PRIVATE_NETWORK = 1,
	NETISO_ERROR_TYPE_INTERNET_CLIENT = 2,
	NETISO_ERROR_TYPE_INTERNET_CLIENT_SERVER = 3,
	NETISO_ERROR_TYPE_MAX = 4,
}


[AllowDuplicates]
public enum FW_DYNAMIC_KEYWORD_ORIGIN_TYPE : int32
{
	FW_DYNAMIC_KEYWORD_ORIGIN_INVALID = 0,
	FW_DYNAMIC_KEYWORD_ORIGIN_LOCAL = 1,
	FW_DYNAMIC_KEYWORD_ORIGIN_MDM = 2,
}


[AllowDuplicates]
public enum FW_DYNAMIC_KEYWORD_ADDRESS_FLAGS : uint32
{
	FW_DYNAMIC_KEYWORD_ADDRESS_FLAGS_AUTO_RESOLVE = 1,
}


[AllowDuplicates]
public enum FW_DYNAMIC_KEYWORD_ADDRESS_ENUM_FLAGS : uint32
{
	FW_DYNAMIC_KEYWORD_ADDRESS_ENUM_FLAGS_AUTO_RESOLVE = 1,
	FW_DYNAMIC_KEYWORD_ADDRESS_ENUM_FLAGS_NON_AUTO_RESOLVE = 2,
	FW_DYNAMIC_KEYWORD_ADDRESS_ENUM_FLAGS_ALL = 3,
}

#endregion

#region Function Pointers
public function void PAC_CHANGES_CALLBACK_FN(void* context, INET_FIREWALL_AC_CHANGE* pChange);

public function void PNETISO_EDP_ID_CALLBACK_FN(void* context, PWSTR wszEnterpriseId, uint32 dwErr);

public function uint32 PFN_FWADDDYNAMICKEYWORDADDRESS0(FW_DYNAMIC_KEYWORD_ADDRESS0* dynamicKeywordAddress);

public function uint32 PFN_FWDELETEDYNAMICKEYWORDADDRESS0(Guid dynamicKeywordAddressId);

public function uint32 PFN_FWENUMDYNAMICKEYWORDADDRESSESBYTYPE0(uint32 flags, FW_DYNAMIC_KEYWORD_ADDRESS_DATA0** dynamicKeywordAddressData);

public function uint32 PFN_FWENUMDYNAMICKEYWORDADDRESSBYID0(Guid dynamicKeywordAddressId, FW_DYNAMIC_KEYWORD_ADDRESS_DATA0** dynamicKeywordAddressData);

public function uint32 PFN_FWFREEDYNAMICKEYWORDADDRESSDATA0(FW_DYNAMIC_KEYWORD_ADDRESS_DATA0* dynamicKeywordAddressData);

public function uint32 PFN_FWUPDATEDYNAMICKEYWORDADDRESS0(Guid dynamicKeywordAddressId, PWSTR updatedAddresses, BOOL @append);

#endregion

#region Structs
[CRepr]
public struct NETCON_PROPERTIES
{
	public Guid guidId;
	public PWSTR pszwName;
	public PWSTR pszwDeviceName;
	public NETCON_STATUS Status;
	public NETCON_MEDIATYPE MediaType;
	public uint32 dwCharacter;
	public Guid clsidThisObject;
	public Guid clsidUiObject;
}

[CRepr]
public struct INET_FIREWALL_AC_CAPABILITIES
{
	public uint32 count;
	public SID_AND_ATTRIBUTES* capabilities;
}

[CRepr]
public struct INET_FIREWALL_AC_BINARIES
{
	public uint32 count;
	public PWSTR* binaries;
}

[CRepr]
public struct INET_FIREWALL_AC_CHANGE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public INET_FIREWALL_AC_CAPABILITIES capabilities;
		public INET_FIREWALL_AC_BINARIES binaries;
	}
	public INET_FIREWALL_AC_CHANGE_TYPE changeType;
	public INET_FIREWALL_AC_CREATION_TYPE createType;
	public SID* appContainerSid;
	public SID* userSid;
	public PWSTR displayName;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct INET_FIREWALL_APP_CONTAINER
{
	public SID* appContainerSid;
	public SID* userSid;
	public PWSTR appContainerName;
	public PWSTR displayName;
	public PWSTR description;
	public INET_FIREWALL_AC_CAPABILITIES capabilities;
	public INET_FIREWALL_AC_BINARIES binaries;
	public PWSTR workingDirectory;
	public PWSTR packageFullName;
}

[CRepr]
public struct FW_DYNAMIC_KEYWORD_ADDRESS0
{
	public Guid id;
	public PWSTR keyword;
	public uint32 flags;
	public PWSTR addresses;
}

[CRepr]
public struct FW_DYNAMIC_KEYWORD_ADDRESS_DATA0
{
	public FW_DYNAMIC_KEYWORD_ADDRESS0 dynamicKeywordAddress;
	public FW_DYNAMIC_KEYWORD_ADDRESS_DATA0* next;
	public uint16 schemaVersion;
	public FW_DYNAMIC_KEYWORD_ORIGIN_TYPE originType;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_UPnPNAT = .(0xae1e00aa, 0x3fd5, 0x403c, 0x8a, 0x27, 0x2b, 0xbd, 0xc3, 0x0c, 0xd0, 0xe1);


	public const Guid CLSID_NetSharingManager = .(0x5c63c1ad, 0x3956, 0x4ff8, 0x84, 0x86, 0x40, 0x03, 0x47, 0x58, 0x31, 0x5b);


	public const Guid CLSID_NetFwRule = .(0x2c5bc43e, 0x3369, 0x4c33, 0xab, 0x0c, 0xbe, 0x94, 0x69, 0x67, 0x7a, 0xf4);


	public const Guid CLSID_NetFwOpenPort = .(0x0ca545c6, 0x37ad, 0x4a6c, 0xbf, 0x92, 0x9f, 0x76, 0x10, 0x06, 0x7e, 0xf5);


	public const Guid CLSID_NetFwAuthorizedApplication = .(0xec9846b3, 0x2762, 0x4a6b, 0xa2, 0x14, 0x6a, 0xcb, 0x60, 0x34, 0x62, 0xd2);


	public const Guid CLSID_NetFwPolicy2 = .(0xe2b3c97f, 0x6ae1, 0x41ac, 0x81, 0x7a, 0xf6, 0xf9, 0x21, 0x66, 0xd7, 0xdd);


	public const Guid CLSID_NetFwProduct = .(0x9d745ed8, 0xc514, 0x4d1d, 0xbf, 0x42, 0x75, 0x1f, 0xed, 0x2d, 0x5a, 0xc7);


	public const Guid CLSID_NetFwProducts = .(0xcc19079b, 0x8272, 0x4d73, 0xbb, 0x70, 0xcd, 0xb5, 0x33, 0x52, 0x7b, 0x61);


	public const Guid CLSID_NetFwMgr = .(0x304ce942, 0x6e39, 0x40d8, 0x94, 0x3a, 0xb9, 0x13, 0xc4, 0x0c, 0x9c, 0xd4);


}
#endregion

#region COM Types
[CRepr]struct IUPnPNAT : IDispatch
{
	public new const Guid IID = .(0xb171c812, 0xcc76, 0x485a, 0x94, 0xd8, 0xb6, 0xb3, 0xa2, 0x79, 0x4e, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStaticPortMappingCollection** ppSPMs) get_StaticPortMappingCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDynamicPortMappingCollection** ppDPMs) get_DynamicPortMappingCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INATEventManager** ppNEM) get_NATEventManager;
	}


	public HRESULT get_StaticPortMappingCollection(IStaticPortMappingCollection** ppSPMs) mut => VT.[Friend]get_StaticPortMappingCollection(&this, ppSPMs);

	public HRESULT get_DynamicPortMappingCollection(IDynamicPortMappingCollection** ppDPMs) mut => VT.[Friend]get_DynamicPortMappingCollection(&this, ppDPMs);

	public HRESULT get_NATEventManager(INATEventManager** ppNEM) mut => VT.[Friend]get_NATEventManager(&this, ppNEM);
}

[CRepr]struct INATEventManager : IDispatch
{
	public new const Guid IID = .(0x624bd588, 0x9060, 0x4109, 0xb0, 0xb0, 0x1a, 0xdb, 0xbc, 0xac, 0x32, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnk) put_ExternalIPAddressCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnk) put_NumberOfEntriesCallback;
	}


	public HRESULT put_ExternalIPAddressCallback(IUnknown* pUnk) mut => VT.[Friend]put_ExternalIPAddressCallback(&this, pUnk);

	public HRESULT put_NumberOfEntriesCallback(IUnknown* pUnk) mut => VT.[Friend]put_NumberOfEntriesCallback(&this, pUnk);
}

[CRepr]struct INATExternalIPAddressCallback : IUnknown
{
	public new const Guid IID = .(0x9c416740, 0xa34e, 0x446f, 0xba, 0x06, 0xab, 0xd0, 0x4c, 0x31, 0x49, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNewExternalIPAddress) NewExternalIPAddress;
	}


	public HRESULT NewExternalIPAddress(BSTR bstrNewExternalIPAddress) mut => VT.[Friend]NewExternalIPAddress(&this, bstrNewExternalIPAddress);
}

[CRepr]struct INATNumberOfEntriesCallback : IUnknown
{
	public new const Guid IID = .(0xc83a0a74, 0x91ee, 0x41b6, 0xb6, 0x7a, 0x67, 0xe0, 0xf0, 0x0b, 0xbd, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lNewNumberOfEntries) NewNumberOfEntries;
	}


	public HRESULT NewNumberOfEntries(int32 lNewNumberOfEntries) mut => VT.[Friend]NewNumberOfEntries(&this, lNewNumberOfEntries);
}

[CRepr]struct IDynamicPortMappingCollection : IDispatch
{
	public new const Guid IID = .(0xb60de00f, 0x156e, 0x4e8d, 0x9e, 0xc1, 0x3a, 0x23, 0x42, 0xc1, 0x08, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRemoteHost, int32 lExternalPort, BSTR bstrProtocol, IDynamicPortMapping** ppDPM) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRemoteHost, int32 lExternalPort, BSTR bstrProtocol) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRemoteHost, int32 lExternalPort, BSTR bstrProtocol, int32 lInternalPort, BSTR bstrInternalClient, int16 bEnabled, BSTR bstrDescription, int32 lLeaseDuration, IDynamicPortMapping** ppDPM) Add;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Item(BSTR bstrRemoteHost, int32 lExternalPort, BSTR bstrProtocol, IDynamicPortMapping** ppDPM) mut => VT.[Friend]get_Item(&this, bstrRemoteHost, lExternalPort, bstrProtocol, ppDPM);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT Remove(BSTR bstrRemoteHost, int32 lExternalPort, BSTR bstrProtocol) mut => VT.[Friend]Remove(&this, bstrRemoteHost, lExternalPort, bstrProtocol);

	public HRESULT Add(BSTR bstrRemoteHost, int32 lExternalPort, BSTR bstrProtocol, int32 lInternalPort, BSTR bstrInternalClient, int16 bEnabled, BSTR bstrDescription, int32 lLeaseDuration, IDynamicPortMapping** ppDPM) mut => VT.[Friend]Add(&this, bstrRemoteHost, lExternalPort, bstrProtocol, lInternalPort, bstrInternalClient, bEnabled, bstrDescription, lLeaseDuration, ppDPM);
}

[CRepr]struct IDynamicPortMapping : IDispatch
{
	public new const Guid IID = .(0x4fc80282, 0x23b6, 0x4378, 0x9a, 0x27, 0xcd, 0x8f, 0x17, 0xc9, 0x40, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ExternalIPAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_RemoteHost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_ExternalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_InternalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_InternalClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_LeaseDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLeaseDurationDesired, int32* pLeaseDurationReturned) RenewLease;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInternalClient) EditInternalClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vb) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) EditDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lInternalPort) EditInternalPort;
	}


	public HRESULT get_ExternalIPAddress(BSTR* pVal) mut => VT.[Friend]get_ExternalIPAddress(&this, pVal);

	public HRESULT get_RemoteHost(BSTR* pVal) mut => VT.[Friend]get_RemoteHost(&this, pVal);

	public HRESULT get_ExternalPort(int32* pVal) mut => VT.[Friend]get_ExternalPort(&this, pVal);

	public HRESULT get_Protocol(BSTR* pVal) mut => VT.[Friend]get_Protocol(&this, pVal);

	public HRESULT get_InternalPort(int32* pVal) mut => VT.[Friend]get_InternalPort(&this, pVal);

	public HRESULT get_InternalClient(BSTR* pVal) mut => VT.[Friend]get_InternalClient(&this, pVal);

	public HRESULT get_Enabled(int16* pVal) mut => VT.[Friend]get_Enabled(&this, pVal);

	public HRESULT get_Description(BSTR* pVal) mut => VT.[Friend]get_Description(&this, pVal);

	public HRESULT get_LeaseDuration(int32* pVal) mut => VT.[Friend]get_LeaseDuration(&this, pVal);

	public HRESULT RenewLease(int32 lLeaseDurationDesired, int32* pLeaseDurationReturned) mut => VT.[Friend]RenewLease(&this, lLeaseDurationDesired, pLeaseDurationReturned);

	public HRESULT EditInternalClient(BSTR bstrInternalClient) mut => VT.[Friend]EditInternalClient(&this, bstrInternalClient);

	public HRESULT Enable(int16 vb) mut => VT.[Friend]Enable(&this, vb);

	public HRESULT EditDescription(BSTR bstrDescription) mut => VT.[Friend]EditDescription(&this, bstrDescription);

	public HRESULT EditInternalPort(int32 lInternalPort) mut => VT.[Friend]EditInternalPort(&this, lInternalPort);
}

[CRepr]struct IStaticPortMappingCollection : IDispatch
{
	public new const Guid IID = .(0xcd1f3e77, 0x66d6, 0x4664, 0x82, 0xc7, 0x36, 0xdb, 0xb6, 0x41, 0xd0, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lExternalPort, BSTR bstrProtocol, IStaticPortMapping** ppSPM) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lExternalPort, BSTR bstrProtocol) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lExternalPort, BSTR bstrProtocol, int32 lInternalPort, BSTR bstrInternalClient, int16 bEnabled, BSTR bstrDescription, IStaticPortMapping** ppSPM) Add;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Item(int32 lExternalPort, BSTR bstrProtocol, IStaticPortMapping** ppSPM) mut => VT.[Friend]get_Item(&this, lExternalPort, bstrProtocol, ppSPM);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT Remove(int32 lExternalPort, BSTR bstrProtocol) mut => VT.[Friend]Remove(&this, lExternalPort, bstrProtocol);

	public HRESULT Add(int32 lExternalPort, BSTR bstrProtocol, int32 lInternalPort, BSTR bstrInternalClient, int16 bEnabled, BSTR bstrDescription, IStaticPortMapping** ppSPM) mut => VT.[Friend]Add(&this, lExternalPort, bstrProtocol, lInternalPort, bstrInternalClient, bEnabled, bstrDescription, ppSPM);
}

[CRepr]struct IStaticPortMapping : IDispatch
{
	public new const Guid IID = .(0x6f10711f, 0x729b, 0x41e5, 0x93, 0xb8, 0xf2, 0x1d, 0x0f, 0x81, 0x8d, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ExternalIPAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_ExternalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_InternalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_InternalClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInternalClient) EditInternalClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vb) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) EditDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lInternalPort) EditInternalPort;
	}


	public HRESULT get_ExternalIPAddress(BSTR* pVal) mut => VT.[Friend]get_ExternalIPAddress(&this, pVal);

	public HRESULT get_ExternalPort(int32* pVal) mut => VT.[Friend]get_ExternalPort(&this, pVal);

	public HRESULT get_InternalPort(int32* pVal) mut => VT.[Friend]get_InternalPort(&this, pVal);

	public HRESULT get_Protocol(BSTR* pVal) mut => VT.[Friend]get_Protocol(&this, pVal);

	public HRESULT get_InternalClient(BSTR* pVal) mut => VT.[Friend]get_InternalClient(&this, pVal);

	public HRESULT get_Enabled(int16* pVal) mut => VT.[Friend]get_Enabled(&this, pVal);

	public HRESULT get_Description(BSTR* pVal) mut => VT.[Friend]get_Description(&this, pVal);

	public HRESULT EditInternalClient(BSTR bstrInternalClient) mut => VT.[Friend]EditInternalClient(&this, bstrInternalClient);

	public HRESULT Enable(int16 vb) mut => VT.[Friend]Enable(&this, vb);

	public HRESULT EditDescription(BSTR bstrDescription) mut => VT.[Friend]EditDescription(&this, bstrDescription);

	public HRESULT EditInternalPort(int32 lInternalPort) mut => VT.[Friend]EditInternalPort(&this, lInternalPort);
}

[CRepr]struct IEnumNetConnection : IUnknown
{
	public new const Guid IID = .(0xc08956a0, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, INetConnection** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetConnection** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, INetConnection** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetConnection** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct INetConnection : IUnknown
{
	public new const Guid IID = .(0xc08956a1, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwDuplicateName, INetConnection** ppCon) Duplicate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NETCON_PROPERTIES** ppProps) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetUiObjectClassId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwNewName) Rename;
	}


	public HRESULT Connect() mut => VT.[Friend]Connect(&this);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Duplicate(PWSTR pszwDuplicateName, INetConnection** ppCon) mut => VT.[Friend]Duplicate(&this, pszwDuplicateName, ppCon);

	public HRESULT GetProperties(NETCON_PROPERTIES** ppProps) mut => VT.[Friend]GetProperties(&this, ppProps);

	public HRESULT GetUiObjectClassId(Guid* pclsid) mut => VT.[Friend]GetUiObjectClassId(&this, pclsid);

	public HRESULT Rename(PWSTR pszwNewName) mut => VT.[Friend]Rename(&this, pszwNewName);
}

[CRepr]struct INetConnectionManager : IUnknown
{
	public new const Guid IID = .(0xc08956a2, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NETCONMGR_ENUM_FLAGS Flags, IEnumNetConnection** ppEnum) EnumConnections;
	}


	public HRESULT EnumConnections(NETCONMGR_ENUM_FLAGS Flags, IEnumNetConnection** ppEnum) mut => VT.[Friend]EnumConnections(&this, Flags, ppEnum);
}

[CRepr]struct INetConnectionConnectUi : IUnknown
{
	public new const Guid IID = .(0xc08956a3, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetConnection* pCon) SetConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint32 dwFlags) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint32 dwFlags) Disconnect;
	}


	public HRESULT SetConnection(INetConnection* pCon) mut => VT.[Friend]SetConnection(&this, pCon);

	public HRESULT Connect(HWND hwndParent, uint32 dwFlags) mut => VT.[Friend]Connect(&this, hwndParent, dwFlags);

	public HRESULT Disconnect(HWND hwndParent, uint32 dwFlags) mut => VT.[Friend]Disconnect(&this, hwndParent, dwFlags);
}

[CRepr]struct IEnumNetSharingPortMapping : IUnknown
{
	public new const Guid IID = .(0xc08956b0, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VARIANT* rgVar, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetSharingPortMapping** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, VARIANT* rgVar, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgVar, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetSharingPortMapping** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct INetSharingPortMappingProps : IDispatch
{
	public new const Guid IID = .(0x24b7e9b5, 0xe38f, 0x4685, 0x85, 0x1b, 0x00, 0x89, 0x2c, 0xf5, 0xf9, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pucIPProt) get_IPProtocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pusPort) get_ExternalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pusPort) get_InternalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwOptions) get_Options;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTargetName) get_TargetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTargetIPAddress) get_TargetIPAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbool) get_Enabled;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_IPProtocol(uint8* pucIPProt) mut => VT.[Friend]get_IPProtocol(&this, pucIPProt);

	public HRESULT get_ExternalPort(int32* pusPort) mut => VT.[Friend]get_ExternalPort(&this, pusPort);

	public HRESULT get_InternalPort(int32* pusPort) mut => VT.[Friend]get_InternalPort(&this, pusPort);

	public HRESULT get_Options(int32* pdwOptions) mut => VT.[Friend]get_Options(&this, pdwOptions);

	public HRESULT get_TargetName(BSTR* pbstrTargetName) mut => VT.[Friend]get_TargetName(&this, pbstrTargetName);

	public HRESULT get_TargetIPAddress(BSTR* pbstrTargetIPAddress) mut => VT.[Friend]get_TargetIPAddress(&this, pbstrTargetIPAddress);

	public HRESULT get_Enabled(int16* pbool) mut => VT.[Friend]get_Enabled(&this, pbool);
}

[CRepr]struct INetSharingPortMapping : IDispatch
{
	public new const Guid IID = .(0xc08956b1, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetSharingPortMappingProps** ppNSPMP) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT Disable() mut => VT.[Friend]Disable(&this);

	public HRESULT Enable() mut => VT.[Friend]Enable(&this);

	public HRESULT get_Properties(INetSharingPortMappingProps** ppNSPMP) mut => VT.[Friend]get_Properties(&this, ppNSPMP);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IEnumNetSharingEveryConnection : IUnknown
{
	public new const Guid IID = .(0xc08956b8, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VARIANT* rgVar, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetSharingEveryConnection** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, VARIANT* rgVar, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgVar, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetSharingEveryConnection** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumNetSharingPublicConnection : IUnknown
{
	public new const Guid IID = .(0xc08956b4, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VARIANT* rgVar, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetSharingPublicConnection** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, VARIANT* rgVar, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgVar, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetSharingPublicConnection** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumNetSharingPrivateConnection : IUnknown
{
	public new const Guid IID = .(0xc08956b5, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VARIANT* rgVar, uint32* pCeltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetSharingPrivateConnection** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, VARIANT* rgVar, uint32* pCeltFetched) mut => VT.[Friend]Next(&this, celt, rgVar, pCeltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetSharingPrivateConnection** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct INetSharingPortMappingCollection : IDispatch
{
	public new const Guid IID = .(0x02e4a2de, 0xda20, 0x4e34, 0x89, 0xc8, 0xac, 0x22, 0x27, 0x5a, 0x01, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);
}

[CRepr]struct INetConnectionProps : IDispatch
{
	public new const Guid IID = .(0xf4277c95, 0xce5b, 0x463d, 0x81, 0x67, 0x56, 0x62, 0xd9, 0xbc, 0xaa, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuid) get_Guid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceName) get_DeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NETCON_STATUS* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NETCON_MEDIATYPE* pMediaType) get_MediaType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) get_Characteristics;
	}


	public HRESULT get_Guid(BSTR* pbstrGuid) mut => VT.[Friend]get_Guid(&this, pbstrGuid);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_DeviceName(BSTR* pbstrDeviceName) mut => VT.[Friend]get_DeviceName(&this, pbstrDeviceName);

	public HRESULT get_Status(NETCON_STATUS* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_MediaType(NETCON_MEDIATYPE* pMediaType) mut => VT.[Friend]get_MediaType(&this, pMediaType);

	public HRESULT get_Characteristics(uint32* pdwFlags) mut => VT.[Friend]get_Characteristics(&this, pdwFlags);
}

[CRepr]struct INetSharingConfiguration : IDispatch
{
	public new const Guid IID = .(0xc08956b6, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_SharingEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHARINGCONNECTIONTYPE* pType) get_SharingConnectionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableSharing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHARINGCONNECTIONTYPE Type) EnableSharing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_InternetFirewallEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableInternetFirewall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableInternetFirewall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHARINGCONNECTION_ENUM_FLAGS Flags, INetSharingPortMappingCollection** ppColl) get_EnumPortMappings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, uint8 ucIPProtocol, uint16 usExternalPort, uint16 usInternalPort, uint32 dwOptions, BSTR bstrTargetNameOrIPAddress, ICS_TARGETTYPE eTargetType, INetSharingPortMapping** ppMapping) AddPortMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetSharingPortMapping* pMapping) RemovePortMapping;
	}


	public HRESULT get_SharingEnabled(int16* pbEnabled) mut => VT.[Friend]get_SharingEnabled(&this, pbEnabled);

	public HRESULT get_SharingConnectionType(SHARINGCONNECTIONTYPE* pType) mut => VT.[Friend]get_SharingConnectionType(&this, pType);

	public HRESULT DisableSharing() mut => VT.[Friend]DisableSharing(&this);

	public HRESULT EnableSharing(SHARINGCONNECTIONTYPE Type) mut => VT.[Friend]EnableSharing(&this, Type);

	public HRESULT get_InternetFirewallEnabled(int16* pbEnabled) mut => VT.[Friend]get_InternetFirewallEnabled(&this, pbEnabled);

	public HRESULT DisableInternetFirewall() mut => VT.[Friend]DisableInternetFirewall(&this);

	public HRESULT EnableInternetFirewall() mut => VT.[Friend]EnableInternetFirewall(&this);

	public HRESULT get_EnumPortMappings(SHARINGCONNECTION_ENUM_FLAGS Flags, INetSharingPortMappingCollection** ppColl) mut => VT.[Friend]get_EnumPortMappings(&this, Flags, ppColl);

	public HRESULT AddPortMapping(BSTR bstrName, uint8 ucIPProtocol, uint16 usExternalPort, uint16 usInternalPort, uint32 dwOptions, BSTR bstrTargetNameOrIPAddress, ICS_TARGETTYPE eTargetType, INetSharingPortMapping** ppMapping) mut => VT.[Friend]AddPortMapping(&this, bstrName, ucIPProtocol, usExternalPort, usInternalPort, dwOptions, bstrTargetNameOrIPAddress, eTargetType, ppMapping);

	public HRESULT RemovePortMapping(INetSharingPortMapping* pMapping) mut => VT.[Friend]RemovePortMapping(&this, pMapping);
}

[CRepr]struct INetSharingEveryConnectionCollection : IDispatch
{
	public new const Guid IID = .(0x33c4643c, 0x7811, 0x46fa, 0xa8, 0x9a, 0x76, 0x85, 0x97, 0xbd, 0x72, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);
}

[CRepr]struct INetSharingPublicConnectionCollection : IDispatch
{
	public new const Guid IID = .(0x7d7a6355, 0xf372, 0x4971, 0xa1, 0x49, 0xbf, 0xc9, 0x27, 0xbe, 0x76, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);
}

[CRepr]struct INetSharingPrivateConnectionCollection : IDispatch
{
	public new const Guid IID = .(0x38ae69e0, 0x4409, 0x402a, 0xa2, 0xcb, 0xe9, 0x65, 0xc7, 0x27, 0xf8, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);
}

[CRepr]struct INetSharingManager : IDispatch
{
	public new const Guid IID = .(0xc08956b7, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbInstalled) get_SharingInstalled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHARINGCONNECTION_ENUM_FLAGS Flags, INetSharingPublicConnectionCollection** ppColl) get_EnumPublicConnections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHARINGCONNECTION_ENUM_FLAGS Flags, INetSharingPrivateConnectionCollection** ppColl) get_EnumPrivateConnections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetConnection* pNetConnection, INetSharingConfiguration** ppNetSharingConfiguration) get_INetSharingConfigurationForINetConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetSharingEveryConnectionCollection** ppColl) get_EnumEveryConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetConnection* pNetConnection, INetConnectionProps** ppProps) get_NetConnectionProps;
	}


	public HRESULT get_SharingInstalled(int16* pbInstalled) mut => VT.[Friend]get_SharingInstalled(&this, pbInstalled);

	public HRESULT get_EnumPublicConnections(SHARINGCONNECTION_ENUM_FLAGS Flags, INetSharingPublicConnectionCollection** ppColl) mut => VT.[Friend]get_EnumPublicConnections(&this, Flags, ppColl);

	public HRESULT get_EnumPrivateConnections(SHARINGCONNECTION_ENUM_FLAGS Flags, INetSharingPrivateConnectionCollection** ppColl) mut => VT.[Friend]get_EnumPrivateConnections(&this, Flags, ppColl);

	public HRESULT get_INetSharingConfigurationForINetConnection(INetConnection* pNetConnection, INetSharingConfiguration** ppNetSharingConfiguration) mut => VT.[Friend]get_INetSharingConfigurationForINetConnection(&this, pNetConnection, ppNetSharingConfiguration);

	public HRESULT get_EnumEveryConnection(INetSharingEveryConnectionCollection** ppColl) mut => VT.[Friend]get_EnumEveryConnection(&this, ppColl);

	public HRESULT get_NetConnectionProps(INetConnection* pNetConnection, INetConnectionProps** ppProps) mut => VT.[Friend]get_NetConnectionProps(&this, pNetConnection, ppProps);
}

[CRepr]struct INetFwRemoteAdminSettings : IDispatch
{
	public new const Guid IID = .(0xd4becddf, 0x6f73, 0x4a83, 0xb8, 0x32, 0x9c, 0x66, 0x87, 0x4c, 0xd2, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION* ipVersion) get_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION ipVersion) put_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE* @scope) get_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE @scope) put_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* remoteAddrs) get_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR remoteAddrs) put_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
	}


	public HRESULT get_IpVersion(NET_FW_IP_VERSION* ipVersion) mut => VT.[Friend]get_IpVersion(&this, ipVersion);

	public HRESULT put_IpVersion(NET_FW_IP_VERSION ipVersion) mut => VT.[Friend]put_IpVersion(&this, ipVersion);

	public HRESULT get_Scope(NET_FW_SCOPE* @scope) mut => VT.[Friend]get_Scope(&this, @scope);

	public HRESULT put_Scope(NET_FW_SCOPE @scope) mut => VT.[Friend]put_Scope(&this, @scope);

	public HRESULT get_RemoteAddresses(BSTR* remoteAddrs) mut => VT.[Friend]get_RemoteAddresses(&this, remoteAddrs);

	public HRESULT put_RemoteAddresses(BSTR remoteAddrs) mut => VT.[Friend]put_RemoteAddresses(&this, remoteAddrs);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);
}

[CRepr]struct INetFwIcmpSettings : IDispatch
{
	public new const Guid IID = .(0xa6207b2e, 0x7cdd, 0x426a, 0x95, 0x1e, 0x5e, 0x1c, 0xbc, 0x5a, 0xfe, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowOutboundDestinationUnreachable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowOutboundDestinationUnreachable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowRedirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowRedirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowInboundEchoRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowInboundEchoRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowOutboundTimeExceeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowOutboundTimeExceeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowOutboundParameterProblem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowOutboundParameterProblem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowOutboundSourceQuench;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowOutboundSourceQuench;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowInboundRouterRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowInboundRouterRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowInboundTimestampRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowInboundTimestampRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowInboundMaskRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowInboundMaskRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* allow) get_AllowOutboundPacketTooBig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 allow) put_AllowOutboundPacketTooBig;
	}


	public HRESULT get_AllowOutboundDestinationUnreachable(int16* allow) mut => VT.[Friend]get_AllowOutboundDestinationUnreachable(&this, allow);

	public HRESULT put_AllowOutboundDestinationUnreachable(int16 allow) mut => VT.[Friend]put_AllowOutboundDestinationUnreachable(&this, allow);

	public HRESULT get_AllowRedirect(int16* allow) mut => VT.[Friend]get_AllowRedirect(&this, allow);

	public HRESULT put_AllowRedirect(int16 allow) mut => VT.[Friend]put_AllowRedirect(&this, allow);

	public HRESULT get_AllowInboundEchoRequest(int16* allow) mut => VT.[Friend]get_AllowInboundEchoRequest(&this, allow);

	public HRESULT put_AllowInboundEchoRequest(int16 allow) mut => VT.[Friend]put_AllowInboundEchoRequest(&this, allow);

	public HRESULT get_AllowOutboundTimeExceeded(int16* allow) mut => VT.[Friend]get_AllowOutboundTimeExceeded(&this, allow);

	public HRESULT put_AllowOutboundTimeExceeded(int16 allow) mut => VT.[Friend]put_AllowOutboundTimeExceeded(&this, allow);

	public HRESULT get_AllowOutboundParameterProblem(int16* allow) mut => VT.[Friend]get_AllowOutboundParameterProblem(&this, allow);

	public HRESULT put_AllowOutboundParameterProblem(int16 allow) mut => VT.[Friend]put_AllowOutboundParameterProblem(&this, allow);

	public HRESULT get_AllowOutboundSourceQuench(int16* allow) mut => VT.[Friend]get_AllowOutboundSourceQuench(&this, allow);

	public HRESULT put_AllowOutboundSourceQuench(int16 allow) mut => VT.[Friend]put_AllowOutboundSourceQuench(&this, allow);

	public HRESULT get_AllowInboundRouterRequest(int16* allow) mut => VT.[Friend]get_AllowInboundRouterRequest(&this, allow);

	public HRESULT put_AllowInboundRouterRequest(int16 allow) mut => VT.[Friend]put_AllowInboundRouterRequest(&this, allow);

	public HRESULT get_AllowInboundTimestampRequest(int16* allow) mut => VT.[Friend]get_AllowInboundTimestampRequest(&this, allow);

	public HRESULT put_AllowInboundTimestampRequest(int16 allow) mut => VT.[Friend]put_AllowInboundTimestampRequest(&this, allow);

	public HRESULT get_AllowInboundMaskRequest(int16* allow) mut => VT.[Friend]get_AllowInboundMaskRequest(&this, allow);

	public HRESULT put_AllowInboundMaskRequest(int16 allow) mut => VT.[Friend]put_AllowInboundMaskRequest(&this, allow);

	public HRESULT get_AllowOutboundPacketTooBig(int16* allow) mut => VT.[Friend]get_AllowOutboundPacketTooBig(&this, allow);

	public HRESULT put_AllowOutboundPacketTooBig(int16 allow) mut => VT.[Friend]put_AllowOutboundPacketTooBig(&this, allow);
}

[CRepr]struct INetFwOpenPort : IDispatch
{
	public new const Guid IID = .(0xe0483ba0, 0x47ff, 0x4d9c, 0xa6, 0xd6, 0x77, 0x41, 0xd0, 0xb1, 0x95, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION* ipVersion) get_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION ipVersion) put_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_PROTOCOL* ipProtocol) get_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_PROTOCOL ipProtocol) put_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* portNumber) get_Port;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 portNumber) put_Port;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE* @scope) get_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE @scope) put_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* remoteAddrs) get_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR remoteAddrs) put_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* builtIn) get_BuiltIn;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_IpVersion(NET_FW_IP_VERSION* ipVersion) mut => VT.[Friend]get_IpVersion(&this, ipVersion);

	public HRESULT put_IpVersion(NET_FW_IP_VERSION ipVersion) mut => VT.[Friend]put_IpVersion(&this, ipVersion);

	public HRESULT get_Protocol(NET_FW_IP_PROTOCOL* ipProtocol) mut => VT.[Friend]get_Protocol(&this, ipProtocol);

	public HRESULT put_Protocol(NET_FW_IP_PROTOCOL ipProtocol) mut => VT.[Friend]put_Protocol(&this, ipProtocol);

	public HRESULT get_Port(int32* portNumber) mut => VT.[Friend]get_Port(&this, portNumber);

	public HRESULT put_Port(int32 portNumber) mut => VT.[Friend]put_Port(&this, portNumber);

	public HRESULT get_Scope(NET_FW_SCOPE* @scope) mut => VT.[Friend]get_Scope(&this, @scope);

	public HRESULT put_Scope(NET_FW_SCOPE @scope) mut => VT.[Friend]put_Scope(&this, @scope);

	public HRESULT get_RemoteAddresses(BSTR* remoteAddrs) mut => VT.[Friend]get_RemoteAddresses(&this, remoteAddrs);

	public HRESULT put_RemoteAddresses(BSTR remoteAddrs) mut => VT.[Friend]put_RemoteAddresses(&this, remoteAddrs);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_BuiltIn(int16* builtIn) mut => VT.[Friend]get_BuiltIn(&this, builtIn);
}

[CRepr]struct INetFwOpenPorts : IDispatch
{
	public new const Guid IID = .(0xc0e9d7fa, 0xe07e, 0x430a, 0xb1, 0x9a, 0x09, 0x0c, 0xe8, 0x2d, 0x92, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwOpenPort* port) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 portNumber, NET_FW_IP_PROTOCOL ipProtocol) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 portNumber, NET_FW_IP_PROTOCOL ipProtocol, INetFwOpenPort** openPort) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** newEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT Add(INetFwOpenPort* port) mut => VT.[Friend]Add(&this, port);

	public HRESULT Remove(int32 portNumber, NET_FW_IP_PROTOCOL ipProtocol) mut => VT.[Friend]Remove(&this, portNumber, ipProtocol);

	public HRESULT Item(int32 portNumber, NET_FW_IP_PROTOCOL ipProtocol, INetFwOpenPort** openPort) mut => VT.[Friend]Item(&this, portNumber, ipProtocol, openPort);

	public HRESULT get__NewEnum(IUnknown** newEnum) mut => VT.[Friend]get__NewEnum(&this, newEnum);
}

[CRepr]struct INetFwService : IDispatch
{
	public new const Guid IID = .(0x79fd57c8, 0x908e, 0x4a36, 0x98, 0x88, 0xd5, 0xb3, 0xf0, 0xa4, 0x44, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SERVICE_TYPE* type) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* customized) get_Customized;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION* ipVersion) get_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION ipVersion) put_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE* @scope) get_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE @scope) put_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* remoteAddrs) get_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR remoteAddrs) put_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwOpenPorts** openPorts) get_GloballyOpenPorts;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT get_Type(NET_FW_SERVICE_TYPE* type) mut => VT.[Friend]get_Type(&this, type);

	public HRESULT get_Customized(int16* customized) mut => VT.[Friend]get_Customized(&this, customized);

	public HRESULT get_IpVersion(NET_FW_IP_VERSION* ipVersion) mut => VT.[Friend]get_IpVersion(&this, ipVersion);

	public HRESULT put_IpVersion(NET_FW_IP_VERSION ipVersion) mut => VT.[Friend]put_IpVersion(&this, ipVersion);

	public HRESULT get_Scope(NET_FW_SCOPE* @scope) mut => VT.[Friend]get_Scope(&this, @scope);

	public HRESULT put_Scope(NET_FW_SCOPE @scope) mut => VT.[Friend]put_Scope(&this, @scope);

	public HRESULT get_RemoteAddresses(BSTR* remoteAddrs) mut => VT.[Friend]get_RemoteAddresses(&this, remoteAddrs);

	public HRESULT put_RemoteAddresses(BSTR remoteAddrs) mut => VT.[Friend]put_RemoteAddresses(&this, remoteAddrs);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_GloballyOpenPorts(INetFwOpenPorts** openPorts) mut => VT.[Friend]get_GloballyOpenPorts(&this, openPorts);
}

[CRepr]struct INetFwServices : IDispatch
{
	public new const Guid IID = .(0x79649bb4, 0x903e, 0x421b, 0x94, 0xc9, 0x79, 0x84, 0x8e, 0x79, 0xf6, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SERVICE_TYPE svcType, INetFwService** service) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** newEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT Item(NET_FW_SERVICE_TYPE svcType, INetFwService** service) mut => VT.[Friend]Item(&this, svcType, service);

	public HRESULT get__NewEnum(IUnknown** newEnum) mut => VT.[Friend]get__NewEnum(&this, newEnum);
}

[CRepr]struct INetFwAuthorizedApplication : IDispatch
{
	public new const Guid IID = .(0xb5e64ffa, 0xc2c5, 0x444e, 0xa3, 0x01, 0xfb, 0x5e, 0x00, 0x01, 0x80, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* imageFileName) get_ProcessImageFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR imageFileName) put_ProcessImageFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION* ipVersion) get_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION ipVersion) put_IpVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE* @scope) get_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_SCOPE @scope) put_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* remoteAddrs) get_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR remoteAddrs) put_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_ProcessImageFileName(BSTR* imageFileName) mut => VT.[Friend]get_ProcessImageFileName(&this, imageFileName);

	public HRESULT put_ProcessImageFileName(BSTR imageFileName) mut => VT.[Friend]put_ProcessImageFileName(&this, imageFileName);

	public HRESULT get_IpVersion(NET_FW_IP_VERSION* ipVersion) mut => VT.[Friend]get_IpVersion(&this, ipVersion);

	public HRESULT put_IpVersion(NET_FW_IP_VERSION ipVersion) mut => VT.[Friend]put_IpVersion(&this, ipVersion);

	public HRESULT get_Scope(NET_FW_SCOPE* @scope) mut => VT.[Friend]get_Scope(&this, @scope);

	public HRESULT put_Scope(NET_FW_SCOPE @scope) mut => VT.[Friend]put_Scope(&this, @scope);

	public HRESULT get_RemoteAddresses(BSTR* remoteAddrs) mut => VT.[Friend]get_RemoteAddresses(&this, remoteAddrs);

	public HRESULT put_RemoteAddresses(BSTR remoteAddrs) mut => VT.[Friend]put_RemoteAddresses(&this, remoteAddrs);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);
}

[CRepr]struct INetFwAuthorizedApplications : IDispatch
{
	public new const Guid IID = .(0x644efd52, 0xccf9, 0x486c, 0x97, 0xa2, 0x39, 0xf3, 0x52, 0x57, 0x0b, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwAuthorizedApplication* app) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR imageFileName) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR imageFileName, INetFwAuthorizedApplication** app) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** newEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT Add(INetFwAuthorizedApplication* app) mut => VT.[Friend]Add(&this, app);

	public HRESULT Remove(BSTR imageFileName) mut => VT.[Friend]Remove(&this, imageFileName);

	public HRESULT Item(BSTR imageFileName, INetFwAuthorizedApplication** app) mut => VT.[Friend]Item(&this, imageFileName, app);

	public HRESULT get__NewEnum(IUnknown** newEnum) mut => VT.[Friend]get__NewEnum(&this, newEnum);
}

[CRepr]struct INetFwRule : IDispatch
{
	public new const Guid IID = .(0xaf230d27, 0xbaba, 0x4e42, 0xac, 0xed, 0xf5, 0x24, 0xf2, 0x2c, 0xfc, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* desc) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR desc) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* imageFileName) get_ApplicationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR imageFileName) put_ApplicationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* serviceName) get_ServiceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serviceName) put_ServiceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* protocol) get_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 protocol) put_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* portNumbers) get_LocalPorts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR portNumbers) put_LocalPorts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* portNumbers) get_RemotePorts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR portNumbers) put_RemotePorts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* localAddrs) get_LocalAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR localAddrs) put_LocalAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* remoteAddrs) get_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR remoteAddrs) put_RemoteAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* icmpTypesAndCodes) get_IcmpTypesAndCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR icmpTypesAndCodes) put_IcmpTypesAndCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_RULE_DIRECTION* dir) get_Direction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_RULE_DIRECTION dir) put_Direction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* interfaces) get_Interfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT interfaces) put_Interfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* interfaceTypes) get_InterfaceTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR interfaceTypes) put_InterfaceTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* context) get_Grouping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR context) put_Grouping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* profileTypesBitmask) get_Profiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 profileTypesBitmask) put_Profiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_EdgeTraversal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_EdgeTraversal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_ACTION* action) get_Action;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_ACTION action) put_Action;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Description(BSTR* desc) mut => VT.[Friend]get_Description(&this, desc);

	public HRESULT put_Description(BSTR desc) mut => VT.[Friend]put_Description(&this, desc);

	public HRESULT get_ApplicationName(BSTR* imageFileName) mut => VT.[Friend]get_ApplicationName(&this, imageFileName);

	public HRESULT put_ApplicationName(BSTR imageFileName) mut => VT.[Friend]put_ApplicationName(&this, imageFileName);

	public HRESULT get_ServiceName(BSTR* serviceName) mut => VT.[Friend]get_ServiceName(&this, serviceName);

	public HRESULT put_ServiceName(BSTR serviceName) mut => VT.[Friend]put_ServiceName(&this, serviceName);

	public HRESULT get_Protocol(int32* protocol) mut => VT.[Friend]get_Protocol(&this, protocol);

	public HRESULT put_Protocol(int32 protocol) mut => VT.[Friend]put_Protocol(&this, protocol);

	public HRESULT get_LocalPorts(BSTR* portNumbers) mut => VT.[Friend]get_LocalPorts(&this, portNumbers);

	public HRESULT put_LocalPorts(BSTR portNumbers) mut => VT.[Friend]put_LocalPorts(&this, portNumbers);

	public HRESULT get_RemotePorts(BSTR* portNumbers) mut => VT.[Friend]get_RemotePorts(&this, portNumbers);

	public HRESULT put_RemotePorts(BSTR portNumbers) mut => VT.[Friend]put_RemotePorts(&this, portNumbers);

	public HRESULT get_LocalAddresses(BSTR* localAddrs) mut => VT.[Friend]get_LocalAddresses(&this, localAddrs);

	public HRESULT put_LocalAddresses(BSTR localAddrs) mut => VT.[Friend]put_LocalAddresses(&this, localAddrs);

	public HRESULT get_RemoteAddresses(BSTR* remoteAddrs) mut => VT.[Friend]get_RemoteAddresses(&this, remoteAddrs);

	public HRESULT put_RemoteAddresses(BSTR remoteAddrs) mut => VT.[Friend]put_RemoteAddresses(&this, remoteAddrs);

	public HRESULT get_IcmpTypesAndCodes(BSTR* icmpTypesAndCodes) mut => VT.[Friend]get_IcmpTypesAndCodes(&this, icmpTypesAndCodes);

	public HRESULT put_IcmpTypesAndCodes(BSTR icmpTypesAndCodes) mut => VT.[Friend]put_IcmpTypesAndCodes(&this, icmpTypesAndCodes);

	public HRESULT get_Direction(NET_FW_RULE_DIRECTION* dir) mut => VT.[Friend]get_Direction(&this, dir);

	public HRESULT put_Direction(NET_FW_RULE_DIRECTION dir) mut => VT.[Friend]put_Direction(&this, dir);

	public HRESULT get_Interfaces(VARIANT* interfaces) mut => VT.[Friend]get_Interfaces(&this, interfaces);

	public HRESULT put_Interfaces(VARIANT interfaces) mut => VT.[Friend]put_Interfaces(&this, interfaces);

	public HRESULT get_InterfaceTypes(BSTR* interfaceTypes) mut => VT.[Friend]get_InterfaceTypes(&this, interfaceTypes);

	public HRESULT put_InterfaceTypes(BSTR interfaceTypes) mut => VT.[Friend]put_InterfaceTypes(&this, interfaceTypes);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_Grouping(BSTR* context) mut => VT.[Friend]get_Grouping(&this, context);

	public HRESULT put_Grouping(BSTR context) mut => VT.[Friend]put_Grouping(&this, context);

	public HRESULT get_Profiles(int32* profileTypesBitmask) mut => VT.[Friend]get_Profiles(&this, profileTypesBitmask);

	public HRESULT put_Profiles(int32 profileTypesBitmask) mut => VT.[Friend]put_Profiles(&this, profileTypesBitmask);

	public HRESULT get_EdgeTraversal(int16* enabled) mut => VT.[Friend]get_EdgeTraversal(&this, enabled);

	public HRESULT put_EdgeTraversal(int16 enabled) mut => VT.[Friend]put_EdgeTraversal(&this, enabled);

	public HRESULT get_Action(NET_FW_ACTION* action) mut => VT.[Friend]get_Action(&this, action);

	public HRESULT put_Action(NET_FW_ACTION action) mut => VT.[Friend]put_Action(&this, action);
}

[CRepr]struct INetFwRule2 : INetFwRule
{
	public new const Guid IID = .(0x9c27c8da, 0x189b, 0x4dde, 0x89, 0xf7, 0x8b, 0x39, 0xa3, 0x16, 0x78, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INetFwRule.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lOptions) get_EdgeTraversalOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lOptions) put_EdgeTraversalOptions;
	}


	public HRESULT get_EdgeTraversalOptions(int32* lOptions) mut => VT.[Friend]get_EdgeTraversalOptions(&this, lOptions);

	public HRESULT put_EdgeTraversalOptions(int32 lOptions) mut => VT.[Friend]put_EdgeTraversalOptions(&this, lOptions);
}

[CRepr]struct INetFwRule3 : INetFwRule2
{
	public new const Guid IID = .(0xb21563ff, 0xd696, 0x4222, 0xab, 0x46, 0x4e, 0x89, 0xb7, 0x3a, 0xb3, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INetFwRule2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* wszPackageId) get_LocalAppPackageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszPackageId) put_LocalAppPackageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* wszUserOwner) get_LocalUserOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszUserOwner) put_LocalUserOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* wszUserAuthList) get_LocalUserAuthorizedList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszUserAuthList) put_LocalUserAuthorizedList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* wszUserAuthList) get_RemoteUserAuthorizedList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszUserAuthList) put_RemoteUserAuthorizedList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* wszUserAuthList) get_RemoteMachineAuthorizedList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszUserAuthList) put_RemoteMachineAuthorizedList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lOptions) get_SecureFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lOptions) put_SecureFlags;
	}


	public HRESULT get_LocalAppPackageId(BSTR* wszPackageId) mut => VT.[Friend]get_LocalAppPackageId(&this, wszPackageId);

	public HRESULT put_LocalAppPackageId(BSTR wszPackageId) mut => VT.[Friend]put_LocalAppPackageId(&this, wszPackageId);

	public HRESULT get_LocalUserOwner(BSTR* wszUserOwner) mut => VT.[Friend]get_LocalUserOwner(&this, wszUserOwner);

	public HRESULT put_LocalUserOwner(BSTR wszUserOwner) mut => VT.[Friend]put_LocalUserOwner(&this, wszUserOwner);

	public HRESULT get_LocalUserAuthorizedList(BSTR* wszUserAuthList) mut => VT.[Friend]get_LocalUserAuthorizedList(&this, wszUserAuthList);

	public HRESULT put_LocalUserAuthorizedList(BSTR wszUserAuthList) mut => VT.[Friend]put_LocalUserAuthorizedList(&this, wszUserAuthList);

	public HRESULT get_RemoteUserAuthorizedList(BSTR* wszUserAuthList) mut => VT.[Friend]get_RemoteUserAuthorizedList(&this, wszUserAuthList);

	public HRESULT put_RemoteUserAuthorizedList(BSTR wszUserAuthList) mut => VT.[Friend]put_RemoteUserAuthorizedList(&this, wszUserAuthList);

	public HRESULT get_RemoteMachineAuthorizedList(BSTR* wszUserAuthList) mut => VT.[Friend]get_RemoteMachineAuthorizedList(&this, wszUserAuthList);

	public HRESULT put_RemoteMachineAuthorizedList(BSTR wszUserAuthList) mut => VT.[Friend]put_RemoteMachineAuthorizedList(&this, wszUserAuthList);

	public HRESULT get_SecureFlags(int32* lOptions) mut => VT.[Friend]get_SecureFlags(&this, lOptions);

	public HRESULT put_SecureFlags(int32 lOptions) mut => VT.[Friend]put_SecureFlags(&this, lOptions);
}

[CRepr]struct INetFwRules : IDispatch
{
	public new const Guid IID = .(0x9c4c6277, 0x5027, 0x441e, 0xaf, 0xae, 0xca, 0x1f, 0x54, 0x2d, 0xa0, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwRule* rule) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, INetFwRule** rule) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** newEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT Add(INetFwRule* rule) mut => VT.[Friend]Add(&this, rule);

	public HRESULT Remove(BSTR name) mut => VT.[Friend]Remove(&this, name);

	public HRESULT Item(BSTR name, INetFwRule** rule) mut => VT.[Friend]Item(&this, name, rule);

	public HRESULT get__NewEnum(IUnknown** newEnum) mut => VT.[Friend]get__NewEnum(&this, newEnum);
}

[CRepr]struct INetFwServiceRestriction : IDispatch
{
	public new const Guid IID = .(0x8267bbe3, 0xf890, 0x491c, 0xb7, 0xb6, 0x2d, 0xb1, 0xef, 0x0e, 0x5d, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serviceName, BSTR appName, int16 restrictService, int16 serviceSidRestricted) RestrictService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serviceName, BSTR appName, int16* serviceRestricted) ServiceRestricted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwRules** rules) get_Rules;
	}


	public HRESULT RestrictService(BSTR serviceName, BSTR appName, int16 restrictService, int16 serviceSidRestricted) mut => VT.[Friend]RestrictService(&this, serviceName, appName, restrictService, serviceSidRestricted);

	public HRESULT ServiceRestricted(BSTR serviceName, BSTR appName, int16* serviceRestricted) mut => VT.[Friend]ServiceRestricted(&this, serviceName, appName, serviceRestricted);

	public HRESULT get_Rules(INetFwRules** rules) mut => VT.[Friend]get_Rules(&this, rules);
}

[CRepr]struct INetFwProfile : IDispatch
{
	public new const Guid IID = .(0x174a0dda, 0xe9f9, 0x449d, 0x99, 0x3b, 0x21, 0xab, 0x66, 0x7c, 0xa4, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE* type) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_FirewallEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_FirewallEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* notAllowed) get_ExceptionsNotAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 notAllowed) put_ExceptionsNotAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* disabled) get_NotificationsDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 disabled) put_NotificationsDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* disabled) get_UnicastResponsesToMulticastBroadcastDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 disabled) put_UnicastResponsesToMulticastBroadcastDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwRemoteAdminSettings** remoteAdminSettings) get_RemoteAdminSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwIcmpSettings** icmpSettings) get_IcmpSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwOpenPorts** openPorts) get_GloballyOpenPorts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwServices** services) get_Services;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwAuthorizedApplications** apps) get_AuthorizedApplications;
	}


	public HRESULT get_Type(NET_FW_PROFILE_TYPE* type) mut => VT.[Friend]get_Type(&this, type);

	public HRESULT get_FirewallEnabled(int16* enabled) mut => VT.[Friend]get_FirewallEnabled(&this, enabled);

	public HRESULT put_FirewallEnabled(int16 enabled) mut => VT.[Friend]put_FirewallEnabled(&this, enabled);

	public HRESULT get_ExceptionsNotAllowed(int16* notAllowed) mut => VT.[Friend]get_ExceptionsNotAllowed(&this, notAllowed);

	public HRESULT put_ExceptionsNotAllowed(int16 notAllowed) mut => VT.[Friend]put_ExceptionsNotAllowed(&this, notAllowed);

	public HRESULT get_NotificationsDisabled(int16* disabled) mut => VT.[Friend]get_NotificationsDisabled(&this, disabled);

	public HRESULT put_NotificationsDisabled(int16 disabled) mut => VT.[Friend]put_NotificationsDisabled(&this, disabled);

	public HRESULT get_UnicastResponsesToMulticastBroadcastDisabled(int16* disabled) mut => VT.[Friend]get_UnicastResponsesToMulticastBroadcastDisabled(&this, disabled);

	public HRESULT put_UnicastResponsesToMulticastBroadcastDisabled(int16 disabled) mut => VT.[Friend]put_UnicastResponsesToMulticastBroadcastDisabled(&this, disabled);

	public HRESULT get_RemoteAdminSettings(INetFwRemoteAdminSettings** remoteAdminSettings) mut => VT.[Friend]get_RemoteAdminSettings(&this, remoteAdminSettings);

	public HRESULT get_IcmpSettings(INetFwIcmpSettings** icmpSettings) mut => VT.[Friend]get_IcmpSettings(&this, icmpSettings);

	public HRESULT get_GloballyOpenPorts(INetFwOpenPorts** openPorts) mut => VT.[Friend]get_GloballyOpenPorts(&this, openPorts);

	public HRESULT get_Services(INetFwServices** services) mut => VT.[Friend]get_Services(&this, services);

	public HRESULT get_AuthorizedApplications(INetFwAuthorizedApplications** apps) mut => VT.[Friend]get_AuthorizedApplications(&this, apps);
}

[CRepr]struct INetFwPolicy : IDispatch
{
	public new const Guid IID = .(0xd46d2478, 0x9ac9, 0x4008, 0x9d, 0xc7, 0x55, 0x63, 0xce, 0x55, 0x36, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwProfile** profile) get_CurrentProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE profileType, INetFwProfile** profile) GetProfileByType;
	}


	public HRESULT get_CurrentProfile(INetFwProfile** profile) mut => VT.[Friend]get_CurrentProfile(&this, profile);

	public HRESULT GetProfileByType(NET_FW_PROFILE_TYPE profileType, INetFwProfile** profile) mut => VT.[Friend]GetProfileByType(&this, profileType, profile);
}

[CRepr]struct INetFwPolicy2 : IDispatch
{
	public new const Guid IID = .(0x98325047, 0xc671, 0x4174, 0x8d, 0x81, 0xde, 0xfc, 0xd3, 0xf0, 0x31, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* profileTypesBitmask) get_CurrentProfileTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16* enabled) get_FirewallEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16 enabled) put_FirewallEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, VARIANT* interfaces) get_ExcludedInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, VARIANT interfaces) put_ExcludedInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16* Block) get_BlockAllInboundTraffic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16 Block) put_BlockAllInboundTraffic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16* disabled) get_NotificationsDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16 disabled) put_NotificationsDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16* disabled) get_UnicastResponsesToMulticastBroadcastDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, int16 disabled) put_UnicastResponsesToMulticastBroadcastDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwRules** rules) get_Rules;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwServiceRestriction** ServiceRestriction) get_ServiceRestriction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 profileTypesBitmask, BSTR group, int16 enable) EnableRuleGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 profileTypesBitmask, BSTR group, int16* enabled) IsRuleGroupEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreLocalFirewallDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION* action) get_DefaultInboundAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION action) put_DefaultInboundAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION* action) get_DefaultOutboundAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION action) put_DefaultOutboundAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR group, int16* enabled) get_IsRuleGroupCurrentlyEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_MODIFY_STATE* modifyState) get_LocalPolicyModifyState;
	}


	public HRESULT get_CurrentProfileTypes(int32* profileTypesBitmask) mut => VT.[Friend]get_CurrentProfileTypes(&this, profileTypesBitmask);

	public HRESULT get_FirewallEnabled(NET_FW_PROFILE_TYPE2 profileType, int16* enabled) mut => VT.[Friend]get_FirewallEnabled(&this, profileType, enabled);

	public HRESULT put_FirewallEnabled(NET_FW_PROFILE_TYPE2 profileType, int16 enabled) mut => VT.[Friend]put_FirewallEnabled(&this, profileType, enabled);

	public HRESULT get_ExcludedInterfaces(NET_FW_PROFILE_TYPE2 profileType, VARIANT* interfaces) mut => VT.[Friend]get_ExcludedInterfaces(&this, profileType, interfaces);

	public HRESULT put_ExcludedInterfaces(NET_FW_PROFILE_TYPE2 profileType, VARIANT interfaces) mut => VT.[Friend]put_ExcludedInterfaces(&this, profileType, interfaces);

	public HRESULT get_BlockAllInboundTraffic(NET_FW_PROFILE_TYPE2 profileType, int16* Block) mut => VT.[Friend]get_BlockAllInboundTraffic(&this, profileType, Block);

	public HRESULT put_BlockAllInboundTraffic(NET_FW_PROFILE_TYPE2 profileType, int16 Block) mut => VT.[Friend]put_BlockAllInboundTraffic(&this, profileType, Block);

	public HRESULT get_NotificationsDisabled(NET_FW_PROFILE_TYPE2 profileType, int16* disabled) mut => VT.[Friend]get_NotificationsDisabled(&this, profileType, disabled);

	public HRESULT put_NotificationsDisabled(NET_FW_PROFILE_TYPE2 profileType, int16 disabled) mut => VT.[Friend]put_NotificationsDisabled(&this, profileType, disabled);

	public HRESULT get_UnicastResponsesToMulticastBroadcastDisabled(NET_FW_PROFILE_TYPE2 profileType, int16* disabled) mut => VT.[Friend]get_UnicastResponsesToMulticastBroadcastDisabled(&this, profileType, disabled);

	public HRESULT put_UnicastResponsesToMulticastBroadcastDisabled(NET_FW_PROFILE_TYPE2 profileType, int16 disabled) mut => VT.[Friend]put_UnicastResponsesToMulticastBroadcastDisabled(&this, profileType, disabled);

	public HRESULT get_Rules(INetFwRules** rules) mut => VT.[Friend]get_Rules(&this, rules);

	public HRESULT get_ServiceRestriction(INetFwServiceRestriction** ServiceRestriction) mut => VT.[Friend]get_ServiceRestriction(&this, ServiceRestriction);

	public HRESULT EnableRuleGroup(int32 profileTypesBitmask, BSTR group, int16 enable) mut => VT.[Friend]EnableRuleGroup(&this, profileTypesBitmask, group, enable);

	public HRESULT IsRuleGroupEnabled(int32 profileTypesBitmask, BSTR group, int16* enabled) mut => VT.[Friend]IsRuleGroupEnabled(&this, profileTypesBitmask, group, enabled);

	public HRESULT RestoreLocalFirewallDefaults() mut => VT.[Friend]RestoreLocalFirewallDefaults(&this);

	public HRESULT get_DefaultInboundAction(NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION* action) mut => VT.[Friend]get_DefaultInboundAction(&this, profileType, action);

	public HRESULT put_DefaultInboundAction(NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION action) mut => VT.[Friend]put_DefaultInboundAction(&this, profileType, action);

	public HRESULT get_DefaultOutboundAction(NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION* action) mut => VT.[Friend]get_DefaultOutboundAction(&this, profileType, action);

	public HRESULT put_DefaultOutboundAction(NET_FW_PROFILE_TYPE2 profileType, NET_FW_ACTION action) mut => VT.[Friend]put_DefaultOutboundAction(&this, profileType, action);

	public HRESULT get_IsRuleGroupCurrentlyEnabled(BSTR group, int16* enabled) mut => VT.[Friend]get_IsRuleGroupCurrentlyEnabled(&this, group, enabled);

	public HRESULT get_LocalPolicyModifyState(NET_FW_MODIFY_STATE* modifyState) mut => VT.[Friend]get_LocalPolicyModifyState(&this, modifyState);
}

[CRepr]struct INetFwMgr : IDispatch
{
	public new const Guid IID = .(0xf7898af5, 0xcac4, 0x4632, 0xa2, 0xec, 0xda, 0x06, 0xe5, 0x11, 0x1a, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwPolicy** localPolicy) get_LocalPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_PROFILE_TYPE* profileType) get_CurrentProfileType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR imageFileName, NET_FW_IP_VERSION ipVersion, int32 portNumber, BSTR localAddress, NET_FW_IP_PROTOCOL ipProtocol, VARIANT* allowed, VARIANT* restricted) IsPortAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NET_FW_IP_VERSION ipVersion, BSTR localAddress, uint8 type, VARIANT* allowed, VARIANT* restricted) IsIcmpTypeAllowed;
	}


	public HRESULT get_LocalPolicy(INetFwPolicy** localPolicy) mut => VT.[Friend]get_LocalPolicy(&this, localPolicy);

	public HRESULT get_CurrentProfileType(NET_FW_PROFILE_TYPE* profileType) mut => VT.[Friend]get_CurrentProfileType(&this, profileType);

	public HRESULT RestoreDefaults() mut => VT.[Friend]RestoreDefaults(&this);

	public HRESULT IsPortAllowed(BSTR imageFileName, NET_FW_IP_VERSION ipVersion, int32 portNumber, BSTR localAddress, NET_FW_IP_PROTOCOL ipProtocol, VARIANT* allowed, VARIANT* restricted) mut => VT.[Friend]IsPortAllowed(&this, imageFileName, ipVersion, portNumber, localAddress, ipProtocol, allowed, restricted);

	public HRESULT IsIcmpTypeAllowed(NET_FW_IP_VERSION ipVersion, BSTR localAddress, uint8 type, VARIANT* allowed, VARIANT* restricted) mut => VT.[Friend]IsIcmpTypeAllowed(&this, ipVersion, localAddress, type, allowed, restricted);
}

[CRepr]struct INetFwProduct : IDispatch
{
	public new const Guid IID = .(0x71881699, 0x18f4, 0x458b, 0xb8, 0x92, 0x3f, 0xfc, 0xe5, 0xe0, 0x7f, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* ruleCategories) get_RuleCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ruleCategories) put_RuleCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* displayName) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR displayName) put_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_PathToSignedProductExe;
	}


	public HRESULT get_RuleCategories(VARIANT* ruleCategories) mut => VT.[Friend]get_RuleCategories(&this, ruleCategories);

	public HRESULT put_RuleCategories(VARIANT ruleCategories) mut => VT.[Friend]put_RuleCategories(&this, ruleCategories);

	public HRESULT get_DisplayName(BSTR* displayName) mut => VT.[Friend]get_DisplayName(&this, displayName);

	public HRESULT put_DisplayName(BSTR displayName) mut => VT.[Friend]put_DisplayName(&this, displayName);

	public HRESULT get_PathToSignedProductExe(BSTR* path) mut => VT.[Friend]get_PathToSignedProductExe(&this, path);
}

[CRepr]struct INetFwProducts : IDispatch
{
	public new const Guid IID = .(0x39eb36e0, 0x2097, 0x40bd, 0x8a, 0xf2, 0x63, 0xa1, 0x3b, 0x52, 0x53, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetFwProduct* product, IUnknown** registration) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, INetFwProduct** product) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** newEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT Register(INetFwProduct* product, IUnknown** registration) mut => VT.[Friend]Register(&this, product, registration);

	public HRESULT Item(int32 index, INetFwProduct** product) mut => VT.[Friend]Item(&this, index, product);

	public HRESULT get__NewEnum(IUnknown** newEnum) mut => VT.[Friend]get__NewEnum(&this, newEnum);
}

#endregion

#region Functions
public static
{
	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NetworkIsolationSetupAppContainerBinaries(PSID applicationContainerSid, PWSTR packageFullName, PWSTR packageFolder, PWSTR displayName, BOOL bBinariesFullyComputed, PWSTR* binaries, uint32 binariesCount);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationRegisterForAppContainerChanges(uint32 flags, PAC_CHANGES_CALLBACK_FN callback, void* context, HANDLE* registrationObject);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationUnregisterForAppContainerChanges(HANDLE registrationObject);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationFreeAppContainers(INET_FIREWALL_APP_CONTAINER* pPublicAppCs);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationEnumAppContainers(uint32 Flags, uint32* pdwNumPublicAppCs, INET_FIREWALL_APP_CONTAINER** ppPublicAppCs);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationGetAppContainerConfig(uint32* pdwNumPublicAppCs, SID_AND_ATTRIBUTES** appContainerSids);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationSetAppContainerConfig(uint32 dwNumPublicAppCs, SID_AND_ATTRIBUTES* appContainerSids);

	[Import("api-ms-win-net-isolation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetworkIsolationDiagnoseConnectFailureAndGetInfo(PWSTR wszServerName, NETISO_ERROR_TYPE* netIsoError);

}
#endregion
