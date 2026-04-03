using Win32.Foundation;
using Win32.Security;
using Win32.System.IO;
using System;

namespace Win32.Storage.Vhd;

#region Constants
public static
{
	public const Guid VIRTUAL_STORAGE_TYPE_VENDOR_UNKNOWN = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT = .(0xec984aec, 0xa0f9, 0x47e9, 0x90, 0x1f, 0x71, 0x41, 0x5a, 0x66, 0x34, 0x5b);
	public const uint32 VIRTUAL_STORAGE_TYPE_DEVICE_UNKNOWN = 0;
	public const uint32 VIRTUAL_STORAGE_TYPE_DEVICE_ISO = 1;
	public const uint32 VIRTUAL_STORAGE_TYPE_DEVICE_VHD = 2;
	public const uint32 VIRTUAL_STORAGE_TYPE_DEVICE_VHDX = 3;
	public const uint32 VIRTUAL_STORAGE_TYPE_DEVICE_VHDSET = 4;
	public const uint32 OPEN_VIRTUAL_DISK_RW_DEPTH_DEFAULT = 1;
	public const uint32 CREATE_VIRTUAL_DISK_PARAMETERS_DEFAULT_BLOCK_SIZE = 0;
	public const uint32 CREATE_VIRTUAL_DISK_PARAMETERS_DEFAULT_SECTOR_SIZE = 0;
	public const uint32 VIRTUAL_DISK_MAXIMUM_CHANGE_TRACKING_ID_LENGTH = 256;
	public const uint32 MERGE_VIRTUAL_DISK_DEFAULT_MERGE_DEPTH = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum OPEN_VIRTUAL_DISK_VERSION : int32
{
	OPEN_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	OPEN_VIRTUAL_DISK_VERSION_1 = 1,
	OPEN_VIRTUAL_DISK_VERSION_2 = 2,
	OPEN_VIRTUAL_DISK_VERSION_3 = 3,
}


[AllowDuplicates]
public enum VIRTUAL_DISK_ACCESS_MASK : uint32
{
	VIRTUAL_DISK_ACCESS_NONE = 0,
	VIRTUAL_DISK_ACCESS_ATTACH_RO = 65536,
	VIRTUAL_DISK_ACCESS_ATTACH_RW = 131072,
	VIRTUAL_DISK_ACCESS_DETACH = 262144,
	VIRTUAL_DISK_ACCESS_GET_INFO = 524288,
	VIRTUAL_DISK_ACCESS_CREATE = 1048576,
	VIRTUAL_DISK_ACCESS_METAOPS = 2097152,
	VIRTUAL_DISK_ACCESS_READ = 851968,
	VIRTUAL_DISK_ACCESS_ALL = 4128768,
	VIRTUAL_DISK_ACCESS_WRITABLE = 3276800,
}


[AllowDuplicates]
public enum OPEN_VIRTUAL_DISK_FLAG : uint32
{
	OPEN_VIRTUAL_DISK_FLAG_NONE = 0,
	OPEN_VIRTUAL_DISK_FLAG_NO_PARENTS = 1,
	OPEN_VIRTUAL_DISK_FLAG_BLANK_FILE = 2,
	OPEN_VIRTUAL_DISK_FLAG_BOOT_DRIVE = 4,
	OPEN_VIRTUAL_DISK_FLAG_CACHED_IO = 8,
	OPEN_VIRTUAL_DISK_FLAG_CUSTOM_DIFF_CHAIN = 16,
	OPEN_VIRTUAL_DISK_FLAG_PARENT_CACHED_IO = 32,
	OPEN_VIRTUAL_DISK_FLAG_VHDSET_FILE_ONLY = 64,
	OPEN_VIRTUAL_DISK_FLAG_IGNORE_RELATIVE_PARENT_LOCATOR = 128,
	OPEN_VIRTUAL_DISK_FLAG_NO_WRITE_HARDENING = 256,
	OPEN_VIRTUAL_DISK_FLAG_SUPPORT_COMPRESSED_VOLUMES = 512,
	OPEN_VIRTUAL_DISK_FLAG_SUPPORT_SPARSE_FILES_ANY_FS = 1024,
	OPEN_VIRTUAL_DISK_FLAG_SUPPORT_ENCRYPTED_FILES = 2048,
}


[AllowDuplicates]
public enum CREATE_VIRTUAL_DISK_VERSION : int32
{
	CREATE_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	CREATE_VIRTUAL_DISK_VERSION_1 = 1,
	CREATE_VIRTUAL_DISK_VERSION_2 = 2,
	CREATE_VIRTUAL_DISK_VERSION_3 = 3,
	CREATE_VIRTUAL_DISK_VERSION_4 = 4,
}


[AllowDuplicates]
public enum CREATE_VIRTUAL_DISK_FLAG : uint32
{
	CREATE_VIRTUAL_DISK_FLAG_NONE = 0,
	CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION = 1,
	CREATE_VIRTUAL_DISK_FLAG_PREVENT_WRITES_TO_SOURCE_DISK = 2,
	CREATE_VIRTUAL_DISK_FLAG_DO_NOT_COPY_METADATA_FROM_PARENT = 4,
	CREATE_VIRTUAL_DISK_FLAG_CREATE_BACKING_STORAGE = 8,
	CREATE_VIRTUAL_DISK_FLAG_USE_CHANGE_TRACKING_SOURCE_LIMIT = 16,
	CREATE_VIRTUAL_DISK_FLAG_PRESERVE_PARENT_CHANGE_TRACKING_STATE = 32,
	CREATE_VIRTUAL_DISK_FLAG_VHD_SET_USE_ORIGINAL_BACKING_STORAGE = 64,
	CREATE_VIRTUAL_DISK_FLAG_SPARSE_FILE = 128,
	CREATE_VIRTUAL_DISK_FLAG_PMEM_COMPATIBLE = 256,
	CREATE_VIRTUAL_DISK_FLAG_SUPPORT_COMPRESSED_VOLUMES = 512,
	CREATE_VIRTUAL_DISK_FLAG_SUPPORT_SPARSE_FILES_ANY_FS = 1024,
}


[AllowDuplicates]
public enum ATTACH_VIRTUAL_DISK_VERSION : int32
{
	ATTACH_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	ATTACH_VIRTUAL_DISK_VERSION_1 = 1,
	ATTACH_VIRTUAL_DISK_VERSION_2 = 2,
}


[AllowDuplicates]
public enum ATTACH_VIRTUAL_DISK_FLAG : uint32
{
	ATTACH_VIRTUAL_DISK_FLAG_NONE = 0,
	ATTACH_VIRTUAL_DISK_FLAG_READ_ONLY = 1,
	ATTACH_VIRTUAL_DISK_FLAG_NO_DRIVE_LETTER = 2,
	ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME = 4,
	ATTACH_VIRTUAL_DISK_FLAG_NO_LOCAL_HOST = 8,
	ATTACH_VIRTUAL_DISK_FLAG_NO_SECURITY_DESCRIPTOR = 16,
	ATTACH_VIRTUAL_DISK_FLAG_BYPASS_DEFAULT_ENCRYPTION_POLICY = 32,
	ATTACH_VIRTUAL_DISK_FLAG_NON_PNP = 64,
	ATTACH_VIRTUAL_DISK_FLAG_RESTRICTED_RANGE = 128,
	ATTACH_VIRTUAL_DISK_FLAG_SINGLE_PARTITION = 256,
	ATTACH_VIRTUAL_DISK_FLAG_REGISTER_VOLUME = 512,
}


[AllowDuplicates]
public enum DETACH_VIRTUAL_DISK_FLAG : uint32
{
	DETACH_VIRTUAL_DISK_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum DEPENDENT_DISK_FLAG : uint32
{
	DEPENDENT_DISK_FLAG_NONE = 0,
	DEPENDENT_DISK_FLAG_MULT_BACKING_FILES = 1,
	DEPENDENT_DISK_FLAG_FULLY_ALLOCATED = 2,
	DEPENDENT_DISK_FLAG_READ_ONLY = 4,
	DEPENDENT_DISK_FLAG_REMOTE = 8,
	DEPENDENT_DISK_FLAG_SYSTEM_VOLUME = 16,
	DEPENDENT_DISK_FLAG_SYSTEM_VOLUME_PARENT = 32,
	DEPENDENT_DISK_FLAG_REMOVABLE = 64,
	DEPENDENT_DISK_FLAG_NO_DRIVE_LETTER = 128,
	DEPENDENT_DISK_FLAG_PARENT = 256,
	DEPENDENT_DISK_FLAG_NO_HOST_DISK = 512,
	DEPENDENT_DISK_FLAG_PERMANENT_LIFETIME = 1024,
	DEPENDENT_DISK_FLAG_SUPPORT_COMPRESSED_VOLUMES = 2048,
	DEPENDENT_DISK_FLAG_ALWAYS_ALLOW_SPARSE = 4096,
	DEPENDENT_DISK_FLAG_SUPPORT_ENCRYPTED_FILES = 8192,
}


[AllowDuplicates]
public enum STORAGE_DEPENDENCY_INFO_VERSION : int32
{
	STORAGE_DEPENDENCY_INFO_VERSION_UNSPECIFIED = 0,
	STORAGE_DEPENDENCY_INFO_VERSION_1 = 1,
	STORAGE_DEPENDENCY_INFO_VERSION_2 = 2,
}


[AllowDuplicates]
public enum GET_STORAGE_DEPENDENCY_FLAG : uint32
{
	GET_STORAGE_DEPENDENCY_FLAG_NONE = 0,
	GET_STORAGE_DEPENDENCY_FLAG_HOST_VOLUMES = 1,
	GET_STORAGE_DEPENDENCY_FLAG_DISK_HANDLE = 2,
}


[AllowDuplicates]
public enum GET_VIRTUAL_DISK_INFO_VERSION : int32
{
	GET_VIRTUAL_DISK_INFO_UNSPECIFIED = 0,
	GET_VIRTUAL_DISK_INFO_SIZE = 1,
	GET_VIRTUAL_DISK_INFO_IDENTIFIER = 2,
	GET_VIRTUAL_DISK_INFO_PARENT_LOCATION = 3,
	GET_VIRTUAL_DISK_INFO_PARENT_IDENTIFIER = 4,
	GET_VIRTUAL_DISK_INFO_PARENT_TIMESTAMP = 5,
	GET_VIRTUAL_DISK_INFO_VIRTUAL_STORAGE_TYPE = 6,
	GET_VIRTUAL_DISK_INFO_PROVIDER_SUBTYPE = 7,
	GET_VIRTUAL_DISK_INFO_IS_4K_ALIGNED = 8,
	GET_VIRTUAL_DISK_INFO_PHYSICAL_DISK = 9,
	GET_VIRTUAL_DISK_INFO_VHD_PHYSICAL_SECTOR_SIZE = 10,
	GET_VIRTUAL_DISK_INFO_SMALLEST_SAFE_VIRTUAL_SIZE = 11,
	GET_VIRTUAL_DISK_INFO_FRAGMENTATION = 12,
	GET_VIRTUAL_DISK_INFO_IS_LOADED = 13,
	GET_VIRTUAL_DISK_INFO_VIRTUAL_DISK_ID = 14,
	GET_VIRTUAL_DISK_INFO_CHANGE_TRACKING_STATE = 15,
}


[AllowDuplicates]
public enum SET_VIRTUAL_DISK_INFO_VERSION : int32
{
	SET_VIRTUAL_DISK_INFO_UNSPECIFIED = 0,
	SET_VIRTUAL_DISK_INFO_PARENT_PATH = 1,
	SET_VIRTUAL_DISK_INFO_IDENTIFIER = 2,
	SET_VIRTUAL_DISK_INFO_PARENT_PATH_WITH_DEPTH = 3,
	SET_VIRTUAL_DISK_INFO_PHYSICAL_SECTOR_SIZE = 4,
	SET_VIRTUAL_DISK_INFO_VIRTUAL_DISK_ID = 5,
	SET_VIRTUAL_DISK_INFO_CHANGE_TRACKING_STATE = 6,
	SET_VIRTUAL_DISK_INFO_PARENT_LOCATOR = 7,
}


[AllowDuplicates]
public enum COMPACT_VIRTUAL_DISK_VERSION : int32
{
	COMPACT_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	COMPACT_VIRTUAL_DISK_VERSION_1 = 1,
}


[AllowDuplicates]
public enum COMPACT_VIRTUAL_DISK_FLAG : uint32
{
	COMPACT_VIRTUAL_DISK_FLAG_NONE = 0,
	COMPACT_VIRTUAL_DISK_FLAG_NO_ZERO_SCAN = 1,
	COMPACT_VIRTUAL_DISK_FLAG_NO_BLOCK_MOVES = 2,
}


[AllowDuplicates]
public enum MERGE_VIRTUAL_DISK_VERSION : int32
{
	MERGE_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	MERGE_VIRTUAL_DISK_VERSION_1 = 1,
	MERGE_VIRTUAL_DISK_VERSION_2 = 2,
}


[AllowDuplicates]
public enum MERGE_VIRTUAL_DISK_FLAG : uint32
{
	MERGE_VIRTUAL_DISK_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum EXPAND_VIRTUAL_DISK_VERSION : int32
{
	EXPAND_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	EXPAND_VIRTUAL_DISK_VERSION_1 = 1,
}


[AllowDuplicates]
public enum EXPAND_VIRTUAL_DISK_FLAG : uint32
{
	EXPAND_VIRTUAL_DISK_FLAG_NONE = 0,
	EXPAND_VIRTUAL_DISK_FLAG_NOTIFY_CHANGE = 1,
}


[AllowDuplicates]
public enum RESIZE_VIRTUAL_DISK_VERSION : int32
{
	RESIZE_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	RESIZE_VIRTUAL_DISK_VERSION_1 = 1,
}


[AllowDuplicates]
public enum RESIZE_VIRTUAL_DISK_FLAG : uint32
{
	RESIZE_VIRTUAL_DISK_FLAG_NONE = 0,
	RESIZE_VIRTUAL_DISK_FLAG_ALLOW_UNSAFE_VIRTUAL_SIZE = 1,
	RESIZE_VIRTUAL_DISK_FLAG_RESIZE_TO_SMALLEST_SAFE_VIRTUAL_SIZE = 2,
}


[AllowDuplicates]
public enum MIRROR_VIRTUAL_DISK_VERSION : int32
{
	MIRROR_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	MIRROR_VIRTUAL_DISK_VERSION_1 = 1,
}


[AllowDuplicates]
public enum MIRROR_VIRTUAL_DISK_FLAG : uint32
{
	MIRROR_VIRTUAL_DISK_FLAG_NONE = 0,
	MIRROR_VIRTUAL_DISK_FLAG_EXISTING_FILE = 1,
	MIRROR_VIRTUAL_DISK_FLAG_SKIP_MIRROR_ACTIVATION = 2,
	MIRROR_VIRTUAL_DISK_FLAG_ENABLE_SMB_COMPRESSION = 4,
	MIRROR_VIRTUAL_DISK_FLAG_IS_LIVE_MIGRATION = 8,
}


[AllowDuplicates]
public enum QUERY_CHANGES_VIRTUAL_DISK_FLAG : uint32
{
	QUERY_CHANGES_VIRTUAL_DISK_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum TAKE_SNAPSHOT_VHDSET_FLAG : uint32
{
	TAKE_SNAPSHOT_VHDSET_FLAG_NONE = 0,
	TAKE_SNAPSHOT_VHDSET_FLAG_WRITEABLE = 1,
}


[AllowDuplicates]
public enum TAKE_SNAPSHOT_VHDSET_VERSION : int32
{
	TAKE_SNAPSHOT_VHDSET_VERSION_UNSPECIFIED = 0,
	TAKE_SNAPSHOT_VHDSET_VERSION_1 = 1,
}


[AllowDuplicates]
public enum DELETE_SNAPSHOT_VHDSET_FLAG : uint32
{
	DELETE_SNAPSHOT_VHDSET_FLAG_NONE = 0,
	DELETE_SNAPSHOT_VHDSET_FLAG_PERSIST_RCT = 1,
}


[AllowDuplicates]
public enum DELETE_SNAPSHOT_VHDSET_VERSION : int32
{
	DELETE_SNAPSHOT_VHDSET_VERSION_UNSPECIFIED = 0,
	DELETE_SNAPSHOT_VHDSET_VERSION_1 = 1,
}


[AllowDuplicates]
public enum MODIFY_VHDSET_VERSION : int32
{
	MODIFY_VHDSET_UNSPECIFIED = 0,
	MODIFY_VHDSET_SNAPSHOT_PATH = 1,
	MODIFY_VHDSET_REMOVE_SNAPSHOT = 2,
	MODIFY_VHDSET_DEFAULT_SNAPSHOT_PATH = 3,
}


[AllowDuplicates]
public enum MODIFY_VHDSET_FLAG : uint32
{
	MODIFY_VHDSET_FLAG_NONE = 0,
	MODIFY_VHDSET_FLAG_WRITEABLE_SNAPSHOT = 1,
}


[AllowDuplicates]
public enum APPLY_SNAPSHOT_VHDSET_FLAG : uint32
{
	APPLY_SNAPSHOT_VHDSET_FLAG_NONE = 0,
	APPLY_SNAPSHOT_VHDSET_FLAG_WRITEABLE = 1,
}


[AllowDuplicates]
public enum APPLY_SNAPSHOT_VHDSET_VERSION : int32
{
	APPLY_SNAPSHOT_VHDSET_VERSION_UNSPECIFIED = 0,
	APPLY_SNAPSHOT_VHDSET_VERSION_1 = 1,
}


[AllowDuplicates]
public enum RAW_SCSI_VIRTUAL_DISK_FLAG : uint32
{
	RAW_SCSI_VIRTUAL_DISK_FLAG_NONE = 0,
}


[AllowDuplicates]
public enum RAW_SCSI_VIRTUAL_DISK_VERSION : int32
{
	RAW_SCSI_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	RAW_SCSI_VIRTUAL_DISK_VERSION_1 = 1,
}


[AllowDuplicates]
public enum FORK_VIRTUAL_DISK_VERSION : int32
{
	FORK_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
	FORK_VIRTUAL_DISK_VERSION_1 = 1,
}


[AllowDuplicates]
public enum FORK_VIRTUAL_DISK_FLAG : uint32
{
	FORK_VIRTUAL_DISK_FLAG_NONE = 0,
	FORK_VIRTUAL_DISK_FLAG_EXISTING_FILE = 1,
}

#endregion


#region Structs
[CRepr]
public struct VIRTUAL_STORAGE_TYPE
{
	public uint32 DeviceId;
	public Guid VendorId;
}

[CRepr]
public struct OPEN_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version3_e__Struct
		{
			public BOOL GetInfoOnly;
			public BOOL ReadOnly;
			public Guid ResiliencyGuid;
			public Guid SnapshotId;
		}
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint32 RWDepth;
		}
		[CRepr]
		public struct _Version2_e__Struct
		{
			public BOOL GetInfoOnly;
			public BOOL ReadOnly;
			public Guid ResiliencyGuid;
		}
		public _Version1_e__Struct Version1;
		public _Version2_e__Struct Version2;
		public _Version3_e__Struct Version3;
	}
	public OPEN_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CREATE_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version4_e__Struct
		{
			public Guid UniqueId;
			public uint64 MaximumSize;
			public uint32 BlockSizeInBytes;
			public uint32 SectorSizeInBytes;
			public uint32 PhysicalSectorSizeInBytes;
			public PWSTR ParentPath;
			public PWSTR SourcePath;
			public OPEN_VIRTUAL_DISK_FLAG OpenFlags;
			public VIRTUAL_STORAGE_TYPE ParentVirtualStorageType;
			public VIRTUAL_STORAGE_TYPE SourceVirtualStorageType;
			public Guid ResiliencyGuid;
			public PWSTR SourceLimitPath;
			public VIRTUAL_STORAGE_TYPE BackingStorageType;
			public Guid PmemAddressAbstractionType;
			public uint64 DataAlignment;
		}
		[CRepr]
		public struct _Version2_e__Struct
		{
			public Guid UniqueId;
			public uint64 MaximumSize;
			public uint32 BlockSizeInBytes;
			public uint32 SectorSizeInBytes;
			public uint32 PhysicalSectorSizeInBytes;
			public PWSTR ParentPath;
			public PWSTR SourcePath;
			public OPEN_VIRTUAL_DISK_FLAG OpenFlags;
			public VIRTUAL_STORAGE_TYPE ParentVirtualStorageType;
			public VIRTUAL_STORAGE_TYPE SourceVirtualStorageType;
			public Guid ResiliencyGuid;
		}
		[CRepr]
		public struct _Version3_e__Struct
		{
			public Guid UniqueId;
			public uint64 MaximumSize;
			public uint32 BlockSizeInBytes;
			public uint32 SectorSizeInBytes;
			public uint32 PhysicalSectorSizeInBytes;
			public PWSTR ParentPath;
			public PWSTR SourcePath;
			public OPEN_VIRTUAL_DISK_FLAG OpenFlags;
			public VIRTUAL_STORAGE_TYPE ParentVirtualStorageType;
			public VIRTUAL_STORAGE_TYPE SourceVirtualStorageType;
			public Guid ResiliencyGuid;
			public PWSTR SourceLimitPath;
			public VIRTUAL_STORAGE_TYPE BackingStorageType;
		}
		[CRepr]
		public struct _Version1_e__Struct
		{
			public Guid UniqueId;
			public uint64 MaximumSize;
			public uint32 BlockSizeInBytes;
			public uint32 SectorSizeInBytes;
			public PWSTR ParentPath;
			public PWSTR SourcePath;
		}
		public _Version1_e__Struct Version1;
		public _Version2_e__Struct Version2;
		public _Version3_e__Struct Version3;
		public _Version4_e__Struct Version4;
	}
	public CREATE_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct ATTACH_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version2_e__Struct
		{
			public uint64 RestrictedOffset;
			public uint64 RestrictedLength;
		}
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint32 Reserved;
		}
		public _Version1_e__Struct Version1;
		public _Version2_e__Struct Version2;
	}
	public ATTACH_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct STORAGE_DEPENDENCY_INFO_TYPE_1
{
	public DEPENDENT_DISK_FLAG DependencyTypeFlags;
	public uint32 ProviderSpecificFlags;
	public VIRTUAL_STORAGE_TYPE VirtualStorageType;
}

