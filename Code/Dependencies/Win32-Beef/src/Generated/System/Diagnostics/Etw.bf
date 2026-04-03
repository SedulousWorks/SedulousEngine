using Win32.Foundation;
using Win32.System.Time;
using Win32.System.Com;
using Win32.Security;
using System;

namespace Win32.System.Diagnostics.Etw;

#region Constants
public static
{
	public const Guid ALPCGuid = .(0x45d8cccd, 0x539f, 0x4b72, 0xa8, 0xb7, 0x5c, 0x68, 0x31, 0x42, 0x60, 0x9a);
	public const Guid DiskIoGuid = .(0x3d6fa8d4, 0xfe05, 0x11d0, 0x9d, 0xda, 0x00, 0xc0, 0x4f, 0xd7, 0xba, 0x7c);
	public const Guid EventTraceConfigGuid = .(0x01853a65, 0x418f, 0x4f36, 0xae, 0xfc, 0xdc, 0x0f, 0x1d, 0x2f, 0xd2, 0x35);
	public const Guid FileIoGuid = .(0x90cbdc39, 0x4a3e, 0x11d1, 0x84, 0xf4, 0x00, 0x00, 0xf8, 0x04, 0x64, 0xe3);
	public const Guid ImageLoadGuid = .(0x2cb15d1d, 0x5fc1, 0x11d2, 0xab, 0xe1, 0x00, 0xa0, 0xc9, 0x11, 0xf5, 0x18);
	public const Guid PageFaultGuid = .(0x3d6fa8d3, 0xfe05, 0x11d0, 0x9d, 0xda, 0x00, 0xc0, 0x4f, 0xd7, 0xba, 0x7c);
	public const Guid PerfInfoGuid = .(0xce1dbfb4, 0x137e, 0x4da6, 0x87, 0xb0, 0x3f, 0x59, 0xaa, 0x10, 0x2c, 0xbc);
	public const Guid ProcessGuid = .(0x3d6fa8d0, 0xfe05, 0x11d0, 0x9d, 0xda, 0x00, 0xc0, 0x4f, 0xd7, 0xba, 0x7c);
	public const Guid RegistryGuid = .(0xae53722e, 0xc863, 0x11d2, 0x86, 0x59, 0x00, 0xc0, 0x4f, 0xa3, 0x21, 0xa1);
	public const Guid SplitIoGuid = .(0xd837ca92, 0x12b9, 0x44a5, 0xad, 0x6a, 0x3a, 0x65, 0xb3, 0x57, 0x8a, 0xa8);
	public const Guid TcpIpGuid = .(0x9a280ac0, 0xc8e0, 0x11d1, 0x84, 0xe2, 0x00, 0xc0, 0x4f, 0xb9, 0x98, 0xa2);
	public const Guid ThreadGuid = .(0x3d6fa8d1, 0xfe05, 0x11d0, 0x9d, 0xda, 0x00, 0xc0, 0x4f, 0xd7, 0xba, 0x7c);
	public const Guid UdpIpGuid = .(0xbf3a50c5, 0xa9c9, 0x4988, 0xa0, 0x05, 0x2d, 0xf0, 0xb7, 0xc8, 0x0f, 0x80);
	public const uint32 WNODE_FLAG_ALL_DATA = 1;
	public const uint32 WNODE_FLAG_SINGLE_INSTANCE = 2;
	public const uint32 WNODE_FLAG_SINGLE_ITEM = 4;
	public const uint32 WNODE_FLAG_EVENT_ITEM = 8;
	public const uint32 WNODE_FLAG_FIXED_INSTANCE_SIZE = 16;
	public const uint32 WNODE_FLAG_TOO_SMALL = 32;
	public const uint32 WNODE_FLAG_INSTANCES_SAME = 64;
	public const uint32 WNODE_FLAG_STATIC_INSTANCE_NAMES = 128;
	public const uint32 WNODE_FLAG_INTERNAL = 256;
	public const uint32 WNODE_FLAG_USE_TIMESTAMP = 512;
	public const uint32 WNODE_FLAG_PERSIST_EVENT = 1024;
	public const uint32 WNODE_FLAG_EVENT_REFERENCE = 8192;
	public const uint32 WNODE_FLAG_ANSI_INSTANCENAMES = 16384;
	public const uint32 WNODE_FLAG_METHOD_ITEM = 32768;
	public const uint32 WNODE_FLAG_PDO_INSTANCE_NAMES = 65536;
	public const uint32 WNODE_FLAG_TRACED_GUID = 131072;
	public const uint32 WNODE_FLAG_LOG_WNODE = 262144;
	public const uint32 WNODE_FLAG_USE_GUID_PTR = 524288;
	public const uint32 WNODE_FLAG_USE_MOF_PTR = 1048576;
	public const uint32 WNODE_FLAG_NO_HEADER = 2097152;
	public const uint32 WNODE_FLAG_SEND_DATA_BLOCK = 4194304;
	public const uint32 WNODE_FLAG_VERSIONED_PROPERTIES = 8388608;
	public const uint32 WNODE_FLAG_SEVERITY_MASK = 4278190080;
	public const uint32 WMIREG_FLAG_EXPENSIVE = 1;
	public const uint32 WMIREG_FLAG_INSTANCE_LIST = 4;
	public const uint32 WMIREG_FLAG_INSTANCE_BASENAME = 8;
	public const uint32 WMIREG_FLAG_INSTANCE_PDO = 32;
	public const uint32 WMIREG_FLAG_REMOVE_GUID = 65536;
	public const uint32 WMIREG_FLAG_RESERVED1 = 131072;
	public const uint32 WMIREG_FLAG_RESERVED2 = 262144;
	public const uint32 WMIREG_FLAG_TRACED_GUID = 524288;
	public const uint32 WMIREG_FLAG_TRACE_CONTROL_GUID = 4096;
	public const uint32 WMIREG_FLAG_EVENT_ONLY_GUID = 64;
	public const uint32 WMI_GUIDTYPE_TRACECONTROL = 0;
	public const uint32 WMI_GUIDTYPE_TRACE = 1;
	public const uint32 WMI_GUIDTYPE_DATA = 2;
	public const uint32 WMI_GUIDTYPE_EVENT = 3;
	public const uint32 WMIGUID_QUERY = 1;
	public const uint32 WMIGUID_SET = 2;
	public const uint32 WMIGUID_NOTIFICATION = 4;
	public const uint32 WMIGUID_READ_DESCRIPTION = 8;
	public const uint32 WMIGUID_EXECUTE = 16;
	public const uint32 TRACELOG_CREATE_REALTIME = 32;
	public const uint32 TRACELOG_CREATE_ONDISK = 64;
	public const uint32 TRACELOG_GUID_ENABLE = 128;
	public const uint32 TRACELOG_ACCESS_KERNEL_LOGGER = 256;
	public const uint32 TRACELOG_LOG_EVENT = 512;
	public const uint32 TRACELOG_CREATE_INPROC = 512;
	public const uint32 TRACELOG_ACCESS_REALTIME = 1024;
	public const uint32 TRACELOG_REGISTER_GUIDS = 2048;
	public const uint32 TRACELOG_JOIN_GROUP = 4096;
	public const uint32 WMI_GLOBAL_LOGGER_ID = 1;
	public const uint32 MAX_PAYLOAD_PREDICATES = 8;
	public const Guid EventTraceGuid = .(0x68fdd900, 0x4a3e, 0x11d1, 0x84, 0xf4, 0x00, 0x00, 0xf8, 0x04, 0x64, 0xe3);
	public const Guid SystemTraceControlGuid = .(0x9e814aad, 0x3204, 0x11d2, 0x9a, 0x82, 0x00, 0x60, 0x08, 0xa8, 0x69, 0x39);
	public const Guid DefaultTraceSecurityGuid = .(0x0811c1af, 0x7a07, 0x4a06, 0x82, 0xed, 0x86, 0x94, 0x55, 0xcd, 0xf7, 0x13);
	public const Guid PrivateLoggerNotificationGuid = .(0x3595ab5c, 0x042a, 0x4c8e, 0xb9, 0x42, 0x2d, 0x05, 0x9b, 0xfe, 0xb1, 0xb1);
	public const Guid SystemIoFilterProviderGuid = .(0xfbd09363, 0x9e22, 0x4661, 0xb8, 0xbf, 0xe7, 0xa3, 0x4b, 0x53, 0x5b, 0x8c);
	public const Guid SystemObjectProviderGuid = .(0xfebd7460, 0x3d1d, 0x47eb, 0xaf, 0x49, 0xc9, 0xee, 0xb1, 0xe1, 0x46, 0xf2);
	public const Guid SystemPowerProviderGuid = .(0xc134884a, 0x32d5, 0x4488, 0x80, 0xe5, 0x14, 0xed, 0x7a, 0xbb, 0x82, 0x69);
	public const Guid SystemHypervisorProviderGuid = .(0xbafa072a, 0x918a, 0x4bed, 0xb6, 0x22, 0xbc, 0x15, 0x20, 0x97, 0x09, 0x8f);
	public const Guid SystemLockProviderGuid = .(0x721ddfd3, 0xdacc, 0x4e1e, 0xb2, 0x6a, 0xa2, 0xcb, 0x31, 0xd4, 0x70, 0x5a);
	public const Guid SystemConfigProviderGuid = .(0xfef3a8b6, 0x318d, 0x4b67, 0xa9, 0x6a, 0x3b, 0x0f, 0x6b, 0x8f, 0x18, 0xfe);
	public const Guid SystemCpuProviderGuid = .(0xc6c5265f, 0xeae8, 0x4650, 0xaa, 0xe4, 0x9d, 0x48, 0x60, 0x3d, 0x85, 0x10);
	public const Guid SystemSchedulerProviderGuid = .(0x599a2a76, 0x4d91, 0x4910, 0x9a, 0xc7, 0x7d, 0x33, 0xf2, 0xe9, 0x7a, 0x6c);
	public const Guid SystemProfileProviderGuid = .(0xbfeb0324, 0x1cee, 0x496f, 0xa4, 0x09, 0x2a, 0xc2, 0xb4, 0x8a, 0x63, 0x22);
	public const Guid SystemIoProviderGuid = .(0x3d5c43e3, 0x0f1c, 0x4202, 0xb8, 0x17, 0x17, 0x4c, 0x00, 0x70, 0xdc, 0x79);
	public const Guid SystemMemoryProviderGuid = .(0x82958ca9, 0xb6cd, 0x47f8, 0xa3, 0xa8, 0x03, 0xae, 0x85, 0xa4, 0xbc, 0x24);
	public const Guid SystemRegistryProviderGuid = .(0x16156bd9, 0xfab4, 0x4cfa, 0xa2, 0x32, 0x89, 0xd1, 0x09, 0x90, 0x58, 0xe3);
	public const Guid SystemProcessProviderGuid = .(0x151f55dc, 0x467d, 0x471f, 0x83, 0xb5, 0x5f, 0x88, 0x9d, 0x46, 0xff, 0x66);
	public const Guid SystemAlpcProviderGuid = .(0xfcb9baaf, 0xe529, 0x4980, 0x92, 0xe9, 0xce, 0xd1, 0xa6, 0xaa, 0xdf, 0xdf);
	public const Guid SystemSyscallProviderGuid = .(0x434286f7, 0x6f1b, 0x45bb, 0xb3, 0x7e, 0x95, 0xf6, 0x23, 0x04, 0x6c, 0x7c);
	public const Guid SystemInterruptProviderGuid = .(0xd4bbee17, 0xb545, 0x4888, 0x85, 0x8b, 0x74, 0x41, 0x69, 0x01, 0x5b, 0x25);
	public const Guid SystemTimerProviderGuid = .(0x4f061568, 0xe215, 0x499f, 0xab, 0x2e, 0xed, 0xa0, 0xae, 0x89, 0x0a, 0x5b);
	public const String KERNEL_LOGGER_NAMEW = "NT Kernel Logger";
	public const String GLOBAL_LOGGER_NAMEW = "GlobalLogger";
	public const String EVENT_LOGGER_NAMEW = "EventLog";
	public const String DIAG_LOGGER_NAMEW = "DiagLog";
	public const String KERNEL_LOGGER_NAMEA = "NT Kernel Logger";
	public const String GLOBAL_LOGGER_NAMEA = "GlobalLogger";
	public const String EVENT_LOGGER_NAMEA = "EventLog";
	public const String DIAG_LOGGER_NAMEA = "DiagLog";
	public const uint32 MAX_MOF_FIELDS = 16;
	public const uint32 SYSTEM_EVENT_TYPE = 1;
	public const uint32 EVENT_TRACE_TYPE_INFO = 0;
	public const uint32 EVENT_TRACE_TYPE_START = 1;
	public const uint32 EVENT_TRACE_TYPE_END = 2;
	public const uint32 EVENT_TRACE_TYPE_STOP = 2;
	public const uint32 EVENT_TRACE_TYPE_DC_START = 3;
	public const uint32 EVENT_TRACE_TYPE_DC_END = 4;
	public const uint32 EVENT_TRACE_TYPE_EXTENSION = 5;
	public const uint32 EVENT_TRACE_TYPE_REPLY = 6;
	public const uint32 EVENT_TRACE_TYPE_DEQUEUE = 7;
	public const uint32 EVENT_TRACE_TYPE_RESUME = 7;
	public const uint32 EVENT_TRACE_TYPE_CHECKPOINT = 8;
	public const uint32 EVENT_TRACE_TYPE_SUSPEND = 8;
	public const uint32 EVENT_TRACE_TYPE_WINEVT_SEND = 9;
	public const uint32 EVENT_TRACE_TYPE_WINEVT_RECEIVE = 240;
	public const uint32 TRACE_LEVEL_NONE = 0;
	public const uint32 TRACE_LEVEL_CRITICAL = 1;
	public const uint32 TRACE_LEVEL_FATAL = 1;
	public const uint32 TRACE_LEVEL_ERROR = 2;
	public const uint32 TRACE_LEVEL_WARNING = 3;
	public const uint32 TRACE_LEVEL_INFORMATION = 4;
	public const uint32 TRACE_LEVEL_VERBOSE = 5;
	public const uint32 TRACE_LEVEL_RESERVED6 = 6;
	public const uint32 TRACE_LEVEL_RESERVED7 = 7;
	public const uint32 TRACE_LEVEL_RESERVED8 = 8;
	public const uint32 TRACE_LEVEL_RESERVED9 = 9;
	public const uint32 EVENT_TRACE_TYPE_LOAD = 10;
	public const uint32 EVENT_TRACE_TYPE_TERMINATE = 11;
	public const uint32 EVENT_TRACE_TYPE_IO_READ = 10;
	public const uint32 EVENT_TRACE_TYPE_IO_WRITE = 11;
	public const uint32 EVENT_TRACE_TYPE_IO_READ_INIT = 12;
	public const uint32 EVENT_TRACE_TYPE_IO_WRITE_INIT = 13;
	public const uint32 EVENT_TRACE_TYPE_IO_FLUSH = 14;
	public const uint32 EVENT_TRACE_TYPE_IO_FLUSH_INIT = 15;
	public const uint32 EVENT_TRACE_TYPE_IO_REDIRECTED_INIT = 16;
	public const uint32 EVENT_TRACE_TYPE_MM_TF = 10;
	public const uint32 EVENT_TRACE_TYPE_MM_DZF = 11;
	public const uint32 EVENT_TRACE_TYPE_MM_COW = 12;
	public const uint32 EVENT_TRACE_TYPE_MM_GPF = 13;
	public const uint32 EVENT_TRACE_TYPE_MM_HPF = 14;
	public const uint32 EVENT_TRACE_TYPE_MM_AV = 15;
	public const uint32 EVENT_TRACE_TYPE_SEND = 10;
	public const uint32 EVENT_TRACE_TYPE_RECEIVE = 11;
	public const uint32 EVENT_TRACE_TYPE_CONNECT = 12;
	public const uint32 EVENT_TRACE_TYPE_DISCONNECT = 13;
	public const uint32 EVENT_TRACE_TYPE_RETRANSMIT = 14;
	public const uint32 EVENT_TRACE_TYPE_ACCEPT = 15;
	public const uint32 EVENT_TRACE_TYPE_RECONNECT = 16;
	public const uint32 EVENT_TRACE_TYPE_CONNFAIL = 17;
	public const uint32 EVENT_TRACE_TYPE_COPY_TCP = 18;
	public const uint32 EVENT_TRACE_TYPE_COPY_ARP = 19;
	public const uint32 EVENT_TRACE_TYPE_ACKFULL = 20;
	public const uint32 EVENT_TRACE_TYPE_ACKPART = 21;
	public const uint32 EVENT_TRACE_TYPE_ACKDUP = 22;
	public const uint32 EVENT_TRACE_TYPE_GUIDMAP = 10;
	public const uint32 EVENT_TRACE_TYPE_CONFIG = 11;
	public const uint32 EVENT_TRACE_TYPE_SIDINFO = 12;
	public const uint32 EVENT_TRACE_TYPE_SECURITY = 13;
	public const uint32 EVENT_TRACE_TYPE_DBGID_RSDS = 64;
	public const uint32 EVENT_TRACE_TYPE_REGCREATE = 10;
	public const uint32 EVENT_TRACE_TYPE_REGOPEN = 11;
	public const uint32 EVENT_TRACE_TYPE_REGDELETE = 12;
	public const uint32 EVENT_TRACE_TYPE_REGQUERY = 13;
	public const uint32 EVENT_TRACE_TYPE_REGSETVALUE = 14;
	public const uint32 EVENT_TRACE_TYPE_REGDELETEVALUE = 15;
	public const uint32 EVENT_TRACE_TYPE_REGQUERYVALUE = 16;
	public const uint32 EVENT_TRACE_TYPE_REGENUMERATEKEY = 17;
	public const uint32 EVENT_TRACE_TYPE_REGENUMERATEVALUEKEY = 18;
	public const uint32 EVENT_TRACE_TYPE_REGQUERYMULTIPLEVALUE = 19;
	public const uint32 EVENT_TRACE_TYPE_REGSETINFORMATION = 20;
	public const uint32 EVENT_TRACE_TYPE_REGFLUSH = 21;
	public const uint32 EVENT_TRACE_TYPE_REGKCBCREATE = 22;
	public const uint32 EVENT_TRACE_TYPE_REGKCBDELETE = 23;
	public const uint32 EVENT_TRACE_TYPE_REGKCBRUNDOWNBEGIN = 24;
	public const uint32 EVENT_TRACE_TYPE_REGKCBRUNDOWNEND = 25;
	public const uint32 EVENT_TRACE_TYPE_REGVIRTUALIZE = 26;
	public const uint32 EVENT_TRACE_TYPE_REGCLOSE = 27;
	public const uint32 EVENT_TRACE_TYPE_REGSETSECURITY = 28;
	public const uint32 EVENT_TRACE_TYPE_REGQUERYSECURITY = 29;
	public const uint32 EVENT_TRACE_TYPE_REGCOMMIT = 30;
	public const uint32 EVENT_TRACE_TYPE_REGPREPARE = 31;
	public const uint32 EVENT_TRACE_TYPE_REGROLLBACK = 32;
	public const uint32 EVENT_TRACE_TYPE_REGMOUNTHIVE = 33;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_CPU = 10;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_PHYSICALDISK = 11;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_LOGICALDISK = 12;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_NIC = 13;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_VIDEO = 14;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_SERVICES = 15;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_POWER = 16;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_NETINFO = 17;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_OPTICALMEDIA = 18;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_IRQ = 21;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_PNP = 22;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_IDECHANNEL = 23;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_NUMANODE = 24;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_PLATFORM = 25;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_PROCESSORGROUP = 26;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_PROCESSORNUMBER = 27;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_DPI = 28;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_CI_INFO = 29;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_MACHINEID = 30;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_DEFRAG = 31;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_MOBILEPLATFORM = 32;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_DEVICEFAMILY = 33;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_FLIGHTID = 34;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_PROCESSOR = 35;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_VIRTUALIZATION = 36;
	public const uint32 EVENT_TRACE_TYPE_CONFIG_BOOT = 37;
	public const uint32 EVENT_TRACE_TYPE_OPTICAL_IO_READ = 55;
	public const uint32 EVENT_TRACE_TYPE_OPTICAL_IO_WRITE = 56;
	public const uint32 EVENT_TRACE_TYPE_OPTICAL_IO_FLUSH = 57;
	public const uint32 EVENT_TRACE_TYPE_OPTICAL_IO_READ_INIT = 58;
	public const uint32 EVENT_TRACE_TYPE_OPTICAL_IO_WRITE_INIT = 59;
	public const uint32 EVENT_TRACE_TYPE_OPTICAL_IO_FLUSH_INIT = 60;
	public const uint32 EVENT_TRACE_TYPE_FLT_PREOP_INIT = 96;
	public const uint32 EVENT_TRACE_TYPE_FLT_POSTOP_INIT = 97;
	public const uint32 EVENT_TRACE_TYPE_FLT_PREOP_COMPLETION = 98;
	public const uint32 EVENT_TRACE_TYPE_FLT_POSTOP_COMPLETION = 99;
	public const uint32 EVENT_TRACE_TYPE_FLT_PREOP_FAILURE = 100;
	public const uint32 EVENT_TRACE_TYPE_FLT_POSTOP_FAILURE = 101;
	public const uint32 EVENT_TRACE_FLAG_DEBUG_EVENTS = 4194304;
	public const uint32 EVENT_TRACE_FLAG_EXTENSION = 2147483648;
	public const uint32 EVENT_TRACE_FLAG_FORWARD_WMI = 1073741824;
	public const uint32 EVENT_TRACE_FLAG_ENABLE_RESERVE = 536870912;
	public const uint32 EVENT_TRACE_FILE_MODE_NONE = 0;
	public const uint32 EVENT_TRACE_FILE_MODE_SEQUENTIAL = 1;
	public const uint32 EVENT_TRACE_FILE_MODE_CIRCULAR = 2;
	public const uint32 EVENT_TRACE_FILE_MODE_APPEND = 4;
	public const uint32 EVENT_TRACE_REAL_TIME_MODE = 256;
	public const uint32 EVENT_TRACE_DELAY_OPEN_FILE_MODE = 512;
	public const uint32 EVENT_TRACE_BUFFERING_MODE = 1024;
	public const uint32 EVENT_TRACE_PRIVATE_LOGGER_MODE = 2048;
	public const uint32 EVENT_TRACE_ADD_HEADER_MODE = 4096;
	public const uint32 EVENT_TRACE_USE_GLOBAL_SEQUENCE = 16384;
	public const uint32 EVENT_TRACE_USE_LOCAL_SEQUENCE = 32768;
	public const uint32 EVENT_TRACE_RELOG_MODE = 65536;
	public const uint32 EVENT_TRACE_USE_PAGED_MEMORY = 16777216;
	public const uint32 EVENT_TRACE_FILE_MODE_NEWFILE = 8;
	public const uint32 EVENT_TRACE_FILE_MODE_PREALLOCATE = 32;
	public const uint32 EVENT_TRACE_NONSTOPPABLE_MODE = 64;
	public const uint32 EVENT_TRACE_SECURE_MODE = 128;
	public const uint32 EVENT_TRACE_USE_KBYTES_FOR_SIZE = 8192;
	public const uint32 EVENT_TRACE_PRIVATE_IN_PROC = 131072;
	public const uint32 EVENT_TRACE_MODE_RESERVED = 1048576;
	public const uint32 EVENT_TRACE_NO_PER_PROCESSOR_BUFFERING = 268435456;
	public const uint32 EVENT_TRACE_SYSTEM_LOGGER_MODE = 33554432;
	public const uint32 EVENT_TRACE_ADDTO_TRIAGE_DUMP = 2147483648;
	public const uint32 EVENT_TRACE_STOP_ON_HYBRID_SHUTDOWN = 4194304;
	public const uint32 EVENT_TRACE_PERSIST_ON_HYBRID_SHUTDOWN = 8388608;
	public const uint32 EVENT_TRACE_INDEPENDENT_SESSION_MODE = 134217728;
	public const uint32 EVENT_TRACE_COMPRESSED_MODE = 67108864;
	public const uint32 EVENT_TRACE_CONTROL_INCREMENT_FILE = 4;
	public const uint32 EVENT_TRACE_CONTROL_CONVERT_TO_REALTIME = 5;
	public const uint32 TRACE_MESSAGE_PERFORMANCE_TIMESTAMP = 16;
	public const uint32 TRACE_MESSAGE_POINTER32 = 64;
	public const uint32 TRACE_MESSAGE_POINTER64 = 128;
	public const uint32 TRACE_MESSAGE_FLAG_MASK = 65535;
	public const uint32 EVENT_TRACE_USE_PROCTIME = 1;
	public const uint32 EVENT_TRACE_USE_NOCPUTIME = 2;
	public const uint32 TRACE_HEADER_FLAG_USE_TIMESTAMP = 512;
	public const uint32 TRACE_HEADER_FLAG_TRACED_GUID = 131072;
	public const uint32 TRACE_HEADER_FLAG_LOG_WNODE = 262144;
	public const uint32 TRACE_HEADER_FLAG_USE_GUID_PTR = 524288;
	public const uint32 TRACE_HEADER_FLAG_USE_MOF_PTR = 1048576;
	public const uint64 SYSTEM_ALPC_KW_GENERAL = 1;
	public const uint64 SYSTEM_CONFIG_KW_SYSTEM = 1;
	public const uint64 SYSTEM_CONFIG_KW_GRAPHICS = 2;
	public const uint64 SYSTEM_CONFIG_KW_STORAGE = 4;
	public const uint64 SYSTEM_CONFIG_KW_NETWORK = 8;
	public const uint64 SYSTEM_CONFIG_KW_SERVICES = 16;
	public const uint64 SYSTEM_CONFIG_KW_PNP = 32;
	public const uint64 SYSTEM_CONFIG_KW_OPTICAL = 64;
	public const uint64 SYSTEM_CPU_KW_CONFIG = 1;
	public const uint64 SYSTEM_CPU_KW_CACHE_FLUSH = 2;
	public const uint64 SYSTEM_CPU_KW_SPEC_CONTROL = 4;
	public const uint64 SYSTEM_HYPERVISOR_KW_PROFILE = 1;
	public const uint64 SYSTEM_HYPERVISOR_KW_CALLOUTS = 2;
	public const uint64 SYSTEM_HYPERVISOR_KW_VTL_CHANGE = 4;
	public const uint64 SYSTEM_INTERRUPT_KW_GENERAL = 1;
	public const uint64 SYSTEM_INTERRUPT_KW_CLOCK_INTERRUPT = 2;
	public const uint64 SYSTEM_INTERRUPT_KW_DPC = 4;
	public const uint64 SYSTEM_INTERRUPT_KW_DPC_QUEUE = 8;
	public const uint64 SYSTEM_INTERRUPT_KW_WDF_DPC = 16;
	public const uint64 SYSTEM_INTERRUPT_KW_WDF_INTERRUPT = 32;
	public const uint64 SYSTEM_INTERRUPT_KW_IPI = 64;
	public const uint64 SYSTEM_IO_KW_DISK = 1;
	public const uint64 SYSTEM_IO_KW_DISK_INIT = 2;
	public const uint64 SYSTEM_IO_KW_FILENAME = 4;
	public const uint64 SYSTEM_IO_KW_SPLIT = 8;
	public const uint64 SYSTEM_IO_KW_FILE = 16;
	public const uint64 SYSTEM_IO_KW_OPTICAL = 32;
	public const uint64 SYSTEM_IO_KW_OPTICAL_INIT = 64;
	public const uint64 SYSTEM_IO_KW_DRIVERS = 128;
	public const uint64 SYSTEM_IO_KW_CC = 256;
	public const uint64 SYSTEM_IO_KW_NETWORK = 512;
	public const uint64 SYSTEM_IOFILTER_KW_GENERAL = 1;
	public const uint64 SYSTEM_IOFILTER_KW_INIT = 2;
	public const uint64 SYSTEM_IOFILTER_KW_FASTIO = 4;
	public const uint64 SYSTEM_IOFILTER_KW_FAILURE = 8;
	public const uint64 SYSTEM_LOCK_KW_SPINLOCK = 1;
	public const uint64 SYSTEM_LOCK_KW_SPINLOCK_COUNTERS = 2;
	public const uint64 SYSTEM_LOCK_KW_SYNC_OBJECTS = 4;
	public const uint64 SYSTEM_MEMORY_KW_GENERAL = 1;
	public const uint64 SYSTEM_MEMORY_KW_HARD_FAULTS = 2;
	public const uint64 SYSTEM_MEMORY_KW_ALL_FAULTS = 4;
	public const uint64 SYSTEM_MEMORY_KW_POOL = 8;
	public const uint64 SYSTEM_MEMORY_KW_MEMINFO = 16;
	public const uint64 SYSTEM_MEMORY_KW_PFSECTION = 32;
	public const uint64 SYSTEM_MEMORY_KW_MEMINFO_WS = 64;
	public const uint64 SYSTEM_MEMORY_KW_HEAP = 128;
	public const uint64 SYSTEM_MEMORY_KW_WS = 256;
	public const uint64 SYSTEM_MEMORY_KW_CONTMEM_GEN = 512;
	public const uint64 SYSTEM_MEMORY_KW_VIRTUAL_ALLOC = 1024;
	public const uint64 SYSTEM_MEMORY_KW_FOOTPRINT = 2048;
	public const uint64 SYSTEM_MEMORY_KW_SESSION = 4096;
	public const uint64 SYSTEM_MEMORY_KW_REFSET = 8192;
	public const uint64 SYSTEM_MEMORY_KW_VAMAP = 16384;
	public const uint64 SYSTEM_MEMORY_KW_NONTRADEABLE = 32768;
	public const uint64 SYSTEM_OBJECT_KW_GENERAL = 1;
	public const uint64 SYSTEM_OBJECT_KW_HANDLE = 2;
	public const uint64 SYSTEM_POWER_KW_GENERAL = 1;
	public const uint64 SYSTEM_POWER_KW_HIBER_RUNDOWN = 2;
	public const uint64 SYSTEM_POWER_KW_PROCESSOR_IDLE = 4;
	public const uint64 SYSTEM_POWER_KW_IDLE_SELECTION = 8;
	public const uint64 SYSTEM_POWER_KW_PPM_EXIT_LATENCY = 16;
	public const uint64 SYSTEM_PROCESS_KW_GENERAL = 1;
	public const uint64 SYSTEM_PROCESS_KW_INSWAP = 2;
	public const uint64 SYSTEM_PROCESS_KW_FREEZE = 4;
	public const uint64 SYSTEM_PROCESS_KW_PERF_COUNTER = 8;
	public const uint64 SYSTEM_PROCESS_KW_WAKE_COUNTER = 16;
	public const uint64 SYSTEM_PROCESS_KW_WAKE_DROP = 32;
	public const uint64 SYSTEM_PROCESS_KW_WAKE_EVENT = 64;
	public const uint64 SYSTEM_PROCESS_KW_DEBUG_EVENTS = 128;
	public const uint64 SYSTEM_PROCESS_KW_DBGPRINT = 256;
	public const uint64 SYSTEM_PROCESS_KW_JOB = 512;
	public const uint64 SYSTEM_PROCESS_KW_WORKER_THREAD = 1024;
	public const uint64 SYSTEM_PROCESS_KW_THREAD = 2048;
	public const uint64 SYSTEM_PROCESS_KW_LOADER = 4096;
	public const uint64 SYSTEM_PROFILE_KW_GENERAL = 1;
	public const uint64 SYSTEM_PROFILE_KW_PMC_PROFILE = 2;
	public const uint64 SYSTEM_REGISTRY_KW_GENERAL = 1;
	public const uint64 SYSTEM_REGISTRY_KW_HIVE = 2;
	public const uint64 SYSTEM_REGISTRY_KW_NOTIFICATION = 4;
	public const uint64 SYSTEM_SCHEDULER_KW_XSCHEDULER = 1;
	public const uint64 SYSTEM_SCHEDULER_KW_DISPATCHER = 2;
	public const uint64 SYSTEM_SCHEDULER_KW_KERNEL_QUEUE = 4;
	public const uint64 SYSTEM_SCHEDULER_KW_SHOULD_YIELD = 8;
	public const uint64 SYSTEM_SCHEDULER_KW_ANTI_STARVATION = 16;
	public const uint64 SYSTEM_SCHEDULER_KW_LOAD_BALANCER = 32;
	public const uint64 SYSTEM_SCHEDULER_KW_AFFINITY = 64;
	public const uint64 SYSTEM_SCHEDULER_KW_PRIORITY = 128;
	public const uint64 SYSTEM_SCHEDULER_KW_IDEAL_PROCESSOR = 256;
	public const uint64 SYSTEM_SCHEDULER_KW_CONTEXT_SWITCH = 512;
	public const uint64 SYSTEM_SCHEDULER_KW_COMPACT_CSWITCH = 1024;
	public const uint64 SYSTEM_SYSCALL_KW_GENERAL = 1;
	public const uint64 SYSTEM_TIMER_KW_GENERAL = 1;
	public const uint64 SYSTEM_TIMER_KW_CLOCK_TIMER = 2;
	public const uint32 SYSTEM_MEMORY_POOL_FILTER_ID = 1;
	public const uint32 ETW_NULL_TYPE_VALUE = 0;
	public const uint32 ETW_OBJECT_TYPE_VALUE = 1;
	public const uint32 ETW_STRING_TYPE_VALUE = 2;
	public const uint32 ETW_SBYTE_TYPE_VALUE = 3;
	public const uint32 ETW_BYTE_TYPE_VALUE = 4;
	public const uint32 ETW_INT16_TYPE_VALUE = 5;
	public const uint32 ETW_UINT16_TYPE_VALUE = 6;
	public const uint32 ETW_INT32_TYPE_VALUE = 7;
	public const uint32 ETW_UINT32_TYPE_VALUE = 8;
	public const uint32 ETW_INT64_TYPE_VALUE = 9;
	public const uint32 ETW_UINT64_TYPE_VALUE = 10;
	public const uint32 ETW_CHAR_TYPE_VALUE = 11;
	public const uint32 ETW_SINGLE_TYPE_VALUE = 12;
	public const uint32 ETW_DOUBLE_TYPE_VALUE = 13;
	public const uint32 ETW_BOOLEAN_TYPE_VALUE = 14;
	public const uint32 ETW_DECIMAL_TYPE_VALUE = 15;
	public const uint32 ETW_GUID_TYPE_VALUE = 101;
	public const uint32 ETW_ASCIICHAR_TYPE_VALUE = 102;
	public const uint32 ETW_ASCIISTRING_TYPE_VALUE = 103;
	public const uint32 ETW_COUNTED_STRING_TYPE_VALUE = 104;
	public const uint32 ETW_POINTER_TYPE_VALUE = 105;
	public const uint32 ETW_SIZET_TYPE_VALUE = 106;
	public const uint32 ETW_HIDDEN_TYPE_VALUE = 107;
	public const uint32 ETW_BOOL_TYPE_VALUE = 108;
	public const uint32 ETW_COUNTED_ANSISTRING_TYPE_VALUE = 109;
	public const uint32 ETW_REVERSED_COUNTED_STRING_TYPE_VALUE = 110;
	public const uint32 ETW_REVERSED_COUNTED_ANSISTRING_TYPE_VALUE = 111;
	public const uint32 ETW_NON_NULL_TERMINATED_STRING_TYPE_VALUE = 112;
	public const uint32 ETW_REDUCED_ANSISTRING_TYPE_VALUE = 113;
	public const uint32 ETW_REDUCED_STRING_TYPE_VALUE = 114;
	public const uint32 ETW_SID_TYPE_VALUE = 115;
	public const uint32 ETW_VARIANT_TYPE_VALUE = 116;
	public const uint32 ETW_PTVECTOR_TYPE_VALUE = 117;
	public const uint32 ETW_WMITIME_TYPE_VALUE = 118;
	public const uint32 ETW_DATETIME_TYPE_VALUE = 119;
	public const uint32 ETW_REFRENCE_TYPE_VALUE = 120;
	public const uint32 TRACE_PROVIDER_FLAG_LEGACY = 1;
	public const uint32 TRACE_PROVIDER_FLAG_PRE_ENABLE = 2;
	public const String KERNEL_LOGGER_NAME = "NT Kernel Logger";
	public const String GLOBAL_LOGGER_NAME = "GlobalLogger";
	public const String EVENT_LOGGER_NAME = "EventLog";
	public const uint32 ENABLE_TRACE_PARAMETERS_VERSION = 1;
	public const uint32 ENABLE_TRACE_PARAMETERS_VERSION_2 = 2;
	public const uint32 EVENT_MIN_LEVEL = 0;
	public const uint32 EVENT_MAX_LEVEL = 255;
	public const uint32 EVENT_ACTIVITY_CTRL_GET_ID = 1;
	public const uint32 EVENT_ACTIVITY_CTRL_SET_ID = 2;
	public const uint32 EVENT_ACTIVITY_CTRL_CREATE_ID = 3;
	public const uint32 EVENT_ACTIVITY_CTRL_GET_SET_ID = 4;
	public const uint32 EVENT_ACTIVITY_CTRL_CREATE_SET_ID = 5;
	public const uint32 MAX_EVENT_DATA_DESCRIPTORS = 128;
	public const uint32 MAX_EVENT_FILTER_DATA_SIZE = 1024;
	public const uint32 MAX_EVENT_FILTER_PAYLOAD_SIZE = 4096;
	public const uint32 MAX_EVENT_FILTER_EVENT_NAME_SIZE = 4096;
	public const uint32 MAX_EVENT_FILTERS_COUNT = 13;
	public const uint32 MAX_EVENT_FILTER_PID_COUNT = 8;
	public const uint32 MAX_EVENT_FILTER_EVENT_ID_COUNT = 64;
	public const uint32 EVENT_FILTER_TYPE_NONE = 0;
	public const uint32 EVENT_FILTER_TYPE_SCHEMATIZED = 2147483648;
	public const uint32 EVENT_FILTER_TYPE_SYSTEM_FLAGS = 2147483649;
	public const uint32 EVENT_FILTER_TYPE_TRACEHANDLE = 2147483650;
	public const uint32 EVENT_FILTER_TYPE_PID = 2147483652;
	public const uint32 EVENT_FILTER_TYPE_EXECUTABLE_NAME = 2147483656;
	public const uint32 EVENT_FILTER_TYPE_PACKAGE_ID = 2147483664;
	public const uint32 EVENT_FILTER_TYPE_PACKAGE_APP_ID = 2147483680;
	public const uint32 EVENT_FILTER_TYPE_PAYLOAD = 2147483904;
	public const uint32 EVENT_FILTER_TYPE_EVENT_ID = 2147484160;
	public const uint32 EVENT_FILTER_TYPE_EVENT_NAME = 2147484672;
	public const uint32 EVENT_FILTER_TYPE_STACKWALK = 2147487744;
	public const uint32 EVENT_FILTER_TYPE_STACKWALK_NAME = 2147491840;
	public const uint32 EVENT_FILTER_TYPE_STACKWALK_LEVEL_KW = 2147500032;
	public const uint32 EVENT_FILTER_TYPE_CONTAINER = 2147516416;
	public const uint32 EVENT_DATA_DESCRIPTOR_TYPE_NONE = 0;
	public const uint32 EVENT_DATA_DESCRIPTOR_TYPE_EVENT_METADATA = 1;
	public const uint32 EVENT_DATA_DESCRIPTOR_TYPE_PROVIDER_METADATA = 2;
	public const uint32 EVENT_DATA_DESCRIPTOR_TYPE_TIMESTAMP_OVERRIDE = 3;
	public const uint32 EVENT_WRITE_FLAG_NO_FAULTING = 1;
	public const uint32 EVENT_WRITE_FLAG_INPRIVATE = 2;
	public const uint32 EVENT_HEADER_EXT_TYPE_RELATED_ACTIVITYID = 1;
	public const uint32 EVENT_HEADER_EXT_TYPE_SID = 2;
	public const uint32 EVENT_HEADER_EXT_TYPE_TS_ID = 3;
	public const uint32 EVENT_HEADER_EXT_TYPE_INSTANCE_INFO = 4;
	public const uint32 EVENT_HEADER_EXT_TYPE_STACK_TRACE32 = 5;
	public const uint32 EVENT_HEADER_EXT_TYPE_STACK_TRACE64 = 6;
	public const uint32 EVENT_HEADER_EXT_TYPE_PEBS_INDEX = 7;
	public const uint32 EVENT_HEADER_EXT_TYPE_PMC_COUNTERS = 8;
	public const uint32 EVENT_HEADER_EXT_TYPE_PSM_KEY = 9;
	public const uint32 EVENT_HEADER_EXT_TYPE_EVENT_KEY = 10;
	public const uint32 EVENT_HEADER_EXT_TYPE_EVENT_SCHEMA_TL = 11;
	public const uint32 EVENT_HEADER_EXT_TYPE_PROV_TRAITS = 12;
	public const uint32 EVENT_HEADER_EXT_TYPE_PROCESS_START_KEY = 13;
	public const uint32 EVENT_HEADER_EXT_TYPE_CONTROL_GUID = 14;
	public const uint32 EVENT_HEADER_EXT_TYPE_QPC_DELTA = 15;
	public const uint32 EVENT_HEADER_EXT_TYPE_CONTAINER_ID = 16;
	public const uint32 EVENT_HEADER_EXT_TYPE_STACK_KEY32 = 17;
	public const uint32 EVENT_HEADER_EXT_TYPE_STACK_KEY64 = 18;
	public const uint32 EVENT_HEADER_EXT_TYPE_MAX = 19;
	public const uint32 EVENT_HEADER_PROPERTY_XML = 1;
	public const uint32 EVENT_HEADER_PROPERTY_FORWARDED_XML = 2;
	public const uint32 EVENT_HEADER_PROPERTY_LEGACY_EVENTLOG = 4;
	public const uint32 EVENT_HEADER_PROPERTY_RELOGGABLE = 8;
	public const uint32 EVENT_HEADER_FLAG_EXTENDED_INFO = 1;
	public const uint32 EVENT_HEADER_FLAG_PRIVATE_SESSION = 2;
	public const uint32 EVENT_HEADER_FLAG_STRING_ONLY = 4;
	public const uint32 EVENT_HEADER_FLAG_TRACE_MESSAGE = 8;
	public const uint32 EVENT_HEADER_FLAG_NO_CPUTIME = 16;
	public const uint32 EVENT_HEADER_FLAG_32_BIT_HEADER = 32;
	public const uint32 EVENT_HEADER_FLAG_64_BIT_HEADER = 64;
	public const uint32 EVENT_HEADER_FLAG_DECODE_GUID = 128;
	public const uint32 EVENT_HEADER_FLAG_CLASSIC_HEADER = 256;
	public const uint32 EVENT_HEADER_FLAG_PROCESSOR_INDEX = 512;
	public const uint32 EVENT_ENABLE_PROPERTY_SID = 1;
	public const uint32 EVENT_ENABLE_PROPERTY_TS_ID = 2;
	public const uint32 EVENT_ENABLE_PROPERTY_STACK_TRACE = 4;
	public const uint32 EVENT_ENABLE_PROPERTY_PSM_KEY = 8;
	public const uint32 EVENT_ENABLE_PROPERTY_IGNORE_KEYWORD_0 = 16;
	public const uint32 EVENT_ENABLE_PROPERTY_PROVIDER_GROUP = 32;
	public const uint32 EVENT_ENABLE_PROPERTY_ENABLE_KEYWORD_0 = 64;
	public const uint32 EVENT_ENABLE_PROPERTY_PROCESS_START_KEY = 128;
	public const uint32 EVENT_ENABLE_PROPERTY_EVENT_KEY = 256;
	public const uint32 EVENT_ENABLE_PROPERTY_EXCLUDE_INPRIVATE = 512;
	public const uint32 EVENT_ENABLE_PROPERTY_ENABLE_SILOS = 1024;
	public const uint32 EVENT_ENABLE_PROPERTY_SOURCE_CONTAINER_TRACKING = 2048;
	public const uint32 PROCESS_TRACE_MODE_REAL_TIME = 256;
	public const uint32 PROCESS_TRACE_MODE_RAW_TIMESTAMP = 4096;
	public const uint32 PROCESS_TRACE_MODE_EVENT_RECORD = 268435456;
	public const Guid CLSID_TraceRelogger = .(0x7b40792d, 0x05ff, 0x44c4, 0x90, 0x58, 0xf4, 0x40, 0xc7, 0x1f, 0x17, 0xd4);
}
#endregion

