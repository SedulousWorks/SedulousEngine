using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// Cooking a corpus of HLSL files into a pack.
///
/// The corpus is BUILT here rather than pointed at the engine's, so the tests own exactly
/// what they assert about: a shader added to the engine later cannot quietly change a
/// variant count.
class ShaderPackCookerTests
{
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

	/// A fresh directory for one test's corpus, emptied first so a previous run cannot leak
	/// files into this one's counts.
	private static void MakeCorpusDirectory(StringView name, String outPath)
	{
		System.IO.Path.GetTempPath(outPath).IgnoreError();
		outPath.AppendF("sedulous_cook_{}", name);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	private static void WriteShader(StringView directory, StringView fileName, StringView text)
	{
		let path = scope String();
		PathJoin(directory, fileName, path);
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	private static ShaderCookOptions SpirvOnly(StringView directory, StringView scratch,
		Span<CookedShaderFormat> formats)
	{
		var options = ShaderCookOptions();
		options.ShaderDirectory = directory;
		options.ScratchDirectory = scratch;
		options.Formats = formats;
		options.ValidateWgsl = false;
		return options;
	}

	/// A corpus cooks: every stage file becomes its declared variants, and the mask is
	/// recorded so a shipped runtime can canonicalize onto them.
	[Test]
	public static void ACorpusCooksToASpirvPack()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let corpus = MakeCorpusDirectory("basic", .. scope String());
		defer { RemoveDirectoryRecursive(corpus); }

		// Two declared flags, so four variants.
		WriteShader(corpus, "forward.vs.hlsl", """
			// variants: SKINNED INSTANCED
			float4 main(uint id : SV_VertexID) : SV_Position {
			#ifdef SKINNED
			    return float4(1, 0, 0, 1);
			#elif defined(INSTANCED)
			    return float4(0, 1, 0, 1);
			#else
			    return float4(0, 0, 1, 1);
			#endif
			}
			""");
		// No directive at all, so a single variant.
		WriteShader(corpus, "flat.ps.hlsl", """
			float4 main() : SV_Target0 { return float4(1, 1, 1, 1); }
			""");
		// Shared code, which must be SKIPPED as a stage file.
		WriteShader(corpus, "shared.hlsli", "#define SHARED_THING 1\n");

		CookedShaderFormat[1] formats = .(.SpirV);
		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler,
			SpirvOnly(corpus, corpus, formats), pack, report);

		Test.Assert(report.Success, "the corpus cooked clean");
		Test.Assert(report.Errors.IsEmpty);
		Test.Assert(report.FilesCooked == 2, "the .hlsli was not treated as a stage");
		// Four variants for the vertex shader plus one for the fragment shader.
		Test.Assert(report.VariantsCooked == 5);
		Test.Assert(pack.Count == 5);

		// Every declared variant is present and distinct from the others.
		Test.Assert(pack.Find("forward", .Vertex, .None, .SpirV) case .Ok(let none));
		Test.Assert(pack.Find("forward", .Vertex, .Skinned, .SpirV) case .Ok(let skinned));
		Test.Assert(pack.Find("forward", .Vertex, .Instanced, .SpirV) case .Ok);
		Test.Assert(pack.Find("forward", .Vertex, .Skinned | .Instanced, .SpirV) case .Ok);
		// The defines really reached the compile, so the branches differ.
		Test.Assert(none.Length != skinned.Length || !SameBytes(none, skinned),
			"the variants are not the same blob");

		Test.Assert(pack.Find("flat", .Fragment, .None, .SpirV) case .Ok);

		// The mask is what a shipped runtime canonicalizes with.
		Test.Assert(pack.DeclaredMask("forward", .Vertex)
			== (ShaderFlags.Skinned | ShaderFlags.Instanced));
		Test.Assert(pack.DeclaredMask("flat", .Fragment) == .None);
	}

	private static bool SameBytes(Span<uint8> a, Span<uint8> b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	/// A stage that branches on a flag it did not declare FAILS the cook. Canonicalization
	/// would strip that flag in a shipped build and the visuals would silently be wrong.
	[Test]
	public static void TheDriftLintFailsAnUndeclaredFlag()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let corpus = MakeCorpusDirectory("drift", .. scope String());
		defer { RemoveDirectoryRecursive(corpus); }

		WriteShader(corpus, "drifty.ps.hlsl", """
			// variants: SKINNED
			float4 main() : SV_Target0 {
			#ifdef GBUFFER
			    return float4(1, 0, 0, 1);
			#endif
			    return float4(0, 0, 0, 1);
			}
			""");

		CookedShaderFormat[1] formats = .(.SpirV);
		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler,
			SpirvOnly(corpus, corpus, formats), pack, report);

