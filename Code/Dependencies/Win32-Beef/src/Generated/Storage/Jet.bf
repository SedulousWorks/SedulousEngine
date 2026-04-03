using Win32.Storage.StructuredStorage;
using Win32.Foundation;
using System;

namespace Win32.Storage.Jet;

#region Constants
public static
{
	public const uint32 JET_VERSION = 1280;
	public const String JET_wszConfigStoreReadControl = "CsReadControl";
	public const uint32 JET_bitConfigStoreReadControlInhibitRead = 1;
	public const uint32 JET_bitConfigStoreReadControlDisableAll = 2;
	public const uint32 JET_bitConfigStoreReadControlDefault = 0;
	public const String JET_wszConfigStoreRelPathSysParamDefault = "SysParamDefault";
	public const String JET_wszConfigStoreRelPathSysParamOverride = "SysParamOverride";
	public const uint32 JET_bitDefragmentBatchStart = 1;
	public const uint32 JET_bitDefragmentBatchStop = 2;
	public const uint32 JET_bitDefragmentAvailSpaceTreesOnly = 64;
	public const uint32 JET_bitDefragmentNoPartialMerges = 128;
	public const uint32 JET_bitDefragmentBTree = 256;
	public const uint32 JET_cbtypNull = 0;
	public const uint32 JET_cbtypFinalize = 1;
	public const uint32 JET_cbtypBeforeInsert = 2;
	public const uint32 JET_cbtypAfterInsert = 4;
	public const uint32 JET_cbtypBeforeReplace = 8;
	public const uint32 JET_cbtypAfterReplace = 16;
	public const uint32 JET_cbtypBeforeDelete = 32;
	public const uint32 JET_cbtypAfterDelete = 64;
	public const uint32 JET_cbtypUserDefinedDefaultValue = 128;
	public const uint32 JET_cbtypOnlineDefragCompleted = 256;
	public const uint32 JET_cbtypFreeCursorLS = 512;
	public const uint32 JET_cbtypFreeTableLS = 1024;
	public const uint32 JET_bitTableInfoUpdatable = 1;
	public const uint32 JET_bitTableInfoBookmark = 2;
	public const uint32 JET_bitTableInfoRollback = 4;
	public const uint32 JET_bitObjectSystem = 2147483648;
	public const uint32 JET_bitObjectTableFixedDDL = 1073741824;
	public const uint32 JET_bitObjectTableTemplate = 536870912;
	public const uint32 JET_bitObjectTableDerived = 268435456;
	public const uint32 JET_bitObjectTableNoFixedVarColumnsInDerivedTables = 67108864;
	public const uint32 cObjectInfoCols = 9;
	public const uint32 cColumnInfoCols = 14;
	public const uint32 cIndexInfoCols = 15;
	public const uint32 JET_MAX_COMPUTERNAME_LENGTH = 15;
	public const uint32 JET_bitDurableCommitCallbackLogUnavailable = 1;
	public const uint32 JET_cbBookmarkMost = 256;
	public const uint32 JET_cbNameMost = 64;
	public const uint32 JET_cbFullNameMost = 255;
	public const uint32 JET_cbColumnLVPageOverhead = 82;
	public const uint32 JET_cbLVDefaultValueMost = 255;
	public const uint32 JET_cbColumnMost = 255;
	public const uint32 JET_cbLVColumnMost = 2147483647;
	public const uint32 JET_cbKeyMost8KBytePage = 2000;
	public const uint32 JET_cbKeyMost4KBytePage = 1000;
	public const uint32 JET_cbKeyMost2KBytePage = 500;
	public const uint32 JET_cbKeyMostMin = 255;
	public const uint32 JET_cbKeyMost = 255;
	public const uint32 JET_cbLimitKeyMost = 256;
	public const uint32 JET_cbPrimaryKeyMost = 255;
	public const uint32 JET_cbSecondaryKeyMost = 255;
	public const uint32 JET_ccolKeyMost = 16;
	public const uint32 JET_ccolMost = 65248;
	public const uint32 JET_ccolFixedMost = 127;
	public const uint32 JET_ccolVarMost = 128;
	public const uint32 JET_EventLoggingDisable = 0;
	public const uint32 JET_EventLoggingLevelMin = 1;
	public const uint32 JET_EventLoggingLevelLow = 25;
	public const uint32 JET_EventLoggingLevelMedium = 50;
	public const uint32 JET_EventLoggingLevelHigh = 75;
	public const uint32 JET_EventLoggingLevelMax = 100;
	public const uint32 JET_IOPriorityNormal = 0;
	public const uint32 JET_IOPriorityLow = 1;
	public const uint32 JET_configDefault = 1;
	public const uint32 JET_configRemoveQuotas = 2;
	public const uint32 JET_configLowDiskFootprint = 4;
	public const uint32 JET_configMediumDiskFootprint = 8;
	public const uint32 JET_configLowMemory = 16;
	public const uint32 JET_configDynamicMediumMemory = 32;
	public const uint32 JET_configLowPower = 64;
	public const uint32 JET_configSSDProfileIO = 128;
	public const uint32 JET_configRunSilent = 256;
	public const uint32 JET_configUnthrottledMemory = 512;
	public const uint32 JET_configHighConcurrencyScaling = 1024;
	public const uint32 JET_paramSystemPath = 0;
	public const uint32 JET_paramTempPath = 1;
	public const uint32 JET_paramLogFilePath = 2;
	public const uint32 JET_paramBaseName = 3;
	public const uint32 JET_paramEventSource = 4;
	public const uint32 JET_paramMaxSessions = 5;
	public const uint32 JET_paramMaxOpenTables = 6;
	public const uint32 JET_paramPreferredMaxOpenTables = 7;
	public const uint32 JET_paramCachedClosedTables = 125;
	public const uint32 JET_paramMaxCursors = 8;
	public const uint32 JET_paramMaxVerPages = 9;
	public const uint32 JET_paramPreferredVerPages = 63;
	public const uint32 JET_paramGlobalMinVerPages = 81;
	public const uint32 JET_paramVersionStoreTaskQueueMax = 105;
	public const uint32 JET_paramMaxTemporaryTables = 10;
	public const uint32 JET_paramLogFileSize = 11;
	public const uint32 JET_paramLogBuffers = 12;
	public const uint32 JET_paramWaitLogFlush = 13;
	public const uint32 JET_paramLogCheckpointPeriod = 14;
	public const uint32 JET_paramLogWaitingUserMax = 15;
	public const uint32 JET_paramCommitDefault = 16;
	public const uint32 JET_paramCircularLog = 17;
	public const uint32 JET_paramDbExtensionSize = 18;
	public const uint32 JET_paramPageTempDBMin = 19;
	public const uint32 JET_paramPageFragment = 20;
	public const uint32 JET_paramEnableFileCache = 126;
	public const uint32 JET_paramVerPageSize = 128;
	public const uint32 JET_paramConfiguration = 129;
	public const uint32 JET_paramEnableAdvanced = 130;
	public const uint32 JET_paramMaxColtyp = 131;
	public const uint32 JET_paramBatchIOBufferMax = 22;
	public const uint32 JET_paramCacheSize = 41;
	public const uint32 JET_paramCacheSizeMin = 60;
	public const uint32 JET_paramCacheSizeMax = 23;
	public const uint32 JET_paramCheckpointDepthMax = 24;
	public const uint32 JET_paramLRUKCorrInterval = 25;
	public const uint32 JET_paramLRUKHistoryMax = 26;
	public const uint32 JET_paramLRUKPolicy = 27;
	public const uint32 JET_paramLRUKTimeout = 28;
	public const uint32 JET_paramLRUKTrxCorrInterval = 29;
	public const uint32 JET_paramOutstandingIOMax = 30;
	public const uint32 JET_paramStartFlushThreshold = 31;
	public const uint32 JET_paramStopFlushThreshold = 32;
	public const uint32 JET_paramEnableViewCache = 127;
	public const uint32 JET_paramCheckpointIOMax = 135;
	public const uint32 JET_paramTableClass1Name = 137;
	public const uint32 JET_paramTableClass2Name = 138;
	public const uint32 JET_paramTableClass3Name = 139;
	public const uint32 JET_paramTableClass4Name = 140;
	public const uint32 JET_paramTableClass5Name = 141;
	public const uint32 JET_paramTableClass6Name = 142;
	public const uint32 JET_paramTableClass7Name = 143;
	public const uint32 JET_paramTableClass8Name = 144;
	public const uint32 JET_paramTableClass9Name = 145;
	public const uint32 JET_paramTableClass10Name = 146;
	public const uint32 JET_paramTableClass11Name = 147;
	public const uint32 JET_paramTableClass12Name = 148;
	public const uint32 JET_paramTableClass13Name = 149;
	public const uint32 JET_paramTableClass14Name = 150;
	public const uint32 JET_paramTableClass15Name = 151;
	public const uint32 JET_paramIOPriority = 152;
	public const uint32 JET_paramRecovery = 34;
	public const uint32 JET_paramEnableOnlineDefrag = 35;
	public const uint32 JET_paramCheckFormatWhenOpenFail = 44;
	public const uint32 JET_paramEnableTempTableVersioning = 46;
	public const uint32 JET_paramIgnoreLogVersion = 47;
	public const uint32 JET_paramDeleteOldLogs = 48;
	public const uint32 JET_paramEventSourceKey = 49;
	public const uint32 JET_paramNoInformationEvent = 50;
	public const uint32 JET_paramEventLoggingLevel = 51;
	public const uint32 JET_paramDeleteOutOfRangeLogs = 52;
	public const uint32 JET_paramAccessDeniedRetryPeriod = 53;
	public const uint32 JET_paramEnableIndexChecking = 45;
	public const uint32 JET_paramEnableIndexCleanup = 54;
	public const uint32 JET_paramDatabasePageSize = 64;
	public const uint32 JET_paramDisableCallbacks = 65;
	public const uint32 JET_paramLogFileCreateAsynch = 69;
	public const uint32 JET_paramErrorToString = 70;
	public const uint32 JET_paramZeroDatabaseDuringBackup = 71;
	public const uint32 JET_paramUnicodeIndexDefault = 72;
	public const uint32 JET_paramRuntimeCallback = 73;
	public const uint32 JET_paramCleanupMismatchedLogFiles = 77;
	public const uint32 JET_paramRecordUpgradeDirtyLevel = 78;
	public const uint32 JET_paramOSSnapshotTimeout = 82;
	public const uint32 JET_paramExceptionAction = 98;
	public const uint32 JET_paramEventLogCache = 99;
	public const uint32 JET_paramCreatePathIfNotExist = 100;
	public const uint32 JET_paramPageHintCacheSize = 101;
	public const uint32 JET_paramOneDatabasePerSession = 102;
	public const uint32 JET_paramMaxInstances = 104;
	public const uint32 JET_paramDisablePerfmon = 107;
	public const uint32 JET_paramIndexTuplesLengthMin = 110;
	public const uint32 JET_paramIndexTuplesLengthMax = 111;
	public const uint32 JET_paramIndexTuplesToIndexMax = 112;
	public const uint32 JET_paramAlternateDatabaseRecoveryPath = 113;
	public const uint32 JET_paramIndexTupleIncrement = 132;
	public const uint32 JET_paramIndexTupleStart = 133;
	public const uint32 JET_paramKeyMost = 134;
	public const uint32 JET_paramLegacyFileNames = 136;
	public const uint32 JET_paramEnablePersistedCallbacks = 156;
	public const uint32 JET_paramWaypointLatency = 153;
	public const uint32 JET_paramDefragmentSequentialBTrees = 160;
	public const uint32 JET_paramDefragmentSequentialBTreesDensityCheckFrequency = 161;
	public const uint32 JET_paramIOThrottlingTimeQuanta = 162;
	public const uint32 JET_paramLVChunkSizeMost = 163;
	public const uint32 JET_paramMaxCoalesceReadSize = 164;
	public const uint32 JET_paramMaxCoalesceWriteSize = 165;
	public const uint32 JET_paramMaxCoalesceReadGapSize = 166;
	public const uint32 JET_paramMaxCoalesceWriteGapSize = 167;
	public const uint32 JET_paramEnableDBScanInRecovery = 169;
	public const uint32 JET_paramDbScanThrottle = 170;
	public const uint32 JET_paramDbScanIntervalMinSec = 171;
	public const uint32 JET_paramDbScanIntervalMaxSec = 172;
	public const uint32 JET_paramCachePriority = 177;
	public const uint32 JET_paramMaxTransactionSize = 178;
	public const uint32 JET_paramPrereadIOMax = 179;
	public const uint32 JET_paramEnableDBScanSerialization = 180;
	public const uint32 JET_paramHungIOThreshold = 181;
	public const uint32 JET_paramHungIOActions = 182;
	public const uint32 JET_paramMinDataForXpress = 183;
	public const uint32 JET_paramEnableShrinkDatabase = 184;
	public const uint32 JET_paramProcessFriendlyName = 186;
	public const uint32 JET_paramDurableCommitCallback = 187;
	public const uint32 JET_paramEnableSqm = 188;
	public const uint32 JET_paramConfigStoreSpec = 189;
	public const uint32 JET_paramUseFlushForWriteDurability = 214;
	public const uint32 JET_paramEnableRBS = 215;
	public const uint32 JET_paramRBSFilePath = 216;
	public const uint32 JET_paramMaxValueInvalid = 217;
	public const uint32 JET_sesparamCommitDefault = 4097;
	public const uint32 JET_sesparamTransactionLevel = 4099;
	public const uint32 JET_sesparamOperationContext = 4100;
	public const uint32 JET_sesparamCorrelationID = 4101;
	public const uint32 JET_sesparamMaxValueInvalid = 4110;
	public const uint32 JET_bitESE98FileNames = 1;
	public const uint32 JET_bitEightDotThreeSoftCompat = 2;
	public const uint32 JET_bitHungIOEvent = 1;
	public const uint32 JET_bitShrinkDatabaseOff = 0;
	public const uint32 JET_bitShrinkDatabaseOn = 1;
	public const uint32 JET_bitShrinkDatabaseRealtime = 2;
	public const uint32 JET_bitShrinkDatabaseTrim = 1;
	public const uint32 JET_bitReplayIgnoreMissingDB = 4;
	public const uint32 JET_bitRecoveryWithoutUndo = 8;
	public const uint32 JET_bitTruncateLogsAfterRecovery = 16;
	public const uint32 JET_bitReplayMissingMapEntryDB = 32;
	public const uint32 JET_bitLogStreamMustExist = 64;
	public const uint32 JET_bitReplayIgnoreLostLogs = 128;
	public const uint32 JET_bitKeepDbAttachedAtEndOfRecovery = 4096;
	public const uint32 JET_bitTermComplete = 1;
	public const uint32 JET_bitTermAbrupt = 2;
	public const uint32 JET_bitTermStopBackup = 4;
	public const uint32 JET_bitTermDirty = 8;
	public const uint32 JET_bitIdleFlushBuffers = 1;
	public const uint32 JET_bitIdleCompact = 2;
	public const uint32 JET_bitIdleStatus = 4;
	public const uint32 JET_bitDbReadOnly = 1;
	public const uint32 JET_bitDbExclusive = 2;
	public const uint32 JET_bitDbDeleteCorruptIndexes = 16;
	public const uint32 JET_bitDbDeleteUnicodeIndexes = 1024;
	public const uint32 JET_bitDbUpgrade = 512;
	public const uint32 JET_bitDbEnableBackgroundMaintenance = 2048;
	public const uint32 JET_bitDbPurgeCacheOnAttach = 4096;
	public const uint32 JET_bitForceDetach = 1;
	public const uint32 JET_bitDbRecoveryOff = 8;
	public const uint32 JET_bitDbShadowingOff = 128;
	public const uint32 JET_bitDbOverwriteExisting = 512;
	public const uint32 JET_bitBackupIncremental = 1;
	public const uint32 JET_bitBackupAtomic = 4;
	public const uint32 JET_bitBackupSnapshot = 16;
	public const uint32 JET_bitBackupEndNormal = 1;
	public const uint32 JET_bitBackupEndAbort = 2;
	public const uint32 JET_bitBackupTruncateDone = 256;
	public const uint32 JET_bitTableCreateFixedDDL = 1;
	public const uint32 JET_bitTableCreateTemplateTable = 2;
	public const uint32 JET_bitTableCreateNoFixedVarColumnsInDerivedTables = 4;
	public const uint32 JET_bitTableCreateImmutableStructure = 8;
	public const uint32 JET_bitColumnFixed = 1;
	public const uint32 JET_bitColumnTagged = 2;
	public const uint32 JET_bitColumnNotNULL = 4;
	public const uint32 JET_bitColumnVersion = 8;
	public const uint32 JET_bitColumnAutoincrement = 16;
	public const uint32 JET_bitColumnUpdatable = 32;
	public const uint32 JET_bitColumnTTKey = 64;
	public const uint32 JET_bitColumnTTDescending = 128;
	public const uint32 JET_bitColumnMultiValued = 1024;
	public const uint32 JET_bitColumnEscrowUpdate = 2048;
	public const uint32 JET_bitColumnUnversioned = 4096;
	public const uint32 JET_bitColumnMaybeNull = 8192;
	public const uint32 JET_bitColumnFinalize = 16384;
	public const uint32 JET_bitColumnUserDefinedDefault = 32768;
	public const uint32 JET_bitColumnDeleteOnZero = 131072;
	public const uint32 JET_bitColumnCompressed = 524288;
	public const uint32 JET_bitDeleteColumnIgnoreTemplateColumns = 1;
	public const uint32 JET_bitMoveFirst = 0;
	public const uint32 JET_bitNoMove = 2;
	public const uint32 JET_bitNewKey = 1;
	public const uint32 JET_bitStrLimit = 2;
	public const uint32 JET_bitSubStrLimit = 4;
	public const uint32 JET_bitNormalizedKey = 8;
	public const uint32 JET_bitKeyDataZeroLength = 16;
	public const uint32 JET_bitFullColumnStartLimit = 256;
	public const uint32 JET_bitFullColumnEndLimit = 512;
	public const uint32 JET_bitPartialColumnStartLimit = 1024;
	public const uint32 JET_bitPartialColumnEndLimit = 2048;
	public const uint32 JET_bitRangeInclusive = 1;
	public const uint32 JET_bitRangeUpperLimit = 2;
	public const uint32 JET_bitRangeInstantDuration = 4;
	public const uint32 JET_bitRangeRemove = 8;
	public const uint32 JET_bitReadLock = 1;
	public const uint32 JET_bitWriteLock = 2;
	public const uint32 JET_MoveFirst = 2147483648;
	public const int32 JET_MovePrevious = -1;
	public const uint32 JET_MoveLast = 2147483647;
	public const uint32 JET_bitMoveKeyNE = 1;
	public const uint32 JET_bitSeekEQ = 1;
	public const uint32 JET_bitSeekLT = 2;
	public const uint32 JET_bitSeekLE = 4;
	public const uint32 JET_bitSeekGE = 8;
	public const uint32 JET_bitSeekGT = 16;
	public const uint32 JET_bitSetIndexRange = 32;
	public const uint32 JET_bitCheckUniqueness = 64;
	public const uint32 JET_bitBookmarkPermitVirtualCurrency = 1;
	public const uint32 JET_bitIndexColumnMustBeNull = 1;
	public const uint32 JET_bitIndexColumnMustBeNonNull = 2;
	public const uint32 JET_bitRecordInIndex = 1;
	public const uint32 JET_bitRecordNotInIndex = 2;
	public const uint32 JET_bitIndexUnique = 1;
	public const uint32 JET_bitIndexPrimary = 2;
	public const uint32 JET_bitIndexDisallowNull = 4;
	public const uint32 JET_bitIndexIgnoreNull = 8;
	public const uint32 JET_bitIndexIgnoreAnyNull = 32;
	public const uint32 JET_bitIndexIgnoreFirstNull = 64;
	public const uint32 JET_bitIndexLazyFlush = 128;
	public const uint32 JET_bitIndexEmpty = 256;
	public const uint32 JET_bitIndexUnversioned = 512;
	public const uint32 JET_bitIndexSortNullsHigh = 1024;
	public const uint32 JET_bitIndexUnicode = 2048;
	public const uint32 JET_bitIndexTuples = 4096;
	public const uint32 JET_bitIndexTupleLimits = 8192;
	public const uint32 JET_bitIndexCrossProduct = 16384;
	public const uint32 JET_bitIndexKeyMost = 32768;
	public const uint32 JET_bitIndexDisallowTruncation = 65536;
	public const uint32 JET_bitIndexNestedTable = 131072;
	public const uint32 JET_bitIndexDotNetGuid = 262144;
	public const uint32 JET_bitIndexImmutableStructure = 524288;
	public const uint32 JET_bitKeyAscending = 0;
	public const uint32 JET_bitKeyDescending = 1;
	public const uint32 JET_bitTableDenyWrite = 1;
	public const uint32 JET_bitTableDenyRead = 2;
	public const uint32 JET_bitTableReadOnly = 4;
	public const uint32 JET_bitTableUpdatable = 8;
	public const uint32 JET_bitTablePermitDDL = 16;
	public const uint32 JET_bitTableNoCache = 32;
	public const uint32 JET_bitTablePreread = 64;
	public const uint32 JET_bitTableOpportuneRead = 128;
	public const uint32 JET_bitTableSequential = 32768;
	public const uint32 JET_bitTableClassMask = 2031616;
	public const uint32 JET_bitTableClassNone = 0;
	public const uint32 JET_bitTableClass1 = 65536;
	public const uint32 JET_bitTableClass2 = 131072;
	public const uint32 JET_bitTableClass3 = 196608;
	public const uint32 JET_bitTableClass4 = 262144;
	public const uint32 JET_bitTableClass5 = 327680;
	public const uint32 JET_bitTableClass6 = 393216;
	public const uint32 JET_bitTableClass7 = 458752;
	public const uint32 JET_bitTableClass8 = 524288;
	public const uint32 JET_bitTableClass9 = 589824;
	public const uint32 JET_bitTableClass10 = 655360;
	public const uint32 JET_bitTableClass11 = 720896;
	public const uint32 JET_bitTableClass12 = 786432;
	public const uint32 JET_bitTableClass13 = 851968;
	public const uint32 JET_bitTableClass14 = 917504;
	public const uint32 JET_bitTableClass15 = 983040;
	public const uint32 JET_bitLSReset = 1;
	public const uint32 JET_bitLSCursor = 2;
	public const uint32 JET_bitLSTable = 4;
	public const uint32 JET_bitPrereadForward = 1;
	public const uint32 JET_bitPrereadBackward = 2;
	public const uint32 JET_bitPrereadFirstPage = 4;
	public const uint32 JET_bitPrereadNormalizedKey = 8;
	public const uint32 JET_bitTTIndexed = 1;
	public const uint32 JET_bitTTUnique = 2;
	public const uint32 JET_bitTTUpdatable = 4;
	public const uint32 JET_bitTTScrollable = 8;
	public const uint32 JET_bitTTSortNullsHigh = 16;
	public const uint32 JET_bitTTForceMaterialization = 32;
	public const uint32 JET_bitTTErrorOnDuplicateInsertion = 32;
	public const uint32 JET_bitTTForwardOnly = 64;
	public const uint32 JET_bitTTIntrinsicLVsOnly = 128;
	public const uint32 JET_bitTTDotNetGuid = 256;
	public const uint32 JET_bitSetAppendLV = 1;
	public const uint32 JET_bitSetOverwriteLV = 4;
	public const uint32 JET_bitSetSizeLV = 8;
	public const uint32 JET_bitSetZeroLength = 32;
	public const uint32 JET_bitSetSeparateLV = 64;
	public const uint32 JET_bitSetUniqueMultiValues = 128;
	public const uint32 JET_bitSetUniqueNormalizedMultiValues = 256;
	public const uint32 JET_bitSetRevertToDefaultValue = 512;
	public const uint32 JET_bitSetIntrinsicLV = 1024;
	public const uint32 JET_bitSetUncompressed = 65536;
	public const uint32 JET_bitSetCompressed = 131072;
	public const uint32 JET_bitSetContiguousLV = 262144;
	public const uint32 JET_bitSpaceHintsUtilizeParentSpace = 1;
	public const uint32 JET_bitCreateHintAppendSequential = 2;
	public const uint32 JET_bitCreateHintHotpointSequential = 4;
	public const uint32 JET_bitRetrieveHintReserve1 = 8;
	public const uint32 JET_bitRetrieveHintTableScanForward = 16;
	public const uint32 JET_bitRetrieveHintTableScanBackward = 32;
	public const uint32 JET_bitRetrieveHintReserve2 = 64;
	public const uint32 JET_bitRetrieveHintReserve3 = 128;
	public const uint32 JET_bitDeleteHintTableSequential = 256;
	public const uint32 JET_prepInsert = 0;
	public const uint32 JET_prepReplace = 2;
	public const uint32 JET_prepCancel = 3;
	public const uint32 JET_prepReplaceNoLock = 4;
	public const uint32 JET_prepInsertCopy = 5;
	public const uint32 JET_prepInsertCopyDeleteOriginal = 7;
	public const uint32 JET_prepInsertCopyReplaceOriginal = 9;
	public const uint32 JET_sqmDisable = 0;
	public const uint32 JET_sqmEnable = 1;
	public const uint32 JET_sqmFromCEIP = 2;
	public const uint32 JET_bitUpdateCheckESE97Compatibility = 1;
	public const uint32 JET_bitEscrowNoRollback = 1;
	public const uint32 JET_bitRetrieveCopy = 1;
	public const uint32 JET_bitRetrieveFromIndex = 2;
	public const uint32 JET_bitRetrieveFromPrimaryBookmark = 4;
	public const uint32 JET_bitRetrieveTag = 8;
	public const uint32 JET_bitRetrieveNull = 16;
	public const uint32 JET_bitRetrieveIgnoreDefault = 32;
	public const uint32 JET_bitRetrieveTuple = 2048;
	public const uint32 JET_bitZeroLength = 1;
	public const uint32 JET_bitEnumerateCopy = 1;
	public const uint32 JET_bitEnumerateIgnoreDefault = 32;
	public const uint32 JET_bitEnumeratePresenceOnly = 131072;
	public const uint32 JET_bitEnumerateTaggedOnly = 262144;
	public const uint32 JET_bitEnumerateCompressOutput = 524288;
	public const uint32 JET_bitEnumerateIgnoreUserDefinedDefault = 1048576;
	public const uint32 JET_bitEnumerateInRecordOnly = 2097152;
	public const uint32 JET_bitRecordSizeInCopyBuffer = 1;
	public const uint32 JET_bitRecordSizeRunningTotal = 2;
	public const uint32 JET_bitRecordSizeLocal = 4;
	public const uint32 JET_bitTransactionReadOnly = 1;
	public const uint32 JET_bitCommitLazyFlush = 1;
	public const uint32 JET_bitWaitLastLevel0Commit = 2;
	public const uint32 JET_bitWaitAllLevel0Commit = 8;
	public const uint32 JET_bitForceNewLog = 16;
	public const uint32 JET_bitRollbackAll = 1;
	public const uint32 JET_bitIncrementalSnapshot = 1;
	public const uint32 JET_bitCopySnapshot = 2;
	public const uint32 JET_bitContinueAfterThaw = 4;
	public const uint32 JET_bitExplicitPrepare = 8;
	public const uint32 JET_bitAllDatabasesSnapshot = 1;
	public const uint32 JET_bitAbortSnapshot = 1;
	public const uint32 JET_DbInfoFilename = 0;
	public const uint32 JET_DbInfoConnect = 1;
	public const uint32 JET_DbInfoCountry = 2;
	public const uint32 JET_DbInfoLCID = 3;
	public const uint32 JET_DbInfoLangid = 3;
	public const uint32 JET_DbInfoCp = 4;
	public const uint32 JET_DbInfoCollate = 5;
	public const uint32 JET_DbInfoOptions = 6;
	public const uint32 JET_DbInfoTransactions = 7;
	public const uint32 JET_DbInfoVersion = 8;
	public const uint32 JET_DbInfoIsam = 9;
	public const uint32 JET_DbInfoFilesize = 10;
	public const uint32 JET_DbInfoSpaceOwned = 11;
	public const uint32 JET_DbInfoSpaceAvailable = 12;
	public const uint32 JET_DbInfoUpgrade = 13;
	public const uint32 JET_DbInfoMisc = 14;
	public const uint32 JET_DbInfoDBInUse = 15;
	public const uint32 JET_DbInfoPageSize = 17;
	public const uint32 JET_DbInfoFileType = 19;
	public const uint32 JET_DbInfoFilesizeOnDisk = 21;
	public const uint32 JET_dbstateJustCreated = 1;
	public const uint32 JET_dbstateDirtyShutdown = 2;
	public const uint32 JET_dbstateCleanShutdown = 3;
	public const uint32 JET_dbstateBeingConverted = 4;
	public const uint32 JET_dbstateForceDetach = 5;
	public const uint32 JET_filetypeUnknown = 0;
	public const uint32 JET_filetypeDatabase = 1;
	public const uint32 JET_filetypeLog = 3;
	public const uint32 JET_filetypeCheckpoint = 4;
	public const uint32 JET_filetypeTempDatabase = 5;
	public const uint32 JET_filetypeFlushMap = 7;
	public const uint32 JET_revertstateNone = 0;
	public const uint32 JET_revertstateInProgress = 1;
	public const uint32 JET_revertstateCopingLogs = 2;
	public const uint32 JET_revertstateCompleted = 3;
	public const uint32 JET_bitDeleteAllExistingLogs = 1;
	public const uint32 JET_coltypNil = 0;
	public const uint32 JET_coltypBit = 1;
	public const uint32 JET_coltypUnsignedByte = 2;
	public const uint32 JET_coltypShort = 3;
	public const uint32 JET_coltypLong = 4;
	public const uint32 JET_coltypCurrency = 5;
	public const uint32 JET_coltypIEEESingle = 6;
	public const uint32 JET_coltypIEEEDouble = 7;
	public const uint32 JET_coltypDateTime = 8;
	public const uint32 JET_coltypBinary = 9;
	public const uint32 JET_coltypText = 10;
	public const uint32 JET_coltypLongBinary = 11;
	public const uint32 JET_coltypLongText = 12;
	public const uint32 JET_coltypMax = 13;
	public const uint32 JET_coltypSLV = 13;
	public const uint32 JET_coltypUnsignedLong = 14;
	public const uint32 JET_coltypLongLong = 15;
	public const uint32 JET_coltypGUID = 16;
	public const uint32 JET_coltypUnsignedShort = 17;
	public const uint32 JET_coltypUnsignedLongLong = 18;
	public const uint32 JET_ColInfoGrbitNonDerivedColumnsOnly = 2147483648;
	public const uint32 JET_ColInfoGrbitMinimalInfo = 1073741824;
	public const uint32 JET_ColInfoGrbitSortByColumnid = 536870912;
	public const uint32 JET_objtypNil = 0;
	public const uint32 JET_objtypTable = 1;
	public const uint32 JET_bitCompactStats = 32;
	public const uint32 JET_bitCompactRepair = 64;
	public const uint32 JET_snpRepair = 2;
	public const uint32 JET_snpCompact = 4;
	public const uint32 JET_snpRestore = 8;
	public const uint32 JET_snpBackup = 9;
	public const uint32 JET_snpUpgrade = 10;
	public const uint32 JET_snpScrub = 11;
	public const uint32 JET_snpUpgradeRecordFormat = 12;
	public const uint32 JET_sntBegin = 5;
	public const uint32 JET_sntRequirements = 7;
	public const uint32 JET_sntProgress = 0;
	public const uint32 JET_sntComplete = 6;
	public const uint32 JET_sntFail = 3;
	public const uint32 JET_ExceptionMsgBox = 1;
	public const uint32 JET_ExceptionNone = 2;
	public const uint32 JET_ExceptionFailFast = 4;
	public const uint32 JET_OnlineDefragDisable = 0;
	public const uint32 JET_OnlineDefragAllOBSOLETE = 1;
	public const uint32 JET_OnlineDefragDatabases = 2;
	public const uint32 JET_OnlineDefragSpaceTrees = 4;
	public const uint32 JET_OnlineDefragAll = 65535;
	public const uint32 JET_bitResizeDatabaseOnlyGrow = 1;
	public const uint32 JET_bitResizeDatabaseOnlyShrink = 2;
	public const uint32 JET_bitStopServiceAll = 0;
	public const uint32 JET_bitStopServiceBackgroundUserTasks = 2;
	public const uint32 JET_bitStopServiceQuiesceCaches = 4;
	public const uint32 JET_bitStopServiceResume = 2147483648;
	public const uint32 JET_errSuccess = 0;
	public const int32 JET_wrnNyi = -1;
	public const int32 JET_errRfsFailure = -100;
	public const int32 JET_errRfsNotArmed = -101;
	public const int32 JET_errFileClose = -102;
	public const int32 JET_errOutOfThreads = -103;
	public const int32 JET_errTooManyIO = -105;
	public const int32 JET_errTaskDropped = -106;
	public const int32 JET_errInternalError = -107;
	public const int32 JET_errDisabledFunctionality = -112;
	public const int32 JET_errUnloadableOSFunctionality = -113;
	public const int32 JET_errDatabaseBufferDependenciesCorrupted = -255;
	public const uint32 JET_wrnRemainingVersions = 321;
	public const int32 JET_errPreviousVersion = -322;
	public const int32 JET_errPageBoundary = -323;
	public const int32 JET_errKeyBoundary = -324;
	public const int32 JET_errBadPageLink = -327;
	public const int32 JET_errBadBookmark = -328;
	public const int32 JET_errNTSystemCallFailed = -334;
	public const int32 JET_errBadParentPageLink = -338;
	public const int32 JET_errSPAvailExtCacheOutOfSync = -340;
	public const int32 JET_errSPAvailExtCorrupted = -341;
	public const int32 JET_errSPAvailExtCacheOutOfMemory = -342;
	public const int32 JET_errSPOwnExtCorrupted = -343;
	public const int32 JET_errDbTimeCorrupted = -344;
	public const uint32 JET_wrnUniqueKey = 345;
	public const int32 JET_errKeyTruncated = -346;
	public const int32 JET_errDatabaseLeakInSpace = -348;
	public const int32 JET_errBadEmptyPage = -351;
	public const uint32 wrnBTNotVisibleRejected = 352;
	public const uint32 wrnBTNotVisibleAccumulated = 353;
	public const int32 JET_errBadLineCount = -354;
	public const int32 JET_errPageTagCorrupted = -357;
	public const int32 JET_errNodeCorrupted = -358;
	public const uint32 JET_wrnSeparateLongValue = 406;
	public const int32 JET_errKeyTooBig = -408;
	public const int32 JET_errCannotSeparateIntrinsicLV = -416;
	public const int32 JET_errSeparatedLongValue = -421;
	public const int32 JET_errMustBeSeparateLongValue = -423;
	public const int32 JET_errInvalidPreread = -424;
	public const int32 JET_errInvalidLoggedOperation = -500;
	public const int32 JET_errLogFileCorrupt = -501;
	public const int32 JET_errNoBackupDirectory = -503;
	public const int32 JET_errBackupDirectoryNotEmpty = -504;
	public const int32 JET_errBackupInProgress = -505;
	public const int32 JET_errRestoreInProgress = -506;
	public const int32 JET_errMissingPreviousLogFile = -509;
	public const int32 JET_errLogWriteFail = -510;
	public const int32 JET_errLogDisabledDueToRecoveryFailure = -511;
	public const int32 JET_errCannotLogDuringRecoveryRedo = -512;
	public const int32 JET_errLogGenerationMismatch = -513;
	public const int32 JET_errBadLogVersion = -514;
	public const int32 JET_errInvalidLogSequence = -515;
	public const int32 JET_errLoggingDisabled = -516;
	public const int32 JET_errLogBufferTooSmall = -517;
	public const int32 JET_errLogSequenceEnd = -519;
	public const int32 JET_errNoBackup = -520;
	public const int32 JET_errInvalidBackupSequence = -521;
	public const int32 JET_errBackupNotAllowedYet = -523;
	public const int32 JET_errDeleteBackupFileFail = -524;
	public const int32 JET_errMakeBackupDirectoryFail = -525;
	public const int32 JET_errInvalidBackup = -526;
	public const int32 JET_errRecoveredWithErrors = -527;
	public const int32 JET_errMissingLogFile = -528;
	public const int32 JET_errLogDiskFull = -529;
	public const int32 JET_errBadLogSignature = -530;
	public const int32 JET_errBadDbSignature = -531;
	public const int32 JET_errBadCheckpointSignature = -532;
	public const int32 JET_errCheckpointCorrupt = -533;
	public const int32 JET_errMissingPatchPage = -534;
	public const int32 JET_errBadPatchPage = -535;
	public const int32 JET_errRedoAbruptEnded = -536;
	public const int32 JET_errPatchFileMissing = -538;
	public const int32 JET_errDatabaseLogSetMismatch = -539;
	public const int32 JET_errDatabaseStreamingFileMismatch = -540;
	public const int32 JET_errLogFileSizeMismatch = -541;
	public const int32 JET_errCheckpointFileNotFound = -542;
	public const int32 JET_errRequiredLogFilesMissing = -543;
	public const int32 JET_errSoftRecoveryOnBackupDatabase = -544;
	public const int32 JET_errLogFileSizeMismatchDatabasesConsistent = -545;
	public const int32 JET_errLogSectorSizeMismatch = -546;
	public const int32 JET_errLogSectorSizeMismatchDatabasesConsistent = -547;
	public const int32 JET_errLogSequenceEndDatabasesConsistent = -548;
	public const int32 JET_errStreamingDataNotLogged = -549;
	public const int32 JET_errDatabaseDirtyShutdown = -550;
	public const int32 JET_errDatabaseInconsistent = -550;
	public const int32 JET_errConsistentTimeMismatch = -551;
	public const int32 JET_errDatabasePatchFileMismatch = -552;
	public const int32 JET_errEndingRestoreLogTooLow = -553;
	public const int32 JET_errStartingRestoreLogTooHigh = -554;
	public const int32 JET_errGivenLogFileHasBadSignature = -555;
	public const int32 JET_errGivenLogFileIsNotContiguous = -556;
	public const int32 JET_errMissingRestoreLogFiles = -557;
	public const uint32 JET_wrnExistingLogFileHasBadSignature = 558;
	public const uint32 JET_wrnExistingLogFileIsNotContiguous = 559;
	public const int32 JET_errMissingFullBackup = -560;
	public const int32 JET_errBadBackupDatabaseSize = -561;
	public const int32 JET_errDatabaseAlreadyUpgraded = -562;
	public const int32 JET_errDatabaseIncompleteUpgrade = -563;
	public const uint32 JET_wrnSkipThisRecord = 564;
	public const int32 JET_errMissingCurrentLogFiles = -565;
	public const int32 JET_errDbTimeTooOld = -566;
	public const int32 JET_errDbTimeTooNew = -567;
	public const int32 JET_errMissingFileToBackup = -569;
	public const int32 JET_errLogTornWriteDuringHardRestore = -570;
	public const int32 JET_errLogTornWriteDuringHardRecovery = -571;
	public const int32 JET_errLogCorruptDuringHardRestore = -573;
	public const int32 JET_errLogCorruptDuringHardRecovery = -574;
	public const int32 JET_errMustDisableLoggingForDbUpgrade = -575;
	public const int32 JET_errBadRestoreTargetInstance = -577;
	public const uint32 JET_wrnTargetInstanceRunning = 578;
	public const int32 JET_errRecoveredWithoutUndo = -579;
	public const int32 JET_errDatabasesNotFromSameSnapshot = -580;
	public const int32 JET_errSoftRecoveryOnSnapshot = -581;
	public const int32 JET_errCommittedLogFilesMissing = -582;
	public const int32 JET_errSectorSizeNotSupported = -583;
	public const int32 JET_errRecoveredWithoutUndoDatabasesConsistent = -584;
	public const uint32 JET_wrnCommittedLogFilesLost = 585;
	public const int32 JET_errCommittedLogFileCorrupt = -586;
	public const uint32 JET_wrnCommittedLogFilesRemoved = 587;
	public const uint32 JET_wrnFinishWithUndo = 588;
	public const int32 JET_errLogSequenceChecksumMismatch = -590;
	public const uint32 JET_wrnDatabaseRepaired = 595;
	public const int32 JET_errPageInitializedMismatch = -596;
	public const int32 JET_errUnicodeTranslationBufferTooSmall = -601;
	public const int32 JET_errUnicodeTranslationFail = -602;
	public const int32 JET_errUnicodeNormalizationNotSupported = -603;
	public const int32 JET_errUnicodeLanguageValidationFailure = -604;
	public const int32 JET_errExistingLogFileHasBadSignature = -610;
	public const int32 JET_errExistingLogFileIsNotContiguous = -611;
	public const int32 JET_errLogReadVerifyFailure = -612;
	public const int32 JET_errCheckpointDepthTooDeep = -614;
	public const int32 JET_errRestoreOfNonBackupDatabase = -615;
	public const int32 JET_errLogFileNotCopied = -616;
	public const int32 JET_errTransactionTooLong = -618;
	public const int32 JET_errEngineFormatVersionNoLongerSupportedTooLow = -619;
	public const int32 JET_errEngineFormatVersionNotYetImplementedTooHigh = -620;
	public const int32 JET_errEngineFormatVersionParamTooLowForRequestedFeature = -621;
	public const int32 JET_errEngineFormatVersionSpecifiedTooLowForLogVersion = -622;
	public const int32 JET_errEngineFormatVersionSpecifiedTooLowForDatabaseVersion = -623;
	public const int32 JET_errBackupAbortByServer = -801;
	public const int32 JET_errInvalidGrbit = -900;
	public const int32 JET_errTermInProgress = -1000;
	public const int32 JET_errFeatureNotAvailable = -1001;
	public const int32 JET_errInvalidName = -1002;
	public const int32 JET_errInvalidParameter = -1003;
	public const uint32 JET_wrnColumnNull = 1004;
	public const uint32 JET_wrnBufferTruncated = 1006;
	public const uint32 JET_wrnDatabaseAttached = 1007;
	public const int32 JET_errDatabaseFileReadOnly = -1008;
	public const uint32 JET_wrnSortOverflow = 1009;
	public const int32 JET_errInvalidDatabaseId = -1010;
	public const int32 JET_errOutOfMemory = -1011;
	public const int32 JET_errOutOfDatabaseSpace = -1012;
	public const int32 JET_errOutOfCursors = -1013;
	public const int32 JET_errOutOfBuffers = -1014;
	public const int32 JET_errTooManyIndexes = -1015;
	public const int32 JET_errTooManyKeys = -1016;
	public const int32 JET_errRecordDeleted = -1017;
	public const int32 JET_errReadVerifyFailure = -1018;
	public const int32 JET_errPageNotInitialized = -1019;
	public const int32 JET_errOutOfFileHandles = -1020;
	public const int32 JET_errDiskReadVerificationFailure = -1021;
	public const int32 JET_errDiskIO = -1022;
	public const int32 JET_errInvalidPath = -1023;
	public const int32 JET_errInvalidSystemPath = -1024;
	public const int32 JET_errInvalidLogDirectory = -1025;
	public const int32 JET_errRecordTooBig = -1026;
	public const int32 JET_errTooManyOpenDatabases = -1027;
	public const int32 JET_errInvalidDatabase = -1028;
	public const int32 JET_errNotInitialized = -1029;
	public const int32 JET_errAlreadyInitialized = -1030;
	public const int32 JET_errInitInProgress = -1031;
	public const int32 JET_errFileAccessDenied = -1032;
	public const int32 JET_errBufferTooSmall = -1038;
	public const uint32 JET_wrnSeekNotEqual = 1039;
	public const int32 JET_errTooManyColumns = -1040;
	public const int32 JET_errContainerNotEmpty = -1043;
	public const int32 JET_errInvalidFilename = -1044;
	public const int32 JET_errInvalidBookmark = -1045;
	public const int32 JET_errColumnInUse = -1046;
	public const int32 JET_errInvalidBufferSize = -1047;
	public const int32 JET_errColumnNotUpdatable = -1048;
	public const int32 JET_errIndexInUse = -1051;
	public const int32 JET_errLinkNotSupported = -1052;
	public const int32 JET_errNullKeyDisallowed = -1053;
	public const int32 JET_errNotInTransaction = -1054;
	public const uint32 JET_wrnNoErrorInfo = 1055;
	public const int32 JET_errMustRollback = -1057;
	public const uint32 JET_wrnNoIdleActivity = 1058;
	public const int32 JET_errTooManyActiveUsers = -1059;
	public const int32 JET_errInvalidCountry = -1061;
	public const int32 JET_errInvalidLanguageId = -1062;
	public const int32 JET_errInvalidCodePage = -1063;
	public const int32 JET_errInvalidLCMapStringFlags = -1064;
	public const int32 JET_errVersionStoreEntryTooBig = -1065;
	public const int32 JET_errVersionStoreOutOfMemoryAndCleanupTimedOut = -1066;
	public const uint32 JET_wrnNoWriteLock = 1067;
	public const uint32 JET_wrnColumnSetNull = 1068;
	public const int32 JET_errVersionStoreOutOfMemory = -1069;
	public const int32 JET_errCannotIndex = -1071;
	public const int32 JET_errRecordNotDeleted = -1072;
	public const int32 JET_errTooManyMempoolEntries = -1073;
	public const int32 JET_errOutOfObjectIDs = -1074;
	public const int32 JET_errOutOfLongValueIDs = -1075;
	public const int32 JET_errOutOfAutoincrementValues = -1076;
	public const int32 JET_errOutOfDbtimeValues = -1077;
	public const int32 JET_errOutOfSequentialIndexValues = -1078;
	public const int32 JET_errRunningInOneInstanceMode = -1080;
	public const int32 JET_errRunningInMultiInstanceMode = -1081;
	public const int32 JET_errSystemParamsAlreadySet = -1082;
	public const int32 JET_errSystemPathInUse = -1083;
	public const int32 JET_errLogFilePathInUse = -1084;
	public const int32 JET_errTempPathInUse = -1085;
	public const int32 JET_errInstanceNameInUse = -1086;
	public const int32 JET_errSystemParameterConflict = -1087;
	public const int32 JET_errInstanceUnavailable = -1090;
	public const int32 JET_errDatabaseUnavailable = -1091;
	public const int32 JET_errInstanceUnavailableDueToFatalLogDiskFull = -1092;
	public const int32 JET_errInvalidSesparamId = -1093;
	public const int32 JET_errTooManyRecords = -1094;
	public const int32 JET_errInvalidDbparamId = -1095;
	public const int32 JET_errOutOfSessions = -1101;
	public const int32 JET_errWriteConflict = -1102;
	public const int32 JET_errTransTooDeep = -1103;
	public const int32 JET_errInvalidSesid = -1104;
	public const int32 JET_errWriteConflictPrimaryIndex = -1105;
	public const int32 JET_errInTransaction = -1108;
	public const int32 JET_errRollbackRequired = -1109;
	public const int32 JET_errTransReadOnly = -1110;
	public const int32 JET_errSessionWriteConflict = -1111;
	public const int32 JET_errRecordTooBigForBackwardCompatibility = -1112;
	public const int32 JET_errCannotMaterializeForwardOnlySort = -1113;
	public const int32 JET_errSesidTableIdMismatch = -1114;
	public const int32 JET_errInvalidInstance = -1115;
	public const int32 JET_errDirtyShutdown = -1116;
	public const int32 JET_errReadPgnoVerifyFailure = -1118;
	public const int32 JET_errReadLostFlushVerifyFailure = -1119;
	public const int32 JET_errFileSystemCorruption = -1121;
	public const uint32 JET_wrnShrinkNotPossible = 1122;
	public const int32 JET_errRecoveryVerifyFailure = -1123;
	public const int32 JET_errFilteredMoveNotSupported = -1124;
	public const int32 JET_errDatabaseDuplicate = -1201;
	public const int32 JET_errDatabaseInUse = -1202;
	public const int32 JET_errDatabaseNotFound = -1203;
	public const int32 JET_errDatabaseInvalidName = -1204;
	public const int32 JET_errDatabaseInvalidPages = -1205;
	public const int32 JET_errDatabaseCorrupted = -1206;
	public const int32 JET_errDatabaseLocked = -1207;
	public const int32 JET_errCannotDisableVersioning = -1208;
	public const int32 JET_errInvalidDatabaseVersion = -1209;
	public const int32 JET_errDatabase200Format = -1210;
	public const int32 JET_errDatabase400Format = -1211;
	public const int32 JET_errDatabase500Format = -1212;
	public const int32 JET_errPageSizeMismatch = -1213;
	public const int32 JET_errTooManyInstances = -1214;
	public const int32 JET_errDatabaseSharingViolation = -1215;
	public const int32 JET_errAttachedDatabaseMismatch = -1216;
	public const int32 JET_errDatabaseInvalidPath = -1217;
	public const int32 JET_errDatabaseIdInUse = -1218;
	public const int32 JET_errForceDetachNotAllowed = -1219;
	public const int32 JET_errCatalogCorrupted = -1220;
	public const int32 JET_errPartiallyAttachedDB = -1221;
	public const int32 JET_errDatabaseSignInUse = -1222;
	public const int32 JET_errDatabaseCorruptedNoRepair = -1224;
	public const int32 JET_errInvalidCreateDbVersion = -1225;
	public const int32 JET_errDatabaseNotReady = -1230;
	public const int32 JET_errDatabaseAttachedForRecovery = -1231;
	public const int32 JET_errTransactionsNotReadyDuringRecovery = -1232;
	public const uint32 JET_wrnTableEmpty = 1301;
	public const int32 JET_errTableLocked = -1302;
	public const int32 JET_errTableDuplicate = -1303;
	public const int32 JET_errTableInUse = -1304;
	public const int32 JET_errObjectNotFound = -1305;
	public const int32 JET_errDensityInvalid = -1307;
	public const int32 JET_errTableNotEmpty = -1308;
	public const int32 JET_errInvalidTableId = -1310;
	public const int32 JET_errTooManyOpenTables = -1311;
	public const int32 JET_errIllegalOperation = -1312;
	public const int32 JET_errTooManyOpenTablesAndCleanupTimedOut = -1313;
	public const int32 JET_errObjectDuplicate = -1314;
	public const int32 JET_errInvalidObject = -1316;
	public const int32 JET_errCannotDeleteTempTable = -1317;
	public const int32 JET_errCannotDeleteSystemTable = -1318;
	public const int32 JET_errCannotDeleteTemplateTable = -1319;
	public const int32 JET_errExclusiveTableLockRequired = -1322;
	public const int32 JET_errFixedDDL = -1323;
	public const int32 JET_errFixedInheritedDDL = -1324;
	public const int32 JET_errCannotNestDDL = -1325;
	public const int32 JET_errDDLNotInheritable = -1326;
	public const uint32 JET_wrnTableInUseBySystem = 1327;
	public const int32 JET_errInvalidSettings = -1328;
	public const int32 JET_errClientRequestToStopJetService = -1329;
	public const int32 JET_errCannotAddFixedVarColumnToDerivedTable = -1330;
	public const int32 JET_errIndexCantBuild = -1401;
	public const int32 JET_errIndexHasPrimary = -1402;
	public const int32 JET_errIndexDuplicate = -1403;
	public const int32 JET_errIndexNotFound = -1404;
	public const int32 JET_errIndexMustStay = -1405;
	public const int32 JET_errIndexInvalidDef = -1406;
	public const int32 JET_errInvalidCreateIndex = -1409;
	public const int32 JET_errTooManyOpenIndexes = -1410;
	public const int32 JET_errMultiValuedIndexViolation = -1411;
	public const int32 JET_errIndexBuildCorrupted = -1412;
	public const int32 JET_errPrimaryIndexCorrupted = -1413;
	public const int32 JET_errSecondaryIndexCorrupted = -1414;
	public const uint32 JET_wrnCorruptIndexDeleted = 1415;
	public const int32 JET_errInvalidIndexId = -1416;
	public const uint32 JET_wrnPrimaryIndexOutOfDate = 1417;
	public const uint32 JET_wrnSecondaryIndexOutOfDate = 1418;
	public const int32 JET_errIndexTuplesSecondaryIndexOnly = -1430;
	public const int32 JET_errIndexTuplesTooManyColumns = -1431;
	public const int32 JET_errIndexTuplesOneColumnOnly = -1431;
	public const int32 JET_errIndexTuplesNonUniqueOnly = -1432;
	public const int32 JET_errIndexTuplesTextBinaryColumnsOnly = -1433;
	public const int32 JET_errIndexTuplesTextColumnsOnly = -1433;
	public const int32 JET_errIndexTuplesVarSegMacNotAllowed = -1434;
	public const int32 JET_errIndexTuplesInvalidLimits = -1435;
	public const int32 JET_errIndexTuplesCannotRetrieveFromIndex = -1436;
	public const int32 JET_errIndexTuplesKeyTooSmall = -1437;
	public const int32 JET_errInvalidLVChunkSize = -1438;
	public const int32 JET_errColumnCannotBeEncrypted = -1439;
	public const int32 JET_errCannotIndexOnEncryptedColumn = -1440;
	public const int32 JET_errColumnLong = -1501;
	public const int32 JET_errColumnNoChunk = -1502;
	public const int32 JET_errColumnDoesNotFit = -1503;
	public const int32 JET_errNullInvalid = -1504;
	public const int32 JET_errColumnIndexed = -1505;
	public const int32 JET_errColumnTooBig = -1506;
	public const int32 JET_errColumnNotFound = -1507;
	public const int32 JET_errColumnDuplicate = -1508;
	public const int32 JET_errMultiValuedColumnMustBeTagged = -1509;
	public const int32 JET_errColumnRedundant = -1510;
	public const int32 JET_errInvalidColumnType = -1511;
	public const uint32 JET_wrnColumnMaxTruncated = 1512;
	public const int32 JET_errTaggedNotNULL = -1514;
	public const int32 JET_errNoCurrentIndex = -1515;
	public const int32 JET_errKeyIsMade = -1516;
	public const int32 JET_errBadColumnId = -1517;
	public const int32 JET_errBadItagSequence = -1518;
	public const int32 JET_errColumnInRelationship = -1519;
	public const uint32 JET_wrnCopyLongValue = 1520;
	public const int32 JET_errCannotBeTagged = -1521;
	public const int32 JET_errDefaultValueTooBig = -1524;
	public const int32 JET_errMultiValuedDuplicate = -1525;
	public const int32 JET_errLVCorrupted = -1526;
	public const int32 JET_errMultiValuedDuplicateAfterTruncation = -1528;
	public const int32 JET_errDerivedColumnCorruption = -1529;
	public const int32 JET_errInvalidPlaceholderColumn = -1530;
	public const uint32 JET_wrnColumnSkipped = 1531;
	public const uint32 JET_wrnColumnNotLocal = 1532;
	public const uint32 JET_wrnColumnMoreTags = 1533;
	public const uint32 JET_wrnColumnTruncated = 1534;
	public const uint32 JET_wrnColumnPresent = 1535;
	public const uint32 JET_wrnColumnSingleValue = 1536;
	public const uint32 JET_wrnColumnDefault = 1537;
	public const int32 JET_errColumnCannotBeCompressed = -1538;
	public const uint32 JET_wrnColumnNotInRecord = 1539;
	public const int32 JET_errColumnNoEncryptionKey = -1540;
	public const uint32 JET_wrnColumnReference = 1541;
	public const int32 JET_errRecordNotFound = -1601;
	public const int32 JET_errRecordNoCopy = -1602;
	public const int32 JET_errNoCurrentRecord = -1603;
	public const int32 JET_errRecordPrimaryChanged = -1604;
	public const int32 JET_errKeyDuplicate = -1605;
	public const int32 JET_errAlreadyPrepared = -1607;
	public const int32 JET_errKeyNotMade = -1608;
	public const int32 JET_errUpdateNotPrepared = -1609;
	public const uint32 JET_wrnDataHasChanged = 1610;
	public const int32 JET_errDataHasChanged = -1611;
	public const uint32 JET_wrnKeyChanged = 1618;
	public const int32 JET_errLanguageNotSupported = -1619;
	public const int32 JET_errDecompressionFailed = -1620;
	public const int32 JET_errUpdateMustVersion = -1621;
	public const int32 JET_errDecryptionFailed = -1622;
	public const int32 JET_errEncryptionBadItag = -1623;
	public const int32 JET_errTooManySorts = -1701;
	public const int32 JET_errInvalidOnSort = -1702;
	public const int32 JET_errTempFileOpenError = -1803;
	public const int32 JET_errTooManyAttachedDatabases = -1805;
	public const int32 JET_errDiskFull = -1808;
	public const int32 JET_errPermissionDenied = -1809;
	public const int32 JET_errFileNotFound = -1811;
	public const int32 JET_errFileInvalidType = -1812;
	public const uint32 JET_wrnFileOpenReadOnly = 1813;
	public const int32 JET_errFileAlreadyExists = -1814;
	public const int32 JET_errAfterInitialization = -1850;
	public const int32 JET_errLogCorrupted = -1852;
	public const int32 JET_errInvalidOperation = -1906;
	public const int32 JET_errAccessDenied = -1907;
	public const uint32 JET_wrnIdleFull = 1908;
	public const int32 JET_errTooManySplits = -1909;
	public const int32 JET_errSessionSharingViolation = -1910;
	public const int32 JET_errEntryPointNotFound = -1911;
	public const int32 JET_errSessionContextAlreadySet = -1912;
	public const int32 JET_errSessionContextNotSetByThisThread = -1913;
	public const int32 JET_errSessionInUse = -1914;
	public const int32 JET_errRecordFormatConversionFailed = -1915;
	public const int32 JET_errOneDatabasePerSession = -1916;
	public const int32 JET_errRollbackError = -1917;
	public const int32 JET_errFlushMapVersionUnsupported = -1918;
	public const int32 JET_errFlushMapDatabaseMismatch = -1919;
	public const int32 JET_errFlushMapUnrecoverable = -1920;
	public const uint32 JET_wrnDefragAlreadyRunning = 2000;
	public const uint32 JET_wrnDefragNotRunning = 2001;
	public const int32 JET_errDatabaseAlreadyRunningMaintenance = -2004;
	public const uint32 JET_wrnCallbackNotRegistered = 2100;
	public const int32 JET_errCallbackFailed = -2101;
	public const int32 JET_errCallbackNotResolved = -2102;
	public const int32 JET_errSpaceHintsInvalid = -2103;
	public const int32 JET_errOSSnapshotInvalidSequence = -2401;
	public const int32 JET_errOSSnapshotTimeOut = -2402;
	public const int32 JET_errOSSnapshotNotAllowed = -2403;
	public const int32 JET_errOSSnapshotInvalidSnapId = -2404;
	public const int32 JET_errLSCallbackNotSpecified = -3000;
	public const int32 JET_errLSAlreadySet = -3001;
	public const int32 JET_errLSNotSet = -3002;
	public const int32 JET_errFileIOSparse = -4000;
	public const int32 JET_errFileIOBeyondEOF = -4001;
	public const int32 JET_errFileIOAbort = -4002;
	public const int32 JET_errFileIORetry = -4003;
	public const int32 JET_errFileIOFail = -4004;
	public const int32 JET_errFileCompressed = -4005;
	public const uint32 JET_BASE_NAME_LENGTH = 3;
	public const uint32 JET_bitDumpMinimum = 1;
	public const uint32 JET_bitDumpMaximum = 2;
	public const uint32 JET_bitDumpCacheMinimum = 4;
	public const uint32 JET_bitDumpCacheMaximum = 8;
	public const uint32 JET_bitDumpCacheIncludeDirtyPages = 16;
	public const uint32 JET_bitDumpCacheIncludeCachedPages = 32;
	public const uint32 JET_bitDumpCacheIncludeCorruptedPages = 64;
	public const uint32 JET_bitDumpCacheNoDecommit = 128;
}
#endregion

