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
}
