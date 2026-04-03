using Win32.Devices.Properties;
using Win32.Foundation;
using Win32.System.Registry;
using Win32.System.Threading;
using System;

namespace Win32.System.Power;

#region Constants
public static
{
	public const DEVPROPKEY PROCESSOR_NUMBER_PKEY = .(.(0x5724c81d, 0xd5af, 0x4c1f, 0xa1, 0x03, 0xa0, 0x6e, 0x28, 0xf2, 0x04, 0xc6), 1);
	public const Guid GUID_DEVICE_BATTERY = .(0x72631e54, 0x78a4, 0x11d0, 0xbc, 0xf7, 0x00, 0xaa, 0x00, 0xb7, 0xb3, 0x2a);
	public const Guid GUID_DEVICE_APPLICATIONLAUNCH_BUTTON = .(0x629758ee, 0x986e, 0x4d9e, 0x8e, 0x47, 0xde, 0x27, 0xf8, 0xab, 0x05, 0x4d);
	public const Guid GUID_DEVICE_SYS_BUTTON = .(0x4afa3d53, 0x74a7, 0x11d0, 0xbe, 0x5e, 0x00, 0xa0, 0xc9, 0x06, 0x28, 0x57);
	public const Guid GUID_DEVICE_LID = .(0x4afa3d52, 0x74a7, 0x11d0, 0xbe, 0x5e, 0x00, 0xa0, 0xc9, 0x06, 0x28, 0x57);
	public const Guid GUID_DEVICE_THERMAL_ZONE = .(0x4afa3d51, 0x74a7, 0x11d0, 0xbe, 0x5e, 0x00, 0xa0, 0xc9, 0x06, 0x28, 0x57);
	public const Guid GUID_DEVICE_FAN = .(0x05ecd13d, 0x81da, 0x4a2a, 0x8a, 0x4c, 0x52, 0x4f, 0x23, 0xdd, 0x4d, 0xc9);
	public const Guid GUID_DEVICE_PROCESSOR = .(0x97fadb10, 0x4e33, 0x40ae, 0x35, 0x9c, 0x8b, 0xef, 0x02, 0x9d, 0xbd, 0xd0);
	public const Guid GUID_DEVICE_MEMORY = .(0x3fd0f03d, 0x92e0, 0x45fb, 0xb7, 0x5c, 0x5e, 0xd8, 0xff, 0xb0, 0x10, 0x21);
	public const Guid GUID_DEVICE_ACPI_TIME = .(0x97f99bf6, 0x4497, 0x4f18, 0xbb, 0x22, 0x4b, 0x9f, 0xb2, 0xfb, 0xef, 0x9c);
	public const Guid GUID_DEVICE_MESSAGE_INDICATOR = .(0xcd48a365, 0xfa94, 0x4ce2, 0xa2, 0x32, 0xa1, 0xb7, 0x64, 0xe5, 0xd8, 0xb4);
	public const Guid GUID_CLASS_INPUT = .(0x4d1e55b2, 0xf16f, 0x11cf, 0x88, 0xcb, 0x00, 0x11, 0x11, 0x00, 0x00, 0x30);
	public const Guid GUID_DEVINTERFACE_THERMAL_COOLING = .(0xdbe4373d, 0x3c81, 0x40cb, 0xac, 0xe4, 0xe0, 0xe5, 0xd0, 0x5f, 0x0c, 0x9f);
	public const Guid GUID_DEVINTERFACE_THERMAL_MANAGER = .(0x927ec093, 0x69a4, 0x4bc0, 0xbd, 0x02, 0x71, 0x16, 0x64, 0x71, 0x44, 0x63);
	public const uint32 BATTERY_UNKNOWN_CAPACITY = 4294967295;
	public const uint32 UNKNOWN_CAPACITY = 4294967295;
	public const uint32 BATTERY_SYSTEM_BATTERY = 2147483648;
	public const uint32 BATTERY_CAPACITY_RELATIVE = 1073741824;
	public const uint32 BATTERY_IS_SHORT_TERM = 536870912;
	public const uint32 BATTERY_SEALED = 268435456;
	public const uint32 BATTERY_SET_CHARGE_SUPPORTED = 1;
	public const uint32 BATTERY_SET_DISCHARGE_SUPPORTED = 2;
	public const uint32 BATTERY_SET_CHARGINGSOURCE_SUPPORTED = 4;
	public const uint32 BATTERY_SET_CHARGER_ID_SUPPORTED = 8;
	public const uint32 BATTERY_UNKNOWN_TIME = 4294967295;
	public const uint32 BATTERY_UNKNOWN_CURRENT = 4294967295;
	public const uint32 UNKNOWN_CURRENT = 4294967295;
	public const uint32 BATTERY_USB_CHARGER_STATUS_FN_DEFAULT_USB = 1;
	public const uint32 BATTERY_USB_CHARGER_STATUS_UCM_PD = 2;
	public const uint32 BATTERY_UNKNOWN_VOLTAGE = 4294967295;
	public const uint32 BATTERY_UNKNOWN_RATE = 2147483648;
	public const uint32 UNKNOWN_RATE = 2147483648;
	public const uint32 UNKNOWN_VOLTAGE = 4294967295;
	public const uint32 BATTERY_POWER_ON_LINE = 1;
	public const uint32 BATTERY_DISCHARGING = 2;
	public const uint32 BATTERY_CHARGING = 4;
	public const uint32 BATTERY_CRITICAL = 8;
	public const uint32 MAX_BATTERY_STRING_SIZE = 128;
	public const uint32 IOCTL_BATTERY_QUERY_TAG = 2703424;
	public const uint32 IOCTL_BATTERY_QUERY_INFORMATION = 2703428;
	public const uint32 IOCTL_BATTERY_SET_INFORMATION = 2719816;
	public const uint32 IOCTL_BATTERY_QUERY_STATUS = 2703436;
	public const uint32 IOCTL_BATTERY_CHARGING_SOURCE_CHANGE = 2703440;
	public const uint32 BATTERY_TAG_INVALID = 0;
	public const uint32 MAX_ACTIVE_COOLING_LEVELS = 10;
	public const uint32 ACTIVE_COOLING = 0;
	public const uint32 PASSIVE_COOLING = 1;
	public const uint32 TZ_ACTIVATION_REASON_THERMAL = 1;
	public const uint32 TZ_ACTIVATION_REASON_CURRENT = 2;
	public const uint32 THERMAL_POLICY_VERSION_1 = 1;
	public const uint32 THERMAL_POLICY_VERSION_2 = 2;
	public const uint32 IOCTL_THERMAL_QUERY_INFORMATION = 2703488;
	public const uint32 IOCTL_THERMAL_SET_COOLING_POLICY = 2719876;
	public const uint32 IOCTL_RUN_ACTIVE_COOLING_METHOD = 2719880;
	public const uint32 IOCTL_THERMAL_SET_PASSIVE_LIMIT = 2719884;
	public const uint32 IOCTL_THERMAL_READ_TEMPERATURE = 2703504;
	public const uint32 IOCTL_THERMAL_READ_POLICY = 2703508;
	public const uint32 IOCTL_QUERY_LID = 2703552;
	public const uint32 IOCTL_NOTIFY_SWITCH_EVENT = 2703616;
	public const uint32 IOCTL_GET_SYS_BUTTON_CAPS = 2703680;
	public const uint32 IOCTL_GET_SYS_BUTTON_EVENT = 2703684;
	public const uint32 SYS_BUTTON_POWER = 1;
	public const uint32 SYS_BUTTON_SLEEP = 2;
	public const uint32 SYS_BUTTON_LID = 4;
	public const uint32 SYS_BUTTON_WAKE = 2147483648;
	public const uint32 SYS_BUTTON_LID_STATE_MASK = 196608;
	public const uint32 SYS_BUTTON_LID_OPEN = 65536;
	public const uint32 SYS_BUTTON_LID_CLOSED = 131072;
	public const uint32 SYS_BUTTON_LID_INITIAL = 262144;
	public const uint32 SYS_BUTTON_LID_CHANGED = 524288;
	public const uint32 IOCTL_GET_PROCESSOR_OBJ_INFO = 2703744;
	public const uint32 THERMAL_COOLING_INTERFACE_VERSION = 1;
	public const uint32 THERMAL_DEVICE_INTERFACE_VERSION = 1;
	public const uint32 IOCTL_SET_SYS_MESSAGE_INDICATOR = 2720192;
	public const uint32 IOCTL_SET_WAKE_ALARM_VALUE = 2720256;
	public const uint32 IOCTL_SET_WAKE_ALARM_POLICY = 2720260;
	public const uint32 IOCTL_GET_WAKE_ALARM_VALUE = 2736648;
	public const uint32 IOCTL_GET_WAKE_ALARM_POLICY = 2736652;
	public const uint32 ACPI_TIME_ADJUST_DAYLIGHT = 1;
	public const uint32 ACPI_TIME_IN_DAYLIGHT = 2;
	public const uint32 ACPI_TIME_ZONE_UNKNOWN = 2047;
	public const uint32 IOCTL_ACPI_GET_REAL_TIME = 2703888;
	public const uint32 IOCTL_ACPI_SET_REAL_TIME = 2720276;
	public const uint32 IOCTL_GET_WAKE_ALARM_SYSTEM_POWERSTATE = 2703896;
	public const Guid BATTERY_STATUS_WMI_GUID = .(0xfc4670d1, 0xebbf, 0x416e, 0x87, 0xce, 0x37, 0x4a, 0x4e, 0xbc, 0x11, 0x1a);
	public const Guid BATTERY_RUNTIME_WMI_GUID = .(0x535a3767, 0x1ac2, 0x49bc, 0xa0, 0x77, 0x3f, 0x7a, 0x02, 0xe4, 0x0a, 0xec);
	public const Guid BATTERY_TEMPERATURE_WMI_GUID = .(0x1a52a14d, 0xadce, 0x4a44, 0x9a, 0x3e, 0xc8, 0xd8, 0xf1, 0x5f, 0xf2, 0xc2);
	public const Guid BATTERY_FULL_CHARGED_CAPACITY_WMI_GUID = .(0x40b40565, 0x96f7, 0x4435, 0x86, 0x94, 0x97, 0xe0, 0xe4, 0x39, 0x59, 0x05);
	public const Guid BATTERY_CYCLE_COUNT_WMI_GUID = .(0xef98db24, 0x0014, 0x4c25, 0xa5, 0x0b, 0xc7, 0x24, 0xae, 0x5c, 0xd3, 0x71);
	public const Guid BATTERY_STATIC_DATA_WMI_GUID = .(0x05e1e463, 0xe4e2, 0x4ea9, 0x80, 0xcb, 0x9b, 0xd4, 0xb3, 0xca, 0x06, 0x55);
	public const Guid BATTERY_STATUS_CHANGE_WMI_GUID = .(0xcddfa0c3, 0x7c5b, 0x4e43, 0xa0, 0x34, 0x05, 0x9f, 0xa5, 0xb8, 0x43, 0x64);
	public const Guid BATTERY_TAG_CHANGE_WMI_GUID = .(0x5e1f6e19, 0x8786, 0x4d23, 0x94, 0xfc, 0x9e, 0x74, 0x6b, 0xd5, 0xd8, 0x88);
	public const uint32 BATTERY_MINIPORT_UPDATE_DATA_VER_1 = 1;
	public const uint32 BATTERY_MINIPORT_UPDATE_DATA_VER_2 = 2;
	public const uint32 BATTERY_CLASS_MAJOR_VERSION = 1;
	public const uint32 BATTERY_CLASS_MINOR_VERSION = 0;
	public const uint32 BATTERY_CLASS_MINOR_VERSION_1 = 1;
	public const Guid GUID_DEVICE_ENERGY_METER = .(0x45bd8344, 0x7ed6, 0x49cf, 0xa4, 0x40, 0xc2, 0x76, 0xc9, 0x33, 0xb0, 0x53);
	public const uint32 IOCTL_EMI_GET_VERSION = 2244608;
	public const uint32 IOCTL_EMI_GET_METADATA_SIZE = 2244612;
	public const uint32 IOCTL_EMI_GET_METADATA = 2244616;
	public const uint32 IOCTL_EMI_GET_MEASUREMENT = 2244620;
	public const uint32 EMI_NAME_MAX = 16;
	public const uint32 EMI_VERSION_V1 = 1;
	public const uint32 EMI_VERSION_V2 = 2;
	public const uint32 EFFECTIVE_POWER_MODE_V1 = 1;
	public const uint32 EFFECTIVE_POWER_MODE_V2 = 2;
	public const uint32 EnableSysTrayBatteryMeter = 1;
	public const uint32 EnableMultiBatteryDisplay = 2;
	public const uint32 EnablePasswordLogon = 4;
	public const uint32 EnableWakeOnRing = 8;
	public const uint32 EnableVideoDimDisplay = 16;
	public const uint32 POWER_ATTRIBUTE_HIDE = 1;
	public const uint32 POWER_ATTRIBUTE_SHOW_AOAC = 2;
	public const uint32 DEVICEPOWER_HARDWAREID = 2147483648;
	public const uint32 DEVICEPOWER_AND_OPERATION = 1073741824;
	public const uint32 DEVICEPOWER_FILTER_DEVICES_PRESENT = 536870912;
	public const uint32 DEVICEPOWER_FILTER_HARDWARE = 268435456;
	public const uint32 DEVICEPOWER_FILTER_WAKEENABLED = 134217728;
	public const uint32 DEVICEPOWER_FILTER_WAKEPROGRAMMABLE = 67108864;
	public const uint32 DEVICEPOWER_FILTER_ON_NAME = 33554432;
	public const uint32 DEVICEPOWER_SET_WAKEENABLED = 1;
	public const uint32 DEVICEPOWER_CLEAR_WAKEENABLED = 2;
	public const uint32 PDCAP_S0_SUPPORTED = 65536;
	public const uint32 PDCAP_S1_SUPPORTED = 131072;
	public const uint32 PDCAP_S2_SUPPORTED = 262144;
	public const uint32 PDCAP_S3_SUPPORTED = 524288;
	public const uint32 PDCAP_WAKE_FROM_S0_SUPPORTED = 1048576;
	public const uint32 PDCAP_WAKE_FROM_S1_SUPPORTED = 2097152;
	public const uint32 PDCAP_WAKE_FROM_S2_SUPPORTED = 4194304;
	public const uint32 PDCAP_WAKE_FROM_S3_SUPPORTED = 8388608;
	public const uint32 PDCAP_S4_SUPPORTED = 16777216;
	public const uint32 PDCAP_S5_SUPPORTED = 33554432;
	public const uint32 THERMAL_EVENT_VERSION = 1;
}
#endregion

