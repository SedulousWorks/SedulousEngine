using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Storage.OfflineFiles;

#region Constants
public static
{
	public const uint32 OFFLINEFILES_SYNC_STATE_LOCAL_KNOWN = 1;
	public const uint32 OFFLINEFILES_SYNC_STATE_REMOTE_KNOWN = 2;
	public const uint32 OFFLINEFILES_CHANGES_NONE = 0;
	public const uint32 OFFLINEFILES_CHANGES_LOCAL_SIZE = 1;
	public const uint32 OFFLINEFILES_CHANGES_LOCAL_ATTRIBUTES = 2;
	public const uint32 OFFLINEFILES_CHANGES_LOCAL_TIME = 4;
	public const uint32 OFFLINEFILES_CHANGES_REMOTE_SIZE = 8;
	public const uint32 OFFLINEFILES_CHANGES_REMOTE_ATTRIBUTES = 16;
	public const uint32 OFFLINEFILES_CHANGES_REMOTE_TIME = 32;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_MODIFIED_DATA = 1;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_MODIFIED_ATTRIBUTES = 2;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_MODIFIED = 4;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_CREATED = 8;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_DELETED = 16;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_DIRTY = 32;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_SPARSE = 64;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_FILE = 128;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_DIRECTORY = 256;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_PINNED_USER = 512;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_PINNED_OTHERS = 1024;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_PINNED_COMPUTER = 2048;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_PINNED = 4096;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_GHOST = 8192;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_SUSPENDED = 16384;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_OFFLINE = 32768;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_ONLINE = 65536;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_USER_WRITE = 131072;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_USER_READ = 262144;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_USER_ANYACCESS = 524288;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_OTHER_WRITE = 1048576;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_OTHER_READ = 2097152;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_OTHER_ANYACCESS = 4194304;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_GUEST_WRITE = 8388608;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_GUEST_READ = 16777216;
	public const uint32 OFFLINEFILES_ITEM_FILTER_FLAG_GUEST_ANYACCESS = 33554432;
	public const uint32 OFFLINEFILES_ITEM_QUERY_REMOTEINFO = 1;
	public const uint32 OFFLINEFILES_ITEM_QUERY_CONNECTIONSTATE = 2;
	public const uint32 OFFLINEFILES_ITEM_QUERY_LOCALDIRTYBYTECOUNT = 4;
	public const uint32 OFFLINEFILES_ITEM_QUERY_REMOTEDIRTYBYTECOUNT = 8;
	public const uint32 OFFLINEFILES_ITEM_QUERY_INCLUDETRANSPARENTCACHE = 16;
	public const uint32 OFFLINEFILES_ITEM_QUERY_ATTEMPT_TRANSITIONONLINE = 32;
	public const uint32 OFFLINEFILES_ITEM_QUERY_ADMIN = 2147483648;
	public const uint32 OFFLINEFILES_ENUM_FLAT = 1;
	public const uint32 OFFLINEFILES_ENUM_FLAT_FILESONLY = 2;
	public const uint32 OFFLINEFILES_SETTING_SCOPE_USER = 1;
	public const uint32 OFFLINEFILES_SETTING_SCOPE_COMPUTER = 2;
	public const String OFFLINEFILES_SETTING_PinLinkTargets = "LinkTargetCaching";
	public const uint32 OFFLINEFILES_PINLINKTARGETS_NEVER = 0;
	public const uint32 OFFLINEFILES_PINLINKTARGETS_EXPLICIT = 1;
	public const uint32 OFFLINEFILES_PINLINKTARGETS_ALWAYS = 2;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_FILLSPARSE = 1;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_SYNCIN = 2;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_SYNCOUT = 4;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_PINNEWFILES = 8;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_PINLINKTARGETS = 16;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_PINFORUSER = 32;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_PINFORUSER_POLICY = 64;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_PINFORALL = 128;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_PINFORREDIR = 256;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_LOWPRIORITY = 512;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_ASYNCPROGRESS = 1024;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_INTERACTIVE = 2048;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_CONSOLE = 4096;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_SKIPSUSPENDEDDIRS = 8192;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_BACKGROUND = 65536;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_FLAG_NONEWFILESOUT = 131072;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_CR_MASK = 4026531840;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_CR_DEFAULT = 0;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_CR_KEEPLOCAL = 268435456;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_CR_KEEPREMOTE = 536870912;
	public const uint32 OFFLINEFILES_SYNC_CONTROL_CR_KEEPLATEST = 805306368;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_FORUSER = 32;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_FORUSER_POLICY = 64;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_FORALL = 128;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_FORREDIR = 256;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_FILL = 1;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_LOWPRIORITY = 512;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_ASYNCPROGRESS = 1024;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_INTERACTIVE = 2048;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_CONSOLE = 4096;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_PINLINKTARGETS = 16;
	public const uint32 OFFLINEFILES_PIN_CONTROL_FLAG_BACKGROUND = 65536;
	public const uint32 OFFLINEFILES_ENCRYPTION_CONTROL_FLAG_LOWPRIORITY = 512;
	public const uint32 OFFLINEFILES_ENCRYPTION_CONTROL_FLAG_ASYNCPROGRESS = 1024;
	public const uint32 OFFLINEFILES_ENCRYPTION_CONTROL_FLAG_INTERACTIVE = 2048;
	public const uint32 OFFLINEFILES_ENCRYPTION_CONTROL_FLAG_CONSOLE = 4096;
	public const uint32 OFFLINEFILES_ENCRYPTION_CONTROL_FLAG_BACKGROUND = 65536;
	public const uint32 OFFLINEFILES_DELETE_FLAG_NOAUTOCACHED = 1;
	public const uint32 OFFLINEFILES_DELETE_FLAG_NOPINNED = 2;
	public const uint32 OFFLINEFILES_DELETE_FLAG_DELMODIFIED = 4;
	public const uint32 OFFLINEFILES_DELETE_FLAG_ADMIN = 2147483648;
	public const uint32 OFFLINEFILES_TRANSITION_FLAG_INTERACTIVE = 1;
	public const uint32 OFFLINEFILES_TRANSITION_FLAG_CONSOLE = 2;
	public const uint32 OFFLINEFILES_SYNC_ITEM_CHANGE_NONE = 0;
	public const uint32 OFFLINEFILES_SYNC_ITEM_CHANGE_CHANGETIME = 1;
	public const uint32 OFFLINEFILES_SYNC_ITEM_CHANGE_WRITETIME = 2;
	public const uint32 OFFLINEFILES_SYNC_ITEM_CHANGE_FILESIZE = 4;
	public const uint32 OFFLINEFILES_SYNC_ITEM_CHANGE_ATTRIBUTES = 8;
}
#endregion

#region Enums

[AllowDuplicates]
public enum OFFLINEFILES_ITEM_TYPE : int32
{
	OFFLINEFILES_ITEM_TYPE_FILE = 0,
	OFFLINEFILES_ITEM_TYPE_DIRECTORY = 1,
	OFFLINEFILES_ITEM_TYPE_SHARE = 2,
	OFFLINEFILES_ITEM_TYPE_SERVER = 3,
}


[AllowDuplicates]
public enum OFFLINEFILES_ITEM_COPY : int32
{
	OFFLINEFILES_ITEM_COPY_LOCAL = 0,
	OFFLINEFILES_ITEM_COPY_REMOTE = 1,
	OFFLINEFILES_ITEM_COPY_ORIGINAL = 2,
}


[AllowDuplicates]
public enum OFFLINEFILES_CONNECT_STATE : int32
{
	OFFLINEFILES_CONNECT_STATE_UNKNOWN = 0,
	OFFLINEFILES_CONNECT_STATE_OFFLINE = 1,
	OFFLINEFILES_CONNECT_STATE_ONLINE = 2,
	OFFLINEFILES_CONNECT_STATE_TRANSPARENTLY_CACHED = 3,
	OFFLINEFILES_CONNECT_STATE_PARTLY_TRANSPARENTLY_CACHED = 4,
}


[AllowDuplicates]
public enum OFFLINEFILES_OFFLINE_REASON : int32
{
	OFFLINEFILES_OFFLINE_REASON_UNKNOWN = 0,
	OFFLINEFILES_OFFLINE_REASON_NOT_APPLICABLE = 1,
	OFFLINEFILES_OFFLINE_REASON_CONNECTION_FORCED = 2,
	OFFLINEFILES_OFFLINE_REASON_CONNECTION_SLOW = 3,
	OFFLINEFILES_OFFLINE_REASON_CONNECTION_ERROR = 4,
	OFFLINEFILES_OFFLINE_REASON_ITEM_VERSION_CONFLICT = 5,
	OFFLINEFILES_OFFLINE_REASON_ITEM_SUSPENDED = 6,
}


