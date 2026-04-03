using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.DistributedTransactionCoordinator;

#region Constants
public static
{
	public const int32 DTCINSTALL_E_CLIENT_ALREADY_INSTALLED = 384;
	public const int32 DTCINSTALL_E_SERVER_ALREADY_INSTALLED = 385;
	public const uint32 XA_SWITCH_F_DTC = 1;
	public const uint32 XA_FMTID_DTC = 4478019;
	public const uint32 XA_FMTID_DTC_VER1 = 21255235;
	public const uint32 XIDDATASIZE = 128;
	public const uint32 MAXGTRIDSIZE = 64;
	public const uint32 MAXBQUALSIZE = 64;
	public const uint32 RMNAMESZ = 32;
	public const uint32 MAXINFOSIZE = 256;
	public const int32 TMNOFLAGS = 0;
	public const int32 TMREGISTER = 1;
	public const int32 TMNOMIGRATE = 2;
	public const int32 TMUSEASYNC = 4;
	public const int32 TMASYNC = -2147483648;
	public const int32 TMONEPHASE = 1073741824;
	public const int32 TMFAIL = 536870912;
	public const int32 TMNOWAIT = 268435456;
	public const int32 TMRESUME = 134217728;
	public const int32 TMSUCCESS = 67108864;
	public const int32 TMSUSPEND = 33554432;
	public const int32 TMSTARTRSCAN = 16777216;
	public const int32 TMENDRSCAN = 8388608;
	public const int32 TMMULTIPLE = 4194304;
	public const int32 TMJOIN = 2097152;
	public const int32 TMMIGRATE = 1048576;
	public const uint32 TM_JOIN = 2;
	public const uint32 TM_RESUME = 1;
	public const uint32 TM_OK = 0;
	public const int32 TMER_TMERR = -1;
	public const int32 TMER_INVAL = -2;
	public const int32 TMER_PROTO = -3;
	public const uint32 XA_RBBASE = 100;
	public const uint32 XA_RBROLLBACK = 100;
	public const uint32 XA_RBCOMMFAIL = 101;
	public const uint32 XA_RBDEADLOCK = 102;
	public const uint32 XA_RBINTEGRITY = 103;
	public const uint32 XA_RBOTHER = 104;
	public const uint32 XA_RBPROTO = 105;
	public const uint32 XA_RBTIMEOUT = 106;
	public const uint32 XA_RBTRANSIENT = 107;
	public const uint32 XA_RBEND = 107;
	public const uint32 XA_NOMIGRATE = 9;
	public const uint32 XA_HEURHAZ = 8;
	public const uint32 XA_HEURCOM = 7;
	public const uint32 XA_HEURRB = 6;
	public const uint32 XA_HEURMIX = 5;
	public const uint32 XA_RETRY = 4;
	public const uint32 XA_RDONLY = 3;
	public const uint32 XA_OK = 0;
	public const int32 XAER_ASYNC = -2;
	public const int32 XAER_RMERR = -3;
	public const int32 XAER_NOTA = -4;
	public const int32 XAER_INVAL = -5;
	public const int32 XAER_PROTO = -6;
	public const int32 XAER_RMFAIL = -7;
	public const int32 XAER_DUPID = -8;
	public const int32 XAER_OUTSIDE = -9;
	public const uint32 DTC_INSTALL_OVERWRITE_CLIENT = 1;
	public const uint32 DTC_INSTALL_OVERWRITE_SERVER = 2;
	public const uint32 OLE_TM_CONFIG_VERSION_1 = 1;
	public const uint32 OLE_TM_CONFIG_VERSION_2 = 2;
	public const uint32 OLE_TM_FLAG_NONE = 0;
	public const uint32 OLE_TM_FLAG_NODEMANDSTART = 1;
	public const uint32 OLE_TM_FLAG_NOAGILERECOVERY = 2;
	public const uint32 OLE_TM_FLAG_QUERY_SERVICE_LOCKSTATUS = 2147483648;
	public const uint32 OLE_TM_FLAG_INTERNAL_TO_TM = 1073741824;
	public const Guid CLSID_MSDtcTransactionManager = .(0x5b18ab61, 0x091d, 0x11d1, 0x97, 0xdf, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);
	public const Guid CLSID_MSDtcTransaction = .(0x39f8d76b, 0x0928, 0x11d1, 0x97, 0xdf, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);
}
#endregion

#region Enums

[AllowDuplicates]
public enum DTC_STATUS_ : int32
{
	DTC_STATUS_UNKNOWN = 0,
	DTC_STATUS_STARTING = 1,
	DTC_STATUS_STARTED = 2,
	DTC_STATUS_PAUSING = 3,
	DTC_STATUS_PAUSED = 4,
	DTC_STATUS_CONTINUING = 5,
	DTC_STATUS_STOPPING = 6,
	DTC_STATUS_STOPPED = 7,
	DTC_STATUS_E_CANTCONTROL = 8,
	DTC_STATUS_FAILED = 9,
}


[AllowDuplicates]
public enum TX_MISC_CONSTANTS : int32
{
	MAX_TRAN_DESC = 40,
}


[AllowDuplicates]
public enum ISOLATIONLEVEL : int32
{
	ISOLATIONLEVEL_UNSPECIFIED = -1,
	ISOLATIONLEVEL_CHAOS = 16,
	ISOLATIONLEVEL_READUNCOMMITTED = 256,
	ISOLATIONLEVEL_BROWSE = 256,
	ISOLATIONLEVEL_CURSORSTABILITY = 4096,
	ISOLATIONLEVEL_READCOMMITTED = 4096,
	ISOLATIONLEVEL_REPEATABLEREAD = 65536,
	ISOLATIONLEVEL_SERIALIZABLE = 1048576,
	ISOLATIONLEVEL_ISOLATED = 1048576,
}


[AllowDuplicates]
public enum ISOFLAG : int32
{
	ISOFLAG_RETAIN_COMMIT_DC = 1,
	ISOFLAG_RETAIN_COMMIT = 2,
	ISOFLAG_RETAIN_COMMIT_NO = 3,
	ISOFLAG_RETAIN_ABORT_DC = 4,
	ISOFLAG_RETAIN_ABORT = 8,
	ISOFLAG_RETAIN_ABORT_NO = 12,
	ISOFLAG_RETAIN_DONTCARE = 5,
	ISOFLAG_RETAIN_BOTH = 10,
	ISOFLAG_RETAIN_NONE = 15,
	ISOFLAG_OPTIMISTIC = 16,
	ISOFLAG_READONLY = 32,
}


[AllowDuplicates]
public enum XACTTC : int32
{
	XACTTC_NONE = 0,
	XACTTC_SYNC_PHASEONE = 1,
	XACTTC_SYNC_PHASETWO = 2,
	XACTTC_SYNC = 2,
	XACTTC_ASYNC_PHASEONE = 4,
	XACTTC_ASYNC = 4,
}


[AllowDuplicates]
public enum XACTRM : int32
{
	XACTRM_OPTIMISTICLASTWINS = 1,
	XACTRM_NOREADONLYPREPARES = 2,
}


[AllowDuplicates]
public enum XACTCONST : int32
{
	XACTCONST_TIMEOUTINFINITE = 0,
}


[AllowDuplicates]
public enum XACTHEURISTIC : int32
{
	XACTHEURISTIC_ABORT = 1,
	XACTHEURISTIC_COMMIT = 2,
	XACTHEURISTIC_DAMAGE = 3,
	XACTHEURISTIC_DANGER = 4,
}


[AllowDuplicates]
public enum XACTSTAT : int32
{
	XACTSTAT_NONE = 0,
	XACTSTAT_OPENNORMAL = 1,
	XACTSTAT_OPENREFUSED = 2,
	XACTSTAT_PREPARING = 4,
	XACTSTAT_PREPARED = 8,
	XACTSTAT_PREPARERETAINING = 16,
	XACTSTAT_PREPARERETAINED = 32,
	XACTSTAT_COMMITTING = 64,
	XACTSTAT_COMMITRETAINING = 128,
	XACTSTAT_ABORTING = 256,
	XACTSTAT_ABORTED = 512,
	XACTSTAT_COMMITTED = 1024,
	XACTSTAT_HEURISTIC_ABORT = 2048,
	XACTSTAT_HEURISTIC_COMMIT = 4096,
	XACTSTAT_HEURISTIC_DAMAGE = 8192,
	XACTSTAT_HEURISTIC_DANGER = 16384,
	XACTSTAT_FORCED_ABORT = 32768,
	XACTSTAT_FORCED_COMMIT = 65536,
	XACTSTAT_INDOUBT = 131072,
	XACTSTAT_CLOSED = 262144,
	XACTSTAT_OPEN = 3,
	XACTSTAT_NOTPREPARED = 524227,
	XACTSTAT_ALL = 524287,
}


[AllowDuplicates]
public enum AUTHENTICATION_LEVEL : int32
{
	NO_AUTHENTICATION_REQUIRED = 0,
	INCOMING_AUTHENTICATION_REQUIRED = 1,
	MUTUAL_AUTHENTICATION_REQUIRED = 2,
}


[AllowDuplicates]
public enum APPLICATIONTYPE : int32
{
	LOCAL_APPLICATIONTYPE = 0,
	CLUSTERRESOURCE_APPLICATIONTYPE = 1,
}


