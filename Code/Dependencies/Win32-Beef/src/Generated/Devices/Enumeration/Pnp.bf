using Win32.Foundation;
using Win32.Security;
using Win32.System.Com;
using Win32.Devices.Properties;
using System;

namespace Win32.Devices.Enumeration.Pnp;

#region Constants
public static
{
	public const HRESULT UPNP_E_ROOT_ELEMENT_EXPECTED = -2147220992;
	public const HRESULT UPNP_E_DEVICE_ELEMENT_EXPECTED = -2147220991;
	public const HRESULT UPNP_E_SERVICE_ELEMENT_EXPECTED = -2147220990;
	public const HRESULT UPNP_E_SERVICE_NODE_INCOMPLETE = -2147220989;
	public const HRESULT UPNP_E_DEVICE_NODE_INCOMPLETE = -2147220988;
	public const HRESULT UPNP_E_ICON_ELEMENT_EXPECTED = -2147220987;
	public const HRESULT UPNP_E_ICON_NODE_INCOMPLETE = -2147220986;
	public const HRESULT UPNP_E_INVALID_ACTION = -2147220985;
	public const HRESULT UPNP_E_INVALID_ARGUMENTS = -2147220984;
	public const HRESULT UPNP_E_OUT_OF_SYNC = -2147220983;
	public const HRESULT UPNP_E_ACTION_REQUEST_FAILED = -2147220976;
	public const HRESULT UPNP_E_TRANSPORT_ERROR = -2147220975;
	public const HRESULT UPNP_E_VARIABLE_VALUE_UNKNOWN = -2147220974;
	public const HRESULT UPNP_E_INVALID_VARIABLE = -2147220973;
	public const HRESULT UPNP_E_DEVICE_ERROR = -2147220972;
	public const HRESULT UPNP_E_PROTOCOL_ERROR = -2147220971;
	public const HRESULT UPNP_E_ERROR_PROCESSING_RESPONSE = -2147220970;
	public const HRESULT UPNP_E_DEVICE_TIMEOUT = -2147220969;
	public const HRESULT UPNP_E_INVALID_DOCUMENT = -2147220224;
	public const HRESULT UPNP_E_EVENT_SUBSCRIPTION_FAILED = -2147220223;
	public const uint32 FAULT_INVALID_ACTION = 401;
	public const uint32 FAULT_INVALID_ARG = 402;
	public const uint32 FAULT_INVALID_SEQUENCE_NUMBER = 403;
	public const uint32 FAULT_INVALID_VARIABLE = 404;
	public const uint32 FAULT_DEVICE_INTERNAL_ERROR = 501;
	public const uint32 FAULT_ACTION_SPECIFIC_BASE = 600;
	public const uint32 FAULT_ACTION_SPECIFIC_MAX = 899;
	public const HRESULT UPNP_E_ACTION_SPECIFIC_BASE = -2147220736;
	public const uint32 UPNP_ADDRESSFAMILY_IPv4 = 1;
	public const uint32 UPNP_ADDRESSFAMILY_IPv6 = 2;
	public const uint32 UPNP_ADDRESSFAMILY_BOTH = 3;
	public const uint32 UPNP_SERVICE_DELAY_SCPD_AND_SUBSCRIPTION = 1;
	public const HRESULT UPNP_E_REQUIRED_ELEMENT_ERROR = -2147180512;
	public const HRESULT UPNP_E_DUPLICATE_NOT_ALLOWED = -2147180511;
	public const HRESULT UPNP_E_DUPLICATE_SERVICE_ID = -2147180510;
	public const HRESULT UPNP_E_INVALID_DESCRIPTION = -2147180509;
	public const HRESULT UPNP_E_INVALID_SERVICE = -2147180508;
	public const HRESULT UPNP_E_INVALID_ICON = -2147180507;
	public const HRESULT UPNP_E_INVALID_XML = -2147180506;
	public const HRESULT UPNP_E_INVALID_ROOT_NAMESPACE = -2147180505;
	public const HRESULT UPNP_E_SUFFIX_TOO_LONG = -2147180504;
	public const HRESULT UPNP_E_URLBASE_PRESENT = -2147180503;
	public const HRESULT UPNP_E_VALUE_TOO_LONG = -2147180496;
	public const HRESULT UPNP_E_DEVICE_RUNNING = -2147180495;
	public const HRESULT UPNP_E_DEVICE_NOTREGISTERED = -2147180494;
	public const String REMOTE_ADDRESS_VALUE_NAME = "RemoteAddress";
	public const String ADDRESS_FAMILY_VALUE_NAME = "AddressFamily";
}
#endregion

