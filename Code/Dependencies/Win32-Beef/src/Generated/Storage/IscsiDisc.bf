using Win32.Foundation;
using Win32.System.Ioctl;
using System;

namespace Win32.Storage.IscsiDisc;

#region Constants
public static
{
	public const uint32 IOCTL_SCSI_BASE = 4;
	public const Guid ScsiRawInterfaceGuid = .(0x53f56309, 0xb6bf, 0x11d0, 0x94, 0xf2, 0x00, 0xa0, 0xc9, 0x1e, 0xfb, 0x8b);
	public const Guid WmiScsiAddressGuid = .(0x53f5630f, 0xb6bf, 0x11d0, 0x94, 0xf2, 0x00, 0xa0, 0xc9, 0x1e, 0xfb, 0x8b);
	public const uint32 FILE_DEVICE_SCSI = 27;
	public const String DD_SCSI_DEVICE_NAME = "\\Device\\ScsiPort";
	public const uint32 IOCTL_SCSI_PASS_THROUGH = 315396;
	public const uint32 IOCTL_SCSI_MINIPORT = 315400;
	public const uint32 IOCTL_SCSI_GET_INQUIRY_DATA = 266252;
	public const uint32 IOCTL_SCSI_GET_CAPABILITIES = 266256;
	public const uint32 IOCTL_SCSI_PASS_THROUGH_DIRECT = 315412;
	public const uint32 IOCTL_SCSI_GET_ADDRESS = 266264;
	public const uint32 IOCTL_SCSI_RESCAN_BUS = 266268;
	public const uint32 IOCTL_SCSI_GET_DUMP_POINTERS = 266272;
	public const uint32 IOCTL_SCSI_FREE_DUMP_POINTERS = 266276;
	public const uint32 IOCTL_IDE_PASS_THROUGH = 315432;
	public const uint32 IOCTL_ATA_PASS_THROUGH = 315436;
	public const uint32 IOCTL_ATA_PASS_THROUGH_DIRECT = 315440;
	public const uint32 IOCTL_ATA_MINIPORT = 315444;
	public const uint32 IOCTL_MINIPORT_PROCESS_SERVICE_IRP = 315448;
	public const uint32 IOCTL_MPIO_PASS_THROUGH_PATH = 315452;
	public const uint32 IOCTL_MPIO_PASS_THROUGH_PATH_DIRECT = 315456;
	public const uint32 IOCTL_SCSI_PASS_THROUGH_EX = 315460;
	public const uint32 IOCTL_SCSI_PASS_THROUGH_DIRECT_EX = 315464;
	public const uint32 IOCTL_MPIO_PASS_THROUGH_PATH_EX = 315468;
	public const uint32 IOCTL_MPIO_PASS_THROUGH_PATH_DIRECT_EX = 315472;
	public const uint32 ATA_FLAGS_DRDY_REQUIRED = 1;
	public const uint32 ATA_FLAGS_DATA_IN = 2;
	public const uint32 ATA_FLAGS_DATA_OUT = 4;
	public const uint32 ATA_FLAGS_48BIT_COMMAND = 8;
	public const uint32 ATA_FLAGS_USE_DMA = 16;
	public const uint32 ATA_FLAGS_NO_MULTIPLE = 32;
	public const String IOCTL_MINIPORT_SIGNATURE_SCSIDISK = "SCSIDISK";
	public const String IOCTL_MINIPORT_SIGNATURE_HYBRDISK = "HYBRDISK";
	public const String IOCTL_MINIPORT_SIGNATURE_DSM_NOTIFICATION = "MPDSM   ";
	public const String IOCTL_MINIPORT_SIGNATURE_DSM_GENERAL = "MPDSMGEN";
	public const String IOCTL_MINIPORT_SIGNATURE_FIRMWARE = "FIRMWARE";
	public const String IOCTL_MINIPORT_SIGNATURE_QUERY_PROTOCOL = "PROTOCOL";
	public const String IOCTL_MINIPORT_SIGNATURE_SET_PROTOCOL = "SETPROTO";
	public const String IOCTL_MINIPORT_SIGNATURE_QUERY_TEMPERATURE = "TEMPERAT";
	public const String IOCTL_MINIPORT_SIGNATURE_SET_TEMPERATURE_THRESHOLD = "SETTEMPT";
	public const String IOCTL_MINIPORT_SIGNATURE_QUERY_PHYSICAL_TOPOLOGY = "TOPOLOGY";
	public const String IOCTL_MINIPORT_SIGNATURE_ENDURANCE_INFO = "ENDURINF";
	public const uint32 NRB_FUNCTION_NVCACHE_INFO = 236;
	public const uint32 NRB_FUNCTION_SPINDLE_STATUS = 229;
	public const uint32 NRB_FUNCTION_NVCACHE_POWER_MODE_SET = 0;
	public const uint32 NRB_FUNCTION_NVCACHE_POWER_MODE_RETURN = 1;
	public const uint32 NRB_FUNCTION_FLUSH_NVCACHE = 20;
	public const uint32 NRB_FUNCTION_QUERY_PINNED_SET = 18;
	public const uint32 NRB_FUNCTION_QUERY_CACHE_MISS = 19;
	public const uint32 NRB_FUNCTION_ADD_LBAS_PINNED_SET = 16;
	public const uint32 NRB_FUNCTION_REMOVE_LBAS_PINNED_SET = 17;
	public const uint32 NRB_FUNCTION_QUERY_ASCENDER_STATUS = 208;
	public const uint32 NRB_FUNCTION_QUERY_HYBRID_DISK_STATUS = 209;
	public const uint32 NRB_FUNCTION_PASS_HINT_PAYLOAD = 224;
	public const uint32 NRB_FUNCTION_NVSEPARATED_INFO = 192;
	public const uint32 NRB_FUNCTION_NVSEPARATED_FLUSH = 193;
	public const uint32 NRB_FUNCTION_NVSEPARATED_WB_DISABLE = 194;
	public const uint32 NRB_FUNCTION_NVSEPARATED_WB_REVERT_DEFAULT = 195;
	public const uint32 NRB_SUCCESS = 0;
	public const uint32 NRB_ILLEGAL_REQUEST = 1;
	public const uint32 NRB_INVALID_PARAMETER = 2;
	public const uint32 NRB_INPUT_DATA_OVERRUN = 3;
	public const uint32 NRB_INPUT_DATA_UNDERRUN = 4;
	public const uint32 NRB_OUTPUT_DATA_OVERRUN = 5;
	public const uint32 NRB_OUTPUT_DATA_UNDERRUN = 6;
	public const uint32 NV_SEP_CACHE_PARAMETER_VERSION_1 = 1;
	public const uint32 NV_SEP_CACHE_PARAMETER_VERSION = 1;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_SUCCESS = 0;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_BUFFER_TOO_SMALL = 1;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_UNSUPPORTED_VERSION = 2;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_INVALID_PARAMETER = 3;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_INVALID_SIGNATURE = 4;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_INVALID_TARGET_TYPE = 5;
	public const uint32 STORAGE_DIAGNOSTIC_STATUS_MORE_DATA = 6;
	public const uint32 MINIPORT_DSM_NOTIFICATION_VERSION_1 = 1;
	public const uint32 MINIPORT_DSM_NOTIFICATION_VERSION = 1;
	public const uint32 MINIPORT_DSM_PROFILE_UNKNOWN = 0;
	public const uint32 MINIPORT_DSM_PROFILE_PAGE_FILE = 1;
	public const uint32 MINIPORT_DSM_PROFILE_HIBERNATION_FILE = 2;
	public const uint32 MINIPORT_DSM_PROFILE_CRASHDUMP_FILE = 3;
	public const uint32 MINIPORT_DSM_NOTIFY_FLAG_BEGIN = 1;
	public const uint32 MINIPORT_DSM_NOTIFY_FLAG_END = 2;
	public const uint32 HYBRID_FUNCTION_GET_INFO = 1;
	public const uint32 HYBRID_FUNCTION_DISABLE_CACHING_MEDIUM = 16;
	public const uint32 HYBRID_FUNCTION_ENABLE_CACHING_MEDIUM = 17;
	public const uint32 HYBRID_FUNCTION_SET_DIRTY_THRESHOLD = 18;
	public const uint32 HYBRID_FUNCTION_DEMOTE_BY_SIZE = 19;
	public const uint32 HYBRID_STATUS_SUCCESS = 0;
	public const uint32 HYBRID_STATUS_ILLEGAL_REQUEST = 1;
	public const uint32 HYBRID_STATUS_INVALID_PARAMETER = 2;
	public const uint32 HYBRID_STATUS_OUTPUT_BUFFER_TOO_SMALL = 3;
	public const uint32 HYBRID_STATUS_ENABLE_REFCOUNT_HOLD = 16;
	public const uint32 HYBRID_REQUEST_BLOCK_STRUCTURE_VERSION = 1;
	public const uint32 HYBRID_REQUEST_INFO_STRUCTURE_VERSION = 1;
	public const uint32 FIRMWARE_FUNCTION_GET_INFO = 1;
	public const uint32 FIRMWARE_FUNCTION_DOWNLOAD = 2;
	public const uint32 FIRMWARE_FUNCTION_ACTIVATE = 3;
	public const uint32 FIRMWARE_STATUS_SUCCESS = 0;
	public const uint32 FIRMWARE_STATUS_ERROR = 1;
	public const uint32 FIRMWARE_STATUS_ILLEGAL_REQUEST = 2;
	public const uint32 FIRMWARE_STATUS_INVALID_PARAMETER = 3;
	public const uint32 FIRMWARE_STATUS_INPUT_BUFFER_TOO_BIG = 4;
	public const uint32 FIRMWARE_STATUS_OUTPUT_BUFFER_TOO_SMALL = 5;
	public const uint32 FIRMWARE_STATUS_INVALID_SLOT = 6;
	public const uint32 FIRMWARE_STATUS_INVALID_IMAGE = 7;
	public const uint32 FIRMWARE_STATUS_CONTROLLER_ERROR = 16;
	public const uint32 FIRMWARE_STATUS_POWER_CYCLE_REQUIRED = 32;
	public const uint32 FIRMWARE_STATUS_DEVICE_ERROR = 64;
	public const uint32 FIRMWARE_STATUS_INTERFACE_CRC_ERROR = 128;
	public const uint32 FIRMWARE_STATUS_UNCORRECTABLE_DATA_ERROR = 129;
	public const uint32 FIRMWARE_STATUS_MEDIA_CHANGE = 130;
	public const uint32 FIRMWARE_STATUS_ID_NOT_FOUND = 131;
	public const uint32 FIRMWARE_STATUS_MEDIA_CHANGE_REQUEST = 132;
	public const uint32 FIRMWARE_STATUS_COMMAND_ABORT = 133;
	public const uint32 FIRMWARE_STATUS_END_OF_MEDIA = 134;
	public const uint32 FIRMWARE_STATUS_ILLEGAL_LENGTH = 135;
	public const uint32 FIRMWARE_REQUEST_BLOCK_STRUCTURE_VERSION = 1;
	public const uint32 FIRMWARE_REQUEST_FLAG_CONTROLLER = 1;
	public const uint32 FIRMWARE_REQUEST_FLAG_LAST_SEGMENT = 2;
	public const uint32 FIRMWARE_REQUEST_FLAG_FIRST_SEGMENT = 4;
	public const uint32 FIRMWARE_REQUEST_FLAG_SWITCH_TO_EXISTING_FIRMWARE = 2147483648;
	public const uint32 STORAGE_FIRMWARE_INFO_STRUCTURE_VERSION = 1;
	public const uint32 STORAGE_FIRMWARE_INFO_STRUCTURE_VERSION_V2 = 2;
	public const uint32 STORAGE_FIRMWARE_INFO_INVALID_SLOT = 255;
	public const uint32 STORAGE_FIRMWARE_SLOT_INFO_V2_REVISION_LENGTH = 16;
	public const uint32 STORAGE_FIRMWARE_DOWNLOAD_STRUCTURE_VERSION = 1;
	public const uint32 STORAGE_FIRMWARE_DOWNLOAD_STRUCTURE_VERSION_V2 = 2;
	public const uint32 STORAGE_FIRMWARE_ACTIVATE_STRUCTURE_VERSION = 1;
	public const uint32 DUMP_POINTERS_VERSION_1 = 1;
	public const uint32 DUMP_POINTERS_VERSION_2 = 2;
	public const uint32 DUMP_POINTERS_VERSION_3 = 3;
	public const uint32 DUMP_POINTERS_VERSION_4 = 4;
	public const uint32 DUMP_DRIVER_NAME_LENGTH = 15;
	public const uint32 DUMP_EX_FLAG_SUPPORT_64BITMEMORY = 1;
	public const uint32 DUMP_EX_FLAG_SUPPORT_DD_TELEMETRY = 2;
	public const uint32 DUMP_EX_FLAG_RESUME_SUPPORT = 4;
	public const uint32 DUMP_EX_FLAG_DRIVER_FULL_PATH_SUPPORT = 8;
	public const uint32 SCSI_IOCTL_DATA_OUT = 0;
	public const uint32 SCSI_IOCTL_DATA_IN = 1;
	public const uint32 SCSI_IOCTL_DATA_UNSPECIFIED = 2;
	public const uint32 SCSI_IOCTL_DATA_BIDIRECTIONAL = 3;
	public const uint32 MPIO_IOCTL_FLAG_USE_PATHID = 1;
	public const uint32 MPIO_IOCTL_FLAG_USE_SCSIADDRESS = 2;
	public const uint32 MPIO_IOCTL_FLAG_INVOLVE_DSM = 4;
	public const uint32 MAX_ISCSI_HBANAME_LEN = 256;
	public const uint32 MAX_ISCSI_NAME_LEN = 223;
	public const uint32 MAX_ISCSI_ALIAS_LEN = 255;
	public const uint32 MAX_ISCSI_PORTAL_NAME_LEN = 256;
	public const uint32 MAX_ISCSI_PORTAL_ALIAS_LEN = 256;
	public const uint32 MAX_ISCSI_TEXT_ADDRESS_LEN = 256;
	public const uint32 MAX_ISCSI_PORTAL_ADDRESS_LEN = 256;
	public const uint32 MAX_ISCSI_DISCOVERY_DOMAIN_LEN = 256;
	public const uint32 MAX_RADIUS_ADDRESS_LEN = 41;
	public const String ISCSI_SECURITY_FLAG_TUNNEL_MODE_PREFERRED = "0x00000040";
	public const String ISCSI_SECURITY_FLAG_TRANSPORT_MODE_PREFERRED = "0x00000020";
	public const String ISCSI_SECURITY_FLAG_PFS_ENABLED = "0x00000010";
	public const String ISCSI_SECURITY_FLAG_AGGRESSIVE_MODE_ENABLED = "0x00000008";
	public const String ISCSI_SECURITY_FLAG_MAIN_MODE_ENABLED = "0x00000004";
	public const String ISCSI_SECURITY_FLAG_IKE_IPSEC_ENABLED = "0x00000002";
	public const String ISCSI_SECURITY_FLAG_VALID = "0x00000001";
	public const String ISCSI_LOGIN_OPTIONS_HEADER_DIGEST = "0x00000001";
	public const String ISCSI_LOGIN_OPTIONS_DATA_DIGEST = "0x00000002";
	public const String ISCSI_LOGIN_OPTIONS_MAXIMUM_CONNECTIONS = "0x00000004";
	public const String ISCSI_LOGIN_OPTIONS_DEFAULT_TIME_2_WAIT = "0x00000008";
	public const String ISCSI_LOGIN_OPTIONS_DEFAULT_TIME_2_RETAIN = "0x00000010";
	public const String ISCSI_LOGIN_OPTIONS_USERNAME = "0x00000020";
	public const String ISCSI_LOGIN_OPTIONS_PASSWORD = "0x00000040";
	public const String ISCSI_LOGIN_OPTIONS_AUTH_TYPE = "0x00000080";
	public const String ID_IPV4_ADDR = "1";
	public const String ID_FQDN = "2";
	public const String ID_USER_FQDN = "3";
	public const String ID_IPV6_ADDR = "5";
	public const uint32 ISCSI_LOGIN_FLAG_REQUIRE_IPSEC = 1;
	public const uint32 ISCSI_LOGIN_FLAG_MULTIPATH_ENABLED = 2;
	public const uint32 ISCSI_LOGIN_FLAG_RESERVED1 = 4;
	public const uint32 ISCSI_LOGIN_FLAG_ALLOW_PORTAL_HOPPING = 8;
	public const uint32 ISCSI_LOGIN_FLAG_USE_RADIUS_RESPONSE = 16;
	public const uint32 ISCSI_LOGIN_FLAG_USE_RADIUS_VERIFICATION = 32;
	public const uint32 ISCSI_LOGIN_OPTIONS_VERSION = 0;
	public const uint32 ISCSI_TARGET_FLAG_HIDE_STATIC_TARGET = 2;
	public const uint32 ISCSI_TARGET_FLAG_MERGE_TARGET_INFORMATION = 4;
}
#endregion

