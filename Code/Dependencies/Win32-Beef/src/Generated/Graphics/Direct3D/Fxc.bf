using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Direct3D10;
using System;

namespace Win32.Graphics.Direct3D.Fxc;

#region Constants
public static
{
	public const String D3DCOMPILER_DLL_W = "d3dcompiler_47.dll";
	public const String D3DCOMPILER_DLL_A = "d3dcompiler_47.dll";
	public const uint32 D3D_COMPILER_VERSION = 47;
	public const uint32 D3DCOMPILE_DEBUG = 1;
	public const uint32 D3DCOMPILE_SKIP_VALIDATION = 2;
	public const uint32 D3DCOMPILE_SKIP_OPTIMIZATION = 4;
	public const uint32 D3DCOMPILE_PACK_MATRIX_ROW_MAJOR = 8;
	public const uint32 D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR = 16;
	public const uint32 D3DCOMPILE_PARTIAL_PRECISION = 32;
	public const uint32 D3DCOMPILE_FORCE_VS_SOFTWARE_NO_OPT = 64;
	public const uint32 D3DCOMPILE_FORCE_PS_SOFTWARE_NO_OPT = 128;
	public const uint32 D3DCOMPILE_NO_PRESHADER = 256;
	public const uint32 D3DCOMPILE_AVOID_FLOW_CONTROL = 512;
	public const uint32 D3DCOMPILE_PREFER_FLOW_CONTROL = 1024;
	public const uint32 D3DCOMPILE_ENABLE_STRICTNESS = 2048;
	public const uint32 D3DCOMPILE_ENABLE_BACKWARDS_COMPATIBILITY = 4096;
	public const uint32 D3DCOMPILE_IEEE_STRICTNESS = 8192;
	public const uint32 D3DCOMPILE_OPTIMIZATION_LEVEL0 = 16384;
	public const uint32 D3DCOMPILE_OPTIMIZATION_LEVEL1 = 0;
	public const uint32 D3DCOMPILE_OPTIMIZATION_LEVEL3 = 32768;
	public const uint32 D3DCOMPILE_RESERVED16 = 65536;
	public const uint32 D3DCOMPILE_RESERVED17 = 131072;
	public const uint32 D3DCOMPILE_WARNINGS_ARE_ERRORS = 262144;
	public const uint32 D3DCOMPILE_RESOURCES_MAY_ALIAS = 524288;
	public const uint32 D3DCOMPILE_ENABLE_UNBOUNDED_DESCRIPTOR_TABLES = 1048576;
	public const uint32 D3DCOMPILE_ALL_RESOURCES_BOUND = 2097152;
	public const uint32 D3DCOMPILE_DEBUG_NAME_FOR_SOURCE = 4194304;
	public const uint32 D3DCOMPILE_DEBUG_NAME_FOR_BINARY = 8388608;
	public const uint32 D3DCOMPILE_EFFECT_CHILD_EFFECT = 1;
	public const uint32 D3DCOMPILE_EFFECT_ALLOW_SLOW_OPS = 2;
	public const uint32 D3DCOMPILE_FLAGS2_FORCE_ROOT_SIGNATURE_LATEST = 0;
	public const uint32 D3DCOMPILE_FLAGS2_FORCE_ROOT_SIGNATURE_1_0 = 16;
	public const uint32 D3DCOMPILE_FLAGS2_FORCE_ROOT_SIGNATURE_1_1 = 32;
	public const uint32 D3DCOMPILE_SECDATA_MERGE_UAV_SLOTS = 1;
	public const uint32 D3DCOMPILE_SECDATA_PRESERVE_TEMPLATE_SLOTS = 2;
	public const uint32 D3DCOMPILE_SECDATA_REQUIRE_TEMPLATE_MATCH = 4;
	public const uint32 D3D_DISASM_ENABLE_COLOR_CODE = 1;
	public const uint32 D3D_DISASM_ENABLE_DEFAULT_VALUE_PRINTS = 2;
	public const uint32 D3D_DISASM_ENABLE_INSTRUCTION_NUMBERING = 4;
	public const uint32 D3D_DISASM_ENABLE_INSTRUCTION_CYCLE = 8;
	public const uint32 D3D_DISASM_DISABLE_DEBUG_INFO = 16;
	public const uint32 D3D_DISASM_ENABLE_INSTRUCTION_OFFSET = 32;
	public const uint32 D3D_DISASM_INSTRUCTION_ONLY = 64;
	public const uint32 D3D_DISASM_PRINT_HEX_LITERALS = 128;
	public const uint32 D3D_GET_INST_OFFSETS_INCLUDE_NON_EXECUTABLE = 1;
	public const uint32 D3D_COMPRESS_SHADER_KEEP_ALL_PARTS = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum D3DCOMPILER_STRIP_FLAGS : int32
{
	D3DCOMPILER_STRIP_REFLECTION_DATA = 1,
	D3DCOMPILER_STRIP_DEBUG_INFO = 2,
	D3DCOMPILER_STRIP_TEST_BLOBS = 4,
	D3DCOMPILER_STRIP_PRIVATE_DATA = 8,
	D3DCOMPILER_STRIP_ROOT_SIGNATURE = 16,
	D3DCOMPILER_STRIP_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum D3D_BLOB_PART : int32
{
	D3D_BLOB_INPUT_SIGNATURE_BLOB = 0,
	D3D_BLOB_OUTPUT_SIGNATURE_BLOB = 1,
	D3D_BLOB_INPUT_AND_OUTPUT_SIGNATURE_BLOB = 2,
	D3D_BLOB_PATCH_CONSTANT_SIGNATURE_BLOB = 3,
	D3D_BLOB_ALL_SIGNATURE_BLOB = 4,
	D3D_BLOB_DEBUG_INFO = 5,
	D3D_BLOB_LEGACY_SHADER = 6,
	D3D_BLOB_XNA_PREPASS_SHADER = 7,
	D3D_BLOB_XNA_SHADER = 8,
	D3D_BLOB_PDB = 9,
	D3D_BLOB_PRIVATE_DATA = 10,
	D3D_BLOB_ROOT_SIGNATURE = 11,
	D3D_BLOB_DEBUG_NAME = 12,
	D3D_BLOB_TEST_ALTERNATE_SHADER = 32768,
	D3D_BLOB_TEST_COMPILE_DETAILS = 32769,
	D3D_BLOB_TEST_COMPILE_PERF = 32770,
	D3D_BLOB_TEST_COMPILE_REPORT = 32771,
}

#endregion

#region Function Pointers
public function HRESULT pD3DCompile(void* pSrcData, uint SrcDataSize, PSTR pFileName, D3D_SHADER_MACRO* pDefines, ID3DInclude* pInclude, PSTR pEntrypoint, PSTR pTarget, uint32 Flags1, uint32 Flags2, ID3DBlob** ppCode, ID3DBlob** ppErrorMsgs);

public function HRESULT pD3DPreprocess(void* pSrcData, uint SrcDataSize, PSTR pFileName, D3D_SHADER_MACRO* pDefines, ID3DInclude* pInclude, ID3DBlob** ppCodeText, ID3DBlob** ppErrorMsgs);

public function HRESULT pD3DDisassemble(void* pSrcData, uint SrcDataSize, uint32 Flags, PSTR szComments, ID3DBlob** ppDisassembly);

#endregion

#region Structs
[CRepr]
public struct D3D_SHADER_DATA
{
	public void* pBytecode;
	public uint BytecodeLength;
}

#endregion

#region Functions
public static
{
	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DReadFileToBlob(PWSTR pFileName, ID3DBlob** ppContents);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DWriteBlobToFile(ID3DBlob* pBlob, PWSTR pFileName, BOOL bOverwrite);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCompile(void* pSrcData, uint SrcDataSize, PSTR pSourceName, D3D_SHADER_MACRO* pDefines, ID3DInclude* pInclude, PSTR pEntrypoint, PSTR pTarget, uint32 Flags1, uint32 Flags2, ID3DBlob** ppCode, ID3DBlob** ppErrorMsgs);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCompile2(void* pSrcData, uint SrcDataSize, PSTR pSourceName, D3D_SHADER_MACRO* pDefines, ID3DInclude* pInclude, PSTR pEntrypoint, PSTR pTarget, uint32 Flags1, uint32 Flags2, uint32 SecondaryDataFlags, void* pSecondaryData, uint SecondaryDataSize, ID3DBlob** ppCode, ID3DBlob** ppErrorMsgs);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCompileFromFile(PWSTR pFileName, D3D_SHADER_MACRO* pDefines, ID3DInclude* pInclude, PSTR pEntrypoint, PSTR pTarget, uint32 Flags1, uint32 Flags2, ID3DBlob** ppCode, ID3DBlob** ppErrorMsgs);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DPreprocess(void* pSrcData, uint SrcDataSize, PSTR pSourceName, D3D_SHADER_MACRO* pDefines, ID3DInclude* pInclude, ID3DBlob** ppCodeText, ID3DBlob** ppErrorMsgs);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DGetDebugInfo(void* pSrcData, uint SrcDataSize, ID3DBlob** ppDebugInfo);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DReflect(void* pSrcData, uint SrcDataSize, in Guid pInterface, void** ppReflector);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DReflectLibrary(void* pSrcData, uint SrcDataSize, in Guid riid, void** ppReflector);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DDisassemble(void* pSrcData, uint SrcDataSize, uint32 Flags, PSTR szComments, ID3DBlob** ppDisassembly);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DDisassembleRegion(void* pSrcData, uint SrcDataSize, uint32 Flags, PSTR szComments, uint StartByteOffset, uint NumInsts, uint* pFinishByteOffset, ID3DBlob** ppDisassembly);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCreateLinker(ID3D11Linker** ppLinker);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DLoadModule(void* pSrcData, uint cbSrcDataSize, ID3D11Module** ppModule);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCreateFunctionLinkingGraph(uint32 uFlags, ID3D11FunctionLinkingGraph** ppFunctionLinkingGraph);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DGetTraceInstructionOffsets(void* pSrcData, uint SrcDataSize, uint32 Flags, uint StartInstIndex, uint NumInsts, uint* pOffsets, uint* pTotalInsts);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DGetInputSignatureBlob(void* pSrcData, uint SrcDataSize, ID3DBlob** ppSignatureBlob);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DGetOutputSignatureBlob(void* pSrcData, uint SrcDataSize, ID3DBlob** ppSignatureBlob);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DGetInputAndOutputSignatureBlob(void* pSrcData, uint SrcDataSize, ID3DBlob** ppSignatureBlob);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DStripShader(void* pShaderBytecode, uint BytecodeLength, uint32 uStripFlags, ID3DBlob** ppStrippedBlob);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DGetBlobPart(void* pSrcData, uint SrcDataSize, D3D_BLOB_PART Part, uint32 Flags, ID3DBlob** ppPart);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DSetBlobPart(void* pSrcData, uint SrcDataSize, D3D_BLOB_PART Part, uint32 Flags, void* pPart, uint PartSize, ID3DBlob** ppNewShader);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCreateBlob(uint Size, ID3DBlob** ppBlob);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DCompressShaders(uint32 uNumShaders, D3D_SHADER_DATA* pShaderData, uint32 uFlags, ID3DBlob** ppCompressedData);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DDecompressShaders(void* pSrcData, uint SrcDataSize, uint32 uNumShaders, uint32 uStartIndex, uint32* pIndices, uint32 uFlags, ID3DBlob** ppShaders, uint32* pTotalShaders);

	[Import("D3DCOMPILER_47.dll"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT D3DDisassemble10Effect(ID3D10Effect* pEffect, uint32 Flags, ID3DBlob** ppDisassembly);

}
#endregion
