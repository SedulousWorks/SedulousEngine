using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Dxgi.Common;
using System;

namespace Win32.Graphics.CompositionSwapchain;

#region Enums

[AllowDuplicates]
public enum PresentStatisticsKind : int32
{
	PresentStatisticsKind_PresentStatus = 1,
	PresentStatisticsKind_CompositionFrame = 2,
	PresentStatisticsKind_IndependentFlipFrame = 3,
}


[AllowDuplicates]
public enum PresentStatus : int32
{
	PresentStatus_Queued = 0,
	PresentStatus_Skipped = 1,
	PresentStatus_Canceled = 2,
}


[AllowDuplicates]
public enum CompositionFrameInstanceKind : int32
{
	CompositionFrameInstanceKind_ComposedOnScreen = 0,
	CompositionFrameInstanceKind_ScanoutOnScreen = 1,
	CompositionFrameInstanceKind_ComposedToIntermediate = 2,
}

#endregion


#region Structs
[CRepr]
public struct SystemInterruptTime
{
	public uint64 value;
}

[CRepr]
public struct PresentationTransform
{
	public float M11;
	public float M12;
	public float M21;
	public float M22;
	public float M31;
	public float M32;
}

[CRepr]
public struct CompositionFrameDisplayInstance
{
	public LUID displayAdapterLUID;
	public uint32 displayVidPnSourceId;
	public uint32 displayUniqueId;
	public LUID renderAdapterLUID;
	public CompositionFrameInstanceKind instanceKind;
	public PresentationTransform finalTransform;
	public uint8 requiredCrossAdapterCopy;
	public DXGI_COLOR_SPACE_TYPE colorSpace;
}

#endregion

#region COM Types
[CRepr]struct IPresentationBuffer : IUnknown
{
	public new const Guid IID = .(0x2e217d3a, 0x5abb, 0x4138, 0x9a, 0x13, 0xa7, 0x75, 0x59, 0x3c, 0x89, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* availableEventHandle) GetAvailableEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* isAvailable) IsAvailable;
	}


	public HRESULT GetAvailableEvent(HANDLE* availableEventHandle) mut => VT.[Friend]GetAvailableEvent(&this, availableEventHandle);

	public HRESULT IsAvailable(uint8* isAvailable) mut => VT.[Friend]IsAvailable(&this, isAvailable);
}

[CRepr]struct IPresentationContent : IUnknown
{
	public new const Guid IID = .(0x5668bb79, 0x3d8e, 0x415c, 0xb2, 0x15, 0xf3, 0x80, 0x20, 0xf2, 0xd2, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint tag) SetTag;
	}


	public void SetTag(uint tag) mut => VT.[Friend]SetTag(&this, tag);
}

[CRepr]struct IPresentationSurface : IPresentationContent
{
	public new const Guid IID = .(0x956710fb, 0xea40, 0x4eba, 0xa3, 0xeb, 0x43, 0x75, 0xa0, 0xeb, 0x4e, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPresentationContent.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPresentationBuffer* presentationBuffer) SetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_COLOR_SPACE_TYPE colorSpace) SetColorSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_ALPHA_MODE alphaMode) SetAlphaMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* sourceRect) SetSourceRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PresentationTransform* transform) SetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* output) RestrictToOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 value) SetDisableReadback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float leftLetterboxSize, float topLetterboxSize, float rightLetterboxSize, float bottomLetterboxSize) SetLetterboxingMargins;
	}


	public HRESULT SetBuffer(IPresentationBuffer* presentationBuffer) mut => VT.[Friend]SetBuffer(&this, presentationBuffer);

	public HRESULT SetColorSpace(DXGI_COLOR_SPACE_TYPE colorSpace) mut => VT.[Friend]SetColorSpace(&this, colorSpace);

	public HRESULT SetAlphaMode(DXGI_ALPHA_MODE alphaMode) mut => VT.[Friend]SetAlphaMode(&this, alphaMode);

	public HRESULT SetSourceRect(RECT* sourceRect) mut => VT.[Friend]SetSourceRect(&this, sourceRect);

	public HRESULT SetTransform(PresentationTransform* transform) mut => VT.[Friend]SetTransform(&this, transform);

	public HRESULT RestrictToOutput(IUnknown* output) mut => VT.[Friend]RestrictToOutput(&this, output);

	public HRESULT SetDisableReadback(uint8 value) mut => VT.[Friend]SetDisableReadback(&this, value);

	public HRESULT SetLetterboxingMargins(float leftLetterboxSize, float topLetterboxSize, float rightLetterboxSize, float bottomLetterboxSize) mut => VT.[Friend]SetLetterboxingMargins(&this, leftLetterboxSize, topLetterboxSize, rightLetterboxSize, bottomLetterboxSize);
}

