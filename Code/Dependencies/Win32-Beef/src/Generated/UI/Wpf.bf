using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Imaging;
using Win32.Graphics.Dwm;
using System;

namespace Win32.UI.Wpf;

#region Constants
public static
{
	public const uint32 MILBITMAPEFFECT_SDK_VERSION = 16777216;
	public const Guid CLSID_MILBitmapEffectGroup = .(0xac9c1a9a, 0x7e18, 0x4f64, 0xac, 0x7e, 0x47, 0xcf, 0x7f, 0x05, 0x1e, 0x95);
	public const Guid CLSID_MILBitmapEffectBlur = .(0xa924df87, 0x225d, 0x4373, 0x8f, 0x5b, 0xb9, 0x0e, 0xc8, 0x5a, 0xe3, 0xde);
	public const Guid CLSID_MILBitmapEffectDropShadow = .(0x459a3fbe, 0xd8ac, 0x4692, 0x87, 0x4b, 0x7a, 0x26, 0x57, 0x15, 0xaa, 0x16);
	public const Guid CLSID_MILBitmapEffectOuterGlow = .(0xe2161bdd, 0x7eb6, 0x4725, 0x9c, 0x0b, 0x8a, 0x2a, 0x1b, 0x4f, 0x06, 0x67);
	public const Guid CLSID_MILBitmapEffectBevel = .(0xfd361dbe, 0x6c9b, 0x4de0, 0x82, 0x90, 0xf6, 0x40, 0x0c, 0x27, 0x37, 0xed);
	public const Guid CLSID_MILBitmapEffectEmboss = .(0xcd299846, 0x824f, 0x47ec, 0xa0, 0x07, 0x12, 0xaa, 0x76, 0x7f, 0x28, 0x16);
}
#endregion

#region Structs
[CRepr]
public struct MilRectD
{
	public double left;
	public double top;
	public double right;
	public double bottom;
}

[CRepr]
public struct MilPoint2D
{
	public double X;
	public double Y;
}

[CRepr]
public struct MILMatrixF
{
	public double _11;
	public double _12;
	public double _13;
	public double _14;
	public double _21;
	public double _22;
	public double _23;
	public double _24;
	public double _31;
	public double _32;
	public double _33;
	public double _34;
	public double _41;
	public double _42;
	public double _43;
	public double _44;
}

#endregion

#region COM Types
[CRepr]struct IMILBitmapEffectConnectorInfo : IUnknown
{
	public new const Guid IID = .(0xf66d2e4b, 0xb46b, 0x42fc, 0x85, 0x9e, 0x3d, 0xa0, 0xec, 0xdb, 0x3c, 0x43);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiIndex) GetIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pFormat) GetOptimalFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulNumberFormats) GetNumberFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, Guid* pFormat) GetFormat;
	}


	public HRESULT GetIndex(uint32* puiIndex) mut => VT.[Friend]GetIndex(&this, puiIndex);

	public HRESULT GetOptimalFormat(Guid* pFormat) mut => VT.[Friend]GetOptimalFormat(&this, pFormat);

	public HRESULT GetNumberFormats(uint32* pulNumberFormats) mut => VT.[Friend]GetNumberFormats(&this, pulNumberFormats);

	public HRESULT GetFormat(uint32 ulIndex, Guid* pFormat) mut => VT.[Friend]GetFormat(&this, ulIndex, pFormat);
}

