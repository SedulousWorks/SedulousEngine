using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.MobileBroadband;

#region Enums

[AllowDuplicates]
public enum MBN_SIGNAL_CONSTANTS : int32
{
	MBN_RSSI_DEFAULT = -1,
	MBN_RSSI_DISABLE = 0,
	MBN_RSSI_UNKNOWN = 99,
	MBN_ERROR_RATE_UNKNOWN = 99,
}


[AllowDuplicates]
public enum MBN_CELLULAR_CLASS : int32
{
	MBN_CELLULAR_CLASS_NONE = 0,
	MBN_CELLULAR_CLASS_GSM = 1,
	MBN_CELLULAR_CLASS_CDMA = 2,
}


[AllowDuplicates]
public enum MBN_VOICE_CLASS : int32
{
	MBN_VOICE_CLASS_NONE = 0,
	MBN_VOICE_CLASS_NO_VOICE = 1,
	MBN_VOICE_CLASS_SEPARATE_VOICE_DATA = 2,
	MBN_VOICE_CLASS_SIMULTANEOUS_VOICE_DATA = 3,
}


[AllowDuplicates]
public enum MBN_PROVIDER_STATE : int32
{
	MBN_PROVIDER_STATE_NONE = 0,
	MBN_PROVIDER_STATE_HOME = 1,
	MBN_PROVIDER_STATE_FORBIDDEN = 2,
	MBN_PROVIDER_STATE_PREFERRED = 4,
	MBN_PROVIDER_STATE_VISIBLE = 8,
	MBN_PROVIDER_STATE_REGISTERED = 16,
	MBN_PROVIDER_STATE_PREFERRED_MULTICARRIER = 32,
}


[AllowDuplicates]
public enum MBN_PROVIDER_CONSTANTS : int32
{
	MBN_PROVIDERNAME_LEN = 20,
	MBN_PROVIDERID_LEN = 6,
}


[AllowDuplicates]
public enum MBN_INTERFACE_CAPS_CONSTANTS : int32
{
	MBN_DEVICEID_LEN = 18,
	MBN_MANUFACTURER_LEN = 32,
	MBN_MODEL_LEN = 32,
	MBN_FIRMWARE_LEN = 32,
}


[AllowDuplicates]
public enum MBN_DATA_CLASS : int32
{
	MBN_DATA_CLASS_NONE = 0,
	MBN_DATA_CLASS_GPRS = 1,
	MBN_DATA_CLASS_EDGE = 2,
	MBN_DATA_CLASS_UMTS = 4,
	MBN_DATA_CLASS_HSDPA = 8,
	MBN_DATA_CLASS_HSUPA = 16,
	MBN_DATA_CLASS_LTE = 32,
	MBN_DATA_CLASS_5G_NSA = 64,
	MBN_DATA_CLASS_5G_SA = 128,
	MBN_DATA_CLASS_1XRTT = 65536,
	MBN_DATA_CLASS_1XEVDO = 131072,
	MBN_DATA_CLASS_1XEVDO_REVA = 262144,
	MBN_DATA_CLASS_1XEVDV = 524288,
	MBN_DATA_CLASS_3XRTT = 1048576,
	MBN_DATA_CLASS_1XEVDO_REVB = 2097152,
	MBN_DATA_CLASS_UMB = 4194304,
	MBN_DATA_CLASS_CUSTOM = -2147483648,
}


[AllowDuplicates]
public enum MBN_CTRL_CAPS : int32
{
	MBN_CTRL_CAPS_NONE = 0,
	MBN_CTRL_CAPS_REG_MANUAL = 1,
	MBN_CTRL_CAPS_HW_RADIO_SWITCH = 2,
	MBN_CTRL_CAPS_CDMA_MOBILE_IP = 4,
	MBN_CTRL_CAPS_CDMA_SIMPLE_IP = 8,
	MBN_CTRL_CAPS_PROTECT_UNIQUEID = 16,
	MBN_CTRL_CAPS_MODEL_MULTI_CARRIER = 32,
	MBN_CTRL_CAPS_USSD = 64,
	MBN_CTRL_CAPS_MULTI_MODE = 128,
}


[AllowDuplicates]
public enum MBN_SMS_CAPS : int32
{
	MBN_SMS_CAPS_NONE = 0,
	MBN_SMS_CAPS_PDU_RECEIVE = 1,
	MBN_SMS_CAPS_PDU_SEND = 2,
	MBN_SMS_CAPS_TEXT_RECEIVE = 4,
	MBN_SMS_CAPS_TEXT_SEND = 8,
}


[AllowDuplicates]
public enum MBN_BAND_CLASS : int32
{
	MBN_BAND_CLASS_NONE = 0,
	MBN_BAND_CLASS_0 = 1,
	MBN_BAND_CLASS_I = 2,
	MBN_BAND_CLASS_II = 4,
	MBN_BAND_CLASS_III = 8,
	MBN_BAND_CLASS_IV = 16,
	MBN_BAND_CLASS_V = 32,
	MBN_BAND_CLASS_VI = 64,
	MBN_BAND_CLASS_VII = 128,
	MBN_BAND_CLASS_VIII = 256,
	MBN_BAND_CLASS_IX = 512,
	MBN_BAND_CLASS_X = 1024,
	MBN_BAND_CLASS_XI = 2048,
	MBN_BAND_CLASS_XII = 4096,
	MBN_BAND_CLASS_XIII = 8192,
	MBN_BAND_CLASS_XIV = 16384,
	MBN_BAND_CLASS_XV = 32768,
	MBN_BAND_CLASS_XVI = 65536,
	MBN_BAND_CLASS_XVII = 131072,
	MBN_BAND_CLASS_CUSTOM = -2147483648,
}


[AllowDuplicates]
public enum MBN_READY_STATE : int32
{
	MBN_READY_STATE_OFF = 0,
	MBN_READY_STATE_INITIALIZED = 1,
	MBN_READY_STATE_SIM_NOT_INSERTED = 2,
	MBN_READY_STATE_BAD_SIM = 3,
	MBN_READY_STATE_FAILURE = 4,
	MBN_READY_STATE_NOT_ACTIVATED = 5,
	MBN_READY_STATE_DEVICE_LOCKED = 6,
	MBN_READY_STATE_DEVICE_BLOCKED = 7,
	MBN_READY_STATE_NO_ESIM_PROFILE = 8,
}


[AllowDuplicates]
public enum MBN_ACTIVATION_STATE : int32
{
	MBN_ACTIVATION_STATE_NONE = 0,
	MBN_ACTIVATION_STATE_ACTIVATED = 1,
	MBN_ACTIVATION_STATE_ACTIVATING = 2,
	MBN_ACTIVATION_STATE_DEACTIVATED = 3,
	MBN_ACTIVATION_STATE_DEACTIVATING = 4,
}


[AllowDuplicates]
public enum MBN_CONNECTION_MODE : int32
{
	MBN_CONNECTION_MODE_PROFILE = 0,
	MBN_CONNECTION_MODE_TMP_PROFILE = 1,
}


[AllowDuplicates]
public enum MBN_VOICE_CALL_STATE : int32
{
	MBN_VOICE_CALL_STATE_NONE = 0,
	MBN_VOICE_CALL_STATE_IN_PROGRESS = 1,
	MBN_VOICE_CALL_STATE_HANGUP = 2,
}


[AllowDuplicates]
public enum MBN_REGISTRATION_CONSTANTS : int32
{
	MBN_ROAMTEXT_LEN = 64,
	MBN_CDMA_DEFAULT_PROVIDER_ID = 0,
}


[AllowDuplicates]
public enum MBN_REGISTER_STATE : int32
{
	MBN_REGISTER_STATE_NONE = 0,
	MBN_REGISTER_STATE_DEREGISTERED = 1,
	MBN_REGISTER_STATE_SEARCHING = 2,
	MBN_REGISTER_STATE_HOME = 3,
	MBN_REGISTER_STATE_ROAMING = 4,
	MBN_REGISTER_STATE_PARTNER = 5,
	MBN_REGISTER_STATE_DENIED = 6,
}


