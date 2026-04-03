using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.Snmp;

#region Constants
public static
{
	public const uint32 ASN_UNIVERSAL = 0;
	public const uint32 ASN_APPLICATION = 64;
	public const uint32 ASN_CONTEXT = 128;
	public const uint32 ASN_PRIVATE = 192;
	public const uint32 ASN_PRIMITIVE = 0;
	public const uint32 ASN_CONSTRUCTOR = 32;
	public const uint32 SNMP_ACCESS_NONE = 0;
	public const uint32 SNMP_ACCESS_NOTIFY = 1;
	public const uint32 SNMP_ACCESS_READ_ONLY = 2;
	public const uint32 SNMP_ACCESS_READ_WRITE = 3;
	public const uint32 SNMP_ACCESS_READ_CREATE = 4;
	public const uint32 SNMPAPI_NOERROR = 1;
	public const uint32 SNMPAPI_ERROR = 0;
	public const uint32 SNMP_OUTPUT_TO_EVENTLOG = 4;
	public const uint32 DEFAULT_SNMP_PORT_UDP = 161;
	public const uint32 DEFAULT_SNMP_PORT_IPX = 36879;
	public const uint32 DEFAULT_SNMPTRAP_PORT_UDP = 162;
	public const uint32 DEFAULT_SNMPTRAP_PORT_IPX = 36880;
	public const uint32 SNMP_MAX_OID_LEN = 128;
	public const uint32 SNMP_MEM_ALLOC_ERROR = 1;
	public const uint32 SNMP_BERAPI_INVALID_LENGTH = 10;
	public const uint32 SNMP_BERAPI_INVALID_TAG = 11;
	public const uint32 SNMP_BERAPI_OVERFLOW = 12;
	public const uint32 SNMP_BERAPI_SHORT_BUFFER = 13;
	public const uint32 SNMP_BERAPI_INVALID_OBJELEM = 14;
	public const uint32 SNMP_PDUAPI_UNRECOGNIZED_PDU = 20;
	public const uint32 SNMP_PDUAPI_INVALID_ES = 21;
	public const uint32 SNMP_PDUAPI_INVALID_GT = 22;
	public const uint32 SNMP_AUTHAPI_INVALID_VERSION = 30;
	public const uint32 SNMP_AUTHAPI_INVALID_MSG_TYPE = 31;
	public const uint32 SNMP_AUTHAPI_TRIV_AUTH_FAILED = 32;
	public const uint32 ASN_CONTEXTSPECIFIC = 128;
	public const uint32 ASN_PRIMATIVE = 0;
	public const uint32 SNMP_MGMTAPI_TIMEOUT = 40;
	public const uint32 SNMP_MGMTAPI_SELECT_FDERRORS = 41;
	public const uint32 SNMP_MGMTAPI_TRAP_ERRORS = 42;
	public const uint32 SNMP_MGMTAPI_TRAP_DUPINIT = 43;
	public const uint32 SNMP_MGMTAPI_NOTRAPS = 44;
	public const uint32 SNMP_MGMTAPI_AGAIN = 45;
	public const uint32 SNMP_MGMTAPI_INVALID_CTL = 46;
	public const uint32 SNMP_MGMTAPI_INVALID_SESSION = 47;
	public const uint32 SNMP_MGMTAPI_INVALID_BUFFER = 48;
	public const uint32 MGMCTL_SETAGENTPORT = 1;
	public const uint32 MAXOBJIDSIZE = 128;
	public const uint32 MAXOBJIDSTRSIZE = 1408;
	public const uint32 SNMPLISTEN_USEENTITY_ADDR = 0;
	public const uint32 SNMPLISTEN_ALL_ADDR = 1;
	public const uint32 SNMP_TRAP_COLDSTART = 0;
	public const uint32 SNMP_TRAP_WARMSTART = 1;
	public const uint32 SNMP_TRAP_LINKDOWN = 2;
	public const uint32 SNMP_TRAP_LINKUP = 3;
	public const uint32 SNMP_TRAP_AUTHFAIL = 4;
	public const uint32 SNMP_TRAP_EGPNEIGHBORLOSS = 5;
	public const uint32 SNMP_TRAP_ENTERPRISESPECIFIC = 6;
	public const uint32 SNMPAPI_NO_SUPPORT = 0;
	public const uint32 SNMPAPI_V1_SUPPORT = 1;
	public const uint32 SNMPAPI_V2_SUPPORT = 2;
	public const uint32 SNMPAPI_M2M_SUPPORT = 3;
	public const uint32 SNMPAPI_FAILURE = 0;
	public const uint32 SNMPAPI_SUCCESS = 1;
	public const uint32 SNMPAPI_ALLOC_ERROR = 2;
	public const uint32 SNMPAPI_CONTEXT_INVALID = 3;
	public const uint32 SNMPAPI_CONTEXT_UNKNOWN = 4;
	public const uint32 SNMPAPI_ENTITY_INVALID = 5;
	public const uint32 SNMPAPI_ENTITY_UNKNOWN = 6;
	public const uint32 SNMPAPI_INDEX_INVALID = 7;
	public const uint32 SNMPAPI_NOOP = 8;
	public const uint32 SNMPAPI_OID_INVALID = 9;
	public const uint32 SNMPAPI_OPERATION_INVALID = 10;
	public const uint32 SNMPAPI_OUTPUT_TRUNCATED = 11;
	public const uint32 SNMPAPI_PDU_INVALID = 12;
	public const uint32 SNMPAPI_SESSION_INVALID = 13;
	public const uint32 SNMPAPI_SYNTAX_INVALID = 14;
	public const uint32 SNMPAPI_VBL_INVALID = 15;
	public const uint32 SNMPAPI_MODE_INVALID = 16;
	public const uint32 SNMPAPI_SIZE_INVALID = 17;
	public const uint32 SNMPAPI_NOT_INITIALIZED = 18;
	public const uint32 SNMPAPI_MESSAGE_INVALID = 19;
	public const uint32 SNMPAPI_HWND_INVALID = 20;
	public const uint32 SNMPAPI_OTHER_ERROR = 99;
	public const uint32 SNMPAPI_TL_NOT_INITIALIZED = 100;
	public const uint32 SNMPAPI_TL_NOT_SUPPORTED = 101;
	public const uint32 SNMPAPI_TL_NOT_AVAILABLE = 102;
	public const uint32 SNMPAPI_TL_RESOURCE_ERROR = 103;
	public const uint32 SNMPAPI_TL_UNDELIVERABLE = 104;
	public const uint32 SNMPAPI_TL_SRC_INVALID = 105;
	public const uint32 SNMPAPI_TL_INVALID_PARAM = 106;
	public const uint32 SNMPAPI_TL_IN_USE = 107;
	public const uint32 SNMPAPI_TL_TIMEOUT = 108;
	public const uint32 SNMPAPI_TL_PDU_TOO_BIG = 109;
	public const uint32 SNMPAPI_TL_OTHER = 199;
	public const uint32 MAXVENDORINFO = 32;
}
#endregion

