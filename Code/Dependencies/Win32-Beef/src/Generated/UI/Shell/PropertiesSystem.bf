using Win32.System.Com;
using Win32.Foundation;
using Win32.System.Com.StructuredStorage;
using Win32.System.Search.Common;
using Win32.UI.Shell.Common;
using System;

namespace Win32.UI.Shell.PropertiesSystem;

#region Constants
public static
{
	public const uint32 PKEY_PIDSTR_MAX = 10;
}
#endregion

#region Enums

[AllowDuplicates]
public enum GETPROPERTYSTOREFLAGS : uint32
{
	GPS_DEFAULT = 0,
	GPS_HANDLERPROPERTIESONLY = 1,
	GPS_READWRITE = 2,
	GPS_TEMPORARY = 4,
	GPS_FASTPROPERTIESONLY = 8,
	GPS_OPENSLOWITEM = 16,
	GPS_DELAYCREATION = 32,
	GPS_BESTEFFORT = 64,
	GPS_NO_OPLOCK = 128,
	GPS_PREFERQUERYPROPERTIES = 256,
	GPS_EXTRINSICPROPERTIES = 512,
	GPS_EXTRINSICPROPERTIESONLY = 1024,
	GPS_VOLATILEPROPERTIES = 2048,
	GPS_VOLATILEPROPERTIESONLY = 4096,
	GPS_MASK_VALID = 8191,
}


[AllowDuplicates]
public enum PKA_FLAGS : uint32
{
	PKA_SET = 0,
	PKA_APPEND = 1,
	PKA_DELETE = 2,
}


[AllowDuplicates]
public enum PSC_STATE : int32
{
	PSC_NORMAL = 0,
	PSC_NOTINSOURCE = 1,
	PSC_DIRTY = 2,
	PSC_READONLY = 3,
}


[AllowDuplicates]
public enum PROPENUMTYPE : int32
{
	PET_DISCRETEVALUE = 0,
	PET_RANGEDVALUE = 1,
	PET_DEFAULTVALUE = 2,
	PET_ENDRANGE = 3,
}


[AllowDuplicates]
public enum PROPDESC_TYPE_FLAGS : uint32
{
	PDTF_DEFAULT = 0,
	PDTF_MULTIPLEVALUES = 1,
	PDTF_ISINNATE = 2,
	PDTF_ISGROUP = 4,
	PDTF_CANGROUPBY = 8,
	PDTF_CANSTACKBY = 16,
	PDTF_ISTREEPROPERTY = 32,
	PDTF_INCLUDEINFULLTEXTQUERY = 64,
	PDTF_ISVIEWABLE = 128,
	PDTF_ISQUERYABLE = 256,
	PDTF_CANBEPURGED = 512,
	PDTF_SEARCHRAWVALUE = 1024,
	PDTF_DONTCOERCEEMPTYSTRINGS = 2048,
	PDTF_ALWAYSINSUPPLEMENTALSTORE = 4096,
	PDTF_ISSYSTEMPROPERTY = 2147483648,
	PDTF_MASK_ALL = 2147491839,
}


[AllowDuplicates]
public enum PROPDESC_VIEW_FLAGS : uint32
{
	PDVF_DEFAULT = 0,
	PDVF_CENTERALIGN = 1,
	PDVF_RIGHTALIGN = 2,
	PDVF_BEGINNEWGROUP = 4,
	PDVF_FILLAREA = 8,
	PDVF_SORTDESCENDING = 16,
	PDVF_SHOWONLYIFPRESENT = 32,
	PDVF_SHOWBYDEFAULT = 64,
	PDVF_SHOWINPRIMARYLIST = 128,
	PDVF_SHOWINSECONDARYLIST = 256,
	PDVF_HIDELABEL = 512,
	PDVF_HIDDEN = 2048,
	PDVF_CANWRAP = 4096,
	PDVF_MASK_ALL = 7167,
}


[AllowDuplicates]
public enum PROPDESC_DISPLAYTYPE : int32
{
	PDDT_STRING = 0,
	PDDT_NUMBER = 1,
	PDDT_BOOLEAN = 2,
	PDDT_DATETIME = 3,
	PDDT_ENUMERATED = 4,
}


[AllowDuplicates]
public enum PROPDESC_GROUPING_RANGE : int32
{
	PDGR_DISCRETE = 0,
	PDGR_ALPHANUMERIC = 1,
	PDGR_SIZE = 2,
	PDGR_DYNAMIC = 3,
	PDGR_DATE = 4,
	PDGR_PERCENT = 5,
	PDGR_ENUMERATED = 6,
}


[AllowDuplicates]
public enum PROPDESC_FORMAT_FLAGS : uint32
{
	PDFF_DEFAULT = 0,
	PDFF_PREFIXNAME = 1,
	PDFF_FILENAME = 2,
	PDFF_ALWAYSKB = 4,
	PDFF_RESERVED_RIGHTTOLEFT = 8,
	PDFF_SHORTTIME = 16,
	PDFF_LONGTIME = 32,
	PDFF_HIDETIME = 64,
	PDFF_SHORTDATE = 128,
	PDFF_LONGDATE = 256,
	PDFF_HIDEDATE = 512,
	PDFF_RELATIVEDATE = 1024,
	PDFF_USEEDITINVITATION = 2048,
	PDFF_READONLY = 4096,
	PDFF_NOAUTOREADINGORDER = 8192,
}


[AllowDuplicates]
public enum PROPDESC_SORTDESCRIPTION : int32
{
	PDSD_GENERAL = 0,
	PDSD_A_Z = 1,
	PDSD_LOWEST_HIGHEST = 2,
	PDSD_SMALLEST_BIGGEST = 3,
	PDSD_OLDEST_NEWEST = 4,
}


[AllowDuplicates]
public enum PROPDESC_RELATIVEDESCRIPTION_TYPE : int32
{
	PDRDT_GENERAL = 0,
	PDRDT_DATE = 1,
	PDRDT_SIZE = 2,
	PDRDT_COUNT = 3,
	PDRDT_REVISION = 4,
	PDRDT_LENGTH = 5,
	PDRDT_DURATION = 6,
	PDRDT_SPEED = 7,
	PDRDT_RATE = 8,
	PDRDT_RATING = 9,
	PDRDT_PRIORITY = 10,
}


[AllowDuplicates]
public enum PROPDESC_AGGREGATION_TYPE : int32
{
	PDAT_DEFAULT = 0,
	PDAT_FIRST = 1,
	PDAT_SUM = 2,
	PDAT_AVERAGE = 3,
	PDAT_DATERANGE = 4,
	PDAT_UNION = 5,
	PDAT_MAX = 6,
	PDAT_MIN = 7,
}


[AllowDuplicates]
public enum PROPDESC_CONDITION_TYPE : int32
{
	PDCOT_NONE = 0,
	PDCOT_STRING = 1,
	PDCOT_SIZE = 2,
	PDCOT_DATETIME = 3,
	PDCOT_BOOLEAN = 4,
	PDCOT_NUMBER = 5,
}


[AllowDuplicates]
public enum PROPDESC_SEARCHINFO_FLAGS : uint32
{
	PDSIF_DEFAULT = 0,
	PDSIF_ININVERTEDINDEX = 1,
	PDSIF_ISCOLUMN = 2,
	PDSIF_ISCOLUMNSPARSE = 4,
	PDSIF_ALWAYSINCLUDE = 8,
	PDSIF_USEFORTYPEAHEAD = 16,
}


[AllowDuplicates]
public enum PROPDESC_COLUMNINDEX_TYPE : int32
{
	PDCIT_NONE = 0,
	PDCIT_ONDISK = 1,
	PDCIT_INMEMORY = 2,
	PDCIT_ONDEMAND = 3,
	PDCIT_ONDISKALL = 4,
	PDCIT_ONDISKVECTOR = 5,
}