[CRepr]struct IMILBitmapEffectConnectionsInfo : IUnknown
{
	public new const Guid IID = .(0x476b538a, 0xc765, 0x4237, 0xba, 0x4a, 0xd6, 0xa8, 0x80, 0xff, 0x0c, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiNumInputs) GetNumberInputs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiNumOutputs) GetNumberOutputs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectConnectorInfo** ppConnectorInfo) GetInputConnectorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectConnectorInfo** ppConnectorInfo) GetOutputConnectorInfo;
	}


	public HRESULT GetNumberInputs(uint32* puiNumInputs) mut => VT.[Friend]GetNumberInputs(&this, puiNumInputs);

	public HRESULT GetNumberOutputs(uint32* puiNumOutputs) mut => VT.[Friend]GetNumberOutputs(&this, puiNumOutputs);

	public HRESULT GetInputConnectorInfo(uint32 uiIndex, IMILBitmapEffectConnectorInfo** ppConnectorInfo) mut => VT.[Friend]GetInputConnectorInfo(&this, uiIndex, ppConnectorInfo);

	public HRESULT GetOutputConnectorInfo(uint32 uiIndex, IMILBitmapEffectConnectorInfo** ppConnectorInfo) mut => VT.[Friend]GetOutputConnectorInfo(&this, uiIndex, ppConnectorInfo);
}

[CRepr]struct IMILBitmapEffectConnections : IUnknown
{
	public new const Guid IID = .(0xc2b5d861, 0x9b1a, 0x4374, 0x89, 0xb0, 0xde, 0xc4, 0x87, 0x4d, 0x6a, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectInputConnector** ppConnector) GetInputConnector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectOutputConnector** ppConnector) GetOutputConnector;
	}


	public HRESULT GetInputConnector(uint32 uiIndex, IMILBitmapEffectInputConnector** ppConnector) mut => VT.[Friend]GetInputConnector(&this, uiIndex, ppConnector);

	public HRESULT GetOutputConnector(uint32 uiIndex, IMILBitmapEffectOutputConnector** ppConnector) mut => VT.[Friend]GetOutputConnector(&this, uiIndex, ppConnector);
}

[CRepr]struct IMILBitmapEffect : IUnknown
{
	public new const Guid IID = .(0x8a6ff321, 0xc944, 0x4a1b, 0x99, 0x44, 0x99, 0x54, 0xaf, 0x30, 0x12, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectRenderContext* pContext, IWICBitmapSource** ppBitmapSource) GetOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectGroup** ppParentEffect) GetParentEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IWICBitmapSource* pBitmapSource) SetInputSource;
	}


	public HRESULT GetOutput(uint32 uiIndex, IMILBitmapEffectRenderContext* pContext, IWICBitmapSource** ppBitmapSource) mut => VT.[Friend]GetOutput(&this, uiIndex, pContext, ppBitmapSource);

	public HRESULT GetParentEffect(IMILBitmapEffectGroup** ppParentEffect) mut => VT.[Friend]GetParentEffect(&this, ppParentEffect);

	public HRESULT SetInputSource(uint32 uiIndex, IWICBitmapSource* pBitmapSource) mut => VT.[Friend]SetInputSource(&this, uiIndex, pBitmapSource);
}

[CRepr]struct IMILBitmapEffectImpl : IUnknown
{
	public new const Guid IID = .(0xcc2468f2, 0x9936, 0x47be, 0xb4, 0xaf, 0x06, 0xb5, 0xdf, 0x5d, 0xbc, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectOutputConnector* pOutputConnector, int16* pfModifyInPlace) IsInPlaceModificationAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectGroup* pParentEffect) SetParentEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IWICBitmapSource** ppBitmapSource) GetInputSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, MilRectD* pRect) GetInputSourceBounds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectRenderContext* pRenderContext, int16* pfModifyInPlace, IWICBitmapSource** ppBitmapSource) GetInputBitmapSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectRenderContext* pRenderContext, int16* pfModifyInPlace, IWICBitmapSource** ppBitmapSource) GetOutputBitmapSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pInner) Initialize;
	}


	public HRESULT IsInPlaceModificationAllowed(IMILBitmapEffectOutputConnector* pOutputConnector, int16* pfModifyInPlace) mut => VT.[Friend]IsInPlaceModificationAllowed(&this, pOutputConnector, pfModifyInPlace);

	public HRESULT SetParentEffect(IMILBitmapEffectGroup* pParentEffect) mut => VT.[Friend]SetParentEffect(&this, pParentEffect);

	public HRESULT GetInputSource(uint32 uiIndex, IWICBitmapSource** ppBitmapSource) mut => VT.[Friend]GetInputSource(&this, uiIndex, ppBitmapSource);

	public HRESULT GetInputSourceBounds(uint32 uiIndex, MilRectD* pRect) mut => VT.[Friend]GetInputSourceBounds(&this, uiIndex, pRect);

	public HRESULT GetInputBitmapSource(uint32 uiIndex, IMILBitmapEffectRenderContext* pRenderContext, int16* pfModifyInPlace, IWICBitmapSource** ppBitmapSource) mut => VT.[Friend]GetInputBitmapSource(&this, uiIndex, pRenderContext, pfModifyInPlace, ppBitmapSource);

	public HRESULT GetOutputBitmapSource(uint32 uiIndex, IMILBitmapEffectRenderContext* pRenderContext, int16* pfModifyInPlace, IWICBitmapSource** ppBitmapSource) mut => VT.[Friend]GetOutputBitmapSource(&this, uiIndex, pRenderContext, pfModifyInPlace, ppBitmapSource);

	public HRESULT Initialize(IUnknown* pInner) mut => VT.[Friend]Initialize(&this, pInner);
}

