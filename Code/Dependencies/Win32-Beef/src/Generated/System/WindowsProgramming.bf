using Win32.Foundation;
using Win32.System.Kernel;
using Win32.System.Com;
using Win32.Security;
using Win32.Graphics.Gdi;
using Win32.System.Registry;
using System;

namespace Win32.System.WindowsProgramming;

#region Constants
public static
{
	public const String WLDP_DLL = "WLDP.DLL";
	public const String WLDP_GETLOCKDOWNPOLICY_FN = "WldpGetLockdownPolicy";
	public const String WLDP_ISCLASSINAPPROVEDLIST_FN = "WldpIsClassInApprovedList";
	public const String WLDP_SETDYNAMICCODETRUST_FN = "WldpSetDynamicCodeTrust";
	public const String WLDP_ISDYNAMICCODEPOLICYENABLED_FN = "WldpIsDynamicCodePolicyEnabled";
	public const String WLDP_QUERYDANAMICCODETRUST_FN = "WldpQueryDynamicCodeTrust";
	public const String WLDP_QUERYDYNAMICCODETRUST_FN = "WldpQueryDynamicCodeTrust";
	public const String WLDP_QUERYWINDOWSLOCKDOWNMODE_FN = "WldpQueryWindowsLockdownMode";
	public const String WLDP_SETWINDOWSLOCKDOWNRESTRICTION_FN = "WldpSetWindowsLockdownRestriction";
	public const String WLDP_QUERYDEVICESECURITYINFORMATION_FN = "WldpQueryDeviceSecurityInformation";
	public const String WLDP_QUERYWINDOWSLOCKDOWNRESTRICTION_FN = "WldpQueryWindowsLockdownRestriction";
	public const String WLDP_ISAPPAPPROVEDBYPOLICY_FN = "WldpIsAppApprovedByPolicy";
	public const String WLDP_QUERYPOLICYSETTINGENABLED_FN = "WldpQueryPolicySettingEnabled";
	public const String WLDP_QUERYPOLICYSETTINGENABLED2_FN = "WldpQueryPolicySettingEnabled2";
	public const String WLDP_ISWCOSPRODUCTIONCONFIGURATION_FN = "WldpIsWcosProductionConfiguration";
	public const String WLDP_RESETWCOSPRODUCTIONCONFIGURATION_FN = "WldpResetWcosProductionConfiguration";
	public const String WLDP_ISPRODUCTIONCONFIGURATION_FN = "WldpIsProductionConfiguration";
	public const String WLDP_RESETPRODUCTIONCONFIGURATION_FN = "WldpResetProductionConfiguration";
	public const uint32 WLDP_LOCKDOWN_UNDEFINED = 0;
	public const uint32 WLDP_LOCKDOWN_DEFINED_FLAG = 2147483648;
	public const uint32 WLDP_LOCKDOWN_CONFIG_CI_FLAG = 1;
	public const uint32 WLDP_LOCKDOWN_CONFIG_CI_AUDIT_FLAG = 2;
	public const uint32 WLDP_LOCKDOWN_UMCIENFORCE_FLAG = 4;
	public const uint32 WLDP_LOCKDOWN_AUDIT_FLAG = 8;
	public const uint32 WLDP_LOCKDOWN_EXCLUSION_FLAG = 16;
	public const uint32 WLDP_LOCKDOWN_OFF = 2147483648;
	public const uint32 WLDP_HOST_INFORMATION_REVISION = 1;
	public const uint32 WLDP_FLAGS_SKIPSIGNATUREVALIDATION = 256;
	public const uint32 MAX_TDI_ENTITIES = 4096;
	public const uint32 INFO_CLASS_GENERIC = 256;
	public const uint32 INFO_CLASS_PROTOCOL = 512;
	public const uint32 INFO_CLASS_IMPLEMENTATION = 768;
	public const uint32 INFO_TYPE_PROVIDER = 256;
	public const uint32 INFO_TYPE_ADDRESS_OBJECT = 512;
	public const uint32 INFO_TYPE_CONNECTION = 768;
	public const uint32 ENTITY_LIST_ID = 0;
	public const int32 INVALID_ENTITY_INSTANCE = -1;
	public const uint32 CONTEXT_SIZE = 16;
	public const uint32 ENTITY_TYPE_ID = 1;
	public const uint32 CO_TL_NBF = 1024;
	public const uint32 CO_TL_SPX = 1026;
	public const uint32 CO_TL_TCP = 1028;
	public const uint32 CO_TL_SPP = 1030;
	public const uint32 CL_TL_NBF = 1025;
	public const uint32 CL_TL_UDP = 1027;
	public const uint32 ER_ICMP = 896;
	public const uint32 CL_NL_IPX = 769;
	public const uint32 CL_NL_IP = 771;
	public const uint32 AT_ARP = 640;
	public const uint32 AT_NULL = 642;
	public const uint32 IF_GENERIC = 512;
	public const uint32 IF_MIB = 514;
	public const uint32 IOCTL_TDI_TL_IO_CONTROL_ENDPOINT = 2162744;
	public const uint32 DCI_VERSION = 256;
	public const uint32 DCICREATEPRIMARYSURFACE = 1;
	public const uint32 DCICREATEOFFSCREENSURFACE = 2;
	public const uint32 DCICREATEOVERLAYSURFACE = 3;
	public const uint32 DCIENUMSURFACE = 4;
	public const uint32 DCIESCAPE = 5;
	public const uint32 DCI_OK = 0;
	public const int32 DCI_FAIL_GENERIC = -1;
	public const int32 DCI_FAIL_UNSUPPORTEDVERSION = -2;
	public const int32 DCI_FAIL_INVALIDSURFACE = -3;
	public const int32 DCI_FAIL_UNSUPPORTED = -4;
	public const int32 DCI_ERR_CURRENTLYNOTAVAIL = -5;
	public const int32 DCI_ERR_INVALIDRECT = -6;
	public const int32 DCI_ERR_UNSUPPORTEDFORMAT = -7;
	public const int32 DCI_ERR_UNSUPPORTEDMASK = -8;
	public const int32 DCI_ERR_TOOBIGHEIGHT = -9;
	public const int32 DCI_ERR_TOOBIGWIDTH = -10;
	public const int32 DCI_ERR_TOOBIGSIZE = -11;
	public const int32 DCI_ERR_OUTOFMEMORY = -12;
	public const int32 DCI_ERR_INVALIDPOSITION = -13;
	public const int32 DCI_ERR_INVALIDSTRETCH = -14;
	public const int32 DCI_ERR_INVALIDCLIPLIST = -15;
	public const int32 DCI_ERR_SURFACEISOBSCURED = -16;
	public const int32 DCI_ERR_XALIGN = -17;
	public const int32 DCI_ERR_YALIGN = -18;
	public const int32 DCI_ERR_XYALIGN = -19;
	public const int32 DCI_ERR_WIDTHALIGN = -20;
	public const int32 DCI_ERR_HEIGHTALIGN = -21;
	public const uint32 DCI_STATUS_POINTERCHANGED = 1;
	public const uint32 DCI_STATUS_STRIDECHANGED = 2;
	public const uint32 DCI_STATUS_FORMATCHANGED = 4;
	public const uint32 DCI_STATUS_SURFACEINFOCHANGED = 8;
	public const uint32 DCI_STATUS_CHROMAKEYCHANGED = 16;
	public const uint32 DCI_STATUS_WASSTILLDRAWING = 32;
	public const uint32 DCI_SURFACE_TYPE = 15;
	public const uint32 DCI_PRIMARY = 0;
	public const uint32 DCI_OFFSCREEN = 1;
	public const uint32 DCI_OVERLAY = 2;
	public const uint32 DCI_VISIBLE = 16;
	public const uint32 DCI_CHROMAKEY = 32;
	public const uint32 DCI_1632_ACCESS = 64;
	public const uint32 DCI_DWORDSIZE = 128;
	public const uint32 DCI_DWORDALIGN = 256;
	public const uint32 DCI_WRITEONLY = 512;
	public const uint32 DCI_ASYNC = 1024;
	public const uint32 DCI_CAN_STRETCHX = 4096;
	public const uint32 DCI_CAN_STRETCHY = 8192;
	public const uint32 DCI_CAN_STRETCHXN = 16384;
	public const uint32 DCI_CAN_STRETCHYN = 32768;
	public const uint32 DCI_CANOVERLAY = 65536;
	public const uint32 FILE_FLAG_OPEN_REQUIRING_OPLOCK = 262144;
	public const uint32 PROGRESS_CONTINUE = 0;
	public const uint32 PROGRESS_CANCEL = 1;
	public const uint32 PROGRESS_STOP = 2;
	public const uint32 PROGRESS_QUIET = 3;
	public const uint32 COPY_FILE_FAIL_IF_EXISTS = 1;
	public const uint32 COPY_FILE_RESTARTABLE = 2;
	public const uint32 COPY_FILE_OPEN_SOURCE_FOR_WRITE = 4;
	public const uint32 COPY_FILE_ALLOW_DECRYPTED_DESTINATION = 8;
	public const uint32 COPY_FILE_COPY_SYMLINK = 2048;
	public const uint32 COPY_FILE_NO_BUFFERING = 4096;
	public const uint32 COPY_FILE_REQUEST_SECURITY_PRIVILEGES = 8192;
	public const uint32 COPY_FILE_RESUME_FROM_PAUSE = 16384;
	public const uint32 COPY_FILE_NO_OFFLOAD = 262144;
	public const uint32 COPY_FILE_IGNORE_EDP_BLOCK = 4194304;
	public const uint32 COPY_FILE_IGNORE_SOURCE_ENCRYPTION = 8388608;
	public const uint32 COPY_FILE_DONT_REQUEST_DEST_WRITE_DAC = 33554432;
	public const uint32 COPY_FILE_REQUEST_COMPRESSED_TRAFFIC = 268435456;
	public const uint32 COPY_FILE_OPEN_AND_COPY_REPARSE_POINT = 2097152;
	public const uint32 COPY_FILE_DIRECTORY = 128;
	public const uint32 COPY_FILE_SKIP_ALTERNATE_STREAMS = 32768;
	public const uint32 COPY_FILE_DISABLE_PRE_ALLOCATION = 67108864;
	public const uint32 COPY_FILE_ENABLE_LOW_FREE_SPACE_MODE = 134217728;
	public const uint32 FAIL_FAST_GENERATE_EXCEPTION_ADDRESS = 1;
	public const uint32 FAIL_FAST_NO_HARD_ERROR_DLG = 2;
	public const uint32 DTR_CONTROL_DISABLE = 0;
	public const uint32 DTR_CONTROL_ENABLE = 1;
	public const uint32 DTR_CONTROL_HANDSHAKE = 2;
	public const uint32 RTS_CONTROL_DISABLE = 0;
	public const uint32 RTS_CONTROL_ENABLE = 1;
	public const uint32 RTS_CONTROL_HANDSHAKE = 2;
	public const uint32 RTS_CONTROL_TOGGLE = 3;
	public const uint32 GMEM_NOCOMPACT = 16;
	public const uint32 GMEM_NODISCARD = 32;
	public const uint32 GMEM_MODIFY = 128;
	public const uint32 GMEM_DISCARDABLE = 256;
	public const uint32 GMEM_NOT_BANKED = 4096;
	public const uint32 GMEM_SHARE = 8192;
	public const uint32 GMEM_DDESHARE = 8192;
	public const uint32 GMEM_NOTIFY = 16384;
	public const uint32 GMEM_LOWER = 4096;
	public const uint32 GMEM_VALID_FLAGS = 32626;
	public const uint32 GMEM_INVALID_HANDLE = 32768;
	public const uint32 GMEM_DISCARDED = 16384;
	public const uint32 GMEM_LOCKCOUNT = 255;
	public const uint32 THREAD_PRIORITY_ERROR_RETURN = 2147483647;
	public const uint32 VOLUME_NAME_DOS = 0;
	public const uint32 VOLUME_NAME_GUID = 1;
	public const uint32 VOLUME_NAME_NT = 2;
	public const uint32 VOLUME_NAME_NONE = 4;
	public const uint32 DRIVE_UNKNOWN = 0;
	public const uint32 DRIVE_NO_ROOT_DIR = 1;
	public const uint32 DRIVE_REMOVABLE = 2;
	public const uint32 DRIVE_FIXED = 3;
	public const uint32 DRIVE_REMOTE = 4;
	public const uint32 DRIVE_CDROM = 5;
	public const uint32 DRIVE_RAMDISK = 6;
	public const uint32 FILE_TYPE_UNKNOWN = 0;
	public const uint32 FILE_TYPE_DISK = 1;
	public const uint32 FILE_TYPE_CHAR = 2;
	public const uint32 FILE_TYPE_PIPE = 3;
	public const uint32 FILE_TYPE_REMOTE = 32768;
	public const uint32 IGNORE = 0;
	public const uint32 INFINITE = 4294967295;
	public const uint32 CBR_110 = 110;
	public const uint32 CBR_300 = 300;
	public const uint32 CBR_600 = 600;
	public const uint32 CBR_1200 = 1200;
	public const uint32 CBR_2400 = 2400;
	public const uint32 CBR_4800 = 4800;
	public const uint32 CBR_9600 = 9600;
	public const uint32 CBR_14400 = 14400;
	public const uint32 CBR_19200 = 19200;
	public const uint32 CBR_38400 = 38400;
	public const uint32 CBR_56000 = 56000;
	public const uint32 CBR_57600 = 57600;
	public const uint32 CBR_115200 = 115200;
	public const uint32 CBR_128000 = 128000;
	public const uint32 CBR_256000 = 256000;
	public const uint32 CE_TXFULL = 256;
	public const uint32 CE_PTO = 512;
	public const uint32 CE_IOE = 1024;
	public const uint32 CE_DNS = 2048;
	public const uint32 CE_OOP = 4096;
	public const uint32 CE_MODE = 32768;
	public const int32 IE_BADID = -1;
	public const int32 IE_OPEN = -2;
	public const int32 IE_NOPEN = -3;
	public const int32 IE_MEMORY = -4;
	public const int32 IE_DEFAULT = -5;
	public const int32 IE_HARDWARE = -10;
	public const int32 IE_BYTESIZE = -11;
	public const int32 IE_BAUDRATE = -12;
	public const uint32 RESETDEV = 7;
	public const uint32 LPTx = 128;
	public const uint32 S_QUEUEEMPTY = 0;
	public const uint32 S_THRESHOLD = 1;
	public const uint32 S_ALLTHRESHOLD = 2;
	public const uint32 S_NORMAL = 0;
	public const uint32 S_LEGATO = 1;
	public const uint32 S_STACCATO = 2;
	public const uint32 S_PERIOD512 = 0;
	public const uint32 S_PERIOD1024 = 1;
	public const uint32 S_PERIOD2048 = 2;
	public const uint32 S_PERIODVOICE = 3;
	public const uint32 S_WHITE512 = 4;
	public const uint32 S_WHITE1024 = 5;
	public const uint32 S_WHITE2048 = 6;
	public const uint32 S_WHITEVOICE = 7;
	public const int32 S_SERDVNA = -1;
	public const int32 S_SEROFM = -2;
	public const int32 S_SERMACT = -3;
	public const int32 S_SERQFUL = -4;
	public const int32 S_SERBDNT = -5;
	public const int32 S_SERDLN = -6;
	public const int32 S_SERDCC = -7;
	public const int32 S_SERDTP = -8;
	public const int32 S_SERDVL = -9;
	public const int32 S_SERDMD = -10;
	public const int32 S_SERDSH = -11;
	public const int32 S_SERDPT = -12;
	public const int32 S_SERDFQ = -13;
	public const int32 S_SERDDR = -14;
	public const int32 S_SERDSR = -15;
	public const int32 S_SERDST = -16;
	public const uint32 FS_CASE_IS_PRESERVED = 2;
	public const uint32 FS_CASE_SENSITIVE = 1;
	public const uint32 FS_UNICODE_STORED_ON_DISK = 4;
	public const uint32 FS_PERSISTENT_ACLS = 8;
	public const uint32 FS_VOL_IS_COMPRESSED = 32768;
	public const uint32 FS_FILE_COMPRESSION = 16;
	public const uint32 FS_FILE_ENCRYPTION = 131072;
	public const uint32 OFS_MAXPATHNAME = 128;
	public const uint32 MAXINTATOM = 49152;
	public const uint32 SCS_32BIT_BINARY = 0;
	public const uint32 SCS_DOS_BINARY = 1;
	public const uint32 SCS_WOW_BINARY = 2;
	public const uint32 SCS_PIF_BINARY = 3;
	public const uint32 SCS_POSIX_BINARY = 4;
	public const uint32 SCS_OS216_BINARY = 5;
	public const uint32 SCS_64BIT_BINARY = 6;
	public const uint32 SCS_THIS_PLATFORM_BINARY = 6;
	public const uint32 FIBER_FLAG_FLOAT_SWITCH = 1;
	public const uint32 UMS_VERSION = 256;
	public const uint32 FILE_SKIP_COMPLETION_PORT_ON_SUCCESS = 1;
	public const uint32 FILE_SKIP_SET_EVENT_ON_HANDLE = 2;
	public const uint32 CRITICAL_SECTION_NO_DEBUG_INFO = 16777216;
	public const uint32 HINSTANCE_ERROR = 32;
	public const uint32 FORMAT_MESSAGE_MAX_WIDTH_MASK = 255;
	public const uint32 FILE_ENCRYPTABLE = 0;
	public const uint32 FILE_IS_ENCRYPTED = 1;
	public const uint32 FILE_SYSTEM_ATTR = 2;
	public const uint32 FILE_ROOT_DIR = 3;
	public const uint32 FILE_SYSTEM_DIR = 4;
	public const uint32 FILE_UNKNOWN = 5;
	public const uint32 FILE_SYSTEM_NOT_SUPPORT = 6;
	public const uint32 FILE_USER_DISALLOWED = 7;
	public const uint32 FILE_READ_ONLY = 8;
	public const uint32 FILE_DIR_DISALLOWED = 9;
	public const uint32 EFS_USE_RECOVERY_KEYS = 1;
	public const uint32 CREATE_FOR_IMPORT = 1;
	public const uint32 CREATE_FOR_DIR = 2;
	public const uint32 OVERWRITE_HIDDEN = 4;
	public const uint32 EFSRPC_SECURE_ONLY = 8;
	public const uint32 EFS_DROP_ALTERNATE_STREAMS = 16;
	public const uint32 BACKUP_INVALID = 0;
	public const uint32 BACKUP_GHOSTED_FILE_EXTENTS = 11;
	public const uint32 STREAM_NORMAL_ATTRIBUTE = 0;
	public const uint32 STREAM_MODIFIED_WHEN_READ = 1;
	public const uint32 STREAM_CONTAINS_SECURITY = 2;
	public const uint32 STREAM_CONTAINS_PROPERTIES = 4;
	public const uint32 STREAM_SPARSE_ATTRIBUTE = 8;
	public const uint32 STREAM_CONTAINS_GHOSTED_FILE_EXTENTS = 16;
	public const uint32 STARTF_HOLOGRAPHIC = 262144;
	public const uint32 SHUTDOWN_NORETRY = 1;
	public const uint32 PROTECTION_LEVEL_SAME = 4294967295;
	public const uint32 PROC_THREAD_ATTRIBUTE_NUMBER = 65535;
	public const uint32 PROC_THREAD_ATTRIBUTE_THREAD = 65536;
	public const uint32 PROC_THREAD_ATTRIBUTE_INPUT = 131072;
	public const uint32 PROC_THREAD_ATTRIBUTE_ADDITIVE = 262144;
	public const uint32 PROCESS_CREATION_MITIGATION_POLICY_DEP_ENABLE = 1;
	public const uint32 PROCESS_CREATION_MITIGATION_POLICY_DEP_ATL_THUNK_ENABLE = 2;
	public const uint32 PROCESS_CREATION_MITIGATION_POLICY_SEHOP_ENABLE = 4;
	public const uint32 PROCESS_CREATION_CHILD_PROCESS_RESTRICTED = 1;
	public const uint32 PROCESS_CREATION_CHILD_PROCESS_OVERRIDE = 2;
	public const uint32 PROCESS_CREATION_CHILD_PROCESS_RESTRICTED_UNLESS_SECURE = 4;
	public const uint32 PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT = 1;
	public const uint32 PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_ENABLE_PROCESS_TREE = 1;
	public const uint32 PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_DISABLE_PROCESS_TREE = 2;
	public const uint32 PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_OVERRIDE = 4;
	public const uint32 ATOM_FLAG_GLOBAL = 2;
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_A_A = "GetSystemWow64DirectoryA";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_A_W = "GetSystemWow64DirectoryA";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_A_T = "GetSystemWow64DirectoryA";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_W_A = "GetSystemWow64DirectoryW";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_W_W = "GetSystemWow64DirectoryW";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_W_T = "GetSystemWow64DirectoryW";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_T_A = "GetSystemWow64DirectoryW";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_T_W = "GetSystemWow64DirectoryW";
	public const String GET_SYSTEM_WOW64_DIRECTORY_NAME_T_T = "GetSystemWow64DirectoryW";
	public const uint32 BASE_SEARCH_PATH_ENABLE_SAFE_SEARCHMODE = 1;
	public const uint32 BASE_SEARCH_PATH_DISABLE_SAFE_SEARCHMODE = 65536;
	public const uint32 BASE_SEARCH_PATH_PERMANENT = 32768;
	public const int32 COPYFILE2_MESSAGE_COPY_OFFLOAD = 1;
	public const uint32 COPYFILE2_IO_CYCLE_SIZE_MIN = 4096;
	public const uint32 COPYFILE2_IO_CYCLE_SIZE_MAX = 1073741824;
	public const uint32 COPYFILE2_IO_RATE_MIN = 512;
	public const uint32 EVENTLOG_FULL_INFO = 0;
	public const uint32 OPERATION_API_VERSION = 1;
	public const uint32 MAX_COMPUTERNAME_LENGTH = 15;
	public const uint32 LOGON32_PROVIDER_WINNT35 = 1;
	public const uint32 LOGON32_PROVIDER_VIRTUAL = 4;
	public const uint32 LOGON_ZERO_PASSWORD_BUFFER = 2147483648;
	public const uint32 HW_PROFILE_GUIDLEN = 39;
	public const uint32 DOCKINFO_UNDOCKED = 1;
	public const uint32 DOCKINFO_DOCKED = 2;
	public const uint32 DOCKINFO_USER_SUPPLIED = 4;
	public const uint32 TC_NORMAL = 0;
	public const uint32 TC_HARDERR = 1;
	public const uint32 TC_GP_TRAP = 2;
	public const uint32 TC_SIGNAL = 3;
	public const uint32 AC_LINE_OFFLINE = 0;
	public const uint32 AC_LINE_ONLINE = 1;
	public const uint32 AC_LINE_BACKUP_POWER = 2;
	public const uint32 AC_LINE_UNKNOWN = 255;
	public const uint32 BATTERY_FLAG_HIGH = 1;
	public const uint32 BATTERY_FLAG_LOW = 2;
	public const uint32 BATTERY_FLAG_CRITICAL = 4;
	public const uint32 BATTERY_FLAG_CHARGING = 8;
	public const uint32 BATTERY_FLAG_NO_BATTERY = 128;
	public const uint32 BATTERY_FLAG_UNKNOWN = 255;
	public const uint32 BATTERY_PERCENTAGE_UNKNOWN = 255;
	public const uint32 SYSTEM_STATUS_FLAG_POWER_SAVING_ON = 1;
	public const uint32 BATTERY_LIFE_UNKNOWN = 4294967295;
	public const uint32 ACTCTX_FLAG_PROCESSOR_ARCHITECTURE_VALID = 1;
	public const uint32 ACTCTX_FLAG_LANGID_VALID = 2;
	public const uint32 ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID = 4;
	public const uint32 ACTCTX_FLAG_RESOURCE_NAME_VALID = 8;
	public const uint32 ACTCTX_FLAG_SET_PROCESS_DEFAULT = 16;
	public const uint32 ACTCTX_FLAG_APPLICATION_NAME_VALID = 32;
	public const uint32 ACTCTX_FLAG_SOURCE_IS_ASSEMBLYREF = 64;
	public const uint32 ACTCTX_FLAG_HMODULE_VALID = 128;
	public const uint32 DEACTIVATE_ACTCTX_FLAG_FORCE_EARLY_DEACTIVATION = 1;
	public const uint32 FIND_ACTCTX_SECTION_KEY_RETURN_HACTCTX = 1;
	public const uint32 FIND_ACTCTX_SECTION_KEY_RETURN_FLAGS = 2;
	public const uint32 FIND_ACTCTX_SECTION_KEY_RETURN_ASSEMBLY_METADATA = 4;
	public const uint32 ACTIVATION_CONTEXT_BASIC_INFORMATION_DEFINED = 1;
	public const uint32 QUERY_ACTCTX_FLAG_USE_ACTIVE_ACTCTX = 4;
	public const uint32 QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE = 8;
	public const uint32 QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS = 16;
	public const uint32 QUERY_ACTCTX_FLAG_NO_ADDREF = 2147483648;
	public const uint32 RESTART_MAX_CMD_LINE = 1024;
	public const uint32 RECOVERY_DEFAULT_PING_INTERVAL = 5000;
	public const uint32 FILE_RENAME_FLAG_REPLACE_IF_EXISTS = 1;
	public const uint32 FILE_RENAME_FLAG_POSIX_SEMANTICS = 2;
	public const uint32 FILE_RENAME_FLAG_SUPPRESS_PIN_STATE_INHERITANCE = 4;
	public const uint32 FILE_DISPOSITION_FLAG_DO_NOT_DELETE = 0;
	public const uint32 FILE_DISPOSITION_FLAG_DELETE = 1;
	public const uint32 FILE_DISPOSITION_FLAG_POSIX_SEMANTICS = 2;
	public const uint32 FILE_DISPOSITION_FLAG_FORCE_IMAGE_SECTION_CHECK = 4;
	public const uint32 FILE_DISPOSITION_FLAG_ON_CLOSE = 8;
	public const uint32 FILE_DISPOSITION_FLAG_IGNORE_READONLY_ATTRIBUTE = 16;
	public const uint32 STORAGE_INFO_FLAGS_ALIGNED_DEVICE = 1;
	public const uint32 STORAGE_INFO_FLAGS_PARTITION_ALIGNED_ON_DEVICE = 2;
	public const uint32 STORAGE_INFO_OFFSET_UNKNOWN = 4294967295;
	public const uint32 REMOTE_PROTOCOL_INFO_FLAG_LOOPBACK = 1;
	public const uint32 REMOTE_PROTOCOL_INFO_FLAG_OFFLINE = 2;
	public const uint32 REMOTE_PROTOCOL_INFO_FLAG_PERSISTENT_HANDLE = 4;
	public const uint32 RPI_FLAG_SMB2_SHARECAP_TIMEWARP = 2;
	public const uint32 RPI_FLAG_SMB2_SHARECAP_DFS = 8;
	public const uint32 RPI_FLAG_SMB2_SHARECAP_CONTINUOUS_AVAILABILITY = 16;
	public const uint32 RPI_FLAG_SMB2_SHARECAP_SCALEOUT = 32;
	public const uint32 RPI_FLAG_SMB2_SHARECAP_CLUSTER = 64;
	public const uint32 RPI_SMB2_FLAG_SERVERCAP_DFS = 1;
	public const uint32 RPI_SMB2_FLAG_SERVERCAP_LEASING = 2;
	public const uint32 RPI_SMB2_FLAG_SERVERCAP_LARGEMTU = 4;
	public const uint32 RPI_SMB2_FLAG_SERVERCAP_MULTICHANNEL = 8;
	public const uint32 RPI_SMB2_FLAG_SERVERCAP_PERSISTENT_HANDLES = 16;
	public const uint32 RPI_SMB2_FLAG_SERVERCAP_DIRECTORY_LEASING = 32;
	public const uint32 MICROSOFT_WINDOWS_WINBASE_H_DEFINE_INTERLOCKED_CPLUSPLUS_OVERLOADS = 0;
	public const uint32 MICROSOFT_WINBASE_H_DEFINE_INTERLOCKED_CPLUSPLUS_OVERLOADS = 0;
	public const uint32 CODEINTEGRITY_OPTION_ENABLED = 1;
	public const uint32 CODEINTEGRITY_OPTION_TESTSIGN = 2;
	public const uint32 CODEINTEGRITY_OPTION_UMCI_ENABLED = 4;
	public const uint32 CODEINTEGRITY_OPTION_UMCI_AUDITMODE_ENABLED = 8;
	public const uint32 CODEINTEGRITY_OPTION_UMCI_EXCLUSIONPATHS_ENABLED = 16;
	public const uint32 CODEINTEGRITY_OPTION_TEST_BUILD = 32;
	public const uint32 CODEINTEGRITY_OPTION_PREPRODUCTION_BUILD = 64;
	public const uint32 CODEINTEGRITY_OPTION_DEBUGMODE_ENABLED = 128;
	public const uint32 CODEINTEGRITY_OPTION_FLIGHT_BUILD = 256;
	public const uint32 CODEINTEGRITY_OPTION_FLIGHTING_ENABLED = 512;
	public const uint32 CODEINTEGRITY_OPTION_HVCI_KMCI_ENABLED = 1024;
	public const uint32 CODEINTEGRITY_OPTION_HVCI_KMCI_AUDITMODE_ENABLED = 2048;
	public const uint32 CODEINTEGRITY_OPTION_HVCI_KMCI_STRICTMODE_ENABLED = 4096;
	public const uint32 CODEINTEGRITY_OPTION_HVCI_IUM_ENABLED = 8192;
	public const uint32 FILE_MAXIMUM_DISPOSITION = 5;
	public const uint32 FILE_DIRECTORY_FILE = 1;
	public const uint32 FILE_WRITE_THROUGH = 2;
	public const uint32 FILE_SEQUENTIAL_ONLY = 4;
	public const uint32 FILE_NO_INTERMEDIATE_BUFFERING = 8;
	public const uint32 FILE_SYNCHRONOUS_IO_ALERT = 16;
	public const uint32 FILE_SYNCHRONOUS_IO_NONALERT = 32;
	public const uint32 FILE_NON_DIRECTORY_FILE = 64;
	public const uint32 FILE_CREATE_TREE_CONNECTION = 128;
	public const uint32 FILE_COMPLETE_IF_OPLOCKED = 256;
	public const uint32 FILE_NO_EA_KNOWLEDGE = 512;
	public const uint32 FILE_OPEN_REMOTE_INSTANCE = 1024;
	public const uint32 FILE_RANDOM_ACCESS = 2048;
	public const uint32 FILE_DELETE_ON_CLOSE = 4096;
	public const uint32 FILE_OPEN_BY_FILE_ID = 8192;
	public const uint32 FILE_OPEN_FOR_BACKUP_INTENT = 16384;
	public const uint32 FILE_NO_COMPRESSION = 32768;
	public const uint32 FILE_OPEN_REQUIRING_OPLOCK = 65536;
	public const uint32 FILE_RESERVE_OPFILTER = 1048576;
	public const uint32 FILE_OPEN_REPARSE_POINT = 2097152;
	public const uint32 FILE_OPEN_NO_RECALL = 4194304;
	public const uint32 FILE_OPEN_FOR_FREE_SPACE_QUERY = 8388608;
	public const uint32 FILE_VALID_OPTION_FLAGS = 16777215;
	public const uint32 FILE_VALID_PIPE_OPTION_FLAGS = 50;
	public const uint32 FILE_VALID_MAILSLOT_OPTION_FLAGS = 50;
	public const uint32 FILE_VALID_SET_FLAGS = 54;
	public const uint32 FILE_SUPERSEDED = 0;
	public const uint32 FILE_OPENED = 1;
	public const uint32 FILE_CREATED = 2;
	public const uint32 FILE_OVERWRITTEN = 3;
	public const uint32 FILE_EXISTS = 4;
	public const uint32 FILE_DOES_NOT_EXIST = 5;
	public const uint32 WINWATCHNOTIFY_START = 0;
	public const uint32 WINWATCHNOTIFY_STOP = 1;
	public const uint32 WINWATCHNOTIFY_DESTROY = 2;
	public const uint32 WINWATCHNOTIFY_CHANGING = 3;
	public const uint32 WINWATCHNOTIFY_CHANGED = 4;
	public const uint32 RSC_FLAG_INF = 1;
	public const uint32 RSC_FLAG_SKIPDISKSPACECHECK = 2;
	public const uint32 RSC_FLAG_QUIET = 4;
	public const uint32 RSC_FLAG_NGCONV = 8;
	public const uint32 RSC_FLAG_UPDHLPDLLS = 16;
	public const uint32 RSC_FLAG_DELAYREGISTEROCX = 512;
	public const uint32 RSC_FLAG_SETUPAPI = 1024;
	public const uint32 ALINF_QUIET = 4;
	public const uint32 ALINF_NGCONV = 8;
	public const uint32 ALINF_UPDHLPDLLS = 16;
	public const uint32 ALINF_BKINSTALL = 32;
	public const uint32 ALINF_ROLLBACK = 64;
	public const uint32 ALINF_CHECKBKDATA = 128;
	public const uint32 ALINF_ROLLBKDOALL = 256;
	public const uint32 ALINF_DELAYREGISTEROCX = 512;
	public const uint32 AIF_WARNIFSKIP = 1;
	public const uint32 AIF_NOSKIP = 2;
	public const uint32 AIF_NOVERSIONCHECK = 4;
	public const uint32 AIF_FORCE_FILE_IN_USE = 8;
	public const uint32 AIF_NOOVERWRITE = 16;
	public const uint32 AIF_NO_VERSION_DIALOG = 32;
	public const uint32 AIF_REPLACEONLY = 1024;
	public const uint32 AIF_NOLANGUAGECHECK = 268435456;
	public const uint32 AIF_QUIET = 536870912;
	public const uint32 IE4_RESTORE = 1;
	public const uint32 IE4_BACKNEW = 2;
	public const uint32 IE4_NODELETENEW = 4;
	public const uint32 IE4_NOMESSAGES = 8;
	public const uint32 IE4_NOPROGRESS = 16;
	public const uint32 IE4_NOENUMKEY = 32;
	public const uint32 IE4_NO_CRC_MAPPING = 64;
	public const uint32 IE4_REGSECTION = 128;
	public const uint32 IE4_FRDOALL = 256;
	public const uint32 IE4_UPDREFCNT = 512;
	public const uint32 IE4_USEREFCNT = 1024;
	public const uint32 IE4_EXTRAINCREFCNT = 2048;
	public const uint32 IE4_REMOVREGBKDATA = 4096;
	public const uint32 ARSR_RESTORE = 1;
	public const uint32 ARSR_NOMESSAGES = 8;
	public const uint32 ARSR_REGSECTION = 128;
	public const uint32 ARSR_REMOVREGBKDATA = 4096;
	public const String REG_SAVE_LOG_KEY = "RegSaveLogFile";
	public const String REG_RESTORE_LOG_KEY = "RegRestoreLogFile";
	public const uint32 AFSR_RESTORE = 1;
	public const uint32 AFSR_BACKNEW = 2;
	public const uint32 AFSR_NODELETENEW = 4;
	public const uint32 AFSR_NOMESSAGES = 8;
	public const uint32 AFSR_NOPROGRESS = 16;
	public const uint32 AFSR_UPDREFCNT = 512;
	public const uint32 AFSR_USEREFCNT = 1024;
	public const uint32 AFSR_EXTRAINCREFCNT = 2048;
	public const uint32 AADBE_ADD_ENTRY = 1;
	public const uint32 AADBE_DEL_ENTRY = 2;
	public const uint32 ADN_DEL_IF_EMPTY = 1;
	public const uint32 ADN_DONT_DEL_SUBDIRS = 2;
	public const uint32 ADN_DONT_DEL_DIR = 4;
	public const uint32 ADN_DEL_UNC_PATHS = 8;
	public const uint32 LIS_QUIET = 1;
	public const uint32 LIS_NOGRPCONV = 2;
	public const uint32 RUNCMDS_QUIET = 1;
	public const uint32 RUNCMDS_NOWAIT = 2;
	public const uint32 RUNCMDS_DELAYPOSTCMD = 4;
	public const uint32 IME_MAXPROCESS = 32;
	public const uint32 CP_HWND = 0;
	public const uint32 CP_OPEN = 1;
	public const uint32 CP_DIRECT = 2;
	public const uint32 CP_LEVEL = 3;
	public const uint32 MCW_DEFAULT = 0;
	public const uint32 MCW_RECT = 1;
	public const uint32 MCW_WINDOW = 2;
	public const uint32 MCW_SCREEN = 4;
	public const uint32 MCW_VERTICAL = 8;
	public const uint32 MCW_HIDDEN = 16;
	public const uint32 IME_MODE_ALPHANUMERIC = 1;
	public const uint32 IME_MODE_SBCSCHAR = 2;
	public const uint32 IME_MODE_KATAKANA = 2;
	public const uint32 IME_MODE_HIRAGANA = 4;
	public const uint32 IME_MODE_HANJACONVERT = 4;
	public const uint32 IME_MODE_DBCSCHAR = 16;
	public const uint32 IME_MODE_ROMAN = 32;
	public const uint32 IME_MODE_NOROMAN = 64;
	public const uint32 IME_MODE_CODEINPUT = 128;
	public const uint32 IME_MODE_NOCODEINPUT = 256;
	public const uint32 IME_GETIMECAPS = 3;
	public const uint32 IME_SETOPEN = 4;
	public const uint32 IME_GETOPEN = 5;
	public const uint32 IME_GETVERSION = 7;
	public const uint32 IME_SETCONVERSIONWINDOW = 8;
	public const uint32 IME_MOVEIMEWINDOW = 8;
	public const uint32 IME_SETCONVERSIONMODE = 16;
	public const uint32 IME_GETCONVERSIONMODE = 17;
	public const uint32 IME_SET_MODE = 18;
	public const uint32 IME_SENDVKEY = 19;
	public const uint32 IME_ENTERWORDREGISTERMODE = 24;
	public const uint32 IME_SETCONVERSIONFONTEX = 25;
	public const uint32 IME_BANJAtoJUNJA = 19;
	public const uint32 IME_JUNJAtoBANJA = 20;
	public const uint32 IME_JOHABtoKS = 21;
	public const uint32 IME_KStoJOHAB = 22;
	public const uint32 IMEA_INIT = 1;
	public const uint32 IMEA_NEXT = 2;
	public const uint32 IMEA_PREV = 3;
	public const uint32 IME_REQUEST_CONVERT = 1;
	public const uint32 IME_ENABLE_CONVERT = 2;
	public const uint32 INTERIM_WINDOW = 0;
	public const uint32 MODE_WINDOW = 1;
	public const uint32 HANJA_WINDOW = 2;
	public const uint32 IME_RS_ERROR = 1;
	public const uint32 IME_RS_NOIME = 2;
	public const uint32 IME_RS_TOOLONG = 5;
	public const uint32 IME_RS_ILLEGAL = 6;
	public const uint32 IME_RS_NOTFOUND = 7;
	public const uint32 IME_RS_NOROOM = 10;
	public const uint32 IME_RS_DISKERROR = 14;
	public const uint32 IME_RS_INVALID = 17;
	public const uint32 IME_RS_NEST = 18;
	public const uint32 IME_RS_SYSTEMMODAL = 19;
	public const uint32 WM_IME_REPORT = 640;
	public const uint32 IR_STRINGSTART = 256;
	public const uint32 IR_STRINGEND = 257;
	public const uint32 IR_OPENCONVERT = 288;
	public const uint32 IR_CHANGECONVERT = 289;
	public const uint32 IR_CLOSECONVERT = 290;
	public const uint32 IR_FULLCONVERT = 291;
	public const uint32 IR_IMESELECT = 304;
	public const uint32 IR_STRING = 320;
	public const uint32 IR_DBCSCHAR = 352;
	public const uint32 IR_UNDETERMINE = 368;
	public const uint32 IR_STRINGEX = 384;
	public const uint32 IR_MODEINFO = 400;
	public const uint32 WM_WNT_CONVERTREQUESTEX = 265;
	public const uint32 WM_CONVERTREQUEST = 266;
	public const uint32 WM_CONVERTRESULT = 267;
	public const uint32 WM_INTERIM = 268;
	public const uint32 WM_IMEKEYDOWN = 656;
	public const uint32 WM_IMEKEYUP = 657;
	public const uint32 DELAYLOAD_GPA_FAILURE = 4;
	public const Guid CATID_DeleteBrowsingHistory = .(0x31caf6e4, 0xd6aa, 0x4090, 0xa0, 0x50, 0xa5, 0xac, 0x89, 0x72, 0xe9, 0xef);
	public const uint32 DELETE_BROWSING_HISTORY_HISTORY = 1;
	public const uint32 DELETE_BROWSING_HISTORY_COOKIES = 2;
	public const uint32 DELETE_BROWSING_HISTORY_TIF = 4;
	public const uint32 DELETE_BROWSING_HISTORY_FORMDATA = 8;
	public const uint32 DELETE_BROWSING_HISTORY_PASSWORDS = 16;
	public const uint32 DELETE_BROWSING_HISTORY_PRESERVEFAVORITES = 32;
	public const uint32 DELETE_BROWSING_HISTORY_DOWNLOADHISTORY = 64;
}
#endregion

