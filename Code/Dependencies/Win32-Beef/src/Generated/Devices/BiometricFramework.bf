using Win32.Foundation;
using Win32.System.IO;
using System;

namespace Win32.Devices.BiometricFramework;

#region Constants
public static
{
	public const uint32 WINBIO_MAX_STRING_LEN = 256;
	public const uint32 WINBIO_SCP_VERSION_1 = 1;
	public const uint32 WINBIO_SCP_RANDOM_SIZE_V1 = 32;
	public const uint32 WINBIO_SCP_DIGEST_SIZE_V1 = 32;
	public const uint32 WINBIO_SCP_CURVE_FIELD_SIZE_V1 = 32;
	public const uint32 WINBIO_SCP_PUBLIC_KEY_SIZE_V1 = 65;
	public const uint32 WINBIO_SCP_PRIVATE_KEY_SIZE_V1 = 32;
	public const uint32 WINBIO_SCP_SIGNATURE_SIZE_V1 = 64;
	public const uint32 WINBIO_SCP_ENCRYPTION_BLOCK_SIZE_V1 = 16;
	public const uint32 WINBIO_SCP_ENCRYPTION_KEY_SIZE_V1 = 32;
	public const uint32 WINBIO_BIR_ALIGN_SIZE = 8;
	public const uint32 WINBIO_BIR_ALGIN_SIZE = 8;
	public const uint32 FACILITY_WINBIO = 9;
	public const uint32 FACILITY_NONE = 0;
	public const HRESULT WINBIO_E_UNSUPPORTED_FACTOR = -2146861055;
	public const HRESULT WINBIO_E_INVALID_UNIT = -2146861054;
	public const HRESULT WINBIO_E_UNKNOWN_ID = -2146861053;
	public const HRESULT WINBIO_E_CANCELED = -2146861052;
	public const HRESULT WINBIO_E_NO_MATCH = -2146861051;
	public const HRESULT WINBIO_E_CAPTURE_ABORTED = -2146861050;
	public const HRESULT WINBIO_E_ENROLLMENT_IN_PROGRESS = -2146861049;
	public const HRESULT WINBIO_E_BAD_CAPTURE = -2146861048;
	public const HRESULT WINBIO_E_INVALID_CONTROL_CODE = -2146861047;
	public const HRESULT WINBIO_E_DATA_COLLECTION_IN_PROGRESS = -2146861045;
	public const HRESULT WINBIO_E_UNSUPPORTED_DATA_FORMAT = -2146861044;
	public const HRESULT WINBIO_E_UNSUPPORTED_DATA_TYPE = -2146861043;
	public const HRESULT WINBIO_E_UNSUPPORTED_PURPOSE = -2146861042;
	public const HRESULT WINBIO_E_INVALID_DEVICE_STATE = -2146861041;
	public const HRESULT WINBIO_E_DEVICE_BUSY = -2146861040;
	public const HRESULT WINBIO_E_DATABASE_CANT_CREATE = -2146861039;
	public const HRESULT WINBIO_E_DATABASE_CANT_OPEN = -2146861038;
	public const HRESULT WINBIO_E_DATABASE_CANT_CLOSE = -2146861037;
	public const HRESULT WINBIO_E_DATABASE_CANT_ERASE = -2146861036;
	public const HRESULT WINBIO_E_DATABASE_CANT_FIND = -2146861035;
	public const HRESULT WINBIO_E_DATABASE_ALREADY_EXISTS = -2146861034;
	public const HRESULT WINBIO_E_DATABASE_FULL = -2146861032;
	public const HRESULT WINBIO_E_DATABASE_LOCKED = -2146861031;
	public const HRESULT WINBIO_E_DATABASE_CORRUPTED = -2146861030;
	public const HRESULT WINBIO_E_DATABASE_NO_SUCH_RECORD = -2146861029;
	public const HRESULT WINBIO_E_DUPLICATE_ENROLLMENT = -2146861028;
	public const HRESULT WINBIO_E_DATABASE_READ_ERROR = -2146861027;
	public const HRESULT WINBIO_E_DATABASE_WRITE_ERROR = -2146861026;
	public const HRESULT WINBIO_E_DATABASE_NO_RESULTS = -2146861025;
	public const HRESULT WINBIO_E_DATABASE_NO_MORE_RECORDS = -2146861024;
	public const HRESULT WINBIO_E_DATABASE_EOF = -2146861023;
	public const HRESULT WINBIO_E_DATABASE_BAD_INDEX_VECTOR = -2146861022;
	public const HRESULT WINBIO_E_INCORRECT_BSP = -2146861020;
	public const HRESULT WINBIO_E_INCORRECT_SENSOR_POOL = -2146861019;
	public const HRESULT WINBIO_E_NO_CAPTURE_DATA = -2146861018;
	public const HRESULT WINBIO_E_INVALID_SENSOR_MODE = -2146861017;
	public const HRESULT WINBIO_E_LOCK_VIOLATION = -2146861014;
	public const HRESULT WINBIO_E_DUPLICATE_TEMPLATE = -2146861013;
	public const HRESULT WINBIO_E_INVALID_OPERATION = -2146861012;
	public const HRESULT WINBIO_E_SESSION_BUSY = -2146861011;
	public const HRESULT WINBIO_E_CRED_PROV_DISABLED = -2146861008;
	public const HRESULT WINBIO_E_CRED_PROV_NO_CREDENTIAL = -2146861007;
	public const HRESULT WINBIO_E_DISABLED = -2146861006;
	public const HRESULT WINBIO_E_CONFIGURATION_FAILURE = -2146861005;
	public const HRESULT WINBIO_E_SENSOR_UNAVAILABLE = -2146861004;
	public const HRESULT WINBIO_E_SAS_ENABLED = -2146861003;
	public const HRESULT WINBIO_E_DEVICE_FAILURE = -2146861002;
	public const HRESULT WINBIO_E_FAST_USER_SWITCH_DISABLED = -2146861001;
	public const HRESULT WINBIO_E_NOT_ACTIVE_CONSOLE = -2146861000;
	public const HRESULT WINBIO_E_EVENT_MONITOR_ACTIVE = -2146860999;
	public const HRESULT WINBIO_E_INVALID_PROPERTY_TYPE = -2146860998;
	public const HRESULT WINBIO_E_INVALID_PROPERTY_ID = -2146860997;
	public const HRESULT WINBIO_E_UNSUPPORTED_PROPERTY = -2146860996;
	public const HRESULT WINBIO_E_ADAPTER_INTEGRITY_FAILURE = -2146860995;
	public const HRESULT WINBIO_E_INCORRECT_SESSION_TYPE = -2146860994;
	public const HRESULT WINBIO_E_SESSION_HANDLE_CLOSED = -2146860993;
	public const HRESULT WINBIO_E_DEADLOCK_DETECTED = -2146860992;
	public const HRESULT WINBIO_E_NO_PREBOOT_IDENTITY = -2146860991;
	public const HRESULT WINBIO_E_MAX_ERROR_COUNT_EXCEEDED = -2146860990;
	public const HRESULT WINBIO_E_AUTO_LOGON_DISABLED = -2146860989;
	public const HRESULT WINBIO_E_INVALID_TICKET = -2146860988;
	public const HRESULT WINBIO_E_TICKET_QUOTA_EXCEEDED = -2146860987;
	public const HRESULT WINBIO_E_DATA_PROTECTION_FAILURE = -2146860986;
	public const HRESULT WINBIO_E_CRED_PROV_SECURITY_LOCKOUT = -2146860985;
	public const HRESULT WINBIO_E_UNSUPPORTED_POOL_TYPE = -2146860984;
	public const HRESULT WINBIO_E_SELECTION_REQUIRED = -2146860983;
	public const HRESULT WINBIO_E_PRESENCE_MONITOR_ACTIVE = -2146860982;
	public const HRESULT WINBIO_E_INVALID_SUBFACTOR = -2146860981;
	public const HRESULT WINBIO_E_INVALID_CALIBRATION_FORMAT_ARRAY = -2146860980;
	public const HRESULT WINBIO_E_NO_SUPPORTED_CALIBRATION_FORMAT = -2146860979;
	public const HRESULT WINBIO_E_UNSUPPORTED_SENSOR_CALIBRATION_FORMAT = -2146860978;
	public const HRESULT WINBIO_E_CALIBRATION_BUFFER_TOO_SMALL = -2146860977;
	public const HRESULT WINBIO_E_CALIBRATION_BUFFER_TOO_LARGE = -2146860976;
	public const HRESULT WINBIO_E_CALIBRATION_BUFFER_INVALID = -2146860975;
	public const HRESULT WINBIO_E_INVALID_KEY_IDENTIFIER = -2146860974;
	public const HRESULT WINBIO_E_KEY_CREATION_FAILED = -2146860973;
	public const HRESULT WINBIO_E_KEY_IDENTIFIER_BUFFER_TOO_SMALL = -2146860972;
	public const HRESULT WINBIO_E_PROPERTY_UNAVAILABLE = -2146860971;
	public const HRESULT WINBIO_E_POLICY_PROTECTION_UNAVAILABLE = -2146860970;
	public const HRESULT WINBIO_E_INSECURE_SENSOR = -2146860969;
	public const HRESULT WINBIO_E_INVALID_BUFFER_ID = -2146860968;
	public const HRESULT WINBIO_E_INVALID_BUFFER = -2146860967;
	public const HRESULT WINBIO_E_TRUSTLET_INTEGRITY_FAIL = -2146860966;
	public const HRESULT WINBIO_E_ENROLLMENT_CANCELED_BY_SUSPEND = -2146860965;
	public const HRESULT WINBIO_I_MORE_DATA = 589825;
	public const HRESULT WINBIO_I_EXTENDED_STATUS_INFORMATION = 589826;
	public const Guid GUID_DEVINTERFACE_BIOMETRIC_READER = .(0xe2b5183a, 0x99ea, 0x4cc3, 0xad, 0x6b, 0x80, 0xca, 0x8d, 0x71, 0x5b, 0x80);
	public const uint32 IOCTL_BIOMETRIC_VENDOR = 4464640;
	public const uint32 WINBIO_WBDI_MAJOR_VERSION = 1;
	public const uint32 WINBIO_WBDI_MINOR_VERSION = 0;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WINBIO_SETTING_SOURCE : uint32
{
	WINBIO_SETTING_SOURCE_INVALID = 0,
	WINBIO_SETTING_SOURCE_DEFAULT = 1,
	WINBIO_SETTING_SOURCE_LOCAL = 3,
	WINBIO_SETTING_SOURCE_POLICY = 2,
}


[AllowDuplicates]
public enum WINBIO_COMPONENT : uint32
{
	WINBIO_COMPONENT_SENSOR = 1,
	WINBIO_COMPONENT_ENGINE = 2,
	WINBIO_COMPONENT_STORAGE = 3,
}


[AllowDuplicates]
public enum WINBIO_POOL : uint32
{
	WINBIO_POOL_SYSTEM = 1,
	WINBIO_POOL_PRIVATE = 2,
}


[AllowDuplicates]
public enum WINBIO_ANTI_SPOOF_POLICY_ACTION : int32
{
	WINBIO_ANTI_SPOOF_DISABLE = 0,
	WINBIO_ANTI_SPOOF_ENABLE = 1,
	WINBIO_ANTI_SPOOF_REMOVE = 2,
}


[AllowDuplicates]
public enum WINBIO_POLICY_SOURCE : int32
{
	WINBIO_POLICY_UNKNOWN = 0,
	WINBIO_POLICY_DEFAULT = 1,
	WINBIO_POLICY_LOCAL = 2,
	WINBIO_POLICY_ADMIN = 3,
}


[AllowDuplicates]
public enum WINBIO_CREDENTIAL_TYPE : int32
{
	WINBIO_CREDENTIAL_PASSWORD = 1,
	WINBIO_CREDENTIAL_ALL = -1,
}


[AllowDuplicates]
public enum WINBIO_CREDENTIAL_FORMAT : int32
{
	WINBIO_PASSWORD_GENERIC = 1,
	WINBIO_PASSWORD_PACKED = 2,
	WINBIO_PASSWORD_PROTECTED = 3,
}


[AllowDuplicates]
public enum WINBIO_CREDENTIAL_STATE : int32
{
	WINBIO_CREDENTIAL_NOT_SET = 1,
	WINBIO_CREDENTIAL_SET = 2,
}


[AllowDuplicates]
public enum WINBIO_ASYNC_NOTIFICATION_METHOD : int32
{
	WINBIO_ASYNC_NOTIFY_NONE = 0,
	WINBIO_ASYNC_NOTIFY_CALLBACK = 1,
	WINBIO_ASYNC_NOTIFY_MESSAGE = 2,
	WINBIO_ASYNC_NOTIFY_MAXIMUM_VALUE = 3,
}

#endregion

#region Function Pointers
public function void PWINBIO_ASYNC_COMPLETION_CALLBACK(WINBIO_ASYNC_RESULT* AsyncResult);

public function void PWINBIO_VERIFY_CALLBACK(void* VerifyCallbackContext, HRESULT OperationStatus, uint32 UnitId, BOOLEAN Match, uint32 RejectDetail);

public function void PWINBIO_IDENTIFY_CALLBACK(void* IdentifyCallbackContext, HRESULT OperationStatus, uint32 UnitId, WINBIO_IDENTITY* Identity, uint8 SubFactor, uint32 RejectDetail);

public function void PWINBIO_LOCATE_SENSOR_CALLBACK(void* LocateCallbackContext, HRESULT OperationStatus, uint32 UnitId);

public function void PWINBIO_ENROLL_CAPTURE_CALLBACK(void* EnrollCallbackContext, HRESULT OperationStatus, uint32 RejectDetail);

public function void PWINBIO_EVENT_CALLBACK(void* EventCallbackContext, HRESULT OperationStatus, WINBIO_EVENT* Event);

public function void PWINBIO_CAPTURE_CALLBACK(void* CaptureCallbackContext, HRESULT OperationStatus, uint32 UnitId, WINBIO_BIR* Sample, uint SampleSize, uint32 RejectDetail);

public function HRESULT PIBIO_SENSOR_ATTACH_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_DETACH_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_CLEAR_CONTEXT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_QUERY_STATUS_FN(WINBIO_PIPELINE* Pipeline, uint32* Status);

public function HRESULT PIBIO_SENSOR_RESET_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_SET_MODE_FN(WINBIO_PIPELINE* Pipeline, uint32 Mode);

public function HRESULT PIBIO_SENSOR_SET_INDICATOR_STATUS_FN(WINBIO_PIPELINE* Pipeline, uint32 IndicatorStatus);

public function HRESULT PIBIO_SENSOR_GET_INDICATOR_STATUS_FN(WINBIO_PIPELINE* Pipeline, uint32* IndicatorStatus);

public function HRESULT PIBIO_SENSOR_START_CAPTURE_FN(WINBIO_PIPELINE* Pipeline, uint8 Purpose, OVERLAPPED** Overlapped);

public function HRESULT PIBIO_SENSOR_FINISH_CAPTURE_FN(WINBIO_PIPELINE* Pipeline, uint32* RejectDetail);

public function HRESULT PIBIO_SENSOR_EXPORT_SENSOR_DATA_FN(WINBIO_PIPELINE* Pipeline, WINBIO_BIR** SampleBuffer, uint* SampleSize);

public function HRESULT PIBIO_SENSOR_CANCEL_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_PUSH_DATA_TO_ENGINE_FN(WINBIO_PIPELINE* Pipeline, uint8 Purpose, uint8 Flags, uint32* RejectDetail);

public function HRESULT PIBIO_SENSOR_CONTROL_UNIT_FN(WINBIO_PIPELINE* Pipeline, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

public function HRESULT PIBIO_SENSOR_CONTROL_UNIT_PRIVILEGED_FN(WINBIO_PIPELINE* Pipeline, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

public function HRESULT PIBIO_SENSOR_NOTIFY_POWER_CHANGE_FN(WINBIO_PIPELINE* Pipeline, uint32 PowerEventType);

public function HRESULT PIBIO_SENSOR_PIPELINE_INIT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_PIPELINE_CLEANUP_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_ACTIVATE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_DEACTIVATE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_SENSOR_QUERY_EXTENDED_INFO_FN(WINBIO_PIPELINE* Pipeline, WINBIO_EXTENDED_SENSOR_INFO* SensorInfo, uint SensorInfoSize);

public function HRESULT PIBIO_SENSOR_QUERY_CALIBRATION_FORMATS_FN(WINBIO_PIPELINE* Pipeline, Guid* FormatArray, uint FormatArraySize, uint* FormatCount);

public function HRESULT PIBIO_SENSOR_SET_CALIBRATION_FORMAT_FN(WINBIO_PIPELINE* Pipeline, Guid* Format);

public function HRESULT PIBIO_SENSOR_ACCEPT_CALIBRATION_DATA_FN(WINBIO_PIPELINE* Pipeline, uint8* CalibrationBuffer, uint CalibrationBufferSize);

public function HRESULT PIBIO_SENSOR_ASYNC_IMPORT_RAW_BUFFER_FN(WINBIO_PIPELINE* Pipeline, uint8* RawBufferAddress, uint RawBufferSize, uint8** ResultBufferAddress, uint* ResultBufferSize);

public function HRESULT PIBIO_SENSOR_ASYNC_IMPORT_SECURE_BUFFER_FN(WINBIO_PIPELINE* Pipeline, Guid SecureBufferIdentifier, uint8* MetadataBufferAddress, uint MetadataBufferSize, uint8** ResultBufferAddress, uint* ResultBufferSize);

public function HRESULT PIBIO_SENSOR_QUERY_PRIVATE_SENSOR_TYPE_FN(WINBIO_PIPELINE* Pipeline, uint8* TypeInfoBufferAddress, uint TypeInfoBufferSize, uint* TypeInfoDataSize);

public function HRESULT PIBIO_SENSOR_CONNECT_SECURE_FN(WINBIO_PIPELINE* Pipeline, WINBIO_SECURE_CONNECTION_PARAMS* ConnectionParams, WINBIO_SECURE_CONNECTION_DATA** ConnectionData);

public function HRESULT PIBIO_SENSOR_START_CAPTURE_EX_FN(WINBIO_PIPELINE* Pipeline, uint8 Purpose, uint8* Nonce, uint NonceSize, uint8 Flags, OVERLAPPED** Overlapped);

public function HRESULT PIBIO_SENSOR_START_NOTIFY_WAKE_FN(WINBIO_PIPELINE* Pipeline, OVERLAPPED** Overlapped);

public function HRESULT PIBIO_SENSOR_FINISH_NOTIFY_WAKE_FN(WINBIO_PIPELINE* Pipeline, uint32* Reason);

public function HRESULT PWINBIO_QUERY_SENSOR_INTERFACE_FN(WINBIO_SENSOR_INTERFACE** SensorInterface);

public function HRESULT PIBIO_ENGINE_ATTACH_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_DETACH_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_CLEAR_CONTEXT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_QUERY_PREFERRED_FORMAT_FN(WINBIO_PIPELINE* Pipeline, WINBIO_REGISTERED_FORMAT* StandardFormat, Guid* VendorFormat);

public function HRESULT PIBIO_ENGINE_QUERY_INDEX_VECTOR_SIZE_FN(WINBIO_PIPELINE* Pipeline, uint* IndexElementCount);

public function HRESULT PIBIO_ENGINE_QUERY_HASH_ALGORITHMS_FN(WINBIO_PIPELINE* Pipeline, uint* AlgorithmCount, uint* AlgorithmBufferSize, uint8** AlgorithmBuffer);

public function HRESULT PIBIO_ENGINE_SET_HASH_ALGORITHM_FN(WINBIO_PIPELINE* Pipeline, uint AlgorithmBufferSize, uint8* AlgorithmBuffer);

public function HRESULT PIBIO_ENGINE_QUERY_SAMPLE_HINT_FN(WINBIO_PIPELINE* Pipeline, uint* SampleHint);

public function HRESULT PIBIO_ENGINE_ACCEPT_SAMPLE_DATA_FN(WINBIO_PIPELINE* Pipeline, WINBIO_BIR* SampleBuffer, uint SampleSize, uint8 Purpose, uint32* RejectDetail);

public function HRESULT PIBIO_ENGINE_EXPORT_ENGINE_DATA_FN(WINBIO_PIPELINE* Pipeline, uint8 Flags, WINBIO_BIR** SampleBuffer, uint* SampleSize);

public function HRESULT PIBIO_ENGINE_VERIFY_FEATURE_SET_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8 SubFactor, BOOLEAN* Match, uint8** PayloadBlob, uint* PayloadBlobSize, uint8** HashValue, uint* HashSize, uint32* RejectDetail);

public function HRESULT PIBIO_ENGINE_IDENTIFY_FEATURE_SET_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8* SubFactor, uint8** PayloadBlob, uint* PayloadBlobSize, uint8** HashValue, uint* HashSize, uint32* RejectDetail);

public function HRESULT PIBIO_ENGINE_CREATE_ENROLLMENT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_UPDATE_ENROLLMENT_FN(WINBIO_PIPELINE* Pipeline, uint32* RejectDetail);

public function HRESULT PIBIO_ENGINE_GET_ENROLLMENT_STATUS_FN(WINBIO_PIPELINE* Pipeline, uint32* RejectDetail);

public function HRESULT PIBIO_ENGINE_GET_ENROLLMENT_HASH_FN(WINBIO_PIPELINE* Pipeline, uint8** HashValue, uint* HashSize);

public function HRESULT PIBIO_ENGINE_CHECK_FOR_DUPLICATE_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8* SubFactor, BOOLEAN* Duplicate);

