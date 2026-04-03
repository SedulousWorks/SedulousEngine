using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.Multicast;

#region Constants
public static
{
	public const uint32 MCAST_CLIENT_ID_LEN = 17;
	public const int32 MCAST_API_CURRENT_VERSION = 1;
	public const int32 MCAST_API_VERSION_0 = 0;
	public const int32 MCAST_API_VERSION_1 = 1;
}
#endregion

#region Structs
[CRepr, Union]
public struct IPNG_ADDRESS
{
	public uint32 IpAddrV4;
	public uint8[16] IpAddrV6;
}

[CRepr]
public struct MCAST_CLIENT_UID
{
	public uint8* ClientUID;
	public uint32 ClientUIDLength;
}

[CRepr]
public struct MCAST_SCOPE_CTX
{
	public IPNG_ADDRESS ScopeID;
	public IPNG_ADDRESS Interface;
	public IPNG_ADDRESS ServerID;
}

[CRepr]
public struct MCAST_SCOPE_ENTRY
{
	public MCAST_SCOPE_CTX ScopeCtx;
	public IPNG_ADDRESS LastAddr;
	public uint32 TTL;
	public UNICODE_STRING ScopeDesc;
}

[CRepr]
public struct MCAST_LEASE_REQUEST
{
	public int32 LeaseStartTime;
	public int32 MaxLeaseStartTime;
	public uint32 LeaseDuration;
	public uint32 MinLeaseDuration;
	public IPNG_ADDRESS ServerAddress;
	public uint16 MinAddrCount;
	public uint16 AddrCount;
	public uint8* pAddrBuf;
}

[CRepr]
public struct MCAST_LEASE_RESPONSE
{
	public int32 LeaseStartTime;
	public int32 LeaseEndTime;
	public IPNG_ADDRESS ServerAddress;
	public uint16 AddrCount;
	public uint8* pAddrBuf;
}

#endregion

#region Functions
public static
{
	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 McastApiStartup(uint32* Version);

	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void McastApiCleanup();

	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 McastGenUID(MCAST_CLIENT_UID* pRequestID);

	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 McastEnumerateScopes(uint16 AddrFamily, BOOL ReQuery, MCAST_SCOPE_ENTRY* pScopeList, uint32* pScopeLen, uint32* pScopeCount);

	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 McastRequestAddress(uint16 AddrFamily, MCAST_CLIENT_UID* pRequestID, MCAST_SCOPE_CTX* pScopeCtx, MCAST_LEASE_REQUEST* pAddrRequest, MCAST_LEASE_RESPONSE* pAddrResponse);

	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 McastRenewAddress(uint16 AddrFamily, MCAST_CLIENT_UID* pRequestID, MCAST_LEASE_REQUEST* pRenewRequest, MCAST_LEASE_RESPONSE* pRenewResponse);

	[Import("dhcpcsvc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 McastReleaseAddress(uint16 AddrFamily, MCAST_CLIENT_UID* pRequestID, MCAST_LEASE_REQUEST* pReleaseRequest);

}
#endregion
