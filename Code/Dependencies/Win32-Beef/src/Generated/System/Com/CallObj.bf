using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.Com.CallObj;

#region Enums

[AllowDuplicates]
public enum CALLFRAME_COPY : int32
{
	CALLFRAME_COPY_NESTED = 1,
	CALLFRAME_COPY_INDEPENDENT = 2,
}


[AllowDuplicates]
public enum CALLFRAME_FREE : int32
{
	CALLFRAME_FREE_NONE = 0,
	CALLFRAME_FREE_IN = 1,
	CALLFRAME_FREE_INOUT = 2,
	CALLFRAME_FREE_OUT = 4,
	CALLFRAME_FREE_TOP_INOUT = 8,
	CALLFRAME_FREE_TOP_OUT = 16,
	CALLFRAME_FREE_ALL = 31,
}


[AllowDuplicates]
public enum CALLFRAME_NULL : int32
{
	CALLFRAME_NULL_NONE = 0,
	CALLFRAME_NULL_INOUT = 2,
	CALLFRAME_NULL_OUT = 4,
	CALLFRAME_NULL_ALL = 6,
}


[AllowDuplicates]
public enum CALLFRAME_WALK : int32
{
	CALLFRAME_WALK_IN = 1,
	CALLFRAME_WALK_INOUT = 2,
	CALLFRAME_WALK_OUT = 4,
}

#endregion


#region Structs
[CRepr]
public struct CALLFRAMEINFO
{
	public uint32 iMethod;
	public BOOL fHasInValues;
	public BOOL fHasInOutValues;
	public BOOL fHasOutValues;
	public BOOL fDerivesFromIDispatch;
	public int32 cInInterfacesMax;
	public int32 cInOutInterfacesMax;
	public int32 cOutInterfacesMax;
	public int32 cTopLevelInInterfaces;
	public Guid iid;
	public uint32 cMethod;
	public uint32 cParams;
}

[CRepr]
public struct CALLFRAMEPARAMINFO
{
	public BOOLEAN fIn;
	public BOOLEAN fOut;
	public uint32 stackOffset;
	public uint32 cbParam;
}

[CRepr]
public struct CALLFRAME_MARSHALCONTEXT
{
	public BOOLEAN fIn;
	public uint32 dwDestContext;
	public void* pvDestContext;
	public IUnknown* punkReserved;
	public Guid guidTransferSyntax;
}

#endregion