#region Enums

[AllowDuplicates]
public enum NV_SEP_WRITE_CACHE_TYPE : int32
{
	NVSEPWriteCacheTypeUnknown = 0,
	NVSEPWriteCacheTypeNone = 1,
	NVSEPWriteCacheTypeWriteBack = 2,
	NVSEPWriteCacheTypeWriteThrough = 3,
}


[AllowDuplicates]
public enum MP_STORAGE_DIAGNOSTIC_LEVEL : int32
{
	MpStorageDiagnosticLevelDefault = 0,
	MpStorageDiagnosticLevelMax = 1,
}


[AllowDuplicates]
public enum MP_STORAGE_DIAGNOSTIC_TARGET_TYPE : int32
{
	MpStorageDiagnosticTargetTypeUndefined = 0,
	MpStorageDiagnosticTargetTypeMiniport = 2,
	MpStorageDiagnosticTargetTypeHbaFirmware = 3,
	MpStorageDiagnosticTargetTypeMax = 4,
}


[AllowDuplicates]
public enum NVCACHE_TYPE : int32
{
	NvCacheTypeUnknown = 0,
	NvCacheTypeNone = 1,
	NvCacheTypeWriteBack = 2,
	NvCacheTypeWriteThrough = 3,
}


[AllowDuplicates]
public enum NVCACHE_STATUS : int32
{
	NvCacheStatusUnknown = 0,
	NvCacheStatusDisabling = 1,
	NvCacheStatusDisabled = 2,
	NvCacheStatusEnabled = 3,
}


