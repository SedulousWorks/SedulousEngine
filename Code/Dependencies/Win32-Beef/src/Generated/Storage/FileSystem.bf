using Win32.Foundation;
using Win32.Security;
using Win32.System.Com;
using Win32.System.IO;
using Win32.System.WindowsProgramming;
using System;

namespace Win32.Storage.FileSystem;

#region Constants
public static
{
	public const uint32 MAXIMUM_REPARSE_DATA_BUFFER_SIZE = 16384;
	public const String EA_CONTAINER_NAME = "ContainerName";
	public const String EA_CONTAINER_SIZE = "ContainerSize";
	public const String CLFS_BASELOG_EXTENSION = ".blf";
	public const uint32 CLFS_FLAG_REENTRANT_FILE_SYSTEM = 8;
	public const uint32 CLFS_FLAG_NON_REENTRANT_FILTER = 16;
	public const uint32 CLFS_FLAG_REENTRANT_FILTER = 32;
	public const uint32 CLFS_FLAG_IGNORE_SHARE_ACCESS = 64;
	public const uint32 CLFS_FLAG_READ_IN_PROGRESS = 128;
	public const uint32 CLFS_FLAG_MINIFILTER_LEVEL = 256;
	public const uint32 CLFS_FLAG_HIDDEN_SYSTEM_LOG = 512;
	public const uint32 CLFS_MARSHALLING_FLAG_NONE = 0;
	public const uint32 CLFS_MARSHALLING_FLAG_DISABLE_BUFF_INIT = 1;
	public const uint32 CLFS_FLAG_FILTER_INTERMEDIATE_LEVEL = 16;
	public const uint32 CLFS_FLAG_FILTER_TOP_LEVEL = 32;
	public const String CLFS_CONTAINER_STREAM_PREFIX = "%BLF%:";
	public const String CLFS_CONTAINER_RELATIVE_PREFIX = "%BLF%\\";
	public const uint32 TRANSACTION_MANAGER_VOLATILE = 1;
	public const uint32 TRANSACTION_MANAGER_COMMIT_DEFAULT = 0;
	public const uint32 TRANSACTION_MANAGER_COMMIT_SYSTEM_VOLUME = 2;
	public const uint32 TRANSACTION_MANAGER_COMMIT_SYSTEM_HIVES = 4;
	public const uint32 TRANSACTION_MANAGER_COMMIT_LOWEST = 8;
	public const uint32 TRANSACTION_MANAGER_CORRUPT_FOR_RECOVERY = 16;
	public const uint32 TRANSACTION_MANAGER_CORRUPT_FOR_PROGRESS = 32;
	public const uint32 TRANSACTION_MANAGER_MAXIMUM_OPTION = 63;
	public const uint32 TRANSACTION_DO_NOT_PROMOTE = 1;
	public const uint32 TRANSACTION_MAXIMUM_OPTION = 1;
	public const uint32 RESOURCE_MANAGER_VOLATILE = 1;
	public const uint32 RESOURCE_MANAGER_COMMUNICATION = 2;
	public const uint32 RESOURCE_MANAGER_MAXIMUM_OPTION = 3;
	public const uint32 CRM_PROTOCOL_EXPLICIT_MARSHAL_ONLY = 1;
	public const uint32 CRM_PROTOCOL_DYNAMIC_MARSHAL_INFO = 2;
	public const uint32 CRM_PROTOCOL_MAXIMUM_OPTION = 3;
	public const uint32 ENLISTMENT_SUPERIOR = 1;
	public const uint32 ENLISTMENT_MAXIMUM_OPTION = 1;
	public const uint32 TRANSACTION_NOTIFY_MASK = 1073741823;
	public const uint32 TRANSACTION_NOTIFY_PREPREPARE = 1;
	public const uint32 TRANSACTION_NOTIFY_PREPARE = 2;
	public const uint32 TRANSACTION_NOTIFY_COMMIT = 4;
	public const uint32 TRANSACTION_NOTIFY_ROLLBACK = 8;
	public const uint32 TRANSACTION_NOTIFY_PREPREPARE_COMPLETE = 16;
	public const uint32 TRANSACTION_NOTIFY_PREPARE_COMPLETE = 32;
	public const uint32 TRANSACTION_NOTIFY_COMMIT_COMPLETE = 64;
	public const uint32 TRANSACTION_NOTIFY_ROLLBACK_COMPLETE = 128;
	public const uint32 TRANSACTION_NOTIFY_RECOVER = 256;
	public const uint32 TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT = 512;
	public const uint32 TRANSACTION_NOTIFY_DELEGATE_COMMIT = 1024;
	public const uint32 TRANSACTION_NOTIFY_RECOVER_QUERY = 2048;
	public const uint32 TRANSACTION_NOTIFY_ENLIST_PREPREPARE = 4096;
	public const uint32 TRANSACTION_NOTIFY_LAST_RECOVER = 8192;
	public const uint32 TRANSACTION_NOTIFY_INDOUBT = 16384;
	public const uint32 TRANSACTION_NOTIFY_PROPAGATE_PULL = 32768;
	public const uint32 TRANSACTION_NOTIFY_PROPAGATE_PUSH = 65536;
	public const uint32 TRANSACTION_NOTIFY_MARSHAL = 131072;
	public const uint32 TRANSACTION_NOTIFY_ENLIST_MASK = 262144;
	public const uint32 TRANSACTION_NOTIFY_RM_DISCONNECTED = 16777216;
	public const uint32 TRANSACTION_NOTIFY_TM_ONLINE = 33554432;
	public const uint32 TRANSACTION_NOTIFY_COMMIT_REQUEST = 67108864;
	public const uint32 TRANSACTION_NOTIFY_PROMOTE = 134217728;
	public const uint32 TRANSACTION_NOTIFY_PROMOTE_NEW = 268435456;
	public const uint32 TRANSACTION_NOTIFY_REQUEST_OUTCOME = 536870912;
	public const uint32 TRANSACTION_NOTIFY_COMMIT_FINALIZE = 1073741824;
	public const String TRANSACTIONMANAGER_OBJECT_PATH = "\\TransactionManager\\";
	public const String TRANSACTION_OBJECT_PATH = "\\Transaction\\";
	public const String ENLISTMENT_OBJECT_PATH = "\\Enlistment\\";
	public const String RESOURCE_MANAGER_OBJECT_PATH = "\\ResourceManager\\";
	public const uint32 TRANSACTION_NOTIFICATION_TM_ONLINE_FLAG_IS_CLUSTERED = 1;
	public const uint32 KTM_MARSHAL_BLOB_VERSION_MAJOR = 1;
	public const uint32 KTM_MARSHAL_BLOB_VERSION_MINOR = 1;
	public const uint32 MAX_TRANSACTION_DESCRIPTION_LENGTH = 64;
	public const uint32 MAX_RESOURCEMANAGER_DESCRIPTION_LENGTH = 64;
	public const uint32 IOCTL_VOLUME_BASE = 86;
	public const uint32 IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS = 5636096;
	public const uint32 IOCTL_VOLUME_ONLINE = 5685256;
	public const uint32 IOCTL_VOLUME_OFFLINE = 5685260;
	public const uint32 IOCTL_VOLUME_IS_CLUSTERED = 5636144;
	public const uint32 IOCTL_VOLUME_GET_GPT_ATTRIBUTES = 5636152;
	public const uint32 IOCTL_VOLUME_SUPPORTS_ONLINE_OFFLINE = 5636100;
	public const uint32 IOCTL_VOLUME_IS_OFFLINE = 5636112;
	public const uint32 IOCTL_VOLUME_IS_IO_CAPABLE = 5636116;
	public const uint32 IOCTL_VOLUME_QUERY_FAILOVER_SET = 5636120;
	public const uint32 IOCTL_VOLUME_QUERY_VOLUME_NUMBER = 5636124;
	public const uint32 IOCTL_VOLUME_LOGICAL_TO_PHYSICAL = 5636128;
	public const uint32 IOCTL_VOLUME_PHYSICAL_TO_LOGICAL = 5636132;
	public const uint32 IOCTL_VOLUME_IS_PARTITION = 5636136;
	public const uint32 IOCTL_VOLUME_READ_PLEX = 5652526;
	public const uint32 IOCTL_VOLUME_SET_GPT_ATTRIBUTES = 5636148;
	public const uint32 IOCTL_VOLUME_GET_BC_PROPERTIES = 5652540;
	public const uint32 IOCTL_VOLUME_ALLOCATE_BC_STREAM = 5685312;
	public const uint32 IOCTL_VOLUME_FREE_BC_STREAM = 5685316;
	public const uint32 IOCTL_VOLUME_BC_VERSION = 1;
	public const uint32 IOCTL_VOLUME_IS_DYNAMIC = 5636168;
	public const uint32 IOCTL_VOLUME_PREPARE_FOR_CRITICAL_IO = 5685324;
	public const uint32 IOCTL_VOLUME_QUERY_ALLOCATION_HINT = 5652562;
	public const uint32 IOCTL_VOLUME_UPDATE_PROPERTIES = 5636180;
	public const uint32 IOCTL_VOLUME_QUERY_MINIMUM_SHRINK_SIZE = 5652568;
	public const uint32 IOCTL_VOLUME_PREPARE_FOR_SHRINK = 5685340;
	public const uint32 IOCTL_VOLUME_IS_CSV = 5636192;
	public const uint32 IOCTL_VOLUME_POST_ONLINE = 5685348;
	public const uint32 IOCTL_VOLUME_GET_CSVBLOCKCACHE_CALLBACK = 5685352;
	public const uint32 CSV_BLOCK_CACHE_CALLBACK_VERSION = 1;
	public const uint32 CSV_BLOCK_AND_FILE_CACHE_CALLBACK_VERSION = 2;
	public const Guid PARTITION_BASIC_DATA_GUID = .(0xebd0a0a2, 0xb9e5, 0x4433, 0x87, 0xc0, 0x68, 0xb6, 0xb7, 0x26, 0x99, 0xc7);
	public const Guid PARTITION_BSP_GUID = .(0x57434f53, 0x4df9, 0x45b9, 0x8e, 0x9e, 0x23, 0x70, 0xf0, 0x06, 0x45, 0x7c);
	public const Guid PARTITION_CLUSTER_GUID = .(0xdb97dba9, 0x0840, 0x4bae, 0x97, 0xf0, 0xff, 0xb9, 0xa3, 0x27, 0xc7, 0xe1);
	public const Guid PARTITION_DPP_GUID = .(0x57434f53, 0x94cb, 0x43f0, 0xa5, 0x33, 0xd7, 0x3c, 0x10, 0xcf, 0xa5, 0x7d);
	public const Guid PARTITION_ENTRY_UNUSED_GUID = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid PARTITION_LDM_DATA_GUID = .(0xaf9b60a0, 0x1431, 0x4f62, 0xbc, 0x68, 0x33, 0x11, 0x71, 0x4a, 0x69, 0xad);
	public const Guid PARTITION_LDM_METADATA_GUID = .(0x5808c8aa, 0x7e8f, 0x42e0, 0x85, 0xd2, 0xe1, 0xe9, 0x04, 0x34, 0xcf, 0xb3);
	public const Guid PARTITION_LEGACY_BL_GUID = .(0x424ca0e2, 0x7cb2, 0x4fb9, 0x81, 0x43, 0xc5, 0x2a, 0x99, 0x39, 0x8b, 0xc6);
	public const Guid PARTITION_LEGACY_BL_GUID_BACKUP = .(0x424c3e6c, 0xd79f, 0x49cb, 0x93, 0x5d, 0x36, 0xd7, 0x14, 0x67, 0xa2, 0x88);
	public const Guid PARTITION_MAIN_OS_GUID = .(0x57434f53, 0x8f45, 0x405e, 0x8a, 0x23, 0x18, 0x6d, 0x8a, 0x43, 0x30, 0xd3);
	public const Guid PARTITION_MSFT_RECOVERY_GUID = .(0xde94bba4, 0x06d1, 0x4d40, 0xa1, 0x6a, 0xbf, 0xd5, 0x01, 0x79, 0xd6, 0xac);
	public const Guid PARTITION_MSFT_RESERVED_GUID = .(0xe3c9e316, 0x0b5c, 0x4db8, 0x81, 0x7d, 0xf9, 0x2d, 0xf0, 0x02, 0x15, 0xae);
	public const Guid PARTITION_MSFT_SNAPSHOT_GUID = .(0xcaddebf1, 0x4400, 0x4de8, 0xb1, 0x03, 0x12, 0x11, 0x7d, 0xcf, 0x3c, 0xcf);
	public const Guid PARTITION_OS_DATA_GUID = .(0x57434f53, 0x23f2, 0x44d5, 0xa8, 0x30, 0x67, 0xbb, 0xda, 0xa6, 0x09, 0xf9);
	public const Guid PARTITION_PATCH_GUID = .(0x8967a686, 0x96aa, 0x6aa8, 0x95, 0x89, 0xa8, 0x42, 0x56, 0x54, 0x10, 0x90);
	public const Guid PARTITION_PRE_INSTALLED_GUID = .(0x57434f53, 0x7fe0, 0x4196, 0x9b, 0x42, 0x42, 0x7b, 0x51, 0x64, 0x34, 0x84);
	public const Guid PARTITION_SERVICING_FILES_GUID = .(0x57434f53, 0x432e, 0x4014, 0xae, 0x4c, 0x8d, 0xea, 0xa9, 0xc0, 0x00, 0x6a);
	public const Guid PARTITION_SERVICING_METADATA_GUID = .(0x57434f53, 0xc691, 0x4a05, 0xbb, 0x4e, 0x70, 0x3d, 0xaf, 0xd2, 0x29, 0xce);
	public const Guid PARTITION_SERVICING_RESERVE_GUID = .(0x57434f53, 0x4b81, 0x460b, 0xa3, 0x19, 0xff, 0xb6, 0xfe, 0x13, 0x6d, 0x14);
	public const Guid PARTITION_SERVICING_STAGING_ROOT_GUID = .(0x57434f53, 0xe84d, 0x4e84, 0xaa, 0xf3, 0xec, 0xbb, 0xbd, 0x04, 0xb9, 0xdf);
	public const Guid PARTITION_SPACES_GUID = .(0xe75caf8f, 0xf680, 0x4cee, 0xaf, 0xa3, 0xb0, 0x01, 0xe5, 0x6e, 0xfc, 0x2d);
	public const Guid PARTITION_SPACES_DATA_GUID = .(0xe7addcb4, 0xdc34, 0x4539, 0x9a, 0x76, 0xeb, 0xbd, 0x07, 0xbe, 0x6f, 0x7e);
	public const Guid PARTITION_SYSTEM_GUID = .(0xc12a7328, 0xf81f, 0x11d2, 0xba, 0x4b, 0x00, 0xa0, 0xc9, 0x3e, 0xc9, 0x3b);
	public const Guid PARTITION_WINDOWS_SYSTEM_GUID = .(0x57434f53, 0xe3e3, 0x4631, 0xa5, 0xc5, 0x26, 0xd2, 0x24, 0x38, 0x73, 0xaa);
	public const uint32 _FT_TYPES_DEFINITION_ = 1;
	public const uint32 CLFS_MGMT_POLICY_VERSION = 1;
	public const uint32 LOG_POLICY_OVERWRITE = 1;
	public const uint32 LOG_POLICY_PERSIST = 2;
	public const uint32 CLFS_MGMT_CLIENT_REGISTRATION_VERSION = 1;
	public const Guid CLSID_DiskQuotaControl = .(0x7988b571, 0xec89, 0x11cf, 0x9c, 0x00, 0x00, 0xaa, 0x00, 0xa1, 0x4f, 0x56);
	public const uint32 DISKQUOTA_STATE_DISABLED = 0;
	public const uint32 DISKQUOTA_STATE_TRACK = 1;
	public const uint32 DISKQUOTA_STATE_ENFORCE = 2;
	public const uint32 DISKQUOTA_STATE_MASK = 3;
	public const uint32 DISKQUOTA_FILESTATE_INCOMPLETE = 256;
	public const uint32 DISKQUOTA_FILESTATE_REBUILDING = 512;
	public const uint32 DISKQUOTA_FILESTATE_MASK = 768;
	public const uint32 DISKQUOTA_LOGFLAG_USER_THRESHOLD = 1;
	public const uint32 DISKQUOTA_LOGFLAG_USER_LIMIT = 2;
	public const uint32 DISKQUOTA_USER_ACCOUNT_RESOLVED = 0;
	public const uint32 DISKQUOTA_USER_ACCOUNT_UNAVAILABLE = 1;
	public const uint32 DISKQUOTA_USER_ACCOUNT_DELETED = 2;
	public const uint32 DISKQUOTA_USER_ACCOUNT_INVALID = 3;
	public const uint32 DISKQUOTA_USER_ACCOUNT_UNKNOWN = 4;
	public const uint32 DISKQUOTA_USER_ACCOUNT_UNRESOLVED = 5;
	public const uint32 INVALID_SET_FILE_POINTER = 4294967295;
	public const uint32 INVALID_FILE_ATTRIBUTES = 4294967295;
	public const uint32 SHARE_NETNAME_PARMNUM = 1;
	public const uint32 SHARE_TYPE_PARMNUM = 3;
	public const uint32 SHARE_REMARK_PARMNUM = 4;
	public const uint32 SHARE_PERMISSIONS_PARMNUM = 5;
	public const uint32 SHARE_MAX_USES_PARMNUM = 6;
	public const uint32 SHARE_CURRENT_USES_PARMNUM = 7;
	public const uint32 SHARE_PATH_PARMNUM = 8;
	public const uint32 SHARE_PASSWD_PARMNUM = 9;
	public const uint32 SHARE_FILE_SD_PARMNUM = 501;
	public const uint32 SHARE_SERVER_PARMNUM = 503;
	public const uint32 SHI1_NUM_ELEMENTS = 4;
	public const uint32 SHI2_NUM_ELEMENTS = 10;
	public const uint32 STYPE_RESERVED1 = 16777216;
	public const uint32 STYPE_RESERVED2 = 33554432;
	public const uint32 STYPE_RESERVED3 = 67108864;
	public const uint32 STYPE_RESERVED4 = 134217728;
	public const uint32 STYPE_RESERVED5 = 1048576;
	public const uint32 STYPE_RESERVED_ALL = 1073741568;
	public const uint32 SHI_USES_UNLIMITED = 4294967295;
	public const uint32 SHI1005_FLAGS_DFS = 1;
	public const uint32 SHI1005_FLAGS_DFS_ROOT = 2;
	public const uint32 CSC_MASK_EXT = 8240;
	public const uint32 CSC_MASK = 48;
	public const uint32 CSC_CACHE_MANUAL_REINT = 0;
	public const uint32 CSC_CACHE_AUTO_REINT = 16;
	public const uint32 CSC_CACHE_VDO = 32;
	public const uint32 CSC_CACHE_NONE = 48;
	public const uint32 SHI1005_FLAGS_RESTRICT_EXCLUSIVE_OPENS = 256;
	public const uint32 SHI1005_FLAGS_FORCE_SHARED_DELETE = 512;
	public const uint32 SHI1005_FLAGS_ALLOW_NAMESPACE_CACHING = 1024;
	public const uint32 SHI1005_FLAGS_ACCESS_BASED_DIRECTORY_ENUM = 2048;
	public const uint32 SHI1005_FLAGS_FORCE_LEVELII_OPLOCK = 4096;
	public const uint32 SHI1005_FLAGS_ENABLE_HASH = 8192;
	public const uint32 SHI1005_FLAGS_ENABLE_CA = 16384;
	public const uint32 SHI1005_FLAGS_ENCRYPT_DATA = 32768;
	public const uint32 SHI1005_FLAGS_RESERVED = 65536;
	public const uint32 SHI1005_FLAGS_DISABLE_CLIENT_BUFFERING = 131072;
	public const uint32 SHI1005_FLAGS_IDENTITY_REMOTING = 262144;
	public const uint32 SHI1005_FLAGS_CLUSTER_MANAGED = 524288;
	public const uint32 SHI1005_FLAGS_COMPRESS_DATA = 1048576;
	public const uint32 SESI1_NUM_ELEMENTS = 8;
	public const uint32 SESI2_NUM_ELEMENTS = 9;
	public const uint32 STATSOPT_CLR = 1;
	public const int32 LZERROR_BADINHANDLE = -1;
	public const int32 LZERROR_BADOUTHANDLE = -2;
	public const int32 LZERROR_READ = -3;
	public const int32 LZERROR_WRITE = -4;
	public const int32 LZERROR_GLOBALLOC = -5;
	public const int32 LZERROR_GLOBLOCK = -6;
	public const int32 LZERROR_BADVALUE = -7;
	public const int32 LZERROR_UNKNOWNALG = -8;
	public const uint32 NTMS_OBJECTNAME_LENGTH = 64;
	public const uint32 NTMS_DESCRIPTION_LENGTH = 127;
	public const uint32 NTMS_DEVICENAME_LENGTH = 64;
	public const uint32 NTMS_SERIALNUMBER_LENGTH = 32;
	public const uint32 NTMS_REVISION_LENGTH = 32;
	public const uint32 NTMS_BARCODE_LENGTH = 64;
	public const uint32 NTMS_SEQUENCE_LENGTH = 32;
	public const uint32 NTMS_VENDORNAME_LENGTH = 128;
	public const uint32 NTMS_PRODUCTNAME_LENGTH = 128;
	public const uint32 NTMS_USERNAME_LENGTH = 64;
	public const uint32 NTMS_APPLICATIONNAME_LENGTH = 64;
	public const uint32 NTMS_COMPUTERNAME_LENGTH = 64;
	public const uint32 NTMS_I1_MESSAGE_LENGTH = 127;
	public const uint32 NTMS_MESSAGE_LENGTH = 256;
	public const uint32 NTMS_POOLHIERARCHY_LENGTH = 512;
	public const uint32 NTMS_OMIDLABELID_LENGTH = 255;
	public const uint32 NTMS_OMIDLABELTYPE_LENGTH = 64;
	public const uint32 NTMS_OMIDLABELINFO_LENGTH = 256;
	public const uint32 NTMS_MAXATTR_LENGTH = 65536;
	public const uint32 NTMS_MAXATTR_NAMELEN = 32;
	public const uint32 NTMSMLI_MAXTYPE = 64;
	public const uint32 NTMSMLI_MAXIDSIZE = 256;
	public const uint32 NTMSMLI_MAXAPPDESCR = 256;
	public const uint32 TXF_LOG_RECORD_GENERIC_TYPE_COMMIT = 1;
	public const uint32 TXF_LOG_RECORD_GENERIC_TYPE_ABORT = 2;
	public const uint32 TXF_LOG_RECORD_GENERIC_TYPE_PREPARE = 4;
	public const uint32 TXF_LOG_RECORD_GENERIC_TYPE_DATA = 8;
	public const uint32 VS_VERSION_INFO = 1;
	public const uint32 VS_USER_DEFINED = 100;
	public const int32 VS_FFI_SIGNATURE = -17890115;
	public const int32 VS_FFI_STRUCVERSION = 65536;
	public const int32 VS_FFI_FILEFLAGSMASK = 63;
	public const uint32 WINEFS_SETUSERKEY_SET_CAPABILITIES = 1;
	public const uint32 EFS_COMPATIBILITY_VERSION_NCRYPT_PROTECTOR = 5;
	public const uint32 EFS_COMPATIBILITY_VERSION_PFILE_PROTECTOR = 6;
	public const uint32 EFS_SUBVER_UNKNOWN = 0;
	public const uint32 EFS_EFS_SUBVER_EFS_CERT = 1;
	public const uint32 EFS_PFILE_SUBVER_RMS = 2;
	public const uint32 EFS_PFILE_SUBVER_APPX = 3;
	public const uint32 MAX_SID_SIZE = 256;
	public const uint32 EFS_METADATA_ADD_USER = 1;
	public const uint32 EFS_METADATA_REMOVE_USER = 2;
	public const uint32 EFS_METADATA_REPLACE_USER = 4;
	public const uint32 EFS_METADATA_GENERAL_OP = 8;
	public const uint32 WOF_PROVIDER_WIM = 1;
	public const uint32 WOF_PROVIDER_FILE = 2;
	public const uint32 WIM_PROVIDER_HASH_SIZE = 20;
	public const uint32 WIM_BOOT_OS_WIM = 1;
	public const uint32 WIM_BOOT_NOT_OS_WIM = 0;
	public const uint32 WIM_ENTRY_FLAG_NOT_ACTIVE = 1;
	public const uint32 WIM_ENTRY_FLAG_SUSPENDED = 2;
	public const uint32 WIM_EXTERNAL_FILE_INFO_FLAG_NOT_ACTIVE = 1;
	public const uint32 WIM_EXTERNAL_FILE_INFO_FLAG_SUSPENDED = 2;
	public const uint32 FILE_PROVIDER_COMPRESSION_XPRESS4K = 0;
	public const uint32 FILE_PROVIDER_COMPRESSION_LZX = 1;
	public const uint32 FILE_PROVIDER_COMPRESSION_XPRESS8K = 2;
	public const uint32 FILE_PROVIDER_COMPRESSION_XPRESS16K = 3;
	public const uint8 ClfsNullRecord = 0;
	public const uint8 ClfsDataRecord = 1;
	public const uint8 ClfsRestartRecord = 2;
	public const uint8 ClfsClientRecord = 3;
	public const uint32 ClsContainerInitializing = 1;
	public const uint32 ClsContainerInactive = 2;
	public const uint32 ClsContainerActive = 4;
	public const uint32 ClsContainerActivePendingDelete = 8;
	public const uint32 ClsContainerPendingArchive = 16;
	public const uint32 ClsContainerPendingArchiveAndDelete = 32;
	public const uint32 ClfsContainerInitializing = 1;
	public const uint32 ClfsContainerInactive = 2;
	public const uint32 ClfsContainerActive = 4;
	public const uint32 ClfsContainerActivePendingDelete = 8;
	public const uint32 ClfsContainerPendingArchive = 16;
	public const uint32 ClfsContainerPendingArchiveAndDelete = 32;
	public const uint32 CLFS_MAX_CONTAINER_INFO = 256;
	public const uint8 CLFS_SCAN_INIT = 1;
	public const uint8 CLFS_SCAN_FORWARD = 2;
	public const uint8 CLFS_SCAN_BACKWARD = 4;
	public const uint8 CLFS_SCAN_CLOSE = 8;
	public const uint8 CLFS_SCAN_INITIALIZED = 16;
	public const uint8 CLFS_SCAN_BUFFERED = 32;
}
#endregion

#region TypeDefs
typealias FindFileHandle = int;

typealias FindFileNameHandle = int;

typealias FindStreamHandle = int;

typealias FindChangeNotificationHandle = int;

typealias FindVolumeHandle = int;

typealias FindVolumeMointPointHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum FIND_FIRST_EX_FLAGS : uint32
{
	FIND_FIRST_EX_CASE_SENSITIVE = 1,
	FIND_FIRST_EX_LARGE_FETCH = 2,
	FIND_FIRST_EX_ON_DISK_ENTRIES_ONLY = 4,
}


[AllowDuplicates]
public enum DEFINE_DOS_DEVICE_FLAGS : uint32
{
	DDD_RAW_TARGET_PATH = 1,
	DDD_REMOVE_DEFINITION = 2,
	DDD_EXACT_MATCH_ON_REMOVE = 4,
	DDD_NO_BROADCAST_SYSTEM = 8,
	DDD_LUID_BROADCAST_DRIVE = 16,
}