public function HRESULT PIBIO_ENGINE_COMMIT_ENROLLMENT_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8 SubFactor, uint8* PayloadBlob, uint PayloadBlobSize);

public function HRESULT PIBIO_ENGINE_DISCARD_ENROLLMENT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_CONTROL_UNIT_FN(WINBIO_PIPELINE* Pipeline, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

public function HRESULT PIBIO_ENGINE_CONTROL_UNIT_PRIVILEGED_FN(WINBIO_PIPELINE* Pipeline, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

public function HRESULT PIBIO_ENGINE_NOTIFY_POWER_CHANGE_FN(WINBIO_PIPELINE* Pipeline, uint32 PowerEventType);

public function HRESULT PIBIO_ENGINE_RESERVED_1_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity);

public function HRESULT PIBIO_ENGINE_PIPELINE_INIT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_PIPELINE_CLEANUP_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_ACTIVATE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_DEACTIVATE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_QUERY_EXTENDED_INFO_FN(WINBIO_PIPELINE* Pipeline, WINBIO_EXTENDED_ENGINE_INFO* EngineInfo, uint EngineInfoSize);

public function HRESULT PIBIO_ENGINE_IDENTIFY_ALL_FN(WINBIO_PIPELINE* Pipeline, uint* PresenceCount, WINBIO_PRESENCE** PresenceArray);

public function HRESULT PIBIO_ENGINE_SET_ENROLLMENT_SELECTOR_FN(WINBIO_PIPELINE* Pipeline, uint64 SelectorValue);

public function HRESULT PIBIO_ENGINE_SET_ENROLLMENT_PARAMETERS_FN(WINBIO_PIPELINE* Pipeline, WINBIO_EXTENDED_ENROLLMENT_PARAMETERS* Parameters);

public function HRESULT PIBIO_ENGINE_QUERY_EXTENDED_ENROLLMENT_STATUS_FN(WINBIO_PIPELINE* Pipeline, WINBIO_EXTENDED_ENROLLMENT_STATUS* EnrollmentStatus, uint EnrollmentStatusSize);

public function HRESULT PIBIO_ENGINE_REFRESH_CACHE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_ENGINE_SELECT_CALIBRATION_FORMAT_FN(WINBIO_PIPELINE* Pipeline, Guid* FormatArray, uint FormatCount, Guid* SelectedFormat, uint* MaxBufferSize);

public function HRESULT PIBIO_ENGINE_QUERY_CALIBRATION_DATA_FN(WINBIO_PIPELINE* Pipeline, BOOLEAN* DiscardAndRepeatCapture, uint8* CalibrationBuffer, uint* CalibrationBufferSize, uint MaxBufferSize);

public function HRESULT PIBIO_ENGINE_SET_ACCOUNT_POLICY_FN(WINBIO_PIPELINE* Pipeline, WINBIO_ACCOUNT_POLICY* PolicyItemArray, uint PolicyItemCount);

public function HRESULT PIBIO_ENGINE_CREATE_KEY_FN(WINBIO_PIPELINE* Pipeline, uint8* Key, uint KeySize, uint8* KeyIdentifier, uint KeyIdentifierSize, uint* ResultSize);

public function HRESULT PIBIO_ENGINE_IDENTIFY_FEATURE_SET_SECURE_FN(WINBIO_PIPELINE* Pipeline, uint8* Nonce, uint NonceSize, uint8* KeyIdentifier, uint KeyIdentifierSize, WINBIO_IDENTITY* Identity, uint8* SubFactor, uint32* RejectDetail, uint8** Authorization, uint* AuthorizationSize);

public function HRESULT PIBIO_ENGINE_ACCEPT_PRIVATE_SENSOR_TYPE_INFO_FN(WINBIO_PIPELINE* Pipeline, uint8* TypeInfoBufferAddress, uint TypeInfoBufferSize);

public function HRESULT PIBIO_ENGINE_CREATE_ENROLLMENT_AUTHENTICATED_FN(WINBIO_PIPELINE* Pipeline, uint8** Nonce, uint* NonceSize);

public function HRESULT PIBIO_ENGINE_IDENTIFY_FEATURE_SET_AUTHENTICATED_FN(WINBIO_PIPELINE* Pipeline, uint8* Nonce, uint NonceSize, WINBIO_IDENTITY* Identity, uint8* SubFactor, uint32* RejectDetail, uint8** Authentication, uint* AuthenticationSize);

public function HRESULT PWINBIO_QUERY_ENGINE_INTERFACE_FN(WINBIO_ENGINE_INTERFACE** EngineInterface);

public function HRESULT PIBIO_STORAGE_ATTACH_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_DETACH_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_CLEAR_CONTEXT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_CREATE_DATABASE_FN(WINBIO_PIPELINE* Pipeline, Guid* DatabaseId, uint32 Factor, Guid* Format, PWSTR FilePath, PWSTR ConnectString, uint IndexElementCount, uint InitialSize);

public function HRESULT PIBIO_STORAGE_ERASE_DATABASE_FN(WINBIO_PIPELINE* Pipeline, Guid* DatabaseId, PWSTR FilePath, PWSTR ConnectString);

public function HRESULT PIBIO_STORAGE_OPEN_DATABASE_FN(WINBIO_PIPELINE* Pipeline, Guid* DatabaseId, PWSTR FilePath, PWSTR ConnectString);

public function HRESULT PIBIO_STORAGE_CLOSE_DATABASE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_GET_DATA_FORMAT_FN(WINBIO_PIPELINE* Pipeline, Guid* Format, WINBIO_VERSION* Version);

public function HRESULT PIBIO_STORAGE_GET_DATABASE_SIZE_FN(WINBIO_PIPELINE* Pipeline, uint* AvailableRecordCount, uint* TotalRecordCount);

public function HRESULT PIBIO_STORAGE_ADD_RECORD_FN(WINBIO_PIPELINE* Pipeline, WINBIO_STORAGE_RECORD* RecordContents);

public function HRESULT PIBIO_STORAGE_DELETE_RECORD_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8 SubFactor);

