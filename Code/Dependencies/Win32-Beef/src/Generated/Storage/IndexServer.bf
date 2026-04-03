using Win32.Foundation;
using Win32.System.Com.StructuredStorage;
using Win32.System.Com;
using System;

namespace Win32.Storage.IndexServer;

#region Constants
public static
{
	public const uint32 CI_VERSION_WDS30 = 258;
	public const uint32 CI_VERSION_WDS40 = 265;
	public const uint32 CI_VERSION_WIN70 = 1792;
	public const String CINULLCATALOG = "::_noindex_::";
	public const String CIADMIN = "::_nodocstore_::";
	public const uint32 LIFF_LOAD_DEFINED_FILTER = 1;
	public const uint32 LIFF_IMPLEMENT_TEXT_FILTER_FALLBACK_POLICY = 2;
	public const uint32 LIFF_FORCE_TEXT_FILTER_FALLBACK = 3;
	public const uint32 PID_FILENAME = 100;
	public const uint32 DBPROP_CI_CATALOG_NAME = 2;
	public const uint32 DBPROP_CI_INCLUDE_SCOPES = 3;
	public const uint32 DBPROP_CI_DEPTHS = 4;
	public const uint32 DBPROP_CI_SCOPE_FLAGS = 4;
	public const uint32 DBPROP_CI_EXCLUDE_SCOPES = 5;
	public const uint32 DBPROP_CI_SECURITY_ID = 6;
	public const uint32 DBPROP_CI_QUERY_TYPE = 7;
	public const uint32 DBPROP_CI_PROVIDER = 8;
	public const uint32 CI_PROVIDER_MSSEARCH = 1;
	public const uint32 CI_PROVIDER_INDEXING_SERVICE = 2;
	public const uint32 CI_PROVIDER_ALL = 4294967295;
	public const uint32 DBPROP_DEFAULT_EQUALS_BEHAVIOR = 2;
	public const uint32 DBPROP_USECONTENTINDEX = 2;
	public const uint32 DBPROP_DEFERNONINDEXEDTRIMMING = 3;
	public const uint32 DBPROP_USEEXTENDEDDBTYPES = 4;
	public const uint32 DBPROP_IGNORENOISEONLYCLAUSES = 5;
	public const uint32 DBPROP_GENERICOPTIONS_STRING = 6;
	public const uint32 DBPROP_FIRSTROWS = 7;
	public const uint32 DBPROP_DEFERCATALOGVERIFICATION = 8;
	public const uint32 DBPROP_CATALOGLISTID = 9;
	public const uint32 DBPROP_GENERATEPARSETREE = 10;
	public const uint32 DBPROP_APPLICATION_NAME = 11;
	public const uint32 DBPROP_FREETEXTANYTERM = 12;
	public const uint32 DBPROP_FREETEXTUSESTEMMING = 13;
	public const uint32 DBPROP_IGNORESBRI = 14;
	public const uint32 DBPROP_DONOTCOMPUTEEXPENSIVEPROPS = 15;
	public const uint32 DBPROP_ENABLEROWSETEVENTS = 16;
	public const uint32 DBPROP_MACHINE = 2;
	public const uint32 DBPROP_CLIENT_CLSID = 3;
	public const uint32 MSIDXSPROP_ROWSETQUERYSTATUS = 2;
	public const uint32 MSIDXSPROP_COMMAND_LOCALE_STRING = 3;
	public const uint32 MSIDXSPROP_QUERY_RESTRICTION = 4;
	public const uint32 MSIDXSPROP_PARSE_TREE = 5;
	public const uint32 MSIDXSPROP_MAX_RANK = 6;
	public const uint32 MSIDXSPROP_RESULTS_FOUND = 7;
	public const uint32 MSIDXSPROP_WHEREID = 8;
	public const uint32 MSIDXSPROP_SERVER_VERSION = 9;
	public const uint32 MSIDXSPROP_SERVER_WINVER_MAJOR = 10;
	public const uint32 MSIDXSPROP_SERVER_WINVER_MINOR = 11;
	public const uint32 MSIDXSPROP_SERVER_NLSVERSION = 12;
	public const uint32 MSIDXSPROP_SERVER_NLSVER_DEFINED = 13;
	public const uint32 MSIDXSPROP_SAME_SORTORDER_USED = 14;
	public const uint32 STAT_BUSY = 0;
	public const uint32 STAT_ERROR = 1;
	public const uint32 STAT_DONE = 2;
	public const uint32 STAT_REFRESH = 3;
	public const uint32 STAT_PARTIAL_SCOPE = 8;
	public const uint32 STAT_NOISE_WORDS = 16;
	public const uint32 STAT_CONTENT_OUT_OF_DATE = 32;
	public const uint32 STAT_REFRESH_INCOMPLETE = 64;
	public const uint32 STAT_CONTENT_QUERY_INCOMPLETE = 128;
	public const uint32 STAT_TIME_LIMIT_EXCEEDED = 256;
	public const uint32 STAT_SHARING_VIOLATION = 512;
	public const uint32 STAT_MISSING_RELDOC = 1024;
	public const uint32 STAT_MISSING_PROP_IN_RELDOC = 2048;
	public const uint32 STAT_RELDOC_ACCESS_DENIED = 4096;
	public const uint32 STAT_COALESCE_COMP_ALL_NOISE = 8192;
	public const uint32 QUERY_SHALLOW = 0;
	public const uint32 QUERY_DEEP = 1;
	public const uint32 QUERY_PHYSICAL_PATH = 0;
	public const uint32 QUERY_VIRTUAL_PATH = 2;
	public const uint32 PROPID_QUERY_WORKID = 5;
	public const uint32 PROPID_QUERY_UNFILTERED = 7;
	public const uint32 PROPID_QUERY_VIRTUALPATH = 9;
	public const uint32 PROPID_QUERY_LASTSEENTIME = 10;
	public const uint32 CICAT_STOPPED = 1;
	public const uint32 CICAT_READONLY = 2;
	public const uint32 CICAT_WRITABLE = 4;
	public const uint32 CICAT_NO_QUERY = 8;
	public const uint32 CICAT_GET_STATE = 16;
	public const uint32 CICAT_ALL_OPENED = 32;
	public const uint32 CI_STATE_SHADOW_MERGE = 1;
	public const uint32 CI_STATE_MASTER_MERGE = 2;
	public const uint32 CI_STATE_CONTENT_SCAN_REQUIRED = 4;
	public const uint32 CI_STATE_ANNEALING_MERGE = 8;
	public const uint32 CI_STATE_SCANNING = 16;
	public const uint32 CI_STATE_RECOVERING = 32;
	public const uint32 CI_STATE_INDEX_MIGRATION_MERGE = 64;
	public const uint32 CI_STATE_LOW_MEMORY = 128;
	public const uint32 CI_STATE_HIGH_IO = 256;
	public const uint32 CI_STATE_MASTER_MERGE_PAUSED = 512;
	public const uint32 CI_STATE_READ_ONLY = 1024;
	public const uint32 CI_STATE_BATTERY_POWER = 2048;
	public const uint32 CI_STATE_USER_ACTIVE = 4096;
	public const uint32 CI_STATE_STARTING = 8192;
	public const uint32 CI_STATE_READING_USNS = 16384;
	public const uint32 CI_STATE_DELETION_MERGE = 32768;
	public const uint32 CI_STATE_LOW_DISK = 65536;
	public const uint32 CI_STATE_HIGH_CPU = 131072;
	public const uint32 CI_STATE_BATTERY_POLICY = 262144;
	public const uint32 GENERATE_METHOD_EXACT = 0;
	public const uint32 GENERATE_METHOD_PREFIX = 1;
	public const uint32 GENERATE_METHOD_INFLECT = 2;
	public const uint32 SCOPE_FLAG_MASK = 255;
	public const uint32 SCOPE_FLAG_INCLUDE = 1;
	public const uint32 SCOPE_FLAG_DEEP = 2;
	public const uint32 SCOPE_TYPE_MASK = 4294967040;
	public const uint32 SCOPE_TYPE_WINPATH = 256;
	public const uint32 SCOPE_TYPE_VPATH = 512;
	public const uint32 PROPID_QUERY_RANKVECTOR = 2;
	public const uint32 PROPID_QUERY_RANK = 3;
	public const uint32 PROPID_QUERY_HITCOUNT = 4;
	public const uint32 PROPID_QUERY_ALL = 6;
	public const uint32 PROPID_STG_CONTENTS = 19;
	public const uint32 VECTOR_RANK_MIN = 0;
	public const uint32 VECTOR_RANK_MAX = 1;
	public const uint32 VECTOR_RANK_INNER = 2;
	public const uint32 VECTOR_RANK_DICE = 3;
	public const uint32 VECTOR_RANK_JACCARD = 4;
	public const uint32 DBSETFUNC_NONE = 0;
	public const uint32 DBSETFUNC_ALL = 1;
	public const uint32 DBSETFUNC_DISTINCT = 2;
	public const uint32 PROXIMITY_UNIT_WORD = 0;
	public const uint32 PROXIMITY_UNIT_SENTENCE = 1;
	public const uint32 PROXIMITY_UNIT_PARAGRAPH = 2;
	public const uint32 PROXIMITY_UNIT_CHAPTER = 3;
	public const HRESULT NOT_AN_ERROR = 524288;
	public const HRESULT FILTER_E_END_OF_CHUNKS = -2147215616;
	public const HRESULT FILTER_E_NO_MORE_TEXT = -2147215615;
	public const HRESULT FILTER_E_NO_MORE_VALUES = -2147215614;
	public const HRESULT FILTER_E_ACCESS = -2147215613;
	public const HRESULT FILTER_W_MONIKER_CLIPPED = 268036;
	public const HRESULT FILTER_E_NO_TEXT = -2147215611;
	public const HRESULT FILTER_E_NO_VALUES = -2147215610;
	public const HRESULT FILTER_E_EMBEDDING_UNAVAILABLE = -2147215609;
	public const HRESULT FILTER_E_LINK_UNAVAILABLE = -2147215608;
	public const HRESULT FILTER_S_LAST_TEXT = 268041;
	public const HRESULT FILTER_S_LAST_VALUES = 268042;
	public const HRESULT FILTER_E_PASSWORD = -2147215605;
	public const HRESULT FILTER_E_UNKNOWNFORMAT = -2147215604;
}
#endregion

