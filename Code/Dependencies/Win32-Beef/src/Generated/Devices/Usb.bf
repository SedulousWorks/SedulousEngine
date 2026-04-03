using Win32.Foundation;
using Win32.System.IO;
using System;

namespace Win32.Devices.Usb;

#region Constants
public static
{
	public const uint32 SHORT_PACKET_TERMINATE = 1;
	public const uint32 AUTO_CLEAR_STALL = 2;
	public const uint32 PIPE_TRANSFER_TIMEOUT = 3;
	public const uint32 IGNORE_SHORT_PACKETS = 4;
	public const uint32 ALLOW_PARTIAL_READS = 5;
	public const uint32 AUTO_FLUSH = 6;
	public const uint32 RAW_IO = 7;
	public const uint32 MAXIMUM_TRANSFER_SIZE = 8;
	public const uint32 RESET_PIPE_ON_RESUME = 9;
	public const uint32 AUTO_SUSPEND = 129;
	public const uint32 SUSPEND_DELAY = 131;
	public const uint32 DEVICE_SPEED = 1;
	public const uint32 LowSpeed = 1;
	public const uint32 FullSpeed = 2;
	public const uint32 HighSpeed = 3;
	public const uint32 IOCTL_GENERICUSBFN_TRANSFER_IN = 2277389;
	public const uint32 IOCTL_GENERICUSBFN_TRANSFER_IN_APPEND_ZERO_PKT = 2277393;
	public const uint32 IOCTL_GENERICUSBFN_TRANSFER_OUT = 2277398;
	public const uint32 IOCTL_GENERICUSBFN_CONTROL_STATUS_HANDSHAKE_IN = 2277400;
	public const uint32 IOCTL_GENERICUSBFN_CONTROL_STATUS_HANDSHAKE_OUT = 2277404;
	public const uint32 IOCTL_GENERICUSBFN_GET_CLASS_INFO = 2277410;
	public const uint32 IOCTL_GENERICUSBFN_GET_PIPE_STATE = 2277414;
	public const uint32 IOCTL_GENERICUSBFN_SET_PIPE_STATE = 2277417;
	public const uint32 IOCTL_GENERICUSBFN_ACTIVATE_USB_BUS = 2277420;
	public const uint32 IOCTL_GENERICUSBFN_DEACTIVATE_USB_BUS = 2277424;
	public const uint32 IOCTL_GENERICUSBFN_BUS_EVENT_NOTIFICATION = 2277430;
	public const uint32 IOCTL_GENERICUSBFN_GET_CLASS_INFO_EX = 2277434;
	public const uint32 IOCTL_GENERICUSBFN_GET_INTERFACE_DESCRIPTOR_SET = 2277438;
	public const uint32 IOCTL_GENERICUSBFN_REGISTER_USB_STRING = 2277441;
	public const uint32 USBUSER_VERSION = 4;
	public const uint32 USBUSER_GET_CONTROLLER_INFO_0 = 1;
	public const uint32 USBUSER_GET_CONTROLLER_DRIVER_KEY = 2;
	public const uint32 USBUSER_PASS_THRU = 3;
	public const uint32 USBUSER_GET_POWER_STATE_MAP = 4;
	public const uint32 USBUSER_GET_BANDWIDTH_INFORMATION = 5;
	public const uint32 USBUSER_GET_BUS_STATISTICS_0 = 6;
	public const uint32 USBUSER_GET_ROOTHUB_SYMBOLIC_NAME = 7;
	public const uint32 USBUSER_GET_USB_DRIVER_VERSION = 8;
	public const uint32 USBUSER_GET_USB2_HW_VERSION = 9;
	public const uint32 USBUSER_USB_REFRESH_HCT_REG = 10;
	public const uint32 USBUSER_OP_SEND_ONE_PACKET = 268435457;
	public const uint32 USBUSER_OP_RAW_RESET_PORT = 536870913;
	public const uint32 USBUSER_OP_OPEN_RAW_DEVICE = 536870914;
	public const uint32 USBUSER_OP_CLOSE_RAW_DEVICE = 536870915;
	public const uint32 USBUSER_OP_SEND_RAW_COMMAND = 536870916;
	public const uint32 USBUSER_SET_ROOTPORT_FEATURE = 536870917;
	public const uint32 USBUSER_CLEAR_ROOTPORT_FEATURE = 536870918;
	public const uint32 USBUSER_GET_ROOTPORT_STATUS = 536870919;
	public const uint32 USBUSER_INVALID_REQUEST = 4294967280;
	public const uint32 USBUSER_OP_MASK_DEVONLY_API = 268435456;
	public const uint32 USBUSER_OP_MASK_HCTEST_API = 536870912;
	public const uint32 USB_PACKETFLAG_LOW_SPEED = 1;
	public const uint32 USB_PACKETFLAG_FULL_SPEED = 2;
	public const uint32 USB_PACKETFLAG_HIGH_SPEED = 4;
	public const uint32 USB_PACKETFLAG_ASYNC_IN = 8;
	public const uint32 USB_PACKETFLAG_ASYNC_OUT = 16;
	public const uint32 USB_PACKETFLAG_ISO_IN = 32;
	public const uint32 USB_PACKETFLAG_ISO_OUT = 64;
	public const uint32 USB_PACKETFLAG_SETUP = 128;
	public const uint32 USB_PACKETFLAG_TOGGLE0 = 256;
	public const uint32 USB_PACKETFLAG_TOGGLE1 = 512;
	public const uint32 USB_HC_FEATURE_FLAG_PORT_POWER_SWITCHING = 1;
	public const uint32 USB_HC_FEATURE_FLAG_SEL_SUSPEND = 2;
	public const uint32 USB_HC_FEATURE_LEGACY_BIOS = 4;
	public const uint32 USB_HC_FEATURE_TIME_SYNC_API = 8;
	public const uint32 USB_SUBMIT_URB = 0;
	public const uint32 USB_RESET_PORT = 1;
	public const uint32 USB_GET_ROOTHUB_PDO = 3;
	public const uint32 USB_GET_PORT_STATUS = 4;
	public const uint32 USB_ENABLE_PORT = 5;
	public const uint32 USB_GET_HUB_COUNT = 6;
	public const uint32 USB_CYCLE_PORT = 7;
	public const uint32 USB_GET_HUB_NAME = 8;
	public const uint32 USB_IDLE_NOTIFICATION = 9;
	public const uint32 USB_RECORD_FAILURE = 10;
	public const uint32 USB_GET_BUS_INFO = 264;
	public const uint32 USB_GET_CONTROLLER_NAME = 265;
	public const uint32 USB_GET_BUSGUID_INFO = 266;
	public const uint32 USB_GET_PARENT_HUB_INFO = 267;
	public const uint32 USB_GET_DEVICE_HANDLE = 268;
	public const uint32 USB_GET_DEVICE_HANDLE_EX = 269;
	public const uint32 USB_GET_TT_DEVICE_HANDLE = 270;
	public const uint32 USB_GET_TOPOLOGY_ADDRESS = 271;
	public const uint32 USB_IDLE_NOTIFICATION_EX = 272;
	public const uint32 USB_REQ_GLOBAL_SUSPEND = 273;
	public const uint32 USB_REQ_GLOBAL_RESUME = 274;
	public const uint32 USB_GET_HUB_CONFIG_INFO = 275;
	public const uint32 USB_FAIL_GET_STATUS = 280;
	public const uint32 USB_REGISTER_COMPOSITE_DEVICE = 0;
	public const uint32 USB_UNREGISTER_COMPOSITE_DEVICE = 1;
	public const uint32 USB_REQUEST_REMOTE_WAKE_NOTIFICATION = 2;
	public const uint32 HCD_GET_STATS_1 = 255;
	public const uint32 HCD_DIAGNOSTIC_MODE_ON = 256;
	public const uint32 HCD_DIAGNOSTIC_MODE_OFF = 257;
	public const uint32 HCD_GET_ROOT_HUB_NAME = 258;
	public const uint32 HCD_GET_DRIVERKEY_NAME = 265;
	public const uint32 HCD_GET_STATS_2 = 266;
	public const uint32 HCD_DISABLE_PORT = 268;
	public const uint32 HCD_ENABLE_PORT = 269;
	public const uint32 HCD_USER_REQUEST = 270;
	public const uint32 HCD_TRACE_READ_REQUEST = 275;
	public const uint32 USB_GET_NODE_INFORMATION = 258;
	public const uint32 USB_GET_NODE_CONNECTION_INFORMATION = 259;
	public const uint32 USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION = 260;
	public const uint32 USB_GET_NODE_CONNECTION_NAME = 261;
	public const uint32 USB_DIAG_IGNORE_HUBS_ON = 262;
	public const uint32 USB_DIAG_IGNORE_HUBS_OFF = 263;
	public const uint32 USB_GET_NODE_CONNECTION_DRIVERKEY_NAME = 264;
	public const uint32 USB_GET_HUB_CAPABILITIES = 271;
	public const uint32 USB_GET_NODE_CONNECTION_ATTRIBUTES = 272;
	public const uint32 USB_HUB_CYCLE_PORT = 273;
	public const uint32 USB_GET_NODE_CONNECTION_INFORMATION_EX = 274;
	public const uint32 USB_RESET_HUB = 275;
	public const uint32 USB_GET_HUB_CAPABILITIES_EX = 276;
	public const uint32 USB_GET_HUB_INFORMATION_EX = 277;
	public const uint32 USB_GET_PORT_CONNECTOR_PROPERTIES = 278;
	public const uint32 USB_GET_NODE_CONNECTION_INFORMATION_EX_V2 = 279;
	public const uint32 USB_GET_TRANSPORT_CHARACTERISTICS = 281;
	public const uint32 USB_REGISTER_FOR_TRANSPORT_CHARACTERISTICS_CHANGE = 282;
	public const uint32 USB_NOTIFY_ON_TRANSPORT_CHARACTERISTICS_CHANGE = 283;
	public const uint32 USB_UNREGISTER_FOR_TRANSPORT_CHARACTERISTICS_CHANGE = 284;
	public const uint32 USB_START_TRACKING_FOR_TIME_SYNC = 285;
	public const uint32 USB_GET_FRAME_NUMBER_AND_QPC_FOR_TIME_SYNC = 286;
	public const uint32 USB_STOP_TRACKING_FOR_TIME_SYNC = 287;
	public const uint32 USB_GET_DEVICE_CHARACTERISTICS = 288;
	public const Guid GUID_DEVINTERFACE_USB_HUB = .(0xf18a0e88, 0xc30c, 0x11d0, 0x88, 0x15, 0x00, 0xa0, 0xc9, 0x06, 0xbe, 0xd8);
	public const Guid GUID_DEVINTERFACE_USB_BILLBOARD = .(0x5e9adaef, 0xf879, 0x473f, 0xb8, 0x07, 0x4e, 0x5e, 0xa7, 0x7d, 0x1b, 0x1c);
	public const Guid GUID_DEVINTERFACE_USB_DEVICE = .(0xa5dcbf10, 0x6530, 0x11d2, 0x90, 0x1f, 0x00, 0xc0, 0x4f, 0xb9, 0x51, 0xed);
	public const Guid GUID_DEVINTERFACE_USB_HOST_CONTROLLER = .(0x3abf6f2d, 0x71c4, 0x462a, 0x8a, 0x92, 0x1e, 0x68, 0x61, 0xe6, 0xaf, 0x27);
	public const Guid GUID_USB_WMI_STD_DATA = .(0x4e623b20, 0xcb14, 0x11d1, 0xb3, 0x31, 0x00, 0xa0, 0xc9, 0x59, 0xbb, 0xd2);
	public const Guid GUID_USB_WMI_STD_NOTIFICATION = .(0x4e623b20, 0xcb14, 0x11d1, 0xb3, 0x31, 0x00, 0xa0, 0xc9, 0x59, 0xbb, 0xd2);
	public const Guid GUID_USB_WMI_DEVICE_PERF_INFO = .(0x66c1aa3c, 0x499f, 0x49a0, 0xa9, 0xa5, 0x61, 0xe2, 0x35, 0x9f, 0x64, 0x07);
	public const Guid GUID_USB_WMI_NODE_INFO = .(0x9c179357, 0xdc7a, 0x4f41, 0xb6, 0x6b, 0x32, 0x3b, 0x9d, 0xdc, 0xb5, 0xb1);
	public const Guid GUID_USB_WMI_TRACING = .(0x3a61881b, 0xb4e6, 0x4bf9, 0xae, 0x0f, 0x3c, 0xd8, 0xf3, 0x94, 0xe5, 0x2f);
	public const Guid GUID_USB_TRANSFER_TRACING = .(0x681eb8aa, 0x403d, 0x452c, 0x9f, 0x8a, 0xf0, 0x61, 0x6f, 0xac, 0x95, 0x40);
	public const Guid GUID_USB_PERFORMANCE_TRACING = .(0xd5de77a6, 0x6ae9, 0x425c, 0xb1, 0xe2, 0xf5, 0x61, 0x5f, 0xd3, 0x48, 0xa9);
	public const Guid GUID_USB_WMI_SURPRISE_REMOVAL_NOTIFICATION = .(0x9bbbf831, 0xa2f2, 0x43b4, 0x96, 0xd1, 0x86, 0x94, 0x4b, 0x59, 0x14, 0xb3);
	public const uint32 FILE_DEVICE_USB = 34;
	public const uint32 BMREQUEST_HOST_TO_DEVICE = 0;
	public const uint32 BMREQUEST_DEVICE_TO_HOST = 1;
	public const uint32 BMREQUEST_STANDARD = 0;
	public const uint32 BMREQUEST_CLASS = 1;
	public const uint32 BMREQUEST_VENDOR = 2;
	public const uint32 BMREQUEST_TO_DEVICE = 0;
	public const uint32 BMREQUEST_TO_INTERFACE = 1;
	public const uint32 BMREQUEST_TO_ENDPOINT = 2;
	public const uint32 BMREQUEST_TO_OTHER = 3;
	public const uint32 USB_REQUEST_GET_STATUS = 0;
	public const uint32 USB_REQUEST_CLEAR_FEATURE = 1;
	public const uint32 USB_REQUEST_SET_FEATURE = 3;
	public const uint32 USB_REQUEST_SET_ADDRESS = 5;
	public const uint32 USB_REQUEST_GET_DESCRIPTOR = 6;
	public const uint32 USB_REQUEST_SET_DESCRIPTOR = 7;
	public const uint32 USB_REQUEST_GET_CONFIGURATION = 8;
	public const uint32 USB_REQUEST_SET_CONFIGURATION = 9;
	public const uint32 USB_REQUEST_GET_INTERFACE = 10;
	public const uint32 USB_REQUEST_SET_INTERFACE = 11;
	public const uint32 USB_REQUEST_SYNC_FRAME = 12;
	public const uint32 USB_REQUEST_GET_FIRMWARE_STATUS = 26;
	public const uint32 USB_REQUEST_SET_FIRMWARE_STATUS = 27;
	public const uint32 USB_GET_FIRMWARE_ALLOWED_OR_DISALLOWED_STATE = 0;
	public const uint32 USB_GET_FIRMWARE_HASH = 1;
	public const uint32 USB_DEVICE_FIRMWARE_HASH_LENGTH = 32;
	public const uint32 USB_DISALLOW_FIRMWARE_UPDATE = 0;
	public const uint32 USB_ALLOW_FIRMWARE_UPDATE = 1;
	public const uint32 USB_REQUEST_SET_SEL = 48;
	public const uint32 USB_REQUEST_ISOCH_DELAY = 49;
	public const uint32 USB_DEVICE_DESCRIPTOR_TYPE = 1;
	public const uint32 USB_CONFIGURATION_DESCRIPTOR_TYPE = 2;
	public const uint32 USB_STRING_DESCRIPTOR_TYPE = 3;
	public const uint32 USB_INTERFACE_DESCRIPTOR_TYPE = 4;
	public const uint32 USB_ENDPOINT_DESCRIPTOR_TYPE = 5;
	public const uint32 USB_DEVICE_QUALIFIER_DESCRIPTOR_TYPE = 6;
	public const uint32 USB_OTHER_SPEED_CONFIGURATION_DESCRIPTOR_TYPE = 7;
	public const uint32 USB_INTERFACE_POWER_DESCRIPTOR_TYPE = 8;
	public const uint32 USB_OTG_DESCRIPTOR_TYPE = 9;
	public const uint32 USB_DEBUG_DESCRIPTOR_TYPE = 10;
	public const uint32 USB_INTERFACE_ASSOCIATION_DESCRIPTOR_TYPE = 11;
	public const uint32 USB_BOS_DESCRIPTOR_TYPE = 15;
	public const uint32 USB_DEVICE_CAPABILITY_DESCRIPTOR_TYPE = 16;
	public const uint32 USB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR_TYPE = 48;
	public const uint32 USB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR_TYPE = 49;
	public const uint32 USB_RESERVED_DESCRIPTOR_TYPE = 6;
	public const uint32 USB_CONFIG_POWER_DESCRIPTOR_TYPE = 7;
	public const uint32 USB_FEATURE_ENDPOINT_STALL = 0;
	public const uint32 USB_FEATURE_REMOTE_WAKEUP = 1;
	public const uint32 USB_FEATURE_TEST_MODE = 2;
	public const uint32 USB_FEATURE_FUNCTION_SUSPEND = 0;
	public const uint32 USB_FEATURE_U1_ENABLE = 48;
	public const uint32 USB_FEATURE_U2_ENABLE = 49;
	public const uint32 USB_FEATURE_LTM_ENABLE = 50;
	public const uint32 USB_FEATURE_LDM_ENABLE = 53;
	public const uint32 USB_FEATURE_BATTERY_WAKE_MASK = 40;
	public const uint32 USB_FEATURE_OS_IS_PD_AWARE = 41;
	public const uint32 USB_FEATURE_POLICY_MODE = 42;
	public const uint32 USB_FEATURE_CHARGING_POLICY = 54;
	public const uint32 USB_CHARGING_POLICY_DEFAULT = 0;
	public const uint32 USB_CHARGING_POLICY_ICCHPF = 1;
	public const uint32 USB_CHARGING_POLICY_ICCLPF = 2;
	public const uint32 USB_CHARGING_POLICY_NO_POWER = 3;
	public const uint32 USB_STATUS_PORT_STATUS = 0;
	public const uint32 USB_STATUS_PD_STATUS = 1;
	public const uint32 USB_STATUS_EXT_PORT_STATUS = 2;
	public const uint32 USB_GETSTATUS_SELF_POWERED = 1;
	public const uint32 USB_GETSTATUS_REMOTE_WAKEUP_ENABLED = 2;
	public const uint32 USB_GETSTATUS_U1_ENABLE = 4;
	public const uint32 USB_GETSTATUS_U2_ENABLE = 8;
	public const uint32 USB_GETSTATUS_LTM_ENABLE = 16;
	public const uint32 USB_DEVICE_CLASS_RESERVED = 0;
	public const uint32 USB_DEVICE_CLASS_AUDIO = 1;
	public const uint32 USB_DEVICE_CLASS_COMMUNICATIONS = 2;
	public const uint32 USB_DEVICE_CLASS_HUMAN_INTERFACE = 3;
	public const uint32 USB_DEVICE_CLASS_MONITOR = 4;
	public const uint32 USB_DEVICE_CLASS_PHYSICAL_INTERFACE = 5;
	public const uint32 USB_DEVICE_CLASS_POWER = 6;
	public const uint32 USB_DEVICE_CLASS_IMAGE = 6;
	public const uint32 USB_DEVICE_CLASS_PRINTER = 7;
	public const uint32 USB_DEVICE_CLASS_STORAGE = 8;
	public const uint32 USB_DEVICE_CLASS_HUB = 9;
	public const uint32 USB_DEVICE_CLASS_CDC_DATA = 10;
	public const uint32 USB_DEVICE_CLASS_SMART_CARD = 11;
	public const uint32 USB_DEVICE_CLASS_CONTENT_SECURITY = 13;
	public const uint32 USB_DEVICE_CLASS_VIDEO = 14;
	public const uint32 USB_DEVICE_CLASS_PERSONAL_HEALTHCARE = 15;
	public const uint32 USB_DEVICE_CLASS_AUDIO_VIDEO = 16;
	public const uint32 USB_DEVICE_CLASS_BILLBOARD = 17;
	public const uint32 USB_DEVICE_CLASS_DIAGNOSTIC_DEVICE = 220;
	public const uint32 USB_DEVICE_CLASS_WIRELESS_CONTROLLER = 224;
	public const uint32 USB_DEVICE_CLASS_MISCELLANEOUS = 239;
	public const uint32 USB_DEVICE_CLASS_APPLICATION_SPECIFIC = 254;
	public const uint32 USB_DEVICE_CLASS_VENDOR_SPECIFIC = 255;
	public const uint32 USB_DEVICE_CAPABILITY_WIRELESS_USB = 1;
	public const uint32 USB_DEVICE_CAPABILITY_USB20_EXTENSION = 2;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_USB = 3;
	public const uint32 USB_DEVICE_CAPABILITY_CONTAINER_ID = 4;
	public const uint32 USB_DEVICE_CAPABILITY_PLATFORM = 5;
	public const uint32 USB_DEVICE_CAPABILITY_POWER_DELIVERY = 6;
	public const uint32 USB_DEVICE_CAPABILITY_BATTERY_INFO = 7;
	public const uint32 USB_DEVICE_CAPABILITY_PD_CONSUMER_PORT = 8;
	public const uint32 USB_DEVICE_CAPABILITY_PD_PROVIDER_PORT = 9;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_USB = 10;
	public const uint32 USB_DEVICE_CAPABILITY_PRECISION_TIME_MEASUREMENT = 11;
	public const uint32 USB_DEVICE_CAPABILITY_BILLBOARD = 13;
	public const uint32 USB_DEVICE_CAPABILITY_FIRMWARE_STATUS = 17;
	public const uint32 USB_DEVICE_CAPABILITY_USB20_EXTENSION_BMATTRIBUTES_RESERVED_MASK = 4294901985;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_BMATTRIBUTES_RESERVED_MASK = 253;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_BMATTRIBUTES_LTM_CAPABLE = 2;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_RESERVED_MASK = 65520;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_LOW = 1;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_FULL = 2;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_HIGH = 4;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_SUPER = 8;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_U1_DEVICE_EXIT_MAX_VALUE = 10;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEED_U2_DEVICE_EXIT_MAX_VALUE = 2047;
	public const uint32 USB_DEVICE_CAPABILITY_MAX_U1_LATENCY = 10;
	public const uint32 USB_DEVICE_CAPABILITY_MAX_U2_LATENCY = 2047;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_LSE_BPS = 0;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_LSE_KBPS = 1;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_LSE_MBPS = 2;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_LSE_GBPS = 3;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_MODE_SYMMETRIC = 0;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_MODE_ASYMMETRIC = 1;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_DIR_RX = 0;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_DIR_TX = 1;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_PROTOCOL_SS = 0;
	public const uint32 USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED_PROTOCOL_SSP = 1;
	public const Guid GUID_USB_MSOS20_PLATFORM_CAPABILITY_ID = .(0xd8dd60df, 0x4589, 0x4cc7, 0x9c, 0xd2, 0x65, 0x9d, 0x9e, 0x64, 0x8a, 0x9f);
	public const uint32 USB_CONFIG_POWERED_MASK = 192;
	public const uint32 USB_CONFIG_BUS_POWERED = 128;
	public const uint32 USB_CONFIG_SELF_POWERED = 64;
	public const uint32 USB_CONFIG_REMOTE_WAKEUP = 32;
	public const uint32 USB_CONFIG_RESERVED = 31;
	public const uint32 USB_ENDPOINT_DIRECTION_MASK = 128;
	public const uint32 USB_ENDPOINT_ADDRESS_MASK = 15;
	public const uint32 USB_ENDPOINT_TYPE_MASK = 3;
	public const uint32 USB_ENDPOINT_TYPE_CONTROL = 0;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS = 1;
	public const uint32 USB_ENDPOINT_TYPE_BULK = 2;
	public const uint32 USB_ENDPOINT_TYPE_INTERRUPT = 3;
	public const uint32 USB_ENDPOINT_TYPE_BULK_RESERVED_MASK = 252;
	public const uint32 USB_ENDPOINT_TYPE_CONTROL_RESERVED_MASK = 252;
	public const uint32 USB_20_ENDPOINT_TYPE_INTERRUPT_RESERVED_MASK = 252;
	public const uint32 USB_30_ENDPOINT_TYPE_INTERRUPT_RESERVED_MASK = 204;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_RESERVED_MASK = 192;
	public const uint32 USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_MASK = 48;
	public const uint32 USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_PERIODIC = 0;
	public const uint32 USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_NOTIFICATION = 16;
	public const uint32 USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_RESERVED10 = 32;
	public const uint32 USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_RESERVED11 = 48;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_MASK = 12;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_NO_SYNCHRONIZATION = 0;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_ASYNCHRONOUS = 4;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_ADAPTIVE = 8;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_SYNCHRONOUS = 12;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_MASK = 48;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_DATA_ENDOINT = 0;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_FEEDBACK_ENDPOINT = 16;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_IMPLICIT_FEEDBACK_DATA_ENDPOINT = 32;
	public const uint32 USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_RESERVED = 48;
	public const uint32 USB_ENDPOINT_SUPERSPEED_BULK_MAX_PACKET_SIZE = 1024;
	public const uint32 USB_ENDPOINT_SUPERSPEED_CONTROL_MAX_PACKET_SIZE = 512;
	public const uint32 USB_ENDPOINT_SUPERSPEED_ISO_MAX_PACKET_SIZE = 1024;
	public const uint32 USB_ENDPOINT_SUPERSPEED_INTERRUPT_MAX_PACKET_SIZE = 1024;
	public const uint32 MAXIMUM_USB_STRING_LENGTH = 255;
	public const uint32 USB_SUPERSPEED_ISOCHRONOUS_MAX_MULTIPLIER = 2;
	public const uint32 USB_SUPERSPEEDPLUS_ISOCHRONOUS_MIN_BYTESPERINTERVAL = 49153;
	public const uint32 USB_SUPERSPEEDPLUS_ISOCHRONOUS_MAX_BYTESPERINTERVAL = 16777215;
	public const uint32 USB_20_HUB_DESCRIPTOR_TYPE = 41;
	public const uint32 USB_30_HUB_DESCRIPTOR_TYPE = 42;
	public const uint32 USB_REQUEST_GET_STATE = 2;
	public const uint32 USB_REQUEST_CLEAR_TT_BUFFER = 8;
	public const uint32 USB_REQUEST_RESET_TT = 9;
	public const uint32 USB_REQUEST_GET_TT_STATE = 10;
	public const uint32 USB_REQUEST_STOP_TT = 11;
	public const uint32 USB_REQUEST_SET_HUB_DEPTH = 12;
	public const uint32 USB_REQUEST_GET_PORT_ERR_COUNT = 13;
	public const uint32 USB_PORT_STATUS_CONNECT = 1;
	public const uint32 USB_PORT_STATUS_ENABLE = 2;
	public const uint32 USB_PORT_STATUS_SUSPEND = 4;
	public const uint32 USB_PORT_STATUS_OVER_CURRENT = 8;
	public const uint32 USB_PORT_STATUS_RESET = 16;
	public const uint32 USB_PORT_STATUS_POWER = 256;
	public const uint32 USB_PORT_STATUS_LOW_SPEED = 512;
	public const uint32 USB_PORT_STATUS_HIGH_SPEED = 1024;
	public const uint32 PORT_LINK_STATE_U0 = 0;
	public const uint32 PORT_LINK_STATE_U1 = 1;
	public const uint32 PORT_LINK_STATE_U2 = 2;
	public const uint32 PORT_LINK_STATE_U3 = 3;
	public const uint32 PORT_LINK_STATE_DISABLED = 4;
	public const uint32 PORT_LINK_STATE_RX_DETECT = 5;
	public const uint32 PORT_LINK_STATE_INACTIVE = 6;
	public const uint32 PORT_LINK_STATE_POLLING = 7;
	public const uint32 PORT_LINK_STATE_RECOVERY = 8;
	public const uint32 PORT_LINK_STATE_HOT_RESET = 9;
	public const uint32 PORT_LINK_STATE_COMPLIANCE_MODE = 10;
	public const uint32 PORT_LINK_STATE_LOOPBACK = 11;
	public const uint32 PORT_LINK_STATE_TEST_MODE = 11;
	public const uint32 USB_FEATURE_INTERFACE_POWER_D0 = 2;
	public const uint32 USB_FEATURE_INTERFACE_POWER_D1 = 3;
	public const uint32 USB_FEATURE_INTERFACE_POWER_D2 = 4;
	public const uint32 USB_FEATURE_INTERFACE_POWER_D3 = 5;
	public const uint32 USB_SUPPORT_D0_COMMAND = 1;
	public const uint32 USB_SUPPORT_D1_COMMAND = 2;
	public const uint32 USB_SUPPORT_D2_COMMAND = 4;
	public const uint32 USB_SUPPORT_D3_COMMAND = 8;
	public const uint32 USB_SUPPORT_D1_WAKEUP = 16;
	public const uint32 USB_SUPPORT_D2_WAKEUP = 32;
	public const uint32 USBDI_VERSION = 1536;
	public const uint32 USB_PORTATTR_NO_CONNECTOR = 1;
	public const uint32 USB_PORTATTR_SHARED_USB2 = 2;
	public const uint32 USB_PORTATTR_MINI_CONNECTOR = 4;
	public const uint32 USB_PORTATTR_OEM_CONNECTOR = 8;
	public const uint32 USB_PORTATTR_OWNED_BY_CC = 16777216;
	public const uint32 USB_PORTATTR_NO_OVERCURRENT_UI = 33554432;
	public const uint32 USB_DEFAULT_DEVICE_ADDRESS = 0;
	public const uint32 USB_DEFAULT_ENDPOINT_ADDRESS = 0;
	public const uint32 USB_DEFAULT_MAX_PACKET = 64;
	public const uint32 URB_FUNCTION_SELECT_CONFIGURATION = 0;
	public const uint32 URB_FUNCTION_SELECT_INTERFACE = 1;
	public const uint32 URB_FUNCTION_ABORT_PIPE = 2;
	public const uint32 URB_FUNCTION_TAKE_FRAME_LENGTH_CONTROL = 3;
	public const uint32 URB_FUNCTION_RELEASE_FRAME_LENGTH_CONTROL = 4;
	public const uint32 URB_FUNCTION_GET_FRAME_LENGTH = 5;
	public const uint32 URB_FUNCTION_SET_FRAME_LENGTH = 6;
	public const uint32 URB_FUNCTION_GET_CURRENT_FRAME_NUMBER = 7;
	public const uint32 URB_FUNCTION_CONTROL_TRANSFER = 8;
	public const uint32 URB_FUNCTION_BULK_OR_INTERRUPT_TRANSFER = 9;
	public const uint32 URB_FUNCTION_ISOCH_TRANSFER = 10;
	public const uint32 URB_FUNCTION_GET_DESCRIPTOR_FROM_DEVICE = 11;
	public const uint32 URB_FUNCTION_SET_DESCRIPTOR_TO_DEVICE = 12;
	public const uint32 URB_FUNCTION_SET_FEATURE_TO_DEVICE = 13;
	public const uint32 URB_FUNCTION_SET_FEATURE_TO_INTERFACE = 14;
	public const uint32 URB_FUNCTION_SET_FEATURE_TO_ENDPOINT = 15;
	public const uint32 URB_FUNCTION_CLEAR_FEATURE_TO_DEVICE = 16;
	public const uint32 URB_FUNCTION_CLEAR_FEATURE_TO_INTERFACE = 17;
	public const uint32 URB_FUNCTION_CLEAR_FEATURE_TO_ENDPOINT = 18;
	public const uint32 URB_FUNCTION_GET_STATUS_FROM_DEVICE = 19;
	public const uint32 URB_FUNCTION_GET_STATUS_FROM_INTERFACE = 20;
	public const uint32 URB_FUNCTION_GET_STATUS_FROM_ENDPOINT = 21;
	public const uint32 URB_FUNCTION_RESERVED_0X0016 = 22;
	public const uint32 URB_FUNCTION_VENDOR_DEVICE = 23;
	public const uint32 URB_FUNCTION_VENDOR_INTERFACE = 24;
	public const uint32 URB_FUNCTION_VENDOR_ENDPOINT = 25;
	public const uint32 URB_FUNCTION_CLASS_DEVICE = 26;
	public const uint32 URB_FUNCTION_CLASS_INTERFACE = 27;
	public const uint32 URB_FUNCTION_CLASS_ENDPOINT = 28;
	public const uint32 URB_FUNCTION_RESERVE_0X001D = 29;
	public const uint32 URB_FUNCTION_SYNC_RESET_PIPE_AND_CLEAR_STALL = 30;
	public const uint32 URB_FUNCTION_CLASS_OTHER = 31;
	public const uint32 URB_FUNCTION_VENDOR_OTHER = 32;
	public const uint32 URB_FUNCTION_GET_STATUS_FROM_OTHER = 33;
	public const uint32 URB_FUNCTION_CLEAR_FEATURE_TO_OTHER = 34;
	public const uint32 URB_FUNCTION_SET_FEATURE_TO_OTHER = 35;
	public const uint32 URB_FUNCTION_GET_DESCRIPTOR_FROM_ENDPOINT = 36;
	public const uint32 URB_FUNCTION_SET_DESCRIPTOR_TO_ENDPOINT = 37;
	public const uint32 URB_FUNCTION_GET_CONFIGURATION = 38;
	public const uint32 URB_FUNCTION_GET_INTERFACE = 39;
	public const uint32 URB_FUNCTION_GET_DESCRIPTOR_FROM_INTERFACE = 40;
	public const uint32 URB_FUNCTION_SET_DESCRIPTOR_TO_INTERFACE = 41;
	public const uint32 URB_FUNCTION_RESERVE_0X002B = 43;
	public const uint32 URB_FUNCTION_RESERVE_0X002C = 44;
	public const uint32 URB_FUNCTION_RESERVE_0X002D = 45;
	public const uint32 URB_FUNCTION_RESERVE_0X002E = 46;
	public const uint32 URB_FUNCTION_RESERVE_0X002F = 47;
	public const uint32 URB_FUNCTION_GET_MS_FEATURE_DESCRIPTOR = 42;
	public const uint32 URB_FUNCTION_SYNC_RESET_PIPE = 48;
	public const uint32 URB_FUNCTION_SYNC_CLEAR_STALL = 49;
	public const uint32 URB_FUNCTION_CONTROL_TRANSFER_EX = 50;
	public const uint32 URB_FUNCTION_RESERVE_0X0033 = 51;
	public const uint32 URB_FUNCTION_RESERVE_0X0034 = 52;
	public const uint32 URB_FUNCTION_OPEN_STATIC_STREAMS = 53;
	public const uint32 URB_FUNCTION_CLOSE_STATIC_STREAMS = 54;
	public const uint32 URB_FUNCTION_BULK_OR_INTERRUPT_TRANSFER_USING_CHAINED_MDL = 55;
	public const uint32 URB_FUNCTION_ISOCH_TRANSFER_USING_CHAINED_MDL = 56;
	public const uint32 URB_FUNCTION_GET_ISOCH_PIPE_TRANSFER_PATH_DELAYS = 61;
	public const uint32 URB_FUNCTION_RESET_PIPE = 30;
	public const uint32 USBD_SHORT_TRANSFER_OK = 2;
	public const uint32 USBD_START_ISO_TRANSFER_ASAP = 4;
	public const uint32 USBD_DEFAULT_PIPE_TRANSFER = 8;
	public const uint32 USBD_TRANSFER_DIRECTION_OUT = 0;
	public const uint32 USBD_TRANSFER_DIRECTION_IN = 1;
	public const uint32 USBD_TRANSFER_DIRECTION = 1;
	public const uint32 USBD_ISO_START_FRAME_RANGE = 1024;
	public const uint32 USBD_DEFAULT_MAXIMUM_TRANSFER_SIZE = 4294967295;
	public const uint32 USBD_PF_CHANGE_MAX_PACKET = 1;
	public const uint32 USBD_PF_SHORT_PACKET_OPT = 2;
	public const uint32 USBD_PF_ENABLE_RT_THREAD_ACCESS = 4;
	public const uint32 USBD_PF_MAP_ADD_TRANSFERS = 8;
	public const uint32 USBD_PF_VIDEO_PRIORITY = 16;
	public const uint32 USBD_PF_VOICE_PRIORITY = 32;
	public const uint32 USBD_PF_INTERACTIVE_PRIORITY = 48;
	public const uint32 USBD_PF_PRIORITY_MASK = 240;
	public const uint32 USBD_PF_HANDLES_SSP_HIGH_BANDWIDTH_ISOCH = 256;
	public const uint32 USBD_PF_SSP_HIGH_BANDWIDTH_ISOCH = 65536;
	public const uint32 OS_STRING_DESCRIPTOR_INDEX = 238;
	public const uint32 MS_GENRE_DESCRIPTOR_INDEX = 1;
	public const uint32 MS_POWER_DESCRIPTOR_INDEX = 2;
	public const String MS_OS_STRING_SIGNATURE = "MSFT100";
	public const uint32 MS_OS_FLAGS_CONTAINERID = 2;
	public const uint32 URB_OPEN_STATIC_STREAMS_VERSION_100 = 256;
	public const String KREGUSBFNENUMPATH = "\\Registry\\Machine\\SYSTEM\\CurrentControlSet\\Control\\USBFN\\";
	public const String UREGUSBFNENUMPATH = "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\USBFN\\";
	public const String KREGMANUSBFNENUMPATH = "\\Registry\\Machine\\SYSTEM\\CurrentControlSet\\Control\\ManufacturingMode\\Current\\USBFN\\";
	public const String UREGMANUSBFNENUMPATH = "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\ManufacturingMode\\Current\\USBFN\\";
	public const uint32 MAX_NUM_USBFN_ENDPOINTS = 15;
	public const uint32 MAX_CONFIGURATION_NAME_LENGTH = 40;
	public const uint32 MAX_USB_STRING_LENGTH = 255;
	public const uint32 MAX_SUPPORTED_CONFIGURATIONS = 12;
	public const uint32 USBFN_INTERRUPT_ENDPOINT_SIZE_NOT_UPDATEABLE_MASK = 128;
	public const uint32 USB_TEST_MODE_TEST_J = 1;
	public const uint32 USB_TEST_MODE_TEST_K = 2;
	public const uint32 USB_TEST_MODE_TEST_SE0_NAK = 3;
	public const uint32 USB_TEST_MODE_TEST_PACKET = 4;
	public const uint32 USB_TEST_MODE_TEST_FORCE_ENABLE = 5;
	public const uint32 MAX_INTERFACE_NAME_LENGTH = 40;
	public const uint32 MAX_ALTERNATE_NAME_LENGTH = 40;
	public const uint32 MAX_ASSOCIATION_NAME_LENGTH = 40;
	public const uint32 IOCTL_INTERNAL_USB_SUBMIT_URB = 2228227;
	public const uint32 IOCTL_INTERNAL_USB_RESET_PORT = 2228231;
	public const uint32 IOCTL_INTERNAL_USB_GET_ROOTHUB_PDO = 2228239;
	public const uint32 USBD_PORT_ENABLED = 1;
	public const uint32 USBD_PORT_CONNECTED = 2;
	public const uint32 IOCTL_INTERNAL_USB_GET_PORT_STATUS = 2228243;
	public const uint32 IOCTL_INTERNAL_USB_ENABLE_PORT = 2228247;
	public const uint32 IOCTL_INTERNAL_USB_GET_HUB_COUNT = 2228251;
	public const uint32 IOCTL_INTERNAL_USB_CYCLE_PORT = 2228255;
	public const uint32 IOCTL_INTERNAL_USB_GET_HUB_NAME = 2228256;
	public const uint32 IOCTL_INTERNAL_USB_GET_BUS_INFO = 2229280;
	public const uint32 IOCTL_INTERNAL_USB_GET_CONTROLLER_NAME = 2229284;
	public const uint32 IOCTL_INTERNAL_USB_GET_BUSGUID_INFO = 2229288;
	public const uint32 IOCTL_INTERNAL_USB_GET_PARENT_HUB_INFO = 2229292;
	public const uint32 IOCTL_INTERNAL_USB_SUBMIT_IDLE_NOTIFICATION = 2228263;
	public const uint32 IOCTL_INTERNAL_USB_GET_DEVICE_HANDLE = 2229299;
	public const uint32 IOCTL_INTERNAL_USB_NOTIFY_IDLE_READY = 2229315;
	public const uint32 IOCTL_INTERNAL_USB_REQ_GLOBAL_SUSPEND = 2229319;
	public const uint32 IOCTL_INTERNAL_USB_REQ_GLOBAL_RESUME = 2229323;
	public const uint32 IOCTL_INTERNAL_USB_RECORD_FAILURE = 2228267;
	public const uint32 IOCTL_INTERNAL_USB_GET_DEVICE_HANDLE_EX = 2229303;
	public const uint32 IOCTL_INTERNAL_USB_GET_TT_DEVICE_HANDLE = 2229307;
	public const uint32 IOCTL_INTERNAL_USB_GET_TOPOLOGY_ADDRESS = 2229311;
	public const uint32 IOCTL_INTERNAL_USB_GET_DEVICE_CONFIG_INFO = 2229327;
	public const uint32 IOCTL_INTERNAL_USB_REGISTER_COMPOSITE_DEVICE = 4784131;
	public const uint32 IOCTL_INTERNAL_USB_UNREGISTER_COMPOSITE_DEVICE = 4784135;
	public const uint32 IOCTL_INTERNAL_USB_REQUEST_REMOTE_WAKE_NOTIFICATION = 4784139;
	public const uint32 IOCTL_INTERNAL_USB_FAIL_GET_STATUS_FROM_DEVICE = 2229347;
	public const uint32 IOCTL_USB_HCD_GET_STATS_1 = 2229244;
	public const uint32 IOCTL_USB_HCD_GET_STATS_2 = 2229288;
	public const uint32 IOCTL_USB_HCD_DISABLE_PORT = 2229296;
	public const uint32 IOCTL_USB_HCD_ENABLE_PORT = 2229300;
	public const uint32 IOCTL_USB_DIAGNOSTIC_MODE_ON = 2229248;
	public const uint32 IOCTL_USB_DIAGNOSTIC_MODE_OFF = 2229252;
	public const uint32 IOCTL_USB_GET_ROOT_HUB_NAME = 2229256;
	public const uint32 IOCTL_GET_HCD_DRIVERKEY_NAME = 2229284;
	public const uint32 IOCTL_USB_GET_NODE_INFORMATION = 2229256;
	public const uint32 IOCTL_USB_GET_NODE_CONNECTION_INFORMATION = 2229260;
	public const uint32 IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION = 2229264;
	public const uint32 IOCTL_USB_GET_NODE_CONNECTION_NAME = 2229268;
	public const uint32 IOCTL_USB_DIAG_IGNORE_HUBS_ON = 2229272;
	public const uint32 IOCTL_USB_DIAG_IGNORE_HUBS_OFF = 2229276;
	public const uint32 IOCTL_USB_GET_NODE_CONNECTION_DRIVERKEY_NAME = 2229280;
	public const uint32 IOCTL_USB_GET_HUB_CAPABILITIES = 2229308;
	public const uint32 IOCTL_USB_HUB_CYCLE_PORT = 2229316;
	public const uint32 IOCTL_USB_GET_NODE_CONNECTION_ATTRIBUTES = 2229312;
	public const uint32 IOCTL_USB_GET_NODE_CONNECTION_INFORMATION_EX = 2229320;
	public const uint32 IOCTL_USB_RESET_HUB = 2229324;
	public const uint32 IOCTL_USB_GET_HUB_CAPABILITIES_EX = 2229328;
	public const uint32 IOCTL_USB_GET_HUB_INFORMATION_EX = 2229332;
	public const uint32 IOCTL_USB_GET_PORT_CONNECTOR_PROPERTIES = 2229336;
	public const uint32 IOCTL_USB_GET_NODE_CONNECTION_INFORMATION_EX_V2 = 2229340;
	public const uint32 IOCTL_USB_GET_TRANSPORT_CHARACTERISTICS = 2229348;
	public const uint32 IOCTL_USB_REGISTER_FOR_TRANSPORT_CHARACTERISTICS_CHANGE = 2229352;
	public const uint32 IOCTL_USB_NOTIFY_ON_TRANSPORT_CHARACTERISTICS_CHANGE = 2229356;
	public const uint32 IOCTL_USB_UNREGISTER_FOR_TRANSPORT_CHARACTERISTICS_CHANGE = 2229360;
	public const uint32 IOCTL_USB_START_TRACKING_FOR_TIME_SYNC = 2229364;
	public const uint32 IOCTL_USB_GET_FRAME_NUMBER_AND_QPC_FOR_TIME_SYNC = 2229368;
	public const uint32 IOCTL_USB_STOP_TRACKING_FOR_TIME_SYNC = 2229372;
	public const uint32 IOCTL_USB_GET_DEVICE_CHARACTERISTICS = 2229376;
	public const uint32 WMI_USB_DRIVER_INFORMATION = 0;
	public const uint32 WMI_USB_DRIVER_NOTIFICATION = 1;
	public const uint32 WMI_USB_POWER_DEVICE_ENABLE = 2;
	public const uint32 WMI_USB_HUB_NODE_INFORMATION = 4;
	public const uint32 WMI_USB_PERFORMANCE_INFORMATION = 1;
	public const uint32 WMI_USB_DEVICE_NODE_INFORMATION = 2;
	public const uint32 USB_TRANSPORT_CHARACTERISTICS_VERSION_1 = 1;
	public const uint32 USB_TRANSPORT_CHARACTERISTICS_LATENCY_AVAILABLE = 1;
	public const uint32 USB_TRANSPORT_CHARACTERISTICS_BANDWIDTH_AVAILABLE = 2;
	public const uint32 USB_REGISTER_FOR_TRANSPORT_LATENCY_CHANGE = 1;
	public const uint32 USB_REGISTER_FOR_TRANSPORT_BANDWIDTH_CHANGE = 2;
	public const uint32 USB_DEVICE_CHARACTERISTICS_VERSION_1 = 1;
	public const uint32 USB_DEVICE_CHARACTERISTICS_MAXIMUM_PATH_DELAYS_AVAILABLE = 1;
	public const uint32 MAX_NUM_PIPES = 8;
	public const uint32 BULKIN_FLAG = 128;
	public const uint32 FILE_DEVICE_USB_SCAN = 32768;
	public const uint32 IOCTL_INDEX = 2048;
	public const uint32 IOCTL_GET_VERSION = 2147491840;
	public const uint32 IOCTL_CANCEL_IO = 2147491844;
	public const uint32 IOCTL_WAIT_ON_DEVICE_EVENT = 2147491848;
	public const uint32 IOCTL_READ_REGISTERS = 2147491852;
	public const uint32 IOCTL_WRITE_REGISTERS = 2147491856;
	public const uint32 IOCTL_GET_CHANNEL_ALIGN_RQST = 2147491860;
	public const uint32 IOCTL_GET_DEVICE_DESCRIPTOR = 2147491864;
	public const uint32 IOCTL_RESET_PIPE = 2147491868;
	public const uint32 IOCTL_GET_USB_DESCRIPTOR = 2147491872;
	public const uint32 IOCTL_SEND_USB_REQUEST = 2147491876;
	public const uint32 IOCTL_GET_PIPE_CONFIGURATION = 2147491880;
	public const uint32 IOCTL_SET_TIMEOUT = 2147491884;
	public const uint32 IOCTL_ABORT_PIPE = 2147491844;
	public const Guid WinUSB_TestGuid = .(0xda812bff, 0x12c3, 0x46a2, 0x8e, 0x2b, 0xdb, 0xd3, 0xb7, 0x83, 0x4c, 0x43);
}
#endregion