[CRepr]
public struct STORAGE_DEPENDENCY_INFO_TYPE_2
{
	public DEPENDENT_DISK_FLAG DependencyTypeFlags;
	public uint32 ProviderSpecificFlags;
	public VIRTUAL_STORAGE_TYPE VirtualStorageType;
	public uint32 AncestorLevel;
	public PWSTR DependencyDeviceName;
	public PWSTR HostVolumeName;
	public PWSTR DependentVolumeName;
	public PWSTR DependentVolumeRelativePath;
}

[CRepr]
public struct STORAGE_DEPENDENCY_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public STORAGE_DEPENDENCY_INFO_TYPE_1* Version1Entries mut => &Version1Entries_impl;
		private STORAGE_DEPENDENCY_INFO_TYPE_1[ANYSIZE_ARRAY] Version1Entries_impl;
		public STORAGE_DEPENDENCY_INFO_TYPE_2* Version2Entries mut => &Version2Entries_impl;
		private STORAGE_DEPENDENCY_INFO_TYPE_2[ANYSIZE_ARRAY] Version2Entries_impl;
	}
	public STORAGE_DEPENDENCY_INFO_VERSION Version;
	public uint32 NumberEntries;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GET_VIRTUAL_DISK_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _PhysicalDisk_e__Struct
		{
			public uint32 LogicalSectorSize;
			public uint32 PhysicalSectorSize;
			public BOOL IsRemote;
		}
		[CRepr]
		public struct _Size_e__Struct
		{
			public uint64 VirtualSize;
			public uint64 PhysicalSize;
			public uint32 BlockSize;
			public uint32 SectorSize;
		}
		[CRepr]
		public struct _ChangeTrackingState_e__Struct
		{
			public BOOL Enabled;
			public BOOL NewerChanges;
			public char16* MostRecentId mut => &MostRecentId_impl;
			private char16[ANYSIZE_ARRAY] MostRecentId_impl;
		}
		[CRepr]
		public struct _ParentLocation_e__Struct
		{
			public BOOL ParentResolved;
			public char16* ParentLocationBuffer mut => &ParentLocationBuffer_impl;
			private char16[ANYSIZE_ARRAY] ParentLocationBuffer_impl;
		}
		public _Size_e__Struct Size;
		public Guid Identifier;
		public _ParentLocation_e__Struct ParentLocation;
		public Guid ParentIdentifier;
		public uint32 ParentTimestamp;
		public VIRTUAL_STORAGE_TYPE VirtualStorageType;
		public uint32 ProviderSubtype;
		public BOOL Is4kAligned;
		public BOOL IsLoaded;
		public _PhysicalDisk_e__Struct PhysicalDisk;
		public uint32 VhdPhysicalSectorSize;
		public uint64 SmallestSafeVirtualSize;
		public uint32 FragmentationPercentage;
		public Guid VirtualDiskId;
		public _ChangeTrackingState_e__Struct ChangeTrackingState;
	}
	public GET_VIRTUAL_DISK_INFO_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SET_VIRTUAL_DISK_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _ParentPathWithDepthInfo_e__Struct
		{
			public uint32 ChildDepth;
			public PWSTR ParentFilePath;
		}
		[CRepr]
		public struct _ParentLocator_e__Struct
		{
			public Guid LinkageId;
			public PWSTR ParentFilePath;
		}
		public PWSTR ParentFilePath;
		public Guid UniqueIdentifier;
		public _ParentPathWithDepthInfo_e__Struct ParentPathWithDepthInfo;
		public uint32 VhdPhysicalSectorSize;
		public Guid VirtualDiskId;
		public BOOL ChangeTrackingEnabled;
		public _ParentLocator_e__Struct ParentLocator;
	}
	public SET_VIRTUAL_DISK_INFO_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct VIRTUAL_DISK_PROGRESS
{
	public uint32 OperationStatus;
	public uint64 CurrentValue;
	public uint64 CompletionValue;
}

