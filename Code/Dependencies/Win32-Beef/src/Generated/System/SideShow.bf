using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.WindowsAndMessaging;
using Win32.System.Com.StructuredStorage;
using System;

namespace Win32.System.SideShow;

#region Constants
public static
{
	public const Guid SIDESHOW_ENDPOINT_SIMPLE_CONTENT_FORMAT = .(0xa9a5353f, 0x2d4b, 0x47ce, 0x93, 0xee, 0x75, 0x9f, 0x3a, 0x7d, 0xda, 0x4f);
	public const Guid SIDESHOW_ENDPOINT_ICAL = .(0x4dff36b5, 0x9dde, 0x4f76, 0x9a, 0x2a, 0x96, 0x43, 0x50, 0x47, 0x06, 0x3d);
	public const Guid SIDESHOW_CAPABILITY_DEVICE_PROPERTIES = .(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_DEVICE_ID = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 1);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_SCREEN_TYPE = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 2);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_SCREEN_WIDTH = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 3);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_SCREEN_HEIGHT = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 4);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_COLOR_DEPTH = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 5);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_COLOR_TYPE = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 6);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_DATA_CACHE = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 7);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_SUPPORTED_LANGUAGES = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 8);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_CURRENT_LANGUAGE = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 9);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_SUPPORTED_THEMES = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 10);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_SUPPORTED_IMAGE_FORMATS = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 14);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_CLIENT_AREA_WIDTH = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 15);
	public const PROPERTYKEY SIDESHOW_CAPABILITY_CLIENT_AREA_HEIGHT = .(.(0x8abc88a8, 0x857b, 0x4ad7, 0xa3, 0x5a, 0xb5, 0x94, 0x2f, 0x49, 0x2b, 0x99), 16);
	public const Guid GUID_DEVINTERFACE_SIDESHOW = .(0x152e5811, 0xfeb9, 0x4b00, 0x90, 0xf4, 0xd3, 0x29, 0x47, 0xae, 0x16, 0x81);
	public const Guid SIDESHOW_CONTENT_MISSING_EVENT = .(0x5007fba8, 0xd313, 0x439f, 0xbe, 0xa2, 0xa5, 0x02, 0x01, 0xd3, 0xe9, 0xa8);
	public const Guid SIDESHOW_APPLICATION_EVENT = .(0x4cb572fa, 0x1d3b, 0x49b3, 0xa1, 0x7a, 0x2e, 0x6b, 0xff, 0x05, 0x28, 0x54);
	public const Guid SIDESHOW_USER_CHANGE_REQUEST_EVENT = .(0x5009673c, 0x3f7d, 0x4c7e, 0x99, 0x71, 0xea, 0xa2, 0xe9, 0x1f, 0x15, 0x75);
	public const Guid SIDESHOW_NEW_EVENT_DATA_AVAILABLE = .(0x57813854, 0x2fc1, 0x411c, 0xa5, 0x9f, 0xf2, 0x49, 0x27, 0x60, 0x88, 0x04);
	public const uint32 CONTENT_ID_GLANCE = 0;
	public const uint32 SIDESHOW_EVENTID_APPLICATION_ENTER = 4294901760;
	public const uint32 SIDESHOW_EVENTID_APPLICATION_EXIT = 4294901761;
	public const uint32 CONTENT_ID_HOME = 1;
	public const uint32 VERSION_1_WINDOWS_7 = 0;
}
#endregion

#region Enums

[AllowDuplicates]
public enum SIDESHOW_SCREEN_TYPE : int32
{
	SIDESHOW_SCREEN_TYPE_BITMAP = 0,
	SIDESHOW_SCREEN_TYPE_TEXT = 1,
}


[AllowDuplicates]
public enum SIDESHOW_COLOR_TYPE : int32
{
	SIDESHOW_COLOR_TYPE_COLOR = 0,
	SIDESHOW_COLOR_TYPE_GREYSCALE = 1,
	SIDESHOW_COLOR_TYPE_BLACK_AND_WHITE = 2,
}


[AllowDuplicates]
public enum SCF_EVENT_IDS : int32
{
	SCF_EVENT_NAVIGATION = 1,
	SCF_EVENT_MENUACTION = 2,
	SCF_EVENT_CONTEXTMENU = 3,
}


[AllowDuplicates]
public enum SCF_BUTTON_IDS : int32
{
	SCF_BUTTON_MENU = 1,
	SCF_BUTTON_SELECT = 2,
	SCF_BUTTON_UP = 3,
	SCF_BUTTON_DOWN = 4,
	SCF_BUTTON_LEFT = 5,
	SCF_BUTTON_RIGHT = 6,
	SCF_BUTTON_PLAY = 7,
	SCF_BUTTON_PAUSE = 8,
	SCF_BUTTON_FASTFORWARD = 9,
	SCF_BUTTON_REWIND = 10,
	SCF_BUTTON_STOP = 11,
	SCF_BUTTON_BACK = 65280,
}