#region TypeDefs
typealias JET_OSSNAPID = uint;

typealias JET_LS = uint;

#endregion


#region Enums

[AllowDuplicates]
public enum JET_RELOP : int32
{
	JET_relopEquals = 0,
	JET_relopPrefixEquals = 1,
	JET_relopNotEquals = 2,
	JET_relopLessThanOrEqual = 3,
	JET_relopLessThan = 4,
	JET_relopGreaterThanOrEqual = 5,
	JET_relopGreaterThan = 6,
	JET_relopBitmaskEqualsZero = 7,
	JET_relopBitmaskNotEqualsZero = 8,
}


[AllowDuplicates]
public enum JET_ERRCAT : int32
{
	JET_errcatUnknown = 0,
	JET_errcatError = 1,
	JET_errcatOperation = 2,
	JET_errcatFatal = 3,
	JET_errcatIO = 4,
	JET_errcatResource = 5,
	JET_errcatMemory = 6,
	JET_errcatQuota = 7,
	JET_errcatDisk = 8,
	JET_errcatData = 9,
	JET_errcatCorruption = 10,
	JET_errcatInconsistent = 11,
	JET_errcatFragmentation = 12,
	JET_errcatApi = 13,
	JET_errcatUsage = 14,
	JET_errcatState = 15,
	JET_errcatObsolete = 16,
	JET_errcatMax = 17,
}


