using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.Dns;

#region Constants
public static
{
	public const uint32 SIZEOF_IP4_ADDRESS = 4;
	public const uint32 IP4_ADDRESS_STRING_LENGTH = 16;
	public const uint32 IP4_ADDRESS_STRING_BUFFER_LENGTH = 16;
	public const uint32 DNS_ADDR_MAX_SOCKADDR_LENGTH = 32;
	public const uint32 IP6_ADDRESS_STRING_LENGTH = 65;
	public const uint32 IP6_ADDRESS_STRING_BUFFER_LENGTH = 65;
	public const uint32 DNS_ADDRESS_STRING_LENGTH = 65;
	public const uint32 DNS_PORT_HOST_ORDER = 53;
	public const uint32 DNS_PORT_NET_ORDER = 13568;
	public const uint32 DNS_RFC_MAX_UDP_PACKET_LENGTH = 512;
	public const uint32 DNS_MAX_NAME_LENGTH = 255;
	public const uint32 DNS_MAX_LABEL_LENGTH = 63;
	public const uint32 DNS_MAX_NAME_BUFFER_LENGTH = 256;
	public const uint32 DNS_MAX_LABEL_BUFFER_LENGTH = 64;
	public const uint32 DNS_MAX_IP4_REVERSE_NAME_LENGTH = 31;
	public const uint32 DNS_MAX_IP6_REVERSE_NAME_LENGTH = 75;
	public const uint32 DNS_MAX_REVERSE_NAME_LENGTH = 75;
	public const uint32 DNS_MAX_IP4_REVERSE_NAME_BUFFER_LENGTH = 31;
	public const uint32 DNS_MAX_IP6_REVERSE_NAME_BUFFER_LENGTH = 75;
	public const uint32 DNS_MAX_REVERSE_NAME_BUFFER_LENGTH = 75;
	public const uint32 DNS_MAX_TEXT_STRING_LENGTH = 255;
	public const uint32 DNS_COMPRESSED_QUESTION_NAME = 49164;
	public const uint32 DNS_OPCODE_QUERY = 0;
	public const uint32 DNS_OPCODE_IQUERY = 1;
	public const uint32 DNS_OPCODE_SERVER_STATUS = 2;
	public const uint32 DNS_OPCODE_UNKNOWN = 3;
	public const uint32 DNS_OPCODE_NOTIFY = 4;
	public const uint32 DNS_OPCODE_UPDATE = 5;
	public const uint32 DNS_RCODE_NOERROR = 0;
	public const uint32 DNS_RCODE_FORMERR = 1;
	public const uint32 DNS_RCODE_SERVFAIL = 2;
	public const uint32 DNS_RCODE_NXDOMAIN = 3;
	public const uint32 DNS_RCODE_NOTIMPL = 4;
	public const uint32 DNS_RCODE_REFUSED = 5;
	public const uint32 DNS_RCODE_YXDOMAIN = 6;
	public const uint32 DNS_RCODE_YXRRSET = 7;
	public const uint32 DNS_RCODE_NXRRSET = 8;
	public const uint32 DNS_RCODE_NOTAUTH = 9;
	public const uint32 DNS_RCODE_NOTZONE = 10;
	public const uint32 DNS_RCODE_MAX = 15;
	public const uint32 DNS_RCODE_BADVERS = 16;
	public const uint32 DNS_RCODE_BADSIG = 16;
	public const uint32 DNS_RCODE_BADKEY = 17;
	public const uint32 DNS_RCODE_BADTIME = 18;
	public const uint32 DNS_RCODE_NO_ERROR = 0;
	public const uint32 DNS_RCODE_FORMAT_ERROR = 1;
	public const uint32 DNS_RCODE_SERVER_FAILURE = 2;
	public const uint32 DNS_RCODE_NAME_ERROR = 3;
	public const uint32 DNS_RCODE_NOT_IMPLEMENTED = 4;
	public const uint32 DNS_CLASS_INTERNET = 1;
	public const uint32 DNS_CLASS_CSNET = 2;
	public const uint32 DNS_CLASS_CHAOS = 3;
	public const uint32 DNS_CLASS_HESIOD = 4;
	public const uint32 DNS_CLASS_NONE = 254;
	public const uint32 DNS_CLASS_ALL = 255;
	public const uint32 DNS_CLASS_ANY = 255;
	public const uint32 DNS_CLASS_UNICAST_RESPONSE = 32768;
	public const uint32 DNS_RCLASS_INTERNET = 256;
	public const uint32 DNS_RCLASS_CSNET = 512;
	public const uint32 DNS_RCLASS_CHAOS = 768;
	public const uint32 DNS_RCLASS_HESIOD = 1024;
	public const uint32 DNS_RCLASS_NONE = 65024;
	public const uint32 DNS_RCLASS_ALL = 65280;
	public const uint32 DNS_RCLASS_ANY = 65280;
	public const uint32 DNS_RCLASS_UNICAST_RESPONSE = 128;
	public const uint32 DNS_TYPE_ZERO = 0;
	public const uint32 DNS_TYPE_A = 1;
	public const uint32 DNS_TYPE_NS = 2;
	public const uint32 DNS_TYPE_MD = 3;
	public const uint32 DNS_TYPE_MF = 4;
	public const uint32 DNS_TYPE_CNAME = 5;
	public const uint32 DNS_TYPE_SOA = 6;
	public const uint32 DNS_TYPE_MB = 7;
	public const uint32 DNS_TYPE_MG = 8;
	public const uint32 DNS_TYPE_MR = 9;
	public const uint32 DNS_TYPE_NULL = 10;
	public const uint32 DNS_TYPE_WKS = 11;
	public const uint32 DNS_TYPE_PTR = 12;
	public const uint32 DNS_TYPE_HINFO = 13;
	public const uint32 DNS_TYPE_MINFO = 14;
	public const uint32 DNS_TYPE_MX = 15;
	public const uint32 DNS_TYPE_TEXT = 16;
	public const uint32 DNS_TYPE_RP = 17;
	public const uint32 DNS_TYPE_AFSDB = 18;
	public const uint32 DNS_TYPE_X25 = 19;
	public const uint32 DNS_TYPE_ISDN = 20;
	public const uint32 DNS_TYPE_RT = 21;
	public const uint32 DNS_TYPE_NSAP = 22;
	public const uint32 DNS_TYPE_NSAPPTR = 23;
	public const uint32 DNS_TYPE_SIG = 24;
	public const uint32 DNS_TYPE_KEY = 25;
	public const uint32 DNS_TYPE_PX = 26;
	public const uint32 DNS_TYPE_GPOS = 27;
	public const uint32 DNS_TYPE_AAAA = 28;
	public const uint32 DNS_TYPE_LOC = 29;
	public const uint32 DNS_TYPE_NXT = 30;
	public const uint32 DNS_TYPE_EID = 31;
	public const uint32 DNS_TYPE_NIMLOC = 32;
	public const uint32 DNS_TYPE_SRV = 33;
	public const uint32 DNS_TYPE_ATMA = 34;
	public const uint32 DNS_TYPE_NAPTR = 35;
	public const uint32 DNS_TYPE_KX = 36;
	public const uint32 DNS_TYPE_CERT = 37;
	public const uint32 DNS_TYPE_A6 = 38;
	public const uint32 DNS_TYPE_DNAME = 39;
	public const uint32 DNS_TYPE_SINK = 40;
	public const uint32 DNS_TYPE_OPT = 41;
	public const uint32 DNS_TYPE_DS = 43;
	public const uint32 DNS_TYPE_RRSIG = 46;
	public const uint32 DNS_TYPE_NSEC = 47;
	public const uint32 DNS_TYPE_DNSKEY = 48;
	public const uint32 DNS_TYPE_DHCID = 49;
	public const uint32 DNS_TYPE_NSEC3 = 50;
	public const uint32 DNS_TYPE_NSEC3PARAM = 51;
	public const uint32 DNS_TYPE_TLSA = 52;
	public const uint32 DNS_TYPE_UINFO = 100;
	public const uint32 DNS_TYPE_UID = 101;
	public const uint32 DNS_TYPE_GID = 102;
	public const uint32 DNS_TYPE_UNSPEC = 103;
	public const uint32 DNS_TYPE_ADDRS = 248;
	public const uint32 DNS_TYPE_TKEY = 249;
	public const uint32 DNS_TYPE_TSIG = 250;
	public const uint32 DNS_TYPE_IXFR = 251;
	public const uint32 DNS_TYPE_AXFR = 252;
	public const uint32 DNS_TYPE_MAILB = 253;
	public const uint32 DNS_TYPE_MAILA = 254;
	public const uint32 DNS_TYPE_ALL = 255;
	public const uint32 DNS_TYPE_ANY = 255;
	public const uint32 DNS_TYPE_WINS = 65281;
	public const uint32 DNS_TYPE_WINSR = 65282;
	public const uint32 DNS_TYPE_NBSTAT = 65282;
	public const uint32 DNS_RTYPE_A = 256;
	public const uint32 DNS_RTYPE_NS = 512;
	public const uint32 DNS_RTYPE_MD = 768;
	public const uint32 DNS_RTYPE_MF = 1024;
	public const uint32 DNS_RTYPE_CNAME = 1280;
	public const uint32 DNS_RTYPE_SOA = 1536;
	public const uint32 DNS_RTYPE_MB = 1792;
	public const uint32 DNS_RTYPE_MG = 2048;
	public const uint32 DNS_RTYPE_MR = 2304;
	public const uint32 DNS_RTYPE_NULL = 2560;
	public const uint32 DNS_RTYPE_WKS = 2816;
	public const uint32 DNS_RTYPE_PTR = 3072;
	public const uint32 DNS_RTYPE_HINFO = 3328;
	public const uint32 DNS_RTYPE_MINFO = 3584;
	public const uint32 DNS_RTYPE_MX = 3840;
	public const uint32 DNS_RTYPE_TEXT = 4096;
	public const uint32 DNS_RTYPE_RP = 4352;
	public const uint32 DNS_RTYPE_AFSDB = 4608;
	public const uint32 DNS_RTYPE_X25 = 4864;
	public const uint32 DNS_RTYPE_ISDN = 5120;
	public const uint32 DNS_RTYPE_RT = 5376;
	public const uint32 DNS_RTYPE_NSAP = 5632;
	public const uint32 DNS_RTYPE_NSAPPTR = 5888;
	public const uint32 DNS_RTYPE_SIG = 6144;
	public const uint32 DNS_RTYPE_KEY = 6400;
	public const uint32 DNS_RTYPE_PX = 6656;
	public const uint32 DNS_RTYPE_GPOS = 6912;
	public const uint32 DNS_RTYPE_AAAA = 7168;
	public const uint32 DNS_RTYPE_LOC = 7424;
	public const uint32 DNS_RTYPE_NXT = 7680;
	public const uint32 DNS_RTYPE_EID = 7936;
	public const uint32 DNS_RTYPE_NIMLOC = 8192;
	public const uint32 DNS_RTYPE_SRV = 8448;
	public const uint32 DNS_RTYPE_ATMA = 8704;
	public const uint32 DNS_RTYPE_NAPTR = 8960;
	public const uint32 DNS_RTYPE_KX = 9216;
	public const uint32 DNS_RTYPE_CERT = 9472;
	public const uint32 DNS_RTYPE_A6 = 9728;
	public const uint32 DNS_RTYPE_DNAME = 9984;
	public const uint32 DNS_RTYPE_SINK = 10240;
	public const uint32 DNS_RTYPE_OPT = 10496;
	public const uint32 DNS_RTYPE_DS = 11008;
	public const uint32 DNS_RTYPE_RRSIG = 11776;
	public const uint32 DNS_RTYPE_NSEC = 12032;
	public const uint32 DNS_RTYPE_DNSKEY = 12288;
	public const uint32 DNS_RTYPE_DHCID = 12544;
	public const uint32 DNS_RTYPE_NSEC3 = 12800;
	public const uint32 DNS_RTYPE_NSEC3PARAM = 13056;
	public const uint32 DNS_RTYPE_TLSA = 13312;
	public const uint32 DNS_RTYPE_UINFO = 25600;
	public const uint32 DNS_RTYPE_UID = 25856;
	public const uint32 DNS_RTYPE_GID = 26112;
	public const uint32 DNS_RTYPE_UNSPEC = 26368;
	public const uint32 DNS_RTYPE_TKEY = 63744;
	public const uint32 DNS_RTYPE_TSIG = 64000;
	public const uint32 DNS_RTYPE_IXFR = 64256;
	public const uint32 DNS_RTYPE_AXFR = 64512;
	public const uint32 DNS_RTYPE_MAILB = 64768;
	public const uint32 DNS_RTYPE_MAILA = 65024;
	public const uint32 DNS_RTYPE_ALL = 65280;
	public const uint32 DNS_RTYPE_ANY = 65280;
	public const uint32 DNS_RTYPE_WINS = 511;
	public const uint32 DNS_RTYPE_WINSR = 767;
	public const uint32 DNS_ATMA_FORMAT_E164 = 1;
	public const uint32 DNS_ATMA_FORMAT_AESA = 2;
	public const uint32 DNS_ATMA_MAX_ADDR_LENGTH = 20;
	public const uint32 DNS_ATMA_AESA_ADDR_LENGTH = 20;
	public const uint32 DNS_ATMA_MAX_RECORD_LENGTH = 21;
	public const uint32 DNSSEC_ALGORITHM_RSAMD5 = 1;
	public const uint32 DNSSEC_ALGORITHM_RSASHA1 = 5;
	public const uint32 DNSSEC_ALGORITHM_RSASHA1_NSEC3 = 7;
	public const uint32 DNSSEC_ALGORITHM_RSASHA256 = 8;
	public const uint32 DNSSEC_ALGORITHM_RSASHA512 = 10;
	public const uint32 DNSSEC_ALGORITHM_ECDSAP256_SHA256 = 13;
	public const uint32 DNSSEC_ALGORITHM_ECDSAP384_SHA384 = 14;
	public const uint32 DNSSEC_ALGORITHM_NULL = 253;
	public const uint32 DNSSEC_ALGORITHM_PRIVATE = 254;
	public const uint32 DNSSEC_DIGEST_ALGORITHM_SHA1 = 1;
	public const uint32 DNSSEC_DIGEST_ALGORITHM_SHA256 = 2;
	public const uint32 DNSSEC_DIGEST_ALGORITHM_SHA384 = 4;
	public const uint32 DNSSEC_PROTOCOL_NONE = 0;
	public const uint32 DNSSEC_PROTOCOL_TLS = 1;
	public const uint32 DNSSEC_PROTOCOL_EMAIL = 2;
	public const uint32 DNSSEC_PROTOCOL_DNSSEC = 3;
	public const uint32 DNSSEC_PROTOCOL_IPSEC = 4;
	public const uint32 DNSSEC_KEY_FLAG_NOAUTH = 1;
	public const uint32 DNSSEC_KEY_FLAG_NOCONF = 2;
	public const uint32 DNSSEC_KEY_FLAG_FLAG2 = 4;
	public const uint32 DNSSEC_KEY_FLAG_EXTEND = 8;
	public const uint32 DNSSEC_KEY_FLAG_FLAG4 = 16;
	public const uint32 DNSSEC_KEY_FLAG_FLAG5 = 32;
	public const uint32 DNSSEC_KEY_FLAG_USER = 0;
	public const uint32 DNSSEC_KEY_FLAG_ZONE = 64;
	public const uint32 DNSSEC_KEY_FLAG_HOST = 128;
	public const uint32 DNSSEC_KEY_FLAG_NTPE3 = 192;
	public const uint32 DNSSEC_KEY_FLAG_FLAG8 = 256;
	public const uint32 DNSSEC_KEY_FLAG_FLAG9 = 512;
	public const uint32 DNSSEC_KEY_FLAG_FLAG10 = 1024;
	public const uint32 DNSSEC_KEY_FLAG_FLAG11 = 2048;
	public const uint32 DNSSEC_KEY_FLAG_SIG0 = 0;
	public const uint32 DNSSEC_KEY_FLAG_SIG1 = 4096;
	public const uint32 DNSSEC_KEY_FLAG_SIG2 = 8192;
	public const uint32 DNSSEC_KEY_FLAG_SIG3 = 12288;
	public const uint32 DNSSEC_KEY_FLAG_SIG4 = 16384;
	public const uint32 DNSSEC_KEY_FLAG_SIG5 = 20480;
	public const uint32 DNSSEC_KEY_FLAG_SIG6 = 24576;
	public const uint32 DNSSEC_KEY_FLAG_SIG7 = 28672;
	public const uint32 DNSSEC_KEY_FLAG_SIG8 = 32768;
	public const uint32 DNSSEC_KEY_FLAG_SIG9 = 36864;
	public const uint32 DNSSEC_KEY_FLAG_SIG10 = 40960;
	public const uint32 DNSSEC_KEY_FLAG_SIG11 = 45056;
	public const uint32 DNSSEC_KEY_FLAG_SIG12 = 49152;
	public const uint32 DNSSEC_KEY_FLAG_SIG13 = 53248;
	public const uint32 DNSSEC_KEY_FLAG_SIG14 = 57344;
	public const uint32 DNSSEC_KEY_FLAG_SIG15 = 61440;
	public const uint32 DNS_TKEY_MODE_SERVER_ASSIGN = 1;
	public const uint32 DNS_TKEY_MODE_DIFFIE_HELLMAN = 2;
	public const uint32 DNS_TKEY_MODE_GSS = 3;
	public const uint32 DNS_TKEY_MODE_RESOLVER_ASSIGN = 4;
	public const uint32 DNS_WINS_FLAG_SCOPE = 2147483648;
	public const uint32 DNS_WINS_FLAG_LOCAL = 65536;
	public const uint32 DNS_CONFIG_FLAG_ALLOC = 1;
	public const uint32 DNSREC_SECTION = 3;
	public const uint32 DNSREC_QUESTION = 0;
	public const uint32 DNSREC_ANSWER = 1;
	public const uint32 DNSREC_AUTHORITY = 2;
	public const uint32 DNSREC_ADDITIONAL = 3;
	public const uint32 DNSREC_ZONE = 0;
	public const uint32 DNSREC_PREREQ = 1;
	public const uint32 DNSREC_UPDATE = 2;
	public const uint32 DNSREC_DELETE = 4;
	public const uint32 DNSREC_NOEXIST = 4;
	public const uint32 DNS_QUERY_STANDARD = 0;
	public const uint32 DNS_QUERY_ACCEPT_TRUNCATED_RESPONSE = 1;
	public const uint32 DNS_QUERY_USE_TCP_ONLY = 2;
	public const uint32 DNS_QUERY_NO_RECURSION = 4;
	public const uint32 DNS_QUERY_BYPASS_CACHE = 8;
	public const uint32 DNS_QUERY_NO_WIRE_QUERY = 16;
	public const uint32 DNS_QUERY_NO_LOCAL_NAME = 32;
	public const uint32 DNS_QUERY_NO_HOSTS_FILE = 64;
	public const uint32 DNS_QUERY_NO_NETBT = 128;
	public const uint32 DNS_QUERY_WIRE_ONLY = 256;
	public const uint32 DNS_QUERY_RETURN_MESSAGE = 512;
	public const uint32 DNS_QUERY_MULTICAST_ONLY = 1024;
	public const uint32 DNS_QUERY_NO_MULTICAST = 2048;
	public const uint32 DNS_QUERY_TREAT_AS_FQDN = 4096;
	public const uint32 DNS_QUERY_ADDRCONFIG = 8192;
	public const uint32 DNS_QUERY_DUAL_ADDR = 16384;
	public const uint32 DNS_QUERY_DONT_RESET_TTL_VALUES = 1048576;
	public const uint32 DNS_QUERY_DISABLE_IDN_ENCODING = 2097152;
	public const uint32 DNS_QUERY_APPEND_MULTILABEL = 8388608;
	public const uint32 DNS_QUERY_DNSSEC_OK = 16777216;
	public const uint32 DNS_QUERY_DNSSEC_CHECKING_DISABLED = 33554432;
	public const uint32 DNS_QUERY_RESERVED = 4026531840;
	public const uint32 DNS_QUERY_CACHE_ONLY = 16;
	public const uint32 DNS_QUERY_REQUEST_VERSION1 = 1;
	public const uint32 DNS_QUERY_REQUEST_VERSION2 = 2;
	public const uint32 DNS_QUERY_RESULTS_VERSION1 = 1;
	public const uint32 DNS_QUERY_REQUEST_VERSION3 = 3;
	public const uint32 DNS_CUSTOM_SERVER_TYPE_UDP = 1;
	public const uint32 DNS_CUSTOM_SERVER_TYPE_DOH = 2;
	public const uint32 DNS_CUSTOM_SERVER_UDP_FALLBACK = 1;
	public const uint32 DNS_APP_SETTINGS_VERSION1 = 1;
	public const uint32 DNS_APP_SETTINGS_EXCLUSIVE_SERVERS = 1;
	public const uint32 DNS_UPDATE_SECURITY_USE_DEFAULT = 0;
	public const uint32 DNS_UPDATE_SECURITY_OFF = 16;
	public const uint32 DNS_UPDATE_SECURITY_ON = 32;
	public const uint32 DNS_UPDATE_SECURITY_ONLY = 256;
	public const uint32 DNS_UPDATE_CACHE_SECURITY_CONTEXT = 512;
	public const uint32 DNS_UPDATE_TEST_USE_LOCAL_SYS_ACCT = 1024;
	public const uint32 DNS_UPDATE_FORCE_SECURITY_NEGO = 2048;
	public const uint32 DNS_UPDATE_TRY_ALL_MASTER_SERVERS = 4096;
	public const uint32 DNS_UPDATE_SKIP_NO_UPDATE_ADAPTERS = 8192;
	public const uint32 DNS_UPDATE_REMOTE_SERVER = 16384;
	public const uint32 DNS_UPDATE_RESERVED = 4294901760;
	public const uint32 DNS_VALSVR_ERROR_INVALID_ADDR = 1;
	public const uint32 DNS_VALSVR_ERROR_INVALID_NAME = 2;
	public const uint32 DNS_VALSVR_ERROR_UNREACHABLE = 3;
	public const uint32 DNS_VALSVR_ERROR_NO_RESPONSE = 4;
	public const uint32 DNS_VALSVR_ERROR_NO_AUTH = 5;
	public const uint32 DNS_VALSVR_ERROR_REFUSED = 6;
	public const uint32 DNS_VALSVR_ERROR_NO_TCP = 16;
	public const uint32 DNS_VALSVR_ERROR_UNKNOWN = 255;
	public const uint32 DNS_CONNECTION_NAME_MAX_LENGTH = 64;
	public const uint32 DNS_CONNECTION_PROXY_INFO_CURRENT_VERSION = 1;
	public const uint32 DNS_CONNECTION_PROXY_INFO_SERVER_MAX_LENGTH = 256;
	public const uint32 DNS_CONNECTION_PROXY_INFO_FRIENDLY_NAME_MAX_LENGTH = 64;
	public const uint32 DNS_CONNECTION_PROXY_INFO_USERNAME_MAX_LENGTH = 128;
	public const uint32 DNS_CONNECTION_PROXY_INFO_PASSWORD_MAX_LENGTH = 128;
	public const uint32 DNS_CONNECTION_PROXY_INFO_EXCEPTION_MAX_LENGTH = 1024;
	public const uint32 DNS_CONNECTION_PROXY_INFO_EXTRA_INFO_MAX_LENGTH = 1024;
	public const uint32 DNS_CONNECTION_PROXY_INFO_FLAG_DISABLED = 1;
	public const uint32 DNS_CONNECTION_PROXY_INFO_FLAG_BYPASSLOCAL = 2;
	public const uint32 DNS_CONNECTION_POLICY_ENTRY_ONDEMAND = 1;
}
#endregion

