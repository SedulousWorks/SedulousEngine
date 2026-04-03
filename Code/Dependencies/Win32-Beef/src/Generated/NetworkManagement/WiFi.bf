using Win32.Devices.Properties;
using Win32.NetworkManagement.Ndis;
using Win32.Foundation;
using Win32.Security.ExtensibleAuthenticationProtocol;
using Win32.System.Com;
using Win32.System.RemoteDesktop;
using System;

namespace Win32.NetworkManagement.WiFi;

#region Constants
public static
{
	public const uint32 L2_REASON_CODE_DOT11_AC_BASE = 131072;
	public const uint32 L2_REASON_CODE_DOT11_MSM_BASE = 196608;
	public const uint32 L2_REASON_CODE_DOT11_SECURITY_BASE = 262144;
	public const uint32 L2_REASON_CODE_ONEX_BASE = 327680;
	public const uint32 L2_REASON_CODE_DOT3_AC_BASE = 393216;
	public const uint32 L2_REASON_CODE_DOT3_MSM_BASE = 458752;
	public const uint32 L2_REASON_CODE_PROFILE_BASE = 524288;
	public const uint32 L2_REASON_CODE_IHV_BASE = 589824;
	public const uint32 L2_REASON_CODE_WIMAX_BASE = 655360;
	public const uint32 L2_REASON_CODE_RESERVED_BASE = 720896;
	public const uint32 WLAN_REASON_CODE_SUCCESS = 0;
	public const uint32 WLAN_REASON_CODE_UNKNOWN = 65537;
	public const uint32 WLAN_REASON_CODE_RANGE_SIZE = 65536;
	public const uint32 WLAN_REASON_CODE_BASE = 131072;
	public const uint32 WLAN_REASON_CODE_AC_BASE = 131072;
	public const uint32 WLAN_REASON_CODE_AC_CONNECT_BASE = 163840;
	public const uint32 WLAN_REASON_CODE_AC_END = 196607;
	public const uint32 WLAN_REASON_CODE_PROFILE_BASE = 524288;
	public const uint32 WLAN_REASON_CODE_PROFILE_CONNECT_BASE = 557056;
	public const uint32 WLAN_REASON_CODE_PROFILE_END = 589823;
	public const uint32 WLAN_REASON_CODE_MSM_BASE = 196608;
	public const uint32 WLAN_REASON_CODE_MSM_CONNECT_BASE = 229376;
	public const uint32 WLAN_REASON_CODE_MSM_END = 262143;
	public const uint32 WLAN_REASON_CODE_MSMSEC_BASE = 262144;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CONNECT_BASE = 294912;
	public const uint32 WLAN_REASON_CODE_MSMSEC_END = 327679;
	public const uint32 WLAN_REASON_CODE_RESERVED_BASE = 720896;
	public const uint32 WLAN_REASON_CODE_RESERVED_END = 786431;
	public const uint32 L2_PROFILE_MAX_NAME_LENGTH = 256;
	public const uint32 L2_NOTIFICATION_SOURCE_NONE = 0;
	public const uint32 L2_NOTIFICATION_SOURCE_DOT3_AUTO_CONFIG = 1;
	public const uint32 L2_NOTIFICATION_SOURCE_SECURITY = 2;
	public const uint32 L2_NOTIFICATION_SOURCE_ONEX = 4;
	public const uint32 L2_NOTIFICATION_SOURCE_WLAN_ACM = 8;
	public const uint32 L2_NOTIFICATION_SOURCE_WLAN_MSM = 16;
	public const uint32 L2_NOTIFICATION_SOURCE_WLAN_SECURITY = 32;
	public const uint32 L2_NOTIFICATION_SOURCE_WLAN_IHV = 64;
	public const uint32 L2_NOTIFICATION_SOURCE_WLAN_HNWK = 128;
	public const uint32 L2_NOTIFICATION_SOURCE_WCM = 256;
	public const uint32 L2_NOTIFICATION_SOURCE_WCM_CSP = 512;
	public const uint32 L2_NOTIFICATION_SOURCE_WFD = 1024;
	public const uint32 L2_NOTIFICATION_SOURCE_WLAN_DEVICE_SERVICE = 2048;
	public const uint32 L2_NOTIFICATION_SOURCE_ALL = 65535;
	public const uint32 L2_NOTIFICATION_CODE_PUBLIC_BEGIN = 0;
	public const uint32 L2_NOTIFICATION_CODE_GROUP_SIZE = 4096;
	public const uint32 L2_REASON_CODE_GROUP_SIZE = 65536;
	public const uint32 L2_REASON_CODE_GEN_BASE = 65536;
	public const uint32 L2_REASON_CODE_SUCCESS = 0;
	public const uint32 L2_REASON_CODE_UNKNOWN = 65537;
	public const uint32 L2_REASON_CODE_PROFILE_MISSING = 1;
	public const uint32 DOT11_BSSID_LIST_REVISION_1 = 1;
	public const uint32 DOT11_HESSID_LENGTH = 6;
	public const uint32 DOT11_RATE_SET_MAX_LENGTH = 126;
	public const uint32 DOT11_WFD_SERVICE_NAME_MAX_LENGTH = 255;
	public const uint32 DOT11_WFD_APS2_SERVICE_TYPE_MAX_LENGTH = 21;
	public const uint32 DOT11_WFD_ASP2_INSTANCE_NAME_MAX_LENGTH = 63;
	public const uint32 DOT11_WFD_SERVICE_INFORMATION_MAX_LENGTH = 65535;
	public const uint32 DOT11_MAX_REQUESTED_SERVICE_INFORMATION_LENGTH = 255;
	public const uint32 DOT11_WFD_SESSION_INFO_MAX_LENGTH = 144;
	public const uint32 NDIS_PACKET_TYPE_802_11_DIRECTED_DATA = 1;
	public const uint32 NDIS_PACKET_TYPE_802_11_BROADCAST_DATA = 8;
	public const uint32 NDIS_PACKET_TYPE_802_11_MULTICAST_DATA = 2;
	public const uint32 NDIS_PACKET_TYPE_802_11_ALL_MULTICAST_DATA = 4;
	public const uint32 NDIS_PACKET_TYPE_802_11_PROMISCUOUS_DATA = 32;
	public const uint32 DOT11_MAX_PDU_SIZE = 2346;
	public const uint32 DOT11_MIN_PDU_SIZE = 256;
	public const uint32 DOT11_MAX_NUM_DEFAULT_KEY = 4;
	public const uint32 DOT11_MAX_NUM_DEFAULT_KEY_MFP = 6;
	public const uint32 OID_DOT11_NDIS_START = 218170112;
	public const uint32 OID_DOT11_OFFLOAD_CAPABILITY = 218170112;
	public const uint32 DOT11_HW_WEP_SUPPORTED_TX = 1;
	public const uint32 DOT11_HW_WEP_SUPPORTED_RX = 2;
	public const uint32 DOT11_HW_FRAGMENTATION_SUPPORTED = 4;
	public const uint32 DOT11_HW_DEFRAGMENTATION_SUPPORTED = 8;
	public const uint32 DOT11_HW_MSDU_AUTH_SUPPORTED_TX = 16;
	public const uint32 DOT11_HW_MSDU_AUTH_SUPPORTED_RX = 32;
	public const uint32 DOT11_CONF_ALGO_WEP_RC4 = 1;
	public const uint32 DOT11_CONF_ALGO_TKIP = 2;
	public const uint32 DOT11_AUTH_ALGO_MICHAEL = 1;
	public const uint32 OID_DOT11_CURRENT_OFFLOAD_CAPABILITY = 218170113;
	public const uint32 OID_DOT11_WEP_OFFLOAD = 218170114;
	public const uint32 OID_DOT11_WEP_UPLOAD = 218170115;
	public const uint32 OID_DOT11_DEFAULT_WEP_OFFLOAD = 218170116;
	public const uint32 OID_DOT11_DEFAULT_WEP_UPLOAD = 218170117;
	public const uint32 OID_DOT11_MPDU_MAX_LENGTH = 218170118;
	public const uint32 OID_DOT11_OPERATION_MODE_CAPABILITY = 218170119;
	public const uint32 DOT11_OPERATION_MODE_UNKNOWN = 0;
	public const uint32 DOT11_OPERATION_MODE_STATION = 1;
	public const uint32 DOT11_OPERATION_MODE_AP = 2;
	public const uint32 DOT11_OPERATION_MODE_EXTENSIBLE_STATION = 4;
	public const uint32 DOT11_OPERATION_MODE_EXTENSIBLE_AP = 8;
	public const uint32 DOT11_OPERATION_MODE_WFD_DEVICE = 16;
	public const uint32 DOT11_OPERATION_MODE_WFD_GROUP_OWNER = 32;
	public const uint32 DOT11_OPERATION_MODE_WFD_CLIENT = 64;
	public const uint32 DOT11_OPERATION_MODE_MANUFACTURING = 1073741824;
	public const uint32 DOT11_OPERATION_MODE_NETWORK_MONITOR = 2147483648;
	public const uint32 OID_DOT11_CURRENT_OPERATION_MODE = 218170120;
	public const uint32 OID_DOT11_CURRENT_PACKET_FILTER = 218170121;
	public const uint32 DOT11_PACKET_TYPE_DIRECTED_CTRL = 1;
	public const uint32 DOT11_PACKET_TYPE_DIRECTED_MGMT = 2;
	public const uint32 DOT11_PACKET_TYPE_DIRECTED_DATA = 4;
	public const uint32 DOT11_PACKET_TYPE_MULTICAST_CTRL = 8;
	public const uint32 DOT11_PACKET_TYPE_MULTICAST_MGMT = 16;
	public const uint32 DOT11_PACKET_TYPE_MULTICAST_DATA = 32;
	public const uint32 DOT11_PACKET_TYPE_BROADCAST_CTRL = 64;
	public const uint32 DOT11_PACKET_TYPE_BROADCAST_MGMT = 128;
	public const uint32 DOT11_PACKET_TYPE_BROADCAST_DATA = 256;
	public const uint32 DOT11_PACKET_TYPE_PROMISCUOUS_CTRL = 512;
	public const uint32 DOT11_PACKET_TYPE_PROMISCUOUS_MGMT = 1024;
	public const uint32 DOT11_PACKET_TYPE_PROMISCUOUS_DATA = 2048;
	public const uint32 DOT11_PACKET_TYPE_ALL_MULTICAST_CTRL = 4096;
	public const uint32 DOT11_PACKET_TYPE_ALL_MULTICAST_MGMT = 8192;
	public const uint32 DOT11_PACKET_TYPE_ALL_MULTICAST_DATA = 16384;
	public const uint32 OID_DOT11_ATIM_WINDOW = 218170122;
	public const uint32 OID_DOT11_SCAN_REQUEST = 218170123;
	public const uint32 OID_DOT11_CURRENT_PHY_TYPE = 218170124;
	public const uint32 DOT11_PHY_TYPE_LIST_REVISION_1 = 1;
	public const uint32 OID_DOT11_JOIN_REQUEST = 218170125;
	public const uint32 DOT11_CAPABILITY_INFO_ESS = 1;
	public const uint32 DOT11_CAPABILITY_INFO_IBSS = 2;
	public const uint32 DOT11_CAPABILITY_INFO_CF_POLLABLE = 4;
	public const uint32 DOT11_CAPABILITY_INFO_CF_POLL_REQ = 8;
	public const uint32 DOT11_CAPABILITY_INFO_PRIVACY = 16;
	public const uint32 DOT11_CAPABILITY_SHORT_PREAMBLE = 32;
	public const uint32 DOT11_CAPABILITY_PBCC = 64;
	public const uint32 DOT11_CAPABILITY_CHANNEL_AGILITY = 128;
	public const uint32 DOT11_CAPABILITY_SHORT_SLOT_TIME = 1024;
	public const uint32 DOT11_CAPABILITY_DSSSOFDM = 8192;
	public const uint32 OID_DOT11_START_REQUEST = 218170126;
	public const uint32 OID_DOT11_UPDATE_IE = 218170127;
	public const uint32 OID_DOT11_RESET_REQUEST = 218170128;
	public const uint32 OID_DOT11_NIC_POWER_STATE = 218170129;
	public const uint32 OID_DOT11_OPTIONAL_CAPABILITY = 218170130;
	public const uint32 OID_DOT11_CURRENT_OPTIONAL_CAPABILITY = 218170131;
	public const uint32 OID_DOT11_STATION_ID = 218170132;
	public const uint32 OID_DOT11_MEDIUM_OCCUPANCY_LIMIT = 218170133;
	public const uint32 OID_DOT11_CF_POLLABLE = 218170134;
	public const uint32 OID_DOT11_CFP_PERIOD = 218170135;
	public const uint32 OID_DOT11_CFP_MAX_DURATION = 218170136;
	public const uint32 OID_DOT11_POWER_MGMT_MODE = 218170137;
	public const uint32 DOT11_POWER_SAVE_LEVEL_MAX_PSP = 1;
	public const uint32 DOT11_POWER_SAVE_LEVEL_FAST_PSP = 2;
	public const uint32 OID_DOT11_OPERATIONAL_RATE_SET = 218170138;
	public const uint32 OID_DOT11_BEACON_PERIOD = 218170139;
	public const uint32 OID_DOT11_DTIM_PERIOD = 218170140;
	public const uint32 OID_DOT11_WEP_ICV_ERROR_COUNT = 218170141;
	public const uint32 OID_DOT11_MAC_ADDRESS = 218170142;
	public const uint32 OID_DOT11_RTS_THRESHOLD = 218170143;
	public const uint32 OID_DOT11_SHORT_RETRY_LIMIT = 218170144;
	public const uint32 OID_DOT11_LONG_RETRY_LIMIT = 218170145;
	public const uint32 OID_DOT11_FRAGMENTATION_THRESHOLD = 218170146;
	public const uint32 OID_DOT11_MAX_TRANSMIT_MSDU_LIFETIME = 218170147;
	public const uint32 OID_DOT11_MAX_RECEIVE_LIFETIME = 218170148;
	public const uint32 OID_DOT11_COUNTERS_ENTRY = 218170149;
	public const uint32 OID_DOT11_SUPPORTED_PHY_TYPES = 218170150;
	public const uint32 OID_DOT11_CURRENT_REG_DOMAIN = 218170151;
	public const uint32 DOT11_REG_DOMAIN_OTHER = 0;
	public const uint32 DOT11_REG_DOMAIN_FCC = 16;
	public const uint32 DOT11_REG_DOMAIN_DOC = 32;
	public const uint32 DOT11_REG_DOMAIN_ETSI = 48;
	public const uint32 DOT11_REG_DOMAIN_SPAIN = 49;
	public const uint32 DOT11_REG_DOMAIN_FRANCE = 50;
	public const uint32 DOT11_REG_DOMAIN_MKK = 64;
	public const uint32 OID_DOT11_TEMP_TYPE = 218170152;
	public const uint32 OID_DOT11_CURRENT_TX_ANTENNA = 218170153;
	public const uint32 OID_DOT11_DIVERSITY_SUPPORT = 218170154;
	public const uint32 OID_DOT11_CURRENT_RX_ANTENNA = 218170155;
	public const uint32 OID_DOT11_SUPPORTED_POWER_LEVELS = 218170156;
	public const uint32 OID_DOT11_CURRENT_TX_POWER_LEVEL = 218170157;
	public const uint32 OID_DOT11_HOP_TIME = 218170158;
	public const uint32 OID_DOT11_CURRENT_CHANNEL_NUMBER = 218170159;
	public const uint32 OID_DOT11_MAX_DWELL_TIME = 218170160;
	public const uint32 OID_DOT11_CURRENT_DWELL_TIME = 218170161;
	public const uint32 OID_DOT11_CURRENT_SET = 218170162;
	public const uint32 OID_DOT11_CURRENT_PATTERN = 218170163;
	public const uint32 OID_DOT11_CURRENT_INDEX = 218170164;
	public const uint32 OID_DOT11_CURRENT_CHANNEL = 218170165;
	public const uint32 OID_DOT11_CCA_MODE_SUPPORTED = 218170166;
	public const uint32 DOT11_CCA_MODE_ED_ONLY = 1;
	public const uint32 DOT11_CCA_MODE_CS_ONLY = 2;
	public const uint32 DOT11_CCA_MODE_ED_and_CS = 4;
	public const uint32 DOT11_CCA_MODE_CS_WITH_TIMER = 8;
	public const uint32 DOT11_CCA_MODE_HRCS_AND_ED = 16;
	public const uint32 OID_DOT11_CURRENT_CCA_MODE = 218170167;
	public const uint32 OID_DOT11_ED_THRESHOLD = 218170168;
	public const uint32 OID_DOT11_CCA_WATCHDOG_TIMER_MAX = 218170169;
	public const uint32 OID_DOT11_CCA_WATCHDOG_COUNT_MAX = 218170170;
	public const uint32 OID_DOT11_CCA_WATCHDOG_TIMER_MIN = 218170171;
	public const uint32 OID_DOT11_CCA_WATCHDOG_COUNT_MIN = 218170172;
	public const uint32 OID_DOT11_REG_DOMAINS_SUPPORT_VALUE = 218170173;
	public const uint32 OID_DOT11_SUPPORTED_TX_ANTENNA = 218170174;
	public const uint32 OID_DOT11_SUPPORTED_RX_ANTENNA = 218170175;
	public const uint32 OID_DOT11_DIVERSITY_SELECTION_RX = 218170176;
	public const uint32 OID_DOT11_SUPPORTED_DATA_RATES_VALUE = 218170177;
	public const uint32 MAX_NUM_SUPPORTED_RATES = 8;
	public const uint32 MAX_NUM_SUPPORTED_RATES_V2 = 255;
	public const uint32 OID_DOT11_CURRENT_FREQUENCY = 218170178;
	public const uint32 OID_DOT11_TI_THRESHOLD = 218170179;
	public const uint32 OID_DOT11_FREQUENCY_BANDS_SUPPORTED = 218170180;
	public const uint32 DOT11_FREQUENCY_BANDS_LOWER = 1;
	public const uint32 DOT11_FREQUENCY_BANDS_MIDDLE = 2;
	public const uint32 DOT11_FREQUENCY_BANDS_UPPER = 4;
	public const uint32 OID_DOT11_SHORT_PREAMBLE_OPTION_IMPLEMENTED = 218170181;
	public const uint32 OID_DOT11_PBCC_OPTION_IMPLEMENTED = 218170182;
	public const uint32 OID_DOT11_CHANNEL_AGILITY_PRESENT = 218170183;
	public const uint32 OID_DOT11_CHANNEL_AGILITY_ENABLED = 218170184;
	public const uint32 OID_DOT11_HR_CCA_MODE_SUPPORTED = 218170185;
	public const uint32 DOT11_HR_CCA_MODE_ED_ONLY = 1;
	public const uint32 DOT11_HR_CCA_MODE_CS_ONLY = 2;
	public const uint32 DOT11_HR_CCA_MODE_CS_AND_ED = 4;
	public const uint32 DOT11_HR_CCA_MODE_CS_WITH_TIMER = 8;
	public const uint32 DOT11_HR_CCA_MODE_HRCS_AND_ED = 16;
	public const uint32 OID_DOT11_MULTI_DOMAIN_CAPABILITY_IMPLEMENTED = 218170186;
	public const uint32 OID_DOT11_MULTI_DOMAIN_CAPABILITY_ENABLED = 218170187;
	public const uint32 OID_DOT11_COUNTRY_STRING = 218170188;
	public const uint32 OID_DOT11_MULTI_DOMAIN_CAPABILITY = 218170189;
	public const uint32 OID_DOT11_EHCC_PRIME_RADIX = 218170190;
	public const uint32 OID_DOT11_EHCC_NUMBER_OF_CHANNELS_FAMILY_INDEX = 218170191;
	public const uint32 OID_DOT11_EHCC_CAPABILITY_IMPLEMENTED = 218170192;
	public const uint32 OID_DOT11_EHCC_CAPABILITY_ENABLED = 218170193;
	public const uint32 OID_DOT11_HOP_ALGORITHM_ADOPTED = 218170194;
	public const uint32 OID_DOT11_RANDOM_TABLE_FLAG = 218170195;
	public const uint32 OID_DOT11_NUMBER_OF_HOPPING_SETS = 218170196;
	public const uint32 OID_DOT11_HOP_MODULUS = 218170197;
	public const uint32 OID_DOT11_HOP_OFFSET = 218170198;
	public const uint32 OID_DOT11_HOPPING_PATTERN = 218170199;
	public const uint32 OID_DOT11_RANDOM_TABLE_FIELD_NUMBER = 218170200;
	public const uint32 OID_DOT11_WPA_TSC = 218170201;
	public const uint32 OID_DOT11_RSSI_RANGE = 218170202;
	public const uint32 OID_DOT11_RF_USAGE = 218170203;
	public const uint32 OID_DOT11_NIC_SPECIFIC_EXTENSION = 218170204;
	public const uint32 OID_DOT11_AP_JOIN_REQUEST = 218170205;
	public const uint32 OID_DOT11_ERP_PBCC_OPTION_IMPLEMENTED = 218170206;
	public const uint32 OID_DOT11_ERP_PBCC_OPTION_ENABLED = 218170207;
	public const uint32 OID_DOT11_DSSS_OFDM_OPTION_IMPLEMENTED = 218170208;
	public const uint32 OID_DOT11_DSSS_OFDM_OPTION_ENABLED = 218170209;
	public const uint32 OID_DOT11_SHORT_SLOT_TIME_OPTION_IMPLEMENTED = 218170210;
	public const uint32 OID_DOT11_SHORT_SLOT_TIME_OPTION_ENABLED = 218170211;
	public const uint32 OID_DOT11_MAX_MAC_ADDRESS_STATES = 218170212;
	public const uint32 OID_DOT11_RECV_SENSITIVITY_LIST = 218170213;
	public const uint32 OID_DOT11_WME_IMPLEMENTED = 218170214;
	public const uint32 OID_DOT11_WME_ENABLED = 218170215;
	public const uint32 OID_DOT11_WME_AC_PARAMETERS = 218170216;
	public const uint32 OID_DOT11_WME_UPDATE_IE = 218170217;
	public const uint32 OID_DOT11_QOS_TX_QUEUES_SUPPORTED = 218170218;
	public const uint32 OID_DOT11_QOS_TX_DURATION = 218170219;
	public const uint32 OID_DOT11_QOS_TX_MEDIUM_TIME = 218170220;
	public const uint32 OID_DOT11_SUPPORTED_OFDM_FREQUENCY_LIST = 218170221;
	public const uint32 OID_DOT11_SUPPORTED_DSSS_CHANNEL_LIST = 218170222;
	public const uint32 DOT11_BSS_ENTRY_BYTE_ARRAY_REVISION_1 = 1;
	public const uint32 DOT11_POWER_SAVING_NO_POWER_SAVING = 0;
	public const uint32 DOT11_POWER_SAVING_FAST_PSP = 8;
	public const uint32 DOT11_POWER_SAVING_MAX_PSP = 16;
	public const uint32 DOT11_POWER_SAVING_MAXIMUM_LEVEL = 24;
	public const uint32 DOT11_SSID_LIST_REVISION_1 = 1;
	public const uint32 DOT11_MAC_ADDRESS_LIST_REVISION_1 = 1;
	public const uint32 DOT11_PMKID_LIST_REVISION_1 = 1;
	public const uint32 DOT11_STATISTICS_REVISION_1 = 1;
	public const uint32 DOT11_EXEMPT_NO_EXEMPTION = 0;
	public const uint32 DOT11_EXEMPT_ALWAYS = 1;
	public const uint32 DOT11_EXEMPT_ON_KEY_MAPPING_KEY_UNAVAILABLE = 2;
	public const uint32 DOT11_EXEMPT_UNICAST = 1;
	public const uint32 DOT11_EXEMPT_MULTICAST = 2;
	public const uint32 DOT11_EXEMPT_BOTH = 3;
	public const uint32 DOT11_PRIVACY_EXEMPTION_LIST_REVISION_1 = 1;
	public const uint32 DOT11_AUTH_ALGORITHM_LIST_REVISION_1 = 1;
	public const uint32 DOT11_AUTH_CIPHER_PAIR_LIST_REVISION_1 = 1;
	public const uint32 DOT11_CIPHER_ALGORITHM_LIST_REVISION_1 = 1;
	public const uint32 DOT11_CIPHER_DEFAULT_KEY_VALUE_REVISION_1 = 1;
	public const uint32 DOT11_CIPHER_KEY_MAPPING_KEY_VALUE_BYTE_ARRAY_REVISION_1 = 1;
	public const uint32 DOT11_ASSOCIATION_INFO_LIST_REVISION_1 = 1;
	public const uint32 DOT11_PHY_ID_LIST_REVISION_1 = 1;
	public const uint32 DOT11_EXTSTA_CAPABILITY_REVISION_1 = 1;
	public const uint32 DOT11_DATA_RATE_MAPPING_TABLE_REVISION_1 = 1;
	public const uint32 DOT11_COUNTRY_OR_REGION_STRING_LIST_REVISION_1 = 1;
	public const uint32 DOT11_PORT_STATE_NOTIFICATION_REVISION_1 = 1;
	public const uint32 DOT11_IBSS_PARAMS_REVISION_1 = 1;
	public const uint32 DOT11_QOS_PARAMS_REVISION_1 = 1;
	public const uint32 DOT11_ASSOCIATION_PARAMS_REVISION_1 = 1;
	public const uint32 DOT11_MAX_NUM_OF_FRAGMENTS = 16;
	public const uint32 DOT11_PRIORITY_CONTENTION = 0;
	public const uint32 DOT11_PRIORITY_CONTENTION_FREE = 1;
	public const uint32 DOT11_SERVICE_CLASS_REORDERABLE_MULTICAST = 0;
	public const uint32 DOT11_SERVICE_CLASS_STRICTLY_ORDERED = 1;
	public const uint32 DOT11_FLAGS_80211B_SHORT_PREAMBLE = 1;
	public const uint32 DOT11_FLAGS_80211B_PBCC = 2;
	public const uint32 DOT11_FLAGS_80211B_CHANNEL_AGILITY = 4;
	public const uint32 DOT11_FLAGS_PS_ON = 8;
	public const uint32 DOT11_FLAGS_80211G_DSSS_OFDM = 16;
	public const uint32 DOT11_FLAGS_80211G_USE_PROTECTION = 32;
	public const uint32 DOT11_FLAGS_80211G_NON_ERP_PRESENT = 64;
	public const uint32 DOT11_FLAGS_80211G_BARKER_PREAMBLE_MODE = 128;
	public const uint32 DOT11_WME_PACKET = 256;
	public const uint32 DOT11_PHY_ATTRIBUTES_REVISION_1 = 1;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_SAFEMODE_OID_SUPPORTED = 1;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_SAFEMODE_CERTIFIED = 2;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_SAFEMODE_RESERVED = 12;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_REVISION_1 = 1;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_REVISION_2 = 2;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_REVISION_3 = 3;
	public const uint32 DOT11_EXTSTA_ATTRIBUTES_REVISION_4 = 4;
	public const uint32 DOT11_SEND_CONTEXT_REVISION_1 = 1;
	public const uint32 DOT11_RECV_CONTEXT_REVISION_1 = 1;
	public const uint32 DOT11_STATUS_SUCCESS = 1;
	public const uint32 DOT11_STATUS_RETRY_LIMIT_EXCEEDED = 2;
	public const uint32 DOT11_STATUS_UNSUPPORTED_PRIORITY = 4;
	public const uint32 DOT11_STATUS_UNSUPPORTED_SERVICE_CLASS = 8;
	public const uint32 DOT11_STATUS_UNAVAILABLE_PRIORITY = 16;
	public const uint32 DOT11_STATUS_UNAVAILABLE_SERVICE_CLASS = 32;
	public const uint32 DOT11_STATUS_XMIT_MSDU_TIMER_EXPIRED = 64;
	public const uint32 DOT11_STATUS_UNAVAILABLE_BSS = 128;
	public const uint32 DOT11_STATUS_EXCESSIVE_DATA_LENGTH = 256;
	public const uint32 DOT11_STATUS_ENCRYPTION_FAILED = 512;
	public const uint32 DOT11_STATUS_WEP_KEY_UNAVAILABLE = 1024;
	public const uint32 DOT11_STATUS_ICV_VERIFIED = 2048;
	public const uint32 DOT11_STATUS_PACKET_REASSEMBLED = 4096;
	public const uint32 DOT11_STATUS_PACKET_NOT_REASSEMBLED = 8192;
	public const uint32 DOT11_STATUS_GENERATE_AUTH_FAILED = 16384;
	public const uint32 DOT11_STATUS_AUTH_NOT_VERIFIED = 32768;
	public const uint32 DOT11_STATUS_AUTH_VERIFIED = 65536;
	public const uint32 DOT11_STATUS_AUTH_FAILED = 131072;
	public const uint32 DOT11_STATUS_PS_LIFETIME_EXPIRED = 262144;
	public const uint32 DOT11_STATUS_RESET_CONFIRM = 4;
	public const uint32 DOT11_STATUS_SCAN_CONFIRM = 1;
	public const uint32 DOT11_STATUS_JOIN_CONFIRM = 2;
	public const uint32 DOT11_STATUS_START_CONFIRM = 3;
	public const uint32 DOT11_STATUS_AP_JOIN_CONFIRM = 5;
	public const uint32 DOT11_STATUS_MPDU_MAX_LENGTH_CHANGED = 6;
	public const uint32 DOT11_MPDU_MAX_LENGTH_INDICATION_REVISION_1 = 1;
	public const uint32 DOT11_ASSOCIATION_START_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_ENCAP_RFC_1042 = 1;
	public const uint32 DOT11_ENCAP_802_1H = 2;
	public const uint32 DOT11_ASSOC_STATUS_SUCCESS = 0;
	public const uint32 DOT11_ASSOCIATION_COMPLETION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_ASSOCIATION_COMPLETION_PARAMETERS_REVISION_2 = 2;
	public const uint32 DOT11_CONNECTION_START_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_CONNECTION_STATUS_SUCCESS = 0;
	public const uint32 DOT11_CONNECTION_COMPLETION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_ROAMING_START_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_ROAMING_COMPLETION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_DISASSOCIATION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_TKIPMIC_FAILURE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_PMKID_CANDIDATE_LIST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_PHY_STATE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_LINK_QUALITY_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_EXTSTA_SEND_CONTEXT_REVISION_1 = 1;
	public const uint32 DOT11_EXTSTA_RECV_CONTEXT_REVISION_1 = 1;
	public const uint32 OID_DOT11_PRIVATE_OIDS_START = 218171136;
	public const uint32 OID_DOT11_CURRENT_ADDRESS = 218171138;
	public const uint32 OID_DOT11_PERMANENT_ADDRESS = 218171139;
	public const uint32 OID_DOT11_MULTICAST_LIST = 218171140;
	public const uint32 OID_DOT11_MAXIMUM_LIST_SIZE = 218171141;
	public const uint32 DOT11_EXTAP_ATTRIBUTES_REVISION_1 = 1;
	public const uint32 DOT11_INCOMING_ASSOC_STARTED_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_INCOMING_ASSOC_REQUEST_RECEIVED_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_ASSOC_ERROR_SOURCE_OS = 0;
	public const uint32 DOT11_ASSOC_ERROR_SOURCE_REMOTE = 1;
	public const uint32 DOT11_ASSOC_ERROR_SOURCE_OTHER = 255;
	public const uint32 DOT11_INCOMING_ASSOC_COMPLETION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_STOP_AP_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_STOP_AP_REASON_FREQUENCY_NOT_AVAILABLE = 1;
	public const uint32 DOT11_STOP_AP_REASON_CHANNEL_NOT_AVAILABLE = 2;
	public const uint32 DOT11_STOP_AP_REASON_AP_ACTIVE = 3;
	public const uint32 DOT11_STOP_AP_REASON_IHV_START = 4278190080;
	public const uint32 DOT11_STOP_AP_REASON_IHV_END = 4294967295;
	public const uint32 DOT11_PHY_FREQUENCY_ADOPTED_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_CAN_SUSTAIN_AP_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_CAN_SUSTAIN_AP_REASON_IHV_START = 4278190080;
	public const uint32 DOT11_CAN_SUSTAIN_AP_REASON_IHV_END = 4294967295;
	public const uint32 DOT11_AVAILABLE_CHANNEL_LIST_REVISION_1 = 1;
	public const uint32 DOT11_AVAILABLE_FREQUENCY_LIST_REVISION_1 = 1;
	public const uint32 DOT11_DISASSOCIATE_PEER_REQUEST_REVISION_1 = 1;
	public const uint32 DOT11_INCOMING_ASSOC_DECISION_REVISION_1 = 1;
	public const uint32 DOT11_INCOMING_ASSOC_DECISION_REVISION_2 = 2;
	public const uint32 DOT11_ADDITIONAL_IE_REVISION_1 = 1;
	public const uint32 DOT11_EXTAP_SEND_CONTEXT_REVISION_1 = 1;
	public const uint32 DOT11_EXTAP_RECV_CONTEXT_REVISION_1 = 1;
	public const uint32 DOT11_PEER_INFO_LIST_REVISION_1 = 1;
	public const uint32 DOT11_VWIFI_COMBINATION_REVISION_1 = 1;
	public const uint32 DOT11_VWIFI_COMBINATION_REVISION_2 = 2;
	public const uint32 DOT11_VWIFI_COMBINATION_REVISION_3 = 3;
	public const uint32 DOT11_VWIFI_ATTRIBUTES_REVISION_1 = 1;
	public const uint32 DOT11_MAC_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_WFD_ATTRIBUTES_REVISION_1 = 1;
	public const uint32 DOT11_WFD_STATUS_SUCCESS = 0;
	public const uint32 DOT11_WFD_STATUS_FAILED_INFORMATION_IS_UNAVAILABLE = 1;
	public const uint32 DOT11_WFD_STATUS_FAILED_INCOMPATIBLE_PARAMETERS = 2;
	public const uint32 DOT11_WFD_STATUS_FAILED_LIMIT_REACHED = 3;
	public const uint32 DOT11_WFD_STATUS_FAILED_INVALID_PARAMETERS = 4;
	public const uint32 DOT11_WFD_STATUS_FAILED_UNABLE_TO_ACCOMODATE_REQUEST = 5;
	public const uint32 DOT11_WFD_STATUS_FAILED_PREVIOUS_PROTOCOL_ERROR = 6;
	public const uint32 DOT11_WFD_STATUS_FAILED_NO_COMMON_CHANNELS = 7;
	public const uint32 DOT11_WFD_STATUS_FAILED_UNKNOWN_WFD_GROUP = 8;
	public const uint32 DOT11_WFD_STATUS_FAILED_MATCHING_MAX_INTENT = 9;
	public const uint32 DOT11_WFD_STATUS_FAILED_INCOMPATIBLE_PROVISIONING_METHOD = 10;
	public const uint32 DOT11_WFD_STATUS_FAILED_REJECTED_BY_USER = 11;
	public const uint32 DOT11_WFD_STATUS_SUCCESS_ACCEPTED_BY_USER = 12;
	public const uint32 DOT11_WFD_MINOR_REASON_SUCCESS = 0;
	public const uint32 DOT11_WFD_MINOR_REASON_DISASSOCIATED_FROM_WLAN_CROSS_CONNECTION_POLICY = 1;
	public const uint32 DOT11_WFD_MINOR_REASON_DISASSOCIATED_NOT_MANAGED_INFRASTRUCTURE_CAPABLE = 2;
	public const uint32 DOT11_WFD_MINOR_REASON_DISASSOCIATED_WFD_COEXISTENCE_POLICY = 3;
	public const uint32 DOT11_WFD_MINOR_REASON_DISASSOCIATED_INFRASTRUCTURE_MANAGED_POLICY = 4;
	public const uint32 DOT11_WPS_VERSION_1_0 = 1;
	public const uint32 DOT11_WPS_VERSION_2_0 = 2;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_SERVICE_DISCOVERY = 1;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_P2P_CLIENT_DISCOVERABILITY = 2;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_CONCURRENT_OPERATION = 4;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_P2P_INFRASTRUCTURE_MANAGED = 8;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_P2P_DEVICE_LIMIT = 16;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_P2P_INVITATION_PROCEDURE = 32;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_RESERVED_6 = 64;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_RESERVED_7 = 128;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_NONE = 0;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_GROUP_OWNER = 1;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_PERSISTENT_GROUP = 2;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_GROUP_LIMIT_REACHED = 4;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_INTRABSS_DISTRIBUTION_SUPPORTED = 8;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_CROSS_CONNECTION_SUPPORTED = 16;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_PERSISTENT_RECONNECT_SUPPORTED = 32;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_IN_GROUP_FORMATION = 64;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_RESERVED_7 = 128;
	public const uint32 DOT11_WFD_GROUP_CAPABILITY_EAPOL_KEY_IP_ADDRESS_ALLOCATION_SUPPORTED = 128;
	public const uint32 DOT11_WPS_DEVICE_NAME_MAX_LENGTH = 32;
	public const uint32 DOT11_WPS_MAX_PASSKEY_LENGTH = 8;
	public const uint32 DOT11_WPS_MAX_MODEL_NAME_LENGTH = 32;
	public const uint32 DOT11_WPS_MAX_MODEL_NUMBER_LENGTH = 32;
	public const uint32 WFDSVC_CONNECTION_CAPABILITY_NEW = 1;
	public const uint32 WFDSVC_CONNECTION_CAPABILITY_CLIENT = 2;
	public const uint32 WFDSVC_CONNECTION_CAPABILITY_GO = 4;
	public const uint32 DOT11_WFD_DISCOVER_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_WFD_DISCOVER_COMPLETE_MAX_LIST_SIZE = 128;
	public const uint32 DOT11_GO_NEGOTIATION_REQUEST_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_GO_NEGOTIATION_REQUEST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_GO_NEGOTIATION_RESPONSE_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_GO_NEGOTIATION_RESPONSE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_GO_NEGOTIATION_CONFIRMATION_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_GO_NEGOTIATION_CONFIRMATION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_INVITATION_REQUEST_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_INVITATION_REQUEST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_INVITATION_RESPONSE_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_INVITATION_RESPONSE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_PROVISION_DISCOVERY_REQUEST_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_PROVISION_DISCOVERY_REQUEST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_PROVISION_DISCOVERY_RESPONSE_SEND_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_RECEIVED_PROVISION_DISCOVERY_RESPONSE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_ANQP_QUERY_COMPLETE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_WFD_DEVICE_CAPABILITY_CONFIG_REVISION_1 = 1;
	public const uint32 DOT11_WFD_GROUP_OWNER_CAPABILITY_CONFIG_REVISION_1 = 1;
	public const uint32 DOT11_WFD_GROUP_OWNER_CAPABILITY_CONFIG_REVISION_2 = 2;
	public const uint32 DOT11_WFD_DEVICE_INFO_REVISION_1 = 1;
	public const uint32 DOT11_WFD_SECONDARY_DEVICE_TYPE_LIST_REVISION_1 = 1;
	public const uint32 DISCOVERY_FILTER_BITMASK_DEVICE = 1;
	public const uint32 DISCOVERY_FILTER_BITMASK_GO = 2;
	public const uint32 DISCOVERY_FILTER_BITMASK_ANY = 15;
	public const uint32 DOT11_WFD_DISCOVER_REQUEST_REVISION_1 = 1;
	public const uint32 DOT11_DEVICE_ENTRY_BYTE_ARRAY_REVISION_1 = 1;
	public const uint32 DOT11_WFD_DEVICE_NOT_DISCOVERABLE = 0;
	public const uint32 DOT11_WFD_DEVICE_AUTO_AVAILABILITY = 16;
	public const uint32 DOT11_WFD_DEVICE_HIGH_AVAILABILITY = 24;
	public const uint32 DOT11_WFD_ADDITIONAL_IE_REVISION_1 = 1;
	public const uint32 DOT11_SEND_GO_NEGOTIATION_REQUEST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_SEND_GO_NEGOTIATION_RESPONSE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_SEND_GO_NEGOTIATION_CONFIRMATION_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_SEND_INVITATION_REQUEST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_SEND_INVITATION_RESPONSE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_SEND_PROVISION_DISCOVERY_REQUEST_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_SEND_PROVISION_DISCOVERY_RESPONSE_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_WFD_DEVICE_LISTEN_CHANNEL_REVISION_1 = 1;
	public const uint32 DOT11_WFD_GROUP_START_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_WFD_GROUP_JOIN_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_POWER_MGMT_AUTO_MODE_ENABLED_REVISION_1 = 1;
	public const uint32 DOT11_POWER_MGMT_MODE_STATUS_INFO_REVISION_1 = 1;
	public const uint32 DOT11_MAX_CHANNEL_HINTS = 4;
	public const uint32 DOT11_INVALID_CHANNEL_NUMBER = 0;
	public const uint32 DOT11_NLO_FLAG_STOP_NLO_INDICATION = 1;
	public const uint32 DOT11_NLO_FLAG_SCAN_ON_AOAC_PLATFORM = 2;
	public const uint32 DOT11_NLO_FLAG_SCAN_AT_SYSTEM_RESUME = 4;
	public const uint32 DOT11_OFFLOAD_NETWORK_LIST_REVISION_1 = 1;
	public const uint32 DOT11_OFFLOAD_NETWORK_STATUS_PARAMETERS_REVISION_1 = 1;
	public const uint32 DOT11_MANUFACTURING_TEST_REVISION_1 = 1;
	public const uint32 DOT11_MANUFACTURING_CALLBACK_REVISION_1 = 1;
	public const uint32 DOT11_SSID_MAX_LENGTH = 32;
	public const uint32 DOT11_OI_MAX_LENGTH = 5;
	public const uint32 DOT11_OI_MIN_LENGTH = 3;
	public const uint32 DevProp_PciRootBus_SecondaryInterface_PciConventional = 0;
	public const uint32 DevProp_PciRootBus_SecondaryInterface_PciXMode1 = 1;
	public const uint32 DevProp_PciRootBus_SecondaryInterface_PciXMode2 = 2;
	public const uint32 DevProp_PciRootBus_SecondaryInterface_PciExpress = 3;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_Conventional_33Mhz = 0;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_Conventional_66Mhz = 1;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_Mode1_66Mhz = 2;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_Mode1_100Mhz = 3;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_Mode1_133Mhz = 4;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_Mode1_ECC_66Mhz = 5;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_Mode1_ECC_100Mhz = 6;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_Mode1_ECC_133Mhz = 7;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_266_Mode2_66Mhz = 8;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_266_Mode2_100Mhz = 9;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_266_Mode2_133Mhz = 10;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_533_Mode2_66Mhz = 11;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_533_Mode2_100Mhz = 12;
	public const uint32 DevProp_PciRootBus_CurrentSpeedAndMode_Pci_X_533_Mode2_133Mhz = 13;
	public const uint32 DevProp_PciRootBus_SupportedSpeedsAndModes_Pci_Conventional_33Mhz = 1;
	public const uint32 DevProp_PciRootBus_SupportedSpeedsAndModes_Pci_Conventional_66Mhz = 2;
	public const uint32 DevProp_PciRootBus_SupportedSpeedsAndModes_Pci_X_66Mhz = 4;
	public const uint32 DevProp_PciRootBus_SupportedSpeedsAndModes_Pci_X_133Mhz = 8;
	public const uint32 DevProp_PciRootBus_SupportedSpeedsAndModes_Pci_X_266Mhz = 16;
	public const uint32 DevProp_PciRootBus_SupportedSpeedsAndModes_Pci_X_533Mhz = 32;
	public const uint32 DevProp_PciRootBus_BusWidth_32Bits = 0;
	public const uint32 DevProp_PciRootBus_BusWidth_64Bits = 1;
	public const uint32 DevProp_PciDevice_DeviceType_PciConventional = 0;
	public const uint32 DevProp_PciDevice_DeviceType_PciX = 1;
	public const uint32 DevProp_PciDevice_DeviceType_PciExpressEndpoint = 2;
	public const uint32 DevProp_PciDevice_DeviceType_PciExpressLegacyEndpoint = 3;
	public const uint32 DevProp_PciDevice_DeviceType_PciExpressRootComplexIntegratedEndpoint = 4;
	public const uint32 DevProp_PciDevice_DeviceType_PciExpressTreatedAsPci = 5;
	public const uint32 DevProp_PciDevice_BridgeType_PciConventional = 6;
	public const uint32 DevProp_PciDevice_BridgeType_PciX = 7;
	public const uint32 DevProp_PciDevice_BridgeType_PciExpressRootPort = 8;
	public const uint32 DevProp_PciDevice_BridgeType_PciExpressUpstreamSwitchPort = 9;
	public const uint32 DevProp_PciDevice_BridgeType_PciExpressDownstreamSwitchPort = 10;
	public const uint32 DevProp_PciDevice_BridgeType_PciExpressToPciXBridge = 11;
	public const uint32 DevProp_PciDevice_BridgeType_PciXToExpressBridge = 12;
	public const uint32 DevProp_PciDevice_BridgeType_PciExpressTreatedAsPci = 13;
	public const uint32 DevProp_PciDevice_BridgeType_PciExpressEventCollector = 14;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_Pci_Conventional_33MHz = 0;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_Pci_Conventional_66MHz = 1;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode_Conventional_Pci = 0;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode1_66Mhz = 1;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode1_100Mhz = 2;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode1_133MHZ = 3;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode1_ECC_66Mhz = 5;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode1_ECC_100Mhz = 6;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode1_ECC_133Mhz = 7;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode2_266_66MHz = 9;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode2_266_100MHz = 10;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode2_266_133MHz = 11;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode2_533_66MHz = 13;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode2_533_100MHz = 14;
	public const uint32 DevProp_PciDevice_CurrentSpeedAndMode_PciX_Mode2_533_133MHz = 15;
	public const uint32 DevProp_PciExpressDevice_PayloadOrRequestSize_128Bytes = 0;
	public const uint32 DevProp_PciExpressDevice_PayloadOrRequestSize_256Bytes = 1;
	public const uint32 DevProp_PciExpressDevice_PayloadOrRequestSize_512Bytes = 2;
	public const uint32 DevProp_PciExpressDevice_PayloadOrRequestSize_1024Bytes = 3;
	public const uint32 DevProp_PciExpressDevice_PayloadOrRequestSize_2048Bytes = 4;
	public const uint32 DevProp_PciExpressDevice_PayloadOrRequestSize_4096Bytes = 5;
	public const uint32 DevProp_PciExpressDevice_LinkSpeed_TwoAndHalf_Gbps = 1;
	public const uint32 DevProp_PciExpressDevice_LinkSpeed_Five_Gbps = 2;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_1 = 1;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_2 = 2;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_4 = 4;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_8 = 8;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_12 = 12;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_16 = 16;
	public const uint32 DevProp_PciExpressDevice_LinkWidth_By_32 = 32;
	public const uint32 DevProp_PciExpressDevice_Spec_Version_10 = 1;
	public const uint32 DevProp_PciExpressDevice_Spec_Version_11 = 2;
	public const uint32 DevProp_PciDevice_InterruptType_LineBased = 1;
	public const uint32 DevProp_PciDevice_InterruptType_Msi = 2;
	public const uint32 DevProp_PciDevice_InterruptType_MsiX = 4;
	public const uint32 DevProp_PciDevice_SriovSupport_Ok = 0;
	public const uint32 DevProp_PciDevice_SriovSupport_MissingAcs = 1;
	public const uint32 DevProp_PciDevice_SriovSupport_MissingPfDriver = 2;
	public const uint32 DevProp_PciDevice_SriovSupport_NoBusResource = 3;
	public const uint32 DevProp_PciDevice_SriovSupport_DidntGetVfBarSpace = 4;
	public const uint32 DevProp_PciDevice_AcsSupport_Present = 0;
	public const uint32 DevProp_PciDevice_AcsSupport_NotNeeded = 1;
	public const uint32 DevProp_PciDevice_AcsSupport_Missing = 2;
	public const uint32 DevProp_PciDevice_AcsCompatibleUpHierarchy_NotSupported = 0;
	public const uint32 DevProp_PciDevice_AcsCompatibleUpHierarchy_SingleFunctionSupported = 1;
	public const uint32 DevProp_PciDevice_AcsCompatibleUpHierarchy_NoP2PSupported = 2;
	public const uint32 DevProp_PciDevice_AcsCompatibleUpHierarchy_Supported = 3;
	public const uint32 DevProp_PciDevice_AcsCompatibleUpHierarchy_Enhanced = 4;
	public const uint32 WLAN_API_VERSION_1_0 = 1;
	public const uint32 WLAN_API_VERSION_2_0 = 2;
	public const uint32 WLAN_API_VERSION = 2;
	public const uint32 WLAN_MAX_NAME_LENGTH = 256;
	public const uint32 WLAN_PROFILE_GROUP_POLICY = 1;
	public const uint32 WLAN_PROFILE_USER = 2;
	public const uint32 WLAN_PROFILE_GET_PLAINTEXT_KEY = 4;
	public const uint32 WLAN_PROFILE_CONNECTION_MODE_SET_BY_CLIENT = 65536;
	public const uint32 WLAN_PROFILE_CONNECTION_MODE_AUTO = 131072;
	public const uint32 DOT11_PSD_IE_MAX_DATA_SIZE = 240;
	public const uint32 DOT11_PSD_IE_MAX_ENTRY_NUMBER = 5;
	public const uint32 WLAN_REASON_CODE_NETWORK_NOT_COMPATIBLE = 131073;
	public const uint32 WLAN_REASON_CODE_PROFILE_NOT_COMPATIBLE = 131074;
	public const uint32 WLAN_REASON_CODE_NO_AUTO_CONNECTION = 163841;
	public const uint32 WLAN_REASON_CODE_NOT_VISIBLE = 163842;
	public const uint32 WLAN_REASON_CODE_GP_DENIED = 163843;
	public const uint32 WLAN_REASON_CODE_USER_DENIED = 163844;
	public const uint32 WLAN_REASON_CODE_BSS_TYPE_NOT_ALLOWED = 163845;
	public const uint32 WLAN_REASON_CODE_IN_FAILED_LIST = 163846;
	public const uint32 WLAN_REASON_CODE_IN_BLOCKED_LIST = 163847;
	public const uint32 WLAN_REASON_CODE_SSID_LIST_TOO_LONG = 163848;
	public const uint32 WLAN_REASON_CODE_CONNECT_CALL_FAIL = 163849;
	public const uint32 WLAN_REASON_CODE_SCAN_CALL_FAIL = 163850;
	public const uint32 WLAN_REASON_CODE_NETWORK_NOT_AVAILABLE = 163851;
	public const uint32 WLAN_REASON_CODE_PROFILE_CHANGED_OR_DELETED = 163852;
	public const uint32 WLAN_REASON_CODE_KEY_MISMATCH = 163853;
	public const uint32 WLAN_REASON_CODE_USER_NOT_RESPOND = 163854;
	public const uint32 WLAN_REASON_CODE_AP_PROFILE_NOT_ALLOWED_FOR_CLIENT = 163855;
	public const uint32 WLAN_REASON_CODE_AP_PROFILE_NOT_ALLOWED = 163856;
	public const uint32 WLAN_REASON_CODE_HOTSPOT2_PROFILE_DENIED = 163857;
	public const uint32 WLAN_REASON_CODE_INVALID_PROFILE_SCHEMA = 524289;
	public const uint32 WLAN_REASON_CODE_PROFILE_MISSING = 524290;
	public const uint32 WLAN_REASON_CODE_INVALID_PROFILE_NAME = 524291;
	public const uint32 WLAN_REASON_CODE_INVALID_PROFILE_TYPE = 524292;
	public const uint32 WLAN_REASON_CODE_INVALID_PHY_TYPE = 524293;
	public const uint32 WLAN_REASON_CODE_MSM_SECURITY_MISSING = 524294;
	public const uint32 WLAN_REASON_CODE_IHV_SECURITY_NOT_SUPPORTED = 524295;
	public const uint32 WLAN_REASON_CODE_IHV_OUI_MISMATCH = 524296;
	public const uint32 WLAN_REASON_CODE_IHV_OUI_MISSING = 524297;
	public const uint32 WLAN_REASON_CODE_IHV_SETTINGS_MISSING = 524298;
	public const uint32 WLAN_REASON_CODE_CONFLICT_SECURITY = 524299;
	public const uint32 WLAN_REASON_CODE_SECURITY_MISSING = 524300;
	public const uint32 WLAN_REASON_CODE_INVALID_BSS_TYPE = 524301;
	public const uint32 WLAN_REASON_CODE_INVALID_ADHOC_CONNECTION_MODE = 524302;
	public const uint32 WLAN_REASON_CODE_NON_BROADCAST_SET_FOR_ADHOC = 524303;
	public const uint32 WLAN_REASON_CODE_AUTO_SWITCH_SET_FOR_ADHOC = 524304;
	public const uint32 WLAN_REASON_CODE_AUTO_SWITCH_SET_FOR_MANUAL_CONNECTION = 524305;
	public const uint32 WLAN_REASON_CODE_IHV_SECURITY_ONEX_MISSING = 524306;
	public const uint32 WLAN_REASON_CODE_PROFILE_SSID_INVALID = 524307;
	public const uint32 WLAN_REASON_CODE_TOO_MANY_SSID = 524308;
	public const uint32 WLAN_REASON_CODE_IHV_CONNECTIVITY_NOT_SUPPORTED = 524309;
	public const uint32 WLAN_REASON_CODE_BAD_MAX_NUMBER_OF_CLIENTS_FOR_AP = 524310;
	public const uint32 WLAN_REASON_CODE_INVALID_CHANNEL = 524311;
	public const uint32 WLAN_REASON_CODE_OPERATION_MODE_NOT_SUPPORTED = 524312;
	public const uint32 WLAN_REASON_CODE_AUTO_AP_PROFILE_NOT_ALLOWED = 524313;
	public const uint32 WLAN_REASON_CODE_AUTO_CONNECTION_NOT_ALLOWED = 524314;
	public const uint32 WLAN_REASON_CODE_HOTSPOT2_PROFILE_NOT_ALLOWED = 524315;
	public const uint32 WLAN_REASON_CODE_UNSUPPORTED_SECURITY_SET_BY_OS = 196609;
	public const uint32 WLAN_REASON_CODE_UNSUPPORTED_SECURITY_SET = 196610;
	public const uint32 WLAN_REASON_CODE_BSS_TYPE_UNMATCH = 196611;
	public const uint32 WLAN_REASON_CODE_PHY_TYPE_UNMATCH = 196612;
	public const uint32 WLAN_REASON_CODE_DATARATE_UNMATCH = 196613;
	public const uint32 WLAN_REASON_CODE_USER_CANCELLED = 229377;
	public const uint32 WLAN_REASON_CODE_ASSOCIATION_FAILURE = 229378;
	public const uint32 WLAN_REASON_CODE_ASSOCIATION_TIMEOUT = 229379;
	public const uint32 WLAN_REASON_CODE_PRE_SECURITY_FAILURE = 229380;
	public const uint32 WLAN_REASON_CODE_START_SECURITY_FAILURE = 229381;
	public const uint32 WLAN_REASON_CODE_SECURITY_FAILURE = 229382;
	public const uint32 WLAN_REASON_CODE_SECURITY_TIMEOUT = 229383;
	public const uint32 WLAN_REASON_CODE_ROAMING_FAILURE = 229384;
	public const uint32 WLAN_REASON_CODE_ROAMING_SECURITY_FAILURE = 229385;
	public const uint32 WLAN_REASON_CODE_ADHOC_SECURITY_FAILURE = 229386;
	public const uint32 WLAN_REASON_CODE_DRIVER_DISCONNECTED = 229387;
	public const uint32 WLAN_REASON_CODE_DRIVER_OPERATION_FAILURE = 229388;
	public const uint32 WLAN_REASON_CODE_IHV_NOT_AVAILABLE = 229389;
	public const uint32 WLAN_REASON_CODE_IHV_NOT_RESPONDING = 229390;
	public const uint32 WLAN_REASON_CODE_DISCONNECT_TIMEOUT = 229391;
	public const uint32 WLAN_REASON_CODE_INTERNAL_FAILURE = 229392;
	public const uint32 WLAN_REASON_CODE_UI_REQUEST_TIMEOUT = 229393;
	public const uint32 WLAN_REASON_CODE_TOO_MANY_SECURITY_ATTEMPTS = 229394;
	public const uint32 WLAN_REASON_CODE_AP_STARTING_FAILURE = 229395;
	public const uint32 WLAN_REASON_CODE_NO_VISIBLE_AP = 229396;
	public const uint32 WLAN_REASON_CODE_MSMSEC_MIN = 262144;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_KEY_INDEX = 262145;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_PSK_PRESENT = 262146;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_KEY_LENGTH = 262147;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_PSK_LENGTH = 262148;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_NO_AUTH_CIPHER_SPECIFIED = 262149;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_TOO_MANY_AUTH_CIPHER_SPECIFIED = 262150;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_DUPLICATE_AUTH_CIPHER = 262151;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_RAWDATA_INVALID = 262152;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_AUTH_CIPHER = 262153;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_ONEX_DISABLED = 262154;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_ONEX_ENABLED = 262155;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_PMKCACHE_MODE = 262156;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_PMKCACHE_SIZE = 262157;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_PMKCACHE_TTL = 262158;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_PREAUTH_MODE = 262159;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_PREAUTH_THROTTLE = 262160;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_PREAUTH_ONLY_ENABLED = 262161;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_NETWORK = 262162;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_NIC = 262163;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_PROFILE = 262164;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_DISCOVERY = 262165;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_PASSPHRASE_CHAR = 262166;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_KEYMATERIAL_CHAR = 262167;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_WRONG_KEYTYPE = 262168;
	public const uint32 WLAN_REASON_CODE_MSMSEC_MIXED_CELL = 262169;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_AUTH_TIMERS_INVALID = 262170;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_INVALID_GKEY_INTV = 262171;
	public const uint32 WLAN_REASON_CODE_MSMSEC_TRANSITION_NETWORK = 262172;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_KEY_UNMAPPED_CHAR = 262173;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_PROFILE_AUTH = 262174;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_PROFILE_CIPHER = 262175;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_SAFE_MODE = 262176;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_PROFILE_SAFE_MODE_NIC = 262177;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_PROFILE_SAFE_MODE_NW = 262178;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_UNSUPPORTED_AUTH = 262179;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PROFILE_UNSUPPORTED_CIPHER = 262180;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CAPABILITY_MFP_NW_NIC = 262181;
	public const uint32 WLAN_REASON_CODE_MSMSEC_UI_REQUEST_FAILURE = 294913;
	public const uint32 WLAN_REASON_CODE_MSMSEC_AUTH_START_TIMEOUT = 294914;
	public const uint32 WLAN_REASON_CODE_MSMSEC_AUTH_SUCCESS_TIMEOUT = 294915;
	public const uint32 WLAN_REASON_CODE_MSMSEC_KEY_START_TIMEOUT = 294916;
	public const uint32 WLAN_REASON_CODE_MSMSEC_KEY_SUCCESS_TIMEOUT = 294917;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M3_MISSING_KEY_DATA = 294918;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M3_MISSING_IE = 294919;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M3_MISSING_GRP_KEY = 294920;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PR_IE_MATCHING = 294921;
	public const uint32 WLAN_REASON_CODE_MSMSEC_SEC_IE_MATCHING = 294922;
	public const uint32 WLAN_REASON_CODE_MSMSEC_NO_PAIRWISE_KEY = 294923;
	public const uint32 WLAN_REASON_CODE_MSMSEC_G1_MISSING_KEY_DATA = 294924;
	public const uint32 WLAN_REASON_CODE_MSMSEC_G1_MISSING_GRP_KEY = 294925;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PEER_INDICATED_INSECURE = 294926;
	public const uint32 WLAN_REASON_CODE_MSMSEC_NO_AUTHENTICATOR = 294927;
	public const uint32 WLAN_REASON_CODE_MSMSEC_NIC_FAILURE = 294928;
	public const uint32 WLAN_REASON_CODE_MSMSEC_CANCELLED = 294929;
	public const uint32 WLAN_REASON_CODE_MSMSEC_KEY_FORMAT = 294930;
	public const uint32 WLAN_REASON_CODE_MSMSEC_DOWNGRADE_DETECTED = 294931;
	public const uint32 WLAN_REASON_CODE_MSMSEC_PSK_MISMATCH_SUSPECTED = 294932;
	public const uint32 WLAN_REASON_CODE_MSMSEC_FORCED_FAILURE = 294933;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M3_TOO_MANY_RSNIE = 294934;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M2_MISSING_KEY_DATA = 294935;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M2_MISSING_IE = 294936;
	public const uint32 WLAN_REASON_CODE_MSMSEC_AUTH_WCN_COMPLETED = 294937;
	public const uint32 WLAN_REASON_CODE_MSMSEC_M3_MISSING_MGMT_GRP_KEY = 294938;
	public const uint32 WLAN_REASON_CODE_MSMSEC_G1_MISSING_MGMT_GRP_KEY = 294939;
	public const uint32 WLAN_REASON_CODE_MSMSEC_MAX = 327679;
	public const uint32 WLAN_AVAILABLE_NETWORK_CONNECTED = 1;
	public const uint32 WLAN_AVAILABLE_NETWORK_HAS_PROFILE = 2;
	public const uint32 WLAN_AVAILABLE_NETWORK_CONSOLE_USER_PROFILE = 4;
	public const uint32 WLAN_AVAILABLE_NETWORK_INTERWORKING_SUPPORTED = 8;
	public const uint32 WLAN_AVAILABLE_NETWORK_HOTSPOT2_ENABLED = 16;
	public const uint32 WLAN_AVAILABLE_NETWORK_ANQP_SUPPORTED = 32;
	public const uint32 WLAN_AVAILABLE_NETWORK_HOTSPOT2_DOMAIN = 64;
	public const uint32 WLAN_AVAILABLE_NETWORK_HOTSPOT2_ROAMING = 128;
	public const uint32 WLAN_AVAILABLE_NETWORK_AUTO_CONNECT_FAILED = 256;
	public const uint32 WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES = 1;
	public const uint32 WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_MANUAL_HIDDEN_PROFILES = 2;
	public const uint32 WLAN_MAX_PHY_TYPE_NUMBER = 8;
	public const uint32 WLAN_MAX_PHY_INDEX = 64;
	public const uint32 WLAN_CONNECTION_HIDDEN_NETWORK = 1;
	public const uint32 WLAN_CONNECTION_ADHOC_JOIN_ONLY = 2;
	public const uint32 WLAN_CONNECTION_IGNORE_PRIVACY_BIT = 4;
	public const uint32 WLAN_CONNECTION_EAPOL_PASSTHROUGH = 8;
	public const uint32 WLAN_CONNECTION_PERSIST_DISCOVERY_PROFILE = 16;
	public const uint32 WLAN_CONNECTION_PERSIST_DISCOVERY_PROFILE_CONNECTION_MODE_AUTO = 32;
	public const uint32 WLAN_CONNECTION_PERSIST_DISCOVERY_PROFILE_OVERWRITE_EXISTING = 64;
	public const uint32 WLAN_NOTIFICATION_SOURCE_NONE = 0;
	public const uint32 WLAN_NOTIFICATION_SOURCE_ALL = 65535;
	public const uint32 WLAN_NOTIFICATION_SOURCE_ACM = 8;
	public const uint32 WLAN_NOTIFICATION_SOURCE_MSM = 16;
	public const uint32 WLAN_NOTIFICATION_SOURCE_SECURITY = 32;
	public const uint32 WLAN_NOTIFICATION_SOURCE_IHV = 64;
	public const uint32 WLAN_NOTIFICATION_SOURCE_HNWK = 128;
	public const uint32 WLAN_NOTIFICATION_SOURCE_ONEX = 4;
	public const uint32 WLAN_NOTIFICATION_SOURCE_DEVICE_SERVICE = 2048;
	public const uint32 WFD_API_VERSION_1_0 = 1;
	public const uint32 WFD_API_VERSION = 1;
	public const uint32 WLAN_UI_API_VERSION = 1;
	public const uint32 WLAN_UI_API_INITIAL_VERSION = 1;
	public const Guid GUID_DEVINTERFACE_WIFIDIRECT_DEVICE = .(0x439b20af, 0x8955, 0x405b, 0x99, 0xf0, 0xa6, 0x2a, 0xf0, 0xc6, 0x8d, 0x43);
	public const Guid GUID_AEPSERVICE_WIFIDIRECT_DEVICE = .(0xcc29827c, 0x9caf, 0x4928, 0x99, 0xa9, 0x18, 0xf7, 0xc2, 0x38, 0x13, 0x89);
	public const Guid GUID_DEVINTERFACE_ASP_INFRA_DEVICE = .(0xff823995, 0x7a72, 0x4c80, 0x87, 0x57, 0xc6, 0x7e, 0xe1, 0x3d, 0x1a, 0x49);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_DeviceAddress = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 1);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_InterfaceAddress = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 2);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_InterfaceGuid = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 3);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_GroupId = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 4);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_IsConnected = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 5);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_IsVisible = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 6);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_IsLegacyDevice = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 7);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_MiracastVersion = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 8);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_IsMiracastLCPSupported = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 9);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_Services = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 10);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_SupportedChannelList = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 11);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_InformationElements = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 12);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_DeviceAddressCopy = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 13);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_IsRecentlyAssociated = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 14);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_Service_Aeps = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 15);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_NoMiracastAutoProject = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 16);
	public const DEVPROPKEY DEVPKEY_InfraCast_Supported = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 17);
	public const DEVPROPKEY DEVPKEY_InfraCast_StreamSecuritySupported = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 18);
	public const DEVPROPKEY DEVPKEY_InfraCast_AccessPointBssid = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 19);
	public const DEVPROPKEY DEVPKEY_InfraCast_SinkHostName = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 20);
	public const DEVPROPKEY DEVPKEY_InfraCast_ChallengeAep = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 21);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_IsDMGCapable = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 22);
	public const DEVPROPKEY DEVPKEY_InfraCast_DevnodeAep = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 23);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_FoundWsbService = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 24);
	public const DEVPROPKEY DEVPKEY_InfraCast_HostName_ResolutionMode = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 25);
	public const DEVPROPKEY DEVPKEY_InfraCast_SinkIpAddress = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 26);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_TransientAssociation = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 27);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_LinkQuality = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 28);
	public const DEVPROPKEY DEVPKEY_InfraCast_PinSupported = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 29);
	public const DEVPROPKEY DEVPKEY_InfraCast_RtspTcpConnectionParametersSupported = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 30);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_Miracast_SessionMgmtControlPort = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 31);
	public const DEVPROPKEY DEVPKEY_WiFiDirect_RtspTcpConnectionParametersSupported = .(.(0x1506935d, 0xe3e7, 0x450f, 0x86, 0x37, 0x82, 0x23, 0x3e, 0xbe, 0x5f, 0x6e), 32);
	public const DEVPROPKEY DEVPKEY_WiFiDirectServices_ServiceAddress = .(.(0x31b37743, 0x7c5e, 0x4005, 0x93, 0xe6, 0xe9, 0x53, 0xf9, 0x2b, 0x82, 0xe9), 2);
	public const DEVPROPKEY DEVPKEY_WiFiDirectServices_ServiceName = .(.(0x31b37743, 0x7c5e, 0x4005, 0x93, 0xe6, 0xe9, 0x53, 0xf9, 0x2b, 0x82, 0xe9), 3);
	public const DEVPROPKEY DEVPKEY_WiFiDirectServices_ServiceInformation = .(.(0x31b37743, 0x7c5e, 0x4005, 0x93, 0xe6, 0xe9, 0x53, 0xf9, 0x2b, 0x82, 0xe9), 4);
	public const DEVPROPKEY DEVPKEY_WiFiDirectServices_AdvertisementId = .(.(0x31b37743, 0x7c5e, 0x4005, 0x93, 0xe6, 0xe9, 0x53, 0xf9, 0x2b, 0x82, 0xe9), 5);
	public const DEVPROPKEY DEVPKEY_WiFiDirectServices_ServiceConfigMethods = .(.(0x31b37743, 0x7c5e, 0x4005, 0x93, 0xe6, 0xe9, 0x53, 0xf9, 0x2b, 0x82, 0xe9), 6);
	public const DEVPROPKEY DEVPKEY_WiFiDirectServices_RequestServiceInformation = .(.(0x31b37743, 0x7c5e, 0x4005, 0x93, 0xe6, 0xe9, 0x53, 0xf9, 0x2b, 0x82, 0xe9), 7);
	public const DEVPROPKEY DEVPKEY_WiFi_InterfaceGuid = .(.(0xef1167eb, 0xcbfc, 0x4341, 0xa5, 0x68, 0xa7, 0xc9, 0x1a, 0x68, 0x98, 0x2c), 2);
	public const uint32 DOT11EXT_PSK_MAX_LENGTH = 64;
	public const uint32 WDIAG_IHV_WLAN_ID_FLAG_SECURITY_ENABLED = 1;
	public const String IHV_VERSION_FUNCTION_NAME = "Dot11ExtIhvGetVersionInfo";
	public const String IHV_INIT_FUNCTION_NAME = "Dot11ExtIhvInitService";
	public const String IHV_INIT_VS_FUNCTION_NAME = "Dot11ExtIhvInitVirtualStation";
	public const uint32 MS_MAX_PROFILE_NAME_LENGTH = 256;
	public const uint32 MS_PROFILE_GROUP_POLICY = 1;
	public const uint32 MS_PROFILE_USER = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WLAN_SET_EAPHOST_FLAGS : uint32
{
	WLAN_SET_EAPHOST_DATA_ALL_USERS = 1,
}


