using Win32.Security;
using Win32.Foundation;
using Win32.System.Rpc;
using System;

namespace Win32.NetworkManagement.WindowsFilteringPlatform;

#region Constants
public static
{
	public const uint32 FWPM_NET_EVENT_KEYWORD_INBOUND_MCAST = 1;
	public const uint32 FWPM_NET_EVENT_KEYWORD_INBOUND_BCAST = 2;
	public const uint32 FWPM_NET_EVENT_KEYWORD_CAPABILITY_DROP = 4;
	public const uint32 FWPM_NET_EVENT_KEYWORD_CAPABILITY_ALLOW = 8;
	public const uint32 FWPM_NET_EVENT_KEYWORD_CLASSIFY_ALLOW = 16;
	public const uint32 FWPM_NET_EVENT_KEYWORD_PORT_SCANNING_DROP = 32;
	public const uint32 FWPM_ENGINE_OPTION_PACKET_QUEUE_NONE = 0;
	public const uint32 FWPM_ENGINE_OPTION_PACKET_QUEUE_INBOUND = 1;
	public const uint32 FWPM_ENGINE_OPTION_PACKET_QUEUE_FORWARD = 2;
	public const uint32 FWPM_ENGINE_OPTION_PACKET_BATCH_INBOUND = 4;
	public const uint32 FWPM_SESSION_FLAG_DYNAMIC = 1;
	public const uint32 FWPM_SESSION_FLAG_RESERVED = 268435456;
	public const uint32 FWPM_PROVIDER_FLAG_PERSISTENT = 1;
	public const uint32 FWPM_PROVIDER_FLAG_DISABLED = 16;
	public const uint32 FWPM_PROVIDER_CONTEXT_FLAG_PERSISTENT = 1;
	public const uint32 FWPM_PROVIDER_CONTEXT_FLAG_DOWNLEVEL = 2;
	public const uint32 FWPM_SUBLAYER_FLAG_PERSISTENT = 1;
	public const uint32 FWPM_LAYER_FLAG_KERNEL = 1;
	public const uint32 FWPM_LAYER_FLAG_BUILTIN = 2;
	public const uint32 FWPM_LAYER_FLAG_CLASSIFY_MOSTLY = 4;
	public const uint32 FWPM_LAYER_FLAG_BUFFERED = 8;
	public const uint32 FWPM_CALLOUT_FLAG_PERSISTENT = 65536;
	public const uint32 FWPM_CALLOUT_FLAG_USES_PROVIDER_CONTEXT = 131072;
	public const uint32 FWPM_CALLOUT_FLAG_REGISTERED = 262144;
	public const uint32 FWPM_FILTER_FLAG_HAS_SECURITY_REALM_PROVIDER_CONTEXT = 128;
	public const uint32 FWPM_FILTER_FLAG_SYSTEMOS_ONLY = 256;
	public const uint32 FWPM_FILTER_FLAG_GAMEOS_ONLY = 512;
	public const uint32 FWPM_FILTER_FLAG_SILENT_MODE = 1024;
	public const uint32 FWPM_FILTER_FLAG_IPSEC_NO_ACQUIRE_INITIATE = 2048;
	public const uint32 FWPM_FILTER_FLAG_RESERVED0 = 4096;
	public const uint32 FWPM_FILTER_FLAG_RESERVED1 = 8192;
	public const uint32 FWPM_NET_EVENT_FLAG_IP_PROTOCOL_SET = 1;
	public const uint32 FWPM_NET_EVENT_FLAG_LOCAL_ADDR_SET = 2;
	public const uint32 FWPM_NET_EVENT_FLAG_REMOTE_ADDR_SET = 4;
	public const uint32 FWPM_NET_EVENT_FLAG_LOCAL_PORT_SET = 8;
	public const uint32 FWPM_NET_EVENT_FLAG_REMOTE_PORT_SET = 16;
	public const uint32 FWPM_NET_EVENT_FLAG_APP_ID_SET = 32;
	public const uint32 FWPM_NET_EVENT_FLAG_USER_ID_SET = 64;
	public const uint32 FWPM_NET_EVENT_FLAG_SCOPE_ID_SET = 128;
	public const uint32 FWPM_NET_EVENT_FLAG_IP_VERSION_SET = 256;
	public const uint32 FWPM_NET_EVENT_FLAG_REAUTH_REASON_SET = 512;
	public const uint32 FWPM_NET_EVENT_FLAG_PACKAGE_ID_SET = 1024;
	public const uint32 FWPM_NET_EVENT_FLAG_ENTERPRISE_ID_SET = 2048;
	public const uint32 FWPM_NET_EVENT_FLAG_POLICY_FLAGS_SET = 4096;
	public const uint32 FWPM_NET_EVENT_FLAG_EFFECTIVE_NAME_SET = 8192;
	public const uint32 IKEEXT_CERT_HASH_LEN = 20;
	public const uint32 FWPM_NET_EVENT_IKEEXT_MM_FAILURE_FLAG_BENIGN = 1;
	public const uint32 FWPM_NET_EVENT_IKEEXT_MM_FAILURE_FLAG_MULTIPLE = 2;
	public const uint32 FWPM_NET_EVENT_IKEEXT_EM_FAILURE_FLAG_MULTIPLE = 1;
	public const uint32 FWPM_NET_EVENT_IKEEXT_EM_FAILURE_FLAG_BENIGN = 2;
	public const uint32 FWPM_CONNECTION_ENUM_FLAG_QUERY_BYTES_TRANSFERRED = 1;
	public const uint32 FWPS_FILTER_FLAG_CLEAR_ACTION_RIGHT = 1;
	public const uint32 FWPS_FILTER_FLAG_PERMIT_IF_CALLOUT_UNREGISTERED = 2;
	public const uint32 FWPS_FILTER_FLAG_OR_CONDITIONS = 4;
	public const uint32 FWPS_FILTER_FLAG_HAS_SECURITY_REALM_PROVIDER_CONTEXT = 8;
	public const uint32 FWPS_FILTER_FLAG_SILENT_MODE = 16;
	public const uint32 FWPS_FILTER_FLAG_IPSEC_NO_ACQUIRE_INITIATE = 32;
	public const uint32 FWPS_FILTER_FLAG_RESERVED0 = 64;
	public const uint32 FWPS_FILTER_FLAG_RESERVED1 = 128;
	public const uint32 FWPS_INCOMING_FLAG_CACHE_SAFE = 1;
	public const uint32 FWPS_INCOMING_FLAG_ENFORCE_QUERY = 2;
	public const uint32 FWPS_INCOMING_FLAG_ABSORB = 4;
	public const uint32 FWPS_INCOMING_FLAG_CONNECTION_FAILING_INDICATION = 8;
	public const uint32 FWPS_INCOMING_FLAG_MID_STREAM_INSPECTION = 16;
	public const uint32 FWPS_INCOMING_FLAG_RECLASSIFY = 32;
	public const uint32 FWPS_INCOMING_FLAG_IS_LOOSE_SOURCE_FLOW = 64;
	public const uint32 FWPS_INCOMING_FLAG_IS_LOCAL_ONLY_FLOW = 128;
	public const uint32 FWPS_L2_INCOMING_FLAG_IS_RAW_IPV4_FRAMING = 1;
	public const uint32 FWPS_L2_INCOMING_FLAG_IS_RAW_IPV6_FRAMING = 2;
	public const uint32 FWPS_L2_INCOMING_FLAG_RECLASSIFY_MULTI_DESTINATION = 8;
	public const uint32 FWPS_INCOMING_FLAG_RESERVED0 = 256;
	public const uint32 FWPS_RIGHT_ACTION_WRITE = 1;
	public const uint32 FWPS_CLASSIFY_OUT_FLAG_ABSORB = 1;
	public const uint32 FWPS_CLASSIFY_OUT_FLAG_BUFFER_LIMIT_REACHED = 2;
	public const uint32 FWPS_CLASSIFY_OUT_FLAG_NO_MORE_DATA = 4;
	public const uint32 FWPS_CLASSIFY_OUT_FLAG_ALE_FAST_CACHE_CHECK = 8;
	public const uint32 FWPS_CLASSIFY_OUT_FLAG_ALE_FAST_CACHE_POSSIBLE = 16;
	public const uint32 FWPS_ALE_ENDPOINT_FLAG_IPSEC_SECURED = 1;
	public const uint32 FWP_BYTEMAP_ARRAY64_SIZE = 8;
	public const uint32 FWP_BYTE_ARRAY6_SIZE = 6;
	public const uint32 FWP_V6_ADDR_SIZE = 16;
	public const uint32 FWP_ACTRL_MATCH_FILTER = 1;
	public const uint32 FWP_OPTION_VALUE_ALLOW_MULTICAST_STATE = 0;
	public const uint32 FWP_OPTION_VALUE_DENY_MULTICAST_STATE = 1;
	public const uint32 FWP_OPTION_VALUE_ALLOW_GLOBAL_MULTICAST_STATE = 2;
	public const uint32 FWP_OPTION_VALUE_DISABLE_LOOSE_SOURCE = 0;
	public const uint32 FWP_OPTION_VALUE_ENABLE_LOOSE_SOURCE = 1;
	public const uint32 FWP_OPTION_VALUE_DISABLE_LOCAL_ONLY_MAPPING = 0;
	public const uint32 FWP_OPTION_VALUE_ENABLE_LOCAL_ONLY_MAPPING = 1;
	public const uint32 FWP_ACTION_FLAG_TERMINATING = 4096;
	public const uint32 FWP_ACTION_FLAG_NON_TERMINATING = 8192;
	public const uint32 FWP_ACTION_FLAG_CALLOUT = 16384;
	public const uint32 FWP_ACTION_NONE = 7;
	public const uint32 FWP_ACTION_NONE_NO_MATCH = 8;
	public const uint32 FWP_CONDITION_FLAG_IS_LOOPBACK = 1;
	public const uint32 FWP_CONDITION_FLAG_IS_IPSEC_SECURED = 2;
	public const uint32 FWP_CONDITION_FLAG_IS_REAUTHORIZE = 4;
	public const uint32 FWP_CONDITION_FLAG_IS_WILDCARD_BIND = 8;
	public const uint32 FWP_CONDITION_FLAG_IS_RAW_ENDPOINT = 16;
	public const uint32 FWP_CONDITION_FLAG_IS_FRAGMENT = 32;
	public const uint32 FWP_CONDITION_FLAG_IS_FRAGMENT_GROUP = 64;
	public const uint32 FWP_CONDITION_FLAG_IS_IPSEC_NATT_RECLASSIFY = 128;
	public const uint32 FWP_CONDITION_FLAG_REQUIRES_ALE_CLASSIFY = 256;
	public const uint32 FWP_CONDITION_FLAG_IS_IMPLICIT_BIND = 512;
	public const uint32 FWP_CONDITION_FLAG_IS_REASSEMBLED = 1024;
	public const uint32 FWP_CONDITION_FLAG_IS_NAME_APP_SPECIFIED = 16384;
	public const uint32 FWP_CONDITION_FLAG_IS_PROMISCUOUS = 32768;
	public const uint32 FWP_CONDITION_FLAG_IS_AUTH_FW = 65536;
	public const uint32 FWP_CONDITION_FLAG_IS_RECLASSIFY = 131072;
	public const uint32 FWP_CONDITION_FLAG_IS_OUTBOUND_PASS_THRU = 262144;
	public const uint32 FWP_CONDITION_FLAG_IS_INBOUND_PASS_THRU = 524288;
	public const uint32 FWP_CONDITION_FLAG_IS_CONNECTION_REDIRECTED = 1048576;
	public const uint32 FWP_CONDITION_FLAG_IS_PROXY_CONNECTION = 2097152;
	public const uint32 FWP_CONDITION_FLAG_IS_APPCONTAINER_LOOPBACK = 4194304;
	public const uint32 FWP_CONDITION_FLAG_IS_NON_APPCONTAINER_LOOPBACK = 8388608;
	public const uint32 FWP_CONDITION_FLAG_IS_RESERVED = 16777216;
	public const uint32 FWP_CONDITION_FLAG_IS_HONORING_POLICY_AUTHORIZE = 33554432;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_POLICY_CHANGE = 1;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_NEW_ARRIVAL_INTERFACE = 2;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_NEW_NEXTHOP_INTERFACE = 4;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_PROFILE_CROSSING = 8;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_CLASSIFY_COMPLETION = 16;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_IPSEC_PROPERTIES_CHANGED = 32;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_MID_STREAM_INSPECTION = 64;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_SOCKET_PROPERTY_CHANGED = 128;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_NEW_INBOUND_MCAST_BCAST_PACKET = 256;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_EDP_POLICY_CHANGED = 512;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_PROXY_HANDLE_CHANGED = 16384;
	public const uint32 FWP_CONDITION_REAUTHORIZE_REASON_CHECK_OFFLOAD = 65536;
	public const uint32 FWP_CONDITION_SOCKET_PROPERTY_FLAG_IS_SYSTEM_PORT_RPC = 1;
	public const uint32 FWP_CONDITION_SOCKET_PROPERTY_FLAG_ALLOW_EDGE_TRAFFIC = 2;
	public const uint32 FWP_CONDITION_SOCKET_PROPERTY_FLAG_DENY_EDGE_TRAFFIC = 4;
	public const uint32 FWP_CONDITION_L2_IS_NATIVE_ETHERNET = 1;
	public const uint32 FWP_CONDITION_L2_IS_WIFI = 2;
	public const uint32 FWP_CONDITION_L2_IS_MOBILE_BROADBAND = 4;
	public const uint32 FWP_CONDITION_L2_IS_WIFI_DIRECT_DATA = 8;
	public const uint32 FWP_CONDITION_L2_IS_VM2VM = 16;
	public const uint32 FWP_CONDITION_L2_IS_MALFORMED_PACKET = 32;
	public const uint32 FWP_CONDITION_L2_IS_IP_FRAGMENT_GROUP = 64;
	public const uint32 FWP_CONDITION_L2_IF_CONNECTOR_PRESENT = 128;
	public const uint32 FWP_FILTER_ENUM_FLAG_BEST_TERMINATING_MATCH = 1;
	public const uint32 FWP_FILTER_ENUM_FLAG_SORTED = 2;
	public const uint32 FWP_FILTER_ENUM_FLAG_BOOTTIME_ONLY = 4;
	public const uint32 FWP_FILTER_ENUM_FLAG_INCLUDE_BOOTTIME = 8;
	public const uint32 FWP_FILTER_ENUM_FLAG_INCLUDE_DISABLED = 16;
	public const uint32 FWP_FILTER_ENUM_FLAG_RESERVED1 = 32;
	public const uint32 FWP_CALLOUT_FLAG_CONDITIONAL_ON_FLOW = 1;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_OFFLOAD = 2;
	public const uint32 FWP_CALLOUT_FLAG_ENABLE_COMMIT_ADD_NOTIFY = 4;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_MID_STREAM_INSPECTION = 8;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_RECLASSIFY = 16;
	public const uint32 FWP_CALLOUT_FLAG_RESERVED1 = 32;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_RSC = 64;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_L2_BATCH_CLASSIFY = 128;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_USO = 256;
	public const uint32 FWP_CALLOUT_FLAG_ALLOW_URO = 512;
	public const uint32 FWP_CALLOUT_FLAG_RESERVED2 = 1024;
	public const uint32 IKEEXT_CERT_AUTH_FLAG_DISABLE_CRL_CHECK = 2;
	public const uint32 IKEEXT_CERT_AUTH_FLAG_DISABLE_REQUEST_PAYLOAD = 64;
	public const uint32 IKEEXT_KERB_AUTH_FORCE_PROXY_ON_INITIATOR = 4;
	public const uint32 IKEEXT_NTLM_V2_AUTH_DONT_ACCEPT_EXPLICIT_CREDENTIALS = 1;
	public const uint32 IKEEXT_POLICY_FLAG_MOBIKE_NOT_SUPPORTED = 16;
	public const uint32 IKEEXT_POLICY_FLAG_SITE_TO_SITE = 32;
	public const uint32 IKEEXT_POLICY_FLAG_IMS_VPN = 64;
	public const uint32 IKEEXT_POLICY_ENABLE_IKEV2_FRAGMENTATION = 128;
	public const uint32 IKEEXT_POLICY_SUPPORT_LOW_POWER_MODE = 256;
	public const uint32 IKEEXT_CERT_CREDENTIAL_FLAG_NAP_CERT = 1;
	public const uint32 IPSEC_AUTH_CONFIG_HMAC_MD5_96 = 0;
	public const uint32 IPSEC_AUTH_CONFIG_HMAC_SHA_1_96 = 1;
	public const uint32 IPSEC_AUTH_CONFIG_HMAC_SHA_256_128 = 2;
	public const uint32 IPSEC_AUTH_CONFIG_GCM_AES_128 = 3;
	public const uint32 IPSEC_AUTH_CONFIG_GCM_AES_192 = 4;
	public const uint32 IPSEC_AUTH_CONFIG_GCM_AES_256 = 5;
	public const uint32 IPSEC_AUTH_CONFIG_MAX = 6;
	public const uint32 IPSEC_CIPHER_CONFIG_CBC_DES = 1;
	public const uint32 IPSEC_CIPHER_CONFIG_CBC_3DES = 2;
	public const uint32 IPSEC_CIPHER_CONFIG_CBC_AES_128 = 3;
	public const uint32 IPSEC_CIPHER_CONFIG_CBC_AES_192 = 4;
	public const uint32 IPSEC_CIPHER_CONFIG_CBC_AES_256 = 5;
	public const uint32 IPSEC_CIPHER_CONFIG_GCM_AES_128 = 6;
	public const uint32 IPSEC_CIPHER_CONFIG_GCM_AES_192 = 7;
	public const uint32 IPSEC_CIPHER_CONFIG_GCM_AES_256 = 8;
	public const uint32 IPSEC_CIPHER_CONFIG_MAX = 9;
	public const uint32 IPSEC_POLICY_FLAG_KEY_MANAGER_ALLOW_NOTIFY_KEY = 16384;
	public const uint32 IPSEC_POLICY_FLAG_RESERVED1 = 32768;
	public const uint32 IPSEC_POLICY_FLAG_SITE_TO_SITE_TUNNEL = 65536;
	public const uint32 IPSEC_KEYING_POLICY_FLAG_TERMINATING_MATCH = 1;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_NLB = 16;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_NO_MACHINE_LUID_VERIFY = 32;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_NO_IMPERSONATION_LUID_VERIFY = 64;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_NO_EXPLICIT_CRED_MATCH = 128;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_FORCE_INBOUND_CONNECTIONS = 32768;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_FORCE_OUTBOUND_CONNECTIONS = 65536;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_FORWARD_PATH_INITIATOR = 131072;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_ENABLE_OPTIONAL_ASYMMETRIC_IDLE = 262144;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_USING_DICTATED_KEYS = 524288;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_LOCALLY_DICTATED_KEYS = 1048576;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_SA_OFFLOADED = 2097152;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_IP_IN_IP_PKT = 4194304;
	public const uint32 IPSEC_SA_BUNDLE_FLAG_LOW_POWER_MODE_SUPPORT = 8388608;
	public const uint32 IPSEC_DOSP_DSCP_DISABLE_VALUE = 255;
	public const uint32 IPSEC_DOSP_RATE_LIMIT_DISABLE_VALUE = 0;
	public const uint32 IPSEC_KEY_MANAGER_FLAG_DICTATE_KEY = 1;
	public const Guid FWPM_LAYER_INBOUND_IPPACKET_V4 = .(0xc86fd1bf, 0x21cd, 0x497e, 0xa0, 0xbb, 0x17, 0x42, 0x5c, 0x88, 0x5c, 0x58);
	public const Guid FWPM_LAYER_INBOUND_IPPACKET_V4_DISCARD = .(0xb5a230d0, 0xa8c0, 0x44f2, 0x91, 0x6e, 0x99, 0x1b, 0x53, 0xde, 0xd1, 0xf7);
	public const Guid FWPM_LAYER_INBOUND_IPPACKET_V6 = .(0xf52032cb, 0x991c, 0x46e7, 0x97, 0x1d, 0x26, 0x01, 0x45, 0x9a, 0x91, 0xca);
	public const Guid FWPM_LAYER_INBOUND_IPPACKET_V6_DISCARD = .(0xbb24c279, 0x93b4, 0x47a2, 0x83, 0xad, 0xae, 0x16, 0x98, 0xb5, 0x08, 0x85);
	public const Guid FWPM_LAYER_OUTBOUND_IPPACKET_V4 = .(0x1e5c9fae, 0x8a84, 0x4135, 0xa3, 0x31, 0x95, 0x0b, 0x54, 0x22, 0x9e, 0xcd);
	public const Guid FWPM_LAYER_OUTBOUND_IPPACKET_V4_DISCARD = .(0x08e4bcb5, 0xb647, 0x48f3, 0x95, 0x3c, 0xe5, 0xdd, 0xbd, 0x03, 0x93, 0x7e);
	public const Guid FWPM_LAYER_OUTBOUND_IPPACKET_V6 = .(0xa3b3ab6b, 0x3564, 0x488c, 0x91, 0x17, 0xf3, 0x4e, 0x82, 0x14, 0x27, 0x63);
	public const Guid FWPM_LAYER_OUTBOUND_IPPACKET_V6_DISCARD = .(0x9513d7c4, 0xa934, 0x49dc, 0x91, 0xa7, 0x6c, 0xcb, 0x80, 0xcc, 0x02, 0xe3);
	public const Guid FWPM_LAYER_IPFORWARD_V4 = .(0xa82acc24, 0x4ee1, 0x4ee1, 0xb4, 0x65, 0xfd, 0x1d, 0x25, 0xcb, 0x10, 0xa4);
	public const Guid FWPM_LAYER_IPFORWARD_V4_DISCARD = .(0x9e9ea773, 0x2fae, 0x4210, 0x8f, 0x17, 0x34, 0x12, 0x9e, 0xf3, 0x69, 0xeb);
	public const Guid FWPM_LAYER_IPFORWARD_V6 = .(0x7b964818, 0x19c7, 0x493a, 0xb7, 0x1f, 0x83, 0x2c, 0x36, 0x84, 0xd2, 0x8c);
	public const Guid FWPM_LAYER_IPFORWARD_V6_DISCARD = .(0x31524a5d, 0x1dfe, 0x472f, 0xbb, 0x93, 0x51, 0x8e, 0xe9, 0x45, 0xd8, 0xa2);
	public const Guid FWPM_LAYER_INBOUND_TRANSPORT_V4 = .(0x5926dfc8, 0xe3cf, 0x4426, 0xa2, 0x83, 0xdc, 0x39, 0x3f, 0x5d, 0x0f, 0x9d);
	public const Guid FWPM_LAYER_INBOUND_TRANSPORT_V4_DISCARD = .(0xac4a9833, 0xf69d, 0x4648, 0xb2, 0x61, 0x6d, 0xc8, 0x48, 0x35, 0xef, 0x39);
	public const Guid FWPM_LAYER_INBOUND_TRANSPORT_V6 = .(0x634a869f, 0xfc23, 0x4b90, 0xb0, 0xc1, 0xbf, 0x62, 0x0a, 0x36, 0xae, 0x6f);
	public const Guid FWPM_LAYER_INBOUND_TRANSPORT_V6_DISCARD = .(0x2a6ff955, 0x3b2b, 0x49d2, 0x98, 0x48, 0xad, 0x9d, 0x72, 0xdc, 0xaa, 0xb7);
	public const Guid FWPM_LAYER_OUTBOUND_TRANSPORT_V4 = .(0x09e61aea, 0xd214, 0x46e2, 0x9b, 0x21, 0xb2, 0x6b, 0x0b, 0x2f, 0x28, 0xc8);
	public const Guid FWPM_LAYER_OUTBOUND_TRANSPORT_V4_DISCARD = .(0xc5f10551, 0xbdb0, 0x43d7, 0xa3, 0x13, 0x50, 0xe2, 0x11, 0xf4, 0xd6, 0x8a);
	public const Guid FWPM_LAYER_OUTBOUND_TRANSPORT_V6 = .(0xe1735bde, 0x013f, 0x4655, 0xb3, 0x51, 0xa4, 0x9e, 0x15, 0x76, 0x2d, 0xf0);
	public const Guid FWPM_LAYER_OUTBOUND_TRANSPORT_V6_DISCARD = .(0xf433df69, 0xccbd, 0x482e, 0xb9, 0xb2, 0x57, 0x16, 0x56, 0x58, 0xc3, 0xb3);
	public const Guid FWPM_LAYER_STREAM_V4 = .(0x3b89653c, 0xc170, 0x49e4, 0xb1, 0xcd, 0xe0, 0xee, 0xee, 0xe1, 0x9a, 0x3e);
	public const Guid FWPM_LAYER_STREAM_V4_DISCARD = .(0x25c4c2c2, 0x25ff, 0x4352, 0x82, 0xf9, 0xc5, 0x4a, 0x4a, 0x47, 0x26, 0xdc);
	public const Guid FWPM_LAYER_STREAM_V6 = .(0x47c9137a, 0x7ec4, 0x46b3, 0xb6, 0xe4, 0x48, 0xe9, 0x26, 0xb1, 0xed, 0xa4);
	public const Guid FWPM_LAYER_STREAM_V6_DISCARD = .(0x10a59fc7, 0xb628, 0x4c41, 0x9e, 0xb8, 0xcf, 0x37, 0xd5, 0x51, 0x03, 0xcf);
	public const Guid FWPM_LAYER_DATAGRAM_DATA_V4 = .(0x3d08bf4e, 0x45f6, 0x4930, 0xa9, 0x22, 0x41, 0x70, 0x98, 0xe2, 0x00, 0x27);
	public const Guid FWPM_LAYER_DATAGRAM_DATA_V4_DISCARD = .(0x18e330c6, 0x7248, 0x4e52, 0xaa, 0xab, 0x47, 0x2e, 0xd6, 0x77, 0x04, 0xfd);
	public const Guid FWPM_LAYER_DATAGRAM_DATA_V6 = .(0xfa45fe2f, 0x3cba, 0x4427, 0x87, 0xfc, 0x57, 0xb9, 0xa4, 0xb1, 0x0d, 0x00);
	public const Guid FWPM_LAYER_DATAGRAM_DATA_V6_DISCARD = .(0x09d1dfe1, 0x9b86, 0x4a42, 0xbe, 0x9d, 0x8c, 0x31, 0x5b, 0x92, 0xa5, 0xd0);
	public const Guid FWPM_LAYER_INBOUND_ICMP_ERROR_V4 = .(0x61499990, 0x3cb6, 0x4e84, 0xb9, 0x50, 0x53, 0xb9, 0x4b, 0x69, 0x64, 0xf3);
	public const Guid FWPM_LAYER_INBOUND_ICMP_ERROR_V4_DISCARD = .(0xa6b17075, 0xebaf, 0x4053, 0xa4, 0xe7, 0x21, 0x3c, 0x81, 0x21, 0xed, 0xe5);
	public const Guid FWPM_LAYER_INBOUND_ICMP_ERROR_V6 = .(0x65f9bdff, 0x3b2d, 0x4e5d, 0xb8, 0xc6, 0xc7, 0x20, 0x65, 0x1f, 0xe8, 0x98);
	public const Guid FWPM_LAYER_INBOUND_ICMP_ERROR_V6_DISCARD = .(0xa6e7ccc0, 0x08fb, 0x468d, 0xa4, 0x72, 0x97, 0x71, 0xd5, 0x59, 0x5e, 0x09);
	public const Guid FWPM_LAYER_OUTBOUND_ICMP_ERROR_V4 = .(0x41390100, 0x564c, 0x4b32, 0xbc, 0x1d, 0x71, 0x80, 0x48, 0x35, 0x4d, 0x7c);
	public const Guid FWPM_LAYER_OUTBOUND_ICMP_ERROR_V4_DISCARD = .(0xb3598d36, 0x0561, 0x4588, 0xa6, 0xbf, 0xe9, 0x55, 0xe3, 0xf6, 0x26, 0x4b);
	public const Guid FWPM_LAYER_OUTBOUND_ICMP_ERROR_V6 = .(0x7fb03b60, 0x7b8d, 0x4dfa, 0xba, 0xdd, 0x98, 0x01, 0x76, 0xfc, 0x4e, 0x12);
	public const Guid FWPM_LAYER_OUTBOUND_ICMP_ERROR_V6_DISCARD = .(0x65f2e647, 0x8d0c, 0x4f47, 0xb1, 0x9b, 0x33, 0xa4, 0xd3, 0xf1, 0x35, 0x7c);
	public const Guid FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4 = .(0x1247d66d, 0x0b60, 0x4a15, 0x8d, 0x44, 0x71, 0x55, 0xd0, 0xf5, 0x3a, 0x0c);
	public const Guid FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V4_DISCARD = .(0x0b5812a2, 0xc3ff, 0x4eca, 0xb8, 0x8d, 0xc7, 0x9e, 0x20, 0xac, 0x63, 0x22);
	public const Guid FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6 = .(0x55a650e1, 0x5f0a, 0x4eca, 0xa6, 0x53, 0x88, 0xf5, 0x3b, 0x26, 0xaa, 0x8c);
	public const Guid FWPM_LAYER_ALE_RESOURCE_ASSIGNMENT_V6_DISCARD = .(0xcbc998bb, 0xc51f, 0x4c1a, 0xbb, 0x4f, 0x97, 0x75, 0xfc, 0xac, 0xab, 0x2f);
	public const Guid FWPM_LAYER_ALE_AUTH_LISTEN_V4 = .(0x88bb5dad, 0x76d7, 0x4227, 0x9c, 0x71, 0xdf, 0x0a, 0x3e, 0xd7, 0xbe, 0x7e);
	public const Guid FWPM_LAYER_ALE_AUTH_LISTEN_V4_DISCARD = .(0x371dfada, 0x9f26, 0x45fd, 0xb4, 0xeb, 0xc2, 0x9e, 0xb2, 0x12, 0x89, 0x3f);
	public const Guid FWPM_LAYER_ALE_AUTH_LISTEN_V6 = .(0x7ac9de24, 0x17dd, 0x4814, 0xb4, 0xbd, 0xa9, 0xfb, 0xc9, 0x5a, 0x32, 0x1b);
	public const Guid FWPM_LAYER_ALE_AUTH_LISTEN_V6_DISCARD = .(0x60703b07, 0x63c8, 0x48e9, 0xad, 0xa3, 0x12, 0xb1, 0xaf, 0x40, 0xa6, 0x17);
	public const Guid FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4 = .(0xe1cd9fe7, 0xf4b5, 0x4273, 0x96, 0xc0, 0x59, 0x2e, 0x48, 0x7b, 0x86, 0x50);
	public const Guid FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4_DISCARD = .(0x9eeaa99b, 0xbd22, 0x4227, 0x91, 0x9f, 0x00, 0x73, 0xc6, 0x33, 0x57, 0xb1);
	public const Guid FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6 = .(0xa3b42c97, 0x9f04, 0x4672, 0xb8, 0x7e, 0xce, 0xe9, 0xc4, 0x83, 0x25, 0x7f);
	public const Guid FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V6_DISCARD = .(0x89455b97, 0xdbe1, 0x453f, 0xa2, 0x24, 0x13, 0xda, 0x89, 0x5a, 0xf3, 0x96);
	public const Guid FWPM_LAYER_ALE_AUTH_CONNECT_V4 = .(0xc38d57d1, 0x05a7, 0x4c33, 0x90, 0x4f, 0x7f, 0xbc, 0xee, 0xe6, 0x0e, 0x82);
	public const Guid FWPM_LAYER_ALE_AUTH_CONNECT_V4_DISCARD = .(0xd632a801, 0xf5ba, 0x4ad6, 0x96, 0xe3, 0x60, 0x70, 0x17, 0xd9, 0x83, 0x6a);
	public const Guid FWPM_LAYER_ALE_AUTH_CONNECT_V6 = .(0x4a72393b, 0x319f, 0x44bc, 0x84, 0xc3, 0xba, 0x54, 0xdc, 0xb3, 0xb6, 0xb4);
	public const Guid FWPM_LAYER_ALE_AUTH_CONNECT_V6_DISCARD = .(0xc97bc3b8, 0xc9a3, 0x4e33, 0x86, 0x95, 0x8e, 0x17, 0xaa, 0xd4, 0xde, 0x09);
	public const Guid FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4 = .(0xaf80470a, 0x5596, 0x4c13, 0x99, 0x92, 0x53, 0x9e, 0x6f, 0xe5, 0x79, 0x67);
	public const Guid FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4_DISCARD = .(0x146ae4a9, 0xa1d2, 0x4d43, 0xa3, 0x1a, 0x4c, 0x42, 0x68, 0x2b, 0x8e, 0x4f);
	public const Guid FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6 = .(0x7021d2b3, 0xdfa4, 0x406e, 0xaf, 0xeb, 0x6a, 0xfa, 0xf7, 0xe7, 0x0e, 0xfd);
	public const Guid FWPM_LAYER_ALE_FLOW_ESTABLISHED_V6_DISCARD = .(0x46928636, 0xbbca, 0x4b76, 0x94, 0x1d, 0x0f, 0xa7, 0xf5, 0xd7, 0xd3, 0x72);
	public const Guid FWPM_LAYER_INBOUND_MAC_FRAME_ETHERNET = .(0xeffb7edb, 0x0055, 0x4f9a, 0xa2, 0x31, 0x4f, 0xf8, 0x13, 0x1a, 0xd1, 0x91);
	public const Guid FWPM_LAYER_OUTBOUND_MAC_FRAME_ETHERNET = .(0x694673bc, 0xd6db, 0x4870, 0xad, 0xee, 0x0a, 0xcd, 0xbd, 0xb7, 0xf4, 0xb2);
	public const Guid FWPM_LAYER_INBOUND_MAC_FRAME_NATIVE = .(0xd4220bd3, 0x62ce, 0x4f08, 0xae, 0x88, 0xb5, 0x6e, 0x85, 0x26, 0xdf, 0x50);
	public const Guid FWPM_LAYER_OUTBOUND_MAC_FRAME_NATIVE = .(0x94c44912, 0x9d6f, 0x4ebf, 0xb9, 0x95, 0x05, 0xab, 0x8a, 0x08, 0x8d, 0x1b);
	public const Guid FWPM_LAYER_INGRESS_VSWITCH_ETHERNET = .(0x7d98577a, 0x9a87, 0x41ec, 0x97, 0x18, 0x7c, 0xf5, 0x89, 0xc9, 0xf3, 0x2d);
	public const Guid FWPM_LAYER_EGRESS_VSWITCH_ETHERNET = .(0x86c872b0, 0x76fa, 0x4b79, 0x93, 0xa4, 0x07, 0x50, 0x53, 0x0a, 0xe2, 0x92);
	public const Guid FWPM_LAYER_INGRESS_VSWITCH_TRANSPORT_V4 = .(0xb2696ff6, 0x774f, 0x4554, 0x9f, 0x7d, 0x3d, 0xa3, 0x94, 0x5f, 0x8e, 0x85);
	public const Guid FWPM_LAYER_INGRESS_VSWITCH_TRANSPORT_V6 = .(0x5ee314fc, 0x7d8a, 0x47f4, 0xb7, 0xe3, 0x29, 0x1a, 0x36, 0xda, 0x4e, 0x12);
	public const Guid FWPM_LAYER_EGRESS_VSWITCH_TRANSPORT_V4 = .(0xb92350b6, 0x91f0, 0x46b6, 0xbd, 0xc4, 0x87, 0x1d, 0xfd, 0x4a, 0x7c, 0x98);
	public const Guid FWPM_LAYER_EGRESS_VSWITCH_TRANSPORT_V6 = .(0x1b2def23, 0x1881, 0x40bd, 0x82, 0xf4, 0x42, 0x54, 0xe6, 0x31, 0x41, 0xcb);
	public const Guid FWPM_LAYER_INBOUND_TRANSPORT_FAST = .(0xe41d2719, 0x05c7, 0x40f0, 0x89, 0x83, 0xea, 0x8d, 0x17, 0xbb, 0xc2, 0xf6);
	public const Guid FWPM_LAYER_OUTBOUND_TRANSPORT_FAST = .(0x13ed4388, 0xa070, 0x4815, 0x99, 0x35, 0x7a, 0x9b, 0xe6, 0x40, 0x8b, 0x78);
	public const Guid FWPM_LAYER_INBOUND_MAC_FRAME_NATIVE_FAST = .(0x853aaa8e, 0x2b78, 0x4d24, 0xa8, 0x04, 0x36, 0xdb, 0x08, 0xb2, 0x97, 0x11);
	public const Guid FWPM_LAYER_OUTBOUND_MAC_FRAME_NATIVE_FAST = .(0x470df946, 0xc962, 0x486f, 0x94, 0x46, 0x82, 0x93, 0xcb, 0xc7, 0x5e, 0xb8);
	public const Guid FWPM_LAYER_IPSEC_KM_DEMUX_V4 = .(0xf02b1526, 0xa459, 0x4a51, 0xb9, 0xe3, 0x75, 0x9d, 0xe5, 0x2b, 0x9d, 0x2c);
	public const Guid FWPM_LAYER_IPSEC_KM_DEMUX_V6 = .(0x2f755cf6, 0x2fd4, 0x4e88, 0xb3, 0xe4, 0xa9, 0x1b, 0xca, 0x49, 0x52, 0x35);
	public const Guid FWPM_LAYER_IPSEC_V4 = .(0xeda65c74, 0x610d, 0x4bc5, 0x94, 0x8f, 0x3c, 0x4f, 0x89, 0x55, 0x68, 0x67);
	public const Guid FWPM_LAYER_IPSEC_V6 = .(0x13c48442, 0x8d87, 0x4261, 0x9a, 0x29, 0x59, 0xd2, 0xab, 0xc3, 0x48, 0xb4);
	public const Guid FWPM_LAYER_IKEEXT_V4 = .(0xb14b7bdb, 0xdbbd, 0x473e, 0xbe, 0xd4, 0x8b, 0x47, 0x08, 0xd4, 0xf2, 0x70);
	public const Guid FWPM_LAYER_IKEEXT_V6 = .(0xb64786b3, 0xf687, 0x4eb9, 0x89, 0xd2, 0x8e, 0xf3, 0x2a, 0xcd, 0xab, 0xe2);
	public const Guid FWPM_LAYER_RPC_UM = .(0x75a89dda, 0x95e4, 0x40f3, 0xad, 0xc7, 0x76, 0x88, 0xa9, 0xc8, 0x47, 0xe1);
	public const Guid FWPM_LAYER_RPC_EPMAP = .(0x9247bc61, 0xeb07, 0x47ee, 0x87, 0x2c, 0xbf, 0xd7, 0x8b, 0xfd, 0x16, 0x16);
	public const Guid FWPM_LAYER_RPC_EP_ADD = .(0x618dffc7, 0xc450, 0x4943, 0x95, 0xdb, 0x99, 0xb4, 0xc1, 0x6a, 0x55, 0xd4);
	public const Guid FWPM_LAYER_RPC_PROXY_CONN = .(0x94a4b50b, 0xba5c, 0x4f27, 0x90, 0x7a, 0x22, 0x9f, 0xac, 0x0c, 0x2a, 0x7a);
	public const Guid FWPM_LAYER_RPC_PROXY_IF = .(0xf8a38615, 0xe12c, 0x41ac, 0x98, 0xdf, 0x12, 0x1a, 0xd9, 0x81, 0xaa, 0xde);
	public const Guid FWPM_LAYER_KM_AUTHORIZATION = .(0x4aa226e9, 0x9020, 0x45fb, 0x95, 0x6a, 0xc0, 0x24, 0x9d, 0x84, 0x11, 0x95);
	public const Guid FWPM_LAYER_NAME_RESOLUTION_CACHE_V4 = .(0x0c2aa681, 0x905b, 0x4ccd, 0xa4, 0x67, 0x4d, 0xd8, 0x11, 0xd0, 0x7b, 0x7b);
	public const Guid FWPM_LAYER_NAME_RESOLUTION_CACHE_V6 = .(0x92d592fa, 0x6b01, 0x434a, 0x9d, 0xea, 0xd1, 0xe9, 0x6e, 0xa9, 0x7d, 0xa9);
	public const Guid FWPM_LAYER_ALE_RESOURCE_RELEASE_V4 = .(0x74365cce, 0xccb0, 0x401a, 0xbf, 0xc1, 0xb8, 0x99, 0x34, 0xad, 0x7e, 0x15);
	public const Guid FWPM_LAYER_ALE_RESOURCE_RELEASE_V6 = .(0xf4e5ce80, 0xedcc, 0x4e13, 0x8a, 0x2f, 0xb9, 0x14, 0x54, 0xbb, 0x05, 0x7b);
	public const Guid FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V4 = .(0xb4766427, 0xe2a2, 0x467a, 0xbd, 0x7e, 0xdb, 0xcd, 0x1b, 0xd8, 0x5a, 0x09);
	public const Guid FWPM_LAYER_ALE_ENDPOINT_CLOSURE_V6 = .(0xbb536ccd, 0x4755, 0x4ba9, 0x9f, 0xf7, 0xf9, 0xed, 0xf8, 0x69, 0x9c, 0x7b);
	public const Guid FWPM_LAYER_ALE_CONNECT_REDIRECT_V4 = .(0xc6e63c8c, 0xb784, 0x4562, 0xaa, 0x7d, 0x0a, 0x67, 0xcf, 0xca, 0xf9, 0xa3);
	public const Guid FWPM_LAYER_ALE_CONNECT_REDIRECT_V6 = .(0x587e54a7, 0x8046, 0x42ba, 0xa0, 0xaa, 0xb7, 0x16, 0x25, 0x0f, 0xc7, 0xfd);
	public const Guid FWPM_LAYER_ALE_BIND_REDIRECT_V4 = .(0x66978cad, 0xc704, 0x42ac, 0x86, 0xac, 0x7c, 0x1a, 0x23, 0x1b, 0xd2, 0x53);
	public const Guid FWPM_LAYER_ALE_BIND_REDIRECT_V6 = .(0xbef02c9c, 0x606b, 0x4536, 0x8c, 0x26, 0x1c, 0x2f, 0xc7, 0xb6, 0x31, 0xd4);
	public const Guid FWPM_LAYER_STREAM_PACKET_V4 = .(0xaf52d8ec, 0xcb2d, 0x44e5, 0xad, 0x92, 0xf8, 0xdc, 0x38, 0xd2, 0xeb, 0x29);
	public const Guid FWPM_LAYER_STREAM_PACKET_V6 = .(0x779a8ca3, 0xf099, 0x468f, 0xb5, 0xd4, 0x83, 0x53, 0x5c, 0x46, 0x1c, 0x02);
	public const Guid FWPM_LAYER_INBOUND_RESERVED2 = .(0xf4fb8d55, 0xc076, 0x46d8, 0xa2, 0xc7, 0x6a, 0x4c, 0x72, 0x2c, 0xa4, 0xed);
	public const Guid FWPM_SUBLAYER_RPC_AUDIT = .(0x758c84f4, 0xfb48, 0x4de9, 0x9a, 0xeb, 0x3e, 0xd9, 0x55, 0x1a, 0xb1, 0xfd);
	public const Guid FWPM_SUBLAYER_IPSEC_TUNNEL = .(0x83f299ed, 0x9ff4, 0x4967, 0xaf, 0xf4, 0xc3, 0x09, 0xf4, 0xda, 0xb8, 0x27);
	public const Guid FWPM_SUBLAYER_UNIVERSAL = .(0xeebecc03, 0xced4, 0x4380, 0x81, 0x9a, 0x27, 0x34, 0x39, 0x7b, 0x2b, 0x74);
	public const Guid FWPM_SUBLAYER_LIPS = .(0x1b75c0ce, 0xff60, 0x4711, 0xa7, 0x0f, 0xb4, 0x95, 0x8c, 0xc3, 0xb2, 0xd0);
	public const Guid FWPM_SUBLAYER_SECURE_SOCKET = .(0x15a66e17, 0x3f3c, 0x4f7b, 0xaa, 0x6c, 0x81, 0x2a, 0xa6, 0x13, 0xdd, 0x82);
	public const Guid FWPM_SUBLAYER_TCP_CHIMNEY_OFFLOAD = .(0x337608b9, 0xb7d5, 0x4d5f, 0x82, 0xf9, 0x36, 0x18, 0x61, 0x8b, 0xc0, 0x58);
	public const Guid FWPM_SUBLAYER_INSPECTION = .(0x877519e1, 0xe6a9, 0x41a5, 0x81, 0xb4, 0x8c, 0x4f, 0x11, 0x8e, 0x4a, 0x60);
	public const Guid FWPM_SUBLAYER_TEREDO = .(0xba69dc66, 0x5176, 0x4979, 0x9c, 0x89, 0x26, 0xa7, 0xb4, 0x6a, 0x83, 0x27);
	public const Guid FWPM_SUBLAYER_IPSEC_FORWARD_OUTBOUND_TUNNEL = .(0xa5082e73, 0x8f71, 0x4559, 0x8a, 0x9a, 0x10, 0x1c, 0xea, 0x04, 0xef, 0x87);
	public const Guid FWPM_SUBLAYER_IPSEC_DOSP = .(0xe076d572, 0x5d3d, 0x48ef, 0x80, 0x2b, 0x90, 0x9e, 0xdd, 0xb0, 0x98, 0xbd);
	public const Guid FWPM_SUBLAYER_TCP_TEMPLATES = .(0x24421dcf, 0x0ac5, 0x4caa, 0x9e, 0x14, 0x50, 0xf6, 0xe3, 0x63, 0x6a, 0xf0);
	public const Guid FWPM_SUBLAYER_IPSEC_SECURITY_REALM = .(0x37a57701, 0x5884, 0x4964, 0x92, 0xb8, 0x3e, 0x70, 0x46, 0x88, 0xb0, 0xad);
	public const Guid FWPM_SUBLAYER_MPSSVC_WSH = .(0xb3cdd441, 0xaf90, 0x41ba, 0xa7, 0x45, 0x7c, 0x60, 0x08, 0xff, 0x23, 0x00);
	public const Guid FWPM_SUBLAYER_MPSSVC_WF = .(0xb3cdd441, 0xaf90, 0x41ba, 0xa7, 0x45, 0x7c, 0x60, 0x08, 0xff, 0x23, 0x01);
	public const Guid FWPM_SUBLAYER_MPSSVC_QUARANTINE = .(0xb3cdd441, 0xaf90, 0x41ba, 0xa7, 0x45, 0x7c, 0x60, 0x08, 0xff, 0x23, 0x02);
	public const Guid FWPM_SUBLAYER_MPSSVC_EDP = .(0x09a47e38, 0xfa97, 0x471b, 0xb1, 0x23, 0x18, 0xbc, 0xd7, 0xe6, 0x50, 0x71);
	public const Guid FWPM_SUBLAYER_MPSSVC_TENANT_RESTRICTIONS = .(0x1ec6c7e1, 0xfdd9, 0x478a, 0xb5, 0x5f, 0xff, 0x8b, 0xa1, 0xd2, 0xc1, 0x7d);
	public const Guid FWPM_CONDITION_INTERFACE_MAC_ADDRESS = .(0xf6e63dce, 0x1f4b, 0x4c6b, 0xb6, 0xef, 0x11, 0x65, 0xe7, 0x1f, 0x8e, 0xe7);
	public const Guid FWPM_CONDITION_MAC_LOCAL_ADDRESS = .(0xd999e981, 0x7948, 0x4c83, 0xb7, 0x42, 0xc8, 0x4e, 0x3b, 0x67, 0x8f, 0x8f);
	public const Guid FWPM_CONDITION_MAC_REMOTE_ADDRESS = .(0x408f2ed4, 0x3a70, 0x4b4d, 0x92, 0xa6, 0x41, 0x5a, 0xc2, 0x0e, 0x2f, 0x12);
	public const Guid FWPM_CONDITION_ETHER_TYPE = .(0xfd08948d, 0xa219, 0x4d52, 0xbb, 0x98, 0x1a, 0x55, 0x40, 0xee, 0x7b, 0x4e);
	public const Guid FWPM_CONDITION_VLAN_ID = .(0x938eab21, 0x3618, 0x4e64, 0x9c, 0xa5, 0x21, 0x41, 0xeb, 0xda, 0x1c, 0xa2);
	public const Guid FWPM_CONDITION_VSWITCH_TENANT_NETWORK_ID = .(0xdc04843c, 0x79e6, 0x4e44, 0xa0, 0x25, 0x65, 0xb9, 0xbb, 0x0f, 0x9f, 0x94);
	public const Guid FWPM_CONDITION_NDIS_PORT = .(0xdb7bb42b, 0x2dac, 0x4cd4, 0xa5, 0x9a, 0xe0, 0xbd, 0xce, 0x1e, 0x68, 0x34);
	public const Guid FWPM_CONDITION_NDIS_MEDIA_TYPE = .(0xcb31cef1, 0x791d, 0x473b, 0x89, 0xd1, 0x61, 0xc5, 0x98, 0x43, 0x04, 0xa0);
	public const Guid FWPM_CONDITION_NDIS_PHYSICAL_MEDIA_TYPE = .(0x34c79823, 0xc229, 0x44f2, 0xb8, 0x3c, 0x74, 0x02, 0x08, 0x82, 0xae, 0x77);
	public const Guid FWPM_CONDITION_L2_FLAGS = .(0x7bc43cbf, 0x37ba, 0x45f1, 0xb7, 0x4a, 0x82, 0xff, 0x51, 0x8e, 0xeb, 0x10);
	public const Guid FWPM_CONDITION_MAC_LOCAL_ADDRESS_TYPE = .(0xcc31355c, 0x3073, 0x4ffb, 0xa1, 0x4f, 0x79, 0x41, 0x5c, 0xb1, 0xea, 0xd1);
	public const Guid FWPM_CONDITION_MAC_REMOTE_ADDRESS_TYPE = .(0x027fedb4, 0xf1c1, 0x4030, 0xb5, 0x64, 0xee, 0x77, 0x7f, 0xd8, 0x67, 0xea);
	public const Guid FWPM_CONDITION_ALE_PACKAGE_ID = .(0x71bc78fa, 0xf17c, 0x4997, 0xa6, 0x02, 0x6a, 0xbb, 0x26, 0x1f, 0x35, 0x1c);
	public const Guid FWPM_CONDITION_MAC_SOURCE_ADDRESS = .(0x7b795451, 0xf1f6, 0x4d05, 0xb7, 0xcb, 0x21, 0x77, 0x9d, 0x80, 0x23, 0x36);
	public const Guid FWPM_CONDITION_MAC_DESTINATION_ADDRESS = .(0x04ea2a93, 0x858c, 0x4027, 0xb6, 0x13, 0xb4, 0x31, 0x80, 0xc7, 0x85, 0x9e);
	public const Guid FWPM_CONDITION_MAC_SOURCE_ADDRESS_TYPE = .(0x5c1b72e4, 0x299e, 0x4437, 0xa2, 0x98, 0xbc, 0x3f, 0x01, 0x4b, 0x3d, 0xc2);
	public const Guid FWPM_CONDITION_MAC_DESTINATION_ADDRESS_TYPE = .(0xae052932, 0xef42, 0x4e99, 0xb1, 0x29, 0xf3, 0xb3, 0x13, 0x9e, 0x34, 0xf7);
	public const Guid FWPM_CONDITION_IP_SOURCE_PORT = .(0xa6afef91, 0x3df4, 0x4730, 0xa2, 0x14, 0xf5, 0x42, 0x6a, 0xeb, 0xf8, 0x21);
	public const Guid FWPM_CONDITION_IP_DESTINATION_PORT = .(0xce6def45, 0x60fb, 0x4a7b, 0xa3, 0x04, 0xaf, 0x30, 0xa1, 0x17, 0x00, 0x0e);
	public const Guid FWPM_CONDITION_VSWITCH_ID = .(0xc4a414ba, 0x437b, 0x4de6, 0x99, 0x46, 0xd9, 0x9c, 0x1b, 0x95, 0xb3, 0x12);
	public const Guid FWPM_CONDITION_VSWITCH_NETWORK_TYPE = .(0x11d48b4b, 0xe77a, 0x40b4, 0x91, 0x55, 0x39, 0x2c, 0x90, 0x6c, 0x26, 0x08);
	public const Guid FWPM_CONDITION_VSWITCH_SOURCE_INTERFACE_ID = .(0x7f4ef24b, 0xb2c1, 0x4938, 0xba, 0x33, 0xa1, 0xec, 0xbe, 0xd5, 0x12, 0xba);
	public const Guid FWPM_CONDITION_VSWITCH_DESTINATION_INTERFACE_ID = .(0x8ed48be4, 0xc926, 0x49f6, 0xa4, 0xf6, 0xef, 0x30, 0x30, 0xe3, 0xfc, 0x16);
	public const Guid FWPM_CONDITION_VSWITCH_SOURCE_VM_ID = .(0x9c2a9ec2, 0x9fc6, 0x42bc, 0xbd, 0xd8, 0x40, 0x6d, 0x4d, 0xa0, 0xbe, 0x64);
	public const Guid FWPM_CONDITION_VSWITCH_DESTINATION_VM_ID = .(0x6106aace, 0x4de1, 0x4c84, 0x96, 0x71, 0x36, 0x37, 0xf8, 0xbc, 0xf7, 0x31);
	public const Guid FWPM_CONDITION_VSWITCH_SOURCE_INTERFACE_TYPE = .(0xe6b040a2, 0xedaf, 0x4c36, 0x90, 0x8b, 0xf2, 0xf5, 0x8a, 0xe4, 0x38, 0x07);
	public const Guid FWPM_CONDITION_VSWITCH_DESTINATION_INTERFACE_TYPE = .(0xfa9b3f06, 0x2f1a, 0x4c57, 0x9e, 0x68, 0xa7, 0x09, 0x8b, 0x28, 0xdb, 0xfe);
	public const Guid FWPM_CONDITION_ALE_SECURITY_ATTRIBUTE_FQBN_VALUE = .(0x37a57699, 0x5883, 0x4963, 0x92, 0xb8, 0x3e, 0x70, 0x46, 0x88, 0xb0, 0xad);
	public const Guid FWPM_CONDITION_IPSEC_SECURITY_REALM_ID = .(0x37a57700, 0x5884, 0x4964, 0x92, 0xb8, 0x3e, 0x70, 0x46, 0x88, 0xb0, 0xad);
	public const Guid FWPM_CONDITION_ALE_EFFECTIVE_NAME = .(0xb1277b9a, 0xb781, 0x40fc, 0x96, 0x71, 0xe5, 0xf1, 0xb9, 0x89, 0xf3, 0x4e);
	public const Guid FWPM_CONDITION_IP_LOCAL_ADDRESS = .(0xd9ee00de, 0xc1ef, 0x4617, 0xbf, 0xe3, 0xff, 0xd8, 0xf5, 0xa0, 0x89, 0x57);
	public const Guid FWPM_CONDITION_IP_REMOTE_ADDRESS = .(0xb235ae9a, 0x1d64, 0x49b8, 0xa4, 0x4c, 0x5f, 0xf3, 0xd9, 0x09, 0x50, 0x45);
	public const Guid FWPM_CONDITION_IP_SOURCE_ADDRESS = .(0xae96897e, 0x2e94, 0x4bc9, 0xb3, 0x13, 0xb2, 0x7e, 0xe8, 0x0e, 0x57, 0x4d);
	public const Guid FWPM_CONDITION_IP_DESTINATION_ADDRESS = .(0x2d79133b, 0xb390, 0x45c6, 0x86, 0x99, 0xac, 0xac, 0xea, 0xaf, 0xed, 0x33);
	public const Guid FWPM_CONDITION_IP_LOCAL_ADDRESS_TYPE = .(0x6ec7f6c4, 0x376b, 0x45d7, 0x9e, 0x9c, 0xd3, 0x37, 0xce, 0xdc, 0xd2, 0x37);
	public const Guid FWPM_CONDITION_IP_DESTINATION_ADDRESS_TYPE = .(0x1ec1b7c9, 0x4eea, 0x4f5e, 0xb9, 0xef, 0x76, 0xbe, 0xaa, 0xaf, 0x17, 0xee);
	public const Guid FWPM_CONDITION_IP_NEXTHOP_ADDRESS = .(0xeabe448a, 0xa711, 0x4d64, 0x85, 0xb7, 0x3f, 0x76, 0xb6, 0x52, 0x99, 0xc7);
	public const Guid FWPM_CONDITION_IP_LOCAL_INTERFACE = .(0x4cd62a49, 0x59c3, 0x4969, 0xb7, 0xf3, 0xbd, 0xa5, 0xd3, 0x28, 0x90, 0xa4);
	public const Guid FWPM_CONDITION_IP_ARRIVAL_INTERFACE = .(0x618a9b6d, 0x386b, 0x4136, 0xad, 0x6e, 0xb5, 0x15, 0x87, 0xcf, 0xb1, 0xcd);
	public const Guid FWPM_CONDITION_ARRIVAL_INTERFACE_TYPE = .(0x89f990de, 0xe798, 0x4e6d, 0xab, 0x76, 0x7c, 0x95, 0x58, 0x29, 0x2e, 0x6f);
	public const Guid FWPM_CONDITION_ARRIVAL_TUNNEL_TYPE = .(0x511166dc, 0x7a8c, 0x4aa7, 0xb5, 0x33, 0x95, 0xab, 0x59, 0xfb, 0x03, 0x40);
	public const Guid FWPM_CONDITION_ARRIVAL_INTERFACE_INDEX = .(0xcc088db3, 0x1792, 0x4a71, 0xb0, 0xf9, 0x03, 0x7d, 0x21, 0xcd, 0x82, 0x8b);
	public const Guid FWPM_CONDITION_NEXTHOP_SUB_INTERFACE_INDEX = .(0xef8a6122, 0x0577, 0x45a7, 0x9a, 0xaf, 0x82, 0x5f, 0xbe, 0xb4, 0xfb, 0x95);
	public const Guid FWPM_CONDITION_IP_NEXTHOP_INTERFACE = .(0x93ae8f5b, 0x7f6f, 0x4719, 0x98, 0xc8, 0x14, 0xe9, 0x74, 0x29, 0xef, 0x04);
	public const Guid FWPM_CONDITION_NEXTHOP_INTERFACE_TYPE = .(0x97537c6c, 0xd9a3, 0x4767, 0xa3, 0x81, 0xe9, 0x42, 0x67, 0x5c, 0xd9, 0x20);
	public const Guid FWPM_CONDITION_NEXTHOP_TUNNEL_TYPE = .(0x72b1a111, 0x987b, 0x4720, 0x99, 0xdd, 0xc7, 0xc5, 0x76, 0xfa, 0x2d, 0x4c);
	public const Guid FWPM_CONDITION_NEXTHOP_INTERFACE_INDEX = .(0x138e6888, 0x7ab8, 0x4d65, 0x9e, 0xe8, 0x05, 0x91, 0xbc, 0xf6, 0xa4, 0x94);
	public const Guid FWPM_CONDITION_ORIGINAL_PROFILE_ID = .(0x46ea1551, 0x2255, 0x492b, 0x80, 0x19, 0xaa, 0xbe, 0xee, 0x34, 0x9f, 0x40);
	public const Guid FWPM_CONDITION_CURRENT_PROFILE_ID = .(0xab3033c9, 0xc0e3, 0x4759, 0x93, 0x7d, 0x57, 0x58, 0xc6, 0x5d, 0x4a, 0xe3);
	public const Guid FWPM_CONDITION_LOCAL_INTERFACE_PROFILE_ID = .(0x4ebf7562, 0x9f18, 0x4d06, 0x99, 0x41, 0xa7, 0xa6, 0x25, 0x74, 0x4d, 0x71);
	public const Guid FWPM_CONDITION_ARRIVAL_INTERFACE_PROFILE_ID = .(0xcdfe6aab, 0xc083, 0x4142, 0x86, 0x79, 0xc0, 0x8f, 0x95, 0x32, 0x9c, 0x61);
	public const Guid FWPM_CONDITION_NEXTHOP_INTERFACE_PROFILE_ID = .(0xd7ff9a56, 0xcdaa, 0x472b, 0x84, 0xdb, 0xd2, 0x39, 0x63, 0xc1, 0xd1, 0xbf);
	public const Guid FWPM_CONDITION_REAUTHORIZE_REASON = .(0x11205e8c, 0x11ae, 0x457a, 0x8a, 0x44, 0x47, 0x70, 0x26, 0xdd, 0x76, 0x4a);
	public const Guid FWPM_CONDITION_ORIGINAL_ICMP_TYPE = .(0x076dfdbe, 0xc56c, 0x4f72, 0xae, 0x8a, 0x2c, 0xfe, 0x7e, 0x5c, 0x82, 0x86);
	public const Guid FWPM_CONDITION_IP_PHYSICAL_ARRIVAL_INTERFACE = .(0xda50d5c8, 0xfa0d, 0x4c89, 0xb0, 0x32, 0x6e, 0x62, 0x13, 0x6d, 0x1e, 0x96);
	public const Guid FWPM_CONDITION_IP_PHYSICAL_NEXTHOP_INTERFACE = .(0xf09bd5ce, 0x5150, 0x48be, 0xb0, 0x98, 0xc2, 0x51, 0x52, 0xfb, 0x1f, 0x92);
	public const Guid FWPM_CONDITION_INTERFACE_QUARANTINE_EPOCH = .(0xcce68d5e, 0x053b, 0x43a8, 0x9a, 0x6f, 0x33, 0x38, 0x4c, 0x28, 0xe4, 0xf6);
	public const Guid FWPM_CONDITION_INTERFACE_TYPE = .(0xdaf8cd14, 0xe09e, 0x4c93, 0xa5, 0xae, 0xc5, 0xc1, 0x3b, 0x73, 0xff, 0xca);
	public const Guid FWPM_CONDITION_TUNNEL_TYPE = .(0x77a40437, 0x8779, 0x4868, 0xa2, 0x61, 0xf5, 0xa9, 0x02, 0xf1, 0xc0, 0xcd);
	public const Guid FWPM_CONDITION_IP_FORWARD_INTERFACE = .(0x1076b8a5, 0x6323, 0x4c5e, 0x98, 0x10, 0xe8, 0xd3, 0xfc, 0x9e, 0x61, 0x36);
	public const Guid FWPM_CONDITION_IP_PROTOCOL = .(0x3971ef2b, 0x623e, 0x4f9a, 0x8c, 0xb1, 0x6e, 0x79, 0xb8, 0x06, 0xb9, 0xa7);
	public const Guid FWPM_CONDITION_IP_LOCAL_PORT = .(0x0c1ba1af, 0x5765, 0x453f, 0xaf, 0x22, 0xa8, 0xf7, 0x91, 0xac, 0x77, 0x5b);
	public const Guid FWPM_CONDITION_IP_REMOTE_PORT = .(0xc35a604d, 0xd22b, 0x4e1a, 0x91, 0xb4, 0x68, 0xf6, 0x74, 0xee, 0x67, 0x4b);
	public const Guid FWPM_CONDITION_EMBEDDED_LOCAL_ADDRESS_TYPE = .(0x4672a468, 0x8a0a, 0x4202, 0xab, 0xb4, 0x84, 0x9e, 0x92, 0xe6, 0x68, 0x09);
	public const Guid FWPM_CONDITION_EMBEDDED_REMOTE_ADDRESS = .(0x77ee4b39, 0x3273, 0x4671, 0xb6, 0x3b, 0xab, 0x6f, 0xeb, 0x66, 0xee, 0xb6);
	public const Guid FWPM_CONDITION_EMBEDDED_PROTOCOL = .(0x07784107, 0xa29e, 0x4c7b, 0x9e, 0xc7, 0x29, 0xc4, 0x4a, 0xfa, 0xfd, 0xbc);
	public const Guid FWPM_CONDITION_EMBEDDED_LOCAL_PORT = .(0xbfca394d, 0xacdb, 0x484e, 0xb8, 0xe6, 0x2a, 0xff, 0x79, 0x75, 0x73, 0x45);
	public const Guid FWPM_CONDITION_EMBEDDED_REMOTE_PORT = .(0xcae4d6a1, 0x2968, 0x40ed, 0xa4, 0xce, 0x54, 0x71, 0x60, 0xdd, 0xa8, 0x8d);
	public const Guid FWPM_CONDITION_FLAGS = .(0x632ce23b, 0x5167, 0x435c, 0x86, 0xd7, 0xe9, 0x03, 0x68, 0x4a, 0xa8, 0x0c);
	public const Guid FWPM_CONDITION_DIRECTION = .(0x8784c146, 0xca97, 0x44d6, 0x9f, 0xd1, 0x19, 0xfb, 0x18, 0x40, 0xcb, 0xf7);
	public const Guid FWPM_CONDITION_INTERFACE_INDEX = .(0x667fd755, 0xd695, 0x434a, 0x8a, 0xf5, 0xd3, 0x83, 0x5a, 0x12, 0x59, 0xbc);
	public const Guid FWPM_CONDITION_SUB_INTERFACE_INDEX = .(0x0cd42473, 0xd621, 0x4be3, 0xae, 0x8c, 0x72, 0xa3, 0x48, 0xd2, 0x83, 0xe1);
	public const Guid FWPM_CONDITION_SOURCE_INTERFACE_INDEX = .(0x2311334d, 0xc92d, 0x45bf, 0x94, 0x96, 0xed, 0xf4, 0x47, 0x82, 0x0e, 0x2d);
	public const Guid FWPM_CONDITION_SOURCE_SUB_INTERFACE_INDEX = .(0x055edd9d, 0xacd2, 0x4361, 0x8d, 0xab, 0xf9, 0x52, 0x5d, 0x97, 0x66, 0x2f);
	public const Guid FWPM_CONDITION_DESTINATION_INTERFACE_INDEX = .(0x35cf6522, 0x4139, 0x45ee, 0xa0, 0xd5, 0x67, 0xb8, 0x09, 0x49, 0xd8, 0x79);
	public const Guid FWPM_CONDITION_DESTINATION_SUB_INTERFACE_INDEX = .(0x2b7d4399, 0xd4c7, 0x4738, 0xa2, 0xf5, 0xe9, 0x94, 0xb4, 0x3d, 0xa3, 0x88);
	public const Guid FWPM_CONDITION_ALE_APP_ID = .(0xd78e1e87, 0x8644, 0x4ea5, 0x94, 0x37, 0xd8, 0x09, 0xec, 0xef, 0xc9, 0x71);
	public const Guid FWPM_CONDITION_ALE_ORIGINAL_APP_ID = .(0x0e6cd086, 0xe1fb, 0x4212, 0x84, 0x2f, 0x8a, 0x9f, 0x99, 0x3f, 0xb3, 0xf6);
	public const Guid FWPM_CONDITION_ALE_USER_ID = .(0xaf043a0a, 0xb34d, 0x4f86, 0x97, 0x9c, 0xc9, 0x03, 0x71, 0xaf, 0x6e, 0x66);
	public const Guid FWPM_CONDITION_ALE_REMOTE_USER_ID = .(0xf63073b7, 0x0189, 0x4ab0, 0x95, 0xa4, 0x61, 0x23, 0xcb, 0xfa, 0xb8, 0x62);
	public const Guid FWPM_CONDITION_ALE_REMOTE_MACHINE_ID = .(0x1aa47f51, 0x7f93, 0x4508, 0xa2, 0x71, 0x81, 0xab, 0xb0, 0x0c, 0x9c, 0xab);
	public const Guid FWPM_CONDITION_ALE_PROMISCUOUS_MODE = .(0x1c974776, 0x7182, 0x46e9, 0xaf, 0xd3, 0xb0, 0x29, 0x10, 0xe3, 0x03, 0x34);
	public const Guid FWPM_CONDITION_ALE_SIO_FIREWALL_SYSTEM_PORT = .(0xb9f4e088, 0xcb98, 0x4efb, 0xa2, 0xc7, 0xad, 0x07, 0x33, 0x26, 0x43, 0xdb);
	public const Guid FWPM_CONDITION_ALE_REAUTH_REASON = .(0xb482d227, 0x1979, 0x4a98, 0x80, 0x44, 0x18, 0xbb, 0xe6, 0x23, 0x75, 0x42);
	public const Guid FWPM_CONDITION_ALE_NAP_CONTEXT = .(0x46275a9d, 0xc03f, 0x4d77, 0xb7, 0x84, 0x1c, 0x57, 0xf4, 0xd0, 0x27, 0x53);
	public const Guid FWPM_CONDITION_KM_AUTH_NAP_CONTEXT = .(0x35d0ea0e, 0x15ca, 0x492b, 0x90, 0x0e, 0x97, 0xfd, 0x46, 0x35, 0x2c, 0xce);
	public const Guid FWPM_CONDITION_REMOTE_USER_TOKEN = .(0x9bf0ee66, 0x06c9, 0x41b9, 0x84, 0xda, 0x28, 0x8c, 0xb4, 0x3a, 0xf5, 0x1f);
	public const Guid FWPM_CONDITION_RPC_IF_UUID = .(0x7c9c7d9f, 0x0075, 0x4d35, 0xa0, 0xd1, 0x83, 0x11, 0xc4, 0xcf, 0x6a, 0xf1);
	public const Guid FWPM_CONDITION_RPC_IF_VERSION = .(0xeabfd9b7, 0x1262, 0x4a2e, 0xad, 0xaa, 0x5f, 0x96, 0xf6, 0xfe, 0x32, 0x6d);
	public const Guid FWPM_CONDITION_RPC_IF_FLAG = .(0x238a8a32, 0x3199, 0x467d, 0x87, 0x1c, 0x27, 0x26, 0x21, 0xab, 0x38, 0x96);
	public const Guid FWPM_CONDITION_DCOM_APP_ID = .(0xff2e7b4d, 0x3112, 0x4770, 0xb6, 0x36, 0x4d, 0x24, 0xae, 0x3a, 0x6a, 0xf2);
	public const Guid FWPM_CONDITION_IMAGE_NAME = .(0xd024de4d, 0xdeaa, 0x4317, 0x9c, 0x85, 0xe4, 0x0e, 0xf6, 0xe1, 0x40, 0xc3);
	public const Guid FWPM_CONDITION_RPC_PROTOCOL = .(0x2717bc74, 0x3a35, 0x4ce7, 0xb7, 0xef, 0xc8, 0x38, 0xfa, 0xbd, 0xec, 0x45);
	public const Guid FWPM_CONDITION_RPC_AUTH_TYPE = .(0xdaba74ab, 0x0d67, 0x43e7, 0x98, 0x6e, 0x75, 0xb8, 0x4f, 0x82, 0xf5, 0x94);
	public const Guid FWPM_CONDITION_RPC_AUTH_LEVEL = .(0xe5a0aed5, 0x59ac, 0x46ea, 0xbe, 0x05, 0xa5, 0xf0, 0x5e, 0xcf, 0x44, 0x6e);
	public const Guid FWPM_CONDITION_SEC_ENCRYPT_ALGORITHM = .(0x0d306ef0, 0xe974, 0x4f74, 0xb5, 0xc7, 0x59, 0x1b, 0x0d, 0xa7, 0xd5, 0x62);
	public const Guid FWPM_CONDITION_SEC_KEY_SIZE = .(0x4772183b, 0xccf8, 0x4aeb, 0xbc, 0xe1, 0xc6, 0xc6, 0x16, 0x1c, 0x8f, 0xe4);
	public const Guid FWPM_CONDITION_IP_LOCAL_ADDRESS_V4 = .(0x03a629cb, 0x6e52, 0x49f8, 0x9c, 0x41, 0x57, 0x09, 0x63, 0x3c, 0x09, 0xcf);
	public const Guid FWPM_CONDITION_IP_LOCAL_ADDRESS_V6 = .(0x2381be84, 0x7524, 0x45b3, 0xa0, 0x5b, 0x1e, 0x63, 0x7d, 0x9c, 0x7a, 0x6a);
	public const Guid FWPM_CONDITION_PIPE = .(0x1bd0741d, 0xe3df, 0x4e24, 0x86, 0x34, 0x76, 0x20, 0x46, 0xee, 0xf6, 0xeb);
	public const Guid FWPM_CONDITION_IP_REMOTE_ADDRESS_V4 = .(0x1febb610, 0x3bcc, 0x45e1, 0xbc, 0x36, 0x2e, 0x06, 0x7e, 0x2c, 0xb1, 0x86);
	public const Guid FWPM_CONDITION_IP_REMOTE_ADDRESS_V6 = .(0x246e1d8c, 0x8bee, 0x4018, 0x9b, 0x98, 0x31, 0xd4, 0x58, 0x2f, 0x33, 0x61);
	public const Guid FWPM_CONDITION_PROCESS_WITH_RPC_IF_UUID = .(0xe31180a8, 0xbbbd, 0x4d14, 0xa6, 0x5e, 0x71, 0x57, 0xb0, 0x62, 0x33, 0xbb);
	public const Guid FWPM_CONDITION_RPC_EP_VALUE = .(0xdccea0b9, 0x0886, 0x4360, 0x9c, 0x6a, 0xab, 0x04, 0x3a, 0x24, 0xfb, 0xa9);
	public const Guid FWPM_CONDITION_RPC_EP_FLAGS = .(0x218b814a, 0x0a39, 0x49b8, 0x8e, 0x71, 0xc2, 0x0c, 0x39, 0xc7, 0xdd, 0x2e);
	public const Guid FWPM_CONDITION_CLIENT_TOKEN = .(0xc228fc1e, 0x403a, 0x4478, 0xbe, 0x05, 0xc9, 0xba, 0xa4, 0xc0, 0x5a, 0xce);
	public const Guid FWPM_CONDITION_RPC_SERVER_NAME = .(0xb605a225, 0xc3b3, 0x48c7, 0x98, 0x33, 0x7a, 0xef, 0xa9, 0x52, 0x75, 0x46);
	public const Guid FWPM_CONDITION_RPC_SERVER_PORT = .(0x8090f645, 0x9ad5, 0x4e3b, 0x9f, 0x9f, 0x80, 0x23, 0xca, 0x09, 0x79, 0x09);
	public const Guid FWPM_CONDITION_RPC_PROXY_AUTH_TYPE = .(0x40953fe2, 0x8565, 0x4759, 0x84, 0x88, 0x17, 0x71, 0xb4, 0xb4, 0xb5, 0xdb);
	public const Guid FWPM_CONDITION_CLIENT_CERT_KEY_LENGTH = .(0xa3ec00c7, 0x05f4, 0x4df7, 0x91, 0xf2, 0x5f, 0x60, 0xd9, 0x1f, 0xf4, 0x43);
	public const Guid FWPM_CONDITION_CLIENT_CERT_OID = .(0xc491ad5e, 0xf882, 0x4283, 0xb9, 0x16, 0x43, 0x6b, 0x10, 0x3f, 0xf4, 0xad);
	public const Guid FWPM_CONDITION_NET_EVENT_TYPE = .(0x206e9996, 0x490e, 0x40cf, 0xb8, 0x31, 0xb3, 0x86, 0x41, 0xeb, 0x6f, 0xcb);
	public const Guid FWPM_CONDITION_PEER_NAME = .(0x9b539082, 0xeb90, 0x4186, 0xa6, 0xcc, 0xde, 0x5b, 0x63, 0x23, 0x50, 0x16);
	public const Guid FWPM_CONDITION_REMOTE_ID = .(0xf68166fd, 0x0682, 0x4c89, 0xb8, 0xf5, 0x86, 0x43, 0x6c, 0x7e, 0xf9, 0xb7);
	public const Guid FWPM_CONDITION_AUTHENTICATION_TYPE = .(0xeb458cd5, 0xda7b, 0x4ef9, 0x8d, 0x43, 0x7b, 0x0a, 0x84, 0x03, 0x32, 0xf2);
	public const Guid FWPM_CONDITION_KM_TYPE = .(0xff0f5f49, 0x0ceb, 0x481b, 0x86, 0x38, 0x14, 0x79, 0x79, 0x1f, 0x3f, 0x2c);
	public const Guid FWPM_CONDITION_KM_MODE = .(0xfeef4582, 0xef8f, 0x4f7b, 0x85, 0x8b, 0x90, 0x77, 0xd1, 0x22, 0xde, 0x47);
	public const Guid FWPM_CONDITION_IPSEC_POLICY_KEY = .(0xad37dee3, 0x722f, 0x45cc, 0xa4, 0xe3, 0x06, 0x80, 0x48, 0x12, 0x44, 0x52);
	public const Guid FWPM_CONDITION_QM_MODE = .(0xf64fc6d1, 0xf9cb, 0x43d2, 0x8a, 0x5f, 0xe1, 0x3b, 0xc8, 0x94, 0xf2, 0x65);
	public const Guid FWPM_CONDITION_COMPARTMENT_ID = .(0x35a791ab, 0x04ac, 0x4ff2, 0xa6, 0xbb, 0xda, 0x6c, 0xfa, 0xc7, 0x18, 0x06);
	public const Guid FWPM_CONDITION_RESERVED0 = .(0x678f4deb, 0x45af, 0x4882, 0x93, 0xfe, 0x19, 0xd4, 0x72, 0x9d, 0x98, 0x34);
	public const Guid FWPM_CONDITION_RESERVED1 = .(0xd818f827, 0x5c69, 0x48eb, 0xbf, 0x80, 0xd8, 0x6b, 0x17, 0x75, 0x5f, 0x97);
	public const Guid FWPM_CONDITION_RESERVED2 = .(0x53d4123d, 0xe15b, 0x4e84, 0xb7, 0xa8, 0xdc, 0xe1, 0x6f, 0x7b, 0x62, 0xd9);
	public const Guid FWPM_CONDITION_RESERVED3 = .(0x7f6e8ca3, 0x6606, 0x4932, 0x97, 0xc7, 0xe1, 0xf2, 0x07, 0x10, 0xaf, 0x3b);
	public const Guid FWPM_CONDITION_RESERVED4 = .(0x5f58e642, 0xb937, 0x495e, 0xa9, 0x4b, 0xf6, 0xb0, 0x51, 0xa4, 0x92, 0x50);
	public const Guid FWPM_CONDITION_RESERVED5 = .(0x9ba8f6cd, 0xf77c, 0x43e6, 0x88, 0x47, 0x11, 0x93, 0x9d, 0xc5, 0xdb, 0x5a);
	public const Guid FWPM_CONDITION_RESERVED6 = .(0xf13d84bd, 0x59d5, 0x44c4, 0x88, 0x17, 0x5e, 0xcd, 0xae, 0x18, 0x05, 0xbd);
	public const Guid FWPM_CONDITION_RESERVED7 = .(0x65a0f930, 0x45dd, 0x4983, 0xaa, 0x33, 0xef, 0xc7, 0xb6, 0x11, 0xaf, 0x08);
	public const Guid FWPM_CONDITION_RESERVED8 = .(0x4f424974, 0x0c12, 0x4816, 0x9b, 0x47, 0x9a, 0x54, 0x7d, 0xb3, 0x9a, 0x32);
	public const Guid FWPM_CONDITION_RESERVED9 = .(0xce78e10f, 0x13ff, 0x4c70, 0x86, 0x43, 0x36, 0xad, 0x18, 0x79, 0xaf, 0xa3);
	public const Guid FWPM_CONDITION_RESERVED10 = .(0xb979e282, 0xd621, 0x4c8c, 0xb1, 0x84, 0xb1, 0x05, 0xa6, 0x1c, 0x36, 0xce);
	public const Guid FWPM_CONDITION_RESERVED11 = .(0x2d62ee4d, 0x023d, 0x411f, 0x95, 0x82, 0x43, 0xac, 0xbb, 0x79, 0x59, 0x75);
	public const Guid FWPM_CONDITION_RESERVED12 = .(0xa3677c32, 0x7e35, 0x4ddc, 0x93, 0xda, 0xe8, 0xc3, 0x3f, 0xc9, 0x23, 0xc7);
	public const Guid FWPM_CONDITION_RESERVED13 = .(0x335a3e90, 0x84aa, 0x42f5, 0x9e, 0x6f, 0x59, 0x30, 0x95, 0x36, 0xa4, 0x4c);
	public const Guid FWPM_CONDITION_RESERVED14 = .(0x30e44da2, 0x2f1a, 0x4116, 0xa5, 0x59, 0xf9, 0x07, 0xde, 0x83, 0x60, 0x4a);
	public const Guid FWPM_CONDITION_RESERVED15 = .(0xbab8340f, 0xafe0, 0x43d1, 0x80, 0xd8, 0x5c, 0xa4, 0x56, 0x96, 0x2d, 0xe3);
	public const Guid FWPM_PROVIDER_IKEEXT = .(0x10ad9216, 0xccde, 0x456c, 0x8b, 0x16, 0xe9, 0xf0, 0x4e, 0x60, 0xa9, 0x0b);
	public const Guid FWPM_PROVIDER_IPSEC_DOSP_CONFIG = .(0x3c6c05a9, 0xc05c, 0x4bb9, 0x83, 0x38, 0x23, 0x27, 0x81, 0x4c, 0xe8, 0xbf);
	public const Guid FWPM_PROVIDER_TCP_CHIMNEY_OFFLOAD = .(0x896aa19e, 0x9a34, 0x4bcb, 0xae, 0x79, 0xbe, 0xb9, 0x12, 0x7c, 0x84, 0xb9);
	public const Guid FWPM_PROVIDER_TCP_TEMPLATES = .(0x76cfcd30, 0x3394, 0x432d, 0xbe, 0xd3, 0x44, 0x1a, 0xe5, 0x0e, 0x63, 0xc3);
	public const Guid FWPM_PROVIDER_MPSSVC_WSH = .(0x4b153735, 0x1049, 0x4480, 0xaa, 0xb4, 0xd1, 0xb9, 0xbd, 0xc0, 0x37, 0x10);
	public const Guid FWPM_PROVIDER_MPSSVC_WF = .(0xdecc16ca, 0x3f33, 0x4346, 0xbe, 0x1e, 0x8f, 0xb4, 0xae, 0x0f, 0x3d, 0x62);
	public const Guid FWPM_PROVIDER_MPSSVC_EDP = .(0xa90296f7, 0x46b8, 0x4457, 0x8f, 0x84, 0xb0, 0x5e, 0x05, 0xd3, 0xc6, 0x22);
	public const Guid FWPM_PROVIDER_MPSSVC_TENANT_RESTRICTIONS = .(0xd0718ff9, 0x44da, 0x4f50, 0x9d, 0xc2, 0xc9, 0x63, 0xa4, 0x24, 0x76, 0x13);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_TRANSPORT_V4 = .(0x5132900d, 0x5e84, 0x4b5f, 0x80, 0xe4, 0x01, 0x74, 0x1e, 0x81, 0xff, 0x10);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_TRANSPORT_V6 = .(0x49d3ac92, 0x2a6c, 0x4dcf, 0x95, 0x5f, 0x1c, 0x3b, 0xe0, 0x09, 0xdd, 0x99);
	public const Guid FWPM_CALLOUT_IPSEC_OUTBOUND_TRANSPORT_V4 = .(0x4b46bf0a, 0x4523, 0x4e57, 0xaa, 0x38, 0xa8, 0x79, 0x87, 0xc9, 0x10, 0xd9);
	public const Guid FWPM_CALLOUT_IPSEC_OUTBOUND_TRANSPORT_V6 = .(0x38d87722, 0xad83, 0x4f11, 0xa9, 0x1f, 0xdf, 0x0f, 0xb0, 0x77, 0x22, 0x5b);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_TUNNEL_V4 = .(0x191a8a46, 0x0bf8, 0x46cf, 0xb0, 0x45, 0x4b, 0x45, 0xdf, 0xa6, 0xa3, 0x24);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_TUNNEL_V6 = .(0x80c342e3, 0x1e53, 0x4d6f, 0x9b, 0x44, 0x03, 0xdf, 0x5a, 0xee, 0xe1, 0x54);
	public const Guid FWPM_CALLOUT_IPSEC_OUTBOUND_TUNNEL_V4 = .(0x70a4196c, 0x835b, 0x4fb0, 0x98, 0xe8, 0x07, 0x5f, 0x4d, 0x97, 0x7d, 0x46);
	public const Guid FWPM_CALLOUT_IPSEC_OUTBOUND_TUNNEL_V6 = .(0xf1835363, 0xa6a5, 0x4e62, 0xb1, 0x80, 0x23, 0xdb, 0x78, 0x9d, 0x8d, 0xa6);
	public const Guid FWPM_CALLOUT_IPSEC_FORWARD_INBOUND_TUNNEL_V4 = .(0x28829633, 0xc4f0, 0x4e66, 0x87, 0x3f, 0x84, 0x4d, 0xb2, 0xa8, 0x99, 0xc7);
	public const Guid FWPM_CALLOUT_IPSEC_FORWARD_INBOUND_TUNNEL_V6 = .(0xaf50bec2, 0xc686, 0x429a, 0x88, 0x4d, 0xb7, 0x44, 0x43, 0xe7, 0xb0, 0xb4);
	public const Guid FWPM_CALLOUT_IPSEC_FORWARD_OUTBOUND_TUNNEL_V4 = .(0xfb532136, 0x15cb, 0x440b, 0x93, 0x7c, 0x17, 0x17, 0xca, 0x32, 0x0c, 0x40);
	public const Guid FWPM_CALLOUT_IPSEC_FORWARD_OUTBOUND_TUNNEL_V6 = .(0xdae640cc, 0xe021, 0x4bee, 0x9e, 0xb6, 0xa4, 0x8b, 0x27, 0x5c, 0x8c, 0x1d);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_INITIATE_SECURE_V4 = .(0x7dff309b, 0xba7d, 0x4aba, 0x91, 0xaa, 0xae, 0x5c, 0x66, 0x40, 0xc9, 0x44);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_INITIATE_SECURE_V6 = .(0xa9a0d6d9, 0xc58c, 0x474e, 0x8a, 0xeb, 0x3c, 0xfe, 0x99, 0xd6, 0xd5, 0x3d);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_TUNNEL_ALE_ACCEPT_V4 = .(0x3df6e7de, 0xfd20, 0x48f2, 0x9f, 0x26, 0xf8, 0x54, 0x44, 0x4c, 0xba, 0x79);
	public const Guid FWPM_CALLOUT_IPSEC_INBOUND_TUNNEL_ALE_ACCEPT_V6 = .(0xa1e392d3, 0x72ac, 0x47bb, 0x87, 0xa7, 0x01, 0x22, 0xc6, 0x94, 0x34, 0xab);
	public const Guid FWPM_CALLOUT_IPSEC_ALE_CONNECT_V4 = .(0x6ac141fc, 0xf75d, 0x4203, 0xb9, 0xc8, 0x48, 0xe6, 0x14, 0x9c, 0x27, 0x12);
	public const Guid FWPM_CALLOUT_IPSEC_ALE_CONNECT_V6 = .(0x4c0dda05, 0xe31f, 0x4666, 0x90, 0xb0, 0xb3, 0xdf, 0xad, 0x34, 0x12, 0x9a);
	public const Guid FWPM_CALLOUT_IPSEC_DOSP_FORWARD_V6 = .(0x6d08a342, 0xdb9e, 0x4fbe, 0x9e, 0xd2, 0x57, 0x37, 0x4c, 0xe8, 0x9f, 0x79);
	public const Guid FWPM_CALLOUT_IPSEC_DOSP_FORWARD_V4 = .(0x2fcb56ec, 0xcd37, 0x4b4f, 0xb1, 0x08, 0x62, 0xc2, 0xb1, 0x85, 0x0a, 0x0c);
	public const Guid FWPM_CALLOUT_WFP_TRANSPORT_LAYER_V4_SILENT_DROP = .(0xeda08606, 0x2494, 0x4d78, 0x89, 0xbc, 0x67, 0x83, 0x7c, 0x03, 0xb9, 0x69);
	public const Guid FWPM_CALLOUT_WFP_TRANSPORT_LAYER_V6_SILENT_DROP = .(0x8693cc74, 0xa075, 0x4156, 0xb4, 0x76, 0x92, 0x86, 0xee, 0xce, 0x81, 0x4e);
	public const Guid FWPM_CALLOUT_TCP_CHIMNEY_CONNECT_LAYER_V4 = .(0xf3e10ab3, 0x2c25, 0x4279, 0xac, 0x36, 0xc3, 0x0f, 0xc1, 0x81, 0xbe, 0xc4);
	public const Guid FWPM_CALLOUT_TCP_CHIMNEY_CONNECT_LAYER_V6 = .(0x39e22085, 0xa341, 0x42fc, 0xa2, 0x79, 0xae, 0xc9, 0x4e, 0x68, 0x9c, 0x56);
	public const Guid FWPM_CALLOUT_TCP_CHIMNEY_ACCEPT_LAYER_V4 = .(0xe183ecb2, 0x3a7f, 0x4b54, 0x8a, 0xd9, 0x76, 0x05, 0x0e, 0xd8, 0x80, 0xca);
	public const Guid FWPM_CALLOUT_TCP_CHIMNEY_ACCEPT_LAYER_V6 = .(0x0378cf41, 0xbf98, 0x4603, 0x81, 0xf2, 0x7f, 0x12, 0x58, 0x60, 0x79, 0xf6);
	public const Guid FWPM_CALLOUT_SET_OPTIONS_AUTH_CONNECT_LAYER_V4 = .(0xbc582280, 0x1677, 0x41e9, 0x94, 0xab, 0xc2, 0xfc, 0xb1, 0x5c, 0x2e, 0xeb);
	public const Guid FWPM_CALLOUT_SET_OPTIONS_AUTH_CONNECT_LAYER_V6 = .(0x98e5373c, 0xb884, 0x490f, 0xb6, 0x5f, 0x2f, 0x6a, 0x4a, 0x57, 0x51, 0x95);
	public const Guid FWPM_CALLOUT_SET_OPTIONS_AUTH_RECV_ACCEPT_LAYER_V4 = .(0x2d55f008, 0x0c01, 0x4f92, 0xb2, 0x6e, 0xa0, 0x8a, 0x94, 0x56, 0x9b, 0x8d);
	public const Guid FWPM_CALLOUT_SET_OPTIONS_AUTH_RECV_ACCEPT_LAYER_V6 = .(0x63018537, 0xf281, 0x4dc4, 0x83, 0xd3, 0x8d, 0xec, 0x18, 0xb7, 0xad, 0xe2);
	public const Guid FWPM_CALLOUT_RESERVED_AUTH_CONNECT_LAYER_V4 = .(0x288b524d, 0x0566, 0x4e19, 0xb6, 0x12, 0x8f, 0x44, 0x1a, 0x2e, 0x59, 0x49);
	public const Guid FWPM_CALLOUT_RESERVED_AUTH_CONNECT_LAYER_V6 = .(0x00b84b92, 0x2b5e, 0x4b71, 0xab, 0x0e, 0xaa, 0xca, 0x43, 0xe3, 0x87, 0xe6);
	public const Guid FWPM_CALLOUT_TEREDO_ALE_RESOURCE_ASSIGNMENT_V6 = .(0x31b95392, 0x066e, 0x42a2, 0xb7, 0xdb, 0x92, 0xf8, 0xac, 0xdd, 0x56, 0xf9);
	public const Guid FWPM_CALLOUT_EDGE_TRAVERSAL_ALE_RESOURCE_ASSIGNMENT_V4 = .(0x079b1010, 0xf1c5, 0x4fcd, 0xae, 0x05, 0xda, 0x41, 0x10, 0x7a, 0xbd, 0x0b);
	public const Guid FWPM_CALLOUT_TEREDO_ALE_LISTEN_V6 = .(0x81a434e7, 0xf60c, 0x4378, 0xba, 0xb8, 0xc6, 0x25, 0xa3, 0x0f, 0x01, 0x97);
	public const Guid FWPM_CALLOUT_EDGE_TRAVERSAL_ALE_LISTEN_V4 = .(0x33486ab5, 0x6d5e, 0x4e65, 0xa0, 0x0b, 0xa7, 0xaf, 0xed, 0x0b, 0xa9, 0xa1);
	public const Guid FWPM_CALLOUT_TCP_TEMPLATES_CONNECT_LAYER_V4 = .(0x215a0b39, 0x4b7e, 0x4eda, 0x8c, 0xe4, 0x17, 0x96, 0x79, 0xdf, 0x62, 0x24);
	public const Guid FWPM_CALLOUT_TCP_TEMPLATES_CONNECT_LAYER_V6 = .(0x838b37a1, 0x5c12, 0x4d34, 0x8b, 0x38, 0x07, 0x87, 0x28, 0xb2, 0xd2, 0x5c);
	public const Guid FWPM_CALLOUT_TCP_TEMPLATES_ACCEPT_LAYER_V4 = .(0x2f23f5d0, 0x40c4, 0x4c41, 0xa2, 0x54, 0x46, 0xd8, 0xdb, 0xa8, 0x95, 0x7c);
	public const Guid FWPM_CALLOUT_TCP_TEMPLATES_ACCEPT_LAYER_V6 = .(0xb25152f0, 0x991c, 0x4f53, 0xbb, 0xe7, 0xd2, 0x4b, 0x45, 0xfe, 0x63, 0x2c);
	public const Guid FWPM_CALLOUT_POLICY_SILENT_MODE_AUTH_CONNECT_LAYER_V4 = .(0x5fbfc31d, 0xa51c, 0x44dc, 0xac, 0xb6, 0x06, 0x24, 0xa0, 0x30, 0xa7, 0x00);
	public const Guid FWPM_CALLOUT_POLICY_SILENT_MODE_AUTH_CONNECT_LAYER_V6 = .(0x5fbfc31d, 0xa51c, 0x44dc, 0xac, 0xb6, 0x06, 0x24, 0xa0, 0x30, 0xa7, 0x01);
	public const Guid FWPM_CALLOUT_POLICY_SILENT_MODE_AUTH_RECV_ACCEPT_LAYER_V4 = .(0x5fbfc31d, 0xa51c, 0x44dc, 0xac, 0xb6, 0x06, 0x24, 0xa0, 0x30, 0xa7, 0x02);
	public const Guid FWPM_CALLOUT_POLICY_SILENT_MODE_AUTH_RECV_ACCEPT_LAYER_V6 = .(0x5fbfc31d, 0xa51c, 0x44dc, 0xac, 0xb6, 0x06, 0x24, 0xa0, 0x30, 0xa7, 0x03);
	public const Guid FWPM_CALLOUT_HTTP_TEMPLATE_SSL_HANDSHAKE = .(0xb3423249, 0x8d09, 0x4858, 0x92, 0x10, 0x95, 0xc7, 0xfd, 0xa8, 0xe3, 0x0f);
	public const Guid FWPM_CALLOUT_BUILT_IN_RESERVED_1 = .(0x779719a4, 0xe695, 0x47b6, 0xa1, 0x99, 0x79, 0x99, 0xfe, 0xc9, 0x16, 0x3b);
	public const Guid FWPM_CALLOUT_BUILT_IN_RESERVED_2 = .(0xef9661b6, 0x7c5e, 0x48fd, 0xa1, 0x30, 0x96, 0x67, 0x8c, 0xea, 0xcc, 0x41);
	public const Guid FWPM_CALLOUT_BUILT_IN_RESERVED_3 = .(0x18729c7a, 0x2f62, 0x4be0, 0x96, 0x6f, 0x97, 0x4b, 0x21, 0xb8, 0x6d, 0xf1);
	public const Guid FWPM_CALLOUT_BUILT_IN_RESERVED_4 = .(0x6c3fb801, 0xdaff, 0x40e9, 0x91, 0xe6, 0xf7, 0xff, 0x7e, 0x52, 0xf7, 0xd9);
	public const Guid FWPM_PROVIDER_CONTEXT_SECURE_SOCKET_AUTHIP = .(0xb25ea800, 0x0d02, 0x46ed, 0x92, 0xbd, 0x7f, 0xa8, 0x4b, 0xb7, 0x3e, 0x9d);
	public const Guid FWPM_PROVIDER_CONTEXT_SECURE_SOCKET_IPSEC = .(0x8c2d4144, 0xf8e0, 0x42c0, 0x94, 0xce, 0x7c, 0xcf, 0xc6, 0x3b, 0x2f, 0x9b);
	public const Guid FWPM_KEYING_MODULE_IKE = .(0xa9bbf787, 0x82a8, 0x45bb, 0xa4, 0x00, 0x5d, 0x7e, 0x59, 0x52, 0xc7, 0xa9);
	public const Guid FWPM_KEYING_MODULE_AUTHIP = .(0x11e3dae0, 0xdd26, 0x4590, 0x85, 0x7d, 0xab, 0x4b, 0x28, 0xd1, 0xa0, 0x95);
	public const Guid FWPM_KEYING_MODULE_IKEV2 = .(0x041792cc, 0x8f07, 0x419d, 0xa3, 0x94, 0x71, 0x69, 0x68, 0xcb, 0x16, 0x47);
	public const uint32 FWPM_AUTO_WEIGHT_BITS = 60;
	public const uint32 FWPM_WEIGHT_RANGE_IPSEC = 0;
	public const uint32 FWPM_WEIGHT_RANGE_IKE_EXEMPTIONS = 12;
	public const uint32 FWPM_ACTRL_ADD = 1;
	public const uint32 FWPM_ACTRL_ADD_LINK = 2;
	public const uint32 FWPM_ACTRL_BEGIN_READ_TXN = 4;
	public const uint32 FWPM_ACTRL_BEGIN_WRITE_TXN = 8;
	public const uint32 FWPM_ACTRL_CLASSIFY = 16;
	public const uint32 FWPM_ACTRL_ENUM = 32;
	public const uint32 FWPM_ACTRL_OPEN = 64;
	public const uint32 FWPM_ACTRL_READ = 128;
	public const uint32 FWPM_ACTRL_READ_STATS = 256;
	public const uint32 FWPM_ACTRL_SUBSCRIBE = 512;
	public const uint32 FWPM_ACTRL_WRITE = 1024;
	public const uint32 FWPM_TXN_READ_ONLY = 1;
	public const uint32 FWPM_TUNNEL_FLAG_POINT_TO_POINT = 1;
	public const uint32 FWPM_TUNNEL_FLAG_ENABLE_VIRTUAL_IF_TUNNELING = 2;
	public const uint32 FWPM_TUNNEL_FLAG_RESERVED0 = 4;
	public const uint32 FWPS_METADATA_FIELD_DISCARD_REASON = 1;
	public const uint32 FWPS_METADATA_FIELD_FLOW_HANDLE = 2;
	public const uint32 FWPS_METADATA_FIELD_IP_HEADER_SIZE = 4;
	public const uint32 FWPS_METADATA_FIELD_PROCESS_PATH = 8;
	public const uint32 FWPS_METADATA_FIELD_TOKEN = 16;
	public const uint32 FWPS_METADATA_FIELD_PROCESS_ID = 32;
	public const uint32 FWPS_METADATA_FIELD_SYSTEM_FLAGS = 64;
	public const uint32 FWPS_METADATA_FIELD_RESERVED = 128;
	public const uint32 FWPS_METADATA_FIELD_SOURCE_INTERFACE_INDEX = 256;
	public const uint32 FWPS_METADATA_FIELD_DESTINATION_INTERFACE_INDEX = 512;
	public const uint32 FWPS_METADATA_FIELD_TRANSPORT_HEADER_SIZE = 1024;
	public const uint32 FWPS_METADATA_FIELD_COMPARTMENT_ID = 2048;
	public const uint32 FWPS_METADATA_FIELD_FRAGMENT_DATA = 4096;
	public const uint32 FWPS_METADATA_FIELD_PATH_MTU = 8192;
	public const uint32 FWPS_METADATA_FIELD_COMPLETION_HANDLE = 16384;
	public const uint32 FWPS_METADATA_FIELD_TRANSPORT_ENDPOINT_HANDLE = 32768;
	public const uint32 FWPS_METADATA_FIELD_TRANSPORT_CONTROL_DATA = 65536;
	public const uint32 FWPS_METADATA_FIELD_REMOTE_SCOPE_ID = 131072;
	public const uint32 FWPS_METADATA_FIELD_PACKET_DIRECTION = 262144;
	public const uint32 FWPS_METADATA_FIELD_PACKET_SYSTEM_CRITICAL = 524288;
	public const uint32 FWPS_METADATA_FIELD_FORWARD_LAYER_OUTBOUND_PASS_THRU = 1048576;
	public const uint32 FWPS_METADATA_FIELD_FORWARD_LAYER_INBOUND_PASS_THRU = 2097152;
	public const uint32 FWPS_METADATA_FIELD_ALE_CLASSIFY_REQUIRED = 4194304;
	public const uint32 FWPS_METADATA_FIELD_TRANSPORT_HEADER_INCLUDE_HEADER = 8388608;
	public const uint32 FWPS_METADATA_FIELD_DESTINATION_PREFIX = 16777216;
	public const uint32 FWPS_METADATA_FIELD_ETHER_FRAME_LENGTH = 33554432;
	public const uint32 FWPS_METADATA_FIELD_PARENT_ENDPOINT_HANDLE = 67108864;
	public const uint32 FWPS_METADATA_FIELD_ICMP_ID_AND_SEQUENCE = 134217728;
	public const uint32 FWPS_METADATA_FIELD_LOCAL_REDIRECT_TARGET_PID = 268435456;
	public const uint32 FWPS_METADATA_FIELD_ORIGINAL_DESTINATION = 536870912;
	public const uint32 FWPS_METADATA_FIELD_REDIRECT_RECORD_HANDLE = 1073741824;
	public const uint32 FWPS_METADATA_FIELD_SUB_PROCESS_TAG = 2147483648;
	public const uint32 FWPS_L2_METADATA_FIELD_ETHERNET_MAC_HEADER_SIZE = 1;
	public const uint32 FWPS_L2_METADATA_FIELD_WIFI_OPERATION_MODE = 2;
	public const uint32 FWPS_L2_METADATA_FIELD_VSWITCH_SOURCE_PORT_ID = 4;
	public const uint32 FWPS_L2_METADATA_FIELD_VSWITCH_SOURCE_NIC_INDEX = 8;
	public const uint32 FWPS_L2_METADATA_FIELD_VSWITCH_PACKET_CONTEXT = 16;
	public const uint32 FWPS_L2_METADATA_FIELD_VSWITCH_DESTINATION_PORT_ID = 32;
	public const uint32 FWPS_L2_METADATA_FIELD_RESERVED = 2147483648;
}
#endregion