[AllowDuplicates]
public enum ISCSI_DIGEST_TYPES : int32
{
	ISCSI_DIGEST_TYPE_NONE = 0,
	ISCSI_DIGEST_TYPE_CRC32C = 1,
}


[AllowDuplicates]
public enum ISCSI_AUTH_TYPES : int32
{
	ISCSI_NO_AUTH_TYPE = 0,
	ISCSI_CHAP_AUTH_TYPE = 1,
	ISCSI_MUTUAL_CHAP_AUTH_TYPE = 2,
}


[AllowDuplicates]
public enum IKE_AUTHENTICATION_METHOD : int32
{
	IKE_AUTHENTICATION_PRESHARED_KEY_METHOD = 1,
}


[AllowDuplicates]
public enum TARGETPROTOCOLTYPE : int32
{
	ISCSI_TCP_PROTOCOL_TYPE = 0,
}


[AllowDuplicates]
public enum TARGET_INFORMATION_CLASS : int32
{
	ProtocolType = 0,
	TargetAlias = 1,
	DiscoveryMechanisms = 2,
	PortalGroups = 3,
	PersistentTargetMappings = 4,
	InitiatorName = 5,
	TargetFlags = 6,
	LoginOptions = 7,
}

#endregion

#region Function Pointers
public function int32 PDUMP_DEVICE_POWERON_ROUTINE(void* Context);

#endregion

