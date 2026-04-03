using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.Graphics.DirectManipulation;

#region Constants
public static
{
	public const uint32 DIRECTMANIPULATION_KEYBOARDFOCUS = 4294967294;
	public const uint32 DIRECTMANIPULATION_MOUSEFOCUS = 4294967293;
	public const Guid CLSID_VerticalIndicatorContent = .(0xa10b5f17, 0xafe0, 0x4aa2, 0x91, 0xe9, 0x3e, 0x70, 0x01, 0xd2, 0xe6, 0xb4);
	public const Guid CLSID_HorizontalIndicatorContent = .(0xe7d18cf5, 0x3ec7, 0x44d5, 0xa7, 0x6b, 0x37, 0x70, 0xf3, 0xcf, 0x90, 0x3d);
	public const Guid CLSID_VirtualViewportContent = .(0x3206a19a, 0x86f0, 0x4cb4, 0xa7, 0xf3, 0x16, 0xe3, 0xb7, 0xe2, 0xd8, 0x52);
	public const Guid CLSID_DragDropConfigurationBehavior = .(0x09b01b3e, 0xba6c, 0x454d, 0x82, 0xe8, 0x95, 0xe3, 0x52, 0x32, 0x9f, 0x23);
	public const Guid CLSID_AutoScrollBehavior = .(0x26126a51, 0x3c70, 0x4c9a, 0xae, 0xc2, 0x94, 0x88, 0x49, 0xee, 0xb0, 0x93);
	public const Guid CLSID_DeferContactService = .(0xd7b67cf4, 0x84bb, 0x434e, 0x86, 0xae, 0x65, 0x92, 0xbb, 0xc9, 0xab, 0xd9);
}
#endregion

#region Enums

