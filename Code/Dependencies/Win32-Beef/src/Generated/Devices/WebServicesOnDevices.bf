using Win32.Security.Cryptography;
using Win32.Foundation;
using Win32.System.Com;
using Win32.Networking.WinSock;
using System;

namespace Win32.Devices.WebServicesOnDevices;

#region Constants
public static
{
	public const String WSD_DEFAULT_HOSTING_ADDRESS = "http://*:5357/";
	public const String WSD_DEFAULT_SECURE_HOSTING_ADDRESS = "https://*:5358/";
	public const String WSD_DEFAULT_EVENTING_ADDRESS = "http://*:5357/";
	public const uint32 WSDAPI_OPTION_MAX_INBOUND_MESSAGE_SIZE = 1;
	public const uint32 WSDAPI_OPTION_TRACE_XML_TO_DEBUGGER = 2;
	public const uint32 WSDAPI_OPTION_TRACE_XML_TO_FILE = 3;
	public const uint32 WSDAPI_SSL_CERT_APPLY_DEFAULT_CHECKS = 0;
	public const uint32 WSDAPI_SSL_CERT_IGNORE_REVOCATION = 1;
	public const uint32 WSDAPI_SSL_CERT_IGNORE_EXPIRY = 2;
	public const uint32 WSDAPI_SSL_CERT_IGNORE_WRONG_USAGE = 4;
	public const uint32 WSDAPI_SSL_CERT_IGNORE_UNKNOWN_CA = 8;
	public const uint32 WSDAPI_SSL_CERT_IGNORE_INVALID_CN = 16;
	public const uint32 WSDAPI_COMPACTSIG_ACCEPT_ALL_MESSAGES = 1;
	public const uint32 WSD_SECURITY_HTTP_AUTH_SCHEME_NEGOTIATE = 1;
	public const uint32 WSD_SECURITY_HTTP_AUTH_SCHEME_NTLM = 2;
	public const uint32 WSDAPI_ADDRESSFAMILY_IPV4 = 1;
	public const uint32 WSDAPI_ADDRESSFAMILY_IPV6 = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WSD_CONFIG_PARAM_TYPE : int32
{
	WSD_CONFIG_MAX_INBOUND_MESSAGE_SIZE = 1,
	WSD_CONFIG_MAX_OUTBOUND_MESSAGE_SIZE = 2,
	WSD_SECURITY_SSL_CERT_FOR_CLIENT_AUTH = 3,
	WSD_SECURITY_SSL_SERVER_CERT_VALIDATION = 4,
	WSD_SECURITY_SSL_CLIENT_CERT_VALIDATION = 5,
	WSD_SECURITY_SSL_NEGOTIATE_CLIENT_CERT = 6,
	WSD_SECURITY_COMPACTSIG_SIGNING_CERT = 7,
	WSD_SECURITY_COMPACTSIG_VALIDATION = 8,
	WSD_CONFIG_HOSTING_ADDRESSES = 9,
	WSD_CONFIG_DEVICE_ADDRESSES = 10,
	WSD_SECURITY_REQUIRE_HTTP_CLIENT_AUTH = 11,
	WSD_SECURITY_REQUIRE_CLIENT_CERT_OR_HTTP_CLIENT_AUTH = 12,
	WSD_SECURITY_USE_HTTP_CLIENT_AUTH = 13,
}


[AllowDuplicates]
public enum WSDUdpMessageType : int32
{
	ONE_WAY = 0,
	TWO_WAY = 1,
}


[AllowDuplicates]
public enum WSDXML_OP : int32
{
	OpNone = 0,
	OpEndOfTable = 1,
	OpBeginElement_ = 2,
	OpBeginAnyElement = 3,
	OpEndElement = 4,
	OpElement_ = 5,
	OpAnyElement = 6,
	OpAnyElements = 7,
	OpAnyText = 8,
	OpAttribute_ = 9,
	OpBeginChoice = 10,
	OpEndChoice = 11,
	OpBeginSequence = 12,
	OpEndSequence = 13,
	OpBeginAll = 14,
	OpEndAll = 15,
	OpAnything = 16,
	OpAnyNumber = 17,
	OpOneOrMore = 18,
	OpOptional = 19,
	OpFormatBool_ = 20,
	OpFormatInt8_ = 21,
	OpFormatInt16_ = 22,
	OpFormatInt32_ = 23,
	OpFormatInt64_ = 24,
	OpFormatUInt8_ = 25,
	OpFormatUInt16_ = 26,
	OpFormatUInt32_ = 27,
	OpFormatUInt64_ = 28,
	OpFormatUnicodeString_ = 29,
	OpFormatDom_ = 30,
	OpFormatStruct_ = 31,
	OpFormatUri_ = 32,
	OpFormatUuidUri_ = 33,
	OpFormatName_ = 34,
	OpFormatListInsertTail_ = 35,
	OpFormatType_ = 36,
	OpFormatDynamicType_ = 37,
	OpFormatLookupType_ = 38,
	OpFormatDuration_ = 39,
	OpFormatDateTime_ = 40,
	OpFormatFloat_ = 41,
	OpFormatDouble_ = 42,
	OpProcess_ = 43,
	OpQualifiedAttribute_ = 44,
	OpFormatXMLDeclaration_ = 45,
	OpFormatMax = 46,
}


[AllowDuplicates]
public enum DeviceDiscoveryMechanism : int32
{
	MulticastDiscovery = 0,
	DirectedDiscovery = 1,
	SecureDirectedDiscovery = 2,
}


[AllowDuplicates]
public enum WSD_PROTOCOL_TYPE : int32
{
	WSD_PT_NONE = 0,
	WSD_PT_UDP = 1,
	WSD_PT_HTTP = 2,
	WSD_PT_HTTPS = 4,
	WSD_PT_ALL = 255,
}


[AllowDuplicates]
public enum WSDEventType : int32
{
	WSDET_NONE = 0,
	WSDET_INCOMING_MESSAGE = 1,
	WSDET_INCOMING_FAULT = 2,
	WSDET_TRANSMISSION_FAILURE = 3,
	WSDET_RESPONSE_TIMEOUT = 4,
}

#endregion

#region Function Pointers
public function HRESULT WSD_STUB_FUNCTION(IUnknown* server, IWSDServiceMessaging* session, WSD_EVENT* event);

public function HRESULT PWSD_SOAP_MESSAGE_HANDLER(IUnknown* thisUnknown, WSD_EVENT* event);

#endregion

#region Structs
[CRepr]
public struct WSD_CONFIG_PARAM
{
	public WSD_CONFIG_PARAM_TYPE configParamType;
	public void* pConfigData;
	public uint32 dwConfigDataSize;
}

[CRepr]
public struct WSD_SECURITY_CERT_VALIDATION_V1
{
	public CERT_CONTEXT** certMatchArray;
	public uint32 dwCertMatchArrayCount;
	public HCERTSTORE hCertMatchStore;
	public HCERTSTORE hCertIssuerStore;
	public uint32 dwCertCheckOptions;
}

[CRepr]
public struct WSD_SECURITY_CERT_VALIDATION
{
	public CERT_CONTEXT** certMatchArray;
	public uint32 dwCertMatchArrayCount;
	public HCERTSTORE hCertMatchStore;
	public HCERTSTORE hCertIssuerStore;
	public uint32 dwCertCheckOptions;
	public PWSTR pszCNGHashAlgId;
	public uint8* pbCertHash;
	public uint32 dwCertHashSize;
}

[CRepr]
public struct WSD_SECURITY_SIGNATURE_VALIDATION
{
	public CERT_CONTEXT** signingCertArray;
	public uint32 dwSigningCertArrayCount;
	public HCERTSTORE hSigningCertStore;
	public uint32 dwFlags;
}

[CRepr]
public struct WSD_CONFIG_ADDRESSES
{
	public IWSDAddress** addresses;
	public uint32 dwAddressCount;
}

[CRepr]
public struct WSDUdpRetransmitParams
{
	public uint32 ulSendDelay;
	public uint32 ulRepeat;
	public uint32 ulRepeatMinDelay;
	public uint32 ulRepeatMaxDelay;
	public uint32 ulRepeatUpperDelay;
}

[CRepr]
public struct WSD_DATETIME
{
	public BOOL isPositive;
	public uint32 year;
	public uint8 month;
	public uint8 day;
	public uint8 hour;
	public uint8 minute;
	public uint8 second;
	public uint32 millisecond;
	public BOOL TZIsLocal;
	public BOOL TZIsPositive;
	public uint8 TZHour;
	public uint8 TZMinute;
}

[CRepr]
public struct WSD_DURATION
{
	public BOOL isPositive;
	public uint32 year;
	public uint32 month;
	public uint32 day;
	public uint32 hour;
	public uint32 minute;
	public uint32 second;
	public uint32 millisecond;
}

[CRepr]
public struct WSDXML_NAMESPACE
{
	public PWSTR Uri;
	public PWSTR PreferredPrefix;
	public WSDXML_NAME* Names;
	public uint16 NamesCount;
	public uint16 Encoding;
}

[CRepr]
public struct WSDXML_NAME
{
	public WSDXML_NAMESPACE* Space;
	public PWSTR LocalName;
}

[CRepr]
public struct WSDXML_TYPE
{
	public PWSTR Uri;
	public uint8* Table;
}

[CRepr]
public struct WSDXML_PREFIX_MAPPING
{
	public uint32 Refs;
	public WSDXML_PREFIX_MAPPING* Next;
	public WSDXML_NAMESPACE* Space;
	public PWSTR Prefix;
}

[CRepr]
public struct WSDXML_ATTRIBUTE
{
	public WSDXML_ELEMENT* Element;
	public WSDXML_ATTRIBUTE* Next;
	public WSDXML_NAME* Name;
	public PWSTR Value;
}

[CRepr]
public struct WSDXML_NODE
{
	public int32 Type;
	public WSDXML_ELEMENT* Parent;
	public WSDXML_NODE* Next;
}

[CRepr]
public struct WSDXML_ELEMENT
{
	public WSDXML_NODE Node;
	public WSDXML_NAME* Name;
	public WSDXML_ATTRIBUTE* FirstAttribute;
	public WSDXML_NODE* FirstChild;
	public WSDXML_PREFIX_MAPPING* PrefixMappings;
}

[CRepr]
public struct WSDXML_TEXT
{
	public WSDXML_NODE Node;
	public PWSTR Text;
}

[CRepr]
public struct WSDXML_ELEMENT_LIST
{
	public WSDXML_ELEMENT_LIST* Next;
	public WSDXML_ELEMENT* Element;
}

[CRepr]
public struct WSD_OPERATION
{
	public WSDXML_TYPE* RequestType;
	public WSDXML_TYPE* ResponseType;
	public WSD_STUB_FUNCTION RequestStubFunction;
}

[CRepr]
public struct WSD_HANDLER_CONTEXT
{
	public PWSD_SOAP_MESSAGE_HANDLER Handler;
	public void* PVoid;
	public IUnknown* Unknown;
}

[CRepr]
public struct WSD_SYNCHRONOUS_RESPONSE_CONTEXT
{
	public HRESULT hr;
	public HANDLE eventHandle;
	public IWSDMessageParameters* messageParameters;
	public void* results;
}

[CRepr]
public struct WSD_PORT_TYPE
{
	public uint32 EncodedName;
	public uint32 OperationCount;
	public WSD_OPERATION* Operations;
	public WSD_PROTOCOL_TYPE ProtocolType;
}

[CRepr]
public struct WSD_RELATIONSHIP_METADATA
{
	public PWSTR Type;
	public WSD_HOST_METADATA* Data;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_SERVICE_METADATA_LIST
{
	public WSD_SERVICE_METADATA_LIST* Next;
	public WSD_SERVICE_METADATA* Element;
}

[CRepr]
public struct WSD_HOST_METADATA
{
	public WSD_SERVICE_METADATA* Host;
	public WSD_SERVICE_METADATA_LIST* Hosted;
}

[CRepr]
public struct WSD_ENDPOINT_REFERENCE_LIST
{
	public WSD_ENDPOINT_REFERENCE_LIST* Next;
	public WSD_ENDPOINT_REFERENCE* Element;
}

[CRepr]
public struct WSD_SERVICE_METADATA
{
	public WSD_ENDPOINT_REFERENCE_LIST* EndpointReference;
	public WSD_NAME_LIST* Types;
	public PWSTR ServiceId;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_THIS_DEVICE_METADATA
{
	public WSD_LOCALIZED_STRING_LIST* FriendlyName;
	public PWSTR FirmwareVersion;
	public PWSTR SerialNumber;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_THIS_MODEL_METADATA
{
	public WSD_LOCALIZED_STRING_LIST* Manufacturer;
	public PWSTR ManufacturerUrl;
	public WSD_LOCALIZED_STRING_LIST* ModelName;
	public PWSTR ModelNumber;
	public PWSTR ModelUrl;
	public PWSTR PresentationUrl;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_LOCALIZED_STRING_LIST
{
	public WSD_LOCALIZED_STRING_LIST* Next;
	public WSD_LOCALIZED_STRING* Element;
}

[CRepr]
public struct WSD_SOAP_FAULT_REASON
{
	public WSD_LOCALIZED_STRING_LIST* Text;
}

[CRepr]
public struct WSD_SOAP_FAULT_SUBCODE
{
	public WSDXML_NAME* Value;
	public WSD_SOAP_FAULT_SUBCODE* Subcode;
}

[CRepr]
public struct WSD_SOAP_FAULT_CODE
{
	public WSDXML_NAME* Value;
	public WSD_SOAP_FAULT_SUBCODE* Subcode;
}

[CRepr]
public struct WSD_SOAP_FAULT
{
	public WSD_SOAP_FAULT_CODE* Code;
	public WSD_SOAP_FAULT_REASON* Reason;
	public PWSTR Node;
	public PWSTR Role;
	public WSDXML_ELEMENT* Detail;
}

[CRepr]
public struct WSD_APP_SEQUENCE
{
	public uint64 InstanceId;
	public PWSTR SequenceId;
	public uint64 MessageNumber;
}

[CRepr]
public struct WSD_HEADER_RELATESTO
{
	public WSDXML_NAME* RelationshipType;
	public PWSTR MessageID;
}

[CRepr]
public struct WSD_SOAP_HEADER
{
	public PWSTR To;
	public PWSTR Action;
	public PWSTR MessageID;
	public WSD_HEADER_RELATESTO RelatesTo;
	public WSD_ENDPOINT_REFERENCE* ReplyTo;
	public WSD_ENDPOINT_REFERENCE* From;
	public WSD_ENDPOINT_REFERENCE* FaultTo;
	public WSD_APP_SEQUENCE* AppSequence;
	public WSDXML_ELEMENT* AnyHeaders;
}

[CRepr]
public struct WSD_SOAP_MESSAGE
{
	public WSD_SOAP_HEADER Header;
	public void* Body;
	public WSDXML_TYPE* BodyType;
}

[CRepr]
public struct WSD_RESOLVE_MATCHES
{
	public WSD_RESOLVE_MATCH* ResolveMatch;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_RESOLVE_MATCH
{
	public WSD_ENDPOINT_REFERENCE* EndpointReference;
	public WSD_NAME_LIST* Types;
	public WSD_SCOPES* Scopes;
	public WSD_URI_LIST* XAddrs;
	public uint64 MetadataVersion;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_RESOLVE
{
	public WSD_ENDPOINT_REFERENCE* EndpointReference;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_PROBE_MATCH
{
	public WSD_ENDPOINT_REFERENCE* EndpointReference;
	public WSD_NAME_LIST* Types;
	public WSD_SCOPES* Scopes;
	public WSD_URI_LIST* XAddrs;
	public uint64 MetadataVersion;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_PROBE_MATCH_LIST
{
	public WSD_PROBE_MATCH_LIST* Next;
	public WSD_PROBE_MATCH* Element;
}

[CRepr]
public struct WSD_PROBE_MATCHES
{
	public WSD_PROBE_MATCH_LIST* ProbeMatch;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_PROBE
{
	public WSD_NAME_LIST* Types;
	public WSD_SCOPES* Scopes;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_BYE
{
	public WSD_ENDPOINT_REFERENCE* EndpointReference;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_SCOPES
{
	public PWSTR MatchBy;
	public WSD_URI_LIST* Scopes;
}

[CRepr]
public struct WSD_NAME_LIST
{
	public WSD_NAME_LIST* Next;
	public WSDXML_NAME* Element;
}

[CRepr]
public struct WSD_HELLO
{
	public WSD_ENDPOINT_REFERENCE* EndpointReference;
	public WSD_NAME_LIST* Types;
	public WSD_SCOPES* Scopes;
	public WSD_URI_LIST* XAddrs;
	public uint64 MetadataVersion;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_REFERENCE_PARAMETERS
{
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_REFERENCE_PROPERTIES
{
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_ENDPOINT_REFERENCE
{
	public PWSTR Address;
	public WSD_REFERENCE_PROPERTIES ReferenceProperties;
	public WSD_REFERENCE_PARAMETERS ReferenceParameters;
	public WSDXML_NAME* PortType;
	public WSDXML_NAME* ServiceName;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_METADATA_SECTION
{
	public PWSTR Dialect;
	public PWSTR Identifier;
	public void* Data;
	public WSD_ENDPOINT_REFERENCE* MetadataReference;
	public PWSTR Location;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_METADATA_SECTION_LIST
{
	public WSD_METADATA_SECTION_LIST* Next;
	public WSD_METADATA_SECTION* Element;
}

[CRepr]
public struct WSD_URI_LIST
{
	public WSD_URI_LIST* Next;
	public PWSTR Element;
}

[CRepr]
public struct WSD_EVENTING_FILTER_ACTION
{
	public WSD_URI_LIST* Actions;
}

[CRepr]
public struct WSD_EVENTING_FILTER
{
	public PWSTR Dialect;
	public WSD_EVENTING_FILTER_ACTION* FilterAction;
	public void* Data;
}

[CRepr]
public struct WSD_EVENTING_EXPIRES
{
	public WSD_DURATION* Duration;
	public WSD_DATETIME* DateTime;
}

[CRepr]
public struct WSD_EVENTING_DELIVERY_MODE_PUSH
{
	public WSD_ENDPOINT_REFERENCE* NotifyTo;
}

[CRepr]
public struct WSD_EVENTING_DELIVERY_MODE
{
	public PWSTR Mode;
	public WSD_EVENTING_DELIVERY_MODE_PUSH* Push;
	public void* Data;
}

[CRepr]
public struct WSD_LOCALIZED_STRING
{
	public PWSTR lang;
	public PWSTR String;
}

[CRepr]
public struct RESPONSEBODY_GetMetadata
{
	public WSD_METADATA_SECTION_LIST* Metadata;
}

[CRepr]
public struct REQUESTBODY_Subscribe
{
	public WSD_ENDPOINT_REFERENCE* EndTo;
	public WSD_EVENTING_DELIVERY_MODE* Delivery;
	public WSD_EVENTING_EXPIRES* Expires;
	public WSD_EVENTING_FILTER* Filter;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct RESPONSEBODY_Subscribe
{
	public WSD_ENDPOINT_REFERENCE* SubscriptionManager;
	public WSD_EVENTING_EXPIRES* expires;
	public WSDXML_ELEMENT* any;
}

[CRepr]
public struct REQUESTBODY_Renew
{
	public WSD_EVENTING_EXPIRES* Expires;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct RESPONSEBODY_Renew
{
	public WSD_EVENTING_EXPIRES* expires;
	public WSDXML_ELEMENT* any;
}

[CRepr]
public struct REQUESTBODY_GetStatus
{
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct RESPONSEBODY_GetStatus
{
	public WSD_EVENTING_EXPIRES* expires;
	public WSDXML_ELEMENT* any;
}

[CRepr]
public struct REQUESTBODY_Unsubscribe
{
	public WSDXML_ELEMENT* any;
}

[CRepr]
public struct RESPONSEBODY_SubscriptionEnd
{
	public WSD_ENDPOINT_REFERENCE* SubscriptionManager;
	public PWSTR Status;
	public WSD_LOCALIZED_STRING* Reason;
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_UNKNOWN_LOOKUP
{
	public WSDXML_ELEMENT* Any;
}

[CRepr]
public struct WSD_EVENT
{
	public HRESULT Hr;
	public uint32 EventType;
	public PWSTR DispatchTag;
	public WSD_HANDLER_CONTEXT HandlerContext;
	public WSD_SOAP_MESSAGE* Soap;
	public WSD_OPERATION* Operation;
	public IWSDMessageParameters* MessageParameters;
}

#endregion

#region COM Types
[CRepr]struct IWSDAddress : IUnknown
{
	public new const Guid IID = .(0xb9574c6c, 0x12a6, 0x4f74, 0x93, 0xa1, 0x33, 0x18, 0xff, 0x60, 0x57, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszBuffer, uint32 cchLength, BOOL fSafe) Serialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszBuffer) Deserialize;
	}


	public HRESULT Serialize(char16* pszBuffer, uint32 cchLength, BOOL fSafe) mut => VT.[Friend]Serialize(&this, pszBuffer, cchLength, fSafe);

	public HRESULT Deserialize(PWSTR pszBuffer) mut => VT.[Friend]Deserialize(&this, pszBuffer);
}

[CRepr]struct IWSDTransportAddress : IWSDAddress
{
	public new const Guid IID = .(0x70d23498, 0x4ee6, 0x4340, 0xa3, 0xdf, 0xd8, 0x45, 0xd2, 0x23, 0x54, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDAddress.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwPort) GetPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wPort) SetPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszAddress) GetTransportAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fSafe, PWSTR* ppszAddress) GetTransportAddressEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAddress) SetTransportAddress;
	}


	public HRESULT GetPort(uint16* pwPort) mut => VT.[Friend]GetPort(&this, pwPort);

	public HRESULT SetPort(uint16 wPort) mut => VT.[Friend]SetPort(&this, wPort);

	public HRESULT GetTransportAddress(PWSTR* ppszAddress) mut => VT.[Friend]GetTransportAddress(&this, ppszAddress);

	public HRESULT GetTransportAddressEx(BOOL fSafe, PWSTR* ppszAddress) mut => VT.[Friend]GetTransportAddressEx(&this, fSafe, ppszAddress);

	public HRESULT SetTransportAddress(PWSTR pszAddress) mut => VT.[Friend]SetTransportAddress(&this, pszAddress);
}

[CRepr]struct IWSDMessageParameters : IUnknown
{
	public new const Guid IID = .(0x1fafe8a2, 0xe6fc, 0x4b80, 0xb6, 0xcf, 0xb7, 0xd4, 0x5c, 0x41, 0x6d, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAddress** ppAddress) GetLocalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAddress* pAddress) SetLocalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAddress** ppAddress) GetRemoteAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAddress* pAddress) SetRemoteAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDMessageParameters** ppTxParams) GetLowerParameters;
	}


	public HRESULT GetLocalAddress(IWSDAddress** ppAddress) mut => VT.[Friend]GetLocalAddress(&this, ppAddress);

	public HRESULT SetLocalAddress(IWSDAddress* pAddress) mut => VT.[Friend]SetLocalAddress(&this, pAddress);

	public HRESULT GetRemoteAddress(IWSDAddress** ppAddress) mut => VT.[Friend]GetRemoteAddress(&this, ppAddress);

	public HRESULT SetRemoteAddress(IWSDAddress* pAddress) mut => VT.[Friend]SetRemoteAddress(&this, pAddress);

	public HRESULT GetLowerParameters(IWSDMessageParameters** ppTxParams) mut => VT.[Friend]GetLowerParameters(&this, ppTxParams);
}

[CRepr]struct IWSDUdpMessageParameters : IWSDMessageParameters
{
	public new const Guid IID = .(0x9934149f, 0x8f0c, 0x447b, 0xaa, 0x0b, 0x73, 0x12, 0x4b, 0x0c, 0xa7, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDMessageParameters.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDUdpRetransmitParams* pParams) SetRetransmitParams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDUdpRetransmitParams* pParams) GetRetransmitParams;
	}


	public HRESULT SetRetransmitParams(WSDUdpRetransmitParams* pParams) mut => VT.[Friend]SetRetransmitParams(&this, pParams);

	public HRESULT GetRetransmitParams(WSDUdpRetransmitParams* pParams) mut => VT.[Friend]GetRetransmitParams(&this, pParams);
}

[CRepr]struct IWSDUdpAddress : IWSDTransportAddress
{
	public new const Guid IID = .(0x74d6124a, 0xa441, 0x4f78, 0xa1, 0xeb, 0x97, 0xa8, 0xd1, 0x99, 0x68, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDTransportAddress.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SOCKADDR_STORAGE* pSockAddr) SetSockaddr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SOCKADDR_STORAGE* pSockAddr) GetSockaddr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fExclusive) SetExclusive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetExclusive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDUdpMessageType messageType) SetMessageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDUdpMessageType* pMessageType) GetMessageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTTL) SetTTL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwTTL) GetTTL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pAlias) SetAlias;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pAlias) GetAlias;
	}


	public HRESULT SetSockaddr(SOCKADDR_STORAGE* pSockAddr) mut => VT.[Friend]SetSockaddr(&this, pSockAddr);

	public HRESULT GetSockaddr(SOCKADDR_STORAGE* pSockAddr) mut => VT.[Friend]GetSockaddr(&this, pSockAddr);

	public HRESULT SetExclusive(BOOL fExclusive) mut => VT.[Friend]SetExclusive(&this, fExclusive);

	public HRESULT GetExclusive() mut => VT.[Friend]GetExclusive(&this);

	public HRESULT SetMessageType(WSDUdpMessageType messageType) mut => VT.[Friend]SetMessageType(&this, messageType);

	public HRESULT GetMessageType(WSDUdpMessageType* pMessageType) mut => VT.[Friend]GetMessageType(&this, pMessageType);

	public HRESULT SetTTL(uint32 dwTTL) mut => VT.[Friend]SetTTL(&this, dwTTL);

	public HRESULT GetTTL(uint32* pdwTTL) mut => VT.[Friend]GetTTL(&this, pdwTTL);

	public HRESULT SetAlias(in Guid pAlias) mut => VT.[Friend]SetAlias(&this, pAlias);

	public HRESULT GetAlias(Guid* pAlias) mut => VT.[Friend]GetAlias(&this, pAlias);
}

