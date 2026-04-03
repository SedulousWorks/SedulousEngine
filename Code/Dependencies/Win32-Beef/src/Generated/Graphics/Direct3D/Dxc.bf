using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.Graphics.Direct3D.Dxc;

#region Constants
public static
{
	public const uint32 DXC_HASHFLAG_INCLUDES_SOURCE = 1;
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
	public const String DXC_EXTRA_OUTPUT_NAME_STDOUT = "*stdout*";
	public const String DXC_EXTRA_OUTPUT_NAME_STDERR = "*stderr*";
	public const uint32 DxcValidatorFlags_Default = 0;
	public const uint32 DxcValidatorFlags_InPlaceEdit = 1;
	public const uint32 DxcValidatorFlags_RootSignatureOnly = 2;
	public const uint32 DxcValidatorFlags_ModuleOnly = 4;
	public const uint32 DxcValidatorFlags_ValidMask = 7;
	public const uint32 DxcVersionInfoFlags_None = 0;
	public const uint32 DxcVersionInfoFlags_Debug = 1;
	public const uint32 DxcVersionInfoFlags_Internal = 2;
	public const Guid CLSID_DxcCompiler = .(0x73e22d93, 0xe6ce, 0x47f3, 0xb5, 0xbf, 0xf0, 0x66, 0x4f, 0x39, 0xc1, 0xb0);
	public const Guid CLSID_DxcLinker = .(0xef6a8087, 0xb0ea, 0x4d56, 0x9e, 0x45, 0xd0, 0x7e, 0x1a, 0x8b, 0x78, 0x06);
	public const Guid CLSID_DxcDiaDataSource = .(0xcd1f6b73, 0x2ab0, 0x484d, 0x8e, 0xdc, 0xeb, 0xe7, 0xa4, 0x3c, 0xa0, 0x9f);
	public const Guid CLSID_DxcCompilerArgs = .(0x3e56ae82, 0x224d, 0x470f, 0xa1, 0xa1, 0xfe, 0x30, 0x16, 0xee, 0x9f, 0x9d);
	public const Guid CLSID_DxcLibrary = .(0x6245d6af, 0x66e0, 0x48fd, 0x80, 0xb4, 0x4d, 0x27, 0x17, 0x96, 0x74, 0x8c);
	public const Guid CLSID_DxcValidator = .(0x8ca3e215, 0xf728, 0x4cf3, 0x8c, 0xdd, 0x88, 0xaf, 0x91, 0x75, 0x87, 0xa1);
	public const Guid CLSID_DxcAssembler = .(0xd728db68, 0xf903, 0x4f80, 0x94, 0xcd, 0xdc, 0xcf, 0x76, 0xec, 0x71, 0x51);
	public const Guid CLSID_DxcContainerReflection = .(0xb9f54489, 0x55b8, 0x400c, 0xba, 0x3a, 0x16, 0x75, 0xe4, 0x72, 0x8b, 0x91);
	public const Guid CLSID_DxcOptimizer = .(0xae2cd79f, 0xcc22, 0x453f, 0x9b, 0x6b, 0xb1, 0x24, 0xe7, 0xa5, 0x20, 0x4c);
	public const Guid CLSID_DxcContainerBuilder = .(0x94134294, 0x411f, 0x4574, 0xb4, 0xd0, 0x87, 0x41, 0xe2, 0x52, 0x40, 0xd2);
	public const Guid CLSID_DxcPdbUtils = .(0x54621dfb, 0xf2ce, 0x457e, 0xae, 0x8c, 0xec, 0x35, 0x5f, 0xae, 0xec, 0x7c);
}
#endregion

#region Enums

[AllowDuplicates]
public enum DXC_CP : uint32
{
	DXC_CP_ACP = 0,
	DXC_CP_UTF16 = 1200,
	DXC_CP_UTF8 = 65001,
}


[AllowDuplicates]
public enum DXC_OUT_KIND : int32
{
	DXC_OUT_NONE = 0,
	DXC_OUT_OBJECT = 1,
	DXC_OUT_ERRORS = 2,
	DXC_OUT_PDB = 3,
	DXC_OUT_SHADER_HASH = 4,
	DXC_OUT_DISASSEMBLY = 5,
	DXC_OUT_HLSL = 6,
	DXC_OUT_TEXT = 7,
	DXC_OUT_REFLECTION = 8,
	DXC_OUT_ROOT_SIGNATURE = 9,
	DXC_OUT_EXTRA_OUTPUTS = 10,
	DXC_OUT_FORCE_DWORD = -1,
}

#endregion

#region Function Pointers
public function HRESULT DxcCreateInstanceProc(in Guid rclsid, in Guid riid, void** ppv);