#region TypeDefs
typealias HSWDEVICE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum SW_DEVICE_CAPABILITIES : int32
{
	SWDeviceCapabilitiesNone = 0,
	SWDeviceCapabilitiesRemovable = 1,
	SWDeviceCapabilitiesSilentInstall = 2,
	SWDeviceCapabilitiesNoDisplayInUI = 4,
	SWDeviceCapabilitiesDriverRequired = 8,
}


[AllowDuplicates]
public enum SW_DEVICE_LIFETIME : int32
{
	SWDeviceLifetimeHandle = 0,
	SWDeviceLifetimeParentPresent = 1,
	SWDeviceLifetimeMax = 2,
}

#endregion

#region Function Pointers
public function void SW_DEVICE_CREATE_CALLBACK(HSWDEVICE hSwDevice, HRESULT CreateResult, void* pContext, PWSTR pszDeviceInstanceId);

#endregion

#region Structs
[CRepr]
public struct SW_DEVICE_CREATE_INFO
{
	public uint32 cbSize;
	public PWSTR pszInstanceId;
	public PWSTR pszzHardwareIds;
	public PWSTR pszzCompatibleIds;
	public Guid* pContainerId;
	public uint32 CapabilityFlags;
	public PWSTR pszDeviceDescription;
	public PWSTR pszDeviceLocation;
	public SECURITY_DESCRIPTOR* pSecurityDescriptor;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_UPnPDeviceFinder = .(0xe2085f28, 0xfeb7, 0x404a, 0xb8, 0xe7, 0xe6, 0x59, 0xbd, 0xea, 0xaa, 0x02);


	public const Guid CLSID_UPnPDevices = .(0xb9e84ffd, 0xad3c, 0x40a4, 0xb8, 0x35, 0x08, 0x82, 0xeb, 0xcb, 0xaa, 0xa8);


	public const Guid CLSID_UPnPDevice = .(0xa32552c5, 0xba61, 0x457a, 0xb5, 0x9a, 0xa2, 0x56, 0x1e, 0x12, 0x5e, 0x33);


	public const Guid CLSID_UPnPServices = .(0xc0bc4b4a, 0xa406, 0x4efc, 0x93, 0x2f, 0xb8, 0x54, 0x6b, 0x81, 0x00, 0xcc);


	public const Guid CLSID_UPnPService = .(0xc624ba95, 0xfbcb, 0x4409, 0x8c, 0x03, 0x8c, 0xce, 0xec, 0x53, 0x3e, 0xf1);


	public const Guid CLSID_UPnPDescriptionDocument = .(0x1d8a9b47, 0x3a28, 0x4ce2, 0x8a, 0x4b, 0xbd, 0x34, 0xe4, 0x5b, 0xce, 0xeb);


	public const Guid CLSID_UPnPDeviceFinderEx = .(0x181b54fc, 0x380b, 0x4a75, 0xb3, 0xf1, 0x4a, 0xc4, 0x5e, 0x96, 0x05, 0xb0);


	public const Guid CLSID_UPnPDescriptionDocumentEx = .(0x33fd0563, 0xd81a, 0x4393, 0x83, 0xcc, 0x01, 0x95, 0xb1, 0xda, 0x2f, 0x91);


	public const Guid CLSID_UPnPRegistrar = .(0x204810b9, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);


	public const Guid CLSID_UPnPRemoteEndpointInfo = .(0x2e5e84e9, 0x4049, 0x4244, 0xb7, 0x28, 0x2d, 0x24, 0x22, 0x71, 0x57, 0xc7);


}
#endregion

#region COM Types
[CRepr]struct IUPnPDeviceFinder : IDispatch
{
	public new const Guid IID = .(0xadda3d55, 0x6f72, 0x4319, 0xbf, 0xf9, 0x18, 0x60, 0x0a, 0x53, 0x9b, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTypeURI, uint32 dwFlags, IUPnPDevices** pDevices) FindByType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTypeURI, uint32 dwFlags, IUnknown* punkDeviceFinderCallback, int32* plFindData) CreateAsyncFind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFindData) StartAsyncFind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFindData) CancelAsyncFind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUDN, IUPnPDevice** pDevice) FindByUDN;
	}


	public HRESULT FindByType(BSTR bstrTypeURI, uint32 dwFlags, IUPnPDevices** pDevices) mut => VT.[Friend]FindByType(&this, bstrTypeURI, dwFlags, pDevices);

	public HRESULT CreateAsyncFind(BSTR bstrTypeURI, uint32 dwFlags, IUnknown* punkDeviceFinderCallback, int32* plFindData) mut => VT.[Friend]CreateAsyncFind(&this, bstrTypeURI, dwFlags, punkDeviceFinderCallback, plFindData);

	public HRESULT StartAsyncFind(int32 lFindData) mut => VT.[Friend]StartAsyncFind(&this, lFindData);

	public HRESULT CancelAsyncFind(int32 lFindData) mut => VT.[Friend]CancelAsyncFind(&this, lFindData);

	public HRESULT FindByUDN(BSTR bstrUDN, IUPnPDevice** pDevice) mut => VT.[Friend]FindByUDN(&this, bstrUDN, pDevice);
}

