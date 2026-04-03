using Win32.Foundation;
using System;

namespace Win32.Security.LicenseProtection;

#region Enums

[AllowDuplicates]
public enum LicenseProtectionStatus : int32
{
	Success = 0,
	LicenseKeyNotFound = 1,
	LicenseKeyUnprotected = 2,
	LicenseKeyCorrupted = 3,
	LicenseKeyAlreadyExists = 4,
}

#endregion


#region Functions
public static
{
	[Import("licenseprotection.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterLicenseKeyWithExpiration(PWSTR licenseKey, uint32 validityInDays, LicenseProtectionStatus* status);

	[Import("licenseprotection.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ValidateLicenseKeyProtection(PWSTR licenseKey, FILETIME* notValidBefore, FILETIME* notValidAfter, LicenseProtectionStatus* status);

}
#endregion
