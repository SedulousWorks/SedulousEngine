using Win32.System.Com;
using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.System.Com.StructuredStorage;

#region Constants
public static
{
	public const uint32 PROPSETFLAG_DEFAULT = 0;
	public const uint32 PROPSETFLAG_NONSIMPLE = 1;
	public const uint32 PROPSETFLAG_ANSI = 2;
	public const uint32 PROPSETFLAG_UNBUFFERED = 4;
	public const uint32 PROPSETFLAG_CASE_SENSITIVE = 8;
	public const uint32 PROPSET_BEHAVIOR_CASE_SENSITIVE = 1;
	public const uint32 PID_DICTIONARY = 0;
	public const uint32 PID_CODEPAGE = 1;
	public const uint32 PID_FIRST_USABLE = 2;
	public const uint32 PID_FIRST_NAME_DEFAULT = 4095;
	public const uint32 PID_LOCALE = 2147483648;
	public const uint32 PID_MODIFY_TIME = 2147483649;
	public const uint32 PID_SECURITY = 2147483650;
	public const uint32 PID_BEHAVIOR = 2147483651;
	public const uint32 PID_ILLEGAL = 4294967295;
	public const uint32 PID_MIN_READONLY = 2147483648;
	public const uint32 PID_MAX_READONLY = 3221225471;
	public const uint32 PRSPEC_INVALID = 4294967295;
	public const uint32 PROPSETHDR_OSVERSION_UNKNOWN = 4294967295;
	public const int32 PIDDI_THUMBNAIL = 2;
	public const int32 PIDSI_TITLE = 2;
	public const int32 PIDSI_SUBJECT = 3;
	public const int32 PIDSI_AUTHOR = 4;
	public const int32 PIDSI_KEYWORDS = 5;
	public const int32 PIDSI_COMMENTS = 6;
	public const int32 PIDSI_TEMPLATE = 7;
	public const int32 PIDSI_LASTAUTHOR = 8;
	public const int32 PIDSI_REVNUMBER = 9;
	public const int32 PIDSI_EDITTIME = 10;
	public const int32 PIDSI_LASTPRINTED = 11;
	public const int32 PIDSI_CREATE_DTM = 12;
	public const int32 PIDSI_LASTSAVE_DTM = 13;
	public const int32 PIDSI_PAGECOUNT = 14;
	public const int32 PIDSI_WORDCOUNT = 15;
	public const int32 PIDSI_CHARCOUNT = 16;
	public const int32 PIDSI_THUMBNAIL = 17;
	public const int32 PIDSI_APPNAME = 18;
	public const int32 PIDSI_DOC_SECURITY = 19;
	public const uint32 PIDDSI_CATEGORY = 2;
	public const uint32 PIDDSI_PRESFORMAT = 3;
	public const uint32 PIDDSI_BYTECOUNT = 4;
	public const uint32 PIDDSI_LINECOUNT = 5;
	public const uint32 PIDDSI_PARCOUNT = 6;
	public const uint32 PIDDSI_SLIDECOUNT = 7;
	public const uint32 PIDDSI_NOTECOUNT = 8;
	public const uint32 PIDDSI_HIDDENCOUNT = 9;
	public const uint32 PIDDSI_MMCLIPCOUNT = 10;
	public const uint32 PIDDSI_SCALE = 11;
	public const uint32 PIDDSI_HEADINGPAIR = 12;
	public const uint32 PIDDSI_DOCPARTS = 13;
	public const uint32 PIDDSI_MANAGER = 14;
	public const uint32 PIDDSI_COMPANY = 15;
	public const uint32 PIDDSI_LINKSDIRTY = 16;
	public const int32 PIDMSI_EDITOR = 2;
	public const int32 PIDMSI_SUPPLIER = 3;
	public const int32 PIDMSI_SOURCE = 4;
	public const int32 PIDMSI_SEQUENCE_NO = 5;
	public const int32 PIDMSI_PROJECT = 6;
	public const int32 PIDMSI_STATUS = 7;
	public const int32 PIDMSI_OWNER = 8;
	public const int32 PIDMSI_RATING = 9;
	public const int32 PIDMSI_PRODUCTION = 10;
	public const int32 PIDMSI_COPYRIGHT = 11;
	public const uint32 CWCSTORAGENAME = 32;
	public const uint32 STGOPTIONS_VERSION = 1;
	public const uint32 CCH_MAX_PROPSTG_NAME = 31;
}
#endregion

#region Enums