[CRepr]
public struct COMPACT_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint32 Reserved;
		}
		public _Version1_e__Struct Version1;
	}
	public COMPACT_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MERGE_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version2_e__Struct
		{
			public uint32 MergeSourceDepth;
			public uint32 MergeTargetDepth;
		}
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint32 MergeDepth;
		}
		public _Version1_e__Struct Version1;
		public _Version2_e__Struct Version2;
	}
	public MERGE_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct EXPAND_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint64 NewSize;
		}
		public _Version1_e__Struct Version1;
	}
	public EXPAND_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RESIZE_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint64 NewSize;
		}
		public _Version1_e__Struct Version1;
	}
	public RESIZE_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MIRROR_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public PWSTR MirrorVirtualDiskPath;
		}
		public _Version1_e__Struct Version1;
	}
	public MIRROR_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct QUERY_CHANGES_VIRTUAL_DISK_RANGE
{
	public uint64 ByteOffset;
	public uint64 ByteLength;
	public uint64 Reserved;
}

[CRepr]
public struct TAKE_SNAPSHOT_VHDSET_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public Guid SnapshotId;
		}
		public _Version1_e__Struct Version1;
	}
	public TAKE_SNAPSHOT_VHDSET_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DELETE_SNAPSHOT_VHDSET_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public Guid SnapshotId;
		}
		public _Version1_e__Struct Version1;
	}
	public DELETE_SNAPSHOT_VHDSET_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MODIFY_VHDSET_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _SnapshotPath_e__Struct
		{
			public Guid SnapshotId;
			public PWSTR SnapshotFilePath;
		}
		public _SnapshotPath_e__Struct SnapshotPath;
		public Guid SnapshotId;
		public PWSTR DefaultFilePath;
	}
	public MODIFY_VHDSET_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct APPLY_SNAPSHOT_VHDSET_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public Guid SnapshotId;
			public Guid LeafSnapshotId;
		}
		public _Version1_e__Struct Version1;
	}
	public APPLY_SNAPSHOT_VHDSET_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RAW_SCSI_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public BOOL RSVDHandle;
			public uint8 DataIn;
			public uint8 CdbLength;
			public uint8 SenseInfoLength;
			public uint32 SrbFlags;
			public uint32 DataTransferLength;
			public void* DataBuffer;
			public uint8* SenseInfo;
			public uint8* Cdb;
		}
		public _Version1_e__Struct Version1;
	}
	public RAW_SCSI_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RAW_SCSI_VIRTUAL_DISK_RESPONSE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public uint8 ScsiStatus;
			public uint8 SenseInfoLength;
			public uint32 DataTransferLength;
		}
		public _Version1_e__Struct Version1;
	}
	public RAW_SCSI_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FORK_VIRTUAL_DISK_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Version1_e__Struct
		{
			public PWSTR ForkedVirtualDiskPath;
		}
		public _Version1_e__Struct Version1;
	}
	public FORK_VIRTUAL_DISK_VERSION Version;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region Functions
