using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com.Marshal;
using System;

namespace Win32.System.WinRT;

#region Constants
public static
{
	public const uint32 MAX_ERROR_MESSAGE_CHARS = 512;
	public const String CastingSourceInfo_Property_PreferredSourceUriScheme = "PreferredSourceUriScheme";
	public const String CastingSourceInfo_Property_CastingTypes = "CastingTypes";
	public const String CastingSourceInfo_Property_ProtectedMedia = "ProtectedMedia";
}
#endregion

#region TypeDefs
typealias HSTRING = int;

typealias HSTRING_BUFFER = int;

typealias ROPARAMIIDHANDLE = int;

typealias APARTMENT_SHUTDOWN_REGISTRATION_COOKIE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum ACTIVATIONTYPE : int32
{
	ACTIVATIONTYPE_UNCATEGORIZED = 0,
	ACTIVATIONTYPE_FROM_MONIKER = 1,
	ACTIVATIONTYPE_FROM_DATA = 2,
	ACTIVATIONTYPE_FROM_STORAGE = 4,
	ACTIVATIONTYPE_FROM_STREAM = 8,
	ACTIVATIONTYPE_FROM_FILE = 16,
}


[AllowDuplicates]
public enum AgileReferenceOptions : int32
{
	AGILEREFERENCE_DEFAULT = 0,
	AGILEREFERENCE_DELAYEDMARSHAL = 1,
}


[AllowDuplicates]
public enum TrustLevel : int32
{
	BaseTrust = 0,
	PartialTrust = 1,
	FullTrust = 2,
}


[AllowDuplicates]
public enum DISPATCHERQUEUE_THREAD_APARTMENTTYPE : int32
{
	DQTAT_COM_NONE = 0,
	DQTAT_COM_ASTA = 1,
	DQTAT_COM_STA = 2,
}


[AllowDuplicates]
public enum DISPATCHERQUEUE_THREAD_TYPE : int32
{
	DQTYPE_THREAD_DEDICATED = 1,
	DQTYPE_THREAD_CURRENT = 2,
}


[AllowDuplicates]
public enum CASTING_CONNECTION_ERROR_STATUS : int32
{
	CASTING_CONNECTION_ERROR_STATUS_SUCCEEDED = 0,
	CASTING_CONNECTION_ERROR_STATUS_DEVICE_DID_NOT_RESPOND = 1,
	CASTING_CONNECTION_ERROR_STATUS_DEVICE_ERROR = 2,
	CASTING_CONNECTION_ERROR_STATUS_DEVICE_LOCKED = 3,
	CASTING_CONNECTION_ERROR_STATUS_PROTECTED_PLAYBACK_FAILED = 4,
	CASTING_CONNECTION_ERROR_STATUS_INVALID_CASTING_SOURCE = 5,
	CASTING_CONNECTION_ERROR_STATUS_UNKNOWN = 6,
}


[AllowDuplicates]
public enum CASTING_CONNECTION_STATE : int32
{
	CASTING_CONNECTION_STATE_DISCONNECTED = 0,
	CASTING_CONNECTION_STATE_CONNECTED = 1,
	CASTING_CONNECTION_STATE_RENDERING = 2,
	CASTING_CONNECTION_STATE_DISCONNECTING = 3,
	CASTING_CONNECTION_STATE_CONNECTING = 4,
}


[AllowDuplicates]
public enum RO_INIT_TYPE : int32
{
	RO_INIT_SINGLETHREADED = 0,
	RO_INIT_MULTITHREADED = 1,
}


[AllowDuplicates]
public enum RO_ERROR_REPORTING_FLAGS : uint32
{
	RO_ERROR_REPORTING_NONE = 0,
	RO_ERROR_REPORTING_SUPPRESSEXCEPTIONS = 1,
	RO_ERROR_REPORTING_FORCEEXCEPTIONS = 2,
	RO_ERROR_REPORTING_USESETERRORINFO = 4,
	RO_ERROR_REPORTING_SUPPRESSSETERRORINFO = 8,
}


[AllowDuplicates]
public enum BSOS_OPTIONS : int32
{
	BSOS_DEFAULT = 0,
	BSOS_PREFERDESTINATIONSTREAM = 1,
}

#endregion

#region Function Pointers
public function HRESULT PINSPECT_HSTRING_CALLBACK(void* context, uint readAddress, uint32 length, uint8* buffer);

public function HRESULT PINSPECT_HSTRING_CALLBACK2(void* context, uint64 readAddress, uint32 length, uint8* buffer);

public function HRESULT PINSPECT_MEMORY_CALLBACK(void* context, uint readAddress, uint32 length, uint8* buffer);

#endregion

#region Structs
[CRepr]
public struct EventRegistrationToken
{
	public int64 value;
}

[CRepr]
public struct HSTRING_HEADER
{
	public uint32 flags;
	public uint32 length;
	public uint32 padding1;
	public uint32 padding2;
	public int data;
}

