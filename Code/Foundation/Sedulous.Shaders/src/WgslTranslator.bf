using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Shaders;

/// Turns one HLSL stage into browser conformant WGSL, at cook time.
///
///   HLSL  -DXC->  SPIR-V, at vulkan1.1 with the engine's standard binding shifts
///         -naga-> WGSL
///         -tint-> validated against what Chrome actually accepts
///
/// COOK TIME ONLY. It shells out to the vendored naga and tint executables, so it has no
/// place in a running game. naga is the version matched translator, its own naga being what
/// wgpu validates WGSL with; tint errors on the uniformity violations naga only warns about,
/// which is why it is a second gate rather than a redundant one.
///
/// The intermediate SPIR-V and WGSL are written to a scratch directory because naga reads a
/// file and writes a file: its emit path does not stream.
class WgslTranslator
{
	private ShaderCompiler mCompiler;
	private String mScratchDirectory = new String() ~ delete _;
	private String mNagaPath = new String() ~ delete _;
	private String mTintPath = new String() ~ delete _;
	private bool mValidate = true;
	private uint64 mCounter = 0;

	/// The compiler is BORROWED and must outlive this. The scratch directory must exist and
	/// be writable.
	public this(ShaderCompiler compiler, StringView scratchDirectory)
	{
		mCompiler = compiler;
		mScratchDirectory.Set(scratchDirectory);
	}

	public void SetNagaPath(StringView path) => mNagaPath.Set(path);
	public void SetTintPath(StringView path) => mTintPath.Set(path);

	/// Whether to run tint over naga's output. On by default.
	///
	/// Turning it off is an explicit opt-out that the caller owns the risk of, which is why
	/// a missing tint is a failure rather than a silent skip.
	public void SetValidateWithTint(bool validate) => mValidate = validate;

	public bool HasNaga => !mNagaPath.IsEmpty;
	public bool HasTint => !mTintPath.IsEmpty;

	public void Translate(StringView hlsl, ShaderStage stage, ShaderFlags flags,
		Span<StringView> includePaths, WgslCookResult outResult)
	{
		outResult.Success = false;
		outResult.FailedStage = .Ok;
		outResult.Wgsl.Clear();
		outResult.Error.Clear();

		if (mNagaPath.IsEmpty)
		{
			outResult.FailedStage = .Translate;
			outResult.Error.Set("no naga binary was configured, so WGSL cannot be produced");
			return;
		}

		let spirv = scope List<uint8>();
		if (CompileToSpirv(hlsl, stage, flags, includePaths, spirv, outResult) case .Err)
			return;

		let id = mCounter++;
		let spirvPath = ScratchPath(id, ".spv", .. scope String());
		let wgslPath = ScratchPath(id, ".wgsl", .. scope String());
		defer
		{
			DeleteFile(spirvPath);
			DeleteFile(wgslPath);
		}

		if (WriteFile(spirvPath, spirv) case .Err)
		{
			outResult.FailedStage = .Translate;
			outResult.Error.Set("could not write the intermediate SPIR-V to the scratch directory");
			return;
		}

		if (RunNaga(spirvPath, wgslPath, outResult) case .Err)
			return;

		let wgslBytes = scope List<uint8>();
		if ((ReadFile(wgslPath, wgslBytes) case .Err) || wgslBytes.IsEmpty)
		{
			outResult.FailedStage = .Translate;
			outResult.Error.Set("naga reported success but produced no WGSL");
			return;
		}
		outResult.Wgsl.Append(StringView((char8*)wgslBytes.Ptr, wgslBytes.Count));

		if (RunTint(wgslPath, outResult) case .Err)
			return;

		outResult.Success = true;
		outResult.FailedStage = .Ok;
	}

