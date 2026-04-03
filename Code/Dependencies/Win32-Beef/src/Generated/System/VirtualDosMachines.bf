using Win32.System.Kernel;
using Win32.Foundation;
using Win32.System.Diagnostics.Debug;
using System;

namespace Win32.System.VirtualDosMachines;

#region Constants
public static
{
	public const uint32 VDMCONTEXT_i386 = 65536;
	public const uint32 VDMCONTEXT_i486 = 65536;
	public const uint32 VDM_KGDT_R3_CODE = 24;
	public const uint32 VDM_MAXIMUM_SUPPORTED_EXTENSION = 512;
	public const uint32 V86FLAGS_CARRY = 1;
	public const uint32 V86FLAGS_PARITY = 4;
	public const uint32 V86FLAGS_AUXCARRY = 16;
	public const uint32 V86FLAGS_ZERO = 64;
	public const uint32 V86FLAGS_SIGN = 128;
	public const uint32 V86FLAGS_TRACE = 256;
	public const uint32 V86FLAGS_INTERRUPT = 512;
	public const uint32 V86FLAGS_DIRECTION = 1024;
	public const uint32 V86FLAGS_OVERFLOW = 2048;
	public const uint32 V86FLAGS_IOPL = 12288;
	public const uint32 V86FLAGS_IOPL_BITS = 18;
	public const uint32 V86FLAGS_RESUME = 65536;
	public const uint32 V86FLAGS_V86 = 131072;
	public const uint32 V86FLAGS_ALIGNMENT = 262144;
	public const int32 STATUS_VDM_EVENT = 1073741829;
	public const uint32 DBG_SEGLOAD = 0;
	public const uint32 DBG_SEGMOVE = 1;
	public const uint32 DBG_SEGFREE = 2;
	public const uint32 DBG_MODLOAD = 3;
	public const uint32 DBG_MODFREE = 4;
	public const uint32 DBG_SINGLESTEP = 5;
	public const uint32 DBG_BREAK = 6;
	public const uint32 DBG_GPFAULT = 7;
	public const uint32 DBG_DIVOVERFLOW = 8;
	public const uint32 DBG_INSTRFAULT = 9;
	public const uint32 DBG_TASKSTART = 10;
	public const uint32 DBG_TASKSTOP = 11;
	public const uint32 DBG_DLLSTART = 12;
	public const uint32 DBG_DLLSTOP = 13;
	public const uint32 DBG_ATTACH = 14;
	public const uint32 DBG_TOOLHELP = 15;
	public const uint32 DBG_STACKFAULT = 16;
	public const uint32 DBG_WOWINIT = 17;
	public const uint32 DBG_TEMPBP = 18;
	public const uint32 DBG_MODMOVE = 19;
	public const uint32 DBG_INIT = 20;
	public const uint32 DBG_GPFAULT2 = 21;
	public const uint32 VDMEVENT_NEEDS_INTERACTIVE = 32768;
	public const uint32 VDMEVENT_VERBOSE = 16384;
	public const uint32 VDMEVENT_PE = 8192;
	public const uint32 VDMEVENT_ALLFLAGS = 57344;
	public const uint32 VDMEVENT_V86 = 1;
	public const uint32 VDMEVENT_PM16 = 2;
	public const uint32 MAX_MODULE_NAME = 9;
	public const uint32 MAX_PATH16 = 255;
	public const uint32 SN_CODE = 0;
	public const uint32 SN_DATA = 1;
	public const uint32 SN_V86 = 2;
	public const uint32 GLOBAL_ALL = 0;
	public const uint32 GLOBAL_LRU = 1;
	public const uint32 GLOBAL_FREE = 2;
	public const uint32 GT_UNKNOWN = 0;
	public const uint32 GT_DGROUP = 1;
	public const uint32 GT_DATA = 2;
	public const uint32 GT_CODE = 3;
	public const uint32 GT_TASK = 4;
	public const uint32 GT_RESOURCE = 5;
	public const uint32 GT_MODULE = 6;
	public const uint32 GT_FREE = 7;
	public const uint32 GT_INTERNAL = 8;
	public const uint32 GT_SENTINEL = 9;
	public const uint32 GT_BURGERMASTER = 10;
	public const uint32 GD_USERDEFINED = 0;
	public const uint32 GD_CURSORCOMPONENT = 1;
	public const uint32 GD_BITMAP = 2;
	public const uint32 GD_ICONCOMPONENT = 3;
	public const uint32 GD_MENU = 4;
	public const uint32 GD_DIALOG = 5;
	public const uint32 GD_STRING = 6;
	public const uint32 GD_FONTDIR = 7;
	public const uint32 GD_FONT = 8;
	public const uint32 GD_ACCELERATORS = 9;
	public const uint32 GD_RCDATA = 10;
	public const uint32 GD_ERRTABLE = 11;
	public const uint32 GD_CURSOR = 12;
	public const uint32 GD_ICON = 14;
	public const uint32 GD_NAMETABLE = 15;
	public const uint32 GD_MAX_RESOURCE = 15;
	public const uint32 VDMDBG_BREAK_DOSTASK = 1;
	public const uint32 VDMDBG_BREAK_WOWTASK = 2;
	public const uint32 VDMDBG_BREAK_LOADDLL = 4;
	public const uint32 VDMDBG_BREAK_EXCEPTIONS = 8;
	public const uint32 VDMDBG_BREAK_DEBUGGER = 16;
	public const uint32 VDMDBG_TRACE_HISTORY = 128;
	public const uint32 VDMDBG_BREAK_DIVIDEBYZERO = 256;
	public const uint32 VDMDBG_INITIAL_FLAGS = 256;
	public const uint32 VDMDBG_MAX_SYMBOL_BUFFER = 256;
	public const uint32 VDMADDR_V86 = 2;
	public const uint32 VDMADDR_PM16 = 4;
	public const uint32 VDMADDR_PM32 = 16;
}
#endregion
#region Function Pointers
#if BF_64_BIT || BF_ARM_64
public function BOOL VDMGETTHREADSELECTORENTRYPROC(HANDLE param0, HANDLE param1, uint32 param2, VDMLDT_ENTRY* param3);
#endif

