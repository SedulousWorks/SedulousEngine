using Win32.System.Com;
using Win32.Foundation;
using Win32.System.DistributedTransactionCoordinator;
using System;

namespace Win32.System.ComponentServices;

#region Constants
public static
{
	public const String TRACKER_STARTSTOP_EVENT = "Global\\COM+ Tracker Push Event";
	public const String TRACKER_INIT_EVENT = "Global\\COM+ Tracker Init Event";
	public const uint32 GUID_STRING_SIZE = 40;
	public const uint32 DATA_NOT_AVAILABLE = 4294967295;
	public const uint32 MTXDM_E_ENLISTRESOURCEFAILED = 2147803392;
	public const uint32 CRR_NO_REASON_SUPPLIED = 0;
	public const uint32 CRR_LIFETIME_LIMIT = 4294967295;
	public const uint32 CRR_ACTIVATION_LIMIT = 4294967294;
	public const uint32 CRR_CALL_LIMIT = 4294967293;
	public const uint32 CRR_MEMORY_LIMIT = 4294967292;
	public const uint32 CRR_RECYCLED_FROM_UI = 4294967291;
}
#endregion

#region Enums

[AllowDuplicates]
public enum COMAdminInUse : int32
{
	COMAdminNotInUse = 0,
	COMAdminInUseByCatalog = 1,
	COMAdminInUseByRegistryUnknown = 2,
	COMAdminInUseByRegistryProxyStub = 3,
	COMAdminInUseByRegistryTypeLib = 4,
	COMAdminInUseByRegistryClsid = 5,
}


[AllowDuplicates]
public enum COMAdminComponentType : int32
{
	COMAdmin32BitComponent = 1,
	COMAdmin64BitComponent = 2,
}


[AllowDuplicates]
public enum COMAdminApplicationInstallOptions : int32
{
	COMAdminInstallNoUsers = 0,
	COMAdminInstallUsers = 1,
	COMAdminInstallForceOverwriteOfFiles = 2,
}


[AllowDuplicates]
public enum COMAdminApplicationExportOptions : int32
{
	COMAdminExportNoUsers = 0,
	COMAdminExportUsers = 1,
	COMAdminExportApplicationProxy = 2,
	COMAdminExportForceOverwriteOfFiles = 4,
	COMAdminExportIn10Format = 16,
}


[AllowDuplicates]
public enum COMAdminThreadingModels : int32
{
	COMAdminThreadingModelApartment = 0,
	COMAdminThreadingModelFree = 1,
	COMAdminThreadingModelMain = 2,
	COMAdminThreadingModelBoth = 3,
	COMAdminThreadingModelNeutral = 4,
	COMAdminThreadingModelNotSpecified = 5,
}


[AllowDuplicates]
public enum COMAdminTransactionOptions : int32
{
	COMAdminTransactionIgnored = 0,
	COMAdminTransactionNone = 1,
	COMAdminTransactionSupported = 2,
	COMAdminTransactionRequired = 3,
	COMAdminTransactionRequiresNew = 4,
}


[AllowDuplicates]
public enum COMAdminTxIsolationLevelOptions : int32
{
	COMAdminTxIsolationLevelAny = 0,
	COMAdminTxIsolationLevelReadUnCommitted = 1,
	COMAdminTxIsolationLevelReadCommitted = 2,
	COMAdminTxIsolationLevelRepeatableRead = 3,
	COMAdminTxIsolationLevelSerializable = 4,
}


[AllowDuplicates]
public enum COMAdminSynchronizationOptions : int32
{
	COMAdminSynchronizationIgnored = 0,
	COMAdminSynchronizationNone = 1,
	COMAdminSynchronizationSupported = 2,
	COMAdminSynchronizationRequired = 3,
	COMAdminSynchronizationRequiresNew = 4,
}


[AllowDuplicates]
public enum COMAdminActivationOptions : int32
{
	COMAdminActivationInproc = 0,
	COMAdminActivationLocal = 1,
}


[AllowDuplicates]
public enum COMAdminAccessChecksLevelOptions : int32
{
	COMAdminAccessChecksApplicationLevel = 0,
	COMAdminAccessChecksApplicationComponentLevel = 1,
}


[AllowDuplicates]
public enum COMAdminAuthenticationLevelOptions : int32
{
	COMAdminAuthenticationDefault = 0,
	COMAdminAuthenticationNone = 1,
	COMAdminAuthenticationConnect = 2,
	COMAdminAuthenticationCall = 3,
	COMAdminAuthenticationPacket = 4,
	COMAdminAuthenticationIntegrity = 5,
	COMAdminAuthenticationPrivacy = 6,
}


[AllowDuplicates]
public enum COMAdminImpersonationLevelOptions : int32
{
	COMAdminImpersonationAnonymous = 1,
	COMAdminImpersonationIdentify = 2,
	COMAdminImpersonationImpersonate = 3,
	COMAdminImpersonationDelegate = 4,
}


[AllowDuplicates]
public enum COMAdminAuthenticationCapabilitiesOptions : int32
{
	COMAdminAuthenticationCapabilitiesNone = 0,
	COMAdminAuthenticationCapabilitiesSecureReference = 2,
	COMAdminAuthenticationCapabilitiesStaticCloaking = 32,
	COMAdminAuthenticationCapabilitiesDynamicCloaking = 64,
}


[AllowDuplicates]
public enum COMAdminOS : int32
{
	COMAdminOSNotInitialized = 0,
	COMAdminOSWindows3_1 = 1,
	COMAdminOSWindows9x = 2,
	COMAdminOSWindows2000 = 3,
	COMAdminOSWindows2000AdvancedServer = 4,
	COMAdminOSWindows2000Unknown = 5,
	COMAdminOSUnknown = 6,
	COMAdminOSWindowsXPPersonal = 11,
	COMAdminOSWindowsXPProfessional = 12,
	COMAdminOSWindowsNETStandardServer = 13,
	COMAdminOSWindowsNETEnterpriseServer = 14,
	COMAdminOSWindowsNETDatacenterServer = 15,
	COMAdminOSWindowsNETWebServer = 16,
	COMAdminOSWindowsLonghornPersonal = 17,
	COMAdminOSWindowsLonghornProfessional = 18,
	COMAdminOSWindowsLonghornStandardServer = 19,
	COMAdminOSWindowsLonghornEnterpriseServer = 20,
	COMAdminOSWindowsLonghornDatacenterServer = 21,
	COMAdminOSWindowsLonghornWebServer = 22,
	COMAdminOSWindows7Personal = 23,
	COMAdminOSWindows7Professional = 24,
	COMAdminOSWindows7StandardServer = 25,
	COMAdminOSWindows7EnterpriseServer = 26,
	COMAdminOSWindows7DatacenterServer = 27,
	COMAdminOSWindows7WebServer = 28,
	COMAdminOSWindows8Personal = 29,
	COMAdminOSWindows8Professional = 30,
	COMAdminOSWindows8StandardServer = 31,
	COMAdminOSWindows8EnterpriseServer = 32,
	COMAdminOSWindows8DatacenterServer = 33,
	COMAdminOSWindows8WebServer = 34,
	COMAdminOSWindowsBluePersonal = 35,
	COMAdminOSWindowsBlueProfessional = 36,
	COMAdminOSWindowsBlueStandardServer = 37,
	COMAdminOSWindowsBlueEnterpriseServer = 38,
	COMAdminOSWindowsBlueDatacenterServer = 39,
	COMAdminOSWindowsBlueWebServer = 40,
}


[AllowDuplicates]
public enum COMAdminServiceOptions : int32
{
	COMAdminServiceLoadBalanceRouter = 1,
}


[AllowDuplicates]
public enum COMAdminServiceStatusOptions : int32
{
	COMAdminServiceStopped = 0,
	COMAdminServiceStartPending = 1,
	COMAdminServiceStopPending = 2,
	COMAdminServiceRunning = 3,
	COMAdminServiceContinuePending = 4,
	COMAdminServicePausePending = 5,
	COMAdminServicePaused = 6,
	COMAdminServiceUnknownState = 7,
}


[AllowDuplicates]
public enum COMAdminQCMessageAuthenticateOptions : int32
{
	COMAdminQCMessageAuthenticateSecureApps = 0,
	COMAdminQCMessageAuthenticateOff = 1,
	COMAdminQCMessageAuthenticateOn = 2,
}


[AllowDuplicates]
public enum COMAdminFileFlags : int32
{
	COMAdminFileFlagLoadable = 1,
	COMAdminFileFlagCOM = 2,
	COMAdminFileFlagContainsPS = 4,
	COMAdminFileFlagContainsComp = 8,
	COMAdminFileFlagContainsTLB = 16,
	COMAdminFileFlagSelfReg = 32,
	COMAdminFileFlagSelfUnReg = 64,
	COMAdminFileFlagUnloadableDLL = 128,
	COMAdminFileFlagDoesNotExist = 256,
	COMAdminFileFlagAlreadyInstalled = 512,
	COMAdminFileFlagBadTLB = 1024,
	COMAdminFileFlagGetClassObjFailed = 2048,
	COMAdminFileFlagClassNotAvailable = 4096,
	COMAdminFileFlagRegistrar = 8192,
	COMAdminFileFlagNoRegistrar = 16384,
	COMAdminFileFlagDLLRegsvrFailed = 32768,
	COMAdminFileFlagRegTLBFailed = 65536,
	COMAdminFileFlagRegistrarFailed = 131072,
	COMAdminFileFlagError = 262144,
}


[AllowDuplicates]
public enum COMAdminComponentFlags : int32
{
	COMAdminCompFlagTypeInfoFound = 1,
	COMAdminCompFlagCOMPlusPropertiesFound = 2,
	COMAdminCompFlagProxyFound = 4,
	COMAdminCompFlagInterfacesFound = 8,
	COMAdminCompFlagAlreadyInstalled = 16,
	COMAdminCompFlagNotInApplication = 32,
}


[AllowDuplicates]
public enum COMAdminErrorCodes : int32
{
	COMAdminErrObjectErrors = -2146368511,
	COMAdminErrObjectInvalid = -2146368510,
	COMAdminErrKeyMissing = -2146368509,
	COMAdminErrAlreadyInstalled = -2146368508,
	COMAdminErrAppFileWriteFail = -2146368505,
	COMAdminErrAppFileReadFail = -2146368504,
	COMAdminErrAppFileVersion = -2146368503,
	COMAdminErrBadPath = -2146368502,
	COMAdminErrApplicationExists = -2146368501,
	COMAdminErrRoleExists = -2146368500,
	COMAdminErrCantCopyFile = -2146368499,
	COMAdminErrNoUser = -2146368497,
	COMAdminErrInvalidUserids = -2146368496,
	COMAdminErrNoRegistryCLSID = -2146368495,
	COMAdminErrBadRegistryProgID = -2146368494,
	COMAdminErrAuthenticationLevel = -2146368493,
	COMAdminErrUserPasswdNotValid = -2146368492,
	COMAdminErrCLSIDOrIIDMismatch = -2146368488,
	COMAdminErrRemoteInterface = -2146368487,
	COMAdminErrDllRegisterServer = -2146368486,
	COMAdminErrNoServerShare = -2146368485,
	COMAdminErrDllLoadFailed = -2146368483,
	COMAdminErrBadRegistryLibID = -2146368482,
	COMAdminErrAppDirNotFound = -2146368481,
	COMAdminErrRegistrarFailed = -2146368477,
	COMAdminErrCompFileDoesNotExist = -2146368476,
	COMAdminErrCompFileLoadDLLFail = -2146368475,
	COMAdminErrCompFileGetClassObj = -2146368474,
	COMAdminErrCompFileClassNotAvail = -2146368473,
	COMAdminErrCompFileBadTLB = -2146368472,
	COMAdminErrCompFileNotInstallable = -2146368471,
	COMAdminErrNotChangeable = -2146368470,
	COMAdminErrNotDeletable = -2146368469,
	COMAdminErrSession = -2146368468,
	COMAdminErrCompMoveLocked = -2146368467,
	COMAdminErrCompMoveBadDest = -2146368466,
	COMAdminErrRegisterTLB = -2146368464,
	COMAdminErrSystemApp = -2146368461,
	COMAdminErrCompFileNoRegistrar = -2146368460,
	COMAdminErrCoReqCompInstalled = -2146368459,
	COMAdminErrServiceNotInstalled = -2146368458,
	COMAdminErrPropertySaveFailed = -2146368457,
	COMAdminErrObjectExists = -2146368456,
	COMAdminErrComponentExists = -2146368455,
	COMAdminErrRegFileCorrupt = -2146368453,
	COMAdminErrPropertyOverflow = -2146368452,
	COMAdminErrNotInRegistry = -2146368450,
	COMAdminErrObjectNotPoolable = -2146368449,
	COMAdminErrApplidMatchesClsid = -2146368442,
	COMAdminErrRoleDoesNotExist = -2146368441,
	COMAdminErrStartAppNeedsComponents = -2146368440,
	COMAdminErrRequiresDifferentPlatform = -2146368439,
	COMAdminErrQueuingServiceNotAvailable = -2146367998,
	COMAdminErrObjectParentMissing = -2146367480,
	COMAdminErrObjectDoesNotExist = -2146367479,
	COMAdminErrCanNotExportAppProxy = -2146368438,
	COMAdminErrCanNotStartApp = -2146368437,
	COMAdminErrCanNotExportSystemApp = -2146368436,
	COMAdminErrCanNotSubscribeToComponent = -2146368435,
	COMAdminErrAppNotRunning = -2146367478,
	COMAdminErrEventClassCannotBeSubscriber = -2146368434,
	COMAdminErrLibAppProxyIncompatible = -2146368433,
	COMAdminErrBasePartitionOnly = -2146368432,
	COMAdminErrDuplicatePartitionName = -2146368425,
	COMAdminErrPartitionInUse = -2146368423,
	COMAdminErrImportedComponentsNotAllowed = -2146368421,
	COMAdminErrRegdbNotInitialized = -2146368398,
	COMAdminErrRegdbNotOpen = -2146368397,
	COMAdminErrRegdbSystemErr = -2146368396,
	COMAdminErrRegdbAlreadyRunning = -2146368395,
	COMAdminErrMigVersionNotSupported = -2146368384,
	COMAdminErrMigSchemaNotFound = -2146368383,
	COMAdminErrCatBitnessMismatch = -2146368382,
	COMAdminErrCatUnacceptableBitness = -2146368381,
	COMAdminErrCatWrongAppBitnessBitness = -2146368380,
	COMAdminErrCatPauseResumeNotSupported = -2146368379,
	COMAdminErrCatServerFault = -2146368378,
	COMAdminErrCantRecycleLibraryApps = -2146367473,
	COMAdminErrCantRecycleServiceApps = -2146367471,
	COMAdminErrProcessAlreadyRecycled = -2146367470,
	COMAdminErrPausedProcessMayNotBeRecycled = -2146367469,
	COMAdminErrInvalidPartition = -2146367477,
	COMAdminErrPartitionMsiOnly = -2146367463,
	COMAdminErrStartAppDisabled = -2146368431,
	COMAdminErrCompMoveSource = -2146367460,
	COMAdminErrCompMoveDest = -2146367459,
	COMAdminErrCompMovePrivate = -2146367458,
	COMAdminErrCannotCopyEventClass = -2146367456,
}


[AllowDuplicates]
public enum TRACKING_COLL_TYPE : int32
{
	TRKCOLL_PROCESSES = 0,
	TRKCOLL_APPLICATIONS = 1,
	TRKCOLL_COMPONENTS = 2,
}


[AllowDuplicates]
public enum DUMPTYPE : int32
{
	DUMPTYPE_FULL = 0,
	DUMPTYPE_MINI = 1,
	DUMPTYPE_NONE = 2,
}


[AllowDuplicates]
public enum COMPLUS_APPTYPE : int32
{
	APPTYPE_UNKNOWN = -1,
	APPTYPE_SERVER = 1,
	APPTYPE_LIBRARY = 0,
	APPTYPE_SWC = 2,
}


[AllowDuplicates]
public enum GetAppTrackerDataFlags : int32
{
	GATD_INCLUDE_PROCESS_EXE_NAME = 1,
	GATD_INCLUDE_LIBRARY_APPS = 2,
	GATD_INCLUDE_SWC = 4,
	GATD_INCLUDE_CLASS_NAME = 8,
	GATD_INCLUDE_APPLICATION_NAME = 16,
}


[AllowDuplicates]
public enum TransactionVote : int32
{
	TxCommit = 0,
	TxAbort = 1,
}


[AllowDuplicates]
public enum CrmTransactionState : int32
{
	TxState_Active = 0,
	TxState_Committed = 1,
	TxState_Aborted = 2,
	TxState_Indoubt = 3,
}


[AllowDuplicates]
public enum CSC_InheritanceConfig : int32
{
	CSC_Inherit = 0,
	CSC_Ignore = 1,
}


[AllowDuplicates]
public enum CSC_ThreadPool : int32
{
	CSC_ThreadPoolNone = 0,
	CSC_ThreadPoolInherit = 1,
	CSC_STAThreadPool = 2,
	CSC_MTAThreadPool = 3,
}


[AllowDuplicates]
public enum CSC_Binding : int32
{
	CSC_NoBinding = 0,
	CSC_BindToPoolThread = 1,
}


[AllowDuplicates]
public enum CSC_TransactionConfig : int32
{
	CSC_NoTransaction = 0,
	CSC_IfContainerIsTransactional = 1,
	CSC_CreateTransactionIfNecessary = 2,
	CSC_NewTransaction = 3,
}


[AllowDuplicates]
public enum CSC_SynchronizationConfig : int32
{
	CSC_NoSynchronization = 0,
	CSC_IfContainerIsSynchronized = 1,
	CSC_NewSynchronizationIfNecessary = 2,
	CSC_NewSynchronization = 3,
}


[AllowDuplicates]
public enum CSC_TrackerConfig : int32
{
	CSC_DontUseTracker = 0,
	CSC_UseTracker = 1,
}


[AllowDuplicates]
public enum CSC_PartitionConfig : int32
{
	CSC_NoPartition = 0,
	CSC_InheritPartition = 1,
	CSC_NewPartition = 2,
}


[AllowDuplicates]
public enum CSC_IISIntrinsicsConfig : int32
{
	CSC_NoIISIntrinsics = 0,
	CSC_InheritIISIntrinsics = 1,
}


[AllowDuplicates]
public enum CSC_COMTIIntrinsicsConfig : int32
{
	CSC_NoCOMTIIntrinsics = 0,
	CSC_InheritCOMTIIntrinsics = 1,
}


[AllowDuplicates]
public enum CSC_SxsConfig : int32
{
	CSC_NoSxs = 0,
	CSC_InheritSxs = 1,
	CSC_NewSxs = 2,
}


[AllowDuplicates]
public enum AutoSvcs_Error_Constants : uint32
{
	mtsErrCtxAborted = 2147803138,
	mtsErrCtxAborting = 2147803139,
	mtsErrCtxNoContext = 2147803140,
	mtsErrCtxNotRegistered = 2147803141,
	mtsErrCtxSynchTimeout = 2147803142,
	mtsErrCtxOldReference = 2147803143,
	mtsErrCtxRoleNotFound = 2147803148,
	mtsErrCtxNoSecurity = 2147803149,
	mtsErrCtxWrongThread = 2147803150,
	mtsErrCtxTMNotAvailable = 2147803151,
	comQCErrApplicationNotQueued = 2148599296,
	comQCErrNoQueueableInterfaces = 2148599297,
	comQCErrQueuingServiceNotAvailable = 2148599298,
	comQCErrQueueTransactMismatch = 2148599299,
	comqcErrRecorderMarshalled = 2148599300,
	comqcErrOutParam = 2148599301,
	comqcErrRecorderNotTrusted = 2148599302,
	comqcErrPSLoad = 2148599303,
	comqcErrMarshaledObjSameTxn = 2148599304,
	comqcErrInvalidMessage = 2148599376,
	comqcErrMsmqSidUnavailable = 2148599377,
	comqcErrWrongMsgExtension = 2148599378,
	comqcErrMsmqServiceUnavailable = 2148599379,
	comqcErrMsgNotAuthenticated = 2148599380,
	comqcErrMsmqConnectorUsed = 2148599381,
	comqcErrBadMarshaledObject = 2148599382,
}


[AllowDuplicates]
public enum LockModes : int32
{
	LockSetGet = 0,
	LockMethod = 1,
}


[AllowDuplicates]
public enum ReleaseModes : int32
{
	Standard = 0,
	Process = 1,
}


[AllowDuplicates]
public enum CRMFLAGS : int32
{
	CRMFLAG_FORGETTARGET = 1,
	CRMFLAG_WRITTENDURINGPREPARE = 2,
	CRMFLAG_WRITTENDURINGCOMMIT = 4,
	CRMFLAG_WRITTENDURINGABORT = 8,
	CRMFLAG_WRITTENDURINGRECOVERY = 16,
	CRMFLAG_WRITTENDURINGREPLAY = 32,
	CRMFLAG_REPLAYINPROGRESS = 64,
}


[AllowDuplicates]
public enum CRMREGFLAGS : int32
{
	CRMREGFLAG_PREPAREPHASE = 1,
	CRMREGFLAG_COMMITPHASE = 2,
	CRMREGFLAG_ABORTPHASE = 4,
	CRMREGFLAG_ALLPHASES = 7,
	CRMREGFLAG_FAILIFINDOUBTSREMAIN = 16,
}

#endregion