	/// The DXC half, with the WebGPU compile settings the runtime would use.
	private Result<void> CompileToSpirv(StringView hlsl, ShaderStage stage, ShaderFlags flags,
		Span<StringView> includePaths, List<uint8> outSpirv, WgslCookResult outResult)
	{
		let defines = scope List<ShaderDefine>();
		ShaderFlagNames.AppendDefines(flags, defines);
		// A browser has no push constants and REJECTS a WGSL var<push_constant>. Compiling
		// the push constant blocks as ordinary constant buffers makes naga emit a uniform
		// the browser accepts, which the WebGPU backend then feeds per draw.
		defines.Add(.("PUSH_CONSTANT_AS_CBUFFER", "1"));

		var options = CompileOptions();
		options.ShaderModel = "6_0";
		options.OptimizationLevel = 3;
		// vulkan1.1, not 1.3: naga rejects the SPIR-V 1.4 and later instructions DXC emits
		// above 1.1.
		options.SpirvTargetEnvironment = "vulkan1.1";
		options.BindingShifts = BindingShifts.Standard;
		options.BindingShiftSets = 4;
		options.Defines = defines;
		options.IncludePaths = includePaths;

		var compiled = mCompiler.Compile(.((uint8*)hlsl.Ptr, hlsl.Length), stage, "main",
			.SPIRV, options);
		defer compiled.Dispose();

		if (!compiled.Success)
		{
			outResult.FailedStage = .Compile;
			outResult.Error.Set(compiled.Messages.IsEmpty ? "the DXC compile failed"
				: compiled.Messages);
			return .Err;
		}

		outSpirv.AddRange(compiled.Bytecode);
		return .Ok;
	}

	private Result<void> RunNaga(StringView spirvPath, StringView wgslPath,
		WgslCookResult outResult)
	{
		// --keep-coordinate-space is LOAD BEARING. Without it naga bakes a clip space Y
		// adjustment into the WGSL that wgpu's own SPIR-V front end does NOT apply, so a
		// cooked WGSL build renders mirrored against both the SPIR-V path and Vulkan. With
		// it, every WebGPU path shares Vulkan's raster orientation and the renderer needs no
		// compensating flip anywhere.
		StringView[3] arguments = .("--keep-coordinate-space", spirvPath, wgslPath);

		let result = scope ProcessResult();
		Process.Run(mNagaPath, arguments, result);
		if (result.Ok)
			return .Ok;

		outResult.FailedStage = .Translate;
		Describe("naga", mNagaPath, result, outResult.Error);
		return .Err;
	}

	private Result<void> RunTint(StringView wgslPath, WgslCookResult outResult)
	{
		if (!mValidate)
			return .Ok;

		// Validation asked for but no tint: FAIL rather than skip. Unvalidated WGSL is
		// exactly the class of output a browser rejects at runtime, and tint is vendored to
		// catch that here. A host that genuinely has none opts out on purpose.
		if (mTintPath.IsEmpty)
		{
			outResult.FailedStage = .Validate;
			outResult.Error.Set("no tint binary was configured, so the WGSL cannot be validated; pass validate=false to cook it unvalidated and own the risk");
			return .Err;
		}

		StringView[3] arguments = .("--format", "wgsl", wgslPath);
		let result = scope ProcessResult();
		Process.Run(mTintPath, arguments, result);
		if (result.Ok)
			return .Ok;

		outResult.FailedStage = .Validate;
		Describe("tint", mTintPath, result, outResult.Error);
		return .Err;
	}

	/// Why a tool failed, always naming the tool.
	///
	/// Unconditionally, not only when the process could not be started: on this platform a
	/// missing executable still spawns and then exits non zero with nothing on either pipe,
	/// which would leave an empty message for the one failure that most needs explaining.
	/// Naming it costs a few words and never loses the tool's own diagnostic, which is
	/// appended when there is one.
	private static void Describe(StringView tool, StringView path, ProcessResult result,
		String outError)
	{
		if (!result.Ran)
			outError.AppendF("could not run {} at {}", tool, path);
		else
			outError.AppendF("{} at {} failed with exit code {}", tool, path, result.ExitCode);

		if (!result.Output.IsEmpty)
		{
			outError.Append(": ");
			outError.Append(result.Output);
		}
	}

	/// A unique path in the scratch directory, so concurrent translations do not collide on
	/// one another's intermediates.
	private void ScratchPath(uint64 id, StringView @extension, String outPath)
	{
		outPath.Set(mScratchDirectory);
		outPath.AppendF("/wgslcook_{}{}", id, @extension);
	}
}
