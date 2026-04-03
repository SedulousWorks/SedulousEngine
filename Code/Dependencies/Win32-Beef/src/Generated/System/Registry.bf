using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.System.Registry;

#region Constants
public static
{
	public const HKEY HKEY_CLASSES_ROOT = -2147483648;
	public const HKEY HKEY_CURRENT_USER = -2147483647;
	public const HKEY HKEY_LOCAL_MACHINE = -2147483646;
	public const HKEY HKEY_USERS = -2147483645;
	public const HKEY HKEY_PERFORMANCE_DATA = -2147483644;
	public const HKEY HKEY_PERFORMANCE_TEXT = -2147483568;
	public const HKEY HKEY_PERFORMANCE_NLSTEXT = -2147483552;
	public const HKEY HKEY_CURRENT_CONFIG = -2147483643;
	public const HKEY HKEY_DYN_DATA = -2147483642;
	public const HKEY HKEY_CURRENT_USER_LOCAL_SETTINGS = -2147483641;
	public const uint32 RRF_SUBKEY_WOW6464KEY = 65536;
	public const uint32 RRF_SUBKEY_WOW6432KEY = 131072;
	public const uint32 RRF_WOW64_MASK = 196608;
	public const uint32 RRF_NOEXPAND = 268435456;
	public const uint32 RRF_ZEROONFAILURE = 536870912;
	public const uint32 REG_PROCESS_APPKEY = 1;
	public const uint32 REG_USE_CURRENT_SECURITY_CONTEXT = 2;
	public const uint32 PROVIDER_KEEPS_VALUE_LENGTH = 1;
	public const uint32 REG_MUI_STRING_TRUNCATE = 1;
	public const uint32 REG_SECURE_CONNECTION = 1;
	public const String REGSTR_KEY_CLASS = "Class";
	public const String REGSTR_KEY_CONFIG = "Config";
	public const String REGSTR_KEY_ENUM = "Enum";
	public const String REGSTR_KEY_ROOTENUM = "Root";
	public const String REGSTR_KEY_BIOSENUM = "BIOS";
	public const String REGSTR_KEY_ACPIENUM = "ACPI";
	public const String REGSTR_KEY_PCMCIAENUM = "PCMCIA";
	public const String REGSTR_KEY_PCIENUM = "PCI";
	public const String REGSTR_KEY_VPOWERDENUM = "VPOWERD";
	public const String REGSTR_KEY_ISAENUM = "ISAPnP";
	public const String REGSTR_KEY_EISAENUM = "EISA";
	public const String REGSTR_KEY_LOGCONFIG = "LogConfig";
	public const String REGSTR_KEY_SYSTEMBOARD = "*PNP0C01";
	public const String REGSTR_KEY_APM = "*PNP0C05";
	public const String REGSTR_KEY_INIUPDATE = "IniUpdate";
	public const String REG_KEY_INSTDEV = "Installed";
	public const String REGSTR_KEY_DOSOPTCDROM = "CD-ROM";
	public const String REGSTR_KEY_DOSOPTMOUSE = "MOUSE";
	public const String REGSTR_KEY_KNOWNDOCKINGSTATES = "Hardware Profiles";
	public const String REGSTR_KEY_DEVICEPARAMETERS = "Device Parameters";
	public const String REGSTR_KEY_DRIVERPARAMETERS = "Driver Parameters";
	public const String REGSTR_DEFAULT_INSTANCE = "0000";
	public const String REGSTR_PATH_SETUP = "Software\\Microsoft\\Windows\\CurrentVersion";
	public const String REGSTR_PATH_DRIVERSIGN = "Software\\Microsoft\\Driver Signing";
	public const String REGSTR_PATH_NONDRIVERSIGN = "Software\\Microsoft\\Non-Driver Signing";
	public const String REGSTR_PATH_DRIVERSIGN_POLICY = "Software\\Policies\\Microsoft\\Windows NT\\Driver Signing";
	public const String REGSTR_PATH_NONDRIVERSIGN_POLICY = "Software\\Policies\\Microsoft\\Windows NT\\Non-Driver Signing";
	public const String REGSTR_PATH_PIFCONVERT = "Software\\Microsoft\\Windows\\CurrentVersion\\PIFConvert";
	public const String REGSTR_PATH_MSDOSOPTS = "Software\\Microsoft\\Windows\\CurrentVersion\\MS-DOSOptions";
	public const String REGSTR_PATH_NOSUGGMSDOS = "Software\\Microsoft\\Windows\\CurrentVersion\\NoMSDOSWarn";
	public const String REGSTR_PATH_NEWDOSBOX = "Software\\Microsoft\\Windows\\CurrentVersion\\MS-DOSSpecialConfig";
	public const String REGSTR_PATH_RUNONCE = "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce";
	public const String REGSTR_PATH_RUNONCEEX = "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnceEx";
	public const String REGSTR_PATH_RUN = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
	public const String REGSTR_PATH_RUNSERVICESONCE = "Software\\Microsoft\\Windows\\CurrentVersion\\RunServicesOnce";
	public const String REGSTR_PATH_RUNSERVICES = "Software\\Microsoft\\Windows\\CurrentVersion\\RunServices";
	public const String REGSTR_PATH_EXPLORER = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer";
	public const String REGSTR_PATH_PROPERTYSYSTEM = "Software\\Microsoft\\Windows\\CurrentVersion\\PropertySystem";
	public const String REGSTR_PATH_DETECT = "Software\\Microsoft\\Windows\\CurrentVersion\\Detect";
	public const String REGSTR_PATH_APPPATHS = "Software\\Microsoft\\Windows\\CurrentVersion\\App Paths";
	public const String REGSTR_PATH_UNINSTALL = "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall";
	public const String REGSTR_PATH_REALMODENET = "Software\\Microsoft\\Windows\\CurrentVersion\\Network\\Real Mode Net";
	public const String REGSTR_PATH_NETEQUIV = "Software\\Microsoft\\Windows\\CurrentVersion\\Network\\Equivalent";
	public const String REGSTR_PATH_CVNETWORK = "Software\\Microsoft\\Windows\\CurrentVersion\\Network";
	public const String REGSTR_PATH_WMI_SECURITY = "System\\CurrentControlSet\\Control\\Wmi\\Security";
	public const String REGSTR_PATH_RELIABILITY = "Software\\Microsoft\\Windows\\CurrentVersion\\Reliability";
	public const String REGSTR_PATH_RELIABILITY_POLICY = "Software\\Policies\\Microsoft\\Windows NT\\Reliability";
	public const String REGSTR_PATH_RELIABILITY_POLICY_SHUTDOWNREASONUI = "ShutdownReasonUI";
	public const String REGSTR_PATH_RELIABILITY_POLICY_SNAPSHOT = "Snapshot";
	public const String REGSTR_PATH_RELIABILITY_POLICY_REPORTSNAPSHOT = "ReportSnapshot";
	public const String REGSTR_PATH_REINSTALL = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Reinstall";
	public const String REGSTR_PATH_NT_CURRENTVERSION = "Software\\Microsoft\\Windows NT\\CurrentVersion";
	public const String REGSTR_PATH_VOLUMECACHE = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VolumeCaches";
	public const String REGSTR_VAL_DISPLAY = "display";
	public const String REGSTR_PATH_IDCONFIGDB = "System\\CurrentControlSet\\Control\\IDConfigDB";
	public const String REGSTR_PATH_CRITICALDEVICEDATABASE = "System\\CurrentControlSet\\Control\\CriticalDeviceDatabase";
	public const String REGSTR_PATH_CLASS = "System\\CurrentControlSet\\Services\\Class";
	public const String REGSTR_PATH_DISPLAYSETTINGS = "Display\\Settings";
	public const String REGSTR_PATH_FONTS = "Display\\Fonts";
	public const String REGSTR_PATH_ENUM = "Enum";
	public const String REGSTR_PATH_ROOT = "Enum\\Root";
	public const String REGSTR_PATH_CURRENTCONTROLSET = "System\\CurrentControlSet";
	public const String REGSTR_PATH_SYSTEMENUM = "System\\CurrentControlSet\\Enum";
	public const String REGSTR_PATH_HWPROFILES = "System\\CurrentControlSet\\Hardware Profiles";
	public const String REGSTR_PATH_HWPROFILESCURRENT = "System\\CurrentControlSet\\Hardware Profiles\\Current";
	public const String REGSTR_PATH_CLASS_NT = "System\\CurrentControlSet\\Control\\Class";
	public const String REGSTR_PATH_PER_HW_ID_STORAGE = "Software\\Microsoft\\Windows NT\\CurrentVersion\\PerHwIdStorage";
	public const String REGSTR_PATH_DEVICE_CLASSES = "System\\CurrentControlSet\\Control\\DeviceClasses";
	public const String REGSTR_PATH_CODEVICEINSTALLERS = "System\\CurrentControlSet\\Control\\CoDeviceInstallers";
	public const String REGSTR_PATH_BUSINFORMATION = "System\\CurrentControlSet\\Control\\PnP\\BusInformation";
	public const String REGSTR_PATH_SERVICES = "System\\CurrentControlSet\\Services";
	public const String REGSTR_PATH_VXD = "System\\CurrentControlSet\\Services\\VxD";
	public const String REGSTR_PATH_IOS = "System\\CurrentControlSet\\Services\\VxD\\IOS";
	public const String REGSTR_PATH_VMM = "System\\CurrentControlSet\\Services\\VxD\\VMM";
	public const String REGSTR_PATH_VPOWERD = "System\\CurrentControlSet\\Services\\VxD\\VPOWERD";
	public const String REGSTR_PATH_VNETSUP = "System\\CurrentControlSet\\Services\\VxD\\VNETSUP";
	public const String REGSTR_PATH_NWREDIR = "System\\CurrentControlSet\\Services\\VxD\\NWREDIR";
	public const String REGSTR_PATH_NCPSERVER = "System\\CurrentControlSet\\Services\\NcpServer\\Parameters";
	public const String REGSTR_PATH_VCOMM = "System\\CurrentControlSet\\Services\\VxD\\VCOMM";
	public const String REGSTR_PATH_IOARB = "System\\CurrentControlSet\\Services\\Arbitrators\\IOArb";
	public const String REGSTR_PATH_ADDRARB = "System\\CurrentControlSet\\Services\\Arbitrators\\AddrArb";
	public const String REGSTR_PATH_DMAARB = "System\\CurrentControlSet\\Services\\Arbitrators\\DMAArb";
	public const String REGSTR_PATH_IRQARB = "System\\CurrentControlSet\\Services\\Arbitrators\\IRQArb";
	public const String REGSTR_PATH_CODEPAGE = "System\\CurrentControlSet\\Control\\Nls\\Codepage";
	public const String REGSTR_PATH_FILESYSTEM = "System\\CurrentControlSet\\Control\\FileSystem";
	public const String REGSTR_PATH_FILESYSTEM_NOVOLTRACK = "System\\CurrentControlSet\\Control\\FileSystem\\NoVolTrack";
	public const String REGSTR_PATH_CDFS = "System\\CurrentControlSet\\Control\\FileSystem\\CDFS";
	public const String REGSTR_PATH_WINBOOT = "System\\CurrentControlSet\\Control\\WinBoot";
	public const String REGSTR_PATH_INSTALLEDFILES = "System\\CurrentControlSet\\Control\\InstalledFiles";
	public const String REGSTR_PATH_VMM32FILES = "System\\CurrentControlSet\\Control\\VMM32Files";
	public const uint32 REGSTR_MAX_VALUE_LENGTH = 256;
	public const String REGSTR_KEY_DEVICE_PROPERTIES = "Properties";
	public const String REGSTR_VAL_SERVICE = "Service";
	public const String REGSTR_VAL_CLASSGUID = "ClassGUID";
	public const String REGSTR_VAL_DISABLECOUNT = "DisableCount";
	public const String REGSTR_VAL_DOCKSTATE = "DockState";
	public const String REGSTR_VAL_DEVICE_INSTANCE = "DeviceInstance";
	public const String REGSTR_VAL_SYMBOLIC_LINK = "SymbolicLink";
	public const String REGSTR_VAL_DEFAULT = "Default";
	public const String REGSTR_VAL_LOWERFILTERS = "LowerFilters";
	public const String REGSTR_VAL_UPPERFILTERS = "UpperFilters";
	public const String REGSTR_VAL_LOCATION_INFORMATION = "LocationInformation";
	public const String REGSTR_VAL_UI_NUMBER = "UINumber";
	public const String REGSTR_VAL_UI_NUMBER_DESC_FORMAT = "UINumberDescFormat";
	public const String REGSTR_VAL_CAPABILITIES = "Capabilities";
	public const String REGSTR_VAL_ADDRESS = "Address";
	public const String REGSTR_VAL_DEVICE_TYPE = "DeviceType";
	public const String REGSTR_VAL_DEVICE_CHARACTERISTICS = "DeviceCharacteristics";
	public const String REGSTR_VAL_DEVICE_SECURITY_DESCRIPTOR = "Security";
	public const String REGSTR_VAL_DEVICE_EXCLUSIVE = "Exclusive";
	public const String REGSTR_VAL_RESOURCE_PICKER_TAGS = "ResourcePickerTags";
	public const String REGSTR_VAL_RESOURCE_PICKER_EXCEPTIONS = "ResourcePickerExceptions";
	public const String REGSTR_VAL_CUSTOM_PROPERTY_CACHE_DATE = "CustomPropertyCacheDate";
	public const String REGSTR_VAL_CUSTOM_PROPERTY_HW_ID_KEY = "CustomPropertyHwIdKey";
	public const String REGSTR_VAL_LAST_UPDATE_TIME = "LastUpdateTime";
	public const String REGSTR_VAL_CONTAINERID = "ContainerID";
	public const String REGSTR_VAL_EJECT_PRIORITY = "EjectPriority";
	public const String REGSTR_KEY_CONTROL = "Control";
	public const String REGSTR_VAL_ACTIVESERVICE = "ActiveService";
	public const String REGSTR_VAL_LINKED = "Linked";
	public const String REGSTR_VAL_PHYSICALDEVICEOBJECT = "PhysicalDeviceObject";
	public const String REGSTR_VAL_REMOVAL_POLICY = "RemovalPolicy";
	public const String REGSTR_KEY_FILTERS = "Filters";
	public const String REGSTR_VAL_LOWER_FILTER_DEFAULT_LEVEL = "LowerFilterDefaultLevel";
	public const String REGSTR_VAL_UPPER_FILTER_DEFAULT_LEVEL = "UpperFilterDefaultLevel";
	public const String REGSTR_KEY_LOWER_FILTER_LEVEL_DEFAULT = "*Lower";
	public const String REGSTR_KEY_UPPER_FILTER_LEVEL_DEFAULT = "*Upper";
	public const String REGSTR_VAL_LOWER_FILTER_LEVELS = "LowerFilterLevels";
	public const String REGSTR_VAL_UPPER_FILTER_LEVELS = "UpperFilterLevels";
	public const String REGSTR_VAL_CURRENT_VERSION = "CurrentVersion";
	public const String REGSTR_VAL_CURRENT_BUILD = "CurrentBuildNumber";
	public const String REGSTR_VAL_CURRENT_CSDVERSION = "CSDVersion";
	public const String REGSTR_VAL_CURRENT_TYPE = "CurrentType";
	public const String REGSTR_VAL_BITSPERPIXEL = "BitsPerPixel";
	public const String REGSTR_VAL_RESOLUTION = "Resolution";
	public const String REGSTR_VAL_DPILOGICALX = "DPILogicalX";
	public const String REGSTR_VAL_DPILOGICALY = "DPILogicalY";
	public const String REGSTR_VAL_DPIPHYSICALX = "DPIPhysicalX";
	public const String REGSTR_VAL_DPIPHYSICALY = "DPIPhysicalY";
	public const String REGSTR_VAL_REFRESHRATE = "RefreshRate";
	public const String REGSTR_VAL_DISPLAYFLAGS = "DisplayFlags";
	public const String REGSTR_PATH_CONTROLPANEL = "Control Panel";
	public const String REGSTR_PATH_CONTROLSFOLDER = "Software\\Microsoft\\Windows\\CurrentVersion\\Controls Folder";
	public const String REGSTR_VAL_DOSCP = "OEMCP";
	public const String REGSTR_VAL_WINCP = "ACP";
	public const String REGSTR_VAL_DONTUSEMEM = "DontAllocLastMem";
	public const String REGSTR_VAL_SYSTEMROOT = "SystemRoot";
	public const String REGSTR_VAL_BOOTCOUNT = "BootCount";
	public const String REGSTR_VAL_REALNETSTART = "RealNetStart";
	public const String REGSTR_VAL_MEDIA = "MediaPath";
	public const String REGSTR_VAL_CONFIG = "ConfigPath";
	public const String REGSTR_VAL_DEVICEPATH = "DevicePath";
	public const String REGSTR_VAL_SRCPATH = "SourcePath";
	public const String REGSTR_VAL_DRIVERCACHEPATH = "DriverCachePath";
	public const String REGSTR_VAL_OLDWINDIR = "OldWinDir";
	public const String REGSTR_VAL_SETUPFLAGS = "SetupFlags";
	public const String REGSTR_VAL_REGOWNER = "RegisteredOwner";
	public const String REGSTR_VAL_REGORGANIZATION = "RegisteredOrganization";
	public const String REGSTR_VAL_LICENSINGINFO = "LicensingInfo";
	public const String REGSTR_VAL_OLDMSDOSVER = "OldMSDOSVer";
	public const String REGSTR_VAL_FIRSTINSTALLDATETIME = "FirstInstallDateTime";
	public const String REGSTR_VAL_INSTALLTYPE = "InstallType";
	public const uint32 IT_COMPACT = 0;
	public const uint32 IT_TYPICAL = 1;
	public const uint32 IT_PORTABLE = 2;
	public const uint32 IT_CUSTOM = 3;
	public const String REGSTR_VAL_WRAPPER = "Wrapper";
	public const String REGSTR_KEY_RUNHISTORY = "RunHistory";
	public const String REGSTR_VAL_LASTALIVEINTERVAL = "TimeStampInterval";
	public const String REGSTR_VAL_DIRTYSHUTDOWN = "DirtyShutdown";
	public const String REGSTR_VAL_DIRTYSHUTDOWNTIME = "DirtyShutdownTime";
	public const String REGSTR_VAL_BT = "6005BT";
	public const String REGSTR_VAL_LASTCOMPUTERNAME = "LastComputerName";
	public const String REGSTR_VAL_LASTALIVEBT = "LastAliveBT";
	public const String REGSTR_VAL_LASTALIVESTAMP = "LastAliveStamp";
	public const String REGSTR_VAL_LASTALIVESTAMPFORCED = "LastAliveStampForced";
	public const String REGSTR_VAL_LASTALIVESTAMPINTERVAL = "LastAliveStampInterval";
	public const String REGSTR_VAL_LASTALIVESTAMPPOLICYINTERVAL = "LastAliveStampPolicyInterval";
	public const String REGSTR_VAL_LASTALIVEUPTIME = "LastAliveUptime";
	public const String REGSTR_VAL_LASTALIVEPMPOLICY = "LastAlivePMPolicy";
	public const String REGSTR_VAL_REASONCODE = "ReasonCode";
	public const String REGSTR_VAL_COMMENT = "Comment";
	public const String REGSTR_VAL_SHUTDOWNREASON = "ShutdownReason";
	public const String REGSTR_VAL_SHUTDOWNREASON_CODE = "ShutdownReasonCode";
	public const String REGSTR_VAL_SHUTDOWNREASON_COMMENT = "ShutdownReasonComment";
	public const String REGSTR_VAL_SHUTDOWNREASON_PROCESS = "ShutdownReasonProcess";
	public const String REGSTR_VAL_SHUTDOWNREASON_USERNAME = "ShutdownReasonUserName";
	public const String REGSTR_VAL_SHOWREASONUI = "ShutdownReasonUI";
	public const String REGSTR_VAL_SHUTDOWN_IGNORE_PREDEFINED = "ShutdownIgnorePredefinedReasons";
	public const String REGSTR_VAL_SHUTDOWN_STATE_SNAPSHOT = "ShutdownStateSnapshot";
	public const String REGSTR_KEY_SETUP = "\\Setup";
	public const String REGSTR_VAL_BOOTDIR = "BootDir";
	public const String REGSTR_VAL_WINBOOTDIR = "WinbootDir";
	public const String REGSTR_VAL_WINDIR = "WinDir";
	public const String REGSTR_VAL_APPINSTPATH = "AppInstallPath";
	public const String REGSTR_KEY_EBDFILESLOCAL = "EBDFilesLocale";
	public const String REGSTR_KEY_EBDFILESKEYBOARD = "EBDFilesKeyboard";
	public const String REGSTR_KEY_EBDAUTOEXECBATLOCAL = "EBDAutoexecBatLocale";
	public const String REGSTR_KEY_EBDAUTOEXECBATKEYBOARD = "EBDAutoexecBatKeyboard";
	public const String REGSTR_KEY_EBDCONFIGSYSLOCAL = "EBDConfigSysLocale";
	public const String REGSTR_KEY_EBDCONFIGSYSKEYBOARD = "EBDConfigSysKeyboard";
	public const String REGSTR_VAL_POLICY = "Policy";
	public const String REGSTR_VAL_BEHAVIOR_ON_FAILED_VERIFY = "BehaviorOnFailedVerify";
	public const uint32 DRIVERSIGN_NONE = 0;
	public const uint32 DRIVERSIGN_WARNING = 1;
	public const uint32 DRIVERSIGN_BLOCKING = 2;
	public const String REGSTR_VAL_MSDOSMODE = "MSDOSMode";
	public const String REGSTR_VAL_MSDOSMODEDISCARD = "Discard";
	public const String REGSTR_VAL_DOSOPTGLOBALFLAGS = "GlobalFlags";
	public const int32 DOSOPTGF_DEFCLEAN = 1;
	public const String REGSTR_VAL_DOSOPTFLAGS = "Flags";
	public const String REGSTR_VAL_OPTORDER = "Order";
	public const String REGSTR_VAL_CONFIGSYS = "Config.Sys";
	public const String REGSTR_VAL_AUTOEXEC = "Autoexec.Bat";
	public const String REGSTR_VAL_STDDOSOPTION = "StdOption";
	public const String REGSTR_VAL_DOSOPTTIP = "TipText";
	public const int32 DOSOPTF_DEFAULT = 1;
	public const int32 DOSOPTF_SUPPORTED = 2;
	public const int32 DOSOPTF_ALWAYSUSE = 4;
	public const int32 DOSOPTF_USESPMODE = 8;
	public const int32 DOSOPTF_PROVIDESUMB = 16;
	public const int32 DOSOPTF_NEEDSETUP = 32;
	public const int32 DOSOPTF_INDOSSTART = 64;
	public const int32 DOSOPTF_MULTIPLE = 128;
	public const int32 SUF_FIRSTTIME = 1;
	public const int32 SUF_EXPRESS = 2;
	public const int32 SUF_BATCHINF = 4;
	public const int32 SUF_CLEAN = 8;
	public const int32 SUF_INSETUP = 16;
	public const int32 SUF_NETSETUP = 32;
	public const int32 SUF_NETHDBOOT = 64;
	public const int32 SUF_NETRPLBOOT = 128;
	public const int32 SUF_SBSCOPYOK = 256;
	public const String REGSTR_VAL_DOSPAGER = "DOSPager";
	public const String REGSTR_VAL_VXDGROUPS = "VXDGroups";
	public const String REGSTR_VAL_VPOWERDFLAGS = "Flags";
	public const uint32 VPDF_DISABLEPWRMGMT = 1;
	public const uint32 VPDF_FORCEAPM10MODE = 2;
	public const uint32 VPDF_SKIPINTELSLCHECK = 4;
	public const uint32 VPDF_DISABLEPWRSTATUSPOLL = 8;
	public const uint32 VPDF_DISABLERINGRESUME = 16;
	public const uint32 VPDF_SHOWMULTIBATT = 32;
	public const uint32 BIF_SHOWSIMILARDRIVERS = 1;
	public const uint32 BIF_RAWDEVICENEEDSDRIVER = 2;
	public const String REGSTR_VAL_WORKGROUP = "Workgroup";
	public const String REGSTR_VAL_DIRECTHOST = "DirectHost";
	public const String REGSTR_VAL_FILESHARING = "FileSharing";
	public const String REGSTR_VAL_PRINTSHARING = "PrintSharing";
	public const String REGSTR_VAL_FIRSTNETDRIVE = "FirstNetworkDrive";
	public const String REGSTR_VAL_MAXCONNECTIONS = "MaxConnections";
	public const String REGSTR_VAL_APISUPPORT = "APISupport";
	public const String REGSTR_VAL_MAXRETRY = "MaxRetry";
	public const String REGSTR_VAL_MINRETRY = "MinRetry";
	public const String REGSTR_VAL_SUPPORTLFN = "SupportLFN";
	public const String REGSTR_VAL_SUPPORTBURST = "SupportBurst";
	public const String REGSTR_VAL_SUPPORTTUNNELLING = "SupportTunnelling";
	public const String REGSTR_VAL_FULLTRACE = "FullTrace";
	public const String REGSTR_VAL_READCACHING = "ReadCaching";
	public const String REGSTR_VAL_SHOWDOTS = "ShowDots";
	public const String REGSTR_VAL_GAPTIME = "GapTime";
	public const String REGSTR_VAL_SEARCHMODE = "SearchMode";
	public const String REGSTR_VAL_SHELLVERSION = "ShellVersion";
	public const String REGSTR_VAL_MAXLIP = "MaxLIP";
	public const String REGSTR_VAL_PRESERVECASE = "PreserveCase";
	public const String REGSTR_VAL_OPTIMIZESFN = "OptimizeSFN";
	public const String REGSTR_VAL_NCP_BROWSEMASTER = "BrowseMaster";
	public const String REGSTR_VAL_NCP_USEPEERBROWSING = "Use_PeerBrowsing";
	public const String REGSTR_VAL_NCP_USESAP = "Use_Sap";
	public const String REGSTR_VAL_PCCARD_POWER = "EnablePowerManagement";
	public const String REGSTR_VAL_WIN31FILESYSTEM = "Win31FileSystem";
	public const String REGSTR_VAL_PRESERVELONGNAMES = "PreserveLongNames";
	public const String REGSTR_VAL_DRIVEWRITEBEHIND = "DriveWriteBehind";
	public const String REGSTR_VAL_ASYNCFILECOMMIT = "AsyncFileCommit";
	public const String REGSTR_VAL_PATHCACHECOUNT = "PathCache";
	public const String REGSTR_VAL_NAMECACHECOUNT = "NameCache";
	public const String REGSTR_VAL_CONTIGFILEALLOC = "ContigFileAllocSize";
	public const String REGSTR_VAL_FREESPACERATIO = "FreeSpaceRatio";
	public const String REGSTR_VAL_VOLIDLETIMEOUT = "VolumeIdleTimeout";
	public const String REGSTR_VAL_BUFFIDLETIMEOUT = "BufferIdleTimeout";
	public const String REGSTR_VAL_BUFFAGETIMEOUT = "BufferAgeTimeout";
	public const String REGSTR_VAL_NAMENUMERICTAIL = "NameNumericTail";
	public const String REGSTR_VAL_READAHEADTHRESHOLD = "ReadAheadThreshold";
	public const String REGSTR_VAL_DOUBLEBUFFER = "DoubleBuffer";
	public const String REGSTR_VAL_SOFTCOMPATMODE = "SoftCompatMode";
	public const String REGSTR_VAL_DRIVESPINDOWN = "DriveSpinDown";
	public const String REGSTR_VAL_FORCEPMIO = "ForcePMIO";
	public const String REGSTR_VAL_FORCERMIO = "ForceRMIO";
	public const String REGSTR_VAL_LASTBOOTPMDRVS = "LastBootPMDrvs";
	public const String REGSTR_VAL_ACSPINDOWNPREVIOUS = "ACSpinDownPrevious";
	public const String REGSTR_VAL_BATSPINDOWNPREVIOUS = "BatSpinDownPrevious";
	public const String REGSTR_VAL_VIRTUALHDIRQ = "VirtualHDIRQ";
	public const String REGSTR_VAL_SRVNAMECACHECOUNT = "ServerNameCacheMax";
	public const String REGSTR_VAL_SRVNAMECACHE = "ServerNameCache";
	public const String REGSTR_VAL_SRVNAMECACHENETPROV = "ServerNameCacheNumNets";
	public const String REGSTR_VAL_AUTOMOUNT = "AutoMountDrives";
	public const String REGSTR_VAL_COMPRESSIONMETHOD = "CompressionAlgorithm";
	public const String REGSTR_VAL_COMPRESSIONTHRESHOLD = "CompressionThreshold";
	public const String REGSTR_VAL_ACDRIVESPINDOWN = "ACDriveSpinDown";
	public const String REGSTR_VAL_BATDRIVESPINDOWN = "BatDriveSpinDown";
	public const String REGSTR_VAL_CDCACHESIZE = "CacheSize";
	public const String REGSTR_VAL_CDPREFETCH = "Prefetch";
	public const String REGSTR_VAL_CDPREFETCHTAIL = "PrefetchTail";
	public const String REGSTR_VAL_CDRAWCACHE = "RawCache";
	public const String REGSTR_VAL_CDEXTERRORS = "ExtendedErrors";
	public const String REGSTR_VAL_CDSVDSENSE = "SVDSense";
	public const String REGSTR_VAL_CDSHOWVERSIONS = "ShowVersions";
	public const String REGSTR_VAL_CDCOMPATNAMES = "MSCDEXCompatNames";
	public const String REGSTR_VAL_CDNOREADAHEAD = "NoReadAhead";
	public const String REGSTR_VAL_SCSI = "SCSI\\";
	public const String REGSTR_VAL_ESDI = "ESDI\\";
	public const String REGSTR_VAL_FLOP = "FLOP\\";
	public const String REGSTR_VAL_DISK = "GenDisk";
	public const String REGSTR_VAL_CDROM = "GenCD";
	public const String REGSTR_VAL_TAPE = "TAPE";
	public const String REGSTR_VAL_SCANNER = "SCANNER";
	public const String REGSTR_VAL_FLOPPY = "FLOPPY";
	public const String REGSTR_VAL_SCSITID = "SCSITargetID";
	public const String REGSTR_VAL_SCSILUN = "SCSILUN";
	public const String REGSTR_VAL_REVLEVEL = "RevisionLevel";
	public const String REGSTR_VAL_PRODUCTID = "ProductId";
	public const String REGSTR_VAL_PRODUCTTYPE = "ProductType";
	public const String REGSTR_VAL_DEVTYPE = "DeviceType";
	public const String REGSTR_VAL_REMOVABLE = "Removable";
	public const String REGSTR_VAL_CURDRVLET = "CurrentDriveLetterAssignment";
	public const String REGSTR_VAL_USRDRVLET = "UserDriveLetterAssignment";
	public const String REGSTR_VAL_SYNCDATAXFER = "SyncDataXfer";
	public const String REGSTR_VAL_AUTOINSNOTE = "AutoInsertNotification";
	public const String REGSTR_VAL_DISCONNECT = "Disconnect";
	public const String REGSTR_VAL_INT13 = "Int13";
	public const String REGSTR_VAL_PMODE_INT13 = "PModeInt13";
	public const String REGSTR_VAL_USERSETTINGS = "AdapterSettings";
	public const String REGSTR_VAL_NOIDE = "NoIDE";
	public const String REGSTR_VAL_DISKCLASSNAME = "DiskDrive";
	public const String REGSTR_VAL_CDROMCLASSNAME = "CDROM";
	public const String REGSTR_VAL_FORCELOAD = "ForceLoadPD";
	public const String REGSTR_VAL_FORCEFIFO = "ForceFIFO";
	public const String REGSTR_VAL_FORCECL = "ForceChangeLine";
	public const String REGSTR_VAL_NOUSECLASS = "NoUseClass";
	public const String REGSTR_VAL_NOINSTALLCLASS = "NoInstallClass";
	public const String REGSTR_VAL_NODISPLAYCLASS = "NoDisplayClass";
	public const String REGSTR_VAL_SILENTINSTALL = "SilentInstall";
	public const String REGSTR_VAL_FSFILTERCLASS = "FSFilterClass";
	public const String REGSTR_KEY_PCMCIA_CLASS = "PCMCIA";
	public const String REGSTR_KEY_SCSI_CLASS = "SCSIAdapter";
	public const String REGSTR_KEY_PORTS_CLASS = "ports";
	public const String REGSTR_KEY_MEDIA_CLASS = "MEDIA";
	public const String REGSTR_KEY_DISPLAY_CLASS = "Display";
	public const String REGSTR_KEY_KEYBOARD_CLASS = "Keyboard";
	public const String REGSTR_KEY_MOUSE_CLASS = "Mouse";
	public const String REGSTR_KEY_MONITOR_CLASS = "Monitor";
	public const String REGSTR_KEY_MODEM_CLASS = "Modem";
	public const String REGSTR_VAL_PCMCIA_OPT = "Options";
	public const int32 PCMCIA_OPT_HAVE_SOCKET = 1;
	public const int32 PCMCIA_OPT_AUTOMEM = 4;
	public const int32 PCMCIA_OPT_NO_SOUND = 8;
	public const int32 PCMCIA_OPT_NO_AUDIO = 16;
	public const int32 PCMCIA_OPT_NO_APMREMOVE = 32;
	public const String REGSTR_VAL_PCMCIA_MEM = "Memory";
	public const uint32 PCMCIA_DEF_MEMBEGIN = 786432;
	public const uint32 PCMCIA_DEF_MEMEND = 16777215;
	public const uint32 PCMCIA_DEF_MEMLEN = 4096;
	public const String REGSTR_VAL_PCMCIA_ALLOC = "AllocMemWin";
	public const String REGSTR_VAL_PCMCIA_ATAD = "ATADelay";
	public const String REGSTR_VAL_PCMCIA_SIZ = "MinRegionSize";
	public const uint32 PCMCIA_DEF_MIN_REGION = 65536;
	public const String REGSTR_VAL_P1284MDL = "Model";
	public const String REGSTR_VAL_P1284MFG = "Manufacturer";
	public const String REGSTR_VAL_ISAPNP = "ISAPNP";
	public const String REGSTR_VAL_ISAPNP_RDP_OVERRIDE = "RDPOverRide";
	public const String REGSTR_VAL_PCI = "PCI";
	public const String REGSTR_PCI_OPTIONS = "Options";
	public const String REGSTR_PCI_DUAL_IDE = "PCIDualIDE";
	public const int32 PCI_OPTIONS_USE_BIOS = 1;
	public const int32 PCI_OPTIONS_USE_IRQ_STEERING = 2;
	public const int32 AGP_FLAG_NO_1X_RATE = 1;
	public const int32 AGP_FLAG_NO_2X_RATE = 2;
	public const int32 AGP_FLAG_NO_4X_RATE = 4;
	public const int32 AGP_FLAG_NO_8X_RATE = 8;
	public const int32 AGP_FLAG_REVERSE_INITIALIZATION = 128;
	public const int32 AGP_FLAG_NO_SBA_ENABLE = 256;
	public const int32 AGP_FLAG_NO_FW_ENABLE = 512;
	public const int32 AGP_FLAG_SPECIAL_TARGET = 1048575;
	public const int32 AGP_FLAG_SPECIAL_RESERVE = 1015808;
	public const String REGSTR_KEY_CRASHES = "Crashes";
	public const String REGSTR_KEY_DANGERS = "Dangers";
	public const String REGSTR_KEY_DETMODVARS = "DetModVars";
	public const String REGSTR_KEY_NDISINFO = "NDISInfo";
	public const String REGSTR_VAL_PROTINIPATH = "ProtIniPath";
	public const String REGSTR_VAL_RESOURCES = "Resources";
	public const String REGSTR_VAL_CRASHFUNCS = "CrashFuncs";
	public const String REGSTR_VAL_CLASS = "Class";
	public const String REGSTR_VAL_CLASSDESC = "ClassDesc";
	public const String REGSTR_VAL_DEVDESC = "DeviceDesc";
	public const String REGSTR_VAL_BOOTCONFIG = "BootConfig";
	public const String REGSTR_VAL_DETFUNC = "DetFunc";
	public const String REGSTR_VAL_DETFLAGS = "DetFlags";
	public const String REGSTR_VAL_COMPATIBLEIDS = "CompatibleIDs";
	public const String REGSTR_VAL_DETCONFIG = "DetConfig";
	public const String REGSTR_VAL_VERIFYKEY = "VerifyKey";
	public const String REGSTR_VAL_COMINFO = "ComInfo";
	public const String REGSTR_VAL_INFNAME = "InfName";
	public const String REGSTR_VAL_CARDSPECIFIC = "CardSpecific";
	public const String REGSTR_VAL_NETOSTYPE = "NetOSType";
	public const String REGSTR_DATA_NETOS_NDIS = "NDIS";
	public const String REGSTR_DATA_NETOS_ODI = "ODI";
	public const String REGSTR_DATA_NETOS_IPX = "IPX";
	public const String REGSTR_VAL_MFG = "Mfg";
	public const String REGSTR_VAL_SCAN_ONLY_FIRST = "ScanOnlyFirstDrive";
	public const String REGSTR_VAL_SHARE_IRQ = "ForceIRQSharing";
	public const String REGSTR_VAL_NONSTANDARD_ATAPI = "NonStandardATAPI";
	public const String REGSTR_VAL_IDE_FORCE_SERIALIZE = "ForceSerialization";
	public const uint32 REGSTR_VAL_MAX_HCID_LEN = 1024;
	public const String REGSTR_VAL_HWREV = "HWRevision";
	public const String REGSTR_VAL_ENABLEINTS = "EnableInts";
	public const uint32 REGDF_NOTDETIO = 1;
	public const uint32 REGDF_NOTDETMEM = 2;
	public const uint32 REGDF_NOTDETIRQ = 4;
	public const uint32 REGDF_NOTDETDMA = 8;
	public const uint32 REGDF_NEEDFULLCONFIG = 16;
	public const uint32 REGDF_GENFORCEDCONFIG = 32;
	public const uint32 REGDF_NODETCONFIG = 32768;
	public const uint32 REGDF_CONFLICTIO = 65536;
	public const uint32 REGDF_CONFLICTMEM = 131072;
	public const uint32 REGDF_CONFLICTIRQ = 262144;
	public const uint32 REGDF_CONFLICTDMA = 524288;
	public const uint32 REGDF_MAPIRQ2TO9 = 1048576;
	public const uint32 REGDF_NOTVERIFIED = 2147483648;
	public const String REGSTR_VAL_APMBIOSVER = "APMBiosVer";
	public const String REGSTR_VAL_APMFLAGS = "APMFlags";
	public const String REGSTR_VAL_SLSUPPORT = "SLSupport";
	public const String REGSTR_VAL_MACHINETYPE = "MachineType";
	public const String REGSTR_VAL_SETUPMACHINETYPE = "SetupMachineType";
	public const String REGSTR_MACHTYPE_UNKNOWN = "Unknown";
	public const String REGSTR_MACHTYPE_IBMPC = "IBM PC";
	public const String REGSTR_MACHTYPE_IBMPCJR = "IBM PCjr";
	public const String REGSTR_MACHTYPE_IBMPCCONV = "IBM PC Convertible";
	public const String REGSTR_MACHTYPE_IBMPCXT = "IBM PC/XT";
	public const String REGSTR_MACHTYPE_IBMPCXT_286 = "IBM PC/XT 286";
	public const String REGSTR_MACHTYPE_IBMPCAT = "IBM PC/AT";
	public const String REGSTR_MACHTYPE_IBMPS2_25 = "IBM PS/2-25";
	public const String REGSTR_MACHTYPE_IBMPS2_30_286 = "IBM PS/2-30 286";
	public const String REGSTR_MACHTYPE_IBMPS2_30 = "IBM PS/2-30";
	public const String REGSTR_MACHTYPE_IBMPS2_50 = "IBM PS/2-50";
	public const String REGSTR_MACHTYPE_IBMPS2_50Z = "IBM PS/2-50Z";
	public const String REGSTR_MACHTYPE_IBMPS2_55SX = "IBM PS/2-55SX";
	public const String REGSTR_MACHTYPE_IBMPS2_60 = "IBM PS/2-60";
	public const String REGSTR_MACHTYPE_IBMPS2_65SX = "IBM PS/2-65SX";
	public const String REGSTR_MACHTYPE_IBMPS2_70 = "IBM PS/2-70";
	public const String REGSTR_MACHTYPE_IBMPS2_P70 = "IBM PS/2-P70";
	public const String REGSTR_MACHTYPE_IBMPS2_70_80 = "IBM PS/2-70/80";
	public const String REGSTR_MACHTYPE_IBMPS2_80 = "IBM PS/2-80";
	public const String REGSTR_MACHTYPE_IBMPS2_90 = "IBM PS/2-90";
	public const String REGSTR_MACHTYPE_IBMPS1 = "IBM PS/1";
	public const String REGSTR_MACHTYPE_PHOENIX_PCAT = "Phoenix PC/AT Compatible";
	public const String REGSTR_MACHTYPE_HP_VECTRA = "HP Vectra";
	public const String REGSTR_MACHTYPE_ATT_PC = "AT&T PC";
	public const String REGSTR_MACHTYPE_ZENITH_PC = "Zenith PC";
	public const String REGSTR_VAL_APMMENUSUSPEND = "APMMenuSuspend";
	public const uint32 APMMENUSUSPEND_DISABLED = 0;
	public const uint32 APMMENUSUSPEND_ENABLED = 1;
	public const uint32 APMMENUSUSPEND_UNDOCKED = 2;
	public const uint32 APMMENUSUSPEND_NOCHANGE = 128;
	public const String REGSTR_VAL_APMACTIMEOUT = "APMACTimeout";
	public const String REGSTR_VAL_APMBATTIMEOUT = "APMBatTimeout";
	public const uint32 APMTIMEOUT_DISABLED = 0;
	public const String REGSTR_VAL_APMSHUTDOWNPOWER = "APMShutDownPower";
	public const String REGSTR_VAL_BUSTYPE = "BusType";
	public const String REGSTR_VAL_CPU = "CPU";
	public const String REGSTR_VAL_NDP = "NDP";
	public const String REGSTR_VAL_PNPBIOSVER = "PnPBIOSVer";
	public const String REGSTR_VAL_PNPSTRUCOFFSET = "PnPStrucOffset";
	public const String REGSTR_VAL_PCIBIOSVER = "PCIBIOSVer";
	public const String REGSTR_VAL_HWMECHANISM = "HWMechanism";
	public const String REGSTR_VAL_LASTPCIBUSNUM = "LastPCIBusNum";
	public const String REGSTR_VAL_CONVMEM = "ConvMem";
	public const String REGSTR_VAL_EXTMEM = "ExtMem";
	public const String REGSTR_VAL_COMPUTERNAME = "ComputerName";
	public const String REGSTR_VAL_BIOSNAME = "BIOSName";
	public const String REGSTR_VAL_BIOSVERSION = "BIOSVersion";
	public const String REGSTR_VAL_BIOSDATE = "BIOSDate";
	public const String REGSTR_VAL_MODEL = "Model";
	public const String REGSTR_VAL_SUBMODEL = "Submodel";
	public const String REGSTR_VAL_REVISION = "Revision";
	public const String REGSTR_VAL_FIFODEPTH = "FIFODepth";
	public const String REGSTR_VAL_RDINTTHRESHOLD = "RDIntThreshold";
	public const String REGSTR_VAL_WRINTTHRESHOLD = "WRIntThreshold";
	public const String REGSTR_VAL_PRIORITY = "Priority";
	public const String REGSTR_VAL_DRIVER = "Driver";
	public const String REGSTR_VAL_FUNCDESC = "FunctionDesc";
	public const String REGSTR_VAL_FORCEDCONFIG = "ForcedConfig";
	public const String REGSTR_VAL_CONFIGFLAGS = "ConfigFlags";
	public const String REGSTR_VAL_CSCONFIGFLAGS = "CSConfigFlags";
	public const uint32 CONFIGFLAG_DISABLED = 1;
	public const uint32 CONFIGFLAG_REMOVED = 2;
	public const uint32 CONFIGFLAG_MANUAL_INSTALL = 4;
	public const uint32 CONFIGFLAG_IGNORE_BOOT_LC = 8;
	public const uint32 CONFIGFLAG_NET_BOOT = 16;
	public const uint32 CONFIGFLAG_REINSTALL = 32;
	public const uint32 CONFIGFLAG_FAILEDINSTALL = 64;
	public const uint32 CONFIGFLAG_CANTSTOPACHILD = 128;
	public const uint32 CONFIGFLAG_OKREMOVEROM = 256;
	public const uint32 CONFIGFLAG_NOREMOVEEXIT = 512;
	public const uint32 CONFIGFLAG_FINISH_INSTALL = 1024;
	public const uint32 CONFIGFLAG_NEEDS_FORCED_CONFIG = 2048;
	public const uint32 CONFIGFLAG_NETBOOT_CARD = 4096;
	public const uint32 CONFIGFLAG_PARTIAL_LOG_CONF = 8192;
	public const uint32 CONFIGFLAG_SUPPRESS_SURPRISE = 16384;
	public const uint32 CONFIGFLAG_VERIFY_HARDWARE = 32768;
	public const uint32 CONFIGFLAG_FINISHINSTALL_UI = 65536;
	public const uint32 CONFIGFLAG_FINISHINSTALL_ACTION = 131072;
	public const uint32 CONFIGFLAG_BOOT_DEVICE = 262144;
	public const uint32 CONFIGFLAG_NEEDS_CLASS_CONFIG = 524288;
	public const uint32 CSCONFIGFLAG_BITS = 7;
	public const uint32 CSCONFIGFLAG_DISABLED = 1;
	public const uint32 CSCONFIGFLAG_DO_NOT_CREATE = 2;
	public const uint32 CSCONFIGFLAG_DO_NOT_START = 4;
	public const uint32 DMSTATEFLAG_APPLYTOALL = 1;
	public const String REGSTR_VAL_ROOT_DEVNODE = "HTREE\\ROOT\\0";
	public const String REGSTR_VAL_RESERVED_DEVNODE = "HTREE\\RESERVED\\0";
	public const String REGSTR_PATH_MULTI_FUNCTION = "MF";
	public const String REGSTR_VAL_RESOURCE_MAP = "ResourceMap";
	public const String REGSTR_PATH_CHILD_PREFIX = "Child";
	public const uint32 NUM_RESOURCE_MAP = 256;
	public const String REGSTR_VAL_MF_FLAGS = "MFFlags";
	public const uint32 MF_FLAGS_EVEN_IF_NO_RESOURCE = 1;
	public const uint32 MF_FLAGS_NO_CREATE_IF_NO_RESOURCE = 2;
	public const uint32 MF_FLAGS_FILL_IN_UNKNOWN_RESOURCE = 4;
	public const uint32 MF_FLAGS_CREATE_BUT_NO_SHOW_DISABLED = 8;
	public const String REGSTR_VAL_EISA_RANGES = "EISARanges";
	public const String REGSTR_VAL_EISA_FUNCTIONS = "EISAFunctions";
	public const String REGSTR_VAL_EISA_FUNCTIONS_MASK = "EISAFunctionsMask";
	public const String REGSTR_VAL_EISA_FLAGS = "EISAFlags";
	public const String REGSTR_VAL_EISA_SIMULATE_INT15 = "EISASimulateInt15";
	public const uint32 EISAFLAG_NO_IO_MERGE = 1;
	public const uint32 EISAFLAG_SLOT_IO_FIRST = 2;
	public const uint32 EISA_NO_MAX_FUNCTION = 255;
	public const uint32 NUM_EISA_RANGES = 4;
	public const String REGSTR_VAL_DRVDESC = "DriverDesc";
	public const String REGSTR_VAL_DEVLOADER = "DevLoader";
	public const String REGSTR_VAL_STATICVXD = "StaticVxD";
	public const String REGSTR_VAL_PROPERTIES = "Properties";
	public const String REGSTR_VAL_MANUFACTURER = "Manufacturer";
	public const String REGSTR_VAL_EXISTS = "Exists";
	public const String REGSTR_VAL_CMENUMFLAGS = "CMEnumFlags";
	public const String REGSTR_VAL_CMDRIVFLAGS = "CMDrivFlags";
	public const String REGSTR_VAL_ENUMERATOR = "Enumerator";
	public const String REGSTR_VAL_DEVICEDRIVER = "DeviceDriver";
	public const String REGSTR_VAL_PORTNAME = "PortName";
	public const String REGSTR_VAL_INFPATH = "InfPath";
	public const String REGSTR_VAL_INFSECTION = "InfSection";
	public const String REGSTR_VAL_INFSECTIONEXT = "InfSectionExt";
	public const String REGSTR_VAL_POLLING = "Polling";
	public const String REGSTR_VAL_DONTLOADIFCONFLICT = "DontLoadIfConflict";
	public const String REGSTR_VAL_PORTSUBCLASS = "PortSubClass";
	public const String REGSTR_VAL_NETCLEAN = "NetClean";
	public const String REGSTR_VAL_IDE_NO_SERIALIZE = "IDENoSerialize";
	public const String REGSTR_VAL_NOCMOSORFDPT = "NoCMOSorFDPT";
	public const String REGSTR_VAL_COMVERIFYBASE = "COMVerifyBase";
	public const String REGSTR_VAL_MATCHINGDEVID = "MatchingDeviceId";
	public const String REGSTR_VAL_DRIVERDATE = "DriverDate";
	public const String REGSTR_VAL_DRIVERDATEDATA = "DriverDateData";
	public const String REGSTR_VAL_DRIVERVERSION = "DriverVersion";
	public const String REGSTR_VAL_LOCATION_INFORMATION_OVERRIDE = "LocationInformationOverride";
	public const String REGSTR_KEY_OVERRIDE = "Override";
	public const String REGSTR_VAL_CONFIGMG = "CONFIGMG";
	public const String REGSTR_VAL_SYSDM = "SysDM";
	public const String REGSTR_VAL_SYSDMFUNC = "SysDMFunc";
	public const String REGSTR_VAL_PRIVATE = "Private";
	public const String REGSTR_VAL_PRIVATEFUNC = "PrivateFunc";
	public const String REGSTR_VAL_DETECT = "Detect";
	public const String REGSTR_VAL_DETECTFUNC = "DetectFunc";
	public const String REGSTR_VAL_ASKFORCONFIG = "AskForConfig";
	public const String REGSTR_VAL_ASKFORCONFIGFUNC = "AskForConfigFunc";
	public const String REGSTR_VAL_WAITFORUNDOCK = "WaitForUndock";
	public const String REGSTR_VAL_WAITFORUNDOCKFUNC = "WaitForUndockFunc";
	public const String REGSTR_VAL_REMOVEROMOKAY = "RemoveRomOkay";
	public const String REGSTR_VAL_REMOVEROMOKAYFUNC = "RemoveRomOkayFunc";
	public const String REGSTR_VAL_CURCONFIG = "CurrentConfig";
	public const String REGSTR_VAL_FRIENDLYNAME = "FriendlyName";
	public const String REGSTR_VAL_CURRENTCONFIG = "CurrentConfig";
	public const String REGSTR_VAL_MAP = "Map";
	public const String REGSTR_VAL_ID = "CurrentID";
	public const String REGSTR_VAL_DOCKED = "CurrentDockedState";
	public const String REGSTR_VAL_CHECKSUM = "CurrentChecksum";
	public const String REGSTR_VAL_HWDETECT = "HardwareDetect";
	public const String REGSTR_VAL_INHIBITRESULTS = "InhibitResults";
	public const String REGSTR_VAL_PROFILEFLAGS = "ProfileFlags";
	public const String REGSTR_KEY_PCMCIA = "PCMCIA\\";
	public const String REGSTR_KEY_PCUNKNOWN = "UNKNOWN_MANUFACTURER";
	public const String REGSTR_VAL_PCSSDRIVER = "Driver";
	public const String REGSTR_KEY_PCMTD = "MTD-";
	public const String REGSTR_VAL_PCMTDRIVER = "MTD";
	public const String REGSTR_VAL_HARDWAREID = "HardwareID";
	public const String REGSTR_VAL_INSTALLER = "Installer";
	public const String REGSTR_VAL_INSTALLER_32 = "Installer32";
	public const String REGSTR_VAL_INSICON = "Icon";
	public const String REGSTR_VAL_ENUMPROPPAGES = "EnumPropPages";
	public const String REGSTR_VAL_ENUMPROPPAGES_32 = "EnumPropPages32";
	public const String REGSTR_VAL_BASICPROPERTIES = "BasicProperties";
	public const String REGSTR_VAL_BASICPROPERTIES_32 = "BasicProperties32";
	public const String REGSTR_VAL_COINSTALLERS_32 = "CoInstallers32";
	public const String REGSTR_VAL_PRIVATEPROBLEM = "PrivateProblem";
	public const String REGSTR_KEY_CURRENT = "Current";
	public const String REGSTR_KEY_DEFAULT = "Default";
	public const String REGSTR_KEY_MODES = "Modes";
	public const String REGSTR_VAL_MODE = "Mode";
	public const String REGSTR_VAL_BPP = "BPP";
	public const String REGSTR_VAL_HRES = "HRes";
	public const String REGSTR_VAL_VRES = "VRes";
	public const String REGSTR_VAL_FONTSIZE = "FontSize";
	public const String REGSTR_VAL_DRV = "drv";
	public const String REGSTR_VAL_GRB = "grb";
	public const String REGSTR_VAL_VDD = "vdd";
	public const String REGSTR_VAL_VER = "Ver";
	public const String REGSTR_VAL_MAXRES = "MaxResolution";
	public const String REGSTR_VAL_DPMS = "DPMS";
	public const String REGSTR_VAL_RESUMERESET = "ResumeReset";
	public const String REGSTR_KEY_SYSTEM = "System";
	public const String REGSTR_KEY_USER = "User";
	public const String REGSTR_VAL_DPI = "dpi";
	public const String REGSTR_VAL_PCICOPTIONS = "PCICOptions";
	public const uint32 PCIC_DEFAULT_IRQMASK = 20152;
	public const uint32 PCIC_DEFAULT_NUMSOCKETS = 0;
	public const String REGSTR_VAL_PCICIRQMAP = "PCICIRQMap";
	public const String REGSTR_PATH_APPEARANCE = "Control Panel\\Appearance";
	public const String REGSTR_PATH_LOOKSCHEMES = "Control Panel\\Appearance\\Schemes";
	public const String REGSTR_VAL_CUSTOMCOLORS = "CustomColors";
	public const String REGSTR_PATH_SCREENSAVE = "Control Panel\\Desktop";
	public const String REGSTR_VALUE_USESCRPASSWORD = "ScreenSaveUsePassword";
	public const String REGSTR_VALUE_SCRPASSWORD = "ScreenSave_Data";
	public const String REGSTR_VALUE_LOWPOWERTIMEOUT = "ScreenSaveLowPowerTimeout";
	public const String REGSTR_VALUE_POWEROFFTIMEOUT = "ScreenSavePowerOffTimeout";
	public const String REGSTR_VALUE_LOWPOWERACTIVE = "ScreenSaveLowPowerActive";
	public const String REGSTR_VALUE_POWEROFFACTIVE = "ScreenSavePowerOffActive";
	public const String REGSTR_PATH_WINDOWSAPPLETS = "Software\\Microsoft\\Windows\\CurrentVersion\\Applets";
	public const String REGSTR_PATH_SYSTRAY = "Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\SysTray";
	public const String REGSTR_VAL_SYSTRAYSVCS = "Services";
	public const String REGSTR_VAL_SYSTRAYBATFLAGS = "PowerFlags";
	public const String REGSTR_VAL_SYSTRAYPCCARDFLAGS = "PCMCIAFlags";
	public const String REGSTR_PATH_NETWORK_USERSETTINGS = "Network";
	public const String REGSTR_KEY_NETWORK_PERSISTENT = "\\Persistent";
	public const String REGSTR_KEY_NETWORK_RECENT = "\\Recent";
	public const String REGSTR_VAL_REMOTE_PATH = "RemotePath";
	public const String REGSTR_VAL_USER_NAME = "UserName";
	public const String REGSTR_VAL_PROVIDER_NAME = "ProviderName";
	public const String REGSTR_VAL_CONNECTION_TYPE = "ConnectionType";
	public const String REGSTR_VAL_UPGRADE = "Upgrade";
	public const String REGSTR_KEY_LOGON = "\\Logon";
	public const String REGSTR_VAL_MUSTBEVALIDATED = "MustBeValidated";
	public const String REGSTR_VAL_RUNLOGINSCRIPT = "ProcessLoginScript";
	public const String REGSTR_KEY_NETWORKPROVIDER = "\\NetworkProvider";
	public const String REGSTR_VAL_AUTHENT_AGENT = "AuthenticatingAgent";
	public const String REGSTR_VAL_PREFREDIR = "PreferredRedir";
	public const String REGSTR_VAL_AUTOSTART = "AutoStart";
	public const String REGSTR_VAL_AUTOLOGON = "AutoLogon";
	public const String REGSTR_VAL_NETCARD = "Netcard";
	public const String REGSTR_VAL_TRANSPORT = "Transport";
	public const String REGSTR_VAL_DYNAMIC = "Dynamic";
	public const String REGSTR_VAL_TRANSITION = "Transition";
	public const String REGSTR_VAL_STATICDRIVE = "StaticDrive";
	public const String REGSTR_VAL_LOADHI = "LoadHi";
	public const String REGSTR_VAL_LOADRMDRIVERS = "LoadRMDrivers";
	public const String REGSTR_VAL_SETUPN = "SetupN";
	public const String REGSTR_VAL_SETUPNPATH = "SetupNPath";
	public const String REGSTR_VAL_WRKGRP_FORCEMAPPING = "WrkgrpForceMapping";
	public const String REGSTR_VAL_WRKGRP_REQUIRED = "WrkgrpRequired";
	public const String REGSTR_PATH_CURRENT_CONTROL_SET = "System\\CurrentControlSet\\Control";
	public const String REGSTR_VAL_CURRENT_USER = "Current User";
	public const String REGSTR_PATH_PWDPROVIDER = "System\\CurrentControlSet\\Control\\PwdProvider";
	public const String REGSTR_VAL_PWDPROVIDER_PATH = "ProviderPath";
	public const String REGSTR_VAL_PWDPROVIDER_DESC = "Description";
	public const String REGSTR_VAL_PWDPROVIDER_CHANGEPWD = "ChangePassword";
	public const String REGSTR_VAL_PWDPROVIDER_CHANGEPWDHWND = "ChangePasswordHwnd";
	public const String REGSTR_VAL_PWDPROVIDER_GETPWDSTATUS = "GetPasswordStatus";
	public const String REGSTR_VAL_PWDPROVIDER_ISNP = "NetworkProvider";
	public const String REGSTR_VAL_PWDPROVIDER_CHANGEORDER = "ChangeOrder";
	public const String REGSTR_PATH_POLICIES = "Software\\Microsoft\\Windows\\CurrentVersion\\Policies";
	public const String REGSTR_PATH_UPDATE = "System\\CurrentControlSet\\Control\\Update";
	public const String REGSTR_VALUE_ENABLE = "Enable";
	public const String REGSTR_VALUE_VERBOSE = "Verbose";
	public const String REGSTR_VALUE_NETPATH = "NetworkPath";
	public const String REGSTR_VALUE_DEFAULTLOC = "UseDefaultNetLocation";
	public const String REGSTR_KEY_NETWORK = "Network";
	public const String REGSTR_KEY_PRINTERS = "Printers";
	public const String REGSTR_KEY_WINOLDAPP = "WinOldApp";
	public const String REGSTR_KEY_EXPLORER = "Explorer";
	public const String REGSTR_VAL_NOFILESHARING = "NoFileSharing";
	public const String REGSTR_VAL_NOPRINTSHARING = "NoPrintSharing";
	public const String REGSTR_VAL_NOFILESHARINGCTRL = "NoFileSharingControl";
	public const String REGSTR_VAL_NOPRINTSHARINGCTRL = "NoPrintSharingControl";
	public const String REGSTR_VAL_HIDESHAREPWDS = "HideSharePwds";
	public const String REGSTR_VAL_DISABLEPWDCACHING = "DisablePwdCaching";
	public const String REGSTR_VAL_ALPHANUMPWDS = "AlphanumPwds";
	public const String REGSTR_VAL_NETSETUP_DISABLE = "NoNetSetup";
	public const String REGSTR_VAL_NETSETUP_NOCONFIGPAGE = "NoNetSetupConfigPage";
	public const String REGSTR_VAL_NETSETUP_NOIDPAGE = "NoNetSetupIDPage";
	public const String REGSTR_VAL_NETSETUP_NOSECURITYPAGE = "NoNetSetupSecurityPage";
	public const String REGSTR_VAL_SYSTEMCPL_NOVIRTMEMPAGE = "NoVirtMemPage";
	public const String REGSTR_VAL_SYSTEMCPL_NODEVMGRPAGE = "NoDevMgrPage";
	public const String REGSTR_VAL_SYSTEMCPL_NOCONFIGPAGE = "NoConfigPage";
	public const String REGSTR_VAL_SYSTEMCPL_NOFILESYSPAGE = "NoFileSysPage";
	public const String REGSTR_VAL_DISPCPL_NODISPCPL = "NoDispCPL";
	public const String REGSTR_VAL_DISPCPL_NOBACKGROUNDPAGE = "NoDispBackgroundPage";
	public const String REGSTR_VAL_DISPCPL_NOSCRSAVPAGE = "NoDispScrSavPage";
	public const String REGSTR_VAL_DISPCPL_NOAPPEARANCEPAGE = "NoDispAppearancePage";
	public const String REGSTR_VAL_DISPCPL_NOSETTINGSPAGE = "NoDispSettingsPage";
	public const String REGSTR_VAL_SECCPL_NOSECCPL = "NoSecCPL";
	public const String REGSTR_VAL_SECCPL_NOPWDPAGE = "NoPwdPage";
	public const String REGSTR_VAL_SECCPL_NOADMINPAGE = "NoAdminPage";
	public const String REGSTR_VAL_SECCPL_NOPROFILEPAGE = "NoProfilePage";
	public const String REGSTR_VAL_PRINTERS_HIDETABS = "NoPrinterTabs";
	public const String REGSTR_VAL_PRINTERS_NODELETE = "NoDeletePrinter";
	public const String REGSTR_VAL_PRINTERS_NOADD = "NoAddPrinter";
	public const String REGSTR_VAL_WINOLDAPP_DISABLED = "Disabled";
	public const String REGSTR_VAL_WINOLDAPP_NOREALMODE = "NoRealMode";
	public const String REGSTR_VAL_NOENTIRENETWORK = "NoEntireNetwork";
	public const String REGSTR_VAL_NOWORKGROUPCONTENTS = "NoWorkgroupContents";
	public const String REGSTR_VAL_UNDOCK_WITHOUT_LOGON = "UndockWithoutLogon";
	public const String REGSTR_VAL_MINPWDLEN = "MinPwdLen";
	public const String REGSTR_VAL_PWDEXPIRATION = "PwdExpiration";
	public const String REGSTR_VAL_WIN31PROVIDER = "Win31Provider";
	public const String REGSTR_VAL_DISABLEREGTOOLS = "DisableRegistryTools";
	public const String REGSTR_PATH_WINLOGON = "Software\\Microsoft\\Windows\\CurrentVersion\\Winlogon";
	public const String REGSTR_VAL_LEGALNOTICECAPTION = "LegalNoticeCaption";
	public const String REGSTR_VAL_LEGALNOTICETEXT = "LegalNoticeText";
	public const String REGSTR_VAL_DRIVE_SPINDOWN = "NoDispSpinDown";
	public const String REGSTR_VAL_SHUTDOWN_FLAGS = "ShutdownFlags";
	public const String REGSTR_VAL_RESTRICTRUN = "RestrictRun";
	public const String REGSTR_KEY_POL_USERS = "Users";
	public const String REGSTR_KEY_POL_COMPUTERS = "Computers";
	public const String REGSTR_KEY_POL_USERGROUPS = "UserGroups";
	public const String REGSTR_KEY_POL_DEFAULT = ".default";
	public const String REGSTR_KEY_POL_USERGROUPDATA = "GroupData\\UserGroups\\Priority";
	public const String REGSTR_PATH_TIMEZONE = "System\\CurrentControlSet\\Control\\TimeZoneInformation";
	public const String REGSTR_VAL_TZBIAS = "Bias";
	public const String REGSTR_VAL_TZDLTBIAS = "DaylightBias";
	public const String REGSTR_VAL_TZSTDBIAS = "StandardBias";
	public const String REGSTR_VAL_TZACTBIAS = "ActiveTimeBias";
	public const String REGSTR_VAL_TZDLTFLAG = "DaylightFlag";
	public const String REGSTR_VAL_TZSTDSTART = "StandardStart";
	public const String REGSTR_VAL_TZDLTSTART = "DaylightStart";
	public const String REGSTR_VAL_TZDLTNAME = "DaylightName";
	public const String REGSTR_VAL_TZSTDNAME = "StandardName";
	public const String REGSTR_VAL_TZNOCHANGESTART = "NoChangeStart";
	public const String REGSTR_VAL_TZNOCHANGEEND = "NoChangeEnd";
	public const String REGSTR_VAL_TZNOAUTOTIME = "DisableAutoDaylightTimeSet";
	public const String REGSTR_PATH_FLOATINGPOINTPROCESSOR = "HARDWARE\\DESCRIPTION\\System\\FloatingPointProcessor";
	public const String REGSTR_PATH_FLOATINGPOINTPROCESSOR0 = "HARDWARE\\DESCRIPTION\\System\\FloatingPointProcessor\\0";
	public const String REGSTR_PATH_COMPUTRNAME = "System\\CurrentControlSet\\Control\\ComputerName\\ComputerName";
	public const String REGSTR_VAL_COMPUTRNAME = "ComputerName";
	public const String REGSTR_PATH_SHUTDOWN = "System\\CurrentControlSet\\Control\\Shutdown";
	public const String REGSTR_VAL_FORCEREBOOT = "ForceReboot";
	public const String REGSTR_VAL_SETUPPROGRAMRAN = "SetupProgramRan";
	public const String REGSTR_VAL_DOES_POLLING = "PollingSupportNeeded";
	public const String REGSTR_PATH_KNOWNDLLS = "System\\CurrentControlSet\\Control\\SessionManager\\KnownDLLs";
	public const String REGSTR_PATH_KNOWN16DLLS = "System\\CurrentControlSet\\Control\\SessionManager\\Known16DLLs";
	public const String REGSTR_PATH_CHECKVERDLLS = "System\\CurrentControlSet\\Control\\SessionManager\\CheckVerDLLs";
	public const String REGSTR_PATH_WARNVERDLLS = "System\\CurrentControlSet\\Control\\SessionManager\\WarnVerDLLs";
	public const String REGSTR_PATH_HACKINIFILE = "System\\CurrentControlSet\\Control\\SessionManager\\HackIniFiles";
	public const String REGSTR_PATH_CHECKBADAPPS = "System\\CurrentControlSet\\Control\\SessionManager\\CheckBadApps";
	public const String REGSTR_PATH_APPPATCH = "System\\CurrentControlSet\\Control\\SessionManager\\AppPatches";
	public const String REGSTR_PATH_CHECKBADAPPS400 = "System\\CurrentControlSet\\Control\\SessionManager\\CheckBadApps400";
	public const String REGSTR_PATH_KNOWNVXDS = "System\\CurrentControlSet\\Control\\SessionManager\\KnownVxDs";
	public const String REGSTR_VAL_UNINSTALLER_DISPLAYNAME = "DisplayName";
	public const String REGSTR_VAL_UNINSTALLER_COMMANDLINE = "UninstallString";
	public const String REGSTR_VAL_REINSTALL_DISPLAYNAME = "DisplayName";
	public const String REGSTR_VAL_REINSTALL_STRING = "ReinstallString";
	public const String REGSTR_VAL_REINSTALL_DEVICEINSTANCEIDS = "DeviceInstanceIds";
	public const String REGSTR_PATH_DESKTOP = "Control Panel\\Desktop";
	public const String REGSTR_PATH_MOUSE = "Control Panel\\Mouse";
	public const String REGSTR_PATH_KEYBOARD = "Control Panel\\Keyboard";
	public const String REGSTR_PATH_COLORS = "Control Panel\\Colors";
	public const String REGSTR_PATH_SOUND = "Control Panel\\Sound";
	public const String REGSTR_PATH_METRICS = "Control Panel\\Desktop\\WindowMetrics";
	public const String REGSTR_PATH_ICONS = "Control Panel\\Icons";
	public const String REGSTR_PATH_CURSORS = "Control Panel\\Cursors";
	public const String REGSTR_PATH_CHECKDISK = "Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Check Drive";
	public const String REGSTR_PATH_CHECKDISKSET = "Settings";
	public const String REGSTR_PATH_CHECKDISKUDRVS = "NoUnknownDDErrDrvs";
	public const String REGSTR_PATH_FAULT = "Software\\Microsoft\\Windows\\CurrentVersion\\Fault";
	public const String REGSTR_VAL_FAULT_LOGFILE = "LogFile";
	public const String REGSTR_PATH_AEDEBUG = "Software\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug";
	public const String REGSTR_VAL_AEDEBUG_DEBUGGER = "Debugger";
	public const String REGSTR_VAL_AEDEBUG_AUTO = "Auto";
	public const String REGSTR_PATH_GRPCONV = "Software\\Microsoft\\Windows\\CurrentVersion\\GrpConv";
	public const String REGSTR_VAL_REGITEMDELETEMESSAGE = "Removal Message";
	public const String REGSTR_PATH_LASTCHECK = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\LastCheck";
	public const String REGSTR_PATH_LASTOPTIMIZE = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\LastOptimize";
	public const String REGSTR_PATH_LASTBACKUP = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\LastBackup";
	public const String REGSTR_PATH_CHKLASTCHECK = "Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Check Drive\\LastCheck";
	public const String REGSTR_PATH_CHKLASTSURFAN = "Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Check Drive\\LastSurfaceAnalysis";
	public const uint32 DTRESULTOK = 0;
	public const uint32 DTRESULTFIX = 1;
	public const uint32 DTRESULTPROB = 2;
	public const uint32 DTRESULTPART = 3;
	public const String REGSTR_KEY_SHARES = "Software\\Microsoft\\Windows\\CurrentVersion\\Network\\LanMan";
	public const String REGSTR_VAL_SHARES_FLAGS = "Flags";
	public const String REGSTR_VAL_SHARES_TYPE = "Type";
	public const String REGSTR_VAL_SHARES_PATH = "Path";
	public const String REGSTR_VAL_SHARES_REMARK = "Remark";
	public const String REGSTR_VAL_SHARES_RW_PASS = "Parm1";
	public const String REGSTR_VAL_SHARES_RO_PASS = "Parm2";
	public const String REGSTR_PATH_PRINT = "System\\CurrentControlSet\\Control\\Print";
	public const String REGSTR_PATH_PRINTERS = "System\\CurrentControlSet\\Control\\Print\\Printers";
	public const String REGSTR_PATH_PROVIDERS = "System\\CurrentControlSet\\Control\\Print\\Providers";
	public const String REGSTR_PATH_MONITORS = "System\\CurrentControlSet\\Control\\Print\\Monitors";
	public const String REGSTR_PATH_ENVIRONMENTS = "System\\CurrentControlSet\\Control\\Print\\Environments";
	public const String REGSTR_VAL_START_ON_BOOT = "StartOnBoot";
	public const String REGSTR_VAL_PRINTERS_MASK = "PrintersMask";
	public const String REGSTR_VAL_DOS_SPOOL_MASK = "DOSSpoolMask";
	public const String REGSTR_KEY_CURRENT_ENV = "\\Windows 4.0";
	public const String REGSTR_KEY_DRIVERS = "\\Drivers";
	public const String REGSTR_KEY_PRINT_PROC = "\\Print Processors";
	public const String REGSTR_PATH_EVENTLABELS = "AppEvents\\EventLabels";
	public const String REGSTR_PATH_SCHEMES = "AppEvents\\Schemes";
	public const String REGSTR_PATH_MULTIMEDIA_AUDIO = "Software\\Microsoft\\Multimedia\\Audio";
	public const String REGSTR_KEY_JOYCURR = "CurrentJoystickSettings";
	public const String REGSTR_KEY_JOYSETTINGS = "JoystickSettings";
	public const String REGSTR_VAL_JOYUSERVALUES = "JoystickUserValues";
	public const String REGSTR_VAL_JOYCALLOUT = "JoystickCallout";
	public const String REGSTR_VAL_JOYNCONFIG = "Joystick%dConfiguration";
	public const String REGSTR_VAL_JOYNOEMNAME = "Joystick%dOEMName";
	public const String REGSTR_VAL_JOYNOEMCALLOUT = "Joystick%dOEMCallout";
	public const String REGSTR_VAL_JOYOEMCALLOUT = "OEMCallout";
	public const String REGSTR_VAL_JOYOEMNAME = "OEMName";
	public const String REGSTR_VAL_JOYOEMDATA = "OEMData";
	public const String REGSTR_VAL_JOYOEMXYLABEL = "OEMXYLabel";
	public const String REGSTR_VAL_JOYOEMZLABEL = "OEMZLabel";
	public const String REGSTR_VAL_JOYOEMRLABEL = "OEMRLabel";
	public const String REGSTR_VAL_JOYOEMPOVLABEL = "OEMPOVLabel";
	public const String REGSTR_VAL_JOYOEMULABEL = "OEMULabel";
	public const String REGSTR_VAL_JOYOEMVLABEL = "OEMVLabel";
	public const String REGSTR_VAL_JOYOEMTESTMOVEDESC = "OEMTestMoveDesc";
	public const String REGSTR_VAL_JOYOEMTESTBUTTONDESC = "OEMTestButtonDesc";
	public const String REGSTR_VAL_JOYOEMTESTMOVECAP = "OEMTestMoveCap";
	public const String REGSTR_VAL_JOYOEMTESTBUTTONCAP = "OEMTestButtonCap";
	public const String REGSTR_VAL_JOYOEMTESTWINCAP = "OEMTestWinCap";
	public const String REGSTR_VAL_JOYOEMCALCAP = "OEMCalCap";
	public const String REGSTR_VAL_JOYOEMCALWINCAP = "OEMCalWinCap";
	public const String REGSTR_VAL_JOYOEMCAL1 = "OEMCal1";
	public const String REGSTR_VAL_JOYOEMCAL2 = "OEMCal2";
	public const String REGSTR_VAL_JOYOEMCAL3 = "OEMCal3";
	public const String REGSTR_VAL_JOYOEMCAL4 = "OEMCal4";
	public const String REGSTR_VAL_JOYOEMCAL5 = "OEMCal5";
	public const String REGSTR_VAL_JOYOEMCAL6 = "OEMCal6";
	public const String REGSTR_VAL_JOYOEMCAL7 = "OEMCal7";
	public const String REGSTR_VAL_JOYOEMCAL8 = "OEMCal8";
	public const String REGSTR_VAL_JOYOEMCAL9 = "OEMCal9";
	public const String REGSTR_VAL_JOYOEMCAL10 = "OEMCal10";
	public const String REGSTR_VAL_JOYOEMCAL11 = "OEMCal11";
	public const String REGSTR_VAL_JOYOEMCAL12 = "OEMCal12";
	public const String REGSTR_VAL_AUDIO_BITMAP = "bitmap";
	public const String REGSTR_VAL_AUDIO_ICON = "icon";
	public const String REGSTR_PATH_DEVICEINSTALLER = "Software\\Microsoft\\Windows\\CurrentVersion\\Device Installer";
	public const String REGSTR_PATH_DIFX = "Software\\Microsoft\\Windows\\CurrentVersion\\DIFX";
	public const String REGSTR_VAL_SEARCHOPTIONS = "SearchOptions";
	public const String REGSTR_PATH_BIOSINFO = "System\\CurrentControlSet\\Control\\BiosInfo";
	public const String REGSTR_PATH_PCIIR = "System\\CurrentControlSet\\Control\\Pnp\\PciIrqRouting";
	public const String REGSTR_VAL_OPTIONS = "Options";
	public const String REGSTR_VAL_STAT = "Status";
	public const String REGSTR_VAL_TABLE_STAT = "TableStatus";
	public const String REGSTR_VAL_MINIPORT_STAT = "MiniportStatus";
	public const uint32 PIR_OPTION_ENABLED = 1;
	public const uint32 PIR_OPTION_REGISTRY = 2;
	public const uint32 PIR_OPTION_MSSPEC = 4;
	public const uint32 PIR_OPTION_REALMODE = 8;
	public const uint32 PIR_OPTION_DEFAULT = 15;
	public const uint32 PIR_STATUS_ERROR = 0;
	public const uint32 PIR_STATUS_ENABLED = 1;
	public const uint32 PIR_STATUS_DISABLED = 2;
	public const uint32 PIR_STATUS_MAX = 3;
	public const uint32 PIR_STATUS_TABLE_REGISTRY = 0;
	public const uint32 PIR_STATUS_TABLE_MSSPEC = 1;
	public const uint32 PIR_STATUS_TABLE_REALMODE = 2;
	public const uint32 PIR_STATUS_TABLE_NONE = 3;
	public const uint32 PIR_STATUS_TABLE_ERROR = 4;
	public const uint32 PIR_STATUS_TABLE_BAD = 5;
	public const uint32 PIR_STATUS_TABLE_SUCCESS = 6;
	public const uint32 PIR_STATUS_TABLE_MAX = 7;
	public const uint32 PIR_STATUS_MINIPORT_NORMAL = 0;
	public const uint32 PIR_STATUS_MINIPORT_COMPATIBLE = 1;
	public const uint32 PIR_STATUS_MINIPORT_OVERRIDE = 2;
	public const uint32 PIR_STATUS_MINIPORT_NONE = 3;
	public const uint32 PIR_STATUS_MINIPORT_ERROR = 4;
	public const uint32 PIR_STATUS_MINIPORT_NOKEY = 5;
	public const uint32 PIR_STATUS_MINIPORT_SUCCESS = 6;
	public const uint32 PIR_STATUS_MINIPORT_INVALID = 7;
	public const uint32 PIR_STATUS_MINIPORT_MAX = 8;
	public const String REGSTR_PATH_LASTGOOD = "System\\LastKnownGoodRecovery\\LastGood";
	public const String REGSTR_PATH_LASTGOODTMP = "System\\LastKnownGoodRecovery\\LastGood.Tmp";
	public const uint32 LASTGOOD_OPERATION = 255;
	public const uint32 LASTGOOD_OPERATION_NOPOSTPROC = 0;
	public const uint32 LASTGOOD_OPERATION_DELETE = 1;
}
#endregion