#region TypeDefs
typealias HWINWATCH = int;

typealias FEATURE_STATE_CHANGE_SUBSCRIPTION = int;

typealias FH_SERVICE_PIPE_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum TDIENTITY_ENTITY_TYPE : uint32
{
	GENERIC_ENTITY = 0,
	AT_ENTITY = 640,
	CL_NL_ENTITY = 769,
	CO_NL_ENTITY = 768,
	CL_TL_ENTITY = 1025,
	CO_TL_ENTITY = 1024,
	ER_ENTITY = 896,
	IF_ENTITY = 512,
}


[AllowDuplicates]
public enum FILE_INFORMATION_CLASS : int32
{
	FileDirectoryInformation = 1,
}


[AllowDuplicates]
public enum SYSTEM_INFORMATION_CLASS : int32
{
	SystemBasicInformation = 0,
	SystemPerformanceInformation = 2,
	SystemTimeOfDayInformation = 3,
	SystemProcessInformation = 5,
	SystemProcessorPerformanceInformation = 8,
	SystemInterruptInformation = 23,
	SystemExceptionInformation = 33,
	SystemRegistryQuotaInformation = 37,
	SystemLookasideInformation = 45,
	SystemCodeIntegrityInformation = 103,
	SystemPolicyInformation = 134,
}