[AllowDuplicates]
public enum PROPDESC_ENUMFILTER : int32
{
	PDEF_ALL = 0,
	PDEF_SYSTEM = 1,
	PDEF_NONSYSTEM = 2,
	PDEF_VIEWABLE = 3,
	PDEF_QUERYABLE = 4,
	PDEF_INFULLTEXTQUERY = 5,
	PDEF_COLUMN = 6,
}


[AllowDuplicates]
public enum _PERSIST_SPROPSTORE_FLAGS : int32
{
	FPSPS_DEFAULT = 0,
	FPSPS_READONLY = 1,
	FPSPS_TREAT_NEW_VALUES_AS_DIRTY = 2,
}


[AllowDuplicates]
public enum PSTIME_FLAGS : uint32
{
	PSTF_UTC = 0,
	PSTF_LOCAL = 1,
}


[AllowDuplicates]
public enum PROPVAR_COMPARE_UNIT : int32
{
	PVCU_DEFAULT = 0,
	PVCU_SECOND = 1,
	PVCU_MINUTE = 2,
	PVCU_HOUR = 3,
	PVCU_DAY = 4,
	PVCU_MONTH = 5,
	PVCU_YEAR = 6,
}


[AllowDuplicates]
public enum PROPVAR_COMPARE_FLAGS : uint32
{
	PVCF_DEFAULT = 0,
	PVCF_TREATEMPTYASGREATERTHAN = 1,
	PVCF_USESTRCMP = 2,
	PVCF_USESTRCMPC = 4,
	PVCF_USESTRCMPI = 8,
	PVCF_USESTRCMPIC = 16,
	PVCF_DIGITSASNUMBERS_CASESENSITIVE = 32,
}


[AllowDuplicates]
public enum PROPVAR_CHANGE_FLAGS : uint32
{
	PVCHF_DEFAULT = 0,
	PVCHF_NOVALUEPROP = 1,
	PVCHF_ALPHABOOL = 2,
	PVCHF_NOUSEROVERRIDE = 4,
	PVCHF_LOCALBOOL = 8,
	PVCHF_NOHEXSTRING = 16,
}


[AllowDuplicates]
public enum DRAWPROGRESSFLAGS : uint32
{
	DPF_NONE = 0,
	DPF_MARQUEE = 1,
	DPF_MARQUEE_COMPLETE = 2,
	DPF_ERROR = 4,
	DPF_WARNING = 8,
	DPF_STOPPED = 16,
}


[AllowDuplicates]
public enum SYNC_TRANSFER_STATUS : uint32
{
	STS_NONE = 0,
	STS_NEEDSUPLOAD = 1,
	STS_NEEDSDOWNLOAD = 2,
	STS_TRANSFERRING = 4,
	STS_PAUSED = 8,
	STS_HASERROR = 16,
	STS_FETCHING_METADATA = 32,
	STS_USER_REQUESTED_REFRESH = 64,
	STS_HASWARNING = 128,
	STS_EXCLUDED = 256,
	STS_INCOMPLETE = 512,
	STS_PLACEHOLDER_IFEMPTY = 1024,
}


[AllowDuplicates]
public enum PLACEHOLDER_STATES : uint32
{
	PS_NONE = 0,
	PS_MARKED_FOR_OFFLINE_AVAILABILITY = 1,
	PS_FULL_PRIMARY_STREAM_AVAILABLE = 2,
	PS_CREATE_FILE_ACCESSIBLE = 4,
	PS_CLOUDFILE_PLACEHOLDER = 8,
	PS_DEFAULT = 7,
	PS_ALL = 15,
}


[AllowDuplicates]
public enum PROPERTYUI_NAME_FLAGS : uint32
{
	PUIFNF_DEFAULT = 0,
	PUIFNF_MNEMONIC = 1,
}


[AllowDuplicates]
public enum PROPERTYUI_FLAGS : uint32
{
	PUIF_DEFAULT = 0,
	PUIF_RIGHTALIGN = 1,
	PUIF_NOLABELININFOTIP = 2,
}


[AllowDuplicates]
public enum PROPERTYUI_FORMAT_FLAGS : uint32
{
	PUIFFDF_DEFAULT = 0,
	PUIFFDF_RIGHTTOLEFT = 1,
	PUIFFDF_SHORTFORMAT = 2,
	PUIFFDF_NOTIME = 4,
	PUIFFDF_FRIENDLYDATE = 8,
}


[AllowDuplicates]
public enum PDOPSTATUS : int32
{
	PDOPS_RUNNING = 1,
	PDOPS_PAUSED = 2,
	PDOPS_CANCELLED = 3,
	PDOPS_STOPPED = 4,
	PDOPS_ERRORS = 5,
}


[AllowDuplicates]
public enum SYNC_ENGINE_STATE_FLAGS : uint32
{
	SESF_NONE = 0,
	SESF_SERVICE_QUOTA_NEARING_LIMIT = 1,
	SESF_SERVICE_QUOTA_EXCEEDED_LIMIT = 2,
	SESF_AUTHENTICATION_ERROR = 4,
	SESF_PAUSED_DUE_TO_METERED_NETWORK = 8,
	SESF_PAUSED_DUE_TO_DISK_SPACE_FULL = 16,
	SESF_PAUSED_DUE_TO_CLIENT_POLICY = 32,
	SESF_PAUSED_DUE_TO_SERVICE_POLICY = 64,
	SESF_SERVICE_UNAVAILABLE = 128,
	SESF_PAUSED_DUE_TO_USER_REQUEST = 256,
	SESF_ALL_FLAGS = 511,
}

#endregion


#region Structs
[CRepr]
public struct PROPERTYKEY
{
	public Guid fmtid;
	public uint32 pid;
}

[CRepr]
public struct SERIALIZEDPROPSTORAGE
{
}

[CRepr, Packed(1)]
public struct PROPPRG
{
	public uint16 flPrg;
	public uint16 flPrgInit;
	public CHAR[30] achTitle;
	public CHAR[128] achCmdLine;
	public CHAR[64] achWorkDir;
	public uint16 wHotKey;
	public CHAR[80] achIconFile;
	public uint16 wIconIndex;
	public uint32 dwEnhModeFlags;
	public uint32 dwRealModeFlags;
	public CHAR[80] achOtherFile;
	public CHAR[260] achPIFFile;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_InMemoryPropertyStore = .(0x9a02e012, 0x6303, 0x4e1e, 0xb9, 0xa1, 0x63, 0x0f, 0x80, 0x25, 0x92, 0xc5);


	public const Guid CLSID_InMemoryPropertyStoreMarshalByValue = .(0xd4ca0e2d, 0x6da7, 0x4b75, 0xa9, 0x7c, 0x5f, 0x30, 0x6f, 0x0e, 0xae, 0xdc);


	public const Guid CLSID_PropertySystem = .(0xb8967f85, 0x58ae, 0x4f46, 0x9f, 0xb2, 0x5d, 0x79, 0x04, 0x79, 0x8f, 0x4b);


}
#endregion

#region COM Types
[CRepr]struct IInitializeWithFile : IUnknown
{
	public new const Guid IID = .(0xb7d14566, 0x0509, 0x4cce, 0xa7, 0x1f, 0x0a, 0x55, 0x42, 0x33, 0xbd, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFilePath, uint32 grfMode) Initialize;
	}


	public HRESULT Initialize(PWSTR pszFilePath, uint32 grfMode) mut => VT.[Friend]Initialize(&this, pszFilePath, grfMode);
}