[CRepr]
public struct ServerInformation
{
	public uint32 dwServerPid;
	public uint32 dwServerTid;
	public uint64 ui64ServerAddress;
}

[CRepr]
public struct DispatcherQueueOptions
{
	public uint32 dwSize;
	public DISPATCHERQUEUE_THREAD_TYPE threadType;
	public DISPATCHERQUEUE_THREAD_APARTMENTTYPE apartmentType;
}

[CRepr]
public struct _RO_REGISTRATION_COOKIE
{
}

#endregion

#region COM Types
[CRepr]struct IAgileReference : IUnknown
{
	public new const Guid IID = .(0xc03f6a43, 0x65a4, 0x9818, 0x98, 0x7e, 0xe0, 0xb8, 0x10, 0xd2, 0xa6, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvObjectReference) Resolve;
	}


	public HRESULT Resolve(in Guid riid, void** ppvObjectReference) mut => VT.[Friend]Resolve(&this, riid, ppvObjectReference);
}

[CRepr]struct IApartmentShutdown : IUnknown
{
	public new const Guid IID = .(0xa2f05a09, 0x27a2, 0x42b5, 0xbc, 0x0e, 0xac, 0x16, 0x3e, 0xf4, 0x9d, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint64 ui64ApartmentIdentifier) OnUninitialize;
	}


	public void OnUninitialize(uint64 ui64ApartmentIdentifier) mut => VT.[Friend]OnUninitialize(&this, ui64ApartmentIdentifier);
}

[CRepr]struct ISpatialInteractionManagerInterop : IInspectable
{
	public new const Guid IID = .(0x5c4ee536, 0x6a98, 0x4b86, 0xa1, 0x70, 0x58, 0x70, 0x13, 0xd6, 0xfd, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, in Guid riid, void** spatialInteractionManager) GetForWindow;
	}


	public HRESULT GetForWindow(HWND window, in Guid riid, void** spatialInteractionManager) mut => VT.[Friend]GetForWindow(&this, window, riid, spatialInteractionManager);
}

[CRepr]struct IHolographicSpaceInterop : IInspectable
{
	public new const Guid IID = .(0x5c4ee536, 0x6a98, 0x4b86, 0xa1, 0x70, 0x58, 0x70, 0x13, 0xd6, 0xfd, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, in Guid riid, void** holographicSpace) CreateForWindow;
	}


	public HRESULT CreateForWindow(HWND window, in Guid riid, void** holographicSpace) mut => VT.[Friend]CreateForWindow(&this, window, riid, holographicSpace);
}

[CRepr]struct IInspectable : IUnknown
{
	public new const Guid IID = .(0xaf86e2e0, 0xb12d, 0x4c6a, 0x9c, 0x5a, 0xd7, 0xaa, 0x65, 0x10, 0x1e, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* iidCount, Guid** iids) GetIids;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING* className) GetRuntimeClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TrustLevel* trustLevel) GetTrustLevel;
	}


	public HRESULT GetIids(uint32* iidCount, Guid** iids) mut => VT.[Friend]GetIids(&this, iidCount, iids);

	public HRESULT GetRuntimeClassName(HSTRING* className) mut => VT.[Friend]GetRuntimeClassName(&this, className);

	public HRESULT GetTrustLevel(TrustLevel* trustLevel) mut => VT.[Friend]GetTrustLevel(&this, trustLevel);
}

[CRepr]struct IAccountsSettingsPaneInterop : IInspectable
{
	public new const Guid IID = .(0xd3ee12ad, 0x3865, 0x4362, 0x97, 0x46, 0xb7, 0x5a, 0x68, 0x2d, 0xf0, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** accountsSettingsPane) GetForWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** asyncAction) ShowManageAccountsForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** asyncAction) ShowAddAccountForWindowAsync;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** accountsSettingsPane) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, accountsSettingsPane);

	public HRESULT ShowManageAccountsForWindowAsync(HWND appWindow, in Guid riid, void** asyncAction) mut => VT.[Friend]ShowManageAccountsForWindowAsync(&this, appWindow, riid, asyncAction);

	public HRESULT ShowAddAccountForWindowAsync(HWND appWindow, in Guid riid, void** asyncAction) mut => VT.[Friend]ShowAddAccountForWindowAsync(&this, appWindow, riid, asyncAction);
}

[CRepr]struct IAppServiceConnectionExtendedExecution : IUnknown
{
	public new const Guid IID = .(0x65219584, 0xf9cb, 0x4ae3, 0x81, 0xf9, 0xa2, 0x8a, 0x6c, 0xa4, 0x50, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** operation) OpenForExtendedExecutionAsync;
	}


	public HRESULT OpenForExtendedExecutionAsync(in Guid riid, void** operation) mut => VT.[Friend]OpenForExtendedExecutionAsync(&this, riid, operation);
}

[CRepr]struct ICorrelationVectorSource : IUnknown
{
	public new const Guid IID = .(0x152b8a3b, 0xb9b9, 0x4685, 0xb5, 0x6e, 0x97, 0x48, 0x47, 0xbc, 0x75, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING* cv) get_CorrelationVector;
	}


	public HRESULT get_CorrelationVector(HSTRING* cv) mut => VT.[Friend]get_CorrelationVector(&this, cv);
}