#region Structs
[CRepr]
public struct _ADAPTER_OBJECT
{
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SCSI_PASS_THROUGH32
{
	public uint16 Length;
	public uint8 ScsiStatus;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 CdbLength;
	public uint8 SenseInfoLength;
	public uint8 DataIn;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public uint32 DataBufferOffset;
	public uint32 SenseInfoOffset;
	public uint8[16] Cdb;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SCSI_PASS_THROUGH_DIRECT32
{
	public uint16 Length;
	public uint8 ScsiStatus;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 CdbLength;
	public uint8 SenseInfoLength;
	public uint8 DataIn;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public void* DataBuffer;
	public uint32 SenseInfoOffset;
	public uint8[16] Cdb;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SCSI_PASS_THROUGH32_EX
{
	public uint32 Version;
	public uint32 Length;
	public uint32 CdbLength;
	public uint32 StorAddressLength;
	public uint8 ScsiStatus;
	public uint8 SenseInfoLength;
	public uint8 DataDirection;
	public uint8 Reserved;
	public uint32 TimeOutValue;
	public uint32 StorAddressOffset;
	public uint32 SenseInfoOffset;
	public uint32 DataOutTransferLength;
	public uint32 DataInTransferLength;
	public uint32 DataOutBufferOffset;
	public uint32 DataInBufferOffset;
	public uint8* Cdb mut => &Cdb_impl;
	private uint8[ANYSIZE_ARRAY] Cdb_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SCSI_PASS_THROUGH_DIRECT32_EX
{
	public uint32 Version;
	public uint32 Length;
	public uint32 CdbLength;
	public uint32 StorAddressLength;
	public uint8 ScsiStatus;
	public uint8 SenseInfoLength;
	public uint8 DataDirection;
	public uint8 Reserved;
	public uint32 TimeOutValue;
	public uint32 StorAddressOffset;
	public uint32 SenseInfoOffset;
	public uint32 DataOutTransferLength;
	public uint32 DataInTransferLength;
	public void* DataOutBuffer;
	public void* DataInBuffer;
	public uint8* Cdb mut => &Cdb_impl;
	private uint8[ANYSIZE_ARRAY] Cdb_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct ATA_PASS_THROUGH_EX32
{
	public uint16 Length;
	public uint16 AtaFlags;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 ReservedAsUchar;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public uint32 ReservedAsUlong;
	public uint32 DataBufferOffset;
	public uint8[8] PreviousTaskFile;
	public uint8[8] CurrentTaskFile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct ATA_PASS_THROUGH_DIRECT32
{
	public uint16 Length;
	public uint16 AtaFlags;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 ReservedAsUchar;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public uint32 ReservedAsUlong;
	public void* DataBuffer;
	public uint8[8] PreviousTaskFile;
	public uint8[8] CurrentTaskFile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct MPIO_PASS_THROUGH_PATH32
{
	public SCSI_PASS_THROUGH32 PassThrough;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct MPIO_PASS_THROUGH_PATH_DIRECT32
{
	public SCSI_PASS_THROUGH_DIRECT32 PassThrough;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct MPIO_PASS_THROUGH_PATH32_EX
{
	public uint32 PassThroughOffset;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct MPIO_PASS_THROUGH_PATH_DIRECT32_EX
{
	public uint32 PassThroughOffset;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}
#endif

[CRepr]
public struct SCSI_PASS_THROUGH
{
	public uint16 Length;
	public uint8 ScsiStatus;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 CdbLength;
	public uint8 SenseInfoLength;
	public uint8 DataIn;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public uint DataBufferOffset;
	public uint32 SenseInfoOffset;
	public uint8[16] Cdb;
}

[CRepr]
public struct SCSI_PASS_THROUGH_DIRECT
{
	public uint16 Length;
	public uint8 ScsiStatus;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 CdbLength;
	public uint8 SenseInfoLength;
	public uint8 DataIn;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public void* DataBuffer;
	public uint32 SenseInfoOffset;
	public uint8[16] Cdb;
}

[CRepr]
public struct SCSI_PASS_THROUGH_EX
{
	public uint32 Version;
	public uint32 Length;
	public uint32 CdbLength;
	public uint32 StorAddressLength;
	public uint8 ScsiStatus;
	public uint8 SenseInfoLength;
	public uint8 DataDirection;
	public uint8 Reserved;
	public uint32 TimeOutValue;
	public uint32 StorAddressOffset;
	public uint32 SenseInfoOffset;
	public uint32 DataOutTransferLength;
	public uint32 DataInTransferLength;
	public uint DataOutBufferOffset;
	public uint DataInBufferOffset;
	public uint8* Cdb mut => &Cdb_impl;
	private uint8[ANYSIZE_ARRAY] Cdb_impl;
}

[CRepr]
public struct SCSI_PASS_THROUGH_DIRECT_EX
{
	public uint32 Version;
	public uint32 Length;
	public uint32 CdbLength;
	public uint32 StorAddressLength;
	public uint8 ScsiStatus;
	public uint8 SenseInfoLength;
	public uint8 DataDirection;
	public uint8 Reserved;
	public uint32 TimeOutValue;
	public uint32 StorAddressOffset;
	public uint32 SenseInfoOffset;
	public uint32 DataOutTransferLength;
	public uint32 DataInTransferLength;
	public void* DataOutBuffer;
	public void* DataInBuffer;
	public uint8* Cdb mut => &Cdb_impl;
	private uint8[ANYSIZE_ARRAY] Cdb_impl;
}

[CRepr]
public struct ATA_PASS_THROUGH_EX
{
	public uint16 Length;
	public uint16 AtaFlags;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 ReservedAsUchar;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public uint32 ReservedAsUlong;
	public uint DataBufferOffset;
	public uint8[8] PreviousTaskFile;
	public uint8[8] CurrentTaskFile;
}

[CRepr]
public struct ATA_PASS_THROUGH_DIRECT
{
	public uint16 Length;
	public uint16 AtaFlags;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public uint8 ReservedAsUchar;
	public uint32 DataTransferLength;
	public uint32 TimeOutValue;
	public uint32 ReservedAsUlong;
	public void* DataBuffer;
	public uint8[8] PreviousTaskFile;
	public uint8[8] CurrentTaskFile;
}

[CRepr]
public struct IDE_IO_CONTROL
{
	public uint32 HeaderLength;
	public uint8[8] Signature;
	public uint32 Timeout;
	public uint32 ControlCode;
	public uint32 ReturnStatus;
	public uint32 DataLength;
}

[CRepr]
public struct MPIO_PASS_THROUGH_PATH
{
	public SCSI_PASS_THROUGH PassThrough;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}

[CRepr]
public struct MPIO_PASS_THROUGH_PATH_DIRECT
{
	public SCSI_PASS_THROUGH_DIRECT PassThrough;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}

[CRepr]
public struct MPIO_PASS_THROUGH_PATH_EX
{
	public uint32 PassThroughOffset;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}

[CRepr]
public struct MPIO_PASS_THROUGH_PATH_DIRECT_EX
{
	public uint32 PassThroughOffset;
	public uint32 Version;
	public uint16 Length;
	public uint8 Flags;
	public uint8 PortNumber;
	public uint64 MpioPathId;
}

[CRepr]
public struct SCSI_BUS_DATA
{
	public uint8 NumberOfLogicalUnits;
	public uint8 InitiatorBusId;
	public uint32 InquiryDataOffset;
}

[CRepr]
public struct SCSI_ADAPTER_BUS_INFO
{
	public uint8 NumberOfBuses;
	public SCSI_BUS_DATA* BusData mut => &BusData_impl;
	private SCSI_BUS_DATA[ANYSIZE_ARRAY] BusData_impl;
}

[CRepr]
public struct SCSI_INQUIRY_DATA
{
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
	public BOOLEAN DeviceClaimed;
	public uint32 InquiryDataLength;
	public uint32 NextInquiryDataOffset;
	public uint8* InquiryData mut => &InquiryData_impl;
	private uint8[ANYSIZE_ARRAY] InquiryData_impl;
}

[CRepr]
public struct SRB_IO_CONTROL
{
	public uint32 HeaderLength;
	public uint8[8] Signature;
	public uint32 Timeout;
	public uint32 ControlCode;
	public uint32 ReturnCode;
	public uint32 Length;
}

[CRepr]
public struct NVCACHE_REQUEST_BLOCK
{
	public uint32 NRBSize;
	public uint16 Function;
	public uint32 NRBFlags;
	public uint32 NRBStatus;
	public uint32 Count;
	public uint64 LBA;
	public uint32 DataBufSize;
	public uint32 NVCacheStatus;
	public uint32 NVCacheSubStatus;
}

[CRepr]
public struct NV_FEATURE_PARAMETER
{
	public uint16 NVPowerModeEnabled;
	public uint16 NVParameterReserv1;
	public uint16 NVCmdEnabled;
	public uint16 NVParameterReserv2;
	public uint16 NVPowerModeVer;
	public uint16 NVCmdVer;
	public uint32 NVSize;
	public uint16 NVReadSpeed;
	public uint16 NVWrtSpeed;
	public uint32 DeviceSpinUpTime;
}

[CRepr]
public struct NVCACHE_HINT_PAYLOAD
{
	public uint8 Command;
	public uint8 Feature7_0;
	public uint8 Feature15_8;
	public uint8 Count15_8;
	public uint8 LBA7_0;
	public uint8 LBA15_8;
	public uint8 LBA23_16;
	public uint8 LBA31_24;
	public uint8 LBA39_32;
	public uint8 LBA47_40;
	public uint8 Auxiliary7_0;
	public uint8 Auxiliary23_16;
	public uint8[4] Reserved;
}

[CRepr]
public struct NV_SEP_CACHE_PARAMETER
{
	[CRepr, Union]
	public struct _Flags_e__Union
	{
		[CRepr]
		public struct _CacheFlags_e__Struct
		{
			public uint8 _bitfield;
		}
		public _CacheFlags_e__Struct CacheFlags;
		public uint8 CacheFlagsSet;
	}
	public uint32 Version;
	public uint32 Size;
	public _Flags_e__Union Flags;
	public uint8 WriteCacheType;
	public uint8 WriteCacheTypeEffective;
	public uint8[3] ParameterReserve1;
}

[CRepr]
public struct STORAGE_DIAGNOSTIC_MP_REQUEST
{
	public uint32 Version;
	public uint32 Size;
	public MP_STORAGE_DIAGNOSTIC_TARGET_TYPE TargetType;
	public MP_STORAGE_DIAGNOSTIC_LEVEL Level;
	public Guid ProviderId;
	public uint32 BufferSize;
	public uint32 Reserved;
	public uint8* DataBuffer mut => &DataBuffer_impl;
	private uint8[ANYSIZE_ARRAY] DataBuffer_impl;
}

[CRepr]
public struct MP_DEVICE_DATA_SET_RANGE
{
	public int64 StartingOffset;
	public uint64 LengthInBytes;
}

[CRepr]
public struct DSM_NOTIFICATION_REQUEST_BLOCK
{
	public uint32 Size;
	public uint32 Version;
	public uint32 NotifyFlags;
	public uint32 DataSetProfile;
	public uint32[3] Reserved;
	public uint32 DataSetRangesCount;
	public MP_DEVICE_DATA_SET_RANGE* DataSetRanges mut => &DataSetRanges_impl;
	private MP_DEVICE_DATA_SET_RANGE[ANYSIZE_ARRAY] DataSetRanges_impl;
}

[CRepr]
public struct HYBRID_REQUEST_BLOCK
{
	public uint32 Version;
	public uint32 Size;
	public uint32 Function;
	public uint32 Flags;
	public uint32 DataBufferOffset;
	public uint32 DataBufferLength;
}

[CRepr]
public struct NVCACHE_PRIORITY_LEVEL_DESCRIPTOR
{
	public uint8 PriorityLevel;
	public uint8[3] Reserved0;
	public uint32 ConsumedNVMSizeFraction;
	public uint32 ConsumedMappingResourcesFraction;
	public uint32 ConsumedNVMSizeForDirtyDataFraction;
	public uint32 ConsumedMappingResourcesForDirtyDataFraction;
	public uint32 Reserved1;
}

[CRepr]
public struct HYBRID_INFORMATION
{
	[CRepr]
	public struct _Priorities_e__Struct
	{
		[CRepr]
		public struct _SupportedCommands_e__Struct
		{
			public uint32 _bitfield;
			public uint32 MaxEvictCommands;
			public uint32 MaxLbaRangeCountForEvict;
			public uint32 MaxLbaRangeCountForChangeLba;
		}
		public uint8 PriorityLevelCount;
		public BOOLEAN MaxPriorityBehavior;
		public uint8 OptimalWriteGranularity;
		public uint8 Reserved;
		public uint32 DirtyThresholdLow;
		public uint32 DirtyThresholdHigh;
		public _SupportedCommands_e__Struct SupportedCommands;
		public NVCACHE_PRIORITY_LEVEL_DESCRIPTOR* Priority mut => &Priority_impl;
		private NVCACHE_PRIORITY_LEVEL_DESCRIPTOR[ANYSIZE_ARRAY] Priority_impl;
	}
	[CRepr]
	public struct _Attributes_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 Version;
	public uint32 Size;
	public BOOLEAN HybridSupported;
	public NVCACHE_STATUS Status;
	public NVCACHE_TYPE CacheTypeEffective;
	public NVCACHE_TYPE CacheTypeDefault;
	public uint32 FractionBase;
	public uint64 CacheSize;
	public _Attributes_e__Struct Attributes;
	public _Priorities_e__Struct Priorities;
}

[CRepr]
public struct HYBRID_DIRTY_THRESHOLDS
{
	public uint32 Version;
	public uint32 Size;
	public uint32 DirtyLowThreshold;
	public uint32 DirtyHighThreshold;
}

[CRepr]
public struct HYBRID_DEMOTE_BY_SIZE
{
	public uint32 Version;
	public uint32 Size;
	public uint8 SourcePriority;
	public uint8 TargetPriority;
	public uint16 Reserved0;
	public uint32 Reserved1;
	public uint64 LbaCount;
}

[CRepr]
public struct FIRMWARE_REQUEST_BLOCK
{
	public uint32 Version;
	public uint32 Size;
	public uint32 Function;
	public uint32 Flags;
	public uint32 DataBufferOffset;
	public uint32 DataBufferLength;
}

[CRepr]
public struct STORAGE_FIRMWARE_SLOT_INFO
{
	[CRepr, Union]
	public struct _Revision_e__Union
	{
		public uint8[8] Info;
		public uint64 AsUlonglong;
	}
	public uint8 SlotNumber;
	public BOOLEAN ReadOnly;
	public uint8[6] Reserved;
	public _Revision_e__Union Revision;
}

[CRepr]
public struct STORAGE_FIRMWARE_SLOT_INFO_V2
{
	public uint8 SlotNumber;
	public BOOLEAN ReadOnly;
	public uint8[6] Reserved;
	public uint8[16] Revision;
}

[CRepr]
public struct STORAGE_FIRMWARE_INFO
{
	public uint32 Version;
	public uint32 Size;
	public BOOLEAN UpgradeSupport;
	public uint8 SlotCount;
	public uint8 ActiveSlot;
	public uint8 PendingActivateSlot;
	public uint32 Reserved;
	public STORAGE_FIRMWARE_SLOT_INFO* Slot mut => &Slot_impl;
	private STORAGE_FIRMWARE_SLOT_INFO[ANYSIZE_ARRAY] Slot_impl;
}

[CRepr]
public struct STORAGE_FIRMWARE_INFO_V2
{
	public uint32 Version;
	public uint32 Size;
	public BOOLEAN UpgradeSupport;
	public uint8 SlotCount;
	public uint8 ActiveSlot;
	public uint8 PendingActivateSlot;
	public BOOLEAN FirmwareShared;
	public uint8[3] Reserved;
	public uint32 ImagePayloadAlignment;
	public uint32 ImagePayloadMaxSize;
	public STORAGE_FIRMWARE_SLOT_INFO_V2* Slot mut => &Slot_impl;
	private STORAGE_FIRMWARE_SLOT_INFO_V2[ANYSIZE_ARRAY] Slot_impl;
}

[CRepr]
public struct STORAGE_FIRMWARE_DOWNLOAD
{
	public uint32 Version;
	public uint32 Size;
	public uint64 Offset;
	public uint64 BufferSize;
	public uint8* ImageBuffer mut => &ImageBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ImageBuffer_impl;
}

[CRepr]
public struct STORAGE_FIRMWARE_DOWNLOAD_V2
{
	public uint32 Version;
	public uint32 Size;
	public uint64 Offset;
	public uint64 BufferSize;
	public uint8 Slot;
	public uint8[3] Reserved;
	public uint32 ImageSize;
	public uint8* ImageBuffer mut => &ImageBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ImageBuffer_impl;
}

[CRepr]
public struct STORAGE_FIRMWARE_ACTIVATE
{
	public uint32 Version;
	public uint32 Size;
	public uint8 SlotToActivate;
	public uint8[3] Reserved0;
}

[CRepr]
public struct IO_SCSI_CAPABILITIES
{
	public uint32 Length;
	public uint32 MaximumTransferLength;
	public uint32 MaximumPhysicalPages;
	public uint32 SupportedAsynchronousEvents;
	public uint32 AlignmentMask;
	public BOOLEAN TaggedQueuing;
	public BOOLEAN AdapterScansDown;
	public BOOLEAN AdapterUsesPio;
}

[CRepr]
public struct SCSI_ADDRESS
{
	public uint32 Length;
	public uint8 PortNumber;
	public uint8 PathId;
	public uint8 TargetId;
	public uint8 Lun;
}

[CRepr]
public struct DUMP_POINTERS_VERSION
{
	public uint32 Version;
	public uint32 Size;
}

[CRepr]
public struct DUMP_POINTERS
{
	public _ADAPTER_OBJECT* AdapterObject;
	public void* MappedRegisterBase;
	public void* DumpData;
	public void* CommonBufferVa;
	public LARGE_INTEGER CommonBufferPa;
	public uint32 CommonBufferSize;
	public BOOLEAN AllocateCommonBuffers;
	public BOOLEAN UseDiskDump;
	public uint8[2] Spare1;
	public void* DeviceObject;
}

[CRepr]
public struct DUMP_POINTERS_EX
{
	public DUMP_POINTERS_VERSION Header;
	public void* DumpData;
	public void* CommonBufferVa;
	public uint32 CommonBufferSize;
	public BOOLEAN AllocateCommonBuffers;
	public void* DeviceObject;
	public void* DriverList;
	public uint32 dwPortFlags;
	public uint32 MaxDeviceDumpSectionSize;
	public uint32 MaxDeviceDumpLevel;
	public uint32 MaxTransferSize;
	public void* AdapterObject;
	public void* MappedRegisterBase;
	public BOOLEAN* DeviceReady;
	public PDUMP_DEVICE_POWERON_ROUTINE DumpDevicePowerOn;
	public void* DumpDevicePowerOnContext;
}

[CRepr]
public struct DUMP_DRIVER
{
	public void* DumpDriverList;
	public char16[15] DriverName;
	public char16[15] BaseName;
}

[CRepr]
public struct NTSCSI_UNICODE_STRING
{
	public uint16 Length;
	public uint16 MaximumLength;
	public PWSTR Buffer;
}

[CRepr]
public struct DUMP_DRIVER_EX
{
	public void* DumpDriverList;
	public char16[15] DriverName;
	public char16[15] BaseName;
	public NTSCSI_UNICODE_STRING DriverFullPath;
}

[CRepr]
public struct STORAGE_ENDURANCE_INFO
{
	[CRepr]
	public struct _Flags_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 ValidFields;
	public uint32 GroupId;
	public _Flags_e__Struct Flags;
	public uint32 LifePercentage;
	public uint8[16] BytesReadCount;
	public uint8[16] ByteWriteCount;
}

[CRepr]
public struct STORAGE_ENDURANCE_DATA_DESCRIPTOR
{
	public uint32 Version;
	public uint32 Size;
	public STORAGE_ENDURANCE_INFO EnduranceInfo;
}

[CRepr]
public struct ISCSI_LOGIN_OPTIONS
{
	public uint32 Version;
	public uint32 InformationSpecified;
	public uint32 LoginFlags;
	public ISCSI_AUTH_TYPES AuthType;
	public ISCSI_DIGEST_TYPES HeaderDigest;
	public ISCSI_DIGEST_TYPES DataDigest;
	public uint32 MaximumConnections;
	public uint32 DefaultTime2Wait;
	public uint32 DefaultTime2Retain;
	public uint32 UsernameLength;
	public uint32 PasswordLength;
	public uint8* Username;
	public uint8* Password;
}

[CRepr]
public struct IKE_AUTHENTICATION_PRESHARED_KEY
{
	public uint64 SecurityFlags;
	public uint8 IdType;
	public uint32 IdLengthInBytes;
	public uint8* Id;
	public uint32 KeyLengthInBytes;
	public uint8* Key;
}

[CRepr]
public struct IKE_AUTHENTICATION_INFORMATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKE_AUTHENTICATION_PRESHARED_KEY PsKey;
	}
	public IKE_AUTHENTICATION_METHOD AuthMethod;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct ISCSI_UNIQUE_SESSION_ID
{
	public uint64 AdapterUnique;
	public uint64 AdapterSpecific;
}

[CRepr]
public struct SCSI_LUN_LIST
{
	public uint32 OSLUN;
	public uint64 TargetLUN;
}

[CRepr]
public struct ISCSI_TARGET_MAPPINGW
{
	public char16[256] InitiatorName;
	public char16[224] TargetName;
	public char16[260] OSDeviceName;
	public ISCSI_UNIQUE_SESSION_ID SessionId;
	public uint32 OSBusNumber;
	public uint32 OSTargetNumber;
	public uint32 LUNCount;
	public SCSI_LUN_LIST* LUNList;
}

[CRepr]
public struct ISCSI_TARGET_MAPPINGA
{
	public CHAR[256] InitiatorName;
	public CHAR[224] TargetName;
	public CHAR[260] OSDeviceName;
	public ISCSI_UNIQUE_SESSION_ID SessionId;
	public uint32 OSBusNumber;
	public uint32 OSTargetNumber;
	public uint32 LUNCount;
	public SCSI_LUN_LIST* LUNList;
}

[CRepr]
public struct ISCSI_TARGET_PORTALW
{
	public char16[256] SymbolicName;
	public char16[256] Address;
	public uint16 Socket;
}

[CRepr]
public struct ISCSI_TARGET_PORTALA
{
	public CHAR[256] SymbolicName;
	public CHAR[256] Address;
	public uint16 Socket;
}

[CRepr]
public struct ISCSI_TARGET_PORTAL_INFOW
{
	public char16[256] InitiatorName;
	public uint32 InitiatorPortNumber;
	public char16[256] SymbolicName;
	public char16[256] Address;
	public uint16 Socket;
}

[CRepr]
public struct ISCSI_TARGET_PORTAL_INFOA
{
	public CHAR[256] InitiatorName;
	public uint32 InitiatorPortNumber;
	public CHAR[256] SymbolicName;
	public CHAR[256] Address;
	public uint16 Socket;
}

[CRepr]
public struct ISCSI_TARGET_PORTAL_INFO_EXW
{
	public char16[256] InitiatorName;
	public uint32 InitiatorPortNumber;
	public char16[256] SymbolicName;
	public char16[256] Address;
	public uint16 Socket;
	public uint64 SecurityFlags;
	public ISCSI_LOGIN_OPTIONS LoginOptions;
}

[CRepr]
public struct ISCSI_TARGET_PORTAL_INFO_EXA
{
	public CHAR[256] InitiatorName;
	public uint32 InitiatorPortNumber;
	public CHAR[256] SymbolicName;
	public CHAR[256] Address;
	public uint16 Socket;
	public uint64 SecurityFlags;
	public ISCSI_LOGIN_OPTIONS LoginOptions;
}

[CRepr]
public struct ISCSI_TARGET_PORTAL_GROUPW
{
	public uint32 Count;
	public ISCSI_TARGET_PORTALW* Portals mut => &Portals_impl;
	private ISCSI_TARGET_PORTALW[ANYSIZE_ARRAY] Portals_impl;
}

[CRepr]
public struct ISCSI_TARGET_PORTAL_GROUPA
{
	public uint32 Count;
	public ISCSI_TARGET_PORTALA* Portals mut => &Portals_impl;
	private ISCSI_TARGET_PORTALA[ANYSIZE_ARRAY] Portals_impl;
}

[CRepr]
public struct ISCSI_CONNECTION_INFOW
{
	public ISCSI_UNIQUE_SESSION_ID ConnectionId;
	public PWSTR InitiatorAddress;
	public PWSTR TargetAddress;
	public uint16 InitiatorSocket;
	public uint16 TargetSocket;
	public uint8[2] CID;
}

[CRepr]
public struct ISCSI_SESSION_INFOW
{
	public ISCSI_UNIQUE_SESSION_ID SessionId;
	public PWSTR InitiatorName;
	public PWSTR TargetNodeName;
	public PWSTR TargetName;
	public uint8[6] ISID;
	public uint8[2] TSID;
	public uint32 ConnectionCount;
	public ISCSI_CONNECTION_INFOW* Connections;
}

[CRepr]
public struct ISCSI_CONNECTION_INFOA
{
	public ISCSI_UNIQUE_SESSION_ID ConnectionId;
	public PSTR InitiatorAddress;
	public PSTR TargetAddress;
	public uint16 InitiatorSocket;
	public uint16 TargetSocket;
	public uint8[2] CID;
}

[CRepr]
public struct ISCSI_SESSION_INFOA
{
	public ISCSI_UNIQUE_SESSION_ID SessionId;
	public PSTR InitiatorName;
	public PSTR TargetNodeName;
	public PSTR TargetName;
	public uint8[6] ISID;
	public uint8[2] TSID;
	public uint32 ConnectionCount;
	public ISCSI_CONNECTION_INFOA* Connections;
}

[CRepr]
public struct ISCSI_CONNECTION_INFO_EX
{
	public ISCSI_UNIQUE_SESSION_ID ConnectionId;
	public uint8 State;
	public uint8 Protocol;
	public uint8 HeaderDigest;
	public uint8 DataDigest;
	public uint32 MaxRecvDataSegmentLength;
	public ISCSI_AUTH_TYPES AuthType;
	public uint64 EstimatedThroughput;
	public uint32 MaxDatagramSize;
}

[CRepr]
public struct ISCSI_SESSION_INFO_EX
{
	public ISCSI_UNIQUE_SESSION_ID SessionId;
	public BOOLEAN InitialR2t;
	public BOOLEAN ImmediateData;
	public uint8 Type;
	public BOOLEAN DataSequenceInOrder;
	public BOOLEAN DataPduInOrder;
	public uint8 ErrorRecoveryLevel;
	public uint32 MaxOutstandingR2t;
	public uint32 FirstBurstLength;
	public uint32 MaxBurstLength;
	public uint32 MaximumConnections;
	public uint32 ConnectionCount;
	public ISCSI_CONNECTION_INFO_EX* Connections;
}

[CRepr]
public struct ISCSI_DEVICE_ON_SESSIONW
{
	public char16[256] InitiatorName;
	public char16[224] TargetName;
	public SCSI_ADDRESS ScsiAddress;
	public Guid DeviceInterfaceType;
	public char16[260] DeviceInterfaceName;
	public char16[260] LegacyName;
	public STORAGE_DEVICE_NUMBER StorageDeviceNumber;
	public uint32 DeviceInstance;
}

[CRepr]
public struct ISCSI_DEVICE_ON_SESSIONA
{
	public CHAR[256] InitiatorName;
	public CHAR[224] TargetName;
	public SCSI_ADDRESS ScsiAddress;
	public Guid DeviceInterfaceType;
	public CHAR[260] DeviceInterfaceName;
	public CHAR[260] LegacyName;
	public STORAGE_DEVICE_NUMBER StorageDeviceNumber;
	public uint32 DeviceInstance;
}

[CRepr]
public struct PERSISTENT_ISCSI_LOGIN_INFOW
{
	public char16[224] TargetName;
	public BOOLEAN IsInformationalSession;
	public char16[256] InitiatorInstance;
	public uint32 InitiatorPortNumber;
	public ISCSI_TARGET_PORTALW TargetPortal;
	public uint64 SecurityFlags;
	public ISCSI_TARGET_MAPPINGW* Mappings;
	public ISCSI_LOGIN_OPTIONS LoginOptions;
}

[CRepr]
public struct PERSISTENT_ISCSI_LOGIN_INFOA
{
	public CHAR[224] TargetName;
	public BOOLEAN IsInformationalSession;
	public CHAR[256] InitiatorInstance;
	public uint32 InitiatorPortNumber;
	public ISCSI_TARGET_PORTALA TargetPortal;
	public uint64 SecurityFlags;
	public ISCSI_TARGET_MAPPINGA* Mappings;
	public ISCSI_LOGIN_OPTIONS LoginOptions;
}

[CRepr]
public struct ISCSI_VERSION_INFO
{
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint32 BuildNumber;
}

#endregion

#region Functions
public static
{
	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiVersionInformation(ISCSI_VERSION_INFO* VersionInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiTargetInformationW(PWSTR TargetName, PWSTR DiscoveryMechanism, TARGET_INFORMATION_CLASS InfoClass, uint32* BufferSize, void* Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiTargetInformationA(PSTR TargetName, PSTR DiscoveryMechanism, TARGET_INFORMATION_CLASS InfoClass, uint32* BufferSize, void* Buffer);
	public static uint32 GetIScsiTargetInformation(PSTR TargetName, PSTR DiscoveryMechanism, TARGET_INFORMATION_CLASS InfoClass, uint32* BufferSize, void* Buffer) => GetIScsiTargetInformationA(TargetName, DiscoveryMechanism, InfoClass, BufferSize, Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddIScsiConnectionW(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, void* Reserved, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALW* TargetPortal, uint64 SecurityFlags, ISCSI_LOGIN_OPTIONS* LoginOptions, uint32 KeySize, uint8* Key, ISCSI_UNIQUE_SESSION_ID* ConnectionId);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddIScsiConnectionA(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, void* Reserved, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* TargetPortal, uint64 SecurityFlags, ISCSI_LOGIN_OPTIONS* LoginOptions, uint32 KeySize, uint8* Key, ISCSI_UNIQUE_SESSION_ID* ConnectionId);
	public static uint32 AddIScsiConnection(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, void* Reserved, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* TargetPortal, uint64 SecurityFlags, ISCSI_LOGIN_OPTIONS* LoginOptions, uint32 KeySize, uint8* Key, ISCSI_UNIQUE_SESSION_ID* ConnectionId) => AddIScsiConnectionA(UniqueSessionId, Reserved, InitiatorPortNumber, TargetPortal, SecurityFlags, LoginOptions, KeySize, Key, ConnectionId);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiConnection(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, ISCSI_UNIQUE_SESSION_ID* ConnectionId);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiTargetsW(BOOLEAN ForceUpdate, uint32* BufferSize, char16* Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiTargetsA(BOOLEAN ForceUpdate, uint32* BufferSize, uint8* Buffer);
	public static uint32 ReportIScsiTargets(BOOLEAN ForceUpdate, uint32* BufferSize, uint8* Buffer) => ReportIScsiTargetsA(ForceUpdate, BufferSize, Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddIScsiStaticTargetW(PWSTR TargetName, PWSTR TargetAlias, uint32 TargetFlags, BOOLEAN Persist, ISCSI_TARGET_MAPPINGW* Mappings, ISCSI_LOGIN_OPTIONS* LoginOptions, ISCSI_TARGET_PORTAL_GROUPW* PortalGroup);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddIScsiStaticTargetA(PSTR TargetName, PSTR TargetAlias, uint32 TargetFlags, BOOLEAN Persist, ISCSI_TARGET_MAPPINGA* Mappings, ISCSI_LOGIN_OPTIONS* LoginOptions, ISCSI_TARGET_PORTAL_GROUPA* PortalGroup);
	public static uint32 AddIScsiStaticTarget(PSTR TargetName, PSTR TargetAlias, uint32 TargetFlags, BOOLEAN Persist, ISCSI_TARGET_MAPPINGA* Mappings, ISCSI_LOGIN_OPTIONS* LoginOptions, ISCSI_TARGET_PORTAL_GROUPA* PortalGroup) => AddIScsiStaticTargetA(TargetName, TargetAlias, TargetFlags, Persist, Mappings, LoginOptions, PortalGroup);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiStaticTargetW(PWSTR TargetName);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiStaticTargetA(PSTR TargetName);
	public static uint32 RemoveIScsiStaticTarget(PSTR TargetName) => RemoveIScsiStaticTargetA(TargetName);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddIScsiSendTargetPortalW(PWSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_LOGIN_OPTIONS* LoginOptions, uint64 SecurityFlags, ISCSI_TARGET_PORTALW* Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddIScsiSendTargetPortalA(PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_LOGIN_OPTIONS* LoginOptions, uint64 SecurityFlags, ISCSI_TARGET_PORTALA* Portal);
	public static uint32 AddIScsiSendTargetPortal(PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_LOGIN_OPTIONS* LoginOptions, uint64 SecurityFlags, ISCSI_TARGET_PORTALA* Portal) => AddIScsiSendTargetPortalA(InitiatorInstance, InitiatorPortNumber, LoginOptions, SecurityFlags, Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiSendTargetPortalW(PWSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALW* Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiSendTargetPortalA(PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* Portal);
	public static uint32 RemoveIScsiSendTargetPortal(PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* Portal) => RemoveIScsiSendTargetPortalA(InitiatorInstance, InitiatorPortNumber, Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RefreshIScsiSendTargetPortalW(PWSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALW* Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RefreshIScsiSendTargetPortalA(PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* Portal);
	public static uint32 RefreshIScsiSendTargetPortal(PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* Portal) => RefreshIScsiSendTargetPortalA(InitiatorInstance, InitiatorPortNumber, Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiSendTargetPortalsW(uint32* PortalCount, ISCSI_TARGET_PORTAL_INFOW* PortalInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiSendTargetPortalsA(uint32* PortalCount, ISCSI_TARGET_PORTAL_INFOA* PortalInfo);
	public static uint32 ReportIScsiSendTargetPortals(uint32* PortalCount, ISCSI_TARGET_PORTAL_INFOA* PortalInfo) => ReportIScsiSendTargetPortalsA(PortalCount, PortalInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiSendTargetPortalsExW(uint32* PortalCount, uint32* PortalInfoSize, ISCSI_TARGET_PORTAL_INFO_EXW* PortalInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiSendTargetPortalsExA(uint32* PortalCount, uint32* PortalInfoSize, ISCSI_TARGET_PORTAL_INFO_EXA* PortalInfo);
	public static uint32 ReportIScsiSendTargetPortalsEx(uint32* PortalCount, uint32* PortalInfoSize, ISCSI_TARGET_PORTAL_INFO_EXA* PortalInfo) => ReportIScsiSendTargetPortalsExA(PortalCount, PortalInfoSize, PortalInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LoginIScsiTargetW(PWSTR TargetName, BOOLEAN IsInformationalSession, PWSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALW* TargetPortal, uint64 SecurityFlags, ISCSI_TARGET_MAPPINGW* Mappings, ISCSI_LOGIN_OPTIONS* LoginOptions, uint32 KeySize, uint8* Key, BOOLEAN IsPersistent, ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, ISCSI_UNIQUE_SESSION_ID* UniqueConnectionId);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LoginIScsiTargetA(PSTR TargetName, BOOLEAN IsInformationalSession, PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* TargetPortal, uint64 SecurityFlags, ISCSI_TARGET_MAPPINGA* Mappings, ISCSI_LOGIN_OPTIONS* LoginOptions, uint32 KeySize, uint8* Key, BOOLEAN IsPersistent, ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, ISCSI_UNIQUE_SESSION_ID* UniqueConnectionId);
	public static uint32 LoginIScsiTarget(PSTR TargetName, BOOLEAN IsInformationalSession, PSTR InitiatorInstance, uint32 InitiatorPortNumber, ISCSI_TARGET_PORTALA* TargetPortal, uint64 SecurityFlags, ISCSI_TARGET_MAPPINGA* Mappings, ISCSI_LOGIN_OPTIONS* LoginOptions, uint32 KeySize, uint8* Key, BOOLEAN IsPersistent, ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, ISCSI_UNIQUE_SESSION_ID* UniqueConnectionId) => LoginIScsiTargetA(TargetName, IsInformationalSession, InitiatorInstance, InitiatorPortNumber, TargetPortal, SecurityFlags, Mappings, LoginOptions, KeySize, Key, IsPersistent, UniqueSessionId, UniqueConnectionId);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiPersistentLoginsW(uint32* Count, PERSISTENT_ISCSI_LOGIN_INFOW* PersistentLoginInfo, uint32* BufferSizeInBytes);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiPersistentLoginsA(uint32* Count, PERSISTENT_ISCSI_LOGIN_INFOA* PersistentLoginInfo, uint32* BufferSizeInBytes);
	public static uint32 ReportIScsiPersistentLogins(uint32* Count, PERSISTENT_ISCSI_LOGIN_INFOA* PersistentLoginInfo, uint32* BufferSizeInBytes) => ReportIScsiPersistentLoginsA(Count, PersistentLoginInfo, BufferSizeInBytes);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LogoutIScsiTarget(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiPersistentTargetW(PWSTR InitiatorInstance, uint32 InitiatorPortNumber, PWSTR TargetName, ISCSI_TARGET_PORTALW* Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveIScsiPersistentTargetA(PSTR InitiatorInstance, uint32 InitiatorPortNumber, PSTR TargetName, ISCSI_TARGET_PORTALA* Portal);
	public static uint32 RemoveIScsiPersistentTarget(PSTR InitiatorInstance, uint32 InitiatorPortNumber, PSTR TargetName, ISCSI_TARGET_PORTALA* Portal) => RemoveIScsiPersistentTargetA(InitiatorInstance, InitiatorPortNumber, TargetName, Portal);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SendScsiInquiry(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, uint64 Lun, uint8 EvpdCmddt, uint8 PageCode, uint8* ScsiStatus, uint32* ResponseSize, uint8* ResponseBuffer, uint32* SenseSize, uint8* SenseBuffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SendScsiReadCapacity(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, uint64 Lun, uint8* ScsiStatus, uint32* ResponseSize, uint8* ResponseBuffer, uint32* SenseSize, uint8* SenseBuffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SendScsiReportLuns(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, uint8* ScsiStatus, uint32* ResponseSize, uint8* ResponseBuffer, uint32* SenseSize, uint8* SenseBuffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiInitiatorListW(uint32* BufferSize, char16* Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiInitiatorListA(uint32* BufferSize, uint8* Buffer);
	public static uint32 ReportIScsiInitiatorList(uint32* BufferSize, uint8* Buffer) => ReportIScsiInitiatorListA(BufferSize, Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportActiveIScsiTargetMappingsW(uint32* BufferSize, uint32* MappingCount, ISCSI_TARGET_MAPPINGW* Mappings);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportActiveIScsiTargetMappingsA(uint32* BufferSize, uint32* MappingCount, ISCSI_TARGET_MAPPINGA* Mappings);
	public static uint32 ReportActiveIScsiTargetMappings(uint32* BufferSize, uint32* MappingCount, ISCSI_TARGET_MAPPINGA* Mappings) => ReportActiveIScsiTargetMappingsA(BufferSize, MappingCount, Mappings);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiTunnelModeOuterAddressW(PWSTR InitiatorName, uint32 InitiatorPortNumber, PWSTR DestinationAddress, PWSTR OuterModeAddress, BOOLEAN Persist);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiTunnelModeOuterAddressA(PSTR InitiatorName, uint32 InitiatorPortNumber, PSTR DestinationAddress, PSTR OuterModeAddress, BOOLEAN Persist);
	public static uint32 SetIScsiTunnelModeOuterAddress(PSTR InitiatorName, uint32 InitiatorPortNumber, PSTR DestinationAddress, PSTR OuterModeAddress, BOOLEAN Persist) => SetIScsiTunnelModeOuterAddressA(InitiatorName, InitiatorPortNumber, DestinationAddress, OuterModeAddress, Persist);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiIKEInfoW(PWSTR InitiatorName, uint32 InitiatorPortNumber, IKE_AUTHENTICATION_INFORMATION* AuthInfo, BOOLEAN Persist);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiIKEInfoA(PSTR InitiatorName, uint32 InitiatorPortNumber, IKE_AUTHENTICATION_INFORMATION* AuthInfo, BOOLEAN Persist);
	public static uint32 SetIScsiIKEInfo(PSTR InitiatorName, uint32 InitiatorPortNumber, IKE_AUTHENTICATION_INFORMATION* AuthInfo, BOOLEAN Persist) => SetIScsiIKEInfoA(InitiatorName, InitiatorPortNumber, AuthInfo, Persist);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiIKEInfoW(PWSTR InitiatorName, uint32 InitiatorPortNumber, uint32* Reserved, IKE_AUTHENTICATION_INFORMATION* AuthInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiIKEInfoA(PSTR InitiatorName, uint32 InitiatorPortNumber, uint32* Reserved, IKE_AUTHENTICATION_INFORMATION* AuthInfo);
	public static uint32 GetIScsiIKEInfo(PSTR InitiatorName, uint32 InitiatorPortNumber, uint32* Reserved, IKE_AUTHENTICATION_INFORMATION* AuthInfo) => GetIScsiIKEInfoA(InitiatorName, InitiatorPortNumber, Reserved, AuthInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiGroupPresharedKey(uint32 KeyLength, uint8* Key, BOOLEAN Persist);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiInitiatorCHAPSharedSecret(uint32 SharedSecretLength, uint8* SharedSecret);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiInitiatorRADIUSSharedSecret(uint32 SharedSecretLength, uint8* SharedSecret);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiInitiatorNodeNameW(PWSTR InitiatorNodeName);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetIScsiInitiatorNodeNameA(PSTR InitiatorNodeName);
	public static uint32 SetIScsiInitiatorNodeName(PSTR InitiatorNodeName) => SetIScsiInitiatorNodeNameA(InitiatorNodeName);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiInitiatorNodeNameW(PWSTR InitiatorNodeName);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiInitiatorNodeNameA(PSTR InitiatorNodeName);
	public static uint32 GetIScsiInitiatorNodeName(PSTR InitiatorNodeName) => GetIScsiInitiatorNodeNameA(InitiatorNodeName);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddISNSServerW(PWSTR Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddISNSServerA(PSTR Address);
	public static uint32 AddISNSServer(PSTR Address) => AddISNSServerA(Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveISNSServerW(PWSTR Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveISNSServerA(PSTR Address);
	public static uint32 RemoveISNSServer(PSTR Address) => RemoveISNSServerA(Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RefreshISNSServerW(PWSTR Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RefreshISNSServerA(PSTR Address);
	public static uint32 RefreshISNSServer(PSTR Address) => RefreshISNSServerA(Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportISNSServerListW(uint32* BufferSizeInChar, char16* Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportISNSServerListA(uint32* BufferSizeInChar, uint8* Buffer);
	public static uint32 ReportISNSServerList(uint32* BufferSizeInChar, uint8* Buffer) => ReportISNSServerListA(BufferSizeInChar, Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiSessionListW(uint32* BufferSize, uint32* SessionCount, ISCSI_SESSION_INFOW* SessionInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiSessionListA(uint32* BufferSize, uint32* SessionCount, ISCSI_SESSION_INFOA* SessionInfo);
	public static uint32 GetIScsiSessionList(uint32* BufferSize, uint32* SessionCount, ISCSI_SESSION_INFOA* SessionInfo) => GetIScsiSessionListA(BufferSize, SessionCount, SessionInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetIScsiSessionListEx(uint32* BufferSize, uint32* SessionCountPtr, ISCSI_SESSION_INFO_EX* SessionInfo);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDevicesForIScsiSessionW(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, uint32* DeviceCount, ISCSI_DEVICE_ON_SESSIONW* Devices);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDevicesForIScsiSessionA(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, uint32* DeviceCount, ISCSI_DEVICE_ON_SESSIONA* Devices);
	public static uint32 GetDevicesForIScsiSession(ISCSI_UNIQUE_SESSION_ID* UniqueSessionId, uint32* DeviceCount, ISCSI_DEVICE_ON_SESSIONA* Devices) => GetDevicesForIScsiSessionA(UniqueSessionId, DeviceCount, Devices);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupPersistentIScsiVolumes();

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupPersistentIScsiDevices();

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddPersistentIScsiDeviceW(PWSTR DevicePath);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddPersistentIScsiDeviceA(PSTR DevicePath);
	public static uint32 AddPersistentIScsiDevice(PSTR DevicePath) => AddPersistentIScsiDeviceA(DevicePath);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemovePersistentIScsiDeviceW(PWSTR DevicePath);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemovePersistentIScsiDeviceA(PSTR DevicePath);
	public static uint32 RemovePersistentIScsiDevice(PSTR DevicePath) => RemovePersistentIScsiDeviceA(DevicePath);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClearPersistentIScsiDevices();

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportPersistentIScsiDevicesW(uint32* BufferSizeInChar, char16* Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportPersistentIScsiDevicesA(uint32* BufferSizeInChar, uint8* Buffer);
	public static uint32 ReportPersistentIScsiDevices(uint32* BufferSizeInChar, uint8* Buffer) => ReportPersistentIScsiDevicesA(BufferSizeInChar, Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiTargetPortalsW(PWSTR InitiatorName, PWSTR TargetName, uint16* TargetPortalTag, uint32* ElementCount, ISCSI_TARGET_PORTALW* Portals);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportIScsiTargetPortalsA(PSTR InitiatorName, PSTR TargetName, uint16* TargetPortalTag, uint32* ElementCount, ISCSI_TARGET_PORTALA* Portals);
	public static uint32 ReportIScsiTargetPortals(PSTR InitiatorName, PSTR TargetName, uint16* TargetPortalTag, uint32* ElementCount, ISCSI_TARGET_PORTALA* Portals) => ReportIScsiTargetPortalsA(InitiatorName, TargetName, TargetPortalTag, ElementCount, Portals);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddRadiusServerW(PWSTR Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddRadiusServerA(PSTR Address);
	public static uint32 AddRadiusServer(PSTR Address) => AddRadiusServerA(Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveRadiusServerW(PWSTR Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveRadiusServerA(PSTR Address);
	public static uint32 RemoveRadiusServer(PSTR Address) => RemoveRadiusServerA(Address);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportRadiusServerListW(uint32* BufferSizeInChar, char16* Buffer);

	[Import("ISCSIDSC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReportRadiusServerListA(uint32* BufferSizeInChar, uint8* Buffer);
	public static uint32 ReportRadiusServerList(uint32* BufferSizeInChar, uint8* Buffer) => ReportRadiusServerListA(BufferSizeInChar, Buffer);

}
#endregion
