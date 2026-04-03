using Win32.System.Com;
using Win32.Foundation;
using Win32.System.Ole;
using Win32.System.Registry;
using Win32.System.Wmi;
using Win32.UI.Controls;
using Win32.Security;
using Win32.UI.Shell;
using System;

namespace Win32.System.GroupPolicy;

#region Constants
public static
{
	public const uint32 GPM_USE_PDC = 0;
	public const uint32 GPM_USE_ANYDC = 1;
	public const uint32 GPM_DONOTUSE_W2KDC = 2;
	public const uint32 GPM_DONOT_VALIDATEDC = 1;
	public const uint32 GPM_MIGRATIONTABLE_ONLY = 1;
	public const uint32 GPM_PROCESS_SECURITY = 2;
	public const uint32 RSOP_NO_COMPUTER = 65536;
	public const uint32 RSOP_NO_USER = 131072;
	public const uint32 RSOP_PLANNING_ASSUME_SLOW_LINK = 1;
	public const uint32 RSOP_PLANNING_ASSUME_LOOPBACK_MERGE = 2;
	public const uint32 RSOP_PLANNING_ASSUME_LOOPBACK_REPLACE = 4;
	public const uint32 RSOP_PLANNING_ASSUME_USER_WQLFILTER_TRUE = 8;
	public const uint32 RSOP_PLANNING_ASSUME_COMP_WQLFILTER_TRUE = 16;
	public const uint32 PI_NOUI = 1;
	public const uint32 PI_APPLYPOLICY = 2;
	public const uint32 PT_TEMPORARY = 1;
	public const uint32 PT_ROAMING = 2;
	public const uint32 PT_MANDATORY = 4;
	public const uint32 PT_ROAMING_PREEXISTING = 8;
	public const uint32 RP_FORCE = 1;
	public const uint32 RP_SYNC = 2;
	public const uint32 GPC_BLOCK_POLICY = 1;
	public const uint32 GPO_FLAG_DISABLE = 1;
	public const uint32 GPO_FLAG_FORCE = 2;
	public const uint32 GPO_LIST_FLAG_MACHINE = 1;
	public const uint32 GPO_LIST_FLAG_SITEONLY = 2;
	public const uint32 GPO_LIST_FLAG_NO_WMIFILTERS = 4;
	public const uint32 GPO_LIST_FLAG_NO_SECURITYFILTERS = 8;
	public const String GP_DLLNAME = "DllName";
	public const String GP_ENABLEASYNCHRONOUSPROCESSING = "EnableAsynchronousProcessing";
	public const String GP_MAXNOGPOLISTCHANGESINTERVAL = "MaxNoGPOListChangesInterval";
	public const String GP_NOBACKGROUNDPOLICY = "NoBackgroundPolicy";
	public const String GP_NOGPOLISTCHANGES = "NoGPOListChanges";
	public const String GP_NOMACHINEPOLICY = "NoMachinePolicy";
	public const String GP_NOSLOWLINK = "NoSlowLink";
	public const String GP_NOTIFYLINKTRANSITION = "NotifyLinkTransition";
	public const String GP_NOUSERPOLICY = "NoUserPolicy";
	public const String GP_PERUSERLOCALSETTINGS = "PerUserLocalSettings";
	public const String GP_PROCESSGROUPPOLICY = "ProcessGroupPolicy";
	public const String GP_REQUIRESSUCCESSFULREGISTRY = "RequiresSuccessfulRegistry";
	public const uint32 GPO_INFO_FLAG_MACHINE = 1;
	public const uint32 GPO_INFO_FLAG_BACKGROUND = 16;
	public const uint32 GPO_INFO_FLAG_SLOWLINK = 32;
	public const uint32 GPO_INFO_FLAG_VERBOSE = 64;
	public const uint32 GPO_INFO_FLAG_NOCHANGES = 128;
	public const uint32 GPO_INFO_FLAG_LINKTRANSITION = 256;
	public const uint32 GPO_INFO_FLAG_LOGRSOP_TRANSITION = 512;
	public const uint32 GPO_INFO_FLAG_FORCED_REFRESH = 1024;
	public const uint32 GPO_INFO_FLAG_SAFEMODE_BOOT = 2048;
	public const uint32 GPO_INFO_FLAG_ASYNC_FOREGROUND = 4096;
	public const uint32 FLAG_NO_GPO_FILTER = 2147483648;
	public const uint32 FLAG_NO_CSE_INVOKE = 1073741824;
	public const uint32 FLAG_ASSUME_SLOW_LINK = 536870912;
	public const uint32 FLAG_LOOPBACK_MERGE = 268435456;
	public const uint32 FLAG_LOOPBACK_REPLACE = 134217728;
	public const uint32 FLAG_ASSUME_USER_WQLFILTER_TRUE = 67108864;
	public const uint32 FLAG_ASSUME_COMP_WQLFILTER_TRUE = 33554432;
	public const uint32 FLAG_PLANNING_MODE = 16777216;
	public const uint32 FLAG_NO_USER = 1;
	public const uint32 FLAG_NO_COMPUTER = 2;
	public const uint32 FLAG_FORCE_CREATENAMESPACE = 4;
	public const uint32 RSOP_USER_ACCESS_DENIED = 1;
	public const uint32 RSOP_COMPUTER_ACCESS_DENIED = 2;
	public const uint32 RSOP_TEMPNAMESPACE_EXISTS = 4;
	public const uint32 LOCALSTATE_ASSIGNED = 1;
	public const uint32 LOCALSTATE_PUBLISHED = 2;
	public const uint32 LOCALSTATE_UNINSTALL_UNMANAGED = 4;
	public const uint32 LOCALSTATE_POLICYREMOVE_ORPHAN = 8;
	public const uint32 LOCALSTATE_POLICYREMOVE_UNINSTALL = 16;
	public const uint32 LOCALSTATE_ORPHANED = 32;
	public const uint32 LOCALSTATE_UNINSTALLED = 64;
	public const uint32 MANAGED_APPS_USERAPPLICATIONS = 1;
	public const uint32 MANAGED_APPS_FROMCATEGORY = 2;
	public const uint32 MANAGED_APPS_INFOLEVEL_DEFAULT = 65536;
	public const uint32 MANAGED_APPTYPE_WINDOWSINSTALLER = 1;
	public const uint32 MANAGED_APPTYPE_SETUPEXE = 2;
	public const uint32 MANAGED_APPTYPE_UNSUPPORTED = 3;
	public const Guid CLSID_GPESnapIn = .(0x8fc0b734, 0xa0e1, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);
	public const Guid NODEID_Machine = .(0x8fc0b737, 0xa0e1, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);
	public const Guid NODEID_MachineSWSettings = .(0x8fc0b73a, 0xa0e1, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);
	public const Guid NODEID_User = .(0x8fc0b738, 0xa0e1, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);
	public const Guid NODEID_UserSWSettings = .(0x8fc0b73c, 0xa0e1, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);
	public const Guid CLSID_GroupPolicyObject = .(0xea502722, 0xa23d, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);
	public const Guid CLSID_RSOPSnapIn = .(0x6dc3804b, 0x7212, 0x458d, 0xad, 0xb0, 0x9a, 0x07, 0xe2, 0xae, 0x1f, 0xa2);
	public const Guid NODEID_RSOPMachine = .(0xbd4c1a2e, 0x0b7a, 0x4a62, 0xa6, 0xb0, 0xc0, 0x57, 0x75, 0x39, 0xc9, 0x7e);
	public const Guid NODEID_RSOPMachineSWSettings = .(0x6a76273e, 0xeb8e, 0x45db, 0x94, 0xc5, 0x25, 0x66, 0x3a, 0x5f, 0x2c, 0x1a);
	public const Guid NODEID_RSOPUser = .(0xab87364f, 0x0cec, 0x4cd8, 0x9b, 0xf8, 0x89, 0x8f, 0x34, 0x62, 0x8f, 0xb8);
	public const Guid NODEID_RSOPUserSWSettings = .(0xe52c5ce3, 0xfd27, 0x4402, 0x84, 0xde, 0xd9, 0xa5, 0xf2, 0x85, 0x89, 0x10);
	public const uint32 GPO_SECTION_ROOT = 0;
	public const uint32 GPO_SECTION_USER = 1;
	public const uint32 GPO_SECTION_MACHINE = 2;
	public const uint32 GPO_OPEN_LOAD_REGISTRY = 1;
	public const uint32 GPO_OPEN_READ_ONLY = 2;
	public const uint32 GPO_OPTION_DISABLE_USER = 1;
	public const uint32 GPO_OPTION_DISABLE_MACHINE = 2;
	public const uint32 RSOP_INFO_FLAG_DIAGNOSTIC_MODE = 1;
	public const uint32 GPO_BROWSE_DISABLENEW = 1;
	public const uint32 GPO_BROWSE_NOCOMPUTERS = 2;
	public const uint32 GPO_BROWSE_NODSGPOS = 4;
	public const uint32 GPO_BROWSE_OPENBUTTON = 8;
	public const uint32 GPO_BROWSE_INITTOALL = 16;
	public const uint32 GPO_BROWSE_NOUSERGPOS = 32;
	public const uint32 GPO_BROWSE_SENDAPPLYONEDIT = 64;
}
#endregion

#region TypeDefs
typealias CriticalPolicySectionHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum GPMRSOPMode : int32
{
	rsopUnknown = 0,
	rsopPlanning = 1,
	rsopLogging = 2,
}


[AllowDuplicates]
public enum GPMPermissionType : int32
{
	permGPOApply = 65536,
	permGPORead = 65792,
	permGPOEdit = 65793,
	permGPOEditSecurityAndDelete = 65794,
	permGPOCustom = 65795,
	permWMIFilterEdit = 131072,
	permWMIFilterFullControl = 131073,
	permWMIFilterCustom = 131074,
	permSOMLink = 1835008,
	permSOMLogging = 1573120,
	permSOMPlanning = 1573376,
	permSOMWMICreate = 1049344,
	permSOMWMIFullControl = 1049345,
	permSOMGPOCreate = 1049600,
	permStarterGPORead = 197888,
	permStarterGPOEdit = 197889,
	permStarterGPOFullControl = 197890,
	permStarterGPOCustom = 197891,
	permSOMStarterGPOCreate = 1049856,
}


[AllowDuplicates]
public enum GPMSearchProperty : int32
{
	gpoPermissions = 0,
	gpoEffectivePermissions = 1,
	gpoDisplayName = 2,
	gpoWMIFilter = 3,
	gpoID = 4,
	gpoComputerExtensions = 5,
	gpoUserExtensions = 6,
	somLinks = 7,
	gpoDomain = 8,
	backupMostRecent = 9,
	starterGPOPermissions = 10,
	starterGPOEffectivePermissions = 11,
	starterGPODisplayName = 12,
	starterGPOID = 13,
	starterGPODomain = 14,
}


[AllowDuplicates]
public enum GPMSearchOperation : int32
{
	opEquals = 0,
	opContains = 1,
	opNotContains = 2,
	opNotEquals = 3,
}


[AllowDuplicates]
public enum GPMReportType : int32
{
	repXML = 0,
	repHTML = 1,
	repInfraXML = 2,
	repInfraRefreshXML = 3,
	repClientHealthXML = 4,
	repClientHealthRefreshXML = 5,
}


[AllowDuplicates]
public enum GPMEntryType : int32
{
	typeUser = 0,
	typeComputer = 1,
	typeLocalGroup = 2,
	typeGlobalGroup = 3,
	typeUniversalGroup = 4,
	typeUNCPath = 5,
	typeUnknown = 6,
}


[AllowDuplicates]
public enum GPMDestinationOption : int32
{
	opDestinationSameAsSource = 0,
	opDestinationNone = 1,
	opDestinationByRelativeName = 2,
	opDestinationSet = 3,
}


[AllowDuplicates]
public enum GPMReportingOptions : int32
{
	opReportLegacy = 0,
	opReportComments = 1,
}


[AllowDuplicates]
public enum GPMSOMType : int32
{
	somSite = 0,
	somDomain = 1,
	somOU = 2,
}


[AllowDuplicates]
public enum GPMBackupType : int32
{
	typeGPO = 0,
	typeStarterGPO = 1,
}


[AllowDuplicates]
public enum GPMStarterGPOType : int32
{
	typeSystem = 0,
	typeCustom = 1,
}


[AllowDuplicates]
public enum GPO_LINK : int32
{
	GPLinkUnknown = 0,
	GPLinkMachine = 1,
	GPLinkSite = 2,
	GPLinkDomain = 3,
	GPLinkOrganizationalUnit = 4,
}


[AllowDuplicates]
public enum SETTINGSTATUS : int32
{
	RSOPUnspecified = 0,
	RSOPApplied = 1,
	RSOPIgnored = 2,
	RSOPFailed = 3,
	RSOPSubsettingFailed = 4,
}


[AllowDuplicates]
public enum INSTALLSPECTYPE : int32
{
	APPNAME = 1,
	FILEEXT = 2,
	PROGID = 3,
	COMCLASS = 4,
}


[AllowDuplicates]
public enum APPSTATE : int32
{
	ABSENT = 0,
	ASSIGNED = 1,
	PUBLISHED = 2,
}