[AllowDuplicates]
public enum XACT_DTC_CONSTANTS : int32
{
	XACT_E_CONNECTION_REQUEST_DENIED = -2147168000,
	XACT_E_TOOMANY_ENLISTMENTS = -2147167999,
	XACT_E_DUPLICATE_GUID = -2147167998,
	XACT_E_NOTSINGLEPHASE = -2147167997,
	XACT_E_RECOVERYALREADYDONE = -2147167996,
	XACT_E_PROTOCOL = -2147167995,
	XACT_E_RM_FAILURE = -2147167994,
	XACT_E_RECOVERY_FAILED = -2147167993,
	XACT_E_LU_NOT_FOUND = -2147167992,
	XACT_E_DUPLICATE_LU = -2147167991,
	XACT_E_LU_NOT_CONNECTED = -2147167990,
	XACT_E_DUPLICATE_TRANSID = -2147167989,
	XACT_E_LU_BUSY = -2147167988,
	XACT_E_LU_NO_RECOVERY_PROCESS = -2147167987,
	XACT_E_LU_DOWN = -2147167986,
	XACT_E_LU_RECOVERING = -2147167985,
	XACT_E_LU_RECOVERY_MISMATCH = -2147167984,
	XACT_E_RM_UNAVAILABLE = -2147167983,
	XACT_E_LRMRECOVERYALREADYDONE = -2147167982,
	XACT_E_NOLASTRESOURCEINTERFACE = -2147167981,
	XACT_S_NONOTIFY = 315648,
	XACT_OK_NONOTIFY = 315649,
	dwUSER_MS_SQLSERVER = 65535,
}


[AllowDuplicates]
public enum DTCINITIATEDRECOVERYWORK : int32
{
	DTCINITIATEDRECOVERYWORK_CHECKLUSTATUS = 1,
	DTCINITIATEDRECOVERYWORK_TRANS = 2,
	DTCINITIATEDRECOVERYWORK_TMDOWN = 3,
}


[AllowDuplicates]
public enum DTCLUXLN : int32
{
	DTCLUXLN_COLD = 1,
	DTCLUXLN_WARM = 2,
}


[AllowDuplicates]
public enum DTCLUXLNCONFIRMATION : int32
{
	DTCLUXLNCONFIRMATION_CONFIRM = 1,
	DTCLUXLNCONFIRMATION_LOGNAMEMISMATCH = 2,
	DTCLUXLNCONFIRMATION_COLDWARMMISMATCH = 3,
	DTCLUXLNCONFIRMATION_OBSOLETE = 4,
}


[AllowDuplicates]
public enum DTCLUXLNRESPONSE : int32
{
	DTCLUXLNRESPONSE_OK_SENDOURXLNBACK = 1,
	DTCLUXLNRESPONSE_OK_SENDCONFIRMATION = 2,
	DTCLUXLNRESPONSE_LOGNAMEMISMATCH = 3,
	DTCLUXLNRESPONSE_COLDWARMMISMATCH = 4,
}


[AllowDuplicates]
public enum DTCLUXLNERROR : int32
{
	DTCLUXLNERROR_PROTOCOL = 1,
	DTCLUXLNERROR_LOGNAMEMISMATCH = 2,
	DTCLUXLNERROR_COLDWARMMISMATCH = 3,
}


[AllowDuplicates]
public enum DTCLUCOMPARESTATE : int32
{
	DTCLUCOMPARESTATE_COMMITTED = 1,
	DTCLUCOMPARESTATE_HEURISTICCOMMITTED = 2,
	DTCLUCOMPARESTATE_HEURISTICMIXED = 3,
	DTCLUCOMPARESTATE_HEURISTICRESET = 4,
	DTCLUCOMPARESTATE_INDOUBT = 5,
	DTCLUCOMPARESTATE_RESET = 6,
}


[AllowDuplicates]
public enum DTCLUCOMPARESTATESCONFIRMATION : int32
{
	DTCLUCOMPARESTATESCONFIRMATION_CONFIRM = 1,
	DTCLUCOMPARESTATESCONFIRMATION_PROTOCOL = 2,
}


[AllowDuplicates]
public enum DTCLUCOMPARESTATESERROR : int32
{
	DTCLUCOMPARESTATESERROR_PROTOCOL = 1,
}


[AllowDuplicates]
public enum DTCLUCOMPARESTATESRESPONSE : int32
{
	DTCLUCOMPARESTATESRESPONSE_OK = 1,
	DTCLUCOMPARESTATESRESPONSE_PROTOCOL = 2,
}

#endregion

#region Function Pointers
public function HRESULT DTC_GET_TRANSACTION_MANAGER(PSTR pszHost, PSTR pszTmName, in Guid rid, uint32 dwReserved1, uint16 wcbReserved2, void* pvReserved2, void** ppvObject);

public function HRESULT DTC_GET_TRANSACTION_MANAGER_EX_A(PSTR i_pszHost, PSTR i_pszTmName, in Guid i_riid, uint32 i_grfOptions, void* i_pvConfigParams, void** o_ppvObject);

public function HRESULT DTC_GET_TRANSACTION_MANAGER_EX_W(PWSTR i_pwszHost, PWSTR i_pwszTmName, in Guid i_riid, uint32 i_grfOptions, void* i_pvConfigParams, void** o_ppvObject);

public function HRESULT DTC_INSTALL_CLIENT(int8* i_pszRemoteTmHostName, uint32 i_dwProtocol, uint32 i_dwOverwrite);

public function int32 XA_OPEN_EPT(PSTR param0, int32 param1, int32 param2);

public function int32 XA_CLOSE_EPT(PSTR param0, int32 param1, int32 param2);

public function int32 XA_START_EPT(XID* param0, int32 param1, int32 param2);

public function int32 XA_END_EPT(XID* param0, int32 param1, int32 param2);

public function int32 XA_ROLLBACK_EPT(XID* param0, int32 param1, int32 param2);

public function int32 XA_PREPARE_EPT(XID* param0, int32 param1, int32 param2);

public function int32 XA_COMMIT_EPT(XID* param0, int32 param1, int32 param2);

public function int32 XA_RECOVER_EPT(XID* param0, int32 param1, int32 param2, int32 param3);

public function int32 XA_FORGET_EPT(XID* param0, int32 param1, int32 param2);

public function int32 XA_COMPLETE_EPT(int32* param0, int32* param1, int32 param2, int32 param3);

#endregion

#region Structs
[CRepr]
public struct BOID
{
	public uint8[16] rgb;
}

[CRepr]
public struct XACTTRANSINFO
{
	public BOID uow;
	public int32 isoLevel;
	public uint32 isoFlags;
	public uint32 grfTCSupported;
	public uint32 grfRMSupported;
	public uint32 grfTCSupportedRetaining;
	public uint32 grfRMSupportedRetaining;
}

[CRepr]
public struct XACTSTATS
{
	public uint32 cOpen;
	public uint32 cCommitting;
	public uint32 cCommitted;
	public uint32 cAborting;
	public uint32 cAborted;
	public uint32 cInDoubt;
	public uint32 cHeuristicDecision;
	public FILETIME timeTransactionsUp;
}

[CRepr]
public struct XACTOPT
{
	public uint32 ulTimeout;
	public uint8[40] szDescription;
}

[CRepr]
public struct XID
{
	public int32 formatID;
	public int32 gtrid_length;
	public int32 bqual_length;
	public CHAR[128] data;
}

[CRepr]
public struct xa_switch_t
{
	public CHAR[32] name;
	public int32 flags;
	public int32 version;
	public int xa_open_entry;
	public int xa_close_entry;
	public int xa_start_entry;
	public int xa_end_entry;
	public int xa_rollback_entry;
	public int xa_prepare_entry;
	public int xa_commit_entry;
	public int xa_recover_entry;
	public int xa_forget_entry;
	public int xa_complete_entry;
}

[CRepr]
public struct OLE_TM_CONFIG_PARAMS_V1
{
	public uint32 dwVersion;
	public uint32 dwcConcurrencyHint;
}

[CRepr]
public struct OLE_TM_CONFIG_PARAMS_V2
{
	public uint32 dwVersion;
	public uint32 dwcConcurrencyHint;
	public APPLICATIONTYPE applicationType;
	public Guid clusterResourceId;
}

[CRepr]
public struct PROXY_CONFIG_PARAMS
{
	public uint16 wcThreadsMax;
}

#endregion

#region COM Types
[CRepr]struct ITransaction : IUnknown
{
	public new const Guid IID = .(0x0fb15084, 0xaf41, 0x11ce, 0xbd, 0x2b, 0x20, 0x4c, 0x4f, 0x4f, 0x50, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRetaining, uint32 grfTC, uint32 grfRM) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOID* pboidReason, BOOL fRetaining, BOOL fAsync) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XACTTRANSINFO* pinfo) GetTransactionInfo;
	}


	public HRESULT Commit(BOOL fRetaining, uint32 grfTC, uint32 grfRM) mut => VT.[Friend]Commit(&this, fRetaining, grfTC, grfRM);

	public HRESULT Abort(BOID* pboidReason, BOOL fRetaining, BOOL fAsync) mut => VT.[Friend]Abort(&this, pboidReason, fRetaining, fAsync);

	public HRESULT GetTransactionInfo(XACTTRANSINFO* pinfo) mut => VT.[Friend]GetTransactionInfo(&this, pinfo);
}

[CRepr]struct ITransactionCloner : ITransaction
{
	public new const Guid IID = .(0x02656950, 0x2152, 0x11d0, 0x94, 0x4c, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITransaction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction** ppITransaction) CloneWithCommitDisabled;
	}


	public HRESULT CloneWithCommitDisabled(ITransaction** ppITransaction) mut => VT.[Friend]CloneWithCommitDisabled(&this, ppITransaction);
}

[CRepr]struct ITransaction2 : ITransactionCloner
{
	public new const Guid IID = .(0x34021548, 0x0065, 0x11d3, 0xba, 0xc1, 0x00, 0xc0, 0x4f, 0x79, 0x7b, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITransactionCloner.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XACTTRANSINFO* pinfo) GetTransactionInfo2;
	}


	public HRESULT GetTransactionInfo2(XACTTRANSINFO* pinfo) mut => VT.[Friend]GetTransactionInfo2(&this, pinfo);
}