[CRepr]struct IWSDHttpMessageParameters : IWSDMessageParameters
{
	public new const Guid IID = .(0x540bd122, 0x5c83, 0x4dec, 0xb3, 0x96, 0xea, 0x62, 0xa2, 0x69, 0x7f, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDMessageParameters.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHeaders) SetInboundHttpHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszHeaders) GetInboundHttpHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHeaders) SetOutboundHttpHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszHeaders) GetOutboundHttpHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszId) SetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszId) GetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pContext) SetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppContext) GetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT SetInboundHttpHeaders(PWSTR pszHeaders) mut => VT.[Friend]SetInboundHttpHeaders(&this, pszHeaders);

	public HRESULT GetInboundHttpHeaders(PWSTR* ppszHeaders) mut => VT.[Friend]GetInboundHttpHeaders(&this, ppszHeaders);

	public HRESULT SetOutboundHttpHeaders(PWSTR pszHeaders) mut => VT.[Friend]SetOutboundHttpHeaders(&this, pszHeaders);

	public HRESULT GetOutboundHttpHeaders(PWSTR* ppszHeaders) mut => VT.[Friend]GetOutboundHttpHeaders(&this, ppszHeaders);

	public HRESULT SetID(PWSTR pszId) mut => VT.[Friend]SetID(&this, pszId);

	public HRESULT GetID(PWSTR* ppszId) mut => VT.[Friend]GetID(&this, ppszId);

	public HRESULT SetContext(IUnknown* pContext) mut => VT.[Friend]SetContext(&this, pContext);

	public HRESULT GetContext(IUnknown** ppContext) mut => VT.[Friend]GetContext(&this, ppContext);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IWSDHttpAddress : IWSDTransportAddress
{
	public new const Guid IID = .(0xd09ac7bd, 0x2a3e, 0x4b85, 0x86, 0x05, 0x27, 0x37, 0xff, 0x3e, 0x4e, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDTransportAddress.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetSecure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fSecure) SetSecure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) SetPath;
	}


	public HRESULT GetSecure() mut => VT.[Friend]GetSecure(&this);

	public HRESULT SetSecure(BOOL fSecure) mut => VT.[Friend]SetSecure(&this, fSecure);

	public HRESULT GetPath(PWSTR* ppszPath) mut => VT.[Friend]GetPath(&this, ppszPath);

	public HRESULT SetPath(PWSTR pszPath) mut => VT.[Friend]SetPath(&this, pszPath);
}

