using Win32.Foundation;
using System;

namespace Win32.Storage.ProjectedFileSystem;

#region TypeDefs
typealias PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT = int;

typealias PRJ_DIR_ENTRY_BUFFER_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum PRJ_NOTIFY_TYPES : uint32
{
	PRJ_NOTIFY_NONE = 0,
	PRJ_NOTIFY_SUPPRESS_NOTIFICATIONS = 1,
	PRJ_NOTIFY_FILE_OPENED = 2,
	PRJ_NOTIFY_NEW_FILE_CREATED = 4,
	PRJ_NOTIFY_FILE_OVERWRITTEN = 8,
	PRJ_NOTIFY_PRE_DELETE = 16,
	PRJ_NOTIFY_PRE_RENAME = 32,
	PRJ_NOTIFY_PRE_SET_HARDLINK = 64,
	PRJ_NOTIFY_FILE_RENAMED = 128,
	PRJ_NOTIFY_HARDLINK_CREATED = 256,
	PRJ_NOTIFY_FILE_HANDLE_CLOSED_NO_MODIFICATION = 512,
	PRJ_NOTIFY_FILE_HANDLE_CLOSED_FILE_MODIFIED = 1024,
	PRJ_NOTIFY_FILE_HANDLE_CLOSED_FILE_DELETED = 2048,
	PRJ_NOTIFY_FILE_PRE_CONVERT_TO_FULL = 4096,
	PRJ_NOTIFY_USE_EXISTING_MASK = 4294967295,
}


[AllowDuplicates]
public enum PRJ_NOTIFICATION : int32
{
	PRJ_NOTIFICATION_FILE_OPENED = 2,
	PRJ_NOTIFICATION_NEW_FILE_CREATED = 4,
	PRJ_NOTIFICATION_FILE_OVERWRITTEN = 8,
	PRJ_NOTIFICATION_PRE_DELETE = 16,
	PRJ_NOTIFICATION_PRE_RENAME = 32,
	PRJ_NOTIFICATION_PRE_SET_HARDLINK = 64,
	PRJ_NOTIFICATION_FILE_RENAMED = 128,
	PRJ_NOTIFICATION_HARDLINK_CREATED = 256,
	PRJ_NOTIFICATION_FILE_HANDLE_CLOSED_NO_MODIFICATION = 512,
	PRJ_NOTIFICATION_FILE_HANDLE_CLOSED_FILE_MODIFIED = 1024,
	PRJ_NOTIFICATION_FILE_HANDLE_CLOSED_FILE_DELETED = 2048,
	PRJ_NOTIFICATION_FILE_PRE_CONVERT_TO_FULL = 4096,
}


[AllowDuplicates]
public enum PRJ_EXT_INFO_TYPE : int32
{
	PRJ_EXT_INFO_TYPE_SYMLINK = 1,
}


[AllowDuplicates]
public enum PRJ_STARTVIRTUALIZING_FLAGS : uint32
{
	PRJ_FLAG_NONE = 0,
	PRJ_FLAG_USE_NEGATIVE_PATH_CACHE = 1,
}


[AllowDuplicates]
public enum PRJ_PLACEHOLDER_ID : int32
{
	PRJ_PLACEHOLDER_ID_LENGTH = 128,
}


[AllowDuplicates]
public enum PRJ_UPDATE_TYPES : uint32
{
	PRJ_UPDATE_NONE = 0,
	PRJ_UPDATE_ALLOW_DIRTY_METADATA = 1,
	PRJ_UPDATE_ALLOW_DIRTY_DATA = 2,
	PRJ_UPDATE_ALLOW_TOMBSTONE = 4,
	PRJ_UPDATE_RESERVED1 = 8,
	PRJ_UPDATE_RESERVED2 = 16,
	PRJ_UPDATE_ALLOW_READ_ONLY = 32,
	PRJ_UPDATE_MAX_VAL = 64,
}


[AllowDuplicates]
public enum PRJ_UPDATE_FAILURE_CAUSES : uint32
{
	PRJ_UPDATE_FAILURE_CAUSE_NONE = 0,
	PRJ_UPDATE_FAILURE_CAUSE_DIRTY_METADATA = 1,
	PRJ_UPDATE_FAILURE_CAUSE_DIRTY_DATA = 2,
	PRJ_UPDATE_FAILURE_CAUSE_TOMBSTONE = 4,
	PRJ_UPDATE_FAILURE_CAUSE_READ_ONLY = 8,
}


[AllowDuplicates]
public enum PRJ_FILE_STATE : uint32
{
	PRJ_FILE_STATE_PLACEHOLDER = 1,
	PRJ_FILE_STATE_HYDRATED_PLACEHOLDER = 2,
	PRJ_FILE_STATE_DIRTY_PLACEHOLDER = 4,
	PRJ_FILE_STATE_FULL = 8,
	PRJ_FILE_STATE_TOMBSTONE = 16,
}


