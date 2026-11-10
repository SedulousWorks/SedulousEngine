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
/// on the built-in PBR it has PBR's layout again. Its effect groups follow the shader's vertex
/// variants, read from the engine's shader library: a shader that declares WIND gives the
/// material its Wind group, one that does not takes it away.
static class MaterialShaderToolTests
{
	[Test]
	public static void AMaterialIsLaidOutByItsShaderAndSaved()
	{
		let dir = Scratch("mcp_material_shader_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
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
		let operations = scope InlineProjectOperations(session, builders, "");
		// The engine's shader library: where the effects' tables (wind.hlsli's Wind) are read from.
		let paths = scope EngineToolPaths();
		DataPath(FindDataRoot(.. scope .()), "Engine/Shaders", paths.ShaderLibrary);
		EngineTools.Register(server, session, builders, importers, creators, logBuffer, paths, operations);
		ProjectOpenTools.Register(server, session, owner);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Shaded"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// A lit surface shader (the lava starter: CrackColor, Speed, Glow, Cracks, MainSampler),
		// cooked.
		let lava = CallOk(server, "asset_create", With(With(Obj(), "creator", "Lit Surface Shader"), "name", "Lava"));
		defer delete lava;
		// A low-level shader whose vertex stage does not declare WIND (the starter's, WIND struck).
		let still = CallOk(server, "asset_create", With(With(Obj(), "creator", "Low-Level Shader"), "name", "Still"));
		defer delete still;
		{
			let path = PathJoin(session.Project.SourcesRoot(.. scope .()), "Still.hlsl", .. scope .());
			let text = scope String();
			Test.Assert(System.IO.File.ReadAllText(path, text) case .Ok);
			let declared = "// variants(vertex): SKINNED INSTANCED WIND";
			Test.Assert(text.Contains(declared));
			text.Replace(declared, "// variants(vertex): SKINNED INSTANCED");
			Test.Assert(WriteFile(path, Span<uint8>((uint8*)text.Ptr, text.Length)) case .Ok);
		}
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
		// A surface shader declares WIND: the material gains the Wind group (a new material had none).
		Test.Assert(onLava.Get("effects").Count == 1);
		Test.Assert(onLava.Get("effects").At(0).Get("name").AsString() == "Wind");
		// Saved: the material's own asset holds the shader's layout, none of PBR's.
		let read = CallOk(server, "asset_data_read", With(Obj(), "guid", materialId));
		defer delete read;
		let xml = read.Get("xml").AsString();
		Test.Assert(xml.Contains("<string>CrackColor</string>"));
		Test.Assert(!xml.Contains("<string>BaseColor</string>"));

		// Back on the built-in PBR: PBR's thirteen properties again (its wind is the Wind effect's
		// group, not three of them).
		let onPbr = CallOk(server, "material_set_shader", With(With(Obj(), "material", materialId), "shader", "pbr"));
		defer delete onPbr;
		Test.Assert(onPbr.Get("properties").Count == 13);
		Test.Assert(onPbr.Get("shaderName").AsString() == "forward");
		// Its Wind group: the effect's three parameters, its gate at nought (still).
		Test.Assert(onPbr.Get("effects").Count == 1);
		let wind = onPbr.Get("effects").At(0);
		Test.Assert(wind.Get("name").AsString() == "Wind");
		Test.Assert(wind.Get("flag").AsString() == "WIND");
		Test.Assert(wind.Get("properties").Count == 3);
		Test.Assert(wind.Get("properties").At(0).Get("name").AsString() == "Strength");
		Test.Assert(wind.Get("properties").At(0).Get("value").AsNumber(-1.0) == 0.0);
		Test.Assert(wind.Get("properties").At(1).Get("name").AsString() == "Speed");

		// On a shader whose vertex stage does not declare WIND: no group.
		let onStill = CallOk(server, "material_set_shader", With(With(Obj(), "material", materialId), "shader", still.Get("guid").AsString()));
		defer delete onStill;
		Test.Assert(onStill.Get("shaderName").AsString() == "Still");
		Test.Assert(onStill.Get("effects").Count == 0);
		let readStill = CallOk(server, "asset_data_read", With(Obj(), "guid", materialId));
		defer delete readStill;
		Test.Assert(!readStill.Get("xml").AsString().Contains("<string>Wind</string>"));

		// On the built-in Phong: its eleven (six values, four maps, the sampler).
		let onPhong = CallOk(server, "material_set_shader", With(With(Obj(), "material", materialId), "shader", "phong"));
		defer delete onPhong;
		Test.Assert(onPhong.Get("properties").Count == 11);
		Test.Assert(onPhong.Get("shaderName").AsString() == "phong");
		// Phong declares WIND as PBR does: the group again, at the effect's defaults.
		Test.Assert(onPhong.Get("effects").Count == 1);
		Test.Assert(onPhong.Get("effects").At(0).Get("name").AsString() == "Wind");
	}
}
