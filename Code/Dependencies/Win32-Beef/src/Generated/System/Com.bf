using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.Com.StructuredStorage;
using Win32.System.SystemServices;
using Win32.Security;
using Win32.System.Ole;
using System;

namespace Win32.System.Com;

#region Constants
public static
{
	public const uint32 MARSHALINTERFACE_MIN = 500;
	public const int32 ASYNC_MODE_COMPATIBILITY = 1;
	public const int32 ASYNC_MODE_DEFAULT = 0;
	public const int32 STGTY_REPEAT = 256;
	public const int32 STG_TOEND = -1;
	public const int32 STG_LAYOUT_SEQUENTIAL = 0;
	public const int32 STG_LAYOUT_INTERLEAVED = 1;
	public const uint32 COM_RIGHTS_EXECUTE = 1;
	public const uint32 COM_RIGHTS_EXECUTE_LOCAL = 2;
	public const uint32 COM_RIGHTS_EXECUTE_REMOTE = 4;
	public const uint32 COM_RIGHTS_ACTIVATE_LOCAL = 8;
	public const uint32 COM_RIGHTS_ACTIVATE_REMOTE = 16;
	public const uint32 COM_RIGHTS_RESERVED1 = 32;
	public const uint32 COM_RIGHTS_RESERVED2 = 64;
	public const uint32 CWMO_MAX_HANDLES = 56;
	public const uint32 ROTREGFLAGS_ALLOWANYCLIENT = 1;
	public const uint32 APPIDREGFLAGS_ACTIVATE_IUSERVER_INDESKTOP = 1;
	public const uint32 APPIDREGFLAGS_SECURE_SERVER_PROCESS_SD_AND_BIND = 2;
	public const uint32 APPIDREGFLAGS_ISSUE_ACTIVATION_RPC_AT_IDENTIFY = 4;
	public const uint32 APPIDREGFLAGS_IUSERVER_UNMODIFIED_LOGON_TOKEN = 8;
	public const uint32 APPIDREGFLAGS_IUSERVER_SELF_SID_IN_LAUNCH_PERMISSION = 16;
	public const uint32 APPIDREGFLAGS_IUSERVER_ACTIVATE_IN_CLIENT_SESSION_ONLY = 32;
	public const uint32 APPIDREGFLAGS_RESERVED1 = 64;
	public const uint32 APPIDREGFLAGS_RESERVED2 = 128;
	public const uint32 APPIDREGFLAGS_RESERVED3 = 256;
	public const uint32 APPIDREGFLAGS_RESERVED4 = 512;
	public const uint32 APPIDREGFLAGS_RESERVED5 = 1024;
	public const uint32 APPIDREGFLAGS_AAA_NO_IMPLICIT_ACTIVATE_AS_IU = 2048;
	public const uint32 APPIDREGFLAGS_RESERVED7 = 4096;
	public const uint32 APPIDREGFLAGS_RESERVED8 = 8192;
	public const uint32 APPIDREGFLAGS_RESERVED9 = 16384;
	public const uint32 DCOMSCM_ACTIVATION_USE_ALL_AUTHNSERVICES = 1;
	public const uint32 DCOMSCM_ACTIVATION_DISALLOW_UNSECURE_CALL = 2;
	public const uint32 DCOMSCM_RESOLVE_USE_ALL_AUTHNSERVICES = 4;
	public const uint32 DCOMSCM_RESOLVE_DISALLOW_UNSECURE_CALL = 8;
	public const uint32 DCOMSCM_PING_USE_MID_AUTHNSERVICE = 16;
	public const uint32 DCOMSCM_PING_DISALLOW_UNSECURE_CALL = 32;
	public const uint64 MAXLSN = 9223372036854775807;
	public const uint32 DMUS_ERRBASE = 4096;
}
#endregion

#region TypeDefs
typealias CO_MTA_USAGE_COOKIE = int;

typealias CO_DEVICE_CATALOG_COOKIE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum URI_CREATE_FLAGS : uint32
{
	Uri_CREATE_ALLOW_RELATIVE = 1,
	Uri_CREATE_ALLOW_IMPLICIT_WILDCARD_SCHEME = 2,
	Uri_CREATE_ALLOW_IMPLICIT_FILE_SCHEME = 4,
	Uri_CREATE_NOFRAG = 8,
	Uri_CREATE_NO_CANONICALIZE = 16,
	Uri_CREATE_CANONICALIZE = 256,
	Uri_CREATE_FILE_USE_DOS_PATH = 32,
	Uri_CREATE_DECODE_EXTRA_INFO = 64,
	Uri_CREATE_NO_DECODE_EXTRA_INFO = 128,
	Uri_CREATE_CRACK_UNKNOWN_SCHEMES = 512,
	Uri_CREATE_NO_CRACK_UNKNOWN_SCHEMES = 1024,
	Uri_CREATE_PRE_PROCESS_HTML_URI = 2048,
	Uri_CREATE_NO_PRE_PROCESS_HTML_URI = 4096,
	Uri_CREATE_IE_SETTINGS = 8192,
	Uri_CREATE_NO_IE_SETTINGS = 16384,
	Uri_CREATE_NO_ENCODE_FORBIDDEN_CHARACTERS = 32768,
	Uri_CREATE_NORMALIZE_INTL_CHARACTERS = 65536,
	Uri_CREATE_CANONICALIZE_ABSOLUTE = 131072,
}


[AllowDuplicates]
public enum RPC_C_AUTHN_LEVEL : uint32
{
	RPC_C_AUTHN_LEVEL_DEFAULT = 0,
	RPC_C_AUTHN_LEVEL_NONE = 1,
	RPC_C_AUTHN_LEVEL_CONNECT = 2,
	RPC_C_AUTHN_LEVEL_CALL = 3,
	RPC_C_AUTHN_LEVEL_PKT = 4,
	RPC_C_AUTHN_LEVEL_PKT_INTEGRITY = 5,
	RPC_C_AUTHN_LEVEL_PKT_PRIVACY = 6,
}


[AllowDuplicates]
public enum RPC_C_IMP_LEVEL : uint32
{
	RPC_C_IMP_LEVEL_DEFAULT = 0,
	RPC_C_IMP_LEVEL_ANONYMOUS = 1,
	RPC_C_IMP_LEVEL_IDENTIFY = 2,
	RPC_C_IMP_LEVEL_IMPERSONATE = 3,
	RPC_C_IMP_LEVEL_DELEGATE = 4,
}


[AllowDuplicates]
public enum ROT_FLAGS : uint32
{
	ROTFLAGS_REGISTRATIONKEEPSALIVE = 1,
	ROTFLAGS_ALLOWANYCLIENT = 2,
}


[AllowDuplicates]
public enum ADVANCED_FEATURE_FLAGS : uint16
{
	FADF_AUTO = 1,
	FADF_STATIC = 2,
	FADF_EMBEDDED = 4,
	FADF_FIXEDSIZE = 16,
	FADF_RECORD = 32,
	FADF_HAVEIID = 64,
	FADF_HAVEVARTYPE = 128,
	FADF_BSTR = 256,
	FADF_UNKNOWN = 512,
	FADF_DISPATCH = 1024,
	FADF_VARIANT = 2048,
	FADF_RESERVED = 61448,
}


[AllowDuplicates]
public enum IMPLTYPEFLAGS : int32
{
	IMPLTYPEFLAG_FDEFAULT = 1,
	IMPLTYPEFLAG_FSOURCE = 2,
	IMPLTYPEFLAG_FRESTRICTED = 4,
	IMPLTYPEFLAG_FDEFAULTVTABLE = 8,
}


[AllowDuplicates]
public enum IDLFLAGS : uint16
{
	IDLFLAG_NONE = 0,
	IDLFLAG_FIN = 1,
	IDLFLAG_FOUT = 2,
	IDLFLAG_FLCID = 4,
	IDLFLAG_FRETVAL = 8,
}


[AllowDuplicates]
public enum DISPATCH_FLAGS : uint16
{
	DISPATCH_METHOD = 1,
	DISPATCH_PROPERTYGET = 2,
	DISPATCH_PROPERTYPUT = 4,
	DISPATCH_PROPERTYPUTREF = 8,
}


[AllowDuplicates]
public enum STGM : uint32
{
	STGM_DIRECT = 0,
	STGM_TRANSACTED = 65536,
	STGM_SIMPLE = 134217728,
	STGM_READ = 0,
	STGM_WRITE = 1,
	STGM_READWRITE = 2,
	STGM_SHARE_DENY_NONE = 64,
	STGM_SHARE_DENY_READ = 48,
	STGM_SHARE_DENY_WRITE = 32,
	STGM_SHARE_EXCLUSIVE = 16,
	STGM_PRIORITY = 262144,
	STGM_DELETEONRELEASE = 67108864,
	STGM_NOSCRATCH = 1048576,
	STGM_CREATE = 4096,
	STGM_CONVERT = 131072,
	STGM_FAILIFTHERE = 0,
	STGM_NOSNAPSHOT = 2097152,
	STGM_DIRECT_SWMR = 4194304,
}


[AllowDuplicates]
public enum DVASPECT : uint32
{
	DVASPECT_CONTENT = 1,
	DVASPECT_THUMBNAIL = 2,
	DVASPECT_ICON = 4,
	DVASPECT_DOCPRINT = 8,
	DVASPECT_OPAQUE = 16,
	DVASPECT_TRANSPARENT = 32,
}


[AllowDuplicates]
public enum STGC : uint32
{
	STGC_DEFAULT = 0,
	STGC_OVERWRITE = 1,
	STGC_ONLYIFCURRENT = 2,
	STGC_DANGEROUSLYCOMMITMERELYTODISKCACHE = 4,
	STGC_CONSOLIDATE = 8,
}


[AllowDuplicates]
public enum STATFLAG : int32
{
	STATFLAG_DEFAULT = 0,
	STATFLAG_NONAME = 1,
	STATFLAG_NOOPEN = 2,
}


[AllowDuplicates]
public enum VARENUM : uint16
{
	VT_EMPTY = 0,
	VT_NULL = 1,
	VT_I2 = 2,
	VT_I4 = 3,
	VT_R4 = 4,
	VT_R8 = 5,
	VT_CY = 6,
	VT_DATE = 7,
	VT_BSTR = 8,
	VT_DISPATCH = 9,
	VT_ERROR = 10,
	VT_BOOL = 11,
	VT_VARIANT = 12,
	VT_UNKNOWN = 13,
	VT_DECIMAL = 14,
	VT_I1 = 16,
	VT_UI1 = 17,
	VT_UI2 = 18,
	VT_UI4 = 19,
	VT_I8 = 20,
	VT_UI8 = 21,
	VT_INT = 22,
	VT_UINT = 23,
	VT_VOID = 24,
	VT_HRESULT = 25,
	VT_PTR = 26,
	VT_SAFEARRAY = 27,
	VT_CARRAY = 28,
	VT_USERDEFINED = 29,
	VT_LPSTR = 30,
	VT_LPWSTR = 31,
	VT_RECORD = 36,
	VT_INT_PTR = 37,
	VT_UINT_PTR = 38,
	VT_FILETIME = 64,
	VT_BLOB = 65,
	VT_STREAM = 66,
	VT_STORAGE = 67,
	VT_STREAMED_OBJECT = 68,
	VT_STORED_OBJECT = 69,
	VT_BLOB_OBJECT = 70,
	VT_CF = 71,
	VT_CLSID = 72,
	VT_VERSIONED_STREAM = 73,
	VT_BSTR_BLOB = 4095,
	VT_VECTOR = 4096,
	VT_ARRAY = 8192,
	VT_BYREF = 16384,
	VT_RESERVED = 32768,
	VT_ILLEGAL = 65535,
	VT_ILLEGALMASKED = 4095,
	VT_TYPEMASK = 4095,
}


[AllowDuplicates]
public enum TYSPEC : int32
{
	TYSPEC_CLSID = 0,
	TYSPEC_FILEEXT = 1,
	TYSPEC_MIMETYPE = 2,
	TYSPEC_FILENAME = 3,
	TYSPEC_PROGID = 4,
	TYSPEC_PACKAGENAME = 5,
	TYSPEC_OBJECTID = 6,
}


[AllowDuplicates]
public enum REGCLS : int32
{
	REGCLS_SINGLEUSE = 0,
	REGCLS_MULTIPLEUSE = 1,
	REGCLS_MULTI_SEPARATE = 2,
	REGCLS_SUSPENDED = 4,
	REGCLS_SURROGATE = 8,
	REGCLS_AGILE = 16,
}


[AllowDuplicates]
public enum COINITBASE : int32
{
	COINITBASE_MULTITHREADED = 0,
}


[AllowDuplicates]
public enum MEMCTX : int32
{
	MEMCTX_TASK = 1,
	MEMCTX_SHARED = 2,
	MEMCTX_MACSYSTEM = 3,
	MEMCTX_UNKNOWN = -1,
	MEMCTX_SAME = -2,
}


[AllowDuplicates]
public enum CLSCTX : uint32
{
	CLSCTX_INPROC_SERVER = 1,
	CLSCTX_INPROC_HANDLER = 2,
	CLSCTX_LOCAL_SERVER = 4,
	CLSCTX_INPROC_SERVER16 = 8,
	CLSCTX_REMOTE_SERVER = 16,
	CLSCTX_INPROC_HANDLER16 = 32,
	CLSCTX_RESERVED1 = 64,
	CLSCTX_RESERVED2 = 128,
	CLSCTX_RESERVED3 = 256,
	CLSCTX_RESERVED4 = 512,
	CLSCTX_NO_CODE_DOWNLOAD = 1024,
	CLSCTX_RESERVED5 = 2048,
	CLSCTX_NO_CUSTOM_MARSHAL = 4096,
	CLSCTX_ENABLE_CODE_DOWNLOAD = 8192,
	CLSCTX_NO_FAILURE_LOG = 16384,
	CLSCTX_DISABLE_AAA = 32768,
	CLSCTX_ENABLE_AAA = 65536,
	CLSCTX_FROM_DEFAULT_CONTEXT = 131072,
	CLSCTX_ACTIVATE_X86_SERVER = 262144,
	CLSCTX_ACTIVATE_32_BIT_SERVER = 262144,
	CLSCTX_ACTIVATE_64_BIT_SERVER = 524288,
	CLSCTX_ENABLE_CLOAKING = 1048576,
	CLSCTX_APPCONTAINER = 4194304,
	CLSCTX_ACTIVATE_AAA_AS_IU = 8388608,
	CLSCTX_RESERVED6 = 16777216,
	CLSCTX_ACTIVATE_ARM32_SERVER = 33554432,
	CLSCTX_PS_DLL = 2147483648,
	CLSCTX_ALL = 23,
	CLSCTX_SERVER = 21,
}


[AllowDuplicates]
public enum MSHLFLAGS : int32
{
	MSHLFLAGS_NORMAL = 0,
	MSHLFLAGS_TABLESTRONG = 1,
	MSHLFLAGS_TABLEWEAK = 2,
	MSHLFLAGS_NOPING = 4,
	MSHLFLAGS_RESERVED1 = 8,
	MSHLFLAGS_RESERVED2 = 16,
	MSHLFLAGS_RESERVED3 = 32,
	MSHLFLAGS_RESERVED4 = 64,
}


[AllowDuplicates]
public enum MSHCTX : int32
{
	MSHCTX_LOCAL = 0,
	MSHCTX_NOSHAREDMEM = 1,
	MSHCTX_DIFFERENTMACHINE = 2,
	MSHCTX_INPROC = 3,
	MSHCTX_CROSSCTX = 4,
	MSHCTX_CONTAINER = 5,
}


[AllowDuplicates]
public enum EXTCONN : int32
{
	EXTCONN_STRONG = 1,
	EXTCONN_WEAK = 2,
	EXTCONN_CALLABLE = 4,
}


[AllowDuplicates]
public enum STGTY : int32
{
	STGTY_STORAGE = 1,
	STGTY_STREAM = 2,
	STGTY_LOCKBYTES = 3,
	STGTY_PROPERTY = 4,
}


[AllowDuplicates]
public enum STREAM_SEEK : uint32
{
	STREAM_SEEK_SET = 0,
	STREAM_SEEK_CUR = 1,
	STREAM_SEEK_END = 2,
}


[AllowDuplicates]
public enum LOCKTYPE : int32
{
	LOCK_WRITE = 1,
	LOCK_EXCLUSIVE = 2,
	LOCK_ONLYONCE = 4,
}


[AllowDuplicates]
public enum EOLE_AUTHENTICATION_CAPABILITIES : int32
{
	EOAC_NONE = 0,
	EOAC_MUTUAL_AUTH = 1,
	EOAC_STATIC_CLOAKING = 32,
	EOAC_DYNAMIC_CLOAKING = 64,
	EOAC_ANY_AUTHORITY = 128,
	EOAC_MAKE_FULLSIC = 256,
	EOAC_DEFAULT = 2048,
	EOAC_SECURE_REFS = 2,
	EOAC_ACCESS_CONTROL = 4,
	EOAC_APPID = 8,
	EOAC_DYNAMIC = 16,
	EOAC_REQUIRE_FULLSIC = 512,
	EOAC_AUTO_IMPERSONATE = 1024,
	EOAC_DISABLE_AAA = 4096,
	EOAC_NO_CUSTOM_MARSHAL = 8192,
	EOAC_RESERVED1 = 16384,
}


[AllowDuplicates]
public enum RPCOPT_PROPERTIES : int32
{
	COMBND_RPCTIMEOUT = 1,
	COMBND_SERVER_LOCALITY = 2,
	COMBND_RESERVED1 = 4,
	COMBND_RESERVED2 = 5,
	COMBND_RESERVED3 = 8,
	COMBND_RESERVED4 = 16,
}


[AllowDuplicates]
public enum RPCOPT_SERVER_LOCALITY_VALUES : int32
{
	SERVER_LOCALITY_PROCESS_LOCAL = 0,
	SERVER_LOCALITY_MACHINE_LOCAL = 1,
	SERVER_LOCALITY_REMOTE = 2,
}


[AllowDuplicates]
public enum GLOBALOPT_PROPERTIES : int32
{
	COMGLB_EXCEPTION_HANDLING = 1,
	COMGLB_APPID = 2,
	COMGLB_RPC_THREADPOOL_SETTING = 3,
	COMGLB_RO_SETTINGS = 4,
	COMGLB_UNMARSHALING_POLICY = 5,
	COMGLB_PROPERTIES_RESERVED1 = 6,
	COMGLB_PROPERTIES_RESERVED2 = 7,
	COMGLB_PROPERTIES_RESERVED3 = 8,
}


[AllowDuplicates]
public enum GLOBALOPT_EH_VALUES : int32
{
	COMGLB_EXCEPTION_HANDLE = 0,
	COMGLB_EXCEPTION_DONOT_HANDLE_FATAL = 1,
	COMGLB_EXCEPTION_DONOT_HANDLE = 1,
	COMGLB_EXCEPTION_DONOT_HANDLE_ANY = 2,
}


[AllowDuplicates]
public enum GLOBALOPT_RPCTP_VALUES : int32
{
	COMGLB_RPC_THREADPOOL_SETTING_DEFAULT_POOL = 0,
	COMGLB_RPC_THREADPOOL_SETTING_PRIVATE_POOL = 1,
}


[AllowDuplicates]
public enum GLOBALOPT_RO_FLAGS : int32
{
	COMGLB_STA_MODALLOOP_REMOVE_TOUCH_MESSAGES = 1,
	COMGLB_STA_MODALLOOP_SHARED_QUEUE_REMOVE_INPUT_MESSAGES = 2,
	COMGLB_STA_MODALLOOP_SHARED_QUEUE_DONOT_REMOVE_INPUT_MESSAGES = 4,
	COMGLB_FAST_RUNDOWN = 8,
	COMGLB_RESERVED1 = 16,
	COMGLB_RESERVED2 = 32,
	COMGLB_RESERVED3 = 64,
	COMGLB_STA_MODALLOOP_SHARED_QUEUE_REORDER_POINTER_MESSAGES = 128,
	COMGLB_RESERVED4 = 256,
	COMGLB_RESERVED5 = 512,
	COMGLB_RESERVED6 = 1024,
}


[AllowDuplicates]
public enum GLOBALOPT_UNMARSHALING_POLICY_VALUES : int32
{
	COMGLB_UNMARSHALING_POLICY_NORMAL = 0,
	COMGLB_UNMARSHALING_POLICY_STRONG = 1,
	COMGLB_UNMARSHALING_POLICY_HYBRID = 2,
}


[AllowDuplicates]
public enum DCOM_CALL_STATE : int32
{
	DCOM_NONE = 0,
	DCOM_CALL_COMPLETE = 1,
	DCOM_CALL_CANCELED = 2,
}


[AllowDuplicates]
public enum APTTYPEQUALIFIER : int32
{
	APTTYPEQUALIFIER_NONE = 0,
	APTTYPEQUALIFIER_IMPLICIT_MTA = 1,
	APTTYPEQUALIFIER_NA_ON_MTA = 2,
	APTTYPEQUALIFIER_NA_ON_STA = 3,
	APTTYPEQUALIFIER_NA_ON_IMPLICIT_MTA = 4,
	APTTYPEQUALIFIER_NA_ON_MAINSTA = 5,
	APTTYPEQUALIFIER_APPLICATION_STA = 6,
	APTTYPEQUALIFIER_RESERVED_1 = 7,
}