#region Enums

[AllowDuplicates]
public enum IPSEC_SA_BUNDLE_FLAGS : uint32
{
	IPSEC_SA_BUNDLE_FLAG_ND_SECURE = 1,
	IPSEC_SA_BUNDLE_FLAG_ND_BOUNDARY = 2,
	IPSEC_SA_BUNDLE_FLAG_ND_PEER_NAT_BOUNDARY = 4,
	IPSEC_SA_BUNDLE_FLAG_GUARANTEE_ENCRYPTION = 8,
	IPSEC_SA_BUNDLE_FLAG_ALLOW_NULL_TARGET_NAME_MATCH = 512,
	IPSEC_SA_BUNDLE_FLAG_CLEAR_DF_ON_TUNNEL = 1024,
	IPSEC_SA_BUNDLE_FLAG_ASSUME_UDP_CONTEXT_OUTBOUND = 2048,
	IPSEC_SA_BUNDLE_FLAG_ND_PEER_BOUNDARY = 4096,
	IPSEC_SA_BUNDLE_FLAG_SUPPRESS_DUPLICATE_DELETION = 8192,
	IPSEC_SA_BUNDLE_FLAG_PEER_SUPPORTS_GUARANTEE_ENCRYPTION = 16384,
}


[AllowDuplicates]
public enum IPSEC_POLICY_FLAG : uint32
{
	IPSEC_POLICY_FLAG_ND_SECURE = 2,
	IPSEC_POLICY_FLAG_ND_BOUNDARY = 4,
	IPSEC_POLICY_FLAG_NAT_ENCAP_ALLOW_PEER_BEHIND_NAT = 16,
	IPSEC_POLICY_FLAG_NAT_ENCAP_ALLOW_GENERAL_NAT_TRAVERSAL = 32,
	IPSEC_POLICY_FLAG_DONT_NEGOTIATE_SECOND_LIFETIME = 64,
	IPSEC_POLICY_FLAG_DONT_NEGOTIATE_BYTE_LIFETIME = 128,
	IPSEC_POLICY_FLAG_CLEAR_DF_ON_TUNNEL = 8,
	IPSEC_POLICY_FLAG_ENABLE_V6_IN_V4_TUNNELING = 256,
	IPSEC_POLICY_FLAG_ENABLE_SERVER_ADDR_ASSIGNMENT = 512,
	IPSEC_POLICY_FLAG_TUNNEL_ALLOW_OUTBOUND_CLEAR_CONNECTION = 1024,
	IPSEC_POLICY_FLAG_TUNNEL_BYPASS_ALREADY_SECURE_CONNECTION = 2048,
	IPSEC_POLICY_FLAG_TUNNEL_BYPASS_ICMPV6 = 4096,
	IPSEC_POLICY_FLAG_KEY_MANAGER_ALLOW_DICTATE_KEY = 8192,
}