public static
{
	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR OpenVirtualDisk(VIRTUAL_STORAGE_TYPE* VirtualStorageType, PWSTR Path, VIRTUAL_DISK_ACCESS_MASK VirtualDiskAccessMask, OPEN_VIRTUAL_DISK_FLAG Flags, OPEN_VIRTUAL_DISK_PARAMETERS* Parameters, HANDLE* Handle);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR CreateVirtualDisk(VIRTUAL_STORAGE_TYPE* VirtualStorageType, PWSTR Path, VIRTUAL_DISK_ACCESS_MASK VirtualDiskAccessMask, PSECURITY_DESCRIPTOR SecurityDescriptor, CREATE_VIRTUAL_DISK_FLAG Flags, uint32 ProviderSpecificFlags, CREATE_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped, HANDLE* Handle);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AttachVirtualDisk(HANDLE VirtualDiskHandle, PSECURITY_DESCRIPTOR SecurityDescriptor, ATTACH_VIRTUAL_DISK_FLAG Flags, uint32 ProviderSpecificFlags, ATTACH_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR DetachVirtualDisk(HANDLE VirtualDiskHandle, DETACH_VIRTUAL_DISK_FLAG Flags, uint32 ProviderSpecificFlags);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetVirtualDiskPhysicalPath(HANDLE VirtualDiskHandle, uint32* DiskPathSizeInBytes, PWSTR DiskPath);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetAllAttachedVirtualDiskPhysicalPaths(uint32* PathsBufferSizeInBytes, PWSTR PathsBuffer);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetStorageDependencyInformation(HANDLE ObjectHandle, GET_STORAGE_DEPENDENCY_FLAG Flags, uint32 StorageDependencyInfoSize, STORAGE_DEPENDENCY_INFO* StorageDependencyInfo, uint32* SizeUsed);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetVirtualDiskInformation(HANDLE VirtualDiskHandle, uint32* VirtualDiskInfoSize, GET_VIRTUAL_DISK_INFO* VirtualDiskInfo, uint32* SizeUsed);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SetVirtualDiskInformation(HANDLE VirtualDiskHandle, SET_VIRTUAL_DISK_INFO* VirtualDiskInfo);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR EnumerateVirtualDiskMetadata(HANDLE VirtualDiskHandle, uint32* NumberOfItems, Guid* Items);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetVirtualDiskMetadata(HANDLE VirtualDiskHandle, in Guid Item, uint32* MetaDataSize, void* MetaData);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SetVirtualDiskMetadata(HANDLE VirtualDiskHandle, in Guid Item, uint32 MetaDataSize, void* MetaData);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR DeleteVirtualDiskMetadata(HANDLE VirtualDiskHandle, in Guid Item);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetVirtualDiskOperationProgress(HANDLE VirtualDiskHandle, OVERLAPPED* Overlapped, VIRTUAL_DISK_PROGRESS* Progress);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR CompactVirtualDisk(HANDLE VirtualDiskHandle, COMPACT_VIRTUAL_DISK_FLAG Flags, COMPACT_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR MergeVirtualDisk(HANDLE VirtualDiskHandle, MERGE_VIRTUAL_DISK_FLAG Flags, MERGE_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ExpandVirtualDisk(HANDLE VirtualDiskHandle, EXPAND_VIRTUAL_DISK_FLAG Flags, EXPAND_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ResizeVirtualDisk(HANDLE VirtualDiskHandle, RESIZE_VIRTUAL_DISK_FLAG Flags, RESIZE_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR MirrorVirtualDisk(HANDLE VirtualDiskHandle, MIRROR_VIRTUAL_DISK_FLAG Flags, MIRROR_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR BreakMirrorVirtualDisk(HANDLE VirtualDiskHandle);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AddVirtualDiskParent(HANDLE VirtualDiskHandle, PWSTR ParentPath);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR QueryChangesVirtualDisk(HANDLE VirtualDiskHandle, PWSTR ChangeTrackingId, uint64 ByteOffset, uint64 ByteLength, QUERY_CHANGES_VIRTUAL_DISK_FLAG Flags, QUERY_CHANGES_VIRTUAL_DISK_RANGE* Ranges, uint32* RangeCount, uint64* ProcessedLength);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR TakeSnapshotVhdSet(HANDLE VirtualDiskHandle, TAKE_SNAPSHOT_VHDSET_PARAMETERS* Parameters, TAKE_SNAPSHOT_VHDSET_FLAG Flags);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR DeleteSnapshotVhdSet(HANDLE VirtualDiskHandle, DELETE_SNAPSHOT_VHDSET_PARAMETERS* Parameters, DELETE_SNAPSHOT_VHDSET_FLAG Flags);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ModifyVhdSet(HANDLE VirtualDiskHandle, MODIFY_VHDSET_PARAMETERS* Parameters, MODIFY_VHDSET_FLAG Flags);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ApplySnapshotVhdSet(HANDLE VirtualDiskHandle, APPLY_SNAPSHOT_VHDSET_PARAMETERS* Parameters, APPLY_SNAPSHOT_VHDSET_FLAG Flags);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RawSCSIVirtualDisk(HANDLE VirtualDiskHandle, RAW_SCSI_VIRTUAL_DISK_PARAMETERS* Parameters, RAW_SCSI_VIRTUAL_DISK_FLAG Flags, RAW_SCSI_VIRTUAL_DISK_RESPONSE* Response);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ForkVirtualDisk(HANDLE VirtualDiskHandle, FORK_VIRTUAL_DISK_FLAG Flags, FORK_VIRTUAL_DISK_PARAMETERS* Parameters, OVERLAPPED* Overlapped);

	[Import("VirtDisk.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR CompleteForkVirtualDisk(HANDLE VirtualDiskHandle);

}
#endregion
