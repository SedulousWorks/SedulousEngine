using Win32.Foundation;
using System;

namespace Win32.System.EventCollector;

#region Constants
public static
{
	public const uint32 EC_VARIANT_TYPE_MASK = 127;
	public const uint32 EC_VARIANT_TYPE_ARRAY = 128;
	public const uint32 EC_READ_ACCESS = 1;
	public const uint32 EC_WRITE_ACCESS = 2;
	public const uint32 EC_OPEN_ALWAYS = 0;
	public const uint32 EC_CREATE_NEW = 1;
	public const uint32 EC_OPEN_EXISTING = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum EC_SUBSCRIPTION_PROPERTY_ID : int32
{
	EcSubscriptionEnabled = 0,
	EcSubscriptionEventSources = 1,
	EcSubscriptionEventSourceAddress = 2,
	EcSubscriptionEventSourceEnabled = 3,
	EcSubscriptionEventSourceUserName = 4,
	EcSubscriptionEventSourcePassword = 5,
	EcSubscriptionDescription = 6,
	EcSubscriptionURI = 7,
	EcSubscriptionConfigurationMode = 8,
	EcSubscriptionExpires = 9,
	EcSubscriptionQuery = 10,
	EcSubscriptionTransportName = 11,
	EcSubscriptionTransportPort = 12,
	EcSubscriptionDeliveryMode = 13,
	EcSubscriptionDeliveryMaxItems = 14,
	EcSubscriptionDeliveryMaxLatencyTime = 15,
	EcSubscriptionHeartbeatInterval = 16,
	EcSubscriptionLocale = 17,
	EcSubscriptionContentFormat = 18,
	EcSubscriptionLogFile = 19,
	EcSubscriptionPublisherName = 20,
	EcSubscriptionCredentialsType = 21,
	EcSubscriptionCommonUserName = 22,
	EcSubscriptionCommonPassword = 23,
	EcSubscriptionHostName = 24,
	EcSubscriptionReadExistingEvents = 25,
	EcSubscriptionDialect = 26,
	EcSubscriptionType = 27,
	EcSubscriptionAllowedIssuerCAs = 28,
	EcSubscriptionAllowedSubjects = 29,
	EcSubscriptionDeniedSubjects = 30,
	EcSubscriptionAllowedSourceDomainComputers = 31,
	EcSubscriptionPropertyIdEND = 32,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_CREDENTIALS_TYPE : int32
{
	EcSubscriptionCredDefault = 0,
	EcSubscriptionCredNegotiate = 1,
	EcSubscriptionCredDigest = 2,
	EcSubscriptionCredBasic = 3,
	EcSubscriptionCredLocalMachine = 4,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_TYPE : int32
{
	EcSubscriptionTypeSourceInitiated = 0,
	EcSubscriptionTypeCollectorInitiated = 1,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_RUNTIME_STATUS_INFO_ID : int32
{
	EcSubscriptionRunTimeStatusActive = 0,
	EcSubscriptionRunTimeStatusLastError = 1,
	EcSubscriptionRunTimeStatusLastErrorMessage = 2,
	EcSubscriptionRunTimeStatusLastErrorTime = 3,
	EcSubscriptionRunTimeStatusNextRetryTime = 4,
	EcSubscriptionRunTimeStatusEventSources = 5,
	EcSubscriptionRunTimeStatusLastHeartbeatTime = 6,
	EcSubscriptionRunTimeStatusInfoIdEND = 7,
}


[AllowDuplicates]
public enum EC_VARIANT_TYPE : int32
{
	EcVarTypeNull = 0,
	EcVarTypeBoolean = 1,
	EcVarTypeUInt32 = 2,
	EcVarTypeDateTime = 3,
	EcVarTypeString = 4,
	EcVarObjectArrayPropertyHandle = 5,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_CONFIGURATION_MODE : int32
{
	EcConfigurationModeNormal = 0,
	EcConfigurationModeCustom = 1,
	EcConfigurationModeMinLatency = 2,
	EcConfigurationModeMinBandwidth = 3,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_DELIVERY_MODE : int32
{
	EcDeliveryModePull = 1,
	EcDeliveryModePush = 2,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_CONTENT_FORMAT : int32
{
	EcContentFormatEvents = 1,
	EcContentFormatRenderedText = 2,
}


[AllowDuplicates]
public enum EC_SUBSCRIPTION_RUNTIME_STATUS_ACTIVE_STATUS : int32
{
	EcRuntimeStatusActiveStatusDisabled = 1,
	EcRuntimeStatusActiveStatusActive = 2,
	EcRuntimeStatusActiveStatusInactive = 3,
	EcRuntimeStatusActiveStatusTrying = 4,
}

#endregion


#region Structs
[CRepr]
public struct EC_VARIANT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public BOOL BooleanVal;
		public uint32 UInt32Val;
		public uint64 DateTimeVal;
		public PWSTR StringVal;
		public uint8* BinaryVal;
		public BOOL* BooleanArr;
		public int32* Int32Arr;
		public PWSTR* StringArr;
		public int PropertyHandleVal;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 Count;
	public uint32 Type;
}

#endregion

#region Functions
public static
{
	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EcOpenSubscriptionEnum(uint32 Flags);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcEnumNextSubscription(int SubscriptionEnum, uint32 SubscriptionNameBufferSize, char16* SubscriptionNameBuffer, uint32* SubscriptionNameBufferUsed);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int EcOpenSubscription(PWSTR SubscriptionName, uint32 AccessMask, uint32 Flags);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcSetSubscriptionProperty(int Subscription, EC_SUBSCRIPTION_PROPERTY_ID PropertyId, uint32 Flags, EC_VARIANT* PropertyValue);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcGetSubscriptionProperty(int Subscription, EC_SUBSCRIPTION_PROPERTY_ID PropertyId, uint32 Flags, uint32 PropertyValueBufferSize, EC_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcSaveSubscription(int Subscription, uint32 Flags);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcDeleteSubscription(PWSTR SubscriptionName, uint32 Flags);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcGetObjectArraySize(int ObjectArray, uint32* ObjectArraySize);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcSetObjectArrayProperty(int ObjectArray, EC_SUBSCRIPTION_PROPERTY_ID PropertyId, uint32 ArrayIndex, uint32 Flags, EC_VARIANT* PropertyValue);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcGetObjectArrayProperty(int ObjectArray, EC_SUBSCRIPTION_PROPERTY_ID PropertyId, uint32 ArrayIndex, uint32 Flags, uint32 PropertyValueBufferSize, EC_VARIANT* PropertyValueBuffer, uint32* PropertyValueBufferUsed);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcInsertObjectArrayElement(int ObjectArray, uint32 ArrayIndex);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcRemoveObjectArrayElement(int ObjectArray, uint32 ArrayIndex);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcGetSubscriptionRunTimeStatus(PWSTR SubscriptionName, EC_SUBSCRIPTION_RUNTIME_STATUS_INFO_ID StatusInfoId, PWSTR EventSourceName, uint32 Flags, uint32 StatusValueBufferSize, EC_VARIANT* StatusValueBuffer, uint32* StatusValueBufferUsed);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcRetrySubscription(PWSTR SubscriptionName, PWSTR EventSourceName, uint32 Flags);

	[Import("WecApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EcClose(int Object);

}
#endregion