[CRepr]struct IWSDSSLClientCertificate : IUnknown
{
	public new const Guid IID = .(0xde105e87, 0xa0da, 0x418e, 0x98, 0xad, 0x27, 0xb9, 0xee, 0xd8, 0x7b, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT** ppCertContext) GetClientCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phToken) GetMappedAccessToken;
	}


	public HRESULT GetClientCertificate(CERT_CONTEXT** ppCertContext) mut => VT.[Friend]GetClientCertificate(&this, ppCertContext);

	public HRESULT GetMappedAccessToken(HANDLE* phToken) mut => VT.[Friend]GetMappedAccessToken(&this, phToken);
}

[CRepr]struct IWSDHttpAuthParameters : IUnknown
{
	public new const Guid IID = .(0x0b476df0, 0x8dac, 0x480d, 0xb0, 0x5c, 0x99, 0x78, 0x1a, 0x58, 0x84, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phToken) GetClientAccessToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pAuthType) GetAuthType;
	}


	public HRESULT GetClientAccessToken(HANDLE* phToken) mut => VT.[Friend]GetClientAccessToken(&this, phToken);

	public HRESULT GetAuthType(uint32* pAuthType) mut => VT.[Friend]GetAuthType(&this, pAuthType);
}

[CRepr]struct IWSDSignatureProperty : IUnknown
{
	public new const Guid IID = .(0x03ce20aa, 0x71c4, 0x45e2, 0xb3, 0x2e, 0x37, 0x66, 0xc6, 0x1c, 0x79, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbSigned) IsMessageSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbSignatureTrusted) IsMessageSignatureTrusted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbKeyInfo, uint32* pdwKeyInfoSize) GetKeyInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbSignature, uint32* pdwSignatureSize) GetSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbSignedInfoHash, uint32* pdwHashSize) GetSignedInfoHash;
	}


	public HRESULT IsMessageSigned(BOOL* pbSigned) mut => VT.[Friend]IsMessageSigned(&this, pbSigned);

	public HRESULT IsMessageSignatureTrusted(BOOL* pbSignatureTrusted) mut => VT.[Friend]IsMessageSignatureTrusted(&this, pbSignatureTrusted);

	public HRESULT GetKeyInfo(uint8* pbKeyInfo, uint32* pdwKeyInfoSize) mut => VT.[Friend]GetKeyInfo(&this, pbKeyInfo, pdwKeyInfoSize);

	public HRESULT GetSignature(uint8* pbSignature, uint32* pdwSignatureSize) mut => VT.[Friend]GetSignature(&this, pbSignature, pdwSignatureSize);

	public HRESULT GetSignedInfoHash(uint8* pbSignedInfoHash, uint32* pdwHashSize) mut => VT.[Friend]GetSignedInfoHash(&this, pbSignedInfoHash, pdwHashSize);
}

