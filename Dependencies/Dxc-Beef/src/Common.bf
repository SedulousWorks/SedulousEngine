using System;
namespace Dxc_Beef
{
	[AllowDuplicates]
	enum DXC_CP
	{
		// For convenience, equivalent definitions to CP_UTF8 and CP_UTF16.
		DXC_CP_UTF8 = 65001,
		DXC_CP_UTF16 = 1200,
		DXC_CP_UTF32 = 12000,
		// Use DXC_CP_ACP for: Binary;  ANSI Text;  Autodetect UTF with BOM
		DXC_CP_ACP = 0,

		/// Codepage for "wide" characters - UTF16 on Windows, UTF32 on other platforms.
#if BF_PLATFORM_WINDOWS
		DXC_CP_WIDE = DXC_CP_UTF16,
#else
		DXC_CP_WIDE = DXC_CP_UTF32,
#endif
	}

	enum HRESULT : int32
	{
		S_OK = 0,
		S_FALSE = 1,
	}

	typealias PWSTR = char16*;

	[CRepr]
	public struct FILETIME
	{
		public uint32 dwLowDateTime;
		public uint32 dwHighDateTime;
	}

	[AllowDuplicates]
	public enum LOCKTYPE : int32
	{
		LOCK_WRITE = 1,
		LOCK_EXCLUSIVE = 2,
		LOCK_ONLYONCE = 4,
	}

	[AllowDuplicates]
	public enum STGM : uint32
	{
		STGM_DIRECT = 0,
		STGM_TRANSACTED = 65536,
		STGM_SIMPLE = 134217728,
		STGM_READ = 0,
		STGM_WRITE = 1,
		STGM_READWRITE = 2,
		STGM_SHARE_DENY_NONE = 64,
		STGM_SHARE_DENY_READ = 48,
		STGM_SHARE_DENY_WRITE = 32,
		STGM_SHARE_EXCLUSIVE = 16,
		STGM_PRIORITY = 262144,
		STGM_DELETEONRELEASE = 67108864,
		STGM_NOSCRATCH = 1048576,
		STGM_CREATE = 4096,
		STGM_CONVERT = 131072,
		STGM_FAILIFTHERE = 0,
		STGM_NOSNAPSHOT = 2097152,
		STGM_DIRECT_SWMR = 4194304,
	}

	[AllowDuplicates]
	public enum STGC : uint32
	{
		STGC_DEFAULT = 0,
		STGC_OVERWRITE = 1,
		STGC_ONLYIFCURRENT = 2,
		STGC_DANGEROUSLYCOMMITMERELYTODISKCACHE = 4,
		STGC_CONSOLIDATE = 8,
	}

	[CRepr]
	public struct STATSTG
	{
		public PWSTR pwcsName;
		public uint32 type;
		public ULARGE_INTEGER cbSize;
		public FILETIME mtime;
		public FILETIME ctime;
		public FILETIME atime;
		public STGM grfMode;
		public LOCKTYPE grfLocksSupported;
		public Guid clsid;
		public uint32 grfStateBits;
		public uint32 reserved;
	}

	[AllowDuplicates]
	public enum STATFLAG : int32
	{
		STATFLAG_DEFAULT = 0,
		STATFLAG_NONAME = 1,
		STATFLAG_NOOPEN = 2,
	}

	[AllowDuplicates]
	public enum STREAM_SEEK : uint32
	{
		STREAM_SEEK_SET = 0,
		STREAM_SEEK_CUR = 1,
		STREAM_SEEK_END = 2,
	}

