using Win32.System.Diagnostics.Debug;
using Win32.Foundation;
using System;

namespace Win32.System.SystemInformation;

#region Constants
public static
{
	public const uint32 NTDDI_WIN2K = 83886080;
	public const uint32 NTDDI_WINXP = 83951616;
	public const uint32 NTDDI_WINXPSP2 = 83952128;
	public const uint32 NTDDI_WS03SP1 = 84017408;
	public const uint32 NTDDI_VISTA = 100663296;
	public const uint32 NTDDI_VISTASP1 = 100663552;
	public const uint32 NTDDI_WIN7 = 100728832;
	public const uint32 NTDDI_WIN8 = 100794368;
	public const uint32 NTDDI_WINBLUE = 100859904;
	public const uint32 NTDDI_WINTHRESHOLD = 167772160;
	public const uint32 SYSTEM_CPU_SET_INFORMATION_PARKED = 1;
	public const uint32 SYSTEM_CPU_SET_INFORMATION_ALLOCATED = 2;
	public const uint32 SYSTEM_CPU_SET_INFORMATION_ALLOCATED_TO_TARGET_PROCESS = 4;
	public const uint32 SYSTEM_CPU_SET_INFORMATION_REALTIME = 8;
	public const uint32 _WIN32_WINNT_NT4 = 1024;
	public const uint32 _WIN32_WINNT_WIN2K = 1280;
	public const uint32 _WIN32_WINNT_WINXP = 1281;
	public const uint32 _WIN32_WINNT_WS03 = 1282;
	public const uint32 _WIN32_WINNT_WIN6 = 1536;
	public const uint32 _WIN32_WINNT_VISTA = 1536;
	public const uint32 _WIN32_WINNT_WS08 = 1536;
	public const uint32 _WIN32_WINNT_LONGHORN = 1536;
	public const uint32 _WIN32_WINNT_WIN7 = 1537;
	public const uint32 _WIN32_WINNT_WIN8 = 1538;
	public const uint32 _WIN32_WINNT_WINBLUE = 1539;
	public const uint32 _WIN32_WINNT_WINTHRESHOLD = 2560;
	public const uint32 _WIN32_WINNT_WIN10 = 2560;
	public const uint32 _WIN32_IE_IE20 = 512;
	public const uint32 _WIN32_IE_IE30 = 768;
	public const uint32 _WIN32_IE_IE302 = 770;
	public const uint32 _WIN32_IE_IE40 = 1024;
	public const uint32 _WIN32_IE_IE401 = 1025;
	public const uint32 _WIN32_IE_IE50 = 1280;
	public const uint32 _WIN32_IE_IE501 = 1281;
	public const uint32 _WIN32_IE_IE55 = 1360;
	public const uint32 _WIN32_IE_IE60 = 1536;
	public const uint32 _WIN32_IE_IE60SP1 = 1537;
	public const uint32 _WIN32_IE_IE60SP2 = 1539;
	public const uint32 _WIN32_IE_IE70 = 1792;
	public const uint32 _WIN32_IE_IE80 = 2048;
	public const uint32 _WIN32_IE_IE90 = 2304;
	public const uint32 _WIN32_IE_IE100 = 2560;
	public const uint32 _WIN32_IE_IE110 = 2560;
	public const uint32 _WIN32_IE_NT4 = 512;
	public const uint32 _WIN32_IE_NT4SP1 = 512;
	public const uint32 _WIN32_IE_NT4SP2 = 512;
	public const uint32 _WIN32_IE_NT4SP3 = 770;
	public const uint32 _WIN32_IE_NT4SP4 = 1025;
	public const uint32 _WIN32_IE_NT4SP5 = 1025;
	public const uint32 _WIN32_IE_NT4SP6 = 1280;
	public const uint32 _WIN32_IE_WIN98 = 1025;
	public const uint32 _WIN32_IE_WIN98SE = 1280;
	public const uint32 _WIN32_IE_WINME = 1360;
	public const uint32 _WIN32_IE_WIN2K = 1281;
	public const uint32 _WIN32_IE_WIN2KSP1 = 1281;
	public const uint32 _WIN32_IE_WIN2KSP2 = 1281;
	public const uint32 _WIN32_IE_WIN2KSP3 = 1281;
	public const uint32 _WIN32_IE_WIN2KSP4 = 1281;
	public const uint32 _WIN32_IE_XP = 1536;
	public const uint32 _WIN32_IE_XPSP1 = 1537;
	public const uint32 _WIN32_IE_XPSP2 = 1539;
	public const uint32 _WIN32_IE_WS03 = 1538;
	public const uint32 _WIN32_IE_WS03SP1 = 1539;
	public const uint32 _WIN32_IE_WIN6 = 1792;
	public const uint32 _WIN32_IE_LONGHORN = 1792;
	public const uint32 _WIN32_IE_WIN7 = 2048;
	public const uint32 _WIN32_IE_WIN8 = 2560;
	public const uint32 _WIN32_IE_WINBLUE = 2560;
	public const uint32 _WIN32_IE_WINTHRESHOLD = 2560;
	public const uint32 _WIN32_IE_WIN10 = 2560;
	public const uint32 NTDDI_WIN4 = 67108864;
	public const uint32 NTDDI_WIN2KSP1 = 83886336;
	public const uint32 NTDDI_WIN2KSP2 = 83886592;
	public const uint32 NTDDI_WIN2KSP3 = 83886848;
	public const uint32 NTDDI_WIN2KSP4 = 83887104;
	public const uint32 NTDDI_WINXPSP1 = 83951872;
	public const uint32 NTDDI_WINXPSP3 = 83952384;
	public const uint32 NTDDI_WINXPSP4 = 83952640;
	public const uint32 NTDDI_WS03 = 84017152;
	public const uint32 NTDDI_WS03SP2 = 84017664;
	public const uint32 NTDDI_WS03SP3 = 84017920;
	public const uint32 NTDDI_WS03SP4 = 84018176;
	public const uint32 NTDDI_WIN6 = 100663296;
	public const uint32 NTDDI_WIN6SP1 = 100663552;
	public const uint32 NTDDI_WIN6SP2 = 100663808;
	public const uint32 NTDDI_WIN6SP3 = 100664064;
	public const uint32 NTDDI_WIN6SP4 = 100664320;
	public const uint32 NTDDI_VISTASP2 = 100663808;
	public const uint32 NTDDI_VISTASP3 = 100664064;
	public const uint32 NTDDI_VISTASP4 = 100664320;
	public const uint32 NTDDI_LONGHORN = 100663296;
	public const uint32 NTDDI_WS08 = 100663552;
	public const uint32 NTDDI_WS08SP2 = 100663808;
	public const uint32 NTDDI_WS08SP3 = 100664064;
	public const uint32 NTDDI_WS08SP4 = 100664320;
	public const uint32 NTDDI_WIN10 = 167772160;
	public const uint32 NTDDI_WIN10_TH2 = 167772161;
	public const uint32 NTDDI_WIN10_RS1 = 167772162;
	public const uint32 NTDDI_WIN10_RS2 = 167772163;
	public const uint32 NTDDI_WIN10_RS3 = 167772164;
	public const uint32 NTDDI_WIN10_RS4 = 167772165;
	public const uint32 NTDDI_WIN10_RS5 = 167772166;
	public const uint32 NTDDI_WIN10_19H1 = 167772167;
	public const uint32 NTDDI_WIN10_VB = 167772168;
	public const uint32 NTDDI_WIN10_MN = 167772169;
	public const uint32 NTDDI_WIN10_FE = 167772170;
	public const uint32 NTDDI_WIN10_CO = 167772171;
	public const uint32 WDK_NTDDI_VERSION = 167772171;
	public const uint32 OSVERSION_MASK = 4294901760;
	public const uint32 SPVERSION_MASK = 65280;
	public const uint32 SUBVERSION_MASK = 255;
	public const uint32 NTDDI_VERSION = 167772171;
	public const uint32 SCEX2_ALT_NETBIOS_NAME = 1;
}
#endregion