[AllowDuplicates]
public enum OFFLINEFILES_CACHING_MODE : int32
{
	OFFLINEFILES_CACHING_MODE_NONE = 0,
	OFFLINEFILES_CACHING_MODE_NOCACHING = 1,
	OFFLINEFILES_CACHING_MODE_MANUAL = 2,
	OFFLINEFILES_CACHING_MODE_AUTO_DOC = 3,
	OFFLINEFILES_CACHING_MODE_AUTO_PROGANDDOC = 4,
}


[AllowDuplicates]
public enum OFFLINEFILES_OP_RESPONSE : int32
{
	OFFLINEFILES_OP_CONTINUE = 0,
	OFFLINEFILES_OP_RETRY = 1,
	OFFLINEFILES_OP_ABORT = 2,
}


[AllowDuplicates]
public enum OFFLINEFILES_EVENTS : int32
{
	OFFLINEFILES_EVENT_CACHEMOVED = 0,
	OFFLINEFILES_EVENT_CACHEISFULL = 1,
	OFFLINEFILES_EVENT_CACHEISCORRUPTED = 2,
	OFFLINEFILES_EVENT_ENABLED = 3,
	OFFLINEFILES_EVENT_ENCRYPTIONCHANGED = 4,
	OFFLINEFILES_EVENT_SYNCBEGIN = 5,
	OFFLINEFILES_EVENT_SYNCFILERESULT = 6,
	OFFLINEFILES_EVENT_SYNCCONFLICTRECADDED = 7,
	OFFLINEFILES_EVENT_SYNCCONFLICTRECUPDATED = 8,
	OFFLINEFILES_EVENT_SYNCCONFLICTRECREMOVED = 9,
	OFFLINEFILES_EVENT_SYNCEND = 10,
	OFFLINEFILES_EVENT_BACKGROUNDSYNCBEGIN = 11,
	OFFLINEFILES_EVENT_BACKGROUNDSYNCEND = 12,
	OFFLINEFILES_EVENT_NETTRANSPORTARRIVED = 13,
	OFFLINEFILES_EVENT_NONETTRANSPORTS = 14,
	OFFLINEFILES_EVENT_ITEMDISCONNECTED = 15,
	OFFLINEFILES_EVENT_ITEMRECONNECTED = 16,
	OFFLINEFILES_EVENT_ITEMAVAILABLEOFFLINE = 17,
	OFFLINEFILES_EVENT_ITEMNOTAVAILABLEOFFLINE = 18,
	OFFLINEFILES_EVENT_ITEMPINNED = 19,
	OFFLINEFILES_EVENT_ITEMNOTPINNED = 20,
	OFFLINEFILES_EVENT_ITEMMODIFIED = 21,
	OFFLINEFILES_EVENT_ITEMADDEDTOCACHE = 22,
	OFFLINEFILES_EVENT_ITEMDELETEDFROMCACHE = 23,
	OFFLINEFILES_EVENT_ITEMRENAMED = 24,
	OFFLINEFILES_EVENT_DATALOST = 25,
	OFFLINEFILES_EVENT_PING = 26,
	OFFLINEFILES_EVENT_ITEMRECONNECTBEGIN = 27,
	OFFLINEFILES_EVENT_ITEMRECONNECTEND = 28,
	OFFLINEFILES_EVENT_CACHEEVICTBEGIN = 29,
	OFFLINEFILES_EVENT_CACHEEVICTEND = 30,
	OFFLINEFILES_EVENT_POLICYCHANGEDETECTED = 31,
	OFFLINEFILES_EVENT_PREFERENCECHANGEDETECTED = 32,
	OFFLINEFILES_EVENT_SETTINGSCHANGESAPPLIED = 33,
	OFFLINEFILES_EVENT_TRANSPARENTCACHEITEMNOTIFY = 34,
	OFFLINEFILES_EVENT_PREFETCHFILEBEGIN = 35,
	OFFLINEFILES_EVENT_PREFETCHFILEEND = 36,
	OFFLINEFILES_EVENT_PREFETCHCLOSEHANDLEBEGIN = 37,
	OFFLINEFILES_EVENT_PREFETCHCLOSEHANDLEEND = 38,
	OFFLINEFILES_NUM_EVENTS = 39,
}


[AllowDuplicates]
public enum OFFLINEFILES_PATHFILTER_MATCH : int32
{
	OFFLINEFILES_PATHFILTER_SELF = 0,
	OFFLINEFILES_PATHFILTER_CHILD = 1,
	OFFLINEFILES_PATHFILTER_DESCENDENT = 2,
	OFFLINEFILES_PATHFILTER_SELFORCHILD = 3,
	OFFLINEFILES_PATHFILTER_SELFORDESCENDENT = 4,
}


[AllowDuplicates]
public enum OFFLINEFILES_SYNC_CONFLICT_RESOLVE : int32
{
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_NONE = 0,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_KEEPLOCAL = 1,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_KEEPREMOTE = 2,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_KEEPALLCHANGES = 3,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_KEEPLATEST = 4,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_LOG = 5,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_SKIP = 6,
	OFFLINEFILES_SYNC_CONFLICT_ABORT = 7,
	OFFLINEFILES_SYNC_CONFLICT_RESOLVE_NUMCODES = 8,
}


[AllowDuplicates]
public enum OFFLINEFILES_ITEM_TIME : int32
{
	OFFLINEFILES_ITEM_TIME_CREATION = 0,
	OFFLINEFILES_ITEM_TIME_LASTACCESS = 1,
	OFFLINEFILES_ITEM_TIME_LASTWRITE = 2,
}


[AllowDuplicates]
public enum OFFLINEFILES_COMPARE : int32
{
	OFFLINEFILES_COMPARE_EQ = 0,
	OFFLINEFILES_COMPARE_NEQ = 1,
	OFFLINEFILES_COMPARE_LT = 2,
	OFFLINEFILES_COMPARE_GT = 3,
	OFFLINEFILES_COMPARE_LTE = 4,
	OFFLINEFILES_COMPARE_GTE = 5,
}


[AllowDuplicates]
public enum OFFLINEFILES_SETTING_VALUE_TYPE : int32
{
	OFFLINEFILES_SETTING_VALUE_UI4 = 0,
	OFFLINEFILES_SETTING_VALUE_BSTR = 1,
	OFFLINEFILES_SETTING_VALUE_BSTR_DBLNULTERM = 2,
	OFFLINEFILES_SETTING_VALUE_2DIM_ARRAY_BSTR_UI4 = 3,
	OFFLINEFILES_SETTING_VALUE_2DIM_ARRAY_BSTR_BSTR = 4,
}


[AllowDuplicates]
public enum OFFLINEFILES_SYNC_OPERATION : int32
{
	OFFLINEFILES_SYNC_OPERATION_CREATE_COPY_ON_SERVER = 0,
	OFFLINEFILES_SYNC_OPERATION_CREATE_COPY_ON_CLIENT = 1,
	OFFLINEFILES_SYNC_OPERATION_SYNC_TO_SERVER = 2,
	OFFLINEFILES_SYNC_OPERATION_SYNC_TO_CLIENT = 3,
	OFFLINEFILES_SYNC_OPERATION_DELETE_SERVER_COPY = 4,
	OFFLINEFILES_SYNC_OPERATION_DELETE_CLIENT_COPY = 5,
	OFFLINEFILES_SYNC_OPERATION_PIN = 6,
	OFFLINEFILES_SYNC_OPERATION_PREPARE = 7,
}