[AllowDuplicates]
public enum DIRECTMANIPULATION_STATUS : int32
{
	DIRECTMANIPULATION_BUILDING = 0,
	DIRECTMANIPULATION_ENABLED = 1,
	DIRECTMANIPULATION_DISABLED = 2,
	DIRECTMANIPULATION_RUNNING = 3,
	DIRECTMANIPULATION_INERTIA = 4,
	DIRECTMANIPULATION_READY = 5,
	DIRECTMANIPULATION_SUSPENDED = 6,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_HITTEST_TYPE : int32
{
	DIRECTMANIPULATION_HITTEST_TYPE_ASYNCHRONOUS = 0,
	DIRECTMANIPULATION_HITTEST_TYPE_SYNCHRONOUS = 1,
	DIRECTMANIPULATION_HITTEST_TYPE_AUTO_SYNCHRONOUS = 2,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_CONFIGURATION : int32
{
	DIRECTMANIPULATION_CONFIGURATION_NONE = 0,
	DIRECTMANIPULATION_CONFIGURATION_INTERACTION = 1,
	DIRECTMANIPULATION_CONFIGURATION_TRANSLATION_X = 2,
	DIRECTMANIPULATION_CONFIGURATION_TRANSLATION_Y = 4,
	DIRECTMANIPULATION_CONFIGURATION_SCALING = 16,
	DIRECTMANIPULATION_CONFIGURATION_TRANSLATION_INERTIA = 32,
	DIRECTMANIPULATION_CONFIGURATION_SCALING_INERTIA = 128,
	DIRECTMANIPULATION_CONFIGURATION_RAILS_X = 256,
	DIRECTMANIPULATION_CONFIGURATION_RAILS_Y = 512,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_GESTURE_CONFIGURATION : int32
{
	DIRECTMANIPULATION_GESTURE_NONE = 0,
	DIRECTMANIPULATION_GESTURE_DEFAULT = 0,
	DIRECTMANIPULATION_GESTURE_CROSS_SLIDE_VERTICAL = 8,
	DIRECTMANIPULATION_GESTURE_CROSS_SLIDE_HORIZONTAL = 16,
	DIRECTMANIPULATION_GESTURE_PINCH_ZOOM = 32,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_MOTION_TYPES : int32
{
	DIRECTMANIPULATION_MOTION_NONE = 0,
	DIRECTMANIPULATION_MOTION_TRANSLATEX = 1,
	DIRECTMANIPULATION_MOTION_TRANSLATEY = 2,
	DIRECTMANIPULATION_MOTION_ZOOM = 4,
	DIRECTMANIPULATION_MOTION_CENTERX = 16,
	DIRECTMANIPULATION_MOTION_CENTERY = 32,
	DIRECTMANIPULATION_MOTION_ALL = 55,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_VIEWPORT_OPTIONS : int32
{
	DIRECTMANIPULATION_VIEWPORT_OPTIONS_DEFAULT = 0,
	DIRECTMANIPULATION_VIEWPORT_OPTIONS_AUTODISABLE = 1,
	DIRECTMANIPULATION_VIEWPORT_OPTIONS_MANUALUPDATE = 2,
	DIRECTMANIPULATION_VIEWPORT_OPTIONS_INPUT = 4,
	DIRECTMANIPULATION_VIEWPORT_OPTIONS_EXPLICITHITTEST = 8,
	DIRECTMANIPULATION_VIEWPORT_OPTIONS_DISABLEPIXELSNAPPING = 16,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_SNAPPOINT_TYPE : int32
{
	DIRECTMANIPULATION_SNAPPOINT_MANDATORY = 0,
	DIRECTMANIPULATION_SNAPPOINT_OPTIONAL = 1,
	DIRECTMANIPULATION_SNAPPOINT_MANDATORY_SINGLE = 2,
	DIRECTMANIPULATION_SNAPPOINT_OPTIONAL_SINGLE = 3,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_SNAPPOINT_COORDINATE : int32
{
	DIRECTMANIPULATION_COORDINATE_BOUNDARY = 0,
	DIRECTMANIPULATION_COORDINATE_ORIGIN = 1,
	DIRECTMANIPULATION_COORDINATE_MIRRORED = 16,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_HORIZONTALALIGNMENT : int32
{
	DIRECTMANIPULATION_HORIZONTALALIGNMENT_NONE = 0,
	DIRECTMANIPULATION_HORIZONTALALIGNMENT_LEFT = 1,
	DIRECTMANIPULATION_HORIZONTALALIGNMENT_CENTER = 2,
	DIRECTMANIPULATION_HORIZONTALALIGNMENT_RIGHT = 4,
	DIRECTMANIPULATION_HORIZONTALALIGNMENT_UNLOCKCENTER = 8,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_VERTICALALIGNMENT : int32
{
	DIRECTMANIPULATION_VERTICALALIGNMENT_NONE = 0,
	DIRECTMANIPULATION_VERTICALALIGNMENT_TOP = 1,
	DIRECTMANIPULATION_VERTICALALIGNMENT_CENTER = 2,
	DIRECTMANIPULATION_VERTICALALIGNMENT_BOTTOM = 4,
	DIRECTMANIPULATION_VERTICALALIGNMENT_UNLOCKCENTER = 8,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_INPUT_MODE : int32
{
	DIRECTMANIPULATION_INPUT_MODE_AUTOMATIC = 0,
	DIRECTMANIPULATION_INPUT_MODE_MANUAL = 1,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_DRAG_DROP_STATUS : int32
{
	DIRECTMANIPULATION_DRAG_DROP_READY = 0,
	DIRECTMANIPULATION_DRAG_DROP_PRESELECT = 1,
	DIRECTMANIPULATION_DRAG_DROP_SELECTING = 2,
	DIRECTMANIPULATION_DRAG_DROP_DRAGGING = 3,
	DIRECTMANIPULATION_DRAG_DROP_CANCELLED = 4,
	DIRECTMANIPULATION_DRAG_DROP_COMMITTED = 5,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION : int32
{
	DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION_VERTICAL = 1,
	DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION_HORIZONTAL = 2,
	DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION_SELECT_ONLY = 16,
	DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION_SELECT_DRAG = 32,
	DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION_HOLD_DRAG = 64,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_INTERACTION_TYPE : int32
{
	DIRECTMANIPULATION_INTERACTION_BEGIN = 0,
	DIRECTMANIPULATION_INTERACTION_TYPE_MANIPULATION = 1,
	DIRECTMANIPULATION_INTERACTION_TYPE_GESTURE_TAP = 2,
	DIRECTMANIPULATION_INTERACTION_TYPE_GESTURE_HOLD = 3,
	DIRECTMANIPULATION_INTERACTION_TYPE_GESTURE_CROSS_SLIDE = 4,
	DIRECTMANIPULATION_INTERACTION_TYPE_GESTURE_PINCH_ZOOM = 5,
	DIRECTMANIPULATION_INTERACTION_END = 100,
}


[AllowDuplicates]
public enum DIRECTMANIPULATION_AUTOSCROLL_CONFIGURATION : int32
{
	DIRECTMANIPULATION_AUTOSCROLL_CONFIGURATION_STOP = 0,
	DIRECTMANIPULATION_AUTOSCROLL_CONFIGURATION_FORWARD = 1,
	DIRECTMANIPULATION_AUTOSCROLL_CONFIGURATION_REVERSE = 2,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_DirectManipulationViewport = .(0x34e211b6, 0x3650, 0x4f75, 0x83, 0x34, 0xfa, 0x35, 0x95, 0x98, 0xe1, 0xc5);


	public const Guid CLSID_DirectManipulationUpdateManager = .(0x9fc1bfd5, 0x1835, 0x441a, 0xb3, 0xb1, 0xb6, 0xcc, 0x74, 0xb7, 0x27, 0xd0);


	public const Guid CLSID_DirectManipulationPrimaryContent = .(0xcaa02661, 0xd59e, 0x41c7, 0x83, 0x93, 0x3b, 0xa3, 0xba, 0xcb, 0x6b, 0x57);


	public const Guid CLSID_DirectManipulationManager = .(0x54e211b6, 0x3650, 0x4f75, 0x83, 0x34, 0xfa, 0x35, 0x95, 0x98, 0xe1, 0xc5);


	public const Guid CLSID_DirectManipulationSharedManager = .(0x99793286, 0x77cc, 0x4b57, 0x96, 0xdb, 0x3b, 0x35, 0x4f, 0x6f, 0x9f, 0xb5);


	public const Guid CLSID_DCompManipulationCompositor = .(0x79dea627, 0xa08a, 0x43ac, 0x8e, 0xf5, 0x69, 0x00, 0xb9, 0x29, 0x91, 0x26);


}
#endregion

#region COM Types
[CRepr]struct IDirectManipulationManager : IUnknown
{
	public new const Guid IID = .(0xfbf5d3b4, 0x70c7, 0x4163, 0x93, 0x22, 0x5a, 0x6f, 0x66, 0x0d, 0x6f, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window) Deactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, HWND hitTestWindow, DIRECTMANIPULATION_HITTEST_TYPE type) RegisterHitTestTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* message, BOOL* handled) ProcessInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** object) GetUpdateManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationFrameInfoProvider* frameInfo, HWND window, in Guid riid, void** object) CreateViewport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationFrameInfoProvider* frameInfo, in Guid clsid, in Guid riid, void** object) CreateContent;
	}


	public HRESULT Activate(HWND window) mut => VT.[Friend]Activate(&this, window);

	public HRESULT Deactivate(HWND window) mut => VT.[Friend]Deactivate(&this, window);

	public HRESULT RegisterHitTestTarget(HWND window, HWND hitTestWindow, DIRECTMANIPULATION_HITTEST_TYPE type) mut => VT.[Friend]RegisterHitTestTarget(&this, window, hitTestWindow, type);

	public HRESULT ProcessInput(MSG* message, BOOL* handled) mut => VT.[Friend]ProcessInput(&this, message, handled);

	public HRESULT GetUpdateManager(in Guid riid, void** object) mut => VT.[Friend]GetUpdateManager(&this, riid, object);

	public HRESULT CreateViewport(IDirectManipulationFrameInfoProvider* frameInfo, HWND window, in Guid riid, void** object) mut => VT.[Friend]CreateViewport(&this, frameInfo, window, riid, object);

	public HRESULT CreateContent(IDirectManipulationFrameInfoProvider* frameInfo, in Guid clsid, in Guid riid, void** object) mut => VT.[Friend]CreateContent(&this, frameInfo, clsid, riid, object);
}

[CRepr]struct IDirectManipulationManager2 : IDirectManipulationManager
{
	public new const Guid IID = .(0xfa1005e9, 0x3d16, 0x484c, 0xbf, 0xc9, 0x62, 0xb6, 0x1e, 0x56, 0xec, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectManipulationManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, in Guid riid, void** object) CreateBehavior;
	}


	public HRESULT CreateBehavior(in Guid clsid, in Guid riid, void** object) mut => VT.[Friend]CreateBehavior(&this, clsid, riid, object);
}

[CRepr]struct IDirectManipulationManager3 : IDirectManipulationManager2
{
	public new const Guid IID = .(0x2cb6b33d, 0xffe8, 0x488c, 0xb7, 0x50, 0xfb, 0xdf, 0xe8, 0x8d, 0xca, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectManipulationManager2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, in Guid riid, void** object) GetService;
	}


	public HRESULT GetService(in Guid clsid, in Guid riid, void** object) mut => VT.[Friend]GetService(&this, clsid, riid, object);
}

[CRepr]struct IDirectManipulationViewport : IUnknown
{
	public new const Guid IID = .(0x28b85a3d, 0x60a0, 0x48bd, 0x9b, 0xa1, 0x5c, 0xe8, 0xd9, 0xea, 0x3a, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pointerId) SetContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pointerId) ReleaseContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseAllContacts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_STATUS* status) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** object, uint32* id) GetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id) SetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* viewport) GetViewportRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* viewport) SetViewportRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float left, float top, float right, float bottom, BOOL animate) ZoomToRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* matrix, uint32 pointCount) SetViewportTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* matrix, uint32 pointCount) SyncDisplayTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** object) GetPrimaryContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationContent* content) AddContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationContent* content) RemoveContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_VIEWPORT_OPTIONS options) SetViewportOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_CONFIGURATION configuration) AddConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_CONFIGURATION configuration) RemoveConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_CONFIGURATION configuration) ActivateConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_GESTURE_CONFIGURATION configuration) SetManualGesture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_MOTION_TYPES enabledTypes) SetChaining;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, IDirectManipulationViewportEventHandler* eventHandler, uint32* cookie) AddEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie) RemoveEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_INPUT_MODE mode) SetInputMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_INPUT_MODE mode) SetUpdateMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abandon;
	}


	public HRESULT Enable() mut => VT.[Friend]Enable(&this);

	public HRESULT Disable() mut => VT.[Friend]Disable(&this);

	public HRESULT SetContact(uint32 pointerId) mut => VT.[Friend]SetContact(&this, pointerId);

	public HRESULT ReleaseContact(uint32 pointerId) mut => VT.[Friend]ReleaseContact(&this, pointerId);

	public HRESULT ReleaseAllContacts() mut => VT.[Friend]ReleaseAllContacts(&this);

	public HRESULT GetStatus(DIRECTMANIPULATION_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);

	public HRESULT GetTag(in Guid riid, void** object, uint32* id) mut => VT.[Friend]GetTag(&this, riid, object, id);

	public HRESULT SetTag(IUnknown* object, uint32 id) mut => VT.[Friend]SetTag(&this, object, id);

	public HRESULT GetViewportRect(RECT* viewport) mut => VT.[Friend]GetViewportRect(&this, viewport);

	public HRESULT SetViewportRect(RECT* viewport) mut => VT.[Friend]SetViewportRect(&this, viewport);

	public HRESULT ZoomToRect(float left, float top, float right, float bottom, BOOL animate) mut => VT.[Friend]ZoomToRect(&this, left, top, right, bottom, animate);

	public HRESULT SetViewportTransform(float* matrix, uint32 pointCount) mut => VT.[Friend]SetViewportTransform(&this, matrix, pointCount);

	public HRESULT SyncDisplayTransform(float* matrix, uint32 pointCount) mut => VT.[Friend]SyncDisplayTransform(&this, matrix, pointCount);

	public HRESULT GetPrimaryContent(in Guid riid, void** object) mut => VT.[Friend]GetPrimaryContent(&this, riid, object);

	public HRESULT AddContent(IDirectManipulationContent* content) mut => VT.[Friend]AddContent(&this, content);

	public HRESULT RemoveContent(IDirectManipulationContent* content) mut => VT.[Friend]RemoveContent(&this, content);

	public HRESULT SetViewportOptions(DIRECTMANIPULATION_VIEWPORT_OPTIONS options) mut => VT.[Friend]SetViewportOptions(&this, options);

	public HRESULT AddConfiguration(DIRECTMANIPULATION_CONFIGURATION configuration) mut => VT.[Friend]AddConfiguration(&this, configuration);

	public HRESULT RemoveConfiguration(DIRECTMANIPULATION_CONFIGURATION configuration) mut => VT.[Friend]RemoveConfiguration(&this, configuration);

	public HRESULT ActivateConfiguration(DIRECTMANIPULATION_CONFIGURATION configuration) mut => VT.[Friend]ActivateConfiguration(&this, configuration);

	public HRESULT SetManualGesture(DIRECTMANIPULATION_GESTURE_CONFIGURATION configuration) mut => VT.[Friend]SetManualGesture(&this, configuration);

	public HRESULT SetChaining(DIRECTMANIPULATION_MOTION_TYPES enabledTypes) mut => VT.[Friend]SetChaining(&this, enabledTypes);

	public HRESULT AddEventHandler(HWND window, IDirectManipulationViewportEventHandler* eventHandler, uint32* cookie) mut => VT.[Friend]AddEventHandler(&this, window, eventHandler, cookie);

	public HRESULT RemoveEventHandler(uint32 cookie) mut => VT.[Friend]RemoveEventHandler(&this, cookie);

	public HRESULT SetInputMode(DIRECTMANIPULATION_INPUT_MODE mode) mut => VT.[Friend]SetInputMode(&this, mode);

	public HRESULT SetUpdateMode(DIRECTMANIPULATION_INPUT_MODE mode) mut => VT.[Friend]SetUpdateMode(&this, mode);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Abandon() mut => VT.[Friend]Abandon(&this);
}