#region TypeDefs
typealias DnsContextHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum DNS_CONFIG_TYPE : int32
{
	DnsConfigPrimaryDomainName_W = 0,
	DnsConfigPrimaryDomainName_A = 1,
	DnsConfigPrimaryDomainName_UTF8 = 2,
	DnsConfigAdapterDomainName_W = 3,
	DnsConfigAdapterDomainName_A = 4,
	DnsConfigAdapterDomainName_UTF8 = 5,
	DnsConfigDnsServerList = 6,
	DnsConfigSearchList = 7,
	DnsConfigAdapterInfo = 8,
	DnsConfigPrimaryHostNameRegistrationEnabled = 9,
	DnsConfigAdapterHostNameRegistrationEnabled = 10,
	DnsConfigAddressRegistrationMaxCount = 11,
	DnsConfigHostName_W = 12,
	DnsConfigHostName_A = 13,
	DnsConfigHostName_UTF8 = 14,
	DnsConfigFullHostName_W = 15,
	DnsConfigFullHostName_A = 16,
	DnsConfigFullHostName_UTF8 = 17,
	DnsConfigNameServer = 18,
}


[AllowDuplicates]
public enum DNS_SECTION : int32
{
	DnsSectionQuestion = 0,
	DnsSectionAnswer = 1,
	DnsSectionAuthority = 2,
	DnsSectionAddtional = 3,
}


