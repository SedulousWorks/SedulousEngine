using Win32.Foundation;
using Win32.Security;
using Win32.Networking.WinSock;
using Win32.System.IO;
using System;

namespace Win32.Networking.HttpServer;

#region Constants
public static
{
	public const uint32 HTTP_DEMAND_CBT = 4;
	public const uint32 HTTP_MAX_SERVER_QUEUE_LENGTH = 2147483647;
	public const uint32 HTTP_MIN_SERVER_QUEUE_LENGTH = 1;
	public const uint32 HTTP_AUTH_ENABLE_BASIC = 1;
	public const uint32 HTTP_AUTH_ENABLE_DIGEST = 2;
	public const uint32 HTTP_AUTH_ENABLE_NTLM = 4;
	public const uint32 HTTP_AUTH_ENABLE_NEGOTIATE = 8;
	public const uint32 HTTP_AUTH_ENABLE_KERBEROS = 16;
	public const uint32 HTTP_AUTH_EX_FLAG_ENABLE_KERBEROS_CREDENTIAL_CACHING = 1;
	public const uint32 HTTP_AUTH_EX_FLAG_CAPTURE_CREDENTIAL = 2;
	public const uint32 HTTP_CHANNEL_BIND_PROXY = 1;
	public const uint32 HTTP_CHANNEL_BIND_PROXY_COHOSTING = 32;
	public const uint32 HTTP_CHANNEL_BIND_NO_SERVICE_NAME_CHECK = 2;
	public const uint32 HTTP_CHANNEL_BIND_DOTLESS_SERVICE = 4;
	public const uint32 HTTP_CHANNEL_BIND_SECURE_CHANNEL_TOKEN = 8;
	public const uint32 HTTP_CHANNEL_BIND_CLIENT_SERVICE = 16;
	public const uint32 HTTP_LOG_FIELD_DATE = 1;
	public const uint32 HTTP_LOG_FIELD_TIME = 2;
	public const uint32 HTTP_LOG_FIELD_CLIENT_IP = 4;
	public const uint32 HTTP_LOG_FIELD_USER_NAME = 8;
	public const uint32 HTTP_LOG_FIELD_SITE_NAME = 16;
	public const uint32 HTTP_LOG_FIELD_COMPUTER_NAME = 32;
	public const uint32 HTTP_LOG_FIELD_SERVER_IP = 64;
	public const uint32 HTTP_LOG_FIELD_METHOD = 128;
	public const uint32 HTTP_LOG_FIELD_URI_STEM = 256;
	public const uint32 HTTP_LOG_FIELD_URI_QUERY = 512;
	public const uint32 HTTP_LOG_FIELD_STATUS = 1024;
	public const uint32 HTTP_LOG_FIELD_WIN32_STATUS = 2048;
	public const uint32 HTTP_LOG_FIELD_BYTES_SENT = 4096;
	public const uint32 HTTP_LOG_FIELD_BYTES_RECV = 8192;
	public const uint32 HTTP_LOG_FIELD_TIME_TAKEN = 16384;
	public const uint32 HTTP_LOG_FIELD_SERVER_PORT = 32768;
	public const uint32 HTTP_LOG_FIELD_USER_AGENT = 65536;
	public const uint32 HTTP_LOG_FIELD_COOKIE = 131072;
	public const uint32 HTTP_LOG_FIELD_REFERER = 262144;
	public const uint32 HTTP_LOG_FIELD_VERSION = 524288;
	public const uint32 HTTP_LOG_FIELD_HOST = 1048576;
	public const uint32 HTTP_LOG_FIELD_SUB_STATUS = 2097152;
	public const uint32 HTTP_LOG_FIELD_STREAM_ID = 134217728;
	public const uint32 HTTP_LOG_FIELD_STREAM_ID_EX = 268435456;
	public const uint32 HTTP_LOG_FIELD_TRANSPORT_TYPE = 536870912;
	public const uint32 HTTP_LOG_FIELD_CLIENT_PORT = 4194304;
	public const uint32 HTTP_LOG_FIELD_URI = 8388608;
	public const uint32 HTTP_LOG_FIELD_SITE_ID = 16777216;
	public const uint32 HTTP_LOG_FIELD_REASON = 33554432;
	public const uint32 HTTP_LOG_FIELD_QUEUE_NAME = 67108864;
	public const uint32 HTTP_LOG_FIELD_CORRELATION_ID = 1073741824;
	public const uint32 HTTP_LOGGING_FLAG_LOCAL_TIME_ROLLOVER = 1;
	public const uint32 HTTP_LOGGING_FLAG_USE_UTF8_CONVERSION = 2;
	public const uint32 HTTP_LOGGING_FLAG_LOG_ERRORS_ONLY = 4;
	public const uint32 HTTP_LOGGING_FLAG_LOG_SUCCESS_ONLY = 8;
	public const uint32 HTTP_CREATE_REQUEST_QUEUE_FLAG_OPEN_EXISTING = 1;
	public const uint32 HTTP_CREATE_REQUEST_QUEUE_FLAG_CONTROLLER = 2;
	public const uint32 HTTP_CREATE_REQUEST_QUEUE_FLAG_DELEGATION = 8;
	public const uint32 HTTP_RECEIVE_REQUEST_ENTITY_BODY_FLAG_FILL_BUFFER = 1;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_DISCONNECT = 1;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_MORE_DATA = 2;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_BUFFER_DATA = 4;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_ENABLE_NAGLING = 8;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_PROCESS_RANGES = 32;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_OPAQUE = 64;
	public const uint32 HTTP_SEND_RESPONSE_FLAG_GOAWAY = 256;
	public const uint32 HTTP_FLUSH_RESPONSE_FLAG_RECURSIVE = 1;
	public const uint32 HTTP_URL_FLAG_REMOVE_ALL = 1;
	public const uint32 HTTP_RECEIVE_SECURE_CHANNEL_TOKEN = 1;
	public const uint32 HTTP_RECEIVE_FULL_CHAIN = 2;
	public const uint32 HTTP_REQUEST_SIZING_INFO_FLAG_TCP_FAST_OPEN = 1;
	public const uint32 HTTP_REQUEST_SIZING_INFO_FLAG_TLS_SESSION_RESUMPTION = 2;
	public const uint32 HTTP_REQUEST_SIZING_INFO_FLAG_TLS_FALSE_START = 4;
	public const uint32 HTTP_REQUEST_SIZING_INFO_FLAG_FIRST_REQUEST = 8;
	public const uint32 HTTP_REQUEST_AUTH_FLAG_TOKEN_FOR_CACHED_CRED = 1;
	public const uint32 HTTP_REQUEST_FLAG_MORE_ENTITY_BODY_EXISTS = 1;
	public const uint32 HTTP_REQUEST_FLAG_IP_ROUTED = 2;
	public const uint32 HTTP_REQUEST_FLAG_HTTP2 = 4;
	public const uint32 HTTP_REQUEST_FLAG_HTTP3 = 8;
	public const uint32 HTTP_RESPONSE_FLAG_MULTIPLE_ENCODINGS_AVAILABLE = 1;
	public const uint32 HTTP_RESPONSE_FLAG_MORE_ENTITY_BODY_EXISTS = 2;
	public const uint32 HTTP_RESPONSE_INFO_FLAGS_PRESERVE_ORDER = 1;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_USE_DS_MAPPER = 1;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_NEGOTIATE_CLIENT_CERT = 2;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_NO_RAW_FILTER = 4;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_REJECT = 8;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_DISABLE_HTTP2 = 16;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_DISABLE_QUIC = 32;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_DISABLE_TLS13 = 64;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_DISABLE_OCSP_STAPLING = 128;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_ENABLE_TOKEN_BINDING = 256;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_LOG_EXTENDED_EVENTS = 512;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_DISABLE_LEGACY_TLS = 1024;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_ENABLE_SESSION_TICKET = 2048;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_DISABLE_TLS12 = 4096;
	public const uint32 HTTP_SERVICE_CONFIG_SSL_FLAG_ENABLE_CLIENT_CORRELATION = 8192;
	public const uint32 HTTP_REQUEST_PROPERTY_SNI_HOST_MAX_LENGTH = 255;
	public const uint32 HTTP_REQUEST_PROPERTY_SNI_FLAG_SNI_USED = 1;
	public const uint32 HTTP_REQUEST_PROPERTY_SNI_FLAG_NO_SNI = 2;
	public const String HTTP_VERSION = "HTTP/1.0";
}
#endregion