#region Enums

[AllowDuplicates]
public enum USB_DEVICE_SPEED : int32
{
	UsbLowSpeed = 0,
	UsbFullSpeed = 1,
	UsbHighSpeed = 2,
	UsbSuperSpeed = 3,
}


[AllowDuplicates]
public enum USB_DEVICE_TYPE : int32
{
	Usb11Device = 0,
	Usb20Device = 1,
}


[AllowDuplicates]
public enum USB_CONTROLLER_FLAVOR : int32
{
	USB_HcGeneric = 0,
	OHCI_Generic = 100,
	OHCI_Hydra = 101,
	OHCI_NEC = 102,
	UHCI_Generic = 200,
	UHCI_Piix4 = 201,
	UHCI_Piix3 = 202,
	UHCI_Ich2 = 203,
	UHCI_Reserved204 = 204,
	UHCI_Ich1 = 205,
	UHCI_Ich3m = 206,
	UHCI_Ich4 = 207,
	UHCI_Ich5 = 208,
	UHCI_Ich6 = 209,
	UHCI_Intel = 249,
	UHCI_VIA = 250,
	UHCI_VIA_x01 = 251,
	UHCI_VIA_x02 = 252,
	UHCI_VIA_x03 = 253,
	UHCI_VIA_x04 = 254,
	UHCI_VIA_x0E_FIFO = 264,
	EHCI_Generic = 1000,
	EHCI_NEC = 2000,
	EHCI_Lucent = 3000,
	EHCI_NVIDIA_Tegra2 = 4000,
	EHCI_NVIDIA_Tegra3 = 4001,
	EHCI_Intel_Medfield = 5001,
}