[AllowDuplicates]
public enum APTTYPE : int32
{
	APTTYPE_CURRENT = -1,
	APTTYPE_STA = 0,
	APTTYPE_MTA = 1,
	APTTYPE_NA = 2,
	APTTYPE_MAINSTA = 3,
}


[AllowDuplicates]
public enum THDTYPE : int32
{
	THDTYPE_BLOCKMESSAGES = 0,
	THDTYPE_PROCESSMESSAGES = 1,
}


[AllowDuplicates]
public enum CO_MARSHALING_CONTEXT_ATTRIBUTES : int32
{
	CO_MARSHALING_SOURCE_IS_APP_CONTAINER = 0,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_1 = -2147483648,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_2 = -2147483647,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_3 = -2147483646,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_4 = -2147483645,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_5 = -2147483644,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_6 = -2147483643,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_7 = -2147483642,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_8 = -2147483641,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_9 = -2147483640,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_10 = -2147483639,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_11 = -2147483638,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_12 = -2147483637,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_13 = -2147483636,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_14 = -2147483635,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_15 = -2147483634,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_16 = -2147483633,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_17 = -2147483632,
	CO_MARSHALING_CONTEXT_ATTRIBUTE_RESERVED_18 = -2147483631,
}


[AllowDuplicates]
public enum BIND_FLAGS : int32
{
	BIND_MAYBOTHERUSER = 1,
	BIND_JUSTTESTEXISTENCE = 2,
}


[AllowDuplicates]
public enum MKSYS : int32
{
	MKSYS_NONE = 0,
	MKSYS_GENERICCOMPOSITE = 1,
	MKSYS_FILEMONIKER = 2,
	MKSYS_ANTIMONIKER = 3,
	MKSYS_ITEMMONIKER = 4,
	MKSYS_POINTERMONIKER = 5,
	MKSYS_CLASSMONIKER = 7,
	MKSYS_OBJREFMONIKER = 8,
	MKSYS_SESSIONMONIKER = 9,
	MKSYS_LUAMONIKER = 10,
}


[AllowDuplicates]
public enum MKRREDUCE : int32
{
	MKRREDUCE_ONE = 196608,
	MKRREDUCE_TOUSER = 131072,
	MKRREDUCE_THROUGHUSER = 65536,
	MKRREDUCE_ALL = 0,
}


[AllowDuplicates]
public enum ADVF : int32
{
	ADVF_NODATA = 1,
	ADVF_PRIMEFIRST = 2,
	ADVF_ONLYONCE = 4,
	ADVF_DATAONSTOP = 64,
	ADVFCACHE_NOHANDLER = 8,
	ADVFCACHE_FORCEBUILTIN = 16,
	ADVFCACHE_ONSAVE = 32,
}


[AllowDuplicates]
public enum TYMED : int32
{
	TYMED_HGLOBAL = 1,
	TYMED_FILE = 2,
	TYMED_ISTREAM = 4,
	TYMED_ISTORAGE = 8,
	TYMED_GDI = 16,
	TYMED_MFPICT = 32,
	TYMED_ENHMF = 64,
	TYMED_NULL = 0,
}


[AllowDuplicates]
public enum DATADIR : int32
{
	DATADIR_GET = 1,
	DATADIR_SET = 2,
}


[AllowDuplicates]
public enum CALLTYPE : int32
{
	CALLTYPE_TOPLEVEL = 1,
	CALLTYPE_NESTED = 2,
	CALLTYPE_ASYNC = 3,
	CALLTYPE_TOPLEVEL_CALLPENDING = 4,
	CALLTYPE_ASYNC_CALLPENDING = 5,
}


[AllowDuplicates]
public enum SERVERCALL : int32
{
	SERVERCALL_ISHANDLED = 0,
	SERVERCALL_REJECTED = 1,
	SERVERCALL_RETRYLATER = 2,
}


[AllowDuplicates]
public enum PENDINGTYPE : int32
{
	PENDINGTYPE_TOPLEVEL = 1,
	PENDINGTYPE_NESTED = 2,
}


[AllowDuplicates]
public enum PENDINGMSG : int32
{
	PENDINGMSG_CANCELCALL = 0,
	PENDINGMSG_WAITNOPROCESS = 1,
	PENDINGMSG_WAITDEFPROCESS = 2,
}


[AllowDuplicates]
public enum ApplicationType : int32
{
	ServerApplication = 0,
	LibraryApplication = 1,
}


[AllowDuplicates]
public enum ShutdownType : int32
{
	IdleShutdown = 0,
	ForcedShutdown = 1,
}


[AllowDuplicates]
public enum COINIT : uint32
{
	COINIT_APARTMENTTHREADED = 2,
	COINIT_MULTITHREADED = 0,
	COINIT_DISABLE_OLE1DDE = 4,
	COINIT_SPEED_OVER_MEMORY = 8,
}


[AllowDuplicates]
public enum COMSD : int32
{
	SD_LAUNCHPERMISSIONS = 0,
	SD_ACCESSPERMISSIONS = 1,
	SD_LAUNCHRESTRICTIONS = 2,
	SD_ACCESSRESTRICTIONS = 3,
}


[AllowDuplicates]
public enum COWAIT_FLAGS : int32
{
	COWAIT_DEFAULT = 0,
	COWAIT_WAITALL = 1,
	COWAIT_ALERTABLE = 2,
	COWAIT_INPUTAVAILABLE = 4,
	COWAIT_DISPATCH_CALLS = 8,
	COWAIT_DISPATCH_WINDOW_MESSAGES = 16,
}


[AllowDuplicates]
public enum CWMO_FLAGS : int32
{
	CWMO_DEFAULT = 0,
	CWMO_DISPATCH_CALLS = 1,
	CWMO_DISPATCH_WINDOW_MESSAGES = 2,
}


[AllowDuplicates]
public enum BINDINFOF : int32
{
	BINDINFOF_URLENCODESTGMEDDATA = 1,
	BINDINFOF_URLENCODEDEXTRAINFO = 2,
}


[AllowDuplicates]
public enum Uri_PROPERTY : int32
{
	Uri_PROPERTY_ABSOLUTE_URI = 0,
	Uri_PROPERTY_STRING_START = 0,
	Uri_PROPERTY_AUTHORITY = 1,
	Uri_PROPERTY_DISPLAY_URI = 2,
	Uri_PROPERTY_DOMAIN = 3,
	Uri_PROPERTY_EXTENSION = 4,
	Uri_PROPERTY_FRAGMENT = 5,
	Uri_PROPERTY_HOST = 6,
	Uri_PROPERTY_PASSWORD = 7,
	Uri_PROPERTY_PATH = 8,
	Uri_PROPERTY_PATH_AND_QUERY = 9,
	Uri_PROPERTY_QUERY = 10,
	Uri_PROPERTY_RAW_URI = 11,
	Uri_PROPERTY_SCHEME_NAME = 12,
	Uri_PROPERTY_USER_INFO = 13,
	Uri_PROPERTY_USER_NAME = 14,
	Uri_PROPERTY_STRING_LAST = 14,
	Uri_PROPERTY_HOST_TYPE = 15,
	Uri_PROPERTY_DWORD_START = 15,
	Uri_PROPERTY_PORT = 16,
	Uri_PROPERTY_SCHEME = 17,
	Uri_PROPERTY_ZONE = 18,
	Uri_PROPERTY_DWORD_LAST = 18,
}


[AllowDuplicates]
public enum TYPEKIND : int32
{
	TKIND_ENUM = 0,
	TKIND_RECORD = 1,
	TKIND_MODULE = 2,
	TKIND_INTERFACE = 3,
	TKIND_DISPATCH = 4,
	TKIND_COCLASS = 5,
	TKIND_ALIAS = 6,
	TKIND_UNION = 7,
	TKIND_MAX = 8,
}


[AllowDuplicates]
public enum CALLCONV : int32
{
	CC_FASTCALL = 0,
	CC_CDECL = 1,
	CC_MSCPASCAL = 2,
	CC_PASCAL = 2,
	CC_MACPASCAL = 3,
	CC_STDCALL = 4,
	CC_FPFASTCALL = 5,
	CC_SYSCALL = 6,
	CC_MPWCDECL = 7,
	CC_MPWPASCAL = 8,
	CC_MAX = 9,
}


[AllowDuplicates]
public enum FUNCKIND : int32
{
	FUNC_VIRTUAL = 0,
	FUNC_PUREVIRTUAL = 1,
	FUNC_NONVIRTUAL = 2,
	FUNC_STATIC = 3,
	FUNC_DISPATCH = 4,
}


[AllowDuplicates]
public enum INVOKEKIND : int32
{
	INVOKE_FUNC = 1,
	INVOKE_PROPERTYGET = 2,
	INVOKE_PROPERTYPUT = 4,
	INVOKE_PROPERTYPUTREF = 8,
}


[AllowDuplicates]
public enum VARKIND : int32
{
	VAR_PERINSTANCE = 0,
	VAR_STATIC = 1,
	VAR_CONST = 2,
	VAR_DISPATCH = 3,
}


[AllowDuplicates]
public enum FUNCFLAGS : uint16
{
	FUNCFLAG_FRESTRICTED = 1,
	FUNCFLAG_FSOURCE = 2,
	FUNCFLAG_FBINDABLE = 4,
	FUNCFLAG_FREQUESTEDIT = 8,
	FUNCFLAG_FDISPLAYBIND = 16,
	FUNCFLAG_FDEFAULTBIND = 32,
	FUNCFLAG_FHIDDEN = 64,
	FUNCFLAG_FUSESGETLASTERROR = 128,
	FUNCFLAG_FDEFAULTCOLLELEM = 256,
	FUNCFLAG_FUIDEFAULT = 512,
	FUNCFLAG_FNONBROWSABLE = 1024,
	FUNCFLAG_FREPLACEABLE = 2048,
	FUNCFLAG_FIMMEDIATEBIND = 4096,
}


[AllowDuplicates]
public enum VARFLAGS : uint16
{
	VARFLAG_FREADONLY = 1,
	VARFLAG_FSOURCE = 2,
	VARFLAG_FBINDABLE = 4,
	VARFLAG_FREQUESTEDIT = 8,
	VARFLAG_FDISPLAYBIND = 16,
	VARFLAG_FDEFAULTBIND = 32,
	VARFLAG_FHIDDEN = 64,
	VARFLAG_FRESTRICTED = 128,
	VARFLAG_FDEFAULTCOLLELEM = 256,
	VARFLAG_FUIDEFAULT = 512,
	VARFLAG_FNONBROWSABLE = 1024,
	VARFLAG_FREPLACEABLE = 2048,
	VARFLAG_FIMMEDIATEBIND = 4096,
}


[AllowDuplicates]
public enum DESCKIND : int32
{
	DESCKIND_NONE = 0,
	DESCKIND_FUNCDESC = 1,
	DESCKIND_VARDESC = 2,
	DESCKIND_TYPECOMP = 3,
	DESCKIND_IMPLICITAPPOBJ = 4,
	DESCKIND_MAX = 5,
}


[AllowDuplicates]
public enum SYSKIND : int32
{
	SYS_WIN16 = 0,
	SYS_WIN32 = 1,
	SYS_MAC = 2,
	SYS_WIN64 = 3,
}

#endregion

#region Function Pointers
public function HRESULT LPEXCEPFINO_DEFERRED_FILLIN(EXCEPINFO* pExcepInfo);

public function HRESULT LPFNGETCLASSOBJECT(in Guid param0, in Guid param1, void** param2);

public function HRESULT LPFNCANUNLOADNOW();

public function HRESULT PFNCONTEXTCALL(ComCallData* pParam);

#endregion

#region Structs
[CRepr, Union]
public struct CY
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 Lo;
		public int32 Hi;
	}
	public using _Anonymous_e__Struct Anonymous;
	public int64 int64;
}

[CRepr]
public struct CSPLATFORM
{
	public uint32 dwPlatformId;
	public uint32 dwVersionHi;
	public uint32 dwVersionLo;
	public uint32 dwProcessorArch;
}

[CRepr]
public struct QUERYCONTEXT
{
	public uint32 dwContext;
	public CSPLATFORM Platform;
	public uint32 Locale;
	public uint32 dwVersionHi;
	public uint32 dwVersionLo;
}

[CRepr]
public struct uCLSSPEC
{
	[CRepr, Union]
	public struct _tagged_union_e__Struct
	{
		[CRepr]
		public struct _ByObjectId_e__Struct
		{
			public Guid ObjectId;
			public Guid PolicyId;
		}
		[CRepr]
		public struct _ByName_e__Struct
		{
			public PWSTR pPackageName;
			public Guid PolicyId;
		}
		public Guid clsid;
		public PWSTR pFileExt;
		public PWSTR pMimeType;
		public PWSTR pProgId;
		public PWSTR pFileName;
		public _ByName_e__Struct ByName;
		public _ByObjectId_e__Struct ByObjectId;
	}
	public uint32 tyspec;
	public _tagged_union_e__Struct tagged_union;
}

[CRepr]
public struct COAUTHIDENTITY
{
	public uint16* User;
	public uint32 UserLength;
	public uint16* Domain;
	public uint32 DomainLength;
	public uint16* Password;
	public uint32 PasswordLength;
	public uint32 Flags;
}

[CRepr]
public struct COAUTHINFO
{
	public uint32 dwAuthnSvc;
	public uint32 dwAuthzSvc;
	public PWSTR pwszServerPrincName;
	public uint32 dwAuthnLevel;
	public uint32 dwImpersonationLevel;
	public COAUTHIDENTITY* pAuthIdentityData;
	public uint32 dwCapabilities;
}

[CRepr]
public struct BYTE_BLOB
{
	public uint32 clSize;
	public uint8* abData mut => &abData_impl;
	private uint8[ANYSIZE_ARRAY] abData_impl;
}

[CRepr]
public struct WORD_BLOB
{
	public uint32 clSize;
	public uint16* asData mut => &asData_impl;
	private uint16[ANYSIZE_ARRAY] asData_impl;
}

[CRepr]
public struct DWORD_BLOB
{
	public uint32 clSize;
	public uint32* alData mut => &alData_impl;
	private uint32[ANYSIZE_ARRAY] alData_impl;
}

[CRepr]
public struct FLAGGED_BYTE_BLOB
{
	public uint32 fFlags;
	public uint32 clSize;
	public uint8* abData mut => &abData_impl;
	private uint8[ANYSIZE_ARRAY] abData_impl;
}

[CRepr]
public struct FLAGGED_WORD_BLOB
{
	public uint32 fFlags;
	public uint32 clSize;
	public uint16* asData mut => &asData_impl;
	private uint16[ANYSIZE_ARRAY] asData_impl;
}

[CRepr]
public struct BYTE_SIZEDARR
{
	public uint32 clSize;
	public uint8* pData;
}

[CRepr]
public struct WORD_SIZEDARR
{
	public uint32 clSize;
	public uint16* pData;
}

[CRepr]
public struct DWORD_SIZEDARR
{
	public uint32 clSize;
	public uint32* pData;
}

[CRepr]
public struct HYPER_SIZEDARR
{
	public uint32 clSize;
	public int64* pData;
}

[CRepr]
public struct BLOB
{
	public uint32 cbSize;
	public uint8* pBlobData;
}

[CRepr]
public struct IEnumContextProps
{
}

[CRepr]
public struct IContext
{
}

[CRepr]
public struct COSERVERINFO
{
	public uint32 dwReserved1;
	public PWSTR pwszName;
	public COAUTHINFO* pAuthInfo;
	public uint32 dwReserved2;
}

[CRepr]
public struct MULTI_QI
{
	public Guid* pIID;
	public IUnknown* pItf;
	public HRESULT hr;
}

[CRepr]
public struct STATSTG
{
	public PWSTR pwcsName;
	public uint32 type;
	public ULARGE_INTEGER cbSize;
	public FILETIME mtime;
	public FILETIME ctime;
	public FILETIME atime;
	public STGM grfMode;
	public LOCKTYPE grfLocksSupported;
	public Guid clsid;
	public uint32 grfStateBits;
	public uint32 reserved;
}

[CRepr]
public struct RPCOLEMESSAGE
{
	public void* reserved1;
	public uint32 dataRepresentation;
	public void* Buffer;
	public uint32 cbBuffer;
	public uint32 iMethod;
	public void*[5] reserved2;
	public uint32 rpcFlags;
}

[CRepr]
public struct SChannelHookCallInfo
{
	public Guid iid;
	public uint32 cbSize;
	public Guid uCausality;
	public uint32 dwServerPid;
	public uint32 iMethod;
	public void* pObject;
}

[CRepr]
public struct SOLE_AUTHENTICATION_SERVICE
{
	public uint32 dwAuthnSvc;
	public uint32 dwAuthzSvc;
	public PWSTR pPrincipalName;
	public HRESULT hr;
}

[CRepr]
public struct SOLE_AUTHENTICATION_INFO
{
	public uint32 dwAuthnSvc;
	public uint32 dwAuthzSvc;
	public void* pAuthInfo;
}

[CRepr]
public struct SOLE_AUTHENTICATION_LIST
{
	public uint32 cAuthInfo;
	public SOLE_AUTHENTICATION_INFO* aAuthInfo;
}

[CRepr]
public struct MachineGlobalObjectTableRegistrationToken__
{
	public int32 unused;
}

[CRepr]
public struct BIND_OPTS
{
	public uint32 cbStruct;
	public uint32 grfFlags;
	public uint32 grfMode;
	public uint32 dwTickCountDeadline;
}

[CRepr]
public struct BIND_OPTS2
{
	public BIND_OPTS Base;
	public uint32 dwTrackFlags;
	public uint32 dwClassContext;
	public uint32 locale;
	public COSERVERINFO* pServerInfo;
}

[CRepr]
public struct BIND_OPTS3
{
	public BIND_OPTS2 Base;
	public HWND hwnd;
}

[CRepr]
public struct DVTARGETDEVICE
{
	public uint32 tdSize;
	public uint16 tdDriverNameOffset;
	public uint16 tdDeviceNameOffset;
	public uint16 tdPortNameOffset;
	public uint16 tdExtDevmodeOffset;
	public uint8* tdData mut => &tdData_impl;
	private uint8[ANYSIZE_ARRAY] tdData_impl;
}

[CRepr]
public struct FORMATETC
{
	public uint16 cfFormat;
	public DVTARGETDEVICE* ptd;
	public uint32 dwAspect;
	public int32 lindex;
	public uint32 tymed;
}

[CRepr]
public struct STATDATA
{
	public FORMATETC formatetc;
	public uint32 advf;
	public IAdviseSink* pAdvSink;
	public uint32 dwConnection;
}

[CRepr]
public struct RemSTGMEDIUM
{
	public TYMED tymed;
	public uint32 dwHandleType;
	public uint32 pData;
	public uint32 pUnkForRelease;
	public uint32 cbData;
	public uint8* data mut => &data_impl;
	private uint8[ANYSIZE_ARRAY] data_impl;
}

[CRepr]
public struct STGMEDIUM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public HBITMAP hBitmap;
		public void* hMetaFilePict;
		public HENHMETAFILE hEnhMetaFile;
		public int hGlobal;
		public PWSTR lpszFileName;
		public IStream* pstm;
		public IStorage* pstg;
	}
	public TYMED tymed;
	public using _Anonymous_e__Union Anonymous;
	public IUnknown* pUnkForRelease;
}

[CRepr]
public struct GDI_OBJECT
{
	[CRepr, Union]
	public struct _u_e__Struct
	{
		public userHBITMAP* hBitmap;
		public userHPALETTE* hPalette;
		public userHGLOBAL* hGeneric;
	}
	public uint32 ObjectType;
	public _u_e__Struct u;
}

[CRepr]
public struct userSTGMEDIUM
{
	[CRepr]
	public struct _STGMEDIUM_UNION
	{
		[CRepr, Union]
		public struct _u_e__Struct
		{
			public userHMETAFILEPICT* hMetaFilePict;
			public userHENHMETAFILE* hHEnhMetaFile;
			public GDI_OBJECT* hGdiHandle;
			public userHGLOBAL* hGlobal;
			public PWSTR lpszFileName;
			public BYTE_BLOB* pstm;
			public BYTE_BLOB* pstg;
		}
		public uint32 tymed;
		public _u_e__Struct u;
	}
	public IUnknown* pUnkForRelease;
}

[CRepr]
public struct userFLAG_STGMEDIUM
{
	public int32 ContextFlags;
	public int32 fPassOwnership;
	public userSTGMEDIUM Stgmed;
}

[CRepr]
public struct FLAG_STGMEDIUM
{
	public int32 ContextFlags;
	public int32 fPassOwnership;
	public STGMEDIUM Stgmed;
}

[CRepr]
public struct INTERFACEINFO
{
	public IUnknown* pUnk;
	public Guid iid;
	public uint16 wMethod;
}

[CRepr]
public struct StorageLayout
{
	public uint32 LayoutType;
	public PWSTR pwcsElementName;
	public LARGE_INTEGER cOffset;
	public LARGE_INTEGER cBytes;
}

[CRepr]
public struct CATEGORYINFO
{
	public Guid catid;
	public uint32 lcid;
	public char16[128] szDescription;
}

[CRepr]
public struct ComCallData
{
	public uint32 dwDispid;
	public uint32 dwReserved;
	public void* pUserDefined;
}

