using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.VFS;

namespace Sedulous.Shaders.Pipeline.Tests;

/// The custom shader cook: one .hlsl file with both stages, its properties block and its variant
/// lattices, through ShaderAssetBuilder into an output content database. A good shader cooks every
/// declared variant and writes the expanded source, both entries, both lattices and the property
/// table; a broken one fails the cook with its file and line; a flag the file tests but no stage
/// declares fails it; the toon sample's real shader, which includes the engine's vertex library,
/// cooks against the data root.
class ShaderAssetCookTests
{
	private const String cSourceRoot = "scratch_shaders_pipeline_src";
	private const String cCookedRoot = "scratch_shaders_pipeline_out";
	private const String cProductType = "Sedulous.Shaders.Resource.ShaderSource";

	/// A one file shader: a properties block, a lattice per stage, VSMain and PSMain.
	private const String cGood = """
		// variants(vertex): SKINNED
		// variants(fragment): ALPHA_TEST
		properties
		{
		    Color   Tint     = (1, 0.5, 0);
		    float   Strength = 2 [0, 4];
		    Texture AlbedoMap;
		    Sampler MainSampler;
		}
		struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
		VSOut VSMain(uint id : SV_VertexID) {
		    VSOut o; o.uv = float2(id & 1, id >> 1);
		#ifdef SKINNED
		    o.uv *= 2.0;
		#endif
		    o.pos = float4(o.uv, 0, 1); return o;
		}
		float4 PSMain(VSOut input) : SV_Target0 {
		    float4 c = AlbedoMap.Sample(MainSampler, input.uv) * Tint * Strength;
		#ifdef ALPHA_TEST
		    if (c.a < 0.5) discard;
		#endif
		    return c;
		}
		""";

	/// The same kind of shader with a mistake on line 6.
	private const String cBroken = """
		properties
		{
		    float Strength = 2;
		}
		float4 VSMain(uint id : SV_VertexID) : SV_Position { return float4(0, 0, 0, 1); }
		float4 PSMain() : SV_Target0 { return float4(1, 1, 1, 1) * Strenght; }
		""";

	/// Tests GBUFFER, which neither stage declares.
	private const String cUndeclared = """
		// variants(fragment): ALPHA_TEST
		float4 VSMain(uint id : SV_VertexID) : SV_Position { return float4(0, 0, 0, 1); }
		float4 PSMain() : SV_Target0 {
		#ifdef GBUFFER
		    return float4(0, 0, 0, 1);
		#endif
		    return float4(1, 1, 1, 1);
		}
		""";

	/// Keeps the error lines logged, so a test can read what the cook reported.
	private class ErrorLines : ILogger
	{
		public LogLevel MinimumLogLevel { get; set; } = .Trace;
		public String Name { get; private set; } = new .("errors") ~ delete _;
		public String Text = new .() ~ delete _;

		public void Log(LogLevel logLevel, StringView format, params Object[] args)
		{
			if (logLevel != .Error)
				return;
			Text.AppendF(format, params args);
			Text.Append('\n');
		}
	}

	private static bool HaveCompiler()
	{
		let compiler = scope ShaderCompiler();
		return compiler.Initialize() case .Ok;
	}

	private static void Save(NativeFileSystem mount, StringView name, StringView text)
		=> Test.Assert(mount.Save(name, Span<uint8>((uint8*)text.Ptr, text.Length)) case .Ok);

