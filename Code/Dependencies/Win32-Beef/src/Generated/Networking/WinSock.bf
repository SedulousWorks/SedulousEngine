using Win32.Foundation;
using Win32.System.Kernel;
using Win32.System.IO;
using Win32.System.Com;
using System;

namespace Win32.Networking.WinSock;

#region Constants
public static
{
	public const Guid SOCKET_DEFAULT2_QM_POLICY = .(0xaec2ef9c, 0x3a4d, 0x4d3e, 0x88, 0x42, 0x23, 0x99, 0x42, 0xe3, 0x9a, 0x47);
	public const Guid REAL_TIME_NOTIFICATION_CAPABILITY = .(0x6b59819a, 0x5cae, 0x492d, 0xa9, 0x01, 0x2a, 0x3c, 0x2c, 0x50, 0x16, 0x4f);
	public const Guid REAL_TIME_NOTIFICATION_CAPABILITY_EX = .(0x6843da03, 0x154a, 0x4616, 0xa5, 0x08, 0x44, 0x37, 0x12, 0x95, 0xf9, 0x6b);
	public const Guid ASSOCIATE_NAMERES_CONTEXT = .(0x59a38b67, 0xd4fe, 0x46e1, 0xba, 0x3c, 0x87, 0xea, 0x74, 0xca, 0x30, 0x49);
	public const uint32 SIO_RCVALL = 2550136833;
	public const uint32 SIO_RCVALL_MCAST = 2550136834;
	public const uint32 SIO_RCVALL_IGMPMCAST = 2550136835;
	public const uint32 SIO_KEEPALIVE_VALS = 2550136836;
	public const uint32 SIO_ABSORB_RTRALERT = 2550136837;
	public const uint32 SIO_UCAST_IF = 2550136838;
	public const uint32 SIO_LIMIT_BROADCASTS = 2550136839;
	public const uint32 SIO_INDEX_BIND = 2550136840;
	public const uint32 SIO_INDEX_MCASTIF = 2550136841;
	public const uint32 SIO_INDEX_ADD_MCAST = 2550136842;
	public const uint32 SIO_INDEX_DEL_MCAST = 2550136843;
	public const uint32 SIO_RCVALL_MCAST_IF = 2550136845;
	public const uint32 SIO_RCVALL_IF = 2550136846;
	public const uint32 SIO_LOOPBACK_FAST_PATH = 2550136848;
	public const uint32 SIO_TCP_INITIAL_RTO = 2550136849;
	public const uint32 SIO_APPLY_TRANSPORT_SETTING = 2550136851;
	public const uint32 SIO_QUERY_TRANSPORT_SETTING = 2550136852;
	public const uint32 SIO_TCP_SET_ICW = 2550136854;
	public const uint32 SIO_TCP_SET_ACK_FREQUENCY = 2550136855;
	public const uint32 SIO_SET_PRIORITY_HINT = 2550136856;
	public const uint32 SIO_PRIORITY_HINT = 2550136856;
	public const uint32 SIO_TCP_INFO = 3623878695;
	public const uint32 SIO_CPU_AFFINITY = 2550136853;
	public const uint32 SIO_TIMESTAMPING = 2550137067;
	public const uint32 TIMESTAMPING_FLAG_RX = 1;
	public const uint32 TIMESTAMPING_FLAG_TX = 2;
	public const uint32 SO_TIMESTAMP = 12298;
	public const uint32 SO_TIMESTAMP_ID = 12299;
	public const uint32 SIO_GET_TX_TIMESTAMP = 2550137066;
	public const uint32 TCP_INITIAL_RTO_DEFAULT_RTT = 0;
	public const uint32 TCP_INITIAL_RTO_DEFAULT_MAX_SYN_RETRANSMISSIONS = 0;
	public const uint32 SIO_ACQUIRE_PORT_RESERVATION = 2550136932;
	public const uint32 SIO_RELEASE_PORT_RESERVATION = 2550136933;
	public const uint32 SIO_ASSOCIATE_PORT_RESERVATION = 2550136934;
	public const uint32 SIO_SET_SECURITY = 2550137032;
	public const uint32 SIO_QUERY_SECURITY = 3623878857;
	public const uint32 SIO_SET_PEER_TARGET_NAME = 2550137034;
	public const uint32 SIO_DELETE_PEER_TARGET_NAME = 2550137035;
	public const uint32 SIO_QUERY_WFP_CONNECTION_REDIRECT_RECORDS = 2550137052;
	public const uint32 SIO_QUERY_WFP_CONNECTION_REDIRECT_CONTEXT = 2550137053;
	public const uint32 SIO_SET_WFP_CONNECTION_REDIRECT_RECORDS = 2550137054;
	public const uint32 SIO_SOCKET_USAGE_NOTIFICATION = 2550137036;
	public const uint32 SOCKET_SETTINGS_GUARANTEE_ENCRYPTION = 1;
	public const uint32 SOCKET_SETTINGS_ALLOW_INSECURE = 2;
	public const uint32 SOCKET_SETTINGS_IPSEC_SKIP_FILTER_INSTANTIATION = 1;
	public const uint32 SOCKET_SETTINGS_IPSEC_OPTIONAL_PEER_NAME_VERIFICATION = 2;
	public const uint32 SOCKET_SETTINGS_IPSEC_ALLOW_FIRST_INBOUND_PKT_UNENCRYPTED = 4;
	public const uint32 SOCKET_SETTINGS_IPSEC_PEER_NAME_IS_RAW_FORMAT = 8;
	public const uint32 SOCKET_QUERY_IPSEC2_ABORT_CONNECTION_ON_FIELD_CHANGE = 1;
	public const uint32 SOCKET_QUERY_IPSEC2_FIELD_MASK_MM_SA_ID = 1;
	public const uint32 SOCKET_QUERY_IPSEC2_FIELD_MASK_QM_SA_ID = 2;
	public const uint32 SOCKET_INFO_CONNECTION_SECURED = 1;
	public const uint32 SOCKET_INFO_CONNECTION_ENCRYPTED = 2;
	public const uint32 SOCKET_INFO_CONNECTION_IMPERSONATED = 4;
	public const uint32 SIO_QUERY_WFP_ALE_ENDPOINT_HANDLE = 1476395213;
	public const uint32 SIO_QUERY_RSS_SCALABILITY_INFO = 1476395218;
	public const uint32 IN4ADDR_LOOPBACK = 16777343;
	public const uint32 IN4ADDR_LOOPBACKPREFIX_LENGTH = 8;
	public const uint32 IN4ADDR_LINKLOCALPREFIX_LENGTH = 16;
	public const uint32 IN4ADDR_MULTICASTPREFIX_LENGTH = 4;
	public const uint32 SIO_SET_COMPATIBILITY_MODE = 2550137132;
	public const uint32 RIO_MSG_DONT_NOTIFY = 1;
	public const uint32 RIO_MSG_DEFER = 2;
	public const uint32 RIO_MSG_WAITALL = 4;
	public const uint32 RIO_MSG_COMMIT_ONLY = 8;
	public const uint32 RIO_MAX_CQ_SIZE = 134217728;
	public const uint32 RIO_CORRUPT_CQ = 4294967295;
	public const uint16 AF_UNIX = 1;
	public const uint16 AF_IMPLINK = 3;
	public const uint16 AF_PUP = 4;
	public const uint16 AF_CHAOS = 5;
	public const uint16 AF_NS = 6;
	public const uint16 AF_IPX = 6;
	public const uint16 AF_ISO = 7;
	public const uint16 AF_OSI = 7;
	public const uint16 AF_ECMA = 8;
	public const uint16 AF_DATAKIT = 9;
	public const uint16 AF_CCITT = 10;
	public const uint16 AF_SNA = 11;
	public const uint16 AF_DECnet = 12;
	public const uint16 AF_DLI = 13;
	public const uint16 AF_LAT = 14;
	public const uint16 AF_HYLINK = 15;
	public const uint16 AF_APPLETALK = 16;
	public const uint16 AF_NETBIOS = 17;
	public const uint16 AF_VOICEVIEW = 18;
	public const uint16 AF_FIREFOX = 19;
	public const uint16 AF_UNKNOWN1 = 20;
	public const uint16 AF_BAN = 21;
	public const uint16 AF_ATM = 22;
	public const uint16 AF_CLUSTER = 24;
	public const uint16 AF_12844 = 25;
	public const uint16 AF_IRDA = 26;
	public const uint16 AF_NETDES = 28;
	public const uint16 AF_MAX = 29;
	public const uint16 AF_TCNPROCESS = 29;
	public const uint16 AF_TCNMESSAGE = 30;
	public const uint16 AF_ICLFXBM = 31;
	public const uint16 AF_LINK = 33;
	public const uint16 AF_HYPERV = 34;
	public const uint16 SOCK_STREAM = 1;
	public const uint16 SOCK_DGRAM = 2;
	public const uint16 SOCK_RAW = 3;
	public const uint16 SOCK_RDM = 4;
	public const uint16 SOCK_SEQPACKET = 5;
	public const uint32 SOL_SOCKET = 65535;
	public const uint32 SO_DEBUG = 1;
	public const uint32 SO_ACCEPTCONN = 2;
	public const uint32 SO_REUSEADDR = 4;
	public const uint32 SO_KEEPALIVE = 8;
	public const uint32 SO_DONTROUTE = 16;
	public const uint32 SO_BROADCAST = 32;
	public const uint32 SO_USELOOPBACK = 64;
	public const uint32 SO_LINGER = 128;
	public const uint32 SO_OOBINLINE = 256;
	public const uint32 SO_SNDBUF = 4097;
	public const uint32 SO_RCVBUF = 4098;
	public const uint32 SO_SNDLOWAT = 4099;
	public const uint32 SO_RCVLOWAT = 4100;
	public const uint32 SO_SNDTIMEO = 4101;
	public const uint32 SO_RCVTIMEO = 4102;
	public const uint32 SO_ERROR = 4103;
	public const uint32 SO_TYPE = 4104;
	public const uint32 SO_BSP_STATE = 4105;
	public const uint32 SO_GROUP_ID = 8193;
	public const uint32 SO_GROUP_PRIORITY = 8194;
	public const uint32 SO_MAX_MSG_SIZE = 8195;
	public const uint32 SO_CONDITIONAL_ACCEPT = 12290;
	public const uint32 SO_PAUSE_ACCEPT = 12291;
	public const uint32 SO_COMPARTMENT_ID = 12292;
	public const uint32 SO_RANDOMIZE_PORT = 12293;
	public const uint32 SO_PORT_SCALABILITY = 12294;
	public const uint32 SO_REUSE_UNICASTPORT = 12295;
	public const uint32 SO_REUSE_MULTICASTPORT = 12296;
	public const uint32 SO_ORIGINAL_DST = 12303;
	public const uint32 IP6T_SO_ORIGINAL_DST = 12303;
	public const uint32 WSK_SO_BASE = 16384;
	public const uint32 TCP_NODELAY = 1;
	public const uint32 _SS_MAXSIZE = 128;
	public const uint32 IOC_UNIX = 0;
	public const uint32 IOC_WS2 = 134217728;
	public const uint32 IOC_PROTOCOL = 268435456;
	public const uint32 IOC_VENDOR = 402653184;
	public const uint32 SIO_ASSOCIATE_HANDLE = 2281701377;
	public const uint32 SIO_ENABLE_CIRCULAR_QUEUEING = 671088642;
	public const uint32 SIO_FIND_ROUTE = 1207959555;
	public const uint32 SIO_FLUSH = 671088644;
	public const uint32 SIO_GET_BROADCAST_ADDRESS = 1207959557;
	public const uint32 SIO_GET_EXTENSION_FUNCTION_POINTER = 3355443206;
	public const uint32 SIO_GET_QOS = 3355443207;
	public const uint32 SIO_GET_GROUP_QOS = 3355443208;
	public const uint32 SIO_MULTIPOINT_LOOPBACK = 2281701385;
	public const uint32 SIO_MULTICAST_SCOPE = 2281701386;
	public const uint32 SIO_SET_QOS = 2281701387;
	public const uint32 SIO_SET_GROUP_QOS = 2281701388;
	public const uint32 SIO_TRANSLATE_HANDLE = 3355443213;
	public const uint32 SIO_ROUTING_INTERFACE_QUERY = 3355443220;
	public const uint32 SIO_ROUTING_INTERFACE_CHANGE = 2281701397;
	public const uint32 SIO_ADDRESS_LIST_QUERY = 1207959574;
	public const uint32 SIO_ADDRESS_LIST_CHANGE = 671088663;
	public const uint32 SIO_QUERY_TARGET_PNP_HANDLE = 1207959576;
	public const uint32 SIO_QUERY_RSS_PROCESSOR_INFO = 1207959589;
	public const uint32 SIO_ADDRESS_LIST_SORT = 3355443225;
	public const uint32 SIO_RESERVED_1 = 2281701402;
	public const uint32 SIO_RESERVED_2 = 2281701409;
	public const uint32 SIO_GET_MULTIPLE_EXTENSION_FUNCTION_POINTER = 3355443236;
	public const uint32 IPPROTO_IP = 0;
	public const uint32 IPPORT_TCPMUX = 1;
	public const uint32 IPPORT_ECHO = 7;
	public const uint32 IPPORT_DISCARD = 9;
	public const uint32 IPPORT_SYSTAT = 11;
	public const uint32 IPPORT_DAYTIME = 13;
	public const uint32 IPPORT_NETSTAT = 15;
	public const uint32 IPPORT_QOTD = 17;
	public const uint32 IPPORT_MSP = 18;
	public const uint32 IPPORT_CHARGEN = 19;
	public const uint32 IPPORT_FTP_DATA = 20;
	public const uint32 IPPORT_FTP = 21;
	public const uint32 IPPORT_TELNET = 23;
	public const uint32 IPPORT_SMTP = 25;
	public const uint32 IPPORT_TIMESERVER = 37;
	public const uint32 IPPORT_NAMESERVER = 42;
	public const uint32 IPPORT_WHOIS = 43;
	public const uint32 IPPORT_MTP = 57;
	public const uint32 IPPORT_TFTP = 69;
	public const uint32 IPPORT_RJE = 77;
	public const uint32 IPPORT_FINGER = 79;
	public const uint32 IPPORT_TTYLINK = 87;
	public const uint32 IPPORT_SUPDUP = 95;
	public const uint32 IPPORT_POP3 = 110;
	public const uint32 IPPORT_NTP = 123;
	public const uint32 IPPORT_EPMAP = 135;
	public const uint32 IPPORT_NETBIOS_NS = 137;
	public const uint32 IPPORT_NETBIOS_DGM = 138;
	public const uint32 IPPORT_NETBIOS_SSN = 139;
	public const uint32 IPPORT_IMAP = 143;
	public const uint32 IPPORT_SNMP = 161;
	public const uint32 IPPORT_SNMP_TRAP = 162;
	public const uint32 IPPORT_IMAP3 = 220;
	public const uint32 IPPORT_LDAP = 389;
	public const uint32 IPPORT_HTTPS = 443;
	public const uint32 IPPORT_MICROSOFT_DS = 445;
	public const uint32 IPPORT_EXECSERVER = 512;
	public const uint32 IPPORT_LOGINSERVER = 513;
	public const uint32 IPPORT_CMDSERVER = 514;
	public const uint32 IPPORT_EFSSERVER = 520;
	public const uint32 IPPORT_BIFFUDP = 512;
	public const uint32 IPPORT_WHOSERVER = 513;
	public const uint32 IPPORT_ROUTESERVER = 520;
	public const uint32 IPPORT_RESERVED = 1024;
	public const uint32 IPPORT_REGISTERED_MIN = 1024;
	public const uint32 IPPORT_REGISTERED_MAX = 49151;
	public const uint32 IPPORT_DYNAMIC_MIN = 49152;
	public const uint32 IPPORT_DYNAMIC_MAX = 65535;
	public const uint32 IN_CLASSA_NET = 4278190080;
	public const uint32 IN_CLASSA_NSHIFT = 24;
	public const uint32 IN_CLASSA_HOST = 16777215;
	public const uint32 IN_CLASSA_MAX = 128;
	public const uint32 IN_CLASSB_NET = 4294901760;
	public const uint32 IN_CLASSB_NSHIFT = 16;
	public const uint32 IN_CLASSB_HOST = 65535;
	public const uint32 IN_CLASSB_MAX = 65536;
	public const uint32 IN_CLASSC_NET = 4294967040;
	public const uint32 IN_CLASSC_NSHIFT = 8;
	public const uint32 IN_CLASSC_HOST = 255;
	public const uint32 IN_CLASSD_NET = 4026531840;
	public const uint32 IN_CLASSD_NSHIFT = 28;
	public const uint32 IN_CLASSD_HOST = 268435455;
	public const uint32 INADDR_LOOPBACK = 2130706433;
	public const uint32 INADDR_NONE = 4294967295;
	public const uint32 IOCPARM_MASK = 127;
	public const uint32 IOC_VOID = 536870912;
	public const uint32 IOC_OUT = 1073741824;
	public const uint32 IOC_IN = 2147483648;
	public const uint32 MSG_TRUNC = 256;
	public const uint32 MSG_CTRUNC = 512;
	public const uint32 MSG_BCAST = 1024;
	public const uint32 MSG_MCAST = 2048;
	public const uint32 MSG_ERRQUEUE = 4096;
	public const uint32 AI_PASSIVE = 1;
	public const uint32 AI_CANONNAME = 2;
	public const uint32 AI_NUMERICHOST = 4;
	public const uint32 AI_NUMERICSERV = 8;
	public const uint32 AI_DNS_ONLY = 16;
	public const uint32 AI_FORCE_CLEAR_TEXT = 32;
	public const uint32 AI_BYPASS_DNS_CACHE = 64;
	public const uint32 AI_RETURN_TTL = 128;
	public const uint32 AI_ALL = 256;
	public const uint32 AI_ADDRCONFIG = 1024;
	public const uint32 AI_V4MAPPED = 2048;
	public const uint32 AI_NON_AUTHORITATIVE = 16384;
	public const uint32 AI_SECURE = 32768;
	public const uint32 AI_RETURN_PREFERRED_NAMES = 65536;
	public const uint32 AI_FQDN = 131072;
	public const uint32 AI_FILESERVER = 262144;
	public const uint32 AI_DISABLE_IDN_ENCODING = 524288;
	public const uint32 AI_SECURE_WITH_FALLBACK = 1048576;
	public const uint32 AI_EXCLUSIVE_CUSTOM_SERVERS = 2097152;
	public const uint32 AI_RETURN_RESPONSE_FLAGS = 268435456;
	public const uint32 AI_REQUIRE_SECURE = 536870912;
	public const uint32 AI_RESOLUTION_HANDLE = 1073741824;
	public const uint32 AI_EXTENDED = 2147483648;
	public const uint32 ADDRINFOEX_VERSION_2 = 2;
	public const uint32 ADDRINFOEX_VERSION_3 = 3;
	public const uint32 ADDRINFOEX_VERSION_4 = 4;
	public const uint32 ADDRINFOEX_VERSION_5 = 5;
	public const uint32 ADDRINFOEX_VERSION_6 = 6;
	public const uint32 AI_DNS_SERVER_TYPE_UDP = 1;
	public const uint32 AI_DNS_SERVER_TYPE_DOH = 2;
	public const uint32 AI_DNS_SERVER_UDP_FALLBACK = 1;
	public const uint32 AI_DNS_RESPONSE_SECURE = 1;
	public const uint32 AI_DNS_RESPONSE_HOSTFILE = 2;
	public const uint32 NS_ALL = 0;
	public const uint32 NS_SAP = 1;
	public const uint32 NS_NDS = 2;
	public const uint32 NS_PEER_BROWSE = 3;
	public const uint32 NS_SLP = 5;
	public const uint32 NS_DHCP = 6;
	public const uint32 NS_TCPIP_LOCAL = 10;
	public const uint32 NS_TCPIP_HOSTS = 11;
	public const uint32 NS_DNS = 12;
	public const uint32 NS_NETBT = 13;
	public const uint32 NS_WINS = 14;
	public const uint32 NS_NLA = 15;
	public const uint32 NS_NBP = 20;
	public const uint32 NS_MS = 30;
	public const uint32 NS_STDA = 31;
	public const uint32 NS_NTDS = 32;
	public const uint32 NS_EMAIL = 37;
	public const uint32 NS_X500 = 40;
	public const uint32 NS_NIS = 41;
	public const uint32 NS_NISPLUS = 42;
	public const uint32 NS_WRQ = 50;
	public const uint32 NS_NETDES = 60;
	public const uint32 NI_NOFQDN = 1;
	public const uint32 NI_NUMERICHOST = 2;
	public const uint32 NI_NAMEREQD = 4;
	public const uint32 NI_NUMERICSERV = 8;
	public const uint32 NI_DGRAM = 16;
	public const uint32 NI_MAXHOST = 1025;
	public const uint32 NI_MAXSERV = 32;
	public const uint32 IFF_UP = 1;
	public const uint32 IFF_BROADCAST = 2;
	public const uint32 IFF_LOOPBACK = 4;
	public const uint32 IFF_POINTTOPOINT = 8;
	public const uint32 IFF_MULTICAST = 16;
	public const uint32 IP_OPTIONS = 1;
	public const uint32 IP_HDRINCL = 2;
	public const uint32 IP_TOS = 3;
	public const uint32 IP_TTL = 4;
	public const uint32 IP_MULTICAST_IF = 9;
	public const uint32 IP_MULTICAST_TTL = 10;
	public const uint32 IP_MULTICAST_LOOP = 11;
	public const uint32 IP_ADD_MEMBERSHIP = 12;
	public const uint32 IP_DROP_MEMBERSHIP = 13;
	public const uint32 IP_DONTFRAGMENT = 14;
	public const uint32 IP_ADD_SOURCE_MEMBERSHIP = 15;
	public const uint32 IP_DROP_SOURCE_MEMBERSHIP = 16;
	public const uint32 IP_BLOCK_SOURCE = 17;
	public const uint32 IP_UNBLOCK_SOURCE = 18;
	public const uint32 IP_PKTINFO = 19;
	public const uint32 IP_HOPLIMIT = 21;
	public const uint32 IP_RECVTTL = 21;
	public const uint32 IP_RECEIVE_BROADCAST = 22;
	public const uint32 IP_RECVIF = 24;
	public const uint32 IP_RECVDSTADDR = 25;
	public const uint32 IP_IFLIST = 28;
	public const uint32 IP_ADD_IFLIST = 29;
	public const uint32 IP_DEL_IFLIST = 30;
	public const uint32 IP_UNICAST_IF = 31;
	public const uint32 IP_RTHDR = 32;
	public const uint32 IP_GET_IFLIST = 33;
	public const uint32 IP_RECVRTHDR = 38;
	public const uint32 IP_TCLASS = 39;
	public const uint32 IP_RECVTCLASS = 40;
	public const uint32 IP_RECVTOS = 40;
	public const uint32 IP_ORIGINAL_ARRIVAL_IF = 47;
	public const uint32 IP_ECN = 50;
	public const uint32 IP_RECVECN = 50;
	public const uint32 IP_PKTINFO_EX = 51;
	public const uint32 IP_WFP_REDIRECT_RECORDS = 60;
	public const uint32 IP_WFP_REDIRECT_CONTEXT = 70;
	public const uint32 IP_MTU_DISCOVER = 71;
	public const uint32 IP_MTU = 73;
	public const uint32 IP_NRT_INTERFACE = 74;
	public const uint32 IP_RECVERR = 75;
	public const uint32 IP_USER_MTU = 76;
	public const int32 IP_UNSPECIFIED_TYPE_OF_SERVICE = -1;
	public const uint32 IP_UNSPECIFIED_USER_MTU = 4294967295;
	public const uint32 IN6ADDR_LINKLOCALPREFIX_LENGTH = 64;
	public const uint32 IN6ADDR_MULTICASTPREFIX_LENGTH = 8;
	public const uint32 IN6ADDR_SOLICITEDNODEMULTICASTPREFIX_LENGTH = 104;
	public const uint32 IN6ADDR_V4MAPPEDPREFIX_LENGTH = 96;
	public const uint32 IN6ADDR_6TO4PREFIX_LENGTH = 16;
	public const uint32 IN6ADDR_TEREDOPREFIX_LENGTH = 32;
	public const uint32 MCAST_JOIN_GROUP = 41;
	public const uint32 MCAST_LEAVE_GROUP = 42;
	public const uint32 MCAST_BLOCK_SOURCE = 43;
	public const uint32 MCAST_UNBLOCK_SOURCE = 44;
	public const uint32 MCAST_JOIN_SOURCE_GROUP = 45;
	public const uint32 MCAST_LEAVE_SOURCE_GROUP = 46;
	public const uint32 IPV6_HOPOPTS = 1;
	public const uint32 IPV6_HDRINCL = 2;
	public const uint32 IPV6_UNICAST_HOPS = 4;
	public const uint32 IPV6_MULTICAST_IF = 9;
	public const uint32 IPV6_MULTICAST_HOPS = 10;
	public const uint32 IPV6_MULTICAST_LOOP = 11;
	public const uint32 IPV6_ADD_MEMBERSHIP = 12;
	public const uint32 IPV6_JOIN_GROUP = 12;
	public const uint32 IPV6_DROP_MEMBERSHIP = 13;
	public const uint32 IPV6_LEAVE_GROUP = 13;
	public const uint32 IPV6_DONTFRAG = 14;
	public const uint32 IPV6_PKTINFO = 19;
	public const uint32 IPV6_HOPLIMIT = 21;
	public const uint32 IPV6_PROTECTION_LEVEL = 23;
	public const uint32 IPV6_RECVIF = 24;
	public const uint32 IPV6_RECVDSTADDR = 25;
	public const uint32 IPV6_CHECKSUM = 26;
	public const uint32 IPV6_V6ONLY = 27;
	public const uint32 IPV6_IFLIST = 28;
	public const uint32 IPV6_ADD_IFLIST = 29;
	public const uint32 IPV6_DEL_IFLIST = 30;
	public const uint32 IPV6_UNICAST_IF = 31;
	public const uint32 IPV6_RTHDR = 32;
	public const uint32 IPV6_GET_IFLIST = 33;
	public const uint32 IPV6_RECVRTHDR = 38;
	public const uint32 IPV6_TCLASS = 39;
	public const uint32 IPV6_RECVTCLASS = 40;
	public const uint32 IPV6_ECN = 50;
	public const uint32 IPV6_RECVECN = 50;
	public const uint32 IPV6_PKTINFO_EX = 51;
	public const uint32 IPV6_WFP_REDIRECT_RECORDS = 60;
	public const uint32 IPV6_WFP_REDIRECT_CONTEXT = 70;
	public const uint32 IPV6_MTU_DISCOVER = 71;
	public const uint32 IPV6_MTU = 72;
	public const uint32 IPV6_NRT_INTERFACE = 74;
	public const uint32 IPV6_RECVERR = 75;
	public const uint32 IPV6_USER_MTU = 76;
	public const int32 IP_UNSPECIFIED_HOP_LIMIT = -1;
	public const uint32 IP_PROTECTION_LEVEL = 23;
	public const uint32 PROTECTION_LEVEL_UNRESTRICTED = 10;
	public const uint32 PROTECTION_LEVEL_EDGERESTRICTED = 20;
	public const uint32 PROTECTION_LEVEL_RESTRICTED = 30;
	public const uint32 PROTECTION_LEVEL_DEFAULT = 20;
	public const uint32 INET_ADDRSTRLEN = 22;
	public const uint32 INET6_ADDRSTRLEN = 65;
	public const uint32 TCP_OFFLOAD_NO_PREFERENCE = 0;
	public const uint32 TCP_OFFLOAD_NOT_PREFERRED = 1;
	public const uint32 TCP_OFFLOAD_PREFERRED = 2;
	public const uint32 TCP_EXPEDITED_1122 = 2;
	public const uint32 TCP_KEEPALIVE = 3;
	public const uint32 TCP_MAXSEG = 4;
	public const uint32 TCP_MAXRT = 5;
	public const uint32 TCP_STDURG = 6;
	public const uint32 TCP_NOURG = 7;
	public const uint32 TCP_ATMARK = 8;
	public const uint32 TCP_NOSYNRETRIES = 9;
	public const uint32 TCP_TIMESTAMPS = 10;
	public const uint32 TCP_OFFLOAD_PREFERENCE = 11;
	public const uint32 TCP_CONGESTION_ALGORITHM = 12;
	public const uint32 TCP_DELAY_FIN_ACK = 13;
	public const uint32 TCP_MAXRTMS = 14;
	public const uint32 TCP_FASTOPEN = 15;
	public const uint32 TCP_KEEPCNT = 16;
	public const uint32 TCP_KEEPIDLE = 3;
	public const uint32 TCP_KEEPINTVL = 17;
	public const uint32 TCP_FAIL_CONNECT_ON_ICMP_ERROR = 18;
	public const uint32 TCP_ICMP_ERROR_INFO = 19;
	public const uint32 UDP_SEND_MSG_SIZE = 2;
	public const uint32 UDP_RECV_MAX_COALESCED_SIZE = 3;
	public const uint32 UDP_COALESCED_INFO = 3;
	public const uint32 WINDOWS_AF_IRDA = 26;
	public const uint32 WINDOWS_PF_IRDA = 26;
	public const uint32 WCE_AF_IRDA = 22;
	public const uint32 WCE_PF_IRDA = 22;
	public const uint32 IRDA_PROTO_SOCK_STREAM = 1;
	public const uint16 PF_IRDA = 26;
	public const uint32 SOL_IRLMP = 255;
	public const uint32 IRLMP_ENUMDEVICES = 16;
	public const uint32 IRLMP_IAS_SET = 17;
	public const uint32 IRLMP_IAS_QUERY = 18;
	public const uint32 IRLMP_SEND_PDU_LEN = 19;
	public const uint32 IRLMP_EXCLUSIVE_MODE = 20;
	public const uint32 IRLMP_IRLPT_MODE = 21;
	public const uint32 IRLMP_9WIRE_MODE = 22;
	public const uint32 IRLMP_TINYTP_MODE = 23;
	public const uint32 IRLMP_PARAMETERS = 24;
	public const uint32 IRLMP_DISCOVERY_MODE = 25;
	public const uint32 IRLMP_SHARP_MODE = 32;
	public const uint32 IAS_ATTRIB_NO_CLASS = 16;
	public const uint32 IAS_ATTRIB_NO_ATTRIB = 0;
	public const uint32 IAS_ATTRIB_INT = 1;
	public const uint32 IAS_ATTRIB_OCTETSEQ = 2;
	public const uint32 IAS_ATTRIB_STR = 3;
	public const uint32 IAS_MAX_USER_STRING = 256;
	public const uint32 IAS_MAX_OCTET_STRING = 1024;
	public const uint32 IAS_MAX_CLASSNAME = 64;
	public const uint32 IAS_MAX_ATTRIBNAME = 256;
	public const uint32 LmCharSetASCII = 0;
	public const uint32 LmCharSetISO_8859_1 = 1;
	public const uint32 LmCharSetISO_8859_2 = 2;
	public const uint32 LmCharSetISO_8859_3 = 3;
	public const uint32 LmCharSetISO_8859_4 = 4;
	public const uint32 LmCharSetISO_8859_5 = 5;
	public const uint32 LmCharSetISO_8859_6 = 6;
	public const uint32 LmCharSetISO_8859_7 = 7;
	public const uint32 LmCharSetISO_8859_8 = 8;
	public const uint32 LmCharSetISO_8859_9 = 9;
	public const uint32 LmCharSetUNICODE = 255;
	public const uint32 LM_BAUD_1200 = 1200;
	public const uint32 LM_BAUD_2400 = 2400;
	public const uint32 LM_BAUD_9600 = 9600;
	public const uint32 LM_BAUD_19200 = 19200;
	public const uint32 LM_BAUD_38400 = 38400;
	public const uint32 LM_BAUD_57600 = 57600;
	public const uint32 LM_BAUD_115200 = 115200;
	public const uint32 LM_BAUD_576K = 576000;
	public const uint32 LM_BAUD_1152K = 1152000;
	public const uint32 LM_BAUD_4M = 4000000;
	public const uint32 LM_BAUD_16M = 16000000;
	public const uint32 SO_CONNDATA = 28672;
	public const uint32 SO_CONNOPT = 28673;
	public const uint32 SO_DISCDATA = 28674;
	public const uint32 SO_DISCOPT = 28675;
	public const uint32 SO_CONNDATALEN = 28676;
	public const uint32 SO_CONNOPTLEN = 28677;
	public const uint32 SO_DISCDATALEN = 28678;
	public const uint32 SO_DISCOPTLEN = 28679;
	public const uint32 SO_OPENTYPE = 28680;
	public const uint32 SO_SYNCHRONOUS_ALERT = 16;
	public const uint32 SO_SYNCHRONOUS_NONALERT = 32;
	public const uint32 SO_MAXDG = 28681;
	public const uint32 SO_MAXPATHDG = 28682;
	public const uint32 SO_UPDATE_ACCEPT_CONTEXT = 28683;
	public const uint32 SO_CONNECT_TIME = 28684;
	public const uint32 SO_UPDATE_CONNECT_CONTEXT = 28688;
	public const uint32 TCP_BSDURGENT = 28672;
	public const uint32 SIO_UDP_CONNRESET = 2550136844;
	public const uint32 SIO_SOCKET_CLOSE_NOTIFY = 2550136845;
	public const uint32 SIO_UDP_NETRESET = 2550136847;
	public const uint32 TF_DISCONNECT = 1;
	public const uint32 TF_REUSE_SOCKET = 2;
	public const uint32 TF_WRITE_BEHIND = 4;
	public const uint32 TF_USE_DEFAULT_WORKER = 0;
	public const uint32 TF_USE_SYSTEM_THREAD = 16;
	public const uint32 TF_USE_KERNEL_APC = 32;
	public const uint32 TP_ELEMENT_MEMORY = 1;
	public const uint32 TP_ELEMENT_FILE = 2;
	public const uint32 TP_ELEMENT_EOP = 4;
	public const uint32 TP_DISCONNECT = 1;
	public const uint32 TP_REUSE_SOCKET = 2;
	public const uint32 TP_USE_DEFAULT_WORKER = 0;
	public const uint32 TP_USE_SYSTEM_THREAD = 16;
	public const uint32 TP_USE_KERNEL_APC = 32;
	public const uint32 DE_REUSE_SOCKET = 2;
	public const uint32 NLA_ALLUSERS_NETWORK = 1;
	public const uint32 NLA_FRIENDLY_NAME = 2;
	public const uint32 SIO_BSP_HANDLE = 1207959579;
	public const uint32 SIO_BSP_HANDLE_SELECT = 1207959580;
	public const uint32 SIO_BSP_HANDLE_POLL = 1207959581;
	public const uint32 SIO_BASE_HANDLE = 1207959586;
	public const uint32 SIO_EXT_SELECT = 3355443230;
	public const uint32 SIO_EXT_POLL = 3355443231;
	public const uint32 SIO_EXT_SENDMSG = 3355443232;
	public const uint32 SERVICE_RESOURCE = 1;
	public const uint32 SERVICE_SERVICE = 2;
	public const uint32 SERVICE_LOCAL = 4;
	public const uint32 SERVICE_FLAG_DEFER = 1;
	public const uint32 SERVICE_FLAG_HARD = 2;
	public const uint32 PROP_COMMENT = 1;
	public const uint32 PROP_LOCALE = 2;
	public const uint32 PROP_DISPLAY_HINT = 4;
	public const uint32 PROP_VERSION = 8;
	public const uint32 PROP_START_TIME = 16;
	public const uint32 PROP_MACHINE = 32;
	public const uint32 PROP_ADDRESSES = 256;
	public const uint32 PROP_SD = 512;
	public const uint32 PROP_ALL = 2147483648;
	public const uint32 SERVICE_ADDRESS_FLAG_RPC_CN = 1;
	public const uint32 SERVICE_ADDRESS_FLAG_RPC_DG = 2;
	public const uint32 SERVICE_ADDRESS_FLAG_RPC_NB = 4;
	public const uint32 NS_DEFAULT = 0;
	public const uint32 NS_VNS = 50;
	public const uint32 NSTYPE_HIERARCHICAL = 1;
	public const uint32 NSTYPE_DYNAMIC = 2;
	public const uint32 NSTYPE_ENUMERABLE = 4;
	public const uint32 NSTYPE_WORKGROUP = 8;
	public const uint32 XP_CONNECTIONLESS = 1;
	public const uint32 XP_GUARANTEED_DELIVERY = 2;
	public const uint32 XP_GUARANTEED_ORDER = 4;
	public const uint32 XP_MESSAGE_ORIENTED = 8;
	public const uint32 XP_PSEUDO_STREAM = 16;
	public const uint32 XP_GRACEFUL_CLOSE = 32;
	public const uint32 XP_EXPEDITED_DATA = 64;
	public const uint32 XP_CONNECT_DATA = 128;
	public const uint32 XP_DISCONNECT_DATA = 256;
	public const uint32 XP_SUPPORTS_BROADCAST = 512;
	public const uint32 XP_SUPPORTS_MULTICAST = 1024;
	public const uint32 XP_BANDWIDTH_ALLOCATION = 2048;
	public const uint32 XP_FRAGMENTATION = 4096;
	public const uint32 XP_ENCRYPTS = 8192;
	public const uint32 RES_SOFT_SEARCH = 1;
	public const uint32 RES_FIND_MULTIPLE = 2;
	public const uint32 RES_SERVICE = 4;
	public const String SERVICE_TYPE_VALUE_SAPIDA = "SapId";
	public const String SERVICE_TYPE_VALUE_SAPIDW = "SapId";
	public const String SERVICE_TYPE_VALUE_CONNA = "ConnectionOriented";
	public const String SERVICE_TYPE_VALUE_CONNW = "ConnectionOriented";
	public const String SERVICE_TYPE_VALUE_TCPPORTA = "TcpPort";
	public const String SERVICE_TYPE_VALUE_TCPPORTW = "TcpPort";
	public const String SERVICE_TYPE_VALUE_UDPPORTA = "UdpPort";
	public const String SERVICE_TYPE_VALUE_UDPPORTW = "UdpPort";
	public const String SERVICE_TYPE_VALUE_SAPID = "SapId";
	public const String SERVICE_TYPE_VALUE_CONN = "ConnectionOriented";
	public const String SERVICE_TYPE_VALUE_TCPPORT = "TcpPort";
	public const String SERVICE_TYPE_VALUE_UDPPORT = "UdpPort";
	public const uint32 SET_SERVICE_PARTIAL_SUCCESS = 1;
	public const uint32 FD_SETSIZE = 64;
	public const uint32 IMPLINK_IP = 155;
	public const uint32 IMPLINK_LOWEXPER = 156;
	public const uint32 IMPLINK_HIGHEXPER = 158;
	public const uint32 WSADESCRIPTION_LEN = 256;
	public const uint32 WSASYS_STATUS_LEN = 128;
	public const uint32 IP_DEFAULT_MULTICAST_TTL = 1;
	public const uint32 IP_DEFAULT_MULTICAST_LOOP = 1;
	public const uint32 IP_MAX_MEMBERSHIPS = 20;
	public const int32 SOCKET_ERROR = -1;
	public const uint16 PF_UNIX = 1;
	public const uint16 PF_IMPLINK = 3;
	public const uint16 PF_PUP = 4;
	public const uint16 PF_CHAOS = 5;
	public const uint16 PF_NS = 6;
	public const uint16 PF_IPX = 6;
	public const uint16 PF_ISO = 7;
	public const uint16 PF_OSI = 7;
	public const uint16 PF_ECMA = 8;
	public const uint16 PF_DATAKIT = 9;
	public const uint16 PF_CCITT = 10;
	public const uint16 PF_SNA = 11;
	public const uint16 PF_DECnet = 12;
	public const uint16 PF_DLI = 13;
	public const uint16 PF_LAT = 14;
	public const uint16 PF_HYLINK = 15;
	public const uint16 PF_APPLETALK = 16;
	public const uint16 PF_VOICEVIEW = 18;
	public const uint16 PF_FIREFOX = 19;
	public const uint16 PF_UNKNOWN1 = 20;
	public const uint16 PF_BAN = 21;
	public const uint16 PF_MAX = 29;
	public const uint32 SOMAXCONN = 5;
	public const uint32 MSG_MAXIOVLEN = 16;
	public const uint32 MSG_PARTIAL = 32768;
	public const uint32 MAXGETHOSTSTRUCT = 1024;
	public const uint32 FD_READ = 1;
	public const uint32 FD_WRITE = 2;
	public const uint32 FD_OOB = 4;
	public const uint32 FD_ACCEPT = 8;
	public const uint32 FD_CONNECT = 16;
	public const uint32 FD_CLOSE = 32;
	public const uint32 INCL_WINSOCK_API_PROTOTYPES = 1;
	public const uint32 INCL_WINSOCK_API_TYPEDEFS = 0;
	public const int32 FROM_PROTOCOL_INFO = -1;
	public const uint32 SO_PROTOCOL_INFOA = 8196;
	public const uint32 SO_PROTOCOL_INFOW = 8197;
	public const uint32 SO_PROTOCOL_INFO = 8197;
	public const uint32 PVD_CONFIG = 12289;
	public const uint16 PF_ATM = 22;
	public const uint32 MSG_INTERRUPT = 16;
	public const uint32 FD_READ_BIT = 0;
	public const uint32 FD_WRITE_BIT = 1;
	public const uint32 FD_OOB_BIT = 2;
	public const uint32 FD_ACCEPT_BIT = 3;
	public const uint32 FD_CONNECT_BIT = 4;
	public const uint32 FD_CLOSE_BIT = 5;
	public const uint32 FD_QOS_BIT = 6;
	public const uint32 FD_GROUP_QOS_BIT = 7;
	public const uint32 FD_ROUTING_INTERFACE_CHANGE_BIT = 8;
	public const uint32 FD_ADDRESS_LIST_CHANGE_BIT = 9;
	public const uint32 FD_MAX_EVENTS = 10;
	public const uint32 WSA_MAXIMUM_WAIT_EVENTS = 64;
	public const uint32 WSA_WAIT_FAILED = 4294967295;
	public const uint32 CF_ACCEPT = 0;
	public const uint32 CF_REJECT = 1;
	public const uint32 CF_DEFER = 2;
	public const uint32 SD_RECEIVE = 0;
	public const uint32 SD_SEND = 1;
	public const uint32 SD_BOTH = 2;
	public const uint32 SG_UNCONSTRAINED_GROUP = 1;
	public const uint32 SG_CONSTRAINED_GROUP = 2;
	public const uint32 MAX_PROTOCOL_CHAIN = 7;
	public const uint32 BASE_PROTOCOL = 1;
	public const uint32 LAYERED_PROTOCOL = 0;
	public const uint32 WSAPROTOCOL_LEN = 255;
	public const uint32 PFL_MULTIPLE_PROTO_ENTRIES = 1;
	public const uint32 PFL_RECOMMENDED_PROTO_ENTRY = 2;
	public const uint32 PFL_HIDDEN = 4;
	public const uint32 PFL_MATCHES_PROTOCOL_ZERO = 8;
	public const uint32 PFL_NETWORKDIRECT_PROVIDER = 16;
	public const uint32 XP1_CONNECTIONLESS = 1;
	public const uint32 XP1_GUARANTEED_DELIVERY = 2;
	public const uint32 XP1_GUARANTEED_ORDER = 4;
	public const uint32 XP1_MESSAGE_ORIENTED = 8;
	public const uint32 XP1_PSEUDO_STREAM = 16;
	public const uint32 XP1_GRACEFUL_CLOSE = 32;
	public const uint32 XP1_EXPEDITED_DATA = 64;
	public const uint32 XP1_CONNECT_DATA = 128;
	public const uint32 XP1_DISCONNECT_DATA = 256;
	public const uint32 XP1_SUPPORT_BROADCAST = 512;
	public const uint32 XP1_SUPPORT_MULTIPOINT = 1024;
	public const uint32 XP1_MULTIPOINT_CONTROL_PLANE = 2048;
	public const uint32 XP1_MULTIPOINT_DATA_PLANE = 4096;
	public const uint32 XP1_QOS_SUPPORTED = 8192;
	public const uint32 XP1_INTERRUPT = 16384;
	public const uint32 XP1_UNI_SEND = 32768;
	public const uint32 XP1_UNI_RECV = 65536;
	public const uint32 XP1_IFS_HANDLES = 131072;
	public const uint32 XP1_PARTIAL_MESSAGE = 262144;
	public const uint32 XP1_SAN_SUPPORT_SDP = 524288;
	public const uint32 BIGENDIAN = 0;
	public const uint32 LITTLEENDIAN = 1;
	public const uint32 SECURITY_PROTOCOL_NONE = 0;
	public const uint32 JL_SENDER_ONLY = 1;
	public const uint32 JL_RECEIVER_ONLY = 2;
	public const uint32 JL_BOTH = 4;
	public const uint32 WSA_FLAG_OVERLAPPED = 1;
	public const uint32 WSA_FLAG_MULTIPOINT_C_ROOT = 2;
	public const uint32 WSA_FLAG_MULTIPOINT_C_LEAF = 4;
	public const uint32 WSA_FLAG_MULTIPOINT_D_ROOT = 8;
	public const uint32 WSA_FLAG_MULTIPOINT_D_LEAF = 16;
	public const uint32 WSA_FLAG_ACCESS_SYSTEM_SECURITY = 64;
	public const uint32 WSA_FLAG_NO_HANDLE_INHERIT = 128;
	public const uint32 WSA_FLAG_REGISTERED_IO = 256;
	public const uint32 SIO_NSP_NOTIFY_CHANGE = 2281701401;
	public const uint32 TH_NETDEV = 1;
	public const uint32 TH_TAPI = 2;
	public const uint32 SERVICE_MULTIPLE = 1;
	public const uint32 NS_LOCALNAME = 19;
	public const uint32 RES_UNUSED_1 = 1;
	public const uint32 RES_FLUSH_CACHE = 2;
	public const String SERVICE_TYPE_VALUE_IPXPORTA = "IpxSocket";
	public const String SERVICE_TYPE_VALUE_IPXPORTW = "IpxSocket";
	public const String SERVICE_TYPE_VALUE_OBJECTIDA = "ObjectId";
	public const String SERVICE_TYPE_VALUE_OBJECTIDW = "ObjectId";
	public const String SERVICE_TYPE_VALUE_OBJECTID = "ObjectId";
	public const uint32 LUP_DEEP = 1;
	public const uint32 LUP_CONTAINERS = 2;
	public const uint32 LUP_NOCONTAINERS = 4;
	public const uint32 LUP_NEAREST = 8;
	public const uint32 LUP_RETURN_NAME = 16;
	public const uint32 LUP_RETURN_TYPE = 32;
	public const uint32 LUP_RETURN_VERSION = 64;
	public const uint32 LUP_RETURN_COMMENT = 128;
	public const uint32 LUP_RETURN_ADDR = 256;
	public const uint32 LUP_RETURN_BLOB = 512;
	public const uint32 LUP_RETURN_ALIASES = 1024;
	public const uint32 LUP_RETURN_QUERY_STRING = 2048;
	public const uint32 LUP_RETURN_ALL = 4080;
	public const uint32 LUP_RES_SERVICE = 32768;
	public const uint32 LUP_FLUSHCACHE = 4096;
	public const uint32 LUP_FLUSHPREVIOUS = 8192;
	public const uint32 LUP_NON_AUTHORITATIVE = 16384;
	public const uint32 LUP_SECURE = 32768;
	public const uint32 LUP_RETURN_PREFERRED_NAMES = 65536;
	public const uint32 LUP_DNS_ONLY = 131072;
	public const uint32 LUP_RETURN_RESPONSE_FLAGS = 262144;
	public const uint32 LUP_ADDRCONFIG = 1048576;
	public const uint32 LUP_DUAL_ADDR = 2097152;
	public const uint32 LUP_FILESERVER = 4194304;
	public const uint32 LUP_DISABLE_IDN_ENCODING = 8388608;
	public const uint32 LUP_API_ANSI = 16777216;
	public const uint32 LUP_EXTENDED_QUERYSET = 33554432;
	public const uint32 LUP_SECURE_WITH_FALLBACK = 67108864;
	public const uint32 LUP_EXCLUSIVE_CUSTOM_SERVERS = 134217728;
	public const uint32 LUP_REQUIRE_SECURE = 268435456;
	public const uint32 LUP_RETURN_TTL = 536870912;
	public const uint32 LUP_FORCE_CLEAR_TEXT = 1073741824;
	public const uint32 LUP_RESOLUTION_HANDLE = 2147483648;
	public const uint32 RESULT_IS_ALIAS = 1;
	public const uint32 RESULT_IS_ADDED = 16;
	public const uint32 RESULT_IS_CHANGED = 32;
	public const uint32 RESULT_IS_DELETED = 64;
	public const uint16 POLLRDNORM = 256;
	public const uint16 POLLRDBAND = 512;
	public const uint16 POLLPRI = 1024;
	public const uint16 POLLWRNORM = 16;
	public const uint16 POLLOUT = 16;
	public const uint16 POLLWRBAND = 32;
	public const uint16 POLLERR = 1;
	public const uint16 POLLHUP = 2;
	public const uint16 POLLNVAL = 4;
	public const uint32 SOCK_NOTIFY_REGISTER_EVENT_NONE = 0;
	public const uint32 SOCK_NOTIFY_REGISTER_EVENT_IN = 1;
	public const uint32 SOCK_NOTIFY_REGISTER_EVENT_OUT = 2;
	public const uint32 SOCK_NOTIFY_REGISTER_EVENT_HANGUP = 4;
	public const uint32 SOCK_NOTIFY_EVENT_IN = 1;
	public const uint32 SOCK_NOTIFY_EVENT_OUT = 2;
	public const uint32 SOCK_NOTIFY_EVENT_HANGUP = 4;
	public const uint32 SOCK_NOTIFY_EVENT_ERR = 64;
	public const uint32 SOCK_NOTIFY_EVENT_REMOVE = 128;
	public const uint32 SOCK_NOTIFY_OP_NONE = 0;
	public const uint32 SOCK_NOTIFY_OP_ENABLE = 1;
	public const uint32 SOCK_NOTIFY_OP_DISABLE = 2;
	public const uint32 SOCK_NOTIFY_OP_REMOVE = 4;
	public const uint32 SOCK_NOTIFY_TRIGGER_ONESHOT = 1;
	public const uint32 SOCK_NOTIFY_TRIGGER_PERSISTENT = 2;
	public const uint32 SOCK_NOTIFY_TRIGGER_LEVEL = 4;
	public const uint32 SOCK_NOTIFY_TRIGGER_EDGE = 8;
	public const uint32 ATMPROTO_AALUSER = 0;
	public const uint32 ATMPROTO_AAL1 = 1;
	public const uint32 ATMPROTO_AAL2 = 2;
	public const uint32 ATMPROTO_AAL34 = 3;
	public const uint32 ATMPROTO_AAL5 = 5;
	public const uint32 SAP_FIELD_ABSENT = 4294967294;
	public const uint32 SAP_FIELD_ANY = 4294967295;
	public const uint32 SAP_FIELD_ANY_AESA_SEL = 4294967290;
	public const uint32 SAP_FIELD_ANY_AESA_REST = 4294967291;
	public const uint32 ATM_E164 = 1;
	public const uint32 ATM_NSAP = 2;
	public const uint32 ATM_AESA = 2;
	public const uint32 ATM_ADDR_SIZE = 20;
	public const uint32 BLLI_L2_ISO_1745 = 1;
	public const uint32 BLLI_L2_Q921 = 2;
	public const uint32 BLLI_L2_X25L = 6;
	public const uint32 BLLI_L2_X25M = 7;
	public const uint32 BLLI_L2_ELAPB = 8;
	public const uint32 BLLI_L2_HDLC_ARM = 9;
	public const uint32 BLLI_L2_HDLC_NRM = 10;
	public const uint32 BLLI_L2_HDLC_ABM = 11;
	public const uint32 BLLI_L2_LLC = 12;
	public const uint32 BLLI_L2_X75 = 13;
	public const uint32 BLLI_L2_Q922 = 14;
	public const uint32 BLLI_L2_USER_SPECIFIED = 16;
	public const uint32 BLLI_L2_ISO_7776 = 17;
	public const uint32 BLLI_L3_X25 = 6;
	public const uint32 BLLI_L3_ISO_8208 = 7;
	public const uint32 BLLI_L3_X223 = 8;
	public const uint32 BLLI_L3_SIO_8473 = 9;
	public const uint32 BLLI_L3_T70 = 10;
	public const uint32 BLLI_L3_ISO_TR9577 = 11;
	public const uint32 BLLI_L3_USER_SPECIFIED = 16;
	public const uint32 BLLI_L3_IPI_SNAP = 128;
	public const uint32 BLLI_L3_IPI_IP = 204;
	public const uint32 BHLI_ISO = 0;
	public const uint32 BHLI_UserSpecific = 1;
	public const uint32 BHLI_HighLayerProfile = 2;
	public const uint32 BHLI_VendorSpecificAppId = 3;
	public const uint32 AAL5_MODE_MESSAGE = 1;
	public const uint32 AAL5_MODE_STREAMING = 2;
	public const uint32 AAL5_SSCS_NULL = 0;
	public const uint32 AAL5_SSCS_SSCOP_ASSURED = 1;
	public const uint32 AAL5_SSCS_SSCOP_NON_ASSURED = 2;
	public const uint32 AAL5_SSCS_FRAME_RELAY = 4;
	public const uint32 BCOB_A = 1;
	public const uint32 BCOB_C = 3;
	public const uint32 BCOB_X = 16;
	public const uint32 TT_NOIND = 0;
	public const uint32 TT_CBR = 4;
	public const uint32 TT_VBR = 8;
	public const uint32 TR_NOIND = 0;
	public const uint32 TR_END_TO_END = 1;
	public const uint32 TR_NO_END_TO_END = 2;
	public const uint32 CLIP_NOT = 0;
	public const uint32 CLIP_SUS = 32;
	public const uint32 UP_P2P = 0;
	public const uint32 UP_P2MP = 1;
	public const uint32 BLLI_L2_MODE_NORMAL = 64;
	public const uint32 BLLI_L2_MODE_EXT = 128;
	public const uint32 BLLI_L3_MODE_NORMAL = 64;
	public const uint32 BLLI_L3_MODE_EXT = 128;
	public const uint32 BLLI_L3_PACKET_16 = 4;
	public const uint32 BLLI_L3_PACKET_32 = 5;
	public const uint32 BLLI_L3_PACKET_64 = 6;
	public const uint32 BLLI_L3_PACKET_128 = 7;
	public const uint32 BLLI_L3_PACKET_256 = 8;
	public const uint32 BLLI_L3_PACKET_512 = 9;
	public const uint32 BLLI_L3_PACKET_1024 = 10;
	public const uint32 BLLI_L3_PACKET_2048 = 11;
	public const uint32 BLLI_L3_PACKET_4096 = 12;
	public const uint32 PI_ALLOWED = 0;
	public const uint32 PI_RESTRICTED = 64;
	public const uint32 PI_NUMBER_NOT_AVAILABLE = 128;
	public const uint32 SI_USER_NOT_SCREENED = 0;
	public const uint32 SI_USER_PASSED = 1;
	public const uint32 SI_USER_FAILED = 2;
	public const uint32 SI_NETWORK = 3;
	public const uint32 CAUSE_LOC_USER = 0;
	public const uint32 CAUSE_LOC_PRIVATE_LOCAL = 1;
	public const uint32 CAUSE_LOC_PUBLIC_LOCAL = 2;
	public const uint32 CAUSE_LOC_TRANSIT_NETWORK = 3;
	public const uint32 CAUSE_LOC_PUBLIC_REMOTE = 4;
	public const uint32 CAUSE_LOC_PRIVATE_REMOTE = 5;
	public const uint32 CAUSE_LOC_INTERNATIONAL_NETWORK = 7;
	public const uint32 CAUSE_LOC_BEYOND_INTERWORKING = 10;
	public const uint32 CAUSE_UNALLOCATED_NUMBER = 1;
	public const uint32 CAUSE_NO_ROUTE_TO_TRANSIT_NETWORK = 2;
	public const uint32 CAUSE_NO_ROUTE_TO_DESTINATION = 3;
	public const uint32 CAUSE_VPI_VCI_UNACCEPTABLE = 10;
	public const uint32 CAUSE_NORMAL_CALL_CLEARING = 16;
	public const uint32 CAUSE_USER_BUSY = 17;
	public const uint32 CAUSE_NO_USER_RESPONDING = 18;
	public const uint32 CAUSE_CALL_REJECTED = 21;
	public const uint32 CAUSE_NUMBER_CHANGED = 22;
	public const uint32 CAUSE_USER_REJECTS_CLIR = 23;
	public const uint32 CAUSE_DESTINATION_OUT_OF_ORDER = 27;
	public const uint32 CAUSE_INVALID_NUMBER_FORMAT = 28;
	public const uint32 CAUSE_STATUS_ENQUIRY_RESPONSE = 30;
	public const uint32 CAUSE_NORMAL_UNSPECIFIED = 31;
	public const uint32 CAUSE_VPI_VCI_UNAVAILABLE = 35;
	public const uint32 CAUSE_NETWORK_OUT_OF_ORDER = 38;
	public const uint32 CAUSE_TEMPORARY_FAILURE = 41;
	public const uint32 CAUSE_ACCESS_INFORMAION_DISCARDED = 43;
	public const uint32 CAUSE_NO_VPI_VCI_AVAILABLE = 45;
	public const uint32 CAUSE_RESOURCE_UNAVAILABLE = 47;
	public const uint32 CAUSE_QOS_UNAVAILABLE = 49;
	public const uint32 CAUSE_USER_CELL_RATE_UNAVAILABLE = 51;
	public const uint32 CAUSE_BEARER_CAPABILITY_UNAUTHORIZED = 57;
	public const uint32 CAUSE_BEARER_CAPABILITY_UNAVAILABLE = 58;
	public const uint32 CAUSE_OPTION_UNAVAILABLE = 63;
	public const uint32 CAUSE_BEARER_CAPABILITY_UNIMPLEMENTED = 65;
	public const uint32 CAUSE_UNSUPPORTED_TRAFFIC_PARAMETERS = 73;
	public const uint32 CAUSE_INVALID_CALL_REFERENCE = 81;
	public const uint32 CAUSE_CHANNEL_NONEXISTENT = 82;
	public const uint32 CAUSE_INCOMPATIBLE_DESTINATION = 88;
	public const uint32 CAUSE_INVALID_ENDPOINT_REFERENCE = 89;
	public const uint32 CAUSE_INVALID_TRANSIT_NETWORK_SELECTION = 91;
	public const uint32 CAUSE_TOO_MANY_PENDING_ADD_PARTY = 92;
	public const uint32 CAUSE_AAL_PARAMETERS_UNSUPPORTED = 93;
	public const uint32 CAUSE_MANDATORY_IE_MISSING = 96;
	public const uint32 CAUSE_UNIMPLEMENTED_MESSAGE_TYPE = 97;
	public const uint32 CAUSE_UNIMPLEMENTED_IE = 99;
	public const uint32 CAUSE_INVALID_IE_CONTENTS = 100;
	public const uint32 CAUSE_INVALID_STATE_FOR_MESSAGE = 101;
	public const uint32 CAUSE_RECOVERY_ON_TIMEOUT = 102;
	public const uint32 CAUSE_INCORRECT_MESSAGE_LENGTH = 104;
	public const uint32 CAUSE_PROTOCOL_ERROR = 111;
	public const uint32 CAUSE_COND_UNKNOWN = 0;
	public const uint32 CAUSE_COND_PERMANENT = 1;
	public const uint32 CAUSE_COND_TRANSIENT = 2;
	public const uint32 CAUSE_REASON_USER = 0;
	public const uint32 CAUSE_REASON_IE_MISSING = 4;
	public const uint32 CAUSE_REASON_IE_INSUFFICIENT = 8;
	public const uint32 CAUSE_PU_PROVIDER = 0;
	public const uint32 CAUSE_PU_USER = 8;
	public const uint32 CAUSE_NA_NORMAL = 0;
	public const uint32 CAUSE_NA_ABNORMAL = 4;
	public const uint32 QOS_CLASS0 = 0;
	public const uint32 QOS_CLASS1 = 1;
	public const uint32 QOS_CLASS2 = 2;
	public const uint32 QOS_CLASS3 = 3;
	public const uint32 QOS_CLASS4 = 4;
	public const uint32 TNS_TYPE_NATIONAL = 64;
	public const uint32 TNS_PLAN_CARRIER_ID_CODE = 1;
	public const uint32 SIO_GET_NUMBER_OF_ATM_DEVICES = 1343619073;
	public const uint32 SIO_GET_ATM_ADDRESS = 3491102722;
	public const uint32 SIO_ASSOCIATE_PVC = 2417360899;
	public const uint32 SIO_GET_ATM_CONNECTION_ID = 1343619076;
	public const uint32 WSPDESCRIPTION_LEN = 255;
	public const int32 WSS_OPERATION_IN_PROGRESS = 259;
	public const uint32 LSP_SYSTEM = 2147483648;
	public const uint32 LSP_INSPECTOR = 1;
	public const uint32 LSP_REDIRECTOR = 2;
	public const uint32 LSP_PROXY = 4;
	public const uint32 LSP_FIREWALL = 8;
	public const uint32 LSP_INBOUND_MODIFY = 16;
	public const uint32 LSP_OUTBOUND_MODIFY = 32;
	public const uint32 LSP_CRYPTO_COMPRESS = 64;
	public const uint32 LSP_LOCAL_CACHE = 128;
	public const uint32 UDP_NOCHECKSUM = 1;
	public const uint32 UDP_CHECKSUM_COVERAGE = 20;
	public const uint32 GAI_STRERROR_BUFFER_SIZE = 1024;
	public const uint32 IPX_PTYPE = 16384;
	public const uint32 IPX_FILTERPTYPE = 16385;
	public const uint32 IPX_STOPFILTERPTYPE = 16387;
	public const uint32 IPX_DSTYPE = 16386;
	public const uint32 IPX_EXTENDED_ADDRESS = 16388;
	public const uint32 IPX_RECVHDR = 16389;
	public const uint32 IPX_MAXSIZE = 16390;
	public const uint32 IPX_ADDRESS = 16391;
	public const uint32 IPX_GETNETINFO = 16392;
	public const uint32 IPX_GETNETINFO_NORIP = 16393;
	public const uint32 IPX_SPXGETCONNECTIONSTATUS = 16395;
	public const uint32 IPX_ADDRESS_NOTIFY = 16396;
	public const uint32 IPX_MAX_ADAPTER_NUM = 16397;
	public const uint32 IPX_RERIPNETNUMBER = 16398;
	public const uint32 IPX_RECEIVE_BROADCAST = 16399;
	public const uint32 IPX_IMMEDIATESPXACK = 16400;
	public const uint32 IPPROTO_RM = 113;
	public const uint32 MAX_MCAST_TTL = 255;
	public const uint32 RM_OPTIONSBASE = 1000;
	public const uint32 RM_RATE_WINDOW_SIZE = 1001;
	public const uint32 RM_SET_MESSAGE_BOUNDARY = 1002;
	public const uint32 RM_FLUSHCACHE = 1003;
	public const uint32 RM_SENDER_WINDOW_ADVANCE_METHOD = 1004;
	public const uint32 RM_SENDER_STATISTICS = 1005;
	public const uint32 RM_LATEJOIN = 1006;
	public const uint32 RM_SET_SEND_IF = 1007;
	public const uint32 RM_ADD_RECEIVE_IF = 1008;
	public const uint32 RM_DEL_RECEIVE_IF = 1009;
	public const uint32 RM_SEND_WINDOW_ADV_RATE = 1010;
	public const uint32 RM_USE_FEC = 1011;
	public const uint32 RM_SET_MCAST_TTL = 1012;
	public const uint32 RM_RECEIVER_STATISTICS = 1013;
	public const uint32 RM_HIGH_SPEED_INTRANET_OPT = 1014;
	public const uint32 SENDER_DEFAULT_RATE_KBITS_PER_SEC = 56;
	public const uint32 SENDER_DEFAULT_WINDOW_ADV_PERCENTAGE = 15;
	public const uint32 MAX_WINDOW_INCREMENT_PERCENTAGE = 25;
	public const uint32 SENDER_DEFAULT_LATE_JOINER_PERCENTAGE = 0;
	public const uint32 SENDER_MAX_LATE_JOINER_PERCENTAGE = 75;
	public const uint32 BITS_PER_BYTE = 8;
	public const uint32 LOG2_BITS_PER_BYTE = 3;
	public const uint32 UNIX_PATH_MAX = 108;
	public const uint32 SIO_AF_UNIX_GETPEERPID = 1476395264;
	public const uint32 SIO_AF_UNIX_SETBINDPARENTPATH = 2550137089;
	public const uint32 SIO_AF_UNIX_SETCONNPARENTPATH = 2550137090;
	public const uint32 ISOPROTO_TP0 = 25;
	public const uint32 ISOPROTO_TP1 = 26;
	public const uint32 ISOPROTO_TP2 = 27;
	public const uint32 ISOPROTO_TP3 = 28;
	public const uint32 ISOPROTO_TP4 = 29;
	public const uint32 ISOPROTO_TP = 29;
	public const uint32 ISOPROTO_CLTP = 30;
	public const uint32 ISOPROTO_CLNP = 31;
	public const uint32 ISOPROTO_X25 = 32;
	public const uint32 ISOPROTO_INACT_NL = 33;
	public const uint32 ISOPROTO_ESIS = 34;
	public const uint32 ISOPROTO_INTRAISIS = 35;
	public const uint32 ISO_MAX_ADDR_LENGTH = 64;
	public const uint32 ISO_HIERARCHICAL = 0;
	public const uint32 ISO_NON_HIERARCHICAL = 1;
	public const uint32 ISO_EXP_DATA_USE = 0;
	public const uint32 ISO_EXP_DATA_NUSE = 1;
	public const uint32 NSPROTO_IPX = 1000;
	public const uint32 NSPROTO_SPX = 1256;
	public const uint32 NSPROTO_SPXII = 1257;
	public const uint32 NETBIOS_NAME_LENGTH = 16;
	public const uint32 NETBIOS_UNIQUE_NAME = 0;
	public const uint32 NETBIOS_GROUP_NAME = 1;
	public const uint32 NETBIOS_TYPE_QUICK_UNIQUE = 2;
	public const uint32 NETBIOS_TYPE_QUICK_GROUP = 3;
	public const uint32 VNSPROTO_IPC = 1;
	public const uint32 VNSPROTO_RELIABLE_IPC = 2;
	public const uint32 VNSPROTO_SPP = 3;
	public const uint32 _LITTLE_ENDIAN = 1234;
	public const uint32 _BIG_ENDIAN = 4321;
	public const uint32 _PDP_ENDIAN = 3412;
	public const uint32 BYTE_ORDER = 1234;
	public const uint32 DL_ADDRESS_LENGTH_MAXIMUM = 32;
	public const uint32 DL_HEADER_LENGTH_MAXIMUM = 64;
	public const uint32 SNAP_DSAP = 170;
	public const uint32 SNAP_SSAP = 170;
	public const uint32 SNAP_CONTROL = 3;
	public const uint32 SNAP_OUI = 0;
	public const uint32 ETH_LENGTH_OF_HEADER = 14;
	public const uint32 ETH_LENGTH_OF_VLAN_HEADER = 4;
	public const uint32 ETH_LENGTH_OF_SNAP_HEADER = 8;
	public const uint32 ETHERNET_TYPE_MINIMUM = 1536;
	public const uint32 ETHERNET_TYPE_IPV4 = 2048;
	public const uint32 ETHERNET_TYPE_ARP = 2054;
	public const uint32 ETHERNET_TYPE_IPV6 = 34525;
	public const uint32 ETHERNET_TYPE_802_1Q = 33024;
	public const uint32 ETHERNET_TYPE_802_1AD = 34984;
	public const uint32 IP_VER_MASK = 240;
	public const uint32 IPV4_VERSION = 4;
	public const uint32 MAX_IPV4_PACKET = 65535;
	public const uint32 MAX_IPV4_HLEN = 60;
	public const uint32 IPV4_MINIMUM_MTU = 576;
	public const uint32 IPV4_MIN_MINIMUM_MTU = 352;
	public const uint32 IPV4_MAX_MINIMUM_MTU = 576;
	public const uint32 SIZEOF_IP_OPT_ROUTING_HEADER = 3;
	public const uint32 SIZEOF_IP_OPT_TIMESTAMP_HEADER = 4;
	public const uint32 SIZEOF_IP_OPT_SECURITY = 11;
	public const uint32 SIZEOF_IP_OPT_STREAMIDENTIFIER = 4;
	public const uint32 SIZEOF_IP_OPT_ROUTERALERT = 4;
	public const uint32 IP4_OFF_MASK = 65311;
	public const uint32 ICMPV4_INVALID_PREFERENCE_LEVEL = 2147483648;
	public const uint32 IGMP_QUERY_TYPE = 17;
	public const uint32 IGMP_VERSION1_REPORT_TYPE = 18;
	public const uint32 IGMP_VERSION2_REPORT_TYPE = 22;
	public const uint32 IGMP_LEAVE_GROUP_TYPE = 23;
	public const uint32 IGMP_VERSION3_REPORT_TYPE = 34;
	public const uint32 IPV6_VERSION = 96;
	public const uint32 IPV6_TRAFFIC_CLASS_MASK = 49167;
	public const uint32 IPV6_FULL_TRAFFIC_CLASS_MASK = 61455;
	public const uint32 IPV6_ECN_MASK = 12288;
	public const uint32 IPV6_FLOW_LABEL_MASK = 4294905600;
	public const uint32 MAX_IPV6_PAYLOAD = 65535;
	public const uint32 IPV6_ECN_SHIFT = 12;
	public const uint32 IPV6_MINIMUM_MTU = 1280;
	public const uint32 IP6F_OFF_MASK = 63743;
	public const uint32 IP6F_RESERVED_MASK = 1536;
	public const uint32 IP6F_MORE_FRAG = 256;
	public const uint32 EXT_LEN_UNIT = 8;
	public const uint32 IP6OPT_TYPE_SKIP = 0;
	public const uint32 IP6OPT_TYPE_DISCARD = 64;
	public const uint32 IP6OPT_TYPE_FORCEICMP = 128;
	public const uint32 IP6OPT_TYPE_ICMP = 192;
	public const uint32 IP6OPT_MUTABLE = 32;
	public const uint32 ICMP6_DST_UNREACH_NOROUTE = 0;
	public const uint32 ICMP6_DST_UNREACH_ADMIN = 1;
	public const uint32 ICMP6_DST_UNREACH_BEYONDSCOPE = 2;
	public const uint32 ICMP6_DST_UNREACH_ADDR = 3;
	public const uint32 ICMP6_DST_UNREACH_NOPORT = 4;
	public const uint32 ICMP6_TIME_EXCEED_TRANSIT = 0;
	public const uint32 ICMP6_TIME_EXCEED_REASSEMBLY = 1;
	public const uint32 ICMP6_PARAMPROB_HEADER = 0;
	public const uint32 ICMP6_PARAMPROB_NEXTHEADER = 1;
	public const uint32 ICMP6_PARAMPROB_OPTION = 2;
	public const uint32 ICMPV6_ECHO_REQUEST_FLAG_REVERSE = 1;
	public const uint32 ND_RA_FLAG_MANAGED = 128;
	public const uint32 ND_RA_FLAG_OTHER = 64;
	public const uint32 ND_RA_FLAG_HOME_AGENT = 32;
	public const uint32 ND_RA_FLAG_PREFERENCE = 24;
	public const uint32 ND_NA_FLAG_ROUTER = 2147483648;
	public const uint32 ND_NA_FLAG_SOLICITED = 1073741824;
	public const uint32 ND_NA_FLAG_OVERRIDE = 536870912;
	public const uint32 ND_OPT_PI_FLAG_ONLINK = 128;
	public const uint32 ND_OPT_PI_FLAG_AUTO = 64;
	public const uint32 ND_OPT_PI_FLAG_ROUTER_ADDR = 32;
	public const uint32 ND_OPT_PI_FLAG_SITE_PREFIX = 16;
	public const uint32 ND_OPT_PI_FLAG_ROUTE = 1;
	public const uint32 ND_OPT_RI_FLAG_PREFERENCE = 24;
	public const uint32 ND_OPT_RDNSS_MIN_LEN = 24;
	public const uint32 ND_OPT_DNSSL_MIN_LEN = 16;
	public const uint32 IN6_EMBEDDEDV4_UOCTET_POSITION = 8;
	public const uint32 IN6_EMBEDDEDV4_BITS_IN_BYTE = 8;
	public const uint32 TH_FIN = 1;
	public const uint32 TH_SYN = 2;
	public const uint32 TH_RST = 4;
	public const uint32 TH_PSH = 8;
	public const uint32 TH_ACK = 16;
	public const uint32 TH_URG = 32;
	public const uint32 TH_ECE = 64;
	public const uint32 TH_CWR = 128;
	public const uint32 TH_OPT_EOL = 0;
	public const uint32 TH_OPT_NOP = 1;
	public const uint32 TH_OPT_MSS = 2;
	public const uint32 TH_OPT_WS = 3;
	public const uint32 TH_OPT_SACK_PERMITTED = 4;
	public const uint32 TH_OPT_SACK = 5;
	public const uint32 TH_OPT_TS = 8;
	public const uint32 TH_OPT_FASTOPEN = 34;
	public const SOCKET INVALID_SOCKET = SOCKET.MaxValue;
	public const uint32 WSA_INFINITE = 4294967295;
	public const uint32 IOC_INOUT = 3221225472;
	public const int32 FIONREAD = 1074030207;
	public const int32 FIONBIO = -2147195266;
	public const int32 FIOASYNC = -2147195267;
	public const int32 SIOCSHIWAT = -2147192064;
	public const int32 SIOCGHIWAT = 1074033409;
	public const int32 SIOCSLOWAT = -2147192062;
	public const int32 SIOCGLOWAT = 1074033411;
	public const int32 SIOCATMARK = 1074033415;
	public const uint16 POLLIN = 768;
	public const int32 LM_HB_Extension = 128;
	public const int32 LM_HB1_PnP = 1;
	public const int32 LM_HB1_PDA_Palmtop = 2;
	public const int32 LM_HB1_Computer = 4;
	public const int32 LM_HB1_Printer = 8;
	public const int32 LM_HB1_Modem = 16;
	public const int32 LM_HB1_Fax = 32;
	public const int32 LM_HB1_LANAccess = 64;
	public const int32 LM_HB2_Telephony = 1;
	public const int32 LM_HB2_FileServer = 2;
}
#endregion