[AllowDuplicates]
public enum MBN_REGISTER_MODE : int32
{
	MBN_REGISTER_MODE_NONE = 0,
	MBN_REGISTER_MODE_AUTOMATIC = 1,
	MBN_REGISTER_MODE_MANUAL = 2,
}


[AllowDuplicates]
public enum MBN_PIN_CONSTANTS : int32
{
	MBN_ATTEMPTS_REMAINING_UNKNOWN = -1,
	MBN_PIN_LENGTH_UNKNOWN = -1,
}


[AllowDuplicates]
public enum MBN_PIN_STATE : int32
{
	MBN_PIN_STATE_NONE = 0,
	MBN_PIN_STATE_ENTER = 1,
	MBN_PIN_STATE_UNBLOCK = 2,
}


[AllowDuplicates]
public enum MBN_PIN_TYPE : int32
{
	MBN_PIN_TYPE_NONE = 0,
	MBN_PIN_TYPE_CUSTOM = 1,
	MBN_PIN_TYPE_PIN1 = 2,
	MBN_PIN_TYPE_PIN2 = 3,
	MBN_PIN_TYPE_DEVICE_SIM_PIN = 4,
	MBN_PIN_TYPE_DEVICE_FIRST_SIM_PIN = 5,
	MBN_PIN_TYPE_NETWORK_PIN = 6,
	MBN_PIN_TYPE_NETWORK_SUBSET_PIN = 7,
	MBN_PIN_TYPE_SVC_PROVIDER_PIN = 8,
	MBN_PIN_TYPE_CORPORATE_PIN = 9,
	MBN_PIN_TYPE_SUBSIDY_LOCK = 10,
}


[AllowDuplicates]
public enum MBN_PIN_MODE : int32
{
	MBN_PIN_MODE_ENABLED = 1,
	MBN_PIN_MODE_DISABLED = 2,
}


[AllowDuplicates]
public enum MBN_PIN_FORMAT : int32
{
	MBN_PIN_FORMAT_NONE = 0,
	MBN_PIN_FORMAT_NUMERIC = 1,
	MBN_PIN_FORMAT_ALPHANUMERIC = 2,
}


[AllowDuplicates]
public enum MBN_CONTEXT_CONSTANTS : int32
{
	MBN_ACCESSSTRING_LEN = 100,
	MBN_USERNAME_LEN = 255,
	MBN_PASSWORD_LEN = 255,
	MBN_CONTEXT_ID_APPEND = -1,
}


[AllowDuplicates]
public enum MBN_AUTH_PROTOCOL : int32
{
	MBN_AUTH_PROTOCOL_NONE = 0,
	MBN_AUTH_PROTOCOL_PAP = 1,
	MBN_AUTH_PROTOCOL_CHAP = 2,
	MBN_AUTH_PROTOCOL_MSCHAPV2 = 3,
}


[AllowDuplicates]
public enum MBN_COMPRESSION : int32
{
	MBN_COMPRESSION_NONE = 0,
	MBN_COMPRESSION_ENABLE = 1,
}


[AllowDuplicates]
public enum MBN_CONTEXT_TYPE : int32
{
	MBN_CONTEXT_TYPE_NONE = 0,
	MBN_CONTEXT_TYPE_INTERNET = 1,
	MBN_CONTEXT_TYPE_VPN = 2,
	MBN_CONTEXT_TYPE_VOICE = 3,
	MBN_CONTEXT_TYPE_VIDEO_SHARE = 4,
	MBN_CONTEXT_TYPE_CUSTOM = 5,
	MBN_CONTEXT_TYPE_PURCHASE = 6,
}


[AllowDuplicates]
public enum WWAEXT_SMS_CONSTANTS : int32
{
	MBN_MESSAGE_INDEX_NONE = 0,
	MBN_CDMA_SHORT_MSG_SIZE_UNKNOWN = 0,
	MBN_CDMA_SHORT_MSG_SIZE_MAX = 160,
}


[AllowDuplicates]
public enum MBN_MSG_STATUS : int32
{
	MBN_MSG_STATUS_NEW = 0,
	MBN_MSG_STATUS_OLD = 1,
	MBN_MSG_STATUS_DRAFT = 2,
	MBN_MSG_STATUS_SENT = 3,
}


[AllowDuplicates]
public enum MBN_SMS_CDMA_LANG : int32
{
	MBN_SMS_CDMA_LANG_NONE = 0,
	MBN_SMS_CDMA_LANG_ENGLISH = 1,
	MBN_SMS_CDMA_LANG_FRENCH = 2,
	MBN_SMS_CDMA_LANG_SPANISH = 3,
	MBN_SMS_CDMA_LANG_JAPANESE = 4,
	MBN_SMS_CDMA_LANG_KOREAN = 5,
	MBN_SMS_CDMA_LANG_CHINESE = 6,
	MBN_SMS_CDMA_LANG_HEBREW = 7,
}


[AllowDuplicates]
public enum MBN_SMS_CDMA_ENCODING : int32
{
	MBN_SMS_CDMA_ENCODING_OCTET = 0,
	MBN_SMS_CDMA_ENCODING_EPM = 1,
	MBN_SMS_CDMA_ENCODING_7BIT_ASCII = 2,
	MBN_SMS_CDMA_ENCODING_IA5 = 3,
	MBN_SMS_CDMA_ENCODING_UNICODE = 4,
	MBN_SMS_CDMA_ENCODING_SHIFT_JIS = 5,
	MBN_SMS_CDMA_ENCODING_KOREAN = 6,
	MBN_SMS_CDMA_ENCODING_LATIN_HEBREW = 7,
	MBN_SMS_CDMA_ENCODING_LATIN = 8,
	MBN_SMS_CDMA_ENCODING_GSM_7BIT = 9,
}


[AllowDuplicates]
public enum MBN_SMS_FLAG : int32
{
	MBN_SMS_FLAG_ALL = 0,
	MBN_SMS_FLAG_INDEX = 1,
	MBN_SMS_FLAG_NEW = 2,
	MBN_SMS_FLAG_OLD = 3,
	MBN_SMS_FLAG_SENT = 4,
	MBN_SMS_FLAG_DRAFT = 5,
}


[AllowDuplicates]
public enum MBN_SMS_STATUS_FLAG : int32
{
	MBN_SMS_FLAG_NONE = 0,
	MBN_SMS_FLAG_MESSAGE_STORE_FULL = 1,
	MBN_SMS_FLAG_NEW_MESSAGE = 2,
}


[AllowDuplicates]
public enum MBN_SMS_FORMAT : int32
{
	MBN_SMS_FORMAT_NONE = 0,
	MBN_SMS_FORMAT_PDU = 1,
	MBN_SMS_FORMAT_TEXT = 2,
}


[AllowDuplicates]
public enum MBN_RADIO : int32
{
	MBN_RADIO_OFF = 0,
	MBN_RADIO_ON = 1,
}


[AllowDuplicates]
public enum MBN_DEVICE_SERVICE_SESSIONS_STATE : int32
{
	MBN_DEVICE_SERVICE_SESSIONS_RESTORED = 0,
}


[AllowDuplicates]
public enum MBN_DEVICE_SERVICES_INTERFACE_STATE : int32
{
	MBN_DEVICE_SERVICES_CAPABLE_INTERFACE_ARRIVAL = 0,
	MBN_DEVICE_SERVICES_CAPABLE_INTERFACE_REMOVAL = 1,
}

#endregion


#region Structs
[CRepr]
public struct MBN_INTERFACE_CAPS
{
	public MBN_CELLULAR_CLASS cellularClass;
	public MBN_VOICE_CLASS voiceClass;
	public uint32 dataClass;
	public BSTR customDataClass;
	public uint32 gsmBandClass;
	public uint32 cdmaBandClass;
	public BSTR customBandClass;
	public uint32 smsCaps;
	public uint32 controlCaps;
	public BSTR deviceID;
	public BSTR manufacturer;
	public BSTR model;
	public BSTR firmwareInfo;
}

