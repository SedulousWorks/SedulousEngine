using Win32.Foundation;
using Win32.System.Diagnostics.Debug;
using System;

namespace Win32.System.ErrorReporting;

#region Constants
public static
{
	public const uint32 WER_FAULT_REPORTING_NO_UI = 32;
	public const uint32 WER_FAULT_REPORTING_FLAG_NO_HEAP_ON_QUEUE = 64;
	public const uint32 WER_FAULT_REPORTING_DISABLE_SNAPSHOT_CRASH = 128;
	public const uint32 WER_FAULT_REPORTING_DISABLE_SNAPSHOT_HANG = 256;
	public const uint32 WER_FAULT_REPORTING_CRITICAL = 512;
	public const uint32 WER_FAULT_REPORTING_DURABLE = 1024;
	public const uint32 WER_MAX_TOTAL_PARAM_LENGTH = 1720;
	public const uint32 WER_MAX_PREFERRED_MODULES = 128;
	public const uint32 WER_MAX_PREFERRED_MODULES_BUFFER = 256;
	public const String APPCRASH_EVENT = "APPCRASH";
	public const String PACKAGED_APPCRASH_EVENT = "MoAppCrash";
	public const uint32 WER_P0 = 0;
	public const uint32 WER_P1 = 1;
	public const uint32 WER_P2 = 2;
	public const uint32 WER_P3 = 3;
	public const uint32 WER_P4 = 4;
	public const uint32 WER_P5 = 5;
	public const uint32 WER_P6 = 6;
	public const uint32 WER_P7 = 7;
	public const uint32 WER_P8 = 8;
	public const uint32 WER_P9 = 9;
	public const uint32 WER_FILE_COMPRESSED = 4;
	public const uint32 WER_SUBMIT_BYPASS_POWER_THROTTLING = 16384;
	public const uint32 WER_SUBMIT_BYPASS_NETWORK_COST_THROTTLING = 32768;
	public const uint32 WER_DUMP_MASK_START = 1;
	public const uint32 WER_DUMP_NOHEAP_ONQUEUE = 1;
	public const uint32 WER_DUMP_AUXILIARY = 2;
	public const uint32 WER_MAX_REGISTERED_ENTRIES = 512;
	public const uint32 WER_MAX_REGISTERED_METADATA = 8;
	public const uint32 WER_MAX_REGISTERED_DUMPCOLLECTION = 4;
	public const uint32 WER_METADATA_KEY_MAX_LENGTH = 64;
	public const uint32 WER_METADATA_VALUE_MAX_LENGTH = 128;
	public const uint32 WER_MAX_SIGNATURE_NAME_LENGTH = 128;
	public const uint32 WER_MAX_EVENT_NAME_LENGTH = 64;
	public const uint32 WER_MAX_PARAM_LENGTH = 260;
	public const uint32 WER_MAX_PARAM_COUNT = 10;
	public const uint32 WER_MAX_FRIENDLY_EVENT_NAME_LENGTH = 128;
	public const uint32 WER_MAX_APPLICATION_NAME_LENGTH = 128;
	public const uint32 WER_MAX_DESCRIPTION_LENGTH = 512;
	public const uint32 WER_MAX_BUCKET_ID_STRING_LENGTH = 260;
	public const uint32 WER_MAX_LOCAL_DUMP_SUBPATH_LENGTH = 64;
	public const uint32 WER_MAX_REGISTERED_RUNTIME_EXCEPTION_MODULES = 16;
	public const String WER_RUNTIME_EXCEPTION_EVENT_FUNCTION = "OutOfProcessExceptionEventCallback";
	public const String WER_RUNTIME_EXCEPTION_EVENT_SIGNATURE_FUNCTION = "OutOfProcessExceptionEventSignatureCallback";
	public const String WER_RUNTIME_EXCEPTION_DEBUGGER_LAUNCH = "OutOfProcessExceptionEventDebuggerLaunchCallback";
}
#endregion

#region TypeDefs
typealias HREPORT = int;

typealias HREPORTSTORE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum WER_FILE : uint32
{
	WER_FILE_ANONYMOUS_DATA = 2,
	WER_FILE_DELETE_WHEN_DONE = 1,
}