#region TypeDefs
typealias HWSAEVENT = int;

typealias SOCKET = uint;

#endregion


#region Enums

[AllowDuplicates]
public enum WSA_ERROR : int32
{
	WSA_IO_PENDING = 997,
	WSA_IO_INCOMPLETE = 996,
	WSA_INVALID_HANDLE = 6,
	WSA_INVALID_PARAMETER = 87,
	WSA_NOT_ENOUGH_MEMORY = 8,
	WSA_OPERATION_ABORTED = 995,
	WSA_WAIT_EVENT_0 = 0,
	WSA_WAIT_IO_COMPLETION = 192,
	WSABASEERR = 10000,
	WSAEINTR = 10004,
	WSAEBADF = 10009,
	WSAEACCES = 10013,
	WSAEFAULT = 10014,
	WSAEINVAL = 10022,
	WSAEMFILE = 10024,
	WSAEWOULDBLOCK = 10035,
	WSAEINPROGRESS = 10036,
	WSAEALREADY = 10037,
	WSAENOTSOCK = 10038,
	WSAEDESTADDRREQ = 10039,
	WSAEMSGSIZE = 10040,
	WSAEPROTOTYPE = 10041,
	WSAENOPROTOOPT = 10042,
	WSAEPROTONOSUPPORT = 10043,
	WSAESOCKTNOSUPPORT = 10044,
	WSAEOPNOTSUPP = 10045,
	WSAEPFNOSUPPORT = 10046,
	WSAEAFNOSUPPORT = 10047,
	WSAEADDRINUSE = 10048,
	WSAEADDRNOTAVAIL = 10049,
	WSAENETDOWN = 10050,
	WSAENETUNREACH = 10051,
	WSAENETRESET = 10052,
	WSAECONNABORTED = 10053,
	WSAECONNRESET = 10054,
	WSAENOBUFS = 10055,
	WSAEISCONN = 10056,
	WSAENOTCONN = 10057,
	WSAESHUTDOWN = 10058,
	WSAETOOMANYREFS = 10059,
	WSAETIMEDOUT = 10060,
	WSAECONNREFUSED = 10061,
	WSAELOOP = 10062,
	WSAENAMETOOLONG = 10063,
	WSAEHOSTDOWN = 10064,
	WSAEHOSTUNREACH = 10065,
	WSAENOTEMPTY = 10066,
	WSAEPROCLIM = 10067,
	WSAEUSERS = 10068,
	WSAEDQUOT = 10069,
	WSAESTALE = 10070,
	WSAEREMOTE = 10071,
	WSASYSNOTREADY = 10091,
	WSAVERNOTSUPPORTED = 10092,
	WSANOTINITIALISED = 10093,
	WSAEDISCON = 10101,
	WSAENOMORE = 10102,
	WSAECANCELLED = 10103,
	WSAEINVALIDPROCTABLE = 10104,
	WSAEINVALIDPROVIDER = 10105,
	WSAEPROVIDERFAILEDINIT = 10106,
	WSASYSCALLFAILURE = 10107,
	WSASERVICE_NOT_FOUND = 10108,
	WSATYPE_NOT_FOUND = 10109,
	WSA_E_NO_MORE = 10110,
	WSA_E_CANCELLED = 10111,
	WSAEREFUSED = 10112,
	WSAHOST_NOT_FOUND = 11001,
	WSATRY_AGAIN = 11002,
	WSANO_RECOVERY = 11003,
	WSANO_DATA = 11004,
	WSA_QOS_RECEIVERS = 11005,
	WSA_QOS_SENDERS = 11006,
	WSA_QOS_NO_SENDERS = 11007,
	WSA_QOS_NO_RECEIVERS = 11008,
	WSA_QOS_REQUEST_CONFIRMED = 11009,
	WSA_QOS_ADMISSION_FAILURE = 11010,
	WSA_QOS_POLICY_FAILURE = 11011,
	WSA_QOS_BAD_STYLE = 11012,
	WSA_QOS_BAD_OBJECT = 11013,
	WSA_QOS_TRAFFIC_CTRL_ERROR = 11014,
	WSA_QOS_GENERIC_ERROR = 11015,
	WSA_QOS_ESERVICETYPE = 11016,
	WSA_QOS_EFLOWSPEC = 11017,
	WSA_QOS_EPROVSPECBUF = 11018,
	WSA_QOS_EFILTERSTYLE = 11019,
	WSA_QOS_EFILTERTYPE = 11020,
	WSA_QOS_EFILTERCOUNT = 11021,
	WSA_QOS_EOBJLENGTH = 11022,
	WSA_QOS_EFLOWCOUNT = 11023,
	WSA_QOS_EUNKOWNPSOBJ = 11024,
	WSA_QOS_EPOLICYOBJ = 11025,
	WSA_QOS_EFLOWDESC = 11026,
	WSA_QOS_EPSFLOWSPEC = 11027,
	WSA_QOS_EPSFILTERSPEC = 11028,
	WSA_QOS_ESDMODEOBJ = 11029,
	WSA_QOS_ESHAPERATEOBJ = 11030,
	WSA_QOS_RESERVED_PETYPE = 11031,
	WSA_SECURE_HOST_NOT_FOUND = 11032,
	WSA_IPSEC_NAME_POLICY_ERROR = 11033,
}


