using Win32.UI.Shell.PropertiesSystem;
using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.WindowsSync;

#region Constants
public static
{
	public const uint32 SYNC_VERSION_FLAG_FROM_FEED = 1;
	public const uint32 SYNC_VERSION_FLAG_HAS_BY = 2;
	public const uint32 SYNC_SERIALIZE_REPLICA_KEY_MAP = 1;
	public const uint32 SYNC_FILTER_INFO_FLAG_ITEM_LIST = 1;
	public const uint32 SYNC_FILTER_INFO_FLAG_CHANGE_UNIT_LIST = 2;
	public const uint32 SYNC_FILTER_INFO_FLAG_CUSTOM = 4;
	public const uint32 SYNC_FILTER_INFO_COMBINED = 8;
	public const uint32 SYNC_CHANGE_FLAG_DELETED = 1;
	public const uint32 SYNC_CHANGE_FLAG_DOES_NOT_EXIST = 2;
	public const uint32 SYNC_CHANGE_FLAG_GHOST = 4;
	public const PROPERTYKEY PKEY_PROVIDER_INSTANCEID = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 2);
	public const PROPERTYKEY PKEY_PROVIDER_CLSID = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 3);
	public const PROPERTYKEY PKEY_PROVIDER_CONFIGUI = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 4);
	public const PROPERTYKEY PKEY_PROVIDER_CONTENTTYPE = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 5);
	public const PROPERTYKEY PKEY_PROVIDER_CAPABILITIES = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 6);
	public const PROPERTYKEY PKEY_PROVIDER_SUPPORTED_ARCHITECTURE = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 7);
	public const PROPERTYKEY PKEY_PROVIDER_NAME = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 8);
	public const PROPERTYKEY PKEY_PROVIDER_DESCRIPTION = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 9);
	public const PROPERTYKEY PKEY_PROVIDER_TOOLTIPS = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 10);
	public const PROPERTYKEY PKEY_PROVIDER_ICON = .(.(0x84179e61, 0x60f6, 0x4c1c, 0x88, 0xed, 0xf1, 0xc5, 0x31, 0xb3, 0x2b, 0xda), 11);
	public const PROPERTYKEY PKEY_CONFIGUI_INSTANCEID = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 2);
	public const PROPERTYKEY PKEY_CONFIGUI_CLSID = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 3);
	public const PROPERTYKEY PKEY_CONFIGUI_CONTENTTYPE = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 4);
	public const PROPERTYKEY PKEY_CONFIGUI_CAPABILITIES = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 5);
	public const PROPERTYKEY PKEY_CONFIGUI_SUPPORTED_ARCHITECTURE = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 6);
	public const PROPERTYKEY PKEY_CONFIGUI_IS_GLOBAL = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 7);
	public const PROPERTYKEY PKEY_CONFIGUI_NAME = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 8);
	public const PROPERTYKEY PKEY_CONFIGUI_DESCRIPTION = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 9);
	public const PROPERTYKEY PKEY_CONFIGUI_TOOLTIPS = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 10);
	public const PROPERTYKEY PKEY_CONFIGUI_ICON = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 11);
	public const PROPERTYKEY PKEY_CONFIGUI_MENUITEM_NOUI = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 12);
	public const PROPERTYKEY PKEY_CONFIGUI_MENUITEM = .(.(0x554b24ea, 0xe8e3, 0x45ba, 0x93, 0x52, 0xdf, 0xb5, 0x61, 0xe1, 0x71, 0xe4), 13);
}
#endregion

#region Enums

[AllowDuplicates]
public enum SYNC_PROVIDER_ROLE : int32
{
	SPR_SOURCE = 0,
	SPR_DESTINATION = 1,
}


[AllowDuplicates]
public enum CONFLICT_RESOLUTION_POLICY : int32
{
	CRP_NONE = 0,
	CRP_DESTINATION_PROVIDER_WINS = 1,
	CRP_SOURCE_PROVIDER_WINS = 2,
	CRP_LAST = 3,
}


[AllowDuplicates]
public enum SYNC_PROGRESS_STAGE : int32
{
	SPS_CHANGE_DETECTION = 0,
	SPS_CHANGE_ENUMERATION = 1,
	SPS_CHANGE_APPLICATION = 2,
}


[AllowDuplicates]
public enum SYNC_FULL_ENUMERATION_ACTION : int32
{
	SFEA_FULL_ENUMERATION = 0,
	SFEA_PARTIAL_SYNC = 1,
	SFEA_ABORT = 2,
}


[AllowDuplicates]
public enum SYNC_RESOLVE_ACTION : int32
{
	SRA_DEFER = 0,
	SRA_ACCEPT_DESTINATION_PROVIDER = 1,
	SRA_ACCEPT_SOURCE_PROVIDER = 2,
	SRA_MERGE = 3,
	SRA_TRANSFER_AND_DEFER = 4,
	SRA_LAST = 5,
}


[AllowDuplicates]
public enum SYNC_STATISTICS : int32
{
	SYNC_STATISTICS_RANGE_COUNT = 0,
}


[AllowDuplicates]
public enum SYNC_SERIALIZATION_VERSION : int32
{
	SYNC_SERIALIZATION_VERSION_V1 = 1,
	SYNC_SERIALIZATION_VERSION_V2 = 4,
	SYNC_SERIALIZATION_VERSION_V3 = 5,
}


[AllowDuplicates]
public enum FILTERING_TYPE : int32
{
	FT_CURRENT_ITEMS_ONLY = 0,
	FT_CURRENT_ITEMS_AND_VERSIONS_FOR_MOVED_OUT_ITEMS = 1,
}


[AllowDuplicates]
public enum SYNC_CONSTRAINT_RESOLVE_ACTION : int32
{
	SCRA_DEFER = 0,
	SCRA_ACCEPT_DESTINATION_PROVIDER = 1,
	SCRA_ACCEPT_SOURCE_PROVIDER = 2,
	SCRA_TRANSFER_AND_DEFER = 3,
	SCRA_MERGE = 4,
	SCRA_RENAME_SOURCE = 5,
	SCRA_RENAME_DESTINATION = 6,
}


[AllowDuplicates]
public enum CONSTRAINT_CONFLICT_REASON : int32
{
	CCR_OTHER = 0,
	CCR_COLLISION = 1,
	CCR_NOPARENT = 2,
	CCR_IDENTITY = 3,
}


[AllowDuplicates]
public enum KNOWLEDGE_COOKIE_COMPARISON_RESULT : int32
{
	KCCR_COOKIE_KNOWLEDGE_EQUAL = 0,
	KCCR_COOKIE_KNOWLEDGE_CONTAINED = 1,
	KCCR_COOKIE_KNOWLEDGE_CONTAINS = 2,
	KCCR_COOKIE_KNOWLEDGE_NOT_COMPARABLE = 3,
}


[AllowDuplicates]
public enum FILTER_COMBINATION_TYPE : int32
{
	FCT_INTERSECTION = 0,
}


[AllowDuplicates]
public enum SYNC_REGISTRATION_EVENT : int32
{
	SRE_PROVIDER_ADDED = 0,
	SRE_PROVIDER_REMOVED = 1,
	SRE_PROVIDER_UPDATED = 2,
	SRE_PROVIDER_STATE_CHANGED = 3,
	SRE_CONFIGUI_ADDED = 4,
	SRE_CONFIGUI_REMOVED = 5,
	SRE_CONFIGUI_UPDATED = 6,
}

#endregion


#region Structs
[CRepr]
public struct ID_PARAMETER_PAIR
{
	public BOOL fIsVariable;
	public uint16 cbIdSize;
}

[CRepr]
public struct ID_PARAMETERS
{
	public uint32 dwSize;
	public ID_PARAMETER_PAIR replicaId;
	public ID_PARAMETER_PAIR itemId;
	public ID_PARAMETER_PAIR changeUnitId;
}

[CRepr]
public struct SYNC_SESSION_STATISTICS
{
	public uint32 dwChangesApplied;
	public uint32 dwChangesFailed;
}

[CRepr]
public struct SYNC_VERSION
{
	public uint32 dwLastUpdatingReplicaKey;
	public uint64 ullTickCount;
}

[CRepr]
public struct SYNC_RANGE
{
	public uint8* pbClosedLowerBound;
	public uint8* pbClosedUpperBound;
}

[CRepr]
public struct SYNC_TIME
{
	public uint32 dwDate;
	public uint32 dwTime;
}

[CRepr]
public struct SYNC_FILTER_CHANGE
{
	public BOOL fMoveIn;
	public SYNC_VERSION moveVersion;
}

[CRepr]
public struct SyncProviderConfiguration
{
	public uint32 dwVersion;
	public Guid guidInstanceId;
	public Guid clsidProvider;
	public Guid guidConfigUIInstanceId;
	public Guid guidContentType;
	public uint32 dwCapabilities;
	public uint32 dwSupportedArchitecture;
}

[CRepr]
public struct SyncProviderConfigUIConfiguration
{
	public uint32 dwVersion;
	public Guid guidInstanceId;
	public Guid clsidConfigUI;
	public Guid guidContentType;
	public uint32 dwCapabilities;
	public uint32 dwSupportedArchitecture;
	public BOOL fIsGlobal;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_SyncProviderRegistration = .(0xf82b4ef1, 0x93a9, 0x4dde, 0x80, 0x15, 0xf7, 0x95, 0x0a, 0x1a, 0x6e, 0x31);


}
#endregion

#region COM Types
[CRepr]struct IClockVectorElement : IUnknown
{
	public new const Guid IID = .(0xe71c4250, 0xadf8, 0x4a07, 0x8f, 0xae, 0x56, 0x69, 0x59, 0x69, 0x09, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwReplicaKey) GetReplicaKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullTickCount) GetTickCount;
	}


	public HRESULT GetReplicaKey(uint32* pdwReplicaKey) mut => VT.[Friend]GetReplicaKey(&this, pdwReplicaKey);

	public HRESULT GetTickCount(uint64* pullTickCount) mut => VT.[Friend]GetTickCount(&this, pullTickCount);
}

[CRepr]struct IFeedClockVectorElement : IClockVectorElement
{
	public new const Guid IID = .(0xa40b46d2, 0xe97b, 0x4156, 0xb6, 0xda, 0x99, 0x1f, 0x50, 0x1b, 0x0f, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IClockVectorElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_TIME* pSyncTime) GetSyncTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbFlags) COM_GetFlags;
	}


	public HRESULT GetSyncTime(SYNC_TIME* pSyncTime) mut => VT.[Friend]GetSyncTime(&this, pSyncTime);

	public HRESULT GetFlags(uint8* pbFlags) mut => VT.[Friend]COM_GetFlags(&this, pbFlags);
}

[CRepr]struct IClockVector : IUnknown
{
	public new const Guid IID = .(0x14b2274a, 0x8698, 0x4cc6, 0x93, 0x33, 0xf8, 0x9b, 0xd1, 0xd4, 0x7b, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppiEnumClockVector) GetClockVectorElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetClockVectorElementCount;
	}


	public HRESULT GetClockVectorElements(in Guid riid, void** ppiEnumClockVector) mut => VT.[Friend]GetClockVectorElements(&this, riid, ppiEnumClockVector);

	public HRESULT GetClockVectorElementCount(uint32* pdwCount) mut => VT.[Friend]GetClockVectorElementCount(&this, pdwCount);
}

[CRepr]struct IFeedClockVector : IClockVector
{
	public new const Guid IID = .(0x8d1d98d1, 0x9fb8, 0x4ec9, 0xa5, 0x53, 0x54, 0xdd, 0x92, 0x4e, 0x0f, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IClockVector.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwUpdateCount) GetUpdateCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsNoConflictsSpecified) IsNoConflictsSpecified;
	}


	public HRESULT GetUpdateCount(uint32* pdwUpdateCount) mut => VT.[Friend]GetUpdateCount(&this, pdwUpdateCount);

	public HRESULT IsNoConflictsSpecified(BOOL* pfIsNoConflictsSpecified) mut => VT.[Friend]IsNoConflictsSpecified(&this, pfIsNoConflictsSpecified);
}

[CRepr]struct IEnumClockVector : IUnknown
{
	public new const Guid IID = .(0x525844db, 0x2837, 0x4799, 0x9e, 0x80, 0x81, 0xa6, 0x6e, 0x02, 0x22, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cClockVectorElements, IClockVectorElement** ppiClockVectorElements, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cSyncVersions) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumClockVector** ppiEnum) Clone;
	}


	public HRESULT Next(uint32 cClockVectorElements, IClockVectorElement** ppiClockVectorElements, uint32* pcFetched) mut => VT.[Friend]Next(&this, cClockVectorElements, ppiClockVectorElements, pcFetched);

	public HRESULT Skip(uint32 cSyncVersions) mut => VT.[Friend]Skip(&this, cSyncVersions);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumClockVector** ppiEnum) mut => VT.[Friend]Clone(&this, ppiEnum);
}

[CRepr]struct IEnumFeedClockVector : IUnknown
{
	public new const Guid IID = .(0x550f763d, 0x146a, 0x48f6, 0xab, 0xeb, 0x6c, 0x88, 0xc7, 0xf7, 0x05, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cClockVectorElements, IFeedClockVectorElement** ppiClockVectorElements, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cSyncVersions) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumFeedClockVector** ppiEnum) Clone;
	}


	public HRESULT Next(uint32 cClockVectorElements, IFeedClockVectorElement** ppiClockVectorElements, uint32* pcFetched) mut => VT.[Friend]Next(&this, cClockVectorElements, ppiClockVectorElements, pcFetched);

	public HRESULT Skip(uint32 cSyncVersions) mut => VT.[Friend]Skip(&this, cSyncVersions);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumFeedClockVector** ppiEnum) mut => VT.[Friend]Clone(&this, ppiEnum);
}