#region Enums

[AllowDuplicates]
public enum SNMP_PDU_TYPE : uint32
{
	SNMP_PDU_GET = 160,
	SNMP_PDU_GETNEXT = 161,
	SNMP_PDU_RESPONSE = 162,
	SNMP_PDU_SET = 163,
	SNMP_PDU_GETBULK = 165,
	SNMP_PDU_TRAP = 167,
}


[AllowDuplicates]
public enum SNMP_EXTENSION_REQUEST_TYPE : uint32
{
	SNMP_EXTENSION_GET = 160,
	SNMP_EXTENSION_GET_NEXT = 161,
	SNMP_EXTENSION_SET_TEST = 224,
	SNMP_EXTENSION_SET_COMMIT = 163,
	SNMP_EXTENSION_SET_UNDO = 225,
	SNMP_EXTENSION_SET_CLEANUP = 226,
}


[AllowDuplicates]
public enum SNMP_API_TRANSLATE_MODE : uint32
{
	SNMPAPI_TRANSLATED = 0,
	SNMPAPI_UNTRANSLATED_V1 = 1,
	SNMPAPI_UNTRANSLATED_V2 = 2,
}


[AllowDuplicates]
public enum SNMP_GENERICTRAP : uint32
{
	SNMP_GENERICTRAP_COLDSTART = 0,
	SNMP_GENERICTRAP_WARMSTART = 1,
	SNMP_GENERICTRAP_LINKDOWN = 2,
	SNMP_GENERICTRAP_LINKUP = 3,
	SNMP_GENERICTRAP_AUTHFAILURE = 4,
	SNMP_GENERICTRAP_EGPNEIGHLOSS = 5,
	SNMP_GENERICTRAP_ENTERSPECIFIC = 6,
}


