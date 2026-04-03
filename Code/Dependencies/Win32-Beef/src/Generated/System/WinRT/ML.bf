using Win32.System.Com;
using Win32.Foundation;
using Win32.AI.MachineLearning.WinML;
using Win32.Graphics.Direct3D12;
using System;

namespace Win32.System.WinRT.ML;

#region COM Types
[CRepr]struct ILearningModelOperatorProviderNative : IUnknown
{
	public new const Guid IID = .(0x1adaa23a, 0xeb67, 0x41f3, 0xaa, 0xd8, 0x5d, 0x98, 0x4e, 0x9b, 0xac, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLOperatorRegistry** ppOperatorRegistry) GetRegistry;
	}


	public HRESULT GetRegistry(IMLOperatorRegistry** ppOperatorRegistry) mut => VT.[Friend]GetRegistry(&this, ppOperatorRegistry);
}

[CRepr]struct ITensorNative : IUnknown
{
	public new const Guid IID = .(0x52f547ef, 0x5b03, 0x49b5, 0x82, 0xd6, 0x56, 0x5f, 0x1e, 0xe0, 0xdd, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** value, uint32* capacity) GetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID3D12Resource** result) GetD3D12Resource;
	}


	public HRESULT GetBuffer(uint8** value, uint32* capacity) mut => VT.[Friend]GetBuffer(&this, value, capacity);

	public HRESULT GetD3D12Resource(ID3D12Resource** result) mut => VT.[Friend]GetD3D12Resource(&this, result);
}

[CRepr]struct ITensorStaticsNative : IUnknown
{
	public new const Guid IID = .(0x39d055a4, 0x66f6, 0x4ebc, 0x95, 0xd9, 0x7a, 0x29, 0xeb, 0xe7, 0x69, 0x0a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID3D12Resource* value, int64* shape, int32 shapeCount, IUnknown** result) CreateFromD3D12Resource;
	}


	public HRESULT CreateFromD3D12Resource(ID3D12Resource* value, int64* shape, int32 shapeCount, IUnknown** result) mut => VT.[Friend]CreateFromD3D12Resource(&this, value, shape, shapeCount, result);
}

[CRepr]struct ILearningModelDeviceFactoryNative : IUnknown
{
	public new const Guid IID = .(0x1e9b31a1, 0x662e, 0x4ae0, 0xaf, 0x67, 0xf6, 0x3b, 0xb3, 0x37, 0xe6, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID3D12CommandQueue* value, IUnknown** result) CreateFromD3D12CommandQueue;
	}


	public HRESULT CreateFromD3D12CommandQueue(ID3D12CommandQueue* value, IUnknown** result) mut => VT.[Friend]CreateFromD3D12CommandQueue(&this, value, result);
}

[CRepr]struct ILearningModelSessionOptionsNative : IUnknown
{
	public new const Guid IID = .(0xc71e953f, 0x37b4, 0x4564, 0x86, 0x58, 0xd8, 0x39, 0x68, 0x66, 0xdb, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 intraOpNumThreads) SetIntraOpNumThreadsOverride;
	}


	public HRESULT SetIntraOpNumThreadsOverride(uint32 intraOpNumThreads) mut => VT.[Friend]SetIntraOpNumThreadsOverride(&this, intraOpNumThreads);
}

#endregion