[AllowDuplicates]
public enum USBD_PIPE_TYPE : int32
{
	UsbdPipeTypeControl = 0,
	UsbdPipeTypeIsochronous = 1,
	UsbdPipeTypeBulk = 2,
	UsbdPipeTypeInterrupt = 3,
}


[AllowDuplicates]
public enum USBD_ENDPOINT_OFFLOAD_MODE : int32
{
	UsbdEndpointOffloadModeNotSupported = 0,
	UsbdEndpointOffloadSoftwareAssisted = 1,
	UsbdEndpointOffloadHardwareAssisted = 2,
}


[AllowDuplicates]
public enum USB_USER_ERROR_CODE : int32
{
	UsbUserSuccess = 0,
	UsbUserNotSupported = 1,
	UsbUserInvalidRequestCode = 2,
	UsbUserFeatureDisabled = 3,
	UsbUserInvalidHeaderParameter = 4,
	UsbUserInvalidParameter = 5,
	UsbUserMiniportError = 6,
	UsbUserBufferTooSmall = 7,
	UsbUserErrorNotMapped = 8,
	UsbUserDeviceNotStarted = 9,
	UsbUserNoDeviceConnected = 10,
}


[AllowDuplicates]
public enum WDMUSB_POWER_STATE : int32
{
	WdmUsbPowerNotMapped = 0,
	WdmUsbPowerSystemUnspecified = 100,
	WdmUsbPowerSystemWorking = 101,
	WdmUsbPowerSystemSleeping1 = 102,
	WdmUsbPowerSystemSleeping2 = 103,
	WdmUsbPowerSystemSleeping3 = 104,
	WdmUsbPowerSystemHibernate = 105,
	WdmUsbPowerSystemShutdown = 106,
	WdmUsbPowerDeviceUnspecified = 200,
	WdmUsbPowerDeviceD0 = 201,
	WdmUsbPowerDeviceD1 = 202,
	WdmUsbPowerDeviceD2 = 203,
	WdmUsbPowerDeviceD3 = 204,
}