[CRepr]struct IDirectManipulationViewport2 : IDirectManipulationViewport
{
	public new const Guid IID = .(0x923ccaac, 0x61e1, 0x4385, 0xb7, 0x26, 0x01, 0x7a, 0xf1, 0x89, 0x88, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectManipulationViewport.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* behavior, uint32* cookie) AddBehavior;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie) RemoveBehavior;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllBehaviors;
	}


	public HRESULT AddBehavior(IUnknown* behavior, uint32* cookie) mut => VT.[Friend]AddBehavior(&this, behavior, cookie);

	public HRESULT RemoveBehavior(uint32 cookie) mut => VT.[Friend]RemoveBehavior(&this, cookie);

	public HRESULT RemoveAllBehaviors() mut => VT.[Friend]RemoveAllBehaviors(&this);
}

[CRepr]struct IDirectManipulationViewportEventHandler : IUnknown
{
	public new const Guid IID = .(0x952121da, 0xd69f, 0x45f9, 0xb0, 0xf9, 0xf2, 0x39, 0x44, 0x32, 0x1a, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationViewport* viewport, DIRECTMANIPULATION_STATUS current, DIRECTMANIPULATION_STATUS previous) OnViewportStatusChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationViewport* viewport) OnViewportUpdated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationViewport* viewport, IDirectManipulationContent* content) OnContentUpdated;
	}


	public HRESULT OnViewportStatusChanged(IDirectManipulationViewport* viewport, DIRECTMANIPULATION_STATUS current, DIRECTMANIPULATION_STATUS previous) mut => VT.[Friend]OnViewportStatusChanged(&this, viewport, current, previous);

	public HRESULT OnViewportUpdated(IDirectManipulationViewport* viewport) mut => VT.[Friend]OnViewportUpdated(&this, viewport);

	public HRESULT OnContentUpdated(IDirectManipulationViewport* viewport, IDirectManipulationContent* content) mut => VT.[Friend]OnContentUpdated(&this, viewport, content);
}