[CRepr]struct ICoreFragment : IUnknown
{
	public new const Guid IID = .(0x613b2ab5, 0xb304, 0x47d9, 0x9c, 0x31, 0xce, 0x6c, 0x54, 0x40, 0x1a, 0x15);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pChangeUnitId, uint32* pChangeUnitIdSize) NextColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pItemId, uint32* pItemIdSize, IClockVector** piClockVector) NextRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pColumnCount) GetColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pRangeCount) GetRangeCount;
	}


	public HRESULT NextColumn(uint8* pChangeUnitId, uint32* pChangeUnitIdSize) mut => VT.[Friend]NextColumn(&this, pChangeUnitId, pChangeUnitIdSize);

	public HRESULT NextRange(uint8* pItemId, uint32* pItemIdSize, IClockVector** piClockVector) mut => VT.[Friend]NextRange(&this, pItemId, pItemIdSize, piClockVector);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT GetColumnCount(uint32* pColumnCount) mut => VT.[Friend]GetColumnCount(&this, pColumnCount);

	public HRESULT GetRangeCount(uint32* pRangeCount) mut => VT.[Friend]GetRangeCount(&this, pRangeCount);
}

[CRepr]struct ICoreFragmentInspector : IUnknown
{
	public new const Guid IID = .(0xf7fcc5fd, 0xae26, 0x4679, 0xba, 0x16, 0x96, 0xaa, 0xc5, 0x83, 0xc1, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 requestedCount, ICoreFragment** ppiCoreFragments, uint32* pFetchedCount) NextCoreFragments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT NextCoreFragments(uint32 requestedCount, ICoreFragment** ppiCoreFragments, uint32* pFetchedCount) mut => VT.[Friend]NextCoreFragments(&this, requestedCount, ppiCoreFragments, pFetchedCount);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IRangeException : IUnknown
{
	public new const Guid IID = .(0x75ae8777, 0x6848, 0x49f7, 0x95, 0x6c, 0xa3, 0xa9, 0x2f, 0x50, 0x96, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbClosedRangeStart, uint32* pcbIdSize) GetClosedRangeStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbClosedRangeEnd, uint32* pcbIdSize) GetClosedRangeEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetClockVector;
	}


	public HRESULT GetClosedRangeStart(uint8* pbClosedRangeStart, uint32* pcbIdSize) mut => VT.[Friend]GetClosedRangeStart(&this, pbClosedRangeStart, pcbIdSize);

	public HRESULT GetClosedRangeEnd(uint8* pbClosedRangeEnd, uint32* pcbIdSize) mut => VT.[Friend]GetClosedRangeEnd(&this, pbClosedRangeEnd, pcbIdSize);

	public HRESULT GetClockVector(in Guid riid, void** ppUnk) mut => VT.[Friend]GetClockVector(&this, riid, ppUnk);
}

[CRepr]struct IEnumRangeExceptions : IUnknown
{
	public new const Guid IID = .(0x0944439f, 0xddb1, 0x4176, 0xb7, 0x03, 0x04, 0x6f, 0xf2, 0x2a, 0x23, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExceptions, IRangeException** ppRangeException, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExceptions) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumRangeExceptions** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cExceptions, IRangeException** ppRangeException, uint32* pcFetched) mut => VT.[Friend]Next(&this, cExceptions, ppRangeException, pcFetched);

	public HRESULT Skip(uint32 cExceptions) mut => VT.[Friend]Skip(&this, cExceptions);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumRangeExceptions** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct ISingleItemException : IUnknown
{
	public new const Guid IID = .(0x892fb9b0, 0x7c55, 0x4a18, 0x93, 0x16, 0xfd, 0xf4, 0x49, 0x56, 0x9b, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint32* pcbIdSize) GetItemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetClockVector;
	}


	public HRESULT GetItemId(uint8* pbItemId, uint32* pcbIdSize) mut => VT.[Friend]GetItemId(&this, pbItemId, pcbIdSize);

	public HRESULT GetClockVector(in Guid riid, void** ppUnk) mut => VT.[Friend]GetClockVector(&this, riid, ppUnk);
}

[CRepr]struct IEnumSingleItemExceptions : IUnknown
{
	public new const Guid IID = .(0xe563381c, 0x1b4d, 0x4c66, 0x97, 0x96, 0xc8, 0x6f, 0xac, 0xcd, 0xcd, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExceptions, ISingleItemException** ppSingleItemException, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExceptions) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSingleItemExceptions** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cExceptions, ISingleItemException** ppSingleItemException, uint32* pcFetched) mut => VT.[Friend]Next(&this, cExceptions, ppSingleItemException, pcFetched);

	public HRESULT Skip(uint32 cExceptions) mut => VT.[Friend]Skip(&this, cExceptions);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSingleItemExceptions** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IChangeUnitException : IUnknown
{
	public new const Guid IID = .(0x0cd7ee7c, 0xfec0, 0x4021, 0x99, 0xee, 0xf0, 0xe5, 0x34, 0x8f, 0x2a, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint32* pcbIdSize) GetItemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbChangeUnitId, uint32* pcbIdSize) GetChangeUnitId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetClockVector;
	}


	public HRESULT GetItemId(uint8* pbItemId, uint32* pcbIdSize) mut => VT.[Friend]GetItemId(&this, pbItemId, pcbIdSize);

	public HRESULT GetChangeUnitId(uint8* pbChangeUnitId, uint32* pcbIdSize) mut => VT.[Friend]GetChangeUnitId(&this, pbChangeUnitId, pcbIdSize);

	public HRESULT GetClockVector(in Guid riid, void** ppUnk) mut => VT.[Friend]GetClockVector(&this, riid, ppUnk);
}

[CRepr]struct IEnumChangeUnitExceptions : IUnknown
{
	public new const Guid IID = .(0x3074e802, 0x9319, 0x4420, 0xbe, 0x21, 0x10, 0x22, 0xe2, 0xe2, 0x1d, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExceptions, IChangeUnitException** ppChangeUnitException, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cExceptions) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumChangeUnitExceptions** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cExceptions, IChangeUnitException** ppChangeUnitException, uint32* pcFetched) mut => VT.[Friend]Next(&this, cExceptions, ppChangeUnitException, pcFetched);

	public HRESULT Skip(uint32 cExceptions) mut => VT.[Friend]Skip(&this, cExceptions);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumChangeUnitExceptions** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IReplicaKeyMap : IUnknown
{
	public new const Guid IID = .(0x2209f4fc, 0xfd10, 0x4ff0, 0x84, 0xa8, 0xf0, 0xa1, 0x98, 0x2e, 0x44, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbReplicaId, uint32* pdwReplicaKey) LookupReplicaKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReplicaKey, uint8* pbReplicaId, uint32* pcbIdSize) LookupReplicaId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbReplicaKeyMap, uint32* pcbReplicaKeyMap) Serialize;
	}


	public HRESULT LookupReplicaKey(uint8* pbReplicaId, uint32* pdwReplicaKey) mut => VT.[Friend]LookupReplicaKey(&this, pbReplicaId, pdwReplicaKey);

	public HRESULT LookupReplicaId(uint32 dwReplicaKey, uint8* pbReplicaId, uint32* pcbIdSize) mut => VT.[Friend]LookupReplicaId(&this, dwReplicaKey, pbReplicaId, pcbIdSize);

	public HRESULT Serialize(uint8* pbReplicaKeyMap, uint32* pcbReplicaKeyMap) mut => VT.[Friend]Serialize(&this, pbReplicaKeyMap, pcbReplicaKeyMap);
}

[CRepr]struct IConstructReplicaKeyMap : IUnknown
{
	public new const Guid IID = .(0xded10970, 0xec85, 0x4115, 0xb5, 0x2c, 0x44, 0x05, 0x84, 0x56, 0x42, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbReplicaId, uint32* pdwReplicaKey) FindOrAddReplica;
	}


	public HRESULT FindOrAddReplica(uint8* pbReplicaId, uint32* pdwReplicaKey) mut => VT.[Friend]FindOrAddReplica(&this, pbReplicaId, pdwReplicaKey);
}

[CRepr]struct ISyncKnowledge : IUnknown
{
	public new const Guid IID = .(0x615bbb53, 0xc945, 0x4203, 0xbf, 0x4b, 0x2c, 0xb6, 0x59, 0x19, 0xa0, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbReplicaId, uint32* pcbIdSize) GetOwnerReplicaId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fSerializeReplicaKeyMap, uint8* pbKnowledge, uint32* pcbKnowledge) Serialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullTickCount) SetLocalTickCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbVersionOwnerReplicaId, uint8* pgidItemId, SYNC_VERSION* pSyncVersion) ContainsChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbVersionOwnerReplicaId, uint8* pbItemId, uint8* pbChangeUnitId, SYNC_VERSION* pSyncVersion) ContainsChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetScopeVector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IReplicaKeyMap** ppReplicaKeyMap) GetReplicaKeyMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppClonedKnowledge) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pKnowledgeIn, uint8* pbCurrentOwnerId, SYNC_VERSION* pVersionIn, uint8* pbNewOwnerId, uint32* pcbIdSize, SYNC_VERSION* pVersionOut) ConvertVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pRemoteKnowledge, ISyncKnowledge** ppMappedKnowledge) MapRemoteToLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pKnowledge) Union;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, ISyncKnowledge** ppKnowledgeOut) ProjectOntoItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint8* pbChangeUnitId, ISyncKnowledge** ppKnowledgeOut) ProjectOntoChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_RANGE* psrngSyncRange, ISyncKnowledge** ppKnowledgeOut) ProjectOntoRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId) ExcludeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint8* pbChangeUnitId) ExcludeChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pKnowledge) ContainsKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbReplicaId, uint64* pullReplicaTickCount) FindMinTickCountForReplica;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetRangeExceptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetSingleItemExceptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppUnk) GetChangeUnitExceptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, in Guid riid, void** ppUnk) FindClockVectorForItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint8* pbChangeUnitId, in Guid riid, void** ppUnk) FindClockVectorForChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwVersion) GetVersion;
	}


	public HRESULT GetOwnerReplicaId(uint8* pbReplicaId, uint32* pcbIdSize) mut => VT.[Friend]GetOwnerReplicaId(&this, pbReplicaId, pcbIdSize);

	public HRESULT Serialize(BOOL fSerializeReplicaKeyMap, uint8* pbKnowledge, uint32* pcbKnowledge) mut => VT.[Friend]Serialize(&this, fSerializeReplicaKeyMap, pbKnowledge, pcbKnowledge);

	public HRESULT SetLocalTickCount(uint64 ullTickCount) mut => VT.[Friend]SetLocalTickCount(&this, ullTickCount);

	public HRESULT ContainsChange(uint8* pbVersionOwnerReplicaId, uint8* pgidItemId, SYNC_VERSION* pSyncVersion) mut => VT.[Friend]ContainsChange(&this, pbVersionOwnerReplicaId, pgidItemId, pSyncVersion);

	public HRESULT ContainsChangeUnit(uint8* pbVersionOwnerReplicaId, uint8* pbItemId, uint8* pbChangeUnitId, SYNC_VERSION* pSyncVersion) mut => VT.[Friend]ContainsChangeUnit(&this, pbVersionOwnerReplicaId, pbItemId, pbChangeUnitId, pSyncVersion);

	public HRESULT GetScopeVector(in Guid riid, void** ppUnk) mut => VT.[Friend]GetScopeVector(&this, riid, ppUnk);

	public HRESULT GetReplicaKeyMap(IReplicaKeyMap** ppReplicaKeyMap) mut => VT.[Friend]GetReplicaKeyMap(&this, ppReplicaKeyMap);

	public HRESULT Clone(ISyncKnowledge** ppClonedKnowledge) mut => VT.[Friend]Clone(&this, ppClonedKnowledge);

	public HRESULT ConvertVersion(ISyncKnowledge* pKnowledgeIn, uint8* pbCurrentOwnerId, SYNC_VERSION* pVersionIn, uint8* pbNewOwnerId, uint32* pcbIdSize, SYNC_VERSION* pVersionOut) mut => VT.[Friend]ConvertVersion(&this, pKnowledgeIn, pbCurrentOwnerId, pVersionIn, pbNewOwnerId, pcbIdSize, pVersionOut);

	public HRESULT MapRemoteToLocal(ISyncKnowledge* pRemoteKnowledge, ISyncKnowledge** ppMappedKnowledge) mut => VT.[Friend]MapRemoteToLocal(&this, pRemoteKnowledge, ppMappedKnowledge);

	public HRESULT Union(ISyncKnowledge* pKnowledge) mut => VT.[Friend]Union(&this, pKnowledge);

	public HRESULT ProjectOntoItem(uint8* pbItemId, ISyncKnowledge** ppKnowledgeOut) mut => VT.[Friend]ProjectOntoItem(&this, pbItemId, ppKnowledgeOut);

	public HRESULT ProjectOntoChangeUnit(uint8* pbItemId, uint8* pbChangeUnitId, ISyncKnowledge** ppKnowledgeOut) mut => VT.[Friend]ProjectOntoChangeUnit(&this, pbItemId, pbChangeUnitId, ppKnowledgeOut);

	public HRESULT ProjectOntoRange(SYNC_RANGE* psrngSyncRange, ISyncKnowledge** ppKnowledgeOut) mut => VT.[Friend]ProjectOntoRange(&this, psrngSyncRange, ppKnowledgeOut);

	public HRESULT ExcludeItem(uint8* pbItemId) mut => VT.[Friend]ExcludeItem(&this, pbItemId);

	public HRESULT ExcludeChangeUnit(uint8* pbItemId, uint8* pbChangeUnitId) mut => VT.[Friend]ExcludeChangeUnit(&this, pbItemId, pbChangeUnitId);

	public HRESULT ContainsKnowledge(ISyncKnowledge* pKnowledge) mut => VT.[Friend]ContainsKnowledge(&this, pKnowledge);

	public HRESULT FindMinTickCountForReplica(uint8* pbReplicaId, uint64* pullReplicaTickCount) mut => VT.[Friend]FindMinTickCountForReplica(&this, pbReplicaId, pullReplicaTickCount);

	public HRESULT GetRangeExceptions(in Guid riid, void** ppUnk) mut => VT.[Friend]GetRangeExceptions(&this, riid, ppUnk);

	public HRESULT GetSingleItemExceptions(in Guid riid, void** ppUnk) mut => VT.[Friend]GetSingleItemExceptions(&this, riid, ppUnk);

	public HRESULT GetChangeUnitExceptions(in Guid riid, void** ppUnk) mut => VT.[Friend]GetChangeUnitExceptions(&this, riid, ppUnk);

	public HRESULT FindClockVectorForItem(uint8* pbItemId, in Guid riid, void** ppUnk) mut => VT.[Friend]FindClockVectorForItem(&this, pbItemId, riid, ppUnk);

	public HRESULT FindClockVectorForChangeUnit(uint8* pbItemId, uint8* pbChangeUnitId, in Guid riid, void** ppUnk) mut => VT.[Friend]FindClockVectorForChangeUnit(&this, pbItemId, pbChangeUnitId, riid, ppUnk);

	public HRESULT GetVersion(uint32* pdwVersion) mut => VT.[Friend]GetVersion(&this, pdwVersion);
}

