using Win32.Foundation;
using Win32.Security;
using Win32.Security.Authorization.UI;
using Win32.UI.Controls;
using System;

namespace Win32.Security.DirectoryServices;

#region Constants
public static
{
	public const uint32 DSSI_READ_ONLY = 1;
	public const uint32 DSSI_NO_ACCESS_CHECK = 2;
	public const uint32 DSSI_NO_EDIT_SACL = 4;
	public const uint32 DSSI_NO_EDIT_OWNER = 8;
	public const uint32 DSSI_IS_ROOT = 16;
	public const uint32 DSSI_NO_FILTER = 32;
	public const uint32 DSSI_NO_READONLY_MESSAGE = 64;
}
#endregion
#region Function Pointers
public function HRESULT PFNREADOBJECTSECURITY(PWSTR param0, uint32 param1, PSECURITY_DESCRIPTOR* param2, LPARAM param3);

public function HRESULT PFNWRITEOBJECTSECURITY(PWSTR param0, uint32 param1, PSECURITY_DESCRIPTOR param2, LPARAM param3);

public function HRESULT PFNDSCREATEISECINFO(PWSTR param0, PWSTR param1, uint32 param2, ISecurityInformation** param3, PFNREADOBJECTSECURITY param4, PFNWRITEOBJECTSECURITY param5, LPARAM param6);

public function HRESULT PFNDSCREATEISECINFOEX(PWSTR param0, PWSTR param1, PWSTR param2, PWSTR param3, PWSTR param4, uint32 param5, ISecurityInformation** param6, PFNREADOBJECTSECURITY param7, PFNWRITEOBJECTSECURITY param8, LPARAM param9);

public function HRESULT PFNDSCREATESECPAGE(PWSTR param0, PWSTR param1, uint32 param2, HPROPSHEETPAGE* param3, PFNREADOBJECTSECURITY param4, PFNWRITEOBJECTSECURITY param5, LPARAM param6);

public function HRESULT PFNDSEDITSECURITY(HWND param0, PWSTR param1, PWSTR param2, uint32 param3, PWSTR param4, PFNREADOBJECTSECURITY param5, PFNWRITEOBJECTSECURITY param6, LPARAM param7);

#endregion

#region Functions
public static
{
	[Import("DSSEC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DSCreateISecurityInfoObject(PWSTR pwszObjectPath, PWSTR pwszObjectClass, uint32 dwFlags, ISecurityInformation** ppSI, PFNREADOBJECTSECURITY pfnReadSD, PFNWRITEOBJECTSECURITY pfnWriteSD, LPARAM lpContext);

	[Import("DSSEC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DSCreateISecurityInfoObjectEx(PWSTR pwszObjectPath, PWSTR pwszObjectClass, PWSTR pwszServer, PWSTR pwszUserName, PWSTR pwszPassword, uint32 dwFlags, ISecurityInformation** ppSI, PFNREADOBJECTSECURITY pfnReadSD, PFNWRITEOBJECTSECURITY pfnWriteSD, LPARAM lpContext);

	[Import("DSSEC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DSCreateSecurityPage(PWSTR pwszObjectPath, PWSTR pwszObjectClass, uint32 dwFlags, HPROPSHEETPAGE* phPage, PFNREADOBJECTSECURITY pfnReadSD, PFNWRITEOBJECTSECURITY pfnWriteSD, LPARAM lpContext);

	[Import("DSSEC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DSEditSecurity(HWND hwndOwner, PWSTR pwszObjectPath, PWSTR pwszObjectClass, uint32 dwFlags, PWSTR pwszCaption, PFNREADOBJECTSECURITY pfnReadSD, PFNWRITEOBJECTSECURITY pfnWriteSD, LPARAM lpContext);

}
#endregion