#region TypeDefs
typealias HKEY = int;

#endregion


#region Enums

[AllowDuplicates]
public enum REG_VALUE_TYPE : uint32
{
	REG_NONE = 0,
	REG_SZ = 1,
	REG_EXPAND_SZ = 2,
	REG_BINARY = 3,
	REG_DWORD = 4,
	REG_DWORD_LITTLE_ENDIAN = 4,
	REG_DWORD_BIG_ENDIAN = 5,
	REG_LINK = 6,
	REG_MULTI_SZ = 7,
	REG_RESOURCE_LIST = 8,
	REG_FULL_RESOURCE_DESCRIPTOR = 9,
	REG_RESOURCE_REQUIREMENTS_LIST = 10,
	REG_QWORD = 11,
	REG_QWORD_LITTLE_ENDIAN = 11,
}


[AllowDuplicates]
public enum REG_SAM_FLAGS : uint32
{
	KEY_QUERY_VALUE = 1,
	KEY_SET_VALUE = 2,
	KEY_CREATE_SUB_KEY = 4,
	KEY_ENUMERATE_SUB_KEYS = 8,
	KEY_NOTIFY = 16,
	KEY_CREATE_LINK = 32,
	KEY_WOW64_32KEY = 512,
	KEY_WOW64_64KEY = 256,
	KEY_WOW64_RES = 768,
	KEY_READ = 131097,
	KEY_WRITE = 131078,
	KEY_EXECUTE = 131097,
	KEY_ALL_ACCESS = 983103,
}