[CRepr]struct IForgottenKnowledge : ISyncKnowledge
{
	public new const Guid IID = .(0x456e0f96, 0x6036, 0x452b, 0x9f, 0x9d, 0xbc, 0xc4, 0xb4, 0xa8, 0x5d, 0xb2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncKnowledge.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pKnowledge, SYNC_VERSION* pVersion) ForgetToVersion;
	}


	public HRESULT ForgetToVersion(ISyncKnowledge* pKnowledge, SYNC_VERSION* pVersion) mut => VT.[Friend]ForgetToVersion(&this, pKnowledge, pVersion);
}

[CRepr]struct ISyncKnowledge2 : ISyncKnowledge
{
	public new const Guid IID = .(0xed0addc0, 0x3b4b, 0x46a1, 0x9a, 0x45, 0x45, 0x66, 0x1d, 0x21, 0x14, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncKnowledge.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID_PARAMETERS* pIdParameters) GetIdParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppColumns, uint32 count, ISyncKnowledge2** ppiKnowledgeOut) ProjectOntoColumnSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_SERIALIZATION_VERSION targetFormatVersion, uint32 dwFlags, uint8* pbBuffer, uint32* pdwSerializedSize) SerializeWithOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge2* piSyncKnowledge, uint8* pbItemId, uint32* pcbItemIdSize) GetLowestUncontainedId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppiInspector) GetInspector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_SERIALIZATION_VERSION* pVersion) GetMinimumSupportedVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_STATISTICS which, uint32* pValue) GetStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pKnowledge, uint8* pbItemId) ContainsKnowledgeForItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pKnowledge, uint8* pbItemId, uint8* pbChangeUnitId) ContainsKnowledgeForChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pPrerequisiteKnowledge, ISyncKnowledge* pTemplateKnowledge, ISyncKnowledge** ppProjectedKnowledge) ProjectOntoKnowledgeWithPrerequisite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pSyncKnowledge, ISyncKnowledge** ppComplementedKnowledge) Complement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pSyncKnowledge) IntersectsWithKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppKnowledgeCookie) GetKnowledgeCookie;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pKnowledgeCookie, KNOWLEDGE_COOKIE_COMPARISON_RESULT* pResult) CompareToKnowledgeCookie;
	}


	public HRESULT GetIdParameters(ID_PARAMETERS* pIdParameters) mut => VT.[Friend]GetIdParameters(&this, pIdParameters);

	public HRESULT ProjectOntoColumnSet(uint8** ppColumns, uint32 count, ISyncKnowledge2** ppiKnowledgeOut) mut => VT.[Friend]ProjectOntoColumnSet(&this, ppColumns, count, ppiKnowledgeOut);

	public HRESULT SerializeWithOptions(SYNC_SERIALIZATION_VERSION targetFormatVersion, uint32 dwFlags, uint8* pbBuffer, uint32* pdwSerializedSize) mut => VT.[Friend]SerializeWithOptions(&this, targetFormatVersion, dwFlags, pbBuffer, pdwSerializedSize);

	public HRESULT GetLowestUncontainedId(ISyncKnowledge2* piSyncKnowledge, uint8* pbItemId, uint32* pcbItemIdSize) mut => VT.[Friend]GetLowestUncontainedId(&this, piSyncKnowledge, pbItemId, pcbItemIdSize);

	public HRESULT GetInspector(in Guid riid, void** ppiInspector) mut => VT.[Friend]GetInspector(&this, riid, ppiInspector);

	public HRESULT GetMinimumSupportedVersion(SYNC_SERIALIZATION_VERSION* pVersion) mut => VT.[Friend]GetMinimumSupportedVersion(&this, pVersion);

	public HRESULT GetStatistics(SYNC_STATISTICS which, uint32* pValue) mut => VT.[Friend]GetStatistics(&this, which, pValue);

	public HRESULT ContainsKnowledgeForItem(ISyncKnowledge* pKnowledge, uint8* pbItemId) mut => VT.[Friend]ContainsKnowledgeForItem(&this, pKnowledge, pbItemId);

	public HRESULT ContainsKnowledgeForChangeUnit(ISyncKnowledge* pKnowledge, uint8* pbItemId, uint8* pbChangeUnitId) mut => VT.[Friend]ContainsKnowledgeForChangeUnit(&this, pKnowledge, pbItemId, pbChangeUnitId);

	public HRESULT ProjectOntoKnowledgeWithPrerequisite(ISyncKnowledge* pPrerequisiteKnowledge, ISyncKnowledge* pTemplateKnowledge, ISyncKnowledge** ppProjectedKnowledge) mut => VT.[Friend]ProjectOntoKnowledgeWithPrerequisite(&this, pPrerequisiteKnowledge, pTemplateKnowledge, ppProjectedKnowledge);

	public HRESULT Complement(ISyncKnowledge* pSyncKnowledge, ISyncKnowledge** ppComplementedKnowledge) mut => VT.[Friend]Complement(&this, pSyncKnowledge, ppComplementedKnowledge);

	public HRESULT IntersectsWithKnowledge(ISyncKnowledge* pSyncKnowledge) mut => VT.[Friend]IntersectsWithKnowledge(&this, pSyncKnowledge);

	public HRESULT GetKnowledgeCookie(IUnknown** ppKnowledgeCookie) mut => VT.[Friend]GetKnowledgeCookie(&this, ppKnowledgeCookie);

	public HRESULT CompareToKnowledgeCookie(IUnknown* pKnowledgeCookie, KNOWLEDGE_COOKIE_COMPARISON_RESULT* pResult) mut => VT.[Friend]CompareToKnowledgeCookie(&this, pKnowledgeCookie, pResult);
}

[CRepr]struct IRecoverableErrorData : IUnknown
{
	public new const Guid IID = .(0xb37c4a0a, 0x4b7d, 0x4c2d, 0x97, 0x11, 0x3b, 0x00, 0xd1, 0x19, 0xb1, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcszItemDisplayName, PWSTR pcszErrorDescription) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemDisplayName, uint32* pcchItemDisplayName) GetItemDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszErrorDescription, uint32* pcchErrorDescription) GetErrorDescription;
	}


	public HRESULT Initialize(PWSTR pcszItemDisplayName, PWSTR pcszErrorDescription) mut => VT.[Friend]Initialize(&this, pcszItemDisplayName, pcszErrorDescription);

	public HRESULT GetItemDisplayName(PWSTR pszItemDisplayName, uint32* pcchItemDisplayName) mut => VT.[Friend]GetItemDisplayName(&this, pszItemDisplayName, pcchItemDisplayName);

	public HRESULT GetErrorDescription(PWSTR pszErrorDescription, uint32* pcchErrorDescription) mut => VT.[Friend]GetErrorDescription(&this, pszErrorDescription, pcchErrorDescription);
}

[CRepr]struct IRecoverableError : IUnknown
{
	public new const Guid IID = .(0x0f5625e8, 0x0a7b, 0x45ee, 0x96, 0x37, 0x1c, 0xe1, 0x36, 0x45, 0x90, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_PROGRESS_STAGE* pStage) GetStage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_PROVIDER_ROLE* pProviderRole) GetProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppChangeWithRecoverableError) GetChangeWithRecoverableError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phrError, IRecoverableErrorData** ppErrorData) GetRecoverableErrorDataForChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChangeUnit* pChangeUnit, HRESULT* phrError, IRecoverableErrorData** ppErrorData) GetRecoverableErrorDataForChangeUnit;
	}


	public HRESULT GetStage(SYNC_PROGRESS_STAGE* pStage) mut => VT.[Friend]GetStage(&this, pStage);

	public HRESULT GetProvider(SYNC_PROVIDER_ROLE* pProviderRole) mut => VT.[Friend]GetProvider(&this, pProviderRole);

	public HRESULT GetChangeWithRecoverableError(ISyncChange** ppChangeWithRecoverableError) mut => VT.[Friend]GetChangeWithRecoverableError(&this, ppChangeWithRecoverableError);

	public HRESULT GetRecoverableErrorDataForChange(HRESULT* phrError, IRecoverableErrorData** ppErrorData) mut => VT.[Friend]GetRecoverableErrorDataForChange(&this, phrError, ppErrorData);

	public HRESULT GetRecoverableErrorDataForChangeUnit(ISyncChangeUnit* pChangeUnit, HRESULT* phrError, IRecoverableErrorData** ppErrorData) mut => VT.[Friend]GetRecoverableErrorDataForChangeUnit(&this, pChangeUnit, phrError, ppErrorData);
}

[CRepr]struct IChangeConflict : IUnknown
{
	public new const Guid IID = .(0x014ebf97, 0x9f20, 0x4f7a, 0xbd, 0xd4, 0x25, 0x97, 0x9c, 0x77, 0xc0, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppConflictingChange) GetDestinationProviderConflictingChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppConflictingChange) GetSourceProviderConflictingChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppConflictingData) GetDestinationProviderConflictingData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppConflictingData) GetSourceProviderConflictingData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_RESOLVE_ACTION* pResolveAction) GetResolveActionForChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_RESOLVE_ACTION resolveAction) SetResolveActionForChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChangeUnit* pChangeUnit, SYNC_RESOLVE_ACTION* pResolveAction) GetResolveActionForChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChangeUnit* pChangeUnit, SYNC_RESOLVE_ACTION resolveAction) SetResolveActionForChangeUnit;
	}


	public HRESULT GetDestinationProviderConflictingChange(ISyncChange** ppConflictingChange) mut => VT.[Friend]GetDestinationProviderConflictingChange(&this, ppConflictingChange);

	public HRESULT GetSourceProviderConflictingChange(ISyncChange** ppConflictingChange) mut => VT.[Friend]GetSourceProviderConflictingChange(&this, ppConflictingChange);

	public HRESULT GetDestinationProviderConflictingData(IUnknown** ppConflictingData) mut => VT.[Friend]GetDestinationProviderConflictingData(&this, ppConflictingData);

	public HRESULT GetSourceProviderConflictingData(IUnknown** ppConflictingData) mut => VT.[Friend]GetSourceProviderConflictingData(&this, ppConflictingData);

	public HRESULT GetResolveActionForChange(SYNC_RESOLVE_ACTION* pResolveAction) mut => VT.[Friend]GetResolveActionForChange(&this, pResolveAction);

	public HRESULT SetResolveActionForChange(SYNC_RESOLVE_ACTION resolveAction) mut => VT.[Friend]SetResolveActionForChange(&this, resolveAction);

	public HRESULT GetResolveActionForChangeUnit(ISyncChangeUnit* pChangeUnit, SYNC_RESOLVE_ACTION* pResolveAction) mut => VT.[Friend]GetResolveActionForChangeUnit(&this, pChangeUnit, pResolveAction);

	public HRESULT SetResolveActionForChangeUnit(ISyncChangeUnit* pChangeUnit, SYNC_RESOLVE_ACTION resolveAction) mut => VT.[Friend]SetResolveActionForChangeUnit(&this, pChangeUnit, resolveAction);
}

[CRepr]struct IConstraintConflict : IUnknown
{
	public new const Guid IID = .(0x00d2302e, 0x1cf8, 0x4835, 0xb8, 0x5f, 0xb7, 0xca, 0x4f, 0x79, 0x9e, 0x0a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppConflictingChange) GetDestinationProviderConflictingChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppConflictingChange) GetSourceProviderConflictingChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppOriginalChange) GetDestinationProviderOriginalChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppConflictingData) GetDestinationProviderConflictingData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppConflictingData) GetSourceProviderConflictingData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppOriginalData) GetDestinationProviderOriginalData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_CONSTRAINT_RESOLVE_ACTION* pConstraintResolveAction) GetConstraintResolveActionForChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_CONSTRAINT_RESOLVE_ACTION constraintResolveAction) SetConstraintResolveActionForChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChangeUnit* pChangeUnit, SYNC_CONSTRAINT_RESOLVE_ACTION* pConstraintResolveAction) GetConstraintResolveActionForChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChangeUnit* pChangeUnit, SYNC_CONSTRAINT_RESOLVE_ACTION constraintResolveAction) SetConstraintResolveActionForChangeUnit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONSTRAINT_CONFLICT_REASON* pConstraintConflictReason) GetConstraintConflictReason;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsTemporary;
	}


	public HRESULT GetDestinationProviderConflictingChange(ISyncChange** ppConflictingChange) mut => VT.[Friend]GetDestinationProviderConflictingChange(&this, ppConflictingChange);

	public HRESULT GetSourceProviderConflictingChange(ISyncChange** ppConflictingChange) mut => VT.[Friend]GetSourceProviderConflictingChange(&this, ppConflictingChange);

	public HRESULT GetDestinationProviderOriginalChange(ISyncChange** ppOriginalChange) mut => VT.[Friend]GetDestinationProviderOriginalChange(&this, ppOriginalChange);

	public HRESULT GetDestinationProviderConflictingData(IUnknown** ppConflictingData) mut => VT.[Friend]GetDestinationProviderConflictingData(&this, ppConflictingData);

	public HRESULT GetSourceProviderConflictingData(IUnknown** ppConflictingData) mut => VT.[Friend]GetSourceProviderConflictingData(&this, ppConflictingData);

	public HRESULT GetDestinationProviderOriginalData(IUnknown** ppOriginalData) mut => VT.[Friend]GetDestinationProviderOriginalData(&this, ppOriginalData);

	public HRESULT GetConstraintResolveActionForChange(SYNC_CONSTRAINT_RESOLVE_ACTION* pConstraintResolveAction) mut => VT.[Friend]GetConstraintResolveActionForChange(&this, pConstraintResolveAction);

	public HRESULT SetConstraintResolveActionForChange(SYNC_CONSTRAINT_RESOLVE_ACTION constraintResolveAction) mut => VT.[Friend]SetConstraintResolveActionForChange(&this, constraintResolveAction);

	public HRESULT GetConstraintResolveActionForChangeUnit(ISyncChangeUnit* pChangeUnit, SYNC_CONSTRAINT_RESOLVE_ACTION* pConstraintResolveAction) mut => VT.[Friend]GetConstraintResolveActionForChangeUnit(&this, pChangeUnit, pConstraintResolveAction);

	public HRESULT SetConstraintResolveActionForChangeUnit(ISyncChangeUnit* pChangeUnit, SYNC_CONSTRAINT_RESOLVE_ACTION constraintResolveAction) mut => VT.[Friend]SetConstraintResolveActionForChangeUnit(&this, pChangeUnit, constraintResolveAction);

	public HRESULT GetConstraintConflictReason(CONSTRAINT_CONFLICT_REASON* pConstraintConflictReason) mut => VT.[Friend]GetConstraintConflictReason(&this, pConstraintConflictReason);

	public HRESULT IsTemporary() mut => VT.[Friend]IsTemporary(&this);
}