public function HRESULT DxcCreateInstance2Proc(IMalloc* pMalloc, in Guid rclsid, in Guid riid, void** ppv);

#endregion

#region Structs
[CRepr]
public struct DxcShaderHash
{
	public uint32 Flags;
	public uint8[16] HashDigest;
}

[CRepr]
public struct DxcBuffer
{
	public void* Ptr;
	public uint Size;
	public uint32 Encoding;
}

[CRepr]
public struct DxcDefine
{
	public PWSTR Name;
	public PWSTR Value;
}

[CRepr]
public struct DxcArgPair
{
	public PWSTR pName;
	public PWSTR pValue;
}

#endregion

#region COM Types
[CRepr]struct IDxcBlob : IUnknown
{
	public new const Guid IID = .(0x8ba5fb08, 0x5195, 0x40e2, 0xac, 0x58, 0x0d, 0x98, 0x9c, 0x3a, 0x01, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self) GetBufferPointer;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self) GetBufferSize;
	}


	public void* GetBufferPointer() mut => VT.[Friend]GetBufferPointer(&this);

	public uint GetBufferSize() mut => VT.[Friend]GetBufferSize(&this);
}

[CRepr]struct IDxcBlobEncoding : IDxcBlob
{
	public new const Guid IID = .(0x7241d424, 0x2646, 0x4191, 0x97, 0xc0, 0x98, 0xe9, 0x6e, 0x42, 0xfc, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcBlob.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pKnown, DXC_CP* pCodePage) GetEncoding;
	}


	public HRESULT GetEncoding(BOOL* pKnown, DXC_CP* pCodePage) mut => VT.[Friend]GetEncoding(&this, pKnown, pCodePage);
}

[CRepr]struct IDxcBlobUtf16 : IDxcBlobEncoding
{
	public new const Guid IID = .(0xa3f84eab, 0x0faa, 0x497e, 0xa3, 0x9c, 0xee, 0x6e, 0xd6, 0x0b, 0x2d, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcBlobEncoding.VTable
	{
		protected new function [CallingConvention(.Stdcall)] PWSTR(SelfOuter* self) GetStringPointer;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self) GetStringLength;
	}


	public PWSTR GetStringPointer() mut => VT.[Friend]GetStringPointer(&this);

	public uint GetStringLength() mut => VT.[Friend]GetStringLength(&this);
}

[CRepr]struct IDxcBlobUtf8 : IDxcBlobEncoding
{
	public new const Guid IID = .(0x3da636c9, 0xba71, 0x4024, 0xa3, 0x01, 0x30, 0xcb, 0xf1, 0x25, 0x30, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcBlobEncoding.VTable
	{
		protected new function [CallingConvention(.Stdcall)] PSTR(SelfOuter* self) GetStringPointer;
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self) GetStringLength;
	}


	public PSTR GetStringPointer() mut => VT.[Friend]GetStringPointer(&this);

	public uint GetStringLength() mut => VT.[Friend]GetStringLength(&this);
}

[CRepr]struct IDxcIncludeHandler : IUnknown
{
	public new const Guid IID = .(0x7f61fc7d, 0x950d, 0x467f, 0xb3, 0xe3, 0x3c, 0x02, 0xfb, 0x49, 0x18, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pFilename, IDxcBlob** ppIncludeSource) LoadSource;
	}


	public HRESULT LoadSource(PWSTR pFilename, IDxcBlob** ppIncludeSource) mut => VT.[Friend]LoadSource(&this, pFilename, ppIncludeSource);
}

[CRepr]struct IDxcCompilerArgs : IUnknown
{
	public new const Guid IID = .(0x73effe2a, 0x70dc, 0x45f8, 0x96, 0x90, 0xef, 0xf6, 0x4c, 0x02, 0x42, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] PWSTR*(SelfOuter* self) GetArguments;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pArguments, uint32 argCount) AddArguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR* pArguments, uint32 argCount) AddArgumentsUTF8;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DxcDefine* pDefines, uint32 defineCount) AddDefines;
	}


	public PWSTR* GetArguments() mut => VT.[Friend]GetArguments(&this);

	public uint32 GetCount() mut => VT.[Friend]GetCount(&this);

	public HRESULT AddArguments(PWSTR* pArguments, uint32 argCount) mut => VT.[Friend]AddArguments(&this, pArguments, argCount);

	public HRESULT AddArgumentsUTF8(PSTR* pArguments, uint32 argCount) mut => VT.[Friend]AddArgumentsUTF8(&this, pArguments, argCount);

	public HRESULT AddDefines(DxcDefine* pDefines, uint32 defineCount) mut => VT.[Friend]AddDefines(&this, pDefines, defineCount);
}