[AllowDuplicates]
public enum PROPSPEC_KIND : uint32
{
	PRSPEC_LPWSTR = 0,
	PRSPEC_PROPID = 1,
}


[AllowDuplicates]
public enum STGFMT : uint32
{
	STGFMT_STORAGE = 0,
	STGFMT_NATIVE = 1,
	STGFMT_FILE = 3,
	STGFMT_ANY = 4,
	STGFMT_DOCFILE = 5,
	STGFMT_DOCUMENT = 0,
}


[AllowDuplicates]
public enum STGMOVE : int32
{
	STGMOVE_MOVE = 0,
	STGMOVE_COPY = 1,
	STGMOVE_SHALLOWCOPY = 2,
}


[AllowDuplicates]
public enum PIDMSI_STATUS_VALUE : int32
{
	PIDMSI_STATUS_NORMAL = 0,
	PIDMSI_STATUS_NEW = 1,
	PIDMSI_STATUS_PRELIM = 2,
	PIDMSI_STATUS_DRAFT = 3,
	PIDMSI_STATUS_INPROGRESS = 4,
	PIDMSI_STATUS_EDIT = 5,
	PIDMSI_STATUS_REVIEW = 6,
	PIDMSI_STATUS_PROOF = 7,
	PIDMSI_STATUS_FINAL = 8,
	PIDMSI_STATUS_OTHER = 32767,
}

#endregion


#region Structs
[CRepr]
public struct BSTRBLOB
{
	public uint32 cbSize;
	public uint8* pData;
}

[CRepr]
public struct CLIPDATA
{
	public uint32 cbSize;
	public int32 ulClipFmt;
	public uint8* pClipData;
}

[CRepr]
public struct RemSNB
{
	public uint32 ulCntStr;
	public uint32 ulCntChar;
	public char16* rgString mut => &rgString_impl;
	private char16[ANYSIZE_ARRAY] rgString_impl;
}

[CRepr]
public struct VERSIONEDSTREAM
{
	public Guid guidVersion;
	public IStream* pStream;
}

[CRepr]
public struct CAC
{
	public uint32 cElems;
	public PSTR pElems;
}

[CRepr]
public struct CAUB
{
	public uint32 cElems;
	public uint8* pElems;
}

[CRepr]
public struct CAI
{
	public uint32 cElems;
	public int16* pElems;
}

[CRepr]
public struct CAUI
{
	public uint32 cElems;
	public uint16* pElems;
}

[CRepr]
public struct CAL
{
	public uint32 cElems;
	public int32* pElems;
}

[CRepr]
public struct CAUL
{
	public uint32 cElems;
	public uint32* pElems;
}

[CRepr]
public struct CAFLT
{
	public uint32 cElems;
	public float* pElems;
}

[CRepr]
public struct CADBL
{
	public uint32 cElems;
	public double* pElems;
}

[CRepr]
public struct CACY
{
	public uint32 cElems;
	public CY* pElems;
}

[CRepr]
public struct CADATE
{
	public uint32 cElems;
	public double* pElems;
}

[CRepr]
public struct CABSTR
{
	public uint32 cElems;
	public BSTR* pElems;
}

[CRepr]
public struct CABSTRBLOB
{
	public uint32 cElems;
	public BSTRBLOB* pElems;
}

[CRepr]
public struct CABOOL
{
	public uint32 cElems;
	public int16* pElems;
}

[CRepr]
public struct CASCODE
{
	public uint32 cElems;
	public int32* pElems;
}

[CRepr]
public struct CAPROPVARIANT
{
	public uint32 cElems;
	public PROPVARIANT* pElems;
}

[CRepr]
public struct CAH
{
	public uint32 cElems;
	public LARGE_INTEGER* pElems;
}

[CRepr]
public struct CAUH
{
	public uint32 cElems;
	public ULARGE_INTEGER* pElems;
}

[CRepr]
public struct CALPSTR
{
	public uint32 cElems;
	public PSTR* pElems;
}

[CRepr]
public struct CALPWSTR
{
	public uint32 cElems;
	public PWSTR* pElems;
}

[CRepr]
public struct CAFILETIME
{
	public uint32 cElems;
	public FILETIME* pElems;
}

[CRepr]
public struct CACLIPDATA
{
	public uint32 cElems;
	public CLIPDATA* pElems;
}

[CRepr]
public struct CACLSID
{
	public uint32 cElems;
	public Guid* pElems;
}