[CRepr]
public struct MBN_PROVIDER
{
	public BSTR providerID;
	public uint32 providerState;
	public BSTR providerName;
	public uint32 dataClass;
}

[CRepr]
public struct MBN_PROVIDER2
{
	public MBN_PROVIDER provider;
	public MBN_CELLULAR_CLASS cellularClass;
	public uint32 signalStrength;
	public uint32 signalError;
}

[CRepr]
public struct MBN_PIN_INFO
{
	public MBN_PIN_STATE pinState;
	public MBN_PIN_TYPE pinType;
	public uint32 attemptsRemaining;
}

[CRepr]
public struct MBN_CONTEXT
{
	public uint32 contextID;
	public MBN_CONTEXT_TYPE contextType;
	public BSTR accessString;
	public BSTR userName;
	public BSTR password;
	public MBN_COMPRESSION compression;
	public MBN_AUTH_PROTOCOL authType;
}

[CRepr]
public struct MBN_SMS_FILTER
{
	public MBN_SMS_FLAG flag;
	public uint32 messageIndex;
}

[CRepr]
public struct MBN_SMS_STATUS_INFO
{
	public uint32 flag;
	public uint32 messageIndex;
}

[CRepr]
public struct MBN_DEVICE_SERVICE
{
	public BSTR deviceServiceID;
	public int16 dataWriteSupported;
	public int16 dataReadSupported;
}

[CRepr]
public struct __mbnapi_ReferenceRemainingTypes__
{
	public MBN_BAND_CLASS bandClass;
	public MBN_CONTEXT_CONSTANTS contextConstants;
	public MBN_CTRL_CAPS ctrlCaps;
	public MBN_DATA_CLASS dataClass;
	public MBN_INTERFACE_CAPS_CONSTANTS interfaceCapsConstants;
	public MBN_PIN_CONSTANTS pinConstants;
	public MBN_PROVIDER_CONSTANTS providerConstants;
	public MBN_PROVIDER_STATE providerState;
	public MBN_REGISTRATION_CONSTANTS registrationConstants;
	public MBN_SIGNAL_CONSTANTS signalConstants;
	public MBN_SMS_CAPS smsCaps;
	public WWAEXT_SMS_CONSTANTS smsConstants;
	public WWAEXT_SMS_CONSTANTS wwaextSmsConstants;
	public MBN_SMS_STATUS_FLAG smsStatusFlag;
}

[CRepr]
public struct __DummyPinType__
{
	public uint32 pinType;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_MbnConnectionProfileManager = .(0xbdfee05a, 0x4418, 0x11dd, 0x90, 0xed, 0x00, 0x1c, 0x25, 0x7c, 0xcf, 0xf1);


	public const Guid CLSID_MbnInterfaceManager = .(0xbdfee05b, 0x4418, 0x11dd, 0x90, 0xed, 0x00, 0x1c, 0x25, 0x7c, 0xcf, 0xf1);


	public const Guid CLSID_MbnConnectionManager = .(0xbdfee05c, 0x4418, 0x11dd, 0x90, 0xed, 0x00, 0x1c, 0x25, 0x7c, 0xcf, 0xf1);


	public const Guid CLSID_MbnDeviceServicesManager = .(0x2269daa3, 0x2a9f, 0x4165, 0xa5, 0x01, 0xce, 0x00, 0xa6, 0xf7, 0xa7, 0x5b);


}
#endregion

#region COM Types
[CRepr]struct IDummyMBNUCMExt : IDispatch
{
	public new const Guid IID = .(0xdcbbbab6, 0xffff, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IMbnConnection : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x200d, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ConnectionID) get_ConnectionID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* InterfaceID) get_InterfaceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_CONNECTION_MODE connectionMode, PWSTR strProfile, uint32* requestID) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_ACTIVATION_STATE* ConnectionState, BSTR* ProfileName) GetConnectionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_VOICE_CALL_STATE* voiceCallState) GetVoiceCallState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* networkError) GetActivationNetworkError;
	}


	public HRESULT get_ConnectionID(BSTR* ConnectionID) mut => VT.[Friend]get_ConnectionID(&this, ConnectionID);

	public HRESULT get_InterfaceID(BSTR* InterfaceID) mut => VT.[Friend]get_InterfaceID(&this, InterfaceID);

	public HRESULT Connect(MBN_CONNECTION_MODE connectionMode, PWSTR strProfile, uint32* requestID) mut => VT.[Friend]Connect(&this, connectionMode, strProfile, requestID);

	public HRESULT Disconnect(uint32* requestID) mut => VT.[Friend]Disconnect(&this, requestID);

	public HRESULT GetConnectionState(MBN_ACTIVATION_STATE* ConnectionState, BSTR* ProfileName) mut => VT.[Friend]GetConnectionState(&this, ConnectionState, ProfileName);

	public HRESULT GetVoiceCallState(MBN_VOICE_CALL_STATE* voiceCallState) mut => VT.[Friend]GetVoiceCallState(&this, voiceCallState);

	public HRESULT GetActivationNetworkError(uint32* networkError) mut => VT.[Friend]GetActivationNetworkError(&this, networkError);
}

[CRepr]struct IMbnConnectionEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x200e, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection* newConnection, uint32 requestID, HRESULT status) OnConnectComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection* newConnection, uint32 requestID, HRESULT status) OnDisconnectComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection* newConnection) OnConnectStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection* newConnection) OnVoiceCallStateChange;
	}


	public HRESULT OnConnectComplete(IMbnConnection* newConnection, uint32 requestID, HRESULT status) mut => VT.[Friend]OnConnectComplete(&this, newConnection, requestID, status);

	public HRESULT OnDisconnectComplete(IMbnConnection* newConnection, uint32 requestID, HRESULT status) mut => VT.[Friend]OnDisconnectComplete(&this, newConnection, requestID, status);

	public HRESULT OnConnectStateChange(IMbnConnection* newConnection) mut => VT.[Friend]OnConnectStateChange(&this, newConnection);

	public HRESULT OnVoiceCallStateChange(IMbnConnection* newConnection) mut => VT.[Friend]OnVoiceCallStateChange(&this, newConnection);
}

[CRepr]struct IMbnInterface : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2001, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* InterfaceID) get_InterfaceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_INTERFACE_CAPS* interfaceCaps) GetInterfaceCapability;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSubscriberInformation** subscriberInformation) GetSubscriberInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_READY_STATE* readyState) GetReadyState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* emergencyMode) InEmergencyMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_PROVIDER* homeProvider) GetHomeProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** preferredProviders) GetPreferredProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* preferredProviders, uint32* requestID) SetPreferredProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* age, SAFEARRAY** visibleProviders) GetVisibleProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) ScanNetwork;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection** mbnConnection) GetConnection;
	}


	public HRESULT get_InterfaceID(BSTR* InterfaceID) mut => VT.[Friend]get_InterfaceID(&this, InterfaceID);

	public HRESULT GetInterfaceCapability(MBN_INTERFACE_CAPS* interfaceCaps) mut => VT.[Friend]GetInterfaceCapability(&this, interfaceCaps);

	public HRESULT GetSubscriberInformation(IMbnSubscriberInformation** subscriberInformation) mut => VT.[Friend]GetSubscriberInformation(&this, subscriberInformation);

	public HRESULT GetReadyState(MBN_READY_STATE* readyState) mut => VT.[Friend]GetReadyState(&this, readyState);

	public HRESULT InEmergencyMode(int16* emergencyMode) mut => VT.[Friend]InEmergencyMode(&this, emergencyMode);

	public HRESULT GetHomeProvider(MBN_PROVIDER* homeProvider) mut => VT.[Friend]GetHomeProvider(&this, homeProvider);

	public HRESULT GetPreferredProviders(SAFEARRAY** preferredProviders) mut => VT.[Friend]GetPreferredProviders(&this, preferredProviders);

	public HRESULT SetPreferredProviders(SAFEARRAY* preferredProviders, uint32* requestID) mut => VT.[Friend]SetPreferredProviders(&this, preferredProviders, requestID);

	public HRESULT GetVisibleProviders(uint32* age, SAFEARRAY** visibleProviders) mut => VT.[Friend]GetVisibleProviders(&this, age, visibleProviders);

	public HRESULT ScanNetwork(uint32* requestID) mut => VT.[Friend]ScanNetwork(&this, requestID);

	public HRESULT GetConnection(IMbnConnection** mbnConnection) mut => VT.[Friend]GetConnection(&this, mbnConnection);
}