#region TypeDefs
typealias TDH_HANDLE = int;

typealias PROCESSTRACE_HANDLE = uint64;

typealias CONTROLTRACE_HANDLE = uint64;

typealias RELOGSTREAM_HANDLE = uint64;

#endregion


#region Enums

[AllowDuplicates]
public enum TRACE_MESSAGE_FLAGS : uint32
{
	TRACE_MESSAGE_COMPONENTID = 4,
	TRACE_MESSAGE_GUID = 2,
	TRACE_MESSAGE_SEQUENCE = 1,
	TRACE_MESSAGE_SYSTEMINFO = 32,
	TRACE_MESSAGE_TIMESTAMP = 8,
}


[AllowDuplicates]
public enum ENABLECALLBACK_ENABLED_STATE : uint32
{
	EVENT_CONTROL_CODE_DISABLE_PROVIDER = 0,
	EVENT_CONTROL_CODE_ENABLE_PROVIDER = 1,
	EVENT_CONTROL_CODE_CAPTURE_STATE = 2,
}


[AllowDuplicates]
public enum EVENT_TRACE_CONTROL : uint32
{
	EVENT_TRACE_CONTROL_FLUSH = 3,
	EVENT_TRACE_CONTROL_QUERY = 0,
	EVENT_TRACE_CONTROL_STOP = 1,
	EVENT_TRACE_CONTROL_UPDATE = 2,
}


