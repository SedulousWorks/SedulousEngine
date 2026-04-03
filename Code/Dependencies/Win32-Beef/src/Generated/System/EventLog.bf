using Win32.Foundation;
using System;

namespace Win32.System.EventLog;

#region Constants
public static
{
	public const uint32 EVT_VARIANT_TYPE_MASK = 127;
	public const uint32 EVT_VARIANT_TYPE_ARRAY = 128;
	public const uint32 EVT_READ_ACCESS = 1;
	public const uint32 EVT_WRITE_ACCESS = 2;
	public const uint32 EVT_CLEAR_ACCESS = 4;
	public const uint32 EVT_ALL_ACCESS = 7;
}
#endregion

#region TypeDefs
typealias EventLogHandle = int;

typealias EventSourceHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum REPORT_EVENT_TYPE : uint16
{
	EVENTLOG_SUCCESS = 0,
	EVENTLOG_AUDIT_FAILURE = 16,
	EVENTLOG_AUDIT_SUCCESS = 8,
	EVENTLOG_ERROR_TYPE = 1,
	EVENTLOG_INFORMATION_TYPE = 4,
	EVENTLOG_WARNING_TYPE = 2,
}


[AllowDuplicates]
public enum READ_EVENT_LOG_READ_FLAGS : uint32
{
	EVENTLOG_SEEK_READ = 2,
	EVENTLOG_SEQUENTIAL_READ = 1,
}


[AllowDuplicates]
public enum EVT_VARIANT_TYPE : int32
{
	EvtVarTypeNull = 0,
	EvtVarTypeString = 1,
	EvtVarTypeAnsiString = 2,
	EvtVarTypeSByte = 3,
	EvtVarTypeByte = 4,
	EvtVarTypeInt16 = 5,
	EvtVarTypeUInt16 = 6,
	EvtVarTypeInt32 = 7,
	EvtVarTypeUInt32 = 8,
	EvtVarTypeInt64 = 9,
	EvtVarTypeUInt64 = 10,
	EvtVarTypeSingle = 11,
	EvtVarTypeDouble = 12,
	EvtVarTypeBoolean = 13,
	EvtVarTypeBinary = 14,
	EvtVarTypeGuid = 15,
	EvtVarTypeSizeT = 16,
	EvtVarTypeFileTime = 17,
	EvtVarTypeSysTime = 18,
	EvtVarTypeSid = 19,
	EvtVarTypeHexInt32 = 20,
	EvtVarTypeHexInt64 = 21,
	EvtVarTypeEvtHandle = 32,
	EvtVarTypeEvtXml = 35,
}


[AllowDuplicates]
public enum EVT_LOGIN_CLASS : int32
{
	EvtRpcLogin = 1,
}


[AllowDuplicates]
public enum EVT_RPC_LOGIN_FLAGS : int32
{
	EvtRpcLoginAuthDefault = 0,
	EvtRpcLoginAuthNegotiate = 1,
	EvtRpcLoginAuthKerberos = 2,
	EvtRpcLoginAuthNTLM = 3,
}


[AllowDuplicates]
public enum EVT_QUERY_FLAGS : int32
{
	EvtQueryChannelPath = 1,
	EvtQueryFilePath = 2,
	EvtQueryForwardDirection = 256,
	EvtQueryReverseDirection = 512,
	EvtQueryTolerateQueryErrors = 4096,
}


[AllowDuplicates]
public enum EVT_SEEK_FLAGS : int32
{
	EvtSeekRelativeToFirst = 1,
	EvtSeekRelativeToLast = 2,
	EvtSeekRelativeToCurrent = 3,
	EvtSeekRelativeToBookmark = 4,
	EvtSeekOriginMask = 7,
	EvtSeekStrict = 65536,
}


[AllowDuplicates]
public enum EVT_SUBSCRIBE_FLAGS : int32
{
	EvtSubscribeToFutureEvents = 1,
	EvtSubscribeStartAtOldestRecord = 2,
	EvtSubscribeStartAfterBookmark = 3,
	EvtSubscribeOriginMask = 3,
	EvtSubscribeTolerateQueryErrors = 4096,
	EvtSubscribeStrict = 65536,
}