[CRepr]struct IUPnPAddressFamilyControl : IUnknown
{
	public new const Guid IID = .(0xe3bf6178, 0x694e, 0x459f, 0xa5, 0xa6, 0x19, 0x1e, 0xa0, 0xff, 0xa1, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) SetAddressFamily;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) GetAddressFamily;
	}


	public HRESULT SetAddressFamily(int32 dwFlags) mut => VT.[Friend]SetAddressFamily(&this, dwFlags);

	public HRESULT GetAddressFamily(int32* pdwFlags) mut => VT.[Friend]GetAddressFamily(&this, pdwFlags);
}

[CRepr]struct IUPnPHttpHeaderControl : IUnknown
{
	public new const Guid IID = .(0x0405af4f, 0x8b5c, 0x447c, 0x80, 0xf2, 0xb7, 0x59, 0x84, 0xa3, 0x1f, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHttpHeaders) AddRequestHeaders;
	}


	public HRESULT AddRequestHeaders(BSTR bstrHttpHeaders) mut => VT.[Friend]AddRequestHeaders(&this, bstrHttpHeaders);
}

[CRepr]struct IUPnPDeviceFinderCallback : IUnknown
{
	public new const Guid IID = .(0x415a984a, 0x88b3, 0x49f3, 0x92, 0xaf, 0x05, 0x08, 0xbe, 0xdf, 0x0d, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFindData, IUPnPDevice* pDevice) DeviceAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFindData, BSTR bstrUDN) DeviceRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFindData) SearchComplete;
	}


	public HRESULT DeviceAdded(int32 lFindData, IUPnPDevice* pDevice) mut => VT.[Friend]DeviceAdded(&this, lFindData, pDevice);

	public HRESULT DeviceRemoved(int32 lFindData, BSTR bstrUDN) mut => VT.[Friend]DeviceRemoved(&this, lFindData, bstrUDN);

	public HRESULT SearchComplete(int32 lFindData) mut => VT.[Friend]SearchComplete(&this, lFindData);
}

[CRepr]struct IUPnPServices : IDispatch
{
	public new const Guid IID = .(0x3f8c8e9e, 0x9a7a, 0x4dc8, 0xbc, 0x41, 0xff, 0x31, 0xfa, 0x37, 0x49, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServiceId, IUPnPService** ppService) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppunk) mut => VT.[Friend]get__NewEnum(&this, ppunk);

	public HRESULT get_Item(BSTR bstrServiceId, IUPnPService** ppService) mut => VT.[Friend]get_Item(&this, bstrServiceId, ppService);
}

[CRepr]struct IUPnPService : IDispatch
{
	public new const Guid IID = .(0xa295019c, 0xdc65, 0x47dd, 0x90, 0xdc, 0x7f, 0xe9, 0x18, 0xa1, 0xab, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVariableName, VARIANT* pValue) QueryStateVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrActionName, VARIANT vInActionArgs, VARIANT* pvOutActionArgs, VARIANT* pvRetVal) InvokeAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ServiceTypeIdentifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkCallback) AddCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plValue) get_LastTransportStatus;
	}


	public HRESULT QueryStateVariable(BSTR bstrVariableName, VARIANT* pValue) mut => VT.[Friend]QueryStateVariable(&this, bstrVariableName, pValue);

	public HRESULT InvokeAction(BSTR bstrActionName, VARIANT vInActionArgs, VARIANT* pvOutActionArgs, VARIANT* pvRetVal) mut => VT.[Friend]InvokeAction(&this, bstrActionName, vInActionArgs, pvOutActionArgs, pvRetVal);

	public HRESULT get_ServiceTypeIdentifier(BSTR* pVal) mut => VT.[Friend]get_ServiceTypeIdentifier(&this, pVal);

	public HRESULT AddCallback(IUnknown* pUnkCallback) mut => VT.[Friend]AddCallback(&this, pUnkCallback);

	public HRESULT get_Id(BSTR* pbstrId) mut => VT.[Friend]get_Id(&this, pbstrId);

	public HRESULT get_LastTransportStatus(int32* plValue) mut => VT.[Friend]get_LastTransportStatus(&this, plValue);
}