[CRepr]
public struct BINDINFO
{
	public uint32 cbSize;
	public PWSTR szExtraInfo;
	public STGMEDIUM stgmedData;
	public uint32 grfBindInfoF;
	public uint32 dwBindVerb;
	public PWSTR szCustomVerb;
	public uint32 cbstgmedData;
	public uint32 dwOptions;
	public uint32 dwOptionsFlags;
	public uint32 dwCodePage;
	public SECURITY_ATTRIBUTES securityAttributes;
	public Guid iid;
	public IUnknown* pUnk;
	public uint32 dwReserved;
}

[CRepr]
public struct AUTHENTICATEINFO
{
	public uint32 dwFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct SAFEARRAYBOUND
{
	public uint32 cElements;
	public int32 lLbound;
}

[CRepr]
public struct SAFEARRAY
{
	public uint16 cDims;
	public ADVANCED_FEATURE_FLAGS fFeatures;
	public uint32 cbElements;
	public uint32 cLocks;
	public void* pvData;
	public SAFEARRAYBOUND* rgsabound mut => &rgsabound_impl;
	private SAFEARRAYBOUND[ANYSIZE_ARRAY] rgsabound_impl;
}

[CRepr]
public struct VARIANT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
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
					public void* pvRecord;
					public IRecordInfo* pRecInfo;
				}
				public int64 llVal;
				public int32 lVal;
				public uint8 bVal;
				public int16 iVal;
				public float fltVal;
				public double dblVal;
				public int16 boolVal;
				public int16 __OBSOLETE__VARIANT_BOOL;
				public int32 scode;
				public CY cyVal;
				public double date;
				public BSTR bstrVal;
				public IUnknown* punkVal;
				public IDispatch* pdispVal;
				public SAFEARRAY* parray;
				public uint8* pbVal;
				public int16* piVal;
				public int32* plVal;
				public int64* pllVal;
				public float* pfltVal;
				public double* pdblVal;
				public int16* pboolVal;
				public int16* __OBSOLETE__VARIANT_PBOOL;
				public int32* pscode;
				public CY* pcyVal;
				public double* pdate;
				public BSTR* pbstrVal;
				public IUnknown** ppunkVal;
				public IDispatch** ppdispVal;
				public SAFEARRAY** pparray;
				public VARIANT* pvarVal;
				public void* byref;
				public CHAR cVal;
				public uint16 uiVal;
				public uint32 ulVal;
				public uint64 ullVal;
				public int32 intVal;
				public uint32 uintVal;
				public DECIMAL* pdecVal;
				public PSTR pcVal;
				public uint16* puiVal;
				public uint32* pulVal;
				public uint64* pullVal;
				public int32* pintVal;
				public uint32* puintVal;
				public using _Anonymous_e__Struct Anonymous;
			}
			public VARENUM vt;
			public uint16 wReserved1;
			public uint16 wReserved2;
			public uint16 wReserved3;
			public using _Anonymous_e__Union Anonymous;
		}
		public using _Anonymous_e__Struct Anonymous;
		public DECIMAL decVal;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TYPEDESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public TYPEDESC* lptdesc;
		public ARRAYDESC* lpadesc;
		public uint32 hreftype;
	}
	public using _Anonymous_e__Union Anonymous;
	public VARENUM vt;
}

[CRepr]
public struct IDLDESC
{
	public uint dwReserved;
	public IDLFLAGS wIDLFlags;
}

[CRepr]
public struct ELEMDESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IDLDESC idldesc;
		public PARAMDESC paramdesc;
	}
	public TYPEDESC tdesc;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TYPEATTR
{
	public Guid guid;
	public uint32 lcid;
	public uint32 dwReserved;
	public int32 memidConstructor;
	public int32 memidDestructor;
	public PWSTR lpstrSchema;
	public uint32 cbSizeInstance;
	public TYPEKIND typekind;
	public uint16 cFuncs;
	public uint16 cVars;
	public uint16 cImplTypes;
	public uint16 cbSizeVft;
	public uint16 cbAlignment;
	public uint16 wTypeFlags;
	public uint16 wMajorVerNum;
	public uint16 wMinorVerNum;
	public TYPEDESC tdescAlias;
	public IDLDESC idldescType;
}

[CRepr]
public struct DISPPARAMS
{
	public VARIANT* rgvarg;
	public int32* rgdispidNamedArgs;
	public uint32 cArgs;
	public uint32 cNamedArgs;
}

[CRepr]
public struct EXCEPINFO
{
	public uint16 wCode;
	public uint16 wReserved;
	public BSTR bstrSource;
	public BSTR bstrDescription;
	public BSTR bstrHelpFile;
	public uint32 dwHelpContext;
	public void* pvReserved;
	public LPEXCEPFINO_DEFERRED_FILLIN pfnDeferredFillIn;
	public int32 scode;
}

[CRepr]
public struct FUNCDESC
{
	public int32 memid;
	public int32* lprgscode;
	public ELEMDESC* lprgelemdescParam;
	public FUNCKIND funckind;
	public INVOKEKIND invkind;
	public CALLCONV callconv;
	public int16 cParams;
	public int16 cParamsOpt;
	public int16 oVft;
	public int16 cScodes;
	public ELEMDESC elemdescFunc;
	public FUNCFLAGS wFuncFlags;
}

[CRepr]
public struct VARDESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 oInst;
		public VARIANT* lpvarValue;
	}
	public int32 memid;
	public PWSTR lpstrSchema;
	public using _Anonymous_e__Union Anonymous;
	public ELEMDESC elemdescVar;
	public VARFLAGS wVarFlags;
	public VARKIND varkind;
}

[CRepr]
public struct CUSTDATAITEM
{
	public Guid guid;
	public VARIANT varValue;
}

[CRepr]
public struct CUSTDATA
{
	public uint32 cCustData;
	public CUSTDATAITEM* prgCustData;
}

[CRepr, Union]
public struct BINDPTR
{
	public FUNCDESC* lpfuncdesc;
	public VARDESC* lpvardesc;
	public ITypeComp* lptcomp;
}

[CRepr]
public struct TLIBATTR
{
	public Guid guid;
	public uint32 lcid;
	public SYSKIND syskind;
	public uint16 wMajorVerNum;
	public uint16 wMinorVerNum;
	public uint16 wLibFlags;
}

[CRepr]
public struct CONNECTDATA
{
	public IUnknown* pUnk;
	public uint32 dwCookie;
}

#endregion

#region COM Types
[CRepr]struct IUnknown
{
	public new const Guid IID = .(0x00000000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvObject) QueryInterface;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) AddRef;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) Release;
	}


	public HRESULT QueryInterface(in Guid riid, void** ppvObject) mut => VT.[Friend]QueryInterface(&this, riid, ppvObject);

	public uint32 AddRef() mut => VT.[Friend]AddRef(&this);

	public uint32 Release() mut => VT.[Friend]Release(&this);
}

[CRepr]struct AsyncIUnknown : IUnknown
{
	public new const Guid IID = .(0x000e0000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid) Begin_QueryInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** ppvObject) Finish_QueryInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_AddRef;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) Finish_AddRef;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_Release;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) Finish_Release;
	}


	public HRESULT Begin_QueryInterface(in Guid riid) mut => VT.[Friend]Begin_QueryInterface(&this, riid);

	public HRESULT Finish_QueryInterface(void** ppvObject) mut => VT.[Friend]Finish_QueryInterface(&this, ppvObject);

	public HRESULT Begin_AddRef() mut => VT.[Friend]Begin_AddRef(&this);

	public uint32 Finish_AddRef() mut => VT.[Friend]Finish_AddRef(&this);

	public HRESULT Begin_Release() mut => VT.[Friend]Begin_Release(&this);

	public uint32 Finish_Release() mut => VT.[Friend]Finish_Release(&this);
}

[CRepr]struct IClassFactory : IUnknown
{
	public new const Guid IID = .(0x00000001, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, void** ppvObject) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLock) LockServer;
	}


	public HRESULT CreateInstance(IUnknown* pUnkOuter, in Guid riid, void** ppvObject) mut => VT.[Friend]CreateInstance(&this, pUnkOuter, riid, ppvObject);

	public HRESULT LockServer(BOOL fLock) mut => VT.[Friend]LockServer(&this, fLock);
}

[CRepr]struct INoMarshal : IUnknown
{
	public new const Guid IID = .(0xecc8691b, 0xc1db, 0x4dc0, 0x85, 0x5e, 0x65, 0xf6, 0xc5, 0x51, 0xaf, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IAgileObject : IUnknown
{
	public new const Guid IID = .(0x94ea2b94, 0xe9cc, 0x49e0, 0xc0, 0xff, 0xee, 0x64, 0xca, 0x8f, 0x5b, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IActivationFilter : IUnknown
{
	public new const Guid IID = .(0x00000017, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwActivationType, in Guid rclsid, Guid* pReplacementClsId) HandleActivation;
	}


	public HRESULT HandleActivation(uint32 dwActivationType, in Guid rclsid, Guid* pReplacementClsId) mut => VT.[Friend]HandleActivation(&this, dwActivationType, rclsid, pReplacementClsId);
}

[CRepr]struct IMalloc : IUnknown
{
	public new const Guid IID = .(0x00000002, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, uint cb) Alloc;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, void* pv, uint cb) Realloc;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pv) Free;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self, void* pv) GetSize;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, void* pv) DidAlloc;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) HeapMinimize;
	}


	public void* Alloc(uint cb) mut => VT.[Friend]Alloc(&this, cb);

	public void* Realloc(void* pv, uint cb) mut => VT.[Friend]Realloc(&this, pv, cb);

	public void Free(void* pv) mut => VT.[Friend]Free(&this, pv);

	public uint GetSize(void* pv) mut => VT.[Friend]GetSize(&this, pv);

	public int32 DidAlloc(void* pv) mut => VT.[Friend]DidAlloc(&this, pv);

	public void HeapMinimize() mut => VT.[Friend]HeapMinimize(&this);
}

[CRepr]struct IStdMarshalInfo : IUnknown
{
	public new const Guid IID = .(0x00000018, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDestContext, void* pvDestContext, Guid* pClsid) GetClassForHandler;
	}


	public HRESULT GetClassForHandler(uint32 dwDestContext, void* pvDestContext, Guid* pClsid) mut => VT.[Friend]GetClassForHandler(&this, dwDestContext, pvDestContext, pClsid);
}

[CRepr]struct IExternalConnection : IUnknown
{
	public new const Guid IID = .(0x00000019, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 extconn, uint32 reserved) AddConnection;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 extconn, uint32 reserved, BOOL fLastReleaseCloses) ReleaseConnection;
	}


	public uint32 AddConnection(uint32 extconn, uint32 reserved) mut => VT.[Friend]AddConnection(&this, extconn, reserved);

	public uint32 ReleaseConnection(uint32 extconn, uint32 reserved, BOOL fLastReleaseCloses) mut => VT.[Friend]ReleaseConnection(&this, extconn, reserved, fLastReleaseCloses);
}

[CRepr]struct IMultiQI : IUnknown
{
	public new const Guid IID = .(0x00000020, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cMQIs, MULTI_QI* pMQIs) QueryMultipleInterfaces;
	}


	public HRESULT QueryMultipleInterfaces(uint32 cMQIs, MULTI_QI* pMQIs) mut => VT.[Friend]QueryMultipleInterfaces(&this, cMQIs, pMQIs);
}

[CRepr]struct AsyncIMultiQI : IUnknown
{
	public new const Guid IID = .(0x000e0020, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cMQIs, MULTI_QI* pMQIs) Begin_QueryMultipleInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MULTI_QI* pMQIs) Finish_QueryMultipleInterfaces;
	}


	public HRESULT Begin_QueryMultipleInterfaces(uint32 cMQIs, MULTI_QI* pMQIs) mut => VT.[Friend]Begin_QueryMultipleInterfaces(&this, cMQIs, pMQIs);

	public HRESULT Finish_QueryMultipleInterfaces(MULTI_QI* pMQIs) mut => VT.[Friend]Finish_QueryMultipleInterfaces(&this, pMQIs);
}

[CRepr]struct IInternalUnknown : IUnknown
{
	public new const Guid IID = .(0x00000021, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) QueryInternalInterface;
	}


	public HRESULT QueryInternalInterface(in Guid riid, void** ppv) mut => VT.[Friend]QueryInternalInterface(&this, riid, ppv);
}

[CRepr]struct IEnumUnknown : IUnknown
{
	public new const Guid IID = .(0x00000100, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IUnknown** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, IUnknown** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumUnknown** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumString : IUnknown
{
	public new const Guid IID = .(0x00000101, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, PWSTR* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, PWSTR* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumString** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISequentialStream : IUnknown
{
	public new const Guid IID = .(0x0c733a30, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pv, uint32 cb, uint32* pcbRead) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pv, uint32 cb, uint32* pcbWritten) Write;
	}


	public HRESULT Read(void* pv, uint32 cb, uint32* pcbRead) mut => VT.[Friend]Read(&this, pv, cb, pcbRead);

	public HRESULT Write(void* pv, uint32 cb, uint32* pcbWritten) mut => VT.[Friend]Write(&this, pv, cb, pcbWritten);
}

[CRepr]struct IStream : ISequentialStream
{
	public new const Guid IID = .(0x0000000c, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISequentialStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER dlibMove, STREAM_SEEK dwOrigin, ULARGE_INTEGER* plibNewPosition) Seek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libNewSize) SetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstm, ULARGE_INTEGER cb, ULARGE_INTEGER* pcbRead, ULARGE_INTEGER* pcbWritten) CopyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STGC grfCommitFlags) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Revert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, LOCKTYPE dwLockType) LockRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, uint32 dwLockType) UnlockRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STATSTG* pstatstg, STATFLAG grfStatFlag) Stat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppstm) Clone;
	}


	public HRESULT Seek(LARGE_INTEGER dlibMove, STREAM_SEEK dwOrigin, ULARGE_INTEGER* plibNewPosition) mut => VT.[Friend]Seek(&this, dlibMove, dwOrigin, plibNewPosition);

	public HRESULT SetSize(ULARGE_INTEGER libNewSize) mut => VT.[Friend]SetSize(&this, libNewSize);

	public HRESULT CopyTo(IStream* pstm, ULARGE_INTEGER cb, ULARGE_INTEGER* pcbRead, ULARGE_INTEGER* pcbWritten) mut => VT.[Friend]CopyTo(&this, pstm, cb, pcbRead, pcbWritten);

	public HRESULT Commit(STGC grfCommitFlags) mut => VT.[Friend]Commit(&this, grfCommitFlags);

	public HRESULT Revert() mut => VT.[Friend]Revert(&this);

	public HRESULT LockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, LOCKTYPE dwLockType) mut => VT.[Friend]LockRegion(&this, libOffset, cb, dwLockType);

	public HRESULT UnlockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, uint32 dwLockType) mut => VT.[Friend]UnlockRegion(&this, libOffset, cb, dwLockType);

	public HRESULT Stat(STATSTG* pstatstg, STATFLAG grfStatFlag) mut => VT.[Friend]Stat(&this, pstatstg, grfStatFlag);

	public HRESULT Clone(IStream** ppstm) mut => VT.[Friend]Clone(&this, ppstm);
}

[CRepr]struct IRpcChannelBuffer : IUnknown
{
	public new const Guid IID = .(0xd5f56b60, 0x593b, 0x101a, 0xb5, 0x69, 0x08, 0x00, 0x2b, 0x2d, 0xbf, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMessage, in Guid riid) GetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMessage, uint32* pStatus) SendReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMessage) FreeBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDestContext, void** ppvDestContext) GetDestCtx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsConnected;
	}


	public HRESULT GetBuffer(RPCOLEMESSAGE* pMessage, in Guid riid) mut => VT.[Friend]GetBuffer(&this, pMessage, riid);

	public HRESULT SendReceive(RPCOLEMESSAGE* pMessage, uint32* pStatus) mut => VT.[Friend]SendReceive(&this, pMessage, pStatus);

	public HRESULT FreeBuffer(RPCOLEMESSAGE* pMessage) mut => VT.[Friend]FreeBuffer(&this, pMessage);

	public HRESULT GetDestCtx(uint32* pdwDestContext, void** ppvDestContext) mut => VT.[Friend]GetDestCtx(&this, pdwDestContext, ppvDestContext);

	public HRESULT IsConnected() mut => VT.[Friend]IsConnected(&this);
}

[CRepr]struct IRpcChannelBuffer2 : IRpcChannelBuffer
{
	public new const Guid IID = .(0x594f31d0, 0x7f19, 0x11d0, 0xb1, 0x94, 0x00, 0xa0, 0xc9, 0x0d, 0xc8, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRpcChannelBuffer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwVersion) GetProtocolVersion;
	}


	public HRESULT GetProtocolVersion(uint32* pdwVersion) mut => VT.[Friend]GetProtocolVersion(&this, pdwVersion);
}

[CRepr]struct IAsyncRpcChannelBuffer : IRpcChannelBuffer2
{
	public new const Guid IID = .(0xa5029fb6, 0x3c34, 0x11d1, 0x9c, 0x99, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRpcChannelBuffer2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, ISynchronize* pSync, uint32* pulStatus) Send;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32* pulStatus) Receive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32* pdwDestContext, void** ppvDestContext) GetDestCtxEx;
	}


	public HRESULT Send(RPCOLEMESSAGE* pMsg, ISynchronize* pSync, uint32* pulStatus) mut => VT.[Friend]Send(&this, pMsg, pSync, pulStatus);

	public HRESULT Receive(RPCOLEMESSAGE* pMsg, uint32* pulStatus) mut => VT.[Friend]Receive(&this, pMsg, pulStatus);

	public HRESULT GetDestCtxEx(RPCOLEMESSAGE* pMsg, uint32* pdwDestContext, void** ppvDestContext) mut => VT.[Friend]GetDestCtxEx(&this, pMsg, pdwDestContext, ppvDestContext);
}

[CRepr]struct IRpcChannelBuffer3 : IRpcChannelBuffer2
{
	public new const Guid IID = .(0x25b15600, 0x0115, 0x11d0, 0xbf, 0x0d, 0x00, 0xaa, 0x00, 0xb8, 0xdf, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRpcChannelBuffer2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32* pulStatus) Send;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32 ulSize, uint32* pulStatus) Receive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, in Guid riid, void** pInterface) GetCallContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32* pdwDestContext, void** ppvDestContext) GetDestCtxEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32* pState) GetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, IAsyncManager* pAsyncMgr) RegisterAsync;
	}


	public HRESULT Send(RPCOLEMESSAGE* pMsg, uint32* pulStatus) mut => VT.[Friend]Send(&this, pMsg, pulStatus);

	public HRESULT Receive(RPCOLEMESSAGE* pMsg, uint32 ulSize, uint32* pulStatus) mut => VT.[Friend]Receive(&this, pMsg, ulSize, pulStatus);

	public HRESULT Cancel(RPCOLEMESSAGE* pMsg) mut => VT.[Friend]Cancel(&this, pMsg);

	public HRESULT GetCallContext(RPCOLEMESSAGE* pMsg, in Guid riid, void** pInterface) mut => VT.[Friend]GetCallContext(&this, pMsg, riid, pInterface);

	public HRESULT GetDestCtxEx(RPCOLEMESSAGE* pMsg, uint32* pdwDestContext, void** ppvDestContext) mut => VT.[Friend]GetDestCtxEx(&this, pMsg, pdwDestContext, ppvDestContext);

	public HRESULT GetState(RPCOLEMESSAGE* pMsg, uint32* pState) mut => VT.[Friend]GetState(&this, pMsg, pState);

	public HRESULT RegisterAsync(RPCOLEMESSAGE* pMsg, IAsyncManager* pAsyncMgr) mut => VT.[Friend]RegisterAsync(&this, pMsg, pAsyncMgr);
}

[CRepr]struct IRpcSyntaxNegotiate : IUnknown
{
	public new const Guid IID = .(0x58a08519, 0x24c8, 0x4935, 0xb4, 0x82, 0x3f, 0xd8, 0x23, 0x33, 0x3a, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg) NegotiateSyntax;
	}


	public HRESULT NegotiateSyntax(RPCOLEMESSAGE* pMsg) mut => VT.[Friend]NegotiateSyntax(&this, pMsg);
}

[CRepr]struct IRpcProxyBuffer : IUnknown
{
	public new const Guid IID = .(0xd5f56a34, 0x593b, 0x101a, 0xb5, 0x69, 0x08, 0x00, 0x2b, 0x2d, 0xbf, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRpcChannelBuffer* pRpcChannelBuffer) Connect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Disconnect;
	}


	public HRESULT Connect(IRpcChannelBuffer* pRpcChannelBuffer) mut => VT.[Friend]Connect(&this, pRpcChannelBuffer);

	public void Disconnect() mut => VT.[Friend]Disconnect(&this);
}