[AllowDuplicates]
public enum ADDRESS_FAMILY : uint32
{
	AF_INET = 2,
	AF_INET6 = 23,
	AF_UNSPEC = 0,
}


[AllowDuplicates]
public enum SET_SERVICE_OPERATION : uint32
{
	SERVICE_REGISTER = 1,
	SERVICE_DEREGISTER = 2,
	SERVICE_FLUSH = 3,
	SERVICE_ADD_TYPE = 4,
	SERVICE_DELETE_TYPE = 5,
}


[AllowDuplicates]
public enum SEND_RECV_FLAGS : int32
{
	MSG_OOB = 1,
	MSG_PEEK = 2,
	MSG_DONTROUTE = 4,
	MSG_WAITALL = 8,
	MSG_PUSH_IMMEDIATE = 32,
}


[AllowDuplicates]
public enum RESOURCE_DISPLAY_TYPE : uint32
{
	RESOURCEDISPLAYTYPE_DOMAIN = 1,
	RESOURCEDISPLAYTYPE_FILE = 4,
	RESOURCEDISPLAYTYPE_GENERIC = 0,
	RESOURCEDISPLAYTYPE_GROUP = 5,
	RESOURCEDISPLAYTYPE_SERVER = 2,
	RESOURCEDISPLAYTYPE_SHARE = 3,
	RESOURCEDISPLAYTYPE_TREE = 10,
}


[AllowDuplicates]
public enum IPPROTO : int32
{
	IPPROTO_HOPOPTS = 0,
	IPPROTO_ICMP = 1,
	IPPROTO_IGMP = 2,
	IPPROTO_GGP = 3,
	IPPROTO_IPV4 = 4,
	IPPROTO_ST = 5,
	IPPROTO_TCP = 6,
	IPPROTO_CBT = 7,
	IPPROTO_EGP = 8,
	IPPROTO_IGP = 9,
	IPPROTO_PUP = 12,
	IPPROTO_UDP = 17,
	IPPROTO_IDP = 22,
	IPPROTO_RDP = 27,
	IPPROTO_IPV6 = 41,
	IPPROTO_ROUTING = 43,
	IPPROTO_FRAGMENT = 44,
	IPPROTO_ESP = 50,
	IPPROTO_AH = 51,
	IPPROTO_ICMPV6 = 58,
	IPPROTO_NONE = 59,
	IPPROTO_DSTOPTS = 60,
	IPPROTO_ND = 77,
	IPPROTO_ICLFXBM = 78,
	IPPROTO_PIM = 103,
	IPPROTO_PGM = 113,
	IPPROTO_L2TP = 115,
	IPPROTO_SCTP = 132,
	IPPROTO_RAW = 255,
	IPPROTO_MAX = 256,
	IPPROTO_RESERVED_RAW = 257,
	IPPROTO_RESERVED_IPSEC = 258,
	IPPROTO_RESERVED_IPSECOFFLOAD = 259,
	IPPROTO_RESERVED_WNV = 260,
	IPPROTO_RESERVED_MAX = 261,
}


[AllowDuplicates]
public enum SCOPE_LEVEL : int32
{
	ScopeLevelInterface = 1,
	ScopeLevelLink = 2,
	ScopeLevelSubnet = 3,
	ScopeLevelAdmin = 4,
	ScopeLevelSite = 5,
	ScopeLevelOrganization = 8,
	ScopeLevelGlobal = 14,
	ScopeLevelCount = 16,
}


[AllowDuplicates]
public enum WSACOMPLETIONTYPE : int32
{
	NSP_NOTIFY_IMMEDIATELY = 0,
	NSP_NOTIFY_HWND = 1,
	NSP_NOTIFY_EVENT = 2,
	NSP_NOTIFY_PORT = 3,
	NSP_NOTIFY_APC = 4,
}


[AllowDuplicates]
public enum WSAECOMPARATOR : int32
{
	COMP_EQUAL = 0,
	COMP_NOTLESS = 1,
}


[AllowDuplicates]
public enum WSAESETSERVICEOP : int32
{
	RNRSERVICE_REGISTER = 0,
	RNRSERVICE_DEREGISTER = 1,
	RNRSERVICE_DELETE = 2,
}


[AllowDuplicates]
public enum PMTUD_STATE : int32
{
	IP_PMTUDISC_NOT_SET = 0,
	IP_PMTUDISC_DO = 1,
	IP_PMTUDISC_DONT = 2,
	IP_PMTUDISC_PROBE = 3,
	IP_PMTUDISC_MAX = 4,
}


[AllowDuplicates]
public enum MULTICAST_MODE_TYPE : int32
{
	MCAST_INCLUDE = 0,
	MCAST_EXCLUDE = 1,
}


[AllowDuplicates]
public enum eWINDOW_ADVANCE_METHOD : int32
{
	E_WINDOW_ADVANCE_BY_TIME = 1,
	E_WINDOW_USE_AS_DATA_CACHE = 2,
}