#region TypeDefs
typealias FIRMWARE_TABLE_ID = uint32;

#endregion


#region Enums

[AllowDuplicates]
public enum VER_FLAGS : uint32
{
	VER_MINORVERSION = 1,
	VER_MAJORVERSION = 2,
	VER_BUILDNUMBER = 4,
	VER_PLATFORMID = 8,
	VER_SERVICEPACKMINOR = 16,
	VER_SERVICEPACKMAJOR = 32,
	VER_SUITENAME = 64,
	VER_PRODUCT_TYPE = 128,
}


[AllowDuplicates]
public enum IMAGE_FILE_MACHINE : uint16
{
	IMAGE_FILE_MACHINE_AXP64 = 644,
	IMAGE_FILE_MACHINE_I386 = 332,
	IMAGE_FILE_MACHINE_IA64 = 512,
	IMAGE_FILE_MACHINE_AMD64 = 34404,
	IMAGE_FILE_MACHINE_UNKNOWN = 0,
	IMAGE_FILE_MACHINE_TARGET_HOST = 1,
	IMAGE_FILE_MACHINE_R3000 = 354,
	IMAGE_FILE_MACHINE_R4000 = 358,
	IMAGE_FILE_MACHINE_R10000 = 360,
	IMAGE_FILE_MACHINE_WCEMIPSV2 = 361,
	IMAGE_FILE_MACHINE_ALPHA = 388,
	IMAGE_FILE_MACHINE_SH3 = 418,
	IMAGE_FILE_MACHINE_SH3DSP = 419,
	IMAGE_FILE_MACHINE_SH3E = 420,
	IMAGE_FILE_MACHINE_SH4 = 422,
	IMAGE_FILE_MACHINE_SH5 = 424,
	IMAGE_FILE_MACHINE_ARM = 448,
	IMAGE_FILE_MACHINE_THUMB = 450,
	IMAGE_FILE_MACHINE_ARMNT = 452,
	IMAGE_FILE_MACHINE_AM33 = 467,
	IMAGE_FILE_MACHINE_POWERPC = 496,
	IMAGE_FILE_MACHINE_POWERPCFP = 497,
	IMAGE_FILE_MACHINE_MIPS16 = 614,
	IMAGE_FILE_MACHINE_ALPHA64 = 644,
	IMAGE_FILE_MACHINE_MIPSFPU = 870,
	IMAGE_FILE_MACHINE_MIPSFPU16 = 1126,
	IMAGE_FILE_MACHINE_TRICORE = 1312,
	IMAGE_FILE_MACHINE_CEF = 3311,
	IMAGE_FILE_MACHINE_EBC = 3772,
	IMAGE_FILE_MACHINE_M32R = 36929,
	IMAGE_FILE_MACHINE_ARM64 = 43620,
	IMAGE_FILE_MACHINE_CEE = 49390,
}