[CRepr]struct IMILBitmapEffectGroup : IUnknown
{
	public new const Guid IID = .(0x2f952360, 0x698a, 0x4ac6, 0x81, 0xa1, 0xbc, 0xfd, 0xf0, 0x8e, 0xb8, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectOutputConnector** ppConnector) GetInteriorInputConnector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectInputConnector** ppConnector) GetInteriorOutputConnector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffect* pEffect) Add;
	}


	public HRESULT GetInteriorInputConnector(uint32 uiIndex, IMILBitmapEffectOutputConnector** ppConnector) mut => VT.[Friend]GetInteriorInputConnector(&this, uiIndex, ppConnector);

	public HRESULT GetInteriorOutputConnector(uint32 uiIndex, IMILBitmapEffectInputConnector** ppConnector) mut => VT.[Friend]GetInteriorOutputConnector(&this, uiIndex, ppConnector);

	public HRESULT Add(IMILBitmapEffect* pEffect) mut => VT.[Friend]Add(&this, pEffect);
}

[CRepr]struct IMILBitmapEffectGroupImpl : IUnknown
{
	public new const Guid IID = .(0x78fed518, 0x1cfc, 0x4807, 0x8b, 0x85, 0x6b, 0x6e, 0x51, 0x39, 0x8f, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectRenderContext* pContext) Preprocess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiNumberChildren) GetNumberChildren;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffects** pChildren) GetChildren;
	}


	public HRESULT Preprocess(IMILBitmapEffectRenderContext* pContext) mut => VT.[Friend]Preprocess(&this, pContext);

	public HRESULT GetNumberChildren(uint32* puiNumberChildren) mut => VT.[Friend]GetNumberChildren(&this, puiNumberChildren);

	public HRESULT GetChildren(IMILBitmapEffects** pChildren) mut => VT.[Friend]GetChildren(&this, pChildren);
}

[CRepr]struct IMILBitmapEffectRenderContext : IUnknown
{
	public new const Guid IID = .(0x12a2ec7e, 0x2d33, 0x44b2, 0xb3, 0x34, 0x1a, 0xbb, 0x78, 0x46, 0xe3, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* format) SetOutputPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pFormat) GetOutputPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fSoftware) SetUseSoftwareRenderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MILMatrixF* pMatrix) SetInitialTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MILMatrixF* pMatrix) GetFinalTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dblDpiX, double dblDpiY) SetOutputDPI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdblDpiX, double* pdblDpiY) GetOutputDPI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MilRectD* pRect) SetRegionOfInterest;
	}


	public HRESULT SetOutputPixelFormat(Guid* format) mut => VT.[Friend]SetOutputPixelFormat(&this, format);

	public HRESULT GetOutputPixelFormat(Guid* pFormat) mut => VT.[Friend]GetOutputPixelFormat(&this, pFormat);

	public HRESULT SetUseSoftwareRenderer(int16 fSoftware) mut => VT.[Friend]SetUseSoftwareRenderer(&this, fSoftware);

	public HRESULT SetInitialTransform(MILMatrixF* pMatrix) mut => VT.[Friend]SetInitialTransform(&this, pMatrix);

	public HRESULT GetFinalTransform(MILMatrixF* pMatrix) mut => VT.[Friend]GetFinalTransform(&this, pMatrix);

	public HRESULT SetOutputDPI(double dblDpiX, double dblDpiY) mut => VT.[Friend]SetOutputDPI(&this, dblDpiX, dblDpiY);

	public HRESULT GetOutputDPI(double* pdblDpiX, double* pdblDpiY) mut => VT.[Friend]GetOutputDPI(&this, pdblDpiX, pdblDpiY);

	public HRESULT SetRegionOfInterest(MilRectD* pRect) mut => VT.[Friend]SetRegionOfInterest(&this, pRect);
}

