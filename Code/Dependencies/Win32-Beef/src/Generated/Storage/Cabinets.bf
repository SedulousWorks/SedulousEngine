using Win32.Foundation;
using System;

namespace Win32.Storage.Cabinets;

#region Constants
public static
{
	public const uint32 INCLUDED_FCI = 1;
	public const uint32 _A_NAME_IS_UTF = 128;
	public const uint32 _A_EXEC = 64;
	public const uint32 statusFile = 0;
	public const uint32 statusFolder = 1;
	public const uint32 statusCabinet = 2;
	public const uint32 INCLUDED_TYPES_FCI_FDI = 1;
	public const int32 CB_MAX_DISK = 2147483647;
	public const uint32 CB_MAX_FILENAME = 256;
	public const uint32 CB_MAX_CABINET_NAME = 256;
	public const uint32 CB_MAX_CAB_PATH = 256;
	public const uint32 CB_MAX_DISK_NAME = 256;
	public const uint32 tcompMASK_TYPE = 15;
	public const uint32 tcompTYPE_NONE = 0;
	public const uint32 tcompTYPE_MSZIP = 1;
	public const uint32 tcompTYPE_QUANTUM = 2;
	public const uint32 tcompTYPE_LZX = 3;
	public const uint32 tcompBAD = 15;
	public const uint32 tcompMASK_LZX_WINDOW = 7936;
	public const uint32 tcompLZX_WINDOW_LO = 3840;
	public const uint32 tcompLZX_WINDOW_HI = 5376;
	public const uint32 tcompSHIFT_LZX_WINDOW = 8;
	public const uint32 tcompMASK_QUANTUM_LEVEL = 240;
	public const uint32 tcompQUANTUM_LEVEL_LO = 16;
	public const uint32 tcompQUANTUM_LEVEL_HI = 112;
	public const uint32 tcompSHIFT_QUANTUM_LEVEL = 4;
	public const uint32 tcompMASK_QUANTUM_MEM = 7936;
	public const uint32 tcompQUANTUM_MEM_LO = 2560;
	public const uint32 tcompQUANTUM_MEM_HI = 5376;
	public const uint32 tcompSHIFT_QUANTUM_MEM = 8;
	public const uint32 tcompMASK_RESERVED = 57344;
	public const uint32 INCLUDED_FDI = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum FDICREATE_CPU_TYPE : int32
{
	cpuUNKNOWN = -1,
	cpu80286 = 0,
	cpu80386 = 1,
}


[AllowDuplicates]
public enum FCIERROR : int32
{
	FCIERR_NONE = 0,
	FCIERR_OPEN_SRC = 1,
	FCIERR_READ_SRC = 2,
	FCIERR_ALLOC_FAIL = 3,
	FCIERR_TEMP_FILE = 4,
	FCIERR_BAD_COMPR_TYPE = 5,
	FCIERR_CAB_FILE = 6,
	FCIERR_USER_ABORT = 7,
	FCIERR_MCI_FAIL = 8,
	FCIERR_CAB_FORMAT_LIMIT = 9,
}


[AllowDuplicates]
public enum FDIERROR : int32
{
	FDIERROR_NONE = 0,
	FDIERROR_CABINET_NOT_FOUND = 1,
	FDIERROR_NOT_A_CABINET = 2,
	FDIERROR_UNKNOWN_CABINET_VERSION = 3,
	FDIERROR_CORRUPT_CABINET = 4,
	FDIERROR_ALLOC_FAIL = 5,
	FDIERROR_BAD_COMPR_TYPE = 6,
	FDIERROR_MDI_FAIL = 7,
	FDIERROR_TARGET_FILE = 8,
	FDIERROR_RESERVE_MISMATCH = 9,
	FDIERROR_WRONG_CABINET = 10,
	FDIERROR_USER_ABORT = 11,
	FDIERROR_EOF = 12,
}


[AllowDuplicates]
public enum FDIDECRYPTTYPE : int32
{
	fdidtNEW_CABINET = 0,
	fdidtNEW_FOLDER = 1,
	fdidtDECRYPT = 2,
}


[AllowDuplicates]
public enum FDINOTIFICATIONTYPE : int32
{
	fdintCABINET_INFO = 0,
	fdintPARTIAL_FILE = 1,
	fdintCOPY_FILE = 2,
	fdintCLOSE_FILE_INFO = 3,
	fdintNEXT_CABINET = 4,
	fdintENUMERATE = 5,
}

#endregion

#region Function Pointers
public function void* PFNFCIALLOC(uint32 cb);

public function void PFNFCIFREE(void* memory);

public function int PFNFCIOPEN(PSTR pszFile, int32 oflag, int32 pmode, int32* err, void* pv);

public function uint32 PFNFCIREAD(int hf, void* memory, uint32 cb, int32* err, void* pv);

public function uint32 PFNFCIWRITE(int hf, void* memory, uint32 cb, int32* err, void* pv);

public function int32 PFNFCICLOSE(int hf, int32* err, void* pv);

public function int32 PFNFCISEEK(int hf, int32 dist, int32 seektype, int32* err, void* pv);

public function int32 PFNFCIDELETE(PSTR pszFile, int32* err, void* pv);

public function BOOL PFNFCIGETNEXTCABINET(CCAB* pccab, uint32 cbPrevCab, void* pv);

public function int32 PFNFCIFILEPLACED(CCAB* pccab, PSTR pszFile, int32 cbFile, BOOL fContinuation, void* pv);

public function int PFNFCIGETOPENINFO(PSTR pszName, uint16* pdate, uint16* ptime, uint16* pattribs, int32* err, void* pv);

public function int32 PFNFCISTATUS(uint32 typeStatus, uint32 cb1, uint32 cb2, void* pv);

public function BOOL PFNFCIGETTEMPFILE(PSTR pszTempName, int32 cbTempName, void* pv);

public function void* PFNALLOC(uint32 cb);

public function void PFNFREE(void* pv);

public function int PFNOPEN(PSTR pszFile, int32 oflag, int32 pmode);

public function uint32 PFNREAD(int hf, void* pv, uint32 cb);

public function uint32 PFNWRITE(int hf, void* pv, uint32 cb);

public function int32 PFNCLOSE(int hf);

public function int32 PFNSEEK(int hf, int32 dist, int32 seektype);

public function int32 PFNFDIDECRYPT(FDIDECRYPT* pfdid);

public function int PFNFDINOTIFY(FDINOTIFICATIONTYPE fdint, FDINOTIFICATION* pfdin);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FDISPILLFILE
{
	public CHAR[2] ach;
	public int32 cbFile;
}
#endif

[CRepr]
public struct ERF
{
	public int32 erfOper;
	public int32 erfType;
	public BOOL fError;
}

[CRepr]
public struct CCAB
{
	public uint32 cb;
	public uint32 cbFolderThresh;
	public uint32 cbReserveCFHeader;
	public uint32 cbReserveCFFolder;
	public uint32 cbReserveCFData;
	public int32 iCab;
	public int32 iDisk;
	public int32 fFailOnIncompressible;
	public uint16 setID;
	public CHAR[256] szDisk;
	public CHAR[256] szCab;
	public CHAR[256] szCabPath;
}

[CRepr]
public struct FDICABINETINFO
{
	public int32 cbCabinet;
	public uint16 cFolders;
	public uint16 cFiles;
	public uint16 setID;
	public uint16 iCabinet;
	public BOOL fReserve;
	public BOOL hasprev;
	public BOOL hasnext;
}

[CRepr]
public struct FDIDECRYPT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _folder_e__Struct
		{
			public void* pFolderReserve;
			public uint16 cbFolderReserve;
			public uint16 iFolder;
		}
		[CRepr]
		public struct _cabinet_e__Struct
		{
			public void* pHeaderReserve;
			public uint16 cbHeaderReserve;
			public uint16 setID;
			public int32 iCabinet;
		}
		[CRepr]
		public struct _decrypt_e__Struct
		{
			public void* pDataReserve;
			public uint16 cbDataReserve;
			public void* pbData;
			public uint16 cbData;
			public BOOL fSplit;
			public uint16 cbPartial;
		}
		public _cabinet_e__Struct cabinet;
		public _folder_e__Struct folder;
		public _decrypt_e__Struct decrypt;
	}
	public FDIDECRYPTTYPE fdidt;
	public void* pvUser;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FDINOTIFICATION
{
	public int32 cb;
	public PSTR psz1;
	public PSTR psz2;
	public PSTR psz3;
	public void* pv;
	public int hf;
	public uint16 date;
	public uint16 time;
	public uint16 attribs;
	public uint16 setID;
	public uint16 iCabinet;
	public uint16 iFolder;
	public FDIERROR fdie;
}

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FDISPILLFILE
{
	public CHAR[2] ach;
	public int32 cbFile;
}
#endif