[AllowDuplicates]
public enum PRJ_CALLBACK_DATA_FLAGS : int32
{
	PRJ_CB_DATA_FLAG_ENUM_RESTART_SCAN = 1,
	PRJ_CB_DATA_FLAG_ENUM_RETURN_SINGLE_ENTRY = 2,
}


[AllowDuplicates]
public enum PRJ_COMPLETE_COMMAND_TYPE : int32
{
	PRJ_COMPLETE_COMMAND_TYPE_NOTIFICATION = 1,
	PRJ_COMPLETE_COMMAND_TYPE_ENUMERATION = 2,
}

#endregion

#region Function Pointers
public function HRESULT PRJ_START_DIRECTORY_ENUMERATION_CB(PRJ_CALLBACK_DATA* callbackData, in Guid enumerationId);

public function HRESULT PRJ_GET_DIRECTORY_ENUMERATION_CB(PRJ_CALLBACK_DATA* callbackData, in Guid enumerationId, PWSTR searchExpression, PRJ_DIR_ENTRY_BUFFER_HANDLE dirEntryBufferHandle);

public function HRESULT PRJ_END_DIRECTORY_ENUMERATION_CB(PRJ_CALLBACK_DATA* callbackData, in Guid enumerationId);

public function HRESULT PRJ_GET_PLACEHOLDER_INFO_CB(PRJ_CALLBACK_DATA* callbackData);

public function HRESULT PRJ_GET_FILE_DATA_CB(PRJ_CALLBACK_DATA* callbackData, uint64 byteOffset, uint32 length);

public function HRESULT PRJ_QUERY_FILE_NAME_CB(PRJ_CALLBACK_DATA* callbackData);

public function HRESULT PRJ_NOTIFICATION_CB(PRJ_CALLBACK_DATA* callbackData, BOOLEAN isDirectory, PRJ_NOTIFICATION notification, PWSTR destinationFileName, PRJ_NOTIFICATION_PARAMETERS* operationParameters);

public function void PRJ_CANCEL_COMMAND_CB(PRJ_CALLBACK_DATA* callbackData);

#endregion

#region Structs
[CRepr]
public struct PRJ_EXTENDED_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Symlink_e__Struct
		{
			public PWSTR TargetName;
		}
		public _Symlink_e__Struct Symlink;
	}
	public PRJ_EXT_INFO_TYPE InfoType;
	public uint32 NextInfoOffset;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PRJ_NOTIFICATION_MAPPING
{
	public PRJ_NOTIFY_TYPES NotificationBitMask;
	public PWSTR NotificationRoot;
}

[CRepr]
public struct PRJ_STARTVIRTUALIZING_OPTIONS
{
	public PRJ_STARTVIRTUALIZING_FLAGS Flags;
	public uint32 PoolThreadCount;
	public uint32 ConcurrentThreadCount;
	public PRJ_NOTIFICATION_MAPPING* NotificationMappings;
	public uint32 NotificationMappingsCount;
}

[CRepr]
public struct PRJ_VIRTUALIZATION_INSTANCE_INFO
{
	public Guid InstanceID;
	public uint32 WriteAlignment;
}

[CRepr]
public struct PRJ_PLACEHOLDER_VERSION_INFO
{
	public uint8[128] ProviderID;
	public uint8[128] ContentID;
}

[CRepr]
public struct PRJ_FILE_BASIC_INFO
{
	public BOOLEAN IsDirectory;
	public int64 FileSize;
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER LastWriteTime;
	public LARGE_INTEGER ChangeTime;
	public uint32 FileAttributes;
}

[CRepr]
public struct PRJ_PLACEHOLDER_INFO
{
	[CRepr]
	public struct _StreamsInformation_e__Struct
	{
		public uint32 StreamsInfoBufferSize;
		public uint32 OffsetToFirstStreamInfo;
	}
	[CRepr]
	public struct _EaInformation_e__Struct
	{
		public uint32 EaBufferSize;
		public uint32 OffsetToFirstEa;
	}
	[CRepr]
	public struct _SecurityInformation_e__Struct
	{
		public uint32 SecurityBufferSize;
		public uint32 OffsetToSecurityDescriptor;
	}
	public PRJ_FILE_BASIC_INFO FileBasicInfo;
	public _EaInformation_e__Struct EaInformation;
	public _SecurityInformation_e__Struct SecurityInformation;
	public _StreamsInformation_e__Struct StreamsInformation;
	public PRJ_PLACEHOLDER_VERSION_INFO VersionInfo;
	public uint8* VariableData mut => &VariableData_impl;
	private uint8[ANYSIZE_ARRAY] VariableData_impl;
}

[CRepr]
public struct PRJ_CALLBACK_DATA
{
	public uint32 Size;
	public PRJ_CALLBACK_DATA_FLAGS Flags;
	public PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT NamespaceVirtualizationContext;
	public int32 CommandId;
	public Guid FileId;
	public Guid DataStreamId;
	public PWSTR FilePathName;
	public PRJ_PLACEHOLDER_VERSION_INFO* VersionInfo;
	public uint32 TriggeringProcessId;
	public PWSTR TriggeringProcessImageFileName;
	public void* InstanceContext;
}