[AllowDuplicates]
public enum IKEEXT_CERT_AUTH : uint32
{
	IKEEXT_CERT_AUTH_FLAG_SSL_ONE_WAY = 1,
	IKEEXT_CERT_AUTH_ENABLE_CRL_CHECK_STRONG = 4,
	IKEEXT_CERT_AUTH_DISABLE_SSL_CERT_VALIDATION = 8,
	IKEEXT_CERT_AUTH_ALLOW_HTTP_CERT_LOOKUP = 16,
	IKEEXT_CERT_AUTH_URL_CONTAINS_BUNDLE = 32,
}


[AllowDuplicates]
public enum IKEEXT_PRESHARED_KEY_AUTHENTICATION_FLAGS : uint32
{
	IKEEXT_PSK_FLAG_LOCAL_AUTH_ONLY = 1,
	IKEEXT_PSK_FLAG_REMOTE_AUTH_ONLY = 2,
}


[AllowDuplicates]
public enum IKEEXT_POLICY_FLAG : uint32
{
	IKEEXT_POLICY_FLAG_DISABLE_DIAGNOSTICS = 1,
	IKEEXT_POLICY_FLAG_NO_MACHINE_LUID_VERIFY = 2,
	IKEEXT_POLICY_FLAG_NO_IMPERSONATION_LUID_VERIFY = 4,
	IKEEXT_POLICY_FLAG_ENABLE_OPTIONAL_DH = 8,
}