[AllowDuplicates]
public enum FILE_FLAGS_AND_ATTRIBUTES : uint32
{
	FILE_ATTRIBUTE_READONLY = 1,
	FILE_ATTRIBUTE_HIDDEN = 2,
	FILE_ATTRIBUTE_SYSTEM = 4,
	FILE_ATTRIBUTE_DIRECTORY = 16,
	FILE_ATTRIBUTE_ARCHIVE = 32,
	FILE_ATTRIBUTE_DEVICE = 64,
	FILE_ATTRIBUTE_NORMAL = 128,
	FILE_ATTRIBUTE_TEMPORARY = 256,
	FILE_ATTRIBUTE_SPARSE_FILE = 512,
	FILE_ATTRIBUTE_REPARSE_POINT = 1024,
	FILE_ATTRIBUTE_COMPRESSED = 2048,
	FILE_ATTRIBUTE_OFFLINE = 4096,
	FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 8192,
	FILE_ATTRIBUTE_ENCRYPTED = 16384,
	FILE_ATTRIBUTE_INTEGRITY_STREAM = 32768,
	FILE_ATTRIBUTE_VIRTUAL = 65536,
	FILE_ATTRIBUTE_NO_SCRUB_DATA = 131072,
	FILE_ATTRIBUTE_EA = 262144,
	FILE_ATTRIBUTE_PINNED = 524288,
	FILE_ATTRIBUTE_UNPINNED = 1048576,
	FILE_ATTRIBUTE_RECALL_ON_OPEN = 262144,
	FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS = 4194304,
	FILE_FLAG_WRITE_THROUGH = 2147483648,
	FILE_FLAG_OVERLAPPED = 1073741824,
	FILE_FLAG_NO_BUFFERING = 536870912,
	FILE_FLAG_RANDOM_ACCESS = 268435456,
	FILE_FLAG_SEQUENTIAL_SCAN = 134217728,
	FILE_FLAG_DELETE_ON_CLOSE = 67108864,
	FILE_FLAG_BACKUP_SEMANTICS = 33554432,
	FILE_FLAG_POSIX_SEMANTICS = 16777216,
	FILE_FLAG_SESSION_AWARE = 8388608,
	FILE_FLAG_OPEN_REPARSE_POINT = 2097152,
	FILE_FLAG_OPEN_NO_RECALL = 1048576,
	FILE_FLAG_FIRST_PIPE_INSTANCE = 524288,
	PIPE_ACCESS_DUPLEX = 3,
	PIPE_ACCESS_INBOUND = 1,
	PIPE_ACCESS_OUTBOUND = 2,
	SECURITY_ANONYMOUS = 0,
	SECURITY_IDENTIFICATION = 65536,
	SECURITY_IMPERSONATION = 131072,
	SECURITY_DELEGATION = 196608,
	SECURITY_CONTEXT_TRACKING = 262144,
	SECURITY_EFFECTIVE_ONLY = 524288,
	SECURITY_SQOS_PRESENT = 1048576,
	SECURITY_VALID_SQOS_FLAGS = 2031616,
}


[AllowDuplicates]
public enum FILE_ACCESS_FLAGS : uint32
{
	FILE_READ_DATA = 1,
	FILE_LIST_DIRECTORY = 1,
	FILE_WRITE_DATA = 2,
	FILE_ADD_FILE = 2,
	FILE_APPEND_DATA = 4,
	FILE_ADD_SUBDIRECTORY = 4,
	FILE_CREATE_PIPE_INSTANCE = 4,
	FILE_READ_EA = 8,
	FILE_WRITE_EA = 16,
	FILE_EXECUTE = 32,
	FILE_TRAVERSE = 32,
	FILE_DELETE_CHILD = 64,
	FILE_READ_ATTRIBUTES = 128,
	FILE_WRITE_ATTRIBUTES = 256,
	DELETE = 65536,
	READ_CONTROL = 131072,
	WRITE_DAC = 262144,
	WRITE_OWNER = 524288,
	SYNCHRONIZE = 1048576,
	STANDARD_RIGHTS_REQUIRED = 983040,
	STANDARD_RIGHTS_READ = 131072,
	STANDARD_RIGHTS_WRITE = 131072,
	STANDARD_RIGHTS_EXECUTE = 131072,
	STANDARD_RIGHTS_ALL = 2031616,
	SPECIFIC_RIGHTS_ALL = 65535,
	FILE_ALL_ACCESS = 2032127,
	FILE_GENERIC_READ = 1179785,
	FILE_GENERIC_WRITE = 1179926,
	FILE_GENERIC_EXECUTE = 1179808,
}


[AllowDuplicates]
public enum GET_FILE_VERSION_INFO_FLAGS : uint32
{
	FILE_VER_GET_LOCALISED = 1,
	FILE_VER_GET_NEUTRAL = 2,
	FILE_VER_GET_PREFETCHED = 4,
}


[AllowDuplicates]
public enum VER_FIND_FILE_FLAGS : uint32
{
	VFFF_ISSHAREDFILE = 1,
}


[AllowDuplicates]
public enum VER_FIND_FILE_STATUS : uint32
{
	VFF_CURNEDEST = 1,
	VFF_FILEINUSE = 2,
	VFF_BUFFTOOSMALL = 4,
}


[AllowDuplicates]
public enum VER_INSTALL_FILE_FLAGS : uint32
{
	VIFF_FORCEINSTALL = 1,
	VIFF_DONTDELETEOLD = 2,
}


[AllowDuplicates]
public enum VER_INSTALL_FILE_STATUS : uint32
{
	VIF_TEMPFILE = 1,
	VIF_MISMATCH = 2,
	VIF_SRCOLD = 4,
	VIF_DIFFLANG = 8,
	VIF_DIFFCODEPG = 16,
	VIF_DIFFTYPE = 32,
	VIF_WRITEPROT = 64,
	VIF_FILEINUSE = 128,
	VIF_OUTOFSPACE = 256,
	VIF_ACCESSVIOLATION = 512,
	VIF_SHARINGVIOLATION = 1024,
	VIF_CANNOTCREATE = 2048,
	VIF_CANNOTDELETE = 4096,
	VIF_CANNOTRENAME = 8192,
	VIF_CANNOTDELETECUR = 16384,
	VIF_OUTOFMEMORY = 32768,
	VIF_CANNOTREADSRC = 65536,
	VIF_CANNOTREADDST = 131072,
	VIF_BUFFTOOSMALL = 262144,
	VIF_CANNOTLOADLZ32 = 524288,
	VIF_CANNOTLOADCABINET = 1048576,
}


[AllowDuplicates]
public enum VS_FIXEDFILEINFO_FILE_FLAGS : uint32
{
	VS_FF_DEBUG = 1,
	VS_FF_PRERELEASE = 2,
	VS_FF_PATCHED = 4,
	VS_FF_PRIVATEBUILD = 8,
	VS_FF_INFOINFERRED = 16,
	VS_FF_SPECIALBUILD = 32,
}


[AllowDuplicates]
public enum VS_FIXEDFILEINFO_FILE_OS : int32
{
	VOS_UNKNOWN = 0,
	VOS_DOS = 65536,
	VOS_OS216 = 131072,
	VOS_OS232 = 196608,
	VOS_NT = 262144,
	VOS_WINCE = 327680,
	VOS__BASE = 0,
	VOS__WINDOWS16 = 1,
	VOS__PM16 = 2,
	VOS__PM32 = 3,
	VOS__WINDOWS32 = 4,
	VOS_DOS_WINDOWS16 = 65537,
	VOS_DOS_WINDOWS32 = 65540,
	VOS_OS216_PM16 = 131074,
	VOS_OS232_PM32 = 196611,
	VOS_NT_WINDOWS32 = 262148,
}


[AllowDuplicates]
public enum VS_FIXEDFILEINFO_FILE_TYPE : int32
{
	VFT_UNKNOWN = 0,
	VFT_APP = 1,
	VFT_DLL = 2,
	VFT_DRV = 3,
	VFT_FONT = 4,
	VFT_VXD = 5,
	VFT_STATIC_LIB = 7,
}


[AllowDuplicates]
public enum VS_FIXEDFILEINFO_FILE_SUBTYPE : int32
{
	VFT2_UNKNOWN = 0,
	VFT2_DRV_PRINTER = 1,
	VFT2_DRV_KEYBOARD = 2,
	VFT2_DRV_LANGUAGE = 3,
	VFT2_DRV_DISPLAY = 4,
	VFT2_DRV_MOUSE = 5,
	VFT2_DRV_NETWORK = 6,
	VFT2_DRV_SYSTEM = 7,
	VFT2_DRV_INSTALLABLE = 8,
	VFT2_DRV_SOUND = 9,
	VFT2_DRV_COMM = 10,
	VFT2_DRV_INPUTMETHOD = 11,
	VFT2_DRV_VERSIONED_PRINTER = 12,
	VFT2_FONT_RASTER = 1,
	VFT2_FONT_VECTOR = 2,
	VFT2_FONT_TRUETYPE = 3,
}


[AllowDuplicates]
public enum FILE_CREATION_DISPOSITION : uint32
{
	CREATE_NEW = 1,
	CREATE_ALWAYS = 2,
	OPEN_EXISTING = 3,
	OPEN_ALWAYS = 4,
	TRUNCATE_EXISTING = 5,
}


[AllowDuplicates]
public enum FILE_SHARE_MODE : uint32
{
	FILE_SHARE_NONE = 0,
	FILE_SHARE_DELETE = 4,
	FILE_SHARE_READ = 1,
	FILE_SHARE_WRITE = 2,
}


[AllowDuplicates]
public enum SHARE_TYPE : uint32
{
	STYPE_DISKTREE = 0,
	STYPE_PRINTQ = 1,
	STYPE_DEVICE = 2,
	STYPE_IPC = 3,
	STYPE_SPECIAL = 2147483648,
	STYPE_TEMPORARY = 1073741824,
	STYPE_MASK = 255,
}


[AllowDuplicates]
public enum CLFS_FLAG : uint32
{
	CLFS_FLAG_FORCE_APPEND = 1,
	CLFS_FLAG_FORCE_FLUSH = 2,
	CLFS_FLAG_NO_FLAGS = 0,
	CLFS_FLAG_USE_RESERVATION = 4,
}


[AllowDuplicates]
public enum SET_FILE_POINTER_MOVE_METHOD : uint32
{
	FILE_BEGIN = 0,
	FILE_CURRENT = 1,
	FILE_END = 2,
}


[AllowDuplicates]
public enum MOVE_FILE_FLAGS : uint32
{
	MOVEFILE_COPY_ALLOWED = 2,
	MOVEFILE_CREATE_HARDLINK = 16,
	MOVEFILE_DELAY_UNTIL_REBOOT = 4,
	MOVEFILE_REPLACE_EXISTING = 1,
	MOVEFILE_WRITE_THROUGH = 8,
	MOVEFILE_FAIL_IF_NOT_TRACKABLE = 32,
}


[AllowDuplicates]
public enum FILE_NAME : uint32
{
	FILE_NAME_NORMALIZED = 0,
	FILE_NAME_OPENED = 8,
}


[AllowDuplicates]
public enum LZOPENFILE_STYLE : uint16
{
	OF_CANCEL = 2048,
	OF_CREATE = 4096,
	OF_DELETE = 512,
	OF_EXIST = 16384,
	OF_PARSE = 256,
	OF_PROMPT = 8192,
	OF_READ = 0,
	OF_READWRITE = 2,
	OF_REOPEN = 32768,
	OF_SHARE_DENY_NONE = 64,
	OF_SHARE_DENY_READ = 48,
	OF_SHARE_DENY_WRITE = 32,
	OF_SHARE_EXCLUSIVE = 16,
	OF_WRITE = 1,
	OF_SHARE_COMPAT = 0,
	OF_VERIFY = 1024,
}


[AllowDuplicates]
public enum FILE_NOTIFY_CHANGE : uint32
{
	FILE_NOTIFY_CHANGE_FILE_NAME = 1,
	FILE_NOTIFY_CHANGE_DIR_NAME = 2,
	FILE_NOTIFY_CHANGE_ATTRIBUTES = 4,
	FILE_NOTIFY_CHANGE_SIZE = 8,
	FILE_NOTIFY_CHANGE_LAST_WRITE = 16,
	FILE_NOTIFY_CHANGE_LAST_ACCESS = 32,
	FILE_NOTIFY_CHANGE_CREATION = 64,
	FILE_NOTIFY_CHANGE_SECURITY = 256,
}


[AllowDuplicates]
public enum TXFS_MINIVERSION : uint32
{
	TXFS_MINIVERSION_COMMITTED_VIEW = 0,
	TXFS_MINIVERSION_DIRTY_VIEW = 65535,
	TXFS_MINIVERSION_DEFAULT_VIEW = 65534,
}


[AllowDuplicates]
public enum TAPE_POSITION_TYPE : int32
{
	TAPE_ABSOLUTE_POSITION = 0,
	TAPE_LOGICAL_POSITION = 1,
}


[AllowDuplicates]
public enum CREATE_TAPE_PARTITION_METHOD : int32
{
	TAPE_FIXED_PARTITIONS = 0,
	TAPE_INITIATOR_PARTITIONS = 2,
	TAPE_SELECT_PARTITIONS = 1,
}


[AllowDuplicates]
public enum REPLACE_FILE_FLAGS : uint32
{
	REPLACEFILE_WRITE_THROUGH = 1,
	REPLACEFILE_IGNORE_MERGE_ERRORS = 2,
	REPLACEFILE_IGNORE_ACL_ERRORS = 4,
}


[AllowDuplicates]
public enum TAPEMARK_TYPE : int32
{
	TAPE_FILEMARKS = 1,
	TAPE_LONG_FILEMARKS = 3,
	TAPE_SETMARKS = 0,
	TAPE_SHORT_FILEMARKS = 2,
}


[AllowDuplicates]
public enum DISKQUOTA_USERNAME_RESOLVE : uint32
{
	DISKQUOTA_USERNAME_RESOLVE_ASYNC = 2,
	DISKQUOTA_USERNAME_RESOLVE_NONE = 0,
	DISKQUOTA_USERNAME_RESOLVE_SYNC = 1,
}


[AllowDuplicates]
public enum TAPE_POSITION_METHOD : int32
{
	TAPE_ABSOLUTE_BLOCK = 1,
	TAPE_LOGICAL_BLOCK = 2,
	TAPE_REWIND = 0,
	TAPE_SPACE_END_OF_DATA = 4,
	TAPE_SPACE_FILEMARKS = 6,
	TAPE_SPACE_RELATIVE_BLOCKS = 5,
	TAPE_SPACE_SEQUENTIAL_FMKS = 7,
	TAPE_SPACE_SEQUENTIAL_SMKS = 9,
	TAPE_SPACE_SETMARKS = 8,
}


[AllowDuplicates]
public enum NT_CREATE_FILE_DISPOSITION : uint32
{
	FILE_SUPERSEDE = 0,
	FILE_CREATE = 2,
	FILE_OPEN = 1,
	FILE_OPEN_IF = 3,
	FILE_OVERWRITE = 4,
	FILE_OVERWRITE_IF = 5,
}


[AllowDuplicates]
public enum TAPE_INFORMATION_TYPE : uint32
{
	SET_TAPE_DRIVE_INFORMATION = 1,
	SET_TAPE_MEDIA_INFORMATION = 0,
}


[AllowDuplicates]
public enum NTMS_OMID_TYPE : uint32
{
	NTMS_OMID_TYPE_FILESYSTEM_INFO = 2,
	NTMS_OMID_TYPE_RAW_LABEL = 1,
}


[AllowDuplicates]
public enum LOCK_FILE_FLAGS : uint32
{
	LOCKFILE_EXCLUSIVE_LOCK = 2,
	LOCKFILE_FAIL_IMMEDIATELY = 1,
}


[AllowDuplicates]
public enum LPPROGRESS_ROUTINE_CALLBACK_REASON : uint32
{
	CALLBACK_CHUNK_FINISHED = 0,
	CALLBACK_STREAM_SWITCH = 1,
}


[AllowDuplicates]
public enum PREPARE_TAPE_OPERATION : int32
{
	TAPE_FORMAT = 5,
	TAPE_LOAD = 0,
	TAPE_LOCK = 3,
	TAPE_TENSION = 2,
	TAPE_UNLOAD = 1,
	TAPE_UNLOCK = 4,
}


[AllowDuplicates]
public enum GET_TAPE_DRIVE_PARAMETERS_OPERATION : uint32
{
	GET_TAPE_DRIVE_INFORMATION = 1,
	GET_TAPE_MEDIA_INFORMATION = 0,
}


[AllowDuplicates]
public enum ERASE_TAPE_TYPE : int32
{
	TAPE_ERASE_LONG = 1,
	TAPE_ERASE_SHORT = 0,
}


[AllowDuplicates]
public enum FILE_ACTION : uint32
{
	FILE_ACTION_ADDED = 1,
	FILE_ACTION_REMOVED = 2,
	FILE_ACTION_MODIFIED = 3,
	FILE_ACTION_RENAMED_OLD_NAME = 4,
	FILE_ACTION_RENAMED_NEW_NAME = 5,
}


[AllowDuplicates]
public enum SHARE_INFO_PERMISSIONS : uint32
{
	ACCESS_READ = 1,
	ACCESS_WRITE = 2,
	ACCESS_CREATE = 4,
	ACCESS_EXEC = 8,
	ACCESS_DELETE = 16,
	ACCESS_ATRIB = 32,
	ACCESS_PERM = 64,
	ACCESS_ALL = 32768,
}


[AllowDuplicates]
public enum FILE_DEVICE_TYPE : uint32
{
	FILE_DEVICE_CD_ROM = 2,
	FILE_DEVICE_DISK = 7,
	FILE_DEVICE_TAPE = 31,
	FILE_DEVICE_DVD = 51,
}


[AllowDuplicates]
public enum SESSION_INFO_USER_FLAGS : uint32
{
	SESS_GUEST = 1,
	SESS_NOENCRYPTION = 2,
}


[AllowDuplicates]
public enum WIN_STREAM_ID : uint32
{
	BACKUP_ALTERNATE_DATA = 4,
	BACKUP_DATA = 1,
	BACKUP_EA_DATA = 2,
	BACKUP_LINK = 5,
	BACKUP_OBJECT_ID = 7,
	BACKUP_PROPERTY_DATA = 6,
	BACKUP_REPARSE_DATA = 8,
	BACKUP_SECURITY_DATA = 3,
	BACKUP_SPARSE_BLOCK = 9,
	BACKUP_TXFS_DATA = 10,
}


[AllowDuplicates]
public enum TXF_LOG_RECORD_TYPE : uint16
{
	TXF_LOG_RECORD_TYPE_AFFECTED_FILE = 4,
	TXF_LOG_RECORD_TYPE_TRUNCATE = 2,
	TXF_LOG_RECORD_TYPE_WRITE = 1,
}


[AllowDuplicates]
public enum FILE_INFO_FLAGS_PERMISSIONS : uint32
{
	PERM_FILE_READ = 1,
	PERM_FILE_WRITE = 2,
	PERM_FILE_CREATE = 4,
}


[AllowDuplicates]
public enum SYMBOLIC_LINK_FLAGS : uint32
{
	SYMBOLIC_LINK_FLAG_DIRECTORY = 1,
	SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE = 2,
}


[AllowDuplicates]
public enum FINDEX_INFO_LEVELS : int32
{
	FindExInfoStandard = 0,
	FindExInfoBasic = 1,
	FindExInfoMaxInfoLevel = 2,
}


[AllowDuplicates]
public enum FINDEX_SEARCH_OPS : int32
{
	FindExSearchNameMatch = 0,
	FindExSearchLimitToDirectories = 1,
	FindExSearchLimitToDevices = 2,
	FindExSearchMaxSearchOp = 3,
}


[AllowDuplicates]
public enum READ_DIRECTORY_NOTIFY_INFORMATION_CLASS : int32
{
	ReadDirectoryNotifyInformation = 1,
	ReadDirectoryNotifyExtendedInformation = 2,
}


[AllowDuplicates]
public enum GET_FILEEX_INFO_LEVELS : int32
{
	GetFileExInfoStandard = 0,
	GetFileExMaxInfoLevel = 1,
}


[AllowDuplicates]
public enum FILE_INFO_BY_HANDLE_CLASS : int32
{
	FileBasicInfo = 0,
	FileStandardInfo = 1,
	FileNameInfo = 2,
	FileRenameInfo = 3,
	FileDispositionInfo = 4,
	FileAllocationInfo = 5,
	FileEndOfFileInfo = 6,
	FileStreamInfo = 7,
	FileCompressionInfo = 8,
	FileAttributeTagInfo = 9,
	FileIdBothDirectoryInfo = 10,
	FileIdBothDirectoryRestartInfo = 11,
	FileIoPriorityHintInfo = 12,
	FileRemoteProtocolInfo = 13,
	FileFullDirectoryInfo = 14,
	FileFullDirectoryRestartInfo = 15,
	FileStorageInfo = 16,
	FileAlignmentInfo = 17,
	FileIdInfo = 18,
	FileIdExtdDirectoryInfo = 19,
	FileIdExtdDirectoryRestartInfo = 20,
	FileDispositionInfoEx = 21,
	FileRenameInfoEx = 22,
	FileCaseSensitiveInfo = 23,
	FileNormalizedNameInfo = 24,
	MaximumFileInfoByHandleClass = 25,
}


[AllowDuplicates]
public enum STREAM_INFO_LEVELS : int32
{
	FindStreamInfoStandard = 0,
	FindStreamInfoMaxInfoLevel = 1,
}


[AllowDuplicates]
public enum NtmsObjectsTypes : int32
{
	NTMS_UNKNOWN = 0,
	NTMS_OBJECT = 1,
	NTMS_CHANGER = 2,
	NTMS_CHANGER_TYPE = 3,
	NTMS_COMPUTER = 4,
	NTMS_DRIVE = 5,
	NTMS_DRIVE_TYPE = 6,
	NTMS_IEDOOR = 7,
	NTMS_IEPORT = 8,
	NTMS_LIBRARY = 9,
	NTMS_LIBREQUEST = 10,
	NTMS_LOGICAL_MEDIA = 11,
	NTMS_MEDIA_POOL = 12,
	NTMS_MEDIA_TYPE = 13,
	NTMS_PARTITION = 14,
	NTMS_PHYSICAL_MEDIA = 15,
	NTMS_STORAGESLOT = 16,
	NTMS_OPREQUEST = 17,
	NTMS_UI_DESTINATION = 18,
	NTMS_NUMBER_OF_OBJECT_TYPES = 19,
}


[AllowDuplicates]
public enum NtmsAsyncStatus : int32
{
	NTMS_ASYNCSTATE_QUEUED = 0,
	NTMS_ASYNCSTATE_WAIT_RESOURCE = 1,
	NTMS_ASYNCSTATE_WAIT_OPERATOR = 2,
	NTMS_ASYNCSTATE_INPROCESS = 3,
	NTMS_ASYNCSTATE_COMPLETE = 4,
}


[AllowDuplicates]
public enum NtmsAsyncOperations : int32
{
	NTMS_ASYNCOP_MOUNT = 1,
}


[AllowDuplicates]
public enum NtmsSessionOptions : int32
{
	NTMS_SESSION_QUERYEXPEDITE = 1,
}


[AllowDuplicates]
public enum NtmsMountOptions : int32
{
	NTMS_MOUNT_READ = 1,
	NTMS_MOUNT_WRITE = 2,
	NTMS_MOUNT_ERROR_NOT_AVAILABLE = 4,
	NTMS_MOUNT_ERROR_IF_UNAVAILABLE = 4,
	NTMS_MOUNT_ERROR_OFFLINE = 8,
	NTMS_MOUNT_ERROR_IF_OFFLINE = 8,
	NTMS_MOUNT_SPECIFIC_DRIVE = 16,
	NTMS_MOUNT_NOWAIT = 32,
}


[AllowDuplicates]
public enum NtmsDismountOptions : int32
{
	NTMS_DISMOUNT_DEFERRED = 1,
	NTMS_DISMOUNT_IMMEDIATE = 2,
}


[AllowDuplicates]
public enum NtmsMountPriority : int32
{
	NTMS_PRIORITY_DEFAULT = 0,
	NTMS_PRIORITY_HIGHEST = 15,
	NTMS_PRIORITY_HIGH = 7,
	NTMS_PRIORITY_NORMAL = 0,
	NTMS_PRIORITY_LOW = -7,
	NTMS_PRIORITY_LOWEST = -15,
}


[AllowDuplicates]
public enum NtmsAllocateOptions : int32
{
	NTMS_ALLOCATE_NEW = 1,
	NTMS_ALLOCATE_NEXT = 2,
	NTMS_ALLOCATE_ERROR_IF_UNAVAILABLE = 4,
}


[AllowDuplicates]
public enum NtmsCreateOptions : int32
{
	NTMS_OPEN_EXISTING = 1,
	NTMS_CREATE_NEW = 2,
	NTMS_OPEN_ALWAYS = 3,
}


[AllowDuplicates]
public enum NtmsDriveState : int32
{
	NTMS_DRIVESTATE_DISMOUNTED = 0,
	NTMS_DRIVESTATE_MOUNTED = 1,
	NTMS_DRIVESTATE_LOADED = 2,
	NTMS_DRIVESTATE_UNLOADED = 5,
	NTMS_DRIVESTATE_BEING_CLEANED = 6,
	NTMS_DRIVESTATE_DISMOUNTABLE = 7,
}


[AllowDuplicates]
public enum NtmsLibraryType : int32
{
	NTMS_LIBRARYTYPE_UNKNOWN = 0,
	NTMS_LIBRARYTYPE_OFFLINE = 1,
	NTMS_LIBRARYTYPE_ONLINE = 2,
	NTMS_LIBRARYTYPE_STANDALONE = 3,
}


[AllowDuplicates]
public enum NtmsLibraryFlags : int32
{
	NTMS_LIBRARYFLAG_FIXEDOFFLINE = 1,
	NTMS_LIBRARYFLAG_CLEANERPRESENT = 2,
	NTMS_LIBRARYFLAG_AUTODETECTCHANGE = 4,
	NTMS_LIBRARYFLAG_IGNORECLEANERUSESREMAINING = 8,
	NTMS_LIBRARYFLAG_RECOGNIZECLEANERBARCODE = 16,
}


[AllowDuplicates]
public enum NtmsInventoryMethod : int32
{
	NTMS_INVENTORY_NONE = 0,
	NTMS_INVENTORY_FAST = 1,
	NTMS_INVENTORY_OMID = 2,
	NTMS_INVENTORY_DEFAULT = 3,
	NTMS_INVENTORY_SLOT = 4,
	NTMS_INVENTORY_STOP = 5,
	NTMS_INVENTORY_MAX = 6,
}


[AllowDuplicates]
public enum NtmsSlotState : int32
{
	NTMS_SLOTSTATE_UNKNOWN = 0,
	NTMS_SLOTSTATE_FULL = 1,
	NTMS_SLOTSTATE_EMPTY = 2,
	NTMS_SLOTSTATE_NOTPRESENT = 3,
	NTMS_SLOTSTATE_NEEDSINVENTORY = 4,
}


[AllowDuplicates]
public enum NtmsDoorState : int32
{
	NTMS_DOORSTATE_UNKNOWN = 0,
	NTMS_DOORSTATE_CLOSED = 1,
	NTMS_DOORSTATE_OPEN = 2,
}


[AllowDuplicates]
public enum NtmsPortPosition : int32
{
	NTMS_PORTPOSITION_UNKNOWN = 0,
	NTMS_PORTPOSITION_EXTENDED = 1,
	NTMS_PORTPOSITION_RETRACTED = 2,
}