[CRepr]struct IUPnPAsyncResult : IUnknown
{
	public new const Guid IID = .(0x4d65fd08, 0xd13e, 0x4274, 0x9c, 0x8b, 0xdd, 0x8d, 0x02, 0x8c, 0x86, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullRequestID) AsyncOperationComplete;
	}


	public HRESULT AsyncOperationComplete(uint64 ullRequestID) mut => VT.[Friend]AsyncOperationComplete(&this, ullRequestID);
}

[CRepr]struct IUPnPServiceAsync : IUnknown
{
	public new const Guid IID = .(0x098bdaf5, 0x5ec1, 0x49e7, 0xa2, 0x60, 0xb3, 0xa1, 0x1d, 0xd8, 0x68, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrActionName, VARIANT vInActionArgs, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) BeginInvokeAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullRequestID, VARIANT* pvOutActionArgs, VARIANT* pvRetVal) EndInvokeAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVariableName, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) BeginQueryStateVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullRequestID, VARIANT* pValue) EndQueryStateVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkCallback, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) BeginSubscribeToEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullRequestID) EndSubscribeToEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) BeginSCPDDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullRequestID, BSTR* pbstrSCPDDoc) EndSCPDDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullRequestID) CancelAsyncOperation;
	}


	public HRESULT BeginInvokeAction(BSTR bstrActionName, VARIANT vInActionArgs, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) mut => VT.[Friend]BeginInvokeAction(&this, bstrActionName, vInActionArgs, pAsyncResult, pullRequestID);

	public HRESULT EndInvokeAction(uint64 ullRequestID, VARIANT* pvOutActionArgs, VARIANT* pvRetVal) mut => VT.[Friend]EndInvokeAction(&this, ullRequestID, pvOutActionArgs, pvRetVal);

	public HRESULT BeginQueryStateVariable(BSTR bstrVariableName, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) mut => VT.[Friend]BeginQueryStateVariable(&this, bstrVariableName, pAsyncResult, pullRequestID);

	public HRESULT EndQueryStateVariable(uint64 ullRequestID, VARIANT* pValue) mut => VT.[Friend]EndQueryStateVariable(&this, ullRequestID, pValue);

	public HRESULT BeginSubscribeToEvents(IUnknown* pUnkCallback, IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) mut => VT.[Friend]BeginSubscribeToEvents(&this, pUnkCallback, pAsyncResult, pullRequestID);

	public HRESULT EndSubscribeToEvents(uint64 ullRequestID) mut => VT.[Friend]EndSubscribeToEvents(&this, ullRequestID);

	public HRESULT BeginSCPDDownload(IUPnPAsyncResult* pAsyncResult, uint64* pullRequestID) mut => VT.[Friend]BeginSCPDDownload(&this, pAsyncResult, pullRequestID);

	public HRESULT EndSCPDDownload(uint64 ullRequestID, BSTR* pbstrSCPDDoc) mut => VT.[Friend]EndSCPDDownload(&this, ullRequestID, pbstrSCPDDoc);

	public HRESULT CancelAsyncOperation(uint64 ullRequestID) mut => VT.[Friend]CancelAsyncOperation(&this, ullRequestID);
}

[CRepr]struct IUPnPServiceCallback : IUnknown
{
	public new const Guid IID = .(0x31fadca9, 0xab73, 0x464b, 0xb6, 0x7d, 0x5c, 0x1d, 0x0f, 0x83, 0xc8, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPService* pus, PWSTR pcwszStateVarName, VARIANT vaValue) StateVariableChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPService* pus) ServiceInstanceDied;
	}


	public HRESULT StateVariableChanged(IUPnPService* pus, PWSTR pcwszStateVarName, VARIANT vaValue) mut => VT.[Friend]StateVariableChanged(&this, pus, pcwszStateVarName, vaValue);

	public HRESULT ServiceInstanceDied(IUPnPService* pus) mut => VT.[Friend]ServiceInstanceDied(&this, pus);
}

[CRepr]struct IUPnPServiceEnumProperty : IUnknown
{
	public new const Guid IID = .(0x38873b37, 0x91bb, 0x49f4, 0xb2, 0x49, 0x2e, 0x8e, 0xfb, 0xb8, 0xa8, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMask) SetServiceEnumProperty;
	}


	public HRESULT SetServiceEnumProperty(uint32 dwMask) mut => VT.[Friend]SetServiceEnumProperty(&this, dwMask);
}