[AllowDuplicates]
public enum WLAN_CONNECTION_NOTIFICATION_FLAGS : uint32
{
	WLAN_CONNECTION_NOTIFICATION_ADHOC_NETWORK_FORMED = 1,
	WLAN_CONNECTION_NOTIFICATION_CONSOLE_USER_PROFILE = 4,
}


[AllowDuplicates]
public enum DOT11_BSS_TYPE : int32
{
	dot11_BSS_type_infrastructure = 1,
	dot11_BSS_type_independent = 2,
	dot11_BSS_type_any = 3,
}


[AllowDuplicates]
public enum DOT11_AUTH_ALGORITHM : int32
{
	DOT11_AUTH_ALGO_80211_OPEN = 1,
	DOT11_AUTH_ALGO_80211_SHARED_KEY = 2,
	DOT11_AUTH_ALGO_WPA = 3,
	DOT11_AUTH_ALGO_WPA_PSK = 4,
	DOT11_AUTH_ALGO_WPA_NONE = 5,
	DOT11_AUTH_ALGO_RSNA = 6,
	DOT11_AUTH_ALGO_RSNA_PSK = 7,
	DOT11_AUTH_ALGO_WPA3 = 8,
	DOT11_AUTH_ALGO_WPA3_ENT_192 = 8,
	DOT11_AUTH_ALGO_WPA3_SAE = 9,
	DOT11_AUTH_ALGO_OWE = 10,
	DOT11_AUTH_ALGO_WPA3_ENT = 11,
	DOT11_AUTH_ALGO_IHV_START = -2147483648,
	DOT11_AUTH_ALGO_IHV_END = -1,
}


