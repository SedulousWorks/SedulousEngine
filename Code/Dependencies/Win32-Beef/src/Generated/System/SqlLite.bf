using Win32.Foundation;
using System;

namespace Win32.System.SqlLite;

#region Constants
public static
{
	public const uint32 SQLITE_VERSION_NUMBER = 3029000;
	public const uint32 SQLITE_OK = 0;
	public const uint32 SQLITE_ERROR = 1;
	public const uint32 SQLITE_INTERNAL = 2;
	public const uint32 SQLITE_PERM = 3;
	public const uint32 SQLITE_ABORT = 4;
	public const uint32 SQLITE_BUSY = 5;
	public const uint32 SQLITE_LOCKED = 6;
	public const uint32 SQLITE_NOMEM = 7;
	public const uint32 SQLITE_READONLY = 8;
	public const uint32 SQLITE_INTERRUPT = 9;
	public const uint32 SQLITE_IOERR = 10;
	public const uint32 SQLITE_CORRUPT = 11;
	public const uint32 SQLITE_NOTFOUND = 12;
	public const uint32 SQLITE_FULL = 13;
	public const uint32 SQLITE_CANTOPEN = 14;
	public const uint32 SQLITE_PROTOCOL = 15;
	public const uint32 SQLITE_EMPTY = 16;
	public const uint32 SQLITE_SCHEMA = 17;
	public const uint32 SQLITE_TOOBIG = 18;
	public const uint32 SQLITE_CONSTRAINT = 19;
	public const uint32 SQLITE_MISMATCH = 20;
	public const uint32 SQLITE_MISUSE = 21;
	public const uint32 SQLITE_NOLFS = 22;
	public const uint32 SQLITE_AUTH = 23;
	public const uint32 SQLITE_FORMAT = 24;
	public const uint32 SQLITE_RANGE = 25;
	public const uint32 SQLITE_NOTADB = 26;
	public const uint32 SQLITE_NOTICE = 27;
	public const uint32 SQLITE_WARNING = 28;
	public const uint32 SQLITE_ROW = 100;
	public const uint32 SQLITE_DONE = 101;
	public const uint32 SQLITE_OPEN_READONLY = 1;
	public const uint32 SQLITE_OPEN_READWRITE = 2;
	public const uint32 SQLITE_OPEN_CREATE = 4;
	public const uint32 SQLITE_OPEN_DELETEONCLOSE = 8;
	public const uint32 SQLITE_OPEN_EXCLUSIVE = 16;
	public const uint32 SQLITE_OPEN_AUTOPROXY = 32;
	public const uint32 SQLITE_OPEN_URI = 64;
	public const uint32 SQLITE_OPEN_MEMORY = 128;
	public const uint32 SQLITE_OPEN_MAIN_DB = 256;
	public const uint32 SQLITE_OPEN_TEMP_DB = 512;
	public const uint32 SQLITE_OPEN_TRANSIENT_DB = 1024;
	public const uint32 SQLITE_OPEN_MAIN_JOURNAL = 2048;
	public const uint32 SQLITE_OPEN_TEMP_JOURNAL = 4096;
	public const uint32 SQLITE_OPEN_SUBJOURNAL = 8192;
	public const uint32 SQLITE_OPEN_SUPER_JOURNAL = 16384;
	public const uint32 SQLITE_OPEN_NOMUTEX = 32768;
	public const uint32 SQLITE_OPEN_FULLMUTEX = 65536;
	public const uint32 SQLITE_OPEN_SHAREDCACHE = 131072;
	public const uint32 SQLITE_OPEN_PRIVATECACHE = 262144;
	public const uint32 SQLITE_OPEN_WAL = 524288;
	public const uint32 SQLITE_OPEN_NOFOLLOW = 16777216;
	public const uint32 SQLITE_OPEN_MASTER_JOURNAL = 16384;
	public const uint32 SQLITE_IOCAP_ATOMIC = 1;
	public const uint32 SQLITE_IOCAP_ATOMIC512 = 2;
	public const uint32 SQLITE_IOCAP_ATOMIC1K = 4;
	public const uint32 SQLITE_IOCAP_ATOMIC2K = 8;
	public const uint32 SQLITE_IOCAP_ATOMIC4K = 16;
	public const uint32 SQLITE_IOCAP_ATOMIC8K = 32;
	public const uint32 SQLITE_IOCAP_ATOMIC16K = 64;
	public const uint32 SQLITE_IOCAP_ATOMIC32K = 128;
	public const uint32 SQLITE_IOCAP_ATOMIC64K = 256;
	public const uint32 SQLITE_IOCAP_SAFE_APPEND = 512;
	public const uint32 SQLITE_IOCAP_SEQUENTIAL = 1024;
	public const uint32 SQLITE_IOCAP_UNDELETABLE_WHEN_OPEN = 2048;
	public const uint32 SQLITE_IOCAP_POWERSAFE_OVERWRITE = 4096;
	public const uint32 SQLITE_IOCAP_IMMUTABLE = 8192;
	public const uint32 SQLITE_IOCAP_BATCH_ATOMIC = 16384;
	public const uint32 SQLITE_LOCK_NONE = 0;
	public const uint32 SQLITE_LOCK_SHARED = 1;
	public const uint32 SQLITE_LOCK_RESERVED = 2;
	public const uint32 SQLITE_LOCK_PENDING = 3;
	public const uint32 SQLITE_LOCK_EXCLUSIVE = 4;
	public const uint32 SQLITE_SYNC_NORMAL = 2;
	public const uint32 SQLITE_SYNC_FULL = 3;
	public const uint32 SQLITE_SYNC_DATAONLY = 16;
	public const uint32 SQLITE_FCNTL_LOCKSTATE = 1;
	public const uint32 SQLITE_FCNTL_GET_LOCKPROXYFILE = 2;
	public const uint32 SQLITE_FCNTL_SET_LOCKPROXYFILE = 3;
	public const uint32 SQLITE_FCNTL_LAST_ERRNO = 4;
	public const uint32 SQLITE_FCNTL_SIZE_HINT = 5;
	public const uint32 SQLITE_FCNTL_CHUNK_SIZE = 6;
	public const uint32 SQLITE_FCNTL_FILE_POINTER = 7;
	public const uint32 SQLITE_FCNTL_SYNC_OMITTED = 8;
	public const uint32 SQLITE_FCNTL_WIN32_AV_RETRY = 9;
	public const uint32 SQLITE_FCNTL_PERSIST_WAL = 10;
	public const uint32 SQLITE_FCNTL_OVERWRITE = 11;
	public const uint32 SQLITE_FCNTL_VFSNAME = 12;
	public const uint32 SQLITE_FCNTL_POWERSAFE_OVERWRITE = 13;
	public const uint32 SQLITE_FCNTL_PRAGMA = 14;
	public const uint32 SQLITE_FCNTL_BUSYHANDLER = 15;
	public const uint32 SQLITE_FCNTL_TEMPFILENAME = 16;
	public const uint32 SQLITE_FCNTL_MMAP_SIZE = 18;
	public const uint32 SQLITE_FCNTL_TRACE = 19;
	public const uint32 SQLITE_FCNTL_HAS_MOVED = 20;
	public const uint32 SQLITE_FCNTL_SYNC = 21;
	public const uint32 SQLITE_FCNTL_COMMIT_PHASETWO = 22;
	public const uint32 SQLITE_FCNTL_WIN32_SET_HANDLE = 23;
	public const uint32 SQLITE_FCNTL_WAL_BLOCK = 24;
	public const uint32 SQLITE_FCNTL_ZIPVFS = 25;
	public const uint32 SQLITE_FCNTL_RBU = 26;
	public const uint32 SQLITE_FCNTL_VFS_POINTER = 27;
	public const uint32 SQLITE_FCNTL_JOURNAL_POINTER = 28;
	public const uint32 SQLITE_FCNTL_WIN32_GET_HANDLE = 29;
	public const uint32 SQLITE_FCNTL_PDB = 30;
	public const uint32 SQLITE_FCNTL_BEGIN_ATOMIC_WRITE = 31;
	public const uint32 SQLITE_FCNTL_COMMIT_ATOMIC_WRITE = 32;
	public const uint32 SQLITE_FCNTL_ROLLBACK_ATOMIC_WRITE = 33;
	public const uint32 SQLITE_FCNTL_LOCK_TIMEOUT = 34;
	public const uint32 SQLITE_FCNTL_DATA_VERSION = 35;
	public const uint32 SQLITE_FCNTL_SIZE_LIMIT = 36;
	public const uint32 SQLITE_FCNTL_CKPT_DONE = 37;
	public const uint32 SQLITE_FCNTL_RESERVE_BYTES = 38;
	public const uint32 SQLITE_FCNTL_CKPT_START = 39;
	public const uint32 SQLITE_GET_LOCKPROXYFILE = 2;
	public const uint32 SQLITE_SET_LOCKPROXYFILE = 3;
	public const uint32 SQLITE_LAST_ERRNO = 4;
	public const uint32 SQLITE_ACCESS_EXISTS = 0;
	public const uint32 SQLITE_ACCESS_READWRITE = 1;
	public const uint32 SQLITE_ACCESS_READ = 2;
	public const uint32 SQLITE_SHM_UNLOCK = 1;
	public const uint32 SQLITE_SHM_LOCK = 2;
	public const uint32 SQLITE_SHM_SHARED = 4;
	public const uint32 SQLITE_SHM_EXCLUSIVE = 8;
	public const uint32 SQLITE_SHM_NLOCK = 8;
	public const uint32 SQLITE_CONFIG_SINGLETHREAD = 1;
	public const uint32 SQLITE_CONFIG_MULTITHREAD = 2;
	public const uint32 SQLITE_CONFIG_SERIALIZED = 3;
	public const uint32 SQLITE_CONFIG_MALLOC = 4;
	public const uint32 SQLITE_CONFIG_GETMALLOC = 5;
	public const uint32 SQLITE_CONFIG_SCRATCH = 6;
	public const uint32 SQLITE_CONFIG_PAGECACHE = 7;
	public const uint32 SQLITE_CONFIG_HEAP = 8;
	public const uint32 SQLITE_CONFIG_MEMSTATUS = 9;
	public const uint32 SQLITE_CONFIG_MUTEX = 10;
	public const uint32 SQLITE_CONFIG_GETMUTEX = 11;
	public const uint32 SQLITE_CONFIG_LOOKASIDE = 13;
	public const uint32 SQLITE_CONFIG_PCACHE = 14;
	public const uint32 SQLITE_CONFIG_GETPCACHE = 15;
	public const uint32 SQLITE_CONFIG_LOG = 16;
	public const uint32 SQLITE_CONFIG_URI = 17;
	public const uint32 SQLITE_CONFIG_PCACHE2 = 18;
	public const uint32 SQLITE_CONFIG_GETPCACHE2 = 19;
	public const uint32 SQLITE_CONFIG_COVERING_INDEX_SCAN = 20;
	public const uint32 SQLITE_CONFIG_SQLLOG = 21;
	public const uint32 SQLITE_CONFIG_MMAP_SIZE = 22;
	public const uint32 SQLITE_CONFIG_WIN32_HEAPSIZE = 23;
	public const uint32 SQLITE_CONFIG_PCACHE_HDRSZ = 24;
	public const uint32 SQLITE_CONFIG_PMASZ = 25;
	public const uint32 SQLITE_CONFIG_STMTJRNL_SPILL = 26;
	public const uint32 SQLITE_CONFIG_SMALL_MALLOC = 27;
	public const uint32 SQLITE_CONFIG_SORTERREF_SIZE = 28;
	public const uint32 SQLITE_CONFIG_MEMDB_MAXSIZE = 29;
	public const uint32 SQLITE_DBCONFIG_MAINDBNAME = 1000;
	public const uint32 SQLITE_DBCONFIG_LOOKASIDE = 1001;
	public const uint32 SQLITE_DBCONFIG_ENABLE_FKEY = 1002;
	public const uint32 SQLITE_DBCONFIG_ENABLE_TRIGGER = 1003;
	public const uint32 SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER = 1004;
	public const uint32 SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION = 1005;
	public const uint32 SQLITE_DBCONFIG_NO_CKPT_ON_CLOSE = 1006;
	public const uint32 SQLITE_DBCONFIG_ENABLE_QPSG = 1007;
	public const uint32 SQLITE_DBCONFIG_TRIGGER_EQP = 1008;
	public const uint32 SQLITE_DBCONFIG_RESET_DATABASE = 1009;
	public const uint32 SQLITE_DBCONFIG_DEFENSIVE = 1010;
	public const uint32 SQLITE_DBCONFIG_WRITABLE_SCHEMA = 1011;
	public const uint32 SQLITE_DBCONFIG_LEGACY_ALTER_TABLE = 1012;
	public const uint32 SQLITE_DBCONFIG_DQS_DML = 1013;
	public const uint32 SQLITE_DBCONFIG_DQS_DDL = 1014;
	public const uint32 SQLITE_DBCONFIG_ENABLE_VIEW = 1015;
	public const uint32 SQLITE_DBCONFIG_LEGACY_FILE_FORMAT = 1016;
	public const uint32 SQLITE_DBCONFIG_TRUSTED_SCHEMA = 1017;
	public const uint32 SQLITE_DBCONFIG_MAX = 1017;
	public const uint32 SQLITE_DENY = 1;
	public const uint32 SQLITE_IGNORE = 2;
	public const uint32 SQLITE_CREATE_INDEX = 1;
	public const uint32 SQLITE_CREATE_TABLE = 2;
	public const uint32 SQLITE_CREATE_TEMP_INDEX = 3;
	public const uint32 SQLITE_CREATE_TEMP_TABLE = 4;
	public const uint32 SQLITE_CREATE_TEMP_TRIGGER = 5;
	public const uint32 SQLITE_CREATE_TEMP_VIEW = 6;
	public const uint32 SQLITE_CREATE_TRIGGER = 7;
	public const uint32 SQLITE_CREATE_VIEW = 8;
	public const uint32 SQLITE_DELETE = 9;
	public const uint32 SQLITE_DROP_INDEX = 10;
	public const uint32 SQLITE_DROP_TABLE = 11;
	public const uint32 SQLITE_DROP_TEMP_INDEX = 12;
	public const uint32 SQLITE_DROP_TEMP_TABLE = 13;
	public const uint32 SQLITE_DROP_TEMP_TRIGGER = 14;
	public const uint32 SQLITE_DROP_TEMP_VIEW = 15;
	public const uint32 SQLITE_DROP_TRIGGER = 16;
	public const uint32 SQLITE_DROP_VIEW = 17;
	public const uint32 SQLITE_INSERT = 18;
	public const uint32 SQLITE_PRAGMA = 19;
	public const uint32 SQLITE_READ = 20;
	public const uint32 SQLITE_SELECT = 21;
	public const uint32 SQLITE_TRANSACTION = 22;
	public const uint32 SQLITE_UPDATE = 23;
	public const uint32 SQLITE_ATTACH = 24;
	public const uint32 SQLITE_DETACH = 25;
	public const uint32 SQLITE_ALTER_TABLE = 26;
	public const uint32 SQLITE_REINDEX = 27;
	public const uint32 SQLITE_ANALYZE = 28;
	public const uint32 SQLITE_CREATE_VTABLE = 29;
	public const uint32 SQLITE_DROP_VTABLE = 30;
	public const uint32 SQLITE_FUNCTION = 31;
	public const uint32 SQLITE_SAVEPOINT = 32;
	public const uint32 SQLITE_COPY = 0;
	public const uint32 SQLITE_RECURSIVE = 33;
	public const uint32 SQLITE_TRACE_STMT = 1;
	public const uint32 SQLITE_TRACE_PROFILE = 2;
	public const uint32 SQLITE_TRACE_ROW = 4;
	public const uint32 SQLITE_TRACE_CLOSE = 8;
	public const uint32 SQLITE_LIMIT_LENGTH = 0;
	public const uint32 SQLITE_LIMIT_SQL_LENGTH = 1;
	public const uint32 SQLITE_LIMIT_COLUMN = 2;
	public const uint32 SQLITE_LIMIT_EXPR_DEPTH = 3;
	public const uint32 SQLITE_LIMIT_COMPOUND_SELECT = 4;
	public const uint32 SQLITE_LIMIT_VDBE_OP = 5;
	public const uint32 SQLITE_LIMIT_FUNCTION_ARG = 6;
	public const uint32 SQLITE_LIMIT_ATTACHED = 7;
	public const uint32 SQLITE_LIMIT_LIKE_PATTERN_LENGTH = 8;
	public const uint32 SQLITE_LIMIT_VARIABLE_NUMBER = 9;
	public const uint32 SQLITE_LIMIT_TRIGGER_DEPTH = 10;
	public const uint32 SQLITE_LIMIT_WORKER_THREADS = 11;
	public const uint32 SQLITE_PREPARE_PERSISTENT = 1;
	public const uint32 SQLITE_PREPARE_NORMALIZE = 2;
	public const uint32 SQLITE_PREPARE_NO_VTAB = 4;
	public const uint32 SQLITE_INTEGER = 1;
	public const uint32 SQLITE_FLOAT = 2;
	public const uint32 SQLITE_BLOB = 4;
	public const uint32 SQLITE_NULL = 5;
	public const uint32 SQLITE3_TEXT = 3;
	public const uint32 SQLITE_UTF8 = 1;
	public const uint32 SQLITE_UTF16LE = 2;
	public const uint32 SQLITE_UTF16BE = 3;
	public const uint32 SQLITE_UTF16 = 4;
	public const uint32 SQLITE_ANY = 5;
	public const uint32 SQLITE_UTF16_ALIGNED = 8;
	public const uint64 SQLITE_DETERMINISTIC = 2048;
	public const uint64 SQLITE_DIRECTONLY = 524288;
	public const uint64 SQLITE_SUBTYPE = 1048576;
	public const uint64 SQLITE_INNOCUOUS = 2097152;
	public const uint32 SQLITE_WIN32_DATA_DIRECTORY_TYPE = 1;
	public const uint32 SQLITE_WIN32_TEMP_DIRECTORY_TYPE = 2;
	public const uint32 SQLITE_TXN_NONE = 0;
	public const uint32 SQLITE_TXN_READ = 1;
	public const uint32 SQLITE_TXN_WRITE = 2;
	public const uint32 SQLITE_INDEX_SCAN_UNIQUE = 1;
	public const uint32 SQLITE_INDEX_CONSTRAINT_EQ = 2;
	public const uint32 SQLITE_INDEX_CONSTRAINT_GT = 4;
	public const uint32 SQLITE_INDEX_CONSTRAINT_LE = 8;
	public const uint32 SQLITE_INDEX_CONSTRAINT_LT = 16;
	public const uint32 SQLITE_INDEX_CONSTRAINT_GE = 32;
	public const uint32 SQLITE_INDEX_CONSTRAINT_MATCH = 64;
	public const uint32 SQLITE_INDEX_CONSTRAINT_LIKE = 65;
	public const uint32 SQLITE_INDEX_CONSTRAINT_GLOB = 66;
	public const uint32 SQLITE_INDEX_CONSTRAINT_REGEXP = 67;
	public const uint32 SQLITE_INDEX_CONSTRAINT_NE = 68;
	public const uint32 SQLITE_INDEX_CONSTRAINT_ISNOT = 69;
	public const uint32 SQLITE_INDEX_CONSTRAINT_ISNOTNULL = 70;
	public const uint32 SQLITE_INDEX_CONSTRAINT_ISNULL = 71;
	public const uint32 SQLITE_INDEX_CONSTRAINT_IS = 72;
	public const uint32 SQLITE_INDEX_CONSTRAINT_FUNCTION = 150;
	public const uint32 SQLITE_MUTEX_FAST = 0;
	public const uint32 SQLITE_MUTEX_RECURSIVE = 1;
	public const uint32 SQLITE_MUTEX_STATIC_MAIN = 2;
	public const uint32 SQLITE_MUTEX_STATIC_MEM = 3;
	public const uint32 SQLITE_MUTEX_STATIC_MEM2 = 4;
	public const uint32 SQLITE_MUTEX_STATIC_OPEN = 4;
	public const uint32 SQLITE_MUTEX_STATIC_PRNG = 5;
	public const uint32 SQLITE_MUTEX_STATIC_LRU = 6;
	public const uint32 SQLITE_MUTEX_STATIC_LRU2 = 7;
	public const uint32 SQLITE_MUTEX_STATIC_PMEM = 7;
	public const uint32 SQLITE_MUTEX_STATIC_APP1 = 8;
	public const uint32 SQLITE_MUTEX_STATIC_APP2 = 9;
	public const uint32 SQLITE_MUTEX_STATIC_APP3 = 10;
	public const uint32 SQLITE_MUTEX_STATIC_VFS1 = 11;
	public const uint32 SQLITE_MUTEX_STATIC_VFS2 = 12;
	public const uint32 SQLITE_MUTEX_STATIC_VFS3 = 13;
	public const uint32 SQLITE_MUTEX_STATIC_MASTER = 2;
	public const uint32 SQLITE_TESTCTRL_FIRST = 5;
	public const uint32 SQLITE_TESTCTRL_PRNG_SAVE = 5;
	public const uint32 SQLITE_TESTCTRL_PRNG_RESTORE = 6;
	public const uint32 SQLITE_TESTCTRL_PRNG_RESET = 7;
	public const uint32 SQLITE_TESTCTRL_BITVEC_TEST = 8;
	public const uint32 SQLITE_TESTCTRL_FAULT_INSTALL = 9;
	public const uint32 SQLITE_TESTCTRL_BENIGN_MALLOC_HOOKS = 10;
	public const uint32 SQLITE_TESTCTRL_PENDING_BYTE = 11;
	public const uint32 SQLITE_TESTCTRL_ASSERT = 12;
	public const uint32 SQLITE_TESTCTRL_ALWAYS = 13;
	public const uint32 SQLITE_TESTCTRL_RESERVE = 14;
	public const uint32 SQLITE_TESTCTRL_OPTIMIZATIONS = 15;
	public const uint32 SQLITE_TESTCTRL_ISKEYWORD = 16;
	public const uint32 SQLITE_TESTCTRL_SCRATCHMALLOC = 17;
	public const uint32 SQLITE_TESTCTRL_INTERNAL_FUNCTIONS = 17;
	public const uint32 SQLITE_TESTCTRL_LOCALTIME_FAULT = 18;
	public const uint32 SQLITE_TESTCTRL_EXPLAIN_STMT = 19;
	public const uint32 SQLITE_TESTCTRL_ONCE_RESET_THRESHOLD = 19;
	public const uint32 SQLITE_TESTCTRL_NEVER_CORRUPT = 20;
	public const uint32 SQLITE_TESTCTRL_VDBE_COVERAGE = 21;
	public const uint32 SQLITE_TESTCTRL_BYTEORDER = 22;
	public const uint32 SQLITE_TESTCTRL_ISINIT = 23;
	public const uint32 SQLITE_TESTCTRL_SORTER_MMAP = 24;
	public const uint32 SQLITE_TESTCTRL_IMPOSTER = 25;
	public const uint32 SQLITE_TESTCTRL_PARSER_COVERAGE = 26;
	public const uint32 SQLITE_TESTCTRL_RESULT_INTREAL = 27;
	public const uint32 SQLITE_TESTCTRL_PRNG_SEED = 28;
	public const uint32 SQLITE_TESTCTRL_EXTRA_SCHEMA_CHECKS = 29;
	public const uint32 SQLITE_TESTCTRL_SEEK_COUNT = 30;
	public const uint32 SQLITE_TESTCTRL_LAST = 30;
	public const uint32 SQLITE_STATUS_MEMORY_USED = 0;
	public const uint32 SQLITE_STATUS_PAGECACHE_USED = 1;
	public const uint32 SQLITE_STATUS_PAGECACHE_OVERFLOW = 2;
	public const uint32 SQLITE_STATUS_SCRATCH_USED = 3;
	public const uint32 SQLITE_STATUS_SCRATCH_OVERFLOW = 4;
	public const uint32 SQLITE_STATUS_MALLOC_SIZE = 5;
	public const uint32 SQLITE_STATUS_PARSER_STACK = 6;
	public const uint32 SQLITE_STATUS_PAGECACHE_SIZE = 7;
	public const uint32 SQLITE_STATUS_SCRATCH_SIZE = 8;
	public const uint32 SQLITE_STATUS_MALLOC_COUNT = 9;
	public const uint32 SQLITE_DBSTATUS_LOOKASIDE_USED = 0;
	public const uint32 SQLITE_DBSTATUS_CACHE_USED = 1;
	public const uint32 SQLITE_DBSTATUS_SCHEMA_USED = 2;
	public const uint32 SQLITE_DBSTATUS_STMT_USED = 3;
	public const uint32 SQLITE_DBSTATUS_LOOKASIDE_HIT = 4;
	public const uint32 SQLITE_DBSTATUS_LOOKASIDE_MISS_SIZE = 5;
	public const uint32 SQLITE_DBSTATUS_LOOKASIDE_MISS_FULL = 6;
	public const uint32 SQLITE_DBSTATUS_CACHE_HIT = 7;
	public const uint32 SQLITE_DBSTATUS_CACHE_MISS = 8;
	public const uint32 SQLITE_DBSTATUS_CACHE_WRITE = 9;
	public const uint32 SQLITE_DBSTATUS_DEFERRED_FKS = 10;
	public const uint32 SQLITE_DBSTATUS_CACHE_USED_SHARED = 11;
	public const uint32 SQLITE_DBSTATUS_CACHE_SPILL = 12;
	public const uint32 SQLITE_DBSTATUS_MAX = 12;
	public const uint32 SQLITE_STMTSTATUS_FULLSCAN_STEP = 1;
	public const uint32 SQLITE_STMTSTATUS_SORT = 2;
	public const uint32 SQLITE_STMTSTATUS_AUTOINDEX = 3;
	public const uint32 SQLITE_STMTSTATUS_VM_STEP = 4;
	public const uint32 SQLITE_STMTSTATUS_REPREPARE = 5;
	public const uint32 SQLITE_STMTSTATUS_RUN = 6;
	public const uint32 SQLITE_STMTSTATUS_MEMUSED = 99;
	public const uint32 SQLITE_CHECKPOINT_PASSIVE = 0;
	public const uint32 SQLITE_CHECKPOINT_FULL = 1;
	public const uint32 SQLITE_CHECKPOINT_RESTART = 2;
	public const uint32 SQLITE_CHECKPOINT_TRUNCATE = 3;
	public const uint32 SQLITE_VTAB_CONSTRAINT_SUPPORT = 1;
	public const uint32 SQLITE_VTAB_INNOCUOUS = 2;
	public const uint32 SQLITE_VTAB_DIRECTONLY = 3;
	public const uint32 SQLITE_ROLLBACK = 1;
	public const uint32 SQLITE_FAIL = 3;
	public const uint32 SQLITE_REPLACE = 5;
	public const uint32 SQLITE_SCANSTAT_NLOOP = 0;
	public const uint32 SQLITE_SCANSTAT_NVISIT = 1;
	public const uint32 SQLITE_SCANSTAT_EST = 2;
	public const uint32 SQLITE_SCANSTAT_NAME = 3;
	public const uint32 SQLITE_SCANSTAT_EXPLAIN = 4;
	public const uint32 SQLITE_SCANSTAT_SELECTID = 5;
	public const uint32 SQLITE_SERIALIZE_NOCOPY = 1;
	public const uint32 SQLITE_DESERIALIZE_FREEONCLOSE = 1;
	public const uint32 SQLITE_DESERIALIZE_RESIZEABLE = 2;
	public const uint32 SQLITE_DESERIALIZE_READONLY = 4;
	public const uint32 NOT_WITHIN = 0;
	public const uint32 PARTLY_WITHIN = 1;
	public const uint32 FULLY_WITHIN = 2;
	public const uint32 __SQLITESESSION_H_ = 1;
	public const uint32 SQLITE_CHANGESETSTART_INVERT = 2;
	public const uint32 SQLITE_CHANGESETAPPLY_NOSAVEPOINT = 1;
	public const uint32 SQLITE_CHANGESETAPPLY_INVERT = 2;
	public const uint32 SQLITE_CHANGESET_DATA = 1;
	public const uint32 SQLITE_CHANGESET_NOTFOUND = 2;
	public const uint32 SQLITE_CHANGESET_CONFLICT = 3;
	public const uint32 SQLITE_CHANGESET_CONSTRAINT = 4;
	public const uint32 SQLITE_CHANGESET_FOREIGN_KEY = 5;
	public const uint32 SQLITE_CHANGESET_OMIT = 0;
	public const uint32 SQLITE_CHANGESET_REPLACE = 1;
	public const uint32 SQLITE_CHANGESET_ABORT = 2;
	public const uint32 SQLITE_SESSION_CONFIG_STRMSIZE = 1;
	public const uint32 FTS5_TOKENIZE_QUERY = 1;
	public const uint32 FTS5_TOKENIZE_PREFIX = 2;
	public const uint32 FTS5_TOKENIZE_DOCUMENT = 4;
	public const uint32 FTS5_TOKENIZE_AUX = 8;
	public const uint32 FTS5_TOKEN_COLOCATED = 1;
}
#endregion
#region Function Pointers
public function int32 sqlite3_callback(void* param0, int32 param1, int8** param2, int8** param3);