[AllowDuplicates]
public enum FWPM_SUBSCRIPTION_FLAGS : uint32
{
	FWPM_SUBSCRIPTION_FLAG_NOTIFY_ON_ADD = 1,
	FWPM_SUBSCRIPTION_FLAG_NOTIFY_ON_DELETE = 2,
}


[AllowDuplicates]
public enum IKEEXT_CERT_FLAGS : uint32
{
	IKEEXT_CERT_FLAG_ENABLE_ACCOUNT_MAPPING = 1,
	IKEEXT_CERT_FLAG_DISABLE_REQUEST_PAYLOAD = 2,
	IKEEXT_CERT_FLAG_USE_NAP_CERTIFICATE = 4,
	IKEEXT_CERT_FLAG_INTERMEDIATE_CA = 8,
	IKEEXT_CERT_FLAG_IGNORE_INIT_CERT_MAP_FAILURE = 16,
	IKEEXT_CERT_FLAG_PREFER_NAP_CERTIFICATE_OUTBOUND = 32,
	IKEEXT_CERT_FLAG_SELECT_NAP_CERTIFICATE = 64,
	IKEEXT_CERT_FLAG_VERIFY_NAP_CERTIFICATE = 128,
	IKEEXT_CERT_FLAG_FOLLOW_RENEWAL_CERTIFICATE = 256,
}


[AllowDuplicates]
public enum IPSEC_DOSP_FLAGS : uint32
{
	IPSEC_DOSP_FLAG_ENABLE_IKEV1 = 1,
	IPSEC_DOSP_FLAG_ENABLE_IKEV2 = 2,
	IPSEC_DOSP_FLAG_DISABLE_AUTHIP = 4,
	IPSEC_DOSP_FLAG_DISABLE_DEFAULT_BLOCK = 8,
	IPSEC_DOSP_FLAG_FILTER_BLOCK = 16,
	IPSEC_DOSP_FLAG_FILTER_EXEMPT = 32,
}


[AllowDuplicates]
public enum IKEEXT_KERBEROS_AUTHENTICATION_FLAGS : uint32
{
	IKEEXT_KERB_AUTH_DISABLE_INITIATOR_TOKEN_GENERATION = 1,
	IKEEXT_KERB_AUTH_DONT_ACCEPT_EXPLICIT_CREDENTIALS = 2,
}


[AllowDuplicates]
public enum IKEEXT_RESERVED_AUTHENTICATION_FLAGS : uint32
{
	IKEEXT_RESERVED_AUTH_DISABLE_INITIATOR_TOKEN_GENERATION = 1,
}


[AllowDuplicates]
public enum IKEEXT_EAP_AUTHENTICATION_FLAGS : uint32
{
	IKEEXT_EAP_FLAG_LOCAL_AUTH_ONLY = 1,
	IKEEXT_EAP_FLAG_REMOTE_AUTH_ONLY = 2,
}


[AllowDuplicates]
public enum FWPM_FILTER_FLAGS : uint32
{
	FWPM_FILTER_FLAG_NONE = 0,
	FWPM_FILTER_FLAG_PERSISTENT = 1,
	FWPM_FILTER_FLAG_BOOTTIME = 2,
	FWPM_FILTER_FLAG_HAS_PROVIDER_CONTEXT = 4,
	FWPM_FILTER_FLAG_CLEAR_ACTION_RIGHT = 8,
	FWPM_FILTER_FLAG_PERMIT_IF_CALLOUT_UNREGISTERED = 16,
	FWPM_FILTER_FLAG_DISABLED = 32,
	FWPM_FILTER_FLAG_INDEXED = 64,
}


[AllowDuplicates]
public enum FWP_DIRECTION : int32
{
	FWP_DIRECTION_OUTBOUND = 0,
	FWP_DIRECTION_INBOUND = 1,
	FWP_DIRECTION_MAX = 2,
}


[AllowDuplicates]
public enum FWP_IP_VERSION : int32
{
	FWP_IP_VERSION_V4 = 0,
	FWP_IP_VERSION_V6 = 1,
	FWP_IP_VERSION_NONE = 2,
	FWP_IP_VERSION_MAX = 3,
}


[AllowDuplicates]
public enum FWP_AF : int32
{
	FWP_AF_INET = 0,
	FWP_AF_INET6 = 1,
	FWP_AF_ETHER = 2,
	FWP_AF_NONE = 3,
}


[AllowDuplicates]
public enum FWP_ETHER_ENCAP_METHOD : int32
{
	FWP_ETHER_ENCAP_METHOD_ETHER_V2 = 0,
	FWP_ETHER_ENCAP_METHOD_SNAP = 1,
	FWP_ETHER_ENCAP_METHOD_SNAP_W_OUI_ZERO = 3,
}


[AllowDuplicates]
public enum FWP_DATA_TYPE : int32
{
	FWP_EMPTY = 0,
	FWP_UINT8 = 1,
	FWP_UINT16 = 2,
	FWP_UINT32 = 3,
	FWP_UINT64 = 4,
	FWP_INT8 = 5,
	FWP_INT16 = 6,
	FWP_INT32 = 7,
	FWP_INT64 = 8,
	FWP_FLOAT = 9,
	FWP_DOUBLE = 10,
	FWP_BYTE_ARRAY16_TYPE = 11,
	FWP_BYTE_BLOB_TYPE = 12,
	FWP_SID = 13,
	FWP_SECURITY_DESCRIPTOR_TYPE = 14,
	FWP_TOKEN_INFORMATION_TYPE = 15,
	FWP_TOKEN_ACCESS_INFORMATION_TYPE = 16,
	FWP_UNICODE_STRING_TYPE = 17,
	FWP_BYTE_ARRAY6_TYPE = 18,
	FWP_SINGLE_DATA_TYPE_MAX = 255,
	FWP_V4_ADDR_MASK = 256,
	FWP_V6_ADDR_MASK = 257,
	FWP_RANGE_TYPE = 258,
	FWP_DATA_TYPE_MAX = 259,
}


[AllowDuplicates]
public enum FWP_MATCH_TYPE : int32
{
	FWP_MATCH_EQUAL = 0,
	FWP_MATCH_GREATER = 1,
	FWP_MATCH_LESS = 2,
	FWP_MATCH_GREATER_OR_EQUAL = 3,
	FWP_MATCH_LESS_OR_EQUAL = 4,
	FWP_MATCH_RANGE = 5,
	FWP_MATCH_FLAGS_ALL_SET = 6,
	FWP_MATCH_FLAGS_ANY_SET = 7,
	FWP_MATCH_FLAGS_NONE_SET = 8,
	FWP_MATCH_EQUAL_CASE_INSENSITIVE = 9,
	FWP_MATCH_NOT_EQUAL = 10,
	FWP_MATCH_PREFIX = 11,
	FWP_MATCH_NOT_PREFIX = 12,
	FWP_MATCH_TYPE_MAX = 13,
}