[AllowDuplicates]
public enum NL_PREFIX_ORIGIN : int32
{
	IpPrefixOriginOther = 0,
	IpPrefixOriginManual = 1,
	IpPrefixOriginWellKnown = 2,
	IpPrefixOriginDhcp = 3,
	IpPrefixOriginRouterAdvertisement = 4,
	IpPrefixOriginUnchanged = 16,
}


[AllowDuplicates]
public enum NL_SUFFIX_ORIGIN : int32
{
	NlsoOther = 0,
	NlsoManual = 1,
	NlsoWellKnown = 2,
	NlsoDhcp = 3,
	NlsoLinkLayerAddress = 4,
	NlsoRandom = 5,
	IpSuffixOriginOther = 0,
	IpSuffixOriginManual = 1,
	IpSuffixOriginWellKnown = 2,
	IpSuffixOriginDhcp = 3,
	IpSuffixOriginLinkLayerAddress = 4,
	IpSuffixOriginRandom = 5,
	IpSuffixOriginUnchanged = 16,
}


[AllowDuplicates]
public enum NL_DAD_STATE : int32
{
	NldsInvalid = 0,
	NldsTentative = 1,
	NldsDuplicate = 2,
	NldsDeprecated = 3,
	NldsPreferred = 4,
	IpDadStateInvalid = 0,
	IpDadStateTentative = 1,
	IpDadStateDuplicate = 2,
	IpDadStateDeprecated = 3,
	IpDadStatePreferred = 4,
}


[AllowDuplicates]
public enum NL_ROUTE_PROTOCOL : int32
{
	RouteProtocolOther = 1,
	RouteProtocolLocal = 2,
	RouteProtocolNetMgmt = 3,
	RouteProtocolIcmp = 4,
	RouteProtocolEgp = 5,
	RouteProtocolGgp = 6,
	RouteProtocolHello = 7,
	RouteProtocolRip = 8,
	RouteProtocolIsIs = 9,
	RouteProtocolEsIs = 10,
	RouteProtocolCisco = 11,
	RouteProtocolBbn = 12,
	RouteProtocolOspf = 13,
	RouteProtocolBgp = 14,
	RouteProtocolIdpr = 15,
	RouteProtocolEigrp = 16,
	RouteProtocolDvmrp = 17,
	RouteProtocolRpl = 18,
	RouteProtocolDhcp = 19,
	MIB_IPPROTO_OTHER = 1,
	PROTO_IP_OTHER = 1,
	MIB_IPPROTO_LOCAL = 2,
	PROTO_IP_LOCAL = 2,
	MIB_IPPROTO_NETMGMT = 3,
	PROTO_IP_NETMGMT = 3,
	MIB_IPPROTO_ICMP = 4,
	PROTO_IP_ICMP = 4,
	MIB_IPPROTO_EGP = 5,
	PROTO_IP_EGP = 5,
	MIB_IPPROTO_GGP = 6,
	PROTO_IP_GGP = 6,
	MIB_IPPROTO_HELLO = 7,
	PROTO_IP_HELLO = 7,
	MIB_IPPROTO_RIP = 8,
	PROTO_IP_RIP = 8,
	MIB_IPPROTO_IS_IS = 9,
	PROTO_IP_IS_IS = 9,
	MIB_IPPROTO_ES_IS = 10,
	PROTO_IP_ES_IS = 10,
	MIB_IPPROTO_CISCO = 11,
	PROTO_IP_CISCO = 11,
	MIB_IPPROTO_BBN = 12,
	PROTO_IP_BBN = 12,
	MIB_IPPROTO_OSPF = 13,
	PROTO_IP_OSPF = 13,
	MIB_IPPROTO_BGP = 14,
	PROTO_IP_BGP = 14,
	MIB_IPPROTO_IDPR = 15,
	PROTO_IP_IDPR = 15,
	MIB_IPPROTO_EIGRP = 16,
	PROTO_IP_EIGRP = 16,
	MIB_IPPROTO_DVMRP = 17,
	PROTO_IP_DVMRP = 17,
	MIB_IPPROTO_RPL = 18,
	PROTO_IP_RPL = 18,
	MIB_IPPROTO_DHCP = 19,
	PROTO_IP_DHCP = 19,
	MIB_IPPROTO_NT_AUTOSTATIC = 10002,
	PROTO_IP_NT_AUTOSTATIC = 10002,
	MIB_IPPROTO_NT_STATIC = 10006,
	PROTO_IP_NT_STATIC = 10006,
	MIB_IPPROTO_NT_STATIC_NON_DOD = 10007,
	PROTO_IP_NT_STATIC_NON_DOD = 10007,
}


[AllowDuplicates]
public enum NL_ADDRESS_TYPE : int32
{
	NlatUnspecified = 0,
	NlatUnicast = 1,
	NlatAnycast = 2,
	NlatMulticast = 3,
	NlatBroadcast = 4,
	NlatInvalid = 5,
}


[AllowDuplicates]
public enum NL_ROUTE_ORIGIN : int32
{
	NlroManual = 0,
	NlroWellKnown = 1,
	NlroDHCP = 2,
	NlroRouterAdvertisement = 3,
	Nlro6to4 = 4,
}


[AllowDuplicates]
public enum NL_NEIGHBOR_STATE : int32
{
	NlnsUnreachable = 0,
	NlnsIncomplete = 1,
	NlnsProbe = 2,
	NlnsDelay = 3,
	NlnsStale = 4,
	NlnsReachable = 5,
	NlnsPermanent = 6,
	NlnsMaximum = 7,
}


[AllowDuplicates]
public enum NL_LINK_LOCAL_ADDRESS_BEHAVIOR : int32
{
	LinkLocalAlwaysOff = 0,
	LinkLocalDelayed = 1,
	LinkLocalAlwaysOn = 2,
	LinkLocalUnchanged = -1,
}


[AllowDuplicates]
public enum NL_ROUTER_DISCOVERY_BEHAVIOR : int32
{
	RouterDiscoveryDisabled = 0,
	RouterDiscoveryEnabled = 1,
	RouterDiscoveryDhcp = 2,
	RouterDiscoveryUnchanged = -1,
}


[AllowDuplicates]
public enum NL_BANDWIDTH_FLAG : int32
{
	NlbwDisabled = 0,
	NlbwEnabled = 1,
	NlbwUnchanged = -1,
}


[AllowDuplicates]
public enum NL_NETWORK_CATEGORY : int32
{
	NetworkCategoryPublic = 0,
	NetworkCategoryPrivate = 1,
	NetworkCategoryDomainAuthenticated = 2,
	NetworkCategoryUnchanged = -1,
	NetworkCategoryUnknown = -1,
}


[AllowDuplicates]
public enum NL_INTERFACE_NETWORK_CATEGORY_STATE : int32
{
	NlincCategoryUnknown = 0,
	NlincPublic = 1,
	NlincPrivate = 2,
	NlincDomainAuthenticated = 3,
	NlincCategoryStateMax = 4,
}


[AllowDuplicates]
public enum NL_NETWORK_CONNECTIVITY_LEVEL_HINT : int32
{
	NetworkConnectivityLevelHintUnknown = 0,
	NetworkConnectivityLevelHintNone = 1,
	NetworkConnectivityLevelHintLocalAccess = 2,
	NetworkConnectivityLevelHintInternetAccess = 3,
	NetworkConnectivityLevelHintConstrainedInternetAccess = 4,
	NetworkConnectivityLevelHintHidden = 5,
}


[AllowDuplicates]
public enum NL_NETWORK_CONNECTIVITY_COST_HINT : int32
{
	NetworkConnectivityCostHintUnknown = 0,
	NetworkConnectivityCostHintUnrestricted = 1,
	NetworkConnectivityCostHintFixed = 2,
	NetworkConnectivityCostHintVariable = 3,
}


[AllowDuplicates]
public enum TCPSTATE : int32
{
	TCPSTATE_CLOSED = 0,
	TCPSTATE_LISTEN = 1,
	TCPSTATE_SYN_SENT = 2,
	TCPSTATE_SYN_RCVD = 3,
	TCPSTATE_ESTABLISHED = 4,
	TCPSTATE_FIN_WAIT_1 = 5,
	TCPSTATE_FIN_WAIT_2 = 6,
	TCPSTATE_CLOSE_WAIT = 7,
	TCPSTATE_CLOSING = 8,
	TCPSTATE_LAST_ACK = 9,
	TCPSTATE_TIME_WAIT = 10,
	TCPSTATE_MAX = 11,
}


[AllowDuplicates]
public enum CONTROL_CHANNEL_TRIGGER_STATUS : int32
{
	CONTROL_CHANNEL_TRIGGER_STATUS_INVALID = 0,
	CONTROL_CHANNEL_TRIGGER_STATUS_SOFTWARE_SLOT_ALLOCATED = 1,
	CONTROL_CHANNEL_TRIGGER_STATUS_HARDWARE_SLOT_ALLOCATED = 2,
	CONTROL_CHANNEL_TRIGGER_STATUS_POLICY_ERROR = 3,
	CONTROL_CHANNEL_TRIGGER_STATUS_SYSTEM_ERROR = 4,
	CONTROL_CHANNEL_TRIGGER_STATUS_TRANSPORT_DISCONNECTED = 5,
	CONTROL_CHANNEL_TRIGGER_STATUS_SERVICE_UNAVAILABLE = 6,
}


[AllowDuplicates]
public enum SOCKET_PRIORITY_HINT : int32
{
	SocketPriorityHintVeryLow = 0,
	SocketPriorityHintLow = 1,
	SocketPriorityHintNormal = 2,
	SocketMaximumPriorityHintType = 3,
}


[AllowDuplicates]
public enum RCVALL_VALUE : int32
{
	RCVALL_OFF = 0,
	RCVALL_ON = 1,
	RCVALL_SOCKETLEVELONLY = 2,
	RCVALL_IPLEVEL = 3,
}


[AllowDuplicates]
public enum TCP_ICW_LEVEL : int32
{
	TCP_ICW_LEVEL_DEFAULT = 0,
	TCP_ICW_LEVEL_HIGH = 1,
	TCP_ICW_LEVEL_VERY_HIGH = 2,
	TCP_ICW_LEVEL_AGGRESSIVE = 3,
	TCP_ICW_LEVEL_EXPERIMENTAL = 4,
	TCP_ICW_LEVEL_COMPAT = 254,
	TCP_ICW_LEVEL_MAX = 255,
}


[AllowDuplicates]
public enum SOCKET_USAGE_TYPE : int32
{
	SYSTEM_CRITICAL_SOCKET = 1,
}


[AllowDuplicates]
public enum SOCKET_SECURITY_PROTOCOL : int32
{
	SOCKET_SECURITY_PROTOCOL_DEFAULT = 0,
	SOCKET_SECURITY_PROTOCOL_IPSEC = 1,
	SOCKET_SECURITY_PROTOCOL_IPSEC2 = 2,
	SOCKET_SECURITY_PROTOCOL_INVALID = 3,
}


[AllowDuplicates]
public enum WSA_COMPATIBILITY_BEHAVIOR_ID : int32
{
	WsaBehaviorAll = 0,
	WsaBehaviorReceiveBuffering = 1,
	WsaBehaviorAutoTuning = 2,
}


[AllowDuplicates]
public enum Q2931_IE_TYPE : int32
{
	IE_AALParameters = 0,
	IE_TrafficDescriptor = 1,
	IE_BroadbandBearerCapability = 2,
	IE_BHLI = 3,
	IE_BLLI = 4,
	IE_CalledPartyNumber = 5,
	IE_CalledPartySubaddress = 6,
	IE_CallingPartyNumber = 7,
	IE_CallingPartySubaddress = 8,
	IE_Cause = 9,
	IE_QOSClass = 10,
	IE_TransitNetworkSelection = 11,
}


[AllowDuplicates]
public enum AAL_TYPE : int32
{
	AALTYPE_5 = 5,
	AALTYPE_USER = 16,
}


[AllowDuplicates]
public enum NAPI_PROVIDER_TYPE : int32
{
	ProviderType_Application = 1,
	ProviderType_Service = 2,
}


[AllowDuplicates]
public enum NAPI_PROVIDER_LEVEL : int32
{
	ProviderLevel_None = 0,
	ProviderLevel_Secondary = 1,
	ProviderLevel_Primary = 2,
}


[AllowDuplicates]
public enum NLA_BLOB_DATA_TYPE : int32
{
	NLA_RAW_DATA = 0,
	NLA_INTERFACE = 1,
	NLA_802_1X_LOCATION = 2,
	NLA_CONNECTIVITY = 3,
	NLA_ICS = 4,
}


[AllowDuplicates]
public enum NLA_CONNECTIVITY_TYPE : int32
{
	NLA_NETWORK_AD_HOC = 0,
	NLA_NETWORK_MANAGED = 1,
	NLA_NETWORK_UNMANAGED = 2,
	NLA_NETWORK_UNKNOWN = 3,
}


[AllowDuplicates]
public enum NLA_INTERNET : int32
{
	NLA_INTERNET_UNKNOWN = 0,
	NLA_INTERNET_NO = 1,
	NLA_INTERNET_YES = 2,
}


[AllowDuplicates]
public enum RIO_NOTIFICATION_COMPLETION_TYPE : int32
{
	RIO_EVENT_COMPLETION = 1,
	RIO_IOCP_COMPLETION = 2,
}


[AllowDuplicates]
public enum WSC_PROVIDER_INFO_TYPE : int32
{
	ProviderInfoLspCategories = 0,
	ProviderInfoAudit = 1,
}


[AllowDuplicates]
public enum IPV4_OPTION_TYPE : int32
{
	IP_OPT_EOL = 0,
	IP_OPT_NOP = 1,
	IP_OPT_SECURITY = 130,
	IP_OPT_LSRR = 131,
	IP_OPT_TS = 68,
	IP_OPT_RR = 7,
	IP_OPT_SSRR = 137,
	IP_OPT_SID = 136,
	IP_OPT_ROUTER_ALERT = 148,
	IP_OPT_MULTIDEST = 149,
}


[AllowDuplicates]
public enum IP_OPTION_TIMESTAMP_FLAGS : int32
{
	IP_OPTION_TIMESTAMP_ONLY = 0,
	IP_OPTION_TIMESTAMP_ADDRESS = 1,
	IP_OPTION_TIMESTAMP_SPECIFIC_ADDRESS = 3,
}


[AllowDuplicates]
public enum ICMP4_UNREACH_CODE : int32
{
	ICMP4_UNREACH_NET = 0,
	ICMP4_UNREACH_HOST = 1,
	ICMP4_UNREACH_PROTOCOL = 2,
	ICMP4_UNREACH_PORT = 3,
	ICMP4_UNREACH_FRAG_NEEDED = 4,
	ICMP4_UNREACH_SOURCEROUTE_FAILED = 5,
	ICMP4_UNREACH_NET_UNKNOWN = 6,
	ICMP4_UNREACH_HOST_UNKNOWN = 7,
	ICMP4_UNREACH_ISOLATED = 8,
	ICMP4_UNREACH_NET_ADMIN = 9,
	ICMP4_UNREACH_HOST_ADMIN = 10,
	ICMP4_UNREACH_NET_TOS = 11,
	ICMP4_UNREACH_HOST_TOS = 12,
	ICMP4_UNREACH_ADMIN = 13,
}


[AllowDuplicates]
public enum ICMP4_TIME_EXCEED_CODE : int32
{
	ICMP4_TIME_EXCEED_TRANSIT = 0,
	ICMP4_TIME_EXCEED_REASSEMBLY = 1,
}


[AllowDuplicates]
public enum ARP_OPCODE : int32
{
	ARP_REQUEST = 1,
	ARP_RESPONSE = 2,
}


[AllowDuplicates]
public enum ARP_HARDWARE_TYPE : int32
{
	ARP_HW_ENET = 1,
	ARP_HW_802 = 6,
}


[AllowDuplicates]
public enum IGMP_MAX_RESP_CODE_TYPE : int32
{
	IGMP_MAX_RESP_CODE_TYPE_NORMAL = 0,
	IGMP_MAX_RESP_CODE_TYPE_FLOAT = 1,
}


[AllowDuplicates]
public enum IPV6_OPTION_TYPE : int32
{
	IP6OPT_PAD1 = 0,
	IP6OPT_PADN = 1,
	IP6OPT_TUNNEL_LIMIT = 4,
	IP6OPT_ROUTER_ALERT = 5,
	IP6OPT_JUMBO = 194,
	IP6OPT_NSAP_ADDR = 195,
}


[AllowDuplicates]
public enum ND_OPTION_TYPE : int32
{
	ND_OPT_SOURCE_LINKADDR = 1,
	ND_OPT_TARGET_LINKADDR = 2,
	ND_OPT_PREFIX_INFORMATION = 3,
	ND_OPT_REDIRECTED_HEADER = 4,
	ND_OPT_MTU = 5,
	ND_OPT_NBMA_SHORTCUT_LIMIT = 6,
	ND_OPT_ADVERTISEMENT_INTERVAL = 7,
	ND_OPT_HOME_AGENT_INFORMATION = 8,
	ND_OPT_SOURCE_ADDR_LIST = 9,
	ND_OPT_TARGET_ADDR_LIST = 10,
	ND_OPT_ROUTE_INFO = 24,
	ND_OPT_RDNSS = 25,
	ND_OPT_DNSSL = 31,
}


[AllowDuplicates]
public enum MLD_MAX_RESP_CODE_TYPE : int32
{
	MLD_MAX_RESP_CODE_TYPE_NORMAL = 0,
	MLD_MAX_RESP_CODE_TYPE_FLOAT = 1,
}


[AllowDuplicates]
public enum TUNNEL_SUB_TYPE : int32
{
	TUNNEL_SUB_TYPE_NONE = 0,
	TUNNEL_SUB_TYPE_CP = 1,
	TUNNEL_SUB_TYPE_IPTLS = 2,
	TUNNEL_SUB_TYPE_HA = 3,
}


[AllowDuplicates]
public enum NPI_MODULEID_TYPE : int32
{
	MIT_GUID = 1,
	MIT_IF_LUID = 2,
}


[AllowDuplicates]
public enum FALLBACK_INDEX : int32
{
	FallbackIndexTcpFastopen = 0,
	FallbackIndexMax = 1,
}

#endregion

#region Function Pointers
public function int32 LPCONDITIONPROC(WSABUF* lpCallerId, WSABUF* lpCallerData, QOS* lpSQOS, QOS* lpGQOS, WSABUF* lpCalleeId, WSABUF* lpCalleeData, uint32* g, uint dwCallbackData);

public function void LPWSAOVERLAPPED_COMPLETION_ROUTINE(uint32 dwError, uint32 cbTransferred, OVERLAPPED* lpOverlapped, uint32 dwFlags);

public function BOOL LPFN_TRANSMITFILE(SOCKET hSocket, HANDLE hFile, uint32 nNumberOfBytesToWrite, uint32 nNumberOfBytesPerSend, OVERLAPPED* lpOverlapped, TRANSMIT_FILE_BUFFERS* lpTransmitBuffers, uint32 dwReserved);

public function BOOL LPFN_ACCEPTEX(SOCKET sListenSocket, SOCKET sAcceptSocket, void* lpOutputBuffer, uint32 dwReceiveDataLength, uint32 dwLocalAddressLength, uint32 dwRemoteAddressLength, uint32* lpdwBytesReceived, OVERLAPPED* lpOverlapped);

public function void LPFN_GETACCEPTEXSOCKADDRS(void* lpOutputBuffer, uint32 dwReceiveDataLength, uint32 dwLocalAddressLength, uint32 dwRemoteAddressLength, SOCKADDR** LocalSockaddr, int32* LocalSockaddrLength, SOCKADDR** RemoteSockaddr, int32* RemoteSockaddrLength);

public function BOOL LPFN_TRANSMITPACKETS(SOCKET hSocket, TRANSMIT_PACKETS_ELEMENT* lpPacketArray, uint32 nElementCount, uint32 nSendSize, OVERLAPPED* lpOverlapped, uint32 dwFlags);

public function BOOL LPFN_CONNECTEX(SOCKET s, SOCKADDR* name, int32 namelen, void* lpSendBuffer, uint32 dwSendDataLength, uint32* lpdwBytesSent, OVERLAPPED* lpOverlapped);

public function BOOL LPFN_DISCONNECTEX(SOCKET s, OVERLAPPED* lpOverlapped, uint32 dwFlags, uint32 dwReserved);

