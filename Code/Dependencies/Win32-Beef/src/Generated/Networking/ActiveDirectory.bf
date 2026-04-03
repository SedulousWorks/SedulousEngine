using Win32.Foundation;
using Win32.UI.WindowsAndMessaging;
using Win32.System.Com;
using Win32.System.Registry;
using Win32.System.Com.StructuredStorage;
using Win32.UI.Shell;
using Win32.UI.Controls;
using Win32.System.Ole;
using Win32.Security;
using Win32.Networking.WinSock;
using Win32.Security.Authentication.Identity;
using System;

namespace Win32.Networking.ActiveDirectory;

#region Constants
public static
{
	public const uint32 WM_ADSPROP_NOTIFY_PAGEINIT = 2125;
	public const uint32 WM_ADSPROP_NOTIFY_PAGEHWND = 2126;
	public const uint32 WM_ADSPROP_NOTIFY_CHANGE = 2127;
	public const uint32 WM_ADSPROP_NOTIFY_APPLY = 2128;
	public const uint32 WM_ADSPROP_NOTIFY_SETFOCUS = 2129;
	public const uint32 WM_ADSPROP_NOTIFY_FOREGROUND = 2130;
	public const uint32 WM_ADSPROP_NOTIFY_EXIT = 2131;
	public const uint32 WM_ADSPROP_NOTIFY_ERROR = 2134;
	public const Guid CLSID_CommonQuery = .(0x83bc5ec0, 0x6f2a, 0x11d0, 0xa1, 0xc4, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const uint64 QUERYFORM_CHANGESFORMLIST = 1;
	public const uint64 QUERYFORM_CHANGESOPTFORMLIST = 2;
	public const uint32 CQFF_NOGLOBALPAGES = 1;
	public const uint32 CQFF_ISOPTIONAL = 2;
	public const uint32 CQPM_INITIALIZE = 1;
	public const uint32 CQPM_RELEASE = 2;
	public const uint32 CQPM_ENABLE = 3;
	public const uint32 CQPM_GETPARAMETERS = 5;
	public const uint32 CQPM_CLEARFORM = 6;
	public const uint32 CQPM_PERSIST = 7;
	public const uint32 CQPM_HELP = 8;
	public const uint32 CQPM_SETDEFAULTPARAMETERS = 9;
	public const uint32 CQPM_HANDLERSPECIFIC = 268435456;
	public const uint32 OQWF_OKCANCEL = 1;
	public const uint32 OQWF_DEFAULTFORM = 2;
	public const uint32 OQWF_SINGLESELECT = 4;
	public const uint32 OQWF_LOADQUERY = 8;
	public const uint32 OQWF_REMOVESCOPES = 16;
	public const uint32 OQWF_REMOVEFORMS = 32;
	public const uint32 OQWF_ISSUEONOPEN = 64;
	public const uint32 OQWF_SHOWOPTIONAL = 128;
	public const uint32 OQWF_SAVEQUERYONOK = 512;
	public const uint32 OQWF_HIDEMENUS = 1024;
	public const uint32 OQWF_HIDESEARCHUI = 2048;
	public const uint32 OQWF_PARAMISPROPERTYBAG = 2147483648;
	public const Guid CLSID_DsAdminCreateObj = .(0xe301a009, 0xf901, 0x11d2, 0x82, 0xb9, 0x00, 0xc0, 0x4f, 0x68, 0x92, 0x8b);
	public const uint32 DSA_NEWOBJ_CTX_PRECOMMIT = 1;
	public const uint32 DSA_NEWOBJ_CTX_COMMIT = 2;
	public const uint32 DSA_NEWOBJ_CTX_POSTCOMMIT = 3;
	public const uint32 DSA_NEWOBJ_CTX_CLEANUP = 4;
	public const uint32 DSA_NOTIFY_DEL = 1;
	public const uint32 DSA_NOTIFY_REN = 2;
	public const uint32 DSA_NOTIFY_MOV = 4;
	public const uint32 DSA_NOTIFY_PROP = 8;
	public const uint32 DSA_NOTIFY_FLAG_ADDITIONAL_DATA = 2;
	public const uint32 DSA_NOTIFY_FLAG_FORCE_ADDITIONAL_DATA = 1;
	public const Guid CLSID_MicrosoftDS = .(0xfe1290f0, 0xcfbd, 0x11cf, 0xa3, 0x30, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const Guid CLSID_DsPropertyPages = .(0x0d45d530, 0x764b, 0x11d0, 0xa1, 0xca, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const Guid CLSID_DsDomainTreeBrowser = .(0x1698790a, 0xe2b4, 0x11d0, 0xb0, 0xb1, 0x00, 0xc0, 0x4f, 0xd8, 0xdc, 0xa6);
	public const Guid CLSID_DsDisplaySpecifier = .(0x1ab4a8c0, 0x6a0b, 0x11d2, 0xad, 0x49, 0x00, 0xc0, 0x4f, 0xa3, 0x1a, 0x86);
	public const Guid CLSID_DsFolderProperties = .(0x9e51e0d0, 0x6e0f, 0x11d2, 0x96, 0x01, 0x00, 0xc0, 0x4f, 0xa3, 0x1a, 0x86);
	public const uint32 DSOBJECT_ISCONTAINER = 1;
	public const uint32 DSOBJECT_READONLYPAGES = 2147483648;
	public const uint32 DSPROVIDER_UNUSED_0 = 1;
	public const uint32 DSPROVIDER_UNUSED_1 = 2;
	public const uint32 DSPROVIDER_UNUSED_2 = 4;
	public const uint32 DSPROVIDER_UNUSED_3 = 8;
	public const uint32 DSPROVIDER_ADVANCED = 16;
	public const uint32 DSPROVIDER_AD_LDS = 32;
	public const String CFSTR_DSOBJECTNAMES = "DsObjectNames";
	public const String CFSTR_DS_DISPLAY_SPEC_OPTIONS = "DsDisplaySpecOptions";
	public const String CFSTR_DSDISPLAYSPECOPTIONS = "DsDisplaySpecOptions";
	public const String DS_PROP_SHELL_PREFIX = "shell";
	public const String DS_PROP_ADMIN_PREFIX = "admin";
	public const uint32 DSDSOF_HASUSERANDSERVERINFO = 1;
	public const uint32 DSDSOF_SIMPLEAUTHENTICATE = 2;
	public const uint32 DSDSOF_DONTSIGNSEAL = 4;
	public const uint32 DSDSOF_DSAVAILABLE = 1073741824;
	public const String CFSTR_DSPROPERTYPAGEINFO = "DsPropPageInfo";
	public const String DSPROP_ATTRCHANGED_MSG = "DsPropAttrChanged";
	public const uint32 DBDTF_RETURNFQDN = 1;
	public const uint32 DBDTF_RETURNMIXEDDOMAINS = 2;
	public const uint32 DBDTF_RETURNEXTERNAL = 4;
	public const uint32 DBDTF_RETURNINBOUND = 8;
	public const uint32 DBDTF_RETURNINOUTBOUND = 16;
	public const uint32 DSSSF_SIMPLEAUTHENTICATE = 1;
	public const uint32 DSSSF_DONTSIGNSEAL = 2;
	public const uint32 DSSSF_DSAVAILABLE = 2147483648;
	public const uint32 DSGIF_ISNORMAL = 0;
	public const uint32 DSGIF_ISOPEN = 1;
	public const uint32 DSGIF_ISDISABLED = 2;
	public const uint32 DSGIF_ISMASK = 15;
	public const uint32 DSGIF_GETDEFAULTICON = 16;
	public const uint32 DSGIF_DEFAULTISCONTAINER = 32;
	public const uint32 DSICCF_IGNORETREATASLEAF = 1;
	public const uint32 DSECAF_NOTLISTED = 1;
	public const uint32 DSCCIF_HASWIZARDDIALOG = 1;
	public const uint32 DSCCIF_HASWIZARDPRIMARYPAGE = 2;
	public const uint32 DSBI_NOBUTTONS = 1;
	public const uint32 DSBI_NOLINES = 2;
	public const uint32 DSBI_NOLINESATROOT = 4;
	public const uint32 DSBI_CHECKBOXES = 256;
	public const uint32 DSBI_NOROOT = 65536;
	public const uint32 DSBI_INCLUDEHIDDEN = 131072;
	public const uint32 DSBI_EXPANDONOPEN = 262144;
	public const uint32 DSBI_ENTIREDIRECTORY = 589824;
	public const uint32 DSBI_RETURN_FORMAT = 1048576;
	public const uint32 DSBI_HASCREDENTIALS = 2097152;
	public const uint32 DSBI_IGNORETREATASLEAF = 4194304;
	public const uint32 DSBI_SIMPLEAUTHENTICATE = 8388608;
	public const uint32 DSBI_RETURNOBJECTCLASS = 16777216;
	public const uint32 DSBI_DONTSIGNSEAL = 33554432;
	public const uint32 DSB_MAX_DISPLAYNAME_CHARS = 64;
	public const uint32 DSBF_STATE = 1;
	public const uint32 DSBF_ICONLOCATION = 2;
	public const uint32 DSBF_DISPLAYNAME = 4;
	public const uint32 DSBS_CHECKED = 1;
	public const uint32 DSBS_HIDDEN = 2;
	public const uint32 DSBS_ROOT = 4;
	public const uint32 DSBM_QUERYINSERTW = 100;
	public const uint32 DSBM_QUERYINSERTA = 101;
	public const uint32 DSBM_QUERYINSERT = 100;
	public const uint32 DSBM_CHANGEIMAGESTATE = 102;
	public const uint32 DSBM_HELP = 103;
	public const uint32 DSBM_CONTEXTMENU = 104;
	public const uint32 DSBID_BANNER = 256;
	public const uint32 DSBID_CONTAINERLIST = 257;
	public const uint32 DS_FORCE_REDISCOVERY = 1;
	public const uint32 DS_DIRECTORY_SERVICE_REQUIRED = 16;
	public const uint32 DS_DIRECTORY_SERVICE_PREFERRED = 32;
	public const uint32 DS_GC_SERVER_REQUIRED = 64;
	public const uint32 DS_PDC_REQUIRED = 128;
	public const uint32 DS_BACKGROUND_ONLY = 256;
	public const uint32 DS_IP_REQUIRED = 512;
	public const uint32 DS_KDC_REQUIRED = 1024;
	public const uint32 DS_TIMESERV_REQUIRED = 2048;
	public const uint32 DS_WRITABLE_REQUIRED = 4096;
	public const uint32 DS_GOOD_TIMESERV_PREFERRED = 8192;
	public const uint32 DS_AVOID_SELF = 16384;
	public const uint32 DS_ONLY_LDAP_NEEDED = 32768;
	public const uint32 DS_IS_FLAT_NAME = 65536;
	public const uint32 DS_IS_DNS_NAME = 131072;
	public const uint32 DS_TRY_NEXTCLOSEST_SITE = 262144;
	public const uint32 DS_DIRECTORY_SERVICE_6_REQUIRED = 524288;
	public const uint32 DS_WEB_SERVICE_REQUIRED = 1048576;
	public const uint32 DS_DIRECTORY_SERVICE_8_REQUIRED = 2097152;
	public const uint32 DS_DIRECTORY_SERVICE_9_REQUIRED = 4194304;
	public const uint32 DS_DIRECTORY_SERVICE_10_REQUIRED = 8388608;
	public const uint32 DS_KEY_LIST_SUPPORT_REQUIRED = 16777216;
	public const uint32 DS_RETURN_DNS_NAME = 1073741824;
	public const uint32 DS_RETURN_FLAT_NAME = 2147483648;
	public const uint32 DS_PDC_FLAG = 1;
	public const uint32 DS_GC_FLAG = 4;
	public const uint32 DS_LDAP_FLAG = 8;
	public const uint32 DS_DS_FLAG = 16;
	public const uint32 DS_KDC_FLAG = 32;
	public const uint32 DS_TIMESERV_FLAG = 64;
	public const uint32 DS_CLOSEST_FLAG = 128;
	public const uint32 DS_WRITABLE_FLAG = 256;
	public const uint32 DS_GOOD_TIMESERV_FLAG = 512;
	public const uint32 DS_NDNC_FLAG = 1024;
	public const uint32 DS_SELECT_SECRET_DOMAIN_6_FLAG = 2048;
	public const uint32 DS_FULL_SECRET_DOMAIN_6_FLAG = 4096;
	public const uint32 DS_WS_FLAG = 8192;
	public const uint32 DS_DS_8_FLAG = 16384;
	public const uint32 DS_DS_9_FLAG = 32768;
	public const uint32 DS_DS_10_FLAG = 65536;
	public const uint32 DS_KEY_LIST_FLAG = 131072;
	public const uint32 DS_PING_FLAGS = 1048575;
	public const uint32 DS_DNS_CONTROLLER_FLAG = 536870912;
	public const uint32 DS_DNS_DOMAIN_FLAG = 1073741824;
	public const uint32 DS_DNS_FOREST_FLAG = 2147483648;
	public const uint32 DS_DOMAIN_IN_FOREST = 1;
	public const uint32 DS_DOMAIN_DIRECT_OUTBOUND = 2;
	public const uint32 DS_DOMAIN_TREE_ROOT = 4;
	public const uint32 DS_DOMAIN_PRIMARY = 8;
	public const uint32 DS_DOMAIN_NATIVE_MODE = 16;
	public const uint32 DS_DOMAIN_DIRECT_INBOUND = 32;
	public const uint32 DS_GFTI_UPDATE_TDO = 1;
	public const uint32 DS_GFTI_VALID_FLAGS = 1;
	public const uint32 DS_ONLY_DO_SITE_NAME = 1;
	public const uint32 DS_NOTIFY_AFTER_SITE_RECORDS = 2;
	public const Guid CLSID_DsQuery = .(0x8a23e65e, 0x31c2, 0x11d0, 0x89, 0x1c, 0x00, 0xa0, 0x24, 0xab, 0x2d, 0xbb);
	public const Guid CLSID_DsFindObjects = .(0x83ee3fe1, 0x57d9, 0x11d0, 0xb9, 0x32, 0x00, 0xa0, 0x24, 0xab, 0x2d, 0xbb);
	public const Guid CLSID_DsFindPeople = .(0x83ee3fe2, 0x57d9, 0x11d0, 0xb9, 0x32, 0x00, 0xa0, 0x24, 0xab, 0x2d, 0xbb);
	public const Guid CLSID_DsFindPrinter = .(0xb577f070, 0x7ee2, 0x11d0, 0x91, 0x3f, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const Guid CLSID_DsFindComputer = .(0x16006700, 0x87ad, 0x11d0, 0x91, 0x40, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const Guid CLSID_DsFindVolume = .(0xc1b3cbf1, 0x886a, 0x11d0, 0x91, 0x40, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const Guid CLSID_DsFindContainer = .(0xc1b3cbf2, 0x886a, 0x11d0, 0x91, 0x40, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);
	public const Guid CLSID_DsFindAdvanced = .(0x83ee3fe3, 0x57d9, 0x11d0, 0xb9, 0x32, 0x00, 0xa0, 0x24, 0xab, 0x2d, 0xbb);
	public const Guid CLSID_DsFindDomainController = .(0x538c7b7e, 0xd25e, 0x11d0, 0x97, 0x42, 0x00, 0xa0, 0xc9, 0x06, 0xaf, 0x45);
	public const Guid CLSID_DsFindWriteableDomainController = .(0x7cbef079, 0xaa84, 0x444b, 0xbc, 0x70, 0x68, 0xe4, 0x12, 0x83, 0xea, 0xbc);
	public const Guid CLSID_DsFindFrsMembers = .(0x94ce4b18, 0xb3d3, 0x11d1, 0xb9, 0xb4, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0xb0);
	public const uint32 DSQPF_NOSAVE = 1;
	public const uint32 DSQPF_SAVELOCATION = 2;
	public const uint32 DSQPF_SHOWHIDDENOBJECTS = 4;
	public const uint32 DSQPF_ENABLEADMINFEATURES = 8;
	public const uint32 DSQPF_ENABLEADVANCEDFEATURES = 16;
	public const uint32 DSQPF_HASCREDENTIALS = 32;
	public const uint32 DSQPF_NOCHOOSECOLUMNS = 64;
	public const String CFSTR_DSQUERYPARAMS = "DsQueryParameters";
	public const String CFSTR_DSQUERYSCOPE = "DsQueryScope";
	public const uint32 DSQPM_GETCLASSLIST = 268435456;
	public const uint32 DSQPM_HELPTOPICS = 268435457;
	public const uint32 DSROLE_PRIMARY_DS_RUNNING = 1;
	public const uint32 DSROLE_PRIMARY_DS_MIXED_MODE = 2;
	public const uint32 DSROLE_UPGRADE_IN_PROGRESS = 4;
	public const uint32 DSROLE_PRIMARY_DS_READONLY = 8;
	public const uint32 DSROLE_PRIMARY_DOMAIN_GUID_PRESENT = 16777216;
	public const uint32 ADS_ATTR_CLEAR = 1;
	public const uint32 ADS_ATTR_UPDATE = 2;
	public const uint32 ADS_ATTR_APPEND = 3;
	public const uint32 ADS_ATTR_DELETE = 4;
	public const uint32 ADS_EXT_MINEXTDISPID = 1;
	public const uint32 ADS_EXT_MAXEXTDISPID = 16777215;
	public const uint32 ADS_EXT_INITCREDENTIALS = 1;
	public const uint32 ADS_EXT_INITIALIZE_COMPLETE = 2;
	public const uint32 DS_BEHAVIOR_WIN2000 = 0;
	public const uint32 DS_BEHAVIOR_WIN2003_WITH_MIXED_DOMAINS = 1;
	public const uint32 DS_BEHAVIOR_WIN2003 = 2;
	public const uint32 DS_BEHAVIOR_WIN2008 = 3;
	public const uint32 DS_BEHAVIOR_WIN2008R2 = 4;
	public const uint32 DS_BEHAVIOR_WIN2012 = 5;
	public const uint32 DS_BEHAVIOR_WIN2012R2 = 6;
	public const uint32 DS_BEHAVIOR_WIN2016 = 7;
	public const uint32 DS_BEHAVIOR_LONGHORN = 3;
	public const uint32 DS_BEHAVIOR_WIN7 = 4;
	public const uint32 DS_BEHAVIOR_WIN8 = 5;
	public const uint32 DS_BEHAVIOR_WINBLUE = 6;
	public const uint32 DS_BEHAVIOR_WINTHRESHOLD = 7;
	public const String DS_SYNCED_EVENT_NAME = "NTDSInitialSyncsCompleted";
	public const String DS_SYNCED_EVENT_NAME_W = "NTDSInitialSyncsCompleted";
	public const uint32 ACTRL_DS_OPEN = 0;
	public const uint32 ACTRL_DS_CREATE_CHILD = 1;
	public const uint32 ACTRL_DS_DELETE_CHILD = 2;
	public const uint32 ACTRL_DS_LIST = 4;
	public const uint32 ACTRL_DS_SELF = 8;
	public const uint32 ACTRL_DS_READ_PROP = 16;
	public const uint32 ACTRL_DS_WRITE_PROP = 32;
	public const uint32 ACTRL_DS_DELETE_TREE = 64;
	public const uint32 ACTRL_DS_LIST_OBJECT = 128;
	public const uint32 ACTRL_DS_CONTROL_ACCESS = 256;
	public const uint32 NTDSAPI_BIND_ALLOW_DELEGATION = 1;
	public const uint32 NTDSAPI_BIND_FIND_BINDING = 2;
	public const uint32 NTDSAPI_BIND_FORCE_KERBEROS = 4;
	public const uint32 DS_REPSYNC_ASYNCHRONOUS_OPERATION = 1;
	public const uint32 DS_REPSYNC_WRITEABLE = 2;
	public const uint32 DS_REPSYNC_PERIODIC = 4;
	public const uint32 DS_REPSYNC_INTERSITE_MESSAGING = 8;
	public const uint32 DS_REPSYNC_FULL = 32;
	public const uint32 DS_REPSYNC_URGENT = 64;
	public const uint32 DS_REPSYNC_NO_DISCARD = 128;
	public const uint32 DS_REPSYNC_FORCE = 256;
	public const uint32 DS_REPSYNC_ADD_REFERENCE = 512;
	public const uint32 DS_REPSYNC_NEVER_COMPLETED = 1024;
	public const uint32 DS_REPSYNC_TWO_WAY = 2048;
	public const uint32 DS_REPSYNC_NEVER_NOTIFY = 4096;
	public const uint32 DS_REPSYNC_INITIAL = 8192;
	public const uint32 DS_REPSYNC_USE_COMPRESSION = 16384;
	public const uint32 DS_REPSYNC_ABANDONED = 32768;
	public const uint32 DS_REPSYNC_SELECT_SECRETS = 32768;
	public const uint32 DS_REPSYNC_INITIAL_IN_PROGRESS = 65536;
	public const uint32 DS_REPSYNC_PARTIAL_ATTRIBUTE_SET = 131072;
	public const uint32 DS_REPSYNC_REQUEUE = 262144;
	public const uint32 DS_REPSYNC_NOTIFICATION = 524288;
	public const uint32 DS_REPSYNC_ASYNCHRONOUS_REPLICA = 1048576;
	public const uint32 DS_REPSYNC_CRITICAL = 2097152;
	public const uint32 DS_REPSYNC_FULL_IN_PROGRESS = 4194304;
	public const uint32 DS_REPSYNC_PREEMPTED = 8388608;
	public const uint32 DS_REPSYNC_NONGC_RO_REPLICA = 16777216;
	public const uint32 DS_REPADD_ASYNCHRONOUS_OPERATION = 1;
	public const uint32 DS_REPADD_WRITEABLE = 2;
	public const uint32 DS_REPADD_INITIAL = 4;
	public const uint32 DS_REPADD_PERIODIC = 8;
	public const uint32 DS_REPADD_INTERSITE_MESSAGING = 16;
	public const uint32 DS_REPADD_ASYNCHRONOUS_REPLICA = 32;
	public const uint32 DS_REPADD_DISABLE_NOTIFICATION = 64;
	public const uint32 DS_REPADD_DISABLE_PERIODIC = 128;
	public const uint32 DS_REPADD_USE_COMPRESSION = 256;
	public const uint32 DS_REPADD_NEVER_NOTIFY = 512;
	public const uint32 DS_REPADD_TWO_WAY = 1024;
	public const uint32 DS_REPADD_CRITICAL = 2048;
	public const uint32 DS_REPADD_SELECT_SECRETS = 4096;
	public const uint32 DS_REPADD_NONGC_RO_REPLICA = 16777216;
	public const uint32 DS_REPDEL_ASYNCHRONOUS_OPERATION = 1;
	public const uint32 DS_REPDEL_WRITEABLE = 2;
	public const uint32 DS_REPDEL_INTERSITE_MESSAGING = 4;
	public const uint32 DS_REPDEL_IGNORE_ERRORS = 8;
	public const uint32 DS_REPDEL_LOCAL_ONLY = 16;
	public const uint32 DS_REPDEL_NO_SOURCE = 32;
	public const uint32 DS_REPDEL_REF_OK = 64;
	public const uint32 DS_REPMOD_ASYNCHRONOUS_OPERATION = 1;
	public const uint32 DS_REPMOD_WRITEABLE = 2;
	public const uint32 DS_REPMOD_UPDATE_FLAGS = 1;
	public const uint32 DS_REPMOD_UPDATE_INSTANCE = 2;
	public const uint32 DS_REPMOD_UPDATE_ADDRESS = 2;
	public const uint32 DS_REPMOD_UPDATE_SCHEDULE = 4;
	public const uint32 DS_REPMOD_UPDATE_RESULT = 8;
	public const uint32 DS_REPMOD_UPDATE_TRANSPORT = 16;
	public const uint32 DS_REPUPD_ASYNCHRONOUS_OPERATION = 1;
	public const uint32 DS_REPUPD_WRITEABLE = 2;
	public const uint32 DS_REPUPD_ADD_REFERENCE = 4;
	public const uint32 DS_REPUPD_DELETE_REFERENCE = 8;
	public const uint32 DS_REPUPD_REFERENCE_GCSPN = 16;
	public const uint32 DS_INSTANCETYPE_IS_NC_HEAD = 1;
	public const uint32 DS_INSTANCETYPE_NC_IS_WRITEABLE = 4;
	public const uint32 DS_INSTANCETYPE_NC_COMING = 16;
	public const uint32 DS_INSTANCETYPE_NC_GOING = 32;
	public const uint32 NTDSDSA_OPT_IS_GC = 1;
	public const uint32 NTDSDSA_OPT_DISABLE_INBOUND_REPL = 2;
	public const uint32 NTDSDSA_OPT_DISABLE_OUTBOUND_REPL = 4;
	public const uint32 NTDSDSA_OPT_DISABLE_NTDSCONN_XLATE = 8;
	public const uint32 NTDSDSA_OPT_DISABLE_SPN_REGISTRATION = 16;
	public const uint32 NTDSDSA_OPT_GENERATE_OWN_TOPO = 32;
	public const uint32 NTDSDSA_OPT_BLOCK_RPC = 64;
	public const uint32 NTDSCONN_OPT_IS_GENERATED = 1;
	public const uint32 NTDSCONN_OPT_TWOWAY_SYNC = 2;
	public const uint32 NTDSCONN_OPT_OVERRIDE_NOTIFY_DEFAULT = 4;
	public const uint32 NTDSCONN_OPT_USE_NOTIFY = 8;
	public const uint32 NTDSCONN_OPT_DISABLE_INTERSITE_COMPRESSION = 16;
	public const uint32 NTDSCONN_OPT_USER_OWNED_SCHEDULE = 32;
	public const uint32 NTDSCONN_OPT_RODC_TOPOLOGY = 64;
	public const uint32 NTDSCONN_KCC_NO_REASON = 0;
	public const uint32 NTDSCONN_KCC_GC_TOPOLOGY = 1;
	public const uint32 NTDSCONN_KCC_RING_TOPOLOGY = 2;
	public const uint32 NTDSCONN_KCC_MINIMIZE_HOPS_TOPOLOGY = 4;
	public const uint32 NTDSCONN_KCC_STALE_SERVERS_TOPOLOGY = 8;
	public const uint32 NTDSCONN_KCC_OSCILLATING_CONNECTION_TOPOLOGY = 16;
	public const uint32 NTDSCONN_KCC_INTERSITE_GC_TOPOLOGY = 32;
	public const uint32 NTDSCONN_KCC_INTERSITE_TOPOLOGY = 64;
	public const uint32 NTDSCONN_KCC_SERVER_FAILOVER_TOPOLOGY = 128;
	public const uint32 NTDSCONN_KCC_SITE_FAILOVER_TOPOLOGY = 256;
	public const uint32 NTDSCONN_KCC_REDUNDANT_SERVER_TOPOLOGY = 512;
	public const uint32 FRSCONN_PRIORITY_MASK = 1879048192;
	public const uint32 FRSCONN_MAX_PRIORITY = 8;
	public const uint32 NTDSCONN_OPT_IGNORE_SCHEDULE_MASK = 2147483648;
	public const uint32 NTDSSETTINGS_OPT_IS_AUTO_TOPOLOGY_DISABLED = 1;
	public const uint32 NTDSSETTINGS_OPT_IS_TOPL_CLEANUP_DISABLED = 2;
	public const uint32 NTDSSETTINGS_OPT_IS_TOPL_MIN_HOPS_DISABLED = 4;
	public const uint32 NTDSSETTINGS_OPT_IS_TOPL_DETECT_STALE_DISABLED = 8;
	public const uint32 NTDSSETTINGS_OPT_IS_INTER_SITE_AUTO_TOPOLOGY_DISABLED = 16;
	public const uint32 NTDSSETTINGS_OPT_IS_GROUP_CACHING_ENABLED = 32;
	public const uint32 NTDSSETTINGS_OPT_FORCE_KCC_WHISTLER_BEHAVIOR = 64;
	public const uint32 NTDSSETTINGS_OPT_FORCE_KCC_W2K_ELECTION = 128;
	public const uint32 NTDSSETTINGS_OPT_IS_RAND_BH_SELECTION_DISABLED = 256;
	public const uint32 NTDSSETTINGS_OPT_IS_SCHEDULE_HASHING_ENABLED = 512;
	public const uint32 NTDSSETTINGS_OPT_IS_REDUNDANT_SERVER_TOPOLOGY_ENABLED = 1024;
	public const uint32 NTDSSETTINGS_OPT_W2K3_IGNORE_SCHEDULES = 2048;
	public const uint32 NTDSSETTINGS_OPT_W2K3_BRIDGES_REQUIRED = 4096;
	public const uint32 NTDSSETTINGS_DEFAULT_SERVER_REDUNDANCY = 2;
	public const uint32 NTDSTRANSPORT_OPT_IGNORE_SCHEDULES = 1;
	public const uint32 NTDSTRANSPORT_OPT_BRIDGES_REQUIRED = 2;
	public const uint32 NTDSSITECONN_OPT_USE_NOTIFY = 1;
	public const uint32 NTDSSITECONN_OPT_TWOWAY_SYNC = 2;
	public const uint32 NTDSSITECONN_OPT_DISABLE_COMPRESSION = 4;
	public const uint32 NTDSSITELINK_OPT_USE_NOTIFY = 1;
	public const uint32 NTDSSITELINK_OPT_TWOWAY_SYNC = 2;
	public const uint32 NTDSSITELINK_OPT_DISABLE_COMPRESSION = 4;
	public const String GUID_USERS_CONTAINER_A = "a9d1ca15768811d1aded00c04fd8d5cd";
	public const String GUID_COMPUTRS_CONTAINER_A = "aa312825768811d1aded00c04fd8d5cd";
	public const String GUID_SYSTEMS_CONTAINER_A = "ab1d30f3768811d1aded00c04fd8d5cd";
	public const String GUID_DOMAIN_CONTROLLERS_CONTAINER_A = "a361b2ffffd211d1aa4b00c04fd7d83a";
	public const String GUID_INFRASTRUCTURE_CONTAINER_A = "2fbac1870ade11d297c400c04fd8d5cd";
	public const String GUID_DELETED_OBJECTS_CONTAINER_A = "18e2ea80684f11d2b9aa00c04f79f805";
	public const String GUID_LOSTANDFOUND_CONTAINER_A = "ab8153b7768811d1aded00c04fd8d5cd";
	public const String GUID_FOREIGNSECURITYPRINCIPALS_CONTAINER_A = "22b70c67d56e4efb91e9300fca3dc1aa";
	public const String GUID_PROGRAM_DATA_CONTAINER_A = "09460c08ae1e4a4ea0f64aee7daa1e5a";
	public const String GUID_MICROSOFT_PROGRAM_DATA_CONTAINER_A = "f4be92a4c777485e878e9421d53087db";
	public const String GUID_NTDS_QUOTAS_CONTAINER_A = "6227f0af1fc2410d8e3bb10615bb5b0f";
	public const String GUID_USERS_CONTAINER_W = "a9d1ca15768811d1aded00c04fd8d5cd";
	public const String GUID_COMPUTRS_CONTAINER_W = "aa312825768811d1aded00c04fd8d5cd";
	public const String GUID_SYSTEMS_CONTAINER_W = "ab1d30f3768811d1aded00c04fd8d5cd";
	public const String GUID_DOMAIN_CONTROLLERS_CONTAINER_W = "a361b2ffffd211d1aa4b00c04fd7d83a";
	public const String GUID_INFRASTRUCTURE_CONTAINER_W = "2fbac1870ade11d297c400c04fd8d5cd";
	public const String GUID_DELETED_OBJECTS_CONTAINER_W = "18e2ea80684f11d2b9aa00c04f79f805";
	public const String GUID_LOSTANDFOUND_CONTAINER_W = "ab8153b7768811d1aded00c04fd8d5cd";
	public const String GUID_FOREIGNSECURITYPRINCIPALS_CONTAINER_W = "22b70c67d56e4efb91e9300fca3dc1aa";
	public const String GUID_PROGRAM_DATA_CONTAINER_W = "09460c08ae1e4a4ea0f64aee7daa1e5a";
	public const String GUID_MICROSOFT_PROGRAM_DATA_CONTAINER_W = "f4be92a4c777485e878e9421d53087db";
	public const String GUID_NTDS_QUOTAS_CONTAINER_W = "6227f0af1fc2410d8e3bb10615bb5b0f";
	public const String GUID_MANAGED_SERVICE_ACCOUNTS_CONTAINER_W = "1EB93889E40C45DF9F0C64D23BBB6237";
	public const String GUID_KEYS_CONTAINER_W = "683A24E2E8164BD3AF86AC3C2CF3F981";
	public const uint32 DS_REPSYNCALL_NO_OPTIONS = 0;
	public const uint32 DS_REPSYNCALL_ABORT_IF_SERVER_UNAVAILABLE = 1;
	public const uint32 DS_REPSYNCALL_SYNC_ADJACENT_SERVERS_ONLY = 2;
	public const uint32 DS_REPSYNCALL_ID_SERVERS_BY_DN = 4;
	public const uint32 DS_REPSYNCALL_DO_NOT_SYNC = 8;
	public const uint32 DS_REPSYNCALL_SKIP_INITIAL_CHECK = 16;
	public const uint32 DS_REPSYNCALL_PUSH_CHANGES_OUTWARD = 32;
	public const uint32 DS_REPSYNCALL_CROSS_SITE_BOUNDARIES = 64;
	public const uint32 DS_LIST_DSA_OBJECT_FOR_SERVER = 0;
	public const uint32 DS_LIST_DNS_HOST_NAME_FOR_SERVER = 1;
	public const uint32 DS_LIST_ACCOUNT_OBJECT_FOR_SERVER = 2;
	public const uint32 DS_ROLE_SCHEMA_OWNER = 0;
	public const uint32 DS_ROLE_DOMAIN_OWNER = 1;
	public const uint32 DS_ROLE_PDC_OWNER = 2;
	public const uint32 DS_ROLE_RID_OWNER = 3;
	public const uint32 DS_ROLE_INFRASTRUCTURE_OWNER = 4;
	public const uint32 DS_SCHEMA_GUID_NOT_FOUND = 0;
	public const uint32 DS_SCHEMA_GUID_ATTR = 1;
	public const uint32 DS_SCHEMA_GUID_ATTR_SET = 2;
	public const uint32 DS_SCHEMA_GUID_CLASS = 3;
	public const uint32 DS_SCHEMA_GUID_CONTROL_RIGHT = 4;
	public const uint32 DS_KCC_FLAG_ASYNC_OP = 1;
	public const uint32 DS_KCC_FLAG_DAMPED = 2;
	public const uint32 DS_EXIST_ADVISORY_MODE = 1;
	public const uint32 DS_REPL_INFO_FLAG_IMPROVE_LINKED_ATTRS = 1;
	public const uint32 DS_REPL_NBR_WRITEABLE = 16;
	public const uint32 DS_REPL_NBR_SYNC_ON_STARTUP = 32;
	public const uint32 DS_REPL_NBR_DO_SCHEDULED_SYNCS = 64;
	public const uint32 DS_REPL_NBR_USE_ASYNC_INTERSITE_TRANSPORT = 128;
	public const uint32 DS_REPL_NBR_TWO_WAY_SYNC = 512;
	public const uint32 DS_REPL_NBR_NONGC_RO_REPLICA = 1024;
	public const uint32 DS_REPL_NBR_RETURN_OBJECT_PARENTS = 2048;
	public const uint32 DS_REPL_NBR_SELECT_SECRETS = 4096;
	public const uint32 DS_REPL_NBR_FULL_SYNC_IN_PROGRESS = 65536;
	public const uint32 DS_REPL_NBR_FULL_SYNC_NEXT_PACKET = 131072;
	public const uint32 DS_REPL_NBR_GCSPN = 1048576;
	public const uint32 DS_REPL_NBR_NEVER_SYNCED = 2097152;
	public const uint32 DS_REPL_NBR_PREEMPTED = 16777216;
	public const uint32 DS_REPL_NBR_IGNORE_CHANGE_NOTIFICATIONS = 67108864;
	public const uint32 DS_REPL_NBR_DISABLE_SCHEDULED_SYNC = 134217728;
	public const uint32 DS_REPL_NBR_COMPRESS_CHANGES = 268435456;
	public const uint32 DS_REPL_NBR_NO_CHANGE_NOTIFICATIONS = 536870912;
	public const uint32 DS_REPL_NBR_PARTIAL_ATTRIBUTE_SET = 1073741824;
	public const String ADAM_SCP_SITE_NAME_STRING = "site:";
	public const String ADAM_SCP_SITE_NAME_STRING_W = "site:";
	public const String ADAM_SCP_PARTITION_STRING = "partition:";
	public const String ADAM_SCP_PARTITION_STRING_W = "partition:";
	public const String ADAM_SCP_INSTANCE_NAME_STRING = "instance:";
	public const String ADAM_SCP_INSTANCE_NAME_STRING_W = "instance:";
	public const String ADAM_SCP_FSMO_STRING = "fsmo:";
	public const String ADAM_SCP_FSMO_STRING_W = "fsmo:";
	public const String ADAM_SCP_FSMO_NAMING_STRING = "naming";
	public const String ADAM_SCP_FSMO_NAMING_STRING_W = "naming";
	public const String ADAM_SCP_FSMO_SCHEMA_STRING = "schema";
	public const String ADAM_SCP_FSMO_SCHEMA_STRING_W = "schema";
	public const uint32 ADAM_REPL_AUTHENTICATION_MODE_NEGOTIATE_PASS_THROUGH = 0;
	public const uint32 ADAM_REPL_AUTHENTICATION_MODE_NEGOTIATE = 1;
	public const uint32 ADAM_REPL_AUTHENTICATION_MODE_MUTUAL_AUTH_REQUIRED = 2;
	public const uint32 FLAG_FOREST_OPTIONAL_FEATURE = 1;
	public const uint32 FLAG_DOMAIN_OPTIONAL_FEATURE = 2;
	public const uint32 FLAG_DISABLABLE_OPTIONAL_FEATURE = 4;
	public const uint32 FLAG_SERVER_OPTIONAL_FEATURE = 8;
	public const String GUID_RECYCLE_BIN_OPTIONAL_FEATURE_A = "d8dc6d76d0ac5e44f3b9a7f9b6744f2a";
	public const String GUID_RECYCLE_BIN_OPTIONAL_FEATURE_W = "d8dc6d76d0ac5e44f3b9a7f9b6744f2a";
	public const String GUID_PRIVILEGED_ACCESS_MANAGEMENT_OPTIONAL_FEATURE_A = "73e843ece8cc4046b4ab07ffe4ab5bcd";
	public const String GUID_PRIVILEGED_ACCESS_MANAGEMENT_OPTIONAL_FEATURE_W = "73e843ece8cc4046b4ab07ffe4ab5bcd";
	public const String CFSTR_DSOP_DS_SELECTION_LIST = "CFSTR_DSOP_DS_SELECTION_LIST";
	public const uint32 DSOP_SCOPE_TYPE_TARGET_COMPUTER = 1;
	public const uint32 DSOP_SCOPE_TYPE_UPLEVEL_JOINED_DOMAIN = 2;
	public const uint32 DSOP_SCOPE_TYPE_DOWNLEVEL_JOINED_DOMAIN = 4;
	public const uint32 DSOP_SCOPE_TYPE_ENTERPRISE_DOMAIN = 8;
	public const uint32 DSOP_SCOPE_TYPE_GLOBAL_CATALOG = 16;
	public const uint32 DSOP_SCOPE_TYPE_EXTERNAL_UPLEVEL_DOMAIN = 32;
	public const uint32 DSOP_SCOPE_TYPE_EXTERNAL_DOWNLEVEL_DOMAIN = 64;
	public const uint32 DSOP_SCOPE_TYPE_WORKGROUP = 128;
	public const uint32 DSOP_SCOPE_TYPE_USER_ENTERED_UPLEVEL_SCOPE = 256;
	public const uint32 DSOP_SCOPE_TYPE_USER_ENTERED_DOWNLEVEL_SCOPE = 512;
	public const uint32 DSOP_SCOPE_FLAG_STARTING_SCOPE = 1;
	public const uint32 DSOP_SCOPE_FLAG_WANT_PROVIDER_WINNT = 2;
	public const uint32 DSOP_SCOPE_FLAG_WANT_PROVIDER_LDAP = 4;
	public const uint32 DSOP_SCOPE_FLAG_WANT_PROVIDER_GC = 8;
	public const uint32 DSOP_SCOPE_FLAG_WANT_SID_PATH = 16;
	public const uint32 DSOP_SCOPE_FLAG_WANT_DOWNLEVEL_BUILTIN_PATH = 32;
	public const uint32 DSOP_SCOPE_FLAG_DEFAULT_FILTER_USERS = 64;
	public const uint32 DSOP_SCOPE_FLAG_DEFAULT_FILTER_GROUPS = 128;
	public const uint32 DSOP_SCOPE_FLAG_DEFAULT_FILTER_COMPUTERS = 256;
	public const uint32 DSOP_SCOPE_FLAG_DEFAULT_FILTER_CONTACTS = 512;
	public const uint32 DSOP_SCOPE_FLAG_DEFAULT_FILTER_SERVICE_ACCOUNTS = 1024;
	public const uint32 DSOP_SCOPE_FLAG_DEFAULT_FILTER_PASSWORDSETTINGS_OBJECTS = 2048;
	public const uint32 DSOP_FILTER_INCLUDE_ADVANCED_VIEW = 1;
	public const uint32 DSOP_FILTER_USERS = 2;
	public const uint32 DSOP_FILTER_BUILTIN_GROUPS = 4;
	public const uint32 DSOP_FILTER_WELL_KNOWN_PRINCIPALS = 8;
	public const uint32 DSOP_FILTER_UNIVERSAL_GROUPS_DL = 16;
	public const uint32 DSOP_FILTER_UNIVERSAL_GROUPS_SE = 32;
	public const uint32 DSOP_FILTER_GLOBAL_GROUPS_DL = 64;
	public const uint32 DSOP_FILTER_GLOBAL_GROUPS_SE = 128;
	public const uint32 DSOP_FILTER_DOMAIN_LOCAL_GROUPS_DL = 256;
	public const uint32 DSOP_FILTER_DOMAIN_LOCAL_GROUPS_SE = 512;
	public const uint32 DSOP_FILTER_CONTACTS = 1024;
	public const uint32 DSOP_FILTER_COMPUTERS = 2048;
	public const uint32 DSOP_FILTER_SERVICE_ACCOUNTS = 4096;
	public const uint32 DSOP_FILTER_PASSWORDSETTINGS_OBJECTS = 8192;
	public const uint32 DSOP_DOWNLEVEL_FILTER_USERS = 2147483649;
	public const uint32 DSOP_DOWNLEVEL_FILTER_LOCAL_GROUPS = 2147483650;
	public const uint32 DSOP_DOWNLEVEL_FILTER_GLOBAL_GROUPS = 2147483652;
	public const uint32 DSOP_DOWNLEVEL_FILTER_COMPUTERS = 2147483656;
	public const uint32 DSOP_DOWNLEVEL_FILTER_WORLD = 2147483664;
	public const uint32 DSOP_DOWNLEVEL_FILTER_AUTHENTICATED_USER = 2147483680;
	public const uint32 DSOP_DOWNLEVEL_FILTER_ANONYMOUS = 2147483712;
	public const uint32 DSOP_DOWNLEVEL_FILTER_BATCH = 2147483776;
	public const uint32 DSOP_DOWNLEVEL_FILTER_CREATOR_OWNER = 2147483904;
	public const uint32 DSOP_DOWNLEVEL_FILTER_CREATOR_GROUP = 2147484160;
	public const uint32 DSOP_DOWNLEVEL_FILTER_DIALUP = 2147484672;
	public const uint32 DSOP_DOWNLEVEL_FILTER_INTERACTIVE = 2147485696;
	public const uint32 DSOP_DOWNLEVEL_FILTER_NETWORK = 2147487744;
	public const uint32 DSOP_DOWNLEVEL_FILTER_SERVICE = 2147491840;
	public const uint32 DSOP_DOWNLEVEL_FILTER_SYSTEM = 2147500032;
	public const uint32 DSOP_DOWNLEVEL_FILTER_EXCLUDE_BUILTIN_GROUPS = 2147516416;
	public const uint32 DSOP_DOWNLEVEL_FILTER_TERMINAL_SERVER = 2147549184;
	public const uint32 DSOP_DOWNLEVEL_FILTER_ALL_WELLKNOWN_SIDS = 2147614720;
	public const uint32 DSOP_DOWNLEVEL_FILTER_LOCAL_SERVICE = 2147745792;
	public const uint32 DSOP_DOWNLEVEL_FILTER_NETWORK_SERVICE = 2148007936;
	public const uint32 DSOP_DOWNLEVEL_FILTER_REMOTE_LOGON = 2148532224;
	public const uint32 DSOP_DOWNLEVEL_FILTER_INTERNET_USER = 2149580800;
	public const uint32 DSOP_DOWNLEVEL_FILTER_OWNER_RIGHTS = 2151677952;
	public const uint32 DSOP_DOWNLEVEL_FILTER_SERVICES = 2155872256;
	public const uint32 DSOP_DOWNLEVEL_FILTER_LOCAL_LOGON = 2164260864;
	public const uint32 DSOP_DOWNLEVEL_FILTER_THIS_ORG_CERT = 2181038080;
	public const uint32 DSOP_DOWNLEVEL_FILTER_IIS_APP_POOL = 2214592512;
	public const uint32 DSOP_DOWNLEVEL_FILTER_ALL_APP_PACKAGES = 2281701376;
	public const uint32 DSOP_DOWNLEVEL_FILTER_LOCAL_ACCOUNTS = 2415919104;
	public const uint32 DSOP_FLAG_MULTISELECT = 1;
	public const uint32 DSOP_FLAG_SKIP_TARGET_COMPUTER_DC_CHECK = 2;
	public const uint32 SCHEDULE_INTERVAL = 0;
	public const uint32 SCHEDULE_BANDWIDTH = 1;
	public const uint32 SCHEDULE_PRIORITY = 2;
	public const uint32 FACILITY_NTDSB = 2048;
	public const uint32 FACILITY_BACKUP = 2047;
	public const uint32 FACILITY_SYSTEM = 0;
	public const uint32 STATUS_SEVERITY_SUCCESS = 0;
	public const uint32 STATUS_SEVERITY_INFORMATIONAL = 1;
	public const uint32 STATUS_SEVERITY_WARNING = 2;
	public const uint32 STATUS_SEVERITY_ERROR = 3;
	public const HRESULT hrNone = 0;
	public const HRESULT hrNyi = -1073741823;
	public const HRESULT hrInvalidParam = -939589631;
	public const HRESULT hrError = -939589630;
	public const HRESULT hrInvalidHandle = -939589629;
	public const HRESULT hrRestoreInProgress = -939589628;
	public const HRESULT hrAlreadyOpen = -939589627;
	public const HRESULT hrInvalidRecips = -939589626;
	public const HRESULT hrCouldNotConnect = -939589625;
	public const HRESULT hrRestoreMapExists = -939589624;
	public const HRESULT hrIncrementalBackupDisabled = -939589623;
	public const HRESULT hrLogFileNotFound = -939589622;
	public const HRESULT hrCircularLogging = -939589621;
	public const HRESULT hrNoFullRestore = -939589620;
	public const HRESULT hrCommunicationError = -939589619;
	public const HRESULT hrFullBackupNotTaken = -939589618;
	public const HRESULT hrMissingExpiryToken = -939589617;
	public const HRESULT hrUnknownExpiryTokenFormat = -939589616;
	public const HRESULT hrContentsExpired = -939589615;
	public const HRESULT hrFileClose = -939523994;
	public const HRESULT hrOutOfThreads = -939523993;
	public const HRESULT hrTooManyIO = -939523991;
	public const HRESULT hrBFNotSynchronous = -2013265720;
	public const HRESULT hrBFPageNotFound = -2013265719;
	public const HRESULT hrBFInUse = -939523894;
	public const HRESULT hrPMRecDeleted = -939523794;
	public const HRESULT hrRemainingVersions = -2013265599;
	public const HRESULT hrFLDKeyTooBig = -2013265520;
	public const HRESULT hrFLDTooManySegments = -939523695;
	public const HRESULT hrFLDNullKey = -2013265518;
	public const HRESULT hrLogFileCorrupt = -939523595;
	public const HRESULT hrNoBackupDirectory = -939523593;
	public const HRESULT hrBackupDirectoryNotEmpty = -939523592;
	public const HRESULT hrBackupInProgress = -939523591;
	public const HRESULT hrMissingPreviousLogFile = -939523587;
	public const HRESULT hrLogWriteFail = -939523586;
	public const HRESULT hrBadLogVersion = -939523582;
	public const HRESULT hrInvalidLogSequence = -939523581;
	public const HRESULT hrLoggingDisabled = -939523580;
	public const HRESULT hrLogBufferTooSmall = -939523579;
	public const HRESULT hrLogSequenceEnd = -939523577;
	public const HRESULT hrNoBackup = -939523576;
	public const HRESULT hrInvalidBackupSequence = -939523575;
	public const HRESULT hrBackupNotAllowedYet = -939523573;
	public const HRESULT hrDeleteBackupFileFail = -939523572;
	public const HRESULT hrMakeBackupDirectoryFail = -939523571;
	public const HRESULT hrInvalidBackup = -939523570;
	public const HRESULT hrRecoveredWithErrors = -939523569;
	public const HRESULT hrMissingLogFile = -939523568;
	public const HRESULT hrLogDiskFull = -939523567;
	public const HRESULT hrBadLogSignature = -939523566;
	public const HRESULT hrBadDbSignature = -939523565;
	public const HRESULT hrBadCheckpointSignature = -939523564;
	public const HRESULT hrCheckpointCorrupt = -939523563;
	public const HRESULT hrDatabaseInconsistent = -939523546;
	public const HRESULT hrConsistentTimeMismatch = -939523545;
	public const HRESULT hrPatchFileMismatch = -939523544;
	public const HRESULT hrRestoreLogTooLow = -939523543;
	public const HRESULT hrRestoreLogTooHigh = -939523542;
	public const HRESULT hrGivenLogFileHasBadSignature = -939523541;
	public const HRESULT hrGivenLogFileIsNotContiguous = -939523540;
	public const HRESULT hrMissingRestoreLogFiles = -939523539;
	public const HRESULT hrExistingLogFileHasBadSignature = -2013265362;
	public const HRESULT hrExistingLogFileIsNotContiguous = -2013265361;
	public const HRESULT hrMissingFullBackup = -939523536;
	public const HRESULT hrBadBackupDatabaseSize = -939523535;
	public const HRESULT hrTermInProgress = -939523096;
	public const HRESULT hrFeatureNotAvailable = -939523095;
	public const HRESULT hrInvalidName = -939523094;
	public const HRESULT hrInvalidParameter = -939523093;
	public const HRESULT hrColumnNull = -2013264916;
	public const HRESULT hrBufferTruncated = -2013264914;
	public const HRESULT hrDatabaseAttached = -2013264913;
	public const HRESULT hrInvalidDatabaseId = -939523086;
	public const HRESULT hrOutOfMemory = -939523085;
	public const HRESULT hrOutOfDatabaseSpace = -939523084;
	public const HRESULT hrOutOfCursors = -939523083;
	public const HRESULT hrOutOfBuffers = -939523082;
	public const HRESULT hrTooManyIndexes = -939523081;
	public const HRESULT hrTooManyKeys = -939523080;
	public const HRESULT hrRecordDeleted = -939523079;
	public const HRESULT hrReadVerifyFailure = -939523078;
	public const HRESULT hrOutOfFileHandles = -939523076;
	public const HRESULT hrDiskIO = -939523074;
	public const HRESULT hrInvalidPath = -939523073;
	public const HRESULT hrRecordTooBig = -939523070;
	public const HRESULT hrTooManyOpenDatabases = -939523069;
	public const HRESULT hrInvalidDatabase = -939523068;
	public const HRESULT hrNotInitialized = -939523067;
	public const HRESULT hrAlreadyInitialized = -939523066;
	public const HRESULT hrFileAccessDenied = -939523064;
	public const HRESULT hrBufferTooSmall = -939523058;
	public const HRESULT hrSeekNotEqual = -2013264881;
	public const HRESULT hrTooManyColumns = -939523056;
	public const HRESULT hrContainerNotEmpty = -939523053;
	public const HRESULT hrInvalidFilename = -939523052;
	public const HRESULT hrInvalidBookmark = -939523051;
	public const HRESULT hrColumnInUse = -939523050;
	public const HRESULT hrInvalidBufferSize = -939523049;
	public const HRESULT hrColumnNotUpdatable = -939523048;
	public const HRESULT hrIndexInUse = -939523045;
	public const HRESULT hrNullKeyDisallowed = -939523043;
	public const HRESULT hrNotInTransaction = -939523042;
	public const HRESULT hrNoIdleActivity = -2013264862;
	public const HRESULT hrTooManyActiveUsers = -939523037;
	public const HRESULT hrInvalidCountry = -939523035;
	public const HRESULT hrInvalidLanguageId = -939523034;
	public const HRESULT hrInvalidCodePage = -939523033;
	public const HRESULT hrNoWriteLock = -2013264853;
	public const HRESULT hrColumnSetNull = -2013264852;
	public const HRESULT hrVersionStoreOutOfMemory = -939523027;
	public const HRESULT hrCurrencyStackOutOfMemory = -939523026;
	public const HRESULT hrOutOfSessions = -939522995;
	public const HRESULT hrWriteConflict = -939522994;
	public const HRESULT hrTransTooDeep = -939522993;
	public const HRESULT hrInvalidSesid = -939522992;
	public const HRESULT hrSessionWriteConflict = -939522989;
	public const HRESULT hrInTransaction = -939522988;
	public const HRESULT hrDatabaseDuplicate = -939522895;
	public const HRESULT hrDatabaseInUse = -939522894;
	public const HRESULT hrDatabaseNotFound = -939522893;
	public const HRESULT hrDatabaseInvalidName = -939522892;
	public const HRESULT hrDatabaseInvalidPages = -939522891;
	public const HRESULT hrDatabaseCorrupted = -939522890;
	public const HRESULT hrDatabaseLocked = -939522889;
	public const HRESULT hrTableEmpty = -2013264619;
	public const HRESULT hrTableLocked = -939522794;
	public const HRESULT hrTableDuplicate = -939522793;
	public const HRESULT hrTableInUse = -939522792;
	public const HRESULT hrObjectNotFound = -939522791;
	public const HRESULT hrCannotRename = -939522790;
	public const HRESULT hrDensityInvalid = -939522789;
	public const HRESULT hrTableNotEmpty = -939522788;
	public const HRESULT hrInvalidTableId = -939522786;
	public const HRESULT hrTooManyOpenTables = -939522785;
	public const HRESULT hrIllegalOperation = -939522784;
	public const HRESULT hrObjectDuplicate = -939522782;
	public const HRESULT hrInvalidObject = -939522780;
	public const HRESULT hrIndexCantBuild = -939522695;
	public const HRESULT hrIndexHasPrimary = -939522694;
	public const HRESULT hrIndexDuplicate = -939522693;
	public const HRESULT hrIndexNotFound = -939522692;
	public const HRESULT hrIndexMustStay = -939522691;
	public const HRESULT hrIndexInvalidDef = -939522690;
	public const HRESULT hrIndexHasClustered = -939522688;
	public const HRESULT hrCreateIndexFailed = -2013264511;
	public const HRESULT hrTooManyOpenIndexes = -939522686;
	public const HRESULT hrColumnLong = -939522595;
	public const HRESULT hrColumnDoesNotFit = -939522593;
	public const HRESULT hrNullInvalid = -939522592;
	public const HRESULT hrColumnIndexed = -939522591;
	public const HRESULT hrColumnTooBig = -939522590;
	public const HRESULT hrColumnNotFound = -939522589;
	public const HRESULT hrColumnDuplicate = -939522588;
	public const HRESULT hrColumn2ndSysMaint = -939522586;
	public const HRESULT hrInvalidColumnType = -939522585;
	public const HRESULT hrColumnMaxTruncated = -2013264408;
	public const HRESULT hrColumnCannotIndex = -939522583;
	public const HRESULT hrTaggedNotNULL = -939522582;
	public const HRESULT hrNoCurrentIndex = -939522581;
	public const HRESULT hrKeyIsMade = -939522580;
	public const HRESULT hrBadColumnId = -939522579;
	public const HRESULT hrBadItagSequence = -939522578;
	public const HRESULT hrCannotBeTagged = -939522575;
	public const HRESULT hrRecordNotFound = -939522495;
	public const HRESULT hrNoCurrentRecord = -939522493;
	public const HRESULT hrRecordClusteredChanged = -939522492;
	public const HRESULT hrKeyDuplicate = -939522491;
	public const HRESULT hrAlreadyPrepared = -939522489;
	public const HRESULT hrKeyNotMade = -939522488;
	public const HRESULT hrUpdateNotPrepared = -939522487;
	public const HRESULT hrwrnDataHasChanged = -2013264310;
	public const HRESULT hrerrDataHasChanged = -939522485;
	public const HRESULT hrKeyChanged = -2013264302;
	public const HRESULT hrTooManySorts = -939522395;
	public const HRESULT hrInvalidOnSort = -939522394;
	public const HRESULT hrTempFileOpenError = -939522293;
	public const HRESULT hrTooManyAttachedDatabases = -939522291;
	public const HRESULT hrDiskFull = -939522288;
	public const HRESULT hrPermissionDenied = -939522287;
	public const HRESULT hrFileNotFound = -939522285;
	public const HRESULT hrFileOpenReadOnly = -2013264107;
	public const HRESULT hrAfterInitialization = -939522246;
	public const HRESULT hrLogCorrupted = -939522244;
	public const HRESULT hrInvalidOperation = -939522190;
	public const HRESULT hrAccessDenied = -939522189;
	public const Guid CLSID_DsObjectPicker = .(0x17d6ccd8, 0x3b7b, 0x11d2, 0xb9, 0xe0, 0x00, 0xc0, 0x4f, 0xd8, 0xdb, 0xf7);
}
#endregion

#region TypeDefs
typealias GetDcContextHandle = int;

typealias ADS_SEARCH_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum ADSTYPE : int32
{
	ADSTYPE_INVALID = 0,
	ADSTYPE_DN_STRING = 1,
	ADSTYPE_CASE_EXACT_STRING = 2,
	ADSTYPE_CASE_IGNORE_STRING = 3,
	ADSTYPE_PRINTABLE_STRING = 4,
	ADSTYPE_NUMERIC_STRING = 5,
	ADSTYPE_BOOLEAN = 6,
	ADSTYPE_INTEGER = 7,
	ADSTYPE_OCTET_STRING = 8,
	ADSTYPE_UTC_TIME = 9,
	ADSTYPE_LARGE_INTEGER = 10,
	ADSTYPE_PROV_SPECIFIC = 11,
	ADSTYPE_OBJECT_CLASS = 12,
	ADSTYPE_CASEIGNORE_LIST = 13,
	ADSTYPE_OCTET_LIST = 14,
	ADSTYPE_PATH = 15,
	ADSTYPE_POSTALADDRESS = 16,
	ADSTYPE_TIMESTAMP = 17,
	ADSTYPE_BACKLINK = 18,
	ADSTYPE_TYPEDNAME = 19,
	ADSTYPE_HOLD = 20,
	ADSTYPE_NETADDRESS = 21,
	ADSTYPE_REPLICAPOINTER = 22,
	ADSTYPE_FAXNUMBER = 23,
	ADSTYPE_EMAIL = 24,
	ADSTYPE_NT_SECURITY_DESCRIPTOR = 25,
	ADSTYPE_UNKNOWN = 26,
	ADSTYPE_DN_WITH_BINARY = 27,
	ADSTYPE_DN_WITH_STRING = 28,
}


[AllowDuplicates]
public enum ADS_AUTHENTICATION_ENUM : uint32
{
	ADS_SECURE_AUTHENTICATION = 1,
	ADS_USE_ENCRYPTION = 2,
	ADS_USE_SSL = 2,
	ADS_READONLY_SERVER = 4,
	ADS_PROMPT_CREDENTIALS = 8,
	ADS_NO_AUTHENTICATION = 16,
	ADS_FAST_BIND = 32,
	ADS_USE_SIGNING = 64,
	ADS_USE_SEALING = 128,
	ADS_USE_DELEGATION = 256,
	ADS_SERVER_BIND = 512,
	ADS_NO_REFERRAL_CHASING = 1024,
	ADS_AUTH_RESERVED = 2147483648,
}


[AllowDuplicates]
public enum ADS_STATUSENUM : int32
{
	ADS_STATUS_S_OK = 0,
	ADS_STATUS_INVALID_SEARCHPREF = 1,
	ADS_STATUS_INVALID_SEARCHPREFVALUE = 2,
}


[AllowDuplicates]
public enum ADS_DEREFENUM : int32
{
	ADS_DEREF_NEVER = 0,
	ADS_DEREF_SEARCHING = 1,
	ADS_DEREF_FINDING = 2,
	ADS_DEREF_ALWAYS = 3,
}


[AllowDuplicates]
public enum ADS_SCOPEENUM : int32
{
	ADS_SCOPE_BASE = 0,
	ADS_SCOPE_ONELEVEL = 1,
	ADS_SCOPE_SUBTREE = 2,
}


[AllowDuplicates]
public enum ADS_PREFERENCES_ENUM : int32
{
	ADSIPROP_ASYNCHRONOUS = 0,
	ADSIPROP_DEREF_ALIASES = 1,
	ADSIPROP_SIZE_LIMIT = 2,
	ADSIPROP_TIME_LIMIT = 3,
	ADSIPROP_ATTRIBTYPES_ONLY = 4,
	ADSIPROP_SEARCH_SCOPE = 5,
	ADSIPROP_TIMEOUT = 6,
	ADSIPROP_PAGESIZE = 7,
	ADSIPROP_PAGED_TIME_LIMIT = 8,
	ADSIPROP_CHASE_REFERRALS = 9,
	ADSIPROP_SORT_ON = 10,
	ADSIPROP_CACHE_RESULTS = 11,
	ADSIPROP_ADSIFLAG = 12,
}


[AllowDuplicates]
public enum ADSI_DIALECT_ENUM : int32
{
	ADSI_DIALECT_LDAP = 0,
	ADSI_DIALECT_SQL = 1,
}


[AllowDuplicates]
public enum ADS_CHASE_REFERRALS_ENUM : int32
{
	ADS_CHASE_REFERRALS_NEVER = 0,
	ADS_CHASE_REFERRALS_SUBORDINATE = 32,
	ADS_CHASE_REFERRALS_EXTERNAL = 64,
	ADS_CHASE_REFERRALS_ALWAYS = 96,
}


[AllowDuplicates]
public enum ADS_SEARCHPREF_ENUM : int32
{
	ADS_SEARCHPREF_ASYNCHRONOUS = 0,
	ADS_SEARCHPREF_DEREF_ALIASES = 1,
	ADS_SEARCHPREF_SIZE_LIMIT = 2,
	ADS_SEARCHPREF_TIME_LIMIT = 3,
	ADS_SEARCHPREF_ATTRIBTYPES_ONLY = 4,
	ADS_SEARCHPREF_SEARCH_SCOPE = 5,
	ADS_SEARCHPREF_TIMEOUT = 6,
	ADS_SEARCHPREF_PAGESIZE = 7,
	ADS_SEARCHPREF_PAGED_TIME_LIMIT = 8,
	ADS_SEARCHPREF_CHASE_REFERRALS = 9,
	ADS_SEARCHPREF_SORT_ON = 10,
	ADS_SEARCHPREF_CACHE_RESULTS = 11,
	ADS_SEARCHPREF_DIRSYNC = 12,
	ADS_SEARCHPREF_TOMBSTONE = 13,
	ADS_SEARCHPREF_VLV = 14,
	ADS_SEARCHPREF_ATTRIBUTE_QUERY = 15,
	ADS_SEARCHPREF_SECURITY_MASK = 16,
	ADS_SEARCHPREF_DIRSYNC_FLAG = 17,
	ADS_SEARCHPREF_EXTENDED_DN = 18,
}


[AllowDuplicates]
public enum ADS_PASSWORD_ENCODING_ENUM : int32
{
	ADS_PASSWORD_ENCODE_REQUIRE_SSL = 0,
	ADS_PASSWORD_ENCODE_CLEAR = 1,
}


[AllowDuplicates]
public enum ADS_PROPERTY_OPERATION_ENUM : int32
{
	ADS_PROPERTY_CLEAR = 1,
	ADS_PROPERTY_UPDATE = 2,
	ADS_PROPERTY_APPEND = 3,
	ADS_PROPERTY_DELETE = 4,
}


[AllowDuplicates]
public enum ADS_SYSTEMFLAG_ENUM : int32
{
	ADS_SYSTEMFLAG_DISALLOW_DELETE = -2147483648,
	ADS_SYSTEMFLAG_CONFIG_ALLOW_RENAME = 1073741824,
	ADS_SYSTEMFLAG_CONFIG_ALLOW_MOVE = 536870912,
	ADS_SYSTEMFLAG_CONFIG_ALLOW_LIMITED_MOVE = 268435456,
	ADS_SYSTEMFLAG_DOMAIN_DISALLOW_RENAME = 134217728,
	ADS_SYSTEMFLAG_DOMAIN_DISALLOW_MOVE = 67108864,
	ADS_SYSTEMFLAG_CR_NTDS_NC = 1,
	ADS_SYSTEMFLAG_CR_NTDS_DOMAIN = 2,
	ADS_SYSTEMFLAG_ATTR_NOT_REPLICATED = 1,
	ADS_SYSTEMFLAG_ATTR_IS_CONSTRUCTED = 4,
}


[AllowDuplicates]
public enum ADS_GROUP_TYPE_ENUM : int32
{
	ADS_GROUP_TYPE_GLOBAL_GROUP = 2,
	ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP = 4,
	ADS_GROUP_TYPE_LOCAL_GROUP = 4,
	ADS_GROUP_TYPE_UNIVERSAL_GROUP = 8,
	ADS_GROUP_TYPE_SECURITY_ENABLED = -2147483648,
}


[AllowDuplicates]
public enum ADS_USER_FLAG_ENUM : int32
{
	ADS_UF_SCRIPT = 1,
	ADS_UF_ACCOUNTDISABLE = 2,
	ADS_UF_HOMEDIR_REQUIRED = 8,
	ADS_UF_LOCKOUT = 16,
	ADS_UF_PASSWD_NOTREQD = 32,
	ADS_UF_PASSWD_CANT_CHANGE = 64,
	ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED = 128,
	ADS_UF_TEMP_DUPLICATE_ACCOUNT = 256,
	ADS_UF_NORMAL_ACCOUNT = 512,
	ADS_UF_INTERDOMAIN_TRUST_ACCOUNT = 2048,
	ADS_UF_WORKSTATION_TRUST_ACCOUNT = 4096,
	ADS_UF_SERVER_TRUST_ACCOUNT = 8192,
	ADS_UF_DONT_EXPIRE_PASSWD = 65536,
	ADS_UF_MNS_LOGON_ACCOUNT = 131072,
	ADS_UF_SMARTCARD_REQUIRED = 262144,
	ADS_UF_TRUSTED_FOR_DELEGATION = 524288,
	ADS_UF_NOT_DELEGATED = 1048576,
	ADS_UF_USE_DES_KEY_ONLY = 2097152,
	ADS_UF_DONT_REQUIRE_PREAUTH = 4194304,
	ADS_UF_PASSWORD_EXPIRED = 8388608,
	ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 16777216,
}


[AllowDuplicates]
public enum ADS_RIGHTS_ENUM : int32
{
	ADS_RIGHT_DELETE = 65536,
	ADS_RIGHT_READ_CONTROL = 131072,
	ADS_RIGHT_WRITE_DAC = 262144,
	ADS_RIGHT_WRITE_OWNER = 524288,
	ADS_RIGHT_SYNCHRONIZE = 1048576,
	ADS_RIGHT_ACCESS_SYSTEM_SECURITY = 16777216,
	ADS_RIGHT_GENERIC_READ = -2147483648,
	ADS_RIGHT_GENERIC_WRITE = 1073741824,
	ADS_RIGHT_GENERIC_EXECUTE = 536870912,
	ADS_RIGHT_GENERIC_ALL = 268435456,
	ADS_RIGHT_DS_CREATE_CHILD = 1,
	ADS_RIGHT_DS_DELETE_CHILD = 2,
	ADS_RIGHT_ACTRL_DS_LIST = 4,
	ADS_RIGHT_DS_SELF = 8,
	ADS_RIGHT_DS_READ_PROP = 16,
	ADS_RIGHT_DS_WRITE_PROP = 32,
	ADS_RIGHT_DS_DELETE_TREE = 64,
	ADS_RIGHT_DS_LIST_OBJECT = 128,
	ADS_RIGHT_DS_CONTROL_ACCESS = 256,
}


[AllowDuplicates]
public enum ADS_ACETYPE_ENUM : int32
{
	ADS_ACETYPE_ACCESS_ALLOWED = 0,
	ADS_ACETYPE_ACCESS_DENIED = 1,
	ADS_ACETYPE_SYSTEM_AUDIT = 2,
	ADS_ACETYPE_ACCESS_ALLOWED_OBJECT = 5,
	ADS_ACETYPE_ACCESS_DENIED_OBJECT = 6,
	ADS_ACETYPE_SYSTEM_AUDIT_OBJECT = 7,
	ADS_ACETYPE_SYSTEM_ALARM_OBJECT = 8,
	ADS_ACETYPE_ACCESS_ALLOWED_CALLBACK = 9,
	ADS_ACETYPE_ACCESS_DENIED_CALLBACK = 10,
	ADS_ACETYPE_ACCESS_ALLOWED_CALLBACK_OBJECT = 11,
	ADS_ACETYPE_ACCESS_DENIED_CALLBACK_OBJECT = 12,
	ADS_ACETYPE_SYSTEM_AUDIT_CALLBACK = 13,
	ADS_ACETYPE_SYSTEM_ALARM_CALLBACK = 14,
	ADS_ACETYPE_SYSTEM_AUDIT_CALLBACK_OBJECT = 15,
	ADS_ACETYPE_SYSTEM_ALARM_CALLBACK_OBJECT = 16,
}


[AllowDuplicates]
public enum ADS_ACEFLAG_ENUM : int32
{
	ADS_ACEFLAG_INHERIT_ACE = 2,
	ADS_ACEFLAG_NO_PROPAGATE_INHERIT_ACE = 4,
	ADS_ACEFLAG_INHERIT_ONLY_ACE = 8,
	ADS_ACEFLAG_INHERITED_ACE = 16,
	ADS_ACEFLAG_VALID_INHERIT_FLAGS = 31,
	ADS_ACEFLAG_SUCCESSFUL_ACCESS = 64,
	ADS_ACEFLAG_FAILED_ACCESS = 128,
}


[AllowDuplicates]
public enum ADS_FLAGTYPE_ENUM : int32
{
	ADS_FLAG_OBJECT_TYPE_PRESENT = 1,
	ADS_FLAG_INHERITED_OBJECT_TYPE_PRESENT = 2,
}


[AllowDuplicates]
public enum ADS_SD_CONTROL_ENUM : int32
{
	ADS_SD_CONTROL_SE_OWNER_DEFAULTED = 1,
	ADS_SD_CONTROL_SE_GROUP_DEFAULTED = 2,
	ADS_SD_CONTROL_SE_DACL_PRESENT = 4,
	ADS_SD_CONTROL_SE_DACL_DEFAULTED = 8,
	ADS_SD_CONTROL_SE_SACL_PRESENT = 16,
	ADS_SD_CONTROL_SE_SACL_DEFAULTED = 32,
	ADS_SD_CONTROL_SE_DACL_AUTO_INHERIT_REQ = 256,
	ADS_SD_CONTROL_SE_SACL_AUTO_INHERIT_REQ = 512,
	ADS_SD_CONTROL_SE_DACL_AUTO_INHERITED = 1024,
	ADS_SD_CONTROL_SE_SACL_AUTO_INHERITED = 2048,
	ADS_SD_CONTROL_SE_DACL_PROTECTED = 4096,
	ADS_SD_CONTROL_SE_SACL_PROTECTED = 8192,
	ADS_SD_CONTROL_SE_SELF_RELATIVE = 32768,
}


[AllowDuplicates]
public enum ADS_SD_REVISION_ENUM : int32
{
	ADS_SD_REVISION_DS = 4,
}


[AllowDuplicates]
public enum ADS_NAME_TYPE_ENUM : int32
{
	ADS_NAME_TYPE_1779 = 1,
	ADS_NAME_TYPE_CANONICAL = 2,
	ADS_NAME_TYPE_NT4 = 3,
	ADS_NAME_TYPE_DISPLAY = 4,
	ADS_NAME_TYPE_DOMAIN_SIMPLE = 5,
	ADS_NAME_TYPE_ENTERPRISE_SIMPLE = 6,
	ADS_NAME_TYPE_GUID = 7,
	ADS_NAME_TYPE_UNKNOWN = 8,
	ADS_NAME_TYPE_USER_PRINCIPAL_NAME = 9,
	ADS_NAME_TYPE_CANONICAL_EX = 10,
	ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME = 11,
	ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME = 12,
}


[AllowDuplicates]
public enum ADS_NAME_INITTYPE_ENUM : int32
{
	ADS_NAME_INITTYPE_DOMAIN = 1,
	ADS_NAME_INITTYPE_SERVER = 2,
	ADS_NAME_INITTYPE_GC = 3,
}


[AllowDuplicates]
public enum ADS_OPTION_ENUM : int32
{
	ADS_OPTION_SERVERNAME = 0,
	ADS_OPTION_REFERRALS = 1,
	ADS_OPTION_PAGE_SIZE = 2,
	ADS_OPTION_SECURITY_MASK = 3,
	ADS_OPTION_MUTUAL_AUTH_STATUS = 4,
	ADS_OPTION_QUOTA = 5,
	ADS_OPTION_PASSWORD_PORTNUMBER = 6,
	ADS_OPTION_PASSWORD_METHOD = 7,
	ADS_OPTION_ACCUMULATIVE_MODIFICATION = 8,
	ADS_OPTION_SKIP_SID_LOOKUP = 9,
}


[AllowDuplicates]
public enum ADS_SECURITY_INFO_ENUM : int32
{
	ADS_SECURITY_INFO_OWNER = 1,
	ADS_SECURITY_INFO_GROUP = 2,
	ADS_SECURITY_INFO_DACL = 4,
	ADS_SECURITY_INFO_SACL = 8,
}


[AllowDuplicates]
public enum ADS_SETTYPE_ENUM : int32
{
	ADS_SETTYPE_FULL = 1,
	ADS_SETTYPE_PROVIDER = 2,
	ADS_SETTYPE_SERVER = 3,
	ADS_SETTYPE_DN = 4,
}


[AllowDuplicates]
public enum ADS_FORMAT_ENUM : int32
{
	ADS_FORMAT_WINDOWS = 1,
	ADS_FORMAT_WINDOWS_NO_SERVER = 2,
	ADS_FORMAT_WINDOWS_DN = 3,
	ADS_FORMAT_WINDOWS_PARENT = 4,
	ADS_FORMAT_X500 = 5,
	ADS_FORMAT_X500_NO_SERVER = 6,
	ADS_FORMAT_X500_DN = 7,
	ADS_FORMAT_X500_PARENT = 8,
	ADS_FORMAT_SERVER = 9,
	ADS_FORMAT_PROVIDER = 10,
	ADS_FORMAT_LEAF = 11,
}


[AllowDuplicates]
public enum ADS_DISPLAY_ENUM : int32
{
	ADS_DISPLAY_FULL = 1,
	ADS_DISPLAY_VALUE_ONLY = 2,
}


[AllowDuplicates]
public enum ADS_ESCAPE_MODE_ENUM : int32
{
	ADS_ESCAPEDMODE_DEFAULT = 1,
	ADS_ESCAPEDMODE_ON = 2,
	ADS_ESCAPEDMODE_OFF = 3,
	ADS_ESCAPEDMODE_OFF_EX = 4,
}


[AllowDuplicates]
public enum ADS_PATHTYPE_ENUM : int32
{
	ADS_PATH_FILE = 1,
	ADS_PATH_FILESHARE = 2,
	ADS_PATH_REGISTRY = 3,
}


[AllowDuplicates]
public enum ADS_SD_FORMAT_ENUM : int32
{
	ADS_SD_FORMAT_IID = 1,
	ADS_SD_FORMAT_RAW = 2,
	ADS_SD_FORMAT_HEXSTRING = 3,
}


[AllowDuplicates]
public enum DS_MANGLE_FOR : int32
{
	DS_MANGLE_UNKNOWN = 0,
	DS_MANGLE_OBJECT_RDN_FOR_DELETION = 1,
	DS_MANGLE_OBJECT_RDN_FOR_NAME_CONFLICT = 2,
}


[AllowDuplicates]
public enum DS_NAME_FORMAT : int32
{
	DS_UNKNOWN_NAME = 0,
	DS_FQDN_1779_NAME = 1,
	DS_NT4_ACCOUNT_NAME = 2,
	DS_DISPLAY_NAME = 3,
	DS_UNIQUE_ID_NAME = 6,
	DS_CANONICAL_NAME = 7,
	DS_USER_PRINCIPAL_NAME = 8,
	DS_CANONICAL_NAME_EX = 9,
	DS_SERVICE_PRINCIPAL_NAME = 10,
	DS_SID_OR_SID_HISTORY_NAME = 11,
	DS_DNS_DOMAIN_NAME = 12,
}


[AllowDuplicates]
public enum DS_NAME_FLAGS : int32
{
	DS_NAME_NO_FLAGS = 0,
	DS_NAME_FLAG_SYNTACTICAL_ONLY = 1,
	DS_NAME_FLAG_EVAL_AT_DC = 2,
	DS_NAME_FLAG_GCVERIFY = 4,
	DS_NAME_FLAG_TRUST_REFERRAL = 8,
}


[AllowDuplicates]
public enum DS_NAME_ERROR : int32
{
	DS_NAME_NO_ERROR = 0,
	DS_NAME_ERROR_RESOLVING = 1,
	DS_NAME_ERROR_NOT_FOUND = 2,
	DS_NAME_ERROR_NOT_UNIQUE = 3,
	DS_NAME_ERROR_NO_MAPPING = 4,
	DS_NAME_ERROR_DOMAIN_ONLY = 5,
	DS_NAME_ERROR_NO_SYNTACTICAL_MAPPING = 6,
	DS_NAME_ERROR_TRUST_REFERRAL = 7,
}


[AllowDuplicates]
public enum DS_SPN_NAME_TYPE : int32
{
	DS_SPN_DNS_HOST = 0,
	DS_SPN_DN_HOST = 1,
	DS_SPN_NB_HOST = 2,
	DS_SPN_DOMAIN = 3,
	DS_SPN_NB_DOMAIN = 4,
	DS_SPN_SERVICE = 5,
}


[AllowDuplicates]
public enum DS_SPN_WRITE_OP : int32
{
	DS_SPN_ADD_SPN_OP = 0,
	DS_SPN_REPLACE_SPN_OP = 1,
	DS_SPN_DELETE_SPN_OP = 2,
}


[AllowDuplicates]
public enum DS_REPSYNCALL_ERROR : int32
{
	DS_REPSYNCALL_WIN32_ERROR_CONTACTING_SERVER = 0,
	DS_REPSYNCALL_WIN32_ERROR_REPLICATING = 1,
	DS_REPSYNCALL_SERVER_UNREACHABLE = 2,
}


[AllowDuplicates]
public enum DS_REPSYNCALL_EVENT : int32
{
	DS_REPSYNCALL_EVENT_ERROR = 0,
	DS_REPSYNCALL_EVENT_SYNC_STARTED = 1,
	DS_REPSYNCALL_EVENT_SYNC_COMPLETED = 2,
	DS_REPSYNCALL_EVENT_FINISHED = 3,
}


[AllowDuplicates]
public enum DS_KCC_TASKID : int32
{
	DS_KCC_TASKID_UPDATE_TOPOLOGY = 0,
}


[AllowDuplicates]
public enum DS_REPL_INFO_TYPE : int32
{
	DS_REPL_INFO_NEIGHBORS = 0,
	DS_REPL_INFO_CURSORS_FOR_NC = 1,
	DS_REPL_INFO_METADATA_FOR_OBJ = 2,
	DS_REPL_INFO_KCC_DSA_CONNECT_FAILURES = 3,
	DS_REPL_INFO_KCC_DSA_LINK_FAILURES = 4,
	DS_REPL_INFO_PENDING_OPS = 5,
	DS_REPL_INFO_METADATA_FOR_ATTR_VALUE = 6,
	DS_REPL_INFO_CURSORS_2_FOR_NC = 7,
	DS_REPL_INFO_CURSORS_3_FOR_NC = 8,
	DS_REPL_INFO_METADATA_2_FOR_OBJ = 9,
	DS_REPL_INFO_METADATA_2_FOR_ATTR_VALUE = 10,
	DS_REPL_INFO_METADATA_EXT_FOR_ATTR_VALUE = 11,
	DS_REPL_INFO_TYPE_MAX = 12,
}


[AllowDuplicates]
public enum DS_REPL_OP_TYPE : int32
{
	DS_REPL_OP_TYPE_SYNC = 0,
	DS_REPL_OP_TYPE_ADD = 1,
	DS_REPL_OP_TYPE_DELETE = 2,
	DS_REPL_OP_TYPE_MODIFY = 3,
	DS_REPL_OP_TYPE_UPDATE_REFS = 4,
}


[AllowDuplicates]
public enum DSROLE_MACHINE_ROLE : int32
{
	DsRole_RoleStandaloneWorkstation = 0,
	DsRole_RoleMemberWorkstation = 1,
	DsRole_RoleStandaloneServer = 2,
	DsRole_RoleMemberServer = 3,
	DsRole_RoleBackupDomainController = 4,
	DsRole_RolePrimaryDomainController = 5,
}


[AllowDuplicates]
public enum DSROLE_SERVER_STATE : int32
{
	DsRoleServerUnknown = 0,
	DsRoleServerPrimary = 1,
	DsRoleServerBackup = 2,
}


[AllowDuplicates]
public enum DSROLE_PRIMARY_DOMAIN_INFO_LEVEL : int32
{
	DsRolePrimaryDomainInfoBasic = 1,
	DsRoleUpgradeStatus = 2,
	DsRoleOperationState = 3,
}


[AllowDuplicates]
public enum DSROLE_OPERATION_STATE : int32
{
	DsRoleOperationIdle = 0,
	DsRoleOperationActive = 1,
	DsRoleOperationNeedReboot = 2,
}

#endregion

#region Function Pointers
public function HRESULT LPCQADDFORMSPROC(LPARAM lParam, CQFORM* pForm);

public function HRESULT LPCQADDPAGESPROC(LPARAM lParam, in Guid clsidForm, CQPAGE* pPage);

public function HRESULT LPCQPAGEPROC(CQPAGE* pPage, HWND hwnd, uint32 uMsg, WPARAM wParam, LPARAM lParam);

public function HRESULT LPDSENUMATTRIBUTES(LPARAM lParam, PWSTR pszAttributeName, PWSTR pszDisplayName, uint32 dwFlags);

#endregion

#region Structs
[CRepr]
public struct CQFORM
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public Guid clsid;
	public HICON hIcon;
	public PWSTR pszTitle;
}

[CRepr]
public struct CQPAGE
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public LPCQPAGEPROC pPageProc;
	public HINSTANCE hInstance;
	public int32 idPageName;
	public int32 idPageTemplate;
	public DLGPROC pDlgProc;
	public LPARAM lParam;
}

[CRepr]
public struct OPENQUERYWINDOW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* pFormParameters;
		public IPropertyBag* ppbFormParameters;
	}
	public uint32 cbStruct;
	public uint32 dwFlags;
	public Guid clsidHandler;
	public void* pHandlerParameters;
	public Guid clsidDefaultForm;
	public IPersistQuery* pPersistQuery;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct ADS_OCTET_STRING
{
	public uint32 dwLength;
	public uint8* lpValue;
}

[CRepr]
public struct ADS_NT_SECURITY_DESCRIPTOR
{
	public uint32 dwLength;
	public uint8* lpValue;
}

[CRepr]
public struct ADS_PROV_SPECIFIC
{
	public uint32 dwLength;
	public uint8* lpValue;
}

[CRepr]
public struct ADS_CASEIGNORE_LIST
{
	public ADS_CASEIGNORE_LIST* Next;
	public PWSTR String;
}

[CRepr]
public struct ADS_OCTET_LIST
{
	public ADS_OCTET_LIST* Next;
	public uint32 Length;
	public uint8* Data;
}

[CRepr]
public struct ADS_PATH
{
	public uint32 Type;
	public PWSTR VolumeName;
	public PWSTR Path;
}

[CRepr]
public struct ADS_POSTALADDRESS
{
	public PWSTR[6] PostalAddress;
}

[CRepr]
public struct ADS_TIMESTAMP
{
	public uint32 WholeSeconds;
	public uint32 EventID;
}

[CRepr]
public struct ADS_BACKLINK
{
	public uint32 RemoteID;
	public PWSTR ObjectName;
}

[CRepr]
public struct ADS_TYPEDNAME
{
	public PWSTR ObjectName;
	public uint32 Level;
	public uint32 Interval;
}

[CRepr]
public struct ADS_HOLD
{
	public PWSTR ObjectName;
	public uint32 Amount;
}

[CRepr]
public struct ADS_NETADDRESS
{
	public uint32 AddressType;
	public uint32 AddressLength;
	public uint8* Address;
}

[CRepr]
public struct ADS_REPLICAPOINTER
{
	public PWSTR ServerName;
	public uint32 ReplicaType;
	public uint32 ReplicaNumber;
	public uint32 Count;
	public ADS_NETADDRESS* ReplicaAddressHints;
}

[CRepr]
public struct ADS_FAXNUMBER
{
	public PWSTR TelephoneNumber;
	public uint32 NumberOfBits;
	public uint8* Parameters;
}

[CRepr]
public struct ADS_EMAIL
{
	public PWSTR Address;
	public uint32 Type;
}

[CRepr]
public struct ADS_DN_WITH_BINARY
{
	public uint32 dwLength;
	public uint8* lpBinaryValue;
	public PWSTR pszDNString;
}

[CRepr]
public struct ADS_DN_WITH_STRING
{
	public PWSTR pszStringValue;
	public PWSTR pszDNString;
}

[CRepr]
public struct ADSVALUE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16* DNString;
		public uint16* CaseExactString;
		public uint16* CaseIgnoreString;
		public uint16* PrintableString;
		public uint16* NumericString;
		public uint32 Boolean;
		public uint32 Integer;
		public ADS_OCTET_STRING OctetString;
		public SYSTEMTIME UTCTime;
		public LARGE_INTEGER LargeInteger;
		public uint16* ClassName;
		public ADS_PROV_SPECIFIC ProviderSpecific;
		public ADS_CASEIGNORE_LIST* pCaseIgnoreList;
		public ADS_OCTET_LIST* pOctetList;
		public ADS_PATH* pPath;
		public ADS_POSTALADDRESS* pPostalAddress;
		public ADS_TIMESTAMP Timestamp;
		public ADS_BACKLINK BackLink;
		public ADS_TYPEDNAME* pTypedName;
		public ADS_HOLD Hold;
		public ADS_NETADDRESS* pNetAddress;
		public ADS_REPLICAPOINTER* pReplicaPointer;
		public ADS_FAXNUMBER* pFaxNumber;
		public ADS_EMAIL Email;
		public ADS_NT_SECURITY_DESCRIPTOR SecurityDescriptor;
		public ADS_DN_WITH_BINARY* pDNWithBinary;
		public ADS_DN_WITH_STRING* pDNWithString;
	}
	public ADSTYPE dwType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct ADS_ATTR_INFO
{
	public PWSTR pszAttrName;
	public uint32 dwControlCode;
	public ADSTYPE dwADsType;
	public ADSVALUE* pADsValues;
	public uint32 dwNumValues;
}

[CRepr]
public struct ADS_OBJECT_INFO
{
	public PWSTR pszRDN;
	public PWSTR pszObjectDN;
	public PWSTR pszParentDN;
	public PWSTR pszSchemaDN;
	public PWSTR pszClassName;
}

[CRepr]
public struct ADS_SEARCHPREF_INFO
{
	public ADS_SEARCHPREF_ENUM dwSearchPref;
	public ADSVALUE vValue;
	public ADS_STATUSENUM dwStatus;
}

[CRepr]
public struct ADS_SEARCH_COLUMN
{
	public PWSTR pszAttrName;
	public ADSTYPE dwADsType;
	public ADSVALUE* pADsValues;
	public uint32 dwNumValues;
	public HANDLE hReserved;
}

[CRepr]
public struct ADS_ATTR_DEF
{
	public PWSTR pszAttrName;
	public ADSTYPE dwADsType;
	public uint32 dwMinRange;
	public uint32 dwMaxRange;
	public BOOL fMultiValued;
}

[CRepr]
public struct ADS_CLASS_DEF
{
	public PWSTR pszClassName;
	public uint32 dwMandatoryAttrs;
	public PWSTR* ppszMandatoryAttrs;
	public uint32 optionalAttrs;
	public PWSTR** ppszOptionalAttrs;
	public uint32 dwNamingAttrs;
	public PWSTR** ppszNamingAttrs;
	public uint32 dwSuperClasses;
	public PWSTR** ppszSuperClasses;
	public BOOL fIsContainer;
}

[CRepr]
public struct ADS_SORTKEY
{
	public PWSTR pszAttrType;
	public PWSTR pszReserved;
	public BOOLEAN fReverseorder;
}

[CRepr]
public struct ADS_VLV
{
	public uint32 dwBeforeCount;
	public uint32 dwAfterCount;
	public uint32 dwOffset;
	public uint32 dwContentCount;
	public PWSTR pszTarget;
	public uint32 dwContextIDLength;
	public uint8* lpContextID;
}

[CRepr]
public struct DSOBJECT
{
	public uint32 dwFlags;
	public uint32 dwProviderFlags;
	public uint32 offsetName;
	public uint32 offsetClass;
}

[CRepr]
public struct DSOBJECTNAMES
{
	public Guid clsidNamespace;
	public uint32 cItems;
	public DSOBJECT* aObjects mut => &aObjects_impl;
	private DSOBJECT[ANYSIZE_ARRAY] aObjects_impl;
}

[CRepr]
public struct DSDISPLAYSPECOPTIONS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 offsetAttribPrefix;
	public uint32 offsetUserName;
	public uint32 offsetPassword;
	public uint32 offsetServer;
	public uint32 offsetServerConfigPath;
}

[CRepr]
public struct DSPROPERTYPAGEINFO
{
	public uint32 offsetString;
}

[CRepr]
public struct DOMAINDESC
{
	public PWSTR pszName;
	public PWSTR pszPath;
	public PWSTR pszNCName;
	public PWSTR pszTrustParent;
	public PWSTR pszObjectClass;
	public uint32 ulFlags;
	public BOOL fDownLevel;
	public DOMAINDESC* pdChildList;
	public DOMAINDESC* pdNextSibling;
}

[CRepr]
public struct DOMAIN_TREE
{
	public uint32 dsSize;
	public uint32 dwCount;
	public DOMAINDESC* aDomains mut => &aDomains_impl;
	private DOMAINDESC[ANYSIZE_ARRAY] aDomains_impl;
}

[CRepr]
public struct DSCLASSCREATIONINFO
{
	public uint32 dwFlags;
	public Guid clsidWizardDialog;
	public Guid clsidWizardPrimaryPage;
	public uint32 cWizardExtensions;
	public Guid* aWizardExtensions mut => &aWizardExtensions_impl;
	private Guid[ANYSIZE_ARRAY] aWizardExtensions_impl;
}

[CRepr]
public struct DSBROWSEINFOW
{
	public uint32 cbStruct;
	public HWND hwndOwner;
	public PWSTR pszCaption;
	public PWSTR pszTitle;
	public PWSTR pszRoot;
	public PWSTR pszPath;
	public uint32 cchPath;
	public uint32 dwFlags;
	public BFFCALLBACK pfnCallback;
	public LPARAM lParam;
	public uint32 dwReturnFormat;
	public PWSTR pUserName;
	public PWSTR pPassword;
	public PWSTR pszObjectClass;
	public uint32 cchObjectClass;
}

[CRepr]
public struct DSBROWSEINFOA
{
	public uint32 cbStruct;
	public HWND hwndOwner;
	public PSTR pszCaption;
	public PSTR pszTitle;
	public PWSTR pszRoot;
	public PWSTR pszPath;
	public uint32 cchPath;
	public uint32 dwFlags;
	public BFFCALLBACK pfnCallback;
	public LPARAM lParam;
	public uint32 dwReturnFormat;
	public PWSTR pUserName;
	public PWSTR pPassword;
	public PWSTR pszObjectClass;
	public uint32 cchObjectClass;
}

[CRepr]
public struct DSBITEMW
{
	public uint32 cbStruct;
	public PWSTR pszADsPath;
	public PWSTR pszClass;
	public uint32 dwMask;
	public uint32 dwState;
	public uint32 dwStateMask;
	public char16[64] szDisplayName;
	public char16[260] szIconLocation;
	public int32 iIconResID;
}

[CRepr]
public struct DSBITEMA
{
	public uint32 cbStruct;
	public PWSTR pszADsPath;
	public PWSTR pszClass;
	public uint32 dwMask;
	public uint32 dwState;
	public uint32 dwStateMask;
	public CHAR[64] szDisplayName;
	public CHAR[260] szIconLocation;
	public int32 iIconResID;
}

[CRepr]
public struct DSOP_UPLEVEL_FILTER_FLAGS
{
	public uint32 flBothModes;
	public uint32 flMixedModeOnly;
	public uint32 flNativeModeOnly;
}

[CRepr]
public struct DSOP_FILTER_FLAGS
{
	public DSOP_UPLEVEL_FILTER_FLAGS Uplevel;
	public uint32 flDownlevel;
}

[CRepr]
public struct DSOP_SCOPE_INIT_INFO
{
	public uint32 cbSize;
	public uint32 flType;
	public uint32 flScope;
	public DSOP_FILTER_FLAGS FilterFlags;
	public PWSTR pwzDcName;
	public PWSTR pwzADsPath;
	public HRESULT hr;
}

[CRepr]
public struct DSOP_INIT_INFO
{
	public uint32 cbSize;
	public PWSTR pwzTargetComputer;
	public uint32 cDsScopeInfos;
	public DSOP_SCOPE_INIT_INFO* aDsScopeInfos;
	public uint32 flOptions;
	public uint32 cAttributesToFetch;
	public PWSTR* apwzAttributeNames;
}

[CRepr]
public struct DS_SELECTION
{
	public PWSTR pwzName;
	public PWSTR pwzADsPath;
	public PWSTR pwzClass;
	public PWSTR pwzUPN;
	public VARIANT* pvarFetchedAttributes;
	public uint32 flScopeType;
}

[CRepr]
public struct DS_SELECTION_LIST
{
	public uint32 cItems;
	public uint32 cFetchedAttributes;
	public DS_SELECTION* aDsSelection mut => &aDsSelection_impl;
	private DS_SELECTION[ANYSIZE_ARRAY] aDsSelection_impl;
}

[CRepr]
public struct DSQUERYINITPARAMS
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public PWSTR pDefaultScope;
	public PWSTR pDefaultSaveLocation;
	public PWSTR pUserName;
	public PWSTR pPassword;
	public PWSTR pServer;
}