[AllowDuplicates]
public enum JET_INDEXCHECKING : int32
{
	JET_IndexCheckingOff = 0,
	JET_IndexCheckingOn = 1,
	JET_IndexCheckingDeferToOpenTable = 2,
	JET_IndexCheckingMax = 3,
}

#endregion

#region Function Pointers
public function int32 JET_PFNSTATUS(JET_SESID sesid, uint32 snp, uint32 snt, void* pv);

public function int32 JET_CALLBACK(JET_SESID sesid, uint32 dbid, JET_TABLEID tableid, uint32 cbtyp, void* pvArg1, void* pvArg2, void* pvContext, JET_API_PTR ulUnused);

public function int32 JET_PFNDURABLECOMMITCALLBACK(JET_INSTANCE instance, JET_COMMIT_ID* pCommitIdSeen, uint32 grbit);

public function void* JET_PFNREALLOC(void* pvContext, void* pv, uint32 cb);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_INDEXID
{
	public uint32 cbStruct;
	public uint8[16] rgbIndexId;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_OBJECTINFO
{
	public uint32 cbStruct;
	public uint32 objtyp;
	public double dtCreate;
	public double dtUpdate;
	public uint32 grbit;
	public uint32 flags;
	public uint32 cRecord;
	public uint32 cPage;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_THREADSTATS2
{
	public uint32 cbStruct;
	public uint32 cPageReferenced;
	public uint32 cPageRead;
	public uint32 cPagePreread;
	public uint32 cPageDirtied;
	public uint32 cPageRedirtied;
	public uint32 cLogRecord;
	public uint32 cbLogRecord;
	public uint64 cusecPageCacheMiss;
	public uint32 cPageCacheMiss;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_COMMIT_ID
{
	public JET_SIGNATURE signLog;
	public int32 reserved;
	public int64 commitId;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_RBSINFOMISC
{
	public int32 lRBSGeneration;
	public JET_LOGTIME logtimeCreate;
	public JET_LOGTIME logtimeCreatePrevRBS;
	public uint32 ulMajor;
	public uint32 ulMinor;
	public uint64 cbLogicalFileSize;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_RBSREVERTINFOMISC
{
	public int32 lGenMinRevertStart;
	public int32 lGenMaxRevertStart;
	public int32 lGenMinRevertEnd;
	public int32 lGenMaxRevertEnd;
	public JET_LOGTIME logtimeRevertFrom;
	public uint64 cSecRevert;
	public uint64 cPagesReverted;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_RECSIZE
{
	public uint64 cbData;
	public uint64 cbLongValueData;
	public uint64 cbOverhead;
	public uint64 cbLongValueOverhead;
	public uint64 cNonTaggedColumns;
	public uint64 cTaggedColumns;
	public uint64 cLongValues;
	public uint64 cMultiValues;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct JET_RECSIZE2
{
	public uint64 cbData;
	public uint64 cbLongValueData;
	public uint64 cbOverhead;
	public uint64 cbLongValueOverhead;
	public uint64 cNonTaggedColumns;
	public uint64 cTaggedColumns;
	public uint64 cLongValues;
	public uint64 cMultiValues;
	public uint64 cCompressedColumns;
	public uint64 cbDataCompressed;
	public uint64 cbLongValueDataCompressed;
}
#endif

#if BF_32_BIT
[CRepr]
public struct JET_INDEXID
{
	public uint32 cbStruct;
	public uint8[12] rgbIndexId;
}
#endif

[CRepr]
public struct JET_RSTMAP_A
{
	public PSTR szDatabaseName;
	public PSTR szNewDatabaseName;
}

[CRepr]
public struct JET_RSTMAP_W
{
	public PWSTR szDatabaseName;
	public PWSTR szNewDatabaseName;
}

[CRepr]
public struct JET_CONVERT_A
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 fFlags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public PSTR szOldDll;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct JET_CONVERT_W
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 fFlags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public PWSTR szOldDll;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct JET_SNPROG
{
	public uint32 cbStruct;
	public uint32 cunitDone;
	public uint32 cunitTotal;
}

[CRepr]
public struct JET_DBINFOUPGRADE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 ulFlags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint32 cbStruct;
	public uint32 cbFilesizeLow;
	public uint32 cbFilesizeHigh;
	public uint32 cbFreeSpaceRequiredLow;
	public uint32 cbFreeSpaceRequiredHigh;
	public uint32 csecToUpgrade;
	public using _Anonymous_e__Union Anonymous;
}

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_OBJECTINFO
{
	public uint32 cbStruct;
	public uint32 objtyp;
	public double dtCreate;
	public double dtUpdate;
	public uint32 grbit;
	public uint32 flags;
	public uint32 cRecord;
	public uint32 cPage;
}
#endif

[CRepr]
public struct JET_OBJECTLIST
{
	public uint32 cbStruct;
	public JET_TABLEID tableid;
	public uint32 cRecord;
	public uint32 columnidcontainername;
	public uint32 columnidobjectname;
	public uint32 columnidobjtyp;
	public uint32 columniddtCreate;
	public uint32 columniddtUpdate;
	public uint32 columnidgrbit;
	public uint32 columnidflags;
	public uint32 columnidcRecord;
	public uint32 columnidcPage;
}

[CRepr]
public struct JET_COLUMNLIST
{
	public uint32 cbStruct;
	public JET_TABLEID tableid;
	public uint32 cRecord;
	public uint32 columnidPresentationOrder;
	public uint32 columnidcolumnname;
	public uint32 columnidcolumnid;
	public uint32 columnidcoltyp;
	public uint32 columnidCountry;
	public uint32 columnidLangid;
	public uint32 columnidCp;
	public uint32 columnidCollate;
	public uint32 columnidcbMax;
	public uint32 columnidgrbit;
	public uint32 columnidDefault;
	public uint32 columnidBaseTableName;
	public uint32 columnidBaseColumnName;
	public uint32 columnidDefinitionName;
}

[CRepr]
public struct JET_COLUMNDEF
{
	public uint32 cbStruct;
	public uint32 columnid;
	public uint32 coltyp;
	public uint16 wCountry;
	public uint16 langid;
	public uint16 cp;
	public uint16 wCollate;
	public uint32 cbMax;
	public uint32 grbit;
}

[CRepr]
public struct JET_COLUMNBASE_A
{
	public uint32 cbStruct;
	public uint32 columnid;
	public uint32 coltyp;
	public uint16 wCountry;
	public uint16 langid;
	public uint16 cp;
	public uint16 wFiller;
	public uint32 cbMax;
	public uint32 grbit;
	public CHAR[256] szBaseTableName;
	public CHAR[256] szBaseColumnName;
}

[CRepr]
public struct JET_COLUMNBASE_W
{
	public uint32 cbStruct;
	public uint32 columnid;
	public uint32 coltyp;
	public uint16 wCountry;
	public uint16 langid;
	public uint16 cp;
	public uint16 wFiller;
	public uint32 cbMax;
	public uint32 grbit;
	public char16[256] szBaseTableName;
	public char16[256] szBaseColumnName;
}

[CRepr]
public struct JET_INDEXLIST
{
	public uint32 cbStruct;
	public JET_TABLEID tableid;
	public uint32 cRecord;
	public uint32 columnidindexname;
	public uint32 columnidgrbitIndex;
	public uint32 columnidcKey;
	public uint32 columnidcEntry;
	public uint32 columnidcPage;
	public uint32 columnidcColumn;
	public uint32 columnidiColumn;
	public uint32 columnidcolumnid;
	public uint32 columnidcoltyp;
	public uint32 columnidCountry;
	public uint32 columnidLangid;
	public uint32 columnidCp;
	public uint32 columnidCollate;
	public uint32 columnidgrbitColumn;
	public uint32 columnidcolumnname;
	public uint32 columnidLCMapFlags;
}

[CRepr]
public struct JET_COLUMNCREATE_A
{
	public uint32 cbStruct;
	public PSTR szColumnName;
	public uint32 coltyp;
	public uint32 cbMax;
	public uint32 grbit;
	public void* pvDefault;
	public uint32 cbDefault;
	public uint32 cp;
	public uint32 columnid;
	public int32 err;
}

[CRepr]
public struct JET_COLUMNCREATE_W
{
	public uint32 cbStruct;
	public PWSTR szColumnName;
	public uint32 coltyp;
	public uint32 cbMax;
	public uint32 grbit;
	public void* pvDefault;
	public uint32 cbDefault;
	public uint32 cp;
	public uint32 columnid;
	public int32 err;
}

[CRepr]
public struct JET_USERDEFINEDDEFAULT_A
{
	public PSTR szCallback;
	public uint8* pbUserData;
	public uint32 cbUserData;
	public PSTR szDependantColumns;
}

[CRepr]
public struct JET_USERDEFINEDDEFAULT_W
{
	public PWSTR szCallback;
	public uint8* pbUserData;
	public uint32 cbUserData;
	public PWSTR szDependantColumns;
}

[CRepr]
public struct JET_CONDITIONALCOLUMN_A
{
	public uint32 cbStruct;
	public PSTR szColumnName;
	public uint32 grbit;
}

[CRepr]
public struct JET_CONDITIONALCOLUMN_W
{
	public uint32 cbStruct;
	public PWSTR szColumnName;
	public uint32 grbit;
}

[CRepr]
public struct JET_UNICODEINDEX
{
	public uint32 lcid;
	public uint32 dwMapFlags;
}

[CRepr]
public struct JET_UNICODEINDEX2
{
	public PWSTR szLocaleName;
	public uint32 dwMapFlags;
}

[CRepr]
public struct JET_TUPLELIMITS
{
	public uint32 chLengthMin;
	public uint32 chLengthMax;
	public uint32 chToIndexMax;
	public uint32 cchIncrement;
	public uint32 ichStart;
}

[CRepr]
public struct JET_SPACEHINTS
{
	public uint32 cbStruct;
	public uint32 ulInitialDensity;
	public uint32 cbInitial;
	public uint32 grbit;
	public uint32 ulMaintDensity;
	public uint32 ulGrowth;
	public uint32 cbMinExtent;
	public uint32 cbMaxExtent;
}

[CRepr]
public struct JET_INDEXCREATE_A
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 lcid;
		public JET_UNICODEINDEX* pidxunicode;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 cbVarSegMac;
		public JET_TUPLELIMITS* ptuplelimits;
	}
	public uint32 cbStruct;
	public PSTR szIndexName;
	public PSTR szKey;
	public uint32 cbKey;
	public uint32 grbit;
	public uint32 ulDensity;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public JET_CONDITIONALCOLUMN_A* rgconditionalcolumn;
	public uint32 cConditionalColumn;
	public int32 err;
	public uint32 cbKeyMost;
}

[CRepr]
public struct JET_INDEXCREATE_W
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 lcid;
		public JET_UNICODEINDEX* pidxunicode;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 cbVarSegMac;
		public JET_TUPLELIMITS* ptuplelimits;
	}
	public uint32 cbStruct;
	public PWSTR szIndexName;
	public PWSTR szKey;
	public uint32 cbKey;
	public uint32 grbit;
	public uint32 ulDensity;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public JET_CONDITIONALCOLUMN_W* rgconditionalcolumn;
	public uint32 cConditionalColumn;
	public int32 err;
	public uint32 cbKeyMost;
}

[CRepr]
public struct JET_INDEXCREATE2_A
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 lcid;
		public JET_UNICODEINDEX* pidxunicode;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 cbVarSegMac;
		public JET_TUPLELIMITS* ptuplelimits;
	}
	public uint32 cbStruct;
	public PSTR szIndexName;
	public PSTR szKey;
	public uint32 cbKey;
	public uint32 grbit;
	public uint32 ulDensity;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public JET_CONDITIONALCOLUMN_A* rgconditionalcolumn;
	public uint32 cConditionalColumn;
	public int32 err;
	public uint32 cbKeyMost;
	public JET_SPACEHINTS* pSpacehints;
}