[AllowDuplicates]
public enum DOT11_CIPHER_ALGORITHM : int32
{
	DOT11_CIPHER_ALGO_NONE = 0,
	DOT11_CIPHER_ALGO_WEP40 = 1,
	DOT11_CIPHER_ALGO_TKIP = 2,
	DOT11_CIPHER_ALGO_CCMP = 4,
	DOT11_CIPHER_ALGO_WEP104 = 5,
	DOT11_CIPHER_ALGO_BIP = 6,
	DOT11_CIPHER_ALGO_GCMP = 8,
	DOT11_CIPHER_ALGO_GCMP_256 = 9,
	DOT11_CIPHER_ALGO_CCMP_256 = 10,
	DOT11_CIPHER_ALGO_BIP_GMAC_128 = 11,
	DOT11_CIPHER_ALGO_BIP_GMAC_256 = 12,
	DOT11_CIPHER_ALGO_BIP_CMAC_256 = 13,
	DOT11_CIPHER_ALGO_WPA_USE_GROUP = 256,
	DOT11_CIPHER_ALGO_RSN_USE_GROUP = 256,
	DOT11_CIPHER_ALGO_WEP = 257,
	DOT11_CIPHER_ALGO_IHV_START = -2147483648,
	DOT11_CIPHER_ALGO_IHV_END = -1,
}


[AllowDuplicates]
public enum DOT11_PHY_TYPE : int32
{
	dot11_phy_type_unknown = 0,
	dot11_phy_type_any = 0,
	dot11_phy_type_fhss = 1,
	dot11_phy_type_dsss = 2,
	dot11_phy_type_irbaseband = 3,
	dot11_phy_type_ofdm = 4,
	dot11_phy_type_hrdsss = 5,
	dot11_phy_type_erp = 6,
	dot11_phy_type_ht = 7,
	dot11_phy_type_vht = 8,
	dot11_phy_type_dmg = 9,
	dot11_phy_type_he = 10,
	dot11_phy_type_IHV_start = -2147483648,
	dot11_phy_type_IHV_end = -1,
}


[AllowDuplicates]
public enum DOT11_OFFLOAD_TYPE : int32
{
	dot11_offload_type_wep = 1,
	dot11_offload_type_auth = 2,
}


[AllowDuplicates]
public enum DOT11_KEY_DIRECTION : int32
{
	dot11_key_direction_both = 1,
	dot11_key_direction_inbound = 2,
	dot11_key_direction_outbound = 3,
}


[AllowDuplicates]
public enum DOT11_SCAN_TYPE : int32
{
	dot11_scan_type_active = 1,
	dot11_scan_type_passive = 2,
	dot11_scan_type_auto = 3,
	dot11_scan_type_forced = -2147483648,
}


[AllowDuplicates]
public enum CH_DESCRIPTION_TYPE : int32
{
	ch_description_type_logical = 1,
	ch_description_type_center_frequency = 2,
	ch_description_type_phy_specific = 3,
}


[AllowDuplicates]
public enum DOT11_UPDATE_IE_OP : int32
{
	dot11_update_ie_op_create_replace = 1,
	dot11_update_ie_op_delete = 2,
}


[AllowDuplicates]
public enum DOT11_RESET_TYPE : int32
{
	dot11_reset_type_phy = 1,
	dot11_reset_type_mac = 2,
	dot11_reset_type_phy_and_mac = 3,
}


[AllowDuplicates]
public enum DOT11_POWER_MODE : int32
{
	dot11_power_mode_unknown = 0,
	dot11_power_mode_active = 1,
	dot11_power_mode_powersave = 2,
}


[AllowDuplicates]
public enum DOT11_TEMP_TYPE : int32
{
	dot11_temp_type_unknown = 0,
	dot11_temp_type_1 = 1,
	dot11_temp_type_2 = 2,
}


[AllowDuplicates]
public enum DOT11_DIVERSITY_SUPPORT : int32
{
	dot11_diversity_support_unknown = 0,
	dot11_diversity_support_fixedlist = 1,
	dot11_diversity_support_notsupported = 2,
	dot11_diversity_support_dynamic = 3,
}


[AllowDuplicates]
public enum DOT11_HOP_ALGO_ADOPTED : int32
{
	dot11_hop_algo_current = 0,
	dot11_hop_algo_hop_index = 1,
	dot11_hop_algo_hcc = 2,
}


[AllowDuplicates]
public enum DOT11_AC_PARAM : int32
{
	dot11_AC_param_BE = 0,
	dot11_AC_param_BK = 1,
	dot11_AC_param_VI = 2,
	dot11_AC_param_VO = 3,
	dot11_AC_param_max = 4,
}


[AllowDuplicates]
public enum DOT11_DIRECTION : int32
{
	DOT11_DIR_INBOUND = 1,
	DOT11_DIR_OUTBOUND = 2,
	DOT11_DIR_BOTH = 3,
}


[AllowDuplicates]
public enum DOT11_ASSOCIATION_STATE : int32
{
	dot11_assoc_state_zero = 0,
	dot11_assoc_state_unauth_unassoc = 1,
	dot11_assoc_state_auth_unassoc = 2,
	dot11_assoc_state_auth_assoc = 3,
}


[AllowDuplicates]
public enum DOT11_DS_INFO : int32
{
	DOT11_DS_CHANGED = 0,
	DOT11_DS_UNCHANGED = 1,
	DOT11_DS_UNKNOWN = 2,
}


[AllowDuplicates]
public enum DOT11_WPS_CONFIG_METHOD : int32
{
	DOT11_WPS_CONFIG_METHOD_NULL = 0,
	DOT11_WPS_CONFIG_METHOD_DISPLAY = 8,
	DOT11_WPS_CONFIG_METHOD_NFC_TAG = 32,
	DOT11_WPS_CONFIG_METHOD_NFC_INTERFACE = 64,
	DOT11_WPS_CONFIG_METHOD_PUSHBUTTON = 128,
	DOT11_WPS_CONFIG_METHOD_KEYPAD = 256,
	DOT11_WPS_CONFIG_METHOD_WFDS_DEFAULT = 4096,
}


[AllowDuplicates]
public enum DOT11_WPS_DEVICE_PASSWORD_ID : int32
{
	DOT11_WPS_PASSWORD_ID_DEFAULT = 0,
	DOT11_WPS_PASSWORD_ID_USER_SPECIFIED = 1,
	DOT11_WPS_PASSWORD_ID_MACHINE_SPECIFIED = 2,
	DOT11_WPS_PASSWORD_ID_REKEY = 3,
	DOT11_WPS_PASSWORD_ID_PUSHBUTTON = 4,
	DOT11_WPS_PASSWORD_ID_REGISTRAR_SPECIFIED = 5,
	DOT11_WPS_PASSWORD_ID_NFC_CONNECTION_HANDOVER = 7,
	DOT11_WPS_PASSWORD_ID_WFD_SERVICES = 8,
	DOT11_WPS_PASSWORD_ID_OOB_RANGE_MIN = 16,
	DOT11_WPS_PASSWORD_ID_OOB_RANGE_MAX = 65535,
}


[AllowDuplicates]
public enum DOT11_ANQP_QUERY_RESULT : int32
{
	dot11_ANQP_query_result_success = 0,
	dot11_ANQP_query_result_failure = 1,
	dot11_ANQP_query_result_timed_out = 2,
	dot11_ANQP_query_result_resources = 3,
	dot11_ANQP_query_result_advertisement_protocol_not_supported_on_remote = 4,
	dot11_ANQP_query_result_gas_protocol_failure = 5,
	dot11_ANQP_query_result_advertisement_server_not_responding = 6,
	dot11_ANQP_query_result_access_issues = 7,
}


[AllowDuplicates]
public enum DOT11_WFD_DISCOVER_TYPE : int32
{
	dot11_wfd_discover_type_scan_only = 1,
	dot11_wfd_discover_type_find_only = 2,
	dot11_wfd_discover_type_auto = 3,
	dot11_wfd_discover_type_scan_social_channels = 4,
	dot11_wfd_discover_type_forced = -2147483648,
}


[AllowDuplicates]
public enum DOT11_WFD_SCAN_TYPE : int32
{
	dot11_wfd_scan_type_active = 1,
	dot11_wfd_scan_type_passive = 2,
	dot11_wfd_scan_type_auto = 3,
}


[AllowDuplicates]
public enum DOT11_POWER_MODE_REASON : int32
{
	dot11_power_mode_reason_no_change = 0,
	dot11_power_mode_reason_noncompliant_AP = 1,
	dot11_power_mode_reason_legacy_WFD_device = 2,
	dot11_power_mode_reason_compliant_AP = 3,
	dot11_power_mode_reason_compliant_WFD_device = 4,
	dot11_power_mode_reason_others = 5,
}


[AllowDuplicates]
public enum DOT11_MANUFACTURING_TEST_TYPE : int32
{
	dot11_manufacturing_test_unknown = 0,
	dot11_manufacturing_test_self_start = 1,
	dot11_manufacturing_test_self_query_result = 2,
	dot11_manufacturing_test_rx = 3,
	dot11_manufacturing_test_tx = 4,
	dot11_manufacturing_test_query_adc = 5,
	dot11_manufacturing_test_set_data = 6,
	dot11_manufacturing_test_query_data = 7,
	dot11_manufacturing_test_sleep = 8,
	dot11_manufacturing_test_awake = 9,
	dot11_manufacturing_test_IHV_start = -2147483648,
	dot11_manufacturing_test_IHV_end = -1,
}


[AllowDuplicates]
public enum DOT11_MANUFACTURING_SELF_TEST_TYPE : int32
{
	DOT11_MANUFACTURING_SELF_TEST_TYPE_INTERFACE = 1,
	DOT11_MANUFACTURING_SELF_TEST_TYPE_RF_INTERFACE = 2,
	DOT11_MANUFACTURING_SELF_TEST_TYPE_BT_COEXISTENCE = 3,
}


[AllowDuplicates]
public enum DOT11_BAND : int32
{
	dot11_band_2p4g = 1,
	dot11_band_4p9g = 2,
	dot11_band_5g = 3,
}


[AllowDuplicates]
public enum DOT11_MANUFACTURING_CALLBACK_TYPE : int32
{
	dot11_manufacturing_callback_unknown = 0,
	dot11_manufacturing_callback_self_test_complete = 1,
	dot11_manufacturing_callback_sleep_complete = 2,
	dot11_manufacturing_callback_IHV_start = -2147483648,
	dot11_manufacturing_callback_IHV_end = -1,
}


[AllowDuplicates]
public enum WLAN_CONNECTION_MODE : int32
{
	wlan_connection_mode_profile = 0,
	wlan_connection_mode_temporary_profile = 1,
	wlan_connection_mode_discovery_secure = 2,
	wlan_connection_mode_discovery_unsecure = 3,
	wlan_connection_mode_auto = 4,
	wlan_connection_mode_invalid = 5,
}


[AllowDuplicates]
public enum WLAN_INTERFACE_STATE : int32
{
	wlan_interface_state_not_ready = 0,
	wlan_interface_state_connected = 1,
	wlan_interface_state_ad_hoc_network_formed = 2,
	wlan_interface_state_disconnecting = 3,
	wlan_interface_state_disconnected = 4,
	wlan_interface_state_associating = 5,
	wlan_interface_state_discovering = 6,
	wlan_interface_state_authenticating = 7,
}


[AllowDuplicates]
public enum WLAN_ADHOC_NETWORK_STATE : int32
{
	wlan_adhoc_network_state_formed = 0,
	wlan_adhoc_network_state_connected = 1,
}


[AllowDuplicates]
public enum DOT11_RADIO_STATE : int32
{
	dot11_radio_state_unknown = 0,
	dot11_radio_state_on = 1,
	dot11_radio_state_off = 2,
}


[AllowDuplicates]
public enum WLAN_OPERATIONAL_STATE : int32
{
	wlan_operational_state_unknown = 0,
	wlan_operational_state_off = 1,
	wlan_operational_state_on = 2,
	wlan_operational_state_going_off = 3,
	wlan_operational_state_going_on = 4,
}


[AllowDuplicates]
public enum WLAN_INTERFACE_TYPE : int32
{
	wlan_interface_type_emulated_802_11 = 0,
	wlan_interface_type_native_802_11 = 1,
	wlan_interface_type_invalid = 2,
}