[AllowDuplicates]
public enum SNMP_ERROR_STATUS : uint32
{
	SNMP_ERRORSTATUS_NOERROR = 0,
	SNMP_ERRORSTATUS_TOOBIG = 1,
	SNMP_ERRORSTATUS_NOSUCHNAME = 2,
	SNMP_ERRORSTATUS_BADVALUE = 3,
	SNMP_ERRORSTATUS_READONLY = 4,
	SNMP_ERRORSTATUS_GENERR = 5,
	SNMP_ERRORSTATUS_NOACCESS = 6,
	SNMP_ERRORSTATUS_WRONGTYPE = 7,
	SNMP_ERRORSTATUS_WRONGLENGTH = 8,
	SNMP_ERRORSTATUS_WRONGENCODING = 9,
	SNMP_ERRORSTATUS_WRONGVALUE = 10,
	SNMP_ERRORSTATUS_NOCREATION = 11,
	SNMP_ERRORSTATUS_INCONSISTENTVALUE = 12,
	SNMP_ERRORSTATUS_RESOURCEUNAVAILABLE = 13,
	SNMP_ERRORSTATUS_COMMITFAILED = 14,
	SNMP_ERRORSTATUS_UNDOFAILED = 15,
	SNMP_ERRORSTATUS_AUTHORIZATIONERROR = 16,
	SNMP_ERRORSTATUS_NOTWRITABLE = 17,
	SNMP_ERRORSTATUS_INCONSISTENTNAME = 18,
}


[AllowDuplicates]
public enum SNMP_STATUS : uint32
{
	SNMPAPI_ON = 1,
	SNMPAPI_OFF = 0,
}


[AllowDuplicates]
public enum SNMP_OUTPUT_LOG_TYPE : uint32
{
	SNMP_OUTPUT_TO_CONSOLE = 1,
	SNMP_OUTPUT_TO_LOGFILE = 2,
	SNMP_OUTPUT_TO_DEBUGGER = 8,
}


[AllowDuplicates]
public enum SNMP_LOG : uint32
{
	SNMP_LOG_SILENT = 0,
	SNMP_LOG_FATAL = 1,
	SNMP_LOG_ERROR = 2,
	SNMP_LOG_WARNING = 3,
	SNMP_LOG_TRACE = 4,
	SNMP_LOG_VERBOSE = 5,
}


[AllowDuplicates]
public enum SNMP_ERROR : uint32
{
	SNMP_ERROR_NOERROR = 0,
	SNMP_ERROR_TOOBIG = 1,
	SNMP_ERROR_NOSUCHNAME = 2,
	SNMP_ERROR_BADVALUE = 3,
	SNMP_ERROR_READONLY = 4,
	SNMP_ERROR_GENERR = 5,
	SNMP_ERROR_NOACCESS = 6,
	SNMP_ERROR_WRONGTYPE = 7,
	SNMP_ERROR_WRONGLENGTH = 8,
	SNMP_ERROR_WRONGENCODING = 9,
	SNMP_ERROR_WRONGVALUE = 10,
	SNMP_ERROR_NOCREATION = 11,
	SNMP_ERROR_INCONSISTENTVALUE = 12,
	SNMP_ERROR_RESOURCEUNAVAILABLE = 13,
	SNMP_ERROR_COMMITFAILED = 14,
	SNMP_ERROR_UNDOFAILED = 15,
	SNMP_ERROR_AUTHORIZATIONERROR = 16,
	SNMP_ERROR_NOTWRITABLE = 17,
	SNMP_ERROR_INCONSISTENTNAME = 18,
}