[CRepr]struct IWSDAttachment : IUnknown
{
	public new const Guid IID = .(0x5d55a616, 0x9df8, 0x4b09, 0xb1, 0x56, 0x9b, 0xa3, 0x51, 0xa4, 0x8b, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IWSDOutboundAttachment : IWSDAttachment
{
	public new const Guid IID = .(0xaa302f8d, 0x5a22, 0x4ba5, 0xb3, 0x92, 0xaa, 0x84, 0x86, 0xf4, 0xc1, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDAttachment.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pBuffer, uint32 dwBytesToWrite, uint32* pdwNumberOfBytesWritten) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
	}


	public HRESULT Write(uint8* pBuffer, uint32 dwBytesToWrite, uint32* pdwNumberOfBytesWritten) mut => VT.[Friend]Write(&this, pBuffer, dwBytesToWrite, pdwNumberOfBytesWritten);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);
}

[CRepr]struct IWSDInboundAttachment : IWSDAttachment
{
	public new const Guid IID = .(0x5bd6ca65, 0x233c, 0x4fb8, 0x9f, 0x7a, 0x26, 0x41, 0x61, 0x96, 0x55, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDAttachment.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pBuffer, uint32 dwBytesToRead, uint32* pdwNumberOfBytesRead) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT Read(uint8* pBuffer, uint32 dwBytesToRead, uint32* pdwNumberOfBytesRead) mut => VT.[Friend]Read(&this, pBuffer, dwBytesToRead, pdwNumberOfBytesRead);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IWSDXMLContext : IUnknown
{
	public new const Guid IID = .(0x75d8f3ee, 0x3e5a, 0x43b4, 0xa1, 0x5a, 0xbc, 0xf6, 0x88, 0x74, 0x60, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUri, PWSTR pszSuggestedPrefix, WSDXML_NAMESPACE** ppNamespace) AddNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUri, PWSTR pszName, WSDXML_NAME** ppName) AddNameToNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDXML_NAMESPACE** pNamespaces, uint16 wNamespacesCount, uint8 bLayerNumber) SetNamespaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDXML_TYPE** pTypes, uint32 dwTypesCount, uint8 bLayerNumber) SetTypes;
	}


	public HRESULT AddNamespace(PWSTR pszUri, PWSTR pszSuggestedPrefix, WSDXML_NAMESPACE** ppNamespace) mut => VT.[Friend]AddNamespace(&this, pszUri, pszSuggestedPrefix, ppNamespace);

	public HRESULT AddNameToNamespace(PWSTR pszUri, PWSTR pszName, WSDXML_NAME** ppName) mut => VT.[Friend]AddNameToNamespace(&this, pszUri, pszName, ppName);

	public HRESULT SetNamespaces(WSDXML_NAMESPACE** pNamespaces, uint16 wNamespacesCount, uint8 bLayerNumber) mut => VT.[Friend]SetNamespaces(&this, pNamespaces, wNamespacesCount, bLayerNumber);

	public HRESULT SetTypes(WSDXML_TYPE** pTypes, uint32 dwTypesCount, uint8 bLayerNumber) mut => VT.[Friend]SetTypes(&this, pTypes, dwTypesCount, bLayerNumber);
}

[CRepr]struct IWSDiscoveryProvider : IUnknown
{
	public new const Guid IID = .(0x8ffc8e55, 0xf0eb, 0x480f, 0x88, 0xb7, 0xb4, 0x35, 0xdd, 0x28, 0x1d, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAddressFamily) SetAddressFamily;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDiscoveryProviderNotify* pSink) Attach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Detach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszId, PWSTR pszTag) SearchById;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAddress, PWSTR pszTag) SearchByAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, PWSTR pszMatchBy, PWSTR pszTag) SearchByType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDXMLContext** ppContext) GetXMLContext;
	}


	public HRESULT SetAddressFamily(uint32 dwAddressFamily) mut => VT.[Friend]SetAddressFamily(&this, dwAddressFamily);

	public HRESULT Attach(IWSDiscoveryProviderNotify* pSink) mut => VT.[Friend]Attach(&this, pSink);

	public HRESULT Detach() mut => VT.[Friend]Detach(&this);

	public HRESULT SearchById(PWSTR pszId, PWSTR pszTag) mut => VT.[Friend]SearchById(&this, pszId, pszTag);

	public HRESULT SearchByAddress(PWSTR pszAddress, PWSTR pszTag) mut => VT.[Friend]SearchByAddress(&this, pszAddress, pszTag);

	public HRESULT SearchByType(WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, PWSTR pszMatchBy, PWSTR pszTag) mut => VT.[Friend]SearchByType(&this, pTypesList, pScopesList, pszMatchBy, pszTag);

	public HRESULT GetXMLContext(IWSDXMLContext** ppContext) mut => VT.[Friend]GetXMLContext(&this, ppContext);
}

