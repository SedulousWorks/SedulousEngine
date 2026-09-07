using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// The WGSL cook driving the real naga and tint binaries.
///
/// These shell out for real. A host without the vendored binaries skips, but the point of
/// vendoring them is that a development machine has them, and the browser conformance gate
/// is only worth anything if it actually runs.
class WgslCookTests
{
	/// A self contained pixel shader: a texture, a sampler and a constant buffer, sampling
	/// through SampleLevel so it carries no implicit derivative and is browser conformant.
	private const String cCleanPixelShader = """
		Texture2D Tex : register(t0, space0);
		SamplerState Samp : register(s0, space0);
		cbuffer C : register(b0, space0) { float4 Tint; };
		float4 main(float2 uv : TEXCOORD0) : SV_Target0 {
		    return Tex.SampleLevel(Samp, uv, 0) * Tint;
		}
		""";

	/// The same, but sampling with implicit derivatives inside a per pixel branch. Legal
	/// HLSL, and a WGSL uniformity error that naga only warns about while tint rejects it.
	/// This is exactly the shader class the second gate exists to catch.
	private const String cNonUniformPixelShader = """
		Texture2D Tex : register(t0, space0);
		SamplerState Samp : register(s0, space0);
		float4 main(float2 uv : TEXCOORD0) : SV_Target0 {
		    float4 c = float4(0,0,0,1);
		    if (uv.x > 0.5) { c = Tex.Sample(Samp, uv); }
		    return c;
		}
		""";

	private static void BinPath(StringView tool, String outPath)
	{
		// The repository's vendored binaries, found relative to this source tree rather than
		// to the build output, which moves per configuration.
		outPath.Set(cRepositoryBin);
		outPath.Append(tool);
	}

	private const String cRepositoryBin = "/home/robert/Dev/CS/GameEngine/Sedulous/Bin/";

	private static bool ToolsPresent()
	{
		let naga = NagaPath(.. scope String());
		let tint = TintPath(.. scope String());
		return FileExists(naga) && FileExists(tint);
	}

	private static void NagaPath(String outPath) => BinPath("Naga/bin/linux-x86_64/naga", outPath);
	private static void TintPath(String outPath) => BinPath("Tint/bin/linux-x86_64/tint", outPath);