[CRepr]struct ICastingEventHandler : IUnknown
{
	public new const Guid IID = .(0xc79a6cb7, 0xbebd, 0x47a6, 0xa2, 0xad, 0x4d, 0x45, 0xad, 0x79, 0xc7, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CASTING_CONNECTION_STATE newState) OnStateChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CASTING_CONNECTION_ERROR_STATUS errorStatus, PWSTR errorMessage) OnError;
	}


	public HRESULT OnStateChanged(CASTING_CONNECTION_STATE newState) mut => VT.[Friend]OnStateChanged(&this, newState);

	public HRESULT OnError(CASTING_CONNECTION_ERROR_STATUS errorStatus, PWSTR errorMessage) mut => VT.[Friend]OnError(&this, errorStatus, errorMessage);
}

[CRepr]struct ICastingController : IUnknown
{
	public new const Guid IID = .(0xf0a56423, 0xa664, 0x4fbd, 0x8b, 0x43, 0x40, 0x9a, 0x45, 0xe8, 0xd9, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* castingEngine, IUnknown* castingSource) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICastingEventHandler* eventHandler, uint32* cookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie) UnAdvise;
	}


	public HRESULT Initialize(IUnknown* castingEngine, IUnknown* castingSource) mut => VT.[Friend]Initialize(&this, castingEngine, castingSource);

	public HRESULT Connect() mut => VT.[Friend]Connect(&this);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT Advise(ICastingEventHandler* eventHandler, uint32* cookie) mut => VT.[Friend]Advise(&this, eventHandler, cookie);

	public HRESULT UnAdvise(uint32 cookie) mut => VT.[Friend]UnAdvise(&this, cookie);
}

[CRepr]struct ICastingSourceInfo : IUnknown
{
	public new const Guid IID = .(0x45101ab7, 0x7c3a, 0x4bce, 0x95, 0x00, 0x12, 0xc0, 0x90, 0x24, 0xb2, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICastingController** controller) GetController;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INamedPropertyStore** props) GetProperties;
	}


	public HRESULT GetController(ICastingController** controller) mut => VT.[Friend]GetController(&this, controller);

	public HRESULT GetProperties(INamedPropertyStore** props) mut => VT.[Friend]GetProperties(&this, props);
}

[CRepr]struct IDragDropManagerInterop : IInspectable
{
	public new const Guid IID = .(0x5ad8cba7, 0x4c01, 0x4dac, 0x90, 0x74, 0x82, 0x78, 0x94, 0x29, 0x2d, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, in Guid riid, void** ppv) GetForWindow;
	}


	public HRESULT GetForWindow(HWND hwnd, in Guid riid, void** ppv) mut => VT.[Friend]GetForWindow(&this, hwnd, riid, ppv);
}

[CRepr]struct IInputPaneInterop : IInspectable
{
	public new const Guid IID = .(0x75cf2c57, 0x9195, 0x4931, 0x83, 0x32, 0xf0, 0xb4, 0x09, 0xe9, 0x16, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** inputPane) GetForWindow;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** inputPane) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, inputPane);
}

[CRepr]struct IPlayToManagerInterop : IInspectable
{
	public new const Guid IID = .(0x24394699, 0x1f2c, 0x4eb3, 0x8c, 0xd7, 0x0e, 0xc1, 0xda, 0x42, 0xa5, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** playToManager) GetForWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow) ShowPlayToUIForWindow;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** playToManager) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, playToManager);

	public HRESULT ShowPlayToUIForWindow(HWND appWindow) mut => VT.[Friend]ShowPlayToUIForWindow(&this, appWindow);
}

[CRepr]struct ICorrelationVectorInformation : IInspectable
{
	public new const Guid IID = .(0x83c78b3c, 0xd88b, 0x4950, 0xaa, 0x6e, 0x22, 0xb8, 0xd2, 0x2a, 0xab, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING* cv) get_LastCorrelationVectorForThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING* cv) get_NextCorrelationVectorForThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING cv) put_NextCorrelationVectorForThread;
	}


	public HRESULT get_LastCorrelationVectorForThread(HSTRING* cv) mut => VT.[Friend]get_LastCorrelationVectorForThread(&this, cv);

	public HRESULT get_NextCorrelationVectorForThread(HSTRING* cv) mut => VT.[Friend]get_NextCorrelationVectorForThread(&this, cv);

	public HRESULT put_NextCorrelationVectorForThread(HSTRING cv) mut => VT.[Friend]put_NextCorrelationVectorForThread(&this, cv);
}