#region Enums

[AllowDuplicates]
public enum IFILTER_INIT : int32
{
	IFILTER_INIT_CANON_PARAGRAPHS = 1,
	IFILTER_INIT_HARD_LINE_BREAKS = 2,
	IFILTER_INIT_CANON_HYPHENS = 4,
	IFILTER_INIT_CANON_SPACES = 8,
	IFILTER_INIT_APPLY_INDEX_ATTRIBUTES = 16,
	IFILTER_INIT_APPLY_OTHER_ATTRIBUTES = 32,
	IFILTER_INIT_APPLY_CRAWL_ATTRIBUTES = 256,
	IFILTER_INIT_INDEXING_ONLY = 64,
	IFILTER_INIT_SEARCH_LINKS = 128,
	IFILTER_INIT_FILTER_OWNED_VALUE_OK = 512,
	IFILTER_INIT_FILTER_AGGRESSIVE_BREAK = 1024,
	IFILTER_INIT_DISABLE_EMBEDDED = 2048,
	IFILTER_INIT_EMIT_FORMATTING = 4096,
}


[AllowDuplicates]
public enum IFILTER_FLAGS : int32
{
	IFILTER_FLAGS_OLE_PROPERTIES = 1,
}


[AllowDuplicates]
public enum CHUNKSTATE : int32
{
	CHUNK_TEXT = 1,
	CHUNK_VALUE = 2,
	CHUNK_FILTER_OWNED_VALUE = 4,
}