[CRepr]struct ISyncCallback : IUnknown
{
	public new const Guid IID = .(0x0599797f, 0x5ed9, 0x485c, 0xae, 0x36, 0x0c, 0x5d, 0x1b, 0xf2, 0xe7, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_PROVIDER_ROLE provider, SYNC_PROGRESS_STAGE syncStage, uint32 dwCompletedWork, uint32 dwTotalWork) OnProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange* pSyncChange) OnChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IChangeConflict* pConflict) OnConflict;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_FULL_ENUMERATION_ACTION* pFullEnumerationAction) OnFullEnumerationNeeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRecoverableError* pRecoverableError) OnRecoverableError;
	}


	public HRESULT OnProgress(SYNC_PROVIDER_ROLE provider, SYNC_PROGRESS_STAGE syncStage, uint32 dwCompletedWork, uint32 dwTotalWork) mut => VT.[Friend]OnProgress(&this, provider, syncStage, dwCompletedWork, dwTotalWork);

	public HRESULT OnChange(ISyncChange* pSyncChange) mut => VT.[Friend]OnChange(&this, pSyncChange);

	public HRESULT OnConflict(IChangeConflict* pConflict) mut => VT.[Friend]OnConflict(&this, pConflict);

	public HRESULT OnFullEnumerationNeeded(SYNC_FULL_ENUMERATION_ACTION* pFullEnumerationAction) mut => VT.[Friend]OnFullEnumerationNeeded(&this, pFullEnumerationAction);

	public HRESULT OnRecoverableError(IRecoverableError* pRecoverableError) mut => VT.[Friend]OnRecoverableError(&this, pRecoverableError);
}

[CRepr]struct ISyncCallback2 : ISyncCallback
{
	public new const Guid IID = .(0x47ce84af, 0x7442, 0x4ead, 0x86, 0x30, 0x12, 0x01, 0x5e, 0x03, 0x0a, 0xd7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangesApplied, uint32 dwChangesFailed) OnChangeApplied;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangesApplied, uint32 dwChangesFailed) OnChangeFailed;
	}


	public HRESULT OnChangeApplied(uint32 dwChangesApplied, uint32 dwChangesFailed) mut => VT.[Friend]OnChangeApplied(&this, dwChangesApplied, dwChangesFailed);

	public HRESULT OnChangeFailed(uint32 dwChangesApplied, uint32 dwChangesFailed) mut => VT.[Friend]OnChangeFailed(&this, dwChangesApplied, dwChangesFailed);
}

[CRepr]struct ISyncConstraintCallback : IUnknown
{
	public new const Guid IID = .(0x8af3843e, 0x75b3, 0x438c, 0xbb, 0x51, 0x6f, 0x02, 0x0d, 0x70, 0xd3, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConstraintConflict* pConflict) OnConstraintConflict;
	}


	public HRESULT OnConstraintConflict(IConstraintConflict* pConflict) mut => VT.[Friend]OnConstraintConflict(&this, pConflict);
}

[CRepr]struct ISyncProvider : IUnknown
{
	public new const Guid IID = .(0x8f657056, 0x2bce, 0x4a17, 0x8c, 0x68, 0xc7, 0xbb, 0x78, 0x98, 0xb5, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID_PARAMETERS* pIdParameters) GetIdParameters;
	}


	public HRESULT GetIdParameters(ID_PARAMETERS* pIdParameters) mut => VT.[Friend]GetIdParameters(&this, pIdParameters);
}

[CRepr]struct ISyncSessionState : IUnknown
{
	public new const Guid IID = .(0xb8a940fe, 0x9f01, 0x483b, 0x94, 0x34, 0xc3, 0x7d, 0x36, 0x12, 0x25, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsCanceled) IsCanceled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbChangeApplierInfo, uint32* pcbChangeApplierInfo) GetInfoForChangeApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbChangeApplierInfo, uint32 cbChangeApplierInfo) LoadInfoFromChangeApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbRangeStart, uint32* pcbRangeStart) GetForgottenKnowledgeRecoveryRangeStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbRangeEnd, uint32* pcbRangeEnd) GetForgottenKnowledgeRecoveryRangeEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_RANGE* pRange) SetForgottenKnowledgeRecoveryRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_PROVIDER_ROLE provider, SYNC_PROGRESS_STAGE syncStage, uint32 dwCompletedWork, uint32 dwTotalWork) OnProgress;
	}


	public HRESULT IsCanceled(BOOL* pfIsCanceled) mut => VT.[Friend]IsCanceled(&this, pfIsCanceled);

	public HRESULT GetInfoForChangeApplication(uint8* pbChangeApplierInfo, uint32* pcbChangeApplierInfo) mut => VT.[Friend]GetInfoForChangeApplication(&this, pbChangeApplierInfo, pcbChangeApplierInfo);

	public HRESULT LoadInfoFromChangeApplication(uint8* pbChangeApplierInfo, uint32 cbChangeApplierInfo) mut => VT.[Friend]LoadInfoFromChangeApplication(&this, pbChangeApplierInfo, cbChangeApplierInfo);

	public HRESULT GetForgottenKnowledgeRecoveryRangeStart(uint8* pbRangeStart, uint32* pcbRangeStart) mut => VT.[Friend]GetForgottenKnowledgeRecoveryRangeStart(&this, pbRangeStart, pcbRangeStart);

	public HRESULT GetForgottenKnowledgeRecoveryRangeEnd(uint8* pbRangeEnd, uint32* pcbRangeEnd) mut => VT.[Friend]GetForgottenKnowledgeRecoveryRangeEnd(&this, pbRangeEnd, pcbRangeEnd);

	public HRESULT SetForgottenKnowledgeRecoveryRange(SYNC_RANGE* pRange) mut => VT.[Friend]SetForgottenKnowledgeRecoveryRange(&this, pRange);

	public HRESULT OnProgress(SYNC_PROVIDER_ROLE provider, SYNC_PROGRESS_STAGE syncStage, uint32 dwCompletedWork, uint32 dwTotalWork) mut => VT.[Friend]OnProgress(&this, provider, syncStage, dwCompletedWork, dwTotalWork);
}

[CRepr]struct ISyncSessionExtendedErrorInfo : IUnknown
{
	public new const Guid IID = .(0x326c6810, 0x790a, 0x409b, 0xb7, 0x41, 0x69, 0x99, 0x38, 0x87, 0x61, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncProvider** ppProviderWithError) GetSyncProviderWithError;
	}


	public HRESULT GetSyncProviderWithError(ISyncProvider** ppProviderWithError) mut => VT.[Friend]GetSyncProviderWithError(&this, ppProviderWithError);
}

[CRepr]struct ISyncSessionState2 : ISyncSessionState
{
	public new const Guid IID = .(0x9e37cfa3, 0x9e38, 0x4c61, 0x9c, 0xa3, 0xff, 0xe8, 0x10, 0xb4, 0x5c, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncSessionState.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fSelf) SetProviderWithError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phrSessionError) GetSessionErrorStatus;
	}


	public HRESULT SetProviderWithError(BOOL fSelf) mut => VT.[Friend]SetProviderWithError(&this, fSelf);

	public HRESULT GetSessionErrorStatus(HRESULT* phrSessionError) mut => VT.[Friend]GetSessionErrorStatus(&this, phrSessionError);
}

[CRepr]struct ISyncFilterInfo : IUnknown
{
	public new const Guid IID = .(0x794eaaf8, 0x3f2e, 0x47e6, 0x97, 0x28, 0x17, 0xe6, 0xfc, 0xf9, 0x4c, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbBuffer, uint32* pcbBuffer) Serialize;
	}


	public HRESULT Serialize(uint8* pbBuffer, uint32* pcbBuffer) mut => VT.[Friend]Serialize(&this, pbBuffer, pcbBuffer);
}

[CRepr]struct ISyncFilterInfo2 : ISyncFilterInfo
{
	public new const Guid IID = .(0x19b394ba, 0xe3d0, 0x468c, 0x93, 0x4d, 0x32, 0x19, 0x68, 0xb2, 0xab, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncFilterInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) COM_GetFlags;
	}


	public HRESULT GetFlags(uint32* pdwFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwFlags);
}

[CRepr]struct IChangeUnitListFilterInfo : ISyncFilterInfo
{
	public new const Guid IID = .(0xf2837671, 0x0bdf, 0x43fa, 0xb5, 0x02, 0x23, 0x23, 0x75, 0xfb, 0x50, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncFilterInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppbChangeUnitIds, uint32 dwChangeUnitCount) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwChangeUnitIdCount) GetChangeUnitIdCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangeUnitIdIndex, uint8* pbChangeUnitId, uint32* pcbIdSize) GetChangeUnitId;
	}


	public HRESULT Initialize(uint8** ppbChangeUnitIds, uint32 dwChangeUnitCount) mut => VT.[Friend]Initialize(&this, ppbChangeUnitIds, dwChangeUnitCount);

	public HRESULT GetChangeUnitIdCount(uint32* pdwChangeUnitIdCount) mut => VT.[Friend]GetChangeUnitIdCount(&this, pdwChangeUnitIdCount);

	public HRESULT GetChangeUnitId(uint32 dwChangeUnitIdIndex, uint8* pbChangeUnitId, uint32* pcbIdSize) mut => VT.[Friend]GetChangeUnitId(&this, dwChangeUnitIdIndex, pbChangeUnitId, pcbIdSize);
}

[CRepr]struct ISyncFilter : IUnknown
{
	public new const Guid IID = .(0x087a3f15, 0x0fcb, 0x44c1, 0x96, 0x39, 0x53, 0xc1, 0x4e, 0x2b, 0x55, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncFilter* pSyncFilter) IsIdentical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbSyncFilter, uint32* pcbSyncFilter) Serialize;
	}


	public HRESULT IsIdentical(ISyncFilter* pSyncFilter) mut => VT.[Friend]IsIdentical(&this, pSyncFilter);

	public HRESULT Serialize(uint8* pbSyncFilter, uint32* pcbSyncFilter) mut => VT.[Friend]Serialize(&this, pbSyncFilter, pcbSyncFilter);
}

[CRepr]struct ISyncFilterDeserializer : IUnknown
{
	public new const Guid IID = .(0xb45b7a72, 0xe5c7, 0x46be, 0x9c, 0x82, 0x77, 0xb8, 0xb1, 0x5d, 0xab, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbSyncFilter, uint32 dwCbSyncFilter, ISyncFilter** ppISyncFilter) DeserializeSyncFilter;
	}


	public HRESULT DeserializeSyncFilter(uint8* pbSyncFilter, uint32 dwCbSyncFilter, ISyncFilter** ppISyncFilter) mut => VT.[Friend]DeserializeSyncFilter(&this, pbSyncFilter, dwCbSyncFilter, ppISyncFilter);
}

[CRepr]struct ICustomFilterInfo : ISyncFilterInfo
{
	public new const Guid IID = .(0x1d335dff, 0x6f88, 0x4e4d, 0x91, 0xa8, 0xa3, 0xf3, 0x51, 0xcf, 0xd4, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncFilterInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncFilter** pISyncFilter) GetSyncFilter;
	}


	public HRESULT GetSyncFilter(ISyncFilter** pISyncFilter) mut => VT.[Friend]GetSyncFilter(&this, pISyncFilter);
}

[CRepr]struct ICombinedFilterInfo : ISyncFilterInfo
{
	public new const Guid IID = .(0x11f9de71, 0x2818, 0x4779, 0xb2, 0xac, 0x42, 0xd4, 0x50, 0x56, 0x5f, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncFilterInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFilterCount) GetFilterCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFilterIndex, ISyncFilterInfo** ppIFilterInfo) GetFilterInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILTER_COMBINATION_TYPE* pFilterCombinationType) GetFilterCombinationType;
	}


	public HRESULT GetFilterCount(uint32* pdwFilterCount) mut => VT.[Friend]GetFilterCount(&this, pdwFilterCount);

	public HRESULT GetFilterInfo(uint32 dwFilterIndex, ISyncFilterInfo** ppIFilterInfo) mut => VT.[Friend]GetFilterInfo(&this, dwFilterIndex, ppIFilterInfo);

	public HRESULT GetFilterCombinationType(FILTER_COMBINATION_TYPE* pFilterCombinationType) mut => VT.[Friend]GetFilterCombinationType(&this, pFilterCombinationType);
}