[AllowDuplicates]
public enum REG_OPEN_CREATE_OPTIONS : uint32
{
	REG_OPTION_RESERVED = 0,
	REG_OPTION_NON_VOLATILE = 0,
	REG_OPTION_VOLATILE = 1,
	REG_OPTION_CREATE_LINK = 2,
	REG_OPTION_BACKUP_RESTORE = 4,
	REG_OPTION_OPEN_LINK = 8,
	REG_OPTION_DONT_VIRTUALIZE = 16,
}


[AllowDuplicates]
public enum REG_CREATE_KEY_DISPOSITION : uint32
{
	REG_CREATED_NEW_KEY = 1,
	REG_OPENED_EXISTING_KEY = 2,
}


[AllowDuplicates]
public enum REG_SAVE_FORMAT : uint32
{
	REG_STANDARD_FORMAT = 1,
	REG_LATEST_FORMAT = 2,
	REG_NO_COMPRESSION = 4,
}


[AllowDuplicates]
public enum REG_RESTORE_KEY_FLAGS : int32
{
	REG_FORCE_RESTORE = 8,
	REG_WHOLE_HIVE_VOLATILE = 1,
}


[AllowDuplicates]
public enum REG_NOTIFY_FILTER : uint32
{
	REG_NOTIFY_CHANGE_NAME = 1,
	REG_NOTIFY_CHANGE_ATTRIBUTES = 2,
	REG_NOTIFY_CHANGE_LAST_SET = 4,
	REG_NOTIFY_CHANGE_SECURITY = 8,
	REG_NOTIFY_THREAD_AGNOSTIC = 268435456,
}