[AllowDuplicates]
public enum NtmsPortContent : int32
{
	NTMS_PORTCONTENT_UNKNOWN = 0,
	NTMS_PORTCONTENT_FULL = 1,
	NTMS_PORTCONTENT_EMPTY = 2,
}


[AllowDuplicates]
public enum NtmsBarCodeState : int32
{
	NTMS_BARCODESTATE_OK = 1,
	NTMS_BARCODESTATE_UNREADABLE = 2,
}


[AllowDuplicates]
public enum NtmsMediaState : int32
{
	NTMS_MEDIASTATE_IDLE = 0,
	NTMS_MEDIASTATE_INUSE = 1,
	NTMS_MEDIASTATE_MOUNTED = 2,
	NTMS_MEDIASTATE_LOADED = 3,
	NTMS_MEDIASTATE_UNLOADED = 4,
	NTMS_MEDIASTATE_OPERROR = 5,
	NTMS_MEDIASTATE_OPREQ = 6,
}


[AllowDuplicates]
public enum NtmsPartitionState : int32
{
	NTMS_PARTSTATE_UNKNOWN = 0,
	NTMS_PARTSTATE_UNPREPARED = 1,
	NTMS_PARTSTATE_INCOMPATIBLE = 2,
	NTMS_PARTSTATE_DECOMMISSIONED = 3,
	NTMS_PARTSTATE_AVAILABLE = 4,
	NTMS_PARTSTATE_ALLOCATED = 5,
	NTMS_PARTSTATE_COMPLETE = 6,
	NTMS_PARTSTATE_FOREIGN = 7,
	NTMS_PARTSTATE_IMPORT = 8,
	NTMS_PARTSTATE_RESERVED = 9,
}


[AllowDuplicates]
public enum NtmsPoolType : int32
{
	NTMS_POOLTYPE_UNKNOWN = 0,
	NTMS_POOLTYPE_SCRATCH = 1,
	NTMS_POOLTYPE_FOREIGN = 2,
	NTMS_POOLTYPE_IMPORT = 3,
	NTMS_POOLTYPE_APPLICATION = 1000,
}


[AllowDuplicates]
public enum NtmsAllocationPolicy : int32
{
	NTMS_ALLOCATE_FROMSCRATCH = 1,
}


[AllowDuplicates]
public enum NtmsDeallocationPolicy : int32
{
	NTMS_DEALLOCATE_TOSCRATCH = 1,
}


[AllowDuplicates]
public enum NtmsReadWriteCharacteristics : int32
{
	NTMS_MEDIARW_UNKNOWN = 0,
	NTMS_MEDIARW_REWRITABLE = 1,
	NTMS_MEDIARW_WRITEONCE = 2,
	NTMS_MEDIARW_READONLY = 3,
}


[AllowDuplicates]
public enum NtmsLmOperation : int32
{
	NTMS_LM_REMOVE = 0,
	NTMS_LM_DISABLECHANGER = 1,
	NTMS_LM_DISABLELIBRARY = 1,
	NTMS_LM_ENABLECHANGER = 2,
	NTMS_LM_ENABLELIBRARY = 2,
	NTMS_LM_DISABLEDRIVE = 3,
	NTMS_LM_ENABLEDRIVE = 4,
	NTMS_LM_DISABLEMEDIA = 5,
	NTMS_LM_ENABLEMEDIA = 6,
	NTMS_LM_UPDATEOMID = 7,
	NTMS_LM_INVENTORY = 8,
	NTMS_LM_DOORACCESS = 9,
	NTMS_LM_EJECT = 10,
	NTMS_LM_EJECTCLEANER = 11,
	NTMS_LM_INJECT = 12,
	NTMS_LM_INJECTCLEANER = 13,
	NTMS_LM_PROCESSOMID = 14,
	NTMS_LM_CLEANDRIVE = 15,
	NTMS_LM_DISMOUNT = 16,
	NTMS_LM_MOUNT = 17,
	NTMS_LM_WRITESCRATCH = 18,
	NTMS_LM_CLASSIFY = 19,
	NTMS_LM_RESERVECLEANER = 20,
	NTMS_LM_RELEASECLEANER = 21,
	NTMS_LM_MAXWORKITEM = 22,
}


[AllowDuplicates]
public enum NtmsLmState : int32
{
	NTMS_LM_QUEUED = 0,
	NTMS_LM_INPROCESS = 1,
	NTMS_LM_PASSED = 2,
	NTMS_LM_FAILED = 3,
	NTMS_LM_INVALID = 4,
	NTMS_LM_WAITING = 5,
	NTMS_LM_DEFERRED = 6,
	NTMS_LM_DEFFERED = 6,
	NTMS_LM_CANCELLED = 7,
	NTMS_LM_STOPPED = 8,
}


[AllowDuplicates]
public enum NtmsOpreqCommand : int32
{
	NTMS_OPREQ_UNKNOWN = 0,
	NTMS_OPREQ_NEWMEDIA = 1,
	NTMS_OPREQ_CLEANER = 2,
	NTMS_OPREQ_DEVICESERVICE = 3,
	NTMS_OPREQ_MOVEMEDIA = 4,
	NTMS_OPREQ_MESSAGE = 5,
}


[AllowDuplicates]
public enum NtmsOpreqState : int32
{
	NTMS_OPSTATE_UNKNOWN = 0,
	NTMS_OPSTATE_SUBMITTED = 1,
	NTMS_OPSTATE_ACTIVE = 2,
	NTMS_OPSTATE_INPROGRESS = 3,
	NTMS_OPSTATE_REFUSED = 4,
	NTMS_OPSTATE_COMPLETE = 5,
}


[AllowDuplicates]
public enum NtmsLibRequestFlags : int32
{
	NTMS_LIBREQFLAGS_NOAUTOPURGE = 1,
	NTMS_LIBREQFLAGS_NOFAILEDPURGE = 2,
}


[AllowDuplicates]
public enum NtmsOpRequestFlags : int32
{
	NTMS_OPREQFLAGS_NOAUTOPURGE = 1,
	NTMS_OPREQFLAGS_NOFAILEDPURGE = 2,
	NTMS_OPREQFLAGS_NOALERTS = 16,
	NTMS_OPREQFLAGS_NOTRAYICON = 32,
}


[AllowDuplicates]
public enum NtmsMediaPoolPolicy : int32
{
	NTMS_POOLPOLICY_PURGEOFFLINESCRATCH = 1,
	NTMS_POOLPOLICY_KEEPOFFLINEIMPORT = 2,
}


[AllowDuplicates]
public enum NtmsOperationalState : int32
{
	NTMS_READY = 0,
	NTMS_INITIALIZING = 10,
	NTMS_NEEDS_SERVICE = 20,
	NTMS_NOT_PRESENT = 21,
}


[AllowDuplicates]
public enum NtmsCreateNtmsMediaOptions : int32
{
	NTMS_ERROR_ON_DUPLICATE = 1,
}


[AllowDuplicates]
public enum NtmsEnumerateOption : int32
{
	NTMS_ENUM_DEFAULT = 0,
	NTMS_ENUM_ROOTPOOL = 1,
}


[AllowDuplicates]
public enum NtmsEjectOperation : int32
{
	NTMS_EJECT_START = 0,
	NTMS_EJECT_STOP = 1,
	NTMS_EJECT_QUEUE = 2,
	NTMS_EJECT_FORCE = 3,
	NTMS_EJECT_IMMEDIATE = 4,
	NTMS_EJECT_ASK_USER = 5,
}


[AllowDuplicates]
public enum NtmsInjectOperation : int32
{
	NTMS_INJECT_START = 0,
	NTMS_INJECT_STOP = 1,
	NTMS_INJECT_RETRACT = 2,
	NTMS_INJECT_STARTMANY = 3,
}


[AllowDuplicates]
public enum NtmsDriveType : int32
{
	NTMS_UNKNOWN_DRIVE = 0,
}


[AllowDuplicates]
public enum NtmsAccessMask : int32
{
	NTMS_USE_ACCESS = 1,
	NTMS_MODIFY_ACCESS = 2,
	NTMS_CONTROL_ACCESS = 4,
}


[AllowDuplicates]
public enum NtmsUITypes : int32
{
	NTMS_UITYPE_INVALID = 0,
	NTMS_UITYPE_INFO = 1,
	NTMS_UITYPE_REQ = 2,
	NTMS_UITYPE_ERR = 3,
	NTMS_UITYPE_MAX = 4,
}


[AllowDuplicates]
public enum NtmsUIOperations : int32
{
	NTMS_UIDEST_ADD = 1,
	NTMS_UIDEST_DELETE = 2,
	NTMS_UIDEST_DELETEALL = 3,
	NTMS_UIOPERATION_MAX = 4,
}


[AllowDuplicates]
public enum NtmsNotificationOperations : int32
{
	NTMS_OBJ_UPDATE = 1,
	NTMS_OBJ_INSERT = 2,
	NTMS_OBJ_DELETE = 3,
	NTMS_EVENT_SIGNAL = 4,
	NTMS_EVENT_COMPLETE = 5,
}


[AllowDuplicates]
public enum CLS_CONTEXT_MODE : int32
{
	ClsContextNone = 0,
	ClsContextUndoNext = 1,
	ClsContextPrevious = 2,
	ClsContextForward = 3,
}


[AllowDuplicates]
public enum CLFS_CONTEXT_MODE : int32
{
	ClfsContextNone = 0,
	ClfsContextUndoNext = 1,
	ClfsContextPrevious = 2,
	ClfsContextForward = 3,
}


[AllowDuplicates]
public enum CLS_LOG_INFORMATION_CLASS : int32
{
	ClfsLogBasicInformation = 0,
	ClfsLogBasicInformationPhysical = 1,
	ClfsLogPhysicalNameInformation = 2,
	ClfsLogStreamIdentifierInformation = 3,
	ClfsLogSystemMarkingInformation = 4,
	ClfsLogPhysicalLsnInformation = 5,
}


[AllowDuplicates]
public enum CLS_IOSTATS_CLASS : int32
{
	ClsIoStatsDefault = 0,
	ClsIoStatsMax = 65535,
}


[AllowDuplicates]
public enum CLFS_IOSTATS_CLASS : int32
{
	ClfsIoStatsDefault = 0,
	ClfsIoStatsMax = 65535,
}


[AllowDuplicates]
public enum CLFS_LOG_ARCHIVE_MODE : int32
{
	ClfsLogArchiveEnabled = 1,
	ClfsLogArchiveDisabled = 2,
}


[AllowDuplicates]
public enum CLFS_MGMT_POLICY_TYPE : int32
{
	ClfsMgmtPolicyMaximumSize = 0,
	ClfsMgmtPolicyMinimumSize = 1,
	ClfsMgmtPolicyNewContainerSize = 2,
	ClfsMgmtPolicyGrowthRate = 3,
	ClfsMgmtPolicyLogTail = 4,
	ClfsMgmtPolicyAutoShrink = 5,
	ClfsMgmtPolicyAutoGrow = 6,
	ClfsMgmtPolicyNewContainerPrefix = 7,
	ClfsMgmtPolicyNewContainerSuffix = 8,
	ClfsMgmtPolicyNewContainerExtension = 9,
	ClfsMgmtPolicyInvalid = 10,
}


[AllowDuplicates]
public enum CLFS_MGMT_NOTIFICATION_TYPE : int32
{
	ClfsMgmtAdvanceTailNotification = 0,
	ClfsMgmtLogFullHandlerNotification = 1,
	ClfsMgmtLogUnpinnedNotification = 2,
	ClfsMgmtLogWriteNotification = 3,
}


[AllowDuplicates]
public enum SERVER_CERTIFICATE_TYPE : int32
{
	QUIC = 0,
}


[AllowDuplicates]
public enum IORING_VERSION : int32
{
	IORING_VERSION_INVALID = 0,
	IORING_VERSION_1 = 1,
}


[AllowDuplicates]
public enum IORING_FEATURE_FLAGS : int32
{
	IORING_FEATURE_FLAGS_NONE = 0,
	IORING_FEATURE_UM_EMULATION = 1,
	IORING_FEATURE_SET_COMPLETION_EVENT = 2,
}


[AllowDuplicates]
public enum IORING_OP_CODE : int32
{
	IORING_OP_NOP = 0,
	IORING_OP_READ = 1,
	IORING_OP_REGISTER_FILES = 2,
	IORING_OP_REGISTER_BUFFERS = 3,
	IORING_OP_CANCEL = 4,
}


[AllowDuplicates]
public enum IORING_SQE_FLAGS : int32
{
	IOSQE_FLAGS_NONE = 0,
}


[AllowDuplicates]
public enum IORING_CREATE_REQUIRED_FLAGS : int32
{
	IORING_CREATE_REQUIRED_FLAGS_NONE = 0,
}


[AllowDuplicates]
public enum IORING_CREATE_ADVISORY_FLAGS : int32
{
	IORING_CREATE_ADVISORY_FLAGS_NONE = 0,
}


[AllowDuplicates]
public enum IORING_REF_KIND : int32
{
	IORING_REF_RAW = 0,
	IORING_REF_REGISTERED = 1,
}


[AllowDuplicates]
public enum TRANSACTION_OUTCOME : int32
{
	TransactionOutcomeUndetermined = 1,
	TransactionOutcomeCommitted = 2,
	TransactionOutcomeAborted = 3,
}


[AllowDuplicates]
public enum STORAGE_BUS_TYPE : int32
{
	BusTypeUnknown = 0,
	BusTypeScsi = 1,
	BusTypeAtapi = 2,
	BusTypeAta = 3,
	BusType1394 = 4,
	BusTypeSsa = 5,
	BusTypeFibre = 6,
	BusTypeUsb = 7,
	BusTypeRAID = 8,
	BusTypeiScsi = 9,
	BusTypeSas = 10,
	BusTypeSata = 11,
	BusTypeSd = 12,
	BusTypeMmc = 13,
	BusTypeVirtual = 14,
	BusTypeFileBackedVirtual = 15,
	BusTypeSpaces = 16,
	BusTypeNvme = 17,
	BusTypeSCM = 18,
	BusTypeUfs = 19,
	BusTypeMax = 20,
	BusTypeMaxReserved = 127,
}


[AllowDuplicates]
public enum COPYFILE2_MESSAGE_TYPE : int32
{
	COPYFILE2_CALLBACK_NONE = 0,
	COPYFILE2_CALLBACK_CHUNK_STARTED = 1,
	COPYFILE2_CALLBACK_CHUNK_FINISHED = 2,
	COPYFILE2_CALLBACK_STREAM_STARTED = 3,
	COPYFILE2_CALLBACK_STREAM_FINISHED = 4,
	COPYFILE2_CALLBACK_POLL_CONTINUE = 5,
	COPYFILE2_CALLBACK_ERROR = 6,
	COPYFILE2_CALLBACK_MAX = 7,
}


[AllowDuplicates]
public enum COPYFILE2_MESSAGE_ACTION : int32
{
	COPYFILE2_PROGRESS_CONTINUE = 0,
	COPYFILE2_PROGRESS_CANCEL = 1,
	COPYFILE2_PROGRESS_STOP = 2,
	COPYFILE2_PROGRESS_QUIET = 3,
	COPYFILE2_PROGRESS_PAUSE = 4,
}


[AllowDuplicates]
public enum COPYFILE2_COPY_PHASE : int32
{
	COPYFILE2_PHASE_NONE = 0,
	COPYFILE2_PHASE_PREPARE_SOURCE = 1,
	COPYFILE2_PHASE_PREPARE_DEST = 2,
	COPYFILE2_PHASE_READ_SOURCE = 3,
	COPYFILE2_PHASE_WRITE_DESTINATION = 4,
	COPYFILE2_PHASE_SERVER_COPY = 5,
	COPYFILE2_PHASE_NAMEGRAFT_COPY = 6,
	COPYFILE2_PHASE_MAX = 7,
}


[AllowDuplicates]
public enum PRIORITY_HINT : int32
{
	IoPriorityHintVeryLow = 0,
	IoPriorityHintLow = 1,
	IoPriorityHintNormal = 2,
	MaximumIoPriorityHintType = 3,
}


[AllowDuplicates]
public enum FILE_ID_TYPE : int32
{
	FileIdType = 0,
	ObjectIdType = 1,
	ExtendedFileIdType = 2,
	MaximumFileIdType = 3,
}

#endregion

#region Function Pointers
public function uint32 MAXMEDIALABEL(uint32* pMaxSize);

public function uint32 CLAIMMEDIALABEL(uint8* pBuffer, uint32 nBufferSize, MediaLabelInfo* pLabelInfo);

public function uint32 CLAIMMEDIALABELEX(uint8* pBuffer, uint32 nBufferSize, MediaLabelInfo* pLabelInfo, Guid* LabelGuid);

public function void* CLFS_BLOCK_ALLOCATION(uint32 cbBufferLength, void* pvUserContext);

public function void CLFS_BLOCK_DEALLOCATION(void* pvBuffer, void* pvUserContext);

public function void PCLFS_COMPLETION_ROUTINE(void* pvOverlapped, uint32 ulReserved);

public function void PLOG_TAIL_ADVANCE_CALLBACK(HANDLE hLogFile, CLS_LSN lsnTarget, void* pvClientContext);

public function void PLOG_FULL_HANDLER_CALLBACK(HANDLE hLogFile, uint32 dwError, BOOL fLogIsPinned, void* pvClientContext);

public function void PLOG_UNPINNED_CALLBACK(HANDLE hLogFile, void* pvClientContext);

public function BOOL WofEnumEntryProc(void* EntryInfo, void* UserData);

public function BOOL WofEnumFilesProc(PWSTR FilePath, void* ExternalFileInfo, void* UserData);

public function void PFN_IO_COMPLETION(FIO_CONTEXT* pContext, FH_OVERLAPPED* lpo, uint32 cb, uint32 dwCompletionStatus);

public function HANDLE FCACHE_CREATE_CALLBACK(PSTR lpstrName, void* lpvData, uint32* cbFileSize, uint32* cbFileSizeHigh);

public function HANDLE FCACHE_RICHCREATE_CALLBACK(PSTR lpstrName, void* lpvData, uint32* cbFileSize, uint32* cbFileSizeHigh, BOOL* pfDidWeScanIt, BOOL* pfIsStuffed, BOOL* pfStoredWithDots, BOOL* pfStoredWithTerminatingDot);

public function int32 CACHE_KEY_COMPARE(uint32 cbKey1, uint8* lpbKey1, uint32 cbKey2, uint8* lpbKey2);

public function uint32 CACHE_KEY_HASH(uint8* lpbKey, uint32 cbKey);

public function BOOL CACHE_READ_CALLBACK(uint32 cb, uint8* lpb, void* lpvContext);

public function void CACHE_DESTROY_CALLBACK(uint32 cb, uint8* lpb);

public function BOOL CACHE_ACCESS_CHECK(PSECURITY_DESCRIPTOR pSecurityDescriptor, HANDLE hClientToken, uint32 dwDesiredAccess, GENERIC_MAPPING* GenericMapping, PRIVILEGE_SET* PrivilegeSet, uint32* PrivilegeSetLength, uint32* GrantedAccess, int32* AccessStatus);

public function uint32 PFE_EXPORT_FUNC(uint8* pbData, void* pvCallbackContext, uint32 ulLength);

public function uint32 PFE_IMPORT_FUNC(uint8* pbData, void* pvCallbackContext, uint32* ulLength);

public function uint32 LPPROGRESS_ROUTINE(LARGE_INTEGER TotalFileSize, LARGE_INTEGER TotalBytesTransferred, LARGE_INTEGER StreamSize, LARGE_INTEGER StreamBytesTransferred, uint32 dwStreamNumber, LPPROGRESS_ROUTINE_CALLBACK_REASON dwCallbackReason, HANDLE hSourceFile, HANDLE hDestinationFile, void* lpData);

public function COPYFILE2_MESSAGE_ACTION PCOPYFILE2_PROGRESS_ROUTINE(COPYFILE2_MESSAGE* pMessage, void* pvCallbackContext);

#endregion

#region Structs
[CRepr]
public struct FILE_DISPOSITION_INFO
{
	public BOOLEAN DeleteFile;
}

[CRepr]
public struct WIN32_FIND_DATAA
{
	public uint32 dwFileAttributes;
	public FILETIME ftCreationTime;
	public FILETIME ftLastAccessTime;
	public FILETIME ftLastWriteTime;
	public uint32 nFileSizeHigh;
	public uint32 nFileSizeLow;
	public uint32 dwReserved0;
	public uint32 dwReserved1;
	public CHAR[260] cFileName;
	public CHAR[14] cAlternateFileName;
}

[CRepr]
public struct WIN32_FIND_DATAW
{
	public uint32 dwFileAttributes;
	public FILETIME ftCreationTime;
	public FILETIME ftLastAccessTime;
	public FILETIME ftLastWriteTime;
	public uint32 nFileSizeHigh;
	public uint32 nFileSizeLow;
	public uint32 dwReserved0;
	public uint32 dwReserved1;
	public char16[260] cFileName;
	public char16[14] cAlternateFileName;
}

[CRepr]
public struct TRANSACTION_NOTIFICATION
{
	public void* TransactionKey;
	public uint32 TransactionNotification;
	public LARGE_INTEGER TmVirtualClock;
	public uint32 ArgumentLength;
}

[CRepr]
public struct TRANSACTION_NOTIFICATION_RECOVERY_ARGUMENT
{
	public Guid EnlistmentId;
	public Guid UOW;
}

[CRepr]
public struct TRANSACTION_NOTIFICATION_TM_ONLINE_ARGUMENT
{
	public Guid TmIdentity;
	public uint32 Flags;
}

[CRepr]
public struct TRANSACTION_NOTIFICATION_SAVEPOINT_ARGUMENT
{
	public uint32 SavepointId;
}

[CRepr]
public struct TRANSACTION_NOTIFICATION_PROPAGATE_ARGUMENT
{
	public uint32 PropagationCookie;
	public Guid UOW;
	public Guid TmIdentity;
	public uint32 BufferLength;
}

[CRepr]
public struct TRANSACTION_NOTIFICATION_MARSHAL_ARGUMENT
{
	public uint32 MarshalCookie;
	public Guid UOW;
}

[CRepr]
public struct KCRM_MARSHAL_HEADER
{
	public uint32 VersionMajor;
	public uint32 VersionMinor;
	public uint32 NumProtocols;
	public uint32 Unused;
}

[CRepr]
public struct KCRM_TRANSACTION_BLOB
{
	public Guid UOW;
	public Guid TmIdentity;
	public uint32 IsolationLevel;
	public uint32 IsolationFlags;
	public uint32 Timeout;
	public char16[64] Description;
}

[CRepr]
public struct KCRM_PROTOCOL_BLOB
{
	public Guid ProtocolId;
	public uint32 StaticInfoLength;
	public uint32 TransactionIdInfoLength;
	public uint32 Unused1;
	public uint32 Unused2;
}

[CRepr]
public struct DISK_SPACE_INFORMATION
{
	public uint64 ActualTotalAllocationUnits;
	public uint64 ActualAvailableAllocationUnits;
	public uint64 ActualPoolUnavailableAllocationUnits;
	public uint64 CallerTotalAllocationUnits;
	public uint64 CallerAvailableAllocationUnits;
	public uint64 CallerPoolUnavailableAllocationUnits;
	public uint64 UsedAllocationUnits;
	public uint64 TotalReservedAllocationUnits;
	public uint64 VolumeStorageReserveAllocationUnits;
	public uint64 AvailableCommittedAllocationUnits;
	public uint64 PoolAvailableAllocationUnits;
	public uint32 SectorsPerAllocationUnit;
	public uint32 BytesPerSector;
}

[CRepr]
public struct WIN32_FILE_ATTRIBUTE_DATA
{
	public uint32 dwFileAttributes;
	public FILETIME ftCreationTime;
	public FILETIME ftLastAccessTime;
	public FILETIME ftLastWriteTime;
	public uint32 nFileSizeHigh;
	public uint32 nFileSizeLow;
}

[CRepr]
public struct BY_HANDLE_FILE_INFORMATION
{
	public uint32 dwFileAttributes;
	public FILETIME ftCreationTime;
	public FILETIME ftLastAccessTime;
	public FILETIME ftLastWriteTime;
	public uint32 dwVolumeSerialNumber;
	public uint32 nFileSizeHigh;
	public uint32 nFileSizeLow;
	public uint32 nNumberOfLinks;
	public uint32 nFileIndexHigh;
	public uint32 nFileIndexLow;
}

[CRepr]
public struct CREATEFILE2_EXTENDED_PARAMETERS
{
	public uint32 dwSize;
	public uint32 dwFileAttributes;
	public uint32 dwFileFlags;
	public uint32 dwSecurityQosFlags;
	public SECURITY_ATTRIBUTES* lpSecurityAttributes;
	public HANDLE hTemplateFile;
}

[CRepr]
public struct WIN32_FIND_STREAM_DATA
{
	public LARGE_INTEGER StreamSize;
	public char16[296] cStreamName;
}

[CRepr]
public struct VS_FIXEDFILEINFO
{
	public uint32 dwSignature;
	public uint32 dwStrucVersion;
	public uint32 dwFileVersionMS;
	public uint32 dwFileVersionLS;
	public uint32 dwProductVersionMS;
	public uint32 dwProductVersionLS;
	public uint32 dwFileFlagsMask;
	public VS_FIXEDFILEINFO_FILE_FLAGS dwFileFlags;
	public VS_FIXEDFILEINFO_FILE_OS dwFileOS;
	public VS_FIXEDFILEINFO_FILE_TYPE dwFileType;
	public VS_FIXEDFILEINFO_FILE_SUBTYPE dwFileSubtype;
	public uint32 dwFileDateMS;
	public uint32 dwFileDateLS;
}

[CRepr]
public struct NTMS_ASYNC_IO
{
	public Guid OperationId;
	public Guid EventId;
	public uint32 dwOperationType;
	public uint32 dwResult;
	public uint32 dwAsyncState;
	public HANDLE hEvent;
	public BOOL bOnStateChange;
}

[CRepr]
public struct NTMS_MOUNT_INFORMATION
{
	public uint32 dwSize;
	public void* lpReserved;
}

[CRepr]
public struct NTMS_ALLOCATION_INFORMATION
{
	public uint32 dwSize;
	public void* lpReserved;
	public Guid AllocatedFrom;
}

[CRepr]
public struct NTMS_DRIVEINFORMATIONA
{
	public uint32 Number;
	public NtmsDriveState State;
	public Guid DriveType;
	public CHAR[64] szDeviceName;
	public CHAR[32] szSerialNumber;
	public CHAR[32] szRevision;
	public uint16 ScsiPort;
	public uint16 ScsiBus;
	public uint16 ScsiTarget;
	public uint16 ScsiLun;
	public uint32 dwMountCount;
	public SYSTEMTIME LastCleanedTs;
	public Guid SavedPartitionId;
	public Guid Library;
	public Guid Reserved;
	public uint32 dwDeferDismountDelay;
}

[CRepr]
public struct NTMS_DRIVEINFORMATIONW
{
	public uint32 Number;
	public NtmsDriveState State;
	public Guid DriveType;
	public char16[64] szDeviceName;
	public char16[32] szSerialNumber;
	public char16[32] szRevision;
	public uint16 ScsiPort;
	public uint16 ScsiBus;
	public uint16 ScsiTarget;
	public uint16 ScsiLun;
	public uint32 dwMountCount;
	public SYSTEMTIME LastCleanedTs;
	public Guid SavedPartitionId;
	public Guid Library;
	public Guid Reserved;
	public uint32 dwDeferDismountDelay;
}