[CRepr]struct ITransactionDispenser : IUnknown
{
	public new const Guid IID = .(0x3a6ad9e1, 0x23b9, 0x11cf, 0xad, 0x60, 0x00, 0xaa, 0x00, 0xa7, 0x4c, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionOptions** ppOptions) GetOptionsObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkOuter, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOptions, ITransaction** ppTransaction) BeginTransaction;
	}


	public HRESULT GetOptionsObject(ITransactionOptions** ppOptions) mut => VT.[Friend]GetOptionsObject(&this, ppOptions);

	public HRESULT BeginTransaction(IUnknown* punkOuter, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOptions, ITransaction** ppTransaction) mut => VT.[Friend]BeginTransaction(&this, punkOuter, isoLevel, isoFlags, pOptions, ppTransaction);
}

[CRepr]struct ITransactionOptions : IUnknown
{
	public new const Guid IID = .(0x3a6ad9e0, 0x23b9, 0x11cf, 0xad, 0x60, 0x00, 0xaa, 0x00, 0xa7, 0x4c, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XACTOPT* pOptions) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XACTOPT* pOptions) GetOptions;
	}


	public HRESULT SetOptions(XACTOPT* pOptions) mut => VT.[Friend]SetOptions(&this, pOptions);

	public HRESULT GetOptions(XACTOPT* pOptions) mut => VT.[Friend]GetOptions(&this, pOptions);
}

[CRepr]struct ITransactionOutcomeEvents : IUnknown
{
	public new const Guid IID = .(0x3a6ad9e2, 0x23b9, 0x11cf, 0xad, 0x60, 0x00, 0xaa, 0x00, 0xa7, 0x4c, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRetaining, BOID* pNewUOW, HRESULT hr) Committed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOID* pboidReason, BOOL fRetaining, BOID* pNewUOW, HRESULT hr) Aborted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDecision, BOID* pboidReason, HRESULT hr) HeuristicDecision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Indoubt;
	}


	public HRESULT Committed(BOOL fRetaining, BOID* pNewUOW, HRESULT hr) mut => VT.[Friend]Committed(&this, fRetaining, pNewUOW, hr);

	public HRESULT Aborted(BOID* pboidReason, BOOL fRetaining, BOID* pNewUOW, HRESULT hr) mut => VT.[Friend]Aborted(&this, pboidReason, fRetaining, pNewUOW, hr);

	public HRESULT HeuristicDecision(uint32 dwDecision, BOID* pboidReason, HRESULT hr) mut => VT.[Friend]HeuristicDecision(&this, dwDecision, pboidReason, hr);

	public HRESULT Indoubt() mut => VT.[Friend]Indoubt(&this);
}

[CRepr]struct ITmNodeName : IUnknown
{
	public new const Guid IID = .(0x30274f88, 0x6ee4, 0x474e, 0x9b, 0x95, 0x78, 0x07, 0xbc, 0x9e, 0xf8, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbNodeNameSize) GetNodeNameSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbNodeNameBufferSize, PWSTR pNodeNameBuffer) GetNodeName;
	}


	public HRESULT GetNodeNameSize(uint32* pcbNodeNameSize) mut => VT.[Friend]GetNodeNameSize(&this, pcbNodeNameSize);

	public HRESULT GetNodeName(uint32 cbNodeNameBufferSize, PWSTR pNodeNameBuffer) mut => VT.[Friend]GetNodeName(&this, cbNodeNameBufferSize, pNodeNameBuffer);
}

[CRepr]struct IKernelTransaction : IUnknown
{
	public new const Guid IID = .(0x79427a2b, 0xf895, 0x40e0, 0xbe, 0x79, 0xb5, 0x7d, 0xc8, 0x2e, 0xd2, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* pHandle) GetHandle;
	}


	public HRESULT GetHandle(HANDLE* pHandle) mut => VT.[Friend]GetHandle(&this, pHandle);
}

[CRepr]struct ITransactionResourceAsync : IUnknown
{
	public new const Guid IID = .(0x69e971f0, 0x23ce, 0x11cf, 0xad, 0x60, 0x00, 0xaa, 0x00, 0xa7, 0x4c, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRetaining, uint32 grfRM, BOOL fWantMoniker, BOOL fSinglePhase) PrepareRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfRM, BOID* pNewUOW) CommitRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOID* pboidReason, BOOL fRetaining, BOID* pNewUOW) AbortRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TMDown;
	}


	public HRESULT PrepareRequest(BOOL fRetaining, uint32 grfRM, BOOL fWantMoniker, BOOL fSinglePhase) mut => VT.[Friend]PrepareRequest(&this, fRetaining, grfRM, fWantMoniker, fSinglePhase);

	public HRESULT CommitRequest(uint32 grfRM, BOID* pNewUOW) mut => VT.[Friend]CommitRequest(&this, grfRM, pNewUOW);

	public HRESULT AbortRequest(BOID* pboidReason, BOOL fRetaining, BOID* pNewUOW) mut => VT.[Friend]AbortRequest(&this, pboidReason, fRetaining, pNewUOW);

	public HRESULT TMDown() mut => VT.[Friend]TMDown(&this);
}

[CRepr]struct ITransactionLastResourceAsync : IUnknown
{
	public new const Guid IID = .(0xc82bd532, 0x5b30, 0x11d3, 0x8a, 0x91, 0x00, 0xc0, 0x4f, 0x79, 0xeb, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfRM) DelegateCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOID* pNewUOW) ForgetRequest;
	}


	public HRESULT DelegateCommit(uint32 grfRM) mut => VT.[Friend]DelegateCommit(&this, grfRM);

	public HRESULT ForgetRequest(BOID* pNewUOW) mut => VT.[Friend]ForgetRequest(&this, pNewUOW);
}

[CRepr]struct ITransactionResource : IUnknown
{
	public new const Guid IID = .(0xee5ff7b3, 0x4572, 0x11d0, 0x94, 0x52, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRetaining, uint32 grfRM, BOOL fWantMoniker, BOOL fSinglePhase) PrepareRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfRM, BOID* pNewUOW) CommitRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOID* pboidReason, BOOL fRetaining, BOID* pNewUOW) AbortRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TMDown;
	}


	public HRESULT PrepareRequest(BOOL fRetaining, uint32 grfRM, BOOL fWantMoniker, BOOL fSinglePhase) mut => VT.[Friend]PrepareRequest(&this, fRetaining, grfRM, fWantMoniker, fSinglePhase);

	public HRESULT CommitRequest(uint32 grfRM, BOID* pNewUOW) mut => VT.[Friend]CommitRequest(&this, grfRM, pNewUOW);

	public HRESULT AbortRequest(BOID* pboidReason, BOOL fRetaining, BOID* pNewUOW) mut => VT.[Friend]AbortRequest(&this, pboidReason, fRetaining, pNewUOW);

	public HRESULT TMDown() mut => VT.[Friend]TMDown(&this);
}

[CRepr]struct ITransactionEnlistmentAsync : IUnknown
{
	public new const Guid IID = .(0x0fb15081, 0xaf41, 0x11ce, 0xbd, 0x2b, 0x20, 0x4c, 0x4f, 0x4f, 0x50, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, IMoniker* pmk, BOID* pboidReason) PrepareRequestDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) CommitRequestDone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) AbortRequestDone;
	}


	public HRESULT PrepareRequestDone(HRESULT hr, IMoniker* pmk, BOID* pboidReason) mut => VT.[Friend]PrepareRequestDone(&this, hr, pmk, pboidReason);

	public HRESULT CommitRequestDone(HRESULT hr) mut => VT.[Friend]CommitRequestDone(&this, hr);

	public HRESULT AbortRequestDone(HRESULT hr) mut => VT.[Friend]AbortRequestDone(&this, hr);
}

[CRepr]struct ITransactionLastEnlistmentAsync : IUnknown
{
	public new const Guid IID = .(0xc82bd533, 0x5b30, 0x11d3, 0x8a, 0x91, 0x00, 0xc0, 0x4f, 0x79, 0xeb, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XACTSTAT XactStat, BOID* pboidReason) TransactionOutcome;
	}


	public HRESULT TransactionOutcome(XACTSTAT XactStat, BOID* pboidReason) mut => VT.[Friend]TransactionOutcome(&this, XactStat, pboidReason);
}

[CRepr]struct ITransactionExportFactory : IUnknown
{
	public new const Guid IID = .(0xe1cf9b53, 0x8745, 0x11ce, 0xa9, 0xba, 0x00, 0xaa, 0x00, 0x6c, 0x37, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetRemoteClassId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbWhereabouts, uint8* rgbWhereabouts, ITransactionExport** ppExport) Create;
	}


	public HRESULT GetRemoteClassId(Guid* pclsid) mut => VT.[Friend]GetRemoteClassId(&this, pclsid);

	public HRESULT Create(uint32 cbWhereabouts, uint8* rgbWhereabouts, ITransactionExport** ppExport) mut => VT.[Friend]Create(&this, cbWhereabouts, rgbWhereabouts, ppExport);
}

[CRepr]struct ITransactionImportWhereabouts : IUnknown
{
	public new const Guid IID = .(0x0141fda4, 0x8fc0, 0x11ce, 0xbd, 0x18, 0x20, 0x4c, 0x4f, 0x4f, 0x50, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbWhereabouts) GetWhereaboutsSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbWhereabouts, uint8* rgbWhereabouts, uint32* pcbUsed) GetWhereabouts;
	}


	public HRESULT GetWhereaboutsSize(uint32* pcbWhereabouts) mut => VT.[Friend]GetWhereaboutsSize(&this, pcbWhereabouts);

	public HRESULT GetWhereabouts(uint32 cbWhereabouts, uint8* rgbWhereabouts, uint32* pcbUsed) mut => VT.[Friend]GetWhereabouts(&this, cbWhereabouts, rgbWhereabouts, pcbUsed);
}

