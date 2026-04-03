using Win32.Foundation;
using System;

namespace Win32.Security.NetworkAccessProtection;

#region Constants
public static
{
	public const uint32 maxSoHAttributeCount = 100;
	public const uint32 maxSoHAttributeSize = 4000;
	public const uint32 minNetworkSoHSize = 12;
	public const uint32 maxNetworkSoHSize = 4000;
	public const uint32 maxStringLength = 1024;
	public const uint32 maxSystemHealthEntityCount = 20;
	public const uint32 maxEnforcerCount = 20;
	public const uint32 maxPrivateDataSize = 200;
	public const uint32 maxConnectionCountPerEnforcer = 20;
	public const uint32 freshSoHRequest = 1;
	public const uint32 shaFixup = 1;
	public const uint32 failureCategoryCount = 5;
	public const uint32 ComponentTypeEnforcementClientSoH = 1;
	public const uint32 ComponentTypeEnforcementClientRp = 2;
	public const uint32 percentageNotSupported = 101;
}
#endregion

#region Enums

[AllowDuplicates]
public enum IsolationState : int32
{
	isolationStateNotRestricted = 1,
	isolationStateInProbation = 2,
	isolationStateRestrictedAccess = 3,
}


[AllowDuplicates]
public enum ExtendedIsolationState : int32
{
	extendedIsolationStateNoData = 0,
	extendedIsolationStateTransition = 1,
	extendedIsolationStateInfected = 2,
	extendedIsolationStateUnknown = 3,
}


[AllowDuplicates]
public enum NapTracingLevel : int32
{
	tracingLevelUndefined = 0,
	tracingLevelBasic = 1,
	tracingLevelAdvanced = 2,
	tracingLevelDebug = 3,
}


[AllowDuplicates]
public enum FailureCategory : int32
{
	failureCategoryNone = 0,
	failureCategoryOther = 1,
	failureCategoryClientComponent = 2,
	failureCategoryClientCommunication = 3,
	failureCategoryServerComponent = 4,
	failureCategoryServerCommunication = 5,
}


[AllowDuplicates]
public enum FixupState : int32
{
	fixupStateSuccess = 0,
	fixupStateInProgress = 1,
	fixupStateCouldNotUpdate = 2,
}


[AllowDuplicates]
public enum NapNotifyType : int32
{
	napNotifyTypeUnknown = 0,
	napNotifyTypeServiceState = 1,
	napNotifyTypeQuarState = 2,
}


[AllowDuplicates]
public enum RemoteConfigurationType : int32
{
	remoteConfigTypeMachine = 1,
	remoteConfigTypeConfigBlob = 2,
}

#endregion


#region Structs
[CRepr]
public struct CountedString
{
	public uint16 length;
	public PWSTR string;
}

[CRepr]
public struct IsolationInfo
{
	public IsolationState isolationState;
	public FILETIME probEndTime;
	public CountedString failureUrl;
}

[CRepr]
public struct IsolationInfoEx
{
	public IsolationState isolationState;
	public ExtendedIsolationState extendedIsolationState;
	public FILETIME probEndTime;
	public CountedString failureUrl;
}

[CRepr]
public struct FailureCategoryMapping
{
	public BOOL[5] mappingCompliance;
}

[CRepr]
public struct CorrelationId
{
	public Guid connId;
	public FILETIME timeStamp;
}

[CRepr]
public struct ResultCodes
{
	public uint16 count;
	public HRESULT* results;
}

[CRepr]
public struct Ipv4Address
{
	public uint8[4] addr;
}

[CRepr]
public struct Ipv6Address
{
	public uint8[16] addr;
}

[CRepr]
public struct FixupInfo
{
	public FixupState state;
	public uint8 percentage;
	public ResultCodes resultCodes;
	public uint32 fixupMsgId;
}

[CRepr]
public struct SystemHealthAgentState
{
	public uint32 id;
	public ResultCodes shaResultCodes;
	public FailureCategory failureCategory;
	public FixupInfo fixupInfo;
}

[CRepr]
public struct SoHAttribute
{
	public uint16 type;
	public uint16 size;
	public uint8* value;
}

[CRepr]
public struct SoH
{
	public uint16 count;
	public SoHAttribute* attributes;
}

[CRepr]
public struct NetworkSoH
{
	public uint16 size;
	public uint8* data;
}

[CRepr]
public struct PrivateData
{
	public uint16 size;
	public uint8* data;
}

[CRepr]
public struct NapComponentRegistrationInfo
{
	public uint32 id;
	public CountedString friendlyName;
	public CountedString description;
	public CountedString version;
	public CountedString vendorName;
	public Guid infoClsid;
	public Guid configClsid;
	public FILETIME registrationDate;
	public uint32 componentType;
}

#endregion
