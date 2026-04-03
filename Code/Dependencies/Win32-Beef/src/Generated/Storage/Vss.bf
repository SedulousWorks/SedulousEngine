using Win32.Foundation;
using Win32.System.Com;
using Win32.Data.Xml.MsXml;
using Win32.Storage.VirtualDiskService;
using System;

namespace Win32.Storage.Vss;

#region Constants
public static
{
	public const int32 VSS_ASSOC_NO_MAX_SPACE = -1;
	public const uint32 VSS_ASSOC_REMOVE = 0;
	public const HRESULT VSS_E_BAD_STATE = -2147212543;
	public const HRESULT VSS_E_UNEXPECTED = -2147212542;
	public const HRESULT VSS_E_PROVIDER_ALREADY_REGISTERED = -2147212541;
	public const HRESULT VSS_E_PROVIDER_NOT_REGISTERED = -2147212540;
	public const HRESULT VSS_E_PROVIDER_VETO = -2147212538;
	public const HRESULT VSS_E_PROVIDER_IN_USE = -2147212537;
	public const HRESULT VSS_E_OBJECT_NOT_FOUND = -2147212536;
	public const HRESULT VSS_S_ASYNC_PENDING = 271113;
	public const HRESULT VSS_S_ASYNC_FINISHED = 271114;
	public const HRESULT VSS_S_ASYNC_CANCELLED = 271115;
	public const HRESULT VSS_E_VOLUME_NOT_SUPPORTED = -2147212532;
	public const HRESULT VSS_E_VOLUME_NOT_SUPPORTED_BY_PROVIDER = -2147212530;
	public const HRESULT VSS_E_OBJECT_ALREADY_EXISTS = -2147212531;
	public const HRESULT VSS_E_UNEXPECTED_PROVIDER_ERROR = -2147212529;
	public const HRESULT VSS_E_CORRUPT_XML_DOCUMENT = -2147212528;
	public const HRESULT VSS_E_INVALID_XML_DOCUMENT = -2147212527;
	public const HRESULT VSS_E_MAXIMUM_NUMBER_OF_VOLUMES_REACHED = -2147212526;
	public const HRESULT VSS_E_FLUSH_WRITES_TIMEOUT = -2147212525;
	public const HRESULT VSS_E_HOLD_WRITES_TIMEOUT = -2147212524;
	public const HRESULT VSS_E_UNEXPECTED_WRITER_ERROR = -2147212523;
	public const HRESULT VSS_E_SNAPSHOT_SET_IN_PROGRESS = -2147212522;
	public const HRESULT VSS_E_MAXIMUM_NUMBER_OF_SNAPSHOTS_REACHED = -2147212521;
	public const HRESULT VSS_E_WRITER_INFRASTRUCTURE = -2147212520;
	public const HRESULT VSS_E_WRITER_NOT_RESPONDING = -2147212519;
	public const HRESULT VSS_E_WRITER_ALREADY_SUBSCRIBED = -2147212518;
	public const HRESULT VSS_E_UNSUPPORTED_CONTEXT = -2147212517;
	public const HRESULT VSS_E_VOLUME_IN_USE = -2147212515;
	public const HRESULT VSS_E_MAXIMUM_DIFFAREA_ASSOCIATIONS_REACHED = -2147212514;
	public const HRESULT VSS_E_INSUFFICIENT_STORAGE = -2147212513;
	public const HRESULT VSS_E_NO_SNAPSHOTS_IMPORTED = -2147212512;
	public const HRESULT VSS_S_SOME_SNAPSHOTS_NOT_IMPORTED = 271137;
	public const HRESULT VSS_E_SOME_SNAPSHOTS_NOT_IMPORTED = -2147212511;
	public const HRESULT VSS_E_MAXIMUM_NUMBER_OF_REMOTE_MACHINES_REACHED = -2147212510;
	public const HRESULT VSS_E_REMOTE_SERVER_UNAVAILABLE = -2147212509;
	public const HRESULT VSS_E_REMOTE_SERVER_UNSUPPORTED = -2147212508;
	public const HRESULT VSS_E_REVERT_IN_PROGRESS = -2147212507;
	public const HRESULT VSS_E_REVERT_VOLUME_LOST = -2147212506;
	public const HRESULT VSS_E_REBOOT_REQUIRED = -2147212505;
	public const HRESULT VSS_E_TRANSACTION_FREEZE_TIMEOUT = -2147212504;
	public const HRESULT VSS_E_TRANSACTION_THAW_TIMEOUT = -2147212503;
	public const HRESULT VSS_E_VOLUME_NOT_LOCAL = -2147212499;
	public const HRESULT VSS_E_CLUSTER_TIMEOUT = -2147212498;
	public const HRESULT VSS_E_WRITERERROR_INCONSISTENTSNAPSHOT = -2147212304;
	public const HRESULT VSS_E_WRITERERROR_OUTOFRESOURCES = -2147212303;
	public const HRESULT VSS_E_WRITERERROR_TIMEOUT = -2147212302;
	public const HRESULT VSS_E_WRITERERROR_RETRYABLE = -2147212301;
	public const HRESULT VSS_E_WRITERERROR_NONRETRYABLE = -2147212300;
	public const HRESULT VSS_E_WRITERERROR_RECOVERY_FAILED = -2147212299;
	public const HRESULT VSS_E_BREAK_REVERT_ID_FAILED = -2147212298;
	public const HRESULT VSS_E_LEGACY_PROVIDER = -2147212297;
	public const HRESULT VSS_E_MISSING_DISK = -2147212296;
	public const HRESULT VSS_E_MISSING_HIDDEN_VOLUME = -2147212295;
	public const HRESULT VSS_E_MISSING_VOLUME = -2147212294;
	public const HRESULT VSS_E_AUTORECOVERY_FAILED = -2147212293;
	public const HRESULT VSS_E_DYNAMIC_DISK_ERROR = -2147212292;
	public const HRESULT VSS_E_NONTRANSPORTABLE_BCD = -2147212291;
	public const HRESULT VSS_E_CANNOT_REVERT_DISKID = -2147212290;
	public const HRESULT VSS_E_RESYNC_IN_PROGRESS = -2147212289;
	public const HRESULT VSS_E_CLUSTER_ERROR = -2147212288;
	public const HRESULT VSS_E_UNSELECTED_VOLUME = -2147212502;
	public const HRESULT VSS_E_SNAPSHOT_NOT_IN_SET = -2147212501;
	public const HRESULT VSS_E_NESTED_VOLUME_LIMIT = -2147212500;
	public const HRESULT VSS_E_NOT_SUPPORTED = -2147212497;
	public const HRESULT VSS_E_WRITERERROR_PARTIAL_FAILURE = -2147212490;
	public const HRESULT VSS_E_ASRERROR_DISK_ASSIGNMENT_FAILED = -2147212287;
	public const HRESULT VSS_E_ASRERROR_DISK_RECREATION_FAILED = -2147212286;
	public const HRESULT VSS_E_ASRERROR_NO_ARCPATH = -2147212285;
	public const HRESULT VSS_E_ASRERROR_MISSING_DYNDISK = -2147212284;
	public const HRESULT VSS_E_ASRERROR_SHARED_CRIDISK = -2147212283;
	public const HRESULT VSS_E_ASRERROR_DATADISK_RDISK0 = -2147212282;
	public const HRESULT VSS_E_ASRERROR_RDISK0_TOOSMALL = -2147212281;
	public const HRESULT VSS_E_ASRERROR_CRITICAL_DISKS_TOO_SMALL = -2147212280;
	public const HRESULT VSS_E_WRITER_STATUS_NOT_AVAILABLE = -2147212279;
	public const HRESULT VSS_E_ASRERROR_DYNAMIC_VHD_NOT_SUPPORTED = -2147212278;
	public const HRESULT VSS_E_CRITICAL_VOLUME_ON_INVALID_DISK = -2147212271;
	public const HRESULT VSS_E_ASRERROR_RDISK_FOR_SYSTEM_DISK_NOT_FOUND = -2147212270;
	public const HRESULT VSS_E_ASRERROR_NO_PHYSICAL_DISK_AVAILABLE = -2147212269;
	public const HRESULT VSS_E_ASRERROR_FIXED_PHYSICAL_DISK_AVAILABLE_AFTER_DISK_EXCLUSION = -2147212268;
	public const HRESULT VSS_E_ASRERROR_CRITICAL_DISK_CANNOT_BE_EXCLUDED = -2147212267;
	public const HRESULT VSS_E_ASRERROR_SYSTEM_PARTITION_HIDDEN = -2147212266;
	public const HRESULT VSS_E_FSS_TIMEOUT = -2147212265;
}
#endregion

#region Enums

[AllowDuplicates]
public enum VSS_OBJECT_TYPE : int32
{
	VSS_OBJECT_UNKNOWN = 0,
	VSS_OBJECT_NONE = 1,
	VSS_OBJECT_SNAPSHOT_SET = 2,
	VSS_OBJECT_SNAPSHOT = 3,
	VSS_OBJECT_PROVIDER = 4,
	VSS_OBJECT_TYPE_COUNT = 5,
}


[AllowDuplicates]
public enum VSS_SNAPSHOT_STATE : int32
{
	VSS_SS_UNKNOWN = 0,
	VSS_SS_PREPARING = 1,
	VSS_SS_PROCESSING_PREPARE = 2,
	VSS_SS_PREPARED = 3,
	VSS_SS_PROCESSING_PRECOMMIT = 4,
	VSS_SS_PRECOMMITTED = 5,
	VSS_SS_PROCESSING_COMMIT = 6,
	VSS_SS_COMMITTED = 7,
	VSS_SS_PROCESSING_POSTCOMMIT = 8,
	VSS_SS_PROCESSING_PREFINALCOMMIT = 9,
	VSS_SS_PREFINALCOMMITTED = 10,
	VSS_SS_PROCESSING_POSTFINALCOMMIT = 11,
	VSS_SS_CREATED = 12,
	VSS_SS_ABORTED = 13,
	VSS_SS_DELETED = 14,
	VSS_SS_POSTCOMMITTED = 15,
	VSS_SS_COUNT = 16,
}


[AllowDuplicates]
public enum VSS_VOLUME_SNAPSHOT_ATTRIBUTES : int32
{
	VSS_VOLSNAP_ATTR_PERSISTENT = 1,
	VSS_VOLSNAP_ATTR_NO_AUTORECOVERY = 2,
	VSS_VOLSNAP_ATTR_CLIENT_ACCESSIBLE = 4,
	VSS_VOLSNAP_ATTR_NO_AUTO_RELEASE = 8,
	VSS_VOLSNAP_ATTR_NO_WRITERS = 16,
	VSS_VOLSNAP_ATTR_TRANSPORTABLE = 32,
	VSS_VOLSNAP_ATTR_NOT_SURFACED = 64,
	VSS_VOLSNAP_ATTR_NOT_TRANSACTED = 128,
	VSS_VOLSNAP_ATTR_HARDWARE_ASSISTED = 65536,
	VSS_VOLSNAP_ATTR_DIFFERENTIAL = 131072,
	VSS_VOLSNAP_ATTR_PLEX = 262144,
	VSS_VOLSNAP_ATTR_IMPORTED = 524288,
	VSS_VOLSNAP_ATTR_EXPOSED_LOCALLY = 1048576,
	VSS_VOLSNAP_ATTR_EXPOSED_REMOTELY = 2097152,
	VSS_VOLSNAP_ATTR_AUTORECOVER = 4194304,
	VSS_VOLSNAP_ATTR_ROLLBACK_RECOVERY = 8388608,
	VSS_VOLSNAP_ATTR_DELAYED_POSTSNAPSHOT = 16777216,
	VSS_VOLSNAP_ATTR_TXF_RECOVERY = 33554432,
	VSS_VOLSNAP_ATTR_FILE_SHARE = 67108864,
}


