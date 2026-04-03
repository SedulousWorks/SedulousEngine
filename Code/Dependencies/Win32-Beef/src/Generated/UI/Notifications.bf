using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.UI.Notifications;

#region Structs
[CRepr]
public struct NOTIFICATION_USER_INPUT_DATA
{
	public PWSTR Key;
	public PWSTR Value;
}

#endregion

#region COM Types
[CRepr]struct INotificationActivationCallback : IUnknown
{
	public new const Guid IID = .(0x53e31837, 0x6600, 0x4a81, 0x93, 0x95, 0x75, 0xcf, 0xfe, 0x74, 0x6f, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR appUserModelId, PWSTR invokedArgs, NOTIFICATION_USER_INPUT_DATA* data, uint32 count) Activate;
	}


	public HRESULT Activate(PWSTR appUserModelId, PWSTR invokedArgs, NOTIFICATION_USER_INPUT_DATA* data, uint32 count) mut => VT.[Friend]Activate(&this, appUserModelId, invokedArgs, data, count);
}

#endregion