[CRepr]
public struct PROPVARIANT
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
				public CHAR cVal;
				public uint8 bVal;
				public int16 iVal;
				public uint16 uiVal;
				public int32 lVal;
				public uint32 ulVal;
				public int32 intVal;
				public uint32 uintVal;
				public LARGE_INTEGER hVal;
				public ULARGE_INTEGER uhVal;
				public float fltVal;
				public double dblVal;
				public int16 boolVal;
				public int16 __OBSOLETE__VARIANT_BOOL;
				public int32 scode;
				public CY cyVal;
				public double date;
				public FILETIME filetime;
				public Guid* puuid;
				public CLIPDATA* pclipdata;
				public BSTR bstrVal;
				public BSTRBLOB bstrblobVal;
				public BLOB blob;
				public PSTR pszVal;
				public PWSTR pwszVal;
				public IUnknown* punkVal;
				public IDispatch* pdispVal;
				public IStream* pStream;
				public IStorage* pStorage;
				public VERSIONEDSTREAM* pVersionedStream;
				public SAFEARRAY* parray;
				public CAC cac;
				public CAUB caub;
				public CAI cai;
				public CAUI caui;
				public CAL cal;
				public CAUL caul;
				public CAH cah;
				public CAUH cauh;
				public CAFLT caflt;
				public CADBL cadbl;
				public CABOOL cabool;
				public CASCODE cascode;
				public CACY cacy;
				public CADATE cadate;
				public CAFILETIME cafiletime;
				public CACLSID cauuid;
				public CACLIPDATA caclipdata;
				public CABSTR cabstr;
				public CABSTRBLOB cabstrblob;
				public CALPSTR calpstr;
				public CALPWSTR calpwstr;
				public CAPROPVARIANT capropvar;
				public PSTR pcVal;
				public uint8* pbVal;
				public int16* piVal;
				public uint16* puiVal;
				public int32* plVal;
				public uint32* pulVal;
				public int32* pintVal;
				public uint32* puintVal;
				public float* pfltVal;
				public double* pdblVal;
				public int16* pboolVal;
				public DECIMAL* pdecVal;
				public int32* pscode;
				public CY* pcyVal;
				public double* pdate;
				public BSTR* pbstrVal;
				public IUnknown** ppunkVal;
				public IDispatch** ppdispVal;
				public SAFEARRAY** pparray;
				public PROPVARIANT* pvarVal;
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
public struct PROPSPEC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 propid;
		public PWSTR lpwstr;
	}
	public PROPSPEC_KIND ulKind;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct STATPROPSTG
{
	public PWSTR lpwstrName;
	public uint32 propid;
	public VARENUM vt;
}

[CRepr]
public struct STATPROPSETSTG
{
	public Guid fmtid;
	public Guid clsid;
	public uint32 grfFlags;
	public FILETIME mtime;
	public FILETIME ctime;
	public FILETIME atime;
	public uint32 dwOSVersion;
}

[CRepr]
public struct STGOPTIONS
{
	public uint16 usVersion;
	public uint16 reserved;
	public uint32 ulSectorSize;
	public PWSTR pwcsTemplateFile;
}

[CRepr]
public struct SERIALIZEDPROPERTYVALUE
{
	public uint32 dwType;
	public uint8* rgb mut => &rgb_impl;
	private uint8[ANYSIZE_ARRAY] rgb_impl;
}

[CRepr]
public struct PMemoryAllocator
{
}

[CRepr]
public struct OLESTREAMVTBL
{
	public int Get;
	public int Put;
}

[CRepr]
public struct OLESTREAM
{
	public OLESTREAMVTBL* lpstbl;
}

[CRepr]
public struct PROPBAG2
{
	public uint32 dwType;
	public VARENUM vt;
	public uint16 cfType;
	public uint32 dwHint;
	public PWSTR pstrName;
	public Guid clsid;
}

#endregion