[CRepr]struct ITransactionExport : IUnknown
{
	public new const Guid IID = .(0x0141fda5, 0x8fc0, 0x11ce, 0xbd, 0x18, 0x20, 0x4c, 0x4f, 0x4f, 0x50, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkTransaction, uint32* pcbTransactionCookie) Export;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkTransaction, uint32 cbTransactionCookie, uint8* rgbTransactionCookie, uint32* pcbUsed) GetTransactionCookie;
	}


	public HRESULT Export(IUnknown* punkTransaction, uint32* pcbTransactionCookie) mut => VT.[Friend]Export(&this, punkTransaction, pcbTransactionCookie);

	public HRESULT GetTransactionCookie(IUnknown* punkTransaction, uint32 cbTransactionCookie, uint8* rgbTransactionCookie, uint32* pcbUsed) mut => VT.[Friend]GetTransactionCookie(&this, punkTransaction, cbTransactionCookie, rgbTransactionCookie, pcbUsed);
}

[CRepr]struct ITransactionImport : IUnknown
{
	public new const Guid IID = .(0xe1cf9b5a, 0x8745, 0x11ce, 0xa9, 0xba, 0x00, 0xaa, 0x00, 0x6c, 0x37, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbTransactionCookie, uint8* rgbTransactionCookie, in Guid piid, void** ppvTransaction) Import;
	}


	public HRESULT Import(uint32 cbTransactionCookie, uint8* rgbTransactionCookie, in Guid piid, void** ppvTransaction) mut => VT.[Friend]Import(&this, cbTransactionCookie, rgbTransactionCookie, piid, ppvTransaction);
}

[CRepr]struct ITipTransaction : IUnknown
{
	public new const Guid IID = .(0x17cf72d0, 0xbac5, 0x11d1, 0xb1, 0xbf, 0x00, 0xc0, 0x4f, 0xc2, 0xf3, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* i_pszRemoteTmUrl, PSTR* o_ppszRemoteTxUrl) Push;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR* o_ppszLocalTxUrl) GetTransactionUrl;
	}


	public HRESULT Push(uint8* i_pszRemoteTmUrl, PSTR* o_ppszRemoteTxUrl) mut => VT.[Friend]Push(&this, i_pszRemoteTmUrl, o_ppszRemoteTxUrl);

	public HRESULT GetTransactionUrl(PSTR* o_ppszLocalTxUrl) mut => VT.[Friend]GetTransactionUrl(&this, o_ppszLocalTxUrl);
}

[CRepr]struct ITipHelper : IUnknown
{
	public new const Guid IID = .(0x17cf72d1, 0xbac5, 0x11d1, 0xb1, 0xbf, 0x00, 0xc0, 0x4f, 0xc2, 0xf3, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* i_pszTxUrl, ITransaction** o_ppITransaction) Pull;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* i_pszTxUrl, ITipPullSink* i_pTipPullSink, ITransaction** o_ppITransaction) PullAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** o_ppszLocalTmUrl) GetLocalTmUrl;
	}


	public HRESULT Pull(uint8* i_pszTxUrl, ITransaction** o_ppITransaction) mut => VT.[Friend]Pull(&this, i_pszTxUrl, o_ppITransaction);

	public HRESULT PullAsync(uint8* i_pszTxUrl, ITipPullSink* i_pTipPullSink, ITransaction** o_ppITransaction) mut => VT.[Friend]PullAsync(&this, i_pszTxUrl, i_pTipPullSink, o_ppITransaction);

	public HRESULT GetLocalTmUrl(uint8** o_ppszLocalTmUrl) mut => VT.[Friend]GetLocalTmUrl(&this, o_ppszLocalTmUrl);
}

[CRepr]struct ITipPullSink : IUnknown
{
	public new const Guid IID = .(0x17cf72d2, 0xbac5, 0x11d1, 0xb1, 0xbf, 0x00, 0xc0, 0x4f, 0xc2, 0xf3, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT i_hrPull) PullComplete;
	}


	public HRESULT PullComplete(HRESULT i_hrPull) mut => VT.[Friend]PullComplete(&this, i_hrPull);
}

[CRepr]struct IDtcNetworkAccessConfig : IUnknown
{
	public new const Guid IID = .(0x9797c15d, 0xa428, 0x4291, 0x87, 0xb6, 0x09, 0x95, 0x03, 0x1a, 0x67, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbAnyNetworkAccess) GetAnyNetworkAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bAnyNetworkAccess) SetAnyNetworkAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbNetworkAdministrationAccess) GetNetworkAdministrationAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bNetworkAdministrationAccess) SetNetworkAdministrationAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbNetworkTransactionAccess) GetNetworkTransactionAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bNetworkTransactionAccess) SetNetworkTransactionAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbNetworkClientAccess) GetNetworkClientAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bNetworkClientAccess) SetNetworkClientAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbNetworkTIPAccess) GetNetworkTIPAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bNetworkTIPAccess) SetNetworkTIPAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbXAAccess) GetXAAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bXAAccess) SetXAAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestartDtcService;
	}


	public HRESULT GetAnyNetworkAccess(BOOL* pbAnyNetworkAccess) mut => VT.[Friend]GetAnyNetworkAccess(&this, pbAnyNetworkAccess);

	public HRESULT SetAnyNetworkAccess(BOOL bAnyNetworkAccess) mut => VT.[Friend]SetAnyNetworkAccess(&this, bAnyNetworkAccess);

	public HRESULT GetNetworkAdministrationAccess(BOOL* pbNetworkAdministrationAccess) mut => VT.[Friend]GetNetworkAdministrationAccess(&this, pbNetworkAdministrationAccess);

	public HRESULT SetNetworkAdministrationAccess(BOOL bNetworkAdministrationAccess) mut => VT.[Friend]SetNetworkAdministrationAccess(&this, bNetworkAdministrationAccess);

	public HRESULT GetNetworkTransactionAccess(BOOL* pbNetworkTransactionAccess) mut => VT.[Friend]GetNetworkTransactionAccess(&this, pbNetworkTransactionAccess);

	public HRESULT SetNetworkTransactionAccess(BOOL bNetworkTransactionAccess) mut => VT.[Friend]SetNetworkTransactionAccess(&this, bNetworkTransactionAccess);

	public HRESULT GetNetworkClientAccess(BOOL* pbNetworkClientAccess) mut => VT.[Friend]GetNetworkClientAccess(&this, pbNetworkClientAccess);

	public HRESULT SetNetworkClientAccess(BOOL bNetworkClientAccess) mut => VT.[Friend]SetNetworkClientAccess(&this, bNetworkClientAccess);

	public HRESULT GetNetworkTIPAccess(BOOL* pbNetworkTIPAccess) mut => VT.[Friend]GetNetworkTIPAccess(&this, pbNetworkTIPAccess);

	public HRESULT SetNetworkTIPAccess(BOOL bNetworkTIPAccess) mut => VT.[Friend]SetNetworkTIPAccess(&this, bNetworkTIPAccess);

	public HRESULT GetXAAccess(BOOL* pbXAAccess) mut => VT.[Friend]GetXAAccess(&this, pbXAAccess);

	public HRESULT SetXAAccess(BOOL bXAAccess) mut => VT.[Friend]SetXAAccess(&this, bXAAccess);

	public HRESULT RestartDtcService() mut => VT.[Friend]RestartDtcService(&this);
}

[CRepr]struct IDtcNetworkAccessConfig2 : IDtcNetworkAccessConfig
{
	public new const Guid IID = .(0xa7aa013b, 0xeb7d, 0x4f42, 0xb4, 0x1c, 0xb2, 0xde, 0xc0, 0x9a, 0xe0, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDtcNetworkAccessConfig.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbInbound) GetNetworkInboundAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbOutbound) GetNetworkOutboundAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bInbound) SetNetworkInboundAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bOutbound) SetNetworkOutboundAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AUTHENTICATION_LEVEL* pAuthLevel) GetAuthenticationLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AUTHENTICATION_LEVEL AuthLevel) SetAuthenticationLevel;
	}


	public HRESULT GetNetworkInboundAccess(BOOL* pbInbound) mut => VT.[Friend]GetNetworkInboundAccess(&this, pbInbound);

	public HRESULT GetNetworkOutboundAccess(BOOL* pbOutbound) mut => VT.[Friend]GetNetworkOutboundAccess(&this, pbOutbound);

	public HRESULT SetNetworkInboundAccess(BOOL bInbound) mut => VT.[Friend]SetNetworkInboundAccess(&this, bInbound);

	public HRESULT SetNetworkOutboundAccess(BOOL bOutbound) mut => VT.[Friend]SetNetworkOutboundAccess(&this, bOutbound);

	public HRESULT GetAuthenticationLevel(AUTHENTICATION_LEVEL* pAuthLevel) mut => VT.[Friend]GetAuthenticationLevel(&this, pAuthLevel);

	public HRESULT SetAuthenticationLevel(AUTHENTICATION_LEVEL AuthLevel) mut => VT.[Friend]SetAuthenticationLevel(&this, AuthLevel);
}

[CRepr]struct IDtcNetworkAccessConfig3 : IDtcNetworkAccessConfig2
{
	public new const Guid IID = .(0x76e4b4f3, 0x2ca5, 0x466b, 0x89, 0xd5, 0xfd, 0x21, 0x8e, 0xe7, 0x5b, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDtcNetworkAccessConfig2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbLUAccess) GetLUAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bLUAccess) SetLUAccess;
	}


	public HRESULT GetLUAccess(BOOL* pbLUAccess) mut => VT.[Friend]GetLUAccess(&this, pbLUAccess);

	public HRESULT SetLUAccess(BOOL bLUAccess) mut => VT.[Friend]SetLUAccess(&this, bLUAccess);
}

