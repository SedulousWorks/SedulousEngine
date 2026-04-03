using Win32.Foundation;
using Win32.Storage.IndexServer;
using Win32.System.Com;
using Win32.System.Com.StructuredStorage;
using Win32.System.Search.Common;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.DistributedTransactionCoordinator;
using Win32.Security.Authorization;
using Win32.UI.Shell.Common;
using System;

namespace Win32.System.Search;

#region Constants
public static
{
	public const uint32 SI_TEMPORARY = 2147483648;
	public const uint32 SUBSINFO_ALLFLAGS = 61311;
	public const uint32 RS_READY = 1;
	public const uint32 RS_SUSPENDED = 2;
	public const uint32 RS_UPDATING = 4;
	public const uint32 RS_SUSPENDONIDLE = 65536;
	public const uint32 RS_MAYBOTHERUSER = 131072;
	public const uint32 RS_COMPLETED = 2147483648;
	public const uint32 SUBSMGRUPDATE_MINIMIZE = 1;
	public const uint32 SUBSMGRUPDATE_MASK = 1;
	public const uint32 SUBSMGRENUM_TEMP = 1;
	public const uint32 SUBSMGRENUM_MASK = 1;
	public const HRESULT INET_E_AGENT_MAX_SIZE_EXCEEDED = -2146693248;
	public const HRESULT INET_S_AGENT_PART_FAIL = 790401;
	public const HRESULT INET_E_AGENT_CACHE_SIZE_EXCEEDED = -2146693246;
	public const HRESULT INET_E_AGENT_CONNECTION_FAILED = -2146693245;
	public const HRESULT INET_E_SCHEDULED_UPDATES_DISABLED = -2146693244;
	public const HRESULT INET_E_SCHEDULED_UPDATES_RESTRICTED = -2146693243;
	public const HRESULT INET_E_SCHEDULED_UPDATE_INTERVAL = -2146693242;
	public const HRESULT INET_E_SCHEDULED_EXCLUDE_RANGE = -2146693241;
	public const HRESULT INET_E_AGENT_EXCEEDING_CACHE_SIZE = -2146693232;
	public const HRESULT INET_S_AGENT_INCREASED_CACHE_SIZE = 790416;
	public const uint32 OLEDBVER = 624;
	public const uint32 DB_NULL_HACCESSOR = 0;
	public const uint32 DB_INVALID_HACCESSOR = 0;
	public const uint32 DB_NULL_HROW = 0;
	public const uint32 DB_NULL_HCHAPTER = 0;
	public const uint32 DB_INVALID_HCHAPTER = 0;
	public const uint32 STD_BOOKMARKLENGTH = 1;
	public const int32 DBPROPVAL_BMK_NUMERIC = 1;
	public const int32 DBPROPVAL_BMK_KEY = 2;
	public const int32 DBPROPVAL_CL_START = 1;
	public const int32 DBPROPVAL_CL_END = 2;
	public const int32 DBPROPVAL_CU_DML_STATEMENTS = 1;
	public const int32 DBPROPVAL_CU_TABLE_DEFINITION = 2;
	public const int32 DBPROPVAL_CU_INDEX_DEFINITION = 4;
	public const int32 DBPROPVAL_CU_PRIVILEGE_DEFINITION = 8;
	public const int32 DBPROPVAL_CD_NOTNULL = 1;
	public const int32 DBPROPVAL_CB_NULL = 1;
	public const int32 DBPROPVAL_CB_NON_NULL = 2;
	public const int32 DBPROPVAL_FU_NOT_SUPPORTED = 1;
	public const int32 DBPROPVAL_FU_COLUMN = 2;
	public const int32 DBPROPVAL_FU_TABLE = 4;
	public const int32 DBPROPVAL_FU_CATALOG = 8;
	public const int32 DBPROPVAL_GB_NOT_SUPPORTED = 1;
	public const int32 DBPROPVAL_GB_EQUALS_SELECT = 2;
	public const int32 DBPROPVAL_GB_CONTAINS_SELECT = 4;
	public const int32 DBPROPVAL_GB_NO_RELATION = 8;
	public const int32 DBPROPVAL_HT_DIFFERENT_CATALOGS = 1;
	public const int32 DBPROPVAL_HT_DIFFERENT_PROVIDERS = 2;
	public const int32 DBPROPVAL_IC_UPPER = 1;
	public const int32 DBPROPVAL_IC_LOWER = 2;
	public const int32 DBPROPVAL_IC_SENSITIVE = 4;
	public const int32 DBPROPVAL_IC_MIXED = 8;
	public const int32 DBPROPVAL_LM_NONE = 1;
	public const int32 DBPROPVAL_LM_READ = 2;
	public const int32 DBPROPVAL_LM_INTENT = 4;
	public const int32 DBPROPVAL_LM_RITE = 8;
	public const int32 DBPROPVAL_NP_OKTODO = 1;
	public const int32 DBPROPVAL_NP_ABOUTTODO = 2;
	public const int32 DBPROPVAL_NP_SYNCHAFTER = 4;
	public const int32 DBPROPVAL_NP_FAILEDTODO = 8;
	public const int32 DBPROPVAL_NP_DIDEVENT = 16;
	public const int32 DBPROPVAL_NC_END = 1;
	public const int32 DBPROPVAL_NC_HIGH = 2;
	public const int32 DBPROPVAL_NC_LOW = 4;
	public const int32 DBPROPVAL_NC_START = 8;
	public const int32 DBPROPVAL_OO_BLOB = 1;
	public const int32 DBPROPVAL_OO_IPERSIST = 2;
	public const int32 DBPROPVAL_CB_DELETE = 1;
	public const int32 DBPROPVAL_CB_PRESERVE = 2;
	public const int32 DBPROPVAL_SU_DML_STATEMENTS = 1;
	public const int32 DBPROPVAL_SU_TABLE_DEFINITION = 2;
	public const int32 DBPROPVAL_SU_INDEX_DEFINITION = 4;
	public const int32 DBPROPVAL_SU_PRIVILEGE_DEFINITION = 8;
	public const int32 DBPROPVAL_SQ_CORRELATEDSUBQUERIES = 1;
	public const int32 DBPROPVAL_SQ_COMPARISON = 2;
	public const int32 DBPROPVAL_SQ_EXISTS = 4;
	public const int32 DBPROPVAL_SQ_IN = 8;
	public const int32 DBPROPVAL_SQ_QUANTIFIED = 16;
	public const int32 DBPROPVAL_SQ_TABLE = 32;
	public const int32 DBPROPVAL_SS_ISEQUENTIALSTREAM = 1;
	public const int32 DBPROPVAL_SS_ISTREAM = 2;
	public const int32 DBPROPVAL_SS_ISTORAGE = 4;
	public const int32 DBPROPVAL_SS_ILOCKBYTES = 8;
	public const int32 DBPROPVAL_TI_CHAOS = 16;
	public const int32 DBPROPVAL_TI_READUNCOMMITTED = 256;
	public const int32 DBPROPVAL_TI_BROWSE = 256;
	public const int32 DBPROPVAL_TI_CURSORSTABILITY = 4096;
	public const int32 DBPROPVAL_TI_READCOMMITTED = 4096;
	public const int32 DBPROPVAL_TI_REPEATABLEREAD = 65536;
	public const int32 DBPROPVAL_TI_SERIALIZABLE = 1048576;
	public const int32 DBPROPVAL_TI_ISOLATED = 1048576;
	public const int32 DBPROPVAL_TR_COMMIT_DC = 1;
	public const int32 DBPROPVAL_TR_COMMIT = 2;
	public const int32 DBPROPVAL_TR_COMMIT_NO = 4;
	public const int32 DBPROPVAL_TR_ABORT_DC = 8;
	public const int32 DBPROPVAL_TR_ABORT = 16;
	public const int32 DBPROPVAL_TR_ABORT_NO = 32;
	public const int32 DBPROPVAL_TR_DONTCARE = 64;
	public const int32 DBPROPVAL_TR_BOTH = 128;
	public const int32 DBPROPVAL_TR_NONE = 256;
	public const int32 DBPROPVAL_TR_OPTIMISTIC = 512;
	public const int32 DBPROPVAL_RT_FREETHREAD = 1;
	public const int32 DBPROPVAL_RT_APTMTTHREAD = 2;
	public const int32 DBPROPVAL_RT_SINGLETHREAD = 4;
	public const int32 DBPROPVAL_UP_CHANGE = 1;
	public const int32 DBPROPVAL_UP_DELETE = 2;
	public const int32 DBPROPVAL_UP_INSERT = 4;
	public const int32 DBPROPVAL_SQL_NONE = 0;
	public const int32 DBPROPVAL_SQL_ODBC_MINIMUM = 1;
	public const int32 DBPROPVAL_SQL_ODBC_CORE = 2;
	public const int32 DBPROPVAL_SQL_ODBC_EXTENDED = 4;
	public const int32 DBPROPVAL_SQL_ANSI89_IEF = 8;
	public const int32 DBPROPVAL_SQL_ANSI92_ENTRY = 16;
	public const int32 DBPROPVAL_SQL_FIPS_TRANSITIONAL = 32;
	public const int32 DBPROPVAL_SQL_ANSI92_INTERMEDIATE = 64;
	public const int32 DBPROPVAL_SQL_ANSI92_FULL = 128;
	public const int32 DBPROPVAL_SQL_ESCAPECLAUSES = 256;
	public const int32 DBPROPVAL_IT_BTREE = 1;
	public const int32 DBPROPVAL_IT_HASH = 2;
	public const int32 DBPROPVAL_IT_CONTENT = 3;
	public const int32 DBPROPVAL_IT_OTHER = 4;
	public const int32 DBPROPVAL_IN_DISALLOWNULL = 1;
	public const int32 DBPROPVAL_IN_IGNORENULL = 2;
	public const int32 DBPROPVAL_IN_IGNOREANYNULL = 4;
	public const int32 DBPROPVAL_TC_NONE = 0;
	public const int32 DBPROPVAL_TC_DML = 1;
	public const int32 DBPROPVAL_TC_DDL_COMMIT = 2;
	public const int32 DBPROPVAL_TC_DDL_IGNORE = 4;
	public const int32 DBPROPVAL_TC_ALL = 8;
	public const int32 DBPROPVAL_OA_NOTSUPPORTED = 1;
	public const int32 DBPROPVAL_OA_ATEXECUTE = 2;
	public const int32 DBPROPVAL_OA_ATROWRELEASE = 4;
	public const int32 DBPROPVAL_MR_NOTSUPPORTED = 0;
	public const int32 DBPROPVAL_MR_SUPPORTED = 1;
	public const int32 DBPROPVAL_MR_CONCURRENT = 2;
	public const int32 DBPROPVAL_PT_GUID_NAME = 1;
	public const int32 DBPROPVAL_PT_GUID_PROPID = 2;
	public const int32 DBPROPVAL_PT_NAME = 4;
	public const int32 DBPROPVAL_PT_GUID = 8;
	public const int32 DBPROPVAL_PT_PROPID = 16;
	public const int32 DBPROPVAL_PT_PGUID_NAME = 32;
	public const int32 DBPROPVAL_PT_PGUID_PROPID = 64;
	public const int32 DBPROPVAL_NT_SINGLEROW = 1;
	public const int32 DBPROPVAL_NT_MULTIPLEROWS = 2;
	public const int32 DBPROPVAL_ASYNCH_INITIALIZE = 1;
	public const int32 DBPROPVAL_ASYNCH_SEQUENTIALPOPULATION = 2;
	public const int32 DBPROPVAL_ASYNCH_RANDOMPOPULATION = 4;
	public const int32 DBPROPVAL_OP_EQUAL = 1;
	public const int32 DBPROPVAL_OP_RELATIVE = 2;
	public const int32 DBPROPVAL_OP_STRING = 4;
	public const int32 DBPROPVAL_CO_EQUALITY = 1;
	public const int32 DBPROPVAL_CO_STRING = 2;
	public const int32 DBPROPVAL_CO_CASESENSITIVE = 4;
	public const int32 DBPROPVAL_CO_CASEINSENSITIVE = 8;
	public const int32 DBPROPVAL_CO_CONTAINS = 16;
	public const int32 DBPROPVAL_CO_BEGINSWITH = 32;
	public const int32 DBPROPVAL_ASYNCH_BACKGROUNDPOPULATION = 8;
	public const int32 DBPROPVAL_ASYNCH_PREPOPULATE = 16;
	public const int32 DBPROPVAL_ASYNCH_POPULATEONDEMAND = 32;
	public const int32 DBPROPVAL_LM_SINGLEROW = 2;
	public const int32 DBPROPVAL_SQL_SUBMINIMUM = 512;
	public const int32 DBPROPVAL_DST_TDP = 1;
	public const int32 DBPROPVAL_DST_MDP = 2;
	public const int32 DBPROPVAL_DST_TDPANDMDP = 3;
	public const int32 MDPROPVAL_AU_UNSUPPORTED = 0;
	public const int32 MDPROPVAL_AU_UNCHANGED = 1;
	public const int32 MDPROPVAL_AU_UNKNOWN = 2;
	public const int32 MDPROPVAL_MF_WITH_CALCMEMBERS = 1;
	public const int32 MDPROPVAL_MF_WITH_NAMEDSETS = 2;
	public const int32 MDPROPVAL_MF_CREATE_CALCMEMBERS = 4;
	public const int32 MDPROPVAL_MF_CREATE_NAMEDSETS = 8;
	public const int32 MDPROPVAL_MF_SCOPE_SESSION = 16;
	public const int32 MDPROPVAL_MF_SCOPE_GLOBAL = 32;
	public const int32 MDPROPVAL_MMF_COUSIN = 1;
	public const int32 MDPROPVAL_MMF_PARALLELPERIOD = 2;
	public const int32 MDPROPVAL_MMF_OPENINGPERIOD = 4;
	public const int32 MDPROPVAL_MMF_CLOSINGPERIOD = 8;
	public const int32 MDPROPVAL_MNF_MEDIAN = 1;
	public const int32 MDPROPVAL_MNF_VAR = 2;
	public const int32 MDPROPVAL_MNF_STDDEV = 4;
	public const int32 MDPROPVAL_MNF_RANK = 8;
	public const int32 MDPROPVAL_MNF_AGGREGATE = 16;
	public const int32 MDPROPVAL_MNF_COVARIANCE = 32;
	public const int32 MDPROPVAL_MNF_CORRELATION = 64;
	public const int32 MDPROPVAL_MNF_LINREGSLOPE = 128;
	public const int32 MDPROPVAL_MNF_LINREGVARIANCE = 256;
	public const int32 MDPROPVAL_MNF_LINREG2 = 512;
	public const int32 MDPROPVAL_MNF_LINREGPOINT = 1024;
	public const int32 MDPROPVAL_MNF_DRILLDOWNLEVEL = 2048;
	public const int32 MDPROPVAL_MNF_DRILLDOWNMEMBERTOP = 4096;
	public const int32 MDPROPVAL_MNF_DRILLDOWNMEMBERBOTTOM = 8192;
	public const int32 MDPROPVAL_MNF_DRILLDOWNLEVELTOP = 16384;
	public const int32 MDPROPVAL_MNF_DRILLDOWNLEVELBOTTOM = 32768;
	public const int32 MDPROPVAL_MNF_DRILLUPMEMBER = 65536;
	public const int32 MDPROPVAL_MNF_DRILLUPLEVEL = 131072;
	public const int32 MDPROPVAL_MSF_TOPPERCENT = 1;
	public const int32 MDPROPVAL_MSF_BOTTOMPERCENT = 2;
	public const int32 MDPROPVAL_MSF_TOPSUM = 4;
	public const int32 MDPROPVAL_MSF_BOTTOMSUM = 8;
	public const int32 MDPROPVAL_MSF_PERIODSTODATE = 16;
	public const int32 MDPROPVAL_MSF_LASTPERIODS = 32;
	public const int32 MDPROPVAL_MSF_YTD = 64;
	public const int32 MDPROPVAL_MSF_QTD = 128;
	public const int32 MDPROPVAL_MSF_MTD = 256;
	public const int32 MDPROPVAL_MSF_WTD = 512;
	public const int32 MDPROPVAL_MSF_DRILLDOWNMEMBBER = 1024;
	public const int32 MDPROPVAL_MSF_DRILLDOWNLEVEL = 2048;
	public const int32 MDPROPVAL_MSF_DRILLDOWNMEMBERTOP = 4096;
	public const int32 MDPROPVAL_MSF_DRILLDOWNMEMBERBOTTOM = 8192;
	public const int32 MDPROPVAL_MSF_DRILLDOWNLEVELTOP = 16384;
	public const int32 MDPROPVAL_MSF_DRILLDOWNLEVELBOTTOM = 32768;
	public const int32 MDPROPVAL_MSF_DRILLUPMEMBER = 65536;
	public const int32 MDPROPVAL_MSF_DRILLUPLEVEL = 131072;
	public const int32 MDPROPVAL_MSF_TOGGLEDRILLSTATE = 262144;
	public const int32 MDPROPVAL_MD_SELF = 1;
	public const int32 MDPROPVAL_MD_BEFORE = 2;
	public const int32 MDPROPVAL_MD_AFTER = 4;
	public const int32 MDPROPVAL_MSC_LESSTHAN = 1;
	public const int32 MDPROPVAL_MSC_GREATERTHAN = 2;
	public const int32 MDPROPVAL_MSC_LESSTHANEQUAL = 4;
	public const int32 MDPROPVAL_MSC_GREATERTHANEQUAL = 8;
	public const int32 MDPROPVAL_MC_SINGLECASE = 1;
	public const int32 MDPROPVAL_MC_SEARCHEDCASE = 2;
	public const int32 MDPROPVAL_MOQ_OUTERREFERENCE = 1;
	public const int32 MDPROPVAL_MOQ_DATASOURCE_CUBE = 1;
	public const int32 MDPROPVAL_MOQ_CATALOG_CUBE = 2;
	public const int32 MDPROPVAL_MOQ_SCHEMA_CUBE = 4;
	public const int32 MDPROPVAL_MOQ_CUBE_DIM = 8;
	public const int32 MDPROPVAL_MOQ_DIM_HIER = 16;
	public const int32 MDPROPVAL_MOQ_DIMHIER_LEVEL = 32;
	public const int32 MDPROPVAL_MOQ_LEVEL_MEMBER = 64;
	public const int32 MDPROPVAL_MOQ_MEMBER_MEMBER = 128;
	public const int32 MDPROPVAL_MOQ_DIMHIER_MEMBER = 256;
	public const int32 MDPROPVAL_FS_FULL_SUPPORT = 1;
	public const int32 MDPROPVAL_FS_GENERATED_COLUMN = 2;
	public const int32 MDPROPVAL_FS_GENERATED_DIMENSION = 3;
	public const int32 MDPROPVAL_FS_NO_SUPPORT = 4;
	public const int32 MDPROPVAL_NL_NAMEDLEVELS = 1;
	public const int32 MDPROPVAL_NL_NUMBEREDLEVELS = 2;
	public const int32 MDPROPVAL_MJC_SINGLECUBE = 1;
	public const int32 MDPROPVAL_MJC_MULTICUBES = 2;
	public const int32 MDPROPVAL_MJC_IMPLICITCUBE = 4;
	public const int32 MDPROPVAL_RR_NORANGEROWSET = 1;
	public const int32 MDPROPVAL_RR_READONLY = 2;
	public const int32 MDPROPVAL_RR_UPDATE = 4;
	public const int32 MDPROPVAL_MS_MULTIPLETUPLES = 1;
	public const int32 MDPROPVAL_MS_SINGLETUPLE = 2;
	public const int32 MDPROPVAL_NME_ALLDIMENSIONS = 0;
	public const int32 MDPROPVAL_NME_MEASURESONLY = 1;
	public const int32 DBPROPVAL_AO_SEQUENTIAL = 0;
	public const int32 DBPROPVAL_AO_SEQUENTIALSTORAGEOBJECTS = 1;
	public const int32 DBPROPVAL_AO_RANDOM = 2;
	public const int32 DBPROPVAL_BD_ROWSET = 0;
	public const int32 DBPROPVAL_BD_INTRANSACTION = 1;
	public const int32 DBPROPVAL_BD_XTRANSACTION = 2;
	public const int32 DBPROPVAL_BD_REORGANIZATION = 3;
	public const int32 BMK_DURABILITY_ROWSET = 0;
	public const int32 BMK_DURABILITY_INTRANSACTION = 1;
	public const int32 BMK_DURABILITY_XTRANSACTION = 2;
	public const int32 BMK_DURABILITY_REORGANIZATION = 3;
	public const int32 DBPROPVAL_BO_NOLOG = 0;
	public const int32 DBPROPVAL_BO_NOINDEXUPDATE = 1;
	public const int32 DBPROPVAL_BO_REFINTEGRITY = 2;
	public const uint32 DBPROPVAL_STGM_DIRECT = 65536;
	public const uint32 DBPROPVAL_STGM_TRANSACTED = 131072;
	public const uint32 DBPROPVAL_STGM_CONVERT = 262144;
	public const uint32 DBPROPVAL_STGM_FAILIFTHERE = 524288;
	public const uint32 DBPROPVAL_STGM_PRIORITY = 1048576;
	public const uint32 DBPROPVAL_STGM_DELETEONRELEASE = 2097152;
	public const int32 DBPROPVAL_GB_COLLATE = 16;
	public const int32 DBPROPVAL_CS_UNINITIALIZED = 0;
	public const int32 DBPROPVAL_CS_INITIALIZED = 1;
	public const int32 DBPROPVAL_CS_COMMUNICATIONFAILURE = 2;
	public const int32 DBPROPVAL_RD_RESETALL = -1;
	public const int32 DBPROPVAL_OS_RESOURCEPOOLING = 1;
	public const int32 DBPROPVAL_OS_TXNENLISTMENT = 2;
	public const int32 DBPROPVAL_OS_CLIENTCURSOR = 4;
	public const int32 DBPROPVAL_OS_ENABLEALL = -1;
	public const int32 DBPROPVAL_BI_CROSSROWSET = 1;
	public const int32 MDPROPVAL_NL_SCHEMAONLY = 4;
	public const int32 DBPROPVAL_OS_DISABLEALL = 0;
	public const int32 DBPROPVAL_OO_ROWOBJECT = 4;
	public const int32 DBPROPVAL_OO_SCOPED = 8;
	public const int32 DBPROPVAL_OO_DIRECTBIND = 16;
	public const int32 DBPROPVAL_DST_DOCSOURCE = 4;
	public const int32 DBPROPVAL_GU_NOTSUPPORTED = 1;
	public const int32 DBPROPVAL_GU_SUFFIX = 2;
	public const int32 DB_BINDFLAGS_DELAYFETCHCOLUMNS = 1;
	public const int32 DB_BINDFLAGS_DELAYFETCHSTREAM = 2;
	public const int32 DB_BINDFLAGS_RECURSIVE = 4;
	public const int32 DB_BINDFLAGS_OUTPUT = 8;
	public const int32 DB_BINDFLAGS_COLLECTION = 16;
	public const int32 DB_BINDFLAGS_OPENIFEXISTS = 32;
	public const int32 DB_BINDFLAGS_OVERWRITE = 64;
	public const int32 DB_BINDFLAGS_ISSTRUCTUREDDOCUMENT = 128;
	public const int32 DBPROPVAL_ORS_TABLE = 0;
	public const int32 DBPROPVAL_ORS_INDEX = 1;
	public const int32 DBPROPVAL_ORS_INTEGRATEDINDEX = 2;
	public const int32 DBPROPVAL_TC_DDL_LOCK = 16;
	public const int32 DBPROPVAL_ORS_STOREDPROC = 4;
	public const int32 DBPROPVAL_IN_ALLOWNULL = 0;
	public const int32 DBPROPVAL_OO_SINGLETON = 32;
	public const int32 DBPROPVAL_OS_AGR_AFTERSESSION = 8;
	public const int32 DBPROPVAL_CM_TRANSACTIONS = 1;
	public const int32 DBPROPVAL_TS_CARDINALITY = 1;
	public const int32 DBPROPVAL_TS_HISTOGRAM = 2;
	public const int32 DBPROPVAL_ORS_HISTOGRAM = 8;
	public const int32 MDPROPVAL_VISUAL_MODE_DEFAULT = 0;
	public const int32 MDPROPVAL_VISUAL_MODE_VISUAL = 1;
	public const int32 MDPROPVAL_VISUAL_MODE_VISUAL_OFF = 2;
	public const uint32 DB_IMP_LEVEL_ANONYMOUS = 0;
	public const uint32 DB_IMP_LEVEL_IDENTIFY = 1;
	public const uint32 DB_IMP_LEVEL_IMPERSONATE = 2;
	public const uint32 DB_IMP_LEVEL_DELEGATE = 3;
	public const uint32 DBPROMPT_PROMPT = 1;
	public const uint32 DBPROMPT_COMPLETE = 2;
	public const uint32 DBPROMPT_COMPLETEREQUIRED = 3;
	public const uint32 DBPROMPT_NOPROMPT = 4;
	public const uint32 DB_PROT_LEVEL_NONE = 0;
	public const uint32 DB_PROT_LEVEL_CONNECT = 1;
	public const uint32 DB_PROT_LEVEL_CALL = 2;
	public const uint32 DB_PROT_LEVEL_PKT = 3;
	public const uint32 DB_PROT_LEVEL_PKT_INTEGRITY = 4;
	public const uint32 DB_PROT_LEVEL_PKT_PRIVACY = 5;
	public const uint32 DB_MODE_READ = 1;
	public const uint32 DB_MODE_WRITE = 2;
	public const uint32 DB_MODE_READWRITE = 3;
	public const uint32 DB_MODE_SHARE_DENY_READ = 4;
	public const uint32 DB_MODE_SHARE_DENY_WRITE = 8;
	public const uint32 DB_MODE_SHARE_EXCLUSIVE = 12;
	public const uint32 DB_MODE_SHARE_DENY_NONE = 16;
	public const uint32 DBCOMPUTEMODE_COMPUTED = 1;
	public const uint32 DBCOMPUTEMODE_DYNAMIC = 2;
	public const uint32 DBCOMPUTEMODE_NOTCOMPUTED = 3;
	public const uint32 DBPROPVAL_DF_INITIALLY_DEFERRED = 1;
	public const uint32 DBPROPVAL_DF_INITIALLY_IMMEDIATE = 2;
	public const uint32 DBPROPVAL_DF_NOT_DEFERRABLE = 3;
	public const uint32 DBPARAMTYPE_INPUT = 1;
	public const uint32 DBPARAMTYPE_INPUTOUTPUT = 2;
	public const uint32 DBPARAMTYPE_OUTPUT = 3;
	public const uint32 DBPARAMTYPE_RETURNVALUE = 4;
	public const uint32 DB_PT_UNKNOWN = 1;
	public const uint32 DB_PT_PROCEDURE = 2;
	public const uint32 DB_PT_FUNCTION = 3;
	public const uint32 DB_REMOTE = 1;
	public const uint32 DB_LOCAL_SHARED = 2;
	public const uint32 DB_LOCAL_EXCLUSIVE = 3;
	public const uint32 DB_COLLATION_ASC = 1;
	public const uint32 DB_COLLATION_DESC = 2;
	public const uint32 DB_UNSEARCHABLE = 1;
	public const uint32 DB_LIKE_ONLY = 2;
	public const uint32 DB_ALL_EXCEPT_LIKE = 3;
	public const uint32 DB_SEARCHABLE = 4;
	public const uint32 MDTREEOP_CHILDREN = 1;
	public const uint32 MDTREEOP_SIBLINGS = 2;
	public const uint32 MDTREEOP_PARENT = 4;
	public const uint32 MDTREEOP_SELF = 8;
	public const uint32 MDTREEOP_DESCENDANTS = 16;
	public const uint32 MDTREEOP_ANCESTORS = 32;
	public const uint32 MD_DIMTYPE_UNKNOWN = 0;
	public const uint32 MD_DIMTYPE_TIME = 1;
	public const uint32 MD_DIMTYPE_MEASURE = 2;
	public const uint32 MD_DIMTYPE_OTHER = 3;
	public const uint32 MDLEVEL_TYPE_UNKNOWN = 0;
	public const uint32 MDLEVEL_TYPE_REGULAR = 0;
	public const uint32 MDLEVEL_TYPE_ALL = 1;
	public const uint32 MDLEVEL_TYPE_CALCULATED = 2;
	public const uint32 MDLEVEL_TYPE_TIME = 4;
	public const uint32 MDLEVEL_TYPE_RESERVED1 = 8;
	public const uint32 MDLEVEL_TYPE_TIME_YEARS = 20;
	public const uint32 MDLEVEL_TYPE_TIME_HALF_YEAR = 36;
	public const uint32 MDLEVEL_TYPE_TIME_QUARTERS = 68;
	public const uint32 MDLEVEL_TYPE_TIME_MONTHS = 132;
	public const uint32 MDLEVEL_TYPE_TIME_WEEKS = 260;
	public const uint32 MDLEVEL_TYPE_TIME_DAYS = 516;
	public const uint32 MDLEVEL_TYPE_TIME_HOURS = 772;
	public const uint32 MDLEVEL_TYPE_TIME_MINUTES = 1028;
	public const uint32 MDLEVEL_TYPE_TIME_SECONDS = 2052;
	public const uint32 MDLEVEL_TYPE_TIME_UNDEFINED = 4100;
	public const uint32 MDMEASURE_AGGR_UNKNOWN = 0;
	public const uint32 MDMEASURE_AGGR_SUM = 1;
	public const uint32 MDMEASURE_AGGR_COUNT = 2;
	public const uint32 MDMEASURE_AGGR_MIN = 3;
	public const uint32 MDMEASURE_AGGR_MAX = 4;
	public const uint32 MDMEASURE_AGGR_AVG = 5;
	public const uint32 MDMEASURE_AGGR_VAR = 6;
	public const uint32 MDMEASURE_AGGR_STD = 7;
	public const uint32 MDMEASURE_AGGR_CALCULATED = 127;
	public const uint32 MDPROP_MEMBER = 1;
	public const uint32 MDPROP_CELL = 2;
	public const uint32 MDMEMBER_TYPE_UNKNOWN = 0;
	public const uint32 MDMEMBER_TYPE_REGULAR = 1;
	public const uint32 MDMEMBER_TYPE_ALL = 2;
	public const uint32 MDMEMBER_TYPE_MEASURE = 3;
	public const uint32 MDMEMBER_TYPE_FORMULA = 4;
	public const uint32 MDMEMBER_TYPE_RESERVE1 = 5;
	public const uint32 MDMEMBER_TYPE_RESERVE2 = 6;
	public const uint32 MDMEMBER_TYPE_RESERVE3 = 7;
	public const uint32 MDMEMBER_TYPE_RESERVE4 = 8;
	public const uint32 MDDISPINFO_DRILLED_DOWN = 65536;
	public const uint32 MDDISPINFO_PARENT_SAME_AS_PREV = 131072;
	public const int32 DB_COUNTUNAVAILABLE = -1;
	public const uint32 MDFF_BOLD = 1;
	public const uint32 MDFF_ITALIC = 2;
	public const uint32 MDFF_UNDERLINE = 4;
	public const uint32 MDFF_STRIKEOUT = 8;
	public const uint32 MDAXIS_COLUMNS = 0;
	public const uint32 MDAXIS_ROWS = 1;
	public const uint32 MDAXIS_PAGES = 2;
	public const uint32 MDAXIS_SECTIONS = 3;
	public const uint32 MDAXIS_CHAPTERS = 4;
	public const uint32 MDAXIS_SLICERS = 4294967295;
	public const uint32 CRESTRICTIONS_DBSCHEMA_ASSERTIONS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_CATALOGS = 1;
	public const uint32 CRESTRICTIONS_DBSCHEMA_CHARACTER_SETS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_COLLATIONS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_COLUMNS = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_CHECK_CONSTRAINTS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_CONSTRAINT_COLUMN_USAGE = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_CONSTRAINT_TABLE_USAGE = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_KEY_COLUMN_USAGE = 7;
	public const uint32 CRESTRICTIONS_DBSCHEMA_REFERENTIAL_CONSTRAINTS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TABLE_CONSTRAINTS = 7;
	public const uint32 CRESTRICTIONS_DBSCHEMA_COLUMN_DOMAIN_USAGE = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_INDEXES = 5;
	public const uint32 CRESTRICTIONS_DBSCHEMA_OBJECT_ACTIONS = 1;
	public const uint32 CRESTRICTIONS_DBSCHEMA_OBJECTS = 1;
	public const uint32 CRESTRICTIONS_DBSCHEMA_COLUMN_PRIVILEGES = 6;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TABLE_PRIVILEGES = 5;
	public const uint32 CRESTRICTIONS_DBSCHEMA_USAGE_PRIVILEGES = 6;
	public const uint32 CRESTRICTIONS_DBSCHEMA_PROCEDURES = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_SCHEMATA = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_SQL_LANGUAGES = 0;
	public const uint32 CRESTRICTIONS_DBSCHEMA_STATISTICS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TABLES = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TRANSLATIONS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_PROVIDER_TYPES = 2;
	public const uint32 CRESTRICTIONS_DBSCHEMA_VIEWS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_VIEW_COLUMN_USAGE = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_VIEW_TABLE_USAGE = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_PROCEDURE_PARAMETERS = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_FOREIGN_KEYS = 6;
	public const uint32 CRESTRICTIONS_DBSCHEMA_PRIMARY_KEYS = 3;
	public const uint32 CRESTRICTIONS_DBSCHEMA_PROCEDURE_COLUMNS = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TABLES_INFO = 4;
	public const uint32 CRESTRICTIONS_MDSCHEMA_CUBES = 3;
	public const uint32 CRESTRICTIONS_MDSCHEMA_DIMENSIONS = 5;
	public const uint32 CRESTRICTIONS_MDSCHEMA_HIERARCHIES = 6;
	public const uint32 CRESTRICTIONS_MDSCHEMA_LEVELS = 7;
	public const uint32 CRESTRICTIONS_MDSCHEMA_MEASURES = 5;
	public const uint32 CRESTRICTIONS_MDSCHEMA_PROPERTIES = 9;
	public const uint32 CRESTRICTIONS_MDSCHEMA_MEMBERS = 12;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TRUSTEE = 4;
	public const uint32 CRESTRICTIONS_DBSCHEMA_TABLE_STATISTICS = 7;
	public const uint32 CRESTRICTIONS_DBSCHEMA_CHECK_CONSTRAINTS_BY_TABLE = 6;
	public const uint32 CRESTRICTIONS_MDSCHEMA_FUNCTIONS = 4;
	public const uint32 CRESTRICTIONS_MDSCHEMA_ACTIONS = 8;
	public const uint32 CRESTRICTIONS_MDSCHEMA_COMMANDS = 5;
	public const uint32 CRESTRICTIONS_MDSCHEMA_SETS = 5;
	public const uint32 IDENTIFIER_SDK_MASK = 4026531840;
	public const uint32 IDENTIFIER_SDK_ERROR = 268435456;
	public const uint32 DBPROP_MSDAORA_DETERMINEKEYCOLUMNS = 1;
	public const uint32 DBPROP_MSDAORA8_DETERMINEKEYCOLUMNS = 2;
	public const uint32 PWPROP_OSPVALUE = 2;
	public const int32 STGM_COLLECTION = 8192;
	public const int32 STGM_OUTPUT = 32768;
	public const int32 STGM_OPEN = -2147483648;
	public const int32 STGM_RECURSIVE = 16777216;
	public const int32 STGM_STRICTOPEN = 1073741824;
	public const uint32 KAGPROP_QUERYBASEDUPDATES = 2;
	public const uint32 KAGPROP_MARSHALLABLE = 3;
	public const uint32 KAGPROP_POSITIONONNEWROW = 4;
	public const uint32 KAGPROP_IRowsetChangeExtInfo = 5;
	public const uint32 KAGPROP_CURSOR = 6;
	public const uint32 KAGPROP_CONCURRENCY = 7;
	public const uint32 KAGPROP_BLOBSONFOCURSOR = 8;
	public const uint32 KAGPROP_INCLUDENONEXACT = 9;
	public const uint32 KAGPROP_FORCESSFIREHOSEMODE = 10;
	public const uint32 KAGPROP_FORCENOPARAMETERREBIND = 11;
	public const uint32 KAGPROP_FORCENOPREPARE = 12;
	public const uint32 KAGPROP_FORCENOREEXECUTE = 13;
	public const uint32 KAGPROP_ACCESSIBLEPROCEDURES = 2;
	public const uint32 KAGPROP_ACCESSIBLETABLES = 3;
	public const uint32 KAGPROP_ODBCSQLOPTIEF = 4;
	public const uint32 KAGPROP_OJCAPABILITY = 5;
	public const uint32 KAGPROP_PROCEDURES = 6;
	public const uint32 KAGPROP_DRIVERNAME = 7;
	public const uint32 KAGPROP_DRIVERVER = 8;
	public const uint32 KAGPROP_DRIVERODBCVER = 9;
	public const uint32 KAGPROP_LIKEESCAPECLAUSE = 10;
	public const uint32 KAGPROP_SPECIALCHARACTERS = 11;
	public const uint32 KAGPROP_MAXCOLUMNSINGROUPBY = 12;
	public const uint32 KAGPROP_MAXCOLUMNSININDEX = 13;
	public const uint32 KAGPROP_MAXCOLUMNSINORDERBY = 14;
	public const uint32 KAGPROP_MAXCOLUMNSINSELECT = 15;
	public const uint32 KAGPROP_MAXCOLUMNSINTABLE = 16;
	public const uint32 KAGPROP_NUMERICFUNCTIONS = 17;
	public const uint32 KAGPROP_ODBCSQLCONFORMANCE = 18;
	public const uint32 KAGPROP_OUTERJOINS = 19;
	public const uint32 KAGPROP_STRINGFUNCTIONS = 20;
	public const uint32 KAGPROP_SYSTEMFUNCTIONS = 21;
	public const uint32 KAGPROP_TIMEDATEFUNCTIONS = 22;
	public const uint32 KAGPROP_FILEUSAGE = 23;
	public const uint32 KAGPROP_ACTIVESTATEMENTS = 24;
	public const uint32 KAGPROP_AUTH_TRUSTEDCONNECTION = 2;
	public const uint32 KAGPROP_AUTH_SERVERINTEGRATED = 3;
	public const uint32 KAGPROPVAL_CONCUR_ROWVER = 1;
	public const uint32 KAGPROPVAL_CONCUR_VALUES = 2;
	public const uint32 KAGPROPVAL_CONCUR_LOCK = 4;
	public const uint32 KAGPROPVAL_CONCUR_READ_ONLY = 8;
	public const uint32 ODBCVER = 896;
	public const uint32 ODBC_ADD_DSN = 1;
	public const uint32 ODBC_CONFIG_DSN = 2;
	public const uint32 ODBC_REMOVE_DSN = 3;
	public const uint32 ODBC_ADD_SYS_DSN = 4;
	public const uint32 ODBC_CONFIG_SYS_DSN = 5;
	public const uint32 ODBC_REMOVE_SYS_DSN = 6;
	public const uint32 ODBC_REMOVE_DEFAULT_DSN = 7;
	public const uint32 ODBC_INSTALL_INQUIRY = 1;
	public const uint32 ODBC_INSTALL_COMPLETE = 2;
	public const uint32 ODBC_INSTALL_DRIVER = 1;
	public const uint32 ODBC_REMOVE_DRIVER = 2;
	public const uint32 ODBC_CONFIG_DRIVER = 3;
	public const uint32 ODBC_CONFIG_DRIVER_MAX = 100;
	public const uint32 ODBC_BOTH_DSN = 0;
	public const uint32 ODBC_USER_DSN = 1;
	public const uint32 ODBC_SYSTEM_DSN = 2;
	public const uint32 ODBC_ERROR_GENERAL_ERR = 1;
	public const uint32 ODBC_ERROR_INVALID_BUFF_LEN = 2;
	public const uint32 ODBC_ERROR_INVALID_HWND = 3;
	public const uint32 ODBC_ERROR_INVALID_STR = 4;
	public const uint32 ODBC_ERROR_INVALID_REQUEST_TYPE = 5;
	public const uint32 ODBC_ERROR_COMPONENT_NOT_FOUND = 6;
	public const uint32 ODBC_ERROR_INVALID_NAME = 7;
	public const uint32 ODBC_ERROR_INVALID_KEYWORD_VALUE = 8;
	public const uint32 ODBC_ERROR_INVALID_DSN = 9;
	public const uint32 ODBC_ERROR_INVALID_INF = 10;
	public const uint32 ODBC_ERROR_REQUEST_FAILED = 11;
	public const uint32 ODBC_ERROR_INVALID_PATH = 12;
	public const uint32 ODBC_ERROR_LOAD_LIB_FAILED = 13;
	public const uint32 ODBC_ERROR_INVALID_PARAM_SEQUENCE = 14;
	public const uint32 ODBC_ERROR_INVALID_LOG_FILE = 15;
	public const uint32 ODBC_ERROR_USER_CANCELED = 16;
	public const uint32 ODBC_ERROR_USAGE_UPDATE_FAILED = 17;
	public const uint32 ODBC_ERROR_CREATE_DSN_FAILED = 18;
	public const uint32 ODBC_ERROR_WRITING_SYSINFO_FAILED = 19;
	public const uint32 ODBC_ERROR_REMOVE_DSN_FAILED = 20;
	public const uint32 ODBC_ERROR_OUT_OF_MEM = 21;
	public const uint32 ODBC_ERROR_OUTPUT_STRING_TRUNCATED = 22;
	public const uint32 ODBC_ERROR_NOTRANINFO = 23;
	public const uint32 ODBC_ERROR_MAX = 23;
	public const uint32 SQL_MAX_SQLSERVERNAME = 128;
	public const uint32 SQL_COPT_SS_BASE = 1200;
	public const uint32 SQL_COPT_SS_REMOTE_PWD = 1201;
	public const uint32 SQL_COPT_SS_USE_PROC_FOR_PREP = 1202;
	public const uint32 SQL_COPT_SS_INTEGRATED_SECURITY = 1203;
	public const uint32 SQL_COPT_SS_PRESERVE_CURSORS = 1204;
	public const uint32 SQL_COPT_SS_USER_DATA = 1205;
	public const uint32 SQL_COPT_SS_FALLBACK_CONNECT = 1210;
	public const uint32 SQL_COPT_SS_PERF_DATA = 1211;
	public const uint32 SQL_COPT_SS_PERF_DATA_LOG = 1212;
	public const uint32 SQL_COPT_SS_PERF_QUERY_INTERVAL = 1213;
	public const uint32 SQL_COPT_SS_PERF_QUERY_LOG = 1214;
	public const uint32 SQL_COPT_SS_PERF_QUERY = 1215;
	public const uint32 SQL_COPT_SS_PERF_DATA_LOG_NOW = 1216;
	public const uint32 SQL_COPT_SS_QUOTED_IDENT = 1217;
	public const uint32 SQL_COPT_SS_ANSI_NPW = 1218;
	public const uint32 SQL_COPT_SS_BCP = 1219;
	public const uint32 SQL_COPT_SS_TRANSLATE = 1220;
	public const uint32 SQL_COPT_SS_ATTACHDBFILENAME = 1221;
	public const uint32 SQL_COPT_SS_CONCAT_NULL = 1222;
	public const uint32 SQL_COPT_SS_ENCRYPT = 1223;
	public const uint32 SQL_COPT_SS_MAX_USED = 1223;
	public const uint32 SQL_SOPT_SS_BASE = 1225;
	public const uint32 SQL_SOPT_SS_TEXTPTR_LOGGING = 1225;
	public const uint32 SQL_SOPT_SS_CURRENT_COMMAND = 1226;
	public const uint32 SQL_SOPT_SS_HIDDEN_COLUMNS = 1227;
	public const uint32 SQL_SOPT_SS_NOBROWSETABLE = 1228;
	public const uint32 SQL_SOPT_SS_REGIONALIZE = 1229;
	public const uint32 SQL_SOPT_SS_CURSOR_OPTIONS = 1230;
	public const uint32 SQL_SOPT_SS_NOCOUNT_STATUS = 1231;
	public const uint32 SQL_SOPT_SS_DEFER_PREPARE = 1232;
	public const uint32 SQL_SOPT_SS_MAX_USED = 1232;
	public const uint32 SQL_COPT_SS_BASE_EX = 1240;
	public const uint32 SQL_COPT_SS_BROWSE_CONNECT = 1241;
	public const uint32 SQL_COPT_SS_BROWSE_SERVER = 1242;
	public const uint32 SQL_COPT_SS_WARN_ON_CP_ERROR = 1243;
	public const uint32 SQL_COPT_SS_CONNECTION_DEAD = 1244;
	public const uint32 SQL_COPT_SS_BROWSE_CACHE_DATA = 1245;
	public const uint32 SQL_COPT_SS_RESET_CONNECTION = 1246;
	public const uint32 SQL_COPT_SS_EX_MAX_USED = 1246;
	public const int32 SQL_UP_OFF = 0;
	public const int32 SQL_UP_ON = 1;
	public const int32 SQL_UP_ON_DROP = 2;
	public const int32 SQL_UP_DEFAULT = 1;
	public const int32 SQL_IS_OFF = 0;
	public const int32 SQL_IS_ON = 1;
	public const int32 SQL_IS_DEFAULT = 0;
	public const int32 SQL_PC_OFF = 0;
	public const int32 SQL_PC_ON = 1;
	public const int32 SQL_PC_DEFAULT = 0;
	public const int32 SQL_XL_OFF = 0;
	public const int32 SQL_XL_ON = 1;
	public const int32 SQL_XL_DEFAULT = 1;
	public const int32 SQL_FB_OFF = 0;
	public const int32 SQL_FB_ON = 1;
	public const int32 SQL_FB_DEFAULT = 0;
	public const int32 SQL_BCP_OFF = 0;
	public const int32 SQL_BCP_ON = 1;
	public const int32 SQL_BCP_DEFAULT = 0;
	public const int32 SQL_QI_OFF = 0;
	public const int32 SQL_QI_ON = 1;
	public const int32 SQL_QI_DEFAULT = 1;
	public const int32 SQL_AD_OFF = 0;
	public const int32 SQL_AD_ON = 1;
	public const int32 SQL_AD_DEFAULT = 1;
	public const int32 SQL_CN_OFF = 0;
	public const int32 SQL_CN_ON = 1;
	public const int32 SQL_CN_DEFAULT = 1;
	public const int32 SQL_TL_OFF = 0;
	public const int32 SQL_TL_ON = 1;
	public const int32 SQL_TL_DEFAULT = 1;
	public const int32 SQL_HC_OFF = 0;
	public const int32 SQL_HC_ON = 1;
	public const int32 SQL_HC_DEFAULT = 0;
	public const int32 SQL_NB_OFF = 0;
	public const int32 SQL_NB_ON = 1;
	public const int32 SQL_NB_DEFAULT = 0;
	public const int32 SQL_RE_OFF = 0;
	public const int32 SQL_RE_ON = 1;
	public const int32 SQL_RE_DEFAULT = 0;
	public const int32 SQL_CO_OFF = 0;
	public const int32 SQL_CO_FFO = 1;
	public const int32 SQL_CO_AF = 2;
	public const int32 SQL_CO_FIREHOSE_AF = 4;
	public const int32 SQL_CO_DEFAULT = 0;
	public const int32 SQL_NC_OFF = 0;
	public const int32 SQL_NC_ON = 1;
	public const int32 SQL_DP_OFF = 0;
	public const int32 SQL_DP_ON = 1;
	public const int32 SQL_EN_OFF = 0;
	public const int32 SQL_EN_ON = 1;
	public const int32 SQL_MORE_INFO_NO = 0;
	public const int32 SQL_MORE_INFO_YES = 1;
	public const int32 SQL_CACHE_DATA_NO = 0;
	public const int32 SQL_CACHE_DATA_YES = 1;
	public const int32 SQL_RESET_YES = 1;
	public const int32 SQL_WARN_NO = 0;
	public const int32 SQL_WARN_YES = 1;
	public const uint32 SQL_CURSOR_FAST_FORWARD_ONLY = 8;
	public const uint32 SQL_CA_SS_BASE = 1200;
	public const uint32 SQL_CA_SS_COLUMN_SSTYPE = 1200;
	public const uint32 SQL_CA_SS_COLUMN_UTYPE = 1201;
	public const uint32 SQL_CA_SS_NUM_ORDERS = 1202;
	public const uint32 SQL_CA_SS_COLUMN_ORDER = 1203;
	public const uint32 SQL_CA_SS_COLUMN_VARYLEN = 1204;
	public const uint32 SQL_CA_SS_NUM_COMPUTES = 1205;
	public const uint32 SQL_CA_SS_COMPUTE_ID = 1206;
	public const uint32 SQL_CA_SS_COMPUTE_BYLIST = 1207;
	public const uint32 SQL_CA_SS_COLUMN_ID = 1208;
	public const uint32 SQL_CA_SS_COLUMN_OP = 1209;
	public const uint32 SQL_CA_SS_COLUMN_SIZE = 1210;
	public const uint32 SQL_CA_SS_COLUMN_HIDDEN = 1211;
	public const uint32 SQL_CA_SS_COLUMN_KEY = 1212;
	public const uint32 SQL_CA_SS_COLUMN_COLLATION = 1214;
	public const uint32 SQL_CA_SS_VARIANT_TYPE = 1215;
	public const uint32 SQL_CA_SS_VARIANT_SQL_TYPE = 1216;
	public const uint32 SQL_CA_SS_VARIANT_SERVER_TYPE = 1217;
	public const uint32 SQL_CA_SS_MAX_USED = 1218;
	public const uint32 SQLTEXT = 35;
	public const uint32 SQLVARBINARY = 37;
	public const uint32 SQLINTN = 38;
	public const uint32 SQLVARCHAR = 39;
	public const uint32 SQLBINARY = 45;
	public const uint32 SQLIMAGE = 34;
	public const uint32 SQLCHARACTER = 47;
	public const uint32 SQLINT1 = 48;
	public const uint32 SQLBIT = 50;
	public const uint32 SQLINT2 = 52;
	public const uint32 SQLINT4 = 56;
	public const uint32 SQLMONEY = 60;
	public const uint32 SQLDATETIME = 61;
	public const uint32 SQLFLT8 = 62;
	public const uint32 SQLFLTN = 109;
	public const uint32 SQLMONEYN = 110;
	public const uint32 SQLDATETIMN = 111;
	public const uint32 SQLFLT4 = 59;
	public const uint32 SQLMONEY4 = 122;
	public const uint32 SQLDATETIM4 = 58;
	public const uint32 SQLDECIMAL = 106;
	public const uint32 SQLNUMERIC = 108;
	public const uint32 SQLUNIQUEID = 36;
	public const uint32 SQLBIGCHAR = 175;
	public const uint32 SQLBIGVARCHAR = 167;
	public const uint32 SQLBIGBINARY = 173;
	public const uint32 SQLBIGVARBINARY = 165;
	public const uint32 SQLBITN = 104;
	public const uint32 SQLNCHAR = 239;
	public const uint32 SQLNVARCHAR = 231;
	public const uint32 SQLNTEXT = 99;
	public const uint32 SQLINT8 = 127;
	public const uint32 SQLVARIANT = 98;
	public const uint32 SQLudtBINARY = 3;
	public const uint32 SQLudtBIT = 16;
	public const uint32 SQLudtBITN = 0;
	public const uint32 SQLudtCHAR = 1;
	public const uint32 SQLudtDATETIM4 = 22;
	public const uint32 SQLudtDATETIME = 12;
	public const uint32 SQLudtDATETIMN = 15;
	public const uint32 SQLudtDECML = 24;
	public const uint32 SQLudtDECMLN = 26;
	public const uint32 SQLudtFLT4 = 23;
	public const uint32 SQLudtFLT8 = 8;
	public const uint32 SQLudtFLTN = 14;
	public const uint32 SQLudtIMAGE = 20;
	public const uint32 SQLudtINT1 = 5;
	public const uint32 SQLudtINT2 = 6;
	public const uint32 SQLudtINT4 = 7;
	public const uint32 SQLudtINTN = 13;
	public const uint32 SQLudtMONEY = 11;
	public const uint32 SQLudtMONEY4 = 21;
	public const uint32 SQLudtMONEYN = 17;
	public const uint32 SQLudtNUM = 10;
	public const uint32 SQLudtNUMN = 25;
	public const uint32 SQLudtSYSNAME = 18;
	public const uint32 SQLudtTEXT = 19;
	public const uint32 SQLudtTIMESTAMP = 80;
	public const uint32 SQLudtUNIQUEIDENTIFIER = 0;
	public const uint32 SQLudtVARBINARY = 4;
	public const uint32 SQLudtVARCHAR = 2;
	public const uint32 MIN_USER_DATATYPE = 256;
	public const uint32 SQLAOPSTDEV = 48;
	public const uint32 SQLAOPSTDEVP = 49;
	public const uint32 SQLAOPVAR = 50;
	public const uint32 SQLAOPVARP = 51;
	public const uint32 SQLAOPCNT = 75;
	public const uint32 SQLAOPSUM = 77;
	public const uint32 SQLAOPAVG = 79;
	public const uint32 SQLAOPMIN = 81;
	public const uint32 SQLAOPMAX = 82;
	public const uint32 SQLAOPANY = 83;
	public const uint32 SQLAOPNOOP = 86;
	public const uint32 SQL_INFO_SS_FIRST = 1199;
	public const uint32 SQL_INFO_SS_NETLIB_NAMEW = 1199;
	public const uint32 SQL_INFO_SS_NETLIB_NAMEA = 1200;
	public const uint32 SQL_INFO_SS_MAX_USED = 1200;
	public const uint32 SQL_INFO_SS_NETLIB_NAME = 1199;
	public const int32 SQL_SS_VARIANT = -150;
	public const int32 SQL_DIAG_SS_BASE = -1150;
	public const int32 SQL_DIAG_SS_MSGSTATE = -1150;
	public const int32 SQL_DIAG_DFC_SS_BASE = -200;
	public const uint32 EX_ANY = 0;
	public const uint32 EX_INFO = 10;
	public const uint32 EX_MAXISEVERITY = 10;
	public const uint32 EX_MISSING = 11;
	public const uint32 EX_TYPE = 12;
	public const uint32 EX_DEADLOCK = 13;
	public const uint32 EX_PERMIT = 14;
	public const uint32 EX_SYNTAX = 15;
	public const uint32 EX_USER = 16;
	public const uint32 EX_RESOURCE = 17;
	public const uint32 EX_INTOK = 18;
	public const uint32 MAXUSEVERITY = 18;
	public const uint32 EX_LIMIT = 19;
	public const uint32 EX_CMDFATAL = 20;
	public const uint32 MINFATALERR = 20;
	public const uint32 EX_DBFATAL = 21;
	public const uint32 EX_TABCORRUPT = 22;
	public const uint32 EX_DBCORRUPT = 23;
	public const uint32 EX_HARDWARE = 24;
	public const uint32 EX_CONTROL = 25;
	public const uint32 DBMAXCHAR = 8001;
	public const uint32 MAXNAME = 129;
	public const uint32 MAXNUMERICLEN = 16;
	public const uint32 SQL_PERF_START = 1;
	public const uint32 SQL_PERF_STOP = 2;
	public const String SQL_SS_DL_DEFAULT = "STATS.LOG";
	public const String SQL_SS_QL_DEFAULT = "QUERY.LOG";
	public const uint32 SQL_SS_QI_DEFAULT = 30000;
	public const uint32 SUCCEED = 1;
	public const uint32 FAIL = 0;
	public const uint32 SUCCEED_ABORT = 2;
	public const uint32 SUCCEED_ASYNC = 3;
	public const uint32 DB_IN = 1;
	public const uint32 DB_OUT = 2;
	public const uint32 BCPMAXERRS = 1;
	public const uint32 BCPFIRST = 2;
	public const uint32 BCPLAST = 3;
	public const uint32 BCPBATCH = 4;
	public const uint32 BCPKEEPNULLS = 5;
	public const uint32 BCPABORT = 6;
	public const uint32 BCPODBC = 7;
	public const uint32 BCPKEEPIDENTITY = 8;
	public const uint32 BCP6xFILEFMT = 9;
	public const uint32 BCPHINTSA = 10;
	public const uint32 BCPHINTSW = 11;
	public const uint32 BCPFILECP = 12;
	public const uint32 BCPUNICODEFILE = 13;
	public const uint32 BCPTEXTFILE = 14;
	public const uint32 BCPFILEFMT = 15;
	public const uint32 BCPFILECP_ACP = 0;
	public const uint32 BCPFILECP_OEMCP = 1;
	public const int32 BCPFILECP_RAW = -1;
	public const int32 SQL_VARLEN_DATA = -10;
	public const uint32 BCPHINTS = 11;
	public const uint32 BCP_FMT_TYPE = 1;
	public const uint32 BCP_FMT_INDICATOR_LEN = 2;
	public const uint32 BCP_FMT_DATA_LEN = 3;
	public const uint32 BCP_FMT_TERMINATOR = 4;
	public const uint32 BCP_FMT_SERVER_COL = 5;
	public const uint32 BCP_FMT_COLLATION = 6;
	public const uint32 BCP_FMT_COLLATION_ID = 7;
	public const uint32 SQL_FAST_CONNECT = 1200;
	public const int32 SQL_FC_OFF = 0;
	public const int32 SQL_FC_ON = 1;
	public const int32 SQL_FC_DEFAULT = 0;
	public const uint32 SQL_COPT_SS_ANSI_OEM = 1206;
	public const int32 SQL_AO_OFF = 0;
	public const int32 SQL_AO_ON = 1;
	public const int32 SQL_AO_DEFAULT = 0;
	public const uint32 SQL_REMOTE_PWD = 1201;
	public const uint32 SQL_USE_PROCEDURE_FOR_PREPARE = 1202;
	public const uint32 SQL_INTEGRATED_SECURITY = 1203;
	public const uint32 SQL_PRESERVE_CURSORS = 1204;
	public const uint32 SQL_TEXTPTR_LOGGING = 1225;
	public const uint32 SQLDECIMALN = 106;
	public const uint32 SQLNUMERICN = 108;
	public const HRESULT DB_E_BOGUS = -2147217665;
	public const HRESULT DB_E_BADACCESSORHANDLE = -2147217920;
	public const HRESULT DB_E_ROWLIMITEXCEEDED = -2147217919;
	public const HRESULT DB_E_READONLYACCESSOR = -2147217918;
	public const HRESULT DB_E_SCHEMAVIOLATION = -2147217917;
	public const HRESULT DB_E_BADROWHANDLE = -2147217916;
	public const HRESULT DB_E_OBJECTOPEN = -2147217915;
	public const HRESULT DB_E_BADCHAPTER = -2147217914;
	public const HRESULT DB_E_CANTCONVERTVALUE = -2147217913;
	public const HRESULT DB_E_BADBINDINFO = -2147217912;
	public const HRESULT DB_SEC_E_PERMISSIONDENIED = -2147217911;
	public const HRESULT DB_E_NOTAREFERENCECOLUMN = -2147217910;
	public const HRESULT DB_E_LIMITREJECTED = -2147217909;
	public const HRESULT DB_E_NOCOMMAND = -2147217908;
	public const HRESULT DB_E_COSTLIMIT = -2147217907;
	public const HRESULT DB_E_BADBOOKMARK = -2147217906;
	public const HRESULT DB_E_BADLOCKMODE = -2147217905;
	public const HRESULT DB_E_PARAMNOTOPTIONAL = -2147217904;
	public const HRESULT DB_E_BADCOLUMNID = -2147217903;
	public const HRESULT DB_E_BADRATIO = -2147217902;
	public const HRESULT DB_E_BADVALUES = -2147217901;
	public const HRESULT DB_E_ERRORSINCOMMAND = -2147217900;
	public const HRESULT DB_E_CANTCANCEL = -2147217899;
	public const HRESULT DB_E_DIALECTNOTSUPPORTED = -2147217898;
	public const HRESULT DB_E_DUPLICATEDATASOURCE = -2147217897;
	public const HRESULT DB_E_CANNOTRESTART = -2147217896;
	public const HRESULT DB_E_NOTFOUND = -2147217895;
	public const HRESULT DB_E_NEWLYINSERTED = -2147217893;
	public const HRESULT DB_E_CANNOTFREE = -2147217894;
	public const HRESULT DB_E_GOALREJECTED = -2147217892;
	public const HRESULT DB_E_UNSUPPORTEDCONVERSION = -2147217891;
	public const HRESULT DB_E_BADSTARTPOSITION = -2147217890;
	public const HRESULT DB_E_NOQUERY = -2147217889;
	public const HRESULT DB_E_NOTREENTRANT = -2147217888;
	public const HRESULT DB_E_ERRORSOCCURRED = -2147217887;
	public const HRESULT DB_E_NOAGGREGATION = -2147217886;
	public const HRESULT DB_E_DELETEDROW = -2147217885;
	public const HRESULT DB_E_CANTFETCHBACKWARDS = -2147217884;
	public const HRESULT DB_E_ROWSNOTRELEASED = -2147217883;
	public const HRESULT DB_E_BADSTORAGEFLAG = -2147217882;
	public const HRESULT DB_E_BADCOMPAREOP = -2147217881;
	public const HRESULT DB_E_BADSTATUSVALUE = -2147217880;
	public const HRESULT DB_E_CANTSCROLLBACKWARDS = -2147217879;
	public const HRESULT DB_E_BADREGIONHANDLE = -2147217878;
	public const HRESULT DB_E_NONCONTIGUOUSRANGE = -2147217877;
	public const HRESULT DB_E_INVALIDTRANSITION = -2147217876;
	public const HRESULT DB_E_NOTASUBREGION = -2147217875;
	public const HRESULT DB_E_MULTIPLESTATEMENTS = -2147217874;
	public const HRESULT DB_E_INTEGRITYVIOLATION = -2147217873;
	public const HRESULT DB_E_BADTYPENAME = -2147217872;
	public const HRESULT DB_E_ABORTLIMITREACHED = -2147217871;
	public const HRESULT DB_E_ROWSETINCOMMAND = -2147217870;
	public const HRESULT DB_E_CANTTRANSLATE = -2147217869;
	public const HRESULT DB_E_DUPLICATEINDEXID = -2147217868;
	public const HRESULT DB_E_NOINDEX = -2147217867;
	public const HRESULT DB_E_INDEXINUSE = -2147217866;
	public const HRESULT DB_E_NOTABLE = -2147217865;
	public const HRESULT DB_E_CONCURRENCYVIOLATION = -2147217864;
	public const HRESULT DB_E_BADCOPY = -2147217863;
	public const HRESULT DB_E_BADPRECISION = -2147217862;
	public const HRESULT DB_E_BADSCALE = -2147217861;
	public const HRESULT DB_E_BADTABLEID = -2147217860;
	public const int32 DB_E_BADID = -2147217860;
	public const HRESULT DB_E_BADTYPE = -2147217859;
	public const HRESULT DB_E_DUPLICATECOLUMNID = -2147217858;
	public const HRESULT DB_E_DUPLICATETABLEID = -2147217857;
	public const HRESULT DB_E_TABLEINUSE = -2147217856;
	public const HRESULT DB_E_NOLOCALE = -2147217855;
	public const HRESULT DB_E_BADRECORDNUM = -2147217854;
	public const HRESULT DB_E_BOOKMARKSKIPPED = -2147217853;
	public const HRESULT DB_E_BADPROPERTYVALUE = -2147217852;
	public const HRESULT DB_E_INVALID = -2147217851;
	public const HRESULT DB_E_BADACCESSORFLAGS = -2147217850;
	public const HRESULT DB_E_BADSTORAGEFLAGS = -2147217849;
	public const HRESULT DB_E_BYREFACCESSORNOTSUPPORTED = -2147217848;
	public const HRESULT DB_E_NULLACCESSORNOTSUPPORTED = -2147217847;
	public const HRESULT DB_E_NOTPREPARED = -2147217846;
	public const HRESULT DB_E_BADACCESSORTYPE = -2147217845;
	public const HRESULT DB_E_WRITEONLYACCESSOR = -2147217844;
	public const HRESULT DB_SEC_E_AUTH_FAILED = -2147217843;
	public const HRESULT DB_E_CANCELED = -2147217842;
	public const HRESULT DB_E_CHAPTERNOTRELEASED = -2147217841;
	public const HRESULT DB_E_BADSOURCEHANDLE = -2147217840;
	public const HRESULT DB_E_PARAMUNAVAILABLE = -2147217839;
	public const HRESULT DB_E_ALREADYINITIALIZED = -2147217838;
	public const HRESULT DB_E_NOTSUPPORTED = -2147217837;
	public const HRESULT DB_E_MAXPENDCHANGESEXCEEDED = -2147217836;
	public const HRESULT DB_E_BADORDINAL = -2147217835;
	public const HRESULT DB_E_PENDINGCHANGES = -2147217834;
	public const HRESULT DB_E_DATAOVERFLOW = -2147217833;
	public const HRESULT DB_E_BADHRESULT = -2147217832;
	public const HRESULT DB_E_BADLOOKUPID = -2147217831;
	public const HRESULT DB_E_BADDYNAMICERRORID = -2147217830;
	public const HRESULT DB_E_PENDINGINSERT = -2147217829;
	public const HRESULT DB_E_BADCONVERTFLAG = -2147217828;
	public const HRESULT DB_E_BADPARAMETERNAME = -2147217827;
	public const HRESULT DB_E_MULTIPLESTORAGE = -2147217826;
	public const HRESULT DB_E_CANTFILTER = -2147217825;
	public const HRESULT DB_E_CANTORDER = -2147217824;
	public const HRESULT MD_E_BADTUPLE = -2147217823;
	public const HRESULT MD_E_BADCOORDINATE = -2147217822;
	public const HRESULT MD_E_INVALIDAXIS = -2147217821;
	public const HRESULT MD_E_INVALIDCELLRANGE = -2147217820;
	public const HRESULT DB_E_NOCOLUMN = -2147217819;
	public const HRESULT DB_E_COMMANDNOTPERSISTED = -2147217817;
	public const HRESULT DB_E_DUPLICATEID = -2147217816;
	public const HRESULT DB_E_OBJECTCREATIONLIMITREACHED = -2147217815;
	public const HRESULT DB_E_BADINDEXID = -2147217806;
	public const HRESULT DB_E_BADINITSTRING = -2147217805;
	public const HRESULT DB_E_NOPROVIDERSREGISTERED = -2147217804;
	public const HRESULT DB_E_MISMATCHEDPROVIDER = -2147217803;
	public const HRESULT DB_E_BADCOMMANDID = -2147217802;
	public const int32 SEC_E_PERMISSIONDENIED = -2147217911;
	public const HRESULT SEC_E_BADTRUSTEEID = -2147217814;
	public const HRESULT SEC_E_NOTRUSTEEID = -2147217813;
	public const HRESULT SEC_E_NOMEMBERSHIPSUPPORT = -2147217812;
	public const HRESULT SEC_E_INVALIDOBJECT = -2147217811;
	public const HRESULT SEC_E_NOOWNER = -2147217810;
	public const HRESULT SEC_E_INVALIDACCESSENTRYLIST = -2147217809;
	public const HRESULT SEC_E_INVALIDOWNER = -2147217808;
	public const HRESULT SEC_E_INVALIDACCESSENTRY = -2147217807;
	public const HRESULT DB_E_BADCONSTRAINTTYPE = -2147217801;
	public const HRESULT DB_E_BADCONSTRAINTFORM = -2147217800;
	public const HRESULT DB_E_BADDEFERRABILITY = -2147217799;
	public const HRESULT DB_E_BADMATCHTYPE = -2147217792;
	public const HRESULT DB_E_BADUPDATEDELETERULE = -2147217782;
	public const HRESULT DB_E_BADCONSTRAINTID = -2147217781;
	public const HRESULT DB_E_BADCOMMANDFLAGS = -2147217780;
	public const HRESULT DB_E_OBJECTMISMATCH = -2147217779;
	public const HRESULT DB_E_NOSOURCEOBJECT = -2147217775;
	public const HRESULT DB_E_RESOURCELOCKED = -2147217774;
	public const HRESULT DB_E_NOTCOLLECTION = -2147217773;
	public const HRESULT DB_E_READONLY = -2147217772;
	public const HRESULT DB_E_ASYNCNOTSUPPORTED = -2147217771;
	public const HRESULT DB_E_CANNOTCONNECT = -2147217770;
	public const HRESULT DB_E_TIMEOUT = -2147217769;
	public const HRESULT DB_E_RESOURCEEXISTS = -2147217768;
	public const HRESULT DB_E_RESOURCEOUTOFSCOPE = -2147217778;
	public const HRESULT DB_E_DROPRESTRICTED = -2147217776;
	public const HRESULT DB_E_DUPLICATECONSTRAINTID = -2147217767;
	public const HRESULT DB_E_OUTOFSPACE = -2147217766;
	public const HRESULT DB_SEC_E_SAFEMODE_DENIED = -2147217765;
	public const HRESULT DB_E_NOSTATISTIC = -2147217764;
	public const HRESULT DB_E_ALTERRESTRICTED = -2147217763;
	public const HRESULT DB_E_RESOURCENOTSUPPORTED = -2147217762;
	public const HRESULT DB_E_NOCONSTRAINT = -2147217761;
	public const HRESULT DB_E_COLUMNUNAVAILABLE = -2147217760;
	public const HRESULT DB_S_ROWLIMITEXCEEDED = 265920;
	public const HRESULT DB_S_COLUMNTYPEMISMATCH = 265921;
	public const HRESULT DB_S_TYPEINFOOVERRIDDEN = 265922;
	public const HRESULT DB_S_BOOKMARKSKIPPED = 265923;
	public const HRESULT DB_S_NONEXTROWSET = 265925;
	public const HRESULT DB_S_ENDOFROWSET = 265926;
	public const HRESULT DB_S_COMMANDREEXECUTED = 265927;
	public const HRESULT DB_S_BUFFERFULL = 265928;
	public const HRESULT DB_S_NORESULT = 265929;
	public const HRESULT DB_S_CANTRELEASE = 265930;
	public const HRESULT DB_S_GOALCHANGED = 265931;
	public const HRESULT DB_S_UNWANTEDOPERATION = 265932;
	public const HRESULT DB_S_DIALECTIGNORED = 265933;
	public const HRESULT DB_S_UNWANTEDPHASE = 265934;
	public const HRESULT DB_S_UNWANTEDREASON = 265935;
	public const HRESULT DB_S_ASYNCHRONOUS = 265936;
	public const HRESULT DB_S_COLUMNSCHANGED = 265937;
	public const HRESULT DB_S_ERRORSRETURNED = 265938;
	public const HRESULT DB_S_BADROWHANDLE = 265939;
	public const HRESULT DB_S_DELETEDROW = 265940;
	public const HRESULT DB_S_TOOMANYCHANGES = 265941;
	public const HRESULT DB_S_STOPLIMITREACHED = 265942;
	public const HRESULT DB_S_LOCKUPGRADED = 265944;
	public const HRESULT DB_S_PROPERTIESCHANGED = 265945;
	public const HRESULT DB_S_ERRORSOCCURRED = 265946;
	public const HRESULT DB_S_PARAMUNAVAILABLE = 265947;
	public const HRESULT DB_S_MULTIPLECHANGES = 265948;
	public const HRESULT DB_S_NOTSINGLETON = 265943;
	public const HRESULT DB_S_NOROWSPECIFICCOLUMNS = 265949;
	public const uint32 DBPROPFLAGS_PERSIST = 8192;
	public const uint32 DBPROPVAL_PERSIST_ADTG = 0;
	public const uint32 DBPROPVAL_PERSIST_XML = 1;
	public const uint32 DBPROP_PersistFormat = 2;
	public const uint32 DBPROP_PersistSchema = 3;
	public const uint32 DBPROP_HCHAPTER = 4;
	public const uint32 DBPROP_MAINTAINPROPS = 5;
	public const uint32 DBPROP_Unicode = 6;
	public const uint32 DBPROP_INTERLEAVEDROWS = 8;
	public const String MS_PERSIST_PROGID = "MSPersist";
	public const uint32 DISPID_QUERY_RANKVECTOR = 2;
	public const uint32 DISPID_QUERY_RANK = 3;
	public const uint32 DISPID_QUERY_HITCOUNT = 4;
	public const uint32 DISPID_QUERY_WORKID = 5;
	public const uint32 DISPID_QUERY_ALL = 6;
	public const uint32 DISPID_QUERY_UNFILTERED = 7;
	public const uint32 DISPID_QUERY_REVNAME = 8;
	public const uint32 DISPID_QUERY_VIRTUALPATH = 9;
	public const uint32 DISPID_QUERY_LASTSEENTIME = 10;
	public const uint32 CQUERYDISPIDS = 11;
	public const uint32 DISPID_QUERY_METADATA_VROOTUSED = 2;
	public const uint32 DISPID_QUERY_METADATA_VROOTAUTOMATIC = 3;
	public const uint32 DISPID_QUERY_METADATA_VROOTMANUAL = 4;
	public const uint32 DISPID_QUERY_METADATA_PROPGUID = 5;
	public const uint32 DISPID_QUERY_METADATA_PROPDISPID = 6;
	public const uint32 DISPID_QUERY_METADATA_PROPNAME = 7;
	public const uint32 DISPID_QUERY_METADATA_STORELEVEL = 8;
	public const uint32 DISPID_QUERY_METADATA_PROPMODIFIABLE = 9;
	public const uint32 CQUERYMETADISPIDS = 10;
	public const uint32 PROPID_DBBMK_BOOKMARK = 2;
	public const uint32 PROPID_DBBMK_CHAPTER = 3;
	public const uint32 CDBBMKDISPIDS = 8;
	public const uint32 PROPID_DBSELF_SELF = 2;
	public const uint32 CDBSELFDISPIDS = 8;
	public const uint32 CDBCOLDISPIDS = 28;
	public const uint32 CQUERYPROPERTY = 64;
	public const uint32 QUERY_VALIDBITS = 3;
	public const uint32 RTNone = 0;
	public const uint32 RTAnd = 1;
	public const uint32 RTOr = 2;
	public const uint32 RTNot = 3;
	public const uint32 RTContent = 4;
	public const uint32 RTProperty = 5;
	public const uint32 RTProximity = 6;
	public const uint32 RTVector = 7;
	public const uint32 RTNatLanguage = 8;
	public const uint32 GENERATE_METHOD_PREFIXMATCH = 1;
	public const uint32 GENERATE_METHOD_STEMMED = 2;
	public const uint32 PRRE = 6;
	public const uint32 PRAllBits = 7;
	public const uint32 PRSomeBits = 8;
	public const uint32 PRAll = 256;
	public const uint32 PRAny = 512;
	public const uint32 QUERY_SORTXASCEND = 2;
	public const uint32 QUERY_SORTXDESCEND = 3;
	public const uint32 QUERY_SORTDEFAULT = 4;
	public const uint32 CATEGORIZE_UNIQUE = 0;
	public const uint32 CATEGORIZE_CLUSTER = 1;
	public const uint32 CATEGORIZE_BUCKETS = 2;
	public const uint32 BUCKET_LINEAR = 0;
	public const uint32 BUCKET_EXPONENTIAL = 1;
	public const uint32 CATEGORIZE_RANGE = 3;
	public const uint32 OCC_INVALID = 4294967295;
	public const uint32 MAX_QUERY_RANK = 1000;
	public const uint32 OSP_IndexLabel = 0;
	public const int32 SQL_NULL_DATA = -1;
	public const int32 SQL_DATA_AT_EXEC = -2;
	public const uint32 SQL_SUCCESS = 0;
	public const uint32 SQL_SUCCESS_WITH_INFO = 1;
	public const uint32 SQL_NO_DATA = 100;
	public const uint32 SQL_PARAM_DATA_AVAILABLE = 101;
	public const int32 SQL_ERROR = -1;
	public const int32 SQL_INVALID_HANDLE = -2;
	public const uint32 SQL_STILL_EXECUTING = 2;
	public const uint32 SQL_NEED_DATA = 99;
	public const int32 SQL_NTS = -3;
	public const int32 SQL_NTSL = -3;
	public const uint32 SQL_MAX_MESSAGE_LENGTH = 512;
	public const uint32 SQL_DATE_LEN = 10;
	public const uint32 SQL_TIME_LEN = 8;
	public const uint32 SQL_TIMESTAMP_LEN = 19;
	public const uint32 SQL_HANDLE_ENV = 1;
	public const uint32 SQL_HANDLE_DBC = 2;
	public const uint32 SQL_HANDLE_STMT = 3;
	public const uint32 SQL_HANDLE_DESC = 4;
	public const uint32 SQL_ATTR_OUTPUT_NTS = 10001;
	public const uint32 SQL_ATTR_AUTO_IPD = 10001;
	public const uint32 SQL_ATTR_METADATA_ID = 10014;
	public const uint32 SQL_ATTR_APP_ROW_DESC = 10010;
	public const uint32 SQL_ATTR_APP_PARAM_DESC = 10011;
	public const uint32 SQL_ATTR_IMP_ROW_DESC = 10012;
	public const uint32 SQL_ATTR_IMP_PARAM_DESC = 10013;
	public const int32 SQL_ATTR_CURSOR_SCROLLABLE = -1;
	public const int32 SQL_ATTR_CURSOR_SENSITIVITY = -2;
	public const uint32 SQL_NONSCROLLABLE = 0;
	public const uint32 SQL_SCROLLABLE = 1;
	public const uint32 SQL_DESC_COUNT = 1001;
	public const uint32 SQL_DESC_TYPE = 1002;
	public const uint32 SQL_DESC_LENGTH = 1003;
	public const uint32 SQL_DESC_OCTET_LENGTH_PTR = 1004;
	public const uint32 SQL_DESC_PRECISION = 1005;
	public const uint32 SQL_DESC_SCALE = 1006;
	public const uint32 SQL_DESC_DATETIME_INTERVAL_CODE = 1007;
	public const uint32 SQL_DESC_NULLABLE = 1008;
	public const uint32 SQL_DESC_INDICATOR_PTR = 1009;
	public const uint32 SQL_DESC_DATA_PTR = 1010;
	public const uint32 SQL_DESC_NAME = 1011;
	public const uint32 SQL_DESC_UNNAMED = 1012;
	public const uint32 SQL_DESC_OCTET_LENGTH = 1013;
	public const uint32 SQL_DESC_ALLOC_TYPE = 1099;
	public const uint32 SQL_DIAG_RETURNCODE = 1;
	public const uint32 SQL_DIAG_NUMBER = 2;
	public const uint32 SQL_DIAG_ROW_COUNT = 3;
	public const uint32 SQL_DIAG_SQLSTATE = 4;
	public const uint32 SQL_DIAG_NATIVE = 5;
	public const uint32 SQL_DIAG_MESSAGE_TEXT = 6;
	public const uint32 SQL_DIAG_DYNAMIC_FUNCTION = 7;
	public const uint32 SQL_DIAG_CLASS_ORIGIN = 8;
	public const uint32 SQL_DIAG_SUBCLASS_ORIGIN = 9;
	public const uint32 SQL_DIAG_CONNECTION_NAME = 10;
	public const uint32 SQL_DIAG_SERVER_NAME = 11;
	public const uint32 SQL_DIAG_DYNAMIC_FUNCTION_CODE = 12;
	public const uint32 SQL_DIAG_ALTER_DOMAIN = 3;
	public const uint32 SQL_DIAG_ALTER_TABLE = 4;
	public const uint32 SQL_DIAG_CALL = 7;
	public const uint32 SQL_DIAG_CREATE_ASSERTION = 6;
	public const uint32 SQL_DIAG_CREATE_CHARACTER_SET = 8;
	public const uint32 SQL_DIAG_CREATE_COLLATION = 10;
	public const uint32 SQL_DIAG_CREATE_DOMAIN = 23;
	public const int32 SQL_DIAG_CREATE_INDEX = -1;
	public const uint32 SQL_DIAG_CREATE_SCHEMA = 64;
	public const uint32 SQL_DIAG_CREATE_TABLE = 77;
	public const uint32 SQL_DIAG_CREATE_TRANSLATION = 79;
	public const uint32 SQL_DIAG_CREATE_VIEW = 84;
	public const uint32 SQL_DIAG_DELETE_WHERE = 19;
	public const uint32 SQL_DIAG_DROP_ASSERTION = 24;
	public const uint32 SQL_DIAG_DROP_CHARACTER_SET = 25;
	public const uint32 SQL_DIAG_DROP_COLLATION = 26;
	public const uint32 SQL_DIAG_DROP_DOMAIN = 27;
	public const int32 SQL_DIAG_DROP_INDEX = -2;
	public const uint32 SQL_DIAG_DROP_SCHEMA = 31;
	public const uint32 SQL_DIAG_DROP_TABLE = 32;
	public const uint32 SQL_DIAG_DROP_TRANSLATION = 33;
	public const uint32 SQL_DIAG_DROP_VIEW = 36;
	public const uint32 SQL_DIAG_DYNAMIC_DELETE_CURSOR = 38;
	public const uint32 SQL_DIAG_DYNAMIC_UPDATE_CURSOR = 81;
	public const uint32 SQL_DIAG_GRANT = 48;
	public const uint32 SQL_DIAG_INSERT = 50;
	public const uint32 SQL_DIAG_REVOKE = 59;
	public const uint32 SQL_DIAG_SELECT_CURSOR = 85;
	public const uint32 SQL_DIAG_UNKNOWN_STATEMENT = 0;
	public const uint32 SQL_DIAG_UPDATE_WHERE = 82;
	public const uint32 SQL_UNKNOWN_TYPE = 0;
	public const uint32 SQL_CHAR = 1;
	public const uint32 SQL_NUMERIC = 2;
	public const uint32 SQL_DECIMAL = 3;
	public const uint32 SQL_INTEGER = 4;
	public const uint32 SQL_SMALLINT = 5;
	public const uint32 SQL_FLOAT = 6;
	public const uint32 SQL_REAL = 7;
	public const uint32 SQL_DOUBLE = 8;
	public const uint32 SQL_DATETIME = 9;
	public const uint32 SQL_VARCHAR = 12;
	public const uint32 SQL_TYPE_DATE = 91;
	public const uint32 SQL_TYPE_TIME = 92;
	public const uint32 SQL_TYPE_TIMESTAMP = 93;
	public const uint32 SQL_UNSPECIFIED = 0;
	public const uint32 SQL_INSENSITIVE = 1;
	public const uint32 SQL_SENSITIVE = 2;
	public const uint32 SQL_ALL_TYPES = 0;
	public const uint32 SQL_DEFAULT = 99;
	public const int32 SQL_ARD_TYPE = -99;
	public const int32 SQL_APD_TYPE = -100;
	public const uint32 SQL_CODE_DATE = 1;
	public const uint32 SQL_CODE_TIME = 2;
	public const uint32 SQL_CODE_TIMESTAMP = 3;
	public const uint32 SQL_FALSE = 0;
	public const uint32 SQL_TRUE = 1;
	public const uint32 SQL_NO_NULLS = 0;
	public const uint32 SQL_NULLABLE = 1;
	public const uint32 SQL_NULLABLE_UNKNOWN = 2;
	public const uint32 SQL_PRED_NONE = 0;
	public const uint32 SQL_PRED_CHAR = 1;
	public const uint32 SQL_PRED_BASIC = 2;
	public const uint32 SQL_NAMED = 0;
	public const uint32 SQL_UNNAMED = 1;
	public const uint32 SQL_DESC_ALLOC_AUTO = 1;
	public const uint32 SQL_DESC_ALLOC_USER = 2;
	public const uint32 SQL_CLOSE = 0;
	public const uint32 SQL_DROP = 1;
	public const uint32 SQL_UNBIND = 2;
	public const uint32 SQL_RESET_PARAMS = 3;
	public const uint32 SQL_FETCH_NEXT = 1;
	public const uint32 SQL_FETCH_FIRST = 2;
	public const uint32 SQL_FETCH_LAST = 3;
	public const uint32 SQL_FETCH_PRIOR = 4;
	public const uint32 SQL_FETCH_ABSOLUTE = 5;
	public const uint32 SQL_FETCH_RELATIVE = 6;
	public const uint32 SQL_COMMIT = 0;
	public const uint32 SQL_ROLLBACK = 1;
	public const uint32 SQL_NULL_HENV = 0;
	public const uint32 SQL_NULL_HDBC = 0;
	public const uint32 SQL_NULL_HSTMT = 0;
	public const uint32 SQL_NULL_HDESC = 0;
	public const int32 SQL_NULL_HANDLE = 0;
	public const uint32 SQL_SCOPE_CURROW = 0;
	public const uint32 SQL_SCOPE_TRANSACTION = 1;
	public const uint32 SQL_SCOPE_SESSION = 2;
	public const uint32 SQL_PC_UNKNOWN = 0;
	public const uint32 SQL_PC_NON_PSEUDO = 1;
	public const uint32 SQL_PC_PSEUDO = 2;
	public const uint32 SQL_ROW_IDENTIFIER = 1;
	public const uint32 SQL_INDEX_UNIQUE = 0;
	public const uint32 SQL_INDEX_ALL = 1;
	public const uint32 SQL_INDEX_CLUSTERED = 1;
	public const uint32 SQL_INDEX_HASHED = 2;
	public const uint32 SQL_INDEX_OTHER = 3;
	public const uint32 SQL_API_SQLALLOCCONNECT = 1;
	public const uint32 SQL_API_SQLALLOCENV = 2;
	public const uint32 SQL_API_SQLALLOCHANDLE = 1001;
	public const uint32 SQL_API_SQLALLOCSTMT = 3;
	public const uint32 SQL_API_SQLBINDCOL = 4;
	public const uint32 SQL_API_SQLBINDPARAM = 1002;
	public const uint32 SQL_API_SQLCANCEL = 5;
	public const uint32 SQL_API_SQLCLOSECURSOR = 1003;
	public const uint32 SQL_API_SQLCOLATTRIBUTE = 6;
	public const uint32 SQL_API_SQLCOLUMNS = 40;
	public const uint32 SQL_API_SQLCONNECT = 7;
	public const uint32 SQL_API_SQLCOPYDESC = 1004;
	public const uint32 SQL_API_SQLDATASOURCES = 57;
	public const uint32 SQL_API_SQLDESCRIBECOL = 8;
	public const uint32 SQL_API_SQLDISCONNECT = 9;
	public const uint32 SQL_API_SQLENDTRAN = 1005;
	public const uint32 SQL_API_SQLERROR = 10;
	public const uint32 SQL_API_SQLEXECDIRECT = 11;
	public const uint32 SQL_API_SQLEXECUTE = 12;
	public const uint32 SQL_API_SQLFETCH = 13;
	public const uint32 SQL_API_SQLFETCHSCROLL = 1021;
	public const uint32 SQL_API_SQLFREECONNECT = 14;
	public const uint32 SQL_API_SQLFREEENV = 15;
	public const uint32 SQL_API_SQLFREEHANDLE = 1006;
	public const uint32 SQL_API_SQLFREESTMT = 16;
	public const uint32 SQL_API_SQLGETCONNECTATTR = 1007;
	public const uint32 SQL_API_SQLGETCONNECTOPTION = 42;
	public const uint32 SQL_API_SQLGETCURSORNAME = 17;
	public const uint32 SQL_API_SQLGETDATA = 43;
	public const uint32 SQL_API_SQLGETDESCFIELD = 1008;
	public const uint32 SQL_API_SQLGETDESCREC = 1009;
	public const uint32 SQL_API_SQLGETDIAGFIELD = 1010;
	public const uint32 SQL_API_SQLGETDIAGREC = 1011;
	public const uint32 SQL_API_SQLGETENVATTR = 1012;
	public const uint32 SQL_API_SQLGETFUNCTIONS = 44;
	public const uint32 SQL_API_SQLGETINFO = 45;
	public const uint32 SQL_API_SQLGETSTMTATTR = 1014;
	public const uint32 SQL_API_SQLGETSTMTOPTION = 46;
	public const uint32 SQL_API_SQLGETTYPEINFO = 47;
	public const uint32 SQL_API_SQLNUMRESULTCOLS = 18;
	public const uint32 SQL_API_SQLPARAMDATA = 48;
	public const uint32 SQL_API_SQLPREPARE = 19;
	public const uint32 SQL_API_SQLPUTDATA = 49;
	public const uint32 SQL_API_SQLROWCOUNT = 20;
	public const uint32 SQL_API_SQLSETCONNECTATTR = 1016;
	public const uint32 SQL_API_SQLSETCONNECTOPTION = 50;
	public const uint32 SQL_API_SQLSETCURSORNAME = 21;
	public const uint32 SQL_API_SQLSETDESCFIELD = 1017;
	public const uint32 SQL_API_SQLSETDESCREC = 1018;
	public const uint32 SQL_API_SQLSETENVATTR = 1019;
	public const uint32 SQL_API_SQLSETPARAM = 22;
	public const uint32 SQL_API_SQLSETSTMTATTR = 1020;
	public const uint32 SQL_API_SQLSETSTMTOPTION = 51;
	public const uint32 SQL_API_SQLSPECIALCOLUMNS = 52;
	public const uint32 SQL_API_SQLSTATISTICS = 53;
	public const uint32 SQL_API_SQLTABLES = 54;
	public const uint32 SQL_API_SQLTRANSACT = 23;
	public const uint32 SQL_API_SQLCANCELHANDLE = 1550;
	public const uint32 SQL_API_SQLCOMPLETEASYNC = 1551;
	public const uint32 SQL_MAX_DRIVER_CONNECTIONS = 0;
	public const uint32 SQL_MAXIMUM_DRIVER_CONNECTIONS = 0;
	public const uint32 SQL_MAX_CONCURRENT_ACTIVITIES = 1;
	public const uint32 SQL_MAXIMUM_CONCURRENT_ACTIVITIES = 1;
	public const uint32 SQL_DATA_SOURCE_NAME = 2;
	public const uint32 SQL_FETCH_DIRECTION = 8;
	public const uint32 SQL_SERVER_NAME = 13;
	public const uint32 SQL_SEARCH_PATTERN_ESCAPE = 14;
	public const uint32 SQL_DBMS_NAME = 17;
	public const uint32 SQL_DBMS_VER = 18;
	public const uint32 SQL_ACCESSIBLE_TABLES = 19;
	public const uint32 SQL_ACCESSIBLE_PROCEDURES = 20;
	public const uint32 SQL_CURSOR_COMMIT_BEHAVIOR = 23;
	public const uint32 SQL_DATA_SOURCE_READ_ONLY = 25;
	public const uint32 SQL_DEFAULT_TXN_ISOLATION = 26;
	public const uint32 SQL_IDENTIFIER_CASE = 28;
	public const uint32 SQL_IDENTIFIER_QUOTE_CHAR = 29;
	public const uint32 SQL_MAX_COLUMN_NAME_LEN = 30;
	public const uint32 SQL_MAXIMUM_COLUMN_NAME_LENGTH = 30;
	public const uint32 SQL_MAX_CURSOR_NAME_LEN = 31;
	public const uint32 SQL_MAXIMUM_CURSOR_NAME_LENGTH = 31;
	public const uint32 SQL_MAX_SCHEMA_NAME_LEN = 32;
	public const uint32 SQL_MAXIMUM_SCHEMA_NAME_LENGTH = 32;
	public const uint32 SQL_MAX_CATALOG_NAME_LEN = 34;
	public const uint32 SQL_MAXIMUM_CATALOG_NAME_LENGTH = 34;
	public const uint32 SQL_MAX_TABLE_NAME_LEN = 35;
	public const uint32 SQL_SCROLL_CONCURRENCY = 43;
	public const uint32 SQL_TXN_CAPABLE = 46;
	public const uint32 SQL_TRANSACTION_CAPABLE = 46;
	public const uint32 SQL_USER_NAME = 47;
	public const uint32 SQL_TXN_ISOLATION_OPTION = 72;
	public const uint32 SQL_TRANSACTION_ISOLATION_OPTION = 72;
	public const uint32 SQL_INTEGRITY = 73;
	public const uint32 SQL_GETDATA_EXTENSIONS = 81;
	public const uint32 SQL_NULL_COLLATION = 85;
	public const uint32 SQL_ALTER_TABLE = 86;
	public const uint32 SQL_ORDER_BY_COLUMNS_IN_SELECT = 90;
	public const uint32 SQL_SPECIAL_CHARACTERS = 94;
	public const uint32 SQL_MAX_COLUMNS_IN_GROUP_BY = 97;
	public const uint32 SQL_MAXIMUM_COLUMNS_IN_GROUP_BY = 97;
	public const uint32 SQL_MAX_COLUMNS_IN_INDEX = 98;
	public const uint32 SQL_MAXIMUM_COLUMNS_IN_INDEX = 98;
	public const uint32 SQL_MAX_COLUMNS_IN_ORDER_BY = 99;
	public const uint32 SQL_MAXIMUM_COLUMNS_IN_ORDER_BY = 99;
	public const uint32 SQL_MAX_COLUMNS_IN_SELECT = 100;
	public const uint32 SQL_MAXIMUM_COLUMNS_IN_SELECT = 100;
	public const uint32 SQL_MAX_COLUMNS_IN_TABLE = 101;
	public const uint32 SQL_MAX_INDEX_SIZE = 102;
	public const uint32 SQL_MAXIMUM_INDEX_SIZE = 102;
	public const uint32 SQL_MAX_ROW_SIZE = 104;
	public const uint32 SQL_MAXIMUM_ROW_SIZE = 104;
	public const uint32 SQL_MAX_STATEMENT_LEN = 105;
	public const uint32 SQL_MAXIMUM_STATEMENT_LENGTH = 105;
	public const uint32 SQL_MAX_TABLES_IN_SELECT = 106;
	public const uint32 SQL_MAXIMUM_TABLES_IN_SELECT = 106;
	public const uint32 SQL_MAX_USER_NAME_LEN = 107;
	public const uint32 SQL_MAXIMUM_USER_NAME_LENGTH = 107;
	public const uint32 SQL_OJ_CAPABILITIES = 115;
	public const uint32 SQL_OUTER_JOIN_CAPABILITIES = 115;
	public const uint32 SQL_XOPEN_CLI_YEAR = 10000;
	public const uint32 SQL_CURSOR_SENSITIVITY = 10001;
	public const uint32 SQL_DESCRIBE_PARAMETER = 10002;
	public const uint32 SQL_CATALOG_NAME = 10003;
	public const uint32 SQL_COLLATION_SEQ = 10004;
	public const uint32 SQL_MAX_IDENTIFIER_LEN = 10005;
	public const uint32 SQL_MAXIMUM_IDENTIFIER_LENGTH = 10005;
	public const int32 SQL_AT_ADD_COLUMN = 1;
	public const int32 SQL_AT_DROP_COLUMN = 2;
	public const int32 SQL_AT_ADD_CONSTRAINT = 8;
	public const uint32 SQL_AM_NONE = 0;
	public const uint32 SQL_AM_CONNECTION = 1;
	public const uint32 SQL_AM_STATEMENT = 2;
	public const uint32 SQL_CB_DELETE = 0;
	public const uint32 SQL_CB_CLOSE = 1;
	public const uint32 SQL_CB_PRESERVE = 2;
	public const int32 SQL_FD_FETCH_NEXT = 1;
	public const int32 SQL_FD_FETCH_FIRST = 2;
	public const int32 SQL_FD_FETCH_LAST = 4;
	public const int32 SQL_FD_FETCH_PRIOR = 8;
	public const int32 SQL_FD_FETCH_ABSOLUTE = 16;
	public const int32 SQL_FD_FETCH_RELATIVE = 32;
	public const int32 SQL_GD_ANY_COLUMN = 1;
	public const int32 SQL_GD_ANY_ORDER = 2;
	public const uint32 SQL_IC_UPPER = 1;
	public const uint32 SQL_IC_LOWER = 2;
	public const uint32 SQL_IC_SENSITIVE = 3;
	public const uint32 SQL_IC_MIXED = 4;
	public const int32 SQL_OJ_LEFT = 1;
	public const int32 SQL_OJ_RIGHT = 2;
	public const int32 SQL_OJ_FULL = 4;
	public const int32 SQL_OJ_NESTED = 8;
	public const int32 SQL_OJ_NOT_ORDERED = 16;
	public const int32 SQL_OJ_INNER = 32;
	public const int32 SQL_OJ_ALL_COMPARISON_OPS = 64;
	public const int32 SQL_SCCO_READ_ONLY = 1;
	public const int32 SQL_SCCO_LOCK = 2;
	public const int32 SQL_SCCO_OPT_ROWVER = 4;
	public const int32 SQL_SCCO_OPT_VALUES = 8;
	public const uint32 SQL_TC_NONE = 0;
	public const uint32 SQL_TC_DML = 1;
	public const uint32 SQL_TC_ALL = 2;
	public const uint32 SQL_TC_DDL_COMMIT = 3;
	public const uint32 SQL_TC_DDL_IGNORE = 4;
	public const int32 SQL_TXN_READ_UNCOMMITTED = 1;
	public const int32 SQL_TRANSACTION_READ_UNCOMMITTED = 1;
	public const int32 SQL_TXN_READ_COMMITTED = 2;
	public const int32 SQL_TRANSACTION_READ_COMMITTED = 2;
	public const int32 SQL_TXN_REPEATABLE_READ = 4;
	public const int32 SQL_TRANSACTION_REPEATABLE_READ = 4;
	public const int32 SQL_TXN_SERIALIZABLE = 8;
	public const int32 SQL_TRANSACTION_SERIALIZABLE = 8;
	public const uint32 SQL_NC_HIGH = 0;
	public const uint32 SQL_NC_LOW = 1;
	public const uint32 SQL_SPEC_MAJOR = 3;
	public const uint32 SQL_SPEC_MINOR = 80;
	public const String SQL_SPEC_STRING = "03.80";
	public const uint32 SQL_SQLSTATE_SIZE = 5;
	public const uint32 SQL_MAX_DSN_LENGTH = 32;
	public const uint32 SQL_MAX_OPTION_STRING_LENGTH = 256;
	public const uint32 SQL_NO_DATA_FOUND = 100;
	public const uint32 SQL_HANDLE_SENV = 5;
	public const uint32 SQL_ATTR_ODBC_VERSION = 200;
	public const uint32 SQL_ATTR_CONNECTION_POOLING = 201;
	public const uint32 SQL_ATTR_CP_MATCH = 202;
	public const uint32 SQL_ATTR_APPLICATION_KEY = 203;
	public const uint32 SQL_CP_OFF = 0;
	public const uint32 SQL_CP_ONE_PER_DRIVER = 1;
	public const uint32 SQL_CP_ONE_PER_HENV = 2;
	public const uint32 SQL_CP_DRIVER_AWARE = 3;
	public const uint32 SQL_CP_DEFAULT = 0;
	public const uint32 SQL_CP_STRICT_MATCH = 0;
	public const uint32 SQL_CP_RELAXED_MATCH = 1;
	public const uint32 SQL_CP_MATCH_DEFAULT = 0;
	public const uint32 SQL_OV_ODBC2 = 2;
	public const uint32 SQL_OV_ODBC3 = 3;
	public const uint32 SQL_OV_ODBC3_80 = 380;
	public const uint32 SQL_ACCESS_MODE = 101;
	public const uint32 SQL_AUTOCOMMIT = 102;
	public const uint32 SQL_LOGIN_TIMEOUT = 103;
	public const uint32 SQL_OPT_TRACE = 104;
	public const uint32 SQL_OPT_TRACEFILE = 105;
	public const uint32 SQL_TRANSLATE_DLL = 106;
	public const uint32 SQL_TRANSLATE_OPTION = 107;
	public const uint32 SQL_TXN_ISOLATION = 108;
	public const uint32 SQL_CURRENT_QUALIFIER = 109;
	public const uint32 SQL_ODBC_CURSORS = 110;
	public const uint32 SQL_QUIET_MODE = 111;
	public const uint32 SQL_PACKET_SIZE = 112;
	public const uint32 SQL_ATTR_ACCESS_MODE = 101;
	public const uint32 SQL_ATTR_AUTOCOMMIT = 102;
	public const uint32 SQL_ATTR_CONNECTION_TIMEOUT = 113;
	public const uint32 SQL_ATTR_CURRENT_CATALOG = 109;
	public const uint32 SQL_ATTR_DISCONNECT_BEHAVIOR = 114;
	public const uint32 SQL_ATTR_ENLIST_IN_DTC = 1207;
	public const uint32 SQL_ATTR_ENLIST_IN_XA = 1208;
	public const uint32 SQL_ATTR_LOGIN_TIMEOUT = 103;
	public const uint32 SQL_ATTR_ODBC_CURSORS = 110;
	public const uint32 SQL_ATTR_PACKET_SIZE = 112;
	public const uint32 SQL_ATTR_QUIET_MODE = 111;
	public const uint32 SQL_ATTR_TRACE = 104;
	public const uint32 SQL_ATTR_TRACEFILE = 105;
	public const uint32 SQL_ATTR_TRANSLATE_LIB = 106;
	public const uint32 SQL_ATTR_TRANSLATE_OPTION = 107;
	public const uint32 SQL_ATTR_TXN_ISOLATION = 108;
	public const uint32 SQL_ATTR_CONNECTION_DEAD = 1209;
	public const uint32 SQL_ATTR_ANSI_APP = 115;
	public const uint32 SQL_ATTR_RESET_CONNECTION = 116;
	public const uint32 SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE = 117;
	public const uint32 SQL_ATTR_ASYNC_DBC_EVENT = 119;
	public const uint32 SQL_CONNECT_OPT_DRVR_START = 1000;
	public const uint32 SQL_CONN_OPT_MAX = 112;
	public const uint32 SQL_CONN_OPT_MIN = 101;
	public const uint32 SQL_MODE_READ_WRITE = 0;
	public const uint32 SQL_MODE_READ_ONLY = 1;
	public const uint32 SQL_MODE_DEFAULT = 0;
	public const uint32 SQL_AUTOCOMMIT_OFF = 0;
	public const uint32 SQL_AUTOCOMMIT_ON = 1;
	public const uint32 SQL_AUTOCOMMIT_DEFAULT = 1;
	public const uint32 SQL_LOGIN_TIMEOUT_DEFAULT = 15;
	public const uint32 SQL_OPT_TRACE_OFF = 0;
	public const uint32 SQL_OPT_TRACE_ON = 1;
	public const uint32 SQL_OPT_TRACE_DEFAULT = 0;
	public const String SQL_OPT_TRACE_FILE_DEFAULT = "\\SQL.LOG";
	public const uint32 SQL_CUR_USE_IF_NEEDED = 0;
	public const uint32 SQL_CUR_USE_ODBC = 1;
	public const uint32 SQL_CUR_USE_DRIVER = 2;
	public const uint32 SQL_CUR_DEFAULT = 2;
	public const uint32 SQL_DB_RETURN_TO_POOL = 0;
	public const uint32 SQL_DB_DISCONNECT = 1;
	public const uint32 SQL_DB_DEFAULT = 0;
	public const int32 SQL_DTC_DONE = 0;
	public const int32 SQL_CD_TRUE = 1;
	public const int32 SQL_CD_FALSE = 0;
	public const int32 SQL_AA_TRUE = 1;
	public const int32 SQL_AA_FALSE = 0;
	public const uint32 SQL_RESET_CONNECTION_YES = 1;
	public const uint32 SQL_ASYNC_DBC_ENABLE_ON = 1;
	public const uint32 SQL_ASYNC_DBC_ENABLE_OFF = 0;
	public const uint32 SQL_ASYNC_DBC_ENABLE_DEFAULT = 0;
	public const uint32 SQL_QUERY_TIMEOUT = 0;
	public const uint32 SQL_MAX_ROWS = 1;
	public const uint32 SQL_NOSCAN = 2;
	public const uint32 SQL_MAX_LENGTH = 3;
	public const uint32 SQL_ASYNC_ENABLE = 4;
	public const uint32 SQL_BIND_TYPE = 5;
	public const uint32 SQL_CURSOR_TYPE = 6;
	public const uint32 SQL_CONCURRENCY = 7;
	public const uint32 SQL_KEYSET_SIZE = 8;
	public const uint32 SQL_ROWSET_SIZE = 9;
	public const uint32 SQL_SIMULATE_CURSOR = 10;
	public const uint32 SQL_RETRIEVE_DATA = 11;
	public const uint32 SQL_USE_BOOKMARKS = 12;
	public const uint32 SQL_GET_BOOKMARK = 13;
	public const uint32 SQL_ROW_NUMBER = 14;
	public const uint32 SQL_ATTR_ASYNC_ENABLE = 4;
	public const uint32 SQL_ATTR_CONCURRENCY = 7;
	public const uint32 SQL_ATTR_CURSOR_TYPE = 6;
	public const uint32 SQL_ATTR_ENABLE_AUTO_IPD = 15;
	public const uint32 SQL_ATTR_FETCH_BOOKMARK_PTR = 16;
	public const uint32 SQL_ATTR_KEYSET_SIZE = 8;
	public const uint32 SQL_ATTR_MAX_LENGTH = 3;
	public const uint32 SQL_ATTR_MAX_ROWS = 1;
	public const uint32 SQL_ATTR_NOSCAN = 2;
	public const uint32 SQL_ATTR_PARAM_BIND_OFFSET_PTR = 17;
	public const uint32 SQL_ATTR_PARAM_BIND_TYPE = 18;
	public const uint32 SQL_ATTR_PARAM_OPERATION_PTR = 19;
	public const uint32 SQL_ATTR_PARAM_STATUS_PTR = 20;
	public const uint32 SQL_ATTR_PARAMS_PROCESSED_PTR = 21;
	public const uint32 SQL_ATTR_PARAMSET_SIZE = 22;
	public const uint32 SQL_ATTR_QUERY_TIMEOUT = 0;
	public const uint32 SQL_ATTR_RETRIEVE_DATA = 11;
	public const uint32 SQL_ATTR_ROW_BIND_OFFSET_PTR = 23;
	public const uint32 SQL_ATTR_ROW_BIND_TYPE = 5;
	public const uint32 SQL_ATTR_ROW_NUMBER = 14;
	public const uint32 SQL_ATTR_ROW_OPERATION_PTR = 24;
	public const uint32 SQL_ATTR_ROW_STATUS_PTR = 25;
	public const uint32 SQL_ATTR_ROWS_FETCHED_PTR = 26;
	public const uint32 SQL_ATTR_ROW_ARRAY_SIZE = 27;
	public const uint32 SQL_ATTR_SIMULATE_CURSOR = 10;
	public const uint32 SQL_ATTR_USE_BOOKMARKS = 12;
	public const uint32 SQL_ATTR_ASYNC_STMT_EVENT = 29;
	public const uint32 SQL_STMT_OPT_MAX = 14;
	public const uint32 SQL_STMT_OPT_MIN = 0;
	public const int32 SQL_IS_POINTER = -4;
	public const int32 SQL_IS_UINTEGER = -5;
	public const int32 SQL_IS_INTEGER = -6;
	public const int32 SQL_IS_USMALLINT = -7;
	public const int32 SQL_IS_SMALLINT = -8;
	public const uint32 SQL_PARAM_BIND_BY_COLUMN = 0;
	public const uint32 SQL_PARAM_BIND_TYPE_DEFAULT = 0;
	public const uint32 SQL_QUERY_TIMEOUT_DEFAULT = 0;
	public const uint32 SQL_MAX_ROWS_DEFAULT = 0;
	public const uint32 SQL_NOSCAN_OFF = 0;
	public const uint32 SQL_NOSCAN_ON = 1;
	public const uint32 SQL_NOSCAN_DEFAULT = 0;
	public const uint32 SQL_MAX_LENGTH_DEFAULT = 0;
	public const uint32 SQL_ASYNC_ENABLE_OFF = 0;
	public const uint32 SQL_ASYNC_ENABLE_ON = 1;
	public const uint32 SQL_ASYNC_ENABLE_DEFAULT = 0;
	public const uint32 SQL_BIND_BY_COLUMN = 0;
	public const uint32 SQL_BIND_TYPE_DEFAULT = 0;
	public const uint32 SQL_CONCUR_READ_ONLY = 1;
	public const uint32 SQL_CONCUR_LOCK = 2;
	public const uint32 SQL_CONCUR_ROWVER = 3;
	public const uint32 SQL_CONCUR_VALUES = 4;
	public const uint32 SQL_CONCUR_DEFAULT = 1;
	public const uint32 SQL_CURSOR_FORWARD_ONLY = 0;
	public const uint32 SQL_CURSOR_KEYSET_DRIVEN = 1;
	public const uint32 SQL_CURSOR_DYNAMIC = 2;
	public const uint32 SQL_CURSOR_STATIC = 3;
	public const uint32 SQL_CURSOR_TYPE_DEFAULT = 0;
	public const uint32 SQL_ROWSET_SIZE_DEFAULT = 1;
	public const uint32 SQL_KEYSET_SIZE_DEFAULT = 0;
	public const uint32 SQL_SC_NON_UNIQUE = 0;
	public const uint32 SQL_SC_TRY_UNIQUE = 1;
	public const uint32 SQL_SC_UNIQUE = 2;
	public const uint32 SQL_RD_OFF = 0;
	public const uint32 SQL_RD_ON = 1;
	public const uint32 SQL_RD_DEFAULT = 1;
	public const uint32 SQL_UB_OFF = 0;
	public const uint32 SQL_UB_ON = 1;
	public const uint32 SQL_UB_DEFAULT = 0;
	public const uint32 SQL_UB_FIXED = 1;
	public const uint32 SQL_UB_VARIABLE = 2;
	public const uint32 SQL_DESC_ARRAY_SIZE = 20;
	public const uint32 SQL_DESC_ARRAY_STATUS_PTR = 21;
	public const uint32 SQL_DESC_BASE_COLUMN_NAME = 22;
	public const uint32 SQL_DESC_BASE_TABLE_NAME = 23;
	public const uint32 SQL_DESC_BIND_OFFSET_PTR = 24;
	public const uint32 SQL_DESC_BIND_TYPE = 25;
	public const uint32 SQL_DESC_DATETIME_INTERVAL_PRECISION = 26;
	public const uint32 SQL_DESC_LITERAL_PREFIX = 27;
	public const uint32 SQL_DESC_LITERAL_SUFFIX = 28;
	public const uint32 SQL_DESC_LOCAL_TYPE_NAME = 29;
	public const uint32 SQL_DESC_MAXIMUM_SCALE = 30;
	public const uint32 SQL_DESC_MINIMUM_SCALE = 31;
	public const uint32 SQL_DESC_NUM_PREC_RADIX = 32;
	public const uint32 SQL_DESC_PARAMETER_TYPE = 33;
	public const uint32 SQL_DESC_ROWS_PROCESSED_PTR = 34;
	public const uint32 SQL_DESC_ROWVER = 35;
	public const int32 SQL_DIAG_CURSOR_ROW_COUNT = -1249;
	public const int32 SQL_DIAG_ROW_NUMBER = -1248;
	public const int32 SQL_DIAG_COLUMN_NUMBER = -1247;
	public const uint32 SQL_DATE = 9;
	public const uint32 SQL_INTERVAL = 10;
	public const uint32 SQL_TIME = 10;
	public const uint32 SQL_TIMESTAMP = 11;
	public const int32 SQL_LONGVARCHAR = -1;
	public const int32 SQL_BINARY = -2;
	public const int32 SQL_VARBINARY = -3;
	public const int32 SQL_LONGVARBINARY = -4;
	public const int32 SQL_BIGINT = -5;
	public const int32 SQL_TINYINT = -6;
	public const int32 SQL_BIT = -7;
	public const int32 SQL_GUID = -11;
	public const uint32 SQL_CODE_YEAR = 1;
	public const uint32 SQL_CODE_MONTH = 2;
	public const uint32 SQL_CODE_DAY = 3;
	public const uint32 SQL_CODE_HOUR = 4;
	public const uint32 SQL_CODE_MINUTE = 5;
	public const uint32 SQL_CODE_SECOND = 6;
	public const uint32 SQL_CODE_YEAR_TO_MONTH = 7;
	public const uint32 SQL_CODE_DAY_TO_HOUR = 8;
	public const uint32 SQL_CODE_DAY_TO_MINUTE = 9;
	public const uint32 SQL_CODE_DAY_TO_SECOND = 10;
	public const uint32 SQL_CODE_HOUR_TO_MINUTE = 11;
	public const uint32 SQL_CODE_HOUR_TO_SECOND = 12;
	public const uint32 SQL_CODE_MINUTE_TO_SECOND = 13;
	public const int32 SQL_INTERVAL_YEAR = -80;
	public const int32 SQL_INTERVAL_MONTH = -81;
	public const int32 SQL_INTERVAL_YEAR_TO_MONTH = -82;
	public const int32 SQL_INTERVAL_DAY = -83;
	public const int32 SQL_INTERVAL_HOUR = -84;
	public const int32 SQL_INTERVAL_MINUTE = -85;
	public const int32 SQL_INTERVAL_SECOND = -86;
	public const int32 SQL_INTERVAL_DAY_TO_HOUR = -87;
	public const int32 SQL_INTERVAL_DAY_TO_MINUTE = -88;
	public const int32 SQL_INTERVAL_DAY_TO_SECOND = -89;
	public const int32 SQL_INTERVAL_HOUR_TO_MINUTE = -90;
	public const int32 SQL_INTERVAL_HOUR_TO_SECOND = -91;
	public const int32 SQL_INTERVAL_MINUTE_TO_SECOND = -92;
	public const int32 SQL_UNICODE = -95;
	public const int32 SQL_UNICODE_VARCHAR = -96;
	public const int32 SQL_UNICODE_LONGVARCHAR = -97;
	public const int32 SQL_UNICODE_CHAR = -95;
	public const int32 SQL_TYPE_DRIVER_START = -80;
	public const int32 SQL_TYPE_DRIVER_END = -97;
	public const uint32 SQL_C_CHAR = 1;
	public const uint32 SQL_C_LONG = 4;
	public const uint32 SQL_C_SHORT = 5;
	public const uint32 SQL_C_FLOAT = 7;
	public const uint32 SQL_C_DOUBLE = 8;
	public const uint32 SQL_C_NUMERIC = 2;
	public const uint32 SQL_C_DEFAULT = 99;
	public const int32 SQL_SIGNED_OFFSET = -20;
	public const int32 SQL_UNSIGNED_OFFSET = -22;
	public const uint32 SQL_C_DATE = 9;
	public const uint32 SQL_C_TIME = 10;
	public const uint32 SQL_C_TIMESTAMP = 11;
	public const uint32 SQL_C_TYPE_DATE = 91;
	public const uint32 SQL_C_TYPE_TIME = 92;
	public const uint32 SQL_C_TYPE_TIMESTAMP = 93;
	public const int32 SQL_C_INTERVAL_YEAR = -80;
	public const int32 SQL_C_INTERVAL_MONTH = -81;
	public const int32 SQL_C_INTERVAL_DAY = -83;
	public const int32 SQL_C_INTERVAL_HOUR = -84;
	public const int32 SQL_C_INTERVAL_MINUTE = -85;
	public const int32 SQL_C_INTERVAL_SECOND = -86;
	public const int32 SQL_C_INTERVAL_YEAR_TO_MONTH = -82;
	public const int32 SQL_C_INTERVAL_DAY_TO_HOUR = -87;
	public const int32 SQL_C_INTERVAL_DAY_TO_MINUTE = -88;
	public const int32 SQL_C_INTERVAL_DAY_TO_SECOND = -89;
	public const int32 SQL_C_INTERVAL_HOUR_TO_MINUTE = -90;
	public const int32 SQL_C_INTERVAL_HOUR_TO_SECOND = -91;
	public const int32 SQL_C_INTERVAL_MINUTE_TO_SECOND = -92;
	public const int32 SQL_C_BINARY = -2;
	public const int32 SQL_C_BIT = -7;
	public const int32 SQL_C_TINYINT = -6;
	public const int32 SQL_C_GUID = -11;
	public const uint32 SQL_TYPE_NULL = 0;
	public const int32 SQL_TYPE_MIN = -7;
	public const uint32 SQL_TYPE_MAX = 12;
	public const uint32 SQL_DRIVER_C_TYPE_BASE = 16384;
	public const uint32 SQL_DRIVER_SQL_TYPE_BASE = 16384;
	public const uint32 SQL_DRIVER_DESC_FIELD_BASE = 16384;
	public const uint32 SQL_DRIVER_DIAG_FIELD_BASE = 16384;
	public const uint32 SQL_DRIVER_INFO_TYPE_BASE = 16384;
	public const uint32 SQL_DRIVER_CONN_ATTR_BASE = 16384;
	public const uint32 SQL_DRIVER_STMT_ATTR_BASE = 16384;
	public const int32 SQL_C_VARBOOKMARK = -2;
	public const int32 SQL_NO_ROW_NUMBER = -1;
	public const int32 SQL_NO_COLUMN_NUMBER = -1;
	public const int32 SQL_ROW_NUMBER_UNKNOWN = -2;
	public const int32 SQL_COLUMN_NUMBER_UNKNOWN = -2;
	public const int32 SQL_DEFAULT_PARAM = -5;
	public const int32 SQL_IGNORE = -6;
	public const int32 SQL_COLUMN_IGNORE = -6;
	public const int32 SQL_LEN_DATA_AT_EXEC_OFFSET = -100;
	public const int32 SQL_LEN_BINARY_ATTR_OFFSET = -100;
	public const int32 SQL_SETPARAM_VALUE_MAX = -1;
	public const uint32 SQL_COLUMN_COUNT = 0;
	public const uint32 SQL_COLUMN_NAME = 1;
	public const uint32 SQL_COLUMN_TYPE = 2;
	public const uint32 SQL_COLUMN_LENGTH = 3;
	public const uint32 SQL_COLUMN_PRECISION = 4;
	public const uint32 SQL_COLUMN_SCALE = 5;
	public const uint32 SQL_COLUMN_DISPLAY_SIZE = 6;
	public const uint32 SQL_COLUMN_NULLABLE = 7;
	public const uint32 SQL_COLUMN_UNSIGNED = 8;
	public const uint32 SQL_COLUMN_MONEY = 9;
	public const uint32 SQL_COLUMN_UPDATABLE = 10;
	public const uint32 SQL_COLUMN_AUTO_INCREMENT = 11;
	public const uint32 SQL_COLUMN_CASE_SENSITIVE = 12;
	public const uint32 SQL_COLUMN_SEARCHABLE = 13;
	public const uint32 SQL_COLUMN_TYPE_NAME = 14;
	public const uint32 SQL_COLUMN_TABLE_NAME = 15;
	public const uint32 SQL_COLUMN_OWNER_NAME = 16;
	public const uint32 SQL_COLUMN_QUALIFIER_NAME = 17;
	public const uint32 SQL_COLUMN_LABEL = 18;
	public const uint32 SQL_COLATT_OPT_MAX = 18;
	public const uint32 SQL_COLUMN_DRIVER_START = 1000;
	public const uint32 SQL_COLATT_OPT_MIN = 0;
	public const uint32 SQL_ATTR_READONLY = 0;
	public const uint32 SQL_ATTR_WRITE = 1;
	public const uint32 SQL_ATTR_READWRITE_UNKNOWN = 2;
	public const uint32 SQL_UNSEARCHABLE = 0;
	public const uint32 SQL_LIKE_ONLY = 1;
	public const uint32 SQL_ALL_EXCEPT_LIKE = 2;
	public const uint32 SQL_SEARCHABLE = 3;
	public const uint32 SQL_PRED_SEARCHABLE = 3;
	public const int32 SQL_NO_TOTAL = -4;
	public const uint32 SQL_API_SQLALLOCHANDLESTD = 73;
	public const uint32 SQL_API_SQLBULKOPERATIONS = 24;
	public const uint32 SQL_API_SQLBINDPARAMETER = 72;
	public const uint32 SQL_API_SQLBROWSECONNECT = 55;
	public const uint32 SQL_API_SQLCOLATTRIBUTES = 6;
	public const uint32 SQL_API_SQLCOLUMNPRIVILEGES = 56;
	public const uint32 SQL_API_SQLDESCRIBEPARAM = 58;
	public const uint32 SQL_API_SQLDRIVERCONNECT = 41;
	public const uint32 SQL_API_SQLDRIVERS = 71;
	public const uint32 SQL_API_SQLPRIVATEDRIVERS = 79;
	public const uint32 SQL_API_SQLEXTENDEDFETCH = 59;
	public const uint32 SQL_API_SQLFOREIGNKEYS = 60;
	public const uint32 SQL_API_SQLMORERESULTS = 61;
	public const uint32 SQL_API_SQLNATIVESQL = 62;
	public const uint32 SQL_API_SQLNUMPARAMS = 63;
	public const uint32 SQL_API_SQLPARAMOPTIONS = 64;
	public const uint32 SQL_API_SQLPRIMARYKEYS = 65;
	public const uint32 SQL_API_SQLPROCEDURECOLUMNS = 66;
	public const uint32 SQL_API_SQLPROCEDURES = 67;
	public const uint32 SQL_API_SQLSETPOS = 68;
	public const uint32 SQL_API_SQLSETSCROLLOPTIONS = 69;
	public const uint32 SQL_API_SQLTABLEPRIVILEGES = 70;
	public const uint32 SQL_EXT_API_LAST = 72;
	public const uint32 SQL_NUM_FUNCTIONS = 23;
	public const uint32 SQL_EXT_API_START = 40;
	public const uint32 SQL_API_ALL_FUNCTIONS = 0;
	public const uint32 SQL_API_LOADBYORDINAL = 199;
	public const uint32 SQL_API_ODBC3_ALL_FUNCTIONS = 999;
	public const uint32 SQL_API_ODBC3_ALL_FUNCTIONS_SIZE = 250;
	public const uint32 SQL_INFO_FIRST = 0;
	public const uint32 SQL_ACTIVE_CONNECTIONS = 0;
	public const uint32 SQL_ACTIVE_STATEMENTS = 1;
	public const uint32 SQL_DRIVER_HDBC = 3;
	public const uint32 SQL_DRIVER_HENV = 4;
	public const uint32 SQL_DRIVER_HSTMT = 5;
	public const uint32 SQL_DRIVER_NAME = 6;
	public const uint32 SQL_DRIVER_VER = 7;
	public const uint32 SQL_ODBC_API_CONFORMANCE = 9;
	public const uint32 SQL_ODBC_VER = 10;
	public const uint32 SQL_ROW_UPDATES = 11;
	public const uint32 SQL_ODBC_SAG_CLI_CONFORMANCE = 12;
	public const uint32 SQL_ODBC_SQL_CONFORMANCE = 15;
	public const uint32 SQL_PROCEDURES = 21;
	public const uint32 SQL_CONCAT_NULL_BEHAVIOR = 22;
	public const uint32 SQL_CURSOR_ROLLBACK_BEHAVIOR = 24;
	public const uint32 SQL_EXPRESSIONS_IN_ORDERBY = 27;
	public const uint32 SQL_MAX_OWNER_NAME_LEN = 32;
	public const uint32 SQL_MAX_PROCEDURE_NAME_LEN = 33;
	public const uint32 SQL_MAX_QUALIFIER_NAME_LEN = 34;
	public const uint32 SQL_MULT_RESULT_SETS = 36;
	public const uint32 SQL_MULTIPLE_ACTIVE_TXN = 37;
	public const uint32 SQL_OUTER_JOINS = 38;
	public const uint32 SQL_OWNER_TERM = 39;
	public const uint32 SQL_PROCEDURE_TERM = 40;
	public const uint32 SQL_QUALIFIER_NAME_SEPARATOR = 41;
	public const uint32 SQL_QUALIFIER_TERM = 42;
	public const uint32 SQL_SCROLL_OPTIONS = 44;
	public const uint32 SQL_TABLE_TERM = 45;
	public const uint32 SQL_CONVERT_FUNCTIONS = 48;
	public const uint32 SQL_NUMERIC_FUNCTIONS = 49;
	public const uint32 SQL_STRING_FUNCTIONS = 50;
	public const uint32 SQL_SYSTEM_FUNCTIONS = 51;
	public const uint32 SQL_TIMEDATE_FUNCTIONS = 52;
	public const uint32 SQL_CONVERT_BIGINT = 53;
	public const uint32 SQL_CONVERT_BINARY = 54;
	public const uint32 SQL_CONVERT_BIT = 55;
	public const uint32 SQL_CONVERT_CHAR = 56;
	public const uint32 SQL_CONVERT_DATE = 57;
	public const uint32 SQL_CONVERT_DECIMAL = 58;
	public const uint32 SQL_CONVERT_DOUBLE = 59;
	public const uint32 SQL_CONVERT_FLOAT = 60;
	public const uint32 SQL_CONVERT_INTEGER = 61;
	public const uint32 SQL_CONVERT_LONGVARCHAR = 62;
	public const uint32 SQL_CONVERT_NUMERIC = 63;
	public const uint32 SQL_CONVERT_REAL = 64;
	public const uint32 SQL_CONVERT_SMALLINT = 65;
	public const uint32 SQL_CONVERT_TIME = 66;
	public const uint32 SQL_CONVERT_TIMESTAMP = 67;
	public const uint32 SQL_CONVERT_TINYINT = 68;
	public const uint32 SQL_CONVERT_VARBINARY = 69;
	public const uint32 SQL_CONVERT_VARCHAR = 70;
	public const uint32 SQL_CONVERT_LONGVARBINARY = 71;
	public const uint32 SQL_ODBC_SQL_OPT_IEF = 73;
	public const uint32 SQL_CORRELATION_NAME = 74;
	public const uint32 SQL_NON_NULLABLE_COLUMNS = 75;
	public const uint32 SQL_DRIVER_HLIB = 76;
	public const uint32 SQL_DRIVER_ODBC_VER = 77;
	public const uint32 SQL_LOCK_TYPES = 78;
	public const uint32 SQL_POS_OPERATIONS = 79;
	public const uint32 SQL_POSITIONED_STATEMENTS = 80;
	public const uint32 SQL_BOOKMARK_PERSISTENCE = 82;
	public const uint32 SQL_STATIC_SENSITIVITY = 83;
	public const uint32 SQL_FILE_USAGE = 84;
	public const uint32 SQL_COLUMN_ALIAS = 87;
	public const uint32 SQL_GROUP_BY = 88;
	public const uint32 SQL_KEYWORDS = 89;
	public const uint32 SQL_OWNER_USAGE = 91;
	public const uint32 SQL_QUALIFIER_USAGE = 92;
	public const uint32 SQL_QUOTED_IDENTIFIER_CASE = 93;
	public const uint32 SQL_SUBQUERIES = 95;
	public const uint32 SQL_UNION = 96;
	public const uint32 SQL_MAX_ROW_SIZE_INCLUDES_LONG = 103;
	public const uint32 SQL_MAX_CHAR_LITERAL_LEN = 108;
	public const uint32 SQL_TIMEDATE_ADD_INTERVALS = 109;
	public const uint32 SQL_TIMEDATE_DIFF_INTERVALS = 110;
	public const uint32 SQL_NEED_LONG_DATA_LEN = 111;
	public const uint32 SQL_MAX_BINARY_LITERAL_LEN = 112;
	public const uint32 SQL_LIKE_ESCAPE_CLAUSE = 113;
	public const uint32 SQL_QUALIFIER_LOCATION = 114;
	public const uint32 SQL_INFO_LAST = 114;
	public const uint32 SQL_INFO_DRIVER_START = 1000;
	public const uint32 SQL_ACTIVE_ENVIRONMENTS = 116;
	public const uint32 SQL_ALTER_DOMAIN = 117;
	public const uint32 SQL_SQL_CONFORMANCE = 118;
	public const uint32 SQL_DATETIME_LITERALS = 119;
	public const uint32 SQL_ASYNC_MODE = 10021;
	public const uint32 SQL_BATCH_ROW_COUNT = 120;
	public const uint32 SQL_BATCH_SUPPORT = 121;
	public const uint32 SQL_CATALOG_LOCATION = 114;
	public const uint32 SQL_CATALOG_NAME_SEPARATOR = 41;
	public const uint32 SQL_CATALOG_TERM = 42;
	public const uint32 SQL_CATALOG_USAGE = 92;
	public const uint32 SQL_CONVERT_WCHAR = 122;
	public const uint32 SQL_CONVERT_INTERVAL_DAY_TIME = 123;
	public const uint32 SQL_CONVERT_INTERVAL_YEAR_MONTH = 124;
	public const uint32 SQL_CONVERT_WLONGVARCHAR = 125;
	public const uint32 SQL_CONVERT_WVARCHAR = 126;
	public const uint32 SQL_CREATE_ASSERTION = 127;
	public const uint32 SQL_CREATE_CHARACTER_SET = 128;
	public const uint32 SQL_CREATE_COLLATION = 129;
	public const uint32 SQL_CREATE_DOMAIN = 130;
	public const uint32 SQL_CREATE_SCHEMA = 131;
	public const uint32 SQL_CREATE_TABLE = 132;
	public const uint32 SQL_CREATE_TRANSLATION = 133;
	public const uint32 SQL_CREATE_VIEW = 134;
	public const uint32 SQL_DRIVER_HDESC = 135;
	public const uint32 SQL_DROP_ASSERTION = 136;
	public const uint32 SQL_DROP_CHARACTER_SET = 137;
	public const uint32 SQL_DROP_COLLATION = 138;
	public const uint32 SQL_DROP_DOMAIN = 139;
	public const uint32 SQL_DROP_SCHEMA = 140;
	public const uint32 SQL_DROP_TABLE = 141;
	public const uint32 SQL_DROP_TRANSLATION = 142;
	public const uint32 SQL_DROP_VIEW = 143;
	public const uint32 SQL_DYNAMIC_CURSOR_ATTRIBUTES1 = 144;
	public const uint32 SQL_DYNAMIC_CURSOR_ATTRIBUTES2 = 145;
	public const uint32 SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1 = 146;
	public const uint32 SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2 = 147;
	public const uint32 SQL_INDEX_KEYWORDS = 148;
	public const uint32 SQL_INFO_SCHEMA_VIEWS = 149;
	public const uint32 SQL_KEYSET_CURSOR_ATTRIBUTES1 = 150;
	public const uint32 SQL_KEYSET_CURSOR_ATTRIBUTES2 = 151;
	public const uint32 SQL_MAX_ASYNC_CONCURRENT_STATEMENTS = 10022;
	public const uint32 SQL_ODBC_INTERFACE_CONFORMANCE = 152;
	public const uint32 SQL_PARAM_ARRAY_ROW_COUNTS = 153;
	public const uint32 SQL_PARAM_ARRAY_SELECTS = 154;
	public const uint32 SQL_SCHEMA_TERM = 39;
	public const uint32 SQL_SCHEMA_USAGE = 91;
	public const uint32 SQL_SQL92_DATETIME_FUNCTIONS = 155;
	public const uint32 SQL_SQL92_FOREIGN_KEY_DELETE_RULE = 156;
	public const uint32 SQL_SQL92_FOREIGN_KEY_UPDATE_RULE = 157;
	public const uint32 SQL_SQL92_GRANT = 158;
	public const uint32 SQL_SQL92_NUMERIC_VALUE_FUNCTIONS = 159;
	public const uint32 SQL_SQL92_PREDICATES = 160;
	public const uint32 SQL_SQL92_RELATIONAL_JOIN_OPERATORS = 161;
	public const uint32 SQL_SQL92_REVOKE = 162;
	public const uint32 SQL_SQL92_ROW_VALUE_CONSTRUCTOR = 163;
	public const uint32 SQL_SQL92_STRING_FUNCTIONS = 164;
	public const uint32 SQL_SQL92_VALUE_EXPRESSIONS = 165;
	public const uint32 SQL_STANDARD_CLI_CONFORMANCE = 166;
	public const uint32 SQL_STATIC_CURSOR_ATTRIBUTES1 = 167;
	public const uint32 SQL_STATIC_CURSOR_ATTRIBUTES2 = 168;
	public const uint32 SQL_AGGREGATE_FUNCTIONS = 169;
	public const uint32 SQL_DDL_INDEX = 170;
	public const uint32 SQL_DM_VER = 171;
	public const uint32 SQL_INSERT_STATEMENT = 172;
	public const uint32 SQL_CONVERT_GUID = 173;
	public const uint32 SQL_UNION_STATEMENT = 96;
	public const uint32 SQL_ASYNC_DBC_FUNCTIONS = 10023;
	public const uint32 SQL_DRIVER_AWARE_POOLING_SUPPORTED = 10024;
	public const uint32 SQL_ASYNC_NOTIFICATION = 10025;
	public const int32 SQL_ASYNC_NOTIFICATION_NOT_CAPABLE = 0;
	public const int32 SQL_ASYNC_NOTIFICATION_CAPABLE = 1;
	public const uint32 SQL_DTC_TRANSITION_COST = 1750;
	public const int32 SQL_AT_ADD_COLUMN_SINGLE = 32;
	public const int32 SQL_AT_ADD_COLUMN_DEFAULT = 64;
	public const int32 SQL_AT_ADD_COLUMN_COLLATION = 128;
	public const int32 SQL_AT_SET_COLUMN_DEFAULT = 256;
	public const int32 SQL_AT_DROP_COLUMN_DEFAULT = 512;
	public const int32 SQL_AT_DROP_COLUMN_CASCADE = 1024;
	public const int32 SQL_AT_DROP_COLUMN_RESTRICT = 2048;
	public const int32 SQL_AT_ADD_TABLE_CONSTRAINT = 4096;
	public const int32 SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE = 8192;
	public const int32 SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT = 16384;
	public const int32 SQL_AT_CONSTRAINT_NAME_DEFINITION = 32768;
	public const int32 SQL_AT_CONSTRAINT_INITIALLY_DEFERRED = 65536;
	public const int32 SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE = 131072;
	public const int32 SQL_AT_CONSTRAINT_DEFERRABLE = 262144;
	public const int32 SQL_AT_CONSTRAINT_NON_DEFERRABLE = 524288;
	public const int32 SQL_CVT_CHAR = 1;
	public const int32 SQL_CVT_NUMERIC = 2;
	public const int32 SQL_CVT_DECIMAL = 4;
	public const int32 SQL_CVT_INTEGER = 8;
	public const int32 SQL_CVT_SMALLINT = 16;
	public const int32 SQL_CVT_FLOAT = 32;
	public const int32 SQL_CVT_REAL = 64;
	public const int32 SQL_CVT_DOUBLE = 128;
	public const int32 SQL_CVT_VARCHAR = 256;
	public const int32 SQL_CVT_LONGVARCHAR = 512;
	public const int32 SQL_CVT_BINARY = 1024;
	public const int32 SQL_CVT_VARBINARY = 2048;
	public const int32 SQL_CVT_BIT = 4096;
	public const int32 SQL_CVT_TINYINT = 8192;
	public const int32 SQL_CVT_BIGINT = 16384;
	public const int32 SQL_CVT_DATE = 32768;
	public const int32 SQL_CVT_TIME = 65536;
	public const int32 SQL_CVT_TIMESTAMP = 131072;
	public const int32 SQL_CVT_LONGVARBINARY = 262144;
	public const int32 SQL_CVT_INTERVAL_YEAR_MONTH = 524288;
	public const int32 SQL_CVT_INTERVAL_DAY_TIME = 1048576;
	public const int32 SQL_CVT_WCHAR = 2097152;
	public const int32 SQL_CVT_WLONGVARCHAR = 4194304;
	public const int32 SQL_CVT_WVARCHAR = 8388608;
	public const int32 SQL_CVT_GUID = 16777216;
	public const int32 SQL_FN_CVT_CONVERT = 1;
	public const int32 SQL_FN_CVT_CAST = 2;
	public const int32 SQL_FN_STR_CONCAT = 1;
	public const int32 SQL_FN_STR_INSERT = 2;
	public const int32 SQL_FN_STR_LEFT = 4;
	public const int32 SQL_FN_STR_LTRIM = 8;
	public const int32 SQL_FN_STR_LENGTH = 16;
	public const int32 SQL_FN_STR_LOCATE = 32;
	public const int32 SQL_FN_STR_LCASE = 64;
	public const int32 SQL_FN_STR_REPEAT = 128;
	public const int32 SQL_FN_STR_REPLACE = 256;
	public const int32 SQL_FN_STR_RIGHT = 512;
	public const int32 SQL_FN_STR_RTRIM = 1024;
	public const int32 SQL_FN_STR_SUBSTRING = 2048;
	public const int32 SQL_FN_STR_UCASE = 4096;
	public const int32 SQL_FN_STR_ASCII = 8192;
	public const int32 SQL_FN_STR_CHAR = 16384;
	public const int32 SQL_FN_STR_DIFFERENCE = 32768;
	public const int32 SQL_FN_STR_LOCATE_2 = 65536;
	public const int32 SQL_FN_STR_SOUNDEX = 131072;
	public const int32 SQL_FN_STR_SPACE = 262144;
	public const int32 SQL_FN_STR_BIT_LENGTH = 524288;
	public const int32 SQL_FN_STR_CHAR_LENGTH = 1048576;
	public const int32 SQL_FN_STR_CHARACTER_LENGTH = 2097152;
	public const int32 SQL_FN_STR_OCTET_LENGTH = 4194304;
	public const int32 SQL_FN_STR_POSITION = 8388608;
	public const int32 SQL_SSF_CONVERT = 1;
	public const int32 SQL_SSF_LOWER = 2;
	public const int32 SQL_SSF_UPPER = 4;
	public const int32 SQL_SSF_SUBSTRING = 8;
	public const int32 SQL_SSF_TRANSLATE = 16;
	public const int32 SQL_SSF_TRIM_BOTH = 32;
	public const int32 SQL_SSF_TRIM_LEADING = 64;
	public const int32 SQL_SSF_TRIM_TRAILING = 128;
	public const int32 SQL_FN_NUM_ABS = 1;
	public const int32 SQL_FN_NUM_ACOS = 2;
	public const int32 SQL_FN_NUM_ASIN = 4;
	public const int32 SQL_FN_NUM_ATAN = 8;
	public const int32 SQL_FN_NUM_ATAN2 = 16;
	public const int32 SQL_FN_NUM_CEILING = 32;
	public const int32 SQL_FN_NUM_COS = 64;
	public const int32 SQL_FN_NUM_COT = 128;
	public const int32 SQL_FN_NUM_EXP = 256;
	public const int32 SQL_FN_NUM_FLOOR = 512;
	public const int32 SQL_FN_NUM_LOG = 1024;
	public const int32 SQL_FN_NUM_MOD = 2048;
	public const int32 SQL_FN_NUM_SIGN = 4096;
	public const int32 SQL_FN_NUM_SIN = 8192;
	public const int32 SQL_FN_NUM_SQRT = 16384;
	public const int32 SQL_FN_NUM_TAN = 32768;
	public const int32 SQL_FN_NUM_PI = 65536;
	public const int32 SQL_FN_NUM_RAND = 131072;
	public const int32 SQL_FN_NUM_DEGREES = 262144;
	public const int32 SQL_FN_NUM_LOG10 = 524288;
	public const int32 SQL_FN_NUM_POWER = 1048576;
	public const int32 SQL_FN_NUM_RADIANS = 2097152;
	public const int32 SQL_FN_NUM_ROUND = 4194304;
	public const int32 SQL_FN_NUM_TRUNCATE = 8388608;
	public const int32 SQL_SNVF_BIT_LENGTH = 1;
	public const int32 SQL_SNVF_CHAR_LENGTH = 2;
	public const int32 SQL_SNVF_CHARACTER_LENGTH = 4;
	public const int32 SQL_SNVF_EXTRACT = 8;
	public const int32 SQL_SNVF_OCTET_LENGTH = 16;
	public const int32 SQL_SNVF_POSITION = 32;
	public const int32 SQL_FN_TD_NOW = 1;
	public const int32 SQL_FN_TD_CURDATE = 2;
	public const int32 SQL_FN_TD_DAYOFMONTH = 4;
	public const int32 SQL_FN_TD_DAYOFWEEK = 8;
	public const int32 SQL_FN_TD_DAYOFYEAR = 16;
	public const int32 SQL_FN_TD_MONTH = 32;
	public const int32 SQL_FN_TD_QUARTER = 64;
	public const int32 SQL_FN_TD_WEEK = 128;
	public const int32 SQL_FN_TD_YEAR = 256;
	public const int32 SQL_FN_TD_CURTIME = 512;
	public const int32 SQL_FN_TD_HOUR = 1024;
	public const int32 SQL_FN_TD_MINUTE = 2048;
	public const int32 SQL_FN_TD_SECOND = 4096;
	public const int32 SQL_FN_TD_TIMESTAMPADD = 8192;
	public const int32 SQL_FN_TD_TIMESTAMPDIFF = 16384;
	public const int32 SQL_FN_TD_DAYNAME = 32768;
	public const int32 SQL_FN_TD_MONTHNAME = 65536;
	public const int32 SQL_FN_TD_CURRENT_DATE = 131072;
	public const int32 SQL_FN_TD_CURRENT_TIME = 262144;
	public const int32 SQL_FN_TD_CURRENT_TIMESTAMP = 524288;
	public const int32 SQL_FN_TD_EXTRACT = 1048576;
	public const int32 SQL_SDF_CURRENT_DATE = 1;
	public const int32 SQL_SDF_CURRENT_TIME = 2;
	public const int32 SQL_SDF_CURRENT_TIMESTAMP = 4;
	public const int32 SQL_FN_SYS_USERNAME = 1;
	public const int32 SQL_FN_SYS_DBNAME = 2;
	public const int32 SQL_FN_SYS_IFNULL = 4;
	public const int32 SQL_FN_TSI_FRAC_SECOND = 1;
	public const int32 SQL_FN_TSI_SECOND = 2;
	public const int32 SQL_FN_TSI_MINUTE = 4;
	public const int32 SQL_FN_TSI_HOUR = 8;
	public const int32 SQL_FN_TSI_DAY = 16;
	public const int32 SQL_FN_TSI_WEEK = 32;
	public const int32 SQL_FN_TSI_MONTH = 64;
	public const int32 SQL_FN_TSI_QUARTER = 128;
	public const int32 SQL_FN_TSI_YEAR = 256;
	public const int32 SQL_CA1_NEXT = 1;
	public const int32 SQL_CA1_ABSOLUTE = 2;
	public const int32 SQL_CA1_RELATIVE = 4;
	public const int32 SQL_CA1_BOOKMARK = 8;
	public const int32 SQL_CA1_LOCK_NO_CHANGE = 64;
	public const int32 SQL_CA1_LOCK_EXCLUSIVE = 128;
	public const int32 SQL_CA1_LOCK_UNLOCK = 256;
	public const int32 SQL_CA1_POS_POSITION = 512;
	public const int32 SQL_CA1_POS_UPDATE = 1024;
	public const int32 SQL_CA1_POS_DELETE = 2048;
	public const int32 SQL_CA1_POS_REFRESH = 4096;
	public const int32 SQL_CA1_POSITIONED_UPDATE = 8192;
	public const int32 SQL_CA1_POSITIONED_DELETE = 16384;
	public const int32 SQL_CA1_SELECT_FOR_UPDATE = 32768;
	public const int32 SQL_CA1_BULK_ADD = 65536;
	public const int32 SQL_CA1_BULK_UPDATE_BY_BOOKMARK = 131072;
	public const int32 SQL_CA1_BULK_DELETE_BY_BOOKMARK = 262144;
	public const int32 SQL_CA1_BULK_FETCH_BY_BOOKMARK = 524288;
	public const int32 SQL_CA2_READ_ONLY_CONCURRENCY = 1;
	public const int32 SQL_CA2_LOCK_CONCURRENCY = 2;
	public const int32 SQL_CA2_OPT_ROWVER_CONCURRENCY = 4;
	public const int32 SQL_CA2_OPT_VALUES_CONCURRENCY = 8;
	public const int32 SQL_CA2_SENSITIVITY_ADDITIONS = 16;
	public const int32 SQL_CA2_SENSITIVITY_DELETIONS = 32;
	public const int32 SQL_CA2_SENSITIVITY_UPDATES = 64;
	public const int32 SQL_CA2_MAX_ROWS_SELECT = 128;
	public const int32 SQL_CA2_MAX_ROWS_INSERT = 256;
	public const int32 SQL_CA2_MAX_ROWS_DELETE = 512;
	public const int32 SQL_CA2_MAX_ROWS_UPDATE = 1024;
	public const int32 SQL_CA2_MAX_ROWS_CATALOG = 2048;
	public const int32 SQL_CA2_CRC_EXACT = 4096;
	public const int32 SQL_CA2_CRC_APPROXIMATE = 8192;
	public const int32 SQL_CA2_SIMULATE_NON_UNIQUE = 16384;
	public const int32 SQL_CA2_SIMULATE_TRY_UNIQUE = 32768;
	public const int32 SQL_CA2_SIMULATE_UNIQUE = 65536;
	public const uint32 SQL_OAC_NONE = 0;
	public const uint32 SQL_OAC_LEVEL1 = 1;
	public const uint32 SQL_OAC_LEVEL2 = 2;
	public const uint32 SQL_OSCC_NOT_COMPLIANT = 0;
	public const uint32 SQL_OSCC_COMPLIANT = 1;
	public const uint32 SQL_OSC_MINIMUM = 0;
	public const uint32 SQL_OSC_CORE = 1;
	public const uint32 SQL_OSC_EXTENDED = 2;
	public const uint32 SQL_CB_NULL = 0;
	public const uint32 SQL_CB_NON_NULL = 1;
	public const int32 SQL_SO_FORWARD_ONLY = 1;
	public const int32 SQL_SO_KEYSET_DRIVEN = 2;
	public const int32 SQL_SO_DYNAMIC = 4;
	public const int32 SQL_SO_MIXED = 8;
	public const int32 SQL_SO_STATIC = 16;
	public const int32 SQL_FD_FETCH_RESUME = 64;
	public const int32 SQL_FD_FETCH_BOOKMARK = 128;
	public const int32 SQL_TXN_VERSIONING = 16;
	public const uint32 SQL_CN_NONE = 0;
	public const uint32 SQL_CN_DIFFERENT = 1;
	public const uint32 SQL_CN_ANY = 2;
	public const uint32 SQL_NNC_NULL = 0;
	public const uint32 SQL_NNC_NON_NULL = 1;
	public const uint32 SQL_NC_START = 2;
	public const uint32 SQL_NC_END = 4;
	public const uint32 SQL_FILE_NOT_SUPPORTED = 0;
	public const uint32 SQL_FILE_TABLE = 1;
	public const uint32 SQL_FILE_QUALIFIER = 2;
	public const uint32 SQL_FILE_CATALOG = 2;
	public const int32 SQL_GD_BLOCK = 4;
	public const int32 SQL_GD_BOUND = 8;
	public const int32 SQL_GD_OUTPUT_PARAMS = 16;
	public const int32 SQL_PS_POSITIONED_DELETE = 1;
	public const int32 SQL_PS_POSITIONED_UPDATE = 2;
	public const int32 SQL_PS_SELECT_FOR_UPDATE = 4;
	public const uint32 SQL_GB_NOT_SUPPORTED = 0;
	public const uint32 SQL_GB_GROUP_BY_EQUALS_SELECT = 1;
	public const uint32 SQL_GB_GROUP_BY_CONTAINS_SELECT = 2;
	public const uint32 SQL_GB_NO_RELATION = 3;
	public const uint32 SQL_GB_COLLATE = 4;
	public const int32 SQL_OU_DML_STATEMENTS = 1;
	public const int32 SQL_OU_PROCEDURE_INVOCATION = 2;
	public const int32 SQL_OU_TABLE_DEFINITION = 4;
	public const int32 SQL_OU_INDEX_DEFINITION = 8;
	public const int32 SQL_OU_PRIVILEGE_DEFINITION = 16;
	public const int32 SQL_SU_DML_STATEMENTS = 1;
	public const int32 SQL_SU_PROCEDURE_INVOCATION = 2;
	public const int32 SQL_SU_TABLE_DEFINITION = 4;
	public const int32 SQL_SU_INDEX_DEFINITION = 8;
	public const int32 SQL_SU_PRIVILEGE_DEFINITION = 16;
	public const int32 SQL_QU_DML_STATEMENTS = 1;
	public const int32 SQL_QU_PROCEDURE_INVOCATION = 2;
	public const int32 SQL_QU_TABLE_DEFINITION = 4;
	public const int32 SQL_QU_INDEX_DEFINITION = 8;
	public const int32 SQL_QU_PRIVILEGE_DEFINITION = 16;
	public const int32 SQL_CU_DML_STATEMENTS = 1;
	public const int32 SQL_CU_PROCEDURE_INVOCATION = 2;
	public const int32 SQL_CU_TABLE_DEFINITION = 4;
	public const int32 SQL_CU_INDEX_DEFINITION = 8;
	public const int32 SQL_CU_PRIVILEGE_DEFINITION = 16;
	public const int32 SQL_SQ_COMPARISON = 1;
	public const int32 SQL_SQ_EXISTS = 2;
	public const int32 SQL_SQ_IN = 4;
	public const int32 SQL_SQ_QUANTIFIED = 8;
	public const int32 SQL_SQ_CORRELATED_SUBQUERIES = 16;
	public const int32 SQL_U_UNION = 1;
	public const int32 SQL_U_UNION_ALL = 2;
	public const int32 SQL_BP_CLOSE = 1;
	public const int32 SQL_BP_DELETE = 2;
	public const int32 SQL_BP_DROP = 4;
	public const int32 SQL_BP_TRANSACTION = 8;
	public const int32 SQL_BP_UPDATE = 16;
	public const int32 SQL_BP_OTHER_HSTMT = 32;
	public const int32 SQL_BP_SCROLL = 64;
	public const int32 SQL_SS_ADDITIONS = 1;
	public const int32 SQL_SS_DELETIONS = 2;
	public const int32 SQL_SS_UPDATES = 4;
	public const int32 SQL_CV_CREATE_VIEW = 1;
	public const int32 SQL_CV_CHECK_OPTION = 2;
	public const int32 SQL_CV_CASCADED = 4;
	public const int32 SQL_CV_LOCAL = 8;
	public const int32 SQL_LCK_NO_CHANGE = 1;
	public const int32 SQL_LCK_EXCLUSIVE = 2;
	public const int32 SQL_LCK_UNLOCK = 4;
	public const int32 SQL_POS_POSITION = 1;
	public const int32 SQL_POS_REFRESH = 2;
	public const int32 SQL_POS_UPDATE = 4;
	public const int32 SQL_POS_DELETE = 8;
	public const int32 SQL_POS_ADD = 16;
	public const uint32 SQL_QL_START = 1;
	public const uint32 SQL_QL_END = 2;
	public const int32 SQL_AF_AVG = 1;
	public const int32 SQL_AF_COUNT = 2;
	public const int32 SQL_AF_MAX = 4;
	public const int32 SQL_AF_MIN = 8;
	public const int32 SQL_AF_SUM = 16;
	public const int32 SQL_AF_DISTINCT = 32;
	public const int32 SQL_AF_ALL = 64;
	public const int32 SQL_SC_SQL92_ENTRY = 1;
	public const int32 SQL_SC_FIPS127_2_TRANSITIONAL = 2;
	public const int32 SQL_SC_SQL92_INTERMEDIATE = 4;
	public const int32 SQL_SC_SQL92_FULL = 8;
	public const int32 SQL_DL_SQL92_DATE = 1;
	public const int32 SQL_DL_SQL92_TIME = 2;
	public const int32 SQL_DL_SQL92_TIMESTAMP = 4;
	public const int32 SQL_DL_SQL92_INTERVAL_YEAR = 8;
	public const int32 SQL_DL_SQL92_INTERVAL_MONTH = 16;
	public const int32 SQL_DL_SQL92_INTERVAL_DAY = 32;
	public const int32 SQL_DL_SQL92_INTERVAL_HOUR = 64;
	public const int32 SQL_DL_SQL92_INTERVAL_MINUTE = 128;
	public const int32 SQL_DL_SQL92_INTERVAL_SECOND = 256;
	public const int32 SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH = 512;
	public const int32 SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR = 1024;
	public const int32 SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE = 2048;
	public const int32 SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND = 4096;
	public const int32 SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE = 8192;
	public const int32 SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND = 16384;
	public const int32 SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND = 32768;
	public const uint32 SQL_CL_START = 1;
	public const uint32 SQL_CL_END = 2;
	public const uint32 SQL_BRC_PROCEDURES = 1;
	public const uint32 SQL_BRC_EXPLICIT = 2;
	public const uint32 SQL_BRC_ROLLED_UP = 4;
	public const int32 SQL_BS_SELECT_EXPLICIT = 1;
	public const int32 SQL_BS_ROW_COUNT_EXPLICIT = 2;
	public const int32 SQL_BS_SELECT_PROC = 4;
	public const int32 SQL_BS_ROW_COUNT_PROC = 8;
	public const uint32 SQL_PARC_BATCH = 1;
	public const uint32 SQL_PARC_NO_BATCH = 2;
	public const uint32 SQL_PAS_BATCH = 1;
	public const uint32 SQL_PAS_NO_BATCH = 2;
	public const uint32 SQL_PAS_NO_SELECT = 3;
	public const int32 SQL_IK_NONE = 0;
	public const int32 SQL_IK_ASC = 1;
	public const int32 SQL_IK_DESC = 2;
	public const int32 SQL_ISV_ASSERTIONS = 1;
	public const int32 SQL_ISV_CHARACTER_SETS = 2;
	public const int32 SQL_ISV_CHECK_CONSTRAINTS = 4;
	public const int32 SQL_ISV_COLLATIONS = 8;
	public const int32 SQL_ISV_COLUMN_DOMAIN_USAGE = 16;
	public const int32 SQL_ISV_COLUMN_PRIVILEGES = 32;
	public const int32 SQL_ISV_COLUMNS = 64;
	public const int32 SQL_ISV_CONSTRAINT_COLUMN_USAGE = 128;
	public const int32 SQL_ISV_CONSTRAINT_TABLE_USAGE = 256;
	public const int32 SQL_ISV_DOMAIN_CONSTRAINTS = 512;
	public const int32 SQL_ISV_DOMAINS = 1024;
	public const int32 SQL_ISV_KEY_COLUMN_USAGE = 2048;
	public const int32 SQL_ISV_REFERENTIAL_CONSTRAINTS = 4096;
	public const int32 SQL_ISV_SCHEMATA = 8192;
	public const int32 SQL_ISV_SQL_LANGUAGES = 16384;
	public const int32 SQL_ISV_TABLE_CONSTRAINTS = 32768;
	public const int32 SQL_ISV_TABLE_PRIVILEGES = 65536;
	public const int32 SQL_ISV_TABLES = 131072;
	public const int32 SQL_ISV_TRANSLATIONS = 262144;
	public const int32 SQL_ISV_USAGE_PRIVILEGES = 524288;
	public const int32 SQL_ISV_VIEW_COLUMN_USAGE = 1048576;
	public const int32 SQL_ISV_VIEW_TABLE_USAGE = 2097152;
	public const int32 SQL_ISV_VIEWS = 4194304;
	public const int32 SQL_AD_CONSTRAINT_NAME_DEFINITION = 1;
	public const int32 SQL_AD_ADD_DOMAIN_CONSTRAINT = 2;
	public const int32 SQL_AD_DROP_DOMAIN_CONSTRAINT = 4;
	public const int32 SQL_AD_ADD_DOMAIN_DEFAULT = 8;
	public const int32 SQL_AD_DROP_DOMAIN_DEFAULT = 16;
	public const int32 SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED = 32;
	public const int32 SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE = 64;
	public const int32 SQL_AD_ADD_CONSTRAINT_DEFERRABLE = 128;
	public const int32 SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE = 256;
	public const int32 SQL_CS_CREATE_SCHEMA = 1;
	public const int32 SQL_CS_AUTHORIZATION = 2;
	public const int32 SQL_CS_DEFAULT_CHARACTER_SET = 4;
	public const int32 SQL_CTR_CREATE_TRANSLATION = 1;
	public const int32 SQL_CA_CREATE_ASSERTION = 1;
	public const int32 SQL_CA_CONSTRAINT_INITIALLY_DEFERRED = 16;
	public const int32 SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE = 32;
	public const int32 SQL_CA_CONSTRAINT_DEFERRABLE = 64;
	public const int32 SQL_CA_CONSTRAINT_NON_DEFERRABLE = 128;
	public const int32 SQL_CCS_CREATE_CHARACTER_SET = 1;
	public const int32 SQL_CCS_COLLATE_CLAUSE = 2;
	public const int32 SQL_CCS_LIMITED_COLLATION = 4;
	public const int32 SQL_CCOL_CREATE_COLLATION = 1;
	public const int32 SQL_CDO_CREATE_DOMAIN = 1;
	public const int32 SQL_CDO_DEFAULT = 2;
	public const int32 SQL_CDO_CONSTRAINT = 4;
	public const int32 SQL_CDO_COLLATION = 8;
	public const int32 SQL_CDO_CONSTRAINT_NAME_DEFINITION = 16;
	public const int32 SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED = 32;
	public const int32 SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE = 64;
	public const int32 SQL_CDO_CONSTRAINT_DEFERRABLE = 128;
	public const int32 SQL_CDO_CONSTRAINT_NON_DEFERRABLE = 256;
	public const int32 SQL_CT_CREATE_TABLE = 1;
	public const int32 SQL_CT_COMMIT_PRESERVE = 2;
	public const int32 SQL_CT_COMMIT_DELETE = 4;
	public const int32 SQL_CT_GLOBAL_TEMPORARY = 8;
	public const int32 SQL_CT_LOCAL_TEMPORARY = 16;
	public const int32 SQL_CT_CONSTRAINT_INITIALLY_DEFERRED = 32;
	public const int32 SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE = 64;
	public const int32 SQL_CT_CONSTRAINT_DEFERRABLE = 128;
	public const int32 SQL_CT_CONSTRAINT_NON_DEFERRABLE = 256;
	public const int32 SQL_CT_COLUMN_CONSTRAINT = 512;
	public const int32 SQL_CT_COLUMN_DEFAULT = 1024;
	public const int32 SQL_CT_COLUMN_COLLATION = 2048;
	public const int32 SQL_CT_TABLE_CONSTRAINT = 4096;
	public const int32 SQL_CT_CONSTRAINT_NAME_DEFINITION = 8192;
	public const int32 SQL_DI_CREATE_INDEX = 1;
	public const int32 SQL_DI_DROP_INDEX = 2;
	public const int32 SQL_DC_DROP_COLLATION = 1;
	public const int32 SQL_DD_DROP_DOMAIN = 1;
	public const int32 SQL_DD_RESTRICT = 2;
	public const int32 SQL_DD_CASCADE = 4;
	public const int32 SQL_DS_DROP_SCHEMA = 1;
	public const int32 SQL_DS_RESTRICT = 2;
	public const int32 SQL_DS_CASCADE = 4;
	public const int32 SQL_DCS_DROP_CHARACTER_SET = 1;
	public const int32 SQL_DA_DROP_ASSERTION = 1;
	public const int32 SQL_DT_DROP_TABLE = 1;
	public const int32 SQL_DT_RESTRICT = 2;
	public const int32 SQL_DT_CASCADE = 4;
	public const int32 SQL_DTR_DROP_TRANSLATION = 1;
	public const int32 SQL_DV_DROP_VIEW = 1;
	public const int32 SQL_DV_RESTRICT = 2;
	public const int32 SQL_DV_CASCADE = 4;
	public const int32 SQL_IS_INSERT_LITERALS = 1;
	public const int32 SQL_IS_INSERT_SEARCHED = 2;
	public const int32 SQL_IS_SELECT_INTO = 4;
	public const uint32 SQL_OIC_CORE = 1;
	public const uint32 SQL_OIC_LEVEL1 = 2;
	public const uint32 SQL_OIC_LEVEL2 = 3;
	public const int32 SQL_SFKD_CASCADE = 1;
	public const int32 SQL_SFKD_NO_ACTION = 2;
	public const int32 SQL_SFKD_SET_DEFAULT = 4;
	public const int32 SQL_SFKD_SET_NULL = 8;
	public const int32 SQL_SFKU_CASCADE = 1;
	public const int32 SQL_SFKU_NO_ACTION = 2;
	public const int32 SQL_SFKU_SET_DEFAULT = 4;
	public const int32 SQL_SFKU_SET_NULL = 8;
	public const int32 SQL_SG_USAGE_ON_DOMAIN = 1;
	public const int32 SQL_SG_USAGE_ON_CHARACTER_SET = 2;
	public const int32 SQL_SG_USAGE_ON_COLLATION = 4;
	public const int32 SQL_SG_USAGE_ON_TRANSLATION = 8;
	public const int32 SQL_SG_WITH_GRANT_OPTION = 16;
	public const int32 SQL_SG_DELETE_TABLE = 32;
	public const int32 SQL_SG_INSERT_TABLE = 64;
	public const int32 SQL_SG_INSERT_COLUMN = 128;
	public const int32 SQL_SG_REFERENCES_TABLE = 256;
	public const int32 SQL_SG_REFERENCES_COLUMN = 512;
	public const int32 SQL_SG_SELECT_TABLE = 1024;
	public const int32 SQL_SG_UPDATE_TABLE = 2048;
	public const int32 SQL_SG_UPDATE_COLUMN = 4096;
	public const int32 SQL_SP_EXISTS = 1;
	public const int32 SQL_SP_ISNOTNULL = 2;
	public const int32 SQL_SP_ISNULL = 4;
	public const int32 SQL_SP_MATCH_FULL = 8;
	public const int32 SQL_SP_MATCH_PARTIAL = 16;
	public const int32 SQL_SP_MATCH_UNIQUE_FULL = 32;
	public const int32 SQL_SP_MATCH_UNIQUE_PARTIAL = 64;
	public const int32 SQL_SP_OVERLAPS = 128;
	public const int32 SQL_SP_UNIQUE = 256;
	public const int32 SQL_SP_LIKE = 512;
	public const int32 SQL_SP_IN = 1024;
	public const int32 SQL_SP_BETWEEN = 2048;
	public const int32 SQL_SP_COMPARISON = 4096;
	public const int32 SQL_SP_QUANTIFIED_COMPARISON = 8192;
	public const int32 SQL_SRJO_CORRESPONDING_CLAUSE = 1;
	public const int32 SQL_SRJO_CROSS_JOIN = 2;
	public const int32 SQL_SRJO_EXCEPT_JOIN = 4;
	public const int32 SQL_SRJO_FULL_OUTER_JOIN = 8;
	public const int32 SQL_SRJO_INNER_JOIN = 16;
	public const int32 SQL_SRJO_INTERSECT_JOIN = 32;
	public const int32 SQL_SRJO_LEFT_OUTER_JOIN = 64;
	public const int32 SQL_SRJO_NATURAL_JOIN = 128;
	public const int32 SQL_SRJO_RIGHT_OUTER_JOIN = 256;
	public const int32 SQL_SRJO_UNION_JOIN = 512;
	public const int32 SQL_SR_USAGE_ON_DOMAIN = 1;
	public const int32 SQL_SR_USAGE_ON_CHARACTER_SET = 2;
	public const int32 SQL_SR_USAGE_ON_COLLATION = 4;
	public const int32 SQL_SR_USAGE_ON_TRANSLATION = 8;
	public const int32 SQL_SR_GRANT_OPTION_FOR = 16;
	public const int32 SQL_SR_CASCADE = 32;
	public const int32 SQL_SR_RESTRICT = 64;
	public const int32 SQL_SR_DELETE_TABLE = 128;
	public const int32 SQL_SR_INSERT_TABLE = 256;
	public const int32 SQL_SR_INSERT_COLUMN = 512;
	public const int32 SQL_SR_REFERENCES_TABLE = 1024;
	public const int32 SQL_SR_REFERENCES_COLUMN = 2048;
	public const int32 SQL_SR_SELECT_TABLE = 4096;
	public const int32 SQL_SR_UPDATE_TABLE = 8192;
	public const int32 SQL_SR_UPDATE_COLUMN = 16384;
	public const int32 SQL_SRVC_VALUE_EXPRESSION = 1;
	public const int32 SQL_SRVC_NULL = 2;
	public const int32 SQL_SRVC_DEFAULT = 4;
	public const int32 SQL_SRVC_ROW_SUBQUERY = 8;
	public const int32 SQL_SVE_CASE = 1;
	public const int32 SQL_SVE_CAST = 2;
	public const int32 SQL_SVE_COALESCE = 4;
	public const int32 SQL_SVE_NULLIF = 8;
	public const int32 SQL_SCC_XOPEN_CLI_VERSION1 = 1;
	public const int32 SQL_SCC_ISO92_CLI = 2;
	public const int32 SQL_US_UNION = 1;
	public const int32 SQL_US_UNION_ALL = 2;
	public const int32 SQL_DRIVER_AWARE_POOLING_NOT_CAPABLE = 0;
	public const int32 SQL_DRIVER_AWARE_POOLING_CAPABLE = 1;
	public const int32 SQL_DTC_ENLIST_EXPENSIVE = 1;
	public const int32 SQL_DTC_UNENLIST_EXPENSIVE = 2;
	public const int32 SQL_ASYNC_DBC_NOT_CAPABLE = 0;
	public const int32 SQL_ASYNC_DBC_CAPABLE = 1;
	public const uint32 SQL_FETCH_FIRST_USER = 31;
	public const uint32 SQL_FETCH_FIRST_SYSTEM = 32;
	public const uint32 SQL_ENTIRE_ROWSET = 0;
	public const uint32 SQL_POSITION = 0;
	public const uint32 SQL_REFRESH = 1;
	public const uint32 SQL_UPDATE = 2;
	public const uint32 SQL_DELETE = 3;
	public const uint32 SQL_ADD = 4;
	public const uint32 SQL_SETPOS_MAX_OPTION_VALUE = 4;
	public const uint32 SQL_UPDATE_BY_BOOKMARK = 5;
	public const uint32 SQL_DELETE_BY_BOOKMARK = 6;
	public const uint32 SQL_FETCH_BY_BOOKMARK = 7;
	public const uint32 SQL_LOCK_NO_CHANGE = 0;
	public const uint32 SQL_LOCK_EXCLUSIVE = 1;
	public const uint32 SQL_LOCK_UNLOCK = 2;
	public const uint32 SQL_SETPOS_MAX_LOCK_VALUE = 2;
	public const uint32 SQL_BEST_ROWID = 1;
	public const uint32 SQL_ROWVER = 2;
	public const uint32 SQL_PC_NOT_PSEUDO = 1;
	public const uint32 SQL_QUICK = 0;
	public const uint32 SQL_ENSURE = 1;
	public const uint32 SQL_TABLE_STAT = 0;
	public const String SQL_ALL_CATALOGS = "%";
	public const String SQL_ALL_SCHEMAS = "%";
	public const String SQL_ALL_TABLE_TYPES = "%";
	public const uint32 SQL_DRIVER_NOPROMPT = 0;
	public const uint32 SQL_DRIVER_COMPLETE = 1;
	public const uint32 SQL_DRIVER_PROMPT = 2;
	public const uint32 SQL_DRIVER_COMPLETE_REQUIRED = 3;
	public const uint32 SQL_FETCH_BOOKMARK = 8;
	public const uint32 SQL_ROW_SUCCESS = 0;
	public const uint32 SQL_ROW_DELETED = 1;
	public const uint32 SQL_ROW_UPDATED = 2;
	public const uint32 SQL_ROW_NOROW = 3;
	public const uint32 SQL_ROW_ADDED = 4;
	public const uint32 SQL_ROW_ERROR = 5;
	public const uint32 SQL_ROW_SUCCESS_WITH_INFO = 6;
	public const uint32 SQL_ROW_PROCEED = 0;
	public const uint32 SQL_ROW_IGNORE = 1;
	public const uint32 SQL_PARAM_SUCCESS = 0;
	public const uint32 SQL_PARAM_SUCCESS_WITH_INFO = 6;
	public const uint32 SQL_PARAM_ERROR = 5;
	public const uint32 SQL_PARAM_UNUSED = 7;
	public const uint32 SQL_PARAM_DIAG_UNAVAILABLE = 1;
	public const uint32 SQL_PARAM_PROCEED = 0;
	public const uint32 SQL_PARAM_IGNORE = 1;
	public const uint32 SQL_CASCADE = 0;
	public const uint32 SQL_RESTRICT = 1;
	public const uint32 SQL_SET_NULL = 2;
	public const uint32 SQL_NO_ACTION = 3;
	public const uint32 SQL_SET_DEFAULT = 4;
	public const uint32 SQL_INITIALLY_DEFERRED = 5;
	public const uint32 SQL_INITIALLY_IMMEDIATE = 6;
	public const uint32 SQL_NOT_DEFERRABLE = 7;
	public const uint32 SQL_PARAM_TYPE_UNKNOWN = 0;
	public const uint32 SQL_PARAM_INPUT = 1;
	public const uint32 SQL_PARAM_INPUT_OUTPUT = 2;
	public const uint32 SQL_RESULT_COL = 3;
	public const uint32 SQL_PARAM_OUTPUT = 4;
	public const uint32 SQL_RETURN_VALUE = 5;
	public const uint32 SQL_PARAM_INPUT_OUTPUT_STREAM = 8;
	public const uint32 SQL_PARAM_OUTPUT_STREAM = 16;
	public const uint32 SQL_PT_UNKNOWN = 0;
	public const uint32 SQL_PT_PROCEDURE = 1;
	public const uint32 SQL_PT_FUNCTION = 2;
	public const String SQL_ODBC_KEYWORDS = "ABSOLUTE,ACTION,ADA,ADD,ALL,ALLOCATE,ALTER,AND,ANY,ARE,AS,ASC,ASSERTION,AT,AUTHORIZATION,AVG,BEGIN,BETWEEN,BIT,BIT_LENGTH,BOTH,BY,CASCADE,CASCADED,CASE,CAST,CATALOG,CHAR,CHAR_LENGTH,CHARACTER,CHARACTER_LENGTH,CHECK,CLOSE,COALESCE,COLLATE,COLLATION,COLUMN,COMMIT,CONNECT,CONNECTION,CONSTRAINT,CONSTRAINTS,CONTINUE,CONVERT,CORRESPONDING,COUNT,CREATE,CROSS,CURRENT,CURRENT_DATE,CURRENT_TIME,CURRENT_TIMESTAMP,CURRENT_USER,CURSOR,DATE,DAY,DEALLOCATE,DEC,DECIMAL,DECLARE,DEFAULT,DEFERRABLE,DEFERRED,DELETE,DESC,DESCRIBE,DESCRIPTOR,DIAGNOSTICS,DISCONNECT,DISTINCT,DOMAIN,DOUBLE,DROP,ELSE,END,END-EXEC,ESCAPE,EXCEPT,EXCEPTION,EXEC,EXECUTE,EXISTS,EXTERNAL,EXTRACT,FALSE,FETCH,FIRST,FLOAT,FOR,FOREIGN,FORTRAN,FOUND,FROM,FULL,GET,GLOBAL,GO,GOTO,GRANT,GROUP,HAVING,HOUR,IDENTITY,IMMEDIATE,IN,INCLUDE,INDEX,INDICATOR,INITIALLY,INNER,INPUT,INSENSITIVE,INSERT,INT,INTEGER,INTERSECT,INTERVAL,INTO,IS,ISOLATION,JOIN,KEY,LANGUAGE,LAST,LEADING,LEFT,LEVEL,LIKE,LOCAL,LOWER,MATCH,MAX,MIN,MINUTE,MODULE,MONTH,NAMES,NATIONAL,NATURAL,NCHAR,NEXT,NO,NONE,NOT,NULL,NULLIF,NUMERIC,OCTET_LENGTH,OF,ON,ONLY,OPEN,OPTION,OR,ORDER,OUTER,OUTPUT,OVERLAPS,PAD,PARTIAL,PASCAL,PLI,POSITION,PRECISION,PREPARE,PRESERVE,PRIMARY,PRIOR,PRIVILEGES,PROCEDURE,PUBLIC,READ,REAL,REFERENCES,RELATIVE,RESTRICT,REVOKE,RIGHT,ROLLBACK,ROWSSCHEMA,SCROLL,SECOND,SECTION,SELECT,SESSION,SESSION_USER,SET,SIZE,SMALLINT,SOME,SPACE,SQL,SQLCA,SQLCODE,SQLERROR,SQLSTATE,SQLWARNING,SUBSTRING,SUM,SYSTEM_USER,TABLE,TEMPORARY,THEN,TIME,TIMESTAMP,TIMEZONE_HOUR,TIMEZONE_MINUTE,TO,TRAILING,TRANSACTION,TRANSLATE,TRANSLATION,TRIM,TRUE,UNION,UNIQUE,UNKNOWN,UPDATE,UPPER,USAGE,USER,USING,VALUE,VALUES,VARCHAR,VARYING,VIEW,WHEN,WHENEVER,WHERE,WITH,WORK,WRITE,YEAR,ZONE";
	public const uint32 SQL_YEAR = 1;
	public const uint32 SQL_MONTH = 2;
	public const uint32 SQL_DAY = 3;
	public const uint32 SQL_HOUR = 4;
	public const uint32 SQL_MINUTE = 5;
	public const uint32 SQL_SECOND = 6;
	public const uint32 SQL_YEAR_TO_MONTH = 7;
	public const uint32 SQL_DAY_TO_HOUR = 8;
	public const uint32 SQL_DAY_TO_MINUTE = 9;
	public const uint32 SQL_DAY_TO_SECOND = 10;
	public const uint32 SQL_HOUR_TO_MINUTE = 11;
	public const uint32 SQL_HOUR_TO_SECOND = 12;
	public const uint32 SQL_MINUTE_TO_SECOND = 13;
	public const uint32 SQL_DATABASE_NAME = 16;
	public const int32 SQL_FD_FETCH_PREV = 8;
	public const uint32 SQL_FETCH_PREV = 4;
	public const uint32 SQL_CONCUR_TIMESTAMP = 3;
	public const int32 SQL_SCCO_OPT_TIMESTAMP = 4;
	public const uint32 SQL_CC_DELETE = 0;
	public const uint32 SQL_CR_DELETE = 0;
	public const uint32 SQL_CC_CLOSE = 1;
	public const uint32 SQL_CR_CLOSE = 1;
	public const uint32 SQL_CC_PRESERVE = 2;
	public const uint32 SQL_CR_PRESERVE = 2;
	public const uint32 SQL_FETCH_RESUME = 7;
	public const int32 SQL_SCROLL_FORWARD_ONLY = 0;
	public const int32 SQL_SCROLL_KEYSET_DRIVEN = -1;
	public const int32 SQL_SCROLL_DYNAMIC = -2;
	public const int32 SQL_SCROLL_STATIC = -3;
	public const uint32 TRACE_VERSION = 1000;
	public const int32 TRACE_ON = 1;
	public const int32 TRACE_VS_EVENT_ON = 2;
	public const int32 ODBC_VS_FLAG_UNICODE_ARG = 1;
	public const int32 ODBC_VS_FLAG_UNICODE_COR = 2;
	public const int32 ODBC_VS_FLAG_RETCODE = 4;
	public const int32 ODBC_VS_FLAG_STOP = 8;
	public const uint32 CRESTRICTIONS_DBSCHEMA_LINKEDSERVERS = 1;
	public const uint32 SSPROP_ENABLEFASTLOAD = 2;
	public const uint32 SSPROP_UNICODELCID = 2;
	public const uint32 SSPROP_UNICODECOMPARISONSTYLE = 3;
	public const uint32 SSPROP_COLUMNLEVELCOLLATION = 4;
	public const uint32 SSPROP_CHARACTERSET = 5;
	public const uint32 SSPROP_SORTORDER = 6;
	public const uint32 SSPROP_CURRENTCOLLATION = 7;
	public const uint32 SSPROP_INIT_CURRENTLANGUAGE = 4;
	public const uint32 SSPROP_INIT_NETWORKADDRESS = 5;
	public const uint32 SSPROP_INIT_NETWORKLIBRARY = 6;
	public const uint32 SSPROP_INIT_USEPROCFORPREP = 7;
	public const uint32 SSPROP_INIT_AUTOTRANSLATE = 8;
	public const uint32 SSPROP_INIT_PACKETSIZE = 9;
	public const uint32 SSPROP_INIT_APPNAME = 10;
	public const uint32 SSPROP_INIT_WSID = 11;
	public const uint32 SSPROP_INIT_FILENAME = 12;
	public const uint32 SSPROP_INIT_ENCRYPT = 13;
	public const uint32 SSPROP_AUTH_REPL_SERVER_NAME = 14;
	public const uint32 SSPROP_INIT_TAGCOLUMNCOLLATION = 15;
	public const uint32 SSPROPVAL_USEPROCFORPREP_OFF = 0;
	public const uint32 SSPROPVAL_USEPROCFORPREP_ON = 1;
	public const uint32 SSPROPVAL_USEPROCFORPREP_ON_DROP = 2;
	public const uint32 SSPROP_QUOTEDCATALOGNAMES = 2;
	public const uint32 SSPROP_ALLOWNATIVEVARIANT = 3;
	public const uint32 SSPROP_SQLXMLXPROGID = 4;
	public const uint32 SSPROP_MAXBLOBLENGTH = 8;
	public const uint32 SSPROP_FASTLOADOPTIONS = 9;
	public const uint32 SSPROP_FASTLOADKEEPNULLS = 10;
	public const uint32 SSPROP_FASTLOADKEEPIDENTITY = 11;
	public const uint32 SSPROP_CURSORAUTOFETCH = 12;
	public const uint32 SSPROP_DEFERPREPARE = 13;
	public const uint32 SSPROP_IRowsetFastLoad = 14;
	public const uint32 SSPROP_COL_COLLATIONNAME = 14;
	public const uint32 SSPROP_STREAM_MAPPINGSCHEMA = 15;
	public const uint32 SSPROP_STREAM_XSL = 16;
	public const uint32 SSPROP_STREAM_BASEPATH = 17;
	public const uint32 SSPROP_STREAM_COMMANDTYPE = 18;
	public const uint32 SSPROP_STREAM_XMLROOT = 19;
	public const uint32 SSPROP_STREAM_FLAGS = 20;
	public const uint32 SSPROP_STREAM_CONTENTTYPE = 23;
	public const uint32 STREAM_FLAGS_DISALLOW_URL = 1;
	public const uint32 STREAM_FLAGS_DISALLOW_ABSOLUTE_PATH = 2;
	public const uint32 STREAM_FLAGS_DISALLOW_QUERY = 4;
	public const uint32 STREAM_FLAGS_DONTCACHEMAPPINGSCHEMA = 8;
	public const uint32 STREAM_FLAGS_DONTCACHETEMPLATE = 16;
	public const uint32 STREAM_FLAGS_DONTCACHEXSL = 32;
	public const uint32 STREAM_FLAGS_DISALLOW_UPDATEGRAMS = 64;
	public const uint32 STREAM_FLAGS_RESERVED = 4294901760;
	public const uint32 SSPROPVAL_COMMANDTYPE_REGULAR = 21;
	public const uint32 SSPROPVAL_COMMANDTYPE_BULKLOAD = 22;
	public const uint32 DBTYPE_SQLVARIANT = 144;
	public const uint32 SQL_HANDLE_DBC_INFO_TOKEN = 6;
	public const uint32 SQL_CONN_POOL_RATING_BEST = 100;
	public const uint32 SQL_CONN_POOL_RATING_GOOD_ENOUGH = 99;
	public const uint32 SQL_CONN_POOL_RATING_USELESS = 0;
	public const uint32 SQL_ATTR_DBC_INFO_TOKEN = 118;
	public const uint32 SQL_ATTR_ASYNC_DBC_NOTIFICATION_CALLBACK = 120;
	public const uint32 SQL_ATTR_ASYNC_DBC_NOTIFICATION_CONTEXT = 121;
	public const uint32 SQL_ATTR_ASYNC_STMT_NOTIFICATION_CALLBACK = 30;
	public const uint32 SQL_ATTR_ASYNC_STMT_NOTIFICATION_CONTEXT = 31;
	public const uint32 SQL_MAX_NUMERIC_LEN = 16;
	public const int32 SQL_WCHAR = -8;
	public const int32 SQL_WVARCHAR = -9;
	public const int32 SQL_WLONGVARCHAR = -10;
	public const int32 SQL_C_WCHAR = -8;
	public const int32 SQL_C_TCHAR = -8;
	public const uint32 SQL_SQLSTATE_SIZEW = 10;
	public const uint32 CSTORAGEPROPERTY = 23;
	public const int32 CATEGORY_SEARCH = 1;
	public const int32 CATEGORY_COLLATOR = 2;
	public const int32 CATEGORY_GATHERER = 3;
	public const int32 CATEGORY_INDEXER = 4;
	public const int32 EVENT_SSSEARCH_STARTED = 1073742827;
	public const int32 EVENT_SSSEARCH_STARTING_SETUP = 1073742828;
	public const int32 EVENT_SSSEARCH_SETUP_SUCCEEDED = 1073742829;
	public const int32 EVENT_SSSEARCH_SETUP_FAILED = -1073740818;
	public const int32 EVENT_OUTOFMEMORY = -1073740817;
	public const int32 EVENT_SSSEARCH_SETUP_CLEANUP_STARTED = -2147482640;
	public const int32 EVENT_EXCEPTION = -1073740815;
	public const int32 EVENT_SSSEARCH_SETUP_CLEANUP_SUCCEEDED = 1073742834;
	public const int32 EVENT_SSSEARCH_SETUP_CLEANUP_FAILED = -1073740813;
	public const int32 EVENT_SSSEARCH_STOPPED = 1073742837;
	public const int32 EVENT_SSSEARCH_CREATE_PATH_RULES_FAILED = -2147482634;
	public const int32 EVENT_SSSEARCH_DROPPED_EVENTS = -2147482633;
	public const int32 EVENT_SSSEARCH_DATAFILES_MOVE_FAILED = -1073740808;
	public const int32 EVENT_SSSEARCH_DATAFILES_MOVE_SUCCEEDED = 1073742841;
	public const int32 EVENT_SSSEARCH_DATAFILES_MOVE_ROLLBACK_ERRORS = -2147482630;
	public const int32 EVENT_SSSEARCH_CSM_SAVE_FAILED = -1073740805;
	public const int32 EVENT_CONFIG_SYNTAX = -2147482604;
	public const int32 EVENT_UNPRIVILEGED_SERVICE_ACCOUNT = -2147482596;
	public const int32 EVENT_SYSTEM_EXCEPTION = -2147482595;
	public const int32 EVENT_CONFIG_ERROR = -1073738821;
	public const int32 EVENT_GATHERSVC_PERFMON = -1073738818;
	public const int32 EVENT_GATHERER_PERFMON = -1073738817;
	public const int32 EVENT_HASHMAP_INSERT = -1073738816;
	public const int32 EVENT_TRANSLOG_CREATE_TRX = -1073738815;
	public const int32 EVENT_TRANSLOG_APPEND = -1073738814;
	public const int32 EVENT_TRANSLOG_UPDATE = -1073738813;
	public const int32 EVENT_HASHMAP_UPDATE = -1073738811;
	public const int32 EVENT_GATHER_EXCEPTION = -1073738810;
	public const int32 EVENT_TRANSACTION_READ = -1073738809;
	public const int32 EVENT_GATHER_END_CRAWL = 1073744842;
	public const int32 EVENT_GATHER_START_CRAWL = 1073744843;
	public const int32 EVENT_GATHER_INTERNAL = -1073738804;
	public const int32 EVENT_GATHER_CRAWL_NOT_STARTED = -2147480625;
	public const int32 EVENT_GATHER_CRAWL_SEED_ERROR = -2147480624;
	public const int32 EVENT_GATHER_CRITICAL_ERROR = -1073738799;
	public const int32 EVENT_GATHER_ADVISE_FAILED = -1073738798;
	public const int32 EVENT_GATHER_TRANSACTION_FAIL = -1073738797;
	public const int32 EVENT_GATHER_OBJ_INIT_FAILED = -1073738796;
	public const int32 EVENT_GATHER_PLUGIN_INIT_FAILED = -1073738795;
	public const int32 EVENT_GATHER_SERVICE_INIT = -1073738794;
	public const int32 EVENT_GATHER_CANT_CREATE_DOCID = -1073738793;
	public const int32 EVENT_GATHER_CANT_DELETE_DOCID = -1073738792;
	public const int32 EVENT_TRANSLOG_CREATE = -1073738791;
	public const int32 EVENT_REG_VERSION = -1073738790;
	public const int32 EVENT_GATHER_CRAWL_SEED_FAILED = -2147480612;
	public const int32 EVENT_GATHER_CRAWL_SEED_FAILED_INIT = -2147480611;
	public const int32 EVENT_GATHER_REG_MISSING = -2147480610;
	public const int32 EVENT_GATHER_CRAWL_IN_PROGRESS = -2147480609;
	public const int32 EVENT_GATHER_LOCK_FAILED = -1073738784;
	public const int32 EVENT_GATHER_RESET_START = 1073744865;
	public const int32 EVENT_GATHER_START_PAUSE = -2147480606;
	public const int32 EVENT_GATHER_THROTTLE = 1073744867;
	public const int32 EVENT_GATHER_RESUME = 1073744868;
	public const int32 EVENT_GATHER_AUTODESCLEN_ADJUSTED = -2147480603;
	public const int32 EVENT_GATHER_NO_CRAWL_SEEDS = -2147480602;
	public const int32 EVENT_GATHER_END_INCREMENTAL = 1073744871;
	public const int32 EVENT_GATHER_FROM_NOT_SET = -1073738776;
	public const int32 EVENT_GATHER_DELETING_HISTORY_ITEMS = -1073738774;
	public const int32 EVENT_GATHER_STOP_START = 1073744876;
	public const int32 EVENT_GATHER_START_CRAWL_IF_RESET = -2147480595;
	public const int32 EVENT_GATHER_DISK_FULL = -2147480594;
	public const int32 EVENT_GATHER_NO_SCHEMA = -2147480593;
	public const int32 EVENT_GATHER_AUTODESCENCODE_INVALID = -2147480592;
	public const int32 EVENT_GATHER_PLUGINMGR_INIT_FAILED = -1073738767;
	public const int32 EVENT_GATHER_APP_INIT_FAILED = -1073738766;
	public const int32 EVENT_FAILED_INITIALIZE_CRAWL = -1073738765;
	public const int32 EVENT_CRAWL_SCHEDULED = 1073744884;
	public const int32 EVENT_FAILED_CREATE_GATHERER_LOG = -2147480587;
	public const int32 EVENT_WBREAKER_NOT_LOADED = -2147480586;
	public const int32 EVENT_LEARN_PROPAGATION_COPY_FAILED = -2147480585;
	public const int32 EVENT_LEARN_CREATE_DB_FAILED = -2147480584;
	public const int32 EVENT_LEARN_COMPILE_FAILED = -2147480583;
	public const int32 EVENT_LEARN_PROPAGATION_FAILED = -2147480582;
	public const int32 EVENT_GATHER_END_ADAPTIVE = 1073744891;
	public const int32 EVENT_USING_DIFFERENT_WORD_BREAKER = -2147480580;
	public const int32 EVENT_GATHER_RESTORE_COMPLETE = 3069;
	public const int32 EVENT_GATHER_RESTORE_ERROR = -1073738754;
	public const int32 EVENT_AUTOCAT_PERFMON = -1073738753;
	public const int32 EVENT_GATHER_DIRTY_STARTUP = -2147480576;
	public const int32 EVENT_GATHER_HISTORY_CORRUPTION_DETECTED = -2147480575;
	public const int32 EVENT_GATHER_RESTOREAPP_ERROR = -1073738750;
	public const int32 EVENT_GATHER_RESTOREAPP_COMPLETE = 3075;
	public const int32 EVENT_GATHER_BACKUPAPP_ERROR = -1073738748;
	public const int32 EVENT_GATHER_BACKUPAPP_COMPLETE = 3077;
	public const int32 EVENT_GATHER_DAEMON_TERMINATED = -2147480570;
	public const int32 EVENT_NOTIFICATION_FAILURE = -1073738745;
	public const int32 EVENT_NOTIFICATION_FAILURE_SCOPE_EXCEEDED_LOGGING = -2147480568;
	public const int32 EVENT_NOTIFICATION_RESTORED = 1073744905;
	public const int32 EVENT_NOTIFICATION_RESTORED_SCOPE_EXCEEDED_LOGGING = -2147480566;
	public const int32 EVENT_GATHER_PROTOCOLHANDLER_LOAD_FAILED = -1073738741;
	public const int32 EVENT_GATHER_PROTOCOLHANDLER_INIT_FAILED = -1073738740;
	public const int32 EVENT_GATHER_INVALID_NETWORK_ACCESS_ACCOUNT = -1073738739;
	public const int32 EVENT_GATHER_SYSTEM_LCID_CHANGED = -2147480562;
	public const int32 EVENT_GATHER_FLUSH_FAILED = -1073738737;
	public const int32 EVENT_GATHER_CHECKPOINT_FAILED = -1073738736;
	public const int32 EVENT_GATHER_SAVE_FAILED = -1073738735;
	public const int32 EVENT_GATHER_RESTORE_CHECKPOINT_FAILED = -1073738734;
	public const int32 EVENT_GATHER_READ_CHECKPOINT_FAILED = -1073738733;
	public const int32 EVENT_GATHER_CHECKPOINT_CORRUPT = -1073738732;
	public const int32 EVENT_GATHER_CHECKPOINT_FILE_MISSING = -1073738731;
	public const int32 EVENT_STS_INIT_SECURITY_FAILED = -2147480554;
	public const int32 EVENT_LOCAL_GROUP_NOT_EXPANDED = 1073744919;
	public const int32 EVENT_LOCAL_GROUPS_CACHE_FLUSHED = 1073744920;
	public const int32 EVENT_GATHERER_DATASOURCE = -1073738727;
	public const int32 EVENT_AUTOCAT_CANT_CREATE_FILE_SHARE = -1073738726;
	public const int32 EVENT_NOTIFICATION_THREAD_EXIT_FAILED = -1073738725;
	public const int32 EVENT_FILTER_HOST_NOT_INITIALIZED = -1073738724;
	public const int32 EVENT_FILTER_HOST_NOT_TERMINATED = -1073738723;
	public const int32 EVENT_FILTERPOOL_ADD_FAILED = -1073738722;
	public const int32 EVENT_FILTERPOOL_DELETE_FAILED = -1073738721;
	public const int32 EVENT_ENUMERATE_SESSIONS_FAILED = -1073738720;
	public const int32 EVENT_DETAILED_FILTERPOOL_ADD_FAILED = -1073738719;
	public const int32 EVENT_AUDIENCECOMPUTATION_CANNOTSTART = -1073738223;
	public const int32 EVENT_GATHER_RECOVERY_FAILURE = -1073738222;
	public const int32 EVENT_INDEXER_STARTED = 1073748824;
	public const int32 EVENT_INDEXER_SCHEMA_COPY_ERROR = -1073734823;
	public const int32 EVENT_INDEXER_INIT_ERROR = -1073734814;
	public const int32 EVENT_INDEXER_INVALID_DIRECTORY = -1073734813;
	public const int32 EVENT_INDEXER_PROP_ERROR = -1073734812;
	public const int32 EVENT_INDEXER_PAUSED_FOR_DISKFULL = -1073734811;
	public const int32 EVENT_INDEXER_PROP_STOPPED = -2147476633;
	public const int32 EVENT_INDEXER_PROP_SUCCEEDED = 7016;
	public const int32 EVENT_INDEXER_PROP_STARTED = 1073748841;
	public const int32 EVENT_INDEXER_NO_SEARCH_SERVERS = -2147476630;
	public const int32 EVENT_INDEXER_ADD_DSS_SUCCEEDED = 7019;
	public const int32 EVENT_INDEXER_REMOVE_DSS_SUCCEEDED = 7020;
	public const int32 EVENT_INDEXER_ADD_DSS_FAILED = -2147476627;
	public const int32 EVENT_INDEXER_REMOVE_DSS_FAILED = -1073734801;
	public const int32 EVENT_INDEXER_DSS_CONTACT_FAILED = -1073734800;
	public const int32 EVENT_INDEXER_BUILD_FAILED = -1073734797;
	public const int32 EVENT_INDEXER_REG_MISSING = -1073734796;
	public const int32 EVENT_INDEXER_PROPSTORE_INIT_FAILED = -1073734787;
	public const int32 EVENT_INDEXER_CI_LOAD_ERROR = -1073734785;
	public const int32 EVENT_INDEXER_RESET_FOR_CORRUPTION = -1073734784;
	public const int32 EVENT_INDEXER_SHUTDOWN = 1073748866;
	public const int32 EVENT_INDEXER_LOAD_FAIL = -1073734781;
	public const int32 EVENT_INDEXER_PROP_STATE_CORRUPT = -1073734780;
	public const int32 EVENT_INDEXER_DSS_ALREADY_ADDED = 1073748870;
	public const int32 EVENT_INDEXER_BUILD_START = 1073748872;
	public const int32 EVENT_INDEXER_BUILD_ENDED = 1073748873;
	public const int32 EVENT_INDEXER_VERIFY_PROP_ACCOUNT = -1073734768;
	public const int32 EVENT_INDEXER_ADD_DSS_DISCONNECT = -2147476585;
	public const int32 EVENT_INDEXER_PERFMON = -1073734760;
	public const int32 EVENT_INDEXER_MISSING_APP_DIRECTORY = -1073734758;
	public const int32 EVENT_INDEXER_REG_ERROR = -1073734756;
	public const int32 EVENT_INDEXER_DSS_UNABLE_TO_REMOVE = -1073734755;
	public const int32 EVENT_INDEXER_NEW_PROJECT = -1073734754;
	public const int32 EVENT_INDEXER_REMOVED_PROJECT = -1073734753;
	public const int32 EVENT_INDEXER_PROP_COMMITTED = 1073748898;
	public const int32 EVENT_INDEXER_PROP_ABORTED = 1073748899;
	public const int32 EVENT_DSS_NOT_ENABLED = -2147476572;
	public const int32 EVENT_INDEXER_PROP_COMMIT_FAILED = -1073734747;
	public const int32 JET_INIT_ERROR = -1073732824;
	public const int32 JET_NEW_PROP_STORE_ERROR = -1073732823;
	public const int32 JET_GET_PROP_STORE_ERROR = -1073732822;
	public const int32 JET_MULTIINSTANCE_DISABLED = -2147474645;
	public const int32 EVENT_WARNING_CANNOT_UPGRADE_NOISE_FILES = -2147473635;
	public const int32 EVENT_WARNING_CANNOT_UPGRADE_NOISE_FILE = -2147473634;
	public const int32 EVENT_WIN32_ERROR = -2147473633;
	public const int32 EVENT_PERF_COUNTERS_NOT_LOADED = -2147473628;
	public const int32 EVENT_PERF_COUNTERS_REGISTRY_TROUBLE = -2147473627;
	public const int32 EVENT_PERF_COUNTERS_ALREADY_EXISTS = -2147473626;
	public const int32 EVENT_PROTOCOL_HOST_FORCE_TERMINATE = -2147473625;
	public const int32 EVENT_FILTER_HOST_FORCE_TERMINATE = -2147473624;
	public const int32 EVENT_INDEXER_OUT_OF_DATABASE_INSTANCE = -1073731799;
	public const int32 EVENT_INDEXER_FAIL_TO_SET_MAX_JETINSTANCE = -1073731798;
	public const int32 EVENT_INDEXER_FAIL_TO_CREATE_PER_USER_CATALOG = -1073731797;
	public const int32 EVENT_INDEXER_FAIL_TO_UNLOAD_PER_USER_CATALOG = -1073731796;
	public const uint32 ERROR_SOURCE_NETWORKING = 768;
	public const uint32 ERROR_SOURCE_DATASOURCE = 1024;
	public const uint32 ERROR_SOURCE_COLLATOR = 1280;
	public const uint32 ERROR_SOURCE_CONNMGR = 1536;
	public const uint32 ERROR_SOURCE_QUERY = 1792;
	public const uint32 ERROR_SOURCE_SCHEMA = 3072;
	public const uint32 ERROR_SOURCE_GATHERER = 3328;
	public const uint32 ERROR_SOURCE_INDEXER = 4352;
	public const uint32 ERROR_SOURCE_SETUP = 4864;
	public const uint32 ERROR_SOURCE_SECURITY = 5120;
	public const uint32 ERROR_SOURCE_CMDLINE = 5376;
	public const uint32 ERROR_SOURCE_NLADMIN = 6400;
	public const uint32 ERROR_SOURCE_SCRIPTPI = 8192;
	public const uint32 ERROR_SOURCE_MSS = 8448;
	public const uint32 ERROR_SOURCE_XML = 8704;
	public const uint32 ERROR_SOURCE_DAV = 8960;
	public const uint32 ERROR_SOURCE_FLTRDMN = 9216;
	public const uint32 ERROR_SOURCE_OLEDB_BINDER = 9472;
	public const uint32 ERROR_SOURCE_NOTESPH = 9728;
	public const uint32 ERROR_SOURCE_EXSTOREPH = 9984;
	public const uint32 ERROR_SOURCE_SRCH_SCHEMA_CACHE = 13056;
	public const uint32 ERROR_SOURCE_CONTENT_SOURCE = 13312;
	public const uint32 ERROR_SOURCE_REMOTE_EXSTOREPH = 13568;
	public const uint32 ERROR_SOURCE_PEOPLE_IMPORT = 16384;
	public const uint32 ERROR_FTE = 13824;
	public const uint32 ERROR_FTE_CB = 51968;
	public const uint32 ERROR_FTE_FD = 64768;
	public const int32 XML_E_NODEFAULTNS = -2147212800;
	public const int32 XML_E_BADSXQL = -2147212799;
	public const int32 MSS_E_INVALIDAPPNAME = -2147213056;
	public const int32 MSS_E_APPNOTFOUND = -2147213055;
	public const int32 MSS_E_APPALREADYEXISTS = -2147213054;
	public const int32 MSS_E_CATALOGNOTFOUND = -2147213053;
	public const int32 MSS_E_CATALOGSTOPPING = -2147213052;
	public const int32 MSS_E_UNICODEFILEHEADERMISSING = -2147213051;
	public const int32 MSS_E_CATALOGALREADYEXISTS = -2147213050;
	public const int32 NET_E_GENERAL = -2147220736;
	public const int32 NET_E_DISCONNECTED = -2147220733;
	public const int32 NET_E_INVALIDPARAMS = -2147220728;
	public const int32 NET_E_OPERATIONINPROGRESS = -2147220727;
	public const int32 SEC_E_INVALIDCONTEXT = -2147216381;
	public const int32 SEC_E_INITFAILED = -2147216383;
	public const int32 SEC_E_NOTINITIALIZED = -2147216382;
	public const int32 SEC_E_ACCESSDENIED = -2147216129;
	public const int32 DS_E_NOMOREDATA = -2147220480;
	public const int32 DS_E_INVALIDDATASOURCE = -2147220479;
	public const int32 DS_E_DATASOURCENOTAVAILABLE = -2147220478;
	public const int32 DS_E_QUERYCANCELED = -2147220477;
	public const int32 DS_E_UNKNOWNREQUEST = -2147220476;
	public const int32 DS_E_BADREQUEST = -2147220475;
	public const int32 DS_E_SERVERCAPACITY = -2147220474;
	public const int32 DS_E_BADSEQUENCE = -2147220473;
	public const int32 DS_E_MESSAGETOOLONG = -2147220472;
	public const int32 DS_E_SERVERERROR = -2147220471;
	public const int32 DS_E_CONFIGBAD = -2147220470;
	public const int32 DS_E_DATANOTPRESENT = -2147220464;
	public const int32 DS_E_SETSTATUSINPROGRESS = -2147220463;
	public const int32 DS_E_DUPLICATEID = -2147220462;
	public const int32 DS_E_TOOMANYDATASOURCES = -2147220461;
	public const int32 DS_E_REGISTRY = -2147220460;
	public const int32 DS_E_DATASOURCENOTDISABLED = -2147220459;
	public const int32 DS_E_INVALIDTAGDB = -2147220458;
	public const int32 DS_E_INVALIDCATALOGNAME = -2147220457;
	public const int32 DS_E_CONFIGNOTRIGHTTYPE = -2147220456;
	public const int32 DS_E_PROTOCOLVERSION = -2147220455;
	public const int32 DS_E_ALREADYENABLED = -2147220454;
	public const int32 DS_E_INDEXDIRECTORY = -2147220452;
	public const int32 DS_E_VALUETOOLARGE = -2147220451;
	public const int32 DS_E_UNKNOWNPARAM = -2147220450;
	public const int32 DS_E_BUFFERTOOSMALL = -2147220449;
	public const int32 DS_E_PARAMOUTOFRANGE = -2147220448;
	public const int32 DS_E_ALREADYDISABLED = -2147220447;
	public const int32 DS_E_QUERYHUNG = -2147220446;
	public const int32 DS_E_BADRESULT = -2147220445;
	public const int32 DS_E_CANNOTWRITEREGISTRY = -2147220444;
	public const int32 DS_E_CANNOTREMOVECONCURRENT = -2147220443;
	public const int32 DS_E_SEARCHCATNAMECOLLISION = -2147220442;
	public const int32 DS_E_PROPVERSIONMISMATCH = -2147220441;
	public const int32 DS_E_MISSINGCATALOG = -2147220440;
	public const int32 COLL_E_BADSEQUENCE = -2147220223;
	public const int32 COLL_E_NOMOREDATA = -2147220222;
	public const int32 COLL_E_INCOMPATIBLECOLUMNS = -2147220221;
	public const int32 COLL_E_BUFFERTOOSMALL = -2147220220;
	public const int32 COLL_E_BADRESULT = -2147220218;
	public const int32 COLL_E_NOSORTCOLUMN = -2147220217;
	public const int32 COLL_E_DUPLICATEDBID = -2147220216;
	public const int32 COLL_E_TOOMANYMERGECOLUMNS = -2147220215;
	public const int32 COLL_E_NODEFAULTCATALOG = -2147220214;
	public const int32 COLL_E_MAXCONNEXCEEDED = -2147220213;
	public const int32 CM_E_TOOMANYDATASERVERS = -2147219967;
	public const int32 CM_E_TOOMANYDATASOURCES = -2147219966;
	public const int32 CM_E_NOQUERYCONNECTIONS = -2147219965;
	public const int32 CM_E_DATASOURCENOTAVAILABLE = -2147219964;
	public const int32 CM_E_CONNECTIONTIMEOUT = -2147219963;
	public const int32 CM_E_SERVERNOTFOUND = -2147219962;
	public const int32 CM_S_NODATASERVERS = 263687;
	public const int32 CM_E_REGISTRY = -2147219960;
	public const int32 CM_E_INVALIDDATASOURCE = -2147219959;
	public const int32 CM_E_TIMEOUT = -2147219958;
	public const int32 CM_E_INSUFFICIENTBUFFER = -2147219957;
	public const int32 QRY_E_QUERYSYNTAX = -2147219711;
	public const int32 QRY_E_TYPEMISMATCH = -2147219710;
	public const int32 QRY_E_UNHANDLEDTYPE = -2147219709;
	public const int32 QRY_S_NOROWSFOUND = 263940;
	public const int32 QRY_E_TOOMANYCOLUMNS = -2147219707;
	public const int32 QRY_E_TOOMANYDATABASES = -2147219706;
	public const int32 QRY_E_STARTHITTOBIG = -2147219705;
	public const int32 QRY_E_TOOMANYQUERYTERMS = -2147219704;
	public const int32 QRY_E_NODATASOURCES = -2147219703;
	public const int32 QRY_E_TIMEOUT = -2147219702;
	public const int32 QRY_E_COLUMNNOTSORTABLE = -2147219701;
	public const int32 QRY_E_COLUMNNOTSEARCHABLE = -2147219700;
	public const int32 QRY_E_INVALIDCOLUMN = -2147219699;
	public const int32 QRY_E_QUERYCORRUPT = -2147219698;
	public const int32 QRY_E_PREFIXWILDCARD = -2147219697;
	public const int32 QRY_E_INFIXWILDCARD = -2147219696;
	public const int32 QRY_E_WILDCARDPREFIXLENGTH = -2147219695;
	public const int32 QRY_S_TERMIGNORED = 263954;
	public const int32 QRY_E_ENGINEFAILED = -2147219693;
	public const int32 QRY_E_SEARCHTOOBIG = -2147219692;
	public const int32 QRY_E_NULLQUERY = -2147219691;
	public const int32 QRY_S_INEXACTRESULTS = 263958;
	public const int32 QRY_E_NOCOLUMNS = -2147219689;
	public const int32 QRY_E_INVALIDSCOPES = -2147219688;
	public const int32 QRY_E_INVALIDCATALOG = -2147219687;
	public const int32 QRY_E_SCOPECARDINALIDY = -2147219686;
	public const int32 QRY_E_UNEXPECTED = -2147219685;
	public const int32 QRY_E_INVALIDPATH = -2147219684;
	public const int32 QRY_E_LMNOTINITIALIZED = -2147219683;
	public const int32 QRY_E_INVALIDINTERVAL = -2147219682;
	public const int32 QRY_E_NOLOGMANAGER = -2147219681;
	public const int32 SCHEMA_E_LOAD_SPECIAL = -2147218431;
	public const int32 SCHEMA_E_FILENOTFOUND = -2147218430;
	public const int32 SCHEMA_E_NESTEDTAG = -2147218429;
	public const int32 SCHEMA_E_UNEXPECTEDTAG = -2147218428;
	public const int32 SCHEMA_E_VERSIONMISMATCH = -2147218427;
	public const int32 SCHEMA_E_CANNOTCREATEFILE = -2147218426;
	public const int32 SCHEMA_E_CANNOTWRITEFILE = -2147218425;
	public const int32 SCHEMA_E_EMPTYFILE = -2147218424;
	public const int32 SCHEMA_E_INVALIDFILETYPE = -2147218423;
	public const int32 SCHEMA_E_INVALIDDATATYPE = -2147218422;
	public const int32 SCHEMA_E_CANNOTCREATENOISEWORDFILE = -2147218421;
	public const int32 SCHEMA_E_ADDSTOPWORDS = -2147218420;
	public const int32 SCHEMA_E_NAMEEXISTS = -2147218419;
	public const int32 SCHEMA_E_INVALIDVALUE = -2147218418;
	public const int32 SCHEMA_E_BADPROPSPEC = -2147218417;
	public const int32 SCHEMA_E_NOMORECOLUMNS = -2147218416;
	public const int32 SCHEMA_E_FILECHANGED = -2147218415;
	public const int32 SCHEMA_E_BADCOLUMNNAME = -2147218414;
	public const int32 SCHEMA_E_BADPROPPID = -2147218413;
	public const int32 SCHEMA_E_BADATTRIBUTE = -2147218412;
	public const int32 SCHEMA_E_BADFILENAME = -2147218411;
	public const int32 SCHEMA_E_PROPEXISTS = -2147218410;
	public const int32 SCHEMA_E_DUPLICATENOISE = -2147218409;
	public const int32 GTHR_E_DUPLICATE_OBJECT = -2147218174;
	public const int32 GTHR_E_UNABLE_TO_READ_REGISTRY = -2147218173;
	public const int32 GTHR_E_ERROR_WRITING_REGISTRY = -2147218172;
	public const int32 GTHR_E_ERROR_INITIALIZING_PERFMON = -2147218171;
	public const int32 GTHR_E_ERROR_OBJECT_NOT_FOUND = -2147218170;
	public const int32 GTHR_E_URL_EXCLUDED = -2147218169;
	public const int32 GTHR_E_CONFIG_DUP_PROJECT = -2147218166;
	public const int32 GTHR_E_CONFIG_DUP_EXTENSION = -2147218165;
	public const int32 GTHR_E_DUPLICATE_URL = -2147218163;
	public const int32 GTHR_E_TOO_MANY_PLUGINS = -2147218162;
	public const int32 GTHR_E_INVALIDFUNCTION = -2147218161;
	public const int32 GTHR_E_NOFILTERSINK = -2147218160;
	public const int32 GTHR_E_FILTER_PROCESS_TERMINATED = -2147218159;
	public const int32 GTHR_E_FILTER_INVALID_MESSAGE = -2147218158;
	public const int32 GTHR_E_UNSUPPORTED_PROPERTY_TYPE = -2147218157;
	public const int32 GTHR_E_NAME_TOO_LONG = -2147218156;
	public const int32 GTHR_E_NO_IDENTITY = -2147218155;
	public const int32 GTHR_E_FILTER_NOT_FOUND = -2147218154;
	public const int32 GTHR_E_FILTER_NO_MORE_THREADS = -2147218153;
	public const int32 GTHR_E_PRT_HNDLR_PROGID_MISSING = -2147218152;
	public const int32 GTHR_E_FILTER_PROCESS_TERMINATED_QUOTA = -2147218151;
	public const int32 GTHR_E_UNKNOWN_PROTOCOL = -2147218150;
	public const int32 GTHR_E_PROJECT_NOT_INITIALIZED = -2147218149;
	public const int32 GTHR_S_STATUS_CHANGE_IGNORED = 265500;
	public const int32 GTHR_S_STATUS_END_CRAWL = 265501;
	public const int32 GTHR_S_STATUS_RESET = 265502;
	public const int32 GTHR_S_STATUS_THROTTLE = 265503;
	public const int32 GTHR_S_STATUS_RESUME = 265504;
	public const int32 GTHR_S_STATUS_PAUSE = 265505;
	public const int32 GTHR_E_INVALID_PROJECT_NAME = -2147218142;
	public const int32 GTHR_E_SHUTTING_DOWN = -2147218141;
	public const int32 GTHR_S_END_STD_CHUNKS = 265508;
	public const int32 GTHR_E_VALUE_NOT_AVAILABLE = -2147218139;
	public const int32 GTHR_E_OUT_OF_DOC_ID = -2147218138;
	public const int32 GTHR_E_NOTIFICATION_START_PAGE = -2147218137;
	public const int32 GTHR_E_DUP_PROPERTY_MAPPING = -2147218134;
	public const int32 GTHR_S_NO_CRAWL_SEEDS = 265515;
	public const int32 GTHR_E_INVALID_ACCOUNT = -2147218132;
	public const int32 GTHR_E_FILTER_INIT = -2147218130;
	public const int32 GTHR_E_INVALID_ACCOUNT_SYNTAX = -2147218129;
	public const int32 GTHR_S_CANNOT_FILTER = 265520;
	public const int32 GTHR_E_PROXY_NAME = -2147218127;
	public const int32 GTHR_E_SERVER_UNAVAILABLE = -2147218126;
	public const int32 GTHR_S_STATUS_STOP = 265523;
	public const int32 GTHR_E_INVALID_PATH = -2147218124;
	public const int32 GTHR_E_FILTER_NO_CODEPAGE = -2147218123;
	public const int32 GTHR_S_STATUS_START = 265526;
	public const int32 GTHR_E_NO_PRTCLHNLR = -2147218121;
	public const int32 GTHR_E_IE_OFFLINE = -2147218120;
	public const int32 GTHR_E_BAD_FILTER_DAEMON = -2147218119;
	public const int32 GTHR_E_INVALID_MAPPING = -2147218112;
	public const int32 GTHR_E_USER_AGENT_NOT_SPECIFIED = -2147218111;
	public const int32 GTHR_E_FROM_NOT_SPECIFIED = -2147218109;
	public const int32 GTHR_E_INVALID_STREAM_LOGS_COUNT = -2147218108;
	public const int32 GTHR_E_INVALID_EXTENSION = -2147218107;
	public const int32 GTHR_E_INVALID_GROW_FACTOR = -2147218106;
	public const int32 GTHR_E_INVALID_TIME_OUT = -2147218105;
	public const int32 GTHR_E_INVALID_RETRIES = -2147218104;
	public const int32 GTHR_E_INVALID_LOG_FILE_NAME = -2147218103;
	public const int32 GTHR_E_INVALID_HOST_NAME = -2147218096;
	public const int32 GTHR_E_INVALID_START_PAGE = -2147218095;
	public const int32 GTHR_E_DUPLICATE_PROJECT = -2147218094;
	public const int32 GTHR_E_INVALID_DIRECTORY = -2147218093;
	public const int32 GTHR_E_FILTER_INTERRUPTED = -2147218092;
	public const int32 GTHR_E_INVALID_PROXY_PORT = -2147218091;
	public const int32 GTHR_S_CONFIG_HAS_ACCOUNTS = 265558;
	public const int32 GTHR_E_SECRET_NOT_FOUND = -2147218089;
	public const int32 GTHR_E_INVALID_PATH_EXPRESSION = -2147218088;
	public const int32 GTHR_E_INVALID_START_PAGE_HOST = -2147218087;
	public const int32 GTHR_E_INVALID_START_PAGE_PATH = -2147218080;
	public const int32 GTHR_E_APPLICATION_NOT_FOUND = -2147218079;
	public const int32 GTHR_E_CANNOT_REMOVE_PLUGINMGR = -2147218078;
	public const int32 GTHR_E_INVALID_APPLICATION_NAME = -2147218077;
	public const int32 GTHR_E_FILTER_FAULT = -2147218075;
	public const int32 GTHR_E_NON_FIXED_DRIVE = -2147218074;
	public const int32 GTHR_S_PROB_NOT_MODIFIED = 265575;
	public const int32 GTHR_S_CRAWL_SCHEDULED = 265576;
	public const int32 GTHR_S_TRANSACTION_IGNORED = 265577;
	public const int32 GTHR_S_START_FILTER_FROM_PROTOCOL = 265578;
	public const int32 GTHR_E_FILTER_SINGLE_THREADED = -2147218069;
	public const int32 GTHR_S_BAD_FILE_LINK = 265580;
	public const int32 GTHR_E_URL_UNIDENTIFIED = -2147218067;
	public const int32 GTHR_S_NOT_ALL_PARTS = 265582;
	public const int32 GTHR_E_FORCE_NOTIFICATION_RESET = -2147218065;
	public const int32 GTHR_S_END_PROCESS_LOOP_NOTIFY_QUEUE = 265584;
	public const int32 GTHR_S_START_FILTER_FROM_BODY = 265585;
	public const int32 GTHR_E_CONTENT_ID_CONFLICT = -2147218062;
	public const int32 GTHR_E_UNABLE_TO_READ_EXCHANGE_STORE = -2147218061;
	public const int32 GTHR_E_RECOVERABLE_EXOLEDB_ERROR = -2147218060;
	public const int32 GTHR_E_INVALID_CALL_FROM_WBREAKER = -2147218058;
	public const int32 GTHR_E_PROPERTY_LIST_NOT_INITIALIZED = -2147218057;
	public const int32 GTHR_S_MODIFIED_PARTS = 265592;
	public const int32 GHTR_E_LOCAL_SERVER_UNAVAILABLE = -2147218055;
	public const int32 GTHR_E_SCHEMA_ERRORS_OCCURRED = -2147218054;
	public const int32 GTHR_E_TIMEOUT = -2147218053;
	public const int32 GTHR_S_CRAWL_FULL = 265603;
	public const int32 GTHR_S_CRAWL_INCREMENTAL = 265604;
	public const int32 GTHR_S_CRAWL_ADAPTIVE = 265605;
	public const int32 GTHR_E_NOTIFICATION_START_ADDRESS_INVALID = -2147218042;
	public const int32 GTHR_E_NOTIFICATION_TYPE_NOT_SUPPORTED = -2147218041;
	public const int32 GTHR_E_NOTIFICATION_FILE_SHARE_INFO_NOT_AVAILABLE = -2147218040;
	public const int32 GTHR_E_NOTIFICATION_LOCAL_PATH_MUST_USE_FIXED_DRIVE = -2147218039;
	public const int32 GHTR_E_INSUFFICIENT_DISK_SPACE = -2147218037;
	public const int32 GTHR_E_INVALID_RESOURCE_ID = -2147218035;
	public const int32 GTHR_E_NESTED_HIERARCHICAL_START_ADDRESSES = -2147218034;
	public const int32 GTHR_S_NO_INDEX = 265616;
	public const int32 GTHR_S_PAUSE_REASON_EXTERNAL = 265618;
	public const int32 GTHR_S_PAUSE_REASON_UPGRADING = 265619;
	public const int32 GTHR_S_PAUSE_REASON_BACKOFF = 265620;
	public const int32 GTHR_E_RETRY = -2147218027;
	public const int32 GTHR_E_JET_BACKUP_ERROR = -2147218026;
	public const int32 GTHR_E_JET_RESTORE_ERROR = -2147218025;
	public const int32 GTHR_S_OFFICE_CHILD = 265626;
	public const int32 GTHR_E_PLUGIN_NOT_REGISTERED = -2147218021;
	public const int32 GTHR_E_NOTIF_ACCESS_TOKEN_UPDATED = -2147218020;
	public const int32 GTHR_E_DIRMON_NOT_INITIALZED = -2147218019;
	public const int32 GTHR_E_NOTIF_BEING_REMOVED = -2147218018;
	public const int32 GTHR_E_NOTIF_EXCESSIVE_THROUGHPUT = -2147218017;
	public const int32 GTHR_E_INVALID_PATH_SPEC = -2147218016;
	public const int32 GTHR_E_INSUFFICIENT_FEATURE_TERMS = -2147218015;
	public const int32 GTHR_E_INSUFFICIENT_EXAMPLE_CATEGORIES = -2147218014;
	public const int32 GTHR_E_INSUFFICIENT_EXAMPLE_DOCUMENTS = -2147218013;
	public const int32 GTHR_E_AUTOCAT_UNEXPECTED = -2147218012;
	public const int32 GTHR_E_SINGLE_THREADED_EMBEDDING = -2147218011;
	public const int32 GTHR_S_CANNOT_WORDBREAK = 265638;
	public const int32 GTHR_S_USE_MIME_FILTER = 265639;
	public const int32 GTHR_E_FOLDER_CRAWLED_BY_ANOTHER_WORKSPACE = -2147218007;
	public const int32 GTHR_E_EMPTY_DACL = -2147218006;
	public const int32 GTHR_E_OBJECT_NOT_VALID = -2147218005;
	public const int32 GTHR_E_CANNOT_ENABLE_CHECKPOINT = -2147218002;
	public const int32 GTHR_E_SCOPES_EXCEEDED = -2147218001;
	public const int32 GTHR_E_PROPERTIES_EXCEEDED = -2147218000;
	public const int32 GTHR_E_INVALID_START_ADDRESS = -2147217998;
	public const int32 GTHR_S_PAUSE_REASON_PROFILE_IMPORT = 265651;
	public const int32 GTHR_E_PIPE_NOT_CONNECTTED = -2147217996;
	public const int32 GTHR_E_BACKUP_VALIDATION_FAIL = -2147217994;
	public const int32 GTHR_E_BAD_FILTER_HOST = -2147217993;
	public const int32 GTHR_E_NTF_CLIENT_NOT_SUBSCRIBED = -1073476167;
	public const int32 GTHR_E_FILTERPOOL_NOTFOUND = -2147217990;
	public const int32 GTHR_E_ADDLINKS_FAILED_WILL_RETRY_PARENT = -2147217989;
	public const int32 IDX_E_INVALIDTAG = -2147217151;
	public const int32 IDX_E_METAFILE_CORRUPT = -2147217150;
	public const int32 IDX_E_TOO_MANY_SEARCH_SERVERS = -2147217149;
	public const int32 IDX_E_SEARCH_SERVER_ALREADY_EXISTS = -2147217148;
	public const int32 IDX_E_BUILD_IN_PROGRESS = -2147217147;
	public const int32 IDX_E_IDXLSTFILE_CORRUPT = -2147217146;
	public const int32 IDX_E_REGISTRY_ENTRY = -2147217145;
	public const int32 IDX_E_OBJECT_NOT_FOUND = -2147217144;
	public const int32 IDX_E_SEARCH_SERVER_NOT_FOUND = -2147217143;
	public const int32 IDX_E_WB_NOTFOUND = -2147217142;
	public const int32 IDX_E_NOISELIST_NOTFOUND = -2147217141;
	public const int32 IDX_E_STEMMER_NOTFOUND = -2147217140;
	public const int32 IDX_E_PROP_STOPPED = -2147217139;
	public const int32 IDX_E_DISKFULL = -2147217138;
	public const int32 IDX_E_INVALID_INDEX = -2147217137;
	public const int32 IDX_E_CORRUPT_INDEX = -2147217136;
	public const int32 IDX_E_PROPSTORE_INIT_FAILED = -2147217134;
	public const int32 IDX_E_PROP_STATE_CORRUPT = -2147217133;
	public const int32 IDX_S_NO_BUILD_IN_PROGRESS = 266516;
	public const int32 IDX_S_SEARCH_SERVER_ALREADY_EXISTS = 266517;
	public const int32 IDX_S_SEARCH_SERVER_DOES_NOT_EXIST = 266518;
	public const int32 IDX_E_NOT_LOADED = -2147217129;
	public const int32 IDX_E_PROP_MAJOR_VERSION_MISMATCH = -2147217128;
	public const int32 IDX_E_PROP_MINOR_VERSION_MISMATCH = -2147217127;
	public const int32 IDX_E_DSS_NOT_CONNECTED = -2147217126;
	public const int32 IDX_E_DOCUMENT_ABORTED = -2147217125;
	public const int32 IDX_E_CATALOG_DISMOUNTED = -2147217124;
	public const int32 IDX_S_DSS_NOT_AVAILABLE = 266525;
	public const int32 IDX_E_USE_DEFAULT_CONTENTCLASS = -2147217121;
	public const int32 IDX_E_USE_APPGLOBAL_PROPTABLE = -2147217120;
	public const int32 JPS_E_JET_ERR = -2147217025;
	public const int32 JPS_S_DUPLICATE_DOC_DETECTED = 266624;
	public const int32 JPS_E_CATALOG_DECSRIPTION_MISSING = -2147217023;
	public const int32 JPS_E_MISSING_INFORMATION = -2147217022;
	public const int32 JPS_E_INSUFFICIENT_VERSION_STORAGE = -2147217021;
	public const int32 JPS_E_INSUFFICIENT_DATABASE_SESSIONS = -2147217020;
	public const int32 JPS_E_INSUFFICIENT_DATABASE_RESOURCES = -2147217019;
	public const int32 JPS_E_SCHEMA_ERROR = -2147217018;
	public const int32 JPS_E_PROPAGATION_FILE = -2147217017;
	public const int32 JPS_E_PROPAGATION_CORRUPTION = -2147217016;
	public const int32 JPS_E_PROPAGATION_VERSION_MISMATCH = -2147217015;
	public const int32 JPS_E_SHARING_VIOLATION = -2147217014;
	public const int32 EXCI_E_NO_CONFIG = -2147216992;
	public const int32 EXCI_E_INVALID_SERVER_CONFIG = -2147216991;
	public const int32 EXCI_E_ACCESS_DENIED = -2147216990;
	public const int32 EXCI_E_INVALID_EXCHANGE_SERVER = -2147216989;
	public const int32 EXCI_E_BADCONFIG_OR_ACCESSDENIED = -2147216988;
	public const int32 EXCI_E_WRONG_SERVER_OR_ACCT = -2147216987;
	public const int32 EXCI_E_NOT_ADMIN_OR_WRONG_SITE = -2147216986;
	public const int32 EXCI_E_NO_MAPI = -2147216985;
	public const int32 EXCI_E_INVALID_ACCOUNT_INFO = -2147216984;
	public const int32 PRTH_E_INTERNAL_ERROR = -2147216892;
	public const int32 PRTH_S_MAX_GROWTH = 266761;
	public const int32 PRTH_E_WININET = -2147216886;
	public const int32 PRTH_E_RETRY = -2147216885;
	public const int32 PRTH_S_MAX_DOWNLOAD = 266764;
	public const int32 PRTH_E_MIME_EXCLUDED = -2147216883;
	public const int32 PRTH_E_CANT_TRANSFORM_EXTERNAL_ACL = -2147216882;
	public const int32 PRTH_E_CANT_TRANSFORM_DENIED_ACE = -2147216881;
	public const int32 PRTH_E_NO_PROPERTY = -2147216877;
	public const int32 PRTH_S_USE_ROSEBUD = 266772;
	public const int32 PRTH_E_DATABASE_OPEN_ERROR = -2147216875;
	public const int32 PRTH_E_OPLOCK_BROKEN = -2147216874;
	public const int32 PRTH_E_LOAD_FAILED = -2147216873;
	public const int32 PRTH_E_INIT_FAILED = -2147216872;
	public const int32 PRTH_E_VOLUME_MOUNT_POINT = -2147216871;
	public const int32 PRTH_E_TRUNCATED = -2147216870;
	public const int32 GTHR_E_LOCAL_GROUPS_EXPANSION_INTERNAL_ERROR = -2147216867;
	public const int32 PRTH_E_HTTPS_CERTIFICATE_ERROR = -2147216861;
	public const int32 PRTH_E_HTTPS_REQUIRE_CERTIFICATE = -2147216860;
	public const int32 PRTH_S_TRY_IMPERSONATING = 266789;
	public const int32 CMDLINE_E_UNEXPECTED = -2147216127;
	public const int32 CMDLINE_E_PAREN = -2147216126;
	public const int32 CMDLINE_E_PARAM_SIZE = -2147216125;
	public const int32 CMDLINE_E_NOT_INIT = -2147216124;
	public const int32 CMDLINE_E_ALREADY_INIT = -2147216123;
	public const int32 CMDLINE_E_NUM_PARAMS = -2147216122;
	public const int32 NLADMIN_E_DUPLICATE_CATALOG = -2147215103;
	public const int32 NLADMIN_S_NOT_ALL_BUILD_CATALOGS_INITIALIZED = 268546;
	public const int32 NLADMIN_E_FAILED_TO_GIVE_ACCOUNT_PRIVILEGE = -2147215101;
	public const int32 NLADMIN_E_BUILD_CATALOG_NOT_INITIALIZED = -2147215100;
	public const int32 SCRIPTPI_E_CHUNK_NOT_TEXT = -2147213312;
	public const int32 SCRIPTPI_E_PID_NOT_NAME = -2147213311;
	public const int32 SCRIPTPI_E_PID_NOT_NUMERIC = -2147213310;
	public const int32 SCRIPTPI_E_CHUNK_NOT_VALUE = -2147213309;
	public const int32 SCRIPTPI_E_CANNOT_ALTER_CHUNK = -2147213308;
	public const int32 SCRIPTPI_E_ALREADY_COMPLETED = -2147213307;
	public const int32 _MAPI_E_NO_SUPPORT = -2147221246;
	public const int32 _MAPI_E_BAD_CHARWIDTH = -2147221245;
	public const int32 _MAPI_E_STRING_TOO_LONG = -2147221243;
	public const int32 _MAPI_E_UNKNOWN_FLAGS = -2147221242;
	public const int32 _MAPI_E_INVALID_ENTRYID = -2147221241;
	public const int32 _MAPI_E_INVALID_OBJECT = -2147221240;
	public const int32 _MAPI_E_OBJECT_CHANGED = -2147221239;
	public const int32 _MAPI_E_OBJECT_DELETED = -2147221238;
	public const int32 _MAPI_E_BUSY = -2147221237;
	public const int32 _MAPI_E_NOT_ENOUGH_DISK = -2147221235;
	public const int32 _MAPI_E_NOT_ENOUGH_RESOURCES = -2147221234;
	public const int32 _MAPI_E_NOT_FOUND = -2147221233;
	public const int32 _MAPI_E_VERSION = -2147221232;
	public const int32 _MAPI_E_LOGON_FAILED = -2147221231;
	public const int32 _MAPI_E_SESSION_LIMIT = -2147221230;
	public const int32 _MAPI_E_USER_CANCEL = -2147221229;
	public const int32 _MAPI_E_UNABLE_TO_ABORT = -2147221228;
	public const int32 _MAPI_E_NETWORK_ERROR = -2147221227;
	public const int32 _MAPI_E_DISK_ERROR = -2147221226;
	public const int32 _MAPI_E_TOO_COMPLEX = -2147221225;
	public const int32 _MAPI_E_BAD_COLUMN = -2147221224;
	public const int32 _MAPI_E_EXTENDED_ERROR = -2147221223;
	public const int32 _MAPI_E_COMPUTED = -2147221222;
	public const int32 _MAPI_E_CORRUPT_DATA = -2147221221;
	public const int32 _MAPI_E_UNCONFIGURED = -2147221220;
	public const int32 _MAPI_E_FAILONEPROVIDER = -2147221219;
	public const int32 _MAPI_E_UNKNOWN_CPID = -2147221218;
	public const int32 _MAPI_E_UNKNOWN_LCID = -2147221217;
	public const int32 _MAPI_E_PASSWORD_CHANGE_REQUIRED = -2147221216;
	public const int32 _MAPI_E_PASSWORD_EXPIRED = -2147221215;
	public const int32 _MAPI_E_INVALID_WORKSTATION_ACCOUNT = -2147221214;
	public const int32 _MAPI_E_INVALID_ACCESS_TIME = -2147221213;
	public const int32 _MAPI_E_ACCOUNT_DISABLED = -2147221212;
	public const int32 _MAPI_E_END_OF_SESSION = -2147220992;
	public const int32 _MAPI_E_UNKNOWN_ENTRYID = -2147220991;
	public const int32 _MAPI_E_MISSING_REQUIRED_COLUMN = -2147220990;
	public const int32 _MAPI_W_NO_SERVICE = 262659;
	public const int32 MSG_TEST_MESSAGE = 1074008064;
	public const int32 FLTRDMN_E_UNEXPECTED = -2147212287;
	public const int32 FLTRDMN_E_QI_FILTER_FAILED = -2147212286;
	public const int32 FLTRDMN_E_FILTER_INIT_FAILED = -2147212284;
	public const int32 FLTRDMN_E_ENCRYPTED_DOCUMENT = -2147212283;
	public const int32 FLTRDMN_E_CANNOT_DECRYPT_PASSWORD = -2147212282;
	public const int32 OLEDB_BINDER_CUSTOM_ERROR = -2147212032;
	public const int32 NOTESPH_E_UNEXPECTED_STATE = -2147211775;
	public const int32 NOTESPH_S_IGNORE_ID = 271874;
	public const int32 NOTESPH_E_UNSUPPORTED_CONTENT_FIELD_TYPE = -2147211773;
	public const int32 NOTESPH_E_ITEM_NOT_FOUND = -2147211772;
	public const int32 NOTESPH_E_SERVER_CONFIG = -2147211771;
	public const int32 NOTESPH_E_ATTACHMENTS = -2147211770;
	public const int32 NOTESPH_E_NO_NTID = -2147211769;
	public const int32 NOTESPH_E_DB_ACCESS_DENIED = -2147211768;
	public const int32 NOTESPH_E_NOTESSETUP_ID_MAPPING_ERROR = -2147211767;
	public const int32 NOTESPH_S_LISTKNOWNFIELDS = 271888;
	public const int32 NOTESPH_E_FAIL = -2147211759;
	public const int32 STS_ABORTXMLPARSE = -2147211756;
	public const int32 STS_WS_ERROR = -2147211754;
	public const int32 SPS_WS_ERROR = -2147211753;
	public const int32 EXSTOREPH_E_UNEXPECTED = -2147211519;
	public const int32 CERT_E_NOT_FOUND_OR_NO_PERMISSSION = -2147211263;
	public const int32 SRCH_SCHEMA_CACHE_E_UNEXPECTED = -2147208447;
	public const int32 CONTENT_SOURCE_E_PROPERTY_MAPPING_READ = -2147208191;
	public const int32 CONTENT_SOURCE_E_UNEXPECTED_NULL_POINTER = -2147208190;
	public const int32 CONTENT_SOURCE_E_PROPERTY_MAPPING_BAD_VECTOR_SIZE = -2147208189;
	public const int32 CONTENT_SOURCE_E_CONTENT_CLASS_READ = -2147208188;
	public const int32 CONTENT_SOURCE_E_UNEXPECTED_EXCEPTION = -2147208187;
	public const int32 CONTENT_SOURCE_E_NULL_CONTENT_CLASS_BSTR = -2147208186;
	public const int32 CONTENT_SOURCE_E_CONTENT_SOURCE_COLUMN_TYPE = -2147208185;
	public const int32 CONTENT_SOURCE_E_OUT_OF_RANGE = -2147208184;
	public const int32 CONTENT_SOURCE_E_NULL_URI = -2147208183;
	public const int32 REXSPH_E_INVALID_CALL = -2147207936;
	public const int32 REXSPH_S_REDIRECTED = 275713;
	public const int32 REXSPH_E_REDIRECT_ON_SECURITY_UPDATE = -2147207934;
	public const int32 REXSPH_E_MULTIPLE_REDIRECT = -2147207933;
	public const int32 REXSPH_E_NO_PROPERTY_ON_ROW = -2147207932;
	public const int32 REXSPH_E_TYPE_MISMATCH_ON_READ = -2147207931;
	public const int32 REXSPH_E_UNEXPECTED_DATA_STATUS = -2147207930;
	public const int32 REXSPH_E_UNKNOWN_DATA_TYPE = -2147207929;
	public const int32 REXSPH_E_UNEXPECTED_FILTER_STATE = -2147207928;
	public const int32 REXSPH_E_DUPLICATE_PROPERTY = -2147207927;
	public const int32 PEOPLE_IMPORT_E_DBCONNFAIL = -2147205120;
	public const int32 PEOPLE_IMPORT_NODSDEFINED = -2147205119;
	public const int32 PEOPLE_IMPORT_E_FAILTOGETDSDEF = -2147205118;
	public const int32 PEOPLE_IMPORT_NOMAPPINGDEFINED = -2147205117;
	public const int32 PEOPLE_IMPORT_E_FAILTOGETDSMAPPING = -2147205116;
	public const int32 PEOPLE_IMPORT_E_DATATYPENOTSUPPORTED = -2147205115;
	public const int32 PEOPLE_IMPORT_E_NOCASTINGSUPPORTED = -2147205114;
	public const int32 PEOPLE_IMPORT_E_UPDATE_DIRSYNC_COOKIE = -2147205113;
	public const int32 PEOPLE_IMPORT_E_DIRSYNC_ZERO_COOKIE = -2147205112;
	public const int32 PEOPLE_IMPORT_E_LDAPPATH_TOOLONG = -2147205111;
	public const int32 PEOPLE_IMPORT_E_CANONICALURL_TOOLONG = -2147205110;
	public const int32 PEOPLE_IMPORT_E_USERNAME_NOTRESOLVED = -2147205109;
	public const int32 PEOPLE_IMPORT_E_DC_NOT_AVAILABLE = -2147205108;
	public const int32 PEOPLE_IMPORT_E_DOMAIN_DISCOVER_FAILED = -2147205107;
	public const int32 PEOPLE_IMPORT_E_FAILTOGETLCID = -2147205106;
	public const int32 PEOPLE_IMPORT_E_DOMAIN_REMOVED = -2147205105;
	public const int32 PEOPLE_IMPORT_E_ENUM_ACCESSDENIED = -2147205104;
	public const int32 PEOPLE_IMPORT_E_DIRSYNC_NOTREFRESHED = -2147205103;
	public const int32 FTE_E_SECRET_NOT_FOUND = -2147207678;
	public const int32 FTE_E_PIPE_NOT_CONNECTED = -2147207677;
	public const int32 FTE_E_ADMIN_BLOB_CORRUPT = -2147207676;
	public const int32 FTE_E_FILTER_SINGLE_THREADED = -2147207675;
	public const int32 FTE_E_ERROR_WRITING_REGISTRY = -2147207674;
	public const int32 FTE_E_PROJECT_SHUTDOWN = -2147207673;
	public const int32 FTE_E_PROJECT_NOT_INITALIZED = -2147207672;
	public const int32 FTE_E_PIPE_DATA_CORRUPTED = -2147207671;
	public const int32 FTE_E_URB_TOO_BIG = -2147207664;
	public const int32 FTE_E_INVALID_DOCID = -2147207663;
	public const int32 FTE_E_PAUSE_EXTERNAL = -2147207662;
	public const int32 FTE_E_REJECTED_DUE_TO_PROJECT_STATUS = -2147207661;
	public const int32 FTE_E_FD_DID_NOT_CONNECT = -2147207660;
	public const int32 FTE_E_PROGID_REQUIRED = -2147207658;
	public const int32 FTE_E_STATIC_THREAD_INVALID_ARGUMENTS = -2147207657;
	public const int32 FTE_E_CATALOG_ALREADY_EXISTS = -2147207656;
	public const int32 FTE_S_RESOURCES_STARTING_TO_GET_LOW = 275993;
	public const int32 FTE_E_PATH_TOO_LONG = -2147207654;
	public const int32 FTE_INVALID_ADMIN_CLIENT = -2147207653;
	public const int32 FTE_E_COM_SIGNATURE_VALIDATION = -2147207652;
	public const int32 FTE_E_AFFINITY_MASK = -2147207651;
	public const int32 FTE_E_FD_OWNERSHIP_OBSOLETE = -2147207650;
	public const int32 FTE_E_EXCEEDED_MAX_PLUGINS = -2147207647;
	public const int32 FTE_S_BEYOND_QUOTA = 276002;
	public const int32 FTE_E_DUPLICATE_OBJECT = -2147207644;
	public const int32 FTE_S_REDUNDANT = 276005;
	public const int32 FTE_E_REDUNDANT_TRAN_FAILURE = -2147207642;
	public const int32 FTE_E_DEPENDENT_TRAN_FAILED_TO_PERSIST = -2147207641;
	public const int32 FTE_E_FD_SHUTDOWN = -2147207640;
	public const int32 FTE_E_CATALOG_DOES_NOT_EXIST = -2147207639;
	public const int32 FTE_E_NO_PLUGINS = -2147207638;
	public const int32 FTE_S_STATUS_CHANGE_REQUEST = 276011;
	public const int32 FTE_E_BATCH_ABORTED = -2147207636;
	public const int32 FTE_E_ANOTHER_STATUS_CHANGE_IS_ALREADY_ACTIVE = -2147207635;
	public const int32 FTE_S_RESUME = 276014;
	public const int32 FTE_E_NOT_PROCESSED_DUE_TO_PREVIOUS_ERRORS = -2147207633;
	public const int32 FTE_E_FD_TIMEOUT = -2147207632;
	public const int32 FTE_E_RESOURCE_SHUTDOWN = -2147207631;
	public const int32 FTE_E_INVALID_PROPERTY = -2147207630;
	public const int32 FTE_E_NO_MORE_PROPERTIES = -2147207629;
	public const int32 FTE_E_UNKNOWN_PLUGIN = -2147207628;
	public const int32 FTE_E_LIBRARY_NOT_LOADED = -2147207627;
	public const int32 FTE_E_PERFMON_FULL = -2147207626;
	public const int32 FTE_E_FAILED_TO_CREATE_ACCESSOR = -2147207625;
	public const int32 FTE_E_INVALID_TYPE = -2147207624;
	public const int32 FTE_E_OUT_OF_RANGE = -2147207623;
	public const int32 FTE_E_CORRUPT_PROPERTY_STORE = -2147207622;
	public const int32 FTE_E_PROPERTY_STORE_WORKID_NOTVALID = -2147207621;
	public const int32 FTE_S_PROPERTY_STORE_END_OF_ENUMERATION = 276028;
	public const int32 FTE_E_CORRUPT_GATHERER_HASH_MAP = -2147207619;
	public const int32 FTE_E_KEY_NOT_CACHED = -2147207618;
	public const int32 FTE_E_UPGRADE_INTERFACE_ALREADY_SHUTDOWN = -2147207617;
	public const int32 FTE_E_UPGRADE_INTERFACE_ALREADY_INSTANTIATED = -2147207616;
	public const int32 FTE_E_STACK_CORRUPTED = -2147207615;
	public const int32 FTE_E_INVALID_PROG_ID = -2147207614;
	public const int32 FTE_E_SERIAL_STREAM_CORRUPT = -2147207613;
	public const int32 FTE_E_READONLY_CATALOG = -2147207612;
	public const int32 FTE_E_PERF_NOT_LOADED = -2147207611;
	public const int32 FTE_S_READONLY_CATALOG = 276038;
	public const int32 FTE_E_RETRY_HUGE_DOC = -2147207608;
	public const int32 FTE_E_UNKNOWN_FD_TYPE = -2147207607;
	public const int32 FTE_E_DOC_TOO_HUGE = -2147207606;
	public const int32 FTE_E_DATATYPE_MISALIGNMENT = -2147207605;
	public const int32 FTE_E_ALREADY_INITIALIZED = -2147207604;
	public const int32 FTE_E_FD_USED_TOO_MUCH_MEMORY = -2147207603;
	public const int32 FTE_E_UNEXPECTED_EXIT = -2147207602;
	public const int32 FTE_E_HIGH_MEMORY_PRESSURE = -2147207601;
	public const int32 FTE_E_INVALID_ISOLATE_ERROR_BATCH = -2147207600;
	public const int32 FTE_E_RETRY_SINGLE_DOC_PER_BATCH = -2147207599;
	public const int32 FTE_E_INVALID_PROJECT_ID = -2147207598;
	public const int32 FTE_E_FAILURE_TO_POST_SETCOMPLETION_STATUS = -2147207597;
	public const int32 FTE_E_INVALID_CODEPAGE = -2147207596;
	public const int32 FTE_E_FD_IDLE = -2147207595;
	public const int32 FTE_E_FD_UNRESPONSIVE = -2147207594;
	public const int32 FTE_S_TRY_TO_FLUSH = 276055;
	public const int32 FTE_S_CATALOG_BLOB_MISMATCHED = 276056;
	public const int32 FTE_S_PROPERTY_RESET = 276057;
	public const int32 FTE_E_NO_PROPERTY_STORE = -1073465766;
	public const int32 FTE_E_CB_OUT_OF_MEMORY = -2147169536;
	public const int32 FTE_E_CB_CBID_OUT_OF_BOUND = -2147169535;
	public const int32 FTE_E_CB_NOT_ENOUGH_AVAIL_PHY_MEM = -2147169534;
	public const int32 FTE_E_CB_NOT_ENOUGH_OCC_BUFFER = -2147169533;
	public const int32 FTE_E_CORRUPT_WORDLIST = -2147169532;
	public const int32 FTE_E_FD_NO_IPERSIST_INTERFACE = -2147156736;
	public const int32 FTE_E_FD_IFILTER_INIT_FAILED = -2147156735;
	public const int32 FTE_E_FD_FAILED_TO_LOAD_IFILTER = -2147156734;
	public const int32 FTE_E_FD_DOC_TIMEOUT = -2147156733;
	public const int32 FTE_E_FD_UNEXPECTED_EXIT = -2147156732;
	public const int32 FTE_E_FD_DOC_UNEXPECTED_EXIT = -2147156731;
	public const int32 FTE_E_FD_NOISE_NO_TEXT_FILTER = -2147156730;
	public const int32 FTE_E_FD_NOISE_NO_IPERSISTSTREAM_ON_TEXT_FILTER = -2147156729;
	public const int32 FTE_E_FD_NOISE_TEXT_FILTER_LOAD_FAILED = -2147156728;
	public const int32 FTE_E_FD_NOISE_TEXT_FILTER_INIT_FAILED = -2147156727;
	public const int32 FTE_E_FD_OCCURRENCE_OVERFLOW = -2147156726;
	public const int32 FTE_E_FD_FILTER_CAUSED_SHARING_VIOLATION = -2147156725;
	public const uint32 ERROR_SOURCE_PROTHNDLR = 4608;
	public const HRESULT QUERY_E_ALLNOISE_AND_NO_RELDOC = -2147215859;
	public const HRESULT QUERY_E_NO_RELDOC = -2147215858;
	public const HRESULT QUERY_E_ALLNOISE_AND_NO_RELPROP = -2147215857;
	public const HRESULT QUERY_E_NO_RELPROP = -2147215856;
	public const HRESULT QUERY_E_REPEATED_RELDOC = -2147215855;
	public const HRESULT QUERY_E_RELDOC_SYNTAX_NOT_SUPPORTED = -2147215854;
	public const HRESULT QUERY_E_INVALID_DOCUMENT_IDENTIFIER = -2147215853;
	public const HRESULT QUERY_E_INCORRECT_VERSION = -2147215852;
	public const HRESULT QUERY_E_INVALIDSCOPE_COALESCE = -2147215851;
	public const HRESULT QUERY_E_INVALIDSORT_COALESCE = -2147215850;
	public const HRESULT QUERY_E_INVALIDCOALESCE = -2147215849;
	public const HRESULT QUERY_E_UPGRADEINPROGRESS = -2147215848;
	public const HRESULT QUERY_E_AGGREGATE_NOT_SUPPORTED = -2147215847;
	public const HRESULT QUERY_E_TOP_LEVEL_IN_GROUP = -2147215846;
	public const HRESULT QUERY_E_DUPLICATE_RANGE_NAME = -2147215845;
	public const HRESULT CI_S_NEW_AUXMETADATA = 268329;
	public const HRESULT CI_E_NO_AUXMETADATA = -2147215318;
	public const HRESULT CI_S_CLIENT_REQUESTED_ABORT = 268331;
	public const HRESULT CI_S_RETRY_DOCUMENT = 268332;
	public const HRESULT CI_E_CORRUPT_FWIDX = -1073473491;
	public const HRESULT CI_E_DIACRITIC_SETTINGS_DIFFER = -1073473490;
	public const HRESULT CI_E_INVALID_CATALOG_LIST_VERSION = -2147215313;
	public const HRESULT CI_S_CATALOG_RESET = 268336;
	public const HRESULT CI_E_NO_CATALOG_MANAGER = -1073473487;
	public const HRESULT CI_E_INCONSISTENT_TRANSACTION = -1073473486;
	public const HRESULT CI_E_PROTECTED_CATALOG_NOT_AVAILABLE = -1073473485;
	public const HRESULT CI_E_NO_PROTECTED_USER = -1073473484;
	public const HRESULT CI_E_MULTIPLE_PROTECTED_USERS_UNSUPPORTED = -1073473483;
	public const HRESULT CI_E_PROTECTED_CATALOG_SID_MISMATCH = -1073473482;
	public const HRESULT CI_E_PROTECTED_CATALOG_NON_INTERACTIVE_USER = -1073473481;
	public const HRESULT MSG_CI_MASTER_MERGE_STARTED = 1073745926;
	public const HRESULT MSG_CI_MASTER_MERGE_COMPLETED = 1073745927;
	public const HRESULT MSG_CI_MASTER_MERGE_ABORTED = 1073745928;
	public const HRESULT MSG_CI_MASTER_MERGE_CANT_START = -1073737719;
	public const HRESULT MSG_CI_MASTER_MERGE_CANT_RESTART = -1073737718;
	public const HRESULT MSG_CI_MASTER_MERGE_RESTARTED = 1073745945;
	public const HRESULT MSG_CI_CORRUPT_INDEX_COMPONENT = 1073745962;
	public const HRESULT MSG_CI_MASTER_MERGE_ABORTED_LOW_DISK = 1073745987;
	public const HRESULT MSG_CI_MASTER_MERGE_REASON_EXTERNAL = 1073745988;
	public const HRESULT MSG_CI_MASTER_MERGE_REASON_INDEX_LIMIT = 1073745989;
	public const HRESULT MSG_CI_MASTER_MERGE_REASON_EXPECTED_DOCS = 1073745990;
	public const HRESULT MSG_CI_MASTER_MERGE_REASON_NUMBER = 1073745991;
	public const HRESULT MSG_CI_CREATE_SEVER_ITEM_FAILED = -2147479480;
	public const HRESULT NOT_N_PARSE_ERROR = 526638;
	public const HRESULT IDS_MON_DEFAULT_ERROR = 264495;
	public const HRESULT IDS_MON_ILLEGAL_PASSTHROUGH = 264496;
	public const HRESULT IDS_MON_PARSE_ERR_1_PARAM = 264497;
	public const HRESULT IDS_MON_PARSE_ERR_2_PARAM = 264498;
	public const HRESULT IDS_MON_SEMI_COLON = 264499;
	public const HRESULT IDS_MON_ORDINAL_OUT_OF_RANGE = 264500;
	public const HRESULT IDS_MON_VIEW_NOT_DEFINED = 264501;
	public const HRESULT IDS_MON_COLUMN_NOT_DEFINED = 264502;
	public const HRESULT IDS_MON_BUILTIN_VIEW = 264503;
	public const HRESULT IDS_MON_OUT_OF_MEMORY = 264504;
	public const HRESULT IDS_MON_SELECT_STAR = 264505;
	public const HRESULT IDS_MON_OR_NOT = 264506;
	public const HRESULT IDS_MON_CANNOT_CONVERT = 264507;
	public const HRESULT IDS_MON_OUT_OF_RANGE = 264508;
	public const HRESULT IDS_MON_RELATIVE_INTERVAL = 264509;
	public const HRESULT IDS_MON_NOT_COLUMN_OF_VIEW = 264510;
	public const HRESULT IDS_MON_BUILTIN_PROPERTY = 264511;
	public const HRESULT IDS_MON_WEIGHT_OUT_OF_RANGE = 264512;
	public const HRESULT IDS_MON_MATCH_STRING = 264513;
	public const HRESULT IDS_MON_PROPERTY_NAME_IN_VIEW = 264514;
	public const HRESULT IDS_MON_VIEW_ALREADY_DEFINED = 264515;
	public const HRESULT IDS_MON_INVALID_CATALOG = 264516;
	public const HRESULT IDS_MON_INVALIDSELECT_COALESCE = 264517;
	public const HRESULT IDS_MON_CANNOT_CAST = 264518;
	public const HRESULT IDS_MON_DATE_OUT_OF_RANGE = 264519;
	public const HRESULT IDS_MON_INVALID_IN_GROUP_CLAUSE = 264520;
	public const Guid DBPROPSET_MSDAORA_ROWSET = .(0xe8cc4cbd, 0xfdff, 0x11d0, 0xb8, 0x65, 0x00, 0xa0, 0xc9, 0x08, 0x1c, 0x1d);
	public const Guid DBPROPSET_MSDAORA8_ROWSET = .(0x7f06a375, 0xdd6a, 0x43db, 0xb4, 0xe0, 0x1f, 0xc1, 0x21, 0xe5, 0xe6, 0x2b);
	public const Guid CLSID_MSDASQL = .(0xc8b522cb, 0x5cf3, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);
	public const Guid CLSID_MSDASQL_ENUMERATOR = .(0xc8b522cd, 0x5cf3, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);
	public const Guid DBPROPSET_PROVIDERDATASOURCEINFO = .(0x497c60e0, 0x7123, 0x11cf, 0xb1, 0x71, 0x00, 0xaa, 0x00, 0x57, 0x59, 0x9e);
	public const Guid DBPROPSET_PROVIDERROWSET = .(0x497c60e1, 0x7123, 0x11cf, 0xb1, 0x71, 0x00, 0xaa, 0x00, 0x57, 0x59, 0x9e);
	public const Guid DBPROPSET_PROVIDERDBINIT = .(0x497c60e2, 0x7123, 0x11cf, 0xb1, 0x71, 0x00, 0xaa, 0x00, 0x57, 0x59, 0x9e);
	public const Guid DBPROPSET_PROVIDERSTMTATTR = .(0x497c60e3, 0x7123, 0x11cf, 0xb1, 0x71, 0x00, 0xaa, 0x00, 0x57, 0x59, 0x9e);
	public const Guid DBPROPSET_PROVIDERCONNATTR = .(0x497c60e4, 0x7123, 0x11cf, 0xb1, 0x71, 0x00, 0xaa, 0x00, 0x57, 0x59, 0x9e);
	public const Guid CLSID_DataShapeProvider = .(0x3449a1c8, 0xc56c, 0x11d0, 0xad, 0x72, 0x00, 0xc0, 0x4f, 0xc2, 0x98, 0x63);
	public const Guid DBPROPSET_MSDSDBINIT = .(0x55cb91a8, 0x5c7a, 0x11d1, 0xad, 0xad, 0x00, 0xc0, 0x4f, 0xc2, 0x98, 0x63);
	public const Guid DBPROPSET_MSDSSESSION = .(0xedf17536, 0xafbf, 0x11d1, 0x88, 0x47, 0x00, 0x00, 0xf8, 0x79, 0xf9, 0x8c);
	public const Guid CLSID_MSPersist = .(0x7c07e0d0, 0x4418, 0x11d2, 0x92, 0x12, 0x00, 0xc0, 0x4f, 0xbb, 0xbf, 0xb3);
	public const Guid DBPROPSET_PERSIST = .(0x4d7839a0, 0x5b8e, 0x11d1, 0xa6, 0xb3, 0x00, 0xa0, 0xc9, 0x13, 0x8c, 0x66);
	public const String PROGID_MSPersist_W = "MSPersist";
	public const String PROGID_MSPersist_Version_W = "MSPersist.1";
	public const Guid CLSID_SQLOLEDB = .(0x0c7ff16c, 0x38e3, 0x11d0, 0x97, 0xab, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid CLSID_SQLOLEDB_ERROR = .(0xc0932c62, 0x38e5, 0x11d0, 0x97, 0xab, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid CLSID_SQLOLEDB_ENUMERATOR = .(0xdfa22b8e, 0xe68d, 0x11d0, 0x97, 0xe4, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid DBGUID_MSSQLXML = .(0x5d531cb2, 0xe6ed, 0x11d2, 0xb2, 0x52, 0x00, 0xc0, 0x4f, 0x68, 0x1b, 0x71);
	public const Guid DBGUID_XPATH = .(0xec2a4293, 0xe898, 0x11d2, 0xb1, 0xb7, 0x00, 0xc0, 0x4f, 0x68, 0x0c, 0x56);
	public const Guid DBSCHEMA_LINKEDSERVERS = .(0x9093caf4, 0x2eac, 0x11d1, 0x98, 0x09, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid DBPROPSET_SQLSERVERDATASOURCE = .(0x28efaee4, 0x2d2c, 0x11d1, 0x98, 0x07, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid DBPROPSET_SQLSERVERDATASOURCEINFO = .(0xdf10cb94, 0x35f6, 0x11d2, 0x9c, 0x54, 0x00, 0xc0, 0x4f, 0x79, 0x71, 0xd3);
	public const Guid DBPROPSET_SQLSERVERDBINIT = .(0x5cf4ca10, 0xef21, 0x11d0, 0x97, 0xe7, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid DBPROPSET_SQLSERVERROWSET = .(0x5cf4ca11, 0xef21, 0x11d0, 0x97, 0xe7, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid DBPROPSET_SQLSERVERSESSION = .(0x28efaee5, 0x2d2c, 0x11d1, 0x98, 0x07, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);
	public const Guid DBPROPSET_SQLSERVERCOLUMN = .(0x3b63fb5e, 0x3fbb, 0x11d3, 0x9f, 0x29, 0x00, 0xc0, 0x4f, 0x8e, 0xe9, 0xdc);
	public const Guid DBPROPSET_SQLSERVERSTREAM = .(0x9f79c073, 0x8a6d, 0x4bca, 0xa8, 0xa8, 0xc9, 0xb7, 0x9a, 0x9b, 0x96, 0x2d);
}
#endregion

#region TypeDefs
typealias HACCESSOR = uint;

#endregion


#region Enums

[AllowDuplicates]
public enum DBTYPEENUM : int32
{
	DBTYPE_EMPTY = 0,
	DBTYPE_NULL = 1,
	DBTYPE_I2 = 2,
	DBTYPE_I4 = 3,
	DBTYPE_R4 = 4,
	DBTYPE_R8 = 5,
	DBTYPE_CY = 6,
	DBTYPE_DATE = 7,
	DBTYPE_BSTR = 8,
	DBTYPE_IDISPATCH = 9,
	DBTYPE_ERROR = 10,
	DBTYPE_BOOL = 11,
	DBTYPE_VARIANT = 12,
	DBTYPE_IUNKNOWN = 13,
	DBTYPE_DECIMAL = 14,
	DBTYPE_UI1 = 17,
	DBTYPE_ARRAY = 8192,
	DBTYPE_BYREF = 16384,
	DBTYPE_I1 = 16,
	DBTYPE_UI2 = 18,
	DBTYPE_UI4 = 19,
	DBTYPE_I8 = 20,
	DBTYPE_UI8 = 21,
	DBTYPE_GUID = 72,
	DBTYPE_VECTOR = 4096,
	DBTYPE_RESERVED = 32768,
	DBTYPE_BYTES = 128,
	DBTYPE_STR = 129,
	DBTYPE_WSTR = 130,
	DBTYPE_NUMERIC = 131,
	DBTYPE_UDT = 132,
	DBTYPE_DBDATE = 133,
	DBTYPE_DBTIME = 134,
	DBTYPE_DBTIMESTAMP = 135,
}


[AllowDuplicates]
public enum DBTYPEENUM15 : int32
{
	DBTYPE_HCHAPTER = 136,
}


[AllowDuplicates]
public enum DBTYPEENUM20 : int32
{
	DBTYPE_FILETIME = 64,
	DBTYPE_PROPVARIANT = 138,
	DBTYPE_VARNUMERIC = 139,
}


[AllowDuplicates]
public enum DBPARTENUM : int32
{
	DBPART_INVALID = 0,
	DBPART_VALUE = 1,
	DBPART_LENGTH = 2,
	DBPART_STATUS = 4,
}


[AllowDuplicates]
public enum DBPARAMIOENUM : int32
{
	DBPARAMIO_NOTPARAM = 0,
	DBPARAMIO_INPUT = 1,
	DBPARAMIO_OUTPUT = 2,
}


[AllowDuplicates]
public enum DBBINDFLAGENUM : int32
{
	DBBINDFLAG_HTML = 1,
}


[AllowDuplicates]
public enum DBMEMOWNERENUM : int32
{
	DBMEMOWNER_CLIENTOWNED = 0,
	DBMEMOWNER_PROVIDEROWNED = 1,
}


[AllowDuplicates]
public enum DBSTATUSENUM : int32
{
	DBSTATUS_S_OK = 0,
	DBSTATUS_E_BADACCESSOR = 1,
	DBSTATUS_E_CANTCONVERTVALUE = 2,
	DBSTATUS_S_ISNULL = 3,
	DBSTATUS_S_TRUNCATED = 4,
	DBSTATUS_E_SIGNMISMATCH = 5,
	DBSTATUS_E_DATAOVERFLOW = 6,
	DBSTATUS_E_CANTCREATE = 7,
	DBSTATUS_E_UNAVAILABLE = 8,
	DBSTATUS_E_PERMISSIONDENIED = 9,
	DBSTATUS_E_INTEGRITYVIOLATION = 10,
	DBSTATUS_E_SCHEMAVIOLATION = 11,
	DBSTATUS_E_BADSTATUS = 12,
	DBSTATUS_S_DEFAULT = 13,
}


[AllowDuplicates]
public enum DBSTATUSENUM20 : int32
{
	MDSTATUS_S_CELLEMPTY = 14,
	DBSTATUS_S_IGNORE = 15,
}


[AllowDuplicates]
public enum DBSTATUSENUM21 : int32
{
	DBSTATUS_E_DOESNOTEXIST = 16,
	DBSTATUS_E_INVALIDURL = 17,
	DBSTATUS_E_RESOURCELOCKED = 18,
	DBSTATUS_E_RESOURCEEXISTS = 19,
	DBSTATUS_E_CANNOTCOMPLETE = 20,
	DBSTATUS_E_VOLUMENOTFOUND = 21,
	DBSTATUS_E_OUTOFSPACE = 22,
	DBSTATUS_S_CANNOTDELETESOURCE = 23,
	DBSTATUS_E_READONLY = 24,
	DBSTATUS_E_RESOURCEOUTOFSCOPE = 25,
	DBSTATUS_S_ALREADYEXISTS = 26,
}


[AllowDuplicates]
public enum DBBINDURLFLAGENUM : int32
{
	DBBINDURLFLAG_READ = 1,
	DBBINDURLFLAG_WRITE = 2,
	DBBINDURLFLAG_READWRITE = 3,
	DBBINDURLFLAG_SHARE_DENY_READ = 4,
	DBBINDURLFLAG_SHARE_DENY_WRITE = 8,
	DBBINDURLFLAG_SHARE_EXCLUSIVE = 12,
	DBBINDURLFLAG_SHARE_DENY_NONE = 16,
	DBBINDURLFLAG_ASYNCHRONOUS = 4096,
	DBBINDURLFLAG_COLLECTION = 8192,
	DBBINDURLFLAG_DELAYFETCHSTREAM = 16384,
	DBBINDURLFLAG_DELAYFETCHCOLUMNS = 32768,
	DBBINDURLFLAG_RECURSIVE = 4194304,
	DBBINDURLFLAG_OUTPUT = 8388608,
	DBBINDURLFLAG_WAITFORINIT = 16777216,
	DBBINDURLFLAG_OPENIFEXISTS = 33554432,
	DBBINDURLFLAG_OVERWRITE = 67108864,
	DBBINDURLFLAG_ISSTRUCTUREDDOCUMENT = 134217728,
}


[AllowDuplicates]
public enum DBBINDURLSTATUSENUM : int32
{
	DBBINDURLSTATUS_S_OK = 0,
	DBBINDURLSTATUS_S_DENYNOTSUPPORTED = 1,
	DBBINDURLSTATUS_S_DENYTYPENOTSUPPORTED = 4,
	DBBINDURLSTATUS_S_REDIRECTED = 8,
}


[AllowDuplicates]
public enum DBSTATUSENUM25 : int32
{
	DBSTATUS_E_CANCELED = 27,
	DBSTATUS_E_NOTCOLLECTION = 28,
}


[AllowDuplicates]
public enum DBROWSTATUSENUM : int32
{
	DBROWSTATUS_S_OK = 0,
	DBROWSTATUS_S_MULTIPLECHANGES = 2,
	DBROWSTATUS_S_PENDINGCHANGES = 3,
	DBROWSTATUS_E_CANCELED = 4,
	DBROWSTATUS_E_CANTRELEASE = 6,
	DBROWSTATUS_E_CONCURRENCYVIOLATION = 7,
	DBROWSTATUS_E_DELETED = 8,
	DBROWSTATUS_E_PENDINGINSERT = 9,
	DBROWSTATUS_E_NEWLYINSERTED = 10,
	DBROWSTATUS_E_INTEGRITYVIOLATION = 11,
	DBROWSTATUS_E_INVALID = 12,
	DBROWSTATUS_E_MAXPENDCHANGESEXCEEDED = 13,
	DBROWSTATUS_E_OBJECTOPEN = 14,
	DBROWSTATUS_E_OUTOFMEMORY = 15,
	DBROWSTATUS_E_PERMISSIONDENIED = 16,
	DBROWSTATUS_E_LIMITREACHED = 17,
	DBROWSTATUS_E_SCHEMAVIOLATION = 18,
	DBROWSTATUS_E_FAIL = 19,
}


[AllowDuplicates]
public enum DBROWSTATUSENUM20 : int32
{
	DBROWSTATUS_S_NOCHANGE = 20,
}


[AllowDuplicates]
public enum DBSTATUSENUM26 : int32
{
	DBSTATUS_S_ROWSETCOLUMN = 29,
}


[AllowDuplicates]
public enum DBCOLUMNFLAGSENUM : int32
{
	DBCOLUMNFLAGS_ISBOOKMARK = 1,
	DBCOLUMNFLAGS_MAYDEFER = 2,
	DBCOLUMNFLAGS_WRITE = 4,
	DBCOLUMNFLAGS_WRITEUNKNOWN = 8,
	DBCOLUMNFLAGS_ISFIXEDLENGTH = 16,
	DBCOLUMNFLAGS_ISNULLABLE = 32,
	DBCOLUMNFLAGS_MAYBENULL = 64,
	DBCOLUMNFLAGS_ISLONG = 128,
	DBCOLUMNFLAGS_ISROWID = 256,
	DBCOLUMNFLAGS_ISROWVER = 512,
	DBCOLUMNFLAGS_CACHEDEFERRED = 4096,
}


[AllowDuplicates]
public enum DBCOLUMNFLAGSENUM20 : int32
{
	DBCOLUMNFLAGS_SCALEISNEGATIVE = 16384,
	DBCOLUMNFLAGS_RESERVED = 32768,
}


[AllowDuplicates]
public enum DBCOLUMNFLAGS15ENUM : int32
{
	DBCOLUMNFLAGS_ISCHAPTER = 8192,
}


[AllowDuplicates]
public enum DBCOLUMNFLAGSENUM21 : int32
{
	DBCOLUMNFLAGS_ISROWURL = 65536,
	DBCOLUMNFLAGS_ISDEFAULTSTREAM = 131072,
	DBCOLUMNFLAGS_ISCOLLECTION = 262144,
}


[AllowDuplicates]
public enum DBCOLUMNFLAGSENUM26 : int32
{
	DBCOLUMNFLAGS_ISSTREAM = 524288,
	DBCOLUMNFLAGS_ISROWSET = 1048576,
	DBCOLUMNFLAGS_ISROW = 2097152,
	DBCOLUMNFLAGS_ROWSPECIFICCOLUMN = 4194304,
}


[AllowDuplicates]
public enum DBTABLESTATISTICSTYPE26 : int32
{
	DBSTAT_HISTOGRAM = 1,
	DBSTAT_COLUMN_CARDINALITY = 2,
	DBSTAT_TUPLE_CARDINALITY = 4,
}


[AllowDuplicates]
public enum DBBOOKMARK : int32
{
	DBBMK_INVALID = 0,
	DBBMK_FIRST = 1,
	DBBMK_LAST = 2,
}


[AllowDuplicates]
public enum DBPROPENUM : int32
{
	DBPROP_ABORTPRESERVE = 2,
	DBPROP_ACTIVESESSIONS = 3,
	DBPROP_APPENDONLY = 187,
	DBPROP_ASYNCTXNABORT = 168,
	DBPROP_ASYNCTXNCOMMIT = 4,
	DBPROP_AUTH_CACHE_AUTHINFO = 5,
	DBPROP_AUTH_ENCRYPT_PASSWORD = 6,
	DBPROP_AUTH_INTEGRATED = 7,
	DBPROP_AUTH_MASK_PASSWORD = 8,
	DBPROP_AUTH_PASSWORD = 9,
	DBPROP_AUTH_PERSIST_ENCRYPTED = 10,
	DBPROP_AUTH_PERSIST_SENSITIVE_AUTHINFO = 11,
	DBPROP_AUTH_USERID = 12,
	DBPROP_BLOCKINGSTORAGEOBJECTS = 13,
	DBPROP_BOOKMARKS = 14,
	DBPROP_BOOKMARKSKIPPED = 15,
	DBPROP_BOOKMARKTYPE = 16,
	DBPROP_BYREFACCESSORS = 120,
	DBPROP_CACHEDEFERRED = 17,
	DBPROP_CANFETCHBACKWARDS = 18,
	DBPROP_CANHOLDROWS = 19,
	DBPROP_CANSCROLLBACKWARDS = 21,
	DBPROP_CATALOGLOCATION = 22,
	DBPROP_CATALOGTERM = 23,
	DBPROP_CATALOGUSAGE = 24,
	DBPROP_CHANGEINSERTEDROWS = 188,
	DBPROP_COL_AUTOINCREMENT = 26,
	DBPROP_COL_DEFAULT = 27,
	DBPROP_COL_DESCRIPTION = 28,
	DBPROP_COL_FIXEDLENGTH = 167,
	DBPROP_COL_NULLABLE = 29,
	DBPROP_COL_PRIMARYKEY = 30,
	DBPROP_COL_UNIQUE = 31,
	DBPROP_COLUMNDEFINITION = 32,
	DBPROP_COLUMNRESTRICT = 33,
	DBPROP_COMMANDTIMEOUT = 34,
	DBPROP_COMMITPRESERVE = 35,
	DBPROP_CONCATNULLBEHAVIOR = 36,
	DBPROP_CURRENTCATALOG = 37,
	DBPROP_DATASOURCENAME = 38,
	DBPROP_DATASOURCEREADONLY = 39,
	DBPROP_DBMSNAME = 40,
	DBPROP_DBMSVER = 41,
	DBPROP_DEFERRED = 42,
	DBPROP_DELAYSTORAGEOBJECTS = 43,
	DBPROP_DSOTHREADMODEL = 169,
	DBPROP_GROUPBY = 44,
	DBPROP_HETEROGENEOUSTABLES = 45,
	DBPROP_IAccessor = 121,
	DBPROP_IColumnsInfo = 122,
	DBPROP_IColumnsRowset = 123,
	DBPROP_IConnectionPointContainer = 124,
	DBPROP_IConvertType = 194,
	DBPROP_IRowset = 126,
	DBPROP_IRowsetChange = 127,
	DBPROP_IRowsetIdentity = 128,
	DBPROP_IRowsetIndex = 159,
	DBPROP_IRowsetInfo = 129,
	DBPROP_IRowsetLocate = 130,
	DBPROP_IRowsetResynch = 132,
	DBPROP_IRowsetScroll = 133,
	DBPROP_IRowsetUpdate = 134,
	DBPROP_ISupportErrorInfo = 135,
	DBPROP_ILockBytes = 136,
	DBPROP_ISequentialStream = 137,
	DBPROP_IStorage = 138,
	DBPROP_IStream = 139,
	DBPROP_IDENTIFIERCASE = 46,
	DBPROP_IMMOBILEROWS = 47,
	DBPROP_INDEX_AUTOUPDATE = 48,
	DBPROP_INDEX_CLUSTERED = 49,
	DBPROP_INDEX_FILLFACTOR = 50,
	DBPROP_INDEX_INITIALSIZE = 51,
	DBPROP_INDEX_NULLCOLLATION = 52,
	DBPROP_INDEX_NULLS = 53,
	DBPROP_INDEX_PRIMARYKEY = 54,
	DBPROP_INDEX_SORTBOOKMARKS = 55,
	DBPROP_INDEX_TEMPINDEX = 163,
	DBPROP_INDEX_TYPE = 56,
	DBPROP_INDEX_UNIQUE = 57,
	DBPROP_INIT_DATASOURCE = 59,
	DBPROP_INIT_HWND = 60,
	DBPROP_INIT_IMPERSONATION_LEVEL = 61,
	DBPROP_INIT_LCID = 186,
	DBPROP_INIT_LOCATION = 62,
	DBPROP_INIT_MODE = 63,
	DBPROP_INIT_PROMPT = 64,
	DBPROP_INIT_PROTECTION_LEVEL = 65,
	DBPROP_INIT_PROVIDERSTRING = 160,
	DBPROP_INIT_TIMEOUT = 66,
	DBPROP_LITERALBOOKMARKS = 67,
	DBPROP_LITERALIDENTITY = 68,
	DBPROP_MAXINDEXSIZE = 70,
	DBPROP_MAXOPENROWS = 71,
	DBPROP_MAXPENDINGROWS = 72,
	DBPROP_MAXROWS = 73,
	DBPROP_MAXROWSIZE = 74,
	DBPROP_MAXROWSIZEINCLUDESBLOB = 75,
	DBPROP_MAXTABLESINSELECT = 76,
	DBPROP_MAYWRITECOLUMN = 77,
	DBPROP_MEMORYUSAGE = 78,
	DBPROP_MULTIPLEPARAMSETS = 191,
	DBPROP_MULTIPLERESULTS = 196,
	DBPROP_MULTIPLESTORAGEOBJECTS = 80,
	DBPROP_MULTITABLEUPDATE = 81,
	DBPROP_NOTIFICATIONGRANULARITY = 198,
	DBPROP_NOTIFICATIONPHASES = 82,
	DBPROP_NOTIFYCOLUMNSET = 171,
	DBPROP_NOTIFYROWDELETE = 173,
	DBPROP_NOTIFYROWFIRSTCHANGE = 174,
	DBPROP_NOTIFYROWINSERT = 175,
	DBPROP_NOTIFYROWRESYNCH = 177,
	DBPROP_NOTIFYROWSETCHANGED = 211,
	DBPROP_NOTIFYROWSETRELEASE = 178,
	DBPROP_NOTIFYROWSETFETCHPOSITIONCHANGE = 179,
	DBPROP_NOTIFYROWUNDOCHANGE = 180,
	DBPROP_NOTIFYROWUNDODELETE = 181,
	DBPROP_NOTIFYROWUNDOINSERT = 182,
	DBPROP_NOTIFYROWUPDATE = 183,
	DBPROP_NULLCOLLATION = 83,
	DBPROP_OLEOBJECTS = 84,
	DBPROP_ORDERBYCOLUMNSINSELECT = 85,
	DBPROP_ORDEREDBOOKMARKS = 86,
	DBPROP_OTHERINSERT = 87,
	DBPROP_OTHERUPDATEDELETE = 88,
	DBPROP_OUTPUTPARAMETERAVAILABILITY = 184,
	DBPROP_OWNINSERT = 89,
	DBPROP_OWNUPDATEDELETE = 90,
	DBPROP_PERSISTENTIDTYPE = 185,
	DBPROP_PREPAREABORTBEHAVIOR = 91,
	DBPROP_PREPARECOMMITBEHAVIOR = 92,
	DBPROP_PROCEDURETERM = 93,
	DBPROP_PROVIDERNAME = 96,
	DBPROP_PROVIDEROLEDBVER = 97,
	DBPROP_PROVIDERVER = 98,
	DBPROP_QUICKRESTART = 99,
	DBPROP_QUOTEDIDENTIFIERCASE = 100,
	DBPROP_REENTRANTEVENTS = 101,
	DBPROP_REMOVEDELETED = 102,
	DBPROP_REPORTMULTIPLECHANGES = 103,
	DBPROP_RETURNPENDINGINSERTS = 189,
	DBPROP_ROWRESTRICT = 104,
	DBPROP_ROWSETCONVERSIONSONCOMMAND = 192,
	DBPROP_ROWTHREADMODEL = 105,
	DBPROP_SCHEMATERM = 106,
	DBPROP_SCHEMAUSAGE = 107,
	DBPROP_SERVERCURSOR = 108,
	DBPROP_SESS_AUTOCOMMITISOLEVELS = 190,
	DBPROP_SQLSUPPORT = 109,
	DBPROP_STRONGIDENTITY = 119,
	DBPROP_STRUCTUREDSTORAGE = 111,
	DBPROP_SUBQUERIES = 112,
	DBPROP_SUPPORTEDTXNDDL = 161,
	DBPROP_SUPPORTEDTXNISOLEVELS = 113,
	DBPROP_SUPPORTEDTXNISORETAIN = 114,
	DBPROP_TABLETERM = 115,
	DBPROP_TBL_TEMPTABLE = 140,
	DBPROP_TRANSACTEDOBJECT = 116,
	DBPROP_UPDATABILITY = 117,
	DBPROP_USERNAME = 118,
}


[AllowDuplicates]
public enum DBPROPENUM15 : int32
{
	DBPROP_FILTERCOMPAREOPS = 209,
	DBPROP_FINDCOMPAREOPS = 210,
	DBPROP_IChapteredRowset = 202,
	DBPROP_IDBAsynchStatus = 203,
	DBPROP_IRowsetFind = 204,
	DBPROP_IRowsetView = 212,
	DBPROP_IViewChapter = 213,
	DBPROP_IViewFilter = 214,
	DBPROP_IViewRowset = 215,
	DBPROP_IViewSort = 216,
	DBPROP_INIT_ASYNCH = 200,
	DBPROP_MAXOPENCHAPTERS = 199,
	DBPROP_MAXORSINFILTER = 205,
	DBPROP_MAXSORTCOLUMNS = 206,
	DBPROP_ROWSET_ASYNCH = 201,
	DBPROP_SORTONINDEX = 207,
}


[AllowDuplicates]
public enum DBPROPENUM20 : int32
{
	DBPROP_IMultipleResults = 217,
	DBPROP_DATASOURCE_TYPE = 251,
	MDPROP_AXES = 252,
	MDPROP_FLATTENING_SUPPORT = 253,
	MDPROP_MDX_JOINCUBES = 254,
	MDPROP_NAMED_LEVELS = 255,
	MDPROP_RANGEROWSET = 256,
	MDPROP_MDX_SLICER = 218,
	MDPROP_MDX_CUBEQUALIFICATION = 219,
	MDPROP_MDX_OUTERREFERENCE = 220,
	MDPROP_MDX_QUERYBYPROPERTY = 221,
	MDPROP_MDX_CASESUPPORT = 222,
	MDPROP_MDX_STRING_COMPOP = 224,
	MDPROP_MDX_DESCFLAGS = 225,
	MDPROP_MDX_SET_FUNCTIONS = 226,
	MDPROP_MDX_MEMBER_FUNCTIONS = 227,
	MDPROP_MDX_NUMERIC_FUNCTIONS = 228,
	MDPROP_MDX_FORMULAS = 229,
	MDPROP_AGGREGATECELL_UPDATE = 230,
	MDPROP_MDX_AGGREGATECELL_UPDATE = 230,
	MDPROP_MDX_OBJQUALIFICATION = 261,
	MDPROP_MDX_NONMEASURE_EXPRESSIONS = 262,
	DBPROP_ACCESSORDER = 231,
	DBPROP_BOOKMARKINFO = 232,
	DBPROP_INIT_CATALOG = 233,
	DBPROP_ROW_BULKOPS = 234,
	DBPROP_PROVIDERFRIENDLYNAME = 235,
	DBPROP_LOCKMODE = 236,
	DBPROP_MULTIPLECONNECTIONS = 237,
	DBPROP_UNIQUEROWS = 238,
	DBPROP_SERVERDATAONINSERT = 239,
	DBPROP_STORAGEFLAGS = 240,
	DBPROP_CONNECTIONSTATUS = 244,
	DBPROP_ALTERCOLUMN = 245,
	DBPROP_COLUMNLCID = 246,
	DBPROP_RESETDATASOURCE = 247,
	DBPROP_INIT_OLEDBSERVICES = 248,
	DBPROP_IRowsetRefresh = 249,
	DBPROP_SERVERNAME = 250,
	DBPROP_IParentRowset = 257,
	DBPROP_HIDDENCOLUMNS = 258,
	DBPROP_PROVIDERMEMORY = 259,
	DBPROP_CLIENTCURSOR = 260,
}


[AllowDuplicates]
public enum DBPROPENUM21 : int32
{
	DBPROP_TRUSTEE_USERNAME = 241,
	DBPROP_TRUSTEE_AUTHENTICATION = 242,
	DBPROP_TRUSTEE_NEWAUTHENTICATION = 243,
	DBPROP_IRow = 263,
	DBPROP_IRowChange = 264,
	DBPROP_IRowSchemaChange = 265,
	DBPROP_IGetRow = 266,
	DBPROP_IScopedOperations = 267,
	DBPROP_IBindResource = 268,
	DBPROP_ICreateRow = 269,
	DBPROP_INIT_BINDFLAGS = 270,
	DBPROP_INIT_LOCKOWNER = 271,
	DBPROP_GENERATEURL = 273,
	DBPROP_IDBBinderProperties = 274,
	DBPROP_IColumnsInfo2 = 275,
	DBPROP_IRegisterProvider = 276,
	DBPROP_IGetSession = 277,
	DBPROP_IGetSourceRow = 278,
	DBPROP_IRowsetCurrentIndex = 279,
	DBPROP_OPENROWSETSUPPORT = 280,
	DBPROP_COL_ISLONG = 281,
}


[AllowDuplicates]
public enum DBPROPENUM25 : int32
{
	DBPROP_COL_SEED = 282,
	DBPROP_COL_INCREMENT = 283,
	DBPROP_INIT_GENERALTIMEOUT = 284,
	DBPROP_COMSERVICES = 285,
}


[AllowDuplicates]
public enum DBPROPENUM26 : int32
{
	DBPROP_OUTPUTSTREAM = 286,
	DBPROP_OUTPUTENCODING = 287,
	DBPROP_TABLESTATISTICS = 288,
	DBPROP_SKIPROWCOUNTRESULTS = 291,
	DBPROP_IRowsetBookmark = 292,
	MDPROP_VISUALMODE = 293,
}


[AllowDuplicates]
public enum DBPARAMFLAGSENUM : int32
{
	DBPARAMFLAGS_ISINPUT = 1,
	DBPARAMFLAGS_ISOUTPUT = 2,
	DBPARAMFLAGS_ISSIGNED = 16,
	DBPARAMFLAGS_ISNULLABLE = 64,
	DBPARAMFLAGS_ISLONG = 128,
}


[AllowDuplicates]
public enum DBPARAMFLAGSENUM20 : int32
{
	DBPARAMFLAGS_SCALEISNEGATIVE = 256,
}


[AllowDuplicates]
public enum DBPROPFLAGSENUM : int32
{
	DBPROPFLAGS_NOTSUPPORTED = 0,
	DBPROPFLAGS_COLUMN = 1,
	DBPROPFLAGS_DATASOURCE = 2,
	DBPROPFLAGS_DATASOURCECREATE = 4,
	DBPROPFLAGS_DATASOURCEINFO = 8,
	DBPROPFLAGS_DBINIT = 16,
	DBPROPFLAGS_INDEX = 32,
	DBPROPFLAGS_ROWSET = 64,
	DBPROPFLAGS_TABLE = 128,
	DBPROPFLAGS_COLUMNOK = 256,
	DBPROPFLAGS_READ = 512,
	DBPROPFLAGS_WRITE = 1024,
	DBPROPFLAGS_REQUIRED = 2048,
	DBPROPFLAGS_SESSION = 4096,
}


[AllowDuplicates]
public enum DBPROPFLAGSENUM21 : int32
{
	DBPROPFLAGS_TRUSTEE = 8192,
}


[AllowDuplicates]
public enum DBPROPFLAGSENUM25 : int32
{
	DBPROPFLAGS_VIEW = 16384,
}


[AllowDuplicates]
public enum DBPROPFLAGSENUM26 : int32
{
	DBPROPFLAGS_STREAM = 32768,
}


[AllowDuplicates]
public enum DBPROPOPTIONSENUM : int32
{
	DBPROPOPTIONS_REQUIRED = 0,
	DBPROPOPTIONS_SETIFCHEAP = 1,
	DBPROPOPTIONS_OPTIONAL = 1,
}


[AllowDuplicates]
public enum DBPROPSTATUSENUM : int32
{
	DBPROPSTATUS_OK = 0,
	DBPROPSTATUS_NOTSUPPORTED = 1,
	DBPROPSTATUS_BADVALUE = 2,
	DBPROPSTATUS_BADOPTION = 3,
	DBPROPSTATUS_BADCOLUMN = 4,
	DBPROPSTATUS_NOTALLSETTABLE = 5,
	DBPROPSTATUS_NOTSETTABLE = 6,
	DBPROPSTATUS_NOTSET = 7,
	DBPROPSTATUS_CONFLICTING = 8,
}


[AllowDuplicates]
public enum DBPROPSTATUSENUM21 : int32
{
	DBPROPSTATUS_NOTAVAILABLE = 9,
}


[AllowDuplicates]
public enum DBINDEX_COL_ORDERENUM : int32
{
	DBINDEX_COL_ORDER_ASC = 0,
	DBINDEX_COL_ORDER_DESC = 1,
}


[AllowDuplicates]
public enum DBCOLUMNDESCFLAGSENUM : int32
{
	DBCOLUMNDESCFLAGS_TYPENAME = 1,
	DBCOLUMNDESCFLAGS_ITYPEINFO = 2,
	DBCOLUMNDESCFLAGS_PROPERTIES = 4,
	DBCOLUMNDESCFLAGS_CLSID = 8,
	DBCOLUMNDESCFLAGS_COLSIZE = 16,
	DBCOLUMNDESCFLAGS_DBCID = 32,
	DBCOLUMNDESCFLAGS_WTYPE = 64,
	DBCOLUMNDESCFLAGS_PRECISION = 128,
	DBCOLUMNDESCFLAGS_SCALE = 256,
}


[AllowDuplicates]
public enum DBEVENTPHASEENUM : int32
{
	DBEVENTPHASE_OKTODO = 0,
	DBEVENTPHASE_ABOUTTODO = 1,
	DBEVENTPHASE_SYNCHAFTER = 2,
	DBEVENTPHASE_FAILEDTODO = 3,
	DBEVENTPHASE_DIDEVENT = 4,
}


[AllowDuplicates]
public enum DBREASONENUM : int32
{
	DBREASON_ROWSET_FETCHPOSITIONCHANGE = 0,
	DBREASON_ROWSET_RELEASE = 1,
	DBREASON_COLUMN_SET = 2,
	DBREASON_COLUMN_RECALCULATED = 3,
	DBREASON_ROW_ACTIVATE = 4,
	DBREASON_ROW_RELEASE = 5,
	DBREASON_ROW_DELETE = 6,
	DBREASON_ROW_FIRSTCHANGE = 7,
	DBREASON_ROW_INSERT = 8,
	DBREASON_ROW_RESYNCH = 9,
	DBREASON_ROW_UNDOCHANGE = 10,
	DBREASON_ROW_UNDOINSERT = 11,
	DBREASON_ROW_UNDODELETE = 12,
	DBREASON_ROW_UPDATE = 13,
	DBREASON_ROWSET_CHANGED = 14,
}


[AllowDuplicates]
public enum DBREASONENUM15 : int32
{
	DBREASON_ROWPOSITION_CHANGED = 15,
	DBREASON_ROWPOSITION_CHAPTERCHANGED = 16,
	DBREASON_ROWPOSITION_CLEARED = 17,
	DBREASON_ROW_ASYNCHINSERT = 18,
}


[AllowDuplicates]
public enum DBCOMPAREOPSENUM : int32
{
	DBCOMPAREOPS_LT = 0,
	DBCOMPAREOPS_LE = 1,
	DBCOMPAREOPS_EQ = 2,
	DBCOMPAREOPS_GE = 3,
	DBCOMPAREOPS_GT = 4,
	DBCOMPAREOPS_BEGINSWITH = 5,
	DBCOMPAREOPS_CONTAINS = 6,
	DBCOMPAREOPS_NE = 7,
	DBCOMPAREOPS_IGNORE = 8,
	DBCOMPAREOPS_CASESENSITIVE = 4096,
	DBCOMPAREOPS_CASEINSENSITIVE = 8192,
}


[AllowDuplicates]
public enum DBCOMPAREOPSENUM20 : int32
{
	DBCOMPAREOPS_NOTBEGINSWITH = 9,
	DBCOMPAREOPS_NOTCONTAINS = 10,
}


[AllowDuplicates]
public enum DBASYNCHOPENUM : int32
{
	DBASYNCHOP_OPEN = 0,
}


[AllowDuplicates]
public enum DBASYNCHPHASEENUM : int32
{
	DBASYNCHPHASE_INITIALIZATION = 0,
	DBASYNCHPHASE_POPULATION = 1,
	DBASYNCHPHASE_COMPLETE = 2,
	DBASYNCHPHASE_CANCELED = 3,
}


[AllowDuplicates]
public enum DBSORTENUM : int32
{
	DBSORT_ASCENDING = 0,
	DBSORT_DESCENDING = 1,
}


[AllowDuplicates]
public enum DBCOMMANDPERSISTFLAGENUM : int32
{
	DBCOMMANDPERSISTFLAG_NOSAVE = 1,
}


[AllowDuplicates]
public enum DBCOMMANDPERSISTFLAGENUM21 : int32
{
	DBCOMMANDPERSISTFLAG_DEFAULT = 0,
	DBCOMMANDPERSISTFLAG_PERSISTVIEW = 2,
	DBCOMMANDPERSISTFLAG_PERSISTPROCEDURE = 4,
}


[AllowDuplicates]
public enum DBCONSTRAINTTYPEENUM : int32
{
	DBCONSTRAINTTYPE_UNIQUE = 0,
	DBCONSTRAINTTYPE_FOREIGNKEY = 1,
	DBCONSTRAINTTYPE_PRIMARYKEY = 2,
	DBCONSTRAINTTYPE_CHECK = 3,
}


[AllowDuplicates]
public enum DBUPDELRULEENUM : int32
{
	DBUPDELRULE_NOACTION = 0,
	DBUPDELRULE_CASCADE = 1,
	DBUPDELRULE_SETNULL = 2,
	DBUPDELRULE_SETDEFAULT = 3,
}


[AllowDuplicates]
public enum DBMATCHTYPEENUM : int32
{
	DBMATCHTYPE_FULL = 0,
	DBMATCHTYPE_NONE = 1,
	DBMATCHTYPE_PARTIAL = 2,
}


[AllowDuplicates]
public enum DBDEFERRABILITYENUM : int32
{
	DBDEFERRABILITY_DEFERRED = 1,
	DBDEFERRABILITY_DEFERRABLE = 2,
}


[AllowDuplicates]
public enum DBACCESSORFLAGSENUM : int32
{
	DBACCESSOR_INVALID = 0,
	DBACCESSOR_PASSBYREF = 1,
	DBACCESSOR_ROWDATA = 2,
	DBACCESSOR_PARAMETERDATA = 4,
	DBACCESSOR_OPTIMIZED = 8,
	DBACCESSOR_INHERITED = 16,
}


[AllowDuplicates]
public enum DBBINDSTATUSENUM : int32
{
	DBBINDSTATUS_OK = 0,
	DBBINDSTATUS_BADORDINAL = 1,
	DBBINDSTATUS_UNSUPPORTEDCONVERSION = 2,
	DBBINDSTATUS_BADBINDINFO = 3,
	DBBINDSTATUS_BADSTORAGEFLAGS = 4,
	DBBINDSTATUS_NOINTERFACE = 5,
	DBBINDSTATUS_MULTIPLESTORAGE = 6,
}


[AllowDuplicates]
public enum DBCOMPAREENUM : int32
{
	DBCOMPARE_LT = 0,
	DBCOMPARE_EQ = 1,
	DBCOMPARE_GT = 2,
	DBCOMPARE_NE = 3,
	DBCOMPARE_NOTCOMPARABLE = 4,
}


[AllowDuplicates]
public enum DBPOSITIONFLAGSENUM : int32
{
	DBPOSITION_OK = 0,
	DBPOSITION_NOROW = 1,
	DBPOSITION_BOF = 2,
	DBPOSITION_EOF = 3,
}


[AllowDuplicates]
public enum DBPENDINGSTATUSENUM : int32
{
	DBPENDINGSTATUS_NEW = 1,
	DBPENDINGSTATUS_CHANGED = 2,
	DBPENDINGSTATUS_DELETED = 4,
	DBPENDINGSTATUS_UNCHANGED = 8,
	DBPENDINGSTATUS_INVALIDROW = 16,
}


[AllowDuplicates]
public enum DBSEEKENUM : int32
{
	DBSEEK_INVALID = 0,
	DBSEEK_FIRSTEQ = 1,
	DBSEEK_LASTEQ = 2,
	DBSEEK_AFTEREQ = 4,
	DBSEEK_AFTER = 8,
	DBSEEK_BEFOREEQ = 16,
	DBSEEK_BEFORE = 32,
}


[AllowDuplicates]
public enum DBRANGEENUM : int32
{
	DBRANGE_INCLUSIVESTART = 0,
	DBRANGE_INCLUSIVEEND = 0,
	DBRANGE_EXCLUSIVESTART = 1,
	DBRANGE_EXCLUSIVEEND = 2,
	DBRANGE_EXCLUDENULLS = 4,
	DBRANGE_PREFIX = 8,
	DBRANGE_MATCH = 16,
}


[AllowDuplicates]
public enum DBRANGEENUM20 : int32
{
	DBRANGE_MATCH_N_SHIFT = 24,
	DBRANGE_MATCH_N_MASK = 255,
}


[AllowDuplicates]
public enum DBRESULTFLAGENUM : int32
{
	DBRESULTFLAG_DEFAULT = 0,
	DBRESULTFLAG_ROWSET = 1,
	DBRESULTFLAG_ROW = 2,
}


[AllowDuplicates]
public enum DBCONVERTFLAGSENUM : int32
{
	DBCONVERTFLAGS_COLUMN = 0,
	DBCONVERTFLAGS_PARAMETER = 1,
}


[AllowDuplicates]
public enum DBCONVERTFLAGSENUM20 : int32
{
	DBCONVERTFLAGS_ISLONG = 2,
	DBCONVERTFLAGS_ISFIXEDLENGTH = 4,
	DBCONVERTFLAGS_FROMVARIANT = 8,
}


[AllowDuplicates]
public enum DBSOURCETYPEENUM : int32
{
	DBSOURCETYPE_DATASOURCE = 1,
	DBSOURCETYPE_ENUMERATOR = 2,
}


[AllowDuplicates]
public enum DBSOURCETYPEENUM20 : int32
{
	DBSOURCETYPE_DATASOURCE_TDP = 1,
	DBSOURCETYPE_DATASOURCE_MDP = 3,
}


[AllowDuplicates]
public enum DBSOURCETYPEENUM25 : int32
{
	DBSOURCETYPE_BINDER = 4,
}


[AllowDuplicates]
public enum DBLITERALENUM : int32
{
	DBLITERAL_INVALID = 0,
	DBLITERAL_BINARY_LITERAL = 1,
	DBLITERAL_CATALOG_NAME = 2,
	DBLITERAL_CATALOG_SEPARATOR = 3,
	DBLITERAL_CHAR_LITERAL = 4,
	DBLITERAL_COLUMN_ALIAS = 5,
	DBLITERAL_COLUMN_NAME = 6,
	DBLITERAL_CORRELATION_NAME = 7,
	DBLITERAL_CURSOR_NAME = 8,
	DBLITERAL_ESCAPE_PERCENT = 9,
	DBLITERAL_ESCAPE_UNDERSCORE = 10,
	DBLITERAL_INDEX_NAME = 11,
	DBLITERAL_LIKE_PERCENT = 12,
	DBLITERAL_LIKE_UNDERSCORE = 13,
	DBLITERAL_PROCEDURE_NAME = 14,
	DBLITERAL_QUOTE = 15,
	DBLITERAL_SCHEMA_NAME = 16,
	DBLITERAL_TABLE_NAME = 17,
	DBLITERAL_TEXT_COMMAND = 18,
	DBLITERAL_USER_NAME = 19,
	DBLITERAL_VIEW_NAME = 20,
}


[AllowDuplicates]
public enum DBLITERALENUM20 : int32
{
	DBLITERAL_CUBE_NAME = 21,
	DBLITERAL_DIMENSION_NAME = 22,
	DBLITERAL_HIERARCHY_NAME = 23,
	DBLITERAL_LEVEL_NAME = 24,
	DBLITERAL_MEMBER_NAME = 25,
	DBLITERAL_PROPERTY_NAME = 26,
	DBLITERAL_SCHEMA_SEPARATOR = 27,
	DBLITERAL_QUOTE_SUFFIX = 28,
}


[AllowDuplicates]
public enum DBLITERALENUM21 : int32
{
	DBLITERAL_ESCAPE_PERCENT_SUFFIX = 29,
	DBLITERAL_ESCAPE_UNDERSCORE_SUFFIX = 30,
}


[AllowDuplicates]
public enum ACCESS_MASKENUM : int32
{
	PERM_EXCLUSIVE = 512,
	PERM_READDESIGN = 1024,
	PERM_WRITEDESIGN = 2048,
	PERM_WITHGRANT = 4096,
	PERM_REFERENCE = 8192,
	PERM_CREATE = 16384,
	PERM_INSERT = 32768,
	PERM_DELETE = 65536,
	PERM_READCONTROL = 131072,
	PERM_WRITEPERMISSIONS = 262144,
	PERM_WRITEOWNER = 524288,
	PERM_MAXIMUM_ALLOWED = 33554432,
	PERM_ALL = 268435456,
	PERM_EXECUTE = 536870912,
	PERM_READ = -2147483648,
	PERM_UPDATE = 1073741824,
	PERM_DROP = 256,
}


[AllowDuplicates]
public enum DBCOPYFLAGSENUM : int32
{
	DBCOPY_ASYNC = 256,
	DBCOPY_REPLACE_EXISTING = 512,
	DBCOPY_ALLOW_EMULATION = 1024,
	DBCOPY_NON_RECURSIVE = 2048,
	DBCOPY_ATOMIC = 4096,
}


[AllowDuplicates]
public enum DBMOVEFLAGSENUM : int32
{
	DBMOVE_REPLACE_EXISTING = 1,
	DBMOVE_ASYNC = 256,
	DBMOVE_DONT_UPDATE_LINKS = 512,
	DBMOVE_ALLOW_EMULATION = 1024,
	DBMOVE_ATOMIC = 4096,
}


[AllowDuplicates]
public enum DBDELETEFLAGSENUM : int32
{
	DBDELETE_ASYNC = 256,
	DBDELETE_ATOMIC = 4096,
}


[AllowDuplicates]
public enum STRUCTURED_QUERY_SYNTAX : int32
{
	SQS_NO_SYNTAX = 0,
	SQS_ADVANCED_QUERY_SYNTAX = 1,
	SQS_NATURAL_QUERY_SYNTAX = 2,
}


[AllowDuplicates]
public enum STRUCTURED_QUERY_SINGLE_OPTION : int32
{
	SQSO_SCHEMA = 0,
	SQSO_LOCALE_WORD_BREAKING = 1,
	SQSO_WORD_BREAKER = 2,
	SQSO_NATURAL_SYNTAX = 3,
	SQSO_AUTOMATIC_WILDCARD = 4,
	SQSO_TRACE_LEVEL = 5,
	SQSO_LANGUAGE_KEYWORDS = 6,
	SQSO_SYNTAX = 7,
	SQSO_TIME_ZONE = 8,
	SQSO_IMPLICIT_CONNECTOR = 9,
	SQSO_CONNECTOR_CASE = 10,
}


[AllowDuplicates]
public enum STRUCTURED_QUERY_MULTIOPTION : int32
{
	SQMO_VIRTUAL_PROPERTY = 0,
	SQMO_DEFAULT_PROPERTY = 1,
	SQMO_GENERATOR_FOR_TYPE = 2,
	SQMO_MAP_PROPERTY = 3,
}


[AllowDuplicates]
public enum STRUCTURED_QUERY_PARSE_ERROR : int32
{
	SQPE_NONE = 0,
	SQPE_EXTRA_OPENING_PARENTHESIS = 1,
	SQPE_EXTRA_CLOSING_PARENTHESIS = 2,
	SQPE_IGNORED_MODIFIER = 3,
	SQPE_IGNORED_CONNECTOR = 4,
	SQPE_IGNORED_KEYWORD = 5,
	SQPE_UNHANDLED = 6,
}


[AllowDuplicates]
public enum STRUCTURED_QUERY_RESOLVE_OPTION : uint32
{
	SQRO_DEFAULT = 0,
	SQRO_DONT_RESOLVE_DATETIME = 1,
	SQRO_ALWAYS_ONE_INTERVAL = 2,
	SQRO_DONT_SIMPLIFY_CONDITION_TREES = 4,
	SQRO_DONT_MAP_RELATIONS = 8,
	SQRO_DONT_RESOLVE_RANGES = 16,
	SQRO_DONT_REMOVE_UNRESTRICTED_KEYWORDS = 32,
	SQRO_DONT_SPLIT_WORDS = 64,
	SQRO_IGNORE_PHRASE_ORDER = 128,
	SQRO_ADD_VALUE_TYPE_FOR_PLAIN_VALUES = 256,
	SQRO_ADD_ROBUST_ITEM_NAME = 512,
}


[AllowDuplicates]
public enum CASE_REQUIREMENT : int32
{
	CASE_REQUIREMENT_ANY = 0,
	CASE_REQUIREMENT_UPPER_IF_AQS = 1,
}


[AllowDuplicates]
public enum INTERVAL_LIMIT_KIND : int32
{
	ILK_EXPLICIT_INCLUDED = 0,
	ILK_EXPLICIT_EXCLUDED = 1,
	ILK_NEGATIVE_INFINITY = 2,
	ILK_POSITIVE_INFINITY = 3,
}


[AllowDuplicates]
public enum QUERY_PARSER_MANAGER_OPTION : int32
{
	QPMO_SCHEMA_BINARY_NAME = 0,
	QPMO_PRELOCALIZED_SCHEMA_BINARY_PATH = 1,
	QPMO_UNLOCALIZED_SCHEMA_BINARY_PATH = 2,
	QPMO_LOCALIZED_SCHEMA_BINARY_PATH = 3,
	QPMO_APPEND_LCID_TO_LOCALIZED_PATH = 4,
	QPMO_LOCALIZER_SUPPORT = 5,
}


[AllowDuplicates]
public enum CONDITION_CREATION_OPTIONS : uint32
{
	CONDITION_CREATION_DEFAULT = 0,
	CONDITION_CREATION_NONE = 0,
	CONDITION_CREATION_SIMPLIFY = 1,
	CONDITION_CREATION_VECTOR_AND = 2,
	CONDITION_CREATION_VECTOR_OR = 4,
	CONDITION_CREATION_VECTOR_LEAF = 8,
	CONDITION_CREATION_USE_CONTENT_LOCALE = 16,
}


[AllowDuplicates]
public enum NAMED_ENTITY_CERTAINTY : int32
{
	NEC_LOW = 0,
	NEC_MEDIUM = 1,
	NEC_HIGH = 2,
}


[AllowDuplicates]
public enum PROXY_ACCESS : int32
{
	PROXY_ACCESS_PRECONFIG = 0,
	PROXY_ACCESS_DIRECT = 1,
	PROXY_ACCESS_PROXY = 2,
}


[AllowDuplicates]
public enum AUTH_TYPE : int32
{
	eAUTH_TYPE_ANONYMOUS = 0,
	eAUTH_TYPE_NTLM = 1,
	eAUTH_TYPE_BASIC = 2,
}


[AllowDuplicates]
public enum FOLLOW_FLAGS : int32
{
	FF_INDEXCOMPLEXURLS = 1,
	FF_SUPPRESSINDEXING = 2,
}


[AllowDuplicates]
public enum CLUSION_REASON : int32
{
	CLUSIONREASON_UNKNOWNSCOPE = 0,
	CLUSIONREASON_DEFAULT = 1,
	CLUSIONREASON_USER = 2,
	CLUSIONREASON_GROUPPOLICY = 3,
}


[AllowDuplicates]
public enum SEARCH_KIND_OF_CHANGE : int32
{
	SEARCH_CHANGE_ADD = 0,
	SEARCH_CHANGE_DELETE = 1,
	SEARCH_CHANGE_MODIFY = 2,
	SEARCH_CHANGE_MOVE_RENAME = 3,
	SEARCH_CHANGE_SEMANTICS_DIRECTORY = 262144,
	SEARCH_CHANGE_SEMANTICS_SHALLOW = 524288,
	SEARCH_CHANGE_SEMANTICS_UPDATE_SECURITY = 4194304,
}


[AllowDuplicates]
public enum SEARCH_NOTIFICATION_PRIORITY : int32
{
	SEARCH_NORMAL_PRIORITY = 0,
	SEARCH_HIGH_PRIORITY = 1,
}


[AllowDuplicates]
public enum SEARCH_INDEXING_PHASE : int32
{
	SEARCH_INDEXING_PHASE_GATHERER = 0,
	SEARCH_INDEXING_PHASE_QUERYABLE = 1,
	SEARCH_INDEXING_PHASE_PERSISTED = 2,
}


[AllowDuplicates]
public enum CatalogStatus : int32
{
	CATALOG_STATUS_IDLE = 0,
	CATALOG_STATUS_PAUSED = 1,
	CATALOG_STATUS_RECOVERING = 2,
	CATALOG_STATUS_FULL_CRAWL = 3,
	CATALOG_STATUS_INCREMENTAL_CRAWL = 4,
	CATALOG_STATUS_PROCESSING_NOTIFICATIONS = 5,
	CATALOG_STATUS_SHUTTING_DOWN = 6,
}


[AllowDuplicates]
public enum CatalogPausedReason : int32
{
	CATALOG_PAUSED_REASON_NONE = 0,
	CATALOG_PAUSED_REASON_HIGH_IO = 1,
	CATALOG_PAUSED_REASON_HIGH_CPU = 2,
	CATALOG_PAUSED_REASON_HIGH_NTF_RATE = 3,
	CATALOG_PAUSED_REASON_LOW_BATTERY = 4,
	CATALOG_PAUSED_REASON_LOW_MEMORY = 5,
	CATALOG_PAUSED_REASON_LOW_DISK = 6,
	CATALOG_PAUSED_REASON_DELAYED_RECOVERY = 7,
	CATALOG_PAUSED_REASON_USER_ACTIVE = 8,
	CATALOG_PAUSED_REASON_EXTERNAL = 9,
	CATALOG_PAUSED_REASON_UPGRADING = 10,
}


[AllowDuplicates]
public enum PRIORITIZE_FLAGS : int32
{
	PRIORITIZE_FLAG_RETRYFAILEDITEMS = 1,
	PRIORITIZE_FLAG_IGNOREFAILURECOUNT = 2,
}


[AllowDuplicates]
public enum SEARCH_TERM_EXPANSION : int32
{
	SEARCH_TERM_NO_EXPANSION = 0,
	SEARCH_TERM_PREFIX_ALL = 1,
	SEARCH_TERM_STEM_ALL = 2,
}


[AllowDuplicates]
public enum SEARCH_QUERY_SYNTAX : int32
{
	SEARCH_NO_QUERY_SYNTAX = 0,
	SEARCH_ADVANCED_QUERY_SYNTAX = 1,
	SEARCH_NATURAL_QUERY_SYNTAX = 2,
}


[AllowDuplicates]
public enum PRIORITY_LEVEL : int32
{
	PRIORITY_LEVEL_FOREGROUND = 0,
	PRIORITY_LEVEL_HIGH = 1,
	PRIORITY_LEVEL_LOW = 2,
	PRIORITY_LEVEL_DEFAULT = 3,
}


[AllowDuplicates]
public enum ROWSETEVENT_ITEMSTATE : int32
{
	ROWSETEVENT_ITEMSTATE_NOTINROWSET = 0,
	ROWSETEVENT_ITEMSTATE_INROWSET = 1,
	ROWSETEVENT_ITEMSTATE_UNKNOWN = 2,
}


[AllowDuplicates]
public enum ROWSETEVENT_TYPE : int32
{
	ROWSETEVENT_TYPE_DATAEXPIRED = 0,
	ROWSETEVENT_TYPE_FOREGROUNDLOST = 1,
	ROWSETEVENT_TYPE_SCOPESTATISTICS = 2,
}


[AllowDuplicates]
public enum SUBSCRIPTIONTYPE : int32
{
	SUBSTYPE_URL = 0,
	SUBSTYPE_CHANNEL = 1,
	SUBSTYPE_DESKTOPURL = 2,
	SUBSTYPE_EXTERNAL = 3,
	SUBSTYPE_DESKTOPCHANNEL = 4,
}


[AllowDuplicates]
public enum SUBSCRIPTIONINFOFLAGS : int32
{
	SUBSINFO_SCHEDULE = 1,
	SUBSINFO_RECURSE = 2,
	SUBSINFO_WEBCRAWL = 4,
	SUBSINFO_MAILNOT = 8,
	SUBSINFO_MAXSIZEKB = 16,
	SUBSINFO_USER = 32,
	SUBSINFO_PASSWORD = 64,
	SUBSINFO_TASKFLAGS = 256,
	SUBSINFO_GLEAM = 512,
	SUBSINFO_CHANGESONLY = 1024,
	SUBSINFO_CHANNELFLAGS = 2048,
	SUBSINFO_FRIENDLYNAME = 8192,
	SUBSINFO_NEEDPASSWORD = 16384,
	SUBSINFO_TYPE = 32768,
}


[AllowDuplicates]
public enum CREATESUBSCRIPTIONFLAGS : int32
{
	CREATESUBS_ADDTOFAVORITES = 1,
	CREATESUBS_FROMFAVORITES = 2,
	CREATESUBS_NOUI = 4,
	CREATESUBS_NOSAVE = 8,
	CREATESUBS_SOFTWAREUPDATE = 16,
}


[AllowDuplicates]
public enum SUBSCRIPTIONSCHEDULE : int32
{
	SUBSSCHED_AUTO = 0,
	SUBSSCHED_DAILY = 1,
	SUBSSCHED_WEEKLY = 2,
	SUBSSCHED_CUSTOM = 3,
	SUBSSCHED_MANUAL = 4,
}


[AllowDuplicates]
public enum DELIVERY_AGENT_FLAGS : int32
{
	DELIVERY_AGENT_FLAG_NO_BROADCAST = 4,
	DELIVERY_AGENT_FLAG_NO_RESTRICTIONS = 8,
	DELIVERY_AGENT_FLAG_SILENT_DIAL = 16,
}


[AllowDuplicates]
public enum WEBCRAWL_RECURSEFLAGS : int32
{
	WEBCRAWL_DONT_MAKE_STICKY = 1,
	WEBCRAWL_GET_IMAGES = 2,
	WEBCRAWL_GET_VIDEOS = 4,
	WEBCRAWL_GET_BGSOUNDS = 8,
	WEBCRAWL_GET_CONTROLS = 16,
	WEBCRAWL_LINKS_ELSEWHERE = 32,
	WEBCRAWL_IGNORE_ROBOTSTXT = 128,
	WEBCRAWL_ONLY_LINKS_TO_HTML = 256,
}


[AllowDuplicates]
public enum CHANNEL_AGENT_FLAGS : int32
{
	CHANNEL_AGENT_DYNAMIC_SCHEDULE = 1,
	CHANNEL_AGENT_PRECACHE_SOME = 2,
	CHANNEL_AGENT_PRECACHE_ALL = 4,
	CHANNEL_AGENT_PRECACHE_SCRNSAVER = 8,
}


[AllowDuplicates]
public enum DBDATACONVERTENUM : int32
{
	DBDATACONVERT_DEFAULT = 0,
	DBDATACONVERT_SETDATABEHAVIOR = 1,
	DBDATACONVERT_LENGTHFROMNTS = 2,
	DBDATACONVERT_DSTISFIXEDLENGTH = 4,
	DBDATACONVERT_DECIMALSCALE = 8,
}


[AllowDuplicates]
public enum DCINFOTYPEENUM : int32
{
	DCINFOTYPE_VERSION = 1,
}


[AllowDuplicates]
public enum OSPFORMAT : int32
{
	OSPFORMAT_RAW = 0,
	OSPFORMAT_DEFAULT = 0,
	OSPFORMAT_FORMATTED = 1,
	OSPFORMAT_HTML = 2,
}


[AllowDuplicates]
public enum OSPRW : int32
{
	OSPRW_DEFAULT = 1,
	OSPRW_READONLY = 0,
	OSPRW_READWRITE = 1,
	OSPRW_MIXED = 2,
}


[AllowDuplicates]
public enum OSPFIND : int32
{
	OSPFIND_DEFAULT = 0,
	OSPFIND_UP = 1,
	OSPFIND_CASESENSITIVE = 2,
	OSPFIND_UPCASESENSITIVE = 3,
}


[AllowDuplicates]
public enum OSPCOMP : int32
{
	OSPCOMP_EQ = 1,
	OSPCOMP_DEFAULT = 1,
	OSPCOMP_LT = 2,
	OSPCOMP_LE = 3,
	OSPCOMP_GE = 4,
	OSPCOMP_GT = 5,
	OSPCOMP_NE = 6,
}


[AllowDuplicates]
public enum OSPXFER : int32
{
	OSPXFER_COMPLETE = 0,
	OSPXFER_ABORT = 1,
	OSPXFER_ERROR = 2,
}


[AllowDuplicates]
public enum EBindInfoOptions : int32
{
	BIO_BINDER = 1,
}


[AllowDuplicates]
public enum DBPROMPTOPTIONSENUM : int32
{
	DBPROMPTOPTIONS_NONE = 0,
	DBPROMPTOPTIONS_WIZARDSHEET = 1,
	DBPROMPTOPTIONS_PROPERTYSHEET = 2,
	DBPROMPTOPTIONS_BROWSEONLY = 8,
	DBPROMPTOPTIONS_DISABLE_PROVIDER_SELECTION = 16,
	DBPROMPTOPTIONS_DISABLESAVEPASSWORD = 32,
}


[AllowDuplicates]
public enum KAGREQDIAGFLAGSENUM : int32
{
	KAGREQDIAGFLAGS_HEADER = 1,
	KAGREQDIAGFLAGS_RECORD = 2,
}


[AllowDuplicates]
public enum MSDSDBINITPROPENUM : int32
{
	DBPROP_MSDS_DBINIT_DATAPROVIDER = 2,
}


[AllowDuplicates]
public enum MSDSSESSIONPROPENUM : int32
{
	DBPROP_MSDS_SESS_UNIQUENAMES = 2,
}


[AllowDuplicates]
public enum SQLINTERVAL : int32
{
	SQL_IS_YEAR = 1,
	SQL_IS_MONTH = 2,
	SQL_IS_DAY = 3,
	SQL_IS_HOUR = 4,
	SQL_IS_MINUTE = 5,
	SQL_IS_SECOND = 6,
	SQL_IS_YEAR_TO_MONTH = 7,
	SQL_IS_DAY_TO_HOUR = 8,
	SQL_IS_DAY_TO_MINUTE = 9,
	SQL_IS_DAY_TO_SECOND = 10,
	SQL_IS_HOUR_TO_MINUTE = 11,
	SQL_IS_HOUR_TO_SECOND = 12,
	SQL_IS_MINUTE_TO_SECOND = 13,
}


[AllowDuplicates]
public enum DBPROPENUM25_DEPRECATED : int32
{
	DBPROP_ICommandCost = 141,
	DBPROP_ICommandTree = 142,
	DBPROP_ICommandValidate = 143,
	DBPROP_IDBSchemaCommand = 144,
	DBPROP_IProvideMoniker = 125,
	DBPROP_IQuery = 146,
	DBPROP_IReadData = 147,
	DBPROP_IRowsetAsynch = 148,
	DBPROP_IRowsetCopyRows = 149,
	DBPROP_IRowsetKeys = 151,
	DBPROP_IRowsetNewRowAfter = 152,
	DBPROP_IRowsetNextRowset = 153,
	DBPROP_IRowsetWatchAll = 155,
	DBPROP_IRowsetWatchNotify = 156,
	DBPROP_IRowsetWatchRegion = 157,
	DBPROP_IRowsetWithParameters = 158,
}


[AllowDuplicates]
public enum DBREASONENUM25 : int32
{
	DBREASON_ROWSET_ROWSADDED = 19,
	DBREASON_ROWSET_POPULATIONCOMPLETE = 20,
	DBREASON_ROWSET_POPULATIONSTOPPED = 21,
}


[AllowDuplicates]
public enum DBWATCHNOTIFYENUM : int32
{
	DBWATCHNOTIFY_ROWSCHANGED = 1,
	DBWATCHNOTIFY_QUERYDONE = 2,
	DBWATCHNOTIFY_QUERYREEXECUTED = 3,
}


[AllowDuplicates]
public enum DBWATCHMODEENUM : int32
{
	DBWATCHMODE_ALL = 1,
	DBWATCHMODE_EXTEND = 2,
	DBWATCHMODE_MOVE = 4,
	DBWATCHMODE_COUNT = 8,
}


[AllowDuplicates]
public enum DBROWCHANGEKINDENUM : int32
{
	DBROWCHANGEKIND_INSERT = 0,
	DBROWCHANGEKIND_DELETE = 1,
	DBROWCHANGEKIND_UPDATE = 2,
	DBROWCHANGEKIND_COUNT = 3,
}


[AllowDuplicates]
public enum DBRESOURCEKINDENUM : int32
{
	DBRESOURCE_INVALID = 0,
	DBRESOURCE_TOTAL = 1,
	DBRESOURCE_CPU = 2,
	DBRESOURCE_MEMORY = 3,
	DBRESOURCE_DISK = 4,
	DBRESOURCE_NETWORK = 5,
	DBRESOURCE_RESPONSE = 6,
	DBRESOURCE_ROWS = 7,
	DBRESOURCE_OTHER = 8,
}


[AllowDuplicates]
public enum DBCOSTUNITENUM : int32
{
	DBUNIT_INVALID = 0,
	DBUNIT_WEIGHT = 1,
	DBUNIT_PERCENT = 2,
	DBUNIT_MAXIMUM = 4,
	DBUNIT_MINIMUM = 8,
	DBUNIT_MICRO_SECOND = 16,
	DBUNIT_MILLI_SECOND = 32,
	DBUNIT_SECOND = 64,
	DBUNIT_MINUTE = 128,
	DBUNIT_HOUR = 256,
	DBUNIT_BYTE = 512,
	DBUNIT_KILO_BYTE = 1024,
	DBUNIT_MEGA_BYTE = 2048,
	DBUNIT_GIGA_BYTE = 4096,
	DBUNIT_NUM_MSGS = 8192,
	DBUNIT_NUM_LOCKS = 16384,
	DBUNIT_NUM_ROWS = 32768,
	DBUNIT_OTHER = 65536,
}


[AllowDuplicates]
public enum DBEXECLIMITSENUM : int32
{
	DBEXECLIMITS_ABORT = 1,
	DBEXECLIMITS_STOP = 2,
	DBEXECLIMITS_SUSPEND = 3,
}


[AllowDuplicates]
public enum SQLVARENUM : int32
{
	VT_SS_EMPTY = 0,
	VT_SS_NULL = 1,
	VT_SS_UI1 = 17,
	VT_SS_I2 = 2,
	VT_SS_I4 = 3,
	VT_SS_I8 = 20,
	VT_SS_R4 = 4,
	VT_SS_R8 = 5,
	VT_SS_MONEY = 6,
	VT_SS_SMALLMONEY = 200,
	VT_SS_WSTRING = 201,
	VT_SS_WVARSTRING = 202,
	VT_SS_STRING = 203,
	VT_SS_VARSTRING = 204,
	VT_SS_BIT = 11,
	VT_SS_GUID = 72,
	VT_SS_NUMERIC = 131,
	VT_SS_DECIMAL = 205,
	VT_SS_DATETIME = 135,
	VT_SS_SMALLDATETIME = 206,
	VT_SS_BINARY = 207,
	VT_SS_VARBINARY = 208,
	VT_SS_UNKNOWN = 209,
}


[AllowDuplicates]
public enum LOCKMODEENUM : int32
{
	LOCKMODE_INVALID = 0,
	LOCKMODE_EXCLUSIVE = 1,
	LOCKMODE_SHARED = 2,
}

#endregion

#region Function Pointers
public function HRESULT PFNFILLTEXTBUFFER(TEXT_SOURCE* pTextSource);

public function int16 SQL_ASYNC_NOTIFICATION_CALLBACK(void* pContext, BOOL fLast);

#endregion

#region Structs
[CRepr]
public struct IRowsetExactScroll
{
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBVECTOR
{
	public uint size;
	public void* ptr;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBTIMESTAMP
{
	public int16 year;
	public uint16 month;
	public uint16 day;
	public uint16 hour;
	public uint16 minute;
	public uint16 second;
	public uint32 fraction;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SEC_OBJECT_ELEMENT
{
	public Guid guidObjectType;
	public DBID ObjectID;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SEC_OBJECT
{
	public uint32 cObjects;
	public SEC_OBJECT_ELEMENT* prgObjects;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBIMPLICITSESSION
{
	public IUnknown* pUnkOuter;
	public Guid* piid;
	public IUnknown* pSession;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBOBJECT
{
	public uint32 dwFlags;
	public Guid iid;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBBINDEXT
{
	public uint8* pExtension;
	public uint ulExtension;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBBINDING
{
	public uint iOrdinal;
	public uint obValue;
	public uint obLength;
	public uint obStatus;
	public ITypeInfo* pTypeInfo;
	public DBOBJECT* pObject;
	public DBBINDEXT* pBindExt;
	public uint32 dwPart;
	public uint32 dwMemOwner;
	public uint32 eParamIO;
	public uint cbMaxLen;
	public uint32 dwFlags;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBFAILUREINFO
{
	public uint hRow;
	public uint iColumn;
	public HRESULT failure;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBCOLUMNINFO
{
	public PWSTR pwszName;
	public ITypeInfo* pTypeInfo;
	public uint iOrdinal;
	public uint32 dwFlags;
	public uint ulColumnSize;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
	public DBID columnid;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPARAMS
{
	public void* pData;
	public uint cParamSets;
	public HACCESSOR hAccessor;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPARAMINFO
{
	public uint32 dwFlags;
	public uint iOrdinal;
	public PWSTR pwszName;
	public ITypeInfo* pTypeInfo;
	public uint ulParamSize;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPROPIDSET
{
	public uint32* rgPropertyIDs;
	public uint32 cPropertyIDs;
	public Guid guidPropertySet;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPROPINFO
{
	public PWSTR pwszDescription;
	public uint32 dwPropertyID;
	public uint32 dwFlags;
	public VARENUM vtType;
	public VARIANT vValues;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPROPINFOSET
{
	public DBPROPINFO* rgPropertyInfos;
	public uint32 cPropertyInfos;
	public Guid guidPropertySet;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPROP
{
	public uint32 dwPropertyID;
	public uint32 dwOptions;
	public uint32 dwStatus;
	public DBID colid;
	public VARIANT vValue;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPROPSET
{
	public DBPROP* rgProperties;
	public uint32 cProperties;
	public Guid guidPropertySet;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBINDEXCOLUMNDESC
{
	public DBID* pColumnID;
	public uint32 eIndexColOrder;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBCOLUMNDESC
{
	public PWSTR pwszTypeName;
	public ITypeInfo* pTypeInfo;
	public DBPROPSET* rgPropertySets;
	public Guid* pclsid;
	public uint32 cPropertySets;
	public uint ulColumnSize;
	public DBID dbcid;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBCOLUMNACCESS
{
	public void* pData;
	public DBID columnid;
	public uint cbDataLen;
	public uint32 dwStatus;
	public uint cbMaxLen;
	public uint dwReserved;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBCONSTRAINTDESC
{
	public DBID* pConstraintID;
	public uint32 ConstraintType;
	public uint cColumns;
	public DBID* rgColumnList;
	public DBID* pReferencedTableID;
	public uint cForeignKeyColumns;
	public DBID* rgForeignKeyColumnList;
	public PWSTR pwszConstraintText;
	public uint32 UpdateRule;
	public uint32 DeleteRule;
	public uint32 MatchType;
	public uint32 Deferrability;
	public uint cReserved;
	public DBPROPSET* rgReserved;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct MDAXISINFO
{
	public uint cbSize;
	public uint iAxis;
	public uint cDimensions;
	public uint cCoordinates;
	public uint* rgcColumns;
	public PWSTR* rgpwszDimensionNames;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct RMTPACK
{
	public ISequentialStream* pISeqStream;
	public uint32 cbData;
	public uint32 cBSTR;
	public BSTR* rgBSTR;
	public uint32 cVARIANT;
	public VARIANT* rgVARIANT;
	public uint32 cIDISPATCH;
	public IDispatch** rgIDISPATCH;
	public uint32 cIUNKNOWN;
	public IUnknown** rgIUNKNOWN;
	public uint32 cPROPVARIANT;
	public PROPVARIANT* rgPROPVARIANT;
	public uint32 cArray;
	public VARIANT* rgArray;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBPARAMBINDINFO
{
	public PWSTR pwszDataSourceType;
	public PWSTR pwszName;
	public uint ulParamSize;
	public uint32 dwFlags;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBLITERALINFO
{
	public PWSTR pwszLiteralValue;
	public PWSTR pwszInvalidChars;
	public PWSTR pwszInvalidStartingChars;
	public uint32 lt;
	public BOOL fSupported;
	public uint32 cchMaxLen;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct ERRORINFO
{
	public HRESULT hrError;
	public uint32 dwMinor;
	public Guid clsid;
	public Guid iid;
	public int32 dispid;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBROWWATCHCHANGE
{
	public uint hRegion;
	public uint32 eChangeKind;
	public uint hRow;
	public uint iRow;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBCOST
{
	public uint32 eKind;
	public uint32 dwUnits;
	public int32 lValue;
}
#endif

[CRepr]
public struct TEXT_SOURCE
{
	public PFNFILLTEXTBUFFER pfnFillTextBuffer;
	public PWSTR awcBuffer;
	public uint32 iEnd;
	public uint32 iCur;
}

[CRepr]
public struct FILTERED_DATA_SOURCES
{
	public PWSTR pwcsExtension;
	public PWSTR pwcsMime;
	public Guid* pClsid;
	public PWSTR pwcsOverride;
}

[CRepr]
public struct DB_NUMERIC
{
	public uint8 precision;
	public uint8 scale;
	public uint8 sign;
	public uint8[16] val;
}

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBVECTOR
{
	public uint size;
	public void* ptr;
}
#endif

[CRepr]
public struct DBDATE
{
	public int16 year;
	public uint16 month;
	public uint16 day;
}

[CRepr]
public struct DBTIME
{
	public uint16 hour;
	public uint16 minute;
	public uint16 second;
}

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBTIMESTAMP
{
	public int16 year;
	public uint16 month;
	public uint16 day;
	public uint16 hour;
	public uint16 minute;
	public uint16 second;
	public uint32 fraction;
}
#endif

[CRepr]
public struct DB_VARNUMERIC
{
	public uint8 precision;
	public int8 scale;
	public uint8 sign;
	public uint8* val mut => &val_impl;
	private uint8[ANYSIZE_ARRAY] val_impl;
}

#if BF_32_BIT
[CRepr, Packed(2)]
public struct SEC_OBJECT_ELEMENT
{
	public Guid guidObjectType;
	public DBID ObjectID;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct SEC_OBJECT
{
	public uint32 cObjects;
	public SEC_OBJECT_ELEMENT* prgObjects;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBIMPLICITSESSION
{
	public IUnknown* pUnkOuter;
	public Guid* piid;
	public IUnknown* pSession;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBOBJECT
{
	public uint32 dwFlags;
	public Guid iid;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBBINDEXT
{
	public uint8* pExtension;
	public uint ulExtension;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBBINDING
{
	public uint iOrdinal;
	public uint obValue;
	public uint obLength;
	public uint obStatus;
	public ITypeInfo* pTypeInfo;
	public DBOBJECT* pObject;
	public DBBINDEXT* pBindExt;
	public uint32 dwPart;
	public uint32 dwMemOwner;
	public uint32 eParamIO;
	public uint cbMaxLen;
	public uint32 dwFlags;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBFAILUREINFO
{
	public uint hRow;
	public uint iColumn;
	public HRESULT failure;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBCOLUMNINFO
{
	public PWSTR pwszName;
	public ITypeInfo* pTypeInfo;
	public uint iOrdinal;
	public uint32 dwFlags;
	public uint ulColumnSize;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
	public DBID columnid;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPARAMS
{
	public void* pData;
	public uint cParamSets;
	public HACCESSOR hAccessor;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPARAMINFO
{
	public uint32 dwFlags;
	public uint iOrdinal;
	public PWSTR pwszName;
	public ITypeInfo* pTypeInfo;
	public uint ulParamSize;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPROPIDSET
{
	public uint32* rgPropertyIDs;
	public uint32 cPropertyIDs;
	public Guid guidPropertySet;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPROPINFO
{
	public PWSTR pwszDescription;
	public uint32 dwPropertyID;
	public uint32 dwFlags;
	public VARENUM vtType;
	public VARIANT vValues;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPROPINFOSET
{
	public DBPROPINFO* rgPropertyInfos;
	public uint32 cPropertyInfos;
	public Guid guidPropertySet;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPROP
{
	public uint32 dwPropertyID;
	public uint32 dwOptions;
	public uint32 dwStatus;
	public DBID colid;
	public VARIANT vValue;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPROPSET
{
	public DBPROP* rgProperties;
	public uint32 cProperties;
	public Guid guidPropertySet;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBINDEXCOLUMNDESC
{
	public DBID* pColumnID;
	public uint32 eIndexColOrder;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBCOLUMNDESC
{
	public PWSTR pwszTypeName;
	public ITypeInfo* pTypeInfo;
	public DBPROPSET* rgPropertySets;
	public Guid* pclsid;
	public uint32 cPropertySets;
	public uint ulColumnSize;
	public DBID dbcid;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBCOLUMNACCESS
{
	public void* pData;
	public DBID columnid;
	public uint cbDataLen;
	public uint32 dwStatus;
	public uint cbMaxLen;
	public uint dwReserved;
	public uint16 wType;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBCONSTRAINTDESC
{
	public DBID* pConstraintID;
	public uint32 ConstraintType;
	public uint cColumns;
	public DBID* rgColumnList;
	public DBID* pReferencedTableID;
	public uint cForeignKeyColumns;
	public DBID* rgForeignKeyColumnList;
	public PWSTR pwszConstraintText;
	public uint32 UpdateRule;
	public uint32 DeleteRule;
	public uint32 MatchType;
	public uint32 Deferrability;
	public uint cReserved;
	public DBPROPSET* rgReserved;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct MDAXISINFO
{
	public uint cbSize;
	public uint iAxis;
	public uint cDimensions;
	public uint cCoordinates;
	public uint* rgcColumns;
	public PWSTR* rgpwszDimensionNames;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct RMTPACK
{
	public ISequentialStream* pISeqStream;
	public uint32 cbData;
	public uint32 cBSTR;
	public BSTR* rgBSTR;
	public uint32 cVARIANT;
	public VARIANT* rgVARIANT;
	public uint32 cIDISPATCH;
	public IDispatch** rgIDISPATCH;
	public uint32 cIUNKNOWN;
	public IUnknown** rgIUNKNOWN;
	public uint32 cPROPVARIANT;
	public PROPVARIANT* rgPROPVARIANT;
	public uint32 cArray;
	public VARIANT* rgArray;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBPARAMBINDINFO
{
	public PWSTR pwszDataSourceType;
	public PWSTR pwszName;
	public uint ulParamSize;
	public uint32 dwFlags;
	public uint8 bPrecision;
	public uint8 bScale;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBLITERALINFO
{
	public PWSTR pwszLiteralValue;
	public PWSTR pwszInvalidChars;
	public PWSTR pwszInvalidStartingChars;
	public uint32 lt;
	public BOOL fSupported;
	public uint32 cchMaxLen;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct ERRORINFO
{
	public HRESULT hrError;
	public uint32 dwMinor;
	public Guid clsid;
	public Guid iid;
	public int32 dispid;
}
#endif

[CRepr]
public struct HITRANGE
{
	public uint32 iPosition;
	public uint32 cLength;
}

[CRepr]
public struct TIMEOUT_INFO
{
	public uint32 dwSize;
	public uint32 dwConnectTimeout;
	public uint32 dwDataTimeout;
}

[CRepr]
public struct PROXY_INFO
{
	public uint32 dwSize;
	public PWSTR pcwszUserAgent;
	public PROXY_ACCESS paUseProxy;
	public BOOL fLocalBypass;
	public uint32 dwPortNumber;
	public PWSTR pcwszProxyName;
	public PWSTR pcwszBypassList;
}

[CRepr]
public struct AUTHENTICATION_INFO
{
	public uint32 dwSize;
	public AUTH_TYPE atAuthenticationType;
	public PWSTR pcwszUser;
	public PWSTR pcwszPassword;
}

[CRepr]
public struct INCREMENTAL_ACCESS_INFO
{
	public uint32 dwSize;
	public FILETIME ftLastModifiedTime;
}

[CRepr]
public struct ITEM_INFO
{
	public uint32 dwSize;
	public PWSTR pcwszFromEMail;
	public PWSTR pcwszApplicationName;
	public PWSTR pcwszCatalogName;
	public PWSTR pcwszContentClass;
}

[CRepr]
public struct SEARCH_ITEM_CHANGE
{
	public SEARCH_KIND_OF_CHANGE Change;
	public SEARCH_NOTIFICATION_PRIORITY Priority;
	public BLOB* pUserData;
	public PWSTR lpwszURL;
	public PWSTR lpwszOldURL;
}

[CRepr]
public struct SEARCH_ITEM_PERSISTENT_CHANGE
{
	public SEARCH_KIND_OF_CHANGE Change;
	public PWSTR URL;
	public PWSTR OldURL;
	public SEARCH_NOTIFICATION_PRIORITY Priority;
}

[CRepr]
public struct SEARCH_ITEM_INDEXING_STATUS
{
	public uint32 dwDocID;
	public HRESULT hrIndexingStatus;
}

[CRepr]
public struct SEARCH_COLUMN_PROPERTIES
{
	public PROPVARIANT Value;
	public uint32 lcid;
}

[CRepr]
public struct ITEMPROP
{
	public VARIANT variantValue;
	public PWSTR pwszName;
}

[CRepr]
public struct SUBSCRIPTIONITEMINFO
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32 dwPriority;
	public Guid ScheduleGroup;
	public Guid clsidAgent;
}

[CRepr]
public struct SUBSCRIPTIONINFO
{
	public uint32 cbSize;
	public uint32 fUpdateFlags;
	public SUBSCRIPTIONSCHEDULE schedule;
	public Guid customGroupCookie;
	public void* pTrigger;
	public uint32 dwRecurseLevels;
	public uint32 fWebcrawlerFlags;
	public BOOL bMailNotification;
	public BOOL bGleam;
	public BOOL bChangesOnly;
	public BOOL bNeedPassword;
	public uint32 fChannelFlags;
	public BSTR bstrUserName;
	public BSTR bstrPassword;
	public BSTR bstrFriendlyName;
	public uint32 dwMaxSizeKB;
	public SUBSCRIPTIONTYPE subType;
	public uint32 fTaskFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct DCINFO
{
	public uint32 eInfoType;
	public VARIANT vData;
}

[CRepr]
public struct KAGREQDIAG
{
	public uint32 ulDiagFlags;
	public VARENUM vt;
	public int16 sDiagField;
}

[CRepr]
public struct KAGGETDIAG
{
	public uint32 ulSize;
	public VARIANT vDiagInfo;
	public int16 sDiagField;
}

[CRepr]
public struct DATE_STRUCT
{
	public int16 year;
	public uint16 month;
	public uint16 day;
}

[CRepr]
public struct TIME_STRUCT
{
	public uint16 hour;
	public uint16 minute;
	public uint16 second;
}

[CRepr]
public struct TIMESTAMP_STRUCT
{
	public int16 year;
	public uint16 month;
	public uint16 day;
	public uint16 hour;
	public uint16 minute;
	public uint16 second;
	public uint32 fraction;
}

[CRepr]
public struct SQL_YEAR_MONTH_STRUCT
{
	public uint32 year;
	public uint32 month;
}

[CRepr]
public struct SQL_DAY_SECOND_STRUCT
{
	public uint32 day;
	public uint32 hour;
	public uint32 minute;
	public uint32 second;
	public uint32 fraction;
}

[CRepr]
public struct SQL_INTERVAL_STRUCT
{
	[CRepr, Union]
	public struct _intval_e__Union
	{
		public SQL_YEAR_MONTH_STRUCT year_month;
		public SQL_DAY_SECOND_STRUCT day_second;
	}
	public SQLINTERVAL interval_type;
	public int16 interval_sign;
	public _intval_e__Union intval;
}

[CRepr]
public struct SQL_NUMERIC_STRUCT
{
	public uint8 precision;
	public int8 scale;
	public uint8 sign;
	public uint8[16] val;
}

[CRepr]
public struct DBVARYCHAR
{
	public int16 len;
	public int8[8001] str;
}

[CRepr]
public struct DBVARYBIN
{
	public int16 len;
	public uint8[8001] array;
}

[CRepr]
public struct DBMONEY
{
	public int32 mnyhigh;
	public uint32 mnylow;
}

[CRepr]
public struct DBDATETIME
{
	public int32 dtdays;
	public uint32 dttime;
}

[CRepr]
public struct DBDATETIM4
{
	public uint16 numdays;
	public uint16 nummins;
}

[CRepr]
public struct SQLPERF
{
	public uint32 TimerResolution;
	public uint32 SQLidu;
	public uint32 SQLiduRows;
	public uint32 SQLSelects;
	public uint32 SQLSelectRows;
	public uint32 Transactions;
	public uint32 SQLPrepares;
	public uint32 ExecDirects;
	public uint32 SQLExecutes;
	public uint32 CursorOpens;
	public uint32 CursorSize;
	public uint32 CursorUsed;
	public double PercentCursorUsed;
	public double AvgFetchTime;
	public double AvgCursorSize;
	public double AvgCursorUsed;
	public uint32 SQLFetchTime;
	public uint32 SQLFetchCount;
	public uint32 CurrentStmtCount;
	public uint32 MaxOpenStmt;
	public uint32 SumOpenStmt;
	public uint32 CurrentConnectionCount;
	public uint32 MaxConnectionsOpened;
	public uint32 SumConnectionsOpened;
	public uint32 SumConnectiontime;
	public double AvgTimeOpened;
	public uint32 ServerRndTrips;
	public uint32 BuffersSent;
	public uint32 BuffersRec;
	public uint32 BytesSent;
	public uint32 BytesRec;
	public uint32 msExecutionTime;
	public uint32 msNetWorkServerTime;
}

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBROWWATCHCHANGE
{
	public uint hRegion;
	public uint32 eChangeKind;
	public uint hRow;
	public uint iRow;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBCOST
{
	public uint32 eKind;
	public uint32 dwUnits;
	public int32 lValue;
}
#endif

[CRepr]
public struct NOTRESTRICTION
{
	public RESTRICTION* pRes;
}

[CRepr]
public struct NODERESTRICTION
{
	public uint32 cRes;
	public RESTRICTION** paRes;
	public uint32 reserved;
}

[CRepr]
public struct VECTORRESTRICTION
{
	public NODERESTRICTION Node;
	public uint32 RankMethod;
}

[CRepr]
public struct CONTENTRESTRICTION
{
	public FULLPROPSPEC prop;
	public PWSTR pwcsPhrase;
	public uint32 lcid;
	public uint32 ulGenerateMethod;
}

[CRepr]
public struct NATLANGUAGERESTRICTION
{
	public FULLPROPSPEC prop;
	public PWSTR pwcsPhrase;
	public uint32 lcid;
}

[CRepr]
public struct PROPERTYRESTRICTION
{
	public uint32 rel;
	public FULLPROPSPEC prop;
	public PROPVARIANT prval;
}

[CRepr]
public struct RESTRICTION
{
	[CRepr, Union]
	public struct _URes
	{
		public NODERESTRICTION ar;
		public NODERESTRICTION orRestriction;
		public NODERESTRICTION pxr;
		public VECTORRESTRICTION vr;
		public NOTRESTRICTION nr;
		public CONTENTRESTRICTION cr;
		public NATLANGUAGERESTRICTION nlr;
		public PROPERTYRESTRICTION pr;
	}
	public uint32 rt;
	public uint32 weight;
	public _URes res;
}

[CRepr]
public struct COLUMNSET
{
	public uint32 cCol;
	public FULLPROPSPEC* aCol;
}

[CRepr]
public struct SORTKEY
{
	public FULLPROPSPEC propColumn;
	public uint32 dwOrder;
	public uint32 locale;
}

[CRepr]
public struct SORTSET
{
	public uint32 cCol;
	public SORTKEY* aCol;
}

[CRepr]
public struct BUCKETCATEGORIZE
{
	public uint32 cBuckets;
	public uint32 Distribution;
}

[CRepr]
public struct RANGECATEGORIZE
{
	public uint32 cRange;
	public PROPVARIANT* aRangeBegin;
}

[CRepr]
public struct CATEGORIZATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cClusters;
		public BUCKETCATEGORIZE bucket;
		public RANGECATEGORIZE range;
	}
	public uint32 ulCatType;
	public using _Anonymous_e__Union Anonymous;
	public COLUMNSET csColumns;
}

[CRepr]
public struct CATEGORIZATIONSET
{
	public uint32 cCat;
	public CATEGORIZATION* aCat;
}

[CRepr]
public struct ODBC_VS_ARGS
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR wszArg;
		public PSTR szArg;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public PWSTR wszCorrelation;
		public PSTR szCorrelation;
	}
	public Guid* pguidEvent;
	public uint32 dwFlags;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public int16 RetCode;
}

[CRepr]
public struct SSVARIANT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _BLOBType
		{
			public DBOBJECT dbobj;
			public IUnknown* pUnk;
		}
		[CRepr]
		public struct _BinaryVal
		{
			public int16 sActualLength;
			public int16 sMaxLength;
			public uint8* prgbBinaryVal;
			public uint32 dwReserved;
		}
		[CRepr]
		public struct _NCharVal
		{
			public int16 sActualLength;
			public int16 sMaxLength;
			public PWSTR pwchNCharVal;
			public uint8[5] rgbReserved;
			public uint32 dwReserved;
			public PWSTR pwchReserved;
		}
		[CRepr]
		public struct _CharVal
		{
			public int16 sActualLength;
			public int16 sMaxLength;
			public PSTR pchCharVal;
			public uint8[5] rgbReserved;
			public uint32 dwReserved;
			public PWSTR pwchReserved;
		}
		[CRepr]
		public struct _UnknownType
		{
			public uint32 dwActualLength;
			public uint8[16] rgMetadata;
			public uint8* pUnknownData;
		}
		public uint8 bTinyIntVal;
		public int16 sShortIntVal;
		public int32 lIntVal;
		public int64 llBigIntVal;
		public float fltRealVal;
		public double dblFloatVal;
		public CY cyMoneyVal;
		public _NCharVal NCharVal;
		public _CharVal CharVal;
		public int16 fBitVal;
		public uint8[16] rgbGuidVal;
		public DB_NUMERIC numNumericVal;
		public _BinaryVal BinaryVal;
		public DBTIMESTAMP tsDateTimeVal;
		public _UnknownType UnknownType;
		public _BLOBType BLOBType;
	}
	public uint16 vt;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SSERRORINFO
{
	public PWSTR pwszMessage;
	public PWSTR pwszServer;
	public PWSTR pwszProcedure;
	public int32 lNative;
	public uint8 bState;
	public uint8 bClass;
	public uint16 wLineNumber;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CSearchManager = .(0x7d096c5f, 0xac08, 0x4f1f, 0xbe, 0xb7, 0x5c, 0x22, 0xc5, 0x17, 0xce, 0x39);


	public const Guid CLSID_CSearchRoot = .(0x30766bd2, 0xea1c, 0x4f28, 0xbf, 0x27, 0x0b, 0x44, 0xe2, 0xf6, 0x8d, 0xb7);


	public const Guid CLSID_CSearchScopeRule = .(0xe63de750, 0x3bd7, 0x4be5, 0x9c, 0x84, 0x6b, 0x42, 0x81, 0x98, 0x8c, 0x44);


	public const Guid CLSID_FilterRegistration = .(0x9e175b8d, 0xf52a, 0x11d8, 0xb9, 0xa5, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);


	public const Guid CLSID_QueryParser = .(0xb72f8fd8, 0x0fab, 0x4dd9, 0xbd, 0xbf, 0x24, 0x5a, 0x6c, 0xe1, 0x48, 0x5b);


	public const Guid CLSID_NegationCondition = .(0x8de9c74c, 0x605a, 0x4acd, 0xbe, 0xe3, 0x2b, 0x22, 0x2a, 0xa2, 0xd2, 0x3d);


	public const Guid CLSID_CompoundCondition = .(0x116f8d13, 0x101e, 0x4fa5, 0x84, 0xd4, 0xff, 0x82, 0x79, 0x38, 0x19, 0x35);


	public const Guid CLSID_LeafCondition = .(0x52f15c89, 0x5a17, 0x48e1, 0xbb, 0xcd, 0x46, 0xa3, 0xf8, 0x9c, 0x7c, 0xc2);


	public const Guid CLSID_ConditionFactory = .(0xe03e85b0, 0x7be3, 0x4000, 0xba, 0x98, 0x6c, 0x13, 0xde, 0x9f, 0xa4, 0x86);


	public const Guid CLSID_Interval = .(0xd957171f, 0x4bf9, 0x4de2, 0xbc, 0xd5, 0xc7, 0x0a, 0x7c, 0xa5, 0x58, 0x36);


	public const Guid CLSID_QueryParserManager = .(0x5088b39a, 0x29b4, 0x4d9d, 0x82, 0x45, 0x4e, 0xe2, 0x89, 0x22, 0x2f, 0x66);


	public const Guid CLSID_CSearchLanguageSupport = .(0x6a68cc80, 0x4337, 0x4dbc, 0xbd, 0x27, 0xfb, 0xfb, 0x10, 0x53, 0x82, 0x0b);


	public const Guid CLSID_SubscriptionMgr = .(0xabbe31d0, 0x6dae, 0x11d0, 0xbe, 0xca, 0x00, 0xc0, 0x4f, 0xd9, 0x40, 0xbe);


	public const Guid CLSID_MSDAORA = .(0xe8cc4cbe, 0xfdff, 0x11d0, 0xb8, 0x65, 0x00, 0xa0, 0xc9, 0x08, 0x1c, 0x1d);


	public const Guid CLSID_MSDAORA_ERROR = .(0xe8cc4cbf, 0xfdff, 0x11d0, 0xb8, 0x65, 0x00, 0xa0, 0xc9, 0x08, 0x1c, 0x1d);


	public const Guid CLSID_MSDAORA8 = .(0x7f06a373, 0xdd6a, 0x43db, 0xb4, 0xe0, 0x1f, 0xc1, 0x21, 0xe5, 0xe6, 0x2b);


	public const Guid CLSID_MSDAORA8_ERROR = .(0x7f06a374, 0xdd6a, 0x43db, 0xb4, 0xe0, 0x1f, 0xc1, 0x21, 0xe5, 0xe6, 0x2b);


	public const Guid CLSID_DataLinks = .(0x2206cdb2, 0x19c1, 0x11d1, 0x89, 0xe0, 0x00, 0xc0, 0x4f, 0xd7, 0xa8, 0x29);


	public const Guid CLSID_MSDAINITIALIZE = .(0x2206cdb0, 0x19c1, 0x11d1, 0x89, 0xe0, 0x00, 0xc0, 0x4f, 0xd7, 0xa8, 0x29);


	public const Guid CLSID_PDPO = .(0xccb4ec60, 0xb9dc, 0x11d1, 0xac, 0x80, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0x73);


	public const Guid CLSID_RootBinder = .(0xff151822, 0xb0bf, 0x11d1, 0xa8, 0x0d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);


}
#endregion

#region COM Types
[CRepr]struct IWordSink : IUnknown
{
	public new const Guid IID = .(0xcc907054, 0xc058, 0x101a, 0xb5, 0x54, 0x08, 0x00, 0x2b, 0x33, 0xb0, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cwc, PWSTR pwcInBuf, uint32 cwcSrcLen, uint32 cwcSrcPos) PutWord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cwc, PWSTR pwcInBuf, uint32 cwcSrcLen, uint32 cwcSrcPos) PutAltWord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartAltPhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndAltPhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WORDREP_BREAK_TYPE breakType) PutBreak;
	}


	public HRESULT PutWord(uint32 cwc, PWSTR pwcInBuf, uint32 cwcSrcLen, uint32 cwcSrcPos) mut => VT.[Friend]PutWord(&this, cwc, pwcInBuf, cwcSrcLen, cwcSrcPos);

	public HRESULT PutAltWord(uint32 cwc, PWSTR pwcInBuf, uint32 cwcSrcLen, uint32 cwcSrcPos) mut => VT.[Friend]PutAltWord(&this, cwc, pwcInBuf, cwcSrcLen, cwcSrcPos);

	public HRESULT StartAltPhrase() mut => VT.[Friend]StartAltPhrase(&this);

	public HRESULT EndAltPhrase() mut => VT.[Friend]EndAltPhrase(&this);

	public HRESULT PutBreak(WORDREP_BREAK_TYPE breakType) mut => VT.[Friend]PutBreak(&this, breakType);
}

[CRepr]struct IWordBreaker : IUnknown
{
	public new const Guid IID = .(0xd53552c8, 0x77e3, 0x101a, 0xb5, 0x52, 0x08, 0x00, 0x2b, 0x33, 0xb0, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fQuery, uint32 ulMaxTokenSize, BOOL* pfLicense) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TEXT_SOURCE* pTextSource, IWordSink* pWordSink, IPhraseSink* pPhraseSink) BreakText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcNoun, uint32 cwcNoun, PWSTR pwcModifier, uint32 cwcModifier, uint32 ulAttachmentType, PWSTR pwcPhrase, uint32* pcwcPhrase) ComposePhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppwcsLicense) GetLicenseToUse;
	}


	public HRESULT Init(BOOL fQuery, uint32 ulMaxTokenSize, BOOL* pfLicense) mut => VT.[Friend]Init(&this, fQuery, ulMaxTokenSize, pfLicense);

	public HRESULT BreakText(TEXT_SOURCE* pTextSource, IWordSink* pWordSink, IPhraseSink* pPhraseSink) mut => VT.[Friend]BreakText(&this, pTextSource, pWordSink, pPhraseSink);

	public HRESULT ComposePhrase(PWSTR pwcNoun, uint32 cwcNoun, PWSTR pwcModifier, uint32 cwcModifier, uint32 ulAttachmentType, PWSTR pwcPhrase, uint32* pcwcPhrase) mut => VT.[Friend]ComposePhrase(&this, pwcNoun, cwcNoun, pwcModifier, cwcModifier, ulAttachmentType, pwcPhrase, pcwcPhrase);

	public HRESULT GetLicenseToUse(uint16** ppwcsLicense) mut => VT.[Friend]GetLicenseToUse(&this, ppwcsLicense);
}

[CRepr]struct IWordFormSink : IUnknown
{
	public new const Guid IID = .(0xfe77c330, 0x7f42, 0x11ce, 0xbe, 0x57, 0x00, 0xaa, 0x00, 0x51, 0xfe, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcInBuf, uint32 cwc) PutAltWord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcInBuf, uint32 cwc) PutWord;
	}


	public HRESULT PutAltWord(PWSTR pwcInBuf, uint32 cwc) mut => VT.[Friend]PutAltWord(&this, pwcInBuf, cwc);

	public HRESULT PutWord(PWSTR pwcInBuf, uint32 cwc) mut => VT.[Friend]PutWord(&this, pwcInBuf, cwc);
}

[CRepr]struct IStemmer : IUnknown
{
	public new const Guid IID = .(0xefbaf140, 0x7f42, 0x11ce, 0xbe, 0x57, 0x00, 0xaa, 0x00, 0x51, 0xfe, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulMaxTokenSize, BOOL* pfLicense) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcInBuf, uint32 cwc, IWordFormSink* pStemSink) GenerateWordForms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppwcsLicense) GetLicenseToUse;
	}


	public HRESULT Init(uint32 ulMaxTokenSize, BOOL* pfLicense) mut => VT.[Friend]Init(&this, ulMaxTokenSize, pfLicense);

	public HRESULT GenerateWordForms(PWSTR pwcInBuf, uint32 cwc, IWordFormSink* pStemSink) mut => VT.[Friend]GenerateWordForms(&this, pwcInBuf, cwc, pStemSink);

	public HRESULT GetLicenseToUse(uint16** ppwcsLicense) mut => VT.[Friend]GetLicenseToUse(&this, ppwcsLicense);
}

[CRepr]struct ISimpleCommandCreator : IUnknown
{
	public new const Guid IID = .(0x5e341ab7, 0x02d0, 0x11d1, 0x90, 0x0c, 0x00, 0xa0, 0xc9, 0x06, 0x37, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppIUnknown, IUnknown* pOuterUnk) CreateICommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszMachine, PWSTR pwszCatalogName) VerifyCatalog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszCatalogName, uint32 cwcIn, uint32* pcwcOut) GetDefaultCatalog;
	}


	public HRESULT CreateICommand(IUnknown** ppIUnknown, IUnknown* pOuterUnk) mut => VT.[Friend]CreateICommand(&this, ppIUnknown, pOuterUnk);

	public HRESULT VerifyCatalog(PWSTR pwszMachine, PWSTR pwszCatalogName) mut => VT.[Friend]VerifyCatalog(&this, pwszMachine, pwszCatalogName);

	public HRESULT GetDefaultCatalog(PWSTR pwszCatalogName, uint32 cwcIn, uint32* pcwcOut) mut => VT.[Friend]GetDefaultCatalog(&this, pwszCatalogName, cwcIn, pcwcOut);
}

[CRepr]struct IColumnMapper : IUnknown
{
	public new const Guid IID = .(0x0b63e37a, 0x9ccc, 0x11d0, 0xbc, 0xdb, 0x00, 0x80, 0x5f, 0xcc, 0xce, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wcsPropName, DBID** ppPropId, uint16* pPropType, uint32* puiWidth) GetPropInfoFromName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pPropId, uint16** pwcsName, uint16* pPropType, uint32* puiWidth) GetPropInfoFromId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iEntry, uint16** pwcsName, DBID** ppPropId, uint16* pPropType, uint32* puiWidth) EnumPropInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsMapUpToDate;
	}


	public HRESULT GetPropInfoFromName(PWSTR wcsPropName, DBID** ppPropId, uint16* pPropType, uint32* puiWidth) mut => VT.[Friend]GetPropInfoFromName(&this, wcsPropName, ppPropId, pPropType, puiWidth);

	public HRESULT GetPropInfoFromId(DBID* pPropId, uint16** pwcsName, uint16* pPropType, uint32* puiWidth) mut => VT.[Friend]GetPropInfoFromId(&this, pPropId, pwcsName, pPropType, puiWidth);

	public HRESULT EnumPropInfo(uint32 iEntry, uint16** pwcsName, DBID** ppPropId, uint16* pPropType, uint32* puiWidth) mut => VT.[Friend]EnumPropInfo(&this, iEntry, pwcsName, ppPropId, pPropType, puiWidth);

	public HRESULT IsMapUpToDate() mut => VT.[Friend]IsMapUpToDate(&this);
}

[CRepr]struct IColumnMapperCreator : IUnknown
{
	public new const Guid IID = .(0x0b63e37b, 0x9ccc, 0x11d0, 0xbc, 0xdb, 0x00, 0x80, 0x5f, 0xcc, 0xce, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wcsMachineName, PWSTR wcsCatalogName, IColumnMapper** ppColumnMapper) GetColumnMapper;
	}


	public HRESULT GetColumnMapper(PWSTR wcsMachineName, PWSTR wcsCatalogName, IColumnMapper** ppColumnMapper) mut => VT.[Friend]GetColumnMapper(&this, wcsMachineName, wcsCatalogName, ppColumnMapper);
}

[CRepr]struct ILoadFilter : IUnknown
{
	public new const Guid IID = .(0xc7310722, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsPath, FILTERED_DATA_SOURCES* pFilteredSources, IUnknown* pUnkOuter, BOOL fUseDefault, Guid* pFilterClsid, int32* SearchDecSize, uint16** pwcsSearchDesc, IFilter** ppIFilt) LoadIFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStg, IUnknown* pUnkOuter, PWSTR pwcsOverride, BOOL fUseDefault, Guid* pFilterClsid, int32* SearchDecSize, uint16** pwcsSearchDesc, IFilter** ppIFilt) LoadIFilterFromStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStm, FILTERED_DATA_SOURCES* pFilteredSources, IUnknown* pUnkOuter, BOOL fUseDefault, Guid* pFilterClsid, int32* SearchDecSize, uint16** pwcsSearchDesc, IFilter** ppIFilt) LoadIFilterFromStream;
	}


	public HRESULT LoadIFilter(PWSTR pwcsPath, FILTERED_DATA_SOURCES* pFilteredSources, IUnknown* pUnkOuter, BOOL fUseDefault, Guid* pFilterClsid, int32* SearchDecSize, uint16** pwcsSearchDesc, IFilter** ppIFilt) mut => VT.[Friend]LoadIFilter(&this, pwcsPath, pFilteredSources, pUnkOuter, fUseDefault, pFilterClsid, SearchDecSize, pwcsSearchDesc, ppIFilt);

	public HRESULT LoadIFilterFromStorage(IStorage* pStg, IUnknown* pUnkOuter, PWSTR pwcsOverride, BOOL fUseDefault, Guid* pFilterClsid, int32* SearchDecSize, uint16** pwcsSearchDesc, IFilter** ppIFilt) mut => VT.[Friend]LoadIFilterFromStorage(&this, pStg, pUnkOuter, pwcsOverride, fUseDefault, pFilterClsid, SearchDecSize, pwcsSearchDesc, ppIFilt);

	public HRESULT LoadIFilterFromStream(IStream* pStm, FILTERED_DATA_SOURCES* pFilteredSources, IUnknown* pUnkOuter, BOOL fUseDefault, Guid* pFilterClsid, int32* SearchDecSize, uint16** pwcsSearchDesc, IFilter** ppIFilt) mut => VT.[Friend]LoadIFilterFromStream(&this, pStm, pFilteredSources, pUnkOuter, fUseDefault, pFilterClsid, SearchDecSize, pwcsSearchDesc, ppIFilt);
}

[CRepr]struct ILoadFilterWithPrivateComActivation : ILoadFilter
{
	public new const Guid IID = .(0x40bdbd34, 0x780b, 0x48d3, 0x9b, 0xb6, 0x12, 0xeb, 0xd4, 0xad, 0x2e, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ILoadFilter.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILTERED_DATA_SOURCES* filteredSources, BOOL useDefault, Guid* filterClsid, BOOL* isFilterPrivateComActivated, IFilter** filterObj) LoadIFilterWithPrivateComActivation;
	}


	public HRESULT LoadIFilterWithPrivateComActivation(FILTERED_DATA_SOURCES* filteredSources, BOOL useDefault, Guid* filterClsid, BOOL* isFilterPrivateComActivated, IFilter** filterObj) mut => VT.[Friend]LoadIFilterWithPrivateComActivation(&this, filteredSources, useDefault, filterClsid, isFilterPrivateComActivated, filterObj);
}

[CRepr]struct IRichChunk : IUnknown
{
	public new const Guid IID = .(0x4fdef69c, 0xdbc9, 0x454e, 0x99, 0x10, 0xb3, 0x4f, 0x3c, 0x64, 0xb5, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFirstPos, uint32* pLength, PWSTR* ppsz, PROPVARIANT* pValue) GetData;
	}


	public HRESULT GetData(uint32* pFirstPos, uint32* pLength, PWSTR* ppsz, PROPVARIANT* pValue) mut => VT.[Friend]GetData(&this, pFirstPos, pLength, ppsz, pValue);
}

[CRepr]struct ICondition : IPersistStream
{
	public new const Guid IID = .(0x0fc988d4, 0xc935, 0x4b97, 0xa9, 0x73, 0x46, 0x28, 0x2e, 0xa1, 0x75, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONDITION_TYPE* pNodeType) GetConditionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetSubConditions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPropertyName, CONDITION_OPERATION* pcop, PROPVARIANT* ppropvar) GetComparisonInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszValueTypeName) GetValueType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszNormalization) GetValueNormalization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRichChunk** ppPropertyTerm, IRichChunk** ppOperationTerm, IRichChunk** ppValueTerm) GetInputTerms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition** ppc) Clone;
	}


	public HRESULT GetConditionType(CONDITION_TYPE* pNodeType) mut => VT.[Friend]GetConditionType(&this, pNodeType);

	public HRESULT GetSubConditions(in Guid riid, void** ppv) mut => VT.[Friend]GetSubConditions(&this, riid, ppv);

	public HRESULT GetComparisonInfo(PWSTR* ppszPropertyName, CONDITION_OPERATION* pcop, PROPVARIANT* ppropvar) mut => VT.[Friend]GetComparisonInfo(&this, ppszPropertyName, pcop, ppropvar);

	public HRESULT GetValueType(PWSTR* ppszValueTypeName) mut => VT.[Friend]GetValueType(&this, ppszValueTypeName);

	public HRESULT GetValueNormalization(PWSTR* ppszNormalization) mut => VT.[Friend]GetValueNormalization(&this, ppszNormalization);

	public HRESULT GetInputTerms(IRichChunk** ppPropertyTerm, IRichChunk** ppOperationTerm, IRichChunk** ppValueTerm) mut => VT.[Friend]GetInputTerms(&this, ppPropertyTerm, ppOperationTerm, ppValueTerm);

	public HRESULT Clone(ICondition** ppc) mut => VT.[Friend]Clone(&this, ppc);
}

[CRepr]struct ICondition2 : ICondition
{
	public new const Guid IID = .(0x0db8851d, 0x2e5b, 0x47eb, 0x92, 0x08, 0xd2, 0x8c, 0x32, 0x5a, 0x01, 0xd7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICondition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszLocaleName) GetLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* ppropkey, CONDITION_OPERATION* pcop, PROPVARIANT* ppropvar) GetLeafConditionInfo;
	}


	public HRESULT GetLocale(PWSTR* ppszLocaleName) mut => VT.[Friend]GetLocale(&this, ppszLocaleName);

	public HRESULT GetLeafConditionInfo(PROPERTYKEY* ppropkey, CONDITION_OPERATION* pcop, PROPVARIANT* ppropvar) mut => VT.[Friend]GetLeafConditionInfo(&this, ppropkey, pcop, ppropvar);
}

[CRepr]struct IAccessor : IUnknown
{
	public new const Guid IID = .(0x0c733a8c, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint32* pcRefCount) AddRefAccessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAccessorFlags, uint cBindings, DBBINDING* rgBindings, uint cbRowSize, HACCESSOR* phAccessor, uint32* rgStatus) CreateAccessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint32* pdwAccessorFlags, uint* pcBindings, DBBINDING** prgBindings) GetBindings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint32* pcRefCount) ReleaseAccessor;
	}


	public HRESULT AddRefAccessor(HACCESSOR hAccessor, uint32* pcRefCount) mut => VT.[Friend]AddRefAccessor(&this, hAccessor, pcRefCount);

	public HRESULT CreateAccessor(uint32 dwAccessorFlags, uint cBindings, DBBINDING* rgBindings, uint cbRowSize, HACCESSOR* phAccessor, uint32* rgStatus) mut => VT.[Friend]CreateAccessor(&this, dwAccessorFlags, cBindings, rgBindings, cbRowSize, phAccessor, rgStatus);

	public HRESULT GetBindings(HACCESSOR hAccessor, uint32* pdwAccessorFlags, uint* pcBindings, DBBINDING** prgBindings) mut => VT.[Friend]GetBindings(&this, hAccessor, pdwAccessorFlags, pcBindings, prgBindings);

	public HRESULT ReleaseAccessor(HACCESSOR hAccessor, uint32* pcRefCount) mut => VT.[Friend]ReleaseAccessor(&this, hAccessor, pcRefCount);
}

[CRepr]struct IRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a7c, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cRows, uint* rghRows, uint32* rgRefCounts, uint32* rgRowStatus) AddRefRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRow, HACCESSOR hAccessor, void* pData) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, int lRowsOffset, int cRows, uint* pcRowsObtained, uint** prghRows) GetNextRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cRows, uint* rghRows, uint32* rgRowOptions, uint32* rgRefCounts, uint32* rgRowStatus) ReleaseRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved) RestartPosition;
	}


	public HRESULT AddRefRows(uint cRows, uint* rghRows, uint32* rgRefCounts, uint32* rgRowStatus) mut => VT.[Friend]AddRefRows(&this, cRows, rghRows, rgRefCounts, rgRowStatus);

	public HRESULT GetData(uint hRow, HACCESSOR hAccessor, void* pData) mut => VT.[Friend]GetData(&this, hRow, hAccessor, pData);

	public HRESULT GetNextRows(uint hReserved, int lRowsOffset, int cRows, uint* pcRowsObtained, uint** prghRows) mut => VT.[Friend]GetNextRows(&this, hReserved, lRowsOffset, cRows, pcRowsObtained, prghRows);

	public HRESULT ReleaseRows(uint cRows, uint* rghRows, uint32* rgRowOptions, uint32* rgRefCounts, uint32* rgRowStatus) mut => VT.[Friend]ReleaseRows(&this, cRows, rghRows, rgRowOptions, rgRefCounts, rgRowStatus);

	public HRESULT RestartPosition(uint hReserved) mut => VT.[Friend]RestartPosition(&this, hReserved);
}

[CRepr]struct IRowsetInfo : IUnknown
{
	public new const Guid IID = .(0x0c733a55, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint iOrdinal, in Guid riid, IUnknown** ppReferencedRowset) GetReferencedRowset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppSpecification) GetSpecification;
	}


	public HRESULT GetProperties(uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) mut => VT.[Friend]GetProperties(&this, cPropertyIDSets, rgPropertyIDSets, pcPropertySets, prgPropertySets);

	public HRESULT GetReferencedRowset(uint iOrdinal, in Guid riid, IUnknown** ppReferencedRowset) mut => VT.[Friend]GetReferencedRowset(&this, iOrdinal, riid, ppReferencedRowset);

	public HRESULT GetSpecification(in Guid riid, IUnknown** ppSpecification) mut => VT.[Friend]GetSpecification(&this, riid, ppSpecification);
}

[CRepr]struct IRowsetLocate : IRowset
{
	public new const Guid IID = .(0x0c733a7d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRowset.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cbBookmark1, uint8* pBookmark1, uint cbBookmark2, uint8* pBookmark2, uint32* pComparison) Compare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved1, uint hReserved2, uint cbBookmark, uint8* pBookmark, int lRowsOffset, int cRows, uint* pcRowsObtained, uint** prghRows) GetRowsAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cRows, uint* rgcbBookmarks, uint8** rgpBookmarks, uint* rghRows, uint32* rgRowStatus) GetRowsByBookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cBookmarks, uint* rgcbBookmarks, uint8** rgpBookmarks, uint* rgHashedValues, uint32* rgBookmarkStatus) Hash;
	}


	public HRESULT Compare(uint hReserved, uint cbBookmark1, uint8* pBookmark1, uint cbBookmark2, uint8* pBookmark2, uint32* pComparison) mut => VT.[Friend]Compare(&this, hReserved, cbBookmark1, pBookmark1, cbBookmark2, pBookmark2, pComparison);

	public HRESULT GetRowsAt(uint hReserved1, uint hReserved2, uint cbBookmark, uint8* pBookmark, int lRowsOffset, int cRows, uint* pcRowsObtained, uint** prghRows) mut => VT.[Friend]GetRowsAt(&this, hReserved1, hReserved2, cbBookmark, pBookmark, lRowsOffset, cRows, pcRowsObtained, prghRows);

	public HRESULT GetRowsByBookmark(uint hReserved, uint cRows, uint* rgcbBookmarks, uint8** rgpBookmarks, uint* rghRows, uint32* rgRowStatus) mut => VT.[Friend]GetRowsByBookmark(&this, hReserved, cRows, rgcbBookmarks, rgpBookmarks, rghRows, rgRowStatus);

	public HRESULT Hash(uint hReserved, uint cBookmarks, uint* rgcbBookmarks, uint8** rgpBookmarks, uint* rgHashedValues, uint32* rgBookmarkStatus) mut => VT.[Friend]Hash(&this, hReserved, cBookmarks, rgcbBookmarks, rgpBookmarks, rgHashedValues, rgBookmarkStatus);
}

[CRepr]struct IRowsetResynch : IUnknown
{
	public new const Guid IID = .(0x0c733a84, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRow, HACCESSOR hAccessor, void* pData) GetVisibleData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cRows, uint* rghRows, uint* pcRowsResynched, uint** prghRowsResynched, uint32** prgRowStatus) ResynchRows;
	}


	public HRESULT GetVisibleData(uint hRow, HACCESSOR hAccessor, void* pData) mut => VT.[Friend]GetVisibleData(&this, hRow, hAccessor, pData);

	public HRESULT ResynchRows(uint cRows, uint* rghRows, uint* pcRowsResynched, uint** prghRowsResynched, uint32** prgRowStatus) mut => VT.[Friend]ResynchRows(&this, cRows, rghRows, pcRowsResynched, prghRowsResynched, prgRowStatus);
}

[CRepr]struct IRowsetScroll : IRowsetLocate
{
	public new const Guid IID = .(0x0c733a7e, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRowsetLocate.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cbBookmark, uint8* pBookmark, uint* pulPosition, uint* pcRows) GetApproximatePosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved1, uint hReserved2, uint ulNumerator, uint ulDenominator, int cRows, uint* pcRowsObtained, uint** prghRows) GetRowsAtRatio;
	}


	public HRESULT GetApproximatePosition(uint hReserved, uint cbBookmark, uint8* pBookmark, uint* pulPosition, uint* pcRows) mut => VT.[Friend]GetApproximatePosition(&this, hReserved, cbBookmark, pBookmark, pulPosition, pcRows);

	public HRESULT GetRowsAtRatio(uint hReserved1, uint hReserved2, uint ulNumerator, uint ulDenominator, int cRows, uint* pcRowsObtained, uint** prghRows) mut => VT.[Friend]GetRowsAtRatio(&this, hReserved1, hReserved2, ulNumerator, ulDenominator, cRows, pcRowsObtained, prghRows);
}

[CRepr]struct IChapteredRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a93, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32* pcRefCount) AddRefChapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32* pcRefCount) ReleaseChapter;
	}


	public HRESULT AddRefChapter(uint hChapter, uint32* pcRefCount) mut => VT.[Friend]AddRefChapter(&this, hChapter, pcRefCount);

	public HRESULT ReleaseChapter(uint hChapter, uint32* pcRefCount) mut => VT.[Friend]ReleaseChapter(&this, hChapter, pcRefCount);
}

[CRepr]struct IRowsetFind : IUnknown
{
	public new const Guid IID = .(0x0c733a9d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, HACCESSOR hAccessor, void* pFindValue, uint32 CompareOp, uint cbBookmark, uint8* pBookmark, int lRowsOffset, int cRows, uint* pcRowsObtained, uint** prghRows) FindNextRow;
	}


	public HRESULT FindNextRow(uint hChapter, HACCESSOR hAccessor, void* pFindValue, uint32 CompareOp, uint cbBookmark, uint8* pBookmark, int lRowsOffset, int cRows, uint* pcRowsObtained, uint** prghRows) mut => VT.[Friend]FindNextRow(&this, hChapter, hAccessor, pFindValue, CompareOp, cbBookmark, pBookmark, lRowsOffset, cRows, pcRowsObtained, prghRows);
}

[CRepr]struct IRowPosition : IUnknown
{
	public new const Guid IID = .(0x0c733a94, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearRowPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phChapter, uint* phRow, uint32* pdwPositionFlags) GetRowPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppRowset) GetRowset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pRowset) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint hRow, uint32 dwPositionFlags) SetRowPosition;
	}


	public HRESULT ClearRowPosition() mut => VT.[Friend]ClearRowPosition(&this);

	public HRESULT GetRowPosition(uint* phChapter, uint* phRow, uint32* pdwPositionFlags) mut => VT.[Friend]GetRowPosition(&this, phChapter, phRow, pdwPositionFlags);

	public HRESULT GetRowset(in Guid riid, IUnknown** ppRowset) mut => VT.[Friend]GetRowset(&this, riid, ppRowset);

	public HRESULT Initialize(IUnknown* pRowset) mut => VT.[Friend]Initialize(&this, pRowset);

	public HRESULT SetRowPosition(uint hChapter, uint hRow, uint32 dwPositionFlags) mut => VT.[Friend]SetRowPosition(&this, hChapter, hRow, dwPositionFlags);
}

[CRepr]struct IRowPositionChange : IUnknown
{
	public new const Guid IID = .(0x0997a571, 0x126e, 0x11d0, 0x9f, 0x8a, 0x00, 0xa0, 0xc9, 0xa0, 0x63, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 eReason, uint32 ePhase, BOOL fCantDeny) OnRowPositionChange;
	}


	public HRESULT OnRowPositionChange(uint32 eReason, uint32 ePhase, BOOL fCantDeny) mut => VT.[Friend]OnRowPositionChange(&this, eReason, ePhase, fCantDeny);
}

[CRepr]struct IViewRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a97, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppObject) GetSpecification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppRowset) OpenViewRowset;
	}


	public HRESULT GetSpecification(in Guid riid, IUnknown** ppObject) mut => VT.[Friend]GetSpecification(&this, riid, ppObject);

	public HRESULT OpenViewRowset(IUnknown* pUnkOuter, in Guid riid, IUnknown** ppRowset) mut => VT.[Friend]OpenViewRowset(&this, pUnkOuter, riid, ppRowset);
}

[CRepr]struct IViewChapter : IUnknown
{
	public new const Guid IID = .(0x0c733a98, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppRowset) GetSpecification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hSource, uint* phViewChapter) OpenViewChapter;
	}


	public HRESULT GetSpecification(in Guid riid, IUnknown** ppRowset) mut => VT.[Friend]GetSpecification(&this, riid, ppRowset);

	public HRESULT OpenViewChapter(uint hSource, uint* phViewChapter) mut => VT.[Friend]OpenViewChapter(&this, hSource, phViewChapter);
}

[CRepr]struct IViewSort : IUnknown
{
	public new const Guid IID = .(0x0c733a9a, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcValues, uint** prgColumns, uint32** prgOrders) GetSortOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cValues, uint* rgColumns, uint32* rgOrders) SetSortOrder;
	}


	public HRESULT GetSortOrder(uint* pcValues, uint** prgColumns, uint32** prgOrders) mut => VT.[Friend]GetSortOrder(&this, pcValues, prgColumns, prgOrders);

	public HRESULT SetSortOrder(uint cValues, uint* rgColumns, uint32* rgOrders) mut => VT.[Friend]SetSortOrder(&this, cValues, rgColumns, rgOrders);
}

[CRepr]struct IViewFilter : IUnknown
{
	public new const Guid IID = .(0x0c733a9b, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint* pcRows, uint32** pCompareOps, void* pCriteriaData) GetFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcBindings, DBBINDING** prgBindings) GetFilterBindings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint cRows, uint32* CompareOps, void* pCriteriaData) SetFilter;
	}


	public HRESULT GetFilter(HACCESSOR hAccessor, uint* pcRows, uint32** pCompareOps, void* pCriteriaData) mut => VT.[Friend]GetFilter(&this, hAccessor, pcRows, pCompareOps, pCriteriaData);

	public HRESULT GetFilterBindings(uint* pcBindings, DBBINDING** prgBindings) mut => VT.[Friend]GetFilterBindings(&this, pcBindings, prgBindings);

	public HRESULT SetFilter(HACCESSOR hAccessor, uint cRows, uint32* CompareOps, void* pCriteriaData) mut => VT.[Friend]SetFilter(&this, hAccessor, cRows, CompareOps, pCriteriaData);
}

[CRepr]struct IRowsetView : IUnknown
{
	public new const Guid IID = .(0x0c733a99, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppView) CreateView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, in Guid riid, uint* phChapterSource, IUnknown** ppView) GetView;
	}


	public HRESULT CreateView(IUnknown* pUnkOuter, in Guid riid, IUnknown** ppView) mut => VT.[Friend]CreateView(&this, pUnkOuter, riid, ppView);

	public HRESULT GetView(uint hChapter, in Guid riid, uint* phChapterSource, IUnknown** ppView) mut => VT.[Friend]GetView(&this, hChapter, riid, phChapterSource, ppView);
}

[CRepr]struct IRowsetChange : IUnknown
{
	public new const Guid IID = .(0x0c733a05, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cRows, uint* rghRows, uint32* rgRowStatus) DeleteRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRow, HACCESSOR hAccessor, void* pData) SetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, HACCESSOR hAccessor, void* pData, uint* phRow) InsertRow;
	}


	public HRESULT DeleteRows(uint hReserved, uint cRows, uint* rghRows, uint32* rgRowStatus) mut => VT.[Friend]DeleteRows(&this, hReserved, cRows, rghRows, rgRowStatus);

	public HRESULT SetData(uint hRow, HACCESSOR hAccessor, void* pData) mut => VT.[Friend]SetData(&this, hRow, hAccessor, pData);

	public HRESULT InsertRow(uint hReserved, HACCESSOR hAccessor, void* pData, uint* phRow) mut => VT.[Friend]InsertRow(&this, hReserved, hAccessor, pData, phRow);
}

[CRepr]struct IRowsetUpdate : IRowsetChange
{
	public new const Guid IID = .(0x0c733a6d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRowsetChange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRow, HACCESSOR hAccessor, void* pData) GetOriginalData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint32 dwRowStatus, uint* pcPendingRows, uint** prgPendingRows, uint32** prgPendingStatus) GetPendingRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cRows, uint* rghRows, uint32* rgPendingStatus) GetRowStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cRows, uint* rghRows, uint* pcRowsUndone, uint** prgRowsUndone, uint32** prgRowStatus) Undo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint cRows, uint* rghRows, uint* pcRows, uint** prgRows, uint32** prgRowStatus) Update;
	}


	public HRESULT GetOriginalData(uint hRow, HACCESSOR hAccessor, void* pData) mut => VT.[Friend]GetOriginalData(&this, hRow, hAccessor, pData);

	public HRESULT GetPendingRows(uint hReserved, uint32 dwRowStatus, uint* pcPendingRows, uint** prgPendingRows, uint32** prgPendingStatus) mut => VT.[Friend]GetPendingRows(&this, hReserved, dwRowStatus, pcPendingRows, prgPendingRows, prgPendingStatus);

	public HRESULT GetRowStatus(uint hReserved, uint cRows, uint* rghRows, uint32* rgPendingStatus) mut => VT.[Friend]GetRowStatus(&this, hReserved, cRows, rghRows, rgPendingStatus);

	public HRESULT Undo(uint hReserved, uint cRows, uint* rghRows, uint* pcRowsUndone, uint** prgRowsUndone, uint32** prgRowStatus) mut => VT.[Friend]Undo(&this, hReserved, cRows, rghRows, pcRowsUndone, prgRowsUndone, prgRowStatus);

	public HRESULT Update(uint hReserved, uint cRows, uint* rghRows, uint* pcRows, uint** prgRows, uint32** prgRowStatus) mut => VT.[Friend]Update(&this, hReserved, cRows, rghRows, pcRows, prgRows, prgRowStatus);
}

[CRepr]struct IRowsetIdentity : IUnknown
{
	public new const Guid IID = .(0x0c733a09, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hThisRow, uint hThatRow) IsSameRow;
	}


	public HRESULT IsSameRow(uint hThisRow, uint hThatRow) mut => VT.[Friend]IsSameRow(&this, hThisRow, hThatRow);
}

[CRepr]struct IRowsetNotify : IUnknown
{
	public new const Guid IID = .(0x0c733a83, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRowset* pRowset, uint hRow, uint cColumns, uint* rgColumns, uint32 eReason, uint32 ePhase, BOOL fCantDeny) OnFieldChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRowset* pRowset, uint cRows, uint* rghRows, uint32 eReason, uint32 ePhase, BOOL fCantDeny) OnRowChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRowset* pRowset, uint32 eReason, uint32 ePhase, BOOL fCantDeny) OnRowsetChange;
	}


	public HRESULT OnFieldChange(IRowset* pRowset, uint hRow, uint cColumns, uint* rgColumns, uint32 eReason, uint32 ePhase, BOOL fCantDeny) mut => VT.[Friend]OnFieldChange(&this, pRowset, hRow, cColumns, rgColumns, eReason, ePhase, fCantDeny);

	public HRESULT OnRowChange(IRowset* pRowset, uint cRows, uint* rghRows, uint32 eReason, uint32 ePhase, BOOL fCantDeny) mut => VT.[Friend]OnRowChange(&this, pRowset, cRows, rghRows, eReason, ePhase, fCantDeny);

	public HRESULT OnRowsetChange(IRowset* pRowset, uint32 eReason, uint32 ePhase, BOOL fCantDeny) mut => VT.[Friend]OnRowsetChange(&this, pRowset, eReason, ePhase, fCantDeny);
}

[CRepr]struct IRowsetIndex : IUnknown
{
	public new const Guid IID = .(0x0c733a82, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcKeyColumns, DBINDEXCOLUMNDESC** prgIndexColumnDesc, uint32* pcIndexPropertySets, DBPROPSET** prgIndexPropertySets) GetIndexInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint cKeyValues, void* pData, uint32 dwSeekOptions) Seek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint cStartKeyColumns, void* pStartData, uint cEndKeyColumns, void* pEndData, uint32 dwRangeOptions) SetRange;
	}


	public HRESULT GetIndexInfo(uint* pcKeyColumns, DBINDEXCOLUMNDESC** prgIndexColumnDesc, uint32* pcIndexPropertySets, DBPROPSET** prgIndexPropertySets) mut => VT.[Friend]GetIndexInfo(&this, pcKeyColumns, prgIndexColumnDesc, pcIndexPropertySets, prgIndexPropertySets);

	public HRESULT Seek(HACCESSOR hAccessor, uint cKeyValues, void* pData, uint32 dwSeekOptions) mut => VT.[Friend]Seek(&this, hAccessor, cKeyValues, pData, dwSeekOptions);

	public HRESULT SetRange(HACCESSOR hAccessor, uint cStartKeyColumns, void* pStartData, uint cEndKeyColumns, void* pEndData, uint32 dwRangeOptions) mut => VT.[Friend]SetRange(&this, hAccessor, cStartKeyColumns, pStartData, cEndKeyColumns, pEndData, dwRangeOptions);
}

[CRepr]struct ICommand : IUnknown
{
	public new const Guid IID = .(0x0c733a63, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, DBPARAMS* pParams, int* pcRowsAffected, IUnknown** ppRowset) Execute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppSession) GetDBSession;
	}


	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Execute(IUnknown* pUnkOuter, in Guid riid, DBPARAMS* pParams, int* pcRowsAffected, IUnknown** ppRowset) mut => VT.[Friend]Execute(&this, pUnkOuter, riid, pParams, pcRowsAffected, ppRowset);

	public HRESULT GetDBSession(in Guid riid, IUnknown** ppSession) mut => VT.[Friend]GetDBSession(&this, riid, ppSession);
}

[CRepr]struct IMultipleResults : IUnknown
{
	public new const Guid IID = .(0x0c733a90, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, int lResultFlag, in Guid riid, int* pcRowsAffected, IUnknown** ppRowset) GetResult;
	}


	public HRESULT GetResult(IUnknown* pUnkOuter, int lResultFlag, in Guid riid, int* pcRowsAffected, IUnknown** ppRowset) mut => VT.[Friend]GetResult(&this, pUnkOuter, lResultFlag, riid, pcRowsAffected, ppRowset);
}

[CRepr]struct IConvertType : IUnknown
{
	public new const Guid IID = .(0x0c733a88, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wFromType, uint16 wToType, uint32 dwConvertFlags) CanConvert;
	}


	public HRESULT CanConvert(uint16 wFromType, uint16 wToType, uint32 dwConvertFlags) mut => VT.[Friend]CanConvert(&this, wFromType, wToType, dwConvertFlags);
}

[CRepr]struct ICommandPrepare : IUnknown
{
	public new const Guid IID = .(0x0c733a26, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExpectedRuns) Prepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unprepare;
	}


	public HRESULT Prepare(uint32 cExpectedRuns) mut => VT.[Friend]Prepare(&this, cExpectedRuns);

	public HRESULT Unprepare() mut => VT.[Friend]Unprepare(&this);
}

[CRepr]struct ICommandProperties : IUnknown
{
	public new const Guid IID = .(0x0c733a79, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertySets, DBPROPSET* rgPropertySets) SetProperties;
	}


	public HRESULT GetProperties(uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) mut => VT.[Friend]GetProperties(&this, cPropertyIDSets, rgPropertyIDSets, pcPropertySets, prgPropertySets);

	public HRESULT SetProperties(uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]SetProperties(&this, cPropertySets, rgPropertySets);
}

[CRepr]struct ICommandText : ICommand
{
	public new const Guid IID = .(0x0c733a27, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICommand.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidDialect, PWSTR* ppwszCommand) GetCommandText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidDialect, PWSTR pwszCommand) SetCommandText;
	}


	public HRESULT GetCommandText(Guid* pguidDialect, PWSTR* ppwszCommand) mut => VT.[Friend]GetCommandText(&this, pguidDialect, ppwszCommand);

	public HRESULT SetCommandText(in Guid rguidDialect, PWSTR pwszCommand) mut => VT.[Friend]SetCommandText(&this, rguidDialect, pwszCommand);
}

[CRepr]struct ICommandWithParameters : IUnknown
{
	public new const Guid IID = .(0x0c733a64, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcParams, DBPARAMINFO** prgParamInfo, uint16** ppNamesBuffer) GetParameterInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cParamNames, PWSTR* rgParamNames, int* rgParamOrdinals) MapParameterNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cParams, uint* rgParamOrdinals, DBPARAMBINDINFO* rgParamBindInfo) SetParameterInfo;
	}


	public HRESULT GetParameterInfo(uint* pcParams, DBPARAMINFO** prgParamInfo, uint16** ppNamesBuffer) mut => VT.[Friend]GetParameterInfo(&this, pcParams, prgParamInfo, ppNamesBuffer);

	public HRESULT MapParameterNames(uint cParamNames, PWSTR* rgParamNames, int* rgParamOrdinals) mut => VT.[Friend]MapParameterNames(&this, cParamNames, rgParamNames, rgParamOrdinals);

	public HRESULT SetParameterInfo(uint cParams, uint* rgParamOrdinals, DBPARAMBINDINFO* rgParamBindInfo) mut => VT.[Friend]SetParameterInfo(&this, cParams, rgParamOrdinals, rgParamBindInfo);
}

[CRepr]struct IColumnsRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a10, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcOptColumns, DBID** prgOptColumns) GetAvailableColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint cOptColumns, DBID* rgOptColumns, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppColRowset) GetColumnsRowset;
	}


	public HRESULT GetAvailableColumns(uint* pcOptColumns, DBID** prgOptColumns) mut => VT.[Friend]GetAvailableColumns(&this, pcOptColumns, prgOptColumns);

	public HRESULT GetColumnsRowset(IUnknown* pUnkOuter, uint cOptColumns, DBID* rgOptColumns, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppColRowset) mut => VT.[Friend]GetColumnsRowset(&this, pUnkOuter, cOptColumns, rgOptColumns, riid, cPropertySets, rgPropertySets, ppColRowset);
}

[CRepr]struct IColumnsInfo : IUnknown
{
	public new const Guid IID = .(0x0c733a11, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcColumns, DBCOLUMNINFO** prgInfo, uint16** ppStringsBuffer) GetColumnInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cColumnIDs, DBID* rgColumnIDs, uint* rgColumns) MapColumnIDs;
	}


	public HRESULT GetColumnInfo(uint* pcColumns, DBCOLUMNINFO** prgInfo, uint16** ppStringsBuffer) mut => VT.[Friend]GetColumnInfo(&this, pcColumns, prgInfo, ppStringsBuffer);

	public HRESULT MapColumnIDs(uint cColumnIDs, DBID* rgColumnIDs, uint* rgColumns) mut => VT.[Friend]MapColumnIDs(&this, cColumnIDs, rgColumnIDs, rgColumns);
}

[CRepr]struct IDBCreateCommand : IUnknown
{
	public new const Guid IID = .(0x0c733a1d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppCommand) CreateCommand;
	}


	public HRESULT CreateCommand(IUnknown* pUnkOuter, in Guid riid, IUnknown** ppCommand) mut => VT.[Friend]CreateCommand(&this, pUnkOuter, riid, ppCommand);
}

[CRepr]struct IDBCreateSession : IUnknown
{
	public new const Guid IID = .(0x0c733a5d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppDBSession) CreateSession;
	}


	public HRESULT CreateSession(IUnknown* pUnkOuter, in Guid riid, IUnknown** ppDBSession) mut => VT.[Friend]CreateSession(&this, pUnkOuter, riid, ppDBSession);
}

[CRepr]struct ISourcesRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a1e, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, uint32 cPropertySets, DBPROPSET* rgProperties, IUnknown** ppSourcesRowset) GetSourcesRowset;
	}


	public HRESULT GetSourcesRowset(IUnknown* pUnkOuter, in Guid riid, uint32 cPropertySets, DBPROPSET* rgProperties, IUnknown** ppSourcesRowset) mut => VT.[Friend]GetSourcesRowset(&this, pUnkOuter, riid, cPropertySets, rgProperties, ppSourcesRowset);
}

[CRepr]struct IDBProperties : IUnknown
{
	public new const Guid IID = .(0x0c733a8a, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertyInfoSets, DBPROPINFOSET** prgPropertyInfoSets, uint16** ppDescBuffer) GetPropertyInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertySets, DBPROPSET* rgPropertySets) SetProperties;
	}


	public HRESULT GetProperties(uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) mut => VT.[Friend]GetProperties(&this, cPropertyIDSets, rgPropertyIDSets, pcPropertySets, prgPropertySets);

	public HRESULT GetPropertyInfo(uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertyInfoSets, DBPROPINFOSET** prgPropertyInfoSets, uint16** ppDescBuffer) mut => VT.[Friend]GetPropertyInfo(&this, cPropertyIDSets, rgPropertyIDSets, pcPropertyInfoSets, prgPropertyInfoSets, ppDescBuffer);

	public HRESULT SetProperties(uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]SetProperties(&this, cPropertySets, rgPropertySets);
}

[CRepr]struct IDBInitialize : IUnknown
{
	public new const Guid IID = .(0x0c733a8b, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Uninitialize;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);

	public HRESULT Uninitialize() mut => VT.[Friend]Uninitialize(&this);
}

[CRepr]struct IDBInfo : IUnknown
{
	public new const Guid IID = .(0x0c733a89, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszKeywords) GetKeywords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cLiterals, uint32* rgLiterals, uint32* pcLiteralInfo, DBLITERALINFO** prgLiteralInfo, uint16** ppCharBuffer) GetLiteralInfo;
	}


	public HRESULT GetKeywords(PWSTR* ppwszKeywords) mut => VT.[Friend]GetKeywords(&this, ppwszKeywords);

	public HRESULT GetLiteralInfo(uint32 cLiterals, uint32* rgLiterals, uint32* pcLiteralInfo, DBLITERALINFO** prgLiteralInfo, uint16** ppCharBuffer) mut => VT.[Friend]GetLiteralInfo(&this, cLiterals, rgLiterals, pcLiteralInfo, prgLiteralInfo, ppCharBuffer);
}

[CRepr]struct IDBDataSourceAdmin : IUnknown
{
	public new const Guid IID = .(0x0c733a7a, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppDBSession) CreateDataSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DestroyDataSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertyInfoSets, DBPROPINFOSET** prgPropertyInfoSets, uint16** ppDescBuffer) GetCreationProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertySets, DBPROPSET* rgPropertySets) ModifyDataSource;
	}


	public HRESULT CreateDataSource(uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppDBSession) mut => VT.[Friend]CreateDataSource(&this, cPropertySets, rgPropertySets, pUnkOuter, riid, ppDBSession);

	public HRESULT DestroyDataSource() mut => VT.[Friend]DestroyDataSource(&this);

	public HRESULT GetCreationProperties(uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertyInfoSets, DBPROPINFOSET** prgPropertyInfoSets, uint16** ppDescBuffer) mut => VT.[Friend]GetCreationProperties(&this, cPropertyIDSets, rgPropertyIDSets, pcPropertyInfoSets, prgPropertyInfoSets, ppDescBuffer);

	public HRESULT ModifyDataSource(uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]ModifyDataSource(&this, cPropertySets, rgPropertySets);
}

[CRepr]struct IDBAsynchNotify : IUnknown
{
	public new const Guid IID = .(0x0c733a96, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint dwReserved) OnLowResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32 eOperation, uint ulProgress, uint ulProgressMax, uint32 eAsynchPhase, PWSTR pwszStatusText) OnProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32 eOperation, HRESULT hrStatus, PWSTR pwszStatusText) OnStop;
	}


	public HRESULT OnLowResource(uint dwReserved) mut => VT.[Friend]OnLowResource(&this, dwReserved);

	public HRESULT OnProgress(uint hChapter, uint32 eOperation, uint ulProgress, uint ulProgressMax, uint32 eAsynchPhase, PWSTR pwszStatusText) mut => VT.[Friend]OnProgress(&this, hChapter, eOperation, ulProgress, ulProgressMax, eAsynchPhase, pwszStatusText);

	public HRESULT OnStop(uint hChapter, uint32 eOperation, HRESULT hrStatus, PWSTR pwszStatusText) mut => VT.[Friend]OnStop(&this, hChapter, eOperation, hrStatus, pwszStatusText);
}

[CRepr]struct IDBAsynchStatus : IUnknown
{
	public new const Guid IID = .(0x0c733a95, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32 eOperation) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32 eOperation, uint* pulProgress, uint* pulProgressMax, uint32* peAsynchPhase, PWSTR* ppwszStatusText) GetStatus;
	}


	public HRESULT Abort(uint hChapter, uint32 eOperation) mut => VT.[Friend]Abort(&this, hChapter, eOperation);

	public HRESULT GetStatus(uint hChapter, uint32 eOperation, uint* pulProgress, uint* pulProgressMax, uint32* peAsynchPhase, PWSTR* ppwszStatusText) mut => VT.[Friend]GetStatus(&this, hChapter, eOperation, pulProgress, pulProgressMax, peAsynchPhase, ppwszStatusText);
}

[CRepr]struct ISessionProperties : IUnknown
{
	public new const Guid IID = .(0x0c733a85, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropertySets, DBPROPSET* rgPropertySets) SetProperties;
	}


	public HRESULT GetProperties(uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) mut => VT.[Friend]GetProperties(&this, cPropertyIDSets, rgPropertyIDSets, pcPropertySets, prgPropertySets);

	public HRESULT SetProperties(uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]SetProperties(&this, cPropertySets, rgPropertySets);
}

[CRepr]struct IIndexDefinition : IUnknown
{
	public new const Guid IID = .(0x0c733a68, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, DBID* pIndexID, uint cIndexColumnDescs, DBINDEXCOLUMNDESC* rgIndexColumnDescs, uint32 cPropertySets, DBPROPSET* rgPropertySets, DBID** ppIndexID) CreateIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, DBID* pIndexID) DropIndex;
	}


	public HRESULT CreateIndex(DBID* pTableID, DBID* pIndexID, uint cIndexColumnDescs, DBINDEXCOLUMNDESC* rgIndexColumnDescs, uint32 cPropertySets, DBPROPSET* rgPropertySets, DBID** ppIndexID) mut => VT.[Friend]CreateIndex(&this, pTableID, pIndexID, cIndexColumnDescs, rgIndexColumnDescs, cPropertySets, rgPropertySets, ppIndexID);

	public HRESULT DropIndex(DBID* pTableID, DBID* pIndexID) mut => VT.[Friend]DropIndex(&this, pTableID, pIndexID);
}

[CRepr]struct ITableDefinition : IUnknown
{
	public new const Guid IID = .(0x0c733a86, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, DBID* pTableID, uint cColumnDescs, DBCOLUMNDESC* rgColumnDescs, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, DBID** ppTableID, IUnknown** ppRowset) CreateTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID) DropTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, DBCOLUMNDESC* pColumnDesc, DBID** ppColumnID) AddColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, DBID* pColumnID) DropColumn;
	}


	public HRESULT CreateTable(IUnknown* pUnkOuter, DBID* pTableID, uint cColumnDescs, DBCOLUMNDESC* rgColumnDescs, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, DBID** ppTableID, IUnknown** ppRowset) mut => VT.[Friend]CreateTable(&this, pUnkOuter, pTableID, cColumnDescs, rgColumnDescs, riid, cPropertySets, rgPropertySets, ppTableID, ppRowset);

	public HRESULT DropTable(DBID* pTableID) mut => VT.[Friend]DropTable(&this, pTableID);

	public HRESULT AddColumn(DBID* pTableID, DBCOLUMNDESC* pColumnDesc, DBID** ppColumnID) mut => VT.[Friend]AddColumn(&this, pTableID, pColumnDesc, ppColumnID);

	public HRESULT DropColumn(DBID* pTableID, DBID* pColumnID) mut => VT.[Friend]DropColumn(&this, pTableID, pColumnID);
}

[CRepr]struct IOpenRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a69, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, DBID* pTableID, DBID* pIndexID, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) OpenRowset;
	}


	public HRESULT OpenRowset(IUnknown* pUnkOuter, DBID* pTableID, DBID* pIndexID, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) mut => VT.[Friend]OpenRowset(&this, pUnkOuter, pTableID, pIndexID, riid, cPropertySets, rgPropertySets, ppRowset);
}

[CRepr]struct IDBSchemaRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a7b, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid rguidSchema, uint32 cRestrictions, VARIANT* rgRestrictions, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) GetRowset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcSchemas, Guid** prgSchemas, uint32** prgRestrictionSupport) GetSchemas;
	}


	public HRESULT GetRowset(IUnknown* pUnkOuter, in Guid rguidSchema, uint32 cRestrictions, VARIANT* rgRestrictions, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) mut => VT.[Friend]GetRowset(&this, pUnkOuter, rguidSchema, cRestrictions, rgRestrictions, riid, cPropertySets, rgPropertySets, ppRowset);

	public HRESULT GetSchemas(uint32* pcSchemas, Guid** prgSchemas, uint32** prgRestrictionSupport) mut => VT.[Friend]GetSchemas(&this, pcSchemas, prgSchemas, prgRestrictionSupport);
}

[CRepr]struct IMDDataset : IUnknown
{
	public new const Guid IID = .(0xa07cccd1, 0x8148, 0x11d0, 0x87, 0xbb, 0x00, 0xc0, 0x4f, 0xc3, 0x39, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cAxes, MDAXISINFO* rgAxisInfo) FreeAxisInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcAxes, MDAXISINFO** prgAxisInfo) GetAxisInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint iAxis, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) GetAxisRowset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, uint ulStartCell, uint ulEndCell, void* pData) GetCellData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppSpecification) GetSpecification;
	}


	public HRESULT FreeAxisInfo(uint cAxes, MDAXISINFO* rgAxisInfo) mut => VT.[Friend]FreeAxisInfo(&this, cAxes, rgAxisInfo);

	public HRESULT GetAxisInfo(uint* pcAxes, MDAXISINFO** prgAxisInfo) mut => VT.[Friend]GetAxisInfo(&this, pcAxes, prgAxisInfo);

	public HRESULT GetAxisRowset(IUnknown* pUnkOuter, uint iAxis, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) mut => VT.[Friend]GetAxisRowset(&this, pUnkOuter, iAxis, riid, cPropertySets, rgPropertySets, ppRowset);

	public HRESULT GetCellData(HACCESSOR hAccessor, uint ulStartCell, uint ulEndCell, void* pData) mut => VT.[Friend]GetCellData(&this, hAccessor, ulStartCell, ulEndCell, pData);

	public HRESULT GetSpecification(in Guid riid, IUnknown** ppSpecification) mut => VT.[Friend]GetSpecification(&this, riid, ppSpecification);
}

[CRepr]struct IMDFind : IUnknown
{
	public new const Guid IID = .(0xa07cccd2, 0x8148, 0x11d0, 0x87, 0xbb, 0x00, 0xc0, 0x4f, 0xc3, 0x39, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ulStartingOrdinal, uint cMembers, PWSTR* rgpwszMember, uint* pulCellOrdinal) FindCell;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulAxisIdentifier, uint ulStartingOrdinal, uint cMembers, PWSTR* rgpwszMember, uint32* pulTupleOrdinal) FindTuple;
	}


	public HRESULT FindCell(uint ulStartingOrdinal, uint cMembers, PWSTR* rgpwszMember, uint* pulCellOrdinal) mut => VT.[Friend]FindCell(&this, ulStartingOrdinal, cMembers, rgpwszMember, pulCellOrdinal);

	public HRESULT FindTuple(uint32 ulAxisIdentifier, uint ulStartingOrdinal, uint cMembers, PWSTR* rgpwszMember, uint32* pulTupleOrdinal) mut => VT.[Friend]FindTuple(&this, ulAxisIdentifier, ulStartingOrdinal, cMembers, rgpwszMember, pulTupleOrdinal);
}

[CRepr]struct IMDRangeRowset : IUnknown
{
	public new const Guid IID = .(0x0c733aa0, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint ulStartCell, uint ulEndCell, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) GetRangeRowset;
	}


	public HRESULT GetRangeRowset(IUnknown* pUnkOuter, uint ulStartCell, uint ulEndCell, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) mut => VT.[Friend]GetRangeRowset(&this, pUnkOuter, ulStartCell, ulEndCell, riid, cPropertySets, rgPropertySets, ppRowset);
}

[CRepr]struct IAlterTable : IUnknown
{
	public new const Guid IID = .(0x0c733aa5, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableId, DBID* pColumnId, uint32 dwColumnDescFlags, DBCOLUMNDESC* pColumnDesc) AlterColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableId, DBID* pNewTableId, uint32 cPropertySets, DBPROPSET* rgPropertySets) AlterTable;
	}


	public HRESULT AlterColumn(DBID* pTableId, DBID* pColumnId, uint32 dwColumnDescFlags, DBCOLUMNDESC* pColumnDesc) mut => VT.[Friend]AlterColumn(&this, pTableId, pColumnId, dwColumnDescFlags, pColumnDesc);

	public HRESULT AlterTable(DBID* pTableId, DBID* pNewTableId, uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]AlterTable(&this, pTableId, pNewTableId, cPropertySets, rgPropertySets);
}

[CRepr]struct IAlterIndex : IUnknown
{
	public new const Guid IID = .(0x0c733aa6, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableId, DBID* pIndexId, DBID* pNewIndexId, uint32 cPropertySets, DBPROPSET* rgPropertySets) AlterIndex;
	}


	public HRESULT AlterIndex(DBID* pTableId, DBID* pIndexId, DBID* pNewIndexId, uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]AlterIndex(&this, pTableId, pIndexId, pNewIndexId, cPropertySets, rgPropertySets);
}

[CRepr]struct IRowsetChapterMember : IUnknown
{
	public new const Guid IID = .(0x0c733aa8, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint hRow) IsRowInChapter;
	}


	public HRESULT IsRowInChapter(uint hChapter, uint hRow) mut => VT.[Friend]IsRowInChapter(&this, hChapter, hRow);
}

[CRepr]struct ICommandPersist : IUnknown
{
	public new const Guid IID = .(0x0c733aa7, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pCommandID) DeleteCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID** ppCommandID) GetCurrentCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pCommandID, uint32 dwFlags) LoadCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pCommandID, uint32 dwFlags) SaveCommand;
	}


	public HRESULT DeleteCommand(DBID* pCommandID) mut => VT.[Friend]DeleteCommand(&this, pCommandID);

	public HRESULT GetCurrentCommand(DBID** ppCommandID) mut => VT.[Friend]GetCurrentCommand(&this, ppCommandID);

	public HRESULT LoadCommand(DBID* pCommandID, uint32 dwFlags) mut => VT.[Friend]LoadCommand(&this, pCommandID, dwFlags);

	public HRESULT SaveCommand(DBID* pCommandID, uint32 dwFlags) mut => VT.[Friend]SaveCommand(&this, pCommandID, dwFlags);
}

[CRepr]struct IRowsetRefresh : IUnknown
{
	public new const Guid IID = .(0x0c733aa9, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint cRows, uint* rghRows, BOOL fOverWrite, uint* pcRowsRefreshed, uint** prghRowsRefreshed, uint32** prgRowStatus) RefreshVisibleData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRow, HACCESSOR hAccessor, void* pData) GetLastVisibleData;
	}


	public HRESULT RefreshVisibleData(uint hChapter, uint cRows, uint* rghRows, BOOL fOverWrite, uint* pcRowsRefreshed, uint** prghRowsRefreshed, uint32** prgRowStatus) mut => VT.[Friend]RefreshVisibleData(&this, hChapter, cRows, rghRows, fOverWrite, pcRowsRefreshed, prghRowsRefreshed, prgRowStatus);

	public HRESULT GetLastVisibleData(uint hRow, HACCESSOR hAccessor, void* pData) mut => VT.[Friend]GetLastVisibleData(&this, hRow, hAccessor, pData);
}

[CRepr]struct IParentRowset : IUnknown
{
	public new const Guid IID = .(0x0c733aaa, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint iOrdinal, in Guid riid, IUnknown** ppRowset) GetChildRowset;
	}


	public HRESULT GetChildRowset(IUnknown* pUnkOuter, uint iOrdinal, in Guid riid, IUnknown** ppRowset) mut => VT.[Friend]GetChildRowset(&this, pUnkOuter, iOrdinal, riid, ppRowset);
}

[CRepr]struct IErrorRecords : IUnknown
{
	public new const Guid IID = .(0x0c733a67, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ERRORINFO* pErrorInfo, uint32 dwLookupID, DISPPARAMS* pdispparams, IUnknown* punkCustomError, uint32 dwDynamicErrorID) AddErrorRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulRecordNum, ERRORINFO* pErrorInfo) GetBasicErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulRecordNum, in Guid riid, IUnknown** ppObject) GetCustomErrorObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulRecordNum, uint32 lcid, IErrorInfo** ppErrorInfo) GetErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulRecordNum, DISPPARAMS* pdispparams) GetErrorParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcRecords) GetRecordCount;
	}


	public HRESULT AddErrorRecord(ERRORINFO* pErrorInfo, uint32 dwLookupID, DISPPARAMS* pdispparams, IUnknown* punkCustomError, uint32 dwDynamicErrorID) mut => VT.[Friend]AddErrorRecord(&this, pErrorInfo, dwLookupID, pdispparams, punkCustomError, dwDynamicErrorID);

	public HRESULT GetBasicErrorInfo(uint32 ulRecordNum, ERRORINFO* pErrorInfo) mut => VT.[Friend]GetBasicErrorInfo(&this, ulRecordNum, pErrorInfo);

	public HRESULT GetCustomErrorObject(uint32 ulRecordNum, in Guid riid, IUnknown** ppObject) mut => VT.[Friend]GetCustomErrorObject(&this, ulRecordNum, riid, ppObject);

	public HRESULT GetErrorInfo(uint32 ulRecordNum, uint32 lcid, IErrorInfo** ppErrorInfo) mut => VT.[Friend]GetErrorInfo(&this, ulRecordNum, lcid, ppErrorInfo);

	public HRESULT GetErrorParameters(uint32 ulRecordNum, DISPPARAMS* pdispparams) mut => VT.[Friend]GetErrorParameters(&this, ulRecordNum, pdispparams);

	public HRESULT GetRecordCount(uint32* pcRecords) mut => VT.[Friend]GetRecordCount(&this, pcRecords);
}

[CRepr]struct IErrorLookup : IUnknown
{
	public new const Guid IID = .(0x0c733a66, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrError, uint32 dwLookupID, DISPPARAMS* pdispparams, uint32 lcid, BSTR* pbstrSource, BSTR* pbstrDescription) GetErrorDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrError, uint32 dwLookupID, uint32 lcid, BSTR* pbstrHelpFile, uint32* pdwHelpContext) GetHelpInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDynamicErrorID) ReleaseErrors;
	}


	public HRESULT GetErrorDescription(HRESULT hrError, uint32 dwLookupID, DISPPARAMS* pdispparams, uint32 lcid, BSTR* pbstrSource, BSTR* pbstrDescription) mut => VT.[Friend]GetErrorDescription(&this, hrError, dwLookupID, pdispparams, lcid, pbstrSource, pbstrDescription);

	public HRESULT GetHelpInfo(HRESULT hrError, uint32 dwLookupID, uint32 lcid, BSTR* pbstrHelpFile, uint32* pdwHelpContext) mut => VT.[Friend]GetHelpInfo(&this, hrError, dwLookupID, lcid, pbstrHelpFile, pdwHelpContext);

	public HRESULT ReleaseErrors(uint32 dwDynamicErrorID) mut => VT.[Friend]ReleaseErrors(&this, dwDynamicErrorID);
}

[CRepr]struct ISQLErrorInfo : IUnknown
{
	public new const Guid IID = .(0x0c733a74, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSQLState, int32* plNativeError) GetSQLInfo;
	}


	public HRESULT GetSQLInfo(BSTR* pbstrSQLState, int32* plNativeError) mut => VT.[Friend]GetSQLInfo(&this, pbstrSQLState, plNativeError);
}

[CRepr]struct IGetDataSource : IUnknown
{
	public new const Guid IID = .(0x0c733a75, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppDataSource) GetDataSource;
	}


	public HRESULT GetDataSource(in Guid riid, IUnknown** ppDataSource) mut => VT.[Friend]GetDataSource(&this, riid, ppDataSource);
}

[CRepr]struct ITransactionLocal : ITransaction
{
	public new const Guid IID = .(0x0c733a5f, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITransaction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionOptions** ppOptions) GetOptionsObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOtherOptions, uint32* pulTransactionLevel) StartTransaction;
	}


	public HRESULT GetOptionsObject(ITransactionOptions** ppOptions) mut => VT.[Friend]GetOptionsObject(&this, ppOptions);

	public HRESULT StartTransaction(int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOtherOptions, uint32* pulTransactionLevel) mut => VT.[Friend]StartTransaction(&this, isoLevel, isoFlags, pOtherOptions, pulTransactionLevel);
}

[CRepr]struct ITransactionJoin : IUnknown
{
	public new const Guid IID = .(0x0c733a5e, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionOptions** ppOptions) GetOptionsObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkTransactionCoord, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOtherOptions) JoinTransaction;
	}


	public HRESULT GetOptionsObject(ITransactionOptions** ppOptions) mut => VT.[Friend]GetOptionsObject(&this, ppOptions);

	public HRESULT JoinTransaction(IUnknown* punkTransactionCoord, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOtherOptions) mut => VT.[Friend]JoinTransaction(&this, punkTransactionCoord, isoLevel, isoFlags, pOtherOptions);
}

[CRepr]struct ITransactionObject : IUnknown
{
	public new const Guid IID = .(0x0c733a60, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulTransactionLevel, ITransaction** ppTransactionObject) GetTransactionObject;
	}


	public HRESULT GetTransactionObject(uint32 ulTransactionLevel, ITransaction** ppTransactionObject) mut => VT.[Friend]GetTransactionObject(&this, ulTransactionLevel, ppTransactionObject);
}

[CRepr]struct ITrusteeAdmin : IUnknown
{
	public new const Guid IID = .(0x0c733aa1, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pTrustee1, TRUSTEE_W* pTrustee2) CompareTrustees;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pTrustee, uint32 cPropertySets, DBPROPSET* rgPropertySets) CreateTrustee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pTrustee) DeleteTrustee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pTrustee, uint32 cPropertySets, DBPROPSET* rgPropertySets) SetTrusteeProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pTrustee, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) GetTrusteeProperties;
	}


	public HRESULT CompareTrustees(TRUSTEE_W* pTrustee1, TRUSTEE_W* pTrustee2) mut => VT.[Friend]CompareTrustees(&this, pTrustee1, pTrustee2);

	public HRESULT CreateTrustee(TRUSTEE_W* pTrustee, uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]CreateTrustee(&this, pTrustee, cPropertySets, rgPropertySets);

	public HRESULT DeleteTrustee(TRUSTEE_W* pTrustee) mut => VT.[Friend]DeleteTrustee(&this, pTrustee);

	public HRESULT SetTrusteeProperties(TRUSTEE_W* pTrustee, uint32 cPropertySets, DBPROPSET* rgPropertySets) mut => VT.[Friend]SetTrusteeProperties(&this, pTrustee, cPropertySets, rgPropertySets);

	public HRESULT GetTrusteeProperties(TRUSTEE_W* pTrustee, uint32 cPropertyIDSets, DBPROPIDSET* rgPropertyIDSets, uint32* pcPropertySets, DBPROPSET** prgPropertySets) mut => VT.[Friend]GetTrusteeProperties(&this, pTrustee, cPropertyIDSets, rgPropertyIDSets, pcPropertySets, prgPropertySets);
}

[CRepr]struct ITrusteeGroupAdmin : IUnknown
{
	public new const Guid IID = .(0x0c733aa2, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pMembershipTrustee, TRUSTEE_W* pMemberTrustee) AddMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pMembershipTrustee, TRUSTEE_W* pMemberTrustee) DeleteMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pMembershipTrustee, TRUSTEE_W* pMemberTrustee, BOOL* pfStatus) IsMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pMembershipTrustee, uint32* pcMembers, TRUSTEE_W** prgMembers) GetMembers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W* pTrustee, uint32* pcMemberships, TRUSTEE_W** prgMemberships) GetMemberships;
	}


	public HRESULT AddMember(TRUSTEE_W* pMembershipTrustee, TRUSTEE_W* pMemberTrustee) mut => VT.[Friend]AddMember(&this, pMembershipTrustee, pMemberTrustee);

	public HRESULT DeleteMember(TRUSTEE_W* pMembershipTrustee, TRUSTEE_W* pMemberTrustee) mut => VT.[Friend]DeleteMember(&this, pMembershipTrustee, pMemberTrustee);

	public HRESULT IsMember(TRUSTEE_W* pMembershipTrustee, TRUSTEE_W* pMemberTrustee, BOOL* pfStatus) mut => VT.[Friend]IsMember(&this, pMembershipTrustee, pMemberTrustee, pfStatus);

	public HRESULT GetMembers(TRUSTEE_W* pMembershipTrustee, uint32* pcMembers, TRUSTEE_W** prgMembers) mut => VT.[Friend]GetMembers(&this, pMembershipTrustee, pcMembers, prgMembers);

	public HRESULT GetMemberships(TRUSTEE_W* pTrustee, uint32* pcMemberships, TRUSTEE_W** prgMemberships) mut => VT.[Friend]GetMemberships(&this, pTrustee, pcMemberships, prgMemberships);
}

[CRepr]struct IObjectAccessControl : IUnknown
{
	public new const Guid IID = .(0x0c733aa3, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEC_OBJECT* pObject, uint32* pcAccessEntries, EXPLICIT_ACCESS_W** prgAccessEntries) GetObjectAccessRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEC_OBJECT* pObject, TRUSTEE_W** ppOwner) GetObjectOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEC_OBJECT* pObject, EXPLICIT_ACCESS_W* pAccessEntry, BOOL* pfResult) IsObjectAccessAllowed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEC_OBJECT* pObject, uint32 cAccessEntries, EXPLICIT_ACCESS_W* prgAccessEntries) SetObjectAccessRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEC_OBJECT* pObject, TRUSTEE_W* pOwner) SetObjectOwner;
	}


	public HRESULT GetObjectAccessRights(SEC_OBJECT* pObject, uint32* pcAccessEntries, EXPLICIT_ACCESS_W** prgAccessEntries) mut => VT.[Friend]GetObjectAccessRights(&this, pObject, pcAccessEntries, prgAccessEntries);

	public HRESULT GetObjectOwner(SEC_OBJECT* pObject, TRUSTEE_W** ppOwner) mut => VT.[Friend]GetObjectOwner(&this, pObject, ppOwner);

	public HRESULT IsObjectAccessAllowed(SEC_OBJECT* pObject, EXPLICIT_ACCESS_W* pAccessEntry, BOOL* pfResult) mut => VT.[Friend]IsObjectAccessAllowed(&this, pObject, pAccessEntry, pfResult);

	public HRESULT SetObjectAccessRights(SEC_OBJECT* pObject, uint32 cAccessEntries, EXPLICIT_ACCESS_W* prgAccessEntries) mut => VT.[Friend]SetObjectAccessRights(&this, pObject, cAccessEntries, prgAccessEntries);

	public HRESULT SetObjectOwner(SEC_OBJECT* pObject, TRUSTEE_W* pOwner) mut => VT.[Friend]SetObjectOwner(&this, pObject, pOwner);
}

[CRepr]struct ISecurityInfo : IUnknown
{
	public new const Guid IID = .(0x0c733aa4, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TRUSTEE_W** ppTrustee) GetCurrentTrustee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cObjectTypes, Guid** rgObjectTypes) GetObjectTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ObjectType, uint32* pPermissions) GetPermissions;
	}


	public HRESULT GetCurrentTrustee(TRUSTEE_W** ppTrustee) mut => VT.[Friend]GetCurrentTrustee(&this, ppTrustee);

	public HRESULT GetObjectTypes(uint32* cObjectTypes, Guid** rgObjectTypes) mut => VT.[Friend]GetObjectTypes(&this, cObjectTypes, rgObjectTypes);

	public HRESULT GetPermissions(Guid ObjectType, uint32* pPermissions) mut => VT.[Friend]GetPermissions(&this, ObjectType, pPermissions);
}

[CRepr]struct ITableCreation : ITableDefinition
{
	public new const Guid IID = .(0x0c733abc, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITableDefinition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, uint* pcColumnDescs, DBCOLUMNDESC** prgColumnDescs, uint32* pcPropertySets, DBPROPSET** prgPropertySets, uint32* pcConstraintDescs, DBCONSTRAINTDESC** prgConstraintDescs, uint16** ppwszStringBuffer) GetTableDefinition;
	}


	public HRESULT GetTableDefinition(DBID* pTableID, uint* pcColumnDescs, DBCOLUMNDESC** prgColumnDescs, uint32* pcPropertySets, DBPROPSET** prgPropertySets, uint32* pcConstraintDescs, DBCONSTRAINTDESC** prgConstraintDescs, uint16** ppwszStringBuffer) mut => VT.[Friend]GetTableDefinition(&this, pTableID, pcColumnDescs, prgColumnDescs, pcPropertySets, prgPropertySets, pcConstraintDescs, prgConstraintDescs, ppwszStringBuffer);
}

[CRepr]struct ITableDefinitionWithConstraints : ITableCreation
{
	public new const Guid IID = .(0x0c733aab, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITableCreation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, DBCONSTRAINTDESC* pConstraintDesc) AddConstraint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, DBID* pTableID, uint cColumnDescs, DBCOLUMNDESC* rgColumnDescs, uint32 cConstraintDescs, DBCONSTRAINTDESC* rgConstraintDescs, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, DBID** ppTableID, IUnknown** ppRowset) CreateTableWithConstraints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, DBID* pConstraintID) DropConstraint;
	}


	public HRESULT AddConstraint(DBID* pTableID, DBCONSTRAINTDESC* pConstraintDesc) mut => VT.[Friend]AddConstraint(&this, pTableID, pConstraintDesc);

	public HRESULT CreateTableWithConstraints(IUnknown* pUnkOuter, DBID* pTableID, uint cColumnDescs, DBCOLUMNDESC* rgColumnDescs, uint32 cConstraintDescs, DBCONSTRAINTDESC* rgConstraintDescs, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, DBID** ppTableID, IUnknown** ppRowset) mut => VT.[Friend]CreateTableWithConstraints(&this, pUnkOuter, pTableID, cColumnDescs, rgColumnDescs, cConstraintDescs, rgConstraintDescs, riid, cPropertySets, rgPropertySets, ppTableID, ppRowset);

	public HRESULT DropConstraint(DBID* pTableID, DBID* pConstraintID) mut => VT.[Friend]DropConstraint(&this, pTableID, pConstraintID);
}

[CRepr]struct IRow : IUnknown
{
	public new const Guid IID = .(0x0c733ab4, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cColumns, DBCOLUMNACCESS* rgColumns) GetColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppRowset, uint* phRow) GetSourceRowset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, DBID* pColumnID, in Guid rguidColumnType, uint32 dwBindFlags, in Guid riid, IUnknown** ppUnk) Open;
	}


	public HRESULT GetColumns(uint cColumns, DBCOLUMNACCESS* rgColumns) mut => VT.[Friend]GetColumns(&this, cColumns, rgColumns);

	public HRESULT GetSourceRowset(in Guid riid, IUnknown** ppRowset, uint* phRow) mut => VT.[Friend]GetSourceRowset(&this, riid, ppRowset, phRow);

	public HRESULT Open(IUnknown* pUnkOuter, DBID* pColumnID, in Guid rguidColumnType, uint32 dwBindFlags, in Guid riid, IUnknown** ppUnk) mut => VT.[Friend]Open(&this, pUnkOuter, pColumnID, rguidColumnType, dwBindFlags, riid, ppUnk);
}

[CRepr]struct IRowChange : IUnknown
{
	public new const Guid IID = .(0x0c733ab5, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cColumns, DBCOLUMNACCESS* rgColumns) SetColumns;
	}


	public HRESULT SetColumns(uint cColumns, DBCOLUMNACCESS* rgColumns) mut => VT.[Friend]SetColumns(&this, cColumns, rgColumns);
}

[CRepr]struct IRowSchemaChange : IRowChange
{
	public new const Guid IID = .(0x0c733aae, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRowChange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cColumns, DBID* rgColumnIDs, uint32* rgdwStatus) DeleteColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cColumns, DBCOLUMNINFO* rgNewColumnInfo, DBCOLUMNACCESS* rgColumns) AddColumns;
	}


	public HRESULT DeleteColumns(uint cColumns, DBID* rgColumnIDs, uint32* rgdwStatus) mut => VT.[Friend]DeleteColumns(&this, cColumns, rgColumnIDs, rgdwStatus);

	public HRESULT AddColumns(uint cColumns, DBCOLUMNINFO* rgNewColumnInfo, DBCOLUMNACCESS* rgColumns) mut => VT.[Friend]AddColumns(&this, cColumns, rgNewColumnInfo, rgColumns);
}

[CRepr]struct IGetRow : IUnknown
{
	public new const Guid IID = .(0x0c733aaf, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint hRow, in Guid riid, IUnknown** ppUnk) GetRowFromHROW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRow, PWSTR* ppwszURL) GetURLFromHROW;
	}


	public HRESULT GetRowFromHROW(IUnknown* pUnkOuter, uint hRow, in Guid riid, IUnknown** ppUnk) mut => VT.[Friend]GetRowFromHROW(&this, pUnkOuter, hRow, riid, ppUnk);

	public HRESULT GetURLFromHROW(uint hRow, PWSTR* ppwszURL) mut => VT.[Friend]GetURLFromHROW(&this, hRow, ppwszURL);
}

[CRepr]struct IBindResource : IUnknown
{
	public new const Guid IID = .(0x0c733ab1, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, PWSTR pwszURL, uint32 dwBindURLFlags, in Guid rguid, in Guid riid, IAuthenticate* pAuthenticate, DBIMPLICITSESSION* pImplSession, uint32* pdwBindStatus, IUnknown** ppUnk) Bind;
	}


	public HRESULT Bind(IUnknown* pUnkOuter, PWSTR pwszURL, uint32 dwBindURLFlags, in Guid rguid, in Guid riid, IAuthenticate* pAuthenticate, DBIMPLICITSESSION* pImplSession, uint32* pdwBindStatus, IUnknown** ppUnk) mut => VT.[Friend]Bind(&this, pUnkOuter, pwszURL, dwBindURLFlags, rguid, riid, pAuthenticate, pImplSession, pdwBindStatus, ppUnk);
}

[CRepr]struct IScopedOperations : IBindResource
{
	public new const Guid IID = .(0x0c733ab0, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBindResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cRows, PWSTR* rgpwszSourceURLs, PWSTR* rgpwszDestURLs, uint32 dwCopyFlags, IAuthenticate* pAuthenticate, uint32* rgdwStatus, PWSTR* rgpwszNewURLs, uint16** ppStringsBuffer) Copy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cRows, PWSTR* rgpwszSourceURLs, PWSTR* rgpwszDestURLs, uint32 dwMoveFlags, IAuthenticate* pAuthenticate, uint32* rgdwStatus, PWSTR* rgpwszNewURLs, uint16** ppStringsBuffer) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cRows, PWSTR* rgpwszURLs, uint32 dwDeleteFlags, uint32* rgdwStatus) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, DBID* pTableID, DBID* pIndexID, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) OpenRowset;
	}


	public HRESULT Copy(uint cRows, PWSTR* rgpwszSourceURLs, PWSTR* rgpwszDestURLs, uint32 dwCopyFlags, IAuthenticate* pAuthenticate, uint32* rgdwStatus, PWSTR* rgpwszNewURLs, uint16** ppStringsBuffer) mut => VT.[Friend]Copy(&this, cRows, rgpwszSourceURLs, rgpwszDestURLs, dwCopyFlags, pAuthenticate, rgdwStatus, rgpwszNewURLs, ppStringsBuffer);

	public HRESULT Move(uint cRows, PWSTR* rgpwszSourceURLs, PWSTR* rgpwszDestURLs, uint32 dwMoveFlags, IAuthenticate* pAuthenticate, uint32* rgdwStatus, PWSTR* rgpwszNewURLs, uint16** ppStringsBuffer) mut => VT.[Friend]Move(&this, cRows, rgpwszSourceURLs, rgpwszDestURLs, dwMoveFlags, pAuthenticate, rgdwStatus, rgpwszNewURLs, ppStringsBuffer);

	public HRESULT Delete(uint cRows, PWSTR* rgpwszURLs, uint32 dwDeleteFlags, uint32* rgdwStatus) mut => VT.[Friend]Delete(&this, cRows, rgpwszURLs, dwDeleteFlags, rgdwStatus);

	public HRESULT OpenRowset(IUnknown* pUnkOuter, DBID* pTableID, DBID* pIndexID, in Guid riid, uint32 cPropertySets, DBPROPSET* rgPropertySets, IUnknown** ppRowset) mut => VT.[Friend]OpenRowset(&this, pUnkOuter, pTableID, pIndexID, riid, cPropertySets, rgPropertySets, ppRowset);
}

[CRepr]struct ICreateRow : IUnknown
{
	public new const Guid IID = .(0x0c733ab2, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, PWSTR pwszURL, uint32 dwBindURLFlags, in Guid rguid, in Guid riid, IAuthenticate* pAuthenticate, DBIMPLICITSESSION* pImplSession, uint32* pdwBindStatus, PWSTR* ppwszNewURL, IUnknown** ppUnk) CreateRow;
	}


	public HRESULT CreateRow(IUnknown* pUnkOuter, PWSTR pwszURL, uint32 dwBindURLFlags, in Guid rguid, in Guid riid, IAuthenticate* pAuthenticate, DBIMPLICITSESSION* pImplSession, uint32* pdwBindStatus, PWSTR* ppwszNewURL, IUnknown** ppUnk) mut => VT.[Friend]CreateRow(&this, pUnkOuter, pwszURL, dwBindURLFlags, rguid, riid, pAuthenticate, pImplSession, pdwBindStatus, ppwszNewURL, ppUnk);
}

[CRepr]struct IDBBinderProperties : IDBProperties
{
	public new const Guid IID = .(0x0c733ab3, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDBProperties.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IColumnsInfo2 : IColumnsInfo
{
	public new const Guid IID = .(0x0c733ab8, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IColumnsInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint cColumnIDMasks, DBID* rgColumnIDMasks, uint32 dwFlags, uint* pcColumns, DBID** prgColumnIDs, DBCOLUMNINFO** prgColumnInfo, uint16** ppStringsBuffer) GetRestrictedColumnInfo;
	}


	public HRESULT GetRestrictedColumnInfo(uint cColumnIDMasks, DBID* rgColumnIDMasks, uint32 dwFlags, uint* pcColumns, DBID** prgColumnIDs, DBCOLUMNINFO** prgColumnInfo, uint16** ppStringsBuffer) mut => VT.[Friend]GetRestrictedColumnInfo(&this, cColumnIDMasks, rgColumnIDMasks, dwFlags, pcColumns, prgColumnIDs, prgColumnInfo, ppStringsBuffer);
}

[CRepr]struct IRegisterProvider : IUnknown
{
	public new const Guid IID = .(0x0c733ab9, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, uint dwReserved, Guid* pclsidProvider) GetURLMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, uint dwReserved, Guid* rclsidProvider) SetURLMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, uint dwReserved, Guid* rclsidProvider) UnregisterProvider;
	}


	public HRESULT GetURLMapping(PWSTR pwszURL, uint dwReserved, Guid* pclsidProvider) mut => VT.[Friend]GetURLMapping(&this, pwszURL, dwReserved, pclsidProvider);

	public HRESULT SetURLMapping(PWSTR pwszURL, uint dwReserved, Guid* rclsidProvider) mut => VT.[Friend]SetURLMapping(&this, pwszURL, dwReserved, rclsidProvider);

	public HRESULT UnregisterProvider(PWSTR pwszURL, uint dwReserved, Guid* rclsidProvider) mut => VT.[Friend]UnregisterProvider(&this, pwszURL, dwReserved, rclsidProvider);
}

[CRepr]struct IGetSession : IUnknown
{
	public new const Guid IID = .(0x0c733aba, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppSession) GetSession;
	}


	public HRESULT GetSession(in Guid riid, IUnknown** ppSession) mut => VT.[Friend]GetSession(&this, riid, ppSession);
}

[CRepr]struct IGetSourceRow : IUnknown
{
	public new const Guid IID = .(0x0c733abb, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppRow) GetSourceRow;
	}


	public HRESULT GetSourceRow(in Guid riid, IUnknown** ppRow) mut => VT.[Friend]GetSourceRow(&this, riid, ppRow);
}

[CRepr]struct IRowsetCurrentIndex : IRowsetIndex
{
	public new const Guid IID = .(0x0c733abd, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRowsetIndex.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID** ppIndexID) GetIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pIndexID) SetIndex;
	}


	public HRESULT GetIndex(DBID** ppIndexID) mut => VT.[Friend]GetIndex(&this, ppIndexID);

	public HRESULT SetIndex(DBID* pIndexID) mut => VT.[Friend]SetIndex(&this, pIndexID);
}

[CRepr]struct ICommandStream : IUnknown
{
	public new const Guid IID = .(0x0c733abf, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* piid, Guid* pguidDialect, IUnknown** ppCommandStream) GetCommandStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, in Guid rguidDialect, IUnknown* pCommandStream) SetCommandStream;
	}


	public HRESULT GetCommandStream(Guid* piid, Guid* pguidDialect, IUnknown** ppCommandStream) mut => VT.[Friend]GetCommandStream(&this, piid, pguidDialect, ppCommandStream);

	public HRESULT SetCommandStream(in Guid riid, in Guid rguidDialect, IUnknown* pCommandStream) mut => VT.[Friend]SetCommandStream(&this, riid, rguidDialect, pCommandStream);
}

[CRepr]struct IRowsetBookmark : IUnknown
{
	public new const Guid IID = .(0x0c733ac2, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint cbBookmark, uint8* pBookmark) PositionOnBookmark;
	}


	public HRESULT PositionOnBookmark(uint hChapter, uint cbBookmark, uint8* pBookmark) mut => VT.[Friend]PositionOnBookmark(&this, hChapter, cbBookmark, pBookmark);
}

[CRepr]struct IQueryParser : IUnknown
{
	public new const Guid IID = .(0x2ebdee67, 0x3505, 0x43f8, 0x99, 0x46, 0xea, 0x44, 0xab, 0xc8, 0xe5, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszInputString, IEnumUnknown* pCustomProperties, IQuerySolution** ppSolution) Parse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STRUCTURED_QUERY_SINGLE_OPTION option, PROPVARIANT* pOptionValue) SetOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STRUCTURED_QUERY_SINGLE_OPTION option, PROPVARIANT* pOptionValue) GetOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STRUCTURED_QUERY_MULTIOPTION option, PWSTR pszOptionKey, PROPVARIANT* pOptionValue) SetMultiOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISchemaProvider** ppSchemaProvider) GetSchemaProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pCondition, BOOL fUseEnglish, PWSTR* ppszQueryString) RestateToString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, PWSTR pszInputString, IQuerySolution** ppSolution) ParsePropertyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pCondition, BOOL fUseEnglish, PWSTR* ppszPropertyName, PWSTR* ppszQueryString) RestatePropertyValueToString;
	}


	public HRESULT Parse(PWSTR pszInputString, IEnumUnknown* pCustomProperties, IQuerySolution** ppSolution) mut => VT.[Friend]Parse(&this, pszInputString, pCustomProperties, ppSolution);

	public HRESULT SetOption(STRUCTURED_QUERY_SINGLE_OPTION option, PROPVARIANT* pOptionValue) mut => VT.[Friend]SetOption(&this, option, pOptionValue);

	public HRESULT GetOption(STRUCTURED_QUERY_SINGLE_OPTION option, PROPVARIANT* pOptionValue) mut => VT.[Friend]GetOption(&this, option, pOptionValue);

	public HRESULT SetMultiOption(STRUCTURED_QUERY_MULTIOPTION option, PWSTR pszOptionKey, PROPVARIANT* pOptionValue) mut => VT.[Friend]SetMultiOption(&this, option, pszOptionKey, pOptionValue);

	public HRESULT GetSchemaProvider(ISchemaProvider** ppSchemaProvider) mut => VT.[Friend]GetSchemaProvider(&this, ppSchemaProvider);

	public HRESULT RestateToString(ICondition* pCondition, BOOL fUseEnglish, PWSTR* ppszQueryString) mut => VT.[Friend]RestateToString(&this, pCondition, fUseEnglish, ppszQueryString);

	public HRESULT ParsePropertyValue(PWSTR pszPropertyName, PWSTR pszInputString, IQuerySolution** ppSolution) mut => VT.[Friend]ParsePropertyValue(&this, pszPropertyName, pszInputString, ppSolution);

	public HRESULT RestatePropertyValueToString(ICondition* pCondition, BOOL fUseEnglish, PWSTR* ppszPropertyName, PWSTR* ppszQueryString) mut => VT.[Friend]RestatePropertyValueToString(&this, pCondition, fUseEnglish, ppszPropertyName, ppszQueryString);
}

[CRepr]struct IConditionFactory : IUnknown
{
	public new const Guid IID = .(0xa5efe073, 0xb16f, 0x474f, 0x9f, 0x3e, 0x9f, 0x8b, 0x49, 0x7a, 0x3e, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pcSub, BOOL fSimplify, ICondition** ppcResult) MakeNot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONDITION_TYPE ct, IEnumUnknown* peuSubs, BOOL fSimplify, ICondition** ppcResult) MakeAndOr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, CONDITION_OPERATION cop, PWSTR pszValueType, PROPVARIANT* ppropvar, IRichChunk* pPropertyNameTerm, IRichChunk* pOperationTerm, IRichChunk* pValueTerm, BOOL fExpand, ICondition** ppcResult) MakeLeaf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pc, STRUCTURED_QUERY_RESOLVE_OPTION sqro, SYSTEMTIME* pstReferenceTime, ICondition** ppcResolved) Resolve;
	}


	public HRESULT MakeNot(ICondition* pcSub, BOOL fSimplify, ICondition** ppcResult) mut => VT.[Friend]MakeNot(&this, pcSub, fSimplify, ppcResult);

	public HRESULT MakeAndOr(CONDITION_TYPE ct, IEnumUnknown* peuSubs, BOOL fSimplify, ICondition** ppcResult) mut => VT.[Friend]MakeAndOr(&this, ct, peuSubs, fSimplify, ppcResult);

	public HRESULT MakeLeaf(PWSTR pszPropertyName, CONDITION_OPERATION cop, PWSTR pszValueType, PROPVARIANT* ppropvar, IRichChunk* pPropertyNameTerm, IRichChunk* pOperationTerm, IRichChunk* pValueTerm, BOOL fExpand, ICondition** ppcResult) mut => VT.[Friend]MakeLeaf(&this, pszPropertyName, cop, pszValueType, ppropvar, pPropertyNameTerm, pOperationTerm, pValueTerm, fExpand, ppcResult);

	public HRESULT Resolve(ICondition* pc, STRUCTURED_QUERY_RESOLVE_OPTION sqro, SYSTEMTIME* pstReferenceTime, ICondition** ppcResolved) mut => VT.[Friend]Resolve(&this, pc, sqro, pstReferenceTime, ppcResolved);
}

[CRepr]struct IQuerySolution : IConditionFactory
{
	public new const Guid IID = .(0xd6ebc66b, 0x8921, 0x4193, 0xaf, 0xdd, 0xa1, 0x78, 0x9f, 0xb7, 0xff, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConditionFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition** ppQueryNode, IEntity** ppMainType) GetQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppParseErrors) GetErrors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszInputString, ITokenCollection** ppTokens, uint32* plcid, IUnknown** ppWordBreaker) GetLexicalData;
	}


	public HRESULT GetQuery(ICondition** ppQueryNode, IEntity** ppMainType) mut => VT.[Friend]GetQuery(&this, ppQueryNode, ppMainType);

	public HRESULT GetErrors(in Guid riid, void** ppParseErrors) mut => VT.[Friend]GetErrors(&this, riid, ppParseErrors);

	public HRESULT GetLexicalData(PWSTR* ppszInputString, ITokenCollection** ppTokens, uint32* plcid, IUnknown** ppWordBreaker) mut => VT.[Friend]GetLexicalData(&this, ppszInputString, ppTokens, plcid, ppWordBreaker);
}

[CRepr]struct IConditionFactory2 : IConditionFactory
{
	public new const Guid IID = .(0x71d222e1, 0x432f, 0x429e, 0x8c, 0x13, 0xb6, 0xda, 0xfd, 0xe5, 0x07, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConditionFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fVal, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateTrueFalse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pcSub, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateNegation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONDITION_TYPE ct, IObjectArray* poaSubs, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateCompoundFromObjectArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONDITION_TYPE ct, ICondition** ppcondSubs, uint32 cSubs, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateCompoundFromArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, CONDITION_OPERATION cop, PWSTR pszValue, PWSTR pszLocaleName, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateStringLeaf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, CONDITION_OPERATION cop, int32 lValue, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateIntegerLeaf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, CONDITION_OPERATION cop, BOOL fValue, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateBooleanLeaf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, CONDITION_OPERATION cop, PROPVARIANT* propvar, PWSTR pszSemanticType, PWSTR pszLocaleName, IRichChunk* pPropertyNameTerm, IRichChunk* pOperationTerm, IRichChunk* pValueTerm, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) CreateLeaf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pc, STRUCTURED_QUERY_RESOLVE_OPTION sqro, SYSTEMTIME* pstReferenceTime, in Guid riid, void** ppv) ResolveCondition;
	}


	public HRESULT CreateTrueFalse(BOOL fVal, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateTrueFalse(&this, fVal, cco, riid, ppv);

	public HRESULT CreateNegation(ICondition* pcSub, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateNegation(&this, pcSub, cco, riid, ppv);

	public HRESULT CreateCompoundFromObjectArray(CONDITION_TYPE ct, IObjectArray* poaSubs, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateCompoundFromObjectArray(&this, ct, poaSubs, cco, riid, ppv);

	public HRESULT CreateCompoundFromArray(CONDITION_TYPE ct, ICondition** ppcondSubs, uint32 cSubs, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateCompoundFromArray(&this, ct, ppcondSubs, cSubs, cco, riid, ppv);

	public HRESULT CreateStringLeaf(PROPERTYKEY* propkey, CONDITION_OPERATION cop, PWSTR pszValue, PWSTR pszLocaleName, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateStringLeaf(&this, propkey, cop, pszValue, pszLocaleName, cco, riid, ppv);

	public HRESULT CreateIntegerLeaf(PROPERTYKEY* propkey, CONDITION_OPERATION cop, int32 lValue, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateIntegerLeaf(&this, propkey, cop, lValue, cco, riid, ppv);

	public HRESULT CreateBooleanLeaf(PROPERTYKEY* propkey, CONDITION_OPERATION cop, BOOL fValue, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateBooleanLeaf(&this, propkey, cop, fValue, cco, riid, ppv);

	public HRESULT CreateLeaf(PROPERTYKEY* propkey, CONDITION_OPERATION cop, PROPVARIANT* propvar, PWSTR pszSemanticType, PWSTR pszLocaleName, IRichChunk* pPropertyNameTerm, IRichChunk* pOperationTerm, IRichChunk* pValueTerm, CONDITION_CREATION_OPTIONS cco, in Guid riid, void** ppv) mut => VT.[Friend]CreateLeaf(&this, propkey, cop, propvar, pszSemanticType, pszLocaleName, pPropertyNameTerm, pOperationTerm, pValueTerm, cco, riid, ppv);

	public HRESULT ResolveCondition(ICondition* pc, STRUCTURED_QUERY_RESOLVE_OPTION sqro, SYSTEMTIME* pstReferenceTime, in Guid riid, void** ppv) mut => VT.[Friend]ResolveCondition(&this, pc, sqro, pstReferenceTime, riid, ppv);
}

[CRepr]struct IConditionGenerator : IUnknown
{
	public new const Guid IID = .(0x92d2cc58, 0x4386, 0x45a3, 0xb9, 0x8c, 0x7e, 0x0c, 0xe6, 0x4a, 0x41, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISchemaProvider* pSchemaProvider) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszInputString, uint32 lcidUserLocale, ITokenCollection* pTokenCollection, INamedEntityCollector* pNamedEntities) RecognizeNamedEntities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConditionFactory* pConditionFactory, PWSTR pszPropertyName, CONDITION_OPERATION cop, PWSTR pszValueType, PWSTR pszValue, PWSTR pszValue2, IRichChunk* pPropertyNameTerm, IRichChunk* pOperationTerm, IRichChunk* pValueTerm, BOOL automaticWildcard, BOOL* pNoStringQuery, ICondition** ppQueryExpression) GenerateForLeaf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValueType, PROPVARIANT* ppropvar, BOOL fUseEnglish, PWSTR* ppszPhrase) DefaultPhrase;
	}


	public HRESULT Initialize(ISchemaProvider* pSchemaProvider) mut => VT.[Friend]Initialize(&this, pSchemaProvider);

	public HRESULT RecognizeNamedEntities(PWSTR pszInputString, uint32 lcidUserLocale, ITokenCollection* pTokenCollection, INamedEntityCollector* pNamedEntities) mut => VT.[Friend]RecognizeNamedEntities(&this, pszInputString, lcidUserLocale, pTokenCollection, pNamedEntities);

	public HRESULT GenerateForLeaf(IConditionFactory* pConditionFactory, PWSTR pszPropertyName, CONDITION_OPERATION cop, PWSTR pszValueType, PWSTR pszValue, PWSTR pszValue2, IRichChunk* pPropertyNameTerm, IRichChunk* pOperationTerm, IRichChunk* pValueTerm, BOOL automaticWildcard, BOOL* pNoStringQuery, ICondition** ppQueryExpression) mut => VT.[Friend]GenerateForLeaf(&this, pConditionFactory, pszPropertyName, cop, pszValueType, pszValue, pszValue2, pPropertyNameTerm, pOperationTerm, pValueTerm, automaticWildcard, pNoStringQuery, ppQueryExpression);

	public HRESULT DefaultPhrase(PWSTR pszValueType, PROPVARIANT* ppropvar, BOOL fUseEnglish, PWSTR* ppszPhrase) mut => VT.[Friend]DefaultPhrase(&this, pszValueType, ppropvar, fUseEnglish, ppszPhrase);
}

[CRepr]struct IInterval : IUnknown
{
	public new const Guid IID = .(0x6bf0a714, 0x3c18, 0x430b, 0x8b, 0x5d, 0x83, 0xb1, 0xc2, 0x34, 0xd3, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INTERVAL_LIMIT_KIND* pilkLower, PROPVARIANT* ppropvarLower, INTERVAL_LIMIT_KIND* pilkUpper, PROPVARIANT* ppropvarUpper) GetLimits;
	}


	public HRESULT GetLimits(INTERVAL_LIMIT_KIND* pilkLower, PROPVARIANT* ppropvarLower, INTERVAL_LIMIT_KIND* pilkUpper, PROPVARIANT* ppropvarUpper) mut => VT.[Friend]GetLimits(&this, pilkLower, ppropvarLower, pilkUpper, ppropvarUpper);
}

[CRepr]struct IMetaData : IUnknown
{
	public new const Guid IID = .(0x780102b0, 0xc43b, 0x4876, 0xbc, 0x7b, 0x5e, 0x9b, 0xa5, 0xc8, 0x87, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszKey, PWSTR* ppszValue) GetData;
	}


	public HRESULT GetData(PWSTR* ppszKey, PWSTR* ppszValue) mut => VT.[Friend]GetData(&this, ppszKey, ppszValue);
}

[CRepr]struct IEntity : IUnknown
{
	public new const Guid IID = .(0x24264891, 0xe80b, 0x4fd3, 0xb7, 0xce, 0x4f, 0xf2, 0xfa, 0xe8, 0x93, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEntity** pBaseEntity) Base;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pRelationships) Relationships;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRelationName, IRelationship** pRelationship) GetRelationship;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pMetaData) MetaData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pNamedEntities) NamedEntities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszValue, INamedEntity** ppNamedEntity) GetNamedEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPhrase) DefaultPhrase;
	}


	public HRESULT Name(PWSTR* ppszName) mut => VT.[Friend]Name(&this, ppszName);

	public HRESULT Base(IEntity** pBaseEntity) mut => VT.[Friend]Base(&this, pBaseEntity);

	public HRESULT Relationships(in Guid riid, void** pRelationships) mut => VT.[Friend]Relationships(&this, riid, pRelationships);

	public HRESULT GetRelationship(PWSTR pszRelationName, IRelationship** pRelationship) mut => VT.[Friend]GetRelationship(&this, pszRelationName, pRelationship);

	public HRESULT MetaData(in Guid riid, void** pMetaData) mut => VT.[Friend]MetaData(&this, riid, pMetaData);

	public HRESULT NamedEntities(in Guid riid, void** pNamedEntities) mut => VT.[Friend]NamedEntities(&this, riid, pNamedEntities);

	public HRESULT GetNamedEntity(PWSTR pszValue, INamedEntity** ppNamedEntity) mut => VT.[Friend]GetNamedEntity(&this, pszValue, ppNamedEntity);

	public HRESULT DefaultPhrase(PWSTR* ppszPhrase) mut => VT.[Friend]DefaultPhrase(&this, ppszPhrase);
}

[CRepr]struct IRelationship : IUnknown
{
	public new const Guid IID = .(0x2769280b, 0x5108, 0x498c, 0x9c, 0x7f, 0xa5, 0x12, 0x39, 0xb6, 0x31, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pIsReal) IsReal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEntity** pDestinationEntity) Destination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pMetaData) MetaData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPhrase) DefaultPhrase;
	}


	public HRESULT Name(PWSTR* ppszName) mut => VT.[Friend]Name(&this, ppszName);

	public HRESULT IsReal(BOOL* pIsReal) mut => VT.[Friend]IsReal(&this, pIsReal);

	public HRESULT Destination(IEntity** pDestinationEntity) mut => VT.[Friend]Destination(&this, pDestinationEntity);

	public HRESULT MetaData(in Guid riid, void** pMetaData) mut => VT.[Friend]MetaData(&this, riid, pMetaData);

	public HRESULT DefaultPhrase(PWSTR* ppszPhrase) mut => VT.[Friend]DefaultPhrase(&this, ppszPhrase);
}

[CRepr]struct INamedEntity : IUnknown
{
	public new const Guid IID = .(0xabdbd0b1, 0x7d54, 0x49fb, 0xab, 0x5c, 0xbf, 0xf4, 0x13, 0x00, 0x04, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPhrase) DefaultPhrase;
	}


	public HRESULT GetValue(PWSTR* ppszValue) mut => VT.[Friend]GetValue(&this, ppszValue);

	public HRESULT DefaultPhrase(PWSTR* ppszPhrase) mut => VT.[Friend]DefaultPhrase(&this, ppszPhrase);
}

[CRepr]struct ISchemaProvider : IUnknown
{
	public new const Guid IID = .(0x8cf89bcb, 0x394c, 0x49b2, 0xae, 0x28, 0xa5, 0x9d, 0xd4, 0xed, 0x7f, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pEntities) Entities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEntity** pRootEntity) RootEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszEntityName, IEntity** pEntity) GetEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pMetaData) MetaData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid, ISchemaLocalizerSupport* pSchemaLocalizerSupport) Localize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSchemaBinaryPath) SaveBinary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEntity* pEntity, PWSTR pszInputString, ITokenCollection* pTokenCollection, uint32 cTokensBegin, uint32* pcTokensLength, PWSTR* ppszValue) LookupAuthoredNamedEntity;
	}


	public HRESULT Entities(in Guid riid, void** pEntities) mut => VT.[Friend]Entities(&this, riid, pEntities);

	public HRESULT RootEntity(IEntity** pRootEntity) mut => VT.[Friend]RootEntity(&this, pRootEntity);

	public HRESULT GetEntity(PWSTR pszEntityName, IEntity** pEntity) mut => VT.[Friend]GetEntity(&this, pszEntityName, pEntity);

	public HRESULT MetaData(in Guid riid, void** pMetaData) mut => VT.[Friend]MetaData(&this, riid, pMetaData);

	public HRESULT Localize(uint32 lcid, ISchemaLocalizerSupport* pSchemaLocalizerSupport) mut => VT.[Friend]Localize(&this, lcid, pSchemaLocalizerSupport);

	public HRESULT SaveBinary(PWSTR pszSchemaBinaryPath) mut => VT.[Friend]SaveBinary(&this, pszSchemaBinaryPath);

	public HRESULT LookupAuthoredNamedEntity(IEntity* pEntity, PWSTR pszInputString, ITokenCollection* pTokenCollection, uint32 cTokensBegin, uint32* pcTokensLength, PWSTR* ppszValue) mut => VT.[Friend]LookupAuthoredNamedEntity(&this, pEntity, pszInputString, pTokenCollection, cTokensBegin, pcTokensLength, ppszValue);
}

[CRepr]struct ITokenCollection : IUnknown
{
	public new const Guid IID = .(0x22d8b4f2, 0xf577, 0x4adb, 0xa3, 0x35, 0xc2, 0xae, 0x88, 0x41, 0x6f, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) NumberOfTokens;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 i, uint32* pBegin, uint32* pLength, PWSTR* ppsz) GetToken;
	}


	public HRESULT NumberOfTokens(uint32* pCount) mut => VT.[Friend]NumberOfTokens(&this, pCount);

	public HRESULT GetToken(uint32 i, uint32* pBegin, uint32* pLength, PWSTR* ppsz) mut => VT.[Friend]GetToken(&this, i, pBegin, pLength, ppsz);
}

[CRepr]struct INamedEntityCollector : IUnknown
{
	public new const Guid IID = .(0xaf2440f6, 0x8afc, 0x47d0, 0x9a, 0x7f, 0x39, 0x6a, 0x0a, 0xcf, 0xb4, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 beginSpan, uint32 endSpan, uint32 beginActual, uint32 endActual, IEntity* pType, PWSTR pszValue, NAMED_ENTITY_CERTAINTY certainty) Add;
	}


	public HRESULT Add(uint32 beginSpan, uint32 endSpan, uint32 beginActual, uint32 endActual, IEntity* pType, PWSTR pszValue, NAMED_ENTITY_CERTAINTY certainty) mut => VT.[Friend]Add(&this, beginSpan, endSpan, beginActual, endActual, pType, pszValue, certainty);
}

[CRepr]struct ISchemaLocalizerSupport : IUnknown
{
	public new const Guid IID = .(0xca3fdca2, 0xbfbe, 0x4eed, 0x90, 0xd7, 0x0c, 0xae, 0xf0, 0xa1, 0xbd, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszGlobalString, PWSTR* ppszLocalString) Localize;
	}


	public HRESULT Localize(PWSTR pszGlobalString, PWSTR* ppszLocalString) mut => VT.[Friend]Localize(&this, pszGlobalString, ppszLocalString);
}

[CRepr]struct IQueryParserManager : IUnknown
{
	public new const Guid IID = .(0xa879e3c4, 0xaf77, 0x44fb, 0x8f, 0x37, 0xeb, 0xd1, 0x48, 0x7c, 0xf9, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCatalog, uint16 langidForKeywords, in Guid riid, void** ppQueryParser) CreateLoadedParser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUnderstandNQS, BOOL fAutoWildCard, IQueryParser* pQueryParser) InitializeOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, QUERY_PARSER_MANAGER_OPTION option, PROPVARIANT* pOptionValue) SetOption;
	}


	public HRESULT CreateLoadedParser(PWSTR pszCatalog, uint16 langidForKeywords, in Guid riid, void** ppQueryParser) mut => VT.[Friend]CreateLoadedParser(&this, pszCatalog, langidForKeywords, riid, ppQueryParser);

	public HRESULT InitializeOptions(BOOL fUnderstandNQS, BOOL fAutoWildCard, IQueryParser* pQueryParser) mut => VT.[Friend]InitializeOptions(&this, fUnderstandNQS, fAutoWildCard, pQueryParser);

	public HRESULT SetOption(QUERY_PARSER_MANAGER_OPTION option, PROPVARIANT* pOptionValue) mut => VT.[Friend]SetOption(&this, option, pOptionValue);
}

[CRepr]struct IUrlAccessor : IUnknown
{
	public new const Guid IID = .(0x0b63e318, 0x9ccc, 0x11d0, 0xbc, 0xdb, 0x00, 0x80, 0x5f, 0xcc, 0xce, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPSPEC* pSpec, PROPVARIANT* pVar) AddRequestParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* wszDocFormat, uint32 dwSize, uint32* pdwLength) GetDocFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pClsid) GetCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* wszHost, uint32 dwSize, uint32* pdwLength) GetHost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pllSize) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftLastModified) GetLastModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* wszFileName, uint32 dwSize, uint32* pdwLength) GetFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pSD, uint32 dwSize, uint32* pdwLength) GetSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* wszRedirectedURL, uint32 dwSize, uint32* pdwLength) GetRedirectedURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pSPClsid) GetSecurityProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppStream) BindToStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFilter** ppFilter) BindToFilter;
	}


	public HRESULT AddRequestParameter(PROPSPEC* pSpec, PROPVARIANT* pVar) mut => VT.[Friend]AddRequestParameter(&this, pSpec, pVar);

	public HRESULT GetDocFormat(char16* wszDocFormat, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetDocFormat(&this, wszDocFormat, dwSize, pdwLength);

	public HRESULT GetCLSID(Guid* pClsid) mut => VT.[Friend]GetCLSID(&this, pClsid);

	public HRESULT GetHost(char16* wszHost, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetHost(&this, wszHost, dwSize, pdwLength);

	public HRESULT IsDirectory() mut => VT.[Friend]IsDirectory(&this);

	public HRESULT GetSize(uint64* pllSize) mut => VT.[Friend]GetSize(&this, pllSize);

	public HRESULT GetLastModified(FILETIME* pftLastModified) mut => VT.[Friend]GetLastModified(&this, pftLastModified);

	public HRESULT GetFileName(char16* wszFileName, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetFileName(&this, wszFileName, dwSize, pdwLength);

	public HRESULT GetSecurityDescriptor(uint8* pSD, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetSecurityDescriptor(&this, pSD, dwSize, pdwLength);

	public HRESULT GetRedirectedURL(char16* wszRedirectedURL, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetRedirectedURL(&this, wszRedirectedURL, dwSize, pdwLength);

	public HRESULT GetSecurityProvider(Guid* pSPClsid) mut => VT.[Friend]GetSecurityProvider(&this, pSPClsid);

	public HRESULT BindToStream(IStream** ppStream) mut => VT.[Friend]BindToStream(&this, ppStream);

	public HRESULT BindToFilter(IFilter** ppFilter) mut => VT.[Friend]BindToFilter(&this, ppFilter);
}

[CRepr]struct IUrlAccessor2 : IUrlAccessor
{
	public new const Guid IID = .(0xc7310734, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUrlAccessor.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* wszDocUrl, uint32 dwSize, uint32* pdwLength) GetDisplayUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* wszCodePage, uint32 dwSize, uint32* pdwLength) GetCodePage;
	}


	public HRESULT GetDisplayUrl(char16* wszDocUrl, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetDisplayUrl(&this, wszDocUrl, dwSize, pdwLength);

	public HRESULT IsDocument() mut => VT.[Friend]IsDocument(&this);

	public HRESULT GetCodePage(char16* wszCodePage, uint32 dwSize, uint32* pdwLength) mut => VT.[Friend]GetCodePage(&this, wszCodePage, dwSize, pdwLength);
}

[CRepr]struct IUrlAccessor3 : IUrlAccessor2
{
	public new const Guid IID = .(0x6fbc7005, 0x0455, 0x4874, 0xb8, 0xff, 0x74, 0x39, 0x45, 0x02, 0x41, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUrlAccessor2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcwszURL, uint32* pcSidCount, BLOB** ppSidBlobs) GetImpersonationSidBlobs;
	}


	public HRESULT GetImpersonationSidBlobs(PWSTR pcwszURL, uint32* pcSidCount, BLOB** ppSidBlobs) mut => VT.[Friend]GetImpersonationSidBlobs(&this, pcwszURL, pcSidCount, ppSidBlobs);
}

[CRepr]struct IUrlAccessor4 : IUrlAccessor3
{
	public new const Guid IID = .(0x5cc51041, 0xc8d2, 0x41d7, 0xbc, 0xa3, 0x9e, 0x9e, 0x28, 0x62, 0x97, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUrlAccessor3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIndexContent) ShouldIndexItemContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, BOOL* pfIndexProperty) ShouldIndexProperty;
	}


	public HRESULT ShouldIndexItemContent(BOOL* pfIndexContent) mut => VT.[Friend]ShouldIndexItemContent(&this, pfIndexContent);

	public HRESULT ShouldIndexProperty(PROPERTYKEY* key, BOOL* pfIndexProperty) mut => VT.[Friend]ShouldIndexProperty(&this, key, pfIndexProperty);
}

[CRepr]struct IOpLockStatus : IUnknown
{
	public new const Guid IID = .(0xc731065d, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsOplockValid) IsOplockValid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsOplockBroken) IsOplockBroken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phOplockEv) GetOplockEventHandle;
	}


	public HRESULT IsOplockValid(BOOL* pfIsOplockValid) mut => VT.[Friend]IsOplockValid(&this, pfIsOplockValid);

	public HRESULT IsOplockBroken(BOOL* pfIsOplockBroken) mut => VT.[Friend]IsOplockBroken(&this, pfIsOplockBroken);

	public HRESULT GetOplockEventHandle(HANDLE* phOplockEv) mut => VT.[Friend]GetOplockEventHandle(&this, phOplockEv);
}

[CRepr]struct ISearchProtocolThreadContext : IUnknown
{
	public new const Guid IID = .(0xc73106e1, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ThreadInit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ThreadShutdown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTimeElaspedSinceLastCallInMS) ThreadIdle;
	}


	public HRESULT ThreadInit() mut => VT.[Friend]ThreadInit(&this);

	public HRESULT ThreadShutdown() mut => VT.[Friend]ThreadShutdown(&this);

	public HRESULT ThreadIdle(uint32 dwTimeElaspedSinceLastCallInMS) mut => VT.[Friend]ThreadIdle(&this, dwTimeElaspedSinceLastCallInMS);
}

[CRepr]struct ISearchProtocol : IUnknown
{
	public new const Guid IID = .(0xc73106ba, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TIMEOUT_INFO* pTimeoutInfo, IProtocolHandlerSite* pProtocolHandlerSite, PROXY_INFO* pProxyInfo) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcwszURL, AUTHENTICATION_INFO* pAuthenticationInfo, INCREMENTAL_ACCESS_INFO* pIncrementalAccessInfo, ITEM_INFO* pItemInfo, IUrlAccessor** ppAccessor) CreateAccessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUrlAccessor* pAccessor) CloseAccessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShutDown;
	}


	public HRESULT Init(TIMEOUT_INFO* pTimeoutInfo, IProtocolHandlerSite* pProtocolHandlerSite, PROXY_INFO* pProxyInfo) mut => VT.[Friend]Init(&this, pTimeoutInfo, pProtocolHandlerSite, pProxyInfo);

	public HRESULT CreateAccessor(PWSTR pcwszURL, AUTHENTICATION_INFO* pAuthenticationInfo, INCREMENTAL_ACCESS_INFO* pIncrementalAccessInfo, ITEM_INFO* pItemInfo, IUrlAccessor** ppAccessor) mut => VT.[Friend]CreateAccessor(&this, pcwszURL, pAuthenticationInfo, pIncrementalAccessInfo, pItemInfo, ppAccessor);

	public HRESULT CloseAccessor(IUrlAccessor* pAccessor) mut => VT.[Friend]CloseAccessor(&this, pAccessor);

	public HRESULT ShutDown() mut => VT.[Friend]ShutDown(&this);
}

[CRepr]struct ISearchProtocol2 : ISearchProtocol
{
	public new const Guid IID = .(0x7789f0b2, 0xb5b2, 0x4722, 0x8b, 0x65, 0x5d, 0xbd, 0x15, 0x06, 0x97, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISearchProtocol.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcwszURL, AUTHENTICATION_INFO* pAuthenticationInfo, INCREMENTAL_ACCESS_INFO* pIncrementalAccessInfo, ITEM_INFO* pItemInfo, BLOB* pUserData, IUrlAccessor** ppAccessor) CreateAccessorEx;
	}


	public HRESULT CreateAccessorEx(PWSTR pcwszURL, AUTHENTICATION_INFO* pAuthenticationInfo, INCREMENTAL_ACCESS_INFO* pIncrementalAccessInfo, ITEM_INFO* pItemInfo, BLOB* pUserData, IUrlAccessor** ppAccessor) mut => VT.[Friend]CreateAccessorEx(&this, pcwszURL, pAuthenticationInfo, pIncrementalAccessInfo, pItemInfo, pUserData, ppAccessor);
}

[CRepr]struct IProtocolHandlerSite : IUnknown
{
	public new const Guid IID = .(0x0b63e385, 0x9ccc, 0x11d0, 0xbc, 0xdb, 0x00, 0x80, 0x5f, 0xcc, 0xce, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsidObj, PWSTR pcwszContentType, PWSTR pcwszExtension, IFilter** ppFilter) GetFilter;
	}


	public HRESULT GetFilter(Guid* pclsidObj, PWSTR pcwszContentType, PWSTR pcwszExtension, IFilter** ppFilter) mut => VT.[Friend]GetFilter(&this, pclsidObj, pcwszContentType, pcwszExtension, ppFilter);
}

[CRepr]struct ISearchRoot : IUnknown
{
	public new const Guid IID = .(0x04c18ccf, 0x1f57, 0x4cbd, 0x88, 0xcc, 0x39, 0x00, 0xf5, 0x19, 0x5c, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTaskArg) put_Schedule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTaskArg) get_Schedule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) put_RootURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszURL) get_RootURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fIsHierarchical) put_IsHierarchical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsHierarchical) get_IsHierarchical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fProvidesNotifications) put_ProvidesNotifications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProvidesNotifications) get_ProvidesNotifications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUseNotificationsOnly) put_UseNotificationsOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfUseNotificationsOnly) get_UseNotificationsOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDepth) put_EnumerationDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDepth) get_EnumerationDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDepth) put_HostDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDepth) get_HostDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFollowDirectories) put_FollowDirectories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfFollowDirectories) get_FollowDirectories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AUTH_TYPE authType) put_AuthenticationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AUTH_TYPE* pAuthType) get_AuthenticationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUser) put_User;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUser) get_User;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPassword) put_Password;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPassword) get_Password;
	}


	public HRESULT put_Schedule(PWSTR pszTaskArg) mut => VT.[Friend]put_Schedule(&this, pszTaskArg);

	public HRESULT get_Schedule(PWSTR* ppszTaskArg) mut => VT.[Friend]get_Schedule(&this, ppszTaskArg);

	public HRESULT put_RootURL(PWSTR pszURL) mut => VT.[Friend]put_RootURL(&this, pszURL);

	public HRESULT get_RootURL(PWSTR* ppszURL) mut => VT.[Friend]get_RootURL(&this, ppszURL);

	public HRESULT put_IsHierarchical(BOOL fIsHierarchical) mut => VT.[Friend]put_IsHierarchical(&this, fIsHierarchical);

	public HRESULT get_IsHierarchical(BOOL* pfIsHierarchical) mut => VT.[Friend]get_IsHierarchical(&this, pfIsHierarchical);

	public HRESULT put_ProvidesNotifications(BOOL fProvidesNotifications) mut => VT.[Friend]put_ProvidesNotifications(&this, fProvidesNotifications);

	public HRESULT get_ProvidesNotifications(BOOL* pfProvidesNotifications) mut => VT.[Friend]get_ProvidesNotifications(&this, pfProvidesNotifications);

	public HRESULT put_UseNotificationsOnly(BOOL fUseNotificationsOnly) mut => VT.[Friend]put_UseNotificationsOnly(&this, fUseNotificationsOnly);

	public HRESULT get_UseNotificationsOnly(BOOL* pfUseNotificationsOnly) mut => VT.[Friend]get_UseNotificationsOnly(&this, pfUseNotificationsOnly);

	public HRESULT put_EnumerationDepth(uint32 dwDepth) mut => VT.[Friend]put_EnumerationDepth(&this, dwDepth);

	public HRESULT get_EnumerationDepth(uint32* pdwDepth) mut => VT.[Friend]get_EnumerationDepth(&this, pdwDepth);

	public HRESULT put_HostDepth(uint32 dwDepth) mut => VT.[Friend]put_HostDepth(&this, dwDepth);

	public HRESULT get_HostDepth(uint32* pdwDepth) mut => VT.[Friend]get_HostDepth(&this, pdwDepth);

	public HRESULT put_FollowDirectories(BOOL fFollowDirectories) mut => VT.[Friend]put_FollowDirectories(&this, fFollowDirectories);

	public HRESULT get_FollowDirectories(BOOL* pfFollowDirectories) mut => VT.[Friend]get_FollowDirectories(&this, pfFollowDirectories);

	public HRESULT put_AuthenticationType(AUTH_TYPE authType) mut => VT.[Friend]put_AuthenticationType(&this, authType);

	public HRESULT get_AuthenticationType(AUTH_TYPE* pAuthType) mut => VT.[Friend]get_AuthenticationType(&this, pAuthType);

	public HRESULT put_User(PWSTR pszUser) mut => VT.[Friend]put_User(&this, pszUser);

	public HRESULT get_User(PWSTR* ppszUser) mut => VT.[Friend]get_User(&this, ppszUser);

	public HRESULT put_Password(PWSTR pszPassword) mut => VT.[Friend]put_Password(&this, pszPassword);

	public HRESULT get_Password(PWSTR* ppszPassword) mut => VT.[Friend]get_Password(&this, ppszPassword);
}

[CRepr]struct IEnumSearchRoots : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ISearchRoot** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSearchRoots** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ISearchRoot** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSearchRoots** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISearchScopeRule : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPatternOrURL) get_PatternOrURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsIncluded) get_IsIncluded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsDefault) get_IsDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFollowFlags) get_FollowFlags;
	}


	public HRESULT get_PatternOrURL(PWSTR* ppszPatternOrURL) mut => VT.[Friend]get_PatternOrURL(&this, ppszPatternOrURL);

	public HRESULT get_IsIncluded(BOOL* pfIsIncluded) mut => VT.[Friend]get_IsIncluded(&this, pfIsIncluded);

	public HRESULT get_IsDefault(BOOL* pfIsDefault) mut => VT.[Friend]get_IsDefault(&this, pfIsDefault);

	public HRESULT get_FollowFlags(uint32* pFollowFlags) mut => VT.[Friend]get_FollowFlags(&this, pFollowFlags);
}

[CRepr]struct IEnumSearchScopeRules : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ISearchScopeRule** pprgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSearchScopeRules** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ISearchScopeRule** pprgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, pprgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSearchScopeRules** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISearchCrawlScopeManager : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL fInclude, uint32 fFollowFlags) AddDefaultScopeRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISearchRoot* pSearchRoot) AddRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) RemoveRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSearchRoots** ppSearchRoots) EnumerateRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL fInclude, BOOL fDefault, BOOL fOverrideChildren) AddHierarchicalScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL fInclude, BOOL fOverrideChildren, uint32 fFollowFlags) AddUserScopeRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRule) RemoveScopeRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSearchScopeRules** ppSearchScopeRules) EnumerateScopeRules;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL* pfHasParentRule) HasParentScopeRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL* pfHasChildRule) HasChildScopeRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL* pfIsIncluded) IncludedInCrawlScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, BOOL* pfIsIncluded, CLUSION_REASON* pReason) IncludedInCrawlScopeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RevertToDefaultScopes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, int32* plScopeId) GetParentScopeVersionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) RemoveDefaultScopeRule;
	}


	public HRESULT AddDefaultScopeRule(PWSTR pszURL, BOOL fInclude, uint32 fFollowFlags) mut => VT.[Friend]AddDefaultScopeRule(&this, pszURL, fInclude, fFollowFlags);

	public HRESULT AddRoot(ISearchRoot* pSearchRoot) mut => VT.[Friend]AddRoot(&this, pSearchRoot);

	public HRESULT RemoveRoot(PWSTR pszURL) mut => VT.[Friend]RemoveRoot(&this, pszURL);

	public HRESULT EnumerateRoots(IEnumSearchRoots** ppSearchRoots) mut => VT.[Friend]EnumerateRoots(&this, ppSearchRoots);

	public HRESULT AddHierarchicalScope(PWSTR pszURL, BOOL fInclude, BOOL fDefault, BOOL fOverrideChildren) mut => VT.[Friend]AddHierarchicalScope(&this, pszURL, fInclude, fDefault, fOverrideChildren);

	public HRESULT AddUserScopeRule(PWSTR pszURL, BOOL fInclude, BOOL fOverrideChildren, uint32 fFollowFlags) mut => VT.[Friend]AddUserScopeRule(&this, pszURL, fInclude, fOverrideChildren, fFollowFlags);

	public HRESULT RemoveScopeRule(PWSTR pszRule) mut => VT.[Friend]RemoveScopeRule(&this, pszRule);

	public HRESULT EnumerateScopeRules(IEnumSearchScopeRules** ppSearchScopeRules) mut => VT.[Friend]EnumerateScopeRules(&this, ppSearchScopeRules);

	public HRESULT HasParentScopeRule(PWSTR pszURL, BOOL* pfHasParentRule) mut => VT.[Friend]HasParentScopeRule(&this, pszURL, pfHasParentRule);

	public HRESULT HasChildScopeRule(PWSTR pszURL, BOOL* pfHasChildRule) mut => VT.[Friend]HasChildScopeRule(&this, pszURL, pfHasChildRule);

	public HRESULT IncludedInCrawlScope(PWSTR pszURL, BOOL* pfIsIncluded) mut => VT.[Friend]IncludedInCrawlScope(&this, pszURL, pfIsIncluded);

	public HRESULT IncludedInCrawlScopeEx(PWSTR pszURL, BOOL* pfIsIncluded, CLUSION_REASON* pReason) mut => VT.[Friend]IncludedInCrawlScopeEx(&this, pszURL, pfIsIncluded, pReason);

	public HRESULT RevertToDefaultScopes() mut => VT.[Friend]RevertToDefaultScopes(&this);

	public HRESULT SaveAll() mut => VT.[Friend]SaveAll(&this);

	public HRESULT GetParentScopeVersionId(PWSTR pszURL, int32* plScopeId) mut => VT.[Friend]GetParentScopeVersionId(&this, pszURL, plScopeId);

	public HRESULT RemoveDefaultScopeRule(PWSTR pszURL) mut => VT.[Friend]RemoveDefaultScopeRule(&this, pszURL);
}

[CRepr]struct ISearchCrawlScopeManager2 : ISearchCrawlScopeManager
{
	public new const Guid IID = .(0x6292f7ad, 0x4e19, 0x4717, 0xa5, 0x34, 0x8f, 0xc2, 0x2b, 0xcd, 0x5c, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISearchCrawlScopeManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32** plVersion, HANDLE* phFileMapping) GetVersion;
	}


	public HRESULT GetVersion(int32** plVersion, HANDLE* phFileMapping) mut => VT.[Friend]GetVersion(&this, plVersion, phFileMapping);
}

[CRepr]struct ISearchItemsChangedSink : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) StartedMonitoringScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) StoppedMonitoringScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwNumberOfChanges, SEARCH_ITEM_CHANGE* rgDataChangeEntries, uint32* rgdwDocIds, HRESULT* rghrCompletionCodes) OnItemsChanged;
	}


	public HRESULT StartedMonitoringScope(PWSTR pszURL) mut => VT.[Friend]StartedMonitoringScope(&this, pszURL);

	public HRESULT StoppedMonitoringScope(PWSTR pszURL) mut => VT.[Friend]StoppedMonitoringScope(&this, pszURL);

	public HRESULT OnItemsChanged(uint32 dwNumberOfChanges, SEARCH_ITEM_CHANGE* rgDataChangeEntries, uint32* rgdwDocIds, HRESULT* rghrCompletionCodes) mut => VT.[Friend]OnItemsChanged(&this, dwNumberOfChanges, rgDataChangeEntries, rgdwDocIds, rghrCompletionCodes);
}

[CRepr]struct ISearchPersistentItemsChangedSink : IUnknown
{
	public new const Guid IID = .(0xa2ffdf9b, 0x4758, 0x4f84, 0xb7, 0x29, 0xdf, 0x81, 0xa1, 0xa0, 0x61, 0x2f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) StartedMonitoringScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) StoppedMonitoringScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwNumberOfChanges, SEARCH_ITEM_PERSISTENT_CHANGE* DataChangeEntries, HRESULT* hrCompletionCodes) OnItemsChanged;
	}


	public HRESULT StartedMonitoringScope(PWSTR pszURL) mut => VT.[Friend]StartedMonitoringScope(&this, pszURL);

	public HRESULT StoppedMonitoringScope(PWSTR pszURL) mut => VT.[Friend]StoppedMonitoringScope(&this, pszURL);

	public HRESULT OnItemsChanged(uint32 dwNumberOfChanges, SEARCH_ITEM_PERSISTENT_CHANGE* DataChangeEntries, HRESULT* hrCompletionCodes) mut => VT.[Friend]OnItemsChanged(&this, dwNumberOfChanges, DataChangeEntries, hrCompletionCodes);
}

[CRepr]struct ISearchViewChangedSink : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwDocID, SEARCH_ITEM_CHANGE* pChange, BOOL* pfInView) OnChange;
	}


	public HRESULT OnChange(int32* pdwDocID, SEARCH_ITEM_CHANGE* pChange, BOOL* pfInView) mut => VT.[Friend]OnChange(&this, pdwDocID, pChange, pfInView);
}

[CRepr]struct ISearchNotifyInlineSite : IUnknown
{
	public new const Guid IID = .(0xb5702e61, 0xe75c, 0x4b64, 0x82, 0xa1, 0x6c, 0xb4, 0xf8, 0x32, 0xfc, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEARCH_INDEXING_PHASE sipStatus, uint32 dwNumEntries, SEARCH_ITEM_INDEXING_STATUS* rgItemStatusEntries) OnItemIndexedStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidCatalogResetSignature, in Guid guidCheckPointSignature, uint32 dwLastCheckPointNumber) OnCatalogStatusChange;
	}


	public HRESULT OnItemIndexedStatusChange(SEARCH_INDEXING_PHASE sipStatus, uint32 dwNumEntries, SEARCH_ITEM_INDEXING_STATUS* rgItemStatusEntries) mut => VT.[Friend]OnItemIndexedStatusChange(&this, sipStatus, dwNumEntries, rgItemStatusEntries);

	public HRESULT OnCatalogStatusChange(in Guid guidCatalogResetSignature, in Guid guidCheckPointSignature, uint32 dwLastCheckPointNumber) mut => VT.[Friend]OnCatalogStatusChange(&this, guidCatalogResetSignature, guidCheckPointSignature, dwLastCheckPointNumber);
}

[CRepr]struct ISearchCatalogManager : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PROPVARIANT** ppValue) GetParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PROPVARIANT* pValue) SetParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CatalogStatus* pStatus, CatalogPausedReason* pPausedReason) GetCatalogStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reindex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPattern) ReindexMatchingURLs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRootURL) ReindexSearchRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnectTimeout) put_ConnectTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwConnectTimeout) get_ConnectTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDataTimeout) put_DataTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDataTimeout) get_DataTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) NumberOfItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plIncrementalCount, int32* plNotificationQueue, int32* plHighPriorityQueue) NumberOfItemsToIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pszUrl) URLBeingIndexed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL, uint32* pdwState) GetURLIndexingState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISearchPersistentItemsChangedSink** ppISearchPersistentItemsChangedSink) GetPersistentItemsChangedSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszView, ISearchViewChangedSink* pViewChangedSink, uint32* pdwCookie) RegisterViewForNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISearchNotifyInlineSite* pISearchNotifyInlineSite, in Guid riid, void** ppv, Guid* pGUIDCatalogResetSignature, Guid* pGUIDCheckPointSignature, uint32* pdwLastCheckPointNumber) GetItemsChangedSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnregisterViewForNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszExtension, BOOL fExclude) SetExtensionClusion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppExtensions) EnumerateExcludedExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISearchQueryHelper** ppSearchQueryHelper) GetQueryHelper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDiacriticSensitive) put_DiacriticSensitivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfDiacriticSensitive) get_DiacriticSensitivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISearchCrawlScopeManager** ppCrawlScopeManager) GetCrawlScopeManager;
	}


	public HRESULT get_Name(PWSTR* pszName) mut => VT.[Friend]get_Name(&this, pszName);

	public HRESULT GetParameter(PWSTR pszName, PROPVARIANT** ppValue) mut => VT.[Friend]GetParameter(&this, pszName, ppValue);

	public HRESULT SetParameter(PWSTR pszName, PROPVARIANT* pValue) mut => VT.[Friend]SetParameter(&this, pszName, pValue);

	public HRESULT GetCatalogStatus(CatalogStatus* pStatus, CatalogPausedReason* pPausedReason) mut => VT.[Friend]GetCatalogStatus(&this, pStatus, pPausedReason);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Reindex() mut => VT.[Friend]Reindex(&this);

	public HRESULT ReindexMatchingURLs(PWSTR pszPattern) mut => VT.[Friend]ReindexMatchingURLs(&this, pszPattern);

	public HRESULT ReindexSearchRoot(PWSTR pszRootURL) mut => VT.[Friend]ReindexSearchRoot(&this, pszRootURL);

	public HRESULT put_ConnectTimeout(uint32 dwConnectTimeout) mut => VT.[Friend]put_ConnectTimeout(&this, dwConnectTimeout);

	public HRESULT get_ConnectTimeout(uint32* pdwConnectTimeout) mut => VT.[Friend]get_ConnectTimeout(&this, pdwConnectTimeout);

	public HRESULT put_DataTimeout(uint32 dwDataTimeout) mut => VT.[Friend]put_DataTimeout(&this, dwDataTimeout);

	public HRESULT get_DataTimeout(uint32* pdwDataTimeout) mut => VT.[Friend]get_DataTimeout(&this, pdwDataTimeout);

	public HRESULT NumberOfItems(int32* plCount) mut => VT.[Friend]NumberOfItems(&this, plCount);

	public HRESULT NumberOfItemsToIndex(int32* plIncrementalCount, int32* plNotificationQueue, int32* plHighPriorityQueue) mut => VT.[Friend]NumberOfItemsToIndex(&this, plIncrementalCount, plNotificationQueue, plHighPriorityQueue);

	public HRESULT URLBeingIndexed(PWSTR* pszUrl) mut => VT.[Friend]URLBeingIndexed(&this, pszUrl);

	public HRESULT GetURLIndexingState(PWSTR pszURL, uint32* pdwState) mut => VT.[Friend]GetURLIndexingState(&this, pszURL, pdwState);

	public HRESULT GetPersistentItemsChangedSink(ISearchPersistentItemsChangedSink** ppISearchPersistentItemsChangedSink) mut => VT.[Friend]GetPersistentItemsChangedSink(&this, ppISearchPersistentItemsChangedSink);

	public HRESULT RegisterViewForNotification(PWSTR pszView, ISearchViewChangedSink* pViewChangedSink, uint32* pdwCookie) mut => VT.[Friend]RegisterViewForNotification(&this, pszView, pViewChangedSink, pdwCookie);

	public HRESULT GetItemsChangedSink(ISearchNotifyInlineSite* pISearchNotifyInlineSite, in Guid riid, void** ppv, Guid* pGUIDCatalogResetSignature, Guid* pGUIDCheckPointSignature, uint32* pdwLastCheckPointNumber) mut => VT.[Friend]GetItemsChangedSink(&this, pISearchNotifyInlineSite, riid, ppv, pGUIDCatalogResetSignature, pGUIDCheckPointSignature, pdwLastCheckPointNumber);

	public HRESULT UnregisterViewForNotification(uint32 dwCookie) mut => VT.[Friend]UnregisterViewForNotification(&this, dwCookie);

	public HRESULT SetExtensionClusion(PWSTR pszExtension, BOOL fExclude) mut => VT.[Friend]SetExtensionClusion(&this, pszExtension, fExclude);

	public HRESULT EnumerateExcludedExtensions(IEnumString** ppExtensions) mut => VT.[Friend]EnumerateExcludedExtensions(&this, ppExtensions);

	public HRESULT GetQueryHelper(ISearchQueryHelper** ppSearchQueryHelper) mut => VT.[Friend]GetQueryHelper(&this, ppSearchQueryHelper);

	public HRESULT put_DiacriticSensitivity(BOOL fDiacriticSensitive) mut => VT.[Friend]put_DiacriticSensitivity(&this, fDiacriticSensitive);

	public HRESULT get_DiacriticSensitivity(BOOL* pfDiacriticSensitive) mut => VT.[Friend]get_DiacriticSensitivity(&this, pfDiacriticSensitive);

	public HRESULT GetCrawlScopeManager(ISearchCrawlScopeManager** ppCrawlScopeManager) mut => VT.[Friend]GetCrawlScopeManager(&this, ppCrawlScopeManager);
}

[CRepr]struct ISearchCatalogManager2 : ISearchCatalogManager
{
	public new const Guid IID = .(0x7ac3286d, 0x4d1d, 0x4817, 0x84, 0xfc, 0xc1, 0xc8, 0x5e, 0x3a, 0xf0, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISearchCatalogManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPattern, PRIORITIZE_FLAGS dwPrioritizeFlags) PrioritizeMatchingURLs;
	}


	public HRESULT PrioritizeMatchingURLs(PWSTR pszPattern, PRIORITIZE_FLAGS dwPrioritizeFlags) mut => VT.[Friend]PrioritizeMatchingURLs(&this, pszPattern, dwPrioritizeFlags);
}

[CRepr]struct ISearchQueryHelper : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pszConnectionString) get_ConnectionString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid) put_QueryContentLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* plcid) get_QueryContentLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid) put_QueryKeywordLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* plcid) get_QueryKeywordLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEARCH_TERM_EXPANSION expandTerms) put_QueryTermExpansion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEARCH_TERM_EXPANSION* pExpandTerms) get_QueryTermExpansion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEARCH_QUERY_SYNTAX querySyntax) put_QuerySyntax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SEARCH_QUERY_SYNTAX* pQuerySyntax) get_QuerySyntax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszContentProperties) put_QueryContentProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszContentProperties) get_QueryContentProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSelectColumns) put_QuerySelectColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszSelectColumns) get_QuerySelectColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRestrictions) put_QueryWhereRestrictions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszRestrictions) get_QueryWhereRestrictions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSorting) put_QuerySorting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszSorting) get_QuerySorting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszQuery, PWSTR* ppszSQL) GenerateSQLFromUserQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 itemID, uint32 dwNumberOfColumns, PROPERTYKEY* pColumns, SEARCH_COLUMN_PROPERTIES* pValues, FILETIME* pftGatherModifiedTime) WriteProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cMaxResults) put_QueryMaxResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcMaxResults) get_QueryMaxResults;
	}


	public HRESULT get_ConnectionString(PWSTR* pszConnectionString) mut => VT.[Friend]get_ConnectionString(&this, pszConnectionString);

	public HRESULT put_QueryContentLocale(uint32 lcid) mut => VT.[Friend]put_QueryContentLocale(&this, lcid);

	public HRESULT get_QueryContentLocale(uint32* plcid) mut => VT.[Friend]get_QueryContentLocale(&this, plcid);

	public HRESULT put_QueryKeywordLocale(uint32 lcid) mut => VT.[Friend]put_QueryKeywordLocale(&this, lcid);

	public HRESULT get_QueryKeywordLocale(uint32* plcid) mut => VT.[Friend]get_QueryKeywordLocale(&this, plcid);

	public HRESULT put_QueryTermExpansion(SEARCH_TERM_EXPANSION expandTerms) mut => VT.[Friend]put_QueryTermExpansion(&this, expandTerms);

	public HRESULT get_QueryTermExpansion(SEARCH_TERM_EXPANSION* pExpandTerms) mut => VT.[Friend]get_QueryTermExpansion(&this, pExpandTerms);

	public HRESULT put_QuerySyntax(SEARCH_QUERY_SYNTAX querySyntax) mut => VT.[Friend]put_QuerySyntax(&this, querySyntax);

	public HRESULT get_QuerySyntax(SEARCH_QUERY_SYNTAX* pQuerySyntax) mut => VT.[Friend]get_QuerySyntax(&this, pQuerySyntax);

	public HRESULT put_QueryContentProperties(PWSTR pszContentProperties) mut => VT.[Friend]put_QueryContentProperties(&this, pszContentProperties);

	public HRESULT get_QueryContentProperties(PWSTR* ppszContentProperties) mut => VT.[Friend]get_QueryContentProperties(&this, ppszContentProperties);

	public HRESULT put_QuerySelectColumns(PWSTR pszSelectColumns) mut => VT.[Friend]put_QuerySelectColumns(&this, pszSelectColumns);

	public HRESULT get_QuerySelectColumns(PWSTR* ppszSelectColumns) mut => VT.[Friend]get_QuerySelectColumns(&this, ppszSelectColumns);

	public HRESULT put_QueryWhereRestrictions(PWSTR pszRestrictions) mut => VT.[Friend]put_QueryWhereRestrictions(&this, pszRestrictions);

	public HRESULT get_QueryWhereRestrictions(PWSTR* ppszRestrictions) mut => VT.[Friend]get_QueryWhereRestrictions(&this, ppszRestrictions);

	public HRESULT put_QuerySorting(PWSTR pszSorting) mut => VT.[Friend]put_QuerySorting(&this, pszSorting);

	public HRESULT get_QuerySorting(PWSTR* ppszSorting) mut => VT.[Friend]get_QuerySorting(&this, ppszSorting);

	public HRESULT GenerateSQLFromUserQuery(PWSTR pszQuery, PWSTR* ppszSQL) mut => VT.[Friend]GenerateSQLFromUserQuery(&this, pszQuery, ppszSQL);

	public HRESULT WriteProperties(int32 itemID, uint32 dwNumberOfColumns, PROPERTYKEY* pColumns, SEARCH_COLUMN_PROPERTIES* pValues, FILETIME* pftGatherModifiedTime) mut => VT.[Friend]WriteProperties(&this, itemID, dwNumberOfColumns, pColumns, pValues, pftGatherModifiedTime);

	public HRESULT put_QueryMaxResults(int32 cMaxResults) mut => VT.[Friend]put_QueryMaxResults(&this, cMaxResults);

	public HRESULT get_QueryMaxResults(int32* pcMaxResults) mut => VT.[Friend]get_QueryMaxResults(&this, pcMaxResults);
}

[CRepr]struct IRowsetPrioritization : IUnknown
{
	public new const Guid IID = .(0x42811652, 0x079d, 0x481b, 0x87, 0xa2, 0x09, 0xa6, 0x9e, 0xcc, 0x5f, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PRIORITY_LEVEL priority, uint32 scopeStatisticsEventFrequency) SetScopePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PRIORITY_LEVEL* priority, uint32* scopeStatisticsEventFrequency) GetScopePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* indexedDocumentCount, uint32* oustandingAddCount, uint32* oustandingModifyCount) GetScopeStatistics;
	}


	public HRESULT SetScopePriority(PRIORITY_LEVEL priority, uint32 scopeStatisticsEventFrequency) mut => VT.[Friend]SetScopePriority(&this, priority, scopeStatisticsEventFrequency);

	public HRESULT GetScopePriority(PRIORITY_LEVEL* priority, uint32* scopeStatisticsEventFrequency) mut => VT.[Friend]GetScopePriority(&this, priority, scopeStatisticsEventFrequency);

	public HRESULT GetScopeStatistics(uint32* indexedDocumentCount, uint32* oustandingAddCount, uint32* oustandingModifyCount) mut => VT.[Friend]GetScopeStatistics(&this, indexedDocumentCount, oustandingAddCount, oustandingModifyCount);
}

[CRepr]struct IRowsetEvents : IUnknown
{
	public new const Guid IID = .(0x1551aea5, 0x5d66, 0x4b11, 0x86, 0xf5, 0xd5, 0x63, 0x4c, 0xb2, 0x11, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* itemID, ROWSETEVENT_ITEMSTATE newItemState) OnNewItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* itemID, ROWSETEVENT_ITEMSTATE rowsetItemState, ROWSETEVENT_ITEMSTATE changedItemState) OnChangedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* itemID, ROWSETEVENT_ITEMSTATE deletedItemState) OnDeletedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ROWSETEVENT_TYPE eventType, PROPVARIANT* eventData) OnRowsetEvent;
	}


	public HRESULT OnNewItem(PROPVARIANT* itemID, ROWSETEVENT_ITEMSTATE newItemState) mut => VT.[Friend]OnNewItem(&this, itemID, newItemState);

	public HRESULT OnChangedItem(PROPVARIANT* itemID, ROWSETEVENT_ITEMSTATE rowsetItemState, ROWSETEVENT_ITEMSTATE changedItemState) mut => VT.[Friend]OnChangedItem(&this, itemID, rowsetItemState, changedItemState);

	public HRESULT OnDeletedItem(PROPVARIANT* itemID, ROWSETEVENT_ITEMSTATE deletedItemState) mut => VT.[Friend]OnDeletedItem(&this, itemID, deletedItemState);

	public HRESULT OnRowsetEvent(ROWSETEVENT_TYPE eventType, PROPVARIANT* eventData) mut => VT.[Friend]OnRowsetEvent(&this, eventType, eventData);
}

[CRepr]struct ISearchManager : IUnknown
{
	public new const Guid IID = .(0xab310581, 0xac80, 0x11d1, 0x8d, 0xf3, 0x00, 0xc0, 0x4f, 0xb6, 0xef, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszVersionString) GetIndexerVersionStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMajor, uint32* pdwMinor) GetIndexerVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PROPVARIANT** ppValue) GetParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PROPVARIANT* pValue) SetParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszProxyName) get_ProxyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszBypassList) get_BypassList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROXY_ACCESS sUseProxy, BOOL fLocalByPassProxy, uint32 dwPortNumber, PWSTR pszProxyName, PWSTR pszByPassList) SetProxy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCatalog, ISearchCatalogManager** ppCatalogManager) GetCatalog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUserAgent) get_UserAgent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUserAgent) put_UserAgent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROXY_ACCESS* pUseProxy) get_UseProxy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfLocalBypass) get_LocalBypass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPortNumber) get_PortNumber;
	}


	public HRESULT GetIndexerVersionStr(PWSTR* ppszVersionString) mut => VT.[Friend]GetIndexerVersionStr(&this, ppszVersionString);

	public HRESULT GetIndexerVersion(uint32* pdwMajor, uint32* pdwMinor) mut => VT.[Friend]GetIndexerVersion(&this, pdwMajor, pdwMinor);

	public HRESULT GetParameter(PWSTR pszName, PROPVARIANT** ppValue) mut => VT.[Friend]GetParameter(&this, pszName, ppValue);

	public HRESULT SetParameter(PWSTR pszName, PROPVARIANT* pValue) mut => VT.[Friend]SetParameter(&this, pszName, pValue);

	public HRESULT get_ProxyName(PWSTR* ppszProxyName) mut => VT.[Friend]get_ProxyName(&this, ppszProxyName);

	public HRESULT get_BypassList(PWSTR* ppszBypassList) mut => VT.[Friend]get_BypassList(&this, ppszBypassList);

	public HRESULT SetProxy(PROXY_ACCESS sUseProxy, BOOL fLocalByPassProxy, uint32 dwPortNumber, PWSTR pszProxyName, PWSTR pszByPassList) mut => VT.[Friend]SetProxy(&this, sUseProxy, fLocalByPassProxy, dwPortNumber, pszProxyName, pszByPassList);

	public HRESULT GetCatalog(PWSTR pszCatalog, ISearchCatalogManager** ppCatalogManager) mut => VT.[Friend]GetCatalog(&this, pszCatalog, ppCatalogManager);

	public HRESULT get_UserAgent(PWSTR* ppszUserAgent) mut => VT.[Friend]get_UserAgent(&this, ppszUserAgent);

	public HRESULT put_UserAgent(PWSTR pszUserAgent) mut => VT.[Friend]put_UserAgent(&this, pszUserAgent);

	public HRESULT get_UseProxy(PROXY_ACCESS* pUseProxy) mut => VT.[Friend]get_UseProxy(&this, pUseProxy);

	public HRESULT get_LocalBypass(BOOL* pfLocalBypass) mut => VT.[Friend]get_LocalBypass(&this, pfLocalBypass);

	public HRESULT get_PortNumber(uint32* pdwPortNumber) mut => VT.[Friend]get_PortNumber(&this, pdwPortNumber);
}

[CRepr]struct ISearchManager2 : ISearchManager
{
	public new const Guid IID = .(0xdbab3f73, 0xdb19, 0x4a79, 0xbf, 0xc0, 0xa6, 0x1a, 0x93, 0x88, 0x6d, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISearchManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCatalog, ISearchCatalogManager** ppCatalogManager) CreateCatalog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCatalog) DeleteCatalog;
	}


	public HRESULT CreateCatalog(PWSTR pszCatalog, ISearchCatalogManager** ppCatalogManager) mut => VT.[Friend]CreateCatalog(&this, pszCatalog, ppCatalogManager);

	public HRESULT DeleteCatalog(PWSTR pszCatalog) mut => VT.[Friend]DeleteCatalog(&this, pszCatalog);
}

[CRepr]struct ISearchLanguageSupport : IUnknown
{
	public new const Guid IID = .(0x24c3cbaa, 0xebc1, 0x491a, 0x9e, 0xf1, 0x9f, 0x6d, 0x8d, 0xeb, 0x1b, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDiacriticSensitive) SetDiacriticSensitivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfDiacriticSensitive) GetDiacriticSensitivity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid, in Guid riid, void** ppWordBreaker, uint32* pLcidUsed) LoadWordBreaker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid, in Guid riid, void** ppStemmer, uint32* pLcidUsed) LoadStemmer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwcsQueryToken, uint32 cwcQueryToken, char16* pwcsDocumentToken, uint32 cwcDocumentToken, uint32* pulPrefixLength) IsPrefixNormalized;
	}


	public HRESULT SetDiacriticSensitivity(BOOL fDiacriticSensitive) mut => VT.[Friend]SetDiacriticSensitivity(&this, fDiacriticSensitive);

	public HRESULT GetDiacriticSensitivity(BOOL* pfDiacriticSensitive) mut => VT.[Friend]GetDiacriticSensitivity(&this, pfDiacriticSensitive);

	public HRESULT LoadWordBreaker(uint32 lcid, in Guid riid, void** ppWordBreaker, uint32* pLcidUsed) mut => VT.[Friend]LoadWordBreaker(&this, lcid, riid, ppWordBreaker, pLcidUsed);

	public HRESULT LoadStemmer(uint32 lcid, in Guid riid, void** ppStemmer, uint32* pLcidUsed) mut => VT.[Friend]LoadStemmer(&this, lcid, riid, ppStemmer, pLcidUsed);

	public HRESULT IsPrefixNormalized(char16* pwcsQueryToken, uint32 cwcQueryToken, char16* pwcsDocumentToken, uint32 cwcDocumentToken, uint32* pulPrefixLength) mut => VT.[Friend]IsPrefixNormalized(&this, pwcsQueryToken, cwcQueryToken, pwcsDocumentToken, cwcDocumentToken, pulPrefixLength);
}

[CRepr]struct IEnumItemProperties : IUnknown
{
	public new const Guid IID = .(0xf72c8d96, 0x6dbd, 0x11d1, 0xa1, 0xe8, 0x00, 0xc0, 0x4f, 0xc2, 0xfb, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ITEMPROP* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumItemProperties** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnCount) GetCount;
	}


	public HRESULT Next(uint32 celt, ITEMPROP* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumItemProperties** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* pnCount) mut => VT.[Friend]GetCount(&this, pnCount);
}

[CRepr]struct ISubscriptionItem : IUnknown
{
	public new const Guid IID = .(0xa97559f8, 0x6c4a, 0x11d1, 0xa1, 0xe8, 0x00, 0xc0, 0x4f, 0xc2, 0xfb, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pCookie) GetCookie;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SUBSCRIPTIONITEMINFO* pSubscriptionItemInfo) GetSubscriptionItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SUBSCRIPTIONITEMINFO* pSubscriptionItemInfo) SetSubscriptionItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCount, PWSTR* rgwszName, VARIANT* rgValue) ReadProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCount, PWSTR* rgwszName, VARIANT* rgValue) WriteProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumItemProperties** ppEnumItemProperties) EnumProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NotifyChanged;
	}


	public HRESULT GetCookie(Guid* pCookie) mut => VT.[Friend]GetCookie(&this, pCookie);

	public HRESULT GetSubscriptionItemInfo(SUBSCRIPTIONITEMINFO* pSubscriptionItemInfo) mut => VT.[Friend]GetSubscriptionItemInfo(&this, pSubscriptionItemInfo);

	public HRESULT SetSubscriptionItemInfo(SUBSCRIPTIONITEMINFO* pSubscriptionItemInfo) mut => VT.[Friend]SetSubscriptionItemInfo(&this, pSubscriptionItemInfo);

	public HRESULT ReadProperties(uint32 nCount, PWSTR* rgwszName, VARIANT* rgValue) mut => VT.[Friend]ReadProperties(&this, nCount, rgwszName, rgValue);

	public HRESULT WriteProperties(uint32 nCount, PWSTR* rgwszName, VARIANT* rgValue) mut => VT.[Friend]WriteProperties(&this, nCount, rgwszName, rgValue);

	public HRESULT EnumProperties(IEnumItemProperties** ppEnumItemProperties) mut => VT.[Friend]EnumProperties(&this, ppEnumItemProperties);

	public HRESULT NotifyChanged() mut => VT.[Friend]NotifyChanged(&this);
}

[CRepr]struct IEnumSubscription : IUnknown
{
	public new const Guid IID = .(0xf72c8d97, 0x6dbd, 0x11d1, 0xa1, 0xe8, 0x00, 0xc0, 0x4f, 0xc2, 0xfb, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, Guid* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSubscription** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnCount) GetCount;
	}


	public HRESULT Next(uint32 celt, Guid* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSubscription** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* pnCount) mut => VT.[Friend]GetCount(&this, pnCount);
}

[CRepr]struct ISubscriptionMgr : IUnknown
{
	public new const Guid IID = .(0x085fb2c0, 0x0df8, 0x11d1, 0x8f, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, HWND hwnd) DeleteSubscription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL) UpdateSubscription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, BOOL* pfSubscribed) IsSubscribed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, SUBSCRIPTIONINFO* pInfo) GetSubscriptionInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SUBSCRIPTIONTYPE subType, SUBSCRIPTIONINFO* pInfo) GetDefaultInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, HWND hwnd) ShowSubscriptionProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, PWSTR pwszURL, PWSTR pwszFriendlyName, uint32 dwFlags, SUBSCRIPTIONTYPE subsType, SUBSCRIPTIONINFO* pInfo) CreateSubscription;
	}


	public HRESULT DeleteSubscription(PWSTR pwszURL, HWND hwnd) mut => VT.[Friend]DeleteSubscription(&this, pwszURL, hwnd);

	public HRESULT UpdateSubscription(PWSTR pwszURL) mut => VT.[Friend]UpdateSubscription(&this, pwszURL);

	public HRESULT UpdateAll() mut => VT.[Friend]UpdateAll(&this);

	public HRESULT IsSubscribed(PWSTR pwszURL, BOOL* pfSubscribed) mut => VT.[Friend]IsSubscribed(&this, pwszURL, pfSubscribed);

	public HRESULT GetSubscriptionInfo(PWSTR pwszURL, SUBSCRIPTIONINFO* pInfo) mut => VT.[Friend]GetSubscriptionInfo(&this, pwszURL, pInfo);

	public HRESULT GetDefaultInfo(SUBSCRIPTIONTYPE subType, SUBSCRIPTIONINFO* pInfo) mut => VT.[Friend]GetDefaultInfo(&this, subType, pInfo);

	public HRESULT ShowSubscriptionProperties(PWSTR pwszURL, HWND hwnd) mut => VT.[Friend]ShowSubscriptionProperties(&this, pwszURL, hwnd);

	public HRESULT CreateSubscription(HWND hwnd, PWSTR pwszURL, PWSTR pwszFriendlyName, uint32 dwFlags, SUBSCRIPTIONTYPE subsType, SUBSCRIPTIONINFO* pInfo) mut => VT.[Friend]CreateSubscription(&this, hwnd, pwszURL, pwszFriendlyName, dwFlags, subsType, pInfo);
}

[CRepr]struct ISubscriptionMgr2 : ISubscriptionMgr
{
	public new const Guid IID = .(0x614bc270, 0xaedf, 0x11d1, 0xa1, 0xf9, 0x00, 0xc0, 0x4f, 0xc2, 0xfb, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISubscriptionMgr.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszURL, ISubscriptionItem** ppSubscriptionItem) GetItemFromURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pSubscriptionCookie, ISubscriptionItem** ppSubscriptionItem) GetItemFromCookie;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwNumCookies, Guid* pCookies, uint32* pdwRunState) GetSubscriptionRunState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IEnumSubscription** ppEnumSubscriptions) EnumSubscriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 dwNumCookies, Guid* pCookies) UpdateItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwNumCookies, Guid* pCookies) AbortItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AbortAll;
	}


	public HRESULT GetItemFromURL(PWSTR pwszURL, ISubscriptionItem** ppSubscriptionItem) mut => VT.[Friend]GetItemFromURL(&this, pwszURL, ppSubscriptionItem);

	public HRESULT GetItemFromCookie(in Guid pSubscriptionCookie, ISubscriptionItem** ppSubscriptionItem) mut => VT.[Friend]GetItemFromCookie(&this, pSubscriptionCookie, ppSubscriptionItem);

	public HRESULT GetSubscriptionRunState(uint32 dwNumCookies, Guid* pCookies, uint32* pdwRunState) mut => VT.[Friend]GetSubscriptionRunState(&this, dwNumCookies, pCookies, pdwRunState);

	public HRESULT EnumSubscriptions(uint32 dwFlags, IEnumSubscription** ppEnumSubscriptions) mut => VT.[Friend]EnumSubscriptions(&this, dwFlags, ppEnumSubscriptions);

	public HRESULT UpdateItems(uint32 dwFlags, uint32 dwNumCookies, Guid* pCookies) mut => VT.[Friend]UpdateItems(&this, dwFlags, dwNumCookies, pCookies);

	public HRESULT AbortItems(uint32 dwNumCookies, Guid* pCookies) mut => VT.[Friend]AbortItems(&this, dwNumCookies, pCookies);

	public HRESULT AbortAll() mut => VT.[Friend]AbortAll(&this);
}

[CRepr]struct IDataConvert : IUnknown
{
	public new const Guid IID = .(0x0c733a8d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wSrcType, uint16 wDstType, uint cbSrcLength, uint* pcbDstLength, void* pSrc, void* pDst, uint cbDstMaxLength, uint32 dbsSrcStatus, uint32* pdbsStatus, uint8 bPrecision, uint8 bScale, uint32 dwFlags) DataConvert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wSrcType, uint16 wDstType) CanConvert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wSrcType, uint16 wDstType, uint* pcbSrcLength, uint* pcbDstLength, void* pSrc) GetConversionSize;
	}


	public HRESULT DataConvert(uint16 wSrcType, uint16 wDstType, uint cbSrcLength, uint* pcbDstLength, void* pSrc, void* pDst, uint cbDstMaxLength, uint32 dbsSrcStatus, uint32* pdbsStatus, uint8 bPrecision, uint8 bScale, uint32 dwFlags) mut => VT.[Friend]DataConvert(&this, wSrcType, wDstType, cbSrcLength, pcbDstLength, pSrc, pDst, cbDstMaxLength, dbsSrcStatus, pdbsStatus, bPrecision, bScale, dwFlags);

	public HRESULT CanConvert(uint16 wSrcType, uint16 wDstType) mut => VT.[Friend]CanConvert(&this, wSrcType, wDstType);

	public HRESULT GetConversionSize(uint16 wSrcType, uint16 wDstType, uint* pcbSrcLength, uint* pcbDstLength, void* pSrc) mut => VT.[Friend]GetConversionSize(&this, wSrcType, wDstType, pcbSrcLength, pcbDstLength, pSrc);
}

[CRepr]struct IDCInfo : IUnknown
{
	public new const Guid IID = .(0x0c733a9c, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cInfo, uint32* rgeInfoType, DCINFO** prgInfo) GetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cInfo, DCINFO* rgInfo) SetInfo;
	}


	public HRESULT GetInfo(uint32 cInfo, uint32* rgeInfoType, DCINFO** prgInfo) mut => VT.[Friend]GetInfo(&this, cInfo, rgeInfoType, prgInfo);

	public HRESULT SetInfo(uint32 cInfo, DCINFO* rgInfo) mut => VT.[Friend]SetInfo(&this, cInfo, rgInfo);
}

[CRepr]struct DataSourceListener : IUnknown
{
	public new const Guid IID = .(0x7c0ffab2, 0xcd84, 0x11d0, 0x94, 0x9a, 0x00, 0xa0, 0xc9, 0x11, 0x10, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* bstrDM) dataMemberChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* bstrDM) dataMemberAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* bstrDM) dataMemberRemoved;
	}


	public HRESULT dataMemberChanged(uint16* bstrDM) mut => VT.[Friend]dataMemberChanged(&this, bstrDM);

	public HRESULT dataMemberAdded(uint16* bstrDM) mut => VT.[Friend]dataMemberAdded(&this, bstrDM);

	public HRESULT dataMemberRemoved(uint16* bstrDM) mut => VT.[Friend]dataMemberRemoved(&this, bstrDM);
}

[CRepr]struct DataSource : IUnknown
{
	public new const Guid IID = .(0x7c0ffab3, 0xcd84, 0x11d0, 0x94, 0x9a, 0x00, 0xa0, 0xc9, 0x11, 0x10, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* bstrDM, in Guid riid, IUnknown** ppunk) getDataMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, uint16** pbstrDM) getDataMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) getDataMemberCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DataSourceListener* pDSL) addDataSourceListener;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DataSourceListener* pDSL) removeDataSourceListener;
	}


	public HRESULT getDataMember(uint16* bstrDM, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]getDataMember(&this, bstrDM, riid, ppunk);

	public HRESULT getDataMemberName(int32 lIndex, uint16** pbstrDM) mut => VT.[Friend]getDataMemberName(&this, lIndex, pbstrDM);

	public HRESULT getDataMemberCount(int32* plCount) mut => VT.[Friend]getDataMemberCount(&this, plCount);

	public HRESULT addDataSourceListener(DataSourceListener* pDSL) mut => VT.[Friend]addDataSourceListener(&this, pDSL);

	public HRESULT removeDataSourceListener(DataSourceListener* pDSL) mut => VT.[Friend]removeDataSourceListener(&this, pDSL);
}

[CRepr]struct OLEDBSimpleProviderListener : IUnknown
{
	public new const Guid IID = .(0xe0e270c1, 0xc0be, 0x11d0, 0x8f, 0xe4, 0x00, 0xa0, 0xc9, 0x0a, 0x63, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int iColumn) aboutToChangeCell;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int iColumn) cellChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows) aboutToDeleteRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows) deletedRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows) aboutToInsertRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows) insertedRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows) rowsAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OSPXFER xfer) transferComplete;
	}


	public HRESULT aboutToChangeCell(int iRow, int iColumn) mut => VT.[Friend]aboutToChangeCell(&this, iRow, iColumn);

	public HRESULT cellChanged(int iRow, int iColumn) mut => VT.[Friend]cellChanged(&this, iRow, iColumn);

	public HRESULT aboutToDeleteRows(int iRow, int cRows) mut => VT.[Friend]aboutToDeleteRows(&this, iRow, cRows);

	public HRESULT deletedRows(int iRow, int cRows) mut => VT.[Friend]deletedRows(&this, iRow, cRows);

	public HRESULT aboutToInsertRows(int iRow, int cRows) mut => VT.[Friend]aboutToInsertRows(&this, iRow, cRows);

	public HRESULT insertedRows(int iRow, int cRows) mut => VT.[Friend]insertedRows(&this, iRow, cRows);

	public HRESULT rowsAvailable(int iRow, int cRows) mut => VT.[Friend]rowsAvailable(&this, iRow, cRows);

	public HRESULT transferComplete(OSPXFER xfer) mut => VT.[Friend]transferComplete(&this, xfer);
}

[CRepr]struct OLEDBSimpleProvider : IUnknown
{
	public new const Guid IID = .(0xe0e270c0, 0xc0be, 0x11d0, 0x8f, 0xe4, 0x00, 0xa0, 0xc9, 0x0a, 0x63, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* pcRows) getRowCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* pcColumns) getColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int iColumn, OSPRW* prwStatus) getRWStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int iColumn, OSPFORMAT format, VARIANT* pVar) getVariant;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int iColumn, OSPFORMAT format, VARIANT Var) setVariant;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLocale) getLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows, int* pcRowsDeleted) deleteRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRow, int cRows, int* pcRowsInserted) insertRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int iRowStart, int iColumn, VARIANT val, OSPFIND findFlags, OSPCOMP compType, int* piRowFound) find;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLEDBSimpleProviderListener* pospIListener) addOLEDBSimpleProviderListener;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLEDBSimpleProviderListener* pospIListener) removeOLEDBSimpleProviderListener;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbAsynch) isAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* piRows) getEstimatedRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stopTransfer;
	}


	public HRESULT getRowCount(int* pcRows) mut => VT.[Friend]getRowCount(&this, pcRows);

	public HRESULT getColumnCount(int* pcColumns) mut => VT.[Friend]getColumnCount(&this, pcColumns);

	public HRESULT getRWStatus(int iRow, int iColumn, OSPRW* prwStatus) mut => VT.[Friend]getRWStatus(&this, iRow, iColumn, prwStatus);

	public HRESULT getVariant(int iRow, int iColumn, OSPFORMAT format, VARIANT* pVar) mut => VT.[Friend]getVariant(&this, iRow, iColumn, format, pVar);

	public HRESULT setVariant(int iRow, int iColumn, OSPFORMAT format, VARIANT Var) mut => VT.[Friend]setVariant(&this, iRow, iColumn, format, Var);

	public HRESULT getLocale(BSTR* pbstrLocale) mut => VT.[Friend]getLocale(&this, pbstrLocale);

	public HRESULT deleteRows(int iRow, int cRows, int* pcRowsDeleted) mut => VT.[Friend]deleteRows(&this, iRow, cRows, pcRowsDeleted);

	public HRESULT insertRows(int iRow, int cRows, int* pcRowsInserted) mut => VT.[Friend]insertRows(&this, iRow, cRows, pcRowsInserted);

	public HRESULT find(int iRowStart, int iColumn, VARIANT val, OSPFIND findFlags, OSPCOMP compType, int* piRowFound) mut => VT.[Friend]find(&this, iRowStart, iColumn, val, findFlags, compType, piRowFound);

	public HRESULT addOLEDBSimpleProviderListener(OLEDBSimpleProviderListener* pospIListener) mut => VT.[Friend]addOLEDBSimpleProviderListener(&this, pospIListener);

	public HRESULT removeOLEDBSimpleProviderListener(OLEDBSimpleProviderListener* pospIListener) mut => VT.[Friend]removeOLEDBSimpleProviderListener(&this, pospIListener);

	public HRESULT isAsync(BOOL* pbAsynch) mut => VT.[Friend]isAsync(&this, pbAsynch);

	public HRESULT getEstimatedRows(int* piRows) mut => VT.[Friend]getEstimatedRows(&this, piRows);

	public HRESULT stopTransfer() mut => VT.[Friend]stopTransfer(&this);
}

[CRepr]struct DataSourceObject : IDispatch
{
	public new const Guid IID = .(0x0ae9a4e4, 0x18d4, 0x11d1, 0xb3, 0xb3, 0x00, 0xaa, 0x00, 0xc1, 0xa9, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IService : IUnknown
{
	public new const Guid IID = .(0x06210e88, 0x01f5, 0x11d1, 0xb5, 0x12, 0x00, 0x80, 0xc7, 0x81, 0xc3, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkInner) InvokeService;
	}


	public HRESULT InvokeService(IUnknown* pUnkInner) mut => VT.[Friend]InvokeService(&this, pUnkInner);
}

[CRepr]struct IDBPromptInitialize : IUnknown
{
	public new const Guid IID = .(0x2206ccb0, 0x19c1, 0x11d1, 0x89, 0xe0, 0x00, 0xc0, 0x4f, 0xd7, 0xa8, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, HWND hWndParent, uint32 dwPromptOptions, uint32 cSourceTypeFilter, uint32* rgSourceTypeFilter, PWSTR pwszszzProviderFilter, in Guid riid, IUnknown** ppDataSource) PromptDataSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, uint32 dwPromptOptions, PWSTR pwszInitialDirectory, PWSTR pwszInitialFile, PWSTR* ppwszSelectedFile) PromptFileName;
	}


	public HRESULT PromptDataSource(IUnknown* pUnkOuter, HWND hWndParent, uint32 dwPromptOptions, uint32 cSourceTypeFilter, uint32* rgSourceTypeFilter, PWSTR pwszszzProviderFilter, in Guid riid, IUnknown** ppDataSource) mut => VT.[Friend]PromptDataSource(&this, pUnkOuter, hWndParent, dwPromptOptions, cSourceTypeFilter, rgSourceTypeFilter, pwszszzProviderFilter, riid, ppDataSource);

	public HRESULT PromptFileName(HWND hWndParent, uint32 dwPromptOptions, PWSTR pwszInitialDirectory, PWSTR pwszInitialFile, PWSTR* ppwszSelectedFile) mut => VT.[Friend]PromptFileName(&this, hWndParent, dwPromptOptions, pwszInitialDirectory, pwszInitialFile, ppwszSelectedFile);
}

[CRepr]struct IDataInitialize : IUnknown
{
	public new const Guid IID = .(0x2206ccb1, 0x19c1, 0x11d1, 0x89, 0xe0, 0x00, 0xc0, 0x4f, 0xd7, 0xa8, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, uint32 dwClsCtx, PWSTR pwszInitializationString, in Guid riid, IUnknown** ppDataSource) GetDataSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDataSource, uint8 fIncludePassword, PWSTR* ppwszInitString) GetInitializationString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidProvider, IUnknown* pUnkOuter, uint32 dwClsCtx, PWSTR pwszReserved, in Guid riid, IUnknown** ppDataSource) CreateDBInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidProvider, IUnknown* pUnkOuter, uint32 dwClsCtx, PWSTR pwszReserved, COSERVERINFO* pServerInfo, uint32 cmq, MULTI_QI* rgmqResults) CreateDBInstanceEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFileName, PWSTR* ppwszInitializationString) LoadStringFromStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFileName, PWSTR pwszInitializationString, uint32 dwCreationDisposition) WriteStringToStorage;
	}


	public HRESULT GetDataSource(IUnknown* pUnkOuter, uint32 dwClsCtx, PWSTR pwszInitializationString, in Guid riid, IUnknown** ppDataSource) mut => VT.[Friend]GetDataSource(&this, pUnkOuter, dwClsCtx, pwszInitializationString, riid, ppDataSource);

	public HRESULT GetInitializationString(IUnknown* pDataSource, uint8 fIncludePassword, PWSTR* ppwszInitString) mut => VT.[Friend]GetInitializationString(&this, pDataSource, fIncludePassword, ppwszInitString);

	public HRESULT CreateDBInstance(in Guid clsidProvider, IUnknown* pUnkOuter, uint32 dwClsCtx, PWSTR pwszReserved, in Guid riid, IUnknown** ppDataSource) mut => VT.[Friend]CreateDBInstance(&this, clsidProvider, pUnkOuter, dwClsCtx, pwszReserved, riid, ppDataSource);

	public HRESULT CreateDBInstanceEx(in Guid clsidProvider, IUnknown* pUnkOuter, uint32 dwClsCtx, PWSTR pwszReserved, COSERVERINFO* pServerInfo, uint32 cmq, MULTI_QI* rgmqResults) mut => VT.[Friend]CreateDBInstanceEx(&this, clsidProvider, pUnkOuter, dwClsCtx, pwszReserved, pServerInfo, cmq, rgmqResults);

	public HRESULT LoadStringFromStorage(PWSTR pwszFileName, PWSTR* ppwszInitializationString) mut => VT.[Friend]LoadStringFromStorage(&this, pwszFileName, ppwszInitializationString);

	public HRESULT WriteStringToStorage(PWSTR pwszFileName, PWSTR pwszInitializationString, uint32 dwCreationDisposition) mut => VT.[Friend]WriteStringToStorage(&this, pwszFileName, pwszInitializationString, dwCreationDisposition);
}

[CRepr]struct IDataSourceLocator : IDispatch
{
	public new const Guid IID = .(0x2206ccb2, 0x19c1, 0x11d1, 0x89, 0xe0, 0x00, 0xc0, 0x4f, 0xd7, 0xa8, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwndParent) get_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent) put_hWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppADOConnection) PromptNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppADOConnection, int16* pbSuccess) PromptEdit;
	}


	public HRESULT get_hWnd(HWND* phwndParent) mut => VT.[Friend]get_hWnd(&this, phwndParent);

	public HRESULT put_hWnd(HWND hwndParent) mut => VT.[Friend]put_hWnd(&this, hwndParent);

	public HRESULT PromptNew(IDispatch** ppADOConnection) mut => VT.[Friend]PromptNew(&this, ppADOConnection);

	public HRESULT PromptEdit(IDispatch** ppADOConnection, int16* pbSuccess) mut => VT.[Friend]PromptEdit(&this, ppADOConnection, pbSuccess);
}

[CRepr]struct IRowsetChangeExtInfo : IUnknown
{
	public new const Guid IID = .(0x0c733a8f, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint hRow, uint* phRowOriginal) GetOriginalRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hReserved, uint hRow, uint32 cColumnOrdinals, uint32* rgiOrdinals, uint32* rgColumnStatus) GetPendingColumns;
	}


	public HRESULT GetOriginalRow(uint hReserved, uint hRow, uint* phRowOriginal) mut => VT.[Friend]GetOriginalRow(&this, hReserved, hRow, phRowOriginal);

	public HRESULT GetPendingColumns(uint hReserved, uint hRow, uint32 cColumnOrdinals, uint32* rgiOrdinals, uint32* rgColumnStatus) mut => VT.[Friend]GetPendingColumns(&this, hReserved, hRow, cColumnOrdinals, rgiOrdinals, rgColumnStatus);
}

[CRepr]struct ISQLRequestDiagFields : IUnknown
{
	public new const Guid IID = .(0x228972f0, 0xb5ff, 0x11d0, 0x8a, 0x80, 0x00, 0xc0, 0x4f, 0xd6, 0x11, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cDiagFields, KAGREQDIAG* rgDiagFields) RequestDiagFields;
	}


	public HRESULT RequestDiagFields(uint32 cDiagFields, KAGREQDIAG* rgDiagFields) mut => VT.[Friend]RequestDiagFields(&this, cDiagFields, rgDiagFields);
}

[CRepr]struct ISQLGetDiagField : IUnknown
{
	public new const Guid IID = .(0x228972f1, 0xb5ff, 0x11d0, 0x8a, 0x80, 0x00, 0xc0, 0x4f, 0xd6, 0x11, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KAGGETDIAG* pDiagInfo) GetDiagField;
	}


	public HRESULT GetDiagField(KAGGETDIAG* pDiagInfo) mut => VT.[Friend]GetDiagField(&this, pDiagInfo);
}

[CRepr]struct IRowsetNextRowset : IUnknown
{
	public new const Guid IID = .(0x0c733a72, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, IUnknown** ppNextRowset) GetNextRowset;
	}


	public HRESULT GetNextRowset(IUnknown* pUnkOuter, in Guid riid, IUnknown** ppNextRowset) mut => VT.[Friend]GetNextRowset(&this, pUnkOuter, riid, ppNextRowset);
}

[CRepr]struct IRowsetNewRowAfter : IUnknown
{
	public new const Guid IID = .(0x0c733a71, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint32 cbbmPrevious, uint8* pbmPrevious, HACCESSOR hAccessor, uint8* pData, uint* phRow) SetNewDataAfter;
	}


	public HRESULT SetNewDataAfter(uint hChapter, uint32 cbbmPrevious, uint8* pbmPrevious, HACCESSOR hAccessor, uint8* pData, uint* phRow) mut => VT.[Friend]SetNewDataAfter(&this, hChapter, cbbmPrevious, pbmPrevious, hAccessor, pData, phRow);
}

[CRepr]struct IRowsetWithParameters : IUnknown
{
	public new const Guid IID = .(0x0c733a6e, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcParams, DBPARAMINFO** prgParamInfo, uint16** ppNamesBuffer) GetParameterInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBPARAMS* pParams, uint32* pulErrorParam, uint* phReserved) Requery;
	}


	public HRESULT GetParameterInfo(uint* pcParams, DBPARAMINFO** prgParamInfo, uint16** ppNamesBuffer) mut => VT.[Friend]GetParameterInfo(&this, pcParams, prgParamInfo, ppNamesBuffer);

	public HRESULT Requery(DBPARAMS* pParams, uint32* pulErrorParam, uint* phReserved) mut => VT.[Friend]Requery(&this, pParams, pulErrorParam, phReserved);
}

[CRepr]struct IRowsetAsynch : IUnknown
{
	public new const Guid IID = .(0x0c733a0f, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pulDenominator, uint* pulNumerator, uint* pcRows, BOOL* pfNewRows) RatioFinished;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
	}


	public HRESULT RatioFinished(uint* pulDenominator, uint* pulNumerator, uint* pcRows, BOOL* pfNewRows) mut => VT.[Friend]RatioFinished(&this, pulDenominator, pulNumerator, pcRows, pfNewRows);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);
}

[CRepr]struct IRowsetKeys : IUnknown
{
	public new const Guid IID = .(0x0c733a12, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcColumns, uint** prgColumns) ListKeys;
	}


	public HRESULT ListKeys(uint* pcColumns, uint** prgColumns) mut => VT.[Friend]ListKeys(&this, pcColumns, prgColumns);
}

[CRepr]struct IRowsetWatchAll : IUnknown
{
	public new const Guid IID = .(0x0c733a73, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Acknowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopWatching;
	}


	public HRESULT Acknowledge() mut => VT.[Friend]Acknowledge(&this);

	public HRESULT Start() mut => VT.[Friend]Start(&this);

	public HRESULT StopWatching() mut => VT.[Friend]StopWatching(&this);
}

[CRepr]struct IRowsetWatchNotify : IUnknown
{
	public new const Guid IID = .(0x0c733a44, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRowset* pRowset, uint32 eChangeReason) OnChange;
	}


	public HRESULT OnChange(IRowset* pRowset, uint32 eChangeReason) mut => VT.[Friend]OnChange(&this, pRowset, eChangeReason);
}

[CRepr]struct IRowsetWatchRegion : IRowsetWatchAll
{
	public new const Guid IID = .(0x0c733a45, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRowsetWatchAll.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWatchMode, uint* phRegion) CreateWatchRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRegion, uint32 dwWatchMode) ChangeWatchMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRegion) DeleteWatchRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRegion, uint32* pdwWatchMode, uint* phChapter, uint* pcbBookmark, uint8** ppBookmark, int* pcRows) GetWatchRegionInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* pcChangesObtained, DBROWWATCHCHANGE** prgChanges) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hRegion, uint hChapter, uint cbBookmark, uint8* pBookmark, int cRows) ShrinkWatchRegion;
	}


	public HRESULT CreateWatchRegion(uint32 dwWatchMode, uint* phRegion) mut => VT.[Friend]CreateWatchRegion(&this, dwWatchMode, phRegion);

	public HRESULT ChangeWatchMode(uint hRegion, uint32 dwWatchMode) mut => VT.[Friend]ChangeWatchMode(&this, hRegion, dwWatchMode);

	public HRESULT DeleteWatchRegion(uint hRegion) mut => VT.[Friend]DeleteWatchRegion(&this, hRegion);

	public HRESULT GetWatchRegionInfo(uint hRegion, uint32* pdwWatchMode, uint* phChapter, uint* pcbBookmark, uint8** ppBookmark, int* pcRows) mut => VT.[Friend]GetWatchRegionInfo(&this, hRegion, pdwWatchMode, phChapter, pcbBookmark, ppBookmark, pcRows);

	public HRESULT Refresh(uint* pcChangesObtained, DBROWWATCHCHANGE** prgChanges) mut => VT.[Friend]Refresh(&this, pcChangesObtained, prgChanges);

	public HRESULT ShrinkWatchRegion(uint hRegion, uint hChapter, uint cbBookmark, uint8* pBookmark, int cRows) mut => VT.[Friend]ShrinkWatchRegion(&this, hRegion, hChapter, cbBookmark, pBookmark, cRows);
}

[CRepr]struct IRowsetCopyRows : IUnknown
{
	public new const Guid IID = .(0x0c733a6b, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 hSourceID) CloseSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 hSourceID, uint hReserved, int cRows, uint* rghRows, uint32 bFlags) CopyByHROWS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 hSourceID, uint hReserved, int cRows, uint32 bFlags, uint* pcRowsCopied) CopyRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRowset* pRowsetSource, uint cColIds, int* rgSourceColumns, int* rgTargetColumns, uint16* phSourceID) DefineSource;
	}


	public HRESULT CloseSource(uint16 hSourceID) mut => VT.[Friend]CloseSource(&this, hSourceID);

	public HRESULT CopyByHROWS(uint16 hSourceID, uint hReserved, int cRows, uint* rghRows, uint32 bFlags) mut => VT.[Friend]CopyByHROWS(&this, hSourceID, hReserved, cRows, rghRows, bFlags);

	public HRESULT CopyRows(uint16 hSourceID, uint hReserved, int cRows, uint32 bFlags, uint* pcRowsCopied) mut => VT.[Friend]CopyRows(&this, hSourceID, hReserved, cRows, bFlags, pcRowsCopied);

	public HRESULT DefineSource(IRowset* pRowsetSource, uint cColIds, int* rgSourceColumns, int* rgTargetColumns, uint16* phSourceID) mut => VT.[Friend]DefineSource(&this, pRowsetSource, cColIds, rgSourceColumns, rgTargetColumns, phSourceID);
}

[CRepr]struct IReadData : IUnknown
{
	public new const Guid IID = .(0x0c733a6a, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter, uint cbBookmark, uint8* pBookmark, int lRowsOffset, HACCESSOR hAccessor, int cRows, uint* pcRowsObtained, uint8** ppFixedData, uint* pcbVariableTotal, uint8** ppVariableData) ReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hChapter) ReleaseChapter;
	}


	public HRESULT ReadData(uint hChapter, uint cbBookmark, uint8* pBookmark, int lRowsOffset, HACCESSOR hAccessor, int cRows, uint* pcRowsObtained, uint8** ppFixedData, uint* pcbVariableTotal, uint8** ppVariableData) mut => VT.[Friend]ReadData(&this, hChapter, cbBookmark, pBookmark, lRowsOffset, hAccessor, cRows, pcRowsObtained, ppFixedData, pcbVariableTotal, ppVariableData);

	public HRESULT ReleaseChapter(uint hChapter) mut => VT.[Friend]ReleaseChapter(&this, hChapter);
}

[CRepr]struct ICommandCost : IUnknown
{
	public new const Guid IID = .(0x0c733a4e, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRowsetName, uint32* pcCostLimits, DBCOST** prgCostLimits) GetAccumulatedCost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRowsetName, uint32* pcCostEstimates, DBCOST* prgCostEstimates) GetCostEstimate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRowsetName, uint32* pcCostGoals, DBCOST* prgCostGoals) GetCostGoals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRowsetName, uint32* pcCostLimits, DBCOST* prgCostLimits) GetCostLimits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRowsetName, uint32 cCostGoals, DBCOST* rgCostGoals) SetCostGoals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszRowsetName, uint32 cCostLimits, DBCOST* prgCostLimits, uint32 dwExecutionFlags) SetCostLimits;
	}


	public HRESULT GetAccumulatedCost(PWSTR pwszRowsetName, uint32* pcCostLimits, DBCOST** prgCostLimits) mut => VT.[Friend]GetAccumulatedCost(&this, pwszRowsetName, pcCostLimits, prgCostLimits);

	public HRESULT GetCostEstimate(PWSTR pwszRowsetName, uint32* pcCostEstimates, DBCOST* prgCostEstimates) mut => VT.[Friend]GetCostEstimate(&this, pwszRowsetName, pcCostEstimates, prgCostEstimates);

	public HRESULT GetCostGoals(PWSTR pwszRowsetName, uint32* pcCostGoals, DBCOST* prgCostGoals) mut => VT.[Friend]GetCostGoals(&this, pwszRowsetName, pcCostGoals, prgCostGoals);

	public HRESULT GetCostLimits(PWSTR pwszRowsetName, uint32* pcCostLimits, DBCOST* prgCostLimits) mut => VT.[Friend]GetCostLimits(&this, pwszRowsetName, pcCostLimits, prgCostLimits);

	public HRESULT SetCostGoals(PWSTR pwszRowsetName, uint32 cCostGoals, DBCOST* rgCostGoals) mut => VT.[Friend]SetCostGoals(&this, pwszRowsetName, cCostGoals, rgCostGoals);

	public HRESULT SetCostLimits(PWSTR pwszRowsetName, uint32 cCostLimits, DBCOST* prgCostLimits, uint32 dwExecutionFlags) mut => VT.[Friend]SetCostLimits(&this, pwszRowsetName, cCostLimits, prgCostLimits, dwExecutionFlags);
}

[CRepr]struct ICommandValidate : IUnknown
{
	public new const Guid IID = .(0x0c733a18, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ValidateCompletely;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ValidateSyntax;
	}


	public HRESULT ValidateCompletely() mut => VT.[Friend]ValidateCompletely(&this);

	public HRESULT ValidateSyntax() mut => VT.[Friend]ValidateSyntax(&this);
}

[CRepr]struct ITableRename : IUnknown
{
	public new const Guid IID = .(0x0c733a77, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableId, DBID* pOldColumnId, DBID* pNewColumnId) RenameColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pOldTableId, DBID* pOldIndexId, DBID* pNewTableId, DBID* pNewIndexId) RenameTable;
	}


	public HRESULT RenameColumn(DBID* pTableId, DBID* pOldColumnId, DBID* pNewColumnId) mut => VT.[Friend]RenameColumn(&this, pTableId, pOldColumnId, pNewColumnId);

	public HRESULT RenameTable(DBID* pOldTableId, DBID* pOldIndexId, DBID* pNewTableId, DBID* pNewIndexId) mut => VT.[Friend]RenameTable(&this, pOldTableId, pOldIndexId, pNewTableId, pNewIndexId);
}

[CRepr]struct IDBSchemaCommand : IUnknown
{
	public new const Guid IID = .(0x0c733a50, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid rguidSchema, ICommand** ppCommand) GetCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcSchemas, Guid** prgSchemas) GetSchemas;
	}


	public HRESULT GetCommand(IUnknown* pUnkOuter, in Guid rguidSchema, ICommand** ppCommand) mut => VT.[Friend]GetCommand(&this, pUnkOuter, rguidSchema, ppCommand);

	public HRESULT GetSchemas(uint32* pcSchemas, Guid** prgSchemas) mut => VT.[Friend]GetSchemas(&this, pcSchemas, prgSchemas);
}

[CRepr]struct IProvideMoniker : IUnknown
{
	public new const Guid IID = .(0x0c733a4d, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker** ppIMoniker) GetMoniker;
	}


	public HRESULT GetMoniker(IMoniker** ppIMoniker) mut => VT.[Friend]GetMoniker(&this, ppIMoniker);
}

[CRepr]struct ISearchQueryHits : IUnknown
{
	public new const Guid IID = .(0xed8ce7e0, 0x106c, 0x11ce, 0x84, 0xe2, 0x00, 0xaa, 0x00, 0x4b, 0x99, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, IFilter* pflt, uint32 ulFlags) Init;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, uint32* pcMnk, IMoniker*** papMnk) NextHitMoniker;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, uint32* pcRegion, FILTERREGION** paRegion) NextHitOffset;
	}


	public int32 Init(IFilter* pflt, uint32 ulFlags) mut => VT.[Friend]Init(&this, pflt, ulFlags);

	public int32 NextHitMoniker(uint32* pcMnk, IMoniker*** papMnk) mut => VT.[Friend]NextHitMoniker(&this, pcMnk, papMnk);

	public int32 NextHitOffset(uint32* pcRegion, FILTERREGION** paRegion) mut => VT.[Friend]NextHitOffset(&this, pcRegion, paRegion);
}

[CRepr]struct IRowsetQueryStatus : IUnknown
{
	public new const Guid IID = .(0xa7ac77ed, 0xf8d7, 0x11ce, 0xa7, 0x98, 0x00, 0x20, 0xf8, 0x00, 0x80, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus, uint32* pcFilteredDocuments, uint32* pcDocumentsToFilter, uint* pdwRatioFinishedDenominator, uint* pdwRatioFinishedNumerator, uint cbBmk, uint8* pBmk, uint* piRowBmk, uint* pcRowsTotal) GetStatusEx;
	}


	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT GetStatusEx(uint32* pdwStatus, uint32* pcFilteredDocuments, uint32* pcDocumentsToFilter, uint* pdwRatioFinishedDenominator, uint* pdwRatioFinishedNumerator, uint cbBmk, uint8* pBmk, uint* piRowBmk, uint* pcRowsTotal) mut => VT.[Friend]GetStatusEx(&this, pdwStatus, pcFilteredDocuments, pcDocumentsToFilter, pdwRatioFinishedDenominator, pdwRatioFinishedNumerator, cbBmk, pBmk, piRowBmk, pcRowsTotal);
}

[CRepr]struct IUMSInitialize : IUnknown
{
	public new const Guid IID = .(0x5cf4ca14, 0xef21, 0x11d0, 0x97, 0xe7, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pUMS) Initialize;
	}


	public HRESULT Initialize(void* pUMS) mut => VT.[Friend]Initialize(&this, pUMS);
}

[CRepr]struct IUMS
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 ticks) SqlUmsSuspend;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 ticks) SqlUmsYield;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) SqlUmsSwitchPremptive;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) SqlUmsSwitchNonPremptive;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) SqlUmsFIsPremptive;
	}


	public void SqlUmsSuspend(uint32 ticks) mut => VT.[Friend]SqlUmsSuspend(&this, ticks);

	public void SqlUmsYield(uint32 ticks) mut => VT.[Friend]SqlUmsYield(&this, ticks);

	public void SqlUmsSwitchPremptive() mut => VT.[Friend]SqlUmsSwitchPremptive(&this);

	public void SqlUmsSwitchNonPremptive() mut => VT.[Friend]SqlUmsSwitchNonPremptive(&this);

	public BOOL SqlUmsFIsPremptive() mut => VT.[Friend]SqlUmsFIsPremptive(&this);
}

[CRepr]struct ISQLServerErrorInfo : IUnknown
{
	public new const Guid IID = .(0x5cf4ca12, 0xef21, 0x11d0, 0x97, 0xe7, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SSERRORINFO** ppErrorInfo, uint16** ppStringsBuffer) GetErrorInfo;
	}


	public HRESULT GetErrorInfo(SSERRORINFO** ppErrorInfo, uint16** ppStringsBuffer) mut => VT.[Friend]GetErrorInfo(&this, ppErrorInfo, ppStringsBuffer);
}

[CRepr]struct IRowsetFastLoad : IUnknown
{
	public new const Guid IID = .(0x5cf4ca13, 0xef21, 0x11d0, 0x97, 0xe7, 0x00, 0xc0, 0x4f, 0xc2, 0xad, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCESSOR hAccessor, void* pData) InsertRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDone) Commit;
	}


	public HRESULT InsertRow(HACCESSOR hAccessor, void* pData) mut => VT.[Friend]InsertRow(&this, hAccessor, pData);

	public HRESULT Commit(BOOL fDone) mut => VT.[Friend]Commit(&this, fDone);
}

[CRepr]struct ISchemaLock : IUnknown
{
	public new const Guid IID = .(0x4c2389fb, 0x2511, 0x11d4, 0xb2, 0x58, 0x00, 0xc0, 0x4f, 0x79, 0x71, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DBID* pTableID, uint32 lmMode, HANDLE* phLockHandle, uint64* pTableVersion) GetSchemaLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hLockHandle) ReleaseSchemaLock;
	}


	public HRESULT GetSchemaLock(DBID* pTableID, uint32 lmMode, HANDLE* phLockHandle, uint64* pTableVersion) mut => VT.[Friend]GetSchemaLock(&this, pTableID, lmMode, phLockHandle, pTableVersion);

	public HRESULT ReleaseSchemaLock(HANDLE hLockHandle) mut => VT.[Friend]ReleaseSchemaLock(&this, hLockHandle);
}

#endregion

#region Functions
public static
{
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBindCol(void* StatementHandle, uint16 ColumnNumber, int16 TargetType, void* TargetValue, int64 BufferLength, int64* StrLen_or_Ind);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBindParam(void* StatementHandle, uint16 ParameterNumber, int16 ValueType, int16 ParameterType, uint64 LengthPrecision, int16 ParameterScale, void* ParameterValue, int64* StrLen_or_Ind);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttribute(void* StatementHandle, uint16 ColumnNumber, uint16 FieldIdentifier, void* CharacterAttribute, int16 BufferLength, int16* StringLength, int64* NumericAttribute);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeCol(void* StatementHandle, uint16 ColumnNumber, uint8* ColumnName, int16 BufferLength, int16* NameLength, int16* DataType, uint64* ColumnSize, int16* DecimalDigits, int16* Nullable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFetchScroll(void* StatementHandle, int16 FetchOrientation, int64 FetchOffset);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetData(void* StatementHandle, uint16 ColumnNumber, int16 TargetType, void* TargetValue, int64 BufferLength, int64* StrLen_or_IndPtr);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescRec(void* DescriptorHandle, int16 RecNumber, uint8* Name, int16 BufferLength, int16* StringLengthPtr, int16* TypePtr, int16* SubTypePtr, int64* LengthPtr, int16* PrecisionPtr, int16* ScalePtr, int16* NullablePtr);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPutData(void* StatementHandle, void* Data, int64 StrLen_or_Ind);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLRowCount(void* StatementHandle, int64* RowCount);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectOption(void* ConnectionHandle, uint16 Option, uint64 Value);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetDescRec(void* DescriptorHandle, int16 RecNumber, int16 Type, int16 SubType, int64 Length, int16 Precision, int16 Scale, void* Data, int64* StringLength, int64* Indicator);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetParam(void* StatementHandle, uint16 ParameterNumber, int16 ValueType, int16 ParameterType, uint64 LengthPrecision, int16 ParameterScale, void* ParameterValue, int64* StrLen_or_Ind);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetStmtOption(void* StatementHandle, uint16 Option, uint64 Value);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributes(void* hstmt, uint16 icol, uint16 fDescType, void* rgbDesc, int16 cbDescMax, int16* pcbDesc, int64* pfDesc);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeParam(void* hstmt, uint16 ipar, int16* pfSqlType, uint64* pcbParamDef, int16* pibScale, int16* pfNullable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLExtendedFetch(void* hstmt, uint16 fFetchType, int64 irow, uint64* pcrow, uint16* rgfRowStatus);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLParamOptions(void* hstmt, uint64 crow, uint64* pirow);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetPos(void* hstmt, uint64 irow, uint16 fOption, uint16 fLock);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBindParameter(void* hstmt, uint16 ipar, int16 fParamType, int16 fCType, int16 fSqlType, uint64 cbColDef, int16 ibScale, void* rgbValue, int64 cbValueMax, int64* pcbValue);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetScrollOptions(void* hstmt, uint16 fConcurrency, int64 crowKeyset, uint16 crowRowset);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributeW(void* hstmt, uint16 iCol, uint16 iField, void* pCharAttr, int16 cbDescMax, int16* pcbCharAttr, int64* pNumAttr);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributesW(void* hstmt, uint16 icol, uint16 fDescType, void* rgbDesc, int16 cbDescMax, int16* pcbDesc, int64* pfDesc);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeColW(void* hstmt, uint16 icol, uint16* szColName, int16 cchColNameMax, int16* pcchColName, int16* pfSqlType, uint64* pcbColDef, int16* pibScale, int16* pfNullable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescRecW(void* hdesc, int16 iRecord, uint16* szName, int16 cchNameMax, int16* pcchName, int16* pfType, int16* pfSubType, int64* pLength, int16* pPrecision, int16* pScale, int16* pNullable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectOptionW(void* hdbc, uint16 fOption, uint64 vParam);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributeA(void* hstmt, int16 iCol, int16 iField, void* pCharAttr, int16 cbCharAttrMax, int16* pcbCharAttr, int64* pNumAttr);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributesA(void* hstmt, uint16 icol, uint16 fDescType, void* rgbDesc, int16 cbDescMax, int16* pcbDesc, int64* pfDesc);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeColA(void* hstmt, uint16 icol, uint8* szColName, int16 cbColNameMax, int16* pcbColName, int16* pfSqlType, uint64* pcbColDef, int16* pibScale, int16* pfNullable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescRecA(void* hdesc, int16 iRecord, uint8* szName, int16 cbNameMax, int16* pcbName, int16* pfType, int16* pfSubType, int64* pLength, int16* pPrecision, int16* pScale, int16* pNullable);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectOptionA(void* hdbc, uint16 fOption, uint64 vParam);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLAllocConnect(void* EnvironmentHandle, void** ConnectionHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLAllocEnv(void** EnvironmentHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLAllocHandle(int16 HandleType, void* InputHandle, void** OutputHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLAllocStmt(void* ConnectionHandle, void** StatementHandle);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBindCol(void* StatementHandle, uint16 ColumnNumber, int16 TargetType, void* TargetValue, int32 BufferLength, int32* StrLen_or_Ind);

#endif
#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBindParam(void* StatementHandle, uint16 ParameterNumber, int16 ValueType, int16 ParameterType, uint32 LengthPrecision, int16 ParameterScale, void* ParameterValue, int32* StrLen_or_Ind);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLCancel(void* StatementHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLCancelHandle(int16 HandleType, void* InputHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLCloseCursor(void* StatementHandle);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttribute(void* StatementHandle, uint16 ColumnNumber, uint16 FieldIdentifier, void* CharacterAttribute, int16 BufferLength, int16* StringLength, void* NumericAttribute);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColumns(void* StatementHandle, uint8* CatalogName, int16 NameLength1, uint8* SchemaName, int16 NameLength2, uint8* TableName, int16 NameLength3, uint8* ColumnName, int16 NameLength4);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLCompleteAsync(int16 HandleType, void* Handle, int16* AsyncRetCodePtr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLConnect(void* ConnectionHandle, uint8* ServerName, int16 NameLength1, uint8* UserName, int16 NameLength2, uint8* Authentication, int16 NameLength3);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLCopyDesc(void* SourceDescHandle, void* TargetDescHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDataSources(void* EnvironmentHandle, uint16 Direction, uint8* ServerName, int16 BufferLength1, int16* NameLength1Ptr, uint8* Description, int16 BufferLength2, int16* NameLength2Ptr);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeCol(void* StatementHandle, uint16 ColumnNumber, uint8* ColumnName, int16 BufferLength, int16* NameLength, int16* DataType, uint32* ColumnSize, int16* DecimalDigits, int16* Nullable);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDisconnect(void* ConnectionHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLEndTran(int16 HandleType, void* Handle, int16 CompletionType);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLError(void* EnvironmentHandle, void* ConnectionHandle, void* StatementHandle, uint8* Sqlstate, int32* NativeError, uint8* MessageText, int16 BufferLength, int16* TextLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLExecDirect(void* StatementHandle, uint8* StatementText, int32 TextLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLExecute(void* StatementHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFetch(void* StatementHandle);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFetchScroll(void* StatementHandle, int16 FetchOrientation, int32 FetchOffset);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFreeConnect(void* ConnectionHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFreeEnv(void* EnvironmentHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFreeHandle(int16 HandleType, void* Handle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLFreeStmt(void* StatementHandle, uint16 Option);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetConnectAttr(void* ConnectionHandle, int32 Attribute, void* Value, int32 BufferLength, int32* StringLengthPtr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetConnectOption(void* ConnectionHandle, uint16 Option, void* Value);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetCursorName(void* StatementHandle, uint8* CursorName, int16 BufferLength, int16* NameLengthPtr);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetData(void* StatementHandle, uint16 ColumnNumber, int16 TargetType, void* TargetValue, int32 BufferLength, int32* StrLen_or_IndPtr);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescField(void* DescriptorHandle, int16 RecNumber, int16 FieldIdentifier, void* Value, int32 BufferLength, int32* StringLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescRec(void* DescriptorHandle, int16 RecNumber, uint8* Name, int16 BufferLength, int16* StringLengthPtr, int16* TypePtr, int16* SubTypePtr, int32* LengthPtr, int16* PrecisionPtr, int16* ScalePtr, int16* NullablePtr);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDiagField(int16 HandleType, void* Handle, int16 RecNumber, int16 DiagIdentifier, void* DiagInfo, int16 BufferLength, int16* StringLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDiagRec(int16 HandleType, void* Handle, int16 RecNumber, uint8* Sqlstate, int32* NativeError, uint8* MessageText, int16 BufferLength, int16* TextLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetEnvAttr(void* EnvironmentHandle, int32 Attribute, void* Value, int32 BufferLength, int32* StringLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetFunctions(void* ConnectionHandle, uint16 FunctionId, uint16* Supported);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetInfo(void* ConnectionHandle, uint16 InfoType, void* InfoValue, int16 BufferLength, int16* StringLengthPtr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetStmtAttr(void* StatementHandle, int32 Attribute, void* Value, int32 BufferLength, int32* StringLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetStmtOption(void* StatementHandle, uint16 Option, void* Value);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetTypeInfo(void* StatementHandle, int16 DataType);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLNumResultCols(void* StatementHandle, int16* ColumnCount);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLParamData(void* StatementHandle, void** Value);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPrepare(void* StatementHandle, uint8* StatementText, int32 TextLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPutData(void* StatementHandle, void* Data, int32 StrLen_or_Ind);

#endif
#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLRowCount(void* StatementHandle, int32* RowCount);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectAttr(void* ConnectionHandle, int32 Attribute, void* Value, int32 StringLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectOption(void* ConnectionHandle, uint16 Option, uint32 Value);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetCursorName(void* StatementHandle, uint8* CursorName, int16 NameLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetDescField(void* DescriptorHandle, int16 RecNumber, int16 FieldIdentifier, void* Value, int32 BufferLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetDescRec(void* DescriptorHandle, int16 RecNumber, int16 Type, int16 SubType, int32 Length, int16 Precision, int16 Scale, void* Data, int32* StringLength, int32* Indicator);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetEnvAttr(void* EnvironmentHandle, int32 Attribute, void* Value, int32 StringLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetParam(void* StatementHandle, uint16 ParameterNumber, int16 ValueType, int16 ParameterType, uint32 LengthPrecision, int16 ParameterScale, void* ParameterValue, int32* StrLen_or_Ind);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetStmtAttr(void* StatementHandle, int32 Attribute, void* Value, int32 StringLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetStmtOption(void* StatementHandle, uint16 Option, uint32 Value);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSpecialColumns(void* StatementHandle, uint16 IdentifierType, uint8* CatalogName, int16 NameLength1, uint8* SchemaName, int16 NameLength2, uint8* TableName, int16 NameLength3, uint16 Scope, uint16 Nullable);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLStatistics(void* StatementHandle, uint8* CatalogName, int16 NameLength1, uint8* SchemaName, int16 NameLength2, uint8* TableName, int16 NameLength3, uint16 Unique, uint16 Reserved);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTables(void* StatementHandle, uint8* CatalogName, int16 NameLength1, uint8* SchemaName, int16 NameLength2, uint8* TableName, int16 NameLength3, uint8* TableType, int16 NameLength4);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTransact(void* EnvironmentHandle, void* ConnectionHandle, uint16 CompletionType);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 bcp_batch(void* param0);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_bind(void* param0, uint8* param1, int32 param2, int32 param3, uint8* param4, int32 param5, int32 param6, int32 param7);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_colfmt(void* param0, int32 param1, uint8 param2, int32 param3, int32 param4, uint8* param5, int32 param6, int32 param7);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_collen(void* param0, int32 param1, int32 param2);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_colptr(void* param0, uint8* param1, int32 param2);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_columns(void* param0, int32 param1);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_control(void* param0, int32 param1, void* param2);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 bcp_done(void* param0);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_exec(void* param0, int32* param1);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_getcolfmt(void* param0, int32 param1, int32 param2, void* param3, int32 param4, int32* param5);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_initA(void* param0, PSTR param1, PSTR param2, PSTR param3, int32 param4);
	public static int16 bcp_init(void* param0, PSTR param1, PSTR param2, PSTR param3, int32 param4) => bcp_initA(param0, param1, param2, param3, param4);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_initW(void* param0, PWSTR param1, PWSTR param2, PWSTR param3, int32 param4);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_moretext(void* param0, int32 param1, uint8* param2);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_readfmtA(void* param0, PSTR param1);
	public static int16 bcp_readfmt(void* param0, PSTR param1) => bcp_readfmtA(param0, param1);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_readfmtW(void* param0, PWSTR param1);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_sendrow(void* param0);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_setcolfmt(void* param0, int32 param1, int32 param2, void* param3, int32 param4);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_writefmtA(void* param0, PSTR param1);
	public static int16 bcp_writefmt(void* param0, PSTR param1) => bcp_writefmtA(param0, param1);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 bcp_writefmtW(void* param0, PWSTR param1);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR dbprtypeA(int32 param0);
	public static PSTR dbprtype(int32 param0) => dbprtypeA(param0);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR dbprtypeW(int32 param0);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLLinkedServers(void* param0);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLLinkedCatalogsA(void* param0, PSTR param1, int16 param2);
	public static int16 SQLLinkedCatalogs(void* param0, PSTR param1, int16 param2) => SQLLinkedCatalogsA(param0, param1, param2);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLLinkedCatalogsW(void* param0, PWSTR param1, int16 param2);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE SQLInitEnumServers(PWSTR pwchServerName, PWSTR pwchInstanceName);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetNextEnumeration(HANDLE hEnumHandle, uint8* prgEnumData, int32* piEnumLength);

	[Import("odbcbcp.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLCloseEnumServers(HANDLE hEnumHandle);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDriverConnect(void* hdbc, int hwnd, uint8* szConnStrIn, int16 cchConnStrIn, uint8* szConnStrOut, int16 cchConnStrOutMax, int16* pcchConnStrOut, uint16 fDriverCompletion);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBrowseConnect(void* hdbc, uint8* szConnStrIn, int16 cchConnStrIn, uint8* szConnStrOut, int16 cchConnStrOutMax, int16* pcchConnStrOut);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBulkOperations(void* StatementHandle, int16 Operation);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributes(void* hstmt, uint16 icol, uint16 fDescType, void* rgbDesc, int16 cbDescMax, int16* pcbDesc, int32* pfDesc);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColumnPrivileges(void* hstmt, uint8* szCatalogName, int16 cchCatalogName, uint8* szSchemaName, int16 cchSchemaName, uint8* szTableName, int16 cchTableName, uint8* szColumnName, int16 cchColumnName);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeParam(void* hstmt, uint16 ipar, int16* pfSqlType, uint32* pcbParamDef, int16* pibScale, int16* pfNullable);

#endif
#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLExtendedFetch(void* hstmt, uint16 fFetchType, int32 irow, uint32* pcrow, uint16* rgfRowStatus);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLForeignKeys(void* hstmt, uint8* szPkCatalogName, int16 cchPkCatalogName, uint8* szPkSchemaName, int16 cchPkSchemaName, uint8* szPkTableName, int16 cchPkTableName, uint8* szFkCatalogName, int16 cchFkCatalogName, uint8* szFkSchemaName, int16 cchFkSchemaName, uint8* szFkTableName, int16 cchFkTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLMoreResults(void* hstmt);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLNativeSql(void* hdbc, uint8* szSqlStrIn, int32 cchSqlStrIn, uint8* szSqlStr, int32 cchSqlStrMax, int32* pcbSqlStr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLNumParams(void* hstmt, int16* pcpar);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLParamOptions(void* hstmt, uint32 crow, uint32* pirow);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPrimaryKeys(void* hstmt, uint8* szCatalogName, int16 cchCatalogName, uint8* szSchemaName, int16 cchSchemaName, uint8* szTableName, int16 cchTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLProcedureColumns(void* hstmt, uint8* szCatalogName, int16 cchCatalogName, uint8* szSchemaName, int16 cchSchemaName, uint8* szProcName, int16 cchProcName, uint8* szColumnName, int16 cchColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLProcedures(void* hstmt, uint8* szCatalogName, int16 cchCatalogName, uint8* szSchemaName, int16 cchSchemaName, uint8* szProcName, int16 cchProcName);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetPos(void* hstmt, uint16 irow, uint16 fOption, uint16 fLock);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTablePrivileges(void* hstmt, uint8* szCatalogName, int16 cchCatalogName, uint8* szSchemaName, int16 cchSchemaName, uint8* szTableName, int16 cchTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDrivers(void* henv, uint16 fDirection, uint8* szDriverDesc, int16 cchDriverDescMax, int16* pcchDriverDesc, uint8* szDriverAttributes, int16 cchDrvrAttrMax, int16* pcchDrvrAttr);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBindParameter(void* hstmt, uint16 ipar, int16 fParamType, int16 fCType, int16 fSqlType, uint32 cbColDef, int16 ibScale, void* rgbValue, int32 cbValueMax, int32* pcbValue);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLAllocHandleStd(int16 fHandleType, void* hInput, void** phOutput);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetScrollOptions(void* hstmt, uint16 fConcurrency, int32 crowKeyset, uint16 crowRowset);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ODBCSetTryWaitValue(uint32 dwValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ODBCGetTryWaitValue();

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributeW(void* hstmt, uint16 iCol, uint16 iField, void* pCharAttr, int16 cbDescMax, int16* pcbCharAttr, void* pNumAttr);

#endif
#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributesW(void* hstmt, uint16 icol, uint16 fDescType, void* rgbDesc, int16 cbDescMax, int16* pcbDesc, int32* pfDesc);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLConnectW(void* hdbc, uint16* szDSN, int16 cchDSN, uint16* szUID, int16 cchUID, uint16* szAuthStr, int16 cchAuthStr);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeColW(void* hstmt, uint16 icol, uint16* szColName, int16 cchColNameMax, int16* pcchColName, int16* pfSqlType, uint32* pcbColDef, int16* pibScale, int16* pfNullable);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLErrorW(void* henv, void* hdbc, void* hstmt, uint16* wszSqlState, int32* pfNativeError, uint16* wszErrorMsg, int16 cchErrorMsgMax, int16* pcchErrorMsg);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLExecDirectW(void* hstmt, uint16* szSqlStr, int32 TextLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetConnectAttrW(void* hdbc, int32 fAttribute, void* rgbValue, int32 cbValueMax, int32* pcbValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetCursorNameW(void* hstmt, uint16* szCursor, int16 cchCursorMax, int16* pcchCursor);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetDescFieldW(void* DescriptorHandle, int16 RecNumber, int16 FieldIdentifier, void* Value, int32 BufferLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescFieldW(void* hdesc, int16 iRecord, int16 iField, void* rgbValue, int32 cbBufferLength, int32* StringLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescRecW(void* hdesc, int16 iRecord, uint16* szName, int16 cchNameMax, int16* pcchName, int16* pfType, int16* pfSubType, int32* pLength, int16* pPrecision, int16* pScale, int16* pNullable);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDiagFieldW(int16 fHandleType, void* handle, int16 iRecord, int16 fDiagField, void* rgbDiagInfo, int16 cbBufferLength, int16* pcbStringLength);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDiagRecW(int16 fHandleType, void* handle, int16 iRecord, uint16* szSqlState, int32* pfNativeError, uint16* szErrorMsg, int16 cchErrorMsgMax, int16* pcchErrorMsg);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPrepareW(void* hstmt, uint16* szSqlStr, int32 cchSqlStr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectAttrW(void* hdbc, int32 fAttribute, void* rgbValue, int32 cbValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetCursorNameW(void* hstmt, uint16* szCursor, int16 cchCursor);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColumnsW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName, uint16* szColumnName, int16 cchColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetConnectOptionW(void* hdbc, uint16 fOption, void* pvParam);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetInfoW(void* hdbc, uint16 fInfoType, void* rgbInfoValue, int16 cbInfoValueMax, int16* pcbInfoValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetTypeInfoW(void* StatementHandle, int16 DataType);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectOptionW(void* hdbc, uint16 fOption, uint32 vParam);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSpecialColumnsW(void* hstmt, uint16 fColType, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName, uint16 fScope, uint16 fNullable);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLStatisticsW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName, uint16 fUnique, uint16 fAccuracy);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTablesW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName, uint16* szTableType, int16 cchTableType);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDataSourcesW(void* henv, uint16 fDirection, uint16* szDSN, int16 cchDSNMax, int16* pcchDSN, uint16* wszDescription, int16 cchDescriptionMax, int16* pcchDescription);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDriverConnectW(void* hdbc, int hwnd, uint16* szConnStrIn, int16 cchConnStrIn, uint16* szConnStrOut, int16 cchConnStrOutMax, int16* pcchConnStrOut, uint16 fDriverCompletion);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBrowseConnectW(void* hdbc, uint16* szConnStrIn, int16 cchConnStrIn, uint16* szConnStrOut, int16 cchConnStrOutMax, int16* pcchConnStrOut);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColumnPrivilegesW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName, uint16* szColumnName, int16 cchColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetStmtAttrW(void* hstmt, int32 fAttribute, void* rgbValue, int32 cbValueMax, int32* pcbValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetStmtAttrW(void* hstmt, int32 fAttribute, void* rgbValue, int32 cbValueMax);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLForeignKeysW(void* hstmt, uint16* szPkCatalogName, int16 cchPkCatalogName, uint16* szPkSchemaName, int16 cchPkSchemaName, uint16* szPkTableName, int16 cchPkTableName, uint16* szFkCatalogName, int16 cchFkCatalogName, uint16* szFkSchemaName, int16 cchFkSchemaName, uint16* szFkTableName, int16 cchFkTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLNativeSqlW(void* hdbc, uint16* szSqlStrIn, int32 cchSqlStrIn, uint16* szSqlStr, int32 cchSqlStrMax, int32* pcchSqlStr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPrimaryKeysW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLProcedureColumnsW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szProcName, int16 cchProcName, uint16* szColumnName, int16 cchColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLProceduresW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szProcName, int16 cchProcName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTablePrivilegesW(void* hstmt, uint16* szCatalogName, int16 cchCatalogName, uint16* szSchemaName, int16 cchSchemaName, uint16* szTableName, int16 cchTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDriversW(void* henv, uint16 fDirection, uint16* szDriverDesc, int16 cchDriverDescMax, int16* pcchDriverDesc, uint16* szDriverAttributes, int16 cchDrvrAttrMax, int16* pcchDrvrAttr);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributeA(void* hstmt, int16 iCol, int16 iField, void* pCharAttr, int16 cbCharAttrMax, int16* pcbCharAttr, void* pNumAttr);

#endif
#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColAttributesA(void* hstmt, uint16 icol, uint16 fDescType, void* rgbDesc, int16 cbDescMax, int16* pcbDesc, int32* pfDesc);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLConnectA(void* hdbc, uint8* szDSN, int16 cbDSN, uint8* szUID, int16 cbUID, uint8* szAuthStr, int16 cbAuthStr);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDescribeColA(void* hstmt, uint16 icol, uint8* szColName, int16 cbColNameMax, int16* pcbColName, int16* pfSqlType, uint32* pcbColDef, int16* pibScale, int16* pfNullable);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLErrorA(void* henv, void* hdbc, void* hstmt, uint8* szSqlState, int32* pfNativeError, uint8* szErrorMsg, int16 cbErrorMsgMax, int16* pcbErrorMsg);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLExecDirectA(void* hstmt, uint8* szSqlStr, int32 cbSqlStr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetConnectAttrA(void* hdbc, int32 fAttribute, void* rgbValue, int32 cbValueMax, int32* pcbValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetCursorNameA(void* hstmt, uint8* szCursor, int16 cbCursorMax, int16* pcbCursor);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescFieldA(void* hdesc, int16 iRecord, int16 iField, void* rgbValue, int32 cbBufferLength, int32* StringLength);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDescRecA(void* hdesc, int16 iRecord, uint8* szName, int16 cbNameMax, int16* pcbName, int16* pfType, int16* pfSubType, int32* pLength, int16* pPrecision, int16* pScale, int16* pNullable);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDiagFieldA(int16 fHandleType, void* handle, int16 iRecord, int16 fDiagField, void* rgbDiagInfo, int16 cbDiagInfoMax, int16* pcbDiagInfo);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetDiagRecA(int16 fHandleType, void* handle, int16 iRecord, uint8* szSqlState, int32* pfNativeError, uint8* szErrorMsg, int16 cbErrorMsgMax, int16* pcbErrorMsg);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetStmtAttrA(void* hstmt, int32 fAttribute, void* rgbValue, int32 cbValueMax, int32* pcbValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetTypeInfoA(void* StatementHandle, int16 DataType);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPrepareA(void* hstmt, uint8* szSqlStr, int32 cbSqlStr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectAttrA(void* hdbc, int32 fAttribute, void* rgbValue, int32 cbValue);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetCursorNameA(void* hstmt, uint8* szCursor, int16 cbCursor);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColumnsA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName, uint8* szColumnName, int16 cbColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetConnectOptionA(void* hdbc, uint16 fOption, void* pvParam);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLGetInfoA(void* hdbc, uint16 fInfoType, void* rgbInfoValue, int16 cbInfoValueMax, int16* pcbInfoValue);

#if BF_32_BIT
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSetConnectOptionA(void* hdbc, uint16 fOption, uint32 vParam);

#endif
	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLSpecialColumnsA(void* hstmt, uint16 fColType, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName, uint16 fScope, uint16 fNullable);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLStatisticsA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName, uint16 fUnique, uint16 fAccuracy);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTablesA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName, uint8* szTableType, int16 cbTableType);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDataSourcesA(void* henv, uint16 fDirection, uint8* szDSN, int16 cbDSNMax, int16* pcbDSN, uint8* szDescription, int16 cbDescriptionMax, int16* pcbDescription);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDriverConnectA(void* hdbc, int hwnd, uint8* szConnStrIn, int16 cbConnStrIn, uint8* szConnStrOut, int16 cbConnStrOutMax, int16* pcbConnStrOut, uint16 fDriverCompletion);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLBrowseConnectA(void* hdbc, uint8* szConnStrIn, int16 cbConnStrIn, uint8* szConnStrOut, int16 cbConnStrOutMax, int16* pcbConnStrOut);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLColumnPrivilegesA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName, uint8* szColumnName, int16 cbColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLForeignKeysA(void* hstmt, uint8* szPkCatalogName, int16 cbPkCatalogName, uint8* szPkSchemaName, int16 cbPkSchemaName, uint8* szPkTableName, int16 cbPkTableName, uint8* szFkCatalogName, int16 cbFkCatalogName, uint8* szFkSchemaName, int16 cbFkSchemaName, uint8* szFkTableName, int16 cbFkTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLNativeSqlA(void* hdbc, uint8* szSqlStrIn, int32 cbSqlStrIn, uint8* szSqlStr, int32 cbSqlStrMax, int32* pcbSqlStr);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLPrimaryKeysA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLProcedureColumnsA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szProcName, int16 cbProcName, uint8* szColumnName, int16 cbColumnName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLProceduresA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szProcName, int16 cbProcName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLTablePrivilegesA(void* hstmt, uint8* szCatalogName, int16 cbCatalogName, uint8* szSchemaName, int16 cbSchemaName, uint8* szTableName, int16 cbTableName);

	[Import("ODBC32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 SQLDriversA(void* henv, uint16 fDirection, uint8* szDriverDesc, int16 cbDriverDescMax, int16* pcbDriverDesc, uint8* szDriverAttributes, int16 cbDrvrAttrMax, int16* pcbDrvrAttr);

}
#endregion