[AllowDuplicates]
public enum FIRMWARE_TABLE_PROVIDER : uint32
{
	ACPI = 1094930505,
	FIRM = 1179210317,
	RSMB = 1381190978,
}


[AllowDuplicates]
public enum USER_CET_ENVIRONMENT : uint32
{
	USER_CET_ENVIRONMENT_WIN32_PROCESS = 0,
	USER_CET_ENVIRONMENT_SGX2_ENCLAVE = 2,
	USER_CET_ENVIRONMENT_VBS_ENCLAVE = 16,
	USER_CET_ENVIRONMENT_VBS_BASIC_ENCLAVE = 17,
}


[AllowDuplicates]
public enum OS_PRODUCT_TYPE : uint32
{
	PRODUCT_BUSINESS = 6,
	PRODUCT_BUSINESS_N = 16,
	PRODUCT_CLUSTER_SERVER = 18,
	PRODUCT_CLUSTER_SERVER_V = 64,
	PRODUCT_CORE = 101,
	PRODUCT_CORE_COUNTRYSPECIFIC = 99,
	PRODUCT_CORE_N = 98,
	PRODUCT_CORE_SINGLELANGUAGE = 100,
	PRODUCT_DATACENTER_EVALUATION_SERVER = 80,
	PRODUCT_DATACENTER_A_SERVER_CORE = 145,
	PRODUCT_STANDARD_A_SERVER_CORE = 146,
	PRODUCT_DATACENTER_SERVER = 8,
	PRODUCT_DATACENTER_SERVER_CORE = 12,
	PRODUCT_DATACENTER_SERVER_CORE_V = 39,
	PRODUCT_DATACENTER_SERVER_V = 37,
	PRODUCT_EDUCATION = 121,
	PRODUCT_EDUCATION_N = 122,
	PRODUCT_ENTERPRISE = 4,
	PRODUCT_ENTERPRISE_E = 70,
	PRODUCT_ENTERPRISE_EVALUATION = 72,
	PRODUCT_ENTERPRISE_N = 27,
	PRODUCT_ENTERPRISE_N_EVALUATION = 84,
	PRODUCT_ENTERPRISE_S = 125,
	PRODUCT_ENTERPRISE_S_EVALUATION = 129,
	PRODUCT_ENTERPRISE_S_N = 126,
	PRODUCT_ENTERPRISE_S_N_EVALUATION = 130,
	PRODUCT_ENTERPRISE_SERVER = 10,
	PRODUCT_ENTERPRISE_SERVER_CORE = 14,
	PRODUCT_ENTERPRISE_SERVER_CORE_V = 41,
	PRODUCT_ENTERPRISE_SERVER_IA64 = 15,
	PRODUCT_ENTERPRISE_SERVER_V = 38,
	PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL = 60,
	PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC = 62,
	PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT = 59,
	PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC = 61,
	PRODUCT_HOME_BASIC = 2,
	PRODUCT_HOME_BASIC_E = 67,
	PRODUCT_HOME_BASIC_N = 5,
	PRODUCT_HOME_PREMIUM = 3,
	PRODUCT_HOME_PREMIUM_E = 68,
	PRODUCT_HOME_PREMIUM_N = 26,
	PRODUCT_HOME_PREMIUM_SERVER = 34,
	PRODUCT_HOME_SERVER = 19,
	PRODUCT_HYPERV = 42,
	PRODUCT_IOTUAP = 123,
	PRODUCT_IOTUAPCOMMERCIAL = 131,
	PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT = 30,
	PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING = 32,
	PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY = 31,
	PRODUCT_MOBILE_CORE = 104,
	PRODUCT_MOBILE_ENTERPRISE = 133,
	PRODUCT_MULTIPOINT_PREMIUM_SERVER = 77,
	PRODUCT_MULTIPOINT_STANDARD_SERVER = 76,
	PRODUCT_PRO_WORKSTATION = 161,
	PRODUCT_PRO_WORKSTATION_N = 162,
	PRODUCT_PROFESSIONAL = 48,
	PRODUCT_PROFESSIONAL_E = 69,
	PRODUCT_PROFESSIONAL_N = 49,
	PRODUCT_PROFESSIONAL_WMC = 103,
	PRODUCT_SB_SOLUTION_SERVER = 50,
	PRODUCT_SB_SOLUTION_SERVER_EM = 54,
	PRODUCT_SERVER_FOR_SB_SOLUTIONS = 51,
	PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM = 55,
	PRODUCT_SERVER_FOR_SMALLBUSINESS = 24,
	PRODUCT_SERVER_FOR_SMALLBUSINESS_V = 35,
	PRODUCT_SERVER_FOUNDATION = 33,
	PRODUCT_SMALLBUSINESS_SERVER = 9,
	PRODUCT_SMALLBUSINESS_SERVER_PREMIUM = 25,
	PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE = 63,
	PRODUCT_SOLUTION_EMBEDDEDSERVER = 56,
	PRODUCT_STANDARD_EVALUATION_SERVER = 79,
	PRODUCT_STANDARD_SERVER = 7,
	PRODUCT_STANDARD_SERVER_CORE_ = 13,
	PRODUCT_STANDARD_SERVER_CORE_V = 40,
	PRODUCT_STANDARD_SERVER_V = 36,
	PRODUCT_STANDARD_SERVER_SOLUTIONS = 52,
	PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE = 53,
	PRODUCT_STARTER = 11,
	PRODUCT_STARTER_E = 66,
	PRODUCT_STARTER_N = 47,
	PRODUCT_STORAGE_ENTERPRISE_SERVER = 23,
	PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE = 46,
	PRODUCT_STORAGE_EXPRESS_SERVER = 20,
	PRODUCT_STORAGE_EXPRESS_SERVER_CORE = 43,
	PRODUCT_STORAGE_STANDARD_EVALUATION_SERVER = 96,
	PRODUCT_STORAGE_STANDARD_SERVER = 21,
	PRODUCT_STORAGE_STANDARD_SERVER_CORE = 44,
	PRODUCT_STORAGE_WORKGROUP_EVALUATION_SERVER = 95,
	PRODUCT_STORAGE_WORKGROUP_SERVER = 22,
	PRODUCT_STORAGE_WORKGROUP_SERVER_CORE = 45,
	PRODUCT_ULTIMATE = 1,
	PRODUCT_ULTIMATE_E = 71,
	PRODUCT_ULTIMATE_N = 28,
	PRODUCT_UNDEFINED = 0,
	PRODUCT_WEB_SERVER = 17,
	PRODUCT_WEB_SERVER_CORE = 29,
}