public function HRESULT PIBIO_STORAGE_QUERY_BY_SUBJECT_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8 SubFactor);

public function HRESULT PIBIO_STORAGE_QUERY_BY_CONTENT_FN(WINBIO_PIPELINE* Pipeline, uint8 SubFactor, uint32* IndexVector, uint IndexElementCount);

public function HRESULT PIBIO_STORAGE_GET_RECORD_COUNT_FN(WINBIO_PIPELINE* Pipeline, uint* RecordCount);

public function HRESULT PIBIO_STORAGE_FIRST_RECORD_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_NEXT_RECORD_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_GET_CURRENT_RECORD_FN(WINBIO_PIPELINE* Pipeline, WINBIO_STORAGE_RECORD* RecordContents);

public function HRESULT PIBIO_STORAGE_CONTROL_UNIT_FN(WINBIO_PIPELINE* Pipeline, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

public function HRESULT PIBIO_STORAGE_CONTROL_UNIT_PRIVILEGED_FN(WINBIO_PIPELINE* Pipeline, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

public function HRESULT PIBIO_STORAGE_NOTIFY_POWER_CHANGE_FN(WINBIO_PIPELINE* Pipeline, uint32 PowerEventType);

public function HRESULT PIBIO_STORAGE_PIPELINE_INIT_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_PIPELINE_CLEANUP_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_ACTIVATE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_DEACTIVATE_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_STORAGE_QUERY_EXTENDED_INFO_FN(WINBIO_PIPELINE* Pipeline, WINBIO_EXTENDED_STORAGE_INFO* StorageInfo, uint StorageInfoSize);

public function HRESULT PIBIO_STORAGE_NOTIFY_DATABASE_CHANGE_FN(WINBIO_PIPELINE* Pipeline, BOOLEAN RecordsAdded);

public function HRESULT PIBIO_STORAGE_RESERVED_1_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint64* Reserved1, uint64* Reserved2);

public function HRESULT PIBIO_STORAGE_RESERVED_2_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity);

public function HRESULT PIBIO_STORAGE_UPDATE_RECORD_BEGIN_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint8 SubFactor, WINBIO_STORAGE_RECORD* RecordContents);

public function HRESULT PIBIO_STORAGE_UPDATE_RECORD_COMMIT_FN(WINBIO_PIPELINE* Pipeline, WINBIO_STORAGE_RECORD* RecordContents);

public function HRESULT PWINBIO_QUERY_STORAGE_INTERFACE_FN(WINBIO_STORAGE_INTERFACE** StorageInterface);