#region COM Types
[CRepr]struct IEnumSTATSTG : IUnknown
{
	public new const Guid IID = .(0x0000000d, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, STATSTG* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATSTG** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, STATSTG* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSTATSTG** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IStorage : IUnknown
{
	public new const Guid IID = .(0x0000000b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, STGM grfMode, uint32 reserved1, uint32 reserved2, IStream** ppstm) CreateStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, void* reserved1, STGM grfMode, uint32 reserved2, IStream** ppstm) OpenStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, STGM grfMode, uint32 reserved1, uint32 reserved2, IStorage** ppstg) CreateStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, IStorage* pstgPriority, STGM grfMode, uint16** snbExclude, uint32 reserved, IStorage** ppstg) OpenStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ciidExclude, Guid* rgiidExclude, uint16** snbExclude, IStorage* pstgDest) CopyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, IStorage* pstgDest, PWSTR pwcsNewName, STGMOVE grfFlags) MoveElementTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STGC grfCommitFlags) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Revert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 reserved1, void* reserved2, uint32 reserved3, IEnumSTATSTG** ppenum) EnumElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName) DestroyElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsOldName, PWSTR pwcsNewName) RenameElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsName, FILETIME* pctime, FILETIME* patime, FILETIME* pmtime) SetElementTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) SetClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfStateBits, uint32 grfMask) SetStateBits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STATSTG* pstatstg, STATFLAG grfStatFlag) Stat;
	}


	public HRESULT CreateStream(PWSTR pwcsName, STGM grfMode, uint32 reserved1, uint32 reserved2, IStream** ppstm) mut => VT.[Friend]CreateStream(&this, pwcsName, grfMode, reserved1, reserved2, ppstm);

	public HRESULT OpenStream(PWSTR pwcsName, void* reserved1, STGM grfMode, uint32 reserved2, IStream** ppstm) mut => VT.[Friend]OpenStream(&this, pwcsName, reserved1, grfMode, reserved2, ppstm);

	public HRESULT CreateStorage(PWSTR pwcsName, STGM grfMode, uint32 reserved1, uint32 reserved2, IStorage** ppstg) mut => VT.[Friend]CreateStorage(&this, pwcsName, grfMode, reserved1, reserved2, ppstg);

	public HRESULT OpenStorage(PWSTR pwcsName, IStorage* pstgPriority, STGM grfMode, uint16** snbExclude, uint32 reserved, IStorage** ppstg) mut => VT.[Friend]OpenStorage(&this, pwcsName, pstgPriority, grfMode, snbExclude, reserved, ppstg);

	public HRESULT CopyTo(uint32 ciidExclude, Guid* rgiidExclude, uint16** snbExclude, IStorage* pstgDest) mut => VT.[Friend]CopyTo(&this, ciidExclude, rgiidExclude, snbExclude, pstgDest);

	public HRESULT MoveElementTo(PWSTR pwcsName, IStorage* pstgDest, PWSTR pwcsNewName, STGMOVE grfFlags) mut => VT.[Friend]MoveElementTo(&this, pwcsName, pstgDest, pwcsNewName, grfFlags);

	public HRESULT Commit(STGC grfCommitFlags) mut => VT.[Friend]Commit(&this, grfCommitFlags);

	public HRESULT Revert() mut => VT.[Friend]Revert(&this);

	public HRESULT EnumElements(uint32 reserved1, void* reserved2, uint32 reserved3, IEnumSTATSTG** ppenum) mut => VT.[Friend]EnumElements(&this, reserved1, reserved2, reserved3, ppenum);

	public HRESULT DestroyElement(PWSTR pwcsName) mut => VT.[Friend]DestroyElement(&this, pwcsName);

	public HRESULT RenameElement(PWSTR pwcsOldName, PWSTR pwcsNewName) mut => VT.[Friend]RenameElement(&this, pwcsOldName, pwcsNewName);

	public HRESULT SetElementTimes(PWSTR pwcsName, FILETIME* pctime, FILETIME* patime, FILETIME* pmtime) mut => VT.[Friend]SetElementTimes(&this, pwcsName, pctime, patime, pmtime);

	public HRESULT SetClass(in Guid clsid) mut => VT.[Friend]SetClass(&this, clsid);

	public HRESULT SetStateBits(uint32 grfStateBits, uint32 grfMask) mut => VT.[Friend]SetStateBits(&this, grfStateBits, grfMask);

	public HRESULT Stat(STATSTG* pstatstg, STATFLAG grfStatFlag) mut => VT.[Friend]Stat(&this, pstatstg, grfStatFlag);
}

[CRepr]struct IPersistStorage : IPersist
{
	public new const Guid IID = .(0x0000010a, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStg) InitNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStg) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStgSave, BOOL fSameAsLoad) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStgNew) SaveCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) HandsOffStorage;
	}


	public HRESULT IsDirty() mut => VT.[Friend]IsDirty(&this);

	public HRESULT InitNew(IStorage* pStg) mut => VT.[Friend]InitNew(&this, pStg);

	public HRESULT Load(IStorage* pStg) mut => VT.[Friend]Load(&this, pStg);

	public HRESULT Save(IStorage* pStgSave, BOOL fSameAsLoad) mut => VT.[Friend]Save(&this, pStgSave, fSameAsLoad);

	public HRESULT SaveCompleted(IStorage* pStgNew) mut => VT.[Friend]SaveCompleted(&this, pStgNew);

	public HRESULT HandsOffStorage() mut => VT.[Friend]HandsOffStorage(&this);
}