[CRepr]
public struct DSCOLUMN
{
	public uint32 dwFlags;
	public int32 fmt;
	public int32 cx;
	public int32 idsName;
	public int32 offsetProperty;
	public uint32 dwReserved;
}

[CRepr]
public struct DSQUERYPARAMS
{
	public uint32 cbStruct;
	public uint32 dwFlags;
	public HINSTANCE hInstance;
	public int32 offsetQuery;
	public int32 iColumns;
	public uint32 dwReserved;
	public DSCOLUMN* aColumns mut => &aColumns_impl;
	private DSCOLUMN[ANYSIZE_ARRAY] aColumns_impl;
}

[CRepr]
public struct DSQUERYCLASSLIST
{
	public uint32 cbStruct;
	public int32 cClasses;
	public uint32* offsetClass mut => &offsetClass_impl;
	private uint32[ANYSIZE_ARRAY] offsetClass_impl;
}

[CRepr]
public struct DSA_NEWOBJ_DISPINFO
{
	public uint32 dwSize;
	public HICON hObjClassIcon;
	public PWSTR lpszWizTitle;
	public PWSTR lpszContDisplayName;
}

[CRepr]
public struct ADSPROPINITPARAMS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public HRESULT hr;
	public IDirectoryObject* pDsObj;
	public PWSTR pwzCN;
	public ADS_ATTR_INFO* pWritableAttrs;
}