[CRepr]struct IMILBitmapEffectRenderContextImpl : IUnknown
{
	public new const Guid IID = .(0x4d25accb, 0x797d, 0x4fd2, 0xb1, 0x28, 0xdf, 0xfe, 0xff, 0x84, 0xfc, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfSoftware) GetUseSoftwareRenderer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MILMatrixF* pMatrix) GetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MILMatrixF* pMatrix) UpdateTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MilRectD* pRect) GetOutputBounds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MilRectD* pRect) UpdateOutputBounds;
	}


	public HRESULT GetUseSoftwareRenderer(int16* pfSoftware) mut => VT.[Friend]GetUseSoftwareRenderer(&this, pfSoftware);

	public HRESULT GetTransform(MILMatrixF* pMatrix) mut => VT.[Friend]GetTransform(&this, pMatrix);

	public HRESULT UpdateTransform(MILMatrixF* pMatrix) mut => VT.[Friend]UpdateTransform(&this, pMatrix);

	public HRESULT GetOutputBounds(MilRectD* pRect) mut => VT.[Friend]GetOutputBounds(&this, pRect);

	public HRESULT UpdateOutputBounds(MilRectD* pRect) mut => VT.[Friend]UpdateOutputBounds(&this, pRect);
}

[CRepr]struct IMILBitmapEffectFactory : IUnknown
{
	public new const Guid IID = .(0x33a9df34, 0xa403, 0x4ec7, 0xb0, 0x7e, 0xbc, 0x06, 0x82, 0x37, 0x08, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidEffect, IMILBitmapEffect** ppEffect) CreateEffect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectRenderContext** ppContext) CreateContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffect** ppEffect) CreateEffectOuter;
	}


	public HRESULT CreateEffect(in Guid pguidEffect, IMILBitmapEffect** ppEffect) mut => VT.[Friend]CreateEffect(&this, pguidEffect, ppEffect);

	public HRESULT CreateContext(IMILBitmapEffectRenderContext** ppContext) mut => VT.[Friend]CreateContext(&this, ppContext);

	public HRESULT CreateEffectOuter(IMILBitmapEffect** ppEffect) mut => VT.[Friend]CreateEffectOuter(&this, ppEffect);
}