[AllowDuplicates]
public enum OBJECT_INFORMATION_CLASS : int32
{
	ObjectBasicInformation = 0,
	ObjectTypeInformation = 2,
}


[AllowDuplicates]
public enum KEY_SET_INFORMATION_CLASS : int32
{
	KeyWriteTimeInformation = 0,
	KeyWow64FlagsInformation = 1,
	KeyControlFlagsInformation = 2,
	KeySetVirtualizationInformation = 3,
	KeySetDebugInformation = 4,
	KeySetHandleTagsInformation = 5,
	MaxKeySetInfoClass = 6,
}


[AllowDuplicates]
public enum WINSTATIONINFOCLASS : int32
{
	WinStationInformation = 8,
}


[AllowDuplicates]
public enum CameraUIControlMode : int32
{
	Browse = 0,
	Linear = 1,
}


[AllowDuplicates]
public enum CameraUIControlLinearSelectionMode : int32
{
	Single = 0,
	Multiple = 1,
}


[AllowDuplicates]
public enum CameraUIControlCaptureMode : int32
{
	PhotoOrVideo = 0,
	Photo = 1,
	Video = 2,
}


[AllowDuplicates]
public enum CameraUIControlPhotoFormat : int32
{
	Jpeg = 0,
	Png = 1,
	JpegXR = 2,
}