[CRepr]struct IWSDiscoveryProviderNotify : IUnknown
{
	public new const Guid IID = .(0x73ee3ced, 0xb6e6, 0x4329, 0xa5, 0x46, 0x3e, 0x8a, 0xd4, 0x65, 0x63, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDiscoveredService* pService) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDiscoveredService* pService) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, PWSTR pszTag) SearchFailed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTag) SearchComplete;
	}


	public HRESULT Add(IWSDiscoveredService* pService) mut => VT.[Friend]Add(&this, pService);

	public HRESULT Remove(IWSDiscoveredService* pService) mut => VT.[Friend]Remove(&this, pService);

	public HRESULT SearchFailed(HRESULT hr, PWSTR pszTag) mut => VT.[Friend]SearchFailed(&this, hr, pszTag);

	public HRESULT SearchComplete(PWSTR pszTag) mut => VT.[Friend]SearchComplete(&this, pszTag);
}

[CRepr]struct IWSDiscoveredService : IUnknown
{
	public new const Guid IID = .(0x4bad8a3b, 0xb374, 0x4420, 0x96, 0x32, 0xaa, 0xc9, 0x45, 0xb3, 0x74, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_ENDPOINT_REFERENCE** ppEndpointReference) GetEndpointReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_NAME_LIST** ppTypesList) GetTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_URI_LIST** ppScopesList) GetScopes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_URI_LIST** ppXAddrsList) GetXAddrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullMetadataVersion) GetMetadataVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDXML_ELEMENT** ppHeaderAny, WSDXML_ELEMENT** ppBodyAny) GetExtendedDiscoXML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTag) GetProbeResolveTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszRemoteTransportAddress) GetRemoteTransportAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszLocalTransportAddress) GetLocalTransportAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetLocalInterfaceGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullInstanceId) GetInstanceId;
	}


	public HRESULT GetEndpointReference(WSD_ENDPOINT_REFERENCE** ppEndpointReference) mut => VT.[Friend]GetEndpointReference(&this, ppEndpointReference);

	public HRESULT GetTypes(WSD_NAME_LIST** ppTypesList) mut => VT.[Friend]GetTypes(&this, ppTypesList);

	public HRESULT GetScopes(WSD_URI_LIST** ppScopesList) mut => VT.[Friend]GetScopes(&this, ppScopesList);

	public HRESULT GetXAddrs(WSD_URI_LIST** ppXAddrsList) mut => VT.[Friend]GetXAddrs(&this, ppXAddrsList);

	public HRESULT GetMetadataVersion(uint64* pullMetadataVersion) mut => VT.[Friend]GetMetadataVersion(&this, pullMetadataVersion);

	public HRESULT GetExtendedDiscoXML(WSDXML_ELEMENT** ppHeaderAny, WSDXML_ELEMENT** ppBodyAny) mut => VT.[Friend]GetExtendedDiscoXML(&this, ppHeaderAny, ppBodyAny);

	public HRESULT GetProbeResolveTag(PWSTR* ppszTag) mut => VT.[Friend]GetProbeResolveTag(&this, ppszTag);

	public HRESULT GetRemoteTransportAddress(PWSTR* ppszRemoteTransportAddress) mut => VT.[Friend]GetRemoteTransportAddress(&this, ppszRemoteTransportAddress);

	public HRESULT GetLocalTransportAddress(PWSTR* ppszLocalTransportAddress) mut => VT.[Friend]GetLocalTransportAddress(&this, ppszLocalTransportAddress);

	public HRESULT GetLocalInterfaceGUID(Guid* pGuid) mut => VT.[Friend]GetLocalInterfaceGUID(&this, pGuid);

	public HRESULT GetInstanceId(uint64* pullInstanceId) mut => VT.[Friend]GetInstanceId(&this, pullInstanceId);
}

[CRepr]struct IWSDiscoveryPublisher : IUnknown
{
	public new const Guid IID = .(0xae01e1a8, 0x3ff9, 0x4148, 0x81, 0x16, 0x05, 0x7c, 0xc6, 0x16, 0xfe, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAddressFamily) SetAddressFamily;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDiscoveryPublisherNotify* pSink) RegisterNotificationSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDiscoveryPublisherNotify* pSink) UnRegisterNotificationSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList) Publish;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszId, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSDXML_ELEMENT* pAny) UnPublish;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_MESSAGE* pProbeMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList) MatchProbe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_MESSAGE* pResolveMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList) MatchResolve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList, WSDXML_ELEMENT* pHeaderAny, WSDXML_ELEMENT* pReferenceParameterAny, WSDXML_ELEMENT* pPolicyAny, WSDXML_ELEMENT* pEndpointReferenceAny, WSDXML_ELEMENT* pAny) PublishEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_MESSAGE* pProbeMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList, WSDXML_ELEMENT* pHeaderAny, WSDXML_ELEMENT* pReferenceParameterAny, WSDXML_ELEMENT* pPolicyAny, WSDXML_ELEMENT* pEndpointReferenceAny, WSDXML_ELEMENT* pAny) MatchProbeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_MESSAGE* pResolveMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList, WSDXML_ELEMENT* pHeaderAny, WSDXML_ELEMENT* pReferenceParameterAny, WSDXML_ELEMENT* pPolicyAny, WSDXML_ELEMENT* pEndpointReferenceAny, WSDXML_ELEMENT* pAny) MatchResolveEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDScopeMatchingRule* pScopeMatchingRule) RegisterScopeMatchingRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDScopeMatchingRule* pScopeMatchingRule) UnRegisterScopeMatchingRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDXMLContext** ppContext) GetXMLContext;
	}


	public HRESULT SetAddressFamily(uint32 dwAddressFamily) mut => VT.[Friend]SetAddressFamily(&this, dwAddressFamily);

	public HRESULT RegisterNotificationSink(IWSDiscoveryPublisherNotify* pSink) mut => VT.[Friend]RegisterNotificationSink(&this, pSink);

	public HRESULT UnRegisterNotificationSink(IWSDiscoveryPublisherNotify* pSink) mut => VT.[Friend]UnRegisterNotificationSink(&this, pSink);

	public HRESULT Publish(PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList) mut => VT.[Friend]Publish(&this, pszId, ullMetadataVersion, ullInstanceId, ullMessageNumber, pszSessionId, pTypesList, pScopesList, pXAddrsList);

	public HRESULT UnPublish(PWSTR pszId, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSDXML_ELEMENT* pAny) mut => VT.[Friend]UnPublish(&this, pszId, ullInstanceId, ullMessageNumber, pszSessionId, pAny);

	public HRESULT MatchProbe(WSD_SOAP_MESSAGE* pProbeMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList) mut => VT.[Friend]MatchProbe(&this, pProbeMessage, pMessageParameters, pszId, ullMetadataVersion, ullInstanceId, ullMessageNumber, pszSessionId, pTypesList, pScopesList, pXAddrsList);

	public HRESULT MatchResolve(WSD_SOAP_MESSAGE* pResolveMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList) mut => VT.[Friend]MatchResolve(&this, pResolveMessage, pMessageParameters, pszId, ullMetadataVersion, ullInstanceId, ullMessageNumber, pszSessionId, pTypesList, pScopesList, pXAddrsList);

	public HRESULT PublishEx(PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList, WSDXML_ELEMENT* pHeaderAny, WSDXML_ELEMENT* pReferenceParameterAny, WSDXML_ELEMENT* pPolicyAny, WSDXML_ELEMENT* pEndpointReferenceAny, WSDXML_ELEMENT* pAny) mut => VT.[Friend]PublishEx(&this, pszId, ullMetadataVersion, ullInstanceId, ullMessageNumber, pszSessionId, pTypesList, pScopesList, pXAddrsList, pHeaderAny, pReferenceParameterAny, pPolicyAny, pEndpointReferenceAny, pAny);

	public HRESULT MatchProbeEx(WSD_SOAP_MESSAGE* pProbeMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList, WSDXML_ELEMENT* pHeaderAny, WSDXML_ELEMENT* pReferenceParameterAny, WSDXML_ELEMENT* pPolicyAny, WSDXML_ELEMENT* pEndpointReferenceAny, WSDXML_ELEMENT* pAny) mut => VT.[Friend]MatchProbeEx(&this, pProbeMessage, pMessageParameters, pszId, ullMetadataVersion, ullInstanceId, ullMessageNumber, pszSessionId, pTypesList, pScopesList, pXAddrsList, pHeaderAny, pReferenceParameterAny, pPolicyAny, pEndpointReferenceAny, pAny);

	public HRESULT MatchResolveEx(WSD_SOAP_MESSAGE* pResolveMessage, IWSDMessageParameters* pMessageParameters, PWSTR pszId, uint64 ullMetadataVersion, uint64 ullInstanceId, uint64 ullMessageNumber, PWSTR pszSessionId, WSD_NAME_LIST* pTypesList, WSD_URI_LIST* pScopesList, WSD_URI_LIST* pXAddrsList, WSDXML_ELEMENT* pHeaderAny, WSDXML_ELEMENT* pReferenceParameterAny, WSDXML_ELEMENT* pPolicyAny, WSDXML_ELEMENT* pEndpointReferenceAny, WSDXML_ELEMENT* pAny) mut => VT.[Friend]MatchResolveEx(&this, pResolveMessage, pMessageParameters, pszId, ullMetadataVersion, ullInstanceId, ullMessageNumber, pszSessionId, pTypesList, pScopesList, pXAddrsList, pHeaderAny, pReferenceParameterAny, pPolicyAny, pEndpointReferenceAny, pAny);

	public HRESULT RegisterScopeMatchingRule(IWSDScopeMatchingRule* pScopeMatchingRule) mut => VT.[Friend]RegisterScopeMatchingRule(&this, pScopeMatchingRule);

	public HRESULT UnRegisterScopeMatchingRule(IWSDScopeMatchingRule* pScopeMatchingRule) mut => VT.[Friend]UnRegisterScopeMatchingRule(&this, pScopeMatchingRule);

	public HRESULT GetXMLContext(IWSDXMLContext** ppContext) mut => VT.[Friend]GetXMLContext(&this, ppContext);
}