[AllowDuplicates]
public enum VSS_SNAPSHOT_CONTEXT : int32
{
	VSS_CTX_BACKUP = 0,
	VSS_CTX_FILE_SHARE_BACKUP = 16,
	VSS_CTX_NAS_ROLLBACK = 25,
	VSS_CTX_APP_ROLLBACK = 9,
	VSS_CTX_CLIENT_ACCESSIBLE = 29,
	VSS_CTX_CLIENT_ACCESSIBLE_WRITERS = 13,
	VSS_CTX_ALL = -1,
}


[AllowDuplicates]
public enum VSS_PROVIDER_CAPABILITIES : int32
{
	VSS_PRV_CAPABILITY_LEGACY = 1,
	VSS_PRV_CAPABILITY_COMPLIANT = 2,
	VSS_PRV_CAPABILITY_LUN_REPOINT = 4,
	VSS_PRV_CAPABILITY_LUN_RESYNC = 8,
	VSS_PRV_CAPABILITY_OFFLINE_CREATION = 16,
	VSS_PRV_CAPABILITY_MULTIPLE_IMPORT = 32,
	VSS_PRV_CAPABILITY_RECYCLING = 64,
	VSS_PRV_CAPABILITY_PLEX = 128,
	VSS_PRV_CAPABILITY_DIFFERENTIAL = 256,
	VSS_PRV_CAPABILITY_CLUSTERED = 512,
}


[AllowDuplicates]
public enum VSS_HARDWARE_OPTIONS : int32
{
	VSS_BREAKEX_FLAG_MASK_LUNS = 1,
	VSS_BREAKEX_FLAG_MAKE_READ_WRITE = 2,
	VSS_BREAKEX_FLAG_REVERT_IDENTITY_ALL = 4,
	VSS_BREAKEX_FLAG_REVERT_IDENTITY_NONE = 8,
	VSS_ONLUNSTATECHANGE_NOTIFY_READ_WRITE = 256,
	VSS_ONLUNSTATECHANGE_NOTIFY_LUN_PRE_RECOVERY = 512,
	VSS_ONLUNSTATECHANGE_NOTIFY_LUN_POST_RECOVERY = 1024,
	VSS_ONLUNSTATECHANGE_DO_MASK_LUNS = 2048,
}


[AllowDuplicates]
public enum VSS_RECOVERY_OPTIONS : int32
{
	VSS_RECOVERY_REVERT_IDENTITY_ALL = 256,
	VSS_RECOVERY_NO_VOLUME_CHECK = 512,
}


[AllowDuplicates]
public enum VSS_WRITER_STATE : int32
{
	VSS_WS_UNKNOWN = 0,
	VSS_WS_STABLE = 1,
	VSS_WS_WAITING_FOR_FREEZE = 2,
	VSS_WS_WAITING_FOR_THAW = 3,
	VSS_WS_WAITING_FOR_POST_SNAPSHOT = 4,
	VSS_WS_WAITING_FOR_BACKUP_COMPLETE = 5,
	VSS_WS_FAILED_AT_IDENTIFY = 6,
	VSS_WS_FAILED_AT_PREPARE_BACKUP = 7,
	VSS_WS_FAILED_AT_PREPARE_SNAPSHOT = 8,
	VSS_WS_FAILED_AT_FREEZE = 9,
	VSS_WS_FAILED_AT_THAW = 10,
	VSS_WS_FAILED_AT_POST_SNAPSHOT = 11,
	VSS_WS_FAILED_AT_BACKUP_COMPLETE = 12,
	VSS_WS_FAILED_AT_PRE_RESTORE = 13,
	VSS_WS_FAILED_AT_POST_RESTORE = 14,
	VSS_WS_FAILED_AT_BACKUPSHUTDOWN = 15,
	VSS_WS_COUNT = 16,
}


[AllowDuplicates]
public enum VSS_BACKUP_TYPE : int32
{
	VSS_BT_UNDEFINED = 0,
	VSS_BT_FULL = 1,
	VSS_BT_INCREMENTAL = 2,
	VSS_BT_DIFFERENTIAL = 3,
	VSS_BT_LOG = 4,
	VSS_BT_COPY = 5,
	VSS_BT_OTHER = 6,
}


[AllowDuplicates]
public enum VSS_RESTORE_TYPE : int32
{
	VSS_RTYPE_UNDEFINED = 0,
	VSS_RTYPE_BY_COPY = 1,
	VSS_RTYPE_IMPORT = 2,
	VSS_RTYPE_OTHER = 3,
}


[AllowDuplicates]
public enum VSS_ROLLFORWARD_TYPE : int32
{
	VSS_RF_UNDEFINED = 0,
	VSS_RF_NONE = 1,
	VSS_RF_ALL = 2,
	VSS_RF_PARTIAL = 3,
}


[AllowDuplicates]
public enum VSS_PROVIDER_TYPE : int32
{
	VSS_PROV_UNKNOWN = 0,
	VSS_PROV_SYSTEM = 1,
	VSS_PROV_SOFTWARE = 2,
	VSS_PROV_HARDWARE = 3,
	VSS_PROV_FILESHARE = 4,
}


[AllowDuplicates]
public enum VSS_APPLICATION_LEVEL : int32
{
	VSS_APP_UNKNOWN = 0,
	VSS_APP_SYSTEM = 1,
	VSS_APP_BACK_END = 2,
	VSS_APP_FRONT_END = 3,
	VSS_APP_SYSTEM_RM = 4,
	VSS_APP_AUTO = -1,
}


[AllowDuplicates]
public enum VSS_SNAPSHOT_COMPATIBILITY : int32
{
	VSS_SC_DISABLE_DEFRAG = 1,
	VSS_SC_DISABLE_CONTENTINDEX = 2,
}


[AllowDuplicates]
public enum VSS_SNAPSHOT_PROPERTY_ID : int32
{
	VSS_SPROPID_UNKNOWN = 0,
	VSS_SPROPID_SNAPSHOT_ID = 1,
	VSS_SPROPID_SNAPSHOT_SET_ID = 2,
	VSS_SPROPID_SNAPSHOTS_COUNT = 3,
	VSS_SPROPID_SNAPSHOT_DEVICE = 4,
	VSS_SPROPID_ORIGINAL_VOLUME = 5,
	VSS_SPROPID_ORIGINATING_MACHINE = 6,
	VSS_SPROPID_SERVICE_MACHINE = 7,
	VSS_SPROPID_EXPOSED_NAME = 8,
	VSS_SPROPID_EXPOSED_PATH = 9,
	VSS_SPROPID_PROVIDER_ID = 10,
	VSS_SPROPID_SNAPSHOT_ATTRIBUTES = 11,
	VSS_SPROPID_CREATION_TIMESTAMP = 12,
	VSS_SPROPID_STATUS = 13,
}


[AllowDuplicates]
public enum VSS_FILE_SPEC_BACKUP_TYPE : int32
{
	VSS_FSBT_FULL_BACKUP_REQUIRED = 1,
	VSS_FSBT_DIFFERENTIAL_BACKUP_REQUIRED = 2,
	VSS_FSBT_INCREMENTAL_BACKUP_REQUIRED = 4,
	VSS_FSBT_LOG_BACKUP_REQUIRED = 8,
	VSS_FSBT_FULL_SNAPSHOT_REQUIRED = 256,
	VSS_FSBT_DIFFERENTIAL_SNAPSHOT_REQUIRED = 512,
	VSS_FSBT_INCREMENTAL_SNAPSHOT_REQUIRED = 1024,
	VSS_FSBT_LOG_SNAPSHOT_REQUIRED = 2048,
	VSS_FSBT_CREATED_DURING_BACKUP = 65536,
	VSS_FSBT_ALL_BACKUP_REQUIRED = 15,
	VSS_FSBT_ALL_SNAPSHOT_REQUIRED = 3840,
}


[AllowDuplicates]
public enum VSS_BACKUP_SCHEMA : int32
{
	VSS_BS_UNDEFINED = 0,
	VSS_BS_DIFFERENTIAL = 1,
	VSS_BS_INCREMENTAL = 2,
	VSS_BS_EXCLUSIVE_INCREMENTAL_DIFFERENTIAL = 4,
	VSS_BS_LOG = 8,
	VSS_BS_COPY = 16,
	VSS_BS_TIMESTAMPED = 32,
	VSS_BS_LAST_MODIFY = 64,
	VSS_BS_LSN = 128,
	VSS_BS_WRITER_SUPPORTS_NEW_TARGET = 256,
	VSS_BS_WRITER_SUPPORTS_RESTORE_WITH_MOVE = 512,
	VSS_BS_INDEPENDENT_SYSTEM_STATE = 1024,
	VSS_BS_ROLLFORWARD_RESTORE = 4096,
	VSS_BS_RESTORE_RENAME = 8192,
	VSS_BS_AUTHORITATIVE_RESTORE = 16384,
	VSS_BS_WRITER_SUPPORTS_PARALLEL_RESTORES = 32768,
}


[AllowDuplicates]
public enum VSS_USAGE_TYPE : int32
{
	VSS_UT_UNDEFINED = 0,
	VSS_UT_BOOTABLESYSTEMSTATE = 1,
	VSS_UT_SYSTEMSERVICE = 2,
	VSS_UT_USERDATA = 3,
	VSS_UT_OTHER = 4,
}


[AllowDuplicates]
public enum VSS_SOURCE_TYPE : int32
{
	VSS_ST_UNDEFINED = 0,
	VSS_ST_TRANSACTEDDB = 1,
	VSS_ST_NONTRANSACTEDDB = 2,
	VSS_ST_OTHER = 3,
}


[AllowDuplicates]
public enum VSS_RESTOREMETHOD_ENUM : int32
{
	VSS_RME_UNDEFINED = 0,
	VSS_RME_RESTORE_IF_NOT_THERE = 1,
	VSS_RME_RESTORE_IF_CAN_REPLACE = 2,
	VSS_RME_STOP_RESTORE_START = 3,
	VSS_RME_RESTORE_TO_ALTERNATE_LOCATION = 4,
	VSS_RME_RESTORE_AT_REBOOT = 5,
	VSS_RME_RESTORE_AT_REBOOT_IF_CANNOT_REPLACE = 6,
	VSS_RME_CUSTOM = 7,
	VSS_RME_RESTORE_STOP_START = 8,
}


