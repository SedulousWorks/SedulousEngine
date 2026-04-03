using Win32.Foundation;
using Win32.Security.Authentication.Identity;
using Win32.Security.Cryptography;
using System;

namespace Win32.Networking.Ldap;

#region Constants
public static
{
	public const int32 LBER_ERROR = -1;
	public const int32 LBER_DEFAULT = -1;
	public const uint32 LDAP_UNICODE = 1;
	public const uint32 LDAP_PORT = 389;
	public const uint32 LDAP_SSL_PORT = 636;
	public const uint32 LDAP_GC_PORT = 3268;
	public const uint32 LDAP_SSL_GC_PORT = 3269;
	public const uint32 LDAP_VERSION1 = 1;
	public const uint32 LDAP_VERSION2 = 2;
	public const uint32 LDAP_VERSION3 = 3;
	public const uint32 LDAP_VERSION = 2;
	public const int32 LDAP_BIND_CMD = 96;
	public const int32 LDAP_UNBIND_CMD = 66;
	public const int32 LDAP_SEARCH_CMD = 99;
	public const int32 LDAP_MODIFY_CMD = 102;
	public const int32 LDAP_ADD_CMD = 104;
	public const int32 LDAP_DELETE_CMD = 74;
	public const int32 LDAP_MODRDN_CMD = 108;
	public const int32 LDAP_COMPARE_CMD = 110;
	public const int32 LDAP_ABANDON_CMD = 80;
	public const int32 LDAP_SESSION_CMD = 113;
	public const int32 LDAP_EXTENDED_CMD = 119;
	public const int32 LDAP_RES_BIND = 97;
	public const int32 LDAP_RES_SEARCH_ENTRY = 100;
	public const int32 LDAP_RES_SEARCH_RESULT = 101;
	public const int32 LDAP_RES_MODIFY = 103;
	public const int32 LDAP_RES_ADD = 105;
	public const int32 LDAP_RES_DELETE = 107;
	public const int32 LDAP_RES_MODRDN = 109;
	public const int32 LDAP_RES_COMPARE = 111;
	public const int32 LDAP_RES_SESSION = 114;
	public const int32 LDAP_RES_REFERRAL = 115;
	public const int32 LDAP_RES_EXTENDED = 120;
	public const int32 LDAP_RES_ANY = -1;
	public const uint32 LDAP_INVALID_CMD = 255;
	public const uint32 LDAP_INVALID_RES = 255;
	public const int32 LDAP_AUTH_SIMPLE = 128;
	public const int32 LDAP_AUTH_SASL = 131;
	public const int32 LDAP_AUTH_OTHERKIND = 134;
	public const uint32 LDAP_FILTER_AND = 160;
	public const uint32 LDAP_FILTER_OR = 161;
	public const uint32 LDAP_FILTER_NOT = 162;
	public const uint32 LDAP_FILTER_EQUALITY = 163;
	public const uint32 LDAP_FILTER_SUBSTRINGS = 164;
	public const uint32 LDAP_FILTER_GE = 165;
	public const uint32 LDAP_FILTER_LE = 166;
	public const uint32 LDAP_FILTER_PRESENT = 135;
	public const uint32 LDAP_FILTER_APPROX = 168;
	public const uint32 LDAP_FILTER_EXTENSIBLE = 169;
	public const int32 LDAP_SUBSTRING_INITIAL = 128;
	public const int32 LDAP_SUBSTRING_ANY = 129;
	public const int32 LDAP_SUBSTRING_FINAL = 130;
	public const uint32 LDAP_DEREF_NEVER = 0;
	public const uint32 LDAP_DEREF_SEARCHING = 1;
	public const uint32 LDAP_DEREF_FINDING = 2;
	public const uint32 LDAP_DEREF_ALWAYS = 3;
	public const uint32 LDAP_NO_LIMIT = 0;
	public const uint32 LDAP_OPT_DNS = 1;
	public const uint32 LDAP_OPT_CHASE_REFERRALS = 2;
	public const uint32 LDAP_OPT_RETURN_REFS = 4;
	public const String LDAP_CONTROL_REFERRALS_W = "1.2.840.113556.1.4.616";
	public const String LDAP_CONTROL_REFERRALS = "1.2.840.113556.1.4.616";
	public const uint32 LDAP_MOD_ADD = 0;
	public const uint32 LDAP_MOD_DELETE = 1;
	public const uint32 LDAP_MOD_REPLACE = 2;
	public const uint32 LDAP_MOD_BVALUES = 128;
	public const uint32 LDAP_OPT_API_INFO = 0;
	public const uint32 LDAP_OPT_DESC = 1;
	public const uint32 LDAP_OPT_DEREF = 2;
	public const uint32 LDAP_OPT_SIZELIMIT = 3;
	public const uint32 LDAP_OPT_TIMELIMIT = 4;
	public const uint32 LDAP_OPT_THREAD_FN_PTRS = 5;
	public const uint32 LDAP_OPT_REBIND_FN = 6;
	public const uint32 LDAP_OPT_REBIND_ARG = 7;
	public const uint32 LDAP_OPT_REFERRALS = 8;
	public const uint32 LDAP_OPT_RESTART = 9;
	public const uint32 LDAP_OPT_SSL = 10;
	public const uint32 LDAP_OPT_IO_FN_PTRS = 11;
	public const uint32 LDAP_OPT_CACHE_FN_PTRS = 13;
	public const uint32 LDAP_OPT_CACHE_STRATEGY = 14;
	public const uint32 LDAP_OPT_CACHE_ENABLE = 15;
	public const uint32 LDAP_OPT_REFERRAL_HOP_LIMIT = 16;
	public const uint32 LDAP_OPT_PROTOCOL_VERSION = 17;
	public const uint32 LDAP_OPT_VERSION = 17;
	public const uint32 LDAP_OPT_API_FEATURE_INFO = 21;
	public const uint32 LDAP_OPT_HOST_NAME = 48;
	public const uint32 LDAP_OPT_ERROR_NUMBER = 49;
	public const uint32 LDAP_OPT_ERROR_STRING = 50;
	public const uint32 LDAP_OPT_SERVER_ERROR = 51;
	public const uint32 LDAP_OPT_SERVER_EXT_ERROR = 52;
	public const uint32 LDAP_OPT_HOST_REACHABLE = 62;
	public const uint32 LDAP_OPT_PING_KEEP_ALIVE = 54;
	public const uint32 LDAP_OPT_PING_WAIT_TIME = 55;
	public const uint32 LDAP_OPT_PING_LIMIT = 56;
	public const uint32 LDAP_OPT_DNSDOMAIN_NAME = 59;
	public const uint32 LDAP_OPT_GETDSNAME_FLAGS = 61;
	public const uint32 LDAP_OPT_PROMPT_CREDENTIALS = 63;
	public const uint32 LDAP_OPT_AUTO_RECONNECT = 145;
	public const uint32 LDAP_OPT_SSPI_FLAGS = 146;
	public const uint32 LDAP_OPT_SSL_INFO = 147;
	public const uint32 LDAP_OPT_TLS = 10;
	public const uint32 LDAP_OPT_TLS_INFO = 147;
	public const uint32 LDAP_OPT_SIGN = 149;
	public const uint32 LDAP_OPT_ENCRYPT = 150;
	public const uint32 LDAP_OPT_SASL_METHOD = 151;
	public const uint32 LDAP_OPT_AREC_EXCLUSIVE = 152;
	public const uint32 LDAP_OPT_SECURITY_CONTEXT = 153;
	public const uint32 LDAP_OPT_ROOTDSE_CACHE = 154;
	public const uint32 LDAP_OPT_TCP_KEEPALIVE = 64;
	public const uint32 LDAP_OPT_FAST_CONCURRENT_BIND = 65;
	public const uint32 LDAP_OPT_SEND_TIMEOUT = 66;
	public const uint32 LDAP_OPT_SCH_FLAGS = 67;
	public const uint32 LDAP_OPT_SOCKET_BIND_ADDRESSES = 68;
	public const uint32 LDAP_CHASE_SUBORDINATE_REFERRALS = 32;
	public const uint32 LDAP_CHASE_EXTERNAL_REFERRALS = 64;
	public const uint32 LDAP_SCOPE_BASE = 0;
	public const uint32 LDAP_SCOPE_ONELEVEL = 1;
	public const uint32 LDAP_SCOPE_SUBTREE = 2;
	public const uint32 LDAP_MSG_ONE = 0;
	public const uint32 LDAP_MSG_ALL = 1;
	public const uint32 LDAP_MSG_RECEIVED = 2;
	public const uint32 LBER_USE_DER = 1;
	public const uint32 LBER_USE_INDEFINITE_LEN = 2;
	public const uint32 LBER_TRANSLATE_STRINGS = 4;
	public const uint32 LAPI_MAJOR_VER1 = 1;
	public const uint32 LAPI_MINOR_VER1 = 1;
	public const uint32 LDAP_API_INFO_VERSION = 1;
	public const uint32 LDAP_API_VERSION = 2004;
	public const uint32 LDAP_VERSION_MIN = 2;
	public const uint32 LDAP_VERSION_MAX = 3;
	public const String LDAP_VENDOR_NAME = "Microsoft Corporation.";
	public const String LDAP_VENDOR_NAME_W = "Microsoft Corporation.";
	public const uint32 LDAP_VENDOR_VERSION = 510;
	public const uint32 LDAP_FEATURE_INFO_VERSION = 1;
	public const String LDAP_SERVER_SORT_OID = "1.2.840.113556.1.4.473";
	public const String LDAP_SERVER_SORT_OID_W = "1.2.840.113556.1.4.473";
	public const String LDAP_SERVER_RESP_SORT_OID = "1.2.840.113556.1.4.474";
	public const String LDAP_SERVER_RESP_SORT_OID_W = "1.2.840.113556.1.4.474";
	public const String LDAP_PAGED_RESULT_OID_STRING = "1.2.840.113556.1.4.319";
	public const String LDAP_PAGED_RESULT_OID_STRING_W = "1.2.840.113556.1.4.319";
	public const String LDAP_CONTROL_VLVREQUEST = "2.16.840.1.113730.3.4.9";
	public const String LDAP_CONTROL_VLVREQUEST_W = "2.16.840.1.113730.3.4.9";
	public const String LDAP_CONTROL_VLVRESPONSE = "2.16.840.1.113730.3.4.10";
	public const String LDAP_CONTROL_VLVRESPONSE_W = "2.16.840.1.113730.3.4.10";
	public const uint32 LDAP_API_FEATURE_VIRTUAL_LIST_VIEW = 1001;
	public const uint32 LDAP_VLVINFO_VERSION = 1;
	public const String LDAP_START_TLS_OID = "1.3.6.1.4.1.1466.20037";
	public const String LDAP_START_TLS_OID_W = "1.3.6.1.4.1.1466.20037";
	public const String LDAP_TTL_EXTENDED_OP_OID = "1.3.6.1.4.1.1466.101.119.1";
	public const String LDAP_TTL_EXTENDED_OP_OID_W = "1.3.6.1.4.1.1466.101.119.1";
	public const uint32 LDAP_OPT_REFERRAL_CALLBACK = 112;
	public const uint32 LDAP_OPT_CLIENT_CERTIFICATE = 128;
	public const uint32 LDAP_OPT_SERVER_CERTIFICATE = 129;
	public const uint32 LDAP_OPT_REF_DEREF_CONN_PER_MSG = 148;
	public const String LDAP_SERVER_FORCE_UPDATE_OID = "1.2.840.113556.1.4.1974";
	public const String LDAP_SERVER_FORCE_UPDATE_OID_W = "1.2.840.113556.1.4.1974";
	public const String LDAP_SERVER_PERMISSIVE_MODIFY_OID = "1.2.840.113556.1.4.1413";
	public const String LDAP_SERVER_PERMISSIVE_MODIFY_OID_W = "1.2.840.113556.1.4.1413";
	public const String LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417";
	public const String LDAP_SERVER_SHOW_DELETED_OID_W = "1.2.840.113556.1.4.417";
	public const String LDAP_SERVER_SHOW_RECYCLED_OID = "1.2.840.113556.1.4.2064";
	public const String LDAP_SERVER_SHOW_RECYCLED_OID_W = "1.2.840.113556.1.4.2064";
	public const String LDAP_SERVER_EXPECTED_ENTRY_COUNT_OID = "1.2.840.113556.1.4.2211";
	public const String LDAP_SERVER_EXPECTED_ENTRY_COUNT_OID_W = "1.2.840.113556.1.4.2211";
	public const String LDAP_SERVER_SEARCH_HINTS_OID = "1.2.840.113556.1.4.2206";
	public const String LDAP_SERVER_SEARCH_HINTS_OID_W = "1.2.840.113556.1.4.2206";
	public const String LDAP_SEARCH_HINT_INDEX_ONLY_OID = "1.2.840.113556.1.4.2207";
	public const String LDAP_SEARCH_HINT_INDEX_ONLY_OID_W = "1.2.840.113556.1.4.2207";
	public const String LDAP_SEARCH_HINT_SOFT_SIZE_LIMIT_OID = "1.2.840.113556.1.4.2210";
	public const String LDAP_SEARCH_HINT_SOFT_SIZE_LIMIT_OID_W = "1.2.840.113556.1.4.2210";
	public const String LDAP_SEARCH_HINT_REQUIRED_INDEX_OID = "1.2.840.113556.1.4.2306";
	public const String LDAP_SEARCH_HINT_REQUIRED_INDEX_OID_W = "1.2.840.113556.1.4.2306";
	public const String LDAP_SERVER_UPDATE_STATS_OID = "1.2.840.113556.1.4.2205";
	public const String LDAP_SERVER_UPDATE_STATS_OID_W = "1.2.840.113556.1.4.2205";
	public const String LDAP_UPDATE_STATS_USN_OID = "1.2.840.113556.1.4.2208";
	public const String LDAP_UPDATE_STATS_USN_OID_W = "1.2.840.113556.1.4.2208";
	public const String LDAP_UPDATE_STATS_INVOCATIONID_OID = "1.2.840.113556.1.4.2209";
	public const String LDAP_UPDATE_STATS_INVOCATIONID_OID_W = "1.2.840.113556.1.4.2209";
	public const String LDAP_SERVER_GET_STATS_OID = "1.2.840.113556.1.4.970";
	public const String LDAP_SERVER_GET_STATS_OID_W = "1.2.840.113556.1.4.970";
	public const String LDAP_SERVER_SHOW_DEACTIVATED_LINK_OID = "1.2.840.113556.1.4.2065";
	public const String LDAP_SERVER_SHOW_DEACTIVATED_LINK_OID_W = "1.2.840.113556.1.4.2065";
	public const String LDAP_SERVER_POLICY_HINTS_DEPRECATED_OID = "1.2.840.113556.1.4.2066";
	public const String LDAP_SERVER_POLICY_HINTS_DEPRECATED_OID_W = "1.2.840.113556.1.4.2066";
	public const String LDAP_SERVER_POLICY_HINTS_OID = "1.2.840.113556.1.4.2239";
	public const String LDAP_SERVER_POLICY_HINTS_OID_W = "1.2.840.113556.1.4.2239";
	public const String LDAP_SERVER_RANGE_OPTION_OID = "1.2.840.113556.1.4.802";
	public const String LDAP_SERVER_RANGE_OPTION_OID_W = "1.2.840.113556.1.4.802";
	public const String LDAP_SERVER_CROSSDOM_MOVE_TARGET_OID = "1.2.840.113556.1.4.521";
	public const String LDAP_SERVER_CROSSDOM_MOVE_TARGET_OID_W = "1.2.840.113556.1.4.521";
	public const String LDAP_SERVER_NOTIFICATION_OID = "1.2.840.113556.1.4.528";
	public const String LDAP_SERVER_NOTIFICATION_OID_W = "1.2.840.113556.1.4.528";
	public const String LDAP_SERVER_SHUTDOWN_NOTIFY_OID = "1.2.840.113556.1.4.1907";
	public const String LDAP_SERVER_SHUTDOWN_NOTIFY_OID_W = "1.2.840.113556.1.4.1907";
	public const String LDAP_SERVER_LAZY_COMMIT_OID = "1.2.840.113556.1.4.619";
	public const String LDAP_SERVER_LAZY_COMMIT_OID_W = "1.2.840.113556.1.4.619";
	public const String LDAP_SERVER_SD_FLAGS_OID = "1.2.840.113556.1.4.801";
	public const String LDAP_SERVER_SD_FLAGS_OID_W = "1.2.840.113556.1.4.801";
	public const String LDAP_SERVER_TREE_DELETE_EX_OID = "1.2.840.113556.1.4.2204";
	public const String LDAP_SERVER_TREE_DELETE_EX_OID_W = "1.2.840.113556.1.4.2204";
	public const String LDAP_SERVER_TREE_DELETE_OID = "1.2.840.113556.1.4.805";
	public const String LDAP_SERVER_TREE_DELETE_OID_W = "1.2.840.113556.1.4.805";
	public const String LDAP_SERVER_ASQ_OID = "1.2.840.113556.1.4.1504";
	public const String LDAP_SERVER_ASQ_OID_W = "1.2.840.113556.1.4.1504";
	public const String LDAP_SERVER_DIRSYNC_OID = "1.2.840.113556.1.4.841";
	public const String LDAP_SERVER_DIRSYNC_OID_W = "1.2.840.113556.1.4.841";
	public const String LDAP_SERVER_DIRSYNC_EX_OID = "1.2.840.113556.1.4.2090";
	public const String LDAP_SERVER_DIRSYNC_EX_OID_W = "1.2.840.113556.1.4.2090";
	public const String LDAP_SERVER_EXTENDED_DN_OID = "1.2.840.113556.1.4.529";
	public const String LDAP_SERVER_EXTENDED_DN_OID_W = "1.2.840.113556.1.4.529";
	public const String LDAP_SERVER_VERIFY_NAME_OID = "1.2.840.113556.1.4.1338";
	public const String LDAP_SERVER_VERIFY_NAME_OID_W = "1.2.840.113556.1.4.1338";
	public const String LDAP_SERVER_DOMAIN_SCOPE_OID = "1.2.840.113556.1.4.1339";
	public const String LDAP_SERVER_DOMAIN_SCOPE_OID_W = "1.2.840.113556.1.4.1339";
	public const String LDAP_SERVER_SEARCH_OPTIONS_OID = "1.2.840.113556.1.4.1340";
	public const String LDAP_SERVER_SEARCH_OPTIONS_OID_W = "1.2.840.113556.1.4.1340";
	public const uint32 SERVER_SEARCH_FLAG_DOMAIN_SCOPE = 1;
	public const uint32 SERVER_SEARCH_FLAG_PHANTOM_ROOT = 2;
	public const String LDAP_SERVER_QUOTA_CONTROL_OID = "1.2.840.113556.1.4.1852";
	public const String LDAP_SERVER_QUOTA_CONTROL_OID_W = "1.2.840.113556.1.4.1852";
	public const String LDAP_SERVER_RANGE_RETRIEVAL_NOERR_OID = "1.2.840.113556.1.4.1948";
	public const String LDAP_SERVER_RANGE_RETRIEVAL_NOERR_OID_W = "1.2.840.113556.1.4.1948";
	public const String LDAP_SERVER_DN_INPUT_OID = "1.2.840.113556.1.4.2026";
	public const String LDAP_SERVER_DN_INPUT_OID_W = "1.2.840.113556.1.4.2026";
	public const String LDAP_SERVER_SET_OWNER_OID = "1.2.840.113556.1.4.2255";
	public const String LDAP_SERVER_SET_OWNER_OID_W = "1.2.840.113556.1.4.2255";
	public const String LDAP_SERVER_BYPASS_QUOTA_OID = "1.2.840.113556.1.4.2256";
	public const String LDAP_SERVER_BYPASS_QUOTA_OID_W = "1.2.840.113556.1.4.2256";
	public const String LDAP_SERVER_LINK_TTL_OID = "1.2.840.113556.1.4.2309";
	public const String LDAP_SERVER_LINK_TTL_OID_W = "1.2.840.113556.1.4.2309";
	public const String LDAP_OPATT_BECOME_DOM_MASTER = "becomeDomainMaster";
	public const String LDAP_OPATT_BECOME_DOM_MASTER_W = "becomeDomainMaster";
	public const String LDAP_OPATT_BECOME_RID_MASTER = "becomeRidMaster";
	public const String LDAP_OPATT_BECOME_RID_MASTER_W = "becomeRidMaster";
	public const String LDAP_OPATT_BECOME_SCHEMA_MASTER = "becomeSchemaMaster";
	public const String LDAP_OPATT_BECOME_SCHEMA_MASTER_W = "becomeSchemaMaster";
	public const String LDAP_OPATT_RECALC_HIERARCHY = "recalcHierarchy";
	public const String LDAP_OPATT_RECALC_HIERARCHY_W = "recalcHierarchy";
	public const String LDAP_OPATT_SCHEMA_UPDATE_NOW = "schemaUpdateNow";
	public const String LDAP_OPATT_SCHEMA_UPDATE_NOW_W = "schemaUpdateNow";
	public const String LDAP_OPATT_BECOME_PDC = "becomePdc";
	public const String LDAP_OPATT_BECOME_PDC_W = "becomePdc";
	public const String LDAP_OPATT_FIXUP_INHERITANCE = "fixupInheritance";
	public const String LDAP_OPATT_FIXUP_INHERITANCE_W = "fixupInheritance";
	public const String LDAP_OPATT_INVALIDATE_RID_POOL = "invalidateRidPool";
	public const String LDAP_OPATT_INVALIDATE_RID_POOL_W = "invalidateRidPool";
	public const String LDAP_OPATT_ABANDON_REPL = "abandonReplication";
	public const String LDAP_OPATT_ABANDON_REPL_W = "abandonReplication";
	public const String LDAP_OPATT_DO_GARBAGE_COLLECTION = "doGarbageCollection";
	public const String LDAP_OPATT_DO_GARBAGE_COLLECTION_W = "doGarbageCollection";
	public const String LDAP_OPATT_SUBSCHEMA_SUBENTRY = "subschemaSubentry";
	public const String LDAP_OPATT_SUBSCHEMA_SUBENTRY_W = "subschemaSubentry";
	public const String LDAP_OPATT_CURRENT_TIME = "currentTime";
	public const String LDAP_OPATT_CURRENT_TIME_W = "currentTime";
	public const String LDAP_OPATT_SERVER_NAME = "serverName";
	public const String LDAP_OPATT_SERVER_NAME_W = "serverName";
	public const String LDAP_OPATT_NAMING_CONTEXTS = "namingContexts";
	public const String LDAP_OPATT_NAMING_CONTEXTS_W = "namingContexts";
	public const String LDAP_OPATT_DEFAULT_NAMING_CONTEXT = "defaultNamingContext";
	public const String LDAP_OPATT_DEFAULT_NAMING_CONTEXT_W = "defaultNamingContext";
	public const String LDAP_OPATT_SUPPORTED_CONTROL = "supportedControl";
	public const String LDAP_OPATT_SUPPORTED_CONTROL_W = "supportedControl";
	public const String LDAP_OPATT_HIGHEST_COMMITTED_USN = "highestCommitedUSN";
	public const String LDAP_OPATT_HIGHEST_COMMITTED_USN_W = "highestCommitedUSN";
	public const String LDAP_OPATT_SUPPORTED_LDAP_VERSION = "supportedLDAPVersion";
	public const String LDAP_OPATT_SUPPORTED_LDAP_VERSION_W = "supportedLDAPVersion";
	public const String LDAP_OPATT_SUPPORTED_LDAP_POLICIES = "supportedLDAPPolicies";
	public const String LDAP_OPATT_SUPPORTED_LDAP_POLICIES_W = "supportedLDAPPolicies";
	public const String LDAP_OPATT_SCHEMA_NAMING_CONTEXT = "schemaNamingContext";
	public const String LDAP_OPATT_SCHEMA_NAMING_CONTEXT_W = "schemaNamingContext";
	public const String LDAP_OPATT_CONFIG_NAMING_CONTEXT = "configurationNamingContext";
	public const String LDAP_OPATT_CONFIG_NAMING_CONTEXT_W = "configurationNamingContext";
	public const String LDAP_OPATT_ROOT_DOMAIN_NAMING_CONTEXT = "rootDomainNamingContext";
	public const String LDAP_OPATT_ROOT_DOMAIN_NAMING_CONTEXT_W = "rootDomainNamingContext";
	public const String LDAP_OPATT_SUPPORTED_SASL_MECHANISM = "supportedSASLMechanisms";
	public const String LDAP_OPATT_SUPPORTED_SASL_MECHANISM_W = "supportedSASLMechanisms";
	public const String LDAP_OPATT_DNS_HOST_NAME = "dnsHostName";
	public const String LDAP_OPATT_DNS_HOST_NAME_W = "dnsHostName";
	public const String LDAP_OPATT_LDAP_SERVICE_NAME = "ldapServiceName";
	public const String LDAP_OPATT_LDAP_SERVICE_NAME_W = "ldapServiceName";
	public const String LDAP_OPATT_DS_SERVICE_NAME = "dsServiceName";
	public const String LDAP_OPATT_DS_SERVICE_NAME_W = "dsServiceName";
	public const String LDAP_OPATT_SUPPORTED_CAPABILITIES = "supportedCapabilities";
	public const String LDAP_OPATT_SUPPORTED_CAPABILITIES_W = "supportedCapabilities";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_OID = "1.2.840.113556.1.4.800";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_OID_W = "1.2.840.113556.1.4.800";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V51_OID = "1.2.840.113556.1.4.1670";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V51_OID_W = "1.2.840.113556.1.4.1670";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_LDAP_INTEG_OID = "1.2.840.113556.1.4.1791";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_LDAP_INTEG_OID_W = "1.2.840.113556.1.4.1791";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_ADAM_OID = "1.2.840.113556.1.4.1851";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_ADAM_OID_W = "1.2.840.113556.1.4.1851";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_PARTIAL_SECRETS_OID = "1.2.840.113556.1.4.1920";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_PARTIAL_SECRETS_OID_W = "1.2.840.113556.1.4.1920";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V60_OID = "1.2.840.113556.1.4.1935";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V60_OID_W = "1.2.840.113556.1.4.1935";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V61_OID = "1.2.840.113556.1.4.1935";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V61_OID_W = "1.2.840.113556.1.4.1935";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V61_R2_OID = "1.2.840.113556.1.4.2080";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_V61_R2_OID_W = "1.2.840.113556.1.4.2080";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_W8_OID = "1.2.840.113556.1.4.2237";
	public const String LDAP_CAP_ACTIVE_DIRECTORY_W8_OID_W = "1.2.840.113556.1.4.2237";
	public const String LDAP_MATCHING_RULE_BIT_AND = "1.2.840.113556.1.4.803";
	public const String LDAP_MATCHING_RULE_BIT_AND_W = "1.2.840.113556.1.4.803";
	public const String LDAP_MATCHING_RULE_BIT_OR = "1.2.840.113556.1.4.804";
	public const String LDAP_MATCHING_RULE_BIT_OR_W = "1.2.840.113556.1.4.804";
	public const String LDAP_MATCHING_RULE_TRANSITIVE_EVALUATION = "1.2.840.113556.1.4.1941";
	public const String LDAP_MATCHING_RULE_TRANSITIVE_EVALUATION_W = "1.2.840.113556.1.4.1941";
	public const String LDAP_MATCHING_RULE_DN_BINARY_COMPLEX = "1.2.840.113556.1.4.2253";
	public const String LDAP_MATCHING_RULE_DN_BINARY_COMPLEX_W = "1.2.840.113556.1.4.2253";
	public const String LDAP_SERVER_FAST_BIND_OID = "1.2.840.113556.1.4.1781";
	public const String LDAP_SERVER_FAST_BIND_OID_W = "1.2.840.113556.1.4.1781";
	public const String LDAP_SERVER_WHO_AM_I_OID = "1.3.6.1.4.1.4203.1.11.3";
	public const String LDAP_SERVER_WHO_AM_I_OID_W = "1.3.6.1.4.1.4203.1.11.3";
	public const String LDAP_SERVER_BATCH_REQUEST_OID = "1.2.840.113556.1.4.2212";
	public const String LDAP_SERVER_BATCH_REQUEST_OID_W = "1.2.840.113556.1.4.2212";
	public const uint32 LDAP_DIRSYNC_OBJECT_SECURITY = 1;
	public const uint32 LDAP_DIRSYNC_ANCESTORS_FIRST_ORDER = 2048;
	public const uint32 LDAP_DIRSYNC_PUBLIC_DATA_ONLY = 8192;
	public const uint32 LDAP_DIRSYNC_INCREMENTAL_VALUES = 2147483648;
	public const uint32 LDAP_DIRSYNC_ROPAS_DATA_ONLY = 1073741824;
	public const uint32 LDAP_POLICYHINT_APPLY_FULLPWDPOLICY = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum LDAP_RETCODE : int32
{
	LDAP_SUCCESS = 0,
	LDAP_OPERATIONS_ERROR = 1,
	LDAP_PROTOCOL_ERROR = 2,
	LDAP_TIMELIMIT_EXCEEDED = 3,
	LDAP_SIZELIMIT_EXCEEDED = 4,
	LDAP_COMPARE_FALSE = 5,
	LDAP_COMPARE_TRUE = 6,
	LDAP_AUTH_METHOD_NOT_SUPPORTED = 7,
	LDAP_STRONG_AUTH_REQUIRED = 8,
	LDAP_REFERRAL_V2 = 9,
	LDAP_PARTIAL_RESULTS = 9,
	LDAP_REFERRAL = 10,
	LDAP_ADMIN_LIMIT_EXCEEDED = 11,
	LDAP_UNAVAILABLE_CRIT_EXTENSION = 12,
	LDAP_CONFIDENTIALITY_REQUIRED = 13,
	LDAP_SASL_BIND_IN_PROGRESS = 14,
	LDAP_NO_SUCH_ATTRIBUTE = 16,
	LDAP_UNDEFINED_TYPE = 17,
	LDAP_INAPPROPRIATE_MATCHING = 18,
	LDAP_CONSTRAINT_VIOLATION = 19,
	LDAP_ATTRIBUTE_OR_VALUE_EXISTS = 20,
	LDAP_INVALID_SYNTAX = 21,
	LDAP_NO_SUCH_OBJECT = 32,
	LDAP_ALIAS_PROBLEM = 33,
	LDAP_INVALID_DN_SYNTAX = 34,
	LDAP_IS_LEAF = 35,
	LDAP_ALIAS_DEREF_PROBLEM = 36,
	LDAP_INAPPROPRIATE_AUTH = 48,
	LDAP_INVALID_CREDENTIALS = 49,
	LDAP_INSUFFICIENT_RIGHTS = 50,
	LDAP_BUSY = 51,
	LDAP_UNAVAILABLE = 52,
	LDAP_UNWILLING_TO_PERFORM = 53,
	LDAP_LOOP_DETECT = 54,
	LDAP_SORT_CONTROL_MISSING = 60,
	LDAP_OFFSET_RANGE_ERROR = 61,
	LDAP_NAMING_VIOLATION = 64,
	LDAP_OBJECT_CLASS_VIOLATION = 65,
	LDAP_NOT_ALLOWED_ON_NONLEAF = 66,
	LDAP_NOT_ALLOWED_ON_RDN = 67,
	LDAP_ALREADY_EXISTS = 68,
	LDAP_NO_OBJECT_CLASS_MODS = 69,
	LDAP_RESULTS_TOO_LARGE = 70,
	LDAP_AFFECTS_MULTIPLE_DSAS = 71,
	LDAP_VIRTUAL_LIST_VIEW_ERROR = 76,
	LDAP_OTHER = 80,
	LDAP_SERVER_DOWN = 81,
	LDAP_LOCAL_ERROR = 82,
	LDAP_ENCODING_ERROR = 83,
	LDAP_DECODING_ERROR = 84,
	LDAP_TIMEOUT = 85,
	LDAP_AUTH_UNKNOWN = 86,
	LDAP_FILTER_ERROR = 87,
	LDAP_USER_CANCELLED = 88,
	LDAP_PARAM_ERROR = 89,
	LDAP_NO_MEMORY = 90,
	LDAP_CONNECT_ERROR = 91,
	LDAP_NOT_SUPPORTED = 92,
	LDAP_NO_RESULTS_RETURNED = 94,
	LDAP_CONTROL_NOT_FOUND = 93,
	LDAP_MORE_RESULTS_TO_RETURN = 95,
	LDAP_CLIENT_LOOP = 96,
	LDAP_REFERRAL_LIMIT_EXCEEDED = 97,
}

#endregion

#region Function Pointers
public function uint32 DBGPRINT(PSTR Format);

public function uint32 QUERYFORCONNECTION(LDAP* PrimaryConnection, LDAP* ReferralFromConnection, PWSTR NewDN, PSTR HostName, uint32 PortNumber, void* SecAuthIdentity, void* CurrentUserToken, LDAP** ConnectionToUse);

public function BOOLEAN NOTIFYOFNEWCONNECTION(LDAP* PrimaryConnection, LDAP* ReferralFromConnection, PWSTR NewDN, PSTR HostName, LDAP* NewConnection, uint32 PortNumber, void* SecAuthIdentity, void* CurrentUser, uint32 ErrorCodeFromBind);

public function uint32 DEREFERENCECONNECTION(LDAP* PrimaryConnection, LDAP* ConnectionToDereference);

public function BOOLEAN QUERYCLIENTCERT(LDAP* Connection, SecPkgContext_IssuerListInfoEx* trusted_CAs, CERT_CONTEXT** ppCertificate);

public function BOOLEAN VERIFYSERVERCERT(LDAP* Connection, CERT_CONTEXT** pServerCert);

#endregion

#region Structs
[CRepr]
public struct LDAP
{
	[CRepr]
	public struct _ld_sb_e__Struct
	{
		public uint sb_sd;
		public uint8[41] Reserved1;
		public uint sb_naddr;
		public uint8[24] Reserved2;
	}
	public _ld_sb_e__Struct ld_sb;
	public PSTR ld_host;
	public uint32 ld_version;
	public uint8 ld_lberoptions;
	public uint32 ld_deref;
	public uint32 ld_timelimit;
	public uint32 ld_sizelimit;
	public uint32 ld_errno;
	public PSTR ld_matched;
	public PSTR ld_error;
	public uint32 ld_msgid;
	public uint8[25] Reserved3;
	public uint32 ld_cldaptries;
	public uint32 ld_cldaptimeout;
	public uint32 ld_refhoplimit;
	public uint32 ld_options;
}

[CRepr]
public struct LDAP_TIMEVAL
{
	public int32 tv_sec;
	public int32 tv_usec;
}

[CRepr]
public struct LDAP_BERVAL
{
	public uint32 bv_len;
	public PSTR bv_val;
}

[CRepr]
public struct LDAPMessage
{
	public uint32 lm_msgid;
	public uint32 lm_msgtype;
	public void* lm_ber;
	public LDAPMessage* lm_chain;
	public LDAPMessage* lm_next;
	public uint32 lm_time;
	public LDAP* Connection;
	public void* Request;
	public uint32 lm_returncode;
	public uint16 lm_referral;
	public BOOLEAN lm_chased;
	public BOOLEAN lm_eom;
	public BOOLEAN ConnectionReferenced;
}

[CRepr]
public struct LDAPControlA
{
	public PSTR ldctl_oid;
	public LDAP_BERVAL ldctl_value;
	public BOOLEAN ldctl_iscritical;
}

[CRepr]
public struct LDAPControlW
{
	public PWSTR ldctl_oid;
	public LDAP_BERVAL ldctl_value;
	public BOOLEAN ldctl_iscritical;
}

[CRepr]
public struct LDAPModW
{
	[CRepr, Union]
	public struct _mod_vals_e__Union
	{
		public PWSTR* modv_strvals;
		public LDAP_BERVAL** modv_bvals;
	}
	public uint32 mod_op;
	public PWSTR mod_type;
	public _mod_vals_e__Union mod_vals;
}

[CRepr]
public struct LDAPModA
{
	[CRepr, Union]
	public struct _mod_vals_e__Union
	{
		public PSTR* modv_strvals;
		public LDAP_BERVAL** modv_bvals;
	}
	public uint32 mod_op;
	public PSTR mod_type;
	public _mod_vals_e__Union mod_vals;
}

[CRepr]
public struct BerElement
{
	public PSTR opaque;
}

[CRepr]
public struct LDAP_VERSION_INFO
{
	public uint32 lv_size;
	public uint32 lv_major;
	public uint32 lv_minor;
}

[CRepr]
public struct LDAPAPIInfoA
{
	public int32 ldapai_info_version;
	public int32 ldapai_api_version;
	public int32 ldapai_protocol_version;
	public int8** ldapai_extensions;
	public PSTR ldapai_vendor_name;
	public int32 ldapai_vendor_version;
}

[CRepr]
public struct LDAPAPIInfoW
{
	public int32 ldapai_info_version;
	public int32 ldapai_api_version;
	public int32 ldapai_protocol_version;
	public PWSTR* ldapai_extensions;
	public PWSTR ldapai_vendor_name;
	public int32 ldapai_vendor_version;
}

[CRepr]
public struct LDAPAPIFeatureInfoA
{
	public int32 ldapaif_info_version;
	public PSTR ldapaif_name;
	public int32 ldapaif_version;
}

[CRepr]
public struct LDAPAPIFeatureInfoW
{
	public int32 ldapaif_info_version;
	public PWSTR ldapaif_name;
	public int32 ldapaif_version;
}

[CRepr]
public struct LDAPSearch
{
}

[CRepr]
public struct LDAPSortKeyW
{
	public PWSTR sk_attrtype;
	public PWSTR sk_matchruleoid;
	public BOOLEAN sk_reverseorder;
}

[CRepr]
public struct LDAPSortKeyA
{
	public PSTR sk_attrtype;
	public PSTR sk_matchruleoid;
	public BOOLEAN sk_reverseorder;
}

[CRepr]
public struct LDAPVLVInfo
{
	public int32 ldvlv_version;
	public uint32 ldvlv_before_count;
	public uint32 ldvlv_after_count;
	public uint32 ldvlv_offset;
	public uint32 ldvlv_count;
	public LDAP_BERVAL* ldvlv_attrvalue;
	public LDAP_BERVAL* ldvlv_context;
	public void* ldvlv_extradata;
}

[CRepr]
public struct LDAP_REFERRAL_CALLBACK
{
	public uint32 SizeOfCallbacks;
	public QUERYFORCONNECTION QueryForConnection;
	public NOTIFYOFNEWCONNECTION NotifyRoutine;
	public DEREFERENCECONNECTION DereferenceRoutine;
}

#endregion

#region Functions
public static
{
	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_openW(PWSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_openA(PSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_initW(PWSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_initA(PSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_sslinitW(PWSTR HostName, uint32 PortNumber, int32 secure);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_sslinitA(PSTR HostName, uint32 PortNumber, int32 secure);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_connect(LDAP* ld, LDAP_TIMEVAL* timeout);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_open(PSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_init(PSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_sslinit(PSTR HostName, uint32 PortNumber, int32 secure);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* cldap_openW(PWSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* cldap_openA(PSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* cldap_open(PSTR HostName, uint32 PortNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_unbind(LDAP* ld);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_unbind_s(LDAP* ld);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_get_option(LDAP* ld, int32 option, void* outvalue);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_get_optionW(LDAP* ld, int32 option, void* outvalue);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_set_option(LDAP* ld, int32 option, void* invalue);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_set_optionW(LDAP* ld, int32 option, void* invalue);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_simple_bindW(LDAP* ld, PWSTR dn, PWSTR passwd);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_simple_bindA(LDAP* ld, PSTR dn, PSTR passwd);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_simple_bind_sW(LDAP* ld, PWSTR dn, PWSTR passwd);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_simple_bind_sA(LDAP* ld, PSTR dn, PSTR passwd);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_bindW(LDAP* ld, PWSTR dn, PWSTR cred, uint32 method);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_bindA(LDAP* ld, PSTR dn, PSTR cred, uint32 method);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_bind_sW(LDAP* ld, PWSTR dn, PWSTR cred, uint32 method);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_bind_sA(LDAP* ld, PSTR dn, PSTR cred, uint32 method);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_sasl_bindA(LDAP* ExternalHandle, PSTR DistName, PSTR AuthMechanism, LDAP_BERVAL* cred, LDAPControlA** ServerCtrls, LDAPControlA** ClientCtrls, int32* MessageNumber);
	public static int32 ldap_sasl_bind(LDAP* ExternalHandle, PSTR DistName, PSTR AuthMechanism, LDAP_BERVAL* cred, LDAPControlA** ServerCtrls, LDAPControlA** ClientCtrls, int32* MessageNumber) => ldap_sasl_bindA(ExternalHandle, DistName, AuthMechanism, cred, ServerCtrls, ClientCtrls, MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_sasl_bindW(LDAP* ExternalHandle, PWSTR DistName, PWSTR AuthMechanism, LDAP_BERVAL* cred, LDAPControlW** ServerCtrls, LDAPControlW** ClientCtrls, int32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_sasl_bind_sA(LDAP* ExternalHandle, PSTR DistName, PSTR AuthMechanism, LDAP_BERVAL* cred, LDAPControlA** ServerCtrls, LDAPControlA** ClientCtrls, LDAP_BERVAL** ServerData);
	public static int32 ldap_sasl_bind_s(LDAP* ExternalHandle, PSTR DistName, PSTR AuthMechanism, LDAP_BERVAL* cred, LDAPControlA** ServerCtrls, LDAPControlA** ClientCtrls, LDAP_BERVAL** ServerData) => ldap_sasl_bind_sA(ExternalHandle, DistName, AuthMechanism, cred, ServerCtrls, ClientCtrls, ServerData);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_sasl_bind_sW(LDAP* ExternalHandle, PWSTR DistName, PWSTR AuthMechanism, LDAP_BERVAL* cred, LDAPControlW** ServerCtrls, LDAPControlW** ClientCtrls, LDAP_BERVAL** ServerData);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_simple_bind(LDAP* ld, PSTR dn, PSTR passwd);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_simple_bind_s(LDAP* ld, PSTR dn, PSTR passwd);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_bind(LDAP* ld, PSTR dn, PSTR cred, uint32 method);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_bind_s(LDAP* ld, PSTR dn, PSTR cred, uint32 method);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_searchW(LDAP* ld, PWSTR @base, uint32 @scope, PWSTR filter, uint16** attrs, uint32 attrsonly);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_searchA(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_sW(LDAP* ld, PWSTR @base, uint32 @scope, PWSTR filter, uint16** attrs, uint32 attrsonly, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_sA(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_stW(LDAP* ld, PWSTR @base, uint32 @scope, PWSTR filter, uint16** attrs, uint32 attrsonly, LDAP_TIMEVAL* timeout, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_stA(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAP_TIMEVAL* timeout, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_extW(LDAP* ld, PWSTR @base, uint32 @scope, PWSTR filter, uint16** attrs, uint32 attrsonly, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32 TimeLimit, uint32 SizeLimit, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_extA(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32 TimeLimit, uint32 SizeLimit, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_ext_sW(LDAP* ld, PWSTR @base, uint32 @scope, PWSTR filter, uint16** attrs, uint32 attrsonly, LDAPControlW** ServerControls, LDAPControlW** ClientControls, LDAP_TIMEVAL* timeout, uint32 SizeLimit, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_ext_sA(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAPControlA** ServerControls, LDAPControlA** ClientControls, LDAP_TIMEVAL* timeout, uint32 SizeLimit, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_s(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_st(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAP_TIMEVAL* timeout, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_ext(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32 TimeLimit, uint32 SizeLimit, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_ext_s(LDAP* ld, PSTR @base, uint32 @scope, PSTR filter, int8** attrs, uint32 attrsonly, LDAPControlA** ServerControls, LDAPControlA** ClientControls, LDAP_TIMEVAL* timeout, uint32 SizeLimit, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_check_filterW(LDAP* ld, PWSTR SearchFilter);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_check_filterA(LDAP* ld, PSTR SearchFilter);
	public static uint32 ldap_check_filter(LDAP* ld, PSTR SearchFilter) => ldap_check_filterA(ld, SearchFilter);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modifyW(LDAP* ld, PWSTR dn, LDAPModW** mods);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modifyA(LDAP* ld, PSTR dn, LDAPModA** mods);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_sW(LDAP* ld, PWSTR dn, LDAPModW** mods);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_sA(LDAP* ld, PSTR dn, LDAPModA** mods);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_extW(LDAP* ld, PWSTR dn, LDAPModW** mods, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_extA(LDAP* ld, PSTR dn, LDAPModA** mods, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_ext_sW(LDAP* ld, PWSTR dn, LDAPModW** mods, LDAPControlW** ServerControls, LDAPControlW** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_ext_sA(LDAP* ld, PSTR dn, LDAPModA** mods, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify(LDAP* ld, PSTR dn, LDAPModA** mods);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_s(LDAP* ld, PSTR dn, LDAPModA** mods);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_ext(LDAP* ld, PSTR dn, LDAPModA** mods, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modify_ext_s(LDAP* ld, PSTR dn, LDAPModA** mods, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn2W(LDAP* ExternalHandle, PWSTR DistinguishedName, PWSTR NewDistinguishedName, int32 DeleteOldRdn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn2A(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName, int32 DeleteOldRdn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdnW(LDAP* ExternalHandle, PWSTR DistinguishedName, PWSTR NewDistinguishedName);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdnA(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn2_sW(LDAP* ExternalHandle, PWSTR DistinguishedName, PWSTR NewDistinguishedName, int32 DeleteOldRdn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn2_sA(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName, int32 DeleteOldRdn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn_sW(LDAP* ExternalHandle, PWSTR DistinguishedName, PWSTR NewDistinguishedName);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn_sA(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn2(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName, int32 DeleteOldRdn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn2_s(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName, int32 DeleteOldRdn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_modrdn_s(LDAP* ExternalHandle, PSTR DistinguishedName, PSTR NewDistinguishedName);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_rename_extW(LDAP* ld, PWSTR dn, PWSTR NewRDN, PWSTR NewParent, int32 DeleteOldRdn, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_rename_extA(LDAP* ld, PSTR dn, PSTR NewRDN, PSTR NewParent, int32 DeleteOldRdn, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_rename_ext_sW(LDAP* ld, PWSTR dn, PWSTR NewRDN, PWSTR NewParent, int32 DeleteOldRdn, LDAPControlW** ServerControls, LDAPControlW** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_rename_ext_sA(LDAP* ld, PSTR dn, PSTR NewRDN, PSTR NewParent, int32 DeleteOldRdn, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_rename_ext(LDAP* ld, PSTR dn, PSTR NewRDN, PSTR NewParent, int32 DeleteOldRdn, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_rename_ext_s(LDAP* ld, PSTR dn, PSTR NewRDN, PSTR NewParent, int32 DeleteOldRdn, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_addW(LDAP* ld, PWSTR dn, LDAPModW** attrs);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_addA(LDAP* ld, PSTR dn, LDAPModA** attrs);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_sW(LDAP* ld, PWSTR dn, LDAPModW** attrs);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_sA(LDAP* ld, PSTR dn, LDAPModA** attrs);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_extW(LDAP* ld, PWSTR dn, LDAPModW** attrs, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_extA(LDAP* ld, PSTR dn, LDAPModA** attrs, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_ext_sW(LDAP* ld, PWSTR dn, LDAPModW** attrs, LDAPControlW** ServerControls, LDAPControlW** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_ext_sA(LDAP* ld, PSTR dn, LDAPModA** attrs, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add(LDAP* ld, PSTR dn, LDAPModA** attrs);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_s(LDAP* ld, PSTR dn, LDAPModA** attrs);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_ext(LDAP* ld, PSTR dn, LDAPModA** attrs, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_add_ext_s(LDAP* ld, PSTR dn, LDAPModA** attrs, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compareW(LDAP* ld, PWSTR dn, PWSTR attr, PWSTR value);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compareA(LDAP* ld, PSTR dn, PSTR attr, PSTR value);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_sW(LDAP* ld, PWSTR dn, PWSTR attr, PWSTR value);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_sA(LDAP* ld, PSTR dn, PSTR attr, PSTR value);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare(LDAP* ld, PSTR dn, PSTR attr, PSTR value);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_s(LDAP* ld, PSTR dn, PSTR attr, PSTR value);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_extW(LDAP* ld, PWSTR dn, PWSTR Attr, PWSTR Value, LDAP_BERVAL* Data, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_extA(LDAP* ld, PSTR dn, PSTR Attr, PSTR Value, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_ext_sW(LDAP* ld, PWSTR dn, PWSTR Attr, PWSTR Value, LDAP_BERVAL* Data, LDAPControlW** ServerControls, LDAPControlW** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_ext_sA(LDAP* ld, PSTR dn, PSTR Attr, PSTR Value, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_ext(LDAP* ld, PSTR dn, PSTR Attr, PSTR Value, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_compare_ext_s(LDAP* ld, PSTR dn, PSTR Attr, PSTR Value, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_deleteW(LDAP* ld, PWSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_deleteA(LDAP* ld, PSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_sW(LDAP* ld, PWSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_sA(LDAP* ld, PSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_extW(LDAP* ld, PWSTR dn, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_extA(LDAP* ld, PSTR dn, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_ext_sW(LDAP* ld, PWSTR dn, LDAPControlW** ServerControls, LDAPControlW** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_ext_sA(LDAP* ld, PSTR dn, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete(LDAP* ld, PSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_s(LDAP* ld, PSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_ext(LDAP* ld, PSTR dn, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_delete_ext_s(LDAP* ld, PSTR dn, LDAPControlA** ServerControls, LDAPControlA** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_abandon(LDAP* ld, uint32 msgid);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_result(LDAP* ld, uint32 msgid, uint32 all, LDAP_TIMEVAL* timeout, LDAPMessage** res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_msgfree(LDAPMessage* res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_result2error(LDAP* ld, LDAPMessage* res, uint32 freeit);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_resultW(LDAP* Connection, LDAPMessage* ResultMessage, uint32* ReturnCode, PWSTR* MatchedDNs, PWSTR* ErrorMessage, uint16*** Referrals, LDAPControlW*** ServerControls, BOOLEAN Freeit);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_resultA(LDAP* Connection, LDAPMessage* ResultMessage, uint32* ReturnCode, PSTR* MatchedDNs, PSTR* ErrorMessage, int8*** Referrals, LDAPControlA*** ServerControls, BOOLEAN Freeit);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_extended_resultA(LDAP* Connection, LDAPMessage* ResultMessage, PSTR* ResultOID, LDAP_BERVAL** ResultData, BOOLEAN Freeit);
	public static uint32 ldap_parse_extended_result(LDAP* Connection, LDAPMessage* ResultMessage, PSTR* ResultOID, LDAP_BERVAL** ResultData, BOOLEAN Freeit) => ldap_parse_extended_resultA(Connection, ResultMessage, ResultOID, ResultData, Freeit);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_extended_resultW(LDAP* Connection, LDAPMessage* ResultMessage, PWSTR* ResultOID, LDAP_BERVAL** ResultData, BOOLEAN Freeit);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_controls_freeA(LDAPControlA** Controls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_control_freeA(LDAPControlA* Controls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_controls_freeW(LDAPControlW** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_control_freeW(LDAPControlW* Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_free_controlsW(LDAPControlW** Controls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_free_controlsA(LDAPControlA** Controls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_result(LDAP* Connection, LDAPMessage* ResultMessage, uint32* ReturnCode, PSTR* MatchedDNs, PSTR* ErrorMessage, PSTR** Referrals, LDAPControlA*** ServerControls, BOOLEAN Freeit);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_controls_free(LDAPControlA** Controls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_control_free(LDAPControlA* Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_free_controls(LDAPControlA** Controls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ldap_err2stringW(uint32 err);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_err2stringA(uint32 err);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_err2string(uint32 err);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ldap_perror(LDAP* ld, PSTR msg);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPMessage* ldap_first_entry(LDAP* ld, LDAPMessage* res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPMessage* ldap_next_entry(LDAP* ld, LDAPMessage* entry);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_count_entries(LDAP* ld, LDAPMessage* res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ldap_first_attributeW(LDAP* ld, LDAPMessage* entry, BerElement** ptr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_first_attributeA(LDAP* ld, LDAPMessage* entry, BerElement** ptr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_first_attribute(LDAP* ld, LDAPMessage* entry, BerElement** ptr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ldap_next_attributeW(LDAP* ld, LDAPMessage* entry, BerElement* ptr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_next_attributeA(LDAP* ld, LDAPMessage* entry, BerElement* ptr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_next_attribute(LDAP* ld, LDAPMessage* entry, BerElement* ptr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR* ldap_get_valuesW(LDAP* ld, LDAPMessage* entry, PWSTR attr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR* ldap_get_valuesA(LDAP* ld, LDAPMessage* entry, PSTR attr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR* ldap_get_values(LDAP* ld, LDAPMessage* entry, PSTR attr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP_BERVAL** ldap_get_values_lenW(LDAP* ExternalHandle, LDAPMessage* Message, PWSTR attr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP_BERVAL** ldap_get_values_lenA(LDAP* ExternalHandle, LDAPMessage* Message, PSTR attr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP_BERVAL** ldap_get_values_len(LDAP* ExternalHandle, LDAPMessage* Message, PSTR attr);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_count_valuesW(PWSTR* vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_count_valuesA(PSTR* vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_count_values(PSTR* vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_count_values_len(LDAP_BERVAL** vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_value_freeW(PWSTR* vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_value_freeA(PSTR* vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_value_free(PSTR* vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_value_free_len(LDAP_BERVAL** vals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ldap_get_dnW(LDAP* ld, LDAPMessage* entry);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_get_dnA(LDAP* ld, LDAPMessage* entry);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_get_dn(LDAP* ld, LDAPMessage* entry);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR* ldap_explode_dnW(PWSTR dn, uint32 notypes);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR* ldap_explode_dnA(PSTR dn, uint32 notypes);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR* ldap_explode_dn(PSTR dn, uint32 notypes);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ldap_dn2ufnW(PWSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_dn2ufnA(PSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ldap_dn2ufn(PSTR dn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ldap_memfreeW(PWSTR Block);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ldap_memfreeA(PSTR Block);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ber_bvfree(LDAP_BERVAL* bv);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ldap_memfree(PSTR Block);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_ufn2dnW(PWSTR ufn, PWSTR* pDn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_ufn2dnA(PSTR ufn, PSTR* pDn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_ufn2dn(PSTR ufn, PSTR* pDn);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_startup(LDAP_VERSION_INFO* version, HANDLE* Instance);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_cleanup(HANDLE hInstance);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_escape_filter_elementW(PSTR sourceFilterElement, uint32 sourceLength, PWSTR destFilterElement, uint32 destLength);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_escape_filter_elementA(PSTR sourceFilterElement, uint32 sourceLength, PSTR destFilterElement, uint32 destLength);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_escape_filter_element(PSTR sourceFilterElement, uint32 sourceLength, PSTR destFilterElement, uint32 destLength);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_set_dbg_flags(uint32 NewFlags);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ldap_set_dbg_routine(DBGPRINT DebugPrintRoutine);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LdapUTF8ToUnicode(uint8* lpSrcStr, int32 cchSrc, char16* lpDestStr, int32 cchDest);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LdapUnicodeToUTF8(char16* lpSrcStr, int32 cchSrc, uint8* lpDestStr, int32 cchDest);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_create_sort_controlA(LDAP* ExternalHandle, LDAPSortKeyA** SortKeys, uint8 IsCritical, LDAPControlA** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_create_sort_controlW(LDAP* ExternalHandle, LDAPSortKeyW** SortKeys, uint8 IsCritical, LDAPControlW** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_sort_controlA(LDAP* ExternalHandle, LDAPControlA** Control, uint32* Result, PSTR* Attribute);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_sort_controlW(LDAP* ExternalHandle, LDAPControlW** Control, uint32* Result, PWSTR* Attribute);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_create_sort_control(LDAP* ExternalHandle, LDAPSortKeyA** SortKeys, uint8 IsCritical, LDAPControlA** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_sort_control(LDAP* ExternalHandle, LDAPControlA** Control, uint32* Result, PSTR* Attribute);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_encode_sort_controlW(LDAP* ExternalHandle, LDAPSortKeyW** SortKeys, LDAPControlW* Control, BOOLEAN Criticality);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_encode_sort_controlA(LDAP* ExternalHandle, LDAPSortKeyA** SortKeys, LDAPControlA* Control, BOOLEAN Criticality);
	public static uint32 ldap_encode_sort_control(LDAP* ExternalHandle, LDAPSortKeyA** SortKeys, LDAPControlA* Control, BOOLEAN Criticality) => ldap_encode_sort_controlA(ExternalHandle, SortKeys, Control, Criticality);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_create_page_controlW(LDAP* ExternalHandle, uint32 PageSize, LDAP_BERVAL* Cookie, uint8 IsCritical, LDAPControlW** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_create_page_controlA(LDAP* ExternalHandle, uint32 PageSize, LDAP_BERVAL* Cookie, uint8 IsCritical, LDAPControlA** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_page_controlW(LDAP* ExternalHandle, LDAPControlW** ServerControls, uint32* TotalCount, LDAP_BERVAL** Cookie);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_page_controlA(LDAP* ExternalHandle, LDAPControlA** ServerControls, uint32* TotalCount, LDAP_BERVAL** Cookie);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_create_page_control(LDAP* ExternalHandle, uint32 PageSize, LDAP_BERVAL* Cookie, uint8 IsCritical, LDAPControlA** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_page_control(LDAP* ExternalHandle, LDAPControlA** ServerControls, uint32* TotalCount, LDAP_BERVAL** Cookie);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPSearch* ldap_search_init_pageW(LDAP* ExternalHandle, PWSTR DistinguishedName, uint32 ScopeOfSearch, PWSTR SearchFilter, uint16** AttributeList, uint32 AttributesOnly, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32 PageTimeLimit, uint32 TotalSizeLimit, LDAPSortKeyW** SortKeys);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPSearch* ldap_search_init_pageA(LDAP* ExternalHandle, PSTR DistinguishedName, uint32 ScopeOfSearch, PSTR SearchFilter, int8** AttributeList, uint32 AttributesOnly, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32 PageTimeLimit, uint32 TotalSizeLimit, LDAPSortKeyA** SortKeys);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPSearch* ldap_search_init_page(LDAP* ExternalHandle, PSTR DistinguishedName, uint32 ScopeOfSearch, PSTR SearchFilter, int8** AttributeList, uint32 AttributesOnly, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32 PageTimeLimit, uint32 TotalSizeLimit, LDAPSortKeyA** SortKeys);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_get_next_page(LDAP* ExternalHandle, LDAPSearch* SearchHandle, uint32 PageSize, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_get_next_page_s(LDAP* ExternalHandle, LDAPSearch* SearchHandle, LDAP_TIMEVAL* timeout, uint32 PageSize, uint32* TotalCount, LDAPMessage** Results);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_get_paged_count(LDAP* ExternalHandle, LDAPSearch* SearchBlock, uint32* TotalCount, LDAPMessage* Results);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_search_abandon_page(LDAP* ExternalHandle, LDAPSearch* SearchBlock);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_create_vlv_controlW(LDAP* ExternalHandle, LDAPVLVInfo* VlvInfo, uint8 IsCritical, LDAPControlW** Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_create_vlv_controlA(LDAP* ExternalHandle, LDAPVLVInfo* VlvInfo, uint8 IsCritical, LDAPControlA** Control);
	public static int32 ldap_create_vlv_control(LDAP* ExternalHandle, LDAPVLVInfo* VlvInfo, uint8 IsCritical, LDAPControlA** Control) => ldap_create_vlv_controlA(ExternalHandle, VlvInfo, IsCritical, Control);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_parse_vlv_controlW(LDAP* ExternalHandle, LDAPControlW** Control, uint32* TargetPos, uint32* ListCount, LDAP_BERVAL** Context, int32* ErrCode);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ldap_parse_vlv_controlA(LDAP* ExternalHandle, LDAPControlA** Control, uint32* TargetPos, uint32* ListCount, LDAP_BERVAL** Context, int32* ErrCode);
	public static int32 ldap_parse_vlv_control(LDAP* ExternalHandle, LDAPControlA** Control, uint32* TargetPos, uint32* ListCount, LDAP_BERVAL** Context, int32* ErrCode) => ldap_parse_vlv_controlA(ExternalHandle, Control, TargetPos, ListCount, Context, ErrCode);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_start_tls_sW(LDAP* ExternalHandle, uint32* ServerReturnValue, LDAPMessage** result, LDAPControlW** ServerControls, LDAPControlW** ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_start_tls_sA(LDAP* ExternalHandle, uint32* ServerReturnValue, LDAPMessage** result, LDAPControlA** ServerControls, LDAPControlA** ClientControls);
	public static uint32 ldap_start_tls_s(LDAP* ExternalHandle, uint32* ServerReturnValue, LDAPMessage** result, LDAPControlA** ServerControls, LDAPControlA** ClientControls) => ldap_start_tls_sA(ExternalHandle, ServerReturnValue, result, ServerControls, ClientControls);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN ldap_stop_tls_s(LDAP* ExternalHandle);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPMessage* ldap_first_reference(LDAP* ld, LDAPMessage* res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAPMessage* ldap_next_reference(LDAP* ld, LDAPMessage* entry);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_count_references(LDAP* ld, LDAPMessage* res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_referenceW(LDAP* Connection, LDAPMessage* ResultMessage, PWSTR** Referrals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_referenceA(LDAP* Connection, LDAPMessage* ResultMessage, PSTR** Referrals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_parse_reference(LDAP* Connection, LDAPMessage* ResultMessage, PSTR** Referrals);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_extended_operationW(LDAP* ld, PWSTR Oid, LDAP_BERVAL* Data, LDAPControlW** ServerControls, LDAPControlW** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_extended_operationA(LDAP* ld, PSTR Oid, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_extended_operation_sA(LDAP* ExternalHandle, PSTR Oid, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls, PSTR* ReturnedOid, LDAP_BERVAL** ReturnedData);
	public static uint32 ldap_extended_operation_s(LDAP* ExternalHandle, PSTR Oid, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls, PSTR* ReturnedOid, LDAP_BERVAL** ReturnedData) => ldap_extended_operation_sA(ExternalHandle, Oid, Data, ServerControls, ClientControls, ReturnedOid, ReturnedData);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_extended_operation_sW(LDAP* ExternalHandle, PWSTR Oid, LDAP_BERVAL* Data, LDAPControlW** ServerControls, LDAPControlW** ClientControls, PWSTR* ReturnedOid, LDAP_BERVAL** ReturnedData);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_extended_operation(LDAP* ld, PSTR Oid, LDAP_BERVAL* Data, LDAPControlA** ServerControls, LDAPControlA** ClientControls, uint32* MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ldap_close_extended_op(LDAP* ld, uint32 MessageNumber);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LdapGetLastError();

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LdapMapErrorToWin32(uint32 LdapError);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP* ldap_conn_from_msg(LDAP* PrimaryConn, LDAPMessage* res);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BerElement* ber_init(LDAP_BERVAL* pBerVal);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ber_free(BerElement* pBerElement, int32 fbuf);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ber_bvecfree(LDAP_BERVAL** pBerVal);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LDAP_BERVAL* ber_bvdup(LDAP_BERVAL* pBerVal);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BerElement* ber_alloc_t(int32 options);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ber_skip_tag(BerElement* pBerElement, uint32* pLen);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ber_peek_tag(BerElement* pBerElement, uint32* pLen);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ber_first_element(BerElement* pBerElement, uint32* pLen, CHAR** ppOpaque);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ber_next_element(BerElement* pBerElement, uint32* pLen, PSTR opaque);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ber_flatten(BerElement* pBerElement, LDAP_BERVAL** pBerVal);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ber_printf(BerElement* pBerElement, PSTR fmt);

	[Import("WLDAP32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ber_scanf(BerElement* pBerElement, PSTR fmt);

}
#endregion