[CRepr]
public struct NTMS_LIBRARYINFORMATION
{
	public NtmsLibraryType LibraryType;
	public Guid CleanerSlot;
	public Guid CleanerSlotDefault;
	public BOOL LibrarySupportsDriveCleaning;
	public BOOL BarCodeReaderInstalled;
	public NtmsInventoryMethod InventoryMethod;
	public uint32 dwCleanerUsesRemaining;
	public uint32 FirstDriveNumber;
	public uint32 dwNumberOfDrives;
	public uint32 FirstSlotNumber;
	public uint32 dwNumberOfSlots;
	public uint32 FirstDoorNumber;
	public uint32 dwNumberOfDoors;
	public uint32 FirstPortNumber;
	public uint32 dwNumberOfPorts;
	public uint32 FirstChangerNumber;
	public uint32 dwNumberOfChangers;
	public uint32 dwNumberOfMedia;
	public uint32 dwNumberOfMediaTypes;
	public uint32 dwNumberOfLibRequests;
	public Guid Reserved;
	public BOOL AutoRecovery;
	public NtmsLibraryFlags dwFlags;
}

[CRepr]
public struct NTMS_CHANGERINFORMATIONA
{
	public uint32 Number;
	public Guid ChangerType;
	public CHAR[32] szSerialNumber;
	public CHAR[32] szRevision;
	public CHAR[64] szDeviceName;
	public uint16 ScsiPort;
	public uint16 ScsiBus;
	public uint16 ScsiTarget;
	public uint16 ScsiLun;
	public Guid Library;
}

[CRepr]
public struct NTMS_CHANGERINFORMATIONW
{
	public uint32 Number;
	public Guid ChangerType;
	public char16[32] szSerialNumber;
	public char16[32] szRevision;
	public char16[64] szDeviceName;
	public uint16 ScsiPort;
	public uint16 ScsiBus;
	public uint16 ScsiTarget;
	public uint16 ScsiLun;
	public Guid Library;
}

[CRepr]
public struct NTMS_STORAGESLOTINFORMATION
{
	public uint32 Number;
	public uint32 State;
	public Guid Library;
}

[CRepr]
public struct NTMS_IEDOORINFORMATION
{
	public uint32 Number;
	public NtmsDoorState State;
	public uint16 MaxOpenSecs;
	public Guid Library;
}

[CRepr]
public struct NTMS_IEPORTINFORMATION
{
	public uint32 Number;
	public NtmsPortContent Content;
	public NtmsPortPosition Position;
	public uint16 MaxExtendSecs;
	public Guid Library;
}

[CRepr]
public struct NTMS_PMIDINFORMATIONA
{
	public Guid CurrentLibrary;
	public Guid MediaPool;
	public Guid Location;
	public uint32 LocationType;
	public Guid MediaType;
	public Guid HomeSlot;
	public CHAR[64] szBarCode;
	public NtmsBarCodeState BarCodeState;
	public CHAR[32] szSequenceNumber;
	public NtmsMediaState MediaState;
	public uint32 dwNumberOfPartitions;
	public uint32 dwMediaTypeCode;
	public uint32 dwDensityCode;
	public Guid MountedPartition;
}

[CRepr]
public struct NTMS_PMIDINFORMATIONW
{
	public Guid CurrentLibrary;
	public Guid MediaPool;
	public Guid Location;
	public uint32 LocationType;
	public Guid MediaType;
	public Guid HomeSlot;
	public char16[64] szBarCode;
	public NtmsBarCodeState BarCodeState;
	public char16[32] szSequenceNumber;
	public NtmsMediaState MediaState;
	public uint32 dwNumberOfPartitions;
	public uint32 dwMediaTypeCode;
	public uint32 dwDensityCode;
	public Guid MountedPartition;
}

[CRepr]
public struct NTMS_LMIDINFORMATION
{
	public Guid MediaPool;
	public uint32 dwNumberOfPartitions;
}

[CRepr]
public struct NTMS_PARTITIONINFORMATIONA
{
	public Guid PhysicalMedia;
	public Guid LogicalMedia;
	public NtmsPartitionState State;
	public uint16 Side;
	public uint32 dwOmidLabelIdLength;
	public uint8[255] OmidLabelId;
	public CHAR[64] szOmidLabelType;
	public CHAR[256] szOmidLabelInfo;
	public uint32 dwMountCount;
	public uint32 dwAllocateCount;
	public LARGE_INTEGER Capacity;
}

[CRepr]
public struct NTMS_PARTITIONINFORMATIONW
{
	public Guid PhysicalMedia;
	public Guid LogicalMedia;
	public NtmsPartitionState State;
	public uint16 Side;
	public uint32 dwOmidLabelIdLength;
	public uint8[255] OmidLabelId;
	public char16[64] szOmidLabelType;
	public char16[256] szOmidLabelInfo;
	public uint32 dwMountCount;
	public uint32 dwAllocateCount;
	public LARGE_INTEGER Capacity;
}

[CRepr]
public struct NTMS_MEDIAPOOLINFORMATION
{
	public uint32 PoolType;
	public Guid MediaType;
	public Guid Parent;
	public uint32 AllocationPolicy;
	public uint32 DeallocationPolicy;
	public uint32 dwMaxAllocates;
	public uint32 dwNumberOfPhysicalMedia;
	public uint32 dwNumberOfLogicalMedia;
	public uint32 dwNumberOfMediaPools;
}

[CRepr]
public struct NTMS_MEDIATYPEINFORMATION
{
	public uint32 MediaType;
	public uint32 NumberOfSides;
	public NtmsReadWriteCharacteristics ReadWriteCharacteristics;
	public FILE_DEVICE_TYPE DeviceType;
}

[CRepr]
public struct NTMS_DRIVETYPEINFORMATIONA
{
	public CHAR[128] szVendor;
	public CHAR[128] szProduct;
	public uint32 NumberOfHeads;
	public FILE_DEVICE_TYPE DeviceType;
}

[CRepr]
public struct NTMS_DRIVETYPEINFORMATIONW
{
	public char16[128] szVendor;
	public char16[128] szProduct;
	public uint32 NumberOfHeads;
	public FILE_DEVICE_TYPE DeviceType;
}

[CRepr]
public struct NTMS_CHANGERTYPEINFORMATIONA
{
	public CHAR[128] szVendor;
	public CHAR[128] szProduct;
	public uint32 DeviceType;
}

[CRepr]
public struct NTMS_CHANGERTYPEINFORMATIONW
{
	public char16[128] szVendor;
	public char16[128] szProduct;
	public uint32 DeviceType;
}

[CRepr]
public struct NTMS_LIBREQUESTINFORMATIONA
{
	public NtmsLmOperation OperationCode;
	public uint32 OperationOption;
	public NtmsLmState State;
	public Guid PartitionId;
	public Guid DriveId;
	public Guid PhysMediaId;
	public Guid Library;
	public Guid SlotId;
	public SYSTEMTIME TimeQueued;
	public SYSTEMTIME TimeCompleted;
	public CHAR[64] szApplication;
	public CHAR[64] szUser;
	public CHAR[64] szComputer;
	public uint32 dwErrorCode;
	public Guid WorkItemId;
	public uint32 dwPriority;
}

[CRepr]
public struct NTMS_LIBREQUESTINFORMATIONW
{
	public NtmsLmOperation OperationCode;
	public uint32 OperationOption;
	public NtmsLmState State;
	public Guid PartitionId;
	public Guid DriveId;
	public Guid PhysMediaId;
	public Guid Library;
	public Guid SlotId;
	public SYSTEMTIME TimeQueued;
	public SYSTEMTIME TimeCompleted;
	public char16[64] szApplication;
	public char16[64] szUser;
	public char16[64] szComputer;
	public uint32 dwErrorCode;
	public Guid WorkItemId;
	public uint32 dwPriority;
}

[CRepr]
public struct NTMS_OPREQUESTINFORMATIONA
{
	public NtmsOpreqCommand Request;
	public SYSTEMTIME Submitted;
	public NtmsOpreqState State;
	public CHAR[256] szMessage;
	public NtmsObjectsTypes Arg1Type;
	public Guid Arg1;
	public NtmsObjectsTypes Arg2Type;
	public Guid Arg2;
	public CHAR[64] szApplication;
	public CHAR[64] szUser;
	public CHAR[64] szComputer;
}

[CRepr]
public struct NTMS_OPREQUESTINFORMATIONW
{
	public NtmsOpreqCommand Request;
	public SYSTEMTIME Submitted;
	public NtmsOpreqState State;
	public char16[256] szMessage;
	public NtmsObjectsTypes Arg1Type;
	public Guid Arg1;
	public NtmsObjectsTypes Arg2Type;
	public Guid Arg2;
	public char16[64] szApplication;
	public char16[64] szUser;
	public char16[64] szComputer;
}

[CRepr]
public struct NTMS_COMPUTERINFORMATION
{
	public uint32 dwLibRequestPurgeTime;
	public uint32 dwOpRequestPurgeTime;
	public uint32 dwLibRequestFlags;
	public uint32 dwOpRequestFlags;
	public uint32 dwMediaPoolPolicy;
}

[CRepr]
public struct NTMS_OBJECTINFORMATIONA
{
	[CRepr, Union]
	public struct _Info_e__Union
	{
		public NTMS_DRIVEINFORMATIONA Drive;
		public NTMS_DRIVETYPEINFORMATIONA DriveType;
		public NTMS_LIBRARYINFORMATION Library;
		public NTMS_CHANGERINFORMATIONA Changer;
		public NTMS_CHANGERTYPEINFORMATIONA ChangerType;
		public NTMS_STORAGESLOTINFORMATION StorageSlot;
		public NTMS_IEDOORINFORMATION IEDoor;
		public NTMS_IEPORTINFORMATION IEPort;
		public NTMS_PMIDINFORMATIONA PhysicalMedia;
		public NTMS_LMIDINFORMATION LogicalMedia;
		public NTMS_PARTITIONINFORMATIONA Partition;
		public NTMS_MEDIAPOOLINFORMATION MediaPool;
		public NTMS_MEDIATYPEINFORMATION MediaType;
		public NTMS_LIBREQUESTINFORMATIONA LibRequest;
		public NTMS_OPREQUESTINFORMATIONA OpRequest;
		public NTMS_COMPUTERINFORMATION Computer;
	}
	public uint32 dwSize;
	public NtmsObjectsTypes dwType;
	public SYSTEMTIME Created;
	public SYSTEMTIME Modified;
	public Guid ObjectGuid;
	public BOOL Enabled;
	public NtmsOperationalState dwOperationalState;
	public CHAR[64] szName;
	public CHAR[127] szDescription;
	public _Info_e__Union Info;
}

[CRepr]
public struct NTMS_OBJECTINFORMATIONW
{
	[CRepr, Union]
	public struct _Info_e__Union
	{
		public NTMS_DRIVEINFORMATIONW Drive;
		public NTMS_DRIVETYPEINFORMATIONW DriveType;
		public NTMS_LIBRARYINFORMATION Library;
		public NTMS_CHANGERINFORMATIONW Changer;
		public NTMS_CHANGERTYPEINFORMATIONW ChangerType;
		public NTMS_STORAGESLOTINFORMATION StorageSlot;
		public NTMS_IEDOORINFORMATION IEDoor;
		public NTMS_IEPORTINFORMATION IEPort;
		public NTMS_PMIDINFORMATIONW PhysicalMedia;
		public NTMS_LMIDINFORMATION LogicalMedia;
		public NTMS_PARTITIONINFORMATIONW Partition;
		public NTMS_MEDIAPOOLINFORMATION MediaPool;
		public NTMS_MEDIATYPEINFORMATION MediaType;
		public NTMS_LIBREQUESTINFORMATIONW LibRequest;
		public NTMS_OPREQUESTINFORMATIONW OpRequest;
		public NTMS_COMPUTERINFORMATION Computer;
	}
	public uint32 dwSize;
	public NtmsObjectsTypes dwType;
	public SYSTEMTIME Created;
	public SYSTEMTIME Modified;
	public Guid ObjectGuid;
	public BOOL Enabled;
	public NtmsOperationalState dwOperationalState;
	public char16[64] szName;
	public char16[127] szDescription;
	public _Info_e__Union Info;
}

[CRepr]
public struct NTMS_I1_LIBRARYINFORMATION
{
	public uint32 LibraryType;
	public Guid CleanerSlot;
	public Guid CleanerSlotDefault;
	public BOOL LibrarySupportsDriveCleaning;
	public BOOL BarCodeReaderInstalled;
	public uint32 InventoryMethod;
	public uint32 dwCleanerUsesRemaining;
	public uint32 FirstDriveNumber;
	public uint32 dwNumberOfDrives;
	public uint32 FirstSlotNumber;
	public uint32 dwNumberOfSlots;
	public uint32 FirstDoorNumber;
	public uint32 dwNumberOfDoors;
	public uint32 FirstPortNumber;
	public uint32 dwNumberOfPorts;
	public uint32 FirstChangerNumber;
	public uint32 dwNumberOfChangers;
	public uint32 dwNumberOfMedia;
	public uint32 dwNumberOfMediaTypes;
	public uint32 dwNumberOfLibRequests;
	public Guid Reserved;
}

[CRepr]
public struct NTMS_I1_LIBREQUESTINFORMATIONA
{
	public uint32 OperationCode;
	public uint32 OperationOption;
	public uint32 State;
	public Guid PartitionId;
	public Guid DriveId;
	public Guid PhysMediaId;
	public Guid Library;
	public Guid SlotId;
	public SYSTEMTIME TimeQueued;
	public SYSTEMTIME TimeCompleted;
	public CHAR[64] szApplication;
	public CHAR[64] szUser;
	public CHAR[64] szComputer;
}

[CRepr]
public struct NTMS_I1_LIBREQUESTINFORMATIONW
{
	public uint32 OperationCode;
	public uint32 OperationOption;
	public uint32 State;
	public Guid PartitionId;
	public Guid DriveId;
	public Guid PhysMediaId;
	public Guid Library;
	public Guid SlotId;
	public SYSTEMTIME TimeQueued;
	public SYSTEMTIME TimeCompleted;
	public char16[64] szApplication;
	public char16[64] szUser;
	public char16[64] szComputer;
}

[CRepr]
public struct NTMS_I1_PMIDINFORMATIONA
{
	public Guid CurrentLibrary;
	public Guid MediaPool;
	public Guid Location;
	public uint32 LocationType;
	public Guid MediaType;
	public Guid HomeSlot;
	public CHAR[64] szBarCode;
	public uint32 BarCodeState;
	public CHAR[32] szSequenceNumber;
	public uint32 MediaState;
	public uint32 dwNumberOfPartitions;
}

[CRepr]
public struct NTMS_I1_PMIDINFORMATIONW
{
	public Guid CurrentLibrary;
	public Guid MediaPool;
	public Guid Location;
	public uint32 LocationType;
	public Guid MediaType;
	public Guid HomeSlot;
	public char16[64] szBarCode;
	public uint32 BarCodeState;
	public char16[32] szSequenceNumber;
	public uint32 MediaState;
	public uint32 dwNumberOfPartitions;
}

[CRepr]
public struct NTMS_I1_PARTITIONINFORMATIONA
{
	public Guid PhysicalMedia;
	public Guid LogicalMedia;
	public uint32 State;
	public uint16 Side;
	public uint32 dwOmidLabelIdLength;
	public uint8[255] OmidLabelId;
	public CHAR[64] szOmidLabelType;
	public CHAR[256] szOmidLabelInfo;
	public uint32 dwMountCount;
	public uint32 dwAllocateCount;
}

[CRepr]
public struct NTMS_I1_PARTITIONINFORMATIONW
{
	public Guid PhysicalMedia;
	public Guid LogicalMedia;
	public uint32 State;
	public uint16 Side;
	public uint32 dwOmidLabelIdLength;
	public uint8[255] OmidLabelId;
	public char16[64] szOmidLabelType;
	public char16[256] szOmidLabelInfo;
	public uint32 dwMountCount;
	public uint32 dwAllocateCount;
}

[CRepr]
public struct NTMS_I1_OPREQUESTINFORMATIONA
{
	public uint32 Request;
	public SYSTEMTIME Submitted;
	public uint32 State;
	public CHAR[127] szMessage;
	public uint32 Arg1Type;
	public Guid Arg1;
	public uint32 Arg2Type;
	public Guid Arg2;
	public CHAR[64] szApplication;
	public CHAR[64] szUser;
	public CHAR[64] szComputer;
}

[CRepr]
public struct NTMS_I1_OPREQUESTINFORMATIONW
{
	public uint32 Request;
	public SYSTEMTIME Submitted;
	public uint32 State;
	public char16[127] szMessage;
	public uint32 Arg1Type;
	public Guid Arg1;
	public uint32 Arg2Type;
	public Guid Arg2;
	public char16[64] szApplication;
	public char16[64] szUser;
	public char16[64] szComputer;
}

[CRepr]
public struct NTMS_I1_OBJECTINFORMATIONA
{
	[CRepr, Union]
	public struct _Info_e__Union
	{
		public NTMS_DRIVEINFORMATIONA Drive;
		public NTMS_DRIVETYPEINFORMATIONA DriveType;
		public NTMS_I1_LIBRARYINFORMATION Library;
		public NTMS_CHANGERINFORMATIONA Changer;
		public NTMS_CHANGERTYPEINFORMATIONA ChangerType;
		public NTMS_STORAGESLOTINFORMATION StorageSlot;
		public NTMS_IEDOORINFORMATION IEDoor;
		public NTMS_IEPORTINFORMATION IEPort;
		public NTMS_I1_PMIDINFORMATIONA PhysicalMedia;
		public NTMS_LMIDINFORMATION LogicalMedia;
		public NTMS_I1_PARTITIONINFORMATIONA Partition;
		public NTMS_MEDIAPOOLINFORMATION MediaPool;
		public NTMS_MEDIATYPEINFORMATION MediaType;
		public NTMS_I1_LIBREQUESTINFORMATIONA LibRequest;
		public NTMS_I1_OPREQUESTINFORMATIONA OpRequest;
	}
	public uint32 dwSize;
	public uint32 dwType;
	public SYSTEMTIME Created;
	public SYSTEMTIME Modified;
	public Guid ObjectGuid;
	public BOOL Enabled;
	public uint32 dwOperationalState;
	public CHAR[64] szName;
	public CHAR[127] szDescription;
	public _Info_e__Union Info;
}

[CRepr]
public struct NTMS_I1_OBJECTINFORMATIONW
{
	[CRepr, Union]
	public struct _Info_e__Union
	{
		public NTMS_DRIVEINFORMATIONW Drive;
		public NTMS_DRIVETYPEINFORMATIONW DriveType;
		public NTMS_I1_LIBRARYINFORMATION Library;
		public NTMS_CHANGERINFORMATIONW Changer;
		public NTMS_CHANGERTYPEINFORMATIONW ChangerType;
		public NTMS_STORAGESLOTINFORMATION StorageSlot;
		public NTMS_IEDOORINFORMATION IEDoor;
		public NTMS_IEPORTINFORMATION IEPort;
		public NTMS_I1_PMIDINFORMATIONW PhysicalMedia;
		public NTMS_LMIDINFORMATION LogicalMedia;
		public NTMS_I1_PARTITIONINFORMATIONW Partition;
		public NTMS_MEDIAPOOLINFORMATION MediaPool;
		public NTMS_MEDIATYPEINFORMATION MediaType;
		public NTMS_I1_LIBREQUESTINFORMATIONW LibRequest;
		public NTMS_I1_OPREQUESTINFORMATIONW OpRequest;
	}
	public uint32 dwSize;
	public uint32 dwType;
	public SYSTEMTIME Created;
	public SYSTEMTIME Modified;
	public Guid ObjectGuid;
	public BOOL Enabled;
	public uint32 dwOperationalState;
	public char16[64] szName;
	public char16[127] szDescription;
	public _Info_e__Union Info;
}

[CRepr]
public struct NTMS_FILESYSTEM_INFO
{
	public char16[64] FileSystemType;
	public char16[256] VolumeName;
	public uint32 SerialNumber;
}

[CRepr]
public struct NTMS_NOTIFICATIONINFORMATION
{
	public NtmsNotificationOperations dwOperation;
	public Guid ObjectId;
}

[CRepr]
public struct MediaLabelInfo
{
	public char16[64] LabelType;
	public uint32 LabelIDSize;
	public uint8[256] LabelID;
	public char16[256] LabelAppDescr;
}

[CRepr]
public struct CLS_LSN
{
	public uint64 Internal;
}

[CRepr]
public struct CLFS_NODE_ID
{
	public uint32 cType;
	public uint32 cbNode;
}

[CRepr]
public struct CLS_WRITE_ENTRY
{
	public void* Buffer;
	public uint32 ByteLength;
}

[CRepr]
public struct CLS_INFORMATION
{
	public int64 TotalAvailable;
	public int64 CurrentAvailable;
	public int64 TotalReservation;
	public uint64 BaseFileSize;
	public uint64 ContainerSize;
	public uint32 TotalContainers;
	public uint32 FreeContainers;
	public uint32 TotalClients;
	public uint32 Attributes;
	public uint32 FlushThreshold;
	public uint32 SectorSize;
	public CLS_LSN MinArchiveTailLsn;
	public CLS_LSN BaseLsn;
	public CLS_LSN LastFlushedLsn;
	public CLS_LSN LastLsn;
	public CLS_LSN RestartLsn;
	public Guid Identity;
}

[CRepr]
public struct CLFS_LOG_NAME_INFORMATION
{
	public uint16 NameLengthInBytes;
	public char16* Name mut => &Name_impl;
	private char16[ANYSIZE_ARRAY] Name_impl;
}

[CRepr]
public struct CLFS_STREAM_ID_INFORMATION
{
	public uint8 StreamIdentifier;
}

[CRepr]
public struct CLFS_PHYSICAL_LSN_INFORMATION
{
	public uint8 StreamIdentifier;
	public CLS_LSN VirtualLsn;
	public CLS_LSN PhysicalLsn;
}

[CRepr]
public struct CLS_CONTAINER_INFORMATION
{
	public uint32 FileAttributes;
	public uint64 CreationTime;
	public uint64 LastAccessTime;
	public uint64 LastWriteTime;
	public int64 ContainerSize;
	public uint32 FileNameActualLength;
	public uint32 FileNameLength;
	public char16[256] FileName;
	public uint32 State;
	public uint32 PhysicalContainerId;
	public uint32 LogicalContainerId;
}

[CRepr]
public struct CLS_IO_STATISTICS_HEADER
{
	public uint8 ubMajorVersion;
	public uint8 ubMinorVersion;
	public CLFS_IOSTATS_CLASS eStatsClass;
	public uint16 cbLength;
	public uint32 coffData;
}

[CRepr]
public struct CLS_IO_STATISTICS
{
	public CLS_IO_STATISTICS_HEADER hdrIoStats;
	public uint64 cFlush;
	public uint64 cbFlush;
	public uint64 cMetaFlush;
	public uint64 cbMetaFlush;
}

[CRepr]
public struct CLS_SCAN_CONTEXT
{
	public CLFS_NODE_ID cidNode;
	public HANDLE hLog;
	public uint32 cIndex;
	public uint32 cContainers;
	public uint32 cContainersReturned;
	public uint8 eScanMode;
	public CLS_CONTAINER_INFORMATION* pinfoContainer;
}

[CRepr]
public struct CLS_ARCHIVE_DESCRIPTOR
{
	public uint64 coffLow;
	public uint64 coffHigh;
	public CLS_CONTAINER_INFORMATION infoContainer;
}

[CRepr]
public struct CLFS_MGMT_POLICY
{
	[CRepr, Union]
	public struct _PolicyParameters_e__Union
	{
		[CRepr]
		public struct _NewContainerExtension_e__Struct
		{
			public uint16 ExtensionLengthInBytes;
			public char16* ExtensionString mut => &ExtensionString_impl;
			private char16[ANYSIZE_ARRAY] ExtensionString_impl;
		}
		[CRepr]
		public struct _NewContainerPrefix_e__Struct
		{
			public uint16 PrefixLengthInBytes;
			public char16* PrefixString mut => &PrefixString_impl;
			private char16[ANYSIZE_ARRAY] PrefixString_impl;
		}
		[CRepr]
		public struct _AutoShrink_e__Struct
		{
			public uint32 Percentage;
		}
		[CRepr]
		public struct _GrowthRate_e__Struct
		{
			public uint32 AbsoluteGrowthInContainers;
			public uint32 RelativeGrowthPercentage;
		}
		[CRepr]
		public struct _MinimumSize_e__Struct
		{
			public uint32 Containers;
		}
		[CRepr]
		public struct _NewContainerSuffix_e__Struct
		{
			public uint64 NextContainerSuffix;
		}
		[CRepr]
		public struct _LogTail_e__Struct
		{
			public uint32 MinimumAvailablePercentage;
			public uint32 MinimumAvailableContainers;
		}
		[CRepr]
		public struct _MaximumSize_e__Struct
		{
			public uint32 Containers;
		}
		[CRepr]
		public struct _AutoGrow_e__Struct
		{
			public uint32 Enabled;
		}
		[CRepr]
		public struct _NewContainerSize_e__Struct
		{
			public uint32 SizeInBytes;
		}
		public _MaximumSize_e__Struct MaximumSize;
		public _MinimumSize_e__Struct MinimumSize;
		public _NewContainerSize_e__Struct NewContainerSize;
		public _GrowthRate_e__Struct GrowthRate;
		public _LogTail_e__Struct LogTail;
		public _AutoShrink_e__Struct AutoShrink;
		public _AutoGrow_e__Struct AutoGrow;
		public _NewContainerPrefix_e__Struct NewContainerPrefix;
		public _NewContainerSuffix_e__Struct NewContainerSuffix;
		public _NewContainerExtension_e__Struct NewContainerExtension;
	}
	public uint32 Version;
	public uint32 LengthInBytes;
	public uint32 PolicyFlags;
	public CLFS_MGMT_POLICY_TYPE PolicyType;
	public _PolicyParameters_e__Union PolicyParameters;
}

[CRepr]
public struct CLFS_MGMT_NOTIFICATION
{
	public CLFS_MGMT_NOTIFICATION_TYPE Notification;
	public CLS_LSN Lsn;
	public uint16 LogIsPinned;
}

[CRepr]
public struct LOG_MANAGEMENT_CALLBACKS
{
	public void* CallbackContext;
	public PLOG_TAIL_ADVANCE_CALLBACK AdvanceTailCallback;
	public PLOG_FULL_HANDLER_CALLBACK LogFullHandlerCallback;
	public PLOG_UNPINNED_CALLBACK LogUnpinnedCallback;
}

[CRepr]
public struct DISKQUOTA_USER_INFORMATION
{
	public int64 QuotaUsed;
	public int64 QuotaThreshold;
	public int64 QuotaLimit;
}