[CRepr]struct IMILBitmapEffectPrimitive : IUnknown
{
	public new const Guid IID = .(0x67e31025, 0x3091, 0x4dfc, 0x98, 0xd6, 0xdd, 0x49, 0x45, 0x51, 0x46, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectRenderContext* pContext, int16* pfModifyInPlace, IWICBitmapSource** ppBitmapSource) GetOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, MilPoint2D* p, int16 fForwardTransform, IMILBitmapEffectRenderContext* pContext, int16* pfPointTransformed) TransformPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, MilRectD* p, int16 fForwardTransform, IMILBitmapEffectRenderContext* pContext) TransformRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, int16* pfAffine) HasAffineTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, int16* pfHasInverse) HasInverseTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, MilMatrix3x2D* pMatrix) GetAffineMatrix;
	}


	public HRESULT GetOutput(uint32 uiIndex, IMILBitmapEffectRenderContext* pContext, int16* pfModifyInPlace, IWICBitmapSource** ppBitmapSource) mut => VT.[Friend]GetOutput(&this, uiIndex, pContext, pfModifyInPlace, ppBitmapSource);

	public HRESULT TransformPoint(uint32 uiIndex, MilPoint2D* p, int16 fForwardTransform, IMILBitmapEffectRenderContext* pContext, int16* pfPointTransformed) mut => VT.[Friend]TransformPoint(&this, uiIndex, p, fForwardTransform, pContext, pfPointTransformed);

	public HRESULT TransformRect(uint32 uiIndex, MilRectD* p, int16 fForwardTransform, IMILBitmapEffectRenderContext* pContext) mut => VT.[Friend]TransformRect(&this, uiIndex, p, fForwardTransform, pContext);

	public HRESULT HasAffineTransform(uint32 uiIndex, int16* pfAffine) mut => VT.[Friend]HasAffineTransform(&this, uiIndex, pfAffine);

	public HRESULT HasInverseTransform(uint32 uiIndex, int16* pfHasInverse) mut => VT.[Friend]HasInverseTransform(&this, uiIndex, pfHasInverse);

	public HRESULT GetAffineMatrix(uint32 uiIndex, MilMatrix3x2D* pMatrix) mut => VT.[Friend]GetAffineMatrix(&this, uiIndex, pMatrix);
}

[CRepr]struct IMILBitmapEffectPrimitiveImpl : IUnknown
{
	public new const Guid IID = .(0xce41e00b, 0xefa6, 0x44e7, 0xb0, 0x07, 0xdd, 0x04, 0x2e, 0x3a, 0xe1, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiOutputIndex, int16* pfDirty) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiOutputIndex, int16* pfVolatile) IsVolatile;
	}


	public HRESULT IsDirty(uint32 uiOutputIndex, int16* pfDirty) mut => VT.[Friend]IsDirty(&this, uiOutputIndex, pfDirty);

	public HRESULT IsVolatile(uint32 uiOutputIndex, int16* pfVolatile) mut => VT.[Friend]IsVolatile(&this, uiOutputIndex, pfVolatile);
}

[CRepr]struct IMILBitmapEffects : IUnknown
{
	public new const Guid IID = .(0x51ac3dce, 0x67c5, 0x448b, 0x91, 0x80, 0xad, 0x3e, 0xab, 0xdd, 0xd5, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppiuReturn) _NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectGroup** ppEffect) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uindex, IMILBitmapEffect** ppEffect) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiCount) get_Count;
	}


	public HRESULT _NewEnum(IUnknown** ppiuReturn) mut => VT.[Friend]_NewEnum(&this, ppiuReturn);

	public HRESULT get_Parent(IMILBitmapEffectGroup** ppEffect) mut => VT.[Friend]get_Parent(&this, ppEffect);

	public HRESULT Item(uint32 uindex, IMILBitmapEffect** ppEffect) mut => VT.[Friend]Item(&this, uindex, ppEffect);

	public HRESULT get_Count(uint32* puiCount) mut => VT.[Friend]get_Count(&this, puiCount);
}

[CRepr]struct IMILBitmapEffectConnector : IMILBitmapEffectConnectorInfo
{
	public new const Guid IID = .(0xf59567b3, 0x76c1, 0x4d47, 0xba, 0x1e, 0x79, 0xf9, 0x55, 0xe3, 0x50, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMILBitmapEffectConnectorInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfConnected) IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffect** ppEffect) GetBitmapEffect;
	}


	public HRESULT IsConnected(int16* pfConnected) mut => VT.[Friend]IsConnected(&this, pfConnected);

	public HRESULT GetBitmapEffect(IMILBitmapEffect** ppEffect) mut => VT.[Friend]GetBitmapEffect(&this, ppEffect);
}