#region COM Types
[CRepr]struct ICallFrame : IUnknown
{
	public new const Guid IID = .(0xd573b4b0, 0x894e, 0x11d2, 0xb8, 0xb6, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CALLFRAMEINFO* pInfo) GetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pIID, uint32* piMethod) GetIIDAndMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pwszInterface, PWSTR* pwszMethod) GetNames;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self) GetStackLocation;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pvStack) SetStackLocation;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, HRESULT hr) SetReturnValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetReturnValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iparam, CALLFRAMEPARAMINFO* pInfo) GetParamInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iparam, VARIANT* pvar) SetParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iparam, VARIANT* pvar) GetParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CALLFRAME_COPY copyControl, ICallFrameWalker* pWalker, ICallFrame** ppFrame) Copy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICallFrame* pframeArgsDest, ICallFrameWalker* pWalkerDestFree, ICallFrameWalker* pWalkerCopy, uint32 freeFlags, ICallFrameWalker* pWalkerFree, uint32 nullFlags) Free;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iparam, uint32 freeFlags, ICallFrameWalker* pWalkerFree, uint32 nullFlags) FreeParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 walkWhat, ICallFrameWalker* pWalker) WalkFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CALLFRAME_MARSHALCONTEXT* pmshlContext, MSHLFLAGS mshlflags, uint32* pcbBufferNeeded) GetMarshalSizeMax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CALLFRAME_MARSHALCONTEXT* pmshlContext, MSHLFLAGS mshlflags, void* pBuffer, uint32 cbBuffer, uint32* pcbBufferUsed, uint32* pdataRep, uint32* prpcFlags) Marshal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pBuffer, uint32 cbBuffer, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext, uint32* pcbUnmarshalled) Unmarshal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pBuffer, uint32 cbBuffer, uint32 ibFirstRelease, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext) ReleaseMarshalData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvReceiver) Invoke;
	}


	public HRESULT GetInfo(CALLFRAMEINFO* pInfo) mut => VT.[Friend]GetInfo(&this, pInfo);

	public HRESULT GetIIDAndMethod(Guid* pIID, uint32* piMethod) mut => VT.[Friend]GetIIDAndMethod(&this, pIID, piMethod);

	public HRESULT GetNames(PWSTR* pwszInterface, PWSTR* pwszMethod) mut => VT.[Friend]GetNames(&this, pwszInterface, pwszMethod);

	public void* GetStackLocation() mut => VT.[Friend]GetStackLocation(&this);

	public void SetStackLocation(void* pvStack) mut => VT.[Friend]SetStackLocation(&this, pvStack);

	public void SetReturnValue(HRESULT hr) mut => VT.[Friend]SetReturnValue(&this, hr);

	public HRESULT GetReturnValue() mut => VT.[Friend]GetReturnValue(&this);

	public HRESULT GetParamInfo(uint32 iparam, CALLFRAMEPARAMINFO* pInfo) mut => VT.[Friend]GetParamInfo(&this, iparam, pInfo);

	public HRESULT SetParam(uint32 iparam, VARIANT* pvar) mut => VT.[Friend]SetParam(&this, iparam, pvar);

	public HRESULT GetParam(uint32 iparam, VARIANT* pvar) mut => VT.[Friend]GetParam(&this, iparam, pvar);

	public HRESULT Copy(CALLFRAME_COPY copyControl, ICallFrameWalker* pWalker, ICallFrame** ppFrame) mut => VT.[Friend]Copy(&this, copyControl, pWalker, ppFrame);

	public HRESULT Free(ICallFrame* pframeArgsDest, ICallFrameWalker* pWalkerDestFree, ICallFrameWalker* pWalkerCopy, uint32 freeFlags, ICallFrameWalker* pWalkerFree, uint32 nullFlags) mut => VT.[Friend]Free(&this, pframeArgsDest, pWalkerDestFree, pWalkerCopy, freeFlags, pWalkerFree, nullFlags);

	public HRESULT FreeParam(uint32 iparam, uint32 freeFlags, ICallFrameWalker* pWalkerFree, uint32 nullFlags) mut => VT.[Friend]FreeParam(&this, iparam, freeFlags, pWalkerFree, nullFlags);

	public HRESULT WalkFrame(uint32 walkWhat, ICallFrameWalker* pWalker) mut => VT.[Friend]WalkFrame(&this, walkWhat, pWalker);

	public HRESULT GetMarshalSizeMax(CALLFRAME_MARSHALCONTEXT* pmshlContext, MSHLFLAGS mshlflags, uint32* pcbBufferNeeded) mut => VT.[Friend]GetMarshalSizeMax(&this, pmshlContext, mshlflags, pcbBufferNeeded);

	public HRESULT Marshal(CALLFRAME_MARSHALCONTEXT* pmshlContext, MSHLFLAGS mshlflags, void* pBuffer, uint32 cbBuffer, uint32* pcbBufferUsed, uint32* pdataRep, uint32* prpcFlags) mut => VT.[Friend]Marshal(&this, pmshlContext, mshlflags, pBuffer, cbBuffer, pcbBufferUsed, pdataRep, prpcFlags);

	public HRESULT Unmarshal(void* pBuffer, uint32 cbBuffer, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext, uint32* pcbUnmarshalled) mut => VT.[Friend]Unmarshal(&this, pBuffer, cbBuffer, dataRep, pcontext, pcbUnmarshalled);

	public HRESULT ReleaseMarshalData(void* pBuffer, uint32 cbBuffer, uint32 ibFirstRelease, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext) mut => VT.[Friend]ReleaseMarshalData(&this, pBuffer, cbBuffer, ibFirstRelease, dataRep, pcontext);

	public HRESULT Invoke(void* pvReceiver) mut => VT.[Friend]Invoke(&this, pvReceiver);
}