[AllowDuplicates]
public enum OFFLINEFILES_SYNC_STATE : int32
{
	OFFLINEFILES_SYNC_STATE_Stable = 0,
	OFFLINEFILES_SYNC_STATE_FileOnClient_DirOnServer = 1,
	OFFLINEFILES_SYNC_STATE_FileOnClient_NoServerCopy = 2,
	OFFLINEFILES_SYNC_STATE_DirOnClient_FileOnServer = 3,
	OFFLINEFILES_SYNC_STATE_DirOnClient_FileChangedOnServer = 4,
	OFFLINEFILES_SYNC_STATE_DirOnClient_NoServerCopy = 5,
	OFFLINEFILES_SYNC_STATE_FileCreatedOnClient_NoServerCopy = 6,
	OFFLINEFILES_SYNC_STATE_FileCreatedOnClient_FileChangedOnServer = 7,
	OFFLINEFILES_SYNC_STATE_FileCreatedOnClient_DirChangedOnServer = 8,
	OFFLINEFILES_SYNC_STATE_FileCreatedOnClient_FileOnServer = 9,
	OFFLINEFILES_SYNC_STATE_FileCreatedOnClient_DirOnServer = 10,
	OFFLINEFILES_SYNC_STATE_FileCreatedOnClient_DeletedOnServer = 11,
	OFFLINEFILES_SYNC_STATE_FileChangedOnClient_ChangedOnServer = 12,
	OFFLINEFILES_SYNC_STATE_FileChangedOnClient_DirOnServer = 13,
	OFFLINEFILES_SYNC_STATE_FileChangedOnClient_DirChangedOnServer = 14,
	OFFLINEFILES_SYNC_STATE_FileChangedOnClient_DeletedOnServer = 15,
	OFFLINEFILES_SYNC_STATE_FileSparseOnClient_ChangedOnServer = 16,
	OFFLINEFILES_SYNC_STATE_FileSparseOnClient_DeletedOnServer = 17,
	OFFLINEFILES_SYNC_STATE_FileSparseOnClient_DirOnServer = 18,
	OFFLINEFILES_SYNC_STATE_FileSparseOnClient_DirChangedOnServer = 19,
	OFFLINEFILES_SYNC_STATE_DirCreatedOnClient_NoServerCopy = 20,
	OFFLINEFILES_SYNC_STATE_DirCreatedOnClient_DirOnServer = 21,
	OFFLINEFILES_SYNC_STATE_DirCreatedOnClient_FileOnServer = 22,
	OFFLINEFILES_SYNC_STATE_DirCreatedOnClient_FileChangedOnServer = 23,
	OFFLINEFILES_SYNC_STATE_DirCreatedOnClient_DirChangedOnServer = 24,
	OFFLINEFILES_SYNC_STATE_DirCreatedOnClient_DeletedOnServer = 25,
	OFFLINEFILES_SYNC_STATE_DirChangedOnClient_FileOnServer = 26,
	OFFLINEFILES_SYNC_STATE_DirChangedOnClient_FileChangedOnServer = 27,
	OFFLINEFILES_SYNC_STATE_DirChangedOnClient_ChangedOnServer = 28,
	OFFLINEFILES_SYNC_STATE_DirChangedOnClient_DeletedOnServer = 29,
	OFFLINEFILES_SYNC_STATE_NoClientCopy_FileOnServer = 30,
	OFFLINEFILES_SYNC_STATE_NoClientCopy_DirOnServer = 31,
	OFFLINEFILES_SYNC_STATE_NoClientCopy_FileChangedOnServer = 32,
	OFFLINEFILES_SYNC_STATE_NoClientCopy_DirChangedOnServer = 33,
	OFFLINEFILES_SYNC_STATE_DeletedOnClient_FileOnServer = 34,
	OFFLINEFILES_SYNC_STATE_DeletedOnClient_DirOnServer = 35,
	OFFLINEFILES_SYNC_STATE_DeletedOnClient_FileChangedOnServer = 36,
	OFFLINEFILES_SYNC_STATE_DeletedOnClient_DirChangedOnServer = 37,
	OFFLINEFILES_SYNC_STATE_FileSparseOnClient = 38,
	OFFLINEFILES_SYNC_STATE_FileChangedOnClient = 39,
	OFFLINEFILES_SYNC_STATE_FileRenamedOnClient = 40,
	OFFLINEFILES_SYNC_STATE_DirSparseOnClient = 41,
	OFFLINEFILES_SYNC_STATE_DirChangedOnClient = 42,
	OFFLINEFILES_SYNC_STATE_DirRenamedOnClient = 43,
	OFFLINEFILES_SYNC_STATE_FileChangedOnServer = 44,
	OFFLINEFILES_SYNC_STATE_FileRenamedOnServer = 45,
	OFFLINEFILES_SYNC_STATE_FileDeletedOnServer = 46,
	OFFLINEFILES_SYNC_STATE_DirChangedOnServer = 47,
	OFFLINEFILES_SYNC_STATE_DirRenamedOnServer = 48,
	OFFLINEFILES_SYNC_STATE_DirDeletedOnServer = 49,
	OFFLINEFILES_SYNC_STATE_FileReplacedAndDeletedOnClient_FileOnServer = 50,
	OFFLINEFILES_SYNC_STATE_FileReplacedAndDeletedOnClient_FileChangedOnServer = 51,
	OFFLINEFILES_SYNC_STATE_FileReplacedAndDeletedOnClient_DirOnServer = 52,
	OFFLINEFILES_SYNC_STATE_FileReplacedAndDeletedOnClient_DirChangedOnServer = 53,
	OFFLINEFILES_SYNC_STATE_NUMSTATES = 54,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_OfflineFilesSetting = .(0xfd3659e9, 0xa920, 0x4123, 0xad, 0x64, 0x7f, 0xc7, 0x6c, 0x7a, 0xac, 0xdf);


	public const Guid CLSID_OfflineFilesCache = .(0x48c6be7c, 0x3871, 0x43cc, 0xb4, 0x6f, 0x14, 0x49, 0xa1, 0xbb, 0x2f, 0xf3);


}
#endregion

