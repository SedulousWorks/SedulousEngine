using Win32.Storage.FileSystem;
using Win32.Foundation;
using Win32.System.CorrelationVector;
using Win32.System.IO;
using System;

namespace Win32.Storage.CloudFilters;

#region Constants
public static
{
	public const uint32 CF_REQUEST_KEY_DEFAULT = 0;
	public const uint32 CF_PLACEHOLDER_MAX_FILE_IDENTITY_LENGTH = 4096;
	public const uint32 CF_MAX_PRIORITY_HINT = 15;
	public const uint32 CF_MAX_PROVIDER_NAME_LENGTH = 255;
	public const uint32 CF_MAX_PROVIDER_VERSION_LENGTH = 255;
}
#endregion

#region TypeDefs
typealias CF_CONNECTION_KEY = int64;

#endregion


#region Enums

[AllowDuplicates]
public enum CF_PLACEHOLDER_CREATE_FLAGS : uint32
{
	CF_PLACEHOLDER_CREATE_FLAG_NONE = 0,
	CF_PLACEHOLDER_CREATE_FLAG_DISABLE_ON_DEMAND_POPULATION = 1,
	CF_PLACEHOLDER_CREATE_FLAG_MARK_IN_SYNC = 2,
	CF_PLACEHOLDER_CREATE_FLAG_SUPERSEDE = 4,
	CF_PLACEHOLDER_CREATE_FLAG_ALWAYS_FULL = 8,
}


[AllowDuplicates]
public enum CF_SYNC_PROVIDER_STATUS : uint32
{
	CF_PROVIDER_STATUS_DISCONNECTED = 0,
	CF_PROVIDER_STATUS_IDLE = 1,
	CF_PROVIDER_STATUS_POPULATE_NAMESPACE = 2,
	CF_PROVIDER_STATUS_POPULATE_METADATA = 4,
	CF_PROVIDER_STATUS_POPULATE_CONTENT = 8,
	CF_PROVIDER_STATUS_SYNC_INCREMENTAL = 16,
	CF_PROVIDER_STATUS_SYNC_FULL = 32,
	CF_PROVIDER_STATUS_CONNECTIVITY_LOST = 64,
	CF_PROVIDER_STATUS_CLEAR_FLAGS = 2147483648,
	CF_PROVIDER_STATUS_TERMINATED = 3221225473,
	CF_PROVIDER_STATUS_ERROR = 3221225474,
}


[AllowDuplicates]
public enum CF_REGISTER_FLAGS : uint32
{
	CF_REGISTER_FLAG_NONE = 0,
	CF_REGISTER_FLAG_UPDATE = 1,
	CF_REGISTER_FLAG_DISABLE_ON_DEMAND_POPULATION_ON_ROOT = 2,
	CF_REGISTER_FLAG_MARK_IN_SYNC_ON_ROOT = 4,
}


[AllowDuplicates]
public enum CF_HYDRATION_POLICY_PRIMARY : uint16
{
	CF_HYDRATION_POLICY_PARTIAL = 0,
	CF_HYDRATION_POLICY_PROGRESSIVE = 1,
	CF_HYDRATION_POLICY_FULL = 2,
	CF_HYDRATION_POLICY_ALWAYS_FULL = 3,
}


[AllowDuplicates]
public enum CF_HYDRATION_POLICY_MODIFIER : uint16
{
	CF_HYDRATION_POLICY_MODIFIER_NONE = 0,
	CF_HYDRATION_POLICY_MODIFIER_VALIDATION_REQUIRED = 1,
	CF_HYDRATION_POLICY_MODIFIER_STREAMING_ALLOWED = 2,
	CF_HYDRATION_POLICY_MODIFIER_AUTO_DEHYDRATION_ALLOWED = 4,
	CF_HYDRATION_POLICY_MODIFIER_ALLOW_FULL_RESTART_HYDRATION = 8,
}


[AllowDuplicates]
public enum CF_POPULATION_POLICY_PRIMARY : uint16
{
	CF_POPULATION_POLICY_PARTIAL = 0,
	CF_POPULATION_POLICY_FULL = 2,
	CF_POPULATION_POLICY_ALWAYS_FULL = 3,
}


[AllowDuplicates]
public enum CF_POPULATION_POLICY_MODIFIER : uint16
{
	CF_POPULATION_POLICY_MODIFIER_NONE = 0,
}


[AllowDuplicates]
public enum CF_PLACEHOLDER_MANAGEMENT_POLICY : int32
{
	CF_PLACEHOLDER_MANAGEMENT_POLICY_DEFAULT = 0,
	CF_PLACEHOLDER_MANAGEMENT_POLICY_CREATE_UNRESTRICTED = 1,
	CF_PLACEHOLDER_MANAGEMENT_POLICY_CONVERT_TO_UNRESTRICTED = 2,
	CF_PLACEHOLDER_MANAGEMENT_POLICY_UPDATE_UNRESTRICTED = 4,
}