[CRepr]
public struct EFS_CERTIFICATE_BLOB
{
	public uint32 dwCertEncodingType;
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct EFS_HASH_BLOB
{
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct EFS_RPC_BLOB
{
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct EFS_PIN_BLOB
{
	public uint32 cbPadding;
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct EFS_KEY_INFO
{
	public uint32 dwVersion;
	public uint32 Entropy;
	public uint32 Algorithm;
	public uint32 KeyLength;
}

[CRepr]
public struct EFS_COMPATIBILITY_INFO
{
	public uint32 EfsVersion;
}

[CRepr]
public struct EFS_VERSION_INFO
{
	public uint32 EfsVersion;
	public uint32 SubVersion;
}

[CRepr]
public struct EFS_DECRYPTION_STATUS_INFO
{
	public uint32 dwDecryptionError;
	public uint32 dwHashOffset;
	public uint32 cbHash;
}

[CRepr]
public struct EFS_ENCRYPTION_STATUS_INFO
{
	public BOOL bHasCurrentKey;
	public uint32 dwEncryptionError;
}

[CRepr]
public struct ENCRYPTION_CERTIFICATE
{
	public uint32 cbTotalLength;
	public SID* pUserSid;
	public EFS_CERTIFICATE_BLOB* pCertBlob;
}

[CRepr]
public struct ENCRYPTION_CERTIFICATE_HASH
{
	public uint32 cbTotalLength;
	public SID* pUserSid;
	public EFS_HASH_BLOB* pHash;
	public PWSTR lpDisplayInformation;
}

[CRepr]
public struct ENCRYPTION_CERTIFICATE_HASH_LIST
{
	public uint32 nCert_Hash;
	public ENCRYPTION_CERTIFICATE_HASH** pUsers;
}

[CRepr]
public struct ENCRYPTION_CERTIFICATE_LIST
{
	public uint32 nUsers;
	public ENCRYPTION_CERTIFICATE** pUsers;
}

[CRepr]
public struct ENCRYPTED_FILE_METADATA_SIGNATURE
{
	public uint32 dwEfsAccessType;
	public ENCRYPTION_CERTIFICATE_HASH_LIST* pCertificatesAdded;
	public ENCRYPTION_CERTIFICATE* pEncryptionCertificate;
	public EFS_RPC_BLOB* pEfsStreamSignature;
}

[CRepr]
public struct ENCRYPTION_PROTECTOR
{
	public uint32 cbTotalLength;
	public SID* pUserSid;
	public PWSTR lpProtectorDescriptor;
}

[CRepr]
public struct ENCRYPTION_PROTECTOR_LIST
{
	public uint32 nProtectors;
	public ENCRYPTION_PROTECTOR** pProtectors;
}

[CRepr]
public struct WIM_ENTRY_INFO
{
	public uint32 WimEntryInfoSize;
	public uint32 WimType;
	public LARGE_INTEGER DataSourceId;
	public Guid WimGuid;
	public PWSTR WimPath;
	public uint32 WimIndex;
	public uint32 Flags;
}

[CRepr]
public struct WIM_EXTERNAL_FILE_INFO
{
	public LARGE_INTEGER DataSourceId;
	public uint8[20] ResourceHash;
	public uint32 Flags;
}

[CRepr]
public struct WOF_FILE_COMPRESSION_INFO_V0
{
	public uint32 Algorithm;
}

[CRepr]
public struct WOF_FILE_COMPRESSION_INFO_V1
{
	public uint32 Algorithm;
	public uint32 Flags;
}

[CRepr, Packed(4)]
public struct TXF_ID
{
	[CRepr, Packed(4)]
	public struct _Anonymous_e__Struct
	{
		public int64 LowPart;
		public int64 HighPart;
	}
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Packed(4)]
public struct TXF_LOG_RECORD_BASE
{
	public uint16 Version;
	public TXF_LOG_RECORD_TYPE RecordType;
	public uint32 RecordLength;
}

[CRepr, Packed(4)]
public struct TXF_LOG_RECORD_WRITE
{
	public uint16 Version;
	public uint16 RecordType;
	public uint32 RecordLength;
	public uint32 Flags;
	public TXF_ID TxfFileId;
	public Guid KtmGuid;
	public int64 ByteOffsetInFile;
	public uint32 NumBytesWritten;
	public uint32 ByteOffsetInStructure;
	public uint32 FileNameLength;
	public uint32 FileNameByteOffsetInStructure;
}

[CRepr, Packed(4)]
public struct TXF_LOG_RECORD_TRUNCATE
{
	public uint16 Version;
	public uint16 RecordType;
	public uint32 RecordLength;
	public uint32 Flags;
	public TXF_ID TxfFileId;
	public Guid KtmGuid;
	public int64 NewFileSize;
	public uint32 FileNameLength;
	public uint32 FileNameByteOffsetInStructure;
}

[CRepr, Packed(4)]
public struct TXF_LOG_RECORD_AFFECTED_FILE
{
	public uint16 Version;
	public uint32 RecordLength;
	public uint32 Flags;
	public TXF_ID TxfFileId;
	public Guid KtmGuid;
	public uint32 FileNameLength;
	public uint32 FileNameByteOffsetInStructure;
}

[CRepr]
public struct VOLUME_FAILOVER_SET
{
	public uint32 NumberOfDisks;
	public uint32* DiskNumbers mut => &DiskNumbers_impl;
	private uint32[ANYSIZE_ARRAY] DiskNumbers_impl;
}

[CRepr]
public struct VOLUME_NUMBER
{
	public uint32 VolumeNumber;
	public char16[8] VolumeManagerName;
}

[CRepr]
public struct VOLUME_LOGICAL_OFFSET
{
	public int64 LogicalOffset;
}

[CRepr]
public struct VOLUME_PHYSICAL_OFFSET
{
	public uint32 DiskNumber;
	public int64 Offset;
}

[CRepr]
public struct VOLUME_PHYSICAL_OFFSETS
{
	public uint32 NumberOfPhysicalOffsets;
	public VOLUME_PHYSICAL_OFFSET* PhysicalOffset mut => &PhysicalOffset_impl;
	private VOLUME_PHYSICAL_OFFSET[ANYSIZE_ARRAY] PhysicalOffset_impl;
}

[CRepr]
public struct VOLUME_READ_PLEX_INPUT
{
	public LARGE_INTEGER ByteOffset;
	public uint32 Length;
	public uint32 PlexNumber;
}

[CRepr]
public struct VOLUME_SET_GPT_ATTRIBUTES_INFORMATION
{
	public uint64 GptAttributes;
	public BOOLEAN RevertOnClose;
	public BOOLEAN ApplyToAllConnectedVolumes;
	public uint16 Reserved1;
	public uint32 Reserved2;
}

[CRepr]
public struct VOLUME_GET_BC_PROPERTIES_INPUT
{
	public uint32 Version;
	public uint32 Reserved1;
	public uint64 LowestByteOffset;
	public uint64 HighestByteOffset;
	public uint32 AccessType;
	public uint32 AccessMode;
}

[CRepr]
public struct VOLUME_GET_BC_PROPERTIES_OUTPUT
{
	public uint32 MaximumRequestsPerPeriod;
	public uint32 MinimumPeriod;
	public uint64 MaximumRequestSize;
	public uint32 EstimatedTimePerRequest;
	public uint32 NumOutStandingRequests;
	public uint64 RequestSize;
}

[CRepr]
public struct VOLUME_ALLOCATE_BC_STREAM_INPUT
{
	public uint32 Version;
	public uint32 RequestsPerPeriod;
	public uint32 Period;
	public BOOLEAN RetryFailures;
	public BOOLEAN Discardable;
	public BOOLEAN[2] Reserved1;
	public uint64 LowestByteOffset;
	public uint64 HighestByteOffset;
	public uint32 AccessType;
	public uint32 AccessMode;
}

[CRepr]
public struct VOLUME_ALLOCATE_BC_STREAM_OUTPUT
{
	public uint64 RequestSize;
	public uint32 NumOutStandingRequests;
}

[CRepr]
public struct FILE_EXTENT
{
	public uint64 VolumeOffset;
	public uint64 ExtentLength;
}

[CRepr]
public struct VOLUME_CRITICAL_IO
{
	public uint32 AccessType;
	public uint32 ExtentsCount;
	public FILE_EXTENT* Extents mut => &Extents_impl;
	private FILE_EXTENT[ANYSIZE_ARRAY] Extents_impl;
}

[CRepr]
public struct VOLUME_ALLOCATION_HINT_INPUT
{
	public uint32 ClusterSize;
	public uint32 NumberOfClusters;
	public int64 StartingClusterNumber;
}

[CRepr]
public struct VOLUME_ALLOCATION_HINT_OUTPUT
{
	public uint32* Bitmap mut => &Bitmap_impl;
	private uint32[ANYSIZE_ARRAY] Bitmap_impl;
}

[CRepr]
public struct VOLUME_SHRINK_INFO
{
	public uint64 VolumeSize;
}

[CRepr]
public struct SHARE_INFO_0
{
	public PWSTR shi0_netname;
}

[CRepr]
public struct SHARE_INFO_1
{
	public PWSTR shi1_netname;
	public SHARE_TYPE shi1_type;
	public PWSTR shi1_remark;
}

[CRepr]
public struct SHARE_INFO_2
{
	public PWSTR shi2_netname;
	public SHARE_TYPE shi2_type;
	public PWSTR shi2_remark;
	public SHARE_INFO_PERMISSIONS shi2_permissions;
	public uint32 shi2_max_uses;
	public uint32 shi2_current_uses;
	public PWSTR shi2_path;
	public PWSTR shi2_passwd;
}

[CRepr]
public struct SHARE_INFO_501
{
	public PWSTR shi501_netname;
	public SHARE_TYPE shi501_type;
	public PWSTR shi501_remark;
	public uint32 shi501_flags;
}

[CRepr]
public struct SHARE_INFO_502
{
	public PWSTR shi502_netname;
	public SHARE_TYPE shi502_type;
	public PWSTR shi502_remark;
	public SHARE_INFO_PERMISSIONS shi502_permissions;
	public uint32 shi502_max_uses;
	public uint32 shi502_current_uses;
	public PWSTR shi502_path;
	public PWSTR shi502_passwd;
	public uint32 shi502_reserved;
	public PSECURITY_DESCRIPTOR shi502_security_descriptor;
}

[CRepr]
public struct SHARE_INFO_503
{
	public PWSTR shi503_netname;
	public SHARE_TYPE shi503_type;
	public PWSTR shi503_remark;
	public SHARE_INFO_PERMISSIONS shi503_permissions;
	public uint32 shi503_max_uses;
	public uint32 shi503_current_uses;
	public PWSTR shi503_path;
	public PWSTR shi503_passwd;
	public PWSTR shi503_servername;
	public uint32 shi503_reserved;
	public PSECURITY_DESCRIPTOR shi503_security_descriptor;
}

[CRepr]
public struct SHARE_INFO_1004
{
	public PWSTR shi1004_remark;
}

[CRepr]
public struct SHARE_INFO_1005
{
	public uint32 shi1005_flags;
}

[CRepr]
public struct SHARE_INFO_1006
{
	public uint32 shi1006_max_uses;
}

[CRepr]
public struct SHARE_INFO_1501
{
	public uint32 shi1501_reserved;
	public PSECURITY_DESCRIPTOR shi1501_security_descriptor;
}

[CRepr]
public struct SHARE_INFO_1503
{
	public Guid shi1503_sharefilter;
}

[CRepr]
public struct SERVER_ALIAS_INFO_0
{
	public PWSTR srvai0_alias;
	public PWSTR srvai0_target;
	public BOOLEAN srvai0_default;
	public uint32 srvai0_reserved;
}

[CRepr]
public struct SESSION_INFO_0
{
	public PWSTR sesi0_cname;
}

[CRepr]
public struct SESSION_INFO_1
{
	public PWSTR sesi1_cname;
	public PWSTR sesi1_username;
	public uint32 sesi1_num_opens;
	public uint32 sesi1_time;
	public uint32 sesi1_idle_time;
	public SESSION_INFO_USER_FLAGS sesi1_user_flags;
}

[CRepr]
public struct SESSION_INFO_2
{
	public PWSTR sesi2_cname;
	public PWSTR sesi2_username;
	public uint32 sesi2_num_opens;
	public uint32 sesi2_time;
	public uint32 sesi2_idle_time;
	public SESSION_INFO_USER_FLAGS sesi2_user_flags;
	public PWSTR sesi2_cltype_name;
}

[CRepr]
public struct SESSION_INFO_10
{
	public PWSTR sesi10_cname;
	public PWSTR sesi10_username;
	public uint32 sesi10_time;
	public uint32 sesi10_idle_time;
}

[CRepr]
public struct SESSION_INFO_502
{
	public PWSTR sesi502_cname;
	public PWSTR sesi502_username;
	public uint32 sesi502_num_opens;
	public uint32 sesi502_time;
	public uint32 sesi502_idle_time;
	public SESSION_INFO_USER_FLAGS sesi502_user_flags;
	public PWSTR sesi502_cltype_name;
	public PWSTR sesi502_transport;
}

[CRepr]
public struct CONNECTION_INFO_0
{
	public uint32 coni0_id;
}

[CRepr]
public struct CONNECTION_INFO_1
{
	public uint32 coni1_id;
	public SHARE_TYPE coni1_type;
	public uint32 coni1_num_opens;
	public uint32 coni1_num_users;
	public uint32 coni1_time;
	public PWSTR coni1_username;
	public PWSTR coni1_netname;
}

[CRepr]
public struct FILE_INFO_2
{
	public uint32 fi2_id;
}

[CRepr]
public struct FILE_INFO_3
{
	public uint32 fi3_id;
	public FILE_INFO_FLAGS_PERMISSIONS fi3_permissions;
	public uint32 fi3_num_locks;
	public PWSTR fi3_pathname;
	public PWSTR fi3_username;
}

[CRepr]
public struct SERVER_CERTIFICATE_INFO_0
{
	public PWSTR srvci0_name;
	public PWSTR srvci0_subject;
	public PWSTR srvci0_issuer;
	public PWSTR srvci0_thumbprint;
	public PWSTR srvci0_friendlyname;
	public PWSTR srvci0_notbefore;
	public PWSTR srvci0_notafter;
	public PWSTR srvci0_storelocation;
	public PWSTR srvci0_storename;
	public PWSTR srvci0_renewalchain;
	public uint32 srvci0_type;
	public uint32 srvci0_flags;
}

[CRepr]
public struct STAT_WORKSTATION_0
{
	public LARGE_INTEGER StatisticsStartTime;
	public LARGE_INTEGER BytesReceived;
	public LARGE_INTEGER SmbsReceived;
	public LARGE_INTEGER PagingReadBytesRequested;
	public LARGE_INTEGER NonPagingReadBytesRequested;
	public LARGE_INTEGER CacheReadBytesRequested;
	public LARGE_INTEGER NetworkReadBytesRequested;
	public LARGE_INTEGER BytesTransmitted;
	public LARGE_INTEGER SmbsTransmitted;
	public LARGE_INTEGER PagingWriteBytesRequested;
	public LARGE_INTEGER NonPagingWriteBytesRequested;
	public LARGE_INTEGER CacheWriteBytesRequested;
	public LARGE_INTEGER NetworkWriteBytesRequested;
	public uint32 InitiallyFailedOperations;
	public uint32 FailedCompletionOperations;
	public uint32 ReadOperations;
	public uint32 RandomReadOperations;
	public uint32 ReadSmbs;
	public uint32 LargeReadSmbs;
	public uint32 SmallReadSmbs;
	public uint32 WriteOperations;
	public uint32 RandomWriteOperations;
	public uint32 WriteSmbs;
	public uint32 LargeWriteSmbs;
	public uint32 SmallWriteSmbs;
	public uint32 RawReadsDenied;
	public uint32 RawWritesDenied;
	public uint32 NetworkErrors;
	public uint32 Sessions;
	public uint32 FailedSessions;
	public uint32 Reconnects;
	public uint32 CoreConnects;
	public uint32 Lanman20Connects;
	public uint32 Lanman21Connects;
	public uint32 LanmanNtConnects;
	public uint32 ServerDisconnects;
	public uint32 HungSessions;
	public uint32 UseCount;
	public uint32 FailedUseCount;
	public uint32 CurrentCommands;
}

[CRepr]
public struct STAT_SERVER_0
{
	public uint32 sts0_start;
	public uint32 sts0_fopens;
	public uint32 sts0_devopens;
	public uint32 sts0_jobsqueued;
	public uint32 sts0_sopens;
	public uint32 sts0_stimedout;
	public uint32 sts0_serrorout;
	public uint32 sts0_pwerrors;
	public uint32 sts0_permerrors;
	public uint32 sts0_syserrors;
	public uint32 sts0_bytessent_low;
	public uint32 sts0_bytessent_high;
	public uint32 sts0_bytesrcvd_low;
	public uint32 sts0_bytesrcvd_high;
	public uint32 sts0_avresponse;
	public uint32 sts0_reqbufneed;
	public uint32 sts0_bigbufneed;
}

[CRepr]
public struct FH_OVERLAPPED
{
	public uint Internal;
	public uint InternalHigh;
	public uint32 Offset;
	public uint32 OffsetHigh;
	public HANDLE hEvent;
	public PFN_IO_COMPLETION pfnCompletion;
	public uint Reserved1;
	public uint Reserved2;
	public uint Reserved3;
	public uint Reserved4;
}

[CRepr]
public struct FIO_CONTEXT
{
	public uint32 m_dwTempHack;
	public uint32 m_dwSignature;
	public HANDLE m_hFile;
	public uint32 m_dwLinesOffset;
	public uint32 m_dwHeaderLength;
}

[CRepr]
public struct NAME_CACHE_CONTEXT
{
	public uint32 m_dwSignature;
}

[CRepr]
public struct IORING_BUFFER_INFO
{
	public void* Address;
	public uint32 Length;
}

[CRepr]
public struct IORING_REGISTERED_BUFFER
{
	public uint32 BufferIndex;
	public uint32 Offset;
}

[CRepr]
public struct HIORING__
{
	public int32 unused;
}

[CRepr]
public struct IORING_CREATE_FLAGS
{
	public IORING_CREATE_REQUIRED_FLAGS Required;
	public IORING_CREATE_ADVISORY_FLAGS Advisory;
}

[CRepr]
public struct IORING_INFO
{
	public IORING_VERSION IoRingVersion;
	public IORING_CREATE_FLAGS Flags;
	public uint32 SubmissionQueueSize;
	public uint32 CompletionQueueSize;
}

[CRepr]
public struct IORING_CAPABILITIES
{
	public IORING_VERSION MaxVersion;
	public uint32 MaxSubmissionQueueSize;
	public uint32 MaxCompletionQueueSize;
	public IORING_FEATURE_FLAGS FeatureFlags;
}

[CRepr]
public struct IORING_HANDLE_REF
{
	[CRepr, Union]
	public struct HandleUnion
	{
		public HANDLE Handle;
		public uint32 Index;
	}
	public IORING_REF_KIND Kind;
	public HandleUnion Handle;
}

[CRepr]
public struct IORING_BUFFER_REF
{
	[CRepr, Union]
	public struct BufferUnion
	{
		public void* Address;
		public IORING_REGISTERED_BUFFER IndexAndOffset;
	}
	public IORING_REF_KIND Kind;
	public BufferUnion Buffer;
}

[CRepr]
public struct IORING_CQE
{
	public uint UserData;
	public HRESULT ResultCode;
	public uint Information;
}

[CRepr]
public struct FILE_ID_128
{
	public uint8[16] Identifier;
}

[CRepr]
public struct FILE_NOTIFY_INFORMATION
{
	public uint32 NextEntryOffset;
	public FILE_ACTION Action;
	public uint32 FileNameLength;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr]
public struct FILE_NOTIFY_EXTENDED_INFORMATION
{
	public uint32 NextEntryOffset;
	public FILE_ACTION Action;
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastModificationTime;
	public LARGE_INTEGER LastChangeTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER AllocatedLength;
	public LARGE_INTEGER FileSize;
	public uint32 FileAttributes;
	public uint32 ReparsePointTag;
	public LARGE_INTEGER FileId;
	public LARGE_INTEGER ParentFileId;
	public uint32 FileNameLength;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr, Union]
public struct FILE_SEGMENT_ELEMENT
{
	public void* Buffer;
	public uint64 Alignment;
}

[CRepr]
public struct REPARSE_GUID_DATA_BUFFER
{
	[CRepr]
	public struct _GenericReparseBuffer_e__Struct
	{
		public uint8* DataBuffer mut => &DataBuffer_impl;
		private uint8[ANYSIZE_ARRAY] DataBuffer_impl;
	}
	public uint32 ReparseTag;
	public uint16 ReparseDataLength;
	public uint16 Reserved;
	public Guid ReparseGuid;
	public _GenericReparseBuffer_e__Struct GenericReparseBuffer;
}

[CRepr]
public struct TAPE_ERASE
{
	public ERASE_TAPE_TYPE Type;
	public BOOLEAN Immediate;
}

[CRepr]
public struct TAPE_PREPARE
{
	public PREPARE_TAPE_OPERATION Operation;
	public BOOLEAN Immediate;
}

[CRepr]
public struct TAPE_WRITE_MARKS
{
	public TAPEMARK_TYPE Type;
	public uint32 Count;
	public BOOLEAN Immediate;
}

[CRepr]
public struct TAPE_GET_POSITION
{
	public TAPE_POSITION_TYPE Type;
	public uint32 Partition;
	public LARGE_INTEGER Offset;
}

[CRepr]
public struct TAPE_SET_POSITION
{
	public TAPE_POSITION_METHOD Method;
	public uint32 Partition;
	public LARGE_INTEGER Offset;
	public BOOLEAN Immediate;
}

[CRepr]
public struct OFSTRUCT
{
	public uint8 cBytes;
	public uint8 fFixedDisk;
	public uint16 nErrCode;
	public uint16 Reserved1;
	public uint16 Reserved2;
	public CHAR[128] szPathName;
}

[CRepr]
public struct WIN32_STREAM_ID
{
	public WIN_STREAM_ID dwStreamId;
	public uint32 dwStreamAttributes;
	public LARGE_INTEGER Size;
	public uint32 dwStreamNameSize;
	public char16* cStreamName mut => &cStreamName_impl;
	private char16[ANYSIZE_ARRAY] cStreamName_impl;
}

[CRepr]
public struct COPYFILE2_MESSAGE
{
	[CRepr, Union]
	public struct _Info_e__Union
	{
		[CRepr]
		public struct _Error_e__Struct
		{
			public COPYFILE2_COPY_PHASE CopyPhase;
			public uint32 dwStreamNumber;
			public HRESULT hrFailure;
			public uint32 dwReserved;
			public ULARGE_INTEGER uliChunkNumber;
			public ULARGE_INTEGER uliStreamSize;
			public ULARGE_INTEGER uliStreamBytesTransferred;
			public ULARGE_INTEGER uliTotalFileSize;
			public ULARGE_INTEGER uliTotalBytesTransferred;
		}
		[CRepr]
		public struct _StreamFinished_e__Struct
		{
			public uint32 dwStreamNumber;
			public uint32 dwReserved;
			public HANDLE hSourceFile;
			public HANDLE hDestinationFile;
			public ULARGE_INTEGER uliStreamSize;
			public ULARGE_INTEGER uliStreamBytesTransferred;
			public ULARGE_INTEGER uliTotalFileSize;
			public ULARGE_INTEGER uliTotalBytesTransferred;
		}
		[CRepr]
		public struct _ChunkFinished_e__Struct
		{
			public uint32 dwStreamNumber;
			public uint32 dwFlags;
			public HANDLE hSourceFile;
			public HANDLE hDestinationFile;
			public ULARGE_INTEGER uliChunkNumber;
			public ULARGE_INTEGER uliChunkSize;
			public ULARGE_INTEGER uliStreamSize;
			public ULARGE_INTEGER uliStreamBytesTransferred;
			public ULARGE_INTEGER uliTotalFileSize;
			public ULARGE_INTEGER uliTotalBytesTransferred;
		}
		[CRepr]
		public struct _PollContinue_e__Struct
		{
			public uint32 dwReserved;
		}
		[CRepr]
		public struct _ChunkStarted_e__Struct
		{
			public uint32 dwStreamNumber;
			public uint32 dwReserved;
			public HANDLE hSourceFile;
			public HANDLE hDestinationFile;
			public ULARGE_INTEGER uliChunkNumber;
			public ULARGE_INTEGER uliChunkSize;
			public ULARGE_INTEGER uliStreamSize;
			public ULARGE_INTEGER uliTotalFileSize;
		}
		[CRepr]
		public struct _StreamStarted_e__Struct
		{
			public uint32 dwStreamNumber;
			public uint32 dwReserved;
			public HANDLE hSourceFile;
			public HANDLE hDestinationFile;
			public ULARGE_INTEGER uliStreamSize;
			public ULARGE_INTEGER uliTotalFileSize;
		}
		public _ChunkStarted_e__Struct ChunkStarted;
		public _ChunkFinished_e__Struct ChunkFinished;
		public _StreamStarted_e__Struct StreamStarted;
		public _StreamFinished_e__Struct StreamFinished;
		public _PollContinue_e__Struct PollContinue;
		public _Error_e__Struct Error;
	}
	public COPYFILE2_MESSAGE_TYPE Type;
	public uint32 dwPadding;
	public _Info_e__Union Info;
}

[CRepr]
public struct COPYFILE2_EXTENDED_PARAMETERS
{
	public uint32 dwSize;
	public uint32 dwCopyFlags;
	public BOOL* pfCancel;
	public PCOPYFILE2_PROGRESS_ROUTINE pProgressRoutine;
	public void* pvCallbackContext;
}

[CRepr]
public struct COPYFILE2_EXTENDED_PARAMETERS_V2
{
	public uint32 dwSize;
	public uint32 dwCopyFlags;
	public BOOL* pfCancel;
	public PCOPYFILE2_PROGRESS_ROUTINE pProgressRoutine;
	public void* pvCallbackContext;
	public uint32 dwCopyFlagsV2;
	public uint32 ioDesiredSize;
	public uint32 ioDesiredRate;
	public void*[8] reserved;
}

[CRepr]
public struct FILE_BASIC_INFO
{
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER LastWriteTime;
	public LARGE_INTEGER ChangeTime;
	public uint32 FileAttributes;
}

[CRepr]
public struct FILE_STANDARD_INFO
{
	public LARGE_INTEGER AllocationSize;
	public LARGE_INTEGER EndOfFile;
	public uint32 NumberOfLinks;
	public BOOLEAN DeletePending;
	public BOOLEAN Directory;
}

[CRepr]
public struct FILE_NAME_INFO
{
	public uint32 FileNameLength;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr]
public struct FILE_RENAME_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public BOOLEAN ReplaceIfExists;
		public uint32 Flags;
	}
	public using _Anonymous_e__Union Anonymous;
	public HANDLE RootDirectory;
	public uint32 FileNameLength;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr]
public struct FILE_ALLOCATION_INFO
{
	public LARGE_INTEGER AllocationSize;
}

[CRepr]
public struct FILE_END_OF_FILE_INFO
{
	public LARGE_INTEGER EndOfFile;
}

[CRepr]
public struct FILE_STREAM_INFO
{
	public uint32 NextEntryOffset;
	public uint32 StreamNameLength;
	public LARGE_INTEGER StreamSize;
	public LARGE_INTEGER StreamAllocationSize;
	public char16* StreamName mut => &StreamName_impl;
	private char16[ANYSIZE_ARRAY] StreamName_impl;
}

[CRepr]
public struct FILE_COMPRESSION_INFO
{
	public LARGE_INTEGER CompressedFileSize;
	public uint16 CompressionFormat;
	public uint8 CompressionUnitShift;
	public uint8 ChunkShift;
	public uint8 ClusterShift;
	public uint8[3] Reserved;
}

[CRepr]
public struct FILE_ATTRIBUTE_TAG_INFO
{
	public uint32 FileAttributes;
	public uint32 ReparseTag;
}

[CRepr]
public struct FILE_ID_BOTH_DIR_INFO
{
	public uint32 NextEntryOffset;
	public uint32 FileIndex;
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER LastWriteTime;
	public LARGE_INTEGER ChangeTime;
	public LARGE_INTEGER EndOfFile;
	public LARGE_INTEGER AllocationSize;
	public uint32 FileAttributes;
	public uint32 FileNameLength;
	public uint32 EaSize;
	public int8 ShortNameLength;
	public char16[12] ShortName;
	public LARGE_INTEGER FileId;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr]
public struct FILE_FULL_DIR_INFO
{
	public uint32 NextEntryOffset;
	public uint32 FileIndex;
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER LastWriteTime;
	public LARGE_INTEGER ChangeTime;
	public LARGE_INTEGER EndOfFile;
	public LARGE_INTEGER AllocationSize;
	public uint32 FileAttributes;
	public uint32 FileNameLength;
	public uint32 EaSize;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr]
public struct FILE_IO_PRIORITY_HINT_INFO
{
	public PRIORITY_HINT PriorityHint;
}

[CRepr]
public struct FILE_ALIGNMENT_INFO
{
	public uint32 AlignmentRequirement;
}

[CRepr]
public struct FILE_STORAGE_INFO
{
	public uint32 LogicalBytesPerSector;
	public uint32 PhysicalBytesPerSectorForAtomicity;
	public uint32 PhysicalBytesPerSectorForPerformance;
	public uint32 FileSystemEffectivePhysicalBytesPerSectorForAtomicity;
	public uint32 Flags;
	public uint32 ByteOffsetForSectorAlignment;
	public uint32 ByteOffsetForPartitionAlignment;
}

[CRepr]
public struct FILE_ID_INFO
{
	public uint64 VolumeSerialNumber;
	public FILE_ID_128 FileId;
}

[CRepr]
public struct FILE_ID_EXTD_DIR_INFO
{
	public uint32 NextEntryOffset;
	public uint32 FileIndex;
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER LastWriteTime;
	public LARGE_INTEGER ChangeTime;
	public LARGE_INTEGER EndOfFile;
	public LARGE_INTEGER AllocationSize;
	public uint32 FileAttributes;
	public uint32 FileNameLength;
	public uint32 EaSize;
	public uint32 ReparsePointTag;
	public FILE_ID_128 FileId;
	public char16* FileName mut => &FileName_impl;
	private char16[ANYSIZE_ARRAY] FileName_impl;
}

[CRepr]
public struct FILE_REMOTE_PROTOCOL_INFO
{
	[CRepr, Union]
	public struct _ProtocolSpecific_e__Union
	{
		[CRepr]
		public struct _Smb2_e__Struct
		{
			[CRepr]
			public struct _Server_e__Struct
			{
				public uint32 Capabilities;
			}
			[CRepr]
			public struct _Share_e__Struct
			{
				public uint32 Capabilities;
				public uint32 CachingFlags;
			}
			public _Server_e__Struct Server;
			public _Share_e__Struct Share;
		}
		public _Smb2_e__Struct Smb2;
		public uint32[16] Reserved;
	}
	[CRepr]
	public struct _GenericReserved_e__Struct
	{
		public uint32[8] Reserved;
	}
	public uint16 StructureVersion;
	public uint16 StructureSize;
	public uint32 Protocol;
	public uint16 ProtocolMajorVersion;
	public uint16 ProtocolMinorVersion;
	public uint16 ProtocolRevision;
	public uint16 Reserved;
	public uint32 Flags;
	public _GenericReserved_e__Struct GenericReserved;
	public _ProtocolSpecific_e__Union ProtocolSpecific;
}

[CRepr]
public struct FILE_ID_DESCRIPTOR
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public LARGE_INTEGER FileId;
		public Guid ObjectId;
		public FILE_ID_128 ExtendedFileId;
	}
	public uint32 dwSize;
	public FILE_ID_TYPE Type;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region COM Types
[CRepr]struct IDiskQuotaUser : IUnknown
{
	public new const Guid IID = .(0x7988b574, 0xec89, 0x11cf, 0x9c, 0x00, 0x00, 0xaa, 0x00, 0xa1, 0x4f, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulID) GetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAccountContainer, uint32 cchAccountContainer, PWSTR pszLogonName, uint32 cchLogonName, PWSTR pszDisplayName, uint32 cchDisplayName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetSidLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbSidBuffer, uint32 cbSidBuffer) GetSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllThreshold) GetQuotaThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText, uint32 cchText) GetQuotaThresholdText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllLimit) GetQuotaLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText, uint32 cchText) GetQuotaLimitText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllUsed) GetQuotaUsed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText, uint32 cchText) GetQuotaUsedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pbQuotaInfo, uint32 cbQuotaInfo) GetQuotaInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 llThreshold, BOOL fWriteThrough) SetQuotaThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 llLimit, BOOL fWriteThrough) SetQuotaLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Invalidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetAccountStatus;
	}


	public HRESULT GetID(uint32* pulID) mut => VT.[Friend]GetID(&this, pulID);

	public HRESULT GetName(PWSTR pszAccountContainer, uint32 cchAccountContainer, PWSTR pszLogonName, uint32 cchLogonName, PWSTR pszDisplayName, uint32 cchDisplayName) mut => VT.[Friend]GetName(&this, pszAccountContainer, cchAccountContainer, pszLogonName, cchLogonName, pszDisplayName, cchDisplayName);

	public HRESULT GetSidLength(uint32* pdwLength) mut => VT.[Friend]GetSidLength(&this, pdwLength);

	public HRESULT GetSid(uint8* pbSidBuffer, uint32 cbSidBuffer) mut => VT.[Friend]GetSid(&this, pbSidBuffer, cbSidBuffer);

	public HRESULT GetQuotaThreshold(int64* pllThreshold) mut => VT.[Friend]GetQuotaThreshold(&this, pllThreshold);

	public HRESULT GetQuotaThresholdText(PWSTR pszText, uint32 cchText) mut => VT.[Friend]GetQuotaThresholdText(&this, pszText, cchText);

	public HRESULT GetQuotaLimit(int64* pllLimit) mut => VT.[Friend]GetQuotaLimit(&this, pllLimit);

	public HRESULT GetQuotaLimitText(PWSTR pszText, uint32 cchText) mut => VT.[Friend]GetQuotaLimitText(&this, pszText, cchText);

	public HRESULT GetQuotaUsed(int64* pllUsed) mut => VT.[Friend]GetQuotaUsed(&this, pllUsed);

	public HRESULT GetQuotaUsedText(PWSTR pszText, uint32 cchText) mut => VT.[Friend]GetQuotaUsedText(&this, pszText, cchText);

	public HRESULT GetQuotaInformation(void* pbQuotaInfo, uint32 cbQuotaInfo) mut => VT.[Friend]GetQuotaInformation(&this, pbQuotaInfo, cbQuotaInfo);

	public HRESULT SetQuotaThreshold(int64 llThreshold, BOOL fWriteThrough) mut => VT.[Friend]SetQuotaThreshold(&this, llThreshold, fWriteThrough);

	public HRESULT SetQuotaLimit(int64 llLimit, BOOL fWriteThrough) mut => VT.[Friend]SetQuotaLimit(&this, llLimit, fWriteThrough);

	public HRESULT Invalidate() mut => VT.[Friend]Invalidate(&this);

	public HRESULT GetAccountStatus(uint32* pdwStatus) mut => VT.[Friend]GetAccountStatus(&this, pdwStatus);
}

