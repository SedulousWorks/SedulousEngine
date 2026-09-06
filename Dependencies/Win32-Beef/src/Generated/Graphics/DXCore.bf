using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Graphics.DXCore;

#region Constants
public static
{
	public const uint32 _FACDXCORE = 2176;
	public const Guid DXCORE_ADAPTER_ATTRIBUTE_D3D11_GRAPHICS = .(0x8c47866b, 0x7583, 0x450d, 0xf0, 0xf0, 0x6b, 0xad, 0xa8, 0x95, 0xaf, 0x4b);
	public const Guid DXCORE_ADAPTER_ATTRIBUTE_D3D12_GRAPHICS = .(0x0c9ece4d, 0x2f6e, 0x4f01, 0x8c, 0x96, 0xe8, 0x9e, 0x33, 0x1b, 0x47, 0xb1);
	public const Guid DXCORE_ADAPTER_ATTRIBUTE_D3D12_CORE_COMPUTE = .(0x248e2800, 0xa793, 0x4724, 0xab, 0xaa, 0x23, 0xa6, 0xde, 0x1b, 0xe0, 0x90);
}
#endregion

#region Enums

[AllowDuplicates]
public enum DXCoreAdapterProperty : uint32
{
	InstanceLuid = 0,
	DriverVersion = 1,
	DriverDescription = 2,
	HardwareID = 3,
	KmdModelVersion = 4,
	ComputePreemptionGranularity = 5,
	GraphicsPreemptionGranularity = 6,
	DedicatedAdapterMemory = 7,
	DedicatedSystemMemory = 8,
	SharedSystemMemory = 9,
	AcgCompatible = 10,
	IsHardware = 11,
	IsIntegrated = 12,
	IsDetachable = 13,
	HardwareIDParts = 14,
}


[AllowDuplicates]
public enum DXCoreAdapterState : uint32
{
	IsDriverUpdateInProgress = 0,
	AdapterMemoryBudget = 1,
}


[AllowDuplicates]
public enum DXCoreSegmentGroup : uint32
{
	Local = 0,
	NonLocal = 1,
}


[AllowDuplicates]
public enum DXCoreNotificationType : uint32
{
	AdapterListStale = 0,
	AdapterNoLongerValid = 1,
	AdapterBudgetChange = 2,
	AdapterHardwareContentProtectionTeardown = 3,
}


[AllowDuplicates]
public enum DXCoreAdapterPreference : uint32
{
	Hardware = 0,
	MinimumPower = 1,
	HighPerformance = 2,
}

#endregion

#region Function Pointers
public function void PFN_DXCORE_NOTIFICATION_CALLBACK(DXCoreNotificationType notificationType, IUnknown* object, void* context);

#endregion

#region Structs
[CRepr]
public struct DXCoreHardwareID
{
	public uint32 vendorID;
	public uint32 deviceID;
	public uint32 subSysID;
	public uint32 revision;
}

[CRepr]
public struct DXCoreHardwareIDParts
{
	public uint32 vendorID;
	public uint32 deviceID;
	public uint32 subSystemID;
	public uint32 subVendorID;
	public uint32 revisionID;
}

[CRepr]
public struct DXCoreAdapterMemoryBudgetNodeSegmentGroup
{
	public uint32 nodeIndex;
	public DXCoreSegmentGroup segmentGroup;
}

[CRepr]
public struct DXCoreAdapterMemoryBudget
{
	public uint64 budget;
	public uint64 currentUsage;
	public uint64 availableForReservation;
	public uint64 currentReservation;
}

#endregion