[AllowDuplicates]
public enum VSS_WRITERRESTORE_ENUM : int32
{
	VSS_WRE_UNDEFINED = 0,
	VSS_WRE_NEVER = 1,
	VSS_WRE_IF_REPLACE_FAILS = 2,
	VSS_WRE_ALWAYS = 3,
}


[AllowDuplicates]
public enum VSS_COMPONENT_TYPE : int32
{
	VSS_CT_UNDEFINED = 0,
	VSS_CT_DATABASE = 1,
	VSS_CT_FILEGROUP = 2,
}


[AllowDuplicates]
public enum VSS_ALTERNATE_WRITER_STATE : int32
{
	VSS_AWS_UNDEFINED = 0,
	VSS_AWS_NO_ALTERNATE_WRITER = 1,
	VSS_AWS_ALTERNATE_WRITER_EXISTS = 2,
	VSS_AWS_THIS_IS_ALTERNATE_WRITER = 3,
}


[AllowDuplicates]
public enum VSS_SUBSCRIBE_MASK : int32
{
	VSS_SM_POST_SNAPSHOT_FLAG = 1,
	VSS_SM_BACKUP_EVENTS_FLAG = 2,
	VSS_SM_RESTORE_EVENTS_FLAG = 4,
	VSS_SM_IO_THROTTLING_FLAG = 8,
	VSS_SM_ALL_FLAGS = -1,
}


[AllowDuplicates]
public enum VSS_RESTORE_TARGET : int32
{
	VSS_RT_UNDEFINED = 0,
	VSS_RT_ORIGINAL = 1,
	VSS_RT_ALTERNATE = 2,
	VSS_RT_DIRECTED = 3,
	VSS_RT_ORIGINAL_LOCATION = 4,
}


[AllowDuplicates]
public enum VSS_FILE_RESTORE_STATUS : int32
{
	VSS_RS_UNDEFINED = 0,
	VSS_RS_NONE = 1,
	VSS_RS_ALL = 2,
	VSS_RS_FAILED = 3,
}


[AllowDuplicates]
public enum VSS_COMPONENT_FLAGS : int32
{
	VSS_CF_BACKUP_RECOVERY = 1,
	VSS_CF_APP_ROLLBACK_RECOVERY = 2,
	VSS_CF_NOT_SYSTEM_STATE = 4,
}


[AllowDuplicates]
public enum VSS_MGMT_OBJECT_TYPE : int32
{
	VSS_MGMT_OBJECT_UNKNOWN = 0,
	VSS_MGMT_OBJECT_VOLUME = 1,
	VSS_MGMT_OBJECT_DIFF_VOLUME = 2,
	VSS_MGMT_OBJECT_DIFF_AREA = 3,
}


[AllowDuplicates]
public enum VSS_PROTECTION_LEVEL : int32
{
	VSS_PROTECTION_LEVEL_ORIGINAL_VOLUME = 0,
	VSS_PROTECTION_LEVEL_SNAPSHOT = 1,
}


[AllowDuplicates]
public enum VSS_PROTECTION_FAULT : int32
{
	VSS_PROTECTION_FAULT_NONE = 0,
	VSS_PROTECTION_FAULT_DIFF_AREA_MISSING = 1,
	VSS_PROTECTION_FAULT_IO_FAILURE_DURING_ONLINE = 2,
	VSS_PROTECTION_FAULT_META_DATA_CORRUPTION = 3,
	VSS_PROTECTION_FAULT_MEMORY_ALLOCATION_FAILURE = 4,
	VSS_PROTECTION_FAULT_MAPPED_MEMORY_FAILURE = 5,
	VSS_PROTECTION_FAULT_COW_READ_FAILURE = 6,
	VSS_PROTECTION_FAULT_COW_WRITE_FAILURE = 7,
	VSS_PROTECTION_FAULT_DIFF_AREA_FULL = 8,
	VSS_PROTECTION_FAULT_GROW_TOO_SLOW = 9,
	VSS_PROTECTION_FAULT_GROW_FAILED = 10,
	VSS_PROTECTION_FAULT_DESTROY_ALL_SNAPSHOTS = 11,
	VSS_PROTECTION_FAULT_FILE_SYSTEM_FAILURE = 12,
	VSS_PROTECTION_FAULT_IO_FAILURE = 13,
	VSS_PROTECTION_FAULT_DIFF_AREA_REMOVED = 14,
	VSS_PROTECTION_FAULT_EXTERNAL_WRITER_TO_DIFF_AREA = 15,
	VSS_PROTECTION_FAULT_MOUNT_DURING_CLUSTER_OFFLINE = 16,
}

#endregion


#region Structs
[CRepr]
public struct VSS_SNAPSHOT_PROP
{
	public Guid m_SnapshotId;
	public Guid m_SnapshotSetId;
	public int32 m_lSnapshotsCount;
	public uint16* m_pwszSnapshotDeviceObject;
	public uint16* m_pwszOriginalVolumeName;
	public uint16* m_pwszOriginatingMachine;
	public uint16* m_pwszServiceMachine;
	public uint16* m_pwszExposedName;
	public uint16* m_pwszExposedPath;
	public Guid m_ProviderId;
	public int32 m_lSnapshotAttributes;
	public int64 m_tsCreationTimestamp;
	public VSS_SNAPSHOT_STATE m_eStatus;
}

[CRepr]
public struct VSS_PROVIDER_PROP
{
	public Guid m_ProviderId;
	public uint16* m_pwszProviderName;
	public VSS_PROVIDER_TYPE m_eProviderType;
	public uint16* m_pwszProviderVersion;
	public Guid m_ProviderVersionId;
	public Guid m_ClassId;
}

[CRepr, Union]
public struct VSS_OBJECT_UNION
{
	public VSS_SNAPSHOT_PROP Snap;
	public VSS_PROVIDER_PROP Prov;
}

[CRepr]
public struct VSS_OBJECT_PROP
{
	public VSS_OBJECT_TYPE Type;
	public VSS_OBJECT_UNION Obj;
}

[CRepr]
public struct IVssExamineWriterMetadata
{
}

[CRepr]
public struct VSS_VOLUME_PROP
{
	public uint16* m_pwszVolumeName;
	public uint16* m_pwszVolumeDisplayName;
}

[CRepr]
public struct VSS_DIFF_VOLUME_PROP
{
	public uint16* m_pwszVolumeName;
	public uint16* m_pwszVolumeDisplayName;
	public int64 m_llVolumeFreeSpace;
	public int64 m_llVolumeTotalSpace;
}

[CRepr]
public struct VSS_DIFF_AREA_PROP
{
	public uint16* m_pwszVolumeName;
	public uint16* m_pwszDiffAreaVolumeName;
	public int64 m_llMaximumDiffSpace;
	public int64 m_llAllocatedDiffSpace;
	public int64 m_llUsedDiffSpace;
}

[CRepr, Union]
public struct VSS_MGMT_OBJECT_UNION
{
	public VSS_VOLUME_PROP Vol;
	public VSS_DIFF_VOLUME_PROP DiffVol;
	public VSS_DIFF_AREA_PROP DiffArea;
}

[CRepr]
public struct VSS_MGMT_OBJECT_PROP
{
	public VSS_MGMT_OBJECT_TYPE Type;
	public VSS_MGMT_OBJECT_UNION Obj;
}

[CRepr]
public struct VSS_VOLUME_PROTECTION_INFO
{
	public VSS_PROTECTION_LEVEL m_protectionLevel;
	public BOOL m_volumeIsOfflineForProtection;
	public VSS_PROTECTION_FAULT m_protectionFault;
	public int32 m_failureStatus;
	public BOOL m_volumeHasUnusedDiffArea;
	public uint32 m_reserved;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_VssSnapshotMgmt = .(0x0b5a2c52, 0x3eb9, 0x470a, 0x96, 0xe2, 0x6c, 0x6d, 0x45, 0x70, 0xe4, 0x0f);


	public const Guid CLSID_VSSCoordinator = .(0xe579ab5f, 0x1cc4, 0x44b4, 0xbe, 0xd9, 0xde, 0x09, 0x91, 0xff, 0x06, 0x23);


}
#endregion

#region COM Types
[CRepr]struct IVssEnumObject : IUnknown
{
	public new const Guid IID = .(0xae1c7110, 0x2f60, 0x11d3, 0x8a, 0x39, 0x00, 0xc0, 0x4f, 0x72, 0xd8, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VSS_OBJECT_PROP* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IVssEnumObject** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, VSS_OBJECT_PROP* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IVssEnumObject** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IVssAsync : IUnknown
{
	public new const Guid IID = .(0x507c37b4, 0xcf5b, 0x4e95, 0xb0, 0xaf, 0x14, 0xeb, 0x97, 0x67, 0x46, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMilliseconds) Wait;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* pHrResult, int32* pReserved) QueryStatus;
	}


	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Wait(uint32 dwMilliseconds) mut => VT.[Friend]Wait(&this, dwMilliseconds);

	public HRESULT QueryStatus(HRESULT* pHrResult, int32* pReserved) mut => VT.[Friend]QueryStatus(&this, pHrResult, pReserved);
}

[CRepr]struct IVssWMFiledesc : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFilespec) GetFilespec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, bool* pbRecursive) GetRecursive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAlternateLocation) GetAlternateLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwTypeMask) GetBackupTypeMask;
	}


	public HRESULT GetPath(BSTR* pbstrPath) mut => VT.[Friend]GetPath(&this, pbstrPath);

	public HRESULT GetFilespec(BSTR* pbstrFilespec) mut => VT.[Friend]GetFilespec(&this, pbstrFilespec);

	public HRESULT GetRecursive(bool* pbRecursive) mut => VT.[Friend]GetRecursive(&this, pbRecursive);

	public HRESULT GetAlternateLocation(BSTR* pbstrAlternateLocation) mut => VT.[Friend]GetAlternateLocation(&this, pbstrAlternateLocation);

	public HRESULT GetBackupTypeMask(uint32* pdwTypeMask) mut => VT.[Friend]GetBackupTypeMask(&this, pdwTypeMask);
}

[CRepr]struct IVssWMDependency : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pWriterId) GetWriterId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLogicalPath) GetLogicalPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrComponentName) GetComponentName;
	}


	public HRESULT GetWriterId(Guid* pWriterId) mut => VT.[Friend]GetWriterId(&this, pWriterId);

	public HRESULT GetLogicalPath(BSTR* pbstrLogicalPath) mut => VT.[Friend]GetLogicalPath(&this, pbstrLogicalPath);

	public HRESULT GetComponentName(BSTR* pbstrComponentName) mut => VT.[Friend]GetComponentName(&this, pbstrComponentName);
}