#if BF_64_BIT || BF_ARM_64
public function BOOL VDMGETCONTEXTPROC(HANDLE param0, HANDLE param1, VDMCONTEXT* param2);
#endif

#if BF_64_BIT || BF_ARM_64
public function BOOL VDMSETCONTEXTPROC(HANDLE param0, HANDLE param1, VDMCONTEXT* param2);
#endif

public function uint32 DEBUGEVENTPROC(DEBUG_EVENT* param0, void* param1);

public function BOOL PROCESSENUMPROC(uint32 dwProcessId, uint32 dwAttributes, LPARAM lpUserDefined);

public function BOOL TASKENUMPROC(uint32 dwThreadId, uint16 hMod16, uint16 hTask16, LPARAM lpUserDefined);

public function BOOL TASKENUMPROCEX(uint32 dwThreadId, uint16 hMod16, uint16 hTask16, int8* pszModName, int8* pszFileName, LPARAM lpUserDefined);

public function BOOL VDMPROCESSEXCEPTIONPROC(DEBUG_EVENT* param0);

#if BF_32_BIT
public function BOOL VDMGETTHREADSELECTORENTRYPROC(HANDLE param0, HANDLE param1, uint32 param2, LDT_ENTRY* param3);
#endif

public function uint32 VDMGETPOINTERPROC(HANDLE param0, HANDLE param1, uint16 param2, uint32 param3, BOOL param4);

#if BF_32_BIT
public function BOOL VDMGETCONTEXTPROC(HANDLE param0, HANDLE param1, CONTEXT* param2);
#endif

#if BF_32_BIT
public function BOOL VDMSETCONTEXTPROC(HANDLE param0, HANDLE param1, CONTEXT* param2);
#endif

public function BOOL VDMKILLWOWPROC();

public function BOOL VDMDETECTWOWPROC();

public function BOOL VDMBREAKTHREADPROC(HANDLE param0);

public function BOOL VDMGETSELECTORMODULEPROC(HANDLE param0, HANDLE param1, uint16 param2, uint32* param3, PSTR param4, uint32 param5, PSTR param6, uint32 param7);

public function BOOL VDMGETMODULESELECTORPROC(HANDLE param0, HANDLE param1, uint32 param2, PSTR param3, uint16* param4);

public function BOOL VDMMODULEFIRSTPROC(HANDLE param0, HANDLE param1, MODULEENTRY* param2, DEBUGEVENTPROC param3, void* param4);

public function BOOL VDMMODULENEXTPROC(HANDLE param0, HANDLE param1, MODULEENTRY* param2, DEBUGEVENTPROC param3, void* param4);

public function BOOL VDMGLOBALFIRSTPROC(HANDLE param0, HANDLE param1, GLOBALENTRY* param2, uint16 param3, DEBUGEVENTPROC param4, void* param5);

public function BOOL VDMGLOBALNEXTPROC(HANDLE param0, HANDLE param1, GLOBALENTRY* param2, uint16 param3, DEBUGEVENTPROC param4, void* param5);

public function int32 VDMENUMPROCESSWOWPROC(PROCESSENUMPROC param0, LPARAM param1);

public function int32 VDMENUMTASKWOWPROC(uint32 param0, TASKENUMPROC param1, LPARAM param2);

public function int32 VDMENUMTASKWOWEXPROC(uint32 param0, TASKENUMPROCEX param1, LPARAM param2);

public function BOOL VDMTERMINATETASKINWOWPROC(uint32 param0, uint16 param1);