public function void sqlite3_syscall_ptr();

public function void sqlite3_destructor_type(void* param0);

public function void fts5_extension_function(Fts5ExtensionApi* pApi, Fts5Context* pFts, sqlite3_context* pCtx, int32 nVal, sqlite3_value** apVal);

public function int32 sqlite3_loadext_entry(sqlite3* db, int8** pzErrMsg, sqlite3_api_routines* pThunk);

#endregion

#region Structs
[CRepr]
public struct sqlite3
{
}

[CRepr]
public struct sqlite3_mutex
{
}

[CRepr]
public struct sqlite3_stmt
{
}

[CRepr]
public struct sqlite3_value
{
}

[CRepr]
public struct sqlite3_context
{
}

[CRepr]
public struct sqlite3_blob
{
}

[CRepr]
public struct sqlite3_str
{
}

[CRepr]
public struct sqlite3_pcache
{
}

[CRepr]
public struct sqlite3_backup
{
}

[CRepr]
public struct Fts5Context
{
}

[CRepr]
public struct Fts5Tokenizer
{
}

[CRepr]
public struct sqlite3_file
{
	public sqlite3_io_methods* pMethods;
}

[CRepr]
public struct sqlite3_io_methods
{
	public int32 iVersion;
	public int xClose;
	public int xRead;
	public int xWrite;
	public int xTruncate;
	public int xSync;
	public int xFileSize;
	public int xLock;
	public int xUnlock;
	public int xCheckReservedLock;
	public int xFileControl;
	public int xSectorSize;
	public int xDeviceCharacteristics;
	public int xShmMap;
	public int xShmLock;
	public int xShmBarrier;
	public int xShmUnmap;
	public int xFetch;
	public int xUnfetch;
}

