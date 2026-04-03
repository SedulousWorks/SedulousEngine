using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Dxgi;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.System.WinRT.Xaml;

#region Constants
public static
{
	public const uint32 E_SURFACE_CONTENTS_LOST = 2150301728;
}
#endregion

#region Enums

[AllowDuplicates]
public enum XAML_REFERENCETRACKER_DISCONNECT : int32
{
	XAML_REFERENCETRACKER_DISCONNECT_DEFAULT = 0,
	XAML_REFERENCETRACKER_DISCONNECT_SUSPEND = 1,
}

#endregion


#region Structs
[CRepr]
public struct TrackerHandle__
{
	public int32 unused;
}

#endregion

#region COM Types
[CRepr]struct ISurfaceImageSourceNative : IUnknown
{
	public new const Guid IID = .(0xf2e9edc1, 0xd307, 0x4525, 0x98, 0x86, 0x0f, 0xaf, 0xaa, 0x44, 0x16, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGIDevice* device) SetDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT updateRect, IDXGISurface** surface, POINT* offset) BeginDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndDraw;
	}


	public HRESULT SetDevice(IDXGIDevice* device) mut => VT.[Friend]SetDevice(&this, device);

	public HRESULT BeginDraw(RECT updateRect, IDXGISurface** surface, POINT* offset) mut => VT.[Friend]BeginDraw(&this, updateRect, surface, offset);

	public HRESULT EndDraw() mut => VT.[Friend]EndDraw(&this);
}

[CRepr]struct IVirtualSurfaceUpdatesCallbackNative : IUnknown
{
	public new const Guid IID = .(0xdbf2e947, 0x8e6c, 0x4254, 0x9e, 0xee, 0x77, 0x38, 0xf7, 0x13, 0x86, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdatesNeeded;
	}


	public HRESULT UpdatesNeeded() mut => VT.[Friend]UpdatesNeeded(&this);
}

[CRepr]struct IVirtualSurfaceImageSourceNative : ISurfaceImageSourceNative
{
	public new const Guid IID = .(0xe9550983, 0x360b, 0x4f53, 0xb3, 0x91, 0xaf, 0xd6, 0x95, 0x07, 0x86, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISurfaceImageSourceNative.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT updateRect) Invalidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetUpdateRectCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* updates, uint32 count) GetUpdateRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* bounds) GetVisibleBounds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IVirtualSurfaceUpdatesCallbackNative* callback) RegisterForUpdatesNeeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 newWidth, int32 newHeight) Resize;
	}


	public HRESULT Invalidate(RECT updateRect) mut => VT.[Friend]Invalidate(&this, updateRect);

	public HRESULT GetUpdateRectCount(uint32* count) mut => VT.[Friend]GetUpdateRectCount(&this, count);

	public HRESULT GetUpdateRects(RECT* updates, uint32 count) mut => VT.[Friend]GetUpdateRects(&this, updates, count);

	public HRESULT GetVisibleBounds(RECT* bounds) mut => VT.[Friend]GetVisibleBounds(&this, bounds);

	public HRESULT RegisterForUpdatesNeeded(IVirtualSurfaceUpdatesCallbackNative* callback) mut => VT.[Friend]RegisterForUpdatesNeeded(&this, callback);

	public HRESULT Resize(int32 newWidth, int32 newHeight) mut => VT.[Friend]Resize(&this, newWidth, newHeight);
}

[CRepr]struct ISwapChainBackgroundPanelNative : IUnknown
{
	public new const Guid IID = .(0x43bebd4e, 0xadd5, 0x4035, 0x8f, 0x85, 0x56, 0x08, 0xd0, 0x8e, 0x9d, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGISwapChain* swapChain) SetSwapChain;
	}


	public HRESULT SetSwapChain(IDXGISwapChain* swapChain) mut => VT.[Friend]SetSwapChain(&this, swapChain);
}

[CRepr]struct ISurfaceImageSourceManagerNative : IUnknown
{
	public new const Guid IID = .(0x4c8798b7, 0x1d88, 0x4a0f, 0xb5, 0x9b, 0xb9, 0x3f, 0x60, 0x0d, 0xe8, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* device) FlushAllSurfacesWithDevice;
	}


	public HRESULT FlushAllSurfacesWithDevice(IUnknown* device) mut => VT.[Friend]FlushAllSurfacesWithDevice(&this, device);
}