[CRepr]struct IDxcLibrary : IUnknown
{
	public new const Guid IID = .(0xe5204dc7, 0xd18c, 0x4c3c, 0xbd, 0xfb, 0x85, 0x16, 0x73, 0x98, 0x0f, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMalloc* pMalloc) SetMalloc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, uint32 offset, uint32 length, IDxcBlob** ppResult) CreateBlobFromBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pFileName, DXC_CP* codePage, IDxcBlobEncoding** pBlobEncoding) CreateBlobFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pText, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) CreateBlobWithEncodingFromPinned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pText, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) CreateBlobWithEncodingOnHeapCopy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pText, IMalloc* pIMalloc, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) CreateBlobWithEncodingOnMalloc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcIncludeHandler** ppResult) CreateIncludeHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, IStream** ppStream) CreateStreamFromBlobReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, IDxcBlobEncoding** pBlobEncoding) GetBlobAsUtf8;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, IDxcBlobEncoding** pBlobEncoding) GetBlobAsUtf16;
	}


	public HRESULT SetMalloc(IMalloc* pMalloc) mut => VT.[Friend]SetMalloc(&this, pMalloc);

	public HRESULT CreateBlobFromBlob(IDxcBlob* pBlob, uint32 offset, uint32 length, IDxcBlob** ppResult) mut => VT.[Friend]CreateBlobFromBlob(&this, pBlob, offset, length, ppResult);

	public HRESULT CreateBlobFromFile(PWSTR pFileName, DXC_CP* codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]CreateBlobFromFile(&this, pFileName, codePage, pBlobEncoding);

	public HRESULT CreateBlobWithEncodingFromPinned(void* pText, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]CreateBlobWithEncodingFromPinned(&this, pText, size, codePage, pBlobEncoding);

	public HRESULT CreateBlobWithEncodingOnHeapCopy(void* pText, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]CreateBlobWithEncodingOnHeapCopy(&this, pText, size, codePage, pBlobEncoding);

	public HRESULT CreateBlobWithEncodingOnMalloc(void* pText, IMalloc* pIMalloc, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]CreateBlobWithEncodingOnMalloc(&this, pText, pIMalloc, size, codePage, pBlobEncoding);

	public HRESULT CreateIncludeHandler(IDxcIncludeHandler** ppResult) mut => VT.[Friend]CreateIncludeHandler(&this, ppResult);

	public HRESULT CreateStreamFromBlobReadOnly(IDxcBlob* pBlob, IStream** ppStream) mut => VT.[Friend]CreateStreamFromBlobReadOnly(&this, pBlob, ppStream);

	public HRESULT GetBlobAsUtf8(IDxcBlob* pBlob, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]GetBlobAsUtf8(&this, pBlob, pBlobEncoding);

	public HRESULT GetBlobAsUtf16(IDxcBlob* pBlob, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]GetBlobAsUtf16(&this, pBlob, pBlobEncoding);
}

[CRepr]struct IDxcOperationResult : IUnknown
{
	public new const Guid IID = .(0xcedb484a, 0xd4e9, 0x445a, 0xb9, 0x91, 0xca, 0x21, 0xca, 0x15, 0x7d, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* pStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob** ppResult) GetResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlobEncoding** ppErrors) GetErrorBuffer;
	}


	public HRESULT GetStatus(HRESULT* pStatus) mut => VT.[Friend]GetStatus(&this, pStatus);

	public HRESULT GetResult(IDxcBlob** ppResult) mut => VT.[Friend]GetResult(&this, ppResult);

	public HRESULT GetErrorBuffer(IDxcBlobEncoding** ppErrors) mut => VT.[Friend]GetErrorBuffer(&this, ppErrors);
}

[CRepr]struct IDxcCompiler : IUnknown
{
	public new const Guid IID = .(0x8c210bf3, 0x011f, 0x4422, 0x8d, 0x70, 0x6f, 0x9a, 0xcb, 0x8d, 0xb6, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pSource, PWSTR pSourceName, PWSTR pEntryPoint, PWSTR pTargetProfile, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcIncludeHandler* pIncludeHandler, IDxcOperationResult** ppResult) Compile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pSource, PWSTR pSourceName, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcIncludeHandler* pIncludeHandler, IDxcOperationResult** ppResult) Preprocess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pSource, IDxcBlobEncoding** ppDisassembly) Disassemble;
	}


	public HRESULT Compile(IDxcBlob* pSource, PWSTR pSourceName, PWSTR pEntryPoint, PWSTR pTargetProfile, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcIncludeHandler* pIncludeHandler, IDxcOperationResult** ppResult) mut => VT.[Friend]Compile(&this, pSource, pSourceName, pEntryPoint, pTargetProfile, pArguments, argCount, pDefines, defineCount, pIncludeHandler, ppResult);

	public HRESULT Preprocess(IDxcBlob* pSource, PWSTR pSourceName, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcIncludeHandler* pIncludeHandler, IDxcOperationResult** ppResult) mut => VT.[Friend]Preprocess(&this, pSource, pSourceName, pArguments, argCount, pDefines, defineCount, pIncludeHandler, ppResult);

	public HRESULT Disassemble(IDxcBlob* pSource, IDxcBlobEncoding** ppDisassembly) mut => VT.[Friend]Disassemble(&this, pSource, ppDisassembly);
}