#region Enums

[AllowDuplicates]
public enum HTTP_RECEIVE_HTTP_REQUEST_FLAGS : uint32
{
	HTTP_RECEIVE_REQUEST_FLAG_COPY_BODY = 1,
	HTTP_RECEIVE_REQUEST_FLAG_FLUSH_BODY = 2,
}


[AllowDuplicates]
public enum HTTP_INITIALIZE : uint32
{
	HTTP_INITIALIZE_CONFIG = 2,
	HTTP_INITIALIZE_SERVER = 1,
}


[AllowDuplicates]
public enum HTTP_SERVER_PROPERTY : int32
{
	HttpServerAuthenticationProperty = 0,
	HttpServerLoggingProperty = 1,
	HttpServerQosProperty = 2,
	HttpServerTimeoutsProperty = 3,
	HttpServerQueueLengthProperty = 4,
	HttpServerStateProperty = 5,
	HttpServer503VerbosityProperty = 6,
	HttpServerBindingProperty = 7,
	HttpServerExtendedAuthenticationProperty = 8,
	HttpServerListenEndpointProperty = 9,
	HttpServerChannelBindProperty = 10,
	HttpServerProtectionLevelProperty = 11,
	HttpServerDelegationProperty = 16,
}


[AllowDuplicates]
public enum HTTP_ENABLED_STATE : int32
{
	HttpEnabledStateActive = 0,
	HttpEnabledStateInactive = 1,
}


[AllowDuplicates]
public enum HTTP_503_RESPONSE_VERBOSITY : int32
{
	Http503ResponseVerbosityBasic = 0,
	Http503ResponseVerbosityLimited = 1,
	Http503ResponseVerbosityFull = 2,
}


[AllowDuplicates]
public enum HTTP_QOS_SETTING_TYPE : int32
{
	HttpQosSettingTypeBandwidth = 0,
	HttpQosSettingTypeConnectionLimit = 1,
	HttpQosSettingTypeFlowRate = 2,
}


[AllowDuplicates]
public enum HTTP_SERVICE_CONFIG_TIMEOUT_KEY : int32
{
	IdleConnectionTimeout = 0,
	HeaderWaitTimeout = 1,
}


[AllowDuplicates]
public enum HTTP_SERVICE_CONFIG_SETTING_KEY : int32
{
	HttpNone = 0,
	HttpTlsThrottle = 1,
}


[AllowDuplicates]
public enum HTTP_SERVICE_BINDING_TYPE : int32
{
	HttpServiceBindingTypeNone = 0,
	HttpServiceBindingTypeW = 1,
	HttpServiceBindingTypeA = 2,
}


[AllowDuplicates]
public enum HTTP_AUTHENTICATION_HARDENING_LEVELS : int32
{
	HttpAuthenticationHardeningLegacy = 0,
	HttpAuthenticationHardeningMedium = 1,
	HttpAuthenticationHardeningStrict = 2,
}


[AllowDuplicates]
public enum HTTP_LOGGING_TYPE : int32
{
	HttpLoggingTypeW3C = 0,
	HttpLoggingTypeIIS = 1,
	HttpLoggingTypeNCSA = 2,
	HttpLoggingTypeRaw = 3,
}


[AllowDuplicates]
public enum HTTP_LOGGING_ROLLOVER_TYPE : int32
{
	HttpLoggingRolloverSize = 0,
	HttpLoggingRolloverDaily = 1,
	HttpLoggingRolloverWeekly = 2,
	HttpLoggingRolloverMonthly = 3,
	HttpLoggingRolloverHourly = 4,
}


[AllowDuplicates]
public enum HTTP_PROTECTION_LEVEL_TYPE : int32
{
	HttpProtectionLevelUnrestricted = 0,
	HttpProtectionLevelEdgeRestricted = 1,
	HttpProtectionLevelRestricted = 2,
}


[AllowDuplicates]
public enum HTTP_SCHEME : int32
{
	HttpSchemeHttp = 0,
	HttpSchemeHttps = 1,
	HttpSchemeMaximum = 2,
}


[AllowDuplicates]
public enum HTTP_VERB : int32
{
	HttpVerbUnparsed = 0,
	HttpVerbUnknown = 1,
	HttpVerbInvalid = 2,
	HttpVerbOPTIONS = 3,
	HttpVerbGET = 4,
	HttpVerbHEAD = 5,
	HttpVerbPOST = 6,
	HttpVerbPUT = 7,
	HttpVerbDELETE = 8,
	HttpVerbTRACE = 9,
	HttpVerbCONNECT = 10,
	HttpVerbTRACK = 11,
	HttpVerbMOVE = 12,
	HttpVerbCOPY = 13,
	HttpVerbPROPFIND = 14,
	HttpVerbPROPPATCH = 15,
	HttpVerbMKCOL = 16,
	HttpVerbLOCK = 17,
	HttpVerbUNLOCK = 18,
	HttpVerbSEARCH = 19,
	HttpVerbMaximum = 20,
}