[AllowDuplicates]
public enum GROUP_POLICY_OBJECT_TYPE : int32
{
	GPOTypeLocal = 0,
	GPOTypeRemote = 1,
	GPOTypeDS = 2,
	GPOTypeLocalUser = 3,
	GPOTypeLocalGroup = 4,
}


[AllowDuplicates]
public enum GROUP_POLICY_HINT_TYPE : int32
{
	GPHintUnknown = 0,
	GPHintMachine = 1,
	GPHintSite = 2,
	GPHintDomain = 3,
	GPHintOrganizationalUnit = 4,
}

#endregion

#region Function Pointers
public function uint32 PFNSTATUSMESSAGECALLBACK(BOOL bVerbose, PWSTR lpMessage);

public function uint32 PFNPROCESSGROUPPOLICY(uint32 dwFlags, HANDLE hToken, HKEY hKeyRoot, GROUP_POLICY_OBJECTA* pDeletedGPOList, GROUP_POLICY_OBJECTA* pChangedGPOList, uint pHandle, BOOL* pbAbort, PFNSTATUSMESSAGECALLBACK pStatusCallback);

public function uint32 PFNPROCESSGROUPPOLICYEX(uint32 dwFlags, HANDLE hToken, HKEY hKeyRoot, GROUP_POLICY_OBJECTA* pDeletedGPOList, GROUP_POLICY_OBJECTA* pChangedGPOList, uint pHandle, BOOL* pbAbort, PFNSTATUSMESSAGECALLBACK pStatusCallback, IWbemServices* pWbemServices, HRESULT* pRsopStatus);

public function uint32 PFNGENERATEGROUPPOLICY(uint32 dwFlags, BOOL* pbAbort, PWSTR pwszSite, RSOP_TARGET* pComputerTarget, RSOP_TARGET* pUserTarget);

#endregion

#region Structs
[CRepr]
public struct GROUP_POLICY_OBJECTA
{
	public uint32 dwOptions;
	public uint32 dwVersion;
	public PSTR lpDSPath;
	public PSTR lpFileSysPath;
	public PSTR lpDisplayName;
	public CHAR[50] szGPOName;
	public GPO_LINK GPOLink;
	public LPARAM lParam;
	public GROUP_POLICY_OBJECTA* pNext;
	public GROUP_POLICY_OBJECTA* pPrev;
	public PSTR lpExtensions;
	public LPARAM lParam2;
	public PSTR lpLink;
}

[CRepr]
public struct GROUP_POLICY_OBJECTW
{
	public uint32 dwOptions;
	public uint32 dwVersion;
	public PWSTR lpDSPath;
	public PWSTR lpFileSysPath;
	public PWSTR lpDisplayName;
	public char16[50] szGPOName;
	public GPO_LINK GPOLink;
	public LPARAM lParam;
	public GROUP_POLICY_OBJECTW* pNext;
	public GROUP_POLICY_OBJECTW* pPrev;
	public PWSTR lpExtensions;
	public LPARAM lParam2;
	public PWSTR lpLink;
}

[CRepr]
public struct RSOP_TARGET
{
	public PWSTR pwszAccountName;
	public PWSTR pwszNewSOM;
	public SAFEARRAY* psaSecurityGroups;
	public void* pRsopToken;
	public GROUP_POLICY_OBJECTA* pGPOList;
	public IWbemServices* pWbemServices;
}

[CRepr]
public struct POLICYSETTINGSTATUSINFO
{
	public PWSTR szKey;
	public PWSTR szEventSource;
	public PWSTR szEventLogName;
	public uint32 dwEventID;
	public uint32 dwErrorCode;
	public SETTINGSTATUS status;
	public SYSTEMTIME timeLogged;
}

[CRepr, Union]
public struct INSTALLSPEC
{
	[CRepr]
	public struct _AppName_e__Struct
	{
		public PWSTR Name;
		public Guid GPOId;
	}
	[CRepr]
	public struct _COMClass_e__Struct
	{
		public Guid Clsid;
		public uint32 ClsCtx;
	}
	public _AppName_e__Struct AppName;
	public PWSTR FileExt;
	public PWSTR ProgId;
	public _COMClass_e__Struct COMClass;
}

[CRepr]
public struct INSTALLDATA
{
	public INSTALLSPECTYPE Type;
	public INSTALLSPEC Spec;
}

[CRepr]
public struct LOCALMANAGEDAPPLICATION
{
	public PWSTR pszDeploymentName;
	public PWSTR pszPolicyName;
	public PWSTR pszProductId;
	public uint32 dwState;
}

[CRepr]
public struct MANAGEDAPPLICATION
{
	public PWSTR pszPackageName;
	public PWSTR pszPublisher;
	public uint32 dwVersionHi;
	public uint32 dwVersionLo;
	public uint32 dwRevision;
	public Guid GpoId;
	public PWSTR pszPolicyName;
	public Guid ProductId;
	public uint16 Language;
	public PWSTR pszOwner;
	public PWSTR pszCompany;
	public PWSTR pszComments;
	public PWSTR pszContact;
	public PWSTR pszSupportUrl;
	public uint32 dwPathType;
	public BOOL bInstalled;
}

[CRepr]
public struct GPOBROWSEINFO
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public HWND hwndOwner;
	public PWSTR lpTitle;
	public PWSTR lpInitialOU;
	public PWSTR lpDSPath;
	public uint32 dwDSPathSize;
	public PWSTR lpName;
	public uint32 dwNameSize;
	public GROUP_POLICY_OBJECT_TYPE gpoType;
	public GROUP_POLICY_HINT_TYPE gpoHint;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_GPM = .(0xf5694708, 0x88fe, 0x4b35, 0xba, 0xbf, 0xe5, 0x61, 0x62, 0xd5, 0xfb, 0xc8);


	public const Guid CLSID_GPMDomain = .(0x710901be, 0x1050, 0x4cb1, 0x83, 0x8a, 0xc5, 0xcf, 0xf2, 0x59, 0xe1, 0x83);


	public const Guid CLSID_GPMSitesContainer = .(0x229f5c42, 0x852c, 0x4b30, 0x94, 0x5f, 0xc5, 0x22, 0xbe, 0x9b, 0xd3, 0x86);


	public const Guid CLSID_GPMBackupDir = .(0xfce4a59d, 0x0f21, 0x4afa, 0xb8, 0x59, 0xe6, 0xd0, 0xc6, 0x2c, 0xd1, 0x0c);


	public const Guid CLSID_GPMSOM = .(0x32d93fac, 0x450e, 0x44cf, 0x82, 0x9c, 0x8b, 0x22, 0xff, 0x6b, 0xda, 0xe1);


	public const Guid CLSID_GPMSearchCriteria = .(0x17aaca26, 0x5ce0, 0x44fa, 0x8c, 0xc0, 0x52, 0x59, 0xe6, 0x48, 0x35, 0x66);


	public const Guid CLSID_GPMPermission = .(0x5871a40a, 0xe9c0, 0x46ec, 0x91, 0x3e, 0x94, 0x4e, 0xf9, 0x22, 0x5a, 0x94);


	public const Guid CLSID_GPMSecurityInfo = .(0x547a5e8f, 0x9162, 0x4516, 0xa4, 0xdf, 0x9d, 0xdb, 0x96, 0x86, 0xd8, 0x46);


	public const Guid CLSID_GPMBackup = .(0xed1a54b8, 0x5efa, 0x482a, 0x93, 0xc0, 0x8a, 0xd8, 0x6f, 0x0d, 0x68, 0xc3);


	public const Guid CLSID_GPMBackupCollection = .(0xeb8f035b, 0x70db, 0x4a9f, 0x96, 0x76, 0x37, 0xc2, 0x59, 0x94, 0xe9, 0xdc);


	public const Guid CLSID_GPMSOMCollection = .(0x24c1f147, 0x3720, 0x4f5b, 0xa9, 0xc3, 0x06, 0xb4, 0xe4, 0xf9, 0x31, 0xd2);


	public const Guid CLSID_GPMWMIFilter = .(0x626745d8, 0x0dea, 0x4062, 0xbf, 0x60, 0xcf, 0xc5, 0xb1, 0xca, 0x12, 0x86);


	public const Guid CLSID_GPMWMIFilterCollection = .(0x74dc6d28, 0xe820, 0x47d6, 0xa0, 0xb8, 0xf0, 0x8d, 0x93, 0xd7, 0xfa, 0x33);


	public const Guid CLSID_GPMRSOP = .(0x489b0caf, 0x9ec2, 0x4eb7, 0x91, 0xf5, 0xb6, 0xf7, 0x1d, 0x43, 0xda, 0x8c);


	public const Guid CLSID_GPMGPO = .(0xd2ce2994, 0x59b5, 0x4064, 0xb5, 0x81, 0x4d, 0x68, 0x48, 0x6a, 0x16, 0xc4);


	public const Guid CLSID_GPMGPOCollection = .(0x7a057325, 0x832d, 0x4de3, 0xa4, 0x1f, 0xc7, 0x80, 0x43, 0x6a, 0x4e, 0x09);


	public const Guid CLSID_GPMGPOLink = .(0xc1df9880, 0x5303, 0x42c6, 0x8a, 0x3c, 0x04, 0x88, 0xe1, 0xbf, 0x73, 0x64);


	public const Guid CLSID_GPMGPOLinksCollection = .(0xf6ed581a, 0x49a5, 0x47e2, 0xb7, 0x71, 0xfd, 0x8d, 0xc0, 0x2b, 0x62, 0x59);


	public const Guid CLSID_GPMAsyncCancel = .(0x372796a9, 0x76ec, 0x479d, 0xad, 0x6c, 0x55, 0x63, 0x18, 0xed, 0x5f, 0x9d);


	public const Guid CLSID_GPMStatusMsgCollection = .(0x2824e4be, 0x4bcc, 0x4cac, 0x9e, 0x60, 0x0e, 0x3e, 0xd7, 0xf1, 0x24, 0x96);


	public const Guid CLSID_GPMStatusMessage = .(0x4b77cc94, 0xd255, 0x409b, 0xbc, 0x62, 0x37, 0x08, 0x81, 0x71, 0x5a, 0x19);


	public const Guid CLSID_GPMTrustee = .(0xc54a700d, 0x19b6, 0x4211, 0xbc, 0xb0, 0xe8, 0xe2, 0x47, 0x5e, 0x47, 0x1e);


	public const Guid CLSID_GPMClientSideExtension = .(0xc1a2e70e, 0x659c, 0x4b1a, 0x94, 0x0b, 0xf8, 0x8b, 0x0a, 0xf9, 0xc8, 0xa4);


	public const Guid CLSID_GPMCSECollection = .(0xcf92b828, 0x2d44, 0x4b61, 0xb1, 0x0a, 0xb3, 0x27, 0xaf, 0xd4, 0x2d, 0xa8);


	public const Guid CLSID_GPMConstants = .(0x3855e880, 0xcd9e, 0x4d0c, 0x9e, 0xaf, 0x15, 0x79, 0x28, 0x3a, 0x18, 0x88);


	public const Guid CLSID_GPMResult = .(0x92101ac0, 0x9287, 0x4206, 0xa3, 0xb2, 0x4b, 0xdb, 0x73, 0xd2, 0x25, 0xf6);


	public const Guid CLSID_GPMMapEntryCollection = .(0x0cf75d5b, 0xa3a1, 0x4c55, 0xb4, 0xfe, 0x9e, 0x14, 0x9c, 0x41, 0xf6, 0x6d);


	public const Guid CLSID_GPMMapEntry = .(0x8c975253, 0x5431, 0x4471, 0xb3, 0x5d, 0x06, 0x26, 0xc9, 0x28, 0x25, 0x8a);


	public const Guid CLSID_GPMMigrationTable = .(0x55af4043, 0x2a06, 0x4f72, 0xab, 0xef, 0x63, 0x1b, 0x44, 0x07, 0x9c, 0x76);


	public const Guid CLSID_GPMBackupDirEx = .(0xe8c0988a, 0xcf03, 0x4c5b, 0x8b, 0xe2, 0x2a, 0xa9, 0xad, 0x32, 0xaa, 0xda);


	public const Guid CLSID_GPMStarterGPOBackupCollection = .(0xe75ea59d, 0x1aeb, 0x4cb5, 0xa7, 0x8a, 0x28, 0x1d, 0xaa, 0x58, 0x24, 0x06);


	public const Guid CLSID_GPMStarterGPOBackup = .(0x389e400a, 0xd8ef, 0x455b, 0xa8, 0x61, 0x5f, 0x9c, 0xa3, 0x4a, 0x6a, 0x02);


	public const Guid CLSID_GPMTemplate = .(0xecf1d454, 0x71da, 0x4e2f, 0xa8, 0xc0, 0x81, 0x85, 0x46, 0x59, 0x11, 0xd9);


	public const Guid CLSID_GPMStarterGPOCollection = .(0x82f8aa8b, 0x49ba, 0x43b2, 0x95, 0x6e, 0x33, 0x97, 0xf9, 0xb9, 0x4c, 0x3a);


}
#endregion

