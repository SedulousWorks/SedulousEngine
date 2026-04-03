using Win32.Foundation;
using Win32.Graphics.Dxgi.Common;
using Win32.System.Com;
using Win32.Graphics.Direct2D.Common;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Dxgi;
using Win32.Security;
using System;

namespace Win32.Graphics.DirectComposition;

#region Constants
public static
{
	public const int32 COMPOSITIONOBJECT_READ = 1;
	public const int32 COMPOSITIONOBJECT_WRITE = 2;
	public const uint32 DCOMPOSITION_MAX_WAITFORCOMPOSITORCLOCK_OBJECTS = 32;
	public const uint32 COMPOSITION_STATS_MAX_TARGETS = 256;
}
#endregion

#region Enums

[AllowDuplicates]
public enum DCOMPOSITION_BITMAP_INTERPOLATION_MODE : int32
{
	DCOMPOSITION_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR = 0,
	DCOMPOSITION_BITMAP_INTERPOLATION_MODE_LINEAR = 1,
	DCOMPOSITION_BITMAP_INTERPOLATION_MODE_INHERIT = -1,
}


[AllowDuplicates]
public enum DCOMPOSITION_BORDER_MODE : int32
{
	DCOMPOSITION_BORDER_MODE_SOFT = 0,
	DCOMPOSITION_BORDER_MODE_HARD = 1,
	DCOMPOSITION_BORDER_MODE_INHERIT = -1,
}


[AllowDuplicates]
public enum DCOMPOSITION_COMPOSITE_MODE : int32
{
	DCOMPOSITION_COMPOSITE_MODE_SOURCE_OVER = 0,
	DCOMPOSITION_COMPOSITE_MODE_DESTINATION_INVERT = 1,
	DCOMPOSITION_COMPOSITE_MODE_MIN_BLEND = 2,
	DCOMPOSITION_COMPOSITE_MODE_INHERIT = -1,
}


[AllowDuplicates]
public enum DCOMPOSITION_BACKFACE_VISIBILITY : int32
{
	DCOMPOSITION_BACKFACE_VISIBILITY_VISIBLE = 0,
	DCOMPOSITION_BACKFACE_VISIBILITY_HIDDEN = 1,
	DCOMPOSITION_BACKFACE_VISIBILITY_INHERIT = -1,
}


[AllowDuplicates]
public enum DCOMPOSITION_OPACITY_MODE : int32
{
	DCOMPOSITION_OPACITY_MODE_LAYER = 0,
	DCOMPOSITION_OPACITY_MODE_MULTIPLY = 1,
	DCOMPOSITION_OPACITY_MODE_INHERIT = -1,
}


[AllowDuplicates]
public enum DCOMPOSITION_DEPTH_MODE : int32
{
	DCOMPOSITION_DEPTH_MODE_TREE = 0,
	DCOMPOSITION_DEPTH_MODE_SPATIAL = 1,
	DCOMPOSITION_DEPTH_MODE_SORTED = 3,
	DCOMPOSITION_DEPTH_MODE_INHERIT = -1,
}


[AllowDuplicates]
public enum COMPOSITION_FRAME_ID_TYPE : int32
{
	COMPOSITION_FRAME_ID_CREATED = 0,
	COMPOSITION_FRAME_ID_CONFIRMED = 1,
	COMPOSITION_FRAME_ID_COMPLETED = 2,
}

#endregion


#region Structs
[CRepr]
public struct DCOMPOSITION_FRAME_STATISTICS
{
	public LARGE_INTEGER lastFrameTime;
	public DXGI_RATIONAL currentCompositionRate;
	public LARGE_INTEGER currentTime;
	public LARGE_INTEGER timeFrequency;
	public LARGE_INTEGER nextEstimatedFrameTime;
}

[CRepr]
public struct COMPOSITION_FRAME_STATS
{
	public uint64 startTime;
	public uint64 targetTime;
	public uint64 framePeriod;
}

[CRepr]
public struct COMPOSITION_TARGET_ID
{
	public LUID displayAdapterLuid;
	public LUID renderAdapterLuid;
	public uint32 vidPnSourceId;
	public uint32 vidPnTargetId;
	public uint32 uniqueId;
}

[CRepr]
public struct COMPOSITION_STATS
{
	public uint32 presentCount;
	public uint32 refreshCount;
	public uint32 virtualRefreshCount;
	public uint64 time;
}

[CRepr]
public struct COMPOSITION_TARGET_STATS
{
	public uint32 outstandingPresents;
	public uint64 presentTime;
	public uint64 vblankDuration;
	public COMPOSITION_STATS presentedStats;
	public COMPOSITION_STATS completedStats;
}

[CRepr]
public struct DCompositionInkTrailPoint
{
	public float x;
	public float y;
	public float radius;
}

#endregion

#region COM Types
[CRepr]struct IDCompositionAnimation : IUnknown
{
	public new const Guid IID = .(0xcbfd91d9, 0x51b2, 0x45e4, 0xb3, 0xde, 0xd1, 0x9c, 0xcf, 0xb8, 0x63, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER beginTime) SetAbsoluteBeginTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double beginOffset, float constantCoefficient, float linearCoefficient, float quadraticCoefficient, float cubicCoefficient) AddCubic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double beginOffset, float bias, float amplitude, float frequency, float phase) AddSinusoidal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double beginOffset, double durationToRepeat) AddRepeat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double endOffset, float endValue) End;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT SetAbsoluteBeginTime(LARGE_INTEGER beginTime) mut => VT.[Friend]SetAbsoluteBeginTime(&this, beginTime);

	public HRESULT AddCubic(double beginOffset, float constantCoefficient, float linearCoefficient, float quadraticCoefficient, float cubicCoefficient) mut => VT.[Friend]AddCubic(&this, beginOffset, constantCoefficient, linearCoefficient, quadraticCoefficient, cubicCoefficient);

	public HRESULT AddSinusoidal(double beginOffset, float bias, float amplitude, float frequency, float phase) mut => VT.[Friend]AddSinusoidal(&this, beginOffset, bias, amplitude, frequency, phase);

	public HRESULT AddRepeat(double beginOffset, double durationToRepeat) mut => VT.[Friend]AddRepeat(&this, beginOffset, durationToRepeat);

	public HRESULT End(double endOffset, float endValue) mut => VT.[Friend]End(&this, endOffset, endValue);
}

[CRepr]struct IDCompositionDevice : IUnknown
{
	public new const Guid IID = .(0xc37ea93a, 0xe7aa, 0x450d, 0xb1, 0x6f, 0x97, 0x46, 0xcb, 0x04, 0x07, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WaitForCommitCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_FRAME_STATISTICS* statistics) GetFrameStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, BOOL topmost, IDCompositionTarget** target) CreateTargetForHwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionVisual** visual) CreateVisual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 width, uint32 height, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionSurface** surface) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 initialWidth, uint32 initialHeight, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionVirtualSurface** virtualSurface) CreateVirtualSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE handle, IUnknown** surface) CreateSurfaceFromHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IUnknown** surface) CreateSurfaceFromHwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTranslateTransform** translateTransform) CreateTranslateTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionScaleTransform** scaleTransform) CreateScaleTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionRotateTransform** rotateTransform) CreateRotateTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionSkewTransform** skewTransform) CreateSkewTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionMatrixTransform** matrixTransform) CreateMatrixTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform** transforms, uint32 elements, IDCompositionTransform** transformGroup) CreateTransformGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTranslateTransform3D** translateTransform3D) CreateTranslateTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionScaleTransform3D** scaleTransform3D) CreateScaleTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionRotateTransform3D** rotateTransform3D) CreateRotateTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionMatrixTransform3D** matrixTransform3D) CreateMatrixTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform3D** transforms3D, uint32 elements, IDCompositionTransform3D** transform3DGroup) CreateTransform3DGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionEffectGroup** effectGroup) CreateEffectGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionRectangleClip** clip) CreateRectangleClip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation** animation) CreateAnimation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfValid) CheckDeviceState;
	}


	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT WaitForCommitCompletion() mut => VT.[Friend]WaitForCommitCompletion(&this);

	public HRESULT GetFrameStatistics(DCOMPOSITION_FRAME_STATISTICS* statistics) mut => VT.[Friend]GetFrameStatistics(&this, statistics);

	public HRESULT CreateTargetForHwnd(HWND hwnd, BOOL topmost, IDCompositionTarget** target) mut => VT.[Friend]CreateTargetForHwnd(&this, hwnd, topmost, target);

	public HRESULT CreateVisual(IDCompositionVisual** visual) mut => VT.[Friend]CreateVisual(&this, visual);

	public HRESULT CreateSurface(uint32 width, uint32 height, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionSurface** surface) mut => VT.[Friend]CreateSurface(&this, width, height, pixelFormat, alphaMode, surface);

	public HRESULT CreateVirtualSurface(uint32 initialWidth, uint32 initialHeight, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionVirtualSurface** virtualSurface) mut => VT.[Friend]CreateVirtualSurface(&this, initialWidth, initialHeight, pixelFormat, alphaMode, virtualSurface);

	public HRESULT CreateSurfaceFromHandle(HANDLE handle, IUnknown** surface) mut => VT.[Friend]CreateSurfaceFromHandle(&this, handle, surface);

	public HRESULT CreateSurfaceFromHwnd(HWND hwnd, IUnknown** surface) mut => VT.[Friend]CreateSurfaceFromHwnd(&this, hwnd, surface);

	public HRESULT CreateTranslateTransform(IDCompositionTranslateTransform** translateTransform) mut => VT.[Friend]CreateTranslateTransform(&this, translateTransform);

	public HRESULT CreateScaleTransform(IDCompositionScaleTransform** scaleTransform) mut => VT.[Friend]CreateScaleTransform(&this, scaleTransform);

	public HRESULT CreateRotateTransform(IDCompositionRotateTransform** rotateTransform) mut => VT.[Friend]CreateRotateTransform(&this, rotateTransform);

	public HRESULT CreateSkewTransform(IDCompositionSkewTransform** skewTransform) mut => VT.[Friend]CreateSkewTransform(&this, skewTransform);

	public HRESULT CreateMatrixTransform(IDCompositionMatrixTransform** matrixTransform) mut => VT.[Friend]CreateMatrixTransform(&this, matrixTransform);

	public HRESULT CreateTransformGroup(IDCompositionTransform** transforms, uint32 elements, IDCompositionTransform** transformGroup) mut => VT.[Friend]CreateTransformGroup(&this, transforms, elements, transformGroup);

	public HRESULT CreateTranslateTransform3D(IDCompositionTranslateTransform3D** translateTransform3D) mut => VT.[Friend]CreateTranslateTransform3D(&this, translateTransform3D);

	public HRESULT CreateScaleTransform3D(IDCompositionScaleTransform3D** scaleTransform3D) mut => VT.[Friend]CreateScaleTransform3D(&this, scaleTransform3D);

	public HRESULT CreateRotateTransform3D(IDCompositionRotateTransform3D** rotateTransform3D) mut => VT.[Friend]CreateRotateTransform3D(&this, rotateTransform3D);

	public HRESULT CreateMatrixTransform3D(IDCompositionMatrixTransform3D** matrixTransform3D) mut => VT.[Friend]CreateMatrixTransform3D(&this, matrixTransform3D);

	public HRESULT CreateTransform3DGroup(IDCompositionTransform3D** transforms3D, uint32 elements, IDCompositionTransform3D** transform3DGroup) mut => VT.[Friend]CreateTransform3DGroup(&this, transforms3D, elements, transform3DGroup);

	public HRESULT CreateEffectGroup(IDCompositionEffectGroup** effectGroup) mut => VT.[Friend]CreateEffectGroup(&this, effectGroup);

	public HRESULT CreateRectangleClip(IDCompositionRectangleClip** clip) mut => VT.[Friend]CreateRectangleClip(&this, clip);

	public HRESULT CreateAnimation(IDCompositionAnimation** animation) mut => VT.[Friend]CreateAnimation(&this, animation);

	public HRESULT CheckDeviceState(BOOL* pfValid) mut => VT.[Friend]CheckDeviceState(&this, pfValid);
}