[AllowDuplicates]
public enum WLAN_POWER_SETTING : int32
{
	wlan_power_setting_no_saving = 0,
	wlan_power_setting_low_saving = 1,
	wlan_power_setting_medium_saving = 2,
	wlan_power_setting_maximum_saving = 3,
	wlan_power_setting_invalid = 4,
}


[AllowDuplicates]
public enum WLAN_NOTIFICATION_ACM : int32
{
	wlan_notification_acm_start = 0,
	wlan_notification_acm_autoconf_enabled = 1,
	wlan_notification_acm_autoconf_disabled = 2,
	wlan_notification_acm_background_scan_enabled = 3,
	wlan_notification_acm_background_scan_disabled = 4,
	wlan_notification_acm_bss_type_change = 5,
	wlan_notification_acm_power_setting_change = 6,
	wlan_notification_acm_scan_complete = 7,
	wlan_notification_acm_scan_fail = 8,
	wlan_notification_acm_connection_start = 9,
	wlan_notification_acm_connection_complete = 10,
	wlan_notification_acm_connection_attempt_fail = 11,
	wlan_notification_acm_filter_list_change = 12,
	wlan_notification_acm_interface_arrival = 13,
	wlan_notification_acm_interface_removal = 14,
	wlan_notification_acm_profile_change = 15,
	wlan_notification_acm_profile_name_change = 16,
	wlan_notification_acm_profiles_exhausted = 17,
	wlan_notification_acm_network_not_available = 18,
	wlan_notification_acm_network_available = 19,
	wlan_notification_acm_disconnecting = 20,
	wlan_notification_acm_disconnected = 21,
	wlan_notification_acm_adhoc_network_state_change = 22,
	wlan_notification_acm_profile_unblocked = 23,
	wlan_notification_acm_screen_power_change = 24,
	wlan_notification_acm_profile_blocked = 25,
	wlan_notification_acm_scan_list_refresh = 26,
	wlan_notification_acm_operational_state_change = 27,
	wlan_notification_acm_end = 28,
}


[AllowDuplicates]
public enum WLAN_NOTIFICATION_MSM : int32
{
	wlan_notification_msm_start = 0,
	wlan_notification_msm_associating = 1,
	wlan_notification_msm_associated = 2,
	wlan_notification_msm_authenticating = 3,
	wlan_notification_msm_connected = 4,
	wlan_notification_msm_roaming_start = 5,
	wlan_notification_msm_roaming_end = 6,
	wlan_notification_msm_radio_state_change = 7,
	wlan_notification_msm_signal_quality_change = 8,
	wlan_notification_msm_disassociating = 9,
	wlan_notification_msm_disconnected = 10,
	wlan_notification_msm_peer_join = 11,
	wlan_notification_msm_peer_leave = 12,
	wlan_notification_msm_adapter_removal = 13,
	wlan_notification_msm_adapter_operation_mode_change = 14,
	wlan_notification_msm_link_degraded = 15,
	wlan_notification_msm_link_improved = 16,
	wlan_notification_msm_end = 17,
}


[AllowDuplicates]
public enum WLAN_NOTIFICATION_SECURITY : int32
{
	wlan_notification_security_start = 0,
	wlan_notification_security_end = 1,
}


[AllowDuplicates]
public enum WLAN_OPCODE_VALUE_TYPE : int32
{
	wlan_opcode_value_type_query_only = 0,
	wlan_opcode_value_type_set_by_group_policy = 1,
	wlan_opcode_value_type_set_by_user = 2,
	wlan_opcode_value_type_invalid = 3,
}


[AllowDuplicates]
public enum WLAN_INTF_OPCODE : int32
{
	wlan_intf_opcode_autoconf_start = 0,
	wlan_intf_opcode_autoconf_enabled = 1,
	wlan_intf_opcode_background_scan_enabled = 2,
	wlan_intf_opcode_media_streaming_mode = 3,
	wlan_intf_opcode_radio_state = 4,
	wlan_intf_opcode_bss_type = 5,
	wlan_intf_opcode_interface_state = 6,
	wlan_intf_opcode_current_connection = 7,
	wlan_intf_opcode_channel_number = 8,
	wlan_intf_opcode_supported_infrastructure_auth_cipher_pairs = 9,
	wlan_intf_opcode_supported_adhoc_auth_cipher_pairs = 10,
	wlan_intf_opcode_supported_country_or_region_string_list = 11,
	wlan_intf_opcode_current_operation_mode = 12,
	wlan_intf_opcode_supported_safe_mode = 13,
	wlan_intf_opcode_certified_safe_mode = 14,
	wlan_intf_opcode_hosted_network_capable = 15,
	wlan_intf_opcode_management_frame_protection_capable = 16,
	wlan_intf_opcode_secondary_sta_interfaces = 17,
	wlan_intf_opcode_secondary_sta_synchronized_connections = 18,
	wlan_intf_opcode_autoconf_end = 268435455,
	wlan_intf_opcode_msm_start = 268435712,
	wlan_intf_opcode_statistics = 268435713,
	wlan_intf_opcode_rssi = 268435714,
	wlan_intf_opcode_msm_end = 536870911,
	wlan_intf_opcode_security_start = 536936448,
	wlan_intf_opcode_security_end = 805306367,
	wlan_intf_opcode_ihv_start = 805306368,
	wlan_intf_opcode_ihv_end = 1073741823,
}


[AllowDuplicates]
public enum WLAN_AUTOCONF_OPCODE : int32
{
	wlan_autoconf_opcode_start = 0,
	wlan_autoconf_opcode_show_denied_networks = 1,
	wlan_autoconf_opcode_power_setting = 2,
	wlan_autoconf_opcode_only_use_gp_profiles_for_allowed_networks = 3,
	wlan_autoconf_opcode_allow_explicit_creds = 4,
	wlan_autoconf_opcode_block_period = 5,
	wlan_autoconf_opcode_allow_virtual_station_extensibility = 6,
	wlan_autoconf_opcode_end = 7,
}


[AllowDuplicates]
public enum WLAN_IHV_CONTROL_TYPE : int32
{
	wlan_ihv_control_type_service = 0,
	wlan_ihv_control_type_driver = 1,
}


[AllowDuplicates]
public enum WLAN_FILTER_LIST_TYPE : int32
{
	wlan_filter_list_type_gp_permit = 0,
	wlan_filter_list_type_gp_deny = 1,
	wlan_filter_list_type_user_permit = 2,
	wlan_filter_list_type_user_deny = 3,
}


[AllowDuplicates]
public enum WLAN_SECURABLE_OBJECT : int32
{
	wlan_secure_permit_list = 0,
	wlan_secure_deny_list = 1,
	wlan_secure_ac_enabled = 2,
	wlan_secure_bc_scan_enabled = 3,
	wlan_secure_bss_type = 4,
	wlan_secure_show_denied = 5,
	wlan_secure_interface_properties = 6,
	wlan_secure_ihv_control = 7,
	wlan_secure_all_user_profiles_order = 8,
	wlan_secure_add_new_all_user_profiles = 9,
	wlan_secure_add_new_per_user_profiles = 10,
	wlan_secure_media_streaming_mode_enabled = 11,
	wlan_secure_current_operation_mode = 12,
	wlan_secure_get_plaintext_key = 13,
	wlan_secure_hosted_network_elevated_access = 14,
	wlan_secure_virtual_station_extensibility = 15,
	wlan_secure_wfd_elevated_access = 16,
	WLAN_SECURABLE_OBJECT_COUNT = 17,
}


[AllowDuplicates]
public enum WFD_ROLE_TYPE : int32
{
	WFD_ROLE_TYPE_NONE = 0,
	WFD_ROLE_TYPE_DEVICE = 1,
	WFD_ROLE_TYPE_GROUP_OWNER = 2,
	WFD_ROLE_TYPE_CLIENT = 4,
	WFD_ROLE_TYPE_MAX = 5,
}


[AllowDuplicates]
public enum WL_DISPLAY_PAGES : int32
{
	WLConnectionPage = 0,
	WLSecurityPage = 1,
	WLAdvPage = 2,
}


[AllowDuplicates]
public enum WLAN_HOSTED_NETWORK_STATE : int32
{
	wlan_hosted_network_unavailable = 0,
	wlan_hosted_network_idle = 1,
	wlan_hosted_network_active = 2,
}


[AllowDuplicates]
public enum WLAN_HOSTED_NETWORK_REASON : int32
{
	wlan_hosted_network_reason_success = 0,
	wlan_hosted_network_reason_unspecified = 1,
	wlan_hosted_network_reason_bad_parameters = 2,
	wlan_hosted_network_reason_service_shutting_down = 3,
	wlan_hosted_network_reason_insufficient_resources = 4,
	wlan_hosted_network_reason_elevation_required = 5,
	wlan_hosted_network_reason_read_only = 6,
	wlan_hosted_network_reason_persistence_failed = 7,
	wlan_hosted_network_reason_crypt_error = 8,
	wlan_hosted_network_reason_impersonation = 9,
	wlan_hosted_network_reason_stop_before_start = 10,
	wlan_hosted_network_reason_interface_available = 11,
	wlan_hosted_network_reason_interface_unavailable = 12,
	wlan_hosted_network_reason_miniport_stopped = 13,
	wlan_hosted_network_reason_miniport_started = 14,
	wlan_hosted_network_reason_incompatible_connection_started = 15,
	wlan_hosted_network_reason_incompatible_connection_stopped = 16,
	wlan_hosted_network_reason_user_action = 17,
	wlan_hosted_network_reason_client_abort = 18,
	wlan_hosted_network_reason_ap_start_failed = 19,
	wlan_hosted_network_reason_peer_arrived = 20,
	wlan_hosted_network_reason_peer_departed = 21,
	wlan_hosted_network_reason_peer_timeout = 22,
	wlan_hosted_network_reason_gp_denied = 23,
	wlan_hosted_network_reason_service_unavailable = 24,
	wlan_hosted_network_reason_device_change = 25,
	wlan_hosted_network_reason_properties_change = 26,
	wlan_hosted_network_reason_virtual_station_blocking_use = 27,
	wlan_hosted_network_reason_service_available_on_virtual_station = 28,
}


[AllowDuplicates]
public enum WLAN_HOSTED_NETWORK_PEER_AUTH_STATE : int32
{
	wlan_hosted_network_peer_state_invalid = 0,
	wlan_hosted_network_peer_state_authenticated = 1,
}


[AllowDuplicates]
public enum WLAN_HOSTED_NETWORK_NOTIFICATION_CODE : int32
{
	wlan_hosted_network_state_change = 4096,
	wlan_hosted_network_peer_state_change = 4097,
	wlan_hosted_network_radio_state_change = 4098,
}


[AllowDuplicates]
public enum WLAN_HOSTED_NETWORK_OPCODE : int32
{
	wlan_hosted_network_opcode_connection_settings = 0,
	wlan_hosted_network_opcode_security_settings = 1,
	wlan_hosted_network_opcode_station_profile = 2,
	wlan_hosted_network_opcode_enable = 3,
}


[AllowDuplicates]
public enum ONEX_AUTH_IDENTITY : int32
{
	OneXAuthIdentityNone = 0,
	OneXAuthIdentityMachine = 1,
	OneXAuthIdentityUser = 2,
	OneXAuthIdentityExplicitUser = 3,
	OneXAuthIdentityGuest = 4,
	OneXAuthIdentityInvalid = 5,
}


[AllowDuplicates]
public enum ONEX_AUTH_STATUS : int32
{
	OneXAuthNotStarted = 0,
	OneXAuthInProgress = 1,
	OneXAuthNoAuthenticatorFound = 2,
	OneXAuthSuccess = 3,
	OneXAuthFailure = 4,
	OneXAuthInvalid = 5,
}


[AllowDuplicates]
public enum ONEX_REASON_CODE : int32
{
	ONEX_REASON_CODE_SUCCESS = 0,
	ONEX_REASON_START = 327680,
	ONEX_UNABLE_TO_IDENTIFY_USER = 327681,
	ONEX_IDENTITY_NOT_FOUND = 327682,
	ONEX_UI_DISABLED = 327683,
	ONEX_UI_FAILURE = 327684,
	ONEX_EAP_FAILURE_RECEIVED = 327685,
	ONEX_AUTHENTICATOR_NO_LONGER_PRESENT = 327686,
	ONEX_NO_RESPONSE_TO_IDENTITY = 327687,
	ONEX_PROFILE_VERSION_NOT_SUPPORTED = 327688,
	ONEX_PROFILE_INVALID_LENGTH = 327689,
	ONEX_PROFILE_DISALLOWED_EAP_TYPE = 327690,
	ONEX_PROFILE_INVALID_EAP_TYPE_OR_FLAG = 327691,
	ONEX_PROFILE_INVALID_ONEX_FLAGS = 327692,
	ONEX_PROFILE_INVALID_TIMER_VALUE = 327693,
	ONEX_PROFILE_INVALID_SUPPLICANT_MODE = 327694,
	ONEX_PROFILE_INVALID_AUTH_MODE = 327695,
	ONEX_PROFILE_INVALID_EAP_CONNECTION_PROPERTIES = 327696,
	ONEX_UI_CANCELLED = 327697,
	ONEX_PROFILE_INVALID_EXPLICIT_CREDENTIALS = 327698,
	ONEX_PROFILE_EXPIRED_EXPLICIT_CREDENTIALS = 327699,
	ONEX_UI_NOT_PERMITTED = 327700,
}


[AllowDuplicates]
public enum ONEX_NOTIFICATION_TYPE : int32
{
	OneXPublicNotificationBase = 0,
	OneXNotificationTypeResultUpdate = 1,
	OneXNotificationTypeAuthRestarted = 2,
	OneXNotificationTypeEventInvalid = 3,
	OneXNumNotifications = 3,
}


[AllowDuplicates]
public enum ONEX_AUTH_RESTART_REASON : int32
{
	OneXRestartReasonPeerInitiated = 0,
	OneXRestartReasonMsmInitiated = 1,
	OneXRestartReasonOneXHeldStateTimeout = 2,
	OneXRestartReasonOneXAuthTimeout = 3,
	OneXRestartReasonOneXConfigurationChanged = 4,
	OneXRestartReasonOneXUserChanged = 5,
	OneXRestartReasonQuarantineStateChanged = 6,
	OneXRestartReasonAltCredsTrial = 7,
	OneXRestartReasonInvalid = 8,
}


[AllowDuplicates]
public enum ONEX_EAP_METHOD_BACKEND_SUPPORT : int32
{
	OneXEapMethodBackendSupportUnknown = 0,
	OneXEapMethodBackendSupported = 1,
	OneXEapMethodBackendUnsupported = 2,
}


[AllowDuplicates]
public enum DOT11_ADHOC_CIPHER_ALGORITHM : int32
{
	DOT11_ADHOC_CIPHER_ALGO_INVALID = -1,
	DOT11_ADHOC_CIPHER_ALGO_NONE = 0,
	DOT11_ADHOC_CIPHER_ALGO_CCMP = 4,
	DOT11_ADHOC_CIPHER_ALGO_WEP = 257,
}


[AllowDuplicates]
public enum DOT11_ADHOC_AUTH_ALGORITHM : int32
{
	DOT11_ADHOC_AUTH_ALGO_INVALID = -1,
	DOT11_ADHOC_AUTH_ALGO_80211_OPEN = 1,
	DOT11_ADHOC_AUTH_ALGO_RSNA_PSK = 7,
}


[AllowDuplicates]
public enum DOT11_ADHOC_NETWORK_CONNECTION_STATUS : int32
{
	DOT11_ADHOC_NETWORK_CONNECTION_STATUS_INVALID = 0,
	DOT11_ADHOC_NETWORK_CONNECTION_STATUS_DISCONNECTED = 11,
	DOT11_ADHOC_NETWORK_CONNECTION_STATUS_CONNECTING = 12,
	DOT11_ADHOC_NETWORK_CONNECTION_STATUS_CONNECTED = 13,
	DOT11_ADHOC_NETWORK_CONNECTION_STATUS_FORMED = 14,
}


[AllowDuplicates]
public enum DOT11_ADHOC_CONNECT_FAIL_REASON : int32
{
	DOT11_ADHOC_CONNECT_FAIL_DOMAIN_MISMATCH = 0,
	DOT11_ADHOC_CONNECT_FAIL_PASSPHRASE_MISMATCH = 1,
	DOT11_ADHOC_CONNECT_FAIL_OTHER = 2,
}


[AllowDuplicates]
public enum DOT11EXT_IHV_CONNECTION_PHASE : int32
{
	connection_phase_any = 0,
	connection_phase_initial_connection = 1,
	connection_phase_post_l3_connection = 2,
}


[AllowDuplicates]
public enum DOT11_MSONEX_RESULT : int32
{
	DOT11_MSONEX_SUCCESS = 0,
	DOT11_MSONEX_FAILURE = 1,
	DOT11_MSONEX_IN_PROGRESS = 2,
}


[AllowDuplicates]
public enum DOT11EXT_IHV_INDICATION_TYPE : int32
{
	IndicationTypeNicSpecificNotification = 0,
	IndicationTypePmkidCandidateList = 1,
	IndicationTypeTkipMicFailure = 2,
	IndicationTypePhyStateChange = 3,
	IndicationTypeLinkQuality = 4,
}

#endregion

#region Function Pointers
public function void WLAN_NOTIFICATION_CALLBACK(L2_NOTIFICATION_DATA* param0, void* param1);

public function void WFD_OPEN_SESSION_COMPLETE_CALLBACK(HANDLE hSessionHandle, void* pvContext, Guid guidSessionInterface, uint32 dwError, uint32 dwReasonCode);

public function uint32 DOT11EXT_ALLOCATE_BUFFER(uint32 dwByteCount, void** ppvBuffer);

public function void DOT11EXT_FREE_BUFFER(void* pvMemory);

public function uint32 DOT11EXT_SET_PROFILE_CUSTOM_USER_DATA(HANDLE hDot11SvcHandle, HANDLE hConnectSession, uint32 dwSessionID, uint32 dwDataSize, void* pvData);

public function uint32 DOT11EXT_GET_PROFILE_CUSTOM_USER_DATA(HANDLE hDot11SvcHandle, HANDLE hConnectSession, uint32 dwSessionID, uint32* pdwDataSize, void** ppvData);

public function uint32 DOT11EXT_SET_CURRENT_PROFILE(HANDLE hDot11SvcHandle, HANDLE hConnectSession, DOT11EXT_IHV_CONNECTIVITY_PROFILE* pIhvConnProfile, DOT11EXT_IHV_SECURITY_PROFILE* pIhvSecProfile);

public function uint32 DOT11EXT_SEND_UI_REQUEST(HANDLE hDot11SvcHandle, DOT11EXT_IHV_UI_REQUEST* pIhvUIRequest);

public function uint32 DOT11EXT_PRE_ASSOCIATE_COMPLETION(HANDLE hDot11SvcHandle, HANDLE hConnectSession, uint32 dwReasonCode, uint32 dwWin32Error);

public function uint32 DOT11EXT_POST_ASSOCIATE_COMPLETION(HANDLE hDot11SvcHandle, HANDLE hSecuritySessionID, uint8** pPeer, uint32 dwReasonCode, uint32 dwWin32Error);

public function uint32 DOT11EXT_SEND_NOTIFICATION(HANDLE hDot11SvcHandle, L2_NOTIFICATION_DATA* pNotificationData);

public function uint32 DOT11EXT_SEND_PACKET(HANDLE hDot11SvcHandle, uint32 uPacketLen, void* pvPacket, HANDLE hSendCompletion);

public function uint32 DOT11EXT_SET_ETHERTYPE_HANDLING(HANDLE hDot11SvcHandle, uint32 uMaxBackLog, uint32 uNumOfExemption, DOT11_PRIVACY_EXEMPTION* pExemption, uint32 uNumOfRegistration, uint16* pusRegistration);

public function uint32 DOT11EXT_SET_AUTH_ALGORITHM(HANDLE hDot11SvcHandle, uint32 dwAuthAlgo);

public function uint32 DOT11EXT_SET_UNICAST_CIPHER_ALGORITHM(HANDLE hDot11SvcHandle, uint32 dwUnicastCipherAlgo);

public function uint32 DOT11EXT_SET_MULTICAST_CIPHER_ALGORITHM(HANDLE hDot11SvcHandle, uint32 dwMulticastCipherAlgo);

public function uint32 DOT11EXT_SET_DEFAULT_KEY(HANDLE hDot11SvcHandle, DOT11_CIPHER_DEFAULT_KEY_VALUE* pKey, DOT11_DIRECTION dot11Direction);

public function uint32 DOT11EXT_SET_KEY_MAPPING_KEY(HANDLE hDot11SvcHandle, DOT11_CIPHER_KEY_MAPPING_KEY_VALUE* pKey);

public function uint32 DOT11EXT_SET_DEFAULT_KEY_ID(HANDLE hDot11SvcHandle, uint32 uDefaultKeyId);

public function uint32 DOT11EXT_SET_EXCLUDE_UNENCRYPTED(HANDLE hDot11SvcHandle, BOOL bExcludeUnencrypted);

public function uint32 DOT11EXT_NIC_SPECIFIC_EXTENSION(HANDLE hDot11SvcHandle, uint32 dwInBufferSize, void* pvInBuffer, uint32* pdwOutBufferSize, void* pvOutBuffer);

public function uint32 DOT11EXT_ONEX_START(HANDLE hDot11SvcHandle, EAP_ATTRIBUTES* pEapAttributes);

public function uint32 DOT11EXT_ONEX_STOP(HANDLE hDot11SvcHandle);

public function uint32 DOT11EXT_PROCESS_ONEX_PACKET(HANDLE hDot11SvcHandle, uint32 dwInPacketSize, void* pvInPacket);

public function uint32 DOT11EXT_REQUEST_VIRTUAL_STATION(HANDLE hDot11PrimaryHandle, void* pvReserved);

public function uint32 DOT11EXT_RELEASE_VIRTUAL_STATION(HANDLE hDot11PrimaryHandle, void* pvReserved);

public function uint32 DOT11EXT_QUERY_VIRTUAL_STATION_PROPERTIES(HANDLE hDot11SvcHandle, BOOL* pbIsVirtualStation, Guid* pgPrimary, void* pvReserved);

public function uint32 DOT11EXT_SET_VIRTUAL_STATION_AP_PROPERTIES(HANDLE hDot11SvcHandle, HANDLE hConnectSession, uint32 dwNumProperties, DOT11EXT_VIRTUAL_STATION_AP_PROPERTY* pProperties, void* pvReserved);

public function uint32 DOT11EXTIHV_GET_VERSION_INFO(DOT11_IHV_VERSION_INFO* pDot11IHVVersionInfo);

public function uint32 DOT11EXTIHV_INIT_SERVICE(uint32 dwVerNumUsed, DOT11EXT_APIS* pDot11ExtAPI, void* pvReserved, DOT11EXT_IHV_HANDLERS* pDot11IHVHandlers);

public function uint32 DOT11EXTIHV_INIT_VIRTUAL_STATION(DOT11EXT_VIRTUAL_STATION_APIS* pDot11ExtVSAPI, void* pvReserved);

public function void DOT11EXTIHV_DEINIT_SERVICE();

public function uint32 DOT11EXTIHV_INIT_ADAPTER(DOT11_ADAPTER* pDot11Adapter, HANDLE hDot11SvcHandle, HANDLE* phIhvExtAdapter);

public function void DOT11EXTIHV_DEINIT_ADAPTER(HANDLE hIhvExtAdapter);

public function uint32 DOT11EXTIHV_PERFORM_PRE_ASSOCIATE(HANDLE hIhvExtAdapter, HANDLE hConnectSession, DOT11EXT_IHV_PROFILE_PARAMS* pIhvProfileParams, DOT11EXT_IHV_CONNECTIVITY_PROFILE* pIhvConnProfile, DOT11EXT_IHV_SECURITY_PROFILE* pIhvSecProfile, DOT11_BSS_LIST* pConnectableBssid, uint32* pdwReasonCode);

public function uint32 DOT11EXTIHV_ADAPTER_RESET(HANDLE hIhvExtAdapter);

public function uint32 DOT11EXTIHV_PERFORM_POST_ASSOCIATE(HANDLE hIhvExtAdapter, HANDLE hSecuritySessionID, DOT11_PORT_STATE* pPortState, uint32 uDot11AssocParamsBytes, DOT11_ASSOCIATION_COMPLETION_PARAMETERS* pDot11AssocParams);

public function uint32 DOT11EXTIHV_STOP_POST_ASSOCIATE(HANDLE hIhvExtAdapter, uint8** pPeer, uint32 dot11AssocStatus);

public function uint32 DOT11EXTIHV_VALIDATE_PROFILE(HANDLE hIhvExtAdapter, DOT11EXT_IHV_PROFILE_PARAMS* pIhvProfileParams, DOT11EXT_IHV_CONNECTIVITY_PROFILE* pIhvConnProfile, DOT11EXT_IHV_SECURITY_PROFILE* pIhvSecProfile, uint32* pdwReasonCode);

public function uint32 DOT11EXTIHV_PERFORM_CAPABILITY_MATCH(HANDLE hIhvExtAdapter, DOT11EXT_IHV_PROFILE_PARAMS* pIhvProfileParams, DOT11EXT_IHV_CONNECTIVITY_PROFILE* pIhvConnProfile, DOT11EXT_IHV_SECURITY_PROFILE* pIhvSecProfile, DOT11_BSS_LIST* pConnectableBssid, uint32* pdwReasonCode);

public function uint32 DOT11EXTIHV_CREATE_DISCOVERY_PROFILES(HANDLE hIhvExtAdapter, BOOL bInsecure, DOT11EXT_IHV_PROFILE_PARAMS* pIhvProfileParams, DOT11_BSS_LIST* pConnectableBssid, DOT11EXT_IHV_DISCOVERY_PROFILE_LIST* pIhvDiscoveryProfileList, uint32* pdwReasonCode);

public function uint32 DOT11EXTIHV_PROCESS_SESSION_CHANGE(uint32 uEventType, WTSSESSION_NOTIFICATION* pSessionNotification);

public function uint32 DOT11EXTIHV_RECEIVE_INDICATION(HANDLE hIhvExtAdapter, DOT11EXT_IHV_INDICATION_TYPE indicationType, uint32 uBufferLength, void* pvBuffer);

public function uint32 DOT11EXTIHV_RECEIVE_PACKET(HANDLE hIhvExtAdapter, uint32 dwInBufferSize, void* pvInBuffer);

public function uint32 DOT11EXTIHV_SEND_PACKET_COMPLETION(HANDLE hSendCompletion);

public function uint32 DOT11EXTIHV_IS_UI_REQUEST_PENDING(Guid guidUIRequest, BOOL* pbIsRequestPending);

public function uint32 DOT11EXTIHV_PROCESS_UI_RESPONSE(Guid guidUIRequest, uint32 dwByteCount, void* pvResponseBuffer);

public function uint32 DOT11EXTIHV_QUERY_UI_REQUEST(HANDLE hIhvExtAdapter, DOT11EXT_IHV_CONNECTION_PHASE connectionPhase, DOT11EXT_IHV_UI_REQUEST** ppIhvUIRequest);

public function uint32 DOT11EXTIHV_ONEX_INDICATE_RESULT(HANDLE hIhvExtAdapter, DOT11_MSONEX_RESULT msOneXResult, DOT11_MSONEX_RESULT_PARAMS* pDot11MsOneXResultParams);

public function uint32 DOT11EXTIHV_CONTROL(HANDLE hIhvExtAdapter, uint32 dwInBufferSize, uint8* pInBuffer, uint32 dwOutBufferSize, uint8* pOutBuffer, uint32* pdwBytesReturned);

#endregion

#region Structs
[CRepr]
public struct DOT11_SSID
{
	public uint32 uSSIDLength;
	public uint8[32] ucSSID;
}