#region TypeDefs
typealias HPOWERNOTIFY = int;

#endregion


#region Enums

[AllowDuplicates]
public enum POWER_COOLING_MODE : uint16
{
	PO_TZ_ACTIVE = 0,
	PO_TZ_PASSIVE = 1,
	PO_TZ_INVALID_MODE = 2,
}


[AllowDuplicates]
public enum POWER_PLATFORM_ROLE_VERSION : uint32
{
	POWER_PLATFORM_ROLE_V1 = 1,
	POWER_PLATFORM_ROLE_V2 = 2,
}


[AllowDuplicates]
public enum POWER_SETTING_REGISTER_NOTIFICATION_FLAGS : uint32
{
	DEVICE_NOTIFY_SERVICE_HANDLE = 1,
	DEVICE_NOTIFY_CALLBACK = 2,
	DEVICE_NOTIFY_WINDOW_HANDLE = 0,
}


[AllowDuplicates]
public enum EXECUTION_STATE : uint32
{
	ES_AWAYMODE_REQUIRED = 64,
	ES_CONTINUOUS = 2147483648,
	ES_DISPLAY_REQUIRED = 2,
	ES_SYSTEM_REQUIRED = 1,
	ES_USER_PRESENT = 4,
}


[AllowDuplicates]
public enum POWER_ACTION_POLICY_EVENT_CODE : uint32
{
	POWER_FORCE_TRIGGER_RESET = 2147483648,
	POWER_LEVEL_USER_NOTIFY_EXEC = 4,
	POWER_LEVEL_USER_NOTIFY_SOUND = 2,
	POWER_LEVEL_USER_NOTIFY_TEXT = 1,
	POWER_USER_NOTIFY_BUTTON = 8,
	POWER_USER_NOTIFY_SHUTDOWN = 16,
}


