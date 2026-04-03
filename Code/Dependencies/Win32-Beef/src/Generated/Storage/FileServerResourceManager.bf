using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.Storage.FileServerResourceManager;

#region Constants
public static
{
	public const uint32 FSRM_DISPID_FEATURE_MASK = 251658240;
	public const uint32 FSRM_DISPID_INTERFACE_A_MASK = 15728640;
	public const uint32 FSRM_DISPID_INTERFACE_B_MASK = 983040;
	public const uint32 FSRM_DISPID_INTERFACE_C_MASK = 61440;
	public const uint32 FSRM_DISPID_INTERFACE_D_MASK = 3840;
	public const uint32 FSRM_DISPID_IS_PROPERTY = 128;
	public const uint32 FSRM_DISPID_METHOD_NUM_MASK = 127;
	public const uint32 FSRM_DISPID_FEATURE_GENERAL = 16777216;
	public const uint32 FSRM_DISPID_FEATURE_QUOTA = 33554432;
	public const uint32 FSRM_DISPID_FEATURE_FILESCREEN = 50331648;
	public const uint32 FSRM_DISPID_FEATURE_REPORTS = 67108864;
	public const uint32 FSRM_DISPID_FEATURE_CLASSIFICATION = 83886080;
	public const uint32 FSRM_DISPID_FEATURE_PIPELINE = 100663296;
	public const uint32 FsrmMaxNumberThresholds = 16;
	public const uint32 FsrmMinThresholdValue = 1;
	public const uint32 FsrmMaxThresholdValue = 250;
	public const uint32 FsrmMinQuotaLimit = 1024;
	public const uint32 FsrmMaxExcludeFolders = 32;
	public const uint32 FsrmMaxNumberPropertyDefinitions = 100;
	public const uint32 MessageSizeLimit = 4096;
	public const int32 FsrmDaysNotSpecified = -1;
	public const HRESULT FSRM_S_PARTIAL_BATCH = 283396;
	public const HRESULT FSRM_S_PARTIAL_CLASSIFICATION = 283397;
	public const HRESULT FSRM_S_CLASSIFICATION_SCAN_FAILURES = 283398;
	public const HRESULT FSRM_E_NOT_FOUND = -2147200255;
	public const HRESULT FSRM_E_INVALID_SCHEDULER_ARGUMENT = -2147200254;
	public const HRESULT FSRM_E_ALREADY_EXISTS = -2147200253;
	public const HRESULT FSRM_E_PATH_NOT_FOUND = -2147200252;
	public const HRESULT FSRM_E_INVALID_USER = -2147200251;
	public const HRESULT FSRM_E_INVALID_PATH = -2147200250;
	public const HRESULT FSRM_E_INVALID_LIMIT = -2147200249;
	public const HRESULT FSRM_E_INVALID_NAME = -2147200248;
	public const HRESULT FSRM_E_FAIL_BATCH = -2147200247;
	public const HRESULT FSRM_E_INVALID_TEXT = -2147200246;
	public const HRESULT FSRM_E_INVALID_IMPORT_VERSION = -2147200245;
	public const HRESULT FSRM_E_OUT_OF_RANGE = -2147200243;
	public const HRESULT FSRM_E_REQD_PARAM_MISSING = -2147200242;
	public const HRESULT FSRM_E_INVALID_COMBINATION = -2147200241;
	public const HRESULT FSRM_E_DUPLICATE_NAME = -2147200240;
	public const HRESULT FSRM_E_NOT_SUPPORTED = -2147200239;
	public const HRESULT FSRM_E_DRIVER_NOT_READY = -2147200237;
	public const HRESULT FSRM_E_INSUFFICIENT_DISK = -2147200236;
	public const HRESULT FSRM_E_VOLUME_UNSUPPORTED = -2147200235;
	public const HRESULT FSRM_E_UNEXPECTED = -2147200234;
	public const HRESULT FSRM_E_INSECURE_PATH = -2147200233;
	public const HRESULT FSRM_E_INVALID_SMTP_SERVER = -2147200232;
	public const HRESULT FSRM_E_AUTO_QUOTA = 283419;
	public const HRESULT FSRM_E_EMAIL_NOT_SENT = -2147200228;
	public const HRESULT FSRM_E_INVALID_EMAIL_ADDRESS = -2147200226;
	public const HRESULT FSRM_E_FILE_SYSTEM_CORRUPT = -2147200225;
	public const HRESULT FSRM_E_LONG_CMDLINE = -2147200224;
	public const HRESULT FSRM_E_INVALID_FILEGROUP_DEFINITION = -2147200223;
	public const HRESULT FSRM_E_INVALID_DATASCREEN_DEFINITION = -2147200220;
	public const HRESULT FSRM_E_INVALID_REPORT_FORMAT = -2147200216;
	public const HRESULT FSRM_E_INVALID_REPORT_DESC = -2147200215;
	public const HRESULT FSRM_E_INVALID_FILENAME = -2147200214;
	public const HRESULT FSRM_E_SHADOW_COPY = -2147200212;
	public const HRESULT FSRM_E_XML_CORRUPTED = -2147200211;
	public const HRESULT FSRM_E_CLUSTER_NOT_RUNNING = -2147200210;
	public const HRESULT FSRM_E_STORE_NOT_INSTALLED = -2147200209;
	public const HRESULT FSRM_E_NOT_CLUSTER_VOLUME = -2147200208;
	public const HRESULT FSRM_E_DIFFERENT_CLUSTER_GROUP = -2147200207;
	public const HRESULT FSRM_E_REPORT_TYPE_ALREADY_EXISTS = -2147200206;
	public const HRESULT FSRM_E_REPORT_JOB_ALREADY_RUNNING = -2147200205;
	public const HRESULT FSRM_E_REPORT_GENERATION_ERR = -2147200204;
	public const HRESULT FSRM_E_REPORT_TASK_TRIGGER = -2147200203;
	public const HRESULT FSRM_E_LOADING_DISABLED_MODULE = -2147200202;
	public const HRESULT FSRM_E_CANNOT_AGGREGATE = -2147200201;
	public const HRESULT FSRM_E_MESSAGE_LIMIT_EXCEEDED = -2147200200;
	public const HRESULT FSRM_E_OBJECT_IN_USE = -2147200199;
	public const HRESULT FSRM_E_CANNOT_RENAME_PROPERTY = -2147200198;
	public const HRESULT FSRM_E_CANNOT_CHANGE_PROPERTY_TYPE = -2147200197;
	public const HRESULT FSRM_E_MAX_PROPERTY_DEFINITIONS = -2147200196;
	public const HRESULT FSRM_E_CLASSIFICATION_ALREADY_RUNNING = -2147200195;
	public const HRESULT FSRM_E_CLASSIFICATION_NOT_RUNNING = -2147200194;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_ALREADY_RUNNING = -2147200193;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_EXPIRATION = -2147200192;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_CUSTOM = -2147200191;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_NOTIFICATION = -2147200190;
	public const HRESULT FSRM_E_FILE_OPEN_ERROR = -2147200189;
	public const HRESULT FSRM_E_UNSECURE_LINK_TO_HOSTED_MODULE = -2147200188;
	public const HRESULT FSRM_E_CACHE_INVALID = -2147200187;
	public const HRESULT FSRM_E_CACHE_MODULE_ALREADY_EXISTS = -2147200186;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_EXPIRATION_DIR_IN_SCOPE = -2147200185;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_ALREADY_EXISTS = -2147200184;
	public const HRESULT FSRM_E_PROPERTY_DELETED = -2147200183;
	public const HRESULT FSRM_E_LAST_ACCESS_UPDATE_DISABLED = -2147200176;
	public const HRESULT FSRM_E_NO_PROPERTY_VALUE = -2147200175;
	public const HRESULT FSRM_E_INPROC_MODULE_BLOCKED = -2147200174;
	public const HRESULT FSRM_E_ENUM_PROPERTIES_FAILED = -2147200173;
	public const HRESULT FSRM_E_SET_PROPERTY_FAILED = -2147200172;
	public const HRESULT FSRM_E_CANNOT_STORE_PROPERTIES = -2147200171;
	public const HRESULT FSRM_E_CANNOT_ALLOW_REPARSE_POINT_TAG = -2147200170;
	public const HRESULT FSRM_E_PARTIAL_CLASSIFICATION_PROPERTY_NOT_FOUND = -2147200169;
	public const HRESULT FSRM_E_TEXTREADER_NOT_INITIALIZED = -2147200168;
	public const HRESULT FSRM_E_TEXTREADER_IFILTER_NOT_FOUND = -2147200167;
	public const HRESULT FSRM_E_PERSIST_PROPERTIES_FAILED_ENCRYPTED = -2147200166;
	public const HRESULT FSRM_E_TEXTREADER_IFILTER_CLSID_MALFORMED = -2147200160;
	public const HRESULT FSRM_E_TEXTREADER_STREAM_ERROR = -2147200159;
	public const HRESULT FSRM_E_TEXTREADER_FILENAME_TOO_LONG = -2147200158;
	public const HRESULT FSRM_E_INCOMPATIBLE_FORMAT = -2147200157;
	public const HRESULT FSRM_E_FILE_ENCRYPTED = -2147200156;
	public const HRESULT FSRM_E_PERSIST_PROPERTIES_FAILED = -2147200155;
	public const HRESULT FSRM_E_VOLUME_OFFLINE = -2147200154;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_ACTION_TIMEOUT = -2147200153;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_ACTION_GET_EXITCODE_FAILED = -2147200152;
	public const HRESULT FSRM_E_MODULE_INVALID_PARAM = -2147200151;
	public const HRESULT FSRM_E_MODULE_INITIALIZATION = -2147200150;
	public const HRESULT FSRM_E_MODULE_SESSION_INITIALIZATION = -2147200149;
	public const HRESULT FSRM_E_CLASSIFICATION_SCAN_FAIL = -2147200148;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_NOT_LEGACY_ACCESSIBLE = -2147200147;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_MAX_FILE_CONDITIONS = -2147200146;
	public const HRESULT FSRM_E_CANNOT_USE_DEPRECATED_PROPERTY = -2147200145;
	public const HRESULT FSRM_E_SYNC_TASK_TIMEOUT = -2147200144;
	public const HRESULT FSRM_E_CANNOT_USE_DELETED_PROPERTY = -2147200143;
	public const HRESULT FSRM_E_INVALID_AD_CLAIM = -2147200142;
	public const HRESULT FSRM_E_CLASSIFICATION_CANCELED = -2147200141;
	public const HRESULT FSRM_E_INVALID_FOLDER_PROPERTY_STORE = -2147200140;
	public const HRESULT FSRM_E_REBUILDING_FODLER_TYPE_INDEX = -2147200139;
	public const HRESULT FSRM_E_PROPERTY_MUST_APPLY_TO_FILES = -2147200138;
	public const HRESULT FSRM_E_CLASSIFICATION_TIMEOUT = -2147200137;
	public const HRESULT FSRM_E_CLASSIFICATION_PARTIAL_BATCH = -2147200136;
	public const HRESULT FSRM_E_CANNOT_DELETE_SYSTEM_PROPERTY = -2147200135;
	public const HRESULT FSRM_E_FILE_IN_USE = -2147200134;
	public const HRESULT FSRM_E_ERROR_NOT_ENABLED = -2147200133;
	public const HRESULT FSRM_E_CANNOT_CREATE_TEMP_COPY = -2147200132;
	public const HRESULT FSRM_E_NO_EMAIL_ADDRESS = -2147200131;
	public const HRESULT FSRM_E_ADR_MAX_EMAILS_SENT = -2147200130;
	public const HRESULT FSRM_E_PATH_NOT_IN_NAMESPACE = -2147200129;
	public const HRESULT FSRM_E_RMS_TEMPLATE_NOT_FOUND = -2147200128;
	public const HRESULT FSRM_E_SECURE_PROPERTIES_NOT_SUPPORTED = -2147200127;
	public const HRESULT FSRM_E_RMS_NO_PROTECTORS_INSTALLED = -2147200126;
	public const HRESULT FSRM_E_RMS_NO_PROTECTOR_INSTALLED_FOR_FILE = -2147200125;
	public const HRESULT FSRM_E_PROPERTY_MUST_APPLY_TO_FOLDERS = -2147200124;
	public const HRESULT FSRM_E_PROPERTY_MUST_BE_SECURE = -2147200123;
	public const HRESULT FSRM_E_PROPERTY_MUST_BE_GLOBAL = -2147200122;
	public const HRESULT FSRM_E_WMI_FAILURE = -2147200121;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_RMS = -2147200120;
	public const HRESULT FSRM_E_SYNC_TASK_HAD_ERRORS = -2147200119;
	public const HRESULT FSRM_E_ADR_SRV_NOT_SUPPORTED = -2147200112;
	public const HRESULT FSRM_E_ADR_PATH_IS_LOCAL = -2147200111;
	public const HRESULT FSRM_E_ADR_NOT_DOMAIN_JOINED = -2147200110;
	public const HRESULT FSRM_E_CANNOT_REMOVE_READONLY = -2147200109;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_INVALID_CONTINUOUS_CONFIG = -2147200108;
	public const HRESULT FSRM_E_LEGACY_SCHEDULE = -2147200107;
	public const HRESULT FSRM_E_CSC_PATH_NOT_SUPPORTED = -2147200106;
	public const HRESULT FSRM_E_EXPIRATION_PATH_NOT_WRITEABLE = -2147200105;
	public const HRESULT FSRM_E_EXPIRATION_PATH_TOO_LONG = -2147200104;
	public const HRESULT FSRM_E_EXPIRATION_VOLUME_NOT_NTFS = -2147200103;
	public const HRESULT FSRM_E_FILE_MANAGEMENT_JOB_DEPRECATED = -2147200102;
	public const HRESULT FSRM_E_MODULE_TIMEOUT = -2147200101;
}
#endregion

#region Enums

[AllowDuplicates]
public enum FsrmQuotaFlags : int32
{
	FsrmQuotaFlags_Enforce = 256,
	FsrmQuotaFlags_Disable = 512,
	FsrmQuotaFlags_StatusIncomplete = 65536,
	FsrmQuotaFlags_StatusRebuilding = 131072,
}


[AllowDuplicates]
public enum FsrmFileScreenFlags : int32
{
	FsrmFileScreenFlags_Enforce = 1,
}


[AllowDuplicates]
public enum FsrmCollectionState : int32
{
	FsrmCollectionState_Fetching = 1,
	FsrmCollectionState_Committing = 2,
	FsrmCollectionState_Complete = 3,
	FsrmCollectionState_Cancelled = 4,
}


[AllowDuplicates]
public enum FsrmEnumOptions : int32
{
	FsrmEnumOptions_None = 0,
	FsrmEnumOptions_Asynchronous = 1,
	FsrmEnumOptions_CheckRecycleBin = 2,
	FsrmEnumOptions_IncludeClusterNodes = 4,
	FsrmEnumOptions_IncludeDeprecatedObjects = 8,
}


[AllowDuplicates]
public enum FsrmCommitOptions : int32
{
	FsrmCommitOptions_None = 0,
	FsrmCommitOptions_Asynchronous = 1,
}


[AllowDuplicates]
public enum FsrmTemplateApplyOptions : int32
{
	FsrmTemplateApplyOptions_ApplyToDerivedMatching = 1,
	FsrmTemplateApplyOptions_ApplyToDerivedAll = 2,
}


[AllowDuplicates]
public enum FsrmActionType : int32
{
	FsrmActionType_Unknown = 0,
	FsrmActionType_EventLog = 1,
	FsrmActionType_Email = 2,
	FsrmActionType_Command = 3,
	FsrmActionType_Report = 4,
}


[AllowDuplicates]
public enum FsrmEventType : int32
{
	FsrmEventType_Unknown = 0,
	FsrmEventType_Information = 1,
	FsrmEventType_Warning = 2,
	FsrmEventType_Error = 3,
}


