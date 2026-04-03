using Win32.Networking.WinSock;
using Win32.Foundation;
using Win32.System.IO;
using System;

namespace Win32.NetworkManagement.WindowsNetworkVirtualization;

#region Constants
public static
{
	public const uint32 WNV_API_MAJOR_VERSION_1 = 1;
	public const uint32 WNV_API_MINOR_VERSION_0 = 0;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WNV_NOTIFICATION_TYPE : int32
{
	WnvPolicyMismatchType = 0,
	WnvRedirectType = 1,
	WnvObjectChangeType = 2,
	WnvNotificationTypeMax = 3,
}


[AllowDuplicates]
public enum WNV_OBJECT_TYPE : int32
{
	WnvProviderAddressType = 0,
	WnvCustomerAddressType = 1,
	WnvObjectTypeMax = 2,
}


[AllowDuplicates]
public enum WNV_CA_NOTIFICATION_TYPE : int32
{
	WnvCustomerAddressAdded = 0,
	WnvCustomerAddressDeleted = 1,
	WnvCustomerAddressMoved = 2,
	WnvCustomerAddressMax = 3,
}

#endregion


#region Structs
[CRepr]
public struct WNV_OBJECT_HEADER
{
	public uint8 MajorVersion;
	public uint8 MinorVersion;
	public uint32 Size;
}

[CRepr]
public struct WNV_NOTIFICATION_PARAM
{
	public WNV_OBJECT_HEADER Header;
	public WNV_NOTIFICATION_TYPE NotificationType;
	public uint32 PendingNotifications;
	public uint8* Buffer;
}

[CRepr]
public struct WNV_IP_ADDRESS
{
	[CRepr, Union]
	public struct _IP_e__Union
	{
		public IN_ADDR v4;
		public IN6_ADDR v6;
		public uint8[16] Addr;
	}
	public _IP_e__Union IP;
}

[CRepr]
public struct WNV_POLICY_MISMATCH_PARAM
{
	public uint16 CAFamily;
	public uint16 PAFamily;
	public uint32 VirtualSubnetId;
	public WNV_IP_ADDRESS CA;
	public WNV_IP_ADDRESS PA;
}

[CRepr]
public struct WNV_PROVIDER_ADDRESS_CHANGE_PARAM
{
	public uint16 PAFamily;
	public WNV_IP_ADDRESS PA;
	public NL_DAD_STATE AddressState;
}

[CRepr]
public struct WNV_CUSTOMER_ADDRESS_CHANGE_PARAM
{
	public DL_EUI48 MACAddress;
	public uint16 CAFamily;
	public WNV_IP_ADDRESS CA;
	public uint32 VirtualSubnetId;
	public uint16 PAFamily;
	public WNV_IP_ADDRESS PA;
	public WNV_CA_NOTIFICATION_TYPE NotificationReason;
}

[CRepr]
public struct WNV_OBJECT_CHANGE_PARAM
{
	[CRepr, Union]
	public struct _ObjectParam_e__Union
	{
		public WNV_PROVIDER_ADDRESS_CHANGE_PARAM ProviderAddressChange;
		public WNV_CUSTOMER_ADDRESS_CHANGE_PARAM CustomerAddressChange;
	}
	public WNV_OBJECT_TYPE ObjectType;
	public _ObjectParam_e__Union ObjectParam;
}

[CRepr]
public struct WNV_REDIRECT_PARAM
{
	public uint16 CAFamily;
	public uint16 PAFamily;
	public uint16 NewPAFamily;
	public uint32 VirtualSubnetId;
	public WNV_IP_ADDRESS CA;
	public WNV_IP_ADDRESS PA;
	public WNV_IP_ADDRESS NewPA;
}

#endregion

#region Functions
public static
{
	[Import("wnvapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WnvOpen();

	[Import("wnvapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WnvRequestNotification(HANDLE WnvHandle, WNV_NOTIFICATION_PARAM* NotificationParam, OVERLAPPED* Overlapped, uint32* BytesTransferred);

}
#endregion
