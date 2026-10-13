using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.VFS;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// material_set_shader does what the material page's Shader row does: a material put on a cooked
/// custom shader is saved in the shader's layout (so its cook has nothing to drop), and put back
/// on the built-in PBR it has PBR's layout again.
static class MaterialShaderToolTests
{
	[Test]
	public static void AMaterialIsLaidOutByItsShaderAndSaved()
	{
		let dir = Scratch("mcp_material_shader_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		PipelineRegistration.RegisterAllImporters(importers);
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllCreators(creators);

		let server = scope McpServer();
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		let operations = scope InlineProjectOperations(session, builders, "", "");
		EngineTools.Register(server, session, builders, importers, creators, logBuffer, scope EngineToolPaths(), operations);
		ProjectOpenTools.Register(server, session, owner);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Shaded"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// A lit surface shader (the lava starter: CrackColor, Speed, Glow, Cracks, MainSampler),
		// cooked.
		let lava = CallOk(server, "asset_create", With(With(Obj(), "creator", "Lit Surface Shader"), "name", "Lava"));
		defer delete lava;
		let cooked = CallOk(server, "asset_cook", Obj());
		defer delete cooked;
		if (cooked.Get("failed").AsInt() != 0)
		{
			Console.WriteLine("SKIP: the shader did not cook here (no DXC?)");
			return;
		}
		let material = CallOk(server, "asset_create", With(With(Obj(), "creator", "PBR Material"), "name", "Rock"));
		defer delete material;
		let materialId = material.Get("guid").AsString();

		// A guid that is not a shader asset is refused.
		let refused = scope String();
		CallErr(server, "material_set_shader", With(With(Obj(), "material", materialId), "shader", materialId), refused);
		Test.Assert(refused.Contains("no shader asset"), refused);

		let onLava = CallOk(server, "material_set_shader", With(With(Obj(), "material", materialId), "shader", lava.Get("guid").AsString()));
		defer delete onLava;
		Test.Assert(onLava.Get("properties").Count == 5);
		Test.Assert(onLava.Get("shaderName").AsString() == "Lava");
		// Saved: the material's own asset holds the shader's layout, none of PBR's.
		let read = CallOk(server, "asset_data_read", With(Obj(), "guid", materialId));
		defer delete read;
		let xml = read.Get("xml").AsString();
		Test.Assert(xml.Contains("<string>CrackColor</string>"));
		Test.Assert(!xml.Contains("<string>BaseColor</string>"));

		// Back on the built-in PBR: PBR's sixteen properties again.
		let onPbr = CallOk(server, "material_set_shader", With(With(Obj(), "material", materialId), "shader", "pbr"));
		defer delete onPbr;
		Test.Assert(onPbr.Get("properties").Count == 16);
		Test.Assert(onPbr.Get("shaderName").AsString() == "forward");
	}
}