[CRepr]
public struct ADSPROPERROR
{
	public HWND hwndPage;
	public PWSTR pszPageTitle;
	public PWSTR pszObjPath;
	public PWSTR pszObjClass;
	public HRESULT hr;
	public PWSTR pszError;
}

[CRepr]
public struct SCHEDULE_HEADER
{
	public uint32 Type;
	public uint32 Offset;
}

[CRepr]
public struct SCHEDULE
{
	public uint32 Size;
	public uint32 Bandwidth;
	public uint32 NumberOfSchedules;
	public SCHEDULE_HEADER* Schedules mut => &Schedules_impl;
	private SCHEDULE_HEADER[ANYSIZE_ARRAY] Schedules_impl;
}

[CRepr]
public struct DS_NAME_RESULT_ITEMA
{
	public uint32 status;
	public PSTR pDomain;
	public PSTR pName;
}

[CRepr]
public struct DS_NAME_RESULTA
{
	public uint32 cItems;
	public DS_NAME_RESULT_ITEMA* rItems;
}

[CRepr]
public struct DS_NAME_RESULT_ITEMW
{
	public uint32 status;
	public PWSTR pDomain;
	public PWSTR pName;
}

[CRepr]
public struct DS_NAME_RESULTW
{
	public uint32 cItems;
	public DS_NAME_RESULT_ITEMW* rItems;
}

[CRepr]
public struct DS_REPSYNCALL_SYNCA
{
	public PSTR pszSrcId;
	public PSTR pszDstId;
	public PSTR pszNC;
	public Guid* pguidSrc;
	public Guid* pguidDst;
}

[CRepr]
public struct DS_REPSYNCALL_SYNCW
{
	public PWSTR pszSrcId;
	public PWSTR pszDstId;
	public PWSTR pszNC;
	public Guid* pguidSrc;
	public Guid* pguidDst;
}

[CRepr]
public struct DS_REPSYNCALL_ERRINFOA
{
	public PSTR pszSvrId;
	public DS_REPSYNCALL_ERROR error;
	public uint32 dwWin32Err;
	public PSTR pszSrcId;
}

[CRepr]
public struct DS_REPSYNCALL_ERRINFOW
{
	public PWSTR pszSvrId;
	public DS_REPSYNCALL_ERROR error;
	public uint32 dwWin32Err;
	public PWSTR pszSrcId;
}

[CRepr]
public struct DS_REPSYNCALL_UPDATEA
{
	public DS_REPSYNCALL_EVENT event;
	public DS_REPSYNCALL_ERRINFOA* pErrInfo;
	public DS_REPSYNCALL_SYNCA* pSync;
}

[CRepr]
public struct DS_REPSYNCALL_UPDATEW
{
	public DS_REPSYNCALL_EVENT event;
	public DS_REPSYNCALL_ERRINFOW* pErrInfo;
	public DS_REPSYNCALL_SYNCW* pSync;
}

[CRepr]
public struct DS_SITE_COST_INFO
{
	public uint32 errorCode;
	public uint32 cost;
}

[CRepr]
public struct DS_SCHEMA_GUID_MAPA
{
	public Guid guid;
	public uint32 guidType;
	public PSTR pName;
}

[CRepr]
public struct DS_SCHEMA_GUID_MAPW
{
	public Guid guid;
	public uint32 guidType;
	public PWSTR pName;
}

[CRepr]
public struct DS_DOMAIN_CONTROLLER_INFO_1A
{
	public PSTR NetbiosName;
	public PSTR DnsHostName;
	public PSTR SiteName;
	public PSTR ComputerObjectName;
	public PSTR ServerObjectName;
	public BOOL fIsPdc;
	public BOOL fDsEnabled;
}

[CRepr]
public struct DS_DOMAIN_CONTROLLER_INFO_1W
{
	public PWSTR NetbiosName;
	public PWSTR DnsHostName;
	public PWSTR SiteName;
	public PWSTR ComputerObjectName;
	public PWSTR ServerObjectName;
	public BOOL fIsPdc;
	public BOOL fDsEnabled;
}

[CRepr]
public struct DS_DOMAIN_CONTROLLER_INFO_2A
{
	public PSTR NetbiosName;
	public PSTR DnsHostName;
	public PSTR SiteName;
	public PSTR SiteObjectName;
	public PSTR ComputerObjectName;
	public PSTR ServerObjectName;
	public PSTR NtdsDsaObjectName;
	public BOOL fIsPdc;
	public BOOL fDsEnabled;
	public BOOL fIsGc;
	public Guid SiteObjectGuid;
	public Guid ComputerObjectGuid;
	public Guid ServerObjectGuid;
	public Guid NtdsDsaObjectGuid;
}

[CRepr]
public struct DS_DOMAIN_CONTROLLER_INFO_2W
{
	public PWSTR NetbiosName;
	public PWSTR DnsHostName;
	public PWSTR SiteName;
	public PWSTR SiteObjectName;
	public PWSTR ComputerObjectName;
	public PWSTR ServerObjectName;
	public PWSTR NtdsDsaObjectName;
	public BOOL fIsPdc;
	public BOOL fDsEnabled;
	public BOOL fIsGc;
	public Guid SiteObjectGuid;
	public Guid ComputerObjectGuid;
	public Guid ServerObjectGuid;
	public Guid NtdsDsaObjectGuid;
}

[CRepr]
public struct DS_DOMAIN_CONTROLLER_INFO_3A
{
	public PSTR NetbiosName;
	public PSTR DnsHostName;
	public PSTR SiteName;
	public PSTR SiteObjectName;
	public PSTR ComputerObjectName;
	public PSTR ServerObjectName;
	public PSTR NtdsDsaObjectName;
	public BOOL fIsPdc;
	public BOOL fDsEnabled;
	public BOOL fIsGc;
	public BOOL fIsRodc;
	public Guid SiteObjectGuid;
	public Guid ComputerObjectGuid;
	public Guid ServerObjectGuid;
	public Guid NtdsDsaObjectGuid;
}

[CRepr]
public struct DS_DOMAIN_CONTROLLER_INFO_3W
{
	public PWSTR NetbiosName;
	public PWSTR DnsHostName;
	public PWSTR SiteName;
	public PWSTR SiteObjectName;
	public PWSTR ComputerObjectName;
	public PWSTR ServerObjectName;
	public PWSTR NtdsDsaObjectName;
	public BOOL fIsPdc;
	public BOOL fDsEnabled;
	public BOOL fIsGc;
	public BOOL fIsRodc;
	public Guid SiteObjectGuid;
	public Guid ComputerObjectGuid;
	public Guid ServerObjectGuid;
	public Guid NtdsDsaObjectGuid;
}

[CRepr]
public struct DS_REPL_NEIGHBORW
{
	public PWSTR pszNamingContext;
	public PWSTR pszSourceDsaDN;
	public PWSTR pszSourceDsaAddress;
	public PWSTR pszAsyncIntersiteTransportDN;
	public uint32 dwReplicaFlags;
	public uint32 dwReserved;
	public Guid uuidNamingContextObjGuid;
	public Guid uuidSourceDsaObjGuid;
	public Guid uuidSourceDsaInvocationID;
	public Guid uuidAsyncIntersiteTransportObjGuid;
	public int64 usnLastObjChangeSynced;
	public int64 usnAttributeFilter;
	public FILETIME ftimeLastSyncSuccess;
	public FILETIME ftimeLastSyncAttempt;
	public uint32 dwLastSyncResult;
	public uint32 cNumConsecutiveSyncFailures;
}

[CRepr]
public struct DS_REPL_NEIGHBORW_BLOB
{
	public uint32 oszNamingContext;
	public uint32 oszSourceDsaDN;
	public uint32 oszSourceDsaAddress;
	public uint32 oszAsyncIntersiteTransportDN;
	public uint32 dwReplicaFlags;
	public uint32 dwReserved;
	public Guid uuidNamingContextObjGuid;
	public Guid uuidSourceDsaObjGuid;
	public Guid uuidSourceDsaInvocationID;
	public Guid uuidAsyncIntersiteTransportObjGuid;
	public int64 usnLastObjChangeSynced;
	public int64 usnAttributeFilter;
	public FILETIME ftimeLastSyncSuccess;
	public FILETIME ftimeLastSyncAttempt;
	public uint32 dwLastSyncResult;
	public uint32 cNumConsecutiveSyncFailures;
}