[AllowDuplicates]
public enum DEVICEFAMILYINFOENUM : uint32
{
	DEVICEFAMILYINFOENUM_UAP = 0,
	DEVICEFAMILYINFOENUM_WINDOWS_8X = 1,
	DEVICEFAMILYINFOENUM_WINDOWS_PHONE_8X = 2,
	DEVICEFAMILYINFOENUM_DESKTOP = 3,
	DEVICEFAMILYINFOENUM_MOBILE = 4,
	DEVICEFAMILYINFOENUM_XBOX = 5,
	DEVICEFAMILYINFOENUM_TEAM = 6,
	DEVICEFAMILYINFOENUM_IOT = 7,
	DEVICEFAMILYINFOENUM_IOT_HEADLESS = 8,
	DEVICEFAMILYINFOENUM_SERVER = 9,
	DEVICEFAMILYINFOENUM_HOLOGRAPHIC = 10,
	DEVICEFAMILYINFOENUM_XBOXSRA = 11,
	DEVICEFAMILYINFOENUM_XBOXERA = 12,
	DEVICEFAMILYINFOENUM_SERVER_NANO = 13,
	DEVICEFAMILYINFOENUM_8828080 = 14,
	DEVICEFAMILYINFOENUM_7067329 = 15,
	DEVICEFAMILYINFOENUM_WINDOWS_CORE = 16,
	DEVICEFAMILYINFOENUM_WINDOWS_CORE_HEADLESS = 17,
	DEVICEFAMILYINFOENUM_MAX = 17,
}


[AllowDuplicates]
public enum DEVICEFAMILYDEVICEFORM : uint32
{
	DEVICEFAMILYDEVICEFORM_UNKNOWN = 0,
	DEVICEFAMILYDEVICEFORM_PHONE = 1,
	DEVICEFAMILYDEVICEFORM_TABLET = 2,
	DEVICEFAMILYDEVICEFORM_DESKTOP = 3,
	DEVICEFAMILYDEVICEFORM_NOTEBOOK = 4,
	DEVICEFAMILYDEVICEFORM_CONVERTIBLE = 5,
	DEVICEFAMILYDEVICEFORM_DETACHABLE = 6,
	DEVICEFAMILYDEVICEFORM_ALLINONE = 7,
	DEVICEFAMILYDEVICEFORM_STICKPC = 8,
	DEVICEFAMILYDEVICEFORM_PUCK = 9,
	DEVICEFAMILYDEVICEFORM_LARGESCREEN = 10,
	DEVICEFAMILYDEVICEFORM_HMD = 11,
	DEVICEFAMILYDEVICEFORM_INDUSTRY_HANDHELD = 12,
	DEVICEFAMILYDEVICEFORM_INDUSTRY_TABLET = 13,
	DEVICEFAMILYDEVICEFORM_BANKING = 14,
	DEVICEFAMILYDEVICEFORM_BUILDING_AUTOMATION = 15,
	DEVICEFAMILYDEVICEFORM_DIGITAL_SIGNAGE = 16,
	DEVICEFAMILYDEVICEFORM_GAMING = 17,
	DEVICEFAMILYDEVICEFORM_HOME_AUTOMATION = 18,
	DEVICEFAMILYDEVICEFORM_INDUSTRIAL_AUTOMATION = 19,
	DEVICEFAMILYDEVICEFORM_KIOSK = 20,
	DEVICEFAMILYDEVICEFORM_MAKER_BOARD = 21,
	DEVICEFAMILYDEVICEFORM_MEDICAL = 22,
	DEVICEFAMILYDEVICEFORM_NETWORKING = 23,
	DEVICEFAMILYDEVICEFORM_POINT_OF_SERVICE = 24,
	DEVICEFAMILYDEVICEFORM_PRINTING = 25,
	DEVICEFAMILYDEVICEFORM_THIN_CLIENT = 26,
	DEVICEFAMILYDEVICEFORM_TOY = 27,
	DEVICEFAMILYDEVICEFORM_VENDING = 28,
	DEVICEFAMILYDEVICEFORM_INDUSTRY_OTHER = 29,
	DEVICEFAMILYDEVICEFORM_XBOX_ONE = 30,
	DEVICEFAMILYDEVICEFORM_XBOX_ONE_S = 31,
	DEVICEFAMILYDEVICEFORM_XBOX_ONE_X = 32,
	DEVICEFAMILYDEVICEFORM_XBOX_ONE_X_DEVKIT = 33,
	DEVICEFAMILYDEVICEFORM_XBOX_SERIES_X = 34,
	DEVICEFAMILYDEVICEFORM_XBOX_SERIES_X_DEVKIT = 35,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_00 = 36,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_01 = 37,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_02 = 38,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_03 = 39,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_04 = 40,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_05 = 41,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_06 = 42,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_07 = 43,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_08 = 44,
	DEVICEFAMILYDEVICEFORM_XBOX_RESERVED_09 = 45,
	DEVICEFAMILYDEVICEFORM_MAX = 45,
}