[CRepr]struct IInitializeWithStream : IUnknown
{
	public new const Guid IID = .(0xb824b49d, 0x22ac, 0x4161, 0xac, 0x8a, 0x99, 0x16, 0xe8, 0xfa, 0x3f, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstream, uint32 grfMode) Initialize;
	}


	public HRESULT Initialize(IStream* pstream, uint32 grfMode) mut => VT.[Friend]Initialize(&this, pstream, grfMode);
}

[CRepr]struct IPropertyStore : IUnknown
{
	public new const Guid IID = .(0x886d8eeb, 0x8cf2, 0x4446, 0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cProps) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iProp, PROPERTYKEY* pkey) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* pv) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* propvar) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
	}


	public HRESULT GetCount(uint32* cProps) mut => VT.[Friend]GetCount(&this, cProps);

	public HRESULT GetAt(uint32 iProp, PROPERTYKEY* pkey) mut => VT.[Friend]GetAt(&this, iProp, pkey);

	public HRESULT GetValue(PROPERTYKEY* key, PROPVARIANT* pv) mut => VT.[Friend]GetValue(&this, key, pv);

	public HRESULT SetValue(PROPERTYKEY* key, PROPVARIANT* propvar) mut => VT.[Friend]SetValue(&this, key, propvar);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);
}

[CRepr]struct INamedPropertyStore : IUnknown
{
	public new const Guid IID = .(0x71604b0f, 0x97b0, 0x4764, 0x85, 0x77, 0x2f, 0x13, 0xe9, 0x8a, 0x14, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PROPVARIANT* ppropvar) GetNamedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PROPVARIANT* propvar) SetNamedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetNameCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iProp, BSTR* pbstrName) GetNameAt;
	}


	public HRESULT GetNamedValue(PWSTR pszName, PROPVARIANT* ppropvar) mut => VT.[Friend]GetNamedValue(&this, pszName, ppropvar);

	public HRESULT SetNamedValue(PWSTR pszName, PROPVARIANT* propvar) mut => VT.[Friend]SetNamedValue(&this, pszName, propvar);

	public HRESULT GetNameCount(uint32* pdwCount) mut => VT.[Friend]GetNameCount(&this, pdwCount);

	public HRESULT GetNameAt(uint32 iProp, BSTR* pbstrName) mut => VT.[Friend]GetNameAt(&this, iProp, pbstrName);
}

[CRepr]struct IObjectWithPropertyKey : IUnknown
{
	public new const Guid IID = .(0xfc0ca0a7, 0xc316, 0x4fd2, 0x90, 0x31, 0x3e, 0x62, 0x8e, 0x6d, 0x4f, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) SetPropertyKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pkey) GetPropertyKey;
	}


	public HRESULT SetPropertyKey(PROPERTYKEY* key) mut => VT.[Friend]SetPropertyKey(&this, key);

	public HRESULT GetPropertyKey(PROPERTYKEY* pkey) mut => VT.[Friend]GetPropertyKey(&this, pkey);
}

[CRepr]struct IPropertyChange : IObjectWithPropertyKey
{
	public new const Guid IID = .(0xf917bc8a, 0x1bba, 0x4478, 0xa2, 0x45, 0x1b, 0xde, 0x03, 0xeb, 0x94, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IObjectWithPropertyKey.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* propvarIn, PROPVARIANT* ppropvarOut) ApplyToPropVariant;
	}


	public HRESULT ApplyToPropVariant(PROPVARIANT* propvarIn, PROPVARIANT* ppropvarOut) mut => VT.[Friend]ApplyToPropVariant(&this, propvarIn, ppropvarOut);
}

[CRepr]struct IPropertyChangeArray : IUnknown
{
	public new const Guid IID = .(0x380f5cad, 0x1b5e, 0x42f2, 0x80, 0x5d, 0x63, 0x7f, 0xd3, 0x92, 0xd3, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcOperations) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, in Guid riid, void** ppv) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, IPropertyChange* ppropChange) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyChange* ppropChange) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyChange* ppropChange) AppendOrReplace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) IsKeyInArray;
	}


	public HRESULT GetCount(uint32* pcOperations) mut => VT.[Friend]GetCount(&this, pcOperations);

	public HRESULT GetAt(uint32 iIndex, in Guid riid, void** ppv) mut => VT.[Friend]GetAt(&this, iIndex, riid, ppv);

	public HRESULT InsertAt(uint32 iIndex, IPropertyChange* ppropChange) mut => VT.[Friend]InsertAt(&this, iIndex, ppropChange);

	public HRESULT Append(IPropertyChange* ppropChange) mut => VT.[Friend]Append(&this, ppropChange);

	public HRESULT AppendOrReplace(IPropertyChange* ppropChange) mut => VT.[Friend]AppendOrReplace(&this, ppropChange);

	public HRESULT RemoveAt(uint32 iIndex) mut => VT.[Friend]RemoveAt(&this, iIndex);

	public HRESULT IsKeyInArray(PROPERTYKEY* key) mut => VT.[Friend]IsKeyInArray(&this, key);
}

[CRepr]struct IPropertyStoreCapabilities : IUnknown
{
	public new const Guid IID = .(0xc8e2d566, 0x186e, 0x4d49, 0xbf, 0x41, 0x69, 0x09, 0xea, 0xd5, 0x6a, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) IsPropertyWritable;
	}


	public HRESULT IsPropertyWritable(PROPERTYKEY* key) mut => VT.[Friend]IsPropertyWritable(&this, key);
}

[CRepr]struct IPropertyStoreCache : IPropertyStore
{
	public new const Guid IID = .(0x3017056d, 0x9a91, 0x4e90, 0x93, 0x7d, 0x74, 0x6c, 0x72, 0xab, 0xbf, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyStore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PSC_STATE* pstate) GetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* ppropvar, PSC_STATE* pstate) GetValueAndState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PSC_STATE state) SetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* ppropvar, PSC_STATE state) SetValueAndState;
	}


	public HRESULT GetState(PROPERTYKEY* key, PSC_STATE* pstate) mut => VT.[Friend]GetState(&this, key, pstate);

	public HRESULT GetValueAndState(PROPERTYKEY* key, PROPVARIANT* ppropvar, PSC_STATE* pstate) mut => VT.[Friend]GetValueAndState(&this, key, ppropvar, pstate);

	public HRESULT SetState(PROPERTYKEY* key, PSC_STATE state) mut => VT.[Friend]SetState(&this, key, state);

	public HRESULT SetValueAndState(PROPERTYKEY* key, PROPVARIANT* ppropvar, PSC_STATE state) mut => VT.[Friend]SetValueAndState(&this, key, ppropvar, state);
}

[CRepr]struct IPropertyEnumType : IUnknown
{
	public new const Guid IID = .(0x11e1fbf9, 0x2d56, 0x4a6b, 0x8d, 0xb3, 0x7c, 0xd1, 0x93, 0xa4, 0x71, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPENUMTYPE* penumtype) GetEnumType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* ppropvar) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* ppropvarMin) GetRangeMinValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* ppropvarSet) GetRangeSetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszDisplay) GetDisplayText;
	}


	public HRESULT GetEnumType(PROPENUMTYPE* penumtype) mut => VT.[Friend]GetEnumType(&this, penumtype);

	public HRESULT GetValue(PROPVARIANT* ppropvar) mut => VT.[Friend]GetValue(&this, ppropvar);

	public HRESULT GetRangeMinValue(PROPVARIANT* ppropvarMin) mut => VT.[Friend]GetRangeMinValue(&this, ppropvarMin);

	public HRESULT GetRangeSetValue(PROPVARIANT* ppropvarSet) mut => VT.[Friend]GetRangeSetValue(&this, ppropvarSet);

	public HRESULT GetDisplayText(PWSTR* ppszDisplay) mut => VT.[Friend]GetDisplayText(&this, ppszDisplay);
}