[CRepr, Union]
public struct PRJ_NOTIFICATION_PARAMETERS
{
	[CRepr]
	public struct _FileRenamed_e__Struct
	{
		public PRJ_NOTIFY_TYPES NotificationMask;
	}
	[CRepr]
	public struct _PostCreate_e__Struct
	{
		public PRJ_NOTIFY_TYPES NotificationMask;
	}
	[CRepr]
	public struct _FileDeletedOnHandleClose_e__Struct
	{
		public BOOLEAN IsFileModified;
	}
	public _PostCreate_e__Struct PostCreate;
	public _FileRenamed_e__Struct FileRenamed;
	public _FileDeletedOnHandleClose_e__Struct FileDeletedOnHandleClose;
}

[CRepr]
public struct PRJ_CALLBACKS
{
	public PRJ_START_DIRECTORY_ENUMERATION_CB StartDirectoryEnumerationCallback;
	public PRJ_END_DIRECTORY_ENUMERATION_CB EndDirectoryEnumerationCallback;
	public PRJ_GET_DIRECTORY_ENUMERATION_CB GetDirectoryEnumerationCallback;
	public PRJ_GET_PLACEHOLDER_INFO_CB GetPlaceholderInfoCallback;
	public PRJ_GET_FILE_DATA_CB GetFileDataCallback;
	public PRJ_QUERY_FILE_NAME_CB QueryFileNameCallback;
	public PRJ_NOTIFICATION_CB NotificationCallback;
	public PRJ_CANCEL_COMMAND_CB CancelCommandCallback;
}

[CRepr]
public struct PRJ_COMPLETE_COMMAND_EXTENDED_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Notification_e__Struct
		{
			public PRJ_NOTIFY_TYPES NotificationMask;
		}
		[CRepr]
		public struct _Enumeration_e__Struct
		{
			public PRJ_DIR_ENTRY_BUFFER_HANDLE DirEntryBufferHandle;
		}
		public _Notification_e__Struct Notification;
		public _Enumeration_e__Struct Enumeration;
	}
	public PRJ_COMPLETE_COMMAND_TYPE CommandType;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region Functions
public static
{
	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjStartVirtualizing(PWSTR virtualizationRootPath, PRJ_CALLBACKS* callbacks, void* instanceContext, PRJ_STARTVIRTUALIZING_OPTIONS* options, PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT* namespaceVirtualizationContext);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PrjStopVirtualizing(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjClearNegativePathCache(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, uint32* totalEntryNumber);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjGetVirtualizationInstanceInfo(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, PRJ_VIRTUALIZATION_INSTANCE_INFO* virtualizationInstanceInfo);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjMarkDirectoryAsPlaceholder(PWSTR rootPathName, PWSTR targetPathName, PRJ_PLACEHOLDER_VERSION_INFO* versionInfo, in Guid virtualizationInstanceID);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjWritePlaceholderInfo(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, PWSTR destinationFileName, PRJ_PLACEHOLDER_INFO* placeholderInfo, uint32 placeholderInfoSize);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjWritePlaceholderInfo2(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, PWSTR destinationFileName, PRJ_PLACEHOLDER_INFO* placeholderInfo, uint32 placeholderInfoSize, PRJ_EXTENDED_INFO* ExtendedInfo);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjUpdateFileIfNeeded(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, PWSTR destinationFileName, PRJ_PLACEHOLDER_INFO* placeholderInfo, uint32 placeholderInfoSize, PRJ_UPDATE_TYPES updateFlags, PRJ_UPDATE_FAILURE_CAUSES* failureReason);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjDeleteFile(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, PWSTR destinationFileName, PRJ_UPDATE_TYPES updateFlags, PRJ_UPDATE_FAILURE_CAUSES* failureReason);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjWriteFileData(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, in Guid dataStreamId, void* buffer, uint64 byteOffset, uint32 length);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjGetOnDiskFileState(PWSTR destinationFileName, PRJ_FILE_STATE* fileState);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* PrjAllocateAlignedBuffer(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, uint size);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PrjFreeAlignedBuffer(void* buffer);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjCompleteCommand(PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT namespaceVirtualizationContext, int32 commandId, HRESULT completionResult, PRJ_COMPLETE_COMMAND_EXTENDED_PARAMETERS* extendedParameters);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjFillDirEntryBuffer(PWSTR fileName, PRJ_FILE_BASIC_INFO* fileBasicInfo, PRJ_DIR_ENTRY_BUFFER_HANDLE dirEntryBufferHandle);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PrjFillDirEntryBuffer2(PRJ_DIR_ENTRY_BUFFER_HANDLE dirEntryBufferHandle, PWSTR fileName, PRJ_FILE_BASIC_INFO* fileBasicInfo, PRJ_EXTENDED_INFO* extendedInfo);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN PrjFileNameMatch(PWSTR fileNameToCheck, PWSTR pattern);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PrjFileNameCompare(PWSTR fileName1, PWSTR fileName2);

	[Import("PROJECTEDFSLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN PrjDoesNameContainWildCards(PWSTR fileName);

}
#endregion
