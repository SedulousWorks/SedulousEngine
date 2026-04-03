using Win32.Foundation;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com;
using System;

namespace Win32.NetworkManagement.WindowsConnectNow;

#region Constants
public static
{
	public const HRESULT WCN_E_PEER_NOT_FOUND = -2147206143;
	public const HRESULT WCN_E_AUTHENTICATION_FAILED = -2147206142;
	public const HRESULT WCN_E_CONNECTION_REJECTED = -2147206141;
	public const HRESULT WCN_E_SESSION_TIMEDOUT = -2147206140;
	public const HRESULT WCN_E_PROTOCOL_ERROR = -2147206139;
	public const String WCN_QUERY_CONSTRAINT_USE_SOFTAP = "WCN.Discovery.SoftAP";
	public const uint32 WCN_VALUE_DT_CATEGORY_COMPUTER = 1;
	public const uint32 WCN_VALUE_DT_CATEGORY_INPUT_DEVICE = 2;
	public const uint32 WCN_VALUE_DT_CATEGORY_PRINTER = 3;
	public const uint32 WCN_VALUE_DT_CATEGORY_CAMERA = 4;
	public const uint32 WCN_VALUE_DT_CATEGORY_STORAGE = 5;
	public const uint32 WCN_VALUE_DT_CATEGORY_NETWORK_INFRASTRUCTURE = 6;
	public const uint32 WCN_VALUE_DT_CATEGORY_DISPLAY = 7;
	public const uint32 WCN_VALUE_DT_CATEGORY_MULTIMEDIA_DEVICE = 8;
	public const uint32 WCN_VALUE_DT_CATEGORY_GAMING_DEVICE = 9;
	public const uint32 WCN_VALUE_DT_CATEGORY_TELEPHONE = 10;
	public const uint32 WCN_VALUE_DT_CATEGORY_AUDIO_DEVICE = 11;
	public const uint32 WCN_VALUE_DT_CATEGORY_OTHER = 255;
	public const uint32 WCN_VALUE_DT_SUBTYPE_WIFI_OUI = 5304836;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__PC = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__SERVER = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__MEDIACENTER = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__ULTRAMOBILEPC = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__NOTEBOOK = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__DESKTOP = 6;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__MID = 7;
	public const uint32 WCN_VALUE_DT_SUBTYPE_COMPUTER__NETBOOK = 8;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__KEYBOARD = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__MOUSE = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__JOYSTICK = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__TRACKBALL = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__GAMECONTROLLER = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__REMOTE = 6;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__TOUCHSCREEN = 7;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__BIOMETRICREADER = 8;
	public const uint32 WCN_VALUE_DT_SUBTYPE_INPUT_DEVICE__BARCODEREADER = 9;
	public const uint32 WCN_VALUE_DT_SUBTYPE_PRINTER__PRINTER = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_PRINTER__SCANNER = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_PRINTER__FAX = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_PRINTER__COPIER = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_PRINTER__ALLINONE = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_CAMERA__STILL_CAMERA = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_CAMERA__VIDEO_CAMERA = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_CAMERA__WEB_CAMERA = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_CAMERA__SECURITY_CAMERA = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_STORAGE__NAS = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_NETWORK_INFRASTRUCUTURE__AP = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_NETWORK_INFRASTRUCUTURE__ROUTER = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_NETWORK_INFRASTRUCUTURE__SWITCH = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_NETWORK_INFRASTRUCUTURE__GATEWAY = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_NETWORK_INFRASTRUCUTURE__BRIDGE = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_DISPLAY__TELEVISION = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_DISPLAY__PICTURE_FRAME = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_DISPLAY__PROJECTOR = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_DISPLAY__MONITOR = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_MULTIMEDIA_DEVICE__DAR = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_MULTIMEDIA_DEVICE__PVR = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_MULTIMEDIA_DEVICE__MCX = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_MULTIMEDIA_DEVICE__SETTOPBOX = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_MULTIMEDIA_DEVICE__MEDIA_SERVER_ADAPT_EXT = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_MULTIMEDIA_DEVICE__PVP = 6;
	public const uint32 WCN_VALUE_DT_SUBTYPE_GAMING_DEVICE__XBOX = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_GAMING_DEVICE__XBOX360 = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_GAMING_DEVICE__PLAYSTATION = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_GAMING_DEVICE__CONSOLE_ADAPT = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_GAMING_DEVICE__PORTABLE = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_TELEPHONE__WINDOWS_MOBILE = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_TELEPHONE__PHONE_SINGLEMODE = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_TELEPHONE__PHONE_DUALMODE = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_TELEPHONE__SMARTPHONE_SINGLEMODE = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_TELEPHONE__SMARTPHONE_DUALMODE = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__TUNER_RECEIVER = 1;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__SPEAKERS = 2;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__PMP = 3;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__HEADSET = 4;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__HEADPHONES = 5;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__MICROPHONE = 6;
	public const uint32 WCN_VALUE_DT_SUBTYPE_AUDIO_DEVICE__HOMETHEATER = 7;
	public const uint32 WCN_API_MAX_BUFFER_SIZE = 2096;
	public const uint32 WCN_MICROSOFT_VENDOR_ID = 311;
	public const uint32 WCN_NO_SUBTYPE = 4294967294;
	public const uint32 WCN_FLAG_DISCOVERY_VE = 1;
	public const uint32 WCN_FLAG_AUTHENTICATED_VE = 2;
	public const uint32 WCN_FLAG_ENCRYPTED_VE = 4;
	public const Guid SID_WcnProvider = .(0xc100beca, 0xd33a, 0x4a4b, 0xbf, 0x23, 0xbb, 0xef, 0x46, 0x63, 0xd0, 0x17);
	public const PROPERTYKEY PKEY_WCN_DeviceType_Category = .(.(0x88190b8b, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 16);
	public const PROPERTYKEY PKEY_WCN_DeviceType_SubCategoryOUI = .(.(0x88190b8b, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 17);
	public const PROPERTYKEY PKEY_WCN_DeviceType_SubCategory = .(.(0x88190b8b, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 18);
	public const PROPERTYKEY PKEY_WCN_SSID = .(.(0x88190b8b, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 32);
}
#endregion

#region Enums

[AllowDuplicates]
public enum WCN_ATTRIBUTE_TYPE : int32
{
	WCN_TYPE_AP_CHANNEL = 0,
	WCN_TYPE_ASSOCIATION_STATE = 1,
	WCN_TYPE_AUTHENTICATION_TYPE = 2,
	WCN_TYPE_AUTHENTICATION_TYPE_FLAGS = 3,
	WCN_TYPE_AUTHENTICATOR = 4,
	WCN_TYPE_CONFIG_METHODS = 5,
	WCN_TYPE_CONFIGURATION_ERROR = 6,
	WCN_TYPE_CONFIRMATION_URL4 = 7,
	WCN_TYPE_CONFIRMATION_URL6 = 8,
	WCN_TYPE_CONNECTION_TYPE = 9,
	WCN_TYPE_CONNECTION_TYPE_FLAGS = 10,
	WCN_TYPE_CREDENTIAL = 11,
	WCN_TYPE_DEVICE_NAME = 12,
	WCN_TYPE_DEVICE_PASSWORD_ID = 13,
	WCN_TYPE_E_HASH1 = 14,
	WCN_TYPE_E_HASH2 = 15,
	WCN_TYPE_E_SNONCE1 = 16,
	WCN_TYPE_E_SNONCE2 = 17,
	WCN_TYPE_ENCRYPTED_SETTINGS = 18,
	WCN_TYPE_ENCRYPTION_TYPE = 19,
	WCN_TYPE_ENCRYPTION_TYPE_FLAGS = 20,
	WCN_TYPE_ENROLLEE_NONCE = 21,
	WCN_TYPE_FEATURE_ID = 22,
	WCN_TYPE_IDENTITY = 23,
	WCN_TYPE_IDENTITY_PROOF = 24,
	WCN_TYPE_KEY_WRAP_AUTHENTICATOR = 25,
	WCN_TYPE_KEY_IDENTIFIER = 26,
	WCN_TYPE_MAC_ADDRESS = 27,
	WCN_TYPE_MANUFACTURER = 28,
	WCN_TYPE_MESSAGE_TYPE = 29,
	WCN_TYPE_MODEL_NAME = 30,
	WCN_TYPE_MODEL_NUMBER = 31,
	WCN_TYPE_NETWORK_INDEX = 32,
	WCN_TYPE_NETWORK_KEY = 33,
	WCN_TYPE_NETWORK_KEY_INDEX = 34,
	WCN_TYPE_NEW_DEVICE_NAME = 35,
	WCN_TYPE_NEW_PASSWORD = 36,
	WCN_TYPE_OOB_DEVICE_PASSWORD = 37,
	WCN_TYPE_OS_VERSION = 38,
	WCN_TYPE_POWER_LEVEL = 39,
	WCN_TYPE_PSK_CURRENT = 40,
	WCN_TYPE_PSK_MAX = 41,
	WCN_TYPE_PUBLIC_KEY = 42,
	WCN_TYPE_RADIO_ENABLED = 43,
	WCN_TYPE_REBOOT = 44,
	WCN_TYPE_REGISTRAR_CURRENT = 45,
	WCN_TYPE_REGISTRAR_ESTABLISHED = 46,
	WCN_TYPE_REGISTRAR_LIST = 47,
	WCN_TYPE_REGISTRAR_MAX = 48,
	WCN_TYPE_REGISTRAR_NONCE = 49,
	WCN_TYPE_REQUEST_TYPE = 50,
	WCN_TYPE_RESPONSE_TYPE = 51,
	WCN_TYPE_RF_BANDS = 52,
	WCN_TYPE_R_HASH1 = 53,
	WCN_TYPE_R_HASH2 = 54,
	WCN_TYPE_R_SNONCE1 = 55,
	WCN_TYPE_R_SNONCE2 = 56,
	WCN_TYPE_SELECTED_REGISTRAR = 57,
	WCN_TYPE_SERIAL_NUMBER = 58,
	WCN_TYPE_WI_FI_PROTECTED_SETUP_STATE = 59,
	WCN_TYPE_SSID = 60,
	WCN_TYPE_TOTAL_NETWORKS = 61,
	WCN_TYPE_UUID_E = 62,
	WCN_TYPE_UUID_R = 63,
	WCN_TYPE_VENDOR_EXTENSION = 64,
	WCN_TYPE_VERSION = 65,
	WCN_TYPE_X_509_CERTIFICATE_REQUEST = 66,
	WCN_TYPE_X_509_CERTIFICATE = 67,
	WCN_TYPE_EAP_IDENTITY = 68,
	WCN_TYPE_MESSAGE_COUNTER = 69,
	WCN_TYPE_PUBLIC_KEY_HASH = 70,
	WCN_TYPE_REKEY_KEY = 71,
	WCN_TYPE_KEY_LIFETIME = 72,
	WCN_TYPE_PERMITTED_CONFIG_METHODS = 73,
	WCN_TYPE_SELECTED_REGISTRAR_CONFIG_METHODS = 74,
	WCN_TYPE_PRIMARY_DEVICE_TYPE = 75,
	WCN_TYPE_SECONDARY_DEVICE_TYPE_LIST = 76,
	WCN_TYPE_PORTABLE_DEVICE = 77,
	WCN_TYPE_AP_SETUP_LOCKED = 78,
	WCN_TYPE_APPLICATION_EXTENSION = 79,
	WCN_TYPE_EAP_TYPE = 80,
	WCN_TYPE_INITIALIZATION_VECTOR = 81,
	WCN_TYPE_KEY_PROVIDED_AUTOMATICALLY = 82,
	WCN_TYPE_802_1X_ENABLED = 83,
	WCN_TYPE_APPSESSIONKEY = 84,
	WCN_TYPE_WEPTRANSMITKEY = 85,
	WCN_TYPE_UUID = 86,
	WCN_TYPE_PRIMARY_DEVICE_TYPE_CATEGORY = 87,
	WCN_TYPE_PRIMARY_DEVICE_TYPE_SUBCATEGORY_OUI = 88,
	WCN_TYPE_PRIMARY_DEVICE_TYPE_SUBCATEGORY = 89,
	WCN_TYPE_CURRENT_SSID = 90,
	WCN_TYPE_BSSID = 91,
	WCN_TYPE_DOT11_MAC_ADDRESS = 92,
	WCN_TYPE_AUTHORIZED_MACS = 93,
	WCN_TYPE_NETWORK_KEY_SHAREABLE = 94,
	WCN_TYPE_REQUEST_TO_ENROLL = 95,
	WCN_TYPE_REQUESTED_DEVICE_TYPE = 96,
	WCN_TYPE_SETTINGS_DELAY_TIME = 97,
	WCN_TYPE_VERSION2 = 98,
	WCN_TYPE_VENDOR_EXTENSION_WFA = 99,
	WCN_NUM_ATTRIBUTE_TYPES = 100,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_VERSION : int32
{
	WCN_VALUE_VERSION_1_0 = 16,
	WCN_VALUE_VERSION_2_0 = 32,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_BOOLEAN : int32
{
	WCN_VALUE_FALSE = 0,
	WCN_VALUE_TRUE = 1,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_ASSOCIATION_STATE : int32
{
	WCN_VALUE_AS_NOT_ASSOCIATED = 0,
	WCN_VALUE_AS_CONNECTION_SUCCESS = 1,
	WCN_VALUE_AS_CONFIGURATION_FAILURE = 2,
	WCN_VALUE_AS_ASSOCIATION_FAILURE = 3,
	WCN_VALUE_AS_IP_FAILURE = 4,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_AUTHENTICATION_TYPE : int32
{
	WCN_VALUE_AT_OPEN = 1,
	WCN_VALUE_AT_WPAPSK = 2,
	WCN_VALUE_AT_SHARED = 4,
	WCN_VALUE_AT_WPA = 8,
	WCN_VALUE_AT_WPA2 = 16,
	WCN_VALUE_AT_WPA2PSK = 32,
	WCN_VALUE_AT_WPAWPA2PSK_MIXED = 34,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_CONFIG_METHODS : int32
{
	WCN_VALUE_CM_USBA = 1,
	WCN_VALUE_CM_ETHERNET = 2,
	WCN_VALUE_CM_LABEL = 4,
	WCN_VALUE_CM_DISPLAY = 8,
	WCN_VALUE_CM_EXTERNAL_NFC = 16,
	WCN_VALUE_CM_INTEGRATED_NFC = 32,
	WCN_VALUE_CM_NFC_INTERFACE = 64,
	WCN_VALUE_CM_PUSHBUTTON = 128,
	WCN_VALUE_CM_KEYPAD = 256,
	WCN_VALUE_CM_VIRT_PUSHBUTTON = 640,
	WCN_VALUE_CM_PHYS_PUSHBUTTON = 1152,
	WCN_VALUE_CM_VIRT_DISPLAY = 8200,
	WCN_VALUE_CM_PHYS_DISPLAY = 16392,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_CONFIGURATION_ERROR : int32
{
	WCN_VALUE_CE_NO_ERROR = 0,
	WCN_VALUE_CE_OOB_INTERFACE_READ_ERROR = 1,
	WCN_VALUE_CE_DECRYPTION_CRC_FAILURE = 2,
	WCN_VALUE_CE_2_4_CHANNEL_NOT_SUPPORTED = 3,
	WCN_VALUE_CE_5_0_CHANNEL_NOT_SUPPORTED = 4,
	WCN_VALUE_CE_SIGNAL_TOO_WEAK = 5,
	WCN_VALUE_CE_NETWORK_AUTHENTICATION_FAILURE = 6,
	WCN_VALUE_CE_NETWORK_ASSOCIATION_FAILURE = 7,
	WCN_VALUE_CE_NO_DHCP_RESPONSE = 8,
	WCN_VALUE_CE_FAILED_DHCP_CONFIG = 9,
	WCN_VALUE_CE_IP_ADDRESS_CONFLICT = 10,
	WCN_VALUE_CE_COULD_NOT_CONNECT_TO_REGISTRAR = 11,
	WCN_VALUE_CE_MULTIPLE_PBC_SESSIONS_DETECTED = 12,
	WCN_VALUE_CE_ROGUE_ACTIVITY_SUSPECTED = 13,
	WCN_VALUE_CE_DEVICE_BUSY = 14,
	WCN_VALUE_CE_SETUP_LOCKED = 15,
	WCN_VALUE_CE_MESSAGE_TIMEOUT = 16,
	WCN_VALUE_CE_REGISTRATION_SESSION_TIMEOUT = 17,
	WCN_VALUE_CE_DEVICE_PASSWORD_AUTH_FAILURE = 18,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_CONNECTION_TYPE : int32
{
	WCN_VALUE_CT_ESS = 1,
	WCN_VALUE_CT_IBSS = 2,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_DEVICE_PASSWORD_ID : int32
{
	WCN_VALUE_DP_DEFAULT = 0,
	WCN_VALUE_DP_USER_SPECIFIED = 1,
	WCN_VALUE_DP_MACHINE_SPECIFIED = 2,
	WCN_VALUE_DP_REKEY = 3,
	WCN_VALUE_DP_PUSHBUTTON = 4,
	WCN_VALUE_DP_REGISTRAR_SPECIFIED = 5,
	WCN_VALUE_DP_NFC_CONNECTION_HANDOVER = 7,
	WCN_VALUE_DP_WFD_SERVICES = 8,
	WCN_VALUE_DP_OUTOFBAND_MIN = 16,
	WCN_VALUE_DP_OUTOFBAND_MAX = 65535,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_ENCRYPTION_TYPE : int32
{
	WCN_VALUE_ET_NONE = 1,
	WCN_VALUE_ET_WEP = 2,
	WCN_VALUE_ET_TKIP = 4,
	WCN_VALUE_ET_AES = 8,
	WCN_VALUE_ET_TKIP_AES_MIXED = 12,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_MESSAGE_TYPE : int32
{
	WCN_VALUE_MT_BEACON = 1,
	WCN_VALUE_MT_PROBE_REQUEST = 2,
	WCN_VALUE_MT_PROBE_RESPONSE = 3,
	WCN_VALUE_MT_M1 = 4,
	WCN_VALUE_MT_M2 = 5,
	WCN_VALUE_MT_M2D = 6,
	WCN_VALUE_MT_M3 = 7,
	WCN_VALUE_MT_M4 = 8,
	WCN_VALUE_MT_M5 = 9,
	WCN_VALUE_MT_M6 = 10,
	WCN_VALUE_MT_M7 = 11,
	WCN_VALUE_MT_M8 = 12,
	WCN_VALUE_MT_ACK = 13,
	WCN_VALUE_MT_NACK = 14,
	WCN_VALUE_MT_DONE = 15,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_REQUEST_TYPE : int32
{
	WCN_VALUE_ReqT_ENROLLEE_INFO = 0,
	WCN_VALUE_ReqT_ENROLLEE_OPEN_1X = 1,
	WCN_VALUE_ReqT_REGISTRAR = 2,
	WCN_VALUE_ReqT_MANAGER_REGISTRAR = 3,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_RESPONSE_TYPE : int32
{
	WCN_VALUE_RspT_ENROLLEE_INFO = 0,
	WCN_VALUE_RspT_ENROLLEE_OPEN_1X = 1,
	WCN_VALUE_RspT_REGISTRAR = 2,
	WCN_VALUE_RspT_AP = 3,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_RF_BANDS : int32
{
	WCN_VALUE_RB_24GHZ = 1,
	WCN_VALUE_RB_50GHZ = 2,
}


[AllowDuplicates]
public enum WCN_VALUE_TYPE_WI_FI_PROTECTED_SETUP_STATE : int32
{
	WCN_VALUE_SS_RESERVED00 = 0,
	WCN_VALUE_SS_NOT_CONFIGURED = 1,
	WCN_VALUE_SS_CONFIGURED = 2,
}


[AllowDuplicates]
public enum WCN_PASSWORD_TYPE : int32
{
	WCN_PASSWORD_TYPE_PUSH_BUTTON = 0,
	WCN_PASSWORD_TYPE_PIN = 1,
	WCN_PASSWORD_TYPE_PIN_REGISTRAR_SPECIFIED = 2,
	WCN_PASSWORD_TYPE_OOB_SPECIFIED = 3,
	WCN_PASSWORD_TYPE_WFDS = 4,
}


[AllowDuplicates]
public enum WCN_SESSION_STATUS : int32
{
	WCN_SESSION_STATUS_SUCCESS = 0,
	WCN_SESSION_STATUS_FAILURE_GENERIC = 1,
	WCN_SESSION_STATUS_FAILURE_TIMEOUT = 2,
}

#endregion


#region Structs
[CRepr, Packed(1)]
public struct WCN_VALUE_TYPE_PRIMARY_DEVICE_TYPE
{
	public uint16 Category;
	public uint32 SubCategoryOUI;
	public uint16 SubCategory;
}

[CRepr]
public struct WCN_VENDOR_EXTENSION_SPEC
{
	public uint32 VendorId;
	public uint32 SubType;
	public uint32 Index;
	public uint32 Flags;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_WCNDeviceObject = .(0xc100bea7, 0xd33a, 0x4a4b, 0xbf, 0x23, 0xbb, 0xef, 0x46, 0x63, 0xd0, 0x17);


}
#endregion

#region COM Types
[CRepr]struct IWCNDevice : IUnknown
{
	public new const Guid IID = .(0xc100be9c, 0xd33a, 0x4a4b, 0xbf, 0x23, 0xbb, 0xef, 0x46, 0x63, 0xd0, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_PASSWORD_TYPE Type, uint32 dwPasswordLength, uint8* pbPassword) SetPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWCNConnectNotify* pNotify) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_ATTRIBUTE_TYPE AttributeType, uint32 dwMaxBufferSize, uint8* pbBuffer, uint32* pdwBufferUsed) GetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_ATTRIBUTE_TYPE AttributeType, uint32* puInteger) GetIntegerAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_ATTRIBUTE_TYPE AttributeType, uint32 cchMaxString, char16* wszString) GetStringAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchMaxStringLength, char16* wszProfile) GetNetworkProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszProfileXml) SetNetworkProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_VENDOR_EXTENSION_SPEC* pVendorExtSpec, uint32 dwMaxBufferSize, uint8* pbBuffer, uint32* pdwBufferUsed) GetVendorExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_VENDOR_EXTENSION_SPEC* pVendorExtSpec, uint32 cbBuffer, uint8* pbBuffer) SetVendorExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WCN_PASSWORD_TYPE Type, uint32 dwOOBPasswordID, uint32 dwPasswordLength, uint8* pbPassword, uint32 dwRemotePublicKeyHashLength, uint8* pbRemotePublicKeyHash, uint32 dwDHKeyBlobLength, uint8* pbDHKeyBlob) SetNFCPasswordParams;
	}


	public HRESULT SetPassword(WCN_PASSWORD_TYPE Type, uint32 dwPasswordLength, uint8* pbPassword) mut => VT.[Friend]SetPassword(&this, Type, dwPasswordLength, pbPassword);

	public HRESULT Connect(IWCNConnectNotify* pNotify) mut => VT.[Friend]Connect(&this, pNotify);

	public HRESULT GetAttribute(WCN_ATTRIBUTE_TYPE AttributeType, uint32 dwMaxBufferSize, uint8* pbBuffer, uint32* pdwBufferUsed) mut => VT.[Friend]GetAttribute(&this, AttributeType, dwMaxBufferSize, pbBuffer, pdwBufferUsed);

	public HRESULT GetIntegerAttribute(WCN_ATTRIBUTE_TYPE AttributeType, uint32* puInteger) mut => VT.[Friend]GetIntegerAttribute(&this, AttributeType, puInteger);

	public HRESULT GetStringAttribute(WCN_ATTRIBUTE_TYPE AttributeType, uint32 cchMaxString, char16* wszString) mut => VT.[Friend]GetStringAttribute(&this, AttributeType, cchMaxString, wszString);

	public HRESULT GetNetworkProfile(uint32 cchMaxStringLength, char16* wszProfile) mut => VT.[Friend]GetNetworkProfile(&this, cchMaxStringLength, wszProfile);

	public HRESULT SetNetworkProfile(PWSTR pszProfileXml) mut => VT.[Friend]SetNetworkProfile(&this, pszProfileXml);

	public HRESULT GetVendorExtension(WCN_VENDOR_EXTENSION_SPEC* pVendorExtSpec, uint32 dwMaxBufferSize, uint8* pbBuffer, uint32* pdwBufferUsed) mut => VT.[Friend]GetVendorExtension(&this, pVendorExtSpec, dwMaxBufferSize, pbBuffer, pdwBufferUsed);

	public HRESULT SetVendorExtension(WCN_VENDOR_EXTENSION_SPEC* pVendorExtSpec, uint32 cbBuffer, uint8* pbBuffer) mut => VT.[Friend]SetVendorExtension(&this, pVendorExtSpec, cbBuffer, pbBuffer);

	public HRESULT Unadvise() mut => VT.[Friend]Unadvise(&this);

	public HRESULT SetNFCPasswordParams(WCN_PASSWORD_TYPE Type, uint32 dwOOBPasswordID, uint32 dwPasswordLength, uint8* pbPassword, uint32 dwRemotePublicKeyHashLength, uint8* pbRemotePublicKeyHash, uint32 dwDHKeyBlobLength, uint8* pbDHKeyBlob) mut => VT.[Friend]SetNFCPasswordParams(&this, Type, dwOOBPasswordID, dwPasswordLength, pbPassword, dwRemotePublicKeyHashLength, pbRemotePublicKeyHash, dwDHKeyBlobLength, pbDHKeyBlob);
}

[CRepr]struct IWCNConnectNotify : IUnknown
{
	public new const Guid IID = .(0xc100be9f, 0xd33a, 0x4a4b, 0xbf, 0x23, 0xbb, 0xef, 0x46, 0x63, 0xd0, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ConnectSucceeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrFailure) ConnectFailed;
	}


	public HRESULT ConnectSucceeded() mut => VT.[Friend]ConnectSucceeded(&this);

	public HRESULT ConnectFailed(HRESULT hrFailure) mut => VT.[Friend]ConnectFailed(&this, hrFailure);
}

#endregion