#endregion

#region Function Pointers
public function BOOL PFNSNMPEXTENSIONINIT(uint32 dwUpTimeReference, HANDLE* phSubagentTrapEvent, AsnObjectIdentifier* pFirstSupportedRegion);

public function BOOL PFNSNMPEXTENSIONINITEX(AsnObjectIdentifier* pNextSupportedRegion);

public function BOOL PFNSNMPEXTENSIONMONITOR(void* pAgentMgmtData);

public function BOOL PFNSNMPEXTENSIONQUERY(uint8 bPduType, SnmpVarBindList* pVarBindList, int32* pErrorStatus, int32* pErrorIndex);

public function BOOL PFNSNMPEXTENSIONQUERYEX(uint32 nRequestType, uint32 nTransactionId, SnmpVarBindList* pVarBindList, AsnOctetString* pContextInfo, int32* pErrorStatus, int32* pErrorIndex);

public function BOOL PFNSNMPEXTENSIONTRAP(AsnObjectIdentifier* pEnterpriseOid, int32* pGenericTrapId, int32* pSpecificTrapId, uint32* pTimeStamp, SnmpVarBindList* pVarBindList);

public function void PFNSNMPEXTENSIONCLOSE();

public function uint32 SNMPAPI_CALLBACK(int hSession, HWND hWnd, uint32 wMsg, WPARAM wParam, LPARAM lParam, void* lpClientData);

public function uint32 PFNSNMPSTARTUPEX(uint32* param0, uint32* param1, uint32* param2, uint32* param3, uint32* param4);

public function uint32 PFNSNMPCLEANUPEX();

#endregion

#region Structs
[CRepr, Packed(4)]
public struct AsnOctetString
{
	public uint8* stream;
	public uint32 length;
	public BOOL dynamic;
}

[CRepr, Packed(4)]
public struct AsnObjectIdentifier
{
	public uint32 idLength;
	public uint32* ids;
}

[CRepr, Packed(4)]
public struct AsnAny
{
	[CRepr, Union, Packed(4)]
	public struct _asnValue_e__Union
	{
		public int32 number;
		public uint32 unsigned32;
		public ULARGE_INTEGER counter64;
		public AsnOctetString string;
		public AsnOctetString bits;
		public AsnObjectIdentifier object;
		public AsnOctetString sequence;
		public AsnOctetString address;
		public uint32 counter;
		public uint32 gauge;
		public uint32 ticks;
		public AsnOctetString arbitrary;
	}
	public uint8 asnType;
	public _asnValue_e__Union asnValue;
}

[CRepr, Packed(4)]
public struct SnmpVarBind
{
	public AsnObjectIdentifier name;
	public AsnAny value;
}

[CRepr, Packed(4)]
public struct SnmpVarBindList
{
	public SnmpVarBind* list;
	public uint32 len;
}

[CRepr]
public struct smiOCTETS
{
	public uint32 len;
	public uint8* ptr;
}

[CRepr]
public struct smiOID
{
	public uint32 len;
	public uint32* ptr;
}

[CRepr]
public struct smiCNTR64
{
	public uint32 hipart;
	public uint32 lopart;
}

[CRepr]
public struct smiVALUE
{
	[CRepr, Union]
	public struct _value_e__Union
	{
		public int32 sNumber;
		public uint32 uNumber;
		public smiCNTR64 hNumber;
		public smiOCTETS string;
		public smiOID oid;
		public uint8 empty;
	}
	public uint32 syntax;
	public _value_e__Union value;
}