[AllowDuplicates]
public enum DNS_PROXY_INFORMATION_TYPE : int32
{
	DNS_PROXY_INFORMATION_DIRECT = 0,
	DNS_PROXY_INFORMATION_DEFAULT_SETTINGS = 1,
	DNS_PROXY_INFORMATION_PROXY_NAME = 2,
	DNS_PROXY_INFORMATION_DOES_NOT_EXIST = 3,
}


[AllowDuplicates]
public enum DNS_CHARSET : int32
{
	DnsCharSetUnknown = 0,
	DnsCharSetUnicode = 1,
	DnsCharSetUtf8 = 2,
	DnsCharSetAnsi = 3,
}


[AllowDuplicates]
public enum DNS_FREE_TYPE : int32
{
	DnsFreeFlat = 0,
	DnsFreeRecordList = 1,
	DnsFreeParsedMessageFields = 2,
}


[AllowDuplicates]
public enum DNS_NAME_FORMAT : int32
{
	DnsNameDomain = 0,
	DnsNameDomainLabel = 1,
	DnsNameHostnameFull = 2,
	DnsNameHostnameLabel = 3,
	DnsNameWildcard = 4,
	DnsNameSrvRecord = 5,
	DnsNameValidateTld = 6,
}


[AllowDuplicates]
public enum DNS_CONNECTION_PROXY_TYPE : int32
{
	DNS_CONNECTION_PROXY_TYPE_NULL = 0,
	DNS_CONNECTION_PROXY_TYPE_HTTP = 1,
	DNS_CONNECTION_PROXY_TYPE_WAP = 2,
	DNS_CONNECTION_PROXY_TYPE_SOCKS4 = 4,
	DNS_CONNECTION_PROXY_TYPE_SOCKS5 = 5,
}