[CRepr]struct IUPnPServiceDocumentAccess : IUnknown
{
	public new const Guid IID = .(0x21905529, 0x0a5e, 0x4589, 0x82, 0x5d, 0x7e, 0x6d, 0x87, 0xea, 0x69, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDocUrl) GetDocumentURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDoc) GetDocument;
	}


	public HRESULT GetDocumentURL(BSTR* pbstrDocUrl) mut => VT.[Friend]GetDocumentURL(&this, pbstrDocUrl);

	public HRESULT GetDocument(BSTR* pbstrDoc) mut => VT.[Friend]GetDocument(&this, pbstrDoc);
}

[CRepr]struct IUPnPDevices : IDispatch
{
	public new const Guid IID = .(0xfdbc0c73, 0xbda3, 0x4c66, 0xac, 0x4f, 0xf2, 0xd9, 0x6f, 0xda, 0xd6, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUDN, IUPnPDevice** ppDevice) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppunk) mut => VT.[Friend]get__NewEnum(&this, ppunk);

	public HRESULT get_Item(BSTR bstrUDN, IUPnPDevice** ppDevice) mut => VT.[Friend]get_Item(&this, bstrUDN, ppDevice);
}

[CRepr]struct IUPnPDevice : IDispatch
{
	public new const Guid IID = .(0x3d44d0d1, 0x98c9, 0x4889, 0xac, 0xd1, 0xf9, 0xd6, 0x74, 0xbf, 0x22, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvarb) get_IsRootDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPDevice** ppudRootDevice) get_RootDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPDevice** ppudDeviceParent) get_ParentDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvarb) get_HasChildren;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPDevices** ppudChildren) get_Children;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_UniqueDeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_PresentationURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_ManufacturerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_ManufacturerURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_ModelName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_ModelNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_ModelURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_UPC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_SerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEncodingFormat, int32 lSizeX, int32 lSizeY, int32 lBitDepth, BSTR* pbstrIconURL) IconURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPServices** ppusServices) get_Services;
	}


	public HRESULT get_IsRootDevice(int16* pvarb) mut => VT.[Friend]get_IsRootDevice(&this, pvarb);

	public HRESULT get_RootDevice(IUPnPDevice** ppudRootDevice) mut => VT.[Friend]get_RootDevice(&this, ppudRootDevice);

	public HRESULT get_ParentDevice(IUPnPDevice** ppudDeviceParent) mut => VT.[Friend]get_ParentDevice(&this, ppudDeviceParent);

	public HRESULT get_HasChildren(int16* pvarb) mut => VT.[Friend]get_HasChildren(&this, pvarb);

	public HRESULT get_Children(IUPnPDevices** ppudChildren) mut => VT.[Friend]get_Children(&this, ppudChildren);

	public HRESULT get_UniqueDeviceName(BSTR* pbstr) mut => VT.[Friend]get_UniqueDeviceName(&this, pbstr);

	public HRESULT get_FriendlyName(BSTR* pbstr) mut => VT.[Friend]get_FriendlyName(&this, pbstr);

	public HRESULT get_Type(BSTR* pbstr) mut => VT.[Friend]get_Type(&this, pbstr);

	public HRESULT get_PresentationURL(BSTR* pbstr) mut => VT.[Friend]get_PresentationURL(&this, pbstr);

	public HRESULT get_ManufacturerName(BSTR* pbstr) mut => VT.[Friend]get_ManufacturerName(&this, pbstr);

	public HRESULT get_ManufacturerURL(BSTR* pbstr) mut => VT.[Friend]get_ManufacturerURL(&this, pbstr);

	public HRESULT get_ModelName(BSTR* pbstr) mut => VT.[Friend]get_ModelName(&this, pbstr);

	public HRESULT get_ModelNumber(BSTR* pbstr) mut => VT.[Friend]get_ModelNumber(&this, pbstr);

	public HRESULT get_Description(BSTR* pbstr) mut => VT.[Friend]get_Description(&this, pbstr);

	public HRESULT get_ModelURL(BSTR* pbstr) mut => VT.[Friend]get_ModelURL(&this, pbstr);

	public HRESULT get_UPC(BSTR* pbstr) mut => VT.[Friend]get_UPC(&this, pbstr);

	public HRESULT get_SerialNumber(BSTR* pbstr) mut => VT.[Friend]get_SerialNumber(&this, pbstr);

	public HRESULT IconURL(BSTR bstrEncodingFormat, int32 lSizeX, int32 lSizeY, int32 lBitDepth, BSTR* pbstrIconURL) mut => VT.[Friend]IconURL(&this, bstrEncodingFormat, lSizeX, lSizeY, lBitDepth, pbstrIconURL);

	public HRESULT get_Services(IUPnPServices** ppusServices) mut => VT.[Friend]get_Services(&this, ppusServices);
}