[AllowDuplicates]
public enum FsrmAccountType : int32
{
	FsrmAccountType_Unknown = 0,
	FsrmAccountType_NetworkService = 1,
	FsrmAccountType_LocalService = 2,
	FsrmAccountType_LocalSystem = 3,
	FsrmAccountType_InProc = 4,
	FsrmAccountType_External = 5,
	FsrmAccountType_Automatic = 500,
}


[AllowDuplicates]
public enum FsrmReportType : int32
{
	FsrmReportType_Unknown = 0,
	FsrmReportType_LargeFiles = 1,
	FsrmReportType_FilesByType = 2,
	FsrmReportType_LeastRecentlyAccessed = 3,
	FsrmReportType_MostRecentlyAccessed = 4,
	FsrmReportType_QuotaUsage = 5,
	FsrmReportType_FilesByOwner = 6,
	FsrmReportType_ExportReport = 7,
	FsrmReportType_DuplicateFiles = 8,
	FsrmReportType_FileScreenAudit = 9,
	FsrmReportType_FilesByProperty = 10,
	FsrmReportType_AutomaticClassification = 11,
	FsrmReportType_Expiration = 12,
	FsrmReportType_FoldersByProperty = 13,
}


[AllowDuplicates]
public enum FsrmReportFormat : int32
{
	FsrmReportFormat_Unknown = 0,
	FsrmReportFormat_DHtml = 1,
	FsrmReportFormat_Html = 2,
	FsrmReportFormat_Txt = 3,
	FsrmReportFormat_Csv = 4,
	FsrmReportFormat_Xml = 5,
}


[AllowDuplicates]
public enum FsrmReportRunningStatus : int32
{
	FsrmReportRunningStatus_Unknown = 0,
	FsrmReportRunningStatus_NotRunning = 1,
	FsrmReportRunningStatus_Queued = 2,
	FsrmReportRunningStatus_Running = 3,
}


[AllowDuplicates]
public enum FsrmReportGenerationContext : int32
{
	FsrmReportGenerationContext_Undefined = 1,
	FsrmReportGenerationContext_ScheduledReport = 2,
	FsrmReportGenerationContext_InteractiveReport = 3,
	FsrmReportGenerationContext_IncidentReport = 4,
}


[AllowDuplicates]
public enum FsrmReportFilter : int32
{
	FsrmReportFilter_MinSize = 1,
	FsrmReportFilter_MinAgeDays = 2,
	FsrmReportFilter_MaxAgeDays = 3,
	FsrmReportFilter_MinQuotaUsage = 4,
	FsrmReportFilter_FileGroups = 5,
	FsrmReportFilter_Owners = 6,
	FsrmReportFilter_NamePattern = 7,
	FsrmReportFilter_Property = 8,
}


[AllowDuplicates]
public enum FsrmReportLimit : int32
{
	FsrmReportLimit_MaxFiles = 1,
	FsrmReportLimit_MaxFileGroups = 2,
	FsrmReportLimit_MaxOwners = 3,
	FsrmReportLimit_MaxFilesPerFileGroup = 4,
	FsrmReportLimit_MaxFilesPerOwner = 5,
	FsrmReportLimit_MaxFilesPerDuplGroup = 6,
	FsrmReportLimit_MaxDuplicateGroups = 7,
	FsrmReportLimit_MaxQuotas = 8,
	FsrmReportLimit_MaxFileScreenEvents = 9,
	FsrmReportLimit_MaxPropertyValues = 10,
	FsrmReportLimit_MaxFilesPerPropertyValue = 11,
	FsrmReportLimit_MaxFolders = 12,
}


[AllowDuplicates]
public enum FsrmPropertyDefinitionType : int32
{
	FsrmPropertyDefinitionType_Unknown = 0,
	FsrmPropertyDefinitionType_OrderedList = 1,
	FsrmPropertyDefinitionType_MultiChoiceList = 2,
	FsrmPropertyDefinitionType_SingleChoiceList = 3,
	FsrmPropertyDefinitionType_String = 4,
	FsrmPropertyDefinitionType_MultiString = 5,
	FsrmPropertyDefinitionType_Int = 6,
	FsrmPropertyDefinitionType_Bool = 7,
	FsrmPropertyDefinitionType_Date = 8,
}


[AllowDuplicates]
public enum FsrmPropertyDefinitionFlags : int32
{
	FsrmPropertyDefinitionFlags_Global = 1,
	FsrmPropertyDefinitionFlags_Deprecated = 2,
	FsrmPropertyDefinitionFlags_Secure = 4,
}


[AllowDuplicates]
public enum FsrmPropertyDefinitionAppliesTo : int32
{
	FsrmPropertyDefinitionAppliesTo_Files = 1,
	FsrmPropertyDefinitionAppliesTo_Folders = 2,
}


[AllowDuplicates]
public enum FsrmRuleType : int32
{
	FsrmRuleType_Unknown = 0,
	FsrmRuleType_Classification = 1,
	FsrmRuleType_Generic = 2,
}


[AllowDuplicates]
public enum FsrmRuleFlags : int32
{
	FsrmRuleFlags_Disabled = 256,
	FsrmRuleFlags_ClearAutomaticallyClassifiedProperty = 1024,
	FsrmRuleFlags_ClearManuallyClassifiedProperty = 2048,
	FsrmRuleFlags_Invalid = 4096,
}


[AllowDuplicates]
public enum FsrmClassificationLoggingFlags : int32
{
	FsrmClassificationLoggingFlags_None = 0,
	FsrmClassificationLoggingFlags_ClassificationsInLogFile = 1,
	FsrmClassificationLoggingFlags_ErrorsInLogFile = 2,
	FsrmClassificationLoggingFlags_ClassificationsInSystemLog = 4,
	FsrmClassificationLoggingFlags_ErrorsInSystemLog = 8,
}


[AllowDuplicates]
public enum FsrmExecutionOption : int32
{
	FsrmExecutionOption_Unknown = 0,
	FsrmExecutionOption_EvaluateUnset = 1,
	FsrmExecutionOption_ReEvaluate_ConsiderExistingValue = 2,
	FsrmExecutionOption_ReEvaluate_IgnoreExistingValue = 3,
}


[AllowDuplicates]
public enum FsrmStorageModuleCaps : int32
{
	FsrmStorageModuleCaps_Unknown = 0,
	FsrmStorageModuleCaps_CanGet = 1,
	FsrmStorageModuleCaps_CanSet = 2,
	FsrmStorageModuleCaps_CanHandleDirectories = 4,
	FsrmStorageModuleCaps_CanHandleFiles = 8,
}


[AllowDuplicates]
public enum FsrmStorageModuleType : int32
{
	FsrmStorageModuleType_Unknown = 0,
	FsrmStorageModuleType_Cache = 1,
	FsrmStorageModuleType_InFile = 2,
	FsrmStorageModuleType_Database = 3,
	FsrmStorageModuleType_System = 100,
}


[AllowDuplicates]
public enum FsrmPropertyBagFlags : int32
{
	FsrmPropertyBagFlags_UpdatedByClassifier = 1,
	FsrmPropertyBagFlags_FailedLoadingProperties = 2,
	FsrmPropertyBagFlags_FailedSavingProperties = 4,
	FsrmPropertyBagFlags_FailedClassifyingProperties = 8,
}


[AllowDuplicates]
public enum FsrmPropertyBagField : int32
{
	FsrmPropertyBagField_AccessVolume = 0,
	FsrmPropertyBagField_VolumeGuidName = 1,
}


[AllowDuplicates]
public enum FsrmPropertyFlags : int32
{
	FsrmPropertyFlags_None = 0,
	FsrmPropertyFlags_Orphaned = 1,
	FsrmPropertyFlags_RetrievedFromCache = 2,
	FsrmPropertyFlags_RetrievedFromStorage = 4,
	FsrmPropertyFlags_SetByClassifier = 8,
	FsrmPropertyFlags_Deleted = 16,
	FsrmPropertyFlags_Reclassified = 32,
	FsrmPropertyFlags_AggregationFailed = 64,
	FsrmPropertyFlags_Existing = 128,
	FsrmPropertyFlags_FailedLoadingProperties = 256,
	FsrmPropertyFlags_FailedClassifyingProperties = 512,
	FsrmPropertyFlags_FailedSavingProperties = 1024,
	FsrmPropertyFlags_Secure = 2048,
	FsrmPropertyFlags_PolicyDerived = 4096,
	FsrmPropertyFlags_Inherited = 8192,
	FsrmPropertyFlags_Manual = 16384,
	FsrmPropertyFlags_ExplicitValueDeleted = 32768,
	FsrmPropertyFlags_PropertyDeletedFromClear = 65536,
	FsrmPropertyFlags_PropertySourceMask = 14,
	FsrmPropertyFlags_PersistentMask = 20480,
}


[AllowDuplicates]
public enum FsrmPipelineModuleType : int32
{
	FsrmPipelineModuleType_Unknown = 0,
	FsrmPipelineModuleType_Storage = 1,
	FsrmPipelineModuleType_Classifier = 2,
}


[AllowDuplicates]
public enum FsrmGetFilePropertyOptions : int32
{
	FsrmGetFilePropertyOptions_None = 0,
	FsrmGetFilePropertyOptions_NoRuleEvaluation = 1,
	FsrmGetFilePropertyOptions_Persistent = 2,
	FsrmGetFilePropertyOptions_FailOnPersistErrors = 4,
	FsrmGetFilePropertyOptions_SkipOrphaned = 8,
}


[AllowDuplicates]
public enum FsrmFileManagementType : int32
{
	FsrmFileManagementType_Unknown = 0,
	FsrmFileManagementType_Expiration = 1,
	FsrmFileManagementType_Custom = 2,
	FsrmFileManagementType_Rms = 3,
}


[AllowDuplicates]
public enum FsrmFileManagementLoggingFlags : int32
{
	FsrmFileManagementLoggingFlags_None = 0,
	FsrmFileManagementLoggingFlags_Error = 1,
	FsrmFileManagementLoggingFlags_Information = 2,
	FsrmFileManagementLoggingFlags_Audit = 4,
}


[AllowDuplicates]
public enum FsrmPropertyConditionType : int32
{
	FsrmPropertyConditionType_Unknown = 0,
	FsrmPropertyConditionType_Equal = 1,
	FsrmPropertyConditionType_NotEqual = 2,
	FsrmPropertyConditionType_GreaterThan = 3,
	FsrmPropertyConditionType_LessThan = 4,
	FsrmPropertyConditionType_Contain = 5,
	FsrmPropertyConditionType_Exist = 6,
	FsrmPropertyConditionType_NotExist = 7,
	FsrmPropertyConditionType_StartWith = 8,
	FsrmPropertyConditionType_EndWith = 9,
	FsrmPropertyConditionType_ContainedIn = 10,
	FsrmPropertyConditionType_PrefixOf = 11,
	FsrmPropertyConditionType_SuffixOf = 12,
	FsrmPropertyConditionType_MatchesPattern = 13,
}


[AllowDuplicates]
public enum FsrmFileStreamingMode : int32
{
	FsrmFileStreamingMode_Unknown = 0,
	FsrmFileStreamingMode_Read = 1,
	FsrmFileStreamingMode_Write = 2,
}


[AllowDuplicates]
public enum FsrmFileStreamingInterfaceType : int32
{
	FsrmFileStreamingInterfaceType_Unknown = 0,
	FsrmFileStreamingInterfaceType_ILockBytes = 1,
	FsrmFileStreamingInterfaceType_IStream = 2,
}


[AllowDuplicates]
public enum FsrmFileConditionType : int32
{
	FsrmFileConditionType_Unknown = 0,
	FsrmFileConditionType_Property = 1,
}


[AllowDuplicates]
public enum FsrmFileSystemPropertyId : int32
{
	FsrmFileSystemPropertyId_Undefined = 0,
	FsrmFileSystemPropertyId_FileName = 1,
	FsrmFileSystemPropertyId_DateCreated = 2,
	FsrmFileSystemPropertyId_DateLastAccessed = 3,
	FsrmFileSystemPropertyId_DateLastModified = 4,
	FsrmFileSystemPropertyId_DateNow = 5,
}


[AllowDuplicates]
public enum FsrmPropertyValueType : int32
{
	FsrmPropertyValueType_Undefined = 0,
	FsrmPropertyValueType_Literal = 1,
	FsrmPropertyValueType_DateOffset = 2,
}


[AllowDuplicates]
public enum AdrClientDisplayFlags : int32
{
	AdrClientDisplayFlags_AllowEmailRequests = 1,
	AdrClientDisplayFlags_ShowDeviceTroubleshooting = 2,
}


[AllowDuplicates]
public enum AdrEmailFlags : int32
{
	AdrEmailFlags_PutDataOwnerOnToLine = 1,
	AdrEmailFlags_PutAdminOnToLine = 2,
	AdrEmailFlags_IncludeDeviceClaims = 4,
	AdrEmailFlags_IncludeUserInfo = 8,
	AdrEmailFlags_GenerateEventLog = 16,
}


[AllowDuplicates]
public enum AdrClientErrorType : int32
{
	AdrClientErrorType_Unknown = 0,
	AdrClientErrorType_AccessDenied = 1,
	AdrClientErrorType_FileNotFound = 2,
}


[AllowDuplicates]
public enum AdrClientFlags : int32
{
	AdrClientFlags_None = 0,
	AdrClientFlags_FailForLocalPaths = 1,
	AdrClientFlags_FailIfNotSupportedByServer = 2,
	AdrClientFlags_FailIfNotDomainJoined = 4,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_FsrmSetting = .(0xf556d708, 0x6d4d, 0x4594, 0x9c, 0x61, 0x7d, 0xbb, 0x0d, 0xae, 0x2a, 0x46);


	public const Guid CLSID_FsrmPathMapper = .(0xf3be42bd, 0x8ac2, 0x409e, 0xbb, 0xd8, 0xfa, 0xf9, 0xb6, 0xb4, 0x1f, 0xeb);


	public const Guid CLSID_FsrmExportImport = .(0x1482dc37, 0xfae9, 0x4787, 0x90, 0x25, 0x8c, 0xe4, 0xe0, 0x24, 0xab, 0x56);


	public const Guid CLSID_FsrmQuotaManager = .(0x90dcab7f, 0x347c, 0x4bfc, 0xb5, 0x43, 0x54, 0x03, 0x26, 0x30, 0x5f, 0xbe);


	public const Guid CLSID_FsrmQuotaTemplateManager = .(0x97d3d443, 0x251c, 0x4337, 0x81, 0xe7, 0xb3, 0x2e, 0x8f, 0x4e, 0xe6, 0x5e);


	public const Guid CLSID_FsrmFileGroupManager = .(0x8f1363f6, 0x656f, 0x4496, 0x92, 0x26, 0x13, 0xae, 0xcb, 0xd7, 0x71, 0x8f);


	public const Guid CLSID_FsrmFileScreenManager = .(0x95941183, 0xdb53, 0x4c5f, 0xb3, 0x7b, 0x7d, 0x09, 0x21, 0xcf, 0x9d, 0xc7);


	public const Guid CLSID_FsrmFileScreenTemplateManager = .(0x243111df, 0xe474, 0x46aa, 0xa0, 0x54, 0xea, 0xa3, 0x3e, 0xdc, 0x29, 0x2a);


	public const Guid CLSID_FsrmReportManager = .(0x0058ef37, 0xaa66, 0x4c48, 0xbd, 0x5b, 0x2f, 0xce, 0x43, 0x2a, 0xb0, 0xc8);


	public const Guid CLSID_FsrmReportScheduler = .(0xea25f1b8, 0x1b8d, 0x4290, 0x8e, 0xe8, 0xe1, 0x7c, 0x12, 0xc2, 0xfe, 0x20);


	public const Guid CLSID_FsrmFileManagementJobManager = .(0xeb18f9b2, 0x4c3a, 0x4321, 0xb2, 0x03, 0x20, 0x51, 0x20, 0xcf, 0xf6, 0x14);


	public const Guid CLSID_FsrmClassificationManager = .(0xb15c0e47, 0xc391, 0x45b9, 0x95, 0xc8, 0xeb, 0x59, 0x6c, 0x85, 0x3f, 0x3a);