[CRepr]
public struct DOT11_AUTH_CIPHER_PAIR
{
	public DOT11_AUTH_ALGORITHM AuthAlgoId;
	public DOT11_CIPHER_ALGORITHM CipherAlgoId;
}

[CRepr]
public struct DOT11_OI
{
	public uint16 OILength;
	public uint8[5] OI;
}

[CRepr]
public struct DOT11_ACCESSNETWORKOPTIONS
{
	public uint8 AccessNetworkType;
	public uint8 Internet;
	public uint8 ASRA;
	public uint8 ESR;
	public uint8 UESA;
}

[CRepr]
public struct DOT11_VENUEINFO
{
	public uint8 VenueGroup;
	public uint8 VenueType;
}

[CRepr]
public struct DOT11_BSSID_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint8[6] BSSIDs;
}

[CRepr]
public struct DOT11_RATE_SET
{
	public uint32 uRateSetLength;
	public uint8[126] ucRateSet;
}

[CRepr]
public struct DOT11_WFD_SESSION_INFO
{
	public uint16 uSessionInfoLength;
	public uint8[144] ucSessionInfo;
}

[CRepr]
public struct DOT11_OFFLOAD_CAPABILITY
{
	public uint32 uReserved;
	public uint32 uFlags;
	public uint32 uSupportedWEPAlgorithms;
	public uint32 uNumOfReplayWindows;
	public uint32 uMaxWEPKeyMappingLength;
	public uint32 uSupportedAuthAlgorithms;
	public uint32 uMaxAuthKeyMappingLength;
}

[CRepr]
public struct DOT11_CURRENT_OFFLOAD_CAPABILITY
{
	public uint32 uReserved;
	public uint32 uFlags;
}

[CRepr]
public struct DOT11_IV48_COUNTER
{
	public uint32 uIV32Counter;
	public uint16 usIV16Counter;
}

[CRepr]
public struct DOT11_WEP_OFFLOAD
{
	public uint32 uReserved;
	public HANDLE hOffloadContext;
	public HANDLE hOffload;
	public DOT11_OFFLOAD_TYPE dot11OffloadType;
	public uint32 dwAlgorithm;
	public BOOLEAN bRowIsOutbound;
	public BOOLEAN bUseDefault;
	public uint32 uFlags;
	public uint8[6] ucMacAddress;
	public uint32 uNumOfRWsOnPeer;
	public uint32 uNumOfRWsOnMe;
	public DOT11_IV48_COUNTER[16] dot11IV48Counters;
	public uint16[16] usDot11RWBitMaps;
	public uint16 usKeyLength;
	public uint8* ucKey mut => &ucKey_impl;
	private uint8[ANYSIZE_ARRAY] ucKey_impl;
}

[CRepr]
public struct DOT11_WEP_UPLOAD
{
	public uint32 uReserved;
	public DOT11_OFFLOAD_TYPE dot11OffloadType;
	public HANDLE hOffload;
	public uint32 uNumOfRWsUsed;
	public DOT11_IV48_COUNTER[16] dot11IV48Counters;
	public uint16[16] usDot11RWBitMaps;
}

[CRepr]
public struct DOT11_DEFAULT_WEP_OFFLOAD
{
	public uint32 uReserved;
	public HANDLE hOffloadContext;
	public HANDLE hOffload;
	public uint32 dwIndex;
	public DOT11_OFFLOAD_TYPE dot11OffloadType;
	public uint32 dwAlgorithm;
	public uint32 uFlags;
	public DOT11_KEY_DIRECTION dot11KeyDirection;
	public uint8[6] ucMacAddress;
	public uint32 uNumOfRWsOnMe;
	public DOT11_IV48_COUNTER[16] dot11IV48Counters;
	public uint16[16] usDot11RWBitMaps;
	public uint16 usKeyLength;
	public uint8* ucKey mut => &ucKey_impl;
	private uint8[ANYSIZE_ARRAY] ucKey_impl;
}

[CRepr]
public struct DOT11_DEFAULT_WEP_UPLOAD
{
	public uint32 uReserved;
	public DOT11_OFFLOAD_TYPE dot11OffloadType;
	public HANDLE hOffload;
	public uint32 uNumOfRWsUsed;
	public DOT11_IV48_COUNTER[16] dot11IV48Counters;
	public uint16[16] usDot11RWBitMaps;
}

[CRepr]
public struct DOT11_OPERATION_MODE_CAPABILITY
{
	public uint32 uReserved;
	public uint32 uMajorVersion;
	public uint32 uMinorVersion;
	public uint32 uNumOfTXBuffers;
	public uint32 uNumOfRXBuffers;
	public uint32 uOpModeCapability;
}

[CRepr]
public struct DOT11_CURRENT_OPERATION_MODE
{
	public uint32 uReserved;
	public uint32 uCurrentOpMode;
}

[CRepr]
public struct DOT11_SCAN_REQUEST
{
	public DOT11_BSS_TYPE dot11BSSType;
	public uint8[6] dot11BSSID;
	public DOT11_SSID dot11SSID;
	public DOT11_SCAN_TYPE dot11ScanType;
	public BOOLEAN bRestrictedScan;
	public BOOLEAN bUseRequestIE;
	public uint32 uRequestIDsOffset;
	public uint32 uNumOfRequestIDs;
	public uint32 uPhyTypesOffset;
	public uint32 uNumOfPhyTypes;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_PHY_TYPE_INFO
{
	public DOT11_PHY_TYPE dot11PhyType;
	public BOOLEAN bUseParameters;
	public uint32 uProbeDelay;
	public uint32 uMinChannelTime;
	public uint32 uMaxChannelTime;
	public CH_DESCRIPTION_TYPE ChDescriptionType;
	public uint32 uChannelListSize;
	public uint8* ucChannelListBuffer mut => &ucChannelListBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucChannelListBuffer_impl;
}

[CRepr]
public struct DOT11_SCAN_REQUEST_V2
{
	public DOT11_BSS_TYPE dot11BSSType;
	public uint8[6] dot11BSSID;
	public DOT11_SCAN_TYPE dot11ScanType;
	public BOOLEAN bRestrictedScan;
	public uint32 udot11SSIDsOffset;
	public uint32 uNumOfdot11SSIDs;
	public BOOLEAN bUseRequestIE;
	public uint32 uRequestIDsOffset;
	public uint32 uNumOfRequestIDs;
	public uint32 uPhyTypeInfosOffset;
	public uint32 uNumOfPhyTypeInfos;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_PHY_TYPE_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_PHY_TYPE* dot11PhyType mut => &dot11PhyType_impl;
	private DOT11_PHY_TYPE[ANYSIZE_ARRAY] dot11PhyType_impl;
}

[CRepr]
public struct DOT11_BSS_DESCRIPTION
{
	public uint32 uReserved;
	public uint8[6] dot11BSSID;
	public DOT11_BSS_TYPE dot11BSSType;
	public uint16 usBeaconPeriod;
	public uint64 ullTimestamp;
	public uint16 usCapabilityInformation;
	public uint32 uBufferLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_JOIN_REQUEST
{
	public uint32 uJoinFailureTimeout;
	public DOT11_RATE_SET OperationalRateSet;
	public uint32 uChCenterFrequency;
	public DOT11_BSS_DESCRIPTION dot11BSSDescription;
}

[CRepr]
public struct DOT11_START_REQUEST
{
	public uint32 uStartFailureTimeout;
	public DOT11_RATE_SET OperationalRateSet;
	public uint32 uChCenterFrequency;
	public DOT11_BSS_DESCRIPTION dot11BSSDescription;
}

[CRepr]
public struct DOT11_UPDATE_IE
{
	public DOT11_UPDATE_IE_OP dot11UpdateIEOp;
	public uint32 uBufferLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_RESET_REQUEST
{
	public DOT11_RESET_TYPE dot11ResetType;
	public uint8[6] dot11MacAddress;
	public BOOLEAN bSetDefaultMIB;
}

[CRepr]
public struct DOT11_OPTIONAL_CAPABILITY
{
	public uint32 uReserved;
	public BOOLEAN bDot11PCF;
	public BOOLEAN bDot11PCFMPDUTransferToPC;
	public BOOLEAN bStrictlyOrderedServiceClass;
}

[CRepr]
public struct DOT11_CURRENT_OPTIONAL_CAPABILITY
{
	public uint32 uReserved;
	public BOOLEAN bDot11CFPollable;
	public BOOLEAN bDot11PCF;
	public BOOLEAN bDot11PCFMPDUTransferToPC;
	public BOOLEAN bStrictlyOrderedServiceClass;
}

[CRepr]
public struct DOT11_POWER_MGMT_MODE
{
	public DOT11_POWER_MODE dot11PowerMode;
	public uint32 uPowerSaveLevel;
	public uint16 usListenInterval;
	public uint16 usAID;
	public BOOLEAN bReceiveDTIMs;
}

[CRepr]
public struct DOT11_COUNTERS_ENTRY
{
	public uint32 uTransmittedFragmentCount;
	public uint32 uMulticastTransmittedFrameCount;
	public uint32 uFailedCount;
	public uint32 uRetryCount;
	public uint32 uMultipleRetryCount;
	public uint32 uFrameDuplicateCount;
	public uint32 uRTSSuccessCount;
	public uint32 uRTSFailureCount;
	public uint32 uACKFailureCount;
	public uint32 uReceivedFragmentCount;
	public uint32 uMulticastReceivedFrameCount;
	public uint32 uFCSErrorCount;
	public uint32 uTransmittedFrameCount;
}

[CRepr]
public struct DOT11_SUPPORTED_PHY_TYPES
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_PHY_TYPE* dot11PHYType mut => &dot11PHYType_impl;
	private DOT11_PHY_TYPE[ANYSIZE_ARRAY] dot11PHYType_impl;
}

[CRepr]
public struct DOT11_SUPPORTED_POWER_LEVELS
{
	public uint32 uNumOfSupportedPowerLevels;
	public uint32[8] uTxPowerLevelValues;
}

[CRepr]
public struct DOT11_REG_DOMAIN_VALUE
{
	public uint32 uRegDomainsSupportIndex;
	public uint32 uRegDomainsSupportValue;
}

[CRepr]
public struct DOT11_REG_DOMAINS_SUPPORT_VALUE
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_REG_DOMAIN_VALUE* dot11RegDomainValue mut => &dot11RegDomainValue_impl;
	private DOT11_REG_DOMAIN_VALUE[ANYSIZE_ARRAY] dot11RegDomainValue_impl;
}

[CRepr]
public struct DOT11_SUPPORTED_ANTENNA
{
	public uint32 uAntennaListIndex;
	public BOOLEAN bSupportedAntenna;
}

[CRepr]
public struct DOT11_SUPPORTED_ANTENNA_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_SUPPORTED_ANTENNA* dot11SupportedAntenna mut => &dot11SupportedAntenna_impl;
	private DOT11_SUPPORTED_ANTENNA[ANYSIZE_ARRAY] dot11SupportedAntenna_impl;
}

[CRepr]
public struct DOT11_DIVERSITY_SELECTION_RX
{
	public uint32 uAntennaListIndex;
	public BOOLEAN bDiversitySelectionRX;
}

[CRepr]
public struct DOT11_DIVERSITY_SELECTION_RX_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_DIVERSITY_SELECTION_RX* dot11DiversitySelectionRx mut => &dot11DiversitySelectionRx_impl;
	private DOT11_DIVERSITY_SELECTION_RX[ANYSIZE_ARRAY] dot11DiversitySelectionRx_impl;
}

[CRepr]
public struct DOT11_SUPPORTED_DATA_RATES_VALUE
{
	public uint8[8] ucSupportedTxDataRatesValue;
	public uint8[8] ucSupportedRxDataRatesValue;
}

[CRepr]
public struct DOT11_SUPPORTED_DATA_RATES_VALUE_V2
{
	public uint8[255] ucSupportedTxDataRatesValue;
	public uint8[255] ucSupportedRxDataRatesValue;
}

[CRepr]
public struct DOT11_MULTI_DOMAIN_CAPABILITY_ENTRY
{
	public uint32 uMultiDomainCapabilityIndex;
	public uint32 uFirstChannelNumber;
	public uint32 uNumberOfChannels;
	public int32 lMaximumTransmitPowerLevel;
}

[CRepr]
public struct DOT11_MD_CAPABILITY_ENTRY_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_MULTI_DOMAIN_CAPABILITY_ENTRY* dot11MDCapabilityEntry mut => &dot11MDCapabilityEntry_impl;
	private DOT11_MULTI_DOMAIN_CAPABILITY_ENTRY[ANYSIZE_ARRAY] dot11MDCapabilityEntry_impl;
}

[CRepr]
public struct DOT11_HOPPING_PATTERN_ENTRY
{
	public uint32 uHoppingPatternIndex;
	public uint32 uRandomTableFieldNumber;
}

[CRepr]
public struct DOT11_HOPPING_PATTERN_ENTRY_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_HOPPING_PATTERN_ENTRY* dot11HoppingPatternEntry mut => &dot11HoppingPatternEntry_impl;
	private DOT11_HOPPING_PATTERN_ENTRY[ANYSIZE_ARRAY] dot11HoppingPatternEntry_impl;
}

[CRepr]
public struct DOT11_WPA_TSC
{
	public uint32 uReserved;
	public DOT11_OFFLOAD_TYPE dot11OffloadType;
	public HANDLE hOffload;
	public DOT11_IV48_COUNTER dot11IV48Counter;
}

[CRepr]
public struct DOT11_RSSI_RANGE
{
	public DOT11_PHY_TYPE dot11PhyType;
	public uint32 uRSSIMin;
	public uint32 uRSSIMax;
}

[CRepr]
public struct DOT11_NIC_SPECIFIC_EXTENSION
{
	public uint32 uBufferLength;
	public uint32 uTotalBufferLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_AP_JOIN_REQUEST
{
	public uint32 uJoinFailureTimeout;
	public DOT11_RATE_SET OperationalRateSet;
	public uint32 uChCenterFrequency;
	public DOT11_BSS_DESCRIPTION dot11BSSDescription;
}

[CRepr]
public struct DOT11_RECV_SENSITIVITY
{
	public uint8 ucDataRate;
	public int32 lRSSIMin;
	public int32 lRSSIMax;
}

[CRepr]
public struct DOT11_RECV_SENSITIVITY_LIST
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public DOT11_PHY_TYPE dot11PhyType;
		public uint32 uPhyId;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_RECV_SENSITIVITY* dot11RecvSensitivity mut => &dot11RecvSensitivity_impl;
	private DOT11_RECV_SENSITIVITY[ANYSIZE_ARRAY] dot11RecvSensitivity_impl;
}

[CRepr]
public struct DOT11_WME_AC_PARAMETERS
{
	public uint8 ucAccessCategoryIndex;
	public uint8 ucAIFSN;
	public uint8 ucECWmin;
	public uint8 ucECWmax;
	public uint16 usTXOPLimit;
}

[CRepr]
public struct DOT11_WME_AC_PARAMETERS_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_WME_AC_PARAMETERS* dot11WMEACParameters mut => &dot11WMEACParameters_impl;
	private DOT11_WME_AC_PARAMETERS[ANYSIZE_ARRAY] dot11WMEACParameters_impl;
}

[CRepr]
public struct DOT11_WME_UPDATE_IE
{
	public uint32 uParamElemMinBeaconIntervals;
	public uint32 uWMEInfoElemOffset;
	public uint32 uWMEInfoElemLength;
	public uint32 uWMEParamElemOffset;
	public uint32 uWMEParamElemLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_QOS_TX_DURATION
{
	public uint32 uNominalMSDUSize;
	public uint32 uMinPHYRate;
	public uint32 uDuration;
}

[CRepr]
public struct DOT11_QOS_TX_MEDIUM_TIME
{
	public uint8[6] dot11PeerAddress;
	public uint8 ucQoSPriority;
	public uint32 uMediumTimeAdmited;
}

[CRepr]
public struct DOT11_SUPPORTED_OFDM_FREQUENCY
{
	public uint32 uCenterFrequency;
}

[CRepr]
public struct DOT11_SUPPORTED_OFDM_FREQUENCY_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_SUPPORTED_OFDM_FREQUENCY* dot11SupportedOFDMFrequency mut => &dot11SupportedOFDMFrequency_impl;
	private DOT11_SUPPORTED_OFDM_FREQUENCY[ANYSIZE_ARRAY] dot11SupportedOFDMFrequency_impl;
}

[CRepr]
public struct DOT11_SUPPORTED_DSSS_CHANNEL
{
	public uint32 uChannel;
}

[CRepr]
public struct DOT11_SUPPORTED_DSSS_CHANNEL_LIST
{
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_SUPPORTED_DSSS_CHANNEL* dot11SupportedDSSSChannel mut => &dot11SupportedDSSSChannel_impl;
	private DOT11_SUPPORTED_DSSS_CHANNEL[ANYSIZE_ARRAY] dot11SupportedDSSSChannel_impl;
}

[CRepr]
public struct DOT11_BYTE_ARRAY
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfBytes;
	public uint32 uTotalNumOfBytes;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr, Union]
public struct DOT11_BSS_ENTRY_PHY_SPECIFIC_INFO
{
	[CRepr]
	public struct _FHSS_e__Struct
	{
		public uint32 uHopPattern;
		public uint32 uHopSet;
		public uint32 uDwellTime;
	}
	public uint32 uChCenterFrequency;
	public _FHSS_e__Struct FHSS;
}

[CRepr]
public struct DOT11_BSS_ENTRY
{
	public uint32 uPhyId;
	public DOT11_BSS_ENTRY_PHY_SPECIFIC_INFO PhySpecificInfo;
	public uint8[6] dot11BSSID;
	public DOT11_BSS_TYPE dot11BSSType;
	public int32 lRSSI;
	public uint32 uLinkQuality;
	public BOOLEAN bInRegDomain;
	public uint16 usBeaconPeriod;
	public uint64 ullTimestamp;
	public uint64 ullHostTimestamp;
	public uint16 usCapabilityInformation;
	public uint32 uBufferLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_SSID_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_SSID* SSIDs mut => &SSIDs_impl;
	private DOT11_SSID[ANYSIZE_ARRAY] SSIDs_impl;
}

[CRepr]
public struct DOT11_MAC_ADDRESS_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint8[6] MacAddrs;
}

[CRepr]
public struct DOT11_PMKID_ENTRY
{
	public uint8[6] BSSID;
	public uint8[16] PMKID;
	public uint32 uFlags;
}

[CRepr]
public struct DOT11_PMKID_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_PMKID_ENTRY* PMKIDs mut => &PMKIDs_impl;
	private DOT11_PMKID_ENTRY[ANYSIZE_ARRAY] PMKIDs_impl;
}

[CRepr]
public struct DOT11_PHY_FRAME_STATISTICS
{
	public uint64 ullTransmittedFrameCount;
	public uint64 ullMulticastTransmittedFrameCount;
	public uint64 ullFailedCount;
	public uint64 ullRetryCount;
	public uint64 ullMultipleRetryCount;
	public uint64 ullMaxTXLifetimeExceededCount;
	public uint64 ullTransmittedFragmentCount;
	public uint64 ullRTSSuccessCount;
	public uint64 ullRTSFailureCount;
	public uint64 ullACKFailureCount;
	public uint64 ullReceivedFrameCount;
	public uint64 ullMulticastReceivedFrameCount;
	public uint64 ullPromiscuousReceivedFrameCount;
	public uint64 ullMaxRXLifetimeExceededCount;
	public uint64 ullFrameDuplicateCount;
	public uint64 ullReceivedFragmentCount;
	public uint64 ullPromiscuousReceivedFragmentCount;
	public uint64 ullFCSErrorCount;
}

[CRepr]
public struct DOT11_MAC_FRAME_STATISTICS
{
	public uint64 ullTransmittedFrameCount;
	public uint64 ullReceivedFrameCount;
	public uint64 ullTransmittedFailureFrameCount;
	public uint64 ullReceivedFailureFrameCount;
	public uint64 ullWEPExcludedCount;
	public uint64 ullTKIPLocalMICFailures;
	public uint64 ullTKIPReplays;
	public uint64 ullTKIPICVErrorCount;
	public uint64 ullCCMPReplays;
	public uint64 ullCCMPDecryptErrors;
	public uint64 ullWEPUndecryptableCount;
	public uint64 ullWEPICVErrorCount;
	public uint64 ullDecryptSuccessCount;
	public uint64 ullDecryptFailureCount;
}

[CRepr]
public struct DOT11_STATISTICS
{
	public NDIS_OBJECT_HEADER Header;
	public uint64 ullFourWayHandshakeFailures;
	public uint64 ullTKIPCounterMeasuresInvoked;
	public uint64 ullReserved;
	public DOT11_MAC_FRAME_STATISTICS MacUcastCounters;
	public DOT11_MAC_FRAME_STATISTICS MacMcastCounters;
	public DOT11_PHY_FRAME_STATISTICS* PhyCounters mut => &PhyCounters_impl;
	private DOT11_PHY_FRAME_STATISTICS[ANYSIZE_ARRAY] PhyCounters_impl;
}

[CRepr]
public struct DOT11_PRIVACY_EXEMPTION
{
	public uint16 usEtherType;
	public uint16 usExemptionActionType;
	public uint16 usExemptionPacketType;
}

[CRepr]
public struct DOT11_PRIVACY_EXEMPTION_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_PRIVACY_EXEMPTION* PrivacyExemptionEntries mut => &PrivacyExemptionEntries_impl;
	private DOT11_PRIVACY_EXEMPTION[ANYSIZE_ARRAY] PrivacyExemptionEntries_impl;
}

[CRepr]
public struct DOT11_AUTH_ALGORITHM_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_AUTH_ALGORITHM* AlgorithmIds mut => &AlgorithmIds_impl;
	private DOT11_AUTH_ALGORITHM[ANYSIZE_ARRAY] AlgorithmIds_impl;
}

[CRepr]
public struct DOT11_AUTH_CIPHER_PAIR_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_AUTH_CIPHER_PAIR* AuthCipherPairs mut => &AuthCipherPairs_impl;
	private DOT11_AUTH_CIPHER_PAIR[ANYSIZE_ARRAY] AuthCipherPairs_impl;
}

[CRepr]
public struct DOT11_CIPHER_ALGORITHM_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_CIPHER_ALGORITHM* AlgorithmIds mut => &AlgorithmIds_impl;
	private DOT11_CIPHER_ALGORITHM[ANYSIZE_ARRAY] AlgorithmIds_impl;
}

[CRepr]
public struct DOT11_CIPHER_DEFAULT_KEY_VALUE
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uKeyIndex;
	public DOT11_CIPHER_ALGORITHM AlgorithmId;
	public uint8[6] MacAddr;
	public BOOLEAN bDelete;
	public BOOLEAN bStatic;
	public uint16 usKeyLength;
	public uint8* ucKey mut => &ucKey_impl;
	private uint8[ANYSIZE_ARRAY] ucKey_impl;
}

[CRepr]
public struct DOT11_KEY_ALGO_TKIP_MIC
{
	public uint8[6] ucIV48Counter;
	public uint32 ulTKIPKeyLength;
	public uint32 ulMICKeyLength;
	public uint8* ucTKIPMICKeys mut => &ucTKIPMICKeys_impl;
	private uint8[ANYSIZE_ARRAY] ucTKIPMICKeys_impl;
}

[CRepr]
public struct DOT11_KEY_ALGO_CCMP
{
	public uint8[6] ucIV48Counter;
	public uint32 ulCCMPKeyLength;
	public uint8* ucCCMPKey mut => &ucCCMPKey_impl;
	private uint8[ANYSIZE_ARRAY] ucCCMPKey_impl;
}

[CRepr]
public struct DOT11_KEY_ALGO_GCMP
{
	public uint8[6] ucIV48Counter;
	public uint32 ulGCMPKeyLength;
	public uint8* ucGCMPKey mut => &ucGCMPKey_impl;
	private uint8[ANYSIZE_ARRAY] ucGCMPKey_impl;
}

[CRepr]
public struct DOT11_KEY_ALGO_GCMP_256
{
	public uint8[6] ucIV48Counter;
	public uint32 ulGCMP256KeyLength;
	public uint8* ucGCMP256Key mut => &ucGCMP256Key_impl;
	private uint8[ANYSIZE_ARRAY] ucGCMP256Key_impl;
}

[CRepr]
public struct DOT11_KEY_ALGO_BIP
{
	public uint8[6] ucIPN;
	public uint32 ulBIPKeyLength;
	public uint8* ucBIPKey mut => &ucBIPKey_impl;
	private uint8[ANYSIZE_ARRAY] ucBIPKey_impl;
}

[CRepr]
public struct DOT11_KEY_ALGO_BIP_GMAC_256
{
	public uint8[6] ucIPN;
	public uint32 ulBIPGmac256KeyLength;
	public uint8* ucBIPGmac256Key mut => &ucBIPGmac256Key_impl;
	private uint8[ANYSIZE_ARRAY] ucBIPGmac256Key_impl;
}

[CRepr]
public struct DOT11_CIPHER_KEY_MAPPING_KEY_VALUE
{
	public uint8[6] PeerMacAddr;
	public DOT11_CIPHER_ALGORITHM AlgorithmId;
	public DOT11_DIRECTION Direction;
	public BOOLEAN bDelete;
	public BOOLEAN bStatic;
	public uint16 usKeyLength;
	public uint8* ucKey mut => &ucKey_impl;
	private uint8[ANYSIZE_ARRAY] ucKey_impl;
}

[CRepr]
public struct DOT11_ASSOCIATION_INFO_EX
{
	public uint8[6] PeerMacAddress;
	public uint8[6] BSSID;
	public uint16 usCapabilityInformation;
	public uint16 usListenInterval;
	public uint8[255] ucPeerSupportedRates;
	public uint16 usAssociationID;
	public DOT11_ASSOCIATION_STATE dot11AssociationState;
	public DOT11_POWER_MODE dot11PowerMode;
	public LARGE_INTEGER liAssociationUpTime;
	public uint64 ullNumOfTxPacketSuccesses;
	public uint64 ullNumOfTxPacketFailures;
	public uint64 ullNumOfRxPacketSuccesses;
	public uint64 ullNumOfRxPacketFailures;
}

[CRepr]
public struct DOT11_ASSOCIATION_INFO_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_ASSOCIATION_INFO_EX* dot11AssocInfo mut => &dot11AssocInfo_impl;
	private DOT11_ASSOCIATION_INFO_EX[ANYSIZE_ARRAY] dot11AssocInfo_impl;
}

[CRepr]
public struct DOT11_PHY_ID_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint32* dot11PhyId mut => &dot11PhyId_impl;
	private uint32[ANYSIZE_ARRAY] dot11PhyId_impl;
}

[CRepr]
public struct DOT11_EXTSTA_CAPABILITY
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uScanSSIDListSize;
	public uint32 uDesiredBSSIDListSize;
	public uint32 uDesiredSSIDListSize;
	public uint32 uExcludedMacAddressListSize;
	public uint32 uPrivacyExemptionListSize;
	public uint32 uKeyMappingTableSize;
	public uint32 uDefaultKeyTableSize;
	public uint32 uWEPKeyValueMaxLength;
	public uint32 uPMKIDCacheSize;
	public uint32 uMaxNumPerSTADefaultKeyTables;
}

[CRepr]
public struct DOT11_DATA_RATE_MAPPING_ENTRY
{
	public uint8 ucDataRateIndex;
	public uint8 ucDataRateFlag;
	public uint16 usDataRateValue;
}

[CRepr]
public struct DOT11_DATA_RATE_MAPPING_TABLE
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uDataRateMappingLength;
	public DOT11_DATA_RATE_MAPPING_ENTRY[126] DataRateMappingEntries;
}

[CRepr]
public struct DOT11_COUNTRY_OR_REGION_STRING_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint8[3] CountryOrRegionStrings;
}