#region COM Types
[CRepr]struct IOfflineFilesEvents : IUnknown
{
	public new const Guid IID = .(0xe25585c1, 0x0caa, 0x4eb1, 0x87, 0x3b, 0x1c, 0xae, 0x5b, 0x77, 0xc3, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszOldPath, PWSTR pszNewPath) CacheMoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CacheIsFull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CacheIsCorrupted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bEnabled) Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bWasEncrypted, BOOL bWasPartial, BOOL bIsEncrypted, BOOL bIsPartial) EncryptionChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rSyncId) SyncBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rSyncId, PWSTR pszFile, HRESULT hrResult) SyncFileResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszConflictPath, FILETIME* pftConflictDateTime, OFFLINEFILES_SYNC_STATE ConflictSyncState) SyncConflictRecAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszConflictPath, FILETIME* pftConflictDateTime, OFFLINEFILES_SYNC_STATE ConflictSyncState) SyncConflictRecUpdated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszConflictPath, FILETIME* pftConflictDateTime, OFFLINEFILES_SYNC_STATE ConflictSyncState) SyncConflictRecRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rSyncId, HRESULT hrResult) SyncEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NetTransportArrived;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NoNetTransports;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemDisconnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemReconnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemAvailableOffline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemNotAvailableOffline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemPinned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemNotPinned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType, BOOL bModifiedData, BOOL bModifiedAttributes) ItemModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemAddedToCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemDeletedFromCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszOldPath, PWSTR pszNewPath, OFFLINEFILES_ITEM_TYPE ItemType) ItemRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DataLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Ping;
	}


	public HRESULT CacheMoved(PWSTR pszOldPath, PWSTR pszNewPath) mut => VT.[Friend]CacheMoved(&this, pszOldPath, pszNewPath);

	public HRESULT CacheIsFull() mut => VT.[Friend]CacheIsFull(&this);

	public HRESULT CacheIsCorrupted() mut => VT.[Friend]CacheIsCorrupted(&this);

	public HRESULT Enabled(BOOL bEnabled) mut => VT.[Friend]Enabled(&this, bEnabled);

	public HRESULT EncryptionChanged(BOOL bWasEncrypted, BOOL bWasPartial, BOOL bIsEncrypted, BOOL bIsPartial) mut => VT.[Friend]EncryptionChanged(&this, bWasEncrypted, bWasPartial, bIsEncrypted, bIsPartial);

	public HRESULT SyncBegin(in Guid rSyncId) mut => VT.[Friend]SyncBegin(&this, rSyncId);

	public HRESULT SyncFileResult(in Guid rSyncId, PWSTR pszFile, HRESULT hrResult) mut => VT.[Friend]SyncFileResult(&this, rSyncId, pszFile, hrResult);

	public HRESULT SyncConflictRecAdded(PWSTR pszConflictPath, FILETIME* pftConflictDateTime, OFFLINEFILES_SYNC_STATE ConflictSyncState) mut => VT.[Friend]SyncConflictRecAdded(&this, pszConflictPath, pftConflictDateTime, ConflictSyncState);

	public HRESULT SyncConflictRecUpdated(PWSTR pszConflictPath, FILETIME* pftConflictDateTime, OFFLINEFILES_SYNC_STATE ConflictSyncState) mut => VT.[Friend]SyncConflictRecUpdated(&this, pszConflictPath, pftConflictDateTime, ConflictSyncState);

	public HRESULT SyncConflictRecRemoved(PWSTR pszConflictPath, FILETIME* pftConflictDateTime, OFFLINEFILES_SYNC_STATE ConflictSyncState) mut => VT.[Friend]SyncConflictRecRemoved(&this, pszConflictPath, pftConflictDateTime, ConflictSyncState);

	public HRESULT SyncEnd(in Guid rSyncId, HRESULT hrResult) mut => VT.[Friend]SyncEnd(&this, rSyncId, hrResult);

	public HRESULT NetTransportArrived() mut => VT.[Friend]NetTransportArrived(&this);

	public HRESULT NoNetTransports() mut => VT.[Friend]NoNetTransports(&this);

	public HRESULT ItemDisconnected(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemDisconnected(&this, pszPath, ItemType);

	public HRESULT ItemReconnected(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemReconnected(&this, pszPath, ItemType);

	public HRESULT ItemAvailableOffline(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemAvailableOffline(&this, pszPath, ItemType);

	public HRESULT ItemNotAvailableOffline(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemNotAvailableOffline(&this, pszPath, ItemType);

	public HRESULT ItemPinned(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemPinned(&this, pszPath, ItemType);

	public HRESULT ItemNotPinned(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemNotPinned(&this, pszPath, ItemType);

	public HRESULT ItemModified(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType, BOOL bModifiedData, BOOL bModifiedAttributes) mut => VT.[Friend]ItemModified(&this, pszPath, ItemType, bModifiedData, bModifiedAttributes);

	public HRESULT ItemAddedToCache(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemAddedToCache(&this, pszPath, ItemType);

	public HRESULT ItemDeletedFromCache(PWSTR pszPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemDeletedFromCache(&this, pszPath, ItemType);

	public HRESULT ItemRenamed(PWSTR pszOldPath, PWSTR pszNewPath, OFFLINEFILES_ITEM_TYPE ItemType) mut => VT.[Friend]ItemRenamed(&this, pszOldPath, pszNewPath, ItemType);

	public HRESULT DataLost() mut => VT.[Friend]DataLost(&this);

	public HRESULT Ping() mut => VT.[Friend]Ping(&this);
}

[CRepr]struct IOfflineFilesEvents2 : IOfflineFilesEvents
{
	public new const Guid IID = .(0x1ead8f56, 0xff76, 0x4faa, 0xa7, 0x95, 0x6f, 0x6e, 0xf7, 0x92, 0x49, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesEvents.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ItemReconnectBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ItemReconnectEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CacheEvictBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CacheEvictEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSyncControlFlags) BackgroundSyncBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSyncControlFlags) BackgroundSyncEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PolicyChangeDetected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PreferenceChangeDetected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SettingsChangesApplied;
	}


	public HRESULT ItemReconnectBegin() mut => VT.[Friend]ItemReconnectBegin(&this);

	public HRESULT ItemReconnectEnd() mut => VT.[Friend]ItemReconnectEnd(&this);

	public HRESULT CacheEvictBegin() mut => VT.[Friend]CacheEvictBegin(&this);

	public HRESULT CacheEvictEnd() mut => VT.[Friend]CacheEvictEnd(&this);

	public HRESULT BackgroundSyncBegin(uint32 dwSyncControlFlags) mut => VT.[Friend]BackgroundSyncBegin(&this, dwSyncControlFlags);

	public HRESULT BackgroundSyncEnd(uint32 dwSyncControlFlags) mut => VT.[Friend]BackgroundSyncEnd(&this, dwSyncControlFlags);

	public HRESULT PolicyChangeDetected() mut => VT.[Friend]PolicyChangeDetected(&this);

	public HRESULT PreferenceChangeDetected() mut => VT.[Friend]PreferenceChangeDetected(&this);

	public HRESULT SettingsChangesApplied() mut => VT.[Friend]SettingsChangesApplied(&this);
}

[CRepr]struct IOfflineFilesEvents3 : IOfflineFilesEvents2
{
	public new const Guid IID = .(0x9ba04a45, 0xee69, 0x42f0, 0x9a, 0xb1, 0x7d, 0xb5, 0xc8, 0x80, 0x58, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesEvents2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, OFFLINEFILES_EVENTS EventType, OFFLINEFILES_ITEM_TYPE ItemType, BOOL bModifiedData, BOOL bModifiedAttributes, PWSTR pzsOldPath) TransparentCacheItemNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) PrefetchFileBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, HRESULT hrResult) PrefetchFileEnd;
	}


	public HRESULT TransparentCacheItemNotify(PWSTR pszPath, OFFLINEFILES_EVENTS EventType, OFFLINEFILES_ITEM_TYPE ItemType, BOOL bModifiedData, BOOL bModifiedAttributes, PWSTR pzsOldPath) mut => VT.[Friend]TransparentCacheItemNotify(&this, pszPath, EventType, ItemType, bModifiedData, bModifiedAttributes, pzsOldPath);

	public HRESULT PrefetchFileBegin(PWSTR pszPath) mut => VT.[Friend]PrefetchFileBegin(&this, pszPath);

	public HRESULT PrefetchFileEnd(PWSTR pszPath, HRESULT hrResult) mut => VT.[Friend]PrefetchFileEnd(&this, pszPath, hrResult);
}

[CRepr]struct IOfflineFilesEvents4 : IOfflineFilesEvents3
{
	public new const Guid IID = .(0xdbd69b1e, 0xc7d2, 0x473e, 0xb3, 0x5f, 0x9d, 0x8c, 0x24, 0xc0, 0xc4, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesEvents3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PrefetchCloseHandleBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwClosedHandleCount, uint32 dwOpenHandleCount, HRESULT hrResult) PrefetchCloseHandleEnd;
	}


	public HRESULT PrefetchCloseHandleBegin() mut => VT.[Friend]PrefetchCloseHandleBegin(&this);

	public HRESULT PrefetchCloseHandleEnd(uint32 dwClosedHandleCount, uint32 dwOpenHandleCount, HRESULT hrResult) mut => VT.[Friend]PrefetchCloseHandleEnd(&this, dwClosedHandleCount, dwOpenHandleCount, hrResult);
}

[CRepr]struct IOfflineFilesEventsFilter : IUnknown
{
	public new const Guid IID = .(0x33fc4e1b, 0x0716, 0x40fa, 0xba, 0x65, 0x6e, 0x62, 0xa8, 0x4a, 0x84, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszFilter, OFFLINEFILES_PATHFILTER_MATCH* pMatch) GetPathFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElements, OFFLINEFILES_EVENTS* prgEvents, uint32* pcEvents) GetIncludedEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElements, OFFLINEFILES_EVENTS* prgEvents, uint32* pcEvents) GetExcludedEvents;
	}


	public HRESULT GetPathFilter(PWSTR* ppszFilter, OFFLINEFILES_PATHFILTER_MATCH* pMatch) mut => VT.[Friend]GetPathFilter(&this, ppszFilter, pMatch);

	public HRESULT GetIncludedEvents(uint32 cElements, OFFLINEFILES_EVENTS* prgEvents, uint32* pcEvents) mut => VT.[Friend]GetIncludedEvents(&this, cElements, prgEvents, pcEvents);

	public HRESULT GetExcludedEvents(uint32 cElements, OFFLINEFILES_EVENTS* prgEvents, uint32* pcEvents) mut => VT.[Friend]GetExcludedEvents(&this, cElements, prgEvents, pcEvents);
}

[CRepr]struct IOfflineFilesErrorInfo : IUnknown
{
	public new const Guid IID = .(0x7112fa5f, 0x7571, 0x435a, 0x8e, 0xb7, 0x19, 0x5c, 0x7c, 0x14, 0x29, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BYTE_BLOB** ppBlob) GetRawData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszDescription) GetDescription;
	}


	public HRESULT GetRawData(BYTE_BLOB** ppBlob) mut => VT.[Friend]GetRawData(&this, ppBlob);

	public HRESULT GetDescription(PWSTR* ppszDescription) mut => VT.[Friend]GetDescription(&this, ppszDescription);
}

[CRepr]struct IOfflineFilesSyncErrorItemInfo : IUnknown
{
	public new const Guid IID = .(0xecdbaf0d, 0x6a18, 0x4d55, 0x80, 0x17, 0x10, 0x8f, 0x76, 0x60, 0xba, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes) GetFileAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftLastWrite, FILETIME* pftChange) GetFileTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER* pSize) GetFileSize;
	}


	public HRESULT GetFileAttributes(uint32* pdwAttributes) mut => VT.[Friend]GetFileAttributes(&this, pdwAttributes);

	public HRESULT GetFileTimes(FILETIME* pftLastWrite, FILETIME* pftChange) mut => VT.[Friend]GetFileTimes(&this, pftLastWrite, pftChange);

	public HRESULT GetFileSize(LARGE_INTEGER* pSize) mut => VT.[Friend]GetFileSize(&this, pSize);
}