#region COM Types
[CRepr]struct IGPM : IDispatch
{
	public new const Guid IID = .(0xf5fae809, 0x3bd6, 0x4da9, 0xa6, 0x5e, 0x17, 0x66, 0x5b, 0x41, 0xd7, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDomain, BSTR bstrDomainController, int32 lDCFlags, IGPMDomain** pIGPMDomain) GetDomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBackupDir, IGPMBackupDir** pIGPMBackupDir) GetBackupDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrForest, BSTR bstrDomain, BSTR bstrDomainController, int32 lDCFlags, IGPMSitesContainer** ppIGPMSitesContainer) GetSitesContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMRSOPMode gpmRSoPMode, BSTR bstrNamespace, int32 lFlags, IGPMRSOP** ppIGPMRSOP) GetRSOP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTrustee, GPMPermissionType perm, int16 bInheritable, IGPMPermission** ppPerm) CreatePermission;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria** ppIGPMSearchCriteria) CreateSearchCriteria;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTrustee, IGPMTrustee** ppIGPMTrustee) CreateTrustee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMCSECollection** ppIGPMCSECollection) GetClientSideExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMConstants** ppIGPMConstants) GetConstants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMigrationTablePath, IGPMMigrationTable** ppMigrationTable) GetMigrationTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMMigrationTable** ppMigrationTable) CreateMigrationTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmPath) InitializeReporting;
	}


	public HRESULT GetDomain(BSTR bstrDomain, BSTR bstrDomainController, int32 lDCFlags, IGPMDomain** pIGPMDomain) mut => VT.[Friend]GetDomain(&this, bstrDomain, bstrDomainController, lDCFlags, pIGPMDomain);

	public HRESULT GetBackupDir(BSTR bstrBackupDir, IGPMBackupDir** pIGPMBackupDir) mut => VT.[Friend]GetBackupDir(&this, bstrBackupDir, pIGPMBackupDir);

	public HRESULT GetSitesContainer(BSTR bstrForest, BSTR bstrDomain, BSTR bstrDomainController, int32 lDCFlags, IGPMSitesContainer** ppIGPMSitesContainer) mut => VT.[Friend]GetSitesContainer(&this, bstrForest, bstrDomain, bstrDomainController, lDCFlags, ppIGPMSitesContainer);

	public HRESULT GetRSOP(GPMRSOPMode gpmRSoPMode, BSTR bstrNamespace, int32 lFlags, IGPMRSOP** ppIGPMRSOP) mut => VT.[Friend]GetRSOP(&this, gpmRSoPMode, bstrNamespace, lFlags, ppIGPMRSOP);

	public HRESULT CreatePermission(BSTR bstrTrustee, GPMPermissionType perm, int16 bInheritable, IGPMPermission** ppPerm) mut => VT.[Friend]CreatePermission(&this, bstrTrustee, perm, bInheritable, ppPerm);

	public HRESULT CreateSearchCriteria(IGPMSearchCriteria** ppIGPMSearchCriteria) mut => VT.[Friend]CreateSearchCriteria(&this, ppIGPMSearchCriteria);

	public HRESULT CreateTrustee(BSTR bstrTrustee, IGPMTrustee** ppIGPMTrustee) mut => VT.[Friend]CreateTrustee(&this, bstrTrustee, ppIGPMTrustee);

	public HRESULT GetClientSideExtensions(IGPMCSECollection** ppIGPMCSECollection) mut => VT.[Friend]GetClientSideExtensions(&this, ppIGPMCSECollection);

	public HRESULT GetConstants(IGPMConstants** ppIGPMConstants) mut => VT.[Friend]GetConstants(&this, ppIGPMConstants);

	public HRESULT GetMigrationTable(BSTR bstrMigrationTablePath, IGPMMigrationTable** ppMigrationTable) mut => VT.[Friend]GetMigrationTable(&this, bstrMigrationTablePath, ppMigrationTable);

	public HRESULT CreateMigrationTable(IGPMMigrationTable** ppMigrationTable) mut => VT.[Friend]CreateMigrationTable(&this, ppMigrationTable);

	public HRESULT InitializeReporting(BSTR bstrAdmPath) mut => VT.[Friend]InitializeReporting(&this, bstrAdmPath);
}

[CRepr]struct IGPMDomain : IDispatch
{
	public new const Guid IID = .(0x6b21cc14, 0x5a00, 0x4f44, 0xa7, 0x38, 0xfe, 0xec, 0x8a, 0x94, 0xc7, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DomainController;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Domain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMGPO** ppNewGPO) CreateGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuid, IGPMGPO** ppGPO) GetGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, IGPMGPOCollection** ppIGPMGPOCollection) SearchGPOs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMBackup* pIGPMBackup, int32 lDCFlags, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) RestoreGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPath, IGPMSOM** ppSOM) GetSOM;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, IGPMSOMCollection** ppIGPMSOMCollection) SearchSOMs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPath, IGPMWMIFilter** ppWMIFilter) GetWMIFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, IGPMWMIFilterCollection** ppIGPMWMIFilterCollection) SearchWMIFilters;
	}


	public HRESULT get_DomainController(BSTR* pVal) mut => VT.[Friend]get_DomainController(&this, pVal);

	public HRESULT get_Domain(BSTR* pVal) mut => VT.[Friend]get_Domain(&this, pVal);

	public HRESULT CreateGPO(IGPMGPO** ppNewGPO) mut => VT.[Friend]CreateGPO(&this, ppNewGPO);

	public HRESULT GetGPO(BSTR bstrGuid, IGPMGPO** ppGPO) mut => VT.[Friend]GetGPO(&this, bstrGuid, ppGPO);

	public HRESULT SearchGPOs(IGPMSearchCriteria* pIGPMSearchCriteria, IGPMGPOCollection** ppIGPMGPOCollection) mut => VT.[Friend]SearchGPOs(&this, pIGPMSearchCriteria, ppIGPMGPOCollection);

	public HRESULT RestoreGPO(IGPMBackup* pIGPMBackup, int32 lDCFlags, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]RestoreGPO(&this, pIGPMBackup, lDCFlags, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GetSOM(BSTR bstrPath, IGPMSOM** ppSOM) mut => VT.[Friend]GetSOM(&this, bstrPath, ppSOM);

	public HRESULT SearchSOMs(IGPMSearchCriteria* pIGPMSearchCriteria, IGPMSOMCollection** ppIGPMSOMCollection) mut => VT.[Friend]SearchSOMs(&this, pIGPMSearchCriteria, ppIGPMSOMCollection);

	public HRESULT GetWMIFilter(BSTR bstrPath, IGPMWMIFilter** ppWMIFilter) mut => VT.[Friend]GetWMIFilter(&this, bstrPath, ppWMIFilter);

	public HRESULT SearchWMIFilters(IGPMSearchCriteria* pIGPMSearchCriteria, IGPMWMIFilterCollection** ppIGPMWMIFilterCollection) mut => VT.[Friend]SearchWMIFilters(&this, pIGPMSearchCriteria, ppIGPMWMIFilterCollection);
}

[CRepr]struct IGPMBackupDir : IDispatch
{
	public new const Guid IID = .(0xb1568bed, 0x0a93, 0x4acc, 0x81, 0x0f, 0xaf, 0xe7, 0x08, 0x10, 0x19, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_BackupDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrID, IGPMBackup** ppBackup) GetBackup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, IGPMBackupCollection** ppIGPMBackupCollection) SearchBackups;
	}


	public HRESULT get_BackupDirectory(BSTR* pVal) mut => VT.[Friend]get_BackupDirectory(&this, pVal);

	public HRESULT GetBackup(BSTR bstrID, IGPMBackup** ppBackup) mut => VT.[Friend]GetBackup(&this, bstrID, ppBackup);

	public HRESULT SearchBackups(IGPMSearchCriteria* pIGPMSearchCriteria, IGPMBackupCollection** ppIGPMBackupCollection) mut => VT.[Friend]SearchBackups(&this, pIGPMSearchCriteria, ppIGPMBackupCollection);
}

[CRepr]struct IGPMSitesContainer : IDispatch
{
	public new const Guid IID = .(0x4725a899, 0x2782, 0x4d27, 0xa6, 0xbb, 0xd4, 0x99, 0x24, 0x6f, 0xfd, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DomainController;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Domain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Forest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSiteName, IGPMSOM** ppSOM) GetSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, IGPMSOMCollection** ppIGPMSOMCollection) SearchSites;
	}


	public HRESULT get_DomainController(BSTR* pVal) mut => VT.[Friend]get_DomainController(&this, pVal);

	public HRESULT get_Domain(BSTR* pVal) mut => VT.[Friend]get_Domain(&this, pVal);

	public HRESULT get_Forest(BSTR* pVal) mut => VT.[Friend]get_Forest(&this, pVal);

	public HRESULT GetSite(BSTR bstrSiteName, IGPMSOM** ppSOM) mut => VT.[Friend]GetSite(&this, bstrSiteName, ppSOM);

	public HRESULT SearchSites(IGPMSearchCriteria* pIGPMSearchCriteria, IGPMSOMCollection** ppIGPMSOMCollection) mut => VT.[Friend]SearchSites(&this, pIGPMSearchCriteria, ppIGPMSOMCollection);
}

[CRepr]struct IGPMSearchCriteria : IDispatch
{
	public new const Guid IID = .(0xd6f11c42, 0x829b, 0x48d4, 0x83, 0xf5, 0x36, 0x15, 0xb6, 0x7d, 0xfc, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty searchProperty, GPMSearchOperation searchOperation, VARIANT varValue) Add;
	}


	public HRESULT Add(GPMSearchProperty searchProperty, GPMSearchOperation searchOperation, VARIANT varValue) mut => VT.[Friend]Add(&this, searchProperty, searchOperation, varValue);
}

[CRepr]struct IGPMTrustee : IDispatch
{
	public new const Guid IID = .(0x3b466da8, 0xc1a4, 0x4b2a, 0x99, 0x9a, 0xbe, 0xfc, 0xdd, 0x56, 0xce, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_TrusteeSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_TrusteeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_TrusteeDomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TrusteeDSPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lVal) get_TrusteeType;
	}


	public HRESULT get_TrusteeSid(BSTR* bstrVal) mut => VT.[Friend]get_TrusteeSid(&this, bstrVal);

	public HRESULT get_TrusteeName(BSTR* bstrVal) mut => VT.[Friend]get_TrusteeName(&this, bstrVal);

	public HRESULT get_TrusteeDomain(BSTR* bstrVal) mut => VT.[Friend]get_TrusteeDomain(&this, bstrVal);

	public HRESULT get_TrusteeDSPath(BSTR* pVal) mut => VT.[Friend]get_TrusteeDSPath(&this, pVal);

	public HRESULT get_TrusteeType(int32* lVal) mut => VT.[Friend]get_TrusteeType(&this, lVal);
}

[CRepr]struct IGPMPermission : IDispatch
{
	public new const Guid IID = .(0x35ebca40, 0xe1a1, 0x4a02, 0x89, 0x05, 0xd7, 0x94, 0x16, 0xfb, 0x46, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Inherited;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Inheritable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Denied;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_Permission;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMTrustee** ppIGPMTrustee) get_Trustee;
	}


	public HRESULT get_Inherited(int16* pVal) mut => VT.[Friend]get_Inherited(&this, pVal);

	public HRESULT get_Inheritable(int16* pVal) mut => VT.[Friend]get_Inheritable(&this, pVal);

	public HRESULT get_Denied(int16* pVal) mut => VT.[Friend]get_Denied(&this, pVal);

	public HRESULT get_Permission(GPMPermissionType* pVal) mut => VT.[Friend]get_Permission(&this, pVal);

	public HRESULT get_Trustee(IGPMTrustee** ppIGPMTrustee) mut => VT.[Friend]get_Trustee(&this, ppIGPMTrustee);
}

[CRepr]struct IGPMSecurityInfo : IDispatch
{
	public new const Guid IID = .(0xb6c31ed4, 0x1c93, 0x4d3e, 0xae, 0x84, 0xeb, 0x6d, 0x61, 0x16, 0x1b, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMPermission* pPerm) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMPermission* pPerm) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTrustee) RemoveTrustee;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);

	public HRESULT Add(IGPMPermission* pPerm) mut => VT.[Friend]Add(&this, pPerm);

	public HRESULT Remove(IGPMPermission* pPerm) mut => VT.[Friend]Remove(&this, pPerm);

	public HRESULT RemoveTrustee(BSTR bstrTrustee) mut => VT.[Friend]RemoveTrustee(&this, bstrTrustee);
}