[CRepr]
public struct smiVENDORINFO
{
	public CHAR[64] vendorName;
	public CHAR[64] vendorContact;
	public CHAR[32] vendorVersionId;
	public CHAR[32] vendorVersionDate;
	public uint32 vendorEnterprise;
}

#endregion

#region Functions
public static
{
	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOidCpy(AsnObjectIdentifier* pOidDst, AsnObjectIdentifier* pOidSrc);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOidAppend(AsnObjectIdentifier* pOidDst, AsnObjectIdentifier* pOidSrc);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOidNCmp(AsnObjectIdentifier* pOid1, AsnObjectIdentifier* pOid2, uint32 nSubIds);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOidCmp(AsnObjectIdentifier* pOid1, AsnObjectIdentifier* pOid2);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilOidFree(AsnObjectIdentifier* pOid);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOctetsCmp(AsnOctetString* pOctets1, AsnOctetString* pOctets2);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOctetsNCmp(AsnOctetString* pOctets1, AsnOctetString* pOctets2, uint32 nChars);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilOctetsCpy(AsnOctetString* pOctetsDst, AsnOctetString* pOctetsSrc);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilOctetsFree(AsnOctetString* pOctets);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilAsnAnyCpy(AsnAny* pAnyDst, AsnAny* pAnySrc);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilAsnAnyFree(AsnAny* pAny);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilVarBindCpy(SnmpVarBind* pVbDst, SnmpVarBind* pVbSrc);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilVarBindFree(SnmpVarBind* pVb);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpUtilVarBindListCpy(SnmpVarBindList* pVblDst, SnmpVarBindList* pVblSrc);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilVarBindListFree(SnmpVarBindList* pVbl);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilMemFree(void* pMem);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SnmpUtilMemAlloc(uint32 nBytes);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SnmpUtilMemReAlloc(void* pMem, uint32 nBytes);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR SnmpUtilOidToA(AsnObjectIdentifier* Oid);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR SnmpUtilIdsToA(uint32* Ids, uint32 IdLength);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilPrintOid(AsnObjectIdentifier* Oid);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilPrintAsnAny(AsnAny* pAny);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSvcGetUptime();

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpSvcSetLogLevel(SNMP_LOG nLogLevel);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpSvcSetLogType(SNMP_OUTPUT_LOG_TYPE nLogType);

	[Import("snmpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SnmpUtilDbgPrint(SNMP_LOG nLogLevel, PSTR szFormat);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SnmpMgrOpen(PSTR lpAgentAddress, PSTR lpAgentCommunity, int32 nTimeOut, int32 nRetries);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrCtl(void* session, uint32 dwCtlCode, void* lpvInBuffer, uint32 cbInBuffer, void* lpvOUTBuffer, uint32 cbOUTBuffer, uint32* lpcbBytesReturned);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrClose(void* session);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SnmpMgrRequest(void* session, uint8 requestType, SnmpVarBindList* variableBindings, SNMP_ERROR_STATUS* errorStatus, int32* errorIndex);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrStrToOid(PSTR string, AsnObjectIdentifier* oid);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrOidToStr(AsnObjectIdentifier* oid, PSTR* string);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrTrapListen(HANDLE* phTrapAvailable);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrGetTrap(AsnObjectIdentifier* enterprise, AsnOctetString* IPAddress, SNMP_GENERICTRAP* genericTrap, int32* specificTrap, uint32* timeStamp, SnmpVarBindList* variableBindings);

	[Import("mgmtapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SnmpMgrGetTrapEx(AsnObjectIdentifier* enterprise, AsnOctetString* agentAddress, AsnOctetString* sourceAddress, SNMP_GENERICTRAP* genericTrap, int32* specificTrap, AsnOctetString* community, uint32* timeStamp, SnmpVarBindList* variableBindings);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetTranslateMode(SNMP_API_TRANSLATE_MODE* nTranslateMode);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetTranslateMode(SNMP_API_TRANSLATE_MODE nTranslateMode);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetRetransmitMode(SNMP_STATUS* nRetransmitMode);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetRetransmitMode(SNMP_STATUS nRetransmitMode);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetTimeout(int hEntity, uint32* nPolicyTimeout, uint32* nActualTimeout);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetTimeout(int hEntity, uint32 nPolicyTimeout);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetRetry(int hEntity, uint32* nPolicyRetry, uint32* nActualRetry);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetRetry(int hEntity, uint32 nPolicyRetry);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetVendorInfo(smiVENDORINFO* vendorInfo);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpStartup(uint32* nMajorVersion, uint32* nMinorVersion, uint32* nLevel, SNMP_API_TRANSLATE_MODE* nTranslateMode, SNMP_STATUS* nRetransmitMode);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpCleanup();

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpOpen(HWND hWnd, uint32 wMsg);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpClose(int session);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSendMsg(int session, int srcEntity, int dstEntity, int context, int PDU);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpRecvMsg(int session, int* srcEntity, int* dstEntity, int* context, int* PDU);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpRegister(int session, int srcEntity, int dstEntity, int context, smiOID* notification, SNMP_STATUS state);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpCreateSession(HWND hWnd, uint32 wMsg, SNMPAPI_CALLBACK fCallBack, void* lpClientData);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpListen(int hEntity, SNMP_STATUS lStatus);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpListenEx(int hEntity, uint32 lStatus, uint32 nUseEntityAddr);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpCancelMsg(int session, int32 reqId);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpStartupEx(uint32* nMajorVersion, uint32* nMinorVersion, uint32* nLevel, SNMP_API_TRANSLATE_MODE* nTranslateMode, SNMP_STATUS* nRetransmitMode);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpCleanupEx();

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpStrToEntity(int session, PSTR string);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpEntityToStr(int entity, uint32 size, uint8* string);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpFreeEntity(int entity);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpStrToContext(int session, smiOCTETS* string);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpContextToStr(int context, smiOCTETS* string);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpFreeContext(int context);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetPort(int hEntity, uint32 nPort);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpCreatePdu(int session, SNMP_PDU_TYPE PDU_type, int32 request_id, int32 error_status, int32 error_index, int varbindlist);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetPduData(int PDU, SNMP_PDU_TYPE* PDU_type, int32* request_id, SNMP_ERROR* error_status, int32* error_index, int* varbindlist);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetPduData(int PDU, int32* PDU_type, int32* request_id, int32* non_repeaters, int32* max_repetitions, int* varbindlist);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpDuplicatePdu(int session, int PDU);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpFreePdu(int PDU);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpCreateVbl(int session, smiOID* name, smiVALUE* value);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int SnmpDuplicateVbl(int session, int vbl);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpFreeVbl(int vbl);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpCountVbl(int vbl);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetVb(int vbl, uint32 index, smiOID* name, smiVALUE* value);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpSetVb(int vbl, uint32 index, smiOID* name, smiVALUE* value);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpDeleteVb(int vbl, uint32 index);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpGetLastError(int session);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpStrToOid(PSTR string, smiOID* dstOID);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpOidToStr(smiOID* srcOID, uint32 size, uint8* string);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpOidCopy(smiOID* srcOID, smiOID* dstOID);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpOidCompare(smiOID* xOID, smiOID* yOID, uint32 maxlen, int32* result);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpEncodeMsg(int session, int srcEntity, int dstEntity, int context, int pdu, smiOCTETS* msgBufDesc);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpDecodeMsg(int session, int* srcEntity, int* dstEntity, int* context, int* pdu, smiOCTETS* msgBufDesc);

	[Import("wsnmp32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SnmpFreeDescriptor(uint32 syntax, smiOCTETS* descriptor);

}
#endregion