[AllowDuplicates]
public enum HTTP_HEADER_ID : int32
{
	HttpHeaderCacheControl = 0,
	HttpHeaderConnection = 1,
	HttpHeaderDate = 2,
	HttpHeaderKeepAlive = 3,
	HttpHeaderPragma = 4,
	HttpHeaderTrailer = 5,
	HttpHeaderTransferEncoding = 6,
	HttpHeaderUpgrade = 7,
	HttpHeaderVia = 8,
	HttpHeaderWarning = 9,
	HttpHeaderAllow = 10,
	HttpHeaderContentLength = 11,
	HttpHeaderContentType = 12,
	HttpHeaderContentEncoding = 13,
	HttpHeaderContentLanguage = 14,
	HttpHeaderContentLocation = 15,
	HttpHeaderContentMd5 = 16,
	HttpHeaderContentRange = 17,
	HttpHeaderExpires = 18,
	HttpHeaderLastModified = 19,
	HttpHeaderAccept = 20,
	HttpHeaderAcceptCharset = 21,
	HttpHeaderAcceptEncoding = 22,
	HttpHeaderAcceptLanguage = 23,
	HttpHeaderAuthorization = 24,
	HttpHeaderCookie = 25,
	HttpHeaderExpect = 26,
	HttpHeaderFrom = 27,
	HttpHeaderHost = 28,
	HttpHeaderIfMatch = 29,
	HttpHeaderIfModifiedSince = 30,
	HttpHeaderIfNoneMatch = 31,
	HttpHeaderIfRange = 32,
	HttpHeaderIfUnmodifiedSince = 33,
	HttpHeaderMaxForwards = 34,
	HttpHeaderProxyAuthorization = 35,
	HttpHeaderReferer = 36,
	HttpHeaderRange = 37,
	HttpHeaderTe = 38,
	HttpHeaderTranslate = 39,
	HttpHeaderUserAgent = 40,
	HttpHeaderRequestMaximum = 41,
	HttpHeaderAcceptRanges = 20,
	HttpHeaderAge = 21,
	HttpHeaderEtag = 22,
	HttpHeaderLocation = 23,
	HttpHeaderProxyAuthenticate = 24,
	HttpHeaderRetryAfter = 25,
	HttpHeaderServer = 26,
	HttpHeaderSetCookie = 27,
	HttpHeaderVary = 28,
	HttpHeaderWwwAuthenticate = 29,
	HttpHeaderResponseMaximum = 30,
	HttpHeaderMaximum = 41,
}


[AllowDuplicates]
public enum HTTP_LOG_DATA_TYPE : int32
{
	HttpLogDataTypeFields = 0,
}


[AllowDuplicates]
public enum HTTP_DATA_CHUNK_TYPE : int32
{
	HttpDataChunkFromMemory = 0,
	HttpDataChunkFromFileHandle = 1,
	HttpDataChunkFromFragmentCache = 2,
	HttpDataChunkFromFragmentCacheEx = 3,
	HttpDataChunkTrailers = 4,
	HttpDataChunkMaximum = 5,
}


[AllowDuplicates]
public enum HTTP_DELEGATE_REQUEST_PROPERTY_ID : int32
{
	DelegateRequestReservedProperty = 0,
	DelegateRequestDelegateUrlProperty = 1,
}


[AllowDuplicates]
public enum HTTP_CREATE_REQUEST_QUEUE_PROPERTY_ID : int32
{
	CreateRequestQueueExternalIdProperty = 1,
	CreateRequestQueueMax = 2,
}


[AllowDuplicates]
public enum HTTP_AUTH_STATUS : int32
{
	HttpAuthStatusSuccess = 0,
	HttpAuthStatusNotAuthenticated = 1,
	HttpAuthStatusFailure = 2,
}


[AllowDuplicates]
public enum HTTP_REQUEST_AUTH_TYPE : int32
{
	HttpRequestAuthTypeNone = 0,
	HttpRequestAuthTypeBasic = 1,
	HttpRequestAuthTypeDigest = 2,
	HttpRequestAuthTypeNTLM = 3,
	HttpRequestAuthTypeNegotiate = 4,
	HttpRequestAuthTypeKerberos = 5,
}


[AllowDuplicates]
public enum HTTP_REQUEST_SIZING_TYPE : int32
{
	HttpRequestSizingTypeTlsHandshakeLeg1ClientData = 0,
	HttpRequestSizingTypeTlsHandshakeLeg1ServerData = 1,
	HttpRequestSizingTypeTlsHandshakeLeg2ClientData = 2,
	HttpRequestSizingTypeTlsHandshakeLeg2ServerData = 3,
	HttpRequestSizingTypeHeaders = 4,
	HttpRequestSizingTypeMax = 5,
}


[AllowDuplicates]
public enum HTTP_REQUEST_TIMING_TYPE : int32
{
	HttpRequestTimingTypeConnectionStart = 0,
	HttpRequestTimingTypeDataStart = 1,
	HttpRequestTimingTypeTlsCertificateLoadStart = 2,
	HttpRequestTimingTypeTlsCertificateLoadEnd = 3,
	HttpRequestTimingTypeTlsHandshakeLeg1Start = 4,
	HttpRequestTimingTypeTlsHandshakeLeg1End = 5,
	HttpRequestTimingTypeTlsHandshakeLeg2Start = 6,
	HttpRequestTimingTypeTlsHandshakeLeg2End = 7,
	HttpRequestTimingTypeTlsAttributesQueryStart = 8,
	HttpRequestTimingTypeTlsAttributesQueryEnd = 9,
	HttpRequestTimingTypeTlsClientCertQueryStart = 10,
	HttpRequestTimingTypeTlsClientCertQueryEnd = 11,
	HttpRequestTimingTypeHttp2StreamStart = 12,
	HttpRequestTimingTypeHttp2HeaderDecodeStart = 13,
	HttpRequestTimingTypeHttp2HeaderDecodeEnd = 14,
	HttpRequestTimingTypeRequestHeaderParseStart = 15,
	HttpRequestTimingTypeRequestHeaderParseEnd = 16,
	HttpRequestTimingTypeRequestRoutingStart = 17,
	HttpRequestTimingTypeRequestRoutingEnd = 18,
	HttpRequestTimingTypeRequestQueuedForInspection = 19,
	HttpRequestTimingTypeRequestDeliveredForInspection = 20,
	HttpRequestTimingTypeRequestReturnedAfterInspection = 21,
	HttpRequestTimingTypeRequestQueuedForDelegation = 22,
	HttpRequestTimingTypeRequestDeliveredForDelegation = 23,
	HttpRequestTimingTypeRequestReturnedAfterDelegation = 24,
	HttpRequestTimingTypeRequestQueuedForIO = 25,
	HttpRequestTimingTypeRequestDeliveredForIO = 26,
	HttpRequestTimingTypeHttp3StreamStart = 27,
	HttpRequestTimingTypeHttp3HeaderDecodeStart = 28,
	HttpRequestTimingTypeHttp3HeaderDecodeEnd = 29,
	HttpRequestTimingTypeMax = 30,
}