public function HRESULT PIBIO_FRAMEWORK_SET_UNIT_STATUS_FN(WINBIO_PIPELINE* Pipeline, WINBIO_EXTENDED_UNIT_STATUS* ExtendedStatus, uint ExtendedStatusSize);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_CLEAR_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_IMPORT_BEGIN_FN(WINBIO_PIPELINE* Pipeline, uint RequiredCapacity, uint* MaxBufferSize);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_IMPORT_NEXT_FN(WINBIO_PIPELINE* Pipeline, uint8* BufferAddress, uint BufferSize);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_IMPORT_END_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_EXPORT_BEGIN_FN(WINBIO_PIPELINE* Pipeline, uint* RequiredCapacity, uint* MaxBufferSize);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_EXPORT_NEXT_FN(WINBIO_PIPELINE* Pipeline, uint8* BufferAddress, uint BufferSize, uint* ReturnedDataSize);

public function HRESULT PIBIO_FRAMEWORK_VSM_CACHE_EXPORT_END_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_FRAMEWORK_VSM_STORAGE_RESERVED_1_FN(WINBIO_PIPELINE* Pipeline, uint Reserved1, uint* Reserved2);

public function HRESULT PIBIO_FRAMEWORK_VSM_STORAGE_RESERVED_2_FN(WINBIO_PIPELINE* Pipeline, uint8* Reserved1, uint Reserved2);

public function HRESULT PIBIO_FRAMEWORK_VSM_STORAGE_RESERVED_3_FN(WINBIO_PIPELINE* Pipeline);

public function HRESULT PIBIO_FRAMEWORK_ALLOCATE_MEMORY_FN(WINBIO_PIPELINE* Pipeline, uint AllocationSize, void** Address);

public function HRESULT PIBIO_FRAMEWORK_FREE_MEMORY_FN(WINBIO_PIPELINE* Pipeline, void* Address);

public function HRESULT PIBIO_FRAMEWORK_GET_PROPERTY_FN(WINBIO_PIPELINE* Pipeline, uint32 PropertyType, uint32 PropertyId, WINBIO_IDENTITY* Identity, uint8 SubFactor, void** PropertyBuffer, uint* PropertyBufferSize);

public function HRESULT PIBIO_FRAMEWORK_LOCK_AND_VALIDATE_SECURE_BUFFER_FN(WINBIO_PIPELINE* Pipeline, Guid SecureBufferIdentifier, void** SecureBufferAddress, uint* SecureBufferSize);

public function HRESULT PIBIO_FRAMEWORK_RELEASE_SECURE_BUFFER_FN(WINBIO_PIPELINE* Pipeline, Guid SecureBufferIdentifier);

public function HRESULT PIBIO_FRAMEWORK_VSM_QUERY_AUTHORIZED_ENROLLMENTS_FN(WINBIO_PIPELINE* Pipeline, WINBIO_IDENTITY* Identity, uint* SecureIdentityCount, WINBIO_IDENTITY** SecureIdentities);

public function HRESULT PIBIO_FRAMEWORK_VSM_DECRYPT_SAMPLE_FN(WINBIO_PIPELINE* Pipeline, uint8* Authentication, uint AuthenticationSize, uint8* Iv, uint IvSize, uint8* EncryptedData, uint EncryptedDataSize);

#endregion

#region Structs
[CRepr]
public struct WINBIO_VERSION
{
	public uint32 MajorVersion;
	public uint32 MinorVersion;
}

[CRepr]
public struct WINBIO_IDENTITY
{
	[CRepr, Union]
	public struct _Value_e__Union
	{
		[CRepr]
		public struct _AccountSid_e__Struct
		{
			public uint32 Size;
			public uint8[68] Data;
		}
		public uint32 Null;
		public uint32 Wildcard;
		public Guid TemplateGuid;
		public _AccountSid_e__Struct AccountSid;
		public uint8[32] SecureId;
	}
	public uint32 Type;
	public _Value_e__Union Value;
}

[CRepr]
public struct WINBIO_SECURE_CONNECTION_PARAMS
{
	public uint32 PayloadSize;
	public uint16 Version;
	public uint16 Flags;
}

[CRepr]
public struct WINBIO_SECURE_CONNECTION_DATA
{
	public uint32 Size;
	public uint16 Version;
	public uint16 Flags;
	public uint32 ModelCertificateSize;
	public uint32 IntermediateCA1Size;
	public uint32 IntermediateCA2Size;
}

[CRepr]
public struct WINBIO_BIR_DATA
{
	public uint32 Size;
	public uint32 Offset;
}

[CRepr]
public struct WINBIO_BIR
{
	public WINBIO_BIR_DATA HeaderBlock;
	public WINBIO_BIR_DATA StandardDataBlock;
	public WINBIO_BIR_DATA VendorDataBlock;
	public WINBIO_BIR_DATA SignatureBlock;
}

[CRepr]
public struct WINBIO_REGISTERED_FORMAT
{
	public uint16 Owner;
	public uint16 Type;
}

[CRepr]
public struct WINBIO_BIR_HEADER
{
	[CRepr]
	public struct _ValidityPeriod_e__Struct
	{
		public LARGE_INTEGER BeginDate;
		public LARGE_INTEGER EndDate;
	}
	public uint16 ValidFields;
	public uint8 HeaderVersion;
	public uint8 PatronHeaderVersion;
	public uint8 DataFlags;
	public uint32 Type;
	public uint8 Subtype;
	public uint8 Purpose;
	public int8 DataQuality;
	public LARGE_INTEGER CreationDate;
	public _ValidityPeriod_e__Struct ValidityPeriod;
	public WINBIO_REGISTERED_FORMAT BiometricDataFormat;
	public WINBIO_REGISTERED_FORMAT ProductId;
}

[CRepr]
public struct WINBIO_BDB_ANSI_381_HEADER
{
	public uint64 RecordLength;
	public uint32 FormatIdentifier;
	public uint32 VersionNumber;
	public WINBIO_REGISTERED_FORMAT ProductId;
	public uint16 CaptureDeviceId;
	public uint16 ImageAcquisitionLevel;
	public uint16 HorizontalScanResolution;
	public uint16 VerticalScanResolution;
	public uint16 HorizontalImageResolution;
	public uint16 VerticalImageResolution;
	public uint8 ElementCount;
	public uint8 ScaleUnits;
	public uint8 PixelDepth;
	public uint8 ImageCompressionAlg;
	public uint16 Reserved;
}

[CRepr]
public struct WINBIO_BDB_ANSI_381_RECORD
{
	public uint32 BlockLength;
	public uint16 HorizontalLineLength;
	public uint16 VerticalLineLength;
	public uint8 Position;
	public uint8 CountOfViews;
	public uint8 ViewNumber;
	public uint8 ImageQuality;
	public uint8 ImpressionType;
	public uint8 Reserved;
}

[CRepr]
public struct WINBIO_SECURE_BUFFER_HEADER_V1
{
	public uint32 Type;
	public uint32 Size;
	public uint32 Flags;
	public uint64 ValidationTag;
}

[CRepr]
public struct WINBIO_EVENT
{
	[CRepr, Union]
	public struct _Parameters_e__Union
	{
		[CRepr]
		public struct _UnclaimedIdentify_e__Struct
		{
			public uint32 UnitId;
			public WINBIO_IDENTITY Identity;
			public uint8 SubFactor;
			public uint32 RejectDetail;
		}
		[CRepr]
		public struct _Unclaimed_e__Struct
		{
			public uint32 UnitId;
			public uint32 RejectDetail;
		}
		[CRepr]
		public struct _Error_e__Struct
		{
			public HRESULT ErrorCode;
		}
		public _Unclaimed_e__Struct Unclaimed;
		public _UnclaimedIdentify_e__Struct UnclaimedIdentify;
		public _Error_e__Struct Error;
	}
	public uint32 Type;
	public _Parameters_e__Union Parameters;
}

[CRepr, Union]
public struct WINBIO_PRESENCE_PROPERTIES
{
	[CRepr]
	public struct _Iris_e__Struct
	{
		public RECT EyeBoundingBox_1;
		public RECT EyeBoundingBox_2;
		public POINT PupilCenter_1;
		public POINT PupilCenter_2;
		public int32 Distance;
	}
	[CRepr]
	public struct _FacialFeatures_e__Struct
	{
		[CRepr]
		public struct _OpaqueEngineData_e__Struct
		{
			public Guid AdapterId;
			public uint32[78] Data;
		}
		public RECT BoundingBox;
		public int32 Distance;
		public _OpaqueEngineData_e__Struct OpaqueEngineData;
	}
	public _FacialFeatures_e__Struct FacialFeatures;
	public _Iris_e__Struct Iris;
}

[CRepr]
public struct WINBIO_PRESENCE
{
	[CRepr]
	public struct _Authorization_e__Struct
	{
		public uint32 Size;
		public uint8[32] Data;
	}
	public uint32 Factor;
	public uint8 SubFactor;
	public HRESULT Status;
	public uint32 RejectDetail;
	public WINBIO_IDENTITY Identity;
	public uint64 TrackingId;
	public uint64 Ticket;
	public WINBIO_PRESENCE_PROPERTIES Properties;
	public _Authorization_e__Struct Authorization;
}

[CRepr]
public struct WINBIO_BSP_SCHEMA
{
	public uint32 BiometricFactor;
	public Guid BspId;
	public uint16[256] Description;
	public uint16[256] Vendor;
	public WINBIO_VERSION Version;
}

[CRepr]
public struct WINBIO_UNIT_SCHEMA
{
	public uint32 UnitId;
	public uint32 PoolType;
	public uint32 BiometricFactor;
	public uint32 SensorSubType;
	public uint32 Capabilities;
	public uint16[256] DeviceInstanceId;
	public uint16[256] Description;
	public uint16[256] Manufacturer;
	public uint16[256] Model;
	public uint16[256] SerialNumber;
	public WINBIO_VERSION FirmwareVersion;
}

