namespace SampleFramework;

using System;
using System.Collections;
using Dxc_Beef;

/// Output format for compiled shaders.
enum ShaderOutputFormat
{
	/// DXIL bytecode (for DX12).
	DXIL,
	/// SPIR-V bytecode (for Vulkan).
	SPIRV,
}

/// Compiles HLSL source to DXIL or SPIR-V using the DXC compiler.
class ShaderCompiler
{
	private IDxcCompiler3* mCompiler;
	private IDxcUtils* mUtils;
	private IDxcIncludeHandler* mIncludeHandler;
	private bool mInitialized;

	/// Optimization level (0-3). Default: 3.
	public int OptimizationLevel = 3;

	/// Whether to enable debug info.
	public bool EnableDebugInfo = false;

	/// Binding shift for SRV/textures (SPIRV only). Matches VulkanBindingShifts.Standard.
	public uint32 SrvShift = 1000;

	/// Binding shift for UAVs (SPIRV only).
	public uint32 UavShift = 2000;

	/// Binding shift for samplers (SPIRV only).
	public uint32 SamplerShift = 3000;

	/// Binding shift for constant buffers (SPIRV only). Usually 0.
	public uint32 CbvShift = 0;

	public Result<void> Init()
	{
		if (mInitialized) return .Ok;

		if (Dxc.CreateInstance<IDxcCompiler3>(out mCompiler) != .S_OK)
			return .Err;

		if (Dxc.CreateInstance<IDxcUtils>(out mUtils) != .S_OK)
		{
			mCompiler.Release(); mCompiler = null;
			return .Err;
		}

		if (mUtils.CreateDefaultIncludeHandler(out mIncludeHandler) != .S_OK)
		{
			mUtils.Release(); mUtils = null;
			mCompiler.Release(); mCompiler = null;
			return .Err;
		}

		mInitialized = true;
		return .Ok;
	}

