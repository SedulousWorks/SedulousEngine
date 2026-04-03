using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.Security.DiagnosticDataQuery;

#region Enums

[AllowDuplicates]
public enum DdqAccessLevel : int32
{
	NoData = 0,
	CurrentUserData = 1,
	AllUserData = 2,
}

#endregion


#region Structs
[CRepr]
public struct DIAGNOSTIC_DATA_RECORD
{
	public int64 rowId;
	public uint64 timestamp;
	public uint64 eventKeywords;
	public PWSTR fullEventName;
	public PWSTR providerGroupGuid;
	public PWSTR producerName;
	public int32* privacyTags;
	public uint32 privacyTagCount;
	public int32* categoryIds;
	public uint32 categoryIdCount;
	public BOOL isCoreData;
	public PWSTR extra1;
	public PWSTR extra2;
	public PWSTR extra3;
}

[CRepr]
public struct DIAGNOSTIC_DATA_SEARCH_CRITERIA
{
	public PWSTR* producerNames;
	public uint32 producerNameCount;
	public PWSTR textToMatch;
	public int32* categoryIds;
	public uint32 categoryIdCount;
	public int32* privacyTags;
	public uint32 privacyTagCount;
	public BOOL coreDataOnly;
}

[CRepr]
public struct DIAGNOSTIC_DATA_EVENT_TAG_DESCRIPTION
{
	public int32 privacyTag;
	public PWSTR name;
	public PWSTR description;
}

[CRepr]
public struct DIAGNOSTIC_DATA_EVENT_PRODUCER_DESCRIPTION
{
	public PWSTR name;
}

[CRepr]
public struct DIAGNOSTIC_DATA_EVENT_CATEGORY_DESCRIPTION
{
	public int32 id;
	public PWSTR name;
}

[CRepr]
public struct DIAGNOSTIC_DATA_EVENT_TAG_STATS
{
	public int32 privacyTag;
	public uint32 eventCount;
}

[CRepr]
public struct DIAGNOSTIC_DATA_EVENT_BINARY_STATS
{
	public PWSTR moduleName;
	public PWSTR friendlyModuleName;
	public uint32 eventCount;
	public uint64 uploadSizeBytes;
}

[CRepr]
public struct DIAGNOSTIC_DATA_GENERAL_STATS
{
	public uint32 optInLevel;
	public uint64 transcriptSizeBytes;
	public uint64 oldestEventTimestamp;
	public uint32 totalEventCountLast24Hours;
	public float averageDailyEvents;
}

[CRepr]
public struct DIAGNOSTIC_DATA_EVENT_TRANSCRIPT_CONFIGURATION
{
	public uint32 hoursOfHistoryToKeep;
	public uint32 maxStoreMegabytes;
	public uint32 requestedMaxStoreMegabytes;
}

[CRepr]
public struct DIAGNOSTIC_REPORT_PARAMETER
{
	public char16[129] name;
	public char16[260] value;
}

[CRepr]
public struct DIAGNOSTIC_REPORT_SIGNATURE
{
	public char16[65] eventName;
	public DIAGNOSTIC_REPORT_PARAMETER[10] parameters;
}

[CRepr]
public struct DIAGNOSTIC_REPORT_DATA
{
	public DIAGNOSTIC_REPORT_SIGNATURE signature;
	public Guid bucketId;
	public Guid reportId;
	public FILETIME creationTime;
	public uint64 sizeInBytes;
	public PWSTR cabId;
	public uint32 reportStatus;
	public Guid reportIntegratorId;
	public PWSTR* fileNames;
	public uint32 fileCount;
	public PWSTR friendlyEventName;
	public PWSTR applicationName;
	public PWSTR applicationPath;
	public PWSTR description;
	public PWSTR bucketIdString;
	public uint64 legacyBucketId;
	public PWSTR reportKey;
}

#endregion