[CRepr]struct IRpcStubBuffer : IUnknown
{
	public new const Guid IID = .(0xd5f56afc, 0x593b, 0x101a, 0xb5, 0x69, 0x08, 0x00, 0x2b, 0x2d, 0xbf, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkServer) Connect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* _prpcmsg, IRpcChannelBuffer* _pRpcChannelBuffer) Invoke;
		protected new function [CallingConvention(.Stdcall)] IRpcStubBuffer*(SelfOuter* self, in Guid riid) IsIIDSupported;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) CountRefs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** ppv) DebugServerQueryInterface;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, void* pv) DebugServerRelease;
	}


	public HRESULT Connect(IUnknown* pUnkServer) mut => VT.[Friend]Connect(&this, pUnkServer);

	public void Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT Invoke(RPCOLEMESSAGE* _prpcmsg, IRpcChannelBuffer* _pRpcChannelBuffer) mut => VT.[Friend]Invoke(&this, _prpcmsg, _pRpcChannelBuffer);

	public IRpcStubBuffer* IsIIDSupported(in Guid riid) mut => VT.[Friend]IsIIDSupported(&this, riid);

	public uint32 CountRefs() mut => VT.[Friend]CountRefs(&this);

	public HRESULT DebugServerQueryInterface(void** ppv) mut => VT.[Friend]DebugServerQueryInterface(&this, ppv);

	public void DebugServerRelease(void* pv) mut => VT.[Friend]DebugServerRelease(&this, pv);
}

[CRepr]struct IPSFactoryBuffer : IUnknown
{
	public new const Guid IID = .(0xd5f569d0, 0x593b, 0x101a, 0xb5, 0x69, 0x08, 0x00, 0x2b, 0x2d, 0xbf, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, IRpcProxyBuffer** ppProxy, void** ppv) CreateProxy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* pUnkServer, IRpcStubBuffer** ppStub) CreateStub;
	}


	public HRESULT CreateProxy(IUnknown* pUnkOuter, in Guid riid, IRpcProxyBuffer** ppProxy, void** ppv) mut => VT.[Friend]CreateProxy(&this, pUnkOuter, riid, ppProxy, ppv);

	public HRESULT CreateStub(in Guid riid, IUnknown* pUnkServer, IRpcStubBuffer** ppStub) mut => VT.[Friend]CreateStub(&this, riid, pUnkServer, ppStub);
}

[CRepr]struct IChannelHook : IUnknown
{
	public new const Guid IID = .(0x1008c4a0, 0x7613, 0x11cf, 0x9a, 0xf1, 0x00, 0x20, 0xaf, 0x6e, 0x72, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, in Guid uExtent, in Guid riid, uint32* pDataSize) ClientGetSize;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, in Guid uExtent, in Guid riid, uint32* pDataSize, void* pDataBuffer) ClientFillBuffer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, in Guid uExtent, in Guid riid, uint32 cbDataSize, void* pDataBuffer, uint32 lDataRep, HRESULT hrFault) ClientNotify;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, in Guid uExtent, in Guid riid, uint32 cbDataSize, void* pDataBuffer, uint32 lDataRep) ServerNotify;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, in Guid uExtent, in Guid riid, HRESULT hrFault, uint32* pDataSize) ServerGetSize;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, in Guid uExtent, in Guid riid, uint32* pDataSize, void* pDataBuffer, HRESULT hrFault) ServerFillBuffer;
	}


	public void ClientGetSize(in Guid uExtent, in Guid riid, uint32* pDataSize) mut => VT.[Friend]ClientGetSize(&this, uExtent, riid, pDataSize);

	public void ClientFillBuffer(in Guid uExtent, in Guid riid, uint32* pDataSize, void* pDataBuffer) mut => VT.[Friend]ClientFillBuffer(&this, uExtent, riid, pDataSize, pDataBuffer);

	public void ClientNotify(in Guid uExtent, in Guid riid, uint32 cbDataSize, void* pDataBuffer, uint32 lDataRep, HRESULT hrFault) mut => VT.[Friend]ClientNotify(&this, uExtent, riid, cbDataSize, pDataBuffer, lDataRep, hrFault);

	public void ServerNotify(in Guid uExtent, in Guid riid, uint32 cbDataSize, void* pDataBuffer, uint32 lDataRep) mut => VT.[Friend]ServerNotify(&this, uExtent, riid, cbDataSize, pDataBuffer, lDataRep);

	public void ServerGetSize(in Guid uExtent, in Guid riid, HRESULT hrFault, uint32* pDataSize) mut => VT.[Friend]ServerGetSize(&this, uExtent, riid, hrFault, pDataSize);

	public void ServerFillBuffer(in Guid uExtent, in Guid riid, uint32* pDataSize, void* pDataBuffer, HRESULT hrFault) mut => VT.[Friend]ServerFillBuffer(&this, uExtent, riid, pDataSize, pDataBuffer, hrFault);
}

[CRepr]struct IClientSecurity : IUnknown
{
	public new const Guid IID = .(0x0000013d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pProxy, uint32* pAuthnSvc, uint32* pAuthzSvc, uint16** pServerPrincName, RPC_C_AUTHN_LEVEL* pAuthnLevel, RPC_C_IMP_LEVEL* pImpLevel, void** pAuthInfo, EOLE_AUTHENTICATION_CAPABILITIES* pCapabilites) QueryBlanket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pProxy, uint32 dwAuthnSvc, uint32 dwAuthzSvc, PWSTR pServerPrincName, RPC_C_AUTHN_LEVEL dwAuthnLevel, RPC_C_IMP_LEVEL dwImpLevel, void* pAuthInfo, EOLE_AUTHENTICATION_CAPABILITIES dwCapabilities) SetBlanket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pProxy, IUnknown** ppCopy) CopyProxy;
	}


	public HRESULT QueryBlanket(IUnknown* pProxy, uint32* pAuthnSvc, uint32* pAuthzSvc, uint16** pServerPrincName, RPC_C_AUTHN_LEVEL* pAuthnLevel, RPC_C_IMP_LEVEL* pImpLevel, void** pAuthInfo, EOLE_AUTHENTICATION_CAPABILITIES* pCapabilites) mut => VT.[Friend]QueryBlanket(&this, pProxy, pAuthnSvc, pAuthzSvc, pServerPrincName, pAuthnLevel, pImpLevel, pAuthInfo, pCapabilites);

	public HRESULT SetBlanket(IUnknown* pProxy, uint32 dwAuthnSvc, uint32 dwAuthzSvc, PWSTR pServerPrincName, RPC_C_AUTHN_LEVEL dwAuthnLevel, RPC_C_IMP_LEVEL dwImpLevel, void* pAuthInfo, EOLE_AUTHENTICATION_CAPABILITIES dwCapabilities) mut => VT.[Friend]SetBlanket(&this, pProxy, dwAuthnSvc, dwAuthzSvc, pServerPrincName, dwAuthnLevel, dwImpLevel, pAuthInfo, dwCapabilities);

	public HRESULT CopyProxy(IUnknown* pProxy, IUnknown** ppCopy) mut => VT.[Friend]CopyProxy(&this, pProxy, ppCopy);
}

[CRepr]struct IServerSecurity : IUnknown
{
	public new const Guid IID = .(0x0000013e, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pAuthnSvc, uint32* pAuthzSvc, uint16** pServerPrincName, uint32* pAuthnLevel, uint32* pImpLevel, void** pPrivs, uint32* pCapabilities) QueryBlanket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ImpersonateClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RevertToSelf;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsImpersonating;
	}


	public HRESULT QueryBlanket(uint32* pAuthnSvc, uint32* pAuthzSvc, uint16** pServerPrincName, uint32* pAuthnLevel, uint32* pImpLevel, void** pPrivs, uint32* pCapabilities) mut => VT.[Friend]QueryBlanket(&this, pAuthnSvc, pAuthzSvc, pServerPrincName, pAuthnLevel, pImpLevel, pPrivs, pCapabilities);

	public HRESULT ImpersonateClient() mut => VT.[Friend]ImpersonateClient(&this);

	public HRESULT RevertToSelf() mut => VT.[Friend]RevertToSelf(&this);

	public BOOL IsImpersonating() mut => VT.[Friend]IsImpersonating(&this);
}

[CRepr]struct IRpcOptions : IUnknown
{
	public new const Guid IID = .(0x00000144, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pPrx, RPCOPT_PROPERTIES dwProperty, uint dwValue) Set;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pPrx, RPCOPT_PROPERTIES dwProperty, uint* pdwValue) Query;
	}


	public HRESULT Set(IUnknown* pPrx, RPCOPT_PROPERTIES dwProperty, uint dwValue) mut => VT.[Friend]Set(&this, pPrx, dwProperty, dwValue);

	public HRESULT Query(IUnknown* pPrx, RPCOPT_PROPERTIES dwProperty, uint* pdwValue) mut => VT.[Friend]Query(&this, pPrx, dwProperty, pdwValue);
}

[CRepr]struct IGlobalOptions : IUnknown
{
	public new const Guid IID = .(0x0000015b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GLOBALOPT_PROPERTIES dwProperty, uint dwValue) Set;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GLOBALOPT_PROPERTIES dwProperty, uint* pdwValue) Query;
	}


	public HRESULT Set(GLOBALOPT_PROPERTIES dwProperty, uint dwValue) mut => VT.[Friend]Set(&this, dwProperty, dwValue);

	public HRESULT Query(GLOBALOPT_PROPERTIES dwProperty, uint* pdwValue) mut => VT.[Friend]Query(&this, dwProperty, pdwValue);
}

[CRepr]struct ISurrogate : IUnknown
{
	public new const Guid IID = .(0x00000022, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Clsid) LoadDllServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FreeSurrogate;
	}


	public HRESULT LoadDllServer(in Guid Clsid) mut => VT.[Friend]LoadDllServer(&this, Clsid);

	public HRESULT FreeSurrogate() mut => VT.[Friend]FreeSurrogate(&this);
}

[CRepr]struct IGlobalInterfaceTable : IUnknown
{
	public new const Guid IID = .(0x00000146, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnk, in Guid riid, uint32* pdwCookie) RegisterInterfaceInGlobal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) RevokeInterfaceFromGlobal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie, in Guid riid, void** ppv) GetInterfaceFromGlobal;
	}


	public HRESULT RegisterInterfaceInGlobal(IUnknown* pUnk, in Guid riid, uint32* pdwCookie) mut => VT.[Friend]RegisterInterfaceInGlobal(&this, pUnk, riid, pdwCookie);

	public HRESULT RevokeInterfaceFromGlobal(uint32 dwCookie) mut => VT.[Friend]RevokeInterfaceFromGlobal(&this, dwCookie);

	public HRESULT GetInterfaceFromGlobal(uint32 dwCookie, in Guid riid, void** ppv) mut => VT.[Friend]GetInterfaceFromGlobal(&this, dwCookie, riid, ppv);
}

[CRepr]struct ISynchronize : IUnknown
{
	public new const Guid IID = .(0x00000030, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 dwMilliseconds) Wait;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Signal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT Wait(uint32 dwFlags, uint32 dwMilliseconds) mut => VT.[Friend]Wait(&this, dwFlags, dwMilliseconds);

	public HRESULT Signal() mut => VT.[Friend]Signal(&this);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct ISynchronizeHandle : IUnknown
{
	public new const Guid IID = .(0x00000031, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* ph) GetHandle;
	}


	public HRESULT GetHandle(HANDLE* ph) mut => VT.[Friend]GetHandle(&this, ph);
}

[CRepr]struct ISynchronizeEvent : ISynchronizeHandle
{
	public new const Guid IID = .(0x00000032, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISynchronizeHandle.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* ph) SetEventHandle;
	}


	public HRESULT SetEventHandle(HANDLE* ph) mut => VT.[Friend]SetEventHandle(&this, ph);
}

[CRepr]struct ISynchronizeContainer : IUnknown
{
	public new const Guid IID = .(0x00000033, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISynchronize* pSync) AddSynchronize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 dwTimeOut, ISynchronize** ppSync) WaitMultiple;
	}


	public HRESULT AddSynchronize(ISynchronize* pSync) mut => VT.[Friend]AddSynchronize(&this, pSync);

	public HRESULT WaitMultiple(uint32 dwFlags, uint32 dwTimeOut, ISynchronize** ppSync) mut => VT.[Friend]WaitMultiple(&this, dwFlags, dwTimeOut, ppSync);
}

[CRepr]struct ISynchronizeMutex : ISynchronize
{
	public new const Guid IID = .(0x00000025, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISynchronize.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseMutex;
	}


	public HRESULT ReleaseMutex() mut => VT.[Friend]ReleaseMutex(&this);
}

[CRepr]struct ICancelMethodCalls : IUnknown
{
	public new const Guid IID = .(0x00000029, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSeconds) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TestCancel;
	}


	public HRESULT Cancel(uint32 ulSeconds) mut => VT.[Friend]Cancel(&this, ulSeconds);

	public HRESULT TestCancel() mut => VT.[Friend]TestCancel(&this);
}

[CRepr]struct IAsyncManager : IUnknown
{
	public new const Guid IID = .(0x0000002a, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT Result) CompleteCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** pInterface) GetCallContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulStateFlags) GetState;
	}


	public HRESULT CompleteCall(HRESULT Result) mut => VT.[Friend]CompleteCall(&this, Result);

	public HRESULT GetCallContext(in Guid riid, void** pInterface) mut => VT.[Friend]GetCallContext(&this, riid, pInterface);

	public HRESULT GetState(uint32* pulStateFlags) mut => VT.[Friend]GetState(&this, pulStateFlags);
}

[CRepr]struct ICallFactory : IUnknown
{
	public new const Guid IID = .(0x1c733a30, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* pCtrlUnk, in Guid riid2, IUnknown** ppv) CreateCall;
	}


	public HRESULT CreateCall(in Guid riid, IUnknown* pCtrlUnk, in Guid riid2, IUnknown** ppv) mut => VT.[Friend]CreateCall(&this, riid, pCtrlUnk, riid2, ppv);
}

[CRepr]struct IRpcHelper : IUnknown
{
	public new const Guid IID = .(0x00000149, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pComVersion) GetDCOMProtocolVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pObjRef, Guid** piid) GetIIDFromOBJREF;
	}


	public HRESULT GetDCOMProtocolVersion(uint32* pComVersion) mut => VT.[Friend]GetDCOMProtocolVersion(&this, pComVersion);

	public HRESULT GetIIDFromOBJREF(void* pObjRef, Guid** piid) mut => VT.[Friend]GetIIDFromOBJREF(&this, pObjRef, piid);
}

[CRepr]struct IReleaseMarshalBuffers : IUnknown
{
	public new const Guid IID = .(0xeb0cb9e8, 0x7996, 0x11d2, 0x87, 0x2e, 0x00, 0x00, 0xf8, 0x08, 0x08, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RPCOLEMESSAGE* pMsg, uint32 dwFlags, IUnknown* pChnl) ReleaseMarshalBuffer;
	}


	public HRESULT ReleaseMarshalBuffer(RPCOLEMESSAGE* pMsg, uint32 dwFlags, IUnknown* pChnl) mut => VT.[Friend]ReleaseMarshalBuffer(&this, pMsg, dwFlags, pChnl);
}

[CRepr]struct IWaitMultiple : IUnknown
{
	public new const Guid IID = .(0x0000002b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 timeout, ISynchronize** pSync) WaitMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISynchronize* pSync) AddSynchronize;
	}


	public HRESULT WaitMultiple(uint32 timeout, ISynchronize** pSync) mut => VT.[Friend]WaitMultiple(&this, timeout, pSync);

	public HRESULT AddSynchronize(ISynchronize* pSync) mut => VT.[Friend]AddSynchronize(&this, pSync);
}

[CRepr]struct IAddrTrackingControl : IUnknown
{
	public new const Guid IID = .(0x00000147, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableCOMDynamicAddrTracking;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableCOMDynamicAddrTracking;
	}


	public HRESULT EnableCOMDynamicAddrTracking() mut => VT.[Friend]EnableCOMDynamicAddrTracking(&this);

	public HRESULT DisableCOMDynamicAddrTracking() mut => VT.[Friend]DisableCOMDynamicAddrTracking(&this);
}

[CRepr]struct IAddrExclusionControl : IUnknown
{
	public new const Guid IID = .(0x00000148, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppEnumerator) GetCurrentAddrExclusionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pEnumerator) UpdateAddrExclusionList;
	}


	public HRESULT GetCurrentAddrExclusionList(in Guid riid, void** ppEnumerator) mut => VT.[Friend]GetCurrentAddrExclusionList(&this, riid, ppEnumerator);

	public HRESULT UpdateAddrExclusionList(IUnknown* pEnumerator) mut => VT.[Friend]UpdateAddrExclusionList(&this, pEnumerator);
}

[CRepr]struct IPipeByte : IUnknown
{
	public new const Guid IID = .(0xdb2f3aca, 0x2f86, 0x11d1, 0x8e, 0x04, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* buf, uint32 cRequest, uint32* pcReturned) Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* buf, uint32 cSent) Push;
	}


	public HRESULT Pull(uint8* buf, uint32 cRequest, uint32* pcReturned) mut => VT.[Friend]Pull(&this, buf, cRequest, pcReturned);

	public HRESULT Push(uint8* buf, uint32 cSent) mut => VT.[Friend]Push(&this, buf, cSent);
}

[CRepr]struct AsyncIPipeByte : IUnknown
{
	public new const Guid IID = .(0xdb2f3acb, 0x2f86, 0x11d1, 0x8e, 0x04, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cRequest) Begin_Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* buf, uint32* pcReturned) Finish_Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* buf, uint32 cSent) Begin_Push;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Push;
	}


	public HRESULT Begin_Pull(uint32 cRequest) mut => VT.[Friend]Begin_Pull(&this, cRequest);

	public HRESULT Finish_Pull(uint8* buf, uint32* pcReturned) mut => VT.[Friend]Finish_Pull(&this, buf, pcReturned);

	public HRESULT Begin_Push(uint8* buf, uint32 cSent) mut => VT.[Friend]Begin_Push(&this, buf, cSent);

	public HRESULT Finish_Push() mut => VT.[Friend]Finish_Push(&this);
}

[CRepr]struct IPipeLong : IUnknown
{
	public new const Guid IID = .(0xdb2f3acc, 0x2f86, 0x11d1, 0x8e, 0x04, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* buf, uint32 cRequest, uint32* pcReturned) Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* buf, uint32 cSent) Push;
	}


	public HRESULT Pull(int32* buf, uint32 cRequest, uint32* pcReturned) mut => VT.[Friend]Pull(&this, buf, cRequest, pcReturned);

	public HRESULT Push(int32* buf, uint32 cSent) mut => VT.[Friend]Push(&this, buf, cSent);
}

[CRepr]struct AsyncIPipeLong : IUnknown
{
	public new const Guid IID = .(0xdb2f3acd, 0x2f86, 0x11d1, 0x8e, 0x04, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cRequest) Begin_Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* buf, uint32* pcReturned) Finish_Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* buf, uint32 cSent) Begin_Push;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Push;
	}


	public HRESULT Begin_Pull(uint32 cRequest) mut => VT.[Friend]Begin_Pull(&this, cRequest);

	public HRESULT Finish_Pull(int32* buf, uint32* pcReturned) mut => VT.[Friend]Finish_Pull(&this, buf, pcReturned);

	public HRESULT Begin_Push(int32* buf, uint32 cSent) mut => VT.[Friend]Begin_Push(&this, buf, cSent);

	public HRESULT Finish_Push() mut => VT.[Friend]Finish_Push(&this);
}

[CRepr]struct IPipeDouble : IUnknown
{
	public new const Guid IID = .(0xdb2f3ace, 0x2f86, 0x11d1, 0x8e, 0x04, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* buf, uint32 cRequest, uint32* pcReturned) Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* buf, uint32 cSent) Push;
	}


	public HRESULT Pull(double* buf, uint32 cRequest, uint32* pcReturned) mut => VT.[Friend]Pull(&this, buf, cRequest, pcReturned);

	public HRESULT Push(double* buf, uint32 cSent) mut => VT.[Friend]Push(&this, buf, cSent);
}

[CRepr]struct AsyncIPipeDouble : IUnknown
{
	public new const Guid IID = .(0xdb2f3acf, 0x2f86, 0x11d1, 0x8e, 0x04, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cRequest) Begin_Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* buf, uint32* pcReturned) Finish_Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* buf, uint32 cSent) Begin_Push;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Push;
	}


	public HRESULT Begin_Pull(uint32 cRequest) mut => VT.[Friend]Begin_Pull(&this, cRequest);

	public HRESULT Finish_Pull(double* buf, uint32* pcReturned) mut => VT.[Friend]Finish_Pull(&this, buf, pcReturned);

	public HRESULT Begin_Push(double* buf, uint32 cSent) mut => VT.[Friend]Begin_Push(&this, buf, cSent);

	public HRESULT Finish_Push() mut => VT.[Friend]Finish_Push(&this);
}

[CRepr]struct IComThreadingInfo : IUnknown
{
	public new const Guid IID = .(0x000001ce, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APTTYPE* pAptType) GetCurrentApartmentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, THDTYPE* pThreadType) GetCurrentThreadType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidLogicalThreadId) GetCurrentLogicalThreadId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid) SetCurrentLogicalThreadId;
	}


	public HRESULT GetCurrentApartmentType(APTTYPE* pAptType) mut => VT.[Friend]GetCurrentApartmentType(&this, pAptType);

	public HRESULT GetCurrentThreadType(THDTYPE* pThreadType) mut => VT.[Friend]GetCurrentThreadType(&this, pThreadType);

	public HRESULT GetCurrentLogicalThreadId(Guid* pguidLogicalThreadId) mut => VT.[Friend]GetCurrentLogicalThreadId(&this, pguidLogicalThreadId);

	public HRESULT SetCurrentLogicalThreadId(in Guid rguid) mut => VT.[Friend]SetCurrentLogicalThreadId(&this, rguid);
}