[AllowDuplicates]
public enum FWP_CLASSIFY_OPTION_TYPE : int32
{
	FWP_CLASSIFY_OPTION_MULTICAST_STATE = 0,
	FWP_CLASSIFY_OPTION_LOOSE_SOURCE_MAPPING = 1,
	FWP_CLASSIFY_OPTION_UNICAST_LIFETIME = 2,
	FWP_CLASSIFY_OPTION_MCAST_BCAST_LIFETIME = 3,
	FWP_CLASSIFY_OPTION_SECURE_SOCKET_SECURITY_FLAGS = 4,
	FWP_CLASSIFY_OPTION_SECURE_SOCKET_AUTHIP_MM_POLICY_KEY = 5,
	FWP_CLASSIFY_OPTION_SECURE_SOCKET_AUTHIP_QM_POLICY_KEY = 6,
	FWP_CLASSIFY_OPTION_LOCAL_ONLY_MAPPING = 7,
	FWP_CLASSIFY_OPTION_MAX = 8,
}


[AllowDuplicates]
public enum FWP_VSWITCH_NETWORK_TYPE : int32
{
	FWP_VSWITCH_NETWORK_TYPE_UNKNOWN = 0,
	FWP_VSWITCH_NETWORK_TYPE_PRIVATE = 1,
	FWP_VSWITCH_NETWORK_TYPE_INTERNAL = 2,
	FWP_VSWITCH_NETWORK_TYPE_EXTERNAL = 3,
}


[AllowDuplicates]
public enum FWP_FILTER_ENUM_TYPE : int32
{
	FWP_FILTER_ENUM_FULLY_CONTAINED = 0,
	FWP_FILTER_ENUM_OVERLAPPING = 1,
	FWP_FILTER_ENUM_TYPE_MAX = 2,
}


[AllowDuplicates]
public enum IKEEXT_KEY_MODULE_TYPE : int32
{
	IKEEXT_KEY_MODULE_IKE = 0,
	IKEEXT_KEY_MODULE_AUTHIP = 1,
	IKEEXT_KEY_MODULE_IKEV2 = 2,
	IKEEXT_KEY_MODULE_MAX = 3,
}


[AllowDuplicates]
public enum IKEEXT_AUTHENTICATION_METHOD_TYPE : int32
{
	IKEEXT_PRESHARED_KEY = 0,
	IKEEXT_CERTIFICATE = 1,
	IKEEXT_KERBEROS = 2,
	IKEEXT_ANONYMOUS = 3,
	IKEEXT_SSL = 4,
	IKEEXT_NTLM_V2 = 5,
	IKEEXT_IPV6_CGA = 6,
	IKEEXT_CERTIFICATE_ECDSA_P256 = 7,
	IKEEXT_CERTIFICATE_ECDSA_P384 = 8,
	IKEEXT_SSL_ECDSA_P256 = 9,
	IKEEXT_SSL_ECDSA_P384 = 10,
	IKEEXT_EAP = 11,
	IKEEXT_RESERVED = 12,
	IKEEXT_AUTHENTICATION_METHOD_TYPE_MAX = 13,
}


[AllowDuplicates]
public enum IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE : int32
{
	IKEEXT_IMPERSONATION_NONE = 0,
	IKEEXT_IMPERSONATION_SOCKET_PRINCIPAL = 1,
	IKEEXT_IMPERSONATION_MAX = 2,
}


[AllowDuplicates]
public enum IKEEXT_CERT_CONFIG_TYPE : int32
{
	IKEEXT_CERT_CONFIG_EXPLICIT_TRUST_LIST = 0,
	IKEEXT_CERT_CONFIG_ENTERPRISE_STORE = 1,
	IKEEXT_CERT_CONFIG_TRUSTED_ROOT_STORE = 2,
	IKEEXT_CERT_CONFIG_UNSPECIFIED = 3,
	IKEEXT_CERT_CONFIG_TYPE_MAX = 4,
}


[AllowDuplicates]
public enum IKEEXT_CERT_CRITERIA_NAME_TYPE : int32
{
	IKEEXT_CERT_CRITERIA_DNS = 0,
	IKEEXT_CERT_CRITERIA_UPN = 1,
	IKEEXT_CERT_CRITERIA_RFC822 = 2,
	IKEEXT_CERT_CRITERIA_CN = 3,
	IKEEXT_CERT_CRITERIA_OU = 4,
	IKEEXT_CERT_CRITERIA_O = 5,
	IKEEXT_CERT_CRITERIA_DC = 6,
	IKEEXT_CERT_CRITERIA_NAME_TYPE_MAX = 7,
}


[AllowDuplicates]
public enum IKEEXT_CIPHER_TYPE : int32
{
	IKEEXT_CIPHER_DES = 0,
	IKEEXT_CIPHER_3DES = 1,
	IKEEXT_CIPHER_AES_128 = 2,
	IKEEXT_CIPHER_AES_192 = 3,
	IKEEXT_CIPHER_AES_256 = 4,
	IKEEXT_CIPHER_AES_GCM_128_16ICV = 5,
	IKEEXT_CIPHER_AES_GCM_256_16ICV = 6,
	IKEEXT_CIPHER_TYPE_MAX = 7,
}


[AllowDuplicates]
public enum IKEEXT_INTEGRITY_TYPE : int32
{
	IKEEXT_INTEGRITY_MD5 = 0,
	IKEEXT_INTEGRITY_SHA1 = 1,
	IKEEXT_INTEGRITY_SHA_256 = 2,
	IKEEXT_INTEGRITY_SHA_384 = 3,
	IKEEXT_INTEGRITY_TYPE_MAX = 4,
}


[AllowDuplicates]
public enum IKEEXT_DH_GROUP : int32
{
	IKEEXT_DH_GROUP_NONE = 0,
	IKEEXT_DH_GROUP_1 = 1,
	IKEEXT_DH_GROUP_2 = 2,
	IKEEXT_DH_GROUP_14 = 3,
	IKEEXT_DH_GROUP_2048 = 3,
	IKEEXT_DH_ECP_256 = 4,
	IKEEXT_DH_ECP_384 = 5,
	IKEEXT_DH_GROUP_24 = 6,
	IKEEXT_DH_GROUP_MAX = 7,
}


[AllowDuplicates]
public enum IKEEXT_MM_SA_STATE : int32
{
	IKEEXT_MM_SA_STATE_NONE = 0,
	IKEEXT_MM_SA_STATE_SA_SENT = 1,
	IKEEXT_MM_SA_STATE_SSPI_SENT = 2,
	IKEEXT_MM_SA_STATE_FINAL = 3,
	IKEEXT_MM_SA_STATE_FINAL_SENT = 4,
	IKEEXT_MM_SA_STATE_COMPLETE = 5,
	IKEEXT_MM_SA_STATE_MAX = 6,
}


[AllowDuplicates]
public enum IKEEXT_QM_SA_STATE : int32
{
	IKEEXT_QM_SA_STATE_NONE = 0,
	IKEEXT_QM_SA_STATE_INITIAL = 1,
	IKEEXT_QM_SA_STATE_FINAL = 2,
	IKEEXT_QM_SA_STATE_COMPLETE = 3,
	IKEEXT_QM_SA_STATE_MAX = 4,
}


[AllowDuplicates]
public enum IKEEXT_EM_SA_STATE : int32
{
	IKEEXT_EM_SA_STATE_NONE = 0,
	IKEEXT_EM_SA_STATE_SENT_ATTS = 1,
	IKEEXT_EM_SA_STATE_SSPI_SENT = 2,
	IKEEXT_EM_SA_STATE_AUTH_COMPLETE = 3,
	IKEEXT_EM_SA_STATE_FINAL = 4,
	IKEEXT_EM_SA_STATE_COMPLETE = 5,
	IKEEXT_EM_SA_STATE_MAX = 6,
}


[AllowDuplicates]
public enum IKEEXT_SA_ROLE : int32
{
	IKEEXT_SA_ROLE_INITIATOR = 0,
	IKEEXT_SA_ROLE_RESPONDER = 1,
	IKEEXT_SA_ROLE_MAX = 2,
}


[AllowDuplicates]
public enum IPSEC_TRANSFORM_TYPE : int32
{
	IPSEC_TRANSFORM_AH = 1,
	IPSEC_TRANSFORM_ESP_AUTH = 2,
	IPSEC_TRANSFORM_ESP_CIPHER = 3,
	IPSEC_TRANSFORM_ESP_AUTH_AND_CIPHER = 4,
	IPSEC_TRANSFORM_ESP_AUTH_FW = 5,
	IPSEC_TRANSFORM_TYPE_MAX = 6,
}


[AllowDuplicates]
public enum IPSEC_AUTH_TYPE : int32
{
	IPSEC_AUTH_MD5 = 0,
	IPSEC_AUTH_SHA_1 = 1,
	IPSEC_AUTH_SHA_256 = 2,
	IPSEC_AUTH_AES_128 = 3,
	IPSEC_AUTH_AES_192 = 4,
	IPSEC_AUTH_AES_256 = 5,
	IPSEC_AUTH_MAX = 6,
}


[AllowDuplicates]
public enum IPSEC_CIPHER_TYPE : int32
{
	IPSEC_CIPHER_TYPE_DES = 1,
	IPSEC_CIPHER_TYPE_3DES = 2,
	IPSEC_CIPHER_TYPE_AES_128 = 3,
	IPSEC_CIPHER_TYPE_AES_192 = 4,
	IPSEC_CIPHER_TYPE_AES_256 = 5,
	IPSEC_CIPHER_TYPE_MAX = 6,
}


[AllowDuplicates]
public enum IPSEC_PFS_GROUP : int32
{
	IPSEC_PFS_NONE = 0,
	IPSEC_PFS_1 = 1,
	IPSEC_PFS_2 = 2,
	IPSEC_PFS_2048 = 3,
	IPSEC_PFS_14 = 3,
	IPSEC_PFS_ECP_256 = 4,
	IPSEC_PFS_ECP_384 = 5,
	IPSEC_PFS_MM = 6,
	IPSEC_PFS_24 = 7,
	IPSEC_PFS_MAX = 8,
}


[AllowDuplicates]
public enum IPSEC_TOKEN_TYPE : int32
{
	IPSEC_TOKEN_TYPE_MACHINE = 0,
	IPSEC_TOKEN_TYPE_IMPERSONATION = 1,
	IPSEC_TOKEN_TYPE_MAX = 2,
}


[AllowDuplicates]
public enum IPSEC_TOKEN_PRINCIPAL : int32
{
	IPSEC_TOKEN_PRINCIPAL_LOCAL = 0,
	IPSEC_TOKEN_PRINCIPAL_PEER = 1,
	IPSEC_TOKEN_PRINCIPAL_MAX = 2,
}


[AllowDuplicates]
public enum IPSEC_TOKEN_MODE : int32
{
	IPSEC_TOKEN_MODE_MAIN = 0,
	IPSEC_TOKEN_MODE_EXTENDED = 1,
	IPSEC_TOKEN_MODE_MAX = 2,
}


[AllowDuplicates]
public enum IPSEC_TRAFFIC_TYPE : int32
{
	IPSEC_TRAFFIC_TYPE_TRANSPORT = 0,
	IPSEC_TRAFFIC_TYPE_TUNNEL = 1,
	IPSEC_TRAFFIC_TYPE_MAX = 2,
}


[AllowDuplicates]
public enum IPSEC_SA_CONTEXT_EVENT_TYPE0 : int32
{
	IPSEC_SA_CONTEXT_EVENT_ADD = 1,
	IPSEC_SA_CONTEXT_EVENT_DELETE = 2,
	IPSEC_SA_CONTEXT_EVENT_MAX = 3,
}


[AllowDuplicates]
public enum IPSEC_FAILURE_POINT : int32
{
	IPSEC_FAILURE_NONE = 0,
	IPSEC_FAILURE_ME = 1,
	IPSEC_FAILURE_PEER = 2,
	IPSEC_FAILURE_POINT_MAX = 3,
}


[AllowDuplicates]
public enum DL_ADDRESS_TYPE : int32
{
	DlUnicast = 0,
	DlMulticast = 1,
	DlBroadcast = 2,
}


[AllowDuplicates]
public enum FWPM_CHANGE_TYPE : int32
{
	FWPM_CHANGE_ADD = 1,
	FWPM_CHANGE_DELETE = 2,
	FWPM_CHANGE_TYPE_MAX = 3,
}


[AllowDuplicates]
public enum FWPM_SERVICE_STATE : int32
{
	FWPM_SERVICE_STOPPED = 0,
	FWPM_SERVICE_START_PENDING = 1,
	FWPM_SERVICE_STOP_PENDING = 2,
	FWPM_SERVICE_RUNNING = 3,
	FWPM_SERVICE_STATE_MAX = 4,
}


[AllowDuplicates]
public enum FWPM_ENGINE_OPTION : int32
{
	FWPM_ENGINE_COLLECT_NET_EVENTS = 0,
	FWPM_ENGINE_NET_EVENT_MATCH_ANY_KEYWORDS = 1,
	FWPM_ENGINE_NAME_CACHE = 2,
	FWPM_ENGINE_MONITOR_IPSEC_CONNECTIONS = 3,
	FWPM_ENGINE_PACKET_QUEUING = 4,
	FWPM_ENGINE_TXN_WATCHDOG_TIMEOUT_IN_MSEC = 5,
	FWPM_ENGINE_OPTION_MAX = 6,
}


[AllowDuplicates]
public enum FWPM_PROVIDER_CONTEXT_TYPE : int32
{
	FWPM_IPSEC_KEYING_CONTEXT = 0,
	FWPM_IPSEC_IKE_QM_TRANSPORT_CONTEXT = 1,
	FWPM_IPSEC_IKE_QM_TUNNEL_CONTEXT = 2,
	FWPM_IPSEC_AUTHIP_QM_TRANSPORT_CONTEXT = 3,
	FWPM_IPSEC_AUTHIP_QM_TUNNEL_CONTEXT = 4,
	FWPM_IPSEC_IKE_MM_CONTEXT = 5,
	FWPM_IPSEC_AUTHIP_MM_CONTEXT = 6,
	FWPM_CLASSIFY_OPTIONS_CONTEXT = 7,
	FWPM_GENERAL_CONTEXT = 8,
	FWPM_IPSEC_IKEV2_QM_TUNNEL_CONTEXT = 9,
	FWPM_IPSEC_IKEV2_MM_CONTEXT = 10,
	FWPM_IPSEC_DOSP_CONTEXT = 11,
	FWPM_IPSEC_IKEV2_QM_TRANSPORT_CONTEXT = 12,
	FWPM_PROVIDER_CONTEXT_TYPE_MAX = 13,
}


[AllowDuplicates]
public enum FWPM_FIELD_TYPE : int32
{
	FWPM_FIELD_RAW_DATA = 0,
	FWPM_FIELD_IP_ADDRESS = 1,
	FWPM_FIELD_FLAGS = 2,
	FWPM_FIELD_TYPE_MAX = 3,
}


[AllowDuplicates]
public enum FWPM_NET_EVENT_TYPE : int32
{
	FWPM_NET_EVENT_TYPE_IKEEXT_MM_FAILURE = 0,
	FWPM_NET_EVENT_TYPE_IKEEXT_QM_FAILURE = 1,
	FWPM_NET_EVENT_TYPE_IKEEXT_EM_FAILURE = 2,
	FWPM_NET_EVENT_TYPE_CLASSIFY_DROP = 3,
	FWPM_NET_EVENT_TYPE_IPSEC_KERNEL_DROP = 4,
	FWPM_NET_EVENT_TYPE_IPSEC_DOSP_DROP = 5,
	FWPM_NET_EVENT_TYPE_CLASSIFY_ALLOW = 6,
	FWPM_NET_EVENT_TYPE_CAPABILITY_DROP = 7,
	FWPM_NET_EVENT_TYPE_CAPABILITY_ALLOW = 8,
	FWPM_NET_EVENT_TYPE_CLASSIFY_DROP_MAC = 9,
	FWPM_NET_EVENT_TYPE_LPM_PACKET_ARRIVAL = 10,
	FWPM_NET_EVENT_TYPE_MAX = 11,
}


[AllowDuplicates]
public enum FWPM_APPC_NETWORK_CAPABILITY_TYPE : int32
{
	FWPM_APPC_NETWORK_CAPABILITY_INTERNET_CLIENT = 0,
	FWPM_APPC_NETWORK_CAPABILITY_INTERNET_CLIENT_SERVER = 1,
	FWPM_APPC_NETWORK_CAPABILITY_INTERNET_PRIVATE_NETWORK = 2,
}


[AllowDuplicates]
public enum FWPM_SYSTEM_PORT_TYPE : int32
{
	FWPM_SYSTEM_PORT_RPC_EPMAP = 0,
	FWPM_SYSTEM_PORT_TEREDO = 1,
	FWPM_SYSTEM_PORT_IPHTTPS_IN = 2,
	FWPM_SYSTEM_PORT_IPHTTPS_OUT = 3,
	FWPM_SYSTEM_PORT_TYPE_MAX = 4,
}


[AllowDuplicates]
public enum FWPM_CONNECTION_EVENT_TYPE : int32
{
	FWPM_CONNECTION_EVENT_ADD = 0,
	FWPM_CONNECTION_EVENT_DELETE = 1,
	FWPM_CONNECTION_EVENT_MAX = 2,
}


[AllowDuplicates]
public enum FWPM_VSWITCH_EVENT_TYPE : int32
{
	FWPM_VSWITCH_EVENT_FILTER_ADD_TO_INCOMPLETE_LAYER = 0,
	FWPM_VSWITCH_EVENT_FILTER_ENGINE_NOT_IN_REQUIRED_POSITION = 1,
	FWPM_VSWITCH_EVENT_ENABLED_FOR_INSPECTION = 2,
	FWPM_VSWITCH_EVENT_DISABLED_FOR_INSPECTION = 3,
	FWPM_VSWITCH_EVENT_FILTER_ENGINE_REORDER = 4,
	FWPM_VSWITCH_EVENT_MAX = 5,
}

#endregion

#region Function Pointers
public function void FWPM_PROVIDER_CHANGE_CALLBACK0(void* context, FWPM_PROVIDER_CHANGE0* change);

public function void FWPM_PROVIDER_CONTEXT_CHANGE_CALLBACK0(void* context, FWPM_PROVIDER_CONTEXT_CHANGE0* change);

public function void FWPM_SUBLAYER_CHANGE_CALLBACK0(void* context, FWPM_SUBLAYER_CHANGE0* change);

public function void FWPM_CALLOUT_CHANGE_CALLBACK0(void* context, FWPM_CALLOUT_CHANGE0* change);

public function void FWPM_FILTER_CHANGE_CALLBACK0(void* context, FWPM_FILTER_CHANGE0* change);

public function void IPSEC_SA_CONTEXT_CALLBACK0(void* context, IPSEC_SA_CONTEXT_CHANGE0* change);

public function void IPSEC_KEY_MANAGER_KEY_DICTATION_CHECK0(IKEEXT_TRAFFIC0* ikeTraffic, BOOL* willDictateKey, uint32* weight);

public function uint32 IPSEC_KEY_MANAGER_DICTATE_KEY0(IPSEC_SA_DETAILS1* inboundSaDetails, IPSEC_SA_DETAILS1* outboundSaDetails, BOOL* keyingModuleGenKey);

public function void IPSEC_KEY_MANAGER_NOTIFY_KEY0(IPSEC_SA_DETAILS1* inboundSa, IPSEC_SA_DETAILS1* outboundSa);

public function void FWPM_NET_EVENT_CALLBACK0(void* context, FWPM_NET_EVENT1* event);

public function void FWPM_NET_EVENT_CALLBACK1(void* context, FWPM_NET_EVENT2* event);

public function void FWPM_NET_EVENT_CALLBACK2(void* context, FWPM_NET_EVENT3* event);

public function void FWPM_NET_EVENT_CALLBACK3(void* context, FWPM_NET_EVENT4* event);

public function void FWPM_NET_EVENT_CALLBACK4(void* context, FWPM_NET_EVENT5* event);

public function void FWPM_DYNAMIC_KEYWORD_CALLBACK0(void* notification, void* context);

public function void FWPM_SYSTEM_PORTS_CALLBACK0(void* context, FWPM_SYSTEM_PORTS0* sysPorts);

public function void FWPM_CONNECTION_CALLBACK0(void* context, FWPM_CONNECTION_EVENT_TYPE eventType, FWPM_CONNECTION0* connection);

public function uint32 FWPM_VSWITCH_EVENT_CALLBACK0(void* context, FWPM_VSWITCH_EVENT0* vSwitchEvent);

#endregion

#region Structs
[CRepr]
public struct FWP_BYTE_ARRAY6
{
	public uint8[6] byteArray6;
}

[CRepr]
public struct FWP_BYTE_ARRAY16
{
	public uint8[16] byteArray16;
}

[CRepr]
public struct FWP_BYTE_BLOB
{
	public uint32 size;
	public uint8* data;
}

[CRepr]
public struct FWP_TOKEN_INFORMATION
{
	public uint32 sidCount;
	public SID_AND_ATTRIBUTES* sids;
	public uint32 restrictedSidCount;
	public SID_AND_ATTRIBUTES* restrictedSids;
}

[CRepr]
public struct FWP_VALUE0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint8 uint8;
		public uint16 uint16;
		public uint32 uint32;
		public uint64* uint64;
		public int8 int8;
		public int16 int16;
		public int32 int32;
		public int64* int64;
		public float float32;
		public double* double64;
		public FWP_BYTE_ARRAY16* byteArray16;
		public FWP_BYTE_BLOB* byteBlob;
		public SID* sid;
		public FWP_BYTE_BLOB* sd;
		public FWP_TOKEN_INFORMATION* tokenInformation;
		public FWP_BYTE_BLOB* tokenAccessInformation;
		public PWSTR unicodeString;
		public FWP_BYTE_ARRAY6* byteArray6;
	}
	public FWP_DATA_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWP_V4_ADDR_AND_MASK
{
	public uint32 addr;
	public uint32 mask;
}

[CRepr]
public struct FWP_V6_ADDR_AND_MASK
{
	public uint8[16] addr;
	public uint8 prefixLength;
}

[CRepr]
public struct FWP_RANGE0
{
	public FWP_VALUE0 valueLow;
	public FWP_VALUE0 valueHigh;
}

[CRepr]
public struct FWP_CONDITION_VALUE0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint8 uint8;
		public uint16 uint16;
		public uint32 uint32;
		public uint64* uint64;
		public int8 int8;
		public int16 int16;
		public int32 int32;
		public int64* int64;
		public float float32;
		public double* double64;
		public FWP_BYTE_ARRAY16* byteArray16;
		public FWP_BYTE_BLOB* byteBlob;
		public SID* sid;
		public FWP_BYTE_BLOB* sd;
		public FWP_TOKEN_INFORMATION* tokenInformation;
		public FWP_BYTE_BLOB* tokenAccessInformation;
		public PWSTR unicodeString;
		public FWP_BYTE_ARRAY6* byteArray6;
		public FWP_V4_ADDR_AND_MASK* v4AddrMask;
		public FWP_V6_ADDR_AND_MASK* v6AddrMask;
		public FWP_RANGE0* rangeValue;
	}
	public FWP_DATA_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_DISPLAY_DATA0
{
	public PWSTR name;
	public PWSTR description;
}

[CRepr]
public struct IPSEC_VIRTUAL_IF_TUNNEL_INFO0
{
	public uint64 virtualIfTunnelId;
	public uint64 trafficSelectorId;
}

[CRepr]
public struct IKEEXT_PRESHARED_KEY_AUTHENTICATION0
{
	public FWP_BYTE_BLOB presharedKey;
}

[CRepr]
public struct IKEEXT_PRESHARED_KEY_AUTHENTICATION1
{
	public FWP_BYTE_BLOB presharedKey;
	public IKEEXT_PRESHARED_KEY_AUTHENTICATION_FLAGS flags;
}

[CRepr]
public struct IKEEXT_CERT_ROOT_CONFIG0
{
	public FWP_BYTE_BLOB certData;
	public IKEEXT_CERT_FLAGS flags;
}

[CRepr]
public struct IKEEXT_CERTIFICATE_AUTHENTICATION0
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 outboundRootArraySize;
			public IKEEXT_CERT_ROOT_CONFIG0* outboundRootArray;
		}
		public using _Anonymous_e__Struct Anonymous;
		public IKEEXT_CERT_ROOT_CONFIG0* outboundEnterpriseStoreConfig;
		public IKEEXT_CERT_ROOT_CONFIG0* outboundTrustedRootStoreConfig;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 inboundRootArraySize;
			public IKEEXT_CERT_ROOT_CONFIG0* inboundRootArray;
		}
		public using _Anonymous_e__Struct Anonymous;
		public IKEEXT_CERT_ROOT_CONFIG0* inboundEnterpriseStoreConfig;
		public IKEEXT_CERT_ROOT_CONFIG0* inboundTrustedRootStoreConfig;
	}
	public IKEEXT_CERT_CONFIG_TYPE inboundConfigType;
	public using _Anonymous1_e__Union Anonymous1;
	public IKEEXT_CERT_CONFIG_TYPE outboundConfigType;
	public using _Anonymous2_e__Union Anonymous2;
	public IKEEXT_CERT_AUTH flags;
}

[CRepr]
public struct IKEEXT_CERTIFICATE_AUTHENTICATION1
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 outboundRootArraySize;
			public IKEEXT_CERT_ROOT_CONFIG0* outboundRootArray;
		}
		public using _Anonymous_e__Struct Anonymous;
		public IKEEXT_CERT_ROOT_CONFIG0* outboundEnterpriseStoreConfig;
		public IKEEXT_CERT_ROOT_CONFIG0* outboundTrustedRootStoreConfig;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 inboundRootArraySize;
			public IKEEXT_CERT_ROOT_CONFIG0* inboundRootArray;
		}
		public using _Anonymous_e__Struct Anonymous;
		public IKEEXT_CERT_ROOT_CONFIG0* inboundEnterpriseStoreConfig;
		public IKEEXT_CERT_ROOT_CONFIG0* inboundTrustedRootStoreConfig;
	}
	public IKEEXT_CERT_CONFIG_TYPE inboundConfigType;
	public using _Anonymous1_e__Union Anonymous1;
	public IKEEXT_CERT_CONFIG_TYPE outboundConfigType;
	public using _Anonymous2_e__Union Anonymous2;
	public IKEEXT_CERT_AUTH flags;
	public FWP_BYTE_BLOB localCertLocationUrl;
}

[CRepr]
public struct IKEEXT_CERT_EKUS0
{
	public uint32 numEku;
	public PSTR* eku;
}

[CRepr]
public struct IKEEXT_CERT_NAME0
{
	public IKEEXT_CERT_CRITERIA_NAME_TYPE nameType;
	public PWSTR certName;
}

[CRepr]
public struct IKEEXT_CERTIFICATE_CRITERIA0
{
	public FWP_BYTE_BLOB certData;
	public FWP_BYTE_BLOB certHash;
	public IKEEXT_CERT_EKUS0* eku;
	public IKEEXT_CERT_NAME0* name;
	public uint32 flags;
}

[CRepr]
public struct IKEEXT_CERTIFICATE_AUTHENTICATION2
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 outboundEnterpriseStoreArraySize;
			public IKEEXT_CERTIFICATE_CRITERIA0* outboundEnterpriseStoreCriteria;
		}
		[CRepr]
		public struct _Anonymous3_e__Struct
		{
			public uint32 outboundRootStoreArraySize;
			public IKEEXT_CERTIFICATE_CRITERIA0* outboundTrustedRootStoreCriteria;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 outboundRootArraySize;
			public IKEEXT_CERTIFICATE_CRITERIA0* outboundRootCriteria;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
		public using _Anonymous3_e__Struct Anonymous3;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous3_e__Struct
		{
			public uint32 inboundRootStoreArraySize;
			public IKEEXT_CERTIFICATE_CRITERIA0* inboundTrustedRootStoreCriteria;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 inboundRootArraySize;
			public IKEEXT_CERTIFICATE_CRITERIA0* inboundRootCriteria;
		}
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 inboundEnterpriseStoreArraySize;
			public IKEEXT_CERTIFICATE_CRITERIA0* inboundEnterpriseStoreCriteria;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
		public using _Anonymous3_e__Struct Anonymous3;
	}
	public IKEEXT_CERT_CONFIG_TYPE inboundConfigType;
	public using _Anonymous1_e__Union Anonymous1;
	public IKEEXT_CERT_CONFIG_TYPE outboundConfigType;
	public using _Anonymous2_e__Union Anonymous2;
	public IKEEXT_CERT_AUTH flags;
	public FWP_BYTE_BLOB localCertLocationUrl;
}