[CRepr]struct IUIViewSettingsInterop : IInspectable
{
	public new const Guid IID = .(0x3694dbf9, 0x8f68, 0x44be, 0x8f, 0xf5, 0x19, 0x5c, 0x98, 0xed, 0xe8, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, in Guid riid, void** ppv) GetForWindow;
	}


	public HRESULT GetForWindow(HWND hwnd, in Guid riid, void** ppv) mut => VT.[Friend]GetForWindow(&this, hwnd, riid, ppv);
}

[CRepr]struct IUserActivityInterop : IInspectable
{
	public new const Guid IID = .(0x1ade314d, 0x0e0a, 0x40d9, 0x82, 0x4c, 0x9a, 0x08, 0x8a, 0x50, 0x05, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, in Guid iid, void** value) CreateSessionForWindow;
	}


	public HRESULT CreateSessionForWindow(HWND window, in Guid iid, void** value) mut => VT.[Friend]CreateSessionForWindow(&this, window, iid, value);
}

[CRepr]struct IUserActivitySourceHostInterop : IInspectable
{
	public new const Guid IID = .(0xc15df8bc, 0x8844, 0x487a, 0xb8, 0x5b, 0x75, 0x78, 0xe0, 0xf6, 0x14, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING activitySourceHost) SetActivitySourceHost;
	}


	public HRESULT SetActivitySourceHost(HSTRING activitySourceHost) mut => VT.[Friend]SetActivitySourceHost(&this, activitySourceHost);
}

[CRepr]struct IUserActivityRequestManagerInterop : IInspectable
{
	public new const Guid IID = .(0xdd69f876, 0x9699, 0x4715, 0x90, 0x95, 0xe3, 0x7e, 0xa3, 0x0d, 0xfa, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, in Guid iid, void** value) GetForWindow;
	}


	public HRESULT GetForWindow(HWND window, in Guid iid, void** value) mut => VT.[Friend]GetForWindow(&this, window, iid, value);
}

[CRepr]struct IUserConsentVerifierInterop : IInspectable
{
	public new const Guid IID = .(0x39e050c3, 0x4e74, 0x441a, 0x8d, 0xc0, 0xb8, 0x11, 0x04, 0xdf, 0x94, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING message, in Guid riid, void** asyncOperation) RequestVerificationForWindowAsync;
	}


	public HRESULT RequestVerificationForWindowAsync(HWND appWindow, HSTRING message, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestVerificationForWindowAsync(&this, appWindow, message, riid, asyncOperation);
}

[CRepr]struct IWebAuthenticationCoreManagerInterop : IInspectable
{
	public new const Guid IID = .(0xf4b8e804, 0x811e, 0x4436, 0xb6, 0x9c, 0x44, 0xcb, 0x67, 0xb7, 0x20, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IInspectable* request, in Guid riid, void** asyncInfo) RequestTokenForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IInspectable* request, IInspectable* webAccount, in Guid riid, void** asyncInfo) RequestTokenWithWebAccountForWindowAsync;
	}


	public HRESULT RequestTokenForWindowAsync(HWND appWindow, IInspectable* request, in Guid riid, void** asyncInfo) mut => VT.[Friend]RequestTokenForWindowAsync(&this, appWindow, request, riid, asyncInfo);

	public HRESULT RequestTokenWithWebAccountForWindowAsync(HWND appWindow, IInspectable* request, IInspectable* webAccount, in Guid riid, void** asyncInfo) mut => VT.[Friend]RequestTokenWithWebAccountForWindowAsync(&this, appWindow, request, webAccount, riid, asyncInfo);
}

[CRepr]struct IRestrictedErrorInfo : IUnknown
{
	public new const Guid IID = .(0x82ba7092, 0x4c88, 0x427d, 0xa7, 0xbc, 0x16, 0xdd, 0x93, 0xfe, 0xb6, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description, HRESULT* error, BSTR* restrictedDescription, BSTR* capabilitySid) GetErrorDetails;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* reference) GetReference;
	}


	public HRESULT GetErrorDetails(BSTR* description, HRESULT* error, BSTR* restrictedDescription, BSTR* capabilitySid) mut => VT.[Friend]GetErrorDetails(&this, description, error, restrictedDescription, capabilitySid);

	public HRESULT GetReference(BSTR* reference) mut => VT.[Friend]GetReference(&this, reference);
}

[CRepr]struct ILanguageExceptionErrorInfo : IUnknown
{
	public new const Guid IID = .(0x04a2dbf3, 0xdf83, 0x116c, 0x09, 0x46, 0x08, 0x12, 0xab, 0xf6, 0xe0, 0x7d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** languageException) GetLanguageException;
	}


	public HRESULT GetLanguageException(IUnknown** languageException) mut => VT.[Friend]GetLanguageException(&this, languageException);
}

[CRepr]struct ILanguageExceptionTransform : IUnknown
{
	public new const Guid IID = .(0xfeb5a271, 0xa6cd, 0x45ce, 0x88, 0x0a, 0x69, 0x67, 0x06, 0xba, 0xdc, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRestrictedErrorInfo** restrictedErrorInfo) GetTransformedRestrictedErrorInfo;
	}


	public HRESULT GetTransformedRestrictedErrorInfo(IRestrictedErrorInfo** restrictedErrorInfo) mut => VT.[Friend]GetTransformedRestrictedErrorInfo(&this, restrictedErrorInfo);
}

