using Win32.Foundation;
using System;

namespace Win32.System.DeveloperLicensing;

#region Functions
public static
{
	[Import("WSClient.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CheckDeveloperLicense(FILETIME* pExpiration);

	[Import("WSClient.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AcquireDeveloperLicense(HWND hwndParent, FILETIME* pExpiration);

	[Import("WSClient.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RemoveDeveloperLicense(HWND hwndParent);

}
#endregion