[CRepr]
public struct DS_REPL_NEIGHBORSW
{
	public uint32 cNumNeighbors;
	public uint32 dwReserved;
	public DS_REPL_NEIGHBORW* rgNeighbor mut => &rgNeighbor_impl;
	private DS_REPL_NEIGHBORW[ANYSIZE_ARRAY] rgNeighbor_impl;
}

[CRepr]
public struct DS_REPL_CURSOR
{
	public Guid uuidSourceDsaInvocationID;
	public int64 usnAttributeFilter;
}

[CRepr]
public struct DS_REPL_CURSOR_2
{
	public Guid uuidSourceDsaInvocationID;
	public int64 usnAttributeFilter;
	public FILETIME ftimeLastSyncSuccess;
}

[CRepr]
public struct DS_REPL_CURSOR_3W
{
	public Guid uuidSourceDsaInvocationID;
	public int64 usnAttributeFilter;
	public FILETIME ftimeLastSyncSuccess;
	public PWSTR pszSourceDsaDN;
}

[CRepr]
public struct DS_REPL_CURSOR_BLOB
{
	public Guid uuidSourceDsaInvocationID;
	public int64 usnAttributeFilter;
	public FILETIME ftimeLastSyncSuccess;
	public uint32 oszSourceDsaDN;
}

[CRepr]
public struct DS_REPL_CURSORS
{
	public uint32 cNumCursors;
	public uint32 dwReserved;
	public DS_REPL_CURSOR* rgCursor mut => &rgCursor_impl;
	private DS_REPL_CURSOR[ANYSIZE_ARRAY] rgCursor_impl;
}

[CRepr]
public struct DS_REPL_CURSORS_2
{
	public uint32 cNumCursors;
	public uint32 dwEnumerationContext;
	public DS_REPL_CURSOR_2* rgCursor mut => &rgCursor_impl;
	private DS_REPL_CURSOR_2[ANYSIZE_ARRAY] rgCursor_impl;
}

[CRepr]
public struct DS_REPL_CURSORS_3W
{
	public uint32 cNumCursors;
	public uint32 dwEnumerationContext;
	public DS_REPL_CURSOR_3W* rgCursor mut => &rgCursor_impl;
	private DS_REPL_CURSOR_3W[ANYSIZE_ARRAY] rgCursor_impl;
}

[CRepr]
public struct DS_REPL_ATTR_META_DATA
{
	public PWSTR pszAttributeName;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
}

[CRepr]
public struct DS_REPL_ATTR_META_DATA_2
{
	public PWSTR pszAttributeName;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
	public PWSTR pszLastOriginatingDsaDN;
}

[CRepr]
public struct DS_REPL_ATTR_META_DATA_BLOB
{
	public uint32 oszAttributeName;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
	public uint32 oszLastOriginatingDsaDN;
}

[CRepr]
public struct DS_REPL_OBJ_META_DATA
{
	public uint32 cNumEntries;
	public uint32 dwReserved;
	public DS_REPL_ATTR_META_DATA* rgMetaData mut => &rgMetaData_impl;
	private DS_REPL_ATTR_META_DATA[ANYSIZE_ARRAY] rgMetaData_impl;
}

[CRepr]
public struct DS_REPL_OBJ_META_DATA_2
{
	public uint32 cNumEntries;
	public uint32 dwReserved;
	public DS_REPL_ATTR_META_DATA_2* rgMetaData mut => &rgMetaData_impl;
	private DS_REPL_ATTR_META_DATA_2[ANYSIZE_ARRAY] rgMetaData_impl;
}

[CRepr]
public struct DS_REPL_KCC_DSA_FAILUREW
{
	public PWSTR pszDsaDN;
	public Guid uuidDsaObjGuid;
	public FILETIME ftimeFirstFailure;
	public uint32 cNumFailures;
	public uint32 dwLastResult;
}

[CRepr]
public struct DS_REPL_KCC_DSA_FAILUREW_BLOB
{
	public uint32 oszDsaDN;
	public Guid uuidDsaObjGuid;
	public FILETIME ftimeFirstFailure;
	public uint32 cNumFailures;
	public uint32 dwLastResult;
}

[CRepr]
public struct DS_REPL_KCC_DSA_FAILURESW
{
	public uint32 cNumEntries;
	public uint32 dwReserved;
	public DS_REPL_KCC_DSA_FAILUREW* rgDsaFailure mut => &rgDsaFailure_impl;
	private DS_REPL_KCC_DSA_FAILUREW[ANYSIZE_ARRAY] rgDsaFailure_impl;
}

[CRepr]
public struct DS_REPL_OPW
{
	public FILETIME ftimeEnqueued;
	public uint32 ulSerialNumber;
	public uint32 ulPriority;
	public DS_REPL_OP_TYPE OpType;
	public uint32 ulOptions;
	public PWSTR pszNamingContext;
	public PWSTR pszDsaDN;
	public PWSTR pszDsaAddress;
	public Guid uuidNamingContextObjGuid;
	public Guid uuidDsaObjGuid;
}

[CRepr]
public struct DS_REPL_OPW_BLOB
{
	public FILETIME ftimeEnqueued;
	public uint32 ulSerialNumber;
	public uint32 ulPriority;
	public DS_REPL_OP_TYPE OpType;
	public uint32 ulOptions;
	public uint32 oszNamingContext;
	public uint32 oszDsaDN;
	public uint32 oszDsaAddress;
	public Guid uuidNamingContextObjGuid;
	public Guid uuidDsaObjGuid;
}

[CRepr]
public struct DS_REPL_PENDING_OPSW
{
	public FILETIME ftimeCurrentOpStarted;
	public uint32 cNumPendingOps;
	public DS_REPL_OPW* rgPendingOp mut => &rgPendingOp_impl;
	private DS_REPL_OPW[ANYSIZE_ARRAY] rgPendingOp_impl;
}

[CRepr]
public struct DS_REPL_VALUE_META_DATA
{
	public PWSTR pszAttributeName;
	public PWSTR pszObjectDn;
	public uint32 cbData;
	public uint8* pbData;
	public FILETIME ftimeDeleted;
	public FILETIME ftimeCreated;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
}

[CRepr]
public struct DS_REPL_VALUE_META_DATA_2
{
	public PWSTR pszAttributeName;
	public PWSTR pszObjectDn;
	public uint32 cbData;
	public uint8* pbData;
	public FILETIME ftimeDeleted;
	public FILETIME ftimeCreated;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
	public PWSTR pszLastOriginatingDsaDN;
}

[CRepr]
public struct DS_REPL_VALUE_META_DATA_EXT
{
	public PWSTR pszAttributeName;
	public PWSTR pszObjectDn;
	public uint32 cbData;
	public uint8* pbData;
	public FILETIME ftimeDeleted;
	public FILETIME ftimeCreated;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
	public PWSTR pszLastOriginatingDsaDN;
	public uint32 dwUserIdentifier;
	public uint32 dwPriorLinkState;
	public uint32 dwCurrentLinkState;
}

[CRepr]
public struct DS_REPL_VALUE_META_DATA_BLOB
{
	public uint32 oszAttributeName;
	public uint32 oszObjectDn;
	public uint32 cbData;
	public uint32 obData;
	public FILETIME ftimeDeleted;
	public FILETIME ftimeCreated;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
	public uint32 oszLastOriginatingDsaDN;
}

[CRepr]
public struct DS_REPL_VALUE_META_DATA_BLOB_EXT
{
	public uint32 oszAttributeName;
	public uint32 oszObjectDn;
	public uint32 cbData;
	public uint32 obData;
	public FILETIME ftimeDeleted;
	public FILETIME ftimeCreated;
	public uint32 dwVersion;
	public FILETIME ftimeLastOriginatingChange;
	public Guid uuidLastOriginatingDsaInvocationID;
	public int64 usnOriginatingChange;
	public int64 usnLocalChange;
	public uint32 oszLastOriginatingDsaDN;
	public uint32 dwUserIdentifier;
	public uint32 dwPriorLinkState;
	public uint32 dwCurrentLinkState;
}

[CRepr]
public struct DS_REPL_ATTR_VALUE_META_DATA
{
	public uint32 cNumEntries;
	public uint32 dwEnumerationContext;
	public DS_REPL_VALUE_META_DATA* rgMetaData mut => &rgMetaData_impl;
	private DS_REPL_VALUE_META_DATA[ANYSIZE_ARRAY] rgMetaData_impl;
}

[CRepr]
public struct DS_REPL_ATTR_VALUE_META_DATA_2
{
	public uint32 cNumEntries;
	public uint32 dwEnumerationContext;
	public DS_REPL_VALUE_META_DATA_2* rgMetaData mut => &rgMetaData_impl;
	private DS_REPL_VALUE_META_DATA_2[ANYSIZE_ARRAY] rgMetaData_impl;
}

[CRepr]
public struct DS_REPL_ATTR_VALUE_META_DATA_EXT
{
	public uint32 cNumEntries;
	public uint32 dwEnumerationContext;
	public DS_REPL_VALUE_META_DATA_EXT* rgMetaData mut => &rgMetaData_impl;
	private DS_REPL_VALUE_META_DATA_EXT[ANYSIZE_ARRAY] rgMetaData_impl;
}

[CRepr]
public struct DS_REPL_QUEUE_STATISTICSW
{
	public FILETIME ftimeCurrentOpStarted;
	public uint32 cNumPendingOps;
	public FILETIME ftimeOldestSync;
	public FILETIME ftimeOldestAdd;
	public FILETIME ftimeOldestMod;
	public FILETIME ftimeOldestDel;
	public FILETIME ftimeOldestUpdRefs;
}

[CRepr]
public struct DSROLE_PRIMARY_DOMAIN_INFO_BASIC
{
	public DSROLE_MACHINE_ROLE MachineRole;
	public uint32 Flags;
	public PWSTR DomainNameFlat;
	public PWSTR DomainNameDns;
	public PWSTR DomainForestName;
	public Guid DomainGuid;
}

[CRepr]
public struct DSROLE_UPGRADE_STATUS_INFO
{
	public uint32 OperationState;
	public DSROLE_SERVER_STATE PreviousServerState;
}

[CRepr]
public struct DSROLE_OPERATION_STATE_INFO
{
	public DSROLE_OPERATION_STATE OperationState;
}

[CRepr]
public struct DOMAIN_CONTROLLER_INFOA
{
	public PSTR DomainControllerName;
	public PSTR DomainControllerAddress;
	public uint32 DomainControllerAddressType;
	public Guid DomainGuid;
	public PSTR DomainName;
	public PSTR DnsForestName;
	public uint32 Flags;
	public PSTR DcSiteName;
	public PSTR ClientSiteName;
}

[CRepr]
public struct DOMAIN_CONTROLLER_INFOW
{
	public PWSTR DomainControllerName;
	public PWSTR DomainControllerAddress;
	public uint32 DomainControllerAddressType;
	public Guid DomainGuid;
	public PWSTR DomainName;
	public PWSTR DnsForestName;
	public uint32 Flags;
	public PWSTR DcSiteName;
	public PWSTR ClientSiteName;
}

[CRepr]
public struct DS_DOMAIN_TRUSTSW
{
	public PWSTR NetbiosDomainName;
	public PWSTR DnsDomainName;
	public uint32 Flags;
	public uint32 ParentIndex;
	public uint32 TrustType;
	public uint32 TrustAttributes;
	public PSID DomainSid;
	public Guid DomainGuid;
}

[CRepr]
public struct DS_DOMAIN_TRUSTSA
{
	public PSTR NetbiosDomainName;
	public PSTR DnsDomainName;
	public uint32 Flags;
	public uint32 ParentIndex;
	public uint32 TrustType;
	public uint32 TrustAttributes;
	public PSID DomainSid;
	public Guid DomainGuid;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_PropertyEntry = .(0x72d3edc2, 0xa4c4, 0x11d0, 0x85, 0x33, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);


	public const Guid CLSID_PropertyValue = .(0x7b9e38b0, 0xa97c, 0x11d0, 0x85, 0x34, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);


	public const Guid CLSID_AccessControlEntry = .(0xb75ac000, 0x9bdd, 0x11d0, 0x85, 0x2c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);


	public const Guid CLSID_AccessControlList = .(0xb85ea052, 0x9bdd, 0x11d0, 0x85, 0x2c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);


	public const Guid CLSID_SecurityDescriptor = .(0xb958f73c, 0x9bdd, 0x11d0, 0x85, 0x2c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);


	public const Guid CLSID_LargeInteger = .(0x927971f5, 0x0939, 0x11d1, 0x8b, 0xe1, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);


	public const Guid CLSID_NameTranslate = .(0x274fae1f, 0x3626, 0x11d1, 0xa3, 0xa4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_CaseIgnoreList = .(0x15f88a55, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_FaxNumber = .(0xa5062215, 0x4681, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_NetAddress = .(0xb0b71247, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_OctetList = .(0x1241400f, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_Email = .(0x8f92a857, 0x478e, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_Path = .(0xb2538919, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_ReplicaPointer = .(0xf5d1badf, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_Timestamp = .(0xb2bed2eb, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_PostalAddress = .(0x0a75afcd, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_BackLink = .(0xfcbf906f, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_TypedName = .(0xb33143cb, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_Hold = .(0xb3ad3e13, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_Pathname = .(0x080d0d78, 0xf421, 0x11d0, 0xa3, 0x6e, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);


	public const Guid CLSID_ADSystemInfo = .(0x50b6327f, 0xafd1, 0x11d2, 0x9c, 0xb9, 0x00, 0x00, 0xf8, 0x7a, 0x36, 0x9e);


	public const Guid CLSID_WinNTSystemInfo = .(0x66182ec4, 0xafd1, 0x11d2, 0x9c, 0xb9, 0x00, 0x00, 0xf8, 0x7a, 0x36, 0x9e);


	public const Guid CLSID_DNWithBinary = .(0x7e99c0a3, 0xf935, 0x11d2, 0xba, 0x96, 0x00, 0xc0, 0x4f, 0xb6, 0xd0, 0xd1);


	public const Guid CLSID_DNWithString = .(0x334857cc, 0xf934, 0x11d2, 0xba, 0x96, 0x00, 0xc0, 0x4f, 0xb6, 0xd0, 0xd1);


	public const Guid CLSID_ADsSecurityUtility = .(0xf270c64a, 0xffb8, 0x4ae4, 0x85, 0xfe, 0x3a, 0x75, 0xe5, 0x34, 0x79, 0x66);


}
#endregion

#region COM Types
[CRepr]struct IQueryForm : IUnknown
{
	public new const Guid IID = .(0x8cfcee30, 0x39bd, 0x11d0, 0xb8, 0xd1, 0x00, 0xa0, 0x24, 0xab, 0x2d, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY hkForm) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPCQADDFORMSPROC pAddFormsProc, LPARAM lParam) AddForms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPCQADDPAGESPROC pAddPagesProc, LPARAM lParam) AddPages;
	}


	public HRESULT Initialize(HKEY hkForm) mut => VT.[Friend]Initialize(&this, hkForm);

	public HRESULT AddForms(LPCQADDFORMSPROC pAddFormsProc, LPARAM lParam) mut => VT.[Friend]AddForms(&this, pAddFormsProc, lParam);

	public HRESULT AddPages(LPCQADDPAGESPROC pAddPagesProc, LPARAM lParam) mut => VT.[Friend]AddPages(&this, pAddPagesProc, lParam);
}

[CRepr]struct IPersistQuery : IPersist
{
	public new const Guid IID = .(0x1a3114b8, 0xa62e, 0x11d0, 0xa6, 0xc5, 0x00, 0xa0, 0xc9, 0x06, 0xaf, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSection, PWSTR pValueName, PWSTR pValue) WriteString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSection, PWSTR pValueName, PWSTR pBuffer, int32 cchBuffer) ReadString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSection, PWSTR pValueName, int32 value) WriteInt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSection, PWSTR pValueName, int32* pValue) ReadInt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSection, PWSTR pValueName, void* pStruct, uint32 cbStruct) WriteStruct;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSection, PWSTR pValueName, void* pStruct, uint32 cbStruct) ReadStruct;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT WriteString(PWSTR pSection, PWSTR pValueName, PWSTR pValue) mut => VT.[Friend]WriteString(&this, pSection, pValueName, pValue);

	public HRESULT ReadString(PWSTR pSection, PWSTR pValueName, PWSTR pBuffer, int32 cchBuffer) mut => VT.[Friend]ReadString(&this, pSection, pValueName, pBuffer, cchBuffer);

	public HRESULT WriteInt(PWSTR pSection, PWSTR pValueName, int32 value) mut => VT.[Friend]WriteInt(&this, pSection, pValueName, value);

	public HRESULT ReadInt(PWSTR pSection, PWSTR pValueName, int32* pValue) mut => VT.[Friend]ReadInt(&this, pSection, pValueName, pValue);

	public HRESULT WriteStruct(PWSTR pSection, PWSTR pValueName, void* pStruct, uint32 cbStruct) mut => VT.[Friend]WriteStruct(&this, pSection, pValueName, pStruct, cbStruct);

	public HRESULT ReadStruct(PWSTR pSection, PWSTR pValueName, void* pStruct, uint32 cbStruct) mut => VT.[Friend]ReadStruct(&this, pSection, pValueName, pStruct, cbStruct);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct ICommonQuery : IUnknown
{
	public new const Guid IID = .(0xab50dec0, 0x6f1d, 0x11d0, 0xa1, 0xc4, 0x00, 0xaa, 0x00, 0xc1, 0x6e, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, OPENQUERYWINDOW* pQueryWnd, IDataObject** ppDataObject) OpenQueryWindow;
	}


	public HRESULT OpenQueryWindow(HWND hwndParent, OPENQUERYWINDOW* pQueryWnd, IDataObject** ppDataObject) mut => VT.[Friend]OpenQueryWindow(&this, hwndParent, pQueryWnd, ppDataObject);
}

[CRepr]struct IADs : IDispatch
{
	public new const Guid IID = .(0xfd8256d0, 0xfd15, 0x11ce, 0xab, 0xc4, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Class;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_GUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ADsPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Schema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT* pvProp) Get;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT vProp) Put;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT* pvProp) GetEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnControlCode, BSTR bstrName, VARIANT vProp) PutEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vProperties, int32 lnReserved) GetInfoEx;
	}


	public HRESULT get_Name(BSTR* retval) mut => VT.[Friend]get_Name(&this, retval);

	public HRESULT get_Class(BSTR* retval) mut => VT.[Friend]get_Class(&this, retval);

	public HRESULT get_GUID(BSTR* retval) mut => VT.[Friend]get_GUID(&this, retval);

	public HRESULT get_ADsPath(BSTR* retval) mut => VT.[Friend]get_ADsPath(&this, retval);

	public HRESULT get_Parent(BSTR* retval) mut => VT.[Friend]get_Parent(&this, retval);

	public HRESULT get_Schema(BSTR* retval) mut => VT.[Friend]get_Schema(&this, retval);

	public HRESULT GetInfo() mut => VT.[Friend]GetInfo(&this);

	public HRESULT SetInfo() mut => VT.[Friend]SetInfo(&this);

	public HRESULT Get(BSTR bstrName, VARIANT* pvProp) mut => VT.[Friend]Get(&this, bstrName, pvProp);

	public HRESULT Put(BSTR bstrName, VARIANT vProp) mut => VT.[Friend]Put(&this, bstrName, vProp);

	public HRESULT GetEx(BSTR bstrName, VARIANT* pvProp) mut => VT.[Friend]GetEx(&this, bstrName, pvProp);

	public HRESULT PutEx(int32 lnControlCode, BSTR bstrName, VARIANT vProp) mut => VT.[Friend]PutEx(&this, lnControlCode, bstrName, vProp);

	public HRESULT GetInfoEx(VARIANT vProperties, int32 lnReserved) mut => VT.[Friend]GetInfoEx(&this, vProperties, lnReserved);
}

[CRepr]struct IADsContainer : IDispatch
{
	public new const Guid IID = .(0x001677d0, 0xfd16, 0x11ce, 0xab, 0xc4, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVar) get_Filter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Var) put_Filter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvFilter) get_Hints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vHints) put_Hints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ClassName, BSTR RelativeName, IDispatch** ppObject) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ClassName, BSTR RelativeName, IDispatch** ppObject) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrClassName, BSTR bstrRelativeName) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SourceName, BSTR NewName, IDispatch** ppObject) CopyHere;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SourceName, BSTR NewName, IDispatch** ppObject) MoveHere;
	}


	public HRESULT get_Count(int32* retval) mut => VT.[Friend]get_Count(&this, retval);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Filter(VARIANT* pVar) mut => VT.[Friend]get_Filter(&this, pVar);

	public HRESULT put_Filter(VARIANT Var) mut => VT.[Friend]put_Filter(&this, Var);

	public HRESULT get_Hints(VARIANT* pvFilter) mut => VT.[Friend]get_Hints(&this, pvFilter);

	public HRESULT put_Hints(VARIANT vHints) mut => VT.[Friend]put_Hints(&this, vHints);

	public HRESULT GetObject(BSTR ClassName, BSTR RelativeName, IDispatch** ppObject) mut => VT.[Friend]GetObject(&this, ClassName, RelativeName, ppObject);

	public HRESULT Create(BSTR ClassName, BSTR RelativeName, IDispatch** ppObject) mut => VT.[Friend]Create(&this, ClassName, RelativeName, ppObject);

	public HRESULT Delete(BSTR bstrClassName, BSTR bstrRelativeName) mut => VT.[Friend]Delete(&this, bstrClassName, bstrRelativeName);

	public HRESULT CopyHere(BSTR SourceName, BSTR NewName, IDispatch** ppObject) mut => VT.[Friend]CopyHere(&this, SourceName, NewName, ppObject);

	public HRESULT MoveHere(BSTR SourceName, BSTR NewName, IDispatch** ppObject) mut => VT.[Friend]MoveHere(&this, SourceName, NewName, ppObject);
}

[CRepr]struct IADsCollection : IDispatch
{
	public new const Guid IID = .(0x72b945e0, 0x253b, 0x11cf, 0xa9, 0x88, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumerator) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT vItem) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemToBeRemoved) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT* pvItem) GetObject;
	}


	public HRESULT get__NewEnum(IUnknown** ppEnumerator) mut => VT.[Friend]get__NewEnum(&this, ppEnumerator);

	public HRESULT Add(BSTR bstrName, VARIANT vItem) mut => VT.[Friend]Add(&this, bstrName, vItem);

	public HRESULT Remove(BSTR bstrItemToBeRemoved) mut => VT.[Friend]Remove(&this, bstrItemToBeRemoved);

	public HRESULT GetObject(BSTR bstrName, VARIANT* pvItem) mut => VT.[Friend]GetObject(&this, bstrName, pvItem);
}

[CRepr]struct IADsMembers : IDispatch
{
	public new const Guid IID = .(0x451a0030, 0x72ec, 0x11cf, 0xb0, 0x3b, 0x00, 0xaa, 0x00, 0x6e, 0x09, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumerator) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvFilter) get_Filter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pvFilter) put_Filter;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumerator) mut => VT.[Friend]get__NewEnum(&this, ppEnumerator);

	public HRESULT get_Filter(VARIANT* pvFilter) mut => VT.[Friend]get_Filter(&this, pvFilter);

	public HRESULT put_Filter(VARIANT pvFilter) mut => VT.[Friend]put_Filter(&this, pvFilter);
}

[CRepr]struct IADsPropertyList : IDispatch
{
	public new const Guid IID = .(0xc6f602b6, 0x8f69, 0x11d0, 0x85, 0x28, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_PropertyCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVariant) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cElements) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, VARIANT* pVariant) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, int32 lnADsType, VARIANT* pVariant) GetPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varData) PutPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varEntry) ResetPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PurgePropertyList;
	}


	public HRESULT get_PropertyCount(int32* plCount) mut => VT.[Friend]get_PropertyCount(&this, plCount);

	public HRESULT Next(VARIANT* pVariant) mut => VT.[Friend]Next(&this, pVariant);

	public HRESULT Skip(int32 cElements) mut => VT.[Friend]Skip(&this, cElements);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Item(VARIANT varIndex, VARIANT* pVariant) mut => VT.[Friend]Item(&this, varIndex, pVariant);

	public HRESULT GetPropertyItem(BSTR bstrName, int32 lnADsType, VARIANT* pVariant) mut => VT.[Friend]GetPropertyItem(&this, bstrName, lnADsType, pVariant);

	public HRESULT PutPropertyItem(VARIANT varData) mut => VT.[Friend]PutPropertyItem(&this, varData);

	public HRESULT ResetPropertyItem(VARIANT varEntry) mut => VT.[Friend]ResetPropertyItem(&this, varEntry);

	public HRESULT PurgePropertyList() mut => VT.[Friend]PurgePropertyList(&this);
}

[CRepr]struct IADsPropertyEntry : IDispatch
{
	public new const Guid IID = .(0x05792c8e, 0x941f, 0x11d0, 0x85, 0x29, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ADsType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnADsType) put_ADsType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ControlCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnControlCode) put_ControlCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Values;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vValues) put_Values;
	}


	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_Name(BSTR* retval) mut => VT.[Friend]get_Name(&this, retval);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_ADsType(int32* retval) mut => VT.[Friend]get_ADsType(&this, retval);

	public HRESULT put_ADsType(int32 lnADsType) mut => VT.[Friend]put_ADsType(&this, lnADsType);

	public HRESULT get_ControlCode(int32* retval) mut => VT.[Friend]get_ControlCode(&this, retval);

	public HRESULT put_ControlCode(int32 lnControlCode) mut => VT.[Friend]put_ControlCode(&this, lnControlCode);

	public HRESULT get_Values(VARIANT* retval) mut => VT.[Friend]get_Values(&this, retval);

	public HRESULT put_Values(VARIANT vValues) mut => VT.[Friend]put_Values(&this, vValues);
}

[CRepr]struct IADsPropertyValue : IDispatch
{
	public new const Guid IID = .(0x79fa9ad0, 0xa97c, 0x11d0, 0x85, 0x34, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ADsType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnADsType) put_ADsType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DNString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDNString) put_DNString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_CaseExactString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCaseExactString) put_CaseExactString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_CaseIgnoreString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCaseIgnoreString) put_CaseIgnoreString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PrintableString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPrintableString) put_PrintableString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_NumericString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNumericString) put_NumericString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Boolean;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnBoolean) put_Boolean;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Integer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnInteger) put_Integer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_OctetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vOctetString) put_OctetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** retval) get_SecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pSecurityDescriptor) put_SecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** retval) get_LargeInteger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pLargeInteger) put_LargeInteger;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_UTCTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daUTCTime) put_UTCTime;
	}


	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_ADsType(int32* retval) mut => VT.[Friend]get_ADsType(&this, retval);

	public HRESULT put_ADsType(int32 lnADsType) mut => VT.[Friend]put_ADsType(&this, lnADsType);

	public HRESULT get_DNString(BSTR* retval) mut => VT.[Friend]get_DNString(&this, retval);

	public HRESULT put_DNString(BSTR bstrDNString) mut => VT.[Friend]put_DNString(&this, bstrDNString);

	public HRESULT get_CaseExactString(BSTR* retval) mut => VT.[Friend]get_CaseExactString(&this, retval);

	public HRESULT put_CaseExactString(BSTR bstrCaseExactString) mut => VT.[Friend]put_CaseExactString(&this, bstrCaseExactString);

	public HRESULT get_CaseIgnoreString(BSTR* retval) mut => VT.[Friend]get_CaseIgnoreString(&this, retval);

	public HRESULT put_CaseIgnoreString(BSTR bstrCaseIgnoreString) mut => VT.[Friend]put_CaseIgnoreString(&this, bstrCaseIgnoreString);

	public HRESULT get_PrintableString(BSTR* retval) mut => VT.[Friend]get_PrintableString(&this, retval);

	public HRESULT put_PrintableString(BSTR bstrPrintableString) mut => VT.[Friend]put_PrintableString(&this, bstrPrintableString);

	public HRESULT get_NumericString(BSTR* retval) mut => VT.[Friend]get_NumericString(&this, retval);

	public HRESULT put_NumericString(BSTR bstrNumericString) mut => VT.[Friend]put_NumericString(&this, bstrNumericString);

	public HRESULT get_Boolean(int32* retval) mut => VT.[Friend]get_Boolean(&this, retval);

	public HRESULT put_Boolean(int32 lnBoolean) mut => VT.[Friend]put_Boolean(&this, lnBoolean);

	public HRESULT get_Integer(int32* retval) mut => VT.[Friend]get_Integer(&this, retval);

	public HRESULT put_Integer(int32 lnInteger) mut => VT.[Friend]put_Integer(&this, lnInteger);

	public HRESULT get_OctetString(VARIANT* retval) mut => VT.[Friend]get_OctetString(&this, retval);

	public HRESULT put_OctetString(VARIANT vOctetString) mut => VT.[Friend]put_OctetString(&this, vOctetString);

	public HRESULT get_SecurityDescriptor(IDispatch** retval) mut => VT.[Friend]get_SecurityDescriptor(&this, retval);

	public HRESULT put_SecurityDescriptor(IDispatch* pSecurityDescriptor) mut => VT.[Friend]put_SecurityDescriptor(&this, pSecurityDescriptor);

	public HRESULT get_LargeInteger(IDispatch** retval) mut => VT.[Friend]get_LargeInteger(&this, retval);

	public HRESULT put_LargeInteger(IDispatch* pLargeInteger) mut => VT.[Friend]put_LargeInteger(&this, pLargeInteger);

	public HRESULT get_UTCTime(double* retval) mut => VT.[Friend]get_UTCTime(&this, retval);

	public HRESULT put_UTCTime(double daUTCTime) mut => VT.[Friend]put_UTCTime(&this, daUTCTime);
}

[CRepr]struct IADsPropertyValue2 : IDispatch
{
	public new const Guid IID = .(0x306e831c, 0x5bc7, 0x11d1, 0xa3, 0xb8, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lnADsType, VARIANT* pvProp) GetObjectProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnADsType, VARIANT vProp) PutObjectProperty;
	}


	public HRESULT GetObjectProperty(int32* lnADsType, VARIANT* pvProp) mut => VT.[Friend]GetObjectProperty(&this, lnADsType, pvProp);

	public HRESULT PutObjectProperty(int32 lnADsType, VARIANT vProp) mut => VT.[Friend]PutObjectProperty(&this, lnADsType, vProp);
}

[CRepr]struct IPrivateDispatch : IUnknown
{
	public new const Guid IID = .(0x86ab4bbe, 0x65f6, 0x11d1, 0x8c, 0x13, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwExtensionId) ADSIInitializeDispatchManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pctinfo) ADSIGetTypeInfoCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itinfo, uint32 lcid, ITypeInfo** pptinfo) ADSIGetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, uint16** rgszNames, uint32 cNames, uint32 lcid, int32* rgdispid) ADSIGetIDsOfNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispidMember, in Guid riid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) ADSIInvoke;
	}


	public HRESULT ADSIInitializeDispatchManager(int32 dwExtensionId) mut => VT.[Friend]ADSIInitializeDispatchManager(&this, dwExtensionId);

	public HRESULT ADSIGetTypeInfoCount(uint32* pctinfo) mut => VT.[Friend]ADSIGetTypeInfoCount(&this, pctinfo);

	public HRESULT ADSIGetTypeInfo(uint32 itinfo, uint32 lcid, ITypeInfo** pptinfo) mut => VT.[Friend]ADSIGetTypeInfo(&this, itinfo, lcid, pptinfo);

	public HRESULT ADSIGetIDsOfNames(in Guid riid, uint16** rgszNames, uint32 cNames, uint32 lcid, int32* rgdispid) mut => VT.[Friend]ADSIGetIDsOfNames(&this, riid, rgszNames, cNames, lcid, rgdispid);

	public HRESULT ADSIInvoke(int32 dispidMember, in Guid riid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) mut => VT.[Friend]ADSIInvoke(&this, dispidMember, riid, lcid, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
}

[CRepr]struct IPrivateUnknown : IUnknown
{
	public new const Guid IID = .(0x89126bab, 0x6ead, 0x11d1, 0x8c, 0x18, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR lpszUserName, BSTR lpszPassword, int32 lnReserved) ADSIInitializeObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ADSIReleaseObject;
	}


	public HRESULT ADSIInitializeObject(BSTR lpszUserName, BSTR lpszPassword, int32 lnReserved) mut => VT.[Friend]ADSIInitializeObject(&this, lpszUserName, lpszPassword, lnReserved);

	public HRESULT ADSIReleaseObject() mut => VT.[Friend]ADSIReleaseObject(&this);
}

[CRepr]struct IADsExtension : IUnknown
{
	public new const Guid IID = .(0x3d35553c, 0xd2b0, 0x11d1, 0xb1, 0x7b, 0x00, 0x00, 0xf8, 0x75, 0x93, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCode, VARIANT varData1, VARIANT varData2, VARIANT varData3) Operate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, uint16** rgszNames, uint32 cNames, uint32 lcid, int32* rgDispid) PrivateGetIDsOfNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispidMember, in Guid riid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) PrivateInvoke;
	}


	public HRESULT Operate(uint32 dwCode, VARIANT varData1, VARIANT varData2, VARIANT varData3) mut => VT.[Friend]Operate(&this, dwCode, varData1, varData2, varData3);

	public HRESULT PrivateGetIDsOfNames(in Guid riid, uint16** rgszNames, uint32 cNames, uint32 lcid, int32* rgDispid) mut => VT.[Friend]PrivateGetIDsOfNames(&this, riid, rgszNames, cNames, lcid, rgDispid);

	public HRESULT PrivateInvoke(int32 dispidMember, in Guid riid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) mut => VT.[Friend]PrivateInvoke(&this, dispidMember, riid, lcid, wFlags, pdispparams, pvarResult, pexcepinfo, puArgErr);
}

[CRepr]struct IADsDeleteOps : IDispatch
{
	public new const Guid IID = .(0xb2bd0902, 0x8878, 0x11d1, 0x8c, 0x21, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnFlags) DeleteObject;
	}


	public HRESULT DeleteObject(int32 lnFlags) mut => VT.[Friend]DeleteObject(&this, lnFlags);
}

[CRepr]struct IADsNamespaces : IADs
{
	public new const Guid IID = .(0x28b96ba0, 0xb330, 0x11cf, 0xa9, 0xad, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DefaultContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDefaultContainer) put_DefaultContainer;
	}


	public HRESULT get_DefaultContainer(BSTR* retval) mut => VT.[Friend]get_DefaultContainer(&this, retval);

	public HRESULT put_DefaultContainer(BSTR bstrDefaultContainer) mut => VT.[Friend]put_DefaultContainer(&this, bstrDefaultContainer);
}