[CRepr]struct IPropertyEnumType2 : IPropertyEnumType
{
	public new const Guid IID = .(0x9b6e051c, 0x5ddd, 0x4321, 0x90, 0x70, 0xfe, 0x2a, 0xcb, 0x55, 0xe7, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyEnumType.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszImageRes) GetImageReference;
	}


	public HRESULT GetImageReference(PWSTR* ppszImageRes) mut => VT.[Friend]GetImageReference(&this, ppszImageRes);
}

[CRepr]struct IPropertyEnumTypeList : IUnknown
{
	public new const Guid IID = .(0xa99400f4, 0x3d84, 0x4557, 0x94, 0xba, 0x12, 0x42, 0xfb, 0x2c, 0xc9, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pctypes) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itype, in Guid riid, void** ppv) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, in Guid riid, void** ppv) GetConditionAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* propvarCmp, uint32* pnIndex) FindMatchingIndex;
	}


	public HRESULT GetCount(uint32* pctypes) mut => VT.[Friend]GetCount(&this, pctypes);

	public HRESULT GetAt(uint32 itype, in Guid riid, void** ppv) mut => VT.[Friend]GetAt(&this, itype, riid, ppv);

	public HRESULT GetConditionAt(uint32 nIndex, in Guid riid, void** ppv) mut => VT.[Friend]GetConditionAt(&this, nIndex, riid, ppv);

	public HRESULT FindMatchingIndex(PROPVARIANT* propvarCmp, uint32* pnIndex) mut => VT.[Friend]FindMatchingIndex(&this, propvarCmp, pnIndex);
}

[CRepr]struct IPropertyDescription : IUnknown
{
	public new const Guid IID = .(0x6f79d558, 0x3e96, 0x4549, 0xa1, 0xd1, 0x7d, 0x75, 0xd2, 0x28, 0x88, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pkey) GetPropertyKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetCanonicalName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pvartype) GetPropertyType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszInvite) GetEditInvitation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_TYPE_FLAGS mask, PROPDESC_TYPE_FLAGS* ppdtFlags) GetTypeFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_VIEW_FLAGS* ppdvFlags) GetViewFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcxChars) GetDefaultColumnWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_DISPLAYTYPE* pdisplaytype) GetDisplayType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcsFlags) GetColumnState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_GROUPING_RANGE* pgr) GetGroupingRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_RELATIVEDESCRIPTION_TYPE* prdt) GetRelativeDescriptionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* propvar1, PROPVARIANT* propvar2, PWSTR* ppszDesc1, PWSTR* ppszDesc2) GetRelativeDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_SORTDESCRIPTION* psd) GetSortDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDescending, PWSTR* ppszDescription) GetSortDescriptionLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_AGGREGATION_TYPE* paggtype) GetAggregationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_CONDITION_TYPE* pcontype, CONDITION_OPERATION* popDefault) GetConditionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetEnumTypeList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* ppropvar) CoerceToCanonicalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdfFlags, PWSTR* ppszDisplay) FormatForDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* propvar) IsValueCanonical;
	}


	public HRESULT GetPropertyKey(PROPERTYKEY* pkey) mut => VT.[Friend]GetPropertyKey(&this, pkey);

	public HRESULT GetCanonicalName(PWSTR* ppszName) mut => VT.[Friend]GetCanonicalName(&this, ppszName);

	public HRESULT GetPropertyType(uint16* pvartype) mut => VT.[Friend]GetPropertyType(&this, pvartype);

	public HRESULT GetDisplayName(PWSTR* ppszName) mut => VT.[Friend]GetDisplayName(&this, ppszName);

	public HRESULT GetEditInvitation(PWSTR* ppszInvite) mut => VT.[Friend]GetEditInvitation(&this, ppszInvite);

	public HRESULT GetTypeFlags(PROPDESC_TYPE_FLAGS mask, PROPDESC_TYPE_FLAGS* ppdtFlags) mut => VT.[Friend]GetTypeFlags(&this, mask, ppdtFlags);

	public HRESULT GetViewFlags(PROPDESC_VIEW_FLAGS* ppdvFlags) mut => VT.[Friend]GetViewFlags(&this, ppdvFlags);

	public HRESULT GetDefaultColumnWidth(uint32* pcxChars) mut => VT.[Friend]GetDefaultColumnWidth(&this, pcxChars);

	public HRESULT GetDisplayType(PROPDESC_DISPLAYTYPE* pdisplaytype) mut => VT.[Friend]GetDisplayType(&this, pdisplaytype);

	public HRESULT GetColumnState(uint32* pcsFlags) mut => VT.[Friend]GetColumnState(&this, pcsFlags);

	public HRESULT GetGroupingRange(PROPDESC_GROUPING_RANGE* pgr) mut => VT.[Friend]GetGroupingRange(&this, pgr);

	public HRESULT GetRelativeDescriptionType(PROPDESC_RELATIVEDESCRIPTION_TYPE* prdt) mut => VT.[Friend]GetRelativeDescriptionType(&this, prdt);

	public HRESULT GetRelativeDescription(PROPVARIANT* propvar1, PROPVARIANT* propvar2, PWSTR* ppszDesc1, PWSTR* ppszDesc2) mut => VT.[Friend]GetRelativeDescription(&this, propvar1, propvar2, ppszDesc1, ppszDesc2);

	public HRESULT GetSortDescription(PROPDESC_SORTDESCRIPTION* psd) mut => VT.[Friend]GetSortDescription(&this, psd);

	public HRESULT GetSortDescriptionLabel(BOOL fDescending, PWSTR* ppszDescription) mut => VT.[Friend]GetSortDescriptionLabel(&this, fDescending, ppszDescription);

	public HRESULT GetAggregationType(PROPDESC_AGGREGATION_TYPE* paggtype) mut => VT.[Friend]GetAggregationType(&this, paggtype);

	public HRESULT GetConditionType(PROPDESC_CONDITION_TYPE* pcontype, CONDITION_OPERATION* popDefault) mut => VT.[Friend]GetConditionType(&this, pcontype, popDefault);

	public HRESULT GetEnumTypeList(in Guid riid, void** ppv) mut => VT.[Friend]GetEnumTypeList(&this, riid, ppv);

	public HRESULT CoerceToCanonicalValue(PROPVARIANT* ppropvar) mut => VT.[Friend]CoerceToCanonicalValue(&this, ppropvar);

	public HRESULT FormatForDisplay(PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdfFlags, PWSTR* ppszDisplay) mut => VT.[Friend]FormatForDisplay(&this, propvar, pdfFlags, ppszDisplay);

	public HRESULT IsValueCanonical(PROPVARIANT* propvar) mut => VT.[Friend]IsValueCanonical(&this, propvar);
}

[CRepr]struct IPropertyDescription2 : IPropertyDescription
{
	public new const Guid IID = .(0x57d2eded, 0x5062, 0x400e, 0xb1, 0x07, 0x5d, 0xae, 0x79, 0xfe, 0x57, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyDescription.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* propvar, PWSTR* ppszImageRes) GetImageReferenceForValue;
	}


	public HRESULT GetImageReferenceForValue(PROPVARIANT* propvar, PWSTR* ppszImageRes) mut => VT.[Friend]GetImageReferenceForValue(&this, propvar, ppszImageRes);
}