[AllowDuplicates]
public enum COMPUTER_NAME_FORMAT : int32
{
	ComputerNameNetBIOS = 0,
	ComputerNameDnsHostname = 1,
	ComputerNameDnsDomain = 2,
	ComputerNameDnsFullyQualified = 3,
	ComputerNamePhysicalNetBIOS = 4,
	ComputerNamePhysicalDnsHostname = 5,
	ComputerNamePhysicalDnsDomain = 6,
	ComputerNamePhysicalDnsFullyQualified = 7,
	ComputerNameMax = 8,
}


[AllowDuplicates]
public enum FIRMWARE_TYPE : int32
{
	FirmwareTypeUnknown = 0,
	FirmwareTypeBios = 1,
	FirmwareTypeUefi = 2,
	FirmwareTypeMax = 3,
}


[AllowDuplicates]
public enum LOGICAL_PROCESSOR_RELATIONSHIP : int32
{
	RelationProcessorCore = 0,
	RelationNumaNode = 1,
	RelationCache = 2,
	RelationProcessorPackage = 3,
	RelationGroup = 4,
	RelationProcessorDie = 5,
	RelationNumaNodeEx = 6,
	RelationProcessorModule = 7,
	RelationAll = 65535,
}


[AllowDuplicates]
public enum PROCESSOR_CACHE_TYPE : int32
{
	CacheUnified = 0,
	CacheInstruction = 1,
	CacheData = 2,
	CacheTrace = 3,
}


[AllowDuplicates]
public enum CPU_SET_INFORMATION_TYPE : int32
{
	CpuSetInformation = 0,
}


[AllowDuplicates]
public enum OS_DEPLOYEMENT_STATE_VALUES : int32
{
	OS_DEPLOYMENT_STANDARD = 1,
	OS_DEPLOYMENT_COMPACT = 2,
}


[AllowDuplicates]
public enum RTL_SYSTEM_GLOBAL_DATA_ID : int32
{
	GlobalDataIdUnknown = 0,
	GlobalDataIdRngSeedVersion = 1,
	GlobalDataIdInterruptTime = 2,
	GlobalDataIdTimeZoneBias = 3,
	GlobalDataIdImageNumberLow = 4,
	GlobalDataIdImageNumberHigh = 5,
	GlobalDataIdTimeZoneId = 6,
	GlobalDataIdNtMajorVersion = 7,
	GlobalDataIdNtMinorVersion = 8,
	GlobalDataIdSystemExpirationDate = 9,
	GlobalDataIdKdDebuggerEnabled = 10,
	GlobalDataIdCyclesPerYield = 11,
	GlobalDataIdSafeBootMode = 12,
	GlobalDataIdLastSystemRITEventTickCount = 13,
}


[AllowDuplicates]
public enum DEP_SYSTEM_POLICY_TYPE : int32
{
	DEPPolicyAlwaysOff = 0,
	DEPPolicyAlwaysOn = 1,
	DEPPolicyOptIn = 2,
	DEPPolicyOptOut = 3,
	DEPTotalPolicyCount = 4,
}

#endregion

#region Function Pointers
public function uint32 PGET_SYSTEM_WOW64_DIRECTORY_A(uint8* lpBuffer, uint32 uSize);

public function uint32 PGET_SYSTEM_WOW64_DIRECTORY_W(char16* lpBuffer, uint32 uSize);

#endregion

#region Structs
[CRepr]
public struct GROUP_AFFINITY
{
	public uint Mask;
	public uint16 Group;
	public uint16[3] Reserved;
}