[AllowDuplicates]
public enum EVENT_TRACE_FLAG : uint32
{
	EVENT_TRACE_FLAG_ALPC = 1048576,
	EVENT_TRACE_FLAG_CSWITCH = 16,
	EVENT_TRACE_FLAG_DBGPRINT = 262144,
	EVENT_TRACE_FLAG_DISK_FILE_IO = 512,
	EVENT_TRACE_FLAG_DISK_IO = 256,
	EVENT_TRACE_FLAG_DISK_IO_INIT = 1024,
	EVENT_TRACE_FLAG_DISPATCHER = 2048,
	EVENT_TRACE_FLAG_DPC = 32,
	EVENT_TRACE_FLAG_DRIVER = 8388608,
	EVENT_TRACE_FLAG_FILE_IO = 33554432,
	EVENT_TRACE_FLAG_FILE_IO_INIT = 67108864,
	EVENT_TRACE_FLAG_IMAGE_LOAD = 4,
	EVENT_TRACE_FLAG_INTERRUPT = 64,
	EVENT_TRACE_FLAG_JOB = 524288,
	EVENT_TRACE_FLAG_MEMORY_HARD_FAULTS = 8192,
	EVENT_TRACE_FLAG_MEMORY_PAGE_FAULTS = 4096,
	EVENT_TRACE_FLAG_NETWORK_TCPIP = 65536,
	EVENT_TRACE_FLAG_NO_SYSCONFIG = 268435456,
	EVENT_TRACE_FLAG_PROCESS = 1,
	EVENT_TRACE_FLAG_PROCESS_COUNTERS = 8,
	EVENT_TRACE_FLAG_PROFILE = 16777216,
	EVENT_TRACE_FLAG_REGISTRY = 131072,
	EVENT_TRACE_FLAG_SPLIT_IO = 2097152,
	EVENT_TRACE_FLAG_SYSTEMCALL = 128,
	EVENT_TRACE_FLAG_THREAD = 2,
	EVENT_TRACE_FLAG_VAMAP = 32768,
	EVENT_TRACE_FLAG_VIRTUAL_ALLOC = 16384,
}