[AllowDuplicates]
public enum CameraUIControlVideoFormat : int32
{
	Mp4 = 0,
	Wmv = 1,
}


[AllowDuplicates]
public enum CameraUIControlViewType : int32
{
	SingleItem = 0,
	ItemList = 1,
}


[AllowDuplicates]
public enum FEATURE_CHANGE_TIME : int32
{
	FEATURE_CHANGE_TIME_READ = 0,
	FEATURE_CHANGE_TIME_MODULE_RELOAD = 1,
	FEATURE_CHANGE_TIME_SESSION = 2,
	FEATURE_CHANGE_TIME_REBOOT = 3,
}


[AllowDuplicates]
public enum FEATURE_ENABLED_STATE : int32
{
	FEATURE_ENABLED_STATE_DEFAULT = 0,
	FEATURE_ENABLED_STATE_DISABLED = 1,
	FEATURE_ENABLED_STATE_ENABLED = 2,
}


[AllowDuplicates]
public enum TDI_TL_IO_CONTROL_TYPE : int32
{
	EndpointIoControlType = 0,
	SetSockOptIoControlType = 1,
	GetSockOptIoControlType = 2,
	SocketIoControlType = 3,
}


[AllowDuplicates]
public enum WLDP_HOST : int32
{
	WLDP_HOST_RUNDLL32 = 0,
	WLDP_HOST_SVCHOST = 1,
	WLDP_HOST_MAX = 2,
}


[AllowDuplicates]
public enum WLDP_HOST_ID : int32
{
	WLDP_HOST_ID_UNKNOWN = 0,
	WLDP_HOST_ID_GLOBAL = 1,
	WLDP_HOST_ID_VBA = 2,
	WLDP_HOST_ID_WSH = 3,
	WLDP_HOST_ID_POWERSHELL = 4,
	WLDP_HOST_ID_IE = 5,
	WLDP_HOST_ID_MSI = 6,
	WLDP_HOST_ID_ALL = 7,
	WLDP_HOST_ID_MAX = 8,
}


[AllowDuplicates]
public enum DECISION_LOCATION : int32
{
	DECISION_LOCATION_REFRESH_GLOBAL_DATA = 0,
	DECISION_LOCATION_PARAMETER_VALIDATION = 1,
	DECISION_LOCATION_AUDIT = 2,
	DECISION_LOCATION_FAILED_CONVERT_GUID = 3,
	DECISION_LOCATION_ENTERPRISE_DEFINED_CLASS_ID = 4,
	DECISION_LOCATION_GLOBAL_BUILT_IN_LIST = 5,
	DECISION_LOCATION_PROVIDER_BUILT_IN_LIST = 6,
	DECISION_LOCATION_ENFORCE_STATE_LIST = 7,
	DECISION_LOCATION_NOT_FOUND = 8,
	DECISION_LOCATION_UNKNOWN = 9,
}


[AllowDuplicates]
public enum WLDP_KEY : int32
{
	KEY_UNKNOWN = 0,
	KEY_OVERRIDE = 1,
	KEY_ALL_KEYS = 2,
}


[AllowDuplicates]
public enum VALUENAME : int32
{
	VALUENAME_UNKNOWN = 0,
	VALUENAME_ENTERPRISE_DEFINED_CLASS_ID = 1,
	VALUENAME_BUILT_IN_LIST = 2,
}


[AllowDuplicates]
public enum WLDP_WINDOWS_LOCKDOWN_MODE : int32
{
	WLDP_WINDOWS_LOCKDOWN_MODE_UNLOCKED = 0,
	WLDP_WINDOWS_LOCKDOWN_MODE_TRIAL = 1,
	WLDP_WINDOWS_LOCKDOWN_MODE_LOCKED = 2,
	WLDP_WINDOWS_LOCKDOWN_MODE_MAX = 3,
}


[AllowDuplicates]
public enum WLDP_WINDOWS_LOCKDOWN_RESTRICTION : int32
{
	WLDP_WINDOWS_LOCKDOWN_RESTRICTION_NONE = 0,
	WLDP_WINDOWS_LOCKDOWN_RESTRICTION_NOUNLOCK = 1,
	WLDP_WINDOWS_LOCKDOWN_RESTRICTION_NOUNLOCK_PERMANENT = 2,
	WLDP_WINDOWS_LOCKDOWN_RESTRICTION_MAX = 3,
}


[AllowDuplicates]
public enum WLDP_POLICY_SETTING : int32
{
	WLDP_POLICY_SETTING_AV_PERF_MODE = 1000,
}

#endregion

#region Function Pointers
public function void* PFIBER_CALLOUT_ROUTINE(void* lpParameter);

public function BOOL PQUERYACTCTXW_FUNC(uint32 dwFlags, HANDLE hActCtx, void* pvSubInstance, uint32 ulInfoClass, void* pvBuffer, uint cbBuffer, uint* pcbWrittenOrRequired);

public function uint32 APPLICATION_RECOVERY_CALLBACK(void* pvParameter);

public function void PIO_APC_ROUTINE(void* ApcContext, IO_STATUS_BLOCK* IoStatusBlock, uint32 Reserved);

public function BOOLEAN PWINSTATIONQUERYINFORMATIONW(HANDLE param0, uint32 param1, WINSTATIONINFOCLASS param2, void* param3, uint32 param4, uint32* param5);

public function void PFEATURE_STATE_CHANGE_CALLBACK(void* context);

public function void ENUM_CALLBACK(DCISURFACEINFO* lpSurfaceInfo, void* lpContext);

public function void WINWATCHNOTIFYPROC(HWINWATCH hww, HWND hwnd, uint32 code, LPARAM lParam);

public function HRESULT REGINSTALLA(HINSTANCE hm, PSTR pszSection, STRTABLEA* pstTable);

public function HRESULT PWLDP_SETDYNAMICCODETRUST_API(HANDLE hFileHandle);

public function HRESULT PWLDP_ISDYNAMICCODEPOLICYENABLED_API(BOOL* pbEnabled);

public function HRESULT PWLDP_QUERYDYNAMICODETRUST_API(HANDLE fileHandle, void* baseImage, uint32 imageSize);

public function HRESULT PWLDP_QUERYWINDOWSLOCKDOWNMODE_API(WLDP_WINDOWS_LOCKDOWN_MODE* lockdownMode);

public function HRESULT PWLDP_QUERYDEVICESECURITYINFORMATION_API(WLDP_DEVICE_SECURITY_INFORMATION* information, uint32 informationLength, uint32* returnLength);

public function HRESULT PWLDP_QUERYWINDOWSLOCKDOWNRESTRICTION_API(WLDP_WINDOWS_LOCKDOWN_RESTRICTION* LockdownRestriction);

public function HRESULT PWLDP_SETWINDOWSLOCKDOWNRESTRICTION_API(WLDP_WINDOWS_LOCKDOWN_RESTRICTION LockdownRestriction);

public function HRESULT PWLDP_ISAPPAPPROVEDBYPOLICY_API(PWSTR PackageFamilyName, uint64 PackageVersion);

public function HRESULT PWLDP_QUERYPOLICYSETTINGENABLED_API(WLDP_POLICY_SETTING Setting, BOOL* Enabled);

public function HRESULT PWLDP_QUERYPOLICYSETTINGENABLED2_API(PWSTR Setting, BOOL* Enabled);

public function HRESULT PWLDP_ISWCOSPRODUCTIONCONFIGURATION_API(BOOL* IsProductionConfiguration);

public function HRESULT PWLDP_RESETWCOSPRODUCTIONCONFIGURATION_API();

public function HRESULT PWLDP_ISPRODUCTIONCONFIGURATION_API(BOOL* IsProductionConfiguration);

public function HRESULT PWLDP_RESETPRODUCTIONCONFIGURATION_API();

public function void* PDELAYLOAD_FAILURE_DLL_CALLBACK(uint32 NotificationReason, DELAYLOAD_INFO* DelayloadInfo);

#endregion

#region Structs
[CRepr]
public struct _D3DHAL_CALLBACKS
{
}

[CRepr]
public struct _D3DHAL_GLOBALDRIVERDATA
{
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct TCP_REQUEST_QUERY_INFORMATION_EX32_XP
{
	public TDIObjectID ID;
	public uint32[4] Context;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DELAYLOAD_INFO
{
	public uint32 Size;
	public IMAGE_DELAYLOAD_DESCRIPTOR* DelayloadDescriptor;
	public IMAGE_THUNK_DATA64* ThunkAddress;
	public PSTR TargetDllName;
	public DELAYLOAD_PROC_DESCRIPTOR TargetApiDescriptor;
	public void* TargetModuleBase;
	public void* Unused;
	public uint32 LastError;
}
#endif

[CRepr]
public struct IMAGE_THUNK_DATA64
{
	[CRepr, Union]
	public struct _u1_e__Union
	{
		public uint64 ForwarderString;
		public uint64 Function;
		public uint64 Ordinal;
		public uint64 AddressOfData;
	}
	public _u1_e__Union u1;
}

[CRepr]
public struct IMAGE_THUNK_DATA32
{
	[CRepr, Union]
	public struct _u1_e__Union
	{
		public uint32 ForwarderString;
		public uint32 Function;
		public uint32 Ordinal;
		public uint32 AddressOfData;
	}
	public _u1_e__Union u1;
}

[CRepr]
public struct IMAGE_DELAYLOAD_DESCRIPTOR
{
	[CRepr, Union]
	public struct _Attributes_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 AllAttributes;
		public using _Anonymous_e__Struct Anonymous;
	}
	public _Attributes_e__Union Attributes;
	public uint32 DllNameRVA;
	public uint32 ModuleHandleRVA;
	public uint32 ImportAddressTableRVA;
	public uint32 ImportNameTableRVA;
	public uint32 BoundImportAddressTableRVA;
	public uint32 UnloadInformationTableRVA;
	public uint32 TimeDateStamp;
}

[CRepr]
public struct CUSTOM_SYSTEM_EVENT_TRIGGER_CONFIG
{
	public uint32 Size;
	public PWSTR TriggerId;
}

[CRepr]
public struct JIT_DEBUG_INFO
{
	public uint32 dwSize;
	public uint32 dwProcessorArchitecture;
	public uint32 dwThreadID;
	public uint32 dwReserved0;
	public uint64 lpExceptionAddress;
	public uint64 lpExceptionRecord;
	public uint64 lpContextRecord;
}

[CRepr]
public struct HW_PROFILE_INFOA
{
	public uint32 dwDockInfo;
	public CHAR[39] szHwProfileGuid;
	public CHAR[80] szHwProfileName;
}

[CRepr]
public struct HW_PROFILE_INFOW
{
	public uint32 dwDockInfo;
	public char16[39] szHwProfileGuid;
	public char16[80] szHwProfileName;
}

[CRepr]
public struct ACTCTX_SECTION_KEYED_DATA_2600
{
	public uint32 cbSize;
	public uint32 ulDataFormatVersion;
	public void* lpData;
	public uint32 ulLength;
	public void* lpSectionGlobalData;
	public uint32 ulSectionGlobalDataLength;
	public void* lpSectionBase;
	public uint32 ulSectionTotalLength;
	public HANDLE hActCtx;
	public uint32 ulAssemblyRosterIndex;
}

[CRepr]
public struct ACTCTX_SECTION_KEYED_DATA_ASSEMBLY_METADATA
{
	public void* lpInformation;
	public void* lpSectionBase;
	public uint32 ulSectionLength;
	public void* lpSectionGlobalDataBase;
	public uint32 ulSectionGlobalDataLength;
}

[CRepr]
public struct ACTIVATION_CONTEXT_BASIC_INFORMATION
{
	public HANDLE hActCtx;
	public uint32 dwFlags;
}

[CRepr]
public struct FILE_CASE_SENSITIVE_INFO
{
	public uint32 Flags;
}

[CRepr]
public struct FILE_DISPOSITION_INFO_EX
{
	public uint32 Flags;
}

[CRepr]
public struct CLIENT_ID
{
	public HANDLE UniqueProcess;
	public HANDLE UniqueThread;
}

[CRepr]
public struct LDR_DATA_TABLE_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 CheckSum;
		public void* Reserved6;
	}
	public void*[2] Reserved1;
	public LIST_ENTRY InMemoryOrderLinks;
	public void*[2] Reserved2;
	public void* DllBase;
	public void*[2] Reserved3;
	public UNICODE_STRING FullDllName;
	public uint8[8] Reserved4;
	public void*[3] Reserved5;
	public using _Anonymous_e__Union Anonymous;
	public uint32 TimeDateStamp;
}