[CRepr]
public struct SYSTEM_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public PROCESSOR_ARCHITECTURE wProcessorArchitecture;
			public uint16 wReserved;
		}
		public uint32 dwOemId;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwPageSize;
	public void* lpMinimumApplicationAddress;
	public void* lpMaximumApplicationAddress;
	public uint dwActiveProcessorMask;
	public uint32 dwNumberOfProcessors;
	public uint32 dwProcessorType;
	public uint32 dwAllocationGranularity;
	public uint16 wProcessorLevel;
	public uint16 wProcessorRevision;
}

[CRepr]
public struct MEMORYSTATUSEX
{
	public uint32 dwLength;
	public uint32 dwMemoryLoad;
	public uint64 ullTotalPhys;
	public uint64 ullAvailPhys;
	public uint64 ullTotalPageFile;
	public uint64 ullAvailPageFile;
	public uint64 ullTotalVirtual;
	public uint64 ullAvailVirtual;
	public uint64 ullAvailExtendedVirtual;
}

[CRepr]
public struct CACHE_DESCRIPTOR
{
	public uint8 Level;
	public uint8 Associativity;
	public uint16 LineSize;
	public uint32 Size;
	public PROCESSOR_CACHE_TYPE Type;
}

[CRepr]
public struct SYSTEM_LOGICAL_PROCESSOR_INFORMATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _ProcessorCore_e__Struct
		{
			public uint8 Flags;
		}
		[CRepr]
		public struct _NumaNode_e__Struct
		{
			public uint32 NodeNumber;
		}
		public _ProcessorCore_e__Struct ProcessorCore;
		public _NumaNode_e__Struct NumaNode;
		public CACHE_DESCRIPTOR Cache;
		public uint64[2] Reserved;
	}
	public uint ProcessorMask;
	public LOGICAL_PROCESSOR_RELATIONSHIP Relationship;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESSOR_RELATIONSHIP
{
	public uint8 Flags;
	public uint8 EfficiencyClass;
	public uint8[20] Reserved;
	public uint16 GroupCount;
	public GROUP_AFFINITY* GroupMask mut => &GroupMask_impl;
	private GROUP_AFFINITY[ANYSIZE_ARRAY] GroupMask_impl;
}

[CRepr]
public struct NUMA_NODE_RELATIONSHIP
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GROUP_AFFINITY GroupMask;
		public GROUP_AFFINITY* GroupMasks mut => &GroupMasks_impl;
		private GROUP_AFFINITY[ANYSIZE_ARRAY] GroupMasks_impl;
	}
	public uint32 NodeNumber;
	public uint8[18] Reserved;
	public uint16 GroupCount;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CACHE_RELATIONSHIP
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GROUP_AFFINITY GroupMask;
		public GROUP_AFFINITY* GroupMasks mut => &GroupMasks_impl;
		private GROUP_AFFINITY[ANYSIZE_ARRAY] GroupMasks_impl;
	}
	public uint8 Level;
	public uint8 Associativity;
	public uint16 LineSize;
	public uint32 CacheSize;
	public PROCESSOR_CACHE_TYPE Type;
	public uint8[18] Reserved;
	public uint16 GroupCount;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESSOR_GROUP_INFO
{
	public uint8 MaximumProcessorCount;
	public uint8 ActiveProcessorCount;
	public uint8[38] Reserved;
	public uint ActiveProcessorMask;
}

[CRepr]
public struct GROUP_RELATIONSHIP
{
	public uint16 MaximumGroupCount;
	public uint16 ActiveGroupCount;
	public uint8[20] Reserved;
	public PROCESSOR_GROUP_INFO* GroupInfo mut => &GroupInfo_impl;
	private PROCESSOR_GROUP_INFO[ANYSIZE_ARRAY] GroupInfo_impl;
}

[CRepr]
public struct SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PROCESSOR_RELATIONSHIP Processor;
		public NUMA_NODE_RELATIONSHIP NumaNode;
		public CACHE_RELATIONSHIP Cache;
		public GROUP_RELATIONSHIP Group;
	}
	public LOGICAL_PROCESSOR_RELATIONSHIP Relationship;
	public uint32 Size;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SYSTEM_CPU_SET_INFORMATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _CpuSet_e__Struct
		{
			[CRepr, Union]
			public struct _Anonymous1_e__Union
			{
				[CRepr]
				public struct _Anonymous_e__Struct
				{
					public uint8 _bitfield;
				}
				public uint8 AllFlags;
				public using _Anonymous_e__Struct Anonymous;
			}
			[CRepr, Union]
			public struct _Anonymous2_e__Union
			{
				public uint32 Reserved;
				public uint8 SchedulingClass;
			}
			public uint32 Id;
			public uint16 Group;
			public uint8 LogicalProcessorIndex;
			public uint8 CoreIndex;
			public uint8 LastLevelCacheIndex;
			public uint8 NumaNodeIndex;
			public uint8 EfficiencyClass;
			public using _Anonymous1_e__Union Anonymous1;
			public using _Anonymous2_e__Union Anonymous2;
			public uint64 AllocationTag;
		}
		public _CpuSet_e__Struct CpuSet;
	}
	public uint32 Size;
	public CPU_SET_INFORMATION_TYPE Type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SYSTEM_POOL_ZEROING_INFORMATION
{
	public BOOLEAN PoolZeroingSupportPresent;
}