	private static void Fresh()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		ShadersPipeline.RegisterAll();
		ShaderResources.RegisterAll();
	}

	private static void Clean()
	{
		RemoveDirectoryRecursive(cSourceRoot);
		RemoveDirectoryRecursive(cCookedRoot);
	}

	/// One cook of `source` saved as shader.hlsl, its product read back into `outProduct` (null
	/// when the cook failed, else the caller's to delete).
	private static Result<void, ErrorCode> Cook(StringView source, StringView dataRoot, out ShaderSource outProduct,
		StringView name = "custom")
	{
		outProduct = null;
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		Save(sourceMount, "shader.hlsl", source);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);

		Guid id;
		Result<void, ErrorCode> result;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("shader", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;
			let asset = scope ShaderAsset();
			ShaderImporter.Import(name, "shader.hlsl", asset);
			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			result = scope ShaderAssetBuilder(dataRoot).Build(asset, context);
		}
		if (result case .Ok)
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let object = database.ReadObject(id);
			outProduct = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ShaderSource;
		}
		return result;
	}

	[Test]
	public static void AOneFileShaderCooksItsVariantsEntriesLatticesAndTable()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		Fresh();
		defer Clean();

		Test.Assert(Cook(cGood, default, let source) case .Ok);
		Test.Assert(source != null);
		defer delete source;
		Test.Assert(source.Name == "custom");
		Test.Assert((source.VertexEntryPoint == "VSMain") && (source.FragmentEntryPoint == "PSMain"));
		Test.Assert(source.VertexVariantMask == (uint32)ShaderFlags.Skinned);
		Test.Assert(source.FragmentVariantMask == (uint32)ShaderFlags.AlphaTest);
		// The expanded source: the block replaced by its declarations, line numbers kept.
		Test.Assert(!source.FragmentSource.Contains("properties\n{"));
		Test.Assert(source.FragmentSource.Contains("cbuffer Material : register(b0, space2)"));
		Test.Assert(source.FragmentSource.Contains("#line 10 \"shader.hlsl\""));

		let table = scope List<ShaderProperty>();
		defer { ClearAndDeleteItems!(table); }
		source.GetProperties(table);
		Test.Assert(table.Count == 4);
		Test.Assert((table[0].Name == "Tint") && (table[0].Type == .Color) && (table[0].Value.W == 1.0f));
		Test.Assert((table[1].Name == "Strength") && (table[1].Offset == 16) && table[1].HasRange && (table[1].RangeMax == 4.0f));
		Test.Assert(table[2].Type == .Texture);
		Test.Assert(table[3].Type == .Sampler);
		Test.Assert(source.UniformSize == 32);
	}

	[Test]
	public static void ACompileErrorFailsTheCookWithTheFileAndTheAuthorsLine()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		Fresh();
		defer Clean();
		let errors = new ErrorLines();
		InitGlobalLogger(errors, true);
		defer ShutdownGlobalLogger();

		Test.Assert(Cook(cBroken, default, ?) case .Err);
		Test.Assert(errors.Text.Contains("shader.hlsl:6:"), scope $"the file and line: {errors.Text}");
		Test.Assert(errors.Text.Contains("Strenght"));
	}

	[Test]
	public static void AMalformedPropertiesBlockFailsWithItsLine()
	{
		Fresh();
		defer Clean();
		let errors = new ErrorLines();
		InitGlobalLogger(errors, true);
		defer ShutdownGlobalLogger();

		Test.Assert(Cook("properties\n{\n    Colour Tint;\n}\n", default, ?) case .Err);
		Test.Assert(errors.Text.Contains("shader.hlsl:3: unknown property type 'Colour'"), scope $"{errors.Text}");
	}

	[Test]
	public static void AFlagTheFileTestsButNoStageDeclaresFailsTheCook()
	{
		Fresh();
		defer Clean();
		let errors = new ErrorLines();
		InitGlobalLogger(errors, true);
		defer ShutdownGlobalLogger();

		Test.Assert(Cook(cUndeclared, default, ?) case .Err);
		Test.Assert(errors.Text.Contains("tests GBUFFER but no stage declares it"), scope $"{errors.Text}");
	}

	/// A source file that is not there is an ERROR rather than an empty shader: an empty one
	/// would cook, ship, and fail to draw with nothing said about why.
	[Test]
	public static void AMissingSourceFileFailsTheBuild()
	{
		Fresh();
		defer Clean();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("missing", cProductType);
		Test.Assert(instance != null);

		let asset = scope ShaderAsset();
		ShaderImporter.Import("missing", "does_not_exist.hlsl", asset);
		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope ShaderAssetBuilder().Build(asset, context) case .Err);
	}

	/// The toon sample's shader: a low level shader that includes the engine's forward vertex
	/// library (under VSMain) and declares the frame's sets itself. It cooks against the data
	/// root, every variant of both stages.
	[Test]
	public static void TheToonSamplesShaderCooksAgainstTheEnginesShaderLibrary()
	{
		let dataRoot = FindDataRoot(.. scope String());
		Test.Assert(!dataRoot.IsEmpty);
		let toon = scope String();
		Test.Assert(System.IO.File.ReadAllText(DataPath(dataRoot, "Assets/shaders/toon/toon.hlsl", .. scope .()), toon) case .Ok);
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		Fresh();
		defer Clean();
		let errors = new ErrorLines();
		InitGlobalLogger(errors, true);
		defer ShutdownGlobalLogger();

		let result = Cook(toon, dataRoot, let source);
		Test.Assert(result case .Ok, scope $"the toon cooks: {errors.Text}");
		Test.Assert(source != null);
		defer delete source;
		Test.Assert(source.VertexVariantMask == (uint32)(ShaderFlags.Skinned | .Instanced));
		Test.Assert(source.FragmentVariantMask == (uint32)(ShaderFlags.AlphaTest | .GBuffer | .Dither));
		Test.Assert(!source.PropertyNames.IsEmpty);
	}

	/// One name keys a shader in the shader system and a shipped build's pack, so a project shader
	/// named like an engine shader would replace the engine's everywhere. The cook refuses it.
	[Test]
	public static void AProjectShaderCannotTakeAnEngineShadersName()
	{
		let dataRoot = FindDataRoot(.. scope String());
		Test.Assert(!dataRoot.IsEmpty);
		Fresh();
		defer Clean();
		let errors = new ErrorLines();
		InitGlobalLogger(errors, true);
		defer ShutdownGlobalLogger();

		Test.Assert(Cook(cGood, dataRoot, ?, "forward") case .Err);
		Test.Assert(errors.Text.Contains("the name 'forward' is the engine's shader"), scope $"{errors.Text}");
	}
}