[CRepr]struct IDtcToXaMapper : IUnknown
{
	public new const Guid IID = .(0x64ffabe0, 0x7ce9, 0x11d0, 0x8c, 0xe6, 0x00, 0xc0, 0x4f, 0xdc, 0x87, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszDSN, PSTR pszClientDllName, uint32* pdwRMCookie) RequestNewResourceManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwITransaction, uint32 dwRMCookie, XID* pXid) TranslateTridToXid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRMCookie, uint32* pdwITransaction) EnlistResourceManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRMCookie) ReleaseResourceManager;
	}


	public HRESULT RequestNewResourceManager(PSTR pszDSN, PSTR pszClientDllName, uint32* pdwRMCookie) mut => VT.[Friend]RequestNewResourceManager(&this, pszDSN, pszClientDllName, pdwRMCookie);

	public HRESULT TranslateTridToXid(uint32* pdwITransaction, uint32 dwRMCookie, XID* pXid) mut => VT.[Friend]TranslateTridToXid(&this, pdwITransaction, dwRMCookie, pXid);

	public HRESULT EnlistResourceManager(uint32 dwRMCookie, uint32* pdwITransaction) mut => VT.[Friend]EnlistResourceManager(&this, dwRMCookie, pdwITransaction);

	public HRESULT ReleaseResourceManager(uint32 dwRMCookie) mut => VT.[Friend]ReleaseResourceManager(&this, dwRMCookie);
}

[CRepr]struct IDtcToXaHelperFactory : IUnknown
{
	public new const Guid IID = .(0xa9861610, 0x304a, 0x11d1, 0x98, 0x13, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszDSN, PSTR pszClientDllName, Guid* pguidRm, IDtcToXaHelper** ppXaHelper) Create;
	}


	public HRESULT Create(PSTR pszDSN, PSTR pszClientDllName, Guid* pguidRm, IDtcToXaHelper** ppXaHelper) mut => VT.[Friend]Create(&this, pszDSN, pszClientDllName, pguidRm, ppXaHelper);
}

[CRepr]struct IDtcToXaHelper : IUnknown
{
	public new const Guid IID = .(0xa9861611, 0x304a, 0x11d1, 0x98, 0x13, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL i_fDoRecovery) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pITransaction, Guid* pguidBqual, XID* pXid) TranslateTridToXid;
	}


	public HRESULT Close(BOOL i_fDoRecovery) mut => VT.[Friend]Close(&this, i_fDoRecovery);

	public HRESULT TranslateTridToXid(ITransaction* pITransaction, Guid* pguidBqual, XID* pXid) mut => VT.[Friend]TranslateTridToXid(&this, pITransaction, pguidBqual, pXid);
}

[CRepr]struct IDtcToXaHelperSinglePipe : IUnknown
{
	public new const Guid IID = .(0x47ed4971, 0x53b3, 0x11d1, 0xbb, 0xb9, 0x00, 0xc0, 0x4f, 0xd6, 0x58, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszDSN, PSTR pszClientDll, uint32* pdwRMCookie) XARMCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwITrans, uint32 dwRMCookie, XID* pxid) ConvertTridToXID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRMCookie, ITransaction* i_pITransaction, ITransactionResourceAsync* i_pITransRes, ITransactionEnlistmentAsync** o_ppITransEnslitment) EnlistWithRM;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 i_dwRMCookie, BOOL i_fNormal) ReleaseRMCookie;
	}


	public HRESULT XARMCreate(PSTR pszDSN, PSTR pszClientDll, uint32* pdwRMCookie) mut => VT.[Friend]XARMCreate(&this, pszDSN, pszClientDll, pdwRMCookie);

	public HRESULT ConvertTridToXID(uint32* pdwITrans, uint32 dwRMCookie, XID* pxid) mut => VT.[Friend]ConvertTridToXID(&this, pdwITrans, dwRMCookie, pxid);

	public HRESULT EnlistWithRM(uint32 dwRMCookie, ITransaction* i_pITransaction, ITransactionResourceAsync* i_pITransRes, ITransactionEnlistmentAsync** o_ppITransEnslitment) mut => VT.[Friend]EnlistWithRM(&this, dwRMCookie, i_pITransaction, i_pITransRes, o_ppITransEnslitment);

	public void ReleaseRMCookie(uint32 i_dwRMCookie, BOOL i_fNormal) mut => VT.[Friend]ReleaseRMCookie(&this, i_dwRMCookie, i_fNormal);
}

[CRepr]struct IXATransLookup : IUnknown
{
	public new const Guid IID = .(0xf3b1f131, 0xeeda, 0x11ce, 0xae, 0xd4, 0x00, 0xaa, 0x00, 0x51, 0xe2, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction** ppTransaction) Lookup;
	}


	public HRESULT Lookup(ITransaction** ppTransaction) mut => VT.[Friend]Lookup(&this, ppTransaction);
}

[CRepr]struct IXATransLookup2 : IUnknown
{
	public new const Guid IID = .(0xbf193c85, 0x0d1a, 0x4290, 0xb8, 0x8f, 0xd2, 0xcb, 0x88, 0x73, 0xd1, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XID* pXID, ITransaction** ppTransaction) Lookup;
	}


	public HRESULT Lookup(XID* pXID, ITransaction** ppTransaction) mut => VT.[Friend]Lookup(&this, pXID, ppTransaction);
}

[CRepr]struct IResourceManagerSink : IUnknown
{
	public new const Guid IID = .(0x0d563181, 0xdefb, 0x11ce, 0xae, 0xd1, 0x00, 0xaa, 0x00, 0x51, 0xe2, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TMDown;
	}


	public HRESULT TMDown() mut => VT.[Friend]TMDown(&this);
}

[CRepr]struct IResourceManager : IUnknown
{
	public new const Guid IID = .(0x13741d21, 0x87eb, 0x11ce, 0x80, 0x81, 0x00, 0x80, 0xc7, 0x58, 0x52, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pTransaction, ITransactionResourceAsync* pRes, BOID* pUOW, int32* pisoLevel, ITransactionEnlistmentAsync** ppEnlist) Enlist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pPrepInfo, uint32 cbPrepInfo, uint32 lTimeout, XACTSTAT* pXactStat) Reenlist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReenlistmentComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, void** ppvObject) GetDistributedTransactionManager;
	}


	public HRESULT Enlist(ITransaction* pTransaction, ITransactionResourceAsync* pRes, BOID* pUOW, int32* pisoLevel, ITransactionEnlistmentAsync** ppEnlist) mut => VT.[Friend]Enlist(&this, pTransaction, pRes, pUOW, pisoLevel, ppEnlist);

	public HRESULT Reenlist(uint8* pPrepInfo, uint32 cbPrepInfo, uint32 lTimeout, XACTSTAT* pXactStat) mut => VT.[Friend]Reenlist(&this, pPrepInfo, cbPrepInfo, lTimeout, pXactStat);

	public HRESULT ReenlistmentComplete() mut => VT.[Friend]ReenlistmentComplete(&this);

	public HRESULT GetDistributedTransactionManager(in Guid iid, void** ppvObject) mut => VT.[Friend]GetDistributedTransactionManager(&this, iid, ppvObject);
}

[CRepr]struct ILastResourceManager : IUnknown
{
	public new const Guid IID = .(0x4d964ad4, 0x5b33, 0x11d3, 0x8a, 0x91, 0x00, 0xc0, 0x4f, 0x79, 0xeb, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pPrepInfo, uint32 cbPrepInfo) TransactionCommitted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RecoveryDone;
	}


	public HRESULT TransactionCommitted(uint8* pPrepInfo, uint32 cbPrepInfo) mut => VT.[Friend]TransactionCommitted(&this, pPrepInfo, cbPrepInfo);

	public HRESULT RecoveryDone() mut => VT.[Friend]RecoveryDone(&this);
}

[CRepr]struct IResourceManager2 : IResourceManager
{
	public new const Guid IID = .(0xd136c69a, 0xf749, 0x11d1, 0x8f, 0x47, 0x00, 0xc0, 0x4f, 0x8e, 0xe5, 0x7d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IResourceManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pTransaction, ITransactionResourceAsync* pResAsync, BOID* pUOW, int32* pisoLevel, XID* pXid, ITransactionEnlistmentAsync** ppEnlist) Enlist2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XID* pXid, uint32 dwTimeout, XACTSTAT* pXactStat) Reenlist2;
	}


	public HRESULT Enlist2(ITransaction* pTransaction, ITransactionResourceAsync* pResAsync, BOID* pUOW, int32* pisoLevel, XID* pXid, ITransactionEnlistmentAsync** ppEnlist) mut => VT.[Friend]Enlist2(&this, pTransaction, pResAsync, pUOW, pisoLevel, pXid, ppEnlist);

	public HRESULT Reenlist2(XID* pXid, uint32 dwTimeout, XACTSTAT* pXactStat) mut => VT.[Friend]Reenlist2(&this, pXid, dwTimeout, pXactStat);
}

[CRepr]struct IResourceManagerRejoinable : IResourceManager2
{
	public new const Guid IID = .(0x6f6de620, 0xb5df, 0x4f3e, 0x9c, 0xfa, 0xc8, 0xae, 0xbd, 0x05, 0x17, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IResourceManager2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pPrepInfo, uint32 cbPrepInfo, uint32 lTimeout, XACTSTAT* pXactStat) Rejoin;
	}


	public HRESULT Rejoin(uint8* pPrepInfo, uint32 cbPrepInfo, uint32 lTimeout, XACTSTAT* pXactStat) mut => VT.[Friend]Rejoin(&this, pPrepInfo, cbPrepInfo, lTimeout, pXactStat);
}