[CRepr]struct IPropertyDescriptionAliasInfo : IPropertyDescription
{
	public new const Guid IID = .(0xf67104fc, 0x2af9, 0x46fd, 0xb3, 0x2d, 0x24, 0x3c, 0x14, 0x04, 0xf3, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyDescription.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetSortByAlias;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetAdditionalSortByAliases;
	}


	public HRESULT GetSortByAlias(in Guid riid, void** ppv) mut => VT.[Friend]GetSortByAlias(&this, riid, ppv);

	public HRESULT GetAdditionalSortByAliases(in Guid riid, void** ppv) mut => VT.[Friend]GetAdditionalSortByAliases(&this, riid, ppv);
}

[CRepr]struct IPropertyDescriptionSearchInfo : IPropertyDescription
{
	public new const Guid IID = .(0x078f91bd, 0x29a2, 0x440f, 0x92, 0x4e, 0x46, 0xa2, 0x91, 0x52, 0x45, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyDescription.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_SEARCHINFO_FLAGS* ppdsiFlags) GetSearchInfoFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_COLUMNINDEX_TYPE* ppdciType) GetColumnIndexType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszProjection) GetProjectionString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbMaxSize) GetMaxSize;
	}


	public HRESULT GetSearchInfoFlags(PROPDESC_SEARCHINFO_FLAGS* ppdsiFlags) mut => VT.[Friend]GetSearchInfoFlags(&this, ppdsiFlags);

	public HRESULT GetColumnIndexType(PROPDESC_COLUMNINDEX_TYPE* ppdciType) mut => VT.[Friend]GetColumnIndexType(&this, ppdciType);

	public HRESULT GetProjectionString(PWSTR* ppszProjection) mut => VT.[Friend]GetProjectionString(&this, ppszProjection);

	public HRESULT GetMaxSize(uint32* pcbMaxSize) mut => VT.[Friend]GetMaxSize(&this, pcbMaxSize);
}

[CRepr]struct IPropertyDescriptionRelatedPropertyInfo : IPropertyDescription
{
	public new const Guid IID = .(0x507393f4, 0x2a3d, 0x4a60, 0xb5, 0x9e, 0xd9, 0xc7, 0x57, 0x16, 0xc2, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyDescription.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRelationshipName, in Guid riid, void** ppv) GetRelatedProperty;
	}


	public HRESULT GetRelatedProperty(PWSTR pszRelationshipName, in Guid riid, void** ppv) mut => VT.[Friend]GetRelatedProperty(&this, pszRelationshipName, riid, ppv);
}

[CRepr]struct IPropertySystem : IUnknown
{
	public new const Guid IID = .(0xca724e8a, 0xc3e6, 0x442b, 0x88, 0xa4, 0x6f, 0xb0, 0xdb, 0x80, 0x35, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, in Guid riid, void** ppv) GetPropertyDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCanonicalName, in Guid riid, void** ppv) GetPropertyDescriptionByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropList, in Guid riid, void** ppv) GetPropertyDescriptionListFromString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPDESC_ENUMFILTER filterOn, in Guid riid, void** ppv) EnumeratePropertyDescriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdff, char16* pszText, uint32 cchText) FormatForDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdff, PWSTR* ppszDisplay) FormatForDisplayAlloc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) RegisterPropertySchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) UnregisterPropertySchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshPropertySchema;
	}


	public HRESULT GetPropertyDescription(PROPERTYKEY* propkey, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyDescription(&this, propkey, riid, ppv);

	public HRESULT GetPropertyDescriptionByName(PWSTR pszCanonicalName, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyDescriptionByName(&this, pszCanonicalName, riid, ppv);

	public HRESULT GetPropertyDescriptionListFromString(PWSTR pszPropList, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyDescriptionListFromString(&this, pszPropList, riid, ppv);

	public HRESULT EnumeratePropertyDescriptions(PROPDESC_ENUMFILTER filterOn, in Guid riid, void** ppv) mut => VT.[Friend]EnumeratePropertyDescriptions(&this, filterOn, riid, ppv);

	public HRESULT FormatForDisplay(PROPERTYKEY* key, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdff, char16* pszText, uint32 cchText) mut => VT.[Friend]FormatForDisplay(&this, key, propvar, pdff, pszText, cchText);

	public HRESULT FormatForDisplayAlloc(PROPERTYKEY* key, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdff, PWSTR* ppszDisplay) mut => VT.[Friend]FormatForDisplayAlloc(&this, key, propvar, pdff, ppszDisplay);

	public HRESULT RegisterPropertySchema(PWSTR pszPath) mut => VT.[Friend]RegisterPropertySchema(&this, pszPath);

	public HRESULT UnregisterPropertySchema(PWSTR pszPath) mut => VT.[Friend]UnregisterPropertySchema(&this, pszPath);

	public HRESULT RefreshPropertySchema() mut => VT.[Friend]RefreshPropertySchema(&this);
}

[CRepr]struct IPropertyDescriptionList : IUnknown
{
	public new const Guid IID = .(0x1f9fc1d0, 0xc39b, 0x4b26, 0x81, 0x7f, 0x01, 0x19, 0x67, 0xd3, 0x44, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcElem) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iElem, in Guid riid, void** ppv) GetAt;
	}


	public HRESULT GetCount(uint32* pcElem) mut => VT.[Friend]GetCount(&this, pcElem);

	public HRESULT GetAt(uint32 iElem, in Guid riid, void** ppv) mut => VT.[Friend]GetAt(&this, iElem, riid, ppv);
}

[CRepr]struct IPropertyStoreFactory : IUnknown
{
	public new const Guid IID = .(0xbc110b6d, 0x57e8, 0x4148, 0xa9, 0xc6, 0x91, 0x01, 0x5a, 0xb2, 0xf3, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GETPROPERTYSTOREFLAGS flags, IUnknown* pUnkFactory, in Guid riid, void** ppv) GetPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* rgKeys, uint32 cKeys, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) GetPropertyStoreForKeys;
	}


	public HRESULT GetPropertyStore(GETPROPERTYSTOREFLAGS flags, IUnknown* pUnkFactory, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyStore(&this, flags, pUnkFactory, riid, ppv);

	public HRESULT GetPropertyStoreForKeys(PROPERTYKEY* rgKeys, uint32 cKeys, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyStoreForKeys(&this, rgKeys, cKeys, flags, riid, ppv);
}

[CRepr]struct IDelayedPropertyStoreFactory : IPropertyStoreFactory
{
	public new const Guid IID = .(0x40d4577f, 0xe237, 0x4bdb, 0xbd, 0x69, 0x58, 0xf0, 0x89, 0x43, 0x1b, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyStoreFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GETPROPERTYSTOREFLAGS flags, uint32 dwStoreId, in Guid riid, void** ppv) GetDelayedPropertyStore;
	}


	public HRESULT GetDelayedPropertyStore(GETPROPERTYSTOREFLAGS flags, uint32 dwStoreId, in Guid riid, void** ppv) mut => VT.[Friend]GetDelayedPropertyStore(&this, flags, dwStoreId, riid, ppv);
}

[CRepr]struct IPersistSerializedPropStorage : IUnknown
{
	public new const Guid IID = .(0xe318ad57, 0x0aa0, 0x450f, 0xac, 0xa5, 0x6f, 0xab, 0x71, 0x03, 0xd9, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 flags) SetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SERIALIZEDPROPSTORAGE* psps, uint32 cb) SetPropertyStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SERIALIZEDPROPSTORAGE** ppsps, uint32* pcb) GetPropertyStorage;
	}


	public HRESULT SetFlags(int32 flags) mut => VT.[Friend]SetFlags(&this, flags);

	public HRESULT SetPropertyStorage(SERIALIZEDPROPSTORAGE* psps, uint32 cb) mut => VT.[Friend]SetPropertyStorage(&this, psps, cb);

	public HRESULT GetPropertyStorage(SERIALIZEDPROPSTORAGE** ppsps, uint32* pcb) mut => VT.[Friend]GetPropertyStorage(&this, ppsps, pcb);
}