[CRepr]
public struct JET_INDEXCREATE2_W
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 lcid;
		public JET_UNICODEINDEX* pidxunicode;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 cbVarSegMac;
		public JET_TUPLELIMITS* ptuplelimits;
	}
	public uint32 cbStruct;
	public PWSTR szIndexName;
	public PWSTR szKey;
	public uint32 cbKey;
	public uint32 grbit;
	public uint32 ulDensity;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public JET_CONDITIONALCOLUMN_W* rgconditionalcolumn;
	public uint32 cConditionalColumn;
	public int32 err;
	public uint32 cbKeyMost;
	public JET_SPACEHINTS* pSpacehints;
}

[CRepr]
public struct JET_INDEXCREATE3_A
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cbVarSegMac;
		public JET_TUPLELIMITS* ptuplelimits;
	}
	public uint32 cbStruct;
	public PSTR szIndexName;
	public PSTR szKey;
	public uint32 cbKey;
	public uint32 grbit;
	public uint32 ulDensity;
	public JET_UNICODEINDEX2* pidxunicode;
	public using _Anonymous_e__Union Anonymous;
	public JET_CONDITIONALCOLUMN_A* rgconditionalcolumn;
	public uint32 cConditionalColumn;
	public int32 err;
	public uint32 cbKeyMost;
	public JET_SPACEHINTS* pSpacehints;
}