[AllowDuplicates]
public enum RRF_RT : uint32
{
	RRF_RT_ANY = 65535,
	RRF_RT_DWORD = 24,
	RRF_RT_QWORD = 72,
	RRF_RT_REG_BINARY = 8,
	RRF_RT_REG_DWORD = 16,
	RRF_RT_REG_EXPAND_SZ = 4,
	RRF_RT_REG_MULTI_SZ = 32,
	RRF_RT_REG_NONE = 1,
	RRF_RT_REG_QWORD = 64,
	RRF_RT_REG_SZ = 2,
}

#endregion

#region Function Pointers
public function uint32 PQUERYHANDLER(void* keycontext, val_context* val_list, uint32 num_vals, void* outputbuffer, uint32* total_outlen, uint32 input_blen);

#endregion

#region Structs
[CRepr]
public struct val_context
{
	public int32 valuelen;
	public void* value_context;
	public void* val_buff_ptr;
}

[CRepr]
public struct PVALUEA
{
	public PSTR pv_valuename;
	public int32 pv_valuelen;
	public void* pv_value_context;
	public uint32 pv_type;
}

[CRepr]
public struct PVALUEW
{
	public PWSTR pv_valuename;
	public int32 pv_valuelen;
	public void* pv_value_context;
	public uint32 pv_type;
}