#endregion

#region Functions
public static
{
	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* FCICreate(ERF* perf, PFNFCIFILEPLACED pfnfcifp, PFNFCIALLOC pfna, PFNFCIFREE pfnf, PFNFCIOPEN pfnopen, PFNFCIREAD pfnread, PFNFCIWRITE pfnwrite, PFNFCICLOSE pfnclose, PFNFCISEEK pfnseek, PFNFCIDELETE pfndelete, PFNFCIGETTEMPFILE pfnfcigtf, CCAB* pccab, void* pv);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FCIAddFile(void* hfci, PSTR pszSourceFile, PSTR pszFileName, BOOL fExecute, PFNFCIGETNEXTCABINET pfnfcignc, PFNFCISTATUS pfnfcis, PFNFCIGETOPENINFO pfnfcigoi, uint16 typeCompress);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FCIFlushCabinet(void* hfci, BOOL fGetNextCab, PFNFCIGETNEXTCABINET pfnfcignc, PFNFCISTATUS pfnfcis);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FCIFlushFolder(void* hfci, PFNFCIGETNEXTCABINET pfnfcignc, PFNFCISTATUS pfnfcis);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FCIDestroy(void* hfci);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* FDICreate(PFNALLOC pfnalloc, PFNFREE pfnfree, PFNOPEN pfnopen, PFNREAD pfnread, PFNWRITE pfnwrite, PFNCLOSE pfnclose, PFNSEEK pfnseek, FDICREATE_CPU_TYPE cpuType, ERF* perf);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FDIIsCabinet(void* hfdi, int hf, FDICABINETINFO* pfdici);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FDICopy(void* hfdi, PSTR pszCabinet, PSTR pszCabPath, int32 flags, PFNFDINOTIFY pfnfdin, PFNFDIDECRYPT pfnfdid, void* pvUser);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FDIDestroy(void* hfdi);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FDITruncateCabinet(void* hfdi, PSTR pszCabinetName, uint16 iFolderToDelete);

}
#endregion