[AllowDuplicates]
public enum EVT_SUBSCRIBE_NOTIFY_ACTION : int32
{
	EvtSubscribeActionError = 0,
	EvtSubscribeActionDeliver = 1,
}


[AllowDuplicates]
public enum EVT_SYSTEM_PROPERTY_ID : int32
{
	EvtSystemProviderName = 0,
	EvtSystemProviderGuid = 1,
	EvtSystemEventID = 2,
	EvtSystemQualifiers = 3,
	EvtSystemLevel = 4,
	EvtSystemTask = 5,
	EvtSystemOpcode = 6,
	EvtSystemKeywords = 7,
	EvtSystemTimeCreated = 8,
	EvtSystemEventRecordId = 9,
	EvtSystemActivityID = 10,
	EvtSystemRelatedActivityID = 11,
	EvtSystemProcessID = 12,
	EvtSystemThreadID = 13,
	EvtSystemChannel = 14,
	EvtSystemComputer = 15,
	EvtSystemUserID = 16,
	EvtSystemVersion = 17,
	EvtSystemPropertyIdEND = 18,
}


[AllowDuplicates]
public enum EVT_RENDER_CONTEXT_FLAGS : int32
{
	EvtRenderContextValues = 0,
	EvtRenderContextSystem = 1,
	EvtRenderContextUser = 2,
}


[AllowDuplicates]
public enum EVT_RENDER_FLAGS : int32
{
	EvtRenderEventValues = 0,
	EvtRenderEventXml = 1,
	EvtRenderBookmark = 2,
}


[AllowDuplicates]
public enum EVT_FORMAT_MESSAGE_FLAGS : int32
{
	EvtFormatMessageEvent = 1,
	EvtFormatMessageLevel = 2,
	EvtFormatMessageTask = 3,
	EvtFormatMessageOpcode = 4,
	EvtFormatMessageKeyword = 5,
	EvtFormatMessageChannel = 6,
	EvtFormatMessageProvider = 7,
	EvtFormatMessageId = 8,
	EvtFormatMessageXml = 9,
}


[AllowDuplicates]
public enum EVT_OPEN_LOG_FLAGS : int32
{
	EvtOpenChannelPath = 1,
	EvtOpenFilePath = 2,
}


[AllowDuplicates]
public enum EVT_LOG_PROPERTY_ID : int32
{
	EvtLogCreationTime = 0,
	EvtLogLastAccessTime = 1,
	EvtLogLastWriteTime = 2,
	EvtLogFileSize = 3,
	EvtLogAttributes = 4,
	EvtLogNumberOfLogRecords = 5,
	EvtLogOldestRecordNumber = 6,
	EvtLogFull = 7,
}


[AllowDuplicates]
public enum EVT_EXPORTLOG_FLAGS : int32
{
	EvtExportLogChannelPath = 1,
	EvtExportLogFilePath = 2,
	EvtExportLogTolerateQueryErrors = 4096,
	EvtExportLogOverwrite = 8192,
}


[AllowDuplicates]
public enum EVT_CHANNEL_CONFIG_PROPERTY_ID : int32
{
	EvtChannelConfigEnabled = 0,
	EvtChannelConfigIsolation = 1,
	EvtChannelConfigType = 2,
	EvtChannelConfigOwningPublisher = 3,
	EvtChannelConfigClassicEventlog = 4,
	EvtChannelConfigAccess = 5,
	EvtChannelLoggingConfigRetention = 6,
	EvtChannelLoggingConfigAutoBackup = 7,
	EvtChannelLoggingConfigMaxSize = 8,
	EvtChannelLoggingConfigLogFilePath = 9,
	EvtChannelPublishingConfigLevel = 10,
	EvtChannelPublishingConfigKeywords = 11,
	EvtChannelPublishingConfigControlGuid = 12,
	EvtChannelPublishingConfigBufferSize = 13,
	EvtChannelPublishingConfigMinBuffers = 14,
	EvtChannelPublishingConfigMaxBuffers = 15,
	EvtChannelPublishingConfigLatency = 16,
	EvtChannelPublishingConfigClockType = 17,
	EvtChannelPublishingConfigSidType = 18,
	EvtChannelPublisherList = 19,
	EvtChannelPublishingConfigFileMax = 20,
	EvtChannelConfigPropertyIdEND = 21,
}


