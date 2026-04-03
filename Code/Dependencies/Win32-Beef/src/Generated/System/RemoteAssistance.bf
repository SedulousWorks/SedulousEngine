using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.RemoteAssistance;

#region Constants
public static
{
	public const uint32 DISPID_EVENT_ON_STATE_CHANGED = 5;
	public const uint32 DISPID_EVENT_ON_TERMINATION = 6;
	public const uint32 DISPID_EVENT_ON_CONTEXT_DATA = 7;
	public const uint32 DISPID_EVENT_ON_SEND_ERROR = 8;
}
#endregion

#region Enums

[AllowDuplicates]
public enum RENDEZVOUS_SESSION_STATE : int32
{
	RSS_UNKNOWN = 0,
	RSS_READY = 1,
	RSS_INVITATION = 2,
	RSS_ACCEPTED = 3,
	RSS_CONNECTED = 4,
	RSS_CANCELLED = 5,
	RSS_DECLINED = 6,
	RSS_TERMINATED = 7,
}


[AllowDuplicates]
public enum RENDEZVOUS_SESSION_FLAGS : int32
{
	RSF_NONE = 0,
	RSF_INVITER = 1,
	RSF_INVITEE = 2,
	RSF_ORIGINAL_INVITER = 4,
	RSF_REMOTE_LEGACYSESSION = 8,
	RSF_REMOTE_WIN7SESSION = 16,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_RendezvousApplication = .(0x0b7e019a, 0xb5de, 0x47fa, 0x89, 0x66, 0x90, 0x82, 0xf8, 0x2f, 0xb1, 0x92);


}
#endregion

#region COM Types
[CRepr]struct IRendezvousSession : IUnknown
{
	public new const Guid IID = .(0x9ba4b1dd, 0x8b0c, 0x48b7, 0x9e, 0x7c, 0x2f, 0x25, 0x85, 0x7c, 0x8d, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RENDEZVOUS_SESSION_STATE* pSessionState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrUserName) get_RemoteUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrData) SendContextData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, BSTR bstrAppData) Terminate;
	}


	public HRESULT get_State(RENDEZVOUS_SESSION_STATE* pSessionState) mut => VT.[Friend]get_State(&this, pSessionState);

	public HRESULT get_RemoteUser(BSTR* bstrUserName) mut => VT.[Friend]get_RemoteUser(&this, bstrUserName);

	public HRESULT get_Flags(int32* pFlags) mut => VT.[Friend]get_Flags(&this, pFlags);

	public HRESULT SendContextData(BSTR bstrData) mut => VT.[Friend]SendContextData(&this, bstrData);

	public HRESULT Terminate(HRESULT hr, BSTR bstrAppData) mut => VT.[Friend]Terminate(&this, hr, bstrAppData);
}

[CRepr]struct DRendezvousSessionEvents : IDispatch
{
	public new const Guid IID = .(0x3fa19cf8, 0x64c4, 0x4f53, 0xae, 0x60, 0x63, 0x5b, 0x38, 0x06, 0xec, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IRendezvousApplication : IUnknown
{
	public new const Guid IID = .(0x4f4d070b, 0xa275, 0x49fb, 0xb1, 0x0d, 0x8e, 0xc2, 0x63, 0x87, 0xb5, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pRendezvousSession) SetRendezvousSession;
	}


	public HRESULT SetRendezvousSession(IUnknown* pRendezvousSession) mut => VT.[Friend]SetRendezvousSession(&this, pRendezvousSession);
}

#endregion