[CRepr]struct ILanguageExceptionStackBackTrace : IUnknown
{
	public new const Guid IID = .(0xcbe53fb5, 0xf967, 0x4258, 0x8d, 0x34, 0x42, 0xf5, 0xe2, 0x58, 0x33, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 maxFramesToCapture, uint* stackBackTrace, uint32* framesCaptured) GetStackBackTrace;
	}


	public HRESULT GetStackBackTrace(uint32 maxFramesToCapture, uint* stackBackTrace, uint32* framesCaptured) mut => VT.[Friend]GetStackBackTrace(&this, maxFramesToCapture, stackBackTrace, framesCaptured);
}

[CRepr]struct ILanguageExceptionErrorInfo2 : ILanguageExceptionErrorInfo
{
	public new const Guid IID = .(0x5746e5c4, 0x5b97, 0x424c, 0xb6, 0x20, 0x28, 0x22, 0x91, 0x57, 0x34, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ILanguageExceptionErrorInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILanguageExceptionErrorInfo2** previousLanguageExceptionErrorInfo) GetPreviousLanguageExceptionErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* languageException) CapturePropagationContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILanguageExceptionErrorInfo2** propagatedLanguageExceptionErrorInfoHead) GetPropagationContextHead;
	}


	public HRESULT GetPreviousLanguageExceptionErrorInfo(ILanguageExceptionErrorInfo2** previousLanguageExceptionErrorInfo) mut => VT.[Friend]GetPreviousLanguageExceptionErrorInfo(&this, previousLanguageExceptionErrorInfo);

	public HRESULT CapturePropagationContext(IUnknown* languageException) mut => VT.[Friend]CapturePropagationContext(&this, languageException);

	public HRESULT GetPropagationContextHead(ILanguageExceptionErrorInfo2** propagatedLanguageExceptionErrorInfoHead) mut => VT.[Friend]GetPropagationContextHead(&this, propagatedLanguageExceptionErrorInfoHead);
}

[CRepr]struct IActivationFactory : IInspectable
{
	public new const Guid IID = .(0x00000035, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable** instance) ActivateInstance;
	}


	public HRESULT ActivateInstance(IInspectable** instance) mut => VT.[Friend]ActivateInstance(&this, instance);
}

[CRepr]struct IBufferByteAccess : IUnknown
{
	public new const Guid IID = .(0x905a0fef, 0xbc53, 0x11df, 0x8c, 0x49, 0x00, 0x1e, 0x4f, 0xc6, 0x86, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** value) Buffer;
	}


	public HRESULT Buffer(uint8** value) mut => VT.[Friend]Buffer(&this, value);
}

[CRepr]struct IRoSimpleMetaDataBuilder
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid iid) SetWinRtInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid iid) SetDelegate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, PWSTR defaultInterfaceName, Guid* defaultInterfaceIID) SetInterfaceGroupSimpleDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, uint32 elementCount, PWSTR* defaultInterfaceNameElements) SetInterfaceGroupParameterizedDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, PWSTR defaultInterfaceName, Guid* defaultInterfaceIID) SetRuntimeClassSimpleDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, uint32 elementCount, PWSTR* defaultInterfaceNameElements) SetRuntimeClassParameterizedDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, uint32 numFields, PWSTR* fieldTypeNames) SetStruct;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, PWSTR baseType) SetEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid piid, uint32 numArgs) SetParameterizedInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid piid, uint32 numArgs) SetParameterizedDelegate;
	}


	public HRESULT SetWinRtInterface(Guid iid) mut => VT.[Friend]SetWinRtInterface(&this, iid);

	public HRESULT SetDelegate(Guid iid) mut => VT.[Friend]SetDelegate(&this, iid);

	public HRESULT SetInterfaceGroupSimpleDefault(PWSTR name, PWSTR defaultInterfaceName, Guid* defaultInterfaceIID) mut => VT.[Friend]SetInterfaceGroupSimpleDefault(&this, name, defaultInterfaceName, defaultInterfaceIID);

	public HRESULT SetInterfaceGroupParameterizedDefault(PWSTR name, uint32 elementCount, PWSTR* defaultInterfaceNameElements) mut => VT.[Friend]SetInterfaceGroupParameterizedDefault(&this, name, elementCount, defaultInterfaceNameElements);

	public HRESULT SetRuntimeClassSimpleDefault(PWSTR name, PWSTR defaultInterfaceName, Guid* defaultInterfaceIID) mut => VT.[Friend]SetRuntimeClassSimpleDefault(&this, name, defaultInterfaceName, defaultInterfaceIID);

	public HRESULT SetRuntimeClassParameterizedDefault(PWSTR name, uint32 elementCount, PWSTR* defaultInterfaceNameElements) mut => VT.[Friend]SetRuntimeClassParameterizedDefault(&this, name, elementCount, defaultInterfaceNameElements);

	public HRESULT SetStruct(PWSTR name, uint32 numFields, PWSTR* fieldTypeNames) mut => VT.[Friend]SetStruct(&this, name, numFields, fieldTypeNames);

	public HRESULT SetEnum(PWSTR name, PWSTR baseType) mut => VT.[Friend]SetEnum(&this, name, baseType);

	public HRESULT SetParameterizedInterface(Guid piid, uint32 numArgs) mut => VT.[Friend]SetParameterizedInterface(&this, piid, numArgs);

	public HRESULT SetParameterizedDelegate(Guid piid, uint32 numArgs) mut => VT.[Friend]SetParameterizedDelegate(&this, piid, numArgs);
}