[CRepr]
public struct SYSTEM_PROCESSOR_CYCLE_TIME_INFORMATION
{
	public uint64 CycleTime;
}

[CRepr]
public struct SYSTEM_SUPPORTED_PROCESSOR_ARCHITECTURES_INFORMATION
{
	public uint32 _bitfield;
}

[CRepr]
public struct OSVERSIONINFOA
{
	public uint32 dwOSVersionInfoSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public uint32 dwPlatformId;
	public CHAR[128] szCSDVersion;
}

[CRepr]
public struct OSVERSIONINFOW
{
	public uint32 dwOSVersionInfoSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public uint32 dwPlatformId;
	public char16[128] szCSDVersion;
}

[CRepr]
public struct OSVERSIONINFOEXA
{
	public uint32 dwOSVersionInfoSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public uint32 dwPlatformId;
	public CHAR[128] szCSDVersion;
	public uint16 wServicePackMajor;
	public uint16 wServicePackMinor;
	public uint16 wSuiteMask;
	public uint8 wProductType;
	public uint8 wReserved;
}

[CRepr]
public struct OSVERSIONINFOEXW
{
	public uint32 dwOSVersionInfoSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public uint32 dwPlatformId;
	public char16[128] szCSDVersion;
	public uint16 wServicePackMajor;
	public uint16 wServicePackMinor;
	public uint16 wSuiteMask;
	public uint8 wProductType;
	public uint8 wReserved;
}

