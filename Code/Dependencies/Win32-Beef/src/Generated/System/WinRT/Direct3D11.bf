using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Dxgi;
using Win32.System.WinRT;
using System;

namespace Win32.System.WinRT.Direct3D11;

#region COM Types
[CRepr]struct IDirect3DDxgiInterfaceAccess : IUnknown
{
	public new const Guid IID = .(0xa9b3d012, 0x3df2, 0x4ee3, 0xb8, 0xd1, 0x86, 0x95, 0xf4, 0x57, 0xd3, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, void** p) GetInterface;
	}


	public HRESULT GetInterface(in Guid iid, void** p) mut => VT.[Friend]GetInterface(&this, iid, p);
}

#endregion

#region Functions
public static
{
	[Import("d3d11.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDirect3D11DeviceFromDXGIDevice(IDXGIDevice* dxgiDevice, IInspectable** graphicsDevice);

	[Import("d3d11.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDirect3D11SurfaceFromDXGISurface(IDXGISurface* dgxiSurface, IInspectable** graphicsSurface);

}
#endregion