[AllowDuplicates]
public enum USBFN_EVENT : int32
{
	UsbfnEventMinimum = 0,
	UsbfnEventAttach = 1,
	UsbfnEventReset = 2,
	UsbfnEventDetach = 3,
	UsbfnEventSuspend = 4,
	UsbfnEventResume = 5,
	UsbfnEventSetupPacket = 6,
	UsbfnEventConfigured = 7,
	UsbfnEventUnConfigured = 8,
	UsbfnEventPortType = 9,
	UsbfnEventBusTearDown = 10,
	UsbfnEventSetInterface = 11,
	UsbfnEventMaximum = 12,
}


[AllowDuplicates]
public enum USBFN_PORT_TYPE : int32
{
	UsbfnUnknownPort = 0,
	UsbfnStandardDownstreamPort = 1,
	UsbfnChargingDownstreamPort = 2,
	UsbfnDedicatedChargingPort = 3,
	UsbfnInvalidDedicatedChargingPort = 4,
	UsbfnProprietaryDedicatedChargingPort = 5,
	UsbfnPortTypeMaximum = 6,
}


[AllowDuplicates]
public enum USBFN_BUS_SPEED : int32
{
	UsbfnBusSpeedLow = 0,
	UsbfnBusSpeedFull = 1,
	UsbfnBusSpeedHigh = 2,
	UsbfnBusSpeedSuper = 3,
	UsbfnBusSpeedMaximum = 4,
}