[CRepr]struct IOfflineFilesSyncErrorInfo : IOfflineFilesErrorInfo
{
	public new const Guid IID = .(0x59f95e46, 0xeb54, 0x49d1, 0xbe, 0x76, 0xde, 0x95, 0x45, 0x8d, 0x01, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesErrorInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_SYNC_OPERATION* pSyncOp) GetSyncOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwItemChangeFlags) GetItemChangeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbLocalEnumerated, BOOL* pbRemoteEnumerated, BOOL* pbOriginalEnumerated) InfoEnumerated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbLocalInfo, BOOL* pbRemoteInfo, BOOL* pbOriginalInfo) InfoAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesSyncErrorItemInfo** ppInfo) GetLocalInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesSyncErrorItemInfo** ppInfo) GetRemoteInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesSyncErrorItemInfo** ppInfo) GetOriginalInfo;
	}


	public HRESULT GetSyncOperation(OFFLINEFILES_SYNC_OPERATION* pSyncOp) mut => VT.[Friend]GetSyncOperation(&this, pSyncOp);

	public HRESULT GetItemChangeFlags(uint32* pdwItemChangeFlags) mut => VT.[Friend]GetItemChangeFlags(&this, pdwItemChangeFlags);

	public HRESULT InfoEnumerated(BOOL* pbLocalEnumerated, BOOL* pbRemoteEnumerated, BOOL* pbOriginalEnumerated) mut => VT.[Friend]InfoEnumerated(&this, pbLocalEnumerated, pbRemoteEnumerated, pbOriginalEnumerated);

	public HRESULT InfoAvailable(BOOL* pbLocalInfo, BOOL* pbRemoteInfo, BOOL* pbOriginalInfo) mut => VT.[Friend]InfoAvailable(&this, pbLocalInfo, pbRemoteInfo, pbOriginalInfo);

	public HRESULT GetLocalInfo(IOfflineFilesSyncErrorItemInfo** ppInfo) mut => VT.[Friend]GetLocalInfo(&this, ppInfo);

	public HRESULT GetRemoteInfo(IOfflineFilesSyncErrorItemInfo** ppInfo) mut => VT.[Friend]GetRemoteInfo(&this, ppInfo);

	public HRESULT GetOriginalInfo(IOfflineFilesSyncErrorItemInfo** ppInfo) mut => VT.[Friend]GetOriginalInfo(&this, ppInfo);
}

[CRepr]struct IOfflineFilesProgress : IUnknown
{
	public new const Guid IID = .(0xfad63237, 0xc55b, 0x4911, 0x98, 0x50, 0xbc, 0xf9, 0x6d, 0x4c, 0x97, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbAbort) Begin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbAbort) QueryAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrResult) End;
	}


	public HRESULT Begin(BOOL* pbAbort) mut => VT.[Friend]Begin(&this, pbAbort);

	public HRESULT QueryAbort(BOOL* pbAbort) mut => VT.[Friend]QueryAbort(&this, pbAbort);

	public HRESULT End(HRESULT hrResult) mut => VT.[Friend]End(&this, hrResult);
}

[CRepr]struct IOfflineFilesSimpleProgress : IOfflineFilesProgress
{
	public new const Guid IID = .(0xc34f7f9b, 0xc43d, 0x4f9d, 0xa7, 0x76, 0xc0, 0xeb, 0x6d, 0xe5, 0xd4, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesProgress.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, OFFLINEFILES_OP_RESPONSE* pResponse) ItemBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, HRESULT hrResult, OFFLINEFILES_OP_RESPONSE* pResponse) ItemResult;
	}


	public HRESULT ItemBegin(PWSTR pszFile, OFFLINEFILES_OP_RESPONSE* pResponse) mut => VT.[Friend]ItemBegin(&this, pszFile, pResponse);

	public HRESULT ItemResult(PWSTR pszFile, HRESULT hrResult, OFFLINEFILES_OP_RESPONSE* pResponse) mut => VT.[Friend]ItemResult(&this, pszFile, hrResult, pResponse);
}

[CRepr]struct IOfflineFilesSyncProgress : IOfflineFilesProgress
{
	public new const Guid IID = .(0x6931f49a, 0x6fc7, 0x4c1b, 0xb2, 0x65, 0x56, 0x79, 0x3f, 0xc4, 0x51, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesProgress.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, OFFLINEFILES_OP_RESPONSE* pResponse) SyncItemBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, HRESULT hrResult, IOfflineFilesSyncErrorInfo* pErrorInfo, OFFLINEFILES_OP_RESPONSE* pResponse) SyncItemResult;
	}


	public HRESULT SyncItemBegin(PWSTR pszFile, OFFLINEFILES_OP_RESPONSE* pResponse) mut => VT.[Friend]SyncItemBegin(&this, pszFile, pResponse);

	public HRESULT SyncItemResult(PWSTR pszFile, HRESULT hrResult, IOfflineFilesSyncErrorInfo* pErrorInfo, OFFLINEFILES_OP_RESPONSE* pResponse) mut => VT.[Friend]SyncItemResult(&this, pszFile, hrResult, pErrorInfo, pResponse);
}

[CRepr]struct IOfflineFilesSyncConflictHandler : IUnknown
{
	public new const Guid IID = .(0xb6dd5092, 0xc65c, 0x46b6, 0x97, 0xb8, 0xfa, 0xdd, 0x08, 0xe7, 0xe1, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, uint32 fStateKnown, OFFLINEFILES_SYNC_STATE state, uint32 fChangeDetails, OFFLINEFILES_SYNC_CONFLICT_RESOLVE* pConflictResolution, PWSTR* ppszNewName) ResolveConflict;
	}


	public HRESULT ResolveConflict(PWSTR pszPath, uint32 fStateKnown, OFFLINEFILES_SYNC_STATE state, uint32 fChangeDetails, OFFLINEFILES_SYNC_CONFLICT_RESOLVE* pConflictResolution, PWSTR* ppszNewName) mut => VT.[Friend]ResolveConflict(&this, pszPath, fStateKnown, state, fChangeDetails, pConflictResolution, ppszNewName);
}

[CRepr]struct IOfflineFilesItemFilter : IUnknown
{
	public new const Guid IID = .(0xf4b5a26c, 0xdc05, 0x4f20, 0xad, 0xa4, 0x55, 0x1f, 0x10, 0x77, 0xbe, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullFlags, uint64* pullMask) GetFilterFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftTime, BOOL* pbEvalTimeOfDay, OFFLINEFILES_ITEM_TIME* pTimeType, OFFLINEFILES_COMPARE* pCompare) GetTimeFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszPattern, uint32 cchPattern) GetPatternFilter;
	}


	public HRESULT GetFilterFlags(uint64* pullFlags, uint64* pullMask) mut => VT.[Friend]GetFilterFlags(&this, pullFlags, pullMask);

	public HRESULT GetTimeFilter(FILETIME* pftTime, BOOL* pbEvalTimeOfDay, OFFLINEFILES_ITEM_TIME* pTimeType, OFFLINEFILES_COMPARE* pCompare) mut => VT.[Friend]GetTimeFilter(&this, pftTime, pbEvalTimeOfDay, pTimeType, pCompare);

	public HRESULT GetPatternFilter(char16* pszPattern, uint32 cchPattern) mut => VT.[Friend]GetPatternFilter(&this, pszPattern, cchPattern);
}

[CRepr]struct IOfflineFilesItem : IUnknown
{
	public new const Guid IID = .(0x4a753da6, 0xe044, 0x4f12, 0xa7, 0x18, 0x5d, 0x14, 0xd0, 0x79, 0xa9, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_ITEM_TYPE* pItemType) GetItemType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesItem** ppItem) GetParentItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwQueryFlags) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbMarkedForDeletion) IsMarkedForDeletion;
	}


	public HRESULT GetItemType(OFFLINEFILES_ITEM_TYPE* pItemType) mut => VT.[Friend]GetItemType(&this, pItemType);

	public HRESULT GetPath(PWSTR* ppszPath) mut => VT.[Friend]GetPath(&this, ppszPath);

	public HRESULT GetParentItem(IOfflineFilesItem** ppItem) mut => VT.[Friend]GetParentItem(&this, ppItem);

	public HRESULT Refresh(uint32 dwQueryFlags) mut => VT.[Friend]Refresh(&this, dwQueryFlags);

	public HRESULT IsMarkedForDeletion(BOOL* pbMarkedForDeletion) mut => VT.[Friend]IsMarkedForDeletion(&this, pbMarkedForDeletion);
}