[CRepr]
public struct MEMORYSTATUS
{
	public uint32 dwLength;
	public uint32 dwMemoryLoad;
	public uint dwTotalPhys;
	public uint dwAvailPhys;
	public uint dwTotalPageFile;
	public uint dwAvailPageFile;
	public uint dwTotalVirtual;
	public uint dwAvailVirtual;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GlobalMemoryStatusEx(MEMORYSTATUSEX* lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetSystemInfo(SYSTEM_INFO* lpSystemInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetSystemTime(SYSTEMTIME* lpSystemTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetSystemTimeAsFileTime(FILETIME* lpSystemTimeAsFileTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetLocalTime(SYSTEMTIME* lpSystemTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsUserCetAvailableInEnvironment(USER_CET_ENVIRONMENT UserCetEnvironment);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemLeapSecondInformation(BOOL* Enabled, uint32* Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetVersion();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetLocalTime(SYSTEMTIME* lpSystemTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTickCount();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 GetTickCount64();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemTimeAdjustment(uint32* lpTimeAdjustment, uint32* lpTimeIncrement, BOOL* lpTimeAdjustmentDisabled);

	[Import("api-ms-win-core-sysinfo-l1-2-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemTimeAdjustmentPrecise(uint64* lpTimeAdjustment, uint64* lpTimeIncrement, BOOL* lpTimeAdjustmentDisabled);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemDirectoryA(uint8* lpBuffer, uint32 uSize);
	public static uint32 GetSystemDirectory(uint8* lpBuffer, uint32 uSize) => GetSystemDirectoryA(lpBuffer, uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemDirectoryW(char16* lpBuffer, uint32 uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetWindowsDirectoryA(uint8* lpBuffer, uint32 uSize);
	public static uint32 GetWindowsDirectory(uint8* lpBuffer, uint32 uSize) => GetWindowsDirectoryA(lpBuffer, uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetWindowsDirectoryW(char16* lpBuffer, uint32 uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemWindowsDirectoryA(uint8* lpBuffer, uint32 uSize);
	public static uint32 GetSystemWindowsDirectory(uint8* lpBuffer, uint32 uSize) => GetSystemWindowsDirectoryA(lpBuffer, uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemWindowsDirectoryW(char16* lpBuffer, uint32 uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetComputerNameExA(COMPUTER_NAME_FORMAT NameType, uint8* lpBuffer, uint32* nSize);
	public static BOOL GetComputerNameEx(COMPUTER_NAME_FORMAT NameType, uint8* lpBuffer, uint32* nSize) => GetComputerNameExA(NameType, lpBuffer, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetComputerNameExW(COMPUTER_NAME_FORMAT NameType, char16* lpBuffer, uint32* nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetComputerNameExW(COMPUTER_NAME_FORMAT NameType, PWSTR lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSystemTime(SYSTEMTIME* lpSystemTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVersionExA(OSVERSIONINFOA* lpVersionInformation);
	public static BOOL GetVersionEx(OSVERSIONINFOA* lpVersionInformation) => GetVersionExA(lpVersionInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVersionExW(OSVERSIONINFOW* lpVersionInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogicalProcessorInformation(SYSTEM_LOGICAL_PROCESSOR_INFORMATION* Buffer, uint32* ReturnedLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogicalProcessorInformationEx(LOGICAL_PROCESSOR_RELATIONSHIP RelationshipType, SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX* Buffer, uint32* ReturnedLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetNativeSystemInfo(SYSTEM_INFO* lpSystemInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetSystemTimePreciseAsFileTime(FILETIME* lpSystemTimeAsFileTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProductInfo(uint32 dwOSMajorVersion, uint32 dwOSMinorVersion, uint32 dwSpMajorVersion, uint32 dwSpMinorVersion, OS_PRODUCT_TYPE* pdwReturnedProductType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 VerSetConditionMask(uint64 ConditionMask, VER_FLAGS TypeMask, uint8 Condition);

	[Import("api-ms-win-core-sysinfo-l1-2-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOsSafeBootMode(uint32* Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnumSystemFirmwareTables(FIRMWARE_TABLE_PROVIDER FirmwareTableProviderSignature, FIRMWARE_TABLE_ID* pFirmwareTableEnumBuffer, uint32 BufferSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemFirmwareTable(FIRMWARE_TABLE_PROVIDER FirmwareTableProviderSignature, FIRMWARE_TABLE_ID FirmwareTableID, void* pFirmwareTableBuffer, uint32 BufferSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsHostnameToComputerNameExW(PWSTR Hostname, char16* ComputerName, uint32* nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPhysicallyInstalledSystemMemory(uint64* TotalMemoryInKilobytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetComputerNameEx2W(COMPUTER_NAME_FORMAT NameType, uint32 Flags, PWSTR lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSystemTimeAdjustment(uint32 dwTimeAdjustment, BOOL bTimeAdjustmentDisabled);

	[Import("api-ms-win-core-sysinfo-l1-2-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSystemTimeAdjustmentPrecise(uint64 dwTimeAdjustment, BOOL bTimeAdjustmentDisabled);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessorSystemCycleTime(uint16 Group, SYSTEM_PROCESSOR_CYCLE_TIME_INFORMATION* Buffer, uint32* ReturnedLength);

	[Import("api-ms-win-core-sysinfo-l1-2-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOsManufacturingMode(BOOL* pbEnabled);

	[Import("api-ms-win-core-sysinfo-l1-2-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetIntegratedDisplaySize(double* sizeInInches);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetComputerNameA(PSTR lpComputerName);
	public static BOOL SetComputerName(PSTR lpComputerName) => SetComputerNameA(lpComputerName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetComputerNameW(PWSTR lpComputerName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetComputerNameExA(COMPUTER_NAME_FORMAT NameType, PSTR lpBuffer);
	public static BOOL SetComputerNameEx(COMPUTER_NAME_FORMAT NameType, PSTR lpBuffer) => SetComputerNameExA(NameType, lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemCpuSetInformation(SYSTEM_CPU_SET_INFORMATION* Information, uint32 BufferLength, uint32* ReturnedLength, HANDLE Process, uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemWow64DirectoryA(uint8* lpBuffer, uint32 uSize);
	public static uint32 GetSystemWow64Directory(uint8* lpBuffer, uint32 uSize) => GetSystemWow64DirectoryA(lpBuffer, uSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemWow64DirectoryW(char16* lpBuffer, uint32 uSize);

	[Import("api-ms-win-core-wow64-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemWow64Directory2A(uint8* lpBuffer, uint32 uSize, IMAGE_FILE_MACHINE ImageFileMachineType);
	public static uint32 GetSystemWow64Directory2(uint8* lpBuffer, uint32 uSize, IMAGE_FILE_MACHINE ImageFileMachineType) => GetSystemWow64Directory2A(lpBuffer, uSize, ImageFileMachineType);

	[Import("api-ms-win-core-wow64-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemWow64Directory2W(char16* lpBuffer, uint32 uSize, IMAGE_FILE_MACHINE ImageFileMachineType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IsWow64GuestMachineSupported(IMAGE_FILE_MACHINE WowGuestMachine, BOOL* MachineIsSupported);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN RtlGetProductInfo(uint32 OSMajorVersion, uint32 OSMinorVersion, uint32 SpMajorVersion, uint32 SpMinorVersion, uint32* ReturnedProductType);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern OS_DEPLOYEMENT_STATE_VALUES RtlOsDeploymentState(uint32 Flags);

	[Import("ntdllk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlGetSystemGlobalData(RTL_SYSTEM_GLOBAL_DATA_ID DataId, void* Buffer, uint32 Size);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlGetDeviceFamilyInfoEnum(uint64* pullUAPInfo, DEVICEFAMILYINFOENUM* pulDeviceFamily, DEVICEFAMILYDEVICEFORM* pulDeviceForm);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlConvertDeviceFamilyInfoToString(uint32* pulDeviceFamilyBufferSize, uint32* pulDeviceFormBufferSize, PWSTR DeviceFamily, PWSTR DeviceForm);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlSwitchedVVI(OSVERSIONINFOEXW* VersionInfo, uint32 TypeMask, uint64 ConditionMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GlobalMemoryStatus(MEMORYSTATUS* lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DEP_SYSTEM_POLICY_TYPE GetSystemDEPPolicy();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFirmwareType(FIRMWARE_TYPE* FirmwareType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VerifyVersionInfoA(OSVERSIONINFOEXA* lpVersionInformation, VER_FLAGS dwTypeMask, uint64 dwlConditionMask);
	public static BOOL VerifyVersionInfo(OSVERSIONINFOEXA* lpVersionInformation, VER_FLAGS dwTypeMask, uint64 dwlConditionMask) => VerifyVersionInfoA(lpVersionInformation, dwTypeMask, dwlConditionMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VerifyVersionInfoW(OSVERSIONINFOEXW* lpVersionInformation, VER_FLAGS dwTypeMask, uint64 dwlConditionMask);

}
#endregion