[CRepr]struct IDCompositionTarget : IUnknown
{
	public new const Guid IID = .(0xeacdd04c, 0x117e, 0x4e17, 0x88, 0xf4, 0xd1, 0xb1, 0x2b, 0x0e, 0x3d, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionVisual* visual) SetRoot;
	}


	public HRESULT SetRoot(IDCompositionVisual* visual) mut => VT.[Friend]SetRoot(&this, visual);
}

[CRepr]struct IDCompositionVisual : IUnknown
{
	public new const Guid IID = .(0x4d93059d, 0x097b, 0x4651, 0x9a, 0x60, 0xf0, 0xf2, 0x51, 0x16, 0xe2, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetX) SetOffsetX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetY) SetOffsetY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform* transform) SetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_MATRIX_3X2_F* matrix) SetTransform0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionVisual* visual) SetTransformParent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionEffect* effect) SetEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_BITMAP_INTERPOLATION_MODE interpolationMode) SetBitmapInterpolationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_BORDER_MODE borderMode) SetBorderMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionClip* clip) SetClip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_RECT_F* rect) SetClip0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* content) SetContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionVisual* visual, BOOL insertAbove, IDCompositionVisual* referenceVisual) AddVisual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionVisual* visual) RemoveVisual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllVisuals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_COMPOSITE_MODE compositeMode) SetCompositeMode;
	}


	public HRESULT SetOffsetX(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetX(&this, animation);

	public HRESULT SetOffsetX(float offsetX) mut => VT.[Friend]SetOffsetX0(&this, offsetX);

	public HRESULT SetOffsetY(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetY(&this, animation);

	public HRESULT SetOffsetY(float offsetY) mut => VT.[Friend]SetOffsetY0(&this, offsetY);

	public HRESULT SetTransform(IDCompositionTransform* transform) mut => VT.[Friend]SetTransform(&this, transform);

	public HRESULT SetTransform(D2D_MATRIX_3X2_F* matrix) mut => VT.[Friend]SetTransform0(&this, matrix);

	public HRESULT SetTransformParent(IDCompositionVisual* visual) mut => VT.[Friend]SetTransformParent(&this, visual);

	public HRESULT SetEffect(IDCompositionEffect* effect) mut => VT.[Friend]SetEffect(&this, effect);

	public HRESULT SetBitmapInterpolationMode(DCOMPOSITION_BITMAP_INTERPOLATION_MODE interpolationMode) mut => VT.[Friend]SetBitmapInterpolationMode(&this, interpolationMode);

	public HRESULT SetBorderMode(DCOMPOSITION_BORDER_MODE borderMode) mut => VT.[Friend]SetBorderMode(&this, borderMode);

	public HRESULT SetClip(IDCompositionClip* clip) mut => VT.[Friend]SetClip(&this, clip);

	public HRESULT SetClip(D2D_RECT_F* rect) mut => VT.[Friend]SetClip0(&this, rect);

	public HRESULT SetContent(IUnknown* content) mut => VT.[Friend]SetContent(&this, content);

	public HRESULT AddVisual(IDCompositionVisual* visual, BOOL insertAbove, IDCompositionVisual* referenceVisual) mut => VT.[Friend]AddVisual(&this, visual, insertAbove, referenceVisual);

	public HRESULT RemoveVisual(IDCompositionVisual* visual) mut => VT.[Friend]RemoveVisual(&this, visual);

	public HRESULT RemoveAllVisuals() mut => VT.[Friend]RemoveAllVisuals(&this);

	public HRESULT SetCompositeMode(DCOMPOSITION_COMPOSITE_MODE compositeMode) mut => VT.[Friend]SetCompositeMode(&this, compositeMode);
}

[CRepr]struct IDCompositionEffect : IUnknown
{
	public new const Guid IID = .(0xec81b08f, 0xbfcb, 0x4e8d, 0xb1, 0x93, 0xa9, 0x15, 0x58, 0x79, 0x99, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IDCompositionTransform3D : IDCompositionEffect
{
	public new const Guid IID = .(0x71185722, 0x246b, 0x41f2, 0xaa, 0xd1, 0x04, 0x43, 0xf7, 0xf4, 0xbf, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionEffect.VTable
	{
	}

}

[CRepr]struct IDCompositionTransform : IDCompositionTransform3D
{
	public new const Guid IID = .(0xfd55faa7, 0x37e0, 0x4c20, 0x95, 0xd2, 0x9b, 0xe4, 0x5b, 0xc3, 0x3f, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform3D.VTable
	{
	}

}

[CRepr]struct IDCompositionTranslateTransform : IDCompositionTransform
{
	public new const Guid IID = .(0x06791122, 0xc6f0, 0x417d, 0x83, 0x23, 0x26, 0x9e, 0x98, 0x7f, 0x59, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetX) SetOffsetX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetY) SetOffsetY0;
	}


	public HRESULT SetOffsetX(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetX(&this, animation);

	public HRESULT SetOffsetX(float offsetX) mut => VT.[Friend]SetOffsetX0(&this, offsetX);

	public HRESULT SetOffsetY(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetY(&this, animation);

	public HRESULT SetOffsetY(float offsetY) mut => VT.[Friend]SetOffsetY0(&this, offsetY);
}

[CRepr]struct IDCompositionScaleTransform : IDCompositionTransform
{
	public new const Guid IID = .(0x71fde914, 0x40ef, 0x45ef, 0xbd, 0x51, 0x68, 0xb0, 0x37, 0xc3, 0x39, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetScaleX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float scaleX) SetScaleX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetScaleY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float scaleY) SetScaleY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerX) SetCenterX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerY) SetCenterY0;
	}


	public HRESULT SetScaleX(IDCompositionAnimation* animation) mut => VT.[Friend]SetScaleX(&this, animation);

	public HRESULT SetScaleX(float scaleX) mut => VT.[Friend]SetScaleX0(&this, scaleX);

	public HRESULT SetScaleY(IDCompositionAnimation* animation) mut => VT.[Friend]SetScaleY(&this, animation);

	public HRESULT SetScaleY(float scaleY) mut => VT.[Friend]SetScaleY0(&this, scaleY);

	public HRESULT SetCenterX(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterX(&this, animation);

	public HRESULT SetCenterX(float centerX) mut => VT.[Friend]SetCenterX0(&this, centerX);

	public HRESULT SetCenterY(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterY(&this, animation);

	public HRESULT SetCenterY(float centerY) mut => VT.[Friend]SetCenterY0(&this, centerY);
}

[CRepr]struct IDCompositionRotateTransform : IDCompositionTransform
{
	public new const Guid IID = .(0x641ed83c, 0xae96, 0x46c5, 0x90, 0xdc, 0x32, 0x77, 0x4c, 0xc5, 0xc6, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAngle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float angle) SetAngle0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerX) SetCenterX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerY) SetCenterY0;
	}


	public HRESULT SetAngle(IDCompositionAnimation* animation) mut => VT.[Friend]SetAngle(&this, animation);

	public HRESULT SetAngle(float angle) mut => VT.[Friend]SetAngle0(&this, angle);

	public HRESULT SetCenterX(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterX(&this, animation);

	public HRESULT SetCenterX(float centerX) mut => VT.[Friend]SetCenterX0(&this, centerX);

	public HRESULT SetCenterY(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterY(&this, animation);

	public HRESULT SetCenterY(float centerY) mut => VT.[Friend]SetCenterY0(&this, centerY);
}

[CRepr]struct IDCompositionSkewTransform : IDCompositionTransform
{
	public new const Guid IID = .(0xe57aa735, 0xdcdb, 0x4c72, 0x9c, 0x61, 0x05, 0x91, 0xf5, 0x88, 0x89, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAngleX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float angleX) SetAngleX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAngleY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float angleY) SetAngleY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerX) SetCenterX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerY) SetCenterY0;
	}


	public HRESULT SetAngleX(IDCompositionAnimation* animation) mut => VT.[Friend]SetAngleX(&this, animation);

	public HRESULT SetAngleX(float angleX) mut => VT.[Friend]SetAngleX0(&this, angleX);

	public HRESULT SetAngleY(IDCompositionAnimation* animation) mut => VT.[Friend]SetAngleY(&this, animation);

	public HRESULT SetAngleY(float angleY) mut => VT.[Friend]SetAngleY0(&this, angleY);

	public HRESULT SetCenterX(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterX(&this, animation);

	public HRESULT SetCenterX(float centerX) mut => VT.[Friend]SetCenterX0(&this, centerX);

	public HRESULT SetCenterY(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterY(&this, animation);

	public HRESULT SetCenterY(float centerY) mut => VT.[Friend]SetCenterY0(&this, centerY);
}

[CRepr]struct IDCompositionMatrixTransform : IDCompositionTransform
{
	public new const Guid IID = .(0x16cdff07, 0xc503, 0x419c, 0x83, 0xf2, 0x09, 0x65, 0xc7, 0xaf, 0x1f, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_MATRIX_3X2_F* matrix) SetMatrix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, IDCompositionAnimation* animation) SetMatrixElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, float value) SetMatrixElement0;
	}


	public HRESULT SetMatrix(D2D_MATRIX_3X2_F* matrix) mut => VT.[Friend]SetMatrix(&this, matrix);

	public HRESULT SetMatrixElement(int32 row, int32 column, IDCompositionAnimation* animation) mut => VT.[Friend]SetMatrixElement(&this, row, column, animation);

	public HRESULT SetMatrixElement(int32 row, int32 column, float value) mut => VT.[Friend]SetMatrixElement0(&this, row, column, value);
}