[CRepr]struct IDxcCompiler2 : IDxcCompiler
{
	public new const Guid IID = .(0xa005a9d9, 0xb8bb, 0x4594, 0xb5, 0xc9, 0x0e, 0x63, 0x3b, 0xec, 0x4d, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcCompiler.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pSource, PWSTR pSourceName, PWSTR pEntryPoint, PWSTR pTargetProfile, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcIncludeHandler* pIncludeHandler, IDxcOperationResult** ppResult, PWSTR* ppDebugBlobName, IDxcBlob** ppDebugBlob) CompileWithDebug;
	}


	public HRESULT CompileWithDebug(IDxcBlob* pSource, PWSTR pSourceName, PWSTR pEntryPoint, PWSTR pTargetProfile, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcIncludeHandler* pIncludeHandler, IDxcOperationResult** ppResult, PWSTR* ppDebugBlobName, IDxcBlob** ppDebugBlob) mut => VT.[Friend]CompileWithDebug(&this, pSource, pSourceName, pEntryPoint, pTargetProfile, pArguments, argCount, pDefines, defineCount, pIncludeHandler, ppResult, ppDebugBlobName, ppDebugBlob);
}

[CRepr]struct IDxcLinker : IUnknown
{
	public new const Guid IID = .(0xf1b5be2a, 0x62dd, 0x4327, 0xa1, 0xc2, 0x42, 0xac, 0x1e, 0x1e, 0x78, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pLibName, IDxcBlob* pLib) RegisterLibrary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pEntryName, PWSTR pTargetProfile, PWSTR* pLibNames, uint32 libCount, PWSTR* pArguments, uint32 argCount, IDxcOperationResult** ppResult) Link;
	}


	public HRESULT RegisterLibrary(PWSTR pLibName, IDxcBlob* pLib) mut => VT.[Friend]RegisterLibrary(&this, pLibName, pLib);

	public HRESULT Link(PWSTR pEntryName, PWSTR pTargetProfile, PWSTR* pLibNames, uint32 libCount, PWSTR* pArguments, uint32 argCount, IDxcOperationResult** ppResult) mut => VT.[Friend]Link(&this, pEntryName, pTargetProfile, pLibNames, libCount, pArguments, argCount, ppResult);
}