[AllowDuplicates]
public enum HTTP_REQUEST_INFO_TYPE : int32
{
	HttpRequestInfoTypeAuth = 0,
	HttpRequestInfoTypeChannelBind = 1,
	HttpRequestInfoTypeSslProtocol = 2,
	HttpRequestInfoTypeSslTokenBindingDraft = 3,
	HttpRequestInfoTypeSslTokenBinding = 4,
	HttpRequestInfoTypeRequestTiming = 5,
	HttpRequestInfoTypeTcpInfoV0 = 6,
	HttpRequestInfoTypeRequestSizing = 7,
	HttpRequestInfoTypeQuicStats = 8,
	HttpRequestInfoTypeTcpInfoV1 = 9,
}


[AllowDuplicates]
public enum HTTP_RESPONSE_INFO_TYPE : int32
{
	HttpResponseInfoTypeMultipleKnownHeaders = 0,
	HttpResponseInfoTypeAuthenticationProperty = 1,
	HttpResponseInfoTypeQoSProperty = 2,
	HttpResponseInfoTypeChannelBind = 3,
}


[AllowDuplicates]
public enum HTTP_CACHE_POLICY_TYPE : int32
{
	HttpCachePolicyNocache = 0,
	HttpCachePolicyUserInvalidates = 1,
	HttpCachePolicyTimeToLive = 2,
	HttpCachePolicyMaximum = 3,
}


[AllowDuplicates]
public enum HTTP_SERVICE_CONFIG_ID : int32
{
	HttpServiceConfigIPListenList = 0,
	HttpServiceConfigSSLCertInfo = 1,
	HttpServiceConfigUrlAclInfo = 2,
	HttpServiceConfigTimeout = 3,
	HttpServiceConfigCache = 4,
	HttpServiceConfigSslSniCertInfo = 5,
	HttpServiceConfigSslCcsCertInfo = 6,
	HttpServiceConfigSetting = 7,
	HttpServiceConfigSslCertInfoEx = 8,
	HttpServiceConfigSslSniCertInfoEx = 9,
	HttpServiceConfigSslCcsCertInfoEx = 10,
	HttpServiceConfigSslScopedCcsCertInfo = 11,
	HttpServiceConfigSslScopedCcsCertInfoEx = 12,
	HttpServiceConfigMax = 13,
}


[AllowDuplicates]
public enum HTTP_SERVICE_CONFIG_QUERY_TYPE : int32
{
	HttpServiceConfigQueryExact = 0,
	HttpServiceConfigQueryNext = 1,
	HttpServiceConfigQueryMax = 2,
}


[AllowDuplicates]
public enum HTTP_SSL_SERVICE_CONFIG_EX_PARAM_TYPE : int32
{
	ExParamTypeHttp2Window = 0,
	ExParamTypeHttp2SettingsLimits = 1,
	ExParamTypeHttpPerformance = 2,
	ExParamTypeTlsRestrictions = 3,
	ExParamTypeErrorHeaders = 4,
	ExParamTypeTlsSessionTicketKeys = 5,
	ExParamTypeMax = 6,
}


[AllowDuplicates]
public enum HTTP_PERFORMANCE_PARAM_TYPE : int32
{
	PerformanceParamSendBufferingFlags = 0,
	PerformanceParamAggressiveICW = 1,
	PerformanceParamMaxSendBufferSize = 2,
	PerformanceParamMaxConcurrentClientStreams = 3,
	PerformanceParamMaxReceiveBufferSize = 4,
	PerformanceParamDecryptOnSspiThread = 5,
	PerformanceParamMax = 6,
}


[AllowDuplicates]
public enum HTTP_SERVICE_CONFIG_CACHE_KEY : int32
{
	MaxCacheResponseSize = 0,
	CacheRangeChunkSize = 1,
}


[AllowDuplicates]
public enum HTTP_REQUEST_PROPERTY : int32
{
	HttpRequestPropertyIsb = 0,
	HttpRequestPropertyTcpInfoV0 = 1,
	HttpRequestPropertyQuicStats = 2,
	HttpRequestPropertyTcpInfoV1 = 3,
	HttpRequestPropertySni = 4,
	HttpRequestPropertyStreamError = 5,
	HttpRequestPropertyWskApiTimings = 6,
	HttpRequestPropertyQuicApiTimings = 7,
}


[AllowDuplicates]
public enum HTTP_FEATURE_ID : int32
{
	HttpFeatureUnknown = 0,
	HttpFeatureResponseTrailers = 1,
	HttpFeatureApiTimings = 2,
	HttpFeatureDelegateEx = 3,
	HttpFeatureHttp3 = 4,
	HttpFeaturemax = -1,
}

#endregion


#region Structs
[CRepr]
public struct HTTP_PROPERTY_FLAGS
{
	public uint32 _bitfield;
}

[CRepr]
public struct HTTP_STATE_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public HTTP_ENABLED_STATE State;
}

[CRepr]
public struct HTTP_QOS_SETTING_INFO
{
	public HTTP_QOS_SETTING_TYPE QosType;
	public void* QosSetting;
}

[CRepr]
public struct HTTP_CONNECTION_LIMIT_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public uint32 MaxConnections;
}

[CRepr]
public struct HTTP_BANDWIDTH_LIMIT_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public uint32 MaxBandwidth;
}

[CRepr]
public struct HTTP_FLOWRATE_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public uint32 MaxBandwidth;
	public uint32 MaxPeakBandwidth;
	public uint32 BurstSize;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_TIMEOUT_SET
{
	public HTTP_SERVICE_CONFIG_TIMEOUT_KEY KeyDesc;
	public uint16 ParamDesc;
}

[CRepr]
public struct HTTP_TIMEOUT_LIMIT_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public uint16 EntityBody;
	public uint16 DrainEntityBody;
	public uint16 RequestQueue;
	public uint16 IdleConnection;
	public uint16 HeaderWait;
	public uint32 MinSendRate;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SETTING_SET
{
	public HTTP_SERVICE_CONFIG_SETTING_KEY KeyDesc;
	public uint32 ParamDesc;
}

[CRepr]
public struct HTTP_LISTEN_ENDPOINT_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public BOOLEAN EnableSharing;
}

[CRepr]
public struct HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS
{
	public uint16 DomainNameLength;
	public PWSTR DomainName;
	public uint16 RealmLength;
	public PWSTR Realm;
}

[CRepr]
public struct HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS
{
	public uint16 RealmLength;
	public PWSTR Realm;
}

[CRepr]
public struct HTTP_SERVER_AUTHENTICATION_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public uint32 AuthSchemes;
	public BOOLEAN ReceiveMutualAuth;
	public BOOLEAN ReceiveContextHandle;
	public BOOLEAN DisableNTLMCredentialCaching;
	public uint8 ExFlags;
	public HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS DigestParams;
	public HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS BasicParams;
}

[CRepr]
public struct HTTP_SERVICE_BINDING_BASE
{
	public HTTP_SERVICE_BINDING_TYPE Type;
}

[CRepr]
public struct HTTP_SERVICE_BINDING_A
{
	public HTTP_SERVICE_BINDING_BASE Base;
	public PSTR Buffer;
	public uint32 BufferSize;
}