[CRepr]struct IEnumSyncChanges : IUnknown
{
	public new const Guid IID = .(0x5f86be4a, 0x5e78, 0x4e32, 0xac, 0x1c, 0xc2, 0x4f, 0xd2, 0x23, 0xef, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cChanges, ISyncChange** ppChange, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cChanges) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncChanges** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cChanges, ISyncChange** ppChange, uint32* pcFetched) mut => VT.[Friend]Next(&this, cChanges, ppChange, pcFetched);

	public HRESULT Skip(uint32 cChanges) mut => VT.[Friend]Skip(&this, cChanges);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncChanges** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct ISyncChangeBuilder : IUnknown
{
	public new const Guid IID = .(0x56f14771, 0x8677, 0x484f, 0xa1, 0x70, 0xe3, 0x86, 0xe4, 0x18, 0xa6, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbChangeUnitId, SYNC_VERSION* pChangeUnitVersion) AddChangeUnitMetadata;
	}


	public HRESULT AddChangeUnitMetadata(uint8* pbChangeUnitId, SYNC_VERSION* pChangeUnitVersion) mut => VT.[Friend]AddChangeUnitMetadata(&this, pbChangeUnitId, pChangeUnitVersion);
}

[CRepr]struct IFilterTrackingSyncChangeBuilder : IUnknown
{
	public new const Guid IID = .(0x295024a0, 0x70da, 0x4c58, 0x88, 0x3c, 0xce, 0x2a, 0xfb, 0x30, 0x8d, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFilterKey, SYNC_FILTER_CHANGE* pFilterChange) AddFilterChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetAllChangeUnitsPresentFlag;
	}


	public HRESULT AddFilterChange(uint32 dwFilterKey, SYNC_FILTER_CHANGE* pFilterChange) mut => VT.[Friend]AddFilterChange(&this, dwFilterKey, pFilterChange);

	public HRESULT SetAllChangeUnitsPresentFlag() mut => VT.[Friend]SetAllChangeUnitsPresentFlag(&this);
}

[CRepr]struct ISyncChangeBatchBase : IUnknown
{
	public new const Guid IID = .(0x52f6e694, 0x6a71, 0x4494, 0xa1, 0x84, 0xa8, 0x31, 0x1b, 0xf5, 0xd2, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncChanges** ppEnum) GetChangeEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfLastBatch) GetIsLastBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwWorkForBatch) GetWorkEstimateForBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRemainingWorkForSession) GetRemainingWorkEstimateForSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbLowerBound) BeginOrderedGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbUpperBound, ISyncKnowledge* pMadeWithKnowledge) EndOrderedGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbOwnerReplicaId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwFlags, uint32 dwWorkForChange, ISyncChangeBuilder** ppChangeBuilder) AddItemMetadataToGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppLearnedKnowledge) GetLearnedKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppPrerequisteKnowledge) GetPrerequisiteKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IForgottenKnowledge** ppSourceForgottenKnowledge) GetSourceForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetLastBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWorkForBatch) SetWorkEstimateForBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRemainingWorkForSession) SetRemainingWorkEstimateForSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbChangeBatch, uint32* pcbChangeBatch) Serialize;
	}


	public HRESULT GetChangeEnumerator(IEnumSyncChanges** ppEnum) mut => VT.[Friend]GetChangeEnumerator(&this, ppEnum);

	public HRESULT GetIsLastBatch(BOOL* pfLastBatch) mut => VT.[Friend]GetIsLastBatch(&this, pfLastBatch);

	public HRESULT GetWorkEstimateForBatch(uint32* pdwWorkForBatch) mut => VT.[Friend]GetWorkEstimateForBatch(&this, pdwWorkForBatch);

	public HRESULT GetRemainingWorkEstimateForSession(uint32* pdwRemainingWorkForSession) mut => VT.[Friend]GetRemainingWorkEstimateForSession(&this, pdwRemainingWorkForSession);

	public HRESULT BeginOrderedGroup(uint8* pbLowerBound) mut => VT.[Friend]BeginOrderedGroup(&this, pbLowerBound);

	public HRESULT EndOrderedGroup(uint8* pbUpperBound, ISyncKnowledge* pMadeWithKnowledge) mut => VT.[Friend]EndOrderedGroup(&this, pbUpperBound, pMadeWithKnowledge);

	public HRESULT AddItemMetadataToGroup(uint8* pbOwnerReplicaId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwFlags, uint32 dwWorkForChange, ISyncChangeBuilder** ppChangeBuilder) mut => VT.[Friend]AddItemMetadataToGroup(&this, pbOwnerReplicaId, pbItemId, pChangeVersion, pCreationVersion, dwFlags, dwWorkForChange, ppChangeBuilder);

	public HRESULT GetLearnedKnowledge(ISyncKnowledge** ppLearnedKnowledge) mut => VT.[Friend]GetLearnedKnowledge(&this, ppLearnedKnowledge);

	public HRESULT GetPrerequisiteKnowledge(ISyncKnowledge** ppPrerequisteKnowledge) mut => VT.[Friend]GetPrerequisiteKnowledge(&this, ppPrerequisteKnowledge);

	public HRESULT GetSourceForgottenKnowledge(IForgottenKnowledge** ppSourceForgottenKnowledge) mut => VT.[Friend]GetSourceForgottenKnowledge(&this, ppSourceForgottenKnowledge);

	public HRESULT SetLastBatch() mut => VT.[Friend]SetLastBatch(&this);

	public HRESULT SetWorkEstimateForBatch(uint32 dwWorkForBatch) mut => VT.[Friend]SetWorkEstimateForBatch(&this, dwWorkForBatch);

	public HRESULT SetRemainingWorkEstimateForSession(uint32 dwRemainingWorkForSession) mut => VT.[Friend]SetRemainingWorkEstimateForSession(&this, dwRemainingWorkForSession);

	public HRESULT Serialize(uint8* pbChangeBatch, uint32* pcbChangeBatch) mut => VT.[Friend]Serialize(&this, pbChangeBatch, pcbChangeBatch);
}

[CRepr]struct ISyncChangeBatch : ISyncChangeBatchBase
{
	public new const Guid IID = .(0x70c64dee, 0x380f, 0x4c2e, 0x8f, 0x70, 0x31, 0xc5, 0x5b, 0xd5, 0xf9, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncChangeBatchBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginUnorderedGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pMadeWithKnowledge, BOOL fAllChangesForKnowledge) EndUnorderedGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbOwnerReplicaId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwFlags, uint32 dwWorkForChange, ISyncKnowledge* pConflictKnowledge, ISyncChangeBuilder** ppChangeBuilder) AddLoggedConflict;
	}


	public HRESULT BeginUnorderedGroup() mut => VT.[Friend]BeginUnorderedGroup(&this);

	public HRESULT EndUnorderedGroup(ISyncKnowledge* pMadeWithKnowledge, BOOL fAllChangesForKnowledge) mut => VT.[Friend]EndUnorderedGroup(&this, pMadeWithKnowledge, fAllChangesForKnowledge);

	public HRESULT AddLoggedConflict(uint8* pbOwnerReplicaId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwFlags, uint32 dwWorkForChange, ISyncKnowledge* pConflictKnowledge, ISyncChangeBuilder** ppChangeBuilder) mut => VT.[Friend]AddLoggedConflict(&this, pbOwnerReplicaId, pbItemId, pChangeVersion, pCreationVersion, dwFlags, dwWorkForChange, pConflictKnowledge, ppChangeBuilder);
}

[CRepr]struct ISyncFullEnumerationChangeBatch : ISyncChangeBatchBase
{
	public new const Guid IID = .(0xef64197d, 0x4f44, 0x4ea2, 0xb3, 0x55, 0x45, 0x24, 0x71, 0x3e, 0x3b, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncChangeBatchBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppLearnedKnowledgeAfterRecoveryComplete) GetLearnedKnowledgeAfterRecoveryComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbClosedLowerBoundItemId, uint32* pcbIdSize) GetClosedLowerBoundItemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbClosedUpperBoundItemId, uint32* pcbIdSize) GetClosedUpperBoundItemId;
	}


	public HRESULT GetLearnedKnowledgeAfterRecoveryComplete(ISyncKnowledge** ppLearnedKnowledgeAfterRecoveryComplete) mut => VT.[Friend]GetLearnedKnowledgeAfterRecoveryComplete(&this, ppLearnedKnowledgeAfterRecoveryComplete);

	public HRESULT GetClosedLowerBoundItemId(uint8* pbClosedLowerBoundItemId, uint32* pcbIdSize) mut => VT.[Friend]GetClosedLowerBoundItemId(&this, pbClosedLowerBoundItemId, pcbIdSize);

	public HRESULT GetClosedUpperBoundItemId(uint8* pbClosedUpperBoundItemId, uint32* pcbIdSize) mut => VT.[Friend]GetClosedUpperBoundItemId(&this, pbClosedUpperBoundItemId, pcbIdSize);
}

[CRepr]struct ISyncChangeBatchWithPrerequisite : ISyncChangeBatchBase
{
	public new const Guid IID = .(0x097f13be, 0x5b92, 0x4048, 0xb3, 0xf2, 0x7b, 0x42, 0xa2, 0x51, 0x5e, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncChangeBatchBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pPrerequisiteKnowledge) SetPrerequisiteKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, ISyncKnowledge** ppLearnedWithPrerequisiteKnowledge) GetLearnedKnowledgeWithPrerequisite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IForgottenKnowledge** ppLearnedForgottenKnowledge) GetLearnedForgottenKnowledge;
	}


	public HRESULT SetPrerequisiteKnowledge(ISyncKnowledge* pPrerequisiteKnowledge) mut => VT.[Friend]SetPrerequisiteKnowledge(&this, pPrerequisiteKnowledge);

	public HRESULT GetLearnedKnowledgeWithPrerequisite(ISyncKnowledge* pDestinationKnowledge, ISyncKnowledge** ppLearnedWithPrerequisiteKnowledge) mut => VT.[Friend]GetLearnedKnowledgeWithPrerequisite(&this, pDestinationKnowledge, ppLearnedWithPrerequisiteKnowledge);

	public HRESULT GetLearnedForgottenKnowledge(IForgottenKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetLearnedForgottenKnowledge(&this, ppLearnedForgottenKnowledge);
}

[CRepr]struct ISyncChangeBatchBase2 : ISyncChangeBatchBase
{
	public new const Guid IID = .(0x6fdb596a, 0xd755, 0x4584, 0xbd, 0x0c, 0xc0, 0xc2, 0x3a, 0x54, 0x8f, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncChangeBatchBase.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_SERIALIZATION_VERSION targetFormatVersion, uint32 dwFlags, uint8* pbBuffer, uint32* pdwSerializedSize) SerializeWithOptions;
	}


	public HRESULT SerializeWithOptions(SYNC_SERIALIZATION_VERSION targetFormatVersion, uint32 dwFlags, uint8* pbBuffer, uint32* pdwSerializedSize) mut => VT.[Friend]SerializeWithOptions(&this, targetFormatVersion, dwFlags, pbBuffer, pdwSerializedSize);
}

[CRepr]struct ISyncChangeBatchAdvanced : IUnknown
{
	public new const Guid IID = .(0x0f1a4995, 0xcbc8, 0x421d, 0xb5, 0x50, 0x5d, 0x0b, 0xeb, 0xf3, 0xe9, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncFilterInfo** ppFilterInfo) GetFilterInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChangeBatch** ppChangeBatch) ConvertFullEnumerationChangeBatchToRegularChangeBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint32* pcbIdSize) GetUpperBoundItemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfBatchKnowledgeShouldBeApplied) GetBatchLevelKnowledgeShouldBeApplied;
	}


	public HRESULT GetFilterInfo(ISyncFilterInfo** ppFilterInfo) mut => VT.[Friend]GetFilterInfo(&this, ppFilterInfo);

	public HRESULT ConvertFullEnumerationChangeBatchToRegularChangeBatch(ISyncChangeBatch** ppChangeBatch) mut => VT.[Friend]ConvertFullEnumerationChangeBatchToRegularChangeBatch(&this, ppChangeBatch);

	public HRESULT GetUpperBoundItemId(uint8* pbItemId, uint32* pcbIdSize) mut => VT.[Friend]GetUpperBoundItemId(&this, pbItemId, pcbIdSize);

	public HRESULT GetBatchLevelKnowledgeShouldBeApplied(BOOL* pfBatchKnowledgeShouldBeApplied) mut => VT.[Friend]GetBatchLevelKnowledgeShouldBeApplied(&this, pfBatchKnowledgeShouldBeApplied);
}

[CRepr]struct ISyncChangeBatch2 : ISyncChangeBatch
{
	public new const Guid IID = .(0x225f4a33, 0xf5ee, 0x4cc7, 0xb0, 0x39, 0x67, 0xa2, 0x62, 0xb4, 0xb2, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncChangeBatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbOwnerReplicaId, uint8* pbWinnerItemId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwWorkForChange, ISyncChangeBuilder** ppChangeBuilder) AddMergeTombstoneMetadataToGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbOwnerReplicaId, uint8* pbWinnerItemId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwWorkForChange, ISyncKnowledge* pConflictKnowledge, ISyncChangeBuilder** ppChangeBuilder) AddMergeTombstoneLoggedConflict;
	}


	public HRESULT AddMergeTombstoneMetadataToGroup(uint8* pbOwnerReplicaId, uint8* pbWinnerItemId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwWorkForChange, ISyncChangeBuilder** ppChangeBuilder) mut => VT.[Friend]AddMergeTombstoneMetadataToGroup(&this, pbOwnerReplicaId, pbWinnerItemId, pbItemId, pChangeVersion, pCreationVersion, dwWorkForChange, ppChangeBuilder);

	public HRESULT AddMergeTombstoneLoggedConflict(uint8* pbOwnerReplicaId, uint8* pbWinnerItemId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwWorkForChange, ISyncKnowledge* pConflictKnowledge, ISyncChangeBuilder** ppChangeBuilder) mut => VT.[Friend]AddMergeTombstoneLoggedConflict(&this, pbOwnerReplicaId, pbWinnerItemId, pbItemId, pChangeVersion, pCreationVersion, dwWorkForChange, pConflictKnowledge, ppChangeBuilder);
}