[CRepr]struct ICallIndirect : IUnknown
{
	public new const Guid IID = .(0xd573b4b1, 0x894e, 0x11d2, 0xb8, 0xb6, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phrReturn, uint32 iMethod, void* pvArgs, uint32* cbArgs) CallIndirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iMethod, CALLFRAMEINFO* pInfo, PWSTR* pwszMethod) GetMethodInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iMethod, uint32* cbArgs) GetStackSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* piid, BOOL* pfDerivesFromIDispatch, uint32* pcMethod, PWSTR* pwszInterface) GetIID;
	}


	public HRESULT CallIndirect(HRESULT* phrReturn, uint32 iMethod, void* pvArgs, uint32* cbArgs) mut => VT.[Friend]CallIndirect(&this, phrReturn, iMethod, pvArgs, cbArgs);

	public HRESULT GetMethodInfo(uint32 iMethod, CALLFRAMEINFO* pInfo, PWSTR* pwszMethod) mut => VT.[Friend]GetMethodInfo(&this, iMethod, pInfo, pwszMethod);

	public HRESULT GetStackSize(uint32 iMethod, uint32* cbArgs) mut => VT.[Friend]GetStackSize(&this, iMethod, cbArgs);

	public HRESULT GetIID(Guid* piid, BOOL* pfDerivesFromIDispatch, uint32* pcMethod, PWSTR* pwszInterface) mut => VT.[Friend]GetIID(&this, piid, pfDerivesFromIDispatch, pcMethod, pwszInterface);
}

[CRepr]struct ICallInterceptor : ICallIndirect
{
	public new const Guid IID = .(0x60c7ca75, 0x896d, 0x11d2, 0xb8, 0xb6, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICallIndirect.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICallFrameEvents* psink) RegisterSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICallFrameEvents** ppsink) GetRegisteredSink;
	}


	public HRESULT RegisterSink(ICallFrameEvents* psink) mut => VT.[Friend]RegisterSink(&this, psink);

	public HRESULT GetRegisteredSink(ICallFrameEvents** ppsink) mut => VT.[Friend]GetRegisteredSink(&this, ppsink);
}

[CRepr]struct ICallFrameEvents : IUnknown
{
	public new const Guid IID = .(0xfd5e0843, 0xfc91, 0x11d0, 0x97, 0xd7, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICallFrame* pFrame) OnCall;
	}


	public HRESULT OnCall(ICallFrame* pFrame) mut => VT.[Friend]OnCall(&this, pFrame);
}

[CRepr]struct ICallUnmarshal : IUnknown
{
	public new const Guid IID = .(0x5333b003, 0x2e42, 0x11d2, 0xb8, 0x9d, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iMethod, void* pBuffer, uint32 cbBuffer, BOOL fForceBufferCopy, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext, uint32* pcbUnmarshalled, ICallFrame** ppFrame) Unmarshal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iMethod, void* pBuffer, uint32 cbBuffer, uint32 ibFirstRelease, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext) ReleaseMarshalData;
	}


	public HRESULT Unmarshal(uint32 iMethod, void* pBuffer, uint32 cbBuffer, BOOL fForceBufferCopy, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext, uint32* pcbUnmarshalled, ICallFrame** ppFrame) mut => VT.[Friend]Unmarshal(&this, iMethod, pBuffer, cbBuffer, fForceBufferCopy, dataRep, pcontext, pcbUnmarshalled, ppFrame);

	public HRESULT ReleaseMarshalData(uint32 iMethod, void* pBuffer, uint32 cbBuffer, uint32 ibFirstRelease, uint32 dataRep, CALLFRAME_MARSHALCONTEXT* pcontext) mut => VT.[Friend]ReleaseMarshalData(&this, iMethod, pBuffer, cbBuffer, ibFirstRelease, dataRep, pcontext);
}

[CRepr]struct ICallFrameWalker : IUnknown
{
	public new const Guid IID = .(0x08b23919, 0x392d, 0x11d2, 0xb8, 0xa4, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, void** ppvInterface, BOOL fIn, BOOL fOut) OnWalkInterface;
	}


	public HRESULT OnWalkInterface(in Guid iid, void** ppvInterface, BOOL fIn, BOOL fOut) mut => VT.[Friend]OnWalkInterface(&this, iid, ppvInterface, fIn, fOut);
}

[CRepr]struct IInterfaceRelated : IUnknown
{
	public new const Guid IID = .(0xd1fb5a79, 0x7706, 0x11d1, 0xad, 0xba, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid) SetIID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* piid) GetIID;
	}


	public HRESULT SetIID(in Guid iid) mut => VT.[Friend]SetIID(&this, iid);

	public HRESULT GetIID(Guid* piid) mut => VT.[Friend]GetIID(&this, piid);
}

#endregion

#region Functions
public static
{
	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetInterceptor(in Guid iidIntercepted, IUnknown* punkOuter, in Guid iid, void** ppv);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetInterceptorFromTypeInfo(in Guid iidIntercepted, IUnknown* punkOuter, ITypeInfo* typeInfo, in Guid iid, void** ppv);

}
#endregion