[CRepr]
public struct OBJECT_ATTRIBUTES
{
	public uint32 Length;
	public HANDLE RootDirectory;
	public UNICODE_STRING* ObjectName;
	public uint32 Attributes;
	public void* SecurityDescriptor;
	public void* SecurityQualityOfService;
}

[CRepr]
public struct IO_STATUS_BLOCK
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public NTSTATUS Status;
		public void* Pointer;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint Information;
}

[CRepr]
public struct SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION
{
	public LARGE_INTEGER IdleTime;
	public LARGE_INTEGER KernelTime;
	public LARGE_INTEGER UserTime;
	public LARGE_INTEGER[2] Reserved1;
	public uint32 Reserved2;
}

[CRepr]
public struct SYSTEM_PROCESS_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint32 NumberOfThreads;
	public uint8[48] Reserved1;
	public UNICODE_STRING ImageName;
	public int32 BasePriority;
	public HANDLE UniqueProcessId;
	public void* Reserved2;
	public uint32 HandleCount;
	public uint32 SessionId;
	public void* Reserved3;
	public uint PeakVirtualSize;
	public uint VirtualSize;
	public uint32 Reserved4;
	public uint PeakWorkingSetSize;
	public uint WorkingSetSize;
	public void* Reserved5;
	public uint QuotaPagedPoolUsage;
	public void* Reserved6;
	public uint QuotaNonPagedPoolUsage;
	public uint PagefileUsage;
	public uint PeakPagefileUsage;
	public uint PrivatePageCount;
	public LARGE_INTEGER[6] Reserved7;
}

[CRepr]
public struct SYSTEM_THREAD_INFORMATION
{
	public LARGE_INTEGER[3] Reserved1;
	public uint32 Reserved2;
	public void* StartAddress;
	public CLIENT_ID ClientId;
	public int32 Priority;
	public int32 BasePriority;
	public uint32 Reserved3;
	public uint32 ThreadState;
	public uint32 WaitReason;
}

[CRepr]
public struct SYSTEM_REGISTRY_QUOTA_INFORMATION
{
	public uint32 RegistryQuotaAllowed;
	public uint32 RegistryQuotaUsed;
	public void* Reserved1;
}

[CRepr]
public struct SYSTEM_BASIC_INFORMATION
{
	public uint8[24] Reserved1;
	public void*[4] Reserved2;
	public int8 NumberOfProcessors;
}

[CRepr]
public struct SYSTEM_TIMEOFDAY_INFORMATION
{
	public uint8[48] Reserved1;
}

[CRepr]
public struct SYSTEM_PERFORMANCE_INFORMATION
{
	public uint8[312] Reserved1;
}

[CRepr]
public struct SYSTEM_EXCEPTION_INFORMATION
{
	public uint8[16] Reserved1;
}

[CRepr]
public struct SYSTEM_LOOKASIDE_INFORMATION
{
	public uint8[32] Reserved1;
}

[CRepr]
public struct SYSTEM_INTERRUPT_INFORMATION
{
	public uint8[24] Reserved1;
}

[CRepr]
public struct SYSTEM_POLICY_INFORMATION
{
	public void*[2] Reserved1;
	public uint32[3] Reserved2;
}

[CRepr]
public struct THREAD_NAME_INFORMATION
{
	public UNICODE_STRING ThreadName;
}

[CRepr]
public struct SYSTEM_CODEINTEGRITY_INFORMATION
{
	public uint32 Length;
	public uint32 CodeIntegrityOptions;
}

[CRepr]
public struct PUBLIC_OBJECT_BASIC_INFORMATION
{
	public uint32 Attributes;
	public uint32 GrantedAccess;
	public uint32 HandleCount;
	public uint32 PointerCount;
	public uint32[10] Reserved;
}

[CRepr]
public struct PUBLIC_OBJECT_TYPE_INFORMATION
{
	public UNICODE_STRING TypeName;
	public uint32[22] Reserved;
}

[CRepr]
public struct KEY_VALUE_ENTRY
{
	public UNICODE_STRING* ValueName;
	public uint32 DataLength;
	public uint32 DataOffset;
	public uint32 Type;
}

[CRepr]
public struct WINSTATIONINFORMATIONW
{
	public uint8[70] Reserved2;
	public uint32 LogonId;
	public uint8[1140] Reserved3;
}

[CRepr]
public struct FEATURE_ERROR
{
	public HRESULT hr;
	public uint16 lineNumber;
	public PSTR file;
	public PSTR process;
	public PSTR module;
	public uint32 callerReturnAddressOffset;
	public PSTR callerModule;
	public PSTR message;
	public uint16 originLineNumber;
	public PSTR originFile;
	public PSTR originModule;
	public uint32 originCallerReturnAddressOffset;
	public PSTR originCallerModule;
	public PSTR originName;
}

[CRepr]
public struct DCICMD
{
	public uint32 dwCommand;
	public uint32 dwParam1;
	public uint32 dwParam2;
	public uint32 dwVersion;
	public uint32 dwReserved;
}

[CRepr]
public struct DCICREATEINPUT
{
	public DCICMD cmd;
	public uint32 dwCompression;
	public uint32[3] dwMask;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public uint32 dwDCICaps;
	public uint32 dwBitCount;
	public void* lpSurface;
}

[CRepr]
public struct DCISURFACEINFO
{
	public uint32 dwSize;
	public uint32 dwDCICaps;
	public uint32 dwCompression;
	public uint32[3] dwMask;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public int32 lStride;
	public uint32 dwBitCount;
	public uint dwOffSurface;
	public uint16 wSelSurface;
	public uint16 wReserved;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public int BeginAccess;
	public int EndAccess;
	public int DestroySurface;
}

[CRepr]
public struct DCIENUMINPUT
{
	public DCICMD cmd;
	public RECT rSrc;
	public RECT rDst;
	public int EnumCallback;
	public void* lpContext;
}

[CRepr]
public struct DCIOFFSCREEN
{
	public DCISURFACEINFO dciInfo;
	public int Draw;
	public int SetClipList;
	public int SetDestination;
}

[CRepr]
public struct DCIOVERLAY
{
	public DCISURFACEINFO dciInfo;
	public uint32 dwChromakeyValue;
	public uint32 dwChromakeyMask;
}

[CRepr]
public struct STRENTRYA
{
	public PSTR pszName;
	public PSTR pszValue;
}

[CRepr]
public struct STRENTRYW
{
	public PWSTR pszName;
	public PWSTR pszValue;
}

[CRepr]
public struct STRTABLEA
{
	public uint32 cEntries;
	public STRENTRYA* pse;
}

[CRepr]
public struct STRTABLEW
{
	public uint32 cEntries;
	public STRENTRYW* pse;
}

[CRepr]
public struct CABINFOA
{
	public PSTR pszCab;
	public PSTR pszInf;
	public PSTR pszSection;
	public CHAR[260] szSrcPath;
	public uint32 dwFlags;
}

[CRepr]
public struct CABINFOW
{
	public PWSTR pszCab;
	public PWSTR pszInf;
	public PWSTR pszSection;
	public char16[260] szSrcPath;
	public uint32 dwFlags;
}

[CRepr]
public struct PERUSERSECTIONA
{
	public CHAR[59] szGUID;
	public CHAR[128] szDispName;
	public CHAR[10] szLocale;
	public CHAR[1040] szStub;
	public CHAR[32] szVersion;
	public CHAR[128] szCompID;
	public uint32 dwIsInstalled;
	public BOOL bRollback;
}

[CRepr]
public struct PERUSERSECTIONW
{
	public char16[59] szGUID;
	public char16[128] szDispName;
	public char16[10] szLocale;
	public char16[1040] szStub;
	public char16[32] szVersion;
	public char16[128] szCompID;
	public uint32 dwIsInstalled;
	public BOOL bRollback;
}

[CRepr]
public struct IMESTRUCT
{
	public uint32 fnc;
	public WPARAM wParam;
	public uint32 wCount;
	public uint32 dchSource;
	public uint32 dchDest;
	public LPARAM lParam1;
	public LPARAM lParam2;
	public LPARAM lParam3;
}

[CRepr]
public struct UNDETERMINESTRUCT
{
	public uint32 dwSize;
	public uint32 uDefIMESize;
	public uint32 uDefIMEPos;
	public uint32 uUndetTextLen;
	public uint32 uUndetTextPos;
	public uint32 uUndetAttrPos;
	public uint32 uCursorPos;
	public uint32 uDeltaStart;
	public uint32 uDetermineTextLen;
	public uint32 uDetermineTextPos;
	public uint32 uDetermineDelimPos;
	public uint32 uYomiTextLen;
	public uint32 uYomiTextPos;
	public uint32 uYomiDelimPos;
}

[CRepr]
public struct STRINGEXSTRUCT
{
	public uint32 dwSize;
	public uint32 uDeterminePos;
	public uint32 uDetermineDelimPos;
	public uint32 uYomiPos;
	public uint32 uYomiDelimPos;
}

[CRepr]
public struct DATETIME
{
	public uint16 year;
	public uint16 month;
	public uint16 day;
	public uint16 hour;
	public uint16 min;
	public uint16 sec;
}

[CRepr]
public struct IMEPROA
{
	public HWND hWnd;
	public DATETIME InstDate;
	public uint32 wVersion;
	public uint8[50] szDescription;
	public uint8[80] szName;
	public uint8[30] szOptions;
}

[CRepr]
public struct IMEPROW
{
	public HWND hWnd;
	public DATETIME InstDate;
	public uint32 wVersion;
	public char16[50] szDescription;
	public char16[80] szName;
	public char16[30] szOptions;
}

[CRepr]
public struct JAVA_TRUST
{
	public uint32 cbSize;
	public uint32 flag;
	public BOOL fAllActiveXPermissions;
	public BOOL fAllPermissions;
	public uint32 dwEncodingType;
	public uint8* pbJavaPermissions;
	public uint32 cbJavaPermissions;
	public uint8* pbSigner;
	public uint32 cbSigner;
	public PWSTR pwszZone;
	public Guid guidZone;
	public HRESULT hVerify;
}

[CRepr]
public struct TDIEntityID
{
	public TDIENTITY_ENTITY_TYPE tei_entity;
	public uint32 tei_instance;
}

[CRepr]
public struct TDIObjectID
{
	public TDIEntityID toi_entity;
	public uint32 toi_class;
	public uint32 toi_type;
	public uint32 toi_id;
}

[CRepr]
public struct TCP_REQUEST_QUERY_INFORMATION_EX_XP
{
	public TDIObjectID ID;
	public uint[4] Context;
}

[CRepr]
public struct TCP_REQUEST_QUERY_INFORMATION_EX_W2K
{
	public TDIObjectID ID;
	public uint8[16] Context;
}

[CRepr]
public struct TCP_REQUEST_SET_INFORMATION_EX
{
	public TDIObjectID ID;
	public uint32 BufferSize;
	public uint8* Buffer mut => &Buffer_impl;
	private uint8[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct TDI_TL_IO_CONTROL_ENDPOINT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 IoControlCode;
		public uint32 OptionName;
	}
	public TDI_TL_IO_CONTROL_TYPE Type;
	public uint32 Level;
	public using _Anonymous_e__Union Anonymous;
	public void* InputBuffer;
	public uint32 InputBufferLength;
	public void* OutputBuffer;
	public uint32 OutputBufferLength;
}

[CRepr]
public struct WLDP_HOST_INFORMATION
{
	public uint32 dwRevision;
	public WLDP_HOST_ID dwHostId;
	public PWSTR szSource;
	public HANDLE hSource;
}

[CRepr]
public struct WLDP_DEVICE_SECURITY_INFORMATION
{
	public uint32 UnlockIdSize;
	public uint8* UnlockId;
	public uint32 ManufacturerIDLength;
	public PWSTR ManufacturerID;
}

[CRepr]
public struct DELAYLOAD_PROC_DESCRIPTOR
{
	[CRepr, Union]
	public struct _Description_e__Union
	{
		public PSTR Name;
		public uint32 Ordinal;
	}
	public uint32 ImportDescribedByName;
	public _Description_e__Union Description;
}

#if BF_32_BIT
[CRepr]
public struct DELAYLOAD_INFO
{
	public uint32 Size;
	public IMAGE_DELAYLOAD_DESCRIPTOR* DelayloadDescriptor;
	public IMAGE_THUNK_DATA32* ThunkAddress;
	public PSTR TargetDllName;
	public DELAYLOAD_PROC_DESCRIPTOR TargetApiDescriptor;
	public void* TargetModuleBase;
	public void* Unused;
	public uint32 LastError;
}
#endif

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CameraUIControl = .(0x16d5a2be, 0xb1c5, 0x47b3, 0x8e, 0xae, 0xcc, 0xbc, 0xf4, 0x52, 0xc7, 0xe8);


	public const Guid CLSID_EditionUpgradeHelper = .(0x01776df3, 0xb9af, 0x4e50, 0x9b, 0x1c, 0x56, 0xe9, 0x31, 0x16, 0xd7, 0x04);


	public const Guid CLSID_EditionUpgradeBroker = .(0xc4270827, 0x4f39, 0x45df, 0x92, 0x88, 0x12, 0xff, 0x6b, 0x85, 0xa9, 0x21);


	public const Guid CLSID_DefaultBrowserSyncSettings = .(0x3ac83423, 0x3112, 0x4aa6, 0x9b, 0x5b, 0x1f, 0xeb, 0x23, 0xd0, 0xc5, 0xf9);


}
#endregion

#region COM Types
[CRepr]struct ICameraUIControlEventCallback : IUnknown
{
	public new const Guid IID = .(0x1bfa0c2c, 0xfbcd, 0x4776, 0xbd, 0xa4, 0x88, 0xbf, 0x97, 0x4e, 0x74, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnStartupComplete;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnSuspendComplete;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, PWSTR pszPath) OnItemCaptured;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, PWSTR pszPath) OnItemDeleted;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnClosed;
	}


	public void OnStartupComplete() mut => VT.[Friend]OnStartupComplete(&this);

	public void OnSuspendComplete() mut => VT.[Friend]OnSuspendComplete(&this);

	public void OnItemCaptured(PWSTR pszPath) mut => VT.[Friend]OnItemCaptured(&this, pszPath);

	public void OnItemDeleted(PWSTR pszPath) mut => VT.[Friend]OnItemDeleted(&this, pszPath);

	public void OnClosed() mut => VT.[Friend]OnClosed(&this);
}