[CRepr]
public struct WINBIO_STORAGE_SCHEMA
{
	public uint32 BiometricFactor;
	public Guid DatabaseId;
	public Guid DataFormat;
	public uint32 Attributes;
	public uint16[256] FilePath;
	public uint16[256] ConnectionString;
}

[CRepr]
public struct WINBIO_EXTENDED_SENSOR_INFO
{
	[CRepr, Union]
	public struct _Specific_e__Union
	{
		[CRepr]
		public struct _Iris_e__Struct
		{
			public RECT FrameSize;
			public POINT FrameOffset;
			public uint32 MandatoryOrientation;
		}
		[CRepr]
		public struct _FacialFeatures_e__Struct
		{
			[CRepr]
			public struct _HardwareInfo_e__Struct
			{
				public char16[260] ColorSensorId;
				public char16[260] InfraredSensorId;
				public uint32 InfraredSensorRotationAngle;
			}
			public RECT FrameSize;
			public POINT FrameOffset;
			public uint32 MandatoryOrientation;
			public _HardwareInfo_e__Struct HardwareInfo;
		}
		[CRepr]
		public struct _Fingerprint_e__Struct
		{
			public uint32 Reserved;
		}
		[CRepr]
		public struct _Voice_e__Struct
		{
			public uint32 Reserved;
		}
		public uint32 Null;
		public _FacialFeatures_e__Struct FacialFeatures;
		public _Fingerprint_e__Struct Fingerprint;
		public _Iris_e__Struct Iris;
		public _Voice_e__Struct Voice;
	}
	public uint32 GenericSensorCapabilities;
	public uint32 Factor;
	public _Specific_e__Union Specific;
}

[CRepr]
public struct WINBIO_EXTENDED_ENGINE_INFO
{
	[CRepr, Union]
	public struct _Specific_e__Union
	{
		[CRepr]
		public struct _Voice_e__Struct
		{
			[CRepr]
			public struct _EnrollmentRequirements_e__Struct
			{
				public uint32 Null;
			}
			public uint32 Capabilities;
			public _EnrollmentRequirements_e__Struct EnrollmentRequirements;
		}
		[CRepr]
		public struct _Iris_e__Struct
		{
			[CRepr]
			public struct _EnrollmentRequirements_e__Struct
			{
				public uint32 Null;
			}
			public uint32 Capabilities;
			public _EnrollmentRequirements_e__Struct EnrollmentRequirements;
		}
		[CRepr]
		public struct _Fingerprint_e__Struct
		{
			[CRepr]
			public struct _EnrollmentRequirements_e__Struct
			{
				public uint32 GeneralSamples;
				public uint32 Center;
				public uint32 TopEdge;
				public uint32 BottomEdge;
				public uint32 LeftEdge;
				public uint32 RightEdge;
			}
			public uint32 Capabilities;
			public _EnrollmentRequirements_e__Struct EnrollmentRequirements;
		}
		[CRepr]
		public struct _FacialFeatures_e__Struct
		{
			[CRepr]
			public struct _EnrollmentRequirements_e__Struct
			{
				public uint32 Null;
			}
			public uint32 Capabilities;
			public _EnrollmentRequirements_e__Struct EnrollmentRequirements;
		}
		public uint32 Null;
		public _FacialFeatures_e__Struct FacialFeatures;
		public _Fingerprint_e__Struct Fingerprint;
		public _Iris_e__Struct Iris;
		public _Voice_e__Struct Voice;
	}
	public uint32 GenericEngineCapabilities;
	public uint32 Factor;
	public _Specific_e__Union Specific;
}

[CRepr]
public struct WINBIO_EXTENDED_STORAGE_INFO
{
	[CRepr, Union]
	public struct _Specific_e__Union
	{
		[CRepr]
		public struct _Iris_e__Struct
		{
			public uint32 Capabilities;
		}
		[CRepr]
		public struct _FacialFeatures_e__Struct
		{
			public uint32 Capabilities;
		}
		[CRepr]
		public struct _Fingerprint_e__Struct
		{
			public uint32 Capabilities;
		}
		[CRepr]
		public struct _Voice_e__Struct
		{
			public uint32 Capabilities;
		}
		public uint32 Null;
		public _FacialFeatures_e__Struct FacialFeatures;
		public _Fingerprint_e__Struct Fingerprint;
		public _Iris_e__Struct Iris;
		public _Voice_e__Struct Voice;
	}
	public uint32 GenericStorageCapabilities;
	public uint32 Factor;
	public _Specific_e__Union Specific;
}

[CRepr]
public struct WINBIO_EXTENDED_ENROLLMENT_STATUS
{
	[CRepr, Union]
	public struct _Specific_e__Union
	{
		[CRepr]
		public struct _Iris_e__Struct
		{
			[CRepr]
			public struct _Point3D_e__Struct
			{
				public double X;
				public double Y;
				public double Z;
			}
			public RECT EyeBoundingBox_1;
			public RECT EyeBoundingBox_2;
			public POINT PupilCenter_1;
			public POINT PupilCenter_2;
			public int32 Distance;
			public uint32 GridPointCompletionPercent;
			public uint16 GridPointIndex;
			public _Point3D_e__Struct Point3D;
			public BOOL StopCaptureAndShowCriticalFeedback;
		}
		[CRepr]
		public struct _FacialFeatures_e__Struct
		{
			[CRepr]
			public struct _OpaqueEngineData_e__Struct
			{
				public Guid AdapterId;
				public uint32[78] Data;
			}
			public RECT BoundingBox;
			public int32 Distance;
			public _OpaqueEngineData_e__Struct OpaqueEngineData;
		}
		[CRepr]
		public struct _Voice_e__Struct
		{
			public uint32 Reserved;
		}
		[CRepr]
		public struct _Fingerprint_e__Struct
		{
			public uint32 GeneralSamples;
			public uint32 Center;
			public uint32 TopEdge;
			public uint32 BottomEdge;
			public uint32 LeftEdge;
			public uint32 RightEdge;
		}
		public uint32 Null;
		public _FacialFeatures_e__Struct FacialFeatures;
		public _Fingerprint_e__Struct Fingerprint;
		public _Iris_e__Struct Iris;
		public _Voice_e__Struct Voice;
	}
	public HRESULT TemplateStatus;
	public uint32 RejectDetail;
	public uint32 PercentComplete;
	public uint32 Factor;
	public uint8 SubFactor;
	public _Specific_e__Union Specific;
}

[CRepr]
public struct WINBIO_EXTENDED_UNIT_STATUS
{
	public uint32 Availability;
	public uint32 ReasonCode;
}

[CRepr]
public struct WINBIO_FP_BU_STATE
{
	public BOOL SensorAttached;
	public HRESULT CreationResult;
}

[CRepr]
public struct WINBIO_ANTI_SPOOF_POLICY
{
	public WINBIO_ANTI_SPOOF_POLICY_ACTION Action;
	public WINBIO_POLICY_SOURCE Source;
}

[CRepr]
public struct WINBIO_EXTENDED_ENROLLMENT_PARAMETERS
{
	public uint Size;
	public uint8 SubFactor;
}

[CRepr]
public struct WINBIO_ACCOUNT_POLICY
{
	public WINBIO_IDENTITY Identity;
	public WINBIO_ANTI_SPOOF_POLICY_ACTION AntiSpoofBehavior;
}

[CRepr]
public struct WINBIO_PROTECTION_POLICY
{
	public uint32 Version;
	public WINBIO_IDENTITY Identity;
	public Guid DatabaseId;
	public uint64 UserState;
	public uint PolicySize;
	public uint8[128] Policy;
}

[CRepr]
public struct WINBIO_GESTURE_METADATA
{
	public uint Size;
	public uint32 BiometricType;
	public uint32 MatchType;
	public uint32 ProtectionType;
}