[CRepr]struct IPersistSerializedPropStorage2 : IPersistSerializedPropStorage
{
	public new const Guid IID = .(0x77effa68, 0x4f98, 0x4366, 0xba, 0x72, 0x57, 0x3b, 0x3d, 0x88, 0x05, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistSerializedPropStorage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcb) GetPropertyStorageSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SERIALIZEDPROPSTORAGE* psps, uint32 cb, uint32* pcbWritten) GetPropertyStorageBuffer;
	}


	public HRESULT GetPropertyStorageSize(uint32* pcb) mut => VT.[Friend]GetPropertyStorageSize(&this, pcb);

	public HRESULT GetPropertyStorageBuffer(SERIALIZEDPROPSTORAGE* psps, uint32 cb, uint32* pcbWritten) mut => VT.[Friend]GetPropertyStorageBuffer(&this, psps, cb, pcbWritten);
}

[CRepr]struct IPropertySystemChangeNotify : IUnknown
{
	public new const Guid IID = .(0xfa955fd9, 0x38be, 0x4879, 0xa6, 0xce, 0x82, 0x4c, 0xf5, 0x2d, 0x60, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SchemaRefreshed;
	}


	public HRESULT SchemaRefreshed() mut => VT.[Friend]SchemaRefreshed(&this);
}

[CRepr]struct ICreateObject : IUnknown
{
	public new const Guid IID = .(0x75121952, 0xe0d0, 0x43e5, 0x93, 0x80, 0x1d, 0x80, 0x48, 0x3a, 0xcf, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, IUnknown* pUnkOuter, in Guid riid, void** ppv) CreateObject;
	}


	public HRESULT CreateObject(in Guid clsid, IUnknown* pUnkOuter, in Guid riid, void** ppv) mut => VT.[Friend]CreateObject(&this, clsid, pUnkOuter, riid, ppv);
}

[CRepr]struct IPropertyUI : IUnknown
{
	public new const Guid IID = .(0x757a7d9f, 0x919a, 0x4118, 0x99, 0xd7, 0xdb, 0xb2, 0x08, 0xc8, 0xcc, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, Guid* pfmtid, uint32* ppid, uint32* pchEaten) ParsePropertyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, char16* pwszText, uint32 cchText) GetCannonicalName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, PROPERTYUI_NAME_FLAGS flags, char16* pwszText, uint32 cchText) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, char16* pwszText, uint32 cchText) GetPropertyDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, uint32* pcxChars) GetDefaultWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, PROPERTYUI_FLAGS* pflags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, PROPVARIANT* ppropvar, PROPERTYUI_FORMAT_FLAGS puiff, char16* pwszText, uint32 cchText) FormatForDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid fmtid, uint32 pid, char16* pwszHelpFile, uint32 cch, uint32* puHelpID) GetHelpInfo;
	}


	public HRESULT ParsePropertyName(PWSTR pszName, Guid* pfmtid, uint32* ppid, uint32* pchEaten) mut => VT.[Friend]ParsePropertyName(&this, pszName, pfmtid, ppid, pchEaten);

	public HRESULT GetCannonicalName(in Guid fmtid, uint32 pid, char16* pwszText, uint32 cchText) mut => VT.[Friend]GetCannonicalName(&this, fmtid, pid, pwszText, cchText);

	public HRESULT GetDisplayName(in Guid fmtid, uint32 pid, PROPERTYUI_NAME_FLAGS flags, char16* pwszText, uint32 cchText) mut => VT.[Friend]GetDisplayName(&this, fmtid, pid, flags, pwszText, cchText);

	public HRESULT GetPropertyDescription(in Guid fmtid, uint32 pid, char16* pwszText, uint32 cchText) mut => VT.[Friend]GetPropertyDescription(&this, fmtid, pid, pwszText, cchText);

	public HRESULT GetDefaultWidth(in Guid fmtid, uint32 pid, uint32* pcxChars) mut => VT.[Friend]GetDefaultWidth(&this, fmtid, pid, pcxChars);

	public HRESULT GetFlags(in Guid fmtid, uint32 pid, PROPERTYUI_FLAGS* pflags) mut => VT.[Friend]COM_GetFlags(&this, fmtid, pid, pflags);

	public HRESULT FormatForDisplay(in Guid fmtid, uint32 pid, PROPVARIANT* ppropvar, PROPERTYUI_FORMAT_FLAGS puiff, char16* pwszText, uint32 cchText) mut => VT.[Friend]FormatForDisplay(&this, fmtid, pid, ppropvar, puiff, pwszText, cchText);

	public HRESULT GetHelpInfo(in Guid fmtid, uint32 pid, char16* pwszHelpFile, uint32 cch, uint32* puHelpID) mut => VT.[Friend]GetHelpInfo(&this, fmtid, pid, pwszHelpFile, cch, puHelpID);
}

#endregion

