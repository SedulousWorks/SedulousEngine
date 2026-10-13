using System;
using Sedulous.Core;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.VFS;

namespace Sedulous.Shaders.Pipeline.Tests;

/// Surface shaders: a `// surface:` line makes a shader's text a Surface() (and optionally a
/// Vertex()) the engine wraps in its templates, as three programs (forward, depth, pick) with the
/// template's lattices. Each compiles in every variant against the engine's library; an error in
/// the author's text keeps the author's line; the directive's word and a commented-out Vertex()
/// are read correctly; a property named like an engine declaration is reported at the property.
class SurfaceShaderTests
{
	/// Waves: a lit surface that moves its vertices and scrolls a texture.
	private const String cWaves = """
		// surface: lit
		properties
		{
		    Color   Water  = (0.1, 0.4, 0.8, 1);
		    float   Height = 0.2 [0, 1];
		    Texture Ripples;
		    Sampler MainSampler;
		}
		void Surface(SurfaceInput input, inout SurfaceOutput surface) {
		    float r = Ripples.Sample(MainSampler, input.uv + Time() * 0.1).r;
		    surface.albedo = Water.rgb * (0.5 + 0.5 * r);
		    surface.roughness = 0.2;
		}
		void Vertex(inout VertexInput v) {
		    v.position.y += sin(v.position.x * 2.0 + Time()) * Height;
		}
		""";

	/// A cut-out leaf: unlit, its alpha from a texture, a commented-out Vertex() example.
	private const String cLeaf = """
		// surface: unlit
		properties
		{
		    float   AlphaCutoff = 0.4 [0, 1];
		    Texture Mask;
		    Sampler MainSampler;
		}
		// void Vertex(inout VertexInput v) { }   (none: an example)
		void Surface(SurfaceInput input, inout SurfaceOutput surface) {
		    surface.albedo = input.color.rgb;
		    surface.alpha = Mask.Sample(MainSampler, input.uv).a;
		}
		""";

	private static bool HaveCompiler()
	{
		let compiler = scope ShaderCompiler();
		return compiler.Initialize() case .Ok;
	}

	private static ShaderCheckOptions LibraryOptions(String library)
	{
		DataPath(FindDataRoot(.. scope String()), "Shaders", library);
		var options = ShaderCheckOptions();
		options.ShaderLibrary = library;
		return options;
	}

	private static String Errors(ShaderCheck check, String outText)
	{
		for (let error in check.Errors)
			error.Format(outText..Append('\n'));
		return outText;
	}

	[Test]
	public static void ALitSurfaceWithVertexIsThreeProgramsEveryVariantCompiling()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		let check = scope ShaderCheck();
		check.Run(cWaves, "Waves.hlsl", LibraryOptions(scope .()));
		Test.Assert(check.IsOk, Errors(check, .. scope .()));
		Test.Assert(check.Surface == .Lit);
		Test.Assert(check.HasVertex);
		Test.Assert(check.Programs.Count == 3);
		Test.Assert(check.Programs[0].Suffix.IsEmpty);
		Test.Assert(check.Programs[1].Suffix == ShaderSource.cDepthProgramSuffix);
		Test.Assert(check.Programs[2].Suffix == ShaderSource.cPickProgramSuffix);
		Test.Assert(check.Programs[0].FragmentMask == ShaderCheck.cSurfaceForwardFragmentMask);
		Test.Assert(check.Programs[1].VertexMask == ShaderCheck.cSurfaceDepthVertexMask);
		Test.Assert(check.Programs[0].Text.Contains("#define SURFACE_HAS_VERTEX 1"));
		Test.Assert(check.Programs[0].Text.Contains("#line 1 \"Waves.hlsl\""));
		Test.Assert(check.Block.Properties.Count == 4);
	}

	[Test]
	public static void AnUnlitCutOutUsesItsAlphaCutoffAndACommentedVertexIsNone()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		let check = scope ShaderCheck();
		check.Run(cLeaf, "Leaf.hlsl", LibraryOptions(scope .()));
		Test.Assert(check.IsOk, Errors(check, .. scope .()));
		Test.Assert(check.Surface == .Unlit);
		Test.Assert(!check.HasVertex);
		Test.Assert(check.Programs[1].Text.Contains("#define SURFACE_HAS_ALPHA_CUTOFF 1"));
		Test.Assert(!check.Programs[1].Text.Contains("SURFACE_HAS_VERTEX"));
	}

	[Test]
	public static void AnErrorInSurfaceKeepsTheAuthorsLine()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		var options = LibraryOptions(scope .());
		options.Depth = .BaseVariants;
		let check = scope ShaderCheck();
		check.Run("// surface: lit\nproperties\n{\n    float Glow = 1;\n}\nvoid Surface(SurfaceInput input, inout SurfaceOutput surface) {\n    surface.emissive = Glw;\n}\n",
			"Lava.hlsl", options);
		Test.Assert(!check.Errors.IsEmpty);
		Test.Assert(check.Errors[0].File == "Lava.hlsl");
		Test.Assert(check.Errors[0].Line == 7, Errors(check, .. scope .()));
	}

	[Test]
	public static void TheDirectivesWordVariantsLinesAndALowLevelShader()
	{
		let bad = scope ShaderCheck();
		bad.Run("// surface: shiny\n", "a.hlsl");
		Test.Assert(bad.Errors.Count == 1);
		Test.Assert(bad.Errors[0].Line == 1);
		Test.Assert(bad.Errors[0].Message.Contains("'shiny' is not a surface model"));

		let variants = scope ShaderCheck();
		variants.Run("// surface: lit\n// variants(fragment): GBUFFER\n", "b.hlsl");
		Test.Assert(variants.Errors.Count == 1);
		Test.Assert(variants.Errors[0].Message.Contains("variants are the engine's"));

		// A low-level shader stays one program of its own.
		let low = scope ShaderCheck();
		low.Run("properties\n{\n    float A = 1;\n}\n", "c.hlsl");
		Test.Assert(low.Surface == .None);

		Test.Assert(ShaderCheck.DefinesVertexFunction("void  Vertex (inout VertexInput v) {}"));
		Test.Assert(!ShaderCheck.DefinesVertexFunction("/* void Vertex(inout VertexInput v) {} */ void VertexColour() {}"));
		Test.Assert(!ShaderCheck.DefinesVertexFunction("voidVertex(x)"));
	}

	/// A property's name is a global in the generated code: one the engine's shaders already
	/// declare is reported at the property's line, not in the engine's file.
	[Test]
	public static void APropertyNamedLikeAnEngineDeclarationIsReportedAtTheProperty()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		var options = LibraryOptions(scope .());
		options.Depth = .BaseVariants;
		let check = scope ShaderCheck();
		check.Run("// surface: lit\nproperties\n{\n    Color Tint = (1, 1, 1, 1);\n}\nvoid Surface(SurfaceInput input, inout SurfaceOutput surface) { surface.albedo = Tint.rgb; }\n",
			"Paint.hlsl", options);
		Test.Assert(!check.Errors.IsEmpty);
		Test.Assert(check.Errors[0].File == "Paint.hlsl", Errors(check, .. scope .()));
		Test.Assert(check.Errors[0].Line == 4);
		Test.Assert(check.Errors[0].Message.Contains("property 'Tint' takes a name the engine's shaders"));
	}
}