		Test.Assert(!report.Success, "the cook failed");
		Test.Assert(report.Errors.Count == 1);
		Test.Assert(report.Errors[0].Contains("GBUFFER"), "and named the offending flag");
		Test.Assert(report.Errors[0].Contains("drifty.ps.hlsl"), "and the file");
		// The stage is skipped entirely rather than cooked with a stripped flag.
		Test.Assert(pack.Count == 0);
	}

	/// The lint sees THROUGH an include: a stage file is often just a directive and one
	/// include, and the conditionals live in the .hlsli.
	[Test]
	public static void TheDriftLintSeesThroughAnInclude()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let corpus = MakeCorpusDirectory("include", .. scope String());
		defer { RemoveDirectoryRecursive(corpus); }

		// The stage file's own text is clean. Only the include is not.
		WriteShader(corpus, "viainclude.ps.hlsl", """
			// variants: SKINNED
			#include "body.hlsli"
			""");
		WriteShader(corpus, "body.hlsli", """
			float4 main() : SV_Target0 {
			#ifdef EMISSIVE
			    return float4(1, 1, 0, 1);
			#endif
			    return float4(0, 0, 0, 1);
			}
			""");

		CookedShaderFormat[1] formats = .(.SpirV);
		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler,
			SpirvOnly(corpus, corpus, formats), pack, report);

		Test.Assert(!report.Success, "linting only the stage file would have passed this");
		Test.Assert(report.Errors.Count == 1);
		Test.Assert(report.Errors[0].Contains("EMISSIVE"));
	}

	/// The same corpus cooked twice produces the same bytes, which a build that caches on a
	/// pack's hash depends on.
	[Test]
	public static void TheCookIsReproducible()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let corpus = MakeCorpusDirectory("repro", .. scope String());
		defer { RemoveDirectoryRecursive(corpus); }

		// Several files, so the directory listing order has a chance to differ between runs
		// and the sort has something to do.
		WriteShader(corpus, "zeta.vs.hlsl",
			"float4 main() : SV_Position { return float4(0, 0, 0, 1); }\n");
		WriteShader(corpus, "alpha.ps.hlsl", "float4 main() : SV_Target0 { return 0; }\n");
		WriteShader(corpus, "middle.cs.hlsl", """
			RWStructuredBuffer<uint> Out : register(u0);
			[numthreads(1,1,1)] void main(uint3 id : SV_DispatchThreadID) { Out[id.x] = 1; }
			""");

		CookedShaderFormat[1] formats = .(.SpirV);

		let first = scope CookedShaderPack();
		let firstReport = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler, SpirvOnly(corpus, corpus, formats),
			first, firstReport);
		Test.Assert(firstReport.Success);

		let second = scope CookedShaderPack();
		let secondReport = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler, SpirvOnly(corpus, corpus, formats),
			second, secondReport);
		Test.Assert(secondReport.Success);

		let firstBytes = scope MemoryStream();
		let secondBytes = scope MemoryStream();
		Test.Assert(first.Write(firstBytes) case .Ok);
		Test.Assert(second.Write(secondBytes) case .Ok);

		Test.Assert(firstBytes.Bytes.Length == secondBytes.Bytes.Length,
			"the two packs are the same size");
		Test.Assert(SameBytes(firstBytes.Bytes, secondBytes.Bytes),
			"and byte for byte identical");
	}

	/// A shader DXC refuses is reported with its diagnostic, and the rest of the corpus still
	/// cooks: one broken shader must not hide the others.
	[Test]
	public static void ABrokenShaderDoesNotStopTheCook()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let corpus = MakeCorpusDirectory("broken", .. scope String());
		defer { RemoveDirectoryRecursive(corpus); }

		WriteShader(corpus, "good.ps.hlsl", "float4 main() : SV_Target0 { return 0; }\n");
		WriteShader(corpus, "broken.ps.hlsl", "this is not valid hlsl @#$\n");

		CookedShaderFormat[1] formats = .(.SpirV);
		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler, SpirvOnly(corpus, corpus, formats),
			pack, report);

		Test.Assert(!report.Success, "the cook is not clean");
		Test.Assert(report.Errors.Count == 1);
		Test.Assert(report.Errors[0].Contains("broken.ps.hlsl"), "the error names the file");
		// The good one still made it, so the report is a list of what to fix rather than a
		// stop at the first problem.
		Test.Assert(pack.Find("good", .Fragment, .None, .SpirV) case .Ok);
	}

	/// A directory that does not exist is reported rather than treated as an empty corpus,
	/// which would cook a silently empty pack.
	[Test]
	public static void AMissingDirectoryIsReported()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		CookedShaderFormat[1] formats = .(.SpirV);
		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler,
			SpirvOnly("/no/such/shader/directory", "/tmp", formats), pack, report);

		Test.Assert(!report.Success);
		Test.Assert(report.Errors.Count == 1);
		Test.Assert(pack.IsEmpty);
	}

	/// The file name convention: the stem is the shader name and the double extension is the
	/// stage, and anything else is not a stage file.
	[Test]
	public static void StageFileNamesAreParsed()
	{
		ShaderStage stage = .Compute;
		let stem = scope String();

		Test.Assert(ShaderPackCooker.ParseStageFile("tonemap.ps.hlsl", ref stage, stem));
		Test.Assert(stage == .Fragment);
		Test.Assert(stem == "tonemap");

		Test.Assert(ShaderPackCooker.ParseStageFile("skin.vs.hlsl", ref stage, stem));
		Test.Assert(stage == .Vertex);
		Test.Assert(stem == "skin");

		Test.Assert(ShaderPackCooker.ParseStageFile("blur.cs.hlsl", ref stage, stem));
		Test.Assert(stage == .Compute);
		Test.Assert(stem == "blur");

		// Shared code, not a stage.
		Test.Assert(!ShaderPackCooker.ParseStageFile("common.hlsli", ref stage, stem));
		Test.Assert(!ShaderPackCooker.ParseStageFile("notes.txt", ref stage, stem));
		// A missing stage marker is not a stage file either.
		Test.Assert(!ShaderPackCooker.ParseStageFile("plain.hlsl", ref stage, stem));
		// An empty stem has no name to key on.
		Test.Assert(!ShaderPackCooker.ParseStageFile(".ps.hlsl", ref stage, stem));
	}
}