[CRepr]
public struct sqlite3_vfs
{
	public int32 iVersion;
	public int32 szOsFile;
	public int32 mxPathname;
	public sqlite3_vfs* pNext;
	public PSTR zName;
	public void* pAppData;
	public int xOpen;
	public int xDelete;
	public int xAccess;
	public int xFullPathname;
	public int xDlOpen;
	public int xDlError;
	public int xDlSym;
	public int xDlClose;
	public int xRandomness;
	public int xSleep;
	public int xCurrentTime;
	public int xGetLastError;
	public int xCurrentTimeInt64;
	public int xSetSystemCall;
	public int xGetSystemCall;
	public int xNextSystemCall;
}

[CRepr]
public struct sqlite3_mem_methods
{
	public int xMalloc;
	public int xFree;
	public int xRealloc;
	public int xSize;
	public int xRoundup;
	public int xInit;
	public int xShutdown;
	public void* pAppData;
}

[CRepr]
public struct sqlite3_module
{
	public int32 iVersion;
	public int xCreate;
	public int xConnect;
	public int xBestIndex;
	public int xDisconnect;
	public int xDestroy;
	public int xOpen;
	public int xClose;
	public int xFilter;
	public int xNext;
	public int xEof;
	public int xColumn;
	public int xRowid;
	public int xUpdate;
	public int xBegin;
	public int xSync;
	public int xCommit;
	public int xRollback;
	public int xFindFunction;
	public int xRename;
	public int xSavepoint;
	public int xRelease;
	public int xRollbackTo;
	public int xShadowName;
}