[AllowDuplicates]
public enum CHUNK_BREAKTYPE : int32
{
	CHUNK_NO_BREAK = 0,
	CHUNK_EOW = 1,
	CHUNK_EOS = 2,
	CHUNK_EOP = 3,
	CHUNK_EOC = 4,
}


[AllowDuplicates]
public enum WORDREP_BREAK_TYPE : int32
{
	WORDREP_BREAK_EOW = 0,
	WORDREP_BREAK_EOS = 1,
	WORDREP_BREAK_EOP = 2,
	WORDREP_BREAK_EOC = 3,
}


[AllowDuplicates]
public enum DBKINDENUM : int32
{
	DBKIND_GUID_NAME = 0,
	DBKIND_GUID_PROPID = 1,
	DBKIND_NAME = 2,
	DBKIND_PGUID_NAME = 3,
	DBKIND_PGUID_PROPID = 4,
	DBKIND_PROPID = 5,
	DBKIND_GUID = 6,
}

#endregion


#region Structs
[CRepr]
public struct CI_STATE
{
	public uint32 cbStruct;
	public uint32 cWordList;
	public uint32 cPersistentIndex;
	public uint32 cQueries;
	public uint32 cDocuments;
	public uint32 cFreshTest;
	public uint32 dwMergeProgress;
	public uint32 eState;
	public uint32 cFilteredDocuments;
	public uint32 cTotalDocuments;
	public uint32 cPendingScans;
	public uint32 dwIndexSize;
	public uint32 cUniqueKeys;
	public uint32 cSecQDocuments;
	public uint32 dwPropCacheSize;
}