[AllowDuplicates]
public enum WMIDPREQUESTCODE : int32
{
	WMI_GET_ALL_DATA = 0,
	WMI_GET_SINGLE_INSTANCE = 1,
	WMI_SET_SINGLE_INSTANCE = 2,
	WMI_SET_SINGLE_ITEM = 3,
	WMI_ENABLE_EVENTS = 4,
	WMI_DISABLE_EVENTS = 5,
	WMI_ENABLE_COLLECTION = 6,
	WMI_DISABLE_COLLECTION = 7,
	WMI_REGINFO = 8,
	WMI_EXECUTE_METHOD = 9,
	WMI_CAPTURE_STATE = 10,
}


[AllowDuplicates]
public enum ETW_COMPRESSION_RESUMPTION_MODE : int32
{
	EtwCompressionModeRestart = 0,
	EtwCompressionModeNoDisable = 1,
	EtwCompressionModeNoRestart = 2,
}


[AllowDuplicates]
public enum ETW_PMC_COUNTER_OWNER_TYPE : int32
{
	EtwPmcOwnerFree = 0,
	EtwPmcOwnerUntagged = 1,
	EtwPmcOwnerTagged = 2,
	EtwPmcOwnerTaggedWithSource = 3,
}


[AllowDuplicates]
public enum TRACE_QUERY_INFO_CLASS : int32
{
	TraceGuidQueryList = 0,
	TraceGuidQueryInfo = 1,
	TraceGuidQueryProcess = 2,
	TraceStackTracingInfo = 3,
	TraceSystemTraceEnableFlagsInfo = 4,
	TraceSampledProfileIntervalInfo = 5,
	TraceProfileSourceConfigInfo = 6,
	TraceProfileSourceListInfo = 7,
	TracePmcEventListInfo = 8,
	TracePmcCounterListInfo = 9,
	TraceSetDisallowList = 10,
	TraceVersionInfo = 11,
	TraceGroupQueryList = 12,
	TraceGroupQueryInfo = 13,
	TraceDisallowListQuery = 14,
	TraceInfoReserved15 = 15,
	TracePeriodicCaptureStateListInfo = 16,
	TracePeriodicCaptureStateInfo = 17,
	TraceProviderBinaryTracking = 18,
	TraceMaxLoggersQuery = 19,
	TraceLbrConfigurationInfo = 20,
	TraceLbrEventListInfo = 21,
	TraceMaxPmcCounterQuery = 22,
	TraceStreamCount = 23,
	TraceStackCachingInfo = 24,
	TracePmcCounterOwners = 25,
	TraceUnifiedStackCachingInfo = 26,
	MaxTraceSetInfoClass = 27,
}


[AllowDuplicates]
public enum ETW_PROCESS_HANDLE_INFO_TYPE : int32
{
	EtwQueryPartitionInformation = 1,
	EtwQueryPartitionInformationV2 = 2,
	EtwQueryLastDroppedTimes = 3,
	EtwQueryProcessHandleInfoMax = 4,
}


[AllowDuplicates]
public enum EVENT_INFO_CLASS : int32
{
	EventProviderBinaryTrackInfo = 0,
	EventProviderSetReserved1 = 1,
	EventProviderSetTraits = 2,
	EventProviderUseDescriptorType = 3,
	MaxEventInfo = 4,
}


[AllowDuplicates]
public enum ETW_PROVIDER_TRAIT_TYPE : int32
{
	EtwProviderTraitTypeGroup = 1,
	EtwProviderTraitDecodeGuid = 2,
	EtwProviderTraitTypeMax = 3,
}


[AllowDuplicates]
public enum EVENTSECURITYOPERATION : int32
{
	EventSecuritySetDACL = 0,
	EventSecuritySetSACL = 1,
	EventSecurityAddDACL = 2,
	EventSecurityAddSACL = 3,
	EventSecurityMax = 4,
}


[AllowDuplicates]
public enum MAP_FLAGS : int32
{
	EVENTMAP_INFO_FLAG_MANIFEST_VALUEMAP = 1,
	EVENTMAP_INFO_FLAG_MANIFEST_BITMAP = 2,
	EVENTMAP_INFO_FLAG_MANIFEST_PATTERNMAP = 4,
	EVENTMAP_INFO_FLAG_WBEM_VALUEMAP = 8,
	EVENTMAP_INFO_FLAG_WBEM_BITMAP = 16,
	EVENTMAP_INFO_FLAG_WBEM_FLAG = 32,
	EVENTMAP_INFO_FLAG_WBEM_NO_MAP = 64,
}


[AllowDuplicates]
public enum MAP_VALUETYPE : int32
{
	EVENTMAP_ENTRY_VALUETYPE_ULONG = 0,
	EVENTMAP_ENTRY_VALUETYPE_STRING = 1,
}