[CRepr]
public struct sqlite3_index_info
{
	[CRepr]
	public struct sqlite3_index_orderby
	{
		public int32 iColumn;
		public uint8 desc;
	}
	[CRepr]
	public struct sqlite3_index_constraint_usage
	{
		public int32 argvIndex;
		public uint8 omit;
	}
	[CRepr]
	public struct sqlite3_index_constraint
	{
		public int32 iColumn;
		public uint8 op;
		public uint8 usable;
		public int32 iTermOffset;
	}
	public int32 nConstraint;
	public sqlite3_index_constraint* aConstraint;
	public int32 nOrderBy;
	public sqlite3_index_orderby* aOrderBy;
	public sqlite3_index_constraint_usage* aConstraintUsage;
	public int32 idxNum;
	public PSTR idxStr;
	public int32 needToFreeIdxStr;
	public int32 orderByConsumed;
	public double estimatedCost;
	public int64 estimatedRows;
	public int32 idxFlags;
	public uint64 colUsed;
}

[CRepr]
public struct sqlite3_vtab
{
	public sqlite3_module* pModule;
	public int32 nRef;
	public PSTR zErrMsg;
}

[CRepr]
public struct sqlite3_vtab_cursor
{
	public sqlite3_vtab* pVtab;
}

[CRepr]
public struct sqlite3_mutex_methods
{
	public int xMutexInit;
	public int xMutexEnd;
	public sqlite3_mutex********* xMutexAlloc;
	public int xMutexFree;
	public int xMutexEnter;
	public int xMutexTry;
	public int xMutexLeave;
	public int xMutexHeld;
	public int xMutexNotheld;
}