[CRepr]struct IDCompositionEffectGroup : IDCompositionEffect
{
	public new const Guid IID = .(0xa7929a74, 0xe6b2, 0x4bd6, 0x8b, 0x95, 0x40, 0x40, 0x11, 0x9c, 0xa3, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOpacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float opacity) SetOpacity0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform3D* transform3D) SetTransform3D;
	}


	public HRESULT SetOpacity(IDCompositionAnimation* animation) mut => VT.[Friend]SetOpacity(&this, animation);

	public HRESULT SetOpacity(float opacity) mut => VT.[Friend]SetOpacity0(&this, opacity);

	public HRESULT SetTransform3D(IDCompositionTransform3D* transform3D) mut => VT.[Friend]SetTransform3D(&this, transform3D);
}

[CRepr]struct IDCompositionTranslateTransform3D : IDCompositionTransform3D
{
	public new const Guid IID = .(0x91636d4b, 0x9ba1, 0x4532, 0xaa, 0xf7, 0xe3, 0x34, 0x49, 0x94, 0xd7, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform3D.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetX) SetOffsetX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetY) SetOffsetY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetZ;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetZ) SetOffsetZ0;
	}


	public HRESULT SetOffsetX(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetX(&this, animation);

	public HRESULT SetOffsetX(float offsetX) mut => VT.[Friend]SetOffsetX0(&this, offsetX);

	public HRESULT SetOffsetY(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetY(&this, animation);

	public HRESULT SetOffsetY(float offsetY) mut => VT.[Friend]SetOffsetY0(&this, offsetY);

	public HRESULT SetOffsetZ(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetZ(&this, animation);

	public HRESULT SetOffsetZ(float offsetZ) mut => VT.[Friend]SetOffsetZ0(&this, offsetZ);
}

[CRepr]struct IDCompositionScaleTransform3D : IDCompositionTransform3D
{
	public new const Guid IID = .(0x2a9e9ead, 0x364b, 0x4b15, 0xa7, 0xc4, 0xa1, 0x99, 0x7f, 0x78, 0xb3, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform3D.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetScaleX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float scaleX) SetScaleX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetScaleY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float scaleY) SetScaleY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetScaleZ;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float scaleZ) SetScaleZ0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerX) SetCenterX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerY) SetCenterY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterZ;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerZ) SetCenterZ0;
	}


	public HRESULT SetScaleX(IDCompositionAnimation* animation) mut => VT.[Friend]SetScaleX(&this, animation);

	public HRESULT SetScaleX(float scaleX) mut => VT.[Friend]SetScaleX0(&this, scaleX);

	public HRESULT SetScaleY(IDCompositionAnimation* animation) mut => VT.[Friend]SetScaleY(&this, animation);

	public HRESULT SetScaleY(float scaleY) mut => VT.[Friend]SetScaleY0(&this, scaleY);

	public HRESULT SetScaleZ(IDCompositionAnimation* animation) mut => VT.[Friend]SetScaleZ(&this, animation);

	public HRESULT SetScaleZ(float scaleZ) mut => VT.[Friend]SetScaleZ0(&this, scaleZ);

	public HRESULT SetCenterX(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterX(&this, animation);

	public HRESULT SetCenterX(float centerX) mut => VT.[Friend]SetCenterX0(&this, centerX);

	public HRESULT SetCenterY(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterY(&this, animation);

	public HRESULT SetCenterY(float centerY) mut => VT.[Friend]SetCenterY0(&this, centerY);

	public HRESULT SetCenterZ(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterZ(&this, animation);

	public HRESULT SetCenterZ(float centerZ) mut => VT.[Friend]SetCenterZ0(&this, centerZ);
}

[CRepr]struct IDCompositionRotateTransform3D : IDCompositionTransform3D
{
	public new const Guid IID = .(0xd8f5b23f, 0xd429, 0x4a91, 0xb5, 0x5a, 0xd2, 0xf4, 0x5f, 0xd7, 0x5b, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform3D.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAngle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float angle) SetAngle0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAxisX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float axisX) SetAxisX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAxisY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float axisY) SetAxisY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAxisZ;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float axisZ) SetAxisZ0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerX) SetCenterX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerY) SetCenterY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCenterZ;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float centerZ) SetCenterZ0;
	}


	public HRESULT SetAngle(IDCompositionAnimation* animation) mut => VT.[Friend]SetAngle(&this, animation);

	public HRESULT SetAngle(float angle) mut => VT.[Friend]SetAngle0(&this, angle);

	public HRESULT SetAxisX(IDCompositionAnimation* animation) mut => VT.[Friend]SetAxisX(&this, animation);

	public HRESULT SetAxisX(float axisX) mut => VT.[Friend]SetAxisX0(&this, axisX);

	public HRESULT SetAxisY(IDCompositionAnimation* animation) mut => VT.[Friend]SetAxisY(&this, animation);

	public HRESULT SetAxisY(float axisY) mut => VT.[Friend]SetAxisY0(&this, axisY);

	public HRESULT SetAxisZ(IDCompositionAnimation* animation) mut => VT.[Friend]SetAxisZ(&this, animation);

	public HRESULT SetAxisZ(float axisZ) mut => VT.[Friend]SetAxisZ0(&this, axisZ);

	public HRESULT SetCenterX(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterX(&this, animation);

	public HRESULT SetCenterX(float centerX) mut => VT.[Friend]SetCenterX0(&this, centerX);

	public HRESULT SetCenterY(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterY(&this, animation);

	public HRESULT SetCenterY(float centerY) mut => VT.[Friend]SetCenterY0(&this, centerY);

	public HRESULT SetCenterZ(IDCompositionAnimation* animation) mut => VT.[Friend]SetCenterZ(&this, animation);

	public HRESULT SetCenterZ(float centerZ) mut => VT.[Friend]SetCenterZ0(&this, centerZ);
}

[CRepr]struct IDCompositionMatrixTransform3D : IDCompositionTransform3D
{
	public new const Guid IID = .(0x4b3363f0, 0x643b, 0x41b7, 0xb6, 0xe0, 0xcc, 0xf2, 0x2d, 0x34, 0x46, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionTransform3D.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D3DMATRIX* matrix) SetMatrix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, IDCompositionAnimation* animation) SetMatrixElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, float value) SetMatrixElement0;
	}


	public HRESULT SetMatrix(D3DMATRIX* matrix) mut => VT.[Friend]SetMatrix(&this, matrix);

	public HRESULT SetMatrixElement(int32 row, int32 column, IDCompositionAnimation* animation) mut => VT.[Friend]SetMatrixElement(&this, row, column, animation);

	public HRESULT SetMatrixElement(int32 row, int32 column, float value) mut => VT.[Friend]SetMatrixElement0(&this, row, column, value);
}