[AllowDuplicates]
public enum CF_INSYNC_POLICY : uint32
{
	CF_INSYNC_POLICY_NONE = 0,
	CF_INSYNC_POLICY_TRACK_FILE_CREATION_TIME = 1,
	CF_INSYNC_POLICY_TRACK_FILE_READONLY_ATTRIBUTE = 2,
	CF_INSYNC_POLICY_TRACK_FILE_HIDDEN_ATTRIBUTE = 4,
	CF_INSYNC_POLICY_TRACK_FILE_SYSTEM_ATTRIBUTE = 8,
	CF_INSYNC_POLICY_TRACK_DIRECTORY_CREATION_TIME = 16,
	CF_INSYNC_POLICY_TRACK_DIRECTORY_READONLY_ATTRIBUTE = 32,
	CF_INSYNC_POLICY_TRACK_DIRECTORY_HIDDEN_ATTRIBUTE = 64,
	CF_INSYNC_POLICY_TRACK_DIRECTORY_SYSTEM_ATTRIBUTE = 128,
	CF_INSYNC_POLICY_TRACK_FILE_LAST_WRITE_TIME = 256,
	CF_INSYNC_POLICY_TRACK_DIRECTORY_LAST_WRITE_TIME = 512,
	CF_INSYNC_POLICY_TRACK_FILE_ALL = 5592335,
	CF_INSYNC_POLICY_TRACK_DIRECTORY_ALL = 11184880,
	CF_INSYNC_POLICY_TRACK_ALL = 16777215,
	CF_INSYNC_POLICY_PRESERVE_INSYNC_FOR_SYNC_ENGINE = 2147483648,
}


[AllowDuplicates]
public enum CF_HARDLINK_POLICY : uint32
{
	CF_HARDLINK_POLICY_NONE = 0,
	CF_HARDLINK_POLICY_ALLOWED = 1,
}


[AllowDuplicates]
public enum CF_CALLBACK_CANCEL_FLAGS : uint32
{
	CF_CALLBACK_CANCEL_FLAG_NONE = 0,
	CF_CALLBACK_CANCEL_FLAG_IO_TIMEOUT = 1,
	CF_CALLBACK_CANCEL_FLAG_IO_ABORTED = 2,
}


[AllowDuplicates]
public enum CF_CALLBACK_FETCH_DATA_FLAGS : uint32
{
	CF_CALLBACK_FETCH_DATA_FLAG_NONE = 0,
	CF_CALLBACK_FETCH_DATA_FLAG_RECOVERY = 1,
	CF_CALLBACK_FETCH_DATA_FLAG_EXPLICIT_HYDRATION = 2,
}


[AllowDuplicates]
public enum CF_CALLBACK_VALIDATE_DATA_FLAGS : uint32
{
	CF_CALLBACK_VALIDATE_DATA_FLAG_NONE = 0,
	CF_CALLBACK_VALIDATE_DATA_FLAG_EXPLICIT_HYDRATION = 2,
}