[CRepr]struct ILockBytes : IUnknown
{
	public new const Guid IID = .(0x0000000a, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER ulOffset, void* pv, uint32 cb, uint32* pcbRead) ReadAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER ulOffset, void* pv, uint32 cb, uint32* pcbWritten) WriteAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER cb) SetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, LOCKTYPE dwLockType) LockRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, uint32 dwLockType) UnlockRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STATSTG* pstatstg, STATFLAG grfStatFlag) Stat;
	}


	public HRESULT ReadAt(ULARGE_INTEGER ulOffset, void* pv, uint32 cb, uint32* pcbRead) mut => VT.[Friend]ReadAt(&this, ulOffset, pv, cb, pcbRead);

	public HRESULT WriteAt(ULARGE_INTEGER ulOffset, void* pv, uint32 cb, uint32* pcbWritten) mut => VT.[Friend]WriteAt(&this, ulOffset, pv, cb, pcbWritten);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);

	public HRESULT SetSize(ULARGE_INTEGER cb) mut => VT.[Friend]SetSize(&this, cb);

	public HRESULT LockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, LOCKTYPE dwLockType) mut => VT.[Friend]LockRegion(&this, libOffset, cb, dwLockType);

	public HRESULT UnlockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, uint32 dwLockType) mut => VT.[Friend]UnlockRegion(&this, libOffset, cb, dwLockType);

	public HRESULT Stat(STATSTG* pstatstg, STATFLAG grfStatFlag) mut => VT.[Friend]Stat(&this, pstatstg, grfStatFlag);
}

[CRepr]struct IRootStorage : IUnknown
{
	public new const Guid IID = .(0x00000012, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile) SwitchToFile;
	}


	public HRESULT SwitchToFile(PWSTR pszFile) mut => VT.[Friend]SwitchToFile(&this, pszFile);
}

[CRepr]struct IFillLockBytes : IUnknown
{
	public new const Guid IID = .(0x99caf010, 0x415e, 0x11cf, 0x88, 0x14, 0x00, 0xaa, 0x00, 0xb5, 0x69, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pv, uint32 cb, uint32* pcbWritten) FillAppend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER ulOffset, void* pv, uint32 cb, uint32* pcbWritten) FillAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER ulSize) SetFillSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bCanceled) Terminate;
	}


	public HRESULT FillAppend(void* pv, uint32 cb, uint32* pcbWritten) mut => VT.[Friend]FillAppend(&this, pv, cb, pcbWritten);

	public HRESULT FillAt(ULARGE_INTEGER ulOffset, void* pv, uint32 cb, uint32* pcbWritten) mut => VT.[Friend]FillAt(&this, ulOffset, pv, cb, pcbWritten);

	public HRESULT SetFillSize(ULARGE_INTEGER ulSize) mut => VT.[Friend]SetFillSize(&this, ulSize);

	public HRESULT Terminate(BOOL bCanceled) mut => VT.[Friend]Terminate(&this, bCanceled);
}

[CRepr]struct ILayoutStorage : IUnknown
{
	public new const Guid IID = .(0x0e6d4d90, 0x6738, 0x11cf, 0x96, 0x08, 0x00, 0xaa, 0x00, 0x68, 0x0d, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, StorageLayout* pStorageLayout, uint32 nEntries, uint32 glfInterleavedFlag) LayoutScript;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginMonitor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndMonitor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwcsNewDfName) ReLayoutDocfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILockBytes* pILockBytes) ReLayoutDocfileOnILockBytes;
	}


	public HRESULT LayoutScript(StorageLayout* pStorageLayout, uint32 nEntries, uint32 glfInterleavedFlag) mut => VT.[Friend]LayoutScript(&this, pStorageLayout, nEntries, glfInterleavedFlag);

	public HRESULT BeginMonitor() mut => VT.[Friend]BeginMonitor(&this);

	public HRESULT EndMonitor() mut => VT.[Friend]EndMonitor(&this);

	public HRESULT ReLayoutDocfile(PWSTR pwcsNewDfName) mut => VT.[Friend]ReLayoutDocfile(&this, pwcsNewDfName);

	public HRESULT ReLayoutDocfileOnILockBytes(ILockBytes* pILockBytes) mut => VT.[Friend]ReLayoutDocfileOnILockBytes(&this, pILockBytes);
}