[AllowDuplicates]
public enum WER_SUBMIT_FLAGS : uint32
{
	WER_SUBMIT_ADD_REGISTERED_DATA = 16,
	WER_SUBMIT_HONOR_RECOVERY = 1,
	WER_SUBMIT_HONOR_RESTART = 2,
	WER_SUBMIT_NO_ARCHIVE = 256,
	WER_SUBMIT_NO_CLOSE_UI = 64,
	WER_SUBMIT_NO_QUEUE = 128,
	WER_SUBMIT_OUTOFPROCESS = 32,
	WER_SUBMIT_OUTOFPROCESS_ASYNC = 1024,
	WER_SUBMIT_QUEUE = 4,
	WER_SUBMIT_SHOW_DEBUG = 8,
	WER_SUBMIT_START_MINIMIZED = 512,
	WER_SUBMIT_BYPASS_DATA_THROTTLING = 2048,
	WER_SUBMIT_ARCHIVE_PARAMETERS_ONLY = 4096,
	WER_SUBMIT_REPORT_MACHINE_ID = 8192,
}


[AllowDuplicates]
public enum WER_FAULT_REPORTING : uint32
{
	WER_FAULT_REPORTING_FLAG_DISABLE_THREAD_SUSPENSION = 4,
	WER_FAULT_REPORTING_FLAG_NOHEAP = 1,
	WER_FAULT_REPORTING_FLAG_QUEUE = 2,
	WER_FAULT_REPORTING_FLAG_QUEUE_UPLOAD = 8,
	WER_FAULT_REPORTING_ALWAYS_SHOW_UI = 16,
}


[AllowDuplicates]
public enum WER_REPORT_UI : int32
{
	WerUIAdditionalDataDlgHeader = 1,
	WerUIIconFilePath = 2,
	WerUIConsentDlgHeader = 3,
	WerUIConsentDlgBody = 4,
	WerUIOnlineSolutionCheckText = 5,
	WerUIOfflineSolutionCheckText = 6,
	WerUICloseText = 7,
	WerUICloseDlgHeader = 8,
	WerUICloseDlgBody = 9,
	WerUICloseDlgButtonText = 10,
	WerUIMax = 11,
}


[AllowDuplicates]
public enum WER_REGISTER_FILE_TYPE : int32
{
	WerRegFileTypeUserDocument = 1,
	WerRegFileTypeOther = 2,
	WerRegFileTypeMax = 3,
}


[AllowDuplicates]
public enum WER_FILE_TYPE : int32
{
	WerFileTypeMicrodump = 1,
	WerFileTypeMinidump = 2,
	WerFileTypeHeapdump = 3,
	WerFileTypeUserDocument = 4,
	WerFileTypeOther = 5,
	WerFileTypeTriagedump = 6,
	WerFileTypeCustomDump = 7,
	WerFileTypeAuxiliaryDump = 8,
	WerFileTypeEtlTrace = 9,
	WerFileTypeMax = 10,
}


[AllowDuplicates]
public enum WER_SUBMIT_RESULT : int32
{
	WerReportQueued = 1,
	WerReportUploaded = 2,
	WerReportDebug = 3,
	WerReportFailed = 4,
	WerDisabled = 5,
	WerReportCancelled = 6,
	WerDisabledQueue = 7,
	WerReportAsync = 8,
	WerCustomAction = 9,
	WerThrottled = 10,
	WerReportUploadedCab = 11,
	WerStorageLocationNotFound = 12,
	WerSubmitResultMax = 13,
}


[AllowDuplicates]
public enum WER_REPORT_TYPE : int32
{
	WerReportNonCritical = 0,
	WerReportCritical = 1,
	WerReportApplicationCrash = 2,
	WerReportApplicationHang = 3,
	WerReportKernel = 4,
	WerReportInvalid = 5,
}


[AllowDuplicates]
public enum WER_CONSENT : int32
{
	WerConsentNotAsked = 1,
	WerConsentApproved = 2,
	WerConsentDenied = 3,
	WerConsentAlwaysPrompt = 4,
	WerConsentMax = 5,
}


[AllowDuplicates]
public enum WER_DUMP_TYPE : int32
{
	WerDumpTypeNone = 0,
	WerDumpTypeMicroDump = 1,
	WerDumpTypeMiniDump = 2,
	WerDumpTypeHeapDump = 3,
	WerDumpTypeTriageDump = 4,
	WerDumpTypeMax = 5,
}