[AllowDuplicates]
public enum _TDH_IN_TYPE : int32
{
	TDH_INTYPE_NULL = 0,
	TDH_INTYPE_UNICODESTRING = 1,
	TDH_INTYPE_ANSISTRING = 2,
	TDH_INTYPE_INT8 = 3,
	TDH_INTYPE_UINT8 = 4,
	TDH_INTYPE_INT16 = 5,
	TDH_INTYPE_UINT16 = 6,
	TDH_INTYPE_INT32 = 7,
	TDH_INTYPE_UINT32 = 8,
	TDH_INTYPE_INT64 = 9,
	TDH_INTYPE_UINT64 = 10,
	TDH_INTYPE_FLOAT = 11,
	TDH_INTYPE_DOUBLE = 12,
	TDH_INTYPE_BOOLEAN = 13,
	TDH_INTYPE_BINARY = 14,
	TDH_INTYPE_GUID = 15,
	TDH_INTYPE_POINTER = 16,
	TDH_INTYPE_FILETIME = 17,
	TDH_INTYPE_SYSTEMTIME = 18,
	TDH_INTYPE_SID = 19,
	TDH_INTYPE_HEXINT32 = 20,
	TDH_INTYPE_HEXINT64 = 21,
	TDH_INTYPE_MANIFEST_COUNTEDSTRING = 22,
	TDH_INTYPE_MANIFEST_COUNTEDANSISTRING = 23,
	TDH_INTYPE_RESERVED24 = 24,
	TDH_INTYPE_MANIFEST_COUNTEDBINARY = 25,
	TDH_INTYPE_COUNTEDSTRING = 300,
	TDH_INTYPE_COUNTEDANSISTRING = 301,
	TDH_INTYPE_REVERSEDCOUNTEDSTRING = 302,
	TDH_INTYPE_REVERSEDCOUNTEDANSISTRING = 303,
	TDH_INTYPE_NONNULLTERMINATEDSTRING = 304,
	TDH_INTYPE_NONNULLTERMINATEDANSISTRING = 305,
	TDH_INTYPE_UNICODECHAR = 306,
	TDH_INTYPE_ANSICHAR = 307,
	TDH_INTYPE_SIZET = 308,
	TDH_INTYPE_HEXDUMP = 309,
	TDH_INTYPE_WBEMSID = 310,
}


[AllowDuplicates]
public enum _TDH_OUT_TYPE : int32
{
	TDH_OUTTYPE_NULL = 0,
	TDH_OUTTYPE_STRING = 1,
	TDH_OUTTYPE_DATETIME = 2,
	TDH_OUTTYPE_BYTE = 3,
	TDH_OUTTYPE_UNSIGNEDBYTE = 4,
	TDH_OUTTYPE_SHORT = 5,
	TDH_OUTTYPE_UNSIGNEDSHORT = 6,
	TDH_OUTTYPE_INT = 7,
	TDH_OUTTYPE_UNSIGNEDINT = 8,
	TDH_OUTTYPE_LONG = 9,
	TDH_OUTTYPE_UNSIGNEDLONG = 10,
	TDH_OUTTYPE_FLOAT = 11,
	TDH_OUTTYPE_DOUBLE = 12,
	TDH_OUTTYPE_BOOLEAN = 13,
	TDH_OUTTYPE_GUID = 14,
	TDH_OUTTYPE_HEXBINARY = 15,
	TDH_OUTTYPE_HEXINT8 = 16,
	TDH_OUTTYPE_HEXINT16 = 17,
	TDH_OUTTYPE_HEXINT32 = 18,
	TDH_OUTTYPE_HEXINT64 = 19,
	TDH_OUTTYPE_PID = 20,
	TDH_OUTTYPE_TID = 21,
	TDH_OUTTYPE_PORT = 22,
	TDH_OUTTYPE_IPV4 = 23,
	TDH_OUTTYPE_IPV6 = 24,
	TDH_OUTTYPE_SOCKETADDRESS = 25,
	TDH_OUTTYPE_CIMDATETIME = 26,
	TDH_OUTTYPE_ETWTIME = 27,
	TDH_OUTTYPE_XML = 28,
	TDH_OUTTYPE_ERRORCODE = 29,
	TDH_OUTTYPE_WIN32ERROR = 30,
	TDH_OUTTYPE_NTSTATUS = 31,
	TDH_OUTTYPE_HRESULT = 32,
	TDH_OUTTYPE_CULTURE_INSENSITIVE_DATETIME = 33,
	TDH_OUTTYPE_JSON = 34,
	TDH_OUTTYPE_UTF8 = 35,
	TDH_OUTTYPE_PKCS7_WITH_TYPE_INFO = 36,
	TDH_OUTTYPE_CODE_POINTER = 37,
	TDH_OUTTYPE_DATETIME_UTC = 38,
	TDH_OUTTYPE_REDUCEDSTRING = 300,
	TDH_OUTTYPE_NOPRINT = 301,
}


[AllowDuplicates]
public enum PROPERTY_FLAGS : int32
{
	PropertyStruct = 1,
	PropertyParamLength = 2,
	PropertyParamCount = 4,
	PropertyWBEMXmlFragment = 8,
	PropertyParamFixedLength = 16,
	PropertyParamFixedCount = 32,
	PropertyHasTags = 64,
	PropertyHasCustomSchema = 128,
}


[AllowDuplicates]
public enum DECODING_SOURCE : int32
{
	DecodingSourceXMLFile = 0,
	DecodingSourceWbem = 1,
	DecodingSourceWPP = 2,
	DecodingSourceTlg = 3,
	DecodingSourceMax = 4,
}


[AllowDuplicates]
public enum TEMPLATE_FLAGS : int32
{
	TEMPLATE_EVENT_DATA = 1,
	TEMPLATE_USER_DATA = 2,
	TEMPLATE_CONTROL_GUID = 4,
}


[AllowDuplicates]
public enum PAYLOAD_OPERATOR : int32
{
	PAYLOADFIELD_EQ = 0,
	PAYLOADFIELD_NE = 1,
	PAYLOADFIELD_LE = 2,
	PAYLOADFIELD_GT = 3,
	PAYLOADFIELD_LT = 4,
	PAYLOADFIELD_GE = 5,
	PAYLOADFIELD_BETWEEN = 6,
	PAYLOADFIELD_NOTBETWEEN = 7,
	PAYLOADFIELD_MODULO = 8,
	PAYLOADFIELD_CONTAINS = 20,
	PAYLOADFIELD_DOESNTCONTAIN = 21,
	PAYLOADFIELD_IS = 30,
	PAYLOADFIELD_ISNOT = 31,
	PAYLOADFIELD_INVALID = 32,
}


[AllowDuplicates]
public enum EVENT_FIELD_TYPE : int32
{
	EventKeywordInformation = 0,
	EventLevelInformation = 1,
	EventChannelInformation = 2,
	EventTaskInformation = 3,
	EventOpcodeInformation = 4,
	EventInformationMax = 5,
}


[AllowDuplicates]
public enum TDH_CONTEXT_TYPE : int32
{
	TDH_CONTEXT_WPP_TMFFILE = 0,
	TDH_CONTEXT_WPP_TMFSEARCHPATH = 1,
	TDH_CONTEXT_WPP_GMT = 2,
	TDH_CONTEXT_POINTERSIZE = 3,
	TDH_CONTEXT_PDB_PATH = 4,
	TDH_CONTEXT_MAXIMUM = 5,
}

#endregion

#region Function Pointers
public function uint32 PEVENT_TRACE_BUFFER_CALLBACKW(EVENT_TRACE_LOGFILEW* Logfile);

public function uint32 PEVENT_TRACE_BUFFER_CALLBACKA(EVENT_TRACE_LOGFILEA* Logfile);

public function void PEVENT_CALLBACK(EVENT_TRACE* pEvent);

public function void PEVENT_RECORD_CALLBACK(EVENT_RECORD* EventRecord);

public function uint32 WMIDPREQUEST(WMIDPREQUESTCODE RequestCode, void* RequestContext, uint32* BufferSize, void* Buffer);

public function void PENABLECALLBACK(in Guid SourceId, ENABLECALLBACK_ENABLED_STATE IsEnabled, uint8 Level, uint64 MatchAnyKeyword, uint64 MatchAllKeyword, EVENT_FILTER_DESCRIPTOR* FilterData, void* CallbackContext);

#endregion

#region Structs
[CRepr]
public struct WNODE_HEADER
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 CountLost;
		public HANDLE KernelHandle;
		public LARGE_INTEGER TimeStamp;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 Version;
			public uint32 Linkage;
		}
		public uint64 HistoricalContext;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint32 BufferSize;
	public uint32 ProviderId;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public Guid Guid;
	public uint32 ClientContext;
	public uint32 Flags;
}

[CRepr]
public struct OFFSETINSTANCEDATAANDLENGTH
{
	public uint32 OffsetInstanceData;
	public uint32 LengthInstanceData;
}

[CRepr]
public struct WNODE_ALL_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 FixedInstanceSize;
		public OFFSETINSTANCEDATAANDLENGTH* OffsetInstanceDataAndLength mut => &OffsetInstanceDataAndLength_impl;
		private OFFSETINSTANCEDATAANDLENGTH[ANYSIZE_ARRAY] OffsetInstanceDataAndLength_impl;
	}
	public WNODE_HEADER WnodeHeader;
	public uint32 DataBlockOffset;
	public uint32 InstanceCount;
	public uint32 OffsetInstanceNameOffsets;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WNODE_SINGLE_INSTANCE
{
	public WNODE_HEADER WnodeHeader;
	public uint32 OffsetInstanceName;
	public uint32 InstanceIndex;
	public uint32 DataBlockOffset;
	public uint32 SizeDataBlock;
	public uint8* VariableData mut => &VariableData_impl;
	private uint8[ANYSIZE_ARRAY] VariableData_impl;
}

[CRepr]
public struct WNODE_SINGLE_ITEM
{
	public WNODE_HEADER WnodeHeader;
	public uint32 OffsetInstanceName;
	public uint32 InstanceIndex;
	public uint32 ItemId;
	public uint32 DataBlockOffset;
	public uint32 SizeDataItem;
	public uint8* VariableData mut => &VariableData_impl;
	private uint8[ANYSIZE_ARRAY] VariableData_impl;
}

[CRepr]
public struct WNODE_METHOD_ITEM
{
	public WNODE_HEADER WnodeHeader;
	public uint32 OffsetInstanceName;
	public uint32 InstanceIndex;
	public uint32 MethodId;
	public uint32 DataBlockOffset;
	public uint32 SizeDataBlock;
	public uint8* VariableData mut => &VariableData_impl;
	private uint8[ANYSIZE_ARRAY] VariableData_impl;
}

[CRepr]
public struct WNODE_EVENT_ITEM
{
	public WNODE_HEADER WnodeHeader;
}

[CRepr]
public struct WNODE_EVENT_REFERENCE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 TargetInstanceIndex;
		public char16* TargetInstanceName mut => &TargetInstanceName_impl;
		private char16[ANYSIZE_ARRAY] TargetInstanceName_impl;
	}
	public WNODE_HEADER WnodeHeader;
	public Guid TargetGuid;
	public uint32 TargetDataBlockSize;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WNODE_TOO_SMALL
{
	public WNODE_HEADER WnodeHeader;
	public uint32 SizeNeeded;
}

[CRepr]
public struct WMIREGGUIDW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 InstanceNameList;
		public uint32 BaseNameOffset;
		public uint Pdo;
		public uint InstanceInfo;
	}
	public Guid Guid;
	public uint32 Flags;
	public uint32 InstanceCount;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WMIREGINFOW
{
	public uint32 BufferSize;
	public uint32 NextWmiRegInfo;
	public uint32 RegistryPath;
	public uint32 MofResourceName;
	public uint32 GuidCount;
	public WMIREGGUIDW* WmiRegGuid mut => &WmiRegGuid_impl;
	private WMIREGGUIDW[ANYSIZE_ARRAY] WmiRegGuid_impl;
}

[CRepr]
public struct EVENT_TRACE_HEADER
{
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 ClientContext;
			public uint32 Flags;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 KernelTime;
			public uint32 UserTime;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public uint64 ProcessorTime;
		public using _Anonymous2_e__Struct Anonymous2;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Class_e__Struct
		{
			public uint8 Type;
			public uint8 Level;
			public uint16 Version;
		}
		public uint32 Version;
		public _Class_e__Struct Class;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 HeaderType;
			public uint8 MarkerFlags;
		}
		public uint16 FieldTypeFlags;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public Guid Guid;
		public uint64 GuidPtr;
	}
	public uint16 Size;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 ThreadId;
	public uint32 ProcessId;
	public LARGE_INTEGER TimeStamp;
	public using _Anonymous3_e__Union Anonymous3;
	public using _Anonymous4_e__Union Anonymous4;
}

[CRepr]
public struct EVENT_INSTANCE_HEADER
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 EventId;
			public uint32 Flags;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 KernelTime;
			public uint32 UserTime;
		}
		public using _Anonymous1_e__Struct Anonymous1;
		public uint64 ProcessorTime;
		public using _Anonymous2_e__Struct Anonymous2;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Class_e__Struct
		{
			public uint8 Type;
			public uint8 Level;
			public uint16 Version;
		}
		public uint32 Version;
		public _Class_e__Struct Class;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 HeaderType;
			public uint8 MarkerFlags;
		}
		public uint16 FieldTypeFlags;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint16 Size;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 ThreadId;
	public uint32 ProcessId;
	public LARGE_INTEGER TimeStamp;
	public uint64 RegHandle;
	public uint32 InstanceId;
	public uint32 ParentInstanceId;
	public using _Anonymous3_e__Union Anonymous3;
	public uint64 ParentRegHandle;
}

