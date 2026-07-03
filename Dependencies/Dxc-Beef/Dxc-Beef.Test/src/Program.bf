using System;
using Dxc_Beef;
using System.Collections;
using System.Diagnostics;
using System.IO;
namespace Dxc_Beef.Test;

class Program
{
	public static void Main(String[] args)
	{
		IDxcLibrary* pLibrary = null;
		var result = Dxc.CreateInstance(out pLibrary);
		if (result != .S_OK)
			return;

		IDxcBlobEncoding* pSource = null;

		uint32 codePage = 0;

		String shadersPath = Path.InternalCombine(.. scope .(), Directory.GetCurrentDirectory(.. scope String()), "shaders");

		result = pLibrary.CreateBlobFromFile(Path.InternalCombine(.. scope .(), shadersPath, "shader.hlsl"), &codePage, out pSource);
		if (result != .S_OK)
			return;

		List<StringView> arguments = scope .();
		{
			arguments.Add("-E");
			arguments.Add("PSMain");

			arguments.Add("-T");
			arguments.Add("ps_6_2");

			arguments.Add("-Qstrip_debug");
			arguments.Add("-Qstrip_reflect");

			arguments.Add(DXC_ARG_WARNINGS_ARE_ERRORS);
			arguments.Add(DXC_ARG_DEBUG);
			arguments.Add(DXC_ARG_PACK_MATRIX_ROW_MAJOR);
		}

		IDxcCompiler3* pCompiler = null;

		result = Dxc.CreateInstance(out pCompiler);
		if (result != .S_OK)
			return;

		DxcBuffer buffer = .()
			{
				Ptr = pSource.GetBufferPointer(),
				Size = (uint)pSource.GetBufferSize(),
				Encoding = 0
			};

		IncludeHandler includeHandler = .(pLibrary, shadersPath);

		result = pCompiler.Compile(&buffer, arguments, &includeHandler, ref IDxcResult.sIID, var ppResult);
		if (result != .S_OK)
			return;

		IDxcResult* pResult = (.)ppResult;

		result = pResult.GetStatus(var status);

		if (status != .S_OK)
		{
			IDxcBlobEncoding* pErrors = null;
			result = pResult.GetErrorBuffer(out pErrors);
			if (pErrors != null && pErrors.GetBufferSize() > 0)
			{
				Debug.WriteLine(scope String((char8*)pErrors.GetBufferPointer()));
			}
			return;
		}

		IDxcBlob* pBlob = null;

		result = pResult.GetResult(out pBlob);
		if (result != .S_OK)
			return;

		List<uint8> data = scope .();

		data.AddRange(Span<uint8>((.)pBlob.GetBufferPointer(), (int)pBlob.GetBufferSize()));

		String outputFile = Path.InternalCombine(.. scope .(), shadersPath, "cache", "compiled_shader.dxil");

		if (File.WriteAll(outputFile, data) case .Err)
		{
			Debug.WriteLine($"Failed to write compiled shader.");
			return;
		}

		Console.WriteLine("Shader compilation successful.\nOutput file: {0}\n", outputFile);

		Console.WriteLine("Press [Enter] to exit.");

		Console.Read();
	}
}