[CRepr]struct IDirectManipulationContent : IUnknown
{
	public new const Guid IID = .(0xb89962cb, 0x3d89, 0x442b, 0xbb, 0x58, 0x50, 0x98, 0xfa, 0x0f, 0x9f, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* contentSize) GetContentRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* contentSize) SetContentRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** object) GetViewport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** object, uint32* id) GetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id) SetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* matrix, uint32 pointCount) GetOutputTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* matrix, uint32 pointCount) GetContentTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* matrix, uint32 pointCount) SyncContentTransform;
	}


	public HRESULT GetContentRect(RECT* contentSize) mut => VT.[Friend]GetContentRect(&this, contentSize);

	public HRESULT SetContentRect(RECT* contentSize) mut => VT.[Friend]SetContentRect(&this, contentSize);

	public HRESULT GetViewport(in Guid riid, void** object) mut => VT.[Friend]GetViewport(&this, riid, object);

	public HRESULT GetTag(in Guid riid, void** object, uint32* id) mut => VT.[Friend]GetTag(&this, riid, object, id);

	public HRESULT SetTag(IUnknown* object, uint32 id) mut => VT.[Friend]SetTag(&this, object, id);

	public HRESULT GetOutputTransform(float* matrix, uint32 pointCount) mut => VT.[Friend]GetOutputTransform(&this, matrix, pointCount);

	public HRESULT GetContentTransform(float* matrix, uint32 pointCount) mut => VT.[Friend]GetContentTransform(&this, matrix, pointCount);

	public HRESULT SyncContentTransform(float* matrix, uint32 pointCount) mut => VT.[Friend]SyncContentTransform(&this, matrix, pointCount);
}