	private static ShaderCompiler MakeCompiler()
	{
		let compiler = new ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			delete compiler;
			return null;
		}
		return compiler;
	}

	private static void ScratchDirectory(String outPath)
	{
		System.IO.Path.GetTempPath(outPath).IgnoreError();
		outPath.Append("sedulous_wgslcook_tests");
		CreateDirectory(outPath);
	}

	/// HLSL becomes WGSL, and the binding shifts SURVIVE the translation.
	///
	/// The shifts are the load bearing part: a texture at t0 must land on binding 100 and a
	/// sampler at s0 on 300, because that is where the WebGPU backend's bind group layout
	/// puts them. WGSL that lost the shifts compiles and then binds nothing.
	[Test]
	public static void HlslTranslatesToWgslWithTheShiftsIntact()
	{
		if (!ToolsPresent()) { Console.WriteLine("SKIP: no naga or tint"); return; }
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let scratch = ScratchDirectory(.. scope String());
		let translator = scope WgslTranslator(compiler, scratch);
		translator.SetNagaPath(NagaPath(.. scope String()));
		translator.SetTintPath(TintPath(.. scope String()));

		let result = scope WgslCookResult();
		translator.Translate(cCleanPixelShader, .Fragment, .None, default, result);

		Test.Assert(result.Success, "the clean shader translated and validated");
		Test.Assert(result.FailedStage == .Ok);
		Test.Assert(!result.Wgsl.IsEmpty, "and produced WGSL");
		Test.Assert(result.Wgsl.Contains("fn main"), "which has an entry point");

		// t0 with the SRV shift is binding 100; s0 with the sampler shift is 300.
		Test.Assert(result.Wgsl.Contains("@binding(100)"), "the texture kept its shifted binding");
		Test.Assert(result.Wgsl.Contains("@binding(300)"), "and so did the sampler");
		// b0 takes the constant buffer shift, which is zero, so it stays at 0.
		Test.Assert(result.Wgsl.Contains("@binding(0)"), "and the constant buffer stayed at 0");
	}

	/// tint rejects a uniformity violation that naga lets through, which is the whole reason
	/// there are two tools rather than one.
	[Test]
	public static void TintRejectsAUniformityViolation()
	{
		if (!ToolsPresent()) { Console.WriteLine("SKIP: no naga or tint"); return; }
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let scratch = ScratchDirectory(.. scope String());
		let translator = scope WgslTranslator(compiler, scratch);
		translator.SetNagaPath(NagaPath(.. scope String()));
		translator.SetTintPath(TintPath(.. scope String()));

		let validated = scope WgslCookResult();
		translator.Translate(cNonUniformPixelShader, .Fragment, .None, default, validated);
		Test.Assert(!validated.Success, "the non-uniform shader was rejected");
		Test.Assert(validated.FailedStage == .Validate, "at the validation gate, not earlier");
		Test.Assert(!validated.Error.IsEmpty, "with tint's own diagnostic");

		// naga alone lets it through: without the second gate this would have shipped.
		let unvalidated = scope WgslCookResult();
		translator.SetValidateWithTint(false);
		translator.Translate(cNonUniformPixelShader, .Fragment, .None, default, unvalidated);
		Test.Assert(unvalidated.Success, "naga alone translates it happily");
	}

	/// Validation requested with no tint is a FAILURE, not a silent skip: unvalidated WGSL is
	/// exactly what a browser rejects at runtime.
	[Test]
	public static void AMissingTintFailsUnlessValidationIsWaived()
	{
		if (!ToolsPresent()) { Console.WriteLine("SKIP: no naga or tint"); return; }
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let scratch = ScratchDirectory(.. scope String());
		let translator = scope WgslTranslator(compiler, scratch);
		translator.SetNagaPath(NagaPath(.. scope String()));
		// Deliberately no tint path.

		let result = scope WgslCookResult();
		translator.Translate(cCleanPixelShader, .Fragment, .None, default, result);
		Test.Assert(!result.Success, "no tint means no validated WGSL");
		Test.Assert(result.FailedStage == .Validate);

		// Waiving it is an explicit choice the caller owns.
		translator.SetValidateWithTint(false);
		let waived = scope WgslCookResult();
		translator.Translate(cCleanPixelShader, .Fragment, .None, default, waived);
		Test.Assert(waived.Success, "and waiving validation cooks it anyway");
	}

	/// A missing naga is REPORTED rather than crashed on, and reported at the translate
	/// stage so the message says which tool.
	[Test]
	public static void AMissingNagaIsReported()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let scratch = ScratchDirectory(.. scope String());

		// No naga configured at all.
		let unconfigured = scope WgslTranslator(compiler, scratch);
		let result = scope WgslCookResult();
		unconfigured.Translate(cCleanPixelShader, .Fragment, .None, default, result);
		Test.Assert(!result.Success);
		Test.Assert(result.FailedStage == .Translate);
		Test.Assert(!result.Error.IsEmpty);

		// A naga path that does not exist: the process cannot start, which is a different
		// failure from a naga that ran and refused.
		let missing = scope WgslTranslator(compiler, scratch);
		missing.SetNagaPath(scope $"{cRepositoryBin}Naga/bin/linux-x86_64/naga_does_not_exist");
		let notRun = scope WgslCookResult();
		missing.Translate(cCleanPixelShader, .Fragment, .None, default, notRun);
		Test.Assert(!notRun.Success);
		Test.Assert(notRun.FailedStage == .Translate);
		Test.Assert(notRun.Error.Contains("naga"), "the message names the tool");
	}

	/// A shader DXC cannot compile fails at the compile stage, before naga is ever reached.
	[Test]
	public static void ABadShaderFailsBeforeTranslation()
	{
		if (!ToolsPresent()) { Console.WriteLine("SKIP: no naga or tint"); return; }
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let scratch = ScratchDirectory(.. scope String());
		let translator = scope WgslTranslator(compiler, scratch);
		translator.SetNagaPath(NagaPath(.. scope String()));
		translator.SetTintPath(TintPath(.. scope String()));

		let result = scope WgslCookResult();
		translator.Translate("this is not valid hlsl @#$", .Fragment, .None, default, result);

		Test.Assert(!result.Success);
		Test.Assert(result.FailedStage == .Compile, "the failure is attributed to DXC");
		Test.Assert(!result.Error.IsEmpty);
	}

	/// The translation leaves no intermediates behind: a cook that runs over a whole corpus
	/// would otherwise fill the scratch directory with one pair of files per variant.
	[Test]
	public static void IntermediatesAreCleanedUp()
	{
		if (!ToolsPresent()) { Console.WriteLine("SKIP: no naga or tint"); return; }
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		// Its own directory, so the count is only this test's doing.
		let scratch = scope String();
		System.IO.Path.GetTempPath(scratch).IgnoreError();
		scratch.Append("sedulous_wgslcook_cleanup");
		CreateDirectory(scratch);
		defer { RemoveDirectoryRecursive(scratch); }

		let translator = scope WgslTranslator(compiler, scratch);
		translator.SetNagaPath(NagaPath(.. scope String()));
		translator.SetTintPath(TintPath(.. scope String()));

		let result = scope WgslCookResult();
		translator.Translate(cCleanPixelShader, .Fragment, .None, default, result);
		Test.Assert(result.Success);

		int leftOver = 0;
		ListDirectory(scratch, scope [&] (name, isDirectory) =>
			{
				if (!isDirectory && name.StartsWith("wgslcook_"))
					leftOver++;
			});
		Test.Assert(leftOver == 0, "no intermediate SPIR-V or WGSL was left behind");
	}
}