#region Functions
public static
{
	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToWinRTPropertyValue(PROPVARIANT* propvar, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinRTPropertyValueToPropVariant(IUnknown* punkPropertyValue, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSFormatForDisplay(PROPERTYKEY* propkey, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdfFlags, char16* pwszText, uint32 cchText);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSFormatForDisplayAlloc(PROPERTYKEY* key, PROPVARIANT* propvar, PROPDESC_FORMAT_FLAGS pdff, PWSTR* ppszDisplay);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSFormatPropertyValue(IPropertyStore* pps, IPropertyDescription* ppd, PROPDESC_FORMAT_FLAGS pdff, PWSTR* ppszDisplay);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetImageReferenceForValue(PROPERTYKEY* propkey, PROPVARIANT* propvar, PWSTR* ppszImageRes);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSStringFromPropertyKey(PROPERTYKEY* pkey, char16* psz, uint32 cch);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyKeyFromString(PWSTR pszString, PROPERTYKEY* pkey);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreateMemoryPropertyStore(in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreateDelayedMultiplexPropertyStore(GETPROPERTYSTOREFLAGS flags, IDelayedPropertyStoreFactory* pdpsf, uint32* rgStoreIds, uint32 cStores, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreateMultiplexPropertyStore(IUnknown** prgpunkStores, uint32 cStores, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreatePropertyChangeArray(PROPERTYKEY* rgpropkey, PKA_FLAGS* rgflags, PROPVARIANT* rgpropvar, uint32 cChanges, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreateSimplePropertyChange(PKA_FLAGS flags, PROPERTYKEY* key, PROPVARIANT* propvar, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertyDescription(PROPERTYKEY* propkey, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertyDescriptionByName(PWSTR pszCanonicalName, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSLookupPropertyHandlerCLSID(PWSTR pszFilePath, Guid* pclsid);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetItemPropertyHandler(IUnknown* punkItem, BOOL fReadWrite, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetItemPropertyHandlerWithCreateObject(IUnknown* punkItem, BOOL fReadWrite, IUnknown* punkCreateObject, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertyValue(IPropertyStore* pps, IPropertyDescription* ppd, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSSetPropertyValue(IPropertyStore* pps, IPropertyDescription* ppd, PROPVARIANT* propvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSRegisterPropertySchema(PWSTR pszPath);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSUnregisterPropertySchema(PWSTR pszPath);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSRefreshPropertySchema();

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSEnumeratePropertyDescriptions(PROPDESC_ENUMFILTER filterOn, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertyKeyFromName(PWSTR pszName, PROPERTYKEY* ppropkey);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetNameFromPropertyKey(PROPERTYKEY* propkey, PWSTR* ppszCanonicalName);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCoerceToCanonicalValue(PROPERTYKEY* key, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertyDescriptionListFromString(PWSTR pszPropList, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreatePropertyStoreFromPropertySetStorage(IPropertySetStorage* ppss, uint32 grfMode, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreatePropertyStoreFromObject(IUnknown* punk, uint32 grfMode, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSCreateAdapterFromPropertyStore(IPropertyStore* pps, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertySystem(in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetPropertyFromPropertyStorage(SERIALIZEDPROPSTORAGE* psps, uint32 cb, PROPERTYKEY* rpkey, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSGetNamedPropertyFromPropertyStorage(SERIALIZEDPROPSTORAGE* psps, uint32 cb, PWSTR pszName, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadType(IPropertyBag* propBag, PWSTR propName, VARIANT* @var, VARENUM type);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadStr(IPropertyBag* propBag, PWSTR propName, char16* value, int32 characterCount);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadStrAlloc(IPropertyBag* propBag, PWSTR propName, PWSTR* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadBSTR(IPropertyBag* propBag, PWSTR propName, BSTR* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteStr(IPropertyBag* propBag, PWSTR propName, PWSTR value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteBSTR(IPropertyBag* propBag, PWSTR propName, BSTR value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadInt(IPropertyBag* propBag, PWSTR propName, int32* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteInt(IPropertyBag* propBag, PWSTR propName, int32 value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadSHORT(IPropertyBag* propBag, PWSTR propName, int16* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteSHORT(IPropertyBag* propBag, PWSTR propName, int16 value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadLONG(IPropertyBag* propBag, PWSTR propName, int32* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteLONG(IPropertyBag* propBag, PWSTR propName, int32 value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadDWORD(IPropertyBag* propBag, PWSTR propName, uint32* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteDWORD(IPropertyBag* propBag, PWSTR propName, uint32 value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadBOOL(IPropertyBag* propBag, PWSTR propName, BOOL* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteBOOL(IPropertyBag* propBag, PWSTR propName, BOOL value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadPOINTL(IPropertyBag* propBag, PWSTR propName, POINTL* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WritePOINTL(IPropertyBag* propBag, PWSTR propName, POINTL* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadPOINTS(IPropertyBag* propBag, PWSTR propName, POINTS* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WritePOINTS(IPropertyBag* propBag, PWSTR propName, POINTS* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadRECTL(IPropertyBag* propBag, PWSTR propName, RECTL* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteRECTL(IPropertyBag* propBag, PWSTR propName, RECTL* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadStream(IPropertyBag* propBag, PWSTR propName, IStream** value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteStream(IPropertyBag* propBag, PWSTR propName, IStream* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_Delete(IPropertyBag* propBag, PWSTR propName);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadULONGLONG(IPropertyBag* propBag, PWSTR propName, uint64* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteULONGLONG(IPropertyBag* propBag, PWSTR propName, uint64 value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadUnknown(IPropertyBag* propBag, PWSTR propName, in Guid riid, void** ppv);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteUnknown(IPropertyBag* propBag, PWSTR propName, IUnknown* punk);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadGUID(IPropertyBag* propBag, PWSTR propName, Guid* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WriteGUID(IPropertyBag* propBag, PWSTR propName, in Guid value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_ReadPropertyKey(IPropertyBag* propBag, PWSTR propName, PROPERTYKEY* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PSPropertyBag_WritePropertyKey(IPropertyBag* propBag, PWSTR propName, PROPERTYKEY* value);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromResource(HINSTANCE hinst, uint32 id, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromBuffer(void* pv, uint32 cb, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromCLSID(in Guid clsid, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromGUIDAsString(in Guid guid, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromFileTime(FILETIME* pftIn, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromPropVariantVectorElem(PROPVARIANT* propvarIn, uint32 iElem, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantVectorFromPropVariant(PROPVARIANT* propvarSingle, PROPVARIANT* ppropvarVector);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromStrRet(STRRET* pstrret, ITEMIDLIST* pidl, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromBooleanVector(BOOL* prgf, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromInt16Vector(int16* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromUInt16Vector(uint16* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromInt32Vector(int32* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromUInt32Vector(uint32* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromInt64Vector(int64* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromUInt64Vector(uint64* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromDoubleVector(double* prgn, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromFileTimeVector(FILETIME* prgft, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromStringVector(PWSTR* prgsz, uint32 cElems, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitPropVariantFromStringAsVector(PWSTR psz, PROPVARIANT* ppropvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PropVariantToBooleanWithDefault(PROPVARIANT* propvarIn, BOOL fDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 PropVariantToInt16WithDefault(PROPVARIANT* propvarIn, int16 iDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 PropVariantToUInt16WithDefault(PROPVARIANT* propvarIn, uint16 uiDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PropVariantToInt32WithDefault(PROPVARIANT* propvarIn, int32 lDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PropVariantToUInt32WithDefault(PROPVARIANT* propvarIn, uint32 ulDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 PropVariantToInt64WithDefault(PROPVARIANT* propvarIn, int64 llDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 PropVariantToUInt64WithDefault(PROPVARIANT* propvarIn, uint64 ullDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double PropVariantToDoubleWithDefault(PROPVARIANT* propvarIn, double dblDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PropVariantToStringWithDefault(PROPVARIANT* propvarIn, PWSTR pszDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToBoolean(PROPVARIANT* propvarIn, BOOL* pfRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt16(PROPVARIANT* propvarIn, int16* piRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt16(PROPVARIANT* propvarIn, uint16* puiRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt32(PROPVARIANT* propvarIn, int32* plRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt32(PROPVARIANT* propvarIn, uint32* pulRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt64(PROPVARIANT* propvarIn, int64* pllRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt64(PROPVARIANT* propvarIn, uint64* pullRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToDouble(PROPVARIANT* propvarIn, double* pdblRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToBuffer(PROPVARIANT* propvar, void* pv, uint32 cb);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToString(PROPVARIANT* propvar, char16* psz, uint32 cch);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToGUID(PROPVARIANT* propvar, Guid* pguid);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToStringAlloc(PROPVARIANT* propvar, PWSTR* ppszOut);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToBSTR(PROPVARIANT* propvar, BSTR* pbstrOut);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToStrRet(PROPVARIANT* propvar, STRRET* pstrret);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToFileTime(PROPVARIANT* propvar, PSTIME_FLAGS pstfOut, FILETIME* pftOut);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PropVariantGetElementCount(PROPVARIANT* propvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToBooleanVector(PROPVARIANT* propvar, BOOL* prgf, uint32 crgf, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt16Vector(PROPVARIANT* propvar, int16* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt16Vector(PROPVARIANT* propvar, uint16* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt32Vector(PROPVARIANT* propvar, int32* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt32Vector(PROPVARIANT* propvar, uint32* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt64Vector(PROPVARIANT* propvar, int64* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt64Vector(PROPVARIANT* propvar, uint64* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToDoubleVector(PROPVARIANT* propvar, double* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToFileTimeVector(PROPVARIANT* propvar, FILETIME* prgft, uint32 crgft, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToStringVector(PROPVARIANT* propvar, PWSTR* prgsz, uint32 crgsz, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToBooleanVectorAlloc(PROPVARIANT* propvar, BOOL** pprgf, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt16VectorAlloc(PROPVARIANT* propvar, int16** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt16VectorAlloc(PROPVARIANT* propvar, uint16** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt32VectorAlloc(PROPVARIANT* propvar, int32** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt32VectorAlloc(PROPVARIANT* propvar, uint32** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToInt64VectorAlloc(PROPVARIANT* propvar, int64** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToUInt64VectorAlloc(PROPVARIANT* propvar, uint64** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToDoubleVectorAlloc(PROPVARIANT* propvar, double** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToFileTimeVectorAlloc(PROPVARIANT* propvar, FILETIME** pprgft, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToStringVectorAlloc(PROPVARIANT* propvar, PWSTR** pprgsz, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetBooleanElem(PROPVARIANT* propvar, uint32 iElem, BOOL* pfVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetInt16Elem(PROPVARIANT* propvar, uint32 iElem, int16* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetUInt16Elem(PROPVARIANT* propvar, uint32 iElem, uint16* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetInt32Elem(PROPVARIANT* propvar, uint32 iElem, int32* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetUInt32Elem(PROPVARIANT* propvar, uint32 iElem, uint32* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetInt64Elem(PROPVARIANT* propvar, uint32 iElem, int64* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetUInt64Elem(PROPVARIANT* propvar, uint32 iElem, uint64* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetDoubleElem(PROPVARIANT* propvar, uint32 iElem, double* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetFileTimeElem(PROPVARIANT* propvar, uint32 iElem, FILETIME* pftVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantGetStringElem(PROPVARIANT* propvar, uint32 iElem, PWSTR* ppszVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ClearPropVariantArray(PROPVARIANT* rgPropVar, uint32 cVars);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PropVariantCompareEx(PROPVARIANT* propvar1, PROPVARIANT* propvar2, PROPVAR_COMPARE_UNIT unit, PROPVAR_COMPARE_FLAGS flags);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantChangeType(PROPVARIANT* ppropvarDest, PROPVARIANT* propvarSrc, PROPVAR_CHANGE_FLAGS flags, VARENUM vt);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantToVariant(PROPVARIANT* pPropVar, VARIANT* pVar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToPropVariant(VARIANT* pVar, PROPVARIANT* pPropVar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromResource(HINSTANCE hinst, uint32 id, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromBuffer(void* pv, uint32 cb, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromGUIDAsString(in Guid guid, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromFileTime(FILETIME* pft, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromFileTimeArray(FILETIME* prgft, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromStrRet(STRRET* pstrret, ITEMIDLIST* pidl, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromVariantArrayElem(VARIANT* varIn, uint32 iElem, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromBooleanArray(BOOL* prgf, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromInt16Array(int16* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromUInt16Array(uint16* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromInt32Array(int32* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromUInt32Array(uint32* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromInt64Array(int64* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromUInt64Array(uint64* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromDoubleArray(double* prgn, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitVariantFromStringArray(PWSTR* prgsz, uint32 cElems, VARIANT* pvar);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VariantToBooleanWithDefault(VARIANT* varIn, BOOL fDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int16 VariantToInt16WithDefault(VARIANT* varIn, int16 iDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 VariantToUInt16WithDefault(VARIANT* varIn, uint16 uiDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 VariantToInt32WithDefault(VARIANT* varIn, int32 lDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 VariantToUInt32WithDefault(VARIANT* varIn, uint32 ulDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 VariantToInt64WithDefault(VARIANT* varIn, int64 llDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 VariantToUInt64WithDefault(VARIANT* varIn, uint64 ullDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double VariantToDoubleWithDefault(VARIANT* varIn, double dblDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR VariantToStringWithDefault(VARIANT* varIn, PWSTR pszDefault);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToBoolean(VARIANT* varIn, BOOL* pfRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt16(VARIANT* varIn, int16* piRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt16(VARIANT* varIn, uint16* puiRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt32(VARIANT* varIn, int32* plRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt32(VARIANT* varIn, uint32* pulRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt64(VARIANT* varIn, int64* pllRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt64(VARIANT* varIn, uint64* pullRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToDouble(VARIANT* varIn, double* pdblRet);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToBuffer(VARIANT* varIn, void* pv, uint32 cb);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToGUID(VARIANT* varIn, Guid* pguid);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToString(VARIANT* varIn, char16* pszBuf, uint32 cchBuf);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToStringAlloc(VARIANT* varIn, PWSTR* ppszBuf);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToDosDateTime(VARIANT* varIn, uint16* pwDate, uint16* pwTime);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToStrRet(VARIANT* varIn, STRRET* pstrret);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToFileTime(VARIANT* varIn, PSTIME_FLAGS stfOut, FILETIME* pftOut);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 VariantGetElementCount(VARIANT* varIn);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToBooleanArray(VARIANT* @var, BOOL* prgf, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt16Array(VARIANT* @var, int16* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt16Array(VARIANT* @var, uint16* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt32Array(VARIANT* @var, int32* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt32Array(VARIANT* @var, uint32* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt64Array(VARIANT* @var, int64* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt64Array(VARIANT* @var, uint64* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToDoubleArray(VARIANT* @var, double* prgn, uint32 crgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToStringArray(VARIANT* @var, PWSTR* prgsz, uint32 crgsz, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToBooleanArrayAlloc(VARIANT* @var, BOOL** pprgf, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt16ArrayAlloc(VARIANT* @var, int16** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt16ArrayAlloc(VARIANT* @var, uint16** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt32ArrayAlloc(VARIANT* @var, int32** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt32ArrayAlloc(VARIANT* @var, uint32** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToInt64ArrayAlloc(VARIANT* @var, int64** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToUInt64ArrayAlloc(VARIANT* @var, uint64** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToDoubleArrayAlloc(VARIANT* @var, double** pprgn, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantToStringArrayAlloc(VARIANT* @var, PWSTR** pprgsz, uint32* pcElem);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetBooleanElem(VARIANT* @var, uint32 iElem, BOOL* pfVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetInt16Elem(VARIANT* @var, uint32 iElem, int16* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetUInt16Elem(VARIANT* @var, uint32 iElem, uint16* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetInt32Elem(VARIANT* @var, uint32 iElem, int32* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetUInt32Elem(VARIANT* @var, uint32 iElem, uint32* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetInt64Elem(VARIANT* @var, uint32 iElem, int64* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetUInt64Elem(VARIANT* @var, uint32 iElem, uint64* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetDoubleElem(VARIANT* @var, uint32 iElem, double* pnVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VariantGetStringElem(VARIANT* @var, uint32 iElem, PWSTR* ppszVal);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ClearVariantArray(VARIANT* pvars, uint32 cvars);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 VariantCompare(VARIANT* var1, VARIANT* var2);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetPropertyStoreFromIDList(ITEMIDLIST* pidl, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetPropertyStoreFromParsingName(PWSTR pszPath, IBindCtx* pbc, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHAddDefaultPropertiesByExt(PWSTR pszExt, IPropertyStore* pPropStore);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE PifMgr_OpenProperties(PWSTR pszApp, PWSTR pszPIF, uint32 hInf, uint32 flOpt);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PifMgr_GetProperties(HANDLE hProps, PSTR pszGroup, void* lpProps, int32 cbProps, uint32 flOpt);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PifMgr_SetProperties(HANDLE hProps, PSTR pszGroup, void* lpProps, int32 cbProps, uint32 flOpt);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE PifMgr_CloseProperties(HANDLE hProps, uint32 flOpt);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHPropStgCreate(IPropertySetStorage* psstg, in Guid fmtid, Guid* pclsid, uint32 grfFlags, uint32 grfMode, uint32 dwDisposition, IPropertyStorage** ppstg, uint32* puCodePage);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHPropStgReadMultiple(IPropertyStorage* pps, uint32 uCodePage, uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgvar);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHPropStgWriteMultiple(IPropertyStorage* pps, uint32* puCodePage, uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgvar, uint32 propidNameFirst);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetPropertyStoreForWindow(HWND hwnd, in Guid riid, void** ppv);

}
#endregion