[AllowDuplicates]
public enum EVT_CHANNEL_TYPE : int32
{
	EvtChannelTypeAdmin = 0,
	EvtChannelTypeOperational = 1,
	EvtChannelTypeAnalytic = 2,
	EvtChannelTypeDebug = 3,
}


[AllowDuplicates]
public enum EVT_CHANNEL_ISOLATION_TYPE : int32
{
	EvtChannelIsolationTypeApplication = 0,
	EvtChannelIsolationTypeSystem = 1,
	EvtChannelIsolationTypeCustom = 2,
}


[AllowDuplicates]
public enum EVT_CHANNEL_CLOCK_TYPE : int32
{
	EvtChannelClockTypeSystemTime = 0,
	EvtChannelClockTypeQPC = 1,
}


[AllowDuplicates]
public enum EVT_CHANNEL_SID_TYPE : int32
{
	EvtChannelSidTypeNone = 0,
	EvtChannelSidTypePublishing = 1,
}


[AllowDuplicates]
public enum EVT_CHANNEL_REFERENCE_FLAGS : int32
{
	EvtChannelReferenceImported = 1,
}


[AllowDuplicates]
public enum EVT_PUBLISHER_METADATA_PROPERTY_ID : int32
{
	EvtPublisherMetadataPublisherGuid = 0,
	EvtPublisherMetadataResourceFilePath = 1,
	EvtPublisherMetadataParameterFilePath = 2,
	EvtPublisherMetadataMessageFilePath = 3,
	EvtPublisherMetadataHelpLink = 4,
	EvtPublisherMetadataPublisherMessageID = 5,
	EvtPublisherMetadataChannelReferences = 6,
	EvtPublisherMetadataChannelReferencePath = 7,
	EvtPublisherMetadataChannelReferenceIndex = 8,
	EvtPublisherMetadataChannelReferenceID = 9,
	EvtPublisherMetadataChannelReferenceFlags = 10,
	EvtPublisherMetadataChannelReferenceMessageID = 11,
	EvtPublisherMetadataLevels = 12,
	EvtPublisherMetadataLevelName = 13,
	EvtPublisherMetadataLevelValue = 14,
	EvtPublisherMetadataLevelMessageID = 15,
	EvtPublisherMetadataTasks = 16,
	EvtPublisherMetadataTaskName = 17,
	EvtPublisherMetadataTaskEventGuid = 18,
	EvtPublisherMetadataTaskValue = 19,
	EvtPublisherMetadataTaskMessageID = 20,
	EvtPublisherMetadataOpcodes = 21,
	EvtPublisherMetadataOpcodeName = 22,
	EvtPublisherMetadataOpcodeValue = 23,
	EvtPublisherMetadataOpcodeMessageID = 24,
	EvtPublisherMetadataKeywords = 25,
	EvtPublisherMetadataKeywordName = 26,
	EvtPublisherMetadataKeywordValue = 27,
	EvtPublisherMetadataKeywordMessageID = 28,
	EvtPublisherMetadataPropertyIdEND = 29,
}


[AllowDuplicates]
public enum EVT_EVENT_METADATA_PROPERTY_ID : int32
{
	EventMetadataEventID = 0,
	EventMetadataEventVersion = 1,
	EventMetadataEventChannel = 2,
	EventMetadataEventLevel = 3,
	EventMetadataEventOpcode = 4,
	EventMetadataEventTask = 5,
	EventMetadataEventKeyword = 6,
	EventMetadataEventMessageID = 7,
	EventMetadataEventTemplate = 8,
	EvtEventMetadataPropertyIdEND = 9,
}