[AllowDuplicates]
public enum REPORT_STORE_TYPES : int32
{
	E_STORE_USER_ARCHIVE = 0,
	E_STORE_USER_QUEUE = 1,
	E_STORE_MACHINE_ARCHIVE = 2,
	E_STORE_MACHINE_QUEUE = 3,
	E_STORE_INVALID = 4,
}


[AllowDuplicates]
public enum EFaultRepRetVal : int32
{
	frrvOk = 0,
	frrvOkManifest = 1,
	frrvOkQueued = 2,
	frrvErr = 3,
	frrvErrNoDW = 4,
	frrvErrTimeout = 5,
	frrvLaunchDebugger = 6,
	frrvOkHeadless = 7,
	frrvErrAnotherInstance = 8,
	frrvErrNoMemory = 9,
	frrvErrDoubleFault = 10,
}

#endregion

#region Function Pointers
public function HRESULT PFN_WER_RUNTIME_EXCEPTION_EVENT(void* pContext, WER_RUNTIME_EXCEPTION_INFORMATION* pExceptionInformation, BOOL* pbOwnershipClaimed, char16* pwszEventName, uint32* pchSize, uint32* pdwSignatureCount);

public function HRESULT PFN_WER_RUNTIME_EXCEPTION_EVENT_SIGNATURE(void* pContext, WER_RUNTIME_EXCEPTION_INFORMATION* pExceptionInformation, uint32 dwIndex, char16* pwszName, uint32* pchName, char16* pwszValue, uint32* pchValue);

public function HRESULT PFN_WER_RUNTIME_EXCEPTION_DEBUGGER_LAUNCH(void* pContext, WER_RUNTIME_EXCEPTION_INFORMATION* pExceptionInformation, BOOL* pbIsCustomDebugger, char16* pwszDebuggerLaunch, uint32* pchDebuggerLaunch, BOOL* pbIsDebuggerAutolaunch);

public function EFaultRepRetVal pfn_REPORTFAULT(EXCEPTION_POINTERS* param0, uint32 param1);

public function EFaultRepRetVal pfn_ADDEREXCLUDEDAPPLICATIONA(PSTR param0);

public function EFaultRepRetVal pfn_ADDEREXCLUDEDAPPLICATIONW(PWSTR param0);

#endregion

#region Structs
[CRepr]
public struct WER_REPORT_INFORMATION
{
	public uint32 dwSize;
	public HANDLE hProcess;
	public char16[64] wzConsentKey;
	public char16[128] wzFriendlyEventName;
	public char16[128] wzApplicationName;
	public char16[260] wzApplicationPath;
	public char16[512] wzDescription;
	public HWND hwndParent;
}

[CRepr]
public struct WER_REPORT_INFORMATION_V3
{
	public uint32 dwSize;
	public HANDLE hProcess;
	public char16[64] wzConsentKey;
	public char16[128] wzFriendlyEventName;
	public char16[128] wzApplicationName;
	public char16[260] wzApplicationPath;
	public char16[512] wzDescription;
	public HWND hwndParent;
	public char16[64] wzNamespacePartner;
	public char16[64] wzNamespaceGroup;
}

[CRepr]
public struct WER_DUMP_CUSTOM_OPTIONS
{
	public uint32 dwSize;
	public uint32 dwMask;
	public uint32 dwDumpFlags;
	public BOOL bOnlyThisThread;
	public uint32 dwExceptionThreadFlags;
	public uint32 dwOtherThreadFlags;
	public uint32 dwExceptionThreadExFlags;
	public uint32 dwOtherThreadExFlags;
	public uint32 dwPreferredModuleFlags;
	public uint32 dwOtherModuleFlags;
	public char16[256] wzPreferredModuleList;
}

[CRepr]
public struct WER_DUMP_CUSTOM_OPTIONS_V2
{
	public uint32 dwSize;
	public uint32 dwMask;
	public uint32 dwDumpFlags;
	public BOOL bOnlyThisThread;
	public uint32 dwExceptionThreadFlags;
	public uint32 dwOtherThreadFlags;
	public uint32 dwExceptionThreadExFlags;
	public uint32 dwOtherThreadExFlags;
	public uint32 dwPreferredModuleFlags;
	public uint32 dwOtherModuleFlags;
	public char16[256] wzPreferredModuleList;
	public uint32 dwPreferredModuleResetFlags;
	public uint32 dwOtherModuleResetFlags;
}