[CRepr]struct IXAConfig : IUnknown
{
	public new const Guid IID = .(0xc8a6e3a1, 0x9a8c, 0x11cf, 0xa3, 0x08, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid clsidHelperDll) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminate;
	}


	public HRESULT Initialize(Guid clsidHelperDll) mut => VT.[Friend]Initialize(&this, clsidHelperDll);

	public HRESULT Terminate() mut => VT.[Friend]Terminate(&this);
}

[CRepr]struct IRMHelper : IUnknown
{
	public new const Guid IID = .(0xe793f6d1, 0xf53d, 0x11cf, 0xa6, 0x0d, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwcTotalNumberOfRMs) RMCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, xa_switch_t* pXa_Switch, BOOL fCDeclCallingConv, PSTR pszOpenString, PSTR pszCloseString, Guid guidRMRecovery) RMInfo;
	}


	public HRESULT RMCount(uint32 dwcTotalNumberOfRMs) mut => VT.[Friend]RMCount(&this, dwcTotalNumberOfRMs);

	public HRESULT RMInfo(xa_switch_t* pXa_Switch, BOOL fCDeclCallingConv, PSTR pszOpenString, PSTR pszCloseString, Guid guidRMRecovery) mut => VT.[Friend]RMInfo(&this, pXa_Switch, fCDeclCallingConv, pszOpenString, pszCloseString, guidRMRecovery);
}

[CRepr]struct IXAObtainRMInfo : IUnknown
{
	public new const Guid IID = .(0xe793f6d2, 0xf53d, 0x11cf, 0xa6, 0x0d, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRMHelper* pIRMHelper) ObtainRMInfo;
	}


	public HRESULT ObtainRMInfo(IRMHelper* pIRMHelper) mut => VT.[Friend]ObtainRMInfo(&this, pIRMHelper);
}

[CRepr]struct IResourceManagerFactory : IUnknown
{
	public new const Guid IID = .(0x13741d20, 0x87eb, 0x11ce, 0x80, 0x81, 0x00, 0x80, 0xc7, 0x58, 0x52, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidRM, PSTR pszRMName, IResourceManagerSink* pIResMgrSink, IResourceManager** ppResMgr) Create;
	}


	public HRESULT Create(Guid* pguidRM, PSTR pszRMName, IResourceManagerSink* pIResMgrSink, IResourceManager** ppResMgr) mut => VT.[Friend]Create(&this, pguidRM, pszRMName, pIResMgrSink, ppResMgr);
}

[CRepr]struct IResourceManagerFactory2 : IResourceManagerFactory
{
	public new const Guid IID = .(0x6b369c21, 0xfbd2, 0x11d1, 0x8f, 0x47, 0x00, 0xc0, 0x4f, 0x8e, 0xe5, 0x7d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IResourceManagerFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidRM, PSTR pszRMName, IResourceManagerSink* pIResMgrSink, in Guid riidRequested, void** ppvResMgr) CreateEx;
	}


	public HRESULT CreateEx(Guid* pguidRM, PSTR pszRMName, IResourceManagerSink* pIResMgrSink, in Guid riidRequested, void** ppvResMgr) mut => VT.[Friend]CreateEx(&this, pguidRM, pszRMName, pIResMgrSink, riidRequested, ppvResMgr);
}

[CRepr]struct IPrepareInfo : IUnknown
{
	public new const Guid IID = .(0x80c7bfd0, 0x87ee, 0x11ce, 0x80, 0x81, 0x00, 0x80, 0xc7, 0x58, 0x52, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbPrepInfo) GetPrepareInfoSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pPrepInfo) GetPrepareInfo;
	}


	public HRESULT GetPrepareInfoSize(uint32* pcbPrepInfo) mut => VT.[Friend]GetPrepareInfoSize(&this, pcbPrepInfo);

	public HRESULT GetPrepareInfo(uint8* pPrepInfo) mut => VT.[Friend]GetPrepareInfo(&this, pPrepInfo);
}

[CRepr]struct IPrepareInfo2 : IUnknown
{
	public new const Guid IID = .(0x5fab2547, 0x9779, 0x11d1, 0xb8, 0x86, 0x00, 0xc0, 0x4f, 0xb9, 0x61, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbPrepInfo) GetPrepareInfoSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbPrepareInfo, uint8* pPrepInfo) GetPrepareInfo;
	}


	public HRESULT GetPrepareInfoSize(uint32* pcbPrepInfo) mut => VT.[Friend]GetPrepareInfoSize(&this, pcbPrepInfo);

	public HRESULT GetPrepareInfo(uint32 cbPrepareInfo, uint8* pPrepInfo) mut => VT.[Friend]GetPrepareInfo(&this, cbPrepareInfo, pPrepInfo);
}

[CRepr]struct IGetDispenser : IUnknown
{
	public new const Guid IID = .(0xc23cc370, 0x87ef, 0x11ce, 0x80, 0x81, 0x00, 0x80, 0xc7, 0x58, 0x52, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, void** ppvObject) GetDispenser;
	}


	public HRESULT GetDispenser(in Guid iid, void** ppvObject) mut => VT.[Friend]GetDispenser(&this, iid, ppvObject);
}

[CRepr]struct ITransactionVoterBallotAsync2 : IUnknown
{
	public new const Guid IID = .(0x5433376c, 0x414d, 0x11d3, 0xb2, 0x06, 0x00, 0xc0, 0x4f, 0xc2, 0xf3, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, BOID* pboidReason) VoteRequestDone;
	}


	public HRESULT VoteRequestDone(HRESULT hr, BOID* pboidReason) mut => VT.[Friend]VoteRequestDone(&this, hr, pboidReason);
}

[CRepr]struct ITransactionVoterNotifyAsync2 : ITransactionOutcomeEvents
{
	public new const Guid IID = .(0x5433376b, 0x414d, 0x11d3, 0xb2, 0x06, 0x00, 0xc0, 0x4f, 0xc2, 0xf3, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITransactionOutcomeEvents.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) VoteRequest;
	}


	public HRESULT VoteRequest() mut => VT.[Friend]VoteRequest(&this);
}

[CRepr]struct ITransactionVoterFactory2 : IUnknown
{
	public new const Guid IID = .(0x5433376a, 0x414d, 0x11d3, 0xb2, 0x06, 0x00, 0xc0, 0x4f, 0xc2, 0xf3, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pTransaction, ITransactionVoterNotifyAsync2* pVoterNotify, ITransactionVoterBallotAsync2** ppVoterBallot) Create;
	}


	public HRESULT Create(ITransaction* pTransaction, ITransactionVoterNotifyAsync2* pVoterNotify, ITransactionVoterBallotAsync2** ppVoterBallot) mut => VT.[Friend]Create(&this, pTransaction, pVoterNotify, ppVoterBallot);
}

[CRepr]struct ITransactionPhase0EnlistmentAsync : IUnknown
{
	public new const Guid IID = .(0x82dc88e1, 0xa954, 0x11d1, 0x8f, 0x88, 0x00, 0x60, 0x08, 0x95, 0xe7, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WaitForEnlistment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Phase0Done;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unenlist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction** ppITransaction) GetTransaction;
	}


	public HRESULT Enable() mut => VT.[Friend]Enable(&this);

	public HRESULT WaitForEnlistment() mut => VT.[Friend]WaitForEnlistment(&this);

	public HRESULT Phase0Done() mut => VT.[Friend]Phase0Done(&this);

	public HRESULT Unenlist() mut => VT.[Friend]Unenlist(&this);

	public HRESULT GetTransaction(ITransaction** ppITransaction) mut => VT.[Friend]GetTransaction(&this, ppITransaction);
}

[CRepr]struct ITransactionPhase0NotifyAsync : IUnknown
{
	public new const Guid IID = .(0xef081809, 0x0c76, 0x11d2, 0x87, 0xa6, 0x00, 0xc0, 0x4f, 0x99, 0x0f, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fAbortingHint) Phase0Request;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT status) EnlistCompleted;
	}


	public HRESULT Phase0Request(BOOL fAbortingHint) mut => VT.[Friend]Phase0Request(&this, fAbortingHint);

	public HRESULT EnlistCompleted(HRESULT status) mut => VT.[Friend]EnlistCompleted(&this, status);
}

[CRepr]struct ITransactionPhase0Factory : IUnknown
{
	public new const Guid IID = .(0x82dc88e0, 0xa954, 0x11d1, 0x8f, 0x88, 0x00, 0x60, 0x08, 0x95, 0xe7, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionPhase0NotifyAsync* pPhase0Notify, ITransactionPhase0EnlistmentAsync** ppPhase0Enlistment) Create;
	}


	public HRESULT Create(ITransactionPhase0NotifyAsync* pPhase0Notify, ITransactionPhase0EnlistmentAsync** ppPhase0Enlistment) mut => VT.[Friend]Create(&this, pPhase0Notify, ppPhase0Enlistment);
}