[CRepr]struct IADsClass : IADs
{
	public new const Guid IID = .(0xc8f93dd0, 0x4ae0, 0x11cf, 0x9e, 0x73, 0x00, 0xaa, 0x00, 0x4a, 0x56, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PrimaryInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_CLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCLSID) put_CLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_OID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOID) put_OID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_Abstract;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fAbstract) put_Abstract;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_Auxiliary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fAuxiliary) put_Auxiliary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_MandatoryProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vMandatoryProperties) put_MandatoryProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_OptionalProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vOptionalProperties) put_OptionalProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_NamingProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vNamingProperties) put_NamingProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_DerivedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDerivedFrom) put_DerivedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_AuxDerivedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vAuxDerivedFrom) put_AuxDerivedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_PossibleSuperiors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vPossibleSuperiors) put_PossibleSuperiors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Containment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vContainment) put_Containment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_Container;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fContainer) put_Container;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_HelpFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHelpFileName) put_HelpFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_HelpFileContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnHelpFileContext) put_HelpFileContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsCollection** ppQualifiers) Qualifiers;
	}


	public HRESULT get_PrimaryInterface(BSTR* retval) mut => VT.[Friend]get_PrimaryInterface(&this, retval);

	public HRESULT get_CLSID(BSTR* retval) mut => VT.[Friend]get_CLSID(&this, retval);

	public HRESULT put_CLSID(BSTR bstrCLSID) mut => VT.[Friend]put_CLSID(&this, bstrCLSID);

	public HRESULT get_OID(BSTR* retval) mut => VT.[Friend]get_OID(&this, retval);

	public HRESULT put_OID(BSTR bstrOID) mut => VT.[Friend]put_OID(&this, bstrOID);

	public HRESULT get_Abstract(int16* retval) mut => VT.[Friend]get_Abstract(&this, retval);

	public HRESULT put_Abstract(int16 fAbstract) mut => VT.[Friend]put_Abstract(&this, fAbstract);

	public HRESULT get_Auxiliary(int16* retval) mut => VT.[Friend]get_Auxiliary(&this, retval);

	public HRESULT put_Auxiliary(int16 fAuxiliary) mut => VT.[Friend]put_Auxiliary(&this, fAuxiliary);

	public HRESULT get_MandatoryProperties(VARIANT* retval) mut => VT.[Friend]get_MandatoryProperties(&this, retval);

	public HRESULT put_MandatoryProperties(VARIANT vMandatoryProperties) mut => VT.[Friend]put_MandatoryProperties(&this, vMandatoryProperties);

	public HRESULT get_OptionalProperties(VARIANT* retval) mut => VT.[Friend]get_OptionalProperties(&this, retval);

	public HRESULT put_OptionalProperties(VARIANT vOptionalProperties) mut => VT.[Friend]put_OptionalProperties(&this, vOptionalProperties);

	public HRESULT get_NamingProperties(VARIANT* retval) mut => VT.[Friend]get_NamingProperties(&this, retval);

	public HRESULT put_NamingProperties(VARIANT vNamingProperties) mut => VT.[Friend]put_NamingProperties(&this, vNamingProperties);

	public HRESULT get_DerivedFrom(VARIANT* retval) mut => VT.[Friend]get_DerivedFrom(&this, retval);

	public HRESULT put_DerivedFrom(VARIANT vDerivedFrom) mut => VT.[Friend]put_DerivedFrom(&this, vDerivedFrom);

	public HRESULT get_AuxDerivedFrom(VARIANT* retval) mut => VT.[Friend]get_AuxDerivedFrom(&this, retval);

	public HRESULT put_AuxDerivedFrom(VARIANT vAuxDerivedFrom) mut => VT.[Friend]put_AuxDerivedFrom(&this, vAuxDerivedFrom);

	public HRESULT get_PossibleSuperiors(VARIANT* retval) mut => VT.[Friend]get_PossibleSuperiors(&this, retval);

	public HRESULT put_PossibleSuperiors(VARIANT vPossibleSuperiors) mut => VT.[Friend]put_PossibleSuperiors(&this, vPossibleSuperiors);

	public HRESULT get_Containment(VARIANT* retval) mut => VT.[Friend]get_Containment(&this, retval);

	public HRESULT put_Containment(VARIANT vContainment) mut => VT.[Friend]put_Containment(&this, vContainment);

	public HRESULT get_Container(int16* retval) mut => VT.[Friend]get_Container(&this, retval);

	public HRESULT put_Container(int16 fContainer) mut => VT.[Friend]put_Container(&this, fContainer);

	public HRESULT get_HelpFileName(BSTR* retval) mut => VT.[Friend]get_HelpFileName(&this, retval);

	public HRESULT put_HelpFileName(BSTR bstrHelpFileName) mut => VT.[Friend]put_HelpFileName(&this, bstrHelpFileName);

	public HRESULT get_HelpFileContext(int32* retval) mut => VT.[Friend]get_HelpFileContext(&this, retval);

	public HRESULT put_HelpFileContext(int32 lnHelpFileContext) mut => VT.[Friend]put_HelpFileContext(&this, lnHelpFileContext);

	public HRESULT Qualifiers(IADsCollection** ppQualifiers) mut => VT.[Friend]Qualifiers(&this, ppQualifiers);
}

[CRepr]struct IADsProperty : IADs
{
	public new const Guid IID = .(0xc8f93dd3, 0x4ae0, 0x11cf, 0x9e, 0x73, 0x00, 0xaa, 0x00, 0x4a, 0x56, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_OID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOID) put_OID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Syntax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSyntax) put_Syntax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxRange) put_MaxRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MinRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMinRange) put_MinRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_MultiValued;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMultiValued) put_MultiValued;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsCollection** ppQualifiers) Qualifiers;
	}


	public HRESULT get_OID(BSTR* retval) mut => VT.[Friend]get_OID(&this, retval);

	public HRESULT put_OID(BSTR bstrOID) mut => VT.[Friend]put_OID(&this, bstrOID);

	public HRESULT get_Syntax(BSTR* retval) mut => VT.[Friend]get_Syntax(&this, retval);

	public HRESULT put_Syntax(BSTR bstrSyntax) mut => VT.[Friend]put_Syntax(&this, bstrSyntax);

	public HRESULT get_MaxRange(int32* retval) mut => VT.[Friend]get_MaxRange(&this, retval);

	public HRESULT put_MaxRange(int32 lnMaxRange) mut => VT.[Friend]put_MaxRange(&this, lnMaxRange);

	public HRESULT get_MinRange(int32* retval) mut => VT.[Friend]get_MinRange(&this, retval);

	public HRESULT put_MinRange(int32 lnMinRange) mut => VT.[Friend]put_MinRange(&this, lnMinRange);

	public HRESULT get_MultiValued(int16* retval) mut => VT.[Friend]get_MultiValued(&this, retval);

	public HRESULT put_MultiValued(int16 fMultiValued) mut => VT.[Friend]put_MultiValued(&this, fMultiValued);

	public HRESULT Qualifiers(IADsCollection** ppQualifiers) mut => VT.[Friend]Qualifiers(&this, ppQualifiers);
}

[CRepr]struct IADsSyntax : IADs
{
	public new const Guid IID = .(0xc8f93dd2, 0x4ae0, 0x11cf, 0x9e, 0x73, 0x00, 0xaa, 0x00, 0x4a, 0x56, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_OleAutoDataType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnOleAutoDataType) put_OleAutoDataType;
	}


	public HRESULT get_OleAutoDataType(int32* retval) mut => VT.[Friend]get_OleAutoDataType(&this, retval);

	public HRESULT put_OleAutoDataType(int32 lnOleAutoDataType) mut => VT.[Friend]put_OleAutoDataType(&this, lnOleAutoDataType);
}

[CRepr]struct IADsLocality : IADs
{
	public new const Guid IID = .(0xa05e03a2, 0xeffe, 0x11cf, 0x8a, 0xbc, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_LocalityName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLocalityName) put_LocalityName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPostalAddress) put_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_SeeAlso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vSeeAlso) put_SeeAlso;
	}


	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_LocalityName(BSTR* retval) mut => VT.[Friend]get_LocalityName(&this, retval);

	public HRESULT put_LocalityName(BSTR bstrLocalityName) mut => VT.[Friend]put_LocalityName(&this, bstrLocalityName);

	public HRESULT get_PostalAddress(BSTR* retval) mut => VT.[Friend]get_PostalAddress(&this, retval);

	public HRESULT put_PostalAddress(BSTR bstrPostalAddress) mut => VT.[Friend]put_PostalAddress(&this, bstrPostalAddress);

	public HRESULT get_SeeAlso(VARIANT* retval) mut => VT.[Friend]get_SeeAlso(&this, retval);

	public HRESULT put_SeeAlso(VARIANT vSeeAlso) mut => VT.[Friend]put_SeeAlso(&this, vSeeAlso);
}

[CRepr]struct IADsO : IADs
{
	public new const Guid IID = .(0xa1cd2dc6, 0xeffe, 0x11cf, 0x8a, 0xbc, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_LocalityName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLocalityName) put_LocalityName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPostalAddress) put_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTelephoneNumber) put_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxNumber) put_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_SeeAlso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vSeeAlso) put_SeeAlso;
	}


	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_LocalityName(BSTR* retval) mut => VT.[Friend]get_LocalityName(&this, retval);

	public HRESULT put_LocalityName(BSTR bstrLocalityName) mut => VT.[Friend]put_LocalityName(&this, bstrLocalityName);

	public HRESULT get_PostalAddress(BSTR* retval) mut => VT.[Friend]get_PostalAddress(&this, retval);

	public HRESULT put_PostalAddress(BSTR bstrPostalAddress) mut => VT.[Friend]put_PostalAddress(&this, bstrPostalAddress);

	public HRESULT get_TelephoneNumber(BSTR* retval) mut => VT.[Friend]get_TelephoneNumber(&this, retval);

	public HRESULT put_TelephoneNumber(BSTR bstrTelephoneNumber) mut => VT.[Friend]put_TelephoneNumber(&this, bstrTelephoneNumber);

	public HRESULT get_FaxNumber(BSTR* retval) mut => VT.[Friend]get_FaxNumber(&this, retval);

	public HRESULT put_FaxNumber(BSTR bstrFaxNumber) mut => VT.[Friend]put_FaxNumber(&this, bstrFaxNumber);

	public HRESULT get_SeeAlso(VARIANT* retval) mut => VT.[Friend]get_SeeAlso(&this, retval);

	public HRESULT put_SeeAlso(VARIANT vSeeAlso) mut => VT.[Friend]put_SeeAlso(&this, vSeeAlso);
}

[CRepr]struct IADsOU : IADs
{
	public new const Guid IID = .(0xa2f733b8, 0xeffe, 0x11cf, 0x8a, 0xbc, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_LocalityName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLocalityName) put_LocalityName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPostalAddress) put_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTelephoneNumber) put_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxNumber) put_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_SeeAlso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vSeeAlso) put_SeeAlso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_BusinessCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBusinessCategory) put_BusinessCategory;
	}


	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_LocalityName(BSTR* retval) mut => VT.[Friend]get_LocalityName(&this, retval);

	public HRESULT put_LocalityName(BSTR bstrLocalityName) mut => VT.[Friend]put_LocalityName(&this, bstrLocalityName);

	public HRESULT get_PostalAddress(BSTR* retval) mut => VT.[Friend]get_PostalAddress(&this, retval);

	public HRESULT put_PostalAddress(BSTR bstrPostalAddress) mut => VT.[Friend]put_PostalAddress(&this, bstrPostalAddress);

	public HRESULT get_TelephoneNumber(BSTR* retval) mut => VT.[Friend]get_TelephoneNumber(&this, retval);

	public HRESULT put_TelephoneNumber(BSTR bstrTelephoneNumber) mut => VT.[Friend]put_TelephoneNumber(&this, bstrTelephoneNumber);

	public HRESULT get_FaxNumber(BSTR* retval) mut => VT.[Friend]get_FaxNumber(&this, retval);

	public HRESULT put_FaxNumber(BSTR bstrFaxNumber) mut => VT.[Friend]put_FaxNumber(&this, bstrFaxNumber);

	public HRESULT get_SeeAlso(VARIANT* retval) mut => VT.[Friend]get_SeeAlso(&this, retval);

	public HRESULT put_SeeAlso(VARIANT vSeeAlso) mut => VT.[Friend]put_SeeAlso(&this, vSeeAlso);

	public HRESULT get_BusinessCategory(BSTR* retval) mut => VT.[Friend]get_BusinessCategory(&this, retval);

	public HRESULT put_BusinessCategory(BSTR bstrBusinessCategory) mut => VT.[Friend]put_BusinessCategory(&this, bstrBusinessCategory);
}

[CRepr]struct IADsDomain : IADs
{
	public new const Guid IID = .(0x00e4c220, 0xfd16, 0x11ce, 0xab, 0xc4, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_IsWorkgroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MinPasswordLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMinPasswordLength) put_MinPasswordLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MinPasswordAge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMinPasswordAge) put_MinPasswordAge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxPasswordAge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxPasswordAge) put_MaxPasswordAge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxBadPasswordsAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxBadPasswordsAllowed) put_MaxBadPasswordsAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_PasswordHistoryLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPasswordHistoryLength) put_PasswordHistoryLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_PasswordAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPasswordAttributes) put_PasswordAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AutoUnlockInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAutoUnlockInterval) put_AutoUnlockInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_LockoutObservationInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnLockoutObservationInterval) put_LockoutObservationInterval;
	}


	public HRESULT get_IsWorkgroup(int16* retval) mut => VT.[Friend]get_IsWorkgroup(&this, retval);

	public HRESULT get_MinPasswordLength(int32* retval) mut => VT.[Friend]get_MinPasswordLength(&this, retval);

	public HRESULT put_MinPasswordLength(int32 lnMinPasswordLength) mut => VT.[Friend]put_MinPasswordLength(&this, lnMinPasswordLength);

	public HRESULT get_MinPasswordAge(int32* retval) mut => VT.[Friend]get_MinPasswordAge(&this, retval);

	public HRESULT put_MinPasswordAge(int32 lnMinPasswordAge) mut => VT.[Friend]put_MinPasswordAge(&this, lnMinPasswordAge);

	public HRESULT get_MaxPasswordAge(int32* retval) mut => VT.[Friend]get_MaxPasswordAge(&this, retval);

	public HRESULT put_MaxPasswordAge(int32 lnMaxPasswordAge) mut => VT.[Friend]put_MaxPasswordAge(&this, lnMaxPasswordAge);

	public HRESULT get_MaxBadPasswordsAllowed(int32* retval) mut => VT.[Friend]get_MaxBadPasswordsAllowed(&this, retval);

	public HRESULT put_MaxBadPasswordsAllowed(int32 lnMaxBadPasswordsAllowed) mut => VT.[Friend]put_MaxBadPasswordsAllowed(&this, lnMaxBadPasswordsAllowed);

	public HRESULT get_PasswordHistoryLength(int32* retval) mut => VT.[Friend]get_PasswordHistoryLength(&this, retval);

	public HRESULT put_PasswordHistoryLength(int32 lnPasswordHistoryLength) mut => VT.[Friend]put_PasswordHistoryLength(&this, lnPasswordHistoryLength);

	public HRESULT get_PasswordAttributes(int32* retval) mut => VT.[Friend]get_PasswordAttributes(&this, retval);

	public HRESULT put_PasswordAttributes(int32 lnPasswordAttributes) mut => VT.[Friend]put_PasswordAttributes(&this, lnPasswordAttributes);

	public HRESULT get_AutoUnlockInterval(int32* retval) mut => VT.[Friend]get_AutoUnlockInterval(&this, retval);

	public HRESULT put_AutoUnlockInterval(int32 lnAutoUnlockInterval) mut => VT.[Friend]put_AutoUnlockInterval(&this, lnAutoUnlockInterval);

	public HRESULT get_LockoutObservationInterval(int32* retval) mut => VT.[Friend]get_LockoutObservationInterval(&this, retval);

	public HRESULT put_LockoutObservationInterval(int32 lnLockoutObservationInterval) mut => VT.[Friend]put_LockoutObservationInterval(&this, lnLockoutObservationInterval);
}

[CRepr]struct IADsComputer : IADs
{
	public new const Guid IID = .(0xefe3cc70, 0x1d9f, 0x11cf, 0xb1, 0xf3, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ComputerID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Site;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Location;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLocation) put_Location;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PrimaryUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPrimaryUser) put_PrimaryUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Owner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOwner) put_Owner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Division;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDivision) put_Division;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Department;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDepartment) put_Department;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Role;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRole) put_Role;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_OperatingSystem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOperatingSystem) put_OperatingSystem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_OperatingSystemVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOperatingSystemVersion) put_OperatingSystemVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Model;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrModel) put_Model;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Processor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProcessor) put_Processor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ProcessorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProcessorCount) put_ProcessorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_MemorySize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMemorySize) put_MemorySize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_StorageCapacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrStorageCapacity) put_StorageCapacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_NetAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vNetAddresses) put_NetAddresses;
	}


	public HRESULT get_ComputerID(BSTR* retval) mut => VT.[Friend]get_ComputerID(&this, retval);

	public HRESULT get_Site(BSTR* retval) mut => VT.[Friend]get_Site(&this, retval);

	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_Location(BSTR* retval) mut => VT.[Friend]get_Location(&this, retval);

	public HRESULT put_Location(BSTR bstrLocation) mut => VT.[Friend]put_Location(&this, bstrLocation);

	public HRESULT get_PrimaryUser(BSTR* retval) mut => VT.[Friend]get_PrimaryUser(&this, retval);

	public HRESULT put_PrimaryUser(BSTR bstrPrimaryUser) mut => VT.[Friend]put_PrimaryUser(&this, bstrPrimaryUser);

	public HRESULT get_Owner(BSTR* retval) mut => VT.[Friend]get_Owner(&this, retval);

	public HRESULT put_Owner(BSTR bstrOwner) mut => VT.[Friend]put_Owner(&this, bstrOwner);

	public HRESULT get_Division(BSTR* retval) mut => VT.[Friend]get_Division(&this, retval);

	public HRESULT put_Division(BSTR bstrDivision) mut => VT.[Friend]put_Division(&this, bstrDivision);

	public HRESULT get_Department(BSTR* retval) mut => VT.[Friend]get_Department(&this, retval);

	public HRESULT put_Department(BSTR bstrDepartment) mut => VT.[Friend]put_Department(&this, bstrDepartment);

	public HRESULT get_Role(BSTR* retval) mut => VT.[Friend]get_Role(&this, retval);

	public HRESULT put_Role(BSTR bstrRole) mut => VT.[Friend]put_Role(&this, bstrRole);

	public HRESULT get_OperatingSystem(BSTR* retval) mut => VT.[Friend]get_OperatingSystem(&this, retval);

	public HRESULT put_OperatingSystem(BSTR bstrOperatingSystem) mut => VT.[Friend]put_OperatingSystem(&this, bstrOperatingSystem);

	public HRESULT get_OperatingSystemVersion(BSTR* retval) mut => VT.[Friend]get_OperatingSystemVersion(&this, retval);

	public HRESULT put_OperatingSystemVersion(BSTR bstrOperatingSystemVersion) mut => VT.[Friend]put_OperatingSystemVersion(&this, bstrOperatingSystemVersion);

	public HRESULT get_Model(BSTR* retval) mut => VT.[Friend]get_Model(&this, retval);

	public HRESULT put_Model(BSTR bstrModel) mut => VT.[Friend]put_Model(&this, bstrModel);

	public HRESULT get_Processor(BSTR* retval) mut => VT.[Friend]get_Processor(&this, retval);

	public HRESULT put_Processor(BSTR bstrProcessor) mut => VT.[Friend]put_Processor(&this, bstrProcessor);

	public HRESULT get_ProcessorCount(BSTR* retval) mut => VT.[Friend]get_ProcessorCount(&this, retval);

	public HRESULT put_ProcessorCount(BSTR bstrProcessorCount) mut => VT.[Friend]put_ProcessorCount(&this, bstrProcessorCount);

	public HRESULT get_MemorySize(BSTR* retval) mut => VT.[Friend]get_MemorySize(&this, retval);

	public HRESULT put_MemorySize(BSTR bstrMemorySize) mut => VT.[Friend]put_MemorySize(&this, bstrMemorySize);

	public HRESULT get_StorageCapacity(BSTR* retval) mut => VT.[Friend]get_StorageCapacity(&this, retval);

	public HRESULT put_StorageCapacity(BSTR bstrStorageCapacity) mut => VT.[Friend]put_StorageCapacity(&this, bstrStorageCapacity);

	public HRESULT get_NetAddresses(VARIANT* retval) mut => VT.[Friend]get_NetAddresses(&this, retval);

	public HRESULT put_NetAddresses(VARIANT vNetAddresses) mut => VT.[Friend]put_NetAddresses(&this, vNetAddresses);
}

[CRepr]struct IADsComputerOperations : IADs
{
	public new const Guid IID = .(0xef497680, 0x1d9f, 0x11cf, 0xb1, 0xf3, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppObject) Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bReboot) Shutdown;
	}


	public HRESULT Status(IDispatch** ppObject) mut => VT.[Friend]Status(&this, ppObject);

	public HRESULT Shutdown(int16 bReboot) mut => VT.[Friend]Shutdown(&this, bReboot);
}

[CRepr]struct IADsGroup : IADs
{
	public new const Guid IID = .(0x27636b00, 0x410f, 0x11cf, 0xb1, 0xff, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsMembers** ppMembers) Members;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMember, int16* bMember) IsMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNewItem) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemToBeRemoved) Remove;
	}


	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT Members(IADsMembers** ppMembers) mut => VT.[Friend]Members(&this, ppMembers);

	public HRESULT IsMember(BSTR bstrMember, int16* bMember) mut => VT.[Friend]IsMember(&this, bstrMember, bMember);

	public HRESULT Add(BSTR bstrNewItem) mut => VT.[Friend]Add(&this, bstrNewItem);

	public HRESULT Remove(BSTR bstrItemToBeRemoved) mut => VT.[Friend]Remove(&this, bstrItemToBeRemoved);
}

[CRepr]struct IADsUser : IADs
{
	public new const Guid IID = .(0x3e37e320, 0x17e2, 0x11cf, 0xab, 0xc4, 0x02, 0x60, 0x8c, 0x9e, 0x75, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_BadLoginAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_BadLoginCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_LastLogin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_LastLogoff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_LastFailedLogin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_PasswordLastChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Division;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDivision) put_Division;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Department;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDepartment) put_Department;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_EmployeeID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEmployeeID) put_EmployeeID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_FullName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFullName) put_FullName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_FirstName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFirstName) put_FirstName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_LastName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLastName) put_LastName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_OtherName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOtherName) put_OtherName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_NamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNamePrefix) put_NamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_NameSuffix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNameSuffix) put_NameSuffix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTitle) put_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Manager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrManager) put_Manager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_TelephoneHome;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vTelephoneHome) put_TelephoneHome;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_TelephoneMobile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vTelephoneMobile) put_TelephoneMobile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vTelephoneNumber) put_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_TelephonePager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vTelephonePager) put_TelephonePager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vFaxNumber) put_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_OfficeLocations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vOfficeLocations) put_OfficeLocations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_PostalAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vPostalAddresses) put_PostalAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_PostalCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vPostalCodes) put_PostalCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_SeeAlso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vSeeAlso) put_SeeAlso;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_AccountDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fAccountDisabled) put_AccountDisabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_AccountExpirationDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daAccountExpirationDate) put_AccountExpirationDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_GraceLoginsAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnGraceLoginsAllowed) put_GraceLoginsAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_GraceLoginsRemaining;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnGraceLoginsRemaining) put_GraceLoginsRemaining;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_IsAccountLocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fIsAccountLocked) put_IsAccountLocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_LoginHours;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vLoginHours) put_LoginHours;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_LoginWorkstations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vLoginWorkstations) put_LoginWorkstations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxLogins;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxLogins) put_MaxLogins;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxStorage) put_MaxStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_PasswordExpirationDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daPasswordExpirationDate) put_PasswordExpirationDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_PasswordMinimumLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPasswordMinimumLength) put_PasswordMinimumLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_PasswordRequired;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fPasswordRequired) put_PasswordRequired;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_RequireUniquePassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fRequireUniquePassword) put_RequireUniquePassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_EmailAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEmailAddress) put_EmailAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_HomeDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHomeDirectory) put_HomeDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Languages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vLanguages) put_Languages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Profile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProfile) put_Profile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_LoginScript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLoginScript) put_LoginScript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Picture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vPicture) put_Picture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_HomePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHomePage) put_HomePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsMembers** ppGroups) Groups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR NewPassword) SetPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOldPassword, BSTR bstrNewPassword) ChangePassword;
	}


	public HRESULT get_BadLoginAddress(BSTR* retval) mut => VT.[Friend]get_BadLoginAddress(&this, retval);

	public HRESULT get_BadLoginCount(int32* retval) mut => VT.[Friend]get_BadLoginCount(&this, retval);

	public HRESULT get_LastLogin(double* retval) mut => VT.[Friend]get_LastLogin(&this, retval);

	public HRESULT get_LastLogoff(double* retval) mut => VT.[Friend]get_LastLogoff(&this, retval);

	public HRESULT get_LastFailedLogin(double* retval) mut => VT.[Friend]get_LastFailedLogin(&this, retval);

	public HRESULT get_PasswordLastChanged(double* retval) mut => VT.[Friend]get_PasswordLastChanged(&this, retval);

	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_Division(BSTR* retval) mut => VT.[Friend]get_Division(&this, retval);

	public HRESULT put_Division(BSTR bstrDivision) mut => VT.[Friend]put_Division(&this, bstrDivision);

	public HRESULT get_Department(BSTR* retval) mut => VT.[Friend]get_Department(&this, retval);

	public HRESULT put_Department(BSTR bstrDepartment) mut => VT.[Friend]put_Department(&this, bstrDepartment);

	public HRESULT get_EmployeeID(BSTR* retval) mut => VT.[Friend]get_EmployeeID(&this, retval);

	public HRESULT put_EmployeeID(BSTR bstrEmployeeID) mut => VT.[Friend]put_EmployeeID(&this, bstrEmployeeID);

	public HRESULT get_FullName(BSTR* retval) mut => VT.[Friend]get_FullName(&this, retval);

	public HRESULT put_FullName(BSTR bstrFullName) mut => VT.[Friend]put_FullName(&this, bstrFullName);

	public HRESULT get_FirstName(BSTR* retval) mut => VT.[Friend]get_FirstName(&this, retval);

	public HRESULT put_FirstName(BSTR bstrFirstName) mut => VT.[Friend]put_FirstName(&this, bstrFirstName);

	public HRESULT get_LastName(BSTR* retval) mut => VT.[Friend]get_LastName(&this, retval);

	public HRESULT put_LastName(BSTR bstrLastName) mut => VT.[Friend]put_LastName(&this, bstrLastName);

	public HRESULT get_OtherName(BSTR* retval) mut => VT.[Friend]get_OtherName(&this, retval);

	public HRESULT put_OtherName(BSTR bstrOtherName) mut => VT.[Friend]put_OtherName(&this, bstrOtherName);

	public HRESULT get_NamePrefix(BSTR* retval) mut => VT.[Friend]get_NamePrefix(&this, retval);

	public HRESULT put_NamePrefix(BSTR bstrNamePrefix) mut => VT.[Friend]put_NamePrefix(&this, bstrNamePrefix);

	public HRESULT get_NameSuffix(BSTR* retval) mut => VT.[Friend]get_NameSuffix(&this, retval);

	public HRESULT put_NameSuffix(BSTR bstrNameSuffix) mut => VT.[Friend]put_NameSuffix(&this, bstrNameSuffix);

	public HRESULT get_Title(BSTR* retval) mut => VT.[Friend]get_Title(&this, retval);

	public HRESULT put_Title(BSTR bstrTitle) mut => VT.[Friend]put_Title(&this, bstrTitle);

	public HRESULT get_Manager(BSTR* retval) mut => VT.[Friend]get_Manager(&this, retval);

	public HRESULT put_Manager(BSTR bstrManager) mut => VT.[Friend]put_Manager(&this, bstrManager);

	public HRESULT get_TelephoneHome(VARIANT* retval) mut => VT.[Friend]get_TelephoneHome(&this, retval);

	public HRESULT put_TelephoneHome(VARIANT vTelephoneHome) mut => VT.[Friend]put_TelephoneHome(&this, vTelephoneHome);

	public HRESULT get_TelephoneMobile(VARIANT* retval) mut => VT.[Friend]get_TelephoneMobile(&this, retval);

	public HRESULT put_TelephoneMobile(VARIANT vTelephoneMobile) mut => VT.[Friend]put_TelephoneMobile(&this, vTelephoneMobile);

	public HRESULT get_TelephoneNumber(VARIANT* retval) mut => VT.[Friend]get_TelephoneNumber(&this, retval);

	public HRESULT put_TelephoneNumber(VARIANT vTelephoneNumber) mut => VT.[Friend]put_TelephoneNumber(&this, vTelephoneNumber);

	public HRESULT get_TelephonePager(VARIANT* retval) mut => VT.[Friend]get_TelephonePager(&this, retval);

	public HRESULT put_TelephonePager(VARIANT vTelephonePager) mut => VT.[Friend]put_TelephonePager(&this, vTelephonePager);

	public HRESULT get_FaxNumber(VARIANT* retval) mut => VT.[Friend]get_FaxNumber(&this, retval);

	public HRESULT put_FaxNumber(VARIANT vFaxNumber) mut => VT.[Friend]put_FaxNumber(&this, vFaxNumber);

	public HRESULT get_OfficeLocations(VARIANT* retval) mut => VT.[Friend]get_OfficeLocations(&this, retval);

	public HRESULT put_OfficeLocations(VARIANT vOfficeLocations) mut => VT.[Friend]put_OfficeLocations(&this, vOfficeLocations);

	public HRESULT get_PostalAddresses(VARIANT* retval) mut => VT.[Friend]get_PostalAddresses(&this, retval);

	public HRESULT put_PostalAddresses(VARIANT vPostalAddresses) mut => VT.[Friend]put_PostalAddresses(&this, vPostalAddresses);

	public HRESULT get_PostalCodes(VARIANT* retval) mut => VT.[Friend]get_PostalCodes(&this, retval);

	public HRESULT put_PostalCodes(VARIANT vPostalCodes) mut => VT.[Friend]put_PostalCodes(&this, vPostalCodes);

	public HRESULT get_SeeAlso(VARIANT* retval) mut => VT.[Friend]get_SeeAlso(&this, retval);

	public HRESULT put_SeeAlso(VARIANT vSeeAlso) mut => VT.[Friend]put_SeeAlso(&this, vSeeAlso);

	public HRESULT get_AccountDisabled(int16* retval) mut => VT.[Friend]get_AccountDisabled(&this, retval);

	public HRESULT put_AccountDisabled(int16 fAccountDisabled) mut => VT.[Friend]put_AccountDisabled(&this, fAccountDisabled);

	public HRESULT get_AccountExpirationDate(double* retval) mut => VT.[Friend]get_AccountExpirationDate(&this, retval);

	public HRESULT put_AccountExpirationDate(double daAccountExpirationDate) mut => VT.[Friend]put_AccountExpirationDate(&this, daAccountExpirationDate);

	public HRESULT get_GraceLoginsAllowed(int32* retval) mut => VT.[Friend]get_GraceLoginsAllowed(&this, retval);

	public HRESULT put_GraceLoginsAllowed(int32 lnGraceLoginsAllowed) mut => VT.[Friend]put_GraceLoginsAllowed(&this, lnGraceLoginsAllowed);

	public HRESULT get_GraceLoginsRemaining(int32* retval) mut => VT.[Friend]get_GraceLoginsRemaining(&this, retval);

	public HRESULT put_GraceLoginsRemaining(int32 lnGraceLoginsRemaining) mut => VT.[Friend]put_GraceLoginsRemaining(&this, lnGraceLoginsRemaining);

	public HRESULT get_IsAccountLocked(int16* retval) mut => VT.[Friend]get_IsAccountLocked(&this, retval);

	public HRESULT put_IsAccountLocked(int16 fIsAccountLocked) mut => VT.[Friend]put_IsAccountLocked(&this, fIsAccountLocked);

	public HRESULT get_LoginHours(VARIANT* retval) mut => VT.[Friend]get_LoginHours(&this, retval);

	public HRESULT put_LoginHours(VARIANT vLoginHours) mut => VT.[Friend]put_LoginHours(&this, vLoginHours);

	public HRESULT get_LoginWorkstations(VARIANT* retval) mut => VT.[Friend]get_LoginWorkstations(&this, retval);

	public HRESULT put_LoginWorkstations(VARIANT vLoginWorkstations) mut => VT.[Friend]put_LoginWorkstations(&this, vLoginWorkstations);

	public HRESULT get_MaxLogins(int32* retval) mut => VT.[Friend]get_MaxLogins(&this, retval);

	public HRESULT put_MaxLogins(int32 lnMaxLogins) mut => VT.[Friend]put_MaxLogins(&this, lnMaxLogins);

	public HRESULT get_MaxStorage(int32* retval) mut => VT.[Friend]get_MaxStorage(&this, retval);

	public HRESULT put_MaxStorage(int32 lnMaxStorage) mut => VT.[Friend]put_MaxStorage(&this, lnMaxStorage);

	public HRESULT get_PasswordExpirationDate(double* retval) mut => VT.[Friend]get_PasswordExpirationDate(&this, retval);

	public HRESULT put_PasswordExpirationDate(double daPasswordExpirationDate) mut => VT.[Friend]put_PasswordExpirationDate(&this, daPasswordExpirationDate);

	public HRESULT get_PasswordMinimumLength(int32* retval) mut => VT.[Friend]get_PasswordMinimumLength(&this, retval);

	public HRESULT put_PasswordMinimumLength(int32 lnPasswordMinimumLength) mut => VT.[Friend]put_PasswordMinimumLength(&this, lnPasswordMinimumLength);

	public HRESULT get_PasswordRequired(int16* retval) mut => VT.[Friend]get_PasswordRequired(&this, retval);

	public HRESULT put_PasswordRequired(int16 fPasswordRequired) mut => VT.[Friend]put_PasswordRequired(&this, fPasswordRequired);

	public HRESULT get_RequireUniquePassword(int16* retval) mut => VT.[Friend]get_RequireUniquePassword(&this, retval);

	public HRESULT put_RequireUniquePassword(int16 fRequireUniquePassword) mut => VT.[Friend]put_RequireUniquePassword(&this, fRequireUniquePassword);

	public HRESULT get_EmailAddress(BSTR* retval) mut => VT.[Friend]get_EmailAddress(&this, retval);

	public HRESULT put_EmailAddress(BSTR bstrEmailAddress) mut => VT.[Friend]put_EmailAddress(&this, bstrEmailAddress);

	public HRESULT get_HomeDirectory(BSTR* retval) mut => VT.[Friend]get_HomeDirectory(&this, retval);

	public HRESULT put_HomeDirectory(BSTR bstrHomeDirectory) mut => VT.[Friend]put_HomeDirectory(&this, bstrHomeDirectory);

	public HRESULT get_Languages(VARIANT* retval) mut => VT.[Friend]get_Languages(&this, retval);

	public HRESULT put_Languages(VARIANT vLanguages) mut => VT.[Friend]put_Languages(&this, vLanguages);

	public HRESULT get_Profile(BSTR* retval) mut => VT.[Friend]get_Profile(&this, retval);

	public HRESULT put_Profile(BSTR bstrProfile) mut => VT.[Friend]put_Profile(&this, bstrProfile);

	public HRESULT get_LoginScript(BSTR* retval) mut => VT.[Friend]get_LoginScript(&this, retval);

	public HRESULT put_LoginScript(BSTR bstrLoginScript) mut => VT.[Friend]put_LoginScript(&this, bstrLoginScript);

	public HRESULT get_Picture(VARIANT* retval) mut => VT.[Friend]get_Picture(&this, retval);

	public HRESULT put_Picture(VARIANT vPicture) mut => VT.[Friend]put_Picture(&this, vPicture);

	public HRESULT get_HomePage(BSTR* retval) mut => VT.[Friend]get_HomePage(&this, retval);

	public HRESULT put_HomePage(BSTR bstrHomePage) mut => VT.[Friend]put_HomePage(&this, bstrHomePage);

	public HRESULT Groups(IADsMembers** ppGroups) mut => VT.[Friend]Groups(&this, ppGroups);

	public HRESULT SetPassword(BSTR NewPassword) mut => VT.[Friend]SetPassword(&this, NewPassword);

	public HRESULT ChangePassword(BSTR bstrOldPassword, BSTR bstrNewPassword) mut => VT.[Friend]ChangePassword(&this, bstrOldPassword, bstrNewPassword);
}