[CRepr]
public struct WINBIO_ASYNC_RESULT
{
	[CRepr, Union]
	public struct _Parameters_e__Union
	{
		[CRepr]
		public struct _NotifyUnitStatusChange_e__Struct
		{
			public WINBIO_EXTENDED_UNIT_STATUS ExtendedStatus;
		}
		[CRepr]
		public struct _MonitorPresence_e__Struct
		{
			public uint32 ChangeType;
			public uint PresenceCount;
			public WINBIO_PRESENCE* PresenceArray;
		}
		[CRepr]
		public struct _IdentifyAndReleaseTicket_e__Struct
		{
			public WINBIO_IDENTITY Identity;
			public uint8 SubFactor;
			public uint32 RejectDetail;
			public uint64 Ticket;
		}
		[CRepr]
		public struct _EnumDatabases_e__Struct
		{
			public uint StorageCount;
			public WINBIO_STORAGE_SCHEMA* StorageSchemaArray;
		}
		[CRepr]
		public struct _EnumServiceProviders_e__Struct
		{
			public uint BspCount;
			public WINBIO_BSP_SCHEMA* BspSchemaArray;
		}
		[CRepr]
		public struct _GetEvent_e__Struct
		{
			public WINBIO_EVENT Event;
		}
		[CRepr]
		public struct _GetProperty_e__Struct
		{
			public uint32 PropertyType;
			public uint32 PropertyId;
			public WINBIO_IDENTITY Identity;
			public uint8 SubFactor;
			public uint PropertyBufferSize;
			public void* PropertyBuffer;
		}
		[CRepr]
		public struct _CaptureSample_e__Struct
		{
			public WINBIO_BIR* Sample;
			public uint SampleSize;
			public uint32 RejectDetail;
		}
		[CRepr]
		public struct _EnrollCommit_e__Struct
		{
			public WINBIO_IDENTITY Identity;
			public BOOLEAN IsNewTemplate;
		}
		[CRepr]
		public struct _EnrollBegin_e__Struct
		{
			public uint8 SubFactor;
		}
		[CRepr]
		public struct _Verify_e__Struct
		{
			public BOOLEAN Match;
			public uint32 RejectDetail;
		}
		[CRepr]
		public struct _EnrollSelect_e__Struct
		{
			public uint64 SelectorValue;
		}
		[CRepr]
		public struct _EnumBiometricUnits_e__Struct
		{
			public uint UnitCount;
			public WINBIO_UNIT_SCHEMA* UnitSchemaArray;
		}
		[CRepr]
		public struct _SetProperty_e__Struct
		{
			public uint32 PropertyType;
			public uint32 PropertyId;
			public WINBIO_IDENTITY Identity;
			public uint8 SubFactor;
			public uint PropertyBufferSize;
			public void* PropertyBuffer;
		}
		[CRepr]
		public struct _EnumEnrollments_e__Struct
		{
			public WINBIO_IDENTITY Identity;
			public uint SubFactorCount;
			public uint8* SubFactorArray;
		}
		[CRepr]
		public struct _Identify_e__Struct
		{
			public WINBIO_IDENTITY Identity;
			public uint8 SubFactor;
			public uint32 RejectDetail;
		}
		[CRepr]
		public struct _VerifyAndReleaseTicket_e__Struct
		{
			public BOOLEAN Match;
			public uint32 RejectDetail;
			public uint64 Ticket;
		}
		[CRepr]
		public struct _DeleteTemplate_e__Struct
		{
			public WINBIO_IDENTITY Identity;
			public uint8 SubFactor;
		}
		[CRepr]
		public struct _GetProtectionPolicy_e__Struct
		{
			public WINBIO_IDENTITY Identity;
			public WINBIO_PROTECTION_POLICY Policy;
		}
		[CRepr]
		public struct _EnrollCapture_e__Struct
		{
			public uint32 RejectDetail;
		}
		[CRepr]
		public struct _ControlUnit_e__Struct
		{
			public WINBIO_COMPONENT Component;
			public uint32 ControlCode;
			public uint32 OperationStatus;
			public uint8* SendBuffer;
			public uint SendBufferSize;
			public uint8* ReceiveBuffer;
			public uint ReceiveBufferSize;
			public uint ReceiveDataSize;
		}
		public _Verify_e__Struct Verify;
		public _Identify_e__Struct Identify;
		public _EnrollBegin_e__Struct EnrollBegin;
		public _EnrollCapture_e__Struct EnrollCapture;
		public _EnrollCommit_e__Struct EnrollCommit;
		public _EnumEnrollments_e__Struct EnumEnrollments;
		public _CaptureSample_e__Struct CaptureSample;
		public _DeleteTemplate_e__Struct DeleteTemplate;
		public _GetProperty_e__Struct GetProperty;
		public _SetProperty_e__Struct SetProperty;
		public _GetEvent_e__Struct GetEvent;
		public _ControlUnit_e__Struct ControlUnit;
		public _EnumServiceProviders_e__Struct EnumServiceProviders;
		public _EnumBiometricUnits_e__Struct EnumBiometricUnits;
		public _EnumDatabases_e__Struct EnumDatabases;
		public _VerifyAndReleaseTicket_e__Struct VerifyAndReleaseTicket;
		public _IdentifyAndReleaseTicket_e__Struct IdentifyAndReleaseTicket;
		public _EnrollSelect_e__Struct EnrollSelect;
		public _MonitorPresence_e__Struct MonitorPresence;
		public _GetProtectionPolicy_e__Struct GetProtectionPolicy;
		public _NotifyUnitStatusChange_e__Struct NotifyUnitStatusChange;
	}
	public uint32 SessionHandle;
	public uint32 Operation;
	public uint64 SequenceNumber;
	public int64 TimeStamp;
	public HRESULT ApiStatus;
	public uint32 UnitId;
	public void* UserData;
	public _Parameters_e__Union Parameters;
}

[CRepr]
public struct _WINIBIO_SENSOR_CONTEXT
{
}

[CRepr]
public struct _WINIBIO_ENGINE_CONTEXT
{
}

[CRepr]
public struct _WINIBIO_STORAGE_CONTEXT
{
}

[CRepr]
public struct WINBIO_STORAGE_RECORD
{
	public WINBIO_IDENTITY* Identity;
	public uint8 SubFactor;
	public uint32* IndexVector;
	public uint IndexElementCount;
	public uint8* TemplateBlob;
	public uint TemplateBlobSize;
	public uint8* PayloadBlob;
	public uint PayloadBlobSize;
}

[CRepr]
public struct WINBIO_PIPELINE
{
	public HANDLE SensorHandle;
	public HANDLE EngineHandle;
	public HANDLE StorageHandle;
	public WINBIO_SENSOR_INTERFACE* SensorInterface;
	public WINBIO_ENGINE_INTERFACE* EngineInterface;
	public WINBIO_STORAGE_INTERFACE* StorageInterface;
	public _WINIBIO_SENSOR_CONTEXT* SensorContext;
	public _WINIBIO_ENGINE_CONTEXT* EngineContext;
	public _WINIBIO_STORAGE_CONTEXT* StorageContext;
	public WINBIO_FRAMEWORK_INTERFACE* FrameworkInterface;
}

[CRepr]
public struct WINBIO_ADAPTER_INTERFACE_VERSION
{
	public uint16 MajorVersion;
	public uint16 MinorVersion;
}

[CRepr]
public struct WINBIO_SENSOR_INTERFACE
{
	public WINBIO_ADAPTER_INTERFACE_VERSION Version;
	public uint32 Type;
	public uint Size;
	public Guid AdapterId;
	public PIBIO_SENSOR_ATTACH_FN Attach;
	public PIBIO_SENSOR_DETACH_FN Detach;
	public PIBIO_SENSOR_CLEAR_CONTEXT_FN ClearContext;
	public PIBIO_SENSOR_QUERY_STATUS_FN QueryStatus;
	public PIBIO_SENSOR_RESET_FN Reset;
	public PIBIO_SENSOR_SET_MODE_FN SetMode;
	public PIBIO_SENSOR_SET_INDICATOR_STATUS_FN SetIndicatorStatus;
	public PIBIO_SENSOR_GET_INDICATOR_STATUS_FN GetIndicatorStatus;
	public PIBIO_SENSOR_START_CAPTURE_FN StartCapture;
	public PIBIO_SENSOR_FINISH_CAPTURE_FN FinishCapture;
	public PIBIO_SENSOR_EXPORT_SENSOR_DATA_FN ExportSensorData;
	public PIBIO_SENSOR_CANCEL_FN Cancel;
	public PIBIO_SENSOR_PUSH_DATA_TO_ENGINE_FN PushDataToEngine;
	public PIBIO_SENSOR_CONTROL_UNIT_FN ControlUnit;
	public PIBIO_SENSOR_CONTROL_UNIT_PRIVILEGED_FN ControlUnitPrivileged;
	public PIBIO_SENSOR_NOTIFY_POWER_CHANGE_FN NotifyPowerChange;
	public PIBIO_SENSOR_PIPELINE_INIT_FN PipelineInit;
	public PIBIO_SENSOR_PIPELINE_CLEANUP_FN PipelineCleanup;
	public PIBIO_SENSOR_ACTIVATE_FN Activate;
	public PIBIO_SENSOR_DEACTIVATE_FN Deactivate;
	public PIBIO_SENSOR_QUERY_EXTENDED_INFO_FN QueryExtendedInfo;
	public PIBIO_SENSOR_QUERY_CALIBRATION_FORMATS_FN QueryCalibrationFormats;
	public PIBIO_SENSOR_SET_CALIBRATION_FORMAT_FN SetCalibrationFormat;
	public PIBIO_SENSOR_ACCEPT_CALIBRATION_DATA_FN AcceptCalibrationData;
	public PIBIO_SENSOR_ASYNC_IMPORT_RAW_BUFFER_FN AsyncImportRawBuffer;
	public PIBIO_SENSOR_ASYNC_IMPORT_SECURE_BUFFER_FN AsyncImportSecureBuffer;
	public PIBIO_SENSOR_QUERY_PRIVATE_SENSOR_TYPE_FN QueryPrivateSensorType;
	public PIBIO_SENSOR_CONNECT_SECURE_FN ConnectSecure;
	public PIBIO_SENSOR_START_CAPTURE_EX_FN StartCaptureEx;
	public PIBIO_SENSOR_START_NOTIFY_WAKE_FN StartNotifyWake;
	public PIBIO_SENSOR_FINISH_NOTIFY_WAKE_FN FinishNotifyWake;
}