[CRepr]struct ISurfaceImageSourceNativeWithD2D : IUnknown
{
	public new const Guid IID = .(0x54298223, 0x41e1, 0x4a41, 0x9c, 0x08, 0x02, 0xe8, 0x25, 0x68, 0x64, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* device) SetDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* updateRect, in Guid iid, void** updateObject, POINT* offset) BeginDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SuspendDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeDraw;
	}


	public HRESULT SetDevice(IUnknown* device) mut => VT.[Friend]SetDevice(&this, device);

	public HRESULT BeginDraw(RECT* updateRect, in Guid iid, void** updateObject, POINT* offset) mut => VT.[Friend]BeginDraw(&this, updateRect, iid, updateObject, offset);

	public HRESULT EndDraw() mut => VT.[Friend]EndDraw(&this);

	public HRESULT SuspendDraw() mut => VT.[Friend]SuspendDraw(&this);

	public HRESULT ResumeDraw() mut => VT.[Friend]ResumeDraw(&this);
}

[CRepr]struct ISwapChainPanelNative : IUnknown
{
	public new const Guid IID = .(0xf92f19d2, 0x3ade, 0x45a6, 0xa2, 0x0c, 0xf6, 0xf1, 0xea, 0x90, 0x55, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGISwapChain* swapChain) SetSwapChain;
	}


	public HRESULT SetSwapChain(IDXGISwapChain* swapChain) mut => VT.[Friend]SetSwapChain(&this, swapChain);
}

[CRepr]struct ISwapChainPanelNative2 : ISwapChainPanelNative
{
	public new const Guid IID = .(0xd5a2f60c, 0x37b2, 0x44a2, 0x93, 0x7b, 0x8d, 0x8e, 0xb9, 0x72, 0x68, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISwapChainPanelNative.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE swapChainHandle) SetSwapChainHandle;
	}


	public HRESULT SetSwapChainHandle(HANDLE swapChainHandle) mut => VT.[Friend]SetSwapChainHandle(&this, swapChainHandle);
}

[CRepr]struct IDesktopWindowXamlSourceNative : IUnknown
{
	public new const Guid IID = .(0x3cbcf1bf, 0x2f76, 0x4e9c, 0x96, 0xab, 0xe8, 0x4b, 0x37, 0x97, 0x25, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND parentWnd) AttachToWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* hWnd) get_WindowHandle;
	}


	public HRESULT AttachToWindow(HWND parentWnd) mut => VT.[Friend]AttachToWindow(&this, parentWnd);

	public HRESULT get_WindowHandle(HWND* hWnd) mut => VT.[Friend]get_WindowHandle(&this, hWnd);
}

[CRepr]struct IDesktopWindowXamlSourceNative2 : IDesktopWindowXamlSourceNative
{
	public new const Guid IID = .(0xe3dcd8c7, 0x3057, 0x4692, 0x99, 0xc3, 0x7b, 0x77, 0x20, 0xaf, 0xda, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDesktopWindowXamlSourceNative.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* message, BOOL* result) PreTranslateMessage;
	}


	public HRESULT PreTranslateMessage(MSG* message, BOOL* result) mut => VT.[Friend]PreTranslateMessage(&this, message, result);
}

[CRepr]struct IReferenceTrackerTarget : IUnknown
{
	public new const Guid IID = .(0x64bd43f8, 0xbfee, 0x4ec4, 0xb7, 0xeb, 0x29, 0x35, 0x15, 0x8d, 0xae, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) AddRefFromReferenceTracker;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) ReleaseFromReferenceTracker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Peg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unpeg;
	}


	public uint32 AddRefFromReferenceTracker() mut => VT.[Friend]AddRefFromReferenceTracker(&this);

	public uint32 ReleaseFromReferenceTracker() mut => VT.[Friend]ReleaseFromReferenceTracker(&this);

	public HRESULT Peg() mut => VT.[Friend]Peg(&this);

	public HRESULT Unpeg() mut => VT.[Friend]Unpeg(&this);
}

[CRepr]struct IReferenceTracker : IUnknown
{
	public new const Guid IID = .(0x11d3b13a, 0x180e, 0x4789, 0xa8, 0xbe, 0x77, 0x12, 0x88, 0x28, 0x93, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ConnectFromTrackerSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisconnectFromTrackerSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFindReferenceTargetsCallback* callback) FindTrackerTargets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IReferenceTrackerManager** value) GetReferenceTrackerManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddRefFromTrackerSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseFromTrackerSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PegFromTrackerSource;
	}


	public HRESULT ConnectFromTrackerSource() mut => VT.[Friend]ConnectFromTrackerSource(&this);

	public HRESULT DisconnectFromTrackerSource() mut => VT.[Friend]DisconnectFromTrackerSource(&this);

	public HRESULT FindTrackerTargets(IFindReferenceTargetsCallback* callback) mut => VT.[Friend]FindTrackerTargets(&this, callback);

	public HRESULT GetReferenceTrackerManager(IReferenceTrackerManager** value) mut => VT.[Friend]GetReferenceTrackerManager(&this, value);

	public HRESULT AddRefFromTrackerSource() mut => VT.[Friend]AddRefFromTrackerSource(&this);

	public HRESULT ReleaseFromTrackerSource() mut => VT.[Friend]ReleaseFromTrackerSource(&this);

	public HRESULT PegFromTrackerSource() mut => VT.[Friend]PegFromTrackerSource(&this);
}