[CRepr]struct IADsPrintQueue : IADs
{
	public new const Guid IID = .(0xb15160d0, 0x1226, 0x11cf, 0xa9, 0x85, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PrinterPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPrinterPath) put_PrinterPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Model;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrModel) put_Model;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Datatype;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDatatype) put_Datatype;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PrintProcessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPrintProcessor) put_PrintProcessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Location;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLocation) put_Location;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daStartTime) put_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_UntilTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daUntilTime) put_UntilTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_DefaultJobPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnDefaultJobPriority) put_DefaultJobPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_BannerPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBannerPage) put_BannerPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_PrintDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vPrintDevices) put_PrintDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_NetAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vNetAddresses) put_NetAddresses;
	}


	public HRESULT get_PrinterPath(BSTR* retval) mut => VT.[Friend]get_PrinterPath(&this, retval);

	public HRESULT put_PrinterPath(BSTR bstrPrinterPath) mut => VT.[Friend]put_PrinterPath(&this, bstrPrinterPath);

	public HRESULT get_Model(BSTR* retval) mut => VT.[Friend]get_Model(&this, retval);

	public HRESULT put_Model(BSTR bstrModel) mut => VT.[Friend]put_Model(&this, bstrModel);

	public HRESULT get_Datatype(BSTR* retval) mut => VT.[Friend]get_Datatype(&this, retval);

	public HRESULT put_Datatype(BSTR bstrDatatype) mut => VT.[Friend]put_Datatype(&this, bstrDatatype);

	public HRESULT get_PrintProcessor(BSTR* retval) mut => VT.[Friend]get_PrintProcessor(&this, retval);

	public HRESULT put_PrintProcessor(BSTR bstrPrintProcessor) mut => VT.[Friend]put_PrintProcessor(&this, bstrPrintProcessor);

	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_Location(BSTR* retval) mut => VT.[Friend]get_Location(&this, retval);

	public HRESULT put_Location(BSTR bstrLocation) mut => VT.[Friend]put_Location(&this, bstrLocation);

	public HRESULT get_StartTime(double* retval) mut => VT.[Friend]get_StartTime(&this, retval);

	public HRESULT put_StartTime(double daStartTime) mut => VT.[Friend]put_StartTime(&this, daStartTime);

	public HRESULT get_UntilTime(double* retval) mut => VT.[Friend]get_UntilTime(&this, retval);

	public HRESULT put_UntilTime(double daUntilTime) mut => VT.[Friend]put_UntilTime(&this, daUntilTime);

	public HRESULT get_DefaultJobPriority(int32* retval) mut => VT.[Friend]get_DefaultJobPriority(&this, retval);

	public HRESULT put_DefaultJobPriority(int32 lnDefaultJobPriority) mut => VT.[Friend]put_DefaultJobPriority(&this, lnDefaultJobPriority);

	public HRESULT get_Priority(int32* retval) mut => VT.[Friend]get_Priority(&this, retval);

	public HRESULT put_Priority(int32 lnPriority) mut => VT.[Friend]put_Priority(&this, lnPriority);

	public HRESULT get_BannerPage(BSTR* retval) mut => VT.[Friend]get_BannerPage(&this, retval);

	public HRESULT put_BannerPage(BSTR bstrBannerPage) mut => VT.[Friend]put_BannerPage(&this, bstrBannerPage);

	public HRESULT get_PrintDevices(VARIANT* retval) mut => VT.[Friend]get_PrintDevices(&this, retval);

	public HRESULT put_PrintDevices(VARIANT vPrintDevices) mut => VT.[Friend]put_PrintDevices(&this, vPrintDevices);

	public HRESULT get_NetAddresses(VARIANT* retval) mut => VT.[Friend]get_NetAddresses(&this, retval);

	public HRESULT put_NetAddresses(VARIANT vNetAddresses) mut => VT.[Friend]put_NetAddresses(&this, vNetAddresses);
}

[CRepr]struct IADsPrintQueueOperations : IADs
{
	public new const Guid IID = .(0x124be5c0, 0x156e, 0x11cf, 0xa9, 0x86, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsCollection** pObject) PrintJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Purge;
	}


	public HRESULT get_Status(int32* retval) mut => VT.[Friend]get_Status(&this, retval);

	public HRESULT PrintJobs(IADsCollection** pObject) mut => VT.[Friend]PrintJobs(&this, pObject);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Purge() mut => VT.[Friend]Purge(&this);
}

[CRepr]struct IADsPrintJob : IADs
{
	public new const Guid IID = .(0x32fb6780, 0x1ed0, 0x11cf, 0xa9, 0x88, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_HostPrintQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_User;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_UserPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_TimeSubmitted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_TotalPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daStartTime) put_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* retval) get_UntilTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double daUntilTime) put_UntilTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNotify) put_Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_NotifyPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNotifyPath) put_NotifyPath;
	}


	public HRESULT get_HostPrintQueue(BSTR* retval) mut => VT.[Friend]get_HostPrintQueue(&this, retval);

	public HRESULT get_User(BSTR* retval) mut => VT.[Friend]get_User(&this, retval);

	public HRESULT get_UserPath(BSTR* retval) mut => VT.[Friend]get_UserPath(&this, retval);

	public HRESULT get_TimeSubmitted(double* retval) mut => VT.[Friend]get_TimeSubmitted(&this, retval);

	public HRESULT get_TotalPages(int32* retval) mut => VT.[Friend]get_TotalPages(&this, retval);

	public HRESULT get_Size(int32* retval) mut => VT.[Friend]get_Size(&this, retval);

	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_Priority(int32* retval) mut => VT.[Friend]get_Priority(&this, retval);

	public HRESULT put_Priority(int32 lnPriority) mut => VT.[Friend]put_Priority(&this, lnPriority);

	public HRESULT get_StartTime(double* retval) mut => VT.[Friend]get_StartTime(&this, retval);

	public HRESULT put_StartTime(double daStartTime) mut => VT.[Friend]put_StartTime(&this, daStartTime);

	public HRESULT get_UntilTime(double* retval) mut => VT.[Friend]get_UntilTime(&this, retval);

	public HRESULT put_UntilTime(double daUntilTime) mut => VT.[Friend]put_UntilTime(&this, daUntilTime);

	public HRESULT get_Notify(BSTR* retval) mut => VT.[Friend]get_Notify(&this, retval);

	public HRESULT put_Notify(BSTR bstrNotify) mut => VT.[Friend]put_Notify(&this, bstrNotify);

	public HRESULT get_NotifyPath(BSTR* retval) mut => VT.[Friend]get_NotifyPath(&this, retval);

	public HRESULT put_NotifyPath(BSTR bstrNotifyPath) mut => VT.[Friend]put_NotifyPath(&this, bstrNotifyPath);
}

[CRepr]struct IADsPrintJobOperations : IADs
{
	public new const Guid IID = .(0x9a52db30, 0x1ecf, 0x11cf, 0xa9, 0x88, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_TimeElapsed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_PagesPrinted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Position;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPosition) put_Position;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
	}


	public HRESULT get_Status(int32* retval) mut => VT.[Friend]get_Status(&this, retval);

	public HRESULT get_TimeElapsed(int32* retval) mut => VT.[Friend]get_TimeElapsed(&this, retval);

	public HRESULT get_PagesPrinted(int32* retval) mut => VT.[Friend]get_PagesPrinted(&this, retval);

	public HRESULT get_Position(int32* retval) mut => VT.[Friend]get_Position(&this, retval);

	public HRESULT put_Position(int32 lnPosition) mut => VT.[Friend]put_Position(&this, lnPosition);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);
}

[CRepr]struct IADsService : IADs
{
	public new const Guid IID = .(0x68af66e0, 0x31ca, 0x11cf, 0xa9, 0x8a, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_HostComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHostComputer) put_HostComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDisplayName) put_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVersion) put_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ServiceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnServiceType) put_ServiceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_StartType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnStartType) put_StartType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPath) put_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_StartupParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrStartupParameters) put_StartupParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ErrorControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnErrorControl) put_ErrorControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_LoadOrderGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLoadOrderGroup) put_LoadOrderGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ServiceAccountName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServiceAccountName) put_ServiceAccountName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ServiceAccountPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServiceAccountPath) put_ServiceAccountPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Dependencies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDependencies) put_Dependencies;
	}


	public HRESULT get_HostComputer(BSTR* retval) mut => VT.[Friend]get_HostComputer(&this, retval);

	public HRESULT put_HostComputer(BSTR bstrHostComputer) mut => VT.[Friend]put_HostComputer(&this, bstrHostComputer);

	public HRESULT get_DisplayName(BSTR* retval) mut => VT.[Friend]get_DisplayName(&this, retval);

	public HRESULT put_DisplayName(BSTR bstrDisplayName) mut => VT.[Friend]put_DisplayName(&this, bstrDisplayName);

	public HRESULT get_Version(BSTR* retval) mut => VT.[Friend]get_Version(&this, retval);

	public HRESULT put_Version(BSTR bstrVersion) mut => VT.[Friend]put_Version(&this, bstrVersion);

	public HRESULT get_ServiceType(int32* retval) mut => VT.[Friend]get_ServiceType(&this, retval);

	public HRESULT put_ServiceType(int32 lnServiceType) mut => VT.[Friend]put_ServiceType(&this, lnServiceType);

	public HRESULT get_StartType(int32* retval) mut => VT.[Friend]get_StartType(&this, retval);

	public HRESULT put_StartType(int32 lnStartType) mut => VT.[Friend]put_StartType(&this, lnStartType);

	public HRESULT get_Path(BSTR* retval) mut => VT.[Friend]get_Path(&this, retval);

	public HRESULT put_Path(BSTR bstrPath) mut => VT.[Friend]put_Path(&this, bstrPath);

	public HRESULT get_StartupParameters(BSTR* retval) mut => VT.[Friend]get_StartupParameters(&this, retval);

	public HRESULT put_StartupParameters(BSTR bstrStartupParameters) mut => VT.[Friend]put_StartupParameters(&this, bstrStartupParameters);

	public HRESULT get_ErrorControl(int32* retval) mut => VT.[Friend]get_ErrorControl(&this, retval);

	public HRESULT put_ErrorControl(int32 lnErrorControl) mut => VT.[Friend]put_ErrorControl(&this, lnErrorControl);

	public HRESULT get_LoadOrderGroup(BSTR* retval) mut => VT.[Friend]get_LoadOrderGroup(&this, retval);

	public HRESULT put_LoadOrderGroup(BSTR bstrLoadOrderGroup) mut => VT.[Friend]put_LoadOrderGroup(&this, bstrLoadOrderGroup);

	public HRESULT get_ServiceAccountName(BSTR* retval) mut => VT.[Friend]get_ServiceAccountName(&this, retval);

	public HRESULT put_ServiceAccountName(BSTR bstrServiceAccountName) mut => VT.[Friend]put_ServiceAccountName(&this, bstrServiceAccountName);

	public HRESULT get_ServiceAccountPath(BSTR* retval) mut => VT.[Friend]get_ServiceAccountPath(&this, retval);

	public HRESULT put_ServiceAccountPath(BSTR bstrServiceAccountPath) mut => VT.[Friend]put_ServiceAccountPath(&this, bstrServiceAccountPath);

	public HRESULT get_Dependencies(VARIANT* retval) mut => VT.[Friend]get_Dependencies(&this, retval);

	public HRESULT put_Dependencies(VARIANT vDependencies) mut => VT.[Friend]put_Dependencies(&this, vDependencies);
}

[CRepr]struct IADsServiceOperations : IADs
{
	public new const Guid IID = .(0x5d7b33f0, 0x31ca, 0x11cf, 0xa9, 0x8a, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Continue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNewPassword) SetPassword;
	}


	public HRESULT get_Status(int32* retval) mut => VT.[Friend]get_Status(&this, retval);

	public HRESULT Start() mut => VT.[Friend]Start(&this);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Continue() mut => VT.[Friend]Continue(&this);

	public HRESULT SetPassword(BSTR bstrNewPassword) mut => VT.[Friend]SetPassword(&this, bstrNewPassword);
}

[CRepr]struct IADsFileService : IADsService
{
	public new const Guid IID = .(0xa89d1900, 0x31ca, 0x11cf, 0xa9, 0x8a, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADsService.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxUserCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxUserCount) put_MaxUserCount;
	}


	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_MaxUserCount(int32* retval) mut => VT.[Friend]get_MaxUserCount(&this, retval);

	public HRESULT put_MaxUserCount(int32 lnMaxUserCount) mut => VT.[Friend]put_MaxUserCount(&this, lnMaxUserCount);
}

[CRepr]struct IADsFileServiceOperations : IADsServiceOperations
{
	public new const Guid IID = .(0xa02ded10, 0x31ca, 0x11cf, 0xa9, 0x8a, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADsServiceOperations.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsCollection** ppSessions) Sessions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsCollection** ppResources) Resources;
	}


	public HRESULT Sessions(IADsCollection** ppSessions) mut => VT.[Friend]Sessions(&this, ppSessions);

	public HRESULT Resources(IADsCollection** ppResources) mut => VT.[Friend]Resources(&this, ppResources);
}

[CRepr]struct IADsFileShare : IADs
{
	public new const Guid IID = .(0xeb6dcaf0, 0x4b83, 0x11cf, 0xa9, 0x95, 0x00, 0xaa, 0x00, 0x6b, 0xc1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_CurrentUserCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_HostComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHostComputer) put_HostComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPath) put_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MaxUserCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnMaxUserCount) put_MaxUserCount;
	}


	public HRESULT get_CurrentUserCount(int32* retval) mut => VT.[Friend]get_CurrentUserCount(&this, retval);

	public HRESULT get_Description(BSTR* retval) mut => VT.[Friend]get_Description(&this, retval);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_HostComputer(BSTR* retval) mut => VT.[Friend]get_HostComputer(&this, retval);

	public HRESULT put_HostComputer(BSTR bstrHostComputer) mut => VT.[Friend]put_HostComputer(&this, bstrHostComputer);

	public HRESULT get_Path(BSTR* retval) mut => VT.[Friend]get_Path(&this, retval);

	public HRESULT put_Path(BSTR bstrPath) mut => VT.[Friend]put_Path(&this, bstrPath);

	public HRESULT get_MaxUserCount(int32* retval) mut => VT.[Friend]get_MaxUserCount(&this, retval);

	public HRESULT put_MaxUserCount(int32 lnMaxUserCount) mut => VT.[Friend]put_MaxUserCount(&this, lnMaxUserCount);
}

[CRepr]struct IADsSession : IADs
{
	public new const Guid IID = .(0x398b7da0, 0x4aab, 0x11cf, 0xae, 0x2c, 0x00, 0xaa, 0x00, 0x6e, 0xbf, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_User;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_UserPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Computer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ComputerPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ConnectTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_IdleTime;
	}


	public HRESULT get_User(BSTR* retval) mut => VT.[Friend]get_User(&this, retval);

	public HRESULT get_UserPath(BSTR* retval) mut => VT.[Friend]get_UserPath(&this, retval);

	public HRESULT get_Computer(BSTR* retval) mut => VT.[Friend]get_Computer(&this, retval);

	public HRESULT get_ComputerPath(BSTR* retval) mut => VT.[Friend]get_ComputerPath(&this, retval);

	public HRESULT get_ConnectTime(int32* retval) mut => VT.[Friend]get_ConnectTime(&this, retval);

	public HRESULT get_IdleTime(int32* retval) mut => VT.[Friend]get_IdleTime(&this, retval);
}

[CRepr]struct IADsResource : IADs
{
	public new const Guid IID = .(0x34a05b20, 0x4aab, 0x11cf, 0xae, 0x2c, 0x00, 0xaa, 0x00, 0x6e, 0xbf, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IADs.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_User;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_UserPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_LockCount;
	}


	public HRESULT get_User(BSTR* retval) mut => VT.[Friend]get_User(&this, retval);

	public HRESULT get_UserPath(BSTR* retval) mut => VT.[Friend]get_UserPath(&this, retval);

	public HRESULT get_Path(BSTR* retval) mut => VT.[Friend]get_Path(&this, retval);

	public HRESULT get_LockCount(int32* retval) mut => VT.[Friend]get_LockCount(&this, retval);
}

[CRepr]struct IADsOpenDSObject : IDispatch
{
	public new const Guid IID = .(0xddf2891e, 0x0f9c, 0x11d0, 0x8a, 0xd4, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR lpszDNName, BSTR lpszUserName, BSTR lpszPassword, int32 lnReserved, IDispatch** ppOleDsObj) OpenDSObject;
	}


	public HRESULT OpenDSObject(BSTR lpszDNName, BSTR lpszUserName, BSTR lpszPassword, int32 lnReserved, IDispatch** ppOleDsObj) mut => VT.[Friend]OpenDSObject(&this, lpszDNName, lpszUserName, lpszPassword, lnReserved, ppOleDsObj);
}

[CRepr]struct IDirectoryObject : IUnknown
{
	public new const Guid IID = .(0xe798de2c, 0x22e4, 0x11d0, 0x84, 0xfe, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_OBJECT_INFO** ppObjInfo) GetObjectInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pAttributeNames, uint32 dwNumberAttributes, ADS_ATTR_INFO** ppAttributeEntries, uint32* pdwNumAttributesReturned) GetObjectAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_ATTR_INFO* pAttributeEntries, uint32 dwNumAttributes, uint32* pdwNumAttributesModified) SetObjectAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRDNName, ADS_ATTR_INFO* pAttributeEntries, uint32 dwNumAttributes, IDispatch** ppObject) CreateDSObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRDNName) DeleteDSObject;
	}


	public HRESULT GetObjectInformation(ADS_OBJECT_INFO** ppObjInfo) mut => VT.[Friend]GetObjectInformation(&this, ppObjInfo);

	public HRESULT GetObjectAttributes(PWSTR* pAttributeNames, uint32 dwNumberAttributes, ADS_ATTR_INFO** ppAttributeEntries, uint32* pdwNumAttributesReturned) mut => VT.[Friend]GetObjectAttributes(&this, pAttributeNames, dwNumberAttributes, ppAttributeEntries, pdwNumAttributesReturned);

	public HRESULT SetObjectAttributes(ADS_ATTR_INFO* pAttributeEntries, uint32 dwNumAttributes, uint32* pdwNumAttributesModified) mut => VT.[Friend]SetObjectAttributes(&this, pAttributeEntries, dwNumAttributes, pdwNumAttributesModified);

	public HRESULT CreateDSObject(PWSTR pszRDNName, ADS_ATTR_INFO* pAttributeEntries, uint32 dwNumAttributes, IDispatch** ppObject) mut => VT.[Friend]CreateDSObject(&this, pszRDNName, pAttributeEntries, dwNumAttributes, ppObject);

	public HRESULT DeleteDSObject(PWSTR pszRDNName) mut => VT.[Friend]DeleteDSObject(&this, pszRDNName);
}

[CRepr]struct IDirectorySearch : IUnknown
{
	public new const Guid IID = .(0x109ba8ec, 0x92f0, 0x11d0, 0xa7, 0x90, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCHPREF_INFO* pSearchPrefs, uint32 dwNumPrefs) SetSearchPreference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSearchFilter, PWSTR* pAttributeNames, uint32 dwNumberAttributes, ADS_SEARCH_HANDLE* phSearchResult) ExecuteSearch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE phSearchResult) AbandonSearch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE hSearchResult) GetFirstRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE hSearchResult) GetNextRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE hSearchResult) GetPreviousRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE hSearchHandle, PWSTR* ppszColumnName) GetNextColumnName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE hSearchResult, PWSTR szColumnName, ADS_SEARCH_COLUMN* pSearchColumn) GetColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_COLUMN* pSearchColumn) FreeColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADS_SEARCH_HANDLE hSearchResult) CloseSearchHandle;
	}


	public HRESULT SetSearchPreference(ADS_SEARCHPREF_INFO* pSearchPrefs, uint32 dwNumPrefs) mut => VT.[Friend]SetSearchPreference(&this, pSearchPrefs, dwNumPrefs);

	public HRESULT ExecuteSearch(PWSTR pszSearchFilter, PWSTR* pAttributeNames, uint32 dwNumberAttributes, ADS_SEARCH_HANDLE* phSearchResult) mut => VT.[Friend]ExecuteSearch(&this, pszSearchFilter, pAttributeNames, dwNumberAttributes, phSearchResult);

	public HRESULT AbandonSearch(ADS_SEARCH_HANDLE phSearchResult) mut => VT.[Friend]AbandonSearch(&this, phSearchResult);

	public HRESULT GetFirstRow(ADS_SEARCH_HANDLE hSearchResult) mut => VT.[Friend]GetFirstRow(&this, hSearchResult);

	public HRESULT GetNextRow(ADS_SEARCH_HANDLE hSearchResult) mut => VT.[Friend]GetNextRow(&this, hSearchResult);

	public HRESULT GetPreviousRow(ADS_SEARCH_HANDLE hSearchResult) mut => VT.[Friend]GetPreviousRow(&this, hSearchResult);

	public HRESULT GetNextColumnName(ADS_SEARCH_HANDLE hSearchHandle, PWSTR* ppszColumnName) mut => VT.[Friend]GetNextColumnName(&this, hSearchHandle, ppszColumnName);

	public HRESULT GetColumn(ADS_SEARCH_HANDLE hSearchResult, PWSTR szColumnName, ADS_SEARCH_COLUMN* pSearchColumn) mut => VT.[Friend]GetColumn(&this, hSearchResult, szColumnName, pSearchColumn);

	public HRESULT FreeColumn(ADS_SEARCH_COLUMN* pSearchColumn) mut => VT.[Friend]FreeColumn(&this, pSearchColumn);

	public HRESULT CloseSearchHandle(ADS_SEARCH_HANDLE hSearchResult) mut => VT.[Friend]CloseSearchHandle(&this, hSearchResult);
}

[CRepr]struct IDirectorySchemaMgmt : IUnknown
{
	public new const Guid IID = .(0x75db3b9c, 0xa4d8, 0x11d0, 0xa7, 0x9c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszAttrNames, uint32 dwNumAttributes, ADS_ATTR_DEF** ppAttrDefinition, uint32* pdwNumAttributes) EnumAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAttributeName, ADS_ATTR_DEF* pAttributeDefinition) CreateAttributeDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAttributeName, ADS_ATTR_DEF* pAttributeDefinition) WriteAttributeDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAttributeName) DeleteAttributeDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszClassNames, uint32 dwNumClasses, ADS_CLASS_DEF** ppClassDefinition, uint32* pdwNumClasses) EnumClasses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszClassName, ADS_CLASS_DEF* pClassDefinition) WriteClassDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszClassName, ADS_CLASS_DEF* pClassDefinition) CreateClassDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszClassName) DeleteClassDefinition;
	}


	public HRESULT EnumAttributes(PWSTR* ppszAttrNames, uint32 dwNumAttributes, ADS_ATTR_DEF** ppAttrDefinition, uint32* pdwNumAttributes) mut => VT.[Friend]EnumAttributes(&this, ppszAttrNames, dwNumAttributes, ppAttrDefinition, pdwNumAttributes);

	public HRESULT CreateAttributeDefinition(PWSTR pszAttributeName, ADS_ATTR_DEF* pAttributeDefinition) mut => VT.[Friend]CreateAttributeDefinition(&this, pszAttributeName, pAttributeDefinition);

	public HRESULT WriteAttributeDefinition(PWSTR pszAttributeName, ADS_ATTR_DEF* pAttributeDefinition) mut => VT.[Friend]WriteAttributeDefinition(&this, pszAttributeName, pAttributeDefinition);

	public HRESULT DeleteAttributeDefinition(PWSTR pszAttributeName) mut => VT.[Friend]DeleteAttributeDefinition(&this, pszAttributeName);

	public HRESULT EnumClasses(PWSTR* ppszClassNames, uint32 dwNumClasses, ADS_CLASS_DEF** ppClassDefinition, uint32* pdwNumClasses) mut => VT.[Friend]EnumClasses(&this, ppszClassNames, dwNumClasses, ppClassDefinition, pdwNumClasses);

	public HRESULT WriteClassDefinition(PWSTR pszClassName, ADS_CLASS_DEF* pClassDefinition) mut => VT.[Friend]WriteClassDefinition(&this, pszClassName, pClassDefinition);

	public HRESULT CreateClassDefinition(PWSTR pszClassName, ADS_CLASS_DEF* pClassDefinition) mut => VT.[Friend]CreateClassDefinition(&this, pszClassName, pClassDefinition);

	public HRESULT DeleteClassDefinition(PWSTR pszClassName) mut => VT.[Friend]DeleteClassDefinition(&this, pszClassName);
}

[CRepr]struct IADsAggregatee : IUnknown
{
	public new const Guid IID = .(0x1346ce8c, 0x9039, 0x11d0, 0x85, 0x28, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pOuterUnknown) ConnectAsAggregatee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisconnectAsAggregatee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid) RelinquishInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid) RestoreInterface;
	}


	public HRESULT ConnectAsAggregatee(IUnknown* pOuterUnknown) mut => VT.[Friend]ConnectAsAggregatee(&this, pOuterUnknown);

	public HRESULT DisconnectAsAggregatee() mut => VT.[Friend]DisconnectAsAggregatee(&this);

	public HRESULT RelinquishInterface(in Guid riid) mut => VT.[Friend]RelinquishInterface(&this, riid);

	public HRESULT RestoreInterface(in Guid riid) mut => VT.[Friend]RestoreInterface(&this, riid);
}

[CRepr]struct IADsAggregator : IUnknown
{
	public new const Guid IID = .(0x52db5fb0, 0x941f, 0x11d0, 0x85, 0x29, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pAggregatee) ConnectAsAggregator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisconnectAsAggregator;
	}


	public HRESULT ConnectAsAggregator(IUnknown* pAggregatee) mut => VT.[Friend]ConnectAsAggregator(&this, pAggregatee);

	public HRESULT DisconnectAsAggregator() mut => VT.[Friend]DisconnectAsAggregator(&this);
}

[CRepr]struct IADsAccessControlEntry : IDispatch
{
	public new const Guid IID = .(0xb4f3a14c, 0x9bdd, 0x11d0, 0x85, 0x2c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AccessMask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAccessMask) put_AccessMask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAceType) put_AceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AceFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAceFlags) put_AceFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnFlags) put_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ObjectType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrObjectType) put_ObjectType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_InheritedObjectType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInheritedObjectType) put_InheritedObjectType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Trustee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTrustee) put_Trustee;
	}


	public HRESULT get_AccessMask(int32* retval) mut => VT.[Friend]get_AccessMask(&this, retval);

	public HRESULT put_AccessMask(int32 lnAccessMask) mut => VT.[Friend]put_AccessMask(&this, lnAccessMask);

	public HRESULT get_AceType(int32* retval) mut => VT.[Friend]get_AceType(&this, retval);

	public HRESULT put_AceType(int32 lnAceType) mut => VT.[Friend]put_AceType(&this, lnAceType);

	public HRESULT get_AceFlags(int32* retval) mut => VT.[Friend]get_AceFlags(&this, retval);

	public HRESULT put_AceFlags(int32 lnAceFlags) mut => VT.[Friend]put_AceFlags(&this, lnAceFlags);

	public HRESULT get_Flags(int32* retval) mut => VT.[Friend]get_Flags(&this, retval);

	public HRESULT put_Flags(int32 lnFlags) mut => VT.[Friend]put_Flags(&this, lnFlags);

	public HRESULT get_ObjectType(BSTR* retval) mut => VT.[Friend]get_ObjectType(&this, retval);

	public HRESULT put_ObjectType(BSTR bstrObjectType) mut => VT.[Friend]put_ObjectType(&this, bstrObjectType);

	public HRESULT get_InheritedObjectType(BSTR* retval) mut => VT.[Friend]get_InheritedObjectType(&this, retval);

	public HRESULT put_InheritedObjectType(BSTR bstrInheritedObjectType) mut => VT.[Friend]put_InheritedObjectType(&this, bstrInheritedObjectType);

	public HRESULT get_Trustee(BSTR* retval) mut => VT.[Friend]get_Trustee(&this, retval);

	public HRESULT put_Trustee(BSTR bstrTrustee) mut => VT.[Friend]put_Trustee(&this, bstrTrustee);
}

[CRepr]struct IADsAccessControlList : IDispatch
{
	public new const Guid IID = .(0xb7ee91cc, 0x9bdd, 0x11d0, 0x85, 0x2c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AclRevision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAclRevision) put_AclRevision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAceCount) put_AceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pAccessControlEntry) AddAce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pAccessControlEntry) RemoveAce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppAccessControlList) CopyAccessList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
	}


	public HRESULT get_AclRevision(int32* retval) mut => VT.[Friend]get_AclRevision(&this, retval);

	public HRESULT put_AclRevision(int32 lnAclRevision) mut => VT.[Friend]put_AclRevision(&this, lnAclRevision);

	public HRESULT get_AceCount(int32* retval) mut => VT.[Friend]get_AceCount(&this, retval);

	public HRESULT put_AceCount(int32 lnAceCount) mut => VT.[Friend]put_AceCount(&this, lnAceCount);

	public HRESULT AddAce(IDispatch* pAccessControlEntry) mut => VT.[Friend]AddAce(&this, pAccessControlEntry);

	public HRESULT RemoveAce(IDispatch* pAccessControlEntry) mut => VT.[Friend]RemoveAce(&this, pAccessControlEntry);

	public HRESULT CopyAccessList(IDispatch** ppAccessControlList) mut => VT.[Friend]CopyAccessList(&this, ppAccessControlList);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);
}

[CRepr]struct IADsSecurityDescriptor : IDispatch
{
	public new const Guid IID = .(0xb8c787ca, 0x9bdd, 0x11d0, 0x85, 0x2c, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Revision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnRevision) put_Revision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Control;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnControl) put_Control;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Owner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOwner) put_Owner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_OwnerDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fOwnerDefaulted) put_OwnerDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Group;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroup) put_Group;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_GroupDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fGroupDefaulted) put_GroupDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** retval) get_DiscretionaryAcl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pDiscretionaryAcl) put_DiscretionaryAcl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_DaclDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fDaclDefaulted) put_DaclDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** retval) get_SystemAcl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pSystemAcl) put_SystemAcl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_SaclDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fSaclDefaulted) put_SaclDefaulted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppSecurityDescriptor) CopySecurityDescriptor;
	}


	public HRESULT get_Revision(int32* retval) mut => VT.[Friend]get_Revision(&this, retval);

	public HRESULT put_Revision(int32 lnRevision) mut => VT.[Friend]put_Revision(&this, lnRevision);

	public HRESULT get_Control(int32* retval) mut => VT.[Friend]get_Control(&this, retval);

	public HRESULT put_Control(int32 lnControl) mut => VT.[Friend]put_Control(&this, lnControl);

	public HRESULT get_Owner(BSTR* retval) mut => VT.[Friend]get_Owner(&this, retval);

	public HRESULT put_Owner(BSTR bstrOwner) mut => VT.[Friend]put_Owner(&this, bstrOwner);

	public HRESULT get_OwnerDefaulted(int16* retval) mut => VT.[Friend]get_OwnerDefaulted(&this, retval);

	public HRESULT put_OwnerDefaulted(int16 fOwnerDefaulted) mut => VT.[Friend]put_OwnerDefaulted(&this, fOwnerDefaulted);

	public HRESULT get_Group(BSTR* retval) mut => VT.[Friend]get_Group(&this, retval);

	public HRESULT put_Group(BSTR bstrGroup) mut => VT.[Friend]put_Group(&this, bstrGroup);

	public HRESULT get_GroupDefaulted(int16* retval) mut => VT.[Friend]get_GroupDefaulted(&this, retval);

	public HRESULT put_GroupDefaulted(int16 fGroupDefaulted) mut => VT.[Friend]put_GroupDefaulted(&this, fGroupDefaulted);

	public HRESULT get_DiscretionaryAcl(IDispatch** retval) mut => VT.[Friend]get_DiscretionaryAcl(&this, retval);

	public HRESULT put_DiscretionaryAcl(IDispatch* pDiscretionaryAcl) mut => VT.[Friend]put_DiscretionaryAcl(&this, pDiscretionaryAcl);

	public HRESULT get_DaclDefaulted(int16* retval) mut => VT.[Friend]get_DaclDefaulted(&this, retval);

	public HRESULT put_DaclDefaulted(int16 fDaclDefaulted) mut => VT.[Friend]put_DaclDefaulted(&this, fDaclDefaulted);

	public HRESULT get_SystemAcl(IDispatch** retval) mut => VT.[Friend]get_SystemAcl(&this, retval);

	public HRESULT put_SystemAcl(IDispatch* pSystemAcl) mut => VT.[Friend]put_SystemAcl(&this, pSystemAcl);

	public HRESULT get_SaclDefaulted(int16* retval) mut => VT.[Friend]get_SaclDefaulted(&this, retval);

	public HRESULT put_SaclDefaulted(int16 fSaclDefaulted) mut => VT.[Friend]put_SaclDefaulted(&this, fSaclDefaulted);

	public HRESULT CopySecurityDescriptor(IDispatch** ppSecurityDescriptor) mut => VT.[Friend]CopySecurityDescriptor(&this, ppSecurityDescriptor);
}

[CRepr]struct IADsLargeInteger : IDispatch
{
	public new const Guid IID = .(0x9068270b, 0x0939, 0x11d1, 0x8b, 0xe1, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_HighPart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnHighPart) put_HighPart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_LowPart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnLowPart) put_LowPart;
	}


	public HRESULT get_HighPart(int32* retval) mut => VT.[Friend]get_HighPart(&this, retval);

	public HRESULT put_HighPart(int32 lnHighPart) mut => VT.[Friend]put_HighPart(&this, lnHighPart);

	public HRESULT get_LowPart(int32* retval) mut => VT.[Friend]get_LowPart(&this, retval);

	public HRESULT put_LowPart(int32 lnLowPart) mut => VT.[Friend]put_LowPart(&this, lnLowPart);
}