[CRepr]struct IUPnPDeviceDocumentAccess : IUnknown
{
	public new const Guid IID = .(0xe7772804, 0x3287, 0x418e, 0x90, 0x72, 0xcf, 0x2b, 0x47, 0x23, 0x89, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDocument) GetDocumentURL;
	}


	public HRESULT GetDocumentURL(BSTR* pbstrDocument) mut => VT.[Friend]GetDocumentURL(&this, pbstrDocument);
}

[CRepr]struct IUPnPDeviceDocumentAccessEx : IUnknown
{
	public new const Guid IID = .(0xc4bc4050, 0x6178, 0x4bd1, 0xa4, 0xb8, 0x63, 0x98, 0x32, 0x1f, 0x32, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDocument) GetDocument;
	}


	public HRESULT GetDocument(BSTR* pbstrDocument) mut => VT.[Friend]GetDocument(&this, pbstrDocument);
}

[CRepr]struct IUPnPDescriptionDocument : IDispatch
{
	public new const Guid IID = .(0x11d1c1b2, 0x7daa, 0x4c9e, 0x95, 0x95, 0x7f, 0x82, 0xed, 0x20, 0x6d, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plReadyState) get_ReadyState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl, IUnknown* punkCallback) LoadAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* phrError) get_LoadResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPDevice** ppudRootDevice) RootDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUDN, IUPnPDevice** ppudDevice) DeviceByUDN;
	}


	public HRESULT get_ReadyState(int32* plReadyState) mut => VT.[Friend]get_ReadyState(&this, plReadyState);

	public HRESULT Load(BSTR bstrUrl) mut => VT.[Friend]Load(&this, bstrUrl);

	public HRESULT LoadAsync(BSTR bstrUrl, IUnknown* punkCallback) mut => VT.[Friend]LoadAsync(&this, bstrUrl, punkCallback);

	public HRESULT get_LoadResult(int32* phrError) mut => VT.[Friend]get_LoadResult(&this, phrError);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);

	public HRESULT RootDevice(IUPnPDevice** ppudRootDevice) mut => VT.[Friend]RootDevice(&this, ppudRootDevice);

	public HRESULT DeviceByUDN(BSTR bstrUDN, IUPnPDevice** ppudDevice) mut => VT.[Friend]DeviceByUDN(&this, bstrUDN, ppudDevice);
}

[CRepr]struct IUPnPDeviceFinderAddCallbackWithInterface : IUnknown
{
	public new const Guid IID = .(0x983dfc0b, 0x1796, 0x44df, 0x89, 0x75, 0xca, 0x54, 0x5b, 0x62, 0x0e, 0xe5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFindData, IUPnPDevice* pDevice, Guid* pguidInterface) DeviceAddedWithInterface;
	}


	public HRESULT DeviceAddedWithInterface(int32 lFindData, IUPnPDevice* pDevice, Guid* pguidInterface) mut => VT.[Friend]DeviceAddedWithInterface(&this, lFindData, pDevice, pguidInterface);
}

[CRepr]struct IUPnPDescriptionDocumentCallback : IUnknown
{
	public new const Guid IID = .(0x77394c69, 0x5486, 0x40d6, 0x9b, 0xc3, 0x49, 0x91, 0x98, 0x3e, 0x02, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrLoadResult) LoadComplete;
	}


	public HRESULT LoadComplete(HRESULT hrLoadResult) mut => VT.[Friend]LoadComplete(&this, hrLoadResult);
}

[CRepr]struct IUPnPEventSink : IUnknown
{
	public new const Guid IID = .(0x204810b4, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cChanges, int32* rgdispidChanges) OnStateChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varsadispidChanges) OnStateChangedSafe;
	}


	public HRESULT OnStateChanged(uint32 cChanges, int32* rgdispidChanges) mut => VT.[Friend]OnStateChanged(&this, cChanges, rgdispidChanges);

	public HRESULT OnStateChangedSafe(VARIANT varsadispidChanges) mut => VT.[Friend]OnStateChangedSafe(&this, varsadispidChanges);
}