[AllowDuplicates]
public enum DNS_CONNECTION_PROXY_INFO_SWITCH : int32
{
	DNS_CONNECTION_PROXY_INFO_SWITCH_CONFIG = 0,
	DNS_CONNECTION_PROXY_INFO_SWITCH_SCRIPT = 1,
	DNS_CONNECTION_PROXY_INFO_SWITCH_WPAD = 2,
}


[AllowDuplicates]
public enum DNS_CONNECTION_POLICY_TAG : int32
{
	TAG_DNS_CONNECTION_POLICY_TAG_DEFAULT = 0,
	TAG_DNS_CONNECTION_POLICY_TAG_CONNECTION_MANAGER = 1,
	TAG_DNS_CONNECTION_POLICY_TAG_WWWPT = 2,
}

#endregion

#region Function Pointers
public function void DNS_PROXY_COMPLETION_ROUTINE(void* completionContext, int32 status);

public function void PDNS_QUERY_COMPLETION_ROUTINE(void* pQueryContext, DNS_QUERY_RESULT* pQueryResults);

public function void PDNS_SERVICE_BROWSE_CALLBACK(uint32 Status, void* pQueryContext, DNS_RECORDW* pDnsRecord);

public function void PDNS_SERVICE_RESOLVE_COMPLETE(uint32 Status, void* pQueryContext, DNS_SERVICE_INSTANCE* pInstance);

public function void PDNS_SERVICE_REGISTER_COMPLETE(uint32 Status, void* pQueryContext, DNS_SERVICE_INSTANCE* pInstance);

public function void PMDNS_QUERY_CALLBACK(void* pQueryContext, MDNS_QUERY_HANDLE* pQueryHandle, DNS_QUERY_RESULT* pQueryResults);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr, Union]
public struct IP6_ADDRESS
{
	public uint64[2] IP6Qword;
	public uint32[4] IP6Dword;
	public uint16[8] IP6Word;
	public uint8[16] IP6Byte;
}
#endif

[CRepr]
public struct IP4_ARRAY
{
	public uint32 AddrCount;
	public uint32* AddrArray mut => &AddrArray_impl;
	private uint32[ANYSIZE_ARRAY] AddrArray_impl;
}

#if BF_32_BIT
[CRepr, Union]
public struct IP6_ADDRESS
{
	public uint32[4] IP6Dword;
	public uint16[8] IP6Word;
	public uint8[16] IP6Byte;
}
#endif

[CRepr]
public struct DNS_ADDR
{
	[CRepr, Union, Packed(1)]
	public struct _Data_e__Union
	{
		public uint32[8] DnsAddrUserDword;
	}
	public CHAR[32] MaxSa;
	public _Data_e__Union Data;
}

[CRepr, Packed(1)]
public struct DNS_ADDR_ARRAY
{
	public uint32 MaxCount;
	public uint32 AddrCount;
	public uint32 Tag;
	public uint16 Family;
	public uint16 WordReserved;
	public uint32 Flags;
	public uint32 MatchFlag;
	public uint32 Reserved1;
	public uint32 Reserved2;
	public DNS_ADDR* AddrArray mut => &AddrArray_impl;
	private DNS_ADDR[ANYSIZE_ARRAY] AddrArray_impl;
}

[CRepr, Packed(1)]
public struct DNS_HEADER
{
	public uint16 Xid;
	public uint8 _bitfield1;
	public uint8 _bitfield2;
	public uint16 QuestionCount;
	public uint16 AnswerCount;
	public uint16 NameServerCount;
	public uint16 AdditionalCount;
}

[CRepr, Packed(1)]
public struct DNS_HEADER_EXT
{
	public uint16 _bitfield;
	public uint8 chRcode;
	public uint8 chVersion;
}

[CRepr, Packed(1)]
public struct DNS_WIRE_QUESTION
{
	public uint16 QuestionType;
	public uint16 QuestionClass;
}

[CRepr, Packed(1)]
public struct DNS_WIRE_RECORD
{
	public uint16 RecordType;
	public uint16 RecordClass;
	public uint32 TimeToLive;
	public uint16 DataLength;
}

[CRepr]
public struct DNS_A_DATA
{
	public uint32 IpAddress;
}

[CRepr]
public struct DNS_PTR_DATAW
{
	public PWSTR pNameHost;
}

[CRepr]
public struct DNS_PTR_DATAA
{
	public PSTR pNameHost;
}

[CRepr]
public struct DNS_SOA_DATAW
{
	public PWSTR pNamePrimaryServer;
	public PWSTR pNameAdministrator;
	public uint32 dwSerialNo;
	public uint32 dwRefresh;
	public uint32 dwRetry;
	public uint32 dwExpire;
	public uint32 dwDefaultTtl;
}

[CRepr]
public struct DNS_SOA_DATAA
{
	public PSTR pNamePrimaryServer;
	public PSTR pNameAdministrator;
	public uint32 dwSerialNo;
	public uint32 dwRefresh;
	public uint32 dwRetry;
	public uint32 dwExpire;
	public uint32 dwDefaultTtl;
}

[CRepr]
public struct DNS_MINFO_DATAW
{
	public PWSTR pNameMailbox;
	public PWSTR pNameErrorsMailbox;
}

[CRepr]
public struct DNS_MINFO_DATAA
{
	public PSTR pNameMailbox;
	public PSTR pNameErrorsMailbox;
}

[CRepr]
public struct DNS_MX_DATAW
{
	public PWSTR pNameExchange;
	public uint16 wPreference;
	public uint16 Pad;
}

[CRepr]
public struct DNS_MX_DATAA
{
	public PSTR pNameExchange;
	public uint16 wPreference;
	public uint16 Pad;
}

[CRepr]
public struct DNS_TXT_DATAW
{
	public uint32 dwStringCount;
	public PWSTR* pStringArray mut => &pStringArray_impl;
	private PWSTR[ANYSIZE_ARRAY] pStringArray_impl;
}

[CRepr]
public struct DNS_TXT_DATAA
{
	public uint32 dwStringCount;
	public PSTR* pStringArray mut => &pStringArray_impl;
	private PSTR[ANYSIZE_ARRAY] pStringArray_impl;
}