[CRepr]struct IVssComponent : IUnknown
{
	public new const Guid IID = .(0xd2c72c96, 0xc121, 0x4518, 0xb6, 0x27, 0xe5, 0xa9, 0x3d, 0x01, 0x0e, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPath) GetLogicalPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_COMPONENT_TYPE* pct) GetComponentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) GetComponentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, bool* pbSucceeded) GetBackupSucceeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcMappings) GetAlternateLocationMappingCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iMapping, IVssWMFiledesc** ppFiledesc) GetAlternateLocationMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszData) SetBackupMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrData) GetBackupMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPath, PWSTR wszFilename, PWSTR wszRanges, PWSTR wszMetadata) AddPartialFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcPartialFiles) GetPartialFileCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iPartialFile, BSTR* pbstrPath, BSTR* pbstrFilename, BSTR* pbstrRange, BSTR* pbstrMetadata) GetPartialFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, bool* pbSelectedForRestore) IsSelectedForRestore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, bool* pbAdditionalRestores) GetAdditionalRestores;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcNewTarget) GetNewTargetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iNewTarget, IVssWMFiledesc** ppFiledesc) GetNewTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszSourcePath, PWSTR wszSourceFilename, PWSTR wszSourceRangeList, PWSTR wszDestinationPath, PWSTR wszDestinationFilename, PWSTR wszDestinationRangeList) AddDirectedTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcDirectedTarget) GetDirectedTargetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iDirectedTarget, BSTR* pbstrSourcePath, BSTR* pbstrSourceFileName, BSTR* pbstrSourceRangeList, BSTR* pbstrDestinationPath, BSTR* pbstrDestinationFilename, BSTR* pbstrDestinationRangeList) GetDirectedTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszRestoreMetadata) SetRestoreMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRestoreMetadata) GetRestoreMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_RESTORE_TARGET target) SetRestoreTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_RESTORE_TARGET* pTarget) GetRestoreTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPreRestoreFailureMsg) SetPreRestoreFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPreRestoreFailureMsg) GetPreRestoreFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPostRestoreFailureMsg) SetPostRestoreFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPostRestoreFailureMsg) GetPostRestoreFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszBackupStamp) SetBackupStamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBackupStamp) GetBackupStamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBackupStamp) GetPreviousBackupStamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBackupOptions) GetBackupOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRestoreOptions) GetRestoreOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcRestoreSubcomponent) GetRestoreSubcomponentCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iComponent, BSTR* pbstrLogicalPath, BSTR* pbstrComponentName, bool* pbRepair) GetRestoreSubcomponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_FILE_RESTORE_STATUS* pStatus) GetFileRestoreStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPath, PWSTR wszFilespec, BOOL bRecursive, FILETIME ftLastModifyTime) AddDifferencedFilesByLastModifyTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPath, PWSTR wszFilespec, BOOL bRecursive, BSTR bstrLsnString) AddDifferencedFilesByLastModifyLSN;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcDifferencedFiles) GetDifferencedFilesCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iDifferencedFile, BSTR* pbstrPath, BSTR* pbstrFilespec, BOOL* pbRecursive, BSTR* pbstrLsnString, FILETIME* pftLastModifyTime) GetDifferencedFile;
	}


	public HRESULT GetLogicalPath(BSTR* pbstrPath) mut => VT.[Friend]GetLogicalPath(&this, pbstrPath);

	public HRESULT GetComponentType(VSS_COMPONENT_TYPE* pct) mut => VT.[Friend]GetComponentType(&this, pct);

	public HRESULT GetComponentName(BSTR* pbstrName) mut => VT.[Friend]GetComponentName(&this, pbstrName);

	public HRESULT GetBackupSucceeded(bool* pbSucceeded) mut => VT.[Friend]GetBackupSucceeded(&this, pbSucceeded);

	public HRESULT GetAlternateLocationMappingCount(uint32* pcMappings) mut => VT.[Friend]GetAlternateLocationMappingCount(&this, pcMappings);

	public HRESULT GetAlternateLocationMapping(uint32 iMapping, IVssWMFiledesc** ppFiledesc) mut => VT.[Friend]GetAlternateLocationMapping(&this, iMapping, ppFiledesc);

	public HRESULT SetBackupMetadata(PWSTR wszData) mut => VT.[Friend]SetBackupMetadata(&this, wszData);

	public HRESULT GetBackupMetadata(BSTR* pbstrData) mut => VT.[Friend]GetBackupMetadata(&this, pbstrData);

	public HRESULT AddPartialFile(PWSTR wszPath, PWSTR wszFilename, PWSTR wszRanges, PWSTR wszMetadata) mut => VT.[Friend]AddPartialFile(&this, wszPath, wszFilename, wszRanges, wszMetadata);

	public HRESULT GetPartialFileCount(uint32* pcPartialFiles) mut => VT.[Friend]GetPartialFileCount(&this, pcPartialFiles);

	public HRESULT GetPartialFile(uint32 iPartialFile, BSTR* pbstrPath, BSTR* pbstrFilename, BSTR* pbstrRange, BSTR* pbstrMetadata) mut => VT.[Friend]GetPartialFile(&this, iPartialFile, pbstrPath, pbstrFilename, pbstrRange, pbstrMetadata);

	public HRESULT IsSelectedForRestore(bool* pbSelectedForRestore) mut => VT.[Friend]IsSelectedForRestore(&this, pbSelectedForRestore);

	public HRESULT GetAdditionalRestores(bool* pbAdditionalRestores) mut => VT.[Friend]GetAdditionalRestores(&this, pbAdditionalRestores);

	public HRESULT GetNewTargetCount(uint32* pcNewTarget) mut => VT.[Friend]GetNewTargetCount(&this, pcNewTarget);

	public HRESULT GetNewTarget(uint32 iNewTarget, IVssWMFiledesc** ppFiledesc) mut => VT.[Friend]GetNewTarget(&this, iNewTarget, ppFiledesc);

	public HRESULT AddDirectedTarget(PWSTR wszSourcePath, PWSTR wszSourceFilename, PWSTR wszSourceRangeList, PWSTR wszDestinationPath, PWSTR wszDestinationFilename, PWSTR wszDestinationRangeList) mut => VT.[Friend]AddDirectedTarget(&this, wszSourcePath, wszSourceFilename, wszSourceRangeList, wszDestinationPath, wszDestinationFilename, wszDestinationRangeList);

	public HRESULT GetDirectedTargetCount(uint32* pcDirectedTarget) mut => VT.[Friend]GetDirectedTargetCount(&this, pcDirectedTarget);

	public HRESULT GetDirectedTarget(uint32 iDirectedTarget, BSTR* pbstrSourcePath, BSTR* pbstrSourceFileName, BSTR* pbstrSourceRangeList, BSTR* pbstrDestinationPath, BSTR* pbstrDestinationFilename, BSTR* pbstrDestinationRangeList) mut => VT.[Friend]GetDirectedTarget(&this, iDirectedTarget, pbstrSourcePath, pbstrSourceFileName, pbstrSourceRangeList, pbstrDestinationPath, pbstrDestinationFilename, pbstrDestinationRangeList);

	public HRESULT SetRestoreMetadata(PWSTR wszRestoreMetadata) mut => VT.[Friend]SetRestoreMetadata(&this, wszRestoreMetadata);

	public HRESULT GetRestoreMetadata(BSTR* pbstrRestoreMetadata) mut => VT.[Friend]GetRestoreMetadata(&this, pbstrRestoreMetadata);

	public HRESULT SetRestoreTarget(VSS_RESTORE_TARGET target) mut => VT.[Friend]SetRestoreTarget(&this, target);

	public HRESULT GetRestoreTarget(VSS_RESTORE_TARGET* pTarget) mut => VT.[Friend]GetRestoreTarget(&this, pTarget);

	public HRESULT SetPreRestoreFailureMsg(PWSTR wszPreRestoreFailureMsg) mut => VT.[Friend]SetPreRestoreFailureMsg(&this, wszPreRestoreFailureMsg);

	public HRESULT GetPreRestoreFailureMsg(BSTR* pbstrPreRestoreFailureMsg) mut => VT.[Friend]GetPreRestoreFailureMsg(&this, pbstrPreRestoreFailureMsg);

	public HRESULT SetPostRestoreFailureMsg(PWSTR wszPostRestoreFailureMsg) mut => VT.[Friend]SetPostRestoreFailureMsg(&this, wszPostRestoreFailureMsg);

	public HRESULT GetPostRestoreFailureMsg(BSTR* pbstrPostRestoreFailureMsg) mut => VT.[Friend]GetPostRestoreFailureMsg(&this, pbstrPostRestoreFailureMsg);

	public HRESULT SetBackupStamp(PWSTR wszBackupStamp) mut => VT.[Friend]SetBackupStamp(&this, wszBackupStamp);

	public HRESULT GetBackupStamp(BSTR* pbstrBackupStamp) mut => VT.[Friend]GetBackupStamp(&this, pbstrBackupStamp);

	public HRESULT GetPreviousBackupStamp(BSTR* pbstrBackupStamp) mut => VT.[Friend]GetPreviousBackupStamp(&this, pbstrBackupStamp);

	public HRESULT GetBackupOptions(BSTR* pbstrBackupOptions) mut => VT.[Friend]GetBackupOptions(&this, pbstrBackupOptions);

	public HRESULT GetRestoreOptions(BSTR* pbstrRestoreOptions) mut => VT.[Friend]GetRestoreOptions(&this, pbstrRestoreOptions);

	public HRESULT GetRestoreSubcomponentCount(uint32* pcRestoreSubcomponent) mut => VT.[Friend]GetRestoreSubcomponentCount(&this, pcRestoreSubcomponent);

	public HRESULT GetRestoreSubcomponent(uint32 iComponent, BSTR* pbstrLogicalPath, BSTR* pbstrComponentName, bool* pbRepair) mut => VT.[Friend]GetRestoreSubcomponent(&this, iComponent, pbstrLogicalPath, pbstrComponentName, pbRepair);

	public HRESULT GetFileRestoreStatus(VSS_FILE_RESTORE_STATUS* pStatus) mut => VT.[Friend]GetFileRestoreStatus(&this, pStatus);

	public HRESULT AddDifferencedFilesByLastModifyTime(PWSTR wszPath, PWSTR wszFilespec, BOOL bRecursive, FILETIME ftLastModifyTime) mut => VT.[Friend]AddDifferencedFilesByLastModifyTime(&this, wszPath, wszFilespec, bRecursive, ftLastModifyTime);

	public HRESULT AddDifferencedFilesByLastModifyLSN(PWSTR wszPath, PWSTR wszFilespec, BOOL bRecursive, BSTR bstrLsnString) mut => VT.[Friend]AddDifferencedFilesByLastModifyLSN(&this, wszPath, wszFilespec, bRecursive, bstrLsnString);

	public HRESULT GetDifferencedFilesCount(uint32* pcDifferencedFiles) mut => VT.[Friend]GetDifferencedFilesCount(&this, pcDifferencedFiles);

	public HRESULT GetDifferencedFile(uint32 iDifferencedFile, BSTR* pbstrPath, BSTR* pbstrFilespec, BOOL* pbRecursive, BSTR* pbstrLsnString, FILETIME* pftLastModifyTime) mut => VT.[Friend]GetDifferencedFile(&this, iDifferencedFile, pbstrPath, pbstrFilespec, pbRecursive, pbstrLsnString, pftLastModifyTime);
}