[CRepr]struct IMbnInterfaceEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2002, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnInterfaceCapabilityAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnSubscriberInformationChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnReadyStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnEmergencyModeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnHomeProviderAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnPreferredProvidersChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface, uint32 requestID, HRESULT status) OnSetPreferredProvidersComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface, uint32 requestID, HRESULT status) OnScanNetworkComplete;
	}


	public HRESULT OnInterfaceCapabilityAvailable(IMbnInterface* newInterface) mut => VT.[Friend]OnInterfaceCapabilityAvailable(&this, newInterface);

	public HRESULT OnSubscriberInformationChange(IMbnInterface* newInterface) mut => VT.[Friend]OnSubscriberInformationChange(&this, newInterface);

	public HRESULT OnReadyStateChange(IMbnInterface* newInterface) mut => VT.[Friend]OnReadyStateChange(&this, newInterface);

	public HRESULT OnEmergencyModeChange(IMbnInterface* newInterface) mut => VT.[Friend]OnEmergencyModeChange(&this, newInterface);

	public HRESULT OnHomeProviderAvailable(IMbnInterface* newInterface) mut => VT.[Friend]OnHomeProviderAvailable(&this, newInterface);

	public HRESULT OnPreferredProvidersChange(IMbnInterface* newInterface) mut => VT.[Friend]OnPreferredProvidersChange(&this, newInterface);

	public HRESULT OnSetPreferredProvidersComplete(IMbnInterface* newInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSetPreferredProvidersComplete(&this, newInterface, requestID, status);

	public HRESULT OnScanNetworkComplete(IMbnInterface* newInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnScanNetworkComplete(&this, newInterface, requestID, status);
}

[CRepr]struct IMbnInterfaceManager : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x201b, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR interfaceID, IMbnInterface** mbnInterface) GetInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** mbnInterfaces) GetInterfaces;
	}


	public HRESULT GetInterface(PWSTR interfaceID, IMbnInterface** mbnInterface) mut => VT.[Friend]GetInterface(&this, interfaceID, mbnInterface);

	public HRESULT GetInterfaces(SAFEARRAY** mbnInterfaces) mut => VT.[Friend]GetInterfaces(&this, mbnInterfaces);
}

[CRepr]struct IMbnInterfaceManagerEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x201c, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* newInterface) OnInterfaceArrival;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* oldInterface) OnInterfaceRemoval;
	}


	public HRESULT OnInterfaceArrival(IMbnInterface* newInterface) mut => VT.[Friend]OnInterfaceArrival(&this, newInterface);

	public HRESULT OnInterfaceRemoval(IMbnInterface* oldInterface) mut => VT.[Friend]OnInterfaceRemoval(&this, oldInterface);
}

[CRepr]struct IMbnRegistration : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2009, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_REGISTER_STATE* registerState) GetRegisterState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_REGISTER_MODE* registerMode) GetRegisterMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* providerID) GetProviderID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* providerName) GetProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* roamingText) GetRoamingText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* availableDataClasses) GetAvailableDataClasses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* currentDataClass) GetCurrentDataClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* registrationNetworkError) GetRegistrationNetworkError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* packetAttachNetworkError) GetPacketAttachNetworkError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_REGISTER_MODE registerMode, PWSTR providerID, uint32 dataClass, uint32* requestID) SetRegisterMode;
	}


	public HRESULT GetRegisterState(MBN_REGISTER_STATE* registerState) mut => VT.[Friend]GetRegisterState(&this, registerState);

	public HRESULT GetRegisterMode(MBN_REGISTER_MODE* registerMode) mut => VT.[Friend]GetRegisterMode(&this, registerMode);

	public HRESULT GetProviderID(BSTR* providerID) mut => VT.[Friend]GetProviderID(&this, providerID);

	public HRESULT GetProviderName(BSTR* providerName) mut => VT.[Friend]GetProviderName(&this, providerName);

	public HRESULT GetRoamingText(BSTR* roamingText) mut => VT.[Friend]GetRoamingText(&this, roamingText);

	public HRESULT GetAvailableDataClasses(uint32* availableDataClasses) mut => VT.[Friend]GetAvailableDataClasses(&this, availableDataClasses);

	public HRESULT GetCurrentDataClass(uint32* currentDataClass) mut => VT.[Friend]GetCurrentDataClass(&this, currentDataClass);

	public HRESULT GetRegistrationNetworkError(uint32* registrationNetworkError) mut => VT.[Friend]GetRegistrationNetworkError(&this, registrationNetworkError);

	public HRESULT GetPacketAttachNetworkError(uint32* packetAttachNetworkError) mut => VT.[Friend]GetPacketAttachNetworkError(&this, packetAttachNetworkError);

	public HRESULT SetRegisterMode(MBN_REGISTER_MODE registerMode, PWSTR providerID, uint32 dataClass, uint32* requestID) mut => VT.[Friend]SetRegisterMode(&this, registerMode, providerID, dataClass, requestID);
}

[CRepr]struct IMbnRegistrationEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x200a, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnRegistration* newInterface) OnRegisterModeAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnRegistration* newInterface) OnRegisterStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnRegistration* newInterface) OnPacketServiceStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnRegistration* newInterface, uint32 requestID, HRESULT status) OnSetRegisterModeComplete;
	}


	public HRESULT OnRegisterModeAvailable(IMbnRegistration* newInterface) mut => VT.[Friend]OnRegisterModeAvailable(&this, newInterface);

	public HRESULT OnRegisterStateChange(IMbnRegistration* newInterface) mut => VT.[Friend]OnRegisterStateChange(&this, newInterface);

	public HRESULT OnPacketServiceStateChange(IMbnRegistration* newInterface) mut => VT.[Friend]OnPacketServiceStateChange(&this, newInterface);

	public HRESULT OnSetRegisterModeComplete(IMbnRegistration* newInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSetRegisterModeComplete(&this, newInterface, requestID, status);
}

[CRepr]struct IMbnConnectionManager : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x201d, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR connectionID, IMbnConnection** mbnConnection) GetConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** mbnConnections) GetConnections;
	}


	public HRESULT GetConnection(PWSTR connectionID, IMbnConnection** mbnConnection) mut => VT.[Friend]GetConnection(&this, connectionID, mbnConnection);

	public HRESULT GetConnections(SAFEARRAY** mbnConnections) mut => VT.[Friend]GetConnections(&this, mbnConnections);
}

[CRepr]struct IMbnConnectionManagerEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x201e, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection* newConnection) OnConnectionArrival;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnection* oldConnection) OnConnectionRemoval;
	}


	public HRESULT OnConnectionArrival(IMbnConnection* newConnection) mut => VT.[Friend]OnConnectionArrival(&this, newConnection);

	public HRESULT OnConnectionRemoval(IMbnConnection* oldConnection) mut => VT.[Friend]OnConnectionRemoval(&this, oldConnection);
}

[CRepr]struct IMbnPinManager : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2005, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pinList) GetPinList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_PIN_TYPE pinType, IMbnPin** pin) GetPin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) GetPinState;
	}


	public HRESULT GetPinList(SAFEARRAY** pinList) mut => VT.[Friend]GetPinList(&this, pinList);

	public HRESULT GetPin(MBN_PIN_TYPE pinType, IMbnPin** pin) mut => VT.[Friend]GetPin(&this, pinType, pin);

	public HRESULT GetPinState(uint32* requestID) mut => VT.[Friend]GetPinState(&this, requestID);
}