#region Structs
[CRepr]
public struct COMSVCSEVENTINFO
{
	public uint32 cbSize;
	public uint32 dwPid;
	public int64 lTime;
	public int32 lMicroTime;
	public int64 perfCount;
	public Guid guidApp;
	public PWSTR sMachineName;
}

[CRepr]
public struct RECYCLE_INFO
{
	public Guid guidCombaseProcessIdentifier;
	public int64 ProcessStartTime;
	public uint32 dwRecycleLifetimeLimit;
	public uint32 dwRecycleMemoryLimit;
	public uint32 dwRecycleExpirationTimeout;
}

[CRepr]
public struct HANG_INFO
{
	public BOOL fAppHangMonitorEnabled;
	public BOOL fTerminateOnHang;
	public DUMPTYPE DumpType;
	public uint32 dwHangTimeout;
	public uint32 dwDumpCount;
	public uint32 dwInfoMsgCount;
}

[CRepr]
public struct APPSTATISTICS
{
	public uint32 m_cTotalCalls;
	public uint32 m_cTotalInstances;
	public uint32 m_cTotalClasses;
	public uint32 m_cCallsPerSecond;
}

[CRepr]
public struct APPDATA
{
	public uint32 m_idApp;
	public char16[40] m_szAppGuid;
	public uint32 m_dwAppProcessId;
	public APPSTATISTICS m_AppStatistics;
}

[CRepr]
public struct CLSIDDATA
{
	public Guid m_clsid;
	public uint32 m_cReferences;
	public uint32 m_cBound;
	public uint32 m_cPooled;
	public uint32 m_cInCall;
	public uint32 m_dwRespTime;
	public uint32 m_cCallsCompleted;
	public uint32 m_cCallsFailed;
}

[CRepr]
public struct CLSIDDATA2
{
	public Guid m_clsid;
	public Guid m_appid;
	public Guid m_partid;
	public PWSTR m_pwszAppName;
	public PWSTR m_pwszCtxName;
	public COMPLUS_APPTYPE m_eAppType;
	public uint32 m_cReferences;
	public uint32 m_cBound;
	public uint32 m_cPooled;
	public uint32 m_cInCall;
	public uint32 m_dwRespTime;
	public uint32 m_cCallsCompleted;
	public uint32 m_cCallsFailed;
}

[CRepr]
public struct ApplicationProcessSummary
{
	public Guid PartitionIdPrimaryApplication;
	public Guid ApplicationIdPrimaryApplication;
	public Guid ApplicationInstanceId;
	public uint32 ProcessId;
	public COMPLUS_APPTYPE Type;
	public PWSTR ProcessExeName;
	public BOOL IsService;
	public BOOL IsPaused;
	public BOOL IsRecycled;
}

[CRepr]
public struct ApplicationProcessStatistics
{
	public uint32 NumCallsOutstanding;
	public uint32 NumTrackedComponents;
	public uint32 NumComponentInstances;
	public uint32 AvgCallsPerSecond;
	public uint32 Reserved1;
	public uint32 Reserved2;
	public uint32 Reserved3;
	public uint32 Reserved4;
}

[CRepr]
public struct ApplicationProcessRecycleInfo
{
	public BOOL IsRecyclable;
	public BOOL IsRecycled;
	public FILETIME TimeRecycled;
	public FILETIME TimeToTerminate;
	public int32 RecycleReasonCode;
	public BOOL IsPendingRecycle;
	public BOOL HasAutomaticLifetimeRecycling;
	public FILETIME TimeForAutomaticRecycling;
	public uint32 MemoryLimitInKB;
	public uint32 MemoryUsageInKBLastCheck;
	public uint32 ActivationLimit;
	public uint32 NumActivationsLastReported;
	public uint32 CallLimit;
	public uint32 NumCallsLastReported;
}

[CRepr]
public struct ApplicationSummary
{
	public Guid ApplicationInstanceId;
	public Guid PartitionId;
	public Guid ApplicationId;
	public COMPLUS_APPTYPE Type;
	public PWSTR ApplicationName;
	public uint32 NumTrackedComponents;
	public uint32 NumComponentInstances;
}

[CRepr]
public struct ComponentSummary
{
	public Guid ApplicationInstanceId;
	public Guid PartitionId;
	public Guid ApplicationId;
	public Guid Clsid;
	public PWSTR ClassName;
	public PWSTR ApplicationName;
}

[CRepr]
public struct ComponentStatistics
{
	public uint32 NumInstances;
	public uint32 NumBoundReferences;
	public uint32 NumPooledObjects;
	public uint32 NumObjectsInCall;
	public uint32 AvgResponseTimeInMs;
	public uint32 NumCallsCompletedRecent;
	public uint32 NumCallsFailedRecent;
	public uint32 NumCallsCompletedTotal;
	public uint32 NumCallsFailedTotal;
	public uint32 Reserved1;
	public uint32 Reserved2;
	public uint32 Reserved3;
	public uint32 Reserved4;
}

[CRepr]
public struct ComponentHangMonitorInfo
{
	public BOOL IsMonitored;
	public BOOL TerminateOnHang;
	public uint32 AvgCallThresholdInMs;
}

[CRepr]
public struct CrmLogRecordRead
{
	public uint32 dwCrmFlags;
	public uint32 dwSequenceNumber;
	public BLOB blobUserData;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_SecurityIdentity = .(0xecabb0a5, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_SecurityCallers = .(0xecabb0a6, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_SecurityCallContext = .(0xecabb0a7, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_GetSecurityCallContextAppObject = .(0xecabb0a8, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_Dummy30040732 = .(0xecabb0a9, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_TransactionContext = .(0x7999fc25, 0xd3c6, 0x11cf, 0xac, 0xab, 0x00, 0xa0, 0x24, 0xa5, 0x5a, 0xef);


	public const Guid CLSID_TransactionContextEx = .(0x5cb66670, 0xd3d4, 0x11cf, 0xac, 0xab, 0x00, 0xa0, 0x24, 0xa5, 0x5a, 0xef);


	public const Guid CLSID_ByotServerEx = .(0xecabb0aa, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_CServiceConfig = .(0xecabb0c8, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_ServicePool = .(0xecabb0c9, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_ServicePoolConfig = .(0xecabb0ca, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_SharedProperty = .(0x2a005c05, 0xa5de, 0x11cf, 0x9e, 0x66, 0x00, 0xaa, 0x00, 0xa3, 0xf4, 0x64);


	public const Guid CLSID_SharedPropertyGroup = .(0x2a005c0b, 0xa5de, 0x11cf, 0x9e, 0x66, 0x00, 0xaa, 0x00, 0xa3, 0xf4, 0x64);


	public const Guid CLSID_SharedPropertyGroupManager = .(0x2a005c11, 0xa5de, 0x11cf, 0x9e, 0x66, 0x00, 0xaa, 0x00, 0xa3, 0xf4, 0x64);


	public const Guid CLSID_COMEvents = .(0xecabb0ab, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_CoMTSLocator = .(0xecabb0ac, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_MtsGrp = .(0x4b2e958d, 0x0393, 0x11d1, 0xb1, 0xab, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);


	public const Guid CLSID_ComServiceEvents = .(0xecabb0c3, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_ComSystemAppEventData = .(0xecabb0c6, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_CRMClerk = .(0xecabb0bd, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_CRMRecoveryClerk = .(0xecabb0be, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_LBEvents = .(0xecabb0c1, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_MessageMover = .(0xecabb0bf, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_DispenserManager = .(0xecabb0c0, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_PoolMgr = .(0xecabafb5, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_EventServer = .(0xecabafbc, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_TrackerServer = .(0xecabafb9, 0x7f19, 0x11d2, 0x97, 0x8e, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);


	public const Guid CLSID_AppDomainHelper = .(0xef24f689, 0x14f8, 0x4d92, 0xb4, 0xaf, 0xd7, 0xb1, 0xf0, 0xe7, 0x0f, 0xd4);


	public const Guid CLSID_ClrAssemblyLocator = .(0x458aa3b5, 0x265a, 0x4b75, 0xbc, 0x05, 0x9b, 0xea, 0x46, 0x30, 0xcf, 0x18);


	public const Guid CLSID_COMAdminCatalog = .(0xf618c514, 0xdfb8, 0x11d1, 0xa2, 0xcf, 0x00, 0x80, 0x5f, 0xc7, 0x92, 0x35);


	public const Guid CLSID_COMAdminCatalogObject = .(0xf618c515, 0xdfb8, 0x11d1, 0xa2, 0xcf, 0x00, 0x80, 0x5f, 0xc7, 0x92, 0x35);


	public const Guid CLSID_COMAdminCatalogCollection = .(0xf618c516, 0xdfb8, 0x11d1, 0xa2, 0xcf, 0x00, 0x80, 0x5f, 0xc7, 0x92, 0x35);


}
#endregion

#region COM Types
[CRepr]struct ICOMAdminCatalog : IDispatch
{
	public new const Guid IID = .(0xdd662187, 0xdfc2, 0x11d1, 0xa2, 0xcf, 0x00, 0x80, 0x5f, 0xc7, 0x92, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCollName, IDispatch** ppCatalogCollection) GetCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCatalogServerName, IDispatch** ppCatalogCollection) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorVersion) get_MinorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCollName, SAFEARRAY** ppsaVarQuery, IDispatch** ppCatalogCollection) GetCollectionByQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIDOrName, BSTR bstrCLSIDOrProgID) ImportComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIDOrName, BSTR bstrDLL, BSTR bstrTLB, BSTR bstrPSDLL) InstallComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIDOrName) ShutdownApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIDOrName, BSTR bstrApplicationFile, COMAdminApplicationExportOptions lOptions) ExportApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationFile, BSTR bstrDestinationDirectory, COMAdminApplicationInstallOptions lOptions, BSTR bstrUserId, BSTR bstrPassword, BSTR bstrRSN) InstallApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopRouter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshRouter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartRouter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reserved1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reserved2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIDOrName, SAFEARRAY** ppsaVarFileNames, SAFEARRAY** ppsaVarCLSIDs) InstallMultipleComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIdOrName, SAFEARRAY** ppsaVarFileNames, SAFEARRAY** ppsaVarCLSIDs, SAFEARRAY** ppsaVarClassNames, SAFEARRAY** ppsaVarFileFlags, SAFEARRAY** ppsaVarComponentFlags) GetMultipleComponentsInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBackupFilePath) BackupREGDB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBackupFilePath) RestoreREGDB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationFile, BSTR* pbstrApplicationName, BSTR* pbstrApplicationDescription, int16* pbHasUsers, int16* pbIsProxy, SAFEARRAY** ppsaVarFileNames) QueryApplicationFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIdOrName) StartApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lService, int32* plStatus) ServiceCheck;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIdOrName, SAFEARRAY** ppsaVarFileNames, SAFEARRAY** ppsaVarCLSIDS) InstallMultipleEventClasses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplIdOrName, BSTR bstrDLL, BSTR bstrTLB, BSTR bstrPSDLL) InstallEventClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrIID, SAFEARRAY** ppsaVarCLSIDs, SAFEARRAY** ppsaVarProgIDs, SAFEARRAY** ppsaVarDescriptions) GetEventClassesForIID;
	}


	public HRESULT GetCollection(BSTR bstrCollName, IDispatch** ppCatalogCollection) mut => VT.[Friend]GetCollection(&this, bstrCollName, ppCatalogCollection);

	public HRESULT Connect(BSTR bstrCatalogServerName, IDispatch** ppCatalogCollection) mut => VT.[Friend]Connect(&this, bstrCatalogServerName, ppCatalogCollection);

	public HRESULT get_MajorVersion(int32* plMajorVersion) mut => VT.[Friend]get_MajorVersion(&this, plMajorVersion);

	public HRESULT get_MinorVersion(int32* plMinorVersion) mut => VT.[Friend]get_MinorVersion(&this, plMinorVersion);

	public HRESULT GetCollectionByQuery(BSTR bstrCollName, SAFEARRAY** ppsaVarQuery, IDispatch** ppCatalogCollection) mut => VT.[Friend]GetCollectionByQuery(&this, bstrCollName, ppsaVarQuery, ppCatalogCollection);

	public HRESULT ImportComponent(BSTR bstrApplIDOrName, BSTR bstrCLSIDOrProgID) mut => VT.[Friend]ImportComponent(&this, bstrApplIDOrName, bstrCLSIDOrProgID);

	public HRESULT InstallComponent(BSTR bstrApplIDOrName, BSTR bstrDLL, BSTR bstrTLB, BSTR bstrPSDLL) mut => VT.[Friend]InstallComponent(&this, bstrApplIDOrName, bstrDLL, bstrTLB, bstrPSDLL);

	public HRESULT ShutdownApplication(BSTR bstrApplIDOrName) mut => VT.[Friend]ShutdownApplication(&this, bstrApplIDOrName);

	public HRESULT ExportApplication(BSTR bstrApplIDOrName, BSTR bstrApplicationFile, COMAdminApplicationExportOptions lOptions) mut => VT.[Friend]ExportApplication(&this, bstrApplIDOrName, bstrApplicationFile, lOptions);

	public HRESULT InstallApplication(BSTR bstrApplicationFile, BSTR bstrDestinationDirectory, COMAdminApplicationInstallOptions lOptions, BSTR bstrUserId, BSTR bstrPassword, BSTR bstrRSN) mut => VT.[Friend]InstallApplication(&this, bstrApplicationFile, bstrDestinationDirectory, lOptions, bstrUserId, bstrPassword, bstrRSN);

	public HRESULT StopRouter() mut => VT.[Friend]StopRouter(&this);

	public HRESULT RefreshRouter() mut => VT.[Friend]RefreshRouter(&this);

	public HRESULT StartRouter() mut => VT.[Friend]StartRouter(&this);

	public HRESULT Reserved1() mut => VT.[Friend]Reserved1(&this);

	public HRESULT Reserved2() mut => VT.[Friend]Reserved2(&this);

	public HRESULT InstallMultipleComponents(BSTR bstrApplIDOrName, SAFEARRAY** ppsaVarFileNames, SAFEARRAY** ppsaVarCLSIDs) mut => VT.[Friend]InstallMultipleComponents(&this, bstrApplIDOrName, ppsaVarFileNames, ppsaVarCLSIDs);

	public HRESULT GetMultipleComponentsInfo(BSTR bstrApplIdOrName, SAFEARRAY** ppsaVarFileNames, SAFEARRAY** ppsaVarCLSIDs, SAFEARRAY** ppsaVarClassNames, SAFEARRAY** ppsaVarFileFlags, SAFEARRAY** ppsaVarComponentFlags) mut => VT.[Friend]GetMultipleComponentsInfo(&this, bstrApplIdOrName, ppsaVarFileNames, ppsaVarCLSIDs, ppsaVarClassNames, ppsaVarFileFlags, ppsaVarComponentFlags);

	public HRESULT RefreshComponents() mut => VT.[Friend]RefreshComponents(&this);

	public HRESULT BackupREGDB(BSTR bstrBackupFilePath) mut => VT.[Friend]BackupREGDB(&this, bstrBackupFilePath);

	public HRESULT RestoreREGDB(BSTR bstrBackupFilePath) mut => VT.[Friend]RestoreREGDB(&this, bstrBackupFilePath);

	public HRESULT QueryApplicationFile(BSTR bstrApplicationFile, BSTR* pbstrApplicationName, BSTR* pbstrApplicationDescription, int16* pbHasUsers, int16* pbIsProxy, SAFEARRAY** ppsaVarFileNames) mut => VT.[Friend]QueryApplicationFile(&this, bstrApplicationFile, pbstrApplicationName, pbstrApplicationDescription, pbHasUsers, pbIsProxy, ppsaVarFileNames);

	public HRESULT StartApplication(BSTR bstrApplIdOrName) mut => VT.[Friend]StartApplication(&this, bstrApplIdOrName);

	public HRESULT ServiceCheck(int32 lService, int32* plStatus) mut => VT.[Friend]ServiceCheck(&this, lService, plStatus);

	public HRESULT InstallMultipleEventClasses(BSTR bstrApplIdOrName, SAFEARRAY** ppsaVarFileNames, SAFEARRAY** ppsaVarCLSIDS) mut => VT.[Friend]InstallMultipleEventClasses(&this, bstrApplIdOrName, ppsaVarFileNames, ppsaVarCLSIDS);

	public HRESULT InstallEventClass(BSTR bstrApplIdOrName, BSTR bstrDLL, BSTR bstrTLB, BSTR bstrPSDLL) mut => VT.[Friend]InstallEventClass(&this, bstrApplIdOrName, bstrDLL, bstrTLB, bstrPSDLL);

	public HRESULT GetEventClassesForIID(BSTR bstrIID, SAFEARRAY** ppsaVarCLSIDs, SAFEARRAY** ppsaVarProgIDs, SAFEARRAY** ppsaVarDescriptions) mut => VT.[Friend]GetEventClassesForIID(&this, bstrIID, ppsaVarCLSIDs, ppsaVarProgIDs, ppsaVarDescriptions);
}

[CRepr]struct ICOMAdminCatalog2 : ICOMAdminCatalog
{
	public new const Guid IID = .(0x790c6e0b, 0x9194, 0x4cc9, 0x94, 0x26, 0xa4, 0x8a, 0x63, 0x18, 0x56, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICOMAdminCatalog.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCollectionName, VARIANT* pVarQueryStrings, IDispatch** ppCatalogCollection) GetCollectionByQuery2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProcessID, BSTR* pbstrApplicationInstanceID) GetApplicationInstanceIDFromProcessID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarApplicationInstanceID) ShutdownApplicationInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarApplicationInstanceID) PauseApplicationInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarApplicationInstanceID) ResumeApplicationInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarApplicationInstanceID, int32 lReasonCode) RecycleApplicationInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarApplicationInstanceID, int16* pVarBoolPaused) AreApplicationInstancesPaused;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationInstanceID, BSTR bstrDirectory, int32 lMaxImages, BSTR* pbstrDumpFile) DumpApplicationInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVarBoolDumpSupported) get_IsApplicationInstanceDumpSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName, BSTR bstrServiceName, BSTR bstrStartType, BSTR bstrErrorControl, BSTR bstrDependencies, BSTR bstrRunAs, BSTR bstrPassword, int16 bDesktopOk) CreateServiceForApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName) DeleteServiceForApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName, BSTR* pbstrPartitionID) GetPartitionID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName, BSTR* pbstrPartitionName) GetPartitionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPartitionIDOrName) put_CurrentPartition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPartitionID) get_CurrentPartitionID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPartitionName) get_CurrentPartitionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGlobalPartitionID) get_GlobalPartitionID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlushPartitionCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSourcePartitionIDOrName, VARIANT* pVarApplicationID, BSTR bstrDestinationPartitionIDOrName) CopyApplications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSourceApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, BSTR bstrDestinationApplicationIDOrName) CopyComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSourceApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, BSTR bstrDestinationApplicationIDOrName) MoveComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSrcApplicationIDOrName, BSTR bstrCLSIDOrProgID, BSTR bstrDestApplicationIDOrName, BSTR bstrNewProgId, BSTR bstrNewClsid) AliasComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDllName, COMAdminInUse* pCOMAdminInUse) IsSafeToDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, VARIANT* pVarComponentType) ImportUnconfiguredComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, VARIANT* pVarComponentType) PromoteUnconfiguredComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, VARIANT* pVarComponentType) ImportComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIs64Bit) get_Is64BitCatalogServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPartitionIDOrName, BSTR bstrPartitionFileName, COMAdminApplicationExportOptions lOptions) ExportPartition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFileName, BSTR bstrDestDirectory, COMAdminApplicationInstallOptions lOptions, BSTR bstrUserID, BSTR bstrPassword, BSTR bstrRSN) InstallPartition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationFile, IDispatch** ppFilesForImport) QueryApplicationFile2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCLSIDOrProgID, int32* plVersionCount) GetComponentVersionCount;
	}


	public HRESULT GetCollectionByQuery2(BSTR bstrCollectionName, VARIANT* pVarQueryStrings, IDispatch** ppCatalogCollection) mut => VT.[Friend]GetCollectionByQuery2(&this, bstrCollectionName, pVarQueryStrings, ppCatalogCollection);

	public HRESULT GetApplicationInstanceIDFromProcessID(int32 lProcessID, BSTR* pbstrApplicationInstanceID) mut => VT.[Friend]GetApplicationInstanceIDFromProcessID(&this, lProcessID, pbstrApplicationInstanceID);

	public HRESULT ShutdownApplicationInstances(VARIANT* pVarApplicationInstanceID) mut => VT.[Friend]ShutdownApplicationInstances(&this, pVarApplicationInstanceID);

	public HRESULT PauseApplicationInstances(VARIANT* pVarApplicationInstanceID) mut => VT.[Friend]PauseApplicationInstances(&this, pVarApplicationInstanceID);

	public HRESULT ResumeApplicationInstances(VARIANT* pVarApplicationInstanceID) mut => VT.[Friend]ResumeApplicationInstances(&this, pVarApplicationInstanceID);

	public HRESULT RecycleApplicationInstances(VARIANT* pVarApplicationInstanceID, int32 lReasonCode) mut => VT.[Friend]RecycleApplicationInstances(&this, pVarApplicationInstanceID, lReasonCode);

	public HRESULT AreApplicationInstancesPaused(VARIANT* pVarApplicationInstanceID, int16* pVarBoolPaused) mut => VT.[Friend]AreApplicationInstancesPaused(&this, pVarApplicationInstanceID, pVarBoolPaused);

	public HRESULT DumpApplicationInstance(BSTR bstrApplicationInstanceID, BSTR bstrDirectory, int32 lMaxImages, BSTR* pbstrDumpFile) mut => VT.[Friend]DumpApplicationInstance(&this, bstrApplicationInstanceID, bstrDirectory, lMaxImages, pbstrDumpFile);

	public HRESULT get_IsApplicationInstanceDumpSupported(int16* pVarBoolDumpSupported) mut => VT.[Friend]get_IsApplicationInstanceDumpSupported(&this, pVarBoolDumpSupported);

	public HRESULT CreateServiceForApplication(BSTR bstrApplicationIDOrName, BSTR bstrServiceName, BSTR bstrStartType, BSTR bstrErrorControl, BSTR bstrDependencies, BSTR bstrRunAs, BSTR bstrPassword, int16 bDesktopOk) mut => VT.[Friend]CreateServiceForApplication(&this, bstrApplicationIDOrName, bstrServiceName, bstrStartType, bstrErrorControl, bstrDependencies, bstrRunAs, bstrPassword, bDesktopOk);

	public HRESULT DeleteServiceForApplication(BSTR bstrApplicationIDOrName) mut => VT.[Friend]DeleteServiceForApplication(&this, bstrApplicationIDOrName);

	public HRESULT GetPartitionID(BSTR bstrApplicationIDOrName, BSTR* pbstrPartitionID) mut => VT.[Friend]GetPartitionID(&this, bstrApplicationIDOrName, pbstrPartitionID);

	public HRESULT GetPartitionName(BSTR bstrApplicationIDOrName, BSTR* pbstrPartitionName) mut => VT.[Friend]GetPartitionName(&this, bstrApplicationIDOrName, pbstrPartitionName);

	public HRESULT put_CurrentPartition(BSTR bstrPartitionIDOrName) mut => VT.[Friend]put_CurrentPartition(&this, bstrPartitionIDOrName);

	public HRESULT get_CurrentPartitionID(BSTR* pbstrPartitionID) mut => VT.[Friend]get_CurrentPartitionID(&this, pbstrPartitionID);

	public HRESULT get_CurrentPartitionName(BSTR* pbstrPartitionName) mut => VT.[Friend]get_CurrentPartitionName(&this, pbstrPartitionName);

	public HRESULT get_GlobalPartitionID(BSTR* pbstrGlobalPartitionID) mut => VT.[Friend]get_GlobalPartitionID(&this, pbstrGlobalPartitionID);

	public HRESULT FlushPartitionCache() mut => VT.[Friend]FlushPartitionCache(&this);

	public HRESULT CopyApplications(BSTR bstrSourcePartitionIDOrName, VARIANT* pVarApplicationID, BSTR bstrDestinationPartitionIDOrName) mut => VT.[Friend]CopyApplications(&this, bstrSourcePartitionIDOrName, pVarApplicationID, bstrDestinationPartitionIDOrName);

	public HRESULT CopyComponents(BSTR bstrSourceApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, BSTR bstrDestinationApplicationIDOrName) mut => VT.[Friend]CopyComponents(&this, bstrSourceApplicationIDOrName, pVarCLSIDOrProgID, bstrDestinationApplicationIDOrName);

	public HRESULT MoveComponents(BSTR bstrSourceApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, BSTR bstrDestinationApplicationIDOrName) mut => VT.[Friend]MoveComponents(&this, bstrSourceApplicationIDOrName, pVarCLSIDOrProgID, bstrDestinationApplicationIDOrName);

	public HRESULT AliasComponent(BSTR bstrSrcApplicationIDOrName, BSTR bstrCLSIDOrProgID, BSTR bstrDestApplicationIDOrName, BSTR bstrNewProgId, BSTR bstrNewClsid) mut => VT.[Friend]AliasComponent(&this, bstrSrcApplicationIDOrName, bstrCLSIDOrProgID, bstrDestApplicationIDOrName, bstrNewProgId, bstrNewClsid);

	public HRESULT IsSafeToDelete(BSTR bstrDllName, COMAdminInUse* pCOMAdminInUse) mut => VT.[Friend]IsSafeToDelete(&this, bstrDllName, pCOMAdminInUse);

	public HRESULT ImportUnconfiguredComponents(BSTR bstrApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, VARIANT* pVarComponentType) mut => VT.[Friend]ImportUnconfiguredComponents(&this, bstrApplicationIDOrName, pVarCLSIDOrProgID, pVarComponentType);

	public HRESULT PromoteUnconfiguredComponents(BSTR bstrApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, VARIANT* pVarComponentType) mut => VT.[Friend]PromoteUnconfiguredComponents(&this, bstrApplicationIDOrName, pVarCLSIDOrProgID, pVarComponentType);

	public HRESULT ImportComponents(BSTR bstrApplicationIDOrName, VARIANT* pVarCLSIDOrProgID, VARIANT* pVarComponentType) mut => VT.[Friend]ImportComponents(&this, bstrApplicationIDOrName, pVarCLSIDOrProgID, pVarComponentType);

	public HRESULT get_Is64BitCatalogServer(int16* pbIs64Bit) mut => VT.[Friend]get_Is64BitCatalogServer(&this, pbIs64Bit);

	public HRESULT ExportPartition(BSTR bstrPartitionIDOrName, BSTR bstrPartitionFileName, COMAdminApplicationExportOptions lOptions) mut => VT.[Friend]ExportPartition(&this, bstrPartitionIDOrName, bstrPartitionFileName, lOptions);

	public HRESULT InstallPartition(BSTR bstrFileName, BSTR bstrDestDirectory, COMAdminApplicationInstallOptions lOptions, BSTR bstrUserID, BSTR bstrPassword, BSTR bstrRSN) mut => VT.[Friend]InstallPartition(&this, bstrFileName, bstrDestDirectory, lOptions, bstrUserID, bstrPassword, bstrRSN);

	public HRESULT QueryApplicationFile2(BSTR bstrApplicationFile, IDispatch** ppFilesForImport) mut => VT.[Friend]QueryApplicationFile2(&this, bstrApplicationFile, ppFilesForImport);

	public HRESULT GetComponentVersionCount(BSTR bstrCLSIDOrProgID, int32* plVersionCount) mut => VT.[Friend]GetComponentVersionCount(&this, bstrCLSIDOrProgID, plVersionCount);
}