[CRepr]
public struct WINBIO_ENGINE_INTERFACE
{
	public WINBIO_ADAPTER_INTERFACE_VERSION Version;
	public uint32 Type;
	public uint Size;
	public Guid AdapterId;
	public PIBIO_ENGINE_ATTACH_FN Attach;
	public PIBIO_ENGINE_DETACH_FN Detach;
	public PIBIO_ENGINE_CLEAR_CONTEXT_FN ClearContext;
	public PIBIO_ENGINE_QUERY_PREFERRED_FORMAT_FN QueryPreferredFormat;
	public PIBIO_ENGINE_QUERY_INDEX_VECTOR_SIZE_FN QueryIndexVectorSize;
	public PIBIO_ENGINE_QUERY_HASH_ALGORITHMS_FN QueryHashAlgorithms;
	public PIBIO_ENGINE_SET_HASH_ALGORITHM_FN SetHashAlgorithm;
	public PIBIO_ENGINE_QUERY_SAMPLE_HINT_FN QuerySampleHint;
	public PIBIO_ENGINE_ACCEPT_SAMPLE_DATA_FN AcceptSampleData;
	public PIBIO_ENGINE_EXPORT_ENGINE_DATA_FN ExportEngineData;
	public PIBIO_ENGINE_VERIFY_FEATURE_SET_FN VerifyFeatureSet;
	public PIBIO_ENGINE_IDENTIFY_FEATURE_SET_FN IdentifyFeatureSet;
	public PIBIO_ENGINE_CREATE_ENROLLMENT_FN CreateEnrollment;
	public PIBIO_ENGINE_UPDATE_ENROLLMENT_FN UpdateEnrollment;
	public PIBIO_ENGINE_GET_ENROLLMENT_STATUS_FN GetEnrollmentStatus;
	public PIBIO_ENGINE_GET_ENROLLMENT_HASH_FN GetEnrollmentHash;
	public PIBIO_ENGINE_CHECK_FOR_DUPLICATE_FN CheckForDuplicate;
	public PIBIO_ENGINE_COMMIT_ENROLLMENT_FN CommitEnrollment;
	public PIBIO_ENGINE_DISCARD_ENROLLMENT_FN DiscardEnrollment;
	public PIBIO_ENGINE_CONTROL_UNIT_FN ControlUnit;
	public PIBIO_ENGINE_CONTROL_UNIT_PRIVILEGED_FN ControlUnitPrivileged;
	public PIBIO_ENGINE_NOTIFY_POWER_CHANGE_FN NotifyPowerChange;
	public PIBIO_ENGINE_RESERVED_1_FN Reserved_1;
	public PIBIO_ENGINE_PIPELINE_INIT_FN PipelineInit;
	public PIBIO_ENGINE_PIPELINE_CLEANUP_FN PipelineCleanup;
	public PIBIO_ENGINE_ACTIVATE_FN Activate;
	public PIBIO_ENGINE_DEACTIVATE_FN Deactivate;
	public PIBIO_ENGINE_QUERY_EXTENDED_INFO_FN QueryExtendedInfo;
	public PIBIO_ENGINE_IDENTIFY_ALL_FN IdentifyAll;
	public PIBIO_ENGINE_SET_ENROLLMENT_SELECTOR_FN SetEnrollmentSelector;
	public PIBIO_ENGINE_SET_ENROLLMENT_PARAMETERS_FN SetEnrollmentParameters;
	public PIBIO_ENGINE_QUERY_EXTENDED_ENROLLMENT_STATUS_FN QueryExtendedEnrollmentStatus;
	public PIBIO_ENGINE_REFRESH_CACHE_FN RefreshCache;
	public PIBIO_ENGINE_SELECT_CALIBRATION_FORMAT_FN SelectCalibrationFormat;
	public PIBIO_ENGINE_QUERY_CALIBRATION_DATA_FN QueryCalibrationData;
	public PIBIO_ENGINE_SET_ACCOUNT_POLICY_FN SetAccountPolicy;
	public PIBIO_ENGINE_CREATE_KEY_FN CreateKey;
	public PIBIO_ENGINE_IDENTIFY_FEATURE_SET_SECURE_FN IdentifyFeatureSetSecure;
	public PIBIO_ENGINE_ACCEPT_PRIVATE_SENSOR_TYPE_INFO_FN AcceptPrivateSensorTypeInfo;
	public PIBIO_ENGINE_CREATE_ENROLLMENT_AUTHENTICATED_FN CreateEnrollmentAuthenticated;
	public PIBIO_ENGINE_IDENTIFY_FEATURE_SET_AUTHENTICATED_FN IdentifyFeatureSetAuthenticated;
}

[CRepr]
public struct WINBIO_STORAGE_INTERFACE
{
	public WINBIO_ADAPTER_INTERFACE_VERSION Version;
	public uint32 Type;
	public uint Size;
	public Guid AdapterId;
	public PIBIO_STORAGE_ATTACH_FN Attach;
	public PIBIO_STORAGE_DETACH_FN Detach;
	public PIBIO_STORAGE_CLEAR_CONTEXT_FN ClearContext;
	public PIBIO_STORAGE_CREATE_DATABASE_FN CreateDatabase;
	public PIBIO_STORAGE_ERASE_DATABASE_FN EraseDatabase;
	public PIBIO_STORAGE_OPEN_DATABASE_FN OpenDatabase;
	public PIBIO_STORAGE_CLOSE_DATABASE_FN CloseDatabase;
	public PIBIO_STORAGE_GET_DATA_FORMAT_FN GetDataFormat;
	public PIBIO_STORAGE_GET_DATABASE_SIZE_FN GetDatabaseSize;
	public PIBIO_STORAGE_ADD_RECORD_FN AddRecord;
	public PIBIO_STORAGE_DELETE_RECORD_FN DeleteRecord;
	public PIBIO_STORAGE_QUERY_BY_SUBJECT_FN QueryBySubject;
	public PIBIO_STORAGE_QUERY_BY_CONTENT_FN QueryByContent;
	public PIBIO_STORAGE_GET_RECORD_COUNT_FN GetRecordCount;
	public PIBIO_STORAGE_FIRST_RECORD_FN FirstRecord;
	public PIBIO_STORAGE_NEXT_RECORD_FN NextRecord;
	public PIBIO_STORAGE_GET_CURRENT_RECORD_FN GetCurrentRecord;
	public PIBIO_STORAGE_CONTROL_UNIT_FN ControlUnit;
	public PIBIO_STORAGE_CONTROL_UNIT_PRIVILEGED_FN ControlUnitPrivileged;
	public PIBIO_STORAGE_NOTIFY_POWER_CHANGE_FN NotifyPowerChange;
	public PIBIO_STORAGE_PIPELINE_INIT_FN PipelineInit;
	public PIBIO_STORAGE_PIPELINE_CLEANUP_FN PipelineCleanup;
	public PIBIO_STORAGE_ACTIVATE_FN Activate;
	public PIBIO_STORAGE_DEACTIVATE_FN Deactivate;
	public PIBIO_STORAGE_QUERY_EXTENDED_INFO_FN QueryExtendedInfo;
	public PIBIO_STORAGE_NOTIFY_DATABASE_CHANGE_FN NotifyDatabaseChange;
	public PIBIO_STORAGE_RESERVED_1_FN Reserved1;
	public PIBIO_STORAGE_RESERVED_2_FN Reserved2;
	public PIBIO_STORAGE_UPDATE_RECORD_BEGIN_FN UpdateRecordBegin;
	public PIBIO_STORAGE_UPDATE_RECORD_COMMIT_FN UpdateRecordCommit;
}

[CRepr]
public struct WINBIO_FRAMEWORK_INTERFACE
{
	public WINBIO_ADAPTER_INTERFACE_VERSION Version;
	public uint32 Type;
	public uint Size;
	public Guid AdapterId;
	public PIBIO_FRAMEWORK_SET_UNIT_STATUS_FN SetUnitStatus;
	public PIBIO_STORAGE_ATTACH_FN VsmStorageAttach;
	public PIBIO_STORAGE_DETACH_FN VsmStorageDetach;
	public PIBIO_STORAGE_CLEAR_CONTEXT_FN VsmStorageClearContext;
	public PIBIO_STORAGE_CREATE_DATABASE_FN VsmStorageCreateDatabase;
	public PIBIO_STORAGE_OPEN_DATABASE_FN VsmStorageOpenDatabase;
	public PIBIO_STORAGE_CLOSE_DATABASE_FN VsmStorageCloseDatabase;
	public PIBIO_STORAGE_DELETE_RECORD_FN VsmStorageDeleteRecord;
	public PIBIO_STORAGE_NOTIFY_POWER_CHANGE_FN VsmStorageNotifyPowerChange;
	public PIBIO_STORAGE_PIPELINE_INIT_FN VsmStoragePipelineInit;
	public PIBIO_STORAGE_PIPELINE_CLEANUP_FN VsmStoragePipelineCleanup;
	public PIBIO_STORAGE_ACTIVATE_FN VsmStorageActivate;
	public PIBIO_STORAGE_DEACTIVATE_FN VsmStorageDeactivate;
	public PIBIO_STORAGE_QUERY_EXTENDED_INFO_FN VsmStorageQueryExtendedInfo;
	public PIBIO_FRAMEWORK_VSM_CACHE_CLEAR_FN VsmStorageCacheClear;
	public PIBIO_FRAMEWORK_VSM_CACHE_IMPORT_BEGIN_FN VsmStorageCacheImportBegin;
	public PIBIO_FRAMEWORK_VSM_CACHE_IMPORT_NEXT_FN VsmStorageCacheImportNext;
	public PIBIO_FRAMEWORK_VSM_CACHE_IMPORT_END_FN VsmStorageCacheImportEnd;
	public PIBIO_FRAMEWORK_VSM_CACHE_EXPORT_BEGIN_FN VsmStorageCacheExportBegin;
	public PIBIO_FRAMEWORK_VSM_CACHE_EXPORT_NEXT_FN VsmStorageCacheExportNext;
	public PIBIO_FRAMEWORK_VSM_CACHE_EXPORT_END_FN VsmStorageCacheExportEnd;
	public PIBIO_SENSOR_ATTACH_FN VsmSensorAttach;
	public PIBIO_SENSOR_DETACH_FN VsmSensorDetach;
	public PIBIO_SENSOR_CLEAR_CONTEXT_FN VsmSensorClearContext;
	public PIBIO_SENSOR_PUSH_DATA_TO_ENGINE_FN VsmSensorPushDataToEngine;
	public PIBIO_SENSOR_NOTIFY_POWER_CHANGE_FN VsmSensorNotifyPowerChange;
	public PIBIO_SENSOR_PIPELINE_INIT_FN VsmSensorPipelineInit;
	public PIBIO_SENSOR_PIPELINE_CLEANUP_FN VsmSensorPipelineCleanup;
	public PIBIO_SENSOR_ACTIVATE_FN VsmSensorActivate;
	public PIBIO_SENSOR_DEACTIVATE_FN VsmSensorDeactivate;
	public PIBIO_SENSOR_ASYNC_IMPORT_RAW_BUFFER_FN VsmSensorAsyncImportRawBuffer;
	public PIBIO_SENSOR_ASYNC_IMPORT_SECURE_BUFFER_FN VsmSensorAsyncImportSecureBuffer;
	public PIBIO_FRAMEWORK_VSM_STORAGE_RESERVED_1_FN Reserved1;
	public PIBIO_FRAMEWORK_VSM_STORAGE_RESERVED_2_FN Reserved2;
	public PIBIO_FRAMEWORK_VSM_STORAGE_RESERVED_3_FN Reserved3;
	public PIBIO_STORAGE_RESERVED_1_FN Reserved4;
	public PIBIO_STORAGE_RESERVED_2_FN Reserved5;
	public PIBIO_FRAMEWORK_ALLOCATE_MEMORY_FN AllocateMemory;
	public PIBIO_FRAMEWORK_FREE_MEMORY_FN FreeMemory;
	public PIBIO_FRAMEWORK_GET_PROPERTY_FN GetProperty;
	public PIBIO_FRAMEWORK_LOCK_AND_VALIDATE_SECURE_BUFFER_FN LockAndValidateSecureBuffer;
	public PIBIO_FRAMEWORK_RELEASE_SECURE_BUFFER_FN ReleaseSecureBuffer;
	public PIBIO_FRAMEWORK_VSM_QUERY_AUTHORIZED_ENROLLMENTS_FN QueryAuthorizedEnrollments;
	public PIBIO_FRAMEWORK_VSM_DECRYPT_SAMPLE_FN DecryptSample;
}