[CRepr]struct IADsNameTranslate : IDispatch
{
	public new const Guid IID = .(0xb1b272a3, 0x3625, 0x11d1, 0xa3, 0xa4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnChaseReferral) put_ChaseReferral;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnSetType, BSTR bstrADsPath) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnSetType, BSTR bstrADsPath, BSTR bstrUserID, BSTR bstrDomain, BSTR bstrPassword) InitEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnSetType, BSTR bstrADsPath) Set;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnFormatType, BSTR* pbstrADsPath) Get;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnFormatType, VARIANT pvar) SetEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnFormatType, VARIANT* pvar) GetEx;
	}


	public HRESULT put_ChaseReferral(int32 lnChaseReferral) mut => VT.[Friend]put_ChaseReferral(&this, lnChaseReferral);

	public HRESULT Init(int32 lnSetType, BSTR bstrADsPath) mut => VT.[Friend]Init(&this, lnSetType, bstrADsPath);

	public HRESULT InitEx(int32 lnSetType, BSTR bstrADsPath, BSTR bstrUserID, BSTR bstrDomain, BSTR bstrPassword) mut => VT.[Friend]InitEx(&this, lnSetType, bstrADsPath, bstrUserID, bstrDomain, bstrPassword);

	public HRESULT Set(int32 lnSetType, BSTR bstrADsPath) mut => VT.[Friend]Set(&this, lnSetType, bstrADsPath);

	public HRESULT Get(int32 lnFormatType, BSTR* pbstrADsPath) mut => VT.[Friend]Get(&this, lnFormatType, pbstrADsPath);

	public HRESULT SetEx(int32 lnFormatType, VARIANT pvar) mut => VT.[Friend]SetEx(&this, lnFormatType, pvar);

	public HRESULT GetEx(int32 lnFormatType, VARIANT* pvar) mut => VT.[Friend]GetEx(&this, lnFormatType, pvar);
}

[CRepr]struct IADsCaseIgnoreList : IDispatch
{
	public new const Guid IID = .(0x7b66b533, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_CaseIgnoreList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vCaseIgnoreList) put_CaseIgnoreList;
	}


	public HRESULT get_CaseIgnoreList(VARIANT* retval) mut => VT.[Friend]get_CaseIgnoreList(&this, retval);

	public HRESULT put_CaseIgnoreList(VARIANT vCaseIgnoreList) mut => VT.[Friend]put_CaseIgnoreList(&this, vCaseIgnoreList);
}

[CRepr]struct IADsFaxNumber : IDispatch
{
	public new const Guid IID = .(0xa910dea9, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTelephoneNumber) put_TelephoneNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vParameters) put_Parameters;
	}


	public HRESULT get_TelephoneNumber(BSTR* retval) mut => VT.[Friend]get_TelephoneNumber(&this, retval);

	public HRESULT put_TelephoneNumber(BSTR bstrTelephoneNumber) mut => VT.[Friend]put_TelephoneNumber(&this, bstrTelephoneNumber);

	public HRESULT get_Parameters(VARIANT* retval) mut => VT.[Friend]get_Parameters(&this, retval);

	public HRESULT put_Parameters(VARIANT vParameters) mut => VT.[Friend]put_Parameters(&this, vParameters);
}

[CRepr]struct IADsNetAddress : IDispatch
{
	public new const Guid IID = .(0xb21a50a9, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_AddressType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAddressType) put_AddressType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_Address;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vAddress) put_Address;
	}


	public HRESULT get_AddressType(int32* retval) mut => VT.[Friend]get_AddressType(&this, retval);

	public HRESULT put_AddressType(int32 lnAddressType) mut => VT.[Friend]put_AddressType(&this, lnAddressType);

	public HRESULT get_Address(VARIANT* retval) mut => VT.[Friend]get_Address(&this, retval);

	public HRESULT put_Address(VARIANT vAddress) mut => VT.[Friend]put_Address(&this, vAddress);
}

[CRepr]struct IADsOctetList : IDispatch
{
	public new const Guid IID = .(0x7b28b80f, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_OctetList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vOctetList) put_OctetList;
	}


	public HRESULT get_OctetList(VARIANT* retval) mut => VT.[Friend]get_OctetList(&this, retval);

	public HRESULT put_OctetList(VARIANT vOctetList) mut => VT.[Friend]put_OctetList(&this, vOctetList);
}

[CRepr]struct IADsEmail : IDispatch
{
	public new const Guid IID = .(0x97af011a, 0x478e, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnType) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Address;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAddress) put_Address;
	}


	public HRESULT get_Type(int32* retval) mut => VT.[Friend]get_Type(&this, retval);

	public HRESULT put_Type(int32 lnType) mut => VT.[Friend]put_Type(&this, lnType);

	public HRESULT get_Address(BSTR* retval) mut => VT.[Friend]get_Address(&this, retval);

	public HRESULT put_Address(BSTR bstrAddress) mut => VT.[Friend]put_Address(&this, bstrAddress);
}

[CRepr]struct IADsPath : IDispatch
{
	public new const Guid IID = .(0xb287fcd5, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnType) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_VolumeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVolumeName) put_VolumeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPath) put_Path;
	}


	public HRESULT get_Type(int32* retval) mut => VT.[Friend]get_Type(&this, retval);

	public HRESULT put_Type(int32 lnType) mut => VT.[Friend]put_Type(&this, lnType);

	public HRESULT get_VolumeName(BSTR* retval) mut => VT.[Friend]get_VolumeName(&this, retval);

	public HRESULT put_VolumeName(BSTR bstrVolumeName) mut => VT.[Friend]put_VolumeName(&this, bstrVolumeName);

	public HRESULT get_Path(BSTR* retval) mut => VT.[Friend]get_Path(&this, retval);

	public HRESULT put_Path(BSTR bstrPath) mut => VT.[Friend]put_Path(&this, bstrPath);
}

[CRepr]struct IADsReplicaPointer : IDispatch
{
	public new const Guid IID = .(0xf60fb803, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ServerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName) put_ServerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ReplicaType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnReplicaType) put_ReplicaType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_ReplicaNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnReplicaNumber) put_ReplicaNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnCount) put_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_ReplicaAddressHints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vReplicaAddressHints) put_ReplicaAddressHints;
	}


	public HRESULT get_ServerName(BSTR* retval) mut => VT.[Friend]get_ServerName(&this, retval);

	public HRESULT put_ServerName(BSTR bstrServerName) mut => VT.[Friend]put_ServerName(&this, bstrServerName);

	public HRESULT get_ReplicaType(int32* retval) mut => VT.[Friend]get_ReplicaType(&this, retval);

	public HRESULT put_ReplicaType(int32 lnReplicaType) mut => VT.[Friend]put_ReplicaType(&this, lnReplicaType);

	public HRESULT get_ReplicaNumber(int32* retval) mut => VT.[Friend]get_ReplicaNumber(&this, retval);

	public HRESULT put_ReplicaNumber(int32 lnReplicaNumber) mut => VT.[Friend]put_ReplicaNumber(&this, lnReplicaNumber);

	public HRESULT get_Count(int32* retval) mut => VT.[Friend]get_Count(&this, retval);

	public HRESULT put_Count(int32 lnCount) mut => VT.[Friend]put_Count(&this, lnCount);

	public HRESULT get_ReplicaAddressHints(VARIANT* retval) mut => VT.[Friend]get_ReplicaAddressHints(&this, retval);

	public HRESULT put_ReplicaAddressHints(VARIANT vReplicaAddressHints) mut => VT.[Friend]put_ReplicaAddressHints(&this, vReplicaAddressHints);
}

[CRepr]struct IADsAcl : IDispatch
{
	public new const Guid IID = .(0x8452d3ab, 0x0869, 0x11d1, 0xa3, 0x77, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ProtectedAttrName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtectedAttrName) put_ProtectedAttrName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_SubjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSubjectName) put_SubjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Privileges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnPrivileges) put_Privileges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppAcl) CopyAcl;
	}


	public HRESULT get_ProtectedAttrName(BSTR* retval) mut => VT.[Friend]get_ProtectedAttrName(&this, retval);

	public HRESULT put_ProtectedAttrName(BSTR bstrProtectedAttrName) mut => VT.[Friend]put_ProtectedAttrName(&this, bstrProtectedAttrName);

	public HRESULT get_SubjectName(BSTR* retval) mut => VT.[Friend]get_SubjectName(&this, retval);

	public HRESULT put_SubjectName(BSTR bstrSubjectName) mut => VT.[Friend]put_SubjectName(&this, bstrSubjectName);

	public HRESULT get_Privileges(int32* retval) mut => VT.[Friend]get_Privileges(&this, retval);

	public HRESULT put_Privileges(int32 lnPrivileges) mut => VT.[Friend]put_Privileges(&this, lnPrivileges);

	public HRESULT CopyAcl(IDispatch** ppAcl) mut => VT.[Friend]CopyAcl(&this, ppAcl);
}

[CRepr]struct IADsTimestamp : IDispatch
{
	public new const Guid IID = .(0xb2f5a901, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_WholeSeconds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnWholeSeconds) put_WholeSeconds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_EventID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnEventID) put_EventID;
	}


	public HRESULT get_WholeSeconds(int32* retval) mut => VT.[Friend]get_WholeSeconds(&this, retval);

	public HRESULT put_WholeSeconds(int32 lnWholeSeconds) mut => VT.[Friend]put_WholeSeconds(&this, lnWholeSeconds);

	public HRESULT get_EventID(int32* retval) mut => VT.[Friend]get_EventID(&this, retval);

	public HRESULT put_EventID(int32 lnEventID) mut => VT.[Friend]put_EventID(&this, lnEventID);
}

[CRepr]struct IADsPostalAddress : IDispatch
{
	public new const Guid IID = .(0x7adecf29, 0x4680, 0x11d1, 0xa3, 0xb4, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_PostalAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vPostalAddress) put_PostalAddress;
	}


	public HRESULT get_PostalAddress(VARIANT* retval) mut => VT.[Friend]get_PostalAddress(&this, retval);

	public HRESULT put_PostalAddress(VARIANT vPostalAddress) mut => VT.[Friend]put_PostalAddress(&this, vPostalAddress);
}

[CRepr]struct IADsBackLink : IDispatch
{
	public new const Guid IID = .(0xfd1302bd, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_RemoteID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnRemoteID) put_RemoteID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrObjectName) put_ObjectName;
	}


	public HRESULT get_RemoteID(int32* retval) mut => VT.[Friend]get_RemoteID(&this, retval);

	public HRESULT put_RemoteID(int32 lnRemoteID) mut => VT.[Friend]put_RemoteID(&this, lnRemoteID);

	public HRESULT get_ObjectName(BSTR* retval) mut => VT.[Friend]get_ObjectName(&this, retval);

	public HRESULT put_ObjectName(BSTR bstrObjectName) mut => VT.[Friend]put_ObjectName(&this, bstrObjectName);
}

[CRepr]struct IADsTypedName : IDispatch
{
	public new const Guid IID = .(0xb371a349, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrObjectName) put_ObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Level;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnLevel) put_Level;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Interval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnInterval) put_Interval;
	}


	public HRESULT get_ObjectName(BSTR* retval) mut => VT.[Friend]get_ObjectName(&this, retval);

	public HRESULT put_ObjectName(BSTR bstrObjectName) mut => VT.[Friend]put_ObjectName(&this, bstrObjectName);

	public HRESULT get_Level(int32* retval) mut => VT.[Friend]get_Level(&this, retval);

	public HRESULT put_Level(int32 lnLevel) mut => VT.[Friend]put_Level(&this, lnLevel);

	public HRESULT get_Interval(int32* retval) mut => VT.[Friend]get_Interval(&this, retval);

	public HRESULT put_Interval(int32 lnInterval) mut => VT.[Friend]put_Interval(&this, lnInterval);
}

[CRepr]struct IADsHold : IDispatch
{
	public new const Guid IID = .(0xb3eb3b37, 0x4080, 0x11d1, 0xa3, 0xac, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrObjectName) put_ObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_Amount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnAmount) put_Amount;
	}


	public HRESULT get_ObjectName(BSTR* retval) mut => VT.[Friend]get_ObjectName(&this, retval);

	public HRESULT put_ObjectName(BSTR bstrObjectName) mut => VT.[Friend]put_ObjectName(&this, bstrObjectName);

	public HRESULT get_Amount(int32* retval) mut => VT.[Friend]get_Amount(&this, retval);

	public HRESULT put_Amount(int32 lnAmount) mut => VT.[Friend]put_Amount(&this, lnAmount);
}

[CRepr]struct IADsObjectOptions : IDispatch
{
	public new const Guid IID = .(0x46f14fda, 0x232b, 0x11d1, 0xa8, 0x08, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnOption, VARIANT* pvValue) GetOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnOption, VARIANT vValue) SetOption;
	}


	public HRESULT GetOption(int32 lnOption, VARIANT* pvValue) mut => VT.[Friend]GetOption(&this, lnOption, pvValue);

	public HRESULT SetOption(int32 lnOption, VARIANT vValue) mut => VT.[Friend]SetOption(&this, lnOption, vValue);
}

[CRepr]struct IADsPathname : IDispatch
{
	public new const Guid IID = .(0xd592aed4, 0xf420, 0x11d0, 0xa3, 0x6e, 0x00, 0xc0, 0x4f, 0xb9, 0x50, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrADsPath, int32 lnSetType) Set;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnDisplayType) SetDisplayType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnFormatType, BSTR* pbstrADsPath) Retrieve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plnNumPathElements) GetNumElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnElementIndex, BSTR* pbstrElement) GetElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLeafElement) AddLeafElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveLeafElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppAdsPath) CopyPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnReserved, BSTR bstrInStr, BSTR* pbstrOutStr) GetEscapedElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_EscapedMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnEscapedMode) put_EscapedMode;
	}


	public HRESULT Set(BSTR bstrADsPath, int32 lnSetType) mut => VT.[Friend]Set(&this, bstrADsPath, lnSetType);

	public HRESULT SetDisplayType(int32 lnDisplayType) mut => VT.[Friend]SetDisplayType(&this, lnDisplayType);

	public HRESULT Retrieve(int32 lnFormatType, BSTR* pbstrADsPath) mut => VT.[Friend]Retrieve(&this, lnFormatType, pbstrADsPath);

	public HRESULT GetNumElements(int32* plnNumPathElements) mut => VT.[Friend]GetNumElements(&this, plnNumPathElements);

	public HRESULT GetElement(int32 lnElementIndex, BSTR* pbstrElement) mut => VT.[Friend]GetElement(&this, lnElementIndex, pbstrElement);

	public HRESULT AddLeafElement(BSTR bstrLeafElement) mut => VT.[Friend]AddLeafElement(&this, bstrLeafElement);

	public HRESULT RemoveLeafElement() mut => VT.[Friend]RemoveLeafElement(&this);

	public HRESULT CopyPath(IDispatch** ppAdsPath) mut => VT.[Friend]CopyPath(&this, ppAdsPath);

	public HRESULT GetEscapedElement(int32 lnReserved, BSTR bstrInStr, BSTR* pbstrOutStr) mut => VT.[Friend]GetEscapedElement(&this, lnReserved, bstrInStr, pbstrOutStr);

	public HRESULT get_EscapedMode(int32* retval) mut => VT.[Friend]get_EscapedMode(&this, retval);

	public HRESULT put_EscapedMode(int32 lnEscapedMode) mut => VT.[Friend]put_EscapedMode(&this, lnEscapedMode);
}

[CRepr]struct IADsADSystemInfo : IDispatch
{
	public new const Guid IID = .(0x5bb11929, 0xafd1, 0x11d2, 0x9c, 0xb9, 0x00, 0x00, 0xf8, 0x7a, 0x36, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_UserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ComputerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_SiteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DomainShortName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DomainDNSName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ForestDNSName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PDCRoleOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_SchemaRoleOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* retval) get_IsNativeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pszDCName) GetAnyDCName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szServer, BSTR* pszSiteName) GetDCSiteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshSchemaCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvTrees) GetTrees;
	}


	public HRESULT get_UserName(BSTR* retval) mut => VT.[Friend]get_UserName(&this, retval);

	public HRESULT get_ComputerName(BSTR* retval) mut => VT.[Friend]get_ComputerName(&this, retval);

	public HRESULT get_SiteName(BSTR* retval) mut => VT.[Friend]get_SiteName(&this, retval);

	public HRESULT get_DomainShortName(BSTR* retval) mut => VT.[Friend]get_DomainShortName(&this, retval);

	public HRESULT get_DomainDNSName(BSTR* retval) mut => VT.[Friend]get_DomainDNSName(&this, retval);

	public HRESULT get_ForestDNSName(BSTR* retval) mut => VT.[Friend]get_ForestDNSName(&this, retval);

	public HRESULT get_PDCRoleOwner(BSTR* retval) mut => VT.[Friend]get_PDCRoleOwner(&this, retval);

	public HRESULT get_SchemaRoleOwner(BSTR* retval) mut => VT.[Friend]get_SchemaRoleOwner(&this, retval);

	public HRESULT get_IsNativeMode(int16* retval) mut => VT.[Friend]get_IsNativeMode(&this, retval);

	public HRESULT GetAnyDCName(BSTR* pszDCName) mut => VT.[Friend]GetAnyDCName(&this, pszDCName);

	public HRESULT GetDCSiteName(BSTR szServer, BSTR* pszSiteName) mut => VT.[Friend]GetDCSiteName(&this, szServer, pszSiteName);

	public HRESULT RefreshSchemaCache() mut => VT.[Friend]RefreshSchemaCache(&this);

	public HRESULT GetTrees(VARIANT* pvTrees) mut => VT.[Friend]GetTrees(&this, pvTrees);
}

[CRepr]struct IADsWinNTSystemInfo : IDispatch
{
	public new const Guid IID = .(0x6c6d65dc, 0xafd1, 0x11d2, 0x9c, 0xb9, 0x00, 0x00, 0xf8, 0x7a, 0x36, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_UserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_ComputerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DomainName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_PDC;
	}


	public HRESULT get_UserName(BSTR* retval) mut => VT.[Friend]get_UserName(&this, retval);

	public HRESULT get_ComputerName(BSTR* retval) mut => VT.[Friend]get_ComputerName(&this, retval);

	public HRESULT get_DomainName(BSTR* retval) mut => VT.[Friend]get_DomainName(&this, retval);

	public HRESULT get_PDC(BSTR* retval) mut => VT.[Friend]get_PDC(&this, retval);
}

[CRepr]struct IADsDNWithBinary : IDispatch
{
	public new const Guid IID = .(0x7e99c0a2, 0xf935, 0x11d2, 0xba, 0x96, 0x00, 0xc0, 0x4f, 0xb6, 0xd0, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* retval) get_BinaryValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vBinaryValue) put_BinaryValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DNString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDNString) put_DNString;
	}


	public HRESULT get_BinaryValue(VARIANT* retval) mut => VT.[Friend]get_BinaryValue(&this, retval);

	public HRESULT put_BinaryValue(VARIANT vBinaryValue) mut => VT.[Friend]put_BinaryValue(&this, vBinaryValue);

	public HRESULT get_DNString(BSTR* retval) mut => VT.[Friend]get_DNString(&this, retval);

	public HRESULT put_DNString(BSTR bstrDNString) mut => VT.[Friend]put_DNString(&this, bstrDNString);
}

[CRepr]struct IADsDNWithString : IDispatch
{
	public new const Guid IID = .(0x370df02e, 0xf934, 0x11d2, 0xba, 0x96, 0x00, 0xc0, 0x4f, 0xb6, 0xd0, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_StringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrStringValue) put_StringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* retval) get_DNString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDNString) put_DNString;
	}


	public HRESULT get_StringValue(BSTR* retval) mut => VT.[Friend]get_StringValue(&this, retval);

	public HRESULT put_StringValue(BSTR bstrStringValue) mut => VT.[Friend]put_StringValue(&this, bstrStringValue);

	public HRESULT get_DNString(BSTR* retval) mut => VT.[Friend]get_DNString(&this, retval);

	public HRESULT put_DNString(BSTR bstrDNString) mut => VT.[Friend]put_DNString(&this, bstrDNString);
}

[CRepr]struct IADsSecurityUtility : IDispatch
{
	public new const Guid IID = .(0xa63251b2, 0x5f21, 0x474b, 0xab, 0x52, 0x4a, 0x8e, 0xfa, 0xd1, 0x08, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varPath, int32 lPathFormat, int32 lFormat, VARIANT* pVariant) GetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varPath, int32 lPathFormat, VARIANT varData, int32 lDataFormat) SetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSD, int32 lDataFormat, int32 lOutFormat, VARIANT* pResult) ConvertSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_SecurityMask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lnSecurityMask) put_SecurityMask;
	}


	public HRESULT GetSecurityDescriptor(VARIANT varPath, int32 lPathFormat, int32 lFormat, VARIANT* pVariant) mut => VT.[Friend]GetSecurityDescriptor(&this, varPath, lPathFormat, lFormat, pVariant);

	public HRESULT SetSecurityDescriptor(VARIANT varPath, int32 lPathFormat, VARIANT varData, int32 lDataFormat) mut => VT.[Friend]SetSecurityDescriptor(&this, varPath, lPathFormat, varData, lDataFormat);

	public HRESULT ConvertSecurityDescriptor(VARIANT varSD, int32 lDataFormat, int32 lOutFormat, VARIANT* pResult) mut => VT.[Friend]ConvertSecurityDescriptor(&this, varSD, lDataFormat, lOutFormat, pResult);

	public HRESULT get_SecurityMask(int32* retval) mut => VT.[Friend]get_SecurityMask(&this, retval);

	public HRESULT put_SecurityMask(int32 lnSecurityMask) mut => VT.[Friend]put_SecurityMask(&this, lnSecurityMask);
}

[CRepr]struct IDsBrowseDomainTree : IUnknown
{
	public new const Guid IID = .(0x7cabcf1e, 0x78f5, 0x11d2, 0x96, 0x0c, 0x00, 0xc0, 0x4f, 0xa3, 0x1a, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR* ppszTargetPath, uint32 dwFlags) BrowseTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOMAIN_TREE** ppDomainTree, uint32 dwFlags) GetDomains;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DOMAIN_TREE** ppDomainTree) FreeDomains;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlushCachedDomains;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszComputerName, PWSTR pszUserName, PWSTR pszPassword) SetComputer;
	}


	public HRESULT BrowseTo(HWND hwndParent, PWSTR* ppszTargetPath, uint32 dwFlags) mut => VT.[Friend]BrowseTo(&this, hwndParent, ppszTargetPath, dwFlags);

	public HRESULT GetDomains(DOMAIN_TREE** ppDomainTree, uint32 dwFlags) mut => VT.[Friend]GetDomains(&this, ppDomainTree, dwFlags);

	public HRESULT FreeDomains(DOMAIN_TREE** ppDomainTree) mut => VT.[Friend]FreeDomains(&this, ppDomainTree);

	public HRESULT FlushCachedDomains() mut => VT.[Friend]FlushCachedDomains(&this);

	public HRESULT SetComputer(PWSTR pszComputerName, PWSTR pszUserName, PWSTR pszPassword) mut => VT.[Friend]SetComputer(&this, pszComputerName, pszUserName, pszPassword);
}

[CRepr]struct IDsDisplaySpecifier : IUnknown
{
	public new const Guid IID = .(0x1ab4a8c0, 0x6a0b, 0x11d2, 0xad, 0x49, 0x00, 0xc0, 0x4f, 0xa3, 0x1a, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszServer, PWSTR pszUserName, PWSTR pszPassword, uint32 dwFlags) SetServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid) SetLanguageID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectClass, in Guid riid, void** ppv) GetDisplaySpecifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectClass, uint32 dwFlags, char16* pszBuffer, int32 cchBuffer, int32* presid) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HICON(SelfOuter* self, PWSTR pszObjectClass, uint32 dwFlags, int32 cxIcon, int32 cyIcon) GetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectClass, char16* pszBuffer, int32 cchBuffer) GetFriendlyClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectClass, PWSTR pszAttributeName, char16* pszBuffer, uint32 cchBuffer) GetFriendlyAttributeName;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, PWSTR pszObjectClass, PWSTR pszADsPath, uint32 dwFlags) IsClassContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectClass, DSCLASSCREATIONINFO** ppdscci) GetClassCreationInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectClass, LPDSENUMATTRIBUTES pcbEnum, LPARAM lParam) EnumClassAttributes;
		protected new function [CallingConvention(.Stdcall)] ADSTYPE(SelfOuter* self, PWSTR pszAttributeName) GetAttributeADsType;
	}


	public HRESULT SetServer(PWSTR pszServer, PWSTR pszUserName, PWSTR pszPassword, uint32 dwFlags) mut => VT.[Friend]SetServer(&this, pszServer, pszUserName, pszPassword, dwFlags);

	public HRESULT SetLanguageID(uint16 langid) mut => VT.[Friend]SetLanguageID(&this, langid);

	public HRESULT GetDisplaySpecifier(PWSTR pszObjectClass, in Guid riid, void** ppv) mut => VT.[Friend]GetDisplaySpecifier(&this, pszObjectClass, riid, ppv);

	public HRESULT GetIconLocation(PWSTR pszObjectClass, uint32 dwFlags, char16* pszBuffer, int32 cchBuffer, int32* presid) mut => VT.[Friend]GetIconLocation(&this, pszObjectClass, dwFlags, pszBuffer, cchBuffer, presid);

	public HICON GetIcon(PWSTR pszObjectClass, uint32 dwFlags, int32 cxIcon, int32 cyIcon) mut => VT.[Friend]GetIcon(&this, pszObjectClass, dwFlags, cxIcon, cyIcon);

	public HRESULT GetFriendlyClassName(PWSTR pszObjectClass, char16* pszBuffer, int32 cchBuffer) mut => VT.[Friend]GetFriendlyClassName(&this, pszObjectClass, pszBuffer, cchBuffer);

	public HRESULT GetFriendlyAttributeName(PWSTR pszObjectClass, PWSTR pszAttributeName, char16* pszBuffer, uint32 cchBuffer) mut => VT.[Friend]GetFriendlyAttributeName(&this, pszObjectClass, pszAttributeName, pszBuffer, cchBuffer);

	public BOOL IsClassContainer(PWSTR pszObjectClass, PWSTR pszADsPath, uint32 dwFlags) mut => VT.[Friend]IsClassContainer(&this, pszObjectClass, pszADsPath, dwFlags);

	public HRESULT GetClassCreationInfo(PWSTR pszObjectClass, DSCLASSCREATIONINFO** ppdscci) mut => VT.[Friend]GetClassCreationInfo(&this, pszObjectClass, ppdscci);

	public HRESULT EnumClassAttributes(PWSTR pszObjectClass, LPDSENUMATTRIBUTES pcbEnum, LPARAM lParam) mut => VT.[Friend]EnumClassAttributes(&this, pszObjectClass, pcbEnum, lParam);

	public ADSTYPE GetAttributeADsType(PWSTR pszAttributeName) mut => VT.[Friend]GetAttributeADsType(&this, pszAttributeName);
}

[CRepr]struct IDsObjectPicker : IUnknown
{
	public new const Guid IID = .(0x0c87e64e, 0x3b7a, 0x11d2, 0xb9, 0xe0, 0x00, 0xc0, 0x4f, 0xd8, 0xdb, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DSOP_INIT_INFO* pInitInfo) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IDataObject** ppdoSelections) InvokeDialog;
	}


	public HRESULT Initialize(DSOP_INIT_INFO* pInitInfo) mut => VT.[Friend]Initialize(&this, pInitInfo);

	public HRESULT InvokeDialog(HWND hwndParent, IDataObject** ppdoSelections) mut => VT.[Friend]InvokeDialog(&this, hwndParent, ppdoSelections);
}

[CRepr]struct IDsObjectPickerCredentials : IDsObjectPicker
{
	public new const Guid IID = .(0xe2d3ec9b, 0xd041, 0x445a, 0x8f, 0x16, 0x47, 0x48, 0xde, 0x8f, 0xb1, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDsObjectPicker.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szUserName, PWSTR szPassword) SetCredentials;
	}


	public HRESULT SetCredentials(PWSTR szUserName, PWSTR szPassword) mut => VT.[Friend]SetCredentials(&this, szUserName, szPassword);
}

[CRepr]struct IDsAdminCreateObj : IUnknown
{
	public new const Guid IID = .(0x53554a38, 0xf902, 0x11d2, 0x82, 0xb9, 0x00, 0xc0, 0x4f, 0x68, 0x92, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsContainer* pADsContainerObj, IADs* pADsCopySource, PWSTR lpszClassName) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IADs** ppADsObj) CreateModal;
	}


	public HRESULT Initialize(IADsContainer* pADsContainerObj, IADs* pADsCopySource, PWSTR lpszClassName) mut => VT.[Friend]Initialize(&this, pADsContainerObj, pADsCopySource, lpszClassName);

	public HRESULT CreateModal(HWND hwndParent, IADs** ppADsObj) mut => VT.[Friend]CreateModal(&this, hwndParent, ppADsObj);
}

[CRepr]struct IDsAdminNewObj : IUnknown
{
	public new const Guid IID = .(0xf2573587, 0xe6fc, 0x11d2, 0x82, 0xaf, 0x00, 0xc0, 0x4f, 0x68, 0x92, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCurrIndex, BOOL bValid) SetButtons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnTotal, int32* pnStartIndex) GetPageCounts;
	}


	public HRESULT SetButtons(uint32 nCurrIndex, BOOL bValid) mut => VT.[Friend]SetButtons(&this, nCurrIndex, bValid);

	public HRESULT GetPageCounts(int32* pnTotal, int32* pnStartIndex) mut => VT.[Friend]GetPageCounts(&this, pnTotal, pnStartIndex);
}

[CRepr]struct IDsAdminNewObjPrimarySite : IUnknown
{
	public new const Guid IID = .(0xbe2b487e, 0xf904, 0x11d2, 0x82, 0xb9, 0x00, 0xc0, 0x4f, 0x68, 0x92, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) CreateNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
	}


	public HRESULT CreateNew(PWSTR pszName) mut => VT.[Friend]CreateNew(&this, pszName);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);
}

[CRepr]struct IDsAdminNewObjExt : IUnknown
{
	public new const Guid IID = .(0x6088eae2, 0xe7bf, 0x11d2, 0x82, 0xaf, 0x00, 0xc0, 0x4f, 0x68, 0x92, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADsContainer* pADsContainerObj, IADs* pADsCopySource, PWSTR lpszClassName, IDsAdminNewObj* pDsAdminNewObj, DSA_NEWOBJ_DISPINFO* pDispInfo) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPFNSVADDPROPSHEETPAGE lpfnAddPage, LPARAM lParam) AddPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IADs* pADsObj) SetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, uint32 uContext) WriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, HRESULT hr, uint32 uContext) OnError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstrText) GetSummaryInfo;
	}


	public HRESULT Initialize(IADsContainer* pADsContainerObj, IADs* pADsCopySource, PWSTR lpszClassName, IDsAdminNewObj* pDsAdminNewObj, DSA_NEWOBJ_DISPINFO* pDispInfo) mut => VT.[Friend]Initialize(&this, pADsContainerObj, pADsCopySource, lpszClassName, pDsAdminNewObj, pDispInfo);

	public HRESULT AddPages(LPFNSVADDPROPSHEETPAGE lpfnAddPage, LPARAM lParam) mut => VT.[Friend]AddPages(&this, lpfnAddPage, lParam);

	public HRESULT SetObject(IADs* pADsObj) mut => VT.[Friend]SetObject(&this, pADsObj);

	public HRESULT WriteData(HWND hWnd, uint32 uContext) mut => VT.[Friend]WriteData(&this, hWnd, uContext);

	public HRESULT OnError(HWND hWnd, HRESULT hr, uint32 uContext) mut => VT.[Friend]OnError(&this, hWnd, hr, uContext);

	public HRESULT GetSummaryInfo(BSTR* pBstrText) mut => VT.[Friend]GetSummaryInfo(&this, pBstrText);
}

[CRepr]struct IDsAdminNotifyHandler : IUnknown
{
	public new const Guid IID = .(0xe4a2b8b3, 0x5a18, 0x11d2, 0x97, 0xc1, 0x00, 0xa0, 0xc9, 0xa0, 0x6d, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pExtraInfo, uint32* puEventFlags) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uEvent, IDataObject* pArg1, IDataObject* pArg2, uint32* puFlags, BSTR* pBstr) Begin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nItem, uint32 uFlags) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) End;
	}


	public HRESULT Initialize(IDataObject* pExtraInfo, uint32* puEventFlags) mut => VT.[Friend]Initialize(&this, pExtraInfo, puEventFlags);

	public HRESULT Begin(uint32 uEvent, IDataObject* pArg1, IDataObject* pArg2, uint32* puFlags, BSTR* pBstr) mut => VT.[Friend]Begin(&this, uEvent, pArg1, pArg2, puFlags, pBstr);

	public HRESULT Notify(uint32 nItem, uint32 uFlags) mut => VT.[Friend]Notify(&this, nItem, uFlags);

	public HRESULT End() mut => VT.[Friend]End(&this);
}

#endregion