[CRepr]struct ICatalogObject : IDispatch
{
	public new const Guid IID = .(0x6eb22871, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, VARIANT* pvarRetVal) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, VARIANT val) put_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarRetVal) get_Key;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarRetVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, int16* pbRetVal) IsPropertyReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRetVal) get_Valid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, int16* pbRetVal) IsPropertyWriteOnly;
	}


	public HRESULT get_Value(BSTR bstrPropName, VARIANT* pvarRetVal) mut => VT.[Friend]get_Value(&this, bstrPropName, pvarRetVal);

	public HRESULT put_Value(BSTR bstrPropName, VARIANT val) mut => VT.[Friend]put_Value(&this, bstrPropName, val);

	public HRESULT get_Key(VARIANT* pvarRetVal) mut => VT.[Friend]get_Key(&this, pvarRetVal);

	public HRESULT get_Name(VARIANT* pvarRetVal) mut => VT.[Friend]get_Name(&this, pvarRetVal);

	public HRESULT IsPropertyReadOnly(BSTR bstrPropName, int16* pbRetVal) mut => VT.[Friend]IsPropertyReadOnly(&this, bstrPropName, pbRetVal);

	public HRESULT get_Valid(int16* pbRetVal) mut => VT.[Friend]get_Valid(&this, pbRetVal);

	public HRESULT IsPropertyWriteOnly(BSTR bstrPropName, int16* pbRetVal) mut => VT.[Friend]IsPropertyWriteOnly(&this, bstrPropName, pbRetVal);
}

[CRepr]struct ICatalogCollection : IDispatch
{
	public new const Guid IID = .(0x6eb22872, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumVariant) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IDispatch** ppCatalogObject) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plObjectCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppCatalogObject) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Populate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcChanges) SaveChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCollName, VARIANT varObjectKey, IDispatch** ppCatalogCollection) GetCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarNamel) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVarBool) get_AddEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVarBool) get_RemoveEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppIDispatch) GetUtilInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion) get_DataStoreMajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorVersionl) get_DataStoreMinorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* psaKeys) PopulateByKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrQueryString, int32 lQueryType) PopulateByQuery;
	}


	public HRESULT get__NewEnum(IUnknown** ppEnumVariant) mut => VT.[Friend]get__NewEnum(&this, ppEnumVariant);

	public HRESULT get_Item(int32 lIndex, IDispatch** ppCatalogObject) mut => VT.[Friend]get_Item(&this, lIndex, ppCatalogObject);

	public HRESULT get_Count(int32* plObjectCount) mut => VT.[Friend]get_Count(&this, plObjectCount);

	public HRESULT Remove(int32 lIndex) mut => VT.[Friend]Remove(&this, lIndex);

	public HRESULT Add(IDispatch** ppCatalogObject) mut => VT.[Friend]Add(&this, ppCatalogObject);

	public HRESULT Populate() mut => VT.[Friend]Populate(&this);

	public HRESULT SaveChanges(int32* pcChanges) mut => VT.[Friend]SaveChanges(&this, pcChanges);

	public HRESULT GetCollection(BSTR bstrCollName, VARIANT varObjectKey, IDispatch** ppCatalogCollection) mut => VT.[Friend]GetCollection(&this, bstrCollName, varObjectKey, ppCatalogCollection);

	public HRESULT get_Name(VARIANT* pVarNamel) mut => VT.[Friend]get_Name(&this, pVarNamel);

	public HRESULT get_AddEnabled(int16* pVarBool) mut => VT.[Friend]get_AddEnabled(&this, pVarBool);

	public HRESULT get_RemoveEnabled(int16* pVarBool) mut => VT.[Friend]get_RemoveEnabled(&this, pVarBool);

	public HRESULT GetUtilInterface(IDispatch** ppIDispatch) mut => VT.[Friend]GetUtilInterface(&this, ppIDispatch);

	public HRESULT get_DataStoreMajorVersion(int32* plMajorVersion) mut => VT.[Friend]get_DataStoreMajorVersion(&this, plMajorVersion);

	public HRESULT get_DataStoreMinorVersion(int32* plMinorVersionl) mut => VT.[Friend]get_DataStoreMinorVersion(&this, plMinorVersionl);

	public HRESULT PopulateByKey(SAFEARRAY* psaKeys) mut => VT.[Friend]PopulateByKey(&this, psaKeys);

	public HRESULT PopulateByQuery(BSTR bstrQueryString, int32 lQueryType) mut => VT.[Friend]PopulateByQuery(&this, bstrQueryString, lQueryType);
}

[CRepr]struct ISecurityIdentityColl : IDispatch
{
	public new const Guid IID = .(0xcafc823c, 0xb441, 0x11d1, 0xb8, 0x2b, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT* pItem) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_Item(BSTR name, VARIANT* pItem) mut => VT.[Friend]get_Item(&this, name, pItem);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);
}

[CRepr]struct ISecurityCallersColl : IDispatch
{
	public new const Guid IID = .(0xcafc823d, 0xb441, 0x11d1, 0xb8, 0x2b, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, ISecurityIdentityColl** pObj) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_Item(int32 lIndex, ISecurityIdentityColl** pObj) mut => VT.[Friend]get_Item(&this, lIndex, pObj);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);
}

[CRepr]struct ISecurityCallContext : IDispatch
{
	public new const Guid IID = .(0xcafc823e, 0xb441, 0x11d1, 0xb8, 0x2b, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT* pItem) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRole, int16* pfInRole) IsCallerInRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfIsEnabled) IsSecurityEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pUser, BSTR bstrRole, int16* pfInRole) IsUserInRole;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_Item(BSTR name, VARIANT* pItem) mut => VT.[Friend]get_Item(&this, name, pItem);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);

	public HRESULT IsCallerInRole(BSTR bstrRole, int16* pfInRole) mut => VT.[Friend]IsCallerInRole(&this, bstrRole, pfInRole);

	public HRESULT IsSecurityEnabled(int16* pfIsEnabled) mut => VT.[Friend]IsSecurityEnabled(&this, pfIsEnabled);

	public HRESULT IsUserInRole(VARIANT* pUser, BSTR bstrRole, int16* pfInRole) mut => VT.[Friend]IsUserInRole(&this, pUser, bstrRole, pfInRole);
}

[CRepr]struct IGetSecurityCallContext : IDispatch
{
	public new const Guid IID = .(0xcafc823f, 0xb441, 0x11d1, 0xb8, 0x2b, 0x00, 0x00, 0xf8, 0x75, 0x7e, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISecurityCallContext** ppObject) GetSecurityCallContext;
	}


	public HRESULT GetSecurityCallContext(ISecurityCallContext** ppObject) mut => VT.[Friend]GetSecurityCallContext(&this, ppObject);
}

[CRepr]struct SecurityProperty : IDispatch
{
	public new const Guid IID = .(0xe74a7215, 0x014d, 0x11d1, 0xa6, 0x3c, 0x00, 0xa0, 0xc9, 0x11, 0xb4, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrUserName) GetDirectCallerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrUserName) GetDirectCreatorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrUserName) GetOriginalCallerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrUserName) GetOriginalCreatorName;
	}


	public HRESULT GetDirectCallerName(BSTR* bstrUserName) mut => VT.[Friend]GetDirectCallerName(&this, bstrUserName);

	public HRESULT GetDirectCreatorName(BSTR* bstrUserName) mut => VT.[Friend]GetDirectCreatorName(&this, bstrUserName);

	public HRESULT GetOriginalCallerName(BSTR* bstrUserName) mut => VT.[Friend]GetOriginalCallerName(&this, bstrUserName);

	public HRESULT GetOriginalCreatorName(BSTR* bstrUserName) mut => VT.[Friend]GetOriginalCreatorName(&this, bstrUserName);
}

[CRepr]struct ContextInfo : IDispatch
{
	public new const Guid IID = .(0x19a5a02c, 0x0ac8, 0x11d2, 0xb2, 0x86, 0x00, 0xc0, 0x4f, 0x8e, 0xf9, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsInTx) IsInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppTx) GetTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTxId) GetTransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrActivityId) GetActivityId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCtxId) GetContextId;
	}


	public HRESULT IsInTransaction(int16* pbIsInTx) mut => VT.[Friend]IsInTransaction(&this, pbIsInTx);

	public HRESULT GetTransaction(IUnknown** ppTx) mut => VT.[Friend]GetTransaction(&this, ppTx);

	public HRESULT GetTransactionId(BSTR* pbstrTxId) mut => VT.[Friend]GetTransactionId(&this, pbstrTxId);

	public HRESULT GetActivityId(BSTR* pbstrActivityId) mut => VT.[Friend]GetActivityId(&this, pbstrActivityId);

	public HRESULT GetContextId(BSTR* pbstrCtxId) mut => VT.[Friend]GetContextId(&this, pbstrCtxId);
}

[CRepr]struct ContextInfo2 : ContextInfo
{
	public new const Guid IID = .(0xc99d6e75, 0x2375, 0x11d4, 0x83, 0x31, 0x00, 0xc0, 0x4f, 0x60, 0x55, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ContextInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* __MIDL__ContextInfo20000) GetPartitionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* __MIDL__ContextInfo20001) GetApplicationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* __MIDL__ContextInfo20002) GetApplicationInstanceId;
	}


	public HRESULT GetPartitionId(BSTR* __MIDL__ContextInfo20000) mut => VT.[Friend]GetPartitionId(&this, __MIDL__ContextInfo20000);

	public HRESULT GetApplicationId(BSTR* __MIDL__ContextInfo20001) mut => VT.[Friend]GetApplicationId(&this, __MIDL__ContextInfo20001);

	public HRESULT GetApplicationInstanceId(BSTR* __MIDL__ContextInfo20002) mut => VT.[Friend]GetApplicationInstanceId(&this, __MIDL__ContextInfo20002);
}

[CRepr]struct ObjectContext : IDispatch
{
	public new const Guid IID = .(0x74c08646, 0xcedb, 0x11cf, 0x8b, 0x49, 0x00, 0xaa, 0x00, 0xb8, 0xa7, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProgID, VARIANT* pObject) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsInTx) IsInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsEnabled) IsSecurityEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRole, int16* pbInRole) IsCallerInRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT* pItem) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SecurityProperty** ppSecurityProperty) get_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ContextInfo** ppContextInfo) get_ContextInfo;
	}


	public HRESULT CreateInstance(BSTR bstrProgID, VARIANT* pObject) mut => VT.[Friend]CreateInstance(&this, bstrProgID, pObject);

	public HRESULT SetComplete() mut => VT.[Friend]SetComplete(&this);

	public HRESULT SetAbort() mut => VT.[Friend]SetAbort(&this);

	public HRESULT EnableCommit() mut => VT.[Friend]EnableCommit(&this);

	public HRESULT DisableCommit() mut => VT.[Friend]DisableCommit(&this);

	public HRESULT IsInTransaction(int16* pbIsInTx) mut => VT.[Friend]IsInTransaction(&this, pbIsInTx);

	public HRESULT IsSecurityEnabled(int16* pbIsEnabled) mut => VT.[Friend]IsSecurityEnabled(&this, pbIsEnabled);

	public HRESULT IsCallerInRole(BSTR bstrRole, int16* pbInRole) mut => VT.[Friend]IsCallerInRole(&this, bstrRole, pbInRole);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_Item(BSTR name, VARIANT* pItem) mut => VT.[Friend]get_Item(&this, name, pItem);

	public HRESULT get__NewEnum(IUnknown** ppEnum) mut => VT.[Friend]get__NewEnum(&this, ppEnum);

	public HRESULT get_Security(SecurityProperty** ppSecurityProperty) mut => VT.[Friend]get_Security(&this, ppSecurityProperty);

	public HRESULT get_ContextInfo(ContextInfo** ppContextInfo) mut => VT.[Friend]get_ContextInfo(&this, ppContextInfo);
}

[CRepr]struct ITransactionContextEx : IUnknown
{
	public new const Guid IID = .(0x7999fc22, 0xd3c6, 0x11cf, 0xac, 0xab, 0x00, 0xa0, 0x24, 0xa5, 0x5a, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid riid, void** pObject) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
	}


	public HRESULT CreateInstance(in Guid rclsid, in Guid riid, void** pObject) mut => VT.[Friend]CreateInstance(&this, rclsid, riid, pObject);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);
}

[CRepr]struct ITransactionContext : IDispatch
{
	public new const Guid IID = .(0x7999fc21, 0xd3c6, 0x11cf, 0xac, 0xab, 0x00, 0xa0, 0x24, 0xa5, 0x5a, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pszProgId, VARIANT* pObject) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
	}


	public HRESULT CreateInstance(BSTR pszProgId, VARIANT* pObject) mut => VT.[Friend]CreateInstance(&this, pszProgId, pObject);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);
}

[CRepr]struct ICreateWithTransactionEx : IUnknown
{
	public new const Guid IID = .(0x455acf57, 0x5345, 0x11d2, 0x99, 0xcf, 0x00, 0xc0, 0x4f, 0x79, 0x7b, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pTransaction, in Guid rclsid, in Guid riid, void** pObject) CreateInstance;
	}


	public HRESULT CreateInstance(ITransaction* pTransaction, in Guid rclsid, in Guid riid, void** pObject) mut => VT.[Friend]CreateInstance(&this, pTransaction, rclsid, riid, pObject);
}

[CRepr]struct ICreateWithLocalTransaction : IUnknown
{
	public new const Guid IID = .(0x227ac7a8, 0x8423, 0x42ce, 0xb7, 0xcf, 0x03, 0x06, 0x1e, 0xc9, 0xaa, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pTransaction, in Guid rclsid, in Guid riid, void** pObject) CreateInstanceWithSysTx;
	}


	public HRESULT CreateInstanceWithSysTx(IUnknown* pTransaction, in Guid rclsid, in Guid riid, void** pObject) mut => VT.[Friend]CreateInstanceWithSysTx(&this, pTransaction, rclsid, riid, pObject);
}

[CRepr]struct ICreateWithTipTransactionEx : IUnknown
{
	public new const Guid IID = .(0x455acf59, 0x5345, 0x11d2, 0x99, 0xcf, 0x00, 0xc0, 0x4f, 0x79, 0x7b, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTipUrl, in Guid rclsid, in Guid riid, void** pObject) CreateInstance;
	}


	public HRESULT CreateInstance(BSTR bstrTipUrl, in Guid rclsid, in Guid riid, void** pObject) mut => VT.[Friend]CreateInstance(&this, bstrTipUrl, rclsid, riid, pObject);
}

[CRepr]struct IComLTxEvents : IUnknown
{
	public new const Guid IID = .(0x605cf82c, 0x578e, 0x4298, 0x97, 0x5d, 0x82, 0xba, 0xbc, 0xd9, 0xe0, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidLtx, Guid tsid, BOOL fRoot, int32 nIsolationLevel) OnLtxTransactionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidLtx, BOOL fVote) OnLtxTransactionPrepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidLtx) OnLtxTransactionAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidLtx) OnLtxTransactionCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidLtx, Guid txnId) OnLtxTransactionPromote;
	}


	public HRESULT OnLtxTransactionStart(COMSVCSEVENTINFO* pInfo, Guid guidLtx, Guid tsid, BOOL fRoot, int32 nIsolationLevel) mut => VT.[Friend]OnLtxTransactionStart(&this, pInfo, guidLtx, tsid, fRoot, nIsolationLevel);

	public HRESULT OnLtxTransactionPrepare(COMSVCSEVENTINFO* pInfo, Guid guidLtx, BOOL fVote) mut => VT.[Friend]OnLtxTransactionPrepare(&this, pInfo, guidLtx, fVote);

	public HRESULT OnLtxTransactionAbort(COMSVCSEVENTINFO* pInfo, Guid guidLtx) mut => VT.[Friend]OnLtxTransactionAbort(&this, pInfo, guidLtx);

	public HRESULT OnLtxTransactionCommit(COMSVCSEVENTINFO* pInfo, Guid guidLtx) mut => VT.[Friend]OnLtxTransactionCommit(&this, pInfo, guidLtx);

	public HRESULT OnLtxTransactionPromote(COMSVCSEVENTINFO* pInfo, Guid guidLtx, Guid txnId) mut => VT.[Friend]OnLtxTransactionPromote(&this, pInfo, guidLtx, txnId);
}