[CRepr]struct IVssWriterComponents
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcComponents) GetComponentCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pidInstance, Guid* pidWriter) GetWriterInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iComponent, IVssComponent** ppComponent) GetComponent;
	}


	public HRESULT GetComponentCount(uint32* pcComponents) mut => VT.[Friend]GetComponentCount(&this, pcComponents);

	public HRESULT GetWriterInfo(Guid* pidInstance, Guid* pidWriter) mut => VT.[Friend]GetWriterInfo(&this, pidInstance, pidWriter);

	public HRESULT GetComponent(uint32 iComponent, IVssComponent** ppComponent) mut => VT.[Friend]GetComponent(&this, iComponent, ppComponent);
}

[CRepr]struct IVssComponentEx : IVssComponent
{
	public new const Guid IID = .(0x156c8b5e, 0xf131, 0x4bd7, 0x9c, 0x97, 0xd1, 0x92, 0x3b, 0xe7, 0xe1, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVssComponent.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszFailureMsg) SetPrepareForBackupFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszFailureMsg) SetPostSnapshotFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFailureMsg) GetPrepareForBackupFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFailureMsg) GetPostSnapshotFailureMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, bool* pbAuth) GetAuthoritativeRestore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_ROLLFORWARD_TYPE* pRollType, BSTR* pbstrPoint) GetRollForward;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) GetRestoreName;
	}


	public HRESULT SetPrepareForBackupFailureMsg(PWSTR wszFailureMsg) mut => VT.[Friend]SetPrepareForBackupFailureMsg(&this, wszFailureMsg);

	public HRESULT SetPostSnapshotFailureMsg(PWSTR wszFailureMsg) mut => VT.[Friend]SetPostSnapshotFailureMsg(&this, wszFailureMsg);

	public HRESULT GetPrepareForBackupFailureMsg(BSTR* pbstrFailureMsg) mut => VT.[Friend]GetPrepareForBackupFailureMsg(&this, pbstrFailureMsg);

	public HRESULT GetPostSnapshotFailureMsg(BSTR* pbstrFailureMsg) mut => VT.[Friend]GetPostSnapshotFailureMsg(&this, pbstrFailureMsg);

	public HRESULT GetAuthoritativeRestore(bool* pbAuth) mut => VT.[Friend]GetAuthoritativeRestore(&this, pbAuth);

	public HRESULT GetRollForward(VSS_ROLLFORWARD_TYPE* pRollType, BSTR* pbstrPoint) mut => VT.[Friend]GetRollForward(&this, pRollType, pbstrPoint);

	public HRESULT GetRestoreName(BSTR* pbstrName) mut => VT.[Friend]GetRestoreName(&this, pbstrName);
}

[CRepr]struct IVssComponentEx2 : IVssComponentEx
{
	public new const Guid IID = .(0x3b5be0f2, 0x07a9, 0x4e4b, 0xbd, 0xd3, 0xcf, 0xdc, 0x8e, 0x2c, 0x0d, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVssComponentEx.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, HRESULT hrApplication, PWSTR wszApplicationMessage, uint32 dwReserved) SetFailure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phr, HRESULT* phrApplication, BSTR* pbstrApplicationMessage, uint32* pdwReserved) GetFailure;
	}


	public HRESULT SetFailure(HRESULT hr, HRESULT hrApplication, PWSTR wszApplicationMessage, uint32 dwReserved) mut => VT.[Friend]SetFailure(&this, hr, hrApplication, wszApplicationMessage, dwReserved);

	public HRESULT GetFailure(HRESULT* phr, HRESULT* phrApplication, BSTR* pbstrApplicationMessage, uint32* pdwReserved) mut => VT.[Friend]GetFailure(&this, phr, phrApplication, pbstrApplicationMessage, pdwReserved);
}

[CRepr]struct IVssCreateWriterMetadata
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive, PWSTR wszAlternateLocation) AddIncludeFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive) AddExcludeFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_COMPONENT_TYPE ct, PWSTR wszLogicalPath, PWSTR wszComponentName, PWSTR wszCaption, uint8* pbIcon, uint32 cbIcon, uint8 bRestoreMetadata, uint8 bNotifyOnBackupComplete, uint8 bSelectable, uint8 bSelectableForRestore, uint32 dwComponentFlags) AddComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszLogicalPath, PWSTR wszDatabaseName, PWSTR wszPath, PWSTR wszFilespec, uint32 dwBackupTypeMask) AddDatabaseFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszLogicalPath, PWSTR wszDatabaseName, PWSTR wszPath, PWSTR wszFilespec, uint32 dwBackupTypeMask) AddDatabaseLogFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszLogicalPath, PWSTR wszGroupName, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive, PWSTR wszAlternateLocation, uint32 dwBackupTypeMask) AddFilesToFileGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_RESTOREMETHOD_ENUM method, PWSTR wszService, PWSTR wszUserProcedure, VSS_WRITERRESTORE_ENUM writerRestore, uint8 bRebootRequired) SetRestoreMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszSourcePath, PWSTR wszSourceFilespec, uint8 bRecursive, PWSTR wszDestination) AddAlternateLocationMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszForLogicalPath, PWSTR wszForComponentName, Guid onWriterId, PWSTR wszOnLogicalPath, PWSTR wszOnComponentName) AddComponentDependency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSchemaMask) SetBackupSchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXMLDOMDocument** pDoc) GetDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrXML) SaveAsXML;
	}


	public HRESULT AddIncludeFiles(PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive, PWSTR wszAlternateLocation) mut => VT.[Friend]AddIncludeFiles(&this, wszPath, wszFilespec, bRecursive, wszAlternateLocation);

	public HRESULT AddExcludeFiles(PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive) mut => VT.[Friend]AddExcludeFiles(&this, wszPath, wszFilespec, bRecursive);

	public HRESULT AddComponent(VSS_COMPONENT_TYPE ct, PWSTR wszLogicalPath, PWSTR wszComponentName, PWSTR wszCaption, uint8* pbIcon, uint32 cbIcon, uint8 bRestoreMetadata, uint8 bNotifyOnBackupComplete, uint8 bSelectable, uint8 bSelectableForRestore, uint32 dwComponentFlags) mut => VT.[Friend]AddComponent(&this, ct, wszLogicalPath, wszComponentName, wszCaption, pbIcon, cbIcon, bRestoreMetadata, bNotifyOnBackupComplete, bSelectable, bSelectableForRestore, dwComponentFlags);

	public HRESULT AddDatabaseFiles(PWSTR wszLogicalPath, PWSTR wszDatabaseName, PWSTR wszPath, PWSTR wszFilespec, uint32 dwBackupTypeMask) mut => VT.[Friend]AddDatabaseFiles(&this, wszLogicalPath, wszDatabaseName, wszPath, wszFilespec, dwBackupTypeMask);

	public HRESULT AddDatabaseLogFiles(PWSTR wszLogicalPath, PWSTR wszDatabaseName, PWSTR wszPath, PWSTR wszFilespec, uint32 dwBackupTypeMask) mut => VT.[Friend]AddDatabaseLogFiles(&this, wszLogicalPath, wszDatabaseName, wszPath, wszFilespec, dwBackupTypeMask);

	public HRESULT AddFilesToFileGroup(PWSTR wszLogicalPath, PWSTR wszGroupName, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive, PWSTR wszAlternateLocation, uint32 dwBackupTypeMask) mut => VT.[Friend]AddFilesToFileGroup(&this, wszLogicalPath, wszGroupName, wszPath, wszFilespec, bRecursive, wszAlternateLocation, dwBackupTypeMask);

	public HRESULT SetRestoreMethod(VSS_RESTOREMETHOD_ENUM method, PWSTR wszService, PWSTR wszUserProcedure, VSS_WRITERRESTORE_ENUM writerRestore, uint8 bRebootRequired) mut => VT.[Friend]SetRestoreMethod(&this, method, wszService, wszUserProcedure, writerRestore, bRebootRequired);

	public HRESULT AddAlternateLocationMapping(PWSTR wszSourcePath, PWSTR wszSourceFilespec, uint8 bRecursive, PWSTR wszDestination) mut => VT.[Friend]AddAlternateLocationMapping(&this, wszSourcePath, wszSourceFilespec, bRecursive, wszDestination);

	public HRESULT AddComponentDependency(PWSTR wszForLogicalPath, PWSTR wszForComponentName, Guid onWriterId, PWSTR wszOnLogicalPath, PWSTR wszOnComponentName) mut => VT.[Friend]AddComponentDependency(&this, wszForLogicalPath, wszForComponentName, onWriterId, wszOnLogicalPath, wszOnComponentName);

	public HRESULT SetBackupSchema(uint32 dwSchemaMask) mut => VT.[Friend]SetBackupSchema(&this, dwSchemaMask);

	public HRESULT GetDocument(IXMLDOMDocument** pDoc) mut => VT.[Friend]GetDocument(&this, pDoc);

	public HRESULT SaveAsXML(BSTR* pbstrXML) mut => VT.[Friend]SaveAsXML(&this, pbstrXML);
}