[CRepr]struct IDCompositionClip : IUnknown
{
	public new const Guid IID = .(0x64ac3703, 0x9d3f, 0x45ec, 0xa1, 0x09, 0x7c, 0xac, 0x0e, 0x7a, 0x13, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IDCompositionRectangleClip : IDCompositionClip
{
	public new const Guid IID = .(0x9842ad7d, 0xd9cf, 0x4908, 0xae, 0xd7, 0x48, 0xb5, 0x1d, 0xa5, 0xe7, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionClip.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetLeft;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float left) SetLeft0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float top) SetTop0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetRight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float right) SetRight0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float bottom) SetBottom0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetTopLeftRadiusX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetTopLeftRadiusX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetTopLeftRadiusY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetTopLeftRadiusY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetTopRightRadiusX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetTopRightRadiusX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetTopRightRadiusY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetTopRightRadiusY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBottomLeftRadiusX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetBottomLeftRadiusX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBottomLeftRadiusY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetBottomLeftRadiusY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBottomRightRadiusX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetBottomRightRadiusX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBottomRightRadiusY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) SetBottomRightRadiusY0;
	}


	public HRESULT SetLeft(IDCompositionAnimation* animation) mut => VT.[Friend]SetLeft(&this, animation);

	public HRESULT SetLeft(float left) mut => VT.[Friend]SetLeft0(&this, left);

	public HRESULT SetTop(IDCompositionAnimation* animation) mut => VT.[Friend]SetTop(&this, animation);

	public HRESULT SetTop(float top) mut => VT.[Friend]SetTop0(&this, top);

	public HRESULT SetRight(IDCompositionAnimation* animation) mut => VT.[Friend]SetRight(&this, animation);

	public HRESULT SetRight(float right) mut => VT.[Friend]SetRight0(&this, right);

	public HRESULT SetBottom(IDCompositionAnimation* animation) mut => VT.[Friend]SetBottom(&this, animation);

	public HRESULT SetBottom(float bottom) mut => VT.[Friend]SetBottom0(&this, bottom);

	public HRESULT SetTopLeftRadiusX(IDCompositionAnimation* animation) mut => VT.[Friend]SetTopLeftRadiusX(&this, animation);

	public HRESULT SetTopLeftRadiusX(float radius) mut => VT.[Friend]SetTopLeftRadiusX0(&this, radius);

	public HRESULT SetTopLeftRadiusY(IDCompositionAnimation* animation) mut => VT.[Friend]SetTopLeftRadiusY(&this, animation);

	public HRESULT SetTopLeftRadiusY(float radius) mut => VT.[Friend]SetTopLeftRadiusY0(&this, radius);

	public HRESULT SetTopRightRadiusX(IDCompositionAnimation* animation) mut => VT.[Friend]SetTopRightRadiusX(&this, animation);

	public HRESULT SetTopRightRadiusX(float radius) mut => VT.[Friend]SetTopRightRadiusX0(&this, radius);

	public HRESULT SetTopRightRadiusY(IDCompositionAnimation* animation) mut => VT.[Friend]SetTopRightRadiusY(&this, animation);

	public HRESULT SetTopRightRadiusY(float radius) mut => VT.[Friend]SetTopRightRadiusY0(&this, radius);

	public HRESULT SetBottomLeftRadiusX(IDCompositionAnimation* animation) mut => VT.[Friend]SetBottomLeftRadiusX(&this, animation);

	public HRESULT SetBottomLeftRadiusX(float radius) mut => VT.[Friend]SetBottomLeftRadiusX0(&this, radius);

	public HRESULT SetBottomLeftRadiusY(IDCompositionAnimation* animation) mut => VT.[Friend]SetBottomLeftRadiusY(&this, animation);

	public HRESULT SetBottomLeftRadiusY(float radius) mut => VT.[Friend]SetBottomLeftRadiusY0(&this, radius);

	public HRESULT SetBottomRightRadiusX(IDCompositionAnimation* animation) mut => VT.[Friend]SetBottomRightRadiusX(&this, animation);

	public HRESULT SetBottomRightRadiusX(float radius) mut => VT.[Friend]SetBottomRightRadiusX0(&this, radius);

	public HRESULT SetBottomRightRadiusY(IDCompositionAnimation* animation) mut => VT.[Friend]SetBottomRightRadiusY(&this, animation);

	public HRESULT SetBottomRightRadiusY(float radius) mut => VT.[Friend]SetBottomRightRadiusY0(&this, radius);
}

[CRepr]struct IDCompositionSurface : IUnknown
{
	public new const Guid IID = .(0xbb8a4953, 0x2c99, 0x4f5a, 0x96, 0xf5, 0x48, 0x19, 0x02, 0x7f, 0xa3, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* updateRect, in Guid iid, void** updateObject, POINT* updateOffset) BeginDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SuspendDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* scrollRect, RECT* clipRect, int32 offsetX, int32 offsetY) Scroll;
	}


	public HRESULT BeginDraw(RECT* updateRect, in Guid iid, void** updateObject, POINT* updateOffset) mut => VT.[Friend]BeginDraw(&this, updateRect, iid, updateObject, updateOffset);

	public HRESULT EndDraw() mut => VT.[Friend]EndDraw(&this);

	public HRESULT SuspendDraw() mut => VT.[Friend]SuspendDraw(&this);

	public HRESULT ResumeDraw() mut => VT.[Friend]ResumeDraw(&this);

	public HRESULT Scroll(RECT* scrollRect, RECT* clipRect, int32 offsetX, int32 offsetY) mut => VT.[Friend]Scroll(&this, scrollRect, clipRect, offsetX, offsetY);
}

[CRepr]struct IDCompositionVirtualSurface : IDCompositionSurface
{
	public new const Guid IID = .(0xae471c51, 0x5f53, 0x4a24, 0x8d, 0x3e, 0xd0, 0xc3, 0x9c, 0x30, 0xb3, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionSurface.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 width, uint32 height) Resize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* rectangles, uint32 count) Trim;
	}


	public HRESULT Resize(uint32 width, uint32 height) mut => VT.[Friend]Resize(&this, width, height);

	public HRESULT Trim(RECT* rectangles, uint32 count) mut => VT.[Friend]Trim(&this, rectangles, count);
}