public function BOOL VDMSTARTTASKINWOWPROC(uint32 param0, PSTR param1, uint16 param2);

public function uint32 VDMGETDBGFLAGSPROC(HANDLE param0);

public function BOOL VDMSETDBGFLAGSPROC(HANDLE param0, uint32 param1);

public function BOOL VDMISMODULELOADEDPROC(PSTR param0);

public function BOOL VDMGETSEGMENTINFOPROC(uint16 param0, uint32 param1, BOOL param2, VDM_SEGINFO param3);

public function BOOL VDMGETSYMBOLPROC(PSTR param0, uint16 param1, uint32 param2, BOOL param3, BOOL param4, uint8* param5, uint32* param6);

public function BOOL VDMGETADDREXPRESSIONPROC(PSTR param0, PSTR param1, uint16* param2, uint32* param3, uint16* param4);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct VDMCONTEXT
{
	public uint32 ContextFlags;
	public uint32 Dr0;
	public uint32 Dr1;
	public uint32 Dr2;
	public uint32 Dr3;
	public uint32 Dr6;
	public uint32 Dr7;
	public FLOATING_SAVE_AREA FloatSave;
	public uint32 SegGs;
	public uint32 SegFs;
	public uint32 SegEs;
	public uint32 SegDs;
	public uint32 Edi;
	public uint32 Esi;
	public uint32 Ebx;
	public uint32 Edx;
	public uint32 Ecx;
	public uint32 Eax;
	public uint32 Ebp;
	public uint32 Eip;
	public uint32 SegCs;
	public uint32 EFlags;
	public uint32 Esp;
	public uint32 SegSs;
	public uint8[512] ExtendedRegisters;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct VDMLDT_ENTRY
{
	[CRepr, Union]
	public struct _HighWord_e__Union
	{
		[CRepr]
		public struct _Bits_e__Struct
		{
			public uint32 _bitfield;
		}
		[CRepr]
		public struct _Bytes_e__Struct
		{
			public uint8 BaseMid;
			public uint8 Flags1;
			public uint8 Flags2;
			public uint8 BaseHi;
		}
		public _Bytes_e__Struct Bytes;
		public _Bits_e__Struct Bits;
	}
	public uint16 LimitLow;
	public uint16 BaseLow;
	public _HighWord_e__Union HighWord;
}
#endif

[CRepr]
public struct VDMCONTEXT_WITHOUT_XSAVE
{
	public uint32 ContextFlags;
	public uint32 Dr0;
	public uint32 Dr1;
	public uint32 Dr2;
	public uint32 Dr3;
	public uint32 Dr6;
	public uint32 Dr7;
	public FLOATING_SAVE_AREA FloatSave;
	public uint32 SegGs;
	public uint32 SegFs;
	public uint32 SegEs;
	public uint32 SegDs;
	public uint32 Edi;
	public uint32 Esi;
	public uint32 Ebx;
	public uint32 Edx;
	public uint32 Ecx;
	public uint32 Eax;
	public uint32 Ebp;
	public uint32 Eip;
	public uint32 SegCs;
	public uint32 EFlags;
	public uint32 Esp;
	public uint32 SegSs;
}

[CRepr]
public struct SEGMENT_NOTE
{
	public uint16 Selector1;
	public uint16 Selector2;
	public uint16 Segment;
	public CHAR[10] Module;
	public CHAR[256] FileName;
	public uint16 Type;
	public uint32 Length;
}

[CRepr]
public struct IMAGE_NOTE
{
	public CHAR[10] Module;
	public CHAR[256] FileName;
	public uint16 hModule;
	public uint16 hTask;
}

[CRepr, Packed(4)]
public struct MODULEENTRY
{
	public uint32 dwSize;
	public CHAR[10] szModule;
	public HANDLE hModule;
	public uint16 wcUsage;
	public CHAR[256] szExePath;
	public uint16 wNext;
}

[CRepr]
public struct TEMP_BP_NOTE
{
	public uint16 Seg;
	public uint32 Offset;
	public BOOL bPM;
}

[CRepr]
public struct VDM_SEGINFO
{
	public uint16 Selector;
	public uint16 SegNumber;
	public uint32 Length;
	public uint16 Type;
	public CHAR[9] ModuleName;
	public CHAR[255] FileName;
}

[CRepr, Packed(4)]
public struct GLOBALENTRY
{
	public uint32 dwSize;
	public uint32 dwAddress;
	public uint32 dwBlockSize;
	public HANDLE hBlock;
	public uint16 wcLock;
	public uint16 wcPageLock;
	public uint16 wFlags;
	public BOOL wHeapPresent;
	public HANDLE hOwner;
	public uint16 wType;
	public uint16 wData;
	public uint32 dwNext;
	public uint32 dwNextAlt;
}

#endregion