[AllowDuplicates]
public enum USBFN_DIRECTION : int32
{
	UsbfnDirectionMinimum = 0,
	UsbfnDirectionIn = 1,
	UsbfnDirectionOut = 2,
	UsbfnDirectionTx = 1,
	UsbfnDirectionRx = 2,
	UsbfnDirectionMaximum = 3,
}


[AllowDuplicates]
public enum USBFN_DEVICE_STATE : int32
{
	UsbfnDeviceStateMinimum = 0,
	UsbfnDeviceStateAttached = 1,
	UsbfnDeviceStateDefault = 2,
	UsbfnDeviceStateDetached = 3,
	UsbfnDeviceStateAddressed = 4,
	UsbfnDeviceStateConfigured = 5,
	UsbfnDeviceStateSuspended = 6,
	UsbfnDeviceStateStateMaximum = 7,
}


[AllowDuplicates]
public enum PIPE_TYPE : int32
{
	EVENT_PIPE = 0,
	READ_DATA_PIPE = 1,
	WRITE_DATA_PIPE = 2,
	ALL_PIPE = 3,
}


[AllowDuplicates]
public enum RAW_PIPE_TYPE : int32
{
	USBSCAN_PIPE_CONTROL = 0,
	USBSCAN_PIPE_ISOCHRONOUS = 1,
	USBSCAN_PIPE_BULK = 2,
	USBSCAN_PIPE_INTERRUPT = 3,
}

#endregion

#region Function Pointers
public function void USB_IDLE_CALLBACK(void* Context);

#endregion

#region Structs
[CRepr, Union]
public struct BM_REQUEST_TYPE
{
	[CRepr]
	public struct _BM
	{
		public uint8 _bitfield;
	}
	public _BM s;
	public uint8 B;
}

[CRepr, Packed(1)]
public struct USB_DEFAULT_PIPE_SETUP_PACKET
{
	[CRepr, Union, Packed(1)]
	public struct _wIndex
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 LowByte;
			public uint8 HiByte;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint16 W;
	}
	[CRepr, Union, Packed(1)]
	public struct _wValue
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 LowByte;
			public uint8 HiByte;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint16 W;
	}
	public BM_REQUEST_TYPE bmRequestType;
	public uint8 bRequest;
	public _wValue wValue;
	public _wIndex wIndex;
	public uint16 wLength;
}

[CRepr, Union, Packed(1)]
public struct USB_DEVICE_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_INTERFACE_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_ENDPOINT_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct USB_COMMON_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint16 bcdUSB;
	public uint8 bDeviceClass;
	public uint8 bDeviceSubClass;
	public uint8 bDeviceProtocol;
	public uint8 bMaxPacketSize0;
	public uint16 idVendor;
	public uint16 idProduct;
	public uint16 bcdDevice;
	public uint8 iManufacturer;
	public uint8 iProduct;
	public uint8 iSerialNumber;
	public uint8 bNumConfigurations;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_QUALIFIER_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint16 bcdUSB;
	public uint8 bDeviceClass;
	public uint8 bDeviceSubClass;
	public uint8 bDeviceProtocol;
	public uint8 bMaxPacketSize0;
	public uint8 bNumConfigurations;
	public uint8 bReserved;
}

[CRepr, Packed(1)]
public struct USB_BOS_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint16 wTotalLength;
	public uint8 bNumDeviceCaps;
}

[CRepr]
public struct USB_DEVICE_CAPABILITY_USB20_EXTENSION_DESCRIPTOR
{
	[CRepr, Union, Packed(1)]
	public struct _bmAttributes_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 AsUlong;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public _bmAttributes_e__Union bmAttributes;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_CAPABILITY_POWER_DELIVERY_DESCRIPTOR
{
	[CRepr, Union, Packed(1)]
	public struct _bmAttributes_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 AsUlong;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bReserved;
	public _bmAttributes_e__Union bmAttributes;
	public uint16 bmProviderPorts;
	public uint16 bmConsumerPorts;
	public uint16 bcdBCVersion;
	public uint16 bcdPDVersion;
	public uint16 bcdUSBTypeCVersion;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_CAPABILITY_PD_CONSUMER_PORT_DESCRIPTOR
{
	[CRepr, Union, Packed(1)]
	public struct _bmCapabilities_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 AsUshort;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bReserved;
	public _bmCapabilities_e__Union bmCapabilities;
	public uint16 wMinVoltage;
	public uint16 wMaxVoltage;
	public uint16 wReserved;
	public uint32 dwMaxOperatingPower;
	public uint32 dwMaxPeakPower;
	public uint32 dwMaxPeakPowerTime;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_CAPABILITY_SUPERSPEED_USB_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bmAttributes;
	public uint16 wSpeedsSupported;
	public uint8 bFunctionalitySupport;
	public uint8 bU1DevExitLat;
	public uint16 wU2DevExitLat;
}

[CRepr, Union, Packed(1)]
public struct USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 AsUlong32;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_USB_DESCRIPTOR
{
	[CRepr, Union, Packed(1)]
	public struct _wFunctionalitySupport_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 AsUshort;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union, Packed(1)]
	public struct _bmAttributes_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 AsUlong;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bReserved;
	public _bmAttributes_e__Union bmAttributes;
	public _wFunctionalitySupport_e__Union wFunctionalitySupport;
	public uint16 wReserved;
	public USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED* bmSublinkSpeedAttr mut => &bmSublinkSpeedAttr_impl;
	private USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED[ANYSIZE_ARRAY] bmSublinkSpeedAttr_impl;
}

[CRepr]
public struct USB_DEVICE_CAPABILITY_CONTAINER_ID_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bReserved;
	public uint8[16] ContainerID;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_CAPABILITY_PLATFORM_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bReserved;
	public Guid PlatformCapabilityUuid;
	public uint8* CapabililityData mut => &CapabililityData_impl;
	private uint8[ANYSIZE_ARRAY] CapabililityData_impl;
}

[CRepr, Packed(1)]
public struct USB_DEVICE_CAPABILITY_BILLBOARD_DESCRIPTOR
{
	[CRepr, Union, Packed(1)]
	public struct _VconnPower_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 AsUshort;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 wSVID;
		public uint8 bAlternateMode;
		public uint8 iAlternateModeSetting;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 iAddtionalInfoURL;
	public uint8 bNumberOfAlternateModes;
	public uint8 bPreferredAlternateMode;
	public _VconnPower_e__Union VconnPower;
	public uint8[32] bmConfigured;
	public uint32 bReserved;
	public _Anonymous_e__Struct* AlternateMode mut => &AlternateMode_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] AlternateMode_impl;
}

