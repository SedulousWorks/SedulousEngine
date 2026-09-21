using System;
using System.Collections;
using Dxc_Beef;
using Sedulous.Core;

namespace Sedulous.Shaders;

/// Compiles HLSL to SPIR-V or DXIL through DXC.
///
/// Stateless with respect to shaders: it holds only the DXC interfaces, and everything about
/// a particular compile arrives in CompileOptions. The layer that caches variants sits above
/// this and is what needs an RHI device; this one has none, which is what lets it be used by
/// a cook that never opens a device.
///
/// The Beef binding links dxcompiler directly and widens the argument strings itself, so
/// there is no manual library loading here and no hand rolled UTF-8 to wide conversion.
class ShaderCompiler
{
	private IDxcCompiler3* mCompiler = null;
	private IDxcUtils* mUtils = null;
	private IDxcIncludeHandler* mIncludeHandler = null;
	private bool mInitialized = false;

	public bool IsInitialized => mInitialized;

	public ~this()
	{
		Shutdown();
	}

	/// Creates the DXC interfaces.
	///
	/// Idempotent, so a second call on a live compiler is a no-op rather than a leak of the
	/// first set.
	public Result<void> Initialize()
	{
		if (mInitialized)
			return .Ok;

		if (Dxc.CreateInstance<IDxcCompiler3>(out mCompiler) != .S_OK)
		{
			Console.Error.WriteLine("Sedulous.Shaders: DxcCreateInstance(IDxcCompiler3) failed");
			Shutdown();
			return .Err;
		}
		if (Dxc.CreateInstance<IDxcUtils>(out mUtils) != .S_OK)
		{
			Console.Error.WriteLine("Sedulous.Shaders: DxcCreateInstance(IDxcUtils) failed");
			Shutdown();
			return .Err;
		}
		// The default handler resolves #include against the -I paths, which is what makes a
		// shared .hlsli work.
		if (mUtils.CreateDefaultIncludeHandler(out mIncludeHandler) != .S_OK)
		{
			Console.Error.WriteLine("Sedulous.Shaders: CreateDefaultIncludeHandler failed");
			Shutdown();
			return .Err;
		}

		mInitialized = true;
		return .Ok;
	}

	public void Shutdown()
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

	/// Compiles `source` for one stage.
	///
	/// A failed compile is a RESULT, not an error: the caller wants the messages, and losing
	/// them would turn a shader typo into an unexplained refusal. The returned result owns
	/// its arrays.
	public CompileResult Compile(Span<uint8> source, ShaderStage stage, StringView entryPoint,
		ShaderTarget target, CompileOptions options)
	{
		CompileResult result = .();
		result.Messages = new String();

		if (!mInitialized)
		{
			result.Messages.Append("the shader compiler was not initialized");
			return result;
		}

		// The argument strings must outlive the Compile call, so they are scoped here rather
		// than built inside the helpers. OWNED: the list's own scope frees the list, not the
		// strings in it.
		let storage = scope List<String>();
		defer { ClearAndDeleteItems!(storage); }
		let arguments = scope List<StringView>();
		BuildArguments(stage, entryPoint, target, options, storage, arguments);

		DxcBuffer sourceBuffer = .()
			{
				Ptr = source.Ptr,
				Size = (uint)source.Length,
				Encoding = DXC_CP_UTF8
			};

		// A compile carrying a resolver gets its own handler, built on the stack for this one
		// call: DXC does not retain it, and the resolver it forwards to is the caller's.
		var resolverHandler = ResolverIncludeHandler(mUtils, options.IncludeResolver);
		let handler = (options.IncludeResolver != null) ? resolverHandler.Handle : mIncludeHandler;

		void** resultPointer = null;
		let hr = mCompiler.Compile(&sourceBuffer, arguments, handler,
			ref IDxcResult.IID, out resultPointer);
		if ((hr != .S_OK) || (resultPointer == null))
		{
			result.Messages.AppendF("IDxcCompiler3::Compile returned HRESULT {}", (int32)hr);
			return result;
		}

		IDxcResult* dxcResult = (.)resultPointer;
		defer dxcResult.Release();

		CollectMessages(dxcResult, result.Messages);

		HRESULT status = .S_OK;
		dxcResult.GetStatus(out status);
		if (status != .S_OK)
			return result;

		CollectBytecode(dxcResult, ref result);
		return result;
	}