	public const Guid CLSID_FsrmPipelineModuleConnector = .(0xc7643375, 0x1eb5, 0x44de, 0xa0, 0x62, 0x62, 0x35, 0x47, 0xd9, 0x33, 0xbc);


	public const Guid CLSID_AdSyncTask = .(0x2ae64751, 0xb728, 0x4d6b, 0x97, 0xa0, 0xb2, 0xda, 0x2e, 0x7d, 0x2a, 0x3b);


	public const Guid CLSID_FsrmAccessDeniedRemediationClient = .(0x100b4fc8, 0x74c1, 0x470f, 0xb1, 0xb7, 0xdd, 0x7b, 0x6b, 0xae, 0x79, 0xbd);


}
#endregion

#region COM Types
[CRepr]struct IFsrmObject : IDispatch
{
	public new const Guid IID = .(0x22bcef93, 0x4a3f, 0x4183, 0x89, 0xf9, 0x2f, 0x8b, 0x8a, 0x62, 0x8a, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR description) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
	}


	public HRESULT get_Id(Guid* id) mut => VT.[Friend]get_Id(&this, id);

	public HRESULT get_Description(BSTR* description) mut => VT.[Friend]get_Description(&this, description);

	public HRESULT put_Description(BSTR description) mut => VT.[Friend]put_Description(&this, description);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);
}

[CRepr]struct IFsrmCollection : IDispatch
{
	public new const Guid IID = .(0xf76fbf3b, 0x8ddd, 0x4b42, 0xb0, 0x5a, 0xcb, 0x1c, 0x3f, 0xf1, 0xfe, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** unknown) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, VARIANT* item) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmCollectionState* state) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 waitSeconds, int16* completed) WaitForCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid id, VARIANT* entry) GetById;
	}


	public HRESULT get__NewEnum(IUnknown** unknown) mut => VT.[Friend]get__NewEnum(&this, unknown);

	public HRESULT get_Item(int32 index, VARIANT* item) mut => VT.[Friend]get_Item(&this, index, item);

	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT get_State(FsrmCollectionState* state) mut => VT.[Friend]get_State(&this, state);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT WaitForCompletion(int32 waitSeconds, int16* completed) mut => VT.[Friend]WaitForCompletion(&this, waitSeconds, completed);

	public HRESULT GetById(Guid id, VARIANT* entry) mut => VT.[Friend]GetById(&this, id, entry);
}

[CRepr]struct IFsrmMutableCollection : IFsrmCollection
{
	public new const Guid IID = .(0x1bb617b8, 0x3886, 0x49dc, 0xaf, 0x82, 0xa6, 0xc9, 0x0f, 0xa3, 0x5d, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmCollection.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT item) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid id) RemoveById;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection** collection) Clone;
	}


	public HRESULT Add(VARIANT item) mut => VT.[Friend]Add(&this, item);

	public HRESULT Remove(int32 index) mut => VT.[Friend]Remove(&this, index);

	public HRESULT RemoveById(Guid id) mut => VT.[Friend]RemoveById(&this, id);

	public HRESULT Clone(IFsrmMutableCollection** collection) mut => VT.[Friend]Clone(&this, collection);
}

[CRepr]struct IFsrmCommittableCollection : IFsrmMutableCollection
{
	public new const Guid IID = .(0x96deb3b5, 0x8b91, 0x4a2a, 0x9d, 0x93, 0x80, 0xa3, 0x5d, 0x8a, 0xa8, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmMutableCollection.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmCommitOptions options, IFsrmCollection** results) Commit;
	}


	public HRESULT Commit(FsrmCommitOptions options, IFsrmCollection** results) mut => VT.[Friend]Commit(&this, options, results);
}

[CRepr]struct IFsrmAction : IDispatch
{
	public new const Guid IID = .(0x6cd6408a, 0xae60, 0x463b, 0x9e, 0xf1, 0xe1, 0x17, 0x53, 0x4d, 0x69, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* id) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmActionType* actionType) get_ActionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* minutes) get_RunLimitInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 minutes) put_RunLimitInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_Id(Guid* id) mut => VT.[Friend]get_Id(&this, id);

	public HRESULT get_ActionType(FsrmActionType* actionType) mut => VT.[Friend]get_ActionType(&this, actionType);

	public HRESULT get_RunLimitInterval(int32* minutes) mut => VT.[Friend]get_RunLimitInterval(&this, minutes);

	public HRESULT put_RunLimitInterval(int32 minutes) mut => VT.[Friend]put_RunLimitInterval(&this, minutes);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IFsrmActionEmail : IFsrmAction
{
	public new const Guid IID = .(0xd646567d, 0x26ae, 0x4caa, 0x9f, 0x84, 0x4e, 0x0a, 0xad, 0x20, 0x7f, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailFrom) get_MailFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailFrom) put_MailFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailReplyTo) get_MailReplyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailReplyTo) put_MailReplyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailTo) get_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailTo) put_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailCc) get_MailCc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailCc) put_MailCc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailBcc) get_MailBcc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailBcc) put_MailBcc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailSubject) get_MailSubject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailSubject) put_MailSubject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* messageText) get_MessageText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR messageText) put_MessageText;
	}


	public HRESULT get_MailFrom(BSTR* mailFrom) mut => VT.[Friend]get_MailFrom(&this, mailFrom);

	public HRESULT put_MailFrom(BSTR mailFrom) mut => VT.[Friend]put_MailFrom(&this, mailFrom);

	public HRESULT get_MailReplyTo(BSTR* mailReplyTo) mut => VT.[Friend]get_MailReplyTo(&this, mailReplyTo);

	public HRESULT put_MailReplyTo(BSTR mailReplyTo) mut => VT.[Friend]put_MailReplyTo(&this, mailReplyTo);

	public HRESULT get_MailTo(BSTR* mailTo) mut => VT.[Friend]get_MailTo(&this, mailTo);

	public HRESULT put_MailTo(BSTR mailTo) mut => VT.[Friend]put_MailTo(&this, mailTo);

	public HRESULT get_MailCc(BSTR* mailCc) mut => VT.[Friend]get_MailCc(&this, mailCc);

	public HRESULT put_MailCc(BSTR mailCc) mut => VT.[Friend]put_MailCc(&this, mailCc);

	public HRESULT get_MailBcc(BSTR* mailBcc) mut => VT.[Friend]get_MailBcc(&this, mailBcc);

	public HRESULT put_MailBcc(BSTR mailBcc) mut => VT.[Friend]put_MailBcc(&this, mailBcc);

	public HRESULT get_MailSubject(BSTR* mailSubject) mut => VT.[Friend]get_MailSubject(&this, mailSubject);

	public HRESULT put_MailSubject(BSTR mailSubject) mut => VT.[Friend]put_MailSubject(&this, mailSubject);

	public HRESULT get_MessageText(BSTR* messageText) mut => VT.[Friend]get_MessageText(&this, messageText);

	public HRESULT put_MessageText(BSTR messageText) mut => VT.[Friend]put_MessageText(&this, messageText);
}

[CRepr]struct IFsrmActionEmail2 : IFsrmActionEmail
{
	public new const Guid IID = .(0x8276702f, 0x2532, 0x4839, 0x89, 0xbf, 0x48, 0x72, 0x60, 0x9a, 0x2e, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmActionEmail.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* attachmentFileListSize) get_AttachmentFileListSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 attachmentFileListSize) put_AttachmentFileListSize;
	}


	public HRESULT get_AttachmentFileListSize(int32* attachmentFileListSize) mut => VT.[Friend]get_AttachmentFileListSize(&this, attachmentFileListSize);

	public HRESULT put_AttachmentFileListSize(int32 attachmentFileListSize) mut => VT.[Friend]put_AttachmentFileListSize(&this, attachmentFileListSize);
}

[CRepr]struct IFsrmActionReport : IFsrmAction
{
	public new const Guid IID = .(0x2dbe63c4, 0xb340, 0x48a0, 0xa5, 0xb0, 0x15, 0x8e, 0x07, 0xfc, 0x56, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** reportTypes) get_ReportTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* reportTypes) put_ReportTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailTo) get_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailTo) put_MailTo;
	}


	public HRESULT get_ReportTypes(SAFEARRAY** reportTypes) mut => VT.[Friend]get_ReportTypes(&this, reportTypes);

	public HRESULT put_ReportTypes(SAFEARRAY* reportTypes) mut => VT.[Friend]put_ReportTypes(&this, reportTypes);

	public HRESULT get_MailTo(BSTR* mailTo) mut => VT.[Friend]get_MailTo(&this, mailTo);

	public HRESULT put_MailTo(BSTR mailTo) mut => VT.[Friend]put_MailTo(&this, mailTo);
}

[CRepr]struct IFsrmActionEventLog : IFsrmAction
{
	public new const Guid IID = .(0x4c8f96c3, 0x5d94, 0x4f37, 0xa4, 0xf4, 0xf5, 0x6a, 0xb4, 0x63, 0x54, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEventType* eventType) get_EventType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEventType eventType) put_EventType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* messageText) get_MessageText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR messageText) put_MessageText;
	}


	public HRESULT get_EventType(FsrmEventType* eventType) mut => VT.[Friend]get_EventType(&this, eventType);

	public HRESULT put_EventType(FsrmEventType eventType) mut => VT.[Friend]put_EventType(&this, eventType);

	public HRESULT get_MessageText(BSTR* messageText) mut => VT.[Friend]get_MessageText(&this, messageText);

	public HRESULT put_MessageText(BSTR messageText) mut => VT.[Friend]put_MessageText(&this, messageText);
}

[CRepr]struct IFsrmActionCommand : IFsrmAction
{
	public new const Guid IID = .(0x12937789, 0xe247, 0x4917, 0x9c, 0x20, 0xf3, 0xee, 0x9c, 0x7e, 0xe7, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmAction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* executablePath) get_ExecutablePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR executablePath) put_ExecutablePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* arguments) get_Arguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR arguments) put_Arguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmAccountType* account) get_Account;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmAccountType account) put_Account;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* workingDirectory) get_WorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR workingDirectory) put_WorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* monitorCommand) get_MonitorCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 monitorCommand) put_MonitorCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* minutes) get_KillTimeOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 minutes) put_KillTimeOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* logResults) get_LogResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 logResults) put_LogResult;
	}


	public HRESULT get_ExecutablePath(BSTR* executablePath) mut => VT.[Friend]get_ExecutablePath(&this, executablePath);

	public HRESULT put_ExecutablePath(BSTR executablePath) mut => VT.[Friend]put_ExecutablePath(&this, executablePath);

	public HRESULT get_Arguments(BSTR* arguments) mut => VT.[Friend]get_Arguments(&this, arguments);

	public HRESULT put_Arguments(BSTR arguments) mut => VT.[Friend]put_Arguments(&this, arguments);

	public HRESULT get_Account(FsrmAccountType* account) mut => VT.[Friend]get_Account(&this, account);

	public HRESULT put_Account(FsrmAccountType account) mut => VT.[Friend]put_Account(&this, account);

	public HRESULT get_WorkingDirectory(BSTR* workingDirectory) mut => VT.[Friend]get_WorkingDirectory(&this, workingDirectory);

	public HRESULT put_WorkingDirectory(BSTR workingDirectory) mut => VT.[Friend]put_WorkingDirectory(&this, workingDirectory);

	public HRESULT get_MonitorCommand(int16* monitorCommand) mut => VT.[Friend]get_MonitorCommand(&this, monitorCommand);

	public HRESULT put_MonitorCommand(int16 monitorCommand) mut => VT.[Friend]put_MonitorCommand(&this, monitorCommand);

	public HRESULT get_KillTimeOut(int32* minutes) mut => VT.[Friend]get_KillTimeOut(&this, minutes);

	public HRESULT put_KillTimeOut(int32 minutes) mut => VT.[Friend]put_KillTimeOut(&this, minutes);

	public HRESULT get_LogResult(int16* logResults) mut => VT.[Friend]get_LogResult(&this, logResults);

	public HRESULT put_LogResult(int16 logResults) mut => VT.[Friend]put_LogResult(&this, logResults);
}

[CRepr]struct IFsrmSetting : IDispatch
{
	public new const Guid IID = .(0xf411d4fd, 0x14be, 0x4260, 0x8c, 0x40, 0x03, 0xb7, 0xc9, 0x5e, 0x60, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* smtpServer) get_SmtpServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR smtpServer) put_SmtpServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailFrom) get_MailFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailFrom) put_MailFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* adminEmail) get_AdminEmail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR adminEmail) put_AdminEmail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* disableCommandLine) get_DisableCommandLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 disableCommandLine) put_DisableCommandLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enableScreeningAudit) get_EnableScreeningAudit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enableScreeningAudit) put_EnableScreeningAudit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailTo) EmailTest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmActionType actionType, int32 delayTimeMinutes) SetActionRunLimitInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmActionType actionType, int32* delayTimeMinutes) GetActionRunLimitInterval;
	}


	public HRESULT get_SmtpServer(BSTR* smtpServer) mut => VT.[Friend]get_SmtpServer(&this, smtpServer);

	public HRESULT put_SmtpServer(BSTR smtpServer) mut => VT.[Friend]put_SmtpServer(&this, smtpServer);

	public HRESULT get_MailFrom(BSTR* mailFrom) mut => VT.[Friend]get_MailFrom(&this, mailFrom);

	public HRESULT put_MailFrom(BSTR mailFrom) mut => VT.[Friend]put_MailFrom(&this, mailFrom);

	public HRESULT get_AdminEmail(BSTR* adminEmail) mut => VT.[Friend]get_AdminEmail(&this, adminEmail);

	public HRESULT put_AdminEmail(BSTR adminEmail) mut => VT.[Friend]put_AdminEmail(&this, adminEmail);

	public HRESULT get_DisableCommandLine(int16* disableCommandLine) mut => VT.[Friend]get_DisableCommandLine(&this, disableCommandLine);

	public HRESULT put_DisableCommandLine(int16 disableCommandLine) mut => VT.[Friend]put_DisableCommandLine(&this, disableCommandLine);

	public HRESULT get_EnableScreeningAudit(int16* enableScreeningAudit) mut => VT.[Friend]get_EnableScreeningAudit(&this, enableScreeningAudit);

	public HRESULT put_EnableScreeningAudit(int16 enableScreeningAudit) mut => VT.[Friend]put_EnableScreeningAudit(&this, enableScreeningAudit);

	public HRESULT EmailTest(BSTR mailTo) mut => VT.[Friend]EmailTest(&this, mailTo);

	public HRESULT SetActionRunLimitInterval(FsrmActionType actionType, int32 delayTimeMinutes) mut => VT.[Friend]SetActionRunLimitInterval(&this, actionType, delayTimeMinutes);

	public HRESULT GetActionRunLimitInterval(FsrmActionType actionType, int32* delayTimeMinutes) mut => VT.[Friend]GetActionRunLimitInterval(&this, actionType, delayTimeMinutes);
}

[CRepr]struct IFsrmPathMapper : IDispatch
{
	public new const Guid IID = .(0x6f4dbfff, 0x6920, 0x4821, 0xa6, 0xc3, 0xb7, 0xe9, 0x4c, 0x1f, 0xd6, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR localPath, SAFEARRAY** sharePaths) GetSharePathsForLocalPath;
	}


	public HRESULT GetSharePathsForLocalPath(BSTR localPath, SAFEARRAY** sharePaths) mut => VT.[Friend]GetSharePathsForLocalPath(&this, localPath, sharePaths);
}