[CRepr]
public struct WINBIO_SENSOR_ATTRIBUTES
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public WINBIO_VERSION WinBioVersion;
	public uint32 SensorType;
	public uint32 SensorSubType;
	public uint32 Capabilities;
	public uint16[256] ManufacturerName;
	public uint16[256] ModelName;
	public uint16[256] SerialNumber;
	public WINBIO_VERSION FirmwareVersion;
	public uint32 SupportedFormatEntries;
	public WINBIO_REGISTERED_FORMAT* SupportedFormat mut => &SupportedFormat_impl;
	private WINBIO_REGISTERED_FORMAT[ANYSIZE_ARRAY] SupportedFormat_impl;
}

[CRepr]
public struct WINBIO_DATA
{
	public uint32 Size;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct WINBIO_UPDATE_FIRMWARE
{
	public uint32 PayloadSize;
	public WINBIO_DATA FirmwareData;
}

[CRepr]
public struct WINBIO_CALIBRATION_INFO
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public WINBIO_DATA CalibrationData;
}

[CRepr]
public struct WINBIO_DIAGNOSTICS
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public uint32 SensorStatus;
	public WINBIO_DATA VendorDiagnostics;
}

[CRepr]
public struct WINBIO_BLANK_PAYLOAD
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
}

[CRepr]
public struct WINBIO_CAPTURE_PARAMETERS
{
	public uint32 PayloadSize;
	public uint8 Purpose;
	public WINBIO_REGISTERED_FORMAT Format;
	public Guid VendorFormat;
	public uint8 Flags;
}

[CRepr]
public struct WINBIO_CAPTURE_DATA
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public uint32 SensorStatus;
	public uint32 RejectDetail;
	public WINBIO_DATA CaptureData;
}

[CRepr]
public struct WINBIO_SUPPORTED_ALGORITHMS
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public uint32 NumberOfAlgorithms;
	public WINBIO_DATA AlgorithmData;
}

[CRepr]
public struct WINBIO_GET_INDICATOR
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public uint32 IndicatorStatus;
}

[CRepr]
public struct WINBIO_SET_INDICATOR
{
	public uint32 PayloadSize;
	public uint32 IndicatorStatus;
}

[CRepr]
public struct WINBIO_PRIVATE_SENSOR_TYPE_INFO
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public WINBIO_DATA PrivateSensorTypeInfo;
}

[CRepr]
public struct WINBIO_ENCRYPTED_CAPTURE_PARAMS
{
	public uint32 PayloadSize;
	public uint8 Purpose;
	public WINBIO_REGISTERED_FORMAT Format;
	public Guid VendorFormat;
	public uint8 Flags;
	public uint32 NonceSize;
}

[CRepr]
public struct WINBIO_NOTIFY_WAKE
{
	public uint32 PayloadSize;
	public HRESULT WinBioHresult;
	public uint32 Reason;
}

#endregion

#region Functions
public static
{
	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnumServiceProviders(uint32 Factor, WINBIO_BSP_SCHEMA** BspSchemaArray, uint* BspCount);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnumBiometricUnits(uint32 Factor, WINBIO_UNIT_SCHEMA** UnitSchemaArray, uint* UnitCount);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnumDatabases(uint32 Factor, WINBIO_STORAGE_SCHEMA** StorageSchemaArray, uint* StorageCount);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAsyncOpenFramework(WINBIO_ASYNC_NOTIFICATION_METHOD NotificationMethod, HWND TargetWindow, uint32 MessageCode, PWINBIO_ASYNC_COMPLETION_CALLBACK CallbackRoutine, void* UserData, BOOL AsynchronousOpen, uint32* FrameworkHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioCloseFramework(uint32 FrameworkHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAsyncEnumServiceProviders(uint32 FrameworkHandle, uint32 Factor);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAsyncEnumBiometricUnits(uint32 FrameworkHandle, uint32 Factor);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAsyncEnumDatabases(uint32 FrameworkHandle, uint32 Factor);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAsyncMonitorFrameworkChanges(uint32 FrameworkHandle, uint32 ChangeTypes);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioOpenSession(uint32 Factor, WINBIO_POOL PoolType, uint32 Flags, uint32* UnitArray, uint UnitCount, Guid* DatabaseId, uint32* SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAsyncOpenSession(uint32 Factor, WINBIO_POOL PoolType, uint32 Flags, uint32* UnitArray, uint UnitCount, Guid* DatabaseId, WINBIO_ASYNC_NOTIFICATION_METHOD NotificationMethod, HWND TargetWindow, uint32 MessageCode, PWINBIO_ASYNC_COMPLETION_CALLBACK CallbackRoutine, void* UserData, BOOL AsynchronousOpen, uint32* SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioCloseSession(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioVerify(uint32 SessionHandle, WINBIO_IDENTITY* Identity, uint8 SubFactor, uint32* UnitId, uint8* Match, uint32* RejectDetail);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioVerifyWithCallback(uint32 SessionHandle, WINBIO_IDENTITY* Identity, uint8 SubFactor, PWINBIO_VERIFY_CALLBACK VerifyCallback, void* VerifyCallbackContext);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioIdentify(uint32 SessionHandle, uint32* UnitId, WINBIO_IDENTITY* Identity, uint8* SubFactor, uint32* RejectDetail);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioIdentifyWithCallback(uint32 SessionHandle, PWINBIO_IDENTIFY_CALLBACK IdentifyCallback, void* IdentifyCallbackContext);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioWait(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioCancel(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioLocateSensor(uint32 SessionHandle, uint32* UnitId);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioLocateSensorWithCallback(uint32 SessionHandle, PWINBIO_LOCATE_SENSOR_CALLBACK LocateCallback, void* LocateCallbackContext);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnrollBegin(uint32 SessionHandle, uint8 SubFactor, uint32 UnitId);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnrollSelect(uint32 SessionHandle, uint64 SelectorValue);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnrollCapture(uint32 SessionHandle, uint32* RejectDetail);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnrollCaptureWithCallback(uint32 SessionHandle, PWINBIO_ENROLL_CAPTURE_CALLBACK EnrollCallback, void* EnrollCallbackContext);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnrollCommit(uint32 SessionHandle, WINBIO_IDENTITY* Identity, uint8* IsNewTemplate);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnrollDiscard(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioEnumEnrollments(uint32 SessionHandle, uint32 UnitId, WINBIO_IDENTITY* Identity, uint8** SubFactorArray, uint* SubFactorCount);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioImproveBegin(uint32 SessionHandle, uint32 UnitId);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioImproveEnd(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioRegisterEventMonitor(uint32 SessionHandle, uint32 EventMask, PWINBIO_EVENT_CALLBACK EventCallback, void* EventCallbackContext);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioUnregisterEventMonitor(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioMonitorPresence(uint32 SessionHandle, uint32 UnitId);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioCaptureSample(uint32 SessionHandle, uint8 Purpose, uint8 Flags, uint32* UnitId, WINBIO_BIR** Sample, uint* SampleSize, uint32* RejectDetail);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioCaptureSampleWithCallback(uint32 SessionHandle, uint8 Purpose, uint8 Flags, PWINBIO_CAPTURE_CALLBACK CaptureCallback, void* CaptureCallbackContext);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioDeleteTemplate(uint32 SessionHandle, uint32 UnitId, WINBIO_IDENTITY* Identity, uint8 SubFactor);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioLockUnit(uint32 SessionHandle, uint32 UnitId);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioUnlockUnit(uint32 SessionHandle, uint32 UnitId);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioControlUnit(uint32 SessionHandle, uint32 UnitId, WINBIO_COMPONENT Component, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioControlUnitPrivileged(uint32 SessionHandle, uint32 UnitId, WINBIO_COMPONENT Component, uint32 ControlCode, uint8* SendBuffer, uint SendBufferSize, uint8* ReceiveBuffer, uint ReceiveBufferSize, uint* ReceiveDataSize, uint32* OperationStatus);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioGetProperty(uint32 SessionHandle, uint32 PropertyType, uint32 PropertyId, uint32 UnitId, WINBIO_IDENTITY* Identity, uint8 SubFactor, void** PropertyBuffer, uint* PropertyBufferSize);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioSetProperty(uint32 SessionHandle, uint32 PropertyType, uint32 PropertyId, uint32 UnitId, WINBIO_IDENTITY* Identity, uint8 SubFactor, void* PropertyBuffer, uint PropertyBufferSize);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioFree(void* Address);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioSetCredential(WINBIO_CREDENTIAL_TYPE Type, uint8* Credential, uint CredentialSize, WINBIO_CREDENTIAL_FORMAT Format);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioRemoveCredential(WINBIO_IDENTITY Identity, WINBIO_CREDENTIAL_TYPE Type);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioRemoveAllCredentials();

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioRemoveAllDomainCredentials();

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioGetCredentialState(WINBIO_IDENTITY Identity, WINBIO_CREDENTIAL_TYPE Type, WINBIO_CREDENTIAL_STATE* CredentialState);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioLogonIdentifiedUser(uint32 SessionHandle);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioGetEnrolledFactors(WINBIO_IDENTITY* AccountOwner, uint32* EnrolledFactors);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinBioGetEnabledSetting(uint8* Value, WINBIO_SETTING_SOURCE* Source);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinBioGetLogonSetting(uint8* Value, WINBIO_SETTING_SOURCE* Source);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinBioGetDomainLogonSetting(uint8* Value, WINBIO_SETTING_SOURCE* Source);

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioAcquireFocus();

	[Import("winbio.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinBioReleaseFocus();

}
#endregion