[CRepr]struct IGPMBackup : IDispatch
{
	public new const Guid IID = .(0xd8a16a35, 0x3b0d, 0x416b, 0x8d, 0x02, 0x4d, 0xf6, 0xf9, 0x5a, 0x71, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_GPOID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_GPODomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_GPODisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_Timestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Comment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_BackupDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) GenerateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) GenerateReportToFile;
	}


	public HRESULT get_ID(BSTR* pVal) mut => VT.[Friend]get_ID(&this, pVal);

	public HRESULT get_GPOID(BSTR* pVal) mut => VT.[Friend]get_GPOID(&this, pVal);

	public HRESULT get_GPODomain(BSTR* pVal) mut => VT.[Friend]get_GPODomain(&this, pVal);

	public HRESULT get_GPODisplayName(BSTR* pVal) mut => VT.[Friend]get_GPODisplayName(&this, pVal);

	public HRESULT get_Timestamp(double* pVal) mut => VT.[Friend]get_Timestamp(&this, pVal);

	public HRESULT get_Comment(BSTR* pVal) mut => VT.[Friend]get_Comment(&this, pVal);

	public HRESULT get_BackupDir(BSTR* pVal) mut => VT.[Friend]get_BackupDir(&this, pVal);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT GenerateReport(GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReport(&this, gpmReportType, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReportToFile(GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReportToFile(&this, gpmReportType, bstrTargetFilePath, ppIGPMResult);
}

[CRepr]struct IGPMBackupCollection : IDispatch
{
	public new const Guid IID = .(0xc786fc0f, 0x26d8, 0x4bab, 0xa7, 0x45, 0x39, 0xca, 0x7e, 0x80, 0x0c, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMBackup) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMBackup) mut => VT.[Friend]get__NewEnum(&this, ppIGPMBackup);
}

[CRepr]struct IGPMSOM : IDispatch
{
	public new const Guid IID = .(0xc0a7f09e, 0x05a1, 0x4f0c, 0x81, 0x58, 0x9e, 0x5c, 0x33, 0x68, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_GPOInheritanceBlocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_GPOInheritanceBlocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLinkPos, IGPMGPO* pGPO, IGPMGPOLink** ppNewGPOLink) CreateGPOLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSOMType* pVal) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMGPOLinksCollection** ppGPOLinks) GetGPOLinks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMGPOLinksCollection** ppGPOLinks) GetInheritedGPOLinks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo** ppSecurityInfo) GetSecurityInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo* pSecurityInfo) SetSecurityInfo;
	}


	public HRESULT get_GPOInheritanceBlocked(int16* pVal) mut => VT.[Friend]get_GPOInheritanceBlocked(&this, pVal);

	public HRESULT put_GPOInheritanceBlocked(int16 newVal) mut => VT.[Friend]put_GPOInheritanceBlocked(&this, newVal);

	public HRESULT get_Name(BSTR* pVal) mut => VT.[Friend]get_Name(&this, pVal);

	public HRESULT get_Path(BSTR* pVal) mut => VT.[Friend]get_Path(&this, pVal);

	public HRESULT CreateGPOLink(int32 lLinkPos, IGPMGPO* pGPO, IGPMGPOLink** ppNewGPOLink) mut => VT.[Friend]CreateGPOLink(&this, lLinkPos, pGPO, ppNewGPOLink);

	public HRESULT get_Type(GPMSOMType* pVal) mut => VT.[Friend]get_Type(&this, pVal);

	public HRESULT GetGPOLinks(IGPMGPOLinksCollection** ppGPOLinks) mut => VT.[Friend]GetGPOLinks(&this, ppGPOLinks);

	public HRESULT GetInheritedGPOLinks(IGPMGPOLinksCollection** ppGPOLinks) mut => VT.[Friend]GetInheritedGPOLinks(&this, ppGPOLinks);

	public HRESULT GetSecurityInfo(IGPMSecurityInfo** ppSecurityInfo) mut => VT.[Friend]GetSecurityInfo(&this, ppSecurityInfo);

	public HRESULT SetSecurityInfo(IGPMSecurityInfo* pSecurityInfo) mut => VT.[Friend]SetSecurityInfo(&this, pSecurityInfo);
}

[CRepr]struct IGPMSOMCollection : IDispatch
{
	public new const Guid IID = .(0xadc1688e, 0x00e4, 0x4495, 0xab, 0xba, 0xbe, 0xd2, 0x00, 0xdf, 0x0c, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMSOM) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMSOM) mut => VT.[Friend]get__NewEnum(&this, ppIGPMSOM);
}

[CRepr]struct IGPMWMIFilter : IDispatch
{
	public new const Guid IID = .(0xef2ff9b4, 0x3c27, 0x459a, 0xb9, 0x79, 0x03, 0x83, 0x05, 0xce, 0xc7, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pQryList) GetQueryList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo** ppSecurityInfo) GetSecurityInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo* pSecurityInfo) SetSecurityInfo;
	}


	public HRESULT get_Path(BSTR* pVal) mut => VT.[Friend]get_Path(&this, pVal);

	public HRESULT put_Name(BSTR newVal) mut => VT.[Friend]put_Name(&this, newVal);

	public HRESULT get_Name(BSTR* pVal) mut => VT.[Friend]get_Name(&this, pVal);

	public HRESULT put_Description(BSTR newVal) mut => VT.[Friend]put_Description(&this, newVal);

	public HRESULT get_Description(BSTR* pVal) mut => VT.[Friend]get_Description(&this, pVal);

	public HRESULT GetQueryList(VARIANT* pQryList) mut => VT.[Friend]GetQueryList(&this, pQryList);

	public HRESULT GetSecurityInfo(IGPMSecurityInfo** ppSecurityInfo) mut => VT.[Friend]GetSecurityInfo(&this, ppSecurityInfo);

	public HRESULT SetSecurityInfo(IGPMSecurityInfo* pSecurityInfo) mut => VT.[Friend]SetSecurityInfo(&this, pSecurityInfo);
}

[CRepr]struct IGPMWMIFilterCollection : IDispatch
{
	public new const Guid IID = .(0x5782d582, 0x1a36, 0x4661, 0x8a, 0x94, 0xc3, 0xc3, 0x25, 0x51, 0x94, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** pVal) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);
}

[CRepr]struct IGPMRSOP : IDispatch
{
	public new const Guid IID = .(0x49ed785a, 0x3237, 0x4ff2, 0xb1, 0xf0, 0xfd, 0xf5, 0xa8, 0xd5, 0xa1, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMRSOPMode* pVal) get_Mode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_Namespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_LoggingComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_LoggingComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_LoggingUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_LoggingUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVal) put_LoggingFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lVal) get_LoggingFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVal) put_PlanningFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lVal) get_PlanningFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_PlanningDomainController;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_PlanningDomainController;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_PlanningSiteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_PlanningSiteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_PlanningUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_PlanningUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_PlanningUserSOM;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_PlanningUserSOM;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varVal) put_PlanningUserWMIFilters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* varVal) get_PlanningUserWMIFilters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varVal) put_PlanningUserSecurityGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* varVal) get_PlanningUserSecurityGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_PlanningComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_PlanningComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_PlanningComputerSOM;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrVal) get_PlanningComputerSOM;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varVal) put_PlanningComputerWMIFilters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* varVal) get_PlanningComputerWMIFilters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varVal) put_PlanningComputerSecurityGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* varVal) get_PlanningComputerSecurityGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* varVal) LoggingEnumerateUsers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CreateQueryResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseQueryResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) GenerateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) GenerateReportToFile;
	}


	public HRESULT get_Mode(GPMRSOPMode* pVal) mut => VT.[Friend]get_Mode(&this, pVal);

	public HRESULT get_Namespace(BSTR* bstrVal) mut => VT.[Friend]get_Namespace(&this, bstrVal);

	public HRESULT put_LoggingComputer(BSTR bstrVal) mut => VT.[Friend]put_LoggingComputer(&this, bstrVal);

	public HRESULT get_LoggingComputer(BSTR* bstrVal) mut => VT.[Friend]get_LoggingComputer(&this, bstrVal);

	public HRESULT put_LoggingUser(BSTR bstrVal) mut => VT.[Friend]put_LoggingUser(&this, bstrVal);

	public HRESULT get_LoggingUser(BSTR* bstrVal) mut => VT.[Friend]get_LoggingUser(&this, bstrVal);

	public HRESULT put_LoggingFlags(int32 lVal) mut => VT.[Friend]put_LoggingFlags(&this, lVal);

	public HRESULT get_LoggingFlags(int32* lVal) mut => VT.[Friend]get_LoggingFlags(&this, lVal);

	public HRESULT put_PlanningFlags(int32 lVal) mut => VT.[Friend]put_PlanningFlags(&this, lVal);

	public HRESULT get_PlanningFlags(int32* lVal) mut => VT.[Friend]get_PlanningFlags(&this, lVal);

	public HRESULT put_PlanningDomainController(BSTR bstrVal) mut => VT.[Friend]put_PlanningDomainController(&this, bstrVal);

	public HRESULT get_PlanningDomainController(BSTR* bstrVal) mut => VT.[Friend]get_PlanningDomainController(&this, bstrVal);

	public HRESULT put_PlanningSiteName(BSTR bstrVal) mut => VT.[Friend]put_PlanningSiteName(&this, bstrVal);

	public HRESULT get_PlanningSiteName(BSTR* bstrVal) mut => VT.[Friend]get_PlanningSiteName(&this, bstrVal);

	public HRESULT put_PlanningUser(BSTR bstrVal) mut => VT.[Friend]put_PlanningUser(&this, bstrVal);

	public HRESULT get_PlanningUser(BSTR* bstrVal) mut => VT.[Friend]get_PlanningUser(&this, bstrVal);

	public HRESULT put_PlanningUserSOM(BSTR bstrVal) mut => VT.[Friend]put_PlanningUserSOM(&this, bstrVal);

	public HRESULT get_PlanningUserSOM(BSTR* bstrVal) mut => VT.[Friend]get_PlanningUserSOM(&this, bstrVal);

	public HRESULT put_PlanningUserWMIFilters(VARIANT varVal) mut => VT.[Friend]put_PlanningUserWMIFilters(&this, varVal);

	public HRESULT get_PlanningUserWMIFilters(VARIANT* varVal) mut => VT.[Friend]get_PlanningUserWMIFilters(&this, varVal);

	public HRESULT put_PlanningUserSecurityGroups(VARIANT varVal) mut => VT.[Friend]put_PlanningUserSecurityGroups(&this, varVal);

	public HRESULT get_PlanningUserSecurityGroups(VARIANT* varVal) mut => VT.[Friend]get_PlanningUserSecurityGroups(&this, varVal);

	public HRESULT put_PlanningComputer(BSTR bstrVal) mut => VT.[Friend]put_PlanningComputer(&this, bstrVal);

	public HRESULT get_PlanningComputer(BSTR* bstrVal) mut => VT.[Friend]get_PlanningComputer(&this, bstrVal);

	public HRESULT put_PlanningComputerSOM(BSTR bstrVal) mut => VT.[Friend]put_PlanningComputerSOM(&this, bstrVal);

	public HRESULT get_PlanningComputerSOM(BSTR* bstrVal) mut => VT.[Friend]get_PlanningComputerSOM(&this, bstrVal);

	public HRESULT put_PlanningComputerWMIFilters(VARIANT varVal) mut => VT.[Friend]put_PlanningComputerWMIFilters(&this, varVal);

	public HRESULT get_PlanningComputerWMIFilters(VARIANT* varVal) mut => VT.[Friend]get_PlanningComputerWMIFilters(&this, varVal);

	public HRESULT put_PlanningComputerSecurityGroups(VARIANT varVal) mut => VT.[Friend]put_PlanningComputerSecurityGroups(&this, varVal);

	public HRESULT get_PlanningComputerSecurityGroups(VARIANT* varVal) mut => VT.[Friend]get_PlanningComputerSecurityGroups(&this, varVal);

	public HRESULT LoggingEnumerateUsers(VARIANT* varVal) mut => VT.[Friend]LoggingEnumerateUsers(&this, varVal);

	public HRESULT CreateQueryResults() mut => VT.[Friend]CreateQueryResults(&this);

	public HRESULT ReleaseQueryResults() mut => VT.[Friend]ReleaseQueryResults(&this);

	public HRESULT GenerateReport(GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReport(&this, gpmReportType, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReportToFile(GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReportToFile(&this, gpmReportType, bstrTargetFilePath, ppIGPMResult);
}

[CRepr]struct IGPMGPO : IDispatch
{
	public new const Guid IID = .(0x58cc4352, 0x1ca3, 0x48e5, 0x98, 0x64, 0x1d, 0xa4, 0xd6, 0xe0, 0xd6, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DomainName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDate) get_CreationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDate) get_ModificationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_UserDSVersionNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_ComputerDSVersionNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_UserSysvolVersionNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_ComputerSysvolVersionNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMWMIFilter** ppIGPMWMIFilter) GetWMIFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMWMIFilter* pIGPMWMIFilter) SetWMIFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbEnabled) SetUserEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbEnabled) SetComputerEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbEnabled) IsUserEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbEnabled) IsComputerEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo** ppSecurityInfo) GetSecurityInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo* pSecurityInfo) SetSecurityInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBackupDir, BSTR bstrComment, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) Backup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IGPMBackup* pIGPMBackup, VARIANT* pvarMigrationTable, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) GenerateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) GenerateReportToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IGPMDomain* pIGPMDomain, VARIANT* pvarNewDisplayName, VARIANT* pvarMigrationTable, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) CopyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IDispatch* pSD) SetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IDispatch** ppSD) GetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbConsistent) IsACLConsistent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MakeACLConsistent;
	}


	public HRESULT get_DisplayName(BSTR* pVal) mut => VT.[Friend]get_DisplayName(&this, pVal);

	public HRESULT put_DisplayName(BSTR newVal) mut => VT.[Friend]put_DisplayName(&this, newVal);

	public HRESULT get_Path(BSTR* pVal) mut => VT.[Friend]get_Path(&this, pVal);

	public HRESULT get_ID(BSTR* pVal) mut => VT.[Friend]get_ID(&this, pVal);

	public HRESULT get_DomainName(BSTR* pVal) mut => VT.[Friend]get_DomainName(&this, pVal);

	public HRESULT get_CreationTime(double* pDate) mut => VT.[Friend]get_CreationTime(&this, pDate);

	public HRESULT get_ModificationTime(double* pDate) mut => VT.[Friend]get_ModificationTime(&this, pDate);

	public HRESULT get_UserDSVersionNumber(int32* pVal) mut => VT.[Friend]get_UserDSVersionNumber(&this, pVal);

	public HRESULT get_ComputerDSVersionNumber(int32* pVal) mut => VT.[Friend]get_ComputerDSVersionNumber(&this, pVal);

	public HRESULT get_UserSysvolVersionNumber(int32* pVal) mut => VT.[Friend]get_UserSysvolVersionNumber(&this, pVal);

	public HRESULT get_ComputerSysvolVersionNumber(int32* pVal) mut => VT.[Friend]get_ComputerSysvolVersionNumber(&this, pVal);

	public HRESULT GetWMIFilter(IGPMWMIFilter** ppIGPMWMIFilter) mut => VT.[Friend]GetWMIFilter(&this, ppIGPMWMIFilter);

	public HRESULT SetWMIFilter(IGPMWMIFilter* pIGPMWMIFilter) mut => VT.[Friend]SetWMIFilter(&this, pIGPMWMIFilter);

	public HRESULT SetUserEnabled(int16 vbEnabled) mut => VT.[Friend]SetUserEnabled(&this, vbEnabled);

	public HRESULT SetComputerEnabled(int16 vbEnabled) mut => VT.[Friend]SetComputerEnabled(&this, vbEnabled);

	public HRESULT IsUserEnabled(int16* pvbEnabled) mut => VT.[Friend]IsUserEnabled(&this, pvbEnabled);

	public HRESULT IsComputerEnabled(int16* pvbEnabled) mut => VT.[Friend]IsComputerEnabled(&this, pvbEnabled);

	public HRESULT GetSecurityInfo(IGPMSecurityInfo** ppSecurityInfo) mut => VT.[Friend]GetSecurityInfo(&this, ppSecurityInfo);

	public HRESULT SetSecurityInfo(IGPMSecurityInfo* pSecurityInfo) mut => VT.[Friend]SetSecurityInfo(&this, pSecurityInfo);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Backup(BSTR bstrBackupDir, BSTR bstrComment, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]Backup(&this, bstrBackupDir, bstrComment, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT Import(int32 lFlags, IGPMBackup* pIGPMBackup, VARIANT* pvarMigrationTable, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]Import(&this, lFlags, pIGPMBackup, pvarMigrationTable, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReport(GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReport(&this, gpmReportType, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReportToFile(GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReportToFile(&this, gpmReportType, bstrTargetFilePath, ppIGPMResult);

	public HRESULT CopyTo(int32 lFlags, IGPMDomain* pIGPMDomain, VARIANT* pvarNewDisplayName, VARIANT* pvarMigrationTable, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]CopyTo(&this, lFlags, pIGPMDomain, pvarNewDisplayName, pvarMigrationTable, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT SetSecurityDescriptor(int32 lFlags, IDispatch* pSD) mut => VT.[Friend]SetSecurityDescriptor(&this, lFlags, pSD);

	public HRESULT GetSecurityDescriptor(int32 lFlags, IDispatch** ppSD) mut => VT.[Friend]GetSecurityDescriptor(&this, lFlags, ppSD);

	public HRESULT IsACLConsistent(int16* pvbConsistent) mut => VT.[Friend]IsACLConsistent(&this, pvbConsistent);

	public HRESULT MakeACLConsistent() mut => VT.[Friend]MakeACLConsistent(&this);
}

[CRepr]struct IGPMGPOCollection : IDispatch
{
	public new const Guid IID = .(0xf0f0d5cf, 0x70ca, 0x4c39, 0x9e, 0x29, 0xb6, 0x42, 0xf8, 0x72, 0x6c, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMGPOs) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMGPOs) mut => VT.[Friend]get__NewEnum(&this, ppIGPMGPOs);
}

[CRepr]struct IGPMGPOLink : IDispatch
{
	public new const Guid IID = .(0x434b99bd, 0x5de7, 0x478a, 0x80, 0x9c, 0xc2, 0x51, 0x72, 0x1d, 0xf7, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_GPOID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_GPODomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Enforced;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 newVal) put_Enforced;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lVal) get_SOMLinkOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSOM** ppIGPMSOM) get_SOM;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_GPOID(BSTR* pVal) mut => VT.[Friend]get_GPOID(&this, pVal);

	public HRESULT get_GPODomain(BSTR* pVal) mut => VT.[Friend]get_GPODomain(&this, pVal);

	public HRESULT get_Enabled(int16* pVal) mut => VT.[Friend]get_Enabled(&this, pVal);

	public HRESULT put_Enabled(int16 newVal) mut => VT.[Friend]put_Enabled(&this, newVal);

	public HRESULT get_Enforced(int16* pVal) mut => VT.[Friend]get_Enforced(&this, pVal);

	public HRESULT put_Enforced(int16 newVal) mut => VT.[Friend]put_Enforced(&this, newVal);

	public HRESULT get_SOMLinkOrder(int32* lVal) mut => VT.[Friend]get_SOMLinkOrder(&this, lVal);

	public HRESULT get_SOM(IGPMSOM** ppIGPMSOM) mut => VT.[Friend]get_SOM(&this, ppIGPMSOM);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IGPMGPOLinksCollection : IDispatch
{
	public new const Guid IID = .(0x189d7b68, 0x16bd, 0x4d0d, 0xa2, 0xec, 0x2e, 0x6a, 0xa2, 0x28, 0x8c, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMLinks) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMLinks) mut => VT.[Friend]get__NewEnum(&this, ppIGPMLinks);
}

[CRepr]struct IGPMCSECollection : IDispatch
{
	public new const Guid IID = .(0x2e52a97d, 0x0a4a, 0x4a6f, 0x85, 0xdb, 0x20, 0x16, 0x22, 0x45, 0x5d, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMCSEs) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMCSEs) mut => VT.[Friend]get__NewEnum(&this, ppIGPMCSEs);
}

[CRepr]struct IGPMClientSideExtension : IDispatch
{
	public new const Guid IID = .(0x69da7488, 0xb8db, 0x415e, 0x92, 0x66, 0x90, 0x1b, 0xe4, 0xd4, 0x99, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbEnabled) IsUserEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbEnabled) IsComputerEnabled;
	}


	public HRESULT get_ID(BSTR* pVal) mut => VT.[Friend]get_ID(&this, pVal);

	public HRESULT get_DisplayName(BSTR* pVal) mut => VT.[Friend]get_DisplayName(&this, pVal);

	public HRESULT IsUserEnabled(int16* pvbEnabled) mut => VT.[Friend]IsUserEnabled(&this, pvbEnabled);

	public HRESULT IsComputerEnabled(int16* pvbEnabled) mut => VT.[Friend]IsComputerEnabled(&this, pvbEnabled);
}