[CRepr]struct IFsrmExportImport : IDispatch
{
	public new const Guid IID = .(0xefcb0ab1, 0x16c4, 0x4a79, 0x81, 0x2c, 0x72, 0x56, 0x14, 0xc3, 0x30, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, VARIANT* fileGroupNamesSafeArray, BSTR remoteHost) ExportFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, VARIANT* fileGroupNamesSafeArray, BSTR remoteHost, IFsrmCommittableCollection** fileGroups) ImportFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost) ExportFileScreenTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost, IFsrmCommittableCollection** templates) ImportFileScreenTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost) ExportQuotaTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost, IFsrmCommittableCollection** templates) ImportQuotaTemplates;
	}


	public HRESULT ExportFileGroups(BSTR filePath, VARIANT* fileGroupNamesSafeArray, BSTR remoteHost) mut => VT.[Friend]ExportFileGroups(&this, filePath, fileGroupNamesSafeArray, remoteHost);

	public HRESULT ImportFileGroups(BSTR filePath, VARIANT* fileGroupNamesSafeArray, BSTR remoteHost, IFsrmCommittableCollection** fileGroups) mut => VT.[Friend]ImportFileGroups(&this, filePath, fileGroupNamesSafeArray, remoteHost, fileGroups);

	public HRESULT ExportFileScreenTemplates(BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost) mut => VT.[Friend]ExportFileScreenTemplates(&this, filePath, templateNamesSafeArray, remoteHost);

	public HRESULT ImportFileScreenTemplates(BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost, IFsrmCommittableCollection** templates) mut => VT.[Friend]ImportFileScreenTemplates(&this, filePath, templateNamesSafeArray, remoteHost, templates);

	public HRESULT ExportQuotaTemplates(BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost) mut => VT.[Friend]ExportQuotaTemplates(&this, filePath, templateNamesSafeArray, remoteHost);

	public HRESULT ImportQuotaTemplates(BSTR filePath, VARIANT* templateNamesSafeArray, BSTR remoteHost, IFsrmCommittableCollection** templates) mut => VT.[Friend]ImportQuotaTemplates(&this, filePath, templateNamesSafeArray, remoteHost, templates);
}

[CRepr]struct IFsrmDerivedObjectsResult : IDispatch
{
	public new const Guid IID = .(0x39322a2d, 0x38ee, 0x4d0d, 0x80, 0x95, 0x42, 0x1a, 0x80, 0x84, 0x9a, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** derivedObjects) get_DerivedObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** results) get_Results;
	}


	public HRESULT get_DerivedObjects(IFsrmCollection** derivedObjects) mut => VT.[Friend]get_DerivedObjects(&this, derivedObjects);

	public HRESULT get_Results(IFsrmCollection** results) mut => VT.[Friend]get_Results(&this, results);
}

[CRepr]struct IFsrmAccessDeniedRemediationClient : IDispatch
{
	public new const Guid IID = .(0x40002314, 0x590b, 0x45a5, 0x8e, 0x1b, 0x8c, 0x05, 0xda, 0x52, 0x7e, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint parentWnd, BSTR accessPath, AdrClientErrorType errorType, int32 flags, BSTR windowTitle, BSTR windowMessage, int32* result) Show;
	}


	public HRESULT Show(uint parentWnd, BSTR accessPath, AdrClientErrorType errorType, int32 flags, BSTR windowTitle, BSTR windowMessage, int32* result) mut => VT.[Friend]Show(&this, parentWnd, accessPath, errorType, flags, windowTitle, windowMessage, result);
}

[CRepr]struct IFsrmQuotaBase : IFsrmObject
{
	public new const Guid IID = .(0x1568a795, 0x3924, 0x4118, 0xb7, 0x4b, 0x68, 0xd8, 0xf0, 0xfa, 0x5d, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* quotaLimit) get_QuotaLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT quotaLimit) put_QuotaLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* quotaFlags) get_QuotaFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 quotaFlags) put_QuotaFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** thresholds) get_Thresholds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 threshold) AddThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 threshold) DeleteThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 threshold, int32 newThreshold) ModifyThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 threshold, FsrmActionType actionType, IFsrmAction** action) CreateThresholdAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 threshold, IFsrmCollection** actions) EnumThresholdActions;
	}


	public HRESULT get_QuotaLimit(VARIANT* quotaLimit) mut => VT.[Friend]get_QuotaLimit(&this, quotaLimit);

	public HRESULT put_QuotaLimit(VARIANT quotaLimit) mut => VT.[Friend]put_QuotaLimit(&this, quotaLimit);

	public HRESULT get_QuotaFlags(int32* quotaFlags) mut => VT.[Friend]get_QuotaFlags(&this, quotaFlags);

	public HRESULT put_QuotaFlags(int32 quotaFlags) mut => VT.[Friend]put_QuotaFlags(&this, quotaFlags);

	public HRESULT get_Thresholds(SAFEARRAY** thresholds) mut => VT.[Friend]get_Thresholds(&this, thresholds);

	public HRESULT AddThreshold(int32 threshold) mut => VT.[Friend]AddThreshold(&this, threshold);

	public HRESULT DeleteThreshold(int32 threshold) mut => VT.[Friend]DeleteThreshold(&this, threshold);

	public HRESULT ModifyThreshold(int32 threshold, int32 newThreshold) mut => VT.[Friend]ModifyThreshold(&this, threshold, newThreshold);

	public HRESULT CreateThresholdAction(int32 threshold, FsrmActionType actionType, IFsrmAction** action) mut => VT.[Friend]CreateThresholdAction(&this, threshold, actionType, action);

	public HRESULT EnumThresholdActions(int32 threshold, IFsrmCollection** actions) mut => VT.[Friend]EnumThresholdActions(&this, threshold, actions);
}

[CRepr]struct IFsrmQuotaObject : IFsrmQuotaBase
{
	public new const Guid IID = .(0x42dc3511, 0x61d5, 0x48ae, 0xb6, 0xdc, 0x59, 0xfc, 0x00, 0xc0, 0xa8, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmQuotaBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userSid) get_UserSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userAccount) get_UserAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* quotaTemplateName) get_SourceTemplateName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* matches) get_MatchesSourceTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR quotaTemplateName) ApplyTemplate;
	}


	public HRESULT get_Path(BSTR* path) mut => VT.[Friend]get_Path(&this, path);

	public HRESULT get_UserSid(BSTR* userSid) mut => VT.[Friend]get_UserSid(&this, userSid);

	public HRESULT get_UserAccount(BSTR* userAccount) mut => VT.[Friend]get_UserAccount(&this, userAccount);

	public HRESULT get_SourceTemplateName(BSTR* quotaTemplateName) mut => VT.[Friend]get_SourceTemplateName(&this, quotaTemplateName);

	public HRESULT get_MatchesSourceTemplate(int16* matches) mut => VT.[Friend]get_MatchesSourceTemplate(&this, matches);

	public HRESULT ApplyTemplate(BSTR quotaTemplateName) mut => VT.[Friend]ApplyTemplate(&this, quotaTemplateName);
}

[CRepr]struct IFsrmQuota : IFsrmQuotaObject
{
	public new const Guid IID = .(0x377f739d, 0x9647, 0x4b8e, 0x97, 0xd2, 0x5f, 0xfc, 0xe6, 0xd7, 0x59, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmQuotaObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* used) get_QuotaUsed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* peakUsage) get_QuotaPeakUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* peakUsageDateTime) get_QuotaPeakUsageTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetPeakUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshUsageProperties;
	}


	public HRESULT get_QuotaUsed(VARIANT* used) mut => VT.[Friend]get_QuotaUsed(&this, used);

	public HRESULT get_QuotaPeakUsage(VARIANT* peakUsage) mut => VT.[Friend]get_QuotaPeakUsage(&this, peakUsage);

	public HRESULT get_QuotaPeakUsageTime(double* peakUsageDateTime) mut => VT.[Friend]get_QuotaPeakUsageTime(&this, peakUsageDateTime);

	public HRESULT ResetPeakUsage() mut => VT.[Friend]ResetPeakUsage(&this);

	public HRESULT RefreshUsageProperties() mut => VT.[Friend]RefreshUsageProperties(&this);
}

[CRepr]struct IFsrmAutoApplyQuota : IFsrmQuotaObject
{
	public new const Guid IID = .(0xf82e5729, 0x6aba, 0x4740, 0xbf, 0xc7, 0xc7, 0xf5, 0x8f, 0x75, 0xfb, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmQuotaObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** folders) get_ExcludeFolders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* folders) put_ExcludeFolders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmCommitOptions commitOptions, FsrmTemplateApplyOptions applyOptions, IFsrmDerivedObjectsResult** derivedObjectsResult) CommitAndUpdateDerived;
	}


	public HRESULT get_ExcludeFolders(SAFEARRAY** folders) mut => VT.[Friend]get_ExcludeFolders(&this, folders);

	public HRESULT put_ExcludeFolders(SAFEARRAY* folders) mut => VT.[Friend]put_ExcludeFolders(&this, folders);

	public HRESULT CommitAndUpdateDerived(FsrmCommitOptions commitOptions, FsrmTemplateApplyOptions applyOptions, IFsrmDerivedObjectsResult** derivedObjectsResult) mut => VT.[Friend]CommitAndUpdateDerived(&this, commitOptions, applyOptions, derivedObjectsResult);
}

[CRepr]struct IFsrmQuotaManager : IDispatch
{
	public new const Guid IID = .(0x8bb68c7d, 0x19d8, 0x4ffb, 0x80, 0x9e, 0xbe, 0x4f, 0xc1, 0x73, 0x40, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** variables) get_ActionVariables;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** descriptions) get_ActionVariableDescriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmQuota** quota) CreateQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR quotaTemplateName, BSTR path, IFsrmAutoApplyQuota** quota) CreateAutoApplyQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmQuota** quota) GetQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmAutoApplyQuota** quota) GetAutoApplyQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmQuota** quota) GetRestrictiveQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** quotas) EnumQuotas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** quotas) EnumAutoApplyQuotas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** quotas) EnumEffectiveQuotas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPath) Scan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCommittableCollection** collection) CreateQuotaCollection;
	}


	public HRESULT get_ActionVariables(SAFEARRAY** variables) mut => VT.[Friend]get_ActionVariables(&this, variables);

	public HRESULT get_ActionVariableDescriptions(SAFEARRAY** descriptions) mut => VT.[Friend]get_ActionVariableDescriptions(&this, descriptions);

	public HRESULT CreateQuota(BSTR path, IFsrmQuota** quota) mut => VT.[Friend]CreateQuota(&this, path, quota);

	public HRESULT CreateAutoApplyQuota(BSTR quotaTemplateName, BSTR path, IFsrmAutoApplyQuota** quota) mut => VT.[Friend]CreateAutoApplyQuota(&this, quotaTemplateName, path, quota);

	public HRESULT GetQuota(BSTR path, IFsrmQuota** quota) mut => VT.[Friend]GetQuota(&this, path, quota);

	public HRESULT GetAutoApplyQuota(BSTR path, IFsrmAutoApplyQuota** quota) mut => VT.[Friend]GetAutoApplyQuota(&this, path, quota);

	public HRESULT GetRestrictiveQuota(BSTR path, IFsrmQuota** quota) mut => VT.[Friend]GetRestrictiveQuota(&this, path, quota);

	public HRESULT EnumQuotas(BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** quotas) mut => VT.[Friend]EnumQuotas(&this, path, options, quotas);

	public HRESULT EnumAutoApplyQuotas(BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** quotas) mut => VT.[Friend]EnumAutoApplyQuotas(&this, path, options, quotas);

	public HRESULT EnumEffectiveQuotas(BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** quotas) mut => VT.[Friend]EnumEffectiveQuotas(&this, path, options, quotas);

	public HRESULT Scan(BSTR strPath) mut => VT.[Friend]Scan(&this, strPath);

	public HRESULT CreateQuotaCollection(IFsrmCommittableCollection** collection) mut => VT.[Friend]CreateQuotaCollection(&this, collection);
}

[CRepr]struct IFsrmQuotaManagerEx : IFsrmQuotaManager
{
	public new const Guid IID = .(0x4846cb01, 0xd430, 0x494f, 0xab, 0xb4, 0xb1, 0x05, 0x49, 0x99, 0xfb, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmQuotaManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FsrmEnumOptions options, int16* affected) IsAffectedByQuota;
	}


	public HRESULT IsAffectedByQuota(BSTR path, FsrmEnumOptions options, int16* affected) mut => VT.[Friend]IsAffectedByQuota(&this, path, options, affected);
}

[CRepr]struct IFsrmQuotaTemplate : IFsrmQuotaBase
{
	public new const Guid IID = .(0xa2efab31, 0x295e, 0x46bb, 0xb9, 0x76, 0xe8, 0x6d, 0x58, 0xb5, 0x2e, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmQuotaBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR quotaTemplateName) CopyTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmCommitOptions commitOptions, FsrmTemplateApplyOptions applyOptions, IFsrmDerivedObjectsResult** derivedObjectsResult) CommitAndUpdateDerived;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT CopyTemplate(BSTR quotaTemplateName) mut => VT.[Friend]CopyTemplate(&this, quotaTemplateName);

	public HRESULT CommitAndUpdateDerived(FsrmCommitOptions commitOptions, FsrmTemplateApplyOptions applyOptions, IFsrmDerivedObjectsResult** derivedObjectsResult) mut => VT.[Friend]CommitAndUpdateDerived(&this, commitOptions, applyOptions, derivedObjectsResult);
}

[CRepr]struct IFsrmQuotaTemplateImported : IFsrmQuotaTemplate
{
	public new const Guid IID = .(0x9a2bf113, 0xa329, 0x44cc, 0x80, 0x9a, 0x5c, 0x00, 0xfc, 0xe8, 0xda, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmQuotaTemplate.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* overwrite) get_OverwriteOnCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 overwrite) put_OverwriteOnCommit;
	}


	public HRESULT get_OverwriteOnCommit(int16* overwrite) mut => VT.[Friend]get_OverwriteOnCommit(&this, overwrite);

	public HRESULT put_OverwriteOnCommit(int16 overwrite) mut => VT.[Friend]put_OverwriteOnCommit(&this, overwrite);
}

[CRepr]struct IFsrmQuotaTemplateManager : IDispatch
{
	public new const Guid IID = .(0x4173ac41, 0x172d, 0x4d52, 0x96, 0x3c, 0xfd, 0xc7, 0xe4, 0x15, 0xf7, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmQuotaTemplate** quotaTemplate) CreateTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IFsrmQuotaTemplate** quotaTemplate) GetTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEnumOptions options, IFsrmCommittableCollection** quotaTemplates) EnumTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* quotaTemplateNamesArray, BSTR* serializedQuotaTemplates) ExportTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serializedQuotaTemplates, VARIANT* quotaTemplateNamesArray, IFsrmCommittableCollection** quotaTemplates) ImportTemplates;
	}


	public HRESULT CreateTemplate(IFsrmQuotaTemplate** quotaTemplate) mut => VT.[Friend]CreateTemplate(&this, quotaTemplate);

	public HRESULT GetTemplate(BSTR name, IFsrmQuotaTemplate** quotaTemplate) mut => VT.[Friend]GetTemplate(&this, name, quotaTemplate);

	public HRESULT EnumTemplates(FsrmEnumOptions options, IFsrmCommittableCollection** quotaTemplates) mut => VT.[Friend]EnumTemplates(&this, options, quotaTemplates);

	public HRESULT ExportTemplates(VARIANT* quotaTemplateNamesArray, BSTR* serializedQuotaTemplates) mut => VT.[Friend]ExportTemplates(&this, quotaTemplateNamesArray, serializedQuotaTemplates);

	public HRESULT ImportTemplates(BSTR serializedQuotaTemplates, VARIANT* quotaTemplateNamesArray, IFsrmCommittableCollection** quotaTemplates) mut => VT.[Friend]ImportTemplates(&this, serializedQuotaTemplates, quotaTemplateNamesArray, quotaTemplates);
}

[CRepr]struct IFsrmFileGroup : IFsrmObject
{
	public new const Guid IID = .(0x8dd04909, 0x0e34, 0x4d55, 0xaf, 0xaa, 0x89, 0xe1, 0xf1, 0xa1, 0xbb, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection** members) get_Members;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection* members) put_Members;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection** nonMembers) get_NonMembers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection* nonMembers) put_NonMembers;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Members(IFsrmMutableCollection** members) mut => VT.[Friend]get_Members(&this, members);

	public HRESULT put_Members(IFsrmMutableCollection* members) mut => VT.[Friend]put_Members(&this, members);

	public HRESULT get_NonMembers(IFsrmMutableCollection** nonMembers) mut => VT.[Friend]get_NonMembers(&this, nonMembers);

	public HRESULT put_NonMembers(IFsrmMutableCollection* nonMembers) mut => VT.[Friend]put_NonMembers(&this, nonMembers);
}

