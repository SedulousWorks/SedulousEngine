using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shaders;

namespace Sedulous.Shaders.System.Tests;

/// Compile on demand, the cooked pack path, and the canonicalization both share.
class ShaderSystemTests
{
	/// A shader whose output depends on a flag, so two variants cannot produce the same
	/// bytecode.
	private const String cFlaggedPixelShader = """
		float4 main() : SV_Target0 {
		#ifdef SKINNED
		    return float4(1, 0, 0, 1);
		#else
		    return float4(0, 0, 1, 1);
		#endif
		}
		""";

	private static IDevice MakeDevice(IBackend* outBackend)
	{
		let backend = NullRhi.CreateBackend();
		*outBackend = backend;
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return null;
		if (adapters[0].CreateDevice(.()) case .Ok(let device))
			return device;
		return null;
	}

	private static Sedulous.Shaders.ShaderCompiler MakeCompiler()
	{
		let compiler = new Sedulous.Shaders.ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			delete compiler;
			return null;
		}
		return compiler;
	}

	/// One file can serve both stages as named functions: each registered stage carries its
	/// entry, every module made from it records that entry (so a pipeline need not name it), and
	/// the cooked path takes the entry from the pack.
	[Test]
	public static void AStagesEntryPointIsRegisteredWithItAndRecordedOnItsModules()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let oneFile = """
			struct VSOut { float4 pos : SV_Position; };
			VSOut VSMain(uint id : SV_VertexID) { VSOut o; o.pos = float4(0, 0, 0, 1); return o; }
			float4 PSMain(VSOut input) : SV_Target0 { return float4(1, 0, 0, 1); }
			""";
		{
			let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
			shaders.OptimizationLevel = 0;
			shaders.RegisterSource("one", .Vertex, oneFile, "VSMain");
			shaders.RegisterSource("one", .Fragment, oneFile, "PSMain");
			let vs = shaders.GetVariant("one", .Vertex, .None);
			let ps = shaders.GetVariant("one", .Fragment, .None);
			Test.Assert((vs != null) && (ps != null));
			Test.Assert(vs.EntryPoint == "VSMain");
			Test.Assert(ps.EntryPoint == "PSMain");
			// A stage that names none runs its module's own; one that names one runs that.
			Test.Assert(ProgrammableStage(vs, .Vertex).ResolvedEntryPoint == "VSMain");
			Test.Assert(ProgrammableStage(vs, "Other", .Vertex).ResolvedEntryPoint == "Other");

			// A wrong entry name is a compile failure, not a module named something it lacks.
			shaders.RegisterSource("wrong", .Vertex, oneFile, "NoSuchFunction");
			Test.Assert(shaders.GetVariant("wrong", .Vertex, .None) == null);
		}
		{
			// Compiler free: the cooked pack supplies the entry the cook compiled the stage for.
			uint8[4] blob = .(1, 2, 3, 4);
			let pack = scope CookedShaderPack();
			pack.Add("cooked", .Fragment, .None, .SpirV, blob);
			pack.AddEntryPoint("cooked", .Fragment, "PSMain");
			let shaders = scope Sedulous.Shaders.ShaderSystem(device);
			shaders.SetCookedPack(pack);
			let module = shaders.GetVariant("cooked", .Fragment, .None);
			Test.Assert((module != null) && (module.EntryPoint == "PSMain"));

			// A pack stage with no entry recorded is refused, not run as `main`.
			pack.Add("unnamed", .Fragment, .None, .SpirV, blob);
			Test.Assert(shaders.GetVariant("unnamed", .Fragment, .None) == null);
		}
	}

	/// The requested flags become defines, and a FAILURE IS NOT CACHED: a shader fixed after
	/// a bad compile must resolve on the next request, which is what makes hot reload useful.
	[Test]
	public static void FlagsBecomeDefinesAndFailuresAreNotCached()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.RegisterSource("flagged", .Fragment, cFlaggedPixelShader, "main");

		let plain = shaders.GetVariant("flagged", .Fragment, .None);
		let skinned = shaders.GetVariant("flagged", .Fragment, .Skinned);
		Test.Assert(plain != null, "the unflagged variant compiled");
		Test.Assert(skinned != null, "and so did the flagged one");
		Test.Assert(plain != skinned, "they are separate modules, so the define took effect");

		// A source that cannot compile yields null, and is not compiled again until it changes.
		shaders.RegisterSource("broken", .Fragment, "this is not valid hlsl @#$", "main");
		Test.Assert(shaders.GetVariant("broken", .Fragment, .None) == null);
		Test.Assert(shaders.FailedVariantCount == 1, "remembered, so not compiled again");
		Test.Assert(shaders.GetVariant("broken", .Fragment, .None) == null);
		shaders.InvalidateShader("broken");
		Test.Assert(shaders.FailedVariantCount == 0, "invalidating forgets it");
		Test.Assert(shaders.GetVariant("broken", .Fragment, .None) == null);

		shaders.RegisterSource("broken", .Fragment,
			"float4 main() : SV_Target0 { return 0; }", "main");
		Test.Assert(shaders.GetVariant("broken", .Fragment, .None) != null,
			"the fixed source compiles: registering forgot the failure");
		Test.Assert(shaders.FailedVariantCount == 0);
	}

	/// A registered source with a declared mask (a cooked shader asset's lattice) canonicalizes
	/// requests onto it, as the corpus does: a flag the stage ignores lands on the variant it has.
	[Test]
	public static void ARegisteredSourcesDeclaredMaskCanonicalizesRequests()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		shaders.OptimizationLevel = 0;
		shaders.RegisterSource("masked", .Fragment, cFlaggedPixelShader, "main", ShaderFlags.Skinned);
		let skinned = shaders.GetVariant("masked", .Fragment, .Skinned);
		Test.Assert(skinned != null);
		Test.Assert(shaders.GetVariant("masked", .Fragment, .Skinned | .GBuffer) == skinned, "GBUFFER is not declared: stripped");
		Test.Assert(shaders.GetVariant("masked", .Fragment, .GBuffer) == shaders.GetVariant("masked", .Fragment, .None));

		// Without a mask the raw flags compile: GBUFFER makes a variant of its own.
		shaders.RegisterSource("raw", .Fragment, cFlaggedPixelShader, "main");
		Test.Assert(shaders.GetVariant("raw", .Fragment, .GBuffer) != shaders.GetVariant("raw", .Fragment, .None));
	}

	/// The device's format picks the pack bucket. Pure, so it needs no device.
	[Test]
	public static void TheDeviceFormatSelectsThePackBucket()
	{
		Test.Assert(Sedulous.Shaders.ShaderSystem.SelectCookedFormat(.SpirV) == .SpirV);
		Test.Assert(Sedulous.Shaders.ShaderSystem.SelectCookedFormat(.DXIL) == .Dxil);
		Test.Assert(Sedulous.Shaders.ShaderSystem.SelectCookedFormat(.WGSL) == .Wgsl);
	}

	/// The pack path serves prebuilt blobs with NO compiler, and canonicalizes a request
	/// against the declared mask so a flag the stage ignores still lands on a variant.
	[Test]
	public static void ThePackPathServesBlobsWithoutACompiler()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		// A blob the null backend will accept as a module.
		uint8[8] blob = .(1, 2, 3, 4, 5, 6, 7, 8);
		let pack = scope CookedShaderPack();
		pack.Add("lit", .Fragment, .None, .SpirV, blob);
		pack.Add("lit", .Fragment, .Skinned, .SpirV, blob);
		// The stage branches only on SKINNED.
		pack.AddDeclaredMask("lit", .Fragment, .Skinned);
		pack.AddEntryPoint("lit", .Fragment, "main");

		// Constructed WITHOUT a compiler, which is what a shipped build has.
		let shaders = scope Sedulous.Shaders.ShaderSystem(device);
		shaders.SetCookedPack(pack);

		let plain = shaders.GetVariant("lit", .Fragment, .None);
		Test.Assert(plain != null, "a cooked variant resolves with no compiler at all");

		// GBUFFER is not declared, so it is stripped and this must land on the None variant
		// that was cooked, not miss.
		let stripped = shaders.GetVariant("lit", .Fragment, .GBuffer);
		Test.Assert(stripped === plain, "an undeclared flag canonicalizes onto the same module");

		// SKINNED is declared, so it is a different variant.
		let skinned = shaders.GetVariant("lit", .Fragment, .Skinned);
		Test.Assert(skinned != null);
		Test.Assert(skinned !== plain, "a declared flag resolves to its own variant");

		// Nothing was cooked for this name, which is a coverage bug and returns null.
		Test.Assert(shaders.GetVariant("absent", .Fragment, .None) == null);
	}

	/// Distinct variants cache separately, and invalidating drops them and bumps the version
	/// a pipeline cache watches.
	[Test]
	public static void VariantsCacheAndInvalidateTogether()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.RegisterSource("cached", .Fragment, cFlaggedPixelShader, "main");

		Test.Assert(shaders.Version("cached") == 0, "an untouched shader is at version zero");

		let first = shaders.GetVariant("cached", .Fragment, .None);
		let again = shaders.GetVariant("cached", .Fragment, .None);
		Test.Assert(first === again, "the second request came from the cache");

		let skinned = shaders.GetVariant("cached", .Fragment, .Skinned);
		Test.Assert(skinned !== first, "a different variant is a different module");

		Test.Assert(shaders.InvalidateShader("cached") == 2, "both variants were dropped");
		Test.Assert(shaders.Version("cached") == 1, "and the version moved");

		let rebuilt = shaders.GetVariant("cached", .Fragment, .None);
		Test.Assert(rebuilt != null, "the next request recompiles");
	}

	/// An explicitly registered source BEATS the pack. The engine pack covers the engine
	/// corpus, while registered sources carry bespoke and user shaders, and those must keep
	/// resolving in pack mode or a custom material shader dies in a shipped build.
	[Test]
	public static void ARegisteredSourceBeatsThePack()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		uint8[8] blob = .(1, 2, 3, 4, 5, 6, 7, 8);
		let pack = scope CookedShaderPack();
		pack.Add("overridden", .Fragment, .None, .SpirV, blob);
		pack.AddEntryPoint("overridden", .Fragment, "main");

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.SetCookedPack(pack);

		// Before registering, the pack answers.
		Test.Assert(shaders.GetVariant("overridden", .Fragment, .None) != null);

		shaders.RegisterSource("overridden", .Fragment,
			"float4 main() : SV_Target0 { return float4(1, 1, 1, 1); }", "main");
		// Registering must not be shadowed by the pack entry of the same name.
		Test.Assert(shaders.GetVariant("overridden", .Fragment, .None) != null,
			"the registered source still resolves in pack mode");
	}

	/// A registered source in a COMPILER FREE build that the pack never cooked is a miss: a
	/// source needs a compiler, and there is none.
	[Test]
	public static void ARegisteredSourceThePackLacksIsAMissWithoutACompiler()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		uint8[8] blob = .(1, 2, 3, 4, 5, 6, 7, 8);
		let pack = scope CookedShaderPack();
		pack.Add("cooked", .Fragment, .None, .SpirV, blob);
		pack.AddEntryPoint("cooked", .Fragment, "main");

		let shaders = scope Sedulous.Shaders.ShaderSystem(device);
		shaders.SetCookedPack(pack);
		shaders.RegisterSource("uncooked", .Fragment,
			"float4 main() : SV_Target0 { return 0; }", "main");

		Test.Assert(shaders.GetVariant("uncooked", .Fragment, .None) == null,
			"a source needs a compiler, and there is none");
		Test.Assert(shaders.GetVariant("cooked", .Fragment, .None) != null,
			"while the cooked one still resolves");
	}

	/// A shipped build (no compiler) serves a project's registered shader from the pack, as the
	/// corpus is served: the export cooked it there with its entry point and lattice.
	[Test]
	public static void ACompilerFreeBuildServesARegisteredShaderFromThePack()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		uint8[4] blob = .(1, 2, 3, 4);
		let pack = scope CookedShaderPack();
		pack.Add("toon", .Fragment, .None, .SpirV, blob);
		pack.Add("toon", .Fragment, .GBuffer, .SpirV, blob);
		pack.AddDeclaredMask("toon", .Fragment, .GBuffer);
		pack.AddEntryPoint("toon", .Fragment, "PSMain");

		let shaders = scope Sedulous.Shaders.ShaderSystem(device);
		shaders.SetCookedPack(pack);
		shaders.RegisterSource("toon", .Fragment, "", "PSMain", ShaderFlags.GBuffer);
		let plain = shaders.GetVariant("toon", .Fragment, .None);
		Test.Assert((plain != null) && (plain.EntryPoint == "PSMain"));
		Test.Assert(shaders.GetVariant("toon", .Fragment, .Skinned) == plain, "a flag the stage never declared reduces to the cooked variant");
		Test.Assert(shaders.GetVariant("toon", .Fragment, .GBuffer) != null);
		Test.Assert(shaders.GetVariant("toon", .Vertex, .None) == null, "a stage the pack never cooked is a miss");
	}

	/// Removing a source drops it: the next request has nothing to compile.
	[Test]
	public static void RemovingASourceDropsIt()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.RegisterSource("temporary", .Fragment,
			"float4 main() : SV_Target0 { return 0; }", "main");
		Test.Assert(shaders.GetVariant("temporary", .Fragment, .None) != null);

		shaders.RemoveSource("temporary");
		// The cached module is still there until the shader is invalidated, so both are
		// done, which is what PumpReloads does.
		shaders.InvalidateShader("temporary");
		Test.Assert(shaders.GetVariant("temporary", .Fragment, .None) == null,
			"with no source and no provider there is nothing to compile");
	}

	/// PumpReloads with no provider is a no-op rather than a crash: a system built on
	/// registered sources alone is a supported configuration.
	[Test]
	public static void PumpReloadsWithoutAProviderIsHarmless()
	{
		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let shaders = scope Sedulous.Shaders.ShaderSystem(device);
		Test.Assert(shaders.PumpReloads() == 0);
		Test.Assert(shaders.SourceProvider == null);
	}
}