[CRepr]struct IReferenceTrackerManager : IUnknown
{
	public new const Guid IID = .(0x3cf184b4, 0x7ccb, 0x4dda, 0x84, 0x55, 0x7e, 0x6c, 0xe9, 0x9a, 0x32, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReferenceTrackingStarted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 findFailed) FindTrackerTargetsCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReferenceTrackingCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IReferenceTrackerHost* value) SetReferenceTrackerHost;
	}


	public HRESULT ReferenceTrackingStarted() mut => VT.[Friend]ReferenceTrackingStarted(&this);

	public HRESULT FindTrackerTargetsCompleted(uint8 findFailed) mut => VT.[Friend]FindTrackerTargetsCompleted(&this, findFailed);

	public HRESULT ReferenceTrackingCompleted() mut => VT.[Friend]ReferenceTrackingCompleted(&this);

	public HRESULT SetReferenceTrackerHost(IReferenceTrackerHost* value) mut => VT.[Friend]SetReferenceTrackerHost(&this, value);
}

[CRepr]struct IFindReferenceTargetsCallback : IUnknown
{
	public new const Guid IID = .(0x04b3486c, 0x4687, 0x4229, 0x8d, 0x14, 0x50, 0x5a, 0xb5, 0x84, 0xdd, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IReferenceTrackerTarget* target) FoundTrackerTarget;
	}


	public HRESULT FoundTrackerTarget(IReferenceTrackerTarget* target) mut => VT.[Friend]FoundTrackerTarget(&this, target);
}

[CRepr]struct IReferenceTrackerHost : IUnknown
{
	public new const Guid IID = .(0x29a71c6a, 0x3c42, 0x4416, 0xa3, 0x9d, 0xe2, 0x82, 0x5a, 0x07, 0xa7, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XAML_REFERENCETRACKER_DISCONNECT options) DisconnectUnusedReferenceSources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseDisconnectedReferenceSources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NotifyEndOfReferenceTrackingOnThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* unknown, IReferenceTrackerTarget** newReference) GetTrackerTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 bytesAllocated) AddMemoryPressure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 bytesAllocated) RemoveMemoryPressure;
	}


	public HRESULT DisconnectUnusedReferenceSources(XAML_REFERENCETRACKER_DISCONNECT options) mut => VT.[Friend]DisconnectUnusedReferenceSources(&this, options);

	public HRESULT ReleaseDisconnectedReferenceSources() mut => VT.[Friend]ReleaseDisconnectedReferenceSources(&this);

	public HRESULT NotifyEndOfReferenceTrackingOnThread() mut => VT.[Friend]NotifyEndOfReferenceTrackingOnThread(&this);

	public HRESULT GetTrackerTarget(IUnknown* unknown, IReferenceTrackerTarget** newReference) mut => VT.[Friend]GetTrackerTarget(&this, unknown, newReference);

	public HRESULT AddMemoryPressure(uint64 bytesAllocated) mut => VT.[Friend]AddMemoryPressure(&this, bytesAllocated);

	public HRESULT RemoveMemoryPressure(uint64 bytesAllocated) mut => VT.[Friend]RemoveMemoryPressure(&this, bytesAllocated);
}

[CRepr]struct IReferenceTrackerExtension : IUnknown
{
	public new const Guid IID = .(0x4e897caa, 0x59d5, 0x4613, 0x8f, 0x8c, 0xf7, 0xeb, 0xd1, 0xf3, 0x99, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct ITrackerOwner : IUnknown
{
	public new const Guid IID = .(0xeb24c20b, 0x9816, 0x4ac7, 0x8c, 0xff, 0x36, 0xf6, 0x7a, 0x11, 0x8f, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TrackerHandle__** returnValue) CreateTrackerHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TrackerHandle__* handle) DeleteTrackerHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TrackerHandle__* handle, IUnknown* value) SetTrackerValue;
		protected new function [CallingConvention(.Stdcall)] uint8(SelfOuter* self, TrackerHandle__* handle, IUnknown** returnValue) TryGetSafeTrackerValue;
	}


	public HRESULT CreateTrackerHandle(TrackerHandle__** returnValue) mut => VT.[Friend]CreateTrackerHandle(&this, returnValue);

	public HRESULT DeleteTrackerHandle(TrackerHandle__* handle) mut => VT.[Friend]DeleteTrackerHandle(&this, handle);

	public HRESULT SetTrackerValue(TrackerHandle__* handle, IUnknown* value) mut => VT.[Friend]SetTrackerValue(&this, handle, value);

	public uint8 TryGetSafeTrackerValue(TrackerHandle__* handle, IUnknown** returnValue) mut => VT.[Friend]TryGetSafeTrackerValue(&this, handle, returnValue);
}

#endregion