[CRepr]
public struct USB_DEVICE_CAPABILITY_FIRMWARE_STATUS_DESCRIPTOR
{
	[CRepr, Union, Packed(1)]
	public struct _bmAttributes_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 AsUlong;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
	public uint8 bcdDescriptorVersion;
	public _bmAttributes_e__Union bmAttributes;
}

[CRepr]
public struct USB_DEVICE_CAPABILITY_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bDevCapabilityType;
}

[CRepr, Packed(1)]
public struct USB_CONFIGURATION_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint16 wTotalLength;
	public uint8 bNumInterfaces;
	public uint8 bConfigurationValue;
	public uint8 iConfiguration;
	public uint8 bmAttributes;
	public uint8 MaxPower;
}

[CRepr]
public struct USB_INTERFACE_ASSOCIATION_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bFirstInterface;
	public uint8 bInterfaceCount;
	public uint8 bFunctionClass;
	public uint8 bFunctionSubClass;
	public uint8 bFunctionProtocol;
	public uint8 iFunction;
}

[CRepr]
public struct USB_INTERFACE_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bInterfaceNumber;
	public uint8 bAlternateSetting;
	public uint8 bNumEndpoints;
	public uint8 bInterfaceClass;
	public uint8 bInterfaceSubClass;
	public uint8 bInterfaceProtocol;
	public uint8 iInterface;
}

[CRepr, Packed(1)]
public struct USB_ENDPOINT_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bEndpointAddress;
	public uint8 bmAttributes;
	public uint16 wMaxPacketSize;
	public uint8 bInterval;
}

[CRepr, Union, Packed(1)]
public struct USB_HIGH_SPEED_MAXPACKET
{
	[CRepr, Packed(1)]
	public struct _MP
	{
		public uint16 _bitfield;
	}
	public uint16 us;
}

[CRepr, Packed(1)]
public struct USB_STRING_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public char16* bString mut => &bString_impl;
	private char16[ANYSIZE_ARRAY] bString_impl;
}

[CRepr, Packed(1)]
public struct USB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR
{
	[CRepr, Union]
	public struct _bmAttributes_e__Union
	{
		[CRepr]
		public struct _Bulk_e__Struct
		{
			public uint8 _bitfield;
		}
		[CRepr]
		public struct _Isochronous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 AsUchar;
		public _Bulk_e__Struct Bulk;
		public _Isochronous_e__Struct Isochronous;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bMaxBurst;
	public _bmAttributes_e__Union bmAttributes;
	public uint16 wBytesPerInterval;
}

[CRepr, Packed(1)]
public struct USB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint16 wReserved;
	public uint32 dwBytesPerInterval;
}

[CRepr, Packed(1)]
public struct USB_HUB_DESCRIPTOR
{
	public uint8 bDescriptorLength;
	public uint8 bDescriptorType;
	public uint8 bNumberOfPorts;
	public uint16 wHubCharacteristics;
	public uint8 bPowerOnToPowerGood;
	public uint8 bHubControlCurrent;
	public uint8[64] bRemoveAndPowerMask;
}

[CRepr, Packed(1)]
public struct USB_30_HUB_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bNumberOfPorts;
	public uint16 wHubCharacteristics;
	public uint8 bPowerOnToPowerGood;
	public uint8 bHubControlCurrent;
	public uint8 bHubHdrDecLat;
	public uint16 wHubDelay;
	public uint16 DeviceRemovable;
}

[CRepr, Union, Packed(1)]
public struct USB_HUB_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_HUB_CHANGE
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_HUB_STATUS_AND_CHANGE
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public USB_HUB_STATUS HubStatus;
		public USB_HUB_CHANGE HubChange;
	}
	public uint32 AsUlong32;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_20_PORT_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_20_PORT_CHANGE
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_30_PORT_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_30_PORT_CHANGE
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 AsUshort16;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_PORT_STATUS
{
	public uint16 AsUshort16;
	public USB_20_PORT_STATUS Usb20PortStatus;
	public USB_30_PORT_STATUS Usb30PortStatus;
}

[CRepr, Union, Packed(1)]
public struct USB_PORT_CHANGE
{
	public uint16 AsUshort16;
	public USB_20_PORT_CHANGE Usb20PortChange;
	public USB_30_PORT_CHANGE Usb30PortChange;
}

[CRepr, Union, Packed(1)]
public struct USB_PORT_EXT_STATUS
{
	[CRepr, Packed(1)]
	public struct _Anonymous_e__Struct
	{
		public uint32 _bitfield;
	}
	public uint32 AsUlong32;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_PORT_STATUS_AND_CHANGE
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public USB_PORT_STATUS PortStatus;
		public USB_PORT_CHANGE PortChange;
	}
	public uint32 AsUlong32;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union, Packed(1)]
public struct USB_PORT_EXT_STATUS_AND_CHANGE
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public USB_PORT_STATUS_AND_CHANGE PortStatusChange;
		public USB_PORT_EXT_STATUS PortExtStatus;
	}
	public uint64 AsUlong64;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union]
public struct USB_HUB_30_PORT_REMOTE_WAKE_MASK
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint8 _bitfield;
	}
	public uint8 AsUchar8;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union]
public struct USB_FUNCTION_SUSPEND_OPTIONS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint8 _bitfield;
	}
	public uint8 AsUchar;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Packed(1)]
public struct USB_CONFIGURATION_POWER_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8[3] SelfPowerConsumedD0;
	public uint8 bPowerSummaryId;
	public uint8 bBusPowerSavingD1;
	public uint8 bSelfPowerSavingD1;
	public uint8 bBusPowerSavingD2;
	public uint8 bSelfPowerSavingD2;
	public uint8 bBusPowerSavingD3;
	public uint8 bSelfPowerSavingD3;
	public uint16 TransitionTimeFromD1;
	public uint16 TransitionTimeFromD2;
	public uint16 TransitionTimeFromD3;
}

[CRepr, Packed(1)]
public struct USB_INTERFACE_POWER_DESCRIPTOR
{
	public uint8 bLength;
	public uint8 bDescriptorType;
	public uint8 bmCapabilitiesFlags;
	public uint8 bBusPowerSavingD1;
	public uint8 bSelfPowerSavingD1;
	public uint8 bBusPowerSavingD2;
	public uint8 bSelfPowerSavingD2;
	public uint8 bBusPowerSavingD3;
	public uint8 bSelfPowerSavingD3;
	public uint16 TransitionTimeFromD1;
	public uint16 TransitionTimeFromD2;
	public uint16 TransitionTimeFromD3;
}

[CRepr]
public struct USBD_VERSION_INFORMATION
{
	public uint32 USBDI_Version;
	public uint32 Supported_USB_Version;
}

[CRepr]
public struct USBD_DEVICE_INFORMATION
{
	public uint32 OffsetNext;
	public void* UsbdDeviceHandle;
	public USB_DEVICE_DESCRIPTOR DeviceDescriptor;
}

[CRepr]
public struct USBD_PIPE_INFORMATION
{
	public uint16 MaximumPacketSize;
	public uint8 EndpointAddress;
	public uint8 Interval;
	public USBD_PIPE_TYPE PipeType;
	public void* PipeHandle;
	public uint32 MaximumTransferSize;
	public uint32 PipeFlags;
}

[CRepr, Packed(1)]
public struct USBD_ENDPOINT_OFFLOAD_INFORMATION
{
	public uint32 Size;
	public uint16 EndpointAddress;
	public uint32 ResourceId;
	public USBD_ENDPOINT_OFFLOAD_MODE Mode;
	public uint32 _bitfield1;
	public uint32 _bitfield2;
	public LARGE_INTEGER TransferSegmentLA;
	public void* TransferSegmentVA;
	public uint TransferRingSize;
	public uint32 TransferRingInitialCycleBit;
	public uint32 MessageNumber;
	public LARGE_INTEGER EventRingSegmentLA;
	public void* EventRingSegmentVA;
	public uint EventRingSize;
	public uint32 EventRingInitialCycleBit;
}

[CRepr]
public struct USBD_INTERFACE_INFORMATION
{
	public uint16 Length;
	public uint8 InterfaceNumber;
	public uint8 AlternateSetting;
	public uint8 Class;
	public uint8 SubClass;
	public uint8 Protocol;
	public uint8 Reserved;
	public void* InterfaceHandle;
	public uint32 NumberOfPipes;
	public USBD_PIPE_INFORMATION* Pipes mut => &Pipes_impl;
	private USBD_PIPE_INFORMATION[ANYSIZE_ARRAY] Pipes_impl;
}

[CRepr]
public struct _URB_HCD_AREA
{
	public void*[8] Reserved8;
}

[CRepr]
public struct _URB_HEADER
{
	public uint16 Length;
	public uint16 Function;
	public int32 Status;
	public void* UsbdDeviceHandle;
	public uint32 UsbdFlags;
}

[CRepr]
public struct _URB_SELECT_INTERFACE
{
	public _URB_HEADER Hdr;
	public void* ConfigurationHandle;
	public USBD_INTERFACE_INFORMATION Interface;
}

[CRepr]
public struct _URB_SELECT_CONFIGURATION
{
	public _URB_HEADER Hdr;
	public USB_CONFIGURATION_DESCRIPTOR* ConfigurationDescriptor;
	public void* ConfigurationHandle;
	public USBD_INTERFACE_INFORMATION Interface;
}

[CRepr]
public struct _URB_PIPE_REQUEST
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 Reserved;
}

[CRepr]
public struct _URB_FRAME_LENGTH_CONTROL
{
	public _URB_HEADER Hdr;
}

[CRepr]
public struct _URB_GET_FRAME_LENGTH
{
	public _URB_HEADER Hdr;
	public uint32 FrameLength;
	public uint32 FrameNumber;
}

[CRepr]
public struct _URB_SET_FRAME_LENGTH
{
	public _URB_HEADER Hdr;
	public int32 FrameLengthDelta;
}

[CRepr]
public struct _URB_GET_CURRENT_FRAME_NUMBER
{
	public _URB_HEADER Hdr;
	public uint32 FrameNumber;
}

[CRepr]
public struct _URB_CONTROL_DESCRIPTOR_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 Reserved0;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint16 Reserved1;
	public uint8 Index;
	public uint8 DescriptorType;
	public uint16 LanguageId;
	public uint16 Reserved2;
}

[CRepr]
public struct _URB_CONTROL_GET_STATUS_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 Reserved0;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint8[4] Reserved1;
	public uint16 Index;
	public uint16 Reserved2;
}

[CRepr]
public struct _URB_CONTROL_FEATURE_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 Reserved2;
	public uint32 Reserved3;
	public void* Reserved4;
	public void* Reserved5;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint16 Reserved0;
	public uint16 FeatureSelector;
	public uint16 Index;
	public uint16 Reserved1;
}

[CRepr]
public struct _URB_CONTROL_VENDOR_OR_CLASS_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 TransferFlags;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint8 RequestTypeReservedBits;
	public uint8 Request;
	public uint16 Value;
	public uint16 Index;
	public uint16 Reserved1;
}

[CRepr]
public struct _URB_CONTROL_GET_INTERFACE_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 Reserved0;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint8[4] Reserved1;
	public uint16 Interface;
	public uint16 Reserved2;
}

[CRepr]
public struct _URB_CONTROL_GET_CONFIGURATION_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 Reserved0;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint8[8] Reserved1;
}

[CRepr]
public struct OS_STRING
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint8 bPad;
		public uint8 bFlags;
	}
	public uint8 bLength;
	public uint8 bDescriptorType;
	public char16[7] MicrosoftString;
	public uint8 bVendorCode;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct _URB_OS_FEATURE_DESCRIPTOR_REQUEST
{
	public _URB_HEADER Hdr;
	public void* Reserved;
	public uint32 Reserved0;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint8 _bitfield;
	public uint8 Reserved2;
	public uint8 InterfaceNumber;
	public uint8 MS_PageIndex;
	public uint16 MS_FeatureDescriptorIndex;
	public uint16 Reserved3;
}