#region COM Types
[CRepr]struct IDXCoreAdapter : IUnknown
{
	public new const Guid IID = .(0xf0db4c7f, 0xfe5a, 0x42a2, 0xbd, 0x62, 0xf2, 0xa6, 0xcf, 0x6f, 0xc8, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsValid;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, in Guid attributeGUID) IsAttributeSupported;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, DXCoreAdapterProperty property) IsPropertySupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXCoreAdapterProperty property, uint bufferSize, void* propertyData) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXCoreAdapterProperty property, uint* bufferSize) GetPropertySize;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, DXCoreAdapterState property) IsQueryStateSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXCoreAdapterState state, uint inputStateDetailsSize, void* inputStateDetails, uint outputBufferSize, void* outputBuffer) QueryState;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, DXCoreAdapterState property) IsSetStateSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXCoreAdapterState state, uint inputStateDetailsSize, void* inputStateDetails, uint inputDataSize, void* inputData) SetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvFactory) GetFactory;
	}


	public bool IsValid() mut => VT.[Friend]IsValid(&this);

	public bool IsAttributeSupported(in Guid attributeGUID) mut => VT.[Friend]IsAttributeSupported(&this, attributeGUID);

	public bool IsPropertySupported(DXCoreAdapterProperty property) mut => VT.[Friend]IsPropertySupported(&this, property);

	public HRESULT GetProperty(DXCoreAdapterProperty property, uint bufferSize, void* propertyData) mut => VT.[Friend]GetProperty(&this, property, bufferSize, propertyData);

	public HRESULT GetPropertySize(DXCoreAdapterProperty property, uint* bufferSize) mut => VT.[Friend]GetPropertySize(&this, property, bufferSize);

	public bool IsQueryStateSupported(DXCoreAdapterState property) mut => VT.[Friend]IsQueryStateSupported(&this, property);

	public HRESULT QueryState(DXCoreAdapterState state, uint inputStateDetailsSize, void* inputStateDetails, uint outputBufferSize, void* outputBuffer) mut => VT.[Friend]QueryState(&this, state, inputStateDetailsSize, inputStateDetails, outputBufferSize, outputBuffer);

	public bool IsSetStateSupported(DXCoreAdapterState property) mut => VT.[Friend]IsSetStateSupported(&this, property);

	public HRESULT SetState(DXCoreAdapterState state, uint inputStateDetailsSize, void* inputStateDetails, uint inputDataSize, void* inputData) mut => VT.[Friend]SetState(&this, state, inputStateDetailsSize, inputStateDetails, inputDataSize, inputData);

	public HRESULT GetFactory(in Guid riid, void** ppvFactory) mut => VT.[Friend]GetFactory(&this, riid, ppvFactory);
}

[CRepr]struct IDXCoreAdapterList : IUnknown
{
	public new const Guid IID = .(0x526c7776, 0x40e9, 0x459b, 0xb7, 0x11, 0xf3, 0x2a, 0xd7, 0x6d, 0xfc, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid riid, void** ppvAdapter) GetAdapter;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetAdapterCount;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsStale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvFactory) GetFactory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 numPreferences, DXCoreAdapterPreference* preferences) Sort;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, DXCoreAdapterPreference preference) IsAdapterPreferenceSupported;
	}


	public HRESULT GetAdapter(uint32 index, in Guid riid, void** ppvAdapter) mut => VT.[Friend]GetAdapter(&this, index, riid, ppvAdapter);

	public uint32 GetAdapterCount() mut => VT.[Friend]GetAdapterCount(&this);

	public bool IsStale() mut => VT.[Friend]IsStale(&this);

	public HRESULT GetFactory(in Guid riid, void** ppvFactory) mut => VT.[Friend]GetFactory(&this, riid, ppvFactory);

	public HRESULT Sort(uint32 numPreferences, DXCoreAdapterPreference* preferences) mut => VT.[Friend]Sort(&this, numPreferences, preferences);

	public bool IsAdapterPreferenceSupported(DXCoreAdapterPreference preference) mut => VT.[Friend]IsAdapterPreferenceSupported(&this, preference);
}

[CRepr]struct IDXCoreAdapterFactory : IUnknown
{
	public new const Guid IID = .(0x78ee5945, 0xc36e, 0x4b13, 0xa6, 0x69, 0x00, 0x5d, 0xd1, 0x1c, 0x0f, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 numAttributes, Guid* filterAttributes, in Guid riid, void** ppvAdapterList) CreateAdapterList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LUID* adapterLUID, in Guid riid, void** ppvAdapter) GetAdapterByLuid;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, DXCoreNotificationType notificationType) IsNotificationTypeSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* dxCoreObject, DXCoreNotificationType notificationType, PFN_DXCORE_NOTIFICATION_CALLBACK callbackFunction, void* callbackContext, uint32* eventCookie) RegisterEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 eventCookie) UnregisterEventNotification;
	}


	public HRESULT CreateAdapterList(uint32 numAttributes, Guid* filterAttributes, in Guid riid, void** ppvAdapterList) mut => VT.[Friend]CreateAdapterList(&this, numAttributes, filterAttributes, riid, ppvAdapterList);

	public HRESULT GetAdapterByLuid(LUID* adapterLUID, in Guid riid, void** ppvAdapter) mut => VT.[Friend]GetAdapterByLuid(&this, adapterLUID, riid, ppvAdapter);

	public bool IsNotificationTypeSupported(DXCoreNotificationType notificationType) mut => VT.[Friend]IsNotificationTypeSupported(&this, notificationType);

	public HRESULT RegisterEventNotification(IUnknown* dxCoreObject, DXCoreNotificationType notificationType, PFN_DXCORE_NOTIFICATION_CALLBACK callbackFunction, void* callbackContext, uint32* eventCookie) mut => VT.[Friend]RegisterEventNotification(&this, dxCoreObject, notificationType, callbackFunction, callbackContext, eventCookie);

	public HRESULT UnregisterEventNotification(uint32 eventCookie) mut => VT.[Friend]UnregisterEventNotification(&this, eventCookie);
}

#endregion

#region Functions
public static
{
	[Import("DXCORE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DXCoreCreateAdapterFactory(in Guid riid, void** ppvFactory);

}
#endregion