[CRepr]struct IGPMAsyncCancel : IDispatch
{
	public new const Guid IID = .(0xddc67754, 0xbe67, 0x4541, 0x81, 0x66, 0xf4, 0x81, 0x66, 0x86, 0x8c, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IGPMAsyncProgress : IDispatch
{
	public new const Guid IID = .(0x6aac29f8, 0x5948, 0x4324, 0xbf, 0x70, 0x42, 0x38, 0x18, 0x94, 0x2d, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProgressNumerator, int32 lProgressDenominator, HRESULT hrStatus, VARIANT* pResult, IGPMStatusMsgCollection* ppIGPMStatusMsgCollection) Status;
	}


	public HRESULT Status(int32 lProgressNumerator, int32 lProgressDenominator, HRESULT hrStatus, VARIANT* pResult, IGPMStatusMsgCollection* ppIGPMStatusMsgCollection) mut => VT.[Friend]Status(&this, lProgressNumerator, lProgressDenominator, hrStatus, pResult, ppIGPMStatusMsgCollection);
}

[CRepr]struct IGPMStatusMsgCollection : IDispatch
{
	public new const Guid IID = .(0x9b6e1af0, 0x1a92, 0x40f3, 0xa5, 0x9d, 0xf3, 0x6a, 0xc1, 0xf7, 0x28, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** pVal) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);
}

[CRepr]struct IGPMStatusMessage : IDispatch
{
	public new const Guid IID = .(0x8496c22f, 0xf3de, 0x4a1f, 0x8f, 0x58, 0x60, 0x3c, 0xaa, 0xa9, 0x3d, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ObjectPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ExtensionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_SettingsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OperationCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Message;
	}


	public HRESULT get_ObjectPath(BSTR* pVal) mut => VT.[Friend]get_ObjectPath(&this, pVal);

	public HRESULT ErrorCode() mut => VT.[Friend]ErrorCode(&this);

	public HRESULT get_ExtensionName(BSTR* pVal) mut => VT.[Friend]get_ExtensionName(&this, pVal);

	public HRESULT get_SettingsName(BSTR* pVal) mut => VT.[Friend]get_SettingsName(&this, pVal);

	public HRESULT OperationCode() mut => VT.[Friend]OperationCode(&this);

	public HRESULT get_Message(BSTR* pVal) mut => VT.[Friend]get_Message(&this, pVal);
}