[CRepr]struct IMbnPinManagerEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2006, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPinManager* pinManager) OnPinListAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPinManager* pinManager, MBN_PIN_INFO pinInfo, uint32 requestID, HRESULT status) OnGetPinStateComplete;
	}


	public HRESULT OnPinListAvailable(IMbnPinManager* pinManager) mut => VT.[Friend]OnPinListAvailable(&this, pinManager);

	public HRESULT OnGetPinStateComplete(IMbnPinManager* pinManager, MBN_PIN_INFO pinInfo, uint32 requestID, HRESULT status) mut => VT.[Friend]OnGetPinStateComplete(&this, pinManager, pinInfo, requestID, status);
}

[CRepr]struct IMbnPinEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2008, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPin* pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) OnEnableComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPin* pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) OnDisableComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPin* Pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) OnEnterComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPin* Pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) OnChangeComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPin* Pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) OnUnblockComplete;
	}


	public HRESULT OnEnableComplete(IMbnPin* pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) mut => VT.[Friend]OnEnableComplete(&this, pin, pinInfo, requestID, status);

	public HRESULT OnDisableComplete(IMbnPin* pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) mut => VT.[Friend]OnDisableComplete(&this, pin, pinInfo, requestID, status);

	public HRESULT OnEnterComplete(IMbnPin* Pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) mut => VT.[Friend]OnEnterComplete(&this, Pin, pinInfo, requestID, status);

	public HRESULT OnChangeComplete(IMbnPin* Pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) mut => VT.[Friend]OnChangeComplete(&this, Pin, pinInfo, requestID, status);

	public HRESULT OnUnblockComplete(IMbnPin* Pin, MBN_PIN_INFO* pinInfo, uint32 requestID, HRESULT status) mut => VT.[Friend]OnUnblockComplete(&this, Pin, pinInfo, requestID, status);
}

[CRepr]struct IMbnSubscriberInformation : IUnknown
{
	public new const Guid IID = .(0x459ecc43, 0xbcf5, 0x11dc, 0xa8, 0xa8, 0x00, 0x13, 0x21, 0xf1, 0x40, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* SubscriberID) get_SubscriberID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* SimIccID) get_SimIccID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** TelephoneNumbers) get_TelephoneNumbers;
	}


	public HRESULT get_SubscriberID(BSTR* SubscriberID) mut => VT.[Friend]get_SubscriberID(&this, SubscriberID);

	public HRESULT get_SimIccID(BSTR* SimIccID) mut => VT.[Friend]get_SimIccID(&this, SimIccID);

	public HRESULT get_TelephoneNumbers(SAFEARRAY** TelephoneNumbers) mut => VT.[Friend]get_TelephoneNumbers(&this, TelephoneNumbers);
}

[CRepr]struct IMbnSignal : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2003, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* signalStrength) GetSignalStrength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* signalError) GetSignalError;
	}


	public HRESULT GetSignalStrength(uint32* signalStrength) mut => VT.[Friend]GetSignalStrength(&this, signalStrength);

	public HRESULT GetSignalError(uint32* signalError) mut => VT.[Friend]GetSignalError(&this, signalError);
}

[CRepr]struct IMbnSignalEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2004, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSignal* newInterface) OnSignalStateChange;
	}


	public HRESULT OnSignalStateChange(IMbnSignal* newInterface) mut => VT.[Friend]OnSignalStateChange(&this, newInterface);
}

[CRepr]struct IMbnConnectionContext : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x200b, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** provisionedContexts) GetProvisionedContexts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_CONTEXT provisionedContexts, PWSTR providerID, uint32* requestID) SetProvisionedContext;
	}


	public HRESULT GetProvisionedContexts(SAFEARRAY** provisionedContexts) mut => VT.[Friend]GetProvisionedContexts(&this, provisionedContexts);

	public HRESULT SetProvisionedContext(MBN_CONTEXT provisionedContexts, PWSTR providerID, uint32* requestID) mut => VT.[Friend]SetProvisionedContext(&this, provisionedContexts, providerID, requestID);
}

[CRepr]struct IMbnConnectionContextEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x200c, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnectionContext* newInterface) OnProvisionedContextListChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnectionContext* newInterface, uint32 requestID, HRESULT status) OnSetProvisionedContextComplete;
	}


	public HRESULT OnProvisionedContextListChange(IMbnConnectionContext* newInterface) mut => VT.[Friend]OnProvisionedContextListChange(&this, newInterface);

	public HRESULT OnSetProvisionedContextComplete(IMbnConnectionContext* newInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSetProvisionedContextComplete(&this, newInterface, requestID, status);
}

[CRepr]struct IMbnConnectionProfileManager : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x200f, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* mbnInterface, SAFEARRAY** connectionProfiles) GetConnectionProfiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnInterface* mbnInterface, PWSTR profileName, IMbnConnectionProfile** connectionProfile) GetConnectionProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR xmlProfile) CreateConnectionProfile;
	}


	public HRESULT GetConnectionProfiles(IMbnInterface* mbnInterface, SAFEARRAY** connectionProfiles) mut => VT.[Friend]GetConnectionProfiles(&this, mbnInterface, connectionProfiles);

	public HRESULT GetConnectionProfile(IMbnInterface* mbnInterface, PWSTR profileName, IMbnConnectionProfile** connectionProfile) mut => VT.[Friend]GetConnectionProfile(&this, mbnInterface, profileName, connectionProfile);

	public HRESULT CreateConnectionProfile(PWSTR xmlProfile) mut => VT.[Friend]CreateConnectionProfile(&this, xmlProfile);
}

[CRepr]struct IMbnConnectionProfile : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2010, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* profileData) GetProfileXmlData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR strProfile) UpdateProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT GetProfileXmlData(BSTR* profileData) mut => VT.[Friend]GetProfileXmlData(&this, profileData);

	public HRESULT UpdateProfile(PWSTR strProfile) mut => VT.[Friend]UpdateProfile(&this, strProfile);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IMbnConnectionProfileEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2011, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnectionProfile* newProfile) OnProfileUpdate;
	}


	public HRESULT OnProfileUpdate(IMbnConnectionProfile* newProfile) mut => VT.[Friend]OnProfileUpdate(&this, newProfile);
}

[CRepr]struct IMbnSmsConfiguration : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2012, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* scAddress) get_ServiceCenterAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR scAddress) put_ServiceCenterAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* index) get_MaxMessageIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* shortMsgSize) get_CdmaShortMsgSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_FORMAT* smsFormat) get_SmsFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_FORMAT smsFormat) put_SmsFormat;
	}


	public HRESULT get_ServiceCenterAddress(BSTR* scAddress) mut => VT.[Friend]get_ServiceCenterAddress(&this, scAddress);

	public HRESULT put_ServiceCenterAddress(PWSTR scAddress) mut => VT.[Friend]put_ServiceCenterAddress(&this, scAddress);

	public HRESULT get_MaxMessageIndex(uint32* index) mut => VT.[Friend]get_MaxMessageIndex(&this, index);

	public HRESULT get_CdmaShortMsgSize(uint32* shortMsgSize) mut => VT.[Friend]get_CdmaShortMsgSize(&this, shortMsgSize);

	public HRESULT get_SmsFormat(MBN_SMS_FORMAT* smsFormat) mut => VT.[Friend]get_SmsFormat(&this, smsFormat);

	public HRESULT put_SmsFormat(MBN_SMS_FORMAT smsFormat) mut => VT.[Friend]put_SmsFormat(&this, smsFormat);
}

[CRepr]struct IMbnSmsReadMsgPdu : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2013, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Index) get_Index;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_MSG_STATUS* Status) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* PduData) get_PduData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** Message) get_Message;
	}


	public HRESULT get_Index(uint32* Index) mut => VT.[Friend]get_Index(&this, Index);

	public HRESULT get_Status(MBN_MSG_STATUS* Status) mut => VT.[Friend]get_Status(&this, Status);

	public HRESULT get_PduData(BSTR* PduData) mut => VT.[Friend]get_PduData(&this, PduData);

	public HRESULT get_Message(SAFEARRAY** Message) mut => VT.[Friend]get_Message(&this, Message);
}