[CRepr]struct IDxcUtils : IUnknown
{
	public new const Guid IID = .(0x4605c4cb, 0x2019, 0x492a, 0xad, 0xa4, 0x65, 0xf2, 0x0b, 0xb7, 0xd6, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, uint32 offset, uint32 length, IDxcBlob** ppResult) CreateBlobFromBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pData, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) CreateBlobFromPinned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pData, IMalloc* pIMalloc, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) MoveToBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pData, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) CreateBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pFileName, DXC_CP* pCodePage, IDxcBlobEncoding** pBlobEncoding) LoadFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, IStream** ppStream) CreateReadOnlyStreamFromBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcIncludeHandler** ppResult) CreateDefaultIncludeHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, IDxcBlobUtf8** pBlobEncoding) GetBlobAsUtf8;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, IDxcBlobUtf16** pBlobEncoding) GetBlobAsUtf16;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DxcBuffer* pShader, uint32 DxcPart, void** ppPartData, uint32* pPartSizeInBytes) GetDxilContainerPart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DxcBuffer* pData, in Guid iid, void** ppvReflection) CreateReflection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSourceName, PWSTR pEntryPoint, PWSTR pTargetProfile, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcCompilerArgs** ppArgs) BuildArguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pPDBBlob, IDxcBlob** ppHash, IDxcBlob** ppContainer) GetPDBContents;
	}


	public HRESULT CreateBlobFromBlob(IDxcBlob* pBlob, uint32 offset, uint32 length, IDxcBlob** ppResult) mut => VT.[Friend]CreateBlobFromBlob(&this, pBlob, offset, length, ppResult);

	public HRESULT CreateBlobFromPinned(void* pData, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]CreateBlobFromPinned(&this, pData, size, codePage, pBlobEncoding);

	public HRESULT MoveToBlob(void* pData, IMalloc* pIMalloc, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]MoveToBlob(&this, pData, pIMalloc, size, codePage, pBlobEncoding);

	public HRESULT CreateBlob(void* pData, uint32 size, DXC_CP codePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]CreateBlob(&this, pData, size, codePage, pBlobEncoding);

	public HRESULT LoadFile(PWSTR pFileName, DXC_CP* pCodePage, IDxcBlobEncoding** pBlobEncoding) mut => VT.[Friend]LoadFile(&this, pFileName, pCodePage, pBlobEncoding);

	public HRESULT CreateReadOnlyStreamFromBlob(IDxcBlob* pBlob, IStream** ppStream) mut => VT.[Friend]CreateReadOnlyStreamFromBlob(&this, pBlob, ppStream);

	public HRESULT CreateDefaultIncludeHandler(IDxcIncludeHandler** ppResult) mut => VT.[Friend]CreateDefaultIncludeHandler(&this, ppResult);

	public HRESULT GetBlobAsUtf8(IDxcBlob* pBlob, IDxcBlobUtf8** pBlobEncoding) mut => VT.[Friend]GetBlobAsUtf8(&this, pBlob, pBlobEncoding);

	public HRESULT GetBlobAsUtf16(IDxcBlob* pBlob, IDxcBlobUtf16** pBlobEncoding) mut => VT.[Friend]GetBlobAsUtf16(&this, pBlob, pBlobEncoding);

	public HRESULT GetDxilContainerPart(DxcBuffer* pShader, uint32 DxcPart, void** ppPartData, uint32* pPartSizeInBytes) mut => VT.[Friend]GetDxilContainerPart(&this, pShader, DxcPart, ppPartData, pPartSizeInBytes);

	public HRESULT CreateReflection(DxcBuffer* pData, in Guid iid, void** ppvReflection) mut => VT.[Friend]CreateReflection(&this, pData, iid, ppvReflection);

	public HRESULT BuildArguments(PWSTR pSourceName, PWSTR pEntryPoint, PWSTR pTargetProfile, PWSTR* pArguments, uint32 argCount, DxcDefine* pDefines, uint32 defineCount, IDxcCompilerArgs** ppArgs) mut => VT.[Friend]BuildArguments(&this, pSourceName, pEntryPoint, pTargetProfile, pArguments, argCount, pDefines, defineCount, ppArgs);

	public HRESULT GetPDBContents(IDxcBlob* pPDBBlob, IDxcBlob** ppHash, IDxcBlob** ppContainer) mut => VT.[Friend]GetPDBContents(&this, pPDBBlob, ppHash, ppContainer);
}

[CRepr]struct IDxcResult : IDxcOperationResult
{
	public new const Guid IID = .(0x58346cda, 0xdde7, 0x4497, 0x94, 0x61, 0x6f, 0x87, 0xaf, 0x5e, 0x06, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcOperationResult.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, DXC_OUT_KIND dxcOutKind) HasOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXC_OUT_KIND dxcOutKind, in Guid iid, void** ppvObject, IDxcBlobUtf16** ppOutputName) GetOutput;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetNumOutputs;
		protected new function [CallingConvention(.Stdcall)] DXC_OUT_KIND(SelfOuter* self, uint32 Index) GetOutputByIndex;
		protected new function [CallingConvention(.Stdcall)] DXC_OUT_KIND(SelfOuter* self) PrimaryOutput;
	}


	public BOOL HasOutput(DXC_OUT_KIND dxcOutKind) mut => VT.[Friend]HasOutput(&this, dxcOutKind);

	public HRESULT GetOutput(DXC_OUT_KIND dxcOutKind, in Guid iid, void** ppvObject, IDxcBlobUtf16** ppOutputName) mut => VT.[Friend]GetOutput(&this, dxcOutKind, iid, ppvObject, ppOutputName);

	public uint32 GetNumOutputs() mut => VT.[Friend]GetNumOutputs(&this);

	public DXC_OUT_KIND GetOutputByIndex(uint32 Index) mut => VT.[Friend]GetOutputByIndex(&this, Index);

	public DXC_OUT_KIND PrimaryOutput() mut => VT.[Friend]PrimaryOutput(&this);
}

[CRepr]struct IDxcExtraOutputs : IUnknown
{
	public new const Guid IID = .(0x319b37a2, 0xa5c2, 0x494a, 0xa5, 0xde, 0x48, 0x01, 0xb2, 0xfa, 0xf9, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetOutputCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, in Guid iid, void** ppvObject, IDxcBlobUtf16** ppOutputType, IDxcBlobUtf16** ppOutputName) GetOutput;
	}


	public uint32 GetOutputCount() mut => VT.[Friend]GetOutputCount(&this);

	public HRESULT GetOutput(uint32 uIndex, in Guid iid, void** ppvObject, IDxcBlobUtf16** ppOutputType, IDxcBlobUtf16** ppOutputName) mut => VT.[Friend]GetOutput(&this, uIndex, iid, ppvObject, ppOutputType, ppOutputName);
}