[CRepr]struct IFsrmFileGroupImported : IFsrmFileGroup
{
	public new const Guid IID = .(0xad55f10b, 0x5f11, 0x4be7, 0x94, 0xef, 0xd9, 0xee, 0x2e, 0x47, 0x0d, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmFileGroup.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* overwrite) get_OverwriteOnCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 overwrite) put_OverwriteOnCommit;
	}


	public HRESULT get_OverwriteOnCommit(int16* overwrite) mut => VT.[Friend]get_OverwriteOnCommit(&this, overwrite);

	public HRESULT put_OverwriteOnCommit(int16 overwrite) mut => VT.[Friend]put_OverwriteOnCommit(&this, overwrite);
}

[CRepr]struct IFsrmFileGroupManager : IDispatch
{
	public new const Guid IID = .(0x426677d5, 0x018c, 0x485c, 0x8a, 0x51, 0x20, 0xb8, 0x6d, 0x00, 0xbd, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmFileGroup** fileGroup) CreateFileGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IFsrmFileGroup** fileGroup) GetFileGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEnumOptions options, IFsrmCommittableCollection** fileGroups) EnumFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* fileGroupNamesArray, BSTR* serializedFileGroups) ExportFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serializedFileGroups, VARIANT* fileGroupNamesArray, IFsrmCommittableCollection** fileGroups) ImportFileGroups;
	}


	public HRESULT CreateFileGroup(IFsrmFileGroup** fileGroup) mut => VT.[Friend]CreateFileGroup(&this, fileGroup);

	public HRESULT GetFileGroup(BSTR name, IFsrmFileGroup** fileGroup) mut => VT.[Friend]GetFileGroup(&this, name, fileGroup);

	public HRESULT EnumFileGroups(FsrmEnumOptions options, IFsrmCommittableCollection** fileGroups) mut => VT.[Friend]EnumFileGroups(&this, options, fileGroups);

	public HRESULT ExportFileGroups(VARIANT* fileGroupNamesArray, BSTR* serializedFileGroups) mut => VT.[Friend]ExportFileGroups(&this, fileGroupNamesArray, serializedFileGroups);

	public HRESULT ImportFileGroups(BSTR serializedFileGroups, VARIANT* fileGroupNamesArray, IFsrmCommittableCollection** fileGroups) mut => VT.[Friend]ImportFileGroups(&this, serializedFileGroups, fileGroupNamesArray, fileGroups);
}

[CRepr]struct IFsrmFileScreenBase : IFsrmObject
{
	public new const Guid IID = .(0xf3637e80, 0x5b22, 0x4a2b, 0xa6, 0x37, 0xbb, 0xb6, 0x42, 0xb4, 0x1c, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection** blockList) get_BlockedFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection* blockList) put_BlockedFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* fileScreenFlags) get_FileScreenFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 fileScreenFlags) put_FileScreenFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmActionType actionType, IFsrmAction** action) CreateAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** actions) EnumActions;
	}


	public HRESULT get_BlockedFileGroups(IFsrmMutableCollection** blockList) mut => VT.[Friend]get_BlockedFileGroups(&this, blockList);

	public HRESULT put_BlockedFileGroups(IFsrmMutableCollection* blockList) mut => VT.[Friend]put_BlockedFileGroups(&this, blockList);

	public HRESULT get_FileScreenFlags(int32* fileScreenFlags) mut => VT.[Friend]get_FileScreenFlags(&this, fileScreenFlags);

	public HRESULT put_FileScreenFlags(int32 fileScreenFlags) mut => VT.[Friend]put_FileScreenFlags(&this, fileScreenFlags);

	public HRESULT CreateAction(FsrmActionType actionType, IFsrmAction** action) mut => VT.[Friend]CreateAction(&this, actionType, action);

	public HRESULT EnumActions(IFsrmCollection** actions) mut => VT.[Friend]EnumActions(&this, actions);
}

[CRepr]struct IFsrmFileScreen : IFsrmFileScreenBase
{
	public new const Guid IID = .(0x5f6325d3, 0xce88, 0x4733, 0x84, 0xc1, 0x2d, 0x6a, 0xef, 0xc5, 0xea, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmFileScreenBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* fileScreenTemplateName) get_SourceTemplateName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* matches) get_MatchesSourceTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userSid) get_UserSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userAccount) get_UserAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR fileScreenTemplateName) ApplyTemplate;
	}


	public HRESULT get_Path(BSTR* path) mut => VT.[Friend]get_Path(&this, path);

	public HRESULT get_SourceTemplateName(BSTR* fileScreenTemplateName) mut => VT.[Friend]get_SourceTemplateName(&this, fileScreenTemplateName);

	public HRESULT get_MatchesSourceTemplate(int16* matches) mut => VT.[Friend]get_MatchesSourceTemplate(&this, matches);

	public HRESULT get_UserSid(BSTR* userSid) mut => VT.[Friend]get_UserSid(&this, userSid);

	public HRESULT get_UserAccount(BSTR* userAccount) mut => VT.[Friend]get_UserAccount(&this, userAccount);

	public HRESULT ApplyTemplate(BSTR fileScreenTemplateName) mut => VT.[Friend]ApplyTemplate(&this, fileScreenTemplateName);
}

[CRepr]struct IFsrmFileScreenException : IFsrmObject
{
	public new const Guid IID = .(0xbee7ce02, 0xdf77, 0x4515, 0x93, 0x89, 0x78, 0xf0, 0x1c, 0x5a, 0xfc, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection** allowList) get_AllowedFileGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmMutableCollection* allowList) put_AllowedFileGroups;
	}


	public HRESULT get_Path(BSTR* path) mut => VT.[Friend]get_Path(&this, path);

	public HRESULT get_AllowedFileGroups(IFsrmMutableCollection** allowList) mut => VT.[Friend]get_AllowedFileGroups(&this, allowList);

	public HRESULT put_AllowedFileGroups(IFsrmMutableCollection* allowList) mut => VT.[Friend]put_AllowedFileGroups(&this, allowList);
}

[CRepr]struct IFsrmFileScreenManager : IDispatch
{
	public new const Guid IID = .(0xff4fa04e, 0x5a94, 0x4bda, 0xa3, 0xa0, 0xd5, 0xb4, 0xd3, 0xc5, 0x2e, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** variables) get_ActionVariables;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** descriptions) get_ActionVariableDescriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmFileScreen** fileScreen) CreateFileScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmFileScreen** fileScreen) GetFileScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** fileScreens) EnumFileScreens;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmFileScreenException** fileScreenException) CreateFileScreenException;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, IFsrmFileScreenException** fileScreenException) GetFileScreenException;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** fileScreenExceptions) EnumFileScreenExceptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCommittableCollection** collection) CreateFileScreenCollection;
	}


	public HRESULT get_ActionVariables(SAFEARRAY** variables) mut => VT.[Friend]get_ActionVariables(&this, variables);

	public HRESULT get_ActionVariableDescriptions(SAFEARRAY** descriptions) mut => VT.[Friend]get_ActionVariableDescriptions(&this, descriptions);

	public HRESULT CreateFileScreen(BSTR path, IFsrmFileScreen** fileScreen) mut => VT.[Friend]CreateFileScreen(&this, path, fileScreen);

	public HRESULT GetFileScreen(BSTR path, IFsrmFileScreen** fileScreen) mut => VT.[Friend]GetFileScreen(&this, path, fileScreen);

	public HRESULT EnumFileScreens(BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** fileScreens) mut => VT.[Friend]EnumFileScreens(&this, path, options, fileScreens);

	public HRESULT CreateFileScreenException(BSTR path, IFsrmFileScreenException** fileScreenException) mut => VT.[Friend]CreateFileScreenException(&this, path, fileScreenException);

	public HRESULT GetFileScreenException(BSTR path, IFsrmFileScreenException** fileScreenException) mut => VT.[Friend]GetFileScreenException(&this, path, fileScreenException);

	public HRESULT EnumFileScreenExceptions(BSTR path, FsrmEnumOptions options, IFsrmCommittableCollection** fileScreenExceptions) mut => VT.[Friend]EnumFileScreenExceptions(&this, path, options, fileScreenExceptions);

	public HRESULT CreateFileScreenCollection(IFsrmCommittableCollection** collection) mut => VT.[Friend]CreateFileScreenCollection(&this, collection);
}

[CRepr]struct IFsrmFileScreenTemplate : IFsrmFileScreenBase
{
	public new const Guid IID = .(0x205bebf8, 0xdd93, 0x452a, 0x95, 0xa6, 0x32, 0xb5, 0x66, 0xb3, 0x58, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmFileScreenBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR fileScreenTemplateName) CopyTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmCommitOptions commitOptions, FsrmTemplateApplyOptions applyOptions, IFsrmDerivedObjectsResult** derivedObjectsResult) CommitAndUpdateDerived;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT CopyTemplate(BSTR fileScreenTemplateName) mut => VT.[Friend]CopyTemplate(&this, fileScreenTemplateName);

	public HRESULT CommitAndUpdateDerived(FsrmCommitOptions commitOptions, FsrmTemplateApplyOptions applyOptions, IFsrmDerivedObjectsResult** derivedObjectsResult) mut => VT.[Friend]CommitAndUpdateDerived(&this, commitOptions, applyOptions, derivedObjectsResult);
}

[CRepr]struct IFsrmFileScreenTemplateImported : IFsrmFileScreenTemplate
{
	public new const Guid IID = .(0xe1010359, 0x3e5d, 0x4ecd, 0x9f, 0xe4, 0xef, 0x48, 0x62, 0x2f, 0xdf, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmFileScreenTemplate.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* overwrite) get_OverwriteOnCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 overwrite) put_OverwriteOnCommit;
	}


	public HRESULT get_OverwriteOnCommit(int16* overwrite) mut => VT.[Friend]get_OverwriteOnCommit(&this, overwrite);

	public HRESULT put_OverwriteOnCommit(int16 overwrite) mut => VT.[Friend]put_OverwriteOnCommit(&this, overwrite);
}

[CRepr]struct IFsrmFileScreenTemplateManager : IDispatch
{
	public new const Guid IID = .(0xcfe36cba, 0x1949, 0x4e74, 0xa1, 0x4f, 0xf1, 0xd5, 0x80, 0xce, 0xaf, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmFileScreenTemplate** fileScreenTemplate) CreateTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IFsrmFileScreenTemplate** fileScreenTemplate) GetTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEnumOptions options, IFsrmCommittableCollection** fileScreenTemplates) EnumTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* fileScreenTemplateNamesArray, BSTR* serializedFileScreenTemplates) ExportTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serializedFileScreenTemplates, VARIANT* fileScreenTemplateNamesArray, IFsrmCommittableCollection** fileScreenTemplates) ImportTemplates;
	}


	public HRESULT CreateTemplate(IFsrmFileScreenTemplate** fileScreenTemplate) mut => VT.[Friend]CreateTemplate(&this, fileScreenTemplate);

	public HRESULT GetTemplate(BSTR name, IFsrmFileScreenTemplate** fileScreenTemplate) mut => VT.[Friend]GetTemplate(&this, name, fileScreenTemplate);

	public HRESULT EnumTemplates(FsrmEnumOptions options, IFsrmCommittableCollection** fileScreenTemplates) mut => VT.[Friend]EnumTemplates(&this, options, fileScreenTemplates);

	public HRESULT ExportTemplates(VARIANT* fileScreenTemplateNamesArray, BSTR* serializedFileScreenTemplates) mut => VT.[Friend]ExportTemplates(&this, fileScreenTemplateNamesArray, serializedFileScreenTemplates);

	public HRESULT ImportTemplates(BSTR serializedFileScreenTemplates, VARIANT* fileScreenTemplateNamesArray, IFsrmCommittableCollection** fileScreenTemplates) mut => VT.[Friend]ImportTemplates(&this, serializedFileScreenTemplates, fileScreenTemplateNamesArray, fileScreenTemplates);
}

[CRepr]struct IFsrmReportManager : IDispatch
{
	public new const Guid IID = .(0x27b899fe, 0x6ffa, 0x4481, 0xa1, 0x84, 0xd3, 0xda, 0xad, 0xe8, 0xa0, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEnumOptions options, IFsrmCollection** reportJobs) EnumReportJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmReportJob** reportJob) CreateReportJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR taskName, IFsrmReportJob** reportJob) GetReportJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportGenerationContext context, BSTR* path) GetOutputDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportGenerationContext context, BSTR path) SetOutputDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportType reportType, FsrmReportFilter filter, int16* valid) IsFilterValidForReportType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportType reportType, FsrmReportFilter filter, VARIANT* filterValue) GetDefaultFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportType reportType, FsrmReportFilter filter, VARIANT filterValue) SetDefaultFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportLimit limit, VARIANT* limitValue) GetReportSizeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportLimit limit, VARIANT limitValue) SetReportSizeLimit;
	}


	public HRESULT EnumReportJobs(FsrmEnumOptions options, IFsrmCollection** reportJobs) mut => VT.[Friend]EnumReportJobs(&this, options, reportJobs);

	public HRESULT CreateReportJob(IFsrmReportJob** reportJob) mut => VT.[Friend]CreateReportJob(&this, reportJob);

	public HRESULT GetReportJob(BSTR taskName, IFsrmReportJob** reportJob) mut => VT.[Friend]GetReportJob(&this, taskName, reportJob);

	public HRESULT GetOutputDirectory(FsrmReportGenerationContext context, BSTR* path) mut => VT.[Friend]GetOutputDirectory(&this, context, path);

	public HRESULT SetOutputDirectory(FsrmReportGenerationContext context, BSTR path) mut => VT.[Friend]SetOutputDirectory(&this, context, path);

	public HRESULT IsFilterValidForReportType(FsrmReportType reportType, FsrmReportFilter filter, int16* valid) mut => VT.[Friend]IsFilterValidForReportType(&this, reportType, filter, valid);

	public HRESULT GetDefaultFilter(FsrmReportType reportType, FsrmReportFilter filter, VARIANT* filterValue) mut => VT.[Friend]GetDefaultFilter(&this, reportType, filter, filterValue);

	public HRESULT SetDefaultFilter(FsrmReportType reportType, FsrmReportFilter filter, VARIANT filterValue) mut => VT.[Friend]SetDefaultFilter(&this, reportType, filter, filterValue);

	public HRESULT GetReportSizeLimit(FsrmReportLimit limit, VARIANT* limitValue) mut => VT.[Friend]GetReportSizeLimit(&this, limit, limitValue);

	public HRESULT SetReportSizeLimit(FsrmReportLimit limit, VARIANT limitValue) mut => VT.[Friend]SetReportSizeLimit(&this, limit, limitValue);
}