	[CRepr, Union]
	public struct LARGE_INTEGER
	{
		[CRepr]
		public struct _u_e__Struct
		{
			public uint32 LowPart;
			public int32 HighPart;
		}
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 LowPart;
			public int32 HighPart;
		}
		public using _Anonymous_e__Struct Anonymous;
		public _u_e__Struct u;
		public int64 QuadPart;
	}

	[CRepr, Union]
	public struct ULARGE_INTEGER
	{
		[CRepr]
		public struct _u_e__Struct
		{
			public uint32 LowPart;
			public uint32 HighPart;
		}
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 LowPart;
			public uint32 HighPart;
		}
		public using _Anonymous_e__Struct Anonymous;
		public _u_e__Struct u;
		public uint64 QuadPart;
	}

	[CRepr]
	struct DxcBuffer
	{
		public void* Ptr;
		public uint Size;
		public uint32 Encoding;
	}

	typealias DxcText = DxcBuffer;

	[CRepr]
	public struct DxcDefine
	{
		public char16* Name;
		public char16* Value;
	}

	// For use with IDxcResult::[Has|Get]Output dxcOutKind argument
	// Note: text outputs returned from version 2 APIs are UTF-8 or UTF-16 based on -encoding option
	[CRepr]
	enum DXC_OUT_KIND
	{
		DXC_OUT_NONE = 0,
		DXC_OUT_OBJECT = 1, // IDxcBlob - Shader or library object
		DXC_OUT_ERRORS = 2, // IDxcBlobUtf8 or IDxcBlobWide
		DXC_OUT_PDB = 3, // IDxcBlob
		DXC_OUT_SHADER_HASH = 4, // IDxcBlob - DxcShaderHash of shader or shader with source info (-Zsb/-Zss)
		DXC_OUT_DISASSEMBLY = 5, // IDxcBlobUtf8 or IDxcBlobWide - from Disassemble
		DXC_OUT_HLSL = 6, // IDxcBlobUtf8 or IDxcBlobWide - from Preprocessor or Rewriter
		DXC_OUT_TEXT = 7, // IDxcBlobUtf8 or IDxcBlobWide - other text, such as -ast-dump or -Odump
		DXC_OUT_REFLECTION = 8, // IDxcBlob - RDAT part with reflection data
		DXC_OUT_ROOT_SIGNATURE = 9, // IDxcBlob - Serialized root signature output
		DXC_OUT_EXTRA_OUTPUTS = 10, // IDxcExtraResults - Extra outputs
		DXC_OUT_REMARKS = 11, // IDxcBlobUtf8 or IDxcBlobUtf16 - text directed at stdout
		DXC_OUT_TIME_REPORT = 12, // IDxcBlobUtf8 or IDxcBlobWide - time report
		DXC_OUT_TIME_TRACE = 13, // IDxcBlobUtf8 or IDxcBlobWide - time trace

		DXC_OUT_FORCE_DWORD = 0xFFFFFFFF
	}

	[CRepr]
	struct DxcShaderHash
	{
		public uint32 Flags;
		public uint8[16] HashDigest;
	}

	[CRepr]
	struct IMalloc;

	[CRepr]
	struct DxcArgPair
	{
		public char16* pName; // wchar
		public char16* pValue; // wchar
	}

	  //typealias BSTR = void*;

	[CRepr]
	struct BSTR
	{
		public int16 Count;
		public char16* Data;
	}

	public static
	{
		public static mixin DXC_FOURCC(var ch0, var ch1, var ch2, var ch3)
		{
			(uint32)(uint8)(ch0) | (uint32)(uint8)(ch1) << 8 | (uint32)(uint8)(ch2) << 16 | (uint32)(uint8)(ch3) << 24
		}

		public const uint32 DXC_PART_PDB = DXC_FOURCC!('I', 'L', 'D', 'B');
		public const uint32 DXC_PART_PDB_NAME = DXC_FOURCC!('I', 'L', 'D', 'N');
		public const uint32 DXC_PART_PRIVATE_DATA = DXC_FOURCC!('P', 'R', 'I', 'V');
		public const uint32 DXC_PART_ROOT_SIGNATURE = DXC_FOURCC!('R', 'T', 'S', '0');
		public const uint32 DXC_PART_DXIL = DXC_FOURCC!('D', 'X', 'I', 'L');
		public const uint32 DXC_PART_REFLECTION_DATA = DXC_FOURCC!('S', 'T', 'A', 'T');
		public const uint32 DXC_PART_SHADER_HASH = DXC_FOURCC!('H', 'A', 'S', 'H');
		public const uint32 DXC_PART_INPUT_SIGNATURE = DXC_FOURCC!('I', 'S', 'G', '1');
		public const uint32 DXC_PART_OUTPUT_SIGNATURE = DXC_FOURCC!('O', 'S', 'G', '1');
		public const uint32 DXC_PART_PATCH_CONSTANT_SIGNATURE = DXC_FOURCC!('P', 'S', 'G', '1');

		public const String DXC_ARG_DEBUG = "-Zi";
		public const String DXC_ARG_SKIP_VALIDATION = "-Vd";
		public const String DXC_ARG_SKIP_OPTIMIZATIONS = "-Od";
		public const String DXC_ARG_PACK_MATRIX_ROW_MAJOR = "-Zpr";
		public const String DXC_ARG_PACK_MATRIX_COLUMN_MAJOR = "-Zpc";
		public const String DXC_ARG_AVOID_FLOW_CONTROL = "-Gfa";
		public const String DXC_ARG_PREFER_FLOW_CONTROL = "-Gfp";
		public const String DXC_ARG_ENABLE_STRICTNESS = "-Ges";
		public const String DXC_ARG_ENABLE_BACKWARDS_COMPATIBILITY = "-Gec";
		public const String DXC_ARG_IEEE_STRICTNESS = "-Gis";
		public const String DXC_ARG_OPTIMIZATION_LEVEL0 = "-O0";
		public const String DXC_ARG_OPTIMIZATION_LEVEL1 = "-O1";
		public const String DXC_ARG_OPTIMIZATION_LEVEL2 = "-O2";
		public const String DXC_ARG_OPTIMIZATION_LEVEL3 = "-O3";
		public const String DXC_ARG_WARNINGS_ARE_ERRORS = "-WX";
		public const String DXC_ARG_RESOURCES_MAY_ALIAS = "-res_may_alias";
		public const String DXC_ARG_ALL_RESOURCES_BOUND = "-all_resources_bound";
		public const String DXC_ARG_DEBUG_NAME_FOR_SOURCE = "-Zss";
		public const String DXC_ARG_DEBUG_NAME_FOR_BINARY = "-Zsb";

		// For convenience, equivalent definitions to CP_UTF8 and CP_UTF16.
		public const uint32 DXC_CP_UTF8 = 65001;
		public const uint32 DXC_CP_UTF16 = 1200;
		public const uint32 DXC_CP_UTF32 = 12000;
		// Use DXC_CP_ACP for: Binary;  ANSI Text;  Autodetect UTF with BOM
		public const uint32 DXC_CP_ACP = 0;

#if BF_PLATFORM_WINDOWS
		public const uint32 DXC_CP_WIDE = DXC_CP_UTF16;
#else
		public const uint32 DXC_CP_WIDE = DXC_CP_UTF32;
#endif
	}

	public static
	{
		public const String DXC_EXTRA_OUTPUT_NAME_STDOUT = "*stdout*";
		public const String DXC_EXTRA_OUTPUT_NAME_STDERR = "*stderr*";
	}

	public static
	{
		public static uint32 DxcValidatorFlags_Default = 0;
		public static uint32 DxcValidatorFlags_InPlaceEdit = 1; // Validator is allowed to update shader blob in-place.
		public static uint32 DxcValidatorFlags_RootSignatureOnly = 2;
		public static uint32 DxcValidatorFlags_ModuleOnly = 4;
		public static uint32 DxcValidatorFlags_ValidMask = 0x7;
	}

	public static
	{
		public const uint32 DxcVersionInfoFlags_None = 0;
		public const uint32 DxcVersionInfoFlags_Debug = 1; // Matches VS_FF_DEBUG
		public const uint32 DxcVersionInfoFlags_Internal = 2; // Internal Validator (non-signing)
	}

	public static
	{
		public static Guid CLSID_DxcCompiler = .(0x73e22d93, 0xe6ce, 0x47f3, 0xb5, 0xbf, 0xf0, 0x66, 0x4f, 0x39, 0xc1, 0xb0);

		// {EF6A8087-B0EA-4D56-9E45-D07E1A8B7806}
		public static Guid CLSID_DxcLinker = .(0xef6a8087, 0xb0ea, 0x4d56, 0x9e, 0x45, 0xd0, 0x7e, 0x1a, 0x8b, 0x78, 0x6);

		// {CD1F6B73-2AB0-484D-8EDC-EBE7A43CA09F}
		public static Guid CLSID_DxcDiaDataSource = .(0xcd1f6b73, 0x2ab0, 0x484d, 0x8e, 0xdc, 0xeb, 0xe7, 0xa4, 0x3c, 0xa0, 0x9f);

		// {3E56AE82-224D-470F-A1A1-FE3016EE9F9D}
		public static Guid CLSID_DxcCompilerArgs = .(0x3e56ae82, 0x224d, 0x470f, 0xa1, 0xa1, 0xfe, 0x30, 0x16, 0xee, 0x9f, 0x9d);

		// {6245D6AF-66E0-48FD-80B4-4D271796748C}
		public static Guid CLSID_DxcLibrary = .(0x6245d6af, 0x66e0, 0x48fd, 0x80, 0xb4, 0x4d, 0x27, 0x17, 0x96, 0x74, 0x8c);

		public static Guid CLSID_DxcUtils = CLSID_DxcLibrary;

		// {8CA3E215-F728-4CF3-8CDD-88AF917587A1}
		public static Guid CLSID_DxcValidator = .(0x8ca3e215, 0xf728, 0x4cf3, 0x8c, 0xdd, 0x88, 0xaf, 0x91, 0x75, 0x87, 0xa1);

		// {D728DB68-F903-4F80-94CD-DCCF76EC7151}
		public static Guid CLSID_DxcAssembler = .(0xd728db68, 0xf903, 0x4f80, 0x94, 0xcd, 0xdc, 0xcf, 0x76, 0xec, 0x71, 0x51);

		// {b9f54489-55b8-400c-ba3a-1675e4728b91}
		public static Guid CLSID_DxcContainerReflection = .(0xb9f54489, 0x55b8, 0x400c, 0xba, 0x3a, 0x16, 0x75, 0xe4, 0x72, 0x8b, 0x91);

		// {AE2CD79F-CC22-453F-9B6B-B124E7A5204C}
		public static Guid CLSID_DxcOptimizer = .(0xae2cd79f, 0xcc22, 0x453f, 0x9b, 0x6b, 0xb1, 0x24, 0xe7, 0xa5, 0x20, 0x4c);

		// {94134294-411f-4574-b4d0-8741e25240d2}
		public static Guid CLSID_DxcContainerBuilder = .(0x94134294, 0x411f, 0x4574, 0xb4, 0xd0, 0x87, 0x41, 0xe2, 0x52, 0x40, 0xd2);

		// {54621dfb-f2ce-457e-ae8c-ec355faeec7c}
		public static Guid CLSID_DxcPdbUtils = .(0x54621dfb, 0xf2ce, 0x457e, 0xae, 0x8c, 0xec, 0x35, 0x5f, 0xae, 0xec, 0x7c);
	}
}