[CRepr]
public struct DOT11_PORT_STATE_NOTIFICATION
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMac;
	public BOOLEAN bOpen;
}

[CRepr]
public struct DOT11_IBSS_PARAMS
{
	public NDIS_OBJECT_HEADER Header;
	public BOOLEAN bJoinOnly;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_QOS_PARAMS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8 ucEnabledQoSProtocolFlags;
}

[CRepr]
public struct DOT11_ASSOCIATION_PARAMS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] BSSID;
	public uint32 uAssocRequestIEsOffset;
	public uint32 uAssocRequestIEsLength;
}

[CRepr]
public struct DOT11_FRAGMENT_DESCRIPTOR
{
	public uint32 uOffset;
	public uint32 uLength;
}

[CRepr]
public struct DOT11_PER_MSDU_COUNTERS
{
	public uint32 uTransmittedFragmentCount;
	public uint32 uRetryCount;
	public uint32 uRTSSuccessCount;
	public uint32 uRTSFailureCount;
	public uint32 uACKFailureCount;
}

[CRepr]
public struct DOT11_HRDSSS_PHY_ATTRIBUTES
{
	public BOOLEAN bShortPreambleOptionImplemented;
	public BOOLEAN bPBCCOptionImplemented;
	public BOOLEAN bChannelAgilityPresent;
	public uint32 uHRCCAModeSupported;
}

[CRepr]
public struct DOT11_OFDM_PHY_ATTRIBUTES
{
	public uint32 uFrequencyBandsSupported;
}

[CRepr]
public struct DOT11_ERP_PHY_ATTRIBUTES
{
	public DOT11_HRDSSS_PHY_ATTRIBUTES HRDSSSAttributes;
	public BOOLEAN bERPPBCCOptionImplemented;
	public BOOLEAN bDSSSOFDMOptionImplemented;
	public BOOLEAN bShortSlotTimeOptionImplemented;
}

[CRepr]
public struct DOT11_PHY_ATTRIBUTES
{
	[CRepr, Union]
	public struct _PhySpecificAttributes_e__Union
	{
		public DOT11_HRDSSS_PHY_ATTRIBUTES HRDSSSAttributes;
		public DOT11_OFDM_PHY_ATTRIBUTES OFDMAttributes;
		public DOT11_ERP_PHY_ATTRIBUTES ERPAttributes;
	}
	public NDIS_OBJECT_HEADER Header;
	public DOT11_PHY_TYPE PhyType;
	public BOOLEAN bHardwarePhyState;
	public BOOLEAN bSoftwarePhyState;
	public BOOLEAN bCFPollable;
	public uint32 uMPDUMaxLength;
	public DOT11_TEMP_TYPE TempType;
	public DOT11_DIVERSITY_SUPPORT DiversitySupport;
	public _PhySpecificAttributes_e__Union PhySpecificAttributes;
	public uint32 uNumberSupportedPowerLevels;
	public uint32[8] TxPowerLevels;
	public uint32 uNumDataRateMappingEntries;
	public DOT11_DATA_RATE_MAPPING_ENTRY[126] DataRateMappingEntries;
	public DOT11_SUPPORTED_DATA_RATES_VALUE_V2 SupportedDataRatesValue;
}

[CRepr]
public struct DOT11_EXTSTA_ATTRIBUTES
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uScanSSIDListSize;
	public uint32 uDesiredBSSIDListSize;
	public uint32 uDesiredSSIDListSize;
	public uint32 uExcludedMacAddressListSize;
	public uint32 uPrivacyExemptionListSize;
	public uint32 uKeyMappingTableSize;
	public uint32 uDefaultKeyTableSize;
	public uint32 uWEPKeyValueMaxLength;
	public uint32 uPMKIDCacheSize;
	public uint32 uMaxNumPerSTADefaultKeyTables;
	public BOOLEAN bStrictlyOrderedServiceClassImplemented;
	public uint8 ucSupportedQoSProtocolFlags;
	public BOOLEAN bSafeModeImplemented;
	public uint32 uNumSupportedCountryOrRegionStrings;
	public uint8* pSupportedCountryOrRegionStrings;
	public uint32 uInfraNumSupportedUcastAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pInfraSupportedUcastAlgoPairs;
	public uint32 uInfraNumSupportedMcastAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pInfraSupportedMcastAlgoPairs;
	public uint32 uAdhocNumSupportedUcastAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pAdhocSupportedUcastAlgoPairs;
	public uint32 uAdhocNumSupportedMcastAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pAdhocSupportedMcastAlgoPairs;
	public BOOLEAN bAutoPowerSaveMode;
	public uint32 uMaxNetworkOffloadListSize;
	public BOOLEAN bMFPCapable;
	public uint32 uInfraNumSupportedMcastMgmtAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pInfraSupportedMcastMgmtAlgoPairs;
	public BOOLEAN bNeighborReportSupported;
	public BOOLEAN bAPChannelReportSupported;
	public BOOLEAN bActionFramesSupported;
	public BOOLEAN bANQPQueryOffloadSupported;
	public BOOLEAN bHESSIDConnectionSupported;
}

[CRepr]
public struct DOT11_RECV_EXTENSION_INFO
{
	public uint32 uVersion;
	public void* pvReserved;
	public DOT11_PHY_TYPE dot11PhyType;
	public uint32 uChCenterFrequency;
	public int32 lRSSI;
	public int32 lRSSIMin;
	public int32 lRSSIMax;
	public uint32 uRSSI;
	public uint8 ucPriority;
	public uint8 ucDataRate;
	public uint8[6] ucPeerMacAddress;
	public uint32 dwExtendedStatus;
	public HANDLE hWEPOffloadContext;
	public HANDLE hAuthOffloadContext;
	public uint16 usWEPAppliedMask;
	public uint16 usWPAMSDUPriority;
	public DOT11_IV48_COUNTER dot11LowestIV48Counter;
	public uint16 usDot11LeftRWBitMap;
	public DOT11_IV48_COUNTER dot11HighestIV48Counter;
	public uint16 usDot11RightRWBitMap;
	public uint16 usNumberOfMPDUsReceived;
	public uint16 usNumberOfFragments;
	public void** pNdisPackets mut => &pNdisPackets_impl;
	private void*[ANYSIZE_ARRAY] pNdisPackets_impl;
}

[CRepr]
public struct DOT11_RECV_EXTENSION_INFO_V2
{
	public uint32 uVersion;
	public void* pvReserved;
	public DOT11_PHY_TYPE dot11PhyType;
	public uint32 uChCenterFrequency;
	public int32 lRSSI;
	public uint32 uRSSI;
	public uint8 ucPriority;
	public uint8 ucDataRate;
	public uint8[6] ucPeerMacAddress;
	public uint32 dwExtendedStatus;
	public HANDLE hWEPOffloadContext;
	public HANDLE hAuthOffloadContext;
	public uint16 usWEPAppliedMask;
	public uint16 usWPAMSDUPriority;
	public DOT11_IV48_COUNTER dot11LowestIV48Counter;
	public uint16 usDot11LeftRWBitMap;
	public DOT11_IV48_COUNTER dot11HighestIV48Counter;
	public uint16 usDot11RightRWBitMap;
	public uint16 usNumberOfMPDUsReceived;
	public uint16 usNumberOfFragments;
	public void** pNdisPackets mut => &pNdisPackets_impl;
	private void*[ANYSIZE_ARRAY] pNdisPackets_impl;
}

[CRepr]
public struct DOT11_STATUS_INDICATION
{
	public uint32 uStatusType;
	public int32 ndisStatus;
}

[CRepr]
public struct DOT11_MPDU_MAX_LENGTH_INDICATION
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uPhyId;
	public uint32 uMPDUMaxLength;
}

[CRepr]
public struct DOT11_ASSOCIATION_START_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] MacAddr;
	public DOT11_SSID SSID;
	public uint32 uIHVDataOffset;
	public uint32 uIHVDataSize;
}

[CRepr]
public struct DOT11_ENCAP_ENTRY
{
	public uint16 usEtherType;
	public uint16 usEncapType;
}

[CRepr]
public struct DOT11_ASSOCIATION_COMPLETION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] MacAddr;
	public uint32 uStatus;
	public BOOLEAN bReAssocReq;
	public BOOLEAN bReAssocResp;
	public uint32 uAssocReqOffset;
	public uint32 uAssocReqSize;
	public uint32 uAssocRespOffset;
	public uint32 uAssocRespSize;
	public uint32 uBeaconOffset;
	public uint32 uBeaconSize;
	public uint32 uIHVDataOffset;
	public uint32 uIHVDataSize;
	public DOT11_AUTH_ALGORITHM AuthAlgo;
	public DOT11_CIPHER_ALGORITHM UnicastCipher;
	public DOT11_CIPHER_ALGORITHM MulticastCipher;
	public uint32 uActivePhyListOffset;
	public uint32 uActivePhyListSize;
	public BOOLEAN bFourAddressSupported;
	public BOOLEAN bPortAuthorized;
	public uint8 ucActiveQoSProtocol;
	public DOT11_DS_INFO DSInfo;
	public uint32 uEncapTableOffset;
	public uint32 uEncapTableSize;
	public DOT11_CIPHER_ALGORITHM MulticastMgmtCipher;
	public uint32 uAssocComebackTime;
}

[CRepr]
public struct DOT11_CONNECTION_START_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_BSS_TYPE BSSType;
	public uint8[6] AdhocBSSID;
	public DOT11_SSID AdhocSSID;
}

[CRepr]
public struct DOT11_CONNECTION_COMPLETION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uStatus;
}

[CRepr]
public struct DOT11_ROAMING_START_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] AdhocBSSID;
	public DOT11_SSID AdhocSSID;
	public uint32 uRoamingReason;
}

[CRepr]
public struct DOT11_ROAMING_COMPLETION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uStatus;
}

[CRepr]
public struct DOT11_DISASSOCIATION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] MacAddr;
	public uint32 uReason;
	public uint32 uIHVDataOffset;
	public uint32 uIHVDataSize;
}

[CRepr]
public struct DOT11_TKIPMIC_FAILURE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public BOOLEAN bDefaultKeyFailure;
	public uint32 uKeyIndex;
	public uint8[6] PeerMac;
}

[CRepr]
public struct DOT11_PMKID_CANDIDATE_LIST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uCandidateListSize;
	public uint32 uCandidateListOffset;
}

[CRepr]
public struct DOT11_BSSID_CANDIDATE
{
	public uint8[6] BSSID;
	public uint32 uFlags;
}

[CRepr]
public struct DOT11_PHY_STATE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uPhyId;
	public BOOLEAN bHardwarePhyState;
	public BOOLEAN bSoftwarePhyState;
}

[CRepr]
public struct DOT11_LINK_QUALITY_ENTRY
{
	public uint8[6] PeerMacAddr;
	public uint8 ucLinkQuality;
}

[CRepr]
public struct DOT11_LINK_QUALITY_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uLinkQualityListSize;
	public uint32 uLinkQualityListOffset;
}

[CRepr]
public struct DOT11_EXTSTA_SEND_CONTEXT
{
	public NDIS_OBJECT_HEADER Header;
	public uint16 usExemptionActionType;
	public uint32 uPhyId;
	public uint32 uDelayedSleepValue;
	public void* pvMediaSpecificInfo;
	public uint32 uSendFlags;
}

[CRepr]
public struct DOT11_EXTSTA_RECV_CONTEXT
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uReceiveFlags;
	public uint32 uPhyId;
	public uint32 uChCenterFrequency;
	public uint16 usNumberOfMPDUsReceived;
	public int32 lRSSI;
	public uint8 ucDataRate;
	public uint32 uSizeMediaSpecificInfo;
	public void* pvMediaSpecificInfo;
	public uint64 ullTimestamp;
}

[CRepr]
public struct DOT11_EXTAP_ATTRIBUTES
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uScanSSIDListSize;
	public uint32 uDesiredSSIDListSize;
	public uint32 uPrivacyExemptionListSize;
	public uint32 uAssociationTableSize;
	public uint32 uDefaultKeyTableSize;
	public uint32 uWEPKeyValueMaxLength;
	public BOOLEAN bStrictlyOrderedServiceClassImplemented;
	public uint32 uNumSupportedCountryOrRegionStrings;
	public uint8* pSupportedCountryOrRegionStrings;
	public uint32 uInfraNumSupportedUcastAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pInfraSupportedUcastAlgoPairs;
	public uint32 uInfraNumSupportedMcastAlgoPairs;
	public DOT11_AUTH_CIPHER_PAIR* pInfraSupportedMcastAlgoPairs;
}

[CRepr]
public struct DOT11_INCOMING_ASSOC_STARTED_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMacAddr;
}

[CRepr]
public struct DOT11_INCOMING_ASSOC_REQUEST_RECEIVED_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMacAddr;
	public BOOLEAN bReAssocReq;
	public uint32 uAssocReqOffset;
	public uint32 uAssocReqSize;
}

[CRepr]
public struct DOT11_INCOMING_ASSOC_COMPLETION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMacAddr;
	public uint32 uStatus;
	public uint8 ucErrorSource;
	public BOOLEAN bReAssocReq;
	public BOOLEAN bReAssocResp;
	public uint32 uAssocReqOffset;
	public uint32 uAssocReqSize;
	public uint32 uAssocRespOffset;
	public uint32 uAssocRespSize;
	public DOT11_AUTH_ALGORITHM AuthAlgo;
	public DOT11_CIPHER_ALGORITHM UnicastCipher;
	public DOT11_CIPHER_ALGORITHM MulticastCipher;
	public uint32 uActivePhyListOffset;
	public uint32 uActivePhyListSize;
	public uint32 uBeaconOffset;
	public uint32 uBeaconSize;
}

[CRepr]
public struct DOT11_STOP_AP_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 ulReason;
}

[CRepr]
public struct DOT11_PHY_FREQUENCY_ADOPTED_PARAMETERS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 ulChannel;
		public uint32 ulFrequency;
	}
	public NDIS_OBJECT_HEADER Header;
	public uint32 ulPhyId;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DOT11_CAN_SUSTAIN_AP_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 ulReason;
}

[CRepr]
public struct DOT11_AVAILABLE_CHANNEL_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint32* uChannelNumber mut => &uChannelNumber_impl;
	private uint32[ANYSIZE_ARRAY] uChannelNumber_impl;
}

[CRepr]
public struct DOT11_AVAILABLE_FREQUENCY_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint32* uFrequencyValue mut => &uFrequencyValue_impl;
	private uint32[ANYSIZE_ARRAY] uFrequencyValue_impl;
}

[CRepr]
public struct DOT11_DISASSOCIATE_PEER_REQUEST
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMacAddr;
	public uint16 usReason;
}

[CRepr]
public struct DOT11_INCOMING_ASSOC_DECISION
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMacAddr;
	public BOOLEAN bAccept;
	public uint16 usReasonCode;
	public uint32 uAssocResponseIEsOffset;
	public uint32 uAssocResponseIEsLength;
}

[CRepr]
public struct DOT11_INCOMING_ASSOC_DECISION_V2
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerMacAddr;
	public BOOLEAN bAccept;
	public uint16 usReasonCode;
	public uint32 uAssocResponseIEsOffset;
	public uint32 uAssocResponseIEsLength;
	public uint8 WFDStatus;
}

[CRepr]
public struct DOT11_ADDITIONAL_IE
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uBeaconIEsOffset;
	public uint32 uBeaconIEsLength;
	public uint32 uResponseIEsOffset;
	public uint32 uResponseIEsLength;
}

[CRepr]
public struct DOT11_PEER_STATISTICS
{
	public uint64 ullDecryptSuccessCount;
	public uint64 ullDecryptFailureCount;
	public uint64 ullTxPacketSuccessCount;
	public uint64 ullTxPacketFailureCount;
	public uint64 ullRxPacketSuccessCount;
	public uint64 ullRxPacketFailureCount;
}

[CRepr]
public struct DOT11_PEER_INFO
{
	public uint8[6] MacAddress;
	public uint16 usCapabilityInformation;
	public DOT11_AUTH_ALGORITHM AuthAlgo;
	public DOT11_CIPHER_ALGORITHM UnicastCipherAlgo;
	public DOT11_CIPHER_ALGORITHM MulticastCipherAlgo;
	public BOOLEAN bWpsEnabled;
	public uint16 usListenInterval;
	public uint8[255] ucSupportedRates;
	public uint16 usAssociationID;
	public DOT11_ASSOCIATION_STATE AssociationState;
	public DOT11_POWER_MODE PowerMode;
	public LARGE_INTEGER liAssociationUpTime;
	public DOT11_PEER_STATISTICS Statistics;
}

[CRepr]
public struct DOT11_PEER_INFO_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_PEER_INFO* PeerInfo mut => &PeerInfo_impl;
	private DOT11_PEER_INFO[ANYSIZE_ARRAY] PeerInfo_impl;
}

[CRepr]
public struct DOT11_VWIFI_COMBINATION
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumInfrastructure;
	public uint32 uNumAdhoc;
	public uint32 uNumSoftAP;
}

[CRepr]
public struct DOT11_VWIFI_COMBINATION_V2
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumInfrastructure;
	public uint32 uNumAdhoc;
	public uint32 uNumSoftAP;
	public uint32 uNumVirtualStation;
}

[CRepr]
public struct DOT11_VWIFI_COMBINATION_V3
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumInfrastructure;
	public uint32 uNumAdhoc;
	public uint32 uNumSoftAP;
	public uint32 uNumVirtualStation;
	public uint32 uNumWFDGroup;
}

[CRepr]
public struct DOT11_VWIFI_ATTRIBUTES
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uTotalNumOfEntries;
	public DOT11_VWIFI_COMBINATION* Combinations mut => &Combinations_impl;
	private DOT11_VWIFI_COMBINATION[ANYSIZE_ARRAY] Combinations_impl;
}

[CRepr]
public struct DOT11_MAC_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uOpmodeMask;
}

[CRepr]
public struct DOT11_MAC_INFO
{
	public uint32 uReserved;
	public uint32 uNdisPortNumber;
	public uint8[6] MacAddr;
}

[CRepr]
public struct DOT11_WFD_ATTRIBUTES
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumConcurrentGORole;
	public uint32 uNumConcurrentClientRole;
	public uint32 WPSVersionsSupported;
	public BOOLEAN bServiceDiscoverySupported;
	public BOOLEAN bClientDiscoverabilitySupported;
	public BOOLEAN bInfrastructureManagementSupported;
	public uint32 uMaxSecondaryDeviceTypeListSize;
	public uint8[6] DeviceAddress;
	public uint32 uInterfaceAddressListCount;
	public uint8* pInterfaceAddressList;
	public uint32 uNumSupportedCountryOrRegionStrings;
	public uint8* pSupportedCountryOrRegionStrings;
	public uint32 uDiscoveryFilterListSize;
	public uint32 uGORoleClientTableSize;
}

[CRepr]
public struct DOT11_WFD_DEVICE_TYPE
{
	public uint16 CategoryID;
	public uint16 SubCategoryID;
	public uint8[4] OUI;
}

[CRepr]
public struct DOT11_WPS_DEVICE_NAME
{
	public uint32 uDeviceNameLength;
	public uint8[32] ucDeviceName;
}

[CRepr]
public struct DOT11_WFD_CONFIGURATION_TIMEOUT
{
	public uint8 GOTimeout;
	public uint8 ClientTimeout;
}

[CRepr]
public struct DOT11_WFD_GROUP_ID
{
	public uint8[6] DeviceAddress;
	public DOT11_SSID SSID;
}

[CRepr]
public struct DOT11_WFD_GO_INTENT
{
	public uint8 _bitfield;
}

[CRepr]
public struct DOT11_WFD_CHANNEL
{
	public uint8[3] CountryRegionString;
	public uint8 OperatingClass;
	public uint8 ChannelNumber;
}

[CRepr]
public struct WFDSVC_CONNECTION_CAPABILITY
{
	public BOOLEAN bNew;
	public BOOLEAN bClient;
	public BOOLEAN bGO;
}

[CRepr]
public struct DOT11_WFD_SERVICE_HASH_LIST
{
	public uint16 ServiceHashCount;
	public uint8[6] ServiceHash;
}

[CRepr]
public struct DOT11_WFD_ADVERTISEMENT_ID
{
	public uint32 AdvertisementID;
	public uint8[6] ServiceAddress;
}

[CRepr]
public struct DOT11_WFD_SESSION_ID
{
	public uint32 SessionID;
	public uint8[6] SessionAddress;
}

[CRepr]
public struct DOT11_WFD_ADVERTISED_SERVICE_DESCRIPTOR
{
	public uint32 AdvertisementID;
	public uint16 ConfigMethods;
	public uint8 ServiceNameLength;
	public uint8[255] ServiceName;
}

[CRepr]
public struct DOT11_WFD_ADVERTISED_SERVICE_LIST
{
	public uint16 ServiceCount;
	public DOT11_WFD_ADVERTISED_SERVICE_DESCRIPTOR* AdvertisedService mut => &AdvertisedService_impl;
	private DOT11_WFD_ADVERTISED_SERVICE_DESCRIPTOR[ANYSIZE_ARRAY] AdvertisedService_impl;
}

[CRepr]
public struct DOT11_WFD_DISCOVER_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public int32 Status;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public uint32 uListOffset;
	public uint32 uListLength;
}

[CRepr]
public struct DOT11_GO_NEGOTIATION_REQUEST_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_GO_NEGOTIATION_REQUEST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public void* RequestContext;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_GO_NEGOTIATION_RESPONSE_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_GO_NEGOTIATION_RESPONSE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public void* ResponseContext;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_GO_NEGOTIATION_CONFIRMATION_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_GO_NEGOTIATION_CONFIRMATION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_INVITATION_REQUEST_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8[6] ReceiverAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_INVITATION_REQUEST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] TransmitterDeviceAddress;
	public uint8[6] BSSID;
	public uint8 DialogToken;
	public void* RequestContext;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_INVITATION_RESPONSE_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] ReceiverDeviceAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_INVITATION_RESPONSE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] TransmitterDeviceAddress;
	public uint8[6] BSSID;
	public uint8 DialogToken;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_PROVISION_DISCOVERY_REQUEST_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8[6] ReceiverAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_PROVISION_DISCOVERY_REQUEST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] TransmitterDeviceAddress;
	public uint8[6] BSSID;
	public uint8 DialogToken;
	public void* RequestContext;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_PROVISION_DISCOVERY_RESPONSE_SEND_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] ReceiverDeviceAddress;
	public uint8 DialogToken;
	public int32 Status;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_RECEIVED_PROVISION_DISCOVERY_RESPONSE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] TransmitterDeviceAddress;
	public uint8[6] BSSID;
	public uint8 DialogToken;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_ANQP_QUERY_COMPLETE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_ANQP_QUERY_RESULT Status;
	public HANDLE hContext;
	public uint32 uResponseLength;
}

[CRepr]
public struct DOT11_WFD_DEVICE_CAPABILITY_CONFIG
{
	public NDIS_OBJECT_HEADER Header;
	public BOOLEAN bServiceDiscoveryEnabled;
	public BOOLEAN bClientDiscoverabilityEnabled;
	public BOOLEAN bConcurrentOperationSupported;
	public BOOLEAN bInfrastructureManagementEnabled;
	public BOOLEAN bDeviceLimitReached;
	public BOOLEAN bInvitationProcedureEnabled;
	public uint32 WPSVersionsEnabled;
}

[CRepr]
public struct DOT11_WFD_GROUP_OWNER_CAPABILITY_CONFIG
{
	public NDIS_OBJECT_HEADER Header;
	public BOOLEAN bPersistentGroupEnabled;
	public BOOLEAN bIntraBSSDistributionSupported;
	public BOOLEAN bCrossConnectionSupported;
	public BOOLEAN bPersistentReconnectSupported;
	public BOOLEAN bGroupFormationEnabled;
	public uint32 uMaximumGroupLimit;
}

[CRepr]
public struct DOT11_WFD_GROUP_OWNER_CAPABILITY_CONFIG_V2
{
	public NDIS_OBJECT_HEADER Header;
	public BOOLEAN bPersistentGroupEnabled;
	public BOOLEAN bIntraBSSDistributionSupported;
	public BOOLEAN bCrossConnectionSupported;
	public BOOLEAN bPersistentReconnectSupported;
	public BOOLEAN bGroupFormationEnabled;
	public uint32 uMaximumGroupLimit;
	public BOOLEAN bEapolKeyIpAddressAllocationSupported;
}

[CRepr]
public struct DOT11_WFD_DEVICE_INFO
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] DeviceAddress;
	public uint16 ConfigMethods;
	public DOT11_WFD_DEVICE_TYPE PrimaryDeviceType;
	public DOT11_WPS_DEVICE_NAME DeviceName;
}

[CRepr]
public struct DOT11_WFD_SECONDARY_DEVICE_TYPE_LIST
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uNumOfEntries;
	public uint32 uTotalNumOfEntries;
	public DOT11_WFD_DEVICE_TYPE* SecondaryDeviceTypes mut => &SecondaryDeviceTypes_impl;
	private DOT11_WFD_DEVICE_TYPE[ANYSIZE_ARRAY] SecondaryDeviceTypes_impl;
}

[CRepr]
public struct DOT11_WFD_DISCOVER_DEVICE_FILTER
{
	public uint8[6] DeviceID;
	public uint8 ucBitmask;
	public DOT11_SSID GroupSSID;
}

[CRepr]
public struct DOT11_WFD_DISCOVER_REQUEST
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_WFD_DISCOVER_TYPE DiscoverType;
	public DOT11_WFD_SCAN_TYPE ScanType;
	public uint32 uDiscoverTimeout;
	public uint32 uDeviceFilterListOffset;
	public uint32 uNumDeviceFilters;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
	public BOOLEAN bForceScanLegacyNetworks;
}

[CRepr]
public struct DOT11_WFD_DEVICE_ENTRY
{
	public uint32 uPhyId;
	public DOT11_BSS_ENTRY_PHY_SPECIFIC_INFO PhySpecificInfo;
	public uint8[6] dot11BSSID;
	public DOT11_BSS_TYPE dot11BSSType;
	public uint8[6] TransmitterAddress;
	public int32 lRSSI;
	public uint32 uLinkQuality;
	public uint16 usBeaconPeriod;
	public uint64 ullTimestamp;
	public uint64 ullBeaconHostTimestamp;
	public uint64 ullProbeResponseHostTimestamp;
	public uint16 usCapabilityInformation;
	public uint32 uBeaconIEsOffset;
	public uint32 uBeaconIEsLength;
	public uint32 uProbeResponseIEsOffset;
	public uint32 uProbeResponseIEsLength;
}

[CRepr]
public struct DOT11_WFD_ADDITIONAL_IE
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 uBeaconIEsOffset;
	public uint32 uBeaconIEsLength;
	public uint32 uProbeResponseIEsOffset;
	public uint32 uProbeResponseIEsLength;
	public uint32 uDefaultRequestIEsOffset;
	public uint32 uDefaultRequestIEsLength;
}