	/// The DXC command line for a compile.
	///
	/// Owned strings go into `storage` and views of them into `arguments`, because DXC takes
	/// the arguments as views and several of them are built rather than literal.
	private static void BuildArguments(ShaderStage stage, StringView entryPoint,
		ShaderTarget target, CompileOptions options, List<String> storage,
		List<StringView> arguments)
	{
		String Own(StringView text)
		{
			let owned = new String(text);
			storage.Add(owned);
			return owned;
		}

		arguments.Add("-E");
		arguments.Add(Own(entryPoint.IsEmpty ? "main" : entryPoint));

		let profile = Own("");
		profile.AppendF("{}_{}", StageProfilePrefix(stage), options.ShaderModel);
		arguments.Add("-T");
		arguments.Add(profile);

		if (target == .SPIRV)
			AppendSpirvArguments(options, storage, arguments);

		// Zpr is row major, Zpc column major. The engine is row vector and row major, but a
		// shader compiled the other way still works as long as the CPU side agrees, so this
		// stays an option rather than a constant.
		arguments.Add(options.RowMajorMatrices ? "-Zpr" : "-Zpc");

		switch (options.OptimizationLevel)
		{
		case 0: arguments.Add("-O0");
		case 1: arguments.Add("-O1");
		case 2: arguments.Add("-O2");
		default: arguments.Add("-O3");
		}

		if (options.EnableDebugInfo)
			arguments.Add("-Zi");

		for (let define in options.Defines)
		{
			let argument = Own("-D");
			argument.Append(define.Name);
			if (!define.Value.IsEmpty)
			{
				argument.Append("=");
				argument.Append(define.Value);
			}
			arguments.Add(argument);
		}

		for (let path in options.IncludePaths)
		{
			if (options.IncludeResolver != null)
				break; // the resolver answers every include, so -I would never be reached
			arguments.Add("-I");
			arguments.Add(Own(path));
		}

		// HLSL carries attributes that mean nothing to one backend or the other, and the
		// warning is noise rather than signal.
		arguments.Add("-Wno-ignored-attributes");
	}

	private static void AppendSpirvArguments(CompileOptions options, List<String> storage,
		List<StringView> arguments)
	{
		String Own(StringView text)
		{
			let owned = new String(text);
			storage.Add(owned);
			return owned;
		}

		arguments.Add("-spirv");
		let targetEnvironment = Own("-fspv-target-env=");
		targetEnvironment.Append(options.SpirvTargetEnvironment);
		arguments.Add(targetEnvironment);

		// DXC takes a shift PER descriptor set, so a shader that uses set 3 needs the shift
		// declared for set 3 or its bindings land unshifted.
		for (uint32 set = 0; set < options.BindingShiftSets; ++set)
		{
			let setText = Own("");
			setText.AppendF("{}", set);

			void PushShift(StringView flag, uint32 shift)
			{
				// A zero shift is the identity, and passing it would only lengthen the
				// command line.
				if (shift == 0)
					return;
				let shiftText = Own("");
				shiftText.AppendF("{}", shift);
				arguments.Add(flag);
				arguments.Add(shiftText);
				arguments.Add(setText);
			}

			PushShift("-fvk-b-shift", options.BindingShifts.ConstantBufferShift);
			PushShift("-fvk-t-shift", options.BindingShifts.TextureShift);
			PushShift("-fvk-s-shift", options.BindingShifts.SamplerShift);
			PushShift("-fvk-u-shift", options.BindingShifts.UavShift);
		}
	}

	/// Diagnostics, which are collected whether or not the compile succeeded.
	private static void CollectMessages(IDxcResult* dxcResult, String outMessages)
	{
		if (!dxcResult.HasOutput(.DXC_OUT_ERRORS))
			return;

		void** errorPointer = null;
		IDxcBlobWide* errorName = null;
		if ((dxcResult.GetOutput(.DXC_OUT_ERRORS, ref IDxcBlobUtf8.IID, out errorPointer,
			out errorName) != .S_OK) || (errorPointer == null))
			return;

		IDxcBlobUtf8* errorBlob = (.)errorPointer;
		let text = errorBlob.GetStringPointer();
		let length = errorBlob.GetStringLength();
		if ((text != null) && (length > 0))
			outMessages.Append(StringView(text, (int)length));

		errorBlob.Release();
		if (errorName != null)
			errorName.Release();
	}

	private static void CollectBytecode(IDxcResult* dxcResult, ref CompileResult result)
	{
		if (!dxcResult.HasOutput(.DXC_OUT_OBJECT))
			return;

		void** objectPointer = null;
		IDxcBlobWide* objectName = null;
		if ((dxcResult.GetOutput(.DXC_OUT_OBJECT, ref IDxcBlob.sIID, out objectPointer,
			out objectName) != .S_OK) || (objectPointer == null))
			return;

		IDxcBlob* objectBlob = (.)objectPointer;
		let bytes = (uint8*)objectBlob.GetBufferPointer();
		let size = (int)objectBlob.GetBufferSize();
		if ((bytes != null) && (size > 0))
		{
			result.Bytecode = new uint8[size];
			Internal.MemCpy(result.Bytecode.Ptr, bytes, size);
			result.Success = true;
		}

		objectBlob.Release();
		if (objectName != null)
			objectName.Release();
	}

	/// The DXC profile prefix for a stage.
	///
	/// Every ray tracing stage compiles as a LIBRARY: they are entry points inside one
	/// module rather than separate programs, which is why they share `lib`.
	private static StringView StageProfilePrefix(ShaderStage stage)
	{
		switch (stage)
		{
		case .Vertex: return "vs";
		case .Fragment: return "ps";
		case .Compute: return "cs";
		case .Mesh: return "ms";
		case .Task: return "as";
		case .RayGen, .ClosestHit, .AnyHit, .Miss, .Intersection, .Callable: return "lib";
		}
	}
}