[AllowDuplicates]
public enum EFFECTIVE_POWER_MODE : int32
{
	EffectivePowerModeBatterySaver = 0,
	EffectivePowerModeBetterBattery = 1,
	EffectivePowerModeBalanced = 2,
	EffectivePowerModeHighPerformance = 3,
	EffectivePowerModeMaxPerformance = 4,
	EffectivePowerModeGameMode = 5,
	EffectivePowerModeMixedReality = 6,
}


[AllowDuplicates]
public enum POWER_DATA_ACCESSOR : int32
{
	ACCESS_AC_POWER_SETTING_INDEX = 0,
	ACCESS_DC_POWER_SETTING_INDEX = 1,
	ACCESS_FRIENDLY_NAME = 2,
	ACCESS_DESCRIPTION = 3,
	ACCESS_POSSIBLE_POWER_SETTING = 4,
	ACCESS_POSSIBLE_POWER_SETTING_FRIENDLY_NAME = 5,
	ACCESS_POSSIBLE_POWER_SETTING_DESCRIPTION = 6,
	ACCESS_DEFAULT_AC_POWER_SETTING = 7,
	ACCESS_DEFAULT_DC_POWER_SETTING = 8,
	ACCESS_POSSIBLE_VALUE_MIN = 9,
	ACCESS_POSSIBLE_VALUE_MAX = 10,
	ACCESS_POSSIBLE_VALUE_INCREMENT = 11,
	ACCESS_POSSIBLE_VALUE_UNITS = 12,
	ACCESS_ICON_RESOURCE = 13,
	ACCESS_DEFAULT_SECURITY_DESCRIPTOR = 14,
	ACCESS_ATTRIBUTES = 15,
	ACCESS_SCHEME = 16,
	ACCESS_SUBGROUP = 17,
	ACCESS_INDIVIDUAL_SETTING = 18,
	ACCESS_ACTIVE_SCHEME = 19,
	ACCESS_CREATE_SCHEME = 20,
	ACCESS_AC_POWER_SETTING_MAX = 21,
	ACCESS_DC_POWER_SETTING_MAX = 22,
	ACCESS_AC_POWER_SETTING_MIN = 23,
	ACCESS_DC_POWER_SETTING_MIN = 24,
	ACCESS_PROFILE = 25,
	ACCESS_OVERLAY_SCHEME = 26,
	ACCESS_ACTIVE_OVERLAY_SCHEME = 27,
}


[AllowDuplicates]
public enum BATTERY_QUERY_INFORMATION_LEVEL : int32
{
	BatteryInformation = 0,
	BatteryGranularityInformation = 1,
	BatteryTemperature = 2,
	BatteryEstimatedTime = 3,
	BatteryDeviceName = 4,
	BatteryManufactureDate = 5,
	BatteryManufactureName = 6,
	BatteryUniqueID = 7,
	BatterySerialNumber = 8,
}


[AllowDuplicates]
public enum BATTERY_CHARGING_SOURCE_TYPE : int32
{
	BatteryChargingSourceType_AC = 1,
	BatteryChargingSourceType_USB = 2,
	BatteryChargingSourceType_Wireless = 3,
	BatteryChargingSourceType_Max = 4,
}


[AllowDuplicates]
public enum USB_CHARGER_PORT : int32
{
	UsbChargerPort_Legacy = 0,
	UsbChargerPort_TypeC = 1,
	UsbChargerPort_Max = 2,
}


[AllowDuplicates]
public enum BATTERY_SET_INFORMATION_LEVEL : int32
{
	BatteryCriticalBias = 0,
	BatteryCharge = 1,
	BatteryDischarge = 2,
	BatteryChargingSource = 3,
	BatteryChargerId = 4,
	BatteryChargerStatus = 5,
}