[CRepr]struct IRoMetaDataLocator
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR nameElement, IRoSimpleMetaDataBuilder* metaDataDestination) Locate;
	}


	public HRESULT Locate(PWSTR nameElement, IRoSimpleMetaDataBuilder* metaDataDestination) mut => VT.[Friend]Locate(&this, nameElement, metaDataDestination);
}

[CRepr]struct IMemoryBufferByteAccess : IUnknown
{
	public new const Guid IID = .(0x5b0d3235, 0x4dba, 0x4d44, 0x86, 0x5e, 0x8f, 0x1d, 0x0e, 0x4f, 0xd0, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** value, uint32* capacity) GetBuffer;
	}


	public HRESULT GetBuffer(uint8** value, uint32* capacity) mut => VT.[Friend]GetBuffer(&this, value, capacity);
}

[CRepr]struct IWeakReference : IUnknown
{
	public new const Guid IID = .(0x00000037, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** objectReference) Resolve;
	}


	public HRESULT Resolve(in Guid riid, void** objectReference) mut => VT.[Friend]Resolve(&this, riid, objectReference);
}

[CRepr]struct IWeakReferenceSource : IUnknown
{
	public new const Guid IID = .(0x00000038, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWeakReference** weakReference) GetWeakReference;
	}


	public HRESULT GetWeakReference(IWeakReference** weakReference) mut => VT.[Friend]GetWeakReference(&this, weakReference);
}

[CRepr]struct ISystemMediaTransportControlsInterop : IInspectable
{
	public new const Guid IID = .(0xddb0472d, 0xc911, 0x4a1f, 0x86, 0xd9, 0xdc, 0x3d, 0x71, 0xa9, 0x5f, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** mediaTransportControl) GetForWindow;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** mediaTransportControl) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, mediaTransportControl);
}

[CRepr]struct IShareWindowCommandEventArgsInterop : IUnknown
{
	public new const Guid IID = .(0x6571a721, 0x643d, 0x43d4, 0xac, 0xa4, 0x6b, 0x6f, 0x5f, 0x30, 0xf1, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* value) GetWindow;
	}


	public HRESULT GetWindow(HWND* value) mut => VT.[Friend]GetWindow(&this, value);
}

[CRepr]struct IShareWindowCommandSourceInterop : IUnknown
{
	public new const Guid IID = .(0x461a191f, 0x8424, 0x43a6, 0xa0, 0xfa, 0x34, 0x51, 0xa2, 0x2f, 0x56, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** shareWindowCommandSource) GetForWindow;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** shareWindowCommandSource) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, shareWindowCommandSource);
}

[CRepr]struct IMessageDispatcher : IInspectable
{
	public new const Guid IID = .(0xf5f84c8f, 0xcfd0, 0x4cd6, 0xb6, 0x6b, 0xc5, 0xd2, 0x6f, 0xf1, 0x68, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PumpMessages;
	}


	public HRESULT PumpMessages() mut => VT.[Friend]PumpMessages(&this);
}

[CRepr]struct ICoreWindowInterop : IUnknown
{
	public new const Guid IID = .(0x45d64a29, 0xa63e, 0x4cb6, 0xb4, 0x98, 0x57, 0x81, 0xd2, 0x98, 0xcb, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* hwnd) get_WindowHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 value) put_MessageHandled;
	}


	public HRESULT get_WindowHandle(HWND* hwnd) mut => VT.[Friend]get_WindowHandle(&this, hwnd);

	public HRESULT put_MessageHandled(uint8 value) mut => VT.[Friend]put_MessageHandled(&this, value);
}

[CRepr]struct ICoreInputInterop : IUnknown
{
	public new const Guid IID = .(0x40bfe3e3, 0xb75a, 0x4479, 0xac, 0x96, 0x47, 0x53, 0x65, 0x74, 0x9b, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* value) SetInputSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 value) put_MessageHandled;
	}


	public HRESULT SetInputSource(IUnknown* value) mut => VT.[Friend]SetInputSource(&this, value);

	public HRESULT put_MessageHandled(uint8 value) mut => VT.[Friend]put_MessageHandled(&this, value);
}