[CRepr]struct IVssWriterImpl : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid writerId, PWSTR wszWriterName, PWSTR wszWriterInstanceName, uint32 dwMajorVersion, uint32 dwMinorVersion, VSS_USAGE_TYPE ut, VSS_SOURCE_TYPE st, VSS_APPLICATION_LEVEL nLevel, uint32 dwTimeout, VSS_ALTERNATE_WRITER_STATE aws, uint8 bIOThrottlingOnly) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSubscribeTimeout, uint32 dwEventFlags) Subscribe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unsubscribe;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] PWSTR*(SelfOuter* self) GetCurrentVolumeArray;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetCurrentVolumeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszOriginalVolume, PWSTR* ppwszSnapshotDevice) GetSnapshotDeviceName;
		protected new function [CallingConvention(.Stdcall)] Guid(SelfOuter* self) GetCurrentSnapshotSetId;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self) GetContext;
		protected new function [CallingConvention(.Stdcall)] VSS_APPLICATION_LEVEL(SelfOuter* self) GetCurrentLevel;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, PWSTR wszPath) IsPathAffected;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsBootableSystemStateBackedUp;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) AreComponentsSelected;
		protected new function [CallingConvention(.Stdcall)] VSS_BACKUP_TYPE(SelfOuter* self) GetBackupType;
		protected new function [CallingConvention(.Stdcall)] VSS_RESTORE_TYPE(SelfOuter* self) GetRestoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) SetWriterFailure;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsPartialFileSupportEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid idWriter, Guid clsid) InstallAlternateWriter;
		protected new function [CallingConvention(.Stdcall)] IVssExamineWriterMetadata*(SelfOuter* self) GetIdentityInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, HRESULT hrApplication, PWSTR wszApplicationMessage) SetWriterFailureEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* idSession) GetSessionId;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsWriterShuttingDown;
	}


	public HRESULT Initialize(Guid writerId, PWSTR wszWriterName, PWSTR wszWriterInstanceName, uint32 dwMajorVersion, uint32 dwMinorVersion, VSS_USAGE_TYPE ut, VSS_SOURCE_TYPE st, VSS_APPLICATION_LEVEL nLevel, uint32 dwTimeout, VSS_ALTERNATE_WRITER_STATE aws, uint8 bIOThrottlingOnly) mut => VT.[Friend]Initialize(&this, writerId, wszWriterName, wszWriterInstanceName, dwMajorVersion, dwMinorVersion, ut, st, nLevel, dwTimeout, aws, bIOThrottlingOnly);

	public HRESULT Subscribe(uint32 dwSubscribeTimeout, uint32 dwEventFlags) mut => VT.[Friend]Subscribe(&this, dwSubscribeTimeout, dwEventFlags);

	public HRESULT Unsubscribe() mut => VT.[Friend]Unsubscribe(&this);

	public void Uninitialize() mut => VT.[Friend]Uninitialize(&this);

	public PWSTR* GetCurrentVolumeArray() mut => VT.[Friend]GetCurrentVolumeArray(&this);

	public uint32 GetCurrentVolumeCount() mut => VT.[Friend]GetCurrentVolumeCount(&this);

	public HRESULT GetSnapshotDeviceName(PWSTR wszOriginalVolume, PWSTR* ppwszSnapshotDevice) mut => VT.[Friend]GetSnapshotDeviceName(&this, wszOriginalVolume, ppwszSnapshotDevice);

	public Guid GetCurrentSnapshotSetId() mut => VT.[Friend]GetCurrentSnapshotSetId(&this);

	public int32 GetContext() mut => VT.[Friend]GetContext(&this);

	public VSS_APPLICATION_LEVEL GetCurrentLevel() mut => VT.[Friend]GetCurrentLevel(&this);

	public bool IsPathAffected(PWSTR wszPath) mut => VT.[Friend]IsPathAffected(&this, wszPath);

	public bool IsBootableSystemStateBackedUp() mut => VT.[Friend]IsBootableSystemStateBackedUp(&this);

	public bool AreComponentsSelected() mut => VT.[Friend]AreComponentsSelected(&this);

	public VSS_BACKUP_TYPE GetBackupType() mut => VT.[Friend]GetBackupType(&this);

	public VSS_RESTORE_TYPE GetRestoreType() mut => VT.[Friend]GetRestoreType(&this);

	public HRESULT SetWriterFailure(HRESULT hr) mut => VT.[Friend]SetWriterFailure(&this, hr);

	public bool IsPartialFileSupportEnabled() mut => VT.[Friend]IsPartialFileSupportEnabled(&this);

	public HRESULT InstallAlternateWriter(Guid idWriter, Guid clsid) mut => VT.[Friend]InstallAlternateWriter(&this, idWriter, clsid);

	public IVssExamineWriterMetadata* GetIdentityInformation() mut => VT.[Friend]GetIdentityInformation(&this);

	public HRESULT SetWriterFailureEx(HRESULT hr, HRESULT hrApplication, PWSTR wszApplicationMessage) mut => VT.[Friend]SetWriterFailureEx(&this, hr, hrApplication, wszApplicationMessage);

	public HRESULT GetSessionId(Guid* idSession) mut => VT.[Friend]GetSessionId(&this, idSession);

	public bool IsWriterShuttingDown() mut => VT.[Friend]IsWriterShuttingDown(&this);
}

[CRepr]struct IVssCreateExpressWriterMetadata : IUnknown
{
	public new const Guid IID = .(0x9c772e77, 0xb26e, 0x427f, 0x92, 0xdd, 0xc9, 0x96, 0xf4, 0x1e, 0xa5, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive) AddExcludeFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_COMPONENT_TYPE ct, PWSTR wszLogicalPath, PWSTR wszComponentName, PWSTR wszCaption, uint8* pbIcon, uint32 cbIcon, uint8 bRestoreMetadata, uint8 bNotifyOnBackupComplete, uint8 bSelectable, uint8 bSelectableForRestore, uint32 dwComponentFlags) AddComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszLogicalPath, PWSTR wszGroupName, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive, PWSTR wszAlternateLocation, uint32 dwBackupTypeMask) AddFilesToFileGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VSS_RESTOREMETHOD_ENUM method, PWSTR wszService, PWSTR wszUserProcedure, VSS_WRITERRESTORE_ENUM writerRestore, uint8 bRebootRequired) SetRestoreMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszForLogicalPath, PWSTR wszForComponentName, Guid onWriterId, PWSTR wszOnLogicalPath, PWSTR wszOnComponentName) AddComponentDependency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSchemaMask) SetBackupSchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrXML) SaveAsXML;
	}


	public HRESULT AddExcludeFiles(PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive) mut => VT.[Friend]AddExcludeFiles(&this, wszPath, wszFilespec, bRecursive);

	public HRESULT AddComponent(VSS_COMPONENT_TYPE ct, PWSTR wszLogicalPath, PWSTR wszComponentName, PWSTR wszCaption, uint8* pbIcon, uint32 cbIcon, uint8 bRestoreMetadata, uint8 bNotifyOnBackupComplete, uint8 bSelectable, uint8 bSelectableForRestore, uint32 dwComponentFlags) mut => VT.[Friend]AddComponent(&this, ct, wszLogicalPath, wszComponentName, wszCaption, pbIcon, cbIcon, bRestoreMetadata, bNotifyOnBackupComplete, bSelectable, bSelectableForRestore, dwComponentFlags);

	public HRESULT AddFilesToFileGroup(PWSTR wszLogicalPath, PWSTR wszGroupName, PWSTR wszPath, PWSTR wszFilespec, uint8 bRecursive, PWSTR wszAlternateLocation, uint32 dwBackupTypeMask) mut => VT.[Friend]AddFilesToFileGroup(&this, wszLogicalPath, wszGroupName, wszPath, wszFilespec, bRecursive, wszAlternateLocation, dwBackupTypeMask);

	public HRESULT SetRestoreMethod(VSS_RESTOREMETHOD_ENUM method, PWSTR wszService, PWSTR wszUserProcedure, VSS_WRITERRESTORE_ENUM writerRestore, uint8 bRebootRequired) mut => VT.[Friend]SetRestoreMethod(&this, method, wszService, wszUserProcedure, writerRestore, bRebootRequired);

	public HRESULT AddComponentDependency(PWSTR wszForLogicalPath, PWSTR wszForComponentName, Guid onWriterId, PWSTR wszOnLogicalPath, PWSTR wszOnComponentName) mut => VT.[Friend]AddComponentDependency(&this, wszForLogicalPath, wszForComponentName, onWriterId, wszOnLogicalPath, wszOnComponentName);

	public HRESULT SetBackupSchema(uint32 dwSchemaMask) mut => VT.[Friend]SetBackupSchema(&this, dwSchemaMask);

	public HRESULT SaveAsXML(BSTR* pbstrXML) mut => VT.[Friend]SaveAsXML(&this, pbstrXML);
}

[CRepr]struct IVssExpressWriter : IUnknown
{
	public new const Guid IID = .(0xe33affdc, 0x59c7, 0x47b1, 0x97, 0xd5, 0x42, 0x66, 0x59, 0x8f, 0x62, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid writerId, PWSTR writerName, VSS_USAGE_TYPE usageType, uint32 versionMajor, uint32 versionMinor, uint32 reserved, IVssCreateExpressWriterMetadata** ppMetadata) CreateMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR metadata, uint32 reserved) LoadMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid writerId) Unregister;
	}


	public HRESULT CreateMetadata(Guid writerId, PWSTR writerName, VSS_USAGE_TYPE usageType, uint32 versionMajor, uint32 versionMinor, uint32 reserved, IVssCreateExpressWriterMetadata** ppMetadata) mut => VT.[Friend]CreateMetadata(&this, writerId, writerName, usageType, versionMajor, versionMinor, reserved, ppMetadata);

	public HRESULT LoadMetadata(PWSTR metadata, uint32 reserved) mut => VT.[Friend]LoadMetadata(&this, metadata, reserved);

	public HRESULT Register() mut => VT.[Friend]Register(&this);

	public HRESULT Unregister(Guid writerId) mut => VT.[Friend]Unregister(&this, writerId);
}

[CRepr]struct IVssSnapshotMgmt : IUnknown
{
	public new const Guid IID = .(0xfa7df749, 0x66e7, 0x4986, 0xa2, 0x7f, 0xe2, 0xf0, 0x4a, 0xe5, 0x37, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ProviderId, in Guid InterfaceId, IUnknown** ppItf) GetProviderMgmtInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ProviderId, int32 lContext, IVssEnumMgmtObject** ppEnum) QueryVolumesSupportedForSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, Guid ProviderId, IVssEnumObject** ppEnum) QuerySnapshotsByVolume;
	}


	public HRESULT GetProviderMgmtInterface(Guid ProviderId, in Guid InterfaceId, IUnknown** ppItf) mut => VT.[Friend]GetProviderMgmtInterface(&this, ProviderId, InterfaceId, ppItf);

	public HRESULT QueryVolumesSupportedForSnapshots(Guid ProviderId, int32 lContext, IVssEnumMgmtObject** ppEnum) mut => VT.[Friend]QueryVolumesSupportedForSnapshots(&this, ProviderId, lContext, ppEnum);

	public HRESULT QuerySnapshotsByVolume(uint16* pwszVolumeName, Guid ProviderId, IVssEnumObject** ppEnum) mut => VT.[Friend]QuerySnapshotsByVolume(&this, pwszVolumeName, ProviderId, ppEnum);
}

[CRepr]struct IVssSnapshotMgmt2 : IUnknown
{
	public new const Guid IID = .(0x0f61ec39, 0xfe82, 0x45f2, 0xa3, 0xf0, 0x76, 0x8b, 0x5d, 0x42, 0x71, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pllMinDiffAreaSize) GetMinDiffAreaSize;
	}


	public HRESULT GetMinDiffAreaSize(int64* pllMinDiffAreaSize) mut => VT.[Friend]GetMinDiffAreaSize(&this, pllMinDiffAreaSize);
}

[CRepr]struct IVssDifferentialSoftwareSnapshotMgmt : IUnknown
{
	public new const Guid IID = .(0x214a0f28, 0xb737, 0x4026, 0xb8, 0x47, 0x4f, 0x9e, 0x37, 0xd7, 0x95, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, int64 llMaximumDiffSpace) AddDiffArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, int64 llMaximumDiffSpace) ChangeDiffAreaMaximumSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszOriginalVolumeName, IVssEnumMgmtObject** ppEnum) QueryVolumesSupportedForDiffAreas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, IVssEnumMgmtObject** ppEnum) QueryDiffAreasForVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, IVssEnumMgmtObject** ppEnum) QueryDiffAreasOnVolume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotId, IVssEnumMgmtObject** ppEnum) QueryDiffAreasForSnapshot;
	}


	public HRESULT AddDiffArea(uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, int64 llMaximumDiffSpace) mut => VT.[Friend]AddDiffArea(&this, pwszVolumeName, pwszDiffAreaVolumeName, llMaximumDiffSpace);

	public HRESULT ChangeDiffAreaMaximumSize(uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, int64 llMaximumDiffSpace) mut => VT.[Friend]ChangeDiffAreaMaximumSize(&this, pwszVolumeName, pwszDiffAreaVolumeName, llMaximumDiffSpace);

	public HRESULT QueryVolumesSupportedForDiffAreas(uint16* pwszOriginalVolumeName, IVssEnumMgmtObject** ppEnum) mut => VT.[Friend]QueryVolumesSupportedForDiffAreas(&this, pwszOriginalVolumeName, ppEnum);

	public HRESULT QueryDiffAreasForVolume(uint16* pwszVolumeName, IVssEnumMgmtObject** ppEnum) mut => VT.[Friend]QueryDiffAreasForVolume(&this, pwszVolumeName, ppEnum);

	public HRESULT QueryDiffAreasOnVolume(uint16* pwszVolumeName, IVssEnumMgmtObject** ppEnum) mut => VT.[Friend]QueryDiffAreasOnVolume(&this, pwszVolumeName, ppEnum);

	public HRESULT QueryDiffAreasForSnapshot(Guid SnapshotId, IVssEnumMgmtObject** ppEnum) mut => VT.[Friend]QueryDiffAreasForSnapshot(&this, SnapshotId, ppEnum);
}

