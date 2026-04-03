using Win32.Foundation;
using System;

namespace Win32.System.HostComputeNetwork;

#region Enums

[AllowDuplicates]
public enum HCN_NOTIFICATIONS : int32
{
	HcnNotificationInvalid = 0,
	HcnNotificationNetworkPreCreate = 1,
	HcnNotificationNetworkCreate = 2,
	HcnNotificationNetworkPreDelete = 3,
	HcnNotificationNetworkDelete = 4,
	HcnNotificationNamespaceCreate = 5,
	HcnNotificationNamespaceDelete = 6,
	HcnNotificationGuestNetworkServiceCreate = 7,
	HcnNotificationGuestNetworkServiceDelete = 8,
	HcnNotificationNetworkEndpointAttached = 9,
	HcnNotificationNetworkEndpointDetached = 16,
	HcnNotificationGuestNetworkServiceStateChanged = 17,
	HcnNotificationGuestNetworkServiceInterfaceStateChanged = 18,
	HcnNotificationServiceDisconnect = 16777216,
	HcnNotificationFlagsReserved = -268435456,
}


[AllowDuplicates]
public enum HCN_PORT_PROTOCOL : int32
{
	HCN_PORT_PROTOCOL_TCP = 1,
	HCN_PORT_PROTOCOL_UDP = 2,
	HCN_PORT_PROTOCOL_BOTH = 3,
}


[AllowDuplicates]
public enum HCN_PORT_ACCESS : int32
{
	HCN_PORT_ACCESS_EXCLUSIVE = 1,
	HCN_PORT_ACCESS_SHARED = 2,
}

#endregion

#region Function Pointers
public function void HCN_NOTIFICATION_CALLBACK(uint32 NotificationType, void* Context, HRESULT NotificationStatus, PWSTR NotificationData);

#endregion

#region Structs
[CRepr]
public struct HCN_PORT_RANGE_RESERVATION
{
	public uint16 startingPort;
	public uint16 endingPort;
}

[CRepr]
public struct HCN_PORT_RANGE_ENTRY
{
	public Guid OwningPartitionId;
	public Guid TargetPartitionId;
	public HCN_PORT_PROTOCOL Protocol;
	public uint64 Priority;
	public uint32 ReservationType;
	public uint32 SharingFlags;
	public uint32 DeliveryMode;
	public uint16 StartingPort;
	public uint16 EndingPort;
}

#endregion

#region Functions
public static
{
	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnEnumerateNetworks(PWSTR Query, PWSTR* Networks, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCreateNetwork(in Guid Id, PWSTR Settings, void** Network, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnOpenNetwork(in Guid Id, void** Network, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnModifyNetwork(void* Network, PWSTR Settings, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnQueryNetworkProperties(void* Network, PWSTR Query, PWSTR* Properties, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnDeleteNetwork(in Guid Id, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCloseNetwork(void* Network);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnEnumerateNamespaces(PWSTR Query, PWSTR* Namespaces, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCreateNamespace(in Guid Id, PWSTR Settings, void** Namespace, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnOpenNamespace(in Guid Id, void** Namespace, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnModifyNamespace(void* Namespace, PWSTR Settings, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnQueryNamespaceProperties(void* Namespace, PWSTR Query, PWSTR* Properties, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnDeleteNamespace(in Guid Id, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCloseNamespace(void* Namespace);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnEnumerateEndpoints(PWSTR Query, PWSTR* Endpoints, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCreateEndpoint(void* Network, in Guid Id, PWSTR Settings, void** Endpoint, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnOpenEndpoint(in Guid Id, void** Endpoint, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnModifyEndpoint(void* Endpoint, PWSTR Settings, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnQueryEndpointProperties(void* Endpoint, PWSTR Query, PWSTR* Properties, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnDeleteEndpoint(in Guid Id, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCloseEndpoint(void* Endpoint);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnEnumerateLoadBalancers(PWSTR Query, PWSTR* LoadBalancer, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCreateLoadBalancer(in Guid Id, PWSTR Settings, void** LoadBalancer, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnOpenLoadBalancer(in Guid Id, void** LoadBalancer, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnModifyLoadBalancer(void* LoadBalancer, PWSTR Settings, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnQueryLoadBalancerProperties(void* LoadBalancer, PWSTR Query, PWSTR* Properties, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnDeleteLoadBalancer(in Guid Id, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCloseLoadBalancer(void* LoadBalancer);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnRegisterServiceCallback(HCN_NOTIFICATION_CALLBACK Callback, void* Context, void** CallbackHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnUnregisterServiceCallback(void* CallbackHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnRegisterGuestNetworkServiceCallback(void* GuestNetworkService, HCN_NOTIFICATION_CALLBACK Callback, void* Context, void** CallbackHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnUnregisterGuestNetworkServiceCallback(void* CallbackHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCreateGuestNetworkService(in Guid Id, PWSTR Settings, void** GuestNetworkService, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnCloseGuestNetworkService(void* GuestNetworkService);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnModifyGuestNetworkService(void* GuestNetworkService, PWSTR Settings, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnDeleteGuestNetworkService(in Guid Id, PWSTR* ErrorRecord);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnReserveGuestNetworkServicePort(void* GuestNetworkService, HCN_PORT_PROTOCOL Protocol, HCN_PORT_ACCESS Access, uint16 Port, HANDLE* PortReservationHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnReserveGuestNetworkServicePortRange(void* GuestNetworkService, uint16 PortCount, HCN_PORT_RANGE_RESERVATION* PortRangeReservation, HANDLE* PortReservationHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnReleaseGuestNetworkServicePortReservationHandle(HANDLE PortReservationHandle);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcnEnumerateGuestNetworkPortReservations(uint32* ReturnCount, HCN_PORT_RANGE_ENTRY** PortEntries);

	[Import("computenetwork.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HcnFreeGuestNetworkPortReservations(HCN_PORT_RANGE_ENTRY* PortEntries);

}
#endregion