[AllowDuplicates]
public enum EMI_MEASUREMENT_UNIT : int32
{
	EmiMeasurementUnitPicowattHours = 0,
}


[AllowDuplicates]
public enum SYSTEM_POWER_STATE : int32
{
	PowerSystemUnspecified = 0,
	PowerSystemWorking = 1,
	PowerSystemSleeping1 = 2,
	PowerSystemSleeping2 = 3,
	PowerSystemSleeping3 = 4,
	PowerSystemHibernate = 5,
	PowerSystemShutdown = 6,
	PowerSystemMaximum = 7,
}


[AllowDuplicates]
public enum POWER_ACTION : int32
{
	PowerActionNone = 0,
	PowerActionReserved = 1,
	PowerActionSleep = 2,
	PowerActionHibernate = 3,
	PowerActionShutdown = 4,
	PowerActionShutdownReset = 5,
	PowerActionShutdownOff = 6,
	PowerActionWarmEject = 7,
	PowerActionDisplayOff = 8,
}


[AllowDuplicates]
public enum DEVICE_POWER_STATE : int32
{
	PowerDeviceUnspecified = 0,
	PowerDeviceD0 = 1,
	PowerDeviceD1 = 2,
	PowerDeviceD2 = 3,
	PowerDeviceD3 = 4,
	PowerDeviceMaximum = 5,
}


[AllowDuplicates]
public enum LATENCY_TIME : int32
{
	LT_DONT_CARE = 0,
	LT_LOWEST_LATENCY = 1,
}


[AllowDuplicates]
public enum POWER_REQUEST_TYPE : int32
{
	PowerRequestDisplayRequired = 0,
	PowerRequestSystemRequired = 1,
	PowerRequestAwayModeRequired = 2,
	PowerRequestExecutionRequired = 3,
}


[AllowDuplicates]
public enum POWER_INFORMATION_LEVEL : int32
{
	SystemPowerPolicyAc = 0,
	SystemPowerPolicyDc = 1,
	VerifySystemPolicyAc = 2,
	VerifySystemPolicyDc = 3,
	SystemPowerCapabilities = 4,
	SystemBatteryState = 5,
	SystemPowerStateHandler = 6,
	ProcessorStateHandler = 7,
	SystemPowerPolicyCurrent = 8,
	AdministratorPowerPolicy = 9,
	SystemReserveHiberFile = 10,
	ProcessorInformation = 11,
	SystemPowerInformation = 12,
	ProcessorStateHandler2 = 13,
	LastWakeTime = 14,
	LastSleepTime = 15,
	SystemExecutionState = 16,
	SystemPowerStateNotifyHandler = 17,
	ProcessorPowerPolicyAc = 18,
	ProcessorPowerPolicyDc = 19,
	VerifyProcessorPowerPolicyAc = 20,
	VerifyProcessorPowerPolicyDc = 21,
	ProcessorPowerPolicyCurrent = 22,
	SystemPowerStateLogging = 23,
	SystemPowerLoggingEntry = 24,
	SetPowerSettingValue = 25,
	NotifyUserPowerSetting = 26,
	PowerInformationLevelUnused0 = 27,
	SystemMonitorHiberBootPowerOff = 28,
	SystemVideoState = 29,
	TraceApplicationPowerMessage = 30,
	TraceApplicationPowerMessageEnd = 31,
	ProcessorPerfStates = 32,
	ProcessorIdleStates = 33,
	ProcessorCap = 34,
	SystemWakeSource = 35,
	SystemHiberFileInformation = 36,
	TraceServicePowerMessage = 37,
	ProcessorLoad = 38,
	PowerShutdownNotification = 39,
	MonitorCapabilities = 40,
	SessionPowerInit = 41,
	SessionDisplayState = 42,
	PowerRequestCreate = 43,
	PowerRequestAction = 44,
	GetPowerRequestList = 45,
	ProcessorInformationEx = 46,
	NotifyUserModeLegacyPowerEvent = 47,
	GroupPark = 48,
	ProcessorIdleDomains = 49,
	WakeTimerList = 50,
	SystemHiberFileSize = 51,
	ProcessorIdleStatesHv = 52,
	ProcessorPerfStatesHv = 53,
	ProcessorPerfCapHv = 54,
	ProcessorSetIdle = 55,
	LogicalProcessorIdling = 56,
	UserPresence = 57,
	PowerSettingNotificationName = 58,
	GetPowerSettingValue = 59,
	IdleResiliency = 60,
	SessionRITState = 61,
	SessionConnectNotification = 62,
	SessionPowerCleanup = 63,
	SessionLockState = 64,
	SystemHiberbootState = 65,
	PlatformInformation = 66,
	PdcInvocation = 67,
	MonitorInvocation = 68,
	FirmwareTableInformationRegistered = 69,
	SetShutdownSelectedTime = 70,
	SuspendResumeInvocation = 71,
	PlmPowerRequestCreate = 72,
	ScreenOff = 73,
	CsDeviceNotification = 74,
	PlatformRole = 75,
	LastResumePerformance = 76,
	DisplayBurst = 77,
	ExitLatencySamplingPercentage = 78,
	RegisterSpmPowerSettings = 79,
	PlatformIdleStates = 80,
	ProcessorIdleVeto = 81,
	PlatformIdleVeto = 82,
	SystemBatteryStatePrecise = 83,
	ThermalEvent = 84,
	PowerRequestActionInternal = 85,
	BatteryDeviceState = 86,
	PowerInformationInternal = 87,
	ThermalStandby = 88,
	SystemHiberFileType = 89,
	PhysicalPowerButtonPress = 90,
	QueryPotentialDripsConstraint = 91,
	EnergyTrackerCreate = 92,
	EnergyTrackerQuery = 93,
	UpdateBlackBoxRecorder = 94,
	SessionAllowExternalDmaDevices = 95,
	SendSuspendResumeNotification = 96,
	PowerInformationLevelMaximum = 97,
}


[AllowDuplicates]
public enum SYSTEM_POWER_CONDITION : int32
{
	PoAc = 0,
	PoDc = 1,
	PoHot = 2,
	PoConditionMaximum = 3,
}


[AllowDuplicates]
public enum POWER_PLATFORM_ROLE : int32
{
	PlatformRoleUnspecified = 0,
	PlatformRoleDesktop = 1,
	PlatformRoleMobile = 2,
	PlatformRoleWorkstation = 3,
	PlatformRoleEnterpriseServer = 4,
	PlatformRoleSOHOServer = 5,
	PlatformRoleAppliancePC = 6,
	PlatformRolePerformanceServer = 7,
	PlatformRoleSlate = 8,
	PlatformRoleMaximum = 9,
}

#endregion

#region Function Pointers
public function void EFFECTIVE_POWER_MODE_CALLBACK(EFFECTIVE_POWER_MODE Mode, void* Context);