[CRepr]
public struct REG_PROVIDER
{
	public PQUERYHANDLER pi_R0_1val;
	public PQUERYHANDLER pi_R0_allvals;
	public PQUERYHANDLER pi_R3_1val;
	public PQUERYHANDLER pi_R3_allvals;
	public uint32 pi_flags;
	public void* pi_key_context;
}

[CRepr]
public struct VALENTA
{
	public PSTR ve_valuename;
	public uint32 ve_valuelen;
	public uint ve_valueptr;
	public REG_VALUE_TYPE ve_type;
}

[CRepr]
public struct VALENTW
{
	public PWSTR ve_valuename;
	public uint32 ve_valuelen;
	public uint ve_valueptr;
	public REG_VALUE_TYPE ve_type;
}

[CRepr]
public struct DSKTLSYSTEMTIME
{
	public uint16 wYear;
	public uint16 wMonth;
	public uint16 wDayOfWeek;
	public uint16 wDay;
	public uint16 wHour;
	public uint16 wMinute;
	public uint16 wSecond;
	public uint16 wMilliseconds;
	public uint16 wResult;
}

#endregion

#region Functions
public static
{
	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCloseKey(HKEY hKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOverridePredefKey(HKEY hKey, HKEY hNewHKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenUserClassesRoot(HANDLE hToken, uint32 dwOptions, uint32 samDesired, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenCurrentUser(uint32 samDesired, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDisablePredefinedCache();

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDisablePredefinedCacheEx();

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegConnectRegistryA(PSTR lpMachineName, HKEY hKey, HKEY* phkResult);
	public static WIN32_ERROR RegConnectRegistry(PSTR lpMachineName, HKEY hKey, HKEY* phkResult) => RegConnectRegistryA(lpMachineName, hKey, phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegConnectRegistryW(PWSTR lpMachineName, HKEY hKey, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RegConnectRegistryExA(PSTR lpMachineName, HKEY hKey, uint32 Flags, HKEY* phkResult);
	public static int32 RegConnectRegistryEx(PSTR lpMachineName, HKEY hKey, uint32 Flags, HKEY* phkResult) => RegConnectRegistryExA(lpMachineName, hKey, Flags, phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RegConnectRegistryExW(PWSTR lpMachineName, HKEY hKey, uint32 Flags, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCreateKeyA(HKEY hKey, PSTR lpSubKey, HKEY* phkResult);
	public static WIN32_ERROR RegCreateKey(HKEY hKey, PSTR lpSubKey, HKEY* phkResult) => RegCreateKeyA(hKey, lpSubKey, phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCreateKeyW(HKEY hKey, PWSTR lpSubKey, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCreateKeyExA(HKEY hKey, PSTR lpSubKey, uint32 Reserved, PSTR lpClass, REG_OPEN_CREATE_OPTIONS dwOptions, REG_SAM_FLAGS samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, REG_CREATE_KEY_DISPOSITION* lpdwDisposition);
	public static WIN32_ERROR RegCreateKeyEx(HKEY hKey, PSTR lpSubKey, uint32 Reserved, PSTR lpClass, REG_OPEN_CREATE_OPTIONS dwOptions, REG_SAM_FLAGS samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, REG_CREATE_KEY_DISPOSITION* lpdwDisposition) => RegCreateKeyExA(hKey, lpSubKey, Reserved, lpClass, dwOptions, samDesired, lpSecurityAttributes, phkResult, lpdwDisposition);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCreateKeyExW(HKEY hKey, PWSTR lpSubKey, uint32 Reserved, PWSTR lpClass, REG_OPEN_CREATE_OPTIONS dwOptions, REG_SAM_FLAGS samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, REG_CREATE_KEY_DISPOSITION* lpdwDisposition);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCreateKeyTransactedA(HKEY hKey, PSTR lpSubKey, uint32 Reserved, PSTR lpClass, REG_OPEN_CREATE_OPTIONS dwOptions, REG_SAM_FLAGS samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, REG_CREATE_KEY_DISPOSITION* lpdwDisposition, HANDLE hTransaction, void* pExtendedParemeter);
	public static WIN32_ERROR RegCreateKeyTransacted(HKEY hKey, PSTR lpSubKey, uint32 Reserved, PSTR lpClass, REG_OPEN_CREATE_OPTIONS dwOptions, REG_SAM_FLAGS samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, REG_CREATE_KEY_DISPOSITION* lpdwDisposition, HANDLE hTransaction, void* pExtendedParemeter) => RegCreateKeyTransactedA(hKey, lpSubKey, Reserved, lpClass, dwOptions, samDesired, lpSecurityAttributes, phkResult, lpdwDisposition, hTransaction, pExtendedParemeter);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCreateKeyTransactedW(HKEY hKey, PWSTR lpSubKey, uint32 Reserved, PWSTR lpClass, REG_OPEN_CREATE_OPTIONS dwOptions, REG_SAM_FLAGS samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, REG_CREATE_KEY_DISPOSITION* lpdwDisposition, HANDLE hTransaction, void* pExtendedParemeter);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyA(HKEY hKey, PSTR lpSubKey);
	public static WIN32_ERROR RegDeleteKey(HKEY hKey, PSTR lpSubKey) => RegDeleteKeyA(hKey, lpSubKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyW(HKEY hKey, PWSTR lpSubKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyExA(HKEY hKey, PSTR lpSubKey, uint32 samDesired, uint32 Reserved);
	public static WIN32_ERROR RegDeleteKeyEx(HKEY hKey, PSTR lpSubKey, uint32 samDesired, uint32 Reserved) => RegDeleteKeyExA(hKey, lpSubKey, samDesired, Reserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyExW(HKEY hKey, PWSTR lpSubKey, uint32 samDesired, uint32 Reserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyTransactedA(HKEY hKey, PSTR lpSubKey, uint32 samDesired, uint32 Reserved, HANDLE hTransaction, void* pExtendedParameter);
	public static WIN32_ERROR RegDeleteKeyTransacted(HKEY hKey, PSTR lpSubKey, uint32 samDesired, uint32 Reserved, HANDLE hTransaction, void* pExtendedParameter) => RegDeleteKeyTransactedA(hKey, lpSubKey, samDesired, Reserved, hTransaction, pExtendedParameter);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyTransactedW(HKEY hKey, PWSTR lpSubKey, uint32 samDesired, uint32 Reserved, HANDLE hTransaction, void* pExtendedParameter);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDisableReflectionKey(HKEY hBase);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnableReflectionKey(HKEY hBase);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryReflectionKey(HKEY hBase, BOOL* bIsReflectionDisabled);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteValueA(HKEY hKey, PSTR lpValueName);
	public static WIN32_ERROR RegDeleteValue(HKEY hKey, PSTR lpValueName) => RegDeleteValueA(hKey, lpValueName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteValueW(HKEY hKey, PWSTR lpValueName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnumKeyA(HKEY hKey, uint32 dwIndex, uint8* lpName, uint32 cchName);
	public static WIN32_ERROR RegEnumKey(HKEY hKey, uint32 dwIndex, uint8* lpName, uint32 cchName) => RegEnumKeyA(hKey, dwIndex, lpName, cchName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnumKeyW(HKEY hKey, uint32 dwIndex, char16* lpName, uint32 cchName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnumKeyExA(HKEY hKey, uint32 dwIndex, uint8* lpName, uint32* lpcchName, uint32* lpReserved, uint8* lpClass, uint32* lpcchClass, FILETIME* lpftLastWriteTime);
	public static WIN32_ERROR RegEnumKeyEx(HKEY hKey, uint32 dwIndex, uint8* lpName, uint32* lpcchName, uint32* lpReserved, uint8* lpClass, uint32* lpcchClass, FILETIME* lpftLastWriteTime) => RegEnumKeyExA(hKey, dwIndex, lpName, lpcchName, lpReserved, lpClass, lpcchClass, lpftLastWriteTime);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnumKeyExW(HKEY hKey, uint32 dwIndex, char16* lpName, uint32* lpcchName, uint32* lpReserved, char16* lpClass, uint32* lpcchClass, FILETIME* lpftLastWriteTime);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnumValueA(HKEY hKey, uint32 dwIndex, uint8* lpValueName, uint32* lpcchValueName, uint32* lpReserved, uint32* lpType, uint8* lpData, uint32* lpcbData);
	public static WIN32_ERROR RegEnumValue(HKEY hKey, uint32 dwIndex, uint8* lpValueName, uint32* lpcchValueName, uint32* lpReserved, uint32* lpType, uint8* lpData, uint32* lpcbData) => RegEnumValueA(hKey, dwIndex, lpValueName, lpcchValueName, lpReserved, lpType, lpData, lpcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegEnumValueW(HKEY hKey, uint32 dwIndex, char16* lpValueName, uint32* lpcchValueName, uint32* lpReserved, uint32* lpType, uint8* lpData, uint32* lpcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegFlushKey(HKEY hKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegGetKeySecurity(HKEY hKey, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32* lpcbSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegLoadKeyA(HKEY hKey, PSTR lpSubKey, PSTR lpFile);
	public static WIN32_ERROR RegLoadKey(HKEY hKey, PSTR lpSubKey, PSTR lpFile) => RegLoadKeyA(hKey, lpSubKey, lpFile);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegLoadKeyW(HKEY hKey, PWSTR lpSubKey, PWSTR lpFile);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegNotifyChangeKeyValue(HKEY hKey, BOOL bWatchSubtree, REG_NOTIFY_FILTER dwNotifyFilter, HANDLE hEvent, BOOL fAsynchronous);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenKeyA(HKEY hKey, PSTR lpSubKey, HKEY* phkResult);
	public static WIN32_ERROR RegOpenKey(HKEY hKey, PSTR lpSubKey, HKEY* phkResult) => RegOpenKeyA(hKey, lpSubKey, phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenKeyW(HKEY hKey, PWSTR lpSubKey, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenKeyExA(HKEY hKey, PSTR lpSubKey, uint32 ulOptions, REG_SAM_FLAGS samDesired, HKEY* phkResult);
	public static WIN32_ERROR RegOpenKeyEx(HKEY hKey, PSTR lpSubKey, uint32 ulOptions, REG_SAM_FLAGS samDesired, HKEY* phkResult) => RegOpenKeyExA(hKey, lpSubKey, ulOptions, samDesired, phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenKeyExW(HKEY hKey, PWSTR lpSubKey, uint32 ulOptions, REG_SAM_FLAGS samDesired, HKEY* phkResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenKeyTransactedA(HKEY hKey, PSTR lpSubKey, uint32 ulOptions, REG_SAM_FLAGS samDesired, HKEY* phkResult, HANDLE hTransaction, void* pExtendedParemeter);
	public static WIN32_ERROR RegOpenKeyTransacted(HKEY hKey, PSTR lpSubKey, uint32 ulOptions, REG_SAM_FLAGS samDesired, HKEY* phkResult, HANDLE hTransaction, void* pExtendedParemeter) => RegOpenKeyTransactedA(hKey, lpSubKey, ulOptions, samDesired, phkResult, hTransaction, pExtendedParemeter);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegOpenKeyTransactedW(HKEY hKey, PWSTR lpSubKey, uint32 ulOptions, REG_SAM_FLAGS samDesired, HKEY* phkResult, HANDLE hTransaction, void* pExtendedParemeter);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryInfoKeyA(HKEY hKey, uint8* lpClass, uint32* lpcchClass, uint32* lpReserved, uint32* lpcSubKeys, uint32* lpcbMaxSubKeyLen, uint32* lpcbMaxClassLen, uint32* lpcValues, uint32* lpcbMaxValueNameLen, uint32* lpcbMaxValueLen, uint32* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);
	public static WIN32_ERROR RegQueryInfoKey(HKEY hKey, uint8* lpClass, uint32* lpcchClass, uint32* lpReserved, uint32* lpcSubKeys, uint32* lpcbMaxSubKeyLen, uint32* lpcbMaxClassLen, uint32* lpcValues, uint32* lpcbMaxValueNameLen, uint32* lpcbMaxValueLen, uint32* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime) => RegQueryInfoKeyA(hKey, lpClass, lpcchClass, lpReserved, lpcSubKeys, lpcbMaxSubKeyLen, lpcbMaxClassLen, lpcValues, lpcbMaxValueNameLen, lpcbMaxValueLen, lpcbSecurityDescriptor, lpftLastWriteTime);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryInfoKeyW(HKEY hKey, char16* lpClass, uint32* lpcchClass, uint32* lpReserved, uint32* lpcSubKeys, uint32* lpcbMaxSubKeyLen, uint32* lpcbMaxClassLen, uint32* lpcValues, uint32* lpcbMaxValueNameLen, uint32* lpcbMaxValueLen, uint32* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryValueA(HKEY hKey, PSTR lpSubKey, PSTR lpData, int32* lpcbData);
	public static WIN32_ERROR RegQueryValue(HKEY hKey, PSTR lpSubKey, PSTR lpData, int32* lpcbData) => RegQueryValueA(hKey, lpSubKey, lpData, lpcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryValueW(HKEY hKey, PWSTR lpSubKey, PWSTR lpData, int32* lpcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryMultipleValuesA(HKEY hKey, VALENTA* val_list, uint32 num_vals, PSTR lpValueBuf, uint32* ldwTotsize);
	public static WIN32_ERROR RegQueryMultipleValues(HKEY hKey, VALENTA* val_list, uint32 num_vals, PSTR lpValueBuf, uint32* ldwTotsize) => RegQueryMultipleValuesA(hKey, val_list, num_vals, lpValueBuf, ldwTotsize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryMultipleValuesW(HKEY hKey, VALENTW* val_list, uint32 num_vals, PWSTR lpValueBuf, uint32* ldwTotsize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryValueExA(HKEY hKey, PSTR lpValueName, uint32* lpReserved, REG_VALUE_TYPE* lpType, uint8* lpData, uint32* lpcbData);
	public static WIN32_ERROR RegQueryValueEx(HKEY hKey, PSTR lpValueName, uint32* lpReserved, REG_VALUE_TYPE* lpType, uint8* lpData, uint32* lpcbData) => RegQueryValueExA(hKey, lpValueName, lpReserved, lpType, lpData, lpcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegQueryValueExW(HKEY hKey, PWSTR lpValueName, uint32* lpReserved, REG_VALUE_TYPE* lpType, uint8* lpData, uint32* lpcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegReplaceKeyA(HKEY hKey, PSTR lpSubKey, PSTR lpNewFile, PSTR lpOldFile);
	public static WIN32_ERROR RegReplaceKey(HKEY hKey, PSTR lpSubKey, PSTR lpNewFile, PSTR lpOldFile) => RegReplaceKeyA(hKey, lpSubKey, lpNewFile, lpOldFile);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegReplaceKeyW(HKEY hKey, PWSTR lpSubKey, PWSTR lpNewFile, PWSTR lpOldFile);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegRestoreKeyA(HKEY hKey, PSTR lpFile, REG_RESTORE_KEY_FLAGS dwFlags);
	public static WIN32_ERROR RegRestoreKey(HKEY hKey, PSTR lpFile, REG_RESTORE_KEY_FLAGS dwFlags) => RegRestoreKeyA(hKey, lpFile, dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegRestoreKeyW(HKEY hKey, PWSTR lpFile, REG_RESTORE_KEY_FLAGS dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegRenameKey(HKEY hKey, PWSTR lpSubKeyName, PWSTR lpNewKeyName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSaveKeyA(HKEY hKey, PSTR lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes);
	public static WIN32_ERROR RegSaveKey(HKEY hKey, PSTR lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes) => RegSaveKeyA(hKey, lpFile, lpSecurityAttributes);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSaveKeyW(HKEY hKey, PWSTR lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetKeySecurity(HKEY hKey, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetValueA(HKEY hKey, PSTR lpSubKey, REG_VALUE_TYPE dwType, PSTR lpData, uint32 cbData);
	public static WIN32_ERROR RegSetValue(HKEY hKey, PSTR lpSubKey, REG_VALUE_TYPE dwType, PSTR lpData, uint32 cbData) => RegSetValueA(hKey, lpSubKey, dwType, lpData, cbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetValueW(HKEY hKey, PWSTR lpSubKey, REG_VALUE_TYPE dwType, PWSTR lpData, uint32 cbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetValueExA(HKEY hKey, PSTR lpValueName, uint32 Reserved, REG_VALUE_TYPE dwType, uint8* lpData, uint32 cbData);
	public static WIN32_ERROR RegSetValueEx(HKEY hKey, PSTR lpValueName, uint32 Reserved, REG_VALUE_TYPE dwType, uint8* lpData, uint32 cbData) => RegSetValueExA(hKey, lpValueName, Reserved, dwType, lpData, cbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetValueExW(HKEY hKey, PWSTR lpValueName, uint32 Reserved, REG_VALUE_TYPE dwType, uint8* lpData, uint32 cbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegUnLoadKeyA(HKEY hKey, PSTR lpSubKey);
	public static WIN32_ERROR RegUnLoadKey(HKEY hKey, PSTR lpSubKey) => RegUnLoadKeyA(hKey, lpSubKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegUnLoadKeyW(HKEY hKey, PWSTR lpSubKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyValueA(HKEY hKey, PSTR lpSubKey, PSTR lpValueName);
	public static WIN32_ERROR RegDeleteKeyValue(HKEY hKey, PSTR lpSubKey, PSTR lpValueName) => RegDeleteKeyValueA(hKey, lpSubKey, lpValueName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteKeyValueW(HKEY hKey, PWSTR lpSubKey, PWSTR lpValueName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetKeyValueA(HKEY hKey, PSTR lpSubKey, PSTR lpValueName, uint32 dwType, void* lpData, uint32 cbData);
	public static WIN32_ERROR RegSetKeyValue(HKEY hKey, PSTR lpSubKey, PSTR lpValueName, uint32 dwType, void* lpData, uint32 cbData) => RegSetKeyValueA(hKey, lpSubKey, lpValueName, dwType, lpData, cbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSetKeyValueW(HKEY hKey, PWSTR lpSubKey, PWSTR lpValueName, uint32 dwType, void* lpData, uint32 cbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteTreeA(HKEY hKey, PSTR lpSubKey);
	public static WIN32_ERROR RegDeleteTree(HKEY hKey, PSTR lpSubKey) => RegDeleteTreeA(hKey, lpSubKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegDeleteTreeW(HKEY hKey, PWSTR lpSubKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCopyTreeA(HKEY hKeySrc, PSTR lpSubKey, HKEY hKeyDest);
	public static WIN32_ERROR RegCopyTree(HKEY hKeySrc, PSTR lpSubKey, HKEY hKeyDest) => RegCopyTreeA(hKeySrc, lpSubKey, hKeyDest);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegGetValueA(HKEY hkey, PSTR lpSubKey, PSTR lpValue, RRF_RT dwFlags, uint32* pdwType, void* pvData, uint32* pcbData);
	public static WIN32_ERROR RegGetValue(HKEY hkey, PSTR lpSubKey, PSTR lpValue, RRF_RT dwFlags, uint32* pdwType, void* pvData, uint32* pcbData) => RegGetValueA(hkey, lpSubKey, lpValue, dwFlags, pdwType, pvData, pcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegGetValueW(HKEY hkey, PWSTR lpSubKey, PWSTR lpValue, RRF_RT dwFlags, uint32* pdwType, void* pvData, uint32* pcbData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegCopyTreeW(HKEY hKeySrc, PWSTR lpSubKey, HKEY hKeyDest);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegLoadMUIStringA(HKEY hKey, PSTR pszValue, PSTR pszOutBuf, uint32 cbOutBuf, uint32* pcbData, uint32 Flags, PSTR pszDirectory);
	public static WIN32_ERROR RegLoadMUIString(HKEY hKey, PSTR pszValue, PSTR pszOutBuf, uint32 cbOutBuf, uint32* pcbData, uint32 Flags, PSTR pszDirectory) => RegLoadMUIStringA(hKey, pszValue, pszOutBuf, cbOutBuf, pcbData, Flags, pszDirectory);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegLoadMUIStringW(HKEY hKey, PWSTR pszValue, PWSTR pszOutBuf, uint32 cbOutBuf, uint32* pcbData, uint32 Flags, PWSTR pszDirectory);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegLoadAppKeyA(PSTR lpFile, HKEY* phkResult, uint32 samDesired, uint32 dwOptions, uint32 Reserved);
	public static WIN32_ERROR RegLoadAppKey(PSTR lpFile, HKEY* phkResult, uint32 samDesired, uint32 dwOptions, uint32 Reserved) => RegLoadAppKeyA(lpFile, phkResult, samDesired, dwOptions, Reserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegLoadAppKeyW(PWSTR lpFile, HKEY* phkResult, uint32 samDesired, uint32 dwOptions, uint32 Reserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSaveKeyExA(HKEY hKey, PSTR lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes, REG_SAVE_FORMAT Flags);
	public static WIN32_ERROR RegSaveKeyEx(HKEY hKey, PSTR lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes, REG_SAVE_FORMAT Flags) => RegSaveKeyExA(hKey, lpFile, lpSecurityAttributes, Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RegSaveKeyExW(HKEY hKey, PWSTR lpFile, SECURITY_ATTRIBUTES* lpSecurityAttributes, REG_SAVE_FORMAT Flags);

	[Import("api-ms-win-core-state-helpers-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetRegistryValueWithFallbackW(HKEY hkeyPrimary, PWSTR pwszPrimarySubKey, HKEY hkeyFallback, PWSTR pwszFallbackSubKey, PWSTR pwszValue, uint32 dwFlags, uint32* pdwType, void* pvData, uint32 cbDataIn, uint32* pcbDataOut);

}
#endregion
