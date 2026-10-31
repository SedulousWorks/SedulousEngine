using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// The properties block a custom shader declares its material parameters in: HLSL's cbuffer
/// packing, the parse (every type, defaults, ranges, slots), every malformed line reported with
/// its line, and the expanded source compiling with the author's line numbers intact.
class ShaderPropertiesTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	/// The line of the single error a source yields, and its message.
	private static uint32 OnlyErrorLine(StringView source, String outMessage = null)
	{
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse(source, block);
		Test.Assert(block.Errors.Count == 1, scope $"one error in: {source}");
		if (block.Errors.Count != 1)
			return 0;
		outMessage?.Set(block.Errors[0].Message);
		return block.Errors[0].Line;
	}

	[Test]
	public static void HlslPackingAlignsToSizeAndNeverCrossesARow()
	{
		uint32 cursor = 0;
		Test.Assert(ShaderProperties.PackCbufferMember(ref cursor, 12) == 0); // float3
		Test.Assert(ShaderProperties.PackCbufferMember(ref cursor, 4) == 12, "a float shares the float3's row");
		Test.Assert(ShaderProperties.PackCbufferMember(ref cursor, 8) == 16); // float2
		Test.Assert(ShaderProperties.PackCbufferMember(ref cursor, 4) == 24);
		Test.Assert(ShaderProperties.PackCbufferMember(ref cursor, 8) == 32, "a float2 at 28 would straddle");
		Test.Assert(ShaderProperties.PackCbufferMember(ref cursor, 16) == 48, "a float4 starts a row");
		Test.Assert(ShaderProperties.CbufferSize(cursor) == 64);
		uint32 odd = 4;
		Test.Assert(ShaderProperties.PackCbufferMember(ref odd, 12) == 4, "a float3 fits the rest of the row");
	}

	[Test]
	public static void EveryTypeItsDefaultRangesAndItsSlot()
	{
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("""
			// the toon
			properties
			{
			    Color       BaseColor = (1, 0.5, 0.25);
			    float       Bands     = 3 [1, 8];
			    float3      Light     = (0, 1, 0);
			    float       Rim;      // a comment
			    float2      Scroll    = (0.5, -1e-1);
			    ColorHdr    Glow;
			    int         Steps     = 4 [0, 16];
			    Texture     AlbedoMap;
			    TextureCube Env;
			    Sampler     MainSampler;
			}
			float4 PSMain() : SV_Target0 { return BaseColor; }
			""", block);
		Test.Assert(block.Present && block.IsOk);
		Test.Assert((block.FirstLine == 2) && (block.LastLine == 14));
		Test.Assert(block.Properties.Count == 10);

		let baseColor = block.Properties[0];
		Test.Assert(baseColor.Type == .Color);
		Test.Assert(Near(baseColor.Value.Y, 0.5f));
		Test.Assert(baseColor.Value.W == 1.0f, "opaque when left out");
		Test.Assert((baseColor.Offset == 0) && (baseColor.Size == 16) && (baseColor.Line == 4));

		let bands = block.Properties[1];
		Test.Assert(bands.Value.X == 3.0f);
		Test.Assert(bands.HasRange && (bands.RangeMax == 8.0f));
		Test.Assert(bands.Offset == 16);

		Test.Assert(block.Properties[2].Offset == 20, "a float3 fits the rest of Bands' row");
		Test.Assert(block.Properties[3].Offset == 32);
		Test.Assert(block.Properties[3].Value.X == 0.0f, "no default: zero");
		Test.Assert(block.Properties[4].Offset == 36, "a float2 within its row");
		Test.Assert(Near(block.Properties[4].Value.Y, -0.1f));
		Test.Assert(block.Properties[5].Type == .ColorHdr);
		Test.Assert(block.Properties[5].Offset == 48, "at 44 it would cross a row");
		Test.Assert(block.Properties[5].Value.W == 1.0f, "black at intensity 1 by default");
		Test.Assert(block.Properties[6].Offset == 64); // the int
		Test.Assert(block.UniformSize == 80);

		Test.Assert(block.Properties[7].Binding == 0); // AlbedoMap: t0
		Test.Assert(block.Properties[8].Binding == 1); // Env: t1
		Test.Assert(block.Properties[9].Binding == 0); // MainSampler: s0
		Test.Assert(block.Properties[9].Size == 0);
	}

	[Test]
	public static void ASourceWithoutABlockIsAShaderWithoutParameters()
	{
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("// properties are not declared here\nfloat4 x;\n", block);
		Test.Assert(!block.Present && block.IsOk);
		let expanded = scope String();
		ShaderProperties.Expand("float4 x;\n", "A.hlsl", expanded, scope ShaderPropertiesBlock());
		Test.Assert(expanded == "float4 x;\n");
	}

	[Test]
	public static void EveryMalformedLineIsReportedWithItsLine()
	{
		let message = scope String();
		Test.Assert(OnlyErrorLine("properties {\n  Colour Tint;\n}\n", message) == 2);
		Test.Assert(message.Contains("unknown property type 'Colour'"));
		Test.Assert(OnlyErrorLine("properties {\n  float;\n}\n") == 2);                 // no name
		Test.Assert(OnlyErrorLine("properties {\n  float A;\n  float A;\n}\n") == 3);    // twice
		Test.Assert(OnlyErrorLine("properties {\n  float2 A = 1;\n}\n") == 2);           // count
		Test.Assert(OnlyErrorLine("properties {\n  Texture A = 1;\n}\n") == 2);          // resource
		Test.Assert(OnlyErrorLine("properties {\n  Color A [0, 1];\n}\n") == 2);         // range type
		Test.Assert(OnlyErrorLine("properties {\n  float A [2, 1];\n}\n") == 2);         // range order
		Test.Assert(OnlyErrorLine("properties {\n  float A = 1\n}\n") == 2);             // no ;
		Test.Assert(OnlyErrorLine("properties {\n  float A; float B;\n}\n") == 2);       // two
		Test.Assert(OnlyErrorLine("properties {\n  float A = (1, 2;\n}\n") == 2);        // no )
		Test.Assert(OnlyErrorLine("\nproperties {\n  float A;\n") == 2);                  // no }
		Test.Assert(OnlyErrorLine("properties\n") == 1);                                  // no {
	}

	/// The expanded source is what the compiler sees: the block becomes the set-2 declarations,
	/// and `#line` keeps every later line's number, so a mistake after the block is reported
	/// where its author sees it.
	[Test]
	public static void TheExpandedSourceCompilesAndKeepsTheAuthorsLineNumbers()
	{
		let compiler = new ShaderCompiler();
		defer delete compiler;
		if (compiler.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		bool Compile(StringView source, String messages)
		{
			let expanded = scope String();
			let block = scope ShaderPropertiesBlock();
			ShaderProperties.Expand(source, "Toon.hlsl", expanded, block);
			Test.Assert(block.IsOk);
			var options = CompileOptions();
			options.SourceName = "Toon.hlsl";
			var result = compiler.Compile(.((uint8*)expanded.Ptr, expanded.Length), .Fragment, "PSMain", .SPIRV, options);
			defer result.Dispose();
			messages.Set(result.Messages);
			return result.Success;
		}

		let messages = scope String();
		Test.Assert(Compile("""
			properties
			{
			    Color   Tint = (1, 0, 0);
			    float   Strength = 2;
			    Texture AlbedoMap;
			    Sampler MainSampler;
			}
			float4 PSMain(float2 uv : TEXCOORD0) : SV_Target0 {
			    return AlbedoMap.Sample(MainSampler, uv) * Tint * Strength;
			}
			""", messages), scope $"the expanded block compiles: {messages}");
		// The block is longer than what replaces it, so only #line keeps the later numbers.
		Test.Assert(!Compile("""
			properties
			{
			    // how strong it is

			    float Strength = 2;

			}
			float4 PSMain() : SV_Target0 {
			    return float4(1, 1, 1, 1) * Strenght;
			}
			""", messages));
		Test.Assert(messages.Contains("Toon.hlsl:9:"), scope $"the author's line: {messages}");
	}

	// ---- effect blocks: the properties grammar in an include, for an effect's own parameters,
	// with a header naming the effect and its variant flag ----

	/// The single error an effect source yields: its line, and its message in `outMessage`.
	private static uint32 OnlyEffectErrorLine(StringView source, String outMessage = null)
	{
		let block = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect(source, 0, block);
		Test.Assert(block.Present, scope $"an effect in: {source}");
		Test.Assert(block.Errors.Count == 1, scope $"one error in: {source}");
		if (block.Errors.Count != 1)
			return 0;
		outMessage?.Set(block.Errors[0].Message);
		return block.Errors[0].Line;
	}

	[Test]
	public static void AnEffectsNameFlagTableOffsetsAndGate()
	{
		let block = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("// wind\n" +                    // 1
			"effect Wind : WIND\n" +                                  // 2
			"{\n" +                                                   // 3
			"    float  Strength  = 0 [0, 2] (gate);\n" +             // 4
			"    float  Speed     = 1 [0, 20];\n" +                   // 5
			"    float  Height    = 1 [0.01, 100]; // m\n" +          // 6
			"    float3 Direction = (1, 0, 0);\n" +                   // 7
			"}\n" +                                                   // 8
			"float Sway() { return Strength; }\n", 0, block);
		Test.Assert(block.Present);
		Test.Assert(block.IsOk);
		Test.Assert((block.FirstLine == 2) && (block.LastLine == 8));
		let effect = block.Effect;
		Test.Assert(effect.Name == "Wind");
		Test.Assert(effect.Flag == .Wind);
		Test.Assert(effect.Properties.Count == 4);
		Test.Assert(effect.GateIndex == 0);
		Test.Assert((effect.Gate != null) && (effect.Gate.Name == "Strength"));

		let strength = effect.Properties[0];
		Test.Assert((strength.Offset == 0) && (strength.Size == 4));
		Test.Assert(strength.HasRange && Near(strength.RangeMax, 2.0f));
		Test.Assert(strength.Line == 4);
		Test.Assert(effect.Properties[1].Offset == 4);
		Test.Assert(Near(effect.Properties[1].Value.X, 1.0f));
		Test.Assert(effect.Properties[2].Offset == 8);
		Test.Assert(Near(effect.Properties[2].RangeMin, 0.01f));
		Test.Assert(effect.Properties[3].Offset == 16, "a float3 at 12 would cross a row");
		Test.Assert(effect.UniformSize == 32);
		Test.Assert(effect.FindProperty("Speed") === effect.Properties[1]);
		Test.Assert(effect.FindProperty("WindSpeed") == null);
	}

	[Test]
	public static void ASourceWithoutAnEffectHasNoneAndSeveralAreFoundInOrder()
	{
		let none = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("// an effect is described here\nfloat x;\n", 0, none);
		Test.Assert(!none.Present);
		Test.Assert(!ShaderProperties.HasEffect("float effects;\n  effective = 1;\n"));
		Test.Assert(ShaderProperties.HasEffect("\n  effect A : WIND {\n}\n"));

		let blocks = scope List<ShaderEffectBlock>();
		defer { ClearAndDeleteItems!(blocks); }
		ShaderProperties.ParseEffects("effect Wind : WIND {\n" +      // 1
			"    float Strength = 0 (gate);\n" +                      // 2
			"}\n" +                                                   // 3
			"float x;\n" +                                            // 4
			"effect Fade : DITHER\n" +                                // 5
			"{\n" +                                                   // 6
			"    float Amount (gate);\n" +                            // 7
			"    Color Tint;\n" +                                     // 8
			"}\n", blocks);
		Test.Assert(blocks.Count == 2);
		Test.Assert(blocks[0].IsOk && (blocks[0].Effect.Name == "Wind"));
		Test.Assert(blocks[1].IsOk);
		Test.Assert(blocks[1].FirstLine == 5);
		Test.Assert(blocks[1].Effect.Flag == .Dither);
		Test.Assert(blocks[1].Effect.Properties[1].Offset == 16);
		Test.Assert(Near(blocks[1].Effect.Properties[1].Value.W, 1.0f), "a colour's default, as in properties");
	}

	[Test]
	public static void EveryMalformedEffectHeaderAndBodyIsReportedWithItsLine()
	{
		let message = scope String();
		// The header: a name, a colon, one of the engine's flags.
		Test.Assert(OnlyEffectErrorLine("effect Wind : WINDY {\n  float S = 0 (gate);\n}\n") == 1);
		Test.Assert(OnlyEffectErrorLine("effect Wind : WINDY {\n  float S (gate);\n}\n", message) == 1);
		Test.Assert(message.Contains("unknown variant flag 'WINDY'"));
		Test.Assert(message.Contains("(SKINNED, "), "the flags it may be");
		Test.Assert(OnlyEffectErrorLine("effect Wind WIND {\n  float S (gate);\n}\n", message) == 1); // no colon
		Test.Assert(message.Contains("colon"));
		Test.Assert(OnlyEffectErrorLine("effect : WIND {\n  float S (gate);\n}\n", message) == 1); // no name
		Test.Assert(message.Contains("needs a name"));
		Test.Assert(OnlyEffectErrorLine("effect Wind : WIND extra {\n  float S (gate);\n}\n") == 1);

		// Uniforms only: a texture, a cube or a sampler is an error at its line.
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float S (gate);\n  Texture T;\n}\n", message) == 3);
		Test.Assert(message.Contains("uniforms only"));
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float S (gate);\n  Sampler T;\n}\n") == 3);
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  TextureCube T;\n  float S (gate);\n}\n") == 2);

		// One gate, a float: none, two, or a gate of another type.
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float S = 1;\n}\n", message) == 1);
		Test.Assert(message.Contains("(gate)"));
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float A (gate);\n  float B = 1 [0, 1] (gate);\n}\n") == 3);
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  int S = 1 (gate);\n}\n") == 2);
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float2 S (gate);\n}\n", message) == 2);
		Test.Assert(message.Contains("is a float"));
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float S (gat);\n}\n") == 2);

		// The properties grammar's errors hold in an effect too.
		Test.Assert(OnlyEffectErrorLine("effect W : WIND {\n  float S (gate)\n  float B;\n}\n") == 2);
		Test.Assert(OnlyEffectErrorLine("effect W : WIND\n") == 1); // no {
	}

	[Test]
	public static void APropertiesBlockKnowsNoGateAndKeepsItsErrorsAsTheyWere()
	{
		let message = scope String();
		// `(gate)` belongs to an effect; in a properties block it is the missing `;` it always was.
		Test.Assert(OnlyErrorLine("properties {\n  float A = 0 (gate);\n}\n", message) == 2);
		Test.Assert(message.Contains("ends with ;"));
		OnlyErrorLine("properties\n", message);
		Test.Assert(message.Contains("properties needs a {"));
		OnlyErrorLine("\nproperties {\n  float A;\n", message);
		Test.Assert(message.Contains("the properties block has no closing }"));
		// A properties block still takes its textures; an effect line is not a properties line.
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("effect W : WIND {\n  float S (gate);\n}\nproperties {\n  Texture T;\n}\n", block);
		Test.Assert(block.IsOk);
		Test.Assert(block.FirstLine == 4);
		Test.Assert(block.Properties.Count == 1);
	}

	[Test]
	public static void TheEffectsConstantBufferBindsAtB1OfTheMaterialsSetReadAsEffectMember()
	{
		let block = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("effect Wind : WIND\n" +
			"{\n" +
			"    float Strength = 0 [0, 2] (gate);\n" +
			"    float Speed = 1 [0, 20];\n" +
			"    float Height = 1 [0.01, 100];\n" +
			"}\n", 0, block);
		Test.Assert(block.IsOk);
		let declaration = ShaderProperties.GenerateEffectDeclaration(block.Effect, .. scope String());
		Test.Assert(declaration == "struct WindEffect {\n" +
			"    float Strength; // offset 0\n" +
			"    float Speed; // offset 4\n" +
			"    float Height; // offset 8\n" +
			"};\n" +
			"ConstantBuffer<WindEffect> Wind : register(b1, space2);\n", declaration);

		// The expansion replaces the block and keeps the later lines' numbers.
		let expanded = scope String();
		let blocks = scope List<ShaderEffectBlock>();
		defer { ClearAndDeleteItems!(blocks); }
		ShaderProperties.ExpandEffects("// head\n" +
			"effect Wind : WIND\n" +
			"{\n" +
			"    float Strength = 0 (gate);\n" +
			"}\n" +
			"float Sway() { return Wind.Strength; }\n", "wind.hlsli", expanded, blocks);
		Test.Assert(blocks.Count == 1);
		Test.Assert(expanded == "// head\n" +
			"struct WindEffect {\n" +
			"    float Strength; // offset 0\n" +
			"};\n" +
			"ConstantBuffer<WindEffect> Wind : register(b1, space2);\n" +
			"#line 6 \"wind.hlsli\"\n" +
			"float Sway() { return Wind.Strength; }\n", expanded);

		// A block with errors becomes an #error at each error's line, so a compile reaching it
		// fails naming the file and line.
		let broken = scope String();
		let bad = scope List<ShaderEffectBlock>();
		defer { ClearAndDeleteItems!(bad); }
		ShaderProperties.ExpandEffects("effect Wind : WIND {\n  float S (gate);\n  Texture T;\n}\nfloat x;\n", "wind.hlsli", broken,
			bad);
		Test.Assert((bad.Count == 1) && !bad[0].IsOk);
		Test.Assert(broken.Contains("#line 3 \"wind.hlsli\"\n#error effect: 'Texture'"), broken);
		Test.Assert(broken.Contains("#line 5 \"wind.hlsli\"\nfloat x;\n"), broken);

		// A source without a block is returned as it is.
		let same = scope String();
		let noBlocks = scope List<ShaderEffectBlock>();
		ShaderProperties.ExpandEffects("float x;\n", "a.hlsli", same, noBlocks);
		Test.Assert(noBlocks.IsEmpty);
		Test.Assert(same == "float x;\n");
	}

	[Test]
	public static void ALibraryHoldsEachEffectOnceByNameAndByFlag()
	{
		let library = scope ShaderEffectLibrary();
		let error = scope String();
		let wind = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("effect Wind : WIND {\n float S (gate);\n}\n", 0, wind);
		Test.Assert(library.Add(wind.Effect, error));
		Test.Assert(library.Find("Wind") != null);
		Test.Assert(library.Find("Wind") !== wind.Effect, "the library holds its own copy");
		Test.Assert(library.ForFlag(.Wind) != null);
		Test.Assert(library.ForFlag(.Dither) == null);

		Test.Assert(!library.Add(wind.Effect, error)); // the same name
		Test.Assert(error.Contains("declared twice"));
		let gust = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("effect Gust : WIND {\n float S (gate);\n}\n", 0, gust);
		Test.Assert(!library.Add(gust.Effect, error)); // the same flag
		Test.Assert(error.Contains("share a variant flag"));
		Test.Assert(library.Count == 1);
	}
}