public function BOOLEAN PWRSCHEMESENUMPROC_V1(uint32 Index, uint32 NameSize, int8* Name, uint32 DescriptionSize, int8* Description, POWER_POLICY* Policy, LPARAM Context);

public function BOOLEAN PWRSCHEMESENUMPROC(uint32 Index, uint32 NameSize, PWSTR Name, uint32 DescriptionSize, PWSTR Description, POWER_POLICY* Policy, LPARAM Context);

public function uint32 PDEVICE_NOTIFY_CALLBACK_ROUTINE(void* Context, uint32 Type, void* Setting);

#endregion

#region Structs
[CRepr]
public struct PROCESSOR_POWER_INFORMATION
{
	public uint64 Number;
	public uint64 MaxMhz;
	public uint64 CurrentMhz;
	public uint64 MhzLimit;
	public uint64 MaxIdleState;
	public uint64 CurrentIdleState;
}

[CRepr]
public struct SYSTEM_POWER_INFORMATION
{
	public uint64 MaxIdlenessAllowed;
	public uint64 Idleness;
	public uint64 TimeRemaining;
	public POWER_COOLING_MODE CoolingMode;
}

[CRepr]
public struct GLOBAL_MACHINE_POWER_POLICY
{
	public uint32 Revision;
	public SYSTEM_POWER_STATE LidOpenWakeAc;
	public SYSTEM_POWER_STATE LidOpenWakeDc;
	public uint32 BroadcastCapacityResolution;
}

[CRepr]
public struct GLOBAL_USER_POWER_POLICY
{
	public uint32 Revision;
	public POWER_ACTION_POLICY PowerButtonAc;
	public POWER_ACTION_POLICY PowerButtonDc;
	public POWER_ACTION_POLICY SleepButtonAc;
	public POWER_ACTION_POLICY SleepButtonDc;
	public POWER_ACTION_POLICY LidCloseAc;
	public POWER_ACTION_POLICY LidCloseDc;
	public SYSTEM_POWER_LEVEL[4] DischargePolicy;
	public uint32 GlobalFlags;
}

[CRepr]
public struct GLOBAL_POWER_POLICY
{
	public GLOBAL_USER_POWER_POLICY user;
	public GLOBAL_MACHINE_POWER_POLICY mach;
}

[CRepr]
public struct MACHINE_POWER_POLICY
{
	public uint32 Revision;
	public SYSTEM_POWER_STATE MinSleepAc;
	public SYSTEM_POWER_STATE MinSleepDc;
	public SYSTEM_POWER_STATE ReducedLatencySleepAc;
	public SYSTEM_POWER_STATE ReducedLatencySleepDc;
	public uint32 DozeTimeoutAc;
	public uint32 DozeTimeoutDc;
	public uint32 DozeS4TimeoutAc;
	public uint32 DozeS4TimeoutDc;
	public uint8 MinThrottleAc;
	public uint8 MinThrottleDc;
	public uint8[2] pad1;
	public POWER_ACTION_POLICY OverThrottledAc;
	public POWER_ACTION_POLICY OverThrottledDc;
}

[CRepr]
public struct MACHINE_PROCESSOR_POWER_POLICY
{
	public uint32 Revision;
	public PROCESSOR_POWER_POLICY ProcessorPolicyAc;
	public PROCESSOR_POWER_POLICY ProcessorPolicyDc;
}

[CRepr]
public struct USER_POWER_POLICY
{
	public uint32 Revision;
	public POWER_ACTION_POLICY IdleAc;
	public POWER_ACTION_POLICY IdleDc;
	public uint32 IdleTimeoutAc;
	public uint32 IdleTimeoutDc;
	public uint8 IdleSensitivityAc;
	public uint8 IdleSensitivityDc;
	public uint8 ThrottlePolicyAc;
	public uint8 ThrottlePolicyDc;
	public SYSTEM_POWER_STATE MaxSleepAc;
	public SYSTEM_POWER_STATE MaxSleepDc;
	public uint32[2] Reserved;
	public uint32 VideoTimeoutAc;
	public uint32 VideoTimeoutDc;
	public uint32 SpindownTimeoutAc;
	public uint32 SpindownTimeoutDc;
	public BOOLEAN OptimizeForPowerAc;
	public BOOLEAN OptimizeForPowerDc;
	public uint8 FanThrottleToleranceAc;
	public uint8 FanThrottleToleranceDc;
	public uint8 ForcedThrottleAc;
	public uint8 ForcedThrottleDc;
}

[CRepr]
public struct POWER_POLICY
{
	public USER_POWER_POLICY user;
	public MACHINE_POWER_POLICY mach;
}

[CRepr]
public struct DEVICE_NOTIFY_SUBSCRIBE_PARAMETERS
{
	public PDEVICE_NOTIFY_CALLBACK_ROUTINE Callback;
	public void* Context;
}

[CRepr]
public struct THERMAL_EVENT
{
	public uint32 Version;
	public uint32 Size;
	public uint32 Type;
	public uint32 Temperature;
	public uint32 TripPointTemperature;
	public PWSTR Initiator;
}

[CRepr]
public struct BATTERY_QUERY_INFORMATION
{
	public uint32 BatteryTag;
	public BATTERY_QUERY_INFORMATION_LEVEL InformationLevel;
	public uint32 AtRate;
}

[CRepr]
public struct BATTERY_INFORMATION
{
	public uint32 Capabilities;
	public uint8 Technology;
	public uint8[3] Reserved;
	public uint8[4] Chemistry;
	public uint32 DesignedCapacity;
	public uint32 FullChargedCapacity;
	public uint32 DefaultAlert1;
	public uint32 DefaultAlert2;
	public uint32 CriticalBias;
	public uint32 CycleCount;
}

[CRepr]
public struct BATTERY_CHARGING_SOURCE
{
	public BATTERY_CHARGING_SOURCE_TYPE Type;
	public uint32 MaxCurrent;
}

[CRepr]
public struct BATTERY_CHARGING_SOURCE_INFORMATION
{
	public BATTERY_CHARGING_SOURCE_TYPE Type;
	public BOOLEAN SourceOnline;
}