[CRepr]struct ICameraUIControl : IUnknown
{
	public new const Guid IID = .(0xb8733adf, 0x3d68, 0x4b8f, 0xbb, 0x08, 0xe2, 0x8a, 0x0b, 0xed, 0x03, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pWindow, CameraUIControlMode mode, CameraUIControlLinearSelectionMode selectionMode, CameraUIControlCaptureMode captureMode, CameraUIControlPhotoFormat photoFormat, CameraUIControlVideoFormat videoFormat, BOOL bHasCloseButton, ICameraUIControlEventCallback* pEventCallback) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbDeferralRequired) Suspend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CameraUIControlViewType* pViewType) GetCurrentViewType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrActiveItemPath) GetActiveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** ppSelectedItemPaths) GetSelectedItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) RemoveCapturedItem;
	}


	public HRESULT Show(IUnknown* pWindow, CameraUIControlMode mode, CameraUIControlLinearSelectionMode selectionMode, CameraUIControlCaptureMode captureMode, CameraUIControlPhotoFormat photoFormat, CameraUIControlVideoFormat videoFormat, BOOL bHasCloseButton, ICameraUIControlEventCallback* pEventCallback) mut => VT.[Friend]Show(&this, pWindow, mode, selectionMode, captureMode, photoFormat, videoFormat, bHasCloseButton, pEventCallback);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Suspend(BOOL* pbDeferralRequired) mut => VT.[Friend]Suspend(&this, pbDeferralRequired);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT GetCurrentViewType(CameraUIControlViewType* pViewType) mut => VT.[Friend]GetCurrentViewType(&this, pViewType);

	public HRESULT GetActiveItem(BSTR* pbstrActiveItemPath) mut => VT.[Friend]GetActiveItem(&this, pbstrActiveItemPath);

	public HRESULT GetSelectedItems(SAFEARRAY** ppSelectedItemPaths) mut => VT.[Friend]GetSelectedItems(&this, ppSelectedItemPaths);

	public HRESULT RemoveCapturedItem(PWSTR pszPath) mut => VT.[Friend]RemoveCapturedItem(&this, pszPath);
}

[CRepr]struct IEditionUpgradeHelper : IUnknown
{
	public new const Guid IID = .(0xd3e9e342, 0x5deb, 0x43b6, 0x84, 0x9e, 0x69, 0x13, 0xb8, 0x5d, 0x50, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isAllowed) CanUpgrade;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR contentId) UpdateOperatingSystem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowProductKeyUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* contentId) GetOsProductContentId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isGenuine) GetGenuineLocalStatus;
	}


	public HRESULT CanUpgrade(BOOL* isAllowed) mut => VT.[Friend]CanUpgrade(&this, isAllowed);

	public HRESULT UpdateOperatingSystem(PWSTR contentId) mut => VT.[Friend]UpdateOperatingSystem(&this, contentId);

	public HRESULT ShowProductKeyUI() mut => VT.[Friend]ShowProductKeyUI(&this);

	public HRESULT GetOsProductContentId(PWSTR* contentId) mut => VT.[Friend]GetOsProductContentId(&this, contentId);

	public HRESULT GetGenuineLocalStatus(BOOL* isGenuine) mut => VT.[Friend]GetGenuineLocalStatus(&this, isGenuine);
}

[CRepr]struct IWindowsLockModeHelper : IUnknown
{
	public new const Guid IID = .(0xf342d19e, 0xcc22, 0x4648, 0xbb, 0x5d, 0x03, 0xcc, 0xf7, 0x5b, 0x47, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isSmode) GetSMode;
	}


	public HRESULT GetSMode(BOOL* isSmode) mut => VT.[Friend]GetSMode(&this, isSmode);
}

[CRepr]struct IEditionUpgradeBroker : IUnknown
{
	public new const Guid IID = .(0xff19cbcf, 0x9455, 0x4937, 0xb8, 0x72, 0x6b, 0x79, 0x29, 0xa4, 0x60, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 parentHandle) InitializeParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR parameter) UpdateOperatingSystem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowProductKeyUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CanUpgrade;
	}


	public HRESULT InitializeParentWindow(uint32 parentHandle) mut => VT.[Friend]InitializeParentWindow(&this, parentHandle);

	public HRESULT UpdateOperatingSystem(BSTR parameter) mut => VT.[Friend]UpdateOperatingSystem(&this, parameter);

	public HRESULT ShowProductKeyUI() mut => VT.[Friend]ShowProductKeyUI(&this);

	public HRESULT CanUpgrade() mut => VT.[Friend]CanUpgrade(&this);
}

[CRepr]struct IContainerActivationHelper : IUnknown
{
	public new const Guid IID = .(0xb524f93f, 0x80d5, 0x4ec7, 0xae, 0x9e, 0xd6, 0x6e, 0x93, 0xad, 0xe1, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* isAllowed) CanActivateClientVM;
	}


	public HRESULT CanActivateClientVM(int16* isAllowed) mut => VT.[Friend]CanActivateClientVM(&this, isAllowed);
}

[CRepr]struct IClipServiceNotificationHelper : IUnknown
{
	public new const Guid IID = .(0xc39948f0, 0x6142, 0x44fd, 0x98, 0xca, 0xe1, 0x68, 0x1a, 0x8d, 0x68, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR titleText, BSTR bodyText, BSTR packageName, BSTR appId, BSTR launchCommand) ShowToast;
	}


	public HRESULT ShowToast(BSTR titleText, BSTR bodyText, BSTR packageName, BSTR appId, BSTR launchCommand) mut => VT.[Friend]ShowToast(&this, titleText, bodyText, packageName, appId, launchCommand);
}

[CRepr]struct IDefaultBrowserSyncSettings : IUnknown
{
	public new const Guid IID = .(0x7a27faad, 0x5ae6, 0x4255, 0x90, 0x30, 0xc5, 0x30, 0x93, 0x62, 0x92, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsEnabled;
	}


	public BOOL IsEnabled() mut => VT.[Friend]IsEnabled(&this);
}

[CRepr]struct IDeleteBrowsingHistory : IUnknown
{
	public new const Guid IID = .(0xcf38ed4b, 0x2be7, 0x4461, 0x8b, 0x5e, 0x9a, 0x46, 0x6d, 0xc8, 0x2a, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) DeleteBrowsingHistory;
	}


	public HRESULT DeleteBrowsingHistory(uint32 dwFlags) mut => VT.[Friend]DeleteBrowsingHistory(&this, dwFlags);
}

#endregion