[CRepr]struct IUPnPEventSource : IUnknown
{
	public new const Guid IID = .(0x204810b5, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPEventSink* pesSubscriber) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUPnPEventSink* pesSubscriber) Unadvise;
	}


	public HRESULT Advise(IUPnPEventSink* pesSubscriber) mut => VT.[Friend]Advise(&this, pesSubscriber);

	public HRESULT Unadvise(IUPnPEventSink* pesSubscriber) mut => VT.[Friend]Unadvise(&this, pesSubscriber);
}

[CRepr]struct IUPnPRegistrar : IUnknown
{
	public new const Guid IID = .(0x204810b6, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrXMLDesc, BSTR bstrProgIDDeviceControlClass, BSTR bstrInitString, BSTR bstrContainerId, BSTR bstrResourcePath, int32 nLifeTime, BSTR* pbstrDeviceIdentifier) RegisterDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrXMLDesc, IUnknown* punkDeviceControl, BSTR bstrInitString, BSTR bstrResourcePath, int32 nLifeTime, BSTR* pbstrDeviceIdentifier) RegisterRunningDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProviderName, BSTR bstrProgIDProviderClass, BSTR bstrInitString, BSTR bstrContainerId) RegisterDeviceProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceIdentifier, BSTR bstrTemplateUDN, BSTR* pbstrUDN) GetUniqueDeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceIdentifier, BOOL fPermanent) UnregisterDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProviderName) UnregisterDeviceProvider;
	}


	public HRESULT RegisterDevice(BSTR bstrXMLDesc, BSTR bstrProgIDDeviceControlClass, BSTR bstrInitString, BSTR bstrContainerId, BSTR bstrResourcePath, int32 nLifeTime, BSTR* pbstrDeviceIdentifier) mut => VT.[Friend]RegisterDevice(&this, bstrXMLDesc, bstrProgIDDeviceControlClass, bstrInitString, bstrContainerId, bstrResourcePath, nLifeTime, pbstrDeviceIdentifier);

	public HRESULT RegisterRunningDevice(BSTR bstrXMLDesc, IUnknown* punkDeviceControl, BSTR bstrInitString, BSTR bstrResourcePath, int32 nLifeTime, BSTR* pbstrDeviceIdentifier) mut => VT.[Friend]RegisterRunningDevice(&this, bstrXMLDesc, punkDeviceControl, bstrInitString, bstrResourcePath, nLifeTime, pbstrDeviceIdentifier);

	public HRESULT RegisterDeviceProvider(BSTR bstrProviderName, BSTR bstrProgIDProviderClass, BSTR bstrInitString, BSTR bstrContainerId) mut => VT.[Friend]RegisterDeviceProvider(&this, bstrProviderName, bstrProgIDProviderClass, bstrInitString, bstrContainerId);

	public HRESULT GetUniqueDeviceName(BSTR bstrDeviceIdentifier, BSTR bstrTemplateUDN, BSTR* pbstrUDN) mut => VT.[Friend]GetUniqueDeviceName(&this, bstrDeviceIdentifier, bstrTemplateUDN, pbstrUDN);

	public HRESULT UnregisterDevice(BSTR bstrDeviceIdentifier, BOOL fPermanent) mut => VT.[Friend]UnregisterDevice(&this, bstrDeviceIdentifier, fPermanent);

	public HRESULT UnregisterDeviceProvider(BSTR bstrProviderName) mut => VT.[Friend]UnregisterDeviceProvider(&this, bstrProviderName);
}

[CRepr]struct IUPnPReregistrar : IUnknown
{
	public new const Guid IID = .(0x204810b7, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceIdentifier, BSTR bstrXMLDesc, BSTR bstrProgIDDeviceControlClass, BSTR bstrInitString, BSTR bstrContainerId, BSTR bstrResourcePath, int32 nLifeTime) ReregisterDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceIdentifier, BSTR bstrXMLDesc, IUnknown* punkDeviceControl, BSTR bstrInitString, BSTR bstrResourcePath, int32 nLifeTime) ReregisterRunningDevice;
	}


	public HRESULT ReregisterDevice(BSTR bstrDeviceIdentifier, BSTR bstrXMLDesc, BSTR bstrProgIDDeviceControlClass, BSTR bstrInitString, BSTR bstrContainerId, BSTR bstrResourcePath, int32 nLifeTime) mut => VT.[Friend]ReregisterDevice(&this, bstrDeviceIdentifier, bstrXMLDesc, bstrProgIDDeviceControlClass, bstrInitString, bstrContainerId, bstrResourcePath, nLifeTime);

	public HRESULT ReregisterRunningDevice(BSTR bstrDeviceIdentifier, BSTR bstrXMLDesc, IUnknown* punkDeviceControl, BSTR bstrInitString, BSTR bstrResourcePath, int32 nLifeTime) mut => VT.[Friend]ReregisterRunningDevice(&this, bstrDeviceIdentifier, bstrXMLDesc, punkDeviceControl, bstrInitString, bstrResourcePath, nLifeTime);
}