[CRepr]
public struct DNS_NULL_DATA
{
	public uint32 dwByteCount;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct DNS_WKS_DATA
{
	public uint32 IpAddress;
	public uint8 chProtocol;
	public uint8* BitMask mut => &BitMask_impl;
	private uint8[ANYSIZE_ARRAY] BitMask_impl;
}

[CRepr]
public struct DNS_AAAA_DATA
{
	public IP6_ADDRESS Ip6Address;
}

[CRepr]
public struct DNS_SIG_DATAW
{
	public uint16 wTypeCovered;
	public uint8 chAlgorithm;
	public uint8 chLabelCount;
	public uint32 dwOriginalTtl;
	public uint32 dwExpiration;
	public uint32 dwTimeSigned;
	public uint16 wKeyTag;
	public uint16 wSignatureLength;
	public PWSTR pNameSigner;
	public uint8* Signature mut => &Signature_impl;
	private uint8[ANYSIZE_ARRAY] Signature_impl;
}

[CRepr]
public struct DNS_SIG_DATAA
{
	public uint16 wTypeCovered;
	public uint8 chAlgorithm;
	public uint8 chLabelCount;
	public uint32 dwOriginalTtl;
	public uint32 dwExpiration;
	public uint32 dwTimeSigned;
	public uint16 wKeyTag;
	public uint16 wSignatureLength;
	public PSTR pNameSigner;
	public uint8* Signature mut => &Signature_impl;
	private uint8[ANYSIZE_ARRAY] Signature_impl;
}

[CRepr]
public struct DNS_KEY_DATA
{
	public uint16 wFlags;
	public uint8 chProtocol;
	public uint8 chAlgorithm;
	public uint16 wKeyLength;
	public uint16 wPad;
	public uint8* Key mut => &Key_impl;
	private uint8[ANYSIZE_ARRAY] Key_impl;
}

[CRepr]
public struct DNS_DHCID_DATA
{
	public uint32 dwByteCount;
	public uint8* DHCID mut => &DHCID_impl;
	private uint8[ANYSIZE_ARRAY] DHCID_impl;
}

[CRepr]
public struct DNS_NSEC_DATAW
{
	public PWSTR pNextDomainName;
	public uint16 wTypeBitMapsLength;
	public uint16 wPad;
	public uint8* TypeBitMaps mut => &TypeBitMaps_impl;
	private uint8[ANYSIZE_ARRAY] TypeBitMaps_impl;
}

[CRepr]
public struct DNS_NSEC_DATAA
{
	public PSTR pNextDomainName;
	public uint16 wTypeBitMapsLength;
	public uint16 wPad;
	public uint8* TypeBitMaps mut => &TypeBitMaps_impl;
	private uint8[ANYSIZE_ARRAY] TypeBitMaps_impl;
}

[CRepr]
public struct DNS_NSEC3_DATA
{
	public uint8 chAlgorithm;
	public uint8 bFlags;
	public uint16 wIterations;
	public uint8 bSaltLength;
	public uint8 bHashLength;
	public uint16 wTypeBitMapsLength;
	public uint8* chData mut => &chData_impl;
	private uint8[ANYSIZE_ARRAY] chData_impl;
}

[CRepr]
public struct DNS_NSEC3PARAM_DATA
{
	public uint8 chAlgorithm;
	public uint8 bFlags;
	public uint16 wIterations;
	public uint8 bSaltLength;
	public uint8[3] bPad;
	public uint8* pbSalt mut => &pbSalt_impl;
	private uint8[ANYSIZE_ARRAY] pbSalt_impl;
}

[CRepr]
public struct DNS_TLSA_DATA
{
	public uint8 bCertUsage;
	public uint8 bSelector;
	public uint8 bMatchingType;
	public uint16 bCertificateAssociationDataLength;
	public uint8[3] bPad;
	public uint8* bCertificateAssociationData mut => &bCertificateAssociationData_impl;
	private uint8[ANYSIZE_ARRAY] bCertificateAssociationData_impl;
}

[CRepr]
public struct DNS_DS_DATA
{
	public uint16 wKeyTag;
	public uint8 chAlgorithm;
	public uint8 chDigestType;
	public uint16 wDigestLength;
	public uint16 wPad;
	public uint8* Digest mut => &Digest_impl;
	private uint8[ANYSIZE_ARRAY] Digest_impl;
}

[CRepr]
public struct DNS_OPT_DATA
{
	public uint16 wDataLength;
	public uint16 wPad;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct DNS_LOC_DATA
{
	public uint16 wVersion;
	public uint16 wSize;
	public uint16 wHorPrec;
	public uint16 wVerPrec;
	public uint32 dwLatitude;
	public uint32 dwLongitude;
	public uint32 dwAltitude;
}

[CRepr]
public struct DNS_NXT_DATAW
{
	public PWSTR pNameNext;
	public uint16 wNumTypes;
	public uint16* wTypes mut => &wTypes_impl;
	private uint16[ANYSIZE_ARRAY] wTypes_impl;
}

[CRepr]
public struct DNS_NXT_DATAA
{
	public PSTR pNameNext;
	public uint16 wNumTypes;
	public uint16* wTypes mut => &wTypes_impl;
	private uint16[ANYSIZE_ARRAY] wTypes_impl;
}

[CRepr]
public struct DNS_SRV_DATAW
{
	public PWSTR pNameTarget;
	public uint16 wPriority;
	public uint16 wWeight;
	public uint16 wPort;
	public uint16 Pad;
}

[CRepr]
public struct DNS_SRV_DATAA
{
	public PSTR pNameTarget;
	public uint16 wPriority;
	public uint16 wWeight;
	public uint16 wPort;
	public uint16 Pad;
}

[CRepr]
public struct DNS_NAPTR_DATAW
{
	public uint16 wOrder;
	public uint16 wPreference;
	public PWSTR pFlags;
	public PWSTR pService;
	public PWSTR pRegularExpression;
	public PWSTR pReplacement;
}

[CRepr]
public struct DNS_NAPTR_DATAA
{
	public uint16 wOrder;
	public uint16 wPreference;
	public PSTR pFlags;
	public PSTR pService;
	public PSTR pRegularExpression;
	public PSTR pReplacement;
}

[CRepr]
public struct DNS_ATMA_DATA
{
	public uint8 AddressType;
	public uint8[20] Address;
}

[CRepr]
public struct DNS_TKEY_DATAW
{
	public PWSTR pNameAlgorithm;
	public uint8* pAlgorithmPacket;
	public uint8* pKey;
	public uint8* pOtherData;
	public uint32 dwCreateTime;
	public uint32 dwExpireTime;
	public uint16 wMode;
	public uint16 wError;
	public uint16 wKeyLength;
	public uint16 wOtherLength;
	public uint8 cAlgNameLength;
	public BOOL bPacketPointers;
}

[CRepr]
public struct DNS_TKEY_DATAA
{
	public PSTR pNameAlgorithm;
	public uint8* pAlgorithmPacket;
	public uint8* pKey;
	public uint8* pOtherData;
	public uint32 dwCreateTime;
	public uint32 dwExpireTime;
	public uint16 wMode;
	public uint16 wError;
	public uint16 wKeyLength;
	public uint16 wOtherLength;
	public uint8 cAlgNameLength;
	public BOOL bPacketPointers;
}

[CRepr]
public struct DNS_TSIG_DATAW
{
	public PWSTR pNameAlgorithm;
	public uint8* pAlgorithmPacket;
	public uint8* pSignature;
	public uint8* pOtherData;
	public int64 i64CreateTime;
	public uint16 wFudgeTime;
	public uint16 wOriginalXid;
	public uint16 wError;
	public uint16 wSigLength;
	public uint16 wOtherLength;
	public uint8 cAlgNameLength;
	public BOOL bPacketPointers;
}

[CRepr]
public struct DNS_TSIG_DATAA
{
	public PSTR pNameAlgorithm;
	public uint8* pAlgorithmPacket;
	public uint8* pSignature;
	public uint8* pOtherData;
	public int64 i64CreateTime;
	public uint16 wFudgeTime;
	public uint16 wOriginalXid;
	public uint16 wError;
	public uint16 wSigLength;
	public uint16 wOtherLength;
	public uint8 cAlgNameLength;
	public BOOL bPacketPointers;
}

[CRepr]
public struct DNS_UNKNOWN_DATA
{
	public uint32 dwByteCount;
	public uint8* bData mut => &bData_impl;
	private uint8[ANYSIZE_ARRAY] bData_impl;
}

[CRepr]
public struct DNS_WINS_DATA
{
	public uint32 dwMappingFlag;
	public uint32 dwLookupTimeout;
	public uint32 dwCacheTimeout;
	public uint32 cWinsServerCount;
	public uint32* WinsServers mut => &WinsServers_impl;
	private uint32[ANYSIZE_ARRAY] WinsServers_impl;
}

[CRepr]
public struct DNS_WINSR_DATAW
{
	public uint32 dwMappingFlag;
	public uint32 dwLookupTimeout;
	public uint32 dwCacheTimeout;
	public PWSTR pNameResultDomain;
}

[CRepr]
public struct DNS_WINSR_DATAA
{
	public uint32 dwMappingFlag;
	public uint32 dwLookupTimeout;
	public uint32 dwCacheTimeout;
	public PSTR pNameResultDomain;
}

[CRepr]
public struct DNS_RECORD_FLAGS
{
	public uint32 _bitfield;
}

[CRepr]
public struct DNS_RECORDW
{
	[CRepr, Union]
	public struct _Flags_e__Union
	{
		public uint32 DW;
		public DNS_RECORD_FLAGS S;
	}
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public DNS_A_DATA A;
		public DNS_SOA_DATAW SOA;
		public DNS_SOA_DATAW Soa;
		public DNS_PTR_DATAW PTR;
		public DNS_PTR_DATAW Ptr;
		public DNS_PTR_DATAW NS;
		public DNS_PTR_DATAW Ns;
		public DNS_PTR_DATAW CNAME;
		public DNS_PTR_DATAW Cname;
		public DNS_PTR_DATAW DNAME;
		public DNS_PTR_DATAW Dname;
		public DNS_PTR_DATAW MB;
		public DNS_PTR_DATAW Mb;
		public DNS_PTR_DATAW MD;
		public DNS_PTR_DATAW Md;
		public DNS_PTR_DATAW MF;
		public DNS_PTR_DATAW Mf;
		public DNS_PTR_DATAW MG;
		public DNS_PTR_DATAW Mg;
		public DNS_PTR_DATAW MR;
		public DNS_PTR_DATAW Mr;
		public DNS_MINFO_DATAW MINFO;
		public DNS_MINFO_DATAW Minfo;
		public DNS_MINFO_DATAW RP;
		public DNS_MINFO_DATAW Rp;
		public DNS_MX_DATAW MX;
		public DNS_MX_DATAW Mx;
		public DNS_MX_DATAW AFSDB;
		public DNS_MX_DATAW Afsdb;
		public DNS_MX_DATAW RT;
		public DNS_MX_DATAW Rt;
		public DNS_TXT_DATAW HINFO;
		public DNS_TXT_DATAW Hinfo;
		public DNS_TXT_DATAW ISDN;
		public DNS_TXT_DATAW Isdn;
		public DNS_TXT_DATAW TXT;
		public DNS_TXT_DATAW Txt;
		public DNS_TXT_DATAW X25;
		public DNS_NULL_DATA Null;
		public DNS_WKS_DATA WKS;
		public DNS_WKS_DATA Wks;
		public DNS_AAAA_DATA AAAA;
		public DNS_KEY_DATA KEY;
		public DNS_KEY_DATA Key;
		public DNS_SIG_DATAW SIG;
		public DNS_SIG_DATAW Sig;
		public DNS_ATMA_DATA ATMA;
		public DNS_ATMA_DATA Atma;
		public DNS_NXT_DATAW NXT;
		public DNS_NXT_DATAW Nxt;
		public DNS_SRV_DATAW SRV;
		public DNS_SRV_DATAW Srv;
		public DNS_NAPTR_DATAW NAPTR;
		public DNS_NAPTR_DATAW Naptr;
		public DNS_OPT_DATA OPT;
		public DNS_OPT_DATA Opt;
		public DNS_DS_DATA DS;
		public DNS_DS_DATA Ds;
		public DNS_SIG_DATAW RRSIG;
		public DNS_SIG_DATAW Rrsig;
		public DNS_NSEC_DATAW NSEC;
		public DNS_NSEC_DATAW Nsec;
		public DNS_KEY_DATA DNSKEY;
		public DNS_KEY_DATA Dnskey;
		public DNS_TKEY_DATAW TKEY;
		public DNS_TKEY_DATAW Tkey;
		public DNS_TSIG_DATAW TSIG;
		public DNS_TSIG_DATAW Tsig;
		public DNS_WINS_DATA WINS;
		public DNS_WINS_DATA Wins;
		public DNS_WINSR_DATAW WINSR;
		public DNS_WINSR_DATAW WinsR;
		public DNS_WINSR_DATAW NBSTAT;
		public DNS_WINSR_DATAW Nbstat;
		public DNS_DHCID_DATA DHCID;
		public DNS_NSEC3_DATA NSEC3;
		public DNS_NSEC3_DATA Nsec3;
		public DNS_NSEC3PARAM_DATA NSEC3PARAM;
		public DNS_NSEC3PARAM_DATA Nsec3Param;
		public DNS_TLSA_DATA TLSA;
		public DNS_TLSA_DATA Tlsa;
		public DNS_UNKNOWN_DATA UNKNOWN;
		public DNS_UNKNOWN_DATA Unknown;
		public uint8* pDataPtr;
	}
	public DNS_RECORDW* pNext;
	public PWSTR pName;
	public uint16 wType;
	public uint16 wDataLength;
	public _Flags_e__Union Flags;
	public uint32 dwTtl;
	public uint32 dwReserved;
	public _Data_e__Union Data;
}

[CRepr]
public struct DNS_RECORD_OPTW
{
	[CRepr, Union]
	public struct _Flags_e__Union
	{
		public uint32 DW;
		public DNS_RECORD_FLAGS S;
	}
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public DNS_OPT_DATA OPT;
		public DNS_OPT_DATA Opt;
	}
	public DNS_RECORDW* pNext;
	public PWSTR pName;
	public uint16 wType;
	public uint16 wDataLength;
	public _Flags_e__Union Flags;
	public DNS_HEADER_EXT ExtHeader;
	public uint16 wPayloadSize;
	public uint16 wReserved;
	public _Data_e__Union Data;
}

