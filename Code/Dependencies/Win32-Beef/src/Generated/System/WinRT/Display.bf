using Win32.System.Com;
using Win32.Foundation;
using Win32.System.WinRT;
using Win32.Security;
using System;

namespace Win32.System.WinRT.Display;

#region COM Types
[CRepr]struct IDisplayDeviceInterop : IUnknown
{
	public new const Guid IID = .(0x64338358, 0x366a, 0x471b, 0xbd, 0x56, 0xdd, 0x8e, 0xf4, 0x8e, 0x43, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable* pObject, SECURITY_ATTRIBUTES* pSecurityAttributes, uint32 Access, HSTRING Name, HANDLE* pHandle) CreateSharedHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE NTHandle, Guid riid, void** ppvObj) OpenSharedHandle;
	}


	public HRESULT CreateSharedHandle(IInspectable* pObject, SECURITY_ATTRIBUTES* pSecurityAttributes, uint32 Access, HSTRING Name, HANDLE* pHandle) mut => VT.[Friend]CreateSharedHandle(&this, pObject, pSecurityAttributes, Access, Name, pHandle);

	public HRESULT OpenSharedHandle(HANDLE NTHandle, Guid riid, void** ppvObj) mut => VT.[Friend]OpenSharedHandle(&this, NTHandle, riid, ppvObj);
}

[CRepr]struct IDisplayPathInterop : IUnknown
{
	public new const Guid IID = .(0xa6ba4205, 0xe59e, 0x4e71, 0xb2, 0x5b, 0x4e, 0x43, 0x6d, 0x21, 0xee, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* pValue) CreateSourcePresentationHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pSourceId) GetSourceId;
	}


	public HRESULT CreateSourcePresentationHandle(HANDLE* pValue) mut => VT.[Friend]CreateSourcePresentationHandle(&this, pValue);

	public HRESULT GetSourceId(uint32* pSourceId) mut => VT.[Friend]GetSourceId(&this, pSourceId);
}

#endregion