[CRepr]struct IDirectManipulationPrimaryContent : IUnknown
{
	public new const Guid IID = .(0xc12851e4, 0x1698, 0x4625, 0xb9, 0xb1, 0x7c, 0xa3, 0xec, 0x18, 0x63, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_MOTION_TYPES motion, float interval, float offset) SetSnapInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_MOTION_TYPES motion, float* points, uint32 pointCount) SetSnapPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_MOTION_TYPES motion, DIRECTMANIPULATION_SNAPPOINT_TYPE type) SetSnapType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_MOTION_TYPES motion, DIRECTMANIPULATION_SNAPPOINT_COORDINATE coordinate, float origin) SetSnapCoordinate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float zoomMinimum, float zoomMaximum) SetZoomBoundaries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_HORIZONTALALIGNMENT alignment) SetHorizontalAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_VERTICALALIGNMENT alignment) SetVerticalAlignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* matrix, uint32 pointCount) GetInertiaEndTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* centerX, float* centerY) GetCenterPoint;
	}


	public HRESULT SetSnapInterval(DIRECTMANIPULATION_MOTION_TYPES motion, float interval, float offset) mut => VT.[Friend]SetSnapInterval(&this, motion, interval, offset);

	public HRESULT SetSnapPoints(DIRECTMANIPULATION_MOTION_TYPES motion, float* points, uint32 pointCount) mut => VT.[Friend]SetSnapPoints(&this, motion, points, pointCount);

	public HRESULT SetSnapType(DIRECTMANIPULATION_MOTION_TYPES motion, DIRECTMANIPULATION_SNAPPOINT_TYPE type) mut => VT.[Friend]SetSnapType(&this, motion, type);

	public HRESULT SetSnapCoordinate(DIRECTMANIPULATION_MOTION_TYPES motion, DIRECTMANIPULATION_SNAPPOINT_COORDINATE coordinate, float origin) mut => VT.[Friend]SetSnapCoordinate(&this, motion, coordinate, origin);

	public HRESULT SetZoomBoundaries(float zoomMinimum, float zoomMaximum) mut => VT.[Friend]SetZoomBoundaries(&this, zoomMinimum, zoomMaximum);

	public HRESULT SetHorizontalAlignment(DIRECTMANIPULATION_HORIZONTALALIGNMENT alignment) mut => VT.[Friend]SetHorizontalAlignment(&this, alignment);

	public HRESULT SetVerticalAlignment(DIRECTMANIPULATION_VERTICALALIGNMENT alignment) mut => VT.[Friend]SetVerticalAlignment(&this, alignment);

	public HRESULT GetInertiaEndTransform(float* matrix, uint32 pointCount) mut => VT.[Friend]GetInertiaEndTransform(&this, matrix, pointCount);

	public HRESULT GetCenterPoint(float* centerX, float* centerY) mut => VT.[Friend]GetCenterPoint(&this, centerX, centerY);
}