[CRepr]struct IDCompositionDevice2 : IUnknown
{
	public new const Guid IID = .(0x75f6468d, 0x1b8e, 0x447c, 0x9b, 0xc6, 0x75, 0xfe, 0xa8, 0x0b, 0x5b, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WaitForCommitCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_FRAME_STATISTICS* statistics) GetFrameStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionVisual2** visual) CreateVisual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* renderingDevice, IDCompositionSurfaceFactory** surfaceFactory) CreateSurfaceFactory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 width, uint32 height, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionSurface** surface) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 initialWidth, uint32 initialHeight, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionVirtualSurface** virtualSurface) CreateVirtualSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTranslateTransform** translateTransform) CreateTranslateTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionScaleTransform** scaleTransform) CreateScaleTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionRotateTransform** rotateTransform) CreateRotateTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionSkewTransform** skewTransform) CreateSkewTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionMatrixTransform** matrixTransform) CreateMatrixTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform** transforms, uint32 elements, IDCompositionTransform** transformGroup) CreateTransformGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTranslateTransform3D** translateTransform3D) CreateTranslateTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionScaleTransform3D** scaleTransform3D) CreateScaleTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionRotateTransform3D** rotateTransform3D) CreateRotateTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionMatrixTransform3D** matrixTransform3D) CreateMatrixTransform3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform3D** transforms3D, uint32 elements, IDCompositionTransform3D** transform3DGroup) CreateTransform3DGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionEffectGroup** effectGroup) CreateEffectGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionRectangleClip** clip) CreateRectangleClip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation** animation) CreateAnimation;
	}


	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT WaitForCommitCompletion() mut => VT.[Friend]WaitForCommitCompletion(&this);

	public HRESULT GetFrameStatistics(DCOMPOSITION_FRAME_STATISTICS* statistics) mut => VT.[Friend]GetFrameStatistics(&this, statistics);

	public HRESULT CreateVisual(IDCompositionVisual2** visual) mut => VT.[Friend]CreateVisual(&this, visual);

	public HRESULT CreateSurfaceFactory(IUnknown* renderingDevice, IDCompositionSurfaceFactory** surfaceFactory) mut => VT.[Friend]CreateSurfaceFactory(&this, renderingDevice, surfaceFactory);

	public HRESULT CreateSurface(uint32 width, uint32 height, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionSurface** surface) mut => VT.[Friend]CreateSurface(&this, width, height, pixelFormat, alphaMode, surface);

	public HRESULT CreateVirtualSurface(uint32 initialWidth, uint32 initialHeight, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionVirtualSurface** virtualSurface) mut => VT.[Friend]CreateVirtualSurface(&this, initialWidth, initialHeight, pixelFormat, alphaMode, virtualSurface);

	public HRESULT CreateTranslateTransform(IDCompositionTranslateTransform** translateTransform) mut => VT.[Friend]CreateTranslateTransform(&this, translateTransform);

	public HRESULT CreateScaleTransform(IDCompositionScaleTransform** scaleTransform) mut => VT.[Friend]CreateScaleTransform(&this, scaleTransform);

	public HRESULT CreateRotateTransform(IDCompositionRotateTransform** rotateTransform) mut => VT.[Friend]CreateRotateTransform(&this, rotateTransform);

	public HRESULT CreateSkewTransform(IDCompositionSkewTransform** skewTransform) mut => VT.[Friend]CreateSkewTransform(&this, skewTransform);

	public HRESULT CreateMatrixTransform(IDCompositionMatrixTransform** matrixTransform) mut => VT.[Friend]CreateMatrixTransform(&this, matrixTransform);

	public HRESULT CreateTransformGroup(IDCompositionTransform** transforms, uint32 elements, IDCompositionTransform** transformGroup) mut => VT.[Friend]CreateTransformGroup(&this, transforms, elements, transformGroup);

	public HRESULT CreateTranslateTransform3D(IDCompositionTranslateTransform3D** translateTransform3D) mut => VT.[Friend]CreateTranslateTransform3D(&this, translateTransform3D);

	public HRESULT CreateScaleTransform3D(IDCompositionScaleTransform3D** scaleTransform3D) mut => VT.[Friend]CreateScaleTransform3D(&this, scaleTransform3D);

	public HRESULT CreateRotateTransform3D(IDCompositionRotateTransform3D** rotateTransform3D) mut => VT.[Friend]CreateRotateTransform3D(&this, rotateTransform3D);

	public HRESULT CreateMatrixTransform3D(IDCompositionMatrixTransform3D** matrixTransform3D) mut => VT.[Friend]CreateMatrixTransform3D(&this, matrixTransform3D);

	public HRESULT CreateTransform3DGroup(IDCompositionTransform3D** transforms3D, uint32 elements, IDCompositionTransform3D** transform3DGroup) mut => VT.[Friend]CreateTransform3DGroup(&this, transforms3D, elements, transform3DGroup);

	public HRESULT CreateEffectGroup(IDCompositionEffectGroup** effectGroup) mut => VT.[Friend]CreateEffectGroup(&this, effectGroup);

	public HRESULT CreateRectangleClip(IDCompositionRectangleClip** clip) mut => VT.[Friend]CreateRectangleClip(&this, clip);

	public HRESULT CreateAnimation(IDCompositionAnimation** animation) mut => VT.[Friend]CreateAnimation(&this, animation);
}

[CRepr]struct IDCompositionDesktopDevice : IDCompositionDevice2
{
	public new const Guid IID = .(0x5f4633fe, 0x1e08, 0x4cb8, 0x8c, 0x75, 0xce, 0x24, 0x33, 0x3f, 0x56, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionDevice2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, BOOL topmost, IDCompositionTarget** target) CreateTargetForHwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE handle, IUnknown** surface) CreateSurfaceFromHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IUnknown** surface) CreateSurfaceFromHwnd;
	}


	public HRESULT CreateTargetForHwnd(HWND hwnd, BOOL topmost, IDCompositionTarget** target) mut => VT.[Friend]CreateTargetForHwnd(&this, hwnd, topmost, target);

	public HRESULT CreateSurfaceFromHandle(HANDLE handle, IUnknown** surface) mut => VT.[Friend]CreateSurfaceFromHandle(&this, handle, surface);

	public HRESULT CreateSurfaceFromHwnd(HWND hwnd, IUnknown** surface) mut => VT.[Friend]CreateSurfaceFromHwnd(&this, hwnd, surface);
}

[CRepr]struct IDCompositionDeviceDebug : IUnknown
{
	public new const Guid IID = .(0xa1a3c64a, 0x224f, 0x4a81, 0x97, 0x73, 0x4f, 0x03, 0xa8, 0x9d, 0x3c, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableDebugCounters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableDebugCounters;
	}


	public HRESULT EnableDebugCounters() mut => VT.[Friend]EnableDebugCounters(&this);

	public HRESULT DisableDebugCounters() mut => VT.[Friend]DisableDebugCounters(&this);
}

[CRepr]struct IDCompositionSurfaceFactory : IUnknown
{
	public new const Guid IID = .(0xe334bc12, 0x3937, 0x4e02, 0x85, 0xeb, 0xfc, 0xf4, 0xeb, 0x30, 0xd2, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 width, uint32 height, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionSurface** surface) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 initialWidth, uint32 initialHeight, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionVirtualSurface** virtualSurface) CreateVirtualSurface;
	}


	public HRESULT CreateSurface(uint32 width, uint32 height, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionSurface** surface) mut => VT.[Friend]CreateSurface(&this, width, height, pixelFormat, alphaMode, surface);

	public HRESULT CreateVirtualSurface(uint32 initialWidth, uint32 initialHeight, DXGI_FORMAT pixelFormat, DXGI_ALPHA_MODE alphaMode, IDCompositionVirtualSurface** virtualSurface) mut => VT.[Friend]CreateVirtualSurface(&this, initialWidth, initialHeight, pixelFormat, alphaMode, virtualSurface);
}

[CRepr]struct IDCompositionVisual2 : IDCompositionVisual
{
	public new const Guid IID = .(0xe8de1639, 0x4331, 0x4b26, 0xbc, 0x5f, 0x6a, 0x32, 0x1d, 0x34, 0x7a, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionVisual.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_OPACITY_MODE mode) SetOpacityMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_BACKFACE_VISIBILITY visibility) SetBackFaceVisibility;
	}


	public HRESULT SetOpacityMode(DCOMPOSITION_OPACITY_MODE mode) mut => VT.[Friend]SetOpacityMode(&this, mode);

	public HRESULT SetBackFaceVisibility(DCOMPOSITION_BACKFACE_VISIBILITY visibility) mut => VT.[Friend]SetBackFaceVisibility(&this, visibility);
}

[CRepr]struct IDCompositionVisualDebug : IDCompositionVisual2
{
	public new const Guid IID = .(0xfed2b808, 0x5eb4, 0x43a0, 0xae, 0xa3, 0x35, 0xf6, 0x52, 0x80, 0xf9, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionVisual2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_COLOR_F* color) EnableHeatMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableHeatMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableRedrawRegions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableRedrawRegions;
	}


	public HRESULT EnableHeatMap(D2D1_COLOR_F* color) mut => VT.[Friend]EnableHeatMap(&this, color);

	public HRESULT DisableHeatMap() mut => VT.[Friend]DisableHeatMap(&this);

	public HRESULT EnableRedrawRegions() mut => VT.[Friend]EnableRedrawRegions(&this);

	public HRESULT DisableRedrawRegions() mut => VT.[Friend]DisableRedrawRegions(&this);
}

[CRepr]struct IDCompositionVisual3 : IDCompositionVisualDebug
{
	public new const Guid IID = .(0x2775f462, 0xb6c1, 0x4015, 0xb0, 0xbe, 0xb3, 0xe7, 0xd6, 0xa4, 0x97, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionVisualDebug.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCOMPOSITION_DEPTH_MODE mode) SetDepthMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOffsetZ;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offsetZ) SetOffsetZ0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetOpacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float opacity) SetOpacity0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTransform3D* transform) SetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_MATRIX_4X4_F* matrix) SetTransform0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL visible) SetVisible;
	}


	public HRESULT SetDepthMode(DCOMPOSITION_DEPTH_MODE mode) mut => VT.[Friend]SetDepthMode(&this, mode);

	public HRESULT SetOffsetZ(IDCompositionAnimation* animation) mut => VT.[Friend]SetOffsetZ(&this, animation);

	public HRESULT SetOffsetZ(float offsetZ) mut => VT.[Friend]SetOffsetZ0(&this, offsetZ);

	public HRESULT SetOpacity(IDCompositionAnimation* animation) mut => VT.[Friend]SetOpacity(&this, animation);

	public HRESULT SetOpacity(float opacity) mut => VT.[Friend]SetOpacity0(&this, opacity);

	public HRESULT SetTransform(IDCompositionTransform3D* transform) mut => VT.[Friend]SetTransform(&this, transform);

	public HRESULT SetTransform(D2D_MATRIX_4X4_F* matrix) mut => VT.[Friend]SetTransform0(&this, matrix);

	public HRESULT SetVisible(BOOL visible) mut => VT.[Friend]SetVisible(&this, visible);
}