[AllowDuplicates]
public enum CF_CALLBACK_FETCH_PLACEHOLDERS_FLAGS : uint32
{
	CF_CALLBACK_FETCH_PLACEHOLDERS_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_CALLBACK_OPEN_COMPLETION_FLAGS : uint32
{
	CF_CALLBACK_OPEN_COMPLETION_FLAG_NONE = 0,
	CF_CALLBACK_OPEN_COMPLETION_FLAG_PLACEHOLDER_UNKNOWN = 1,
	CF_CALLBACK_OPEN_COMPLETION_FLAG_PLACEHOLDER_UNSUPPORTED = 2,
}


[AllowDuplicates]
public enum CF_CALLBACK_CLOSE_COMPLETION_FLAGS : uint32
{
	CF_CALLBACK_CLOSE_COMPLETION_FLAG_NONE = 0,
	CF_CALLBACK_CLOSE_COMPLETION_FLAG_DELETED = 1,
}


[AllowDuplicates]
public enum CF_CALLBACK_DEHYDRATE_FLAGS : uint32
{
	CF_CALLBACK_DEHYDRATE_FLAG_NONE = 0,
	CF_CALLBACK_DEHYDRATE_FLAG_BACKGROUND = 1,
}


[AllowDuplicates]
public enum CF_CALLBACK_DEHYDRATE_COMPLETION_FLAGS : uint32
{
	CF_CALLBACK_DEHYDRATE_COMPLETION_FLAG_NONE = 0,
	CF_CALLBACK_DEHYDRATE_COMPLETION_FLAG_BACKGROUND = 1,
	CF_CALLBACK_DEHYDRATE_COMPLETION_FLAG_DEHYDRATED = 2,
}


[AllowDuplicates]
public enum CF_CALLBACK_DELETE_FLAGS : uint32
{
	CF_CALLBACK_DELETE_FLAG_NONE = 0,
	CF_CALLBACK_DELETE_FLAG_IS_DIRECTORY = 1,
	CF_CALLBACK_DELETE_FLAG_IS_UNDELETE = 2,
}


[AllowDuplicates]
public enum CF_CALLBACK_DELETE_COMPLETION_FLAGS : uint32
{
	CF_CALLBACK_DELETE_COMPLETION_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_CALLBACK_RENAME_FLAGS : uint32
{
	CF_CALLBACK_RENAME_FLAG_NONE = 0,
	CF_CALLBACK_RENAME_FLAG_IS_DIRECTORY = 1,
	CF_CALLBACK_RENAME_FLAG_SOURCE_IN_SCOPE = 2,
	CF_CALLBACK_RENAME_FLAG_TARGET_IN_SCOPE = 4,
}


[AllowDuplicates]
public enum CF_CALLBACK_RENAME_COMPLETION_FLAGS : uint32
{
	CF_CALLBACK_RENAME_COMPLETION_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_CALLBACK_DEHYDRATION_REASON : int32
{
	CF_CALLBACK_DEHYDRATION_REASON_NONE = 0,
	CF_CALLBACK_DEHYDRATION_REASON_USER_MANUAL = 1,
	CF_CALLBACK_DEHYDRATION_REASON_SYSTEM_LOW_SPACE = 2,
	CF_CALLBACK_DEHYDRATION_REASON_SYSTEM_INACTIVITY = 3,
	CF_CALLBACK_DEHYDRATION_REASON_SYSTEM_OS_UPGRADE = 4,
}


[AllowDuplicates]
public enum CF_CALLBACK_TYPE : int32
{
	CF_CALLBACK_TYPE_FETCH_DATA = 0,
	CF_CALLBACK_TYPE_VALIDATE_DATA = 1,
	CF_CALLBACK_TYPE_CANCEL_FETCH_DATA = 2,
	CF_CALLBACK_TYPE_FETCH_PLACEHOLDERS = 3,
	CF_CALLBACK_TYPE_CANCEL_FETCH_PLACEHOLDERS = 4,
	CF_CALLBACK_TYPE_NOTIFY_FILE_OPEN_COMPLETION = 5,
	CF_CALLBACK_TYPE_NOTIFY_FILE_CLOSE_COMPLETION = 6,
	CF_CALLBACK_TYPE_NOTIFY_DEHYDRATE = 7,
	CF_CALLBACK_TYPE_NOTIFY_DEHYDRATE_COMPLETION = 8,
	CF_CALLBACK_TYPE_NOTIFY_DELETE = 9,
	CF_CALLBACK_TYPE_NOTIFY_DELETE_COMPLETION = 10,
	CF_CALLBACK_TYPE_NOTIFY_RENAME = 11,
	CF_CALLBACK_TYPE_NOTIFY_RENAME_COMPLETION = 12,
	CF_CALLBACK_TYPE_NONE = -1,
}


[AllowDuplicates]
public enum CF_CONNECT_FLAGS : uint32
{
	CF_CONNECT_FLAG_NONE = 0,
	CF_CONNECT_FLAG_REQUIRE_PROCESS_INFO = 2,
	CF_CONNECT_FLAG_REQUIRE_FULL_FILE_PATH = 4,
	CF_CONNECT_FLAG_BLOCK_SELF_IMPLICIT_HYDRATION = 8,
}


[AllowDuplicates]
public enum CF_OPERATION_TYPE : int32
{
	CF_OPERATION_TYPE_TRANSFER_DATA = 0,
	CF_OPERATION_TYPE_RETRIEVE_DATA = 1,
	CF_OPERATION_TYPE_ACK_DATA = 2,
	CF_OPERATION_TYPE_RESTART_HYDRATION = 3,
	CF_OPERATION_TYPE_TRANSFER_PLACEHOLDERS = 4,
	CF_OPERATION_TYPE_ACK_DEHYDRATE = 5,
	CF_OPERATION_TYPE_ACK_DELETE = 6,
	CF_OPERATION_TYPE_ACK_RENAME = 7,
}


[AllowDuplicates]
public enum CF_OPERATION_TRANSFER_DATA_FLAGS : uint32
{
	CF_OPERATION_TRANSFER_DATA_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_OPERATION_RETRIEVE_DATA_FLAGS : uint32
{
	CF_OPERATION_RETRIEVE_DATA_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_OPERATION_ACK_DATA_FLAGS : uint32
{
	CF_OPERATION_ACK_DATA_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_OPERATION_RESTART_HYDRATION_FLAGS : uint32
{
	CF_OPERATION_RESTART_HYDRATION_FLAG_NONE = 0,
	CF_OPERATION_RESTART_HYDRATION_FLAG_MARK_IN_SYNC = 1,
}


[AllowDuplicates]
public enum CF_OPERATION_TRANSFER_PLACEHOLDERS_FLAGS : uint32
{
	CF_OPERATION_TRANSFER_PLACEHOLDERS_FLAG_NONE = 0,
	CF_OPERATION_TRANSFER_PLACEHOLDERS_FLAG_STOP_ON_ERROR = 1,
	CF_OPERATION_TRANSFER_PLACEHOLDERS_FLAG_DISABLE_ON_DEMAND_POPULATION = 2,
}


[AllowDuplicates]
public enum CF_OPERATION_ACK_DEHYDRATE_FLAGS : uint32
{
	CF_OPERATION_ACK_DEHYDRATE_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_OPERATION_ACK_RENAME_FLAGS : uint32
{
	CF_OPERATION_ACK_RENAME_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_OPERATION_ACK_DELETE_FLAGS : uint32
{
	CF_OPERATION_ACK_DELETE_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_CREATE_FLAGS : uint32
{
	CF_CREATE_FLAG_NONE = 0,
	CF_CREATE_FLAG_STOP_ON_ERROR = 1,
}


[AllowDuplicates]
public enum CF_OPEN_FILE_FLAGS : uint32
{
	CF_OPEN_FILE_FLAG_NONE = 0,
	CF_OPEN_FILE_FLAG_EXCLUSIVE = 1,
	CF_OPEN_FILE_FLAG_WRITE_ACCESS = 2,
	CF_OPEN_FILE_FLAG_DELETE_ACCESS = 4,
	CF_OPEN_FILE_FLAG_FOREGROUND = 8,
}


[AllowDuplicates]
public enum CF_CONVERT_FLAGS : uint32
{
	CF_CONVERT_FLAG_NONE = 0,
	CF_CONVERT_FLAG_MARK_IN_SYNC = 1,
	CF_CONVERT_FLAG_DEHYDRATE = 2,
	CF_CONVERT_FLAG_ENABLE_ON_DEMAND_POPULATION = 4,
	CF_CONVERT_FLAG_ALWAYS_FULL = 8,
	CF_CONVERT_FLAG_FORCE_CONVERT_TO_CLOUD_FILE = 16,
}


[AllowDuplicates]
public enum CF_UPDATE_FLAGS : uint32
{
	CF_UPDATE_FLAG_NONE = 0,
	CF_UPDATE_FLAG_VERIFY_IN_SYNC = 1,
	CF_UPDATE_FLAG_MARK_IN_SYNC = 2,
	CF_UPDATE_FLAG_DEHYDRATE = 4,
	CF_UPDATE_FLAG_ENABLE_ON_DEMAND_POPULATION = 8,
	CF_UPDATE_FLAG_DISABLE_ON_DEMAND_POPULATION = 16,
	CF_UPDATE_FLAG_REMOVE_FILE_IDENTITY = 32,
	CF_UPDATE_FLAG_CLEAR_IN_SYNC = 64,
	CF_UPDATE_FLAG_REMOVE_PROPERTY = 128,
	CF_UPDATE_FLAG_PASSTHROUGH_FS_METADATA = 256,
	CF_UPDATE_FLAG_ALWAYS_FULL = 512,
	CF_UPDATE_FLAG_ALLOW_PARTIAL = 1024,
}


[AllowDuplicates]
public enum CF_REVERT_FLAGS : uint32
{
	CF_REVERT_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_HYDRATE_FLAGS : uint32
{
	CF_HYDRATE_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_DEHYDRATE_FLAGS : uint32
{
	CF_DEHYDRATE_FLAG_NONE = 0,
	CF_DEHYDRATE_FLAG_BACKGROUND = 1,
}


[AllowDuplicates]
public enum CF_PIN_STATE : int32
{
	CF_PIN_STATE_UNSPECIFIED = 0,
	CF_PIN_STATE_PINNED = 1,
	CF_PIN_STATE_UNPINNED = 2,
	CF_PIN_STATE_EXCLUDED = 3,
	CF_PIN_STATE_INHERIT = 4,
}


[AllowDuplicates]
public enum CF_SET_PIN_FLAGS : uint32
{
	CF_SET_PIN_FLAG_NONE = 0,
	CF_SET_PIN_FLAG_RECURSE = 1,
	CF_SET_PIN_FLAG_RECURSE_ONLY = 2,
	CF_SET_PIN_FLAG_RECURSE_STOP_ON_ERROR = 4,
}


[AllowDuplicates]
public enum CF_IN_SYNC_STATE : int32
{
	CF_IN_SYNC_STATE_NOT_IN_SYNC = 0,
	CF_IN_SYNC_STATE_IN_SYNC = 1,
}


[AllowDuplicates]
public enum CF_SET_IN_SYNC_FLAGS : uint32
{
	CF_SET_IN_SYNC_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum CF_PLACEHOLDER_STATE : uint32
{
	CF_PLACEHOLDER_STATE_NO_STATES = 0,
	CF_PLACEHOLDER_STATE_PLACEHOLDER = 1,
	CF_PLACEHOLDER_STATE_SYNC_ROOT = 2,
	CF_PLACEHOLDER_STATE_ESSENTIAL_PROP_PRESENT = 4,
	CF_PLACEHOLDER_STATE_IN_SYNC = 8,
	CF_PLACEHOLDER_STATE_PARTIAL = 16,
	CF_PLACEHOLDER_STATE_PARTIALLY_ON_DISK = 32,
	CF_PLACEHOLDER_STATE_INVALID = 4294967295,
}


[AllowDuplicates]
public enum CF_PLACEHOLDER_INFO_CLASS : int32
{
	CF_PLACEHOLDER_INFO_BASIC = 0,
	CF_PLACEHOLDER_INFO_STANDARD = 1,
}


[AllowDuplicates]
public enum CF_SYNC_ROOT_INFO_CLASS : int32
{
	CF_SYNC_ROOT_INFO_BASIC = 0,
	CF_SYNC_ROOT_INFO_STANDARD = 1,
	CF_SYNC_ROOT_INFO_PROVIDER = 2,
}


[AllowDuplicates]
public enum CF_PLACEHOLDER_RANGE_INFO_CLASS : int32
{
	CF_PLACEHOLDER_RANGE_INFO_ONDISK = 1,
	CF_PLACEHOLDER_RANGE_INFO_VALIDATED = 2,
	CF_PLACEHOLDER_RANGE_INFO_MODIFIED = 3,
}

#endregion

#region Function Pointers
public function void CF_CALLBACK(CF_CALLBACK_INFO* CallbackInfo, CF_CALLBACK_PARAMETERS* CallbackParameters);

#endregion

#region Structs
[CRepr]
public struct CF_FS_METADATA
{
	public FILE_BASIC_INFO BasicInfo;
	public LARGE_INTEGER FileSize;
}

[CRepr]
public struct CF_PLACEHOLDER_CREATE_INFO
{
	public PWSTR RelativeFileName;
	public CF_FS_METADATA FsMetadata;
	public void* FileIdentity;
	public uint32 FileIdentityLength;
	public CF_PLACEHOLDER_CREATE_FLAGS Flags;
	public HRESULT Result;
	public int64 CreateUsn;
}

[CRepr]
public struct CF_PROCESS_INFO
{
	public uint32 StructSize;
	public uint32 ProcessId;
	public PWSTR ImagePath;
	public PWSTR PackageName;
	public PWSTR ApplicationId;
	public PWSTR CommandLine;
	public uint32 SessionId;
}

[CRepr]
public struct CF_PLATFORM_INFO
{
	public uint32 BuildNumber;
	public uint32 RevisionNumber;
	public uint32 IntegrationNumber;
}

[CRepr]
public struct CF_HYDRATION_POLICY_PRIMARY_USHORT
{
	public uint16 us;
}

[CRepr]
public struct CF_HYDRATION_POLICY_MODIFIER_USHORT
{
	public uint16 us;
}

[CRepr]
public struct CF_HYDRATION_POLICY
{
	public CF_HYDRATION_POLICY_PRIMARY_USHORT Primary;
	public CF_HYDRATION_POLICY_MODIFIER_USHORT Modifier;
}

[CRepr]
public struct CF_POPULATION_POLICY_PRIMARY_USHORT
{
	public uint16 us;
}

[CRepr]
public struct CF_POPULATION_POLICY_MODIFIER_USHORT
{
	public uint16 us;
}

[CRepr]
public struct CF_POPULATION_POLICY
{
	public CF_POPULATION_POLICY_PRIMARY_USHORT Primary;
	public CF_POPULATION_POLICY_MODIFIER_USHORT Modifier;
}

[CRepr]
public struct CF_SYNC_POLICIES
{
	public uint32 StructSize;
	public CF_HYDRATION_POLICY Hydration;
	public CF_POPULATION_POLICY Population;
	public CF_INSYNC_POLICY InSync;
	public CF_HARDLINK_POLICY HardLink;
	public CF_PLACEHOLDER_MANAGEMENT_POLICY PlaceholderManagement;
}

[CRepr]
public struct CF_SYNC_REGISTRATION
{
	public uint32 StructSize;
	public PWSTR ProviderName;
	public PWSTR ProviderVersion;
	public void* SyncRootIdentity;
	public uint32 SyncRootIdentityLength;
	public void* FileIdentity;
	public uint32 FileIdentityLength;
	public Guid ProviderId;
}

[CRepr]
public struct CF_CALLBACK_INFO
{
	public uint32 StructSize;
	public CF_CONNECTION_KEY ConnectionKey;
	public void* CallbackContext;
	public PWSTR VolumeGuidName;
	public PWSTR VolumeDosName;
	public uint32 VolumeSerialNumber;
	public LARGE_INTEGER SyncRootFileId;
	public void* SyncRootIdentity;
	public uint32 SyncRootIdentityLength;
	public LARGE_INTEGER FileId;
	public LARGE_INTEGER FileSize;
	public void* FileIdentity;
	public uint32 FileIdentityLength;
	public PWSTR NormalizedPath;
	public LARGE_INTEGER TransferKey;
	public uint8 PriorityHint;
	public CORRELATION_VECTOR* CorrelationVector;
	public CF_PROCESS_INFO* ProcessInfo;
	public LARGE_INTEGER RequestKey;
}

[CRepr]
public struct CF_CALLBACK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Rename_e__Struct
		{
			public CF_CALLBACK_RENAME_FLAGS Flags;
			public PWSTR TargetPath;
		}
		[CRepr]
		public struct _Delete_e__Struct
		{
			public CF_CALLBACK_DELETE_FLAGS Flags;
		}
		[CRepr]
		public struct _Dehydrate_e__Struct
		{
			public CF_CALLBACK_DEHYDRATE_FLAGS Flags;
			public CF_CALLBACK_DEHYDRATION_REASON Reason;
		}
		[CRepr]
		public struct _OpenCompletion_e__Struct
		{
			public CF_CALLBACK_OPEN_COMPLETION_FLAGS Flags;
		}
		[CRepr]
		public struct _ValidateData_e__Struct
		{
			public CF_CALLBACK_VALIDATE_DATA_FLAGS Flags;
			public LARGE_INTEGER RequiredFileOffset;
			public LARGE_INTEGER RequiredLength;
		}
		[CRepr]
		public struct _Cancel_e__Struct
		{
			[CRepr, Union]
			public struct _Anonymous_e__Union
			{
				[CRepr]
				public struct _FetchData_e__Struct
				{
					public LARGE_INTEGER FileOffset;
					public LARGE_INTEGER Length;
				}
				public _FetchData_e__Struct FetchData;
			}
			public CF_CALLBACK_CANCEL_FLAGS Flags;
			public using _Anonymous_e__Union Anonymous;
		}
		[CRepr]
		public struct _RenameCompletion_e__Struct
		{
			public CF_CALLBACK_RENAME_COMPLETION_FLAGS Flags;
			public PWSTR SourcePath;
		}
		[CRepr]
		public struct _DehydrateCompletion_e__Struct
		{
			public CF_CALLBACK_DEHYDRATE_COMPLETION_FLAGS Flags;
			public CF_CALLBACK_DEHYDRATION_REASON Reason;
		}
		[CRepr]
		public struct _FetchPlaceholders_e__Struct
		{
			public CF_CALLBACK_FETCH_PLACEHOLDERS_FLAGS Flags;
			public PWSTR Pattern;
		}
		[CRepr]
		public struct _CloseCompletion_e__Struct
		{
			public CF_CALLBACK_CLOSE_COMPLETION_FLAGS Flags;
		}
		[CRepr]
		public struct _DeleteCompletion_e__Struct
		{
			public CF_CALLBACK_DELETE_COMPLETION_FLAGS Flags;
		}
		[CRepr]
		public struct _FetchData_e__Struct
		{
			public CF_CALLBACK_FETCH_DATA_FLAGS Flags;
			public LARGE_INTEGER RequiredFileOffset;
			public LARGE_INTEGER RequiredLength;
			public LARGE_INTEGER OptionalFileOffset;
			public LARGE_INTEGER OptionalLength;
			public LARGE_INTEGER LastDehydrationTime;
			public CF_CALLBACK_DEHYDRATION_REASON LastDehydrationReason;
		}
		public _Cancel_e__Struct Cancel;
		public _FetchData_e__Struct FetchData;
		public _ValidateData_e__Struct ValidateData;
		public _FetchPlaceholders_e__Struct FetchPlaceholders;
		public _OpenCompletion_e__Struct OpenCompletion;
		public _CloseCompletion_e__Struct CloseCompletion;
		public _Dehydrate_e__Struct Dehydrate;
		public _DehydrateCompletion_e__Struct DehydrateCompletion;
		public _Delete_e__Struct Delete;
		public _DeleteCompletion_e__Struct DeleteCompletion;
		public _Rename_e__Struct Rename;
		public _RenameCompletion_e__Struct RenameCompletion;
	}
	public uint32 ParamSize;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CF_CALLBACK_REGISTRATION
{
	public CF_CALLBACK_TYPE Type;
	public CF_CALLBACK Callback;
}

[CRepr]
public struct CF_SYNC_STATUS
{
	public uint32 StructSize;
	public uint32 Code;
	public uint32 DescriptionOffset;
	public uint32 DescriptionLength;
	public uint32 DeviceIdOffset;
	public uint32 DeviceIdLength;
}

[CRepr]
public struct CF_OPERATION_INFO
{
	public uint32 StructSize;
	public CF_OPERATION_TYPE Type;
	public CF_CONNECTION_KEY ConnectionKey;
	public LARGE_INTEGER TransferKey;
	public CORRELATION_VECTOR* CorrelationVector;
	public CF_SYNC_STATUS* SyncStatus;
	public LARGE_INTEGER RequestKey;
}

[CRepr]
public struct CF_OPERATION_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _AckRename_e__Struct
		{
			public CF_OPERATION_ACK_RENAME_FLAGS Flags;
			public NTSTATUS CompletionStatus;
		}
		[CRepr]
		public struct _TransferPlaceholders_e__Struct
		{
			public CF_OPERATION_TRANSFER_PLACEHOLDERS_FLAGS Flags;
			public NTSTATUS CompletionStatus;
			public LARGE_INTEGER PlaceholderTotalCount;
			public CF_PLACEHOLDER_CREATE_INFO* PlaceholderArray;
			public uint32 PlaceholderCount;
			public uint32 EntriesProcessed;
		}
		[CRepr]
		public struct _AckData_e__Struct
		{
			public CF_OPERATION_ACK_DATA_FLAGS Flags;
			public NTSTATUS CompletionStatus;
			public LARGE_INTEGER Offset;
			public LARGE_INTEGER Length;
		}
		[CRepr]
		public struct _TransferData_e__Struct
		{
			public CF_OPERATION_TRANSFER_DATA_FLAGS Flags;
			public NTSTATUS CompletionStatus;
			public void* Buffer;
			public LARGE_INTEGER Offset;
			public LARGE_INTEGER Length;
		}
		[CRepr]
		public struct _AckDelete_e__Struct
		{
			public CF_OPERATION_ACK_DELETE_FLAGS Flags;
			public NTSTATUS CompletionStatus;
		}
		[CRepr]
		public struct _RestartHydration_e__Struct
		{
			public CF_OPERATION_RESTART_HYDRATION_FLAGS Flags;
			public CF_FS_METADATA* FsMetadata;
			public void* FileIdentity;
			public uint32 FileIdentityLength;
		}
		[CRepr]
		public struct _RetrieveData_e__Struct
		{
			public CF_OPERATION_RETRIEVE_DATA_FLAGS Flags;
			public void* Buffer;
			public LARGE_INTEGER Offset;
			public LARGE_INTEGER Length;
			public LARGE_INTEGER ReturnedLength;
		}
		[CRepr]
		public struct _AckDehydrate_e__Struct
		{
			public CF_OPERATION_ACK_DEHYDRATE_FLAGS Flags;
			public NTSTATUS CompletionStatus;
			public void* FileIdentity;
			public uint32 FileIdentityLength;
		}
		public _TransferData_e__Struct TransferData;
		public _RetrieveData_e__Struct RetrieveData;
		public _AckData_e__Struct AckData;
		public _RestartHydration_e__Struct RestartHydration;
		public _TransferPlaceholders_e__Struct TransferPlaceholders;
		public _AckDehydrate_e__Struct AckDehydrate;
		public _AckRename_e__Struct AckRename;
		public _AckDelete_e__Struct AckDelete;
	}
	public uint32 ParamSize;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CF_FILE_RANGE
{
	public LARGE_INTEGER StartingOffset;
	public LARGE_INTEGER Length;
}

[CRepr]
public struct CF_PLACEHOLDER_BASIC_INFO
{
	public CF_PIN_STATE PinState;
	public CF_IN_SYNC_STATE InSyncState;
	public LARGE_INTEGER FileId;
	public LARGE_INTEGER SyncRootFileId;
	public uint32 FileIdentityLength;
	public uint8* FileIdentity mut => &FileIdentity_impl;
	private uint8[ANYSIZE_ARRAY] FileIdentity_impl;
}

[CRepr]
public struct CF_PLACEHOLDER_STANDARD_INFO
{
	public LARGE_INTEGER OnDiskDataSize;
	public LARGE_INTEGER ValidatedDataSize;
	public LARGE_INTEGER ModifiedDataSize;
	public LARGE_INTEGER PropertiesSize;
	public CF_PIN_STATE PinState;
	public CF_IN_SYNC_STATE InSyncState;
	public LARGE_INTEGER FileId;
	public LARGE_INTEGER SyncRootFileId;
	public uint32 FileIdentityLength;
	public uint8* FileIdentity mut => &FileIdentity_impl;
	private uint8[ANYSIZE_ARRAY] FileIdentity_impl;
}

[CRepr]
public struct CF_SYNC_ROOT_BASIC_INFO
{
	public LARGE_INTEGER SyncRootFileId;
}

[CRepr]
public struct CF_SYNC_ROOT_PROVIDER_INFO
{
	public CF_SYNC_PROVIDER_STATUS ProviderStatus;
	public char16[256] ProviderName;
	public char16[256] ProviderVersion;
}

[CRepr]
public struct CF_SYNC_ROOT_STANDARD_INFO
{
	public LARGE_INTEGER SyncRootFileId;
	public CF_HYDRATION_POLICY HydrationPolicy;
	public CF_POPULATION_POLICY PopulationPolicy;
	public CF_INSYNC_POLICY InSyncPolicy;
	public CF_HARDLINK_POLICY HardLinkPolicy;
	public CF_SYNC_PROVIDER_STATUS ProviderStatus;
	public char16[256] ProviderName;
	public char16[256] ProviderVersion;
	public uint32 SyncRootIdentityLength;
	public uint8* SyncRootIdentity mut => &SyncRootIdentity_impl;
	private uint8[ANYSIZE_ARRAY] SyncRootIdentity_impl;
}

#endregion

#region Functions
public static
{
	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetPlatformInfo(CF_PLATFORM_INFO* PlatformVersion);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfRegisterSyncRoot(PWSTR SyncRootPath, CF_SYNC_REGISTRATION* Registration, CF_SYNC_POLICIES* Policies, CF_REGISTER_FLAGS RegisterFlags);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfUnregisterSyncRoot(PWSTR SyncRootPath);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfConnectSyncRoot(PWSTR SyncRootPath, CF_CALLBACK_REGISTRATION* CallbackTable, void* CallbackContext, CF_CONNECT_FLAGS ConnectFlags, CF_CONNECTION_KEY* ConnectionKey);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfDisconnectSyncRoot(CF_CONNECTION_KEY ConnectionKey);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetTransferKey(HANDLE FileHandle, LARGE_INTEGER* TransferKey);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CfReleaseTransferKey(HANDLE FileHandle, LARGE_INTEGER* TransferKey);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfExecute(CF_OPERATION_INFO* OpInfo, CF_OPERATION_PARAMETERS* OpParams);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfUpdateSyncProviderStatus(CF_CONNECTION_KEY ConnectionKey, CF_SYNC_PROVIDER_STATUS ProviderStatus);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfQuerySyncProviderStatus(CF_CONNECTION_KEY ConnectionKey, CF_SYNC_PROVIDER_STATUS* ProviderStatus);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfReportSyncStatus(PWSTR SyncRootPath, CF_SYNC_STATUS* SyncStatus);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfCreatePlaceholders(PWSTR BaseDirectoryPath, CF_PLACEHOLDER_CREATE_INFO* PlaceholderArray, uint32 PlaceholderCount, CF_CREATE_FLAGS CreateFlags, uint32* EntriesProcessed);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfOpenFileWithOplock(PWSTR FilePath, CF_OPEN_FILE_FLAGS Flags, HANDLE* ProtectedHandle);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN CfReferenceProtectedHandle(HANDLE ProtectedHandle);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CfGetWin32HandleFromProtectedHandle(HANDLE ProtectedHandle);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CfReleaseProtectedHandle(HANDLE ProtectedHandle);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CfCloseHandle(HANDLE FileHandle);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfConvertToPlaceholder(HANDLE FileHandle, void* FileIdentity, uint32 FileIdentityLength, CF_CONVERT_FLAGS ConvertFlags, int64* ConvertUsn, OVERLAPPED* Overlapped);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfUpdatePlaceholder(HANDLE FileHandle, CF_FS_METADATA* FsMetadata, void* FileIdentity, uint32 FileIdentityLength, CF_FILE_RANGE* DehydrateRangeArray, uint32 DehydrateRangeCount, CF_UPDATE_FLAGS UpdateFlags, int64* UpdateUsn, OVERLAPPED* Overlapped);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfRevertPlaceholder(HANDLE FileHandle, CF_REVERT_FLAGS RevertFlags, OVERLAPPED* Overlapped);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfHydratePlaceholder(HANDLE FileHandle, LARGE_INTEGER StartingOffset, LARGE_INTEGER Length, CF_HYDRATE_FLAGS HydrateFlags, OVERLAPPED* Overlapped);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfDehydratePlaceholder(HANDLE FileHandle, LARGE_INTEGER StartingOffset, LARGE_INTEGER Length, CF_DEHYDRATE_FLAGS DehydrateFlags, OVERLAPPED* Overlapped);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfSetPinState(HANDLE FileHandle, CF_PIN_STATE PinState, CF_SET_PIN_FLAGS PinFlags, OVERLAPPED* Overlapped);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfSetInSyncState(HANDLE FileHandle, CF_IN_SYNC_STATE InSyncState, CF_SET_IN_SYNC_FLAGS InSyncFlags, int64* InSyncUsn);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfSetCorrelationVector(HANDLE FileHandle, CORRELATION_VECTOR* CorrelationVector);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetCorrelationVector(HANDLE FileHandle, CORRELATION_VECTOR* CorrelationVector);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CF_PLACEHOLDER_STATE CfGetPlaceholderStateFromAttributeTag(uint32 FileAttributes, uint32 ReparseTag);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CF_PLACEHOLDER_STATE CfGetPlaceholderStateFromFileInfo(void* InfoBuffer, FILE_INFO_BY_HANDLE_CLASS InfoClass);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CF_PLACEHOLDER_STATE CfGetPlaceholderStateFromFindData(WIN32_FIND_DATAA* FindData);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetPlaceholderInfo(HANDLE FileHandle, CF_PLACEHOLDER_INFO_CLASS InfoClass, void* InfoBuffer, uint32 InfoBufferLength, uint32* ReturnedLength);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetSyncRootInfoByPath(PWSTR FilePath, CF_SYNC_ROOT_INFO_CLASS InfoClass, void* InfoBuffer, uint32 InfoBufferLength, uint32* ReturnedLength);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetSyncRootInfoByHandle(HANDLE FileHandle, CF_SYNC_ROOT_INFO_CLASS InfoClass, void* InfoBuffer, uint32 InfoBufferLength, uint32* ReturnedLength);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfGetPlaceholderRangeInfo(HANDLE FileHandle, CF_PLACEHOLDER_RANGE_INFO_CLASS InfoClass, LARGE_INTEGER StartingOffset, LARGE_INTEGER Length, void* InfoBuffer, uint32 InfoBufferLength, uint32* ReturnedLength);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfReportProviderProgress(CF_CONNECTION_KEY ConnectionKey, LARGE_INTEGER TransferKey, LARGE_INTEGER ProviderProgressTotal, LARGE_INTEGER ProviderProgressCompleted);

	[Import("cldapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CfReportProviderProgress2(CF_CONNECTION_KEY ConnectionKey, LARGE_INTEGER TransferKey, LARGE_INTEGER RequestKey, LARGE_INTEGER ProviderProgressTotal, LARGE_INTEGER ProviderProgressCompleted, uint32 TargetSessionId);

}
#endregion