[CRepr]struct IDirectWriterLock : IUnknown
{
	public new const Guid IID = .(0x0e6d4d92, 0x6738, 0x11cf, 0x96, 0x08, 0x00, 0xaa, 0x00, 0x68, 0x0d, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTimeout) WaitForWriteAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseWriteAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) HaveWriteAccess;
	}


	public HRESULT WaitForWriteAccess(uint32 dwTimeout) mut => VT.[Friend]WaitForWriteAccess(&this, dwTimeout);

	public HRESULT ReleaseWriteAccess() mut => VT.[Friend]ReleaseWriteAccess(&this);

	public HRESULT HaveWriteAccess() mut => VT.[Friend]HaveWriteAccess(&this);
}

[CRepr]struct IPropertyStorage : IUnknown
{
	public new const Guid IID = .(0x00000138, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar) ReadMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar, uint32 propidNameFirst) WriteMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec) DeleteMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) ReadPropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) WritePropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpropid, uint32* rgpropid) DeletePropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfCommitFlags) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Revert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATPROPSTG** ppenum) Enum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pctime, FILETIME* patime, FILETIME* pmtime) SetTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) SetClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STATPROPSETSTG* pstatpsstg) Stat;
	}


	public HRESULT ReadMultiple(uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar) mut => VT.[Friend]ReadMultiple(&this, cpspec, rgpspec, rgpropvar);

	public HRESULT WriteMultiple(uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar, uint32 propidNameFirst) mut => VT.[Friend]WriteMultiple(&this, cpspec, rgpspec, rgpropvar, propidNameFirst);

	public HRESULT DeleteMultiple(uint32 cpspec, PROPSPEC* rgpspec) mut => VT.[Friend]DeleteMultiple(&this, cpspec, rgpspec);

	public HRESULT ReadPropertyNames(uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) mut => VT.[Friend]ReadPropertyNames(&this, cpropid, rgpropid, rglpwstrName);

	public HRESULT WritePropertyNames(uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) mut => VT.[Friend]WritePropertyNames(&this, cpropid, rgpropid, rglpwstrName);

	public HRESULT DeletePropertyNames(uint32 cpropid, uint32* rgpropid) mut => VT.[Friend]DeletePropertyNames(&this, cpropid, rgpropid);

	public HRESULT Commit(uint32 grfCommitFlags) mut => VT.[Friend]Commit(&this, grfCommitFlags);

	public HRESULT Revert() mut => VT.[Friend]Revert(&this);

	public HRESULT Enum(IEnumSTATPROPSTG** ppenum) mut => VT.[Friend]Enum(&this, ppenum);

	public HRESULT SetTimes(FILETIME* pctime, FILETIME* patime, FILETIME* pmtime) mut => VT.[Friend]SetTimes(&this, pctime, patime, pmtime);

	public HRESULT SetClass(in Guid clsid) mut => VT.[Friend]SetClass(&this, clsid);

	public HRESULT Stat(STATPROPSETSTG* pstatpsstg) mut => VT.[Friend]Stat(&this, pstatpsstg);
}

[CRepr]struct IPropertySetStorage : IUnknown
{
	public new const Guid IID = .(0x0000013a, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfmtid, in Guid pclsid, uint32 grfFlags, uint32 grfMode, IPropertyStorage** ppprstg) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfmtid, uint32 grfMode, IPropertyStorage** ppprstg) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfmtid) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATPROPSETSTG** ppenum) Enum;
	}


	public HRESULT Create(in Guid rfmtid, in Guid pclsid, uint32 grfFlags, uint32 grfMode, IPropertyStorage** ppprstg) mut => VT.[Friend]Create(&this, rfmtid, pclsid, grfFlags, grfMode, ppprstg);

	public HRESULT Open(in Guid rfmtid, uint32 grfMode, IPropertyStorage** ppprstg) mut => VT.[Friend]Open(&this, rfmtid, grfMode, ppprstg);

	public HRESULT Delete(in Guid rfmtid) mut => VT.[Friend]Delete(&this, rfmtid);

	public HRESULT Enum(IEnumSTATPROPSETSTG** ppenum) mut => VT.[Friend]Enum(&this, ppenum);
}