[CRepr]struct IDirectManipulationDragDropEventHandler : IUnknown
{
	public new const Guid IID = .(0x1fa11b10, 0x701b, 0x41ae, 0xb5, 0xf2, 0x49, 0xe3, 0x6b, 0xd5, 0x95, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationViewport2* viewport, DIRECTMANIPULATION_DRAG_DROP_STATUS current, DIRECTMANIPULATION_DRAG_DROP_STATUS previous) OnDragDropStatusChange;
	}


	public HRESULT OnDragDropStatusChange(IDirectManipulationViewport2* viewport, DIRECTMANIPULATION_DRAG_DROP_STATUS current, DIRECTMANIPULATION_DRAG_DROP_STATUS previous) mut => VT.[Friend]OnDragDropStatusChange(&this, viewport, current, previous);
}

[CRepr]struct IDirectManipulationDragDropBehavior : IUnknown
{
	public new const Guid IID = .(0x814b5af5, 0xc2c8, 0x4270, 0xa9, 0xb7, 0xa1, 0x98, 0xce, 0x8d, 0x02, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION configuration) SetConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_DRAG_DROP_STATUS* status) GetStatus;
	}


	public HRESULT SetConfiguration(DIRECTMANIPULATION_DRAG_DROP_CONFIGURATION configuration) mut => VT.[Friend]SetConfiguration(&this, configuration);

	public HRESULT GetStatus(DIRECTMANIPULATION_DRAG_DROP_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);
}