[CRepr]
public struct JET_INDEXCREATE3_W
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cbVarSegMac;
		public JET_TUPLELIMITS* ptuplelimits;
	}
	public uint32 cbStruct;
	public PWSTR szIndexName;
	public PWSTR szKey;
	public uint32 cbKey;
	public uint32 grbit;
	public uint32 ulDensity;
	public JET_UNICODEINDEX2* pidxunicode;
	public using _Anonymous_e__Union Anonymous;
	public JET_CONDITIONALCOLUMN_W* rgconditionalcolumn;
	public uint32 cConditionalColumn;
	public int32 err;
	public uint32 cbKeyMost;
	public JET_SPACEHINTS* pSpacehints;
}

[CRepr]
public struct JET_TABLECREATE_A
{
	public uint32 cbStruct;
	public PSTR szTableName;
	public PSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_A* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE_A* rgindexcreate;
	public uint32 cIndexes;
	public uint32 grbit;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE_W
{
	public uint32 cbStruct;
	public PWSTR szTableName;
	public PWSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_W* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE_W* rgindexcreate;
	public uint32 cIndexes;
	public uint32 grbit;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE2_A
{
	public uint32 cbStruct;
	public PSTR szTableName;
	public PSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_A* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE_A* rgindexcreate;
	public uint32 cIndexes;
	public PSTR szCallback;
	public uint32 cbtyp;
	public uint32 grbit;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE2_W
{
	public uint32 cbStruct;
	public PWSTR szTableName;
	public PWSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_W* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE_W* rgindexcreate;
	public uint32 cIndexes;
	public PWSTR szCallback;
	public uint32 cbtyp;
	public uint32 grbit;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE3_A
{
	public uint32 cbStruct;
	public PSTR szTableName;
	public PSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_A* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE2_A* rgindexcreate;
	public uint32 cIndexes;
	public PSTR szCallback;
	public uint32 cbtyp;
	public uint32 grbit;
	public JET_SPACEHINTS* pSeqSpacehints;
	public JET_SPACEHINTS* pLVSpacehints;
	public uint32 cbSeparateLV;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE3_W
{
	public uint32 cbStruct;
	public PWSTR szTableName;
	public PWSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_W* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE2_W* rgindexcreate;
	public uint32 cIndexes;
	public PWSTR szCallback;
	public uint32 cbtyp;
	public uint32 grbit;
	public JET_SPACEHINTS* pSeqSpacehints;
	public JET_SPACEHINTS* pLVSpacehints;
	public uint32 cbSeparateLV;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE4_A
{
	public uint32 cbStruct;
	public PSTR szTableName;
	public PSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_A* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE3_A* rgindexcreate;
	public uint32 cIndexes;
	public PSTR szCallback;
	public uint32 cbtyp;
	public uint32 grbit;
	public JET_SPACEHINTS* pSeqSpacehints;
	public JET_SPACEHINTS* pLVSpacehints;
	public uint32 cbSeparateLV;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_TABLECREATE4_W
{
	public uint32 cbStruct;
	public PWSTR szTableName;
	public PWSTR szTemplateTableName;
	public uint32 ulPages;
	public uint32 ulDensity;
	public JET_COLUMNCREATE_W* rgcolumncreate;
	public uint32 cColumns;
	public JET_INDEXCREATE3_W* rgindexcreate;
	public uint32 cIndexes;
	public PWSTR szCallback;
	public uint32 cbtyp;
	public uint32 grbit;
	public JET_SPACEHINTS* pSeqSpacehints;
	public JET_SPACEHINTS* pLVSpacehints;
	public uint32 cbSeparateLV;
	public JET_TABLEID tableid;
	public uint32 cCreated;
}

[CRepr]
public struct JET_OPENTEMPORARYTABLE
{
	public uint32 cbStruct;
	public JET_COLUMNDEF* prgcolumndef;
	public uint32 ccolumn;
	public JET_UNICODEINDEX* pidxunicode;
	public uint32 grbit;
	public uint32* prgcolumnid;
	public uint32 cbKeyMost;
	public uint32 cbVarSegMac;
	public JET_TABLEID tableid;
}

[CRepr]
public struct JET_OPENTEMPORARYTABLE2
{
	public uint32 cbStruct;
	public JET_COLUMNDEF* prgcolumndef;
	public uint32 ccolumn;
	public JET_UNICODEINDEX2* pidxunicode;
	public uint32 grbit;
	public uint32* prgcolumnid;
	public uint32 cbKeyMost;
	public uint32 cbVarSegMac;
	public JET_TABLEID tableid;
}

[CRepr]
public struct JET_RETINFO
{
	public uint32 cbStruct;
	public uint32 ibLongValue;
	public uint32 itagSequence;
	public uint32 columnidNextTagged;
}

[CRepr]
public struct JET_SETINFO
{
	public uint32 cbStruct;
	public uint32 ibLongValue;
	public uint32 itagSequence;
}

[CRepr]
public struct JET_RECPOS
{
	public uint32 cbStruct;
	public uint32 centriesLT;
	public uint32 centriesInRange;
	public uint32 centriesTotal;
}

[CRepr]
public struct JET_RECORDLIST
{
	public uint32 cbStruct;
	public JET_TABLEID tableid;
	public uint32 cRecord;
	public uint32 columnidBookmark;
}

[CRepr]
public struct JET_INDEXRANGE
{
	public uint32 cbStruct;
	public JET_TABLEID tableid;
	public uint32 grbit;
}

[CRepr]
public struct JET_INDEX_COLUMN
{
	public uint32 columnid;
	public JET_RELOP relop;
	public void* pv;
	public uint32 cb;
	public uint32 grbit;
}

[CRepr]
public struct JET_INDEX_RANGE
{
	public JET_INDEX_COLUMN* rgStartColumns;
	public uint32 cStartColumns;
	public JET_INDEX_COLUMN* rgEndColumns;
	public uint32 cEndColumns;
}

[CRepr]
public struct JET_LOGTIME
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public CHAR bFiller2;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public CHAR bFiller1;
		public using _Anonymous_e__Struct Anonymous;
	}
	public CHAR bSeconds;
	public CHAR bMinutes;
	public CHAR bHours;
	public CHAR bDay;
	public CHAR bMonth;
	public CHAR bYear;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct JET_BKLOGTIME
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public CHAR bFiller2;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public CHAR bFiller1;
		public using _Anonymous_e__Struct Anonymous;
	}
	public CHAR bSeconds;
	public CHAR bMinutes;
	public CHAR bHours;
	public CHAR bDay;
	public CHAR bMonth;
	public CHAR bYear;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr, Packed(1)]
public struct JET_LGPOS
{
	public uint16 ib;
	public uint16 isec;
	public int32 lGeneration;
}

[CRepr, Packed(1)]
public struct JET_SIGNATURE
{
	public uint32 ulRandom;
	public JET_LOGTIME logtimeCreate;
	public CHAR[16] szComputerName;
}

[CRepr, Packed(1)]
public struct JET_BKINFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public JET_LOGTIME logtimeMark;
		public JET_BKLOGTIME bklogtimeMark;
	}
	public JET_LGPOS lgposMark;
	public using _Anonymous_e__Union Anonymous;
	public uint32 genLow;
	public uint32 genHigh;
}

[CRepr]
public struct JET_DBINFOMISC
{
	public uint32 ulVersion;
	public uint32 ulUpdate;
	public JET_SIGNATURE signDb;
	public uint32 dbstate;
	public JET_LGPOS lgposConsistent;
	public JET_LOGTIME logtimeConsistent;
	public JET_LOGTIME logtimeAttach;
	public JET_LGPOS lgposAttach;
	public JET_LOGTIME logtimeDetach;
	public JET_LGPOS lgposDetach;
	public JET_SIGNATURE signLog;
	public JET_BKINFO bkinfoFullPrev;
	public JET_BKINFO bkinfoIncPrev;
	public JET_BKINFO bkinfoFullCur;
	public uint32 fShadowingDisabled;
	public uint32 fUpgradeDb;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public int32 lSPNumber;
	public uint32 cbPageSize;
}

[CRepr]
public struct JET_DBINFOMISC2
{
	public uint32 ulVersion;
	public uint32 ulUpdate;
	public JET_SIGNATURE signDb;
	public uint32 dbstate;
	public JET_LGPOS lgposConsistent;
	public JET_LOGTIME logtimeConsistent;
	public JET_LOGTIME logtimeAttach;
	public JET_LGPOS lgposAttach;
	public JET_LOGTIME logtimeDetach;
	public JET_LGPOS lgposDetach;
	public JET_SIGNATURE signLog;
	public JET_BKINFO bkinfoFullPrev;
	public JET_BKINFO bkinfoIncPrev;
	public JET_BKINFO bkinfoFullCur;
	public uint32 fShadowingDisabled;
	public uint32 fUpgradeDb;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public int32 lSPNumber;
	public uint32 cbPageSize;
	public uint32 genMinRequired;
	public uint32 genMaxRequired;
	public JET_LOGTIME logtimeGenMaxCreate;
	public uint32 ulRepairCount;
	public JET_LOGTIME logtimeRepair;
	public uint32 ulRepairCountOld;
	public uint32 ulECCFixSuccess;
	public JET_LOGTIME logtimeECCFixSuccess;
	public uint32 ulECCFixSuccessOld;
	public uint32 ulECCFixFail;
	public JET_LOGTIME logtimeECCFixFail;
	public uint32 ulECCFixFailOld;
	public uint32 ulBadChecksum;
	public JET_LOGTIME logtimeBadChecksum;
	public uint32 ulBadChecksumOld;
}

[CRepr]
public struct JET_DBINFOMISC3
{
	public uint32 ulVersion;
	public uint32 ulUpdate;
	public JET_SIGNATURE signDb;
	public uint32 dbstate;
	public JET_LGPOS lgposConsistent;
	public JET_LOGTIME logtimeConsistent;
	public JET_LOGTIME logtimeAttach;
	public JET_LGPOS lgposAttach;
	public JET_LOGTIME logtimeDetach;
	public JET_LGPOS lgposDetach;
	public JET_SIGNATURE signLog;
	public JET_BKINFO bkinfoFullPrev;
	public JET_BKINFO bkinfoIncPrev;
	public JET_BKINFO bkinfoFullCur;
	public uint32 fShadowingDisabled;
	public uint32 fUpgradeDb;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public int32 lSPNumber;
	public uint32 cbPageSize;
	public uint32 genMinRequired;
	public uint32 genMaxRequired;
	public JET_LOGTIME logtimeGenMaxCreate;
	public uint32 ulRepairCount;
	public JET_LOGTIME logtimeRepair;
	public uint32 ulRepairCountOld;
	public uint32 ulECCFixSuccess;
	public JET_LOGTIME logtimeECCFixSuccess;
	public uint32 ulECCFixSuccessOld;
	public uint32 ulECCFixFail;
	public JET_LOGTIME logtimeECCFixFail;
	public uint32 ulECCFixFailOld;
	public uint32 ulBadChecksum;
	public JET_LOGTIME logtimeBadChecksum;
	public uint32 ulBadChecksumOld;
	public uint32 genCommitted;
}

[CRepr]
public struct JET_DBINFOMISC4
{
	public uint32 ulVersion;
	public uint32 ulUpdate;
	public JET_SIGNATURE signDb;
	public uint32 dbstate;
	public JET_LGPOS lgposConsistent;
	public JET_LOGTIME logtimeConsistent;
	public JET_LOGTIME logtimeAttach;
	public JET_LGPOS lgposAttach;
	public JET_LOGTIME logtimeDetach;
	public JET_LGPOS lgposDetach;
	public JET_SIGNATURE signLog;
	public JET_BKINFO bkinfoFullPrev;
	public JET_BKINFO bkinfoIncPrev;
	public JET_BKINFO bkinfoFullCur;
	public uint32 fShadowingDisabled;
	public uint32 fUpgradeDb;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public int32 lSPNumber;
	public uint32 cbPageSize;
	public uint32 genMinRequired;
	public uint32 genMaxRequired;
	public JET_LOGTIME logtimeGenMaxCreate;
	public uint32 ulRepairCount;
	public JET_LOGTIME logtimeRepair;
	public uint32 ulRepairCountOld;
	public uint32 ulECCFixSuccess;
	public JET_LOGTIME logtimeECCFixSuccess;
	public uint32 ulECCFixSuccessOld;
	public uint32 ulECCFixFail;
	public JET_LOGTIME logtimeECCFixFail;
	public uint32 ulECCFixFailOld;
	public uint32 ulBadChecksum;
	public JET_LOGTIME logtimeBadChecksum;
	public uint32 ulBadChecksumOld;
	public uint32 genCommitted;
	public JET_BKINFO bkinfoCopyPrev;
	public JET_BKINFO bkinfoDiffPrev;
}

[CRepr]
public struct JET_THREADSTATS
{
	public uint32 cbStruct;
	public uint32 cPageReferenced;
	public uint32 cPageRead;
	public uint32 cPagePreread;
	public uint32 cPageDirtied;
	public uint32 cPageRedirtied;
	public uint32 cLogRecord;
	public uint32 cbLogRecord;
}

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_THREADSTATS2
{
	public uint32 cbStruct;
	public uint32 cPageReferenced;
	public uint32 cPageRead;
	public uint32 cPagePreread;
	public uint32 cPageDirtied;
	public uint32 cPageRedirtied;
	public uint32 cLogRecord;
	public uint32 cbLogRecord;
	public uint64 cusecPageCacheMiss;
	public uint32 cPageCacheMiss;
}
#endif

[CRepr]
public struct JET_RSTINFO_A
{
	public uint32 cbStruct;
	public JET_RSTMAP_A* rgrstmap;
	public int32 crstmap;
	public JET_LGPOS lgposStop;
	public JET_LOGTIME logtimeStop;
	public JET_PFNSTATUS pfnStatus;
}

[CRepr]
public struct JET_RSTINFO_W
{
	public uint32 cbStruct;
	public JET_RSTMAP_W* rgrstmap;
	public int32 crstmap;
	public JET_LGPOS lgposStop;
	public JET_LOGTIME logtimeStop;
	public JET_PFNSTATUS pfnStatus;
}

[CRepr]
public struct JET_ERRINFOBASIC_W
{
	public uint32 cbStruct;
	public int32 errValue;
	public JET_ERRCAT errcatMostSpecific;
	public uint8[8] rgCategoricalHierarchy;
	public uint32 lSourceLine;
	public char16[64] rgszSourceFile;
}

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_COMMIT_ID
{
	public JET_SIGNATURE signLog;
	public int32 reserved;
	public int64 commitId;
}
#endif

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_RBSINFOMISC
{
	public int32 lRBSGeneration;
	public JET_LOGTIME logtimeCreate;
	public JET_LOGTIME logtimeCreatePrevRBS;
	public uint32 ulMajor;
	public uint32 ulMinor;
	public uint64 cbLogicalFileSize;
}
#endif

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_RBSREVERTINFOMISC
{
	public int32 lGenMinRevertStart;
	public int32 lGenMaxRevertStart;
	public int32 lGenMinRevertEnd;
	public int32 lGenMaxRevertEnd;
	public JET_LOGTIME logtimeRevertFrom;
	public uint64 cSecRevert;
	public uint64 cPagesReverted;
}
#endif

[CRepr]
public struct JET_OPERATIONCONTEXT
{
	public uint32 ulUserID;
	public uint8 nOperationID;
	public uint8 nOperationType;
	public uint8 nClientType;
	public uint8 fFlags;
}

[CRepr]
public struct JET_SETCOLUMN
{
	public uint32 columnid;
	public void* pvData;
	public uint32 cbData;
	public uint32 grbit;
	public uint32 ibLongValue;
	public uint32 itagSequence;
	public int32 err;
}

[CRepr]
public struct JET_SETSYSPARAM_A
{
	public uint32 paramid;
	public JET_API_PTR lParam;
	public PSTR sz;
	public int32 err;
}

[CRepr]
public struct JET_SETSYSPARAM_W
{
	public uint32 paramid;
	public JET_API_PTR lParam;
	public PWSTR sz;
	public int32 err;
}

[CRepr]
public struct JET_RETRIEVECOLUMN
{
	public uint32 columnid;
	public void* pvData;
	public uint32 cbData;
	public uint32 cbActual;
	public uint32 grbit;
	public uint32 ibLongValue;
	public uint32 itagSequence;
	public uint32 columnidNextTagged;
	public int32 err;
}

[CRepr]
public struct JET_ENUMCOLUMNID
{
	public uint32 columnid;
	public uint32 ctagSequence;
	public uint32* rgtagSequence;
}

[CRepr]
public struct JET_ENUMCOLUMNVALUE
{
	public uint32 itagSequence;
	public int32 err;
	public uint32 cbData;
	public void* pvData;
}

[CRepr]
public struct JET_ENUMCOLUMN
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 cbData;
			public void* pvData;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 cEnumColumnValue;
			public JET_ENUMCOLUMNVALUE* rgEnumColumnValue;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
	}
	public uint32 columnid;
	public int32 err;
	public using _Anonymous_e__Union Anonymous;
}

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_RECSIZE
{
	public uint64 cbData;
	public uint64 cbLongValueData;
	public uint64 cbOverhead;
	public uint64 cbLongValueOverhead;
	public uint64 cNonTaggedColumns;
	public uint64 cTaggedColumns;
	public uint64 cLongValues;
	public uint64 cMultiValues;
}
#endif