[CRepr]
public struct BATTERY_SET_INFORMATION
{
	public uint32 BatteryTag;
	public BATTERY_SET_INFORMATION_LEVEL InformationLevel;
	public uint8* Buffer mut => &Buffer_impl;
	private uint8[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct BATTERY_CHARGER_STATUS
{
	public BATTERY_CHARGING_SOURCE_TYPE Type;
	public uint32* VaData mut => &VaData_impl;
	private uint32[ANYSIZE_ARRAY] VaData_impl;
}

[CRepr]
public struct BATTERY_USB_CHARGER_STATUS
{
	public BATTERY_CHARGING_SOURCE_TYPE Type;
	public uint32 Reserved;
	public uint32 Flags;
	public uint32 MaxCurrent;
	public uint32 Voltage;
	public USB_CHARGER_PORT PortType;
	public uint64 PortId;
	public void* PowerSourceInformation;
	public Guid OemCharger;
}

[CRepr]
public struct BATTERY_WAIT_STATUS
{
	public uint32 BatteryTag;
	public uint32 Timeout;
	public uint32 PowerState;
	public uint32 LowCapacity;
	public uint32 HighCapacity;
}

[CRepr]
public struct BATTERY_STATUS
{
	public uint32 PowerState;
	public uint32 Capacity;
	public uint32 Voltage;
	public int32 Rate;
}

[CRepr]
public struct BATTERY_MANUFACTURE_DATE
{
	public uint8 Day;
	public uint8 Month;
	public uint16 Year;
}

[CRepr]
public struct THERMAL_INFORMATION
{
	public uint32 ThermalStamp;
	public uint32 ThermalConstant1;
	public uint32 ThermalConstant2;
	public uint Processors;
	public uint32 SamplingPeriod;
	public uint32 CurrentTemperature;
	public uint32 PassiveTripPoint;
	public uint32 CriticalTripPoint;
	public uint8 ActiveTripPointCount;
	public uint32[10] ActiveTripPoint;
}

[CRepr]
public struct THERMAL_WAIT_READ
{
	public uint32 Timeout;
	public uint32 LowTemperature;
	public uint32 HighTemperature;
}

[CRepr]
public struct THERMAL_POLICY
{
	public uint32 Version;
	public BOOLEAN WaitForUpdate;
	public BOOLEAN Hibernate;
	public BOOLEAN Critical;
	public BOOLEAN ThermalStandby;
	public uint32 ActivationReasons;
	public uint32 PassiveLimit;
	public uint32 ActiveLevel;
	public BOOLEAN OverThrottled;
}

[CRepr]
public struct PROCESSOR_OBJECT_INFO
{
	public uint32 PhysicalID;
	public uint32 PBlkAddress;
	public uint8 PBlkLength;
}

[CRepr]
public struct PROCESSOR_OBJECT_INFO_EX
{
	public uint32 PhysicalID;
	public uint32 PBlkAddress;
	public uint8 PBlkLength;
	public uint32 InitialApicId;
}

[CRepr]
public struct WAKE_ALARM_INFORMATION
{
	public uint32 TimerIdentifier;
	public uint32 Timeout;
}

[CRepr]
public struct ACPI_REAL_TIME
{
	public uint16 Year;
	public uint8 Month;
	public uint8 Day;
	public uint8 Hour;
	public uint8 Minute;
	public uint8 Second;
	public uint8 Valid;
	public uint16 Milliseconds;
	public int16 TimeZone;
	public uint8 DayLight;
	public uint8[3] Reserved1;
}

[CRepr]
public struct EMI_VERSION
{
	public uint16 EmiVersion;
}

[CRepr]
public struct EMI_METADATA_SIZE
{
	public uint32 MetadataSize;
}

[CRepr]
public struct EMI_CHANNEL_MEASUREMENT_DATA
{
	public uint64 AbsoluteEnergy;
	public uint64 AbsoluteTime;
}

[CRepr]
public struct EMI_METADATA_V1
{
	public EMI_MEASUREMENT_UNIT MeasurementUnit;
	public char16[16] HardwareOEM;
	public char16[16] HardwareModel;
	public uint16 HardwareRevision;
	public uint16 MeteredHardwareNameSize;
	public char16* MeteredHardwareName mut => &MeteredHardwareName_impl;
	private char16[ANYSIZE_ARRAY] MeteredHardwareName_impl;
}

[CRepr]
public struct EMI_CHANNEL_V2
{
	public EMI_MEASUREMENT_UNIT MeasurementUnit;
	public uint16 ChannelNameSize;
	public char16* ChannelName mut => &ChannelName_impl;
	private char16[ANYSIZE_ARRAY] ChannelName_impl;
}

[CRepr]
public struct EMI_METADATA_V2
{
	public char16[16] HardwareOEM;
	public char16[16] HardwareModel;
	public uint16 HardwareRevision;
	public uint16 ChannelCount;
	public EMI_CHANNEL_V2* Channels mut => &Channels_impl;
	private EMI_CHANNEL_V2[ANYSIZE_ARRAY] Channels_impl;
}

[CRepr]
public struct EMI_MEASUREMENT_DATA_V2
{
	public EMI_CHANNEL_MEASUREMENT_DATA* ChannelData mut => &ChannelData_impl;
	private EMI_CHANNEL_MEASUREMENT_DATA[ANYSIZE_ARRAY] ChannelData_impl;
}

[CRepr]
public struct CM_POWER_DATA
{
	public uint32 PD_Size;
	public DEVICE_POWER_STATE PD_MostRecentPowerState;
	public uint32 PD_Capabilities;
	public uint32 PD_D1Latency;
	public uint32 PD_D2Latency;
	public uint32 PD_D3Latency;
	public DEVICE_POWER_STATE[7] PD_PowerStateMapping;
	public SYSTEM_POWER_STATE PD_DeepestSystemWake;
}

[CRepr]
public struct SET_POWER_SETTING_VALUE
{
	public uint32 Version;
	public Guid Guid;
	public SYSTEM_POWER_CONDITION PowerCondition;
	public uint32 DataLength;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct BATTERY_REPORTING_SCALE
{
	public uint32 Granularity;
	public uint32 Capacity;
}

[CRepr]
public struct POWER_ACTION_POLICY
{
	public POWER_ACTION Action;
	public uint32 Flags;
	public POWER_ACTION_POLICY_EVENT_CODE EventCode;
}

[CRepr]
public struct SYSTEM_POWER_LEVEL
{
	public BOOLEAN Enable;
	public uint8[3] Spare;
	public uint32 BatteryLevel;
	public POWER_ACTION_POLICY PowerPolicy;
	public SYSTEM_POWER_STATE MinSystemState;
}

[CRepr]
public struct SYSTEM_POWER_POLICY
{
	public uint32 Revision;
	public POWER_ACTION_POLICY PowerButton;
	public POWER_ACTION_POLICY SleepButton;
	public POWER_ACTION_POLICY LidClose;
	public SYSTEM_POWER_STATE LidOpenWake;
	public uint32 Reserved;
	public POWER_ACTION_POLICY Idle;
	public uint32 IdleTimeout;
	public uint8 IdleSensitivity;
	public uint8 DynamicThrottle;
	public uint8[2] Spare2;
	public SYSTEM_POWER_STATE MinSleep;
	public SYSTEM_POWER_STATE MaxSleep;
	public SYSTEM_POWER_STATE ReducedLatencySleep;
	public uint32 WinLogonFlags;
	public uint32 Spare3;
	public uint32 DozeS4Timeout;
	public uint32 BroadcastCapacityResolution;
	public SYSTEM_POWER_LEVEL[4] DischargePolicy;
	public uint32 VideoTimeout;
	public BOOLEAN VideoDimDisplay;
	public uint32[3] VideoReserved;
	public uint32 SpindownTimeout;
	public BOOLEAN OptimizeForPower;
	public uint8 FanThrottleTolerance;
	public uint8 ForcedThrottle;
	public uint8 MinThrottle;
	public POWER_ACTION_POLICY OverThrottled;
}

[CRepr]
public struct PROCESSOR_POWER_POLICY_INFO
{
	public uint32 TimeCheck;
	public uint32 DemoteLimit;
	public uint32 PromoteLimit;
	public uint8 DemotePercent;
	public uint8 PromotePercent;
	public uint8[2] Spare;
	public uint32 _bitfield;
}

[CRepr]
public struct PROCESSOR_POWER_POLICY
{
	public uint32 Revision;
	public uint8 DynamicThrottle;
	public uint8[3] Spare;
	public uint32 _bitfield;
	public uint32 PolicyCount;
	public PROCESSOR_POWER_POLICY_INFO[3] Policy;
}

[CRepr]
public struct ADMINISTRATOR_POWER_POLICY
{
	public SYSTEM_POWER_STATE MinSleep;
	public SYSTEM_POWER_STATE MaxSleep;
	public uint32 MinVideoTimeout;
	public uint32 MaxVideoTimeout;
	public uint32 MinSpindownTimeout;
	public uint32 MaxSpindownTimeout;
}

[CRepr]
public struct SYSTEM_POWER_CAPABILITIES
{
	public BOOLEAN PowerButtonPresent;
	public BOOLEAN SleepButtonPresent;
	public BOOLEAN LidPresent;
	public BOOLEAN SystemS1;
	public BOOLEAN SystemS2;
	public BOOLEAN SystemS3;
	public BOOLEAN SystemS4;
	public BOOLEAN SystemS5;
	public BOOLEAN HiberFilePresent;
	public BOOLEAN FullWake;
	public BOOLEAN VideoDimPresent;
	public BOOLEAN ApmPresent;
	public BOOLEAN UpsPresent;
	public BOOLEAN ThermalControl;
	public BOOLEAN ProcessorThrottle;
	public uint8 ProcessorMinThrottle;
	public uint8 ProcessorMaxThrottle;
	public BOOLEAN FastSystemS4;
	public BOOLEAN Hiberboot;
	public BOOLEAN WakeAlarmPresent;
	public BOOLEAN AoAc;
	public BOOLEAN DiskSpinDown;
	public uint8 HiberFileType;
	public BOOLEAN AoAcConnectivitySupported;
	public uint8[6] spare3;
	public BOOLEAN SystemBatteriesPresent;
	public BOOLEAN BatteriesAreShortTerm;
	public BATTERY_REPORTING_SCALE[3] BatteryScale;
	public SYSTEM_POWER_STATE AcOnLineWake;
	public SYSTEM_POWER_STATE SoftLidWake;
	public SYSTEM_POWER_STATE RtcWake;
	public SYSTEM_POWER_STATE MinDeviceWakeState;
	public SYSTEM_POWER_STATE DefaultLowLatencyWake;
}

[CRepr]
public struct SYSTEM_BATTERY_STATE
{
	public BOOLEAN AcOnLine;
	public BOOLEAN BatteryPresent;
	public BOOLEAN Charging;
	public BOOLEAN Discharging;
	public BOOLEAN[3] Spare1;
	public uint8 Tag;
	public uint32 MaxCapacity;
	public uint32 RemainingCapacity;
	public uint32 Rate;
	public uint32 EstimatedTime;
	public uint32 DefaultAlert1;
	public uint32 DefaultAlert2;
}

[CRepr]
public struct POWERBROADCAST_SETTING
{
	public Guid PowerSetting;
	public uint32 DataLength;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct SYSTEM_POWER_STATUS
{
	public uint8 ACLineStatus;
	public uint8 BatteryFlag;
	public uint8 BatteryLifePercent;
	public uint8 SystemStatusFlag;
	public uint32 BatteryLifeTime;
	public uint32 BatteryFullLifeTime;
}

#endregion

#region Functions
public static
{
	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS CallNtPowerInformation(POWER_INFORMATION_LEVEL InformationLevel, void* InputBuffer, uint32 InputBufferLength, void* OutputBuffer, uint32 OutputBufferLength);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetPwrCapabilities(SYSTEM_POWER_CAPABILITIES* lpspc);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern POWER_PLATFORM_ROLE PowerDeterminePlatformRoleEx(POWER_PLATFORM_ROLE_VERSION Version);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerRegisterSuspendResumeNotification(uint32 Flags, HANDLE Recipient, void** RegistrationHandle);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerUnregisterSuspendResumeNotification(HPOWERNOTIFY RegistrationHandle);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadACValue(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* Type, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadDCValue(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* Type, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteACValueIndex(HKEY RootPowerKey, in Guid SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 AcValueIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteDCValueIndex(HKEY RootPowerKey, in Guid SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 DcValueIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerGetActiveScheme(HKEY UserRootPowerKey, Guid** ActivePolicyGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerSetActiveScheme(HKEY UserRootPowerKey, Guid* SchemeGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerSettingRegisterNotification(in Guid SettingGuid, POWER_SETTING_REGISTER_NOTIFICATION_FLAGS Flags, HANDLE Recipient, void** RegistrationHandle);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerSettingUnregisterNotification(HPOWERNOTIFY RegistrationHandle);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PowerRegisterForEffectivePowerModeNotifications(uint32 Version, EFFECTIVE_POWER_MODE_CALLBACK Callback, void* Context, void** RegistrationHandle);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PowerUnregisterFromEffectivePowerModeNotifications(void* RegistrationHandle);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetPwrDiskSpindownRange(uint32* puiMax, uint32* puiMin);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN EnumPwrSchemes(PWRSCHEMESENUMPROC lpfn, LPARAM lParam);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN ReadGlobalPwrPolicy(GLOBAL_POWER_POLICY* pGlobalPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN ReadPwrScheme(uint32 uiID, POWER_POLICY* pPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN WritePwrScheme(uint32* puiID, PWSTR lpszSchemeName, PWSTR lpszDescription, POWER_POLICY* lpScheme);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN WriteGlobalPwrPolicy(GLOBAL_POWER_POLICY* pGlobalPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN DeletePwrScheme(uint32 uiID);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetActivePwrScheme(uint32* puiID);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN SetActivePwrScheme(uint32 uiID, GLOBAL_POWER_POLICY* pGlobalPowerPolicy, POWER_POLICY* pPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN IsPwrSuspendAllowed();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN IsPwrHibernateAllowed();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN IsPwrShutdownAllowed();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN IsAdminOverrideActive(ADMINISTRATOR_POWER_POLICY* papp);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN SetSuspendState(BOOLEAN bHibernate, BOOLEAN bForce, BOOLEAN bWakeupEventsDisabled);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetCurrentPowerPolicies(GLOBAL_POWER_POLICY* pGlobalPowerPolicy, POWER_POLICY* pPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN CanUserWritePwrScheme();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN ReadProcessorPwrScheme(uint32 uiID, MACHINE_PROCESSOR_POWER_POLICY* pMachineProcessorPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN WriteProcessorPwrScheme(uint32 uiID, MACHINE_PROCESSOR_POWER_POLICY* pMachineProcessorPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN ValidatePowerPolicies(GLOBAL_POWER_POLICY* pGlobalPowerPolicy, POWER_POLICY* pPowerPolicy);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN PowerIsSettingRangeDefined(Guid* SubKeyGuid, Guid* SettingGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerSettingAccessCheckEx(POWER_DATA_ACCESSOR AccessFlags, Guid* PowerGuid, REG_SAM_FLAGS AccessType);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerSettingAccessCheck(POWER_DATA_ACCESSOR AccessFlags, Guid* PowerGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadACValueIndex(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* AcValueIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadDCValueIndex(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* DcValueIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadFriendlyName(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadDescription(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadPossibleValue(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* Type, uint32 PossibleSettingIndex, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadPossibleFriendlyName(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 PossibleSettingIndex, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadPossibleDescription(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 PossibleSettingIndex, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadValueMin(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* ValueMinimum);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadValueMax(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* ValueMaximum);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadValueIncrement(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32* ValueIncrement);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadValueUnitsSpecifier(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadACDefaultIndex(HKEY RootPowerKey, in Guid SchemePersonalityGuid, Guid* SubGroupOfPowerSettingsGuid, in Guid PowerSettingGuid, uint32* AcDefaultIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadDCDefaultIndex(HKEY RootPowerKey, in Guid SchemePersonalityGuid, Guid* SubGroupOfPowerSettingsGuid, in Guid PowerSettingGuid, uint32* DcDefaultIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadIconResourceSpecifier(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReadSettingAttributes(Guid* SubGroupGuid, Guid* PowerSettingGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteFriendlyName(HKEY RootPowerKey, in Guid SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteDescription(HKEY RootPowerKey, in Guid SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWritePossibleValue(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 Type, uint32 PossibleSettingIndex, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWritePossibleFriendlyName(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 PossibleSettingIndex, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWritePossibleDescription(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 PossibleSettingIndex, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteValueMin(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 ValueMinimum);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteValueMax(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 ValueMaximum);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteValueIncrement(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint32 ValueIncrement);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteValueUnitsSpecifier(HKEY RootPowerKey, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteACDefaultIndex(HKEY RootSystemPowerKey, in Guid SchemePersonalityGuid, Guid* SubGroupOfPowerSettingsGuid, in Guid PowerSettingGuid, uint32 DefaultAcIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteDCDefaultIndex(HKEY RootSystemPowerKey, in Guid SchemePersonalityGuid, Guid* SubGroupOfPowerSettingsGuid, in Guid PowerSettingGuid, uint32 DefaultDcIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteIconResourceSpecifier(HKEY RootPowerKey, in Guid SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, Guid* PowerSettingGuid, uint8* Buffer, uint32 BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerWriteSettingAttributes(Guid* SubGroupGuid, Guid* PowerSettingGuid, uint32 Attributes);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerDuplicateScheme(HKEY RootPowerKey, in Guid SourceSchemeGuid, Guid** DestinationSchemeGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerImportPowerScheme(HKEY RootPowerKey, PWSTR ImportFileNamePath, Guid** DestinationSchemeGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerDeleteScheme(HKEY RootPowerKey, in Guid SchemeGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerRemovePowerSetting(in Guid PowerSettingSubKeyGuid, in Guid PowerSettingGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerCreateSetting(HKEY RootSystemPowerKey, in Guid SubGroupOfPowerSettingsGuid, in Guid PowerSettingGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerCreatePossibleSetting(HKEY RootSystemPowerKey, in Guid SubGroupOfPowerSettingsGuid, in Guid PowerSettingGuid, uint32 PossibleSettingIndex);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerEnumerate(HKEY RootPowerKey, Guid* SchemeGuid, Guid* SubGroupOfPowerSettingsGuid, POWER_DATA_ACCESSOR AccessFlags, uint32 Index, uint8* Buffer, uint32* BufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerOpenUserPowerKey(HKEY* phUserPowerKey, uint32 Access, BOOL OpenExisting);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerOpenSystemPowerKey(HKEY* phSystemPowerKey, uint32 Access, BOOL OpenExisting);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerCanRestoreIndividualDefaultPowerScheme(in Guid SchemeGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerRestoreIndividualDefaultPowerScheme(in Guid SchemeGuid);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerRestoreDefaultPowerSchemes();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReplaceDefaultPowerSchemes();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern POWER_PLATFORM_ROLE PowerDeterminePlatformRole();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN DevicePowerEnumDevices(uint32 QueryIndex, uint32 QueryInterpretationFlags, uint32 QueryFlags, uint8* pReturnBuffer, uint32* pBufferSize);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DevicePowerSetDeviceState(PWSTR DeviceDescription, uint32 SetFlags, void* SetData);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN DevicePowerOpen(uint32 DebugMask);

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN DevicePowerClose();

	[Import("POWRPROF.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PowerReportThermalEvent(THERMAL_EVENT* Event);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPOWERNOTIFY RegisterPowerSettingNotification(HANDLE hRecipient, in Guid PowerSettingGuid, uint32 Flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterPowerSettingNotification(HPOWERNOTIFY Handle);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPOWERNOTIFY RegisterSuspendResumeNotification(HANDLE hRecipient, uint32 Flags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterSuspendResumeNotification(HPOWERNOTIFY Handle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RequestWakeupLatency(LATENCY_TIME latency);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsSystemResumeAutomatic();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern EXECUTION_STATE SetThreadExecutionState(EXECUTION_STATE esFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE PowerCreateRequest(REASON_CONTEXT* Context);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PowerSetRequest(HANDLE PowerRequest, POWER_REQUEST_TYPE RequestType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PowerClearRequest(HANDLE PowerRequest, POWER_REQUEST_TYPE RequestType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDevicePowerState(HANDLE hDevice, BOOL* pfOn);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSystemPowerState(BOOL fSuspend, BOOL fForce);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemPowerStatus(SYSTEM_POWER_STATUS* lpSystemPowerStatus);

}
#endregion