[CRepr]struct IMbnSmsReadMsgTextCdma : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2014, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Index) get_Index;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_MSG_STATUS* Status) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Address) get_Address;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Timestamp) get_Timestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_CDMA_ENCODING* EncodingID) get_EncodingID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_CDMA_LANG* LanguageID) get_LanguageID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* SizeInCharacters) get_SizeInCharacters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** Message) get_Message;
	}


	public HRESULT get_Index(uint32* Index) mut => VT.[Friend]get_Index(&this, Index);

	public HRESULT get_Status(MBN_MSG_STATUS* Status) mut => VT.[Friend]get_Status(&this, Status);

	public HRESULT get_Address(BSTR* Address) mut => VT.[Friend]get_Address(&this, Address);

	public HRESULT get_Timestamp(BSTR* Timestamp) mut => VT.[Friend]get_Timestamp(&this, Timestamp);

	public HRESULT get_EncodingID(MBN_SMS_CDMA_ENCODING* EncodingID) mut => VT.[Friend]get_EncodingID(&this, EncodingID);

	public HRESULT get_LanguageID(MBN_SMS_CDMA_LANG* LanguageID) mut => VT.[Friend]get_LanguageID(&this, LanguageID);

	public HRESULT get_SizeInCharacters(uint32* SizeInCharacters) mut => VT.[Friend]get_SizeInCharacters(&this, SizeInCharacters);

	public HRESULT get_Message(SAFEARRAY** Message) mut => VT.[Friend]get_Message(&this, Message);
}

[CRepr]struct IMbnSms : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2015, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSmsConfiguration** smsConfiguration) GetSmsConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSmsConfiguration* smsConfiguration, uint32* requestID) SetSmsConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pduData, uint8 size, uint32* requestID) SmsSendPdu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR address, MBN_SMS_CDMA_ENCODING encoding, MBN_SMS_CDMA_LANG language, uint32 sizeInCharacters, SAFEARRAY* message, uint32* requestID) SmsSendCdma;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* message, uint32* requestID) SmsSendCdmaPdu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_FILTER* smsFilter, MBN_SMS_FORMAT smsFormat, uint32* requestID) SmsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_FILTER* smsFilter, uint32* requestID) SmsDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_SMS_STATUS_INFO* smsStatusInfo) GetSmsStatus;
	}


	public HRESULT GetSmsConfiguration(IMbnSmsConfiguration** smsConfiguration) mut => VT.[Friend]GetSmsConfiguration(&this, smsConfiguration);

	public HRESULT SetSmsConfiguration(IMbnSmsConfiguration* smsConfiguration, uint32* requestID) mut => VT.[Friend]SetSmsConfiguration(&this, smsConfiguration, requestID);

	public HRESULT SmsSendPdu(PWSTR pduData, uint8 size, uint32* requestID) mut => VT.[Friend]SmsSendPdu(&this, pduData, size, requestID);

	public HRESULT SmsSendCdma(PWSTR address, MBN_SMS_CDMA_ENCODING encoding, MBN_SMS_CDMA_LANG language, uint32 sizeInCharacters, SAFEARRAY* message, uint32* requestID) mut => VT.[Friend]SmsSendCdma(&this, address, encoding, language, sizeInCharacters, message, requestID);

	public HRESULT SmsSendCdmaPdu(SAFEARRAY* message, uint32* requestID) mut => VT.[Friend]SmsSendCdmaPdu(&this, message, requestID);

	public HRESULT SmsRead(MBN_SMS_FILTER* smsFilter, MBN_SMS_FORMAT smsFormat, uint32* requestID) mut => VT.[Friend]SmsRead(&this, smsFilter, smsFormat, requestID);

	public HRESULT SmsDelete(MBN_SMS_FILTER* smsFilter, uint32* requestID) mut => VT.[Friend]SmsDelete(&this, smsFilter, requestID);

	public HRESULT GetSmsStatus(MBN_SMS_STATUS_INFO* smsStatusInfo) mut => VT.[Friend]GetSmsStatus(&this, smsStatusInfo);
}

[CRepr]struct IMbnSmsEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2016, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms) OnSmsConfigurationChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms, uint32 requestID, HRESULT status) OnSetSmsConfigurationComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms, uint32 requestID, HRESULT status) OnSmsSendComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms, MBN_SMS_FORMAT smsFormat, SAFEARRAY* readMsgs, int16 moreMsgs, uint32 requestID, HRESULT status) OnSmsReadComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms, MBN_SMS_FORMAT smsFormat, SAFEARRAY* readMsgs) OnSmsNewClass0Message;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms, uint32 requestID, HRESULT status) OnSmsDeleteComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnSms* sms) OnSmsStatusChange;
	}


	public HRESULT OnSmsConfigurationChange(IMbnSms* sms) mut => VT.[Friend]OnSmsConfigurationChange(&this, sms);

	public HRESULT OnSetSmsConfigurationComplete(IMbnSms* sms, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSetSmsConfigurationComplete(&this, sms, requestID, status);

	public HRESULT OnSmsSendComplete(IMbnSms* sms, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSmsSendComplete(&this, sms, requestID, status);

	public HRESULT OnSmsReadComplete(IMbnSms* sms, MBN_SMS_FORMAT smsFormat, SAFEARRAY* readMsgs, int16 moreMsgs, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSmsReadComplete(&this, sms, smsFormat, readMsgs, moreMsgs, requestID, status);

	public HRESULT OnSmsNewClass0Message(IMbnSms* sms, MBN_SMS_FORMAT smsFormat, SAFEARRAY* readMsgs) mut => VT.[Friend]OnSmsNewClass0Message(&this, sms, smsFormat, readMsgs);

	public HRESULT OnSmsDeleteComplete(IMbnSms* sms, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSmsDeleteComplete(&this, sms, requestID, status);

	public HRESULT OnSmsStatusChange(IMbnSms* sms) mut => VT.[Friend]OnSmsStatusChange(&this, sms);
}

[CRepr]struct IMbnServiceActivation : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2017, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* vendorSpecificData, uint32* requestID) Activate;
	}


	public HRESULT Activate(SAFEARRAY* vendorSpecificData, uint32* requestID) mut => VT.[Friend]Activate(&this, vendorSpecificData, requestID);
}

[CRepr]struct IMbnServiceActivationEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2018, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnServiceActivation* serviceActivation, SAFEARRAY* vendorSpecificData, uint32 requestID, HRESULT status, uint32 networkError) OnActivationComplete;
	}


	public HRESULT OnActivationComplete(IMbnServiceActivation* serviceActivation, SAFEARRAY* vendorSpecificData, uint32 requestID, HRESULT status, uint32 networkError) mut => VT.[Friend]OnActivationComplete(&this, serviceActivation, vendorSpecificData, requestID, status, networkError);
}

[CRepr]struct IMbnVendorSpecificOperation : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2019, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* vendorSpecificData, uint32* requestID) SetVendorSpecific;
	}


	public HRESULT SetVendorSpecific(SAFEARRAY* vendorSpecificData, uint32* requestID) mut => VT.[Friend]SetVendorSpecific(&this, vendorSpecificData, requestID);
}

[CRepr]struct IMbnVendorSpecificEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x201a, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnVendorSpecificOperation* vendorOperation, SAFEARRAY* vendorSpecificData) OnEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnVendorSpecificOperation* vendorOperation, SAFEARRAY* vendorSpecificData, uint32 requestID) OnSetVendorSpecificComplete;
	}


	public HRESULT OnEventNotification(IMbnVendorSpecificOperation* vendorOperation, SAFEARRAY* vendorSpecificData) mut => VT.[Friend]OnEventNotification(&this, vendorOperation, vendorSpecificData);

	public HRESULT OnSetVendorSpecificComplete(IMbnVendorSpecificOperation* vendorOperation, SAFEARRAY* vendorSpecificData, uint32 requestID) mut => VT.[Friend]OnSetVendorSpecificComplete(&this, vendorOperation, vendorSpecificData, requestID);
}