#if BF_32_BIT
[CRepr, Packed(4)]
public struct JET_RECSIZE2
{
	public uint64 cbData;
	public uint64 cbLongValueData;
	public uint64 cbOverhead;
	public uint64 cbLongValueOverhead;
	public uint64 cNonTaggedColumns;
	public uint64 cTaggedColumns;
	public uint64 cLongValues;
	public uint64 cMultiValues;
	public uint64 cCompressedColumns;
	public uint64 cbDataCompressed;
	public uint64 cbLongValueDataCompressed;
}
#endif

[CRepr]
public struct JET_LOGINFO_A
{
	public uint32 cbSize;
	public uint32 ulGenLow;
	public uint32 ulGenHigh;
	public CHAR[4] szBaseName;
}

[CRepr]
public struct JET_LOGINFO_W
{
	public uint32 cbSize;
	public uint32 ulGenLow;
	public uint32 ulGenHigh;
	public char16[4] szBaseName;
}

[CRepr]
public struct JET_INSTANCE_INFO_A
{
	public JET_INSTANCE hInstanceId;
	public PSTR szInstanceName;
	public JET_API_PTR cDatabases;
	public int8** szDatabaseFileName;
	public int8** szDatabaseDisplayName;
	public int8** szDatabaseSLVFileName_Obsolete;
}

[CRepr]
public struct JET_INSTANCE_INFO_W
{
	public JET_INSTANCE hInstanceId;
	public PWSTR szInstanceName;
	public JET_API_PTR cDatabases;
	public uint16** szDatabaseFileName;
	public uint16** szDatabaseDisplayName;
	public uint16** szDatabaseSLVFileName_Obsolete;
}

#endregion