#region Functions
public static
{
	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqCreateSession(DdqAccessLevel accessLevel, HDIAGNOSTIC_DATA_QUERY_SESSION* hSession);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqCloseSession(HDIAGNOSTIC_DATA_QUERY_SESSION hSession);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetSessionAccessLevel(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, DdqAccessLevel* accessLevel);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticDataAccessLevelAllowed(DdqAccessLevel* accessLevel);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordStats(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, DIAGNOSTIC_DATA_SEARCH_CRITERIA* searchCriteria, uint32* recordCount, int64* minRowId, int64* maxRowId);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordPayload(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, int64 rowId, PWSTR* payload);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordLocaleTags(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, PWSTR locale, HDIAGNOSTIC_EVENT_TAG_DESCRIPTION* hTagDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqFreeDiagnosticRecordLocaleTags(HDIAGNOSTIC_EVENT_TAG_DESCRIPTION hTagDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordLocaleTagAtIndex(HDIAGNOSTIC_EVENT_TAG_DESCRIPTION hTagDescription, uint32 index, DIAGNOSTIC_DATA_EVENT_TAG_DESCRIPTION* tagDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordLocaleTagCount(HDIAGNOSTIC_EVENT_TAG_DESCRIPTION hTagDescription, uint32* tagDescriptionCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordProducers(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, HDIAGNOSTIC_EVENT_PRODUCER_DESCRIPTION* hProducerDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqFreeDiagnosticRecordProducers(HDIAGNOSTIC_EVENT_PRODUCER_DESCRIPTION hProducerDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordProducerAtIndex(HDIAGNOSTIC_EVENT_PRODUCER_DESCRIPTION hProducerDescription, uint32 index, DIAGNOSTIC_DATA_EVENT_PRODUCER_DESCRIPTION* producerDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordProducerCount(HDIAGNOSTIC_EVENT_PRODUCER_DESCRIPTION hProducerDescription, uint32* producerDescriptionCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordProducerCategories(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, PWSTR producerName, HDIAGNOSTIC_EVENT_CATEGORY_DESCRIPTION* hCategoryDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqFreeDiagnosticRecordProducerCategories(HDIAGNOSTIC_EVENT_CATEGORY_DESCRIPTION hCategoryDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordCategoryAtIndex(HDIAGNOSTIC_EVENT_CATEGORY_DESCRIPTION hCategoryDescription, uint32 index, DIAGNOSTIC_DATA_EVENT_CATEGORY_DESCRIPTION* categoryDescription);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordCategoryCount(HDIAGNOSTIC_EVENT_CATEGORY_DESCRIPTION hCategoryDescription, uint32* categoryDescriptionCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqIsDiagnosticRecordSampledIn(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, in Guid providerGroup, Guid* providerId, PWSTR providerName, uint32* eventId, PWSTR eventName, uint32* eventVersion, uint64* eventKeywords, BOOL* isSampledIn);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordPage(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, DIAGNOSTIC_DATA_SEARCH_CRITERIA* searchCriteria, uint32 offset, uint32 pageRecordCount, int64 baseRowId, HDIAGNOSTIC_RECORD* hRecord);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqFreeDiagnosticRecordPage(HDIAGNOSTIC_RECORD hRecord);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordAtIndex(HDIAGNOSTIC_RECORD hRecord, uint32 index, DIAGNOSTIC_DATA_RECORD* record);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordCount(HDIAGNOSTIC_RECORD hRecord, uint32* recordCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticReportStoreReportCount(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, uint32 reportStoreType, uint32* reportCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqCancelDiagnosticRecordOperation(HDIAGNOSTIC_DATA_QUERY_SESSION hSession);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticReport(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, uint32 reportStoreType, HDIAGNOSTIC_REPORT* hReport);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqFreeDiagnosticReport(HDIAGNOSTIC_REPORT hReport);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticReportAtIndex(HDIAGNOSTIC_REPORT hReport, uint32 index, DIAGNOSTIC_REPORT_DATA* report);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticReportCount(HDIAGNOSTIC_REPORT hReport, uint32* reportCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqExtractDiagnosticReport(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, uint32 reportStoreType, PWSTR reportKey, PWSTR destinationPath);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordTagDistribution(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, PWSTR* producerNames, uint32 producerNameCount, DIAGNOSTIC_DATA_EVENT_TAG_STATS** tagStats, uint32* statCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordBinaryDistribution(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, PWSTR* producerNames, uint32 producerNameCount, uint32 topNBinaries, DIAGNOSTIC_DATA_EVENT_BINARY_STATS** binaryStats, uint32* statCount);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetDiagnosticRecordSummary(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, PWSTR* producerNames, uint32 producerNameCount, DIAGNOSTIC_DATA_GENERAL_STATS* generalStats);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqSetTranscriptConfiguration(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, DIAGNOSTIC_DATA_EVENT_TRANSCRIPT_CONFIGURATION* desiredConfig);

	[Import("DiagnosticDataQuery.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DdqGetTranscriptConfiguration(HDIAGNOSTIC_DATA_QUERY_SESSION hSession, DIAGNOSTIC_DATA_EVENT_TRANSCRIPT_CONFIGURATION* currentConfig);

}
#endregion