[CRepr]struct IMbnConnectionProfileManagerEvents : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x201f, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnectionProfile* newConnectionProfile) OnConnectionProfileArrival;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnConnectionProfile* oldConnectionProfile) OnConnectionProfileRemoval;
	}


	public HRESULT OnConnectionProfileArrival(IMbnConnectionProfile* newConnectionProfile) mut => VT.[Friend]OnConnectionProfileArrival(&this, newConnectionProfile);

	public HRESULT OnConnectionProfileRemoval(IMbnConnectionProfile* oldConnectionProfile) mut => VT.[Friend]OnConnectionProfileRemoval(&this, oldConnectionProfile);
}

[CRepr]struct IMbnRadio : IUnknown
{
	public new const Guid IID = .(0xdccccab6, 0x201f, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_RADIO* SoftwareRadioState) get_SoftwareRadioState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_RADIO* HardwareRadioState) get_HardwareRadioState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_RADIO radioState, uint32* requestID) SetSoftwareRadioState;
	}


	public HRESULT get_SoftwareRadioState(MBN_RADIO* SoftwareRadioState) mut => VT.[Friend]get_SoftwareRadioState(&this, SoftwareRadioState);

	public HRESULT get_HardwareRadioState(MBN_RADIO* HardwareRadioState) mut => VT.[Friend]get_HardwareRadioState(&this, HardwareRadioState);

	public HRESULT SetSoftwareRadioState(MBN_RADIO radioState, uint32* requestID) mut => VT.[Friend]SetSoftwareRadioState(&this, radioState, requestID);
}

[CRepr]struct IMbnRadioEvents : IUnknown
{
	public new const Guid IID = .(0xdcdddab6, 0x201f, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnRadio* newInterface) OnRadioStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnRadio* newInterface, uint32 requestID, HRESULT status) OnSetSoftwareRadioStateComplete;
	}


	public HRESULT OnRadioStateChange(IMbnRadio* newInterface) mut => VT.[Friend]OnRadioStateChange(&this, newInterface);

	public HRESULT OnSetSoftwareRadioStateComplete(IMbnRadio* newInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSetSoftwareRadioStateComplete(&this, newInterface, requestID, status);
}

[CRepr]struct IMbnMultiCarrier : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2020, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_PROVIDER2* homeProvider, uint32* requestID) SetHomeProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** preferredMulticarrierProviders) GetPreferredProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* age, SAFEARRAY** visibleProviders) GetVisibleProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** cellularClasses) GetSupportedCellularClasses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_CELLULAR_CLASS* currentCellularClass) GetCurrentCellularClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) ScanNetwork;
	}


	public HRESULT SetHomeProvider(MBN_PROVIDER2* homeProvider, uint32* requestID) mut => VT.[Friend]SetHomeProvider(&this, homeProvider, requestID);

	public HRESULT GetPreferredProviders(SAFEARRAY** preferredMulticarrierProviders) mut => VT.[Friend]GetPreferredProviders(&this, preferredMulticarrierProviders);

	public HRESULT GetVisibleProviders(uint32* age, SAFEARRAY** visibleProviders) mut => VT.[Friend]GetVisibleProviders(&this, age, visibleProviders);

	public HRESULT GetSupportedCellularClasses(SAFEARRAY** cellularClasses) mut => VT.[Friend]GetSupportedCellularClasses(&this, cellularClasses);

	public HRESULT GetCurrentCellularClass(MBN_CELLULAR_CLASS* currentCellularClass) mut => VT.[Friend]GetCurrentCellularClass(&this, currentCellularClass);

	public HRESULT ScanNetwork(uint32* requestID) mut => VT.[Friend]ScanNetwork(&this, requestID);
}

[CRepr]struct IMbnMultiCarrierEvents : IUnknown
{
	public new const Guid IID = .(0xdcdddab6, 0x2021, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnMultiCarrier* mbnInterface, uint32 requestID, HRESULT status) OnSetHomeProviderComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnMultiCarrier* mbnInterface) OnCurrentCellularClassChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnMultiCarrier* mbnInterface) OnPreferredProvidersChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnMultiCarrier* mbnInterface, uint32 requestID, HRESULT status) OnScanNetworkComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnMultiCarrier* mbnInterface) OnInterfaceCapabilityChange;
	}


	public HRESULT OnSetHomeProviderComplete(IMbnMultiCarrier* mbnInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnSetHomeProviderComplete(&this, mbnInterface, requestID, status);

	public HRESULT OnCurrentCellularClassChange(IMbnMultiCarrier* mbnInterface) mut => VT.[Friend]OnCurrentCellularClassChange(&this, mbnInterface);

	public HRESULT OnPreferredProvidersChange(IMbnMultiCarrier* mbnInterface) mut => VT.[Friend]OnPreferredProvidersChange(&this, mbnInterface);

	public HRESULT OnScanNetworkComplete(IMbnMultiCarrier* mbnInterface, uint32 requestID, HRESULT status) mut => VT.[Friend]OnScanNetworkComplete(&this, mbnInterface, requestID, status);

	public HRESULT OnInterfaceCapabilityChange(IMbnMultiCarrier* mbnInterface) mut => VT.[Friend]OnInterfaceCapabilityChange(&this, mbnInterface);
}

[CRepr]struct IMbnDeviceServiceStateEvents : IUnknown
{
	public new const Guid IID = .(0x5d3ff196, 0x89ee, 0x49d8, 0x8b, 0x60, 0x33, 0xff, 0xdd, 0xff, 0xc5, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR interfaceID, MBN_DEVICE_SERVICE_SESSIONS_STATE stateChange) OnSessionsStateChange;
	}


	public HRESULT OnSessionsStateChange(BSTR interfaceID, MBN_DEVICE_SERVICE_SESSIONS_STATE stateChange) mut => VT.[Friend]OnSessionsStateChange(&this, interfaceID, stateChange);
}

[CRepr]struct IMbnDeviceServicesManager : IUnknown
{
	public new const Guid IID = .(0x20a26258, 0x6811, 0x4478, 0xac, 0x1d, 0x13, 0x32, 0x4e, 0x45, 0xe4, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR networkInterfaceID, IMbnDeviceServicesContext** mbnDevicesContext) GetDeviceServicesContext;
	}


	public HRESULT GetDeviceServicesContext(BSTR networkInterfaceID, IMbnDeviceServicesContext** mbnDevicesContext) mut => VT.[Friend]GetDeviceServicesContext(&this, networkInterfaceID, mbnDevicesContext);
}

[CRepr]struct IMbnDeviceServicesContext : IUnknown
{
	public new const Guid IID = .(0xfc5ac347, 0x1592, 0x4068, 0x80, 0xbb, 0x6a, 0x57, 0x58, 0x01, 0x50, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** deviceServices) EnumerateDeviceServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR deviceServiceID, IMbnDeviceService** mbnDeviceService) GetDeviceService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* maxCommandSize) get_MaxCommandSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* maxDataSize) get_MaxDataSize;
	}


	public HRESULT EnumerateDeviceServices(SAFEARRAY** deviceServices) mut => VT.[Friend]EnumerateDeviceServices(&this, deviceServices);

	public HRESULT GetDeviceService(BSTR deviceServiceID, IMbnDeviceService** mbnDeviceService) mut => VT.[Friend]GetDeviceService(&this, deviceServiceID, mbnDeviceService);

	public HRESULT get_MaxCommandSize(uint32* maxCommandSize) mut => VT.[Friend]get_MaxCommandSize(&this, maxCommandSize);

	public HRESULT get_MaxDataSize(uint32* maxDataSize) mut => VT.[Friend]get_MaxDataSize(&this, maxDataSize);
}