[CRepr]struct IOfflineFilesServerItem : IOfflineFilesItem
{
	public new const Guid IID = .(0x9b1c9576, 0xa92b, 0x4151, 0x8e, 0x9e, 0x7c, 0x7b, 0x3e, 0xc2, 0xe0, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesItem.VTable
	{
	}

}

[CRepr]struct IOfflineFilesShareItem : IOfflineFilesItem
{
	public new const Guid IID = .(0xbab7e48d, 0x4804, 0x41b5, 0xa4, 0x4d, 0x0f, 0x19, 0x9b, 0x06, 0xb1, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesItem.VTable
	{
	}

}

[CRepr]struct IOfflineFilesDirectoryItem : IOfflineFilesItem
{
	public new const Guid IID = .(0x2273597a, 0xa08c, 0x4a00, 0xa3, 0x7a, 0xc1, 0xae, 0x4e, 0x9a, 0x1c, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesItem.VTable
	{
	}

}

[CRepr]struct IOfflineFilesFileItem : IOfflineFilesItem
{
	public new const Guid IID = .(0x8dfadead, 0x26c2, 0x4eff, 0x8a, 0x72, 0x6b, 0x50, 0x72, 0x3d, 0x9a, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsSparse) IsSparse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsEncrypted) IsEncrypted;
	}


	public HRESULT IsSparse(BOOL* pbIsSparse) mut => VT.[Friend]IsSparse(&this, pbIsSparse);

	public HRESULT IsEncrypted(BOOL* pbIsEncrypted) mut => VT.[Friend]IsEncrypted(&this, pbIsEncrypted);
}

[CRepr]struct IEnumOfflineFilesItems : IUnknown
{
	public new const Guid IID = .(0xda70e815, 0xc361, 0x4407, 0xbc, 0x0b, 0x0d, 0x70, 0x46, 0xe5, 0xf2, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IOfflineFilesItem** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOfflineFilesItems** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, IOfflineFilesItem** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumOfflineFilesItems** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IOfflineFilesItemContainer : IUnknown
{
	public new const Guid IID = .(0x3836f049, 0x9413, 0x45dd, 0xbf, 0x46, 0xb5, 0xaa, 0xa8, 0x2d, 0xc3, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwQueryFlags, IEnumOfflineFilesItems** ppenum) EnumItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesItemFilter* pIncludeFileFilter, IOfflineFilesItemFilter* pIncludeDirFilter, IOfflineFilesItemFilter* pExcludeFileFilter, IOfflineFilesItemFilter* pExcludeDirFilter, uint32 dwEnumFlags, uint32 dwQueryFlags, IEnumOfflineFilesItems** ppenum) EnumItemsEx;
	}


	public HRESULT EnumItems(uint32 dwQueryFlags, IEnumOfflineFilesItems** ppenum) mut => VT.[Friend]EnumItems(&this, dwQueryFlags, ppenum);

	public HRESULT EnumItemsEx(IOfflineFilesItemFilter* pIncludeFileFilter, IOfflineFilesItemFilter* pIncludeDirFilter, IOfflineFilesItemFilter* pExcludeFileFilter, IOfflineFilesItemFilter* pExcludeDirFilter, uint32 dwEnumFlags, uint32 dwQueryFlags, IEnumOfflineFilesItems** ppenum) mut => VT.[Friend]EnumItemsEx(&this, pIncludeFileFilter, pIncludeDirFilter, pExcludeFileFilter, pExcludeDirFilter, dwEnumFlags, dwQueryFlags, ppenum);
}

[CRepr]struct IOfflineFilesChangeInfo : IUnknown
{
	public new const Guid IID = .(0xa96e6fa4, 0xe0d1, 0x4c29, 0x96, 0x0b, 0xee, 0x50, 0x8f, 0xe6, 0x8c, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbDirty) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbDeletedOffline) IsDeletedOffline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbCreatedOffline) IsCreatedOffline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbLocallyModifiedData) IsLocallyModifiedData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbLocallyModifiedAttributes) IsLocallyModifiedAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbLocallyModifiedTime) IsLocallyModifiedTime;
	}


	public HRESULT IsDirty(BOOL* pbDirty) mut => VT.[Friend]IsDirty(&this, pbDirty);

	public HRESULT IsDeletedOffline(BOOL* pbDeletedOffline) mut => VT.[Friend]IsDeletedOffline(&this, pbDeletedOffline);

	public HRESULT IsCreatedOffline(BOOL* pbCreatedOffline) mut => VT.[Friend]IsCreatedOffline(&this, pbCreatedOffline);

	public HRESULT IsLocallyModifiedData(BOOL* pbLocallyModifiedData) mut => VT.[Friend]IsLocallyModifiedData(&this, pbLocallyModifiedData);

	public HRESULT IsLocallyModifiedAttributes(BOOL* pbLocallyModifiedAttributes) mut => VT.[Friend]IsLocallyModifiedAttributes(&this, pbLocallyModifiedAttributes);

	public HRESULT IsLocallyModifiedTime(BOOL* pbLocallyModifiedTime) mut => VT.[Friend]IsLocallyModifiedTime(&this, pbLocallyModifiedTime);
}

[CRepr]struct IOfflineFilesDirtyInfo : IUnknown
{
	public new const Guid IID = .(0x0f50ce33, 0xbac9, 0x4eaa, 0xa1, 0x1d, 0xda, 0x0e, 0x52, 0x7d, 0x04, 0x7d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER* pDirtyByteCount) LocalDirtyByteCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER* pDirtyByteCount) RemoteDirtyByteCount;
	}


	public HRESULT LocalDirtyByteCount(LARGE_INTEGER* pDirtyByteCount) mut => VT.[Friend]LocalDirtyByteCount(&this, pDirtyByteCount);

	public HRESULT RemoteDirtyByteCount(LARGE_INTEGER* pDirtyByteCount) mut => VT.[Friend]RemoteDirtyByteCount(&this, pDirtyByteCount);
}

[CRepr]struct IOfflineFilesFileSysInfo : IUnknown
{
	public new const Guid IID = .(0xbc1a163f, 0x7bfd, 0x4d88, 0x9c, 0x66, 0x96, 0xea, 0x9a, 0x6a, 0x3d, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_ITEM_COPY copy, uint32* pdwAttributes) GetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_ITEM_COPY copy, FILETIME* pftCreationTime, FILETIME* pftLastWriteTime, FILETIME* pftChangeTime, FILETIME* pftLastAccessTime) GetTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_ITEM_COPY copy, LARGE_INTEGER* pSize) GetFileSize;
	}


	public HRESULT GetAttributes(OFFLINEFILES_ITEM_COPY copy, uint32* pdwAttributes) mut => VT.[Friend]GetAttributes(&this, copy, pdwAttributes);

	public HRESULT GetTimes(OFFLINEFILES_ITEM_COPY copy, FILETIME* pftCreationTime, FILETIME* pftLastWriteTime, FILETIME* pftChangeTime, FILETIME* pftLastAccessTime) mut => VT.[Friend]GetTimes(&this, copy, pftCreationTime, pftLastWriteTime, pftChangeTime, pftLastAccessTime);

	public HRESULT GetFileSize(OFFLINEFILES_ITEM_COPY copy, LARGE_INTEGER* pSize) mut => VT.[Friend]GetFileSize(&this, copy, pSize);
}

[CRepr]struct IOfflineFilesPinInfo : IUnknown
{
	public new const Guid IID = .(0x5b2b0655, 0xb3fd, 0x497d, 0xad, 0xeb, 0xbd, 0x15, 0x6b, 0xc8, 0x35, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPinned) IsPinned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPinnedForUser, BOOL* pbInherit) IsPinnedForUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPinnedForUser, BOOL* pbInherit) IsPinnedForUserByPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPinnedForComputer, BOOL* pbInherit) IsPinnedForComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPinnedForFolderRedirection, BOOL* pbInherit) IsPinnedForFolderRedirection;
	}


	public HRESULT IsPinned(BOOL* pbPinned) mut => VT.[Friend]IsPinned(&this, pbPinned);

	public HRESULT IsPinnedForUser(BOOL* pbPinnedForUser, BOOL* pbInherit) mut => VT.[Friend]IsPinnedForUser(&this, pbPinnedForUser, pbInherit);

	public HRESULT IsPinnedForUserByPolicy(BOOL* pbPinnedForUser, BOOL* pbInherit) mut => VT.[Friend]IsPinnedForUserByPolicy(&this, pbPinnedForUser, pbInherit);

	public HRESULT IsPinnedForComputer(BOOL* pbPinnedForComputer, BOOL* pbInherit) mut => VT.[Friend]IsPinnedForComputer(&this, pbPinnedForComputer, pbInherit);

	public HRESULT IsPinnedForFolderRedirection(BOOL* pbPinnedForFolderRedirection, BOOL* pbInherit) mut => VT.[Friend]IsPinnedForFolderRedirection(&this, pbPinnedForFolderRedirection, pbInherit);
}