[CRepr]struct IVssDifferentialSoftwareSnapshotMgmt2 : IVssDifferentialSoftwareSnapshotMgmt
{
	public new const Guid IID = .(0x949d7353, 0x675f, 0x4275, 0x89, 0x69, 0xf0, 0x44, 0xc6, 0x27, 0x78, 0x15);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVssDifferentialSoftwareSnapshotMgmt.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, int64 llMaximumDiffSpace, BOOL bVolatile) ChangeDiffAreaMaximumSizeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, uint16* pwszNewDiffAreaVolumeName) MigrateDiffAreas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, IVssAsync** ppAsync) QueryMigrationStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid idSnapshot, uint8 priority) SetSnapshotPriority;
	}


	public HRESULT ChangeDiffAreaMaximumSizeEx(uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, int64 llMaximumDiffSpace, BOOL bVolatile) mut => VT.[Friend]ChangeDiffAreaMaximumSizeEx(&this, pwszVolumeName, pwszDiffAreaVolumeName, llMaximumDiffSpace, bVolatile);

	public HRESULT MigrateDiffAreas(uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, uint16* pwszNewDiffAreaVolumeName) mut => VT.[Friend]MigrateDiffAreas(&this, pwszVolumeName, pwszDiffAreaVolumeName, pwszNewDiffAreaVolumeName);

	public HRESULT QueryMigrationStatus(uint16* pwszVolumeName, uint16* pwszDiffAreaVolumeName, IVssAsync** ppAsync) mut => VT.[Friend]QueryMigrationStatus(&this, pwszVolumeName, pwszDiffAreaVolumeName, ppAsync);

	public HRESULT SetSnapshotPriority(Guid idSnapshot, uint8 priority) mut => VT.[Friend]SetSnapshotPriority(&this, idSnapshot, priority);
}

[CRepr]struct IVssDifferentialSoftwareSnapshotMgmt3 : IVssDifferentialSoftwareSnapshotMgmt2
{
	public new const Guid IID = .(0x383f7e71, 0xa4c5, 0x401f, 0xb2, 0x7f, 0xf8, 0x26, 0x28, 0x9f, 0x84, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVssDifferentialSoftwareSnapshotMgmt2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, VSS_PROTECTION_LEVEL protectionLevel) SetVolumeProtectLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, VSS_VOLUME_PROTECTION_INFO* protectionLevel) GetVolumeProtectLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName) ClearVolumeProtectFault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszDiffAreaVolumeName) DeleteUnusedDiffAreas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid idSnapshotOlder, Guid idSnapshotYounger, uint32* pcBlockSizePerBit, uint32* pcBitmapLength, uint8** ppbBitmap) QuerySnapshotDeltaBitmap;
	}


	public HRESULT SetVolumeProtectLevel(uint16* pwszVolumeName, VSS_PROTECTION_LEVEL protectionLevel) mut => VT.[Friend]SetVolumeProtectLevel(&this, pwszVolumeName, protectionLevel);

	public HRESULT GetVolumeProtectLevel(uint16* pwszVolumeName, VSS_VOLUME_PROTECTION_INFO* protectionLevel) mut => VT.[Friend]GetVolumeProtectLevel(&this, pwszVolumeName, protectionLevel);

	public HRESULT ClearVolumeProtectFault(uint16* pwszVolumeName) mut => VT.[Friend]ClearVolumeProtectFault(&this, pwszVolumeName);

	public HRESULT DeleteUnusedDiffAreas(uint16* pwszDiffAreaVolumeName) mut => VT.[Friend]DeleteUnusedDiffAreas(&this, pwszDiffAreaVolumeName);

	public HRESULT QuerySnapshotDeltaBitmap(Guid idSnapshotOlder, Guid idSnapshotYounger, uint32* pcBlockSizePerBit, uint32* pcBitmapLength, uint8** ppbBitmap) mut => VT.[Friend]QuerySnapshotDeltaBitmap(&this, idSnapshotOlder, idSnapshotYounger, pcBlockSizePerBit, pcBitmapLength, ppbBitmap);
}

[CRepr]struct IVssEnumMgmtObject : IUnknown
{
	public new const Guid IID = .(0x01954e6b, 0x9254, 0x4e6e, 0x80, 0x8c, 0xc9, 0xe0, 0x5d, 0x00, 0x76, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, VSS_MGMT_OBJECT_PROP* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IVssEnumMgmtObject** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, VSS_MGMT_OBJECT_PROP* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IVssEnumMgmtObject** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IVssAdmin : IUnknown
{
	public new const Guid IID = .(0x77ed5996, 0x2f63, 0x11d3, 0x8a, 0x39, 0x00, 0xc0, 0x4f, 0x72, 0xd8, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid pProviderId, Guid ClassId, uint16* pwszProviderName, VSS_PROVIDER_TYPE eProviderType, uint16* pwszProviderVersion, Guid ProviderVersionId) RegisterProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ProviderId) UnregisterProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IVssEnumObject** ppEnum) QueryProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AbortAllSnapshotsInProgress;
	}


	public HRESULT RegisterProvider(Guid pProviderId, Guid ClassId, uint16* pwszProviderName, VSS_PROVIDER_TYPE eProviderType, uint16* pwszProviderVersion, Guid ProviderVersionId) mut => VT.[Friend]RegisterProvider(&this, pProviderId, ClassId, pwszProviderName, eProviderType, pwszProviderVersion, ProviderVersionId);

	public HRESULT UnregisterProvider(Guid ProviderId) mut => VT.[Friend]UnregisterProvider(&this, ProviderId);

	public HRESULT QueryProviders(IVssEnumObject** ppEnum) mut => VT.[Friend]QueryProviders(&this, ppEnum);

	public HRESULT AbortAllSnapshotsInProgress() mut => VT.[Friend]AbortAllSnapshotsInProgress(&this);
}

[CRepr]struct IVssAdminEx : IVssAdmin
{
	public new const Guid IID = .(0x7858a9f8, 0xb1fa, 0x41a6, 0x96, 0x4f, 0xb9, 0xb3, 0x6b, 0x8c, 0xd8, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVssAdmin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid pProviderId, uint64* pllOriginalCapabilityMask) GetProviderCapability;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ProviderId, int32* plContext) GetProviderContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ProviderId, int32 lContext) SetProviderContext;
	}


	public HRESULT GetProviderCapability(Guid pProviderId, uint64* pllOriginalCapabilityMask) mut => VT.[Friend]GetProviderCapability(&this, pProviderId, pllOriginalCapabilityMask);

	public HRESULT GetProviderContext(Guid ProviderId, int32* plContext) mut => VT.[Friend]GetProviderContext(&this, ProviderId, plContext);

	public HRESULT SetProviderContext(Guid ProviderId, int32 lContext) mut => VT.[Friend]SetProviderContext(&this, ProviderId, lContext);
}

[CRepr]struct IVssSoftwareSnapshotProvider : IUnknown
{
	public new const Guid IID = .(0x609e123e, 0x2c5a, 0x44d3, 0x8f, 0x01, 0x0b, 0x1d, 0x9a, 0x47, 0xd1, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lContext) SetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotId, VSS_SNAPSHOT_PROP* pProp) GetSnapshotProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid QueriedObjectId, VSS_OBJECT_TYPE eQueriedObjectType, VSS_OBJECT_TYPE eReturnedObjectsType, IVssEnumObject** ppEnum) Query;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SourceObjectId, VSS_OBJECT_TYPE eSourceObjectType, BOOL bForceDelete, int32* plDeletedSnapshots, Guid* pNondeletedSnapshotID) DeleteSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId, Guid SnapshotId, uint16* pwszVolumeName, int32 lNewContext) BeginPrepareSnapshot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, BOOL* pbSupportedByThisProvider) IsVolumeSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolumeName, BOOL* pbSnapshotsPresent, int32* plSnapshotCompatibility) IsVolumeSnapshotted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotId, VSS_SNAPSHOT_PROPERTY_ID eSnapshotPropertyId, VARIANT vProperty) SetSnapshotProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotId) RevertToSnapshot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszVolume, IVssAsync** ppAsync) QueryRevertStatus;
	}


	public HRESULT SetContext(int32 lContext) mut => VT.[Friend]SetContext(&this, lContext);

	public HRESULT GetSnapshotProperties(Guid SnapshotId, VSS_SNAPSHOT_PROP* pProp) mut => VT.[Friend]GetSnapshotProperties(&this, SnapshotId, pProp);

	public HRESULT Query(Guid QueriedObjectId, VSS_OBJECT_TYPE eQueriedObjectType, VSS_OBJECT_TYPE eReturnedObjectsType, IVssEnumObject** ppEnum) mut => VT.[Friend]Query(&this, QueriedObjectId, eQueriedObjectType, eReturnedObjectsType, ppEnum);

	public HRESULT DeleteSnapshots(Guid SourceObjectId, VSS_OBJECT_TYPE eSourceObjectType, BOOL bForceDelete, int32* plDeletedSnapshots, Guid* pNondeletedSnapshotID) mut => VT.[Friend]DeleteSnapshots(&this, SourceObjectId, eSourceObjectType, bForceDelete, plDeletedSnapshots, pNondeletedSnapshotID);

	public HRESULT BeginPrepareSnapshot(Guid SnapshotSetId, Guid SnapshotId, uint16* pwszVolumeName, int32 lNewContext) mut => VT.[Friend]BeginPrepareSnapshot(&this, SnapshotSetId, SnapshotId, pwszVolumeName, lNewContext);

	public HRESULT IsVolumeSupported(uint16* pwszVolumeName, BOOL* pbSupportedByThisProvider) mut => VT.[Friend]IsVolumeSupported(&this, pwszVolumeName, pbSupportedByThisProvider);

	public HRESULT IsVolumeSnapshotted(uint16* pwszVolumeName, BOOL* pbSnapshotsPresent, int32* plSnapshotCompatibility) mut => VT.[Friend]IsVolumeSnapshotted(&this, pwszVolumeName, pbSnapshotsPresent, plSnapshotCompatibility);

	public HRESULT SetSnapshotProperty(Guid SnapshotId, VSS_SNAPSHOT_PROPERTY_ID eSnapshotPropertyId, VARIANT vProperty) mut => VT.[Friend]SetSnapshotProperty(&this, SnapshotId, eSnapshotPropertyId, vProperty);

	public HRESULT RevertToSnapshot(Guid SnapshotId) mut => VT.[Friend]RevertToSnapshot(&this, SnapshotId);

	public HRESULT QueryRevertStatus(uint16* pwszVolume, IVssAsync** ppAsync) mut => VT.[Friend]QueryRevertStatus(&this, pwszVolume, ppAsync);
}