[CRepr]struct IMILBitmapEffectInputConnector : IMILBitmapEffectConnector
{
	public new const Guid IID = .(0xa9b4ecaa, 0x7a3c, 0x45e7, 0x85, 0x73, 0xf4, 0xb8, 0x1b, 0x60, 0xdd, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMILBitmapEffectConnector.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectOutputConnector* pConnector) ConnectTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectOutputConnector** ppConnector) GetConnection;
	}


	public HRESULT ConnectTo(IMILBitmapEffectOutputConnector* pConnector) mut => VT.[Friend]ConnectTo(&this, pConnector);

	public HRESULT GetConnection(IMILBitmapEffectOutputConnector** ppConnector) mut => VT.[Friend]GetConnection(&this, ppConnector);
}

[CRepr]struct IMILBitmapEffectOutputConnector : IMILBitmapEffectConnector
{
	public new const Guid IID = .(0x92957aad, 0x841b, 0x4866, 0x82, 0xec, 0x87, 0x52, 0x46, 0x8b, 0x07, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMILBitmapEffectConnector.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiNumberConnections) GetNumberConnections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, IMILBitmapEffectInputConnector** ppConnection) GetConnection;
	}


	public HRESULT GetNumberConnections(uint32* puiNumberConnections) mut => VT.[Friend]GetNumberConnections(&this, puiNumberConnections);

	public HRESULT GetConnection(uint32 uiIndex, IMILBitmapEffectInputConnector** ppConnection) mut => VT.[Friend]GetConnection(&this, uiIndex, ppConnection);
}

[CRepr]struct IMILBitmapEffectOutputConnectorImpl : IUnknown
{
	public new const Guid IID = .(0x21fae777, 0x8b39, 0x4bfa, 0x9f, 0x2d, 0xf3, 0x94, 0x1e, 0xd3, 0x69, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectInputConnector* pConnection) AddBackLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectInputConnector* pConnection) RemoveBackLink;
	}


	public HRESULT AddBackLink(IMILBitmapEffectInputConnector* pConnection) mut => VT.[Friend]AddBackLink(&this, pConnection);

	public HRESULT RemoveBackLink(IMILBitmapEffectInputConnector* pConnection) mut => VT.[Friend]RemoveBackLink(&this, pConnection);
}

[CRepr]struct IMILBitmapEffectInteriorInputConnector : IUnknown
{
	public new const Guid IID = .(0x20287e9e, 0x86a2, 0x4e15, 0x95, 0x3d, 0xeb, 0x14, 0x38, 0xa5, 0xb8, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectInputConnector** pInputConnector) GetInputConnector;
	}


	public HRESULT GetInputConnector(IMILBitmapEffectInputConnector** pInputConnector) mut => VT.[Friend]GetInputConnector(&this, pInputConnector);
}

[CRepr]struct IMILBitmapEffectInteriorOutputConnector : IUnknown
{
	public new const Guid IID = .(0x00bbb6dc, 0xacc9, 0x4bfc, 0xb3, 0x44, 0x8b, 0xee, 0x38, 0x3d, 0xfe, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffectOutputConnector** pOutputConnector) GetOutputConnector;
	}


	public HRESULT GetOutputConnector(IMILBitmapEffectOutputConnector** pOutputConnector) mut => VT.[Friend]GetOutputConnector(&this, pOutputConnector);
}

[CRepr]struct IMILBitmapEffectEvents : IUnknown
{
	public new const Guid IID = .(0x2e880dd8, 0xf8ce, 0x457b, 0x81, 0x99, 0xd6, 0x0b, 0xb3, 0xd7, 0xef, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffect* pEffect, BSTR bstrPropertyName) PropertyChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMILBitmapEffect* pEffect, MilRectD* pRect) DirtyRegion;
	}


	public HRESULT PropertyChange(IMILBitmapEffect* pEffect, BSTR bstrPropertyName) mut => VT.[Friend]PropertyChange(&this, pEffect, bstrPropertyName);

	public HRESULT DirtyRegion(IMILBitmapEffect* pEffect, MilRectD* pRect) mut => VT.[Friend]DirtyRegion(&this, pEffect, pRect);
}

#endregion