[CRepr]struct IEnumSTATPROPSTG : IUnknown
{
	public new const Guid IID = .(0x00000139, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, STATPROPSTG* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATPROPSTG** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, STATPROPSTG* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSTATPROPSTG** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumSTATPROPSETSTG : IUnknown
{
	public new const Guid IID = .(0x0000013b, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, STATPROPSETSTG* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATPROPSETSTG** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, STATPROPSETSTG* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSTATPROPSETSTG** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IPropertyBag : IUnknown
{
	public new const Guid IID = .(0x55272a00, 0x42cb, 0x11ce, 0x81, 0x35, 0x00, 0xaa, 0x00, 0x4b, 0xb8, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropName, VARIANT* pVar, IErrorLog* pErrorLog) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropName, VARIANT* pVar) Write;
	}


	public HRESULT Read(PWSTR pszPropName, VARIANT* pVar, IErrorLog* pErrorLog) mut => VT.[Friend]Read(&this, pszPropName, pVar, pErrorLog);

	public HRESULT Write(PWSTR pszPropName, VARIANT* pVar) mut => VT.[Friend]Write(&this, pszPropName, pVar);
}

[CRepr]struct IPropertyBag2 : IUnknown
{
	public new const Guid IID = .(0x22f55882, 0x280b, 0x11d0, 0xa8, 0xa9, 0x00, 0xa0, 0xc9, 0x0c, 0x20, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cProperties, PROPBAG2* pPropBag, IErrorLog* pErrLog, VARIANT* pvarValue, HRESULT* phrError) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cProperties, PROPBAG2* pPropBag, VARIANT* pvarValue) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcProperties) CountProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iProperty, uint32 cProperties, PROPBAG2* pPropBag, uint32* pcProperties) GetPropertyInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pstrName, uint32 dwHint, IUnknown* pUnkObject, IErrorLog* pErrLog) LoadObject;
	}


	public HRESULT Read(uint32 cProperties, PROPBAG2* pPropBag, IErrorLog* pErrLog, VARIANT* pvarValue, HRESULT* phrError) mut => VT.[Friend]Read(&this, cProperties, pPropBag, pErrLog, pvarValue, phrError);

	public HRESULT Write(uint32 cProperties, PROPBAG2* pPropBag, VARIANT* pvarValue) mut => VT.[Friend]Write(&this, cProperties, pPropBag, pvarValue);

	public HRESULT CountProperties(uint32* pcProperties) mut => VT.[Friend]CountProperties(&this, pcProperties);

	public HRESULT GetPropertyInfo(uint32 iProperty, uint32 cProperties, PROPBAG2* pPropBag, uint32* pcProperties) mut => VT.[Friend]GetPropertyInfo(&this, iProperty, cProperties, pPropBag, pcProperties);

	public HRESULT LoadObject(PWSTR pstrName, uint32 dwHint, IUnknown* pUnkObject, IErrorLog* pErrLog) mut => VT.[Friend]LoadObject(&this, pstrName, dwHint, pUnkObject, pErrLog);
}

#endregion