	/// Compiles HLSL source code to shader bytecode.
	/// - source: HLSL source text
	/// - entryPoint: Entry point function name (e.g. "VSMain")
	/// - profile: Shader profile (e.g. "vs_6_0", "ps_6_0", "cs_6_0")
	/// - format: Output format (DXIL or SPIRV)
	/// - outBytecode: Receives the compiled bytecode. Caller owns the list.
	/// - outErrors: Optional — receives error/warning messages. Caller owns the string.
	public Result<void> Compile(StringView source, StringView entryPoint, StringView profile,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		if (!mInitialized) return .Err;

		// Build arguments
		List<StringView> args = scope .();
		args.Add("-E");
		args.Add(entryPoint);
		args.Add("-T");
		args.Add(profile);

		// Optimization
		switch (OptimizationLevel)
		{
		case 0: args.Add(DXC_ARG_OPTIMIZATION_LEVEL0);
		case 1: args.Add(DXC_ARG_OPTIMIZATION_LEVEL1);
		case 2: args.Add(DXC_ARG_OPTIMIZATION_LEVEL2);
		default: args.Add(DXC_ARG_OPTIMIZATION_LEVEL3);
		}

		if (EnableDebugInfo)
			args.Add(DXC_ARG_DEBUG);

		// SPIRV target with register shifts
		if (format == .SPIRV)
		{
			args.Add("-spirv");
			args.Add("-fspv-target-env=vulkan1.3");
			args.Add("-fspv-extension=SPV_EXT_mesh_shader");
			args.Add("-fspv-extension=SPV_KHR_ray_tracing");

			for (int32 setIdx = 0; setIdx < 4; setIdx++)
			{
				String setStr = scope:: .();
				setStr.AppendF("{}", setIdx);

				if (CbvShift > 0)
				{
					args.Add("-fvk-b-shift");
					String s = scope:: .();
					s.AppendF("{}", CbvShift);
					args.Add(s);
					args.Add(setStr);
				}

				if (SrvShift > 0)
				{
					args.Add("-fvk-t-shift");
					String s = scope:: .();
					s.AppendF("{}", SrvShift);
					args.Add(s);
					args.Add(setStr);
				}

				if (UavShift > 0)
				{
					args.Add("-fvk-u-shift");
					String s = scope:: .();
					s.AppendF("{}", UavShift);
					args.Add(s);
					args.Add(setStr);
				}

				if (SamplerShift > 0)
				{
					args.Add("-fvk-s-shift");
					String s = scope:: .();
					s.AppendF("{}", SamplerShift);
					args.Add(s);
					args.Add(setStr);
				}
			}
		}

		// Create source buffer
		DxcBuffer srcBuffer = .()
		{
			Ptr = source.Ptr,
			Size = (uint)source.Length,
			Encoding = DXC_CP_UTF8
		};

		// Compile
		void** ppResult = null;
		let hr = mCompiler.Compile(&srcBuffer, args, mIncludeHandler, ref IDxcResult.IID, out ppResult);
		if (hr != .S_OK || ppResult == null)
		{
			outErrors?.AppendF("DXC Compile call failed with HRESULT: {}", (int32)hr);
			return .Err;
		}

		IDxcResult* result = (.)ppResult;
		defer result.Release();

		// Check status
		HRESULT status = .S_OK;
		result.GetStatus(out status);

		// Get error messages
		if (result.HasOutput(.DXC_OUT_ERRORS))
		{
			void** errorPtr = null;
			IDxcBlobWide* errorName = null;
			if (result.GetOutput(.DXC_OUT_ERRORS, ref IDxcBlobUtf8.IID, out errorPtr, out errorName) == .S_OK && errorPtr != null)
			{
				IDxcBlobUtf8* errorBlob = (.)errorPtr;
				let errorStr = errorBlob.GetStringPointer();
				let errorLen = errorBlob.GetStringLength();
				if (errorStr != null && errorLen > 0)
				{
					let msg = StringView(errorStr, errorLen);
					outErrors?.Append(msg);

					if (status != .S_OK)
						System.Diagnostics.Debug.WriteLine(scope String()..AppendF("[ShaderCompiler ERROR] {}", msg));
				}
				errorBlob.Release();
				if (errorName != null)
					errorName.Release();
			}
		}

		if (status != .S_OK)
			return .Err;

		// Get compiled bytecode
		if (result.HasOutput(.DXC_OUT_OBJECT))
		{
			void** objectPtr = null;
			IDxcBlobWide* objectName = null;
			if (result.GetOutput(.DXC_OUT_OBJECT, ref IDxcBlob.sIID, out objectPtr, out objectName) == .S_OK && objectPtr != null)
			{
				IDxcBlob* blob = (.)objectPtr;
				let ptr = (uint8*)blob.GetBufferPointer();
				let size = blob.GetBufferSize();

				if (ptr != null && size > 0)
					outBytecode.AddRange(Span<uint8>(ptr, (int)size));

				blob.Release();
				if (objectName != null)
					objectName.Release();
			}
		}

		return .Ok;
	}

	/// Convenience: compile a vertex shader.
	public Result<void> CompileVertex(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "vs_6_0", format, outBytecode, outErrors);
	}

	/// Convenience: compile a pixel/fragment shader.
	public Result<void> CompilePixel(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "ps_6_0", format, outBytecode, outErrors);
	}

	/// Convenience: compile a compute shader.
	public Result<void> CompileCompute(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "cs_6_0", format, outBytecode, outErrors);
	}

	/// Convenience: compile a mesh shader (SM 6.5+).
	public Result<void> CompileMesh(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "ms_6_5", format, outBytecode, outErrors);
	}

	/// Convenience: compile an amplification/task shader (SM 6.5+).
	public Result<void> CompileAmplification(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "as_6_5", format, outBytecode, outErrors);
	}

	/// Convenience: compile a ray generation shader (SM 6.3+).
	public Result<void> CompileRayGeneration(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "lib_6_3", format, outBytecode, outErrors);
	}

	/// Convenience: compile a ray tracing library (closest hit, miss, any hit, etc.) (SM 6.3+).
	public Result<void> CompileRayTracingLib(StringView source, StringView entryPoint,
		ShaderOutputFormat format, List<uint8> outBytecode, String outErrors = null)
	{
		return Compile(source, entryPoint, "lib_6_3", format, outBytecode, outErrors);
	}

	public void Destroy()
	{
		if (mIncludeHandler != null) { mIncludeHandler.Release(); mIncludeHandler = null; }
		if (mUtils != null) { mUtils.Release(); mUtils = null; }
		if (mCompiler != null) { mCompiler.Release(); mCompiler = null; }
		mInitialized = false;
	}
}
