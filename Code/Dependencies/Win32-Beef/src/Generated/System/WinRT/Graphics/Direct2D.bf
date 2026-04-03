using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Direct2D;
using System;

namespace Win32.System.WinRT.Graphics.Direct2D;

#region Enums

[AllowDuplicates]
public enum GRAPHICS_EFFECT_PROPERTY_MAPPING : int32
{
	GRAPHICS_EFFECT_PROPERTY_MAPPING_UNKNOWN = 0,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_DIRECT = 1,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_VECTORX = 2,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_VECTORY = 3,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_VECTORZ = 4,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_VECTORW = 5,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_RECT_TO_VECTOR4 = 6,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_RADIANS_TO_DEGREES = 7,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_COLORMATRIX_ALPHA_MODE = 8,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_COLOR_TO_VECTOR3 = 9,
	GRAPHICS_EFFECT_PROPERTY_MAPPING_COLOR_TO_VECTOR4 = 10,
}

#endregion


#region COM Types
[CRepr]struct IGraphicsEffectD2D1Interop : IUnknown
{
	public new const Guid IID = .(0x2fc57384, 0xa068, 0x44d7, 0xa3, 0x31, 0x30, 0x98, 0x2f, 0xcf, 0x71, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* id) GetEffectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, uint32* index, GRAPHICS_EFFECT_PROPERTY_MAPPING* mapping) GetNamedPropertyMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetPropertyCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, void** value) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, void** source) GetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetSourceCount;
	}


	public HRESULT GetEffectId(Guid* id) mut => VT.[Friend]GetEffectId(&this, id);

	public HRESULT GetNamedPropertyMapping(PWSTR name, uint32* index, GRAPHICS_EFFECT_PROPERTY_MAPPING* mapping) mut => VT.[Friend]GetNamedPropertyMapping(&this, name, index, mapping);

	public HRESULT GetPropertyCount(uint32* count) mut => VT.[Friend]GetPropertyCount(&this, count);

	public HRESULT GetProperty(uint32 index, void** value) mut => VT.[Friend]GetProperty(&this, index, value);

	public HRESULT GetSource(uint32 index, void** source) mut => VT.[Friend]GetSource(&this, index, source);

	public HRESULT GetSourceCount(uint32* count) mut => VT.[Friend]GetSourceCount(&this, count);
}

[CRepr]struct IGeometrySource2DInterop : IUnknown
{
	public new const Guid IID = .(0x0657af73, 0x53fd, 0x47cf, 0x84, 0xff, 0xc8, 0x49, 0x2d, 0x2a, 0x80, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1Geometry** value) GetGeometry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1Factory* factory, ID2D1Geometry** value) TryGetGeometryUsingFactory;
	}


	public HRESULT GetGeometry(ID2D1Geometry** value) mut => VT.[Friend]GetGeometry(&this, value);

	public HRESULT TryGetGeometryUsingFactory(ID2D1Factory* factory, ID2D1Geometry** value) mut => VT.[Friend]TryGetGeometryUsingFactory(&this, factory, value);
}

#endregion
