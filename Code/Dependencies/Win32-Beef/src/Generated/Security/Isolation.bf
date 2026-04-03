using Win32.Foundation;
using Win32.System.Com;
using Win32.Security;
using Win32.System.Registry;
using System;

namespace Win32.Security.Isolation;

#region Structs
[CRepr]
public struct IsolatedAppLauncherTelemetryParameters
{
	public BOOL EnableForLaunch;
	public Guid CorrelationGUID;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_IsolatedAppLauncher = .(0xbc812430, 0xe75e, 0x4fd1, 0x96, 0x41, 0x1f, 0x9f, 0x1e, 0x2d, 0x9a, 0x1f);


}
#endregion

#region COM Types
[CRepr]struct IIsolatedAppLauncher : IUnknown
{
	public new const Guid IID = .(0xf686878f, 0x7b42, 0x4cc4, 0x96, 0xfb, 0xf4, 0xf3, 0xb6, 0xe3, 0xd2, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR appUserModelId, PWSTR arguments, IsolatedAppLauncherTelemetryParameters* telemetryParameters) Launch;
	}


	public HRESULT Launch(PWSTR appUserModelId, PWSTR arguments, IsolatedAppLauncherTelemetryParameters* telemetryParameters) mut => VT.[Friend]Launch(&this, appUserModelId, arguments, telemetryParameters);
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAppContainerNamedObjectPath(HANDLE Token, PSID AppContainerSid, uint32 ObjectPathLength, char16* ObjectPath, uint32* ReturnLength);

	[Import("api-ms-win-security-isolatedcontainer-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsProcessInWDAGContainer(void* Reserved, BOOL* isProcessInWDAGContainer);

	[Import("api-ms-win-security-isolatedcontainer-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsProcessInIsolatedContainer(BOOL* isProcessInIsolatedContainer);

	[Import("IsolatedWindowsEnvironmentUtils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsProcessInIsolatedWindowsEnvironment(BOOL* isProcessInIsolatedWindowsEnvironment);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateAppContainerProfile(PWSTR pszAppContainerName, PWSTR pszDisplayName, PWSTR pszDescription, SID_AND_ATTRIBUTES* pCapabilities, uint32 dwCapabilityCount, PSID* ppSidAppContainerSid);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeleteAppContainerProfile(PWSTR pszAppContainerName);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetAppContainerRegistryLocation(uint32 desiredAccess, HKEY* phAppContainerKey);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetAppContainerFolderPath(PWSTR pszAppContainerSid, PWSTR* ppszPath);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName(PSID psidAppContainerSid, PWSTR pszRestrictedAppContainerName, PSID* ppsidRestrictedAppContainerSid);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeriveAppContainerSidFromAppContainerName(PWSTR pszAppContainerName, PSID* ppsidAppContainerSid);

}
#endregion