[CRepr]struct IMbnDeviceServicesEvents : IUnknown
{
	public new const Guid IID = .(0x0a900c19, 0x6824, 0x4e97, 0xb7, 0x6e, 0xcf, 0x23, 0x9d, 0x0c, 0xa6, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, SAFEARRAY* commandIDList, HRESULT status, uint32 requestID) OnQuerySupportedCommandsComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) OnOpenCommandSessionComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) OnCloseCommandSessionComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, uint32 responseID, SAFEARRAY* deviceServiceData, HRESULT status, uint32 requestID) OnSetCommandComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, uint32 responseID, SAFEARRAY* deviceServiceData, HRESULT status, uint32 requestID) OnQueryCommandComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, uint32 eventID, SAFEARRAY* deviceServiceData) OnEventNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) OnOpenDataSessionComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) OnCloseDataSessionComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) OnWriteDataComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnDeviceService* deviceService, SAFEARRAY* deviceServiceData) OnReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR interfaceID, MBN_DEVICE_SERVICES_INTERFACE_STATE stateChange) OnInterfaceStateChange;
	}


	public HRESULT OnQuerySupportedCommandsComplete(IMbnDeviceService* deviceService, SAFEARRAY* commandIDList, HRESULT status, uint32 requestID) mut => VT.[Friend]OnQuerySupportedCommandsComplete(&this, deviceService, commandIDList, status, requestID);

	public HRESULT OnOpenCommandSessionComplete(IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) mut => VT.[Friend]OnOpenCommandSessionComplete(&this, deviceService, status, requestID);

	public HRESULT OnCloseCommandSessionComplete(IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) mut => VT.[Friend]OnCloseCommandSessionComplete(&this, deviceService, status, requestID);

	public HRESULT OnSetCommandComplete(IMbnDeviceService* deviceService, uint32 responseID, SAFEARRAY* deviceServiceData, HRESULT status, uint32 requestID) mut => VT.[Friend]OnSetCommandComplete(&this, deviceService, responseID, deviceServiceData, status, requestID);

	public HRESULT OnQueryCommandComplete(IMbnDeviceService* deviceService, uint32 responseID, SAFEARRAY* deviceServiceData, HRESULT status, uint32 requestID) mut => VT.[Friend]OnQueryCommandComplete(&this, deviceService, responseID, deviceServiceData, status, requestID);

	public HRESULT OnEventNotification(IMbnDeviceService* deviceService, uint32 eventID, SAFEARRAY* deviceServiceData) mut => VT.[Friend]OnEventNotification(&this, deviceService, eventID, deviceServiceData);

	public HRESULT OnOpenDataSessionComplete(IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) mut => VT.[Friend]OnOpenDataSessionComplete(&this, deviceService, status, requestID);

	public HRESULT OnCloseDataSessionComplete(IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) mut => VT.[Friend]OnCloseDataSessionComplete(&this, deviceService, status, requestID);

	public HRESULT OnWriteDataComplete(IMbnDeviceService* deviceService, HRESULT status, uint32 requestID) mut => VT.[Friend]OnWriteDataComplete(&this, deviceService, status, requestID);

	public HRESULT OnReadData(IMbnDeviceService* deviceService, SAFEARRAY* deviceServiceData) mut => VT.[Friend]OnReadData(&this, deviceService, deviceServiceData);

	public HRESULT OnInterfaceStateChange(BSTR interfaceID, MBN_DEVICE_SERVICES_INTERFACE_STATE stateChange) mut => VT.[Friend]OnInterfaceStateChange(&this, interfaceID, stateChange);
}

[CRepr]struct IMbnDeviceService : IUnknown
{
	public new const Guid IID = .(0xb3bb9a71, 0xdc70, 0x4be9, 0xa4, 0xda, 0x78, 0x86, 0xae, 0x8b, 0x19, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) QuerySupportedCommands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) OpenCommandSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) CloseCommandSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandID, SAFEARRAY* deviceServiceData, uint32* requestID) SetCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandID, SAFEARRAY* deviceServiceData, uint32* requestID) QueryCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) OpenDataSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* requestID) CloseDataSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* deviceServiceData, uint32* requestID) WriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* InterfaceID) get_InterfaceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* DeviceServiceID) get_DeviceServiceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* value) get_IsCommandSessionOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* value) get_IsDataSessionOpen;
	}


	public HRESULT QuerySupportedCommands(uint32* requestID) mut => VT.[Friend]QuerySupportedCommands(&this, requestID);

	public HRESULT OpenCommandSession(uint32* requestID) mut => VT.[Friend]OpenCommandSession(&this, requestID);

	public HRESULT CloseCommandSession(uint32* requestID) mut => VT.[Friend]CloseCommandSession(&this, requestID);

	public HRESULT SetCommand(uint32 commandID, SAFEARRAY* deviceServiceData, uint32* requestID) mut => VT.[Friend]SetCommand(&this, commandID, deviceServiceData, requestID);

	public HRESULT QueryCommand(uint32 commandID, SAFEARRAY* deviceServiceData, uint32* requestID) mut => VT.[Friend]QueryCommand(&this, commandID, deviceServiceData, requestID);

	public HRESULT OpenDataSession(uint32* requestID) mut => VT.[Friend]OpenDataSession(&this, requestID);

	public HRESULT CloseDataSession(uint32* requestID) mut => VT.[Friend]CloseDataSession(&this, requestID);

	public HRESULT WriteData(SAFEARRAY* deviceServiceData, uint32* requestID) mut => VT.[Friend]WriteData(&this, deviceServiceData, requestID);

	public HRESULT get_InterfaceID(BSTR* InterfaceID) mut => VT.[Friend]get_InterfaceID(&this, InterfaceID);

	public HRESULT get_DeviceServiceID(BSTR* DeviceServiceID) mut => VT.[Friend]get_DeviceServiceID(&this, DeviceServiceID);

	public HRESULT get_IsCommandSessionOpen(BOOL* value) mut => VT.[Friend]get_IsCommandSessionOpen(&this, value);

	public HRESULT get_IsDataSessionOpen(BOOL* value) mut => VT.[Friend]get_IsDataSessionOpen(&this, value);
}

[CRepr]struct IMbnPin : IUnknown
{
	public new const Guid IID = .(0xdcbbbab6, 0x2007, 0x4bbb, 0xaa, 0xee, 0x33, 0x8e, 0x36, 0x8a, 0xf6, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_PIN_TYPE* PinType) get_PinType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_PIN_FORMAT* PinFormat) get_PinFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* PinLengthMin) get_PinLengthMin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* PinLengthMax) get_PinLengthMax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MBN_PIN_MODE* PinMode) get_PinMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pin, uint32* requestID) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pin, uint32* requestID) Disable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pin, uint32* requestID) Enter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pin, PWSTR newPin, uint32* requestID) Change;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR puk, PWSTR newPin, uint32* requestID) Unblock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMbnPinManager** pinManager) GetPinManager;
	}


	public HRESULT get_PinType(MBN_PIN_TYPE* PinType) mut => VT.[Friend]get_PinType(&this, PinType);

	public HRESULT get_PinFormat(MBN_PIN_FORMAT* PinFormat) mut => VT.[Friend]get_PinFormat(&this, PinFormat);

	public HRESULT get_PinLengthMin(uint32* PinLengthMin) mut => VT.[Friend]get_PinLengthMin(&this, PinLengthMin);

	public HRESULT get_PinLengthMax(uint32* PinLengthMax) mut => VT.[Friend]get_PinLengthMax(&this, PinLengthMax);

	public HRESULT get_PinMode(MBN_PIN_MODE* PinMode) mut => VT.[Friend]get_PinMode(&this, PinMode);

	public HRESULT Enable(PWSTR pin, uint32* requestID) mut => VT.[Friend]Enable(&this, pin, requestID);

	public HRESULT Disable(PWSTR pin, uint32* requestID) mut => VT.[Friend]Disable(&this, pin, requestID);

	public HRESULT Enter(PWSTR pin, uint32* requestID) mut => VT.[Friend]Enter(&this, pin, requestID);

	public HRESULT Change(PWSTR pin, PWSTR newPin, uint32* requestID) mut => VT.[Friend]Change(&this, pin, newPin, requestID);

	public HRESULT Unblock(PWSTR puk, PWSTR newPin, uint32* requestID) mut => VT.[Friend]Unblock(&this, puk, newPin, requestID);

	public HRESULT GetPinManager(IMbnPinManager** pinManager) mut => VT.[Friend]GetPinManager(&this, pinManager);
}

#endregion