[CRepr]
public struct MOF_FIELD
{
	public uint64 DataPtr;
	public uint32 Length;
	public uint32 DataType;
}

[CRepr]
public struct TRACE_LOGFILE_HEADER
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 StartBuffers;
			public uint32 PointerSize;
			public uint32 EventsLost;
			public uint32 CpuSpeedInMHz;
		}
		public Guid LogInstanceGuid;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _VersionDetail_e__Struct
		{
			public uint8 MajorVersion;
			public uint8 MinorVersion;
			public uint8 SubVersion;
			public uint8 SubMinorVersion;
		}
		public uint32 Version;
		public _VersionDetail_e__Struct VersionDetail;
	}
	public uint32 BufferSize;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 ProviderVersion;
	public uint32 NumberOfProcessors;
	public LARGE_INTEGER EndTime;
	public uint32 TimerResolution;
	public uint32 MaximumFileSize;
	public uint32 LogFileMode;
	public uint32 BuffersWritten;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR LoggerName;
	public PWSTR LogFileName;
	public TIME_ZONE_INFORMATION TimeZone;
	public LARGE_INTEGER BootTime;
	public LARGE_INTEGER PerfFreq;
	public LARGE_INTEGER StartTime;
	public uint32 ReservedFlags;
	public uint32 BuffersLost;
}

[CRepr]
public struct TRACE_LOGFILE_HEADER32
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 StartBuffers;
			public uint32 PointerSize;
			public uint32 EventsLost;
			public uint32 CpuSpeedInMHz;
		}
		public Guid LogInstanceGuid;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _VersionDetail_e__Struct
		{
			public uint8 MajorVersion;
			public uint8 MinorVersion;
			public uint8 SubVersion;
			public uint8 SubMinorVersion;
		}
		public uint32 Version;
		public _VersionDetail_e__Struct VersionDetail;
	}
	public uint32 BufferSize;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 ProviderVersion;
	public uint32 NumberOfProcessors;
	public LARGE_INTEGER EndTime;
	public uint32 TimerResolution;
	public uint32 MaximumFileSize;
	public uint32 LogFileMode;
	public uint32 BuffersWritten;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 LoggerName;
	public uint32 LogFileName;
	public TIME_ZONE_INFORMATION TimeZone;
	public LARGE_INTEGER BootTime;
	public LARGE_INTEGER PerfFreq;
	public LARGE_INTEGER StartTime;
	public uint32 ReservedFlags;
	public uint32 BuffersLost;
}

[CRepr]
public struct TRACE_LOGFILE_HEADER64
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 StartBuffers;
			public uint32 PointerSize;
			public uint32 EventsLost;
			public uint32 CpuSpeedInMHz;
		}
		public Guid LogInstanceGuid;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _VersionDetail_e__Struct
		{
			public uint8 MajorVersion;
			public uint8 MinorVersion;
			public uint8 SubVersion;
			public uint8 SubMinorVersion;
		}
		public uint32 Version;
		public _VersionDetail_e__Struct VersionDetail;
	}
	public uint32 BufferSize;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 ProviderVersion;
	public uint32 NumberOfProcessors;
	public LARGE_INTEGER EndTime;
	public uint32 TimerResolution;
	public uint32 MaximumFileSize;
	public uint32 LogFileMode;
	public uint32 BuffersWritten;
	public using _Anonymous2_e__Union Anonymous2;
	public uint64 LoggerName;
	public uint64 LogFileName;
	public TIME_ZONE_INFORMATION TimeZone;
	public LARGE_INTEGER BootTime;
	public LARGE_INTEGER PerfFreq;
	public LARGE_INTEGER StartTime;
	public uint32 ReservedFlags;
	public uint32 BuffersLost;
}

[CRepr]
public struct EVENT_INSTANCE_INFO
{
	public HANDLE RegHandle;
	public uint32 InstanceId;
}

[CRepr]
public struct EVENT_TRACE_PROPERTIES
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int32 AgeLimit;
		public int32 FlushThreshold;
	}
	public WNODE_HEADER Wnode;
	public uint32 BufferSize;
	public uint32 MinimumBuffers;
	public uint32 MaximumBuffers;
	public uint32 MaximumFileSize;
	public uint32 LogFileMode;
	public uint32 FlushTimer;
	public EVENT_TRACE_FLAG EnableFlags;
	public using _Anonymous_e__Union Anonymous;
	public uint32 NumberOfBuffers;
	public uint32 FreeBuffers;
	public uint32 EventsLost;
	public uint32 BuffersWritten;
	public uint32 LogBuffersLost;
	public uint32 RealTimeBuffersLost;
	public HANDLE LoggerThreadId;
	public uint32 LogFileNameOffset;
	public uint32 LoggerNameOffset;
}

[CRepr]
public struct EVENT_TRACE_PROPERTIES_V2
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint64 V2Options;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 V2Control;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public int32 AgeLimit;
		public int32 FlushThreshold;
	}
	public WNODE_HEADER Wnode;
	public uint32 BufferSize;
	public uint32 MinimumBuffers;
	public uint32 MaximumBuffers;
	public uint32 MaximumFileSize;
	public uint32 LogFileMode;
	public uint32 FlushTimer;
	public EVENT_TRACE_FLAG EnableFlags;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 NumberOfBuffers;
	public uint32 FreeBuffers;
	public uint32 EventsLost;
	public uint32 BuffersWritten;
	public uint32 LogBuffersLost;
	public uint32 RealTimeBuffersLost;
	public HANDLE LoggerThreadId;
	public uint32 LogFileNameOffset;
	public uint32 LoggerNameOffset;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 FilterDescCount;
	public EVENT_FILTER_DESCRIPTOR* FilterDesc;
	public using _Anonymous3_e__Union Anonymous3;
}

[CRepr]
public struct TRACE_GUID_REGISTRATION
{
	public Guid* Guid;
	public HANDLE RegHandle;
}

[CRepr]
public struct TRACE_GUID_PROPERTIES
{
	public Guid Guid;
	public uint32 GuidType;
	public uint32 LoggerId;
	public uint32 EnableLevel;
	public uint32 EnableFlags;
	public BOOLEAN IsEnable;
}

[CRepr]
public struct ETW_BUFFER_CONTEXT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 ProcessorNumber;
			public uint8 Alignment;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint16 ProcessorIndex;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint16 LoggerId;
}

[CRepr]
public struct TRACE_ENABLE_INFO
{
	public uint32 IsEnabled;
	public uint8 Level;
	public uint8 Reserved1;
	public uint16 LoggerId;
	public uint32 EnableProperty;
	public uint32 Reserved2;
	public uint64 MatchAnyKeyword;
	public uint64 MatchAllKeyword;
}

[CRepr]
public struct TRACE_PROVIDER_INSTANCE_INFO
{
	public uint32 NextOffset;
	public uint32 EnableCount;
	public uint32 Pid;
	public uint32 Flags;
}

[CRepr]
public struct TRACE_GUID_INFO
{
	public uint32 InstanceCount;
	public uint32 Reserved;
}

[CRepr]
public struct PROFILE_SOURCE_INFO
{
	public uint32 NextEntryOffset;
	public uint32 Source;
	public uint32 MinInterval;
	public uint32 MaxInterval;
	public uint64 Reserved;
	public char16* Description mut => &Description_impl;
	private char16[ANYSIZE_ARRAY] Description_impl;
}

[CRepr]
public struct ETW_PMC_COUNTER_OWNER
{
	public ETW_PMC_COUNTER_OWNER_TYPE OwnerType;
	public uint32 ProfileSource;
	public uint32 OwnerTag;
}

[CRepr]
public struct ETW_PMC_COUNTER_OWNERSHIP_STATUS
{
	public uint32 ProcessorNumber;
	public uint32 NumberOfCounters;
	public ETW_PMC_COUNTER_OWNER* CounterOwners mut => &CounterOwners_impl;
	private ETW_PMC_COUNTER_OWNER[ANYSIZE_ARRAY] CounterOwners_impl;
}

[CRepr]
public struct EVENT_TRACE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 ClientContext;
		public ETW_BUFFER_CONTEXT BufferContext;
	}
	public EVENT_TRACE_HEADER Header;
	public uint32 InstanceId;
	public uint32 ParentInstanceId;
	public Guid ParentGuid;
	public void* MofData;
	public uint32 MofLength;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct EVENT_TRACE_LOGFILEW
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 LogFileMode;
		public uint32 ProcessTraceMode;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public PEVENT_CALLBACK EventCallback;
		public PEVENT_RECORD_CALLBACK EventRecordCallback;
	}
	public PWSTR LogFileName;
	public PWSTR LoggerName;
	public int64 CurrentTime;
	public uint32 BuffersRead;
	public using _Anonymous1_e__Union Anonymous1;
	public EVENT_TRACE CurrentEvent;
	public TRACE_LOGFILE_HEADER LogfileHeader;
	public PEVENT_TRACE_BUFFER_CALLBACKW BufferCallback;
	public uint32 BufferSize;
	public uint32 Filled;
	public uint32 EventsLost;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 IsKernelTrace;
	public void* Context;
}

[CRepr]
public struct EVENT_TRACE_LOGFILEA
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 LogFileMode;
		public uint32 ProcessTraceMode;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public PEVENT_CALLBACK EventCallback;
		public PEVENT_RECORD_CALLBACK EventRecordCallback;
	}
	public PSTR LogFileName;
	public PSTR LoggerName;
	public int64 CurrentTime;
	public uint32 BuffersRead;
	public using _Anonymous1_e__Union Anonymous1;
	public EVENT_TRACE CurrentEvent;
	public TRACE_LOGFILE_HEADER LogfileHeader;
	public PEVENT_TRACE_BUFFER_CALLBACKA BufferCallback;
	public uint32 BufferSize;
	public uint32 Filled;
	public uint32 EventsLost;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 IsKernelTrace;
	public void* Context;
}

[CRepr]
public struct ENABLE_TRACE_PARAMETERS_V1
{
	public uint32 Version;
	public uint32 EnableProperty;
	public uint32 ControlFlags;
	public Guid SourceId;
	public EVENT_FILTER_DESCRIPTOR* EnableFilterDesc;
}

[CRepr]
public struct ENABLE_TRACE_PARAMETERS
{
	public uint32 Version;
	public uint32 EnableProperty;
	public uint32 ControlFlags;
	public Guid SourceId;
	public EVENT_FILTER_DESCRIPTOR* EnableFilterDesc;
	public uint32 FilterDescCount;
}

[CRepr]
public struct CLASSIC_EVENT_ID
{
	public Guid EventGuid;
	public uint8 Type;
	public uint8[7] Reserved;
}

[CRepr]
public struct TRACE_STACK_CACHING_INFO
{
	public BOOLEAN Enabled;
	public uint32 CacheSize;
	public uint32 BucketCount;
}

[CRepr]
public struct TRACE_PROFILE_INTERVAL
{
	public uint32 Source;
	public uint32 Interval;
}

[CRepr]
public struct TRACE_VERSION_INFO
{
	public uint32 EtwTraceProcessingVersion;
	public uint32 Reserved;
}

[CRepr]
public struct TRACE_PERIODIC_CAPTURE_STATE_INFO
{
	public uint32 CaptureStateFrequencyInSeconds;
	public uint16 ProviderCount;
	public uint16 Reserved;
}

[CRepr]
public struct ETW_TRACE_PARTITION_INFORMATION
{
	public Guid PartitionId;
	public Guid ParentId;
	public int64 QpcOffsetFromRoot;
	public uint32 PartitionType;
}

[CRepr]
public struct ETW_TRACE_PARTITION_INFORMATION_V2
{
	public int64 QpcOffsetFromRoot;
	public uint32 PartitionType;
	public PWSTR PartitionId;
	public PWSTR ParentId;
}

[CRepr]
public struct EVENT_DATA_DESCRIPTOR
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 Type;
			public uint8 Reserved1;
			public uint16 Reserved2;
		}
		public uint32 Reserved;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint64 Ptr;
	public uint32 Size;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct EVENT_DESCRIPTOR
{
	public uint16 Id;
	public uint8 Version;
	public uint8 Channel;
	public uint8 Level;
	public uint8 Opcode;
	public uint16 Task;
	public uint64 Keyword;
}

[CRepr]
public struct EVENT_FILTER_DESCRIPTOR
{
	public uint64 Ptr;
	public uint32 Size;
	public uint32 Type;
}

[CRepr]
public struct EVENT_FILTER_HEADER
{
	public uint16 Id;
	public uint8 Version;
	public uint8[5] Reserved;
	public uint64 InstanceId;
	public uint32 Size;
	public uint32 NextOffset;
}

[CRepr]
public struct EVENT_FILTER_EVENT_ID
{
	public BOOLEAN FilterIn;
	public uint8 Reserved;
	public uint16 Count;
	public uint16* Events mut => &Events_impl;
	private uint16[ANYSIZE_ARRAY] Events_impl;
}

[CRepr]
public struct EVENT_FILTER_EVENT_NAME
{
	public uint64 MatchAnyKeyword;
	public uint64 MatchAllKeyword;
	public uint8 Level;
	public BOOLEAN FilterIn;
	public uint16 NameCount;
	public uint8* Names mut => &Names_impl;
	private uint8[ANYSIZE_ARRAY] Names_impl;
}

