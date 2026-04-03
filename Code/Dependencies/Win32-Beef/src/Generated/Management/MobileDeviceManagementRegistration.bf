using Win32.Foundation;
using System;

namespace Win32.Management.MobileDeviceManagementRegistration;

#region Constants
public static
{
	public const HRESULT MENROLL_E_DEVICE_MESSAGE_FORMAT_ERROR = -2145910783;
	public const HRESULT MENROLL_E_DEVICE_AUTHENTICATION_ERROR = -2145910782;
	public const HRESULT MENROLL_E_DEVICE_AUTHORIZATION_ERROR = -2145910781;
	public const HRESULT MENROLL_E_DEVICE_CERTIFICATEREQUEST_ERROR = -2145910780;
	public const HRESULT MENROLL_E_DEVICE_CONFIGMGRSERVER_ERROR = -2145910779;
	public const HRESULT MENROLL_E_DEVICE_INTERNALSERVICE_ERROR = -2145910778;
	public const HRESULT MENROLL_E_DEVICE_INVALIDSECURITY_ERROR = -2145910777;
	public const HRESULT MENROLL_E_DEVICE_UNKNOWN_ERROR = -2145910776;
	public const HRESULT MENROLL_E_ENROLLMENT_IN_PROGRESS = -2145910775;
	public const HRESULT MENROLL_E_DEVICE_ALREADY_ENROLLED = -2145910774;
	public const HRESULT MENROLL_E_DISCOVERY_SEC_CERT_DATE_INVALID = -2145910771;
	public const HRESULT MENROLL_E_PASSWORD_NEEDED = -2145910770;
	public const HRESULT MENROLL_E_WAB_ERROR = -2145910769;
	public const HRESULT MENROLL_E_CONNECTIVITY = -2145910768;
	public const HRESULT MENROLL_E_INVALIDSSLCERT = -2145910766;
	public const HRESULT MENROLL_E_DEVICEAPREACHED = -2145910765;
	public const HRESULT MENROLL_E_DEVICENOTSUPPORTED = -2145910764;
	public const HRESULT MENROLL_E_NOT_SUPPORTED = -2145910763;
	public const HRESULT MENROLL_E_NOTELIGIBLETORENEW = -2145910762;
	public const HRESULT MENROLL_E_INMAINTENANCE = -2145910761;
	public const HRESULT MENROLL_E_USER_LICENSE = -2145910760;
	public const HRESULT MENROLL_E_ENROLLMENTDATAINVALID = -2145910759;
	public const HRESULT MENROLL_E_INSECUREREDIRECT = -2145910758;
	public const HRESULT MENROLL_E_PLATFORM_WRONG_STATE = -2145910757;
	public const HRESULT MENROLL_E_PLATFORM_LICENSE_ERROR = -2145910756;
	public const HRESULT MENROLL_E_PLATFORM_UNKNOWN_ERROR = -2145910755;
	public const HRESULT MENROLL_E_PROV_CSP_CERTSTORE = -2145910754;
	public const HRESULT MENROLL_E_PROV_CSP_W7 = -2145910753;
	public const HRESULT MENROLL_E_PROV_CSP_DMCLIENT = -2145910752;
	public const HRESULT MENROLL_E_PROV_CSP_PFW = -2145910751;
	public const HRESULT MENROLL_E_PROV_CSP_MISC = -2145910750;
	public const HRESULT MENROLL_E_PROV_UNKNOWN = -2145910749;
	public const HRESULT MENROLL_E_PROV_SSLCERTNOTFOUND = -2145910748;
	public const HRESULT MENROLL_E_PROV_CSP_APPMGMT = -2145910747;
	public const HRESULT MENROLL_E_DEVICE_MANAGEMENT_BLOCKED = -2145910746;
	public const HRESULT MENROLL_E_CERTPOLICY_PRIVATEKEYCREATION_FAILED = -2145910745;
	public const HRESULT MENROLL_E_CERTAUTH_FAILED_TO_FIND_CERT = -2145910744;
	public const HRESULT MENROLL_E_EMPTY_MESSAGE = -2145910743;
	public const HRESULT MENROLL_E_USER_CANCELLED = -2145910736;
	public const HRESULT MENROLL_E_MDM_NOT_CONFIGURED = -2145910735;
	public const uint32 MDM_REGISTRATION_FACILITY_CODE = 25;
	public const uint32 DEVICE_ENROLLER_FACILITY_CODE = 24;
	public const HRESULT MREGISTER_E_DEVICE_MESSAGE_FORMAT_ERROR = -2145845247;
	public const HRESULT MREGISTER_E_DEVICE_AUTHENTICATION_ERROR = -2145845246;
	public const HRESULT MREGISTER_E_DEVICE_AUTHORIZATION_ERROR = -2145845245;
	public const HRESULT MREGISTER_E_DEVICE_CERTIFCATEREQUEST_ERROR = -2145845244;
	public const HRESULT MENROLL_E_DEVICE_CERTIFCATEREQUEST_ERROR = -2145910780;
	public const HRESULT MREGISTER_E_DEVICE_CONFIGMGRSERVER_ERROR = -2145845243;
	public const HRESULT MREGISTER_E_DEVICE_INTERNALSERVICE_ERROR = -2145845242;
	public const HRESULT MREGISTER_E_DEVICE_INVALIDSECURITY_ERROR = -2145845241;
	public const HRESULT MREGISTER_E_DEVICE_UNKNOWN_ERROR = -2145845240;
	public const HRESULT MREGISTER_E_REGISTRATION_IN_PROGRESS = -2145845239;
	public const HRESULT MREGISTER_E_DEVICE_ALREADY_REGISTERED = -2145845238;
	public const HRESULT MREGISTER_E_DEVICE_NOT_REGISTERED = -2145845237;
	public const HRESULT MENROLL_E_DEVICE_NOT_ENROLLED = -2145910773;
	public const HRESULT MREGISTER_E_DISCOVERY_REDIRECTED = -2145845236;
	public const HRESULT MREGISTER_E_DEVICE_NOT_AD_REGISTERED_ERROR = -2145845235;
	public const HRESULT MREGISTER_E_DISCOVERY_FAILED = -2145845234;
	public const HRESULT MENROLL_E_DEVICECAPREACHED = -2145910765;
	public const HRESULT MENROLL_E_NOTSUPPORTED = -2145910763;
	public const HRESULT MENROLL_E_USERLICENSE = -2145910760;
	public const HRESULT MENROLL_E_USER_CANCELED = -2145910742;
	public const uint32 DEVICEREGISTRATIONTYPE_MDM_ONLY = 0;
	public const uint32 DEVICEREGISTRATIONTYPE_MAM = 5;
	public const uint32 DEVICEREGISTRATIONTYPE_MDM_DEVICEWIDE_WITH_AAD = 6;
	public const uint32 DEVICEREGISTRATIONTYPE_MDM_USERSPECIFIC_WITH_AAD = 13;
}
#endregion

