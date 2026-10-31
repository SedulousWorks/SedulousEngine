using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// Effect blocks through the compiler: an include's `effect` block is expanded by the engine's
/// include handler on the cook's disk route and the editor's resolver route alike, and one in the
/// source itself is expanded too; a malformed one fails the compile naming its file and line.
class ShaderEffectCompileTests
{
	public const String cWindEffect = """
		// a vertex effect's parameters
		effect Wind : WIND
		{
		    float Strength = 0 [0, 2] (gate);
		    float Speed = 1 [0, 20];
		    float Height = 1 [0.01, 100];
		}
		float WindAmount() { return Wind.Strength * Wind.Speed; }

		""";

	/// An effect whose third line declares a texture, which an effect may not.
	public const String cBadEffect = """
		effect Wind : WIND
		{
		    Texture Gusts;
		    float Strength (gate);
		}

		""";

	/// Reads the effect's members by their declared names, through the effect's buffer.
	private const String cReadsWind = """
		#include "fx_wind.hlsli"
		float4 main() : SV_Target {
		    return float4(Wind.Strength, Wind.Speed, Wind.Height, WindAmount());
		}
		""";

	/// Serves the effect headers from memory.
	private class EffectIncludeResolver : IShaderIncludeResolver
	{
		public bool LoadInclude(StringView path, String outSource)
		{
			if (path == "fx_wind.hlsli")
			{
				outSource.Set(cWindEffect);
				return true;
			}
			if (path == "fx_bad.hlsli")
			{
				outSource.Set(cBadEffect);
				return true;
			}
			return false;
		}
	}

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

	/// A fresh scratch directory for one test, emptied first.
	private static void MakeScratch(StringView name, String outPath)
	{
		System.IO.Path.GetTempPath(outPath).IgnoreError();
		outPath.AppendF("sedulous_effects_{}", name);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	private static void WriteScratch(StringView directory, StringView fileName, StringView text)
	{
		let path = PathJoin(directory, fileName, .. scope String());
		Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok, path);
	}

	/// Compiles `source` as a fragment stage; its success, and its messages in `outMessages`.
	private static bool CompileFragment(ShaderCompiler compiler, StringView source, CompileOptions options,
		String outMessages)
	{
		var result = compiler.Compile(.((uint8*)source.Ptr, source.Length), .Fragment, "main", .SPIRV, options);
		defer result.Dispose();
		outMessages.Set(result.Messages);
		return result.Success;
	}

	[Test]
	public static void AnIncludesEffectCompilesFromDiskBesideItsIncluderOrOnTheSearchPath()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let root = MakeScratch("disk", .. scope String());
		defer RemoveDirectoryRecursive(root);
		let sub = PathJoin(root, "sub", .. scope String());
		CreateDirectory(sub);
		WriteScratch(root, "fx_wind.hlsli", cWindEffect);
		// Only beside its includer (sub/), never on the search path: found relative to the
		// includer first, as DXC's own handler does, and its effect expanded there too.
		WriteScratch(sub, "fx_sibling.hlsli", "effect Fade : DITHER\n{\n    float Amount = 1 (gate);\n}\n");
		WriteScratch(sub, "fx_nested.hlsli", "#include \"fx_sibling.hlsli\"\nfloat FadeAmount() { return Fade.Amount; }\n");

		StringView[1] includePaths = .(root);
		var options = CompileOptions();
		options.IncludePaths = includePaths;
		options.SourceName = "reads_wind.hlsl";

		let messages = scope String();
		Test.Assert(CompileFragment(compiler, cReadsWind, options, messages), messages);
		Test.Assert(CompileFragment(compiler, "#include \"sub/fx_nested.hlsli\"\nfloat4 main() : SV_Target { return FadeAmount(); }\n",
			options, messages), messages);

		// An include without an effect block is served as it was read.
		WriteScratch(root, "fx_plain.hlsli", "float Plain() { return 2; }\n");
		Test.Assert(CompileFragment(compiler, "#include \"fx_plain.hlsli\"\nfloat4 main() : SV_Target { return Plain(); }\n",
			options, messages), messages);

		// A missing include is still a reported error.
		Test.Assert(!CompileFragment(compiler, "#include \"fx_absent.hlsli\"\nfloat4 main() : SV_Target { return 0; }\n",
			options, messages));
	}

	[Test]
	public static void AnIncludesEffectCompilesThroughAResolver()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let resolver = scope EffectIncludeResolver();
		var options = CompileOptions();
		options.IncludeResolver = resolver;
		let messages = scope String();
		Test.Assert(CompileFragment(compiler, cReadsWind, options, messages), messages);

		// The effect's members are not global names: a shader whose own material has a `Speed`
		// and a `Height` (a surface shader declares WIND whatever its properties are called)
		// compiles.
		let ownSpeed = """
			cbuffer Material : register(b0, space2) {
			    float Speed;
			    float Height;
			};
			#include "fx_wind.hlsli"
			float4 main() : SV_Target {
			    return float4(Speed, Height, Wind.Speed, Wind.Height);
			}
			""";
		Test.Assert(CompileFragment(compiler, ownSpeed, options, messages), messages);
	}

	[Test]
	public static void AnEffectBlockInTheSourceItselfIsExpandedToo()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let top = "effect Wind : WIND\n" +       // 1
			"{\n" +                              // 2
			"    float Strength = 0 (gate);\n" + // 3
			"}\n" +                              // 4
			"float4 main() : SV_Target {\n" +    // 5
			"    return Wind.Strength * Sped;\n" + // 6: the mistake
			"}\n";
		var options = CompileOptions();
		options.SourceName = "Top.hlsl";
		let messages = scope String();
		Test.Assert(!CompileFragment(compiler, top, options, messages));
		Test.Assert(messages.Contains("Top.hlsl:6:"), scope $"the line kept after the block: {messages}");
		Test.Assert(messages.Contains("Sped"), messages);
		Test.Assert(!messages.Contains("'Strength'"), "the block's member is declared");
	}

	[Test]
	public static void AMalformedEffectInAnIncludeFailsTheCompileNamingItsFileAndLine()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let readsBad = "#include \"fx_bad.hlsli\"\nfloat4 main() : SV_Target { return Wind.Strength; }\n";

		// Disk.
		let root = MakeScratch("bad", .. scope String());
		defer RemoveDirectoryRecursive(root);
		WriteScratch(root, "fx_bad.hlsli", cBadEffect);
		StringView[1] includePaths = .(root);
		var disk = CompileOptions();
		disk.IncludePaths = includePaths;
		let messages = scope String();
		Test.Assert(!CompileFragment(compiler, readsBad, disk, messages));
		Test.Assert(messages.Contains("fx_bad.hlsli:3:"), messages);
		Test.Assert(messages.Contains("uniforms only"), messages);

		// A resolver.
		let resolver = scope EffectIncludeResolver();
		var resolved = CompileOptions();
		resolved.IncludeResolver = resolver;
		let resolvedMessages = scope String();
		Test.Assert(!CompileFragment(compiler, readsBad, resolved, resolvedMessages));
		Test.Assert(resolvedMessages.Contains("fx_bad.hlsli:3:"), resolvedMessages);
		Test.Assert(resolvedMessages.Contains("uniforms only"), resolvedMessages);
	}
}