[CRepr]
public struct DNS_RECORDA
{
	[CRepr, Union]
	public struct _Flags_e__Union
	{
		public uint32 DW;
		public DNS_RECORD_FLAGS S;
	}
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public DNS_A_DATA A;
		public DNS_SOA_DATAA SOA;
		public DNS_SOA_DATAA Soa;
		public DNS_PTR_DATAA PTR;
		public DNS_PTR_DATAA Ptr;
		public DNS_PTR_DATAA NS;
		public DNS_PTR_DATAA Ns;
		public DNS_PTR_DATAA CNAME;
		public DNS_PTR_DATAA Cname;
		public DNS_PTR_DATAA DNAME;
		public DNS_PTR_DATAA Dname;
		public DNS_PTR_DATAA MB;
		public DNS_PTR_DATAA Mb;
		public DNS_PTR_DATAA MD;
		public DNS_PTR_DATAA Md;
		public DNS_PTR_DATAA MF;
		public DNS_PTR_DATAA Mf;
		public DNS_PTR_DATAA MG;
		public DNS_PTR_DATAA Mg;
		public DNS_PTR_DATAA MR;
		public DNS_PTR_DATAA Mr;
		public DNS_MINFO_DATAA MINFO;
		public DNS_MINFO_DATAA Minfo;
		public DNS_MINFO_DATAA RP;
		public DNS_MINFO_DATAA Rp;
		public DNS_MX_DATAA MX;
		public DNS_MX_DATAA Mx;
		public DNS_MX_DATAA AFSDB;
		public DNS_MX_DATAA Afsdb;
		public DNS_MX_DATAA RT;
		public DNS_MX_DATAA Rt;
		public DNS_TXT_DATAA HINFO;
		public DNS_TXT_DATAA Hinfo;
		public DNS_TXT_DATAA ISDN;
		public DNS_TXT_DATAA Isdn;
		public DNS_TXT_DATAA TXT;
		public DNS_TXT_DATAA Txt;
		public DNS_TXT_DATAA X25;
		public DNS_NULL_DATA Null;
		public DNS_WKS_DATA WKS;
		public DNS_WKS_DATA Wks;
		public DNS_AAAA_DATA AAAA;
		public DNS_KEY_DATA KEY;
		public DNS_KEY_DATA Key;
		public DNS_SIG_DATAA SIG;
		public DNS_SIG_DATAA Sig;
		public DNS_ATMA_DATA ATMA;
		public DNS_ATMA_DATA Atma;
		public DNS_NXT_DATAA NXT;
		public DNS_NXT_DATAA Nxt;
		public DNS_SRV_DATAA SRV;
		public DNS_SRV_DATAA Srv;
		public DNS_NAPTR_DATAA NAPTR;
		public DNS_NAPTR_DATAA Naptr;
		public DNS_OPT_DATA OPT;
		public DNS_OPT_DATA Opt;
		public DNS_DS_DATA DS;
		public DNS_DS_DATA Ds;
		public DNS_SIG_DATAA RRSIG;
		public DNS_SIG_DATAA Rrsig;
		public DNS_NSEC_DATAA NSEC;
		public DNS_NSEC_DATAA Nsec;
		public DNS_KEY_DATA DNSKEY;
		public DNS_KEY_DATA Dnskey;
		public DNS_TKEY_DATAA TKEY;
		public DNS_TKEY_DATAA Tkey;
		public DNS_TSIG_DATAA TSIG;
		public DNS_TSIG_DATAA Tsig;
		public DNS_WINS_DATA WINS;
		public DNS_WINS_DATA Wins;
		public DNS_WINSR_DATAA WINSR;
		public DNS_WINSR_DATAA WinsR;
		public DNS_WINSR_DATAA NBSTAT;
		public DNS_WINSR_DATAA Nbstat;
		public DNS_DHCID_DATA DHCID;
		public DNS_NSEC3_DATA NSEC3;
		public DNS_NSEC3_DATA Nsec3;
		public DNS_NSEC3PARAM_DATA NSEC3PARAM;
		public DNS_NSEC3PARAM_DATA Nsec3Param;
		public DNS_TLSA_DATA TLSA;
		public DNS_TLSA_DATA Tlsa;
		public DNS_UNKNOWN_DATA UNKNOWN;
		public DNS_UNKNOWN_DATA Unknown;
		public uint8* pDataPtr;
	}
	public DNS_RECORDA* pNext;
	public PSTR pName;
	public uint16 wType;
	public uint16 wDataLength;
	public _Flags_e__Union Flags;
	public uint32 dwTtl;
	public uint32 dwReserved;
	public _Data_e__Union Data;
}

[CRepr]
public struct _DnsRecordOptA
{
	[CRepr, Union]
	public struct _Flags_e__Union
	{
		public uint32 DW;
		public DNS_RECORD_FLAGS S;
	}
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public DNS_OPT_DATA OPT;
		public DNS_OPT_DATA Opt;
	}
	public DNS_RECORDA* pNext;
	public PSTR pName;
	public uint16 wType;
	public uint16 wDataLength;
	public _Flags_e__Union Flags;
	public DNS_HEADER_EXT ExtHeader;
	public uint16 wPayloadSize;
	public uint16 wReserved;
	public _Data_e__Union Data;
}

