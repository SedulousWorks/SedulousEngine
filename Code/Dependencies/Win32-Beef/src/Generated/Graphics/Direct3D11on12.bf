using Win32.Foundation;
using Win32.System.Com;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Direct3D12;
using System;

namespace Win32.Graphics.Direct3D11on12;
#region Function Pointers
public function HRESULT PFN_D3D11ON12_CREATE_DEVICE(IUnknown* param0, uint32 param1, D3D_FEATURE_LEVEL* param2, uint32 FeatureLevels, IUnknown** param4, uint32 NumQueues, uint32 param6, ID3D11Device** param7, ID3D11DeviceContext** param8, D3D_FEATURE_LEVEL* param9);

#endregion

#region Structs
[CRepr]
public struct D3D11_RESOURCE_FLAGS
{
	public uint32 BindFlags;
	public uint32 MiscFlags;
	public uint32 CPUAccessFlags;
	public uint32 StructureByteStride;
}

#endregion

#region COM Types
[CRepr]struct ID3D11On12Device : IUnknown
{
	public new const Guid IID = .(0x85611e73, 0x70a9, 0x490e, 0x96, 0x14, 0xa9, 0xe3, 0x02, 0x77, 0x79, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pResource12, D3D11_RESOURCE_FLAGS* pFlags11, D3D12_RESOURCE_STATES InState, D3D12_RESOURCE_STATES OutState, in Guid riid, void** ppResource11) CreateWrappedResource;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, ID3D11Resource** ppResources, uint32 NumResources) ReleaseWrappedResources;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, ID3D11Resource** ppResources, uint32 NumResources) AcquireWrappedResources;
	}


	public HRESULT CreateWrappedResource(IUnknown* pResource12, D3D11_RESOURCE_FLAGS* pFlags11, D3D12_RESOURCE_STATES InState, D3D12_RESOURCE_STATES OutState, in Guid riid, void** ppResource11) mut => VT.[Friend]CreateWrappedResource(&this, pResource12, pFlags11, InState, OutState, riid, ppResource11);

	public void ReleaseWrappedResources(ID3D11Resource** ppResources, uint32 NumResources) mut => VT.[Friend]ReleaseWrappedResources(&this, ppResources, NumResources);

	public void AcquireWrappedResources(ID3D11Resource** ppResources, uint32 NumResources) mut => VT.[Friend]AcquireWrappedResources(&this, ppResources, NumResources);
}

[CRepr]struct ID3D11On12Device1 : ID3D11On12Device
{
	public new const Guid IID = .(0xbdb64df4, 0xea2f, 0x4c70, 0xb8, 0x61, 0xaa, 0xab, 0x12, 0x58, 0xbb, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ID3D11On12Device.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvDevice) GetD3D12Device;
	}


	public HRESULT GetD3D12Device(in Guid riid, void** ppvDevice) mut => VT.[Friend]GetD3D12Device(&this, riid, ppvDevice);
}

[CRepr]struct ID3D11On12Device2 : ID3D11On12Device1
{
	public new const Guid IID = .(0xdc90f331, 0x4740, 0x43fa, 0x86, 0x6e, 0x67, 0xf1, 0x2c, 0xb5, 0x82, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ID3D11On12Device1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID3D11Resource* pResource11, ID3D12CommandQueue* pCommandQueue, in Guid riid, void** ppvResource12) UnwrapUnderlyingResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID3D11Resource* pResource11, uint32 NumSync, uint64* pSignalValues, ID3D12Fence** ppFences) ReturnUnderlyingResource;
	}


	public HRESULT UnwrapUnderlyingResource(ID3D11Resource* pResource11, ID3D12CommandQueue* pCommandQueue, in Guid riid, void** ppvResource12) mut => VT.[Friend]UnwrapUnderlyingResource(&this, pResource11, pCommandQueue, riid, ppvResource12);

	public HRESULT ReturnUnderlyingResource(ID3D11Resource* pResource11, uint32 NumSync, uint64* pSignalValues, ID3D12Fence** ppFences) mut => VT.[Friend]ReturnUnderlyingResource(&this, pResource11, NumSync, pSignalValues, ppFences);
}

#endregion

#region Functions
public static
{
	[Import("d3d11.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3D11On12CreateDevice(IUnknown* pDevice, uint32 Flags, D3D_FEATURE_LEVEL* pFeatureLevels, uint32 FeatureLevels, IUnknown** ppCommandQueues, uint32 NumQueues, uint32 NodeMask, ID3D11Device** ppDevice, ID3D11DeviceContext** ppImmediateContext, D3D_FEATURE_LEVEL* pChosenFeatureLevel);

}
#endregion