public function int32 LPFN_WSARECVMSG(SOCKET s, WSAMSG* lpMsg, uint32* lpdwNumberOfBytesRecvd, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

public function int32 LPFN_WSASENDMSG(SOCKET s, WSAMSG* lpMsg, uint32 dwFlags, uint32* lpNumberOfBytesSent, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

public function int32 LPFN_WSAPOLL(WSAPOLLFD* fdarray, uint32 nfds, int32 timeout);

public function BOOL LPFN_RIORECEIVE(RIO_RQ_t* SocketQueue, RIO_BUF* pData, uint32 DataBufferCount, uint32 Flags, void* RequestContext);

public function int32 LPFN_RIORECEIVEEX(RIO_RQ_t* SocketQueue, RIO_BUF* pData, uint32 DataBufferCount, RIO_BUF* pLocalAddress, RIO_BUF* pRemoteAddress, RIO_BUF* pControlContext, RIO_BUF* pFlags, uint32 Flags, void* RequestContext);

public function BOOL LPFN_RIOSEND(RIO_RQ_t* SocketQueue, RIO_BUF* pData, uint32 DataBufferCount, uint32 Flags, void* RequestContext);

public function BOOL LPFN_RIOSENDEX(RIO_RQ_t* SocketQueue, RIO_BUF* pData, uint32 DataBufferCount, RIO_BUF* pLocalAddress, RIO_BUF* pRemoteAddress, RIO_BUF* pControlContext, RIO_BUF* pFlags, uint32 Flags, void* RequestContext);

public function void LPFN_RIOCLOSECOMPLETIONQUEUE(RIO_CQ_t* CQ);

public function RIO_CQ_t* LPFN_RIOCREATECOMPLETIONQUEUE(uint32 QueueSize, RIO_NOTIFICATION_COMPLETION* NotificationCompletion);

public function RIO_RQ_t* LPFN_RIOCREATEREQUESTQUEUE(SOCKET Socket, uint32 MaxOutstandingReceive, uint32 MaxReceiveDataBuffers, uint32 MaxOutstandingSend, uint32 MaxSendDataBuffers, RIO_CQ_t* ReceiveCQ, RIO_CQ_t* SendCQ, void* SocketContext);

public function uint32 LPFN_RIODEQUEUECOMPLETION(RIO_CQ_t* CQ, RIORESULT* Array, uint32 ArraySize);

public function void LPFN_RIODEREGISTERBUFFER(RIO_BUFFERID_t* BufferId);

public function int32 LPFN_RIONOTIFY(RIO_CQ_t* CQ);

public function RIO_BUFFERID_t* LPFN_RIOREGISTERBUFFER(PSTR DataBuffer, uint32 DataLength);

public function BOOL LPFN_RIORESIZECOMPLETIONQUEUE(RIO_CQ_t* CQ, uint32 QueueSize);

public function BOOL LPFN_RIORESIZEREQUESTQUEUE(RIO_RQ_t* RQ, uint32 MaxOutstandingReceive, uint32 MaxOutstandingSend);

public function BOOL LPBLOCKINGCALLBACK(uint dwContext);

public function void LPWSAUSERAPC(uint dwContext);

public function SOCKET LPWSPACCEPT(SOCKET s, SOCKADDR* addr, int32* addrlen, LPCONDITIONPROC lpfnCondition, uint dwCallbackData, int32* lpErrno);

public function int32 LPWSPADDRESSTOSTRING(SOCKADDR* lpsaAddress, uint32 dwAddressLength, WSAPROTOCOL_INFOW* lpProtocolInfo, char16* lpszAddressString, uint32* lpdwAddressStringLength, int32* lpErrno);

public function int32 LPWSPASYNCSELECT(SOCKET s, HWND hWnd, uint32 wMsg, int32 lEvent, int32* lpErrno);

public function int32 LPWSPBIND(SOCKET s, SOCKADDR* name, int32 namelen, int32* lpErrno);

public function int32 LPWSPCANCELBLOCKINGCALL(int32* lpErrno);

public function int32 LPWSPCLEANUP(int32* lpErrno);

public function int32 LPWSPCLOSESOCKET(SOCKET s, int32* lpErrno);

public function int32 LPWSPCONNECT(SOCKET s, SOCKADDR* name, int32 namelen, WSABUF* lpCallerData, WSABUF* lpCalleeData, QOS* lpSQOS, QOS* lpGQOS, int32* lpErrno);

public function int32 LPWSPDUPLICATESOCKET(SOCKET s, uint32 dwProcessId, WSAPROTOCOL_INFOW* lpProtocolInfo, int32* lpErrno);

public function int32 LPWSPENUMNETWORKEVENTS(SOCKET s, HANDLE hEventObject, WSANETWORKEVENTS* lpNetworkEvents, int32* lpErrno);

public function int32 LPWSPEVENTSELECT(SOCKET s, HANDLE hEventObject, int32 lNetworkEvents, int32* lpErrno);

public function BOOL LPWSPGETOVERLAPPEDRESULT(SOCKET s, OVERLAPPED* lpOverlapped, uint32* lpcbTransfer, BOOL fWait, uint32* lpdwFlags, int32* lpErrno);

public function int32 LPWSPGETPEERNAME(SOCKET s, SOCKADDR* name, int32* namelen, int32* lpErrno);

public function int32 LPWSPGETSOCKNAME(SOCKET s, SOCKADDR* name, int32* namelen, int32* lpErrno);

public function int32 LPWSPGETSOCKOPT(SOCKET s, int32 level, int32 optname, PSTR optval, int32* optlen, int32* lpErrno);

public function BOOL LPWSPGETQOSBYNAME(SOCKET s, WSABUF* lpQOSName, QOS* lpQOS, int32* lpErrno);

public function int32 LPWSPIOCTL(SOCKET s, uint32 dwIoControlCode, void* lpvInBuffer, uint32 cbInBuffer, void* lpvOutBuffer, uint32 cbOutBuffer, uint32* lpcbBytesReturned, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine, WSATHREADID* lpThreadId, int32* lpErrno);

public function SOCKET LPWSPJOINLEAF(SOCKET s, SOCKADDR* name, int32 namelen, WSABUF* lpCallerData, WSABUF* lpCalleeData, QOS* lpSQOS, QOS* lpGQOS, uint32 dwFlags, int32* lpErrno);

public function int32 LPWSPLISTEN(SOCKET s, int32 backlog, int32* lpErrno);

public function int32 LPWSPRECV(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesRecvd, uint32* lpFlags, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine, WSATHREADID* lpThreadId, int32* lpErrno);

public function int32 LPWSPRECVDISCONNECT(SOCKET s, WSABUF* lpInboundDisconnectData, int32* lpErrno);

public function int32 LPWSPRECVFROM(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesRecvd, uint32* lpFlags, SOCKADDR* lpFrom, int32* lpFromlen, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine, WSATHREADID* lpThreadId, int32* lpErrno);

public function int32 LPWSPSELECT(int32 nfds, FD_SET* readfds, FD_SET* writefds, FD_SET* exceptfds, TIMEVAL* timeout, int32* lpErrno);

public function int32 LPWSPSEND(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesSent, uint32 dwFlags, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine, WSATHREADID* lpThreadId, int32* lpErrno);

public function int32 LPWSPSENDDISCONNECT(SOCKET s, WSABUF* lpOutboundDisconnectData, int32* lpErrno);

public function int32 LPWSPSENDTO(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesSent, uint32 dwFlags, SOCKADDR* lpTo, int32 iTolen, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine, WSATHREADID* lpThreadId, int32* lpErrno);

public function int32 LPWSPSETSOCKOPT(SOCKET s, int32 level, int32 optname, PSTR optval, int32 optlen, int32* lpErrno);

public function int32 LPWSPSHUTDOWN(SOCKET s, int32 how, int32* lpErrno);

public function SOCKET LPWSPSOCKET(int32 af, int32 type, int32 protocol, WSAPROTOCOL_INFOW* lpProtocolInfo, uint32 g, uint32 dwFlags, int32* lpErrno);

public function int32 LPWSPSTRINGTOADDRESS(PWSTR AddressString, int32 AddressFamily, WSAPROTOCOL_INFOW* lpProtocolInfo, SOCKADDR* lpAddress, int32* lpAddressLength, int32* lpErrno);

public function BOOL LPWPUCLOSEEVENT(HANDLE hEvent, int32* lpErrno);

public function int32 LPWPUCLOSESOCKETHANDLE(SOCKET s, int32* lpErrno);

public function HANDLE LPWPUCREATEEVENT(int32* lpErrno);

public function SOCKET LPWPUCREATESOCKETHANDLE(uint32 dwCatalogEntryId, uint dwContext, int32* lpErrno);

public function int32 LPWPUFDISSET(SOCKET s, FD_SET* fdset);

public function int32 LPWPUGETPROVIDERPATH(Guid* lpProviderId, char16* lpszProviderDllPath, int32* lpProviderDllPathLen, int32* lpErrno);

public function SOCKET LPWPUMODIFYIFSHANDLE(uint32 dwCatalogEntryId, SOCKET ProposedHandle, int32* lpErrno);

public function BOOL LPWPUPOSTMESSAGE(HWND hWnd, uint32 Msg, WPARAM wParam, LPARAM lParam);

public function int32 LPWPUQUERYBLOCKINGCALLBACK(uint32 dwCatalogEntryId, LPBLOCKINGCALLBACK* lplpfnCallback, uint* lpdwContext, int32* lpErrno);

public function int32 LPWPUQUERYSOCKETHANDLECONTEXT(SOCKET s, uint* lpContext, int32* lpErrno);

public function int32 LPWPUQUEUEAPC(WSATHREADID* lpThreadId, LPWSAUSERAPC lpfnUserApc, uint dwContext, int32* lpErrno);

public function BOOL LPWPURESETEVENT(HANDLE hEvent, int32* lpErrno);

public function BOOL LPWPUSETEVENT(HANDLE hEvent, int32* lpErrno);

public function int32 LPWPUOPENCURRENTTHREAD(WSATHREADID* lpThreadId, int32* lpErrno);

public function int32 LPWPUCLOSETHREAD(WSATHREADID* lpThreadId, int32* lpErrno);

public function int32 LPWPUCOMPLETEOVERLAPPEDREQUEST(SOCKET s, OVERLAPPED* lpOverlapped, uint32 dwError, uint32 cbTransferred, int32* lpErrno);

public function int32 LPWSPSTARTUP(uint16 wVersionRequested, WSPDATA* lpWSPData, WSAPROTOCOL_INFOW* lpProtocolInfo, WSPUPCALLTABLE UpcallTable, WSPPROC_TABLE* lpProcTable);

public function int32 LPWSCENUMPROTOCOLS(int32* lpiProtocols, WSAPROTOCOL_INFOW* lpProtocolBuffer, uint32* lpdwBufferLength, int32* lpErrno);

public function int32 LPWSCDEINSTALLPROVIDER(Guid* lpProviderId, int32* lpErrno);

public function int32 LPWSCINSTALLPROVIDER(Guid* lpProviderId, PWSTR lpszProviderDllPath, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, int32* lpErrno);

public function int32 LPWSCGETPROVIDERPATH(Guid* lpProviderId, char16* lpszProviderDllPath, int32* lpProviderDllPathLen, int32* lpErrno);

public function int32 LPWSCUPDATEPROVIDER(Guid* lpProviderId, PWSTR lpszProviderDllPath, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, int32* lpErrno);

public function int32 LPWSCINSTALLNAMESPACE(PWSTR lpszIdentifier, PWSTR lpszPathName, uint32 dwNameSpace, uint32 dwVersion, Guid* lpProviderId);

public function int32 LPWSCUNINSTALLNAMESPACE(Guid* lpProviderId);

public function int32 LPWSCENABLENSPROVIDER(Guid* lpProviderId, BOOL fEnable);

public function int32 LPNSPCLEANUP(Guid* lpProviderId);

public function int32 LPNSPLOOKUPSERVICEBEGIN(Guid* lpProviderId, WSAQUERYSETW* lpqsRestrictions, WSASERVICECLASSINFOW* lpServiceClassInfo, uint32 dwControlFlags, HANDLE* lphLookup);

public function int32 LPNSPLOOKUPSERVICENEXT(HANDLE hLookup, uint32 dwControlFlags, uint32* lpdwBufferLength, WSAQUERYSETW* lpqsResults);

public function int32 LPNSPIOCTL(HANDLE hLookup, uint32 dwControlCode, void* lpvInBuffer, uint32 cbInBuffer, void* lpvOutBuffer, uint32 cbOutBuffer, uint32* lpcbBytesReturned, WSACOMPLETION* lpCompletion, WSATHREADID* lpThreadId);

public function int32 LPNSPLOOKUPSERVICEEND(HANDLE hLookup);

public function int32 LPNSPSETSERVICE(Guid* lpProviderId, WSASERVICECLASSINFOW* lpServiceClassInfo, WSAQUERYSETW* lpqsRegInfo, WSAESETSERVICEOP essOperation, uint32 dwControlFlags);

public function int32 LPNSPINSTALLSERVICECLASS(Guid* lpProviderId, WSASERVICECLASSINFOW* lpServiceClassInfo);

public function int32 LPNSPREMOVESERVICECLASS(Guid* lpProviderId, Guid* lpServiceClassId);

public function int32 LPNSPGETSERVICECLASSINFO(Guid* lpProviderId, uint32* lpdwBufSize, WSASERVICECLASSINFOW* lpServiceClassInfo);

public function int32 LPNSPSTARTUP(Guid* lpProviderId, NSP_ROUTINE* lpnspRoutines);

public function int32 LPNSPV2STARTUP(Guid* lpProviderId, void** ppvClientSessionArg);

public function int32 LPNSPV2CLEANUP(Guid* lpProviderId, void* pvClientSessionArg);

public function int32 LPNSPV2LOOKUPSERVICEBEGIN(Guid* lpProviderId, WSAQUERYSET2W* lpqsRestrictions, uint32 dwControlFlags, void* lpvClientSessionArg, HANDLE* lphLookup);

public function void LPNSPV2LOOKUPSERVICENEXTEX(HANDLE hAsyncCall, HANDLE hLookup, uint32 dwControlFlags, uint32* lpdwBufferLength, WSAQUERYSET2W* lpqsResults);

public function int32 LPNSPV2LOOKUPSERVICEEND(HANDLE hLookup);

public function void LPNSPV2SETSERVICEEX(HANDLE hAsyncCall, Guid* lpProviderId, WSAQUERYSET2W* lpqsRegInfo, WSAESETSERVICEOP essOperation, uint32 dwControlFlags, void* lpvClientSessionArg);

public function void LPNSPV2CLIENTSESSIONRUNDOWN(Guid* lpProviderId, void* pvClientSessionArg);

public function uint32 LPFN_NSPAPI();

public function void LPSERVICE_CALLBACK_PROC(LPARAM lParam, HANDLE hAsyncTaskHandle);

public function void LPLOOKUPSERVICE_COMPLETION_ROUTINE(uint32 dwError, uint32 dwBytes, OVERLAPPED* lpOverlapped);

public function int32 LPWSCWRITEPROVIDERORDER(uint32* lpwdCatalogEntryId, uint32 dwNumberOfEntries);

public function int32 LPWSCWRITENAMESPACEORDER(Guid* lpProviderId, uint32 dwNumberOfEntries);

#endregion

#region Structs
[CRepr]
public struct RIO_BUFFERID_t
{
}

[CRepr]
public struct RIO_CQ_t
{
}

[CRepr]
public struct RIO_RQ_t
{
}

[CRepr]
public struct FLOWSPEC
{
	public uint32 TokenRate;
	public uint32 TokenBucketSize;
	public uint32 PeakBandwidth;
	public uint32 Latency;
	public uint32 DelayVariation;
	public uint32 ServiceType;
	public uint32 MaxSduSize;
	public uint32 MinimumPolicedSize;
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SERVENT
{
	public PSTR s_name;
	public int8** s_aliases;
	public PSTR s_proto;
	public int16 s_port;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct WSADATA
{
	public uint16 wVersion;
	public uint16 wHighVersion;
	public uint16 iMaxSockets;
	public uint16 iMaxUdpDg;
	public PSTR lpVendorInfo;
	public CHAR[257] szDescription;
	public CHAR[129] szSystemStatus;
}
#endif

[CRepr]
public struct IN_ADDR
{
	[CRepr, Union]
	public struct _S_un_e__Union
	{
		[CRepr]
		public struct _S_un_w_e__Struct
		{
			public uint16 s_w1;
			public uint16 s_w2;
		}
		[CRepr]
		public struct _S_un_b_e__Struct
		{
			public uint8 s_b1;
			public uint8 s_b2;
			public uint8 s_b3;
			public uint8 s_b4;
		}
		public _S_un_b_e__Struct S_un_b;
		public _S_un_w_e__Struct S_un_w;
		public uint32 S_addr;
	}
	public _S_un_e__Union S_un;
}

[CRepr]
public struct SOCKADDR
{
	public uint16 sa_family;
	public CHAR[14] sa_data;
}

[CRepr]
public struct SOCKET_ADDRESS
{
	public SOCKADDR* lpSockaddr;
	public int32 iSockaddrLength;
}

[CRepr]
public struct SOCKET_ADDRESS_LIST
{
	public int32 iAddressCount;
	public SOCKET_ADDRESS* Address mut => &Address_impl;
	private SOCKET_ADDRESS[ANYSIZE_ARRAY] Address_impl;
}

[CRepr]
public struct CSADDR_INFO
{
	public SOCKET_ADDRESS LocalAddr;
	public SOCKET_ADDRESS RemoteAddr;
	public int32 iSocketType;
	public int32 iProtocol;
}

[CRepr]
public struct SOCKADDR_STORAGE
{
	public uint16 ss_family;
	public CHAR[6] __ss_pad1;
	public int64 __ss_align;
	public CHAR[112] __ss_pad2;
}

[CRepr]
public struct SOCKADDR_STORAGE_XP
{
	public int16 ss_family;
	public CHAR[6] __ss_pad1;
	public int64 __ss_align;
	public CHAR[112] __ss_pad2;
}

[CRepr]
public struct SOCKET_PROCESSOR_AFFINITY
{
	public PROCESSOR_NUMBER Processor;
	public uint16 NumaNodeId;
	public uint16 Reserved;
}

[CRepr]
public struct SCOPE_ID
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 Value;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SOCKADDR_IN
{
	public uint16 sin_family;
	public uint16 sin_port;
	public IN_ADDR sin_addr;
	public CHAR[8] sin_zero;
}

[CRepr]
public struct SOCKADDR_DL
{
	public uint16 sdl_family;
	public uint8[8] sdl_data;
	public uint8[4] sdl_zero;
}

[CRepr]
public struct WSABUF
{
	public uint32 len;
	public PSTR buf;
}

[CRepr]
public struct WSAMSG
{
	public SOCKADDR* name;
	public int32 namelen;
	public WSABUF* lpBuffers;
	public uint32 dwBufferCount;
	public WSABUF Control;
	public uint32 dwFlags;
}

[CRepr]
public struct CMSGHDR
{
	public uint cmsg_len;
	public int32 cmsg_level;
	public int32 cmsg_type;
}

[CRepr]
public struct ADDRINFOA
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public ADDRINFOA* ai_next;
}

[CRepr]
public struct ADDRINFOW
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public ADDRINFOW* ai_next;
}

[CRepr]
public struct ADDRINFOEXA
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEXA* ai_next;
}

[CRepr]
public struct ADDRINFOEXW
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEXW* ai_next;
}

[CRepr]
public struct ADDRINFOEX2A
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEX2A* ai_next;
	public int32 ai_version;
	public PSTR ai_fqdn;
}

[CRepr]
public struct ADDRINFOEX2W
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEX2W* ai_next;
	public int32 ai_version;
	public PWSTR ai_fqdn;
}

[CRepr]
public struct ADDRINFOEX3
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEX3* ai_next;
	public int32 ai_version;
	public PWSTR ai_fqdn;
	public int32 ai_interfaceindex;
}

[CRepr]
public struct ADDRINFOEX4
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEX4* ai_next;
	public int32 ai_version;
	public PWSTR ai_fqdn;
	public int32 ai_interfaceindex;
	public HANDLE ai_resolutionhandle;
}

[CRepr]
public struct ADDRINFOEX5
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEX5* ai_next;
	public int32 ai_version;
	public PWSTR ai_fqdn;
	public int32 ai_interfaceindex;
	public HANDLE ai_resolutionhandle;
	public uint32 ai_ttl;
}

[CRepr]
public struct ADDRINFO_DNS_SERVER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR ai_template;
	}
	public uint32 ai_servertype;
	public uint64 ai_flags;
	public uint32 ai_addrlen;
	public SOCKADDR* ai_addr;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct ADDRINFOEX6
{
	public int32 ai_flags;
	public int32 ai_family;
	public int32 ai_socktype;
	public int32 ai_protocol;
	public uint ai_addrlen;
	public PWSTR ai_canonname;
	public SOCKADDR* ai_addr;
	public void* ai_blob;
	public uint ai_bloblen;
	public Guid* ai_provider;
	public ADDRINFOEX5* ai_next;
	public int32 ai_version;
	public PWSTR ai_fqdn;
	public int32 ai_interfaceindex;
	public HANDLE ai_resolutionhandle;
	public uint32 ai_ttl;
	public uint32 ai_numservers;
	public ADDRINFO_DNS_SERVER* ai_servers;
	public uint64 ai_responseflags;
}

[CRepr]
public struct FD_SET
{
	public uint32 fd_count;
	public SOCKET[64] fd_array;
}

[CRepr]
public struct TIMEVAL
{
	public int32 tv_sec;
	public int32 tv_usec;
}

[CRepr]
public struct HOSTENT
{
	public PSTR h_name;
	public int8** h_aliases;
	public int16 h_addrtype;
	public int16 h_length;
	public int8** h_addr_list;
}

[CRepr]
public struct netent
{
	public PSTR n_name;
	public int8** n_aliases;
	public int16 n_addrtype;
	public uint32 n_net;
}

#if BF_32_BIT
[CRepr]
public struct SERVENT
{
	public PSTR s_name;
	public int8** s_aliases;
	public int16 s_port;
	public PSTR s_proto;
}
#endif

[CRepr]
public struct PROTOENT
{
	public PSTR p_name;
	public int8** p_aliases;
	public int16 p_proto;
}

#if BF_32_BIT
[CRepr]
public struct WSADATA
{
	public uint16 wVersion;
	public uint16 wHighVersion;
	public CHAR[257] szDescription;
	public CHAR[129] szSystemStatus;
	public uint16 iMaxSockets;
	public uint16 iMaxUdpDg;
	public PSTR lpVendorInfo;
}
#endif

[CRepr]
public struct sockproto
{
	public uint16 sp_family;
	public uint16 sp_protocol;
}

[CRepr]
public struct LINGER
{
	public uint16 l_onoff;
	public uint16 l_linger;
}

[CRepr]
public struct QOS
{
	public FLOWSPEC SendingFlowspec;
	public FLOWSPEC ReceivingFlowspec;
	public WSABUF ProviderSpecific;
}

[CRepr]
public struct WSANETWORKEVENTS
{
	public int32 lNetworkEvents;
	public int32[10] iErrorCode;
}

[CRepr]
public struct WSAPROTOCOLCHAIN
{
	public int32 ChainLen;
	public uint32[7] ChainEntries;
}

[CRepr]
public struct WSAPROTOCOL_INFOA
{
	public uint32 dwServiceFlags1;
	public uint32 dwServiceFlags2;
	public uint32 dwServiceFlags3;
	public uint32 dwServiceFlags4;
	public uint32 dwProviderFlags;
	public Guid ProviderId;
	public uint32 dwCatalogEntryId;
	public WSAPROTOCOLCHAIN ProtocolChain;
	public int32 iVersion;
	public int32 iAddressFamily;
	public int32 iMaxSockAddr;
	public int32 iMinSockAddr;
	public int32 iSocketType;
	public int32 iProtocol;
	public int32 iProtocolMaxOffset;
	public int32 iNetworkByteOrder;
	public int32 iSecurityScheme;
	public uint32 dwMessageSize;
	public uint32 dwProviderReserved;
	public CHAR[256] szProtocol;
}

[CRepr]
public struct WSAPROTOCOL_INFOW
{
	public uint32 dwServiceFlags1;
	public uint32 dwServiceFlags2;
	public uint32 dwServiceFlags3;
	public uint32 dwServiceFlags4;
	public uint32 dwProviderFlags;
	public Guid ProviderId;
	public uint32 dwCatalogEntryId;
	public WSAPROTOCOLCHAIN ProtocolChain;
	public int32 iVersion;
	public int32 iAddressFamily;
	public int32 iMaxSockAddr;
	public int32 iMinSockAddr;
	public int32 iSocketType;
	public int32 iProtocol;
	public int32 iProtocolMaxOffset;
	public int32 iNetworkByteOrder;
	public int32 iSecurityScheme;
	public uint32 dwMessageSize;
	public uint32 dwProviderReserved;
	public char16[256] szProtocol;
}

[CRepr]
public struct WSACOMPLETION
{
	[CRepr, Union]
	public struct _Parameters_e__Union
	{
		[CRepr]
		public struct _Port_e__Struct
		{
			public OVERLAPPED* lpOverlapped;
			public HANDLE hPort;
			public uint Key;
		}
		[CRepr]
		public struct _Event_e__Struct
		{
			public OVERLAPPED* lpOverlapped;
		}
		[CRepr]
		public struct _WindowMessage_e__Struct
		{
			public HWND hWnd;
			public uint32 uMsg;
			public WPARAM context;
		}
		[CRepr]
		public struct _Apc_e__Struct
		{
			public OVERLAPPED* lpOverlapped;
			public LPWSAOVERLAPPED_COMPLETION_ROUTINE lpfnCompletionProc;
		}
		public _WindowMessage_e__Struct WindowMessage;
		public _Event_e__Struct Event;
		public _Apc_e__Struct Apc;
		public _Port_e__Struct Port;
	}
	public WSACOMPLETIONTYPE Type;
	public _Parameters_e__Union Parameters;
}

[CRepr]
public struct AFPROTOCOLS
{
	public int32 iAddressFamily;
	public int32 iProtocol;
}

[CRepr]
public struct WSAVERSION
{
	public uint32 dwVersion;
	public WSAECOMPARATOR ecHow;
}

[CRepr]
public struct WSAQUERYSETA
{
	public uint32 dwSize;
	public PSTR lpszServiceInstanceName;
	public Guid* lpServiceClassId;
	public WSAVERSION* lpVersion;
	public PSTR lpszComment;
	public uint32 dwNameSpace;
	public Guid* lpNSProviderId;
	public PSTR lpszContext;
	public uint32 dwNumberOfProtocols;
	public AFPROTOCOLS* lpafpProtocols;
	public PSTR lpszQueryString;
	public uint32 dwNumberOfCsAddrs;
	public CSADDR_INFO* lpcsaBuffer;
	public uint32 dwOutputFlags;
	public BLOB* lpBlob;
}

[CRepr]
public struct WSAQUERYSETW
{
	public uint32 dwSize;
	public PWSTR lpszServiceInstanceName;
	public Guid* lpServiceClassId;
	public WSAVERSION* lpVersion;
	public PWSTR lpszComment;
	public uint32 dwNameSpace;
	public Guid* lpNSProviderId;
	public PWSTR lpszContext;
	public uint32 dwNumberOfProtocols;
	public AFPROTOCOLS* lpafpProtocols;
	public PWSTR lpszQueryString;
	public uint32 dwNumberOfCsAddrs;
	public CSADDR_INFO* lpcsaBuffer;
	public uint32 dwOutputFlags;
	public BLOB* lpBlob;
}

[CRepr]
public struct WSAQUERYSET2A
{
	public uint32 dwSize;
	public PSTR lpszServiceInstanceName;
	public WSAVERSION* lpVersion;
	public PSTR lpszComment;
	public uint32 dwNameSpace;
	public Guid* lpNSProviderId;
	public PSTR lpszContext;
	public uint32 dwNumberOfProtocols;
	public AFPROTOCOLS* lpafpProtocols;
	public PSTR lpszQueryString;
	public uint32 dwNumberOfCsAddrs;
	public CSADDR_INFO* lpcsaBuffer;
	public uint32 dwOutputFlags;
	public BLOB* lpBlob;
}

[CRepr]
public struct WSAQUERYSET2W
{
	public uint32 dwSize;
	public PWSTR lpszServiceInstanceName;
	public WSAVERSION* lpVersion;
	public PWSTR lpszComment;
	public uint32 dwNameSpace;
	public Guid* lpNSProviderId;
	public PWSTR lpszContext;
	public uint32 dwNumberOfProtocols;
	public AFPROTOCOLS* lpafpProtocols;
	public PWSTR lpszQueryString;
	public uint32 dwNumberOfCsAddrs;
	public CSADDR_INFO* lpcsaBuffer;
	public uint32 dwOutputFlags;
	public BLOB* lpBlob;
}

[CRepr]
public struct WSANSCLASSINFOA
{
	public PSTR lpszName;
	public uint32 dwNameSpace;
	public uint32 dwValueType;
	public uint32 dwValueSize;
	public void* lpValue;
}

[CRepr]
public struct WSANSCLASSINFOW
{
	public PWSTR lpszName;
	public uint32 dwNameSpace;
	public uint32 dwValueType;
	public uint32 dwValueSize;
	public void* lpValue;
}

[CRepr]
public struct WSASERVICECLASSINFOA
{
	public Guid* lpServiceClassId;
	public PSTR lpszServiceClassName;
	public uint32 dwCount;
	public WSANSCLASSINFOA* lpClassInfos;
}

[CRepr]
public struct WSASERVICECLASSINFOW
{
	public Guid* lpServiceClassId;
	public PWSTR lpszServiceClassName;
	public uint32 dwCount;
	public WSANSCLASSINFOW* lpClassInfos;
}

[CRepr]
public struct WSANAMESPACE_INFOA
{
	public Guid NSProviderId;
	public uint32 dwNameSpace;
	public BOOL fActive;
	public uint32 dwVersion;
	public PSTR lpszIdentifier;
}

[CRepr]
public struct WSANAMESPACE_INFOW
{
	public Guid NSProviderId;
	public uint32 dwNameSpace;
	public BOOL fActive;
	public uint32 dwVersion;
	public PWSTR lpszIdentifier;
}

[CRepr]
public struct WSANAMESPACE_INFOEXA
{
	public Guid NSProviderId;
	public uint32 dwNameSpace;
	public BOOL fActive;
	public uint32 dwVersion;
	public PSTR lpszIdentifier;
	public BLOB ProviderSpecific;
}

[CRepr]
public struct WSANAMESPACE_INFOEXW
{
	public Guid NSProviderId;
	public uint32 dwNameSpace;
	public BOOL fActive;
	public uint32 dwVersion;
	public PWSTR lpszIdentifier;
	public BLOB ProviderSpecific;
}

[CRepr]
public struct WSAPOLLFD
{
	public SOCKET fd;
	public int16 events;
	public int16 revents;
}

[CRepr]
public struct SOCK_NOTIFY_REGISTRATION
{
	public SOCKET socket;
	public void* completionKey;
	public uint16 eventFilter;
	public uint8 operation;
	public uint8 triggerFlags;
	public uint32 registrationResult;
}

[CRepr]
public struct IN6_ADDR
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public uint8[16] Byte;
		public uint16[8] Word;
	}
	public _u_e__Union u;
}

[CRepr]
public struct sockaddr_in6_old
{
	public int16 sin6_family;
	public uint16 sin6_port;
	public uint32 sin6_flowinfo;
	public IN6_ADDR sin6_addr;
}

[CRepr, Union]
public struct sockaddr_gen
{
	public SOCKADDR Address;
	public SOCKADDR_IN AddressIn;
	public sockaddr_in6_old AddressIn6;
}

[CRepr]
public struct INTERFACE_INFO
{
	public uint32 iiFlags;
	public sockaddr_gen iiAddress;
	public sockaddr_gen iiBroadcastAddress;
	public sockaddr_gen iiNetmask;
}

[CRepr]
public struct INTERFACE_INFO_EX
{
	public uint32 iiFlags;
	public SOCKET_ADDRESS iiAddress;
	public SOCKET_ADDRESS iiBroadcastAddress;
	public SOCKET_ADDRESS iiNetmask;
}

[CRepr]
public struct SOCKADDR_IN6
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 sin6_scope_id;
		public SCOPE_ID sin6_scope_struct;
	}
	public uint16 sin6_family;
	public uint16 sin6_port;
	public uint32 sin6_flowinfo;
	public IN6_ADDR sin6_addr;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SOCKADDR_IN6_W2KSP1
{
	public int16 sin6_family;
	public uint16 sin6_port;
	public uint32 sin6_flowinfo;
	public IN6_ADDR sin6_addr;
	public uint32 sin6_scope_id;
}

[CRepr, Union]
public struct SOCKADDR_INET
{
	public SOCKADDR_IN Ipv4;
	public SOCKADDR_IN6 Ipv6;
	public uint16 si_family;
}

[CRepr]
public struct SOCKADDR_IN6_PAIR
{
	public SOCKADDR_IN6* SourceAddress;
	public SOCKADDR_IN6* DestinationAddress;
}

[CRepr]
public struct IP_MREQ
{
	public IN_ADDR imr_multiaddr;
	public IN_ADDR imr_interface;
}

[CRepr]
public struct IP_MREQ_SOURCE
{
	public IN_ADDR imr_multiaddr;
	public IN_ADDR imr_sourceaddr;
	public IN_ADDR imr_interface;
}

[CRepr]
public struct IP_MSFILTER
{
	public IN_ADDR imsf_multiaddr;
	public IN_ADDR imsf_interface;
	public MULTICAST_MODE_TYPE imsf_fmode;
	public uint32 imsf_numsrc;
	public IN_ADDR* imsf_slist mut => &imsf_slist_impl;
	private IN_ADDR[ANYSIZE_ARRAY] imsf_slist_impl;
}

[CRepr]
public struct IPV6_MREQ
{
	public IN6_ADDR ipv6mr_multiaddr;
	public uint32 ipv6mr_interface;
}

[CRepr]
public struct GROUP_REQ
{
	public uint32 gr_interface;
	public SOCKADDR_STORAGE gr_group;
}

[CRepr]
public struct GROUP_SOURCE_REQ
{
	public uint32 gsr_interface;
	public SOCKADDR_STORAGE gsr_group;
	public SOCKADDR_STORAGE gsr_source;
}

[CRepr]
public struct GROUP_FILTER
{
	public uint32 gf_interface;
	public SOCKADDR_STORAGE gf_group;
	public MULTICAST_MODE_TYPE gf_fmode;
	public uint32 gf_numsrc;
	public SOCKADDR_STORAGE* gf_slist mut => &gf_slist_impl;
	private SOCKADDR_STORAGE[ANYSIZE_ARRAY] gf_slist_impl;
}

[CRepr]
public struct IN_PKTINFO
{
	public IN_ADDR ipi_addr;
	public uint32 ipi_ifindex;
}

[CRepr]
public struct IN6_PKTINFO
{
	public IN6_ADDR ipi6_addr;
	public uint32 ipi6_ifindex;
}

[CRepr]
public struct IN_PKTINFO_EX
{
	public IN_PKTINFO pkt_info;
	public SCOPE_ID scope_id;
}

[CRepr]
public struct IN6_PKTINFO_EX
{
	public IN6_PKTINFO pkt_info;
	public SCOPE_ID scope_id;
}

[CRepr]
public struct IN_RECVERR
{
	public IPPROTO protocol;
	public uint32 info;
	public uint8 type;
	public uint8 code;
}

[CRepr]
public struct ICMP_ERROR_INFO
{
	public SOCKADDR_INET srcaddress;
	public IPPROTO protocol;
	public uint8 type;
	public uint8 code;
}

[CRepr]
public struct RM_SEND_WINDOW
{
	public uint32 RateKbitsPerSec;
	public uint32 WindowSizeInMSecs;
	public uint32 WindowSizeInBytes;
}

[CRepr]
public struct RM_SENDER_STATS
{
	public uint64 DataBytesSent;
	public uint64 TotalBytesSent;
	public uint64 NaksReceived;
	public uint64 NaksReceivedTooLate;
	public uint64 NumOutstandingNaks;
	public uint64 NumNaksAfterRData;
	public uint64 RepairPacketsSent;
	public uint64 BufferSpaceAvailable;
	public uint64 TrailingEdgeSeqId;
	public uint64 LeadingEdgeSeqId;
	public uint64 RateKBitsPerSecOverall;
	public uint64 RateKBitsPerSecLast;
	public uint64 TotalODataPacketsSent;
}