[CRepr]struct ISyncFullEnumerationChangeBatch2 : ISyncFullEnumerationChangeBatch
{
	public new const Guid IID = .(0xe06449f4, 0xa205, 0x4b65, 0x97, 0x24, 0x01, 0xb2, 0x21, 0x01, 0xee, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncFullEnumerationChangeBatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbOwnerReplicaId, uint8* pbWinnerItemId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwWorkForChange, ISyncChangeBuilder** ppChangeBuilder) AddMergeTombstoneMetadataToGroup;
	}


	public HRESULT AddMergeTombstoneMetadataToGroup(uint8* pbOwnerReplicaId, uint8* pbWinnerItemId, uint8* pbItemId, SYNC_VERSION* pChangeVersion, SYNC_VERSION* pCreationVersion, uint32 dwWorkForChange, ISyncChangeBuilder** ppChangeBuilder) mut => VT.[Friend]AddMergeTombstoneMetadataToGroup(&this, pbOwnerReplicaId, pbWinnerItemId, pbItemId, pChangeVersion, pCreationVersion, dwWorkForChange, ppChangeBuilder);
}

[CRepr]struct IKnowledgeSyncProvider : ISyncProvider
{
	public new const Guid IID = .(0x43434a49, 0x8da4, 0x47f2, 0x81, 0x72, 0xad, 0x7b, 0x8b, 0x02, 0x49, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_PROVIDER_ROLE role, ISyncSessionState* pSessionState) BeginSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppSyncKnowledge, uint32* pdwRequestedBatchSize) GetSyncBatchParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBatchSize, ISyncKnowledge* pSyncKnowledge, ISyncChangeBatch** ppSyncChangeBatch, IUnknown** ppUnkDataRetriever) GetChangeBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBatchSize, uint8* pbLowerEnumerationBound, ISyncKnowledge* pSyncKnowledge, ISyncFullEnumerationChangeBatch** ppSyncChangeBatch, IUnknown** ppUnkDataRetriever) GetFullEnumerationChangeBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONFLICT_RESOLUTION_POLICY resolutionPolicy, ISyncChangeBatch* pSourceChangeBatch, IUnknown* pUnkDataRetriever, ISyncCallback* pCallback, SYNC_SESSION_STATISTICS* pSyncSessionStatistics) ProcessChangeBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONFLICT_RESOLUTION_POLICY resolutionPolicy, ISyncFullEnumerationChangeBatch* pSourceChangeBatch, IUnknown* pUnkDataRetriever, ISyncCallback* pCallback, SYNC_SESSION_STATISTICS* pSyncSessionStatistics) ProcessFullEnumerationChangeBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncSessionState* pSessionState) EndSession;
	}


	public HRESULT BeginSession(SYNC_PROVIDER_ROLE role, ISyncSessionState* pSessionState) mut => VT.[Friend]BeginSession(&this, role, pSessionState);

	public HRESULT GetSyncBatchParameters(ISyncKnowledge** ppSyncKnowledge, uint32* pdwRequestedBatchSize) mut => VT.[Friend]GetSyncBatchParameters(&this, ppSyncKnowledge, pdwRequestedBatchSize);

	public HRESULT GetChangeBatch(uint32 dwBatchSize, ISyncKnowledge* pSyncKnowledge, ISyncChangeBatch** ppSyncChangeBatch, IUnknown** ppUnkDataRetriever) mut => VT.[Friend]GetChangeBatch(&this, dwBatchSize, pSyncKnowledge, ppSyncChangeBatch, ppUnkDataRetriever);

	public HRESULT GetFullEnumerationChangeBatch(uint32 dwBatchSize, uint8* pbLowerEnumerationBound, ISyncKnowledge* pSyncKnowledge, ISyncFullEnumerationChangeBatch** ppSyncChangeBatch, IUnknown** ppUnkDataRetriever) mut => VT.[Friend]GetFullEnumerationChangeBatch(&this, dwBatchSize, pbLowerEnumerationBound, pSyncKnowledge, ppSyncChangeBatch, ppUnkDataRetriever);

	public HRESULT ProcessChangeBatch(CONFLICT_RESOLUTION_POLICY resolutionPolicy, ISyncChangeBatch* pSourceChangeBatch, IUnknown* pUnkDataRetriever, ISyncCallback* pCallback, SYNC_SESSION_STATISTICS* pSyncSessionStatistics) mut => VT.[Friend]ProcessChangeBatch(&this, resolutionPolicy, pSourceChangeBatch, pUnkDataRetriever, pCallback, pSyncSessionStatistics);

	public HRESULT ProcessFullEnumerationChangeBatch(CONFLICT_RESOLUTION_POLICY resolutionPolicy, ISyncFullEnumerationChangeBatch* pSourceChangeBatch, IUnknown* pUnkDataRetriever, ISyncCallback* pCallback, SYNC_SESSION_STATISTICS* pSyncSessionStatistics) mut => VT.[Friend]ProcessFullEnumerationChangeBatch(&this, resolutionPolicy, pSourceChangeBatch, pUnkDataRetriever, pCallback, pSyncSessionStatistics);

	public HRESULT EndSession(ISyncSessionState* pSessionState) mut => VT.[Friend]EndSession(&this, pSessionState);
}

[CRepr]struct ISyncChangeUnit : IUnknown
{
	public new const Guid IID = .(0x60edd8ca, 0x7341, 0x4bb7, 0x95, 0xce, 0xfa, 0xb6, 0x39, 0x4b, 0x51, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppSyncChange) GetItemChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbChangeUnitId, uint32* pcbIdSize) GetChangeUnitId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbCurrentReplicaId, SYNC_VERSION* pVersion) GetChangeUnitVersion;
	}


	public HRESULT GetItemChange(ISyncChange** ppSyncChange) mut => VT.[Friend]GetItemChange(&this, ppSyncChange);

	public HRESULT GetChangeUnitId(uint8* pbChangeUnitId, uint32* pcbIdSize) mut => VT.[Friend]GetChangeUnitId(&this, pbChangeUnitId, pcbIdSize);

	public HRESULT GetChangeUnitVersion(uint8* pbCurrentReplicaId, SYNC_VERSION* pVersion) mut => VT.[Friend]GetChangeUnitVersion(&this, pbCurrentReplicaId, pVersion);
}

[CRepr]struct IEnumSyncChangeUnits : IUnknown
{
	public new const Guid IID = .(0x346b35f1, 0x8703, 0x4c6d, 0xab, 0x1a, 0x4d, 0xbc, 0xa2, 0xcf, 0xf9, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cChanges, ISyncChangeUnit** ppChangeUnit, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cChanges) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncChangeUnits** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cChanges, ISyncChangeUnit** ppChangeUnit, uint32* pcFetched) mut => VT.[Friend]Next(&this, cChanges, ppChangeUnit, pcFetched);

	public HRESULT Skip(uint32 cChanges) mut => VT.[Friend]Skip(&this, cChanges);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncChangeUnits** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct ISyncChange : IUnknown
{
	public new const Guid IID = .(0xa1952beb, 0x0f6b, 0x4711, 0xb1, 0x36, 0x01, 0xda, 0x85, 0xb9, 0x68, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbReplicaId, uint32* pcbIdSize) GetOwnerReplicaId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbRootItemId, uint32* pcbIdSize) GetRootItemId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbCurrentReplicaId, SYNC_VERSION* pVersion) GetChangeVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbCurrentReplicaId, SYNC_VERSION* pVersion) GetCreationVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwWork) GetWorkEstimate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncChangeUnits** ppEnum) GetChangeUnits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppMadeWithKnowledge) GetMadeWithKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppLearnedKnowledge) GetLearnedKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWork) SetWorkEstimate;
	}


	public HRESULT GetOwnerReplicaId(uint8* pbReplicaId, uint32* pcbIdSize) mut => VT.[Friend]GetOwnerReplicaId(&this, pbReplicaId, pcbIdSize);

	public HRESULT GetRootItemId(uint8* pbRootItemId, uint32* pcbIdSize) mut => VT.[Friend]GetRootItemId(&this, pbRootItemId, pcbIdSize);

	public HRESULT GetChangeVersion(uint8* pbCurrentReplicaId, SYNC_VERSION* pVersion) mut => VT.[Friend]GetChangeVersion(&this, pbCurrentReplicaId, pVersion);

	public HRESULT GetCreationVersion(uint8* pbCurrentReplicaId, SYNC_VERSION* pVersion) mut => VT.[Friend]GetCreationVersion(&this, pbCurrentReplicaId, pVersion);

	public HRESULT GetFlags(uint32* pdwFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwFlags);

	public HRESULT GetWorkEstimate(uint32* pdwWork) mut => VT.[Friend]GetWorkEstimate(&this, pdwWork);

	public HRESULT GetChangeUnits(IEnumSyncChangeUnits** ppEnum) mut => VT.[Friend]GetChangeUnits(&this, ppEnum);

	public HRESULT GetMadeWithKnowledge(ISyncKnowledge** ppMadeWithKnowledge) mut => VT.[Friend]GetMadeWithKnowledge(&this, ppMadeWithKnowledge);

	public HRESULT GetLearnedKnowledge(ISyncKnowledge** ppLearnedKnowledge) mut => VT.[Friend]GetLearnedKnowledge(&this, ppLearnedKnowledge);

	public HRESULT SetWorkEstimate(uint32 dwWork) mut => VT.[Friend]SetWorkEstimate(&this, dwWork);
}

[CRepr]struct ISyncChangeWithPrerequisite : IUnknown
{
	public new const Guid IID = .(0x9e38382f, 0x1589, 0x48c3, 0x92, 0xe4, 0x05, 0xec, 0xdc, 0xb4, 0xf3, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppPrerequisiteKnowledge) GetPrerequisiteKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, ISyncKnowledge** ppLearnedKnowledgeWithPrerequisite) GetLearnedKnowledgeWithPrerequisite;
	}


	public HRESULT GetPrerequisiteKnowledge(ISyncKnowledge** ppPrerequisiteKnowledge) mut => VT.[Friend]GetPrerequisiteKnowledge(&this, ppPrerequisiteKnowledge);

	public HRESULT GetLearnedKnowledgeWithPrerequisite(ISyncKnowledge* pDestinationKnowledge, ISyncKnowledge** ppLearnedKnowledgeWithPrerequisite) mut => VT.[Friend]GetLearnedKnowledgeWithPrerequisite(&this, pDestinationKnowledge, ppLearnedKnowledgeWithPrerequisite);
}

[CRepr]struct ISyncFullEnumerationChange : IUnknown
{
	public new const Guid IID = .(0x9785e0bd, 0xbdff, 0x40c4, 0x98, 0xc5, 0xb3, 0x4b, 0x2f, 0x19, 0x91, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge** ppLearnedKnowledge) GetLearnedKnowledgeAfterRecoveryComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IForgottenKnowledge** ppLearnedForgottenKnowledge) GetLearnedForgottenKnowledge;
	}


	public HRESULT GetLearnedKnowledgeAfterRecoveryComplete(ISyncKnowledge** ppLearnedKnowledge) mut => VT.[Friend]GetLearnedKnowledgeAfterRecoveryComplete(&this, ppLearnedKnowledge);

	public HRESULT GetLearnedForgottenKnowledge(IForgottenKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetLearnedForgottenKnowledge(&this, ppLearnedForgottenKnowledge);
}

[CRepr]struct ISyncMergeTombstoneChange : IUnknown
{
	public new const Guid IID = .(0x6ec62597, 0x0903, 0x484c, 0xad, 0x61, 0x36, 0xd6, 0xe9, 0x38, 0xf4, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbWinnerItemId, uint32* pcbIdSize) GetWinnerItemId;
	}


	public HRESULT GetWinnerItemId(uint8* pbWinnerItemId, uint32* pcbIdSize) mut => VT.[Friend]GetWinnerItemId(&this, pbWinnerItemId, pcbIdSize);
}

[CRepr]struct IEnumItemIds : IUnknown
{
	public new const Guid IID = .(0x43aa3f61, 0x4b2e, 0x4b60, 0x83, 0xdf, 0xb1, 0x10, 0xd3, 0xe1, 0x48, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint32* pcbItemIdSize) Next;
	}


	public HRESULT Next(uint8* pbItemId, uint32* pcbItemIdSize) mut => VT.[Friend]Next(&this, pbItemId, pcbItemIdSize);
}

[CRepr]struct IFilterKeyMap : IUnknown
{
	public new const Guid IID = .(0xca169652, 0x07c6, 0x4708, 0xa3, 0xda, 0x6e, 0x4e, 0xba, 0x8d, 0x22, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncFilter* pISyncFilter, uint32* pdwFilterKey) AddFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFilterKey, ISyncFilter** ppISyncFilter) GetFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbFilterKeyMap, uint32* pcbFilterKeyMap) Serialize;
	}


	public HRESULT GetCount(uint32* pdwCount) mut => VT.[Friend]GetCount(&this, pdwCount);

	public HRESULT AddFilter(ISyncFilter* pISyncFilter, uint32* pdwFilterKey) mut => VT.[Friend]AddFilter(&this, pISyncFilter, pdwFilterKey);

	public HRESULT GetFilter(uint32 dwFilterKey, ISyncFilter** ppISyncFilter) mut => VT.[Friend]GetFilter(&this, dwFilterKey, ppISyncFilter);

	public HRESULT Serialize(uint8* pbFilterKeyMap, uint32* pcbFilterKeyMap) mut => VT.[Friend]Serialize(&this, pbFilterKeyMap, pcbFilterKeyMap);
}