#region Functions
public static
{
	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsGetObject(PWSTR lpszPathName, in Guid riid, void** ppObject);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsBuildEnumerator(IADsContainer* pADsContainer, IEnumVARIANT** ppEnumVariant);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsFreeEnumerator(IEnumVARIANT* pEnumVariant);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsEnumerateNext(IEnumVARIANT* pEnumVariant, uint32 cElements, VARIANT* pvar, uint32* pcElementsFetched);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsBuildVarArrayStr(PWSTR* lppPathNames, uint32 dwPathNames, VARIANT* pVar);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsBuildVarArrayInt(uint32* lpdwObjectTypes, uint32 dwObjectTypes, VARIANT* pVar);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsOpenObject(PWSTR lpszPathName, PWSTR lpszUserName, PWSTR lpszPassword, ADS_AUTHENTICATION_ENUM dwReserved, in Guid riid, void** ppObject);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsGetLastError(uint32* lpError, char16* lpErrorBuf, uint32 dwErrorBufLen, char16* lpNameBuf, uint32 dwNameBufLen);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ADsSetLastError(uint32 dwErr, PWSTR pszError, PWSTR pszProvider);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* AllocADsMem(uint32 cb);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeADsMem(void* pMem);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ReallocADsMem(void* pOldMem, uint32 cbOld, uint32 cbNew);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR AllocADsStr(PWSTR pStr);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeADsStr(PWSTR pStr);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReallocADsStr(PWSTR* ppStr, PWSTR pStr);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsEncodeBinaryData(uint8* pbSrcData, uint32 dwSrcLen, PWSTR* ppszDestData);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsDecodeBinaryData(PWSTR szSrcData, uint8** ppbDestData, uint32* pdwDestLen);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToAdsType(VARIANT* pVariant, uint32 dwNumVariant, ADSVALUE** ppAdsValues, uint32* pdwNumValues);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AdsTypeToPropVariant(ADSVALUE* pAdsValues, uint32 dwNumValues, VARIANT* pVariant);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void AdsFreeAdsValues(ADSVALUE* pAdsValues, uint32 dwNumValues);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BinarySDToSecurityDescriptor(PSECURITY_DESCRIPTOR pSecurityDescriptor, VARIANT* pVarsec, PWSTR pszServerName, PWSTR userName, PWSTR passWord, uint32 dwFlags);

	[Import("ACTIVEDS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SecurityDescriptorToBinarySD(VARIANT vVarSecDes, PSECURITY_DESCRIPTOR* ppSecurityDescriptor, uint32* pdwSDLength, PWSTR pszServerName, PWSTR userName, PWSTR passWord, uint32 dwFlags);

	[Import("dsuiext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DsBrowseForContainerW(DSBROWSEINFOW* pInfo);

	[Import("dsuiext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DsBrowseForContainerA(DSBROWSEINFOA* pInfo);
	public static int32 DsBrowseForContainer(DSBROWSEINFOA* pInfo) => DsBrowseForContainerA(pInfo);

	[Import("dsuiext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON DsGetIcon(uint32 dwFlags, PWSTR pszObjectClass, int32 cxImage, int32 cyImage);

	[Import("dsuiext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DsGetFriendlyClassName(PWSTR pszObjectClass, char16* pszBuffer, uint32 cchBuffer);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ADsPropCreateNotifyObj(IDataObject* pAppThdDataObj, PWSTR pwzADsObjName, HWND* phNotifyObj);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ADsPropGetInitInfo(HWND hNotifyObj, ADSPROPINITPARAMS* pInitParams);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ADsPropSetHwndWithTitle(HWND hNotifyObj, HWND hPage, int8* ptzTitle);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ADsPropSetHwnd(HWND hNotifyObj, HWND hPage);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ADsPropCheckIfWritable(PWSTR pwzAttr, ADS_ATTR_INFO* pWritableAttrs);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ADsPropSendErrorMessage(HWND hNotifyObj, ADSPROPERROR* pError);

	[Import("dsprop.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ADsPropShowErrorDialog(HWND hNotifyObj, HWND hPage);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMakeSpnW(PWSTR ServiceClass, PWSTR ServiceName, PWSTR InstanceName, uint16 InstancePort, PWSTR Referrer, uint32* pcSpnLength, char16* pszSpn);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMakeSpnA(PSTR ServiceClass, PSTR ServiceName, PSTR InstanceName, uint16 InstancePort, PSTR Referrer, uint32* pcSpnLength, uint8* pszSpn);
	public static uint32 DsMakeSpn(PSTR ServiceClass, PSTR ServiceName, PSTR InstanceName, uint16 InstancePort, PSTR Referrer, uint32* pcSpnLength, uint8* pszSpn) => DsMakeSpnA(ServiceClass, ServiceName, InstanceName, InstancePort, Referrer, pcSpnLength, pszSpn);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackSpnA(PSTR pszSpn, uint32* pcServiceClass, uint8* ServiceClass, uint32* pcServiceName, uint8* ServiceName, uint32* pcInstanceName, uint8* InstanceName, uint16* pInstancePort);
	public static uint32 DsCrackSpn(PSTR pszSpn, uint32* pcServiceClass, uint8* ServiceClass, uint32* pcServiceName, uint8* ServiceName, uint32* pcInstanceName, uint8* InstanceName, uint16* pInstancePort) => DsCrackSpnA(pszSpn, pcServiceClass, ServiceClass, pcServiceName, ServiceName, pcInstanceName, InstanceName, pInstancePort);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackSpnW(PWSTR pszSpn, uint32* pcServiceClass, char16* ServiceClass, uint32* pcServiceName, char16* ServiceName, uint32* pcInstanceName, char16* InstanceName, uint16* pInstancePort);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsQuoteRdnValueW(uint32 cUnquotedRdnValueLength, char16* psUnquotedRdnValue, uint32* pcQuotedRdnValueLength, char16* psQuotedRdnValue);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsQuoteRdnValueA(uint32 cUnquotedRdnValueLength, uint8* psUnquotedRdnValue, uint32* pcQuotedRdnValueLength, uint8* psQuotedRdnValue);
	public static uint32 DsQuoteRdnValue(uint32 cUnquotedRdnValueLength, uint8* psUnquotedRdnValue, uint32* pcQuotedRdnValueLength, uint8* psQuotedRdnValue) => DsQuoteRdnValueA(cUnquotedRdnValueLength, psUnquotedRdnValue, pcQuotedRdnValueLength, psQuotedRdnValue);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsUnquoteRdnValueW(uint32 cQuotedRdnValueLength, char16* psQuotedRdnValue, uint32* pcUnquotedRdnValueLength, char16* psUnquotedRdnValue);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsUnquoteRdnValueA(uint32 cQuotedRdnValueLength, uint8* psQuotedRdnValue, uint32* pcUnquotedRdnValueLength, uint8* psUnquotedRdnValue);
	public static uint32 DsUnquoteRdnValue(uint32 cQuotedRdnValueLength, uint8* psQuotedRdnValue, uint32* pcUnquotedRdnValueLength, uint8* psUnquotedRdnValue) => DsUnquoteRdnValueA(cQuotedRdnValueLength, psQuotedRdnValue, pcUnquotedRdnValueLength, psUnquotedRdnValue);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetRdnW(PWSTR* ppDN, uint32* pcDN, PWSTR* ppKey, uint32* pcKey, PWSTR* ppVal, uint32* pcVal);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DsCrackUnquotedMangledRdnW(char16* pszRDN, uint32 cchRDN, Guid* pGuid, DS_MANGLE_FOR* peDsMangleFor);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DsCrackUnquotedMangledRdnA(uint8* pszRDN, uint32 cchRDN, Guid* pGuid, DS_MANGLE_FOR* peDsMangleFor);
	public static BOOL DsCrackUnquotedMangledRdn(uint8* pszRDN, uint32 cchRDN, Guid* pGuid, DS_MANGLE_FOR* peDsMangleFor) => DsCrackUnquotedMangledRdnA(pszRDN, cchRDN, pGuid, peDsMangleFor);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DsIsMangledRdnValueW(char16* pszRdn, uint32 cRdn, DS_MANGLE_FOR eDsMangleForDesired);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DsIsMangledRdnValueA(uint8* pszRdn, uint32 cRdn, DS_MANGLE_FOR eDsMangleForDesired);
	public static BOOL DsIsMangledRdnValue(uint8* pszRdn, uint32 cRdn, DS_MANGLE_FOR eDsMangleForDesired) => DsIsMangledRdnValueA(pszRdn, cRdn, eDsMangleForDesired);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DsIsMangledDnA(PSTR pszDn, DS_MANGLE_FOR eDsMangleFor);
	public static BOOL DsIsMangledDn(PSTR pszDn, DS_MANGLE_FOR eDsMangleFor) => DsIsMangledDnA(pszDn, eDsMangleFor);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DsIsMangledDnW(PWSTR pszDn, DS_MANGLE_FOR eDsMangleFor);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackSpn2A(uint8* pszSpn, uint32 cSpn, uint32* pcServiceClass, uint8* ServiceClass, uint32* pcServiceName, uint8* ServiceName, uint32* pcInstanceName, uint8* InstanceName, uint16* pInstancePort);
	public static uint32 DsCrackSpn2(uint8* pszSpn, uint32 cSpn, uint32* pcServiceClass, uint8* ServiceClass, uint32* pcServiceName, uint8* ServiceName, uint32* pcInstanceName, uint8* InstanceName, uint16* pInstancePort) => DsCrackSpn2A(pszSpn, cSpn, pcServiceClass, ServiceClass, pcServiceName, ServiceName, pcInstanceName, InstanceName, pInstancePort);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackSpn2W(char16* pszSpn, uint32 cSpn, uint32* pcServiceClass, char16* ServiceClass, uint32* pcServiceName, char16* ServiceName, uint32* pcInstanceName, char16* InstanceName, uint16* pInstancePort);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackSpn3W(PWSTR pszSpn, uint32 cSpn, uint32* pcHostName, char16* HostName, uint32* pcInstanceName, char16* InstanceName, uint16* pPortNumber, uint32* pcDomainName, char16* DomainName, uint32* pcRealmName, char16* RealmName);

	[Import("DSPARSE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackSpn4W(PWSTR pszSpn, uint32 cSpn, uint32* pcHostName, char16* HostName, uint32* pcInstanceName, char16* InstanceName, uint32* pcPortName, char16* PortName, uint32* pcDomainName, char16* DomainName, uint32* pcRealmName, char16* RealmName);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindW(PWSTR DomainControllerName, PWSTR DnsDomainName, HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindA(PSTR DomainControllerName, PSTR DnsDomainName, HANDLE* phDS);
	public static uint32 DsBind(PSTR DomainControllerName, PSTR DnsDomainName, HANDLE* phDS) => DsBindA(DomainControllerName, DnsDomainName, phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindWithCredW(PWSTR DomainControllerName, PWSTR DnsDomainName, void* AuthIdentity, HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindWithCredA(PSTR DomainControllerName, PSTR DnsDomainName, void* AuthIdentity, HANDLE* phDS);
	public static uint32 DsBindWithCred(PSTR DomainControllerName, PSTR DnsDomainName, void* AuthIdentity, HANDLE* phDS) => DsBindWithCredA(DomainControllerName, DnsDomainName, AuthIdentity, phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindWithSpnW(PWSTR DomainControllerName, PWSTR DnsDomainName, void* AuthIdentity, PWSTR ServicePrincipalName, HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindWithSpnA(PSTR DomainControllerName, PSTR DnsDomainName, void* AuthIdentity, PSTR ServicePrincipalName, HANDLE* phDS);
	public static uint32 DsBindWithSpn(PSTR DomainControllerName, PSTR DnsDomainName, void* AuthIdentity, PSTR ServicePrincipalName, HANDLE* phDS) => DsBindWithSpnA(DomainControllerName, DnsDomainName, AuthIdentity, ServicePrincipalName, phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindWithSpnExW(PWSTR DomainControllerName, PWSTR DnsDomainName, void* AuthIdentity, PWSTR ServicePrincipalName, uint32 BindFlags, HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindWithSpnExA(PSTR DomainControllerName, PSTR DnsDomainName, void* AuthIdentity, PSTR ServicePrincipalName, uint32 BindFlags, HANDLE* phDS);
	public static uint32 DsBindWithSpnEx(PSTR DomainControllerName, PSTR DnsDomainName, void* AuthIdentity, PSTR ServicePrincipalName, uint32 BindFlags, HANDLE* phDS) => DsBindWithSpnExA(DomainControllerName, DnsDomainName, AuthIdentity, ServicePrincipalName, BindFlags, phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindByInstanceW(PWSTR ServerName, PWSTR Annotation, Guid* InstanceGuid, PWSTR DnsDomainName, void* AuthIdentity, PWSTR ServicePrincipalName, uint32 BindFlags, HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindByInstanceA(PSTR ServerName, PSTR Annotation, Guid* InstanceGuid, PSTR DnsDomainName, void* AuthIdentity, PSTR ServicePrincipalName, uint32 BindFlags, HANDLE* phDS);
	public static uint32 DsBindByInstance(PSTR ServerName, PSTR Annotation, Guid* InstanceGuid, PSTR DnsDomainName, void* AuthIdentity, PSTR ServicePrincipalName, uint32 BindFlags, HANDLE* phDS) => DsBindByInstanceA(ServerName, Annotation, InstanceGuid, DnsDomainName, AuthIdentity, ServicePrincipalName, BindFlags, phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindToISTGW(PWSTR SiteName, HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindToISTGA(PSTR SiteName, HANDLE* phDS);
	public static uint32 DsBindToISTG(PSTR SiteName, HANDLE* phDS) => DsBindToISTGA(SiteName, phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsBindingSetTimeout(HANDLE hDS, uint32 cTimeoutSecs);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsUnBindW(HANDLE* phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsUnBindA(HANDLE* phDS);
	public static uint32 DsUnBind(HANDLE* phDS) => DsUnBindA(phDS);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMakePasswordCredentialsW(PWSTR User, PWSTR Domain, PWSTR Password, void** pAuthIdentity);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMakePasswordCredentialsA(PSTR User, PSTR Domain, PSTR Password, void** pAuthIdentity);
	public static uint32 DsMakePasswordCredentials(PSTR User, PSTR Domain, PSTR Password, void** pAuthIdentity) => DsMakePasswordCredentialsA(User, Domain, Password, pAuthIdentity);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreePasswordCredentials(void* AuthIdentity);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackNamesW(HANDLE hDS, DS_NAME_FLAGS flags, DS_NAME_FORMAT formatOffered, DS_NAME_FORMAT formatDesired, uint32 cNames, PWSTR* rpNames, DS_NAME_RESULTW** ppResult);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsCrackNamesA(HANDLE hDS, DS_NAME_FLAGS flags, DS_NAME_FORMAT formatOffered, DS_NAME_FORMAT formatDesired, uint32 cNames, PSTR* rpNames, DS_NAME_RESULTA** ppResult);
	public static uint32 DsCrackNames(HANDLE hDS, DS_NAME_FLAGS flags, DS_NAME_FORMAT formatOffered, DS_NAME_FORMAT formatDesired, uint32 cNames, PSTR* rpNames, DS_NAME_RESULTA** ppResult) => DsCrackNamesA(hDS, flags, formatOffered, formatDesired, cNames, rpNames, ppResult);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeNameResultW(DS_NAME_RESULTW* pResult);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeNameResultA(DS_NAME_RESULTA* pResult);
	public static void DsFreeNameResult(DS_NAME_RESULTA* pResult) => DsFreeNameResultA(pResult);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetSpnA(DS_SPN_NAME_TYPE ServiceType, PSTR ServiceClass, PSTR ServiceName, uint16 InstancePort, uint16 cInstanceNames, PSTR* pInstanceNames, uint16* pInstancePorts, uint32* pcSpn, PSTR** prpszSpn);
	public static uint32 DsGetSpn(DS_SPN_NAME_TYPE ServiceType, PSTR ServiceClass, PSTR ServiceName, uint16 InstancePort, uint16 cInstanceNames, PSTR* pInstanceNames, uint16* pInstancePorts, uint32* pcSpn, PSTR** prpszSpn) => DsGetSpnA(ServiceType, ServiceClass, ServiceName, InstancePort, cInstanceNames, pInstanceNames, pInstancePorts, pcSpn, prpszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetSpnW(DS_SPN_NAME_TYPE ServiceType, PWSTR ServiceClass, PWSTR ServiceName, uint16 InstancePort, uint16 cInstanceNames, PWSTR* pInstanceNames, uint16* pInstancePorts, uint32* pcSpn, PWSTR** prpszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeSpnArrayA(uint32 cSpn, PSTR* rpszSpn);
	public static void DsFreeSpnArray(uint32 cSpn, PSTR* rpszSpn) => DsFreeSpnArrayA(cSpn, rpszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeSpnArrayW(uint32 cSpn, PWSTR* rpszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsWriteAccountSpnA(HANDLE hDS, DS_SPN_WRITE_OP Operation, PSTR pszAccount, uint32 cSpn, PSTR* rpszSpn);
	public static uint32 DsWriteAccountSpn(HANDLE hDS, DS_SPN_WRITE_OP Operation, PSTR pszAccount, uint32 cSpn, PSTR* rpszSpn) => DsWriteAccountSpnA(hDS, Operation, pszAccount, cSpn, rpszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsWriteAccountSpnW(HANDLE hDS, DS_SPN_WRITE_OP Operation, PWSTR pszAccount, uint32 cSpn, PWSTR* rpszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsClientMakeSpnForTargetServerW(PWSTR ServiceClass, PWSTR ServiceName, uint32* pcSpnLength, char16* pszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsClientMakeSpnForTargetServerA(PSTR ServiceClass, PSTR ServiceName, uint32* pcSpnLength, uint8* pszSpn);
	public static uint32 DsClientMakeSpnForTargetServer(PSTR ServiceClass, PSTR ServiceName, uint32* pcSpnLength, uint8* pszSpn) => DsClientMakeSpnForTargetServerA(ServiceClass, ServiceName, pcSpnLength, pszSpn);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsServerRegisterSpnA(DS_SPN_WRITE_OP Operation, PSTR ServiceClass, PSTR UserObjectDN);
	public static uint32 DsServerRegisterSpn(DS_SPN_WRITE_OP Operation, PSTR ServiceClass, PSTR UserObjectDN) => DsServerRegisterSpnA(Operation, ServiceClass, UserObjectDN);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsServerRegisterSpnW(DS_SPN_WRITE_OP Operation, PWSTR ServiceClass, PWSTR UserObjectDN);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaSyncA(HANDLE hDS, PSTR NameContext, in Guid pUuidDsaSrc, uint32 Options);
	public static uint32 DsReplicaSync(HANDLE hDS, PSTR NameContext, in Guid pUuidDsaSrc, uint32 Options) => DsReplicaSyncA(hDS, NameContext, pUuidDsaSrc, Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaSyncW(HANDLE hDS, PWSTR NameContext, in Guid pUuidDsaSrc, uint32 Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaAddA(HANDLE hDS, PSTR NameContext, PSTR SourceDsaDn, PSTR TransportDn, PSTR SourceDsaAddress, SCHEDULE* pSchedule, uint32 Options);
	public static uint32 DsReplicaAdd(HANDLE hDS, PSTR NameContext, PSTR SourceDsaDn, PSTR TransportDn, PSTR SourceDsaAddress, SCHEDULE* pSchedule, uint32 Options) => DsReplicaAddA(hDS, NameContext, SourceDsaDn, TransportDn, SourceDsaAddress, pSchedule, Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaAddW(HANDLE hDS, PWSTR NameContext, PWSTR SourceDsaDn, PWSTR TransportDn, PWSTR SourceDsaAddress, SCHEDULE* pSchedule, uint32 Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaDelA(HANDLE hDS, PSTR NameContext, PSTR DsaSrc, uint32 Options);
	public static uint32 DsReplicaDel(HANDLE hDS, PSTR NameContext, PSTR DsaSrc, uint32 Options) => DsReplicaDelA(hDS, NameContext, DsaSrc, Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaDelW(HANDLE hDS, PWSTR NameContext, PWSTR DsaSrc, uint32 Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaModifyA(HANDLE hDS, PSTR NameContext, Guid* pUuidSourceDsa, PSTR TransportDn, PSTR SourceDsaAddress, SCHEDULE* pSchedule, uint32 ReplicaFlags, uint32 ModifyFields, uint32 Options);
	public static uint32 DsReplicaModify(HANDLE hDS, PSTR NameContext, Guid* pUuidSourceDsa, PSTR TransportDn, PSTR SourceDsaAddress, SCHEDULE* pSchedule, uint32 ReplicaFlags, uint32 ModifyFields, uint32 Options) => DsReplicaModifyA(hDS, NameContext, pUuidSourceDsa, TransportDn, SourceDsaAddress, pSchedule, ReplicaFlags, ModifyFields, Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaModifyW(HANDLE hDS, PWSTR NameContext, Guid* pUuidSourceDsa, PWSTR TransportDn, PWSTR SourceDsaAddress, SCHEDULE* pSchedule, uint32 ReplicaFlags, uint32 ModifyFields, uint32 Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaUpdateRefsA(HANDLE hDS, PSTR NameContext, PSTR DsaDest, in Guid pUuidDsaDest, uint32 Options);
	public static uint32 DsReplicaUpdateRefs(HANDLE hDS, PSTR NameContext, PSTR DsaDest, in Guid pUuidDsaDest, uint32 Options) => DsReplicaUpdateRefsA(hDS, NameContext, DsaDest, pUuidDsaDest, Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaUpdateRefsW(HANDLE hDS, PWSTR NameContext, PWSTR DsaDest, in Guid pUuidDsaDest, uint32 Options);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaSyncAllA(HANDLE hDS, PSTR pszNameContext, uint32 ulFlags, int pFnCallBack, void* pCallbackData, DS_REPSYNCALL_ERRINFOA*** pErrors);
	public static uint32 DsReplicaSyncAll(HANDLE hDS, PSTR pszNameContext, uint32 ulFlags, int pFnCallBack, void* pCallbackData, DS_REPSYNCALL_ERRINFOA*** pErrors) => DsReplicaSyncAllA(hDS, pszNameContext, ulFlags, pFnCallBack, pCallbackData, pErrors);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaSyncAllW(HANDLE hDS, PWSTR pszNameContext, uint32 ulFlags, int pFnCallBack, void* pCallbackData, DS_REPSYNCALL_ERRINFOW*** pErrors);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsRemoveDsServerW(HANDLE hDs, PWSTR ServerDN, PWSTR DomainDN, BOOL* fLastDcInDomain, BOOL fCommit);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsRemoveDsServerA(HANDLE hDs, PSTR ServerDN, PSTR DomainDN, BOOL* fLastDcInDomain, BOOL fCommit);
	public static uint32 DsRemoveDsServer(HANDLE hDs, PSTR ServerDN, PSTR DomainDN, BOOL* fLastDcInDomain, BOOL fCommit) => DsRemoveDsServerA(hDs, ServerDN, DomainDN, fLastDcInDomain, fCommit);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsRemoveDsDomainW(HANDLE hDs, PWSTR DomainDN);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsRemoveDsDomainA(HANDLE hDs, PSTR DomainDN);
	public static uint32 DsRemoveDsDomain(HANDLE hDs, PSTR DomainDN) => DsRemoveDsDomainA(hDs, DomainDN);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListSitesA(HANDLE hDs, DS_NAME_RESULTA** ppSites);
	public static uint32 DsListSites(HANDLE hDs, DS_NAME_RESULTA** ppSites) => DsListSitesA(hDs, ppSites);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListSitesW(HANDLE hDs, DS_NAME_RESULTW** ppSites);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListServersInSiteA(HANDLE hDs, PSTR site, DS_NAME_RESULTA** ppServers);
	public static uint32 DsListServersInSite(HANDLE hDs, PSTR site, DS_NAME_RESULTA** ppServers) => DsListServersInSiteA(hDs, site, ppServers);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListServersInSiteW(HANDLE hDs, PWSTR site, DS_NAME_RESULTW** ppServers);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListDomainsInSiteA(HANDLE hDs, PSTR site, DS_NAME_RESULTA** ppDomains);
	public static uint32 DsListDomainsInSite(HANDLE hDs, PSTR site, DS_NAME_RESULTA** ppDomains) => DsListDomainsInSiteA(hDs, site, ppDomains);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListDomainsInSiteW(HANDLE hDs, PWSTR site, DS_NAME_RESULTW** ppDomains);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListServersForDomainInSiteA(HANDLE hDs, PSTR domain, PSTR site, DS_NAME_RESULTA** ppServers);
	public static uint32 DsListServersForDomainInSite(HANDLE hDs, PSTR domain, PSTR site, DS_NAME_RESULTA** ppServers) => DsListServersForDomainInSiteA(hDs, domain, site, ppServers);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListServersForDomainInSiteW(HANDLE hDs, PWSTR domain, PWSTR site, DS_NAME_RESULTW** ppServers);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListInfoForServerA(HANDLE hDs, PSTR server, DS_NAME_RESULTA** ppInfo);
	public static uint32 DsListInfoForServer(HANDLE hDs, PSTR server, DS_NAME_RESULTA** ppInfo) => DsListInfoForServerA(hDs, server, ppInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListInfoForServerW(HANDLE hDs, PWSTR server, DS_NAME_RESULTW** ppInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListRolesA(HANDLE hDs, DS_NAME_RESULTA** ppRoles);
	public static uint32 DsListRoles(HANDLE hDs, DS_NAME_RESULTA** ppRoles) => DsListRolesA(hDs, ppRoles);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsListRolesW(HANDLE hDs, DS_NAME_RESULTW** ppRoles);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsQuerySitesByCostW(HANDLE hDS, PWSTR pwszFromSite, PWSTR* rgwszToSites, uint32 cToSites, uint32 dwFlags, DS_SITE_COST_INFO** prgSiteInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsQuerySitesByCostA(HANDLE hDS, PSTR pszFromSite, PSTR* rgszToSites, uint32 cToSites, uint32 dwFlags, DS_SITE_COST_INFO** prgSiteInfo);
	public static uint32 DsQuerySitesByCost(HANDLE hDS, PSTR pszFromSite, PSTR* rgszToSites, uint32 cToSites, uint32 dwFlags, DS_SITE_COST_INFO** prgSiteInfo) => DsQuerySitesByCostA(hDS, pszFromSite, rgszToSites, cToSites, dwFlags, prgSiteInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsQuerySitesFree(DS_SITE_COST_INFO* rgSiteInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMapSchemaGuidsA(HANDLE hDs, uint32 cGuids, Guid* rGuids, DS_SCHEMA_GUID_MAPA** ppGuidMap);
	public static uint32 DsMapSchemaGuids(HANDLE hDs, uint32 cGuids, Guid* rGuids, DS_SCHEMA_GUID_MAPA** ppGuidMap) => DsMapSchemaGuidsA(hDs, cGuids, rGuids, ppGuidMap);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeSchemaGuidMapA(DS_SCHEMA_GUID_MAPA* pGuidMap);
	public static void DsFreeSchemaGuidMap(DS_SCHEMA_GUID_MAPA* pGuidMap) => DsFreeSchemaGuidMapA(pGuidMap);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMapSchemaGuidsW(HANDLE hDs, uint32 cGuids, Guid* rGuids, DS_SCHEMA_GUID_MAPW** ppGuidMap);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeSchemaGuidMapW(DS_SCHEMA_GUID_MAPW* pGuidMap);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDomainControllerInfoA(HANDLE hDs, PSTR DomainName, uint32 InfoLevel, uint32* pcOut, void** ppInfo);
	public static uint32 DsGetDomainControllerInfo(HANDLE hDs, PSTR DomainName, uint32 InfoLevel, uint32* pcOut, void** ppInfo) => DsGetDomainControllerInfoA(hDs, DomainName, InfoLevel, pcOut, ppInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDomainControllerInfoW(HANDLE hDs, PWSTR DomainName, uint32 InfoLevel, uint32* pcOut, void** ppInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeDomainControllerInfoA(uint32 InfoLevel, uint32 cInfo, void* pInfo);
	public static void DsFreeDomainControllerInfo(uint32 InfoLevel, uint32 cInfo, void* pInfo) => DsFreeDomainControllerInfoA(InfoLevel, cInfo, pInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsFreeDomainControllerInfoW(uint32 InfoLevel, uint32 cInfo, void* pInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaConsistencyCheck(HANDLE hDS, DS_KCC_TASKID TaskID, uint32 dwFlags);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaVerifyObjectsW(HANDLE hDS, PWSTR NameContext, in Guid pUuidDsaSrc, uint32 ulOptions);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaVerifyObjectsA(HANDLE hDS, PSTR NameContext, in Guid pUuidDsaSrc, uint32 ulOptions);
	public static uint32 DsReplicaVerifyObjects(HANDLE hDS, PSTR NameContext, in Guid pUuidDsaSrc, uint32 ulOptions) => DsReplicaVerifyObjectsA(hDS, NameContext, pUuidDsaSrc, ulOptions);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaGetInfoW(HANDLE hDS, DS_REPL_INFO_TYPE InfoType, PWSTR pszObject, Guid* puuidForSourceDsaObjGuid, void** ppInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsReplicaGetInfo2W(HANDLE hDS, DS_REPL_INFO_TYPE InfoType, PWSTR pszObject, Guid* puuidForSourceDsaObjGuid, PWSTR pszAttributeName, PWSTR pszValue, uint32 dwFlags, uint32 dwEnumerationContext, void** ppInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsReplicaFreeInfo(DS_REPL_INFO_TYPE InfoType, void* pInfo);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsAddSidHistoryW(HANDLE hDS, uint32 Flags, PWSTR SrcDomain, PWSTR SrcPrincipal, PWSTR SrcDomainController, void* SrcDomainCreds, PWSTR DstDomain, PWSTR DstPrincipal);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsAddSidHistoryA(HANDLE hDS, uint32 Flags, PSTR SrcDomain, PSTR SrcPrincipal, PSTR SrcDomainController, void* SrcDomainCreds, PSTR DstDomain, PSTR DstPrincipal);
	public static uint32 DsAddSidHistory(HANDLE hDS, uint32 Flags, PSTR SrcDomain, PSTR SrcPrincipal, PSTR SrcDomainController, void* SrcDomainCreds, PSTR DstDomain, PSTR DstPrincipal) => DsAddSidHistoryA(hDS, Flags, SrcDomain, SrcPrincipal, SrcDomainController, SrcDomainCreds, DstDomain, DstPrincipal);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsInheritSecurityIdentityW(HANDLE hDS, uint32 Flags, PWSTR SrcPrincipal, PWSTR DstPrincipal);

	[Import("NTDSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsInheritSecurityIdentityA(HANDLE hDS, uint32 Flags, PSTR SrcPrincipal, PSTR DstPrincipal);
	public static uint32 DsInheritSecurityIdentity(HANDLE hDS, uint32 Flags, PSTR SrcPrincipal, PSTR DstPrincipal) => DsInheritSecurityIdentityA(hDS, Flags, SrcPrincipal, DstPrincipal);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsRoleGetPrimaryDomainInformation(PWSTR lpServer, DSROLE_PRIMARY_DOMAIN_INFO_LEVEL InfoLevel, uint8** Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsRoleFreeMemory(void* Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcNameA(PSTR ComputerName, PSTR DomainName, Guid* DomainGuid, PSTR SiteName, uint32 Flags, DOMAIN_CONTROLLER_INFOA** DomainControllerInfo);
	public static uint32 DsGetDcName(PSTR ComputerName, PSTR DomainName, Guid* DomainGuid, PSTR SiteName, uint32 Flags, DOMAIN_CONTROLLER_INFOA** DomainControllerInfo) => DsGetDcNameA(ComputerName, DomainName, DomainGuid, SiteName, Flags, DomainControllerInfo);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcNameW(PWSTR ComputerName, PWSTR DomainName, Guid* DomainGuid, PWSTR SiteName, uint32 Flags, DOMAIN_CONTROLLER_INFOW** DomainControllerInfo);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetSiteNameA(PSTR ComputerName, PSTR* SiteName);
	public static uint32 DsGetSiteName(PSTR ComputerName, PSTR* SiteName) => DsGetSiteNameA(ComputerName, SiteName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetSiteNameW(PWSTR ComputerName, PWSTR* SiteName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsValidateSubnetNameW(PWSTR SubnetName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsValidateSubnetNameA(PSTR SubnetName);
	public static uint32 DsValidateSubnetName(PSTR SubnetName) => DsValidateSubnetNameA(SubnetName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsAddressToSiteNamesW(PWSTR ComputerName, uint32 EntryCount, SOCKET_ADDRESS* SocketAddresses, PWSTR** SiteNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsAddressToSiteNamesA(PSTR ComputerName, uint32 EntryCount, SOCKET_ADDRESS* SocketAddresses, PSTR** SiteNames);
	public static uint32 DsAddressToSiteNames(PSTR ComputerName, uint32 EntryCount, SOCKET_ADDRESS* SocketAddresses, PSTR** SiteNames) => DsAddressToSiteNamesA(ComputerName, EntryCount, SocketAddresses, SiteNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsAddressToSiteNamesExW(PWSTR ComputerName, uint32 EntryCount, SOCKET_ADDRESS* SocketAddresses, PWSTR** SiteNames, PWSTR** SubnetNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsAddressToSiteNamesExA(PSTR ComputerName, uint32 EntryCount, SOCKET_ADDRESS* SocketAddresses, PSTR** SiteNames, PSTR** SubnetNames);
	public static uint32 DsAddressToSiteNamesEx(PSTR ComputerName, uint32 EntryCount, SOCKET_ADDRESS* SocketAddresses, PSTR** SiteNames, PSTR** SubnetNames) => DsAddressToSiteNamesExA(ComputerName, EntryCount, SocketAddresses, SiteNames, SubnetNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsEnumerateDomainTrustsW(PWSTR ServerName, uint32 Flags, DS_DOMAIN_TRUSTSW** Domains, uint32* DomainCount);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsEnumerateDomainTrustsA(PSTR ServerName, uint32 Flags, DS_DOMAIN_TRUSTSA** Domains, uint32* DomainCount);
	public static uint32 DsEnumerateDomainTrusts(PSTR ServerName, uint32 Flags, DS_DOMAIN_TRUSTSA** Domains, uint32* DomainCount) => DsEnumerateDomainTrustsA(ServerName, Flags, Domains, DomainCount);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetForestTrustInformationW(PWSTR ServerName, PWSTR TrustedDomainName, uint32 Flags, LSA_FOREST_TRUST_INFORMATION** ForestTrustInfo);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsMergeForestTrustInformationW(PWSTR DomainName, LSA_FOREST_TRUST_INFORMATION* NewForestTrustInfo, LSA_FOREST_TRUST_INFORMATION* OldForestTrustInfo, LSA_FOREST_TRUST_INFORMATION** MergedForestTrustInfo);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcSiteCoverageW(PWSTR ServerName, uint32* EntryCount, PWSTR** SiteNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcSiteCoverageA(PSTR ServerName, uint32* EntryCount, PSTR** SiteNames);
	public static uint32 DsGetDcSiteCoverage(PSTR ServerName, uint32* EntryCount, PSTR** SiteNames) => DsGetDcSiteCoverageA(ServerName, EntryCount, SiteNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsDeregisterDnsHostRecordsW(PWSTR ServerName, PWSTR DnsDomainName, Guid* DomainGuid, Guid* DsaGuid, PWSTR DnsHostName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsDeregisterDnsHostRecordsA(PSTR ServerName, PSTR DnsDomainName, Guid* DomainGuid, Guid* DsaGuid, PSTR DnsHostName);
	public static uint32 DsDeregisterDnsHostRecords(PSTR ServerName, PSTR DnsDomainName, Guid* DomainGuid, Guid* DsaGuid, PSTR DnsHostName) => DsDeregisterDnsHostRecordsA(ServerName, DnsDomainName, DomainGuid, DsaGuid, DnsHostName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcOpenW(PWSTR DnsName, uint32 OptionFlags, PWSTR SiteName, Guid* DomainGuid, PWSTR DnsForestName, uint32 DcFlags, GetDcContextHandle* RetGetDcContext);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcOpenA(PSTR DnsName, uint32 OptionFlags, PSTR SiteName, Guid* DomainGuid, PSTR DnsForestName, uint32 DcFlags, GetDcContextHandle* RetGetDcContext);
	public static uint32 DsGetDcOpen(PSTR DnsName, uint32 OptionFlags, PSTR SiteName, Guid* DomainGuid, PSTR DnsForestName, uint32 DcFlags, GetDcContextHandle* RetGetDcContext) => DsGetDcOpenA(DnsName, OptionFlags, SiteName, DomainGuid, DnsForestName, DcFlags, RetGetDcContext);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcNextW(HANDLE GetDcContextHandle, uint32* SockAddressCount, SOCKET_ADDRESS** SockAddresses, PWSTR* DnsHostName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DsGetDcNextA(HANDLE GetDcContextHandle, uint32* SockAddressCount, SOCKET_ADDRESS** SockAddresses, PSTR* DnsHostName);
	public static uint32 DsGetDcNext(HANDLE GetDcContextHandle, uint32* SockAddressCount, SOCKET_ADDRESS** SockAddresses, PSTR* DnsHostName) => DsGetDcNextA(GetDcContextHandle, SockAddressCount, SockAddresses, DnsHostName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DsGetDcCloseW(GetDcContextHandle GetDcContextHandle);

}
#endregion