[CRepr]struct IComUserEvent : IUnknown
{
	public new const Guid IID = .(0x683130a4, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, VARIANT* pvarEvent) OnUserEvent;
	}


	public HRESULT OnUserEvent(COMSVCSEVENTINFO* pInfo, VARIANT* pvarEvent) mut => VT.[Friend]OnUserEvent(&this, pInfo, pvarEvent);
}

[CRepr]struct IComThreadEvents : IUnknown
{
	public new const Guid IID = .(0x683130a5, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint32 dwThread, uint32 dwTheadCnt) OnThreadStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint32 dwThread, uint32 dwTheadCnt) OnThreadTerminate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 AptID, uint32 dwActCnt, uint32 dwLowCnt) OnThreadBindToApartment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 AptID, uint32 dwActCnt) OnThreadUnBind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen) OnThreadWorkEnque;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID) OnThreadWorkPrivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen) OnThreadWorkPublic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen, uint64 ThreadNum) OnThreadWorkRedirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen) OnThreadWorkReject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, uint64 AptID) OnThreadAssignApartment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 AptID) OnThreadUnassignApartment;
	}


	public HRESULT OnThreadStart(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint32 dwThread, uint32 dwTheadCnt) mut => VT.[Friend]OnThreadStart(&this, pInfo, ThreadID, dwThread, dwTheadCnt);

	public HRESULT OnThreadTerminate(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint32 dwThread, uint32 dwTheadCnt) mut => VT.[Friend]OnThreadTerminate(&this, pInfo, ThreadID, dwThread, dwTheadCnt);

	public HRESULT OnThreadBindToApartment(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 AptID, uint32 dwActCnt, uint32 dwLowCnt) mut => VT.[Friend]OnThreadBindToApartment(&this, pInfo, ThreadID, AptID, dwActCnt, dwLowCnt);

	public HRESULT OnThreadUnBind(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 AptID, uint32 dwActCnt) mut => VT.[Friend]OnThreadUnBind(&this, pInfo, ThreadID, AptID, dwActCnt);

	public HRESULT OnThreadWorkEnque(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen) mut => VT.[Friend]OnThreadWorkEnque(&this, pInfo, ThreadID, MsgWorkID, QueueLen);

	public HRESULT OnThreadWorkPrivate(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID) mut => VT.[Friend]OnThreadWorkPrivate(&this, pInfo, ThreadID, MsgWorkID);

	public HRESULT OnThreadWorkPublic(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen) mut => VT.[Friend]OnThreadWorkPublic(&this, pInfo, ThreadID, MsgWorkID, QueueLen);

	public HRESULT OnThreadWorkRedirect(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen, uint64 ThreadNum) mut => VT.[Friend]OnThreadWorkRedirect(&this, pInfo, ThreadID, MsgWorkID, QueueLen, ThreadNum);

	public HRESULT OnThreadWorkReject(COMSVCSEVENTINFO* pInfo, uint64 ThreadID, uint64 MsgWorkID, uint32 QueueLen) mut => VT.[Friend]OnThreadWorkReject(&this, pInfo, ThreadID, MsgWorkID, QueueLen);

	public HRESULT OnThreadAssignApartment(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, uint64 AptID) mut => VT.[Friend]OnThreadAssignApartment(&this, pInfo, guidActivity, AptID);

	public HRESULT OnThreadUnassignApartment(COMSVCSEVENTINFO* pInfo, uint64 AptID) mut => VT.[Friend]OnThreadUnassignApartment(&this, pInfo, AptID);
}

[CRepr]struct IComAppEvents : IUnknown
{
	public new const Guid IID = .(0x683130a6, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnAppActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnAppShutdown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnAppForceShutdown;
	}


	public HRESULT OnAppActivation(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnAppActivation(&this, pInfo, guidApp);

	public HRESULT OnAppShutdown(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnAppShutdown(&this, pInfo, guidApp);

	public HRESULT OnAppForceShutdown(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnAppForceShutdown(&this, pInfo, guidApp);
}

[CRepr]struct IComInstanceEvents : IUnknown
{
	public new const Guid IID = .(0x683130a7, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid clsid, in Guid tsid, uint64 CtxtID, uint64 ObjectID) OnObjectCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID) OnObjectDestroy;
	}


	public HRESULT OnObjectCreate(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid clsid, in Guid tsid, uint64 CtxtID, uint64 ObjectID) mut => VT.[Friend]OnObjectCreate(&this, pInfo, guidActivity, clsid, tsid, CtxtID, ObjectID);

	public HRESULT OnObjectDestroy(COMSVCSEVENTINFO* pInfo, uint64 CtxtID) mut => VT.[Friend]OnObjectDestroy(&this, pInfo, CtxtID);
}

[CRepr]struct IComTransactionEvents : IUnknown
{
	public new const Guid IID = .(0x683130a8, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx, in Guid tsid, BOOL fRoot) OnTransactionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx, BOOL fVoteYes) OnTransactionPrepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx) OnTransactionAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx) OnTransactionCommit;
	}


	public HRESULT OnTransactionStart(COMSVCSEVENTINFO* pInfo, in Guid guidTx, in Guid tsid, BOOL fRoot) mut => VT.[Friend]OnTransactionStart(&this, pInfo, guidTx, tsid, fRoot);

	public HRESULT OnTransactionPrepare(COMSVCSEVENTINFO* pInfo, in Guid guidTx, BOOL fVoteYes) mut => VT.[Friend]OnTransactionPrepare(&this, pInfo, guidTx, fVoteYes);

	public HRESULT OnTransactionAbort(COMSVCSEVENTINFO* pInfo, in Guid guidTx) mut => VT.[Friend]OnTransactionAbort(&this, pInfo, guidTx);

	public HRESULT OnTransactionCommit(COMSVCSEVENTINFO* pInfo, in Guid guidTx) mut => VT.[Friend]OnTransactionCommit(&this, pInfo, guidTx);
}

[CRepr]struct IComMethodEvents : IUnknown
{
	public new const Guid IID = .(0x683130a9, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 iMeth) OnMethodCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 iMeth, HRESULT hresult) OnMethodReturn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 iMeth) OnMethodException;
	}


	public HRESULT OnMethodCall(COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 iMeth) mut => VT.[Friend]OnMethodCall(&this, pInfo, oid, guidCid, guidRid, iMeth);

	public HRESULT OnMethodReturn(COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 iMeth, HRESULT hresult) mut => VT.[Friend]OnMethodReturn(&this, pInfo, oid, guidCid, guidRid, iMeth, hresult);

	public HRESULT OnMethodException(COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 iMeth) mut => VT.[Friend]OnMethodException(&this, pInfo, oid, guidCid, guidRid, iMeth);
}

[CRepr]struct IComObjectEvents : IUnknown
{
	public new const Guid IID = .(0x683130aa, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID, uint64 ObjectID) OnObjectActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID, uint64 ObjectID) OnObjectDeactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID) OnDisableCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID) OnEnableCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID) OnSetComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID) OnSetAbort;
	}


	public HRESULT OnObjectActivate(COMSVCSEVENTINFO* pInfo, uint64 CtxtID, uint64 ObjectID) mut => VT.[Friend]OnObjectActivate(&this, pInfo, CtxtID, ObjectID);

	public HRESULT OnObjectDeactivate(COMSVCSEVENTINFO* pInfo, uint64 CtxtID, uint64 ObjectID) mut => VT.[Friend]OnObjectDeactivate(&this, pInfo, CtxtID, ObjectID);

	public HRESULT OnDisableCommit(COMSVCSEVENTINFO* pInfo, uint64 CtxtID) mut => VT.[Friend]OnDisableCommit(&this, pInfo, CtxtID);

	public HRESULT OnEnableCommit(COMSVCSEVENTINFO* pInfo, uint64 CtxtID) mut => VT.[Friend]OnEnableCommit(&this, pInfo, CtxtID);

	public HRESULT OnSetComplete(COMSVCSEVENTINFO* pInfo, uint64 CtxtID) mut => VT.[Friend]OnSetComplete(&this, pInfo, CtxtID);

	public HRESULT OnSetAbort(COMSVCSEVENTINFO* pInfo, uint64 CtxtID) mut => VT.[Friend]OnSetAbort(&this, pInfo, CtxtID);
}

[CRepr]struct IComResourceEvents : IUnknown
{
	public new const Guid IID = .(0x683130ab, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId, BOOL enlisted) OnResourceCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId, BOOL enlisted, uint32 NumRated, uint32 Rating) OnResourceAllocate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId) OnResourceRecycle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ObjectID, HRESULT hr, PWSTR pszType, uint64 resId) OnResourceDestroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId, BOOL enlisted) OnResourceTrack;
	}


	public HRESULT OnResourceCreate(COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId, BOOL enlisted) mut => VT.[Friend]OnResourceCreate(&this, pInfo, ObjectID, pszType, resId, enlisted);

	public HRESULT OnResourceAllocate(COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId, BOOL enlisted, uint32 NumRated, uint32 Rating) mut => VT.[Friend]OnResourceAllocate(&this, pInfo, ObjectID, pszType, resId, enlisted, NumRated, Rating);

	public HRESULT OnResourceRecycle(COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId) mut => VT.[Friend]OnResourceRecycle(&this, pInfo, ObjectID, pszType, resId);

	public HRESULT OnResourceDestroy(COMSVCSEVENTINFO* pInfo, uint64 ObjectID, HRESULT hr, PWSTR pszType, uint64 resId) mut => VT.[Friend]OnResourceDestroy(&this, pInfo, ObjectID, hr, pszType, resId);

	public HRESULT OnResourceTrack(COMSVCSEVENTINFO* pInfo, uint64 ObjectID, PWSTR pszType, uint64 resId, BOOL enlisted) mut => VT.[Friend]OnResourceTrack(&this, pInfo, ObjectID, pszType, resId, enlisted);
}

[CRepr]struct IComSecurityEvents : IUnknown
{
	public new const Guid IID = .(0x683130ac, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, uint64 ObjectID, in Guid guidIID, uint32 iMeth, uint32 cbByteOrig, uint8* pSidOriginalUser, uint32 cbByteCur, uint8* pSidCurrentUser, BOOL bCurrentUserInpersonatingInProc) OnAuthenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, uint64 ObjectID, in Guid guidIID, uint32 iMeth, uint32 cbByteOrig, uint8* pSidOriginalUser, uint32 cbByteCur, uint8* pSidCurrentUser, BOOL bCurrentUserInpersonatingInProc) OnAuthenticateFail;
	}


	public HRESULT OnAuthenticate(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, uint64 ObjectID, in Guid guidIID, uint32 iMeth, uint32 cbByteOrig, uint8* pSidOriginalUser, uint32 cbByteCur, uint8* pSidCurrentUser, BOOL bCurrentUserInpersonatingInProc) mut => VT.[Friend]OnAuthenticate(&this, pInfo, guidActivity, ObjectID, guidIID, iMeth, cbByteOrig, pSidOriginalUser, cbByteCur, pSidCurrentUser, bCurrentUserInpersonatingInProc);

	public HRESULT OnAuthenticateFail(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, uint64 ObjectID, in Guid guidIID, uint32 iMeth, uint32 cbByteOrig, uint8* pSidOriginalUser, uint32 cbByteCur, uint8* pSidCurrentUser, BOOL bCurrentUserInpersonatingInProc) mut => VT.[Friend]OnAuthenticateFail(&this, pInfo, guidActivity, ObjectID, guidIID, iMeth, cbByteOrig, pSidOriginalUser, cbByteCur, pSidCurrentUser, bCurrentUserInpersonatingInProc);
}

[CRepr]struct IComObjectPoolEvents : IUnknown
{
	public new const Guid IID = .(0x683130ad, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, int32 nReason, uint32 dwAvailable, uint64 oid) OnObjPoolPutObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, uint32 dwAvailable, uint64 oid) OnObjPoolGetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid) OnObjPoolRecycleToTx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid) OnObjPoolGetFromTx;
	}


	public HRESULT OnObjPoolPutObject(COMSVCSEVENTINFO* pInfo, in Guid guidObject, int32 nReason, uint32 dwAvailable, uint64 oid) mut => VT.[Friend]OnObjPoolPutObject(&this, pInfo, guidObject, nReason, dwAvailable, oid);

	public HRESULT OnObjPoolGetObject(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, uint32 dwAvailable, uint64 oid) mut => VT.[Friend]OnObjPoolGetObject(&this, pInfo, guidActivity, guidObject, dwAvailable, oid);

	public HRESULT OnObjPoolRecycleToTx(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid) mut => VT.[Friend]OnObjPoolRecycleToTx(&this, pInfo, guidActivity, guidObject, guidTx, objid);

	public HRESULT OnObjPoolGetFromTx(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid) mut => VT.[Friend]OnObjPoolGetFromTx(&this, pInfo, guidActivity, guidObject, guidTx, objid);
}

[CRepr]struct IComObjectPoolEvents2 : IUnknown
{
	public new const Guid IID = .(0x683130ae, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, uint32 dwObjsCreated, uint64 oid) OnObjPoolCreateObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, uint32 dwObjsCreated, uint64 oid) OnObjPoolDestroyObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint32 dwThreadsWaiting, uint32 dwAvail, uint32 dwCreated, uint32 dwMin, uint32 dwMax) OnObjPoolCreateDecision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, in Guid guidActivity, uint32 dwTimeout) OnObjPoolTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, uint32 dwMin, uint32 dwMax, uint32 dwTimeout) OnObjPoolCreatePool;
	}


	public HRESULT OnObjPoolCreateObject(COMSVCSEVENTINFO* pInfo, in Guid guidObject, uint32 dwObjsCreated, uint64 oid) mut => VT.[Friend]OnObjPoolCreateObject(&this, pInfo, guidObject, dwObjsCreated, oid);

	public HRESULT OnObjPoolDestroyObject(COMSVCSEVENTINFO* pInfo, in Guid guidObject, uint32 dwObjsCreated, uint64 oid) mut => VT.[Friend]OnObjPoolDestroyObject(&this, pInfo, guidObject, dwObjsCreated, oid);

	public HRESULT OnObjPoolCreateDecision(COMSVCSEVENTINFO* pInfo, uint32 dwThreadsWaiting, uint32 dwAvail, uint32 dwCreated, uint32 dwMin, uint32 dwMax) mut => VT.[Friend]OnObjPoolCreateDecision(&this, pInfo, dwThreadsWaiting, dwAvail, dwCreated, dwMin, dwMax);

	public HRESULT OnObjPoolTimeout(COMSVCSEVENTINFO* pInfo, in Guid guidObject, in Guid guidActivity, uint32 dwTimeout) mut => VT.[Friend]OnObjPoolTimeout(&this, pInfo, guidObject, guidActivity, dwTimeout);

	public HRESULT OnObjPoolCreatePool(COMSVCSEVENTINFO* pInfo, in Guid guidObject, uint32 dwMin, uint32 dwMax, uint32 dwTimeout) mut => VT.[Friend]OnObjPoolCreatePool(&this, pInfo, guidObject, dwMin, dwMax, dwTimeout);
}

[CRepr]struct IComObjectConstructionEvents : IUnknown
{
	public new const Guid IID = .(0x683130af, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, PWSTR sConstructString, uint64 oid) OnObjectConstruct;
	}


	public HRESULT OnObjectConstruct(COMSVCSEVENTINFO* pInfo, in Guid guidObject, PWSTR sConstructString, uint64 oid) mut => VT.[Friend]OnObjectConstruct(&this, pInfo, guidObject, sConstructString, oid);
}

[CRepr]struct IComActivityEvents : IUnknown
{
	public new const Guid IID = .(0x683130b0, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity) OnActivityCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity) OnActivityDestroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, in Guid guidEntered, uint32 dwThread) OnActivityEnter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, in Guid guidEntered, uint32 dwThread, uint32 dwTimeout) OnActivityTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, uint32 dwThread, uint32 dwCallDepth) OnActivityReenter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, in Guid guidLeft) OnActivityLeave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, uint32 dwCallDepth) OnActivityLeaveSame;
	}


	public HRESULT OnActivityCreate(COMSVCSEVENTINFO* pInfo, in Guid guidActivity) mut => VT.[Friend]OnActivityCreate(&this, pInfo, guidActivity);

	public HRESULT OnActivityDestroy(COMSVCSEVENTINFO* pInfo, in Guid guidActivity) mut => VT.[Friend]OnActivityDestroy(&this, pInfo, guidActivity);

	public HRESULT OnActivityEnter(COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, in Guid guidEntered, uint32 dwThread) mut => VT.[Friend]OnActivityEnter(&this, pInfo, guidCurrent, guidEntered, dwThread);

	public HRESULT OnActivityTimeout(COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, in Guid guidEntered, uint32 dwThread, uint32 dwTimeout) mut => VT.[Friend]OnActivityTimeout(&this, pInfo, guidCurrent, guidEntered, dwThread, dwTimeout);

	public HRESULT OnActivityReenter(COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, uint32 dwThread, uint32 dwCallDepth) mut => VT.[Friend]OnActivityReenter(&this, pInfo, guidCurrent, dwThread, dwCallDepth);

	public HRESULT OnActivityLeave(COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, in Guid guidLeft) mut => VT.[Friend]OnActivityLeave(&this, pInfo, guidCurrent, guidLeft);

	public HRESULT OnActivityLeaveSame(COMSVCSEVENTINFO* pInfo, in Guid guidCurrent, uint32 dwCallDepth) mut => VT.[Friend]OnActivityLeaveSame(&this, pInfo, guidCurrent, dwCallDepth);
}

[CRepr]struct IComIdentityEvents : IUnknown
{
	public new const Guid IID = .(0x683130b1, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 ObjId, PWSTR pszClientIP, PWSTR pszServerIP, PWSTR pszURL) OnIISRequestInfo;
	}


	public HRESULT OnIISRequestInfo(COMSVCSEVENTINFO* pInfo, uint64 ObjId, PWSTR pszClientIP, PWSTR pszServerIP, PWSTR pszURL) mut => VT.[Friend]OnIISRequestInfo(&this, pInfo, ObjId, pszClientIP, pszServerIP, pszURL);
}

[CRepr]struct IComQCEvents : IUnknown
{
	public new const Guid IID = .(0x683130b2, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 objid, char16* szQueue, in Guid guidMsgId, in Guid guidWorkFlowId, HRESULT msmqhr) OnQCRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, char16* szQueue, uint64 QueueID, HRESULT hr) OnQCQueueOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 QueueID, in Guid guidMsgId, in Guid guidWorkFlowId, HRESULT hr) OnQCReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 QueueID, HRESULT msmqhr) OnQCReceiveFail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidMsgId, in Guid guidWorkFlowId, uint32 RetryIndex) OnQCMoveToReTryQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidMsgId, in Guid guidWorkFlowId) OnQCMoveToDeadQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 objid, in Guid guidMsgId, in Guid guidWorkFlowId, HRESULT hr) OnQCPlayback;
	}


	public HRESULT OnQCRecord(COMSVCSEVENTINFO* pInfo, uint64 objid, char16* szQueue, in Guid guidMsgId, in Guid guidWorkFlowId, HRESULT msmqhr) mut => VT.[Friend]OnQCRecord(&this, pInfo, objid, szQueue, guidMsgId, guidWorkFlowId, msmqhr);

	public HRESULT OnQCQueueOpen(COMSVCSEVENTINFO* pInfo, char16* szQueue, uint64 QueueID, HRESULT hr) mut => VT.[Friend]OnQCQueueOpen(&this, pInfo, szQueue, QueueID, hr);

	public HRESULT OnQCReceive(COMSVCSEVENTINFO* pInfo, uint64 QueueID, in Guid guidMsgId, in Guid guidWorkFlowId, HRESULT hr) mut => VT.[Friend]OnQCReceive(&this, pInfo, QueueID, guidMsgId, guidWorkFlowId, hr);

	public HRESULT OnQCReceiveFail(COMSVCSEVENTINFO* pInfo, uint64 QueueID, HRESULT msmqhr) mut => VT.[Friend]OnQCReceiveFail(&this, pInfo, QueueID, msmqhr);

	public HRESULT OnQCMoveToReTryQueue(COMSVCSEVENTINFO* pInfo, in Guid guidMsgId, in Guid guidWorkFlowId, uint32 RetryIndex) mut => VT.[Friend]OnQCMoveToReTryQueue(&this, pInfo, guidMsgId, guidWorkFlowId, RetryIndex);

	public HRESULT OnQCMoveToDeadQueue(COMSVCSEVENTINFO* pInfo, in Guid guidMsgId, in Guid guidWorkFlowId) mut => VT.[Friend]OnQCMoveToDeadQueue(&this, pInfo, guidMsgId, guidWorkFlowId);

	public HRESULT OnQCPlayback(COMSVCSEVENTINFO* pInfo, uint64 objid, in Guid guidMsgId, in Guid guidWorkFlowId, HRESULT hr) mut => VT.[Friend]OnQCPlayback(&this, pInfo, objid, guidMsgId, guidWorkFlowId, hr);
}