[CRepr]struct ISyncChangeWithFilterKeyMap : IUnknown
{
	public new const Guid IID = .(0xbfe1ef00, 0xe87d, 0x42fd, 0xa4, 0xe9, 0x24, 0x2d, 0x70, 0x41, 0x4a, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFilterCount) GetFilterCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFilterKey, SYNC_FILTER_CHANGE* pFilterChange) GetFilterChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAllChangeUnitsPresent) GetAllChangeUnitsPresentFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFilterKey, ISyncKnowledge** ppIFilterForgottenKnowledge) GetFilterForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedKnowledge) GetFilteredReplicaLearnedKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) GetLearnedFilterForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) GetFilteredReplicaLearnedForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) GetFilteredReplicaLearnedForgottenKnowledgeAfterRecoveryComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) GetLearnedFilterForgottenKnowledgeAfterRecoveryComplete;
	}


	public HRESULT GetFilterCount(uint32* pdwFilterCount) mut => VT.[Friend]GetFilterCount(&this, pdwFilterCount);

	public HRESULT GetFilterChange(uint32 dwFilterKey, SYNC_FILTER_CHANGE* pFilterChange) mut => VT.[Friend]GetFilterChange(&this, dwFilterKey, pFilterChange);

	public HRESULT GetAllChangeUnitsPresentFlag(BOOL* pfAllChangeUnitsPresent) mut => VT.[Friend]GetAllChangeUnitsPresentFlag(&this, pfAllChangeUnitsPresent);

	public HRESULT GetFilterForgottenKnowledge(uint32 dwFilterKey, ISyncKnowledge** ppIFilterForgottenKnowledge) mut => VT.[Friend]GetFilterForgottenKnowledge(&this, dwFilterKey, ppIFilterForgottenKnowledge);

	public HRESULT GetFilteredReplicaLearnedKnowledge(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedKnowledge) mut => VT.[Friend]GetFilteredReplicaLearnedKnowledge(&this, pDestinationKnowledge, pNewMoveins, ppLearnedKnowledge);

	public HRESULT GetLearnedFilterForgottenKnowledge(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) mut => VT.[Friend]GetLearnedFilterForgottenKnowledge(&this, pDestinationKnowledge, pNewMoveins, dwFilterKey, ppLearnedFilterForgottenKnowledge);

	public HRESULT GetFilteredReplicaLearnedForgottenKnowledge(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetFilteredReplicaLearnedForgottenKnowledge(&this, pDestinationKnowledge, pNewMoveins, ppLearnedForgottenKnowledge);

	public HRESULT GetFilteredReplicaLearnedForgottenKnowledgeAfterRecoveryComplete(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetFilteredReplicaLearnedForgottenKnowledgeAfterRecoveryComplete(&this, pDestinationKnowledge, pNewMoveins, ppLearnedForgottenKnowledge);

	public HRESULT GetLearnedFilterForgottenKnowledgeAfterRecoveryComplete(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) mut => VT.[Friend]GetLearnedFilterForgottenKnowledgeAfterRecoveryComplete(&this, pDestinationKnowledge, pNewMoveins, dwFilterKey, ppLearnedFilterForgottenKnowledge);
}

[CRepr]struct ISyncChangeBatchWithFilterKeyMap : IUnknown
{
	public new const Guid IID = .(0xde247002, 0x566d, 0x459a, 0xa6, 0xed, 0xa5, 0xaa, 0xb3, 0x45, 0x9f, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFilterKeyMap** ppIFilterKeyMap) GetFilterKeyMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFilterKeyMap* pIFilterKeyMap) SetFilterKeyMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFilterKey, ISyncKnowledge* pFilterForgottenKnowledge) SetFilterForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) GetFilteredReplicaLearnedKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) GetLearnedFilterForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) GetFilteredReplicaLearnedForgottenKnowledge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) GetFilteredReplicaLearnedForgottenKnowledgeAfterRecoveryComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) GetLearnedFilterForgottenKnowledgeAfterRecoveryComplete;
	}


	public HRESULT GetFilterKeyMap(IFilterKeyMap** ppIFilterKeyMap) mut => VT.[Friend]GetFilterKeyMap(&this, ppIFilterKeyMap);

	public HRESULT SetFilterKeyMap(IFilterKeyMap* pIFilterKeyMap) mut => VT.[Friend]SetFilterKeyMap(&this, pIFilterKeyMap);

	public HRESULT SetFilterForgottenKnowledge(uint32 dwFilterKey, ISyncKnowledge* pFilterForgottenKnowledge) mut => VT.[Friend]SetFilterForgottenKnowledge(&this, dwFilterKey, pFilterForgottenKnowledge);

	public HRESULT GetFilteredReplicaLearnedKnowledge(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetFilteredReplicaLearnedKnowledge(&this, pDestinationKnowledge, pNewMoveins, ppLearnedForgottenKnowledge);

	public HRESULT GetLearnedFilterForgottenKnowledge(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) mut => VT.[Friend]GetLearnedFilterForgottenKnowledge(&this, pDestinationKnowledge, pNewMoveins, dwFilterKey, ppLearnedFilterForgottenKnowledge);

	public HRESULT GetFilteredReplicaLearnedForgottenKnowledge(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetFilteredReplicaLearnedForgottenKnowledge(&this, pDestinationKnowledge, pNewMoveins, ppLearnedForgottenKnowledge);

	public HRESULT GetFilteredReplicaLearnedForgottenKnowledgeAfterRecoveryComplete(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, ISyncKnowledge** ppLearnedForgottenKnowledge) mut => VT.[Friend]GetFilteredReplicaLearnedForgottenKnowledgeAfterRecoveryComplete(&this, pDestinationKnowledge, pNewMoveins, ppLearnedForgottenKnowledge);

	public HRESULT GetLearnedFilterForgottenKnowledgeAfterRecoveryComplete(ISyncKnowledge* pDestinationKnowledge, IEnumItemIds* pNewMoveins, uint32 dwFilterKey, ISyncKnowledge** ppLearnedFilterForgottenKnowledge) mut => VT.[Friend]GetLearnedFilterForgottenKnowledgeAfterRecoveryComplete(&this, pDestinationKnowledge, pNewMoveins, dwFilterKey, ppLearnedFilterForgottenKnowledge);
}

[CRepr]struct IDataRetrieverCallback : IUnknown
{
	public new const Guid IID = .(0x71b4863b, 0xf969, 0x4676, 0xbb, 0xc3, 0x3d, 0x9f, 0xdc, 0x3f, 0xb2, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkData) LoadChangeDataComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrError) LoadChangeDataError;
	}


	public HRESULT LoadChangeDataComplete(IUnknown* pUnkData) mut => VT.[Friend]LoadChangeDataComplete(&this, pUnkData);

	public HRESULT LoadChangeDataError(HRESULT hrError) mut => VT.[Friend]LoadChangeDataError(&this, hrError);
}

[CRepr]struct ILoadChangeContext : IUnknown
{
	public new const Guid IID = .(0x44a4aaca, 0xec39, 0x46d5, 0xb5, 0xc9, 0xd6, 0x33, 0xc0, 0xee, 0x67, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncChange** ppSyncChange) GetSyncChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrError, IRecoverableErrorData* pErrorData) SetRecoverableErrorOnChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrError, ISyncChangeUnit* pChangeUnit, IRecoverableErrorData* pErrorData) SetRecoverableErrorOnChangeUnit;
	}


	public HRESULT GetSyncChange(ISyncChange** ppSyncChange) mut => VT.[Friend]GetSyncChange(&this, ppSyncChange);

	public HRESULT SetRecoverableErrorOnChange(HRESULT hrError, IRecoverableErrorData* pErrorData) mut => VT.[Friend]SetRecoverableErrorOnChange(&this, hrError, pErrorData);

	public HRESULT SetRecoverableErrorOnChangeUnit(HRESULT hrError, ISyncChangeUnit* pChangeUnit, IRecoverableErrorData* pErrorData) mut => VT.[Friend]SetRecoverableErrorOnChangeUnit(&this, hrError, pChangeUnit, pErrorData);
}

[CRepr]struct ISynchronousDataRetriever : IUnknown
{
	public new const Guid IID = .(0x9b22f2a9, 0xa4cd, 0x4648, 0x9d, 0x8e, 0x3a, 0x51, 0x0d, 0x4d, 0xa0, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID_PARAMETERS* pIdParameters) GetIdParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILoadChangeContext* pLoadChangeContext, IUnknown** ppUnkData) LoadChangeData;
	}


	public HRESULT GetIdParameters(ID_PARAMETERS* pIdParameters) mut => VT.[Friend]GetIdParameters(&this, pIdParameters);

	public HRESULT LoadChangeData(ILoadChangeContext* pLoadChangeContext, IUnknown** ppUnkData) mut => VT.[Friend]LoadChangeData(&this, pLoadChangeContext, ppUnkData);
}

[CRepr]struct IAsynchronousDataRetriever : IUnknown
{
	public new const Guid IID = .(0x9fc7e470, 0x61ea, 0x4a88, 0x9b, 0xe4, 0xdf, 0x56, 0xa2, 0x7c, 0xfe, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID_PARAMETERS* pIdParameters) GetIdParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataRetrieverCallback* pDataRetrieverCallback) RegisterCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataRetrieverCallback* pDataRetrieverCallback) RevokeCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILoadChangeContext* pLoadChangeContext) LoadChangeData;
	}


	public HRESULT GetIdParameters(ID_PARAMETERS* pIdParameters) mut => VT.[Friend]GetIdParameters(&this, pIdParameters);

	public HRESULT RegisterCallback(IDataRetrieverCallback* pDataRetrieverCallback) mut => VT.[Friend]RegisterCallback(&this, pDataRetrieverCallback);

	public HRESULT RevokeCallback(IDataRetrieverCallback* pDataRetrieverCallback) mut => VT.[Friend]RevokeCallback(&this, pDataRetrieverCallback);

	public HRESULT LoadChangeData(ILoadChangeContext* pLoadChangeContext) mut => VT.[Friend]LoadChangeData(&this, pLoadChangeContext);
}

[CRepr]struct IFilterRequestCallback : IUnknown
{
	public new const Guid IID = .(0x82df8873, 0x6360, 0x463a, 0xa8, 0xa1, 0xed, 0xe5, 0xe1, 0xa1, 0x59, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pFilter, FILTERING_TYPE filteringType) RequestFilter;
	}


	public HRESULT RequestFilter(IUnknown* pFilter, FILTERING_TYPE filteringType) mut => VT.[Friend]RequestFilter(&this, pFilter, filteringType);
}

[CRepr]struct IRequestFilteredSync : IUnknown
{
	public new const Guid IID = .(0x2e020184, 0x6d18, 0x46a7, 0xa3, 0x2a, 0xda, 0x4a, 0xeb, 0x06, 0x69, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFilterRequestCallback* pCallback) SpecifyFilter;
	}


	public HRESULT SpecifyFilter(IFilterRequestCallback* pCallback) mut => VT.[Friend]SpecifyFilter(&this, pCallback);
}

[CRepr]struct ISupportFilteredSync : IUnknown
{
	public new const Guid IID = .(0x3d128ded, 0xd555, 0x4e0d, 0xbf, 0x4b, 0xfb, 0x21, 0x3a, 0x8a, 0x93, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pFilter, FILTERING_TYPE filteringType) AddFilter;
	}


	public HRESULT AddFilter(IUnknown* pFilter, FILTERING_TYPE filteringType) mut => VT.[Friend]AddFilter(&this, pFilter, filteringType);
}

[CRepr]struct IFilterTrackingRequestCallback : IUnknown
{
	public new const Guid IID = .(0x713ca7bb, 0xc858, 0x4674, 0xb4, 0xb6, 0x11, 0x22, 0x43, 0x65, 0x87, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncFilter* pFilter) RequestTrackedFilter;
	}


	public HRESULT RequestTrackedFilter(ISyncFilter* pFilter) mut => VT.[Friend]RequestTrackedFilter(&this, pFilter);
}

[CRepr]struct IFilterTrackingProvider : IUnknown
{
	public new const Guid IID = .(0x743383c0, 0xfc4e, 0x45ba, 0xad, 0x81, 0xd9, 0xd8, 0x4c, 0x7a, 0x24, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFilterTrackingRequestCallback* pCallback) SpecifyTrackedFilters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncFilter* pFilter) AddTrackedFilter;
	}


	public HRESULT SpecifyTrackedFilters(IFilterTrackingRequestCallback* pCallback) mut => VT.[Friend]SpecifyTrackedFilters(&this, pCallback);

	public HRESULT AddTrackedFilter(ISyncFilter* pFilter) mut => VT.[Friend]AddTrackedFilter(&this, pFilter);
}

[CRepr]struct ISupportLastWriteTime : IUnknown
{
	public new const Guid IID = .(0xeadf816f, 0xd0bd, 0x43ca, 0x8f, 0x40, 0x5a, 0xcd, 0xc6, 0xc0, 0x6f, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint64* pullTimestamp) GetItemChangeTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbItemId, uint8* pbChangeUnitId, uint64* pullTimestamp) GetChangeUnitChangeTime;
	}


	public HRESULT GetItemChangeTime(uint8* pbItemId, uint64* pullTimestamp) mut => VT.[Friend]GetItemChangeTime(&this, pbItemId, pullTimestamp);

	public HRESULT GetChangeUnitChangeTime(uint8* pbItemId, uint8* pbChangeUnitId, uint64* pullTimestamp) mut => VT.[Friend]GetChangeUnitChangeTime(&this, pbItemId, pbChangeUnitId, pullTimestamp);
}

[CRepr]struct IProviderConverter : IUnknown
{
	public new const Guid IID = .(0x809b7276, 0x98cf, 0x4957, 0x93, 0xa5, 0x0e, 0xbd, 0xd3, 0xdd, 0xdf, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncProvider* pISyncProvider) Initialize;
	}


	public HRESULT Initialize(ISyncProvider* pISyncProvider) mut => VT.[Friend]Initialize(&this, pISyncProvider);
}