[CRepr]
public struct DNS_RRSET
{
	public DNS_RECORDA* pFirstRR;
	public DNS_RECORDA* pLastRR;
}

[CRepr]
public struct DNS_PROXY_INFORMATION
{
	public uint32 version;
	public DNS_PROXY_INFORMATION_TYPE proxyInformationType;
	public PWSTR proxyName;
}

[CRepr]
public struct DNS_QUERY_RESULT
{
	public uint32 Version;
	public int32 QueryStatus;
	public uint64 QueryOptions;
	public DNS_RECORDA* pQueryRecords;
	public void* Reserved;
}

[CRepr]
public struct DNS_QUERY_REQUEST
{
	public uint32 Version;
	public PWSTR QueryName;
	public uint16 QueryType;
	public uint64 QueryOptions;
	public DNS_ADDR_ARRAY* pDnsServerList;
	public uint32 InterfaceIndex;
	public PDNS_QUERY_COMPLETION_ROUTINE pQueryCompletionCallback;
	public void* pQueryContext;
}

[CRepr]
public struct DNS_QUERY_CANCEL
{
	public CHAR[32] Reserved;
}

[CRepr]
public struct DNS_CUSTOM_SERVER
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pwszTemplate;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public CHAR[32] MaxSa;
	}
	public uint32 dwServerType;
	public uint64 ullFlags;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct DNS_QUERY_REQUEST3
{
	public uint32 Version;
	public PWSTR QueryName;
	public uint16 QueryType;
	public uint64 QueryOptions;
	public DNS_ADDR_ARRAY* pDnsServerList;
	public uint32 InterfaceIndex;
	public PDNS_QUERY_COMPLETION_ROUTINE pQueryCompletionCallback;
	public void* pQueryContext;
	public BOOL IsNetworkQueryRequired;
	public uint32 RequiredNetworkIndex;
	public uint32 cCustomServers;
	public DNS_CUSTOM_SERVER* pCustomServers;
}

[CRepr]
public struct DNS_APPLICATION_SETTINGS
{
	public uint32 Version;
	public uint64 Flags;
}

[CRepr]
public struct DNS_MESSAGE_BUFFER
{
	public DNS_HEADER MessageHead;
	public CHAR* MessageBody mut => &MessageBody_impl;
	private CHAR[ANYSIZE_ARRAY] MessageBody_impl;
}

[CRepr]
public struct DNS_CONNECTION_PROXY_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _DNS_CONNECTION_PROXY_INFO_SCRIPT
		{
			public PWSTR pwszScript;
			public PWSTR pwszUsername;
			public PWSTR pwszPassword;
		}
		[CRepr]
		public struct _DNS_CONNECTION_PROXY_INFO_CONFIG
		{
			public PWSTR pwszServer;
			public PWSTR pwszUsername;
			public PWSTR pwszPassword;
			public PWSTR pwszException;
			public PWSTR pwszExtraInfo;
			public uint16 Port;
		}
		public _DNS_CONNECTION_PROXY_INFO_CONFIG Config;
		public _DNS_CONNECTION_PROXY_INFO_SCRIPT Script;
	}
	public uint32 Version;
	public PWSTR pwszFriendlyName;
	public uint32 Flags;
	public DNS_CONNECTION_PROXY_INFO_SWITCH Switch;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DNS_CONNECTION_PROXY_INFO_EX
{
	public DNS_CONNECTION_PROXY_INFO ProxyInfo;
	public uint32 dwInterfaceIndex;
	public PWSTR pwszConnectionName;
	public BOOL fDirectConfiguration;
	public HANDLE hConnection;
}

[CRepr]
public struct DNS_CONNECTION_PROXY_ELEMENT
{
	public DNS_CONNECTION_PROXY_TYPE Type;
	public DNS_CONNECTION_PROXY_INFO Info;
}

[CRepr]
public struct DNS_CONNECTION_PROXY_LIST
{
	public uint32 cProxies;
	public DNS_CONNECTION_PROXY_ELEMENT* pProxies;
}

[CRepr]
public struct DNS_CONNECTION_NAME
{
	public char16[65] wszName;
}

[CRepr]
public struct DNS_CONNECTION_NAME_LIST
{
	public uint32 cNames;
	public DNS_CONNECTION_NAME* pNames;
}

[CRepr]
public struct DNS_CONNECTION_IFINDEX_ENTRY
{
	public PWSTR pwszConnectionName;
	public uint32 dwIfIndex;
}

[CRepr]
public struct DNS_CONNECTION_IFINDEX_LIST
{
	public DNS_CONNECTION_IFINDEX_ENTRY* pConnectionIfIndexEntries;
	public uint32 nEntries;
}

[CRepr]
public struct DNS_CONNECTION_POLICY_ENTRY
{
	public PWSTR pwszHost;
	public PWSTR pwszAppId;
	public uint32 cbAppSid;
	public uint8* pbAppSid;
	public uint32 nConnections;
	public PWSTR* ppwszConnections;
	public uint32 dwPolicyEntryFlags;
}

[CRepr]
public struct DNS_CONNECTION_POLICY_ENTRY_LIST
{
	public DNS_CONNECTION_POLICY_ENTRY* pPolicyEntries;
	public uint32 nEntries;
}

[CRepr]
public struct DNS_SERVICE_INSTANCE
{
	public PWSTR pszInstanceName;
	public PWSTR pszHostName;
	public uint32* ip4Address;
	public IP6_ADDRESS* ip6Address;
	public uint16 wPort;
	public uint16 wPriority;
	public uint16 wWeight;
	public uint32 dwPropertyCount;
	public PWSTR* keys;
	public PWSTR* values;
	public uint32 dwInterfaceIndex;
}

[CRepr]
public struct DNS_SERVICE_CANCEL
{
	public void* reserved;
}

[CRepr]
public struct DNS_SERVICE_BROWSE_REQUEST
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PDNS_SERVICE_BROWSE_CALLBACK pBrowseCallback;
		public PDNS_QUERY_COMPLETION_ROUTINE pBrowseCallbackV2;
	}
	public uint32 Version;
	public uint32 InterfaceIndex;
	public PWSTR QueryName;
	public using _Anonymous_e__Union Anonymous;
	public void* pQueryContext;
}

[CRepr]
public struct DNS_SERVICE_RESOLVE_REQUEST
{
	public uint32 Version;
	public uint32 InterfaceIndex;
	public PWSTR QueryName;
	public PDNS_SERVICE_RESOLVE_COMPLETE pResolveCompletionCallback;
	public void* pQueryContext;
}

[CRepr]
public struct DNS_SERVICE_REGISTER_REQUEST
{
	public uint32 Version;
	public uint32 InterfaceIndex;
	public DNS_SERVICE_INSTANCE* pServiceInstance;
	public PDNS_SERVICE_REGISTER_COMPLETE pRegisterCompletionCallback;
	public void* pQueryContext;
	public HANDLE hCredentials;
	public BOOL unicastEnabled;
}

[CRepr]
public struct MDNS_QUERY_HANDLE
{
	public char16[256] nameBuf;
	public uint16 wType;
	public void* pSubscription;
	public void* pWnfCallbackParams;
	public uint32[2] stateNameData;
}

[CRepr]
public struct MDNS_QUERY_REQUEST
{
	public uint32 Version;
	public uint32 ulRefCount;
	public PWSTR Query;
	public uint16 QueryType;
	public uint64 QueryOptions;
	public uint32 InterfaceIndex;
	public PMDNS_QUERY_CALLBACK pQueryCallback;
	public void* pQueryContext;
	public BOOL fAnswerReceived;
	public uint32 ulResendCount;
}

#endregion

