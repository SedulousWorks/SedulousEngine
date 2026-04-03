using Win32.Networking.WinSock;
using Win32.Foundation;
using System;

namespace Win32.System.UserAccessLogging;

#region Structs
[CRepr]
public struct UAL_DATA_BLOB
{
	public uint32 Size;
	public Guid RoleGuid;
	public Guid TenantId;
	public SOCKADDR_STORAGE Address;
	public char16[260] UserName;
}

#endregion

#region Functions
public static
{
	[Import("ualapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UalStart(UAL_DATA_BLOB* Data);

	[Import("ualapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UalStop(UAL_DATA_BLOB* Data);

	[Import("ualapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UalInstrument(UAL_DATA_BLOB* Data);

	[Import("ualapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UalRegisterProduct(PWSTR wszProductName, PWSTR wszRoleName, PWSTR wszGuid);

}
#endregion