[CRepr]struct IFsrmReportJob : IFsrmObject
{
	public new const Guid IID = .(0x38e87280, 0x715c, 0x4c7d, 0xa2, 0x80, 0xea, 0x16, 0x51, 0xa1, 0x9f, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* taskName) get_Task;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR taskName) put_Task;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** namespaceRoots) get_NamespaceRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* namespaceRoots) put_NamespaceRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** formats) get_Formats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* formats) put_Formats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailTo) get_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailTo) put_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportRunningStatus* runningStatus) get_RunningStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastRun) get_LastRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* lastError) get_LastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_LastGeneratedInDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** reports) EnumReports;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportType reportType, IFsrmReport** report) CreateReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportGenerationContext context) Run;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 waitSeconds, int16* completed) WaitForCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT get_Task(BSTR* taskName) mut => VT.[Friend]get_Task(&this, taskName);

	public HRESULT put_Task(BSTR taskName) mut => VT.[Friend]put_Task(&this, taskName);

	public HRESULT get_NamespaceRoots(SAFEARRAY** namespaceRoots) mut => VT.[Friend]get_NamespaceRoots(&this, namespaceRoots);

	public HRESULT put_NamespaceRoots(SAFEARRAY* namespaceRoots) mut => VT.[Friend]put_NamespaceRoots(&this, namespaceRoots);

	public HRESULT get_Formats(SAFEARRAY** formats) mut => VT.[Friend]get_Formats(&this, formats);

	public HRESULT put_Formats(SAFEARRAY* formats) mut => VT.[Friend]put_Formats(&this, formats);

	public HRESULT get_MailTo(BSTR* mailTo) mut => VT.[Friend]get_MailTo(&this, mailTo);

	public HRESULT put_MailTo(BSTR mailTo) mut => VT.[Friend]put_MailTo(&this, mailTo);

	public HRESULT get_RunningStatus(FsrmReportRunningStatus* runningStatus) mut => VT.[Friend]get_RunningStatus(&this, runningStatus);

	public HRESULT get_LastRun(double* lastRun) mut => VT.[Friend]get_LastRun(&this, lastRun);

	public HRESULT get_LastError(BSTR* lastError) mut => VT.[Friend]get_LastError(&this, lastError);

	public HRESULT get_LastGeneratedInDirectory(BSTR* path) mut => VT.[Friend]get_LastGeneratedInDirectory(&this, path);

	public HRESULT EnumReports(IFsrmCollection** reports) mut => VT.[Friend]EnumReports(&this, reports);

	public HRESULT CreateReport(FsrmReportType reportType, IFsrmReport** report) mut => VT.[Friend]CreateReport(&this, reportType, report);

	public HRESULT Run(FsrmReportGenerationContext context) mut => VT.[Friend]Run(&this, context);

	public HRESULT WaitForCompletion(int32 waitSeconds, int16* completed) mut => VT.[Friend]WaitForCompletion(&this, waitSeconds, completed);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IFsrmReport : IDispatch
{
	public new const Guid IID = .(0xd8cc81d9, 0x46b8, 0x4fa4, 0xbf, 0xa5, 0x4a, 0xa9, 0xde, 0xc9, 0xb6, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportType* reportType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR description) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* prefix) get_LastGeneratedFileNamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportFilter filter, VARIANT* filterValue) GetFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportFilter filter, VARIANT filterValue) SetFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_Type(FsrmReportType* reportType) mut => VT.[Friend]get_Type(&this, reportType);

	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Description(BSTR* description) mut => VT.[Friend]get_Description(&this, description);

	public HRESULT put_Description(BSTR description) mut => VT.[Friend]put_Description(&this, description);

	public HRESULT get_LastGeneratedFileNamePrefix(BSTR* prefix) mut => VT.[Friend]get_LastGeneratedFileNamePrefix(&this, prefix);

	public HRESULT GetFilter(FsrmReportFilter filter, VARIANT* filterValue) mut => VT.[Friend]GetFilter(&this, filter, filterValue);

	public HRESULT SetFilter(FsrmReportFilter filter, VARIANT filterValue) mut => VT.[Friend]SetFilter(&this, filter, filterValue);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IFsrmReportScheduler : IDispatch
{
	public new const Guid IID = .(0x6879caf9, 0x6617, 0x4484, 0x87, 0x19, 0x71, 0xc3, 0xd8, 0x64, 0x5f, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* namespacesSafeArray) VerifyNamespaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR taskName, VARIANT* namespacesSafeArray, BSTR serializedTask) CreateScheduleTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR taskName, VARIANT* namespacesSafeArray, BSTR serializedTask) ModifyScheduleTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR taskName) DeleteScheduleTask;
	}


	public HRESULT VerifyNamespaces(VARIANT* namespacesSafeArray) mut => VT.[Friend]VerifyNamespaces(&this, namespacesSafeArray);

	public HRESULT CreateScheduleTask(BSTR taskName, VARIANT* namespacesSafeArray, BSTR serializedTask) mut => VT.[Friend]CreateScheduleTask(&this, taskName, namespacesSafeArray, serializedTask);

	public HRESULT ModifyScheduleTask(BSTR taskName, VARIANT* namespacesSafeArray, BSTR serializedTask) mut => VT.[Friend]ModifyScheduleTask(&this, taskName, namespacesSafeArray, serializedTask);

	public HRESULT DeleteScheduleTask(BSTR taskName) mut => VT.[Friend]DeleteScheduleTask(&this, taskName);
}

[CRepr]struct IFsrmFileManagementJobManager : IDispatch
{
	public new const Guid IID = .(0xee321ecb, 0xd95e, 0x48e9, 0x90, 0x7c, 0xc7, 0x68, 0x5a, 0x01, 0x32, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** variables) get_ActionVariables;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** descriptions) get_ActionVariableDescriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEnumOptions options, IFsrmCollection** fileManagementJobs) EnumFileManagementJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmFileManagementJob** fileManagementJob) CreateFileManagementJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IFsrmFileManagementJob** fileManagementJob) GetFileManagementJob;
	}


	public HRESULT get_ActionVariables(SAFEARRAY** variables) mut => VT.[Friend]get_ActionVariables(&this, variables);

	public HRESULT get_ActionVariableDescriptions(SAFEARRAY** descriptions) mut => VT.[Friend]get_ActionVariableDescriptions(&this, descriptions);

	public HRESULT EnumFileManagementJobs(FsrmEnumOptions options, IFsrmCollection** fileManagementJobs) mut => VT.[Friend]EnumFileManagementJobs(&this, options, fileManagementJobs);

	public HRESULT CreateFileManagementJob(IFsrmFileManagementJob** fileManagementJob) mut => VT.[Friend]CreateFileManagementJob(&this, fileManagementJob);

	public HRESULT GetFileManagementJob(BSTR name, IFsrmFileManagementJob** fileManagementJob) mut => VT.[Friend]GetFileManagementJob(&this, name, fileManagementJob);
}

[CRepr]struct IFsrmFileManagementJob : IFsrmObject
{
	public new const Guid IID = .(0x0770687e, 0x9f36, 0x4d6f, 0x87, 0x78, 0x59, 0x9d, 0x18, 0x84, 0x61, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** namespaceRoots) get_NamespaceRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* namespaceRoots) put_NamespaceRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmFileManagementType* operationType) get_OperationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmFileManagementType operationType) put_OperationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* expirationDirectory) get_ExpirationDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR expirationDirectory) put_ExpirationDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmActionCommand** action) get_CustomAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** notifications) get_Notifications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* loggingFlags) get_Logging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 loggingFlags) put_Logging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* reportEnabled) get_ReportEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 reportEnabled) put_ReportEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** formats) get_Formats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* formats) put_Formats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailTo) get_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailTo) put_MailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* daysSinceCreation) get_DaysSinceFileCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 daysSinceCreation) put_DaysSinceFileCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* daysSinceAccess) get_DaysSinceFileLastAccessed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 daysSinceAccess) put_DaysSinceFileLastAccessed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* daysSinceModify) get_DaysSinceFileLastModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 daysSinceModify) put_DaysSinceFileLastModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** propertyConditions) get_PropertyConditions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* fromDate) get_FromDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double fromDate) put_FromDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* taskName) get_Task;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR taskName) put_Task;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** parameters) get_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* parameters) put_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportRunningStatus* runningStatus) get_RunningStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* lastError) get_LastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_LastReportPathWithoutExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastRun) get_LastRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* fileNamePattern) get_FileNamePattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR fileNamePattern) put_FileNamePattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportGenerationContext context) Run;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 waitSeconds, int16* completed) WaitForCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 days) AddNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 days) DeleteNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 days, int32 newDays) ModifyNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 days, FsrmActionType actionType, IFsrmAction** action) CreateNotificationAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 days, IFsrmCollection** actions) EnumNotificationActions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IFsrmPropertyCondition** propertyCondition) CreatePropertyCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmActionCommand** customAction) CreateCustomAction;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_NamespaceRoots(SAFEARRAY** namespaceRoots) mut => VT.[Friend]get_NamespaceRoots(&this, namespaceRoots);

	public HRESULT put_NamespaceRoots(SAFEARRAY* namespaceRoots) mut => VT.[Friend]put_NamespaceRoots(&this, namespaceRoots);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_OperationType(FsrmFileManagementType* operationType) mut => VT.[Friend]get_OperationType(&this, operationType);

	public HRESULT put_OperationType(FsrmFileManagementType operationType) mut => VT.[Friend]put_OperationType(&this, operationType);

	public HRESULT get_ExpirationDirectory(BSTR* expirationDirectory) mut => VT.[Friend]get_ExpirationDirectory(&this, expirationDirectory);

	public HRESULT put_ExpirationDirectory(BSTR expirationDirectory) mut => VT.[Friend]put_ExpirationDirectory(&this, expirationDirectory);

	public HRESULT get_CustomAction(IFsrmActionCommand** action) mut => VT.[Friend]get_CustomAction(&this, action);

	public HRESULT get_Notifications(SAFEARRAY** notifications) mut => VT.[Friend]get_Notifications(&this, notifications);

	public HRESULT get_Logging(int32* loggingFlags) mut => VT.[Friend]get_Logging(&this, loggingFlags);

	public HRESULT put_Logging(int32 loggingFlags) mut => VT.[Friend]put_Logging(&this, loggingFlags);

	public HRESULT get_ReportEnabled(int16* reportEnabled) mut => VT.[Friend]get_ReportEnabled(&this, reportEnabled);

	public HRESULT put_ReportEnabled(int16 reportEnabled) mut => VT.[Friend]put_ReportEnabled(&this, reportEnabled);

	public HRESULT get_Formats(SAFEARRAY** formats) mut => VT.[Friend]get_Formats(&this, formats);

	public HRESULT put_Formats(SAFEARRAY* formats) mut => VT.[Friend]put_Formats(&this, formats);

	public HRESULT get_MailTo(BSTR* mailTo) mut => VT.[Friend]get_MailTo(&this, mailTo);

	public HRESULT put_MailTo(BSTR mailTo) mut => VT.[Friend]put_MailTo(&this, mailTo);

	public HRESULT get_DaysSinceFileCreated(int32* daysSinceCreation) mut => VT.[Friend]get_DaysSinceFileCreated(&this, daysSinceCreation);

	public HRESULT put_DaysSinceFileCreated(int32 daysSinceCreation) mut => VT.[Friend]put_DaysSinceFileCreated(&this, daysSinceCreation);

	public HRESULT get_DaysSinceFileLastAccessed(int32* daysSinceAccess) mut => VT.[Friend]get_DaysSinceFileLastAccessed(&this, daysSinceAccess);

	public HRESULT put_DaysSinceFileLastAccessed(int32 daysSinceAccess) mut => VT.[Friend]put_DaysSinceFileLastAccessed(&this, daysSinceAccess);

	public HRESULT get_DaysSinceFileLastModified(int32* daysSinceModify) mut => VT.[Friend]get_DaysSinceFileLastModified(&this, daysSinceModify);

	public HRESULT put_DaysSinceFileLastModified(int32 daysSinceModify) mut => VT.[Friend]put_DaysSinceFileLastModified(&this, daysSinceModify);

	public HRESULT get_PropertyConditions(IFsrmCollection** propertyConditions) mut => VT.[Friend]get_PropertyConditions(&this, propertyConditions);

	public HRESULT get_FromDate(double* fromDate) mut => VT.[Friend]get_FromDate(&this, fromDate);

	public HRESULT put_FromDate(double fromDate) mut => VT.[Friend]put_FromDate(&this, fromDate);

	public HRESULT get_Task(BSTR* taskName) mut => VT.[Friend]get_Task(&this, taskName);

	public HRESULT put_Task(BSTR taskName) mut => VT.[Friend]put_Task(&this, taskName);

	public HRESULT get_Parameters(SAFEARRAY** parameters) mut => VT.[Friend]get_Parameters(&this, parameters);

	public HRESULT put_Parameters(SAFEARRAY* parameters) mut => VT.[Friend]put_Parameters(&this, parameters);

	public HRESULT get_RunningStatus(FsrmReportRunningStatus* runningStatus) mut => VT.[Friend]get_RunningStatus(&this, runningStatus);

	public HRESULT get_LastError(BSTR* lastError) mut => VT.[Friend]get_LastError(&this, lastError);

	public HRESULT get_LastReportPathWithoutExtension(BSTR* path) mut => VT.[Friend]get_LastReportPathWithoutExtension(&this, path);

	public HRESULT get_LastRun(double* lastRun) mut => VT.[Friend]get_LastRun(&this, lastRun);

	public HRESULT get_FileNamePattern(BSTR* fileNamePattern) mut => VT.[Friend]get_FileNamePattern(&this, fileNamePattern);

	public HRESULT put_FileNamePattern(BSTR fileNamePattern) mut => VT.[Friend]put_FileNamePattern(&this, fileNamePattern);

	public HRESULT Run(FsrmReportGenerationContext context) mut => VT.[Friend]Run(&this, context);

	public HRESULT WaitForCompletion(int32 waitSeconds, int16* completed) mut => VT.[Friend]WaitForCompletion(&this, waitSeconds, completed);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT AddNotification(int32 days) mut => VT.[Friend]AddNotification(&this, days);

	public HRESULT DeleteNotification(int32 days) mut => VT.[Friend]DeleteNotification(&this, days);

	public HRESULT ModifyNotification(int32 days, int32 newDays) mut => VT.[Friend]ModifyNotification(&this, days, newDays);

	public HRESULT CreateNotificationAction(int32 days, FsrmActionType actionType, IFsrmAction** action) mut => VT.[Friend]CreateNotificationAction(&this, days, actionType, action);

	public HRESULT EnumNotificationActions(int32 days, IFsrmCollection** actions) mut => VT.[Friend]EnumNotificationActions(&this, days, actions);

	public HRESULT CreatePropertyCondition(BSTR name, IFsrmPropertyCondition** propertyCondition) mut => VT.[Friend]CreatePropertyCondition(&this, name, propertyCondition);

	public HRESULT CreateCustomAction(IFsrmActionCommand** customAction) mut => VT.[Friend]CreateCustomAction(&this, customAction);
}

[CRepr]struct IFsrmPropertyCondition : IDispatch
{
	public new const Guid IID = .(0x326af66f, 0x2ac0, 0x4f68, 0xbf, 0x8c, 0x47, 0x59, 0xf0, 0x54, 0xfa, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyConditionType* type) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyConditionType type) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* value) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR value) put_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Type(FsrmPropertyConditionType* type) mut => VT.[Friend]get_Type(&this, type);

	public HRESULT put_Type(FsrmPropertyConditionType type) mut => VT.[Friend]put_Type(&this, type);

	public HRESULT get_Value(BSTR* value) mut => VT.[Friend]get_Value(&this, value);

	public HRESULT put_Value(BSTR value) mut => VT.[Friend]put_Value(&this, value);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IFsrmFileCondition : IDispatch
{
	public new const Guid IID = .(0x70684ffc, 0x691a, 0x4a1a, 0xb9, 0x22, 0x97, 0x75, 0x2e, 0x13, 0x8c, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmFileConditionType* pVal) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_Type(FsrmFileConditionType* pVal) mut => VT.[Friend]get_Type(&this, pVal);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IFsrmFileConditionProperty : IFsrmFileCondition
{
	public new const Guid IID = .(0x81926775, 0xb981, 0x4479, 0x98, 0x8f, 0xda, 0x17, 0x1d, 0x62, 0x73, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmFileCondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_PropertyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_PropertyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmFileSystemPropertyId* pVal) get_PropertyId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmFileSystemPropertyId newVal) put_PropertyId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyConditionType* pVal) get_Operator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyConditionType newVal) put_Operator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyValueType* pVal) get_ValueType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyValueType newVal) put_ValueType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT newVal) put_Value;
	}


	public HRESULT get_PropertyName(BSTR* pVal) mut => VT.[Friend]get_PropertyName(&this, pVal);

	public HRESULT put_PropertyName(BSTR newVal) mut => VT.[Friend]put_PropertyName(&this, newVal);

	public HRESULT get_PropertyId(FsrmFileSystemPropertyId* pVal) mut => VT.[Friend]get_PropertyId(&this, pVal);

	public HRESULT put_PropertyId(FsrmFileSystemPropertyId newVal) mut => VT.[Friend]put_PropertyId(&this, newVal);

	public HRESULT get_Operator(FsrmPropertyConditionType* pVal) mut => VT.[Friend]get_Operator(&this, pVal);

	public HRESULT put_Operator(FsrmPropertyConditionType newVal) mut => VT.[Friend]put_Operator(&this, newVal);

	public HRESULT get_ValueType(FsrmPropertyValueType* pVal) mut => VT.[Friend]get_ValueType(&this, pVal);

	public HRESULT put_ValueType(FsrmPropertyValueType newVal) mut => VT.[Friend]put_ValueType(&this, newVal);

	public HRESULT get_Value(VARIANT* pVal) mut => VT.[Friend]get_Value(&this, pVal);

	public HRESULT put_Value(VARIANT newVal) mut => VT.[Friend]put_Value(&this, newVal);
}