[CRepr]struct IComExceptionEvents : IUnknown
{
	public new const Guid IID = .(0x683130b3, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint32 code, uint64 address, PWSTR pszStackTrace) OnExceptionUser;
	}


	public HRESULT OnExceptionUser(COMSVCSEVENTINFO* pInfo, uint32 code, uint64 address, PWSTR pszStackTrace) mut => VT.[Friend]OnExceptionUser(&this, pInfo, code, address, pszStackTrace);
}

[CRepr]struct ILBEvents : IUnknown
{
	public new const Guid IID = .(0x683130b4, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, BSTR bstrClsidEng) TargetUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, BSTR bstrClsidEng) TargetDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, VARIANT* varPropValue, BSTR bstrClsidEng) EngineDefined;
	}


	public HRESULT TargetUp(BSTR bstrServerName, BSTR bstrClsidEng) mut => VT.[Friend]TargetUp(&this, bstrServerName, bstrClsidEng);

	public HRESULT TargetDown(BSTR bstrServerName, BSTR bstrClsidEng) mut => VT.[Friend]TargetDown(&this, bstrServerName, bstrClsidEng);

	public HRESULT EngineDefined(BSTR bstrPropName, VARIANT* varPropValue, BSTR bstrClsidEng) mut => VT.[Friend]EngineDefined(&this, bstrPropName, varPropValue, bstrClsidEng);
}

[CRepr]struct IComCRMEvents : IUnknown
{
	public new const Guid IID = .(0x683130b5, 0x2e50, 0x11d2, 0x98, 0xa5, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnCRMRecoveryStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnCRMRecoveryDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnCRMCheckpoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, Guid guidActivity, Guid guidTx, char16* szProgIdCompensator, char16* szDescription) OnCRMBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMPrepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMIndoubt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMRelease;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, uint32 dwCrmRecordType, uint32 dwRecordSize) OnCRMAnalyze;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, BOOL fVariants, uint32 dwRecordSize) OnCRMWrite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMForget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) OnCRMForce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, BOOL fVariants, uint32 dwRecordSize) OnCRMDeliver;
	}


	public HRESULT OnCRMRecoveryStart(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnCRMRecoveryStart(&this, pInfo, guidApp);

	public HRESULT OnCRMRecoveryDone(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnCRMRecoveryDone(&this, pInfo, guidApp);

	public HRESULT OnCRMCheckpoint(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnCRMCheckpoint(&this, pInfo, guidApp);

	public HRESULT OnCRMBegin(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, Guid guidActivity, Guid guidTx, char16* szProgIdCompensator, char16* szDescription) mut => VT.[Friend]OnCRMBegin(&this, pInfo, guidClerkCLSID, guidActivity, guidTx, szProgIdCompensator, szDescription);

	public HRESULT OnCRMPrepare(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMPrepare(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMCommit(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMCommit(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMAbort(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMAbort(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMIndoubt(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMIndoubt(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMDone(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMDone(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMRelease(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMRelease(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMAnalyze(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, uint32 dwCrmRecordType, uint32 dwRecordSize) mut => VT.[Friend]OnCRMAnalyze(&this, pInfo, guidClerkCLSID, dwCrmRecordType, dwRecordSize);

	public HRESULT OnCRMWrite(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, BOOL fVariants, uint32 dwRecordSize) mut => VT.[Friend]OnCRMWrite(&this, pInfo, guidClerkCLSID, fVariants, dwRecordSize);

	public HRESULT OnCRMForget(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMForget(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMForce(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID) mut => VT.[Friend]OnCRMForce(&this, pInfo, guidClerkCLSID);

	public HRESULT OnCRMDeliver(COMSVCSEVENTINFO* pInfo, Guid guidClerkCLSID, BOOL fVariants, uint32 dwRecordSize) mut => VT.[Friend]OnCRMDeliver(&this, pInfo, guidClerkCLSID, fVariants, dwRecordSize);
}

[CRepr]struct IComMethod2Events : IUnknown
{
	public new const Guid IID = .(0xfb388aaa, 0x567d, 0x4024, 0xaf, 0x8e, 0x6e, 0x93, 0xee, 0x74, 0x85, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 dwThread, uint32 iMeth) OnMethodCall2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 dwThread, uint32 iMeth, HRESULT hresult) OnMethodReturn2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 dwThread, uint32 iMeth) OnMethodException2;
	}


	public HRESULT OnMethodCall2(COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 dwThread, uint32 iMeth) mut => VT.[Friend]OnMethodCall2(&this, pInfo, oid, guidCid, guidRid, dwThread, iMeth);

	public HRESULT OnMethodReturn2(COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 dwThread, uint32 iMeth, HRESULT hresult) mut => VT.[Friend]OnMethodReturn2(&this, pInfo, oid, guidCid, guidRid, dwThread, iMeth, hresult);

	public HRESULT OnMethodException2(COMSVCSEVENTINFO* pInfo, uint64 oid, in Guid guidCid, in Guid guidRid, uint32 dwThread, uint32 iMeth) mut => VT.[Friend]OnMethodException2(&this, pInfo, oid, guidCid, guidRid, dwThread, iMeth);
}

[CRepr]struct IComTrackingInfoEvents : IUnknown
{
	public new const Guid IID = .(0x4e6cdcc9, 0xfb25, 0x4fd5, 0x9c, 0xc5, 0xc9, 0xf4, 0xb6, 0x55, 0x9c, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pToplevelCollection) OnNewTrackingInfo;
	}


	public HRESULT OnNewTrackingInfo(IUnknown* pToplevelCollection) mut => VT.[Friend]OnNewTrackingInfo(&this, pToplevelCollection);
}

[CRepr]struct IComTrackingInfoCollection : IUnknown
{
	public new const Guid IID = .(0xc266c677, 0xc9ad, 0x49ab, 0x9f, 0xd9, 0xd9, 0x66, 0x10, 0x78, 0x58, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRACKING_COLL_TYPE* pType) Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, in Guid riid, void** ppv) Item;
	}


	public HRESULT Type(TRACKING_COLL_TYPE* pType) mut => VT.[Friend]Type(&this, pType);

	public HRESULT Count(uint32* pCount) mut => VT.[Friend]Count(&this, pCount);

	public HRESULT Item(uint32 ulIndex, in Guid riid, void** ppv) mut => VT.[Friend]Item(&this, ulIndex, riid, ppv);
}

[CRepr]struct IComTrackingInfoObject : IUnknown
{
	public new const Guid IID = .(0x116e42c5, 0xd8b1, 0x47bf, 0xab, 0x1e, 0xc8, 0x95, 0xed, 0x3e, 0x23, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szPropertyName, VARIANT* pvarOut) GetValue;
	}


	public HRESULT GetValue(PWSTR szPropertyName, VARIANT* pvarOut) mut => VT.[Friend]GetValue(&this, szPropertyName, pvarOut);
}

[CRepr]struct IComTrackingInfoProperties : IUnknown
{
	public new const Guid IID = .(0x789b42be, 0x6f6b, 0x443a, 0x89, 0x8e, 0x67, 0xab, 0xf3, 0x90, 0xaa, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) PropCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, PWSTR* ppszPropName) GetPropName;
	}


	public HRESULT PropCount(uint32* pCount) mut => VT.[Friend]PropCount(&this, pCount);

	public HRESULT GetPropName(uint32 ulIndex, PWSTR* ppszPropName) mut => VT.[Friend]GetPropName(&this, ulIndex, ppszPropName);
}

[CRepr]struct IComApp2Events : IUnknown
{
	public new const Guid IID = .(0x1290bc1a, 0xb219, 0x418d, 0xb0, 0x78, 0x59, 0x34, 0xde, 0xd0, 0x82, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp, Guid guidProcess) OnAppActivation2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnAppShutdown2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp) OnAppForceShutdown2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp, BOOL bPaused) OnAppPaused2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, Guid guidApp, Guid guidProcess, int32 lReason) OnAppRecycle2;
	}


	public HRESULT OnAppActivation2(COMSVCSEVENTINFO* pInfo, Guid guidApp, Guid guidProcess) mut => VT.[Friend]OnAppActivation2(&this, pInfo, guidApp, guidProcess);

	public HRESULT OnAppShutdown2(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnAppShutdown2(&this, pInfo, guidApp);

	public HRESULT OnAppForceShutdown2(COMSVCSEVENTINFO* pInfo, Guid guidApp) mut => VT.[Friend]OnAppForceShutdown2(&this, pInfo, guidApp);

	public HRESULT OnAppPaused2(COMSVCSEVENTINFO* pInfo, Guid guidApp, BOOL bPaused) mut => VT.[Friend]OnAppPaused2(&this, pInfo, guidApp, bPaused);

	public HRESULT OnAppRecycle2(COMSVCSEVENTINFO* pInfo, Guid guidApp, Guid guidProcess, int32 lReason) mut => VT.[Friend]OnAppRecycle2(&this, pInfo, guidApp, guidProcess, lReason);
}

[CRepr]struct IComTransaction2Events : IUnknown
{
	public new const Guid IID = .(0xa136f62a, 0x2f94, 0x4288, 0x86, 0xe0, 0xd8, 0xa1, 0xfa, 0x4c, 0x02, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx, in Guid tsid, BOOL fRoot, int32 nIsolationLevel) OnTransactionStart2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx, BOOL fVoteYes) OnTransactionPrepare2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx) OnTransactionAbort2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidTx) OnTransactionCommit2;
	}


	public HRESULT OnTransactionStart2(COMSVCSEVENTINFO* pInfo, in Guid guidTx, in Guid tsid, BOOL fRoot, int32 nIsolationLevel) mut => VT.[Friend]OnTransactionStart2(&this, pInfo, guidTx, tsid, fRoot, nIsolationLevel);

	public HRESULT OnTransactionPrepare2(COMSVCSEVENTINFO* pInfo, in Guid guidTx, BOOL fVoteYes) mut => VT.[Friend]OnTransactionPrepare2(&this, pInfo, guidTx, fVoteYes);

	public HRESULT OnTransactionAbort2(COMSVCSEVENTINFO* pInfo, in Guid guidTx) mut => VT.[Friend]OnTransactionAbort2(&this, pInfo, guidTx);

	public HRESULT OnTransactionCommit2(COMSVCSEVENTINFO* pInfo, in Guid guidTx) mut => VT.[Friend]OnTransactionCommit2(&this, pInfo, guidTx);
}

[CRepr]struct IComInstance2Events : IUnknown
{
	public new const Guid IID = .(0x20e3bf07, 0xb506, 0x4ad5, 0xa5, 0x0c, 0xd2, 0xca, 0x5b, 0x9c, 0x15, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid clsid, in Guid tsid, uint64 CtxtID, uint64 ObjectID, in Guid guidPartition) OnObjectCreate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, uint64 CtxtID) OnObjectDestroy2;
	}


	public HRESULT OnObjectCreate2(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid clsid, in Guid tsid, uint64 CtxtID, uint64 ObjectID, in Guid guidPartition) mut => VT.[Friend]OnObjectCreate2(&this, pInfo, guidActivity, clsid, tsid, CtxtID, ObjectID, guidPartition);

	public HRESULT OnObjectDestroy2(COMSVCSEVENTINFO* pInfo, uint64 CtxtID) mut => VT.[Friend]OnObjectDestroy2(&this, pInfo, CtxtID);
}

[CRepr]struct IComObjectPool2Events : IUnknown
{
	public new const Guid IID = .(0x65bf6534, 0x85ea, 0x4f64, 0x8c, 0xf4, 0x3d, 0x97, 0x4b, 0x2a, 0xb1, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, int32 nReason, uint32 dwAvailable, uint64 oid) OnObjPoolPutObject2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, uint32 dwAvailable, uint64 oid, in Guid guidPartition) OnObjPoolGetObject2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid) OnObjPoolRecycleToTx2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid, in Guid guidPartition) OnObjPoolGetFromTx2;
	}


	public HRESULT OnObjPoolPutObject2(COMSVCSEVENTINFO* pInfo, in Guid guidObject, int32 nReason, uint32 dwAvailable, uint64 oid) mut => VT.[Friend]OnObjPoolPutObject2(&this, pInfo, guidObject, nReason, dwAvailable, oid);

	public HRESULT OnObjPoolGetObject2(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, uint32 dwAvailable, uint64 oid, in Guid guidPartition) mut => VT.[Friend]OnObjPoolGetObject2(&this, pInfo, guidActivity, guidObject, dwAvailable, oid, guidPartition);

	public HRESULT OnObjPoolRecycleToTx2(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid) mut => VT.[Friend]OnObjPoolRecycleToTx2(&this, pInfo, guidActivity, guidObject, guidTx, objid);

	public HRESULT OnObjPoolGetFromTx2(COMSVCSEVENTINFO* pInfo, in Guid guidActivity, in Guid guidObject, in Guid guidTx, uint64 objid, in Guid guidPartition) mut => VT.[Friend]OnObjPoolGetFromTx2(&this, pInfo, guidActivity, guidObject, guidTx, objid, guidPartition);
}

[CRepr]struct IComObjectConstruction2Events : IUnknown
{
	public new const Guid IID = .(0x4b5a7827, 0x8df2, 0x45c0, 0x8f, 0x6f, 0x57, 0xea, 0x1f, 0x85, 0x6a, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMSVCSEVENTINFO* pInfo, in Guid guidObject, PWSTR sConstructString, uint64 oid, in Guid guidPartition) OnObjectConstruct2;
	}


	public HRESULT OnObjectConstruct2(COMSVCSEVENTINFO* pInfo, in Guid guidObject, PWSTR sConstructString, uint64 oid, in Guid guidPartition) mut => VT.[Friend]OnObjectConstruct2(&this, pInfo, guidObject, sConstructString, oid, guidPartition);
}

[CRepr]struct ISystemAppEventData : IUnknown
{
	public new const Guid IID = .(0xd6d48a3c, 0xd5c5, 0x49e7, 0x8c, 0x74, 0x99, 0xe4, 0x88, 0x9e, 0xd5, 0x2f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Startup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwPID, uint32 dwMask, uint32 dwNumberSinks, BSTR bstrDwMethodMask, uint32 dwReason, uint64 u64TraceHandle) OnDataChanged;
	}


	public HRESULT Startup() mut => VT.[Friend]Startup(&this);

	public HRESULT OnDataChanged(uint32 dwPID, uint32 dwMask, uint32 dwNumberSinks, BSTR bstrDwMethodMask, uint32 dwReason, uint64 u64TraceHandle) mut => VT.[Friend]OnDataChanged(&this, dwPID, dwMask, dwNumberSinks, bstrDwMethodMask, dwReason, u64TraceHandle);
}

[CRepr]struct IMtsEvents : IDispatch
{
	public new const Guid IID = .(0xbacedf4d, 0x74ab, 0x11d0, 0xb1, 0x62, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_PackageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_PackageGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* vEvent) PostEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_FireEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* id) GetProcessID;
	}


	public HRESULT get_PackageName(BSTR* pVal) mut => VT.[Friend]get_PackageName(&this, pVal);

	public HRESULT get_PackageGuid(BSTR* pVal) mut => VT.[Friend]get_PackageGuid(&this, pVal);

	public HRESULT PostEvent(VARIANT* vEvent) mut => VT.[Friend]PostEvent(&this, vEvent);

	public HRESULT get_FireEvents(int16* pVal) mut => VT.[Friend]get_FireEvents(&this, pVal);

	public HRESULT GetProcessID(int32* id) mut => VT.[Friend]GetProcessID(&this, id);
}

[CRepr]struct IMtsEventInfo : IDispatch
{
	public new const Guid IID = .(0xd56c3dc1, 0x8482, 0x11d0, 0xb1, 0x70, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pUnk) get_Names;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* sDisplayName) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* sGuidEventID) get_EventID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR sKey, VARIANT* pVal) get_Value;
	}


	public HRESULT get_Names(IUnknown** pUnk) mut => VT.[Friend]get_Names(&this, pUnk);

	public HRESULT get_DisplayName(BSTR* sDisplayName) mut => VT.[Friend]get_DisplayName(&this, sDisplayName);

	public HRESULT get_EventID(BSTR* sGuidEventID) mut => VT.[Friend]get_EventID(&this, sGuidEventID);

	public HRESULT get_Count(int32* lCount) mut => VT.[Friend]get_Count(&this, lCount);

	public HRESULT get_Value(BSTR sKey, VARIANT* pVal) mut => VT.[Friend]get_Value(&this, sKey, pVal);
}

[CRepr]struct IMTSLocator : IDispatch
{
	public new const Guid IID = .(0xd19b8bfd, 0x7f88, 0x11d0, 0xb1, 0x6e, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pUnk) GetEventDispatcher;
	}


	public HRESULT GetEventDispatcher(IUnknown** pUnk) mut => VT.[Friend]GetEventDispatcher(&this, pUnk);
}

[CRepr]struct IMtsGrp : IDispatch
{
	public new const Guid IID = .(0x4b2e958c, 0x0393, 0x11d1, 0xb1, 0xab, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IUnknown** ppUnkDispatcher) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT Item(int32 lIndex, IUnknown** ppUnkDispatcher) mut => VT.[Friend]Item(&this, lIndex, ppUnkDispatcher);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);
}

[CRepr]struct IMessageMover : IDispatch
{
	public new const Guid IID = .(0x588a085a, 0xb795, 0x11d1, 0x80, 0x54, 0x00, 0xc0, 0x4f, 0xc3, 0x40, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_SourcePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_SourcePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_DestPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_DestPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_CommitBatchSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 newVal) put_CommitBatchSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMessagesMoved) MoveMessages;
	}


	public HRESULT get_SourcePath(BSTR* pVal) mut => VT.[Friend]get_SourcePath(&this, pVal);

	public HRESULT put_SourcePath(BSTR newVal) mut => VT.[Friend]put_SourcePath(&this, newVal);

	public HRESULT get_DestPath(BSTR* pVal) mut => VT.[Friend]get_DestPath(&this, pVal);

	public HRESULT put_DestPath(BSTR newVal) mut => VT.[Friend]put_DestPath(&this, newVal);

	public HRESULT get_CommitBatchSize(int32* pVal) mut => VT.[Friend]get_CommitBatchSize(&this, pVal);

	public HRESULT put_CommitBatchSize(int32 newVal) mut => VT.[Friend]put_CommitBatchSize(&this, newVal);

	public HRESULT MoveMessages(int32* plMessagesMoved) mut => VT.[Friend]MoveMessages(&this, plMessagesMoved);
}

[CRepr]struct IEventServerTrace : IDispatch
{
	public new const Guid IID = .(0x9a9f12b8, 0x80af, 0x47ab, 0xa5, 0x79, 0x35, 0xea, 0x57, 0x72, 0x53, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrguidEvent, BSTR bstrguidFilter, int32 lPidFilter) StartTraceGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrguidEvent, BSTR bstrguidFilter, int32 lPidFilter) StopTraceGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCntGuids, BSTR* pbstrGuidList) EnumTraceGuid;
	}


	public HRESULT StartTraceGuid(BSTR bstrguidEvent, BSTR bstrguidFilter, int32 lPidFilter) mut => VT.[Friend]StartTraceGuid(&this, bstrguidEvent, bstrguidFilter, lPidFilter);

	public HRESULT StopTraceGuid(BSTR bstrguidEvent, BSTR bstrguidFilter, int32 lPidFilter) mut => VT.[Friend]StopTraceGuid(&this, bstrguidEvent, bstrguidFilter, lPidFilter);

	public HRESULT EnumTraceGuid(int32* plCntGuids, BSTR* pbstrGuidList) mut => VT.[Friend]EnumTraceGuid(&this, plCntGuids, pbstrGuidList);
}