[CRepr]struct IDCompositionDevice3 : IDCompositionDevice2
{
	public new const Guid IID = .(0x0987cb06, 0xf916, 0x48bf, 0x8d, 0x35, 0xce, 0x76, 0x41, 0x78, 0x1b, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionDevice2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionGaussianBlurEffect** gaussianBlurEffect) CreateGaussianBlurEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionBrightnessEffect** brightnessEffect) CreateBrightnessEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionColorMatrixEffect** colorMatrixEffect) CreateColorMatrixEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionShadowEffect** shadowEffect) CreateShadowEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionHueRotationEffect** hueRotationEffect) CreateHueRotationEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionSaturationEffect** saturationEffect) CreateSaturationEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTurbulenceEffect** turbulenceEffect) CreateTurbulenceEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionLinearTransferEffect** linearTransferEffect) CreateLinearTransferEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionTableTransferEffect** tableTransferEffect) CreateTableTransferEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionCompositeEffect** compositeEffect) CreateCompositeEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionBlendEffect** blendEffect) CreateBlendEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionArithmeticCompositeEffect** arithmeticCompositeEffect) CreateArithmeticCompositeEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAffineTransform2DEffect** affineTransform2dEffect) CreateAffineTransform2DEffect;
	}


	public HRESULT CreateGaussianBlurEffect(IDCompositionGaussianBlurEffect** gaussianBlurEffect) mut => VT.[Friend]CreateGaussianBlurEffect(&this, gaussianBlurEffect);

	public HRESULT CreateBrightnessEffect(IDCompositionBrightnessEffect** brightnessEffect) mut => VT.[Friend]CreateBrightnessEffect(&this, brightnessEffect);

	public HRESULT CreateColorMatrixEffect(IDCompositionColorMatrixEffect** colorMatrixEffect) mut => VT.[Friend]CreateColorMatrixEffect(&this, colorMatrixEffect);

	public HRESULT CreateShadowEffect(IDCompositionShadowEffect** shadowEffect) mut => VT.[Friend]CreateShadowEffect(&this, shadowEffect);

	public HRESULT CreateHueRotationEffect(IDCompositionHueRotationEffect** hueRotationEffect) mut => VT.[Friend]CreateHueRotationEffect(&this, hueRotationEffect);

	public HRESULT CreateSaturationEffect(IDCompositionSaturationEffect** saturationEffect) mut => VT.[Friend]CreateSaturationEffect(&this, saturationEffect);

	public HRESULT CreateTurbulenceEffect(IDCompositionTurbulenceEffect** turbulenceEffect) mut => VT.[Friend]CreateTurbulenceEffect(&this, turbulenceEffect);

	public HRESULT CreateLinearTransferEffect(IDCompositionLinearTransferEffect** linearTransferEffect) mut => VT.[Friend]CreateLinearTransferEffect(&this, linearTransferEffect);

	public HRESULT CreateTableTransferEffect(IDCompositionTableTransferEffect** tableTransferEffect) mut => VT.[Friend]CreateTableTransferEffect(&this, tableTransferEffect);

	public HRESULT CreateCompositeEffect(IDCompositionCompositeEffect** compositeEffect) mut => VT.[Friend]CreateCompositeEffect(&this, compositeEffect);

	public HRESULT CreateBlendEffect(IDCompositionBlendEffect** blendEffect) mut => VT.[Friend]CreateBlendEffect(&this, blendEffect);

	public HRESULT CreateArithmeticCompositeEffect(IDCompositionArithmeticCompositeEffect** arithmeticCompositeEffect) mut => VT.[Friend]CreateArithmeticCompositeEffect(&this, arithmeticCompositeEffect);

	public HRESULT CreateAffineTransform2DEffect(IDCompositionAffineTransform2DEffect** affineTransform2dEffect) mut => VT.[Friend]CreateAffineTransform2DEffect(&this, affineTransform2dEffect);
}

[CRepr]struct IDCompositionFilterEffect : IDCompositionEffect
{
	public new const Guid IID = .(0x30c421d5, 0x8cb2, 0x4e9f, 0xb1, 0x33, 0x37, 0xbe, 0x27, 0x0d, 0x4a, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IUnknown* input, uint32 flags) SetInput;
	}


	public HRESULT SetInput(uint32 index, IUnknown* input, uint32 flags) mut => VT.[Friend]SetInput(&this, index, input, flags);
}

[CRepr]struct IDCompositionGaussianBlurEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x45d4d0b7, 0x1bd4, 0x454e, 0x88, 0x94, 0x2b, 0xfa, 0x68, 0x44, 0x30, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetStandardDeviation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amount) SetStandardDeviation0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_BORDER_MODE mode) SetBorderMode;
	}


	public HRESULT SetStandardDeviation(IDCompositionAnimation* animation) mut => VT.[Friend]SetStandardDeviation(&this, animation);

	public HRESULT SetStandardDeviation(float amount) mut => VT.[Friend]SetStandardDeviation0(&this, amount);

	public HRESULT SetBorderMode(D2D1_BORDER_MODE mode) mut => VT.[Friend]SetBorderMode(&this, mode);
}

[CRepr]struct IDCompositionBrightnessEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x6027496e, 0xcb3a, 0x49ab, 0x93, 0x4f, 0xd7, 0x98, 0xda, 0x4f, 0x7d, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_2F* whitePoint) SetWhitePoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_2F* blackPoint) SetBlackPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetWhitePointX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float whitePointX) SetWhitePointX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetWhitePointY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float whitePointY) SetWhitePointY0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBlackPointX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float blackPointX) SetBlackPointX0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBlackPointY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float blackPointY) SetBlackPointY0;
	}


	public HRESULT SetWhitePoint(D2D_VECTOR_2F* whitePoint) mut => VT.[Friend]SetWhitePoint(&this, whitePoint);

	public HRESULT SetBlackPoint(D2D_VECTOR_2F* blackPoint) mut => VT.[Friend]SetBlackPoint(&this, blackPoint);

	public HRESULT SetWhitePointX(IDCompositionAnimation* animation) mut => VT.[Friend]SetWhitePointX(&this, animation);

	public HRESULT SetWhitePointX(float whitePointX) mut => VT.[Friend]SetWhitePointX0(&this, whitePointX);

	public HRESULT SetWhitePointY(IDCompositionAnimation* animation) mut => VT.[Friend]SetWhitePointY(&this, animation);

	public HRESULT SetWhitePointY(float whitePointY) mut => VT.[Friend]SetWhitePointY0(&this, whitePointY);

	public HRESULT SetBlackPointX(IDCompositionAnimation* animation) mut => VT.[Friend]SetBlackPointX(&this, animation);

	public HRESULT SetBlackPointX(float blackPointX) mut => VT.[Friend]SetBlackPointX0(&this, blackPointX);

	public HRESULT SetBlackPointY(IDCompositionAnimation* animation) mut => VT.[Friend]SetBlackPointY(&this, animation);

	public HRESULT SetBlackPointY(float blackPointY) mut => VT.[Friend]SetBlackPointY0(&this, blackPointY);
}

[CRepr]struct IDCompositionColorMatrixEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0xc1170a22, 0x3ce2, 0x4966, 0x90, 0xd4, 0x55, 0x40, 0x8b, 0xfc, 0x84, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_MATRIX_5X4_F* matrix) SetMatrix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, IDCompositionAnimation* animation) SetMatrixElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, float value) SetMatrixElement0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_COLORMATRIX_ALPHA_MODE mode) SetAlphaMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL clamp) SetClampOutput;
	}


	public HRESULT SetMatrix(D2D_MATRIX_5X4_F* matrix) mut => VT.[Friend]SetMatrix(&this, matrix);

	public HRESULT SetMatrixElement(int32 row, int32 column, IDCompositionAnimation* animation) mut => VT.[Friend]SetMatrixElement(&this, row, column, animation);

	public HRESULT SetMatrixElement(int32 row, int32 column, float value) mut => VT.[Friend]SetMatrixElement0(&this, row, column, value);

	public HRESULT SetAlphaMode(D2D1_COLORMATRIX_ALPHA_MODE mode) mut => VT.[Friend]SetAlphaMode(&this, mode);

	public HRESULT SetClampOutput(BOOL clamp) mut => VT.[Friend]SetClampOutput(&this, clamp);
}

[CRepr]struct IDCompositionShadowEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x4ad18ac0, 0xcfd2, 0x4c2f, 0xbb, 0x62, 0x96, 0xe5, 0x4f, 0xdb, 0x68, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetStandardDeviation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amount) SetStandardDeviation0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_4F* color) SetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetRed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amount) SetRed0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetGreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amount) SetGreen0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBlue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amount) SetBlue0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAlpha;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amount) SetAlpha0;
	}


	public HRESULT SetStandardDeviation(IDCompositionAnimation* animation) mut => VT.[Friend]SetStandardDeviation(&this, animation);

	public HRESULT SetStandardDeviation(float amount) mut => VT.[Friend]SetStandardDeviation0(&this, amount);

	public HRESULT SetColor(D2D_VECTOR_4F* color) mut => VT.[Friend]SetColor(&this, color);

	public HRESULT SetRed(IDCompositionAnimation* animation) mut => VT.[Friend]SetRed(&this, animation);

	public HRESULT SetRed(float amount) mut => VT.[Friend]SetRed0(&this, amount);

	public HRESULT SetGreen(IDCompositionAnimation* animation) mut => VT.[Friend]SetGreen(&this, animation);

	public HRESULT SetGreen(float amount) mut => VT.[Friend]SetGreen0(&this, amount);

	public HRESULT SetBlue(IDCompositionAnimation* animation) mut => VT.[Friend]SetBlue(&this, animation);

	public HRESULT SetBlue(float amount) mut => VT.[Friend]SetBlue0(&this, amount);

	public HRESULT SetAlpha(IDCompositionAnimation* animation) mut => VT.[Friend]SetAlpha(&this, animation);

	public HRESULT SetAlpha(float amount) mut => VT.[Friend]SetAlpha0(&this, amount);
}

