namespace Sedulous.Shaders;

using System;
using System.Collections;
using Sedulous.RHI;
using Dxc_Beef;
using System.Diagnostics;
/// Shader compilation target format.
enum ShaderTarget
{
	/// SPIRV bytecode (Vulkan).
	SPIRV,
	/// DXIL bytecode (Direct3D 12).
	DXIL
}

/// Result of shader compilation.
struct CompilationResult : IDisposable
{
	/// Whether compilation succeeded.
	public bool Success;

	/// Compiled bytecode (owned, must be deleted).
	public uint8[] Bytecode;

	/// Error/warning messages.
	public String Messages;

	public void Dispose() mut
	{
		delete Bytecode;
		delete Messages;
	}
}

/// Wraps DXC (DirectX Shader Compiler) for HLSL compilation.
/// Compiles HLSL source to SPIRV or DXIL bytecode.
class ShaderCompiler : IDisposable
{
	private IDxcCompiler3* mCompiler;
	private IDxcUtils* mUtils;
	private IDxcIncludeHandler* mIncludeHandler;
	private bool mInitialized = false;

	/// Default shader model to target.
	public StringView ShaderModel = "6_0";

	/// Whether to enable debug info.
	public bool EnableDebugInfo = false;

	/// Whether to use row-major matrix packing.
	public bool RowMajorMatrices = true;

	/// Optimization level (0-3).
	public int OptimizationLevel = 3;

	/// Binding shift for textures (SPIRV only). Default matches RHI.Vulkan shifts.
	public uint32 TextureShift = 1000;

	/// Binding shift for samplers (SPIRV only). Default matches RHI.Vulkan shifts.
	public uint32 SamplerShift = 3000;

	/// Binding shift for UAVs (SPIRV only). Default matches RHI.Vulkan shifts.
	public uint32 UAVShift = 2000;

	/// Binding shift for constant buffers (SPIRV only). Usually 0.
	public uint32 ConstantBufferShift = 0;

	/// Include paths for shader compilation.
	private List<String> mIncludePaths = new .() ~ DeleteContainerAndItems!(_);

	/// Initializes the DXC compiler.
	public Result<void> Initialize()
	{
		if (mInitialized)
			return .Ok;

		// Create compiler instance
		if (Dxc.CreateInstance<IDxcCompiler3>(out mCompiler) != .S_OK)
			return .Err;

		// Create utils instance
		if (Dxc.CreateInstance<IDxcUtils>(out mUtils) != .S_OK)
		{
			if (mCompiler != null)
				mCompiler.Release();
			mCompiler = null;
			return .Err;
		}

		// Create default include handler
		if (mUtils.CreateDefaultIncludeHandler(out mIncludeHandler) != .S_OK)
		{
			mUtils.Release();
			mCompiler.Release();
			mUtils = null;
			mCompiler = null;
			return .Err;
		}

		mInitialized = true;
		return .Ok;
	}

	/// Adds an include path for shader compilation.
	public void AddIncludePath(StringView path)
	{
		mIncludePaths.Add(new String(path));
	}