[CRepr]struct IGetAppTrackerData : IUnknown
{
	public new const Guid IID = .(0x507c3ac8, 0x3e12, 0x4cb0, 0x93, 0x66, 0x65, 0x3d, 0x3e, 0x05, 0x06, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid PartitionId, in Guid ApplicationId, uint32 Flags, uint32* NumApplicationProcesses, ApplicationProcessSummary** ApplicationProcesses) GetApplicationProcesses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ApplicationInstanceId, uint32 ProcessId, uint32 Flags, ApplicationProcessSummary* Summary, ApplicationProcessStatistics* Statistics, ApplicationProcessRecycleInfo* RecycleInfo, BOOL* AnyComponentsHangMonitored) GetApplicationProcessDetails;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ApplicationInstanceId, uint32 ProcessId, in Guid PartitionId, uint32 Flags, uint32* NumApplicationsInProcess, ApplicationSummary** Applications) GetApplicationsInProcess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ApplicationInstanceId, uint32 ProcessId, in Guid PartitionId, in Guid ApplicationId, uint32 Flags, uint32* NumComponentsInProcess, ComponentSummary** Components) GetComponentsInProcess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ApplicationInstanceId, uint32 ProcessId, in Guid Clsid, uint32 Flags, ComponentSummary* Summary, ComponentStatistics* Statistics, ComponentHangMonitorInfo* HangMonitorInfo) GetComponentDetails;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** TopLevelCollection) GetTrackerDataAsCollectionObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* PollingIntervalInSeconds) GetSuggestedPollingInterval;
	}


	public HRESULT GetApplicationProcesses(in Guid PartitionId, in Guid ApplicationId, uint32 Flags, uint32* NumApplicationProcesses, ApplicationProcessSummary** ApplicationProcesses) mut => VT.[Friend]GetApplicationProcesses(&this, PartitionId, ApplicationId, Flags, NumApplicationProcesses, ApplicationProcesses);

	public HRESULT GetApplicationProcessDetails(in Guid ApplicationInstanceId, uint32 ProcessId, uint32 Flags, ApplicationProcessSummary* Summary, ApplicationProcessStatistics* Statistics, ApplicationProcessRecycleInfo* RecycleInfo, BOOL* AnyComponentsHangMonitored) mut => VT.[Friend]GetApplicationProcessDetails(&this, ApplicationInstanceId, ProcessId, Flags, Summary, Statistics, RecycleInfo, AnyComponentsHangMonitored);

	public HRESULT GetApplicationsInProcess(in Guid ApplicationInstanceId, uint32 ProcessId, in Guid PartitionId, uint32 Flags, uint32* NumApplicationsInProcess, ApplicationSummary** Applications) mut => VT.[Friend]GetApplicationsInProcess(&this, ApplicationInstanceId, ProcessId, PartitionId, Flags, NumApplicationsInProcess, Applications);

	public HRESULT GetComponentsInProcess(in Guid ApplicationInstanceId, uint32 ProcessId, in Guid PartitionId, in Guid ApplicationId, uint32 Flags, uint32* NumComponentsInProcess, ComponentSummary** Components) mut => VT.[Friend]GetComponentsInProcess(&this, ApplicationInstanceId, ProcessId, PartitionId, ApplicationId, Flags, NumComponentsInProcess, Components);

	public HRESULT GetComponentDetails(in Guid ApplicationInstanceId, uint32 ProcessId, in Guid Clsid, uint32 Flags, ComponentSummary* Summary, ComponentStatistics* Statistics, ComponentHangMonitorInfo* HangMonitorInfo) mut => VT.[Friend]GetComponentDetails(&this, ApplicationInstanceId, ProcessId, Clsid, Flags, Summary, Statistics, HangMonitorInfo);

	public HRESULT GetTrackerDataAsCollectionObject(IUnknown** TopLevelCollection) mut => VT.[Friend]GetTrackerDataAsCollectionObject(&this, TopLevelCollection);

	public HRESULT GetSuggestedPollingInterval(uint32* PollingIntervalInSeconds) mut => VT.[Friend]GetSuggestedPollingInterval(&this, PollingIntervalInSeconds);
}

[CRepr]struct IDispenserManager : IUnknown
{
	public new const Guid IID = .(0x5cb31e10, 0x2b5f, 0x11cf, 0xbe, 0x10, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispenserDriver* __MIDL__IDispenserManager0000, PWSTR szDispenserName, IHolder** __MIDL__IDispenserManager0001) RegisterDispenser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* __MIDL__IDispenserManager0002, uint* __MIDL__IDispenserManager0003) GetContext;
	}


	public HRESULT RegisterDispenser(IDispenserDriver* __MIDL__IDispenserManager0000, PWSTR szDispenserName, IHolder** __MIDL__IDispenserManager0001) mut => VT.[Friend]RegisterDispenser(&this, __MIDL__IDispenserManager0000, szDispenserName, __MIDL__IDispenserManager0001);

	public HRESULT GetContext(uint* __MIDL__IDispenserManager0002, uint* __MIDL__IDispenserManager0003) mut => VT.[Friend]GetContext(&this, __MIDL__IDispenserManager0002, __MIDL__IDispenserManager0003);
}

[CRepr]struct IHolder : IUnknown
{
	public new const Guid IID = .(0xbf6a1850, 0x2b45, 0x11cf, 0xbe, 0x10, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint __MIDL__IHolder0000, uint* __MIDL__IHolder0001) AllocResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint __MIDL__IHolder0002) FreeResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint __MIDL__IHolder0003) TrackResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* __MIDL__IHolder0004) TrackResourceS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint __MIDL__IHolder0005, BOOL __MIDL__IHolder0006) UntrackResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* __MIDL__IHolder0007, BOOL __MIDL__IHolder0008) UntrackResourceS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint __MIDL__IHolder0009) RequestDestroyResource;
	}


	public HRESULT AllocResource(uint __MIDL__IHolder0000, uint* __MIDL__IHolder0001) mut => VT.[Friend]AllocResource(&this, __MIDL__IHolder0000, __MIDL__IHolder0001);

	public HRESULT FreeResource(uint __MIDL__IHolder0002) mut => VT.[Friend]FreeResource(&this, __MIDL__IHolder0002);

	public HRESULT TrackResource(uint __MIDL__IHolder0003) mut => VT.[Friend]TrackResource(&this, __MIDL__IHolder0003);

	public HRESULT TrackResourceS(uint16* __MIDL__IHolder0004) mut => VT.[Friend]TrackResourceS(&this, __MIDL__IHolder0004);

	public HRESULT UntrackResource(uint __MIDL__IHolder0005, BOOL __MIDL__IHolder0006) mut => VT.[Friend]UntrackResource(&this, __MIDL__IHolder0005, __MIDL__IHolder0006);

	public HRESULT UntrackResourceS(uint16* __MIDL__IHolder0007, BOOL __MIDL__IHolder0008) mut => VT.[Friend]UntrackResourceS(&this, __MIDL__IHolder0007, __MIDL__IHolder0008);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT RequestDestroyResource(uint __MIDL__IHolder0009) mut => VT.[Friend]RequestDestroyResource(&this, __MIDL__IHolder0009);
}

[CRepr]struct IDispenserDriver : IUnknown
{
	public new const Guid IID = .(0x208b3651, 0x2b48, 0x11cf, 0xbe, 0x10, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ResTypId, uint* pResId, int32* pSecsFreeBeforeDestroy) CreateResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ResTypId, uint ResId, BOOL fRequiresTransactionEnlistment, uint32* pRating) RateResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ResId, uint TransId) EnlistResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ResId) ResetResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ResId) DestroyResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* ResId) DestroyResourceS;
	}


	public HRESULT CreateResource(uint ResTypId, uint* pResId, int32* pSecsFreeBeforeDestroy) mut => VT.[Friend]CreateResource(&this, ResTypId, pResId, pSecsFreeBeforeDestroy);

	public HRESULT RateResource(uint ResTypId, uint ResId, BOOL fRequiresTransactionEnlistment, uint32* pRating) mut => VT.[Friend]RateResource(&this, ResTypId, ResId, fRequiresTransactionEnlistment, pRating);

	public HRESULT EnlistResource(uint ResId, uint TransId) mut => VT.[Friend]EnlistResource(&this, ResId, TransId);

	public HRESULT ResetResource(uint ResId) mut => VT.[Friend]ResetResource(&this, ResId);

	public HRESULT DestroyResource(uint ResId) mut => VT.[Friend]DestroyResource(&this, ResId);

	public HRESULT DestroyResourceS(uint16* ResId) mut => VT.[Friend]DestroyResourceS(&this, ResId);
}

[CRepr]struct ITransactionProxy : IUnknown
{
	public new const Guid IID = .(0x02558374, 0xdf2e, 0x4dae, 0xbd, 0x6b, 0x1d, 0x5c, 0x99, 0x4f, 0x9b, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guid) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction** pTransaction) Promote;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionVoterNotifyAsync2* pTxAsync, ITransactionVoterBallotAsync2** ppBallot) CreateVoter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* __MIDL__ITransactionProxy0000) GetIsolationLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pbstrIdentifier) GetIdentifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsReusable) IsReusable;
	}


	public HRESULT Commit(Guid guid) mut => VT.[Friend]Commit(&this, guid);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);

	public HRESULT Promote(ITransaction** pTransaction) mut => VT.[Friend]Promote(&this, pTransaction);

	public HRESULT CreateVoter(ITransactionVoterNotifyAsync2* pTxAsync, ITransactionVoterBallotAsync2** ppBallot) mut => VT.[Friend]CreateVoter(&this, pTxAsync, ppBallot);

	public HRESULT GetIsolationLevel(int32* __MIDL__ITransactionProxy0000) mut => VT.[Friend]GetIsolationLevel(&this, __MIDL__ITransactionProxy0000);

	public HRESULT GetIdentifier(Guid* pbstrIdentifier) mut => VT.[Friend]GetIdentifier(&this, pbstrIdentifier);

	public HRESULT IsReusable(BOOL* pfIsReusable) mut => VT.[Friend]IsReusable(&this, pfIsReusable);
}

[CRepr]struct IContextSecurityPerimeter : IUnknown
{
	public new const Guid IID = .(0xa7549a29, 0xa7c4, 0x42e1, 0x8d, 0xc1, 0x7e, 0x3d, 0x74, 0x8d, 0xc2, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pFlag) GetPerimeterFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFlag) SetPerimeterFlag;
	}


	public HRESULT GetPerimeterFlag(BOOL* pFlag) mut => VT.[Friend]GetPerimeterFlag(&this, pFlag);

	public HRESULT SetPerimeterFlag(BOOL fFlag) mut => VT.[Friend]SetPerimeterFlag(&this, fFlag);
}

[CRepr]struct ITxProxyHolder : IUnknown
{
	public new const Guid IID = .(0x13d86f31, 0x0139, 0x41af, 0xbc, 0xad, 0xc7, 0xd5, 0x04, 0x35, 0xfe, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid* pGuidLtx) GetIdentifier;
	}


	public void GetIdentifier(Guid* pGuidLtx) mut => VT.[Friend]GetIdentifier(&this, pGuidLtx);
}

[CRepr]struct IObjectContext : IUnknown
{
	public new const Guid IID = .(0x51372ae0, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid riid, void** ppv) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableCommit;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsInTransaction;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsSecurityEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRole, BOOL* pfIsInRole) IsCallerInRole;
	}


	public HRESULT CreateInstance(in Guid rclsid, in Guid riid, void** ppv) mut => VT.[Friend]CreateInstance(&this, rclsid, riid, ppv);

	public HRESULT SetComplete() mut => VT.[Friend]SetComplete(&this);

	public HRESULT SetAbort() mut => VT.[Friend]SetAbort(&this);

	public HRESULT EnableCommit() mut => VT.[Friend]EnableCommit(&this);

	public HRESULT DisableCommit() mut => VT.[Friend]DisableCommit(&this);

	public BOOL IsInTransaction() mut => VT.[Friend]IsInTransaction(&this);

	public BOOL IsSecurityEnabled() mut => VT.[Friend]IsSecurityEnabled(&this);

	public HRESULT IsCallerInRole(BSTR bstrRole, BOOL* pfIsInRole) mut => VT.[Friend]IsCallerInRole(&this, bstrRole, pfIsInRole);
}

[CRepr]struct IObjectControl : IUnknown
{
	public new const Guid IID = .(0x51372aec, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Activate;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Deactivate;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) CanBePooled;
	}


	public HRESULT Activate() mut => VT.[Friend]Activate(&this);

	public void Deactivate() mut => VT.[Friend]Deactivate(&this);

	public BOOL CanBePooled() mut => VT.[Friend]CanBePooled(&this);
}

[CRepr]struct IEnumNames : IUnknown
{
	public new const Guid IID = .(0x51372af2, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, BSTR* rgname, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNames** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, BSTR* rgname, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgname, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNames** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISecurityProperty : IUnknown
{
	public new const Guid IID = .(0x51372aea, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID* pSID) GetDirectCreatorSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID* pSID) GetOriginalCreatorSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID* pSID) GetDirectCallerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID* pSID) GetOriginalCallerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSID pSID) ReleaseSID;
	}


	public HRESULT GetDirectCreatorSID(PSID* pSID) mut => VT.[Friend]GetDirectCreatorSID(&this, pSID);

	public HRESULT GetOriginalCreatorSID(PSID* pSID) mut => VT.[Friend]GetOriginalCreatorSID(&this, pSID);

	public HRESULT GetDirectCallerSID(PSID* pSID) mut => VT.[Friend]GetDirectCallerSID(&this, pSID);

	public HRESULT GetOriginalCallerSID(PSID* pSID) mut => VT.[Friend]GetOriginalCallerSID(&this, pSID);

	public HRESULT ReleaseSID(PSID pSID) mut => VT.[Friend]ReleaseSID(&this, pSID);
}

[CRepr]struct ObjectControl : IUnknown
{
	public new const Guid IID = .(0x7dc41850, 0x0c31, 0x11d0, 0x8b, 0x79, 0x00, 0xaa, 0x00, 0xb8, 0xa7, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Deactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbPoolable) CanBePooled;
	}


	public HRESULT Activate() mut => VT.[Friend]Activate(&this);

	public HRESULT Deactivate() mut => VT.[Friend]Deactivate(&this);

	public HRESULT CanBePooled(int16* pbPoolable) mut => VT.[Friend]CanBePooled(&this, pbPoolable);
}

[CRepr]struct ISharedProperty : IDispatch
{
	public new const Guid IID = .(0x2a005c01, 0xa5de, 0x11cf, 0x9e, 0x66, 0x00, 0xaa, 0x00, 0xa3, 0xf4, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT val) put_Value;
	}


	public HRESULT get_Value(VARIANT* pVal) mut => VT.[Friend]get_Value(&this, pVal);

	public HRESULT put_Value(VARIANT val) mut => VT.[Friend]put_Value(&this, val);
}

[CRepr]struct ISharedPropertyGroup : IDispatch
{
	public new const Guid IID = .(0x2a005c07, 0xa5de, 0x11cf, 0x9e, 0x66, 0x00, 0xaa, 0x00, 0xa3, 0xf4, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int16* fExists, ISharedProperty** ppProp) CreatePropertyByPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISharedProperty** ppProperty) get_PropertyByPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, int16* fExists, ISharedProperty** ppProp) CreateProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, ISharedProperty** ppProperty) get_Property;
	}


	public HRESULT CreatePropertyByPosition(int32 Index, int16* fExists, ISharedProperty** ppProp) mut => VT.[Friend]CreatePropertyByPosition(&this, Index, fExists, ppProp);

	public HRESULT get_PropertyByPosition(int32 Index, ISharedProperty** ppProperty) mut => VT.[Friend]get_PropertyByPosition(&this, Index, ppProperty);

	public HRESULT CreateProperty(BSTR Name, int16* fExists, ISharedProperty** ppProp) mut => VT.[Friend]CreateProperty(&this, Name, fExists, ppProp);

	public HRESULT get_Property(BSTR Name, ISharedProperty** ppProperty) mut => VT.[Friend]get_Property(&this, Name, ppProperty);
}

[CRepr]struct ISharedPropertyGroupManager : IDispatch
{
	public new const Guid IID = .(0x2a005c0d, 0xa5de, 0x11cf, 0x9e, 0x66, 0x00, 0xaa, 0x00, 0xa3, 0xf4, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, int32* dwIsoMode, int32* dwRelMode, int16* fExists, ISharedPropertyGroup** ppGroup) CreatePropertyGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, ISharedPropertyGroup** ppGroup) get_Group;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
	}


	public HRESULT CreatePropertyGroup(BSTR Name, int32* dwIsoMode, int32* dwRelMode, int16* fExists, ISharedPropertyGroup** ppGroup) mut => VT.[Friend]CreatePropertyGroup(&this, Name, dwIsoMode, dwRelMode, fExists, ppGroup);

	public HRESULT get_Group(BSTR Name, ISharedPropertyGroup** ppGroup) mut => VT.[Friend]get_Group(&this, Name, ppGroup);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);
}

[CRepr]struct IObjectConstruct : IUnknown
{
	public new const Guid IID = .(0x41c4f8b3, 0x7439, 0x11d2, 0x98, 0xcb, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pCtorObj) Construct;
	}


	public HRESULT Construct(IDispatch* pCtorObj) mut => VT.[Friend]Construct(&this, pCtorObj);
}

[CRepr]struct IObjectConstructString : IDispatch
{
	public new const Guid IID = .(0x41c4f8b2, 0x7439, 0x11d2, 0x98, 0xcb, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ConstructString;
	}


	public HRESULT get_ConstructString(BSTR* pVal) mut => VT.[Friend]get_ConstructString(&this, pVal);
}

[CRepr]struct IObjectContextActivity : IUnknown
{
	public new const Guid IID = .(0x51372afc, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGUID) GetActivityId;
	}


	public HRESULT GetActivityId(Guid* pGUID) mut => VT.[Friend]GetActivityId(&this, pGUID);
}

[CRepr]struct IObjectContextInfo : IUnknown
{
	public new const Guid IID = .(0x75b52ddb, 0xe8ed, 0x11d1, 0x93, 0xad, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pptrans) GetTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetTransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGUID) GetActivityId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetContextId;
	}


	public BOOL IsInTransaction() mut => VT.[Friend]IsInTransaction(&this);

	public HRESULT GetTransaction(IUnknown** pptrans) mut => VT.[Friend]GetTransaction(&this, pptrans);

	public HRESULT GetTransactionId(Guid* pGuid) mut => VT.[Friend]GetTransactionId(&this, pGuid);

	public HRESULT GetActivityId(Guid* pGUID) mut => VT.[Friend]GetActivityId(&this, pGUID);

	public HRESULT GetContextId(Guid* pGuid) mut => VT.[Friend]GetContextId(&this, pGuid);
}

[CRepr]struct IObjectContextInfo2 : IObjectContextInfo
{
	public new const Guid IID = .(0x594be71a, 0x4bc4, 0x438b, 0x91, 0x97, 0xcf, 0xd1, 0x76, 0x24, 0x8b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IObjectContextInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetPartitionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetApplicationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetApplicationInstanceId;
	}


	public HRESULT GetPartitionId(Guid* pGuid) mut => VT.[Friend]GetPartitionId(&this, pGuid);

	public HRESULT GetApplicationId(Guid* pGuid) mut => VT.[Friend]GetApplicationId(&this, pGuid);

	public HRESULT GetApplicationInstanceId(Guid* pGuid) mut => VT.[Friend]GetApplicationInstanceId(&this, pGuid);
}

[CRepr]struct ITransactionStatus : IUnknown
{
	public new const Guid IID = .(0x61f589e8, 0x3724, 0x4898, 0xa0, 0xa4, 0x66, 0x4a, 0xe9, 0xe1, 0xd1, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrStatus) SetTransactionStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* pHrStatus) GetTransactionStatus;
	}


	public HRESULT SetTransactionStatus(HRESULT hrStatus) mut => VT.[Friend]SetTransactionStatus(&this, hrStatus);

	public HRESULT GetTransactionStatus(HRESULT* pHrStatus) mut => VT.[Friend]GetTransactionStatus(&this, pHrStatus);
}

[CRepr]struct IObjectContextTip : IUnknown
{
	public new const Guid IID = .(0x92fd41ca, 0xbad9, 0x11d2, 0x9a, 0x2d, 0x00, 0xc0, 0x4f, 0x79, 0x7b, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pTipUrl) GetTipUrl;
	}


	public HRESULT GetTipUrl(BSTR* pTipUrl) mut => VT.[Friend]GetTipUrl(&this, pTipUrl);
}

[CRepr]struct IPlaybackControl : IUnknown
{
	public new const Guid IID = .(0x51372afd, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FinalClientRetry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FinalServerRetry;
	}


	public HRESULT FinalClientRetry() mut => VT.[Friend]FinalClientRetry(&this);

	public HRESULT FinalServerRetry() mut => VT.[Friend]FinalServerRetry(&this);
}

[CRepr]struct IGetContextProperties : IUnknown
{
	public new const Guid IID = .(0x51372af4, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT* pProperty) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNames** ppenum) EnumNames;
	}


	public HRESULT Count(int32* plCount) mut => VT.[Friend]Count(&this, plCount);

	public HRESULT GetProperty(BSTR name, VARIANT* pProperty) mut => VT.[Friend]GetProperty(&this, name, pProperty);

	public HRESULT EnumNames(IEnumNames** ppenum) mut => VT.[Friend]EnumNames(&this, ppenum);
}

[CRepr]struct IContextState : IUnknown
{
	public new const Guid IID = .(0x3c05e54b, 0xa42a, 0x11d2, 0xaf, 0xc4, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bDeactivate) SetDeactivateOnReturn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbDeactivate) GetDeactivateOnReturn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TransactionVote txVote) SetMyTransactionVote;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TransactionVote* ptxVote) GetMyTransactionVote;
	}


	public HRESULT SetDeactivateOnReturn(int16 bDeactivate) mut => VT.[Friend]SetDeactivateOnReturn(&this, bDeactivate);

	public HRESULT GetDeactivateOnReturn(int16* pbDeactivate) mut => VT.[Friend]GetDeactivateOnReturn(&this, pbDeactivate);

	public HRESULT SetMyTransactionVote(TransactionVote txVote) mut => VT.[Friend]SetMyTransactionVote(&this, txVote);

	public HRESULT GetMyTransactionVote(TransactionVote* ptxVote) mut => VT.[Friend]GetMyTransactionVote(&this, ptxVote);
}

[CRepr]struct IPoolManager : IDispatch
{
	public new const Guid IID = .(0x0a469861, 0x5a91, 0x43a0, 0x99, 0xb6, 0xd5, 0xe1, 0x79, 0xbb, 0x06, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR CLSIDOrProgID) ShutdownPool;
	}


	public HRESULT ShutdownPool(BSTR CLSIDOrProgID) mut => VT.[Friend]ShutdownPool(&this, CLSIDOrProgID);
}