[CRepr]
public struct WER_REPORT_INFORMATION_V4
{
	public uint32 dwSize;
	public HANDLE hProcess;
	public char16[64] wzConsentKey;
	public char16[128] wzFriendlyEventName;
	public char16[128] wzApplicationName;
	public char16[260] wzApplicationPath;
	public char16[512] wzDescription;
	public HWND hwndParent;
	public char16[64] wzNamespacePartner;
	public char16[64] wzNamespaceGroup;
	public uint8[16] rgbApplicationIdentity;
	public HANDLE hSnapshot;
	public HANDLE hDeleteFilesImpersonationToken;
}

[CRepr]
public struct WER_REPORT_INFORMATION_V5
{
	public uint32 dwSize;
	public HANDLE hProcess;
	public char16[64] wzConsentKey;
	public char16[128] wzFriendlyEventName;
	public char16[128] wzApplicationName;
	public char16[260] wzApplicationPath;
	public char16[512] wzDescription;
	public HWND hwndParent;
	public char16[64] wzNamespacePartner;
	public char16[64] wzNamespaceGroup;
	public uint8[16] rgbApplicationIdentity;
	public HANDLE hSnapshot;
	public HANDLE hDeleteFilesImpersonationToken;
	public WER_SUBMIT_RESULT submitResultMax;
}

[CRepr]
public struct WER_DUMP_CUSTOM_OPTIONS_V3
{
	public uint32 dwSize;
	public uint32 dwMask;
	public uint32 dwDumpFlags;
	public BOOL bOnlyThisThread;
	public uint32 dwExceptionThreadFlags;
	public uint32 dwOtherThreadFlags;
	public uint32 dwExceptionThreadExFlags;
	public uint32 dwOtherThreadExFlags;
	public uint32 dwPreferredModuleFlags;
	public uint32 dwOtherModuleFlags;
	public char16[256] wzPreferredModuleList;
	public uint32 dwPreferredModuleResetFlags;
	public uint32 dwOtherModuleResetFlags;
	public void* pvDumpKey;
	public HANDLE hSnapshot;
	public uint32 dwThreadID;
}

[CRepr]
public struct WER_EXCEPTION_INFORMATION
{
	public EXCEPTION_POINTERS* pExceptionPointers;
	public BOOL bClientPointers;
}

[CRepr]
public struct WER_RUNTIME_EXCEPTION_INFORMATION
{
	public uint32 dwSize;
	public HANDLE hProcess;
	public HANDLE hThread;
	public EXCEPTION_RECORD exceptionRecord;
	public CONTEXT context;
	public PWSTR pwszReportId;
	public BOOL bIsFatal;
	public uint32 dwReserved;
}

[CRepr]
public struct WER_REPORT_PARAMETER
{
	public char16[129] Name;
	public char16[260] Value;
}

[CRepr]
public struct WER_REPORT_SIGNATURE
{
	public char16[65] EventName;
	public WER_REPORT_PARAMETER[10] Parameters;
}

[CRepr]
public struct WER_REPORT_METADATA_V2
{
	public WER_REPORT_SIGNATURE Signature;
	public Guid BucketId;
	public Guid ReportId;
	public FILETIME CreationTime;
	public uint64 SizeInBytes;
	public char16[260] CabId;
	public uint32 ReportStatus;
	public Guid ReportIntegratorId;
	public uint32 NumberOfFiles;
	public uint32 SizeOfFileNames;
	public PWSTR FileNames;
}

[CRepr]
public struct WER_REPORT_METADATA_V3
{
	public WER_REPORT_SIGNATURE Signature;
	public Guid BucketId;
	public Guid ReportId;
	public FILETIME CreationTime;
	public uint64 SizeInBytes;
	public char16[260] CabId;
	public uint32 ReportStatus;
	public Guid ReportIntegratorId;
	public uint32 NumberOfFiles;
	public uint32 SizeOfFileNames;
	public PWSTR FileNames;
	public char16[128] FriendlyEventName;
	public char16[128] ApplicationName;
	public char16[260] ApplicationPath;
	public char16[512] Description;
	public char16[260] BucketIdString;
	public uint64 LegacyBucketId;
}

[CRepr]
public struct WER_REPORT_METADATA_V1
{
	public WER_REPORT_SIGNATURE Signature;
	public Guid BucketId;
	public Guid ReportId;
	public FILETIME CreationTime;
	public uint64 SizeInBytes;
}