[CRepr]struct ISyncDataConverter : IUnknown
{
	public new const Guid IID = .(0x435d4861, 0x68d5, 0x44aa, 0xa0, 0xf9, 0x72, 0xa0, 0xb0, 0x0e, 0xf9, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkDataRetrieverIn, IEnumSyncChanges* pEnumSyncChanges, IUnknown** ppUnkDataOut) ConvertDataRetrieverFromProviderFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkDataRetrieverIn, IEnumSyncChanges* pEnumSyncChanges, IUnknown** ppUnkDataOut) ConvertDataRetrieverToProviderFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILoadChangeContext* pDataContext, IUnknown* pUnkDataIn, IUnknown** ppUnkDataOut) ConvertDataFromProviderFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILoadChangeContext* pDataContext, IUnknown* pUnkDataOut, IUnknown** ppUnkDataout) ConvertDataToProviderFormat;
	}


	public HRESULT ConvertDataRetrieverFromProviderFormat(IUnknown* pUnkDataRetrieverIn, IEnumSyncChanges* pEnumSyncChanges, IUnknown** ppUnkDataOut) mut => VT.[Friend]ConvertDataRetrieverFromProviderFormat(&this, pUnkDataRetrieverIn, pEnumSyncChanges, ppUnkDataOut);

	public HRESULT ConvertDataRetrieverToProviderFormat(IUnknown* pUnkDataRetrieverIn, IEnumSyncChanges* pEnumSyncChanges, IUnknown** ppUnkDataOut) mut => VT.[Friend]ConvertDataRetrieverToProviderFormat(&this, pUnkDataRetrieverIn, pEnumSyncChanges, ppUnkDataOut);

	public HRESULT ConvertDataFromProviderFormat(ILoadChangeContext* pDataContext, IUnknown* pUnkDataIn, IUnknown** ppUnkDataOut) mut => VT.[Friend]ConvertDataFromProviderFormat(&this, pDataContext, pUnkDataIn, ppUnkDataOut);

	public HRESULT ConvertDataToProviderFormat(ILoadChangeContext* pDataContext, IUnknown* pUnkDataOut, IUnknown** ppUnkDataout) mut => VT.[Friend]ConvertDataToProviderFormat(&this, pDataContext, pUnkDataOut, ppUnkDataout);
}

[CRepr]struct ISyncProviderRegistration : IUnknown
{
	public new const Guid IID = .(0xcb45953b, 0x7624, 0x47bc, 0xa4, 0x72, 0xeb, 0x8c, 0xac, 0x6b, 0x22, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SyncProviderConfigUIConfiguration* pConfigUIConfig, ISyncProviderConfigUIInfo** ppConfigUIInfo) CreateSyncProviderConfigUIRegistrationInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId) UnregisterSyncProviderConfigUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContentType, uint32 dwSupportedArchitecture, IEnumSyncProviderConfigUIInfos** ppEnumSyncProviderConfigUIInfos) EnumerateSyncProviderConfigUIs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SyncProviderConfiguration* pProviderConfiguration, ISyncProviderInfo** ppProviderInfo) CreateSyncProviderRegistrationInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId) UnregisterSyncProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidProviderInstanceId, ISyncProviderConfigUIInfo** ppProviderConfigUIInfo) GetSyncProviderConfigUIInfoforProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContentType, uint32 dwStateFlagsToFilterMask, uint32 dwStateFlagsToFilter, in Guid refProviderClsId, uint32 dwSupportedArchitecture, IEnumSyncProviderInfos** ppEnumSyncProviderInfos) EnumerateSyncProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, ISyncProviderInfo** ppProviderInfo) GetSyncProviderInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, uint32 dwClsContext, IRegisteredSyncProvider** ppSyncProvider) GetSyncProviderFromInstanceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, ISyncProviderConfigUIInfo** ppConfigUIInfo) GetSyncProviderConfigUIInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, uint32 dwClsContext, ISyncProviderConfigUI** ppConfigUI) GetSyncProviderConfigUIFromInstanceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, uint32* pdwStateFlags) GetSyncProviderState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, uint32 dwStateFlagsMask, uint32 dwStateFlags) SetSyncProviderState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phEvent) RegisterForEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent) RevokeEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, ISyncRegistrationChange** ppChange) GetChange;
	}


	public HRESULT CreateSyncProviderConfigUIRegistrationInstance(SyncProviderConfigUIConfiguration* pConfigUIConfig, ISyncProviderConfigUIInfo** ppConfigUIInfo) mut => VT.[Friend]CreateSyncProviderConfigUIRegistrationInstance(&this, pConfigUIConfig, ppConfigUIInfo);

	public HRESULT UnregisterSyncProviderConfigUI(in Guid pguidInstanceId) mut => VT.[Friend]UnregisterSyncProviderConfigUI(&this, pguidInstanceId);

	public HRESULT EnumerateSyncProviderConfigUIs(Guid* pguidContentType, uint32 dwSupportedArchitecture, IEnumSyncProviderConfigUIInfos** ppEnumSyncProviderConfigUIInfos) mut => VT.[Friend]EnumerateSyncProviderConfigUIs(&this, pguidContentType, dwSupportedArchitecture, ppEnumSyncProviderConfigUIInfos);

	public HRESULT CreateSyncProviderRegistrationInstance(SyncProviderConfiguration* pProviderConfiguration, ISyncProviderInfo** ppProviderInfo) mut => VT.[Friend]CreateSyncProviderRegistrationInstance(&this, pProviderConfiguration, ppProviderInfo);

	public HRESULT UnregisterSyncProvider(in Guid pguidInstanceId) mut => VT.[Friend]UnregisterSyncProvider(&this, pguidInstanceId);

	public HRESULT GetSyncProviderConfigUIInfoforProvider(in Guid pguidProviderInstanceId, ISyncProviderConfigUIInfo** ppProviderConfigUIInfo) mut => VT.[Friend]GetSyncProviderConfigUIInfoforProvider(&this, pguidProviderInstanceId, ppProviderConfigUIInfo);

	public HRESULT EnumerateSyncProviders(Guid* pguidContentType, uint32 dwStateFlagsToFilterMask, uint32 dwStateFlagsToFilter, in Guid refProviderClsId, uint32 dwSupportedArchitecture, IEnumSyncProviderInfos** ppEnumSyncProviderInfos) mut => VT.[Friend]EnumerateSyncProviders(&this, pguidContentType, dwStateFlagsToFilterMask, dwStateFlagsToFilter, refProviderClsId, dwSupportedArchitecture, ppEnumSyncProviderInfos);

	public HRESULT GetSyncProviderInfo(in Guid pguidInstanceId, ISyncProviderInfo** ppProviderInfo) mut => VT.[Friend]GetSyncProviderInfo(&this, pguidInstanceId, ppProviderInfo);

	public HRESULT GetSyncProviderFromInstanceId(in Guid pguidInstanceId, uint32 dwClsContext, IRegisteredSyncProvider** ppSyncProvider) mut => VT.[Friend]GetSyncProviderFromInstanceId(&this, pguidInstanceId, dwClsContext, ppSyncProvider);

	public HRESULT GetSyncProviderConfigUIInfo(in Guid pguidInstanceId, ISyncProviderConfigUIInfo** ppConfigUIInfo) mut => VT.[Friend]GetSyncProviderConfigUIInfo(&this, pguidInstanceId, ppConfigUIInfo);

	public HRESULT GetSyncProviderConfigUIFromInstanceId(in Guid pguidInstanceId, uint32 dwClsContext, ISyncProviderConfigUI** ppConfigUI) mut => VT.[Friend]GetSyncProviderConfigUIFromInstanceId(&this, pguidInstanceId, dwClsContext, ppConfigUI);

	public HRESULT GetSyncProviderState(in Guid pguidInstanceId, uint32* pdwStateFlags) mut => VT.[Friend]GetSyncProviderState(&this, pguidInstanceId, pdwStateFlags);

	public HRESULT SetSyncProviderState(in Guid pguidInstanceId, uint32 dwStateFlagsMask, uint32 dwStateFlags) mut => VT.[Friend]SetSyncProviderState(&this, pguidInstanceId, dwStateFlagsMask, dwStateFlags);

	public HRESULT RegisterForEvent(HANDLE* phEvent) mut => VT.[Friend]RegisterForEvent(&this, phEvent);

	public HRESULT RevokeEvent(HANDLE hEvent) mut => VT.[Friend]RevokeEvent(&this, hEvent);

	public HRESULT GetChange(HANDLE hEvent, ISyncRegistrationChange** ppChange) mut => VT.[Friend]GetChange(&this, hEvent, ppChange);
}

[CRepr]struct IEnumSyncProviderConfigUIInfos : IUnknown
{
	public new const Guid IID = .(0xf6be2602, 0x17c6, 0x4658, 0xa2, 0xd7, 0x68, 0xed, 0x33, 0x30, 0xf6, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFactories, ISyncProviderConfigUIInfo** ppSyncProviderConfigUIInfo, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFactories) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncProviderConfigUIInfos** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cFactories, ISyncProviderConfigUIInfo** ppSyncProviderConfigUIInfo, uint32* pcFetched) mut => VT.[Friend]Next(&this, cFactories, ppSyncProviderConfigUIInfo, pcFetched);

	public HRESULT Skip(uint32 cFactories) mut => VT.[Friend]Skip(&this, cFactories);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncProviderConfigUIInfos** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IEnumSyncProviderInfos : IUnknown
{
	public new const Guid IID = .(0xa04ba850, 0x5eb1, 0x460d, 0xa9, 0x73, 0x39, 0x3f, 0xcb, 0x60, 0x8a, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cInstances, ISyncProviderInfo** ppSyncProviderInfo, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cInstances) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncProviderInfos** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cInstances, ISyncProviderInfo** ppSyncProviderInfo, uint32* pcFetched) mut => VT.[Friend]Next(&this, cInstances, ppSyncProviderInfo, pcFetched);

	public HRESULT Skip(uint32 cInstances) mut => VT.[Friend]Skip(&this, cInstances);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncProviderInfos** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct ISyncProviderInfo : IPropertyStore
{
	public new const Guid IID = .(0x1ee135de, 0x88a4, 0x4504, 0xb0, 0xd0, 0xf7, 0x92, 0x0d, 0x7e, 0x5b, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyStore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwClsContext, IRegisteredSyncProvider** ppSyncProvider) GetSyncProvider;
	}


	public HRESULT GetSyncProvider(uint32 dwClsContext, IRegisteredSyncProvider** ppSyncProvider) mut => VT.[Friend]GetSyncProvider(&this, dwClsContext, ppSyncProvider);
}

[CRepr]struct ISyncProviderConfigUIInfo : IPropertyStore
{
	public new const Guid IID = .(0x214141ae, 0x33d7, 0x4d8d, 0x8e, 0x37, 0xf2, 0x27, 0xe8, 0x80, 0xce, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyStore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwClsContext, ISyncProviderConfigUI** ppSyncProviderConfigUI) GetSyncProviderConfigUI;
	}


	public HRESULT GetSyncProviderConfigUI(uint32 dwClsContext, ISyncProviderConfigUI** ppSyncProviderConfigUI) mut => VT.[Friend]GetSyncProviderConfigUI(&this, dwClsContext, ppSyncProviderConfigUI);
}

[CRepr]struct ISyncProviderConfigUI : IUnknown
{
	public new const Guid IID = .(0x7b0705f6, 0xcbcd, 0x4071, 0xab, 0x05, 0x3b, 0xdc, 0x36, 0x4d, 0x4a, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, in Guid pguidContentType, IPropertyStore* pConfigurationProperties) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppConfigUIProperties) GetRegisteredProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IUnknown* pUnkContext, ISyncProviderInfo** ppProviderInfo) CreateAndRegisterNewSyncProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IUnknown* pUnkContext, ISyncProviderInfo* pProviderInfo) ModifySyncProvider;
	}


	public HRESULT Init(in Guid pguidInstanceId, in Guid pguidContentType, IPropertyStore* pConfigurationProperties) mut => VT.[Friend]Init(&this, pguidInstanceId, pguidContentType, pConfigurationProperties);

	public HRESULT GetRegisteredProperties(IPropertyStore** ppConfigUIProperties) mut => VT.[Friend]GetRegisteredProperties(&this, ppConfigUIProperties);

	public HRESULT CreateAndRegisterNewSyncProvider(HWND hwndParent, IUnknown* pUnkContext, ISyncProviderInfo** ppProviderInfo) mut => VT.[Friend]CreateAndRegisterNewSyncProvider(&this, hwndParent, pUnkContext, ppProviderInfo);

	public HRESULT ModifySyncProvider(HWND hwndParent, IUnknown* pUnkContext, ISyncProviderInfo* pProviderInfo) mut => VT.[Friend]ModifySyncProvider(&this, hwndParent, pUnkContext, pProviderInfo);
}

[CRepr]struct IRegisteredSyncProvider : IUnknown
{
	public new const Guid IID = .(0x913bcf76, 0x47c1, 0x40b5, 0xa8, 0x96, 0x5e, 0x8a, 0x9c, 0x41, 0x4c, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidInstanceId, in Guid pguidContentType, IPropertyStore* pContextPropertyStore) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidInstanceId) GetInstanceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT Init(in Guid pguidInstanceId, in Guid pguidContentType, IPropertyStore* pContextPropertyStore) mut => VT.[Friend]Init(&this, pguidInstanceId, pguidContentType, pContextPropertyStore);

	public HRESULT GetInstanceId(Guid* pguidInstanceId) mut => VT.[Friend]GetInstanceId(&this, pguidInstanceId);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct ISyncRegistrationChange : IUnknown
{
	public new const Guid IID = .(0xeea0d9ae, 0x6b29, 0x43b4, 0x9e, 0x70, 0xe3, 0xae, 0x33, 0xbb, 0x2c, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNC_REGISTRATION_EVENT* psreEvent) GetEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidInstanceId) GetInstanceId;
	}


	public HRESULT GetEvent(SYNC_REGISTRATION_EVENT* psreEvent) mut => VT.[Friend]GetEvent(&this, psreEvent);

	public HRESULT GetInstanceId(Guid* pguidInstanceId) mut => VT.[Friend]GetInstanceId(&this, pguidInstanceId);
}

#endregion