#endregion


#region Structs
[CRepr]
public struct SCF_EVENT_HEADER
{
	public uint32 PreviousPage;
	public uint32 TargetPage;
}

[CRepr]
public struct SCF_NAVIGATION_EVENT
{
	public uint32 PreviousPage;
	public uint32 TargetPage;
	public uint32 Button;
}

[CRepr]
public struct SCF_MENUACTION_EVENT
{
	public uint32 PreviousPage;
	public uint32 TargetPage;
	public uint32 Button;
	public uint32 ItemId;
}

[CRepr]
public struct SCF_CONTEXTMENU_EVENT
{
	public uint32 PreviousPage;
	public uint32 TargetPage;
	public uint32 PreviousItemId;
	public uint32 MenuPage;
	public uint32 MenuItemId;
}

[CRepr, Packed(1)]
public struct CONTENT_MISSING_EVENT_DATA
{
	public uint32 cbContentMissingEventData;
	public Guid ApplicationId;
	public Guid EndpointId;
	public uint32 ContentId;
}

[CRepr, Packed(1)]
public struct APPLICATION_EVENT_DATA
{
	public uint32 cbApplicationEventData;
	public Guid ApplicationId;
	public Guid EndpointId;
	public uint32 dwEventId;
	public uint32 cbEventData;
	public uint8* bEventData mut => &bEventData_impl;
	private uint8[ANYSIZE_ARRAY] bEventData_impl;
}

[CRepr, Packed(1)]
public struct DEVICE_USER_CHANGE_EVENT_DATA
{
	public uint32 cbDeviceUserChangeEventData;
	public char16 wszUser;
}

[CRepr, Packed(1)]
public struct NEW_EVENT_DATA_AVAILABLE
{
	public uint32 cbNewEventDataAvailable;
	public uint32 dwVersion;
}

[CRepr, Packed(1)]
public struct EVENT_DATA_HEADER
{
	public uint32 cbEventDataHeader;
	public Guid guidEventType;
	public uint32 dwVersion;
	public uint32 cbEventDataSid;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_SideShowSession = .(0xe20543b9, 0xf785, 0x4ea2, 0x98, 0x1e, 0xc4, 0xff, 0xa7, 0x6b, 0xbc, 0x7c);


	public const Guid CLSID_SideShowNotification = .(0x0ce3e86f, 0xd5cd, 0x4525, 0xa7, 0x66, 0x1a, 0xba, 0xb1, 0xa7, 0x52, 0xf5);


	public const Guid CLSID_SideShowKeyCollection = .(0xdfbbdbf8, 0x18de, 0x49b8, 0x83, 0xdc, 0xeb, 0xc7, 0x27, 0xc6, 0x2d, 0x94);


	public const Guid CLSID_SideShowPropVariantCollection = .(0xe640f415, 0x539e, 0x4923, 0x96, 0xcd, 0x5f, 0x09, 0x3b, 0xc2, 0x50, 0xcd);


}
#endregion

#region COM Types
[CRepr]struct ISideShowSession : IUnknown
{
	public new const Guid IID = .(0xe22331ee, 0x9e7d, 0x4922, 0x9f, 0xc2, 0xab, 0x7a, 0xa4, 0x1c, 0xe4, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* in_applicationId, Guid* in_endpointId, ISideShowContentManager** out_ppIContent) RegisterContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* in_applicationId, ISideShowNotificationManager** out_ppINotification) RegisterNotifications;
	}


	public HRESULT RegisterContent(Guid* in_applicationId, Guid* in_endpointId, ISideShowContentManager** out_ppIContent) mut => VT.[Friend]RegisterContent(&this, in_applicationId, in_endpointId, out_ppIContent);

	public HRESULT RegisterNotifications(Guid* in_applicationId, ISideShowNotificationManager** out_ppINotification) mut => VT.[Friend]RegisterNotifications(&this, in_applicationId, out_ppINotification);
}

[CRepr]struct ISideShowNotificationManager : IUnknown
{
	public new const Guid IID = .(0x63cea909, 0xf2b9, 0x4302, 0xb5, 0xe1, 0xc6, 0x8e, 0x6d, 0x9a, 0xb8, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowNotification* in_pINotification) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 in_notificationId) Revoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RevokeAll;
	}


	public HRESULT Show(ISideShowNotification* in_pINotification) mut => VT.[Friend]Show(&this, in_pINotification);

	public HRESULT Revoke(uint32 in_notificationId) mut => VT.[Friend]Revoke(&this, in_notificationId);

	public HRESULT RevokeAll() mut => VT.[Friend]RevokeAll(&this);
}