[CRepr]
public struct _URB_CONTROL_TRANSFER
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 TransferFlags;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint8[8] SetupPacket;
}

[CRepr]
public struct _URB_CONTROL_TRANSFER_EX
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 TransferFlags;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public uint32 Timeout;
	public _URB_HCD_AREA hca;
	public uint8[8] SetupPacket;
}

[CRepr]
public struct _URB_BULK_OR_INTERRUPT_TRANSFER
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 TransferFlags;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
}

[CRepr]
public struct USBD_ISO_PACKET_DESCRIPTOR
{
	public uint32 Offset;
	public uint32 Length;
	public int32 Status;
}

[CRepr]
public struct _URB_ISOCH_TRANSFER
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 TransferFlags;
	public uint32 TransferBufferLength;
	public void* TransferBuffer;
	public void* TransferBufferMDL;
	public URB* UrbLink;
	public _URB_HCD_AREA hca;
	public uint32 StartFrame;
	public uint32 NumberOfPackets;
	public uint32 ErrorCount;
	public USBD_ISO_PACKET_DESCRIPTOR* IsoPacket mut => &IsoPacket_impl;
	private USBD_ISO_PACKET_DESCRIPTOR[ANYSIZE_ARRAY] IsoPacket_impl;
}

[CRepr]
public struct USBD_STREAM_INFORMATION
{
	public void* PipeHandle;
	public uint32 StreamID;
	public uint32 MaximumTransferSize;
	public uint32 PipeFlags;
}

[CRepr]
public struct _URB_OPEN_STATIC_STREAMS
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 NumberOfStreams;
	public uint16 StreamInfoVersion;
	public uint16 StreamInfoSize;
	public USBD_STREAM_INFORMATION* Streams;
}

[CRepr]
public struct _URB_GET_ISOCH_PIPE_TRANSFER_PATH_DELAYS
{
	public _URB_HEADER Hdr;
	public void* PipeHandle;
	public uint32 MaximumSendPathDelayInMilliSeconds;
	public uint32 MaximumCompletionPathDelayInMilliSeconds;
}

[CRepr]
public struct URB
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public _URB_HEADER UrbHeader;
		public _URB_SELECT_INTERFACE UrbSelectInterface;
		public _URB_SELECT_CONFIGURATION UrbSelectConfiguration;
		public _URB_PIPE_REQUEST UrbPipeRequest;
		public _URB_FRAME_LENGTH_CONTROL UrbFrameLengthControl;
		public _URB_GET_FRAME_LENGTH UrbGetFrameLength;
		public _URB_SET_FRAME_LENGTH UrbSetFrameLength;
		public _URB_GET_CURRENT_FRAME_NUMBER UrbGetCurrentFrameNumber;
		public _URB_CONTROL_TRANSFER UrbControlTransfer;
		public _URB_CONTROL_TRANSFER_EX UrbControlTransferEx;
		public _URB_BULK_OR_INTERRUPT_TRANSFER UrbBulkOrInterruptTransfer;
		public _URB_ISOCH_TRANSFER UrbIsochronousTransfer;
		public _URB_CONTROL_DESCRIPTOR_REQUEST UrbControlDescriptorRequest;
		public _URB_CONTROL_GET_STATUS_REQUEST UrbControlGetStatusRequest;
		public _URB_CONTROL_FEATURE_REQUEST UrbControlFeatureRequest;
		public _URB_CONTROL_VENDOR_OR_CLASS_REQUEST UrbControlVendorClassRequest;
		public _URB_CONTROL_GET_INTERFACE_REQUEST UrbControlGetInterfaceRequest;
		public _URB_CONTROL_GET_CONFIGURATION_REQUEST UrbControlGetConfigurationRequest;
		public _URB_OS_FEATURE_DESCRIPTOR_REQUEST UrbOSFeatureDescriptorRequest;
		public _URB_OPEN_STATIC_STREAMS UrbOpenStaticStreams;
		public _URB_GET_ISOCH_PIPE_TRANSFER_PATH_DELAYS UrbGetIsochPipeTransferPathDelays;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct USB_IDLE_CALLBACK_INFO
{
	public USB_IDLE_CALLBACK IdleCallback;
	public void* IdleContext;
}

[CRepr, Packed(1)]
public struct USBUSER_REQUEST_HEADER
{
	public uint32 UsbUserRequest;
	public USB_USER_ERROR_CODE UsbUserStatusCode;
	public uint32 RequestBufferLength;
	public uint32 ActualBufferLength;
}

[CRepr, Packed(1)]
public struct PACKET_PARAMETERS
{
	public uint8 DeviceAddress;
	public uint8 EndpointAddress;
	public uint16 MaximumPacketSize;
	public uint32 Timeout;
	public uint32 Flags;
	public uint32 DataLength;
	public uint16 HubDeviceAddress;
	public uint16 PortTTNumber;
	public uint8 ErrorCount;
	public uint8[3] Pad;
	public int32 UsbdStatusCode;
	public uint8[4] Data;
}

[CRepr, Packed(1)]
public struct USBUSER_SEND_ONE_PACKET
{
	public USBUSER_REQUEST_HEADER Header;
	public PACKET_PARAMETERS PacketParameters;
}

[CRepr, Packed(1)]
public struct RAW_RESET_PORT_PARAMETERS
{
	public uint16 PortNumber;
	public uint16 PortStatus;
}

[CRepr, Packed(1)]
public struct USBUSER_RAW_RESET_ROOT_PORT
{
	public USBUSER_REQUEST_HEADER Header;
	public RAW_RESET_PORT_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct RAW_ROOTPORT_FEATURE
{
	public uint16 PortNumber;
	public uint16 PortFeature;
	public uint16 PortStatus;
}

[CRepr, Packed(1)]
public struct USBUSER_ROOTPORT_FEATURE_REQUEST
{
	public USBUSER_REQUEST_HEADER Header;
	public RAW_ROOTPORT_FEATURE Parameters;
}

[CRepr, Packed(1)]
public struct RAW_ROOTPORT_PARAMETERS
{
	public uint16 PortNumber;
	public uint16 PortStatus;
}

[CRepr, Packed(1)]
public struct USBUSER_ROOTPORT_PARAMETERS
{
	public USBUSER_REQUEST_HEADER Header;
	public RAW_ROOTPORT_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct USB_CONTROLLER_INFO_0
{
	public uint32 PciVendorId;
	public uint32 PciDeviceId;
	public uint32 PciRevision;
	public uint32 NumberOfRootPorts;
	public USB_CONTROLLER_FLAVOR ControllerFlavor;
	public uint32 HcFeatureFlags;
}

[CRepr, Packed(1)]
public struct USBUSER_CONTROLLER_INFO_0
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_CONTROLLER_INFO_0 Info0;
}

[CRepr, Packed(1)]
public struct USB_UNICODE_NAME
{
	public uint32 Length;
	public char16* String mut => &String_impl;
	private char16[ANYSIZE_ARRAY] String_impl;
}

[CRepr, Packed(1)]
public struct USBUSER_CONTROLLER_UNICODE_NAME
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_UNICODE_NAME UnicodeName;
}

[CRepr, Packed(1)]
public struct USB_PASS_THRU_PARAMETERS
{
	public Guid FunctionGUID;
	public uint32 ParameterLength;
	public uint8[4] Parameters;
}

[CRepr, Packed(1)]
public struct USBUSER_PASS_THRU_REQUEST
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_PASS_THRU_PARAMETERS PassThru;
}

[CRepr, Packed(1)]
public struct USB_POWER_INFO
{
	public WDMUSB_POWER_STATE SystemState;
	public WDMUSB_POWER_STATE HcDevicePowerState;
	public WDMUSB_POWER_STATE HcDeviceWake;
	public WDMUSB_POWER_STATE HcSystemWake;
	public WDMUSB_POWER_STATE RhDevicePowerState;
	public WDMUSB_POWER_STATE RhDeviceWake;
	public WDMUSB_POWER_STATE RhSystemWake;
	public WDMUSB_POWER_STATE LastSystemSleepState;
	public BOOLEAN CanWakeup;
	public BOOLEAN IsPowered;
}

[CRepr, Packed(1)]
public struct USBUSER_POWER_INFO_REQUEST
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_POWER_INFO PowerInformation;
}

[CRepr, Packed(1)]
public struct USB_OPEN_RAW_DEVICE_PARAMETERS
{
	public uint16 PortStatus;
	public uint16 MaxPacketEp0;
}

[CRepr, Packed(1)]
public struct USBUSER_OPEN_RAW_DEVICE
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_OPEN_RAW_DEVICE_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct USB_CLOSE_RAW_DEVICE_PARAMETERS
{
	public uint32 xxx;
}

[CRepr, Packed(1)]
public struct USBUSER_CLOSE_RAW_DEVICE
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_CLOSE_RAW_DEVICE_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct USB_SEND_RAW_COMMAND_PARAMETERS
{
	public uint8 Usb_bmRequest;
	public uint8 Usb_bRequest;
	public uint16 Usb_wVlaue;
	public uint16 Usb_wIndex;
	public uint16 Usb_wLength;
	public uint16 DeviceAddress;
	public uint16 MaximumPacketSize;
	public uint32 Timeout;
	public uint32 DataLength;
	public int32 UsbdStatusCode;
	public uint8[4] Data;
}

[CRepr, Packed(1)]
public struct USBUSER_SEND_RAW_COMMAND
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_SEND_RAW_COMMAND_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct USB_BANDWIDTH_INFO
{
	public uint32 DeviceCount;
	public uint32 TotalBusBandwidth;
	public uint32 Total32secBandwidth;
	public uint32 AllocedBulkAndControl;
	public uint32 AllocedIso;
	public uint32 AllocedInterrupt_1ms;
	public uint32 AllocedInterrupt_2ms;
	public uint32 AllocedInterrupt_4ms;
	public uint32 AllocedInterrupt_8ms;
	public uint32 AllocedInterrupt_16ms;
	public uint32 AllocedInterrupt_32ms;
}

[CRepr, Packed(1)]
public struct USBUSER_BANDWIDTH_INFO_REQUEST
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_BANDWIDTH_INFO BandwidthInformation;
}

[CRepr, Packed(1)]
public struct USB_BUS_STATISTICS_0
{
	public uint32 DeviceCount;
	public LARGE_INTEGER CurrentSystemTime;
	public uint32 CurrentUsbFrame;
	public uint32 BulkBytes;
	public uint32 IsoBytes;
	public uint32 InterruptBytes;
	public uint32 ControlDataBytes;
	public uint32 PciInterruptCount;
	public uint32 HardResetCount;
	public uint32 WorkerSignalCount;
	public uint32 CommonBufferBytes;
	public uint32 WorkerIdleTimeMs;
	public BOOLEAN RootHubEnabled;
	public uint8 RootHubDevicePowerState;
	public uint8 Unused;
	public uint8 NameIndex;
}

[CRepr, Packed(1)]
public struct USBUSER_BUS_STATISTICS_0_REQUEST
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_BUS_STATISTICS_0 BusStatistics0;
}

[CRepr, Packed(1)]
public struct USB_DRIVER_VERSION_PARAMETERS
{
	public uint32 DriverTrackingCode;
	public uint32 USBDI_Version;
	public uint32 USBUSER_Version;
	public BOOLEAN CheckedPortDriver;
	public BOOLEAN CheckedMiniportDriver;
	public uint16 USB_Version;
}

[CRepr, Packed(1)]
public struct USBUSER_GET_DRIVER_VERSION
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_DRIVER_VERSION_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct USB_USB2HW_VERSION_PARAMETERS
{
	public uint8 Usb2HwRevision;
}

[CRepr, Packed(1)]
public struct USBUSER_GET_USB2HW_VERSION
{
	public USBUSER_REQUEST_HEADER Header;
	public USB_USB2HW_VERSION_PARAMETERS Parameters;
}