[CRepr]struct IProcessInitControl : IUnknown
{
	public new const Guid IID = .(0x72380d55, 0x8d2b, 0x43a3, 0x85, 0x13, 0x2b, 0x6e, 0xf3, 0x14, 0x34, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSecondsRemaining) ResetInitializerTimeout;
	}


	public HRESULT ResetInitializerTimeout(uint32 dwSecondsRemaining) mut => VT.[Friend]ResetInitializerTimeout(&this, dwSecondsRemaining);
}

[CRepr]struct IFastRundown : IUnknown
{
	public new const Guid IID = .(0x00000040, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IMachineGlobalObjectTable : IUnknown
{
	public new const Guid IID = .(0x26d709ac, 0xf70b, 0x4421, 0xa9, 0x6f, 0xd2, 0x87, 0x8f, 0xaf, 0xb0, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, PWSTR identifier, IUnknown* object, MachineGlobalObjectTableRegistrationToken__** token) RegisterObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, PWSTR identifier, in Guid riid, void** ppv) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MachineGlobalObjectTableRegistrationToken__* token) RevokeObject;
	}


	public HRESULT RegisterObject(in Guid clsid, PWSTR identifier, IUnknown* object, MachineGlobalObjectTableRegistrationToken__** token) mut => VT.[Friend]RegisterObject(&this, clsid, identifier, object, token);

	public HRESULT GetObject(in Guid clsid, PWSTR identifier, in Guid riid, void** ppv) mut => VT.[Friend]GetObject(&this, clsid, identifier, riid, ppv);

	public HRESULT RevokeObject(MachineGlobalObjectTableRegistrationToken__* token) mut => VT.[Friend]RevokeObject(&this, token);
}

[CRepr]struct IMallocSpy : IUnknown
{
	public new const Guid IID = .(0x0000001d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self, uint cbRequest) PreAlloc;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, void* pActual) PostAlloc;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, void* pRequest, BOOL fSpyed) PreFree;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BOOL fSpyed) PostFree;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self, void* pRequest, uint cbRequest, void** ppNewRequest, BOOL fSpyed) PreRealloc;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, void* pActual, BOOL fSpyed) PostRealloc;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, void* pRequest, BOOL fSpyed) PreGetSize;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self, uint cbActual, BOOL fSpyed) PostGetSize;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self, void* pRequest, BOOL fSpyed) PreDidAlloc;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, void* pRequest, BOOL fSpyed, int32 fActual) PostDidAlloc;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PreHeapMinimize;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PostHeapMinimize;
	}


	public uint PreAlloc(uint cbRequest) mut => VT.[Friend]PreAlloc(&this, cbRequest);

	public void* PostAlloc(void* pActual) mut => VT.[Friend]PostAlloc(&this, pActual);

	public void* PreFree(void* pRequest, BOOL fSpyed) mut => VT.[Friend]PreFree(&this, pRequest, fSpyed);

	public void PostFree(BOOL fSpyed) mut => VT.[Friend]PostFree(&this, fSpyed);

	public uint PreRealloc(void* pRequest, uint cbRequest, void** ppNewRequest, BOOL fSpyed) mut => VT.[Friend]PreRealloc(&this, pRequest, cbRequest, ppNewRequest, fSpyed);

	public void* PostRealloc(void* pActual, BOOL fSpyed) mut => VT.[Friend]PostRealloc(&this, pActual, fSpyed);

	public void* PreGetSize(void* pRequest, BOOL fSpyed) mut => VT.[Friend]PreGetSize(&this, pRequest, fSpyed);

	public uint PostGetSize(uint cbActual, BOOL fSpyed) mut => VT.[Friend]PostGetSize(&this, cbActual, fSpyed);

	public void* PreDidAlloc(void* pRequest, BOOL fSpyed) mut => VT.[Friend]PreDidAlloc(&this, pRequest, fSpyed);

	public int32 PostDidAlloc(void* pRequest, BOOL fSpyed, int32 fActual) mut => VT.[Friend]PostDidAlloc(&this, pRequest, fSpyed, fActual);

	public void PreHeapMinimize() mut => VT.[Friend]PreHeapMinimize(&this);

	public void PostHeapMinimize() mut => VT.[Friend]PostHeapMinimize(&this);
}

[CRepr]struct IBindCtx : IUnknown
{
	public new const Guid IID = .(0x0000000e, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) RegisterObjectBound;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) RevokeObjectBound;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseBoundObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BIND_OPTS* pbindopts) SetBindOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BIND_OPTS* pbindopts) GetBindOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRunningObjectTable** pprot) GetRunningObjectTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszKey, IUnknown* punk) RegisterObjectParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszKey, IUnknown** ppunk) GetObjectParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppenum) EnumObjectParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszKey) RevokeObjectParam;
	}


	public HRESULT RegisterObjectBound(IUnknown* punk) mut => VT.[Friend]RegisterObjectBound(&this, punk);

	public HRESULT RevokeObjectBound(IUnknown* punk) mut => VT.[Friend]RevokeObjectBound(&this, punk);

	public HRESULT ReleaseBoundObjects() mut => VT.[Friend]ReleaseBoundObjects(&this);

	public HRESULT SetBindOptions(BIND_OPTS* pbindopts) mut => VT.[Friend]SetBindOptions(&this, pbindopts);

	public HRESULT GetBindOptions(BIND_OPTS* pbindopts) mut => VT.[Friend]GetBindOptions(&this, pbindopts);

	public HRESULT GetRunningObjectTable(IRunningObjectTable** pprot) mut => VT.[Friend]GetRunningObjectTable(&this, pprot);

	public HRESULT RegisterObjectParam(PWSTR pszKey, IUnknown* punk) mut => VT.[Friend]RegisterObjectParam(&this, pszKey, punk);

	public HRESULT GetObjectParam(PWSTR pszKey, IUnknown** ppunk) mut => VT.[Friend]GetObjectParam(&this, pszKey, ppunk);

	public HRESULT EnumObjectParam(IEnumString** ppenum) mut => VT.[Friend]EnumObjectParam(&this, ppenum);

	public HRESULT RevokeObjectParam(PWSTR pszKey) mut => VT.[Friend]RevokeObjectParam(&this, pszKey);
}

[CRepr]struct IEnumMoniker : IUnknown
{
	public new const Guid IID = .(0x00000102, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IMoniker** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumMoniker** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, IMoniker** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumMoniker** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IRunnableObject : IUnknown
{
	public new const Guid IID = .(0x00000126, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* lpClsid) GetRunningClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc) Run;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLock, BOOL fLastUnlockCloses) LockRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fContained) SetContainedObject;
	}


	public HRESULT GetRunningClass(Guid* lpClsid) mut => VT.[Friend]GetRunningClass(&this, lpClsid);

	public HRESULT Run(IBindCtx* pbc) mut => VT.[Friend]Run(&this, pbc);

	public BOOL IsRunning() mut => VT.[Friend]IsRunning(&this);

	public HRESULT LockRunning(BOOL fLock, BOOL fLastUnlockCloses) mut => VT.[Friend]LockRunning(&this, fLock, fLastUnlockCloses);

	public HRESULT SetContainedObject(BOOL fContained) mut => VT.[Friend]SetContainedObject(&this, fContained);
}

[CRepr]struct IRunningObjectTable : IUnknown
{
	public new const Guid IID = .(0x00000010, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ROT_FLAGS grfFlags, IUnknown* punkObject, IMoniker* pmkObjectName, uint32* pdwRegister) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegister) Revoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkObjectName) IsRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkObjectName, IUnknown** ppunkObject) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegister, FILETIME* pfiletime) NoteChangeTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkObjectName, FILETIME* pfiletime) GetTimeOfLastChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumMoniker** ppenumMoniker) EnumRunning;
	}


	public HRESULT Register(ROT_FLAGS grfFlags, IUnknown* punkObject, IMoniker* pmkObjectName, uint32* pdwRegister) mut => VT.[Friend]Register(&this, grfFlags, punkObject, pmkObjectName, pdwRegister);

	public HRESULT Revoke(uint32 dwRegister) mut => VT.[Friend]Revoke(&this, dwRegister);

	public HRESULT IsRunning(IMoniker* pmkObjectName) mut => VT.[Friend]IsRunning(&this, pmkObjectName);

	public HRESULT GetObject(IMoniker* pmkObjectName, IUnknown** ppunkObject) mut => VT.[Friend]GetObject(&this, pmkObjectName, ppunkObject);

	public HRESULT NoteChangeTime(uint32 dwRegister, FILETIME* pfiletime) mut => VT.[Friend]NoteChangeTime(&this, dwRegister, pfiletime);

	public HRESULT GetTimeOfLastChange(IMoniker* pmkObjectName, FILETIME* pfiletime) mut => VT.[Friend]GetTimeOfLastChange(&this, pmkObjectName, pfiletime);

	public HRESULT EnumRunning(IEnumMoniker** ppenumMoniker) mut => VT.[Friend]EnumRunning(&this, ppenumMoniker);
}

[CRepr]struct IPersist : IUnknown
{
	public new const Guid IID = .(0x0000010c, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pClassID) GetClassID;
	}


	public HRESULT GetClassID(Guid* pClassID) mut => VT.[Friend]GetClassID(&this, pClassID);
}

[CRepr]struct IPersistStream : IPersist
{
	public new const Guid IID = .(0x00000109, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStm) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStm, BOOL fClearDirty) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER* pcbSize) GetSizeMax;
	}


	public HRESULT IsDirty() mut => VT.[Friend]IsDirty(&this);

	public HRESULT Load(IStream* pStm) mut => VT.[Friend]Load(&this, pStm);

	public HRESULT Save(IStream* pStm, BOOL fClearDirty) mut => VT.[Friend]Save(&this, pStm, fClearDirty);

	public HRESULT GetSizeMax(ULARGE_INTEGER* pcbSize) mut => VT.[Friend]GetSizeMax(&this, pcbSize);
}

[CRepr]struct IMoniker : IPersistStream
{
	public new const Guid IID = .(0x0000000f, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, IMoniker* pmkToLeft, in Guid riidResult, void** ppvResult) BindToObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, IMoniker* pmkToLeft, in Guid riid, void** ppvObj) BindToStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, uint32 dwReduceHowFar, IMoniker** ppmkToLeft, IMoniker** ppmkReduced) Reduce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkRight, BOOL fOnlyIfNotGeneric, IMoniker** ppmkComposite) ComposeWith;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fForward, IEnumMoniker** ppenumMoniker) Enum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkOtherMoniker) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwHash) Hash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, IMoniker* pmkToLeft, IMoniker* pmkNewlyRunning) IsRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, IMoniker* pmkToLeft, FILETIME* pFileTime) GetTimeOfLastChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker** ppmk) Inverse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkOther, IMoniker** ppmkPrefix) CommonPrefixWith;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmkOther, IMoniker** ppmkRelPath) RelativePathTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, IMoniker* pmkToLeft, PWSTR* ppszDisplayName) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, IMoniker* pmkToLeft, PWSTR pszDisplayName, uint32* pchEaten, IMoniker** ppmkOut) ParseDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMksys) IsSystemMoniker;
	}


	public HRESULT BindToObject(IBindCtx* pbc, IMoniker* pmkToLeft, in Guid riidResult, void** ppvResult) mut => VT.[Friend]BindToObject(&this, pbc, pmkToLeft, riidResult, ppvResult);

	public HRESULT BindToStorage(IBindCtx* pbc, IMoniker* pmkToLeft, in Guid riid, void** ppvObj) mut => VT.[Friend]BindToStorage(&this, pbc, pmkToLeft, riid, ppvObj);

	public HRESULT Reduce(IBindCtx* pbc, uint32 dwReduceHowFar, IMoniker** ppmkToLeft, IMoniker** ppmkReduced) mut => VT.[Friend]Reduce(&this, pbc, dwReduceHowFar, ppmkToLeft, ppmkReduced);

	public HRESULT ComposeWith(IMoniker* pmkRight, BOOL fOnlyIfNotGeneric, IMoniker** ppmkComposite) mut => VT.[Friend]ComposeWith(&this, pmkRight, fOnlyIfNotGeneric, ppmkComposite);

	public HRESULT Enum(BOOL fForward, IEnumMoniker** ppenumMoniker) mut => VT.[Friend]Enum(&this, fForward, ppenumMoniker);

	public HRESULT IsEqual(IMoniker* pmkOtherMoniker) mut => VT.[Friend]IsEqual(&this, pmkOtherMoniker);

	public HRESULT Hash(uint32* pdwHash) mut => VT.[Friend]Hash(&this, pdwHash);

	public HRESULT IsRunning(IBindCtx* pbc, IMoniker* pmkToLeft, IMoniker* pmkNewlyRunning) mut => VT.[Friend]IsRunning(&this, pbc, pmkToLeft, pmkNewlyRunning);

	public HRESULT GetTimeOfLastChange(IBindCtx* pbc, IMoniker* pmkToLeft, FILETIME* pFileTime) mut => VT.[Friend]GetTimeOfLastChange(&this, pbc, pmkToLeft, pFileTime);

	public HRESULT Inverse(IMoniker** ppmk) mut => VT.[Friend]Inverse(&this, ppmk);

	public HRESULT CommonPrefixWith(IMoniker* pmkOther, IMoniker** ppmkPrefix) mut => VT.[Friend]CommonPrefixWith(&this, pmkOther, ppmkPrefix);

	public HRESULT RelativePathTo(IMoniker* pmkOther, IMoniker** ppmkRelPath) mut => VT.[Friend]RelativePathTo(&this, pmkOther, ppmkRelPath);

	public HRESULT GetDisplayName(IBindCtx* pbc, IMoniker* pmkToLeft, PWSTR* ppszDisplayName) mut => VT.[Friend]GetDisplayName(&this, pbc, pmkToLeft, ppszDisplayName);

	public HRESULT ParseDisplayName(IBindCtx* pbc, IMoniker* pmkToLeft, PWSTR pszDisplayName, uint32* pchEaten, IMoniker** ppmkOut) mut => VT.[Friend]ParseDisplayName(&this, pbc, pmkToLeft, pszDisplayName, pchEaten, ppmkOut);

	public HRESULT IsSystemMoniker(uint32* pdwMksys) mut => VT.[Friend]IsSystemMoniker(&this, pdwMksys);
}

[CRepr]struct IROTData : IUnknown
{
	public new const Guid IID = .(0xf29f6bc0, 0x5021, 0x11ce, 0xaa, 0x15, 0x00, 0x00, 0x69, 0x01, 0x29, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbData, uint32 cbMax, uint32* pcbData) GetComparisonData;
	}


	public HRESULT GetComparisonData(uint8* pbData, uint32 cbMax, uint32* pcbData) mut => VT.[Friend]GetComparisonData(&this, pbData, cbMax, pcbData);
}

[CRepr]struct IPersistFile : IPersist
{
	public new const Guid IID = .(0x0000010b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName, uint32 dwMode) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName, BOOL fRemember) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName) SaveCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszFileName) GetCurFile;
	}


	public HRESULT IsDirty() mut => VT.[Friend]IsDirty(&this);

	public HRESULT Load(PWSTR pszFileName, uint32 dwMode) mut => VT.[Friend]Load(&this, pszFileName, dwMode);

	public HRESULT Save(PWSTR pszFileName, BOOL fRemember) mut => VT.[Friend]Save(&this, pszFileName, fRemember);

	public HRESULT SaveCompleted(PWSTR pszFileName) mut => VT.[Friend]SaveCompleted(&this, pszFileName);

	public HRESULT GetCurFile(PWSTR* ppszFileName) mut => VT.[Friend]GetCurFile(&this, ppszFileName);
}

[CRepr]struct IEnumFORMATETC : IUnknown
{
	public new const Guid IID = .(0x00000103, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, FORMATETC* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumFORMATETC** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, FORMATETC* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumFORMATETC** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumSTATDATA : IUnknown
{
	public new const Guid IID = .(0x00000105, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, STATDATA* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATDATA** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, STATDATA* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSTATDATA** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IAdviseSink : IUnknown
{
	public new const Guid IID = .(0x0000010f, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, FORMATETC* pFormatetc, STGMEDIUM* pStgmed) OnDataChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwAspect, int32 lindex) OnViewChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IMoniker* pmk) OnRename;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnSave;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) OnClose;
	}


	public void OnDataChange(FORMATETC* pFormatetc, STGMEDIUM* pStgmed) mut => VT.[Friend]OnDataChange(&this, pFormatetc, pStgmed);

	public void OnViewChange(uint32 dwAspect, int32 lindex) mut => VT.[Friend]OnViewChange(&this, dwAspect, lindex);

	public void OnRename(IMoniker* pmk) mut => VT.[Friend]OnRename(&this, pmk);

	public void OnSave() mut => VT.[Friend]OnSave(&this);

	public void OnClose() mut => VT.[Friend]OnClose(&this);
}

[CRepr]struct AsyncIAdviseSink : IUnknown
{
	public new const Guid IID = .(0x00000150, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, FORMATETC* pFormatetc, STGMEDIUM* pStgmed) Begin_OnDataChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Finish_OnDataChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwAspect, int32 lindex) Begin_OnViewChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Finish_OnViewChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IMoniker* pmk) Begin_OnRename;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Finish_OnRename;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Begin_OnSave;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Finish_OnSave;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Begin_OnClose;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Finish_OnClose;
	}


	public void Begin_OnDataChange(FORMATETC* pFormatetc, STGMEDIUM* pStgmed) mut => VT.[Friend]Begin_OnDataChange(&this, pFormatetc, pStgmed);

	public void Finish_OnDataChange() mut => VT.[Friend]Finish_OnDataChange(&this);

	public void Begin_OnViewChange(uint32 dwAspect, int32 lindex) mut => VT.[Friend]Begin_OnViewChange(&this, dwAspect, lindex);

	public void Finish_OnViewChange() mut => VT.[Friend]Finish_OnViewChange(&this);

	public void Begin_OnRename(IMoniker* pmk) mut => VT.[Friend]Begin_OnRename(&this, pmk);

	public void Finish_OnRename() mut => VT.[Friend]Finish_OnRename(&this);

	public void Begin_OnSave() mut => VT.[Friend]Begin_OnSave(&this);

	public void Finish_OnSave() mut => VT.[Friend]Finish_OnSave(&this);

	public void Begin_OnClose() mut => VT.[Friend]Begin_OnClose(&this);

	public void Finish_OnClose() mut => VT.[Friend]Finish_OnClose(&this);
}

[CRepr]struct IAdviseSink2 : IAdviseSink
{
	public new const Guid IID = .(0x00000125, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAdviseSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IMoniker* pmk) OnLinkSrcChange;
	}


	public void OnLinkSrcChange(IMoniker* pmk) mut => VT.[Friend]OnLinkSrcChange(&this, pmk);
}

[CRepr]struct AsyncIAdviseSink2 : AsyncIAdviseSink
{
	public new const Guid IID = .(0x00000151, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : AsyncIAdviseSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IMoniker* pmk) Begin_OnLinkSrcChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Finish_OnLinkSrcChange;
	}


	public void Begin_OnLinkSrcChange(IMoniker* pmk) mut => VT.[Friend]Begin_OnLinkSrcChange(&this, pmk);

	public void Finish_OnLinkSrcChange() mut => VT.[Friend]Finish_OnLinkSrcChange(&this);
}

[CRepr]struct IDataObject : IUnknown
{
	public new const Guid IID = .(0x0000010e, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetcIn, STGMEDIUM* pmedium) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetc, STGMEDIUM* pmedium) GetDataHere;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetc) QueryGetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatectIn, FORMATETC* pformatetcOut) GetCanonicalFormatEtc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetc, STGMEDIUM* pmedium, BOOL fRelease) SetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDirection, IEnumFORMATETC** ppenumFormatEtc) EnumFormatEtc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FORMATETC* pformatetc, uint32 advf, IAdviseSink* pAdvSink, uint32* pdwConnection) DAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnection) DUnadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATDATA** ppenumAdvise) EnumDAdvise;
	}


	public HRESULT GetData(FORMATETC* pformatetcIn, STGMEDIUM* pmedium) mut => VT.[Friend]GetData(&this, pformatetcIn, pmedium);

	public HRESULT GetDataHere(FORMATETC* pformatetc, STGMEDIUM* pmedium) mut => VT.[Friend]GetDataHere(&this, pformatetc, pmedium);

	public HRESULT QueryGetData(FORMATETC* pformatetc) mut => VT.[Friend]QueryGetData(&this, pformatetc);

	public HRESULT GetCanonicalFormatEtc(FORMATETC* pformatectIn, FORMATETC* pformatetcOut) mut => VT.[Friend]GetCanonicalFormatEtc(&this, pformatectIn, pformatetcOut);

	public HRESULT SetData(FORMATETC* pformatetc, STGMEDIUM* pmedium, BOOL fRelease) mut => VT.[Friend]SetData(&this, pformatetc, pmedium, fRelease);

	public HRESULT EnumFormatEtc(uint32 dwDirection, IEnumFORMATETC** ppenumFormatEtc) mut => VT.[Friend]EnumFormatEtc(&this, dwDirection, ppenumFormatEtc);

	public HRESULT DAdvise(FORMATETC* pformatetc, uint32 advf, IAdviseSink* pAdvSink, uint32* pdwConnection) mut => VT.[Friend]DAdvise(&this, pformatetc, advf, pAdvSink, pdwConnection);

	public HRESULT DUnadvise(uint32 dwConnection) mut => VT.[Friend]DUnadvise(&this, dwConnection);

	public HRESULT EnumDAdvise(IEnumSTATDATA** ppenumAdvise) mut => VT.[Friend]EnumDAdvise(&this, ppenumAdvise);
}