[CRepr]struct IDirectManipulationInteractionEventHandler : IUnknown
{
	public new const Guid IID = .(0xe43f45b8, 0x42b4, 0x403e, 0xb1, 0xf2, 0x27, 0x3b, 0x8f, 0x51, 0x08, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationViewport2* viewport, DIRECTMANIPULATION_INTERACTION_TYPE interaction) OnInteraction;
	}


	public HRESULT OnInteraction(IDirectManipulationViewport2* viewport, DIRECTMANIPULATION_INTERACTION_TYPE interaction) mut => VT.[Friend]OnInteraction(&this, viewport, interaction);
}

[CRepr]struct IDirectManipulationFrameInfoProvider : IUnknown
{
	public new const Guid IID = .(0xfb759dba, 0x6f4c, 0x4c01, 0x87, 0x4e, 0x19, 0xc8, 0xa0, 0x59, 0x07, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* time, uint64* processTime, uint64* compositionTime) GetNextFrameInfo;
	}


	public HRESULT GetNextFrameInfo(uint64* time, uint64* processTime, uint64* compositionTime) mut => VT.[Friend]GetNextFrameInfo(&this, time, processTime, compositionTime);
}

[CRepr]struct IDirectManipulationCompositor : IUnknown
{
	public new const Guid IID = .(0x537a0825, 0x0387, 0x4efa, 0xb6, 0x2f, 0x71, 0xeb, 0x1f, 0x08, 0x5a, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationContent* content, IUnknown* device, IUnknown* parentVisual, IUnknown* childVisual) AddContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationContent* content) RemoveContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationUpdateManager* updateManager) SetUpdateManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
	}


	public HRESULT AddContent(IDirectManipulationContent* content, IUnknown* device, IUnknown* parentVisual, IUnknown* childVisual) mut => VT.[Friend]AddContent(&this, content, device, parentVisual, childVisual);

	public HRESULT RemoveContent(IDirectManipulationContent* content) mut => VT.[Friend]RemoveContent(&this, content);

	public HRESULT SetUpdateManager(IDirectManipulationUpdateManager* updateManager) mut => VT.[Friend]SetUpdateManager(&this, updateManager);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);
}

