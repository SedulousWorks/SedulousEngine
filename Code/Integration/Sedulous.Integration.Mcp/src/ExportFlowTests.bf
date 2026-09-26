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
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// project_export: a REAL dist from an authored project, the player staged from a stand in
/// host build, plus the refusals: no project, an unknown preset.
static class ExportFlowTests
{
	[Test]
	public static void ProjectExportMakesARealDistFromAnAuthoredProject()
	{
		let dir = Scratch("mcp_export_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		// A stand in player directory beside the "host tool", as the build lays them out.
		let playerDir = Scratch("mcp_export_player", .. scope .());
		defer RemoveDirectoryRecursive(playerDir);
		CreateDirectory(playerDir);
		let player = "#!player\n";
		WriteFile(PathJoin(playerDir, BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .()), .. scope .()), .((uint8*)player.Ptr, player.Length)).IgnoreError();
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, playerDir, dataRoot);
		ProjectExportTool.Register(server, session, operations);

		let noProject = scope String();
		CallErr(server, "project_export", Obj(), noProject);
		Test.Assert(noProject.Contains("project_open"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Exportable"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		{
			let authored = scope Scene("main");
			EngineSceneComposition.AddAllSceneManagers(authored);
			authored.CreateEntity("anchor");
			let instance = session.Project.SourceDb.RootGroup.CreateInstance("main", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
		}
		let unknown = scope String();
		CallErr(server, "project_export", With(Obj(), "preset", "NoSuchPreset"), unknown);
		Test.Assert(unknown.Contains("available"), "the refusal lists the presets");

		let exported = CallOk(server, "project_export", Obj());
		defer delete exported;
		Test.Assert(exported.Get("exported").AsBool());
		Test.Assert(exported.Get("scenesStaged").AsInt() >= 1);
		Test.Assert(exported.Get("cookFailed").AsInt() == 0);
		let outputDir = scope String(exported.Get("outputDir").AsString());
		Test.Assert(!outputDir.IsEmpty);
		Test.Assert(FileExists(PathJoin(outputDir, "Content.pak", .. scope .())) && FileExists(PathJoin(outputDir, "player.xml", .. scope .())));
		Test.Assert(FileExists(PathJoin(outputDir, "Data/Shaders/shaders.dpak", .. scope .())), "the shader pack cooked from the data root");
		Test.Assert(exported.Get("filesStaged").AsInt() >= 1, "the player staged");
		Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .()), .. scope .())));
	}
}