[CRepr]struct IDataAdviseHolder : IUnknown
{
	public new const Guid IID = .(0x00000110, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, FORMATETC* pFetc, uint32 advf, IAdviseSink* pAdvise, uint32* pdwConnection) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwConnection) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATDATA** ppenumAdvise) EnumAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, uint32 dwReserved, uint32 advf) SendOnDataChange;
	}


	public HRESULT Advise(IDataObject* pDataObject, FORMATETC* pFetc, uint32 advf, IAdviseSink* pAdvise, uint32* pdwConnection) mut => VT.[Friend]Advise(&this, pDataObject, pFetc, advf, pAdvise, pdwConnection);

	public HRESULT Unadvise(uint32 dwConnection) mut => VT.[Friend]Unadvise(&this, dwConnection);

	public HRESULT EnumAdvise(IEnumSTATDATA** ppenumAdvise) mut => VT.[Friend]EnumAdvise(&this, ppenumAdvise);

	public HRESULT SendOnDataChange(IDataObject* pDataObject, uint32 dwReserved, uint32 advf) mut => VT.[Friend]SendOnDataChange(&this, pDataObject, dwReserved, advf);
}

[CRepr]struct IClassActivator : IUnknown
{
	public new const Guid IID = .(0x00000140, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 dwClassContext, uint32 locale, in Guid riid, void** ppv) GetClassObject;
	}


	public HRESULT GetClassObject(in Guid rclsid, uint32 dwClassContext, uint32 locale, in Guid riid, void** ppv) mut => VT.[Friend]GetClassObject(&this, rclsid, dwClassContext, locale, riid, ppv);
}

[CRepr]struct IProgressNotify : IUnknown
{
	public new const Guid IID = .(0xa9d758a0, 0x4617, 0x11cf, 0x95, 0xfc, 0x00, 0xaa, 0x00, 0x68, 0x0d, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProgressCurrent, uint32 dwProgressMaximum, BOOL fAccurate, BOOL fOwner) OnProgress;
	}


	public HRESULT OnProgress(uint32 dwProgressCurrent, uint32 dwProgressMaximum, BOOL fAccurate, BOOL fOwner) mut => VT.[Friend]OnProgress(&this, dwProgressCurrent, dwProgressMaximum, fAccurate, fOwner);
}

[CRepr]struct IBlockingLock : IUnknown
{
	public new const Guid IID = .(0x30f3d47a, 0x6447, 0x11d1, 0x8e, 0x3c, 0x00, 0xc0, 0x4f, 0xb9, 0x38, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTimeout) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unlock;
	}


	public HRESULT Lock(uint32 dwTimeout) mut => VT.[Friend]Lock(&this, dwTimeout);

	public HRESULT Unlock() mut => VT.[Friend]Unlock(&this);
}

[CRepr]struct ITimeAndNoticeControl : IUnknown
{
	public new const Guid IID = .(0xbc0bf6ae, 0x8878, 0x11d1, 0x83, 0xe9, 0x00, 0xc0, 0x4f, 0xc2, 0xc6, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 res1, uint32 res2) SuppressChanges;
	}


	public HRESULT SuppressChanges(uint32 res1, uint32 res2) mut => VT.[Friend]SuppressChanges(&this, res1, res2);
}

[CRepr]struct IOplockStorage : IUnknown
{
	public new const Guid IID = .(0x8d19c834, 0x8879, 0x11d1, 0x83, 0xe9, 0x00, 0xc0, 0x4f, 0xc2, 0xc6, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, uint32 grfMode, uint32 stgfmt, uint32 grfAttrs, in Guid riid, void** ppstgOpen) CreateStorageEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, uint32 grfMode, uint32 stgfmt, uint32 grfAttrs, in Guid riid, void** ppstgOpen) OpenStorageEx;
	}


	public HRESULT CreateStorageEx(PWSTR pwcsName, uint32 grfMode, uint32 stgfmt, uint32 grfAttrs, in Guid riid, void** ppstgOpen) mut => VT.[Friend]CreateStorageEx(&this, pwcsName, grfMode, stgfmt, grfAttrs, riid, ppstgOpen);

	public HRESULT OpenStorageEx(PWSTR pwcsName, uint32 grfMode, uint32 stgfmt, uint32 grfAttrs, in Guid riid, void** ppstgOpen) mut => VT.[Friend]OpenStorageEx(&this, pwcsName, grfMode, stgfmt, grfAttrs, riid, ppstgOpen);
}

[CRepr]struct IUrlMon : IUnknown
{
	public new const Guid IID = .(0x00000026, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, PWSTR pszTYPE, PWSTR pszExt, uint32 dwFileVersionMS, uint32 dwFileVersionLS, PWSTR pszCodeBase, IBindCtx* pbc, uint32 dwClassContext, in Guid riid, uint32 flags) AsyncGetClassBits;
	}


	public HRESULT AsyncGetClassBits(in Guid rclsid, PWSTR pszTYPE, PWSTR pszExt, uint32 dwFileVersionMS, uint32 dwFileVersionLS, PWSTR pszCodeBase, IBindCtx* pbc, uint32 dwClassContext, in Guid riid, uint32 flags) mut => VT.[Friend]AsyncGetClassBits(&this, rclsid, pszTYPE, pszExt, dwFileVersionMS, dwFileVersionLS, pszCodeBase, pbc, dwClassContext, riid, flags);
}

[CRepr]struct IForegroundTransfer : IUnknown
{
	public new const Guid IID = .(0x00000145, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpvReserved) AllowForegroundTransfer;
	}


	public HRESULT AllowForegroundTransfer(void* lpvReserved) mut => VT.[Friend]AllowForegroundTransfer(&this, lpvReserved);
}

[CRepr]struct IProcessLock : IUnknown
{
	public new const Guid IID = .(0x000001d5, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) AddRefOnProcess;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) ReleaseRefOnProcess;
	}


	public uint32 AddRefOnProcess() mut => VT.[Friend]AddRefOnProcess(&this);

	public uint32 ReleaseRefOnProcess() mut => VT.[Friend]ReleaseRefOnProcess(&this);
}

[CRepr]struct ISurrogateService : IUnknown
{
	public new const Guid IID = .(0x000001d4, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidProcessID, IProcessLock* pProcessLock, BOOL* pfApplicationAware) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidApplID, ApplicationType appType) ApplicationLaunch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidApplID) ApplicationFree;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulReserved) CatalogRefresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ShutdownType shutdownType) ProcessShutdown;
	}


	public HRESULT Init(in Guid rguidProcessID, IProcessLock* pProcessLock, BOOL* pfApplicationAware) mut => VT.[Friend]Init(&this, rguidProcessID, pProcessLock, pfApplicationAware);

	public HRESULT ApplicationLaunch(in Guid rguidApplID, ApplicationType appType) mut => VT.[Friend]ApplicationLaunch(&this, rguidApplID, appType);

	public HRESULT ApplicationFree(in Guid rguidApplID) mut => VT.[Friend]ApplicationFree(&this, rguidApplID);

	public HRESULT CatalogRefresh(uint32 ulReserved) mut => VT.[Friend]CatalogRefresh(&this, ulReserved);

	public HRESULT ProcessShutdown(ShutdownType shutdownType) mut => VT.[Friend]ProcessShutdown(&this, shutdownType);
}

[CRepr]struct IInitializeSpy : IUnknown
{
	public new const Guid IID = .(0x00000034, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCoInit, uint32 dwCurThreadAptRefs) PreInitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrCoInit, uint32 dwCoInit, uint32 dwNewThreadAptRefs) PostInitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCurThreadAptRefs) PreUninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwNewThreadAptRefs) PostUninitialize;
	}


	public HRESULT PreInitialize(uint32 dwCoInit, uint32 dwCurThreadAptRefs) mut => VT.[Friend]PreInitialize(&this, dwCoInit, dwCurThreadAptRefs);

	public HRESULT PostInitialize(HRESULT hrCoInit, uint32 dwCoInit, uint32 dwNewThreadAptRefs) mut => VT.[Friend]PostInitialize(&this, hrCoInit, dwCoInit, dwNewThreadAptRefs);

	public HRESULT PreUninitialize(uint32 dwCurThreadAptRefs) mut => VT.[Friend]PreUninitialize(&this, dwCurThreadAptRefs);

	public HRESULT PostUninitialize(uint32 dwNewThreadAptRefs) mut => VT.[Friend]PostUninitialize(&this, dwNewThreadAptRefs);
}

[CRepr]struct IServiceProvider : IUnknown
{
	public new const Guid IID = .(0x6d5140c1, 0x7436, 0x11ce, 0x80, 0x34, 0x00, 0xaa, 0x00, 0x60, 0x09, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidService, in Guid riid, void** ppvObject) QueryService;
	}


	public HRESULT QueryService(in Guid guidService, in Guid riid, void** ppvObject) mut => VT.[Friend]QueryService(&this, guidService, riid, ppvObject);
}

[CRepr]struct IEnumGUID : IUnknown
{
	public new const Guid IID = .(0x0002e000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, Guid* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumGUID** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, Guid* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumGUID** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumCATEGORYINFO : IUnknown
{
	public new const Guid IID = .(0x0002e011, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, CATEGORYINFO* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCATEGORYINFO** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, CATEGORYINFO* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumCATEGORYINFO** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ICatRegister : IUnknown
{
	public new const Guid IID = .(0x0002e012, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCategories, CATEGORYINFO* rgCategoryInfo) RegisterCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCategories, Guid* rgcatid) UnRegisterCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 cCategories, Guid* rgcatid) RegisterClassImplCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 cCategories, Guid* rgcatid) UnRegisterClassImplCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 cCategories, Guid* rgcatid) RegisterClassReqCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 cCategories, Guid* rgcatid) UnRegisterClassReqCategories;
	}


	public HRESULT RegisterCategories(uint32 cCategories, CATEGORYINFO* rgCategoryInfo) mut => VT.[Friend]RegisterCategories(&this, cCategories, rgCategoryInfo);

	public HRESULT UnRegisterCategories(uint32 cCategories, Guid* rgcatid) mut => VT.[Friend]UnRegisterCategories(&this, cCategories, rgcatid);

	public HRESULT RegisterClassImplCategories(in Guid rclsid, uint32 cCategories, Guid* rgcatid) mut => VT.[Friend]RegisterClassImplCategories(&this, rclsid, cCategories, rgcatid);

	public HRESULT UnRegisterClassImplCategories(in Guid rclsid, uint32 cCategories, Guid* rgcatid) mut => VT.[Friend]UnRegisterClassImplCategories(&this, rclsid, cCategories, rgcatid);

	public HRESULT RegisterClassReqCategories(in Guid rclsid, uint32 cCategories, Guid* rgcatid) mut => VT.[Friend]RegisterClassReqCategories(&this, rclsid, cCategories, rgcatid);

	public HRESULT UnRegisterClassReqCategories(in Guid rclsid, uint32 cCategories, Guid* rgcatid) mut => VT.[Friend]UnRegisterClassReqCategories(&this, rclsid, cCategories, rgcatid);
}

[CRepr]struct ICatInformation : IUnknown
{
	public new const Guid IID = .(0x0002e013, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid, IEnumCATEGORYINFO** ppenumCategoryInfo) EnumCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* rcatid, uint32 lcid, PWSTR* pszDesc) GetCategoryDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cImplemented, Guid* rgcatidImpl, uint32 cRequired, Guid* rgcatidReq, IEnumGUID** ppenumClsid) EnumClassesOfCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 cImplemented, Guid* rgcatidImpl, uint32 cRequired, Guid* rgcatidReq) IsClassOfCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, IEnumGUID** ppenumCatid) EnumImplCategoriesOfClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, IEnumGUID** ppenumCatid) EnumReqCategoriesOfClass;
	}


	public HRESULT EnumCategories(uint32 lcid, IEnumCATEGORYINFO** ppenumCategoryInfo) mut => VT.[Friend]EnumCategories(&this, lcid, ppenumCategoryInfo);

	public HRESULT GetCategoryDesc(Guid* rcatid, uint32 lcid, PWSTR* pszDesc) mut => VT.[Friend]GetCategoryDesc(&this, rcatid, lcid, pszDesc);

	public HRESULT EnumClassesOfCategories(uint32 cImplemented, Guid* rgcatidImpl, uint32 cRequired, Guid* rgcatidReq, IEnumGUID** ppenumClsid) mut => VT.[Friend]EnumClassesOfCategories(&this, cImplemented, rgcatidImpl, cRequired, rgcatidReq, ppenumClsid);

	public HRESULT IsClassOfCategories(in Guid rclsid, uint32 cImplemented, Guid* rgcatidImpl, uint32 cRequired, Guid* rgcatidReq) mut => VT.[Friend]IsClassOfCategories(&this, rclsid, cImplemented, rgcatidImpl, cRequired, rgcatidReq);

	public HRESULT EnumImplCategoriesOfClass(in Guid rclsid, IEnumGUID** ppenumCatid) mut => VT.[Friend]EnumImplCategoriesOfClass(&this, rclsid, ppenumCatid);

	public HRESULT EnumReqCategoriesOfClass(in Guid rclsid, IEnumGUID** ppenumCatid) mut => VT.[Friend]EnumReqCategoriesOfClass(&this, rclsid, ppenumCatid);
}

[CRepr]struct IContextCallback : IUnknown
{
	public new const Guid IID = .(0x000001da, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PFNCONTEXTCALL pfnCallback, ComCallData* pParam, in Guid riid, int32 iMethod, IUnknown* pUnk) ContextCallback;
	}


	public HRESULT ContextCallback(PFNCONTEXTCALL pfnCallback, ComCallData* pParam, in Guid riid, int32 iMethod, IUnknown* pUnk) mut => VT.[Friend]ContextCallback(&this, pfnCallback, pParam, riid, iMethod, pUnk);
}

[CRepr]struct IBinding : IUnknown
{
	public new const Guid IID = .(0x79eac9c0, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Suspend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nPriority) SetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnPriority) GetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsidProtocol, uint32* pdwResult, PWSTR* pszResult, uint32* pdwReserved) GetBindResult;
	}


	public HRESULT Abort() mut => VT.[Friend]Abort(&this);

	public HRESULT Suspend() mut => VT.[Friend]Suspend(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT SetPriority(int32 nPriority) mut => VT.[Friend]SetPriority(&this, nPriority);

	public HRESULT GetPriority(int32* pnPriority) mut => VT.[Friend]GetPriority(&this, pnPriority);

	public HRESULT GetBindResult(Guid* pclsidProtocol, uint32* pdwResult, PWSTR* pszResult, uint32* pdwReserved) mut => VT.[Friend]GetBindResult(&this, pclsidProtocol, pdwResult, pszResult, pdwReserved);
}

[CRepr]struct IBindStatusCallback : IUnknown
{
	public new const Guid IID = .(0x79eac9c1, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved, IBinding* pib) OnStartBinding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnPriority) GetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 reserved) OnLowResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulProgress, uint32 ulProgressMax, uint32 ulStatusCode, PWSTR szStatusText) OnProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hresult, PWSTR szError) OnStopBinding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* grfBINDF, BINDINFO* pbindinfo) GetBindInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfBSCF, uint32 dwSize, FORMATETC* pformatetc, STGMEDIUM* pstgmed) OnDataAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk) OnObjectAvailable;
	}


	public HRESULT OnStartBinding(uint32 dwReserved, IBinding* pib) mut => VT.[Friend]OnStartBinding(&this, dwReserved, pib);

	public HRESULT GetPriority(int32* pnPriority) mut => VT.[Friend]GetPriority(&this, pnPriority);

	public HRESULT OnLowResource(uint32 reserved) mut => VT.[Friend]OnLowResource(&this, reserved);

	public HRESULT OnProgress(uint32 ulProgress, uint32 ulProgressMax, uint32 ulStatusCode, PWSTR szStatusText) mut => VT.[Friend]OnProgress(&this, ulProgress, ulProgressMax, ulStatusCode, szStatusText);

	public HRESULT OnStopBinding(HRESULT hresult, PWSTR szError) mut => VT.[Friend]OnStopBinding(&this, hresult, szError);

	public HRESULT GetBindInfo(uint32* grfBINDF, BINDINFO* pbindinfo) mut => VT.[Friend]GetBindInfo(&this, grfBINDF, pbindinfo);

	public HRESULT OnDataAvailable(uint32 grfBSCF, uint32 dwSize, FORMATETC* pformatetc, STGMEDIUM* pstgmed) mut => VT.[Friend]OnDataAvailable(&this, grfBSCF, dwSize, pformatetc, pstgmed);

	public HRESULT OnObjectAvailable(in Guid riid, IUnknown* punk) mut => VT.[Friend]OnObjectAvailable(&this, riid, punk);
}

[CRepr]struct IBindStatusCallbackEx : IBindStatusCallback
{
	public new const Guid IID = .(0xaaa74ef9, 0x8ee7, 0x4659, 0x88, 0xd9, 0xf8, 0xc5, 0x04, 0xda, 0x73, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBindStatusCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* grfBINDF, BINDINFO* pbindinfo, uint32* grfBINDF2, uint32* pdwReserved) GetBindInfoEx;
	}


	public HRESULT GetBindInfoEx(uint32* grfBINDF, BINDINFO* pbindinfo, uint32* grfBINDF2, uint32* pdwReserved) mut => VT.[Friend]GetBindInfoEx(&this, grfBINDF, pbindinfo, grfBINDF2, pdwReserved);
}

[CRepr]struct IAuthenticate : IUnknown
{
	public new const Guid IID = .(0x79eac9d0, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd, PWSTR* pszUsername, PWSTR* pszPassword) Authenticate;
	}


	public HRESULT Authenticate(HWND* phwnd, PWSTR* pszUsername, PWSTR* pszPassword) mut => VT.[Friend]Authenticate(&this, phwnd, pszUsername, pszPassword);
}

[CRepr]struct IAuthenticateEx : IAuthenticate
{
	public new const Guid IID = .(0x2ad1edaf, 0xd83d, 0x48b5, 0x9a, 0xdf, 0x03, 0xdb, 0xe1, 0x9f, 0x53, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAuthenticate.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd, PWSTR* pszUsername, PWSTR* pszPassword, AUTHENTICATEINFO* pauthinfo) AuthenticateEx;
	}


	public HRESULT AuthenticateEx(HWND* phwnd, PWSTR* pszUsername, PWSTR* pszPassword, AUTHENTICATEINFO* pauthinfo) mut => VT.[Friend]AuthenticateEx(&this, phwnd, pszUsername, pszPassword, pauthinfo);
}

[CRepr]struct IUri : IUnknown
{
	public new const Guid IID = .(0xa39ee748, 0x6a27, 0x4817, 0xa6, 0xf2, 0x13, 0x91, 0x4b, 0xef, 0x58, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Uri_PROPERTY uriProp, BSTR* pbstrProperty, uint32 dwFlags) GetPropertyBSTR;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Uri_PROPERTY uriProp, uint32* pcchProperty, uint32 dwFlags) GetPropertyLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Uri_PROPERTY uriProp, uint32* pdwProperty, uint32 dwFlags) GetPropertyDWORD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Uri_PROPERTY uriProp, BOOL* pfHasProperty) HasProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAbsoluteUri) GetAbsoluteUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAuthority) GetAuthority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDisplayString) GetDisplayUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDomain) GetDomain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrExtension) GetExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFragment) GetFragment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrHost) GetHost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPassword) GetPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathAndQuery) GetPathAndQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrQuery) GetQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRawUri) GetRawUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSchemeName) GetSchemeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUserInfo) GetUserInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUserName) GetUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwHostType) GetHostType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPort) GetPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwScheme) GetScheme;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwZone) GetZone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri* pUri, BOOL* pfEqual) IsEqual;
	}


	public HRESULT GetPropertyBSTR(Uri_PROPERTY uriProp, BSTR* pbstrProperty, uint32 dwFlags) mut => VT.[Friend]GetPropertyBSTR(&this, uriProp, pbstrProperty, dwFlags);

	public HRESULT GetPropertyLength(Uri_PROPERTY uriProp, uint32* pcchProperty, uint32 dwFlags) mut => VT.[Friend]GetPropertyLength(&this, uriProp, pcchProperty, dwFlags);

	public HRESULT GetPropertyDWORD(Uri_PROPERTY uriProp, uint32* pdwProperty, uint32 dwFlags) mut => VT.[Friend]GetPropertyDWORD(&this, uriProp, pdwProperty, dwFlags);

	public HRESULT HasProperty(Uri_PROPERTY uriProp, BOOL* pfHasProperty) mut => VT.[Friend]HasProperty(&this, uriProp, pfHasProperty);

	public HRESULT GetAbsoluteUri(BSTR* pbstrAbsoluteUri) mut => VT.[Friend]GetAbsoluteUri(&this, pbstrAbsoluteUri);

	public HRESULT GetAuthority(BSTR* pbstrAuthority) mut => VT.[Friend]GetAuthority(&this, pbstrAuthority);

	public HRESULT GetDisplayUri(BSTR* pbstrDisplayString) mut => VT.[Friend]GetDisplayUri(&this, pbstrDisplayString);

	public HRESULT GetDomain(BSTR* pbstrDomain) mut => VT.[Friend]GetDomain(&this, pbstrDomain);

	public HRESULT GetExtension(BSTR* pbstrExtension) mut => VT.[Friend]GetExtension(&this, pbstrExtension);

	public HRESULT GetFragment(BSTR* pbstrFragment) mut => VT.[Friend]GetFragment(&this, pbstrFragment);

	public HRESULT GetHost(BSTR* pbstrHost) mut => VT.[Friend]GetHost(&this, pbstrHost);

	public HRESULT GetPassword(BSTR* pbstrPassword) mut => VT.[Friend]GetPassword(&this, pbstrPassword);

	public HRESULT GetPath(BSTR* pbstrPath) mut => VT.[Friend]GetPath(&this, pbstrPath);

	public HRESULT GetPathAndQuery(BSTR* pbstrPathAndQuery) mut => VT.[Friend]GetPathAndQuery(&this, pbstrPathAndQuery);

	public HRESULT GetQuery(BSTR* pbstrQuery) mut => VT.[Friend]GetQuery(&this, pbstrQuery);

	public HRESULT GetRawUri(BSTR* pbstrRawUri) mut => VT.[Friend]GetRawUri(&this, pbstrRawUri);

	public HRESULT GetSchemeName(BSTR* pbstrSchemeName) mut => VT.[Friend]GetSchemeName(&this, pbstrSchemeName);

	public HRESULT GetUserInfo(BSTR* pbstrUserInfo) mut => VT.[Friend]GetUserInfo(&this, pbstrUserInfo);

	public HRESULT GetUserName(BSTR* pbstrUserName) mut => VT.[Friend]GetUserName(&this, pbstrUserName);

	public HRESULT GetHostType(uint32* pdwHostType) mut => VT.[Friend]GetHostType(&this, pdwHostType);

	public HRESULT GetPort(uint32* pdwPort) mut => VT.[Friend]GetPort(&this, pdwPort);

	public HRESULT GetScheme(uint32* pdwScheme) mut => VT.[Friend]GetScheme(&this, pdwScheme);

	public HRESULT GetZone(uint32* pdwZone) mut => VT.[Friend]GetZone(&this, pdwZone);

	public HRESULT GetProperties(uint32* pdwFlags) mut => VT.[Friend]GetProperties(&this, pdwFlags);

	public HRESULT IsEqual(IUri* pUri, BOOL* pfEqual) mut => VT.[Friend]IsEqual(&this, pUri, pfEqual);
}