[CRepr]struct IPresentStatistics : IUnknown
{
	public new const Guid IID = .(0xb44b8bda, 0x7282, 0x495d, 0x9d, 0xd7, 0xce, 0xad, 0xd8, 0xb4, 0xbb, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self) GetPresentId;
		protected new function [CallingConvention(.Stdcall)] PresentStatisticsKind(SelfOuter* self) GetKind;
	}


	public uint64 GetPresentId() mut => VT.[Friend]GetPresentId(&this);

	public PresentStatisticsKind GetKind() mut => VT.[Friend]GetKind(&this);
}

[CRepr]struct IPresentationManager : IUnknown
{
	public new const Guid IID = .(0xfb562f82, 0x6292, 0x470a, 0x88, 0xb1, 0x84, 0x36, 0x61, 0xe7, 0xf2, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* resource, IPresentationBuffer** presentationBuffer) AddBufferFromResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE compositionSurfaceHandle, IPresentationSurface** presentationSurface) CreatePresentationSurface;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self) GetNextPresentId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SystemInterruptTime targetTime) SetTargetTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SystemInterruptTime preferredDuration, SystemInterruptTime deviationTolerance) SetPreferredPresentDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 forceVsyncInterrupt) ForceVSyncInterrupt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Present;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** fence) GetPresentRetiringFence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 presentIdToCancelFrom) CancelPresentsFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* lostEventHandle) GetLostEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* presentStatisticsAvailableEventHandle) GetPresentStatisticsAvailableEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PresentStatisticsKind presentStatisticsKind, uint8 enabled) EnablePresentStatisticsKind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPresentStatistics** nextPresentStatistics) GetNextPresentStatistics;
	}


	public HRESULT AddBufferFromResource(IUnknown* resource, IPresentationBuffer** presentationBuffer) mut => VT.[Friend]AddBufferFromResource(&this, resource, presentationBuffer);

	public HRESULT CreatePresentationSurface(HANDLE compositionSurfaceHandle, IPresentationSurface** presentationSurface) mut => VT.[Friend]CreatePresentationSurface(&this, compositionSurfaceHandle, presentationSurface);

	public uint64 GetNextPresentId() mut => VT.[Friend]GetNextPresentId(&this);

	public HRESULT SetTargetTime(SystemInterruptTime targetTime) mut => VT.[Friend]SetTargetTime(&this, targetTime);

	public HRESULT SetPreferredPresentDuration(SystemInterruptTime preferredDuration, SystemInterruptTime deviationTolerance) mut => VT.[Friend]SetPreferredPresentDuration(&this, preferredDuration, deviationTolerance);

	public HRESULT ForceVSyncInterrupt(uint8 forceVsyncInterrupt) mut => VT.[Friend]ForceVSyncInterrupt(&this, forceVsyncInterrupt);

	public HRESULT Present() mut => VT.[Friend]Present(&this);

	public HRESULT GetPresentRetiringFence(in Guid riid, void** fence) mut => VT.[Friend]GetPresentRetiringFence(&this, riid, fence);

	public HRESULT CancelPresentsFrom(uint64 presentIdToCancelFrom) mut => VT.[Friend]CancelPresentsFrom(&this, presentIdToCancelFrom);

	public HRESULT GetLostEvent(HANDLE* lostEventHandle) mut => VT.[Friend]GetLostEvent(&this, lostEventHandle);

	public HRESULT GetPresentStatisticsAvailableEvent(HANDLE* presentStatisticsAvailableEventHandle) mut => VT.[Friend]GetPresentStatisticsAvailableEvent(&this, presentStatisticsAvailableEventHandle);

	public HRESULT EnablePresentStatisticsKind(PresentStatisticsKind presentStatisticsKind, uint8 enabled) mut => VT.[Friend]EnablePresentStatisticsKind(&this, presentStatisticsKind, enabled);

	public HRESULT GetNextPresentStatistics(IPresentStatistics** nextPresentStatistics) mut => VT.[Friend]GetNextPresentStatistics(&this, nextPresentStatistics);
}