[CRepr]
public struct RM_RECEIVER_STATS
{
	public uint64 NumODataPacketsReceived;
	public uint64 NumRDataPacketsReceived;
	public uint64 NumDuplicateDataPackets;
	public uint64 DataBytesReceived;
	public uint64 TotalBytesReceived;
	public uint64 RateKBitsPerSecOverall;
	public uint64 RateKBitsPerSecLast;
	public uint64 TrailingEdgeSeqId;
	public uint64 LeadingEdgeSeqId;
	public uint64 AverageSequencesInWindow;
	public uint64 MinSequencesInWindow;
	public uint64 MaxSequencesInWindow;
	public uint64 FirstNakSequenceNumber;
	public uint64 NumPendingNaks;
	public uint64 NumOutstandingNaks;
	public uint64 NumDataPacketsBuffered;
	public uint64 TotalSelectiveNaksSent;
	public uint64 TotalParityNaksSent;
}

[CRepr]
public struct RM_FEC_INFO
{
	public uint16 FECBlockSize;
	public uint16 FECProActivePackets;
	public uint8 FECGroupSize;
	public BOOLEAN fFECOnDemandParityEnabled;
}

[CRepr]
public struct IPX_ADDRESS_DATA
{
	public int32 adapternum;
	public uint8[4] netnum;
	public uint8[6] nodenum;
	public BOOLEAN wan;
	public BOOLEAN status;
	public int32 maxpkt;
	public uint32 linkspeed;
}

[CRepr]
public struct IPX_NETNUM_DATA
{
	public uint8[4] netnum;
	public uint16 hopcount;
	public uint16 netdelay;
	public int32 cardnum;
	public uint8[6] router;
}

[CRepr]
public struct IPX_SPXCONNSTATUS_DATA
{
	public uint8 ConnectionState;
	public uint8 WatchDogActive;
	public uint16 LocalConnectionId;
	public uint16 RemoteConnectionId;
	public uint16 LocalSequenceNumber;
	public uint16 LocalAckNumber;
	public uint16 LocalAllocNumber;
	public uint16 RemoteAckNumber;
	public uint16 RemoteAllocNumber;
	public uint16 LocalSocket;
	public uint8[6] ImmediateAddress;
	public uint8[4] RemoteNetwork;
	public uint8[6] RemoteNode;
	public uint16 RemoteSocket;
	public uint16 RetransmissionCount;
	public uint16 EstimatedRoundTripDelay;
	public uint16 RetransmittedPackets;
	public uint16 SuppressedPacket;
}

[CRepr]
public struct LM_IRPARMS
{
	public uint32 nTXDataBytes;
	public uint32 nRXDataBytes;
	public uint32 nBaudRate;
	public uint32 thresholdTime;
	public uint32 discTime;
	public uint16 nMSLinkTurn;
	public uint8 nTXPackets;
	public uint8 nRXPackets;
}

[CRepr]
public struct SOCKADDR_IRDA
{
	public uint16 irdaAddressFamily;
	public uint8[4] irdaDeviceID;
	public CHAR[25] irdaServiceName;
}

[CRepr]
public struct WINDOWS_IRDA_DEVICE_INFO
{
	public uint8[4] irdaDeviceID;
	public CHAR[22] irdaDeviceName;
	public uint8 irdaDeviceHints1;
	public uint8 irdaDeviceHints2;
	public uint8 irdaCharSet;
}

[CRepr]
public struct WCE_IRDA_DEVICE_INFO
{
	public uint8[4] irdaDeviceID;
	public CHAR[22] irdaDeviceName;
	public uint8[2] Reserved;
}

[CRepr]
public struct WINDOWS_DEVICELIST
{
	public uint32 numDevice;
	public WINDOWS_IRDA_DEVICE_INFO* Device mut => &Device_impl;
	private WINDOWS_IRDA_DEVICE_INFO[ANYSIZE_ARRAY] Device_impl;
}

[CRepr]
public struct WCE_DEVICELIST
{
	public uint32 numDevice;
	public WCE_IRDA_DEVICE_INFO* Device mut => &Device_impl;
	private WCE_IRDA_DEVICE_INFO[ANYSIZE_ARRAY] Device_impl;
}

[CRepr]
public struct WINDOWS_IAS_SET
{
	[CRepr, Union]
	public struct _irdaAttribute_e__Union
	{
		[CRepr]
		public struct _irdaAttribOctetSeq_e__Struct
		{
			public uint16 Len;
			public uint8[1024] OctetSeq;
		}
		[CRepr]
		public struct _irdaAttribUsrStr_e__Struct
		{
			public uint8 Len;
			public uint8 CharSet;
			public uint8[256] UsrStr;
		}
		public int32 irdaAttribInt;
		public _irdaAttribOctetSeq_e__Struct irdaAttribOctetSeq;
		public _irdaAttribUsrStr_e__Struct irdaAttribUsrStr;
	}
	public CHAR[64] irdaClassName;
	public CHAR[256] irdaAttribName;
	public uint32 irdaAttribType;
	public _irdaAttribute_e__Union irdaAttribute;
}

[CRepr]
public struct WINDOWS_IAS_QUERY
{
	[CRepr, Union]
	public struct _irdaAttribute_e__Union
	{
		[CRepr]
		public struct _irdaAttribOctetSeq_e__Struct
		{
			public uint32 Len;
			public uint8[1024] OctetSeq;
		}
		[CRepr]
		public struct _irdaAttribUsrStr_e__Struct
		{
			public uint32 Len;
			public uint32 CharSet;
			public uint8[256] UsrStr;
		}
		public int32 irdaAttribInt;
		public _irdaAttribOctetSeq_e__Struct irdaAttribOctetSeq;
		public _irdaAttribUsrStr_e__Struct irdaAttribUsrStr;
	}
	public uint8[4] irdaDeviceID;
	public CHAR[64] irdaClassName;
	public CHAR[256] irdaAttribName;
	public uint32 irdaAttribType;
	public _irdaAttribute_e__Union irdaAttribute;
}

[CRepr]
public struct NL_INTERFACE_OFFLOAD_ROD
{
	public uint8 _bitfield;
}

[CRepr]
public struct NL_PATH_BANDWIDTH_ROD
{
	public uint64 Bandwidth;
	public uint64 Instability;
	public BOOLEAN BandwidthPeaked;
}

[CRepr]
public struct NL_NETWORK_CONNECTIVITY_HINT
{
	public NL_NETWORK_CONNECTIVITY_LEVEL_HINT ConnectivityLevel;
	public NL_NETWORK_CONNECTIVITY_COST_HINT ConnectivityCost;
	public BOOLEAN ApproachingDataLimit;
	public BOOLEAN OverDataLimit;
	public BOOLEAN Roaming;
}

[CRepr]
public struct NL_BANDWIDTH_INFORMATION
{
	public uint64 Bandwidth;
	public uint64 Instability;
	public BOOLEAN BandwidthPeaked;
}

[CRepr]
public struct TRANSPORT_SETTING_ID
{
	public Guid Guid;
}

[CRepr]
public struct tcp_keepalive
{
	public uint32 onoff;
	public uint32 keepalivetime;
	public uint32 keepaliveinterval;
}

[CRepr]
public struct REAL_TIME_NOTIFICATION_SETTING_INPUT
{
	public TRANSPORT_SETTING_ID TransportSettingId;
	public Guid BrokerEventGuid;
}

[CRepr]
public struct REAL_TIME_NOTIFICATION_SETTING_INPUT_EX
{
	public TRANSPORT_SETTING_ID TransportSettingId;
	public Guid BrokerEventGuid;
	public BOOLEAN Unmark;
}

[CRepr]
public struct REAL_TIME_NOTIFICATION_SETTING_OUTPUT
{
	public CONTROL_CHANNEL_TRIGGER_STATUS ChannelStatus;
}

[CRepr]
public struct ASSOCIATE_NAMERES_CONTEXT_INPUT
{
	public TRANSPORT_SETTING_ID TransportSettingId;
	public uint64 Handle;
}

[CRepr]
public struct TIMESTAMPING_CONFIG
{
	public uint32 Flags;
	public uint16 TxTimestampsBuffered;
}

[CRepr]
public struct PRIORITY_STATUS
{
	public SOCKET_PRIORITY_HINT Sender;
	public SOCKET_PRIORITY_HINT Receiver;
}

[CRepr]
public struct RCVALL_IF
{
	public RCVALL_VALUE Mode;
	public uint32 Interface;
}

[CRepr]
public struct TCP_INITIAL_RTO_PARAMETERS
{
	public uint16 Rtt;
	public uint8 MaxSynRetransmissions;
}

[CRepr]
public struct TCP_ICW_PARAMETERS
{
	public TCP_ICW_LEVEL Level;
}

[CRepr]
public struct TCP_ACK_FREQUENCY_PARAMETERS
{
	public uint8 TcpDelayedAckFrequency;
}

[CRepr]
public struct TCP_INFO_v0
{
	public TCPSTATE State;
	public uint32 Mss;
	public uint64 ConnectionTimeMs;
	public BOOLEAN TimestampsEnabled;
	public uint32 RttUs;
	public uint32 MinRttUs;
	public uint32 BytesInFlight;
	public uint32 Cwnd;
	public uint32 SndWnd;
	public uint32 RcvWnd;
	public uint32 RcvBuf;
	public uint64 BytesOut;
	public uint64 BytesIn;
	public uint32 BytesReordered;
	public uint32 BytesRetrans;
	public uint32 FastRetrans;
	public uint32 DupAcksIn;
	public uint32 TimeoutEpisodes;
	public uint8 SynRetrans;
}

[CRepr]
public struct TCP_INFO_v1
{
	public TCPSTATE State;
	public uint32 Mss;
	public uint64 ConnectionTimeMs;
	public BOOLEAN TimestampsEnabled;
	public uint32 RttUs;
	public uint32 MinRttUs;
	public uint32 BytesInFlight;
	public uint32 Cwnd;
	public uint32 SndWnd;
	public uint32 RcvWnd;
	public uint32 RcvBuf;
	public uint64 BytesOut;
	public uint64 BytesIn;
	public uint32 BytesReordered;
	public uint32 BytesRetrans;
	public uint32 FastRetrans;
	public uint32 DupAcksIn;
	public uint32 TimeoutEpisodes;
	public uint8 SynRetrans;
	public uint32 SndLimTransRwin;
	public uint32 SndLimTimeRwin;
	public uint64 SndLimBytesRwin;
	public uint32 SndLimTransCwnd;
	public uint32 SndLimTimeCwnd;
	public uint64 SndLimBytesCwnd;
	public uint32 SndLimTransSnd;
	public uint32 SndLimTimeSnd;
	public uint64 SndLimBytesSnd;
}

[CRepr]
public struct INET_PORT_RANGE
{
	public uint16 StartPort;
	public uint16 NumberOfPorts;
}

[CRepr]
public struct INET_PORT_RESERVATION_TOKEN
{
	public uint64 Token;
}

[CRepr]
public struct INET_PORT_RESERVATION_INSTANCE
{
	public INET_PORT_RANGE Reservation;
	public INET_PORT_RESERVATION_TOKEN Token;
}

[CRepr]
public struct INET_PORT_RESERVATION_INFORMATION
{
	public uint32 OwningPid;
}

[CRepr]
public struct SOCKET_SECURITY_SETTINGS
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public uint32 SecurityFlags;
}

[CRepr]
public struct SOCKET_SECURITY_SETTINGS_IPSEC
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public uint32 SecurityFlags;
	public uint32 IpsecFlags;
	public Guid AuthipMMPolicyKey;
	public Guid AuthipQMPolicyKey;
	public Guid Reserved;
	public uint64 Reserved2;
	public uint32 UserNameStringLen;
	public uint32 DomainNameStringLen;
	public uint32 PasswordStringLen;
	public char16* AllStrings mut => &AllStrings_impl;
	private char16[ANYSIZE_ARRAY] AllStrings_impl;
}

[CRepr]
public struct SOCKET_PEER_TARGET_NAME
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public SOCKADDR_STORAGE PeerAddress;
	public uint32 PeerTargetNameStringLen;
	public char16* AllStrings mut => &AllStrings_impl;
	private char16[ANYSIZE_ARRAY] AllStrings_impl;
}

[CRepr]
public struct SOCKET_SECURITY_QUERY_TEMPLATE
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public SOCKADDR_STORAGE PeerAddress;
	public uint32 PeerTokenAccessMask;
}

[CRepr]
public struct SOCKET_SECURITY_QUERY_TEMPLATE_IPSEC2
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public SOCKADDR_STORAGE PeerAddress;
	public uint32 PeerTokenAccessMask;
	public uint32 Flags;
	public uint32 FieldMask;
}

[CRepr]
public struct SOCKET_SECURITY_QUERY_INFO
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public uint32 Flags;
	public uint64 PeerApplicationAccessTokenHandle;
	public uint64 PeerMachineAccessTokenHandle;
}

[CRepr]
public struct SOCKET_SECURITY_QUERY_INFO_IPSEC2
{
	public SOCKET_SECURITY_PROTOCOL SecurityProtocol;
	public uint32 Flags;
	public uint64 PeerApplicationAccessTokenHandle;
	public uint64 PeerMachineAccessTokenHandle;
	public uint64 MmSaId;
	public uint64 QmSaId;
	public uint32 NegotiationWinerr;
	public Guid SaLookupContext;
}

[CRepr]
public struct RSS_SCALABILITY_INFO
{
	public BOOLEAN RssEnabled;
}

[CRepr]
public struct WSA_COMPATIBILITY_MODE
{
	public WSA_COMPATIBILITY_BEHAVIOR_ID BehaviorId;
	public uint32 TargetOsVersion;
}

[CRepr]
public struct RIORESULT
{
	public int32 Status;
	public uint32 BytesTransferred;
	public uint64 SocketContext;
	public uint64 RequestContext;
}

[CRepr]
public struct RIO_BUF
{
	public RIO_BUFFERID_t* BufferId;
	public uint32 Offset;
	public uint32 Length;
}

[CRepr]
public struct RIO_CMSG_BUFFER
{
	public uint32 TotalLength;
}

[CRepr]
public struct ATM_ADDRESS
{
	public uint32 AddressType;
	public uint32 NumofDigits;
	public uint8[20] Addr;
}

[CRepr]
public struct ATM_BLLI
{
	public uint32 Layer2Protocol;
	public uint32 Layer2UserSpecifiedProtocol;
	public uint32 Layer3Protocol;
	public uint32 Layer3UserSpecifiedProtocol;
	public uint32 Layer3IPI;
	public uint8[5] SnapID;
}

[CRepr]
public struct ATM_BHLI
{
	public uint32 HighLayerInfoType;
	public uint32 HighLayerInfoLength;
	public uint8[8] HighLayerInfo;
}

[CRepr]
public struct SOCKADDR_ATM
{
	public uint16 satm_family;
	public ATM_ADDRESS satm_number;
	public ATM_BLLI satm_blli;
	public ATM_BHLI satm_bhli;
}

[CRepr]
public struct Q2931_IE
{
	public Q2931_IE_TYPE IEType;
	public uint32 IELength;
	public uint8* IE mut => &IE_impl;
	private uint8[ANYSIZE_ARRAY] IE_impl;
}

[CRepr]
public struct AAL5_PARAMETERS
{
	public uint32 ForwardMaxCPCSSDUSize;
	public uint32 BackwardMaxCPCSSDUSize;
	public uint8 Mode;
	public uint8 SSCSType;
}

[CRepr]
public struct AALUSER_PARAMETERS
{
	public uint32 UserDefined;
}

[CRepr]
public struct AAL_PARAMETERS_IE
{
	[CRepr, Union]
	public struct _AALSpecificParameters_e__Union
	{
		public AAL5_PARAMETERS AAL5Parameters;
		public AALUSER_PARAMETERS AALUserParameters;
	}
	public AAL_TYPE AALType;
	public _AALSpecificParameters_e__Union AALSpecificParameters;
}

[CRepr]
public struct ATM_TD
{
	public uint32 PeakCellRate_CLP0;
	public uint32 PeakCellRate_CLP01;
	public uint32 SustainableCellRate_CLP0;
	public uint32 SustainableCellRate_CLP01;
	public uint32 MaxBurstSize_CLP0;
	public uint32 MaxBurstSize_CLP01;
	public BOOL Tagging;
}

[CRepr]
public struct ATM_TRAFFIC_DESCRIPTOR_IE
{
	public ATM_TD Forward;
	public ATM_TD Backward;
	public BOOL BestEffort;
}

[CRepr]
public struct ATM_BROADBAND_BEARER_CAPABILITY_IE
{
	public uint8 BearerClass;
	public uint8 TrafficType;
	public uint8 TimingRequirements;
	public uint8 ClippingSusceptability;
	public uint8 UserPlaneConnectionConfig;
}

[CRepr]
public struct ATM_BLLI_IE
{
	public uint32 Layer2Protocol;
	public uint8 Layer2Mode;
	public uint8 Layer2WindowSize;
	public uint32 Layer2UserSpecifiedProtocol;
	public uint32 Layer3Protocol;
	public uint8 Layer3Mode;
	public uint8 Layer3DefaultPacketSize;
	public uint8 Layer3PacketWindowSize;
	public uint32 Layer3UserSpecifiedProtocol;
	public uint32 Layer3IPI;
	public uint8[5] SnapID;
}

[CRepr]
public struct ATM_CALLING_PARTY_NUMBER_IE
{
	public ATM_ADDRESS ATM_Number;
	public uint8 Presentation_Indication;
	public uint8 Screening_Indicator;
}

[CRepr]
public struct ATM_CAUSE_IE
{
	public uint8 Location;
	public uint8 Cause;
	public uint8 DiagnosticsLength;
	public uint8[4] Diagnostics;
}

[CRepr]
public struct ATM_QOS_CLASS_IE
{
	public uint8 QOSClassForward;
	public uint8 QOSClassBackward;
}

[CRepr]
public struct ATM_TRANSIT_NETWORK_SELECTION_IE
{
	public uint8 TypeOfNetworkId;
	public uint8 NetworkIdPlan;
	public uint8 NetworkIdLength;
	public uint8* NetworkId mut => &NetworkId_impl;
	private uint8[ANYSIZE_ARRAY] NetworkId_impl;
}

[CRepr]
public struct ATM_CONNECTION_ID
{
	public uint32 DeviceNumber;
	public uint32 VPI;
	public uint32 VCI;
}

[CRepr, Packed(4)]
public struct ATM_PVC_PARAMS
{
	public ATM_CONNECTION_ID PvcConnectionId;
	public QOS PvcQos;
}

[CRepr]
public struct NAPI_DOMAIN_DESCRIPTION_BLOB
{
	public uint32 AuthLevel;
	public uint32 cchDomainName;
	public uint32 OffsetNextDomainDescription;
	public uint32 OffsetThisDomainName;
}

[CRepr]
public struct NAPI_PROVIDER_INSTALLATION_BLOB
{
	public uint32 dwVersion;
	public uint32 dwProviderType;
	public uint32 fSupportsWildCard;
	public uint32 cDomains;
	public uint32 OffsetFirstDomain;
}

[CRepr]
public struct TRANSMIT_FILE_BUFFERS
{
	public void* Head;
	public uint32 HeadLength;
	public void* Tail;
	public uint32 TailLength;
}

[CRepr]
public struct TRANSMIT_PACKETS_ELEMENT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public LARGE_INTEGER nFileOffset;
			public HANDLE hFile;
		}
		public using _Anonymous_e__Struct Anonymous;
		public void* pBuffer;
	}
	public uint32 dwElFlags;
	public uint32 cLength;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct NLA_BLOB
{
	[CRepr, Union]
	public struct _data_e__Union
	{
		[CRepr]
		public struct _ICS_e__Struct
		{
			[CRepr]
			public struct _remote_e__Struct
			{
				public uint32 speed;
				public uint32 type;
				public uint32 state;
				public char16[256] machineName;
				public char16[256] sharedAdapterName;
			}
			public _remote_e__Struct remote;
		}
		[CRepr]
		public struct _locationData_e__Struct
		{
			public CHAR* information mut => &information_impl;
			private CHAR[ANYSIZE_ARRAY] information_impl;
		}
		[CRepr]
		public struct _interfaceData_e__Struct
		{
			public uint32 dwType;
			public uint32 dwSpeed;
			public CHAR* adapterName mut => &adapterName_impl;
			private CHAR[ANYSIZE_ARRAY] adapterName_impl;
		}
		[CRepr]
		public struct _connectivity_e__Struct
		{
			public NLA_CONNECTIVITY_TYPE type;
			public NLA_INTERNET internet;
		}
		public CHAR* rawData mut => &rawData_impl;
		private CHAR[ANYSIZE_ARRAY] rawData_impl;
		public _interfaceData_e__Struct interfaceData;
		public _locationData_e__Struct locationData;
		public _connectivity_e__Struct connectivity;
		public _ICS_e__Struct ICS;
	}
	[CRepr]
	public struct _header_e__Struct
	{
		public NLA_BLOB_DATA_TYPE type;
		public uint32 dwSize;
		public uint32 nextOffset;
	}
	public _header_e__Struct header;
	public _data_e__Union data;
}

[CRepr]
public struct WSAPOLLDATA
{
	public int32 result;
	public uint32 fds;
	public int32 timeout;
	public WSAPOLLFD* fdArray mut => &fdArray_impl;
	private WSAPOLLFD[ANYSIZE_ARRAY] fdArray_impl;
}

[CRepr]
public struct WSASENDMSG
{
	public WSAMSG* lpMsg;
	public uint32 dwFlags;
	public uint32* lpNumberOfBytesSent;
	public OVERLAPPED* lpOverlapped;
	public LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine;
}

[CRepr]
public struct RIO_NOTIFICATION_COMPLETION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Iocp_e__Struct
		{
			public HANDLE IocpHandle;
			public void* CompletionKey;
			public void* Overlapped;
		}
		[CRepr]
		public struct _Event_e__Struct
		{
			public HANDLE EventHandle;
			public BOOL NotifyReset;
		}
		public _Event_e__Struct Event;
		public _Iocp_e__Struct Iocp;
	}
	public RIO_NOTIFICATION_COMPLETION_TYPE Type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RIO_EXTENSION_FUNCTION_TABLE
{
	public uint32 cbSize;
	public LPFN_RIORECEIVE RIOReceive;
	public LPFN_RIORECEIVEEX RIOReceiveEx;
	public LPFN_RIOSEND RIOSend;
	public LPFN_RIOSENDEX RIOSendEx;
	public LPFN_RIOCLOSECOMPLETIONQUEUE RIOCloseCompletionQueue;
	public LPFN_RIOCREATECOMPLETIONQUEUE RIOCreateCompletionQueue;
	public LPFN_RIOCREATEREQUESTQUEUE RIOCreateRequestQueue;
	public LPFN_RIODEQUEUECOMPLETION RIODequeueCompletion;
	public LPFN_RIODEREGISTERBUFFER RIODeregisterBuffer;
	public LPFN_RIONOTIFY RIONotify;
	public LPFN_RIOREGISTERBUFFER RIORegisterBuffer;
	public LPFN_RIORESIZECOMPLETIONQUEUE RIOResizeCompletionQueue;
	public LPFN_RIORESIZEREQUESTQUEUE RIOResizeRequestQueue;
}

[CRepr]
public struct WSPDATA
{
	public uint16 wVersion;
	public uint16 wHighVersion;
	public char16[256] szDescription;
}

[CRepr]
public struct WSATHREADID
{
	public HANDLE ThreadHandle;
	public uint Reserved;
}

[CRepr]
public struct WSPPROC_TABLE
{
	public LPWSPACCEPT lpWSPAccept;
	public LPWSPADDRESSTOSTRING lpWSPAddressToString;
	public LPWSPASYNCSELECT lpWSPAsyncSelect;
	public LPWSPBIND lpWSPBind;
	public LPWSPCANCELBLOCKINGCALL lpWSPCancelBlockingCall;
	public LPWSPCLEANUP lpWSPCleanup;
	public LPWSPCLOSESOCKET lpWSPCloseSocket;
	public LPWSPCONNECT lpWSPConnect;
	public LPWSPDUPLICATESOCKET lpWSPDuplicateSocket;
	public LPWSPENUMNETWORKEVENTS lpWSPEnumNetworkEvents;
	public LPWSPEVENTSELECT lpWSPEventSelect;
	public LPWSPGETOVERLAPPEDRESULT lpWSPGetOverlappedResult;
	public LPWSPGETPEERNAME lpWSPGetPeerName;
	public LPWSPGETSOCKNAME lpWSPGetSockName;
	public LPWSPGETSOCKOPT lpWSPGetSockOpt;
	public LPWSPGETQOSBYNAME lpWSPGetQOSByName;
	public LPWSPIOCTL lpWSPIoctl;
	public LPWSPJOINLEAF lpWSPJoinLeaf;
	public LPWSPLISTEN lpWSPListen;
	public LPWSPRECV lpWSPRecv;
	public LPWSPRECVDISCONNECT lpWSPRecvDisconnect;
	public LPWSPRECVFROM lpWSPRecvFrom;
	public LPWSPSELECT lpWSPSelect;
	public LPWSPSEND lpWSPSend;
	public LPWSPSENDDISCONNECT lpWSPSendDisconnect;
	public LPWSPSENDTO lpWSPSendTo;
	public LPWSPSETSOCKOPT lpWSPSetSockOpt;
	public LPWSPSHUTDOWN lpWSPShutdown;
	public LPWSPSOCKET lpWSPSocket;
	public LPWSPSTRINGTOADDRESS lpWSPStringToAddress;
}

[CRepr]
public struct WSPUPCALLTABLE
{
	public LPWPUCLOSEEVENT lpWPUCloseEvent;
	public LPWPUCLOSESOCKETHANDLE lpWPUCloseSocketHandle;
	public LPWPUCREATEEVENT lpWPUCreateEvent;
	public LPWPUCREATESOCKETHANDLE lpWPUCreateSocketHandle;
	public LPWPUFDISSET lpWPUFDIsSet;
	public LPWPUGETPROVIDERPATH lpWPUGetProviderPath;
	public LPWPUMODIFYIFSHANDLE lpWPUModifyIFSHandle;
	public LPWPUPOSTMESSAGE lpWPUPostMessage;
	public LPWPUQUERYBLOCKINGCALLBACK lpWPUQueryBlockingCallback;
	public LPWPUQUERYSOCKETHANDLECONTEXT lpWPUQuerySocketHandleContext;
	public LPWPUQUEUEAPC lpWPUQueueApc;
	public LPWPURESETEVENT lpWPUResetEvent;
	public LPWPUSETEVENT lpWPUSetEvent;
	public LPWPUOPENCURRENTTHREAD lpWPUOpenCurrentThread;
	public LPWPUCLOSETHREAD lpWPUCloseThread;
}

[CRepr]
public struct WSC_PROVIDER_AUDIT_INFO
{
	public uint32 RecordSize;
	public void* Reserved;
}

[CRepr]
public struct NSP_ROUTINE
{
	public uint32 cbSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public LPNSPCLEANUP NSPCleanup;
	public LPNSPLOOKUPSERVICEBEGIN NSPLookupServiceBegin;
	public LPNSPLOOKUPSERVICENEXT NSPLookupServiceNext;
	public LPNSPLOOKUPSERVICEEND NSPLookupServiceEnd;
	public LPNSPSETSERVICE NSPSetService;
	public LPNSPINSTALLSERVICECLASS NSPInstallServiceClass;
	public LPNSPREMOVESERVICECLASS NSPRemoveServiceClass;
	public LPNSPGETSERVICECLASSINFO NSPGetServiceClassInfo;
	public LPNSPIOCTL NSPIoctl;
}

[CRepr]
public struct NSPV2_ROUTINE
{
	public uint32 cbSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public LPNSPV2STARTUP NSPv2Startup;
	public LPNSPV2CLEANUP NSPv2Cleanup;
	public LPNSPV2LOOKUPSERVICEBEGIN NSPv2LookupServiceBegin;
	public LPNSPV2LOOKUPSERVICENEXTEX NSPv2LookupServiceNextEx;
	public LPNSPV2LOOKUPSERVICEEND NSPv2LookupServiceEnd;
	public LPNSPV2SETSERVICEEX NSPv2SetServiceEx;
	public LPNSPV2CLIENTSESSIONRUNDOWN NSPv2ClientSessionRundown;
}