[CRepr]struct ISelectCOMLBServer : IUnknown
{
	public new const Guid IID = .(0xdcf443f4, 0x3f8a, 0x4872, 0xb9, 0xf0, 0x36, 0x9a, 0x79, 0x6d, 0x12, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnk) GetLBServer;
	}


	public HRESULT Init() mut => VT.[Friend]Init(&this);

	public HRESULT GetLBServer(IUnknown* pUnk) mut => VT.[Friend]GetLBServer(&this, pUnk);
}

[CRepr]struct ICOMLBArguments : IUnknown
{
	public new const Guid IID = .(0x3a0f150f, 0x8ee5, 0x4b94, 0xb4, 0x0e, 0xae, 0xf2, 0xf9, 0xe4, 0x2e, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pCLSID) GetCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pCLSID) SetCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchSvr, char16* szServerName) GetMachineName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchSvr, char16* szServerName) SetMachineName;
	}


	public HRESULT GetCLSID(Guid* pCLSID) mut => VT.[Friend]GetCLSID(&this, pCLSID);

	public HRESULT SetCLSID(Guid* pCLSID) mut => VT.[Friend]SetCLSID(&this, pCLSID);

	public HRESULT GetMachineName(uint32 cchSvr, char16* szServerName) mut => VT.[Friend]GetMachineName(&this, cchSvr, szServerName);

	public HRESULT SetMachineName(uint32 cchSvr, char16* szServerName) mut => VT.[Friend]SetMachineName(&this, cchSvr, szServerName);
}

[CRepr]struct ICrmLogControl : IUnknown
{
	public new const Guid IID = .(0xa0e174b3, 0xd26e, 0x11d2, 0x8f, 0x84, 0x00, 0x80, 0x5f, 0xc7, 0xbc, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TransactionUOW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpcwstrProgIdCompensator, PWSTR lpcwstrDescription, int32 lCrmRegFlags) RegisterCompensator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pLogRecord) WriteLogRecordVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ForceLog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ForgetLogRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ForceTransactionToAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BLOB* rgBlob, uint32 cBlob) WriteLogRecord;
	}


	public HRESULT get_TransactionUOW(BSTR* pVal) mut => VT.[Friend]get_TransactionUOW(&this, pVal);

	public HRESULT RegisterCompensator(PWSTR lpcwstrProgIdCompensator, PWSTR lpcwstrDescription, int32 lCrmRegFlags) mut => VT.[Friend]RegisterCompensator(&this, lpcwstrProgIdCompensator, lpcwstrDescription, lCrmRegFlags);

	public HRESULT WriteLogRecordVariants(VARIANT* pLogRecord) mut => VT.[Friend]WriteLogRecordVariants(&this, pLogRecord);

	public HRESULT ForceLog() mut => VT.[Friend]ForceLog(&this);

	public HRESULT ForgetLogRecord() mut => VT.[Friend]ForgetLogRecord(&this);

	public HRESULT ForceTransactionToAbort() mut => VT.[Friend]ForceTransactionToAbort(&this);

	public HRESULT WriteLogRecord(BLOB* rgBlob, uint32 cBlob) mut => VT.[Friend]WriteLogRecord(&this, rgBlob, cBlob);
}

[CRepr]struct ICrmCompensatorVariants : IUnknown
{
	public new const Guid IID = .(0xf0baf8e4, 0x7804, 0x11d1, 0x82, 0xe9, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICrmLogControl* pLogControl) SetLogControlVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginPrepareVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pLogRecord, int16* pbForget) PrepareRecordVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbOkToPrepare) EndPrepareVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRecovery) BeginCommitVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pLogRecord, int16* pbForget) CommitRecordVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndCommitVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRecovery) BeginAbortVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pLogRecord, int16* pbForget) AbortRecordVariants;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndAbortVariants;
	}


	public HRESULT SetLogControlVariants(ICrmLogControl* pLogControl) mut => VT.[Friend]SetLogControlVariants(&this, pLogControl);

	public HRESULT BeginPrepareVariants() mut => VT.[Friend]BeginPrepareVariants(&this);

	public HRESULT PrepareRecordVariants(VARIANT* pLogRecord, int16* pbForget) mut => VT.[Friend]PrepareRecordVariants(&this, pLogRecord, pbForget);

	public HRESULT EndPrepareVariants(int16* pbOkToPrepare) mut => VT.[Friend]EndPrepareVariants(&this, pbOkToPrepare);

	public HRESULT BeginCommitVariants(int16 bRecovery) mut => VT.[Friend]BeginCommitVariants(&this, bRecovery);

	public HRESULT CommitRecordVariants(VARIANT* pLogRecord, int16* pbForget) mut => VT.[Friend]CommitRecordVariants(&this, pLogRecord, pbForget);

	public HRESULT EndCommitVariants() mut => VT.[Friend]EndCommitVariants(&this);

	public HRESULT BeginAbortVariants(int16 bRecovery) mut => VT.[Friend]BeginAbortVariants(&this, bRecovery);

	public HRESULT AbortRecordVariants(VARIANT* pLogRecord, int16* pbForget) mut => VT.[Friend]AbortRecordVariants(&this, pLogRecord, pbForget);

	public HRESULT EndAbortVariants() mut => VT.[Friend]EndAbortVariants(&this);
}

[CRepr]struct ICrmCompensator : IUnknown
{
	public new const Guid IID = .(0xbbc01830, 0x8d3b, 0x11d1, 0x82, 0xec, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICrmLogControl* pLogControl) SetLogControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginPrepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CrmLogRecordRead crmLogRec, BOOL* pfForget) PrepareRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfOkToPrepare) EndPrepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRecovery) BeginCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CrmLogRecordRead crmLogRec, BOOL* pfForget) CommitRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRecovery) BeginAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CrmLogRecordRead crmLogRec, BOOL* pfForget) AbortRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndAbort;
	}


	public HRESULT SetLogControl(ICrmLogControl* pLogControl) mut => VT.[Friend]SetLogControl(&this, pLogControl);

	public HRESULT BeginPrepare() mut => VT.[Friend]BeginPrepare(&this);

	public HRESULT PrepareRecord(CrmLogRecordRead crmLogRec, BOOL* pfForget) mut => VT.[Friend]PrepareRecord(&this, crmLogRec, pfForget);

	public HRESULT EndPrepare(BOOL* pfOkToPrepare) mut => VT.[Friend]EndPrepare(&this, pfOkToPrepare);

	public HRESULT BeginCommit(BOOL fRecovery) mut => VT.[Friend]BeginCommit(&this, fRecovery);

	public HRESULT CommitRecord(CrmLogRecordRead crmLogRec, BOOL* pfForget) mut => VT.[Friend]CommitRecord(&this, crmLogRec, pfForget);

	public HRESULT EndCommit() mut => VT.[Friend]EndCommit(&this);

	public HRESULT BeginAbort(BOOL fRecovery) mut => VT.[Friend]BeginAbort(&this, fRecovery);

	public HRESULT AbortRecord(CrmLogRecordRead crmLogRec, BOOL* pfForget) mut => VT.[Friend]AbortRecord(&this, crmLogRec, pfForget);

	public HRESULT EndAbort() mut => VT.[Friend]EndAbort(&this);
}

[CRepr]struct ICrmMonitorLogRecords : IUnknown
{
	public new const Guid IID = .(0x70c8e441, 0xc7ed, 0x11d1, 0x82, 0xfb, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CrmTransactionState* pVal) get_TransactionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_StructuredRecords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, CrmLogRecordRead* pCrmLogRec) GetLogRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT IndexNumber, VARIANT* pLogRecord) GetLogRecordVariants;
	}


	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_TransactionState(CrmTransactionState* pVal) mut => VT.[Friend]get_TransactionState(&this, pVal);

	public HRESULT get_StructuredRecords(int16* pVal) mut => VT.[Friend]get_StructuredRecords(&this, pVal);

	public HRESULT GetLogRecord(uint32 dwIndex, CrmLogRecordRead* pCrmLogRec) mut => VT.[Friend]GetLogRecord(&this, dwIndex, pCrmLogRec);

	public HRESULT GetLogRecordVariants(VARIANT IndexNumber, VARIANT* pLogRecord) mut => VT.[Friend]GetLogRecordVariants(&this, IndexNumber, pLogRecord);
}

[CRepr]struct ICrmMonitorClerks : IDispatch
{
	public new const Guid IID = .(0x70c8e442, 0xc7ed, 0x11d1, 0x82, 0xfb, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Index, VARIANT* pItem) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Index, VARIANT* pItem) ProgIdCompensator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Index, VARIANT* pItem) Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Index, VARIANT* pItem) TransactionUOW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Index, VARIANT* pItem) ActivityId;
	}


	public HRESULT Item(VARIANT Index, VARIANT* pItem) mut => VT.[Friend]Item(&this, Index, pItem);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT ProgIdCompensator(VARIANT Index, VARIANT* pItem) mut => VT.[Friend]ProgIdCompensator(&this, Index, pItem);

	public HRESULT Description(VARIANT Index, VARIANT* pItem) mut => VT.[Friend]Description(&this, Index, pItem);

	public HRESULT TransactionUOW(VARIANT Index, VARIANT* pItem) mut => VT.[Friend]TransactionUOW(&this, Index, pItem);

	public HRESULT ActivityId(VARIANT Index, VARIANT* pItem) mut => VT.[Friend]ActivityId(&this, Index, pItem);
}

[CRepr]struct ICrmMonitor : IUnknown
{
	public new const Guid IID = .(0x70c8e443, 0xc7ed, 0x11d1, 0x82, 0xfb, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICrmMonitorClerks** pClerks) GetClerks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Index, VARIANT* pItem) HoldClerk;
	}


	public HRESULT GetClerks(ICrmMonitorClerks** pClerks) mut => VT.[Friend]GetClerks(&this, pClerks);

	public HRESULT HoldClerk(VARIANT Index, VARIANT* pItem) mut => VT.[Friend]HoldClerk(&this, Index, pItem);
}

[CRepr]struct ICrmFormatLogRecords : IUnknown
{
	public new const Guid IID = .(0x9c51d821, 0xc98b, 0x11d1, 0x82, 0xfb, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plColumnCount) GetColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pHeaders) GetColumnHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CrmLogRecordRead CrmLogRec, VARIANT* pFormattedLogRecord) GetColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LogRecord, VARIANT* pFormattedLogRecord) GetColumnVariants;
	}


	public HRESULT GetColumnCount(int32* plColumnCount) mut => VT.[Friend]GetColumnCount(&this, plColumnCount);

	public HRESULT GetColumnHeaders(VARIANT* pHeaders) mut => VT.[Friend]GetColumnHeaders(&this, pHeaders);

	public HRESULT GetColumn(CrmLogRecordRead CrmLogRec, VARIANT* pFormattedLogRecord) mut => VT.[Friend]GetColumn(&this, CrmLogRec, pFormattedLogRecord);

	public HRESULT GetColumnVariants(VARIANT LogRecord, VARIANT* pFormattedLogRecord) mut => VT.[Friend]GetColumnVariants(&this, LogRecord, pFormattedLogRecord);
}

[CRepr]struct IServiceIISIntrinsicsConfig : IUnknown
{
	public new const Guid IID = .(0x1a0cf920, 0xd452, 0x46f4, 0xbc, 0x36, 0x48, 0x11, 0x8d, 0x54, 0xea, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_IISIntrinsicsConfig iisIntrinsicsConfig) IISIntrinsicsConfig;
	}


	public HRESULT IISIntrinsicsConfig(CSC_IISIntrinsicsConfig iisIntrinsicsConfig) mut => VT.[Friend]IISIntrinsicsConfig(&this, iisIntrinsicsConfig);
}

[CRepr]struct IServiceComTIIntrinsicsConfig : IUnknown
{
	public new const Guid IID = .(0x09e6831e, 0x04e1, 0x4ed4, 0x9d, 0x0f, 0xe8, 0xb1, 0x68, 0xba, 0xfe, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_COMTIIntrinsicsConfig comtiIntrinsicsConfig) ComTIIntrinsicsConfig;
	}


	public HRESULT ComTIIntrinsicsConfig(CSC_COMTIIntrinsicsConfig comtiIntrinsicsConfig) mut => VT.[Friend]ComTIIntrinsicsConfig(&this, comtiIntrinsicsConfig);
}

[CRepr]struct IServiceSxsConfig : IUnknown
{
	public new const Guid IID = .(0xc7cd7379, 0xf3f2, 0x4634, 0x81, 0x1b, 0x70, 0x32, 0x81, 0xd7, 0x3e, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_SxsConfig scsConfig) SxsConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szSxsName) SxsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szSxsDirectory) SxsDirectory;
	}


	public HRESULT SxsConfig(CSC_SxsConfig scsConfig) mut => VT.[Friend]SxsConfig(&this, scsConfig);

	public HRESULT SxsName(PWSTR szSxsName) mut => VT.[Friend]SxsName(&this, szSxsName);

	public HRESULT SxsDirectory(PWSTR szSxsDirectory) mut => VT.[Friend]SxsDirectory(&this, szSxsDirectory);
}

[CRepr]struct ICheckSxsConfig : IUnknown
{
	public new const Guid IID = .(0x0ff5a96f, 0x11fc, 0x47d1, 0xba, 0xa6, 0x25, 0xdd, 0x34, 0x7e, 0x72, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszSxsName, PWSTR wszSxsDirectory, PWSTR wszSxsAppName) IsSameSxsConfig;
	}


	public HRESULT IsSameSxsConfig(PWSTR wszSxsName, PWSTR wszSxsDirectory, PWSTR wszSxsAppName) mut => VT.[Friend]IsSameSxsConfig(&this, wszSxsName, wszSxsDirectory, wszSxsAppName);
}

[CRepr]struct IServiceInheritanceConfig : IUnknown
{
	public new const Guid IID = .(0x92186771, 0xd3b4, 0x4d77, 0xa8, 0xea, 0xee, 0x84, 0x2d, 0x58, 0x6f, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_InheritanceConfig inheritanceConfig) ContainingContextTreatment;
	}


	public HRESULT ContainingContextTreatment(CSC_InheritanceConfig inheritanceConfig) mut => VT.[Friend]ContainingContextTreatment(&this, inheritanceConfig);
}

[CRepr]struct IServiceThreadPoolConfig : IUnknown
{
	public new const Guid IID = .(0x186d89bc, 0xf277, 0x4bcc, 0x80, 0xd5, 0x4d, 0xf7, 0xb8, 0x36, 0xef, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_ThreadPool threadPool) SelectThreadPool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_Binding binding) SetBindingInfo;
	}


	public HRESULT SelectThreadPool(CSC_ThreadPool threadPool) mut => VT.[Friend]SelectThreadPool(&this, threadPool);

	public HRESULT SetBindingInfo(CSC_Binding binding) mut => VT.[Friend]SetBindingInfo(&this, binding);
}

[CRepr]struct IServiceTransactionConfigBase : IUnknown
{
	public new const Guid IID = .(0x772b3fbe, 0x6ffd, 0x42fb, 0xb5, 0xf8, 0x8f, 0x9b, 0x26, 0x0f, 0x38, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_TransactionConfig transactionConfig) ConfigureTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMAdminTxIsolationLevelOptions option) IsolationLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulTimeoutSec) TransactionTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szTipURL) BringYourOwnTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szTxDesc) NewTransactionDescription;
	}


	public HRESULT ConfigureTransaction(CSC_TransactionConfig transactionConfig) mut => VT.[Friend]ConfigureTransaction(&this, transactionConfig);

	public HRESULT IsolationLevel(COMAdminTxIsolationLevelOptions option) mut => VT.[Friend]IsolationLevel(&this, option);

	public HRESULT TransactionTimeout(uint32 ulTimeoutSec) mut => VT.[Friend]TransactionTimeout(&this, ulTimeoutSec);

	public HRESULT BringYourOwnTransaction(PWSTR szTipURL) mut => VT.[Friend]BringYourOwnTransaction(&this, szTipURL);

	public HRESULT NewTransactionDescription(PWSTR szTxDesc) mut => VT.[Friend]NewTransactionDescription(&this, szTxDesc);
}

[CRepr]struct IServiceTransactionConfig : IServiceTransactionConfigBase
{
	public new const Guid IID = .(0x59f4c2a3, 0xd3d7, 0x4a31, 0xb6, 0xe4, 0x6a, 0xb3, 0x17, 0x7c, 0x50, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IServiceTransactionConfigBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pITxByot) ConfigureBYOT;
	}


	public HRESULT ConfigureBYOT(ITransaction* pITxByot) mut => VT.[Friend]ConfigureBYOT(&this, pITxByot);
}

[CRepr]struct IServiceSysTxnConfig : IServiceTransactionConfig
{
	public new const Guid IID = .(0x33caf1a1, 0xfcb8, 0x472b, 0xb4, 0x5e, 0x96, 0x74, 0x48, 0xde, 0xd6, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IServiceTransactionConfig.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionProxy* pTxProxy) ConfigureBYOTSysTxn;
	}


	public HRESULT ConfigureBYOTSysTxn(ITransactionProxy* pTxProxy) mut => VT.[Friend]ConfigureBYOTSysTxn(&this, pTxProxy);
}

[CRepr]struct IServiceSynchronizationConfig : IUnknown
{
	public new const Guid IID = .(0xfd880e81, 0x6dce, 0x4c58, 0xaf, 0x83, 0xa2, 0x08, 0x84, 0x6c, 0x00, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_SynchronizationConfig synchConfig) ConfigureSynchronization;
	}


	public HRESULT ConfigureSynchronization(CSC_SynchronizationConfig synchConfig) mut => VT.[Friend]ConfigureSynchronization(&this, synchConfig);
}

[CRepr]struct IServiceTrackerConfig : IUnknown
{
	public new const Guid IID = .(0x6c3a3e1d, 0x0ba6, 0x4036, 0xb7, 0x6f, 0xd0, 0x40, 0x4d, 0xb8, 0x16, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_TrackerConfig trackerConfig, PWSTR szTrackerAppName, PWSTR szTrackerCtxName) TrackerConfig;
	}


	public HRESULT TrackerConfig(CSC_TrackerConfig trackerConfig, PWSTR szTrackerAppName, PWSTR szTrackerCtxName) mut => VT.[Friend]TrackerConfig(&this, trackerConfig, szTrackerAppName, szTrackerCtxName);
}

[CRepr]struct IServicePartitionConfig : IUnknown
{
	public new const Guid IID = .(0x80182d03, 0x5ea4, 0x4831, 0xae, 0x97, 0x55, 0xbe, 0xff, 0xc2, 0xe5, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CSC_PartitionConfig partitionConfig) PartitionConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidPartitionID) PartitionID;
	}


	public HRESULT PartitionConfig(CSC_PartitionConfig partitionConfig) mut => VT.[Friend]PartitionConfig(&this, partitionConfig);

	public HRESULT PartitionID(in Guid guidPartitionID) mut => VT.[Friend]PartitionID(&this, guidPartitionID);
}

[CRepr]struct IServiceCall : IUnknown
{
	public new const Guid IID = .(0xbd3e2e12, 0x42dd, 0x40f4, 0xa0, 0x9a, 0x95, 0xa5, 0x0c, 0x58, 0x30, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnCall;
	}


	public HRESULT OnCall() mut => VT.[Friend]OnCall(&this);
}

[CRepr]struct IAsyncErrorNotify : IUnknown
{
	public new const Guid IID = .(0xfe6777fb, 0xa674, 0x4177, 0x8f, 0x32, 0x6d, 0x70, 0x7e, 0x11, 0x34, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) OnError;
	}


	public HRESULT OnError(HRESULT hr) mut => VT.[Friend]OnError(&this, hr);
}

[CRepr]struct IServiceActivity : IUnknown
{
	public new const Guid IID = .(0x67532e0c, 0x9e2f, 0x4450, 0xa3, 0x54, 0x03, 0x56, 0x33, 0x94, 0x4e, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IServiceCall* pIServiceCall) SynchronousCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IServiceCall* pIServiceCall) AsynchronousCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BindToCurrentThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnbindFromThread;
	}


	public HRESULT SynchronousCall(IServiceCall* pIServiceCall) mut => VT.[Friend]SynchronousCall(&this, pIServiceCall);

	public HRESULT AsynchronousCall(IServiceCall* pIServiceCall) mut => VT.[Friend]AsynchronousCall(&this, pIServiceCall);

	public HRESULT BindToCurrentThread() mut => VT.[Friend]BindToCurrentThread(&this);

	public HRESULT UnbindFromThread() mut => VT.[Friend]UnbindFromThread(&this);
}

[CRepr]struct IThreadPoolKnobs : IUnknown
{
	public new const Guid IID = .(0x51372af7, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plcMaxThreads) GetMaxThreads;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plcCurrentThreads) GetCurrentThreads;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lcMaxThreads) SetMaxThreads;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pmsecDeleteDelay) GetDeleteDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 msecDeleteDelay) SetDeleteDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plcMaxQueuedRequests) GetMaxQueuedRequests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plcCurrentQueuedRequests) GetCurrentQueuedRequests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lcMaxQueuedRequests) SetMaxQueuedRequests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lcMinThreads) SetMinThreads;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lcQueueDepth) SetQueueDepth;
	}


	public HRESULT GetMaxThreads(int32* plcMaxThreads) mut => VT.[Friend]GetMaxThreads(&this, plcMaxThreads);

	public HRESULT GetCurrentThreads(int32* plcCurrentThreads) mut => VT.[Friend]GetCurrentThreads(&this, plcCurrentThreads);

	public HRESULT SetMaxThreads(int32 lcMaxThreads) mut => VT.[Friend]SetMaxThreads(&this, lcMaxThreads);

	public HRESULT GetDeleteDelay(int32* pmsecDeleteDelay) mut => VT.[Friend]GetDeleteDelay(&this, pmsecDeleteDelay);

	public HRESULT SetDeleteDelay(int32 msecDeleteDelay) mut => VT.[Friend]SetDeleteDelay(&this, msecDeleteDelay);

	public HRESULT GetMaxQueuedRequests(int32* plcMaxQueuedRequests) mut => VT.[Friend]GetMaxQueuedRequests(&this, plcMaxQueuedRequests);

	public HRESULT GetCurrentQueuedRequests(int32* plcCurrentQueuedRequests) mut => VT.[Friend]GetCurrentQueuedRequests(&this, plcCurrentQueuedRequests);

	public HRESULT SetMaxQueuedRequests(int32 lcMaxQueuedRequests) mut => VT.[Friend]SetMaxQueuedRequests(&this, lcMaxQueuedRequests);

	public HRESULT SetMinThreads(int32 lcMinThreads) mut => VT.[Friend]SetMinThreads(&this, lcMinThreads);

	public HRESULT SetQueueDepth(int32 lcQueueDepth) mut => VT.[Friend]SetQueueDepth(&this, lcQueueDepth);
}