[CRepr]
public struct DOT11_SEND_GO_NEGOTIATION_REQUEST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public uint32 uSendTimeout;
	public DOT11_WFD_GO_INTENT GroupOwnerIntent;
	public DOT11_WFD_CONFIGURATION_TIMEOUT MinimumConfigTimeout;
	public uint8[6] IntendedInterfaceAddress;
	public uint8 GroupCapability;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_SEND_GO_NEGOTIATION_RESPONSE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public void* RequestContext;
	public uint32 uSendTimeout;
	public uint8 Status;
	public DOT11_WFD_GO_INTENT GroupOwnerIntent;
	public DOT11_WFD_CONFIGURATION_TIMEOUT MinimumConfigTimeout;
	public uint8[6] IntendedInterfaceAddress;
	public uint8 GroupCapability;
	public DOT11_WFD_GROUP_ID GroupID;
	public BOOLEAN bUseGroupID;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_SEND_GO_NEGOTIATION_CONFIRMATION_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] PeerDeviceAddress;
	public uint8 DialogToken;
	public void* ResponseContext;
	public uint32 uSendTimeout;
	public uint8 Status;
	public uint8 GroupCapability;
	public DOT11_WFD_GROUP_ID GroupID;
	public BOOLEAN bUseGroupID;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_WFD_INVITATION_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct DOT11_SEND_INVITATION_REQUEST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8 DialogToken;
	public uint8[6] PeerDeviceAddress;
	public uint32 uSendTimeout;
	public DOT11_WFD_CONFIGURATION_TIMEOUT MinimumConfigTimeout;
	public DOT11_WFD_INVITATION_FLAGS InvitationFlags;
	public uint8[6] GroupBSSID;
	public BOOLEAN bUseGroupBSSID;
	public DOT11_WFD_CHANNEL OperatingChannel;
	public BOOLEAN bUseSpecifiedOperatingChannel;
	public DOT11_WFD_GROUP_ID GroupID;
	public BOOLEAN bLocalGO;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_SEND_INVITATION_RESPONSE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] ReceiverDeviceAddress;
	public uint8 DialogToken;
	public void* RequestContext;
	public uint32 uSendTimeout;
	public uint8 Status;
	public DOT11_WFD_CONFIGURATION_TIMEOUT MinimumConfigTimeout;
	public uint8[6] GroupBSSID;
	public BOOLEAN bUseGroupBSSID;
	public DOT11_WFD_CHANNEL OperatingChannel;
	public BOOLEAN bUseSpecifiedOperatingChannel;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_SEND_PROVISION_DISCOVERY_REQUEST_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8 DialogToken;
	public uint8[6] PeerDeviceAddress;
	public uint32 uSendTimeout;
	public uint8 GroupCapability;
	public DOT11_WFD_GROUP_ID GroupID;
	public BOOLEAN bUseGroupID;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_SEND_PROVISION_DISCOVERY_RESPONSE_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public uint8[6] ReceiverDeviceAddress;
	public uint8 DialogToken;
	public void* RequestContext;
	public uint32 uSendTimeout;
	public uint32 uIEsOffset;
	public uint32 uIEsLength;
}

[CRepr]
public struct DOT11_WFD_DEVICE_LISTEN_CHANNEL
{
	public NDIS_OBJECT_HEADER Header;
	public uint8 ChannelNumber;
}

[CRepr]
public struct DOT11_WFD_GROUP_START_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_WFD_CHANNEL AdvertisedOperatingChannel;
}

[CRepr]
public struct DOT11_WFD_GROUP_JOIN_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_WFD_CHANNEL GOOperatingChannel;
	public uint32 GOConfigTime;
	public BOOLEAN bInGroupFormation;
	public BOOLEAN bWaitForWPSReady;
}

[CRepr]
public struct DOT11_POWER_MGMT_AUTO_MODE_ENABLED_INFO
{
	public NDIS_OBJECT_HEADER Header;
	public BOOLEAN bEnabled;
}

[CRepr]
public struct DOT11_POWER_MGMT_MODE_STATUS_INFO
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_POWER_MODE PowerSaveMode;
	public uint32 uPowerSaveLevel;
	public DOT11_POWER_MODE_REASON Reason;
}

[CRepr]
public struct DOT11_CHANNEL_HINT
{
	public DOT11_PHY_TYPE Dot11PhyType;
	public uint32 uChannelNumber;
}

[CRepr]
public struct DOT11_OFFLOAD_NETWORK
{
	public DOT11_SSID Ssid;
	public DOT11_CIPHER_ALGORITHM UnicastCipher;
	public DOT11_AUTH_ALGORITHM AuthAlgo;
	public DOT11_CHANNEL_HINT[4] Dot11ChannelHints;
}

[CRepr]
public struct DOT11_OFFLOAD_NETWORK_LIST_INFO
{
	public NDIS_OBJECT_HEADER Header;
	public uint32 ulFlags;
	public uint32 FastScanPeriod;
	public uint32 FastScanIterations;
	public uint32 SlowScanPeriod;
	public uint32 uNumOfEntries;
	public DOT11_OFFLOAD_NETWORK* offloadNetworkList mut => &offloadNetworkList_impl;
	private DOT11_OFFLOAD_NETWORK[ANYSIZE_ARRAY] offloadNetworkList_impl;
}

[CRepr]
public struct DOT11_OFFLOAD_NETWORK_STATUS_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public int32 Status;
}

[CRepr]
public struct DOT11_MANUFACTURING_TEST
{
	public DOT11_MANUFACTURING_TEST_TYPE dot11ManufacturingTestType;
	public uint32 uBufferLength;
	public uint8* ucBuffer mut => &ucBuffer_impl;
	private uint8[ANYSIZE_ARRAY] ucBuffer_impl;
}

[CRepr]
public struct DOT11_MANUFACTURING_SELF_TEST_SET_PARAMS
{
	public DOT11_MANUFACTURING_SELF_TEST_TYPE SelfTestType;
	public uint32 uTestID;
	public uint32 uPinBitMask;
	public void* pvContext;
	public uint32 uBufferLength;
	public uint8* ucBufferIn mut => &ucBufferIn_impl;
	private uint8[ANYSIZE_ARRAY] ucBufferIn_impl;
}

[CRepr]
public struct DOT11_MANUFACTURING_SELF_TEST_QUERY_RESULTS
{
	public DOT11_MANUFACTURING_SELF_TEST_TYPE SelfTestType;
	public uint32 uTestID;
	public BOOLEAN bResult;
	public uint32 uPinFailedBitMask;
	public void* pvContext;
	public uint32 uBytesWrittenOut;
	public uint8* ucBufferOut mut => &ucBufferOut_impl;
	private uint8[ANYSIZE_ARRAY] ucBufferOut_impl;
}

[CRepr]
public struct DOT11_MANUFACTURING_FUNCTIONAL_TEST_RX
{
	public BOOLEAN bEnabled;
	public DOT11_BAND Dot11Band;
	public uint32 uChannel;
	public int32 PowerLevel;
}

[CRepr]
public struct DOT11_MANUFACTURING_FUNCTIONAL_TEST_TX
{
	public BOOLEAN bEnable;
	public BOOLEAN bOpenLoop;
	public DOT11_BAND Dot11Band;
	public uint32 uChannel;
	public uint32 uSetPowerLevel;
	public int32 ADCPowerLevel;
}

[CRepr]
public struct DOT11_MANUFACTURING_FUNCTIONAL_TEST_QUERY_ADC
{
	public DOT11_BAND Dot11Band;
	public uint32 uChannel;
	public int32 ADCPowerLevel;
}

[CRepr]
public struct DOT11_MANUFACTURING_TEST_SET_DATA
{
	public uint32 uKey;
	public uint32 uOffset;
	public uint32 uBufferLength;
	public uint8* ucBufferIn mut => &ucBufferIn_impl;
	private uint8[ANYSIZE_ARRAY] ucBufferIn_impl;
}

[CRepr]
public struct DOT11_MANUFACTURING_TEST_QUERY_DATA
{
	public uint32 uKey;
	public uint32 uOffset;
	public uint32 uBufferLength;
	public uint32 uBytesRead;
	public uint8* ucBufferOut mut => &ucBufferOut_impl;
	private uint8[ANYSIZE_ARRAY] ucBufferOut_impl;
}

[CRepr]
public struct DOT11_MANUFACTURING_TEST_SLEEP
{
	public uint32 uSleepTime;
	public void* pvContext;
}

[CRepr]
public struct DOT11_MANUFACTURING_CALLBACK_PARAMETERS
{
	public NDIS_OBJECT_HEADER Header;
	public DOT11_MANUFACTURING_CALLBACK_TYPE dot11ManufacturingCallbackType;
	public uint32 uStatus;
	public void* pvContext;
}

[CRepr]
public struct L2_NOTIFICATION_DATA
{
	public uint32 NotificationSource;
	public uint32 NotificationCode;
	public Guid InterfaceGuid;
	public uint32 dwDataSize;
	public void* pData;
}

[CRepr]
public struct WLAN_PROFILE_INFO
{
	public char16[256] strProfileName;
	public uint32 dwFlags;
}

[CRepr]
public struct DOT11_NETWORK
{
	public DOT11_SSID dot11Ssid;
	public DOT11_BSS_TYPE dot11BssType;
}

[CRepr]
public struct WLAN_RAW_DATA
{
	public uint32 dwDataSize;
	public uint8* DataBlob mut => &DataBlob_impl;
	private uint8[ANYSIZE_ARRAY] DataBlob_impl;
}

[CRepr]
public struct WLAN_RAW_DATA_LIST
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 dwDataOffset;
		public uint32 dwDataSize;
	}
	public uint32 dwTotalSize;
	public uint32 dwNumberOfItems;
	public _Anonymous_e__Struct* DataList mut => &DataList_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] DataList_impl;
}

[CRepr]
public struct WLAN_RATE_SET
{
	public uint32 uRateSetLength;
	public uint16[126] usRateSet;
}

[CRepr]
public struct WLAN_AVAILABLE_NETWORK
{
	public char16[256] strProfileName;
	public DOT11_SSID dot11Ssid;
	public DOT11_BSS_TYPE dot11BssType;
	public uint32 uNumberOfBssids;
	public BOOL bNetworkConnectable;
	public uint32 wlanNotConnectableReason;
	public uint32 uNumberOfPhyTypes;
	public DOT11_PHY_TYPE[8] dot11PhyTypes;
	public BOOL bMorePhyTypes;
	public uint32 wlanSignalQuality;
	public BOOL bSecurityEnabled;
	public DOT11_AUTH_ALGORITHM dot11DefaultAuthAlgorithm;
	public DOT11_CIPHER_ALGORITHM dot11DefaultCipherAlgorithm;
	public uint32 dwFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct WLAN_AVAILABLE_NETWORK_V2
{
	public char16[256] strProfileName;
	public DOT11_SSID dot11Ssid;
	public DOT11_BSS_TYPE dot11BssType;
	public uint32 uNumberOfBssids;
	public BOOL bNetworkConnectable;
	public uint32 wlanNotConnectableReason;
	public uint32 uNumberOfPhyTypes;
	public DOT11_PHY_TYPE[8] dot11PhyTypes;
	public BOOL bMorePhyTypes;
	public uint32 wlanSignalQuality;
	public BOOL bSecurityEnabled;
	public DOT11_AUTH_ALGORITHM dot11DefaultAuthAlgorithm;
	public DOT11_CIPHER_ALGORITHM dot11DefaultCipherAlgorithm;
	public uint32 dwFlags;
	public DOT11_ACCESSNETWORKOPTIONS AccessNetworkOptions;
	public uint8[6] dot11HESSID;
	public DOT11_VENUEINFO VenueInfo;
	public uint32 dwReserved;
}

[CRepr]
public struct WLAN_BSS_ENTRY
{
	public DOT11_SSID dot11Ssid;
	public uint32 uPhyId;
	public uint8[6] dot11Bssid;
	public DOT11_BSS_TYPE dot11BssType;
	public DOT11_PHY_TYPE dot11BssPhyType;
	public int32 lRssi;
	public uint32 uLinkQuality;
	public BOOLEAN bInRegDomain;
	public uint16 usBeaconPeriod;
	public uint64 ullTimestamp;
	public uint64 ullHostTimestamp;
	public uint16 usCapabilityInformation;
	public uint32 ulChCenterFrequency;
	public WLAN_RATE_SET wlanRateSet;
	public uint32 ulIeOffset;
	public uint32 ulIeSize;
}

[CRepr]
public struct WLAN_BSS_LIST
{
	public uint32 dwTotalSize;
	public uint32 dwNumberOfItems;
	public WLAN_BSS_ENTRY* wlanBssEntries mut => &wlanBssEntries_impl;
	private WLAN_BSS_ENTRY[ANYSIZE_ARRAY] wlanBssEntries_impl;
}

[CRepr]
public struct WLAN_INTERFACE_INFO
{
	public Guid InterfaceGuid;
	public char16[256] strInterfaceDescription;
	public WLAN_INTERFACE_STATE isState;
}

[CRepr]
public struct WLAN_ASSOCIATION_ATTRIBUTES
{
	public DOT11_SSID dot11Ssid;
	public DOT11_BSS_TYPE dot11BssType;
	public uint8[6] dot11Bssid;
	public DOT11_PHY_TYPE dot11PhyType;
	public uint32 uDot11PhyIndex;
	public uint32 wlanSignalQuality;
	public uint32 ulRxRate;
	public uint32 ulTxRate;
}

[CRepr]
public struct WLAN_SECURITY_ATTRIBUTES
{
	public BOOL bSecurityEnabled;
	public BOOL bOneXEnabled;
	public DOT11_AUTH_ALGORITHM dot11AuthAlgorithm;
	public DOT11_CIPHER_ALGORITHM dot11CipherAlgorithm;
}

[CRepr]
public struct WLAN_CONNECTION_ATTRIBUTES
{
	public WLAN_INTERFACE_STATE isState;
	public WLAN_CONNECTION_MODE wlanConnectionMode;
	public char16[256] strProfileName;
	public WLAN_ASSOCIATION_ATTRIBUTES wlanAssociationAttributes;
	public WLAN_SECURITY_ATTRIBUTES wlanSecurityAttributes;
}

[CRepr]
public struct WLAN_PHY_RADIO_STATE
{
	public uint32 dwPhyIndex;
	public DOT11_RADIO_STATE dot11SoftwareRadioState;
	public DOT11_RADIO_STATE dot11HardwareRadioState;
}

[CRepr]
public struct WLAN_RADIO_STATE
{
	public uint32 dwNumberOfPhys;
	public WLAN_PHY_RADIO_STATE[64] PhyRadioState;
}

[CRepr]
public struct WLAN_INTERFACE_CAPABILITY
{
	public WLAN_INTERFACE_TYPE interfaceType;
	public BOOL bDot11DSupported;
	public uint32 dwMaxDesiredSsidListSize;
	public uint32 dwMaxDesiredBssidListSize;
	public uint32 dwNumberOfSupportedPhys;
	public DOT11_PHY_TYPE[64] dot11PhyTypes;
}

[CRepr]
public struct WLAN_AUTH_CIPHER_PAIR_LIST
{
	public uint32 dwNumberOfItems;
	public DOT11_AUTH_CIPHER_PAIR* pAuthCipherPairList mut => &pAuthCipherPairList_impl;
	private DOT11_AUTH_CIPHER_PAIR[ANYSIZE_ARRAY] pAuthCipherPairList_impl;
}

[CRepr]
public struct WLAN_COUNTRY_OR_REGION_STRING_LIST
{
	public uint32 dwNumberOfItems;
	public uint8[3] pCountryOrRegionStringList;
}

[CRepr]
public struct WLAN_PROFILE_INFO_LIST
{
	public uint32 dwNumberOfItems;
	public uint32 dwIndex;
	public WLAN_PROFILE_INFO* ProfileInfo mut => &ProfileInfo_impl;
	private WLAN_PROFILE_INFO[ANYSIZE_ARRAY] ProfileInfo_impl;
}

[CRepr]
public struct WLAN_AVAILABLE_NETWORK_LIST
{
	public uint32 dwNumberOfItems;
	public uint32 dwIndex;
	public WLAN_AVAILABLE_NETWORK* Network mut => &Network_impl;
	private WLAN_AVAILABLE_NETWORK[ANYSIZE_ARRAY] Network_impl;
}

[CRepr]
public struct WLAN_AVAILABLE_NETWORK_LIST_V2
{
	public uint32 dwNumberOfItems;
	public uint32 dwIndex;
	public WLAN_AVAILABLE_NETWORK_V2* Network mut => &Network_impl;
	private WLAN_AVAILABLE_NETWORK_V2[ANYSIZE_ARRAY] Network_impl;
}

[CRepr]
public struct WLAN_INTERFACE_INFO_LIST
{
	public uint32 dwNumberOfItems;
	public uint32 dwIndex;
	public WLAN_INTERFACE_INFO* InterfaceInfo mut => &InterfaceInfo_impl;
	private WLAN_INTERFACE_INFO[ANYSIZE_ARRAY] InterfaceInfo_impl;
}

[CRepr]
public struct DOT11_NETWORK_LIST
{
	public uint32 dwNumberOfItems;
	public uint32 dwIndex;
	public DOT11_NETWORK* Network mut => &Network_impl;
	private DOT11_NETWORK[ANYSIZE_ARRAY] Network_impl;
}

[CRepr]
public struct WLAN_CONNECTION_PARAMETERS
{
	public WLAN_CONNECTION_MODE wlanConnectionMode;
	public PWSTR strProfile;
	public DOT11_SSID* pDot11Ssid;
	public DOT11_BSSID_LIST* pDesiredBssidList;
	public DOT11_BSS_TYPE dot11BssType;
	public uint32 dwFlags;
}

[CRepr]
public struct WLAN_CONNECTION_PARAMETERS_V2
{
	public WLAN_CONNECTION_MODE wlanConnectionMode;
	public PWSTR strProfile;
	public DOT11_SSID* pDot11Ssid;
	public uint8* pDot11Hessid;
	public DOT11_BSSID_LIST* pDesiredBssidList;
	public DOT11_BSS_TYPE dot11BssType;
	public uint32 dwFlags;
	public DOT11_ACCESSNETWORKOPTIONS* pDot11AccessNetworkOptions;
}

[CRepr]
public struct WLAN_MSM_NOTIFICATION_DATA
{
	public WLAN_CONNECTION_MODE wlanConnectionMode;
	public char16[256] strProfileName;
	public DOT11_SSID dot11Ssid;
	public DOT11_BSS_TYPE dot11BssType;
	public uint8[6] dot11MacAddr;
	public BOOL bSecurityEnabled;
	public BOOL bFirstPeer;
	public BOOL bLastPeer;
	public uint32 wlanReasonCode;
}

[CRepr]
public struct WLAN_CONNECTION_NOTIFICATION_DATA
{
	public WLAN_CONNECTION_MODE wlanConnectionMode;
	public char16[256] strProfileName;
	public DOT11_SSID dot11Ssid;
	public DOT11_BSS_TYPE dot11BssType;
	public BOOL bSecurityEnabled;
	public uint32 wlanReasonCode;
	public WLAN_CONNECTION_NOTIFICATION_FLAGS dwFlags;
	public char16* strProfileXml mut => &strProfileXml_impl;
	private char16[ANYSIZE_ARRAY] strProfileXml_impl;
}

[CRepr]
public struct WLAN_DEVICE_SERVICE_NOTIFICATION_DATA
{
	public Guid DeviceService;
	public uint32 dwOpCode;
	public uint32 dwDataSize;
	public uint8* DataBlob mut => &DataBlob_impl;
	private uint8[ANYSIZE_ARRAY] DataBlob_impl;
}

[CRepr]
public struct WLAN_PHY_FRAME_STATISTICS
{
	public uint64 ullTransmittedFrameCount;
	public uint64 ullMulticastTransmittedFrameCount;
	public uint64 ullFailedCount;
	public uint64 ullRetryCount;
	public uint64 ullMultipleRetryCount;
	public uint64 ullMaxTXLifetimeExceededCount;
	public uint64 ullTransmittedFragmentCount;
	public uint64 ullRTSSuccessCount;
	public uint64 ullRTSFailureCount;
	public uint64 ullACKFailureCount;
	public uint64 ullReceivedFrameCount;
	public uint64 ullMulticastReceivedFrameCount;
	public uint64 ullPromiscuousReceivedFrameCount;
	public uint64 ullMaxRXLifetimeExceededCount;
	public uint64 ullFrameDuplicateCount;
	public uint64 ullReceivedFragmentCount;
	public uint64 ullPromiscuousReceivedFragmentCount;
	public uint64 ullFCSErrorCount;
}

[CRepr]
public struct WLAN_MAC_FRAME_STATISTICS
{
	public uint64 ullTransmittedFrameCount;
	public uint64 ullReceivedFrameCount;
	public uint64 ullWEPExcludedCount;
	public uint64 ullTKIPLocalMICFailures;
	public uint64 ullTKIPReplays;
	public uint64 ullTKIPICVErrorCount;
	public uint64 ullCCMPReplays;
	public uint64 ullCCMPDecryptErrors;
	public uint64 ullWEPUndecryptableCount;
	public uint64 ullWEPICVErrorCount;
	public uint64 ullDecryptSuccessCount;
	public uint64 ullDecryptFailureCount;
}

[CRepr]
public struct WLAN_STATISTICS
{
	public uint64 ullFourWayHandshakeFailures;
	public uint64 ullTKIPCounterMeasuresInvoked;
	public uint64 ullReserved;
	public WLAN_MAC_FRAME_STATISTICS MacUcastCounters;
	public WLAN_MAC_FRAME_STATISTICS MacMcastCounters;
	public uint32 dwNumberOfPhys;
	public WLAN_PHY_FRAME_STATISTICS* PhyCounters mut => &PhyCounters_impl;
	private WLAN_PHY_FRAME_STATISTICS[ANYSIZE_ARRAY] PhyCounters_impl;
}

[CRepr]
public struct WLAN_DEVICE_SERVICE_GUID_LIST
{
	public uint32 dwNumberOfItems;
	public uint32 dwIndex;
	public Guid* DeviceService mut => &DeviceService_impl;
	private Guid[ANYSIZE_ARRAY] DeviceService_impl;
}

[CRepr]
public struct WFD_GROUP_ID
{
	public uint8[6] DeviceAddress;
	public DOT11_SSID GroupSSID;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_PEER_STATE
{
	public uint8[6] PeerMacAddress;
	public WLAN_HOSTED_NETWORK_PEER_AUTH_STATE PeerAuthState;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_RADIO_STATE
{
	public DOT11_RADIO_STATE dot11SoftwareRadioState;
	public DOT11_RADIO_STATE dot11HardwareRadioState;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_STATE_CHANGE
{
	public WLAN_HOSTED_NETWORK_STATE OldState;
	public WLAN_HOSTED_NETWORK_STATE NewState;
	public WLAN_HOSTED_NETWORK_REASON StateChangeReason;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_DATA_PEER_STATE_CHANGE
{
	public WLAN_HOSTED_NETWORK_PEER_STATE OldState;
	public WLAN_HOSTED_NETWORK_PEER_STATE NewState;
	public WLAN_HOSTED_NETWORK_REASON PeerStateChangeReason;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_CONNECTION_SETTINGS
{
	public DOT11_SSID hostedNetworkSSID;
	public uint32 dwMaxNumberOfPeers;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_SECURITY_SETTINGS
{
	public DOT11_AUTH_ALGORITHM dot11AuthAlgo;
	public DOT11_CIPHER_ALGORITHM dot11CipherAlgo;
}

[CRepr]
public struct WLAN_HOSTED_NETWORK_STATUS
{
	public WLAN_HOSTED_NETWORK_STATE HostedNetworkState;
	public Guid IPDeviceID;
	public uint8[6] wlanHostedNetworkBSSID;
	public DOT11_PHY_TYPE dot11PhyType;
	public uint32 ulChannelFrequency;
	public uint32 dwNumberOfPeers;
	public WLAN_HOSTED_NETWORK_PEER_STATE* PeerList mut => &PeerList_impl;
	private WLAN_HOSTED_NETWORK_PEER_STATE[ANYSIZE_ARRAY] PeerList_impl;
}

[CRepr]
public struct ONEX_VARIABLE_BLOB
{
	public uint32 dwSize;
	public uint32 dwOffset;
}

[CRepr]
public struct ONEX_AUTH_PARAMS
{
	public BOOL fUpdatePending;
	public ONEX_VARIABLE_BLOB oneXConnProfile;
	public ONEX_AUTH_IDENTITY authIdentity;
	public uint32 dwQuarantineState;
	public uint32 _bitfield;
	public uint32 dwSessionId;
	public HANDLE hUserToken;
	public ONEX_VARIABLE_BLOB OneXUserProfile;
	public ONEX_VARIABLE_BLOB Identity;
	public ONEX_VARIABLE_BLOB UserName;
	public ONEX_VARIABLE_BLOB Domain;
}

[CRepr]
public struct ONEX_EAP_ERROR
{
	public uint32 dwWinError;
	public EAP_METHOD_TYPE type;
	public uint32 dwReasonCode;
	public Guid rootCauseGuid;
	public Guid repairGuid;
	public Guid helpLinkGuid;
	public uint32 _bitfield;
	public ONEX_VARIABLE_BLOB RootCauseString;
	public ONEX_VARIABLE_BLOB RepairString;
}

[CRepr]
public struct ONEX_STATUS
{
	public ONEX_AUTH_STATUS authStatus;
	public uint32 dwReason;
	public uint32 dwError;
}

[CRepr]
public struct ONEX_RESULT_UPDATE_DATA
{
	public ONEX_STATUS oneXStatus;
	public ONEX_EAP_METHOD_BACKEND_SUPPORT BackendSupport;
	public BOOL fBackendEngaged;
	public uint32 _bitfield;
	public ONEX_VARIABLE_BLOB authParams;
	public ONEX_VARIABLE_BLOB eapError;
}

[CRepr]
public struct ONEX_USER_INFO
{
	public ONEX_AUTH_IDENTITY authIdentity;
	public uint32 _bitfield;
	public ONEX_VARIABLE_BLOB UserName;
	public ONEX_VARIABLE_BLOB DomainName;
}

[CRepr]
public struct DOT11_ADAPTER
{
	public Guid gAdapterId;
	public PWSTR pszDescription;
	public DOT11_CURRENT_OPERATION_MODE Dot11CurrentOpMode;
}

[CRepr]
public struct DOT11_BSS_LIST
{
	public uint32 uNumOfBytes;
	public uint8* pucBuffer;
}

[CRepr]
public struct DOT11_PORT_STATE
{
	public uint8[6] PeerMacAddress;
	public uint32 uSessionId;
	public BOOL bPortControlled;
	public BOOL bPortAuthorized;
}

[CRepr, Packed(1)]
public struct DOT11_SECURITY_PACKET_HEADER
{
	public uint8[6] PeerMac;
	public uint16 usEtherType;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct DOT11_MSSECURITY_SETTINGS
{
	public DOT11_AUTH_ALGORITHM dot11AuthAlgorithm;
	public DOT11_CIPHER_ALGORITHM dot11CipherAlgorithm;
	public BOOL fOneXEnabled;
	public EAP_METHOD_TYPE eapMethodType;
	public uint32 dwEapConnectionDataLen;
	public uint8* pEapConnectionData;
}

[CRepr]
public struct DOT11EXT_IHV_SSID_LIST
{
	public uint32 ulCount;
	public DOT11_SSID* SSIDs mut => &SSIDs_impl;
	private DOT11_SSID[ANYSIZE_ARRAY] SSIDs_impl;
}

[CRepr]
public struct DOT11EXT_IHV_PROFILE_PARAMS
{
	public DOT11EXT_IHV_SSID_LIST* pSsidList;
	public DOT11_BSS_TYPE BssType;
	public DOT11_MSSECURITY_SETTINGS* pMSSecuritySettings;
}

[CRepr]
public struct DOT11EXT_IHV_PARAMS
{
	public DOT11EXT_IHV_PROFILE_PARAMS dot11ExtIhvProfileParams;
	public char16[256] wstrProfileName;
	public uint32 dwProfileTypeFlags;
	public Guid interfaceGuid;
}

[CRepr]
public struct DOT11_IHV_VERSION_INFO
{
	public uint32 dwVerMin;
	public uint32 dwVerMax;
}

[CRepr]
public struct DOT11EXT_IHV_UI_REQUEST
{
	public uint32 dwSessionId;
	public Guid guidUIRequest;
	public Guid UIPageClsid;
	public uint32 dwByteCount;
	public uint8* pvUIRequest;
}

[CRepr]
public struct DOT11_EAP_RESULT
{
	public uint32 dwFailureReasonCode;
	public EAP_ATTRIBUTES* pAttribArray;
}

[CRepr]
public struct DOT11_MSONEX_RESULT_PARAMS
{
	public ONEX_AUTH_STATUS Dot11OnexAuthStatus;
	public ONEX_REASON_CODE Dot11OneXReasonCode;
	public uint8* pbMPPESendKey;
	public uint32 dwMPPESendKeyLen;
	public uint8* pbMPPERecvKey;
	public uint32 dwMPPERecvKeyLen;
	public DOT11_EAP_RESULT* pDot11EapResult;
}

[CRepr]
public struct DOT11EXT_IHV_CONNECTIVITY_PROFILE
{
	public PWSTR pszXmlFragmentIhvConnectivity;
}

[CRepr]
public struct DOT11EXT_IHV_SECURITY_PROFILE
{
	public PWSTR pszXmlFragmentIhvSecurity;
	public BOOL bUseMSOnex;
}

[CRepr]
public struct DOT11EXT_IHV_DISCOVERY_PROFILE
{
	public DOT11EXT_IHV_CONNECTIVITY_PROFILE IhvConnectivityProfile;
	public DOT11EXT_IHV_SECURITY_PROFILE IhvSecurityProfile;
}

[CRepr]
public struct DOT11EXT_IHV_DISCOVERY_PROFILE_LIST
{
	public uint32 dwCount;
	public DOT11EXT_IHV_DISCOVERY_PROFILE* pIhvDiscoveryProfiles;
}

[CRepr]
public struct DOT11EXT_VIRTUAL_STATION_AP_PROPERTY
{
	public DOT11_SSID dot11SSID;
	public DOT11_AUTH_ALGORITHM dot11AuthAlgo;
	public DOT11_CIPHER_ALGORITHM dot11CipherAlgo;
	public BOOL bIsPassPhrase;
	public uint32 dwKeyLength;
	public uint8[64] ucKeyData;
}

[CRepr]
public struct WDIAG_IHV_WLAN_ID
{
	public char16[256] strProfileName;
	public DOT11_SSID Ssid;
	public DOT11_BSS_TYPE BssType;
	public uint32 dwFlags;
	public uint32 dwReasonCode;
}

[CRepr]
public struct DOT11EXT_APIS
{
	public DOT11EXT_ALLOCATE_BUFFER Dot11ExtAllocateBuffer;
	public DOT11EXT_FREE_BUFFER Dot11ExtFreeBuffer;
	public DOT11EXT_SET_PROFILE_CUSTOM_USER_DATA Dot11ExtSetProfileCustomUserData;
	public DOT11EXT_GET_PROFILE_CUSTOM_USER_DATA Dot11ExtGetProfileCustomUserData;
	public DOT11EXT_SET_CURRENT_PROFILE Dot11ExtSetCurrentProfile;
	public DOT11EXT_SEND_UI_REQUEST Dot11ExtSendUIRequest;
	public DOT11EXT_PRE_ASSOCIATE_COMPLETION Dot11ExtPreAssociateCompletion;
	public DOT11EXT_POST_ASSOCIATE_COMPLETION Dot11ExtPostAssociateCompletion;
	public DOT11EXT_SEND_NOTIFICATION Dot11ExtSendNotification;
	public DOT11EXT_SEND_PACKET Dot11ExtSendPacket;
	public DOT11EXT_SET_ETHERTYPE_HANDLING Dot11ExtSetEtherTypeHandling;
	public DOT11EXT_SET_AUTH_ALGORITHM Dot11ExtSetAuthAlgorithm;
	public DOT11EXT_SET_UNICAST_CIPHER_ALGORITHM Dot11ExtSetUnicastCipherAlgorithm;
	public DOT11EXT_SET_MULTICAST_CIPHER_ALGORITHM Dot11ExtSetMulticastCipherAlgorithm;
	public DOT11EXT_SET_DEFAULT_KEY Dot11ExtSetDefaultKey;
	public DOT11EXT_SET_KEY_MAPPING_KEY Dot11ExtSetKeyMappingKey;
	public DOT11EXT_SET_DEFAULT_KEY_ID Dot11ExtSetDefaultKeyId;
	public DOT11EXT_NIC_SPECIFIC_EXTENSION Dot11ExtNicSpecificExtension;
	public DOT11EXT_SET_EXCLUDE_UNENCRYPTED Dot11ExtSetExcludeUnencrypted;
	public DOT11EXT_ONEX_START Dot11ExtStartOneX;
	public DOT11EXT_ONEX_STOP Dot11ExtStopOneX;
	public DOT11EXT_PROCESS_ONEX_PACKET Dot11ExtProcessSecurityPacket;
}

[CRepr]
public struct DOT11EXT_IHV_HANDLERS
{
	public DOT11EXTIHV_DEINIT_SERVICE Dot11ExtIhvDeinitService;
	public DOT11EXTIHV_INIT_ADAPTER Dot11ExtIhvInitAdapter;
	public DOT11EXTIHV_DEINIT_ADAPTER Dot11ExtIhvDeinitAdapter;
	public DOT11EXTIHV_PERFORM_PRE_ASSOCIATE Dot11ExtIhvPerformPreAssociate;
	public DOT11EXTIHV_ADAPTER_RESET Dot11ExtIhvAdapterReset;
	public DOT11EXTIHV_PERFORM_POST_ASSOCIATE Dot11ExtIhvPerformPostAssociate;
	public DOT11EXTIHV_STOP_POST_ASSOCIATE Dot11ExtIhvStopPostAssociate;
	public DOT11EXTIHV_VALIDATE_PROFILE Dot11ExtIhvValidateProfile;
	public DOT11EXTIHV_PERFORM_CAPABILITY_MATCH Dot11ExtIhvPerformCapabilityMatch;
	public DOT11EXTIHV_CREATE_DISCOVERY_PROFILES Dot11ExtIhvCreateDiscoveryProfiles;
	public DOT11EXTIHV_PROCESS_SESSION_CHANGE Dot11ExtIhvProcessSessionChange;
	public DOT11EXTIHV_RECEIVE_INDICATION Dot11ExtIhvReceiveIndication;
	public DOT11EXTIHV_RECEIVE_PACKET Dot11ExtIhvReceivePacket;
	public DOT11EXTIHV_SEND_PACKET_COMPLETION Dot11ExtIhvSendPacketCompletion;
	public DOT11EXTIHV_IS_UI_REQUEST_PENDING Dot11ExtIhvIsUIRequestPending;
	public DOT11EXTIHV_PROCESS_UI_RESPONSE Dot11ExtIhvProcessUIResponse;
	public DOT11EXTIHV_QUERY_UI_REQUEST Dot11ExtIhvQueryUIRequest;
	public DOT11EXTIHV_ONEX_INDICATE_RESULT Dot11ExtIhvOnexIndicateResult;
	public DOT11EXTIHV_CONTROL Dot11ExtIhvControl;
}

[CRepr]
public struct DOT11EXT_VIRTUAL_STATION_APIS
{
	public DOT11EXT_REQUEST_VIRTUAL_STATION Dot11ExtRequestVirtualStation;
	public DOT11EXT_RELEASE_VIRTUAL_STATION Dot11ExtReleaseVirtualStation;
	public DOT11EXT_QUERY_VIRTUAL_STATION_PROPERTIES Dot11ExtQueryVirtualStationProperties;
	public DOT11EXT_SET_VIRTUAL_STATION_AP_PROPERTIES Dot11ExtSetVirtualStationAPProperties;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_Dot11AdHocManager = .(0xdd06a84f, 0x83bd, 0x4d01, 0x8a, 0xb9, 0x23, 0x89, 0xfe, 0xa0, 0x86, 0x9e);


}
#endregion

#region COM Types
[CRepr]struct IDot11AdHocManager : IUnknown
{
	public new const Guid IID = .(0x8f10cc26, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Name, PWSTR Password, int32 GeographicalId, IDot11AdHocInterface* pInterface, IDot11AdHocSecuritySettings* pSecurity, Guid* pContextGuid, IDot11AdHocNetwork** pIAdHoc) CreateNetwork;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDot11AdHocNetwork* pIAdHoc, BOOLEAN fSaveProfile, BOOLEAN fMakeSavedProfileUserSpecific) CommitCreatedNetwork;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pContextGuid, IEnumDot11AdHocNetworks** ppEnum) GetIEnumDot11AdHocNetworks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDot11AdHocInterfaces** ppEnum) GetIEnumDot11AdHocInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* NetworkSignature, IDot11AdHocNetwork** pNetwork) GetNetwork;
	}


	public HRESULT CreateNetwork(PWSTR Name, PWSTR Password, int32 GeographicalId, IDot11AdHocInterface* pInterface, IDot11AdHocSecuritySettings* pSecurity, Guid* pContextGuid, IDot11AdHocNetwork** pIAdHoc) mut => VT.[Friend]CreateNetwork(&this, Name, Password, GeographicalId, pInterface, pSecurity, pContextGuid, pIAdHoc);

	public HRESULT CommitCreatedNetwork(IDot11AdHocNetwork* pIAdHoc, BOOLEAN fSaveProfile, BOOLEAN fMakeSavedProfileUserSpecific) mut => VT.[Friend]CommitCreatedNetwork(&this, pIAdHoc, fSaveProfile, fMakeSavedProfileUserSpecific);

	public HRESULT GetIEnumDot11AdHocNetworks(Guid* pContextGuid, IEnumDot11AdHocNetworks** ppEnum) mut => VT.[Friend]GetIEnumDot11AdHocNetworks(&this, pContextGuid, ppEnum);

	public HRESULT GetIEnumDot11AdHocInterfaces(IEnumDot11AdHocInterfaces** ppEnum) mut => VT.[Friend]GetIEnumDot11AdHocInterfaces(&this, ppEnum);

	public HRESULT GetNetwork(Guid* NetworkSignature, IDot11AdHocNetwork** pNetwork) mut => VT.[Friend]GetNetwork(&this, NetworkSignature, pNetwork);
}

[CRepr]struct IDot11AdHocManagerNotificationSink : IUnknown
{
	public new const Guid IID = .(0x8f10cc27, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDot11AdHocNetwork* pIAdHocNetwork) OnNetworkAdd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* Signature) OnNetworkRemove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDot11AdHocInterface* pIAdHocInterface) OnInterfaceAdd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* Signature) OnInterfaceRemove;
	}


	public HRESULT OnNetworkAdd(IDot11AdHocNetwork* pIAdHocNetwork) mut => VT.[Friend]OnNetworkAdd(&this, pIAdHocNetwork);

	public HRESULT OnNetworkRemove(Guid* Signature) mut => VT.[Friend]OnNetworkRemove(&this, Signature);

	public HRESULT OnInterfaceAdd(IDot11AdHocInterface* pIAdHocInterface) mut => VT.[Friend]OnInterfaceAdd(&this, pIAdHocInterface);

	public HRESULT OnInterfaceRemove(Guid* Signature) mut => VT.[Friend]OnInterfaceRemove(&this, Signature);
}