[CRepr]
public struct NS_INFOA
{
	public uint32 dwNameSpace;
	public uint32 dwNameSpaceFlags;
	public PSTR lpNameSpace;
}

[CRepr]
public struct NS_INFOW
{
	public uint32 dwNameSpace;
	public uint32 dwNameSpaceFlags;
	public PWSTR lpNameSpace;
}

[CRepr]
public struct SERVICE_TYPE_VALUE
{
	public uint32 dwNameSpace;
	public uint32 dwValueType;
	public uint32 dwValueSize;
	public uint32 dwValueNameOffset;
	public uint32 dwValueOffset;
}

[CRepr]
public struct SERVICE_TYPE_VALUE_ABSA
{
	public uint32 dwNameSpace;
	public uint32 dwValueType;
	public uint32 dwValueSize;
	public PSTR lpValueName;
	public void* lpValue;
}

[CRepr]
public struct SERVICE_TYPE_VALUE_ABSW
{
	public uint32 dwNameSpace;
	public uint32 dwValueType;
	public uint32 dwValueSize;
	public PWSTR lpValueName;
	public void* lpValue;
}

[CRepr]
public struct SERVICE_TYPE_INFO
{
	public uint32 dwTypeNameOffset;
	public uint32 dwValueCount;
	public SERVICE_TYPE_VALUE* Values mut => &Values_impl;
	private SERVICE_TYPE_VALUE[ANYSIZE_ARRAY] Values_impl;
}

[CRepr]
public struct SERVICE_TYPE_INFO_ABSA
{
	public PSTR lpTypeName;
	public uint32 dwValueCount;
	public SERVICE_TYPE_VALUE_ABSA* Values mut => &Values_impl;
	private SERVICE_TYPE_VALUE_ABSA[ANYSIZE_ARRAY] Values_impl;
}

[CRepr]
public struct SERVICE_TYPE_INFO_ABSW
{
	public PWSTR lpTypeName;
	public uint32 dwValueCount;
	public SERVICE_TYPE_VALUE_ABSW* Values mut => &Values_impl;
	private SERVICE_TYPE_VALUE_ABSW[ANYSIZE_ARRAY] Values_impl;
}

[CRepr]
public struct SERVICE_ADDRESS
{
	public uint32 dwAddressType;
	public uint32 dwAddressFlags;
	public uint32 dwAddressLength;
	public uint32 dwPrincipalLength;
	public uint8* lpAddress;
	public uint8* lpPrincipal;
}

[CRepr]
public struct SERVICE_ADDRESSES
{
	public uint32 dwAddressCount;
	public SERVICE_ADDRESS* Addresses mut => &Addresses_impl;
	private SERVICE_ADDRESS[ANYSIZE_ARRAY] Addresses_impl;
}

[CRepr]
public struct SERVICE_INFOA
{
	public Guid* lpServiceType;
	public PSTR lpServiceName;
	public PSTR lpComment;
	public PSTR lpLocale;
	public RESOURCE_DISPLAY_TYPE dwDisplayHint;
	public uint32 dwVersion;
	public uint32 dwTime;
	public PSTR lpMachineName;
	public SERVICE_ADDRESSES* lpServiceAddress;
	public BLOB ServiceSpecificInfo;
}

[CRepr]
public struct SERVICE_INFOW
{
	public Guid* lpServiceType;
	public PWSTR lpServiceName;
	public PWSTR lpComment;
	public PWSTR lpLocale;
	public RESOURCE_DISPLAY_TYPE dwDisplayHint;
	public uint32 dwVersion;
	public uint32 dwTime;
	public PWSTR lpMachineName;
	public SERVICE_ADDRESSES* lpServiceAddress;
	public BLOB ServiceSpecificInfo;
}

[CRepr]
public struct NS_SERVICE_INFOA
{
	public uint32 dwNameSpace;
	public SERVICE_INFOA ServiceInfo;
}

[CRepr]
public struct NS_SERVICE_INFOW
{
	public uint32 dwNameSpace;
	public SERVICE_INFOW ServiceInfo;
}

[CRepr]
public struct PROTOCOL_INFOA
{
	public uint32 dwServiceFlags;
	public int32 iAddressFamily;
	public int32 iMaxSockAddr;
	public int32 iMinSockAddr;
	public int32 iSocketType;
	public int32 iProtocol;
	public uint32 dwMessageSize;
	public PSTR lpProtocol;
}

[CRepr]
public struct PROTOCOL_INFOW
{
	public uint32 dwServiceFlags;
	public int32 iAddressFamily;
	public int32 iMaxSockAddr;
	public int32 iMinSockAddr;
	public int32 iSocketType;
	public int32 iProtocol;
	public uint32 dwMessageSize;
	public PWSTR lpProtocol;
}

[CRepr]
public struct NETRESOURCE2A
{
	public uint32 dwScope;
	public uint32 dwType;
	public uint32 dwUsage;
	public uint32 dwDisplayType;
	public PSTR lpLocalName;
	public PSTR lpRemoteName;
	public PSTR lpComment;
	public NS_INFOA ns_info;
	public Guid ServiceType;
	public uint32 dwProtocols;
	public int32* lpiProtocols;
}

[CRepr]
public struct NETRESOURCE2W
{
	public uint32 dwScope;
	public uint32 dwType;
	public uint32 dwUsage;
	public uint32 dwDisplayType;
	public PWSTR lpLocalName;
	public PWSTR lpRemoteName;
	public PWSTR lpComment;
	public NS_INFOA ns_info;
	public Guid ServiceType;
	public uint32 dwProtocols;
	public int32* lpiProtocols;
}

[CRepr]
public struct SERVICE_ASYNC_INFO
{
	public LPSERVICE_CALLBACK_PROC lpServiceCallbackProc;
	public LPARAM lParam;
	public HANDLE hAsyncTaskHandle;
}

[CRepr]
public struct SOCKADDR_UN
{
	public uint16 sun_family;
	public CHAR[108] sun_path;
}

[CRepr]
public struct SOCKADDR_IPX
{
	public int16 sa_family;
	public CHAR[4] sa_netnum;
	public CHAR[6] sa_nodenum;
	public uint16 sa_socket;
}

[CRepr]
public struct SOCKADDR_TP
{
	public uint16 tp_family;
	public uint16 tp_addr_type;
	public uint16 tp_taddr_len;
	public uint16 tp_tsel_len;
	public uint8[64] tp_addr;
}

[CRepr]
public struct SOCKADDR_NB
{
	public int16 snb_family;
	public uint16 snb_type;
	public CHAR[16] snb_name;
}

[CRepr]
public struct SOCKADDR_VNS
{
	public uint16 sin_family;
	public uint8[4] net_address;
	public uint8[2] subnet_addr;
	public uint8[2] port;
	public uint8 hops;
	public uint8[5] filler;
}

[CRepr, Union]
public struct DL_OUI
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint8 _bitfield;
	}
	public uint8[3] Byte;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union]
public struct DL_EI48
{
	public uint8[3] Byte;
}

[CRepr, Union]
public struct DL_EUI48
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public DL_OUI Oui;
		public DL_EI48 Ei48;
	}
	public uint8[6] Byte;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr, Union]
public struct DL_EI64
{
	public uint8[5] Byte;
}

[CRepr, Union]
public struct DL_EUI64
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		[CRepr, Union]
		public struct _Anonymous_e__Union
		{
			[CRepr]
			public struct _Anonymous_e__Struct
			{
				public uint8 Type;
				public uint8 Tse;
				public DL_EI48 Ei48;
			}
			public DL_EI64 Ei64;
			public using _Anonymous_e__Struct Anonymous;
		}
		public DL_OUI Oui;
		public using _Anonymous_e__Union Anonymous;
	}
	public uint8[8] Byte;
	public uint64 Value;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct SNAP_HEADER
{
	public uint8 Dsap;
	public uint8 Ssap;
	public uint8 Control;
	public uint8[3] Oui;
	public uint16 Type;
}

[CRepr]
public struct ETHERNET_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 Type;
		public uint16 Length;
	}
	public DL_EUI48 Destination;
	public DL_EUI48 Source;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct VLAN_TAG
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 Tag;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint16 Type;
}

[CRepr]
public struct ICMP_HEADER
{
	public uint8 Type;
	public uint8 Code;
	public uint16 Checksum;
}

[CRepr]
public struct ICMP_MESSAGE
{
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public uint32* Data32 mut => &Data32_impl;
		private uint32[ANYSIZE_ARRAY] Data32_impl;
		public uint16[2] Data16;
		public uint8[4] Data8;
	}
	public ICMP_HEADER Header;
	public _Data_e__Union Data;
}

[CRepr]
public struct IPV4_HEADER
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 FlagsAndOffset;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 TypeOfServiceAndEcnField;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 VersionAndHeaderLength;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 TotalLength;
	public uint16 Identification;
	public using _Anonymous3_e__Union Anonymous3;
	public uint8 TimeToLive;
	public uint8 Protocol;
	public uint16 HeaderChecksum;
	public IN_ADDR SourceAddress;
	public IN_ADDR DestinationAddress;
}

[CRepr]
public struct IPV4_OPTION_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 OptionType;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint8 OptionLength;
}

[CRepr]
public struct IPV4_TIMESTAMP_OPTION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 FlagsOverflow;
		public using _Anonymous_e__Struct Anonymous;
	}
	public IPV4_OPTION_HEADER OptionHeader;
	public uint8 Pointer;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IPV4_ROUTING_HEADER
{
	public IPV4_OPTION_HEADER OptionHeader;
	public uint8 Pointer;
}

[CRepr]
public struct ICMPV4_ROUTER_SOLICIT
{
	public ICMP_MESSAGE RsHeader;
}

[CRepr]
public struct ICMPV4_ROUTER_ADVERT_HEADER
{
	public ICMP_MESSAGE RaHeader;
}

[CRepr]
public struct ICMPV4_ROUTER_ADVERT_ENTRY
{
	public IN_ADDR RouterAdvertAddr;
	public int32 PreferenceLevel;
}

[CRepr]
public struct ICMPV4_TIMESTAMP_MESSAGE
{
	public ICMP_MESSAGE Header;
	public uint32 OriginateTimestamp;
	public uint32 ReceiveTimestamp;
	public uint32 TransmitTimestamp;
}

[CRepr]
public struct ICMPV4_ADDRESS_MASK_MESSAGE
{
	public ICMP_MESSAGE Header;
	public uint32 AddressMask;
}

[CRepr]
public struct ARP_HEADER
{
	public uint16 HardwareAddressSpace;
	public uint16 ProtocolAddressSpace;
	public uint8 HardwareAddressLength;
	public uint8 ProtocolAddressLength;
	public uint16 Opcode;
	public uint8* SenderHardwareAddress mut => &SenderHardwareAddress_impl;
	private uint8[ANYSIZE_ARRAY] SenderHardwareAddress_impl;
}

[CRepr]
public struct IGMP_HEADER
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint8 VersionType;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint8 Reserved;
		public uint8 MaxRespTime;
		public uint8 Code;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 Checksum;
	public IN_ADDR MulticastAddress;
}

[CRepr]
public struct IGMPV3_QUERY_HEADER
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 QueriersQueryInterfaceCode;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 MaxRespCode;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8 Type;
	public using _Anonymous1_e__Union Anonymous1;
	public uint16 Checksum;
	public IN_ADDR MulticastAddress;
	public uint8 _bitfield;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 SourceCount;
}

[CRepr]
public struct IGMPV3_REPORT_RECORD_HEADER
{
	public uint8 Type;
	public uint8 AuxillaryDataLength;
	public uint16 SourceCount;
	public IN_ADDR MulticastAddress;
}

[CRepr]
public struct IGMPV3_REPORT_HEADER
{
	public uint8 Type;
	public uint8 Reserved;
	public uint16 Checksum;
	public uint16 Reserved2;
	public uint16 RecordCount;
}

[CRepr]
public struct IPV6_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 VersionClassFlow;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint16 PayloadLength;
	public uint8 NextHeader;
	public uint8 HopLimit;
	public IN6_ADDR SourceAddress;
	public IN6_ADDR DestinationAddress;
}

[CRepr]
public struct IPV6_FRAGMENT_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint16 OffsetAndFlags;
	}
	public uint8 NextHeader;
	public uint8 Reserved;
	public using _Anonymous_e__Union Anonymous;
	public uint32 Id;
}

[CRepr]
public struct IPV6_EXTENSION_HEADER
{
	public uint8 NextHeader;
	public uint8 Length;
}

[CRepr]
public struct IPV6_OPTION_HEADER
{
	public uint8 Type;
	public uint8 DataLength;
}

[CRepr]
public struct IPV6_OPTION_JUMBOGRAM
{
	public IPV6_OPTION_HEADER Header;
	public uint8[4] JumbogramLength;
}

[CRepr]
public struct IPV6_OPTION_ROUTER_ALERT
{
	public IPV6_OPTION_HEADER Header;
	public uint8[2] Value;
}

[CRepr]
public struct IPV6_ROUTING_HEADER
{
	public uint8 NextHeader;
	public uint8 Length;
	public uint8 RoutingType;
	public uint8 SegmentsLeft;
	public uint8[4] Reserved;
}

[CRepr]
public struct ND_ROUTER_SOLICIT_HEADER
{
	public ICMP_MESSAGE nd_rs_hdr;
}

[CRepr]
public struct ND_ROUTER_ADVERT_HEADER
{
	public ICMP_MESSAGE nd_ra_hdr;
	public uint32 nd_ra_reachable;
	public uint32 nd_ra_retransmit;
}

[CRepr, Union]
public struct IPV6_ROUTER_ADVERTISEMENT_FLAGS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint8 _bitfield;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint8 Value;
}

[CRepr]
public struct ND_NEIGHBOR_SOLICIT_HEADER
{
	public ICMP_MESSAGE nd_ns_hdr;
	public IN6_ADDR nd_ns_target;
}

[CRepr]
public struct ND_NEIGHBOR_ADVERT_HEADER
{
	public ICMP_MESSAGE nd_na_hdr;
	public IN6_ADDR nd_na_target;
}

[CRepr, Union]
public struct IPV6_NEIGHBOR_ADVERTISEMENT_FLAGS
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint8 _bitfield;
		public uint8[3] Reserved2;
	}
	public using _Anonymous_e__Struct Anonymous;
	public uint32 Value;
}

[CRepr]
public struct ND_REDIRECT_HEADER
{
	public ICMP_MESSAGE nd_rd_hdr;
	public IN6_ADDR nd_rd_target;
	public IN6_ADDR nd_rd_dst;
}

[CRepr]
public struct ND_OPTION_HDR
{
	public uint8 nd_opt_type;
	public uint8 nd_opt_len;
}

[CRepr]
public struct ND_OPTION_PREFIX_INFO
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8[3] nd_opt_pi_reserved3;
			public uint8 nd_opt_pi_site_prefix_len;
		}
		public uint32 nd_opt_pi_reserved2;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Flags_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 nd_opt_pi_flags_reserved;
		public _Flags_e__Struct Flags;
	}
	public uint8 nd_opt_pi_type;
	public uint8 nd_opt_pi_len;
	public uint8 nd_opt_pi_prefix_len;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 nd_opt_pi_valid_time;
	public uint32 nd_opt_pi_preferred_time;
	public using _Anonymous2_e__Union Anonymous2;
	public IN6_ADDR nd_opt_pi_prefix;
}

[CRepr]
public struct ND_OPTION_RD_HDR
{
	public uint8 nd_opt_rh_type;
	public uint8 nd_opt_rh_len;
	public uint16 nd_opt_rh_reserved1;
	public uint32 nd_opt_rh_reserved2;
}

[CRepr]
public struct ND_OPTION_MTU
{
	public uint8 nd_opt_mtu_type;
	public uint8 nd_opt_mtu_len;
	public uint16 nd_opt_mtu_reserved;
	public uint32 nd_opt_mtu_mtu;
}

[CRepr]
public struct ND_OPTION_ROUTE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Flags_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 nd_opt_ri_flags_reserved;
		public _Flags_e__Struct Flags;
	}
	public uint8 nd_opt_ri_type;
	public uint8 nd_opt_ri_len;
	public uint8 nd_opt_ri_prefix_len;
	public using _Anonymous_e__Union Anonymous;
	public uint32 nd_opt_ri_route_lifetime;
	public IN6_ADDR nd_opt_ri_prefix;
}

[CRepr]
public struct ND_OPTION_RDNSS
{
	public uint8 nd_opt_rdnss_type;
	public uint8 nd_opt_rdnss_len;
	public uint16 nd_opt_rdnss_reserved;
	public uint32 nd_opt_rdnss_lifetime;
}

[CRepr]
public struct ND_OPTION_DNSSL
{
	public uint8 nd_opt_dnssl_type;
	public uint8 nd_opt_dnssl_len;
	public uint16 nd_opt_dnssl_reserved;
	public uint32 nd_opt_dnssl_lifetime;
}

[CRepr]
public struct MLD_HEADER
{
	public ICMP_HEADER IcmpHeader;
	public uint16 MaxRespTime;
	public uint16 Reserved;
	public IN6_ADDR MulticastAddress;
}

[CRepr]
public struct MLDV2_QUERY_HEADER
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 _bitfield;
		}
		public uint8 QueriersQueryInterfaceCode;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 _bitfield;
		}
		public uint16 MaxRespCode;
		public using _Anonymous_e__Struct Anonymous;
	}
	public ICMP_HEADER IcmpHeader;
	public using _Anonymous1_e__Union Anonymous1;
	public uint16 Reserved;
	public IN6_ADDR MulticastAddress;
	public uint8 _bitfield;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 SourceCount;
}

[CRepr]
public struct MLDV2_REPORT_RECORD_HEADER
{
	public uint8 Type;
	public uint8 AuxillaryDataLength;
	public uint16 SourceCount;
	public IN6_ADDR MulticastAddress;
}

[CRepr]
public struct MLDV2_REPORT_HEADER
{
	public ICMP_HEADER IcmpHeader;
	public uint16 Reserved;
	public uint16 RecordCount;
}

[CRepr, Packed(1)]
public struct TCP_HDR
{
	public uint16 th_sport;
	public uint16 th_dport;
	public uint32 th_seq;
	public uint32 th_ack;
	public uint8 _bitfield;
	public uint8 th_flags;
	public uint16 th_win;
	public uint16 th_sum;
	public uint16 th_urp;
}

[CRepr, Packed(1)]
public struct TCP_OPT_MSS
{
	public uint8 Kind;
	public uint8 Length;
	public uint16 Mss;
}

[CRepr, Packed(1)]
public struct TCP_OPT_WS
{
	public uint8 Kind;
	public uint8 Length;
	public uint8 ShiftCnt;
}

[CRepr, Packed(1)]
public struct TCP_OPT_SACK_PERMITTED
{
	public uint8 Kind;
	public uint8 Length;
}

[CRepr, Packed(1)]
public struct TCP_OPT_SACK
{
	[CRepr, Packed(1)]
	public struct tcp_opt_sack_block
	{
		public uint32 Left;
		public uint32 Right;
	}
	public uint8 Kind;
	public uint8 Length;
	public tcp_opt_sack_block* Block mut => &Block_impl;
	private tcp_opt_sack_block[ANYSIZE_ARRAY] Block_impl;
}

[CRepr, Packed(1)]
public struct TCP_OPT_TS
{
	public uint8 Kind;
	public uint8 Length;
	public uint32 Val;
	public uint32 EcR;
}

[CRepr, Packed(1)]
public struct TCP_OPT_UNKNOWN
{
	public uint8 Kind;
	public uint8 Length;
}

[CRepr, Packed(1)]
public struct TCP_OPT_FASTOPEN
{
	public uint8 Kind;
	public uint8 Length;
	public uint8* Cookie mut => &Cookie_impl;
	private uint8[ANYSIZE_ARRAY] Cookie_impl;
}

[CRepr]
public struct DL_TUNNEL_ADDRESS
{
	public COMPARTMENT_ID CompartmentId;
	public SCOPE_ID ScopeId;
	public uint8* IpAddress mut => &IpAddress_impl;
	private uint8[ANYSIZE_ARRAY] IpAddress_impl;
}

[CRepr, Packed(1)]
public struct DL_TEREDO_ADDRESS
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint16 Flags;
			public uint16 MappedPort;
			public IN_ADDR MappedAddress;
		}
		public DL_EUI64 Eui64;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8[6] Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(1)]
public struct DL_TEREDO_ADDRESS_PRV
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		[CRepr, Packed(1)]
		public struct _Anonymous_e__Struct
		{
			public uint16 Flags;
			public uint16 MappedPort;
			public IN_ADDR MappedAddress;
			public IN_ADDR LocalAddress;
			public uint32 InterfaceIndex;
			public uint16 LocalPort;
			public DL_EUI48 DlDestination;
		}
		public DL_EUI64 Eui64;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint8[6] Reserved;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(1)]
public struct IPTLS_METADATA
{
	public uint64 SequenceNumber;
}

[CRepr]
public struct NPI_MODULEID
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public Guid Guid;
		public LUID IfLuid;
	}
	public uint16 Length;
	public NPI_MODULEID_TYPE Type;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region Functions