[CRepr]
public struct EVENT_FILTER_LEVEL_KW
{
	public uint64 MatchAnyKeyword;
	public uint64 MatchAllKeyword;
	public uint8 Level;
	public BOOLEAN FilterIn;
}

[CRepr]
public struct EVENT_HEADER_EXTENDED_DATA_ITEM
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint16 _bitfield;
	}
	public uint16 Reserved1;
	public uint16 ExtType;
	public using _Anonymous_e__Struct Anonymous;
	public uint16 DataSize;
	public uint64 DataPtr;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_INSTANCE
{
	public uint32 InstanceId;
	public uint32 ParentInstanceId;
	public Guid ParentGuid;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_RELATED_ACTIVITYID
{
	public Guid RelatedActivityId;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_TS_ID
{
	public uint32 SessionId;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_STACK_TRACE32
{
	public uint64 MatchId;
	public uint32* Address mut => &Address_impl;
	private uint32[ANYSIZE_ARRAY] Address_impl;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_STACK_TRACE64
{
	public uint64 MatchId;
	public uint64* Address mut => &Address_impl;
	private uint64[ANYSIZE_ARRAY] Address_impl;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_STACK_KEY32
{
	public uint64 MatchId;
	public uint32 StackKey;
	public uint32 Padding;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_STACK_KEY64
{
	public uint64 MatchId;
	public uint64 StackKey;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_PEBS_INDEX
{
	public uint64 PebsIndex;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_PMC_COUNTERS
{
	public uint64* Counter mut => &Counter_impl;
	private uint64[ANYSIZE_ARRAY] Counter_impl;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_PROCESS_START_KEY
{
	public uint64 ProcessStartKey;
}

[CRepr]
public struct EVENT_EXTENDED_ITEM_EVENT_KEY
{
	public uint64 Key;
}

[CRepr]
public struct EVENT_HEADER
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 KernelTime;
			public uint32 UserTime;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint64 ProcessorTime;
	}
	public uint16 Size;
	public uint16 HeaderType;
	public uint16 Flags;
	public uint16 EventProperty;
	public uint32 ThreadId;
	public uint32 ProcessId;
	public LARGE_INTEGER TimeStamp;
	public Guid ProviderId;
	public EVENT_DESCRIPTOR EventDescriptor;
	public using _Anonymous_e__Union Anonymous;
	public Guid ActivityId;
}

[CRepr]
public struct EVENT_RECORD
{
	public EVENT_HEADER EventHeader;
	public ETW_BUFFER_CONTEXT BufferContext;
	public uint16 ExtendedDataCount;
	public uint16 UserDataLength;
	public EVENT_HEADER_EXTENDED_DATA_ITEM* ExtendedData;
	public void* UserData;
	public void* UserContext;
}

[CRepr]
public struct EVENT_MAP_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 Value;
		public uint32 InputOffset;
	}
	public uint32 OutputOffset;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct EVENT_MAP_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public MAP_VALUETYPE MapEntryValueType;
		public uint32 FormatStringOffset;
	}
	public uint32 NameOffset;
	public MAP_FLAGS Flag;
	public uint32 EntryCount;
	public using _Anonymous_e__Union Anonymous;
	public EVENT_MAP_ENTRY* MapEntryArray mut => &MapEntryArray_impl;
	private EVENT_MAP_ENTRY[ANYSIZE_ARRAY] MapEntryArray_impl;
}

[CRepr]
public struct EVENT_PROPERTY_INFO
{
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public uint32 Reserved;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint16 count;
		public uint16 countPropertyIndex;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _customSchemaType
		{
			public uint16 InType;
			public uint16 OutType;
			public uint32 CustomSchemaOffset;
		}
		[CRepr]
		public struct _nonStructType
		{
			public uint16 InType;
			public uint16 OutType;
			public uint32 MapNameOffset;
		}
		[CRepr]
		public struct _structType
		{
			public uint16 StructStartIndex;
			public uint16 NumOfStructMembers;
			public uint32 padding;
		}
		public _nonStructType nonStructType;
		public _structType structType;
		public _customSchemaType customSchemaType;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public uint16 length;
		public uint16 lengthPropertyIndex;
	}
	public PROPERTY_FLAGS Flags;
	public uint32 NameOffset;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public using _Anonymous4_e__Union Anonymous4;
}

[CRepr]
public struct TRACE_EVENT_INFO
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public TEMPLATE_FLAGS Flags;
		public using _Anonymous_e__Struct Anonymous;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 EventNameOffset;
		public uint32 ActivityIDNameOffset;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 EventAttributesOffset;
		public uint32 RelatedActivityIDNameOffset;
	}
	public Guid ProviderGuid;
	public Guid EventGuid;
	public EVENT_DESCRIPTOR EventDescriptor;
	public DECODING_SOURCE DecodingSource;
	public uint32 ProviderNameOffset;
	public uint32 LevelNameOffset;
	public uint32 ChannelNameOffset;
	public uint32 KeywordsNameOffset;
	public uint32 TaskNameOffset;
	public uint32 OpcodeNameOffset;
	public uint32 EventMessageOffset;
	public uint32 ProviderMessageOffset;
	public uint32 BinaryXMLOffset;
	public uint32 BinaryXMLSize;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 PropertyCount;
	public uint32 TopLevelPropertyCount;
	public using _Anonymous3_e__Union Anonymous3;
	public EVENT_PROPERTY_INFO* EventPropertyInfoArray mut => &EventPropertyInfoArray_impl;
	private EVENT_PROPERTY_INFO[ANYSIZE_ARRAY] EventPropertyInfoArray_impl;
}

[CRepr]
public struct PROPERTY_DATA_DESCRIPTOR
{
	public uint64 PropertyName;
	public uint32 ArrayIndex;
	public uint32 Reserved;
}

[CRepr]
public struct PAYLOAD_FILTER_PREDICATE
{
	public PWSTR FieldName;
	public uint16 CompareOp;
	public PWSTR Value;
}

[CRepr]
public struct PROVIDER_FILTER_INFO
{
	public uint8 Id;
	public uint8 Version;
	public uint32 MessageOffset;
	public uint32 Reserved;
	public uint32 PropertyCount;
	public EVENT_PROPERTY_INFO* EventPropertyInfoArray mut => &EventPropertyInfoArray_impl;
	private EVENT_PROPERTY_INFO[ANYSIZE_ARRAY] EventPropertyInfoArray_impl;
}

[CRepr]
public struct PROVIDER_FIELD_INFO
{
	public uint32 NameOffset;
	public uint32 DescriptionOffset;
	public uint64 Value;
}

[CRepr]
public struct PROVIDER_FIELD_INFOARRAY
{
	public uint32 NumberOfElements;
	public EVENT_FIELD_TYPE FieldType;
	public PROVIDER_FIELD_INFO* FieldInfoArray mut => &FieldInfoArray_impl;
	private PROVIDER_FIELD_INFO[ANYSIZE_ARRAY] FieldInfoArray_impl;
}

[CRepr]
public struct TRACE_PROVIDER_INFO
{
	public Guid ProviderGuid;
	public uint32 SchemaSource;
	public uint32 ProviderNameOffset;
}

[CRepr]
public struct PROVIDER_ENUMERATION_INFO
{
	public uint32 NumberOfProviders;
	public uint32 Reserved;
	public TRACE_PROVIDER_INFO* TraceProviderInfoArray mut => &TraceProviderInfoArray_impl;
	private TRACE_PROVIDER_INFO[ANYSIZE_ARRAY] TraceProviderInfoArray_impl;
}

[CRepr]
public struct PROVIDER_EVENT_INFO
{
	public uint32 NumberOfEvents;
	public uint32 Reserved;
	public EVENT_DESCRIPTOR* EventDescriptorsArray mut => &EventDescriptorsArray_impl;
	private EVENT_DESCRIPTOR[ANYSIZE_ARRAY] EventDescriptorsArray_impl;
}

[CRepr]
public struct TDH_CONTEXT
{
	public uint64 ParameterValue;
	public TDH_CONTEXT_TYPE ParameterType;
	public uint32 ParameterSize;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CTraceRelogger = .(0x7b40792d, 0x05ff, 0x44c4, 0x90, 0x58, 0xf4, 0x40, 0xc7, 0x1f, 0x17, 0xd4);


}
#endregion

#region COM Types
[CRepr]struct ITraceEvent : IUnknown
{
	public new const Guid IID = .(0x8cc97f40, 0x9028, 0x4ff3, 0x9b, 0x62, 0x7d, 0x1f, 0x79, 0xca, 0x7b, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITraceEvent** NewEvent) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** UserContext) GetUserContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EVENT_RECORD** EventRecord) GetEventRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* Payload, uint32 PayloadSize) SetPayload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EVENT_DESCRIPTOR* EventDescriptor) SetEventDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ProcessId) SetProcessId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ProcessorIndex) SetProcessorIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ThreadId) SetThreadId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 KernelTime, uint32 UserTime) SetThreadTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ActivityId) SetActivityId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER* TimeStamp) SetTimeStamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ProviderId) SetProviderId;
	}


	public HRESULT Clone(ITraceEvent** NewEvent) mut => VT.[Friend]Clone(&this, NewEvent);

	public HRESULT GetUserContext(void** UserContext) mut => VT.[Friend]GetUserContext(&this, UserContext);

	public HRESULT GetEventRecord(EVENT_RECORD** EventRecord) mut => VT.[Friend]GetEventRecord(&this, EventRecord);

	public HRESULT SetPayload(uint8* Payload, uint32 PayloadSize) mut => VT.[Friend]SetPayload(&this, Payload, PayloadSize);

	public HRESULT SetEventDescriptor(EVENT_DESCRIPTOR* EventDescriptor) mut => VT.[Friend]SetEventDescriptor(&this, EventDescriptor);

	public HRESULT SetProcessId(uint32 ProcessId) mut => VT.[Friend]SetProcessId(&this, ProcessId);

	public HRESULT SetProcessorIndex(uint32 ProcessorIndex) mut => VT.[Friend]SetProcessorIndex(&this, ProcessorIndex);

	public HRESULT SetThreadId(uint32 ThreadId) mut => VT.[Friend]SetThreadId(&this, ThreadId);

	public HRESULT SetThreadTimes(uint32 KernelTime, uint32 UserTime) mut => VT.[Friend]SetThreadTimes(&this, KernelTime, UserTime);

	public HRESULT SetActivityId(in Guid ActivityId) mut => VT.[Friend]SetActivityId(&this, ActivityId);

	public HRESULT SetTimeStamp(LARGE_INTEGER* TimeStamp) mut => VT.[Friend]SetTimeStamp(&this, TimeStamp);

	public HRESULT SetProviderId(in Guid ProviderId) mut => VT.[Friend]SetProviderId(&this, ProviderId);
}

[CRepr]struct ITraceEventCallback : IUnknown
{
	public new const Guid IID = .(0x3ed25501, 0x593f, 0x43e9, 0x8f, 0x38, 0x3a, 0xb4, 0x6f, 0x5a, 0x4a, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITraceEvent* HeaderEvent, ITraceRelogger* Relogger) OnBeginProcessTrace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITraceRelogger* Relogger) OnFinalizeProcessTrace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITraceEvent* Event, ITraceRelogger* Relogger) OnEvent;
	}


	public HRESULT OnBeginProcessTrace(ITraceEvent* HeaderEvent, ITraceRelogger* Relogger) mut => VT.[Friend]OnBeginProcessTrace(&this, HeaderEvent, Relogger);

	public HRESULT OnFinalizeProcessTrace(ITraceRelogger* Relogger) mut => VT.[Friend]OnFinalizeProcessTrace(&this, Relogger);

	public HRESULT OnEvent(ITraceEvent* Event, ITraceRelogger* Relogger) mut => VT.[Friend]OnEvent(&this, Event, Relogger);
}

[CRepr]struct ITraceRelogger : IUnknown
{
	public new const Guid IID = .(0xf754ad43, 0x3bcc, 0x4286, 0x80, 0x09, 0x9c, 0x5d, 0xa2, 0x14, 0xe8, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR LogfileName, void* UserContext, RELOGSTREAM_HANDLE* TraceHandle) AddLogfileTraceStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR LoggerName, void* UserContext, RELOGSTREAM_HANDLE* TraceHandle) AddRealtimeTraceStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITraceEventCallback* Callback) RegisterCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITraceEvent* Event) Inject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RELOGSTREAM_HANDLE TraceHandle, uint32 Flags, ITraceEvent** Event) CreateEventInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ProcessTrace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR LogfileName) SetOutputFilename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOLEAN CompressionMode) SetCompressionMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT AddLogfileTraceStream(BSTR LogfileName, void* UserContext, RELOGSTREAM_HANDLE* TraceHandle) mut => VT.[Friend]AddLogfileTraceStream(&this, LogfileName, UserContext, TraceHandle);

	public HRESULT AddRealtimeTraceStream(BSTR LoggerName, void* UserContext, RELOGSTREAM_HANDLE* TraceHandle) mut => VT.[Friend]AddRealtimeTraceStream(&this, LoggerName, UserContext, TraceHandle);

	public HRESULT RegisterCallback(ITraceEventCallback* Callback) mut => VT.[Friend]RegisterCallback(&this, Callback);

	public HRESULT Inject(ITraceEvent* Event) mut => VT.[Friend]Inject(&this, Event);

	public HRESULT CreateEventInstance(RELOGSTREAM_HANDLE TraceHandle, uint32 Flags, ITraceEvent** Event) mut => VT.[Friend]CreateEventInstance(&this, TraceHandle, Flags, Event);

	public HRESULT ProcessTrace() mut => VT.[Friend]ProcessTrace(&this);

	public HRESULT SetOutputFilename(BSTR LogfileName) mut => VT.[Friend]SetOutputFilename(&this, LogfileName);

	public HRESULT SetCompressionMode(BOOLEAN CompressionMode) mut => VT.[Friend]SetCompressionMode(&this, CompressionMode);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