[CRepr]struct IPresentationFactory : IUnknown
{
	public new const Guid IID = .(0x8fb37b58, 0x1d74, 0x4f64, 0xa4, 0x9c, 0x1f, 0x97, 0xa8, 0x0a, 0x2e, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint8(SelfOuter* self) IsPresentationSupported;
		protected new function [CallingConvention(.Stdcall)] uint8(SelfOuter* self) IsPresentationSupportedWithIndependentFlip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPresentationManager** ppPresentationManager) CreatePresentationManager;
	}


	public uint8 IsPresentationSupported() mut => VT.[Friend]IsPresentationSupported(&this);

	public uint8 IsPresentationSupportedWithIndependentFlip() mut => VT.[Friend]IsPresentationSupportedWithIndependentFlip(&this);

	public HRESULT CreatePresentationManager(IPresentationManager** ppPresentationManager) mut => VT.[Friend]CreatePresentationManager(&this, ppPresentationManager);
}

[CRepr]struct IPresentStatusPresentStatistics : IPresentStatistics
{
	public new const Guid IID = .(0xc9ed2a41, 0x79cb, 0x435e, 0x96, 0x4e, 0xc8, 0x55, 0x30, 0x55, 0x42, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPresentStatistics.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self) GetCompositionFrameId;
		protected new function [CallingConvention(.Stdcall)] PresentStatus(SelfOuter* self) GetPresentStatus;
	}


	public uint64 GetCompositionFrameId() mut => VT.[Friend]GetCompositionFrameId(&this);

	public PresentStatus GetPresentStatus() mut => VT.[Friend]GetPresentStatus(&this);
}

[CRepr]struct ICompositionFramePresentStatistics : IPresentStatistics
{
	public new const Guid IID = .(0xab41d127, 0xc101, 0x4c0a, 0x91, 0x1d, 0xf9, 0xf2, 0xe9, 0xd0, 0x8e, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPresentStatistics.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self) GetContentTag;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self) GetCompositionFrameId;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32* displayInstanceArrayCount, CompositionFrameDisplayInstance** displayInstanceArray) GetDisplayInstanceArray;
	}


	public uint GetContentTag() mut => VT.[Friend]GetContentTag(&this);

	public uint64 GetCompositionFrameId() mut => VT.[Friend]GetCompositionFrameId(&this);

	public void GetDisplayInstanceArray(uint32* displayInstanceArrayCount, CompositionFrameDisplayInstance** displayInstanceArray) mut => VT.[Friend]GetDisplayInstanceArray(&this, displayInstanceArrayCount, displayInstanceArray);
}

[CRepr]struct IIndependentFlipFramePresentStatistics : IPresentStatistics
{
	public new const Guid IID = .(0x8c93be27, 0xad94, 0x4da0, 0x8f, 0xd4, 0x24, 0x13, 0x13, 0x2d, 0x12, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPresentStatistics.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, out LUID @return) GetOutputAdapterLUID;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetOutputVidPnSourceId;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self) GetContentTag;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, out SystemInterruptTime @return) GetDisplayedTime;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, out SystemInterruptTime @return) GetPresentDuration;
	}


	public LUID GetOutputAdapterLUID() mut => VT.[Friend]GetOutputAdapterLUID(&this, ..?);

	public uint32 GetOutputVidPnSourceId() mut => VT.[Friend]GetOutputVidPnSourceId(&this);

	public uint GetContentTag() mut => VT.[Friend]GetContentTag(&this);

	public SystemInterruptTime GetDisplayedTime() mut => VT.[Friend]GetDisplayedTime(&this, ..?);

	public SystemInterruptTime GetPresentDuration() mut => VT.[Friend]GetPresentDuration(&this, ..?);
}

#endregion

#region Functions
public static
{
	[Import("dcomp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreatePresentationFactory(IUnknown* d3dDevice, in Guid riid, void** presentationFactory);

}
#endregion