[CRepr]
public struct HTTP_SERVICE_BINDING_W
{
	public HTTP_SERVICE_BINDING_BASE Base;
	public PWSTR Buffer;
	public uint32 BufferSize;
}

[CRepr]
public struct HTTP_CHANNEL_BIND_INFO
{
	public HTTP_AUTHENTICATION_HARDENING_LEVELS Hardening;
	public uint32 Flags;
	public HTTP_SERVICE_BINDING_BASE** ServiceNames;
	public uint32 NumberOfServiceNames;
}

[CRepr]
public struct HTTP_REQUEST_CHANNEL_BIND_STATUS
{
	public HTTP_SERVICE_BINDING_BASE* ServiceName;
	public uint8* ChannelToken;
	public uint32 ChannelTokenSize;
	public uint32 Flags;
}

[CRepr]
public struct HTTP_REQUEST_TOKEN_BINDING_INFO
{
	public uint8* TokenBinding;
	public uint32 TokenBindingSize;
	public uint8* EKM;
	public uint32 EKMSize;
	public uint8 KeyType;
}

[CRepr]
public struct HTTP_LOGGING_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public uint32 LoggingFlags;
	public PWSTR SoftwareName;
	public uint16 SoftwareNameLength;
	public uint16 DirectoryNameLength;
	public PWSTR DirectoryName;
	public HTTP_LOGGING_TYPE Format;
	public uint32 Fields;
	public void* pExtFields;
	public uint16 NumOfExtFields;
	public uint16 MaxRecordSize;
	public HTTP_LOGGING_ROLLOVER_TYPE RolloverType;
	public uint32 RolloverSize;
	public PSECURITY_DESCRIPTOR pSecurityDescriptor;
}

[CRepr]
public struct HTTP_BINDING_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public HANDLE RequestQueueHandle;
}

[CRepr]
public struct HTTP_PROTECTION_LEVEL_INFO
{
	public HTTP_PROPERTY_FLAGS Flags;
	public HTTP_PROTECTION_LEVEL_TYPE Level;
}

[CRepr]
public struct HTTP_BYTE_RANGE
{
	public ULARGE_INTEGER StartingOffset;
	public ULARGE_INTEGER Length;
}

[CRepr]
public struct HTTP_VERSION
{
	public uint16 MajorVersion;
	public uint16 MinorVersion;
}

[CRepr]
public struct HTTP_KNOWN_HEADER
{
	public uint16 RawValueLength;
	public PSTR pRawValue;
}

[CRepr]
public struct HTTP_UNKNOWN_HEADER
{
	public uint16 NameLength;
	public uint16 RawValueLength;
	public PSTR pName;
	public PSTR pRawValue;
}

[CRepr]
public struct HTTP_LOG_DATA
{
	public HTTP_LOG_DATA_TYPE Type;
}

[CRepr]
public struct HTTP_LOG_FIELDS_DATA
{
	public HTTP_LOG_DATA Base;
	public uint16 UserNameLength;
	public uint16 UriStemLength;
	public uint16 ClientIpLength;
	public uint16 ServerNameLength;
	public uint16 ServiceNameLength;
	public uint16 ServerIpLength;
	public uint16 MethodLength;
	public uint16 UriQueryLength;
	public uint16 HostLength;
	public uint16 UserAgentLength;
	public uint16 CookieLength;
	public uint16 ReferrerLength;
	public PWSTR UserName;
	public PWSTR UriStem;
	public PSTR ClientIp;
	public PSTR ServerName;
	public PSTR ServiceName;
	public PSTR ServerIp;
	public PSTR Method;
	public PSTR UriQuery;
	public PSTR Host;
	public PSTR UserAgent;
	public PSTR Cookie;
	public PSTR Referrer;
	public uint16 ServerPort;
	public uint16 ProtocolStatus;
	public uint32 Win32Status;
	public HTTP_VERB MethodNum;
	public uint16 SubStatus;
}

[CRepr]
public struct HTTP_DATA_CHUNK
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _FromFragmentCacheEx_e__Struct
		{
			public HTTP_BYTE_RANGE ByteRange;
			public PWSTR pFragmentName;
		}
		[CRepr]
		public struct _FromFileHandle_e__Struct
		{
			public HTTP_BYTE_RANGE ByteRange;
			public HANDLE FileHandle;
		}
		[CRepr]
		public struct _FromFragmentCache_e__Struct
		{
			public uint16 FragmentNameLength;
			public PWSTR pFragmentName;
		}
		[CRepr]
		public struct _FromMemory_e__Struct
		{
			public void* pBuffer;
			public uint32 BufferLength;
		}
		[CRepr]
		public struct _Trailers_e__Struct
		{
			public uint16 TrailerCount;
			public HTTP_UNKNOWN_HEADER* pTrailers;
		}
		public _FromMemory_e__Struct FromMemory;
		public _FromFileHandle_e__Struct FromFileHandle;
		public _FromFragmentCache_e__Struct FromFragmentCache;
		public _FromFragmentCacheEx_e__Struct FromFragmentCacheEx;
		public _Trailers_e__Struct Trailers;
	}
	public HTTP_DATA_CHUNK_TYPE DataChunkType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct HTTP_REQUEST_HEADERS
{
	public uint16 UnknownHeaderCount;
	public HTTP_UNKNOWN_HEADER* pUnknownHeaders;
	public uint16 TrailerCount;
	public HTTP_UNKNOWN_HEADER* pTrailers;
	public HTTP_KNOWN_HEADER[41] KnownHeaders;
}

[CRepr]
public struct HTTP_RESPONSE_HEADERS
{
	public uint16 UnknownHeaderCount;
	public HTTP_UNKNOWN_HEADER* pUnknownHeaders;
	public uint16 TrailerCount;
	public HTTP_UNKNOWN_HEADER* pTrailers;
	public HTTP_KNOWN_HEADER[30] KnownHeaders;
}

[CRepr]
public struct HTTP_DELEGATE_REQUEST_PROPERTY_INFO
{
	public HTTP_DELEGATE_REQUEST_PROPERTY_ID PropertyId;
	public uint32 PropertyInfoLength;
	public void* PropertyInfo;
}

[CRepr]
public struct HTTP_CREATE_REQUEST_QUEUE_PROPERTY_INFO
{
	public HTTP_CREATE_REQUEST_QUEUE_PROPERTY_ID PropertyId;
	public uint32 PropertyInfoLength;
	public void* PropertyInfo;
}

[CRepr]
public struct HTTP_TRANSPORT_ADDRESS
{
	public SOCKADDR* pRemoteAddress;
	public SOCKADDR* pLocalAddress;
}

[CRepr]
public struct HTTP_COOKED_URL
{
	public uint16 FullUrlLength;
	public uint16 HostLength;
	public uint16 AbsPathLength;
	public uint16 QueryStringLength;
	public PWSTR pFullUrl;
	public PWSTR pHost;
	public PWSTR pAbsPath;
	public PWSTR pQueryString;
}