[CRepr, Packed(1)]
public struct USBUSER_REFRESH_HCT_REG
{
	public USBUSER_REQUEST_HEADER Header;
	public uint32 Flags;
}

[CRepr]
public struct WINUSB_PIPE_INFORMATION
{
	public USBD_PIPE_TYPE PipeType;
	public uint8 PipeId;
	public uint16 MaximumPacketSize;
	public uint8 Interval;
}

[CRepr]
public struct WINUSB_PIPE_INFORMATION_EX
{
	public USBD_PIPE_TYPE PipeType;
	public uint8 PipeId;
	public uint16 MaximumPacketSize;
	public uint8 Interval;
	public uint32 MaximumBytesPerInterval;
}

[CRepr, Packed(1)]
public struct WINUSB_SETUP_PACKET
{
	public uint8 RequestType;
	public uint8 Request;
	public uint16 Value;
	public uint16 Index;
	public uint16 Length;
}

[CRepr, Packed(1)]
public struct USB_START_TRACKING_FOR_TIME_SYNC_INFORMATION
{
	public HANDLE TimeTrackingHandle;
	public BOOLEAN IsStartupDelayTolerable;
}

[CRepr, Packed(1)]
public struct USB_STOP_TRACKING_FOR_TIME_SYNC_INFORMATION
{
	public HANDLE TimeTrackingHandle;
}

[CRepr, Packed(1)]
public struct USB_FRAME_NUMBER_AND_QPC_FOR_TIME_SYNC_INFORMATION
{
	public HANDLE TimeTrackingHandle;
	public uint32 InputFrameNumber;
	public uint32 InputMicroFrameNumber;
	public LARGE_INTEGER QueryPerformanceCounterAtInputFrameOrMicroFrame;
	public LARGE_INTEGER QueryPerformanceCounterFrequency;
	public uint32 PredictedAccuracyInMicroSeconds;
	public uint32 CurrentGenerationID;
	public LARGE_INTEGER CurrentQueryPerformanceCounter;
	public uint32 CurrentHardwareFrameNumber;
	public uint32 CurrentHardwareMicroFrameNumber;
	public uint32 CurrentUSBFrameNumber;
}

[CRepr]
public struct ALTERNATE_INTERFACE
{
	public uint16 InterfaceNumber;
	public uint16 AlternateInterfaceNumber;
}

[CRepr]
public struct USBFN_NOTIFICATION
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public USBFN_BUS_SPEED BusSpeed;
		public USB_DEFAULT_PIPE_SETUP_PACKET SetupPacket;
		public uint16 ConfigurationValue;
		public USBFN_PORT_TYPE PortType;
		public ALTERNATE_INTERFACE AlternateInterface;
	}
	public USBFN_EVENT Event;
	public _u_e__Union u;
}

[CRepr]
public struct USBFN_PIPE_INFORMATION
{
	public USB_ENDPOINT_DESCRIPTOR EpDesc;
	public uint32 PipeId;
}

[CRepr]
public struct USBFN_CLASS_INTERFACE
{
	public uint8 InterfaceNumber;
	public uint8 PipeCount;
	public USBFN_PIPE_INFORMATION[16] PipeArr;
}

[CRepr]
public struct USBFN_CLASS_INFORMATION_PACKET
{
	public USBFN_CLASS_INTERFACE FullSpeedClassInterface;
	public USBFN_CLASS_INTERFACE HighSpeedClassInterface;
	public char16[40] InterfaceName;
	public char16[39] InterfaceGuid;
	public BOOLEAN HasInterfaceGuid;
	public USBFN_CLASS_INTERFACE SuperSpeedClassInterface;
}

[CRepr]
public struct USBFN_CLASS_INTERFACE_EX
{
	public uint8 BaseInterfaceNumber;
	public uint8 InterfaceCount;
	public uint8 PipeCount;
	public USBFN_PIPE_INFORMATION[16] PipeArr;
}

[CRepr]
public struct USBFN_CLASS_INFORMATION_PACKET_EX
{
	public USBFN_CLASS_INTERFACE_EX FullSpeedClassInterfaceEx;
	public USBFN_CLASS_INTERFACE_EX HighSpeedClassInterfaceEx;
	public USBFN_CLASS_INTERFACE_EX SuperSpeedClassInterfaceEx;
	public char16[40] InterfaceName;
	public char16[39] InterfaceGuid;
	public BOOLEAN HasInterfaceGuid;
}

[CRepr]
public struct USBFN_INTERFACE_INFO
{
	public uint8 InterfaceNumber;
	public USBFN_BUS_SPEED Speed;
	public uint16 Size;
	public uint8* InterfaceDescriptorSet mut => &InterfaceDescriptorSet_impl;
	private uint8[ANYSIZE_ARRAY] InterfaceDescriptorSet_impl;
}

[CRepr]
public struct USBFN_USB_STRING
{
	public uint8 StringIndex;
	public char16[255] UsbString;
}

[CRepr]
public struct USBFN_BUS_CONFIGURATION_INFO
{
	public char16[40] ConfigurationName;
	public BOOLEAN IsCurrent;
	public BOOLEAN IsActive;
}

[CRepr]
public struct DRV_VERSION
{
	public uint32 major;
	public uint32 minor;
	public uint32 @internal;
}

[CRepr]
public struct IO_BLOCK
{
	public uint32 uOffset;
	public uint32 uLength;
	public uint8* pbyData;
	public uint32 uIndex;
}

[CRepr]
public struct IO_BLOCK_EX
{
	public uint32 uOffset;
	public uint32 uLength;
	public uint8* pbyData;
	public uint32 uIndex;
	public uint8 bRequest;
	public uint8 bmRequestType;
	public uint8 fTransferDirectionIn;
}

[CRepr]
public struct CHANNEL_INFO
{
	public uint32 EventChannelSize;
	public uint32 uReadDataAlignment;
	public uint32 uWriteDataAlignment;
}

[CRepr]
public struct USBSCAN_GET_DESCRIPTOR
{
	public uint8 DescriptorType;
	public uint8 Index;
	public uint16 LanguageId;
}

[CRepr]
public struct DEVICE_DESCRIPTOR
{
	public uint16 usVendorId;
	public uint16 usProductId;
	public uint16 usBcdDevice;
	public uint16 usLanguageId;
}

[CRepr]
public struct USBSCAN_PIPE_INFORMATION
{
	public uint16 MaximumPacketSize;
	public uint8 EndpointAddress;
	public uint8 Interval;
	public RAW_PIPE_TYPE PipeType;
}

[CRepr]
public struct USBSCAN_PIPE_CONFIGURATION
{
	public uint32 NumberOfPipes;
	public USBSCAN_PIPE_INFORMATION[8] PipeInfo;
}

[CRepr]
public struct USBSCAN_TIMEOUT
{
	public uint32 TimeoutRead;
	public uint32 TimeoutWrite;
	public uint32 TimeoutEvent;
}

#endregion

#region Functions
public static
{
	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_Initialize(HANDLE DeviceHandle, void** InterfaceHandle);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_Free(void* InterfaceHandle);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetAssociatedInterface(void* InterfaceHandle, uint8 AssociatedInterfaceIndex, void** AssociatedInterfaceHandle);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetDescriptor(void* InterfaceHandle, uint8 DescriptorType, uint8 Index, uint16 LanguageID, uint8* Buffer, uint32 BufferLength, uint32* LengthTransferred);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_QueryInterfaceSettings(void* InterfaceHandle, uint8 AlternateInterfaceNumber, USB_INTERFACE_DESCRIPTOR* UsbAltInterfaceDescriptor);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_QueryDeviceInformation(void* InterfaceHandle, uint32 InformationType, uint32* BufferLength, void* Buffer);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_SetCurrentAlternateSetting(void* InterfaceHandle, uint8 SettingNumber);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetCurrentAlternateSetting(void* InterfaceHandle, uint8* SettingNumber);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_QueryPipe(void* InterfaceHandle, uint8 AlternateInterfaceNumber, uint8 PipeIndex, WINUSB_PIPE_INFORMATION* PipeInformation);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_QueryPipeEx(void* InterfaceHandle, uint8 AlternateSettingNumber, uint8 PipeIndex, WINUSB_PIPE_INFORMATION_EX* PipeInformationEx);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_SetPipePolicy(void* InterfaceHandle, uint8 PipeID, uint32 PolicyType, uint32 ValueLength, void* Value);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetPipePolicy(void* InterfaceHandle, uint8 PipeID, uint32 PolicyType, uint32* ValueLength, void* Value);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_ReadPipe(void* InterfaceHandle, uint8 PipeID, uint8* Buffer, uint32 BufferLength, uint32* LengthTransferred, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_WritePipe(void* InterfaceHandle, uint8 PipeID, uint8* Buffer, uint32 BufferLength, uint32* LengthTransferred, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_ControlTransfer(void* InterfaceHandle, WINUSB_SETUP_PACKET SetupPacket, uint8* Buffer, uint32 BufferLength, uint32* LengthTransferred, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_ResetPipe(void* InterfaceHandle, uint8 PipeID);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_AbortPipe(void* InterfaceHandle, uint8 PipeID);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_FlushPipe(void* InterfaceHandle, uint8 PipeID);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_SetPowerPolicy(void* InterfaceHandle, uint32 PolicyType, uint32 ValueLength, void* Value);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetPowerPolicy(void* InterfaceHandle, uint32 PolicyType, uint32* ValueLength, void* Value);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetOverlappedResult(void* InterfaceHandle, OVERLAPPED* lpOverlapped, uint32* lpNumberOfBytesTransferred, BOOL bWait);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USB_INTERFACE_DESCRIPTOR* WinUsb_ParseConfigurationDescriptor(USB_CONFIGURATION_DESCRIPTOR* ConfigurationDescriptor, void* StartPosition, int32 InterfaceNumber, int32 AlternateSetting, int32 InterfaceClass, int32 InterfaceSubClass, int32 InterfaceProtocol);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USB_COMMON_DESCRIPTOR* WinUsb_ParseDescriptors(void* DescriptorBuffer, uint32 TotalLength, void* StartPosition, int32 DescriptorType);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetCurrentFrameNumber(void* InterfaceHandle, uint32* CurrentFrameNumber, LARGE_INTEGER* TimeStamp);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetAdjustedFrameNumber(uint32* CurrentFrameNumber, LARGE_INTEGER TimeStamp);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_RegisterIsochBuffer(void* InterfaceHandle, uint8 PipeID, uint8* Buffer, uint32 BufferLength, void** IsochBufferHandle);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_UnregisterIsochBuffer(void* IsochBufferHandle);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_WriteIsochPipe(void* BufferHandle, uint32 Offset, uint32 Length, uint32* FrameNumber, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_ReadIsochPipe(void* BufferHandle, uint32 Offset, uint32 Length, uint32* FrameNumber, uint32 NumberOfPackets, USBD_ISO_PACKET_DESCRIPTOR* IsoPacketDescriptors, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_WriteIsochPipeAsap(void* BufferHandle, uint32 Offset, uint32 Length, BOOL ContinueStream, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_ReadIsochPipeAsap(void* BufferHandle, uint32 Offset, uint32 Length, BOOL ContinueStream, uint32 NumberOfPackets, USBD_ISO_PACKET_DESCRIPTOR* IsoPacketDescriptors, OVERLAPPED* Overlapped);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_StartTrackingForTimeSync(void* InterfaceHandle, USB_START_TRACKING_FOR_TIME_SYNC_INFORMATION* StartTrackingInfo);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_GetCurrentFrameNumberAndQpc(void* InterfaceHandle, USB_FRAME_NUMBER_AND_QPC_FOR_TIME_SYNC_INFORMATION* FrameQpcInfo);

	[Import("WINUSB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinUsb_StopTrackingForTimeSync(void* InterfaceHandle, USB_STOP_TRACKING_FOR_TIME_SYNC_INFORMATION* StopTrackingInfo);

}
#endregion