[CRepr]struct IWSDiscoveryPublisherNotify : IUnknown
{
	public new const Guid IID = .(0xe67651b0, 0x337a, 0x4b3c, 0x97, 0x58, 0x73, 0x33, 0x88, 0x56, 0x82, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_MESSAGE* pSoap, IWSDMessageParameters* pMessageParameters) ProbeHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_MESSAGE* pSoap, IWSDMessageParameters* pMessageParameters) ResolveHandler;
	}


	public HRESULT ProbeHandler(WSD_SOAP_MESSAGE* pSoap, IWSDMessageParameters* pMessageParameters) mut => VT.[Friend]ProbeHandler(&this, pSoap, pMessageParameters);

	public HRESULT ResolveHandler(WSD_SOAP_MESSAGE* pSoap, IWSDMessageParameters* pMessageParameters) mut => VT.[Friend]ResolveHandler(&this, pSoap, pMessageParameters);
}

[CRepr]struct IWSDScopeMatchingRule : IUnknown
{
	public new const Guid IID = .(0xfcafe424, 0xfef5, 0x481a, 0xbd, 0x9f, 0x33, 0xce, 0x05, 0x74, 0x25, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszScopeMatchingRule) GetScopeRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszScope1, PWSTR pszScope2, BOOL* pfMatch) MatchScopes;
	}


	public HRESULT GetScopeRule(PWSTR* ppszScopeMatchingRule) mut => VT.[Friend]GetScopeRule(&this, ppszScopeMatchingRule);

	public HRESULT MatchScopes(PWSTR pszScope1, PWSTR pszScope2, BOOL* pfMatch) mut => VT.[Friend]MatchScopes(&this, pszScope1, pszScope2, pfMatch);
}

[CRepr]struct IWSDEndpointProxy : IUnknown
{
	public new const Guid IID = .(0x1860d430, 0xb24c, 0x4975, 0x9f, 0x90, 0xdb, 0xb3, 0x9b, 0xaa, 0x24, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pBody, WSD_OPERATION* pOperation) SendOneWayRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pBody, WSD_OPERATION* pOperation, WSD_SYNCHRONOUS_RESPONSE_CONTEXT* pResponseContext) SendTwoWayRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pBody, WSD_OPERATION* pOperation, IUnknown* pAsyncState, IWSDAsyncCallback* pCallback, IWSDAsyncResult** pResult) SendTwoWayRequestAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncResult* pAsyncResult) AbortAsyncOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_FAULT* pFault) ProcessFault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszErrorInfo) GetErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_FAULT** ppFault) GetFaultInfo;
	}


	public HRESULT SendOneWayRequest(void* pBody, WSD_OPERATION* pOperation) mut => VT.[Friend]SendOneWayRequest(&this, pBody, pOperation);

	public HRESULT SendTwoWayRequest(void* pBody, WSD_OPERATION* pOperation, WSD_SYNCHRONOUS_RESPONSE_CONTEXT* pResponseContext) mut => VT.[Friend]SendTwoWayRequest(&this, pBody, pOperation, pResponseContext);

	public HRESULT SendTwoWayRequestAsync(void* pBody, WSD_OPERATION* pOperation, IUnknown* pAsyncState, IWSDAsyncCallback* pCallback, IWSDAsyncResult** pResult) mut => VT.[Friend]SendTwoWayRequestAsync(&this, pBody, pOperation, pAsyncState, pCallback, pResult);

	public HRESULT AbortAsyncOperation(IWSDAsyncResult* pAsyncResult) mut => VT.[Friend]AbortAsyncOperation(&this, pAsyncResult);

	public HRESULT ProcessFault(WSD_SOAP_FAULT* pFault) mut => VT.[Friend]ProcessFault(&this, pFault);

	public HRESULT GetErrorInfo(PWSTR* ppszErrorInfo) mut => VT.[Friend]GetErrorInfo(&this, ppszErrorInfo);

	public HRESULT GetFaultInfo(WSD_SOAP_FAULT** ppFault) mut => VT.[Friend]GetFaultInfo(&this, ppFault);
}

[CRepr]struct IWSDMetadataExchange : IUnknown
{
	public new const Guid IID = .(0x06996d57, 0x1d67, 0x4928, 0x93, 0x07, 0x3d, 0x78, 0x33, 0xfd, 0xb8, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_METADATA_SECTION_LIST** MetadataOut) GetMetadata;
	}


	public HRESULT GetMetadata(WSD_METADATA_SECTION_LIST** MetadataOut) mut => VT.[Friend]GetMetadata(&this, MetadataOut);
}

[CRepr]struct IWSDServiceProxy : IWSDMetadataExchange
{
	public new const Guid IID = .(0xd4c7fb9c, 0x03ab, 0x4175, 0x9d, 0x67, 0x09, 0x4f, 0xaf, 0xeb, 0xf4, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDMetadataExchange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncResult** ppResult) BeginGetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncResult* pResult, WSD_METADATA_SECTION_LIST** ppMetadata) EndGetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SERVICE_METADATA** ppServiceMetadata) GetServiceMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperation, IUnknown* pUnknown, WSDXML_ELEMENT* pAny, WSDXML_ELEMENT** ppAny) SubscribeToOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperation) UnsubscribeToOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDEventingStatus* pStatus) SetEventingStatusCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDEndpointProxy** ppProxy) GetEndpointProxy;
	}


	public HRESULT BeginGetMetadata(IWSDAsyncResult** ppResult) mut => VT.[Friend]BeginGetMetadata(&this, ppResult);

	public HRESULT EndGetMetadata(IWSDAsyncResult* pResult, WSD_METADATA_SECTION_LIST** ppMetadata) mut => VT.[Friend]EndGetMetadata(&this, pResult, ppMetadata);

	public HRESULT GetServiceMetadata(WSD_SERVICE_METADATA** ppServiceMetadata) mut => VT.[Friend]GetServiceMetadata(&this, ppServiceMetadata);

	public HRESULT SubscribeToOperation(WSD_OPERATION* pOperation, IUnknown* pUnknown, WSDXML_ELEMENT* pAny, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]SubscribeToOperation(&this, pOperation, pUnknown, pAny, ppAny);

	public HRESULT UnsubscribeToOperation(WSD_OPERATION* pOperation) mut => VT.[Friend]UnsubscribeToOperation(&this, pOperation);

	public HRESULT SetEventingStatusCallback(IWSDEventingStatus* pStatus) mut => VT.[Friend]SetEventingStatusCallback(&this, pStatus);

	public HRESULT GetEndpointProxy(IWSDEndpointProxy** ppProxy) mut => VT.[Friend]GetEndpointProxy(&this, ppProxy);
}