[CRepr]
public struct HTTP_SSL_CLIENT_CERT_INFO
{
	public uint32 CertFlags;
	public uint32 CertEncodedSize;
	public uint8* pCertEncoded;
	public HANDLE Token;
	public BOOLEAN CertDeniedByMapper;
}

[CRepr]
public struct HTTP_SSL_INFO
{
	public uint16 ServerCertKeySize;
	public uint16 ConnectionKeySize;
	public uint32 ServerCertIssuerSize;
	public uint32 ServerCertSubjectSize;
	public PSTR pServerCertIssuer;
	public PSTR pServerCertSubject;
	public HTTP_SSL_CLIENT_CERT_INFO* pClientCertInfo;
	public uint32 SslClientCertNegotiated;
}

[CRepr]
public struct HTTP_SSL_PROTOCOL_INFO
{
	public uint32 Protocol;
	public uint32 CipherType;
	public uint32 CipherStrength;
	public uint32 HashType;
	public uint32 HashStrength;
	public uint32 KeyExchangeType;
	public uint32 KeyExchangeStrength;
}

[CRepr]
public struct HTTP_REQUEST_SIZING_INFO
{
	public uint64 Flags;
	public uint32 RequestIndex;
	public uint32 RequestSizingCount;
	public uint64[5] RequestSizing;
}

[CRepr]
public struct HTTP_REQUEST_TIMING_INFO
{
	public uint32 RequestTimingCount;
	public uint64[30] RequestTiming;
}

[CRepr]
public struct HTTP_REQUEST_INFO
{
	public HTTP_REQUEST_INFO_TYPE InfoType;
	public uint32 InfoLength;
	public void* pInfo;
}

[CRepr]
public struct HTTP_REQUEST_AUTH_INFO
{
	public HTTP_AUTH_STATUS AuthStatus;
	public HRESULT SecStatus;
	public uint32 Flags;
	public HTTP_REQUEST_AUTH_TYPE AuthType;
	public HANDLE AccessToken;
	public uint32 ContextAttributes;
	public uint32 PackedContextLength;
	public uint32 PackedContextType;
	public void* PackedContext;
	public uint32 MutualAuthDataLength;
	public PSTR pMutualAuthData;
	public uint16 PackageNameLength;
	public PWSTR pPackageName;
}

[CRepr]
public struct HTTP_REQUEST_V1
{
	public uint32 Flags;
	public uint64 ConnectionId;
	public uint64 RequestId;
	public uint64 UrlContext;
	public HTTP_VERSION Version;
	public HTTP_VERB Verb;
	public uint16 UnknownVerbLength;
	public uint16 RawUrlLength;
	public PSTR pUnknownVerb;
	public PSTR pRawUrl;
	public HTTP_COOKED_URL CookedUrl;
	public HTTP_TRANSPORT_ADDRESS Address;
	public HTTP_REQUEST_HEADERS Headers;
	public uint64 BytesReceived;
	public uint16 EntityChunkCount;
	public HTTP_DATA_CHUNK* pEntityChunks;
	public uint64 RawConnectionId;
	public HTTP_SSL_INFO* pSslInfo;
}

[CRepr]
public struct HTTP_REQUEST_V2
{
	public HTTP_REQUEST_V1 Base;
	public uint16 RequestInfoCount;
	public HTTP_REQUEST_INFO* pRequestInfo;
}

[CRepr]
public struct HTTP_RESPONSE_V1
{
	public uint32 Flags;
	public HTTP_VERSION Version;
	public uint16 StatusCode;
	public uint16 ReasonLength;
	public PSTR pReason;
	public HTTP_RESPONSE_HEADERS Headers;
	public uint16 EntityChunkCount;
	public HTTP_DATA_CHUNK* pEntityChunks;
}

[CRepr]
public struct HTTP_RESPONSE_INFO
{
	public HTTP_RESPONSE_INFO_TYPE Type;
	public uint32 Length;
	public void* pInfo;
}

[CRepr]
public struct HTTP_MULTIPLE_KNOWN_HEADERS
{
	public HTTP_HEADER_ID HeaderId;
	public uint32 Flags;
	public uint16 KnownHeaderCount;
	public HTTP_KNOWN_HEADER* KnownHeaders;
}

[CRepr]
public struct HTTP_RESPONSE_V2
{
	public HTTP_RESPONSE_V1 Base;
	public uint16 ResponseInfoCount;
	public HTTP_RESPONSE_INFO* pResponseInfo;
}

[CRepr]
public struct HTTPAPI_VERSION
{
	public uint16 HttpApiMajorVersion;
	public uint16 HttpApiMinorVersion;
}