[CRepr]
public struct IKEEXT_IPV6_CGA_AUTHENTICATION0
{
	public PWSTR keyContainerName;
	public PWSTR cspName;
	public uint32 cspType;
	public FWP_BYTE_ARRAY16 cgaModifier;
	public uint8 cgaCollisionCount;
}

[CRepr]
public struct IKEEXT_KERBEROS_AUTHENTICATION0
{
	public IKEEXT_KERBEROS_AUTHENTICATION_FLAGS flags;
}

[CRepr]
public struct IKEEXT_KERBEROS_AUTHENTICATION1
{
	public IKEEXT_KERBEROS_AUTHENTICATION_FLAGS flags;
	public PWSTR proxyServer;
}

[CRepr]
public struct IKEEXT_RESERVED_AUTHENTICATION0
{
	public IKEEXT_RESERVED_AUTHENTICATION_FLAGS flags;
}

[CRepr]
public struct IKEEXT_NTLM_V2_AUTHENTICATION0
{
	public uint32 flags;
}

[CRepr]
public struct IKEEXT_EAP_AUTHENTICATION0
{
	public IKEEXT_EAP_AUTHENTICATION_FLAGS flags;
}

[CRepr]
public struct IKEEXT_AUTHENTICATION_METHOD0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKEEXT_PRESHARED_KEY_AUTHENTICATION0 presharedKeyAuthentication;
		public IKEEXT_CERTIFICATE_AUTHENTICATION0 certificateAuthentication;
		public IKEEXT_KERBEROS_AUTHENTICATION0 kerberosAuthentication;
		public IKEEXT_NTLM_V2_AUTHENTICATION0 ntlmV2Authentication;
		public IKEEXT_CERTIFICATE_AUTHENTICATION0 sslAuthentication;
		public IKEEXT_IPV6_CGA_AUTHENTICATION0 cgaAuthentication;
	}
	public IKEEXT_AUTHENTICATION_METHOD_TYPE authenticationMethodType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IKEEXT_AUTHENTICATION_METHOD1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKEEXT_PRESHARED_KEY_AUTHENTICATION1 presharedKeyAuthentication;
		public IKEEXT_CERTIFICATE_AUTHENTICATION1 certificateAuthentication;
		public IKEEXT_KERBEROS_AUTHENTICATION0 kerberosAuthentication;
		public IKEEXT_NTLM_V2_AUTHENTICATION0 ntlmV2Authentication;
		public IKEEXT_CERTIFICATE_AUTHENTICATION1 sslAuthentication;
		public IKEEXT_IPV6_CGA_AUTHENTICATION0 cgaAuthentication;
		public IKEEXT_EAP_AUTHENTICATION0 eapAuthentication;
	}
	public IKEEXT_AUTHENTICATION_METHOD_TYPE authenticationMethodType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IKEEXT_AUTHENTICATION_METHOD2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKEEXT_PRESHARED_KEY_AUTHENTICATION1 presharedKeyAuthentication;
		public IKEEXT_CERTIFICATE_AUTHENTICATION2 certificateAuthentication;
		public IKEEXT_KERBEROS_AUTHENTICATION1 kerberosAuthentication;
		public IKEEXT_RESERVED_AUTHENTICATION0 reservedAuthentication;
		public IKEEXT_NTLM_V2_AUTHENTICATION0 ntlmV2Authentication;
		public IKEEXT_CERTIFICATE_AUTHENTICATION2 sslAuthentication;
		public IKEEXT_IPV6_CGA_AUTHENTICATION0 cgaAuthentication;
		public IKEEXT_EAP_AUTHENTICATION0 eapAuthentication;
	}
	public IKEEXT_AUTHENTICATION_METHOD_TYPE authenticationMethodType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IKEEXT_CIPHER_ALGORITHM0
{
	public IKEEXT_CIPHER_TYPE algoIdentifier;
	public uint32 keyLen;
	public uint32 rounds;
}

[CRepr]
public struct IKEEXT_INTEGRITY_ALGORITHM0
{
	public IKEEXT_INTEGRITY_TYPE algoIdentifier;
}

[CRepr]
public struct IKEEXT_PROPOSAL0
{
	public IKEEXT_CIPHER_ALGORITHM0 cipherAlgorithm;
	public IKEEXT_INTEGRITY_ALGORITHM0 integrityAlgorithm;
	public uint32 maxLifetimeSeconds;
	public IKEEXT_DH_GROUP dhGroup;
	public uint32 quickModeLimit;
}

[CRepr]
public struct IKEEXT_POLICY0
{
	public uint32 softExpirationTime;
	public uint32 numAuthenticationMethods;
	public IKEEXT_AUTHENTICATION_METHOD0* authenticationMethods;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE initiatorImpersonationType;
	public uint32 numIkeProposals;
	public IKEEXT_PROPOSAL0* ikeProposals;
	public IKEEXT_POLICY_FLAG flags;
	public uint32 maxDynamicFilters;
}

[CRepr]
public struct IKEEXT_POLICY1
{
	public uint32 softExpirationTime;
	public uint32 numAuthenticationMethods;
	public IKEEXT_AUTHENTICATION_METHOD1* authenticationMethods;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE initiatorImpersonationType;
	public uint32 numIkeProposals;
	public IKEEXT_PROPOSAL0* ikeProposals;
	public IKEEXT_POLICY_FLAG flags;
	public uint32 maxDynamicFilters;
	public uint32 retransmitDurationSecs;
}

[CRepr]
public struct IKEEXT_POLICY2
{
	public uint32 softExpirationTime;
	public uint32 numAuthenticationMethods;
	public IKEEXT_AUTHENTICATION_METHOD2* authenticationMethods;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE initiatorImpersonationType;
	public uint32 numIkeProposals;
	public IKEEXT_PROPOSAL0* ikeProposals;
	public IKEEXT_POLICY_FLAG flags;
	public uint32 maxDynamicFilters;
	public uint32 retransmitDurationSecs;
}

[CRepr]
public struct IKEEXT_EM_POLICY0
{
	public uint32 numAuthenticationMethods;
	public IKEEXT_AUTHENTICATION_METHOD0* authenticationMethods;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE initiatorImpersonationType;
}

[CRepr]
public struct IKEEXT_EM_POLICY1
{
	public uint32 numAuthenticationMethods;
	public IKEEXT_AUTHENTICATION_METHOD1* authenticationMethods;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE initiatorImpersonationType;
}

[CRepr]
public struct IKEEXT_EM_POLICY2
{
	public uint32 numAuthenticationMethods;
	public IKEEXT_AUTHENTICATION_METHOD2* authenticationMethods;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE initiatorImpersonationType;
}

[CRepr]
public struct IKEEXT_IP_VERSION_SPECIFIC_KEYMODULE_STATISTICS0
{
	public uint32 currentActiveMainModes;
	public uint32 totalMainModesStarted;
	public uint32 totalSuccessfulMainModes;
	public uint32 totalFailedMainModes;
	public uint32 totalResponderMainModes;
	public uint32 currentNewResponderMainModes;
	public uint32 currentActiveQuickModes;
	public uint32 totalQuickModesStarted;
	public uint32 totalSuccessfulQuickModes;
	public uint32 totalFailedQuickModes;
	public uint32 totalAcquires;
	public uint32 totalReinitAcquires;
	public uint32 currentActiveExtendedModes;
	public uint32 totalExtendedModesStarted;
	public uint32 totalSuccessfulExtendedModes;
	public uint32 totalFailedExtendedModes;
	public uint32 totalImpersonationExtendedModes;
	public uint32 totalImpersonationMainModes;
}

[CRepr]
public struct IKEEXT_IP_VERSION_SPECIFIC_KEYMODULE_STATISTICS1
{
	public uint32 currentActiveMainModes;
	public uint32 totalMainModesStarted;
	public uint32 totalSuccessfulMainModes;
	public uint32 totalFailedMainModes;
	public uint32 totalResponderMainModes;
	public uint32 currentNewResponderMainModes;
	public uint32 currentActiveQuickModes;
	public uint32 totalQuickModesStarted;
	public uint32 totalSuccessfulQuickModes;
	public uint32 totalFailedQuickModes;
	public uint32 totalAcquires;
	public uint32 totalReinitAcquires;
	public uint32 currentActiveExtendedModes;
	public uint32 totalExtendedModesStarted;
	public uint32 totalSuccessfulExtendedModes;
	public uint32 totalFailedExtendedModes;
	public uint32 totalImpersonationExtendedModes;
	public uint32 totalImpersonationMainModes;
}

[CRepr]
public struct IKEEXT_KEYMODULE_STATISTICS0
{
	public IKEEXT_IP_VERSION_SPECIFIC_KEYMODULE_STATISTICS0 v4Statistics;
	public IKEEXT_IP_VERSION_SPECIFIC_KEYMODULE_STATISTICS0 v6Statistics;
	public uint32[97] errorFrequencyTable;
	public uint32 mainModeNegotiationTime;
	public uint32 quickModeNegotiationTime;
	public uint32 extendedModeNegotiationTime;
}

[CRepr]
public struct IKEEXT_KEYMODULE_STATISTICS1
{
	public IKEEXT_IP_VERSION_SPECIFIC_KEYMODULE_STATISTICS1 v4Statistics;
	public IKEEXT_IP_VERSION_SPECIFIC_KEYMODULE_STATISTICS1 v6Statistics;
	public uint32[97] errorFrequencyTable;
	public uint32 mainModeNegotiationTime;
	public uint32 quickModeNegotiationTime;
	public uint32 extendedModeNegotiationTime;
}

[CRepr]
public struct IKEEXT_IP_VERSION_SPECIFIC_COMMON_STATISTICS0
{
	public uint32 totalSocketReceiveFailures;
	public uint32 totalSocketSendFailures;
}

[CRepr]
public struct IKEEXT_IP_VERSION_SPECIFIC_COMMON_STATISTICS1
{
	public uint32 totalSocketReceiveFailures;
	public uint32 totalSocketSendFailures;
}

[CRepr]
public struct IKEEXT_COMMON_STATISTICS0
{
	public IKEEXT_IP_VERSION_SPECIFIC_COMMON_STATISTICS0 v4Statistics;
	public IKEEXT_IP_VERSION_SPECIFIC_COMMON_STATISTICS0 v6Statistics;
	public uint32 totalPacketsReceived;
	public uint32 totalInvalidPacketsReceived;
	public uint32 currentQueuedWorkitems;
}

[CRepr]
public struct IKEEXT_COMMON_STATISTICS1
{
	public IKEEXT_IP_VERSION_SPECIFIC_COMMON_STATISTICS1 v4Statistics;
	public IKEEXT_IP_VERSION_SPECIFIC_COMMON_STATISTICS1 v6Statistics;
	public uint32 totalPacketsReceived;
	public uint32 totalInvalidPacketsReceived;
	public uint32 currentQueuedWorkitems;
}

[CRepr]
public struct IKEEXT_STATISTICS0
{
	public IKEEXT_KEYMODULE_STATISTICS0 ikeStatistics;
	public IKEEXT_KEYMODULE_STATISTICS0 authipStatistics;
	public IKEEXT_COMMON_STATISTICS0 commonStatistics;
}

[CRepr]
public struct IKEEXT_STATISTICS1
{
	public IKEEXT_KEYMODULE_STATISTICS1 ikeStatistics;
	public IKEEXT_KEYMODULE_STATISTICS1 authipStatistics;
	public IKEEXT_KEYMODULE_STATISTICS1 ikeV2Statistics;
	public IKEEXT_COMMON_STATISTICS1 commonStatistics;
}

[CRepr]
public struct IKEEXT_TRAFFIC0
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint64 authIpFilterId;
}

[CRepr]
public struct IKEEXT_COOKIE_PAIR0
{
	public uint64 initiator;
	public uint64 responder;
}

[CRepr]
public struct IKEEXT_CERTIFICATE_CREDENTIAL0
{
	public FWP_BYTE_BLOB subjectName;
	public FWP_BYTE_BLOB certHash;
	public uint32 flags;
}

[CRepr]
public struct IKEEXT_NAME_CREDENTIAL0
{
	public PWSTR principalName;
}

[CRepr]
public struct IKEEXT_CREDENTIAL0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKEEXT_PRESHARED_KEY_AUTHENTICATION0* presharedKey;
		public IKEEXT_CERTIFICATE_CREDENTIAL0* certificate;
		public IKEEXT_NAME_CREDENTIAL0* name;
	}
	public IKEEXT_AUTHENTICATION_METHOD_TYPE authenticationMethodType;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE impersonationType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IKEEXT_CREDENTIAL_PAIR0
{
	public IKEEXT_CREDENTIAL0 localCredentials;
	public IKEEXT_CREDENTIAL0 peerCredentials;
}

[CRepr]
public struct IKEEXT_CREDENTIALS0
{
	public uint32 numCredentials;
	public IKEEXT_CREDENTIAL_PAIR0* credentials;
}

[CRepr]
public struct IKEEXT_SA_DETAILS0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* v4UdpEncapsulation;
	}
	public uint64 saId;
	public IKEEXT_KEY_MODULE_TYPE keyModuleType;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public IKEEXT_TRAFFIC0 ikeTraffic;
	public IKEEXT_PROPOSAL0 ikeProposal;
	public IKEEXT_COOKIE_PAIR0 cookiePair;
	public IKEEXT_CREDENTIALS0 ikeCredentials;
	public Guid ikePolicyKey;
	public uint64 virtualIfTunnelId;
}

[CRepr]
public struct IKEEXT_CERTIFICATE_CREDENTIAL1
{
	public FWP_BYTE_BLOB subjectName;
	public FWP_BYTE_BLOB certHash;
	public uint32 flags;
	public FWP_BYTE_BLOB certificate;
}

[CRepr]
public struct IKEEXT_CREDENTIAL1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKEEXT_PRESHARED_KEY_AUTHENTICATION1* presharedKey;
		public IKEEXT_CERTIFICATE_CREDENTIAL1* certificate;
		public IKEEXT_NAME_CREDENTIAL0* name;
	}
	public IKEEXT_AUTHENTICATION_METHOD_TYPE authenticationMethodType;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE impersonationType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IKEEXT_CREDENTIAL_PAIR1
{
	public IKEEXT_CREDENTIAL1 localCredentials;
	public IKEEXT_CREDENTIAL1 peerCredentials;
}

[CRepr]
public struct IKEEXT_CREDENTIALS1
{
	public uint32 numCredentials;
	public IKEEXT_CREDENTIAL_PAIR1* credentials;
}

[CRepr]
public struct IKEEXT_SA_DETAILS1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* v4UdpEncapsulation;
	}
	public uint64 saId;
	public IKEEXT_KEY_MODULE_TYPE keyModuleType;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public IKEEXT_TRAFFIC0 ikeTraffic;
	public IKEEXT_PROPOSAL0 ikeProposal;
	public IKEEXT_COOKIE_PAIR0 cookiePair;
	public IKEEXT_CREDENTIALS1 ikeCredentials;
	public Guid ikePolicyKey;
	public uint64 virtualIfTunnelId;
	public FWP_BYTE_BLOB correlationKey;
}

[CRepr]
public struct IKEEXT_CREDENTIAL2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IKEEXT_PRESHARED_KEY_AUTHENTICATION1* presharedKey;
		public IKEEXT_CERTIFICATE_CREDENTIAL1* certificate;
		public IKEEXT_NAME_CREDENTIAL0* name;
	}
	public IKEEXT_AUTHENTICATION_METHOD_TYPE authenticationMethodType;
	public IKEEXT_AUTHENTICATION_IMPERSONATION_TYPE impersonationType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IKEEXT_CREDENTIAL_PAIR2
{
	public IKEEXT_CREDENTIAL2 localCredentials;
	public IKEEXT_CREDENTIAL2 peerCredentials;
}

[CRepr]
public struct IKEEXT_CREDENTIALS2
{
	public uint32 numCredentials;
	public IKEEXT_CREDENTIAL_PAIR2* credentials;
}

[CRepr]
public struct IKEEXT_SA_DETAILS2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* v4UdpEncapsulation;
	}
	public uint64 saId;
	public IKEEXT_KEY_MODULE_TYPE keyModuleType;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public IKEEXT_TRAFFIC0 ikeTraffic;
	public IKEEXT_PROPOSAL0 ikeProposal;
	public IKEEXT_COOKIE_PAIR0 cookiePair;
	public IKEEXT_CREDENTIALS2 ikeCredentials;
	public Guid ikePolicyKey;
	public uint64 virtualIfTunnelId;
	public FWP_BYTE_BLOB correlationKey;
}

[CRepr]
public struct IKEEXT_SA_ENUM_TEMPLATE0
{
	public FWP_CONDITION_VALUE0 localSubNet;
	public FWP_CONDITION_VALUE0 remoteSubNet;
	public FWP_BYTE_BLOB localMainModeCertHash;
}

[CRepr]
public struct IPSEC_SA_LIFETIME0
{
	public uint32 lifetimeSeconds;
	public uint32 lifetimeKilobytes;
	public uint32 lifetimePackets;
}

[CRepr]
public struct IPSEC_AUTH_TRANSFORM_ID0
{
	public IPSEC_AUTH_TYPE authType;
	public uint8 authConfig;
}

[CRepr]
public struct IPSEC_AUTH_TRANSFORM0
{
	public IPSEC_AUTH_TRANSFORM_ID0 authTransformId;
	public Guid* cryptoModuleId;
}

[CRepr]
public struct IPSEC_CIPHER_TRANSFORM_ID0
{
	public IPSEC_CIPHER_TYPE cipherType;
	public uint8 cipherConfig;
}

[CRepr]
public struct IPSEC_CIPHER_TRANSFORM0
{
	public IPSEC_CIPHER_TRANSFORM_ID0 cipherTransformId;
	public Guid* cryptoModuleId;
}

[CRepr]
public struct IPSEC_AUTH_AND_CIPHER_TRANSFORM0
{
	public IPSEC_AUTH_TRANSFORM0 authTransform;
	public IPSEC_CIPHER_TRANSFORM0 cipherTransform;
}

[CRepr]
public struct IPSEC_SA_TRANSFORM0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_AUTH_TRANSFORM0* ahTransform;
		public IPSEC_AUTH_TRANSFORM0* espAuthTransform;
		public IPSEC_CIPHER_TRANSFORM0* espCipherTransform;
		public IPSEC_AUTH_AND_CIPHER_TRANSFORM0* espAuthAndCipherTransform;
		public IPSEC_AUTH_TRANSFORM0* espAuthFwTransform;
	}
	public IPSEC_TRANSFORM_TYPE ipsecTransformType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IPSEC_PROPOSAL0
{
	public IPSEC_SA_LIFETIME0 lifetime;
	public uint32 numSaTransforms;
	public IPSEC_SA_TRANSFORM0* saTransforms;
	public IPSEC_PFS_GROUP pfsGroup;
}

[CRepr]
public struct IPSEC_SA_IDLE_TIMEOUT0
{
	public uint32 idleTimeoutSeconds;
	public uint32 idleTimeoutSecondsFailOver;
}

[CRepr]
public struct IPSEC_TRAFFIC_SELECTOR0
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 startV4Address;
		public uint8[16] startV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 endV4Address;
		public uint8[16] endV6Address;
	}
	public uint8 protocolId;
	public uint16 portStart;
	public uint16 portEnd;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct IPSEC_TRAFFIC_SELECTOR_POLICY0
{
	public uint32 flags;
	public uint32 numLocalTrafficSelectors;
	public IPSEC_TRAFFIC_SELECTOR0* localTrafficSelectors;
	public uint32 numRemoteTrafficSelectors;
	public IPSEC_TRAFFIC_SELECTOR0* remoteTrafficSelectors;
}

[CRepr]
public struct IPSEC_TRANSPORT_POLICY0
{
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_POLICY_FLAG flags;
	public uint32 ndAllowClearTimeoutSeconds;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY0* emPolicy;
}

[CRepr]
public struct IPSEC_TRANSPORT_POLICY1
{
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_POLICY_FLAG flags;
	public uint32 ndAllowClearTimeoutSeconds;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY1* emPolicy;
}

[CRepr]
public struct IPSEC_TRANSPORT_POLICY2
{
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_POLICY_FLAG flags;
	public uint32 ndAllowClearTimeoutSeconds;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY2* emPolicy;
}

[CRepr]
public struct IPSEC_TUNNEL_ENDPOINTS0
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct IPSEC_TUNNEL_ENDPOINT0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 v4Address;
		public uint8[16] v6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IPSEC_TUNNEL_ENDPOINTS2
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint64 localIfLuid;
	public PWSTR remoteFqdn;
	public uint32 numAddresses;
	public IPSEC_TUNNEL_ENDPOINT0* remoteAddresses;
}

[CRepr]
public struct IPSEC_TUNNEL_ENDPOINTS1
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint64 localIfLuid;
}

[CRepr]
public struct IPSEC_TUNNEL_POLICY0
{
	public IPSEC_POLICY_FLAG flags;
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_TUNNEL_ENDPOINTS0 tunnelEndpoints;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY0* emPolicy;
}

[CRepr]
public struct IPSEC_TUNNEL_POLICY1
{
	public IPSEC_POLICY_FLAG flags;
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_TUNNEL_ENDPOINTS1 tunnelEndpoints;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY1* emPolicy;
}

[CRepr]
public struct IPSEC_TUNNEL_POLICY2
{
	public IPSEC_POLICY_FLAG flags;
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_TUNNEL_ENDPOINTS2 tunnelEndpoints;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY2* emPolicy;
	public uint32 fwdPathSaLifetime;
}

[CRepr]
public struct IPSEC_TUNNEL_POLICY3
{
	public uint32 flags;
	public uint32 numIpsecProposals;
	public IPSEC_PROPOSAL0* ipsecProposals;
	public IPSEC_TUNNEL_ENDPOINTS2 tunnelEndpoints;
	public IPSEC_SA_IDLE_TIMEOUT0 saIdleTimeout;
	public IKEEXT_EM_POLICY2* emPolicy;
	public uint32 fwdPathSaLifetime;
	public uint32 compartmentId;
	public uint32 numTrafficSelectorPolicy;
	public IPSEC_TRAFFIC_SELECTOR_POLICY0* trafficSelectorPolicies;
}

[CRepr]
public struct IPSEC_KEYING_POLICY0
{
	public uint32 numKeyMods;
	public Guid* keyModKeys;
}

[CRepr]
public struct IPSEC_KEYING_POLICY1
{
	public uint32 numKeyMods;
	public Guid* keyModKeys;
	public uint32 flags;
}

[CRepr]
public struct IPSEC_AGGREGATE_SA_STATISTICS0
{
	public uint32 activeSas;
	public uint32 pendingSaNegotiations;
	public uint32 totalSasAdded;
	public uint32 totalSasDeleted;
	public uint32 successfulRekeys;
	public uint32 activeTunnels;
	public uint32 offloadedSas;
}

[CRepr]
public struct IPSEC_ESP_DROP_PACKET_STATISTICS0
{
	public uint32 invalidSpisOnInbound;
	public uint32 decryptionFailuresOnInbound;
	public uint32 authenticationFailuresOnInbound;
	public uint32 replayCheckFailuresOnInbound;
	public uint32 saNotInitializedOnInbound;
}

[CRepr]
public struct IPSEC_AH_DROP_PACKET_STATISTICS0
{
	public uint32 invalidSpisOnInbound;
	public uint32 authenticationFailuresOnInbound;
	public uint32 replayCheckFailuresOnInbound;
	public uint32 saNotInitializedOnInbound;
}

[CRepr]
public struct IPSEC_AGGREGATE_DROP_PACKET_STATISTICS0
{
	public uint32 invalidSpisOnInbound;
	public uint32 decryptionFailuresOnInbound;
	public uint32 authenticationFailuresOnInbound;
	public uint32 udpEspValidationFailuresOnInbound;
	public uint32 replayCheckFailuresOnInbound;
	public uint32 invalidClearTextInbound;
	public uint32 saNotInitializedOnInbound;
	public uint32 receiveOverIncorrectSaInbound;
	public uint32 secureReceivesNotMatchingFilters;
}

[CRepr]
public struct IPSEC_AGGREGATE_DROP_PACKET_STATISTICS1
{
	public uint32 invalidSpisOnInbound;
	public uint32 decryptionFailuresOnInbound;
	public uint32 authenticationFailuresOnInbound;
	public uint32 udpEspValidationFailuresOnInbound;
	public uint32 replayCheckFailuresOnInbound;
	public uint32 invalidClearTextInbound;
	public uint32 saNotInitializedOnInbound;
	public uint32 receiveOverIncorrectSaInbound;
	public uint32 secureReceivesNotMatchingFilters;
	public uint32 totalDropPacketsInbound;
}

[CRepr]
public struct IPSEC_TRAFFIC_STATISTICS0
{
	public uint64 encryptedByteCount;
	public uint64 authenticatedAHByteCount;
	public uint64 authenticatedESPByteCount;
	public uint64 transportByteCount;
	public uint64 tunnelByteCount;
	public uint64 offloadByteCount;
}

[CRepr]
public struct IPSEC_TRAFFIC_STATISTICS1
{
	public uint64 encryptedByteCount;
	public uint64 authenticatedAHByteCount;
	public uint64 authenticatedESPByteCount;
	public uint64 transportByteCount;
	public uint64 tunnelByteCount;
	public uint64 offloadByteCount;
	public uint64 totalSuccessfulPackets;
}

[CRepr]
public struct IPSEC_STATISTICS0
{
	public IPSEC_AGGREGATE_SA_STATISTICS0 aggregateSaStatistics;
	public IPSEC_ESP_DROP_PACKET_STATISTICS0 espDropPacketStatistics;
	public IPSEC_AH_DROP_PACKET_STATISTICS0 ahDropPacketStatistics;
	public IPSEC_AGGREGATE_DROP_PACKET_STATISTICS0 aggregateDropPacketStatistics;
	public IPSEC_TRAFFIC_STATISTICS0 inboundTrafficStatistics;
	public IPSEC_TRAFFIC_STATISTICS0 outboundTrafficStatistics;
}

[CRepr]
public struct IPSEC_STATISTICS1
{
	public IPSEC_AGGREGATE_SA_STATISTICS0 aggregateSaStatistics;
	public IPSEC_ESP_DROP_PACKET_STATISTICS0 espDropPacketStatistics;
	public IPSEC_AH_DROP_PACKET_STATISTICS0 ahDropPacketStatistics;
	public IPSEC_AGGREGATE_DROP_PACKET_STATISTICS1 aggregateDropPacketStatistics;
	public IPSEC_TRAFFIC_STATISTICS1 inboundTrafficStatistics;
	public IPSEC_TRAFFIC_STATISTICS1 outboundTrafficStatistics;
}

[CRepr]
public struct IPSEC_SA_AUTH_INFORMATION0
{
	public IPSEC_AUTH_TRANSFORM0 authTransform;
	public FWP_BYTE_BLOB authKey;
}

[CRepr]
public struct IPSEC_SA_CIPHER_INFORMATION0
{
	public IPSEC_CIPHER_TRANSFORM0 cipherTransform;
	public FWP_BYTE_BLOB cipherKey;
}

[CRepr]
public struct IPSEC_SA_AUTH_AND_CIPHER_INFORMATION0
{
	public IPSEC_SA_CIPHER_INFORMATION0 saCipherInformation;
	public IPSEC_SA_AUTH_INFORMATION0 saAuthInformation;
}

[CRepr]
public struct IPSEC_SA0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_SA_AUTH_INFORMATION0* ahInformation;
		public IPSEC_SA_AUTH_INFORMATION0* espAuthInformation;
		public IPSEC_SA_CIPHER_INFORMATION0* espCipherInformation;
		public IPSEC_SA_AUTH_AND_CIPHER_INFORMATION0* espAuthAndCipherInformation;
		public IPSEC_SA_AUTH_INFORMATION0* espAuthFwInformation;
	}
	public uint32 spi;
	public IPSEC_TRANSFORM_TYPE saTransformType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct IPSEC_KEYMODULE_STATE0
{
	public Guid keyModuleKey;
	public FWP_BYTE_BLOB stateBlob;
}