[CRepr]struct IComStaThreadPoolKnobs : IUnknown
{
	public new const Guid IID = .(0x324b64fa, 0x33b6, 0x11d2, 0x98, 0xb7, 0x00, 0xc0, 0x4f, 0x8e, 0xe1, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 minThreads) SetMinThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* minThreads) GetMinThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 maxThreads) SetMaxThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* maxThreads) GetMaxThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 activitiesPerThread) SetActivityPerThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* activitiesPerThread) GetActivityPerThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double activityRatio) SetActivityRatio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* activityRatio) GetActivityRatio;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwThreads) GetThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwQDepth) GetQueueDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwQDepth) SetQueueDepth;
	}


	public HRESULT SetMinThreadCount(uint32 minThreads) mut => VT.[Friend]SetMinThreadCount(&this, minThreads);

	public HRESULT GetMinThreadCount(uint32* minThreads) mut => VT.[Friend]GetMinThreadCount(&this, minThreads);

	public HRESULT SetMaxThreadCount(uint32 maxThreads) mut => VT.[Friend]SetMaxThreadCount(&this, maxThreads);

	public HRESULT GetMaxThreadCount(uint32* maxThreads) mut => VT.[Friend]GetMaxThreadCount(&this, maxThreads);

	public HRESULT SetActivityPerThread(uint32 activitiesPerThread) mut => VT.[Friend]SetActivityPerThread(&this, activitiesPerThread);

	public HRESULT GetActivityPerThread(uint32* activitiesPerThread) mut => VT.[Friend]GetActivityPerThread(&this, activitiesPerThread);

	public HRESULT SetActivityRatio(double activityRatio) mut => VT.[Friend]SetActivityRatio(&this, activityRatio);

	public HRESULT GetActivityRatio(double* activityRatio) mut => VT.[Friend]GetActivityRatio(&this, activityRatio);

	public HRESULT GetThreadCount(uint32* pdwThreads) mut => VT.[Friend]GetThreadCount(&this, pdwThreads);

	public HRESULT GetQueueDepth(uint32* pdwQDepth) mut => VT.[Friend]GetQueueDepth(&this, pdwQDepth);

	public HRESULT SetQueueDepth(int32 dwQDepth) mut => VT.[Friend]SetQueueDepth(&this, dwQDepth);
}

[CRepr]struct IComMtaThreadPoolKnobs : IUnknown
{
	public new const Guid IID = .(0xf9a76d2e, 0x76a5, 0x43eb, 0xa0, 0xc4, 0x49, 0xbe, 0xc8, 0xe4, 0x84, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxThreads) MTASetMaxThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxThreads) MTAGetMaxThreadCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThrottle) MTASetThrottleValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwThrottle) MTAGetThrottleValue;
	}


	public HRESULT MTASetMaxThreadCount(uint32 dwMaxThreads) mut => VT.[Friend]MTASetMaxThreadCount(&this, dwMaxThreads);

	public HRESULT MTAGetMaxThreadCount(uint32* pdwMaxThreads) mut => VT.[Friend]MTAGetMaxThreadCount(&this, pdwMaxThreads);

	public HRESULT MTASetThrottleValue(uint32 dwThrottle) mut => VT.[Friend]MTASetThrottleValue(&this, dwThrottle);

	public HRESULT MTAGetThrottleValue(uint32* pdwThrottle) mut => VT.[Friend]MTAGetThrottleValue(&this, pdwThrottle);
}

[CRepr]struct IComStaThreadPoolKnobs2 : IComStaThreadPoolKnobs
{
	public new const Guid IID = .(0x73707523, 0xff9a, 0x4974, 0xbf, 0x84, 0x21, 0x08, 0xdc, 0x21, 0x37, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IComStaThreadPoolKnobs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLoad) GetMaxCPULoad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 pdwLoad) SetMaxCPULoad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbMetricEnabled) GetCPUMetricEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMetricEnabled) SetCPUMetricEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbMetricEnabled) GetCreateThreadsAggressively;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMetricEnabled) SetCreateThreadsAggressively;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCSR) GetMaxCSR;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwCSR) SetMaxCSR;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwThreadCleanupWaitTime) GetWaitTimeForThreadCleanup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwThreadCleanupWaitTime) SetWaitTimeForThreadCleanup;
	}


	public HRESULT GetMaxCPULoad(uint32* pdwLoad) mut => VT.[Friend]GetMaxCPULoad(&this, pdwLoad);

	public HRESULT SetMaxCPULoad(int32 pdwLoad) mut => VT.[Friend]SetMaxCPULoad(&this, pdwLoad);

	public HRESULT GetCPUMetricEnabled(BOOL* pbMetricEnabled) mut => VT.[Friend]GetCPUMetricEnabled(&this, pbMetricEnabled);

	public HRESULT SetCPUMetricEnabled(BOOL bMetricEnabled) mut => VT.[Friend]SetCPUMetricEnabled(&this, bMetricEnabled);

	public HRESULT GetCreateThreadsAggressively(BOOL* pbMetricEnabled) mut => VT.[Friend]GetCreateThreadsAggressively(&this, pbMetricEnabled);

	public HRESULT SetCreateThreadsAggressively(BOOL bMetricEnabled) mut => VT.[Friend]SetCreateThreadsAggressively(&this, bMetricEnabled);

	public HRESULT GetMaxCSR(uint32* pdwCSR) mut => VT.[Friend]GetMaxCSR(&this, pdwCSR);

	public HRESULT SetMaxCSR(int32 dwCSR) mut => VT.[Friend]SetMaxCSR(&this, dwCSR);

	public HRESULT GetWaitTimeForThreadCleanup(uint32* pdwThreadCleanupWaitTime) mut => VT.[Friend]GetWaitTimeForThreadCleanup(&this, pdwThreadCleanupWaitTime);

	public HRESULT SetWaitTimeForThreadCleanup(int32 dwThreadCleanupWaitTime) mut => VT.[Friend]SetWaitTimeForThreadCleanup(&this, dwThreadCleanupWaitTime);
}

[CRepr]struct IProcessInitializer : IUnknown
{
	public new const Guid IID = .(0x1113f52d, 0xdc7f, 0x4943, 0xae, 0xd6, 0x88, 0xd0, 0x40, 0x27, 0xe3, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkProcessControl) Startup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Shutdown;
	}


	public HRESULT Startup(IUnknown* punkProcessControl) mut => VT.[Friend]Startup(&this, punkProcessControl);

	public HRESULT Shutdown() mut => VT.[Friend]Shutdown(&this);
}

[CRepr]struct IServicePoolConfig : IUnknown
{
	public new const Guid IID = .(0xa9690656, 0x5bca, 0x470c, 0x84, 0x51, 0x25, 0x0c, 0x1f, 0x43, 0xa3, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxPool) put_MaxPoolSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxPool) get_MaxPoolSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMinPool) put_MinPoolSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMinPool) get_MinPoolSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCreationTimeout) put_CreationTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCreationTimeout) get_CreationTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fTxAffinity) put_TransactionAffinity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfTxAffinity) get_TransactionAffinity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IClassFactory* pFactory) put_ClassFactory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IClassFactory** pFactory) get_ClassFactory;
	}


	public HRESULT put_MaxPoolSize(uint32 dwMaxPool) mut => VT.[Friend]put_MaxPoolSize(&this, dwMaxPool);

	public HRESULT get_MaxPoolSize(uint32* pdwMaxPool) mut => VT.[Friend]get_MaxPoolSize(&this, pdwMaxPool);

	public HRESULT put_MinPoolSize(uint32 dwMinPool) mut => VT.[Friend]put_MinPoolSize(&this, dwMinPool);

	public HRESULT get_MinPoolSize(uint32* pdwMinPool) mut => VT.[Friend]get_MinPoolSize(&this, pdwMinPool);

	public HRESULT put_CreationTimeout(uint32 dwCreationTimeout) mut => VT.[Friend]put_CreationTimeout(&this, dwCreationTimeout);

	public HRESULT get_CreationTimeout(uint32* pdwCreationTimeout) mut => VT.[Friend]get_CreationTimeout(&this, pdwCreationTimeout);

	public HRESULT put_TransactionAffinity(BOOL fTxAffinity) mut => VT.[Friend]put_TransactionAffinity(&this, fTxAffinity);

	public HRESULT get_TransactionAffinity(BOOL* pfTxAffinity) mut => VT.[Friend]get_TransactionAffinity(&this, pfTxAffinity);

	public HRESULT put_ClassFactory(IClassFactory* pFactory) mut => VT.[Friend]put_ClassFactory(&this, pFactory);

	public HRESULT get_ClassFactory(IClassFactory** pFactory) mut => VT.[Friend]get_ClassFactory(&this, pFactory);
}

[CRepr]struct IServicePool : IUnknown
{
	public new const Guid IID = .(0xb302df81, 0xea45, 0x451e, 0x99, 0xa2, 0x09, 0xf9, 0xfd, 0x1b, 0x1e, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pPoolConfig) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Shutdown;
	}


	public HRESULT Initialize(IUnknown* pPoolConfig) mut => VT.[Friend]Initialize(&this, pPoolConfig);

	public HRESULT GetObject(in Guid riid, void** ppv) mut => VT.[Friend]GetObject(&this, riid, ppv);

	public HRESULT Shutdown() mut => VT.[Friend]Shutdown(&this);
}

[CRepr]struct IManagedPooledObj : IUnknown
{
	public new const Guid IID = .(0xc5da4bea, 0x1b42, 0x4437, 0x89, 0x26, 0xb6, 0xa3, 0x88, 0x60, 0xa7, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL m_bHeld) SetHeld;
	}


	public HRESULT SetHeld(BOOL m_bHeld) mut => VT.[Friend]SetHeld(&this, m_bHeld);
}

[CRepr]struct IManagedPoolAction : IUnknown
{
	public new const Guid IID = .(0xda91b74e, 0x5388, 0x4783, 0x94, 0x9d, 0xc1, 0xcd, 0x5f, 0xb0, 0x05, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) LastRelease;
	}


	public HRESULT LastRelease() mut => VT.[Friend]LastRelease(&this);
}

[CRepr]struct IManagedObjectInfo : IUnknown
{
	public new const Guid IID = .(0x1427c51a, 0x4584, 0x49d8, 0x90, 0xa0, 0xc5, 0x0d, 0x80, 0x86, 0xcb, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pUnk) GetIUnknown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectControl** pCtrl) GetIObjectControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bInPool, IManagedPooledObj* pPooledObj) SetInPool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bStrong) SetWrapperStrength;
	}


	public HRESULT GetIUnknown(IUnknown** pUnk) mut => VT.[Friend]GetIUnknown(&this, pUnk);

	public HRESULT GetIObjectControl(IObjectControl** pCtrl) mut => VT.[Friend]GetIObjectControl(&this, pCtrl);

	public HRESULT SetInPool(BOOL bInPool, IManagedPooledObj* pPooledObj) mut => VT.[Friend]SetInPool(&this, bInPool, pPooledObj);

	public HRESULT SetWrapperStrength(BOOL bStrong) mut => VT.[Friend]SetWrapperStrength(&this, bStrong);
}

[CRepr]struct IAppDomainHelper : IDispatch
{
	public new const Guid IID = .(0xc7b67079, 0x8255, 0x42c6, 0x9e, 0xc0, 0x69, 0x94, 0xa3, 0x54, 0x87, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkAD, int __MIDL__IAppDomainHelper0000, void* pPool) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkAD, int __MIDL__IAppDomainHelper0001, void* pPool) DoCallback;
	}


	public HRESULT Initialize(IUnknown* pUnkAD, int __MIDL__IAppDomainHelper0000, void* pPool) mut => VT.[Friend]Initialize(&this, pUnkAD, __MIDL__IAppDomainHelper0000, pPool);

	public HRESULT DoCallback(IUnknown* pUnkAD, int __MIDL__IAppDomainHelper0001, void* pPool) mut => VT.[Friend]DoCallback(&this, pUnkAD, __MIDL__IAppDomainHelper0001, pPool);
}

[CRepr]struct IAssemblyLocator : IDispatch
{
	public new const Guid IID = .(0x391ffbb9, 0xa8ee, 0x432a, 0xab, 0xc8, 0xba, 0xa2, 0x38, 0xda, 0xb9, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR applicationDir, BSTR applicationName, BSTR assemblyName, SAFEARRAY** pModules) GetModules;
	}


	public HRESULT GetModules(BSTR applicationDir, BSTR applicationName, BSTR assemblyName, SAFEARRAY** pModules) mut => VT.[Friend]GetModules(&this, applicationDir, applicationName, assemblyName, pModules);
}

[CRepr]struct IManagedActivationEvents : IUnknown
{
	public new const Guid IID = .(0xa5f325af, 0x572f, 0x46da, 0xb8, 0xab, 0x82, 0x7c, 0x3d, 0x95, 0xd9, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IManagedObjectInfo* pInfo, BOOL fDist) CreateManagedStub;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IManagedObjectInfo* pInfo) DestroyManagedStub;
	}


	public HRESULT CreateManagedStub(IManagedObjectInfo* pInfo, BOOL fDist) mut => VT.[Friend]CreateManagedStub(&this, pInfo, fDist);

	public HRESULT DestroyManagedStub(IManagedObjectInfo* pInfo) mut => VT.[Friend]DestroyManagedStub(&this, pInfo);
}

[CRepr]struct ISendMethodEvents : IUnknown
{
	public new const Guid IID = .(0x2732fd59, 0xb2b4, 0x4d44, 0x87, 0x8c, 0x8b, 0x8f, 0x09, 0x62, 0x60, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pIdentity, in Guid riid, uint32 dwMeth) SendMethodCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pIdentity, in Guid riid, uint32 dwMeth, HRESULT hrCall, HRESULT hrServer) SendMethodReturn;
	}


	public HRESULT SendMethodCall(void* pIdentity, in Guid riid, uint32 dwMeth) mut => VT.[Friend]SendMethodCall(&this, pIdentity, riid, dwMeth);

	public HRESULT SendMethodReturn(void* pIdentity, in Guid riid, uint32 dwMeth, HRESULT hrCall, HRESULT hrServer) mut => VT.[Friend]SendMethodReturn(&this, pIdentity, riid, dwMeth, hrCall, hrServer);
}

[CRepr]struct ITransactionResourcePool : IUnknown
{
	public new const Guid IID = .(0xc5feb7c1, 0x346a, 0x11d1, 0xb1, 0xcc, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjPool* pPool, IUnknown* pUnk) PutResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjPool* pPool, IUnknown** ppUnk) GetResource;
	}


	public HRESULT PutResource(IObjPool* pPool, IUnknown* pUnk) mut => VT.[Friend]PutResource(&this, pPool, pUnk);

	public HRESULT GetResource(IObjPool* pPool, IUnknown** ppUnk) mut => VT.[Friend]GetResource(&this, pPool, ppUnk);
}

[CRepr]struct IMTSCall : IUnknown
{
	public new const Guid IID = .(0x51372aef, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnCall;
	}


	public HRESULT OnCall() mut => VT.[Friend]OnCall(&this);
}

[CRepr]struct IContextProperties : IUnknown
{
	public new const Guid IID = .(0xd396da85, 0xbf8f, 0x11d1, 0xbb, 0xae, 0x00, 0xc0, 0x4f, 0xc2, 0xfa, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT* pProperty) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNames** ppenum) EnumNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT property) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) RemoveProperty;
	}


	public HRESULT Count(int32* plCount) mut => VT.[Friend]Count(&this, plCount);

	public HRESULT GetProperty(BSTR name, VARIANT* pProperty) mut => VT.[Friend]GetProperty(&this, name, pProperty);

	public HRESULT EnumNames(IEnumNames** ppenum) mut => VT.[Friend]EnumNames(&this, ppenum);

	public HRESULT SetProperty(BSTR name, VARIANT property) mut => VT.[Friend]SetProperty(&this, name, property);

	public HRESULT RemoveProperty(BSTR name) mut => VT.[Friend]RemoveProperty(&this, name);
}

[CRepr]struct IObjPool : IUnknown
{
	public new const Guid IID = .(0x7d8805a0, 0x2ea7, 0x11d1, 0xb1, 0xcc, 0x00, 0xaa, 0x00, 0xba, 0x32, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved1;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved2;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved3;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved4;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IUnknown* pObj) PutEndTx;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved5;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved6;
	}


	public void Reserved1() mut => VT.[Friend]Reserved1(&this);

	public void Reserved2() mut => VT.[Friend]Reserved2(&this);

	public void Reserved3() mut => VT.[Friend]Reserved3(&this);

	public void Reserved4() mut => VT.[Friend]Reserved4(&this);

	public void PutEndTx(IUnknown* pObj) mut => VT.[Friend]PutEndTx(&this, pObj);

	public void Reserved5() mut => VT.[Friend]Reserved5(&this);

	public void Reserved6() mut => VT.[Friend]Reserved6(&this);
}

[CRepr]struct ITransactionProperty : IUnknown
{
	public new const Guid IID = .(0x788ea814, 0x87b1, 0x11d1, 0xbb, 0xa6, 0x00, 0xc0, 0x4f, 0xc2, 0xfa, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved1;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved2;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved3;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved4;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved5;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved6;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved7;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved8;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved9;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionResourcePool** ppTxPool) GetTransactionResourcePool;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved10;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved11;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved12;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved13;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved14;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved15;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved16;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved17;
	}


	public void Reserved1() mut => VT.[Friend]Reserved1(&this);

	public void Reserved2() mut => VT.[Friend]Reserved2(&this);

	public void Reserved3() mut => VT.[Friend]Reserved3(&this);

	public void Reserved4() mut => VT.[Friend]Reserved4(&this);

	public void Reserved5() mut => VT.[Friend]Reserved5(&this);

	public void Reserved6() mut => VT.[Friend]Reserved6(&this);

	public void Reserved7() mut => VT.[Friend]Reserved7(&this);

	public void Reserved8() mut => VT.[Friend]Reserved8(&this);

	public void Reserved9() mut => VT.[Friend]Reserved9(&this);

	public HRESULT GetTransactionResourcePool(ITransactionResourcePool** ppTxPool) mut => VT.[Friend]GetTransactionResourcePool(&this, ppTxPool);

	public void Reserved10() mut => VT.[Friend]Reserved10(&this);

	public void Reserved11() mut => VT.[Friend]Reserved11(&this);

	public void Reserved12() mut => VT.[Friend]Reserved12(&this);

	public void Reserved13() mut => VT.[Friend]Reserved13(&this);

	public void Reserved14() mut => VT.[Friend]Reserved14(&this);

	public void Reserved15() mut => VT.[Friend]Reserved15(&this);

	public void Reserved16() mut => VT.[Friend]Reserved16(&this);

	public void Reserved17() mut => VT.[Friend]Reserved17(&this);
}

[CRepr]struct IMTSActivity : IUnknown
{
	public new const Guid IID = .(0x51372af0, 0xcae7, 0x11cf, 0xbe, 0x81, 0x00, 0xaa, 0x00, 0xa2, 0xfa, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMTSCall* pCall) SynchronousCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMTSCall* pCall) AsyncCall;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Reserved1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BindToCurrentThread;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnbindFromThread;
	}


	public HRESULT SynchronousCall(IMTSCall* pCall) mut => VT.[Friend]SynchronousCall(&this, pCall);

	public HRESULT AsyncCall(IMTSCall* pCall) mut => VT.[Friend]AsyncCall(&this, pCall);

	public void Reserved1() mut => VT.[Friend]Reserved1(&this);

	public HRESULT BindToCurrentThread() mut => VT.[Friend]BindToCurrentThread(&this);

	public HRESULT UnbindFromThread() mut => VT.[Friend]UnbindFromThread(&this);
}

#endregion

#region Functions
public static
{
	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetDefaultContext(APTTYPE aptType, in Guid riid, void** ppv);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCreateActivity(IUnknown* pIUnknown, in Guid riid, void** ppObj);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoEnterServiceDomain(IUnknown* pConfigObject);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoLeaveServiceDomain(IUnknown* pUnkStatus);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetManagedExtensions(uint32* dwExts);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SafeRef(in Guid rid, IUnknown* pUnk);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RecycleSurrogate(int32 lReasonCode);

	[Import("comsvcs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MTSCreateActivity(in Guid riid, void** ppobj);

	[Import("MTxDM.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDispenserManager(IDispenserManager** param0);

}
#endregion