#region Functions
public static
{
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uaw_lstrcmpW(uint16* String1, uint16* String2);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uaw_lstrcmpiW(uint16* String1, uint16* String2);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uaw_lstrlenW(uint16* String);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* uaw_wcschr(uint16* String, char16 Character);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* uaw_wcscpy(uint16* Destination, uint16* Source);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uaw_wcsicmp(uint16* String1, uint16* String2);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint uaw_wcslen(uint16* String);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* uaw_wcsrchr(uint16* String, char16 Character);

#endif
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint RtlGetReturnAddressHijackTarget();

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlRaiseCustomSystemEventTrigger(CUSTOM_SYSTEM_EVENT_TRIGGER_CONFIG* TriggerConfig);

	[Import("api-ms-win-core-apiquery-l2-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsApiSetImplemented(PSTR Contract);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryThreadCycleTime(HANDLE ThreadHandle, uint64* CycleTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryProcessCycleTime(HANDLE ProcessHandle, uint64* CycleTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryIdleProcessorCycleTime(uint32* BufferLength, uint64* ProcessorIdleCycleTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryIdleProcessorCycleTimeEx(uint16 Group, uint32* BufferLength, uint64* ProcessorIdleCycleTime);

	[Import("api-ms-win-core-realtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void QueryInterruptTimePrecise(uint64* lpInterruptTimePrecise);

	[Import("api-ms-win-core-realtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void QueryUnbiasedInterruptTimePrecise(uint64* lpUnbiasedInterruptTimePrecise);

	[Import("api-ms-win-core-realtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void QueryInterruptTime(uint64* lpInterruptTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryUnbiasedInterruptTime(uint64* UnbiasedTime);

	[Import("api-ms-win-core-realtime-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryAuxiliaryCounterFrequency(uint64* lpAuxiliaryCounterFrequency);

	[Import("api-ms-win-core-realtime-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ConvertAuxiliaryCounterToPerformanceCounter(uint64 ullAuxiliaryCounterValue, uint64* lpPerformanceCounterValue, uint64* lpConversionError);

	[Import("api-ms-win-core-realtime-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ConvertPerformanceCounterToAuxiliaryCounter(uint64 ullPerformanceCounterValue, uint64* lpAuxiliaryCounterValue, uint64* lpConversionError);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint GlobalCompact(uint32 dwMinFree);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GlobalFix(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GlobalUnfix(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* GlobalWire(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GlobalUnWire(int hMem);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint LocalShrink(int hMem, uint32 cbNewSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint LocalCompact(uint32 uMinFree);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEnvironmentStringsA(PSTR NewEnvironment);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetHandleCount(uint32 uNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RequestDeviceWakeup(HANDLE hDevice);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelDeviceWakeupRequest(HANDLE hDevice);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetMessageWaitingIndicator(HANDLE hMsgIndicator, uint32 ulMsgCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 MulDiv(int32 nNumber, int32 nNumerator, int32 nDenominator);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemRegistryQuota(uint32* pdwQuotaAllowed, uint32* pdwQuotaUsed);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FileTimeToDosDateTime(FILETIME* lpFileTime, uint16* lpFatDate, uint16* lpFatTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DosDateTimeToFileTime(uint16 wFatDate, uint16 wFatTime, FILETIME* lpFileTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 _lopen(PSTR lpPathName, int32 iReadWrite);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 _lcreat(PSTR lpPathName, int32 iAttribute);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 _lread(int32 hFile, void* lpBuffer, uint32 uBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 _lwrite(int32 hFile, PSTR lpBuffer, uint32 uBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 _hread(int32 hFile, void* lpBuffer, int32 lBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 _hwrite(int32 hFile, PSTR lpBuffer, int32 lBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 _lclose(int32 hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 _llseek(int32 hFile, int32 lOffset, int32 iOrigin);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SignalObjectAndWait(HANDLE hObjectToSignal, HANDLE hObjectToWaitOn, uint32 dwMilliseconds, BOOL bAlertable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenMutexA(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenSemaphoreA(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateWaitableTimerA(SECURITY_ATTRIBUTES* lpTimerAttributes, BOOL bManualReset, PSTR lpTimerName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenWaitableTimerA(uint32 dwDesiredAccess, BOOL bInheritHandle, PSTR lpTimerName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateWaitableTimerExA(SECURITY_ATTRIBUTES* lpTimerAttributes, PSTR lpTimerName, uint32 dwFlags, uint32 dwDesiredAccess);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFirmwareEnvironmentVariableA(PSTR lpName, PSTR lpGuid, void* pBuffer, uint32 nSize);
	public static uint32 GetFirmwareEnvironmentVariable(PSTR lpName, PSTR lpGuid, void* pBuffer, uint32 nSize) => GetFirmwareEnvironmentVariableA(lpName, lpGuid, pBuffer, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFirmwareEnvironmentVariableW(PWSTR lpName, PWSTR lpGuid, void* pBuffer, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFirmwareEnvironmentVariableExA(PSTR lpName, PSTR lpGuid, void* pBuffer, uint32 nSize, uint32* pdwAttribubutes);
	public static uint32 GetFirmwareEnvironmentVariableEx(PSTR lpName, PSTR lpGuid, void* pBuffer, uint32 nSize, uint32* pdwAttribubutes) => GetFirmwareEnvironmentVariableExA(lpName, lpGuid, pBuffer, nSize, pdwAttribubutes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFirmwareEnvironmentVariableExW(PWSTR lpName, PWSTR lpGuid, void* pBuffer, uint32 nSize, uint32* pdwAttribubutes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFirmwareEnvironmentVariableA(PSTR lpName, PSTR lpGuid, void* pValue, uint32 nSize);
	public static BOOL SetFirmwareEnvironmentVariable(PSTR lpName, PSTR lpGuid, void* pValue, uint32 nSize) => SetFirmwareEnvironmentVariableA(lpName, lpGuid, pValue, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFirmwareEnvironmentVariableW(PWSTR lpName, PWSTR lpGuid, void* pValue, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFirmwareEnvironmentVariableExA(PSTR lpName, PSTR lpGuid, void* pValue, uint32 nSize, uint32 dwAttributes);
	public static BOOL SetFirmwareEnvironmentVariableEx(PSTR lpName, PSTR lpGuid, void* pValue, uint32 nSize, uint32 dwAttributes) => SetFirmwareEnvironmentVariableExA(lpName, lpGuid, pValue, nSize, dwAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFirmwareEnvironmentVariableExW(PWSTR lpName, PWSTR lpGuid, void* pValue, uint32 nSize, uint32 dwAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsNativeVhdBoot(BOOL* NativeVhdBoot);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProfileIntA(PSTR lpAppName, PSTR lpKeyName, int32 nDefault);
	public static uint32 GetProfileInt(PSTR lpAppName, PSTR lpKeyName, int32 nDefault) => GetProfileIntA(lpAppName, lpKeyName, nDefault);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProfileIntW(PWSTR lpAppName, PWSTR lpKeyName, int32 nDefault);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProfileStringA(PSTR lpAppName, PSTR lpKeyName, PSTR lpDefault, uint8* lpReturnedString, uint32 nSize);
	public static uint32 GetProfileString(PSTR lpAppName, PSTR lpKeyName, PSTR lpDefault, uint8* lpReturnedString, uint32 nSize) => GetProfileStringA(lpAppName, lpKeyName, lpDefault, lpReturnedString, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProfileStringW(PWSTR lpAppName, PWSTR lpKeyName, PWSTR lpDefault, char16* lpReturnedString, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteProfileStringA(PSTR lpAppName, PSTR lpKeyName, PSTR lpString);
	public static BOOL WriteProfileString(PSTR lpAppName, PSTR lpKeyName, PSTR lpString) => WriteProfileStringA(lpAppName, lpKeyName, lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteProfileStringW(PWSTR lpAppName, PWSTR lpKeyName, PWSTR lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProfileSectionA(PSTR lpAppName, uint8* lpReturnedString, uint32 nSize);
	public static uint32 GetProfileSection(PSTR lpAppName, uint8* lpReturnedString, uint32 nSize) => GetProfileSectionA(lpAppName, lpReturnedString, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetProfileSectionW(PWSTR lpAppName, char16* lpReturnedString, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteProfileSectionA(PSTR lpAppName, PSTR lpString);
	public static BOOL WriteProfileSection(PSTR lpAppName, PSTR lpString) => WriteProfileSectionA(lpAppName, lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteProfileSectionW(PWSTR lpAppName, PWSTR lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileIntA(PSTR lpAppName, PSTR lpKeyName, int32 nDefault, PSTR lpFileName);
	public static uint32 GetPrivateProfileInt(PSTR lpAppName, PSTR lpKeyName, int32 nDefault, PSTR lpFileName) => GetPrivateProfileIntA(lpAppName, lpKeyName, nDefault, lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileIntW(PWSTR lpAppName, PWSTR lpKeyName, int32 nDefault, PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileStringA(PSTR lpAppName, PSTR lpKeyName, PSTR lpDefault, uint8* lpReturnedString, uint32 nSize, PSTR lpFileName);
	public static uint32 GetPrivateProfileString(PSTR lpAppName, PSTR lpKeyName, PSTR lpDefault, uint8* lpReturnedString, uint32 nSize, PSTR lpFileName) => GetPrivateProfileStringA(lpAppName, lpKeyName, lpDefault, lpReturnedString, nSize, lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileStringW(PWSTR lpAppName, PWSTR lpKeyName, PWSTR lpDefault, char16* lpReturnedString, uint32 nSize, PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrivateProfileStringA(PSTR lpAppName, PSTR lpKeyName, PSTR lpString, PSTR lpFileName);
	public static BOOL WritePrivateProfileString(PSTR lpAppName, PSTR lpKeyName, PSTR lpString, PSTR lpFileName) => WritePrivateProfileStringA(lpAppName, lpKeyName, lpString, lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrivateProfileStringW(PWSTR lpAppName, PWSTR lpKeyName, PWSTR lpString, PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileSectionA(PSTR lpAppName, uint8* lpReturnedString, uint32 nSize, PSTR lpFileName);
	public static uint32 GetPrivateProfileSection(PSTR lpAppName, uint8* lpReturnedString, uint32 nSize, PSTR lpFileName) => GetPrivateProfileSectionA(lpAppName, lpReturnedString, nSize, lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileSectionW(PWSTR lpAppName, char16* lpReturnedString, uint32 nSize, PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrivateProfileSectionA(PSTR lpAppName, PSTR lpString, PSTR lpFileName);
	public static BOOL WritePrivateProfileSection(PSTR lpAppName, PSTR lpString, PSTR lpFileName) => WritePrivateProfileSectionA(lpAppName, lpString, lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrivateProfileSectionW(PWSTR lpAppName, PWSTR lpString, PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileSectionNamesA(uint8* lpszReturnBuffer, uint32 nSize, PSTR lpFileName);
	public static uint32 GetPrivateProfileSectionNames(uint8* lpszReturnBuffer, uint32 nSize, PSTR lpFileName) => GetPrivateProfileSectionNamesA(lpszReturnBuffer, nSize, lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetPrivateProfileSectionNamesW(char16* lpszReturnBuffer, uint32 nSize, PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrivateProfileStructA(PSTR lpszSection, PSTR lpszKey, void* lpStruct, uint32 uSizeStruct, PSTR szFile);
	public static BOOL GetPrivateProfileStruct(PSTR lpszSection, PSTR lpszKey, void* lpStruct, uint32 uSizeStruct, PSTR szFile) => GetPrivateProfileStructA(lpszSection, lpszKey, lpStruct, uSizeStruct, szFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrivateProfileStructW(PWSTR lpszSection, PWSTR lpszKey, void* lpStruct, uint32 uSizeStruct, PWSTR szFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrivateProfileStructA(PSTR lpszSection, PSTR lpszKey, void* lpStruct, uint32 uSizeStruct, PSTR szFile);
	public static BOOL WritePrivateProfileStruct(PSTR lpszSection, PSTR lpszKey, void* lpStruct, uint32 uSizeStruct, PSTR szFile) => WritePrivateProfileStructA(lpszSection, lpszKey, lpStruct, uSizeStruct, szFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WritePrivateProfileStructW(PWSTR lpszSection, PWSTR lpszKey, void* lpStruct, uint32 uSizeStruct, PWSTR szFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadHugeReadPtr(void* lp, uint ucb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsBadHugeWritePtr(void* lp, uint ucb);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetComputerNameA(uint8* lpBuffer, uint32* nSize);
	public static BOOL GetComputerName(uint8* lpBuffer, uint32* nSize) => GetComputerNameA(lpBuffer, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetComputerNameW(char16* lpBuffer, uint32* nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsHostnameToComputerNameA(PSTR Hostname, uint8* ComputerName, uint32* nSize);
	public static BOOL DnsHostnameToComputerName(PSTR Hostname, uint8* ComputerName, uint32* nSize) => DnsHostnameToComputerNameA(Hostname, ComputerName, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsHostnameToComputerNameW(PWSTR Hostname, char16* ComputerName, uint32* nSize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserNameA(uint8* lpBuffer, uint32* pcbBuffer);
	public static BOOL GetUserName(uint8* lpBuffer, uint32* pcbBuffer) => GetUserNameA(lpBuffer, pcbBuffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserNameW(char16* lpBuffer, uint32* pcbBuffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsTokenUntrusted(HANDLE TokenHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelTimerQueueTimer(HANDLE TimerQueue, HANDLE Timer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentHwProfileA(HW_PROFILE_INFOA* lpHwProfileInfo);
	public static BOOL GetCurrentHwProfile(HW_PROFILE_INFOA* lpHwProfileInfo) => GetCurrentHwProfileA(lpHwProfileInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentHwProfileW(HW_PROFILE_INFOW* lpHwProfileInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReplacePartitionUnit(PWSTR TargetPartition, PWSTR SparePartition, uint32 Flags);

#if BF_32_BIT || BF_64_BIT
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 GetThreadEnabledXStateFeatures();

#endif
#if BF_32_BIT || BF_64_BIT
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnableProcessOptionalXStateFeatures(uint64 Features);

#endif
	[Import("api-ms-win-core-backgroundtask-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RaiseCustomSystemEventTrigger(CUSTOM_SYSTEM_EVENT_TRIGGER_CONFIG* CustomSystemEventTriggerConfig);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtClose(HANDLE Handle);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtOpenFile(HANDLE* FileHandle, uint32 DesiredAccess, OBJECT_ATTRIBUTES* ObjectAttributes, IO_STATUS_BLOCK* IoStatusBlock, uint32 ShareAccess, uint32 OpenOptions);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtRenameKey(HANDLE KeyHandle, UNICODE_STRING* NewName);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtNotifyChangeMultipleKeys(HANDLE MasterKeyHandle, uint32 Count, OBJECT_ATTRIBUTES* SubordinateObjects, HANDLE Event, PIO_APC_ROUTINE ApcRoutine, void* ApcContext, IO_STATUS_BLOCK* IoStatusBlock, uint32 CompletionFilter, BOOLEAN WatchTree, void* Buffer, uint32 BufferSize, BOOLEAN Asynchronous);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQueryMultipleValueKey(HANDLE KeyHandle, KEY_VALUE_ENTRY* ValueEntries, uint32 EntryCount, void* ValueBuffer, uint32* BufferLength, uint32* RequiredBufferLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtSetInformationKey(HANDLE KeyHandle, KEY_SET_INFORMATION_CLASS KeySetInformationClass, void* KeySetInformation, uint32 KeySetInformationLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtDeviceIoControlFile(HANDLE FileHandle, HANDLE Event, PIO_APC_ROUTINE ApcRoutine, void* ApcContext, IO_STATUS_BLOCK* IoStatusBlock, uint32 IoControlCode, void* InputBuffer, uint32 InputBufferLength, void* OutputBuffer, uint32 OutputBufferLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtWaitForSingleObject(HANDLE Handle, BOOLEAN Alertable, LARGE_INTEGER* Timeout);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN RtlIsNameLegalDOS8Dot3(UNICODE_STRING* Name, STRING* OemName, BOOLEAN* NameContainsSpaces);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQueryObject(HANDLE Handle, OBJECT_INFORMATION_CLASS ObjectInformationClass, void* ObjectInformation, uint32 ObjectInformationLength, uint32* ReturnLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQuerySystemInformation(SYSTEM_INFORMATION_CLASS SystemInformationClass, void* SystemInformation, uint32 SystemInformationLength, uint32* ReturnLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQuerySystemTime(LARGE_INTEGER* SystemTime);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtQueryTimerResolution(uint32* MaximumTime, uint32* MinimumTime, uint32* CurrentTime);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlLocalTimeToSystemTime(LARGE_INTEGER* LocalTime, LARGE_INTEGER* SystemTime);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN RtlTimeToSecondsSince1970(LARGE_INTEGER* Time, uint32* ElapsedSeconds);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlFreeAnsiString(STRING* AnsiString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlFreeUnicodeString(UNICODE_STRING* UnicodeString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlFreeOemString(STRING* OemString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlInitString(STRING* DestinationString, int8* SourceString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlInitStringEx(STRING* DestinationString, int8* SourceString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlInitAnsiString(STRING* DestinationString, int8* SourceString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlInitAnsiStringEx(STRING* DestinationString, int8* SourceString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlInitUnicodeString(UNICODE_STRING* DestinationString, PWSTR SourceString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlAnsiStringToUnicodeString(UNICODE_STRING* DestinationString, STRING* SourceString, BOOLEAN AllocateDestinationString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlUnicodeStringToAnsiString(STRING* DestinationString, UNICODE_STRING* SourceString, BOOLEAN AllocateDestinationString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlUnicodeStringToOemString(STRING* DestinationString, UNICODE_STRING* SourceString, BOOLEAN AllocateDestinationString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlUnicodeToMultiByteSize(uint32* BytesInMultiByteString, PWSTR UnicodeString, uint32 BytesInUnicodeString);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlCharToInteger(int8* String, uint32 Base, uint32* Value);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlUniform(uint32* Seed);

	[Import("api-ms-win-core-featurestaging-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FEATURE_ENABLED_STATE GetFeatureEnabledState(uint32 featureId, FEATURE_CHANGE_TIME changeTime);

	[Import("api-ms-win-core-featurestaging-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RecordFeatureUsage(uint32 featureId, uint32 kind, uint32 addend, PSTR originName);

	[Import("api-ms-win-core-featurestaging-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RecordFeatureError(uint32 featureId, FEATURE_ERROR* error);

	[Import("api-ms-win-core-featurestaging-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SubscribeFeatureStateChangeNotification(FEATURE_STATE_CHANGE_SUBSCRIPTION* subscription, PFEATURE_STATE_CHANGE_CALLBACK callback, void* context);

	[Import("api-ms-win-core-featurestaging-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UnsubscribeFeatureStateChangeNotification(FEATURE_STATE_CHANGE_SUBSCRIPTION subscription);

	[Import("api-ms-win-core-featurestaging-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFeatureVariant(uint32 featureId, FEATURE_CHANGE_TIME changeTime, uint32* payloadId, BOOL* hasNotification);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC DCIOpenProvider();

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DCICloseProvider(HDC hdc);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCICreatePrimary(HDC hdc, DCISURFACEINFO** lplpSurface);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCICreateOffscreen(HDC hdc, uint32 dwCompression, uint32 dwRedMask, uint32 dwGreenMask, uint32 dwBlueMask, uint32 dwWidth, uint32 dwHeight, uint32 dwDCICaps, uint32 dwBitCount, DCIOFFSCREEN** lplpSurface);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCICreateOverlay(HDC hdc, void* lpOffscreenSurf, DCIOVERLAY** lplpSurface);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCIEnum(HDC hdc, RECT* lprDst, RECT* lprSrc, void* lpFnCallback, void* lpContext);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCISetSrcDestClip(DCIOFFSCREEN* pdci, RECT* srcrc, RECT* destrc, RGNDATA* prd);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWINWATCH WinWatchOpen(HWND hwnd);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinWatchClose(HWINWATCH hWW);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinWatchGetClipList(HWINWATCH hWW, RECT* prc, uint32 size, RGNDATA* prd);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinWatchDidStatusChange(HWINWATCH hWW);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetWindowRegionData(HWND hwnd, uint32 size, RGNDATA* prd);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDCRegionData(HDC hdc, uint32 size, RGNDATA* prd);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinWatchNotify(HWINWATCH hWW, WINWATCHNOTIFYPROC NotifyCallback, LPARAM NotifyParam);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DCIEndAccess(DCISURFACEINFO* pdci);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCIBeginAccess(DCISURFACEINFO* pdci, int32 x, int32 y, int32 dx, int32 dy);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DCIDestroy(DCISURFACEINFO* pdci);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCIDraw(DCIOFFSCREEN* pdci);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCISetClipList(DCIOFFSCREEN* pdci, RGNDATA* prd);

	[Import("DCIMAN32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DCISetDestination(DCIOFFSCREEN* pdci, RECT* dst, RECT* src);

	[Import("api-ms-win-dx-d3dkmt-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GdiEntry13();

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RunSetupCommandA(HWND hWnd, PSTR szCmdName, PSTR szInfSection, PSTR szDir, PSTR lpszTitle, HANDLE* phEXE, uint32 dwFlags, void* pvReserved);
	public static HRESULT RunSetupCommand(HWND hWnd, PSTR szCmdName, PSTR szInfSection, PSTR szDir, PSTR lpszTitle, HANDLE* phEXE, uint32 dwFlags, void* pvReserved) => RunSetupCommandA(hWnd, szCmdName, szInfSection, szDir, lpszTitle, phEXE, dwFlags, pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RunSetupCommandW(HWND hWnd, PWSTR szCmdName, PWSTR szInfSection, PWSTR szDir, PWSTR lpszTitle, HANDLE* phEXE, uint32 dwFlags, void* pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NeedRebootInit();

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL NeedReboot(uint32 dwRebootCheck);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RebootCheckOnInstallA(HWND hwnd, PSTR pszINF, PSTR pszSec, uint32 dwReserved);
	public static HRESULT RebootCheckOnInstall(HWND hwnd, PSTR pszINF, PSTR pszSec, uint32 dwReserved) => RebootCheckOnInstallA(hwnd, pszINF, pszSec, dwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RebootCheckOnInstallW(HWND hwnd, PWSTR pszINF, PWSTR pszSec, uint32 dwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TranslateInfStringA(PSTR pszInfFilename, PSTR pszInstallSection, PSTR pszTranslateSection, PSTR pszTranslateKey, uint8* pszBuffer, uint32 cchBuffer, uint32* pdwRequiredSize, void* pvReserved);
	public static HRESULT TranslateInfString(PSTR pszInfFilename, PSTR pszInstallSection, PSTR pszTranslateSection, PSTR pszTranslateKey, uint8* pszBuffer, uint32 cchBuffer, uint32* pdwRequiredSize, void* pvReserved) => TranslateInfStringA(pszInfFilename, pszInstallSection, pszTranslateSection, pszTranslateKey, pszBuffer, cchBuffer, pdwRequiredSize, pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TranslateInfStringW(PWSTR pszInfFilename, PWSTR pszInstallSection, PWSTR pszTranslateSection, PWSTR pszTranslateKey, char16* pszBuffer, uint32 cchBuffer, uint32* pdwRequiredSize, void* pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegInstallA(HINSTANCE hmod, PSTR pszSection, STRTABLEA* pstTable);
	public static HRESULT RegInstall(HINSTANCE hmod, PSTR pszSection, STRTABLEA* pstTable) => RegInstallA(hmod, pszSection, pstTable);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegInstallW(HINSTANCE hmod, PWSTR pszSection, STRTABLEW* pstTable);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LaunchINFSectionExW(HWND hwnd, HINSTANCE hInstance, PWSTR pszParms, int32 nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExecuteCabA(HWND hwnd, CABINFOA* pCab, void* pReserved);
	public static HRESULT ExecuteCab(HWND hwnd, CABINFOA* pCab, void* pReserved) => ExecuteCabA(hwnd, pCab, pReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExecuteCabW(HWND hwnd, CABINFOW* pCab, void* pReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AdvInstallFileA(HWND hwnd, PSTR lpszSourceDir, PSTR lpszSourceFile, PSTR lpszDestDir, PSTR lpszDestFile, uint32 dwFlags, uint32 dwReserved);
	public static HRESULT AdvInstallFile(HWND hwnd, PSTR lpszSourceDir, PSTR lpszSourceFile, PSTR lpszDestDir, PSTR lpszDestFile, uint32 dwFlags, uint32 dwReserved) => AdvInstallFileA(hwnd, lpszSourceDir, lpszSourceFile, lpszDestDir, lpszDestFile, dwFlags, dwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AdvInstallFileW(HWND hwnd, PWSTR lpszSourceDir, PWSTR lpszSourceFile, PWSTR lpszDestDir, PWSTR lpszDestFile, uint32 dwFlags, uint32 dwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegSaveRestoreA(HWND hWnd, PSTR pszTitleString, HKEY hkBckupKey, PSTR pcszRootKey, PSTR pcszSubKey, PSTR pcszValueName, uint32 dwFlags);
	public static HRESULT RegSaveRestore(HWND hWnd, PSTR pszTitleString, HKEY hkBckupKey, PSTR pcszRootKey, PSTR pcszSubKey, PSTR pcszValueName, uint32 dwFlags) => RegSaveRestoreA(hWnd, pszTitleString, hkBckupKey, pcszRootKey, pcszSubKey, pcszValueName, dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegSaveRestoreW(HWND hWnd, PWSTR pszTitleString, HKEY hkBckupKey, PWSTR pcszRootKey, PWSTR pcszSubKey, PWSTR pcszValueName, uint32 dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegSaveRestoreOnINFA(HWND hWnd, PSTR pszTitle, PSTR pszINF, PSTR pszSection, HKEY hHKLMBackKey, HKEY hHKCUBackKey, uint32 dwFlags);
	public static HRESULT RegSaveRestoreOnINF(HWND hWnd, PSTR pszTitle, PSTR pszINF, PSTR pszSection, HKEY hHKLMBackKey, HKEY hHKCUBackKey, uint32 dwFlags) => RegSaveRestoreOnINFA(hWnd, pszTitle, pszINF, pszSection, hHKLMBackKey, hHKCUBackKey, dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegSaveRestoreOnINFW(HWND hWnd, PWSTR pszTitle, PWSTR pszINF, PWSTR pszSection, HKEY hHKLMBackKey, HKEY hHKCUBackKey, uint32 dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegRestoreAllA(HWND hWnd, PSTR pszTitleString, HKEY hkBckupKey);
	public static HRESULT RegRestoreAll(HWND hWnd, PSTR pszTitleString, HKEY hkBckupKey) => RegRestoreAllA(hWnd, pszTitleString, hkBckupKey);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegRestoreAllW(HWND hWnd, PWSTR pszTitleString, HKEY hkBckupKey);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FileSaveRestoreW(HWND hDlg, PWSTR lpFileList, PWSTR lpDir, PWSTR lpBaseName, uint32 dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FileSaveRestoreOnINFA(HWND hWnd, PSTR pszTitle, PSTR pszINF, PSTR pszSection, PSTR pszBackupDir, PSTR pszBaseBackupFile, uint32 dwFlags);
	public static HRESULT FileSaveRestoreOnINF(HWND hWnd, PSTR pszTitle, PSTR pszINF, PSTR pszSection, PSTR pszBackupDir, PSTR pszBaseBackupFile, uint32 dwFlags) => FileSaveRestoreOnINFA(hWnd, pszTitle, pszINF, pszSection, pszBackupDir, pszBaseBackupFile, dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FileSaveRestoreOnINFW(HWND hWnd, PWSTR pszTitle, PWSTR pszINF, PWSTR pszSection, PWSTR pszBackupDir, PWSTR pszBaseBackupFile, uint32 dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddDelBackupEntryA(PSTR lpcszFileList, PSTR lpcszBackupDir, PSTR lpcszBaseName, uint32 dwFlags);
	public static HRESULT AddDelBackupEntry(PSTR lpcszFileList, PSTR lpcszBackupDir, PSTR lpcszBaseName, uint32 dwFlags) => AddDelBackupEntryA(lpcszFileList, lpcszBackupDir, lpcszBaseName, dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddDelBackupEntryW(PWSTR lpcszFileList, PWSTR lpcszBackupDir, PWSTR lpcszBaseName, uint32 dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FileSaveMarkNotExistA(PSTR lpFileList, PSTR lpDir, PSTR lpBaseName);
	public static HRESULT FileSaveMarkNotExist(PSTR lpFileList, PSTR lpDir, PSTR lpBaseName) => FileSaveMarkNotExistA(lpFileList, lpDir, lpBaseName);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FileSaveMarkNotExistW(PWSTR lpFileList, PWSTR lpDir, PWSTR lpBaseName);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetVersionFromFileA(PSTR lpszFilename, uint32* pdwMSVer, uint32* pdwLSVer, BOOL bVersion);
	public static HRESULT GetVersionFromFile(PSTR lpszFilename, uint32* pdwMSVer, uint32* pdwLSVer, BOOL bVersion) => GetVersionFromFileA(lpszFilename, pdwMSVer, pdwLSVer, bVersion);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetVersionFromFileW(PWSTR lpszFilename, uint32* pdwMSVer, uint32* pdwLSVer, BOOL bVersion);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetVersionFromFileExA(PSTR lpszFilename, uint32* pdwMSVer, uint32* pdwLSVer, BOOL bVersion);
	public static HRESULT GetVersionFromFileEx(PSTR lpszFilename, uint32* pdwMSVer, uint32* pdwLSVer, BOOL bVersion) => GetVersionFromFileExA(lpszFilename, pdwMSVer, pdwLSVer, bVersion);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetVersionFromFileExW(PWSTR lpszFilename, uint32* pdwMSVer, uint32* pdwLSVer, BOOL bVersion);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsNTAdmin(uint32 dwReserved, uint32* lpdwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DelNodeA(PSTR pszFileOrDirName, uint32 dwFlags);
	public static HRESULT DelNode(PSTR pszFileOrDirName, uint32 dwFlags) => DelNodeA(pszFileOrDirName, dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DelNodeW(PWSTR pszFileOrDirName, uint32 dwFlags);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DelNodeRunDLL32W(HWND hwnd, HINSTANCE hInstance, PWSTR pszParms, int32 nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OpenINFEngineA(PSTR pszInfFilename, PSTR pszInstallSection, uint32 dwFlags, void** phInf, void* pvReserved);
	public static HRESULT OpenINFEngine(PSTR pszInfFilename, PSTR pszInstallSection, uint32 dwFlags, void** phInf, void* pvReserved) => OpenINFEngineA(pszInfFilename, pszInstallSection, dwFlags, phInf, pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OpenINFEngineW(PWSTR pszInfFilename, PWSTR pszInstallSection, uint32 dwFlags, void** phInf, void* pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TranslateInfStringExA(void* hInf, PSTR pszInfFilename, PSTR pszTranslateSection, PSTR pszTranslateKey, uint8* pszBuffer, uint32 dwBufferSize, uint32* pdwRequiredSize, void* pvReserved);
	public static HRESULT TranslateInfStringEx(void* hInf, PSTR pszInfFilename, PSTR pszTranslateSection, PSTR pszTranslateKey, uint8* pszBuffer, uint32 dwBufferSize, uint32* pdwRequiredSize, void* pvReserved) => TranslateInfStringExA(hInf, pszInfFilename, pszTranslateSection, pszTranslateKey, pszBuffer, dwBufferSize, pdwRequiredSize, pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TranslateInfStringExW(void* hInf, PWSTR pszInfFilename, PWSTR pszTranslateSection, PWSTR pszTranslateKey, char16* pszBuffer, uint32 dwBufferSize, uint32* pdwRequiredSize, void* pvReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CloseINFEngine(void* hInf);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExtractFilesA(PSTR pszCabName, PSTR pszExpandDir, uint32 dwFlags, PSTR pszFileList, void* lpReserved, uint32 dwReserved);
	public static HRESULT ExtractFiles(PSTR pszCabName, PSTR pszExpandDir, uint32 dwFlags, PSTR pszFileList, void* lpReserved, uint32 dwReserved) => ExtractFilesA(pszCabName, pszExpandDir, dwFlags, pszFileList, lpReserved, dwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExtractFilesW(PWSTR pszCabName, PWSTR pszExpandDir, uint32 dwFlags, PWSTR pszFileList, void* lpReserved, uint32 dwReserved);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LaunchINFSectionW(HWND hwndOwner, HINSTANCE hInstance, PWSTR pszParams, int32 nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UserInstStubWrapperA(HWND hwnd, HINSTANCE hInstance, PSTR pszParms, int32 nShow);
	public static HRESULT UserInstStubWrapper(HWND hwnd, HINSTANCE hInstance, PSTR pszParms, int32 nShow) => UserInstStubWrapperA(hwnd, hInstance, pszParms, nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UserInstStubWrapperW(HWND hwnd, HINSTANCE hInstance, PWSTR pszParms, int32 nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UserUnInstStubWrapperA(HWND hwnd, HINSTANCE hInstance, PSTR pszParms, int32 nShow);
	public static HRESULT UserUnInstStubWrapper(HWND hwnd, HINSTANCE hInstance, PSTR pszParms, int32 nShow) => UserUnInstStubWrapperA(hwnd, hInstance, pszParms, nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UserUnInstStubWrapperW(HWND hwnd, HINSTANCE hInstance, PWSTR pszParms, int32 nShow);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetPerUserSecValuesA(PERUSERSECTIONA* pPerUser);
	public static HRESULT SetPerUserSecValues(PERUSERSECTIONA* pPerUser) => SetPerUserSecValuesA(pPerUser);

	[Import("ADVPACK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetPerUserSecValuesW(PERUSERSECTIONW* pPerUser);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT SendIMEMessageExA(HWND param0, LPARAM param1);
	public static LRESULT SendIMEMessageEx(HWND param0, LPARAM param1) => SendIMEMessageExA(param0, param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT SendIMEMessageExW(HWND param0, LPARAM param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IMPGetIMEA(HWND param0, IMEPROA* param1);
	public static BOOL IMPGetIME(HWND param0, IMEPROA* param1) => IMPGetIMEA(param0, param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IMPGetIMEW(HWND param0, IMEPROW* param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IMPQueryIMEA(IMEPROA* param0);
	public static BOOL IMPQueryIME(IMEPROA* param0) => IMPQueryIMEA(param0);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IMPQueryIMEW(IMEPROW* param0);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IMPSetIMEA(HWND param0, IMEPROA* param1);
	public static BOOL IMPSetIME(HWND param0, IMEPROA* param1) => IMPSetIMEA(param0, param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IMPSetIMEW(HWND param0, IMEPROW* param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WINNLSGetIMEHotkey(HWND param0);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WINNLSEnableIME(HWND param0, BOOL param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WINNLSGetEnableStatus(HWND param0);

	[Import("APPHELP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ApphelpCheckShellObject(in Guid ObjectCLSID, BOOL bShimIfNecessary, uint64* pullFlags);

	[Import("Wldp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WldpGetLockdownPolicy(WLDP_HOST_INFORMATION* hostInformation, uint32* lockdownState, uint32 lockdownFlags);

	[Import("Wldp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WldpIsClassInApprovedList(in Guid classID, WLDP_HOST_INFORMATION* hostInformation, BOOL* isApproved, uint32 optionalFlags);

	[Import("Wldp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WldpSetDynamicCodeTrust(HANDLE fileHandle);

	[Import("Wldp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WldpIsDynamicCodePolicyEnabled(BOOL* isEnabled);

	[Import("Wldp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WldpQueryDynamicCodeTrust(HANDLE fileHandle, void* baseImage, uint32 imageSize);

	[Import("Wldp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WldpQueryDeviceSecurityInformation(WLDP_DEVICE_SECURITY_INFORMATION* information, uint32 informationLength, uint32* returnLength);

}
#endregion