#region Functions
public static
{
	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetInit(JET_INSTANCE* pinstance);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetInit2(JET_INSTANCE* pinstance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetInit3A(JET_INSTANCE* pinstance, JET_RSTINFO_A* prstInfo, uint32 grbit);
	public static int32 JetInit3(JET_INSTANCE* pinstance, JET_RSTINFO_A* prstInfo, uint32 grbit) => JetInit3A(pinstance, prstInfo, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetInit3W(JET_INSTANCE* pinstance, JET_RSTINFO_W* prstInfo, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateInstanceA(JET_INSTANCE* pinstance, int8* szInstanceName);
	public static int32 JetCreateInstance(JET_INSTANCE* pinstance, int8* szInstanceName) => JetCreateInstanceA(pinstance, szInstanceName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateInstanceW(JET_INSTANCE* pinstance, uint16* szInstanceName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateInstance2A(JET_INSTANCE* pinstance, int8* szInstanceName, int8* szDisplayName, uint32 grbit);
	public static int32 JetCreateInstance2(JET_INSTANCE* pinstance, int8* szInstanceName, int8* szDisplayName, uint32 grbit) => JetCreateInstance2A(pinstance, szInstanceName, szDisplayName, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateInstance2W(JET_INSTANCE* pinstance, uint16* szInstanceName, uint16* szDisplayName, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetInstanceMiscInfo(JET_INSTANCE instance, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetTerm(JET_INSTANCE instance);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetTerm2(JET_INSTANCE instance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetStopService();

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetStopServiceInstance(JET_INSTANCE instance);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetStopServiceInstance2(JET_INSTANCE instance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetStopBackup();

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetStopBackupInstance(JET_INSTANCE instance);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetSystemParameterA(JET_INSTANCE* pinstance, JET_SESID sesid, uint32 paramid, JET_API_PTR lParam, int8* szParam);
	public static int32 JetSetSystemParameter(JET_INSTANCE* pinstance, JET_SESID sesid, uint32 paramid, JET_API_PTR lParam, int8* szParam) => JetSetSystemParameterA(pinstance, sesid, paramid, lParam, szParam);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetSystemParameterW(JET_INSTANCE* pinstance, JET_SESID sesid, uint32 paramid, JET_API_PTR lParam, uint16* szParam);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetSystemParameterA(JET_INSTANCE instance, JET_SESID sesid, uint32 paramid, JET_API_PTR* plParam, int8* szParam, uint32 cbMax);
	public static int32 JetGetSystemParameter(JET_INSTANCE instance, JET_SESID sesid, uint32 paramid, JET_API_PTR* plParam, int8* szParam, uint32 cbMax) => JetGetSystemParameterA(instance, sesid, paramid, plParam, szParam, cbMax);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetSystemParameterW(JET_INSTANCE instance, JET_SESID sesid, uint32 paramid, JET_API_PTR* plParam, uint16* szParam, uint32 cbMax);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEnableMultiInstanceA(JET_SETSYSPARAM_A* psetsysparam, uint32 csetsysparam, uint32* pcsetsucceed);
	public static int32 JetEnableMultiInstance(JET_SETSYSPARAM_A* psetsysparam, uint32 csetsysparam, uint32* pcsetsucceed) => JetEnableMultiInstanceA(psetsysparam, csetsysparam, pcsetsucceed);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEnableMultiInstanceW(JET_SETSYSPARAM_W* psetsysparam, uint32 csetsysparam, uint32* pcsetsucceed);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetThreadStats(void* pvResult, uint32 cbMax);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginSessionA(JET_INSTANCE instance, JET_SESID* psesid, int8* szUserName, int8* szPassword);
	public static int32 JetBeginSession(JET_INSTANCE instance, JET_SESID* psesid, int8* szUserName, int8* szPassword) => JetBeginSessionA(instance, psesid, szUserName, szPassword);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginSessionW(JET_INSTANCE instance, JET_SESID* psesid, uint16* szUserName, uint16* szPassword);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDupSession(JET_SESID sesid, JET_SESID* psesid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEndSession(JET_SESID sesid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetVersion(JET_SESID sesid, uint32* pwVersion);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetIdle(JET_SESID sesid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateDatabaseA(JET_SESID sesid, int8* szFilename, int8* szConnect, uint32* pdbid, uint32 grbit);
	public static int32 JetCreateDatabase(JET_SESID sesid, int8* szFilename, int8* szConnect, uint32* pdbid, uint32 grbit) => JetCreateDatabaseA(sesid, szFilename, szConnect, pdbid, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateDatabaseW(JET_SESID sesid, uint16* szFilename, uint16* szConnect, uint32* pdbid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateDatabase2A(JET_SESID sesid, int8* szFilename, uint32 cpgDatabaseSizeMax, uint32* pdbid, uint32 grbit);
	public static int32 JetCreateDatabase2(JET_SESID sesid, int8* szFilename, uint32 cpgDatabaseSizeMax, uint32* pdbid, uint32 grbit) => JetCreateDatabase2A(sesid, szFilename, cpgDatabaseSizeMax, pdbid, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateDatabase2W(JET_SESID sesid, uint16* szFilename, uint32 cpgDatabaseSizeMax, uint32* pdbid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetAttachDatabaseA(JET_SESID sesid, int8* szFilename, uint32 grbit);
	public static int32 JetAttachDatabase(JET_SESID sesid, int8* szFilename, uint32 grbit) => JetAttachDatabaseA(sesid, szFilename, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetAttachDatabaseW(JET_SESID sesid, uint16* szFilename, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetAttachDatabase2A(JET_SESID sesid, int8* szFilename, uint32 cpgDatabaseSizeMax, uint32 grbit);
	public static int32 JetAttachDatabase2(JET_SESID sesid, int8* szFilename, uint32 cpgDatabaseSizeMax, uint32 grbit) => JetAttachDatabase2A(sesid, szFilename, cpgDatabaseSizeMax, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetAttachDatabase2W(JET_SESID sesid, uint16* szFilename, uint32 cpgDatabaseSizeMax, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDetachDatabaseA(JET_SESID sesid, int8* szFilename);
	public static int32 JetDetachDatabase(JET_SESID sesid, int8* szFilename) => JetDetachDatabaseA(sesid, szFilename);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDetachDatabaseW(JET_SESID sesid, uint16* szFilename);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDetachDatabase2A(JET_SESID sesid, int8* szFilename, uint32 grbit);
	public static int32 JetDetachDatabase2(JET_SESID sesid, int8* szFilename, uint32 grbit) => JetDetachDatabase2A(sesid, szFilename, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDetachDatabase2W(JET_SESID sesid, uint16* szFilename, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetObjectInfoA(JET_SESID sesid, uint32 dbid, uint32 objtyp, int8* szContainerName, int8* szObjectName, void* pvResult, uint32 cbMax, uint32 InfoLevel);
	public static int32 JetGetObjectInfo(JET_SESID sesid, uint32 dbid, uint32 objtyp, int8* szContainerName, int8* szObjectName, void* pvResult, uint32 cbMax, uint32 InfoLevel) => JetGetObjectInfoA(sesid, dbid, objtyp, szContainerName, szObjectName, pvResult, cbMax, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetObjectInfoW(JET_SESID sesid, uint32 dbid, uint32 objtyp, uint16* szContainerName, uint16* szObjectName, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTableInfoA(JET_SESID sesid, JET_TABLEID tableid, void* pvResult, uint32 cbMax, uint32 InfoLevel);
	public static int32 JetGetTableInfo(JET_SESID sesid, JET_TABLEID tableid, void* pvResult, uint32 cbMax, uint32 InfoLevel) => JetGetTableInfoA(sesid, tableid, pvResult, cbMax, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTableInfoW(JET_SESID sesid, JET_TABLEID tableid, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableA(JET_SESID sesid, uint32 dbid, int8* szTableName, uint32 lPages, uint32 lDensity, JET_TABLEID* ptableid);
	public static int32 JetCreateTable(JET_SESID sesid, uint32 dbid, int8* szTableName, uint32 lPages, uint32 lDensity, JET_TABLEID* ptableid) => JetCreateTableA(sesid, dbid, szTableName, lPages, lDensity, ptableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableW(JET_SESID sesid, uint32 dbid, uint16* szTableName, uint32 lPages, uint32 lDensity, JET_TABLEID* ptableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndexA(JET_SESID sesid, uint32 dbid, JET_TABLECREATE_A* ptablecreate);
	public static int32 JetCreateTableColumnIndex(JET_SESID sesid, uint32 dbid, JET_TABLECREATE_A* ptablecreate) => JetCreateTableColumnIndexA(sesid, dbid, ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndexW(JET_SESID sesid, uint32 dbid, JET_TABLECREATE_W* ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndex2A(JET_SESID sesid, uint32 dbid, JET_TABLECREATE2_A* ptablecreate);
	public static int32 JetCreateTableColumnIndex2(JET_SESID sesid, uint32 dbid, JET_TABLECREATE2_A* ptablecreate) => JetCreateTableColumnIndex2A(sesid, dbid, ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndex2W(JET_SESID sesid, uint32 dbid, JET_TABLECREATE2_W* ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndex3A(JET_SESID sesid, uint32 dbid, JET_TABLECREATE3_A* ptablecreate);
	public static int32 JetCreateTableColumnIndex3(JET_SESID sesid, uint32 dbid, JET_TABLECREATE3_A* ptablecreate) => JetCreateTableColumnIndex3A(sesid, dbid, ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndex3W(JET_SESID sesid, uint32 dbid, JET_TABLECREATE3_W* ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndex4A(JET_SESID sesid, uint32 dbid, JET_TABLECREATE4_A* ptablecreate);
	public static int32 JetCreateTableColumnIndex4(JET_SESID sesid, uint32 dbid, JET_TABLECREATE4_A* ptablecreate) => JetCreateTableColumnIndex4A(sesid, dbid, ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateTableColumnIndex4W(JET_SESID sesid, uint32 dbid, JET_TABLECREATE4_W* ptablecreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteTableA(JET_SESID sesid, uint32 dbid, int8* szTableName);
	public static int32 JetDeleteTable(JET_SESID sesid, uint32 dbid, int8* szTableName) => JetDeleteTableA(sesid, dbid, szTableName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteTableW(JET_SESID sesid, uint32 dbid, uint16* szTableName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRenameTableA(JET_SESID sesid, uint32 dbid, int8* szName, int8* szNameNew);
	public static int32 JetRenameTable(JET_SESID sesid, uint32 dbid, int8* szName, int8* szNameNew) => JetRenameTableA(sesid, dbid, szName, szNameNew);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRenameTableW(JET_SESID sesid, uint32 dbid, uint16* szName, uint16* szNameNew);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTableColumnInfoA(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName, void* pvResult, uint32 cbMax, uint32 InfoLevel);
	public static int32 JetGetTableColumnInfo(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName, void* pvResult, uint32 cbMax, uint32 InfoLevel) => JetGetTableColumnInfoA(sesid, tableid, szColumnName, pvResult, cbMax, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTableColumnInfoW(JET_SESID sesid, JET_TABLEID tableid, uint16* szColumnName, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetColumnInfoA(JET_SESID sesid, uint32 dbid, int8* szTableName, int8* pColumnNameOrId, void* pvResult, uint32 cbMax, uint32 InfoLevel);
	public static int32 JetGetColumnInfo(JET_SESID sesid, uint32 dbid, int8* szTableName, int8* pColumnNameOrId, void* pvResult, uint32 cbMax, uint32 InfoLevel) => JetGetColumnInfoA(sesid, dbid, szTableName, pColumnNameOrId, pvResult, cbMax, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetColumnInfoW(JET_SESID sesid, uint32 dbid, uint16* szTableName, uint16* pwColumnNameOrId, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetAddColumnA(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName, JET_COLUMNDEF* pcolumndef, void* pvDefault, uint32 cbDefault, uint32* pcolumnid);
	public static int32 JetAddColumn(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName, JET_COLUMNDEF* pcolumndef, void* pvDefault, uint32 cbDefault, uint32* pcolumnid) => JetAddColumnA(sesid, tableid, szColumnName, pcolumndef, pvDefault, cbDefault, pcolumnid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetAddColumnW(JET_SESID sesid, JET_TABLEID tableid, uint16* szColumnName, JET_COLUMNDEF* pcolumndef, void* pvDefault, uint32 cbDefault, uint32* pcolumnid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteColumnA(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName);
	public static int32 JetDeleteColumn(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName) => JetDeleteColumnA(sesid, tableid, szColumnName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteColumnW(JET_SESID sesid, JET_TABLEID tableid, uint16* szColumnName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteColumn2A(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName, uint32 grbit);
	public static int32 JetDeleteColumn2(JET_SESID sesid, JET_TABLEID tableid, int8* szColumnName, uint32 grbit) => JetDeleteColumn2A(sesid, tableid, szColumnName, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteColumn2W(JET_SESID sesid, JET_TABLEID tableid, uint16* szColumnName, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRenameColumnA(JET_SESID sesid, JET_TABLEID tableid, int8* szName, int8* szNameNew, uint32 grbit);
	public static int32 JetRenameColumn(JET_SESID sesid, JET_TABLEID tableid, int8* szName, int8* szNameNew, uint32 grbit) => JetRenameColumnA(sesid, tableid, szName, szNameNew, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRenameColumnW(JET_SESID sesid, JET_TABLEID tableid, uint16* szName, uint16* szNameNew, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetColumnDefaultValueA(JET_SESID sesid, uint32 dbid, int8* szTableName, int8* szColumnName, void* pvData, uint32 cbData, uint32 grbit);
	public static int32 JetSetColumnDefaultValue(JET_SESID sesid, uint32 dbid, int8* szTableName, int8* szColumnName, void* pvData, uint32 cbData, uint32 grbit) => JetSetColumnDefaultValueA(sesid, dbid, szTableName, szColumnName, pvData, cbData, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetColumnDefaultValueW(JET_SESID sesid, uint32 dbid, uint16* szTableName, uint16* szColumnName, void* pvData, uint32 cbData, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTableIndexInfoA(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, void* pvResult, uint32 cbResult, uint32 InfoLevel);
	public static int32 JetGetTableIndexInfo(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, void* pvResult, uint32 cbResult, uint32 InfoLevel) => JetGetTableIndexInfoA(sesid, tableid, szIndexName, pvResult, cbResult, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTableIndexInfoW(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName, void* pvResult, uint32 cbResult, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetIndexInfoA(JET_SESID sesid, uint32 dbid, int8* szTableName, int8* szIndexName, void* pvResult, uint32 cbResult, uint32 InfoLevel);
	public static int32 JetGetIndexInfo(JET_SESID sesid, uint32 dbid, int8* szTableName, int8* szIndexName, void* pvResult, uint32 cbResult, uint32 InfoLevel) => JetGetIndexInfoA(sesid, dbid, szTableName, szIndexName, pvResult, cbResult, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetIndexInfoW(JET_SESID sesid, uint32 dbid, uint16* szTableName, uint16* szIndexName, void* pvResult, uint32 cbResult, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndexA(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 grbit, PSTR szKey, uint32 cbKey, uint32 lDensity);
	public static int32 JetCreateIndex(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 grbit, PSTR szKey, uint32 cbKey, uint32 lDensity) => JetCreateIndexA(sesid, tableid, szIndexName, grbit, szKey, cbKey, lDensity);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndexW(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName, uint32 grbit, PWSTR szKey, uint32 cbKey, uint32 lDensity);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndex2A(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE_A* pindexcreate, uint32 cIndexCreate);
	public static int32 JetCreateIndex2(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE_A* pindexcreate, uint32 cIndexCreate) => JetCreateIndex2A(sesid, tableid, pindexcreate, cIndexCreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndex2W(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE_W* pindexcreate, uint32 cIndexCreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndex3A(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE2_A* pindexcreate, uint32 cIndexCreate);
	public static int32 JetCreateIndex3(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE2_A* pindexcreate, uint32 cIndexCreate) => JetCreateIndex3A(sesid, tableid, pindexcreate, cIndexCreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndex3W(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE2_W* pindexcreate, uint32 cIndexCreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndex4A(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE3_A* pindexcreate, uint32 cIndexCreate);
	public static int32 JetCreateIndex4(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE3_A* pindexcreate, uint32 cIndexCreate) => JetCreateIndex4A(sesid, tableid, pindexcreate, cIndexCreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCreateIndex4W(JET_SESID sesid, JET_TABLEID tableid, JET_INDEXCREATE3_W* pindexcreate, uint32 cIndexCreate);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteIndexA(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName);
	public static int32 JetDeleteIndex(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName) => JetDeleteIndexA(sesid, tableid, szIndexName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDeleteIndexW(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginTransaction(JET_SESID sesid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginTransaction2(JET_SESID sesid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginTransaction3(JET_SESID sesid, int64 trxid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCommitTransaction(JET_SESID sesid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCommitTransaction2(JET_SESID sesid, uint32 grbit, uint32 cmsecDurableCommit, JET_COMMIT_ID* pCommitId);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRollback(JET_SESID sesid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetDatabaseInfoA(JET_SESID sesid, uint32 dbid, void* pvResult, uint32 cbMax, uint32 InfoLevel);
	public static int32 JetGetDatabaseInfo(JET_SESID sesid, uint32 dbid, void* pvResult, uint32 cbMax, uint32 InfoLevel) => JetGetDatabaseInfoA(sesid, dbid, pvResult, cbMax, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetDatabaseInfoW(JET_SESID sesid, uint32 dbid, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetDatabaseFileInfoA(int8* szDatabaseName, void* pvResult, uint32 cbMax, uint32 InfoLevel);
	public static int32 JetGetDatabaseFileInfo(int8* szDatabaseName, void* pvResult, uint32 cbMax, uint32 InfoLevel) => JetGetDatabaseFileInfoA(szDatabaseName, pvResult, cbMax, InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetDatabaseFileInfoW(uint16* szDatabaseName, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenDatabaseA(JET_SESID sesid, int8* szFilename, int8* szConnect, uint32* pdbid, uint32 grbit);
	public static int32 JetOpenDatabase(JET_SESID sesid, int8* szFilename, int8* szConnect, uint32* pdbid, uint32 grbit) => JetOpenDatabaseA(sesid, szFilename, szConnect, pdbid, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenDatabaseW(JET_SESID sesid, uint16* szFilename, uint16* szConnect, uint32* pdbid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCloseDatabase(JET_SESID sesid, uint32 dbid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTableA(JET_SESID sesid, uint32 dbid, int8* szTableName, void* pvParameters, uint32 cbParameters, uint32 grbit, JET_TABLEID* ptableid);
	public static int32 JetOpenTable(JET_SESID sesid, uint32 dbid, int8* szTableName, void* pvParameters, uint32 cbParameters, uint32 grbit, JET_TABLEID* ptableid) => JetOpenTableA(sesid, dbid, szTableName, pvParameters, cbParameters, grbit, ptableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTableW(JET_SESID sesid, uint32 dbid, uint16* szTableName, void* pvParameters, uint32 cbParameters, uint32 grbit, JET_TABLEID* ptableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetTableSequential(JET_SESID sesid, JET_TABLEID tableid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetResetTableSequential(JET_SESID sesid, JET_TABLEID tableid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCloseTable(JET_SESID sesid, JET_TABLEID tableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDelete(JET_SESID sesid, JET_TABLEID tableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetUpdate(JET_SESID sesid, JET_TABLEID tableid, void* pvBookmark, uint32 cbBookmark, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetUpdate2(JET_SESID sesid, JET_TABLEID tableid, void* pvBookmark, uint32 cbBookmark, uint32* pcbActual, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEscrowUpdate(JET_SESID sesid, JET_TABLEID tableid, uint32 columnid, void* pv, uint32 cbMax, void* pvOld, uint32 cbOldMax, uint32* pcbOldActual, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRetrieveColumn(JET_SESID sesid, JET_TABLEID tableid, uint32 columnid, void* pvData, uint32 cbData, uint32* pcbActual, uint32 grbit, JET_RETINFO* pretinfo);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRetrieveColumns(JET_SESID sesid, JET_TABLEID tableid, JET_RETRIEVECOLUMN* pretrievecolumn, uint32 cretrievecolumn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEnumerateColumns(JET_SESID sesid, JET_TABLEID tableid, uint32 cEnumColumnId, JET_ENUMCOLUMNID* rgEnumColumnId, uint32* pcEnumColumn, JET_ENUMCOLUMN** prgEnumColumn, JET_PFNREALLOC pfnRealloc, void* pvReallocContext, uint32 cbDataMost, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetRecordSize(JET_SESID sesid, JET_TABLEID tableid, JET_RECSIZE* precsize, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetRecordSize2(JET_SESID sesid, JET_TABLEID tableid, JET_RECSIZE2* precsize, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetColumn(JET_SESID sesid, JET_TABLEID tableid, uint32 columnid, void* pvData, uint32 cbData, uint32 grbit, JET_SETINFO* psetinfo);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetColumns(JET_SESID sesid, JET_TABLEID tableid, JET_SETCOLUMN* psetcolumn, uint32 csetcolumn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetPrepareUpdate(JET_SESID sesid, JET_TABLEID tableid, uint32 prep);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetRecordPosition(JET_SESID sesid, JET_TABLEID tableid, JET_RECPOS* precpos, uint32 cbRecpos);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGotoPosition(JET_SESID sesid, JET_TABLEID tableid, JET_RECPOS* precpos);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetCursorInfo(JET_SESID sesid, JET_TABLEID tableid, void* pvResult, uint32 cbMax, uint32 InfoLevel);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDupCursor(JET_SESID sesid, JET_TABLEID tableid, JET_TABLEID* ptableid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetCurrentIndexA(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 cbIndexName);
	public static int32 JetGetCurrentIndex(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 cbIndexName) => JetGetCurrentIndexA(sesid, tableid, szIndexName, cbIndexName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetCurrentIndexW(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName, uint32 cbIndexName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndexA(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName);
	public static int32 JetSetCurrentIndex(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName) => JetSetCurrentIndexA(sesid, tableid, szIndexName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndexW(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndex2A(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 grbit);
	public static int32 JetSetCurrentIndex2(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 grbit) => JetSetCurrentIndex2A(sesid, tableid, szIndexName, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndex2W(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndex3A(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 grbit, uint32 itagSequence);
	public static int32 JetSetCurrentIndex3(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, uint32 grbit, uint32 itagSequence) => JetSetCurrentIndex3A(sesid, tableid, szIndexName, grbit, itagSequence);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndex3W(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName, uint32 grbit, uint32 itagSequence);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndex4A(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, JET_INDEXID* pindexid, uint32 grbit, uint32 itagSequence);
	public static int32 JetSetCurrentIndex4(JET_SESID sesid, JET_TABLEID tableid, int8* szIndexName, JET_INDEXID* pindexid, uint32 grbit, uint32 itagSequence) => JetSetCurrentIndex4A(sesid, tableid, szIndexName, pindexid, grbit, itagSequence);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCurrentIndex4W(JET_SESID sesid, JET_TABLEID tableid, uint16* szIndexName, JET_INDEXID* pindexid, uint32 grbit, uint32 itagSequence);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetMove(JET_SESID sesid, JET_TABLEID tableid, int32 cRow, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetCursorFilter(JET_SESID sesid, JET_TABLEID tableid, JET_INDEX_COLUMN* rgColumnFilters, uint32 cColumnFilters, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLock(JET_SESID sesid, JET_TABLEID tableid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetMakeKey(JET_SESID sesid, JET_TABLEID tableid, void* pvData, uint32 cbData, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSeek(JET_SESID sesid, JET_TABLEID tableid, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetPrereadKeys(JET_SESID sesid, JET_TABLEID tableid, void** rgpvKeys, uint32* rgcbKeys, int32 ckeys, int32* pckeysPreread, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetPrereadIndexRanges(JET_SESID sesid, JET_TABLEID tableid, JET_INDEX_RANGE* rgIndexRanges, uint32 cIndexRanges, uint32* pcRangesPreread, uint32* rgcolumnidPreread, uint32 ccolumnidPreread, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetBookmark(JET_SESID sesid, JET_TABLEID tableid, void* pvBookmark, uint32 cbMax, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetSecondaryIndexBookmark(JET_SESID sesid, JET_TABLEID tableid, void* pvSecondaryKey, uint32 cbSecondaryKeyMax, uint32* pcbSecondaryKeyActual, void* pvPrimaryBookmark, uint32 cbPrimaryBookmarkMax, uint32* pcbPrimaryBookmarkActual, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCompactA(JET_SESID sesid, int8* szDatabaseSrc, int8* szDatabaseDest, JET_PFNSTATUS pfnStatus, JET_CONVERT_A* pconvert, uint32 grbit);
	public static int32 JetCompact(JET_SESID sesid, int8* szDatabaseSrc, int8* szDatabaseDest, JET_PFNSTATUS pfnStatus, JET_CONVERT_A* pconvert, uint32 grbit) => JetCompactA(sesid, szDatabaseSrc, szDatabaseDest, pfnStatus, pconvert, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCompactW(JET_SESID sesid, uint16* szDatabaseSrc, uint16* szDatabaseDest, JET_PFNSTATUS pfnStatus, JET_CONVERT_W* pconvert, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDefragmentA(JET_SESID sesid, uint32 dbid, int8* szTableName, uint32* pcPasses, uint32* pcSeconds, uint32 grbit);
	public static int32 JetDefragment(JET_SESID sesid, uint32 dbid, int8* szTableName, uint32* pcPasses, uint32* pcSeconds, uint32 grbit) => JetDefragmentA(sesid, dbid, szTableName, pcPasses, pcSeconds, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDefragmentW(JET_SESID sesid, uint32 dbid, uint16* szTableName, uint32* pcPasses, uint32* pcSeconds, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDefragment2A(JET_SESID sesid, uint32 dbid, int8* szTableName, uint32* pcPasses, uint32* pcSeconds, JET_CALLBACK callback, uint32 grbit);
	public static int32 JetDefragment2(JET_SESID sesid, uint32 dbid, int8* szTableName, uint32* pcPasses, uint32* pcSeconds, JET_CALLBACK callback, uint32 grbit) => JetDefragment2A(sesid, dbid, szTableName, pcPasses, pcSeconds, callback, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDefragment2W(JET_SESID sesid, uint32 dbid, uint16* szTableName, uint32* pcPasses, uint32* pcSeconds, JET_CALLBACK callback, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDefragment3A(JET_SESID sesid, int8* szDatabaseName, int8* szTableName, uint32* pcPasses, uint32* pcSeconds, JET_CALLBACK callback, void* pvContext, uint32 grbit);
	public static int32 JetDefragment3(JET_SESID sesid, int8* szDatabaseName, int8* szTableName, uint32* pcPasses, uint32* pcSeconds, JET_CALLBACK callback, void* pvContext, uint32 grbit) => JetDefragment3A(sesid, szDatabaseName, szTableName, pcPasses, pcSeconds, callback, pvContext, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetDefragment3W(JET_SESID sesid, uint16* szDatabaseName, uint16* szTableName, uint32* pcPasses, uint32* pcSeconds, JET_CALLBACK callback, void* pvContext, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetDatabaseSizeA(JET_SESID sesid, int8* szDatabaseName, uint32 cpg, uint32* pcpgReal);
	public static int32 JetSetDatabaseSize(JET_SESID sesid, int8* szDatabaseName, uint32 cpg, uint32* pcpgReal) => JetSetDatabaseSizeA(sesid, szDatabaseName, cpg, pcpgReal);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetDatabaseSizeW(JET_SESID sesid, uint16* szDatabaseName, uint32 cpg, uint32* pcpgReal);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGrowDatabase(JET_SESID sesid, uint32 dbid, uint32 cpg, uint32* pcpgReal);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetResizeDatabase(JET_SESID sesid, uint32 dbid, uint32 cpgTarget, uint32* pcpgActual, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetSessionContext(JET_SESID sesid, JET_API_PTR ulContext);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetResetSessionContext(JET_SESID sesid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGotoBookmark(JET_SESID sesid, JET_TABLEID tableid, void* pvBookmark, uint32 cbBookmark);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGotoSecondaryIndexBookmark(JET_SESID sesid, JET_TABLEID tableid, void* pvSecondaryKey, uint32 cbSecondaryKey, void* pvPrimaryBookmark, uint32 cbPrimaryBookmark, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetIntersectIndexes(JET_SESID sesid, JET_INDEXRANGE* rgindexrange, uint32 cindexrange, JET_RECORDLIST* precordlist, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetComputeStats(JET_SESID sesid, JET_TABLEID tableid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTempTable(JET_SESID sesid, JET_COLUMNDEF* prgcolumndef, uint32 ccolumn, uint32 grbit, JET_TABLEID* ptableid, uint32* prgcolumnid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTempTable2(JET_SESID sesid, JET_COLUMNDEF* prgcolumndef, uint32 ccolumn, uint32 lcid, uint32 grbit, JET_TABLEID* ptableid, uint32* prgcolumnid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTempTable3(JET_SESID sesid, JET_COLUMNDEF* prgcolumndef, uint32 ccolumn, JET_UNICODEINDEX* pidxunicode, uint32 grbit, JET_TABLEID* ptableid, uint32* prgcolumnid);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTemporaryTable(JET_SESID sesid, JET_OPENTEMPORARYTABLE* popentemporarytable);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenTemporaryTable2(JET_SESID sesid, JET_OPENTEMPORARYTABLE2* popentemporarytable);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBackupA(int8* szBackupPath, uint32 grbit, JET_PFNSTATUS pfnStatus);
	public static int32 JetBackup(int8* szBackupPath, uint32 grbit, JET_PFNSTATUS pfnStatus) => JetBackupA(szBackupPath, grbit, pfnStatus);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBackupW(uint16* szBackupPath, uint32 grbit, JET_PFNSTATUS pfnStatus);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBackupInstanceA(JET_INSTANCE instance, int8* szBackupPath, uint32 grbit, JET_PFNSTATUS pfnStatus);
	public static int32 JetBackupInstance(JET_INSTANCE instance, int8* szBackupPath, uint32 grbit, JET_PFNSTATUS pfnStatus) => JetBackupInstanceA(instance, szBackupPath, grbit, pfnStatus);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBackupInstanceW(JET_INSTANCE instance, uint16* szBackupPath, uint32 grbit, JET_PFNSTATUS pfnStatus);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRestoreA(int8* szSource, JET_PFNSTATUS pfn);
	public static int32 JetRestore(int8* szSource, JET_PFNSTATUS pfn) => JetRestoreA(szSource, pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRestoreW(uint16* szSource, JET_PFNSTATUS pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRestore2A(int8* sz, int8* szDest, JET_PFNSTATUS pfn);
	public static int32 JetRestore2(int8* sz, int8* szDest, JET_PFNSTATUS pfn) => JetRestore2A(sz, szDest, pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRestore2W(uint16* sz, uint16* szDest, JET_PFNSTATUS pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRestoreInstanceA(JET_INSTANCE instance, int8* sz, int8* szDest, JET_PFNSTATUS pfn);
	public static int32 JetRestoreInstance(JET_INSTANCE instance, int8* sz, int8* szDest, JET_PFNSTATUS pfn) => JetRestoreInstanceA(instance, sz, szDest, pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRestoreInstanceW(JET_INSTANCE instance, uint16* sz, uint16* szDest, JET_PFNSTATUS pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetIndexRange(JET_SESID sesid, JET_TABLEID tableidSrc, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetIndexRecordCount(JET_SESID sesid, JET_TABLEID tableid, uint32* pcrec, uint32 crecMax);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRetrieveKey(JET_SESID sesid, JET_TABLEID tableid, void* pvKey, uint32 cbMax, uint32* pcbActual, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginExternalBackup(uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetBeginExternalBackupInstance(JET_INSTANCE instance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetAttachInfoA(int8* szzDatabases, uint32 cbMax, uint32* pcbActual);
	public static int32 JetGetAttachInfo(int8* szzDatabases, uint32 cbMax, uint32* pcbActual) => JetGetAttachInfoA(szzDatabases, cbMax, pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetAttachInfoW(uint16* wszzDatabases, uint32 cbMax, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetAttachInfoInstanceA(JET_INSTANCE instance, int8* szzDatabases, uint32 cbMax, uint32* pcbActual);
	public static int32 JetGetAttachInfoInstance(JET_INSTANCE instance, int8* szzDatabases, uint32 cbMax, uint32* pcbActual) => JetGetAttachInfoInstanceA(instance, szzDatabases, cbMax, pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetAttachInfoInstanceW(JET_INSTANCE instance, uint16* szzDatabases, uint32 cbMax, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenFileA(int8* szFileName, JET_HANDLE* phfFile, uint32* pulFileSizeLow, uint32* pulFileSizeHigh);
	public static int32 JetOpenFile(int8* szFileName, JET_HANDLE* phfFile, uint32* pulFileSizeLow, uint32* pulFileSizeHigh) => JetOpenFileA(szFileName, phfFile, pulFileSizeLow, pulFileSizeHigh);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenFileW(uint16* szFileName, JET_HANDLE* phfFile, uint32* pulFileSizeLow, uint32* pulFileSizeHigh);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenFileInstanceA(JET_INSTANCE instance, int8* szFileName, JET_HANDLE* phfFile, uint32* pulFileSizeLow, uint32* pulFileSizeHigh);
	public static int32 JetOpenFileInstance(JET_INSTANCE instance, int8* szFileName, JET_HANDLE* phfFile, uint32* pulFileSizeLow, uint32* pulFileSizeHigh) => JetOpenFileInstanceA(instance, szFileName, phfFile, pulFileSizeLow, pulFileSizeHigh);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOpenFileInstanceW(JET_INSTANCE instance, uint16* szFileName, JET_HANDLE* phfFile, uint32* pulFileSizeLow, uint32* pulFileSizeHigh);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetReadFile(JET_HANDLE hfFile, void* pv, uint32 cb, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetReadFileInstance(JET_INSTANCE instance, JET_HANDLE hfFile, void* pv, uint32 cb, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCloseFile(JET_HANDLE hfFile);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetCloseFileInstance(JET_INSTANCE instance, JET_HANDLE hfFile);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLogInfoA(int8* szzLogs, uint32 cbMax, uint32* pcbActual);
	public static int32 JetGetLogInfo(int8* szzLogs, uint32 cbMax, uint32* pcbActual) => JetGetLogInfoA(szzLogs, cbMax, pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLogInfoW(uint16* szzLogs, uint32 cbMax, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLogInfoInstanceA(JET_INSTANCE instance, int8* szzLogs, uint32 cbMax, uint32* pcbActual);
	public static int32 JetGetLogInfoInstance(JET_INSTANCE instance, int8* szzLogs, uint32 cbMax, uint32* pcbActual) => JetGetLogInfoInstanceA(instance, szzLogs, cbMax, pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLogInfoInstanceW(JET_INSTANCE instance, uint16* wszzLogs, uint32 cbMax, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLogInfoInstance2A(JET_INSTANCE instance, int8* szzLogs, uint32 cbMax, uint32* pcbActual, JET_LOGINFO_A* pLogInfo);
	public static int32 JetGetLogInfoInstance2(JET_INSTANCE instance, int8* szzLogs, uint32 cbMax, uint32* pcbActual, JET_LOGINFO_A* pLogInfo) => JetGetLogInfoInstance2A(instance, szzLogs, cbMax, pcbActual, pLogInfo);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLogInfoInstance2W(JET_INSTANCE instance, uint16* wszzLogs, uint32 cbMax, uint32* pcbActual, JET_LOGINFO_W* pLogInfo);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTruncateLogInfoInstanceA(JET_INSTANCE instance, int8* szzLogs, uint32 cbMax, uint32* pcbActual);
	public static int32 JetGetTruncateLogInfoInstance(JET_INSTANCE instance, int8* szzLogs, uint32 cbMax, uint32* pcbActual) => JetGetTruncateLogInfoInstanceA(instance, szzLogs, cbMax, pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetTruncateLogInfoInstanceW(JET_INSTANCE instance, uint16* wszzLogs, uint32 cbMax, uint32* pcbActual);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetTruncateLog();

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetTruncateLogInstance(JET_INSTANCE instance);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEndExternalBackup();

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEndExternalBackupInstance(JET_INSTANCE instance);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetEndExternalBackupInstance2(JET_INSTANCE instance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetExternalRestoreA(int8* szCheckpointFilePath, int8* szLogPath, JET_RSTMAP_A* rgrstmap, int32 crstfilemap, int8* szBackupLogPath, int32 genLow, int32 genHigh, JET_PFNSTATUS pfn);
	public static int32 JetExternalRestore(int8* szCheckpointFilePath, int8* szLogPath, JET_RSTMAP_A* rgrstmap, int32 crstfilemap, int8* szBackupLogPath, int32 genLow, int32 genHigh, JET_PFNSTATUS pfn) => JetExternalRestoreA(szCheckpointFilePath, szLogPath, rgrstmap, crstfilemap, szBackupLogPath, genLow, genHigh, pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetExternalRestoreW(uint16* szCheckpointFilePath, uint16* szLogPath, JET_RSTMAP_W* rgrstmap, int32 crstfilemap, uint16* szBackupLogPath, int32 genLow, int32 genHigh, JET_PFNSTATUS pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetExternalRestore2A(int8* szCheckpointFilePath, int8* szLogPath, JET_RSTMAP_A* rgrstmap, int32 crstfilemap, int8* szBackupLogPath, JET_LOGINFO_A* pLogInfo, int8* szTargetInstanceName, int8* szTargetInstanceLogPath, int8* szTargetInstanceCheckpointPath, JET_PFNSTATUS pfn);
	public static int32 JetExternalRestore2(int8* szCheckpointFilePath, int8* szLogPath, JET_RSTMAP_A* rgrstmap, int32 crstfilemap, int8* szBackupLogPath, JET_LOGINFO_A* pLogInfo, int8* szTargetInstanceName, int8* szTargetInstanceLogPath, int8* szTargetInstanceCheckpointPath, JET_PFNSTATUS pfn) => JetExternalRestore2A(szCheckpointFilePath, szLogPath, rgrstmap, crstfilemap, szBackupLogPath, pLogInfo, szTargetInstanceName, szTargetInstanceLogPath, szTargetInstanceCheckpointPath, pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetExternalRestore2W(uint16* szCheckpointFilePath, uint16* szLogPath, JET_RSTMAP_W* rgrstmap, int32 crstfilemap, uint16* szBackupLogPath, JET_LOGINFO_W* pLogInfo, uint16* szTargetInstanceName, uint16* szTargetInstanceLogPath, uint16* szTargetInstanceCheckpointPath, JET_PFNSTATUS pfn);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetRegisterCallback(JET_SESID sesid, JET_TABLEID tableid, uint32 cbtyp, JET_CALLBACK pCallback, void* pvContext, JET_HANDLE* phCallbackId);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetUnregisterCallback(JET_SESID sesid, JET_TABLEID tableid, uint32 cbtyp, JET_HANDLE hCallbackId);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetInstanceInfoA(uint32* pcInstanceInfo, JET_INSTANCE_INFO_A** paInstanceInfo);
	public static int32 JetGetInstanceInfo(uint32* pcInstanceInfo, JET_INSTANCE_INFO_A** paInstanceInfo) => JetGetInstanceInfoA(pcInstanceInfo, paInstanceInfo);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetInstanceInfoW(uint32* pcInstanceInfo, JET_INSTANCE_INFO_W** paInstanceInfo);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetFreeBuffer(PSTR pbBuf);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetLS(JET_SESID sesid, JET_TABLEID tableid, JET_LS ls, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetLS(JET_SESID sesid, JET_TABLEID tableid, JET_LS* pls, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotPrepare(JET_OSSNAPID* psnapId, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotPrepareInstance(JET_OSSNAPID snapId, JET_INSTANCE instance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotFreezeA(JET_OSSNAPID snapId, uint32* pcInstanceInfo, JET_INSTANCE_INFO_A** paInstanceInfo, uint32 grbit);
	public static int32 JetOSSnapshotFreeze(JET_OSSNAPID snapId, uint32* pcInstanceInfo, JET_INSTANCE_INFO_A** paInstanceInfo, uint32 grbit) => JetOSSnapshotFreezeA(snapId, pcInstanceInfo, paInstanceInfo, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotFreezeW(JET_OSSNAPID snapId, uint32* pcInstanceInfo, JET_INSTANCE_INFO_W** paInstanceInfo, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotThaw(JET_OSSNAPID snapId, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotAbort(JET_OSSNAPID snapId, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotTruncateLog(JET_OSSNAPID snapId, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotTruncateLogInstance(JET_OSSNAPID snapId, JET_INSTANCE instance, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotGetFreezeInfoA(JET_OSSNAPID snapId, uint32* pcInstanceInfo, JET_INSTANCE_INFO_A** paInstanceInfo, uint32 grbit);
	public static int32 JetOSSnapshotGetFreezeInfo(JET_OSSNAPID snapId, uint32* pcInstanceInfo, JET_INSTANCE_INFO_A** paInstanceInfo, uint32 grbit) => JetOSSnapshotGetFreezeInfoA(snapId, pcInstanceInfo, paInstanceInfo, grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotGetFreezeInfoW(JET_OSSNAPID snapId, uint32* pcInstanceInfo, JET_INSTANCE_INFO_W** paInstanceInfo, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetOSSnapshotEnd(JET_OSSNAPID snapId, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetConfigureProcessForCrashDump(uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetErrorInfoW(void* pvContext, void* pvResult, uint32 cbMax, uint32 InfoLevel, uint32 grbit);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetSetSessionParameter(JET_SESID sesid, uint32 sesparamid, void* pvParam, uint32 cbParam);

	[Import("ESENT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 JetGetSessionParameter(JET_SESID sesid, uint32 sesparamid, void* pvParam, uint32 cbParamMax, uint32* pcbParamActual);

}
#endregion