[CRepr]struct IDCompositionHueRotationEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x6db9f920, 0x0770, 0x4781, 0xb0, 0xc6, 0x38, 0x19, 0x12, 0xf9, 0xd1, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAngle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float amountDegrees) SetAngle0;
	}


	public HRESULT SetAngle(IDCompositionAnimation* animation) mut => VT.[Friend]SetAngle(&this, animation);

	public HRESULT SetAngle(float amountDegrees) mut => VT.[Friend]SetAngle0(&this, amountDegrees);
}

[CRepr]struct IDCompositionSaturationEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0xa08debda, 0x3258, 0x4fa4, 0x9f, 0x16, 0x91, 0x74, 0xd3, 0xfe, 0x93, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetSaturation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float ratio) SetSaturation0;
	}


	public HRESULT SetSaturation(IDCompositionAnimation* animation) mut => VT.[Friend]SetSaturation(&this, animation);

	public HRESULT SetSaturation(float ratio) mut => VT.[Friend]SetSaturation0(&this, ratio);
}

[CRepr]struct IDCompositionTurbulenceEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0xa6a55bda, 0xc09c, 0x49f3, 0x91, 0x93, 0xa4, 0x19, 0x22, 0xc8, 0x97, 0x15);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_2F* offset) SetOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_2F* frequency) SetBaseFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_2F* size) SetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 numOctaves) SetNumOctaves;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 seed) SetSeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_TURBULENCE_NOISE noise) SetNoise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL stitchable) SetStitchable;
	}


	public HRESULT SetOffset(D2D_VECTOR_2F* offset) mut => VT.[Friend]SetOffset(&this, offset);

	public HRESULT SetBaseFrequency(D2D_VECTOR_2F* frequency) mut => VT.[Friend]SetBaseFrequency(&this, frequency);

	public HRESULT SetSize(D2D_VECTOR_2F* size) mut => VT.[Friend]SetSize(&this, size);

	public HRESULT SetNumOctaves(uint32 numOctaves) mut => VT.[Friend]SetNumOctaves(&this, numOctaves);

	public HRESULT SetSeed(uint32 seed) mut => VT.[Friend]SetSeed(&this, seed);

	public HRESULT SetNoise(D2D1_TURBULENCE_NOISE noise) mut => VT.[Friend]SetNoise(&this, noise);

	public HRESULT SetStitchable(BOOL stitchable) mut => VT.[Friend]SetStitchable(&this, stitchable);
}

[CRepr]struct IDCompositionLinearTransferEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x4305ee5b, 0xc4a0, 0x4c88, 0x93, 0x85, 0x67, 0x12, 0x4e, 0x01, 0x76, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetRedYIntercept;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float redYIntercept) SetRedYIntercept0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetRedSlope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float redSlope) SetRedSlope0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL redDisable) SetRedDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetGreenYIntercept;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float greenYIntercept) SetGreenYIntercept0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetGreenSlope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float greenSlope) SetGreenSlope0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL greenDisable) SetGreenDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBlueYIntercept;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float blueYIntercept) SetBlueYIntercept0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetBlueSlope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float blueSlope) SetBlueSlope0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL blueDisable) SetBlueDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAlphaYIntercept;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float alphaYIntercept) SetAlphaYIntercept0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetAlphaSlope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float alphaSlope) SetAlphaSlope0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL alphaDisable) SetAlphaDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL clampOutput) SetClampOutput;
	}


	public HRESULT SetRedYIntercept(IDCompositionAnimation* animation) mut => VT.[Friend]SetRedYIntercept(&this, animation);

	public HRESULT SetRedYIntercept(float redYIntercept) mut => VT.[Friend]SetRedYIntercept0(&this, redYIntercept);

	public HRESULT SetRedSlope(IDCompositionAnimation* animation) mut => VT.[Friend]SetRedSlope(&this, animation);

	public HRESULT SetRedSlope(float redSlope) mut => VT.[Friend]SetRedSlope0(&this, redSlope);

	public HRESULT SetRedDisable(BOOL redDisable) mut => VT.[Friend]SetRedDisable(&this, redDisable);

	public HRESULT SetGreenYIntercept(IDCompositionAnimation* animation) mut => VT.[Friend]SetGreenYIntercept(&this, animation);

	public HRESULT SetGreenYIntercept(float greenYIntercept) mut => VT.[Friend]SetGreenYIntercept0(&this, greenYIntercept);

	public HRESULT SetGreenSlope(IDCompositionAnimation* animation) mut => VT.[Friend]SetGreenSlope(&this, animation);

	public HRESULT SetGreenSlope(float greenSlope) mut => VT.[Friend]SetGreenSlope0(&this, greenSlope);

	public HRESULT SetGreenDisable(BOOL greenDisable) mut => VT.[Friend]SetGreenDisable(&this, greenDisable);

	public HRESULT SetBlueYIntercept(IDCompositionAnimation* animation) mut => VT.[Friend]SetBlueYIntercept(&this, animation);

	public HRESULT SetBlueYIntercept(float blueYIntercept) mut => VT.[Friend]SetBlueYIntercept0(&this, blueYIntercept);

	public HRESULT SetBlueSlope(IDCompositionAnimation* animation) mut => VT.[Friend]SetBlueSlope(&this, animation);

	public HRESULT SetBlueSlope(float blueSlope) mut => VT.[Friend]SetBlueSlope0(&this, blueSlope);

	public HRESULT SetBlueDisable(BOOL blueDisable) mut => VT.[Friend]SetBlueDisable(&this, blueDisable);

	public HRESULT SetAlphaYIntercept(IDCompositionAnimation* animation) mut => VT.[Friend]SetAlphaYIntercept(&this, animation);

	public HRESULT SetAlphaYIntercept(float alphaYIntercept) mut => VT.[Friend]SetAlphaYIntercept0(&this, alphaYIntercept);

	public HRESULT SetAlphaSlope(IDCompositionAnimation* animation) mut => VT.[Friend]SetAlphaSlope(&this, animation);

	public HRESULT SetAlphaSlope(float alphaSlope) mut => VT.[Friend]SetAlphaSlope0(&this, alphaSlope);

	public HRESULT SetAlphaDisable(BOOL alphaDisable) mut => VT.[Friend]SetAlphaDisable(&this, alphaDisable);

	public HRESULT SetClampOutput(BOOL clampOutput) mut => VT.[Friend]SetClampOutput(&this, clampOutput);
}

[CRepr]struct IDCompositionTableTransferEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x9b7e82e2, 0x69c5, 0x4eb4, 0xa5, 0xf5, 0xa7, 0x03, 0x3f, 0x51, 0x32, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* tableValues, uint32 count) SetRedTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* tableValues, uint32 count) SetGreenTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* tableValues, uint32 count) SetBlueTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* tableValues, uint32 count) SetAlphaTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL redDisable) SetRedDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL greenDisable) SetGreenDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL blueDisable) SetBlueDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL alphaDisable) SetAlphaDisable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL clampOutput) SetClampOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IDCompositionAnimation* animation) SetRedTableValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, float value) SetRedTableValue0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IDCompositionAnimation* animation) SetGreenTableValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, float value) SetGreenTableValue0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IDCompositionAnimation* animation) SetBlueTableValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, float value) SetBlueTableValue0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IDCompositionAnimation* animation) SetAlphaTableValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, float value) SetAlphaTableValue0;
	}


	public HRESULT SetRedTable(float* tableValues, uint32 count) mut => VT.[Friend]SetRedTable(&this, tableValues, count);

	public HRESULT SetGreenTable(float* tableValues, uint32 count) mut => VT.[Friend]SetGreenTable(&this, tableValues, count);

	public HRESULT SetBlueTable(float* tableValues, uint32 count) mut => VT.[Friend]SetBlueTable(&this, tableValues, count);

	public HRESULT SetAlphaTable(float* tableValues, uint32 count) mut => VT.[Friend]SetAlphaTable(&this, tableValues, count);

	public HRESULT SetRedDisable(BOOL redDisable) mut => VT.[Friend]SetRedDisable(&this, redDisable);

	public HRESULT SetGreenDisable(BOOL greenDisable) mut => VT.[Friend]SetGreenDisable(&this, greenDisable);

	public HRESULT SetBlueDisable(BOOL blueDisable) mut => VT.[Friend]SetBlueDisable(&this, blueDisable);

	public HRESULT SetAlphaDisable(BOOL alphaDisable) mut => VT.[Friend]SetAlphaDisable(&this, alphaDisable);

	public HRESULT SetClampOutput(BOOL clampOutput) mut => VT.[Friend]SetClampOutput(&this, clampOutput);

	public HRESULT SetRedTableValue(uint32 index, IDCompositionAnimation* animation) mut => VT.[Friend]SetRedTableValue(&this, index, animation);

	public HRESULT SetRedTableValue(uint32 index, float value) mut => VT.[Friend]SetRedTableValue0(&this, index, value);

	public HRESULT SetGreenTableValue(uint32 index, IDCompositionAnimation* animation) mut => VT.[Friend]SetGreenTableValue(&this, index, animation);

	public HRESULT SetGreenTableValue(uint32 index, float value) mut => VT.[Friend]SetGreenTableValue0(&this, index, value);

	public HRESULT SetBlueTableValue(uint32 index, IDCompositionAnimation* animation) mut => VT.[Friend]SetBlueTableValue(&this, index, animation);

	public HRESULT SetBlueTableValue(uint32 index, float value) mut => VT.[Friend]SetBlueTableValue0(&this, index, value);

	public HRESULT SetAlphaTableValue(uint32 index, IDCompositionAnimation* animation) mut => VT.[Friend]SetAlphaTableValue(&this, index, animation);

	public HRESULT SetAlphaTableValue(uint32 index, float value) mut => VT.[Friend]SetAlphaTableValue0(&this, index, value);
}