#region Functions
public static
{
	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsQueryConfig(DNS_CONFIG_TYPE Config, uint32 Flag, PWSTR pwsAdapterName, void* pReserved, void* pBuffer, uint32* pBufLen);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DNS_RECORDA* DnsRecordCopyEx(DNS_RECORDA* pRecord, DNS_CHARSET CharSetIn, DNS_CHARSET CharSetOut);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DNS_RECORDA* DnsRecordSetCopyEx(DNS_RECORDA* pRecordSet, DNS_CHARSET CharSetIn, DNS_CHARSET CharSetOut);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsRecordCompare(DNS_RECORDA* pRecord1, DNS_RECORDA* pRecord2);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsRecordSetCompare(DNS_RECORDA* pRR1, DNS_RECORDA* pRR2, DNS_RECORDA** ppDiff1, DNS_RECORDA** ppDiff2);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DNS_RECORDA* DnsRecordSetDetach(DNS_RECORDA* pRecordList);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsFree(void* pData, DNS_FREE_TYPE FreeType);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsQuery_A(PSTR pszName, uint16 wType, uint32 Options, void* pExtra, DNS_RECORDA** ppQueryResults, void** pReserved);
	public static int32 DnsQuery_(PSTR pszName, uint16 wType, uint32 Options, void* pExtra, DNS_RECORDA** ppQueryResults, void** pReserved) => DnsQuery_A(pszName, wType, Options, pExtra, ppQueryResults, pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsQuery_UTF8(PSTR pszName, uint16 wType, uint32 Options, void* pExtra, DNS_RECORDA** ppQueryResults, void** pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsQuery_W(PWSTR pszName, uint16 wType, uint32 Options, void* pExtra, DNS_RECORDA** ppQueryResults, void** pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsQueryEx(DNS_QUERY_REQUEST* pQueryRequest, DNS_QUERY_RESULT* pQueryResults, DNS_QUERY_CANCEL* pCancelHandle);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsCancelQuery(DNS_QUERY_CANCEL* pCancelHandle);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsFreeCustomServers(uint32* pcServers, DNS_CUSTOM_SERVER** ppServers);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsGetApplicationSettings(uint32* pcServers, DNS_CUSTOM_SERVER** ppDefaultServers, DNS_APPLICATION_SETTINGS* pSettings);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsSetApplicationSettings(uint32 cServers, DNS_CUSTOM_SERVER* pServers, DNS_APPLICATION_SETTINGS* pSettings);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsAcquireContextHandle_W(uint32 CredentialFlags, void* Credentials, DnsContextHandle* pContext);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsAcquireContextHandle_A(uint32 CredentialFlags, void* Credentials, DnsContextHandle* pContext);
	public static int32 DnsAcquireContextHandle_(uint32 CredentialFlags, void* Credentials, DnsContextHandle* pContext) => DnsAcquireContextHandle_A(CredentialFlags, Credentials, pContext);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsReleaseContextHandle(HANDLE hContext);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsModifyRecordsInSet_W(DNS_RECORDA* pAddRecords, DNS_RECORDA* pDeleteRecords, uint32 Options, HANDLE hCredentials, void* pExtraList, void* pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsModifyRecordsInSet_A(DNS_RECORDA* pAddRecords, DNS_RECORDA* pDeleteRecords, uint32 Options, HANDLE hCredentials, void* pExtraList, void* pReserved);
	public static int32 DnsModifyRecordsInSet_(DNS_RECORDA* pAddRecords, DNS_RECORDA* pDeleteRecords, uint32 Options, HANDLE hCredentials, void* pExtraList, void* pReserved) => DnsModifyRecordsInSet_A(pAddRecords, pDeleteRecords, Options, hCredentials, pExtraList, pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsModifyRecordsInSet_UTF8(DNS_RECORDA* pAddRecords, DNS_RECORDA* pDeleteRecords, uint32 Options, HANDLE hCredentials, void* pExtraList, void* pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsReplaceRecordSetW(DNS_RECORDA* pReplaceSet, uint32 Options, HANDLE hContext, void* pExtraInfo, void* pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsReplaceRecordSetA(DNS_RECORDA* pReplaceSet, uint32 Options, HANDLE hContext, void* pExtraInfo, void* pReserved);
	public static int32 DnsReplaceRecordSet(DNS_RECORDA* pReplaceSet, uint32 Options, HANDLE hContext, void* pExtraInfo, void* pReserved) => DnsReplaceRecordSetA(pReplaceSet, Options, hContext, pExtraInfo, pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsReplaceRecordSetUTF8(DNS_RECORDA* pReplaceSet, uint32 Options, HANDLE hContext, void* pExtraInfo, void* pReserved);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsValidateName_W(PWSTR pszName, DNS_NAME_FORMAT Format);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsValidateName_A(PSTR pszName, DNS_NAME_FORMAT Format);
	public static int32 DnsValidateName_(PSTR pszName, DNS_NAME_FORMAT Format) => DnsValidateName_A(pszName, Format);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsValidateName_UTF8(PSTR pszName, DNS_NAME_FORMAT Format);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsNameCompare_A(PSTR pName1, PSTR pName2);
	public static BOOL DnsNameCompare_(PSTR pName1, PSTR pName2) => DnsNameCompare_A(pName1, pName2);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsNameCompare_W(PWSTR pName1, PWSTR pName2);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsWriteQuestionToBuffer_W(DNS_MESSAGE_BUFFER* pDnsBuffer, uint32* pdwBufferSize, PWSTR pszName, uint16 wType, uint16 Xid, BOOL fRecursionDesired);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DnsWriteQuestionToBuffer_UTF8(DNS_MESSAGE_BUFFER* pDnsBuffer, uint32* pdwBufferSize, PSTR pszName, uint16 wType, uint16 Xid, BOOL fRecursionDesired);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsExtractRecordsFromMessage_W(DNS_MESSAGE_BUFFER* pDnsBuffer, uint16 wMessageLength, DNS_RECORDA** ppRecord);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsExtractRecordsFromMessage_UTF8(DNS_MESSAGE_BUFFER* pDnsBuffer, uint16 wMessageLength, DNS_RECORDA** ppRecord);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsGetProxyInformation(PWSTR hostName, DNS_PROXY_INFORMATION* proxyInformation, DNS_PROXY_INFORMATION* defaultProxyInformation, DNS_PROXY_COMPLETION_ROUTINE completionRoutine, void* completionContext);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsFreeProxyName(PWSTR proxyName);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionGetProxyInfoForHostUrl(PWSTR pwszHostUrl, uint8* pSelectionContext, uint32 dwSelectionContextLength, uint32 dwExplicitInterfaceIndex, DNS_CONNECTION_PROXY_INFO_EX* pProxyInfoEx);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsConnectionFreeProxyInfoEx(DNS_CONNECTION_PROXY_INFO_EX* pProxyInfoEx);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionGetProxyInfo(PWSTR pwszConnectionName, DNS_CONNECTION_PROXY_TYPE Type, DNS_CONNECTION_PROXY_INFO* pProxyInfo);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsConnectionFreeProxyInfo(DNS_CONNECTION_PROXY_INFO* pProxyInfo);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionSetProxyInfo(PWSTR pwszConnectionName, DNS_CONNECTION_PROXY_TYPE Type, DNS_CONNECTION_PROXY_INFO* pProxyInfo);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionDeleteProxyInfo(PWSTR pwszConnectionName, DNS_CONNECTION_PROXY_TYPE Type);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionGetProxyList(PWSTR pwszConnectionName, DNS_CONNECTION_PROXY_LIST* pProxyList);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsConnectionFreeProxyList(DNS_CONNECTION_PROXY_LIST* pProxyList);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionGetNameList(DNS_CONNECTION_NAME_LIST* pNameList);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsConnectionFreeNameList(DNS_CONNECTION_NAME_LIST* pNameList);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionUpdateIfIndexTable(DNS_CONNECTION_IFINDEX_LIST* pConnectionIfIndexEntries);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionSetPolicyEntries(DNS_CONNECTION_POLICY_TAG PolicyEntryTag, DNS_CONNECTION_POLICY_ENTRY_LIST* pPolicyEntryList);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsConnectionDeletePolicyEntries(DNS_CONNECTION_POLICY_TAG PolicyEntryTag);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DNS_SERVICE_INSTANCE* DnsServiceConstructInstance(PWSTR pServiceName, PWSTR pHostName, uint32* pIp4, IP6_ADDRESS* pIp6, uint16 wPort, uint16 wPriority, uint16 wWeight, uint32 dwPropertiesCount, PWSTR* keys, PWSTR* values);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DNS_SERVICE_INSTANCE* DnsServiceCopyInstance(DNS_SERVICE_INSTANCE* pOrig);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DnsServiceFreeInstance(DNS_SERVICE_INSTANCE* pInstance);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsServiceBrowse(DNS_SERVICE_BROWSE_REQUEST* pRequest, DNS_SERVICE_CANCEL* pCancel);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsServiceBrowseCancel(DNS_SERVICE_CANCEL* pCancelHandle);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsServiceResolve(DNS_SERVICE_RESOLVE_REQUEST* pRequest, DNS_SERVICE_CANCEL* pCancel);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsServiceResolveCancel(DNS_SERVICE_CANCEL* pCancelHandle);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsServiceRegister(DNS_SERVICE_REGISTER_REQUEST* pRequest, DNS_SERVICE_CANCEL* pCancel);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsServiceDeRegister(DNS_SERVICE_REGISTER_REQUEST* pRequest, DNS_SERVICE_CANCEL* pCancel);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DnsServiceRegisterCancel(DNS_SERVICE_CANCEL* pCancelHandle);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsStartMulticastQuery(MDNS_QUERY_REQUEST* pQueryRequest, MDNS_QUERY_HANDLE* pHandle);

	[Import("DNSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DnsStopMulticastQuery(MDNS_QUERY_HANDLE* pHandle);

}
#endregion