[CRepr]struct IOfflineFilesPinInfo2 : IOfflineFilesPinInfo
{
	public new const Guid IID = .(0x623c58a2, 0x42ed, 0x4ad7, 0xb6, 0x9a, 0x0f, 0x1b, 0x30, 0xa7, 0x2d, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesPinInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPartlyPinned) IsPartlyPinned;
	}


	public HRESULT IsPartlyPinned(BOOL* pbPartlyPinned) mut => VT.[Friend]IsPartlyPinned(&this, pbPartlyPinned);
}

[CRepr]struct IOfflineFilesTransparentCacheInfo : IUnknown
{
	public new const Guid IID = .(0xbcaf4a01, 0x5b68, 0x4b56, 0xa6, 0xa1, 0x8d, 0x27, 0x86, 0xed, 0xe8, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbTransparentlyCached) IsTransparentlyCached;
	}


	public HRESULT IsTransparentlyCached(BOOL* pbTransparentlyCached) mut => VT.[Friend]IsTransparentlyCached(&this, pbTransparentlyCached);
}

[CRepr]struct IOfflineFilesGhostInfo : IUnknown
{
	public new const Guid IID = .(0x2b09d48c, 0x8ab5, 0x464f, 0xa7, 0x55, 0xa5, 0x9d, 0x92, 0xf9, 0x94, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbGhosted) IsGhosted;
	}


	public HRESULT IsGhosted(BOOL* pbGhosted) mut => VT.[Friend]IsGhosted(&this, pbGhosted);
}

[CRepr]struct IOfflineFilesConnectionInfo : IUnknown
{
	public new const Guid IID = .(0xefb23a09, 0xa867, 0x4be8, 0x83, 0xa6, 0x86, 0x96, 0x9a, 0x7d, 0x08, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_CONNECT_STATE* pConnectState, OFFLINEFILES_OFFLINE_REASON* pOfflineReason) GetConnectState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint32 dwFlags, OFFLINEFILES_CONNECT_STATE ConnectState) SetConnectState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint32 dwFlags) TransitionOnline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint32 dwFlags, BOOL bForceOpenFilesClosed, BOOL* pbOpenFilesPreventedTransition) TransitionOffline;
	}


	public HRESULT GetConnectState(OFFLINEFILES_CONNECT_STATE* pConnectState, OFFLINEFILES_OFFLINE_REASON* pOfflineReason) mut => VT.[Friend]GetConnectState(&this, pConnectState, pOfflineReason);

	public HRESULT SetConnectState(HWND hwndParent, uint32 dwFlags, OFFLINEFILES_CONNECT_STATE ConnectState) mut => VT.[Friend]SetConnectState(&this, hwndParent, dwFlags, ConnectState);

	public HRESULT TransitionOnline(HWND hwndParent, uint32 dwFlags) mut => VT.[Friend]TransitionOnline(&this, hwndParent, dwFlags);

	public HRESULT TransitionOffline(HWND hwndParent, uint32 dwFlags, BOOL bForceOpenFilesClosed, BOOL* pbOpenFilesPreventedTransition) mut => VT.[Friend]TransitionOffline(&this, hwndParent, dwFlags, bForceOpenFilesClosed, pbOpenFilesPreventedTransition);
}

[CRepr]struct IOfflineFilesShareInfo : IUnknown
{
	public new const Guid IID = .(0x7bcc43e7, 0x31ce, 0x4ca4, 0x8c, 0xcd, 0x1c, 0xff, 0x2d, 0xc4, 0x94, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesShareItem** ppShareItem) GetShareItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_CACHING_MODE* pCachingMode) GetShareCachingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsDfsJunction) IsShareDfsJunction;
	}


	public HRESULT GetShareItem(IOfflineFilesShareItem** ppShareItem) mut => VT.[Friend]GetShareItem(&this, ppShareItem);

	public HRESULT GetShareCachingMode(OFFLINEFILES_CACHING_MODE* pCachingMode) mut => VT.[Friend]GetShareCachingMode(&this, pCachingMode);

	public HRESULT IsShareDfsJunction(BOOL* pbIsDfsJunction) mut => VT.[Friend]IsShareDfsJunction(&this, pbIsDfsJunction);
}

[CRepr]struct IOfflineFilesSuspend : IUnknown
{
	public new const Guid IID = .(0x62c4560f, 0xbc0b, 0x48ca, 0xad, 0x9d, 0x34, 0xcb, 0x52, 0x8d, 0x99, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bSuspend) SuspendRoot;
	}


	public HRESULT SuspendRoot(BOOL bSuspend) mut => VT.[Friend]SuspendRoot(&this, bSuspend);
}

[CRepr]struct IOfflineFilesSuspendInfo : IUnknown
{
	public new const Guid IID = .(0xa457c25b, 0x4e9c, 0x4b04, 0x85, 0xaf, 0x89, 0x32, 0xcc, 0xd9, 0x78, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbSuspended, BOOL* pbSuspendedRoot) IsSuspended;
	}


	public HRESULT IsSuspended(BOOL* pbSuspended, BOOL* pbSuspendedRoot) mut => VT.[Friend]IsSuspended(&this, pbSuspended, pbSuspendedRoot);
}

[CRepr]struct IOfflineFilesSetting : IUnknown
{
	public new const Guid IID = .(0xd871d3f7, 0xf613, 0x48a1, 0x82, 0x7e, 0x7a, 0x34, 0xe5, 0x60, 0xff, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OFFLINEFILES_SETTING_VALUE_TYPE* pType) GetValueType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue, uint32 dwScope) GetPreference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwScope) GetPreferenceScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue, uint32 dwScope) SetPreference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwScope) DeletePreference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue, uint32 dwScope) GetPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwScope) GetPolicyScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue, BOOL* pbSetByPolicy) GetValue;
	}


	public HRESULT GetName(PWSTR* ppszName) mut => VT.[Friend]GetName(&this, ppszName);

	public HRESULT GetValueType(OFFLINEFILES_SETTING_VALUE_TYPE* pType) mut => VT.[Friend]GetValueType(&this, pType);

	public HRESULT GetPreference(VARIANT* pvarValue, uint32 dwScope) mut => VT.[Friend]GetPreference(&this, pvarValue, dwScope);

	public HRESULT GetPreferenceScope(uint32* pdwScope) mut => VT.[Friend]GetPreferenceScope(&this, pdwScope);

	public HRESULT SetPreference(VARIANT* pvarValue, uint32 dwScope) mut => VT.[Friend]SetPreference(&this, pvarValue, dwScope);

	public HRESULT DeletePreference(uint32 dwScope) mut => VT.[Friend]DeletePreference(&this, dwScope);

	public HRESULT GetPolicy(VARIANT* pvarValue, uint32 dwScope) mut => VT.[Friend]GetPolicy(&this, pvarValue, dwScope);

	public HRESULT GetPolicyScope(uint32* pdwScope) mut => VT.[Friend]GetPolicyScope(&this, pdwScope);

	public HRESULT GetValue(VARIANT* pvarValue, BOOL* pbSetByPolicy) mut => VT.[Friend]GetValue(&this, pvarValue, pbSetByPolicy);
}