[CRepr]struct IFsrmPropertyDefinition : IFsrmObject
{
	public new const Guid IID = .(0xede0150f, 0xe9a3, 0x419c, 0x87, 0x7c, 0x01, 0xfe, 0x5d, 0x24, 0xc5, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyDefinitionType* type) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyDefinitionType type) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** possibleValues) get_PossibleValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* possibleValues) put_PossibleValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** valueDescriptions) get_ValueDescriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* valueDescriptions) put_ValueDescriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** parameters) get_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* parameters) put_Parameters;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Type(FsrmPropertyDefinitionType* type) mut => VT.[Friend]get_Type(&this, type);

	public HRESULT put_Type(FsrmPropertyDefinitionType type) mut => VT.[Friend]put_Type(&this, type);

	public HRESULT get_PossibleValues(SAFEARRAY** possibleValues) mut => VT.[Friend]get_PossibleValues(&this, possibleValues);

	public HRESULT put_PossibleValues(SAFEARRAY* possibleValues) mut => VT.[Friend]put_PossibleValues(&this, possibleValues);

	public HRESULT get_ValueDescriptions(SAFEARRAY** valueDescriptions) mut => VT.[Friend]get_ValueDescriptions(&this, valueDescriptions);

	public HRESULT put_ValueDescriptions(SAFEARRAY* valueDescriptions) mut => VT.[Friend]put_ValueDescriptions(&this, valueDescriptions);

	public HRESULT get_Parameters(SAFEARRAY** parameters) mut => VT.[Friend]get_Parameters(&this, parameters);

	public HRESULT put_Parameters(SAFEARRAY* parameters) mut => VT.[Friend]put_Parameters(&this, parameters);
}

[CRepr]struct IFsrmPropertyDefinition2 : IFsrmPropertyDefinition
{
	public new const Guid IID = .(0x47782152, 0xd16c, 0x4229, 0xb4, 0xe1, 0x0d, 0xdf, 0xe3, 0x08, 0xb9, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmPropertyDefinition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* propertyDefinitionFlags) get_PropertyDefinitionFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* appliesTo) get_AppliesTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** valueDefinitions) get_ValueDefinitions;
	}


	public HRESULT get_PropertyDefinitionFlags(int32* propertyDefinitionFlags) mut => VT.[Friend]get_PropertyDefinitionFlags(&this, propertyDefinitionFlags);

	public HRESULT get_DisplayName(BSTR* name) mut => VT.[Friend]get_DisplayName(&this, name);

	public HRESULT put_DisplayName(BSTR name) mut => VT.[Friend]put_DisplayName(&this, name);

	public HRESULT get_AppliesTo(int32* appliesTo) mut => VT.[Friend]get_AppliesTo(&this, appliesTo);

	public HRESULT get_ValueDefinitions(IFsrmCollection** valueDefinitions) mut => VT.[Friend]get_ValueDefinitions(&this, valueDefinitions);
}

[CRepr]struct IFsrmPropertyDefinitionValue : IDispatch
{
	public new const Guid IID = .(0xe946d148, 0xbd67, 0x4178, 0x8e, 0x22, 0x1c, 0x44, 0x92, 0x5e, 0xd7, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* displayName) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* uniqueID) get_UniqueID;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT get_DisplayName(BSTR* displayName) mut => VT.[Friend]get_DisplayName(&this, displayName);

	public HRESULT get_Description(BSTR* description) mut => VT.[Friend]get_Description(&this, description);

	public HRESULT get_UniqueID(BSTR* uniqueID) mut => VT.[Friend]get_UniqueID(&this, uniqueID);
}

[CRepr]struct IFsrmProperty : IDispatch
{
	public new const Guid IID = .(0x4a73fee4, 0x4102, 0x4fcc, 0x9f, 0xfb, 0x38, 0x61, 0x4f, 0x9e, 0xe7, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* value) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** sources) get_Sources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* flags) get_PropertyFlags;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT get_Value(BSTR* value) mut => VT.[Friend]get_Value(&this, value);

	public HRESULT get_Sources(SAFEARRAY** sources) mut => VT.[Friend]get_Sources(&this, sources);

	public HRESULT get_PropertyFlags(int32* flags) mut => VT.[Friend]get_PropertyFlags(&this, flags);
}

[CRepr]struct IFsrmRule : IFsrmObject
{
	public new const Guid IID = .(0xcb0df960, 0x16f5, 0x4495, 0x90, 0x79, 0x3f, 0x93, 0x60, 0xd8, 0x31, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmRuleType* ruleType) get_RuleType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* moduleDefinitionName) get_ModuleDefinitionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR moduleDefinitionName) put_ModuleDefinitionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** namespaceRoots) get_NamespaceRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* namespaceRoots) put_NamespaceRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* ruleFlags) get_RuleFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ruleFlags) put_RuleFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** parameters) get_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* parameters) put_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* lastModified) get_LastModified;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_RuleType(FsrmRuleType* ruleType) mut => VT.[Friend]get_RuleType(&this, ruleType);

	public HRESULT get_ModuleDefinitionName(BSTR* moduleDefinitionName) mut => VT.[Friend]get_ModuleDefinitionName(&this, moduleDefinitionName);

	public HRESULT put_ModuleDefinitionName(BSTR moduleDefinitionName) mut => VT.[Friend]put_ModuleDefinitionName(&this, moduleDefinitionName);

	public HRESULT get_NamespaceRoots(SAFEARRAY** namespaceRoots) mut => VT.[Friend]get_NamespaceRoots(&this, namespaceRoots);

	public HRESULT put_NamespaceRoots(SAFEARRAY* namespaceRoots) mut => VT.[Friend]put_NamespaceRoots(&this, namespaceRoots);

	public HRESULT get_RuleFlags(int32* ruleFlags) mut => VT.[Friend]get_RuleFlags(&this, ruleFlags);

	public HRESULT put_RuleFlags(int32 ruleFlags) mut => VT.[Friend]put_RuleFlags(&this, ruleFlags);

	public HRESULT get_Parameters(SAFEARRAY** parameters) mut => VT.[Friend]get_Parameters(&this, parameters);

	public HRESULT put_Parameters(SAFEARRAY* parameters) mut => VT.[Friend]put_Parameters(&this, parameters);

	public HRESULT get_LastModified(VARIANT* lastModified) mut => VT.[Friend]get_LastModified(&this, lastModified);
}

[CRepr]struct IFsrmClassificationRule : IFsrmRule
{
	public new const Guid IID = .(0xafc052c2, 0x5315, 0x45ab, 0x84, 0x1b, 0xc6, 0xdb, 0x0e, 0x12, 0x01, 0x48);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmRule.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmExecutionOption* executionOption) get_ExecutionOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmExecutionOption executionOption) put_ExecutionOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* property) get_PropertyAffected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR property) put_PropertyAffected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* value) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR value) put_Value;
	}


	public HRESULT get_ExecutionOption(FsrmExecutionOption* executionOption) mut => VT.[Friend]get_ExecutionOption(&this, executionOption);

	public HRESULT put_ExecutionOption(FsrmExecutionOption executionOption) mut => VT.[Friend]put_ExecutionOption(&this, executionOption);

	public HRESULT get_PropertyAffected(BSTR* property) mut => VT.[Friend]get_PropertyAffected(&this, property);

	public HRESULT put_PropertyAffected(BSTR property) mut => VT.[Friend]put_PropertyAffected(&this, property);

	public HRESULT get_Value(BSTR* value) mut => VT.[Friend]get_Value(&this, value);

	public HRESULT put_Value(BSTR value) mut => VT.[Friend]put_Value(&this, value);
}

[CRepr]struct IFsrmPipelineModuleDefinition : IFsrmObject
{
	public new const Guid IID = .(0x515c1277, 0x2c81, 0x440e, 0x8f, 0xcf, 0x36, 0x79, 0x21, 0xed, 0x4f, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* moduleClsid) get_ModuleClsid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR moduleClsid) put_ModuleClsid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* company) get_Company;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR company) put_Company;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* version) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR version) put_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPipelineModuleType* moduleType) get_ModuleType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* needsFileContent) get_NeedsFileContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 needsFileContent) put_NeedsFileContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmAccountType* retrievalAccount) get_Account;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmAccountType retrievalAccount) put_Account;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** supportedExtensions) get_SupportedExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* supportedExtensions) put_SupportedExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** parameters) get_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* parameters) put_Parameters;
	}


	public HRESULT get_ModuleClsid(BSTR* moduleClsid) mut => VT.[Friend]get_ModuleClsid(&this, moduleClsid);

	public HRESULT put_ModuleClsid(BSTR moduleClsid) mut => VT.[Friend]put_ModuleClsid(&this, moduleClsid);

	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT put_Name(BSTR name) mut => VT.[Friend]put_Name(&this, name);

	public HRESULT get_Company(BSTR* company) mut => VT.[Friend]get_Company(&this, company);

	public HRESULT put_Company(BSTR company) mut => VT.[Friend]put_Company(&this, company);

	public HRESULT get_Version(BSTR* version) mut => VT.[Friend]get_Version(&this, version);

	public HRESULT put_Version(BSTR version) mut => VT.[Friend]put_Version(&this, version);

	public HRESULT get_ModuleType(FsrmPipelineModuleType* moduleType) mut => VT.[Friend]get_ModuleType(&this, moduleType);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_NeedsFileContent(int16* needsFileContent) mut => VT.[Friend]get_NeedsFileContent(&this, needsFileContent);

	public HRESULT put_NeedsFileContent(int16 needsFileContent) mut => VT.[Friend]put_NeedsFileContent(&this, needsFileContent);

	public HRESULT get_Account(FsrmAccountType* retrievalAccount) mut => VT.[Friend]get_Account(&this, retrievalAccount);

	public HRESULT put_Account(FsrmAccountType retrievalAccount) mut => VT.[Friend]put_Account(&this, retrievalAccount);

	public HRESULT get_SupportedExtensions(SAFEARRAY** supportedExtensions) mut => VT.[Friend]get_SupportedExtensions(&this, supportedExtensions);

	public HRESULT put_SupportedExtensions(SAFEARRAY* supportedExtensions) mut => VT.[Friend]put_SupportedExtensions(&this, supportedExtensions);

	public HRESULT get_Parameters(SAFEARRAY** parameters) mut => VT.[Friend]get_Parameters(&this, parameters);

	public HRESULT put_Parameters(SAFEARRAY* parameters) mut => VT.[Friend]put_Parameters(&this, parameters);
}

[CRepr]struct IFsrmClassifierModuleDefinition : IFsrmPipelineModuleDefinition
{
	public new const Guid IID = .(0xbb36ea26, 0x6318, 0x4b8c, 0x85, 0x92, 0xf7, 0x2d, 0xd6, 0x02, 0xe7, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmPipelineModuleDefinition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** propertiesAffected) get_PropertiesAffected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* propertiesAffected) put_PropertiesAffected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** propertiesUsed) get_PropertiesUsed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* propertiesUsed) put_PropertiesUsed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* needsExplicitValue) get_NeedsExplicitValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 needsExplicitValue) put_NeedsExplicitValue;
	}


	public HRESULT get_PropertiesAffected(SAFEARRAY** propertiesAffected) mut => VT.[Friend]get_PropertiesAffected(&this, propertiesAffected);

	public HRESULT put_PropertiesAffected(SAFEARRAY* propertiesAffected) mut => VT.[Friend]put_PropertiesAffected(&this, propertiesAffected);

	public HRESULT get_PropertiesUsed(SAFEARRAY** propertiesUsed) mut => VT.[Friend]get_PropertiesUsed(&this, propertiesUsed);

	public HRESULT put_PropertiesUsed(SAFEARRAY* propertiesUsed) mut => VT.[Friend]put_PropertiesUsed(&this, propertiesUsed);

	public HRESULT get_NeedsExplicitValue(int16* needsExplicitValue) mut => VT.[Friend]get_NeedsExplicitValue(&this, needsExplicitValue);

	public HRESULT put_NeedsExplicitValue(int16 needsExplicitValue) mut => VT.[Friend]put_NeedsExplicitValue(&this, needsExplicitValue);
}

[CRepr]struct IFsrmStorageModuleDefinition : IFsrmPipelineModuleDefinition
{
	public new const Guid IID = .(0x15a81350, 0x497d, 0x4aba, 0x80, 0xe9, 0xd4, 0xdb, 0xcc, 0x55, 0x21, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmPipelineModuleDefinition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmStorageModuleCaps* capabilities) get_Capabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmStorageModuleCaps capabilities) put_Capabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmStorageModuleType* storageType) get_StorageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmStorageModuleType storageType) put_StorageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* updatesFileContent) get_UpdatesFileContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 updatesFileContent) put_UpdatesFileContent;
	}


	public HRESULT get_Capabilities(FsrmStorageModuleCaps* capabilities) mut => VT.[Friend]get_Capabilities(&this, capabilities);

	public HRESULT put_Capabilities(FsrmStorageModuleCaps capabilities) mut => VT.[Friend]put_Capabilities(&this, capabilities);

	public HRESULT get_StorageType(FsrmStorageModuleType* storageType) mut => VT.[Friend]get_StorageType(&this, storageType);

	public HRESULT put_StorageType(FsrmStorageModuleType storageType) mut => VT.[Friend]put_StorageType(&this, storageType);

	public HRESULT get_UpdatesFileContent(int16* updatesFileContent) mut => VT.[Friend]get_UpdatesFileContent(&this, updatesFileContent);

	public HRESULT put_UpdatesFileContent(int16 updatesFileContent) mut => VT.[Friend]put_UpdatesFileContent(&this, updatesFileContent);
}