[CRepr]
public struct sqlite3_pcache_page
{
	public void* pBuf;
	public void* pExtra;
}

[CRepr]
public struct sqlite3_pcache_methods2
{
	public int32 iVersion;
	public void* pArg;
	public int xInit;
	public int xShutdown;
	public sqlite3_pcache********* xCreate;
	public int xCachesize;
	public int xPagecount;
	public sqlite3_pcache_page******************* xFetch;
	public int xUnpin;
	public int xRekey;
	public int xTruncate;
	public int xDestroy;
	public int xShrink;
}

[CRepr]
public struct sqlite3_pcache_methods
{
	public void* pArg;
	public int xInit;
	public int xShutdown;
	public sqlite3_pcache********* xCreate;
	public int xCachesize;
	public int xPagecount;
	public int xFetch;
	public int xUnpin;
	public int xRekey;
	public int xTruncate;
	public int xDestroy;
}

[CRepr]
public struct sqlite3_snapshot
{
	public uint8[48] hidden;
}

[CRepr]
public struct sqlite3_rtree_geometry
{
	public void* pContext;
	public int32 nParam;
	public double* aParam;
	public void* pUser;
	public int xDelUser;
}

[CRepr]
public struct sqlite3_rtree_query_info
{
	public void* pContext;
	public int32 nParam;
	public double* aParam;
	public void* pUser;
	public int xDelUser;
	public double* aCoord;
	public uint32* anQueue;
	public int32 nCoord;
	public int32 iLevel;
	public int32 mxLevel;
	public int64 iRowid;
	public double rParentScore;
	public int32 eParentWithin;
	public int32 eWithin;
	public double rScore;
	public sqlite3_value** apSqlParam;
}

[CRepr]
public struct Fts5PhraseIter
{
	public uint8* a;
	public uint8* b;
}

[CRepr]
public struct Fts5ExtensionApi
{
	public int32 iVersion;
	public int xUserData;
	public int xColumnCount;
	public int xRowCount;
	public int xColumnTotalSize;
	public int xTokenize;
	public int xPhraseCount;
	public int xPhraseSize;
	public int xInstCount;
	public int xInst;
	public int xRowid;
	public int xColumnText;
	public int xColumnSize;
	public int xQueryPhrase;
	public int xSetAuxdata;
	public int xGetAuxdata;
	public int xPhraseFirst;
	public int xPhraseNext;
	public int xPhraseFirstColumn;
	public int xPhraseNextColumn;
}

[CRepr]
public struct fts5_tokenizer
{
	public int xCreate;
	public int xDelete;
	public int xTokenize;
}