[CRepr]struct IEnumDiskQuotaUsers : IUnknown
{
	public new const Guid IID = .(0x7988b577, 0xec89, 0x11cf, 0x9c, 0x00, 0x00, 0xaa, 0x00, 0xa1, 0x4f, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cUsers, IDiskQuotaUser** rgUsers, uint32* pcUsersFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cUsers) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDiskQuotaUsers** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cUsers, IDiskQuotaUser** rgUsers, uint32* pcUsersFetched) mut => VT.[Friend]Next(&this, cUsers, rgUsers, pcUsersFetched);

	public HRESULT Skip(uint32 cUsers) mut => VT.[Friend]Skip(&this, cUsers);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumDiskQuotaUsers** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IDiskQuotaUserBatch : IUnknown
{
	public new const Guid IID = .(0x7988b576, 0xec89, 0x11cf, 0x9c, 0x00, 0x00, 0xaa, 0x00, 0xa1, 0x4f, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDiskQuotaUser* pUser) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDiskQuotaUser* pUser) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlushToDisk;
	}


	public HRESULT Add(IDiskQuotaUser* pUser) mut => VT.[Friend]Add(&this, pUser);

	public HRESULT Remove(IDiskQuotaUser* pUser) mut => VT.[Friend]Remove(&this, pUser);

	public HRESULT RemoveAll() mut => VT.[Friend]RemoveAll(&this);

	public HRESULT FlushToDisk() mut => VT.[Friend]FlushToDisk(&this);
}

[CRepr]struct IDiskQuotaControl : IConnectionPointContainer
{
	public new const Guid IID = .(0x7988b572, 0xec89, 0x11cf, 0x9c, 0x00, 0x00, 0xaa, 0x00, 0xa1, 0x4f, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConnectionPointContainer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, BOOL bReadWrite) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwState) SetQuotaState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwState) GetQuotaState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetQuotaLogFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetQuotaLogFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 llThreshold) SetDefaultQuotaThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllThreshold) GetDefaultQuotaThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText, uint32 cchText) GetDefaultQuotaThresholdText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 llLimit) SetDefaultQuotaLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllLimit) GetDefaultQuotaLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText, uint32 cchText) GetDefaultQuotaLimitText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID pUserSid, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IDiskQuotaUser** ppUser) AddUserSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLogonName, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IDiskQuotaUser** ppUser) AddUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDiskQuotaUser* pUser) DeleteUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID pUserSid, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IDiskQuotaUser** ppUser) FindUserSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLogonName, IDiskQuotaUser** ppUser) FindUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID* rgpUserSids, uint32 cpSids, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IEnumDiskQuotaUsers** ppEnum) CreateEnumUsers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDiskQuotaUserBatch** ppBatch) CreateUserBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InvalidateSidNameCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDiskQuotaUser* pUser) GiveUserNameResolutionPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShutdownNameResolution;
	}


	public HRESULT Initialize(PWSTR pszPath, BOOL bReadWrite) mut => VT.[Friend]Initialize(&this, pszPath, bReadWrite);

	public HRESULT SetQuotaState(uint32 dwState) mut => VT.[Friend]SetQuotaState(&this, dwState);

	public HRESULT GetQuotaState(uint32* pdwState) mut => VT.[Friend]GetQuotaState(&this, pdwState);

	public HRESULT SetQuotaLogFlags(uint32 dwFlags) mut => VT.[Friend]SetQuotaLogFlags(&this, dwFlags);

	public HRESULT GetQuotaLogFlags(uint32* pdwFlags) mut => VT.[Friend]GetQuotaLogFlags(&this, pdwFlags);

	public HRESULT SetDefaultQuotaThreshold(int64 llThreshold) mut => VT.[Friend]SetDefaultQuotaThreshold(&this, llThreshold);

	public HRESULT GetDefaultQuotaThreshold(int64* pllThreshold) mut => VT.[Friend]GetDefaultQuotaThreshold(&this, pllThreshold);

	public HRESULT GetDefaultQuotaThresholdText(PWSTR pszText, uint32 cchText) mut => VT.[Friend]GetDefaultQuotaThresholdText(&this, pszText, cchText);

	public HRESULT SetDefaultQuotaLimit(int64 llLimit) mut => VT.[Friend]SetDefaultQuotaLimit(&this, llLimit);

	public HRESULT GetDefaultQuotaLimit(int64* pllLimit) mut => VT.[Friend]GetDefaultQuotaLimit(&this, pllLimit);

	public HRESULT GetDefaultQuotaLimitText(PWSTR pszText, uint32 cchText) mut => VT.[Friend]GetDefaultQuotaLimitText(&this, pszText, cchText);

	public HRESULT AddUserSid(PSID pUserSid, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IDiskQuotaUser** ppUser) mut => VT.[Friend]AddUserSid(&this, pUserSid, fNameResolution, ppUser);

	public HRESULT AddUserName(PWSTR pszLogonName, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IDiskQuotaUser** ppUser) mut => VT.[Friend]AddUserName(&this, pszLogonName, fNameResolution, ppUser);

	public HRESULT DeleteUser(IDiskQuotaUser* pUser) mut => VT.[Friend]DeleteUser(&this, pUser);

	public HRESULT FindUserSid(PSID pUserSid, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IDiskQuotaUser** ppUser) mut => VT.[Friend]FindUserSid(&this, pUserSid, fNameResolution, ppUser);

	public HRESULT FindUserName(PWSTR pszLogonName, IDiskQuotaUser** ppUser) mut => VT.[Friend]FindUserName(&this, pszLogonName, ppUser);

	public HRESULT CreateEnumUsers(PSID* rgpUserSids, uint32 cpSids, DISKQUOTA_USERNAME_RESOLVE fNameResolution, IEnumDiskQuotaUsers** ppEnum) mut => VT.[Friend]CreateEnumUsers(&this, rgpUserSids, cpSids, fNameResolution, ppEnum);

	public HRESULT CreateUserBatch(IDiskQuotaUserBatch** ppBatch) mut => VT.[Friend]CreateUserBatch(&this, ppBatch);

	public HRESULT InvalidateSidNameCache() mut => VT.[Friend]InvalidateSidNameCache(&this);

	public HRESULT GiveUserNameResolutionPriority(IDiskQuotaUser* pUser) mut => VT.[Friend]GiveUserNameResolutionPriority(&this, pUser);

	public HRESULT ShutdownNameResolution() mut => VT.[Friend]ShutdownNameResolution(&this);
}