[CRepr]struct IDCompositionCompositeEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x576616c0, 0xa231, 0x494d, 0xa3, 0x8d, 0x00, 0xfd, 0x5e, 0xc4, 0xdb, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_COMPOSITE_MODE mode) SetMode;
	}


	public HRESULT SetMode(D2D1_COMPOSITE_MODE mode) mut => VT.[Friend]SetMode(&this, mode);
}

[CRepr]struct IDCompositionBlendEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x33ecdc0a, 0x578a, 0x4a11, 0x9c, 0x14, 0x0c, 0xb9, 0x05, 0x17, 0xf9, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_BLEND_MODE mode) SetMode;
	}


	public HRESULT SetMode(D2D1_BLEND_MODE mode) mut => VT.[Friend]SetMode(&this, mode);
}

[CRepr]struct IDCompositionArithmeticCompositeEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x3b67dfa8, 0xe3dd, 0x4e61, 0xb6, 0x40, 0x46, 0xc2, 0xf3, 0xd7, 0x39, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_VECTOR_4F* coefficients) SetCoefficients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL clampoutput) SetClampOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCoefficient1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Coeffcient1) SetCoefficient10;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCoefficient2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Coefficient2) SetCoefficient20;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCoefficient3;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Coefficient3) SetCoefficient30;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetCoefficient4;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float Coefficient4) SetCoefficient40;
	}


	public HRESULT SetCoefficients(D2D_VECTOR_4F* coefficients) mut => VT.[Friend]SetCoefficients(&this, coefficients);

	public HRESULT SetClampOutput(BOOL clampoutput) mut => VT.[Friend]SetClampOutput(&this, clampoutput);

	public HRESULT SetCoefficient1(IDCompositionAnimation* animation) mut => VT.[Friend]SetCoefficient1(&this, animation);

	public HRESULT SetCoefficient1(float Coeffcient1) mut => VT.[Friend]SetCoefficient10(&this, Coeffcient1);

	public HRESULT SetCoefficient2(IDCompositionAnimation* animation) mut => VT.[Friend]SetCoefficient2(&this, animation);

	public HRESULT SetCoefficient2(float Coefficient2) mut => VT.[Friend]SetCoefficient20(&this, Coefficient2);

	public HRESULT SetCoefficient3(IDCompositionAnimation* animation) mut => VT.[Friend]SetCoefficient3(&this, animation);

	public HRESULT SetCoefficient3(float Coefficient3) mut => VT.[Friend]SetCoefficient30(&this, Coefficient3);

	public HRESULT SetCoefficient4(IDCompositionAnimation* animation) mut => VT.[Friend]SetCoefficient4(&this, animation);

	public HRESULT SetCoefficient4(float Coefficient4) mut => VT.[Friend]SetCoefficient40(&this, Coefficient4);
}

[CRepr]struct IDCompositionAffineTransform2DEffect : IDCompositionFilterEffect
{
	public new const Guid IID = .(0x0b74b9e8, 0xcdd6, 0x492f, 0xbb, 0xbc, 0x5e, 0xd3, 0x21, 0x57, 0x02, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDCompositionFilterEffect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Win32.Graphics.Direct2D.Common.D2D1_2DAFFINETRANSFORM_INTERPOLATION_MODE interpolationMode) SetInterpolationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_BORDER_MODE borderMode) SetBorderMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D_MATRIX_3X2_F* transformMatrix) SetTransformMatrix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, IDCompositionAnimation* animation) SetTransformMatrixElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 row, int32 column, float value) SetTransformMatrixElement0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) SetSharpness;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float sharpness) SetSharpness0;
	}


	public HRESULT SetInterpolationMode(Win32.Graphics.Direct2D.Common.D2D1_2DAFFINETRANSFORM_INTERPOLATION_MODE interpolationMode) mut => VT.[Friend]SetInterpolationMode(&this, interpolationMode);

	public HRESULT SetBorderMode(D2D1_BORDER_MODE borderMode) mut => VT.[Friend]SetBorderMode(&this, borderMode);

	public HRESULT SetTransformMatrix(D2D_MATRIX_3X2_F* transformMatrix) mut => VT.[Friend]SetTransformMatrix(&this, transformMatrix);

	public HRESULT SetTransformMatrixElement(int32 row, int32 column, IDCompositionAnimation* animation) mut => VT.[Friend]SetTransformMatrixElement(&this, row, column, animation);

	public HRESULT SetTransformMatrixElement(int32 row, int32 column, float value) mut => VT.[Friend]SetTransformMatrixElement0(&this, row, column, value);

	public HRESULT SetSharpness(IDCompositionAnimation* animation) mut => VT.[Friend]SetSharpness(&this, animation);

	public HRESULT SetSharpness(float sharpness) mut => VT.[Friend]SetSharpness0(&this, sharpness);
}

[CRepr]struct IDCompositionDelegatedInkTrail : IUnknown
{
	public new const Guid IID = .(0xc2448e9b, 0x547d, 0x4057, 0x8c, 0xf5, 0x81, 0x44, 0xed, 0xe1, 0xc2, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCompositionInkTrailPoint* inkPoints, uint32 inkPointsCount, uint32* generationId) AddTrailPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DCompositionInkTrailPoint* inkPoints, uint32 inkPointsCount, DCompositionInkTrailPoint* predictedInkPoints, uint32 predictedInkPointsCount, uint32* generationId) AddTrailPointsWithPrediction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 generationId) RemoveTrailPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, D2D1_COLOR_F* color) StartNewTrail;
	}


	public HRESULT AddTrailPoints(DCompositionInkTrailPoint* inkPoints, uint32 inkPointsCount, uint32* generationId) mut => VT.[Friend]AddTrailPoints(&this, inkPoints, inkPointsCount, generationId);

	public HRESULT AddTrailPointsWithPrediction(DCompositionInkTrailPoint* inkPoints, uint32 inkPointsCount, DCompositionInkTrailPoint* predictedInkPoints, uint32 predictedInkPointsCount, uint32* generationId) mut => VT.[Friend]AddTrailPointsWithPrediction(&this, inkPoints, inkPointsCount, predictedInkPoints, predictedInkPointsCount, generationId);

	public HRESULT RemoveTrailPoints(uint32 generationId) mut => VT.[Friend]RemoveTrailPoints(&this, generationId);

	public HRESULT StartNewTrail(D2D1_COLOR_F* color) mut => VT.[Friend]StartNewTrail(&this, color);
}

[CRepr]struct IDCompositionInkTrailDevice : IUnknown
{
	public new const Guid IID = .(0xdf0c7cec, 0xcdeb, 0x4d4a, 0xb9, 0x1c, 0x72, 0x1b, 0xf2, 0x2f, 0x4e, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionDelegatedInkTrail** inkTrail) CreateDelegatedInkTrail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* swapChain, IDCompositionDelegatedInkTrail** inkTrail) CreateDelegatedInkTrailForSwapChain;
	}


	public HRESULT CreateDelegatedInkTrail(IDCompositionDelegatedInkTrail** inkTrail) mut => VT.[Friend]CreateDelegatedInkTrail(&this, inkTrail);

	public HRESULT CreateDelegatedInkTrailForSwapChain(IUnknown* swapChain, IDCompositionDelegatedInkTrail** inkTrail) mut => VT.[Friend]CreateDelegatedInkTrailForSwapChain(&this, swapChain, inkTrail);
}

#endregion

#region Functions
public static
{
	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionCreateDevice(IDXGIDevice* dxgiDevice, in Guid iid, void** dcompositionDevice);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionCreateDevice2(IUnknown* renderingDevice, in Guid iid, void** dcompositionDevice);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionCreateDevice3(IUnknown* renderingDevice, in Guid iid, void** dcompositionDevice);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionCreateSurfaceHandle(uint32 desiredAccess, SECURITY_ATTRIBUTES* securityAttributes, HANDLE* surfaceHandle);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionAttachMouseWheelToHwnd(IDCompositionVisual* visual, HWND hwnd, BOOL enable);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionAttachMouseDragToHwnd(IDCompositionVisual* visual, HWND hwnd, BOOL enable);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionGetFrameId(COMPOSITION_FRAME_ID_TYPE frameIdType, uint64* frameId);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionGetStatistics(uint64 frameId, COMPOSITION_FRAME_STATS* frameStats, uint32 targetIdCount, COMPOSITION_TARGET_ID* targetIds, uint32* actualTargetIdCount);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionGetTargetStatistics(uint64 frameId, COMPOSITION_TARGET_ID* targetId, COMPOSITION_TARGET_STATS* targetStats);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DCompositionBoostCompositorClock(BOOL enable);

	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DCompositionWaitForCompositorClock(uint32 count, HANDLE* handles, uint32 timeoutInMs);

}
#endregion