[CRepr]struct IFsrmClassificationManager : IDispatch
{
	public new const Guid IID = .(0xd2dc89da, 0xee91, 0x48a0, 0x85, 0xd8, 0xcc, 0x72, 0xa5, 0x6f, 0x7d, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** formats) get_ClassificationReportFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* formats) put_ClassificationReportFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* logging) get_Logging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 logging) put_Logging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mailTo) get_ClassificationReportMailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR mailTo) put_ClassificationReportMailTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* reportEnabled) get_ClassificationReportEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 reportEnabled) put_ClassificationReportEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* lastReportPath) get_ClassificationLastReportPathWithoutExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* lastError) get_ClassificationLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportRunningStatus* runningStatus) get_ClassificationRunningStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmEnumOptions options, IFsrmCollection** propertyDefinitions) EnumPropertyDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPropertyDefinition** propertyDefinition) CreatePropertyDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR propertyName, IFsrmPropertyDefinition** propertyDefinition) GetPropertyDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmRuleType ruleType, FsrmEnumOptions options, IFsrmCollection** Rules) EnumRules;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmRuleType ruleType, IFsrmRule** Rule) CreateRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ruleName, FsrmRuleType ruleType, IFsrmRule** Rule) GetRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPipelineModuleType moduleType, FsrmEnumOptions options, IFsrmCollection** moduleDefinitions) EnumModuleDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPipelineModuleType moduleType, IFsrmPipelineModuleDefinition** moduleDefinition) CreateModuleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR moduleName, FsrmPipelineModuleType moduleType, IFsrmPipelineModuleDefinition** moduleDefinition) GetModuleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmReportGenerationContext context, BSTR reserved) RunClassification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 waitSeconds, int16* completed) WaitForClassificationCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelClassification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, FsrmGetFilePropertyOptions options, IFsrmCollection** fileProperties) EnumFileProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, BSTR propertyName, FsrmGetFilePropertyOptions options, IFsrmProperty** property) GetFileProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, BSTR propertyName, BSTR propertyValue) SetFileProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filePath, BSTR property) ClearFileProperty;
	}


	public HRESULT get_ClassificationReportFormats(SAFEARRAY** formats) mut => VT.[Friend]get_ClassificationReportFormats(&this, formats);

	public HRESULT put_ClassificationReportFormats(SAFEARRAY* formats) mut => VT.[Friend]put_ClassificationReportFormats(&this, formats);

	public HRESULT get_Logging(int32* logging) mut => VT.[Friend]get_Logging(&this, logging);

	public HRESULT put_Logging(int32 logging) mut => VT.[Friend]put_Logging(&this, logging);

	public HRESULT get_ClassificationReportMailTo(BSTR* mailTo) mut => VT.[Friend]get_ClassificationReportMailTo(&this, mailTo);

	public HRESULT put_ClassificationReportMailTo(BSTR mailTo) mut => VT.[Friend]put_ClassificationReportMailTo(&this, mailTo);

	public HRESULT get_ClassificationReportEnabled(int16* reportEnabled) mut => VT.[Friend]get_ClassificationReportEnabled(&this, reportEnabled);

	public HRESULT put_ClassificationReportEnabled(int16 reportEnabled) mut => VT.[Friend]put_ClassificationReportEnabled(&this, reportEnabled);

	public HRESULT get_ClassificationLastReportPathWithoutExtension(BSTR* lastReportPath) mut => VT.[Friend]get_ClassificationLastReportPathWithoutExtension(&this, lastReportPath);

	public HRESULT get_ClassificationLastError(BSTR* lastError) mut => VT.[Friend]get_ClassificationLastError(&this, lastError);

	public HRESULT get_ClassificationRunningStatus(FsrmReportRunningStatus* runningStatus) mut => VT.[Friend]get_ClassificationRunningStatus(&this, runningStatus);

	public HRESULT EnumPropertyDefinitions(FsrmEnumOptions options, IFsrmCollection** propertyDefinitions) mut => VT.[Friend]EnumPropertyDefinitions(&this, options, propertyDefinitions);

	public HRESULT CreatePropertyDefinition(IFsrmPropertyDefinition** propertyDefinition) mut => VT.[Friend]CreatePropertyDefinition(&this, propertyDefinition);

	public HRESULT GetPropertyDefinition(BSTR propertyName, IFsrmPropertyDefinition** propertyDefinition) mut => VT.[Friend]GetPropertyDefinition(&this, propertyName, propertyDefinition);

	public HRESULT EnumRules(FsrmRuleType ruleType, FsrmEnumOptions options, IFsrmCollection** Rules) mut => VT.[Friend]EnumRules(&this, ruleType, options, Rules);

	public HRESULT CreateRule(FsrmRuleType ruleType, IFsrmRule** Rule) mut => VT.[Friend]CreateRule(&this, ruleType, Rule);

	public HRESULT GetRule(BSTR ruleName, FsrmRuleType ruleType, IFsrmRule** Rule) mut => VT.[Friend]GetRule(&this, ruleName, ruleType, Rule);

	public HRESULT EnumModuleDefinitions(FsrmPipelineModuleType moduleType, FsrmEnumOptions options, IFsrmCollection** moduleDefinitions) mut => VT.[Friend]EnumModuleDefinitions(&this, moduleType, options, moduleDefinitions);

	public HRESULT CreateModuleDefinition(FsrmPipelineModuleType moduleType, IFsrmPipelineModuleDefinition** moduleDefinition) mut => VT.[Friend]CreateModuleDefinition(&this, moduleType, moduleDefinition);

	public HRESULT GetModuleDefinition(BSTR moduleName, FsrmPipelineModuleType moduleType, IFsrmPipelineModuleDefinition** moduleDefinition) mut => VT.[Friend]GetModuleDefinition(&this, moduleName, moduleType, moduleDefinition);

	public HRESULT RunClassification(FsrmReportGenerationContext context, BSTR reserved) mut => VT.[Friend]RunClassification(&this, context, reserved);

	public HRESULT WaitForClassificationCompletion(int32 waitSeconds, int16* completed) mut => VT.[Friend]WaitForClassificationCompletion(&this, waitSeconds, completed);

	public HRESULT CancelClassification() mut => VT.[Friend]CancelClassification(&this);

	public HRESULT EnumFileProperties(BSTR filePath, FsrmGetFilePropertyOptions options, IFsrmCollection** fileProperties) mut => VT.[Friend]EnumFileProperties(&this, filePath, options, fileProperties);

	public HRESULT GetFileProperty(BSTR filePath, BSTR propertyName, FsrmGetFilePropertyOptions options, IFsrmProperty** property) mut => VT.[Friend]GetFileProperty(&this, filePath, propertyName, options, property);

	public HRESULT SetFileProperty(BSTR filePath, BSTR propertyName, BSTR propertyValue) mut => VT.[Friend]SetFileProperty(&this, filePath, propertyName, propertyValue);

	public HRESULT ClearFileProperty(BSTR filePath, BSTR property) mut => VT.[Friend]ClearFileProperty(&this, filePath, property);
}

[CRepr]struct IFsrmClassificationManager2 : IFsrmClassificationManager
{
	public new const Guid IID = .(0x0004c1c9, 0x127e, 0x4765, 0xba, 0x07, 0x6a, 0x31, 0x47, 0xbc, 0xa1, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmClassificationManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* filePaths, SAFEARRAY* propertyNames, SAFEARRAY* propertyValues, FsrmGetFilePropertyOptions options) ClassifyFiles;
	}


	public HRESULT ClassifyFiles(SAFEARRAY* filePaths, SAFEARRAY* propertyNames, SAFEARRAY* propertyValues, FsrmGetFilePropertyOptions options) mut => VT.[Friend]ClassifyFiles(&this, filePaths, propertyNames, propertyValues, options);
}

[CRepr]struct IFsrmPropertyBag : IDispatch
{
	public new const Guid IID = .(0x774589d1, 0xd300, 0x4f7a, 0x9a, 0x24, 0xf7, 0xb7, 0x66, 0x80, 0x02, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_RelativePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* volumeName) get_VolumeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* relativeNamespaceRoot) get_RelativeNamespaceRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* volumeId) get_VolumeIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* fileId) get_FileId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* parentDirectoryId) get_ParentDirectoryId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* size) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* sizeAllocated) get_SizeAllocated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* creationTime) get_CreationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* lastAccessTime) get_LastAccessTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* lastModificationTime) get_LastModificationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* attributes) get_Attributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ownerSid) get_OwnerSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** filePropertyNames) get_FilePropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** messages) get_Messages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* flags) get_PropertyBagFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IFsrmProperty** fileProperty) GetFileProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, BSTR value) SetFileProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR message) AddMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmFileStreamingMode accessMode, FsrmFileStreamingInterfaceType interfaceType, VARIANT* pStreamInterface) GetFileStreamInterface;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT get_RelativePath(BSTR* path) mut => VT.[Friend]get_RelativePath(&this, path);

	public HRESULT get_VolumeName(BSTR* volumeName) mut => VT.[Friend]get_VolumeName(&this, volumeName);

	public HRESULT get_RelativeNamespaceRoot(BSTR* relativeNamespaceRoot) mut => VT.[Friend]get_RelativeNamespaceRoot(&this, relativeNamespaceRoot);

	public HRESULT get_VolumeIndex(uint32* volumeId) mut => VT.[Friend]get_VolumeIndex(&this, volumeId);

	public HRESULT get_FileId(VARIANT* fileId) mut => VT.[Friend]get_FileId(&this, fileId);

	public HRESULT get_ParentDirectoryId(VARIANT* parentDirectoryId) mut => VT.[Friend]get_ParentDirectoryId(&this, parentDirectoryId);

	public HRESULT get_Size(VARIANT* size) mut => VT.[Friend]get_Size(&this, size);

	public HRESULT get_SizeAllocated(VARIANT* sizeAllocated) mut => VT.[Friend]get_SizeAllocated(&this, sizeAllocated);

	public HRESULT get_CreationTime(VARIANT* creationTime) mut => VT.[Friend]get_CreationTime(&this, creationTime);

	public HRESULT get_LastAccessTime(VARIANT* lastAccessTime) mut => VT.[Friend]get_LastAccessTime(&this, lastAccessTime);

	public HRESULT get_LastModificationTime(VARIANT* lastModificationTime) mut => VT.[Friend]get_LastModificationTime(&this, lastModificationTime);

	public HRESULT get_Attributes(uint32* attributes) mut => VT.[Friend]get_Attributes(&this, attributes);

	public HRESULT get_OwnerSid(BSTR* ownerSid) mut => VT.[Friend]get_OwnerSid(&this, ownerSid);

	public HRESULT get_FilePropertyNames(SAFEARRAY** filePropertyNames) mut => VT.[Friend]get_FilePropertyNames(&this, filePropertyNames);

	public HRESULT get_Messages(SAFEARRAY** messages) mut => VT.[Friend]get_Messages(&this, messages);

	public HRESULT get_PropertyBagFlags(uint32* flags) mut => VT.[Friend]get_PropertyBagFlags(&this, flags);

	public HRESULT GetFileProperty(BSTR name, IFsrmProperty** fileProperty) mut => VT.[Friend]GetFileProperty(&this, name, fileProperty);

	public HRESULT SetFileProperty(BSTR name, BSTR value) mut => VT.[Friend]SetFileProperty(&this, name, value);

	public HRESULT AddMessage(BSTR message) mut => VT.[Friend]AddMessage(&this, message);

	public HRESULT GetFileStreamInterface(FsrmFileStreamingMode accessMode, FsrmFileStreamingInterfaceType interfaceType, VARIANT* pStreamInterface) mut => VT.[Friend]GetFileStreamInterface(&this, accessMode, interfaceType, pStreamInterface);
}

[CRepr]struct IFsrmPropertyBag2 : IFsrmPropertyBag
{
	public new const Guid IID = .(0x0e46bdbd, 0x2402, 0x4fed, 0x9c, 0x30, 0x92, 0x66, 0xe6, 0xeb, 0x2c, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmPropertyBag.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FsrmPropertyBagField field, VARIANT* value) GetFieldValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection** props) GetUntrustedInFileProperties;
	}


	public HRESULT GetFieldValue(FsrmPropertyBagField field, VARIANT* value) mut => VT.[Friend]GetFieldValue(&this, field, value);

	public HRESULT GetUntrustedInFileProperties(IFsrmCollection** props) mut => VT.[Friend]GetUntrustedInFileProperties(&this, props);
}

[CRepr]struct IFsrmPipelineModuleImplementation : IDispatch
{
	public new const Guid IID = .(0xb7907906, 0x2b02, 0x4cb5, 0x84, 0xa9, 0xfd, 0xf5, 0x46, 0x13, 0xd6, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPipelineModuleDefinition* moduleDefinition, IFsrmPipelineModuleConnector** moduleConnector) OnLoad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnUnload;
	}


	public HRESULT OnLoad(IFsrmPipelineModuleDefinition* moduleDefinition, IFsrmPipelineModuleConnector** moduleConnector) mut => VT.[Friend]OnLoad(&this, moduleDefinition, moduleConnector);

	public HRESULT OnUnload() mut => VT.[Friend]OnUnload(&this);
}

[CRepr]struct IFsrmClassifierModuleImplementation : IFsrmPipelineModuleImplementation
{
	public new const Guid IID = .(0x4c968fc6, 0x6edb, 0x4051, 0x9c, 0x18, 0x73, 0xb7, 0x29, 0x1a, 0xe1, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmPipelineModuleImplementation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* lastModified) get_LastModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection* rules, IFsrmCollection* propertyDefinitions) UseRulesAndDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPropertyBag* propertyBag, SAFEARRAY* arrayRuleIds) OnBeginFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR property, BSTR value, int16* applyValue, Guid idRule, Guid idPropDef) DoesPropertyValueApply;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR property, BSTR* value, Guid idRule, Guid idPropDef) GetPropertyValueToApply;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnEndFile;
	}


	public HRESULT get_LastModified(VARIANT* lastModified) mut => VT.[Friend]get_LastModified(&this, lastModified);

	public HRESULT UseRulesAndDefinitions(IFsrmCollection* rules, IFsrmCollection* propertyDefinitions) mut => VT.[Friend]UseRulesAndDefinitions(&this, rules, propertyDefinitions);

	public HRESULT OnBeginFile(IFsrmPropertyBag* propertyBag, SAFEARRAY* arrayRuleIds) mut => VT.[Friend]OnBeginFile(&this, propertyBag, arrayRuleIds);

	public HRESULT DoesPropertyValueApply(BSTR property, BSTR value, int16* applyValue, Guid idRule, Guid idPropDef) mut => VT.[Friend]DoesPropertyValueApply(&this, property, value, applyValue, idRule, idPropDef);

	public HRESULT GetPropertyValueToApply(BSTR property, BSTR* value, Guid idRule, Guid idPropDef) mut => VT.[Friend]GetPropertyValueToApply(&this, property, value, idRule, idPropDef);

	public HRESULT OnEndFile() mut => VT.[Friend]OnEndFile(&this);
}

[CRepr]struct IFsrmStorageModuleImplementation : IFsrmPipelineModuleImplementation
{
	public new const Guid IID = .(0x0af4a0da, 0x895a, 0x4e50, 0x87, 0x12, 0xa9, 0x67, 0x24, 0xbc, 0xec, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFsrmPipelineModuleImplementation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmCollection* propertyDefinitions) UseDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPropertyBag* propertyBag) LoadProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPropertyBag* propertyBag) SaveProperties;
	}


	public HRESULT UseDefinitions(IFsrmCollection* propertyDefinitions) mut => VT.[Friend]UseDefinitions(&this, propertyDefinitions);

	public HRESULT LoadProperties(IFsrmPropertyBag* propertyBag) mut => VT.[Friend]LoadProperties(&this, propertyBag);

	public HRESULT SaveProperties(IFsrmPropertyBag* propertyBag) mut => VT.[Friend]SaveProperties(&this, propertyBag);
}

[CRepr]struct IFsrmPipelineModuleConnector : IDispatch
{
	public new const Guid IID = .(0xc16014f3, 0x9aa1, 0x46b3, 0xb0, 0xa7, 0xab, 0x14, 0x6e, 0xb2, 0x05, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPipelineModuleImplementation** pipelineModuleImplementation) get_ModuleImplementation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userName) get_ModuleName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userAccount) get_HostingUserAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pid) get_HostingProcessPid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFsrmPipelineModuleDefinition* moduleDefinition, IFsrmPipelineModuleImplementation* moduleImplementation) Bind;
	}


	public HRESULT get_ModuleImplementation(IFsrmPipelineModuleImplementation** pipelineModuleImplementation) mut => VT.[Friend]get_ModuleImplementation(&this, pipelineModuleImplementation);

	public HRESULT get_ModuleName(BSTR* userName) mut => VT.[Friend]get_ModuleName(&this, userName);

	public HRESULT get_HostingUserAccount(BSTR* userAccount) mut => VT.[Friend]get_HostingUserAccount(&this, userAccount);

	public HRESULT get_HostingProcessPid(int32* pid) mut => VT.[Friend]get_HostingProcessPid(&this, pid);

	public HRESULT Bind(IFsrmPipelineModuleDefinition* moduleDefinition, IFsrmPipelineModuleImplementation* moduleImplementation) mut => VT.[Friend]Bind(&this, moduleDefinition, moduleImplementation);
}

[CRepr]struct DIFsrmClassificationEvents : IDispatch
{
	public new const Guid IID = .(0x26942db0, 0xdabf, 0x41d8, 0xbb, 0xdd, 0xb1, 0x29, 0xa9, 0xf7, 0x04, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

#endregion