[CRepr]struct IDiskQuotaEvents : IUnknown
{
	public new const Guid IID = .(0x7988b579, 0xec89, 0x11cf, 0x9c, 0x00, 0x00, 0xaa, 0x00, 0xa1, 0x4f, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDiskQuotaUser* pUser) OnUserNameChanged;
	}


	public HRESULT OnUserNameChanged(IDiskQuotaUser* pUser) mut => VT.[Friend]OnUserNameChanged(&this, pUser);
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SearchPathW(PWSTR lpPath, PWSTR lpFileName, PWSTR lpExtension, uint32 nBufferLength, char16* lpBuffer, PWSTR* lpFilePart);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SearchPathA(PSTR lpPath, PSTR lpFileName, PSTR lpExtension, uint32 nBufferLength, uint8* lpBuffer, PSTR* lpFilePart);
	public static uint32 SearchPath(PSTR lpPath, PSTR lpFileName, PSTR lpExtension, uint32 nBufferLength, uint8* lpBuffer, PSTR* lpFilePart) => SearchPathA(lpPath, lpFileName, lpExtension, nBufferLength, lpBuffer, lpFilePart);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CompareFileTime(FILETIME* lpFileTime1, FILETIME* lpFileTime2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryA(PSTR lpPathName, SECURITY_ATTRIBUTES* lpSecurityAttributes);
	public static BOOL CreateDirectory(PSTR lpPathName, SECURITY_ATTRIBUTES* lpSecurityAttributes) => CreateDirectoryA(lpPathName, lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryW(PWSTR lpPathName, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileA(PSTR lpFileName, FILE_ACCESS_FLAGS dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_CREATION_DISPOSITION dwCreationDisposition, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes, HANDLE hTemplateFile);
	public static HANDLE CreateFile(PSTR lpFileName, FILE_ACCESS_FLAGS dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_CREATION_DISPOSITION dwCreationDisposition, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes, HANDLE hTemplateFile) => CreateFileA(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileW(PWSTR lpFileName, FILE_ACCESS_FLAGS dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_CREATION_DISPOSITION dwCreationDisposition, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes, HANDLE hTemplateFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DefineDosDeviceW(DEFINE_DOS_DEVICE_FLAGS dwFlags, PWSTR lpDeviceName, PWSTR lpTargetPath);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFileA(PSTR lpFileName);
	public static BOOL DeleteFile(PSTR lpFileName) => DeleteFileA(lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFileW(PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteVolumeMountPointW(PWSTR lpszVolumeMountPoint);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FileTimeToLocalFileTime(FILETIME* lpFileTime, FILETIME* lpLocalFileTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindClose(FindFileHandle hFindFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindCloseChangeNotification(FindChangeNotificationHandle hChangeHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindChangeNotificationHandle FindFirstChangeNotificationA(PSTR lpPathName, BOOL bWatchSubtree, FILE_NOTIFY_CHANGE dwNotifyFilter);
	public static FindChangeNotificationHandle FindFirstChangeNotification(PSTR lpPathName, BOOL bWatchSubtree, FILE_NOTIFY_CHANGE dwNotifyFilter) => FindFirstChangeNotificationA(lpPathName, bWatchSubtree, dwNotifyFilter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindChangeNotificationHandle FindFirstChangeNotificationW(PWSTR lpPathName, BOOL bWatchSubtree, FILE_NOTIFY_CHANGE dwNotifyFilter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileHandle FindFirstFileA(PSTR lpFileName, WIN32_FIND_DATAA* lpFindFileData);
	public static FindFileHandle FindFirstFile(PSTR lpFileName, WIN32_FIND_DATAA* lpFindFileData) => FindFirstFileA(lpFileName, lpFindFileData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileHandle FindFirstFileW(PWSTR lpFileName, WIN32_FIND_DATAW* lpFindFileData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileHandle FindFirstFileExA(PSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, FIND_FIRST_EX_FLAGS dwAdditionalFlags);
	public static FindFileHandle FindFirstFileEx(PSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, FIND_FIRST_EX_FLAGS dwAdditionalFlags) => FindFirstFileExA(lpFileName, fInfoLevelId, lpFindFileData, fSearchOp, lpSearchFilter, dwAdditionalFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileHandle FindFirstFileExW(PWSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, FIND_FIRST_EX_FLAGS dwAdditionalFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindVolumeHandle FindFirstVolumeW(char16* lpszVolumeName, uint32 cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextChangeNotification(FindChangeNotificationHandle hChangeHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextFileA(FindFileHandle hFindFile, WIN32_FIND_DATAA* lpFindFileData);
	public static BOOL FindNextFile(FindFileHandle hFindFile, WIN32_FIND_DATAA* lpFindFileData) => FindNextFileA(hFindFile, lpFindFileData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextFileW(FindFileHandle hFindFile, WIN32_FIND_DATAW* lpFindFileData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextVolumeW(FindVolumeHandle hFindVolume, char16* lpszVolumeName, uint32 cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindVolumeClose(FindVolumeHandle hFindVolume);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlushFileBuffers(HANDLE hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDiskFreeSpaceA(PSTR lpRootPathName, uint32* lpSectorsPerCluster, uint32* lpBytesPerSector, uint32* lpNumberOfFreeClusters, uint32* lpTotalNumberOfClusters);
	public static BOOL GetDiskFreeSpace(PSTR lpRootPathName, uint32* lpSectorsPerCluster, uint32* lpBytesPerSector, uint32* lpNumberOfFreeClusters, uint32* lpTotalNumberOfClusters) => GetDiskFreeSpaceA(lpRootPathName, lpSectorsPerCluster, lpBytesPerSector, lpNumberOfFreeClusters, lpTotalNumberOfClusters);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDiskFreeSpaceW(PWSTR lpRootPathName, uint32* lpSectorsPerCluster, uint32* lpBytesPerSector, uint32* lpNumberOfFreeClusters, uint32* lpTotalNumberOfClusters);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDiskFreeSpaceExA(PSTR lpDirectoryName, ULARGE_INTEGER* lpFreeBytesAvailableToCaller, ULARGE_INTEGER* lpTotalNumberOfBytes, ULARGE_INTEGER* lpTotalNumberOfFreeBytes);
	public static BOOL GetDiskFreeSpaceEx(PSTR lpDirectoryName, ULARGE_INTEGER* lpFreeBytesAvailableToCaller, ULARGE_INTEGER* lpTotalNumberOfBytes, ULARGE_INTEGER* lpTotalNumberOfFreeBytes) => GetDiskFreeSpaceExA(lpDirectoryName, lpFreeBytesAvailableToCaller, lpTotalNumberOfBytes, lpTotalNumberOfFreeBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDiskFreeSpaceExW(PWSTR lpDirectoryName, ULARGE_INTEGER* lpFreeBytesAvailableToCaller, ULARGE_INTEGER* lpTotalNumberOfBytes, ULARGE_INTEGER* lpTotalNumberOfFreeBytes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDiskSpaceInformationA(PSTR rootPath, DISK_SPACE_INFORMATION* diskSpaceInfo);
	public static HRESULT GetDiskSpaceInformation(PSTR rootPath, DISK_SPACE_INFORMATION* diskSpaceInfo) => GetDiskSpaceInformationA(rootPath, diskSpaceInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDiskSpaceInformationW(PWSTR rootPath, DISK_SPACE_INFORMATION* diskSpaceInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDriveTypeA(PSTR lpRootPathName);
	public static uint32 GetDriveType(PSTR lpRootPathName) => GetDriveTypeA(lpRootPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDriveTypeW(PWSTR lpRootPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileAttributesA(PSTR lpFileName);
	public static uint32 GetFileAttributes(PSTR lpFileName) => GetFileAttributesA(lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileAttributesW(PWSTR lpFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileAttributesExA(PSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation);
	public static BOOL GetFileAttributesEx(PSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation) => GetFileAttributesExA(lpFileName, fInfoLevelId, lpFileInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileAttributesExW(PWSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileInformationByHandle(HANDLE hFile, BY_HANDLE_FILE_INFORMATION* lpFileInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileSize(HANDLE hFile, uint32* lpFileSizeHigh);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileSizeEx(HANDLE hFile, LARGE_INTEGER* lpFileSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileType(HANDLE hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFinalPathNameByHandleA(HANDLE hFile, uint8* lpszFilePath, uint32 cchFilePath, FILE_NAME dwFlags);
	public static uint32 GetFinalPathNameByHandle(HANDLE hFile, uint8* lpszFilePath, uint32 cchFilePath, FILE_NAME dwFlags) => GetFinalPathNameByHandleA(hFile, lpszFilePath, cchFilePath, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFinalPathNameByHandleW(HANDLE hFile, char16* lpszFilePath, uint32 cchFilePath, FILE_NAME dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileTime(HANDLE hFile, FILETIME* lpCreationTime, FILETIME* lpLastAccessTime, FILETIME* lpLastWriteTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFullPathNameW(PWSTR lpFileName, uint32 nBufferLength, char16* lpBuffer, PWSTR* lpFilePart);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFullPathNameA(PSTR lpFileName, uint32 nBufferLength, uint8* lpBuffer, PSTR* lpFilePart);
	public static uint32 GetFullPathName(PSTR lpFileName, uint32 nBufferLength, uint8* lpBuffer, PSTR* lpFilePart) => GetFullPathNameA(lpFileName, nBufferLength, lpBuffer, lpFilePart);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLogicalDrives();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLogicalDriveStringsW(uint32 nBufferLength, char16* lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLongPathNameA(PSTR lpszShortPath, uint8* lpszLongPath, uint32 cchBuffer);
	public static uint32 GetLongPathName(PSTR lpszShortPath, uint8* lpszLongPath, uint32 cchBuffer) => GetLongPathNameA(lpszShortPath, lpszLongPath, cchBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLongPathNameW(PWSTR lpszShortPath, char16* lpszLongPath, uint32 cchBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AreShortNamesEnabled(HANDLE Handle, BOOL* Enabled);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetShortPathNameW(PWSTR lpszLongPath, char16* lpszShortPath, uint32 cchBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTempFileNameW(PWSTR lpPathName, PWSTR lpPrefixString, uint32 uUnique, char16* lpTempFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumeInformationByHandleW(HANDLE hFile, char16* lpVolumeNameBuffer, uint32 nVolumeNameSize, uint32* lpVolumeSerialNumber, uint32* lpMaximumComponentLength, uint32* lpFileSystemFlags, char16* lpFileSystemNameBuffer, uint32 nFileSystemNameSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumeInformationW(PWSTR lpRootPathName, char16* lpVolumeNameBuffer, uint32 nVolumeNameSize, uint32* lpVolumeSerialNumber, uint32* lpMaximumComponentLength, uint32* lpFileSystemFlags, char16* lpFileSystemNameBuffer, uint32 nFileSystemNameSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumePathNameW(PWSTR lpszFileName, char16* lpszVolumePathName, uint32 cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LocalFileTimeToFileTime(FILETIME* lpLocalFileTime, FILETIME* lpFileTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LockFile(HANDLE hFile, uint32 dwFileOffsetLow, uint32 dwFileOffsetHigh, uint32 nNumberOfBytesToLockLow, uint32 nNumberOfBytesToLockHigh);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LockFileEx(HANDLE hFile, LOCK_FILE_FLAGS dwFlags, uint32 dwReserved, uint32 nNumberOfBytesToLockLow, uint32 nNumberOfBytesToLockHigh, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryDosDeviceW(PWSTR lpDeviceName, char16* lpTargetPath, uint32 ucchMax);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadFile(HANDLE hFile, void* lpBuffer, uint32 nNumberOfBytesToRead, uint32* lpNumberOfBytesRead, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadFileEx(HANDLE hFile, void* lpBuffer, uint32 nNumberOfBytesToRead, OVERLAPPED* lpOverlapped, LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadFileScatter(HANDLE hFile, FILE_SEGMENT_ELEMENT* aSegmentArray, uint32 nNumberOfBytesToRead, uint32* lpReserved, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveDirectoryA(PSTR lpPathName);
	public static BOOL RemoveDirectory(PSTR lpPathName) => RemoveDirectoryA(lpPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveDirectoryW(PWSTR lpPathName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEndOfFile(HANDLE hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileAttributesA(PSTR lpFileName, FILE_FLAGS_AND_ATTRIBUTES dwFileAttributes);
	public static BOOL SetFileAttributes(PSTR lpFileName, FILE_FLAGS_AND_ATTRIBUTES dwFileAttributes) => SetFileAttributesA(lpFileName, dwFileAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileAttributesW(PWSTR lpFileName, FILE_FLAGS_AND_ATTRIBUTES dwFileAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileInformationByHandle(HANDLE hFile, FILE_INFO_BY_HANDLE_CLASS FileInformationClass, void* lpFileInformation, uint32 dwBufferSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetFilePointer(HANDLE hFile, int32 lDistanceToMove, int32* lpDistanceToMoveHigh, SET_FILE_POINTER_MOVE_METHOD dwMoveMethod);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFilePointerEx(HANDLE hFile, LARGE_INTEGER liDistanceToMove, LARGE_INTEGER* lpNewFilePointer, SET_FILE_POINTER_MOVE_METHOD dwMoveMethod);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileTime(HANDLE hFile, FILETIME* lpCreationTime, FILETIME* lpLastAccessTime, FILETIME* lpLastWriteTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileValidData(HANDLE hFile, int64 ValidDataLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnlockFile(HANDLE hFile, uint32 dwFileOffsetLow, uint32 dwFileOffsetHigh, uint32 nNumberOfBytesToUnlockLow, uint32 nNumberOfBytesToUnlockHigh);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnlockFileEx(HANDLE hFile, uint32 dwReserved, uint32 nNumberOfBytesToUnlockLow, uint32 nNumberOfBytesToUnlockHigh, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteFile(HANDLE hFile, void* lpBuffer, uint32 nNumberOfBytesToWrite, uint32* lpNumberOfBytesWritten, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteFileEx(HANDLE hFile, void* lpBuffer, uint32 nNumberOfBytesToWrite, OVERLAPPED* lpOverlapped, LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteFileGather(HANDLE hFile, FILE_SEGMENT_ELEMENT* aSegmentArray, uint32 nNumberOfBytesToWrite, uint32* lpReserved, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTempPathW(uint32 nBufferLength, char16* lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumeNameForVolumeMountPointW(PWSTR lpszVolumeMountPoint, char16* lpszVolumeName, uint32 cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumePathNamesForVolumeNameW(PWSTR lpszVolumeName, char16* lpszVolumePathNames, uint32 cchBufferLength, uint32* lpcchReturnLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFile2(PWSTR lpFileName, FILE_ACCESS_FLAGS dwDesiredAccess, FILE_SHARE_MODE dwShareMode, FILE_CREATION_DISPOSITION dwCreationDisposition, CREATEFILE2_EXTENDED_PARAMETERS* pCreateExParams);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileIoOverlappedRange(HANDLE FileHandle, uint8* OverlappedRangeStart, uint32 Length);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCompressedFileSizeA(PSTR lpFileName, uint32* lpFileSizeHigh);
	public static uint32 GetCompressedFileSize(PSTR lpFileName, uint32* lpFileSizeHigh) => GetCompressedFileSizeA(lpFileName, lpFileSizeHigh);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCompressedFileSizeW(PWSTR lpFileName, uint32* lpFileSizeHigh);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindStreamHandle FindFirstStreamW(PWSTR lpFileName, STREAM_INFO_LEVELS InfoLevel, void* lpFindStreamData, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextStreamW(FindStreamHandle hFindStream, void* lpFindStreamData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AreFileApisANSI();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTempPathA(uint32 nBufferLength, uint8* lpBuffer);
	public static uint32 GetTempPath(uint32 nBufferLength, uint8* lpBuffer) => GetTempPathA(nBufferLength, lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileNameHandle FindFirstFileNameW(PWSTR lpFileName, uint32 dwFlags, uint32* StringLength, char16* LinkName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextFileNameW(FindFileNameHandle hFindStream, uint32* StringLength, char16* LinkName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumeInformationA(PSTR lpRootPathName, uint8* lpVolumeNameBuffer, uint32 nVolumeNameSize, uint32* lpVolumeSerialNumber, uint32* lpMaximumComponentLength, uint32* lpFileSystemFlags, uint8* lpFileSystemNameBuffer, uint32 nFileSystemNameSize);
	public static BOOL GetVolumeInformation(PSTR lpRootPathName, uint8* lpVolumeNameBuffer, uint32 nVolumeNameSize, uint32* lpVolumeSerialNumber, uint32* lpMaximumComponentLength, uint32* lpFileSystemFlags, uint8* lpFileSystemNameBuffer, uint32 nFileSystemNameSize) => GetVolumeInformationA(lpRootPathName, lpVolumeNameBuffer, nVolumeNameSize, lpVolumeSerialNumber, lpMaximumComponentLength, lpFileSystemFlags, lpFileSystemNameBuffer, nFileSystemNameSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTempFileNameA(PSTR lpPathName, PSTR lpPrefixString, uint32 uUnique, uint8* lpTempFileName);
	public static uint32 GetTempFileName(PSTR lpPathName, PSTR lpPrefixString, uint32 uUnique, uint8* lpTempFileName) => GetTempFileNameA(lpPathName, lpPrefixString, uUnique, lpTempFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetFileApisToOEM();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetFileApisToANSI();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTempPath2W(uint32 BufferLength, char16* Buffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTempPath2A(uint32 BufferLength, uint8* Buffer);
	public static uint32 GetTempPath2(uint32 BufferLength, uint8* Buffer) => GetTempPath2A(BufferLength, Buffer);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileFromAppW(PWSTR lpExistingFileName, PWSTR lpNewFileName, BOOL bFailIfExists);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryFromAppW(PWSTR lpPathName, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileFromAppW(PWSTR lpFileName, uint32 dwDesiredAccess, uint32 dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, uint32 dwCreationDisposition, uint32 dwFlagsAndAttributes, HANDLE hTemplateFile);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFile2FromAppW(PWSTR lpFileName, uint32 dwDesiredAccess, uint32 dwShareMode, uint32 dwCreationDisposition, CREATEFILE2_EXTENDED_PARAMETERS* pCreateExParams);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFileFromAppW(PWSTR lpFileName);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE FindFirstFileExFromAppW(PWSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, uint32 dwAdditionalFlags);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileAttributesExFromAppW(PWSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileFromAppW(PWSTR lpExistingFileName, PWSTR lpNewFileName);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveDirectoryFromAppW(PWSTR lpPathName);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReplaceFileFromAppW(PWSTR lpReplacedFileName, PWSTR lpReplacementFileName, PWSTR lpBackupFileName, uint32 dwReplaceFlags, void* lpExclude, void* lpReserved);

	[Import("api-ms-win-core-file-fromapp-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileAttributesFromAppW(PWSTR lpFileName, uint32 dwFileAttributes);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VER_FIND_FILE_STATUS VerFindFileA(VER_FIND_FILE_FLAGS uFlags, PSTR szFileName, PSTR szWinDir, PSTR szAppDir, uint8* szCurDir, uint32* puCurDirLen, uint8* szDestDir, uint32* puDestDirLen);
	public static VER_FIND_FILE_STATUS VerFindFile(VER_FIND_FILE_FLAGS uFlags, PSTR szFileName, PSTR szWinDir, PSTR szAppDir, uint8* szCurDir, uint32* puCurDirLen, uint8* szDestDir, uint32* puDestDirLen) => VerFindFileA(uFlags, szFileName, szWinDir, szAppDir, szCurDir, puCurDirLen, szDestDir, puDestDirLen);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VER_FIND_FILE_STATUS VerFindFileW(VER_FIND_FILE_FLAGS uFlags, PWSTR szFileName, PWSTR szWinDir, PWSTR szAppDir, char16* szCurDir, uint32* puCurDirLen, char16* szDestDir, uint32* puDestDirLen);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VER_INSTALL_FILE_STATUS VerInstallFileA(VER_INSTALL_FILE_FLAGS uFlags, PSTR szSrcFileName, PSTR szDestFileName, PSTR szSrcDir, PSTR szDestDir, PSTR szCurDir, uint8* szTmpFile, uint32* puTmpFileLen);
	public static VER_INSTALL_FILE_STATUS VerInstallFile(VER_INSTALL_FILE_FLAGS uFlags, PSTR szSrcFileName, PSTR szDestFileName, PSTR szSrcDir, PSTR szDestDir, PSTR szCurDir, uint8* szTmpFile, uint32* puTmpFileLen) => VerInstallFileA(uFlags, szSrcFileName, szDestFileName, szSrcDir, szDestDir, szCurDir, szTmpFile, puTmpFileLen);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern VER_INSTALL_FILE_STATUS VerInstallFileW(VER_INSTALL_FILE_FLAGS uFlags, PWSTR szSrcFileName, PWSTR szDestFileName, PWSTR szSrcDir, PWSTR szDestDir, PWSTR szCurDir, char16* szTmpFile, uint32* puTmpFileLen);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileVersionInfoSizeA(PSTR lptstrFilename, uint32* lpdwHandle);
	public static uint32 GetFileVersionInfoSize(PSTR lptstrFilename, uint32* lpdwHandle) => GetFileVersionInfoSizeA(lptstrFilename, lpdwHandle);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileVersionInfoSizeW(PWSTR lptstrFilename, uint32* lpdwHandle);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileVersionInfoA(PSTR lptstrFilename, uint32 dwHandle, uint32 dwLen, void* lpData);
	public static BOOL GetFileVersionInfo(PSTR lptstrFilename, uint32 dwHandle, uint32 dwLen, void* lpData) => GetFileVersionInfoA(lptstrFilename, dwHandle, dwLen, lpData);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileVersionInfoW(PWSTR lptstrFilename, uint32 dwHandle, uint32 dwLen, void* lpData);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileVersionInfoSizeExA(GET_FILE_VERSION_INFO_FLAGS dwFlags, PSTR lpwstrFilename, uint32* lpdwHandle);
	public static uint32 GetFileVersionInfoSizeEx(GET_FILE_VERSION_INFO_FLAGS dwFlags, PSTR lpwstrFilename, uint32* lpdwHandle) => GetFileVersionInfoSizeExA(dwFlags, lpwstrFilename, lpdwHandle);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFileVersionInfoSizeExW(GET_FILE_VERSION_INFO_FLAGS dwFlags, PWSTR lpwstrFilename, uint32* lpdwHandle);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileVersionInfoExA(GET_FILE_VERSION_INFO_FLAGS dwFlags, PSTR lpwstrFilename, uint32 dwHandle, uint32 dwLen, void* lpData);
	public static BOOL GetFileVersionInfoEx(GET_FILE_VERSION_INFO_FLAGS dwFlags, PSTR lpwstrFilename, uint32 dwHandle, uint32 dwLen, void* lpData) => GetFileVersionInfoExA(dwFlags, lpwstrFilename, dwHandle, dwLen, lpData);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileVersionInfoExW(GET_FILE_VERSION_INFO_FLAGS dwFlags, PWSTR lpwstrFilename, uint32 dwHandle, uint32 dwLen, void* lpData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 VerLanguageNameA(uint32 wLang, uint8* szLang, uint32 cchLang);
	public static uint32 VerLanguageName(uint32 wLang, uint8* szLang, uint32 cchLang) => VerLanguageNameA(wLang, szLang, cchLang);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 VerLanguageNameW(uint32 wLang, char16* szLang, uint32 cchLang);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VerQueryValueA(void* pBlock, PSTR lpSubBlock, void** lplpBuffer, uint32* puLen);
	public static BOOL VerQueryValue(void* pBlock, PSTR lpSubBlock, void** lplpBuffer, uint32* puLen) => VerQueryValueA(pBlock, lpSubBlock, lplpBuffer, puLen);

	[Import("VERSION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VerQueryValueW(void* pBlock, PWSTR lpSubBlock, void** lplpBuffer, uint32* puLen);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN LsnEqual(CLS_LSN* plsn1, CLS_LSN* plsn2);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN LsnLess(CLS_LSN* plsn1, CLS_LSN* plsn2);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN LsnGreater(CLS_LSN* plsn1, CLS_LSN* plsn2);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN LsnNull(CLS_LSN* plsn);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LsnContainer(CLS_LSN* plsn);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLS_LSN LsnCreate(uint32 cidContainer, uint32 offBlock, uint32 cRecord);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LsnBlockOffset(CLS_LSN* plsn);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LsnRecordSequence(CLS_LSN* plsn);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN LsnInvalid(CLS_LSN* plsn);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLS_LSN LsnIncrement(CLS_LSN* plsn);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateLogFile(PWSTR pszLogFileName, FILE_ACCESS_FLAGS fDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* psaLogFile, FILE_CREATION_DISPOSITION fCreateDisposition, FILE_FLAGS_AND_ATTRIBUTES fFlagsAndAttributes);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteLogByHandle(HANDLE hLog);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteLogFile(PWSTR pszLogFileName, void* pvReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddLogContainer(HANDLE hLog, uint64* pcbContainer, PWSTR pwszContainerPath, void* pReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddLogContainerSet(HANDLE hLog, uint16 cContainer, uint64* pcbContainer, PWSTR* rgwszContainerPath, void* pReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveLogContainer(HANDLE hLog, PWSTR pwszContainerPath, BOOL fForce, void* pReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveLogContainerSet(HANDLE hLog, uint16 cContainer, PWSTR* rgwszContainerPath, BOOL fForce, void* pReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetLogArchiveTail(HANDLE hLog, CLS_LSN* plsnArchiveTail, void* pReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEndOfLog(HANDLE hLog, CLS_LSN* plsnEnd, OVERLAPPED* lpOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TruncateLog(void* pvMarshal, CLS_LSN* plsnEnd, OVERLAPPED* lpOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateLogContainerScanContext(HANDLE hLog, uint32 cFromContainer, uint32 cContainers, uint8 eScanMode, CLS_SCAN_CONTEXT* pcxScan, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScanLogContainers(CLS_SCAN_CONTEXT* pcxScan, uint8 eScanMode, void* pReserved);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AlignReservedLog(void* pvMarshal, uint32 cReservedRecords, int64* rgcbReservation, int64* pcbAlignReservation);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocReservedLog(void* pvMarshal, uint32 cReservedRecords, int64* pcbAdjustment);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeReservedLog(void* pvMarshal, uint32 cReservedRecords, int64* pcbAdjustment);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogFileInformation(HANDLE hLog, CLS_INFORMATION* pinfoBuffer, uint32* cbBuffer);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetLogArchiveMode(HANDLE hLog, CLFS_LOG_ARCHIVE_MODE eMode);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadLogRestartArea(void* pvMarshal, void** ppvRestartBuffer, uint32* pcbRestartBuffer, CLS_LSN* plsn, void** ppvContext, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadPreviousLogRestartArea(void* pvReadContext, void** ppvRestartBuffer, uint32* pcbRestartBuffer, CLS_LSN* plsnRestart, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteLogRestartArea(void* pvMarshal, void* pvRestartBuffer, uint32 cbRestartBuffer, CLS_LSN* plsnBase, CLFS_FLAG fFlags, uint32* pcbWritten, CLS_LSN* plsnNext, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogReservationInfo(void* pvMarshal, uint32* pcbRecordNumber, int64* pcbUserReservation, int64* pcbCommitReservation);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AdvanceLogBase(void* pvMarshal, CLS_LSN* plsnBase, uint32 fFlags, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseAndResetLogFile(HANDLE hLog);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateLogMarshallingArea(HANDLE hLog, CLFS_BLOCK_ALLOCATION pfnAllocBuffer, CLFS_BLOCK_DEALLOCATION pfnFreeBuffer, void* pvBlockAllocContext, uint32 cbMarshallingBuffer, uint32 cMaxWriteBuffers, uint32 cMaxReadBuffers, void** ppvMarshal);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteLogMarshallingArea(void* pvMarshal);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReserveAndAppendLog(void* pvMarshal, CLS_WRITE_ENTRY* rgWriteEntries, uint32 cWriteEntries, CLS_LSN* plsnUndoNext, CLS_LSN* plsnPrevious, uint32 cReserveRecords, int64* rgcbReservation, CLFS_FLAG fFlags, CLS_LSN* plsn, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReserveAndAppendLogAligned(void* pvMarshal, CLS_WRITE_ENTRY* rgWriteEntries, uint32 cWriteEntries, uint32 cbEntryAlignment, CLS_LSN* plsnUndoNext, CLS_LSN* plsnPrevious, uint32 cReserveRecords, int64* rgcbReservation, CLFS_FLAG fFlags, CLS_LSN* plsn, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlushLogBuffers(void* pvMarshal, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlushLogToLsn(void* pvMarshalContext, CLS_LSN* plsnFlush, CLS_LSN* plsnLastFlushed, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadLogRecord(void* pvMarshal, CLS_LSN* plsnFirst, CLFS_CONTEXT_MODE eContextMode, void** ppvReadBuffer, uint32* pcbReadBuffer, uint8* peRecordType, CLS_LSN* plsnUndoNext, CLS_LSN* plsnPrevious, void** ppvReadContext, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadNextLogRecord(void* pvReadContext, void** ppvBuffer, uint32* pcbBuffer, uint8* peRecordType, CLS_LSN* plsnUser, CLS_LSN* plsnUndoNext, CLS_LSN* plsnPrevious, CLS_LSN* plsnRecord, OVERLAPPED* pOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TerminateReadLog(void* pvCursorContext);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrepareLogArchive(HANDLE hLog, char16* pszBaseLogFileName, uint32 cLen, CLS_LSN* plsnLow, CLS_LSN* plsnHigh, uint32* pcActualLength, uint64* poffBaseLogFileData, uint64* pcbBaseLogFileLength, CLS_LSN* plsnBase, CLS_LSN* plsnLast, CLS_LSN* plsnCurrentArchiveTail, void** ppvArchiveContext);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadLogArchiveMetadata(void* pvArchiveContext, uint32 cbOffset, uint32 cbBytesToRead, uint8* pbReadBuffer, uint32* pcbBytesRead);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNextLogArchiveExtent(void* pvArchiveContext, CLS_ARCHIVE_DESCRIPTOR* rgadExtent, uint32 cDescriptors, uint32* pcDescriptorsReturned);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TerminateLogArchive(void* pvArchiveContext);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ValidateLog(PWSTR pszLogFileName, SECURITY_ATTRIBUTES* psaLogFile, CLS_INFORMATION* pinfoBuffer, uint32* pcbBuffer);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogContainerName(HANDLE hLog, uint32 cidLogicalContainer, PWSTR pwstrContainerName, uint32 cLenContainerName, uint32* pcActualLenContainerName);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogIoStatistics(HANDLE hLog, void* pvStatsBuffer, uint32 cbStatsBuffer, CLFS_IOSTATS_CLASS eStatsClass, uint32* pcbStatsWritten);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterManageableLogClient(HANDLE hLog, LOG_MANAGEMENT_CALLBACKS* pCallbacks);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeregisterManageableLogClient(HANDLE hLog);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadLogNotification(HANDLE hLog, CLFS_MGMT_NOTIFICATION* pNotification, OVERLAPPED* lpOverlapped);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InstallLogPolicy(HANDLE hLog, CLFS_MGMT_POLICY* pPolicy);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveLogPolicy(HANDLE hLog, CLFS_MGMT_POLICY_TYPE ePolicyType);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryLogPolicy(HANDLE hLog, CLFS_MGMT_POLICY_TYPE ePolicyType, CLFS_MGMT_POLICY* pPolicyBuffer, uint32* pcbPolicyBuffer);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetLogFileSizeWithPolicy(HANDLE hLog, uint64* pDesiredSize, uint64* pResultingSize);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HandleLogFull(HANDLE hLog);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LogTailAdvanceFailure(HANDLE hLog, uint32 dwReason);

	[Import("clfsw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterForLogWriteNotification(HANDLE hLog, uint32 cbThreshold, BOOL fEnable);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryUsersOnEncryptedFile(PWSTR lpFileName, ENCRYPTION_CERTIFICATE_HASH_LIST** pUsers);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryRecoveryAgentsOnEncryptedFile(PWSTR lpFileName, ENCRYPTION_CERTIFICATE_HASH_LIST** pRecoveryAgents);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveUsersFromEncryptedFile(PWSTR lpFileName, ENCRYPTION_CERTIFICATE_HASH_LIST* pHashes);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddUsersToEncryptedFile(PWSTR lpFileName, ENCRYPTION_CERTIFICATE_LIST* pEncryptionCertificates);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetUserFileEncryptionKey(ENCRYPTION_CERTIFICATE* pEncryptionCertificate);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetUserFileEncryptionKeyEx(ENCRYPTION_CERTIFICATE* pEncryptionCertificate, uint32 dwCapabilities, uint32 dwFlags, void* pvReserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeEncryptionCertificateHashList(ENCRYPTION_CERTIFICATE_HASH_LIST* pUsers);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EncryptionDisable(PWSTR DirPath, BOOL Disable);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DuplicateEncryptionInfoFile(PWSTR SrcFileName, PWSTR DstFileName, uint32 dwCreationDistribution, uint32 dwAttributes, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEncryptedFileMetadata(PWSTR lpFileName, uint32* pcbMetadata, uint8** ppbMetadata);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetEncryptedFileMetadata(PWSTR lpFileName, uint8* pbOldMetadata, uint8* pbNewMetadata, ENCRYPTION_CERTIFICATE_HASH* pOwnerHash, uint32 dwOperation, ENCRYPTION_CERTIFICATE_HASH_LIST* pCertificatesAdded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeEncryptedFileMetadata(uint8* pbMetadata);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZStart();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LZDone();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CopyLZFile(int32 hfSource, int32 hfDest);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZCopy(int32 hfSource, int32 hfDest);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZInit(int32 hfSource);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetExpandedNameA(PSTR lpszSource, uint8* lpszBuffer);
	public static int32 GetExpandedName(PSTR lpszSource, uint8* lpszBuffer) => GetExpandedNameA(lpszSource, lpszBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetExpandedNameW(PWSTR lpszSource, char16* lpszBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZOpenFileA(PSTR lpFileName, OFSTRUCT* lpReOpenBuf, LZOPENFILE_STYLE wStyle);
	public static int32 LZOpenFile(PSTR lpFileName, OFSTRUCT* lpReOpenBuf, LZOPENFILE_STYLE wStyle) => LZOpenFileA(lpFileName, lpReOpenBuf, wStyle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZOpenFileW(PWSTR lpFileName, OFSTRUCT* lpReOpenBuf, LZOPENFILE_STYLE wStyle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZSeek(int32 hFile, int32 lOffset, int32 iOrigin);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LZRead(int32 hFile, PSTR lpBuffer, int32 cbRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LZClose(int32 hFile);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WofShouldCompressBinaries(PWSTR Volume, uint32* Algorithm);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofGetDriverVersion(HANDLE FileOrVolumeHandle, uint32 Provider, uint32* WofVersion);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofSetFileDataLocation(HANDLE FileHandle, uint32 Provider, void* ExternalFileInfo, uint32 Length);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofIsExternalFile(PWSTR FilePath, BOOL* IsExternalFile, uint32* Provider, void* ExternalFileInfo, uint32* BufferLength);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofEnumEntries(PWSTR VolumeName, uint32 Provider, WofEnumEntryProc EnumProc, void* UserData);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofWimAddEntry(PWSTR VolumeName, PWSTR WimPath, uint32 WimType, uint32 WimIndex, LARGE_INTEGER* DataSourceId);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofWimEnumFiles(PWSTR VolumeName, LARGE_INTEGER DataSourceId, WofEnumFilesProc EnumProc, void* UserData);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofWimSuspendEntry(PWSTR VolumeName, LARGE_INTEGER DataSourceId);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofWimRemoveEntry(PWSTR VolumeName, LARGE_INTEGER DataSourceId);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofWimUpdateEntry(PWSTR VolumeName, LARGE_INTEGER DataSourceId, PWSTR NewWimPath);

	[Import("WOFUTIL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WofFileEnumFiles(PWSTR VolumeName, uint32 Algorithm, WofEnumFilesProc EnumProc, void* UserData);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfLogCreateFileReadContext(PWSTR LogPath, CLS_LSN BeginningLsn, CLS_LSN EndingLsn, TXF_ID* TxfFileId, void** TxfLogContext);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfLogCreateRangeReadContext(PWSTR LogPath, CLS_LSN BeginningLsn, CLS_LSN EndingLsn, LARGE_INTEGER* BeginningVirtualClock, LARGE_INTEGER* EndingVirtualClock, uint32 RecordTypeMask, void** TxfLogContext);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfLogDestroyReadContext(void* TxfLogContext);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfLogReadRecords(void* TxfLogContext, uint32 BufferLength, void* Buffer, uint32* BytesUsed, uint32* RecordCount);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfReadMetadataInfo(HANDLE FileHandle, TXF_ID* TxfFileId, CLS_LSN* LastLsn, uint32* TransactionState, Guid* LockingTransaction);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfLogRecordGetFileName(void* RecordBuffer, uint32 RecordBufferLengthInBytes, PWSTR NameBuffer, uint32* NameBufferLengthInBytes, TXF_ID* TxfId);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TxfLogRecordGetGenericType(void* RecordBuffer, uint32 RecordBufferLengthInBytes, uint32* GenericType, LARGE_INTEGER* VirtualClock);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void TxfSetThreadMiniVersionForCreate(uint16 MiniVersion);

	[Import("txfw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void TxfGetThreadMiniVersionForCreate(uint16* MiniVersion);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateTransaction(SECURITY_ATTRIBUTES* lpTransactionAttributes, Guid* UOW, uint32 CreateOptions, uint32 IsolationLevel, uint32 IsolationFlags, uint32 Timeout, PWSTR Description);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenTransaction(uint32 dwDesiredAccess, Guid* TransactionId);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CommitTransaction(HANDLE TransactionHandle);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CommitTransactionAsync(HANDLE TransactionHandle);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RollbackTransaction(HANDLE TransactionHandle);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RollbackTransactionAsync(HANDLE TransactionHandle);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTransactionId(HANDLE TransactionHandle, Guid* TransactionId);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTransactionInformation(HANDLE TransactionHandle, uint32* Outcome, uint32* IsolationLevel, uint32* IsolationFlags, uint32* Timeout, uint32 BufferLength, char16* Description);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetTransactionInformation(HANDLE TransactionHandle, uint32 IsolationLevel, uint32 IsolationFlags, uint32 Timeout, PWSTR Description);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateTransactionManager(SECURITY_ATTRIBUTES* lpTransactionAttributes, PWSTR LogFileName, uint32 CreateOptions, uint32 CommitStrength);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenTransactionManager(PWSTR LogFileName, uint32 DesiredAccess, uint32 OpenOptions);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenTransactionManagerById(Guid* TransactionManagerId, uint32 DesiredAccess, uint32 OpenOptions);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RenameTransactionManager(PWSTR LogFileName, Guid* ExistingTransactionManagerGuid);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RollforwardTransactionManager(HANDLE TransactionManagerHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RecoverTransactionManager(HANDLE TransactionManagerHandle);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentClockTransactionManager(HANDLE TransactionManagerHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTransactionManagerId(HANDLE TransactionManagerHandle, Guid* TransactionManagerId);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateResourceManager(SECURITY_ATTRIBUTES* lpResourceManagerAttributes, Guid* ResourceManagerId, uint32 CreateOptions, HANDLE TmHandle, PWSTR Description);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenResourceManager(uint32 dwDesiredAccess, HANDLE TmHandle, Guid* ResourceManagerId);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RecoverResourceManager(HANDLE ResourceManagerHandle);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNotificationResourceManager(HANDLE ResourceManagerHandle, TRANSACTION_NOTIFICATION* TransactionNotification, uint32 NotificationLength, uint32 dwMilliseconds, uint32* ReturnLength);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNotificationResourceManagerAsync(HANDLE ResourceManagerHandle, TRANSACTION_NOTIFICATION* TransactionNotification, uint32 TransactionNotificationLength, uint32* ReturnLength, OVERLAPPED* lpOverlapped);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetResourceManagerCompletionPort(HANDLE ResourceManagerHandle, HANDLE IoCompletionPortHandle, uint CompletionKey);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateEnlistment(SECURITY_ATTRIBUTES* lpEnlistmentAttributes, HANDLE ResourceManagerHandle, HANDLE TransactionHandle, uint32 NotificationMask, uint32 CreateOptions, void* EnlistmentKey);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenEnlistment(uint32 dwDesiredAccess, HANDLE ResourceManagerHandle, Guid* EnlistmentId);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RecoverEnlistment(HANDLE EnlistmentHandle, void* EnlistmentKey);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetEnlistmentRecoveryInformation(HANDLE EnlistmentHandle, uint32 BufferSize, void* Buffer, uint32* BufferUsed);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetEnlistmentId(HANDLE EnlistmentHandle, Guid* EnlistmentId);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetEnlistmentRecoveryInformation(HANDLE EnlistmentHandle, uint32 BufferSize, void* Buffer);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrepareEnlistment(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrePrepareEnlistment(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CommitEnlistment(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RollbackEnlistment(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrePrepareComplete(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrepareComplete(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadOnlyEnlistment(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CommitComplete(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RollbackComplete(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("ktmw32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SinglePhaseReject(HANDLE EnlistmentHandle, LARGE_INTEGER* TmVirtualClock);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareEnumSticky(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareGetInfo(PWSTR servername, PWSTR netname, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareSetInfo(PWSTR servername, PWSTR netname, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareDel(PWSTR servername, PWSTR netname, uint32 reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareDelSticky(PWSTR servername, PWSTR netname, uint32 reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareCheck(PWSTR servername, PWSTR device, uint32* type);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetShareDelEx(PWSTR servername, uint32 level, uint8* buf);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerAliasAdd(PWSTR servername, uint32 level, uint8* buf);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerAliasDel(PWSTR servername, uint32 level, uint8* buf);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerAliasEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resumehandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetSessionEnum(PWSTR servername, PWSTR UncClientName, PWSTR username, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetSessionDel(PWSTR servername, PWSTR UncClientName, PWSTR username);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetSessionGetInfo(PWSTR servername, PWSTR UncClientName, PWSTR username, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetConnectionEnum(PWSTR servername, PWSTR qualifier, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetFileClose(PWSTR servername, uint32 fileid);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetFileEnum(PWSTR servername, PWSTR basepath, PWSTR username, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetFileGetInfo(PWSTR servername, uint32 fileid, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetStatisticsGet(int8* ServerName, int8* Service, uint32 Level, uint32 Options, uint8** Buffer);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryIoRingCapabilities(IORING_CAPABILITIES* capabilities);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsIoRingOpSupported(HIORING__* ioRing, IORING_OP_CODE op);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateIoRing(IORING_VERSION ioringVersion, IORING_CREATE_FLAGS flags, uint32 submissionQueueSize, uint32 completionQueueSize, HIORING__** h);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetIoRingInfo(HIORING__* ioRing, IORING_INFO* info);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SubmitIoRing(HIORING__* ioRing, uint32 waitOperations, uint32 milliseconds, uint32* submittedEntries);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CloseIoRing(HIORING__* ioRing);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PopIoRingCompletion(HIORING__* ioRing, IORING_CQE* cqe);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetIoRingCompletionEvent(HIORING__* ioRing, HANDLE hEvent);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BuildIoRingCancelRequest(HIORING__* ioRing, IORING_HANDLE_REF file, uint opToCancel, uint userData);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BuildIoRingReadFile(HIORING__* ioRing, IORING_HANDLE_REF fileRef, IORING_BUFFER_REF dataRef, uint32 numberOfBytesToRead, uint64 fileOffset, uint userData, IORING_SQE_FLAGS flags);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BuildIoRingRegisterFileHandles(HIORING__* ioRing, uint32 count, HANDLE* handles, uint userData);

	[Import("api-ms-win-core-ioring-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BuildIoRingRegisterBuffers(HIORING__* ioRing, uint32 count, IORING_BUFFER_INFO* buffers, uint userData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN Wow64EnableWow64FsRedirection(BOOLEAN Wow64FsEnableRedirection);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Wow64DisableWow64FsRedirection(void** OldValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Wow64RevertWow64FsRedirection(void* OlValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetBinaryTypeA(PSTR lpApplicationName, uint32* lpBinaryType);
	public static BOOL GetBinaryType(PSTR lpApplicationName, uint32* lpBinaryType) => GetBinaryTypeA(lpApplicationName, lpBinaryType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetBinaryTypeW(PWSTR lpApplicationName, uint32* lpBinaryType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetShortPathNameA(PSTR lpszLongPath, uint8* lpszShortPath, uint32 cchBuffer);
	public static uint32 GetShortPathName(PSTR lpszLongPath, uint8* lpszShortPath, uint32 cchBuffer) => GetShortPathNameA(lpszLongPath, lpszShortPath, cchBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLongPathNameTransactedA(PSTR lpszShortPath, uint8* lpszLongPath, uint32 cchBuffer, HANDLE hTransaction);
	public static uint32 GetLongPathNameTransacted(PSTR lpszShortPath, uint8* lpszLongPath, uint32 cchBuffer, HANDLE hTransaction) => GetLongPathNameTransactedA(lpszShortPath, lpszLongPath, cchBuffer, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLongPathNameTransactedW(PWSTR lpszShortPath, char16* lpszLongPath, uint32 cchBuffer, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileCompletionNotificationModes(HANDLE FileHandle, uint8 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileShortNameA(HANDLE hFile, PSTR lpShortName);
	public static BOOL SetFileShortName(HANDLE hFile, PSTR lpShortName) => SetFileShortNameA(hFile, lpShortName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileShortNameW(HANDLE hFile, PWSTR lpShortName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetTapePosition(HANDLE hDevice, TAPE_POSITION_METHOD dwPositionMethod, uint32 dwPartition, uint32 dwOffsetLow, uint32 dwOffsetHigh, BOOL bImmediate);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTapePosition(HANDLE hDevice, TAPE_POSITION_TYPE dwPositionType, uint32* lpdwPartition, uint32* lpdwOffsetLow, uint32* lpdwOffsetHigh);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PrepareTape(HANDLE hDevice, PREPARE_TAPE_OPERATION dwOperation, BOOL bImmediate);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EraseTape(HANDLE hDevice, ERASE_TAPE_TYPE dwEraseType, BOOL bImmediate);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CreateTapePartition(HANDLE hDevice, CREATE_TAPE_PARTITION_METHOD dwPartitionMethod, uint32 dwCount, uint32 dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WriteTapemark(HANDLE hDevice, TAPEMARK_TYPE dwTapemarkType, uint32 dwTapemarkCount, BOOL bImmediate);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTapeStatus(HANDLE hDevice);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTapeParameters(HANDLE hDevice, GET_TAPE_DRIVE_PARAMETERS_OPERATION dwOperation, uint32* lpdwSize, void* lpTapeInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetTapeParameters(HANDLE hDevice, TAPE_INFORMATION_TYPE dwOperation, void* lpTapeInformation);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EncryptFileA(PSTR lpFileName);
	public static BOOL EncryptFile(PSTR lpFileName) => EncryptFileA(lpFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EncryptFileW(PWSTR lpFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DecryptFileA(PSTR lpFileName, uint32 dwReserved);
	public static BOOL DecryptFile(PSTR lpFileName, uint32 dwReserved) => DecryptFileA(lpFileName, dwReserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DecryptFileW(PWSTR lpFileName, uint32 dwReserved);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FileEncryptionStatusA(PSTR lpFileName, uint32* lpStatus);
	public static BOOL FileEncryptionStatus(PSTR lpFileName, uint32* lpStatus) => FileEncryptionStatusA(lpFileName, lpStatus);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FileEncryptionStatusW(PWSTR lpFileName, uint32* lpStatus);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OpenEncryptedFileRawA(PSTR lpFileName, uint32 ulFlags, void** pvContext);
	public static uint32 OpenEncryptedFileRaw(PSTR lpFileName, uint32 ulFlags, void** pvContext) => OpenEncryptedFileRawA(lpFileName, ulFlags, pvContext);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OpenEncryptedFileRawW(PWSTR lpFileName, uint32 ulFlags, void** pvContext);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReadEncryptedFileRaw(PFE_EXPORT_FUNC pfExportCallback, void* pvCallbackContext, void* pvContext);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WriteEncryptedFileRaw(PFE_IMPORT_FUNC pfImportCallback, void* pvCallbackContext, void* pvContext);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CloseEncryptedFileRaw(void* pvContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 OpenFile(PSTR lpFileName, OFSTRUCT* lpReOpenBuff, uint32 uStyle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BackupRead(HANDLE hFile, uint8* lpBuffer, uint32 nNumberOfBytesToRead, uint32* lpNumberOfBytesRead, BOOL bAbort, BOOL bProcessSecurity, void** lpContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BackupSeek(HANDLE hFile, uint32 dwLowBytesToSeek, uint32 dwHighBytesToSeek, uint32* lpdwLowByteSeeked, uint32* lpdwHighByteSeeked, void** lpContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BackupWrite(HANDLE hFile, uint8* lpBuffer, uint32 nNumberOfBytesToWrite, uint32* lpNumberOfBytesWritten, BOOL bAbort, BOOL bProcessSecurity, void** lpContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLogicalDriveStringsA(uint32 nBufferLength, uint8* lpBuffer);
	public static uint32 GetLogicalDriveStrings(uint32 nBufferLength, uint8* lpBuffer) => GetLogicalDriveStringsA(nBufferLength, lpBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSearchPathMode(uint32 Flags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryExA(PSTR lpTemplateDirectory, PSTR lpNewDirectory, SECURITY_ATTRIBUTES* lpSecurityAttributes);
	public static BOOL CreateDirectoryEx(PSTR lpTemplateDirectory, PSTR lpNewDirectory, SECURITY_ATTRIBUTES* lpSecurityAttributes) => CreateDirectoryExA(lpTemplateDirectory, lpNewDirectory, lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryExW(PWSTR lpTemplateDirectory, PWSTR lpNewDirectory, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryTransactedA(PSTR lpTemplateDirectory, PSTR lpNewDirectory, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE hTransaction);
	public static BOOL CreateDirectoryTransacted(PSTR lpTemplateDirectory, PSTR lpNewDirectory, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE hTransaction) => CreateDirectoryTransactedA(lpTemplateDirectory, lpNewDirectory, lpSecurityAttributes, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDirectoryTransactedW(PWSTR lpTemplateDirectory, PWSTR lpNewDirectory, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveDirectoryTransactedA(PSTR lpPathName, HANDLE hTransaction);
	public static BOOL RemoveDirectoryTransacted(PSTR lpPathName, HANDLE hTransaction) => RemoveDirectoryTransactedA(lpPathName, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveDirectoryTransactedW(PWSTR lpPathName, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFullPathNameTransactedA(PSTR lpFileName, uint32 nBufferLength, uint8* lpBuffer, PSTR* lpFilePart, HANDLE hTransaction);
	public static uint32 GetFullPathNameTransacted(PSTR lpFileName, uint32 nBufferLength, uint8* lpBuffer, PSTR* lpFilePart, HANDLE hTransaction) => GetFullPathNameTransactedA(lpFileName, nBufferLength, lpBuffer, lpFilePart, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetFullPathNameTransactedW(PWSTR lpFileName, uint32 nBufferLength, char16* lpBuffer, PWSTR* lpFilePart, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DefineDosDeviceA(DEFINE_DOS_DEVICE_FLAGS dwFlags, PSTR lpDeviceName, PSTR lpTargetPath);
	public static BOOL DefineDosDevice(DEFINE_DOS_DEVICE_FLAGS dwFlags, PSTR lpDeviceName, PSTR lpTargetPath) => DefineDosDeviceA(dwFlags, lpDeviceName, lpTargetPath);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryDosDeviceA(PSTR lpDeviceName, uint8* lpTargetPath, uint32 ucchMax);
	public static uint32 QueryDosDevice(PSTR lpDeviceName, uint8* lpTargetPath, uint32 ucchMax) => QueryDosDeviceA(lpDeviceName, lpTargetPath, ucchMax);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileTransactedA(PSTR lpFileName, uint32 dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_CREATION_DISPOSITION dwCreationDisposition, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes, HANDLE hTemplateFile, HANDLE hTransaction, TXFS_MINIVERSION* pusMiniVersion, void* lpExtendedParameter);
	public static HANDLE CreateFileTransacted(PSTR lpFileName, uint32 dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_CREATION_DISPOSITION dwCreationDisposition, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes, HANDLE hTemplateFile, HANDLE hTransaction, TXFS_MINIVERSION* pusMiniVersion, void* lpExtendedParameter) => CreateFileTransactedA(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile, hTransaction, pusMiniVersion, lpExtendedParameter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateFileTransactedW(PWSTR lpFileName, uint32 dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_CREATION_DISPOSITION dwCreationDisposition, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes, HANDLE hTemplateFile, HANDLE hTransaction, TXFS_MINIVERSION* pusMiniVersion, void* lpExtendedParameter);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE ReOpenFile(HANDLE hOriginalFile, FILE_ACCESS_FLAGS dwDesiredAccess, FILE_SHARE_MODE dwShareMode, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileAttributesTransactedA(PSTR lpFileName, uint32 dwFileAttributes, HANDLE hTransaction);
	public static BOOL SetFileAttributesTransacted(PSTR lpFileName, uint32 dwFileAttributes, HANDLE hTransaction) => SetFileAttributesTransactedA(lpFileName, dwFileAttributes, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileAttributesTransactedW(PWSTR lpFileName, uint32 dwFileAttributes, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileAttributesTransactedA(PSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation, HANDLE hTransaction);
	public static BOOL GetFileAttributesTransacted(PSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation, HANDLE hTransaction) => GetFileAttributesTransactedA(lpFileName, fInfoLevelId, lpFileInformation, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileAttributesTransactedW(PWSTR lpFileName, GET_FILEEX_INFO_LEVELS fInfoLevelId, void* lpFileInformation, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCompressedFileSizeTransactedA(PSTR lpFileName, uint32* lpFileSizeHigh, HANDLE hTransaction);
	public static uint32 GetCompressedFileSizeTransacted(PSTR lpFileName, uint32* lpFileSizeHigh, HANDLE hTransaction) => GetCompressedFileSizeTransactedA(lpFileName, lpFileSizeHigh, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCompressedFileSizeTransactedW(PWSTR lpFileName, uint32* lpFileSizeHigh, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFileTransactedA(PSTR lpFileName, HANDLE hTransaction);
	public static BOOL DeleteFileTransacted(PSTR lpFileName, HANDLE hTransaction) => DeleteFileTransactedA(lpFileName, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteFileTransactedW(PWSTR lpFileName, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckNameLegalDOS8Dot3A(PSTR lpName, uint8* lpOemName, uint32 OemNameSize, BOOL* pbNameContainsSpaces, BOOL* pbNameLegal);
	public static BOOL CheckNameLegalDOS8Dot3(PSTR lpName, uint8* lpOemName, uint32 OemNameSize, BOOL* pbNameContainsSpaces, BOOL* pbNameLegal) => CheckNameLegalDOS8Dot3A(lpName, lpOemName, OemNameSize, pbNameContainsSpaces, pbNameLegal);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckNameLegalDOS8Dot3W(PWSTR lpName, uint8* lpOemName, uint32 OemNameSize, BOOL* pbNameContainsSpaces, BOOL* pbNameLegal);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileHandle FindFirstFileTransactedA(PSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, uint32 dwAdditionalFlags, HANDLE hTransaction);
	public static FindFileHandle FindFirstFileTransacted(PSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, uint32 dwAdditionalFlags, HANDLE hTransaction) => FindFirstFileTransactedA(lpFileName, fInfoLevelId, lpFindFileData, fSearchOp, lpSearchFilter, dwAdditionalFlags, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileHandle FindFirstFileTransactedW(PWSTR lpFileName, FINDEX_INFO_LEVELS fInfoLevelId, void* lpFindFileData, FINDEX_SEARCH_OPS fSearchOp, void* lpSearchFilter, uint32 dwAdditionalFlags, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileA(PSTR lpExistingFileName, PSTR lpNewFileName, BOOL bFailIfExists);
	public static BOOL CopyFile(PSTR lpExistingFileName, PSTR lpNewFileName, BOOL bFailIfExists) => CopyFileA(lpExistingFileName, lpNewFileName, bFailIfExists);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileW(PWSTR lpExistingFileName, PWSTR lpNewFileName, BOOL bFailIfExists);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileExA(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, int32* pbCancel, uint32 dwCopyFlags);
	public static BOOL CopyFileEx(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, int32* pbCancel, uint32 dwCopyFlags) => CopyFileExA(lpExistingFileName, lpNewFileName, lpProgressRoutine, lpData, pbCancel, dwCopyFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileExW(PWSTR lpExistingFileName, PWSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, int32* pbCancel, uint32 dwCopyFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileTransactedA(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, int32* pbCancel, uint32 dwCopyFlags, HANDLE hTransaction);
	public static BOOL CopyFileTransacted(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, int32* pbCancel, uint32 dwCopyFlags, HANDLE hTransaction) => CopyFileTransactedA(lpExistingFileName, lpNewFileName, lpProgressRoutine, lpData, pbCancel, dwCopyFlags, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopyFileTransactedW(PWSTR lpExistingFileName, PWSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, int32* pbCancel, uint32 dwCopyFlags, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CopyFile2(PWSTR pwszExistingFileName, PWSTR pwszNewFileName, COPYFILE2_EXTENDED_PARAMETERS* pExtendedParameters);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileA(PSTR lpExistingFileName, PSTR lpNewFileName);
	public static BOOL MoveFile(PSTR lpExistingFileName, PSTR lpNewFileName) => MoveFileA(lpExistingFileName, lpNewFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileW(PWSTR lpExistingFileName, PWSTR lpNewFileName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileExA(PSTR lpExistingFileName, PSTR lpNewFileName, MOVE_FILE_FLAGS dwFlags);
	public static BOOL MoveFileEx(PSTR lpExistingFileName, PSTR lpNewFileName, MOVE_FILE_FLAGS dwFlags) => MoveFileExA(lpExistingFileName, lpNewFileName, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileExW(PWSTR lpExistingFileName, PWSTR lpNewFileName, MOVE_FILE_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileWithProgressA(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, MOVE_FILE_FLAGS dwFlags);
	public static BOOL MoveFileWithProgress(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, MOVE_FILE_FLAGS dwFlags) => MoveFileWithProgressA(lpExistingFileName, lpNewFileName, lpProgressRoutine, lpData, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileWithProgressW(PWSTR lpExistingFileName, PWSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, MOVE_FILE_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileTransactedA(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, MOVE_FILE_FLAGS dwFlags, HANDLE hTransaction);
	public static BOOL MoveFileTransacted(PSTR lpExistingFileName, PSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, MOVE_FILE_FLAGS dwFlags, HANDLE hTransaction) => MoveFileTransactedA(lpExistingFileName, lpNewFileName, lpProgressRoutine, lpData, dwFlags, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MoveFileTransactedW(PWSTR lpExistingFileName, PWSTR lpNewFileName, LPPROGRESS_ROUTINE lpProgressRoutine, void* lpData, MOVE_FILE_FLAGS dwFlags, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReplaceFileA(PSTR lpReplacedFileName, PSTR lpReplacementFileName, PSTR lpBackupFileName, REPLACE_FILE_FLAGS dwReplaceFlags, void* lpExclude, void* lpReserved);
	public static BOOL ReplaceFile(PSTR lpReplacedFileName, PSTR lpReplacementFileName, PSTR lpBackupFileName, REPLACE_FILE_FLAGS dwReplaceFlags, void* lpExclude, void* lpReserved) => ReplaceFileA(lpReplacedFileName, lpReplacementFileName, lpBackupFileName, dwReplaceFlags, lpExclude, lpReserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReplaceFileW(PWSTR lpReplacedFileName, PWSTR lpReplacementFileName, PWSTR lpBackupFileName, REPLACE_FILE_FLAGS dwReplaceFlags, void* lpExclude, void* lpReserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateHardLinkA(PSTR lpFileName, PSTR lpExistingFileName, SECURITY_ATTRIBUTES* lpSecurityAttributes);
	public static BOOL CreateHardLink(PSTR lpFileName, PSTR lpExistingFileName, SECURITY_ATTRIBUTES* lpSecurityAttributes) => CreateHardLinkA(lpFileName, lpExistingFileName, lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateHardLinkW(PWSTR lpFileName, PWSTR lpExistingFileName, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateHardLinkTransactedA(PSTR lpFileName, PSTR lpExistingFileName, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE hTransaction);
	public static BOOL CreateHardLinkTransacted(PSTR lpFileName, PSTR lpExistingFileName, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE hTransaction) => CreateHardLinkTransactedA(lpFileName, lpExistingFileName, lpSecurityAttributes, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateHardLinkTransactedW(PWSTR lpFileName, PWSTR lpExistingFileName, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindStreamHandle FindFirstStreamTransactedW(PWSTR lpFileName, STREAM_INFO_LEVELS InfoLevel, void* lpFindStreamData, uint32 dwFlags, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindFileNameHandle FindFirstFileNameTransactedW(PWSTR lpFileName, uint32 dwFlags, uint32* StringLength, char16* LinkName, HANDLE hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetVolumeLabelA(PSTR lpRootPathName, PSTR lpVolumeName);
	public static BOOL SetVolumeLabel(PSTR lpRootPathName, PSTR lpVolumeName) => SetVolumeLabelA(lpRootPathName, lpVolumeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetVolumeLabelW(PWSTR lpRootPathName, PWSTR lpVolumeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileBandwidthReservation(HANDLE hFile, uint32 nPeriodMilliseconds, uint32 nBytesPerPeriod, BOOL bDiscardable, uint32* lpTransferSize, uint32* lpNumOutstandingRequests);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileBandwidthReservation(HANDLE hFile, uint32* lpPeriodMilliseconds, uint32* lpBytesPerPeriod, int32* pDiscardable, uint32* lpTransferSize, uint32* lpNumOutstandingRequests);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadDirectoryChangesW(HANDLE hDirectory, void* lpBuffer, uint32 nBufferLength, BOOL bWatchSubtree, FILE_NOTIFY_CHANGE dwNotifyFilter, uint32* lpBytesReturned, OVERLAPPED* lpOverlapped, LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadDirectoryChangesExW(HANDLE hDirectory, void* lpBuffer, uint32 nBufferLength, BOOL bWatchSubtree, FILE_NOTIFY_CHANGE dwNotifyFilter, uint32* lpBytesReturned, OVERLAPPED* lpOverlapped, LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine, READ_DIRECTORY_NOTIFY_INFORMATION_CLASS ReadDirectoryNotifyInformationClass);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindVolumeHandle FindFirstVolumeA(uint8* lpszVolumeName, uint32 cchBufferLength);
	public static FindVolumeHandle FindFirstVolume(uint8* lpszVolumeName, uint32 cchBufferLength) => FindFirstVolumeA(lpszVolumeName, cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextVolumeA(FindVolumeHandle hFindVolume, uint8* lpszVolumeName, uint32 cchBufferLength);
	public static BOOL FindNextVolume(FindVolumeHandle hFindVolume, uint8* lpszVolumeName, uint32 cchBufferLength) => FindNextVolumeA(hFindVolume, lpszVolumeName, cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindVolumeMointPointHandle FindFirstVolumeMountPointA(PSTR lpszRootPathName, uint8* lpszVolumeMountPoint, uint32 cchBufferLength);
	public static FindVolumeMointPointHandle FindFirstVolumeMountPoint(PSTR lpszRootPathName, uint8* lpszVolumeMountPoint, uint32 cchBufferLength) => FindFirstVolumeMountPointA(lpszRootPathName, lpszVolumeMountPoint, cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FindVolumeMointPointHandle FindFirstVolumeMountPointW(PWSTR lpszRootPathName, char16* lpszVolumeMountPoint, uint32 cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextVolumeMountPointA(FindVolumeMointPointHandle hFindVolumeMountPoint, uint8* lpszVolumeMountPoint, uint32 cchBufferLength);
	public static BOOL FindNextVolumeMountPoint(FindVolumeMointPointHandle hFindVolumeMountPoint, uint8* lpszVolumeMountPoint, uint32 cchBufferLength) => FindNextVolumeMountPointA(hFindVolumeMountPoint, lpszVolumeMountPoint, cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindNextVolumeMountPointW(FindVolumeMointPointHandle hFindVolumeMountPoint, char16* lpszVolumeMountPoint, uint32 cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindVolumeMountPointClose(FindVolumeMointPointHandle hFindVolumeMountPoint);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetVolumeMountPointA(PSTR lpszVolumeMountPoint, PSTR lpszVolumeName);
	public static BOOL SetVolumeMountPoint(PSTR lpszVolumeMountPoint, PSTR lpszVolumeName) => SetVolumeMountPointA(lpszVolumeMountPoint, lpszVolumeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetVolumeMountPointW(PWSTR lpszVolumeMountPoint, PWSTR lpszVolumeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteVolumeMountPointA(PSTR lpszVolumeMountPoint);
	public static BOOL DeleteVolumeMountPoint(PSTR lpszVolumeMountPoint) => DeleteVolumeMountPointA(lpszVolumeMountPoint);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumeNameForVolumeMountPointA(PSTR lpszVolumeMountPoint, uint8* lpszVolumeName, uint32 cchBufferLength);
	public static BOOL GetVolumeNameForVolumeMountPoint(PSTR lpszVolumeMountPoint, uint8* lpszVolumeName, uint32 cchBufferLength) => GetVolumeNameForVolumeMountPointA(lpszVolumeMountPoint, lpszVolumeName, cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumePathNameA(PSTR lpszFileName, uint8* lpszVolumePathName, uint32 cchBufferLength);
	public static BOOL GetVolumePathName(PSTR lpszFileName, uint8* lpszVolumePathName, uint32 cchBufferLength) => GetVolumePathNameA(lpszFileName, lpszVolumePathName, cchBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetVolumePathNamesForVolumeNameA(PSTR lpszVolumeName, uint8* lpszVolumePathNames, uint32 cchBufferLength, uint32* lpcchReturnLength);
	public static BOOL GetVolumePathNamesForVolumeName(PSTR lpszVolumeName, uint8* lpszVolumePathNames, uint32 cchBufferLength, uint32* lpcchReturnLength) => GetVolumePathNamesForVolumeNameA(lpszVolumeName, lpszVolumePathNames, cchBufferLength, lpcchReturnLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileInformationByHandleEx(HANDLE hFile, FILE_INFO_BY_HANDLE_CLASS FileInformationClass, void* lpFileInformation, uint32 dwBufferSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenFileById(HANDLE hVolumeHint, FILE_ID_DESCRIPTOR* lpFileId, FILE_ACCESS_FLAGS dwDesiredAccess, FILE_SHARE_MODE dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, FILE_FLAGS_AND_ATTRIBUTES dwFlagsAndAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN CreateSymbolicLinkA(PSTR lpSymlinkFileName, PSTR lpTargetFileName, SYMBOLIC_LINK_FLAGS dwFlags);
	public static BOOLEAN CreateSymbolicLink(PSTR lpSymlinkFileName, PSTR lpTargetFileName, SYMBOLIC_LINK_FLAGS dwFlags) => CreateSymbolicLinkA(lpSymlinkFileName, lpTargetFileName, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN CreateSymbolicLinkW(PWSTR lpSymlinkFileName, PWSTR lpTargetFileName, SYMBOLIC_LINK_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN CreateSymbolicLinkTransactedA(PSTR lpSymlinkFileName, PSTR lpTargetFileName, SYMBOLIC_LINK_FLAGS dwFlags, HANDLE hTransaction);
	public static BOOLEAN CreateSymbolicLinkTransacted(PSTR lpSymlinkFileName, PSTR lpTargetFileName, SYMBOLIC_LINK_FLAGS dwFlags, HANDLE hTransaction) => CreateSymbolicLinkTransactedA(lpSymlinkFileName, lpTargetFileName, dwFlags, hTransaction);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN CreateSymbolicLinkTransactedW(PWSTR lpSymlinkFileName, PWSTR lpTargetFileName, SYMBOLIC_LINK_FLAGS dwFlags, HANDLE hTransaction);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NtCreateFile(HANDLE* FileHandle, uint32 DesiredAccess, OBJECT_ATTRIBUTES* ObjectAttributes, IO_STATUS_BLOCK* IoStatusBlock, LARGE_INTEGER* AllocationSize, uint32 FileAttributes, FILE_SHARE_MODE ShareAccess, NT_CREATE_FILE_DISPOSITION CreateDisposition, uint32 CreateOptions, void* EaBuffer, uint32 EaLength);

}
#endregion
