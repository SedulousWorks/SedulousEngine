using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.System.HostComputeSystem;

#region TypeDefs
typealias HCS_OPERATION = int;

typealias HCS_SYSTEM = int;

typealias HCS_PROCESS = int;

#endregion


#region Enums

[AllowDuplicates]
public enum HCS_OPERATION_TYPE : int32
{
	HcsOperationTypeNone = -1,
	HcsOperationTypeEnumerate = 0,
	HcsOperationTypeCreate = 1,
	HcsOperationTypeStart = 2,
	HcsOperationTypeShutdown = 3,
	HcsOperationTypePause = 4,
	HcsOperationTypeResume = 5,
	HcsOperationTypeSave = 6,
	HcsOperationTypeTerminate = 7,
	HcsOperationTypeModify = 8,
	HcsOperationTypeGetProperties = 9,
	HcsOperationTypeCreateProcess = 10,
	HcsOperationTypeSignalProcess = 11,
	HcsOperationTypeGetProcessInfo = 12,
	HcsOperationTypeGetProcessProperties = 13,
	HcsOperationTypeModifyProcess = 14,
	HcsOperationTypeCrash = 15,
}


[AllowDuplicates]
public enum HCS_EVENT_TYPE : int32
{
	HcsEventInvalid = 0,
	HcsEventSystemExited = 1,
	HcsEventSystemCrashInitiated = 2,
	HcsEventSystemCrashReport = 3,
	HcsEventSystemRdpEnhancedModeStateChanged = 4,
	HcsEventSystemSiloJobCreated = 5,
	HcsEventSystemGuestConnectionClosed = 6,
	HcsEventProcessExited = 65536,
	HcsEventOperationCallback = 16777216,
	HcsEventServiceDisconnect = 33554432,
}


[AllowDuplicates]
public enum HCS_EVENT_OPTIONS : uint32
{
	HcsEventOptionNone = 0,
	HcsEventOptionEnableOperationCallbacks = 1,
}


[AllowDuplicates]
public enum HCS_NOTIFICATION_FLAGS : int32
{
	HcsNotificationFlagSuccess = 0,
	HcsNotificationFlagFailure = -2147483648,
}


[AllowDuplicates]
public enum HCS_NOTIFICATIONS : int32
{
	HcsNotificationInvalid = 0,
	HcsNotificationSystemExited = 1,
	HcsNotificationSystemCreateCompleted = 2,
	HcsNotificationSystemStartCompleted = 3,
	HcsNotificationSystemPauseCompleted = 4,
	HcsNotificationSystemResumeCompleted = 5,
	HcsNotificationSystemCrashReport = 6,
	HcsNotificationSystemSiloJobCreated = 7,
	HcsNotificationSystemSaveCompleted = 8,
	HcsNotificationSystemRdpEnhancedModeStateChanged = 9,
	HcsNotificationSystemShutdownFailed = 10,
	HcsNotificationSystemShutdownCompleted = 10,
	HcsNotificationSystemGetPropertiesCompleted = 11,
	HcsNotificationSystemModifyCompleted = 12,
	HcsNotificationSystemCrashInitiated = 13,
	HcsNotificationSystemGuestConnectionClosed = 14,
	HcsNotificationSystemOperationCompletion = 15,
	HcsNotificationSystemPassThru = 16,
	HcsNotificationProcessExited = 65536,
	HcsNotificationServiceDisconnect = 16777216,
	HcsNotificationFlagsReserved = -268435456,
}


[AllowDuplicates]
public enum HCS_CREATE_OPTIONS : int32
{
	HcsCreateOptions_1 = 65536,
}

#endregion

#region Function Pointers
public function void HCS_OPERATION_COMPLETION(HCS_OPERATION operation, void* context);

public function void HCS_EVENT_CALLBACK(HCS_EVENT* event, void* context);

public function void HCS_NOTIFICATION_CALLBACK(uint32 notificationType, void* context, HRESULT notificationStatus, PWSTR notificationData);

#endregion

#region Structs
[CRepr]
public struct HCS_EVENT
{
	public HCS_EVENT_TYPE Type;
	public PWSTR EventData;
	public HCS_OPERATION Operation;
}

[CRepr]
public struct HCS_PROCESS_INFORMATION
{
	public uint32 ProcessId;
	public uint32 Reserved;
	public HANDLE StdInput;
	public HANDLE StdOutput;
	public HANDLE StdError;
}

[CRepr]
public struct HCS_CREATE_OPTIONS_1
{
	public HCS_CREATE_OPTIONS Version;
	public HANDLE UserToken;
	public SECURITY_DESCRIPTOR* SecurityDescriptor;
	public HCS_EVENT_OPTIONS CallbackOptions;
	public void* CallbackContext;
	public HCS_EVENT_CALLBACK Callback;
}

#endregion