	/// Compiles HLSL source code to bytecode.
	public CompilationResult Compile(
		StringView source,
		ShaderVariantKey key,
		ShaderTarget target = .SPIRV,
		StringView entryPoint = default)
	{
		var result = CompilationResult();
		result.Messages = new String();

		if (!mInitialized)
		{
			result.Messages.Append("Shader compiler not initialized");
			return result;
		}

		// Prepend #defines from shader flags and target backend
		String fullSource = scope .();

		// Add backend-specific define
		switch (target)
		{
		case .SPIRV:
			fullSource.Append("#define VULKAN 1\n");
		case .DXIL:
			fullSource.Append("#define DX12 1\n");
		}

		key.Flags.AppendDefines(fullSource);
		fullSource.Append(source);

		// Build arguments
		List<StringView> args = scope .();

		// Entry point
		String entryPointStr = scope .();
		if (entryPoint.IsEmpty)
			key.GetDefaultEntryPoint(entryPointStr);
		else
			entryPointStr.Append(entryPoint);

		args.Add("-E");
		args.Add(entryPointStr);

		// Target profile
		String targetProfile = scope .();
		key.GetTargetProfile(targetProfile, ShaderModel);
		args.Add("-T");
		args.Add(targetProfile);

		// SPIRV target
		if (target == .SPIRV)
		{
			args.Add("-spirv");
			args.Add("-fspv-target-env=vulkan1.2");
			//args.Add("-fvk-use-dx-layout");

			// Binding shifts for Vulkan to avoid conflicts between resource types
			// Apply to all descriptor sets
			for (int32 setIndex = 0; setIndex < 5; setIndex++)
			{
				String setStr = scope:: .();
				setStr.AppendF("{}", setIndex);

				if (ConstantBufferShift > 0)
				{
					args.Add("-fvk-b-shift");
					String shiftStr = scope:: .();
					shiftStr.AppendF("{}", ConstantBufferShift);
					args.Add(shiftStr);
					args.Add(setStr);
				}

				if (TextureShift > 0)
				{
					args.Add("-fvk-t-shift");
					String shiftStr = scope:: .();
					shiftStr.AppendF("{}", TextureShift);
					args.Add(shiftStr);
					args.Add(setStr);
				}

				if (SamplerShift > 0)
				{
					args.Add("-fvk-s-shift");
					String shiftStr = scope:: .();
					shiftStr.AppendF("{}", SamplerShift);
					args.Add(shiftStr);
					args.Add(setStr);
				}

				if (UAVShift > 0)
				{
					args.Add("-fvk-u-shift");
					String shiftStr = scope:: .();
					shiftStr.AppendF("{}", UAVShift);
					args.Add(shiftStr);
					args.Add(setStr);
				}
			}
		}

		// Matrix packing
		/*if (RowMajorMatrices)
			args.Add(DXC_ARG_PACK_MATRIX_ROW_MAJOR);
		else
			args.Add(DXC_ARG_PACK_MATRIX_COLUMN_MAJOR);*/

		// Optimization level
		switch (OptimizationLevel)
		{
		case 0: args.Add(DXC_ARG_OPTIMIZATION_LEVEL0);
		case 1: args.Add(DXC_ARG_OPTIMIZATION_LEVEL1);
		case 2: args.Add(DXC_ARG_OPTIMIZATION_LEVEL2);
		default: args.Add(DXC_ARG_OPTIMIZATION_LEVEL3);
		}

		// Debug info
		if (EnableDebugInfo)
			args.Add(DXC_ARG_DEBUG);

		// Include paths
		for (let includePath in mIncludePaths)
		{
			args.Add("-I");
			args.Add(includePath);
		}

		// Warnings
		args.Add("-Wno-ignored-attributes");

		// Create source buffer
		DxcBuffer sourceBuffer = .()
		{
			Ptr = fullSource.Ptr,
			Size = (.)fullSource.Length,
			Encoding = DXC_CP_UTF8
		};

		// Compile
		void** resultPtr = null;
		let hr = mCompiler.Compile(&sourceBuffer, args, mIncludeHandler, ref IDxcResult.IID, out resultPtr);

		if (hr != .S_OK || resultPtr == null)
		{
			result.Messages.AppendF("DXC compilation failed with HRESULT: {}", (int32)hr);
			return result;
		}

		IDxcResult* dxcResult = (.)resultPtr;
		defer dxcResult.Release();

		// Check status
		HRESULT status = .S_OK;
		dxcResult.GetStatus(out status);

		// Get error messages
		if (dxcResult.HasOutput(.DXC_OUT_ERRORS))
		{
			void** errorPtr = null;
			IDxcBlobWide* errorName = null;
			if (dxcResult.GetOutput(.DXC_OUT_ERRORS, ref IDxcBlobUtf8.IID, out errorPtr, out errorName) == .S_OK && errorPtr != null)
			{
				IDxcBlobUtf8* errorBlob = (.)errorPtr;
				let errorStr = errorBlob.GetStringPointer();
				let errorLen = errorBlob.GetStringLength();
				if (errorStr != null && errorLen > 0)
					result.Messages.Append(StringView(errorStr, errorLen));
				errorBlob.Release();
				if (errorName != null)
					errorName.Release();
			}
		}

		if (status != .S_OK)
			return result;

		// Get compiled bytecode
		if (dxcResult.HasOutput(.DXC_OUT_OBJECT))
		{
			void** objectPtr = null;
			IDxcBlobWide* objectName = null;
			if (dxcResult.GetOutput(.DXC_OUT_OBJECT, ref IDxcBlob.sIID, out objectPtr, out objectName) == .S_OK && objectPtr != null)
			{
				IDxcBlob* objectBlob = (.)objectPtr;
				let bytecodePtr = (uint8*)objectBlob.GetBufferPointer();
				let bytecodeSize = objectBlob.GetBufferSize();

				if (bytecodePtr != null && bytecodeSize > 0)
				{
					result.Bytecode = new uint8[bytecodeSize];
					Internal.MemCpy(result.Bytecode.Ptr, bytecodePtr, (int)bytecodeSize);
					result.Success = true;
				}

				objectBlob.Release();
				if (objectName != null)
					objectName.Release();
			}
		}

		return result;
	}

	/// Compiles HLSL source and returns a ShaderModule.
	public Result<ShaderModule> CompileToModule(
		StringView source,
		ShaderVariantKey key,
		ShaderTarget target = .SPIRV,
		StringView entryPoint = default,
		IDevice device = null)
	{
		var compileResult = Compile(source, key, target, entryPoint);
		defer compileResult.Dispose();

		if (!compileResult.Success)
		{
			// Log error
			if (!compileResult.Messages.IsEmpty){
				Console.WriteLine("Shader compilation failed: {}", compileResult.Messages);
				Debug.WriteLine("Shader compilation failed: {}", compileResult.Messages);
			}
			return .Err;
		}

		return new ShaderModule(key, compileResult.Bytecode, device);
	}

	public void Dispose()
	{
		if (mIncludeHandler != null)
		{
			mIncludeHandler.Release();
			mIncludeHandler = null;
		}

		if (mUtils != null)
		{
			mUtils.Release();
			mUtils = null;
		}

		if (mCompiler != null)
		{
			mCompiler.Release();
			mCompiler = null;
		}

		mInitialized = false;
	}
}