[CRepr]
public struct FULLPROPSPEC
{
	public Guid guidPropSet;
	public PROPSPEC psProperty;
}

[CRepr]
public struct FILTERREGION
{
	public uint32 idChunk;
	public uint32 cwcStart;
	public uint32 cwcExtent;
}

[CRepr]
public struct STAT_CHUNK
{
	public uint32 idChunk;
	public CHUNK_BREAKTYPE breakType;
	public CHUNKSTATE flags;
	public uint32 locale;
	public FULLPROPSPEC attribute;
	public uint32 idChunkSource;
	public uint32 cwcStartSource;
	public uint32 cwcLenSource;
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DBID
{
	[CRepr, Union]
	public struct _uGuid_e__Union
	{
		public Guid guid;
		public Guid* pguid;
	}
	[CRepr, Union]
	public struct _uName_e__Union
	{
		public PWSTR pwszName;
		public uint32 ulPropid;
	}
	public _uGuid_e__Union uGuid;
	public uint32 eKind;
	public _uName_e__Union uName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(2)]
public struct DBID
{
	[CRepr, Union, Packed(2)]
	public struct _uName_e__Union
	{
		public PWSTR pwszName;
		public uint32 ulPropid;
	}
	[CRepr, Union, Packed(2)]
	public struct _uGuid_e__Union
	{
		public Guid guid;
		public Guid* pguid;
	}
	public _uGuid_e__Union uGuid;
	public uint32 eKind;
	public _uName_e__Union uName;
}
#endif

#endregion

#region COM Types
[CRepr]struct IFilter : IUnknown
{
	public new const Guid IID = .(0x89bcb740, 0x6119, 0x101a, 0xbc, 0xb7, 0x00, 0xdd, 0x01, 0x06, 0x55, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, uint32 grfFlags, uint32 cAttributes, FULLPROPSPEC* aAttributes, uint32* pFlags) Init;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, STAT_CHUNK* pStat) GetChunk;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, uint32* pcwcBuffer, char16* awcBuffer) GetText;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, PROPVARIANT** ppPropValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self, FILTERREGION origPos, in Guid riid, void** ppunk) BindRegion;
	}


	public int32 Init(uint32 grfFlags, uint32 cAttributes, FULLPROPSPEC* aAttributes, uint32* pFlags) mut => VT.[Friend]Init(&this, grfFlags, cAttributes, aAttributes, pFlags);

	public int32 GetChunk(STAT_CHUNK* pStat) mut => VT.[Friend]GetChunk(&this, pStat);

	public int32 GetText(uint32* pcwcBuffer, char16* awcBuffer) mut => VT.[Friend]GetText(&this, pcwcBuffer, awcBuffer);

	public int32 GetValue(PROPVARIANT** ppPropValue) mut => VT.[Friend]GetValue(&this, ppPropValue);

	public int32 BindRegion(FILTERREGION origPos, in Guid riid, void** ppunk) mut => VT.[Friend]BindRegion(&this, origPos, riid, ppunk);
}

[CRepr]struct IPhraseSink : IUnknown
{
	public new const Guid IID = .(0xcc906ff0, 0xc058, 0x101a, 0xb5, 0x54, 0x08, 0x00, 0x2b, 0x33, 0xb0, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcNoun, uint32 cwcNoun, PWSTR pwcModifier, uint32 cwcModifier, uint32 ulAttachmentType) PutSmallPhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcPhrase, uint32 cwcPhrase) PutPhrase;
	}


	public HRESULT PutSmallPhrase(PWSTR pwcNoun, uint32 cwcNoun, PWSTR pwcModifier, uint32 cwcModifier, uint32 ulAttachmentType) mut => VT.[Friend]PutSmallPhrase(&this, pwcNoun, cwcNoun, pwcModifier, cwcModifier, ulAttachmentType);

	public HRESULT PutPhrase(PWSTR pwcPhrase, uint32 cwcPhrase) mut => VT.[Friend]PutPhrase(&this, pwcPhrase, cwcPhrase);
}

#endregion

#region Functions
public static
{
	[Import("query.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadIFilter(PWSTR pwcsPath, IUnknown* pUnkOuter, void** ppIUnk);

	[Import("query.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT LoadIFilterEx(PWSTR pwcsPath, uint32 dwFlags, in Guid riid, void** ppIUnk);

	[Import("query.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BindIFilterFromStorage(IStorage* pStg, IUnknown* pUnkOuter, void** ppIUnk);

	[Import("query.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BindIFilterFromStream(IStream* pStm, IUnknown* pUnkOuter, void** ppIUnk);

}
#endregion
