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
using Sedulous.Editor.Core;
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

		// The flow runs over the SHARED engine surface (what every host serves) plus the
		// stdio host's project_create and project_open.
		let server = scope McpServer();
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		EngineTools.Register(server, session, builders, importers, logBuffer, scope EngineToolPaths());
		ProjectOpenTools.Register(server, session, owner);

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

	/// EngineTools registers exactly cEngineToolCount tools: the surface every host serves,
	/// and only that.
	[Test]
	public static void EngineToolsRegistersExactlyTheSharedSurface()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession();

		let server = scope McpServer();
		EngineTools.Register(server, session, builders, importers, logBuffer, scope EngineToolPaths());
		Test.Assert(server.ToolCount == EngineTools.cEngineToolCount, scope $"{server.ToolCount} tools");

		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}");
		defer delete listed;
		let tools = listed.Get("result").Get("tools");
		bool Has(StringView name)
		{
			for (int i < tools.Count)
				if (tools.At(i).Get("name").AsString() == name)
					return true;
			return false;
		}
		// Spot checks across the families the root gathers ...
		Test.Assert(Has("type_list"));
		Test.Assert(Has("script_api"));
		Test.Assert(Has("project_info"));
		Test.Assert(Has("asset_cook"));
		Test.Assert(Has("scene_write"));
		Test.Assert(Has("project_export"));
		Test.Assert(Has("known_issues"));
		// ... and what a HOST adds itself: never part of the shared surface.
		Test.Assert(!Has("project_open"));
		Test.Assert(!Has("project_create"));
		Test.Assert(!Has("host_info"));
	}
}