[CRepr]struct IUPnPDeviceControl : IUnknown
{
	public new const Guid IID = .(0x204810ba, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrXMLDesc, BSTR bstrDeviceIdentifier, BSTR bstrInitString) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUDN, BSTR bstrServiceId, IDispatch** ppdispService) GetServiceObject;
	}


	public HRESULT Initialize(BSTR bstrXMLDesc, BSTR bstrDeviceIdentifier, BSTR bstrInitString) mut => VT.[Friend]Initialize(&this, bstrXMLDesc, bstrDeviceIdentifier, bstrInitString);

	public HRESULT GetServiceObject(BSTR bstrUDN, BSTR bstrServiceId, IDispatch** ppdispService) mut => VT.[Friend]GetServiceObject(&this, bstrUDN, bstrServiceId, ppdispService);
}

[CRepr]struct IUPnPDeviceControlHttpHeaders : IUnknown
{
	public new const Guid IID = .(0x204810bb, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrHttpResponseHeaders) GetAdditionalResponseHeaders;
	}


	public HRESULT GetAdditionalResponseHeaders(BSTR* bstrHttpResponseHeaders) mut => VT.[Friend]GetAdditionalResponseHeaders(&this, bstrHttpResponseHeaders);
}

[CRepr]struct IUPnPDeviceProvider : IUnknown
{
	public new const Guid IID = .(0x204810b8, 0x73b2, 0x11d4, 0xbf, 0x42, 0x00, 0xb0, 0xd0, 0x11, 0x8b, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInitString) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
	}


	public HRESULT Start(BSTR bstrInitString) mut => VT.[Friend]Start(&this, bstrInitString);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);
}

[CRepr]struct IUPnPRemoteEndpointInfo : IUnknown
{
	public new const Guid IID = .(0xc92eb863, 0x0269, 0x4aff, 0x9c, 0x72, 0x75, 0x32, 0x1b, 0xba, 0x29, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrValueName, uint32* pdwValue) GetDwordValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrValueName, BSTR* pbstrValue) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrValueName, Guid* pguidValue) GetGuidValue;
	}


	public HRESULT GetDwordValue(BSTR bstrValueName, uint32* pdwValue) mut => VT.[Friend]GetDwordValue(&this, bstrValueName, pdwValue);

	public HRESULT GetStringValue(BSTR bstrValueName, BSTR* pbstrValue) mut => VT.[Friend]GetStringValue(&this, bstrValueName, pbstrValue);

	public HRESULT GetGuidValue(BSTR bstrValueName, Guid* pguidValue) mut => VT.[Friend]GetGuidValue(&this, bstrValueName, pguidValue);
}

#endregion

#region Functions
public static
{
	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDeviceCreate(PWSTR pszEnumeratorName, PWSTR pszParentDeviceInstance, SW_DEVICE_CREATE_INFO* pCreateInfo, uint32 cPropertyCount, DEVPROPERTY* pProperties, SW_DEVICE_CREATE_CALLBACK pCallback, void* pContext, int* phSwDevice);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SwDeviceClose(HSWDEVICE hSwDevice);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDeviceSetLifetime(HSWDEVICE hSwDevice, SW_DEVICE_LIFETIME Lifetime);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDeviceGetLifetime(HSWDEVICE hSwDevice, SW_DEVICE_LIFETIME* pLifetime);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDevicePropertySet(HSWDEVICE hSwDevice, uint32 cPropertyCount, DEVPROPERTY* pProperties);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDeviceInterfaceRegister(HSWDEVICE hSwDevice, in Guid pInterfaceClassGuid, PWSTR pszReferenceString, uint32 cPropertyCount, DEVPROPERTY* pProperties, BOOL fEnabled, PWSTR* ppszDeviceInterfaceId);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SwMemFree(void* pMem);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDeviceInterfaceSetState(HSWDEVICE hSwDevice, PWSTR pszDeviceInterfaceId, BOOL fEnabled);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SwDeviceInterfacePropertySet(HSWDEVICE hSwDevice, PWSTR pszDeviceInterfaceId, uint32 cPropertyCount, DEVPROPERTY* pProperties);

}
#endregion