[CRepr]struct IDxcCompiler3 : IUnknown
{
	public new const Guid IID = .(0x228b4687, 0x5a6a, 0x4730, 0x90, 0x0c, 0x97, 0x02, 0xb2, 0x20, 0x3f, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DxcBuffer* pSource, PWSTR* pArguments, uint32 argCount, IDxcIncludeHandler* pIncludeHandler, in Guid riid, void** ppResult) Compile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DxcBuffer* pObject, in Guid riid, void** ppResult) Disassemble;
	}


	public HRESULT Compile(DxcBuffer* pSource, PWSTR* pArguments, uint32 argCount, IDxcIncludeHandler* pIncludeHandler, in Guid riid, void** ppResult) mut => VT.[Friend]Compile(&this, pSource, pArguments, argCount, pIncludeHandler, riid, ppResult);

	public HRESULT Disassemble(DxcBuffer* pObject, in Guid riid, void** ppResult) mut => VT.[Friend]Disassemble(&this, pObject, riid, ppResult);
}

[CRepr]struct IDxcValidator : IUnknown
{
	public new const Guid IID = .(0xa6e82bd2, 0x1fd7, 0x4826, 0x98, 0x11, 0x28, 0x57, 0xe7, 0x97, 0xf4, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pShader, uint32 Flags, IDxcOperationResult** ppResult) Validate;
	}


	public HRESULT Validate(IDxcBlob* pShader, uint32 Flags, IDxcOperationResult** ppResult) mut => VT.[Friend]Validate(&this, pShader, Flags, ppResult);
}

[CRepr]struct IDxcValidator2 : IDxcValidator
{
	public new const Guid IID = .(0x458e1fd1, 0xb1b2, 0x4750, 0xa6, 0xe1, 0x9c, 0x10, 0xf0, 0x3b, 0xed, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcValidator.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pShader, uint32 Flags, DxcBuffer* pOptDebugBitcode, IDxcOperationResult** ppResult) ValidateWithDebug;
	}


	public HRESULT ValidateWithDebug(IDxcBlob* pShader, uint32 Flags, DxcBuffer* pOptDebugBitcode, IDxcOperationResult** ppResult) mut => VT.[Friend]ValidateWithDebug(&this, pShader, Flags, pOptDebugBitcode, ppResult);
}

[CRepr]struct IDxcContainerBuilder : IUnknown
{
	public new const Guid IID = .(0x334b1f50, 0x2292, 0x4b35, 0x99, 0xa1, 0x25, 0x58, 0x8d, 0x8c, 0x17, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pDxilContainerHeader) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fourCC, IDxcBlob* pSource) AddPart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fourCC) RemovePart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcOperationResult** ppResult) SerializeContainer;
	}


	public HRESULT Load(IDxcBlob* pDxilContainerHeader) mut => VT.[Friend]Load(&this, pDxilContainerHeader);

	public HRESULT AddPart(uint32 fourCC, IDxcBlob* pSource) mut => VT.[Friend]AddPart(&this, fourCC, pSource);

	public HRESULT RemovePart(uint32 fourCC) mut => VT.[Friend]RemovePart(&this, fourCC);

	public HRESULT SerializeContainer(IDxcOperationResult** ppResult) mut => VT.[Friend]SerializeContainer(&this, ppResult);
}

[CRepr]struct IDxcAssembler : IUnknown
{
	public new const Guid IID = .(0x091f7a26, 0x1c1f, 0x4948, 0x90, 0x4b, 0xe6, 0xe3, 0xa8, 0xa7, 0x71, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pShader, IDxcOperationResult** ppResult) AssembleToContainer;
	}


	public HRESULT AssembleToContainer(IDxcBlob* pShader, IDxcOperationResult** ppResult) mut => VT.[Friend]AssembleToContainer(&this, pShader, ppResult);
}

[CRepr]struct IDxcContainerReflection : IUnknown
{
	public new const Guid IID = .(0xd2c21b26, 0x8350, 0x4bdc, 0x97, 0x6a, 0x33, 0x1c, 0xe6, 0xf4, 0xc5, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pContainer) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pResult) GetPartCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idx, uint32* pResult) GetPartKind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idx, IDxcBlob** ppResult) GetPartContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 kind, uint32* pResult) FindFirstPartKind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idx, in Guid iid, void** ppvObject) GetPartReflection;
	}


	public HRESULT Load(IDxcBlob* pContainer) mut => VT.[Friend]Load(&this, pContainer);

	public HRESULT GetPartCount(uint32* pResult) mut => VT.[Friend]GetPartCount(&this, pResult);

	public HRESULT GetPartKind(uint32 idx, uint32* pResult) mut => VT.[Friend]GetPartKind(&this, idx, pResult);

	public HRESULT GetPartContent(uint32 idx, IDxcBlob** ppResult) mut => VT.[Friend]GetPartContent(&this, idx, ppResult);

	public HRESULT FindFirstPartKind(uint32 kind, uint32* pResult) mut => VT.[Friend]FindFirstPartKind(&this, kind, pResult);

	public HRESULT GetPartReflection(uint32 idx, in Guid iid, void** ppvObject) mut => VT.[Friend]GetPartReflection(&this, idx, iid, ppvObject);
}