[CRepr]struct IGPMConstants : IDispatch
{
	public new const Guid IID = .(0x50ef73e6, 0xd35c, 0x4c8d, 0xbe, 0x63, 0x7e, 0xa5, 0xd2, 0xaa, 0xc5, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermGPOApply;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermGPORead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermGPOEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermGPOEditSecurityAndDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermGPOCustom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermWMIFilterEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermWMIFilterFullControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermWMIFilterCustom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermSOMLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermSOMLogging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermSOMPlanning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermSOMGPOCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermSOMWMICreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermSOMWMIFullControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPOPermissions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPOEffectivePermissions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPODisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPOWMIFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPOID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPOComputerExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPOUserExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertySOMLinks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyGPODomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyBackupMostRecent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchOperation* pVal) get_SearchOpEquals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchOperation* pVal) get_SearchOpContains;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchOperation* pVal) get_SearchOpNotContains;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchOperation* pVal) get_SearchOpNotEquals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_UsePDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_UseAnyDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_DoNotUseW2KDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSOMType* pVal) get_SOMSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSOMType* pVal) get_SOMDomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSOMType* pVal) get_SOMOU;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbOwner, int16 vbGroup, int16 vbDACL, int16 vbSACL, int32* pVal) get_SecurityFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_DoNotValidateDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType* pVal) get_ReportHTML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType* pVal) get_ReportXML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMRSOPMode* pVal) get_RSOPModeUnknown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMRSOPMode* pVal) get_RSOPModePlanning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMRSOPMode* pVal) get_RSOPModeLogging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeLocalGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeGlobalGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeUniversalGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeUNCPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pVal) get_EntryTypeUnknown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMDestinationOption* pVal) get_DestinationOptionSameAsSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMDestinationOption* pVal) get_DestinationOptionNone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMDestinationOption* pVal) get_DestinationOptionByRelativeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMDestinationOption* pVal) get_DestinationOptionSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_MigrationTableOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_ProcessSecurity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_RsopLoggingNoComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_RsopLoggingNoUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_RsopPlanningAssumeSlowLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbMerge, int32* pVal) get_RsopPlanningLoopbackOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_RsopPlanningAssumeUserWQLFilterTrue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_RsopPlanningAssumeCompWQLFilterTrue;
	}


	public HRESULT get_PermGPOApply(GPMPermissionType* pVal) mut => VT.[Friend]get_PermGPOApply(&this, pVal);

	public HRESULT get_PermGPORead(GPMPermissionType* pVal) mut => VT.[Friend]get_PermGPORead(&this, pVal);

	public HRESULT get_PermGPOEdit(GPMPermissionType* pVal) mut => VT.[Friend]get_PermGPOEdit(&this, pVal);

	public HRESULT get_PermGPOEditSecurityAndDelete(GPMPermissionType* pVal) mut => VT.[Friend]get_PermGPOEditSecurityAndDelete(&this, pVal);

	public HRESULT get_PermGPOCustom(GPMPermissionType* pVal) mut => VT.[Friend]get_PermGPOCustom(&this, pVal);

	public HRESULT get_PermWMIFilterEdit(GPMPermissionType* pVal) mut => VT.[Friend]get_PermWMIFilterEdit(&this, pVal);

	public HRESULT get_PermWMIFilterFullControl(GPMPermissionType* pVal) mut => VT.[Friend]get_PermWMIFilterFullControl(&this, pVal);

	public HRESULT get_PermWMIFilterCustom(GPMPermissionType* pVal) mut => VT.[Friend]get_PermWMIFilterCustom(&this, pVal);

	public HRESULT get_PermSOMLink(GPMPermissionType* pVal) mut => VT.[Friend]get_PermSOMLink(&this, pVal);

	public HRESULT get_PermSOMLogging(GPMPermissionType* pVal) mut => VT.[Friend]get_PermSOMLogging(&this, pVal);

	public HRESULT get_PermSOMPlanning(GPMPermissionType* pVal) mut => VT.[Friend]get_PermSOMPlanning(&this, pVal);

	public HRESULT get_PermSOMGPOCreate(GPMPermissionType* pVal) mut => VT.[Friend]get_PermSOMGPOCreate(&this, pVal);

	public HRESULT get_PermSOMWMICreate(GPMPermissionType* pVal) mut => VT.[Friend]get_PermSOMWMICreate(&this, pVal);

	public HRESULT get_PermSOMWMIFullControl(GPMPermissionType* pVal) mut => VT.[Friend]get_PermSOMWMIFullControl(&this, pVal);

	public HRESULT get_SearchPropertyGPOPermissions(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPOPermissions(&this, pVal);

	public HRESULT get_SearchPropertyGPOEffectivePermissions(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPOEffectivePermissions(&this, pVal);

	public HRESULT get_SearchPropertyGPODisplayName(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPODisplayName(&this, pVal);

	public HRESULT get_SearchPropertyGPOWMIFilter(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPOWMIFilter(&this, pVal);

	public HRESULT get_SearchPropertyGPOID(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPOID(&this, pVal);

	public HRESULT get_SearchPropertyGPOComputerExtensions(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPOComputerExtensions(&this, pVal);

	public HRESULT get_SearchPropertyGPOUserExtensions(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPOUserExtensions(&this, pVal);

	public HRESULT get_SearchPropertySOMLinks(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertySOMLinks(&this, pVal);

	public HRESULT get_SearchPropertyGPODomain(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyGPODomain(&this, pVal);

	public HRESULT get_SearchPropertyBackupMostRecent(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyBackupMostRecent(&this, pVal);

	public HRESULT get_SearchOpEquals(GPMSearchOperation* pVal) mut => VT.[Friend]get_SearchOpEquals(&this, pVal);

	public HRESULT get_SearchOpContains(GPMSearchOperation* pVal) mut => VT.[Friend]get_SearchOpContains(&this, pVal);

	public HRESULT get_SearchOpNotContains(GPMSearchOperation* pVal) mut => VT.[Friend]get_SearchOpNotContains(&this, pVal);

	public HRESULT get_SearchOpNotEquals(GPMSearchOperation* pVal) mut => VT.[Friend]get_SearchOpNotEquals(&this, pVal);

	public HRESULT get_UsePDC(int32* pVal) mut => VT.[Friend]get_UsePDC(&this, pVal);

	public HRESULT get_UseAnyDC(int32* pVal) mut => VT.[Friend]get_UseAnyDC(&this, pVal);

	public HRESULT get_DoNotUseW2KDC(int32* pVal) mut => VT.[Friend]get_DoNotUseW2KDC(&this, pVal);

	public HRESULT get_SOMSite(GPMSOMType* pVal) mut => VT.[Friend]get_SOMSite(&this, pVal);

	public HRESULT get_SOMDomain(GPMSOMType* pVal) mut => VT.[Friend]get_SOMDomain(&this, pVal);

	public HRESULT get_SOMOU(GPMSOMType* pVal) mut => VT.[Friend]get_SOMOU(&this, pVal);

	public HRESULT get_SecurityFlags(int16 vbOwner, int16 vbGroup, int16 vbDACL, int16 vbSACL, int32* pVal) mut => VT.[Friend]get_SecurityFlags(&this, vbOwner, vbGroup, vbDACL, vbSACL, pVal);

	public HRESULT get_DoNotValidateDC(int32* pVal) mut => VT.[Friend]get_DoNotValidateDC(&this, pVal);

	public HRESULT get_ReportHTML(GPMReportType* pVal) mut => VT.[Friend]get_ReportHTML(&this, pVal);

	public HRESULT get_ReportXML(GPMReportType* pVal) mut => VT.[Friend]get_ReportXML(&this, pVal);

	public HRESULT get_RSOPModeUnknown(GPMRSOPMode* pVal) mut => VT.[Friend]get_RSOPModeUnknown(&this, pVal);

	public HRESULT get_RSOPModePlanning(GPMRSOPMode* pVal) mut => VT.[Friend]get_RSOPModePlanning(&this, pVal);

	public HRESULT get_RSOPModeLogging(GPMRSOPMode* pVal) mut => VT.[Friend]get_RSOPModeLogging(&this, pVal);

	public HRESULT get_EntryTypeUser(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeUser(&this, pVal);

	public HRESULT get_EntryTypeComputer(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeComputer(&this, pVal);

	public HRESULT get_EntryTypeLocalGroup(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeLocalGroup(&this, pVal);

	public HRESULT get_EntryTypeGlobalGroup(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeGlobalGroup(&this, pVal);

	public HRESULT get_EntryTypeUniversalGroup(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeUniversalGroup(&this, pVal);

	public HRESULT get_EntryTypeUNCPath(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeUNCPath(&this, pVal);

	public HRESULT get_EntryTypeUnknown(GPMEntryType* pVal) mut => VT.[Friend]get_EntryTypeUnknown(&this, pVal);

	public HRESULT get_DestinationOptionSameAsSource(GPMDestinationOption* pVal) mut => VT.[Friend]get_DestinationOptionSameAsSource(&this, pVal);

	public HRESULT get_DestinationOptionNone(GPMDestinationOption* pVal) mut => VT.[Friend]get_DestinationOptionNone(&this, pVal);

	public HRESULT get_DestinationOptionByRelativeName(GPMDestinationOption* pVal) mut => VT.[Friend]get_DestinationOptionByRelativeName(&this, pVal);

	public HRESULT get_DestinationOptionSet(GPMDestinationOption* pVal) mut => VT.[Friend]get_DestinationOptionSet(&this, pVal);

	public HRESULT get_MigrationTableOnly(int32* pVal) mut => VT.[Friend]get_MigrationTableOnly(&this, pVal);

	public HRESULT get_ProcessSecurity(int32* pVal) mut => VT.[Friend]get_ProcessSecurity(&this, pVal);

	public HRESULT get_RsopLoggingNoComputer(int32* pVal) mut => VT.[Friend]get_RsopLoggingNoComputer(&this, pVal);

	public HRESULT get_RsopLoggingNoUser(int32* pVal) mut => VT.[Friend]get_RsopLoggingNoUser(&this, pVal);

	public HRESULT get_RsopPlanningAssumeSlowLink(int32* pVal) mut => VT.[Friend]get_RsopPlanningAssumeSlowLink(&this, pVal);

	public HRESULT get_RsopPlanningLoopbackOption(int16 vbMerge, int32* pVal) mut => VT.[Friend]get_RsopPlanningLoopbackOption(&this, vbMerge, pVal);

	public HRESULT get_RsopPlanningAssumeUserWQLFilterTrue(int32* pVal) mut => VT.[Friend]get_RsopPlanningAssumeUserWQLFilterTrue(&this, pVal);

	public HRESULT get_RsopPlanningAssumeCompWQLFilterTrue(int32* pVal) mut => VT.[Friend]get_RsopPlanningAssumeCompWQLFilterTrue(&this, pVal);
}

[CRepr]struct IGPMResult : IDispatch
{
	public new const Guid IID = .(0x86dff7e9, 0xf76f, 0x42ab, 0x95, 0x70, 0xce, 0xbc, 0x6b, 0xe8, 0xa5, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMStatusMsgCollection** ppIGPMStatusMsgCollection) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarResult) get_Result;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OverallStatus;
	}


	public HRESULT get_Status(IGPMStatusMsgCollection** ppIGPMStatusMsgCollection) mut => VT.[Friend]get_Status(&this, ppIGPMStatusMsgCollection);

	public HRESULT get_Result(VARIANT* pvarResult) mut => VT.[Friend]get_Result(&this, pvarResult);

	public HRESULT OverallStatus() mut => VT.[Friend]OverallStatus(&this);
}

[CRepr]struct IGPMMapEntryCollection : IDispatch
{
	public new const Guid IID = .(0xbb0bf49b, 0xe53f, 0x443f, 0xb8, 0x07, 0x8b, 0xe2, 0x2b, 0xfb, 0x6d, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** pVal) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);
}

[CRepr]struct IGPMMapEntry : IDispatch
{
	public new const Guid IID = .(0x8e79ad06, 0x2381, 0x4444, 0xbe, 0x4c, 0xff, 0x69, 0x3e, 0x6e, 0x6f, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSource) get_Source;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDestination) get_Destination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMDestinationOption* pgpmDestOption) get_DestinationOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMEntryType* pgpmEntryType) get_EntryType;
	}


	public HRESULT get_Source(BSTR* pbstrSource) mut => VT.[Friend]get_Source(&this, pbstrSource);

	public HRESULT get_Destination(BSTR* pbstrDestination) mut => VT.[Friend]get_Destination(&this, pbstrDestination);

	public HRESULT get_DestinationOption(GPMDestinationOption* pgpmDestOption) mut => VT.[Friend]get_DestinationOption(&this, pgpmDestOption);

	public HRESULT get_EntryType(GPMEntryType* pgpmEntryType) mut => VT.[Friend]get_EntryType(&this, pgpmEntryType);
}

[CRepr]struct IGPMMigrationTable : IDispatch
{
	public new const Guid IID = .(0x48f823b1, 0xefaf, 0x470b, 0xb6, 0xed, 0x40, 0xd1, 0x4e, 0xe1, 0xa4, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMigrationTablePath) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT @var) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSource, GPMEntryType gpmEntryType, VARIANT* pvarDestination, IGPMMapEntry** ppEntry) AddEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSource, IGPMMapEntry** ppEntry) GetEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSource) DeleteEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSource, VARIANT* pvarDestination, IGPMMapEntry** ppEntry) UpdateDestination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMResult** ppResult) Validate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMMapEntryCollection** ppEntries) GetEntries;
	}


	public HRESULT Save(BSTR bstrMigrationTablePath) mut => VT.[Friend]Save(&this, bstrMigrationTablePath);

	public HRESULT Add(int32 lFlags, VARIANT @var) mut => VT.[Friend]Add(&this, lFlags, @var);

	public HRESULT AddEntry(BSTR bstrSource, GPMEntryType gpmEntryType, VARIANT* pvarDestination, IGPMMapEntry** ppEntry) mut => VT.[Friend]AddEntry(&this, bstrSource, gpmEntryType, pvarDestination, ppEntry);

	public HRESULT GetEntry(BSTR bstrSource, IGPMMapEntry** ppEntry) mut => VT.[Friend]GetEntry(&this, bstrSource, ppEntry);

	public HRESULT DeleteEntry(BSTR bstrSource) mut => VT.[Friend]DeleteEntry(&this, bstrSource);

	public HRESULT UpdateDestination(BSTR bstrSource, VARIANT* pvarDestination, IGPMMapEntry** ppEntry) mut => VT.[Friend]UpdateDestination(&this, bstrSource, pvarDestination, ppEntry);

	public HRESULT Validate(IGPMResult** ppResult) mut => VT.[Friend]Validate(&this, ppResult);

	public HRESULT GetEntries(IGPMMapEntryCollection** ppEntries) mut => VT.[Friend]GetEntries(&this, ppEntries);
}

[CRepr]struct IGPMBackupDirEx : IDispatch
{
	public new const Guid IID = .(0xf8dc55ed, 0x3ba0, 0x4864, 0xaa, 0xd4, 0xd3, 0x65, 0x18, 0x9e, 0xe1, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBackupDir) get_BackupDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMBackupType* pgpmBackupType) get_BackupType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrID, VARIANT* pvarBackup) GetBackup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, VARIANT* pvarBackupCollection) SearchBackups;
	}


	public HRESULT get_BackupDir(BSTR* pbstrBackupDir) mut => VT.[Friend]get_BackupDir(&this, pbstrBackupDir);

	public HRESULT get_BackupType(GPMBackupType* pgpmBackupType) mut => VT.[Friend]get_BackupType(&this, pgpmBackupType);

	public HRESULT GetBackup(BSTR bstrID, VARIANT* pvarBackup) mut => VT.[Friend]GetBackup(&this, bstrID, pvarBackup);

	public HRESULT SearchBackups(IGPMSearchCriteria* pIGPMSearchCriteria, VARIANT* pvarBackupCollection) mut => VT.[Friend]SearchBackups(&this, pIGPMSearchCriteria, pvarBackupCollection);
}

[CRepr]struct IGPMStarterGPOBackupCollection : IDispatch
{
	public new const Guid IID = .(0xc998031d, 0xadd0, 0x4bb5, 0x8d, 0xea, 0x29, 0x85, 0x05, 0xd8, 0x42, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMTmplBackup) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMTmplBackup) mut => VT.[Friend]get__NewEnum(&this, ppIGPMTmplBackup);
}