[AllowDuplicates]
public enum EVT_QUERY_PROPERTY_ID : int32
{
	EvtQueryNames = 0,
	EvtQueryStatuses = 1,
	EvtQueryPropertyIdEND = 2,
}


[AllowDuplicates]
public enum EVT_EVENT_PROPERTY_ID : int32
{
	EvtEventQueryIDs = 0,
	EvtEventPath = 1,
	EvtEventPropertyIdEND = 2,
}

#endregion

#region Function Pointers
public function uint32 EVT_SUBSCRIBE_CALLBACK(EVT_SUBSCRIBE_NOTIFY_ACTION Action, void* UserContext, int Event);

#endregion

#region Structs
[CRepr]
public struct EVT_VARIANT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public BOOL BooleanVal;
		public int8 SByteVal;
		public int16 Int16Val;
		public int32 Int32Val;
		public int64 Int64Val;
		public uint8 ByteVal;
		public uint16 UInt16Val;
		public uint32 UInt32Val;
		public uint64 UInt64Val;
		public float SingleVal;
		public double DoubleVal;
		public uint64 FileTimeVal;
		public SYSTEMTIME* SysTimeVal;
		public Guid* GuidVal;
		public PWSTR StringVal;
		public PSTR AnsiStringVal;
		public uint8* BinaryVal;
		public PSID SidVal;
		public uint SizeTVal;
		public BOOL* BooleanArr;
		public int8* SByteArr;
		public int16* Int16Arr;
		public int32* Int32Arr;
		public int64* Int64Arr;
		public uint8* ByteArr;
		public uint16* UInt16Arr;
		public uint32* UInt32Arr;
		public uint64* UInt64Arr;
		public float* SingleArr;
		public double* DoubleArr;
		public FILETIME* FileTimeArr;
		public SYSTEMTIME* SysTimeArr;
		public Guid* GuidArr;
		public PWSTR* StringArr;
		public PSTR* AnsiStringArr;
		public PSID* SidArr;
		public uint* SizeTArr;
		public int EvtHandleVal;
		public PWSTR XmlVal;
		public PWSTR* XmlValArr;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 Count;
	public uint32 Type;
}

[CRepr]
public struct EVT_RPC_LOGIN
{
	public PWSTR Server;
	public PWSTR User;
	public PWSTR Domain;
	public PWSTR Password;
	public uint32 Flags;
}

[CRepr]
public struct EVENTLOGRECORD
{
	public uint32 Length;
	public uint32 Reserved;
	public uint32 RecordNumber;
	public uint32 TimeGenerated;
	public uint32 TimeWritten;
	public uint32 EventID;
	public REPORT_EVENT_TYPE EventType;
	public uint16 NumStrings;
	public uint16 EventCategory;
	public uint16 ReservedFlags;
	public uint32 ClosingRecordNumber;
	public uint32 StringOffset;
	public uint32 UserSidLength;
	public uint32 UserSidOffset;
	public uint32 DataLength;
	public uint32 DataOffset;
}

[CRepr]
public struct EVENTSFORLOGFILE
{
	public uint32 ulSize;
	public char16[256] szLogicalLogFile;
	public uint32 ulNumRecords;
	public EVENTLOGRECORD* pEventLogRecords mut => &pEventLogRecords_impl;
	private EVENTLOGRECORD[ANYSIZE_ARRAY] pEventLogRecords_impl;
}

[CRepr]
public struct EVENTLOG_FULL_INFORMATION
{
	public uint32 dwFull;
}

#endregion