#endregion

#region Functions
public static
{
	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR StartTraceW(CONTROLTRACE_HANDLE* TraceHandle, PWSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR StartTraceA(CONTROLTRACE_HANDLE* TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);
	public static WIN32_ERROR StartTrace(CONTROLTRACE_HANDLE* TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties) => StartTraceA(TraceHandle, InstanceName, Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR StopTraceW(CONTROLTRACE_HANDLE TraceHandle, PWSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR StopTraceA(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);
	public static WIN32_ERROR StopTrace(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties) => StopTraceA(TraceHandle, InstanceName, Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR QueryTraceW(CONTROLTRACE_HANDLE TraceHandle, PWSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR QueryTraceA(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);
	public static WIN32_ERROR QueryTrace(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties) => QueryTraceA(TraceHandle, InstanceName, Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR UpdateTraceW(CONTROLTRACE_HANDLE TraceHandle, PWSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR UpdateTraceA(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);
	public static WIN32_ERROR UpdateTrace(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties) => UpdateTraceA(TraceHandle, InstanceName, Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR FlushTraceW(CONTROLTRACE_HANDLE TraceHandle, PWSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR FlushTraceA(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties);
	public static WIN32_ERROR FlushTrace(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties) => FlushTraceA(TraceHandle, InstanceName, Properties);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ControlTraceW(CONTROLTRACE_HANDLE TraceHandle, PWSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties, EVENT_TRACE_CONTROL ControlCode);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ControlTraceA(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties, EVENT_TRACE_CONTROL ControlCode);
	public static WIN32_ERROR ControlTrace(CONTROLTRACE_HANDLE TraceHandle, PSTR InstanceName, EVENT_TRACE_PROPERTIES* Properties, EVENT_TRACE_CONTROL ControlCode) => ControlTraceA(TraceHandle, InstanceName, Properties, ControlCode);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR QueryAllTracesW(EVENT_TRACE_PROPERTIES** PropertyArray, uint32 PropertyArrayCount, uint32* LoggerCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR QueryAllTracesA(EVENT_TRACE_PROPERTIES** PropertyArray, uint32 PropertyArrayCount, uint32* LoggerCount);
	public static WIN32_ERROR QueryAllTraces(EVENT_TRACE_PROPERTIES** PropertyArray, uint32 PropertyArrayCount, uint32* LoggerCount) => QueryAllTracesA(PropertyArray, PropertyArrayCount, LoggerCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR EnableTrace(uint32 Enable, uint32 EnableFlag, uint32 EnableLevel, in Guid ControlGuid, CONTROLTRACE_HANDLE TraceHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR EnableTraceEx(in Guid ProviderId, Guid* SourceId, CONTROLTRACE_HANDLE TraceHandle, uint32 IsEnabled, uint8 Level, uint64 MatchAnyKeyword, uint64 MatchAllKeyword, uint32 EnableProperty, EVENT_FILTER_DESCRIPTOR* EnableFilterDesc);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR EnableTraceEx2(CONTROLTRACE_HANDLE TraceHandle, in Guid ProviderId, uint32 ControlCode, uint8 Level, uint64 MatchAnyKeyword, uint64 MatchAllKeyword, uint32 Timeout, ENABLE_TRACE_PARAMETERS* EnableParameters);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR EnumerateTraceGuidsEx(TRACE_QUERY_INFO_CLASS TraceQueryInfoClass, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR TraceSetInformation(CONTROLTRACE_HANDLE SessionHandle, TRACE_QUERY_INFO_CLASS InformationClass, void* TraceInformation, uint32 InformationLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR TraceQueryInformation(CONTROLTRACE_HANDLE SessionHandle, TRACE_QUERY_INFO_CLASS InformationClass, void* TraceInformation, uint32 InformationLength, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR CreateTraceInstanceId(HANDLE RegHandle, EVENT_INSTANCE_INFO* InstInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR TraceEvent(uint64 TraceHandle, EVENT_TRACE_HEADER* EventTrace);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceEventInstance(uint64 TraceHandle, EVENT_INSTANCE_HEADER* EventTrace, EVENT_INSTANCE_INFO* InstInfo, EVENT_INSTANCE_INFO* ParentInstInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterTraceGuidsW(WMIDPREQUEST RequestAddress, void* RequestContext, in Guid ControlGuid, uint32 GuidCount, TRACE_GUID_REGISTRATION* TraceGuidReg, PWSTR MofImagePath, PWSTR MofResourceName, uint64* RegistrationHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterTraceGuidsA(WMIDPREQUEST RequestAddress, void* RequestContext, in Guid ControlGuid, uint32 GuidCount, TRACE_GUID_REGISTRATION* TraceGuidReg, PSTR MofImagePath, PSTR MofResourceName, uint64* RegistrationHandle);
	public static uint32 RegisterTraceGuids(WMIDPREQUEST RequestAddress, void* RequestContext, in Guid ControlGuid, uint32 GuidCount, TRACE_GUID_REGISTRATION* TraceGuidReg, PSTR MofImagePath, PSTR MofResourceName, uint64* RegistrationHandle) => RegisterTraceGuidsA(RequestAddress, RequestContext, ControlGuid, GuidCount, TraceGuidReg, MofImagePath, MofResourceName, RegistrationHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR EnumerateTraceGuids(TRACE_GUID_PROPERTIES** GuidPropertiesArray, uint32 PropertyArrayCount, uint32* GuidCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 UnregisterTraceGuids(uint64 RegistrationHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 GetTraceLoggerHandle(void* Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 GetTraceEnableLevel(uint64 TraceHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetTraceEnableFlags(uint64 TraceHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PROCESSTRACE_HANDLE OpenTraceW(EVENT_TRACE_LOGFILEW* Logfile);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ProcessTrace(PROCESSTRACE_HANDLE* HandleArray, uint32 HandleCount, FILETIME* StartTime, FILETIME* EndTime);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR CloseTrace(PROCESSTRACE_HANDLE TraceHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR QueryTraceProcessingHandle(PROCESSTRACE_HANDLE ProcessingHandle, ETW_PROCESS_HANDLE_INFO_TYPE InformationClass, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PROCESSTRACE_HANDLE OpenTraceA(EVENT_TRACE_LOGFILEA* Logfile);
	public static PROCESSTRACE_HANDLE OpenTrace(EVENT_TRACE_LOGFILEA* Logfile) => OpenTraceA(Logfile);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SetTraceCallback(in Guid pGuid, PEVENT_CALLBACK EventCallback);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR RemoveTraceCallback(in Guid pGuid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR TraceMessage(uint64 LoggerHandle, TRACE_MESSAGE_FLAGS MessageFlags, in Guid MessageGuid, uint16 MessageNumber);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR TraceMessageVa(uint64 LoggerHandle, TRACE_MESSAGE_FLAGS MessageFlags, in Guid MessageGuid, uint16 MessageNumber, int8* MessageArgList);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventRegister(in Guid ProviderId, PENABLECALLBACK EnableCallback, void* CallbackContext, uint64* RegHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventUnregister(uint64 RegHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventSetInformation(uint64 RegHandle, EVENT_INFO_CLASS InformationClass, void* EventInformation, uint32 InformationLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN EventEnabled(uint64 RegHandle, EVENT_DESCRIPTOR* EventDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN EventProviderEnabled(uint64 RegHandle, uint8 Level, uint64 Keyword);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventWrite(uint64 RegHandle, EVENT_DESCRIPTOR* EventDescriptor, uint32 UserDataCount, EVENT_DATA_DESCRIPTOR* UserData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventWriteTransfer(uint64 RegHandle, EVENT_DESCRIPTOR* EventDescriptor, Guid* ActivityId, Guid* RelatedActivityId, uint32 UserDataCount, EVENT_DATA_DESCRIPTOR* UserData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventWriteEx(uint64 RegHandle, EVENT_DESCRIPTOR* EventDescriptor, uint64 Filter, uint32 Flags, Guid* ActivityId, Guid* RelatedActivityId, uint32 UserDataCount, EVENT_DATA_DESCRIPTOR* UserData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventWriteString(uint64 RegHandle, uint8 Level, uint64 Keyword, PWSTR String);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventActivityIdControl(uint32 ControlCode, Guid* ActivityId);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventAccessControl(Guid* Guid, uint32 Operation, PSID Sid, uint32 Rights, BOOLEAN AllowOrDeny);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventAccessQuery(Guid* Guid, PSECURITY_DESCRIPTOR Buffer, uint32* BufferSize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EventAccessRemove(Guid* Guid);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhCreatePayloadFilter(in Guid ProviderGuid, EVENT_DESCRIPTOR* EventDescriptor, BOOLEAN EventMatchANY, uint32 PayloadPredicateCount, PAYLOAD_FILTER_PREDICATE* PayloadPredicates, void** PayloadFilter);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhDeletePayloadFilter(void** PayloadFilter);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhAggregatePayloadFilters(uint32 PayloadFilterCount, void** PayloadFilterPtrs, BOOLEAN* EventMatchALLFlags, EVENT_FILTER_DESCRIPTOR* EventFilterDescriptor);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhCleanupPayloadEventFilterDescriptor(EVENT_FILTER_DESCRIPTOR* EventFilterDescriptor);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetEventInformation(EVENT_RECORD* Event, uint32 TdhContextCount, TDH_CONTEXT* TdhContext, TRACE_EVENT_INFO* Buffer, uint32* BufferSize);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetEventMapInformation(EVENT_RECORD* pEvent, PWSTR pMapName, EVENT_MAP_INFO* pBuffer, uint32* pBufferSize);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetPropertySize(EVENT_RECORD* pEvent, uint32 TdhContextCount, TDH_CONTEXT* pTdhContext, uint32 PropertyDataCount, PROPERTY_DATA_DESCRIPTOR* pPropertyData, uint32* pPropertySize);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetProperty(EVENT_RECORD* pEvent, uint32 TdhContextCount, TDH_CONTEXT* pTdhContext, uint32 PropertyDataCount, PROPERTY_DATA_DESCRIPTOR* pPropertyData, uint32 BufferSize, uint8* pBuffer);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhEnumerateProviders(PROVIDER_ENUMERATION_INFO* pBuffer, uint32* pBufferSize);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhEnumerateProvidersForDecodingSource(DECODING_SOURCE filter, PROVIDER_ENUMERATION_INFO* buffer, uint32 bufferSize, uint32* bufferRequired);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhQueryProviderFieldInformation(Guid* pGuid, uint64 EventFieldValue, EVENT_FIELD_TYPE EventFieldType, PROVIDER_FIELD_INFOARRAY* pBuffer, uint32* pBufferSize);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhEnumerateProviderFieldInformation(Guid* pGuid, EVENT_FIELD_TYPE EventFieldType, PROVIDER_FIELD_INFOARRAY* pBuffer, uint32* pBufferSize);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhEnumerateProviderFilters(Guid* Guid, uint32 TdhContextCount, TDH_CONTEXT* TdhContext, uint32* FilterCount, PROVIDER_FILTER_INFO** Buffer, uint32* BufferSize);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhLoadManifest(PWSTR Manifest);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhLoadManifestFromMemory(void* pData, uint32 cbData);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhUnloadManifest(PWSTR Manifest);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhUnloadManifestFromMemory(void* pData, uint32 cbData);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhFormatProperty(TRACE_EVENT_INFO* EventInfo, EVENT_MAP_INFO* MapInfo, uint32 PointerSize, uint16 PropertyInType, uint16 PropertyOutType, uint16 PropertyLength, uint16 UserDataLength, uint8* UserData, uint32* BufferSize, PWSTR Buffer, uint16* UserDataConsumed);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhOpenDecodingHandle(TDH_HANDLE* Handle);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhSetDecodingParameter(TDH_HANDLE Handle, TDH_CONTEXT* TdhContext);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetDecodingParameter(TDH_HANDLE Handle, TDH_CONTEXT* TdhContext);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetWppProperty(TDH_HANDLE Handle, EVENT_RECORD* EventRecord, PWSTR PropertyName, uint32* BufferSize, uint8* Buffer);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetWppMessage(TDH_HANDLE Handle, EVENT_RECORD* EventRecord, uint32* BufferSize, uint8* Buffer);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhCloseDecodingHandle(TDH_HANDLE Handle);

	[Import("tdh.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhLoadManifestFromBinary(PWSTR BinaryPath);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhEnumerateManifestProviderEvents(Guid* ProviderGuid, PROVIDER_EVENT_INFO* Buffer, uint32* BufferSize);

	[Import("TDH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TdhGetManifestEventInformation(Guid* ProviderGuid, EVENT_DESCRIPTOR* EventDescriptor, TRACE_EVENT_INFO* Buffer, uint32* BufferSize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CveEventWrite(PWSTR CveId, PWSTR AdditionalDetails);

}
#endregion