[CRepr]struct IEnumDot11AdHocNetworks : IUnknown
{
	public new const Guid IID = .(0x8f10cc28, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt, IDot11AdHocNetwork** rgElt, uint32* pcEltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDot11AdHocNetworks** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cElt, IDot11AdHocNetwork** rgElt, uint32* pcEltFetched) mut => VT.[Friend]Next(&this, cElt, rgElt, pcEltFetched);

	public HRESULT Skip(uint32 cElt) mut => VT.[Friend]Skip(&this, cElt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumDot11AdHocNetworks** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IDot11AdHocNetwork : IUnknown
{
	public new const Guid IID = .(0x8f10cc29, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_NETWORK_CONNECTION_STATUS* eStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwSSID) GetSSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pf11d) HasProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwProfileName) GetProfileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puStrengthValue, uint32* puStrengthMax) GetSignalQuality;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDot11AdHocSecuritySettings** pAdHocSecuritySetting) GetSecuritySetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pContextGuid) GetContextGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pSignature) GetSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDot11AdHocInterface** pAdHocInterface) GetInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Passphrase, int32 GeographicalId, BOOLEAN fSaveProfile, BOOLEAN fMakeSavedProfileUserSpecific) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
	}


	public HRESULT GetStatus(DOT11_ADHOC_NETWORK_CONNECTION_STATUS* eStatus) mut => VT.[Friend]GetStatus(&this, eStatus);

	public HRESULT GetSSID(PWSTR* ppszwSSID) mut => VT.[Friend]GetSSID(&this, ppszwSSID);

	public HRESULT HasProfile(uint8* pf11d) mut => VT.[Friend]HasProfile(&this, pf11d);

	public HRESULT GetProfileName(PWSTR* ppszwProfileName) mut => VT.[Friend]GetProfileName(&this, ppszwProfileName);

	public HRESULT DeleteProfile() mut => VT.[Friend]DeleteProfile(&this);

	public HRESULT GetSignalQuality(uint32* puStrengthValue, uint32* puStrengthMax) mut => VT.[Friend]GetSignalQuality(&this, puStrengthValue, puStrengthMax);

	public HRESULT GetSecuritySetting(IDot11AdHocSecuritySettings** pAdHocSecuritySetting) mut => VT.[Friend]GetSecuritySetting(&this, pAdHocSecuritySetting);

	public HRESULT GetContextGuid(Guid* pContextGuid) mut => VT.[Friend]GetContextGuid(&this, pContextGuid);

	public HRESULT GetSignature(Guid* pSignature) mut => VT.[Friend]GetSignature(&this, pSignature);

	public HRESULT GetInterface(IDot11AdHocInterface** pAdHocInterface) mut => VT.[Friend]GetInterface(&this, pAdHocInterface);

	public HRESULT Connect(PWSTR Passphrase, int32 GeographicalId, BOOLEAN fSaveProfile, BOOLEAN fMakeSavedProfileUserSpecific) mut => VT.[Friend]Connect(&this, Passphrase, GeographicalId, fSaveProfile, fMakeSavedProfileUserSpecific);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);
}

[CRepr]struct IDot11AdHocNetworkNotificationSink : IUnknown
{
	public new const Guid IID = .(0x8f10cc2a, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_NETWORK_CONNECTION_STATUS eStatus) OnStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_CONNECT_FAIL_REASON eFailReason) OnConnectFail;
	}


	public HRESULT OnStatusChange(DOT11_ADHOC_NETWORK_CONNECTION_STATUS eStatus) mut => VT.[Friend]OnStatusChange(&this, eStatus);

	public HRESULT OnConnectFail(DOT11_ADHOC_CONNECT_FAIL_REASON eFailReason) mut => VT.[Friend]OnConnectFail(&this, eFailReason);
}

[CRepr]struct IDot11AdHocInterface : IUnknown
{
	public new const Guid IID = .(0x8f10cc2b, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pSignature) GetDeviceSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pf11d) IsDot11d;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pfAdHocCapable) IsAdHocCapable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pfIsRadioOn) IsRadioOn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDot11AdHocNetwork** ppNetwork) GetActiveNetwork;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDot11AdHocSecuritySettings** ppEnum) GetIEnumSecuritySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pFilterGuid, IEnumDot11AdHocNetworks** ppEnum) GetIEnumDot11AdHocNetworks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_NETWORK_CONNECTION_STATUS* pState) GetStatus;
	}


	public HRESULT GetDeviceSignature(Guid* pSignature) mut => VT.[Friend]GetDeviceSignature(&this, pSignature);

	public HRESULT GetFriendlyName(PWSTR* ppszName) mut => VT.[Friend]GetFriendlyName(&this, ppszName);

	public HRESULT IsDot11d(uint8* pf11d) mut => VT.[Friend]IsDot11d(&this, pf11d);

	public HRESULT IsAdHocCapable(uint8* pfAdHocCapable) mut => VT.[Friend]IsAdHocCapable(&this, pfAdHocCapable);

	public HRESULT IsRadioOn(uint8* pfIsRadioOn) mut => VT.[Friend]IsRadioOn(&this, pfIsRadioOn);

	public HRESULT GetActiveNetwork(IDot11AdHocNetwork** ppNetwork) mut => VT.[Friend]GetActiveNetwork(&this, ppNetwork);

	public HRESULT GetIEnumSecuritySettings(IEnumDot11AdHocSecuritySettings** ppEnum) mut => VT.[Friend]GetIEnumSecuritySettings(&this, ppEnum);

	public HRESULT GetIEnumDot11AdHocNetworks(Guid* pFilterGuid, IEnumDot11AdHocNetworks** ppEnum) mut => VT.[Friend]GetIEnumDot11AdHocNetworks(&this, pFilterGuid, ppEnum);

	public HRESULT GetStatus(DOT11_ADHOC_NETWORK_CONNECTION_STATUS* pState) mut => VT.[Friend]GetStatus(&this, pState);
}

[CRepr]struct IEnumDot11AdHocInterfaces : IUnknown
{
	public new const Guid IID = .(0x8f10cc2c, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt, IDot11AdHocInterface** rgElt, uint32* pcEltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDot11AdHocInterfaces** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cElt, IDot11AdHocInterface** rgElt, uint32* pcEltFetched) mut => VT.[Friend]Next(&this, cElt, rgElt, pcEltFetched);

	public HRESULT Skip(uint32 cElt) mut => VT.[Friend]Skip(&this, cElt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumDot11AdHocInterfaces** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IEnumDot11AdHocSecuritySettings : IUnknown
{
	public new const Guid IID = .(0x8f10cc2d, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt, IDot11AdHocSecuritySettings** rgElt, uint32* pcEltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDot11AdHocSecuritySettings** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cElt, IDot11AdHocSecuritySettings** rgElt, uint32* pcEltFetched) mut => VT.[Friend]Next(&this, cElt, rgElt, pcEltFetched);

	public HRESULT Skip(uint32 cElt) mut => VT.[Friend]Skip(&this, cElt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumDot11AdHocSecuritySettings** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IDot11AdHocSecuritySettings : IUnknown
{
	public new const Guid IID = .(0x8f10cc2e, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_AUTH_ALGORITHM* pAuth) GetDot11AuthAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_CIPHER_ALGORITHM* pCipher) GetDot11CipherAlgorithm;
	}


	public HRESULT GetDot11AuthAlgorithm(DOT11_ADHOC_AUTH_ALGORITHM* pAuth) mut => VT.[Friend]GetDot11AuthAlgorithm(&this, pAuth);

	public HRESULT GetDot11CipherAlgorithm(DOT11_ADHOC_CIPHER_ALGORITHM* pCipher) mut => VT.[Friend]GetDot11CipherAlgorithm(&this, pCipher);
}

[CRepr]struct IDot11AdHocInterfaceNotificationSink : IUnknown
{
	public new const Guid IID = .(0x8f10cc2f, 0xcf0d, 0x42a0, 0xac, 0xbe, 0xe2, 0xde, 0x70, 0x07, 0x38, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOT11_ADHOC_NETWORK_CONNECTION_STATUS eStatus) OnConnectionStatusChange;
	}


	public HRESULT OnConnectionStatusChange(DOT11_ADHOC_NETWORK_CONNECTION_STATUS eStatus) mut => VT.[Friend]OnConnectionStatusChange(&this, eStatus);
}

#endregion

#region Functions
public static
{
	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanOpenHandle(uint32 dwClientVersion, void* pReserved, uint32* pdwNegotiatedVersion, HANDLE* phClientHandle);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanCloseHandle(HANDLE hClientHandle, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanEnumInterfaces(HANDLE hClientHandle, void* pReserved, WLAN_INTERFACE_INFO_LIST** ppInterfaceList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetAutoConfigParameter(HANDLE hClientHandle, WLAN_AUTOCONF_OPCODE OpCode, uint32 dwDataSize, void* pData, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanQueryAutoConfigParameter(HANDLE hClientHandle, WLAN_AUTOCONF_OPCODE OpCode, void* pReserved, uint32* pdwDataSize, void** ppData, WLAN_OPCODE_VALUE_TYPE* pWlanOpcodeValueType);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetInterfaceCapability(HANDLE hClientHandle, in Guid pInterfaceGuid, void* pReserved, WLAN_INTERFACE_CAPABILITY** ppCapability);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetInterface(HANDLE hClientHandle, in Guid pInterfaceGuid, WLAN_INTF_OPCODE OpCode, uint32 dwDataSize, void* pData, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanQueryInterface(HANDLE hClientHandle, in Guid pInterfaceGuid, WLAN_INTF_OPCODE OpCode, void* pReserved, uint32* pdwDataSize, void** ppData, WLAN_OPCODE_VALUE_TYPE* pWlanOpcodeValueType);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanIhvControl(HANDLE hClientHandle, in Guid pInterfaceGuid, WLAN_IHV_CONTROL_TYPE Type, uint32 dwInBufferSize, void* pInBuffer, uint32 dwOutBufferSize, void* pOutBuffer, uint32* pdwBytesReturned);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanScan(HANDLE hClientHandle, in Guid pInterfaceGuid, DOT11_SSID* pDot11Ssid, WLAN_RAW_DATA* pIeData, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetAvailableNetworkList(HANDLE hClientHandle, in Guid pInterfaceGuid, uint32 dwFlags, void* pReserved, WLAN_AVAILABLE_NETWORK_LIST** ppAvailableNetworkList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetAvailableNetworkList2(HANDLE hClientHandle, in Guid pInterfaceGuid, uint32 dwFlags, void* pReserved, WLAN_AVAILABLE_NETWORK_LIST_V2** ppAvailableNetworkList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetNetworkBssList(HANDLE hClientHandle, in Guid pInterfaceGuid, DOT11_SSID* pDot11Ssid, DOT11_BSS_TYPE dot11BssType, BOOL bSecurityEnabled, void* pReserved, WLAN_BSS_LIST** ppWlanBssList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanConnect(HANDLE hClientHandle, in Guid pInterfaceGuid, WLAN_CONNECTION_PARAMETERS* pConnectionParameters, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanConnect2(HANDLE hClientHandle, in Guid pInterfaceGuid, WLAN_CONNECTION_PARAMETERS_V2* pConnectionParameters, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanDisconnect(HANDLE hClientHandle, in Guid pInterfaceGuid, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanRegisterNotification(HANDLE hClientHandle, uint32 dwNotifSource, BOOL bIgnoreDuplicate, WLAN_NOTIFICATION_CALLBACK funcCallback, void* pCallbackContext, void* pReserved, uint32* pdwPrevNotifSource);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetProfile(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, void* pReserved, PWSTR* pstrProfileXml, uint32* pdwFlags, uint32* pdwGrantedAccess);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetProfileEapUserData(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, EAP_METHOD_TYPE eapType, WLAN_SET_EAPHOST_FLAGS dwFlags, uint32 dwEapUserDataSize, uint8* pbEapUserData, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetProfileEapXmlUserData(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, WLAN_SET_EAPHOST_FLAGS dwFlags, PWSTR strEapXmlUserData, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetProfile(HANDLE hClientHandle, in Guid pInterfaceGuid, uint32 dwFlags, PWSTR strProfileXml, PWSTR strAllUserProfileSecurity, BOOL bOverwrite, void* pReserved, uint32* pdwReasonCode);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanDeleteProfile(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanRenameProfile(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strOldProfileName, PWSTR strNewProfileName, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetProfileList(HANDLE hClientHandle, in Guid pInterfaceGuid, void* pReserved, WLAN_PROFILE_INFO_LIST** ppProfileList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetProfileList(HANDLE hClientHandle, in Guid pInterfaceGuid, uint32 dwItems, PWSTR* strProfileNames, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetProfilePosition(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, uint32 dwPosition, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetProfileCustomUserData(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, uint32 dwDataSize, uint8* pData, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetProfileCustomUserData(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, void* pReserved, uint32* pdwDataSize, uint8** ppData);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetFilterList(HANDLE hClientHandle, WLAN_FILTER_LIST_TYPE wlanFilterListType, DOT11_NETWORK_LIST* pNetworkList, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetFilterList(HANDLE hClientHandle, WLAN_FILTER_LIST_TYPE wlanFilterListType, void* pReserved, DOT11_NETWORK_LIST** ppNetworkList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetPsdIEDataList(HANDLE hClientHandle, PWSTR strFormat, WLAN_RAW_DATA_LIST* pPsdIEDataList, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSaveTemporaryProfile(HANDLE hClientHandle, in Guid pInterfaceGuid, PWSTR strProfileName, PWSTR strAllUserProfileSecurity, uint32 dwFlags, BOOL bOverWrite, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanDeviceServiceCommand(HANDLE hClientHandle, in Guid pInterfaceGuid, Guid* pDeviceServiceGuid, uint32 dwOpCode, uint32 dwInBufferSize, void* pInBuffer, uint32 dwOutBufferSize, void* pOutBuffer, uint32* pdwBytesReturned);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetSupportedDeviceServices(HANDLE hClientHandle, in Guid pInterfaceGuid, WLAN_DEVICE_SERVICE_GUID_LIST** ppDevSvcGuidList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanRegisterDeviceServiceNotification(HANDLE hClientHandle, WLAN_DEVICE_SERVICE_GUID_LIST* pDevSvcGuidList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanExtractPsdIEDataList(HANDLE hClientHandle, uint32 dwIeDataSize, uint8* pRawIeData, PWSTR strFormat, void* pReserved, WLAN_RAW_DATA_LIST** ppPsdIEDataList);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanReasonCodeToString(uint32 dwReasonCode, uint32 dwBufferSize, char16* pStringBuffer, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WlanAllocateMemory(uint32 dwMemorySize);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WlanFreeMemory(void* pMemory);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanSetSecuritySettings(HANDLE hClientHandle, WLAN_SECURABLE_OBJECT SecurableObject, PWSTR strModifiedSDDL);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanGetSecuritySettings(HANDLE hClientHandle, WLAN_SECURABLE_OBJECT SecurableObject, WLAN_OPCODE_VALUE_TYPE* pValueType, PWSTR* pstrCurrentSDDL, uint32* pdwGrantedAccess);

	[Import("wlanui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanUIEditProfile(uint32 dwClientVersion, PWSTR wstrProfileName, Guid* pInterfaceGuid, HWND hWnd, WL_DISPLAY_PAGES wlStartPage, void* pReserved, uint32* pWlanReasonCode);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkStartUsing(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkStopUsing(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkForceStart(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkForceStop(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkQueryProperty(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_OPCODE OpCode, uint32* pdwDataSize, void** ppvData, WLAN_OPCODE_VALUE_TYPE* pWlanOpcodeValueType, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkSetProperty(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_OPCODE OpCode, uint32 dwDataSize, void* pvData, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkInitSettings(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkRefreshSecuritySettings(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkQueryStatus(HANDLE hClientHandle, WLAN_HOSTED_NETWORK_STATUS** ppWlanHostedNetworkStatus, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkSetSecondaryKey(HANDLE hClientHandle, uint32 dwKeyLength, uint8* pucKeyData, BOOL bIsPassPhrase, BOOL bPersistent, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanHostedNetworkQuerySecondaryKey(HANDLE hClientHandle, uint32* pdwKeyLength, uint8** ppucKeyData, BOOL* pbIsPassPhrase, BOOL* pbPersistent, WLAN_HOSTED_NETWORK_REASON* pFailReason, void* pvReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WlanRegisterVirtualStationNotification(HANDLE hClientHandle, BOOL bRegister, void* pReserved);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDOpenHandle(uint32 dwClientVersion, uint32* pdwNegotiatedVersion, HANDLE* phClientHandle);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDCloseHandle(HANDLE hClientHandle);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDStartOpenSession(HANDLE hClientHandle, uint8** pDeviceAddress, void* pvContext, WFD_OPEN_SESSION_COMPLETE_CALLBACK pfnCallback, HANDLE* phSessionHandle);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDCancelOpenSession(HANDLE hSessionHandle);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDOpenLegacySession(HANDLE hClientHandle, uint8** pLegacyMacAddress, HANDLE* phSessionHandle, Guid* pGuidSessionInterface);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDCloseSession(HANDLE hSessionHandle);

	[Import("wlanapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WFDUpdateDeviceVisibility(uint8** pDeviceAddress);

}
#endregion