[CRepr]struct ICoreWindowComponentInterop : IUnknown
{
	public new const Guid IID = .(0x0576ab31, 0xa310, 0x4c40, 0xba, 0x31, 0xfd, 0x37, 0xe0, 0x29, 0x8d, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hostViewInstanceId, HWND hwndHost, IUnknown* inputSourceVisual) ConfigureComponentInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* componentViewInstanceId) GetViewInstanceId;
	}


	public HRESULT ConfigureComponentInput(uint32 hostViewInstanceId, HWND hwndHost, IUnknown* inputSourceVisual) mut => VT.[Friend]ConfigureComponentInput(&this, hostViewInstanceId, hwndHost, inputSourceVisual);

	public HRESULT GetViewInstanceId(uint32* componentViewInstanceId) mut => VT.[Friend]GetViewInstanceId(&this, componentViewInstanceId);
}

[CRepr]struct ICoreWindowAdapterInterop : IInspectable
{
	public new const Guid IID = .(0x7a5b6fd1, 0xcd73, 0x4b6c, 0x9c, 0xf4, 0x2e, 0x86, 0x9e, 0xaf, 0x47, 0x0a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_AppActivationClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_ApplicationViewClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_CoreApplicationViewClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_HoloViewClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_PositionerClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_SystemNavigationClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) get_TitleBarClientAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* value) SetWindowClientAdapter;
	}


	public HRESULT get_AppActivationClientAdapter(IUnknown** value) mut => VT.[Friend]get_AppActivationClientAdapter(&this, value);

	public HRESULT get_ApplicationViewClientAdapter(IUnknown** value) mut => VT.[Friend]get_ApplicationViewClientAdapter(&this, value);

	public HRESULT get_CoreApplicationViewClientAdapter(IUnknown** value) mut => VT.[Friend]get_CoreApplicationViewClientAdapter(&this, value);

	public HRESULT get_HoloViewClientAdapter(IUnknown** value) mut => VT.[Friend]get_HoloViewClientAdapter(&this, value);

	public HRESULT get_PositionerClientAdapter(IUnknown** value) mut => VT.[Friend]get_PositionerClientAdapter(&this, value);

	public HRESULT get_SystemNavigationClientAdapter(IUnknown** value) mut => VT.[Friend]get_SystemNavigationClientAdapter(&this, value);

	public HRESULT get_TitleBarClientAdapter(IUnknown** value) mut => VT.[Friend]get_TitleBarClientAdapter(&this, value);

	public HRESULT SetWindowClientAdapter(IUnknown* value) mut => VT.[Friend]SetWindowClientAdapter(&this, value);
}

#endregion