[CRepr]struct IDirectManipulationCompositor2 : IDirectManipulationCompositor
{
	public new const Guid IID = .(0xd38c7822, 0xf1cb, 0x43cb, 0xb4, 0xb9, 0xac, 0x0c, 0x76, 0x7a, 0x41, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDirectManipulationCompositor.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationPrimaryContent* content, IUnknown* device, IUnknown* parentVisual, IUnknown* childVisual) AddContentWithCrossProcessChaining;
	}


	public HRESULT AddContentWithCrossProcessChaining(IDirectManipulationPrimaryContent* content, IUnknown* device, IUnknown* parentVisual, IUnknown* childVisual) mut => VT.[Friend]AddContentWithCrossProcessChaining(&this, content, device, parentVisual, childVisual);
}

[CRepr]struct IDirectManipulationUpdateHandler : IUnknown
{
	public new const Guid IID = .(0x790b6337, 0x64f8, 0x4ff5, 0xa2, 0x69, 0xb3, 0x2b, 0xc2, 0xaf, 0x27, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Update;
	}


	public HRESULT Update() mut => VT.[Friend]Update(&this);
}

[CRepr]struct IDirectManipulationUpdateManager : IUnknown
{
	public new const Guid IID = .(0xb0ae62fd, 0xbe34, 0x46e7, 0x9c, 0xaa, 0xd3, 0x61, 0xfa, 0xcb, 0xb9, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE handle, IDirectManipulationUpdateHandler* eventHandler, uint32* cookie) RegisterWaitHandleCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie) UnregisterWaitHandleCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectManipulationFrameInfoProvider* frameInfo) Update;
	}


	public HRESULT RegisterWaitHandleCallback(HANDLE handle, IDirectManipulationUpdateHandler* eventHandler, uint32* cookie) mut => VT.[Friend]RegisterWaitHandleCallback(&this, handle, eventHandler, cookie);

	public HRESULT UnregisterWaitHandleCallback(uint32 cookie) mut => VT.[Friend]UnregisterWaitHandleCallback(&this, cookie);

	public HRESULT Update(IDirectManipulationFrameInfoProvider* frameInfo) mut => VT.[Friend]Update(&this, frameInfo);
}

[CRepr]struct IDirectManipulationAutoScrollBehavior : IUnknown
{
	public new const Guid IID = .(0x6d5954d4, 0x2003, 0x4356, 0x9b, 0x31, 0xd0, 0x51, 0xc9, 0xff, 0x0a, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DIRECTMANIPULATION_MOTION_TYPES motionTypes, DIRECTMANIPULATION_AUTOSCROLL_CONFIGURATION scrollMotion) SetConfiguration;
	}


	public HRESULT SetConfiguration(DIRECTMANIPULATION_MOTION_TYPES motionTypes, DIRECTMANIPULATION_AUTOSCROLL_CONFIGURATION scrollMotion) mut => VT.[Friend]SetConfiguration(&this, motionTypes, scrollMotion);
}

[CRepr]struct IDirectManipulationDeferContactService : IUnknown
{
	public new const Guid IID = .(0x652d5c71, 0xfe60, 0x4a98, 0xbe, 0x70, 0xe5, 0xf2, 0x12, 0x91, 0xe7, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pointerId, uint32 timeout) DeferContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pointerId) CancelContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pointerId) CancelDeferral;
	}


	public HRESULT DeferContact(uint32 pointerId, uint32 timeout) mut => VT.[Friend]DeferContact(&this, pointerId, timeout);

	public HRESULT CancelContact(uint32 pointerId) mut => VT.[Friend]CancelContact(&this, pointerId);

	public HRESULT CancelDeferral(uint32 pointerId) mut => VT.[Friend]CancelDeferral(&this, pointerId);
}

#endregion