[CRepr]struct ISideShowNotification : IUnknown
{
	public new const Guid IID = .(0x03c93300, 0x8ab2, 0x41c5, 0x9b, 0x79, 0x46, 0x12, 0x7a, 0x30, 0xe1, 0x48);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* out_pNotificationId) get_NotificationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 in_notificationId) put_NotificationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* out_ppwszTitle) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR in_pwszTitle) put_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* out_ppwszMessage) get_Message;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR in_pwszMessage) put_Message;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON* out_phIcon) get_Image;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON in_hIcon) put_Image;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* out_pTime) get_ExpirationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* in_pTime) put_ExpirationTime;
	}


	public HRESULT get_NotificationId(uint32* out_pNotificationId) mut => VT.[Friend]get_NotificationId(&this, out_pNotificationId);

	public HRESULT put_NotificationId(uint32 in_notificationId) mut => VT.[Friend]put_NotificationId(&this, in_notificationId);

	public HRESULT get_Title(PWSTR* out_ppwszTitle) mut => VT.[Friend]get_Title(&this, out_ppwszTitle);

	public HRESULT put_Title(PWSTR in_pwszTitle) mut => VT.[Friend]put_Title(&this, in_pwszTitle);

	public HRESULT get_Message(PWSTR* out_ppwszMessage) mut => VT.[Friend]get_Message(&this, out_ppwszMessage);

	public HRESULT put_Message(PWSTR in_pwszMessage) mut => VT.[Friend]put_Message(&this, in_pwszMessage);

	public HRESULT get_Image(HICON* out_phIcon) mut => VT.[Friend]get_Image(&this, out_phIcon);

	public HRESULT put_Image(HICON in_hIcon) mut => VT.[Friend]put_Image(&this, in_hIcon);

	public HRESULT get_ExpirationTime(SYSTEMTIME* out_pTime) mut => VT.[Friend]get_ExpirationTime(&this, out_pTime);

	public HRESULT put_ExpirationTime(SYSTEMTIME* in_pTime) mut => VT.[Friend]put_ExpirationTime(&this, in_pTime);
}

[CRepr]struct ISideShowContentManager : IUnknown
{
	public new const Guid IID = .(0xa5d5b66b, 0xeef9, 0x41db, 0x8d, 0x7e, 0xe1, 0x7c, 0x33, 0xab, 0x10, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowContent* in_pIContent) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 in_contentId) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowEvents* in_pIEvents) SetEventSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowCapabilitiesCollection** out_ppCollection) GetDeviceCapabilities;
	}


	public HRESULT Add(ISideShowContent* in_pIContent) mut => VT.[Friend]Add(&this, in_pIContent);

	public HRESULT Remove(uint32 in_contentId) mut => VT.[Friend]Remove(&this, in_contentId);

	public HRESULT RemoveAll() mut => VT.[Friend]RemoveAll(&this);

	public HRESULT SetEventSink(ISideShowEvents* in_pIEvents) mut => VT.[Friend]SetEventSink(&this, in_pIEvents);

	public HRESULT GetDeviceCapabilities(ISideShowCapabilitiesCollection** out_ppCollection) mut => VT.[Friend]GetDeviceCapabilities(&this, out_ppCollection);
}

[CRepr]struct ISideShowContent : IUnknown
{
	public new const Guid IID = .(0xc18552ed, 0x74ff, 0x4fec, 0xbe, 0x07, 0x4c, 0xfe, 0xd2, 0x9d, 0x48, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowCapabilities* in_pICapabilities, uint32* out_pdwSize, uint8** out_ppbData) GetContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* out_pcontentId) get_ContentId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* out_pfDifferentiateContent) get_DifferentiateContent;
	}


	public HRESULT GetContent(ISideShowCapabilities* in_pICapabilities, uint32* out_pdwSize, uint8** out_ppbData) mut => VT.[Friend]GetContent(&this, in_pICapabilities, out_pdwSize, out_ppbData);

	public HRESULT get_ContentId(uint32* out_pcontentId) mut => VT.[Friend]get_ContentId(&this, out_pcontentId);

	public HRESULT get_DifferentiateContent(BOOL* out_pfDifferentiateContent) mut => VT.[Friend]get_DifferentiateContent(&this, out_pfDifferentiateContent);
}