#region Functions
public static
{
	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoDecodeProxy(uint32 dwClientPid, uint64 ui64ProxyAddress, ServerInformation* pServerInformation);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetAgileReference(AgileReferenceOptions options, in Guid riid, IUnknown* pUnk, IAgileReference** ppAgileReference);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HSTRING_UserSize(uint32* param0, uint32 param1, HSTRING* param2);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HSTRING_UserMarshal(uint32* param0, uint8* param1, HSTRING* param2);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HSTRING_UserUnmarshal(uint32* param0, uint8* param1, HSTRING* param2);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HSTRING_UserFree(uint32* param0, HSTRING* param1);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HSTRING_UserSize64(uint32* param0, uint32 param1, HSTRING* param2);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HSTRING_UserMarshal64(uint32* param0, uint8* param1, HSTRING* param2);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HSTRING_UserUnmarshal64(uint32* param0, uint8* param1, HSTRING* param2);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HSTRING_UserFree64(uint32* param0, HSTRING* param1);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsCreateString(char16* sourceString, uint32 length, HSTRING* string);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsCreateStringReference(PWSTR sourceString, uint32 length, HSTRING_HEADER* hstringHeader, HSTRING* string);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsDeleteString(HSTRING string);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsDuplicateString(HSTRING string, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WindowsGetStringLen(HSTRING string);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR WindowsGetStringRawBuffer(HSTRING string, uint32* length);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WindowsIsStringEmpty(HSTRING string);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsStringHasEmbeddedNull(HSTRING string, BOOL* hasEmbedNull);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsCompareStringOrdinal(HSTRING string1, HSTRING string2, int32* result);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsSubstring(HSTRING string, uint32 startIndex, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsSubstringWithSpecifiedLength(HSTRING string, uint32 startIndex, uint32 length, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsConcatString(HSTRING string1, HSTRING string2, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsReplaceString(HSTRING string, HSTRING stringReplaced, HSTRING stringReplaceWith, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsTrimStringStart(HSTRING string, HSTRING trimString, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsTrimStringEnd(HSTRING string, HSTRING trimString, HSTRING* newString);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsPreallocateStringBuffer(uint32 length, uint16** charBuffer, HSTRING_BUFFER* bufferHandle);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsPromoteStringBuffer(HSTRING_BUFFER bufferHandle, HSTRING* string);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsDeleteStringBuffer(HSTRING_BUFFER bufferHandle);

	[Import("api-ms-win-core-winrt-string-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsInspectString(uint targetHString, uint16 machine, PINSPECT_HSTRING_CALLBACK callback, void* context, uint32* length, uint* targetStringAddress);

	[Import("api-ms-win-core-winrt-string-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WindowsInspectString2(uint64 targetHString, uint16 machine, PINSPECT_HSTRING_CALLBACK2 callback, void* context, uint32* length, uint64* targetStringAddress);

	[Import("CoreMessaging.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDispatcherQueueController(DispatcherQueueOptions options, void** dispatcherQueueController);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoInitialize(RO_INIT_TYPE initType);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RoUninitialize();

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoActivateInstance(HSTRING activatableClassId, IInspectable** instance);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoRegisterActivationFactories(HSTRING* activatableClassIds, int* activationFactoryCallbacks, uint32 count, int* cookie);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RoRevokeActivationFactories(int cookie);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetActivationFactory(HSTRING activatableClassId, in Guid iid, void** factory);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoRegisterForApartmentShutdown(IApartmentShutdown* callbackObject, uint64* apartmentIdentifier, APARTMENT_SHUTDOWN_REGISTRATION_COOKIE* regCookie);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoUnregisterForApartmentShutdown(APARTMENT_SHUTDOWN_REGISTRATION_COOKIE regCookie);

	[Import("api-ms-win-core-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetApartmentIdentifier(uint64* apartmentIdentifier);

	[Import("api-ms-win-core-winrt-robuffer-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetBufferMarshaler(IMarshal** bufferMarshaler);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetErrorReportingFlags(uint32* pflags);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoSetErrorReportingFlags(uint32 flags);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoResolveRestrictedErrorInfoReference(PWSTR reference, IRestrictedErrorInfo** ppRestrictedErrorInfo);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetRestrictedErrorInfo(IRestrictedErrorInfo* pRestrictedErrorInfo);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRestrictedErrorInfo(IRestrictedErrorInfo** ppRestrictedErrorInfo);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RoOriginateErrorW(HRESULT error, uint32 cchMax, char16* message);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RoOriginateError(HRESULT error, HSTRING message);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RoTransformErrorW(HRESULT oldError, HRESULT newError, uint32 cchMax, char16* message);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RoTransformError(HRESULT oldError, HRESULT newError, HSTRING message);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoCaptureErrorContext(HRESULT hr);

	[Import("api-ms-win-core-winrt-error-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RoFailFastWithErrorContext(HRESULT hrError);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RoOriginateLanguageException(HRESULT error, HSTRING message, IUnknown* languageException);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RoClearError();

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoReportUnhandledError(IRestrictedErrorInfo* pRestrictedErrorInfo);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoInspectThreadErrorInfo(uint targetTebAddress, uint16 machine, PINSPECT_MEMORY_CALLBACK readMemoryCallback, void* context, uint* targetErrorInfoAddress);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoInspectCapturedStackBackTrace(uint targetErrorInfoAddress, uint16 machine, PINSPECT_MEMORY_CALLBACK readMemoryCallback, void* context, uint32* frameCount, uint* targetBackTraceAddress);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetMatchingRestrictedErrorInfo(HRESULT hrIn, IRestrictedErrorInfo** ppRestrictedErrorInfo);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoReportFailedDelegate(IUnknown* punkDelegate, IRestrictedErrorInfo* pRestrictedErrorInfo);

	[Import("api-ms-win-core-winrt-error-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsErrorPropagationEnabled();

	[Import("RoMetadata.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MetaDataGetDispenser(in Guid rclsid, in Guid riid, void** ppv);

	[Import("api-ms-win-core-winrt-roparameterizediid-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetParameterizedTypeInstanceIID(uint32 nameElementCount, PWSTR* nameElements, IRoMetaDataLocator* metaDataLocator, Guid* iid, ROPARAMIIDHANDLE* pExtra);

	[Import("api-ms-win-core-winrt-roparameterizediid-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RoFreeParameterizedTypeExtra(ROPARAMIIDHANDLE extra);

	[Import("api-ms-win-core-winrt-roparameterizediid-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR RoParameterizedTypeExtraGetTypeSignature(ROPARAMIIDHANDLE extra);

	[Import("api-ms-win-core-winrt-registration-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RoGetServerActivatableClasses(HSTRING serverName, HSTRING** activatableClassIds, uint32* count);

	[Import("api-ms-win-shcore-stream-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateRandomAccessStreamOnFile(PWSTR filePath, uint32 accessMode, in Guid riid, void** ppv);

	[Import("api-ms-win-shcore-stream-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateRandomAccessStreamOverStream(IStream* stream, BSOS_OPTIONS options, in Guid riid, void** ppv);

	[Import("api-ms-win-shcore-stream-winrt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStreamOverRandomAccessStream(IUnknown* randomAccessStream, in Guid riid, void** ppv);

	[Import("Windows.UI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateControlInput(in Guid riid, void** ppv);

	[Import("Windows.UI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateControlInputEx(IUnknown* pCoreWindow, in Guid riid, void** ppv);

}
#endregion