[CRepr]
public struct IPSEC_TOKEN0
{
	public IPSEC_TOKEN_TYPE type;
	public IPSEC_TOKEN_PRINCIPAL principal;
	public IPSEC_TOKEN_MODE mode;
	public uint64 token;
}

[CRepr]
public struct IPSEC_ID0
{
	public PWSTR mmTargetName;
	public PWSTR emTargetName;
	public uint32 numTokens;
	public IPSEC_TOKEN0* tokens;
	public uint64 explicitCredentials;
	public uint64 logonId;
}

[CRepr]
public struct IPSEC_SA_BUNDLE0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 peerV4PrivateAddress;
	}
	public IPSEC_SA_BUNDLE_FLAGS flags;
	public IPSEC_SA_LIFETIME0 lifetime;
	public uint32 idleTimeoutSeconds;
	public uint32 ndAllowClearTimeoutSeconds;
	public IPSEC_ID0* ipsecId;
	public uint32 napContext;
	public uint32 qmSaId;
	public uint32 numSAs;
	public IPSEC_SA0* saList;
	public IPSEC_KEYMODULE_STATE0* keyModuleState;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public uint64 mmSaId;
	public IPSEC_PFS_GROUP pfsGroup;
}

[CRepr]
public struct IPSEC_SA_BUNDLE1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 peerV4PrivateAddress;
	}
	public IPSEC_SA_BUNDLE_FLAGS flags;
	public IPSEC_SA_LIFETIME0 lifetime;
	public uint32 idleTimeoutSeconds;
	public uint32 ndAllowClearTimeoutSeconds;
	public IPSEC_ID0* ipsecId;
	public uint32 napContext;
	public uint32 qmSaId;
	public uint32 numSAs;
	public IPSEC_SA0* saList;
	public IPSEC_KEYMODULE_STATE0* keyModuleState;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public uint64 mmSaId;
	public IPSEC_PFS_GROUP pfsGroup;
	public Guid saLookupContext;
	public uint64 qmFilterId;
}

[CRepr]
public struct IPSEC_TRAFFIC0
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public uint64 ipsecFilterId;
		public uint64 tunnelPolicyId;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public IPSEC_TRAFFIC_TYPE trafficType;
	public using _Anonymous3_e__Union Anonymous3;
	public uint16 remotePort;
}

[CRepr]
public struct IPSEC_TRAFFIC1
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public uint64 ipsecFilterId;
		public uint64 tunnelPolicyId;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public IPSEC_TRAFFIC_TYPE trafficType;
	public using _Anonymous3_e__Union Anonymous3;
	public uint16 remotePort;
	public uint16 localPort;
	public uint8 ipProtocol;
	public uint64 localIfLuid;
	public uint32 realIfProfileId;
}

[CRepr]
public struct IPSEC_V4_UDP_ENCAPSULATION0
{
	public uint16 localUdpEncapPort;
	public uint16 remoteUdpEncapPort;
}

[CRepr]
public struct IPSEC_GETSPI0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* inboundUdpEncapsulation;
	}
	public IPSEC_TRAFFIC0 inboundIpsecTraffic;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public Guid* rngCryptoModuleID;
}

[CRepr]
public struct IPSEC_GETSPI1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* inboundUdpEncapsulation;
	}
	public IPSEC_TRAFFIC1 inboundIpsecTraffic;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous_e__Union Anonymous;
	public Guid* rngCryptoModuleID;
}

[CRepr]
public struct IPSEC_SA_DETAILS0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* udpEncapsulation;
	}
	public FWP_IP_VERSION ipVersion;
	public FWP_DIRECTION saDirection;
	public IPSEC_TRAFFIC0 traffic;
	public IPSEC_SA_BUNDLE0 saBundle;
	public using _Anonymous_e__Union Anonymous;
	public FWPM_FILTER0* transportFilter;
}

[CRepr]
public struct IPSEC_SA_DETAILS1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_V4_UDP_ENCAPSULATION0* udpEncapsulation;
	}
	public FWP_IP_VERSION ipVersion;
	public FWP_DIRECTION saDirection;
	public IPSEC_TRAFFIC1 traffic;
	public IPSEC_SA_BUNDLE1 saBundle;
	public using _Anonymous_e__Union Anonymous;
	public FWPM_FILTER0* transportFilter;
	public IPSEC_VIRTUAL_IF_TUNNEL_INFO0 virtualIfTunnelInfo;
}

[CRepr]
public struct IPSEC_SA_CONTEXT0
{
	public uint64 saContextId;
	public IPSEC_SA_DETAILS0* inboundSa;
	public IPSEC_SA_DETAILS0* outboundSa;
}

[CRepr]
public struct IPSEC_SA_CONTEXT1
{
	public uint64 saContextId;
	public IPSEC_SA_DETAILS1* inboundSa;
	public IPSEC_SA_DETAILS1* outboundSa;
}

[CRepr]
public struct IPSEC_SA_CONTEXT_ENUM_TEMPLATE0
{
	public FWP_CONDITION_VALUE0 localSubNet;
	public FWP_CONDITION_VALUE0 remoteSubNet;
}

[CRepr]
public struct IPSEC_SA_ENUM_TEMPLATE0
{
	public FWP_DIRECTION saDirection;
}

[CRepr]
public struct IPSEC_SA_CONTEXT_SUBSCRIPTION0
{
	public IPSEC_SA_CONTEXT_ENUM_TEMPLATE0* enumTemplate;
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct IPSEC_SA_CONTEXT_CHANGE0
{
	public IPSEC_SA_CONTEXT_EVENT_TYPE0 changeType;
	public uint64 saContextId;
}

[CRepr]
public struct IPSEC_ADDRESS_INFO0
{
	public uint32 numV4Addresses;
	public uint32* v4Addresses;
	public uint32 numV6Addresses;
	public FWP_BYTE_ARRAY16* v6Addresses;
}

[CRepr]
public struct IPSEC_DOSP_OPTIONS0
{
	public uint32 stateIdleTimeoutSeconds;
	public uint32 perIPRateLimitQueueIdleTimeoutSeconds;
	public uint8 ipV6IPsecUnauthDscp;
	public uint32 ipV6IPsecUnauthRateLimitBytesPerSec;
	public uint32 ipV6IPsecUnauthPerIPRateLimitBytesPerSec;
	public uint8 ipV6IPsecAuthDscp;
	public uint32 ipV6IPsecAuthRateLimitBytesPerSec;
	public uint8 icmpV6Dscp;
	public uint32 icmpV6RateLimitBytesPerSec;
	public uint8 ipV6FilterExemptDscp;
	public uint32 ipV6FilterExemptRateLimitBytesPerSec;
	public uint8 defBlockExemptDscp;
	public uint32 defBlockExemptRateLimitBytesPerSec;
	public uint32 maxStateEntries;
	public uint32 maxPerIPRateLimitQueues;
	public IPSEC_DOSP_FLAGS flags;
	public uint32 numPublicIFLuids;
	public uint64* publicIFLuids;
	public uint32 numInternalIFLuids;
	public uint64* internalIFLuids;
	public FWP_V6_ADDR_AND_MASK publicV6AddrMask;
	public FWP_V6_ADDR_AND_MASK internalV6AddrMask;
}

[CRepr]
public struct IPSEC_DOSP_STATISTICS0
{
	public uint64 totalStateEntriesCreated;
	public uint64 currentStateEntries;
	public uint64 totalInboundAllowedIPv6IPsecUnauthPkts;
	public uint64 totalInboundRatelimitDiscardedIPv6IPsecUnauthPkts;
	public uint64 totalInboundPerIPRatelimitDiscardedIPv6IPsecUnauthPkts;
	public uint64 totalInboundOtherDiscardedIPv6IPsecUnauthPkts;
	public uint64 totalInboundAllowedIPv6IPsecAuthPkts;
	public uint64 totalInboundRatelimitDiscardedIPv6IPsecAuthPkts;
	public uint64 totalInboundOtherDiscardedIPv6IPsecAuthPkts;
	public uint64 totalInboundAllowedICMPv6Pkts;
	public uint64 totalInboundRatelimitDiscardedICMPv6Pkts;
	public uint64 totalInboundAllowedIPv6FilterExemptPkts;
	public uint64 totalInboundRatelimitDiscardedIPv6FilterExemptPkts;
	public uint64 totalInboundDiscardedIPv6FilterBlockPkts;
	public uint64 totalInboundAllowedDefBlockExemptPkts;
	public uint64 totalInboundRatelimitDiscardedDefBlockExemptPkts;
	public uint64 totalInboundDiscardedDefBlockPkts;
	public uint64 currentInboundIPv6IPsecUnauthPerIPRateLimitQueues;
}

[CRepr]
public struct IPSEC_DOSP_STATE0
{
	public uint8[16] publicHostV6Addr;
	public uint8[16] internalHostV6Addr;
	public uint64 totalInboundIPv6IPsecAuthPackets;
	public uint64 totalOutboundIPv6IPsecAuthPackets;
	public uint32 durationSecs;
}

[CRepr]
public struct IPSEC_DOSP_STATE_ENUM_TEMPLATE0
{
	public FWP_V6_ADDR_AND_MASK publicV6AddrMask;
	public FWP_V6_ADDR_AND_MASK internalV6AddrMask;
}

[CRepr]
public struct IPSEC_KEY_MANAGER0
{
	public Guid keyManagerKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public uint8 keyDictationTimeoutHint;
}

[CRepr]
public struct FWPM_SESSION0
{
	public Guid sessionKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public uint32 txnWaitTimeoutInMSec;
	public uint32 processId;
	public SID* sid;
	public PWSTR username;
	public BOOL kernelMode;
}

[CRepr]
public struct FWPM_SESSION_ENUM_TEMPLATE0
{
	public uint64 reserved;
}

[CRepr]
public struct FWPM_PROVIDER0
{
	public Guid providerKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public FWP_BYTE_BLOB providerData;
	public PWSTR serviceName;
}

[CRepr]
public struct FWPM_PROVIDER_ENUM_TEMPLATE0
{
	public uint64 reserved;
}

[CRepr]
public struct FWPM_PROVIDER_CHANGE0
{
	public FWPM_CHANGE_TYPE changeType;
	public Guid providerKey;
}

[CRepr]
public struct FWPM_PROVIDER_SUBSCRIPTION0
{
	public FWPM_PROVIDER_ENUM_TEMPLATE0* enumTemplate;
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_CLASSIFY_OPTION0
{
	public FWP_CLASSIFY_OPTION_TYPE type;
	public FWP_VALUE0 value;
}

[CRepr]
public struct FWPM_CLASSIFY_OPTIONS0
{
	public uint32 numOptions;
	public FWPM_CLASSIFY_OPTION0* options;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_KEYING_POLICY0* keyingPolicy;
		public IPSEC_TRANSPORT_POLICY0* ikeQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY0* ikeQmTunnelPolicy;
		public IPSEC_TRANSPORT_POLICY0* authipQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY0* authipQmTunnelPolicy;
		public IKEEXT_POLICY0* ikeMmPolicy;
		public IKEEXT_POLICY0* authIpMmPolicy;
		public FWP_BYTE_BLOB* dataBuffer;
		public FWPM_CLASSIFY_OPTIONS0* classifyOptions;
	}
	public Guid providerContextKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public FWPM_PROVIDER_CONTEXT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
	public uint64 providerContextId;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_KEYING_POLICY0* keyingPolicy;
		public IPSEC_TRANSPORT_POLICY1* ikeQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY1* ikeQmTunnelPolicy;
		public IPSEC_TRANSPORT_POLICY1* authipQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY1* authipQmTunnelPolicy;
		public IKEEXT_POLICY1* ikeMmPolicy;
		public IKEEXT_POLICY1* authIpMmPolicy;
		public FWP_BYTE_BLOB* dataBuffer;
		public FWPM_CLASSIFY_OPTIONS0* classifyOptions;
		public IPSEC_TUNNEL_POLICY1* ikeV2QmTunnelPolicy;
		public IKEEXT_POLICY1* ikeV2MmPolicy;
		public IPSEC_DOSP_OPTIONS0* idpOptions;
	}
	public Guid providerContextKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public FWPM_PROVIDER_CONTEXT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
	public uint64 providerContextId;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_KEYING_POLICY1* keyingPolicy;
		public IPSEC_TRANSPORT_POLICY2* ikeQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY2* ikeQmTunnelPolicy;
		public IPSEC_TRANSPORT_POLICY2* authipQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY2* authipQmTunnelPolicy;
		public IKEEXT_POLICY2* ikeMmPolicy;
		public IKEEXT_POLICY2* authIpMmPolicy;
		public FWP_BYTE_BLOB* dataBuffer;
		public FWPM_CLASSIFY_OPTIONS0* classifyOptions;
		public IPSEC_TUNNEL_POLICY2* ikeV2QmTunnelPolicy;
		public IPSEC_TRANSPORT_POLICY2* ikeV2QmTransportPolicy;
		public IKEEXT_POLICY2* ikeV2MmPolicy;
		public IPSEC_DOSP_OPTIONS0* idpOptions;
	}
	public Guid providerContextKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public FWPM_PROVIDER_CONTEXT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
	public uint64 providerContextId;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT3
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IPSEC_KEYING_POLICY1* keyingPolicy;
		public IPSEC_TRANSPORT_POLICY2* ikeQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY3* ikeQmTunnelPolicy;
		public IPSEC_TRANSPORT_POLICY2* authipQmTransportPolicy;
		public IPSEC_TUNNEL_POLICY3* authipQmTunnelPolicy;
		public IKEEXT_POLICY2* ikeMmPolicy;
		public IKEEXT_POLICY2* authIpMmPolicy;
		public FWP_BYTE_BLOB* dataBuffer;
		public FWPM_CLASSIFY_OPTIONS0* classifyOptions;
		public IPSEC_TUNNEL_POLICY3* ikeV2QmTunnelPolicy;
		public IPSEC_TRANSPORT_POLICY2* ikeV2QmTransportPolicy;
		public IKEEXT_POLICY2* ikeV2MmPolicy;
		public IPSEC_DOSP_OPTIONS0* idpOptions;
	}
	public Guid providerContextKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public FWPM_PROVIDER_CONTEXT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
	public uint64 providerContextId;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT_ENUM_TEMPLATE0
{
	public Guid* providerKey;
	public FWPM_PROVIDER_CONTEXT_TYPE providerContextType;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT_CHANGE0
{
	public FWPM_CHANGE_TYPE changeType;
	public Guid providerContextKey;
	public uint64 providerContextId;
}

[CRepr]
public struct FWPM_PROVIDER_CONTEXT_SUBSCRIPTION0
{
	public FWPM_PROVIDER_CONTEXT_ENUM_TEMPLATE0* enumTemplate;
	public FWPM_SUBSCRIPTION_FLAGS flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_SUBLAYER0
{
	public Guid subLayerKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public uint16 weight;
}

[CRepr]
public struct FWPM_SUBLAYER_ENUM_TEMPLATE0
{
	public Guid* providerKey;
}

[CRepr]
public struct FWPM_SUBLAYER_CHANGE0
{
	public FWPM_CHANGE_TYPE changeType;
	public Guid subLayerKey;
}

[CRepr]
public struct FWPM_SUBLAYER_SUBSCRIPTION0
{
	public FWPM_SUBLAYER_ENUM_TEMPLATE0* enumTemplate;
	public FWPM_SUBSCRIPTION_FLAGS flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_FIELD0
{
	public Guid* fieldKey;
	public FWPM_FIELD_TYPE type;
	public FWP_DATA_TYPE dataType;
}

[CRepr]
public struct FWPM_LAYER0
{
	public Guid layerKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public uint32 numFields;
	public FWPM_FIELD0* field;
	public Guid defaultSubLayerKey;
	public uint16 layerId;
}

[CRepr]
public struct FWPM_LAYER_ENUM_TEMPLATE0
{
	public uint64 reserved;
}

[CRepr]
public struct FWPM_CALLOUT0
{
	public Guid calloutKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public uint32 flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public Guid applicableLayer;
	public uint32 calloutId;
}

[CRepr]
public struct FWPM_CALLOUT_ENUM_TEMPLATE0
{
	public Guid* providerKey;
	public Guid layerKey;
}

[CRepr]
public struct FWPM_CALLOUT_CHANGE0
{
	public FWPM_CHANGE_TYPE changeType;
	public Guid calloutKey;
	public uint32 calloutId;
}

[CRepr]
public struct FWPM_CALLOUT_SUBSCRIPTION0
{
	public FWPM_CALLOUT_ENUM_TEMPLATE0* enumTemplate;
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_ACTION0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public Guid filterType;
		public Guid calloutKey;
	}
	public uint32 type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_FILTER_CONDITION0
{
	public Guid fieldKey;
	public FWP_MATCH_TYPE matchType;
	public FWP_CONDITION_VALUE0 conditionValue;
}

[CRepr]
public struct FWPM_FILTER0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint64 rawContext;
		public Guid providerContextKey;
	}
	public Guid filterKey;
	public FWPM_DISPLAY_DATA0 displayData;
	public FWPM_FILTER_FLAGS flags;
	public Guid* providerKey;
	public FWP_BYTE_BLOB providerData;
	public Guid layerKey;
	public Guid subLayerKey;
	public FWP_VALUE0 weight;
	public uint32 numFilterConditions;
	public FWPM_FILTER_CONDITION0* filterCondition;
	public FWPM_ACTION0 action;
	public using _Anonymous_e__Union Anonymous;
	public Guid* reserved;
	public uint64 filterId;
	public FWP_VALUE0 effectiveWeight;
}

[CRepr]
public struct FWPM_FILTER_ENUM_TEMPLATE0
{
	public Guid* providerKey;
	public Guid layerKey;
	public FWP_FILTER_ENUM_TYPE enumType;
	public uint32 flags;
	public FWPM_PROVIDER_CONTEXT_ENUM_TEMPLATE0* providerContextTemplate;
	public uint32 numFilterConditions;
	public FWPM_FILTER_CONDITION0* filterCondition;
	public uint32 actionMask;
	public Guid* calloutKey;
}

[CRepr]
public struct FWPM_FILTER_CHANGE0
{
	public FWPM_CHANGE_TYPE changeType;
	public Guid filterKey;
	public uint64 filterId;
}

[CRepr]
public struct FWPM_FILTER_SUBSCRIPTION0
{
	public FWPM_FILTER_ENUM_TEMPLATE0* enumTemplate;
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_LAYER_STATISTICS0
{
	public Guid layerId;
	public uint32 classifyPermitCount;
	public uint32 classifyBlockCount;
	public uint32 classifyVetoCount;
	public uint32 numCacheEntries;
}

[CRepr]
public struct FWPM_STATISTICS0
{
	public uint32 numLayerStatistics;
	public FWPM_LAYER_STATISTICS0* layerStatistics;
	public uint32 inboundAllowedConnectionsV4;
	public uint32 inboundBlockedConnectionsV4;
	public uint32 outboundAllowedConnectionsV4;
	public uint32 outboundBlockedConnectionsV4;
	public uint32 inboundAllowedConnectionsV6;
	public uint32 inboundBlockedConnectionsV6;
	public uint32 outboundAllowedConnectionsV6;
	public uint32 outboundBlockedConnectionsV6;
	public uint32 inboundActiveConnectionsV4;
	public uint32 outboundActiveConnectionsV4;
	public uint32 inboundActiveConnectionsV6;
	public uint32 outboundActiveConnectionsV6;
	public uint64 reauthDirInbound;
	public uint64 reauthDirOutbound;
	public uint64 reauthFamilyV4;
	public uint64 reauthFamilyV6;
	public uint64 reauthProtoOther;
	public uint64 reauthProtoIPv4;
	public uint64 reauthProtoIPv6;
	public uint64 reauthProtoICMP;
	public uint64 reauthProtoICMP6;
	public uint64 reauthProtoUDP;
	public uint64 reauthProtoTCP;
	public uint64 reauthReasonPolicyChange;
	public uint64 reauthReasonNewArrivalInterface;
	public uint64 reauthReasonNewNextHopInterface;
	public uint64 reauthReasonProfileCrossing;
	public uint64 reauthReasonClassifyCompletion;
	public uint64 reauthReasonIPSecPropertiesChanged;
	public uint64 reauthReasonMidStreamInspection;
	public uint64 reauthReasonSocketPropertyChanged;
	public uint64 reauthReasonNewInboundMCastBCastPacket;
	public uint64 reauthReasonEDPPolicyChanged;
	public uint64 reauthReasonProxyHandleChanged;
}

[CRepr]
public struct FWPM_NET_EVENT_HEADER0
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localAddrV4;
		public FWP_BYTE_ARRAY16 localAddrV6;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteAddrV4;
		public FWP_BYTE_ARRAY16 remoteAddrV6;
	}
	public FILETIME timeStamp;
	public uint32 flags;
	public FWP_IP_VERSION ipVersion;
	public uint8 ipProtocol;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 localPort;
	public uint16 remotePort;
	public uint32 scopeId;
	public FWP_BYTE_BLOB appId;
	public SID* userId;
}

[CRepr]
public struct FWPM_NET_EVENT_HEADER1
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
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
					public FWP_BYTE_ARRAY6 reserved2;
					public FWP_BYTE_ARRAY6 reserved3;
					public uint32 reserved4;
					public uint32 reserved5;
					public uint16 reserved6;
					public uint32 reserved7;
					public uint32 reserved8;
					public uint16 reserved9;
					public uint64 reserved10;
				}
				public using _Anonymous_e__Struct Anonymous;
			}
			public FWP_AF reserved1;
			public using _Anonymous_e__Union Anonymous;
		}
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localAddrV4;
		public FWP_BYTE_ARRAY16 localAddrV6;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteAddrV4;
		public FWP_BYTE_ARRAY16 remoteAddrV6;
	}
	public FILETIME timeStamp;
	public uint32 flags;
	public FWP_IP_VERSION ipVersion;
	public uint8 ipProtocol;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 localPort;
	public uint16 remotePort;
	public uint32 scopeId;
	public FWP_BYTE_BLOB appId;
	public SID* userId;
	public using _Anonymous3_e__Union Anonymous3;
}

[CRepr]
public struct FWPM_NET_EVENT_HEADER2
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localAddrV4;
		public FWP_BYTE_ARRAY16 localAddrV6;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteAddrV4;
		public FWP_BYTE_ARRAY16 remoteAddrV6;
	}
	public FILETIME timeStamp;
	public uint32 flags;
	public FWP_IP_VERSION ipVersion;
	public uint8 ipProtocol;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 localPort;
	public uint16 remotePort;
	public uint32 scopeId;
	public FWP_BYTE_BLOB appId;
	public SID* userId;
	public FWP_AF addressFamily;
	public SID* packageSid;
}

[CRepr]
public struct FWPM_NET_EVENT_HEADER3
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localAddrV4;
		public FWP_BYTE_ARRAY16 localAddrV6;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteAddrV4;
		public FWP_BYTE_ARRAY16 remoteAddrV6;
	}
	public FILETIME timeStamp;
	public uint32 flags;
	public FWP_IP_VERSION ipVersion;
	public uint8 ipProtocol;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint16 localPort;
	public uint16 remotePort;
	public uint32 scopeId;
	public FWP_BYTE_BLOB appId;
	public SID* userId;
	public FWP_AF addressFamily;
	public SID* packageSid;
	public PWSTR enterpriseId;
	public uint64 policyFlags;
	public FWP_BYTE_BLOB effectiveName;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_MM_FAILURE0
{
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public uint32 flags;
	public IKEEXT_KEY_MODULE_TYPE keyingModuleType;
	public IKEEXT_MM_SA_STATE mmState;
	public IKEEXT_SA_ROLE saRole;
	public IKEEXT_AUTHENTICATION_METHOD_TYPE mmAuthMethod;
	public uint8[20] endCertHash;
	public uint64 mmId;
	public uint64 mmFilterId;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_MM_FAILURE1
{
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public uint32 flags;
	public IKEEXT_KEY_MODULE_TYPE keyingModuleType;
	public IKEEXT_MM_SA_STATE mmState;
	public IKEEXT_SA_ROLE saRole;
	public IKEEXT_AUTHENTICATION_METHOD_TYPE mmAuthMethod;
	public uint8[20] endCertHash;
	public uint64 mmId;
	public uint64 mmFilterId;
	public PWSTR localPrincipalNameForAuth;
	public PWSTR remotePrincipalNameForAuth;
	public uint32 numLocalPrincipalGroupSids;
	public PWSTR* localPrincipalGroupSids;
	public uint32 numRemotePrincipalGroupSids;
	public PWSTR* remotePrincipalGroupSids;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_MM_FAILURE2
{
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public uint32 flags;
	public IKEEXT_KEY_MODULE_TYPE keyingModuleType;
	public IKEEXT_MM_SA_STATE mmState;
	public IKEEXT_SA_ROLE saRole;
	public IKEEXT_AUTHENTICATION_METHOD_TYPE mmAuthMethod;
	public uint8[20] endCertHash;
	public uint64 mmId;
	public uint64 mmFilterId;
	public PWSTR localPrincipalNameForAuth;
	public PWSTR remotePrincipalNameForAuth;
	public uint32 numLocalPrincipalGroupSids;
	public PWSTR* localPrincipalGroupSids;
	public uint32 numRemotePrincipalGroupSids;
	public PWSTR* remotePrincipalGroupSids;
	public Guid* providerContextKey;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_QM_FAILURE0
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public FWP_CONDITION_VALUE0 localSubNet;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public FWP_CONDITION_VALUE0 remoteSubNet;
	}
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public IKEEXT_KEY_MODULE_TYPE keyingModuleType;
	public IKEEXT_QM_SA_STATE qmState;
	public IKEEXT_SA_ROLE saRole;
	public IPSEC_TRAFFIC_TYPE saTrafficType;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint64 qmFilterId;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_QM_FAILURE1
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public FWP_CONDITION_VALUE0 localSubNet;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public FWP_CONDITION_VALUE0 remoteSubNet;
	}
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public IKEEXT_KEY_MODULE_TYPE keyingModuleType;
	public IKEEXT_QM_SA_STATE qmState;
	public IKEEXT_SA_ROLE saRole;
	public IPSEC_TRAFFIC_TYPE saTrafficType;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint64 qmFilterId;
	public uint64 mmSaLuid;
	public Guid mmProviderContextKey;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_EM_FAILURE0
{
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public uint32 flags;
	public IKEEXT_EM_SA_STATE emState;
	public IKEEXT_SA_ROLE saRole;
	public IKEEXT_AUTHENTICATION_METHOD_TYPE emAuthMethod;
	public uint8[20] endCertHash;
	public uint64 mmId;
	public uint64 qmFilterId;
}

[CRepr]
public struct FWPM_NET_EVENT_IKEEXT_EM_FAILURE1
{
	public uint32 failureErrorCode;
	public IPSEC_FAILURE_POINT failurePoint;
	public uint32 flags;
	public IKEEXT_EM_SA_STATE emState;
	public IKEEXT_SA_ROLE saRole;
	public IKEEXT_AUTHENTICATION_METHOD_TYPE emAuthMethod;
	public uint8[20] endCertHash;
	public uint64 mmId;
	public uint64 qmFilterId;
	public PWSTR localPrincipalNameForAuth;
	public PWSTR remotePrincipalNameForAuth;
	public uint32 numLocalPrincipalGroupSids;
	public PWSTR* localPrincipalGroupSids;
	public uint32 numRemotePrincipalGroupSids;
	public PWSTR* remotePrincipalGroupSids;
	public IPSEC_TRAFFIC_TYPE saTrafficType;
}

[CRepr]
public struct FWPM_NET_EVENT_CLASSIFY_DROP0
{
	public uint64 filterId;
	public uint16 layerId;
}

[CRepr]
public struct FWPM_NET_EVENT_CLASSIFY_DROP1
{
	public uint64 filterId;
	public uint16 layerId;
	public uint32 reauthReason;
	public uint32 originalProfile;
	public uint32 currentProfile;
	public uint32 msFwpDirection;
	public BOOL isLoopback;
}

[CRepr]
public struct FWPM_NET_EVENT_CLASSIFY_DROP2
{
	public uint64 filterId;
	public uint16 layerId;
	public uint32 reauthReason;
	public uint32 originalProfile;
	public uint32 currentProfile;
	public uint32 msFwpDirection;
	public BOOL isLoopback;
	public FWP_BYTE_BLOB vSwitchId;
	public uint32 vSwitchSourcePort;
	public uint32 vSwitchDestinationPort;
}

[CRepr]
public struct FWPM_NET_EVENT_CLASSIFY_DROP_MAC0
{
	public FWP_BYTE_ARRAY6 localMacAddr;
	public FWP_BYTE_ARRAY6 remoteMacAddr;
	public uint32 mediaType;
	public uint32 ifType;
	public uint16 etherType;
	public uint32 ndisPortNumber;
	public uint32 reserved;
	public uint16 vlanTag;
	public uint64 ifLuid;
	public uint64 filterId;
	public uint16 layerId;
	public uint32 reauthReason;
	public uint32 originalProfile;
	public uint32 currentProfile;
	public uint32 msFwpDirection;
	public BOOL isLoopback;
	public FWP_BYTE_BLOB vSwitchId;
	public uint32 vSwitchSourcePort;
	public uint32 vSwitchDestinationPort;
}

[CRepr]
public struct FWPM_NET_EVENT_CLASSIFY_ALLOW0
{
	public uint64 filterId;
	public uint16 layerId;
	public uint32 reauthReason;
	public uint32 originalProfile;
	public uint32 currentProfile;
	public uint32 msFwpDirection;
	public BOOL isLoopback;
}

[CRepr]
public struct FWPM_NET_EVENT_IPSEC_KERNEL_DROP0
{
	public int32 failureStatus;
	public FWP_DIRECTION direction;
	public uint32 spi;
	public uint64 filterId;
	public uint16 layerId;
}

[CRepr]
public struct FWPM_NET_EVENT_IPSEC_DOSP_DROP0
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 publicHostV4Addr;
		public uint8[16] publicHostV6Addr;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 internalHostV4Addr;
		public uint8[16] internalHostV6Addr;
	}
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public int32 failureStatus;
	public FWP_DIRECTION direction;
}

