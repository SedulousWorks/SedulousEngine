using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// ONE sequence through the tools in the order the guide teaches: create, open, import a
/// real source (the starter), cook it clean, write a scene from a real save, validate it
/// by guid, and read the project as sound with nothing dirty and nothing failed.
static class FullFlowTests
{
	[Test]
	public static void TheFullAgentFlow()
	{
		let dir = Scratch("mcp_full_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllImporters(importers);

		let server = scope McpServer();
		let session = scope ProjectSession();
		ProjectTools.Register(server, session);
		AssetTools.Register(server, session);
		AssetWriteTools.Register(server, session, builders, importers);
		SceneTools.Register(server, session);
		ProjectHealthTool.Register(server, session, builders);

		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Full"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// A real source: the backend's own behavior starter, on disk.
		let starter = scope String();
		ScriptLanguageCooks.Find("angelscript").NewAssetTemplate(.Behavior, starter);
		let sourcePath = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "mcp_full_starter.as", .. scope .());
		defer DeleteFile(sourcePath);
		File.WriteAllText(sourcePath, starter).IgnoreError();
		let imported = CallOk(server, "asset_import", With(With(Obj(), "source", sourcePath), "group", "scripts"));
		defer delete imported;
		Test.Assert(imported.Get("type").AsString() == typeof(ScriptClassAsset).GetFullName(.. scope .()));

		let cooked = CallOk(server, "asset_cook", Obj());
		defer delete cooked;
		Test.Assert(cooked.Get("cooked").AsInt() >= 1);
		Test.Assert(cooked.Get("failed").AsInt() == 0);

		// A scene from a real save, written through the tool and validated by guid.
		let xml = scope String();
		{
			let authored = scope Scene("hub");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let root = authored.CreateEntity("root");
			authored.SetParent(authored.CreateEntity("child"), root);
			let seed = session.Project.SourceDb.RootGroup.CreateInstance("seed", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(authored, seed) case .Ok);
			Test.Assert(McpTools.ReadSceneStream(seed, xml));
			Test.Assert(session.Project.SourceDb.DeleteInstance(seed.Id) case .Ok);
		}
		let written = CallOk(server, "scene_write", With(With(Obj(), "xml", xml), "name", "hub"));
		defer delete written;
		let valid = CallOk(server, "scene_validate", With(Obj(), "guid", written.Get("guid").AsString()));
		defer delete valid;
		Test.Assert(valid.Get("valid").AsBool());
		Test.Assert(valid.Get("componentValidation").AsString() == "full");

		let health = CallOk(server, "project_health", Obj());
		defer delete health;
		Test.Assert(health.Get("sound").AsBool());
		Test.Assert(health.Get("dirty").AsInt() == 0, scope $"{health.Get("dirty").AsInt()} dirty");
		Test.Assert(health.Get("failedCooks").AsInt() == 0);
	}
}