[CRepr]struct IEnumOfflineFilesSettings : IUnknown
{
	public new const Guid IID = .(0x729680c4, 0x1a38, 0x47bc, 0x9e, 0x5c, 0x02, 0xc5, 0x15, 0x62, 0xac, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IOfflineFilesSetting** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOfflineFilesSettings** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, IOfflineFilesSetting** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumOfflineFilesSettings** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IOfflineFilesCache : IUnknown
{
	public new const Guid IID = .(0x855d6203, 0x7914, 0x48b9, 0x8d, 0x40, 0x4c, 0x56, 0xf5, 0xac, 0xff, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR* rgpszPaths, uint32 cPaths, BOOL bAsync, uint32 dwSyncControl, IOfflineFilesSyncConflictHandler* pISyncConflictHandler, IOfflineFilesSyncProgress* pIProgress, Guid* pSyncId) Synchronize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* rgpszPaths, uint32 cPaths, uint32 dwFlags, BOOL bAsync, IOfflineFilesSimpleProgress* pIProgress) DeleteItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUser, PWSTR* rgpszPaths, uint32 cPaths, uint32 dwFlags, BOOL bAsync, IOfflineFilesSimpleProgress* pIProgress) DeleteItemsForUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR* rgpszPaths, uint32 cPaths, BOOL bDeep, BOOL bAsync, uint32 dwPinControlFlags, IOfflineFilesSyncProgress* pIProgress) Pin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR* rgpszPaths, uint32 cPaths, BOOL bDeep, BOOL bAsync, uint32 dwPinControlFlags, IOfflineFilesSyncProgress* pIProgress) Unpin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbEncrypted, BOOL* pbPartial) GetEncryptionStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, BOOL bEncrypt, uint32 dwEncryptionControlFlags, BOOL bAsync, IOfflineFilesSyncProgress* pIProgress) Encrypt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, uint32 dwQueryFlags, IOfflineFilesItem** ppItem) FindItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, IOfflineFilesItemFilter* pIncludeFileFilter, IOfflineFilesItemFilter* pIncludeDirFilter, IOfflineFilesItemFilter* pExcludeFileFilter, IOfflineFilesItemFilter* pExcludeDirFilter, uint32 dwQueryFlags, IOfflineFilesItem** ppItem) FindItemEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPathOriginal, PWSTR pszPathNew, BOOL bReplaceIfExists) RenameItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) GetLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pcbVolumeTotal, uint64* pcbLimit, uint64* pcbUsed, uint64* pcbUnpinnedLimit, uint64* pcbUnpinnedUsed) GetDiskSpaceInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 cbLimit, uint64 cbUnpinnedLimit) SetDiskSpaceLimits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOfflineFilesSyncProgress* pPinProgress, IOfflineFilesSyncProgress* pUnpinProgress) ProcessAdminPinPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSettingName, IOfflineFilesSetting** ppSetting) GetSettingObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumOfflineFilesSettings** ppEnum) EnumSettingObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, BOOL* pbCacheable, OFFLINEFILES_CACHING_MODE* pShareCachingMode) IsPathCacheable;
	}


	public HRESULT Synchronize(HWND hwndParent, PWSTR* rgpszPaths, uint32 cPaths, BOOL bAsync, uint32 dwSyncControl, IOfflineFilesSyncConflictHandler* pISyncConflictHandler, IOfflineFilesSyncProgress* pIProgress, Guid* pSyncId) mut => VT.[Friend]Synchronize(&this, hwndParent, rgpszPaths, cPaths, bAsync, dwSyncControl, pISyncConflictHandler, pIProgress, pSyncId);

	public HRESULT DeleteItems(PWSTR* rgpszPaths, uint32 cPaths, uint32 dwFlags, BOOL bAsync, IOfflineFilesSimpleProgress* pIProgress) mut => VT.[Friend]DeleteItems(&this, rgpszPaths, cPaths, dwFlags, bAsync, pIProgress);

	public HRESULT DeleteItemsForUser(PWSTR pszUser, PWSTR* rgpszPaths, uint32 cPaths, uint32 dwFlags, BOOL bAsync, IOfflineFilesSimpleProgress* pIProgress) mut => VT.[Friend]DeleteItemsForUser(&this, pszUser, rgpszPaths, cPaths, dwFlags, bAsync, pIProgress);

	public HRESULT Pin(HWND hwndParent, PWSTR* rgpszPaths, uint32 cPaths, BOOL bDeep, BOOL bAsync, uint32 dwPinControlFlags, IOfflineFilesSyncProgress* pIProgress) mut => VT.[Friend]Pin(&this, hwndParent, rgpszPaths, cPaths, bDeep, bAsync, dwPinControlFlags, pIProgress);

	public HRESULT Unpin(HWND hwndParent, PWSTR* rgpszPaths, uint32 cPaths, BOOL bDeep, BOOL bAsync, uint32 dwPinControlFlags, IOfflineFilesSyncProgress* pIProgress) mut => VT.[Friend]Unpin(&this, hwndParent, rgpszPaths, cPaths, bDeep, bAsync, dwPinControlFlags, pIProgress);

	public HRESULT GetEncryptionStatus(BOOL* pbEncrypted, BOOL* pbPartial) mut => VT.[Friend]GetEncryptionStatus(&this, pbEncrypted, pbPartial);

	public HRESULT Encrypt(HWND hwndParent, BOOL bEncrypt, uint32 dwEncryptionControlFlags, BOOL bAsync, IOfflineFilesSyncProgress* pIProgress) mut => VT.[Friend]Encrypt(&this, hwndParent, bEncrypt, dwEncryptionControlFlags, bAsync, pIProgress);

	public HRESULT FindItem(PWSTR pszPath, uint32 dwQueryFlags, IOfflineFilesItem** ppItem) mut => VT.[Friend]FindItem(&this, pszPath, dwQueryFlags, ppItem);

	public HRESULT FindItemEx(PWSTR pszPath, IOfflineFilesItemFilter* pIncludeFileFilter, IOfflineFilesItemFilter* pIncludeDirFilter, IOfflineFilesItemFilter* pExcludeFileFilter, IOfflineFilesItemFilter* pExcludeDirFilter, uint32 dwQueryFlags, IOfflineFilesItem** ppItem) mut => VT.[Friend]FindItemEx(&this, pszPath, pIncludeFileFilter, pIncludeDirFilter, pExcludeFileFilter, pExcludeDirFilter, dwQueryFlags, ppItem);

	public HRESULT RenameItem(PWSTR pszPathOriginal, PWSTR pszPathNew, BOOL bReplaceIfExists) mut => VT.[Friend]RenameItem(&this, pszPathOriginal, pszPathNew, bReplaceIfExists);

	public HRESULT GetLocation(PWSTR* ppszPath) mut => VT.[Friend]GetLocation(&this, ppszPath);

	public HRESULT GetDiskSpaceInformation(uint64* pcbVolumeTotal, uint64* pcbLimit, uint64* pcbUsed, uint64* pcbUnpinnedLimit, uint64* pcbUnpinnedUsed) mut => VT.[Friend]GetDiskSpaceInformation(&this, pcbVolumeTotal, pcbLimit, pcbUsed, pcbUnpinnedLimit, pcbUnpinnedUsed);

	public HRESULT SetDiskSpaceLimits(uint64 cbLimit, uint64 cbUnpinnedLimit) mut => VT.[Friend]SetDiskSpaceLimits(&this, cbLimit, cbUnpinnedLimit);

	public HRESULT ProcessAdminPinPolicy(IOfflineFilesSyncProgress* pPinProgress, IOfflineFilesSyncProgress* pUnpinProgress) mut => VT.[Friend]ProcessAdminPinPolicy(&this, pPinProgress, pUnpinProgress);

	public HRESULT GetSettingObject(PWSTR pszSettingName, IOfflineFilesSetting** ppSetting) mut => VT.[Friend]GetSettingObject(&this, pszSettingName, ppSetting);

	public HRESULT EnumSettingObjects(IEnumOfflineFilesSettings** ppEnum) mut => VT.[Friend]EnumSettingObjects(&this, ppEnum);

	public HRESULT IsPathCacheable(PWSTR pszPath, BOOL* pbCacheable, OFFLINEFILES_CACHING_MODE* pShareCachingMode) mut => VT.[Friend]IsPathCacheable(&this, pszPath, pbCacheable, pShareCachingMode);
}

[CRepr]struct IOfflineFilesCache2 : IOfflineFilesCache
{
	public new const Guid IID = .(0x8c075039, 0x1551, 0x4ed9, 0x87, 0x81, 0x56, 0x70, 0x5c, 0x04, 0xd3, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOfflineFilesCache.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPathOriginal, PWSTR pszPathNew, BOOL bReplaceIfExists) RenameItemEx;
	}


	public HRESULT RenameItemEx(PWSTR pszPathOriginal, PWSTR pszPathNew, BOOL bReplaceIfExists) mut => VT.[Friend]RenameItemEx(&this, pszPathOriginal, pszPathNew, bReplaceIfExists);
}

#endregion

#region Functions
public static
{
	[Import("CSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineFilesEnable(BOOL bEnable, BOOL* pbRebootRequired);

	[Import("CSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineFilesStart();

	[Import("CSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineFilesQueryStatus(BOOL* pbActive, BOOL* pbEnabled);

	[Import("CSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineFilesQueryStatusEx(BOOL* pbActive, BOOL* pbEnabled, BOOL* pbAvailable);

}
#endregion