#region Functions
public static
{
	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsEnumerateComputeSystems(PWSTR query, HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsEnumerateComputeSystemsInNamespace(PWSTR idNamespace, PWSTR query, HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCS_OPERATION HcsCreateOperation(void* context, HCS_OPERATION_COMPLETION callback);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HcsCloseOperation(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* HcsGetOperationContext(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSetOperationContext(HCS_OPERATION operation, void* context);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCS_SYSTEM HcsGetComputeSystemFromOperation(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCS_PROCESS HcsGetProcessFromOperation(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCS_OPERATION_TYPE HcsGetOperationType(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 HcsGetOperationId(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetOperationResult(HCS_OPERATION operation, PWSTR* resultDocument);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetOperationResultAndProcessInfo(HCS_OPERATION operation, HCS_PROCESS_INFORMATION* processInformation, PWSTR* resultDocument);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetProcessorCompatibilityFromSavedState(PWSTR RuntimeFileName, PWSTR* ProcessorFeaturesString);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsWaitForOperationResult(HCS_OPERATION operation, uint32 timeoutMs, PWSTR* resultDocument);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsWaitForOperationResultAndProcessInfo(HCS_OPERATION operation, uint32 timeoutMs, HCS_PROCESS_INFORMATION* processInformation, PWSTR* resultDocument);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSetOperationCallback(HCS_OPERATION operation, void* context, HCS_OPERATION_COMPLETION callback);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCancelOperation(HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCreateComputeSystem(PWSTR id, PWSTR configuration, HCS_OPERATION operation, SECURITY_DESCRIPTOR* securityDescriptor, HCS_SYSTEM* computeSystem);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCreateComputeSystemInNamespace(PWSTR idNamespace, PWSTR id, PWSTR configuration, HCS_OPERATION operation, HCS_CREATE_OPTIONS* options, HCS_SYSTEM* computeSystem);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsOpenComputeSystem(PWSTR id, uint32 requestedAccess, HCS_SYSTEM* computeSystem);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsOpenComputeSystemInNamespace(PWSTR idNamespace, PWSTR id, uint32 requestedAccess, HCS_SYSTEM* computeSystem);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HcsCloseComputeSystem(HCS_SYSTEM computeSystem);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsStartComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsShutDownComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsTerminateComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCrashComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsPauseComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsResumeComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSaveComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetComputeSystemProperties(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR propertyQuery);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsModifyComputeSystem(HCS_SYSTEM computeSystem, HCS_OPERATION operation, PWSTR configuration, HANDLE identity);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsWaitForComputeSystemExit(HCS_SYSTEM computeSystem, uint32 timeoutMs, PWSTR* result);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSetComputeSystemCallback(HCS_SYSTEM computeSystem, HCS_EVENT_OPTIONS callbackOptions, void* context, HCS_EVENT_CALLBACK callback);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCreateProcess(HCS_SYSTEM computeSystem, PWSTR processParameters, HCS_OPERATION operation, SECURITY_DESCRIPTOR* securityDescriptor, HCS_PROCESS* process);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsOpenProcess(HCS_SYSTEM computeSystem, uint32 processId, uint32 requestedAccess, HCS_PROCESS* process);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HcsCloseProcess(HCS_PROCESS process);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsTerminateProcess(HCS_PROCESS process, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSignalProcess(HCS_PROCESS process, HCS_OPERATION operation, PWSTR options);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetProcessInfo(HCS_PROCESS process, HCS_OPERATION operation);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetProcessProperties(HCS_PROCESS process, HCS_OPERATION operation, PWSTR propertyQuery);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsModifyProcess(HCS_PROCESS process, HCS_OPERATION operation, PWSTR settings);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSetProcessCallback(HCS_PROCESS process, HCS_EVENT_OPTIONS callbackOptions, void* context, HCS_EVENT_CALLBACK callback);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsWaitForProcessExit(HCS_PROCESS computeSystem, uint32 timeoutMs, PWSTR* result);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetServiceProperties(PWSTR propertyQuery, PWSTR* result);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsModifyServiceSettings(PWSTR settings, PWSTR* result);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSubmitWerReport(PWSTR settings);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCreateEmptyGuestStateFile(PWSTR guestStateFilePath);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsCreateEmptyRuntimeStateFile(PWSTR runtimeStateFilePath);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGrantVmAccess(PWSTR vmId, PWSTR filePath);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsRevokeVmAccess(PWSTR vmId, PWSTR filePath);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGrantVmGroupAccess(PWSTR filePath);

	[Import("computecore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsRevokeVmGroupAccess(PWSTR filePath);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsImportLayer(PWSTR layerPath, PWSTR sourceFolderPath, PWSTR layerData);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsExportLayer(PWSTR layerPath, PWSTR exportFolderPath, PWSTR layerData, PWSTR options);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsExportLegacyWritableLayer(PWSTR writableLayerMountPath, PWSTR writableLayerFolderPath, PWSTR exportFolderPath, PWSTR layerData);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsDestroyLayer(PWSTR layerPath);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSetupBaseOSLayer(PWSTR layerPath, HANDLE vhdHandle, PWSTR options);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsInitializeWritableLayer(PWSTR writableLayerPath, PWSTR layerData, PWSTR options);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsInitializeLegacyWritableLayer(PWSTR writableLayerMountPath, PWSTR writableLayerFolderPath, PWSTR layerData, PWSTR options);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsAttachLayerStorageFilter(PWSTR layerPath, PWSTR layerData);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsDetachLayerStorageFilter(PWSTR layerPath);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsFormatWritableLayerVhd(HANDLE vhdHandle);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsGetLayerVhdMountPath(HANDLE vhdHandle, PWSTR* mountPath);

	[Import("computestorage.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HcsSetupBaseOSVolume(PWSTR layerPath, PWSTR volumePath, PWSTR options);

}
#endregion