[CRepr]struct IUriBuilder : IUnknown
{
	public new const Guid IID = .(0x4221b2e1, 0x8955, 0x46c0, 0xbd, 0x5b, 0xde, 0x98, 0x97, 0x56, 0x5d, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAllowEncodingPropertyMask, uint dwReserved, IUri** ppIUri) CreateUriSimple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCreateFlags, uint32 dwAllowEncodingPropertyMask, uint dwReserved, IUri** ppIUri) CreateUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCreateFlags, uint32 dwUriBuilderFlags, uint32 dwAllowEncodingPropertyMask, uint dwReserved, IUri** ppIUri) CreateUriWithFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri** ppIUri) GetIUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri* pIUri) SetIUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchFragment, PWSTR* ppwzFragment) GetFragment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchHost, PWSTR* ppwzHost) GetHost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchPassword, PWSTR* ppwzPassword) GetPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchPath, PWSTR* ppwzPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfHasPort, uint32* pdwPort) GetPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchQuery, PWSTR* ppwzQuery) GetQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchSchemeName, PWSTR* ppwzSchemeName) GetSchemeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchUserName, PWSTR* ppwzUserName) GetUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetFragment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetHost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fHasPort, uint32 dwNewValue) SetPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetSchemeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzNewValue) SetUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwPropertyMask) RemoveProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfModified) HasBeenModified;
	}


	public HRESULT CreateUriSimple(uint32 dwAllowEncodingPropertyMask, uint dwReserved, IUri** ppIUri) mut => VT.[Friend]CreateUriSimple(&this, dwAllowEncodingPropertyMask, dwReserved, ppIUri);

	public HRESULT CreateUri(uint32 dwCreateFlags, uint32 dwAllowEncodingPropertyMask, uint dwReserved, IUri** ppIUri) mut => VT.[Friend]CreateUri(&this, dwCreateFlags, dwAllowEncodingPropertyMask, dwReserved, ppIUri);

	public HRESULT CreateUriWithFlags(uint32 dwCreateFlags, uint32 dwUriBuilderFlags, uint32 dwAllowEncodingPropertyMask, uint dwReserved, IUri** ppIUri) mut => VT.[Friend]CreateUriWithFlags(&this, dwCreateFlags, dwUriBuilderFlags, dwAllowEncodingPropertyMask, dwReserved, ppIUri);

	public HRESULT GetIUri(IUri** ppIUri) mut => VT.[Friend]GetIUri(&this, ppIUri);

	public HRESULT SetIUri(IUri* pIUri) mut => VT.[Friend]SetIUri(&this, pIUri);

	public HRESULT GetFragment(uint32* pcchFragment, PWSTR* ppwzFragment) mut => VT.[Friend]GetFragment(&this, pcchFragment, ppwzFragment);

	public HRESULT GetHost(uint32* pcchHost, PWSTR* ppwzHost) mut => VT.[Friend]GetHost(&this, pcchHost, ppwzHost);

	public HRESULT GetPassword(uint32* pcchPassword, PWSTR* ppwzPassword) mut => VT.[Friend]GetPassword(&this, pcchPassword, ppwzPassword);

	public HRESULT GetPath(uint32* pcchPath, PWSTR* ppwzPath) mut => VT.[Friend]GetPath(&this, pcchPath, ppwzPath);

	public HRESULT GetPort(BOOL* pfHasPort, uint32* pdwPort) mut => VT.[Friend]GetPort(&this, pfHasPort, pdwPort);

	public HRESULT GetQuery(uint32* pcchQuery, PWSTR* ppwzQuery) mut => VT.[Friend]GetQuery(&this, pcchQuery, ppwzQuery);

	public HRESULT GetSchemeName(uint32* pcchSchemeName, PWSTR* ppwzSchemeName) mut => VT.[Friend]GetSchemeName(&this, pcchSchemeName, ppwzSchemeName);

	public HRESULT GetUserName(uint32* pcchUserName, PWSTR* ppwzUserName) mut => VT.[Friend]GetUserName(&this, pcchUserName, ppwzUserName);

	public HRESULT SetFragment(PWSTR pwzNewValue) mut => VT.[Friend]SetFragment(&this, pwzNewValue);

	public HRESULT SetHost(PWSTR pwzNewValue) mut => VT.[Friend]SetHost(&this, pwzNewValue);

	public HRESULT SetPassword(PWSTR pwzNewValue) mut => VT.[Friend]SetPassword(&this, pwzNewValue);

	public HRESULT SetPath(PWSTR pwzNewValue) mut => VT.[Friend]SetPath(&this, pwzNewValue);

	public HRESULT SetPort(BOOL fHasPort, uint32 dwNewValue) mut => VT.[Friend]SetPort(&this, fHasPort, dwNewValue);

	public HRESULT SetQuery(PWSTR pwzNewValue) mut => VT.[Friend]SetQuery(&this, pwzNewValue);

	public HRESULT SetSchemeName(PWSTR pwzNewValue) mut => VT.[Friend]SetSchemeName(&this, pwzNewValue);

	public HRESULT SetUserName(PWSTR pwzNewValue) mut => VT.[Friend]SetUserName(&this, pwzNewValue);

	public HRESULT RemoveProperties(uint32 dwPropertyMask) mut => VT.[Friend]RemoveProperties(&this, dwPropertyMask);

	public HRESULT HasBeenModified(BOOL* pfModified) mut => VT.[Friend]HasBeenModified(&this, pfModified);
}

[CRepr]struct IBindHost : IUnknown
{
	public new const Guid IID = .(0xfc4801a1, 0x2ba9, 0x11cf, 0xa2, 0x29, 0x00, 0xaa, 0x00, 0x3d, 0x73, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName, IBindCtx* pBC, IMoniker** ppmk, uint32 dwReserved) CreateMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pMk, IBindCtx* pBC, IBindStatusCallback* pBSC, in Guid riid, void** ppvObj) MonikerBindToStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pMk, IBindCtx* pBC, IBindStatusCallback* pBSC, in Guid riid, void** ppvObj) MonikerBindToObject;
	}


	public HRESULT CreateMoniker(PWSTR szName, IBindCtx* pBC, IMoniker** ppmk, uint32 dwReserved) mut => VT.[Friend]CreateMoniker(&this, szName, pBC, ppmk, dwReserved);

	public HRESULT MonikerBindToStorage(IMoniker* pMk, IBindCtx* pBC, IBindStatusCallback* pBSC, in Guid riid, void** ppvObj) mut => VT.[Friend]MonikerBindToStorage(&this, pMk, pBC, pBSC, riid, ppvObj);

	public HRESULT MonikerBindToObject(IMoniker* pMk, IBindCtx* pBC, IBindStatusCallback* pBSC, in Guid riid, void** ppvObj) mut => VT.[Friend]MonikerBindToObject(&this, pMk, pBC, pBSC, riid, ppvObj);
}

[CRepr]struct IDispatch : IUnknown
{
	public new const Guid IID = .(0x00020400, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pctinfo) GetTypeInfoCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iTInfo, uint32 lcid, ITypeInfo** ppTInfo) GetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, PWSTR* rgszNames, uint32 cNames, uint32 lcid, int32* rgDispId) GetIDsOfNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispIdMember, in Guid riid, uint32 lcid, DISPATCH_FLAGS wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint32* puArgErr) Invoke;
	}


	public HRESULT GetTypeInfoCount(uint32* pctinfo) mut => VT.[Friend]GetTypeInfoCount(&this, pctinfo);

	public HRESULT GetTypeInfo(uint32 iTInfo, uint32 lcid, ITypeInfo** ppTInfo) mut => VT.[Friend]GetTypeInfo(&this, iTInfo, lcid, ppTInfo);

	public HRESULT GetIDsOfNames(in Guid riid, PWSTR* rgszNames, uint32 cNames, uint32 lcid, int32* rgDispId) mut => VT.[Friend]GetIDsOfNames(&this, riid, rgszNames, cNames, lcid, rgDispId);

	public HRESULT Invoke(int32 dispIdMember, in Guid riid, uint32 lcid, DISPATCH_FLAGS wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint32* puArgErr) mut => VT.[Friend]Invoke(&this, dispIdMember, riid, lcid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr);
}

[CRepr]struct ITypeComp : IUnknown
{
	public new const Guid IID = .(0x00020403, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName, uint32 lHashVal, uint16 wFlags, ITypeInfo** ppTInfo, DESCKIND* pDescKind, BINDPTR* pBindPtr) Bind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szName, uint32 lHashVal, ITypeInfo** ppTInfo, ITypeComp** ppTComp) BindType;
	}


	public HRESULT Bind(PWSTR szName, uint32 lHashVal, uint16 wFlags, ITypeInfo** ppTInfo, DESCKIND* pDescKind, BINDPTR* pBindPtr) mut => VT.[Friend]Bind(&this, szName, lHashVal, wFlags, ppTInfo, pDescKind, pBindPtr);

	public HRESULT BindType(PWSTR szName, uint32 lHashVal, ITypeInfo** ppTInfo, ITypeComp** ppTComp) mut => VT.[Friend]BindType(&this, szName, lHashVal, ppTInfo, ppTComp);
}

[CRepr]struct ITypeInfo : IUnknown
{
	public new const Guid IID = .(0x00020401, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TYPEATTR** ppTypeAttr) GetTypeAttr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeComp** ppTComp) GetTypeComp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, FUNCDESC** ppFuncDesc) GetFuncDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, VARDESC** ppVarDesc) GetVarDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, BSTR* rgBstrNames, uint32 cMaxNames, uint32* pcNames) GetNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, uint32* pRefType) GetRefTypeOfImplType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, int32* pImplTypeFlags) GetImplTypeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* rgszNames, uint32 cNames, int32* pMemId) GetIDsOfNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvInstance, int32 memid, DISPATCH_FLAGS wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint32* puArgErr) Invoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, BSTR* pBstrName, BSTR* pBstrDocString, uint32* pdwHelpContext, BSTR* pBstrHelpFile) GetDocumentation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, INVOKEKIND invKind, BSTR* pBstrDllName, BSTR* pBstrName, uint16* pwOrdinal) GetDllEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hRefType, ITypeInfo** ppTInfo) GetRefTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, INVOKEKIND invKind, void** ppv) AddressOfMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkOuter, in Guid riid, void** ppvObj) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, BSTR* pBstrMops) GetMops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeLib** ppTLib, uint32* pIndex) GetContainingTypeLib;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, TYPEATTR* pTypeAttr) ReleaseTypeAttr;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, FUNCDESC* pFuncDesc) ReleaseFuncDesc;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, VARDESC* pVarDesc) ReleaseVarDesc;
	}


	public HRESULT GetTypeAttr(TYPEATTR** ppTypeAttr) mut => VT.[Friend]GetTypeAttr(&this, ppTypeAttr);

	public HRESULT GetTypeComp(ITypeComp** ppTComp) mut => VT.[Friend]GetTypeComp(&this, ppTComp);

	public HRESULT GetFuncDesc(uint32 index, FUNCDESC** ppFuncDesc) mut => VT.[Friend]GetFuncDesc(&this, index, ppFuncDesc);

	public HRESULT GetVarDesc(uint32 index, VARDESC** ppVarDesc) mut => VT.[Friend]GetVarDesc(&this, index, ppVarDesc);

	public HRESULT GetNames(int32 memid, BSTR* rgBstrNames, uint32 cMaxNames, uint32* pcNames) mut => VT.[Friend]GetNames(&this, memid, rgBstrNames, cMaxNames, pcNames);

	public HRESULT GetRefTypeOfImplType(uint32 index, uint32* pRefType) mut => VT.[Friend]GetRefTypeOfImplType(&this, index, pRefType);

	public HRESULT GetImplTypeFlags(uint32 index, int32* pImplTypeFlags) mut => VT.[Friend]GetImplTypeFlags(&this, index, pImplTypeFlags);

	public HRESULT GetIDsOfNames(PWSTR* rgszNames, uint32 cNames, int32* pMemId) mut => VT.[Friend]GetIDsOfNames(&this, rgszNames, cNames, pMemId);

	public HRESULT Invoke(void* pvInstance, int32 memid, DISPATCH_FLAGS wFlags, DISPPARAMS* pDispParams, VARIANT* pVarResult, EXCEPINFO* pExcepInfo, uint32* puArgErr) mut => VT.[Friend]Invoke(&this, pvInstance, memid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr);

	public HRESULT GetDocumentation(int32 memid, BSTR* pBstrName, BSTR* pBstrDocString, uint32* pdwHelpContext, BSTR* pBstrHelpFile) mut => VT.[Friend]GetDocumentation(&this, memid, pBstrName, pBstrDocString, pdwHelpContext, pBstrHelpFile);

	public HRESULT GetDllEntry(int32 memid, INVOKEKIND invKind, BSTR* pBstrDllName, BSTR* pBstrName, uint16* pwOrdinal) mut => VT.[Friend]GetDllEntry(&this, memid, invKind, pBstrDllName, pBstrName, pwOrdinal);

	public HRESULT GetRefTypeInfo(uint32 hRefType, ITypeInfo** ppTInfo) mut => VT.[Friend]GetRefTypeInfo(&this, hRefType, ppTInfo);

	public HRESULT AddressOfMember(int32 memid, INVOKEKIND invKind, void** ppv) mut => VT.[Friend]AddressOfMember(&this, memid, invKind, ppv);

	public HRESULT CreateInstance(IUnknown* pUnkOuter, in Guid riid, void** ppvObj) mut => VT.[Friend]CreateInstance(&this, pUnkOuter, riid, ppvObj);

	public HRESULT GetMops(int32 memid, BSTR* pBstrMops) mut => VT.[Friend]GetMops(&this, memid, pBstrMops);

	public HRESULT GetContainingTypeLib(ITypeLib** ppTLib, uint32* pIndex) mut => VT.[Friend]GetContainingTypeLib(&this, ppTLib, pIndex);

	public void ReleaseTypeAttr(TYPEATTR* pTypeAttr) mut => VT.[Friend]ReleaseTypeAttr(&this, pTypeAttr);

	public void ReleaseFuncDesc(FUNCDESC* pFuncDesc) mut => VT.[Friend]ReleaseFuncDesc(&this, pFuncDesc);

	public void ReleaseVarDesc(VARDESC* pVarDesc) mut => VT.[Friend]ReleaseVarDesc(&this, pVarDesc);
}

[CRepr]struct ITypeInfo2 : ITypeInfo
{
	public new const Guid IID = .(0x00020412, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITypeInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TYPEKIND* pTypeKind) GetTypeKind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pTypeFlags) GetTypeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, INVOKEKIND invKind, uint32* pFuncIndex) GetFuncIndexOfMemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, uint32* pVarIndex) GetVarIndexOfMemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, VARIANT* pVarVal) GetCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid guid, VARIANT* pVarVal) GetFuncCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 indexFunc, uint32 indexParam, in Guid guid, VARIANT* pVarVal) GetParamCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid guid, VARIANT* pVarVal) GetVarCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, in Guid guid, VARIANT* pVarVal) GetImplTypeCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 memid, uint32 lcid, BSTR* pbstrHelpString, uint32* pdwHelpStringContext, BSTR* pbstrHelpStringDll) GetDocumentation2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CUSTDATA* pCustData) GetAllCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, CUSTDATA* pCustData) GetAllFuncCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 indexFunc, uint32 indexParam, CUSTDATA* pCustData) GetAllParamCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, CUSTDATA* pCustData) GetAllVarCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, CUSTDATA* pCustData) GetAllImplTypeCustData;
	}


	public HRESULT GetTypeKind(TYPEKIND* pTypeKind) mut => VT.[Friend]GetTypeKind(&this, pTypeKind);

	public HRESULT GetTypeFlags(uint32* pTypeFlags) mut => VT.[Friend]GetTypeFlags(&this, pTypeFlags);

	public HRESULT GetFuncIndexOfMemId(int32 memid, INVOKEKIND invKind, uint32* pFuncIndex) mut => VT.[Friend]GetFuncIndexOfMemId(&this, memid, invKind, pFuncIndex);

	public HRESULT GetVarIndexOfMemId(int32 memid, uint32* pVarIndex) mut => VT.[Friend]GetVarIndexOfMemId(&this, memid, pVarIndex);

	public HRESULT GetCustData(in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]GetCustData(&this, guid, pVarVal);

	public HRESULT GetFuncCustData(uint32 index, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]GetFuncCustData(&this, index, guid, pVarVal);

	public HRESULT GetParamCustData(uint32 indexFunc, uint32 indexParam, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]GetParamCustData(&this, indexFunc, indexParam, guid, pVarVal);

	public HRESULT GetVarCustData(uint32 index, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]GetVarCustData(&this, index, guid, pVarVal);

	public HRESULT GetImplTypeCustData(uint32 index, in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]GetImplTypeCustData(&this, index, guid, pVarVal);

	public HRESULT GetDocumentation2(int32 memid, uint32 lcid, BSTR* pbstrHelpString, uint32* pdwHelpStringContext, BSTR* pbstrHelpStringDll) mut => VT.[Friend]GetDocumentation2(&this, memid, lcid, pbstrHelpString, pdwHelpStringContext, pbstrHelpStringDll);

	public HRESULT GetAllCustData(CUSTDATA* pCustData) mut => VT.[Friend]GetAllCustData(&this, pCustData);

	public HRESULT GetAllFuncCustData(uint32 index, CUSTDATA* pCustData) mut => VT.[Friend]GetAllFuncCustData(&this, index, pCustData);

	public HRESULT GetAllParamCustData(uint32 indexFunc, uint32 indexParam, CUSTDATA* pCustData) mut => VT.[Friend]GetAllParamCustData(&this, indexFunc, indexParam, pCustData);

	public HRESULT GetAllVarCustData(uint32 index, CUSTDATA* pCustData) mut => VT.[Friend]GetAllVarCustData(&this, index, pCustData);

	public HRESULT GetAllImplTypeCustData(uint32 index, CUSTDATA* pCustData) mut => VT.[Friend]GetAllImplTypeCustData(&this, index, pCustData);
}