[CRepr]struct IGPMStarterGPOBackup : IDispatch
{
	public new const Guid IID = .(0x51d98eda, 0xa87e, 0x43dd, 0xb8, 0x0a, 0x0b, 0x66, 0xef, 0x19, 0x38, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBackupDir) get_BackupDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrComment) get_Comment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDisplayName) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTemplateDomain) get_Domain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTemplateID) get_StarterGPOID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrID) get_ID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pTimestamp) get_Timestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMStarterGPOType* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) GenerateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) GenerateReportToFile;
	}


	public HRESULT get_BackupDir(BSTR* pbstrBackupDir) mut => VT.[Friend]get_BackupDir(&this, pbstrBackupDir);

	public HRESULT get_Comment(BSTR* pbstrComment) mut => VT.[Friend]get_Comment(&this, pbstrComment);

	public HRESULT get_DisplayName(BSTR* pbstrDisplayName) mut => VT.[Friend]get_DisplayName(&this, pbstrDisplayName);

	public HRESULT get_Domain(BSTR* pbstrTemplateDomain) mut => VT.[Friend]get_Domain(&this, pbstrTemplateDomain);

	public HRESULT get_StarterGPOID(BSTR* pbstrTemplateID) mut => VT.[Friend]get_StarterGPOID(&this, pbstrTemplateID);

	public HRESULT get_ID(BSTR* pbstrID) mut => VT.[Friend]get_ID(&this, pbstrID);

	public HRESULT get_Timestamp(double* pTimestamp) mut => VT.[Friend]get_Timestamp(&this, pTimestamp);

	public HRESULT get_Type(GPMStarterGPOType* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT GenerateReport(GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReport(&this, gpmReportType, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReportToFile(GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReportToFile(&this, gpmReportType, bstrTargetFilePath, ppIGPMResult);
}

[CRepr]struct IGPM2 : IGPM
{
	public new const Guid IID = .(0x00238f8a, 0x3d86, 0x41ac, 0x8f, 0x5e, 0x06, 0xa6, 0x63, 0x8a, 0x63, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IGPM.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBackupDir, GPMBackupType backupDirType, IGPMBackupDirEx** ppIGPMBackupDirEx) GetBackupDirEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmPath, int32 reportingOptions) InitializeReportingEx;
	}


	public HRESULT GetBackupDirEx(BSTR bstrBackupDir, GPMBackupType backupDirType, IGPMBackupDirEx** ppIGPMBackupDirEx) mut => VT.[Friend]GetBackupDirEx(&this, bstrBackupDir, backupDirType, ppIGPMBackupDirEx);

	public HRESULT InitializeReportingEx(BSTR bstrAdmPath, int32 reportingOptions) mut => VT.[Friend]InitializeReportingEx(&this, bstrAdmPath, reportingOptions);
}

[CRepr]struct IGPMStarterGPO : IDispatch
{
	public new const Guid IID = .(0xdfc3f61b, 0x8880, 0x4490, 0x93, 0x37, 0xd2, 0x9c, 0x7b, 0xa8, 0xc2, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Author;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Product;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_CreationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_ModifiedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMStarterGPOType* pVal) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pVal) get_ComputerVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pVal) get_UserVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_StarterGPOVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSaveFile, int16 bOverwrite, int16 bSaveAsSystem, VARIANT* bstrLanguage, VARIANT* bstrAuthor, VARIANT* bstrProduct, VARIANT* bstrUniqueID, VARIANT* bstrVersion, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBackupDir, BSTR bstrComment, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) Backup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarNewDisplayName, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) CopyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) GenerateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) GenerateReportToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo** ppSecurityInfo) GetSecurityInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSecurityInfo* pSecurityInfo) SetSecurityInfo;
	}


	public HRESULT get_DisplayName(BSTR* pVal) mut => VT.[Friend]get_DisplayName(&this, pVal);

	public HRESULT put_DisplayName(BSTR newVal) mut => VT.[Friend]put_DisplayName(&this, newVal);

	public HRESULT get_Description(BSTR* pVal) mut => VT.[Friend]get_Description(&this, pVal);

	public HRESULT put_Description(BSTR newVal) mut => VT.[Friend]put_Description(&this, newVal);

	public HRESULT get_Author(BSTR* pVal) mut => VT.[Friend]get_Author(&this, pVal);

	public HRESULT get_Product(BSTR* pVal) mut => VT.[Friend]get_Product(&this, pVal);

	public HRESULT get_CreationTime(double* pVal) mut => VT.[Friend]get_CreationTime(&this, pVal);

	public HRESULT get_ID(BSTR* pVal) mut => VT.[Friend]get_ID(&this, pVal);

	public HRESULT get_ModifiedTime(double* pVal) mut => VT.[Friend]get_ModifiedTime(&this, pVal);

	public HRESULT get_Type(GPMStarterGPOType* pVal) mut => VT.[Friend]get_Type(&this, pVal);

	public HRESULT get_ComputerVersion(uint16* pVal) mut => VT.[Friend]get_ComputerVersion(&this, pVal);

	public HRESULT get_UserVersion(uint16* pVal) mut => VT.[Friend]get_UserVersion(&this, pVal);

	public HRESULT get_StarterGPOVersion(BSTR* pVal) mut => VT.[Friend]get_StarterGPOVersion(&this, pVal);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Save(BSTR bstrSaveFile, int16 bOverwrite, int16 bSaveAsSystem, VARIANT* bstrLanguage, VARIANT* bstrAuthor, VARIANT* bstrProduct, VARIANT* bstrUniqueID, VARIANT* bstrVersion, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]Save(&this, bstrSaveFile, bOverwrite, bSaveAsSystem, bstrLanguage, bstrAuthor, bstrProduct, bstrUniqueID, bstrVersion, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT Backup(BSTR bstrBackupDir, BSTR bstrComment, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]Backup(&this, bstrBackupDir, bstrComment, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT CopyTo(VARIANT* pvarNewDisplayName, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]CopyTo(&this, pvarNewDisplayName, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReport(GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReport(&this, gpmReportType, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT GenerateReportToFile(GPMReportType gpmReportType, BSTR bstrTargetFilePath, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReportToFile(&this, gpmReportType, bstrTargetFilePath, ppIGPMResult);

	public HRESULT GetSecurityInfo(IGPMSecurityInfo** ppSecurityInfo) mut => VT.[Friend]GetSecurityInfo(&this, ppSecurityInfo);

	public HRESULT SetSecurityInfo(IGPMSecurityInfo* pSecurityInfo) mut => VT.[Friend]SetSecurityInfo(&this, pSecurityInfo);
}

[CRepr]struct IGPMStarterGPOCollection : IDispatch
{
	public new const Guid IID = .(0x2e522729, 0x2219, 0x44ad, 0x93, 0x3a, 0x64, 0xdf, 0xd6, 0x50, 0xc4, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** ppIGPMTemplates) get__NewEnum;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(int32 lIndex, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, lIndex, pVal);

	public HRESULT get__NewEnum(IEnumVARIANT** ppIGPMTemplates) mut => VT.[Friend]get__NewEnum(&this, ppIGPMTemplates);
}

[CRepr]struct IGPMDomain2 : IGPMDomain
{
	public new const Guid IID = .(0x7ca6bb8b, 0xf1eb, 0x490a, 0x93, 0x8d, 0x3c, 0x4e, 0x51, 0xc7, 0x68, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IGPMDomain.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMStarterGPO** ppnewTemplate) CreateStarterGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMStarterGPO* pGPOTemplate, IGPMGPO** ppnewGPO) CreateGPOFromStarterGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuid, IGPMStarterGPO** ppTemplate) GetStarterGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMSearchCriteria* pIGPMSearchCriteria, IGPMStarterGPOCollection** ppIGPMTemplateCollection) SearchStarterGPOs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLoadFile, int16 bOverwrite, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) LoadStarterGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGPMStarterGPOBackup* pIGPMTmplBackup, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) RestoreStarterGPO;
	}


	public HRESULT CreateStarterGPO(IGPMStarterGPO** ppnewTemplate) mut => VT.[Friend]CreateStarterGPO(&this, ppnewTemplate);

	public HRESULT CreateGPOFromStarterGPO(IGPMStarterGPO* pGPOTemplate, IGPMGPO** ppnewGPO) mut => VT.[Friend]CreateGPOFromStarterGPO(&this, pGPOTemplate, ppnewGPO);

	public HRESULT GetStarterGPO(BSTR bstrGuid, IGPMStarterGPO** ppTemplate) mut => VT.[Friend]GetStarterGPO(&this, bstrGuid, ppTemplate);

	public HRESULT SearchStarterGPOs(IGPMSearchCriteria* pIGPMSearchCriteria, IGPMStarterGPOCollection** ppIGPMTemplateCollection) mut => VT.[Friend]SearchStarterGPOs(&this, pIGPMSearchCriteria, ppIGPMTemplateCollection);

	public HRESULT LoadStarterGPO(BSTR bstrLoadFile, int16 bOverwrite, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]LoadStarterGPO(&this, bstrLoadFile, bOverwrite, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT RestoreStarterGPO(IGPMStarterGPOBackup* pIGPMTmplBackup, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]RestoreStarterGPO(&this, pIGPMTmplBackup, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);
}

[CRepr]struct IGPMConstants2 : IGPMConstants
{
	public new const Guid IID = .(0x05ae21b0, 0xac09, 0x4032, 0xa2, 0x6f, 0x9e, 0x7d, 0xa7, 0x86, 0xdc, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IGPMConstants.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMBackupType* pVal) get_BackupTypeGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMBackupType* pVal) get_BackupTypeStarterGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMStarterGPOType* pVal) get_StarterGPOTypeSystem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMStarterGPOType* pVal) get_StarterGPOTypeCustom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyStarterGPOPermissions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyStarterGPOEffectivePermissions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyStarterGPODisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyStarterGPOID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMSearchProperty* pVal) get_SearchPropertyStarterGPODomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermStarterGPORead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermStarterGPOEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermStarterGPOFullControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMPermissionType* pVal) get_PermStarterGPOCustom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportingOptions* pVal) get_ReportLegacy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportingOptions* pVal) get_ReportComments;
	}


	public HRESULT get_BackupTypeGPO(GPMBackupType* pVal) mut => VT.[Friend]get_BackupTypeGPO(&this, pVal);

	public HRESULT get_BackupTypeStarterGPO(GPMBackupType* pVal) mut => VT.[Friend]get_BackupTypeStarterGPO(&this, pVal);

	public HRESULT get_StarterGPOTypeSystem(GPMStarterGPOType* pVal) mut => VT.[Friend]get_StarterGPOTypeSystem(&this, pVal);

	public HRESULT get_StarterGPOTypeCustom(GPMStarterGPOType* pVal) mut => VT.[Friend]get_StarterGPOTypeCustom(&this, pVal);

	public HRESULT get_SearchPropertyStarterGPOPermissions(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyStarterGPOPermissions(&this, pVal);

	public HRESULT get_SearchPropertyStarterGPOEffectivePermissions(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyStarterGPOEffectivePermissions(&this, pVal);

	public HRESULT get_SearchPropertyStarterGPODisplayName(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyStarterGPODisplayName(&this, pVal);

	public HRESULT get_SearchPropertyStarterGPOID(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyStarterGPOID(&this, pVal);

	public HRESULT get_SearchPropertyStarterGPODomain(GPMSearchProperty* pVal) mut => VT.[Friend]get_SearchPropertyStarterGPODomain(&this, pVal);

	public HRESULT get_PermStarterGPORead(GPMPermissionType* pVal) mut => VT.[Friend]get_PermStarterGPORead(&this, pVal);

	public HRESULT get_PermStarterGPOEdit(GPMPermissionType* pVal) mut => VT.[Friend]get_PermStarterGPOEdit(&this, pVal);

	public HRESULT get_PermStarterGPOFullControl(GPMPermissionType* pVal) mut => VT.[Friend]get_PermStarterGPOFullControl(&this, pVal);

	public HRESULT get_PermStarterGPOCustom(GPMPermissionType* pVal) mut => VT.[Friend]get_PermStarterGPOCustom(&this, pVal);

	public HRESULT get_ReportLegacy(GPMReportingOptions* pVal) mut => VT.[Friend]get_ReportLegacy(&this, pVal);

	public HRESULT get_ReportComments(GPMReportingOptions* pVal) mut => VT.[Friend]get_ReportComments(&this, pVal);
}

[CRepr]struct IGPMGPO2 : IGPMGPO
{
	public new const Guid IID = .(0x8a66a210, 0xb78b, 0x4d99, 0x88, 0xe2, 0xc3, 0x06, 0xa8, 0x17, 0xc9, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IGPMGPO.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_Description;
	}


	public HRESULT get_Description(BSTR* pVal) mut => VT.[Friend]get_Description(&this, pVal);

	public HRESULT put_Description(BSTR newVal) mut => VT.[Friend]put_Description(&this, newVal);
}

[CRepr]struct IGPMDomain3 : IGPMDomain2
{
	public new const Guid IID = .(0x0077fdfe, 0x88c7, 0x4acf, 0xa1, 0x1d, 0xd1, 0x0a, 0x7c, 0x31, 0x0a, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IGPMDomain2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) GenerateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_InfrastructureDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_InfrastructureDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) put_InfrastructureFlags;
	}


	public HRESULT GenerateReport(GPMReportType gpmReportType, VARIANT* pvarGPMProgress, VARIANT* pvarGPMCancel, IGPMResult** ppIGPMResult) mut => VT.[Friend]GenerateReport(&this, gpmReportType, pvarGPMProgress, pvarGPMCancel, ppIGPMResult);

	public HRESULT get_InfrastructureDC(BSTR* pVal) mut => VT.[Friend]get_InfrastructureDC(&this, pVal);

	public HRESULT put_InfrastructureDC(BSTR newVal) mut => VT.[Friend]put_InfrastructureDC(&this, newVal);

	public HRESULT put_InfrastructureFlags(uint32 dwFlags) mut => VT.[Friend]put_InfrastructureFlags(&this, dwFlags);
}

[CRepr]struct IGPMGPO3 : IGPMGPO2
{
	public new const Guid IID = .(0x7cf123a1, 0xf94a, 0x4112, 0xbf, 0xae, 0x6a, 0xa1, 0xdb, 0x9c, 0xb2, 0x48);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IGPMGPO2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_InfrastructureDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_InfrastructureDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) put_InfrastructureFlags;
	}


	public HRESULT get_InfrastructureDC(BSTR* pVal) mut => VT.[Friend]get_InfrastructureDC(&this, pVal);

	public HRESULT put_InfrastructureDC(BSTR newVal) mut => VT.[Friend]put_InfrastructureDC(&this, newVal);

	public HRESULT put_InfrastructureFlags(uint32 dwFlags) mut => VT.[Friend]put_InfrastructureFlags(&this, dwFlags);
}