#region Functions
public static
{
	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenSession(EVT_LOGIN_CLASS LoginClass, void* Login, uint32 Timeout, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtClose(int Object);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtCancel(int Object);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EvtGetExtendedStatus(uint32 BufferSize, char16* Buffer, uint32* BufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtQuery(int Session, PWSTR Path, PWSTR Query, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtNext(int ResultSet, uint32 EventsSize, int* Events, uint32 Timeout, uint32 Flags, uint32* Returned);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtSeek(int ResultSet, int64 Position, int Bookmark, uint32 Timeout, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtSubscribe(int Session, HANDLE SignalEvent, PWSTR ChannelPath, PWSTR Query, int Bookmark, void* Context, EVT_SUBSCRIBE_CALLBACK Callback, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtCreateRenderContext(uint32 ValuePathsCount, PWSTR* ValuePaths, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtRender(int Context, int Fragment, uint32 Flags, uint32 BufferSize, void* Buffer, uint32* BufferUsed, uint32* PropertyCount);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtFormatMessage(int PublisherMetadata, int Event, uint32 MessageId, uint32 ValueCount, EVT_VARIANT* Values, uint32 Flags, uint32 BufferSize, char16* Buffer, uint32* BufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenLog(int Session, PWSTR Path, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetLogInfo(int Log, EVT_LOG_PROPERTY_ID PropertyId, uint32 PropertyValueBufferSize, EVT_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtClearLog(int Session, PWSTR ChannelPath, PWSTR TargetFilePath, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtExportLog(int Session, PWSTR Path, PWSTR Query, PWSTR TargetFilePath, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtArchiveExportedLog(int Session, PWSTR LogFilePath, uint32 Locale, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenChannelEnum(int Session, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtNextChannelPath(int ChannelEnum, uint32 ChannelPathBufferSize, char16* ChannelPathBuffer, uint32* ChannelPathBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenChannelConfig(int Session, PWSTR ChannelPath, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtSaveChannelConfig(int ChannelConfig, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtSetChannelConfigProperty(int ChannelConfig, EVT_CHANNEL_CONFIG_PROPERTY_ID PropertyId, uint32 Flags, EVT_VARIANT* PropertyValue);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetChannelConfigProperty(int ChannelConfig, EVT_CHANNEL_CONFIG_PROPERTY_ID PropertyId, uint32 Flags, uint32 PropertyValueBufferSize, EVT_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenPublisherEnum(int Session, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtNextPublisherId(int PublisherEnum, uint32 PublisherIdBufferSize, char16* PublisherIdBuffer, uint32* PublisherIdBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenPublisherMetadata(int Session, PWSTR PublisherId, PWSTR LogFilePath, uint32 Locale, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetPublisherMetadataProperty(int PublisherMetadata, EVT_PUBLISHER_METADATA_PROPERTY_ID PropertyId, uint32 Flags, uint32 PublisherMetadataPropertyBufferSize, EVT_VARIANT* PublisherMetadataPropertyBuffer, uint32* PublisherMetadataPropertyBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtOpenEventMetadataEnum(int PublisherMetadata, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtNextEventMetadata(int EventMetadataEnum, uint32 Flags);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetEventMetadataProperty(int EventMetadata, EVT_EVENT_METADATA_PROPERTY_ID PropertyId, uint32 Flags, uint32 EventMetadataPropertyBufferSize, EVT_VARIANT* EventMetadataPropertyBuffer, uint32* EventMetadataPropertyBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetObjectArraySize(int ObjectArray, uint32* ObjectArraySize);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetObjectArrayProperty(int ObjectArray, uint32 PropertyId, uint32 ArrayIndex, uint32 Flags, uint32 PropertyValueBufferSize, EVT_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetQueryInfo(int QueryOrSubscription, EVT_QUERY_PROPERTY_ID PropertyId, uint32 PropertyValueBufferSize, EVT_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EvtCreateBookmark(PWSTR BookmarkXml);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtUpdateBookmark(int Bookmark, int Event);

	[Import("wevtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EvtGetEventInfo(int Event, EVT_EVENT_PROPERTY_ID PropertyId, uint32 PropertyValueBufferSize, EVT_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClearEventLogA(EventLogHandle hEventLog, PSTR lpBackupFileName);
	public static BOOL ClearEventLog(EventLogHandle hEventLog, PSTR lpBackupFileName) => ClearEventLogA(hEventLog, lpBackupFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClearEventLogW(EventLogHandle hEventLog, PWSTR lpBackupFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BackupEventLogA(EventLogHandle hEventLog, PSTR lpBackupFileName);
	public static BOOL BackupEventLog(EventLogHandle hEventLog, PSTR lpBackupFileName) => BackupEventLogA(hEventLog, lpBackupFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BackupEventLogW(EventLogHandle hEventLog, PWSTR lpBackupFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseEventLog(EventLogHandle hEventLog);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeregisterEventSource(EventSourceHandle hEventLog);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL NotifyChangeEventLog(EventLogHandle hEventLog, HANDLE hEvent);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumberOfEventLogRecords(EventLogHandle hEventLog, uint32* NumberOfRecords);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOldestEventLogRecord(EventLogHandle hEventLog, uint32* OldestRecord);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EventLogHandle OpenEventLogA(PSTR lpUNCServerName, PSTR lpSourceName);
	public static EventLogHandle OpenEventLog(PSTR lpUNCServerName, PSTR lpSourceName) => OpenEventLogA(lpUNCServerName, lpSourceName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EventLogHandle OpenEventLogW(PWSTR lpUNCServerName, PWSTR lpSourceName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EventSourceHandle RegisterEventSourceA(PSTR lpUNCServerName, PSTR lpSourceName);
	public static EventSourceHandle RegisterEventSource(PSTR lpUNCServerName, PSTR lpSourceName) => RegisterEventSourceA(lpUNCServerName, lpSourceName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EventSourceHandle RegisterEventSourceW(PWSTR lpUNCServerName, PWSTR lpSourceName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EventLogHandle OpenBackupEventLogA(PSTR lpUNCServerName, PSTR lpFileName);
	public static EventLogHandle OpenBackupEventLog(PSTR lpUNCServerName, PSTR lpFileName) => OpenBackupEventLogA(lpUNCServerName, lpFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EventLogHandle OpenBackupEventLogW(PWSTR lpUNCServerName, PWSTR lpFileName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadEventLogA(EventLogHandle hEventLog, READ_EVENT_LOG_READ_FLAGS dwReadFlags, uint32 dwRecordOffset, void* lpBuffer, uint32 nNumberOfBytesToRead, uint32* pnBytesRead, uint32* pnMinNumberOfBytesNeeded);
	public static BOOL ReadEventLog(EventLogHandle hEventLog, READ_EVENT_LOG_READ_FLAGS dwReadFlags, uint32 dwRecordOffset, void* lpBuffer, uint32 nNumberOfBytesToRead, uint32* pnBytesRead, uint32* pnMinNumberOfBytesNeeded) => ReadEventLogA(hEventLog, dwReadFlags, dwRecordOffset, lpBuffer, nNumberOfBytesToRead, pnBytesRead, pnMinNumberOfBytesNeeded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadEventLogW(EventLogHandle hEventLog, READ_EVENT_LOG_READ_FLAGS dwReadFlags, uint32 dwRecordOffset, void* lpBuffer, uint32 nNumberOfBytesToRead, uint32* pnBytesRead, uint32* pnMinNumberOfBytesNeeded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReportEventA(EventSourceHandle hEventLog, REPORT_EVENT_TYPE wType, uint16 wCategory, uint32 dwEventID, PSID lpUserSid, uint16 wNumStrings, uint32 dwDataSize, PSTR* lpStrings, void* lpRawData);
	public static BOOL ReportEvent(EventSourceHandle hEventLog, REPORT_EVENT_TYPE wType, uint16 wCategory, uint32 dwEventID, PSID lpUserSid, uint16 wNumStrings, uint32 dwDataSize, PSTR* lpStrings, void* lpRawData) => ReportEventA(hEventLog, wType, wCategory, dwEventID, lpUserSid, wNumStrings, dwDataSize, lpStrings, lpRawData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReportEventW(EventSourceHandle hEventLog, REPORT_EVENT_TYPE wType, uint16 wCategory, uint32 dwEventID, PSID lpUserSid, uint16 wNumStrings, uint32 dwDataSize, PWSTR* lpStrings, void* lpRawData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetEventLogInformation(EventLogHandle hEventLog, uint32 dwInfoLevel, void* lpBuffer, uint32 cbBufSize, uint32* pcbBytesNeeded);

}
#endregion