[CRepr]struct ITypeLib : IUnknown
{
	public new const Guid IID = .(0x00020402, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetTypeInfoCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, ITypeInfo** ppTInfo) GetTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, TYPEKIND* pTKind) GetTypeInfoType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, ITypeInfo** ppTinfo) GetTypeInfoOfGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TLIBATTR** ppTLibAttr) GetLibAttr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITypeComp** ppTComp) GetTypeComp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, BSTR* pBstrName, BSTR* pBstrDocString, uint32* pdwHelpContext, BSTR* pBstrHelpFile) GetDocumentation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szNameBuf, uint32 lHashVal, BOOL* pfName) IsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szNameBuf, uint32 lHashVal, ITypeInfo** ppTInfo, int32* rgMemId, uint16* pcFound) FindName;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, TLIBATTR* pTLibAttr) ReleaseTLibAttr;
	}


	public uint32 GetTypeInfoCount() mut => VT.[Friend]GetTypeInfoCount(&this);

	public HRESULT GetTypeInfo(uint32 index, ITypeInfo** ppTInfo) mut => VT.[Friend]GetTypeInfo(&this, index, ppTInfo);

	public HRESULT GetTypeInfoType(uint32 index, TYPEKIND* pTKind) mut => VT.[Friend]GetTypeInfoType(&this, index, pTKind);

	public HRESULT GetTypeInfoOfGuid(in Guid guid, ITypeInfo** ppTinfo) mut => VT.[Friend]GetTypeInfoOfGuid(&this, guid, ppTinfo);

	public HRESULT GetLibAttr(TLIBATTR** ppTLibAttr) mut => VT.[Friend]GetLibAttr(&this, ppTLibAttr);

	public HRESULT GetTypeComp(ITypeComp** ppTComp) mut => VT.[Friend]GetTypeComp(&this, ppTComp);

	public HRESULT GetDocumentation(int32 index, BSTR* pBstrName, BSTR* pBstrDocString, uint32* pdwHelpContext, BSTR* pBstrHelpFile) mut => VT.[Friend]GetDocumentation(&this, index, pBstrName, pBstrDocString, pdwHelpContext, pBstrHelpFile);

	public HRESULT IsName(PWSTR szNameBuf, uint32 lHashVal, BOOL* pfName) mut => VT.[Friend]IsName(&this, szNameBuf, lHashVal, pfName);

	public HRESULT FindName(PWSTR szNameBuf, uint32 lHashVal, ITypeInfo** ppTInfo, int32* rgMemId, uint16* pcFound) mut => VT.[Friend]FindName(&this, szNameBuf, lHashVal, ppTInfo, rgMemId, pcFound);

	public void ReleaseTLibAttr(TLIBATTR* pTLibAttr) mut => VT.[Friend]ReleaseTLibAttr(&this, pTLibAttr);
}

[CRepr]struct ITypeLib2 : ITypeLib
{
	public new const Guid IID = .(0x00020411, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITypeLib.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, VARIANT* pVarVal) GetCustData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcUniqueNames, uint32* pcchUniqueNames) GetLibStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, uint32 lcid, BSTR* pbstrHelpString, uint32* pdwHelpStringContext, BSTR* pbstrHelpStringDll) GetDocumentation2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CUSTDATA* pCustData) GetAllCustData;
	}


	public HRESULT GetCustData(in Guid guid, VARIANT* pVarVal) mut => VT.[Friend]GetCustData(&this, guid, pVarVal);

	public HRESULT GetLibStatistics(uint32* pcUniqueNames, uint32* pcchUniqueNames) mut => VT.[Friend]GetLibStatistics(&this, pcUniqueNames, pcchUniqueNames);

	public HRESULT GetDocumentation2(int32 index, uint32 lcid, BSTR* pbstrHelpString, uint32* pdwHelpStringContext, BSTR* pbstrHelpStringDll) mut => VT.[Friend]GetDocumentation2(&this, index, lcid, pbstrHelpString, pdwHelpStringContext, pbstrHelpStringDll);

	public HRESULT GetAllCustData(CUSTDATA* pCustData) mut => VT.[Friend]GetAllCustData(&this, pCustData);
}

[CRepr]struct IErrorInfo : IUnknown
{
	public new const Guid IID = .(0x1cf2b120, 0x547d, 0x101b, 0x8e, 0x65, 0x08, 0x00, 0x2b, 0x2b, 0xd1, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGUID) GetGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstrSource) GetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstrDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pBstrHelpFile) GetHelpFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwHelpContext) GetHelpContext;
	}


	public HRESULT GetGUID(Guid* pGUID) mut => VT.[Friend]GetGUID(&this, pGUID);

	public HRESULT GetSource(BSTR* pBstrSource) mut => VT.[Friend]GetSource(&this, pBstrSource);

	public HRESULT GetDescription(BSTR* pBstrDescription) mut => VT.[Friend]GetDescription(&this, pBstrDescription);

	public HRESULT GetHelpFile(BSTR* pBstrHelpFile) mut => VT.[Friend]GetHelpFile(&this, pBstrHelpFile);

	public HRESULT GetHelpContext(uint32* pdwHelpContext) mut => VT.[Friend]GetHelpContext(&this, pdwHelpContext);
}

[CRepr]struct ISupportErrorInfo : IUnknown
{
	public new const Guid IID = .(0xdf0b3d60, 0x548f, 0x101b, 0x8e, 0x65, 0x08, 0x00, 0x2b, 0x2b, 0xd1, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid) InterfaceSupportsErrorInfo;
	}


	public HRESULT InterfaceSupportsErrorInfo(in Guid riid) mut => VT.[Friend]InterfaceSupportsErrorInfo(&this, riid);
}

[CRepr]struct IErrorLog : IUnknown
{
	public new const Guid IID = .(0x3127ca40, 0x446e, 0x11ce, 0x81, 0x35, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropName, EXCEPINFO* pExcepInfo) AddError;
	}


	public HRESULT AddError(PWSTR pszPropName, EXCEPINFO* pExcepInfo) mut => VT.[Friend]AddError(&this, pszPropName, pExcepInfo);
}

[CRepr]struct ITypeLibRegistrationReader : IUnknown
{
	public new const Guid IID = .(0xed6a8a2a, 0xb160, 0x4e77, 0x8f, 0x73, 0xaa, 0x74, 0x35, 0xcd, 0x5c, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** ppEnumUnknown) EnumTypeLibRegistrations;
	}


	public HRESULT EnumTypeLibRegistrations(IEnumUnknown** ppEnumUnknown) mut => VT.[Friend]EnumTypeLibRegistrations(&this, ppEnumUnknown);
}

[CRepr]struct ITypeLibRegistration : IUnknown
{
	public new const Guid IID = .(0x76a3e735, 0x02df, 0x4a12, 0x98, 0xeb, 0x04, 0x3a, 0xd3, 0x60, 0x0a, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVersion) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLcid) GetLcid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pWin32Path) GetWin32Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pWin64Path) GetWin64Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pDisplayName) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pHelpDir) GetHelpDir;
	}


	public HRESULT GetGuid(Guid* pGuid) mut => VT.[Friend]GetGuid(&this, pGuid);

	public HRESULT GetVersion(BSTR* pVersion) mut => VT.[Friend]GetVersion(&this, pVersion);

	public HRESULT GetLcid(uint32* pLcid) mut => VT.[Friend]GetLcid(&this, pLcid);

	public HRESULT GetWin32Path(BSTR* pWin32Path) mut => VT.[Friend]GetWin32Path(&this, pWin32Path);

	public HRESULT GetWin64Path(BSTR* pWin64Path) mut => VT.[Friend]GetWin64Path(&this, pWin64Path);

	public HRESULT GetDisplayName(BSTR* pDisplayName) mut => VT.[Friend]GetDisplayName(&this, pDisplayName);

	public HRESULT GetFlags(uint32* pFlags) mut => VT.[Friend]COM_GetFlags(&this, pFlags);

	public HRESULT GetHelpDir(BSTR* pHelpDir) mut => VT.[Friend]GetHelpDir(&this, pHelpDir);
}

[CRepr]struct IEnumConnections : IUnknown
{
	public new const Guid IID = .(0xb196b287, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cConnections, CONNECTDATA* rgcd, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cConnections) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumConnections** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cConnections, CONNECTDATA* rgcd, uint32* pcFetched) mut => VT.[Friend]Next(&this, cConnections, rgcd, pcFetched);

	public HRESULT Skip(uint32 cConnections) mut => VT.[Friend]Skip(&this, cConnections);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumConnections** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IConnectionPoint : IUnknown
{
	public new const Guid IID = .(0xb196b286, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pIID) GetConnectionInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConnectionPointContainer** ppCPC) GetConnectionPointContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkSink, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumConnections** ppEnum) EnumConnections;
	}


	public HRESULT GetConnectionInterface(Guid* pIID) mut => VT.[Friend]GetConnectionInterface(&this, pIID);

	public HRESULT GetConnectionPointContainer(IConnectionPointContainer** ppCPC) mut => VT.[Friend]GetConnectionPointContainer(&this, ppCPC);

	public HRESULT Advise(IUnknown* pUnkSink, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, pUnkSink, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT EnumConnections(IEnumConnections** ppEnum) mut => VT.[Friend]EnumConnections(&this, ppEnum);
}

[CRepr]struct IEnumConnectionPoints : IUnknown
{
	public new const Guid IID = .(0xb196b285, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cConnections, IConnectionPoint** ppCP, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cConnections) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumConnectionPoints** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cConnections, IConnectionPoint** ppCP, uint32* pcFetched) mut => VT.[Friend]Next(&this, cConnections, ppCP, pcFetched);

	public HRESULT Skip(uint32 cConnections) mut => VT.[Friend]Skip(&this, cConnections);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumConnectionPoints** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IConnectionPointContainer : IUnknown
{
	public new const Guid IID = .(0xb196b284, 0xbab4, 0x101a, 0xb6, 0x9c, 0x00, 0xaa, 0x00, 0x34, 0x1d, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumConnectionPoints** ppEnum) EnumConnectionPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IConnectionPoint** ppCP) FindConnectionPoint;
	}


	public HRESULT EnumConnectionPoints(IEnumConnectionPoints** ppEnum) mut => VT.[Friend]EnumConnectionPoints(&this, ppEnum);

	public HRESULT FindConnectionPoint(in Guid riid, IConnectionPoint** ppCP) mut => VT.[Friend]FindConnectionPoint(&this, riid, ppCP);
}

[CRepr]struct IPersistMemory : IPersist
{
	public new const Guid IID = .(0xbd1ae5e0, 0xa6ae, 0x11ce, 0xbd, 0x37, 0x50, 0x42, 0x00, 0xc1, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pMem, uint32 cbSize) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pMem, BOOL fClearDirty, uint32 cbSize) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCbSize) GetSizeMax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitNew;
	}


	public HRESULT IsDirty() mut => VT.[Friend]IsDirty(&this);

	public HRESULT Load(void* pMem, uint32 cbSize) mut => VT.[Friend]Load(&this, pMem, cbSize);

	public HRESULT Save(void* pMem, BOOL fClearDirty, uint32 cbSize) mut => VT.[Friend]Save(&this, pMem, fClearDirty, cbSize);

	public HRESULT GetSizeMax(uint32* pCbSize) mut => VT.[Friend]GetSizeMax(&this, pCbSize);

	public HRESULT InitNew() mut => VT.[Friend]InitNew(&this);
}

[CRepr]struct IPersistStreamInit : IPersist
{
	public new const Guid IID = .(0x7fd52380, 0x4e07, 0x101b, 0xae, 0x2d, 0x08, 0x00, 0x2b, 0x2e, 0xc7, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStm) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStm, BOOL fClearDirty) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER* pCbSize) GetSizeMax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitNew;
	}


	public HRESULT IsDirty() mut => VT.[Friend]IsDirty(&this);

	public HRESULT Load(IStream* pStm) mut => VT.[Friend]Load(&this, pStm);

	public HRESULT Save(IStream* pStm, BOOL fClearDirty) mut => VT.[Friend]Save(&this, pStm, fClearDirty);

	public HRESULT GetSizeMax(ULARGE_INTEGER* pCbSize) mut => VT.[Friend]GetSizeMax(&this, pCbSize);

	public HRESULT InitNew() mut => VT.[Friend]InitNew(&this);
}

#endregion

#region Functions
public static
{
	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CoBuildVersion();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoInitialize(void* pvReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterMallocSpy(IMallocSpy* pMallocSpy);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRevokeMallocSpy();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterInitializeSpy(IInitializeSpy* pSpy, ULARGE_INTEGER* puliCookie);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRevokeInitializeSpy(ULARGE_INTEGER uliCookie);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetSystemSecurityPermissions(COMSD comSDType, PSECURITY_DESCRIPTOR* ppSD);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE CoLoadLibrary(PWSTR lpszLibName, BOOL bAutoFree);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoFreeLibrary(HINSTANCE hInst);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoFreeAllLibraries();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoAllowSetForegroundWindow(IUnknown* pUnk, void* lpvReserved);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DcomChannelSetHResult(void* pvReserved, uint32* pulReserved, HRESULT appsHR);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CoIsOle1Class(in Guid rclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CLSIDFromProgIDEx(PWSTR lpszProgID, Guid* lpclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CoFileTimeToDosDateTime(FILETIME* lpFileTime, uint16* lpDosDate, uint16* lpDosTime);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CoDosDateTimeToFileTime(uint16 nDosDate, uint16 nDosTime, FILETIME* lpFileTime);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoFileTimeNow(FILETIME* lpFileTime);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterChannelHook(in Guid ExtensionUuid, IChannelHook* pChannelHook);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoTreatAsClass(in Guid clsidOld, in Guid clsidNew);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDataAdviseHolder(IDataAdviseHolder** ppDAHolder);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDataCache(IUnknown* pUnkOuter, in Guid rclsid, in Guid iid, void** ppv);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoInstall(IBindCtx* pbc, uint32 dwFlags, uCLSSPEC* pClassSpec, QUERYCONTEXT* pQuery, PWSTR pszCodeBase);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BindMoniker(IMoniker* pmk, uint32 grfOpt, in Guid iidResult, void** ppvResult);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetObject(PWSTR pszName, BIND_OPTS* pBindOptions, in Guid riid, void** ppv);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MkParseDisplayName(IBindCtx* pbc, PWSTR szUserName, uint32* pchEaten, IMoniker** ppmk);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MonikerRelativePathTo(IMoniker* pmkSrc, IMoniker* pmkDest, IMoniker** ppmkRelPath, BOOL dwReserved);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MonikerCommonPrefixWith(IMoniker* pmkThis, IMoniker* pmkOther, IMoniker** ppmkCommon);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateBindCtx(uint32 reserved, IBindCtx** ppbc);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateGenericComposite(IMoniker* pmkFirst, IMoniker* pmkRest, IMoniker** ppmkComposite);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetClassFile(PWSTR szFilename, Guid* pclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateClassMoniker(in Guid rclsid, IMoniker** ppmk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateFileMoniker(PWSTR lpszPathName, IMoniker** ppmk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateItemMoniker(PWSTR lpszDelim, PWSTR lpszItem, IMoniker** ppmk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateAntiMoniker(IMoniker** ppmk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreatePointerMoniker(IUnknown* punk, IMoniker** ppmk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateObjrefMoniker(IUnknown* punk, IMoniker** ppmk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetRunningObjectTable(uint32 reserved, IRunningObjectTable** pprot);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStdProgressIndicator(HWND hwndParent, PWSTR pszTitle, IBindStatusCallback* pIbscCaller, IBindStatusCallback** ppIbsc);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetMalloc(uint32 dwMemContext, IMalloc** ppMalloc);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoUninitialize();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CoGetCurrentProcess();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoInitializeEx(void* pvReserved, COINIT dwCoInit);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetCallerTID(uint32* lpdwTID);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetCurrentLogicalThreadId(Guid* pguid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetContextToken(uint* pToken);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetApartmentType(APTTYPE* pAptType, APTTYPEQUALIFIER* pAptQualifier);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoIncrementMTAUsage(CO_MTA_USAGE_COOKIE* pCookie);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoDecrementMTAUsage(CO_MTA_USAGE_COOKIE Cookie);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoAllowUnmarshalerCLSID(in Guid clsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetObjectContext(in Guid riid, void** ppv);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetClassObject(in Guid rclsid, CLSCTX dwClsContext, void* pvReserved, in Guid riid, void** ppv);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterClassObject(in Guid rclsid, IUnknown* pUnk, CLSCTX dwClsContext, REGCLS flags, uint32* lpdwRegister);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRevokeClassObject(uint32 dwRegister);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoResumeClassObjects();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoSuspendClassObjects();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CoAddRefServerProcess();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CoReleaseServerProcess();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetPSClsid(in Guid riid, Guid* pClsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterPSClsid(in Guid riid, in Guid rclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterSurrogate(ISurrogate* pSurrogate);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoDisconnectObject(IUnknown* pUnk, uint32 dwReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoLockObjectExternal(IUnknown* pUnk, BOOL fLock, BOOL fLastUnlockReleases);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CoIsHandlerConnected(IUnknown* pUnk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCreateFreeThreadedMarshaler(IUnknown* punkOuter, IUnknown** ppunkMarshal);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoFreeUnusedLibraries();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoFreeUnusedLibrariesEx(uint32 dwUnloadDelay, uint32 dwReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoDisconnectContext(uint32 dwTimeout);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoInitializeSecurity(PSECURITY_DESCRIPTOR pSecDesc, int32 cAuthSvc, SOLE_AUTHENTICATION_SERVICE* asAuthSvc, void* pReserved1, RPC_C_AUTHN_LEVEL dwAuthnLevel, RPC_C_IMP_LEVEL dwImpLevel, void* pAuthList, EOLE_AUTHENTICATION_CAPABILITIES dwCapabilities, void* pReserved3);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetCallContext(in Guid riid, void** ppInterface);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoQueryProxyBlanket(IUnknown* pProxy, uint32* pwAuthnSvc, uint32* pAuthzSvc, PWSTR* pServerPrincName, uint32* pAuthnLevel, uint32* pImpLevel, void** pAuthInfo, uint32* pCapabilites);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoSetProxyBlanket(IUnknown* pProxy, uint32 dwAuthnSvc, uint32 dwAuthzSvc, PWSTR pServerPrincName, RPC_C_AUTHN_LEVEL dwAuthnLevel, RPC_C_IMP_LEVEL dwImpLevel, void* pAuthInfo, EOLE_AUTHENTICATION_CAPABILITIES dwCapabilities);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCopyProxy(IUnknown* pProxy, IUnknown** ppCopy);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoQueryClientBlanket(uint32* pAuthnSvc, uint32* pAuthzSvc, PWSTR* pServerPrincName, uint32* pAuthnLevel, uint32* pImpLevel, void** pPrivs, uint32* pCapabilities);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoImpersonateClient();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRevertToSelf();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoQueryAuthenticationServices(uint32* pcAuthSvc, SOLE_AUTHENTICATION_SERVICE** asAuthSvc);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoSwitchCallContext(IUnknown* pNewObject, IUnknown** ppOldObject);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCreateInstance(in Guid rclsid, IUnknown* pUnkOuter, CLSCTX dwClsContext, in Guid riid, void** ppv);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCreateInstanceEx(in Guid Clsid, IUnknown* punkOuter, CLSCTX dwClsCtx, COSERVERINFO* pServerInfo, uint32 dwCount, MULTI_QI* pResults);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCreateInstanceFromApp(in Guid Clsid, IUnknown* punkOuter, CLSCTX dwClsCtx, void* reserved, uint32 dwCount, MULTI_QI* pResults);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterActivationFilter(IActivationFilter* pActivationFilter);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetCancelObject(uint32 dwThreadId, in Guid iid, void** ppUnk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoSetCancelObject(IUnknown* pUnk);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCancelCall(uint32 dwThreadId, uint32 ulTimeout);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoTestCancel();

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoEnableCallCancellation(void* pReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoDisableCallCancellation(void* pReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StringFromCLSID(in Guid rclsid, PWSTR* lplpsz);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CLSIDFromString(PWSTR lpsz, Guid* pclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StringFromIID(in Guid rclsid, PWSTR* lplpsz);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IIDFromString(PWSTR lpsz, Guid* lpiid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ProgIDFromCLSID(in Guid clsid, PWSTR* lplpszProgID);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CLSIDFromProgID(PWSTR lpszProgID, Guid* lpclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StringFromGUID2(in Guid rguid, char16* lpsz, int32 cchMax);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoCreateGuid(Guid* pguid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoWaitForMultipleHandles(uint32 dwFlags, uint32 dwTimeout, uint32 cHandles, HANDLE* pHandles, uint32* lpdwindex);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoWaitForMultipleObjects(uint32 dwFlags, uint32 dwTimeout, uint32 cHandles, HANDLE* pHandles, uint32* lpdwindex);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetTreatAsClass(in Guid clsidOld, Guid* pClsidNew);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoInvalidateRemoteMachineBindings(PWSTR pszMachineName);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CoTaskMemAlloc(uint cb);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CoTaskMemRealloc(void* pv, uint cb);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CoTaskMemFree(void* pv);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRegisterDeviceCatalog(PWSTR deviceInstanceId, CO_DEVICE_CATALOG_COOKIE* cookie);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoRevokeDeviceCatalog(CO_DEVICE_CATALOG_COOKIE cookie);

	[Import("URLMON.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateUri(PWSTR pwzURI, URI_CREATE_FLAGS dwFlags, uint dwReserved, IUri** ppURI);

	[Import("URLMON.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateUriWithFragment(PWSTR pwzURI, PWSTR pwzFragment, uint32 dwFlags, uint dwReserved, IUri** ppURI);

	[Import("urlmon.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateUriFromMultiByteString(PSTR pszANSIInputUri, uint32 dwEncodingFlags, uint32 dwCodePage, uint32 dwCreateFlags, uint dwReserved, IUri** ppUri);

	[Import("URLMON.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateIUriBuilder(IUri* pIUri, uint32 dwFlags, uint dwReserved, IUriBuilder** ppIUriBuilder);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetErrorInfo(uint32 dwReserved, IErrorInfo* perrinfo);

	[Import("OLEAUT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetErrorInfo(uint32 dwReserved, IErrorInfo** pperrinfo);

}
#endregion