#region Functions
public static
{
	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetInstanceFromFile(COSERVERINFO* pServerInfo, Guid* pClsid, IUnknown* punkOuter, CLSCTX dwClsCtx, uint32 grfMode, PWSTR pwszName, uint32 dwCount, MULTI_QI* pResults);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetInstanceFromIStorage(COSERVERINFO* pServerInfo, Guid* pClsid, IUnknown* punkOuter, CLSCTX dwClsCtx, IStorage* pstg, uint32 dwCount, MULTI_QI* pResults);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgOpenAsyncDocfileOnIFillLockBytes(IFillLockBytes* pflb, uint32 grfMode, uint32 asyncFlags, IStorage** ppstgOpen);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgGetIFillLockBytesOnILockBytes(ILockBytes* pilb, IFillLockBytes** ppflb);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgGetIFillLockBytesOnFile(PWSTR pwcsName, IFillLockBytes** ppflb);

	[Import("dflayout.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgOpenLayoutDocfile(PWSTR pwcsDfName, uint32 grfMode, uint32 reserved, IStorage** ppstgOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateStreamOnHGlobal(int hGlobal, BOOL fDeleteOnRelease, IStream** ppstm);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetHGlobalFromStream(IStream* pstm, int* phglobal);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CoGetInterfaceAndReleaseStream(IStream* pStm, in Guid iid, void** ppv);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantCopy(PROPVARIANT* pvarDest, PROPVARIANT* pvarSrc);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropVariantClear(PROPVARIANT* pvar);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FreePropVariantArray(uint32 cVariants, PROPVARIANT* rgvars);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgCreateDocfile(PWSTR pwcsName, STGM grfMode, uint32 reserved, IStorage** ppstgOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgCreateDocfileOnILockBytes(ILockBytes* plkbyt, STGM grfMode, uint32 reserved, IStorage** ppstgOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgOpenStorage(PWSTR pwcsName, IStorage* pstgPriority, STGM grfMode, uint16** snbExclude, uint32 reserved, IStorage** ppstgOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgOpenStorageOnILockBytes(ILockBytes* plkbyt, IStorage* pstgPriority, STGM grfMode, uint16** snbExclude, uint32 reserved, IStorage** ppstgOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgIsStorageFile(PWSTR pwcsName);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgIsStorageILockBytes(ILockBytes* plkbyt);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgSetTimes(PWSTR lpszName, FILETIME* pctime, FILETIME* patime, FILETIME* pmtime);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgCreateStorageEx(PWSTR pwcsName, STGM grfMode, STGFMT stgfmt, uint32 grfAttrs, STGOPTIONS* pStgOptions, PSECURITY_DESCRIPTOR pSecurityDescriptor, in Guid riid, void** ppObjectOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgOpenStorageEx(PWSTR pwcsName, STGM grfMode, STGFMT stgfmt, uint32 grfAttrs, STGOPTIONS* pStgOptions, PSECURITY_DESCRIPTOR pSecurityDescriptor, in Guid riid, void** ppObjectOpen);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgCreatePropStg(IUnknown* pUnk, in Guid fmtid, in Guid pclsid, uint32 grfFlags, uint32 dwReserved, IPropertyStorage** ppPropStg);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgOpenPropStg(IUnknown* pUnk, in Guid fmtid, uint32 grfFlags, uint32 dwReserved, IPropertyStorage** ppPropStg);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgCreatePropSetStg(IStorage* pStorage, uint32 dwReserved, IPropertySetStorage** ppPropSetStg);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FmtIdToPropStgName(in Guid pfmtid, PWSTR oszName);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PropStgNameToFmtId(PWSTR oszName, Guid* pfmtid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReadClassStg(IStorage* pStg, Guid* pclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WriteClassStg(IStorage* pStg, in Guid rclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReadClassStm(IStream* pStm, Guid* pclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WriteClassStm(IStream* pStm, in Guid rclsid);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetHGlobalFromILockBytes(ILockBytes* plkbyt, int* phglobal);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateILockBytesOnHGlobal(int hGlobal, BOOL fDeleteOnRelease, ILockBytes** pplkbyt);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetConvertStg(IStorage* pStg);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SERIALIZEDPROPERTYVALUE* StgConvertVariantToProperty(PROPVARIANT* pvar, uint16 CodePage, SERIALIZEDPROPERTYVALUE* pprop, uint32* pcb, uint32 pid, BOOLEAN fReserved, uint32* pcIndirect);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN StgConvertPropertyToVariant(SERIALIZEDPROPERTYVALUE* pprop, uint16 CodePage, PROPVARIANT* pvar, PMemoryAllocator* pma);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 StgPropertyLengthAsVariant(SERIALIZEDPROPERTYVALUE* pProp, uint32 cbProp, uint16 CodePage, uint8 bReserved);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WriteFmtUserTypeStg(IStorage* pstg, uint16 cf, PWSTR lpszUserType);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReadFmtUserTypeStg(IStorage* pstg, uint16* pcf, PWSTR* lplpszUserType);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleConvertOLESTREAMToIStorage(OLESTREAM* lpolestream, IStorage* pstg, DVTARGETDEVICE* ptd);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleConvertIStorageToOLESTREAM(IStorage* pstg, OLESTREAM* lpolestream);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetConvertStg(IStorage* pStg, BOOL fConvert);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleConvertIStorageToOLESTREAMEx(IStorage* pstg, uint16 cfFormat, int32 lWidth, int32 lHeight, uint32 dwSize, STGMEDIUM* pmedium, OLESTREAM* polestm);

	[Import("ole32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleConvertOLESTREAMToIStorageEx(OLESTREAM* polestm, IStorage* pstg, uint16* pcfFormat, int32* plwWidth, int32* plHeight, uint32* pdwSize, STGMEDIUM* pmedium);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgSerializePropVariant(PROPVARIANT* ppropvar, SERIALIZEDPROPERTYVALUE** ppProp, uint32* pcb);

	[Import("PROPSYS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgDeserializePropVariant(SERIALIZEDPROPERTYVALUE* pprop, uint32 cbMax, PROPVARIANT* ppropvar);

}
#endregion
