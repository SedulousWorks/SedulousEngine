using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shaders;

namespace Sedulous.Shaders.System.Tests;

/// Shaders pulled from real files, and the hot reload built on top.
class FileProviderTests
{
	private static void MakeRoot(StringView name, String outPath)
	{
		global::System.IO.Path.GetTempPath(outPath).IgnoreError();
		outPath.AppendF("sedulous_provider_{}", name);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	private static void Write(StringView directory, StringView fileName, StringView text)
	{
		let path = scope String();
		PathJoin(directory, fileName, path);
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

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

	/// The manifest is scanned eagerly and maps stems to names and double extensions to
	/// stages, while the sources themselves are read only when asked for.
	[Test]
	public static void TheManifestMapsStemsAndStages()
	{
		let root = MakeRoot("manifest", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		Write(root, "tonemap.ps.hlsl", "float4 main() : SV_Target0 { return 0; }\n");
		Write(root, "skin.vs.hlsl",
			"float4 main() : SV_Position { return float4(0, 0, 0, 1); }\n");
		Write(root, "blur.cs.hlsl", "[numthreads(1,1,1)] void main() {}\n");
		// Shared code and unrelated files are not stages.
		Write(root, "common.hlsli", "#define SHARED 1\n");
		Write(root, "notes.txt", "not a shader\n");

		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize(root) case .Ok);
		Test.Assert(provider.ShaderFileCount == 3, "only the three stage files were mapped");
		Test.Assert(provider.RootDirectory == root);

		let names = scope List<String>();
		provider.CollectShaderNames(names);
		defer { ClearAndDeleteItems!(names); }
		Test.Assert(names.Count == 3);

		let source = scope String();
		Test.Assert(provider.FetchSource("tonemap", .Fragment, source));
		Test.Assert(source.Contains("SV_Target0"), "the file's real contents came back");

		// The stage is part of the identity: the same stem in another stage is a miss.
		source.Clear();
		Test.Assert(!provider.FetchSource("tonemap", .Vertex, source));
		Test.Assert(!provider.FetchSource("nosuchshader", .Fragment, source));
	}

	/// A root that does not exist is refused, so a caller falls back loudly rather than
	/// serving nothing in silence.
	[Test]
	public static void AMissingRootIsRefused()
	{
		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize("/no/such/shader/root") case .Err);
		Test.Assert(provider.ShaderFileCount == 0);
	}

	/// The shader system PULLS from the provider on a miss, and an include resolves through
	/// the root.
	[Test]
	public static void TheSystemPullsFromTheProvider()
	{
		let root = MakeRoot("pull", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		Write(root, "shared.hlsli", "float4 Shared() { return float4(0, 1, 0, 1); }\n");
		Write(root, "viainclude.ps.hlsl", """
			#include "shared.hlsli"
			float4 main() : SV_Target0 { return Shared(); }
			""");

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

		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize(root) case .Ok);

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.SetSourceProvider(provider);
		StringView[1] includePaths = .(root);
		shaders.SetIncludePaths(includePaths);

		// Nothing was registered, so this can only have come from the provider, and it only
		// compiles if the include resolved.
		Test.Assert(shaders.GetVariant("viainclude", .Fragment, .None) != null,
			"the source was pulled and its include resolved");
	}

	/// A provider fetched source is canonicalized against its declared mask, EXACTLY as the
	/// cooked path does. Development and a shipped build must agree, and it dedupes: a stage
	/// that ignores a flag stops compiling a variant per value of it.
	[Test]
	public static void DevelopmentCanonicalizesLikeTheCookedPath()
	{
		let root = MakeRoot("canon", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		// Declares SKINNED only.
		Write(root, "declared.ps.hlsl", """
			// variants: SKINNED
			float4 main() : SV_Target0 {
			#ifdef SKINNED
			    return float4(1, 0, 0, 1);
			#endif
			    return float4(0, 0, 1, 1);
			}
			""");

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

		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize(root) case .Ok);

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.SetSourceProvider(provider);

		let plain = shaders.GetVariant("declared", .Fragment, .None);
		Test.Assert(plain != null);

		// GBUFFER is not declared, so it is stripped and this must be the SAME module, not
		// a second compile of an identical shader.
		let undeclared = shaders.GetVariant("declared", .Fragment, .GBuffer);
		Test.Assert(undeclared === plain, "an undeclared flag collapsed onto the same variant");

		// SKINNED is declared, so it is genuinely a different variant.
		let skinned = shaders.GetVariant("declared", .Fragment, .Skinned);
		Test.Assert(skinned !== plain);

		// A registered source has no mask, so its raw flags all apply.
		shaders.RegisterSource("raw", .Fragment, """
			float4 main() : SV_Target0 {
			#ifdef GBUFFER
			    return float4(1, 0, 0, 1);
			#endif
			    return float4(0, 0, 1, 1);
			}
			""");
		let rawPlain = shaders.GetVariant("raw", .Fragment, .None);
		let rawGBuffer = shaders.GetVariant("raw", .Fragment, .GBuffer);
		Test.Assert(rawPlain != null && rawGBuffer != null);
		Test.Assert(rawPlain !== rawGBuffer,
			"a registered source applies every requested flag");
	}

	/// An edit is picked up: the changed source is dropped, its variants go, and the version
	/// moves so a pipeline cache rebuilds.
	[Test]
	public static void AnEditIsPickedUp()
	{
		let root = MakeRoot("reload", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		Write(root, "live.ps.hlsl", "float4 main() : SV_Target0 { return float4(1,0,0,1); }\n");

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

		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize(root) case .Ok);

		let shaders = scope Sedulous.Shaders.ShaderSystem(compiler, device);
		// Nothing here reads the bytecode's quality, and optimization is most of what
		// DXC spends its time on.
		shaders.OptimizationLevel = 0;
		shaders.SetSourceProvider(provider);
		Test.Assert(shaders.GetVariant("live", .Fragment, .None) != null);
		Test.Assert(shaders.Version("live") == 0);

		Write(root, "live.ps.hlsl", "float4 main() : SV_Target0 { return float4(0,1,0,1); }\n");

		// The provider throttles its sweep, so the poll has to be driven the number of times
		// a frame loop would drive it.
		int reloaded = 0;
		for (int i < FileShaderSourceProvider.PollEveryNCalls * 2)
		{
			reloaded += shaders.PumpReloads();
			if (reloaded > 0)
				break;
		}

		Test.Assert(reloaded > 0, "the edit was seen");
		Test.Assert(shaders.Version("live") >= 1, "and the version moved for the rebuild");
		Test.Assert(shaders.GetVariant("live", .Fragment, .None) != null,
			"and the shader still resolves afterwards");
	}

	/// Reload detection works with an ABSOLUTE root.
	///
	/// A regression test: the mount joins its root with each relative name, so a root that
	/// is already absolute is the case where a path can end up normalised differently from
	/// the one the change source reports, and a changed file then matches nothing. Nothing
	/// changing is reported until something does.
	[Test]
	public static void ReloadWorksWithAnAbsoluteRoot()
	{
		let root = MakeRoot("absolute", .. scope String());
		defer { RemoveDirectoryRecursive(root); }
		// MakeRoot already produces an absolute path, which is the point: this asserts the
		// provider handles it rather than only handling a relative one.
		Test.Assert(PathIsAbsolute(root), "the root under test is absolute");

		Write(root, "hot.ps.hlsl", "float4 main() : SV_Target0 { return float4(1,0,0,1); }\n");

		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize(root) case .Ok);

		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }

		// Nothing has been touched since the mount was made, so polling past the throttle
		// must report nothing. A provider that reports a change here would reload every
		// frame forever.
		for (int i < FileShaderSourceProvider.PollEveryNCalls * 2 + 1)
			provider.PollChanges(changed);
		Test.Assert(changed.IsEmpty, "an untouched tree reports no changes");

		Write(root, "hot.ps.hlsl", "float4 main() : SV_Target0 { return float4(0,1,0,1); }\n");

		for (int i < FileShaderSourceProvider.PollEveryNCalls * 2 + 1)
		{
			if (provider.PollChanges(changed))
				break;
		}
		Test.Assert(changed.Count == 1, "and the edit is seen through the absolute root");
		Test.Assert(changed[0] == "hot");
	}

	/// An .hlsli edit reloads EVERY shader the provider serves. Which shaders include it is
	/// unknown, so a full recompile is the correct answer rather than a guess.
	[Test]
	public static void AnIncludeEditReloadsEverything()
	{
		let root = MakeRoot("includereload", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		Write(root, "shared.hlsli", "static const float kTint = 1.0;\n");
		Write(root, "one.ps.hlsl", """
			#include "shared.hlsli"
			float4 main() : SV_Target0 { return float4(kTint, 0, 0, 1); }
			""");
		Write(root, "two.ps.hlsl", """
			#include "shared.hlsli"
			float4 main() : SV_Target0 { return float4(0, kTint, 0, 1); }
			""");

		let provider = scope FileShaderSourceProvider();
		Test.Assert(provider.Initialize(root) case .Ok);

		Write(root, "shared.hlsli", "static const float kTint = 0.5;\n");

		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		for (int i < FileShaderSourceProvider.PollEveryNCalls * 2)
		{
			if (provider.PollChanges(changed))
				break;
		}

		Test.Assert(changed.Count == 2,
			"an include edit reports every shader, since the includers are unknown");
	}
}
