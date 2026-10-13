using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Shaders;
using Sedulous.Shaders.Pipeline;
using Sedulous.VFS;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// shader_validate: the New Shader starter checks clean against the engine's shader library, with
/// its properties and both stages' variants reported; a broken shader comes back with the file,
/// line and column of its error.
static class ShaderValidateToolTests
{
	[Test]
	public static void TheStarterChecksCleanAndABrokenShaderReportsItsLine()
	{
		{
			let compiler = scope ShaderCompiler();
			if (compiler.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		}
		let dataRoot = FindDataRoot(.. scope String());
		Test.Assert(!dataRoot.IsEmpty);
		let server = scope McpServer();
		ShaderValidateTool.Register(server, DataPath(dataRoot, "Shaders", .. scope .()));

		let good = CallOk(server, "shader_validate", With(With(Obj(), "source", ShaderCreators.cStarter), "name", "Lava.hlsl"));
		defer delete good;
		Test.Assert(good.Get("valid").AsBool(), scope $"{good.Get("errors").ToString(.. scope .())}");
		Test.Assert(good.Get("errors").Count == 0);
		let properties = good.Get("properties");
		Test.Assert(properties.Count == 6);
		Test.Assert(properties.At(0).Get("name").AsString() == "BaseColor");
		Test.Assert(properties.At(0).Get("type").AsString() == "Color");
		Test.Assert(properties.At(1).Get("range").Count == 2, "Roughness [0, 1]");
		Test.Assert(properties.At(0).Get("range") == null, "no range declared");
		Test.Assert(good.Get("vertexVariants").Count == 2); // SKINNED INSTANCED
		Test.Assert(good.Get("fragmentVariants").Count == 3); // ALPHA_TEST GBUFFER DITHER
		Test.Assert(good.Get("fragmentVariants").At(0).AsString() == "ALPHA_TEST");
		Test.Assert(good.Get("kind").AsString() == "lowLevel");

		// A surface shader: its kind and its Vertex().
		let lava = CallOk(server, "shader_validate", With(Obj(), "source", ShaderCreators.cLitSurfaceStarter));
		defer delete lava;
		Test.Assert(lava.Get("valid").AsBool(), scope $"{lava.Get("errors").ToString(.. scope .())}");
		Test.Assert(lava.Get("kind").AsString() == "lit");
		Test.Assert(!lava.Get("hasVertex").AsBool());
		Test.Assert(lava.Get("properties").Count == 5);

		let bad = CallOk(server, "shader_validate", With(With(Obj(), "source",
			"properties\n{\n    float Glow = 1;\n}\nfloat4 VSMain(uint id : SV_VertexID) : SV_Position { return 0; }\nfloat4 PSMain() : SV_Target0 { return Glw; }\n"),
			"name", "Bad.hlsl"));
		defer delete bad;
		Test.Assert(!bad.Get("valid").AsBool());
		Test.Assert(bad.Get("errors").Count >= 1);
		let error = bad.Get("errors").At(0);
		Test.Assert(error.Get("file").AsString() == "Bad.hlsl");
		Test.Assert(error.Get("line").AsNumber() == 6.0);
		Test.Assert(error.Get("column").AsNumber() > 0.0);
	}
}