[CRepr]struct ITransactionTransmitter : IUnknown
{
	public new const Guid IID = .(0x59313e01, 0xb36c, 0x11cf, 0xa5, 0x39, 0x00, 0xaa, 0x00, 0x68, 0x87, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransaction* pTransaction) Set;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbToken) GetPropagationTokenSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbToken, uint8* rgbToken, uint32* pcbUsed) MarshalPropagationToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbReturnToken, uint8* rgbReturnToken) UnmarshalReturnToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT Set(ITransaction* pTransaction) mut => VT.[Friend]Set(&this, pTransaction);

	public HRESULT GetPropagationTokenSize(uint32* pcbToken) mut => VT.[Friend]GetPropagationTokenSize(&this, pcbToken);

	public HRESULT MarshalPropagationToken(uint32 cbToken, uint8* rgbToken, uint32* pcbUsed) mut => VT.[Friend]MarshalPropagationToken(&this, cbToken, rgbToken, pcbUsed);

	public HRESULT UnmarshalReturnToken(uint32 cbReturnToken, uint8* rgbReturnToken) mut => VT.[Friend]UnmarshalReturnToken(&this, cbReturnToken, rgbReturnToken);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct ITransactionTransmitterFactory : IUnknown
{
	public new const Guid IID = .(0x59313e00, 0xb36c, 0x11cf, 0xa5, 0x39, 0x00, 0xaa, 0x00, 0x68, 0x87, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionTransmitter** ppTransmitter) Create;
	}


	public HRESULT Create(ITransactionTransmitter** ppTransmitter) mut => VT.[Friend]Create(&this, ppTransmitter);
}

[CRepr]struct ITransactionReceiver : IUnknown
{
	public new const Guid IID = .(0x59313e03, 0xb36c, 0x11cf, 0xa5, 0x39, 0x00, 0xaa, 0x00, 0x68, 0x87, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbToken, uint8* rgbToken, ITransaction** ppTransaction) UnmarshalPropagationToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbReturnToken) GetReturnTokenSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbReturnToken, uint8* rgbReturnToken, uint32* pcbUsed) MarshalReturnToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT UnmarshalPropagationToken(uint32 cbToken, uint8* rgbToken, ITransaction** ppTransaction) mut => VT.[Friend]UnmarshalPropagationToken(&this, cbToken, rgbToken, ppTransaction);

	public HRESULT GetReturnTokenSize(uint32* pcbReturnToken) mut => VT.[Friend]GetReturnTokenSize(&this, pcbReturnToken);

	public HRESULT MarshalReturnToken(uint32 cbReturnToken, uint8* rgbReturnToken, uint32* pcbUsed) mut => VT.[Friend]MarshalReturnToken(&this, cbReturnToken, rgbReturnToken, pcbUsed);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct ITransactionReceiverFactory : IUnknown
{
	public new const Guid IID = .(0x59313e02, 0xb36c, 0x11cf, 0xa5, 0x39, 0x00, 0xaa, 0x00, 0x68, 0x87, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransactionReceiver** ppReceiver) Create;
	}


	public HRESULT Create(ITransactionReceiver** ppReceiver) mut => VT.[Friend]Create(&this, ppReceiver);
}

[CRepr]struct IDtcLuConfigure : IUnknown
{
	public new const Guid IID = .(0x4131e760, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pucLuPair, uint32 cbLuPair) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pucLuPair, uint32 cbLuPair) Delete;
	}


	public HRESULT Add(uint8* pucLuPair, uint32 cbLuPair) mut => VT.[Friend]Add(&this, pucLuPair, cbLuPair);

	public HRESULT Delete(uint8* pucLuPair, uint32 cbLuPair) mut => VT.[Friend]Delete(&this, pucLuPair, cbLuPair);
}

[CRepr]struct IDtcLuRecovery : IUnknown
{
	public new const Guid IID = .(0xac2b8ad2, 0xd6f0, 0x11d0, 0xb3, 0x86, 0x00, 0xa0, 0xc9, 0x08, 0x33, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

[CRepr]struct IDtcLuRecoveryFactory : IUnknown
{
	public new const Guid IID = .(0x4131e762, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pucLuPair, uint32 cbLuPair, IDtcLuRecovery** ppRecovery) Create;
	}


	public HRESULT Create(uint8* pucLuPair, uint32 cbLuPair, IDtcLuRecovery** ppRecovery) mut => VT.[Friend]Create(&this, pucLuPair, cbLuPair, ppRecovery);
}

[CRepr]struct IDtcLuRecoveryInitiatedByDtcTransWork : IUnknown
{
	public new const Guid IID = .(0x4131e765, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbOurLogName, uint32* pcbRemoteLogName) GetLogNameSizes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUXLN* pXln, uint8* pOurLogName, uint8* pRemoteLogName, uint32* pdwProtocol) GetOurXln;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUXLNCONFIRMATION Confirmation) HandleConfirmationFromOurXln;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUXLN Xln, uint8* pRemoteLogName, uint32 cbRemoteLogName, uint32 dwProtocol, DTCLUXLNCONFIRMATION* pConfirmation) HandleTheirXlnResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUXLNERROR Error) HandleErrorFromOurXln;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fCompareStates) CheckForCompareStates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbOurTransId) GetOurTransIdSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pOurTransId, DTCLUCOMPARESTATE* pCompareState) GetOurCompareStates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUCOMPARESTATE CompareState, DTCLUCOMPARESTATESCONFIRMATION* pConfirmation) HandleTheirCompareStatesResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUCOMPARESTATESERROR Error) HandleErrorFromOurCompareStates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ConversationLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRecoverySeqNum) GetRecoverySeqNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lNewRecoverySeqNum) ObsoleteRecoverySeqNum;
	}


	public HRESULT GetLogNameSizes(uint32* pcbOurLogName, uint32* pcbRemoteLogName) mut => VT.[Friend]GetLogNameSizes(&this, pcbOurLogName, pcbRemoteLogName);

	public HRESULT GetOurXln(DTCLUXLN* pXln, uint8* pOurLogName, uint8* pRemoteLogName, uint32* pdwProtocol) mut => VT.[Friend]GetOurXln(&this, pXln, pOurLogName, pRemoteLogName, pdwProtocol);

	public HRESULT HandleConfirmationFromOurXln(DTCLUXLNCONFIRMATION Confirmation) mut => VT.[Friend]HandleConfirmationFromOurXln(&this, Confirmation);

	public HRESULT HandleTheirXlnResponse(DTCLUXLN Xln, uint8* pRemoteLogName, uint32 cbRemoteLogName, uint32 dwProtocol, DTCLUXLNCONFIRMATION* pConfirmation) mut => VT.[Friend]HandleTheirXlnResponse(&this, Xln, pRemoteLogName, cbRemoteLogName, dwProtocol, pConfirmation);

	public HRESULT HandleErrorFromOurXln(DTCLUXLNERROR Error) mut => VT.[Friend]HandleErrorFromOurXln(&this, Error);

	public HRESULT CheckForCompareStates(BOOL* fCompareStates) mut => VT.[Friend]CheckForCompareStates(&this, fCompareStates);

	public HRESULT GetOurTransIdSize(uint32* pcbOurTransId) mut => VT.[Friend]GetOurTransIdSize(&this, pcbOurTransId);

	public HRESULT GetOurCompareStates(uint8* pOurTransId, DTCLUCOMPARESTATE* pCompareState) mut => VT.[Friend]GetOurCompareStates(&this, pOurTransId, pCompareState);

	public HRESULT HandleTheirCompareStatesResponse(DTCLUCOMPARESTATE CompareState, DTCLUCOMPARESTATESCONFIRMATION* pConfirmation) mut => VT.[Friend]HandleTheirCompareStatesResponse(&this, CompareState, pConfirmation);

	public HRESULT HandleErrorFromOurCompareStates(DTCLUCOMPARESTATESERROR Error) mut => VT.[Friend]HandleErrorFromOurCompareStates(&this, Error);

	public HRESULT ConversationLost() mut => VT.[Friend]ConversationLost(&this);

	public HRESULT GetRecoverySeqNum(int32* plRecoverySeqNum) mut => VT.[Friend]GetRecoverySeqNum(&this, plRecoverySeqNum);

	public HRESULT ObsoleteRecoverySeqNum(int32 lNewRecoverySeqNum) mut => VT.[Friend]ObsoleteRecoverySeqNum(&this, lNewRecoverySeqNum);
}

[CRepr]struct IDtcLuRecoveryInitiatedByDtcStatusWork : IUnknown
{
	public new const Guid IID = .(0x4131e766, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRecoverySeqNum) HandleCheckLuStatus;
	}


	public HRESULT HandleCheckLuStatus(int32 lRecoverySeqNum) mut => VT.[Friend]HandleCheckLuStatus(&this, lRecoverySeqNum);
}

[CRepr]struct IDtcLuRecoveryInitiatedByDtc : IUnknown
{
	public new const Guid IID = .(0x4131e764, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCINITIATEDRECOVERYWORK* pWork, void** ppv) GetWork;
	}


	public HRESULT GetWork(DTCINITIATEDRECOVERYWORK* pWork, void** ppv) mut => VT.[Friend]GetWork(&this, pWork, ppv);
}