#region Enums

[AllowDuplicates]
public enum REGISTRATION_INFORMATION_CLASS : int32
{
	DeviceRegistrationBasicInfo = 1,
	MaxDeviceInfoClass = 2,
}

#endregion


#region Structs
[CRepr]
public struct MANAGEMENT_SERVICE_INFO
{
	public PWSTR pszMDMServiceUri;
	public PWSTR pszAuthenticationUri;
}

[CRepr]
public struct MANAGEMENT_REGISTRATION_INFO
{
	public BOOL fDeviceRegisteredWithManagement;
	public uint32 dwDeviceRegistionKind;
	public PWSTR pszUPN;
	public PWSTR pszMDMServiceUri;
}

#endregion

#region Functions
public static
{
	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDeviceRegistrationInfo(REGISTRATION_INFORMATION_CLASS DeviceInformationClass, void** ppDeviceRegistrationInfo);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsDeviceRegisteredWithManagement(BOOL* pfIsDeviceRegisteredWithManagement, uint32 cchUPN, char16* pszUPN);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsManagementRegistrationAllowed(BOOL* pfIsManagementRegistrationAllowed);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsMdmUxWithoutAadAllowed(BOOL* isEnrollmentAllowed);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetManagedExternally(BOOL IsManagedExternally);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DiscoverManagementService(PWSTR pszUPN, MANAGEMENT_SERVICE_INFO** ppMgmtInfo);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterDeviceWithManagementUsingAADCredentials(HANDLE UserToken);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterDeviceWithManagementUsingAADDeviceCredentials();

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterDeviceWithManagementUsingAADDeviceCredentials2(PWSTR MDMApplicationID);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterDeviceWithManagement(PWSTR pszUPN, PWSTR ppszMDMServiceUri, PWSTR ppzsAccessToken);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnregisterDeviceWithManagement(PWSTR enrollmentID);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDeviceManagementConfigInfo(PWSTR providerID, uint32* configStringBufferLength, char16* configString);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetDeviceManagementConfigInfo(PWSTR providerID, PWSTR configString);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetManagementAppHyperlink(uint32 cchHyperlink, char16* pszHyperlink);

	[Import("MDMRegistration.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DiscoverManagementServiceEx(PWSTR pszUPN, PWSTR pszDiscoveryServiceCandidate, MANAGEMENT_SERVICE_INFO** ppMgmtInfo);

	[Import("MDMLocalManagement.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterDeviceWithLocalManagement(BOOL* alreadyRegistered);

	[Import("MDMLocalManagement.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ApplyLocalManagementSyncML(PWSTR syncMLRequest, PWSTR* syncMLResult);

	[Import("MDMLocalManagement.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnregisterDeviceWithLocalManagement();

}
#endregion