[CRepr]struct IDxcOptimizerPass : IUnknown
{
	public new const Guid IID = .(0xae2cd79f, 0xcc22, 0x453f, 0x9b, 0x6b, 0xb1, 0x24, 0xe7, 0xa5, 0x20, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppResult) GetOptionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppResult) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetOptionArgCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 argIndex, PWSTR* ppResult) GetOptionArgName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 argIndex, PWSTR* ppResult) GetOptionArgDescription;
	}


	public HRESULT GetOptionName(PWSTR* ppResult) mut => VT.[Friend]GetOptionName(&this, ppResult);

	public HRESULT GetDescription(PWSTR* ppResult) mut => VT.[Friend]GetDescription(&this, ppResult);

	public HRESULT GetOptionArgCount(uint32* pCount) mut => VT.[Friend]GetOptionArgCount(&this, pCount);

	public HRESULT GetOptionArgName(uint32 argIndex, PWSTR* ppResult) mut => VT.[Friend]GetOptionArgName(&this, argIndex, ppResult);

	public HRESULT GetOptionArgDescription(uint32 argIndex, PWSTR* ppResult) mut => VT.[Friend]GetOptionArgDescription(&this, argIndex, ppResult);
}

[CRepr]struct IDxcOptimizer : IUnknown
{
	public new const Guid IID = .(0x25740e2e, 0x9cba, 0x401b, 0x91, 0x19, 0x4f, 0xb4, 0x2f, 0x39, 0xf2, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetAvailablePassCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IDxcOptimizerPass** ppResult) GetAvailablePass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pBlob, PWSTR* ppOptions, uint32 optionCount, IDxcBlob** pOutputModule, IDxcBlobEncoding** ppOutputText) RunOptimizer;
	}


	public HRESULT GetAvailablePassCount(uint32* pCount) mut => VT.[Friend]GetAvailablePassCount(&this, pCount);

	public HRESULT GetAvailablePass(uint32 index, IDxcOptimizerPass** ppResult) mut => VT.[Friend]GetAvailablePass(&this, index, ppResult);

	public HRESULT RunOptimizer(IDxcBlob* pBlob, PWSTR* ppOptions, uint32 optionCount, IDxcBlob** pOutputModule, IDxcBlobEncoding** ppOutputText) mut => VT.[Friend]RunOptimizer(&this, pBlob, ppOptions, optionCount, pOutputModule, ppOutputText);
}

[CRepr]struct IDxcVersionInfo : IUnknown
{
	public new const Guid IID = .(0xb04f5b50, 0x2059, 0x4f12, 0xa8, 0xff, 0xa1, 0xe0, 0xcd, 0xe1, 0xcc, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMajor, uint32* pMinor) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) COM_GetFlags;
	}


	public HRESULT GetVersion(uint32* pMajor, uint32* pMinor) mut => VT.[Friend]GetVersion(&this, pMajor, pMinor);

	public HRESULT GetFlags(uint32* pFlags) mut => VT.[Friend]COM_GetFlags(&this, pFlags);
}

[CRepr]struct IDxcVersionInfo2 : IDxcVersionInfo
{
	public new const Guid IID = .(0xfb6904c4, 0x42f0, 0x4b62, 0x9c, 0x46, 0x98, 0x3a, 0xf7, 0xda, 0x7c, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDxcVersionInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCommitCount, int8** pCommitHash) GetCommitInfo;
	}


	public HRESULT GetCommitInfo(uint32* pCommitCount, int8** pCommitHash) mut => VT.[Friend]GetCommitInfo(&this, pCommitCount, pCommitHash);
}

[CRepr]struct IDxcVersionInfo3 : IUnknown
{
	public new const Guid IID = .(0x5e13e843, 0x9d25, 0x473c, 0x9a, 0xd2, 0x03, 0xb2, 0xd0, 0xb4, 0x4b, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8** pVersionString) GetCustomVersionString;
	}


	public HRESULT GetCustomVersionString(int8** pVersionString) mut => VT.[Friend]GetCustomVersionString(&this, pVersionString);
}