[CRepr]
public struct FWPM_NET_EVENT_CAPABILITY_DROP0
{
	public FWPM_APPC_NETWORK_CAPABILITY_TYPE networkCapabilityId;
	public uint64 filterId;
	public BOOL isLoopback;
}

[CRepr]
public struct FWPM_NET_EVENT_CAPABILITY_ALLOW0
{
	public FWPM_APPC_NETWORK_CAPABILITY_TYPE networkCapabilityId;
	public uint64 filterId;
	public BOOL isLoopback;
}

[CRepr]
public struct FWPM_NET_EVENT_LPM_PACKET_ARRIVAL0
{
	public uint32 spi;
}

[CRepr]
public struct FWPM_NET_EVENT0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public FWPM_NET_EVENT_IKEEXT_MM_FAILURE0* ikeMmFailure;
		public FWPM_NET_EVENT_IKEEXT_QM_FAILURE0* ikeQmFailure;
		public FWPM_NET_EVENT_IKEEXT_EM_FAILURE0* ikeEmFailure;
		public FWPM_NET_EVENT_CLASSIFY_DROP0* classifyDrop;
		public FWPM_NET_EVENT_IPSEC_KERNEL_DROP0* ipsecDrop;
		public FWPM_NET_EVENT_IPSEC_DOSP_DROP0* idpDrop;
	}
	public FWPM_NET_EVENT_HEADER0 header;
	public FWPM_NET_EVENT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_NET_EVENT1
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public FWPM_NET_EVENT_IKEEXT_MM_FAILURE1* ikeMmFailure;
		public FWPM_NET_EVENT_IKEEXT_QM_FAILURE0* ikeQmFailure;
		public FWPM_NET_EVENT_IKEEXT_EM_FAILURE1* ikeEmFailure;
		public FWPM_NET_EVENT_CLASSIFY_DROP1* classifyDrop;
		public FWPM_NET_EVENT_IPSEC_KERNEL_DROP0* ipsecDrop;
		public FWPM_NET_EVENT_IPSEC_DOSP_DROP0* idpDrop;
	}
	public FWPM_NET_EVENT_HEADER1 header;
	public FWPM_NET_EVENT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_NET_EVENT2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public FWPM_NET_EVENT_IKEEXT_MM_FAILURE1* ikeMmFailure;
		public FWPM_NET_EVENT_IKEEXT_QM_FAILURE0* ikeQmFailure;
		public FWPM_NET_EVENT_IKEEXT_EM_FAILURE1* ikeEmFailure;
		public FWPM_NET_EVENT_CLASSIFY_DROP2* classifyDrop;
		public FWPM_NET_EVENT_IPSEC_KERNEL_DROP0* ipsecDrop;
		public FWPM_NET_EVENT_IPSEC_DOSP_DROP0* idpDrop;
		public FWPM_NET_EVENT_CLASSIFY_ALLOW0* classifyAllow;
		public FWPM_NET_EVENT_CAPABILITY_DROP0* capabilityDrop;
		public FWPM_NET_EVENT_CAPABILITY_ALLOW0* capabilityAllow;
		public FWPM_NET_EVENT_CLASSIFY_DROP_MAC0* classifyDropMac;
	}
	public FWPM_NET_EVENT_HEADER2 header;
	public FWPM_NET_EVENT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_NET_EVENT3
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public FWPM_NET_EVENT_IKEEXT_MM_FAILURE1* ikeMmFailure;
		public FWPM_NET_EVENT_IKEEXT_QM_FAILURE0* ikeQmFailure;
		public FWPM_NET_EVENT_IKEEXT_EM_FAILURE1* ikeEmFailure;
		public FWPM_NET_EVENT_CLASSIFY_DROP2* classifyDrop;
		public FWPM_NET_EVENT_IPSEC_KERNEL_DROP0* ipsecDrop;
		public FWPM_NET_EVENT_IPSEC_DOSP_DROP0* idpDrop;
		public FWPM_NET_EVENT_CLASSIFY_ALLOW0* classifyAllow;
		public FWPM_NET_EVENT_CAPABILITY_DROP0* capabilityDrop;
		public FWPM_NET_EVENT_CAPABILITY_ALLOW0* capabilityAllow;
		public FWPM_NET_EVENT_CLASSIFY_DROP_MAC0* classifyDropMac;
	}
	public FWPM_NET_EVENT_HEADER3 header;
	public FWPM_NET_EVENT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_NET_EVENT4
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public FWPM_NET_EVENT_IKEEXT_MM_FAILURE2* ikeMmFailure;
		public FWPM_NET_EVENT_IKEEXT_QM_FAILURE1* ikeQmFailure;
		public FWPM_NET_EVENT_IKEEXT_EM_FAILURE1* ikeEmFailure;
		public FWPM_NET_EVENT_CLASSIFY_DROP2* classifyDrop;
		public FWPM_NET_EVENT_IPSEC_KERNEL_DROP0* ipsecDrop;
		public FWPM_NET_EVENT_IPSEC_DOSP_DROP0* idpDrop;
		public FWPM_NET_EVENT_CLASSIFY_ALLOW0* classifyAllow;
		public FWPM_NET_EVENT_CAPABILITY_DROP0* capabilityDrop;
		public FWPM_NET_EVENT_CAPABILITY_ALLOW0* capabilityAllow;
		public FWPM_NET_EVENT_CLASSIFY_DROP_MAC0* classifyDropMac;
	}
	public FWPM_NET_EVENT_HEADER3 header;
	public FWPM_NET_EVENT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_NET_EVENT5
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public FWPM_NET_EVENT_IKEEXT_MM_FAILURE2* ikeMmFailure;
		public FWPM_NET_EVENT_IKEEXT_QM_FAILURE1* ikeQmFailure;
		public FWPM_NET_EVENT_IKEEXT_EM_FAILURE1* ikeEmFailure;
		public FWPM_NET_EVENT_CLASSIFY_DROP2* classifyDrop;
		public FWPM_NET_EVENT_IPSEC_KERNEL_DROP0* ipsecDrop;
		public FWPM_NET_EVENT_IPSEC_DOSP_DROP0* idpDrop;
		public FWPM_NET_EVENT_CLASSIFY_ALLOW0* classifyAllow;
		public FWPM_NET_EVENT_CAPABILITY_DROP0* capabilityDrop;
		public FWPM_NET_EVENT_CAPABILITY_ALLOW0* capabilityAllow;
		public FWPM_NET_EVENT_CLASSIFY_DROP_MAC0* classifyDropMac;
		public FWPM_NET_EVENT_LPM_PACKET_ARRIVAL0* lpmPacketArrival;
	}
	public FWPM_NET_EVENT_HEADER3 header;
	public FWPM_NET_EVENT_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_NET_EVENT_ENUM_TEMPLATE0
{
	public FILETIME startTime;
	public FILETIME endTime;
	public uint32 numFilterConditions;
	public FWPM_FILTER_CONDITION0* filterCondition;
}

[CRepr]
public struct FWPM_NET_EVENT_SUBSCRIPTION0
{
	public FWPM_NET_EVENT_ENUM_TEMPLATE0* enumTemplate;
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_SYSTEM_PORTS_BY_TYPE0
{
	public FWPM_SYSTEM_PORT_TYPE type;
	public uint32 numPorts;
	public uint16* ports;
}

[CRepr]
public struct FWPM_SYSTEM_PORTS0
{
	public uint32 numTypes;
	public FWPM_SYSTEM_PORTS_BY_TYPE0* types;
}

[CRepr]
public struct FWPM_CONNECTION0
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 localV4Address;
		public uint8[16] localV6Address;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 remoteV4Address;
		public uint8[16] remoteV6Address;
	}
	public uint64 connectionId;
	public FWP_IP_VERSION ipVersion;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public Guid* providerKey;
	public IPSEC_TRAFFIC_TYPE ipsecTrafficModeType;
	public IKEEXT_KEY_MODULE_TYPE keyModuleType;
	public IKEEXT_PROPOSAL0 mmCrypto;
	public IKEEXT_CREDENTIAL2 mmPeer;
	public IKEEXT_CREDENTIAL2 emPeer;
	public uint64 bytesTransferredIn;
	public uint64 bytesTransferredOut;
	public uint64 bytesTransferredTotal;
	public FILETIME startSysTime;
}

[CRepr]
public struct FWPM_CONNECTION_ENUM_TEMPLATE0
{
	public uint64 connectionId;
	public uint32 flags;
}

[CRepr]
public struct FWPM_CONNECTION_SUBSCRIPTION0
{
	public FWPM_CONNECTION_ENUM_TEMPLATE0* enumTemplate;
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct FWPM_VSWITCH_EVENT0
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _positionInfo_e__Struct
		{
			public uint32 numvSwitchFilterExtensions;
			public PWSTR* vSwitchFilterExtensions;
		}
		[CRepr]
		public struct _reorderInfo_e__Struct
		{
			public BOOL inRequiredPosition;
			public uint32 numvSwitchFilterExtensions;
			public PWSTR* vSwitchFilterExtensions;
		}
		public _positionInfo_e__Struct positionInfo;
		public _reorderInfo_e__Struct reorderInfo;
	}
	public FWPM_VSWITCH_EVENT_TYPE eventType;
	public PWSTR vSwitchId;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FWPM_VSWITCH_EVENT_SUBSCRIPTION0
{
	public uint32 flags;
	public Guid sessionKey;
}

[CRepr]
public struct IPSEC_KEY_MANAGER_CALLBACKS0
{
	public Guid reserved;
	public uint32 flags;
	public IPSEC_KEY_MANAGER_KEY_DICTATION_CHECK0 keyDictationCheck;
	public IPSEC_KEY_MANAGER_DICTATE_KEY0 keyDictation;
	public IPSEC_KEY_MANAGER_NOTIFY_KEY0 keyNotify;
}

#endregion

#region Functions
public static
{
	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FwpmFreeMemory0(void** p);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmEngineOpen0(PWSTR serverName, uint32 authnService, SEC_WINNT_AUTH_IDENTITY_W* authIdentity, FWPM_SESSION0* session, HANDLE* engineHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmEngineClose0(HANDLE engineHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmEngineGetOption0(HANDLE engineHandle, FWPM_ENGINE_OPTION option, FWP_VALUE0** value);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmEngineSetOption0(HANDLE engineHandle, FWPM_ENGINE_OPTION option, FWP_VALUE0* newValue);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmEngineGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmEngineSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSessionCreateEnumHandle0(HANDLE engineHandle, FWPM_SESSION_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSessionEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_SESSION0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSessionDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmTransactionBegin0(HANDLE engineHandle, uint32 flags);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmTransactionCommit0(HANDLE engineHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmTransactionAbort0(HANDLE engineHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderAdd0(HANDLE engineHandle, FWPM_PROVIDER0* provider, PSECURITY_DESCRIPTOR sd);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderDeleteByKey0(HANDLE engineHandle, in Guid key);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderGetByKey0(HANDLE engineHandle, in Guid key, FWPM_PROVIDER0** provider);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderCreateEnumHandle0(HANDLE engineHandle, FWPM_PROVIDER_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_PROVIDER0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderGetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderSetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderSubscribeChanges0(HANDLE engineHandle, FWPM_PROVIDER_SUBSCRIPTION0* subscription, FWPM_PROVIDER_CHANGE_CALLBACK0 callback, void* context, HANDLE* changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderUnsubscribeChanges0(HANDLE engineHandle, HANDLE changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderSubscriptionsGet0(HANDLE engineHandle, FWPM_PROVIDER_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextAdd0(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT0* providerContext, PSECURITY_DESCRIPTOR sd, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextAdd1(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT1* providerContext, PSECURITY_DESCRIPTOR sd, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextAdd2(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT2* providerContext, PSECURITY_DESCRIPTOR sd, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextAdd3(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT3* providerContext, PSECURITY_DESCRIPTOR sd, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextDeleteById0(HANDLE engineHandle, uint64 id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextDeleteByKey0(HANDLE engineHandle, in Guid key);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetById0(HANDLE engineHandle, uint64 id, FWPM_PROVIDER_CONTEXT0** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetById1(HANDLE engineHandle, uint64 id, FWPM_PROVIDER_CONTEXT1** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetById2(HANDLE engineHandle, uint64 id, FWPM_PROVIDER_CONTEXT2** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetById3(HANDLE engineHandle, uint64 id, FWPM_PROVIDER_CONTEXT3** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetByKey0(HANDLE engineHandle, in Guid key, FWPM_PROVIDER_CONTEXT0** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetByKey1(HANDLE engineHandle, in Guid key, FWPM_PROVIDER_CONTEXT1** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetByKey2(HANDLE engineHandle, in Guid key, FWPM_PROVIDER_CONTEXT2** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetByKey3(HANDLE engineHandle, in Guid key, FWPM_PROVIDER_CONTEXT3** providerContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextCreateEnumHandle0(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_PROVIDER_CONTEXT0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextEnum1(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_PROVIDER_CONTEXT1*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextEnum2(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_PROVIDER_CONTEXT2*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextEnum3(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_PROVIDER_CONTEXT3*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextGetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextSetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextSubscribeChanges0(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT_SUBSCRIPTION0* subscription, FWPM_PROVIDER_CONTEXT_CHANGE_CALLBACK0 callback, void* context, HANDLE* changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextUnsubscribeChanges0(HANDLE engineHandle, HANDLE changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmProviderContextSubscriptionsGet0(HANDLE engineHandle, FWPM_PROVIDER_CONTEXT_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerAdd0(HANDLE engineHandle, FWPM_SUBLAYER0* subLayer, PSECURITY_DESCRIPTOR sd);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerDeleteByKey0(HANDLE engineHandle, in Guid key);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerGetByKey0(HANDLE engineHandle, in Guid key, FWPM_SUBLAYER0** subLayer);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerCreateEnumHandle0(HANDLE engineHandle, FWPM_SUBLAYER_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_SUBLAYER0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerGetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerSetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerSubscribeChanges0(HANDLE engineHandle, FWPM_SUBLAYER_SUBSCRIPTION0* subscription, FWPM_SUBLAYER_CHANGE_CALLBACK0 callback, void* context, HANDLE* changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerUnsubscribeChanges0(HANDLE engineHandle, HANDLE changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSubLayerSubscriptionsGet0(HANDLE engineHandle, FWPM_SUBLAYER_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerGetById0(HANDLE engineHandle, uint16 id, FWPM_LAYER0** layer);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerGetByKey0(HANDLE engineHandle, in Guid key, FWPM_LAYER0** layer);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerCreateEnumHandle0(HANDLE engineHandle, FWPM_LAYER_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_LAYER0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerGetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmLayerSetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutAdd0(HANDLE engineHandle, FWPM_CALLOUT0* callout, PSECURITY_DESCRIPTOR sd, uint32* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutDeleteById0(HANDLE engineHandle, uint32 id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutDeleteByKey0(HANDLE engineHandle, in Guid key);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutGetById0(HANDLE engineHandle, uint32 id, FWPM_CALLOUT0** callout);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutGetByKey0(HANDLE engineHandle, in Guid key, FWPM_CALLOUT0** callout);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutCreateEnumHandle0(HANDLE engineHandle, FWPM_CALLOUT_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_CALLOUT0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutGetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutSetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutSubscribeChanges0(HANDLE engineHandle, FWPM_CALLOUT_SUBSCRIPTION0* subscription, FWPM_CALLOUT_CHANGE_CALLBACK0 callback, void* context, HANDLE* changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutUnsubscribeChanges0(HANDLE engineHandle, HANDLE changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmCalloutSubscriptionsGet0(HANDLE engineHandle, FWPM_CALLOUT_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterAdd0(HANDLE engineHandle, FWPM_FILTER0* filter, PSECURITY_DESCRIPTOR sd, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterDeleteById0(HANDLE engineHandle, uint64 id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterDeleteByKey0(HANDLE engineHandle, in Guid key);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterGetById0(HANDLE engineHandle, uint64 id, FWPM_FILTER0** filter);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterGetByKey0(HANDLE engineHandle, in Guid key, FWPM_FILTER0** filter);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterCreateEnumHandle0(HANDLE engineHandle, FWPM_FILTER_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_FILTER0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterGetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterSetSecurityInfoByKey0(HANDLE engineHandle, Guid* key, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterSubscribeChanges0(HANDLE engineHandle, FWPM_FILTER_SUBSCRIPTION0* subscription, FWPM_FILTER_CHANGE_CALLBACK0 callback, void* context, HANDLE* changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterUnsubscribeChanges0(HANDLE engineHandle, HANDLE changeHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmFilterSubscriptionsGet0(HANDLE engineHandle, FWPM_FILTER_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmGetAppIdFromFileName0(PWSTR fileName, FWP_BYTE_BLOB** appId);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmIPsecTunnelAdd0(HANDLE engineHandle, uint32 flags, FWPM_PROVIDER_CONTEXT0* mainModePolicy, FWPM_PROVIDER_CONTEXT0* tunnelPolicy, uint32 numFilterConditions, FWPM_FILTER_CONDITION0* filterConditions, PSECURITY_DESCRIPTOR sd);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmIPsecTunnelAdd1(HANDLE engineHandle, uint32 flags, FWPM_PROVIDER_CONTEXT1* mainModePolicy, FWPM_PROVIDER_CONTEXT1* tunnelPolicy, uint32 numFilterConditions, FWPM_FILTER_CONDITION0* filterConditions, Guid* keyModKey, PSECURITY_DESCRIPTOR sd);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmIPsecTunnelAdd2(HANDLE engineHandle, uint32 flags, FWPM_PROVIDER_CONTEXT2* mainModePolicy, FWPM_PROVIDER_CONTEXT2* tunnelPolicy, uint32 numFilterConditions, FWPM_FILTER_CONDITION0* filterConditions, Guid* keyModKey, PSECURITY_DESCRIPTOR sd);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmIPsecTunnelAdd3(HANDLE engineHandle, uint32 flags, FWPM_PROVIDER_CONTEXT3* mainModePolicy, FWPM_PROVIDER_CONTEXT3* tunnelPolicy, uint32 numFilterConditions, FWPM_FILTER_CONDITION0* filterConditions, Guid* keyModKey, PSECURITY_DESCRIPTOR sd);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmIPsecTunnelDeleteByKey0(HANDLE engineHandle, in Guid key);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecGetStatistics0(HANDLE engineHandle, IPSEC_STATISTICS0* ipsecStatistics);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecGetStatistics1(HANDLE engineHandle, IPSEC_STATISTICS1* ipsecStatistics);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextCreate0(HANDLE engineHandle, IPSEC_TRAFFIC0* outboundTraffic, uint64* inboundFilterId, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextCreate1(HANDLE engineHandle, IPSEC_TRAFFIC1* outboundTraffic, IPSEC_VIRTUAL_IF_TUNNEL_INFO0* virtualIfTunnelInfo, uint64* inboundFilterId, uint64* id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextDeleteById0(HANDLE engineHandle, uint64 id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextGetById0(HANDLE engineHandle, uint64 id, IPSEC_SA_CONTEXT0** saContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextGetById1(HANDLE engineHandle, uint64 id, IPSEC_SA_CONTEXT1** saContext);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextGetSpi0(HANDLE engineHandle, uint64 id, IPSEC_GETSPI0* getSpi, uint32* inboundSpi);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextGetSpi1(HANDLE engineHandle, uint64 id, IPSEC_GETSPI1* getSpi, uint32* inboundSpi);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextSetSpi0(HANDLE engineHandle, uint64 id, IPSEC_GETSPI1* getSpi, uint32 inboundSpi);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextAddInbound0(HANDLE engineHandle, uint64 id, IPSEC_SA_BUNDLE0* inboundBundle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextAddOutbound0(HANDLE engineHandle, uint64 id, IPSEC_SA_BUNDLE0* outboundBundle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextAddInbound1(HANDLE engineHandle, uint64 id, IPSEC_SA_BUNDLE1* inboundBundle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextAddOutbound1(HANDLE engineHandle, uint64 id, IPSEC_SA_BUNDLE1* outboundBundle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextExpire0(HANDLE engineHandle, uint64 id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextUpdate0(HANDLE engineHandle, uint64 flags, IPSEC_SA_CONTEXT1* newValues);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextCreateEnumHandle0(HANDLE engineHandle, IPSEC_SA_CONTEXT_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IPSEC_SA_CONTEXT0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextEnum1(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IPSEC_SA_CONTEXT1*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextSubscribe0(HANDLE engineHandle, IPSEC_SA_CONTEXT_SUBSCRIPTION0* subscription, IPSEC_SA_CONTEXT_CALLBACK0 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextUnsubscribe0(HANDLE engineHandle, HANDLE eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaContextSubscriptionsGet0(HANDLE engineHandle, IPSEC_SA_CONTEXT_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaCreateEnumHandle0(HANDLE engineHandle, IPSEC_SA_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IPSEC_SA_DETAILS0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaEnum1(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IPSEC_SA_DETAILS1*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaDbGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecSaDbSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecDospGetStatistics0(HANDLE engineHandle, IPSEC_DOSP_STATISTICS0* idpStatistics);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecDospStateCreateEnumHandle0(HANDLE engineHandle, IPSEC_DOSP_STATE_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecDospStateEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IPSEC_DOSP_STATE0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecDospStateDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecDospGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecDospSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecKeyManagerAddAndRegister0(HANDLE engineHandle, IPSEC_KEY_MANAGER0* keyManager, IPSEC_KEY_MANAGER_CALLBACKS0* keyManagerCallbacks, HANDLE* keyMgmtHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecKeyManagerUnregisterAndDelete0(HANDLE engineHandle, HANDLE keyMgmtHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecKeyManagersGet0(HANDLE engineHandle, IPSEC_KEY_MANAGER0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecKeyManagerGetSecurityInfoByKey0(HANDLE engineHandle, void* reserved, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IPsecKeyManagerSetSecurityInfoByKey0(HANDLE engineHandle, void* reserved, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextGetStatistics0(HANDLE engineHandle, IKEEXT_STATISTICS0* ikeextStatistics);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextGetStatistics1(HANDLE engineHandle, IKEEXT_STATISTICS1* ikeextStatistics);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaDeleteById0(HANDLE engineHandle, uint64 id);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaGetById0(HANDLE engineHandle, uint64 id, IKEEXT_SA_DETAILS0** sa);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaGetById1(HANDLE engineHandle, uint64 id, Guid* saLookupContext, IKEEXT_SA_DETAILS1** sa);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaGetById2(HANDLE engineHandle, uint64 id, Guid* saLookupContext, IKEEXT_SA_DETAILS2** sa);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaCreateEnumHandle0(HANDLE engineHandle, IKEEXT_SA_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IKEEXT_SA_DETAILS0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaEnum1(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IKEEXT_SA_DETAILS1*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaEnum2(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, IKEEXT_SA_DETAILS2*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaDbGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IkeextSaDbSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventCreateEnumHandle0(HANDLE engineHandle, FWPM_NET_EVENT_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_NET_EVENT0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventEnum1(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_NET_EVENT1*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventEnum2(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_NET_EVENT2*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventEnum3(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_NET_EVENT3*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventEnum4(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_NET_EVENT4*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventEnum5(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_NET_EVENT5*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventsGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventsSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventSubscribe0(HANDLE engineHandle, FWPM_NET_EVENT_SUBSCRIPTION0* subscription, FWPM_NET_EVENT_CALLBACK0 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventUnsubscribe0(HANDLE engineHandle, HANDLE eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventSubscriptionsGet0(HANDLE engineHandle, FWPM_NET_EVENT_SUBSCRIPTION0*** entries, uint32* numEntries);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventSubscribe1(HANDLE engineHandle, FWPM_NET_EVENT_SUBSCRIPTION0* subscription, FWPM_NET_EVENT_CALLBACK1 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventSubscribe2(HANDLE engineHandle, FWPM_NET_EVENT_SUBSCRIPTION0* subscription, FWPM_NET_EVENT_CALLBACK2 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventSubscribe3(HANDLE engineHandle, FWPM_NET_EVENT_SUBSCRIPTION0* subscription, FWPM_NET_EVENT_CALLBACK3 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmNetEventSubscribe4(HANDLE engineHandle, FWPM_NET_EVENT_SUBSCRIPTION0* subscription, FWPM_NET_EVENT_CALLBACK4 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmDynamicKeywordSubscribe0(uint32 flags, FWPM_DYNAMIC_KEYWORD_CALLBACK0 callback, void* context, HANDLE* subscriptionHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmDynamicKeywordUnsubscribe0(HANDLE subscriptionHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSystemPortsGet0(HANDLE engineHandle, FWPM_SYSTEM_PORTS0** sysPorts);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSystemPortsSubscribe0(HANDLE engineHandle, void* reserved, FWPM_SYSTEM_PORTS_CALLBACK0 callback, void* context, HANDLE* sysPortsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmSystemPortsUnsubscribe0(HANDLE engineHandle, HANDLE sysPortsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionGetById0(HANDLE engineHandle, uint64 id, FWPM_CONNECTION0** connection);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionEnum0(HANDLE engineHandle, HANDLE enumHandle, uint32 numEntriesRequested, FWPM_CONNECTION0*** entries, uint32* numEntriesReturned);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionCreateEnumHandle0(HANDLE engineHandle, FWPM_CONNECTION_ENUM_TEMPLATE0* enumTemplate, HANDLE* enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionDestroyEnumHandle0(HANDLE engineHandle, HANDLE enumHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionSubscribe0(HANDLE engineHandle, FWPM_CONNECTION_SUBSCRIPTION0* subscription, FWPM_CONNECTION_CALLBACK0 callback, void* context, HANDLE* eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmConnectionUnsubscribe0(HANDLE engineHandle, HANDLE eventsHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmvSwitchEventSubscribe0(HANDLE engineHandle, FWPM_VSWITCH_EVENT_SUBSCRIPTION0* subscription, FWPM_VSWITCH_EVENT_CALLBACK0 callback, void* context, HANDLE* subscriptionHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmvSwitchEventUnsubscribe0(HANDLE engineHandle, HANDLE subscriptionHandle);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmvSwitchEventsGetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, PSID* sidOwner, PSID* sidGroup, ACL** dacl, ACL** sacl, PSECURITY_DESCRIPTOR* securityDescriptor);

	[Import("fwpuclnt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FwpmvSwitchEventsSetSecurityInfo0(HANDLE engineHandle, uint32 securityInfo, SID* sidOwner, SID* sidGroup, ACL* dacl, ACL* sacl);

}
#endregion