[CRepr]struct IWSDServiceProxyEventing : IWSDServiceProxy
{
	public new const Guid IID = .(0xf9279d6d, 0x1012, 0x4a94, 0xb8, 0xcc, 0xfd, 0x35, 0xd2, 0x20, 0x2b, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWSDServiceProxy.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, IUnknown* pUnknown, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) SubscribeToMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, IUnknown* pUnknown, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) BeginSubscribeToMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) EndSubscribeToMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny) UnsubscribeToMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) BeginUnsubscribeToMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult) EndUnsubscribeToMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) RenewMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) BeginRenewMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) EndRenewMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) GetStatusForMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) BeginGetStatusForMultipleOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) EndGetStatusForMultipleOperations;
	}


	public HRESULT SubscribeToMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, IUnknown* pUnknown, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]SubscribeToMultipleOperations(&this, pOperations, dwOperationCount, pUnknown, pExpires, pAny, ppExpires, ppAny);

	public HRESULT BeginSubscribeToMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, IUnknown* pUnknown, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) mut => VT.[Friend]BeginSubscribeToMultipleOperations(&this, pOperations, dwOperationCount, pUnknown, pExpires, pAny, pAsyncState, pAsyncCallback, ppResult);

	public HRESULT EndSubscribeToMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]EndSubscribeToMultipleOperations(&this, pOperations, dwOperationCount, pResult, ppExpires, ppAny);

	public HRESULT UnsubscribeToMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny) mut => VT.[Friend]UnsubscribeToMultipleOperations(&this, pOperations, dwOperationCount, pAny);

	public HRESULT BeginUnsubscribeToMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) mut => VT.[Friend]BeginUnsubscribeToMultipleOperations(&this, pOperations, dwOperationCount, pAny, pAsyncState, pAsyncCallback, ppResult);

	public HRESULT EndUnsubscribeToMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult) mut => VT.[Friend]EndUnsubscribeToMultipleOperations(&this, pOperations, dwOperationCount, pResult);

	public HRESULT RenewMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]RenewMultipleOperations(&this, pOperations, dwOperationCount, pExpires, pAny, ppExpires, ppAny);

	public HRESULT BeginRenewMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, WSD_EVENTING_EXPIRES* pExpires, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) mut => VT.[Friend]BeginRenewMultipleOperations(&this, pOperations, dwOperationCount, pExpires, pAny, pAsyncState, pAsyncCallback, ppResult);

	public HRESULT EndRenewMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]EndRenewMultipleOperations(&this, pOperations, dwOperationCount, pResult, ppExpires, ppAny);

	public HRESULT GetStatusForMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]GetStatusForMultipleOperations(&this, pOperations, dwOperationCount, pAny, ppExpires, ppAny);

	public HRESULT BeginGetStatusForMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, WSDXML_ELEMENT* pAny, IUnknown* pAsyncState, IWSDAsyncCallback* pAsyncCallback, IWSDAsyncResult** ppResult) mut => VT.[Friend]BeginGetStatusForMultipleOperations(&this, pOperations, dwOperationCount, pAny, pAsyncState, pAsyncCallback, ppResult);

	public HRESULT EndGetStatusForMultipleOperations(WSD_OPERATION* pOperations, uint32 dwOperationCount, IWSDAsyncResult* pResult, WSD_EVENTING_EXPIRES** ppExpires, WSDXML_ELEMENT** ppAny) mut => VT.[Friend]EndGetStatusForMultipleOperations(&this, pOperations, dwOperationCount, pResult, ppExpires, ppAny);
}

[CRepr]struct IWSDDeviceProxy : IUnknown
{
	public new const Guid IID = .(0xeee0c031, 0xc578, 0x4c0e, 0x9a, 0x3b, 0x97, 0x3c, 0x35, 0xf4, 0x09, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceId, IWSDAddress* pDeviceAddress, PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDDeviceProxy* pSponsor) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncResult** ppResult) BeginGetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncResult* pResult) EndGetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_HOST_METADATA** ppHostMetadata) GetHostMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_THIS_MODEL_METADATA** ppManufacturerMetadata) GetThisModelMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_THIS_DEVICE_METADATA** ppThisDeviceMetadata) GetThisDeviceMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_METADATA_SECTION_LIST** ppMetadata) GetAllMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId, IWSDServiceProxy** ppServiceProxy) GetServiceProxyById;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSDXML_NAME* pType, IWSDServiceProxy** ppServiceProxy) GetServiceProxyByType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDEndpointProxy** ppProxy) GetEndpointProxy;
	}


	public HRESULT Init(PWSTR pszDeviceId, IWSDAddress* pDeviceAddress, PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDDeviceProxy* pSponsor) mut => VT.[Friend]Init(&this, pszDeviceId, pDeviceAddress, pszLocalId, pContext, pSponsor);

	public HRESULT BeginGetMetadata(IWSDAsyncResult** ppResult) mut => VT.[Friend]BeginGetMetadata(&this, ppResult);

	public HRESULT EndGetMetadata(IWSDAsyncResult* pResult) mut => VT.[Friend]EndGetMetadata(&this, pResult);

	public HRESULT GetHostMetadata(WSD_HOST_METADATA** ppHostMetadata) mut => VT.[Friend]GetHostMetadata(&this, ppHostMetadata);

	public HRESULT GetThisModelMetadata(WSD_THIS_MODEL_METADATA** ppManufacturerMetadata) mut => VT.[Friend]GetThisModelMetadata(&this, ppManufacturerMetadata);

	public HRESULT GetThisDeviceMetadata(WSD_THIS_DEVICE_METADATA** ppThisDeviceMetadata) mut => VT.[Friend]GetThisDeviceMetadata(&this, ppThisDeviceMetadata);

	public HRESULT GetAllMetadata(WSD_METADATA_SECTION_LIST** ppMetadata) mut => VT.[Friend]GetAllMetadata(&this, ppMetadata);

	public HRESULT GetServiceProxyById(PWSTR pszServiceId, IWSDServiceProxy** ppServiceProxy) mut => VT.[Friend]GetServiceProxyById(&this, pszServiceId, ppServiceProxy);

	public HRESULT GetServiceProxyByType(WSDXML_NAME* pType, IWSDServiceProxy** ppServiceProxy) mut => VT.[Friend]GetServiceProxyByType(&this, pType, ppServiceProxy);

	public HRESULT GetEndpointProxy(IWSDEndpointProxy** ppProxy) mut => VT.[Friend]GetEndpointProxy(&this, ppProxy);
}

[CRepr]struct IWSDAsyncResult : IUnknown
{
	public new const Guid IID = .(0x11a9852a, 0x8dd8, 0x423e, 0xb5, 0x37, 0x93, 0x56, 0xdb, 0x4f, 0xbf, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncCallback* pCallback, IUnknown* pAsyncState) SetCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hWaitHandle) SetWaitHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) HasCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppAsyncState) GetAsyncState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_EVENT* pEvent) GetEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDEndpointProxy** ppEndpoint) GetEndpointProxy;
	}


	public HRESULT SetCallback(IWSDAsyncCallback* pCallback, IUnknown* pAsyncState) mut => VT.[Friend]SetCallback(&this, pCallback, pAsyncState);

	public HRESULT SetWaitHandle(HANDLE hWaitHandle) mut => VT.[Friend]SetWaitHandle(&this, hWaitHandle);

	public HRESULT HasCompleted() mut => VT.[Friend]HasCompleted(&this);

	public HRESULT GetAsyncState(IUnknown** ppAsyncState) mut => VT.[Friend]GetAsyncState(&this, ppAsyncState);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);

	public HRESULT GetEvent(WSD_EVENT* pEvent) mut => VT.[Friend]GetEvent(&this, pEvent);

	public HRESULT GetEndpointProxy(IWSDEndpointProxy** ppEndpoint) mut => VT.[Friend]GetEndpointProxy(&this, ppEndpoint);
}

[CRepr]struct IWSDAsyncCallback : IUnknown
{
	public new const Guid IID = .(0xa63e109d, 0xce72, 0x49e2, 0xba, 0x98, 0xe8, 0x45, 0xf5, 0xee, 0x16, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWSDAsyncResult* pAsyncResult, IUnknown* pAsyncState) AsyncOperationComplete;
	}


	public HRESULT AsyncOperationComplete(IWSDAsyncResult* pAsyncResult, IUnknown* pAsyncState) mut => VT.[Friend]AsyncOperationComplete(&this, pAsyncResult, pAsyncState);
}

[CRepr]struct IWSDEventingStatus : IUnknown
{
	public new const Guid IID = .(0x49b17f52, 0x637a, 0x407a, 0xae, 0x99, 0xfb, 0xe8, 0x2a, 0x4d, 0x38, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, PWSTR pszSubscriptionAction) SubscriptionRenewed;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, PWSTR pszSubscriptionAction, HRESULT hr) SubscriptionRenewalFailed;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, PWSTR pszSubscriptionAction) SubscriptionEnded;
	}


	public void SubscriptionRenewed(PWSTR pszSubscriptionAction) mut => VT.[Friend]SubscriptionRenewed(&this, pszSubscriptionAction);

	public void SubscriptionRenewalFailed(PWSTR pszSubscriptionAction, HRESULT hr) mut => VT.[Friend]SubscriptionRenewalFailed(&this, pszSubscriptionAction, hr);

	public void SubscriptionEnded(PWSTR pszSubscriptionAction) mut => VT.[Friend]SubscriptionEnded(&this, pszSubscriptionAction);
}