public static
{
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCEnumProtocols32(int32* lpiProtocols, WSAPROTOCOL_INFOW* lpProtocolBuffer, uint32* lpdwBufferLength, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCDeinstallProvider32(Guid* lpProviderId, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallProvider64_32(Guid* lpProviderId, PWSTR lpszProviderDllPath, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCGetProviderPath32(Guid* lpProviderId, char16* lpszProviderDllPath, int32* lpProviderDllPathLen, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCUpdateProvider32(Guid* lpProviderId, PWSTR lpszProviderDllPath, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCSetProviderInfo32(Guid* lpProviderId, WSC_PROVIDER_INFO_TYPE InfoType, uint8* Info, uint InfoSize, uint32 Flags, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCGetProviderInfo32(Guid* lpProviderId, WSC_PROVIDER_INFO_TYPE InfoType, uint8* Info, uint* InfoSize, uint32 Flags, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCEnumNameSpaceProviders32(uint32* lpdwBufferLength, WSANAMESPACE_INFOW* lpnspBuffer);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCEnumNameSpaceProvidersEx32(uint32* lpdwBufferLength, WSANAMESPACE_INFOEXW* lpnspBuffer);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallNameSpace32(PWSTR lpszIdentifier, PWSTR lpszPathName, uint32 dwNameSpace, uint32 dwVersion, Guid* lpProviderId);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallNameSpaceEx32(PWSTR lpszIdentifier, PWSTR lpszPathName, uint32 dwNameSpace, uint32 dwVersion, Guid* lpProviderId, BLOB* lpProviderSpecific);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCUnInstallNameSpace32(Guid* lpProviderId);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCEnableNSProvider32(Guid* lpProviderId, BOOL fEnable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallProviderAndChains64_32(Guid* lpProviderId, PWSTR lpszProviderDllPath, PWSTR lpszProviderDllPath32, PWSTR lpszLspName, uint32 dwServiceFlags, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, uint32* lpdwCatalogEntryId, int32* lpErrno);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCWriteProviderOrder32(uint32* lpwdCatalogEntryId, uint32 dwNumberOfEntries);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCWriteNameSpaceOrder32(Guid* lpProviderId, uint32 dwNumberOfEntries);

#endif
	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 __WSAFDIsSet(SOCKET fd, FD_SET* param1);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SOCKET accept(SOCKET s, SOCKADDR* addr, int32* addrlen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 bind(SOCKET s, SOCKADDR* name, int32 namelen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 closesocket(SOCKET s);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 connect(SOCKET s, SOCKADDR* name, int32 namelen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ioctlsocket(SOCKET s, int32 cmd, uint32* argp);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 getpeername(SOCKET s, SOCKADDR* name, int32* namelen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 getsockname(SOCKET s, SOCKADDR* name, int32* namelen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 getsockopt(SOCKET s, int32 level, int32 optname, PSTR optval, int32* optlen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 htonl(uint32 hostlong);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 htons(uint16 hostshort);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 inet_addr(PSTR cp);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR inet_ntoa(IN_ADDR @in);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 listen(SOCKET s, int32 backlog);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ntohl(uint32 netlong);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 ntohs(uint16 netshort);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 recv(SOCKET s, PSTR buf, int32 len, SEND_RECV_FLAGS flags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 recvfrom(SOCKET s, PSTR buf, int32 len, int32 flags, SOCKADDR* from, int32* fromlen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 select(int32 nfds, FD_SET* readfds, FD_SET* writefds, FD_SET* exceptfds, TIMEVAL* timeout);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 send(SOCKET s, PSTR buf, int32 len, SEND_RECV_FLAGS flags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sendto(SOCKET s, PSTR buf, int32 len, int32 flags, SOCKADDR* to, int32 tolen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 setsockopt(SOCKET s, int32 level, int32 optname, PSTR optval, int32 optlen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 shutdown(SOCKET s, int32 how);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SOCKET socket(int32 af, int32 type, int32 protocol);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HOSTENT* gethostbyaddr(PSTR addr, int32 len, int32 type);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HOSTENT* gethostbyname(PSTR name);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 gethostname(PSTR name, int32 namelen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetHostNameW(char16* name, int32 namelen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SERVENT* getservbyport(int32 port, PSTR proto);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SERVENT* getservbyname(PSTR name, PSTR proto);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PROTOENT* getprotobynumber(int32 number);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PROTOENT* getprotobyname(PSTR name);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAStartup(uint16 wVersionRequested, WSADATA* lpWSAData);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSACleanup();

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WSASetLastError(int32 iError);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WSA_ERROR WSAGetLastError();

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAIsBlocking();

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAUnhookBlockingHook();

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FARPROC WSASetBlockingHook(FARPROC lpBlockFunc);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSACancelBlockingCall();

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSAAsyncGetServByName(HWND hWnd, uint32 wMsg, PSTR name, PSTR proto, PSTR buf, int32 buflen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSAAsyncGetServByPort(HWND hWnd, uint32 wMsg, int32 port, PSTR proto, PSTR buf, int32 buflen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSAAsyncGetProtoByName(HWND hWnd, uint32 wMsg, PSTR name, PSTR buf, int32 buflen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSAAsyncGetProtoByNumber(HWND hWnd, uint32 wMsg, int32 number, PSTR buf, int32 buflen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSAAsyncGetHostByName(HWND hWnd, uint32 wMsg, PSTR name, PSTR buf, int32 buflen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSAAsyncGetHostByAddr(HWND hWnd, uint32 wMsg, PSTR addr, int32 len, int32 type, PSTR buf, int32 buflen);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSACancelAsyncRequest(HANDLE hAsyncTaskHandle);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAAsyncSelect(SOCKET s, HWND hWnd, uint32 wMsg, int32 lEvent);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SOCKET WSAAccept(SOCKET s, SOCKADDR* addr, int32* addrlen, LPCONDITIONPROC lpfnCondition, uint dwCallbackData);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSACloseEvent(HANDLE hEvent);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAConnect(SOCKET s, SOCKADDR* name, int32 namelen, WSABUF* lpCallerData, WSABUF* lpCalleeData, QOS* lpSQOS, QOS* lpGQOS);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAConnectByNameW(SOCKET s, PWSTR nodename, PWSTR servicename, uint32* LocalAddressLength, SOCKADDR* LocalAddress, uint32* RemoteAddressLength, SOCKADDR* RemoteAddress, TIMEVAL* timeout, OVERLAPPED* Reserved);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAConnectByNameA(SOCKET s, PSTR nodename, PSTR servicename, uint32* LocalAddressLength, SOCKADDR* LocalAddress, uint32* RemoteAddressLength, SOCKADDR* RemoteAddress, TIMEVAL* timeout, OVERLAPPED* Reserved);
	public static BOOL WSAConnectByName(SOCKET s, PSTR nodename, PSTR servicename, uint32* LocalAddressLength, SOCKADDR* LocalAddress, uint32* RemoteAddressLength, SOCKADDR* RemoteAddress, TIMEVAL* timeout, OVERLAPPED* Reserved) => WSAConnectByNameA(s, nodename, servicename, LocalAddressLength, LocalAddress, RemoteAddressLength, RemoteAddress, timeout, Reserved);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAConnectByList(SOCKET s, SOCKET_ADDRESS_LIST* SocketAddress, uint32* LocalAddressLength, SOCKADDR* LocalAddress, uint32* RemoteAddressLength, SOCKADDR* RemoteAddress, TIMEVAL* timeout, OVERLAPPED* Reserved);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WSACreateEvent();

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSADuplicateSocketA(SOCKET s, uint32 dwProcessId, WSAPROTOCOL_INFOA* lpProtocolInfo);
	public static int32 WSADuplicateSocket(SOCKET s, uint32 dwProcessId, WSAPROTOCOL_INFOA* lpProtocolInfo) => WSADuplicateSocketA(s, dwProcessId, lpProtocolInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSADuplicateSocketW(SOCKET s, uint32 dwProcessId, WSAPROTOCOL_INFOW* lpProtocolInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumNetworkEvents(SOCKET s, HANDLE hEventObject, WSANETWORKEVENTS* lpNetworkEvents);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumProtocolsA(int32* lpiProtocols, WSAPROTOCOL_INFOA* lpProtocolBuffer, uint32* lpdwBufferLength);
	public static int32 WSAEnumProtocols(int32* lpiProtocols, WSAPROTOCOL_INFOA* lpProtocolBuffer, uint32* lpdwBufferLength) => WSAEnumProtocolsA(lpiProtocols, lpProtocolBuffer, lpdwBufferLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumProtocolsW(int32* lpiProtocols, WSAPROTOCOL_INFOW* lpProtocolBuffer, uint32* lpdwBufferLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEventSelect(SOCKET s, HANDLE hEventObject, int32 lNetworkEvents);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAGetOverlappedResult(SOCKET s, OVERLAPPED* lpOverlapped, uint32* lpcbTransfer, BOOL fWait, uint32* lpdwFlags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAGetQOSByName(SOCKET s, WSABUF* lpQOSName, QOS* lpQOS);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAHtonl(SOCKET s, uint32 hostlong, uint32* lpnetlong);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAHtons(SOCKET s, uint16 hostshort, uint16* lpnetshort);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAIoctl(SOCKET s, uint32 dwIoControlCode, void* lpvInBuffer, uint32 cbInBuffer, void* lpvOutBuffer, uint32 cbOutBuffer, uint32* lpcbBytesReturned, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SOCKET WSAJoinLeaf(SOCKET s, SOCKADDR* name, int32 namelen, WSABUF* lpCallerData, WSABUF* lpCalleeData, QOS* lpSQOS, QOS* lpGQOS, uint32 dwFlags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSANtohl(SOCKET s, uint32 netlong, uint32* lphostlong);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSANtohs(SOCKET s, uint16 netshort, uint16* lphostshort);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSARecv(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesRecvd, uint32* lpFlags, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSARecvDisconnect(SOCKET s, WSABUF* lpInboundDisconnectData);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSARecvFrom(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesRecvd, uint32* lpFlags, SOCKADDR* lpFrom, int32* lpFromlen, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSAResetEvent(HANDLE hEvent);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASend(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesSent, uint32 dwFlags, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASendMsg(SOCKET Handle, WSAMSG* lpMsg, uint32 dwFlags, uint32* lpNumberOfBytesSent, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASendDisconnect(SOCKET s, WSABUF* lpOutboundDisconnectData);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASendTo(SOCKET s, WSABUF* lpBuffers, uint32 dwBufferCount, uint32* lpNumberOfBytesSent, uint32 dwFlags, SOCKADDR* lpTo, int32 iTolen, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WSASetEvent(HANDLE hEvent);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SOCKET WSASocketA(int32 af, int32 type, int32 protocol, WSAPROTOCOL_INFOA* lpProtocolInfo, uint32 g, uint32 dwFlags);
	public static SOCKET WSASocket(int32 af, int32 type, int32 protocol, WSAPROTOCOL_INFOA* lpProtocolInfo, uint32 g, uint32 dwFlags) => WSASocketA(af, type, protocol, lpProtocolInfo, g, dwFlags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SOCKET WSASocketW(int32 af, int32 type, int32 protocol, WSAPROTOCOL_INFOW* lpProtocolInfo, uint32 g, uint32 dwFlags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WSAWaitForMultipleEvents(uint32 cEvents, HANDLE* lphEvents, BOOL fWaitAll, uint32 dwTimeout, BOOL fAlertable);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAAddressToStringA(SOCKADDR* lpsaAddress, uint32 dwAddressLength, WSAPROTOCOL_INFOA* lpProtocolInfo, uint8* lpszAddressString, uint32* lpdwAddressStringLength);
	public static int32 WSAAddressToString(SOCKADDR* lpsaAddress, uint32 dwAddressLength, WSAPROTOCOL_INFOA* lpProtocolInfo, uint8* lpszAddressString, uint32* lpdwAddressStringLength) => WSAAddressToStringA(lpsaAddress, dwAddressLength, lpProtocolInfo, lpszAddressString, lpdwAddressStringLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAAddressToStringW(SOCKADDR* lpsaAddress, uint32 dwAddressLength, WSAPROTOCOL_INFOW* lpProtocolInfo, char16* lpszAddressString, uint32* lpdwAddressStringLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAStringToAddressA(PSTR AddressString, int32 AddressFamily, WSAPROTOCOL_INFOA* lpProtocolInfo, SOCKADDR* lpAddress, int32* lpAddressLength);
	public static int32 WSAStringToAddress(PSTR AddressString, int32 AddressFamily, WSAPROTOCOL_INFOA* lpProtocolInfo, SOCKADDR* lpAddress, int32* lpAddressLength) => WSAStringToAddressA(AddressString, AddressFamily, lpProtocolInfo, lpAddress, lpAddressLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAStringToAddressW(PWSTR AddressString, int32 AddressFamily, WSAPROTOCOL_INFOW* lpProtocolInfo, SOCKADDR* lpAddress, int32* lpAddressLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSALookupServiceBeginA(WSAQUERYSETA* lpqsRestrictions, uint32 dwControlFlags, HANDLE* lphLookup);
	public static int32 WSALookupServiceBegin(WSAQUERYSETA* lpqsRestrictions, uint32 dwControlFlags, HANDLE* lphLookup) => WSALookupServiceBeginA(lpqsRestrictions, dwControlFlags, lphLookup);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSALookupServiceBeginW(WSAQUERYSETW* lpqsRestrictions, uint32 dwControlFlags, HANDLE* lphLookup);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSALookupServiceNextA(HANDLE hLookup, uint32 dwControlFlags, uint32* lpdwBufferLength, WSAQUERYSETA* lpqsResults);
	public static int32 WSALookupServiceNext(HANDLE hLookup, uint32 dwControlFlags, uint32* lpdwBufferLength, WSAQUERYSETA* lpqsResults) => WSALookupServiceNextA(hLookup, dwControlFlags, lpdwBufferLength, lpqsResults);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSALookupServiceNextW(HANDLE hLookup, uint32 dwControlFlags, uint32* lpdwBufferLength, WSAQUERYSETW* lpqsResults);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSANSPIoctl(HANDLE hLookup, uint32 dwControlCode, void* lpvInBuffer, uint32 cbInBuffer, void* lpvOutBuffer, uint32 cbOutBuffer, uint32* lpcbBytesReturned, WSACOMPLETION* lpCompletion);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSALookupServiceEnd(HANDLE hLookup);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAInstallServiceClassA(WSASERVICECLASSINFOA* lpServiceClassInfo);
	public static int32 WSAInstallServiceClass(WSASERVICECLASSINFOA* lpServiceClassInfo) => WSAInstallServiceClassA(lpServiceClassInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAInstallServiceClassW(WSASERVICECLASSINFOW* lpServiceClassInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSARemoveServiceClass(Guid* lpServiceClassId);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAGetServiceClassInfoA(Guid* lpProviderId, Guid* lpServiceClassId, uint32* lpdwBufSize, WSASERVICECLASSINFOA* lpServiceClassInfo);
	public static int32 WSAGetServiceClassInfo(Guid* lpProviderId, Guid* lpServiceClassId, uint32* lpdwBufSize, WSASERVICECLASSINFOA* lpServiceClassInfo) => WSAGetServiceClassInfoA(lpProviderId, lpServiceClassId, lpdwBufSize, lpServiceClassInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAGetServiceClassInfoW(Guid* lpProviderId, Guid* lpServiceClassId, uint32* lpdwBufSize, WSASERVICECLASSINFOW* lpServiceClassInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumNameSpaceProvidersA(uint32* lpdwBufferLength, WSANAMESPACE_INFOA* lpnspBuffer);
	public static int32 WSAEnumNameSpaceProviders(uint32* lpdwBufferLength, WSANAMESPACE_INFOA* lpnspBuffer) => WSAEnumNameSpaceProvidersA(lpdwBufferLength, lpnspBuffer);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumNameSpaceProvidersW(uint32* lpdwBufferLength, WSANAMESPACE_INFOW* lpnspBuffer);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumNameSpaceProvidersExA(uint32* lpdwBufferLength, WSANAMESPACE_INFOEXA* lpnspBuffer);
	public static int32 WSAEnumNameSpaceProvidersEx(uint32* lpdwBufferLength, WSANAMESPACE_INFOEXA* lpnspBuffer) => WSAEnumNameSpaceProvidersExA(lpdwBufferLength, lpnspBuffer);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAEnumNameSpaceProvidersExW(uint32* lpdwBufferLength, WSANAMESPACE_INFOEXW* lpnspBuffer);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAGetServiceClassNameByClassIdA(Guid* lpServiceClassId, PSTR lpszServiceClassName, uint32* lpdwBufferLength);
	public static int32 WSAGetServiceClassNameByClassId(Guid* lpServiceClassId, PSTR lpszServiceClassName, uint32* lpdwBufferLength) => WSAGetServiceClassNameByClassIdA(lpServiceClassId, lpszServiceClassName, lpdwBufferLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAGetServiceClassNameByClassIdW(Guid* lpServiceClassId, PWSTR lpszServiceClassName, uint32* lpdwBufferLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASetServiceA(WSAQUERYSETA* lpqsRegInfo, WSAESETSERVICEOP essoperation, uint32 dwControlFlags);
	public static int32 WSASetService(WSAQUERYSETA* lpqsRegInfo, WSAESETSERVICEOP essoperation, uint32 dwControlFlags) => WSASetServiceA(lpqsRegInfo, essoperation, dwControlFlags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASetServiceW(WSAQUERYSETW* lpqsRegInfo, WSAESETSERVICEOP essoperation, uint32 dwControlFlags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAProviderConfigChange(HANDLE* lpNotificationHandle, OVERLAPPED* lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAPoll(WSAPOLLFD* fdArray, uint32 fds, int32 timeout);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ProcessSocketNotifications(HANDLE completionPort, uint32 registrationCount, SOCK_NOTIFY_REGISTRATION* registrationInfos, uint32 timeoutMs, uint32 completionCount, OVERLAPPED_ENTRY* completionPortEntries, uint32* receivedEntryCount);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR RtlIpv4AddressToStringA(IN_ADDR* Addr, uint8* S);
	public static PSTR RtlIpv4AddressToString(IN_ADDR* Addr, uint8* S) => RtlIpv4AddressToStringA(Addr, S);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv4AddressToStringExA(IN_ADDR* Address, uint16 Port, uint8* AddressString, uint32* AddressStringLength);
	public static int32 RtlIpv4AddressToStringEx(IN_ADDR* Address, uint16 Port, uint8* AddressString, uint32* AddressStringLength) => RtlIpv4AddressToStringExA(Address, Port, AddressString, AddressStringLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR RtlIpv4AddressToStringW(IN_ADDR* Addr, char16* S);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv4AddressToStringExW(IN_ADDR* Address, uint16 Port, char16* AddressString, uint32* AddressStringLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv4StringToAddressA(PSTR S, BOOLEAN Strict, PSTR* Terminator, IN_ADDR* Addr);
	public static int32 RtlIpv4StringToAddress(PSTR S, BOOLEAN Strict, PSTR* Terminator, IN_ADDR* Addr) => RtlIpv4StringToAddressA(S, Strict, Terminator, Addr);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv4StringToAddressExA(PSTR AddressString, BOOLEAN Strict, IN_ADDR* Address, uint16* Port);
	public static int32 RtlIpv4StringToAddressEx(PSTR AddressString, BOOLEAN Strict, IN_ADDR* Address, uint16* Port) => RtlIpv4StringToAddressExA(AddressString, Strict, Address, Port);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv4StringToAddressW(PWSTR S, BOOLEAN Strict, PWSTR* Terminator, IN_ADDR* Addr);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv4StringToAddressExW(PWSTR AddressString, BOOLEAN Strict, IN_ADDR* Address, uint16* Port);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR RtlIpv6AddressToStringA(IN6_ADDR* Addr, uint8* S);
	public static PSTR RtlIpv6AddressToString(IN6_ADDR* Addr, uint8* S) => RtlIpv6AddressToStringA(Addr, S);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv6AddressToStringExA(IN6_ADDR* Address, uint32 ScopeId, uint16 Port, uint8* AddressString, uint32* AddressStringLength);
	public static int32 RtlIpv6AddressToStringEx(IN6_ADDR* Address, uint32 ScopeId, uint16 Port, uint8* AddressString, uint32* AddressStringLength) => RtlIpv6AddressToStringExA(Address, ScopeId, Port, AddressString, AddressStringLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR RtlIpv6AddressToStringW(IN6_ADDR* Addr, char16* S);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv6AddressToStringExW(IN6_ADDR* Address, uint32 ScopeId, uint16 Port, char16* AddressString, uint32* AddressStringLength);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv6StringToAddressA(PSTR S, PSTR* Terminator, IN6_ADDR* Addr);
	public static int32 RtlIpv6StringToAddress(PSTR S, PSTR* Terminator, IN6_ADDR* Addr) => RtlIpv6StringToAddressA(S, Terminator, Addr);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv6StringToAddressExA(PSTR AddressString, IN6_ADDR* Address, uint32* ScopeId, uint16* Port);
	public static int32 RtlIpv6StringToAddressEx(PSTR AddressString, IN6_ADDR* Address, uint32* ScopeId, uint16* Port) => RtlIpv6StringToAddressExA(AddressString, Address, ScopeId, Port);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv6StringToAddressW(PWSTR S, PWSTR* Terminator, IN6_ADDR* Addr);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlIpv6StringToAddressExW(PWSTR AddressString, IN6_ADDR* Address, uint32* ScopeId, uint16* Port);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR RtlEthernetAddressToStringA(DL_EUI48* Addr, uint8* S);
	public static PSTR RtlEthernetAddressToString(DL_EUI48* Addr, uint8* S) => RtlEthernetAddressToStringA(Addr, S);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR RtlEthernetAddressToStringW(DL_EUI48* Addr, char16* S);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlEthernetStringToAddressA(PSTR S, PSTR* Terminator, DL_EUI48* Addr);
	public static int32 RtlEthernetStringToAddress(PSTR S, PSTR* Terminator, DL_EUI48* Addr) => RtlEthernetStringToAddressA(S, Terminator, Addr);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RtlEthernetStringToAddressW(PWSTR S, PWSTR* Terminator, DL_EUI48* Addr);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSARecvEx(SOCKET s, PSTR buf, int32 len, int32* flags);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TransmitFile(SOCKET hSocket, HANDLE hFile, uint32 nNumberOfBytesToWrite, uint32 nNumberOfBytesPerSend, OVERLAPPED* lpOverlapped, TRANSMIT_FILE_BUFFERS* lpTransmitBuffers, uint32 dwReserved);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AcceptEx(SOCKET sListenSocket, SOCKET sAcceptSocket, void* lpOutputBuffer, uint32 dwReceiveDataLength, uint32 dwLocalAddressLength, uint32 dwRemoteAddressLength, uint32* lpdwBytesReceived, OVERLAPPED* lpOverlapped);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void GetAcceptExSockaddrs(void* lpOutputBuffer, uint32 dwReceiveDataLength, uint32 dwLocalAddressLength, uint32 dwRemoteAddressLength, SOCKADDR** LocalSockaddr, int32* LocalSockaddrLength, SOCKADDR** RemoteSockaddr, int32* RemoteSockaddrLength);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCEnumProtocols(int32* lpiProtocols, WSAPROTOCOL_INFOW* lpProtocolBuffer, uint32* lpdwBufferLength, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCDeinstallProvider(Guid* lpProviderId, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallProvider(Guid* lpProviderId, PWSTR lpszProviderDllPath, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCGetProviderPath(Guid* lpProviderId, char16* lpszProviderDllPath, int32* lpProviderDllPathLen, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCUpdateProvider(Guid* lpProviderId, PWSTR lpszProviderDllPath, WSAPROTOCOL_INFOW* lpProtocolInfoList, uint32 dwNumberOfEntries, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCSetProviderInfo(Guid* lpProviderId, WSC_PROVIDER_INFO_TYPE InfoType, uint8* Info, uint InfoSize, uint32 Flags, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCGetProviderInfo(Guid* lpProviderId, WSC_PROVIDER_INFO_TYPE InfoType, uint8* Info, uint* InfoSize, uint32 Flags, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCSetApplicationCategory(char16* Path, uint32 PathLength, char16* Extra, uint32 ExtraLength, uint32 PermittedLspCategories, uint32* pPrevPermLspCat, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCGetApplicationCategory(char16* Path, uint32 PathLength, char16* Extra, uint32 ExtraLength, uint32* pPermittedLspCategories, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WPUCompleteOverlappedRequest(SOCKET s, OVERLAPPED* lpOverlapped, uint32 dwError, uint32 cbTransferred, int32* lpErrno);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallNameSpace(PWSTR lpszIdentifier, PWSTR lpszPathName, uint32 dwNameSpace, uint32 dwVersion, Guid* lpProviderId);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCUnInstallNameSpace(Guid* lpProviderId);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCInstallNameSpaceEx(PWSTR lpszIdentifier, PWSTR lpszPathName, uint32 dwNameSpace, uint32 dwVersion, Guid* lpProviderId, BLOB* lpProviderSpecific);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCEnableNSProvider(Guid* lpProviderId, BOOL fEnable);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAAdvertiseProvider(in Guid puuidProviderId, NSPV2_ROUTINE* pNSPv2Routine);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAUnadvertiseProvider(in Guid puuidProviderId);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAProviderCompleteAsyncCall(HANDLE hAsyncCall, int32 iRetCode);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumProtocolsA(int32* lpiProtocols, void* lpProtocolBuffer, uint32* lpdwBufferLength);
	public static int32 EnumProtocols(int32* lpiProtocols, void* lpProtocolBuffer, uint32* lpdwBufferLength) => EnumProtocolsA(lpiProtocols, lpProtocolBuffer, lpdwBufferLength);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumProtocolsW(int32* lpiProtocols, void* lpProtocolBuffer, uint32* lpdwBufferLength);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddressByNameA(uint32 dwNameSpace, Guid* lpServiceType, PSTR lpServiceName, int32* lpiProtocols, uint32 dwResolution, SERVICE_ASYNC_INFO* lpServiceAsyncInfo, void* lpCsaddrBuffer, uint32* lpdwBufferLength, uint8* lpAliasBuffer, uint32* lpdwAliasBufferLength);
	public static int32 GetAddressByName(uint32 dwNameSpace, Guid* lpServiceType, PSTR lpServiceName, int32* lpiProtocols, uint32 dwResolution, SERVICE_ASYNC_INFO* lpServiceAsyncInfo, void* lpCsaddrBuffer, uint32* lpdwBufferLength, uint8* lpAliasBuffer, uint32* lpdwAliasBufferLength) => GetAddressByNameA(dwNameSpace, lpServiceType, lpServiceName, lpiProtocols, dwResolution, lpServiceAsyncInfo, lpCsaddrBuffer, lpdwBufferLength, lpAliasBuffer, lpdwAliasBufferLength);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddressByNameW(uint32 dwNameSpace, Guid* lpServiceType, PWSTR lpServiceName, int32* lpiProtocols, uint32 dwResolution, SERVICE_ASYNC_INFO* lpServiceAsyncInfo, void* lpCsaddrBuffer, uint32* lpdwBufferLength, char16* lpAliasBuffer, uint32* lpdwAliasBufferLength);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTypeByNameA(PSTR lpServiceName, Guid* lpServiceType);
	public static int32 GetTypeByName(PSTR lpServiceName, Guid* lpServiceType) => GetTypeByNameA(lpServiceName, lpServiceType);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTypeByNameW(PWSTR lpServiceName, Guid* lpServiceType);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNameByTypeA(Guid* lpServiceType, PSTR lpServiceName, uint32 dwNameLength);
	public static int32 GetNameByType(Guid* lpServiceType, PSTR lpServiceName, uint32 dwNameLength) => GetNameByTypeA(lpServiceType, lpServiceName, dwNameLength);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNameByTypeW(Guid* lpServiceType, PWSTR lpServiceName, uint32 dwNameLength);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetServiceA(uint32 dwNameSpace, SET_SERVICE_OPERATION dwOperation, uint32 dwFlags, SERVICE_INFOA* lpServiceInfo, SERVICE_ASYNC_INFO* lpServiceAsyncInfo, uint32* lpdwStatusFlags);
	public static int32 SetService(uint32 dwNameSpace, SET_SERVICE_OPERATION dwOperation, uint32 dwFlags, SERVICE_INFOA* lpServiceInfo, SERVICE_ASYNC_INFO* lpServiceAsyncInfo, uint32* lpdwStatusFlags) => SetServiceA(dwNameSpace, dwOperation, dwFlags, lpServiceInfo, lpServiceAsyncInfo, lpdwStatusFlags);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetServiceW(uint32 dwNameSpace, SET_SERVICE_OPERATION dwOperation, uint32 dwFlags, SERVICE_INFOW* lpServiceInfo, SERVICE_ASYNC_INFO* lpServiceAsyncInfo, uint32* lpdwStatusFlags);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetServiceA(uint32 dwNameSpace, Guid* lpGuid, PSTR lpServiceName, uint32 dwProperties, void* lpBuffer, uint32* lpdwBufferSize, SERVICE_ASYNC_INFO* lpServiceAsyncInfo);
	public static int32 GetService(uint32 dwNameSpace, Guid* lpGuid, PSTR lpServiceName, uint32 dwProperties, void* lpBuffer, uint32* lpdwBufferSize, SERVICE_ASYNC_INFO* lpServiceAsyncInfo) => GetServiceA(dwNameSpace, lpGuid, lpServiceName, dwProperties, lpBuffer, lpdwBufferSize, lpServiceAsyncInfo);

	[Import("MSWSOCK.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetServiceW(uint32 dwNameSpace, Guid* lpGuid, PWSTR lpServiceName, uint32 dwProperties, void* lpBuffer, uint32* lpdwBufferSize, SERVICE_ASYNC_INFO* lpServiceAsyncInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 getaddrinfo(PSTR pNodeName, PSTR pServiceName, ADDRINFOA* pHints, ADDRINFOA** ppResult);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddrInfoW(PWSTR pNodeName, PWSTR pServiceName, ADDRINFOW* pHints, ADDRINFOW** ppResult);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddrInfoExA(PSTR pName, PSTR pServiceName, uint32 dwNameSpace, Guid* lpNspId, ADDRINFOEXA* hints, ADDRINFOEXA** ppResult, TIMEVAL* timeout, OVERLAPPED* lpOverlapped, LPLOOKUPSERVICE_COMPLETION_ROUTINE lpCompletionRoutine, HANDLE* lpNameHandle);
	public static int32 GetAddrInfoEx(PSTR pName, PSTR pServiceName, uint32 dwNameSpace, Guid* lpNspId, ADDRINFOEXA* hints, ADDRINFOEXA** ppResult, TIMEVAL* timeout, OVERLAPPED* lpOverlapped, LPLOOKUPSERVICE_COMPLETION_ROUTINE lpCompletionRoutine, HANDLE* lpNameHandle) => GetAddrInfoExA(pName, pServiceName, dwNameSpace, lpNspId, hints, ppResult, timeout, lpOverlapped, lpCompletionRoutine, lpNameHandle);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddrInfoExW(PWSTR pName, PWSTR pServiceName, uint32 dwNameSpace, Guid* lpNspId, ADDRINFOEXW* hints, ADDRINFOEXW** ppResult, TIMEVAL* timeout, OVERLAPPED* lpOverlapped, LPLOOKUPSERVICE_COMPLETION_ROUTINE lpCompletionRoutine, HANDLE* lpHandle);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddrInfoExCancel(HANDLE* lpHandle);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetAddrInfoExOverlappedResult(OVERLAPPED* lpOverlapped);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetAddrInfoExA(PSTR pName, PSTR pServiceName, SOCKET_ADDRESS* pAddresses, uint32 dwAddressCount, BLOB* lpBlob, uint32 dwFlags, uint32 dwNameSpace, Guid* lpNspId, TIMEVAL* timeout, OVERLAPPED* lpOverlapped, LPLOOKUPSERVICE_COMPLETION_ROUTINE lpCompletionRoutine, HANDLE* lpNameHandle);
	public static int32 SetAddrInfoEx(PSTR pName, PSTR pServiceName, SOCKET_ADDRESS* pAddresses, uint32 dwAddressCount, BLOB* lpBlob, uint32 dwFlags, uint32 dwNameSpace, Guid* lpNspId, TIMEVAL* timeout, OVERLAPPED* lpOverlapped, LPLOOKUPSERVICE_COMPLETION_ROUTINE lpCompletionRoutine, HANDLE* lpNameHandle) => SetAddrInfoExA(pName, pServiceName, pAddresses, dwAddressCount, lpBlob, dwFlags, dwNameSpace, lpNspId, timeout, lpOverlapped, lpCompletionRoutine, lpNameHandle);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetAddrInfoExW(PWSTR pName, PWSTR pServiceName, SOCKET_ADDRESS* pAddresses, uint32 dwAddressCount, BLOB* lpBlob, uint32 dwFlags, uint32 dwNameSpace, Guid* lpNspId, TIMEVAL* timeout, OVERLAPPED* lpOverlapped, LPLOOKUPSERVICE_COMPLETION_ROUTINE lpCompletionRoutine, HANDLE* lpNameHandle);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void freeaddrinfo(ADDRINFOA* pAddrInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeAddrInfoW(ADDRINFOW* pAddrInfo);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeAddrInfoEx(ADDRINFOEXA* pAddrInfoEx);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeAddrInfoExW(ADDRINFOEXW* pAddrInfoEx);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 getnameinfo(SOCKADDR* pSockaddr, int32 SockaddrLength, uint8* pNodeBuffer, uint32 NodeBufferSize, uint8* pServiceBuffer, uint32 ServiceBufferSize, int32 Flags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNameInfoW(SOCKADDR* pSockaddr, int32 SockaddrLength, char16* pNodeBuffer, uint32 NodeBufferSize, char16* pServiceBuffer, uint32 ServiceBufferSize, int32 Flags);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 inet_pton(int32 Family, PSTR pszAddrString, void* pAddrBuf);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 InetPtonW(int32 Family, PWSTR pszAddrString, void* pAddrBuf);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR inet_ntop(int32 Family, void* pAddr, uint8* pStringBuf, uint StringBufSize);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR InetNtopW(int32 Family, void* pAddr, char16* pStringBuf, uint StringBufSize);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASetSocketSecurity(SOCKET Socket, SOCKET_SECURITY_SETTINGS* SecuritySettings, uint32 SecuritySettingsLen, OVERLAPPED* Overlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE CompletionRoutine);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAQuerySocketSecurity(SOCKET Socket, SOCKET_SECURITY_QUERY_TEMPLATE* SecurityQueryTemplate, uint32 SecurityQueryTemplateLen, SOCKET_SECURITY_QUERY_INFO* SecurityQueryInfo, uint32* SecurityQueryInfoLen, OVERLAPPED* Overlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE CompletionRoutine);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSASetSocketPeerTargetName(SOCKET Socket, SOCKET_PEER_TARGET_NAME* PeerTargetName, uint32 PeerTargetNameLen, OVERLAPPED* Overlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE CompletionRoutine);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSADeleteSocketPeerTargetName(SOCKET Socket, SOCKADDR* PeerAddr, uint32 PeerAddrLen, OVERLAPPED* Overlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE CompletionRoutine);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSAImpersonateSocketPeer(SOCKET Socket, SOCKADDR* PeerAddr, uint32 PeerAddrLen);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSARevertImpersonation();

	[Import("Windows.Networking.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetSocketMediaStreamingMode(BOOL value);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCWriteProviderOrder(uint32* lpwdCatalogEntryId, uint32 dwNumberOfEntries);

	[Import("WS2_32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WSCWriteNameSpaceOrder(Guid* lpProviderId, uint32 dwNumberOfEntries);

}
#endregion
