using Win32.Foundation;
using Win32.System.Com;
using Win32.Graphics.Direct3D9;
using Win32.Graphics.Direct3D12;
using System;

namespace Win32.Graphics.Direct3D9on12;

#region Constants
public static
{
	public const uint32 MAX_D3D9ON12_QUEUES = 2;
}
#endregion
#region Function Pointers
public function HRESULT PFN_Direct3DCreate9On12Ex(uint32 SDKVersion, D3D9ON12_ARGS* pOverrideList, uint32 NumOverrideEntries, IDirect3D9Ex** ppOutputInterface);

public function IDirect3D9* PFN_Direct3DCreate9On12(uint32 SDKVersion, D3D9ON12_ARGS* pOverrideList, uint32 NumOverrideEntries);

#endregion

#region Structs
[CRepr]
public struct D3D9ON12_ARGS
{
	public BOOL Enable9On12;
	public IUnknown* pD3D12Device;
	public IUnknown*[2] ppD3D12Queues;
	public uint32 NumQueues;
	public uint32 NodeMask;
}

#endregion

#region COM Types
[CRepr]struct IDirect3DDevice9On12 : IUnknown
{
	public new const Guid IID = .(0xe7fda234, 0xb589, 0x4049, 0x94, 0x0d, 0x88, 0x78, 0x97, 0x75, 0x31, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvDevice) GetD3D12Device;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirect3DResource9* pResource, ID3D12CommandQueue* pCommandQueue, in Guid riid, void** ppvResource12) UnwrapUnderlyingResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirect3DResource9* pResource, uint32 NumSync, uint64* pSignalValues, ID3D12Fence** ppFences) ReturnUnderlyingResource;
	}


	public HRESULT GetD3D12Device(in Guid riid, void** ppvDevice) mut => VT.[Friend]GetD3D12Device(&this, riid, ppvDevice);

	public HRESULT UnwrapUnderlyingResource(IDirect3DResource9* pResource, ID3D12CommandQueue* pCommandQueue, in Guid riid, void** ppvResource12) mut => VT.[Friend]UnwrapUnderlyingResource(&this, pResource, pCommandQueue, riid, ppvResource12);

	public HRESULT ReturnUnderlyingResource(IDirect3DResource9* pResource, uint32 NumSync, uint64* pSignalValues, ID3D12Fence** ppFences) mut => VT.[Friend]ReturnUnderlyingResource(&this, pResource, NumSync, pSignalValues, ppFences);
}

#endregion

#region Functions
public static
{
	[Import("d3d9.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT Direct3DCreate9On12Ex(uint32 SDKVersion, D3D9ON12_ARGS* pOverrideList, uint32 NumOverrideEntries, IDirect3D9Ex** ppOutputInterface);

	[Import("d3d9.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IDirect3D9* Direct3DCreate9On12(uint32 SDKVersion, D3D9ON12_ARGS* pOverrideList, uint32 NumOverrideEntries);

}
#endregion