[CRepr]struct IVssProviderCreateSnapshotSet : IUnknown
{
	public new const Guid IID = .(0x5f894e5b, 0x1e39, 0x4778, 0x8e, 0x23, 0x9a, 0xba, 0xd9, 0xf0, 0xe0, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId) EndPrepareSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId) PreCommitSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId) CommitSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId, int32 lSnapshotsCount) PostCommitSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId) PreFinalCommitSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId) PostFinalCommitSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId) AbortSnapshots;
	}


	public HRESULT EndPrepareSnapshots(Guid SnapshotSetId) mut => VT.[Friend]EndPrepareSnapshots(&this, SnapshotSetId);

	public HRESULT PreCommitSnapshots(Guid SnapshotSetId) mut => VT.[Friend]PreCommitSnapshots(&this, SnapshotSetId);

	public HRESULT CommitSnapshots(Guid SnapshotSetId) mut => VT.[Friend]CommitSnapshots(&this, SnapshotSetId);

	public HRESULT PostCommitSnapshots(Guid SnapshotSetId, int32 lSnapshotsCount) mut => VT.[Friend]PostCommitSnapshots(&this, SnapshotSetId, lSnapshotsCount);

	public HRESULT PreFinalCommitSnapshots(Guid SnapshotSetId) mut => VT.[Friend]PreFinalCommitSnapshots(&this, SnapshotSetId);

	public HRESULT PostFinalCommitSnapshots(Guid SnapshotSetId) mut => VT.[Friend]PostFinalCommitSnapshots(&this, SnapshotSetId);

	public HRESULT AbortSnapshots(Guid SnapshotSetId) mut => VT.[Friend]AbortSnapshots(&this, SnapshotSetId);
}

[CRepr]struct IVssProviderNotifications : IUnknown
{
	public new const Guid IID = .(0xe561901f, 0x03a5, 0x4afe, 0x86, 0xd0, 0x72, 0xba, 0xee, 0xce, 0x70, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pCallback) OnLoad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bForceUnload) OnUnload;
	}


	public HRESULT OnLoad(IUnknown* pCallback) mut => VT.[Friend]OnLoad(&this, pCallback);

	public HRESULT OnUnload(BOOL bForceUnload) mut => VT.[Friend]OnUnload(&this, bForceUnload);
}

[CRepr]struct IVssHardwareSnapshotProvider : IUnknown
{
	public new const Guid IID = .(0x9593a157, 0x44e9, 0x4344, 0xbb, 0xeb, 0x44, 0xfb, 0xf9, 0xb0, 0x6b, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLunCount, int32 lContext, uint16** rgwszDevices, VDS_LUN_INFORMATION* pLunInformation, BOOL* pbIsSupported) AreLunsSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* wszDeviceName, VDS_LUN_INFORMATION* pLunInfo, BOOL* pbIsSupported) FillInLunInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId, Guid SnapshotId, int32 lContext, int32 lLunCount, uint16** rgDeviceNames, VDS_LUN_INFORMATION* rgLunInformation) BeginPrepareSnapshot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLunCount, uint16** rgDeviceNames, VDS_LUN_INFORMATION* rgSourceLuns, VDS_LUN_INFORMATION* rgDestinationLuns) GetTargetLuns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLunCount, VDS_LUN_INFORMATION* rgSourceLuns) LocateLuns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* wszDeviceName, VDS_LUN_INFORMATION* pInformation) OnLunEmpty;
	}


	public HRESULT AreLunsSupported(int32 lLunCount, int32 lContext, uint16** rgwszDevices, VDS_LUN_INFORMATION* pLunInformation, BOOL* pbIsSupported) mut => VT.[Friend]AreLunsSupported(&this, lLunCount, lContext, rgwszDevices, pLunInformation, pbIsSupported);

	public HRESULT FillInLunInfo(uint16* wszDeviceName, VDS_LUN_INFORMATION* pLunInfo, BOOL* pbIsSupported) mut => VT.[Friend]FillInLunInfo(&this, wszDeviceName, pLunInfo, pbIsSupported);

	public HRESULT BeginPrepareSnapshot(Guid SnapshotSetId, Guid SnapshotId, int32 lContext, int32 lLunCount, uint16** rgDeviceNames, VDS_LUN_INFORMATION* rgLunInformation) mut => VT.[Friend]BeginPrepareSnapshot(&this, SnapshotSetId, SnapshotId, lContext, lLunCount, rgDeviceNames, rgLunInformation);

	public HRESULT GetTargetLuns(int32 lLunCount, uint16** rgDeviceNames, VDS_LUN_INFORMATION* rgSourceLuns, VDS_LUN_INFORMATION* rgDestinationLuns) mut => VT.[Friend]GetTargetLuns(&this, lLunCount, rgDeviceNames, rgSourceLuns, rgDestinationLuns);

	public HRESULT LocateLuns(int32 lLunCount, VDS_LUN_INFORMATION* rgSourceLuns) mut => VT.[Friend]LocateLuns(&this, lLunCount, rgSourceLuns);

	public HRESULT OnLunEmpty(uint16* wszDeviceName, VDS_LUN_INFORMATION* pInformation) mut => VT.[Friend]OnLunEmpty(&this, wszDeviceName, pInformation);
}

[CRepr]struct IVssHardwareSnapshotProviderEx : IVssHardwareSnapshotProvider
{
	public new const Guid IID = .(0x7f5ba925, 0xcdb1, 0x4d11, 0xa7, 0x1f, 0x33, 0x9e, 0xb7, 0xe7, 0x09, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVssHardwareSnapshotProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pllOriginalCapabilityMask) GetProviderCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VDS_LUN_INFORMATION* pSnapshotLuns, VDS_LUN_INFORMATION* pOriginalLuns, uint32 dwCount, uint32 dwFlags) OnLunStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VDS_LUN_INFORMATION* pSourceLuns, VDS_LUN_INFORMATION* pTargetLuns, uint32 dwCount, IVssAsync** ppAsync) ResyncLuns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VDS_LUN_INFORMATION* pSnapshotLuns, VDS_LUN_INFORMATION* pOriginalLuns, uint32 dwCount) OnReuseLuns;
	}


	public HRESULT GetProviderCapabilities(uint64* pllOriginalCapabilityMask) mut => VT.[Friend]GetProviderCapabilities(&this, pllOriginalCapabilityMask);

	public HRESULT OnLunStateChange(VDS_LUN_INFORMATION* pSnapshotLuns, VDS_LUN_INFORMATION* pOriginalLuns, uint32 dwCount, uint32 dwFlags) mut => VT.[Friend]OnLunStateChange(&this, pSnapshotLuns, pOriginalLuns, dwCount, dwFlags);

	public HRESULT ResyncLuns(VDS_LUN_INFORMATION* pSourceLuns, VDS_LUN_INFORMATION* pTargetLuns, uint32 dwCount, IVssAsync** ppAsync) mut => VT.[Friend]ResyncLuns(&this, pSourceLuns, pTargetLuns, dwCount, ppAsync);

	public HRESULT OnReuseLuns(VDS_LUN_INFORMATION* pSnapshotLuns, VDS_LUN_INFORMATION* pOriginalLuns, uint32 dwCount) mut => VT.[Friend]OnReuseLuns(&this, pSnapshotLuns, pOriginalLuns, dwCount);
}

[CRepr]struct IVssFileShareSnapshotProvider : IUnknown
{
	public new const Guid IID = .(0xc8636060, 0x7c2e, 0x11df, 0x8c, 0x4a, 0x08, 0x00, 0x20, 0x0c, 0x9a, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lContext) SetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotId, VSS_SNAPSHOT_PROP* pProp) GetSnapshotProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid QueriedObjectId, VSS_OBJECT_TYPE eQueriedObjectType, VSS_OBJECT_TYPE eReturnedObjectsType, IVssEnumObject** ppEnum) Query;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SourceObjectId, VSS_OBJECT_TYPE eSourceObjectType, BOOL bForceDelete, int32* plDeletedSnapshots, Guid* pNondeletedSnapshotID) DeleteSnapshots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotSetId, Guid SnapshotId, uint16* pwszSharePath, int32 lNewContext, Guid ProviderId) BeginPrepareSnapshot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszSharePath, BOOL* pbSupportedByThisProvider) IsPathSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwszSharePath, BOOL* pbSnapshotsPresent, int32* plSnapshotCompatibility) IsPathSnapshotted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid SnapshotId, VSS_SNAPSHOT_PROPERTY_ID eSnapshotPropertyId, VARIANT vProperty) SetSnapshotProperty;
	}


	public HRESULT SetContext(int32 lContext) mut => VT.[Friend]SetContext(&this, lContext);

	public HRESULT GetSnapshotProperties(Guid SnapshotId, VSS_SNAPSHOT_PROP* pProp) mut => VT.[Friend]GetSnapshotProperties(&this, SnapshotId, pProp);

	public HRESULT Query(Guid QueriedObjectId, VSS_OBJECT_TYPE eQueriedObjectType, VSS_OBJECT_TYPE eReturnedObjectsType, IVssEnumObject** ppEnum) mut => VT.[Friend]Query(&this, QueriedObjectId, eQueriedObjectType, eReturnedObjectsType, ppEnum);

	public HRESULT DeleteSnapshots(Guid SourceObjectId, VSS_OBJECT_TYPE eSourceObjectType, BOOL bForceDelete, int32* plDeletedSnapshots, Guid* pNondeletedSnapshotID) mut => VT.[Friend]DeleteSnapshots(&this, SourceObjectId, eSourceObjectType, bForceDelete, plDeletedSnapshots, pNondeletedSnapshotID);

	public HRESULT BeginPrepareSnapshot(Guid SnapshotSetId, Guid SnapshotId, uint16* pwszSharePath, int32 lNewContext, Guid ProviderId) mut => VT.[Friend]BeginPrepareSnapshot(&this, SnapshotSetId, SnapshotId, pwszSharePath, lNewContext, ProviderId);

	public HRESULT IsPathSupported(uint16* pwszSharePath, BOOL* pbSupportedByThisProvider) mut => VT.[Friend]IsPathSupported(&this, pwszSharePath, pbSupportedByThisProvider);

	public HRESULT IsPathSnapshotted(uint16* pwszSharePath, BOOL* pbSnapshotsPresent, int32* plSnapshotCompatibility) mut => VT.[Friend]IsPathSnapshotted(&this, pwszSharePath, pbSnapshotsPresent, plSnapshotCompatibility);

	public HRESULT SetSnapshotProperty(Guid SnapshotId, VSS_SNAPSHOT_PROPERTY_ID eSnapshotPropertyId, VARIANT vProperty) mut => VT.[Friend]SetSnapshotProperty(&this, SnapshotId, eSnapshotPropertyId, vProperty);
}

#endregion

#region Functions
public static
{
	[Import("VSSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateVssExpressWriterInternal(IVssExpressWriter** ppWriter);

}
#endregion