[CRepr]struct ISideShowEvents : IUnknown
{
	public new const Guid IID = .(0x61feca4c, 0xdeb4, 0x4a7e, 0x8d, 0x75, 0x51, 0xf1, 0x13, 0x2d, 0x61, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 in_contentId, ISideShowContent** out_ppIContent) ContentMissing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowCapabilities* in_pICapabilities, uint32 in_dwEventId, uint32 in_dwEventSize, uint8* in_pbEventData) ApplicationEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowCapabilities* in_pIDevice) DeviceAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowCapabilities* in_pIDevice) DeviceRemoved;
	}


	public HRESULT ContentMissing(uint32 in_contentId, ISideShowContent** out_ppIContent) mut => VT.[Friend]ContentMissing(&this, in_contentId, out_ppIContent);

	public HRESULT ApplicationEvent(ISideShowCapabilities* in_pICapabilities, uint32 in_dwEventId, uint32 in_dwEventSize, uint8* in_pbEventData) mut => VT.[Friend]ApplicationEvent(&this, in_pICapabilities, in_dwEventId, in_dwEventSize, in_pbEventData);

	public HRESULT DeviceAdded(ISideShowCapabilities* in_pIDevice) mut => VT.[Friend]DeviceAdded(&this, in_pIDevice);

	public HRESULT DeviceRemoved(ISideShowCapabilities* in_pIDevice) mut => VT.[Friend]DeviceRemoved(&this, in_pIDevice);
}

[CRepr]struct ISideShowCapabilities : IUnknown
{
	public new const Guid IID = .(0x535e1379, 0xc09e, 0x4a54, 0xa5, 0x11, 0x59, 0x7b, 0xab, 0x3a, 0x72, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* in_keyCapability, PROPVARIANT* inout_pValue) GetCapability;
	}


	public HRESULT GetCapability(PROPERTYKEY* in_keyCapability, PROPVARIANT* inout_pValue) mut => VT.[Friend]GetCapability(&this, in_keyCapability, inout_pValue);
}

[CRepr]struct ISideShowCapabilitiesCollection : IUnknown
{
	public new const Guid IID = .(0x50305597, 0x5e0d, 0x4ff7, 0xb3, 0xaf, 0x33, 0xd0, 0xd9, 0xbd, 0x52, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* out_pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 in_dwIndex, ISideShowCapabilities** out_ppCapabilities) GetAt;
	}


	public HRESULT GetCount(uint32* out_pdwCount) mut => VT.[Friend]GetCount(&this, out_pdwCount);

	public HRESULT GetAt(uint32 in_dwIndex, ISideShowCapabilities** out_ppCapabilities) mut => VT.[Friend]GetAt(&this, in_dwIndex, out_ppCapabilities);
}

[CRepr]struct ISideShowBulkCapabilities : ISideShowCapabilities
{
	public new const Guid IID = .(0x3a2b7fbc, 0x3ad5, 0x48bd, 0xbb, 0xf1, 0x0e, 0x6c, 0xfb, 0xd1, 0x08, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISideShowCapabilities.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISideShowKeyCollection* in_keyCollection, ISideShowPropVariantCollection** inout_pValues) GetCapabilities;
	}


	public HRESULT GetCapabilities(ISideShowKeyCollection* in_keyCollection, ISideShowPropVariantCollection** inout_pValues) mut => VT.[Friend]GetCapabilities(&this, in_keyCollection, inout_pValues);
}

[CRepr]struct ISideShowKeyCollection : IUnknown
{
	public new const Guid IID = .(0x045473bc, 0xa37b, 0x4957, 0xb1, 0x44, 0x68, 0x10, 0x54, 0x11, 0xed, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* Key) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, PROPERTYKEY* pKey) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcElems) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) RemoveAt;
	}


	public HRESULT Add(PROPERTYKEY* Key) mut => VT.[Friend]Add(&this, Key);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT GetAt(uint32 dwIndex, PROPERTYKEY* pKey) mut => VT.[Friend]GetAt(&this, dwIndex, pKey);

	public HRESULT GetCount(uint32* pcElems) mut => VT.[Friend]GetCount(&this, pcElems);

	public HRESULT RemoveAt(uint32 dwIndex) mut => VT.[Friend]RemoveAt(&this, dwIndex);
}

[CRepr]struct ISideShowPropVariantCollection : IUnknown
{
	public new const Guid IID = .(0x2ea7a549, 0x7bff, 0x4aae, 0xba, 0xb0, 0x22, 0xd4, 0x31, 0x11, 0xde, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* pValue) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, PROPVARIANT* pValue) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcElems) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) RemoveAt;
	}


	public HRESULT Add(PROPVARIANT* pValue) mut => VT.[Friend]Add(&this, pValue);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT GetAt(uint32 dwIndex, PROPVARIANT* pValue) mut => VT.[Friend]GetAt(&this, dwIndex, pValue);

	public HRESULT GetCount(uint32* pcElems) mut => VT.[Friend]GetCount(&this, pcElems);

	public HRESULT RemoveAt(uint32 dwIndex) mut => VT.[Friend]RemoveAt(&this, dwIndex);
}

#endregion