[CRepr]struct IDxcPdbUtils : IUnknown
{
	public new const Guid IID = .(0xe6c9647e, 0x9d6a, 0x4c3b, 0xb9, 0x4c, 0x52, 0x4b, 0x5a, 0x6c, 0x34, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob* pPdbOrDxil) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetSourceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, IDxcBlobEncoding** ppResult) GetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pResult) GetSourceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetFlagCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pResult) GetFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetArgCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pResult) GetArg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetArgPairCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pName, BSTR* pValue) GetArgPair;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetDefineCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pResult) GetDefine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pResult) GetTargetProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pResult) GetEntryPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pResult) GetMainFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob** ppResult) GetHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pResult) GetName;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsFullPDB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcBlob** ppFullPDB) GetFullPDB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcVersionInfo** ppVersionInfo) GetVersionInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcCompiler3* pCompiler) SetCompiler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDxcResult** ppResult) CompileForFullPDB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DxcArgPair* pArgPairs, uint32 uNumArgPairs) OverrideArgs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pRootSignature) OverrideRootSignature;
	}


	public HRESULT Load(IDxcBlob* pPdbOrDxil) mut => VT.[Friend]Load(&this, pPdbOrDxil);

	public HRESULT GetSourceCount(uint32* pCount) mut => VT.[Friend]GetSourceCount(&this, pCount);

	public HRESULT GetSource(uint32 uIndex, IDxcBlobEncoding** ppResult) mut => VT.[Friend]GetSource(&this, uIndex, ppResult);

	public HRESULT GetSourceName(uint32 uIndex, BSTR* pResult) mut => VT.[Friend]GetSourceName(&this, uIndex, pResult);

	public HRESULT GetFlagCount(uint32* pCount) mut => VT.[Friend]GetFlagCount(&this, pCount);

	public HRESULT GetFlag(uint32 uIndex, BSTR* pResult) mut => VT.[Friend]GetFlag(&this, uIndex, pResult);

	public HRESULT GetArgCount(uint32* pCount) mut => VT.[Friend]GetArgCount(&this, pCount);

	public HRESULT GetArg(uint32 uIndex, BSTR* pResult) mut => VT.[Friend]GetArg(&this, uIndex, pResult);

	public HRESULT GetArgPairCount(uint32* pCount) mut => VT.[Friend]GetArgPairCount(&this, pCount);

	public HRESULT GetArgPair(uint32 uIndex, BSTR* pName, BSTR* pValue) mut => VT.[Friend]GetArgPair(&this, uIndex, pName, pValue);

	public HRESULT GetDefineCount(uint32* pCount) mut => VT.[Friend]GetDefineCount(&this, pCount);

	public HRESULT GetDefine(uint32 uIndex, BSTR* pResult) mut => VT.[Friend]GetDefine(&this, uIndex, pResult);

	public HRESULT GetTargetProfile(BSTR* pResult) mut => VT.[Friend]GetTargetProfile(&this, pResult);

	public HRESULT GetEntryPoint(BSTR* pResult) mut => VT.[Friend]GetEntryPoint(&this, pResult);

	public HRESULT GetMainFileName(BSTR* pResult) mut => VT.[Friend]GetMainFileName(&this, pResult);

	public HRESULT GetHash(IDxcBlob** ppResult) mut => VT.[Friend]GetHash(&this, ppResult);

	public HRESULT GetName(BSTR* pResult) mut => VT.[Friend]GetName(&this, pResult);

	public BOOL IsFullPDB() mut => VT.[Friend]IsFullPDB(&this);

	public HRESULT GetFullPDB(IDxcBlob** ppFullPDB) mut => VT.[Friend]GetFullPDB(&this, ppFullPDB);

	public HRESULT GetVersionInfo(IDxcVersionInfo** ppVersionInfo) mut => VT.[Friend]GetVersionInfo(&this, ppVersionInfo);

	public HRESULT SetCompiler(IDxcCompiler3* pCompiler) mut => VT.[Friend]SetCompiler(&this, pCompiler);

	public HRESULT CompileForFullPDB(IDxcResult** ppResult) mut => VT.[Friend]CompileForFullPDB(&this, ppResult);

	public HRESULT OverrideArgs(DxcArgPair* pArgPairs, uint32 uNumArgPairs) mut => VT.[Friend]OverrideArgs(&this, pArgPairs, uNumArgPairs);

	public HRESULT OverrideRootSignature(PWSTR pRootSignature) mut => VT.[Friend]OverrideRootSignature(&this, pRootSignature);
}

#endregion

#region Functions
public static
{
	[Import("dxcompiler.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DxcCreateInstance(in Guid rclsid, in Guid riid, void** ppv);

	[Import("dxcompiler.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DxcCreateInstance2(IMalloc* pMalloc, in Guid rclsid, in Guid riid, void** ppv);

}
#endregion