[CRepr]struct IDtcLuRecoveryInitiatedByLuWork : IUnknown
{
	public new const Guid IID = .(0xac2b8ad1, 0xd6f0, 0x11d0, 0xb3, 0x86, 0x00, 0xa0, 0xc9, 0x08, 0x33, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRecoverySeqNum, DTCLUXLN Xln, uint8* pRemoteLogName, uint32 cbRemoteLogName, uint8* pOurLogName, uint32 cbOurLogName, uint32 dwProtocol, DTCLUXLNRESPONSE* pResponse) HandleTheirXln;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbOurLogName) GetOurLogNameSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUXLN* pXln, uint8* pOurLogName, uint32* pdwProtocol) GetOurXln;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUXLNCONFIRMATION Confirmation) HandleConfirmationOfOurXln;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pRemoteTransId, uint32 cbRemoteTransId, DTCLUCOMPARESTATE CompareState, DTCLUCOMPARESTATESRESPONSE* pResponse, DTCLUCOMPARESTATE* pCompareState) HandleTheirCompareStates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUCOMPARESTATESCONFIRMATION Confirmation) HandleConfirmationOfOurCompareStates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DTCLUCOMPARESTATESERROR Error) HandleErrorFromOurCompareStates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ConversationLost;
	}


	public HRESULT HandleTheirXln(int32 lRecoverySeqNum, DTCLUXLN Xln, uint8* pRemoteLogName, uint32 cbRemoteLogName, uint8* pOurLogName, uint32 cbOurLogName, uint32 dwProtocol, DTCLUXLNRESPONSE* pResponse) mut => VT.[Friend]HandleTheirXln(&this, lRecoverySeqNum, Xln, pRemoteLogName, cbRemoteLogName, pOurLogName, cbOurLogName, dwProtocol, pResponse);

	public HRESULT GetOurLogNameSize(uint32* pcbOurLogName) mut => VT.[Friend]GetOurLogNameSize(&this, pcbOurLogName);

	public HRESULT GetOurXln(DTCLUXLN* pXln, uint8* pOurLogName, uint32* pdwProtocol) mut => VT.[Friend]GetOurXln(&this, pXln, pOurLogName, pdwProtocol);

	public HRESULT HandleConfirmationOfOurXln(DTCLUXLNCONFIRMATION Confirmation) mut => VT.[Friend]HandleConfirmationOfOurXln(&this, Confirmation);

	public HRESULT HandleTheirCompareStates(uint8* pRemoteTransId, uint32 cbRemoteTransId, DTCLUCOMPARESTATE CompareState, DTCLUCOMPARESTATESRESPONSE* pResponse, DTCLUCOMPARESTATE* pCompareState) mut => VT.[Friend]HandleTheirCompareStates(&this, pRemoteTransId, cbRemoteTransId, CompareState, pResponse, pCompareState);

	public HRESULT HandleConfirmationOfOurCompareStates(DTCLUCOMPARESTATESCONFIRMATION Confirmation) mut => VT.[Friend]HandleConfirmationOfOurCompareStates(&this, Confirmation);

	public HRESULT HandleErrorFromOurCompareStates(DTCLUCOMPARESTATESERROR Error) mut => VT.[Friend]HandleErrorFromOurCompareStates(&this, Error);

	public HRESULT ConversationLost() mut => VT.[Friend]ConversationLost(&this);
}

[CRepr]struct IDtcLuRecoveryInitiatedByLu : IUnknown
{
	public new const Guid IID = .(0x4131e768, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDtcLuRecoveryInitiatedByLuWork** ppWork) GetObjectToHandleWorkFromLu;
	}


	public HRESULT GetObjectToHandleWorkFromLu(IDtcLuRecoveryInitiatedByLuWork** ppWork) mut => VT.[Friend]GetObjectToHandleWorkFromLu(&this, ppWork);
}

[CRepr]struct IDtcLuRmEnlistment : IUnknown
{
	public new const Guid IID = .(0x4131e769, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fConversationLost) Unplug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackedOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Committed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Forget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestCommit;
	}


	public HRESULT Unplug(BOOL fConversationLost) mut => VT.[Friend]Unplug(&this, fConversationLost);

	public HRESULT BackedOut() mut => VT.[Friend]BackedOut(&this);

	public HRESULT BackOut() mut => VT.[Friend]BackOut(&this);

	public HRESULT Committed() mut => VT.[Friend]Committed(&this);

	public HRESULT Forget() mut => VT.[Friend]Forget(&this);

	public HRESULT RequestCommit() mut => VT.[Friend]RequestCommit(&this);
}

[CRepr]struct IDtcLuRmEnlistmentSink : IUnknown
{
	public new const Guid IID = .(0x4131e770, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AckUnplug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TmDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SessionLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackedOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Committed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Forget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Prepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestCommit;
	}


	public HRESULT AckUnplug() mut => VT.[Friend]AckUnplug(&this);

	public HRESULT TmDown() mut => VT.[Friend]TmDown(&this);

	public HRESULT SessionLost() mut => VT.[Friend]SessionLost(&this);

	public HRESULT BackedOut() mut => VT.[Friend]BackedOut(&this);

	public HRESULT BackOut() mut => VT.[Friend]BackOut(&this);

	public HRESULT Committed() mut => VT.[Friend]Committed(&this);

	public HRESULT Forget() mut => VT.[Friend]Forget(&this);

	public HRESULT Prepare() mut => VT.[Friend]Prepare(&this);

	public HRESULT RequestCommit() mut => VT.[Friend]RequestCommit(&this);
}

[CRepr]struct IDtcLuRmEnlistmentFactory : IUnknown
{
	public new const Guid IID = .(0x4131e771, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pucLuPair, uint32 cbLuPair, ITransaction* pITransaction, uint8* pTransId, uint32 cbTransId, IDtcLuRmEnlistmentSink* pRmEnlistmentSink, IDtcLuRmEnlistment** ppRmEnlistment) Create;
	}


	public HRESULT Create(uint8* pucLuPair, uint32 cbLuPair, ITransaction* pITransaction, uint8* pTransId, uint32 cbTransId, IDtcLuRmEnlistmentSink* pRmEnlistmentSink, IDtcLuRmEnlistment** ppRmEnlistment) mut => VT.[Friend]Create(&this, pucLuPair, cbLuPair, pITransaction, pTransId, cbTransId, pRmEnlistmentSink, ppRmEnlistment);
}

[CRepr]struct IDtcLuSubordinateDtc : IUnknown
{
	public new const Guid IID = .(0x4131e773, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fConversationLost) Unplug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackedOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Committed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Forget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Prepare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestCommit;
	}


	public HRESULT Unplug(BOOL fConversationLost) mut => VT.[Friend]Unplug(&this, fConversationLost);

	public HRESULT BackedOut() mut => VT.[Friend]BackedOut(&this);

	public HRESULT BackOut() mut => VT.[Friend]BackOut(&this);

	public HRESULT Committed() mut => VT.[Friend]Committed(&this);

	public HRESULT Forget() mut => VT.[Friend]Forget(&this);

	public HRESULT Prepare() mut => VT.[Friend]Prepare(&this);

	public HRESULT RequestCommit() mut => VT.[Friend]RequestCommit(&this);
}

[CRepr]struct IDtcLuSubordinateDtcSink : IUnknown
{
	public new const Guid IID = .(0x4131e774, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AckUnplug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TmDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SessionLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackedOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BackOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Committed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Forget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequestCommit;
	}


	public HRESULT AckUnplug() mut => VT.[Friend]AckUnplug(&this);

	public HRESULT TmDown() mut => VT.[Friend]TmDown(&this);

	public HRESULT SessionLost() mut => VT.[Friend]SessionLost(&this);

	public HRESULT BackedOut() mut => VT.[Friend]BackedOut(&this);

	public HRESULT BackOut() mut => VT.[Friend]BackOut(&this);

	public HRESULT Committed() mut => VT.[Friend]Committed(&this);

	public HRESULT Forget() mut => VT.[Friend]Forget(&this);

	public HRESULT RequestCommit() mut => VT.[Friend]RequestCommit(&this);
}

[CRepr]struct IDtcLuSubordinateDtcFactory : IUnknown
{
	public new const Guid IID = .(0x4131e775, 0x1aea, 0x11d0, 0x94, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pucLuPair, uint32 cbLuPair, IUnknown* punkTransactionOuter, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOptions, ITransaction** ppTransaction, uint8* pTransId, uint32 cbTransId, IDtcLuSubordinateDtcSink* pSubordinateDtcSink, IDtcLuSubordinateDtc** ppSubordinateDtc) Create;
	}


	public HRESULT Create(uint8* pucLuPair, uint32 cbLuPair, IUnknown* punkTransactionOuter, int32 isoLevel, uint32 isoFlags, ITransactionOptions* pOptions, ITransaction** ppTransaction, uint8* pTransId, uint32 cbTransId, IDtcLuSubordinateDtcSink* pSubordinateDtcSink, IDtcLuSubordinateDtc** ppSubordinateDtc) mut => VT.[Friend]Create(&this, pucLuPair, cbLuPair, punkTransactionOuter, isoLevel, isoFlags, pOptions, ppTransaction, pTransId, cbTransId, pSubordinateDtcSink, ppSubordinateDtc);
}

#endregion

#region Functions
public static
{
	[Import("XOLEHLP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DtcGetTransactionManager(PSTR i_pszHost, PSTR i_pszTmName, in Guid i_riid, uint32 i_dwReserved1, uint16 i_wcbReserved2, void* i_pvReserved2, void** o_ppvObject);

	[Import("XOLEHLP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DtcGetTransactionManagerC(PSTR i_pszHost, PSTR i_pszTmName, in Guid i_riid, uint32 i_dwReserved1, uint16 i_wcbReserved2, void* i_pvReserved2, void** o_ppvObject);

	[Import("XOLEHLP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DtcGetTransactionManagerExA(PSTR i_pszHost, PSTR i_pszTmName, in Guid i_riid, uint32 i_grfOptions, void* i_pvConfigParams, void** o_ppvObject);
	public static HRESULT DtcGetTransactionManagerEx(PSTR i_pszHost, PSTR i_pszTmName, in Guid i_riid, uint32 i_grfOptions, void* i_pvConfigParams, void** o_ppvObject) => DtcGetTransactionManagerExA(i_pszHost, i_pszTmName, i_riid, i_grfOptions, i_pvConfigParams, o_ppvObject);

	[Import("XOLEHLP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DtcGetTransactionManagerExW(PWSTR i_pwszHost, PWSTR i_pwszTmName, in Guid i_riid, uint32 i_grfOptions, void* i_pvConfigParams, void** o_ppvObject);

}
#endregion