[CRepr]
public struct fts5_api
{
	public int32 iVersion;
	public int xCreateTokenizer;
	public int xFindTokenizer;
	public int xCreateFunction;
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct sqlite3_api_routines
{
	public int aggregate_context;
	public int aggregate_count;
	public int bind_blob;
	public int bind_double;
	public int bind_int;
	public int bind_int64;
	public int bind_null;
	public int bind_parameter_count;
	public int bind_parameter_index;
	public int bind_parameter_name;
	public int bind_text;
	public int bind_text16;
	public int bind_value;
	public int busy_handler;
	public int busy_timeout;
	public int changes;
	public int close;
	public int collation_needed;
	public int collation_needed16;
	public int column_blob;
	public int column_bytes;
	public int column_bytes16;
	public int column_count;
	public int column_database_name;
	public int column_database_name16;
	public int column_decltype;
	public int column_decltype16;
	public int column_double;
	public int column_int;
	public int column_int64;
	public int column_name;
	public int column_name16;
	public int column_origin_name;
	public int column_origin_name16;
	public int column_table_name;
	public int column_table_name16;
	public int column_text;
	public int column_text16;
	public int column_type;
	public sqlite3_value***************** column_value;
	public int commit_hook;
	public int complete;
	public int complete16;
	public int create_collation;
	public int create_collation16;
	public int create_function;
	public int create_function16;
	public int create_module;
	public int data_count;
	public sqlite3***************** db_handle;
	public int declare_vtab;
	public int enable_shared_cache;
	public int errcode;
	public int errmsg;
	public int errmsg16;
	public int exec;
	public int expired;
	public int finalize;
	public int free;
	public int free_table;
	public int get_autocommit;
	public int get_auxdata;
	public int get_table;
	public int global_recover;
	public int interruptx;
	public int last_insert_rowid;
	public int libversion;
	public int libversion_number;
	public int malloc;
	public int mprintf;
	public int open;
	public int open16;
	public int prepare;
	public int prepare16;
	public int profile;
	public int progress_handler;
	public int realloc;
	public int reset;
	public int result_blob;
	public int result_double;
	public int result_error;
	public int result_error16;
	public int result_int;
	public int result_int64;
	public int result_null;
	public int result_text;
	public int result_text16;
	public int result_text16be;
	public int result_text16le;
	public int result_value;
	public int rollback_hook;
	public int set_authorizer;
	public int set_auxdata;
	public int xsnprintf;
	public int step;
	public int table_column_metadata;
	public int thread_cleanup;
	public int total_changes;
	public int trace;
	public int transfer_bindings;
	public int update_hook;
	public int user_data;
	public int value_blob;
	public int value_bytes;
	public int value_bytes16;
	public int value_double;
	public int value_int;
	public int value_int64;
	public int value_numeric_type;
	public int value_text;
	public int value_text16;
	public int value_text16be;
	public int value_text16le;
	public int value_type;
	public int vmprintf;
	public int overload_function;
	public int prepare_v2;
	public int prepare16_v2;
	public int clear_bindings;
	public int create_module_v2;
	public int bind_zeroblob;
	public int blob_bytes;
	public int blob_close;
	public int blob_open;
	public int blob_read;
	public int blob_write;
	public int create_collation_v2;
	public int file_control;
	public int memory_highwater;
	public int memory_used;
	public sqlite3_mutex********* mutex_alloc;
	public int mutex_enter;
	public int mutex_free;
	public int mutex_leave;
	public int mutex_try;
	public int open_v2;
	public int release_memory;
	public int result_error_nomem;
	public int result_error_toobig;
	public int sleep;
	public int soft_heap_limit;
	public sqlite3_vfs********** vfs_find;
	public int vfs_register;
	public int vfs_unregister;
	public int xthreadsafe;
	public int result_zeroblob;
	public int result_error_code;
	public int test_control;
	public int randomness;
	public sqlite3******************** context_db_handle;
	public int extended_result_codes;
	public int limit;
	public sqlite3_stmt************ next_stmt;
	public int sql;
	public int status;
	public int backup_finish;
	public sqlite3_backup************ backup_init;
	public int backup_pagecount;
	public int backup_remaining;
	public int backup_step;
	public int compileoption_get;
	public int compileoption_used;
	public int create_function_v2;
	public int db_config;
	public sqlite3_mutex************ db_mutex;
	public int db_status;
	public int extended_errcode;
	public int log;
	public int soft_heap_limit64;
	public int sourceid;
	public int stmt_status;
	public int strnicmp;
	public int unlock_notify;
	public int wal_autocheckpoint;
	public int wal_checkpoint;
	public int wal_hook;
	public int blob_reopen;
	public int vtab_config;
	public int vtab_on_conflict;
	public int close_v2;
	public int db_filename;
	public int db_readonly;
	public int db_release_memory;
	public int errstr;
	public int stmt_busy;
	public int stmt_readonly;
	public int stricmp;
	public int uri_boolean;
	public int uri_int64;
	public int uri_parameter;
	public int xvsnprintf;
	public int wal_checkpoint_v2;
	public int auto_extension;
	public int bind_blob64;
	public int bind_text64;
	public int cancel_auto_extension;
	public int load_extension;
	public int malloc64;
	public int msize;
	public int realloc64;
	public int reset_auto_extension;
	public int result_blob64;
	public int result_text64;
	public int strglob;
	public sqlite3_value********** value_dup;
	public int value_free;
	public int result_zeroblob64;
	public int bind_zeroblob64;
	public int value_subtype;
	public int result_subtype;
	public int status64;
	public int strlike;
	public int db_cacheflush;
	public int system_errno;
	public int trace_v2;
	public int expanded_sql;
	public int set_last_insert_rowid;
	public int prepare_v3;
	public int prepare16_v3;
	public int bind_pointer;
	public int result_pointer;
	public int value_pointer;
	public int vtab_nochange;
	public int value_nochange;
	public int vtab_collation;
	public int keyword_count;
	public int keyword_name;
	public int keyword_check;
	public sqlite3_str************ str_new;
	public int str_finish;
	public int str_appendf;
	public int str_vappendf;
	public int str_append;
	public int str_appendall;
	public int str_appendchar;
	public int str_reset;
	public int str_errcode;
	public int str_length;
	public int str_value;
	public int create_window_function;
	public int normalized_sql;
	public int stmt_isexplain;
	public int value_frombind;
	public int drop_modules;
	public int hard_heap_limit64;
	public int uri_key;
	public int filename_database;
	public int filename_journal;
	public int filename_wal;
	public int create_filename;
	public int free_filename;
	public sqlite3_file********** database_file_object;
	public int txn_state;
}
#endif

#if BF_32_BIT
[CRepr]
public struct sqlite3_api_routines
{
	public int aggregate_context;
	public int aggregate_count;
	public int bind_blob;
	public int bind_double;
	public int bind_int;
	public int bind_int64;
	public int bind_null;
	public int bind_parameter_count;
	public int bind_parameter_index;
	public int bind_parameter_name;
	public int bind_text;
	public int bind_text16;
	public int bind_value;
	public int busy_handler;
	public int busy_timeout;
	public int changes;
	public int close;
	public int collation_needed;
	public int collation_needed16;
	public int column_blob;
	public int column_bytes;
	public int column_bytes16;
	public int column_count;
	public int column_database_name;
	public int column_database_name16;
	public int column_decltype;
	public int column_decltype16;
	public int column_double;
	public int column_int;
	public int column_int64;
	public int column_name;
	public int column_name16;
	public int column_origin_name;
	public int column_origin_name16;
	public int column_table_name;
	public int column_table_name16;
	public int column_text;
	public int column_text16;
	public int column_type;
	public sqlite3_value***************** column_value;
	public int commit_hook;
	public int complete;
	public int complete16;
	public int create_collation;
	public int create_collation16;
	public int create_function;
	public int create_function16;
	public int create_module;
	public int data_count;
	public sqlite3***************** db_handle;
	public int declare_vtab;
	public int enable_shared_cache;
	public int errcode;
	public int errmsg;
	public int errmsg16;
	public int exec;
	public int expired;
	public int finalize;
	public int free;
	public int free_table;
	public int get_autocommit;
	public int get_auxdata;
	public int get_table;
	public int global_recover;
	public int interruptx;
	public int last_insert_rowid;
	public int libversion;
	public int libversion_number;
	public int malloc;
	public int mprintf;
	public int open;
	public int open16;
	public int prepare;
	public int prepare16;
	public int profile;
	public int progress_handler;
	public int realloc;
	public int reset;
	public int result_blob;
	public int result_double;
	public int result_error;
	public int result_error16;
	public int result_int;
	public int result_int64;
	public int result_null;
	public int result_text;
	public int result_text16;
	public int result_text16be;
	public int result_text16le;
	public int result_value;
	public int rollback_hook;
	public int set_authorizer;
	public int set_auxdata;
	public int xsnprintf;
	public int step;
	public int table_column_metadata;
	public int thread_cleanup;
	public int total_changes;
	public int trace;
	public int transfer_bindings;
	public int update_hook;
	public int user_data;
	public int value_blob;
	public int value_bytes;
	public int value_bytes16;
	public int value_double;
	public int value_int;
	public int value_int64;
	public int value_numeric_type;
	public int value_text;
	public int value_text16;
	public int value_text16be;
	public int value_text16le;
	public int value_type;
	public int vmprintf;
	public int overload_function;
	public int prepare_v2;
	public int prepare16_v2;
	public int clear_bindings;
	public int create_module_v2;
	public int bind_zeroblob;
	public int blob_bytes;
	public int blob_close;
	public int blob_open;
	public int blob_read;
	public int blob_write;
	public int create_collation_v2;
	public int file_control;
	public int memory_highwater;
	public int memory_used;
	public sqlite3_mutex********* mutex_alloc;
	public int mutex_enter;
	public int mutex_free;
	public int mutex_leave;
	public int mutex_try;
	public int open_v2;
	public int release_memory;
	public int result_error_nomem;
	public int result_error_toobig;
	public int sleep;
	public int soft_heap_limit;
	public sqlite3_vfs********** vfs_find;
	public int vfs_register;
	public int vfs_unregister;
	public int xthreadsafe;
	public int result_zeroblob;
	public int result_error_code;
	public int test_control;
	public int randomness;
	public sqlite3******************** context_db_handle;
	public int extended_result_codes;
	public int limit;
	public sqlite3_stmt************ next_stmt;
	public int sql;
	public int status;
	public int backup_finish;
	public sqlite3_backup************ backup_init;
	public int backup_pagecount;
	public int backup_remaining;
	public int backup_step;
	public int compileoption_get;
	public int compileoption_used;
	public int create_function_v2;
	public int db_config;
	public sqlite3_mutex************ db_mutex;
	public int db_status;
	public int extended_errcode;
	public int log;
	public int soft_heap_limit64;
	public int sourceid;
	public int stmt_status;
	public int strnicmp;
	public int unlock_notify;
	public int wal_autocheckpoint;
	public int wal_checkpoint;
	public int wal_hook;
	public int blob_reopen;
	public int vtab_config;
	public int vtab_on_conflict;
	public int close_v2;
	public int db_filename;
	public int db_readonly;
	public int db_release_memory;
	public int errstr;
	public int stmt_busy;
	public int stmt_readonly;
	public int stricmp;
	public int uri_boolean;
	public int uri_int64;
	public int uri_parameter;
	public int xvsnprintf;
	public int wal_checkpoint_v2;
	public int auto_extension;
	public int bind_blob64;
	public int bind_text64;
	public int cancel_auto_extension;
	public int load_extension;
	public int malloc64;
	public int msize;
	public int realloc64;
	public int reset_auto_extension;
	public int result_blob64;
	public int result_text64;
	public int strglob;
	public sqlite3_value********** value_dup;
	public int value_free;
	public int result_zeroblob64;
	public int bind_zeroblob64;
	public int value_subtype;
	public int result_subtype;
	public int status64;
	public int strlike;
	public int db_cacheflush;
	public int system_errno;
	public int trace_v2;
	public int expanded_sql;
	public int set_last_insert_rowid;
	public int prepare_v3;
	public int prepare16_v3;
	public int bind_pointer;
	public int result_pointer;
	public int value_pointer;
	public int vtab_nochange;
	public int value_nochange;
	public int vtab_collation;
	public int keyword_count;
	public int keyword_name;
	public int keyword_check;
	public sqlite3_str************ str_new;
	public int str_finish;
	public int str_appendf;
	public int str_vappendf;
	public int str_append;
	public int str_appendall;
	public int str_appendchar;
	public int str_reset;
	public int str_errcode;
	public int str_length;
	public int str_value;
	public int create_window_function;
	public int normalized_sql;
	public int stmt_isexplain;
	public int value_frombind;
	public int drop_modules;
	public int hard_heap_limit64;
	public int uri_key;
	public int filename_database;
	public int filename_journal;
	public int filename_wal;
	public int create_filename;
	public int free_filename;
	public sqlite3_file********** database_file_object;
	public int txn_state;
}
#endif

#endregion

#region Functions
public static
{
	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_libversion();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_sourceid();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_libversion_number();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_compileoption_used(PSTR zOptName);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_compileoption_get(int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_threadsafe();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_close(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_close_v2(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_exec(sqlite3* param0, PSTR sql, int callback, void* param3, int8** errmsg);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_initialize();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_shutdown();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_os_init();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_os_end();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_config(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_db_config(sqlite3* param0, int32 op);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_extended_result_codes(sqlite3* param0, int32 onoff);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_last_insert_rowid(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_set_last_insert_rowid(sqlite3* param0, int64 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_changes(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_total_changes(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_interrupt(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_complete(PSTR sql);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_complete16(void* sql);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_busy_handler(sqlite3* param0, int param1, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_busy_timeout(sqlite3* param0, int32 ms);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_get_table(sqlite3* db, PSTR zSql, int8*** pazResult, int32* pnRow, int32* pnColumn, int8** pzErrmsg);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_free_table(int8** result);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_mprintf(PSTR param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_vmprintf(PSTR param0, int8* param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_snprintf(int32 param0, PSTR param1, PSTR param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_vsnprintf(int32 param0, PSTR param1, PSTR param2, int8* param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_malloc(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_malloc64(uint64 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_realloc(void* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_realloc64(void* param0, uint64 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_free(void* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 sqlite3_msize(void* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_memory_used();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_memory_highwater(int32 resetFlag);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_randomness(int32 N, void* P);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_set_authorizer(sqlite3* param0, int xAuth, void* pUserData);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_trace(sqlite3* param0, int xTrace, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_profile(sqlite3* param0, int xProfile, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_trace_v2(sqlite3* param0, uint32 uMask, int xCallback, void* pCtx);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_progress_handler(sqlite3* param0, int32 param1, int param2, void* param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_open(PSTR filename, sqlite3** ppDb);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_open16(void* filename, sqlite3** ppDb);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_open_v2(PSTR filename, sqlite3** ppDb, int32 flags, PSTR zVfs);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_uri_parameter(PSTR zFilename, PSTR zParam);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_uri_boolean(PSTR zFile, PSTR zParam, int32 bDefault);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_uri_int64(PSTR param0, PSTR param1, int64 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_uri_key(PSTR zFilename, int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_filename_database(PSTR param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_filename_journal(PSTR param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_filename_wal(PSTR param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_file* sqlite3_database_file_object(PSTR param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_create_filename(PSTR zDatabase, PSTR zJournal, PSTR zWal, int32 nParam, int8** azParam);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_free_filename(PSTR param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_errcode(sqlite3* db);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_extended_errcode(sqlite3* db);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_errmsg(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_errmsg16(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_errstr(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_limit(sqlite3* param0, int32 id, int32 newVal);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_prepare(sqlite3* db, PSTR zSql, int32 nByte, sqlite3_stmt** ppStmt, int8** pzTail);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_prepare_v2(sqlite3* db, PSTR zSql, int32 nByte, sqlite3_stmt** ppStmt, int8** pzTail);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_prepare_v3(sqlite3* db, PSTR zSql, int32 nByte, uint32 prepFlags, sqlite3_stmt** ppStmt, int8** pzTail);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_prepare16(sqlite3* db, void* zSql, int32 nByte, sqlite3_stmt** ppStmt, void** pzTail);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_prepare16_v2(sqlite3* db, void* zSql, int32 nByte, sqlite3_stmt** ppStmt, void** pzTail);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_prepare16_v3(sqlite3* db, void* zSql, int32 nByte, uint32 prepFlags, sqlite3_stmt** ppStmt, void** pzTail);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_sql(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_expanded_sql(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_stmt_readonly(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_stmt_isexplain(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_stmt_busy(sqlite3_stmt* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_blob(sqlite3_stmt* param0, int32 param1, void* param2, int32 n, int param4);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_blob64(sqlite3_stmt* param0, int32 param1, void* param2, uint64 param3, int param4);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_double(sqlite3_stmt* param0, int32 param1, double param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_int(sqlite3_stmt* param0, int32 param1, int32 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_int64(sqlite3_stmt* param0, int32 param1, int64 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_null(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_text(sqlite3_stmt* param0, int32 param1, PSTR param2, int32 param3, int param4);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_text16(sqlite3_stmt* param0, int32 param1, void* param2, int32 param3, int param4);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_text64(sqlite3_stmt* param0, int32 param1, PSTR param2, uint64 param3, int param4, uint8 encoding);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_value(sqlite3_stmt* param0, int32 param1, sqlite3_value* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_pointer(sqlite3_stmt* param0, int32 param1, void* param2, PSTR param3, int param4);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_zeroblob(sqlite3_stmt* param0, int32 param1, int32 n);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_zeroblob64(sqlite3_stmt* param0, int32 param1, uint64 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_parameter_count(sqlite3_stmt* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_bind_parameter_name(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_bind_parameter_index(sqlite3_stmt* param0, PSTR zName);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_clear_bindings(sqlite3_stmt* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_column_count(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_column_name(sqlite3_stmt* param0, int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_name16(sqlite3_stmt* param0, int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_column_database_name(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_database_name16(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_column_table_name(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_table_name16(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_column_origin_name(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_origin_name16(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_column_decltype(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_decltype16(sqlite3_stmt* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_step(sqlite3_stmt* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_data_count(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_blob(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern double sqlite3_column_double(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_column_int(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_column_int64(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* sqlite3_column_text(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_column_text16(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_value* sqlite3_column_value(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_column_bytes(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_column_bytes16(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_column_type(sqlite3_stmt* param0, int32 iCol);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_finalize(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_reset(sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_function(sqlite3* db, PSTR zFunctionName, int32 nArg, int32 eTextRep, void* pApp, int xFunc, int xStep, int xFinal);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_function16(sqlite3* db, void* zFunctionName, int32 nArg, int32 eTextRep, void* pApp, int xFunc, int xStep, int xFinal);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_function_v2(sqlite3* db, PSTR zFunctionName, int32 nArg, int32 eTextRep, void* pApp, int xFunc, int xStep, int xFinal, int xDestroy);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_window_function(sqlite3* db, PSTR zFunctionName, int32 nArg, int32 eTextRep, void* pApp, int xStep, int xFinal, int xValue, int xInverse, int xDestroy);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_aggregate_count(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_expired(sqlite3_stmt* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_transfer_bindings(sqlite3_stmt* param0, sqlite3_stmt* param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_global_recover();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_thread_cleanup();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_memory_alarm(int param0, void* param1, int64 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_value_blob(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern double sqlite3_value_double(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_int(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_value_int64(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_value_pointer(sqlite3_value* param0, PSTR param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* sqlite3_value_text(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_value_text16(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_value_text16le(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_value_text16be(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_bytes(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_bytes16(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_type(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_numeric_type(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_nochange(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_value_frombind(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 sqlite3_value_subtype(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_value* sqlite3_value_dup(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_value_free(sqlite3_value* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_aggregate_context(sqlite3_context* param0, int32 nBytes);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_user_data(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3* sqlite3_context_db_handle(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_get_auxdata(sqlite3_context* param0, int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_set_auxdata(sqlite3_context* param0, int32 N, void* param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_blob(sqlite3_context* param0, void* param1, int32 param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_blob64(sqlite3_context* param0, void* param1, uint64 param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_double(sqlite3_context* param0, double param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_error(sqlite3_context* param0, PSTR param1, int32 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_error16(sqlite3_context* param0, void* param1, int32 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_error_toobig(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_error_nomem(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_error_code(sqlite3_context* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_int(sqlite3_context* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_int64(sqlite3_context* param0, int64 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_null(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_text(sqlite3_context* param0, PSTR param1, int32 param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_text64(sqlite3_context* param0, PSTR param1, uint64 param2, int param3, uint8 encoding);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_text16(sqlite3_context* param0, void* param1, int32 param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_text16le(sqlite3_context* param0, void* param1, int32 param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_text16be(sqlite3_context* param0, void* param1, int32 param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_value(sqlite3_context* param0, sqlite3_value* param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_pointer(sqlite3_context* param0, void* param1, PSTR param2, int param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_zeroblob(sqlite3_context* param0, int32 n);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_result_zeroblob64(sqlite3_context* param0, uint64 n);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_result_subtype(sqlite3_context* param0, uint32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_collation(sqlite3* param0, PSTR zName, int32 eTextRep, void* pArg, int xCompare);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_collation_v2(sqlite3* param0, PSTR zName, int32 eTextRep, void* pArg, int xCompare, int xDestroy);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_collation16(sqlite3* param0, void* zName, int32 eTextRep, void* pArg, int xCompare);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_collation_needed(sqlite3* param0, void* param1, int param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_collation_needed16(sqlite3* param0, void* param1, int param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_sleep(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_win32_set_directory(uint32 type, void* zValue);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_win32_set_directory8(uint32 type, PSTR zValue);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_win32_set_directory16(uint32 type, void* zValue);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_get_autocommit(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3* sqlite3_db_handle(sqlite3_stmt* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_db_filename(sqlite3* db, PSTR zDbName);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_db_readonly(sqlite3* db, PSTR zDbName);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_txn_state(sqlite3* param0, PSTR zSchema);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_stmt* sqlite3_next_stmt(sqlite3* pDb, sqlite3_stmt* pStmt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_commit_hook(sqlite3* param0, int param1, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_rollback_hook(sqlite3* param0, int param1, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_update_hook(sqlite3* param0, int param1, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_enable_shared_cache(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_release_memory(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_db_release_memory(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_soft_heap_limit64(int64 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 sqlite3_hard_heap_limit64(int64 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_soft_heap_limit(int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_table_column_metadata(sqlite3* db, PSTR zDbName, PSTR zTableName, PSTR zColumnName, int8** pzDataType, int8** pzCollSeq, int32* pNotNull, int32* pPrimaryKey, int32* pAutoinc);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_load_extension(sqlite3* db, PSTR zFile, PSTR zProc, int8** pzErrMsg);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_enable_load_extension(sqlite3* db, int32 onoff);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_auto_extension(int xEntryPoint);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_cancel_auto_extension(int xEntryPoint);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_reset_auto_extension();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_module(sqlite3* db, PSTR zName, sqlite3_module* p, void* pClientData);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_create_module_v2(sqlite3* db, PSTR zName, sqlite3_module* p, void* pClientData, int xDestroy);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_drop_modules(sqlite3* db, int8** azKeep);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_declare_vtab(sqlite3* param0, PSTR zSQL);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_overload_function(sqlite3* param0, PSTR zFuncName, int32 nArg);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_blob_open(sqlite3* param0, PSTR zDb, PSTR zTable, PSTR zColumn, int64 iRow, int32 flags, sqlite3_blob** ppBlob);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_blob_reopen(sqlite3_blob* param0, int64 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_blob_close(sqlite3_blob* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_blob_bytes(sqlite3_blob* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_blob_read(sqlite3_blob* param0, void* Z, int32 N, int32 iOffset);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_blob_write(sqlite3_blob* param0, void* z, int32 n, int32 iOffset);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_vfs* sqlite3_vfs_find(PSTR zVfsName);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_vfs_register(sqlite3_vfs* param0, int32 makeDflt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_vfs_unregister(sqlite3_vfs* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_mutex* sqlite3_mutex_alloc(int32 param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_mutex_free(sqlite3_mutex* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_mutex_enter(sqlite3_mutex* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_mutex_try(sqlite3_mutex* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_mutex_leave(sqlite3_mutex* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_mutex* sqlite3_db_mutex(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_file_control(sqlite3* param0, PSTR zDbName, int32 op, void* param3);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_test_control(int32 op);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_keyword_count();

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_keyword_name(int32 param0, int8** param1, int32* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_keyword_check(PSTR param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_str* sqlite3_str_new(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_str_finish(sqlite3_str* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_str_appendf(sqlite3_str* param0, PSTR zFormat);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_str_vappendf(sqlite3_str* param0, PSTR zFormat, int8* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_str_append(sqlite3_str* param0, PSTR zIn, int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_str_appendall(sqlite3_str* param0, PSTR zIn);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_str_appendchar(sqlite3_str* param0, int32 N, CHAR C);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_str_reset(sqlite3_str* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_str_errcode(sqlite3_str* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_str_length(sqlite3_str* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_str_value(sqlite3_str* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_status(int32 op, int32* pCurrent, int32* pHighwater, int32 resetFlag);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_status64(int32 op, int64* pCurrent, int64* pHighwater, int32 resetFlag);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_db_status(sqlite3* param0, int32 op, int32* pCur, int32* pHiwtr, int32 resetFlg);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_stmt_status(sqlite3_stmt* param0, int32 op, int32 resetFlg);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern sqlite3_backup* sqlite3_backup_init(sqlite3* pDest, PSTR zDestName, sqlite3* pSource, PSTR zSourceName);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_backup_step(sqlite3_backup* p, int32 nPage);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_backup_finish(sqlite3_backup* p);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_backup_remaining(sqlite3_backup* p);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_backup_pagecount(sqlite3_backup* p);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_stricmp(PSTR param0, PSTR param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_strnicmp(PSTR param0, PSTR param1, int32 param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_strglob(PSTR zGlob, PSTR zStr);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_strlike(PSTR zGlob, PSTR zStr, uint32 cEsc);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void sqlite3_log(int32 iErrCode, PSTR zFormat);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern void* sqlite3_wal_hook(sqlite3* param0, int param1, void* param2);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_wal_autocheckpoint(sqlite3* db, int32 N);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_wal_checkpoint(sqlite3* db, PSTR zDb);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_wal_checkpoint_v2(sqlite3* db, PSTR zDb, int32 eMode, int32* pnLog, int32* pnCkpt);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_vtab_config(sqlite3* param0, int32 op);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_vtab_on_conflict(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_vtab_nochange(sqlite3_context* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR sqlite3_vtab_collation(sqlite3_index_info* param0, int32 param1);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_db_cacheflush(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_system_errno(sqlite3* param0);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* sqlite3_serialize(sqlite3* db, PSTR zSchema, int64* piSize, uint32 mFlags);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_deserialize(sqlite3* db, PSTR zSchema, uint8* pData, int64 szDb, int64 szBuf, uint32 mFlags);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_rtree_geometry_callback(sqlite3* db, PSTR zGeom, int xGeom, void* pContext);

	[Import("winsqlite3"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 sqlite3_rtree_query_callback(sqlite3* db, PSTR zQueryFunc, int xQueryFunc, void* pContext, int xDestructor);

}
#endregion