#endregion

#region Functions
public static
{
	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportCreate(PWSTR pwzEventType, WER_REPORT_TYPE repType, WER_REPORT_INFORMATION* pReportInformation, HREPORT* phReportHandle);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportSetParameter(HREPORT hReportHandle, uint32 dwparamID, PWSTR pwzName, PWSTR pwzValue);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportAddFile(HREPORT hReportHandle, PWSTR pwzPath, WER_FILE_TYPE repFileType, WER_FILE dwFileFlags);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportSetUIOption(HREPORT hReportHandle, WER_REPORT_UI repUITypeID, PWSTR pwzValue);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportSubmit(HREPORT hReportHandle, WER_CONSENT consent, WER_SUBMIT_FLAGS dwFlags, WER_SUBMIT_RESULT* pSubmitResult);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportAddDump(HREPORT hReportHandle, HANDLE hProcess, HANDLE hThread, WER_DUMP_TYPE dumpType, WER_EXCEPTION_INFORMATION* pExceptionParam, WER_DUMP_CUSTOM_OPTIONS* pDumpCustomOptions, uint32 dwFlags);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportCloseHandle(HREPORT hReportHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterFile(PWSTR pwzFile, WER_REGISTER_FILE_TYPE regFileType, WER_FILE dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterFile(PWSTR pwzFilePath);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterMemoryBlock(void* pvAddress, uint32 dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterMemoryBlock(void* pvAddress);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterExcludedMemoryBlock(void* address, uint32 size);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterExcludedMemoryBlock(void* address);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterCustomMetadata(PWSTR key, PWSTR value);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterCustomMetadata(PWSTR key);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterAdditionalProcess(uint32 processId, uint32 captureExtraInfoForThreadId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterAdditionalProcess(uint32 processId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterAppLocalDump(PWSTR localAppDataRelativePath);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterAppLocalDump();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerSetFlags(WER_FAULT_REPORTING dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerGetFlags(HANDLE hProcess, WER_FAULT_REPORTING* pdwFlags);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerAddExcludedApplication(PWSTR pwzExeName, BOOL bAllUsers);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRemoveExcludedApplication(PWSTR pwzExeName, BOOL bAllUsers);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerRegisterRuntimeExceptionModule(PWSTR pwszOutOfProcessCallbackDll, void* pContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerUnregisterRuntimeExceptionModule(PWSTR pwszOutOfProcessCallbackDll, void* pContext);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreOpen(REPORT_STORE_TYPES repStoreType, HREPORTSTORE* phReportStore);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WerStoreClose(HREPORTSTORE hReportStore);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreGetFirstReportKey(HREPORTSTORE hReportStore, PWSTR* ppszReportKey);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreGetNextReportKey(HREPORTSTORE hReportStore, PWSTR* ppszReportKey);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreQueryReportMetadataV2(HREPORTSTORE hReportStore, PWSTR pszReportKey, WER_REPORT_METADATA_V2* pReportMetadata);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreQueryReportMetadataV3(HREPORTSTORE hReportStore, PWSTR pszReportKey, WER_REPORT_METADATA_V3* pReportMetadata);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WerFreeString(PWSTR pwszStr);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStorePurge();

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreGetReportCount(HREPORTSTORE hReportStore, uint32* pdwReportCount);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreGetSizeOnDisk(HREPORTSTORE hReportStore, uint64* pqwSizeInBytes);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreQueryReportMetadataV1(HREPORTSTORE hReportStore, PWSTR pszReportKey, WER_REPORT_METADATA_V1* pReportMetadata);

	[Import("wer.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerStoreUploadReport(HREPORTSTORE hReportStore, PWSTR pszReportKey, uint32 dwFlags, WER_SUBMIT_RESULT* pSubmitResult);

	[Import("faultrep.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EFaultRepRetVal ReportFault(EXCEPTION_POINTERS* pep, uint32 dwOpt);

	[Import("faultrep.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddERExcludedApplicationA(PSTR szApplication);
	public static BOOL AddERExcludedApplication(PSTR szApplication) => AddERExcludedApplicationA(szApplication);

	[Import("faultrep.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddERExcludedApplicationW(PWSTR wszApplication);

	[Import("faultrep.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WerReportHang(HWND hwndHungApp, PWSTR pwzHungApplicationName);

}
#endregion