[CRepr]struct IGPEInformation : IUnknown
{
	public new const Guid IID = .(0x8fc0b735, 0xa0e1, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cchMaxLength) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cchMaxLength) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, HKEY* hKey) GetRegistryKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, char16* pszPath, int32 cchMaxPath) GetDSPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, char16* pszPath, int32 cchMaxPath) GetFileSysPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dwOptions) GetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GROUP_POLICY_OBJECT_TYPE* gpoType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GROUP_POLICY_HINT_TYPE* gpHint) GetHint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMachine, BOOL bAdd, Guid* pGuidExtension, Guid* pGuidSnapin) PolicyChanged;
	}


	public HRESULT GetName(char16* pszName, int32 cchMaxLength) mut => VT.[Friend]GetName(&this, pszName, cchMaxLength);

	public HRESULT GetDisplayName(char16* pszName, int32 cchMaxLength) mut => VT.[Friend]GetDisplayName(&this, pszName, cchMaxLength);

	public HRESULT GetRegistryKey(uint32 dwSection, HKEY* hKey) mut => VT.[Friend]GetRegistryKey(&this, dwSection, hKey);

	public HRESULT GetDSPath(uint32 dwSection, char16* pszPath, int32 cchMaxPath) mut => VT.[Friend]GetDSPath(&this, dwSection, pszPath, cchMaxPath);

	public HRESULT GetFileSysPath(uint32 dwSection, char16* pszPath, int32 cchMaxPath) mut => VT.[Friend]GetFileSysPath(&this, dwSection, pszPath, cchMaxPath);

	public HRESULT GetOptions(uint32* dwOptions) mut => VT.[Friend]GetOptions(&this, dwOptions);

	public HRESULT GetType(GROUP_POLICY_OBJECT_TYPE* gpoType) mut => VT.[Friend]COM_GetType(&this, gpoType);

	public HRESULT GetHint(GROUP_POLICY_HINT_TYPE* gpHint) mut => VT.[Friend]GetHint(&this, gpHint);

	public HRESULT PolicyChanged(BOOL bMachine, BOOL bAdd, Guid* pGuidExtension, Guid* pGuidSnapin) mut => VT.[Friend]PolicyChanged(&this, bMachine, bAdd, pGuidExtension, pGuidSnapin);
}

[CRepr]struct IGroupPolicyObject : IUnknown
{
	public new const Guid IID = .(0xea502723, 0xa23d, 0x11d1, 0xa7, 0xd3, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDomainName, PWSTR pszDisplayName, uint32 dwFlags) New;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, uint32 dwFlags) OpenDSGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) OpenLocalMachineGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszComputerName, uint32 dwFlags) OpenRemoteMachineGPO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMachine, BOOL bAdd, Guid* pGuidExtension, Guid* pGuid) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cchMaxLength) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cchMaxLength) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) SetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszPath, int32 cchMaxLength) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, char16* pszPath, int32 cchMaxPath) GetDSPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, char16* pszPath, int32 cchMaxPath) GetFileSysPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, HKEY* hKey) GetRegistryKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dwOptions) GetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOptions, uint32 dwMask) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GROUP_POLICY_OBJECT_TYPE* gpoType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cchMaxLength) GetMachineName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE** hPages, uint32* uPageCount) GetPropertySheetPages;
	}


	public HRESULT New(PWSTR pszDomainName, PWSTR pszDisplayName, uint32 dwFlags) mut => VT.[Friend]New(&this, pszDomainName, pszDisplayName, dwFlags);

	public HRESULT OpenDSGPO(PWSTR pszPath, uint32 dwFlags) mut => VT.[Friend]OpenDSGPO(&this, pszPath, dwFlags);

	public HRESULT OpenLocalMachineGPO(uint32 dwFlags) mut => VT.[Friend]OpenLocalMachineGPO(&this, dwFlags);

	public HRESULT OpenRemoteMachineGPO(PWSTR pszComputerName, uint32 dwFlags) mut => VT.[Friend]OpenRemoteMachineGPO(&this, pszComputerName, dwFlags);

	public HRESULT Save(BOOL bMachine, BOOL bAdd, Guid* pGuidExtension, Guid* pGuid) mut => VT.[Friend]Save(&this, bMachine, bAdd, pGuidExtension, pGuid);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT GetName(char16* pszName, int32 cchMaxLength) mut => VT.[Friend]GetName(&this, pszName, cchMaxLength);

	public HRESULT GetDisplayName(char16* pszName, int32 cchMaxLength) mut => VT.[Friend]GetDisplayName(&this, pszName, cchMaxLength);

	public HRESULT SetDisplayName(PWSTR pszName) mut => VT.[Friend]SetDisplayName(&this, pszName);

	public HRESULT GetPath(char16* pszPath, int32 cchMaxLength) mut => VT.[Friend]GetPath(&this, pszPath, cchMaxLength);

	public HRESULT GetDSPath(uint32 dwSection, char16* pszPath, int32 cchMaxPath) mut => VT.[Friend]GetDSPath(&this, dwSection, pszPath, cchMaxPath);

	public HRESULT GetFileSysPath(uint32 dwSection, char16* pszPath, int32 cchMaxPath) mut => VT.[Friend]GetFileSysPath(&this, dwSection, pszPath, cchMaxPath);

	public HRESULT GetRegistryKey(uint32 dwSection, HKEY* hKey) mut => VT.[Friend]GetRegistryKey(&this, dwSection, hKey);

	public HRESULT GetOptions(uint32* dwOptions) mut => VT.[Friend]GetOptions(&this, dwOptions);

	public HRESULT SetOptions(uint32 dwOptions, uint32 dwMask) mut => VT.[Friend]SetOptions(&this, dwOptions, dwMask);

	public HRESULT GetType(GROUP_POLICY_OBJECT_TYPE* gpoType) mut => VT.[Friend]COM_GetType(&this, gpoType);

	public HRESULT GetMachineName(char16* pszName, int32 cchMaxLength) mut => VT.[Friend]GetMachineName(&this, pszName, cchMaxLength);

	public HRESULT GetPropertySheetPages(HPROPSHEETPAGE** hPages, uint32* uPageCount) mut => VT.[Friend]GetPropertySheetPages(&this, hPages, uPageCount);
}

[CRepr]struct IRSOPInformation : IUnknown
{
	public new const Guid IID = .(0x9a5a81b5, 0xd9c7, 0x49ef, 0x9d, 0x11, 0xdd, 0xf5, 0x09, 0x68, 0xc4, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSection, char16* pszName, int32 cchMaxLength) GetNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszEventSource, PWSTR pszEventLogName, PWSTR pszEventTime, uint32 dwEventID, PWSTR* ppszText) GetEventLogEntryText;
	}


	public HRESULT GetNamespace(uint32 dwSection, char16* pszName, int32 cchMaxLength) mut => VT.[Friend]GetNamespace(&this, dwSection, pszName, cchMaxLength);

	public HRESULT GetFlags(uint32* pdwFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwFlags);

	public HRESULT GetEventLogEntryText(PWSTR pszEventSource, PWSTR pszEventLogName, PWSTR pszEventTime, uint32 dwEventID, PWSTR* ppszText) mut => VT.[Friend]GetEventLogEntryText(&this, pszEventSource, pszEventLogName, pszEventTime, dwEventID, ppszText);
}

#endregion

#region Functions
public static
{
	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RefreshPolicy(BOOL bMachine);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RefreshPolicyEx(BOOL bMachine, uint32 dwOptions);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE EnterCriticalPolicySection(BOOL bMachine);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LeaveCriticalPolicySection(HANDLE hSection);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterGPNotification(HANDLE hEvent, BOOL bMachine);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterGPNotification(HANDLE hEvent);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetGPOListA(HANDLE hToken, PSTR lpName, PSTR lpHostName, PSTR lpComputerName, uint32 dwFlags, GROUP_POLICY_OBJECTA** pGPOList);
	public static BOOL GetGPOList(HANDLE hToken, PSTR lpName, PSTR lpHostName, PSTR lpComputerName, uint32 dwFlags, GROUP_POLICY_OBJECTA** pGPOList) => GetGPOListA(hToken, lpName, lpHostName, lpComputerName, dwFlags, pGPOList);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetGPOListW(HANDLE hToken, PWSTR lpName, PWSTR lpHostName, PWSTR lpComputerName, uint32 dwFlags, GROUP_POLICY_OBJECTW** pGPOList);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeGPOListA(GROUP_POLICY_OBJECTA* pGPOList);
	public static BOOL FreeGPOList(GROUP_POLICY_OBJECTA* pGPOList) => FreeGPOListA(pGPOList);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeGPOListW(GROUP_POLICY_OBJECTW* pGPOList);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetAppliedGPOListA(uint32 dwFlags, PSTR pMachineName, PSID pSidUser, Guid* pGuidExtension, GROUP_POLICY_OBJECTA** ppGPOList);
	public static uint32 GetAppliedGPOList(uint32 dwFlags, PSTR pMachineName, PSID pSidUser, Guid* pGuidExtension, GROUP_POLICY_OBJECTA** ppGPOList) => GetAppliedGPOListA(dwFlags, pMachineName, pSidUser, pGuidExtension, ppGPOList);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetAppliedGPOListW(uint32 dwFlags, PWSTR pMachineName, PSID pSidUser, Guid* pGuidExtension, GROUP_POLICY_OBJECTW** ppGPOList);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ProcessGroupPolicyCompleted(Guid* extensionId, uint pAsyncHandle, uint32 dwStatus);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ProcessGroupPolicyCompletedEx(Guid* extensionId, uint pAsyncHandle, uint32 dwStatus, HRESULT RsopStatus);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RsopAccessCheckByType(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID pPrincipalSelfSid, void* pRsopToken, uint32 dwDesiredAccessMask, OBJECT_TYPE_LIST* pObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* pGenericMapping, PRIVILEGE_SET* pPrivilegeSet, uint32* pdwPrivilegeSetLength, uint32* pdwGrantedAccessMask, int32* pbAccessStatus);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RsopFileAccessCheck(PWSTR pszFileName, void* pRsopToken, uint32 dwDesiredAccessMask, uint32* pdwGrantedAccessMask, int32* pbAccessStatus);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RsopSetPolicySettingStatus(uint32 dwFlags, IWbemServices* pServices, IWbemClassObject* pSettingInstance, uint32 nInfo, POLICYSETTINGSTATUSINFO* pStatus);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RsopResetPolicySettingStatus(uint32 dwFlags, IWbemServices* pServices, IWbemClassObject* pSettingInstance);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GenerateGPNotification(BOOL bMachine, PWSTR lpwszMgmtProduct, uint32 dwMgmtProductOptions);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 InstallApplication(INSTALLDATA* pInstallInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 UninstallApplication(PWSTR ProductCode, uint32 dwStatus);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CommandLineFromMsiDescriptor(PWSTR Descriptor, char16* CommandLine, uint32* CommandLineLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetManagedApplications(Guid* pCategory, uint32 dwQueryFlags, uint32 dwInfoLevel, uint32* pdwApps, MANAGEDAPPLICATION** prgManagedApps);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLocalManagedApplications(BOOL bUserApps, uint32* pdwApps, LOCALMANAGEDAPPLICATION** prgLocalApps);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetLocalManagedApplicationData(PWSTR ProductCode, PWSTR* DisplayName, PWSTR* SupportUrl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetManagedApplicationCategories(uint32 dwReserved, APPCATEGORYINFOLIST* pAppCategory);

	[Import("GPEDIT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateGPOLink(PWSTR lpGPO, PWSTR lpContainer, BOOL fHighPriority);

	[Import("GPEDIT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeleteGPOLink(PWSTR lpGPO, PWSTR lpContainer);

	[Import("GPEDIT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeleteAllGPOLinks(PWSTR lpContainer);

	[Import("GPEDIT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BrowseForGPO(GPOBROWSEINFO* lpBrowseInfo);

	[Import("GPEDIT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImportRSoPData(PWSTR lpNameSpace, PWSTR lpFileName);

	[Import("GPEDIT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExportRSoPData(PWSTR lpNameSpace, PWSTR lpFileName);

}
#endregion