[CRepr]struct IWSDDeviceHost : IUnknown
{
	public new const Guid IID = .(0x917fe891, 0x3d13, 0x4138, 0x98, 0x09, 0x93, 0x4c, 0x8a, 0xbe, 0xb1, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDAddress** ppHostAddresses, uint32 dwHostAddressCount) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullInstanceId, WSD_URI_LIST* pScopeList, IWSDDeviceHostNotify* pNotificationSink) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_PORT_TYPE* pPortType) RegisterPortType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_THIS_MODEL_METADATA* pThisModelMetadata, WSD_THIS_DEVICE_METADATA* pThisDeviceMetadata, WSD_HOST_METADATA* pHostMetadata, WSD_METADATA_SECTION_LIST* pCustomMetadata) SetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId, IUnknown* pService) RegisterService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId) RetireService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId, PWSTR pszEndpointAddress, WSD_PORT_TYPE* pPortType, WSDXML_NAME* pPortName, WSDXML_ELEMENT* pAny, IUnknown* pService) AddDynamicService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId) RemoveDynamicService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId, BOOL fDiscoverable) SetServiceDiscoverable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId, void* pBody, WSD_OPERATION* pOperation) SignalEvent;
	}


	public HRESULT Init(PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDAddress** ppHostAddresses, uint32 dwHostAddressCount) mut => VT.[Friend]Init(&this, pszLocalId, pContext, ppHostAddresses, dwHostAddressCount);

	public HRESULT Start(uint64 ullInstanceId, WSD_URI_LIST* pScopeList, IWSDDeviceHostNotify* pNotificationSink) mut => VT.[Friend]Start(&this, ullInstanceId, pScopeList, pNotificationSink);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Terminate() mut => VT.[Friend]Terminate(&this);

	public HRESULT RegisterPortType(WSD_PORT_TYPE* pPortType) mut => VT.[Friend]RegisterPortType(&this, pPortType);

	public HRESULT SetMetadata(WSD_THIS_MODEL_METADATA* pThisModelMetadata, WSD_THIS_DEVICE_METADATA* pThisDeviceMetadata, WSD_HOST_METADATA* pHostMetadata, WSD_METADATA_SECTION_LIST* pCustomMetadata) mut => VT.[Friend]SetMetadata(&this, pThisModelMetadata, pThisDeviceMetadata, pHostMetadata, pCustomMetadata);

	public HRESULT RegisterService(PWSTR pszServiceId, IUnknown* pService) mut => VT.[Friend]RegisterService(&this, pszServiceId, pService);

	public HRESULT RetireService(PWSTR pszServiceId) mut => VT.[Friend]RetireService(&this, pszServiceId);

	public HRESULT AddDynamicService(PWSTR pszServiceId, PWSTR pszEndpointAddress, WSD_PORT_TYPE* pPortType, WSDXML_NAME* pPortName, WSDXML_ELEMENT* pAny, IUnknown* pService) mut => VT.[Friend]AddDynamicService(&this, pszServiceId, pszEndpointAddress, pPortType, pPortName, pAny, pService);

	public HRESULT RemoveDynamicService(PWSTR pszServiceId) mut => VT.[Friend]RemoveDynamicService(&this, pszServiceId);

	public HRESULT SetServiceDiscoverable(PWSTR pszServiceId, BOOL fDiscoverable) mut => VT.[Friend]SetServiceDiscoverable(&this, pszServiceId, fDiscoverable);

	public HRESULT SignalEvent(PWSTR pszServiceId, void* pBody, WSD_OPERATION* pOperation) mut => VT.[Friend]SignalEvent(&this, pszServiceId, pBody, pOperation);
}

[CRepr]struct IWSDDeviceHostNotify : IUnknown
{
	public new const Guid IID = .(0xb5bee9f9, 0xeeda, 0x41fe, 0x96, 0xf7, 0xf4, 0x5e, 0x14, 0x99, 0x0f, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServiceId, IUnknown** ppService) GetService;
	}


	public HRESULT GetService(PWSTR pszServiceId, IUnknown** ppService) mut => VT.[Friend]GetService(&this, pszServiceId, ppService);
}

[CRepr]struct IWSDServiceMessaging : IUnknown
{
	public new const Guid IID = .(0x94974cf4, 0x0cab, 0x460d, 0xa3, 0xf6, 0x7a, 0x0a, 0xd6, 0x23, 0xc0, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pBody, WSD_OPERATION* pOperation, IWSDMessageParameters* pMessageParameters) SendResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSD_SOAP_HEADER* pRequestHeader, IWSDMessageParameters* pMessageParameters, WSD_SOAP_FAULT* pFault) FaultRequest;
	}


	public HRESULT SendResponse(void* pBody, WSD_OPERATION* pOperation, IWSDMessageParameters* pMessageParameters) mut => VT.[Friend]SendResponse(&this, pBody, pOperation, pMessageParameters);

	public HRESULT FaultRequest(WSD_SOAP_HEADER* pRequestHeader, IWSDMessageParameters* pMessageParameters, WSD_SOAP_FAULT* pFault) mut => VT.[Friend]FaultRequest(&this, pRequestHeader, pMessageParameters, pFault);
}

#endregion

#region Functions
public static
{
	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateUdpMessageParameters(IWSDUdpMessageParameters** ppTxParams);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateUdpAddress(IWSDUdpAddress** ppAddress);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateHttpMessageParameters(IWSDHttpMessageParameters** ppTxParams);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateHttpAddress(IWSDHttpAddress** ppAddress);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateOutboundAttachment(IWSDOutboundAttachment** ppAttachment);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLGetNameFromBuiltinNamespace(PWSTR pszNamespace, PWSTR pszName, WSDXML_NAME** ppName);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLCreateContext(IWSDXMLContext** ppContext);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDiscoveryProvider(IWSDXMLContext* pContext, IWSDiscoveryProvider** ppProvider);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDiscoveryProvider2(IWSDXMLContext* pContext, WSD_CONFIG_PARAM* pConfigParams, uint32 dwConfigParamCount, IWSDiscoveryProvider** ppProvider);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDiscoveryPublisher(IWSDXMLContext* pContext, IWSDiscoveryPublisher** ppPublisher);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDiscoveryPublisher2(IWSDXMLContext* pContext, WSD_CONFIG_PARAM* pConfigParams, uint32 dwConfigParamCount, IWSDiscoveryPublisher** ppPublisher);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDeviceProxy(PWSTR pszDeviceId, PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDDeviceProxy** ppDeviceProxy);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDeviceProxyAdvanced(PWSTR pszDeviceId, IWSDAddress* pDeviceAddress, PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDDeviceProxy** ppDeviceProxy);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDeviceProxy2(PWSTR pszDeviceId, PWSTR pszLocalId, IWSDXMLContext* pContext, WSD_CONFIG_PARAM* pConfigParams, uint32 dwConfigParamCount, IWSDDeviceProxy** ppDeviceProxy);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDeviceHost(PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDDeviceHost** ppDeviceHost);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDeviceHostAdvanced(PWSTR pszLocalId, IWSDXMLContext* pContext, IWSDAddress** ppHostAddresses, uint32 dwHostAddressCount, IWSDDeviceHost** ppDeviceHost);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDCreateDeviceHost2(PWSTR pszLocalId, IWSDXMLContext* pContext, WSD_CONFIG_PARAM* pConfigParams, uint32 dwConfigParamCount, IWSDDeviceHost** ppDeviceHost);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDSetConfigurationOption(uint32 dwOption, void* pVoid, uint32 cbInBuffer);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDGetConfigurationOption(uint32 dwOption, void* pVoid, uint32 cbOutBuffer);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WSDAllocateLinkedMemory(void* pParent, uint cbSize);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WSDFreeLinkedMemory(void* pVoid);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WSDAttachLinkedMemory(void* pParent, void* pChild);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WSDDetachLinkedMemory(void* pVoid);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLBuildAnyForSingleElement(WSDXML_NAME* pElementName, PWSTR pszText, WSDXML_ELEMENT** ppAny);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLGetValueFromAny(PWSTR pszNamespace, PWSTR pszName, WSDXML_ELEMENT* pAny, PWSTR* ppszValue);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLAddSibling(WSDXML_ELEMENT* pFirst, WSDXML_ELEMENT* pSecond);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLAddChild(WSDXML_ELEMENT* pParent, WSDXML_ELEMENT* pChild);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDXMLCleanupElement(WSDXML_ELEMENT* pAny);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDGenerateFault(PWSTR pszCode, PWSTR pszSubCode, PWSTR pszReason, PWSTR pszDetail, IWSDXMLContext* pContext, WSD_SOAP_FAULT** ppFault);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDGenerateFaultEx(WSDXML_NAME* pCode, WSDXML_NAME* pSubCode, WSD_LOCALIZED_STRING_LIST* pReasons, PWSTR pszDetail, WSD_SOAP_FAULT** ppFault);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDUriEncode(char16* source, uint32 cchSource, PWSTR* destOut, uint32* cchDestOut);

	[Import("wsdapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WSDUriDecode(char16* source, uint32 cchSource, PWSTR* destOut, uint32* cchDestOut);

}
#endregion