[CRepr]
public struct HTTP_CACHE_POLICY
{
	public HTTP_CACHE_POLICY_TYPE Policy;
	public uint32 SecondsToLive;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_KEY
{
	public SOCKADDR* pIpPort;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_KEY_EX
{
	public SOCKADDR_STORAGE IpPort;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SNI_KEY
{
	public SOCKADDR_STORAGE IpPort;
	public PWSTR Host;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_CCS_KEY
{
	public SOCKADDR_STORAGE LocalAddress;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_PARAM
{
	public uint32 SslHashLength;
	public void* pSslHash;
	public Guid AppId;
	public PWSTR pSslCertStoreName;
	public uint32 DefaultCertCheckMode;
	public uint32 DefaultRevocationFreshnessTime;
	public uint32 DefaultRevocationUrlRetrievalTimeout;
	public PWSTR pDefaultSslCtlIdentifier;
	public PWSTR pDefaultSslCtlStoreName;
	public uint32 DefaultFlags;
}

[CRepr]
public struct HTTP2_WINDOW_SIZE_PARAM
{
	public uint32 Http2ReceiveWindowSize;
}

[CRepr]
public struct HTTP2_SETTINGS_LIMITS_PARAM
{
	public uint32 Http2MaxSettingsPerFrame;
	public uint32 Http2MaxSettingsPerMinute;
}

[CRepr]
public struct HTTP_PERFORMANCE_PARAM
{
	public HTTP_PERFORMANCE_PARAM_TYPE Type;
	public uint32 BufferSize;
	public void* Buffer;
}

[CRepr]
public struct HTTP_TLS_RESTRICTIONS_PARAM
{
	public uint32 RestrictionCount;
	public void* TlsRestrictions;
}

[CRepr]
public struct HTTP_ERROR_HEADERS_PARAM
{
	public uint16 StatusCode;
	public uint16 HeaderCount;
	public HTTP_UNKNOWN_HEADER* Headers;
}

[CRepr]
public struct HTTP_TLS_SESSION_TICKET_KEYS_PARAM
{
	public uint32 SessionTicketKeyCount;
	public void* SessionTicketKeys;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_PARAM_EX
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public HTTP2_WINDOW_SIZE_PARAM Http2WindowSizeParam;
		public HTTP2_SETTINGS_LIMITS_PARAM Http2SettingsLimitsParam;
		public HTTP_PERFORMANCE_PARAM HttpPerformanceParam;
		public HTTP_TLS_RESTRICTIONS_PARAM HttpTlsRestrictionsParam;
		public HTTP_ERROR_HEADERS_PARAM HttpErrorHeadersParam;
		public HTTP_TLS_SESSION_TICKET_KEYS_PARAM HttpTlsSessionTicketKeysParam;
	}
	public HTTP_SSL_SERVICE_CONFIG_EX_PARAM_TYPE ParamType;
	public uint64 Flags;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SET
{
	public HTTP_SERVICE_CONFIG_SSL_KEY KeyDesc;
	public HTTP_SERVICE_CONFIG_SSL_PARAM ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SNI_SET
{
	public HTTP_SERVICE_CONFIG_SSL_SNI_KEY KeyDesc;
	public HTTP_SERVICE_CONFIG_SSL_PARAM ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_CCS_SET
{
	public HTTP_SERVICE_CONFIG_SSL_CCS_KEY KeyDesc;
	public HTTP_SERVICE_CONFIG_SSL_PARAM ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SET_EX
{
	public HTTP_SERVICE_CONFIG_SSL_KEY_EX KeyDesc;
	public HTTP_SERVICE_CONFIG_SSL_PARAM_EX ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SNI_SET_EX
{
	public HTTP_SERVICE_CONFIG_SSL_SNI_KEY KeyDesc;
	public HTTP_SERVICE_CONFIG_SSL_PARAM_EX ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_CCS_SET_EX
{
	public HTTP_SERVICE_CONFIG_SSL_CCS_KEY KeyDesc;
	public HTTP_SERVICE_CONFIG_SSL_PARAM_EX ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_QUERY
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_SSL_KEY KeyDesc;
	public uint32 dwToken;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SNI_QUERY
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_SSL_SNI_KEY KeyDesc;
	public uint32 dwToken;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_CCS_QUERY
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_SSL_CCS_KEY KeyDesc;
	public uint32 dwToken;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_QUERY_EX
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_SSL_KEY_EX KeyDesc;
	public uint32 dwToken;
	public HTTP_SSL_SERVICE_CONFIG_EX_PARAM_TYPE ParamType;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_SNI_QUERY_EX
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_SSL_SNI_KEY KeyDesc;
	public uint32 dwToken;
	public HTTP_SSL_SERVICE_CONFIG_EX_PARAM_TYPE ParamType;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_SSL_CCS_QUERY_EX
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_SSL_CCS_KEY KeyDesc;
	public uint32 dwToken;
	public HTTP_SSL_SERVICE_CONFIG_EX_PARAM_TYPE ParamType;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_IP_LISTEN_PARAM
{
	public uint16 AddrLength;
	public SOCKADDR* pAddress;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_IP_LISTEN_QUERY
{
	public uint32 AddrCount;
	public SOCKADDR_STORAGE* AddrList mut => &AddrList_impl;
	private SOCKADDR_STORAGE[ANYSIZE_ARRAY] AddrList_impl;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_URLACL_KEY
{
	public PWSTR pUrlPrefix;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_URLACL_PARAM
{
	public PWSTR pStringSecurityDescriptor;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_URLACL_SET
{
	public HTTP_SERVICE_CONFIG_URLACL_KEY KeyDesc;
	public HTTP_SERVICE_CONFIG_URLACL_PARAM ParamDesc;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_URLACL_QUERY
{
	public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
	public HTTP_SERVICE_CONFIG_URLACL_KEY KeyDesc;
	public uint32 dwToken;
}

[CRepr]
public struct HTTP_SERVICE_CONFIG_CACHE_SET
{
	public HTTP_SERVICE_CONFIG_CACHE_KEY KeyDesc;
	public uint32 ParamDesc;
}

[CRepr]
public struct HTTP_QUERY_REQUEST_QUALIFIER_TCP
{
	public uint64 Freshness;
}

[CRepr]
public struct HTTP_QUERY_REQUEST_QUALIFIER_QUIC
{
	public uint64 Freshness;
}

[CRepr]
public struct HTTP_REQUEST_PROPERTY_SNI
{
	public char16[256] Hostname;
	public uint32 Flags;
}

[CRepr]
public struct HTTP_REQUEST_PROPERTY_STREAM_ERROR
{
	public uint32 ErrorCode;
}

[CRepr]
public struct HTTP_WSK_API_TIMINGS
{
	public uint64 ConnectCount;
	public uint64 ConnectSum;
	public uint64 DisconnectCount;
	public uint64 DisconnectSum;
	public uint64 SendCount;
	public uint64 SendSum;
	public uint64 ReceiveCount;
	public uint64 ReceiveSum;
	public uint64 ReleaseCount;
	public uint64 ReleaseSum;
	public uint64 ControlSocketCount;
	public uint64 ControlSocketSum;
}

[CRepr]
public struct HTTP_QUIC_STREAM_API_TIMINGS
{
	public uint64 OpenCount;
	public uint64 OpenSum;
	public uint64 CloseCount;
	public uint64 CloseSum;
	public uint64 StartCount;
	public uint64 StartSum;
	public uint64 ShutdownCount;
	public uint64 ShutdownSum;
	public uint64 SendCount;
	public uint64 SendSum;
	public uint64 ReceiveSetEnabledCount;
	public uint64 ReceiveSetEnabledSum;
	public uint64 GetParamCount;
	public uint64 GetParamSum;
	public uint64 SetParamCount;
	public uint64 SetParamSum;
	public uint64 SetCallbackHandlerCount;
	public uint64 SetCallbackHandlerSum;
}

[CRepr]
public struct HTTP_QUIC_CONNECTION_API_TIMINGS
{
	public uint64 OpenTime;
	public uint64 CloseTime;
	public uint64 StartTime;
	public uint64 ShutdownTime;
	public uint64 SecConfigCreateTime;
	public uint64 SecConfigDeleteTime;
	public uint64 GetParamCount;
	public uint64 GetParamSum;
	public uint64 SetParamCount;
	public uint64 SetParamSum;
	public uint64 SetCallbackHandlerCount;
	public uint64 SetCallbackHandlerSum;
	public HTTP_QUIC_STREAM_API_TIMINGS ControlStreamTimings;
}

[CRepr]
public struct HTTP_QUIC_API_TIMINGS
{
	public HTTP_QUIC_CONNECTION_API_TIMINGS ConnectionTimings;
	public HTTP_QUIC_STREAM_API_TIMINGS StreamTimings;
}

#endregion

#region Functions
public static
{
	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpInitialize(HTTPAPI_VERSION Version, HTTP_INITIALIZE Flags, void* pReserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpTerminate(HTTP_INITIALIZE Flags, void* pReserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCreateHttpHandle(HANDLE* RequestQueueHandle, uint32 Reserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCreateRequestQueue(HTTPAPI_VERSION Version, PWSTR Name, SECURITY_ATTRIBUTES* SecurityAttributes, uint32 Flags, HANDLE* RequestQueueHandle);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCloseRequestQueue(HANDLE RequestQueueHandle);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSetRequestQueueProperty(HANDLE RequestQueueHandle, HTTP_SERVER_PROPERTY Property, void* PropertyInformation, uint32 PropertyInformationLength, uint32 Reserved1, void* Reserved2);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpQueryRequestQueueProperty(HANDLE RequestQueueHandle, HTTP_SERVER_PROPERTY Property, void* PropertyInformation, uint32 PropertyInformationLength, uint32 Reserved1, uint32* ReturnLength, void* Reserved2);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSetRequestProperty(HANDLE RequestQueueHandle, uint64 Id, HTTP_REQUEST_PROPERTY PropertyId, void* Input, uint32 InputPropertySize, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpShutdownRequestQueue(HANDLE RequestQueueHandle);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpReceiveClientCertificate(HANDLE RequestQueueHandle, uint64 ConnectionId, uint32 Flags, HTTP_SSL_CLIENT_CERT_INFO* SslClientCertInfo, uint32 SslClientCertInfoSize, uint32* BytesReceived, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCreateServerSession(HTTPAPI_VERSION Version, uint64* ServerSessionId, uint32 Reserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCloseServerSession(uint64 ServerSessionId);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpQueryServerSessionProperty(uint64 ServerSessionId, HTTP_SERVER_PROPERTY Property, void* PropertyInformation, uint32 PropertyInformationLength, uint32* ReturnLength);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSetServerSessionProperty(uint64 ServerSessionId, HTTP_SERVER_PROPERTY Property, void* PropertyInformation, uint32 PropertyInformationLength);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpAddUrl(HANDLE RequestQueueHandle, PWSTR FullyQualifiedUrl, void* Reserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpRemoveUrl(HANDLE RequestQueueHandle, PWSTR FullyQualifiedUrl);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCreateUrlGroup(uint64 ServerSessionId, uint64* pUrlGroupId, uint32 Reserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCloseUrlGroup(uint64 UrlGroupId);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpAddUrlToUrlGroup(uint64 UrlGroupId, PWSTR pFullyQualifiedUrl, uint64 UrlContext, uint32 Reserved);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpRemoveUrlFromUrlGroup(uint64 UrlGroupId, PWSTR pFullyQualifiedUrl, uint32 Flags);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSetUrlGroupProperty(uint64 UrlGroupId, HTTP_SERVER_PROPERTY Property, void* PropertyInformation, uint32 PropertyInformationLength);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpQueryUrlGroupProperty(uint64 UrlGroupId, HTTP_SERVER_PROPERTY Property, void* PropertyInformation, uint32 PropertyInformationLength, uint32* ReturnLength);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpPrepareUrl(void* Reserved, uint32 Flags, PWSTR Url, PWSTR* PreparedUrl);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpReceiveHttpRequest(HANDLE RequestQueueHandle, uint64 RequestId, HTTP_RECEIVE_HTTP_REQUEST_FLAGS Flags, HTTP_REQUEST_V2* RequestBuffer, uint32 RequestBufferLength, uint32* BytesReturned, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpReceiveRequestEntityBody(HANDLE RequestQueueHandle, uint64 RequestId, uint32 Flags, void* EntityBuffer, uint32 EntityBufferLength, uint32* BytesReturned, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSendHttpResponse(HANDLE RequestQueueHandle, uint64 RequestId, uint32 Flags, HTTP_RESPONSE_V2* HttpResponse, HTTP_CACHE_POLICY* CachePolicy, uint32* BytesSent, void* Reserved1, uint32 Reserved2, OVERLAPPED* Overlapped, HTTP_LOG_DATA* LogData);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSendResponseEntityBody(HANDLE RequestQueueHandle, uint64 RequestId, uint32 Flags, uint16 EntityChunkCount, HTTP_DATA_CHUNK* EntityChunks, uint32* BytesSent, void* Reserved1, uint32 Reserved2, OVERLAPPED* Overlapped, HTTP_LOG_DATA* LogData);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpDeclarePush(HANDLE RequestQueueHandle, uint64 RequestId, HTTP_VERB Verb, PWSTR Path, PSTR Query, HTTP_REQUEST_HEADERS* Headers);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpWaitForDisconnect(HANDLE RequestQueueHandle, uint64 ConnectionId, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpWaitForDisconnectEx(HANDLE RequestQueueHandle, uint64 ConnectionId, uint32 Reserved, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpCancelHttpRequest(HANDLE RequestQueueHandle, uint64 RequestId, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpWaitForDemandStart(HANDLE RequestQueueHandle, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL HttpIsFeatureSupported(HTTP_FEATURE_ID FeatureId);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpDelegateRequestEx(HANDLE RequestQueueHandle, HANDLE DelegateQueueHandle, uint64 RequestId, uint64 DelegateUrlGroupId, uint32 PropertyInfoSetSize, HTTP_DELEGATE_REQUEST_PROPERTY_INFO* PropertyInfoSet);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpFindUrlGroupId(PWSTR FullyQualifiedUrl, HANDLE RequestQueueHandle, uint64* UrlGroupId);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpFlushResponseCache(HANDLE RequestQueueHandle, PWSTR UrlPrefix, uint32 Flags, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpAddFragmentToCache(HANDLE RequestQueueHandle, PWSTR UrlPrefix, HTTP_DATA_CHUNK* DataChunk, HTTP_CACHE_POLICY* CachePolicy, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpReadFragmentFromCache(HANDLE RequestQueueHandle, PWSTR UrlPrefix, HTTP_BYTE_RANGE* ByteRange, void* Buffer, uint32 BufferLength, uint32* BytesRead, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpSetServiceConfiguration(HANDLE ServiceHandle, HTTP_SERVICE_CONFIG_ID ConfigId, void* pConfigInformation, uint32 ConfigInformationLength, OVERLAPPED* pOverlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpUpdateServiceConfiguration(HANDLE Handle, HTTP_SERVICE_CONFIG_ID ConfigId, void* ConfigInfo, uint32 ConfigInfoLength, OVERLAPPED* Overlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpDeleteServiceConfiguration(HANDLE ServiceHandle, HTTP_SERVICE_CONFIG_ID ConfigId, void* pConfigInformation, uint32 ConfigInformationLength, OVERLAPPED* pOverlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpQueryServiceConfiguration(HANDLE ServiceHandle, HTTP_SERVICE_CONFIG_ID ConfigId, void* pInput, uint32 InputLength, void* pOutput, uint32 OutputLength, uint32* pReturnLength, OVERLAPPED* pOverlapped);

	[Import("HTTPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpGetExtension(HTTPAPI_VERSION Version, uint32 Extension, void* Buffer, uint32 BufferSize);

}
#endregion
